// =============================================================================
// tb —— Slice 家族 UT：golden Slice/_1/_2/_3 与重写 Slice*_xs 四对双例化，同激励逐拍比对
//       每对全部 334 个输出（4 态 !==）。
//
// 激励（每拍全部输入重摇，偏置见 gen_tb.py 的 drive_expr）：
//   · 地址压到 tag 0..15 × set 0..3（A/C/snoop/预取同一地址域），让命中、替换、同 set 冲突、
//     snoop 撞在途 MSHR 真正发生；A opcode 偏向 Get/Hint/AcquireBlock/AcquirePerm，C 偏向
//     ProbeAck/ProbeAckData/Release/ReleaseData；RXDAT/RXRSP 的 txnID 偏向 0..15（= mshrId）、
//     opcode 偏向 CompData/DataSepResp 与 RetryAck..ReadReceipt；snoop opcode 偏向 1..10；
//   · CHI 节点号（srcID/homeNID）压到 0..1；P-Credit grant 只在对应 MSHR 查询时给（1/4 概率）；
//     RXDAT/RXRSP 只发给处在对应等待状态的 MSHR（pick_target）；E 通道 sink 取 0..16；
//   · 每 4000 拍一轮三个阶段：常速 2000 拍 / 下游慢 1000 拍（RXDAT/RXRSP 1/32，逼 MSHR 全占）/
//     MBIST 窗口 1000 拍（bore req 持续拉高）；SRAM hold/bypass/cgen 低频翻、aux_clk/aux_ckbp 恒 0
//     （见 drive_expr 里的说明）；约 1/20000 拍一次异步复位。
// 厂商 SRAM 叶子（array_*_ext）的存储体：编译带 +define+RANDOMIZE_MEM_INIT，由叶子自带的 initial
//   块填随机值（模拟上电垃圾；不填则 tag/数据读出全 X、流水在 X 上停摆、比对 X===X 空过），
//   再随同步表拷到重写侧。
// 未复位寄存器 / 存储阵列：+vcs+initreg+random 下两侧初值不同，tb 在首个时钟沿前把 golden 侧
//   初值同步到重写侧（表从各 child 的 UT tb 机械收割，见 gen_tb.py 文件头）；有复位的不同步。
// 覆盖：一组 golden 内部事件各自为真的拍数（只计 Slice 那一对），任何一项为 0 即判 TEST FAILED。
//
// 本文件由 verif/ut/Slice/gen_tb.py 生成，勿手改。
// =============================================================================
`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 200000;
  bit clock = 0; always #5 clock = ~clock;
  logic reset;
  longint errors = 0, checks = 0;
  longint cyc = 0;
  // 阶段：每 4000 拍一轮 —— [0,2000) 常速；[2000,3000) 下游慢（RXDAT/RXRSP 1/32），逼 MSHR 全占；
  //        [3000,4000) MBIST 窗口（bore req 持续拉高、array/读写随机），让 MBIST 分发真正握手。
  function automatic bit slow_phase();  return (cyc % 4000) >= 2000 && (cyc % 4000) < 3000; endfunction
  function automatic bit mbist_phase(); return (cyc % 4000) >= 3000; endfunction

  logic io_in_a_valid;
  logic [3:0] io_in_a_bits_opcode;
  logic [2:0] io_in_a_bits_param;
  logic [2:0] io_in_a_bits_size;
  logic [6:0] io_in_a_bits_source;
  logic [47:0] io_in_a_bits_address;
  logic [4:0] io_in_a_bits_user_reqSource;
  logic [1:0] io_in_a_bits_user_alias;
  logic [43:0] io_in_a_bits_user_vaddr;
  logic io_in_a_bits_user_needHint;
  logic io_in_a_bits_echo_isKeyword;
  logic io_in_a_bits_corrupt;
  logic io_in_b_ready;
  logic io_in_c_valid;
  logic [2:0] io_in_c_bits_opcode;
  logic [2:0] io_in_c_bits_param;
  logic [2:0] io_in_c_bits_size;
  logic [6:0] io_in_c_bits_source;
  logic [47:0] io_in_c_bits_address;
  logic [255:0] io_in_c_bits_data;
  logic io_in_c_bits_corrupt;
  logic io_in_d_ready;
  logic io_in_e_valid;
  logic [7:0] io_in_e_bits_sink;
  logic io_l1Hint_ready;
  logic io_prefetch_train_ready;
  logic io_prefetch_req_valid;
  logic [32:0] io_prefetch_req_bits_tag;
  logic [8:0] io_prefetch_req_bits_set;
  logic [43:0] io_prefetch_req_bits_vaddr;
  logic io_prefetch_req_bits_needT;
  logic [6:0] io_prefetch_req_bits_source;
  logic [4:0] io_prefetch_req_bits_pfSource;
  logic io_prefetch_resp_ready;
  logic io_out_tx_req_ready;
  logic io_out_tx_rsp_ready;
  logic io_out_tx_dat_ready;
  logic io_out_rx_rsp_valid;
  logic [10:0] io_out_rx_rsp_bits_srcID;
  logic [11:0] io_out_rx_rsp_bits_txnID;
  logic [4:0] io_out_rx_rsp_bits_opcode;
  logic [1:0] io_out_rx_rsp_bits_respErr;
  logic [2:0] io_out_rx_rsp_bits_resp;
  logic [11:0] io_out_rx_rsp_bits_dbID;
  logic [3:0] io_out_rx_rsp_bits_pCrdType;
  logic io_out_rx_rsp_bits_traceTag;
  logic io_out_rx_dat_valid;
  logic [11:0] io_out_rx_dat_bits_txnID;
  logic [10:0] io_out_rx_dat_bits_homeNID;
  logic [3:0] io_out_rx_dat_bits_opcode;
  logic [1:0] io_out_rx_dat_bits_respErr;
  logic [2:0] io_out_rx_dat_bits_resp;
  logic [11:0] io_out_rx_dat_bits_dbID;
  logic [1:0] io_out_rx_dat_bits_dataID;
  logic io_out_rx_dat_bits_traceTag;
  logic [255:0] io_out_rx_dat_bits_data;
  logic [31:0] io_out_rx_dat_bits_dataCheck;
  logic [3:0] io_out_rx_dat_bits_poison;
  logic io_out_rx_snp_valid;
  logic [3:0] io_out_rx_snp_bits_qos;
  logic [10:0] io_out_rx_snp_bits_srcID;
  logic [11:0] io_out_rx_snp_bits_txnID;
  logic [10:0] io_out_rx_snp_bits_fwdNID;
  logic [11:0] io_out_rx_snp_bits_fwdTxnID;
  logic [4:0] io_out_rx_snp_bits_opcode;
  logic [44:0] io_out_rx_snp_bits_addr;
  logic io_out_rx_snp_bits_ns;
  logic io_out_rx_snp_bits_doNotGoToSD;
  logic io_out_rx_snp_bits_retToSrc;
  logic io_out_rx_snp_bits_traceTag;
  logic io_out_rx_snp_bits_mpam_perfMonGroup;
  logic [8:0] io_out_rx_snp_bits_mpam_partID;
  logic io_out_rx_snp_bits_mpam_mpamNS;
  logic io_pCrd_0_grant;
  logic io_pCrd_1_grant;
  logic io_pCrd_2_grant;
  logic io_pCrd_3_grant;
  logic io_pCrd_4_grant;
  logic io_pCrd_5_grant;
  logic io_pCrd_6_grant;
  logic io_pCrd_7_grant;
  logic io_pCrd_8_grant;
  logic io_pCrd_9_grant;
  logic io_pCrd_10_grant;
  logic io_pCrd_11_grant;
  logic io_pCrd_12_grant;
  logic io_pCrd_13_grant;
  logic io_pCrd_14_grant;
  logic io_pCrd_15_grant;
  logic sigFromSrams_bore_ram_hold;
  logic sigFromSrams_bore_ram_bypass;
  logic sigFromSrams_bore_ram_bp_clken;
  logic sigFromSrams_bore_ram_aux_clk;
  logic sigFromSrams_bore_ram_aux_ckbp;
  logic sigFromSrams_bore_ram_mcp_hold;
  logic sigFromSrams_bore_cgen;
  logic sigFromSrams_bore_1_ram_hold;
  logic sigFromSrams_bore_1_ram_bypass;
  logic sigFromSrams_bore_1_ram_bp_clken;
  logic sigFromSrams_bore_1_ram_aux_clk;
  logic sigFromSrams_bore_1_ram_aux_ckbp;
  logic sigFromSrams_bore_1_ram_mcp_hold;
  logic sigFromSrams_bore_1_cgen;
  logic sigFromSrams_bore_2_ram_hold;
  logic sigFromSrams_bore_2_ram_bypass;
  logic sigFromSrams_bore_2_ram_bp_clken;
  logic sigFromSrams_bore_2_ram_aux_clk;
  logic sigFromSrams_bore_2_ram_aux_ckbp;
  logic sigFromSrams_bore_2_ram_mcp_hold;
  logic sigFromSrams_bore_2_cgen;
  logic sigFromSrams_bore_3_ram_hold;
  logic sigFromSrams_bore_3_ram_bypass;
  logic sigFromSrams_bore_3_ram_bp_clken;
  logic sigFromSrams_bore_3_ram_aux_clk;
  logic sigFromSrams_bore_3_ram_aux_ckbp;
  logic sigFromSrams_bore_3_ram_mcp_hold;
  logic sigFromSrams_bore_3_cgen;
  logic sigFromSrams_bore_4_ram_hold;
  logic sigFromSrams_bore_4_ram_bypass;
  logic sigFromSrams_bore_4_ram_bp_clken;
  logic sigFromSrams_bore_4_ram_aux_clk;
  logic sigFromSrams_bore_4_ram_aux_ckbp;
  logic sigFromSrams_bore_4_ram_mcp_hold;
  logic sigFromSrams_bore_4_cgen;
  logic sigFromSrams_bore_5_ram_hold;
  logic sigFromSrams_bore_5_ram_bypass;
  logic sigFromSrams_bore_5_ram_bp_clken;
  logic sigFromSrams_bore_5_ram_aux_clk;
  logic sigFromSrams_bore_5_ram_aux_ckbp;
  logic sigFromSrams_bore_5_ram_mcp_hold;
  logic sigFromSrams_bore_5_cgen;
  logic sigFromSrams_bore_6_ram_hold;
  logic sigFromSrams_bore_6_ram_bypass;
  logic sigFromSrams_bore_6_ram_bp_clken;
  logic sigFromSrams_bore_6_ram_aux_clk;
  logic sigFromSrams_bore_6_ram_aux_ckbp;
  logic sigFromSrams_bore_6_ram_mcp_hold;
  logic sigFromSrams_bore_6_cgen;
  logic sigFromSrams_bore_7_ram_hold;
  logic sigFromSrams_bore_7_ram_bypass;
  logic sigFromSrams_bore_7_ram_bp_clken;
  logic sigFromSrams_bore_7_ram_aux_clk;
  logic sigFromSrams_bore_7_ram_aux_ckbp;
  logic sigFromSrams_bore_7_ram_mcp_hold;
  logic sigFromSrams_bore_7_cgen;
  logic sigFromSrams_bore_8_ram_hold;
  logic sigFromSrams_bore_8_ram_bypass;
  logic sigFromSrams_bore_8_ram_bp_clken;
  logic sigFromSrams_bore_8_ram_aux_clk;
  logic sigFromSrams_bore_8_ram_aux_ckbp;
  logic sigFromSrams_bore_8_ram_mcp_hold;
  logic sigFromSrams_bore_8_cgen;
  logic sigFromSrams_bore_9_ram_hold;
  logic sigFromSrams_bore_9_ram_bypass;
  logic sigFromSrams_bore_9_ram_bp_clken;
  logic sigFromSrams_bore_9_ram_aux_clk;
  logic sigFromSrams_bore_9_ram_aux_ckbp;
  logic sigFromSrams_bore_9_ram_mcp_hold;
  logic sigFromSrams_bore_9_cgen;
  logic sigFromSrams_bore_10_ram_hold;
  logic sigFromSrams_bore_10_ram_bypass;
  logic sigFromSrams_bore_10_ram_bp_clken;
  logic sigFromSrams_bore_10_ram_aux_clk;
  logic sigFromSrams_bore_10_ram_aux_ckbp;
  logic sigFromSrams_bore_10_ram_mcp_hold;
  logic sigFromSrams_bore_10_cgen;
  logic [5:0] boreChildrenBd_bore_array;
  logic boreChildrenBd_bore_all;
  logic boreChildrenBd_bore_req;
  logic boreChildrenBd_bore_writeen;
  logic [7:0] boreChildrenBd_bore_be;
  logic [12:0] boreChildrenBd_bore_addr;
  logic [136:0] boreChildrenBd_bore_indata;
  logic boreChildrenBd_bore_readen;
  logic [12:0] boreChildrenBd_bore_addr_rd;
  logic g0_io_in_a_ready, i0_io_in_a_ready;
  logic g0_io_in_b_valid, i0_io_in_b_valid;
  logic [2:0] g0_io_in_b_bits_opcode, i0_io_in_b_bits_opcode;
  logic [1:0] g0_io_in_b_bits_param, i0_io_in_b_bits_param;
  logic [47:0] g0_io_in_b_bits_address, i0_io_in_b_bits_address;
  logic [255:0] g0_io_in_b_bits_data, i0_io_in_b_bits_data;
  logic g0_io_in_c_ready, i0_io_in_c_ready;
  logic g0_io_in_d_valid, i0_io_in_d_valid;
  logic [3:0] g0_io_in_d_bits_opcode, i0_io_in_d_bits_opcode;
  logic [1:0] g0_io_in_d_bits_param, i0_io_in_d_bits_param;
  logic [6:0] g0_io_in_d_bits_source, i0_io_in_d_bits_source;
  logic [7:0] g0_io_in_d_bits_sink, i0_io_in_d_bits_sink;
  logic g0_io_in_d_bits_denied, i0_io_in_d_bits_denied;
  logic g0_io_in_d_bits_echo_isKeyword, i0_io_in_d_bits_echo_isKeyword;
  logic [255:0] g0_io_in_d_bits_data, i0_io_in_d_bits_data;
  logic g0_io_in_d_bits_corrupt, i0_io_in_d_bits_corrupt;
  logic g0_io_l1Hint_valid, i0_io_l1Hint_valid;
  logic [31:0] g0_io_l1Hint_bits_sourceId, i0_io_l1Hint_bits_sourceId;
  logic g0_io_l1Hint_bits_isKeyword, i0_io_l1Hint_bits_isKeyword;
  logic g0_io_prefetch_train_valid, i0_io_prefetch_train_valid;
  logic [32:0] g0_io_prefetch_train_bits_tag, i0_io_prefetch_train_bits_tag;
  logic [8:0] g0_io_prefetch_train_bits_set, i0_io_prefetch_train_bits_set;
  logic g0_io_prefetch_train_bits_needT, i0_io_prefetch_train_bits_needT;
  logic [6:0] g0_io_prefetch_train_bits_source, i0_io_prefetch_train_bits_source;
  logic [43:0] g0_io_prefetch_train_bits_vaddr, i0_io_prefetch_train_bits_vaddr;
  logic g0_io_prefetch_train_bits_hit, i0_io_prefetch_train_bits_hit;
  logic g0_io_prefetch_train_bits_prefetched, i0_io_prefetch_train_bits_prefetched;
  logic [2:0] g0_io_prefetch_train_bits_pfsource, i0_io_prefetch_train_bits_pfsource;
  logic [4:0] g0_io_prefetch_train_bits_reqsource, i0_io_prefetch_train_bits_reqsource;
  logic g0_io_prefetch_req_ready, i0_io_prefetch_req_ready;
  logic g0_io_prefetch_resp_valid, i0_io_prefetch_resp_valid;
  logic [32:0] g0_io_prefetch_resp_bits_tag, i0_io_prefetch_resp_bits_tag;
  logic [8:0] g0_io_prefetch_resp_bits_set, i0_io_prefetch_resp_bits_set;
  logic [43:0] g0_io_prefetch_resp_bits_vaddr, i0_io_prefetch_resp_bits_vaddr;
  logic [4:0] g0_io_prefetch_resp_bits_pfSource, i0_io_prefetch_resp_bits_pfSource;
  logic g0_io_dirResult_valid, i0_io_dirResult_valid;
  logic g0_io_dirResult_bits_hit, i0_io_dirResult_bits_hit;
  logic g0_io_dirResult_bits_meta_prefetch, i0_io_dirResult_bits_meta_prefetch;
  logic [2:0] g0_io_dirResult_bits_meta_prefetchSrc, i0_io_dirResult_bits_meta_prefetchSrc;
  logic [2:0] g0_io_dirResult_bits_replacerInfo_channel, i0_io_dirResult_bits_replacerInfo_channel;
  logic [4:0] g0_io_dirResult_bits_replacerInfo_reqSource, i0_io_dirResult_bits_replacerInfo_reqSource;
  logic g0_io_hitPfInMSHR_valid, i0_io_hitPfInMSHR_valid;
  logic [2:0] g0_io_hitPfInMSHR_bits, i0_io_hitPfInMSHR_bits;
  logic g0_io_pfSent_valid, i0_io_pfSent_valid;
  logic [4:0] g0_io_pfSent_bits, i0_io_pfSent_bits;
  logic g0_io_pfLateInMSHR_valid, i0_io_pfLateInMSHR_valid;
  logic [4:0] g0_io_pfLateInMSHR_bits, i0_io_pfLateInMSHR_bits;
  logic g0_io_error_valid, i0_io_error_valid;
  logic g0_io_error_bits_valid, i0_io_error_bits_valid;
  logic [45:0] g0_io_error_bits_address, i0_io_error_bits_address;
  logic g0_io_l2Miss, i0_io_l2Miss;
  logic g0_io_msStatus_0_valid, i0_io_msStatus_0_valid;
  logic [2:0] g0_io_msStatus_0_bits_channel, i0_io_msStatus_0_bits_channel;
  logic [8:0] g0_io_msStatus_0_bits_set, i0_io_msStatus_0_bits_set;
  logic [30:0] g0_io_msStatus_0_bits_reqTag, i0_io_msStatus_0_bits_reqTag;
  logic g0_io_msStatus_0_bits_is_miss, i0_io_msStatus_0_bits_is_miss;
  logic g0_io_msStatus_0_bits_is_prefetch, i0_io_msStatus_0_bits_is_prefetch;
  logic g0_io_msStatus_1_valid, i0_io_msStatus_1_valid;
  logic [2:0] g0_io_msStatus_1_bits_channel, i0_io_msStatus_1_bits_channel;
  logic [8:0] g0_io_msStatus_1_bits_set, i0_io_msStatus_1_bits_set;
  logic [30:0] g0_io_msStatus_1_bits_reqTag, i0_io_msStatus_1_bits_reqTag;
  logic g0_io_msStatus_1_bits_is_miss, i0_io_msStatus_1_bits_is_miss;
  logic g0_io_msStatus_1_bits_is_prefetch, i0_io_msStatus_1_bits_is_prefetch;
  logic g0_io_msStatus_2_valid, i0_io_msStatus_2_valid;
  logic [2:0] g0_io_msStatus_2_bits_channel, i0_io_msStatus_2_bits_channel;
  logic [8:0] g0_io_msStatus_2_bits_set, i0_io_msStatus_2_bits_set;
  logic [30:0] g0_io_msStatus_2_bits_reqTag, i0_io_msStatus_2_bits_reqTag;
  logic g0_io_msStatus_2_bits_is_miss, i0_io_msStatus_2_bits_is_miss;
  logic g0_io_msStatus_2_bits_is_prefetch, i0_io_msStatus_2_bits_is_prefetch;
  logic g0_io_msStatus_3_valid, i0_io_msStatus_3_valid;
  logic [2:0] g0_io_msStatus_3_bits_channel, i0_io_msStatus_3_bits_channel;
  logic [8:0] g0_io_msStatus_3_bits_set, i0_io_msStatus_3_bits_set;
  logic [30:0] g0_io_msStatus_3_bits_reqTag, i0_io_msStatus_3_bits_reqTag;
  logic g0_io_msStatus_3_bits_is_miss, i0_io_msStatus_3_bits_is_miss;
  logic g0_io_msStatus_3_bits_is_prefetch, i0_io_msStatus_3_bits_is_prefetch;
  logic g0_io_msStatus_4_valid, i0_io_msStatus_4_valid;
  logic [2:0] g0_io_msStatus_4_bits_channel, i0_io_msStatus_4_bits_channel;
  logic [8:0] g0_io_msStatus_4_bits_set, i0_io_msStatus_4_bits_set;
  logic [30:0] g0_io_msStatus_4_bits_reqTag, i0_io_msStatus_4_bits_reqTag;
  logic g0_io_msStatus_4_bits_is_miss, i0_io_msStatus_4_bits_is_miss;
  logic g0_io_msStatus_4_bits_is_prefetch, i0_io_msStatus_4_bits_is_prefetch;
  logic g0_io_msStatus_5_valid, i0_io_msStatus_5_valid;
  logic [2:0] g0_io_msStatus_5_bits_channel, i0_io_msStatus_5_bits_channel;
  logic [8:0] g0_io_msStatus_5_bits_set, i0_io_msStatus_5_bits_set;
  logic [30:0] g0_io_msStatus_5_bits_reqTag, i0_io_msStatus_5_bits_reqTag;
  logic g0_io_msStatus_5_bits_is_miss, i0_io_msStatus_5_bits_is_miss;
  logic g0_io_msStatus_5_bits_is_prefetch, i0_io_msStatus_5_bits_is_prefetch;
  logic g0_io_msStatus_6_valid, i0_io_msStatus_6_valid;
  logic [2:0] g0_io_msStatus_6_bits_channel, i0_io_msStatus_6_bits_channel;
  logic [8:0] g0_io_msStatus_6_bits_set, i0_io_msStatus_6_bits_set;
  logic [30:0] g0_io_msStatus_6_bits_reqTag, i0_io_msStatus_6_bits_reqTag;
  logic g0_io_msStatus_6_bits_is_miss, i0_io_msStatus_6_bits_is_miss;
  logic g0_io_msStatus_6_bits_is_prefetch, i0_io_msStatus_6_bits_is_prefetch;
  logic g0_io_msStatus_7_valid, i0_io_msStatus_7_valid;
  logic [2:0] g0_io_msStatus_7_bits_channel, i0_io_msStatus_7_bits_channel;
  logic [8:0] g0_io_msStatus_7_bits_set, i0_io_msStatus_7_bits_set;
  logic [30:0] g0_io_msStatus_7_bits_reqTag, i0_io_msStatus_7_bits_reqTag;
  logic g0_io_msStatus_7_bits_is_miss, i0_io_msStatus_7_bits_is_miss;
  logic g0_io_msStatus_7_bits_is_prefetch, i0_io_msStatus_7_bits_is_prefetch;
  logic g0_io_msStatus_8_valid, i0_io_msStatus_8_valid;
  logic [2:0] g0_io_msStatus_8_bits_channel, i0_io_msStatus_8_bits_channel;
  logic [8:0] g0_io_msStatus_8_bits_set, i0_io_msStatus_8_bits_set;
  logic [30:0] g0_io_msStatus_8_bits_reqTag, i0_io_msStatus_8_bits_reqTag;
  logic g0_io_msStatus_8_bits_is_miss, i0_io_msStatus_8_bits_is_miss;
  logic g0_io_msStatus_8_bits_is_prefetch, i0_io_msStatus_8_bits_is_prefetch;
  logic g0_io_msStatus_9_valid, i0_io_msStatus_9_valid;
  logic [2:0] g0_io_msStatus_9_bits_channel, i0_io_msStatus_9_bits_channel;
  logic [8:0] g0_io_msStatus_9_bits_set, i0_io_msStatus_9_bits_set;
  logic [30:0] g0_io_msStatus_9_bits_reqTag, i0_io_msStatus_9_bits_reqTag;
  logic g0_io_msStatus_9_bits_is_miss, i0_io_msStatus_9_bits_is_miss;
  logic g0_io_msStatus_9_bits_is_prefetch, i0_io_msStatus_9_bits_is_prefetch;
  logic g0_io_msStatus_10_valid, i0_io_msStatus_10_valid;
  logic [2:0] g0_io_msStatus_10_bits_channel, i0_io_msStatus_10_bits_channel;
  logic [8:0] g0_io_msStatus_10_bits_set, i0_io_msStatus_10_bits_set;
  logic [30:0] g0_io_msStatus_10_bits_reqTag, i0_io_msStatus_10_bits_reqTag;
  logic g0_io_msStatus_10_bits_is_miss, i0_io_msStatus_10_bits_is_miss;
  logic g0_io_msStatus_10_bits_is_prefetch, i0_io_msStatus_10_bits_is_prefetch;
  logic g0_io_msStatus_11_valid, i0_io_msStatus_11_valid;
  logic [2:0] g0_io_msStatus_11_bits_channel, i0_io_msStatus_11_bits_channel;
  logic [8:0] g0_io_msStatus_11_bits_set, i0_io_msStatus_11_bits_set;
  logic [30:0] g0_io_msStatus_11_bits_reqTag, i0_io_msStatus_11_bits_reqTag;
  logic g0_io_msStatus_11_bits_is_miss, i0_io_msStatus_11_bits_is_miss;
  logic g0_io_msStatus_11_bits_is_prefetch, i0_io_msStatus_11_bits_is_prefetch;
  logic g0_io_msStatus_12_valid, i0_io_msStatus_12_valid;
  logic [2:0] g0_io_msStatus_12_bits_channel, i0_io_msStatus_12_bits_channel;
  logic [8:0] g0_io_msStatus_12_bits_set, i0_io_msStatus_12_bits_set;
  logic [30:0] g0_io_msStatus_12_bits_reqTag, i0_io_msStatus_12_bits_reqTag;
  logic g0_io_msStatus_12_bits_is_miss, i0_io_msStatus_12_bits_is_miss;
  logic g0_io_msStatus_12_bits_is_prefetch, i0_io_msStatus_12_bits_is_prefetch;
  logic g0_io_msStatus_13_valid, i0_io_msStatus_13_valid;
  logic [2:0] g0_io_msStatus_13_bits_channel, i0_io_msStatus_13_bits_channel;
  logic [8:0] g0_io_msStatus_13_bits_set, i0_io_msStatus_13_bits_set;
  logic [30:0] g0_io_msStatus_13_bits_reqTag, i0_io_msStatus_13_bits_reqTag;
  logic g0_io_msStatus_13_bits_is_miss, i0_io_msStatus_13_bits_is_miss;
  logic g0_io_msStatus_13_bits_is_prefetch, i0_io_msStatus_13_bits_is_prefetch;
  logic g0_io_msStatus_14_valid, i0_io_msStatus_14_valid;
  logic [2:0] g0_io_msStatus_14_bits_channel, i0_io_msStatus_14_bits_channel;
  logic [8:0] g0_io_msStatus_14_bits_set, i0_io_msStatus_14_bits_set;
  logic [30:0] g0_io_msStatus_14_bits_reqTag, i0_io_msStatus_14_bits_reqTag;
  logic g0_io_msStatus_14_bits_is_miss, i0_io_msStatus_14_bits_is_miss;
  logic g0_io_msStatus_14_bits_is_prefetch, i0_io_msStatus_14_bits_is_prefetch;
  logic g0_io_msStatus_15_valid, i0_io_msStatus_15_valid;
  logic [2:0] g0_io_msStatus_15_bits_channel, i0_io_msStatus_15_bits_channel;
  logic [8:0] g0_io_msStatus_15_bits_set, i0_io_msStatus_15_bits_set;
  logic [30:0] g0_io_msStatus_15_bits_reqTag, i0_io_msStatus_15_bits_reqTag;
  logic g0_io_msStatus_15_bits_is_miss, i0_io_msStatus_15_bits_is_miss;
  logic g0_io_msStatus_15_bits_is_prefetch, i0_io_msStatus_15_bits_is_prefetch;
  logic g0_io_msAlloc_0_valid, i0_io_msAlloc_0_valid;
  logic [2:0] g0_io_msAlloc_0_bits_channel, i0_io_msAlloc_0_bits_channel;
  logic g0_io_msAlloc_0_bits_is_miss, i0_io_msAlloc_0_bits_is_miss;
  logic g0_io_msAlloc_0_bits_is_prefetch, i0_io_msAlloc_0_bits_is_prefetch;
  logic g0_io_msAlloc_1_valid, i0_io_msAlloc_1_valid;
  logic [2:0] g0_io_msAlloc_1_bits_channel, i0_io_msAlloc_1_bits_channel;
  logic g0_io_msAlloc_1_bits_is_miss, i0_io_msAlloc_1_bits_is_miss;
  logic g0_io_msAlloc_1_bits_is_prefetch, i0_io_msAlloc_1_bits_is_prefetch;
  logic g0_io_msAlloc_2_valid, i0_io_msAlloc_2_valid;
  logic [2:0] g0_io_msAlloc_2_bits_channel, i0_io_msAlloc_2_bits_channel;
  logic g0_io_msAlloc_2_bits_is_miss, i0_io_msAlloc_2_bits_is_miss;
  logic g0_io_msAlloc_2_bits_is_prefetch, i0_io_msAlloc_2_bits_is_prefetch;
  logic g0_io_msAlloc_3_valid, i0_io_msAlloc_3_valid;
  logic [2:0] g0_io_msAlloc_3_bits_channel, i0_io_msAlloc_3_bits_channel;
  logic g0_io_msAlloc_3_bits_is_miss, i0_io_msAlloc_3_bits_is_miss;
  logic g0_io_msAlloc_3_bits_is_prefetch, i0_io_msAlloc_3_bits_is_prefetch;
  logic g0_io_msAlloc_4_valid, i0_io_msAlloc_4_valid;
  logic [2:0] g0_io_msAlloc_4_bits_channel, i0_io_msAlloc_4_bits_channel;
  logic g0_io_msAlloc_4_bits_is_miss, i0_io_msAlloc_4_bits_is_miss;
  logic g0_io_msAlloc_4_bits_is_prefetch, i0_io_msAlloc_4_bits_is_prefetch;
  logic g0_io_msAlloc_5_valid, i0_io_msAlloc_5_valid;
  logic [2:0] g0_io_msAlloc_5_bits_channel, i0_io_msAlloc_5_bits_channel;
  logic g0_io_msAlloc_5_bits_is_miss, i0_io_msAlloc_5_bits_is_miss;
  logic g0_io_msAlloc_5_bits_is_prefetch, i0_io_msAlloc_5_bits_is_prefetch;
  logic g0_io_msAlloc_6_valid, i0_io_msAlloc_6_valid;
  logic [2:0] g0_io_msAlloc_6_bits_channel, i0_io_msAlloc_6_bits_channel;
  logic g0_io_msAlloc_6_bits_is_miss, i0_io_msAlloc_6_bits_is_miss;
  logic g0_io_msAlloc_6_bits_is_prefetch, i0_io_msAlloc_6_bits_is_prefetch;
  logic g0_io_msAlloc_7_valid, i0_io_msAlloc_7_valid;
  logic [2:0] g0_io_msAlloc_7_bits_channel, i0_io_msAlloc_7_bits_channel;
  logic g0_io_msAlloc_7_bits_is_miss, i0_io_msAlloc_7_bits_is_miss;
  logic g0_io_msAlloc_7_bits_is_prefetch, i0_io_msAlloc_7_bits_is_prefetch;
  logic g0_io_msAlloc_8_valid, i0_io_msAlloc_8_valid;
  logic [2:0] g0_io_msAlloc_8_bits_channel, i0_io_msAlloc_8_bits_channel;
  logic g0_io_msAlloc_8_bits_is_miss, i0_io_msAlloc_8_bits_is_miss;
  logic g0_io_msAlloc_8_bits_is_prefetch, i0_io_msAlloc_8_bits_is_prefetch;
  logic g0_io_msAlloc_9_valid, i0_io_msAlloc_9_valid;
  logic [2:0] g0_io_msAlloc_9_bits_channel, i0_io_msAlloc_9_bits_channel;
  logic g0_io_msAlloc_9_bits_is_miss, i0_io_msAlloc_9_bits_is_miss;
  logic g0_io_msAlloc_9_bits_is_prefetch, i0_io_msAlloc_9_bits_is_prefetch;
  logic g0_io_msAlloc_10_valid, i0_io_msAlloc_10_valid;
  logic [2:0] g0_io_msAlloc_10_bits_channel, i0_io_msAlloc_10_bits_channel;
  logic g0_io_msAlloc_10_bits_is_miss, i0_io_msAlloc_10_bits_is_miss;
  logic g0_io_msAlloc_10_bits_is_prefetch, i0_io_msAlloc_10_bits_is_prefetch;
  logic g0_io_msAlloc_11_valid, i0_io_msAlloc_11_valid;
  logic [2:0] g0_io_msAlloc_11_bits_channel, i0_io_msAlloc_11_bits_channel;
  logic g0_io_msAlloc_11_bits_is_miss, i0_io_msAlloc_11_bits_is_miss;
  logic g0_io_msAlloc_11_bits_is_prefetch, i0_io_msAlloc_11_bits_is_prefetch;
  logic g0_io_msAlloc_12_valid, i0_io_msAlloc_12_valid;
  logic [2:0] g0_io_msAlloc_12_bits_channel, i0_io_msAlloc_12_bits_channel;
  logic g0_io_msAlloc_12_bits_is_miss, i0_io_msAlloc_12_bits_is_miss;
  logic g0_io_msAlloc_12_bits_is_prefetch, i0_io_msAlloc_12_bits_is_prefetch;
  logic g0_io_msAlloc_13_valid, i0_io_msAlloc_13_valid;
  logic [2:0] g0_io_msAlloc_13_bits_channel, i0_io_msAlloc_13_bits_channel;
  logic g0_io_msAlloc_13_bits_is_miss, i0_io_msAlloc_13_bits_is_miss;
  logic g0_io_msAlloc_13_bits_is_prefetch, i0_io_msAlloc_13_bits_is_prefetch;
  logic g0_io_msAlloc_14_valid, i0_io_msAlloc_14_valid;
  logic [2:0] g0_io_msAlloc_14_bits_channel, i0_io_msAlloc_14_bits_channel;
  logic g0_io_msAlloc_14_bits_is_miss, i0_io_msAlloc_14_bits_is_miss;
  logic g0_io_msAlloc_14_bits_is_prefetch, i0_io_msAlloc_14_bits_is_prefetch;
  logic g0_io_msAlloc_15_valid, i0_io_msAlloc_15_valid;
  logic [2:0] g0_io_msAlloc_15_bits_channel, i0_io_msAlloc_15_bits_channel;
  logic g0_io_msAlloc_15_bits_is_miss, i0_io_msAlloc_15_bits_is_miss;
  logic g0_io_msAlloc_15_bits_is_prefetch, i0_io_msAlloc_15_bits_is_prefetch;
  logic g0_io_out_tx_req_valid, i0_io_out_tx_req_valid;
  logic [3:0] g0_io_out_tx_req_bits_qos, i0_io_out_tx_req_bits_qos;
  logic [11:0] g0_io_out_tx_req_bits_txnID, i0_io_out_tx_req_bits_txnID;
  logic [10:0] g0_io_out_tx_req_bits_returnNID, i0_io_out_tx_req_bits_returnNID;
  logic g0_io_out_tx_req_bits_stashNIDValid, i0_io_out_tx_req_bits_stashNIDValid;
  logic [11:0] g0_io_out_tx_req_bits_returnTxnID, i0_io_out_tx_req_bits_returnTxnID;
  logic [6:0] g0_io_out_tx_req_bits_opcode, i0_io_out_tx_req_bits_opcode;
  logic [47:0] g0_io_out_tx_req_bits_addr, i0_io_out_tx_req_bits_addr;
  logic g0_io_out_tx_req_bits_ns, i0_io_out_tx_req_bits_ns;
  logic g0_io_out_tx_req_bits_likelyshared, i0_io_out_tx_req_bits_likelyshared;
  logic g0_io_out_tx_req_bits_allowRetry, i0_io_out_tx_req_bits_allowRetry;
  logic [1:0] g0_io_out_tx_req_bits_order, i0_io_out_tx_req_bits_order;
  logic [3:0] g0_io_out_tx_req_bits_pCrdType, i0_io_out_tx_req_bits_pCrdType;
  logic g0_io_out_tx_req_bits_memAttr_allocate, i0_io_out_tx_req_bits_memAttr_allocate;
  logic g0_io_out_tx_req_bits_memAttr_cacheable, i0_io_out_tx_req_bits_memAttr_cacheable;
  logic g0_io_out_tx_req_bits_memAttr_device, i0_io_out_tx_req_bits_memAttr_device;
  logic g0_io_out_tx_req_bits_memAttr_ewa, i0_io_out_tx_req_bits_memAttr_ewa;
  logic g0_io_out_tx_req_bits_snpAttr, i0_io_out_tx_req_bits_snpAttr;
  logic [7:0] g0_io_out_tx_req_bits_lpIDWithPadding, i0_io_out_tx_req_bits_lpIDWithPadding;
  logic g0_io_out_tx_req_bits_snoopMe, i0_io_out_tx_req_bits_snoopMe;
  logic g0_io_out_tx_req_bits_expCompAck, i0_io_out_tx_req_bits_expCompAck;
  logic [1:0] g0_io_out_tx_req_bits_tagOp, i0_io_out_tx_req_bits_tagOp;
  logic g0_io_out_tx_req_bits_traceTag, i0_io_out_tx_req_bits_traceTag;
  logic g0_io_out_tx_req_bits_mpam_perfMonGroup, i0_io_out_tx_req_bits_mpam_perfMonGroup;
  logic [8:0] g0_io_out_tx_req_bits_mpam_partID, i0_io_out_tx_req_bits_mpam_partID;
  logic g0_io_out_tx_req_bits_mpam_mpamNS, i0_io_out_tx_req_bits_mpam_mpamNS;
  logic [3:0] g0_io_out_tx_req_bits_rsvdc, i0_io_out_tx_req_bits_rsvdc;
  logic g0_io_out_tx_rsp_valid, i0_io_out_tx_rsp_valid;
  logic [3:0] g0_io_out_tx_rsp_bits_qos, i0_io_out_tx_rsp_bits_qos;
  logic [10:0] g0_io_out_tx_rsp_bits_tgtID, i0_io_out_tx_rsp_bits_tgtID;
  logic [11:0] g0_io_out_tx_rsp_bits_txnID, i0_io_out_tx_rsp_bits_txnID;
  logic [4:0] g0_io_out_tx_rsp_bits_opcode, i0_io_out_tx_rsp_bits_opcode;
  logic [1:0] g0_io_out_tx_rsp_bits_respErr, i0_io_out_tx_rsp_bits_respErr;
  logic [2:0] g0_io_out_tx_rsp_bits_resp, i0_io_out_tx_rsp_bits_resp;
  logic [2:0] g0_io_out_tx_rsp_bits_fwdState, i0_io_out_tx_rsp_bits_fwdState;
  logic [2:0] g0_io_out_tx_rsp_bits_cBusy, i0_io_out_tx_rsp_bits_cBusy;
  logic [11:0] g0_io_out_tx_rsp_bits_dbID, i0_io_out_tx_rsp_bits_dbID;
  logic [3:0] g0_io_out_tx_rsp_bits_pCrdType, i0_io_out_tx_rsp_bits_pCrdType;
  logic [1:0] g0_io_out_tx_rsp_bits_tagOp, i0_io_out_tx_rsp_bits_tagOp;
  logic g0_io_out_tx_rsp_bits_traceTag, i0_io_out_tx_rsp_bits_traceTag;
  logic g0_io_out_tx_dat_valid, i0_io_out_tx_dat_valid;
  logic [10:0] g0_io_out_tx_dat_bits_tgtID, i0_io_out_tx_dat_bits_tgtID;
  logic [11:0] g0_io_out_tx_dat_bits_txnID, i0_io_out_tx_dat_bits_txnID;
  logic [10:0] g0_io_out_tx_dat_bits_homeNID, i0_io_out_tx_dat_bits_homeNID;
  logic [3:0] g0_io_out_tx_dat_bits_opcode, i0_io_out_tx_dat_bits_opcode;
  logic [1:0] g0_io_out_tx_dat_bits_respErr, i0_io_out_tx_dat_bits_respErr;
  logic [2:0] g0_io_out_tx_dat_bits_resp, i0_io_out_tx_dat_bits_resp;
  logic [3:0] g0_io_out_tx_dat_bits_dataSource, i0_io_out_tx_dat_bits_dataSource;
  logic [11:0] g0_io_out_tx_dat_bits_dbID, i0_io_out_tx_dat_bits_dbID;
  logic [1:0] g0_io_out_tx_dat_bits_ccID, i0_io_out_tx_dat_bits_ccID;
  logic [1:0] g0_io_out_tx_dat_bits_dataID, i0_io_out_tx_dat_bits_dataID;
  logic g0_io_out_tx_dat_bits_traceTag, i0_io_out_tx_dat_bits_traceTag;
  logic [31:0] g0_io_out_tx_dat_bits_be, i0_io_out_tx_dat_bits_be;
  logic [255:0] g0_io_out_tx_dat_bits_data, i0_io_out_tx_dat_bits_data;
  logic [31:0] g0_io_out_tx_dat_bits_dataCheck, i0_io_out_tx_dat_bits_dataCheck;
  logic [3:0] g0_io_out_tx_dat_bits_poison, i0_io_out_tx_dat_bits_poison;
  logic g0_io_out_rx_snp_ready, i0_io_out_rx_snp_ready;
  logic g0_io_pCrd_0_query_valid, i0_io_pCrd_0_query_valid;
  logic [3:0] g0_io_pCrd_0_query_bits_pCrdType, i0_io_pCrd_0_query_bits_pCrdType;
  logic [10:0] g0_io_pCrd_0_query_bits_srcID, i0_io_pCrd_0_query_bits_srcID;
  logic g0_io_pCrd_1_query_valid, i0_io_pCrd_1_query_valid;
  logic [3:0] g0_io_pCrd_1_query_bits_pCrdType, i0_io_pCrd_1_query_bits_pCrdType;
  logic [10:0] g0_io_pCrd_1_query_bits_srcID, i0_io_pCrd_1_query_bits_srcID;
  logic g0_io_pCrd_2_query_valid, i0_io_pCrd_2_query_valid;
  logic [3:0] g0_io_pCrd_2_query_bits_pCrdType, i0_io_pCrd_2_query_bits_pCrdType;
  logic [10:0] g0_io_pCrd_2_query_bits_srcID, i0_io_pCrd_2_query_bits_srcID;
  logic g0_io_pCrd_3_query_valid, i0_io_pCrd_3_query_valid;
  logic [3:0] g0_io_pCrd_3_query_bits_pCrdType, i0_io_pCrd_3_query_bits_pCrdType;
  logic [10:0] g0_io_pCrd_3_query_bits_srcID, i0_io_pCrd_3_query_bits_srcID;
  logic g0_io_pCrd_4_query_valid, i0_io_pCrd_4_query_valid;
  logic [3:0] g0_io_pCrd_4_query_bits_pCrdType, i0_io_pCrd_4_query_bits_pCrdType;
  logic [10:0] g0_io_pCrd_4_query_bits_srcID, i0_io_pCrd_4_query_bits_srcID;
  logic g0_io_pCrd_5_query_valid, i0_io_pCrd_5_query_valid;
  logic [3:0] g0_io_pCrd_5_query_bits_pCrdType, i0_io_pCrd_5_query_bits_pCrdType;
  logic [10:0] g0_io_pCrd_5_query_bits_srcID, i0_io_pCrd_5_query_bits_srcID;
  logic g0_io_pCrd_6_query_valid, i0_io_pCrd_6_query_valid;
  logic [3:0] g0_io_pCrd_6_query_bits_pCrdType, i0_io_pCrd_6_query_bits_pCrdType;
  logic [10:0] g0_io_pCrd_6_query_bits_srcID, i0_io_pCrd_6_query_bits_srcID;
  logic g0_io_pCrd_7_query_valid, i0_io_pCrd_7_query_valid;
  logic [3:0] g0_io_pCrd_7_query_bits_pCrdType, i0_io_pCrd_7_query_bits_pCrdType;
  logic [10:0] g0_io_pCrd_7_query_bits_srcID, i0_io_pCrd_7_query_bits_srcID;
  logic g0_io_pCrd_8_query_valid, i0_io_pCrd_8_query_valid;
  logic [3:0] g0_io_pCrd_8_query_bits_pCrdType, i0_io_pCrd_8_query_bits_pCrdType;
  logic [10:0] g0_io_pCrd_8_query_bits_srcID, i0_io_pCrd_8_query_bits_srcID;
  logic g0_io_pCrd_9_query_valid, i0_io_pCrd_9_query_valid;
  logic [3:0] g0_io_pCrd_9_query_bits_pCrdType, i0_io_pCrd_9_query_bits_pCrdType;
  logic [10:0] g0_io_pCrd_9_query_bits_srcID, i0_io_pCrd_9_query_bits_srcID;
  logic g0_io_pCrd_10_query_valid, i0_io_pCrd_10_query_valid;
  logic [3:0] g0_io_pCrd_10_query_bits_pCrdType, i0_io_pCrd_10_query_bits_pCrdType;
  logic [10:0] g0_io_pCrd_10_query_bits_srcID, i0_io_pCrd_10_query_bits_srcID;
  logic g0_io_pCrd_11_query_valid, i0_io_pCrd_11_query_valid;
  logic [3:0] g0_io_pCrd_11_query_bits_pCrdType, i0_io_pCrd_11_query_bits_pCrdType;
  logic [10:0] g0_io_pCrd_11_query_bits_srcID, i0_io_pCrd_11_query_bits_srcID;
  logic g0_io_pCrd_12_query_valid, i0_io_pCrd_12_query_valid;
  logic [3:0] g0_io_pCrd_12_query_bits_pCrdType, i0_io_pCrd_12_query_bits_pCrdType;
  logic [10:0] g0_io_pCrd_12_query_bits_srcID, i0_io_pCrd_12_query_bits_srcID;
  logic g0_io_pCrd_13_query_valid, i0_io_pCrd_13_query_valid;
  logic [3:0] g0_io_pCrd_13_query_bits_pCrdType, i0_io_pCrd_13_query_bits_pCrdType;
  logic [10:0] g0_io_pCrd_13_query_bits_srcID, i0_io_pCrd_13_query_bits_srcID;
  logic g0_io_pCrd_14_query_valid, i0_io_pCrd_14_query_valid;
  logic [3:0] g0_io_pCrd_14_query_bits_pCrdType, i0_io_pCrd_14_query_bits_pCrdType;
  logic [10:0] g0_io_pCrd_14_query_bits_srcID, i0_io_pCrd_14_query_bits_srcID;
  logic g0_io_pCrd_15_query_valid, i0_io_pCrd_15_query_valid;
  logic [3:0] g0_io_pCrd_15_query_bits_pCrdType, i0_io_pCrd_15_query_bits_pCrdType;
  logic [10:0] g0_io_pCrd_15_query_bits_srcID, i0_io_pCrd_15_query_bits_srcID;
  logic [5:0] g0_io_perf_0_value, i0_io_perf_0_value;
  logic [5:0] g0_io_perf_1_value, i0_io_perf_1_value;
  logic [5:0] g0_io_perf_3_value, i0_io_perf_3_value;
  logic [5:0] g0_io_perf_4_value, i0_io_perf_4_value;
  logic [5:0] g0_io_perf_5_value, i0_io_perf_5_value;
  logic [5:0] g0_io_perf_6_value, i0_io_perf_6_value;
  logic [5:0] g0_io_perf_7_value, i0_io_perf_7_value;
  logic [5:0] g0_io_perf_8_value, i0_io_perf_8_value;
  logic [5:0] g0_io_perf_9_value, i0_io_perf_9_value;
  logic [5:0] g0_io_perf_10_value, i0_io_perf_10_value;
  logic [5:0] g0_io_perf_11_value, i0_io_perf_11_value;
  logic [5:0] g0_io_perf_12_value, i0_io_perf_12_value;
  logic [5:0] g0_io_perf_13_value, i0_io_perf_13_value;
  logic [5:0] g0_io_perf_14_value, i0_io_perf_14_value;
  logic [5:0] g0_io_perf_15_value, i0_io_perf_15_value;
  logic [5:0] g0_io_perf_16_value, i0_io_perf_16_value;
  logic g0_boreChildrenBd_bore_ack, i0_boreChildrenBd_bore_ack;
  logic [136:0] g0_boreChildrenBd_bore_outdata, i0_boreChildrenBd_bore_outdata;
  logic g1_io_in_a_ready, i1_io_in_a_ready;
  logic g1_io_in_b_valid, i1_io_in_b_valid;
  logic [2:0] g1_io_in_b_bits_opcode, i1_io_in_b_bits_opcode;
  logic [1:0] g1_io_in_b_bits_param, i1_io_in_b_bits_param;
  logic [47:0] g1_io_in_b_bits_address, i1_io_in_b_bits_address;
  logic [255:0] g1_io_in_b_bits_data, i1_io_in_b_bits_data;
  logic g1_io_in_c_ready, i1_io_in_c_ready;
  logic g1_io_in_d_valid, i1_io_in_d_valid;
  logic [3:0] g1_io_in_d_bits_opcode, i1_io_in_d_bits_opcode;
  logic [1:0] g1_io_in_d_bits_param, i1_io_in_d_bits_param;
  logic [6:0] g1_io_in_d_bits_source, i1_io_in_d_bits_source;
  logic [7:0] g1_io_in_d_bits_sink, i1_io_in_d_bits_sink;
  logic g1_io_in_d_bits_denied, i1_io_in_d_bits_denied;
  logic g1_io_in_d_bits_echo_isKeyword, i1_io_in_d_bits_echo_isKeyword;
  logic [255:0] g1_io_in_d_bits_data, i1_io_in_d_bits_data;
  logic g1_io_in_d_bits_corrupt, i1_io_in_d_bits_corrupt;
  logic g1_io_l1Hint_valid, i1_io_l1Hint_valid;
  logic [31:0] g1_io_l1Hint_bits_sourceId, i1_io_l1Hint_bits_sourceId;
  logic g1_io_l1Hint_bits_isKeyword, i1_io_l1Hint_bits_isKeyword;
  logic g1_io_prefetch_train_valid, i1_io_prefetch_train_valid;
  logic [32:0] g1_io_prefetch_train_bits_tag, i1_io_prefetch_train_bits_tag;
  logic [8:0] g1_io_prefetch_train_bits_set, i1_io_prefetch_train_bits_set;
  logic g1_io_prefetch_train_bits_needT, i1_io_prefetch_train_bits_needT;
  logic [6:0] g1_io_prefetch_train_bits_source, i1_io_prefetch_train_bits_source;
  logic [43:0] g1_io_prefetch_train_bits_vaddr, i1_io_prefetch_train_bits_vaddr;
  logic g1_io_prefetch_train_bits_hit, i1_io_prefetch_train_bits_hit;
  logic g1_io_prefetch_train_bits_prefetched, i1_io_prefetch_train_bits_prefetched;
  logic [2:0] g1_io_prefetch_train_bits_pfsource, i1_io_prefetch_train_bits_pfsource;
  logic [4:0] g1_io_prefetch_train_bits_reqsource, i1_io_prefetch_train_bits_reqsource;
  logic g1_io_prefetch_req_ready, i1_io_prefetch_req_ready;
  logic g1_io_prefetch_resp_valid, i1_io_prefetch_resp_valid;
  logic [32:0] g1_io_prefetch_resp_bits_tag, i1_io_prefetch_resp_bits_tag;
  logic [8:0] g1_io_prefetch_resp_bits_set, i1_io_prefetch_resp_bits_set;
  logic [43:0] g1_io_prefetch_resp_bits_vaddr, i1_io_prefetch_resp_bits_vaddr;
  logic [4:0] g1_io_prefetch_resp_bits_pfSource, i1_io_prefetch_resp_bits_pfSource;
  logic g1_io_dirResult_valid, i1_io_dirResult_valid;
  logic g1_io_dirResult_bits_hit, i1_io_dirResult_bits_hit;
  logic g1_io_dirResult_bits_meta_prefetch, i1_io_dirResult_bits_meta_prefetch;
  logic [2:0] g1_io_dirResult_bits_meta_prefetchSrc, i1_io_dirResult_bits_meta_prefetchSrc;
  logic [2:0] g1_io_dirResult_bits_replacerInfo_channel, i1_io_dirResult_bits_replacerInfo_channel;
  logic [4:0] g1_io_dirResult_bits_replacerInfo_reqSource, i1_io_dirResult_bits_replacerInfo_reqSource;
  logic g1_io_hitPfInMSHR_valid, i1_io_hitPfInMSHR_valid;
  logic [2:0] g1_io_hitPfInMSHR_bits, i1_io_hitPfInMSHR_bits;
  logic g1_io_pfSent_valid, i1_io_pfSent_valid;
  logic [4:0] g1_io_pfSent_bits, i1_io_pfSent_bits;
  logic g1_io_pfLateInMSHR_valid, i1_io_pfLateInMSHR_valid;
  logic [4:0] g1_io_pfLateInMSHR_bits, i1_io_pfLateInMSHR_bits;
  logic g1_io_error_valid, i1_io_error_valid;
  logic g1_io_error_bits_valid, i1_io_error_bits_valid;
  logic [45:0] g1_io_error_bits_address, i1_io_error_bits_address;
  logic g1_io_l2Miss, i1_io_l2Miss;
  logic g1_io_msStatus_0_valid, i1_io_msStatus_0_valid;
  logic [2:0] g1_io_msStatus_0_bits_channel, i1_io_msStatus_0_bits_channel;
  logic [8:0] g1_io_msStatus_0_bits_set, i1_io_msStatus_0_bits_set;
  logic [30:0] g1_io_msStatus_0_bits_reqTag, i1_io_msStatus_0_bits_reqTag;
  logic g1_io_msStatus_0_bits_is_miss, i1_io_msStatus_0_bits_is_miss;
  logic g1_io_msStatus_0_bits_is_prefetch, i1_io_msStatus_0_bits_is_prefetch;
  logic g1_io_msStatus_1_valid, i1_io_msStatus_1_valid;
  logic [2:0] g1_io_msStatus_1_bits_channel, i1_io_msStatus_1_bits_channel;
  logic [8:0] g1_io_msStatus_1_bits_set, i1_io_msStatus_1_bits_set;
  logic [30:0] g1_io_msStatus_1_bits_reqTag, i1_io_msStatus_1_bits_reqTag;
  logic g1_io_msStatus_1_bits_is_miss, i1_io_msStatus_1_bits_is_miss;
  logic g1_io_msStatus_1_bits_is_prefetch, i1_io_msStatus_1_bits_is_prefetch;
  logic g1_io_msStatus_2_valid, i1_io_msStatus_2_valid;
  logic [2:0] g1_io_msStatus_2_bits_channel, i1_io_msStatus_2_bits_channel;
  logic [8:0] g1_io_msStatus_2_bits_set, i1_io_msStatus_2_bits_set;
  logic [30:0] g1_io_msStatus_2_bits_reqTag, i1_io_msStatus_2_bits_reqTag;
  logic g1_io_msStatus_2_bits_is_miss, i1_io_msStatus_2_bits_is_miss;
  logic g1_io_msStatus_2_bits_is_prefetch, i1_io_msStatus_2_bits_is_prefetch;
  logic g1_io_msStatus_3_valid, i1_io_msStatus_3_valid;
  logic [2:0] g1_io_msStatus_3_bits_channel, i1_io_msStatus_3_bits_channel;
  logic [8:0] g1_io_msStatus_3_bits_set, i1_io_msStatus_3_bits_set;
  logic [30:0] g1_io_msStatus_3_bits_reqTag, i1_io_msStatus_3_bits_reqTag;
  logic g1_io_msStatus_3_bits_is_miss, i1_io_msStatus_3_bits_is_miss;
  logic g1_io_msStatus_3_bits_is_prefetch, i1_io_msStatus_3_bits_is_prefetch;
  logic g1_io_msStatus_4_valid, i1_io_msStatus_4_valid;
  logic [2:0] g1_io_msStatus_4_bits_channel, i1_io_msStatus_4_bits_channel;
  logic [8:0] g1_io_msStatus_4_bits_set, i1_io_msStatus_4_bits_set;
  logic [30:0] g1_io_msStatus_4_bits_reqTag, i1_io_msStatus_4_bits_reqTag;
  logic g1_io_msStatus_4_bits_is_miss, i1_io_msStatus_4_bits_is_miss;
  logic g1_io_msStatus_4_bits_is_prefetch, i1_io_msStatus_4_bits_is_prefetch;
  logic g1_io_msStatus_5_valid, i1_io_msStatus_5_valid;
  logic [2:0] g1_io_msStatus_5_bits_channel, i1_io_msStatus_5_bits_channel;
  logic [8:0] g1_io_msStatus_5_bits_set, i1_io_msStatus_5_bits_set;
  logic [30:0] g1_io_msStatus_5_bits_reqTag, i1_io_msStatus_5_bits_reqTag;
  logic g1_io_msStatus_5_bits_is_miss, i1_io_msStatus_5_bits_is_miss;
  logic g1_io_msStatus_5_bits_is_prefetch, i1_io_msStatus_5_bits_is_prefetch;
  logic g1_io_msStatus_6_valid, i1_io_msStatus_6_valid;
  logic [2:0] g1_io_msStatus_6_bits_channel, i1_io_msStatus_6_bits_channel;
  logic [8:0] g1_io_msStatus_6_bits_set, i1_io_msStatus_6_bits_set;
  logic [30:0] g1_io_msStatus_6_bits_reqTag, i1_io_msStatus_6_bits_reqTag;
  logic g1_io_msStatus_6_bits_is_miss, i1_io_msStatus_6_bits_is_miss;
  logic g1_io_msStatus_6_bits_is_prefetch, i1_io_msStatus_6_bits_is_prefetch;
  logic g1_io_msStatus_7_valid, i1_io_msStatus_7_valid;
  logic [2:0] g1_io_msStatus_7_bits_channel, i1_io_msStatus_7_bits_channel;
  logic [8:0] g1_io_msStatus_7_bits_set, i1_io_msStatus_7_bits_set;
  logic [30:0] g1_io_msStatus_7_bits_reqTag, i1_io_msStatus_7_bits_reqTag;
  logic g1_io_msStatus_7_bits_is_miss, i1_io_msStatus_7_bits_is_miss;
  logic g1_io_msStatus_7_bits_is_prefetch, i1_io_msStatus_7_bits_is_prefetch;
  logic g1_io_msStatus_8_valid, i1_io_msStatus_8_valid;
  logic [2:0] g1_io_msStatus_8_bits_channel, i1_io_msStatus_8_bits_channel;
  logic [8:0] g1_io_msStatus_8_bits_set, i1_io_msStatus_8_bits_set;
  logic [30:0] g1_io_msStatus_8_bits_reqTag, i1_io_msStatus_8_bits_reqTag;
  logic g1_io_msStatus_8_bits_is_miss, i1_io_msStatus_8_bits_is_miss;
  logic g1_io_msStatus_8_bits_is_prefetch, i1_io_msStatus_8_bits_is_prefetch;
  logic g1_io_msStatus_9_valid, i1_io_msStatus_9_valid;
  logic [2:0] g1_io_msStatus_9_bits_channel, i1_io_msStatus_9_bits_channel;
  logic [8:0] g1_io_msStatus_9_bits_set, i1_io_msStatus_9_bits_set;
  logic [30:0] g1_io_msStatus_9_bits_reqTag, i1_io_msStatus_9_bits_reqTag;
  logic g1_io_msStatus_9_bits_is_miss, i1_io_msStatus_9_bits_is_miss;
  logic g1_io_msStatus_9_bits_is_prefetch, i1_io_msStatus_9_bits_is_prefetch;
  logic g1_io_msStatus_10_valid, i1_io_msStatus_10_valid;
  logic [2:0] g1_io_msStatus_10_bits_channel, i1_io_msStatus_10_bits_channel;
  logic [8:0] g1_io_msStatus_10_bits_set, i1_io_msStatus_10_bits_set;
  logic [30:0] g1_io_msStatus_10_bits_reqTag, i1_io_msStatus_10_bits_reqTag;
  logic g1_io_msStatus_10_bits_is_miss, i1_io_msStatus_10_bits_is_miss;
  logic g1_io_msStatus_10_bits_is_prefetch, i1_io_msStatus_10_bits_is_prefetch;
  logic g1_io_msStatus_11_valid, i1_io_msStatus_11_valid;
  logic [2:0] g1_io_msStatus_11_bits_channel, i1_io_msStatus_11_bits_channel;
  logic [8:0] g1_io_msStatus_11_bits_set, i1_io_msStatus_11_bits_set;
  logic [30:0] g1_io_msStatus_11_bits_reqTag, i1_io_msStatus_11_bits_reqTag;
  logic g1_io_msStatus_11_bits_is_miss, i1_io_msStatus_11_bits_is_miss;
  logic g1_io_msStatus_11_bits_is_prefetch, i1_io_msStatus_11_bits_is_prefetch;
  logic g1_io_msStatus_12_valid, i1_io_msStatus_12_valid;
  logic [2:0] g1_io_msStatus_12_bits_channel, i1_io_msStatus_12_bits_channel;
  logic [8:0] g1_io_msStatus_12_bits_set, i1_io_msStatus_12_bits_set;
  logic [30:0] g1_io_msStatus_12_bits_reqTag, i1_io_msStatus_12_bits_reqTag;
  logic g1_io_msStatus_12_bits_is_miss, i1_io_msStatus_12_bits_is_miss;
  logic g1_io_msStatus_12_bits_is_prefetch, i1_io_msStatus_12_bits_is_prefetch;
  logic g1_io_msStatus_13_valid, i1_io_msStatus_13_valid;
  logic [2:0] g1_io_msStatus_13_bits_channel, i1_io_msStatus_13_bits_channel;
  logic [8:0] g1_io_msStatus_13_bits_set, i1_io_msStatus_13_bits_set;
  logic [30:0] g1_io_msStatus_13_bits_reqTag, i1_io_msStatus_13_bits_reqTag;
  logic g1_io_msStatus_13_bits_is_miss, i1_io_msStatus_13_bits_is_miss;
  logic g1_io_msStatus_13_bits_is_prefetch, i1_io_msStatus_13_bits_is_prefetch;
  logic g1_io_msStatus_14_valid, i1_io_msStatus_14_valid;
  logic [2:0] g1_io_msStatus_14_bits_channel, i1_io_msStatus_14_bits_channel;
  logic [8:0] g1_io_msStatus_14_bits_set, i1_io_msStatus_14_bits_set;
  logic [30:0] g1_io_msStatus_14_bits_reqTag, i1_io_msStatus_14_bits_reqTag;
  logic g1_io_msStatus_14_bits_is_miss, i1_io_msStatus_14_bits_is_miss;
  logic g1_io_msStatus_14_bits_is_prefetch, i1_io_msStatus_14_bits_is_prefetch;
  logic g1_io_msStatus_15_valid, i1_io_msStatus_15_valid;
  logic [2:0] g1_io_msStatus_15_bits_channel, i1_io_msStatus_15_bits_channel;
  logic [8:0] g1_io_msStatus_15_bits_set, i1_io_msStatus_15_bits_set;
  logic [30:0] g1_io_msStatus_15_bits_reqTag, i1_io_msStatus_15_bits_reqTag;
  logic g1_io_msStatus_15_bits_is_miss, i1_io_msStatus_15_bits_is_miss;
  logic g1_io_msStatus_15_bits_is_prefetch, i1_io_msStatus_15_bits_is_prefetch;
  logic g1_io_msAlloc_0_valid, i1_io_msAlloc_0_valid;
  logic [2:0] g1_io_msAlloc_0_bits_channel, i1_io_msAlloc_0_bits_channel;
  logic g1_io_msAlloc_0_bits_is_miss, i1_io_msAlloc_0_bits_is_miss;
  logic g1_io_msAlloc_0_bits_is_prefetch, i1_io_msAlloc_0_bits_is_prefetch;
  logic g1_io_msAlloc_1_valid, i1_io_msAlloc_1_valid;
  logic [2:0] g1_io_msAlloc_1_bits_channel, i1_io_msAlloc_1_bits_channel;
  logic g1_io_msAlloc_1_bits_is_miss, i1_io_msAlloc_1_bits_is_miss;
  logic g1_io_msAlloc_1_bits_is_prefetch, i1_io_msAlloc_1_bits_is_prefetch;
  logic g1_io_msAlloc_2_valid, i1_io_msAlloc_2_valid;
  logic [2:0] g1_io_msAlloc_2_bits_channel, i1_io_msAlloc_2_bits_channel;
  logic g1_io_msAlloc_2_bits_is_miss, i1_io_msAlloc_2_bits_is_miss;
  logic g1_io_msAlloc_2_bits_is_prefetch, i1_io_msAlloc_2_bits_is_prefetch;
  logic g1_io_msAlloc_3_valid, i1_io_msAlloc_3_valid;
  logic [2:0] g1_io_msAlloc_3_bits_channel, i1_io_msAlloc_3_bits_channel;
  logic g1_io_msAlloc_3_bits_is_miss, i1_io_msAlloc_3_bits_is_miss;
  logic g1_io_msAlloc_3_bits_is_prefetch, i1_io_msAlloc_3_bits_is_prefetch;
  logic g1_io_msAlloc_4_valid, i1_io_msAlloc_4_valid;
  logic [2:0] g1_io_msAlloc_4_bits_channel, i1_io_msAlloc_4_bits_channel;
  logic g1_io_msAlloc_4_bits_is_miss, i1_io_msAlloc_4_bits_is_miss;
  logic g1_io_msAlloc_4_bits_is_prefetch, i1_io_msAlloc_4_bits_is_prefetch;
  logic g1_io_msAlloc_5_valid, i1_io_msAlloc_5_valid;
  logic [2:0] g1_io_msAlloc_5_bits_channel, i1_io_msAlloc_5_bits_channel;
  logic g1_io_msAlloc_5_bits_is_miss, i1_io_msAlloc_5_bits_is_miss;
  logic g1_io_msAlloc_5_bits_is_prefetch, i1_io_msAlloc_5_bits_is_prefetch;
  logic g1_io_msAlloc_6_valid, i1_io_msAlloc_6_valid;
  logic [2:0] g1_io_msAlloc_6_bits_channel, i1_io_msAlloc_6_bits_channel;
  logic g1_io_msAlloc_6_bits_is_miss, i1_io_msAlloc_6_bits_is_miss;
  logic g1_io_msAlloc_6_bits_is_prefetch, i1_io_msAlloc_6_bits_is_prefetch;
  logic g1_io_msAlloc_7_valid, i1_io_msAlloc_7_valid;
  logic [2:0] g1_io_msAlloc_7_bits_channel, i1_io_msAlloc_7_bits_channel;
  logic g1_io_msAlloc_7_bits_is_miss, i1_io_msAlloc_7_bits_is_miss;
  logic g1_io_msAlloc_7_bits_is_prefetch, i1_io_msAlloc_7_bits_is_prefetch;
  logic g1_io_msAlloc_8_valid, i1_io_msAlloc_8_valid;
  logic [2:0] g1_io_msAlloc_8_bits_channel, i1_io_msAlloc_8_bits_channel;
  logic g1_io_msAlloc_8_bits_is_miss, i1_io_msAlloc_8_bits_is_miss;
  logic g1_io_msAlloc_8_bits_is_prefetch, i1_io_msAlloc_8_bits_is_prefetch;
  logic g1_io_msAlloc_9_valid, i1_io_msAlloc_9_valid;
  logic [2:0] g1_io_msAlloc_9_bits_channel, i1_io_msAlloc_9_bits_channel;
  logic g1_io_msAlloc_9_bits_is_miss, i1_io_msAlloc_9_bits_is_miss;
  logic g1_io_msAlloc_9_bits_is_prefetch, i1_io_msAlloc_9_bits_is_prefetch;
  logic g1_io_msAlloc_10_valid, i1_io_msAlloc_10_valid;
  logic [2:0] g1_io_msAlloc_10_bits_channel, i1_io_msAlloc_10_bits_channel;
  logic g1_io_msAlloc_10_bits_is_miss, i1_io_msAlloc_10_bits_is_miss;
  logic g1_io_msAlloc_10_bits_is_prefetch, i1_io_msAlloc_10_bits_is_prefetch;
  logic g1_io_msAlloc_11_valid, i1_io_msAlloc_11_valid;
  logic [2:0] g1_io_msAlloc_11_bits_channel, i1_io_msAlloc_11_bits_channel;
  logic g1_io_msAlloc_11_bits_is_miss, i1_io_msAlloc_11_bits_is_miss;
  logic g1_io_msAlloc_11_bits_is_prefetch, i1_io_msAlloc_11_bits_is_prefetch;
  logic g1_io_msAlloc_12_valid, i1_io_msAlloc_12_valid;
  logic [2:0] g1_io_msAlloc_12_bits_channel, i1_io_msAlloc_12_bits_channel;
  logic g1_io_msAlloc_12_bits_is_miss, i1_io_msAlloc_12_bits_is_miss;
  logic g1_io_msAlloc_12_bits_is_prefetch, i1_io_msAlloc_12_bits_is_prefetch;
  logic g1_io_msAlloc_13_valid, i1_io_msAlloc_13_valid;
  logic [2:0] g1_io_msAlloc_13_bits_channel, i1_io_msAlloc_13_bits_channel;
  logic g1_io_msAlloc_13_bits_is_miss, i1_io_msAlloc_13_bits_is_miss;
  logic g1_io_msAlloc_13_bits_is_prefetch, i1_io_msAlloc_13_bits_is_prefetch;
  logic g1_io_msAlloc_14_valid, i1_io_msAlloc_14_valid;
  logic [2:0] g1_io_msAlloc_14_bits_channel, i1_io_msAlloc_14_bits_channel;
  logic g1_io_msAlloc_14_bits_is_miss, i1_io_msAlloc_14_bits_is_miss;
  logic g1_io_msAlloc_14_bits_is_prefetch, i1_io_msAlloc_14_bits_is_prefetch;
  logic g1_io_msAlloc_15_valid, i1_io_msAlloc_15_valid;
  logic [2:0] g1_io_msAlloc_15_bits_channel, i1_io_msAlloc_15_bits_channel;
  logic g1_io_msAlloc_15_bits_is_miss, i1_io_msAlloc_15_bits_is_miss;
  logic g1_io_msAlloc_15_bits_is_prefetch, i1_io_msAlloc_15_bits_is_prefetch;
  logic g1_io_out_tx_req_valid, i1_io_out_tx_req_valid;
  logic [3:0] g1_io_out_tx_req_bits_qos, i1_io_out_tx_req_bits_qos;
  logic [11:0] g1_io_out_tx_req_bits_txnID, i1_io_out_tx_req_bits_txnID;
  logic [10:0] g1_io_out_tx_req_bits_returnNID, i1_io_out_tx_req_bits_returnNID;
  logic g1_io_out_tx_req_bits_stashNIDValid, i1_io_out_tx_req_bits_stashNIDValid;
  logic [11:0] g1_io_out_tx_req_bits_returnTxnID, i1_io_out_tx_req_bits_returnTxnID;
  logic [6:0] g1_io_out_tx_req_bits_opcode, i1_io_out_tx_req_bits_opcode;
  logic [47:0] g1_io_out_tx_req_bits_addr, i1_io_out_tx_req_bits_addr;
  logic g1_io_out_tx_req_bits_ns, i1_io_out_tx_req_bits_ns;
  logic g1_io_out_tx_req_bits_likelyshared, i1_io_out_tx_req_bits_likelyshared;
  logic g1_io_out_tx_req_bits_allowRetry, i1_io_out_tx_req_bits_allowRetry;
  logic [1:0] g1_io_out_tx_req_bits_order, i1_io_out_tx_req_bits_order;
  logic [3:0] g1_io_out_tx_req_bits_pCrdType, i1_io_out_tx_req_bits_pCrdType;
  logic g1_io_out_tx_req_bits_memAttr_allocate, i1_io_out_tx_req_bits_memAttr_allocate;
  logic g1_io_out_tx_req_bits_memAttr_cacheable, i1_io_out_tx_req_bits_memAttr_cacheable;
  logic g1_io_out_tx_req_bits_memAttr_device, i1_io_out_tx_req_bits_memAttr_device;
  logic g1_io_out_tx_req_bits_memAttr_ewa, i1_io_out_tx_req_bits_memAttr_ewa;
  logic g1_io_out_tx_req_bits_snpAttr, i1_io_out_tx_req_bits_snpAttr;
  logic [7:0] g1_io_out_tx_req_bits_lpIDWithPadding, i1_io_out_tx_req_bits_lpIDWithPadding;
  logic g1_io_out_tx_req_bits_snoopMe, i1_io_out_tx_req_bits_snoopMe;
  logic g1_io_out_tx_req_bits_expCompAck, i1_io_out_tx_req_bits_expCompAck;
  logic [1:0] g1_io_out_tx_req_bits_tagOp, i1_io_out_tx_req_bits_tagOp;
  logic g1_io_out_tx_req_bits_traceTag, i1_io_out_tx_req_bits_traceTag;
  logic g1_io_out_tx_req_bits_mpam_perfMonGroup, i1_io_out_tx_req_bits_mpam_perfMonGroup;
  logic [8:0] g1_io_out_tx_req_bits_mpam_partID, i1_io_out_tx_req_bits_mpam_partID;
  logic g1_io_out_tx_req_bits_mpam_mpamNS, i1_io_out_tx_req_bits_mpam_mpamNS;
  logic [3:0] g1_io_out_tx_req_bits_rsvdc, i1_io_out_tx_req_bits_rsvdc;
  logic g1_io_out_tx_rsp_valid, i1_io_out_tx_rsp_valid;
  logic [3:0] g1_io_out_tx_rsp_bits_qos, i1_io_out_tx_rsp_bits_qos;
  logic [10:0] g1_io_out_tx_rsp_bits_tgtID, i1_io_out_tx_rsp_bits_tgtID;
  logic [11:0] g1_io_out_tx_rsp_bits_txnID, i1_io_out_tx_rsp_bits_txnID;
  logic [4:0] g1_io_out_tx_rsp_bits_opcode, i1_io_out_tx_rsp_bits_opcode;
  logic [1:0] g1_io_out_tx_rsp_bits_respErr, i1_io_out_tx_rsp_bits_respErr;
  logic [2:0] g1_io_out_tx_rsp_bits_resp, i1_io_out_tx_rsp_bits_resp;
  logic [2:0] g1_io_out_tx_rsp_bits_fwdState, i1_io_out_tx_rsp_bits_fwdState;
  logic [2:0] g1_io_out_tx_rsp_bits_cBusy, i1_io_out_tx_rsp_bits_cBusy;
  logic [11:0] g1_io_out_tx_rsp_bits_dbID, i1_io_out_tx_rsp_bits_dbID;
  logic [3:0] g1_io_out_tx_rsp_bits_pCrdType, i1_io_out_tx_rsp_bits_pCrdType;
  logic [1:0] g1_io_out_tx_rsp_bits_tagOp, i1_io_out_tx_rsp_bits_tagOp;
  logic g1_io_out_tx_rsp_bits_traceTag, i1_io_out_tx_rsp_bits_traceTag;
  logic g1_io_out_tx_dat_valid, i1_io_out_tx_dat_valid;
  logic [10:0] g1_io_out_tx_dat_bits_tgtID, i1_io_out_tx_dat_bits_tgtID;
  logic [11:0] g1_io_out_tx_dat_bits_txnID, i1_io_out_tx_dat_bits_txnID;
  logic [10:0] g1_io_out_tx_dat_bits_homeNID, i1_io_out_tx_dat_bits_homeNID;
  logic [3:0] g1_io_out_tx_dat_bits_opcode, i1_io_out_tx_dat_bits_opcode;
  logic [1:0] g1_io_out_tx_dat_bits_respErr, i1_io_out_tx_dat_bits_respErr;
  logic [2:0] g1_io_out_tx_dat_bits_resp, i1_io_out_tx_dat_bits_resp;
  logic [3:0] g1_io_out_tx_dat_bits_dataSource, i1_io_out_tx_dat_bits_dataSource;
  logic [11:0] g1_io_out_tx_dat_bits_dbID, i1_io_out_tx_dat_bits_dbID;
  logic [1:0] g1_io_out_tx_dat_bits_ccID, i1_io_out_tx_dat_bits_ccID;
  logic [1:0] g1_io_out_tx_dat_bits_dataID, i1_io_out_tx_dat_bits_dataID;
  logic g1_io_out_tx_dat_bits_traceTag, i1_io_out_tx_dat_bits_traceTag;
  logic [31:0] g1_io_out_tx_dat_bits_be, i1_io_out_tx_dat_bits_be;
  logic [255:0] g1_io_out_tx_dat_bits_data, i1_io_out_tx_dat_bits_data;
  logic [31:0] g1_io_out_tx_dat_bits_dataCheck, i1_io_out_tx_dat_bits_dataCheck;
  logic [3:0] g1_io_out_tx_dat_bits_poison, i1_io_out_tx_dat_bits_poison;
  logic g1_io_out_rx_snp_ready, i1_io_out_rx_snp_ready;
  logic g1_io_pCrd_0_query_valid, i1_io_pCrd_0_query_valid;
  logic [3:0] g1_io_pCrd_0_query_bits_pCrdType, i1_io_pCrd_0_query_bits_pCrdType;
  logic [10:0] g1_io_pCrd_0_query_bits_srcID, i1_io_pCrd_0_query_bits_srcID;
  logic g1_io_pCrd_1_query_valid, i1_io_pCrd_1_query_valid;
  logic [3:0] g1_io_pCrd_1_query_bits_pCrdType, i1_io_pCrd_1_query_bits_pCrdType;
  logic [10:0] g1_io_pCrd_1_query_bits_srcID, i1_io_pCrd_1_query_bits_srcID;
  logic g1_io_pCrd_2_query_valid, i1_io_pCrd_2_query_valid;
  logic [3:0] g1_io_pCrd_2_query_bits_pCrdType, i1_io_pCrd_2_query_bits_pCrdType;
  logic [10:0] g1_io_pCrd_2_query_bits_srcID, i1_io_pCrd_2_query_bits_srcID;
  logic g1_io_pCrd_3_query_valid, i1_io_pCrd_3_query_valid;
  logic [3:0] g1_io_pCrd_3_query_bits_pCrdType, i1_io_pCrd_3_query_bits_pCrdType;
  logic [10:0] g1_io_pCrd_3_query_bits_srcID, i1_io_pCrd_3_query_bits_srcID;
  logic g1_io_pCrd_4_query_valid, i1_io_pCrd_4_query_valid;
  logic [3:0] g1_io_pCrd_4_query_bits_pCrdType, i1_io_pCrd_4_query_bits_pCrdType;
  logic [10:0] g1_io_pCrd_4_query_bits_srcID, i1_io_pCrd_4_query_bits_srcID;
  logic g1_io_pCrd_5_query_valid, i1_io_pCrd_5_query_valid;
  logic [3:0] g1_io_pCrd_5_query_bits_pCrdType, i1_io_pCrd_5_query_bits_pCrdType;
  logic [10:0] g1_io_pCrd_5_query_bits_srcID, i1_io_pCrd_5_query_bits_srcID;
  logic g1_io_pCrd_6_query_valid, i1_io_pCrd_6_query_valid;
  logic [3:0] g1_io_pCrd_6_query_bits_pCrdType, i1_io_pCrd_6_query_bits_pCrdType;
  logic [10:0] g1_io_pCrd_6_query_bits_srcID, i1_io_pCrd_6_query_bits_srcID;
  logic g1_io_pCrd_7_query_valid, i1_io_pCrd_7_query_valid;
  logic [3:0] g1_io_pCrd_7_query_bits_pCrdType, i1_io_pCrd_7_query_bits_pCrdType;
  logic [10:0] g1_io_pCrd_7_query_bits_srcID, i1_io_pCrd_7_query_bits_srcID;
  logic g1_io_pCrd_8_query_valid, i1_io_pCrd_8_query_valid;
  logic [3:0] g1_io_pCrd_8_query_bits_pCrdType, i1_io_pCrd_8_query_bits_pCrdType;
  logic [10:0] g1_io_pCrd_8_query_bits_srcID, i1_io_pCrd_8_query_bits_srcID;
  logic g1_io_pCrd_9_query_valid, i1_io_pCrd_9_query_valid;
  logic [3:0] g1_io_pCrd_9_query_bits_pCrdType, i1_io_pCrd_9_query_bits_pCrdType;
  logic [10:0] g1_io_pCrd_9_query_bits_srcID, i1_io_pCrd_9_query_bits_srcID;
  logic g1_io_pCrd_10_query_valid, i1_io_pCrd_10_query_valid;
  logic [3:0] g1_io_pCrd_10_query_bits_pCrdType, i1_io_pCrd_10_query_bits_pCrdType;
  logic [10:0] g1_io_pCrd_10_query_bits_srcID, i1_io_pCrd_10_query_bits_srcID;
  logic g1_io_pCrd_11_query_valid, i1_io_pCrd_11_query_valid;
  logic [3:0] g1_io_pCrd_11_query_bits_pCrdType, i1_io_pCrd_11_query_bits_pCrdType;
  logic [10:0] g1_io_pCrd_11_query_bits_srcID, i1_io_pCrd_11_query_bits_srcID;
  logic g1_io_pCrd_12_query_valid, i1_io_pCrd_12_query_valid;
  logic [3:0] g1_io_pCrd_12_query_bits_pCrdType, i1_io_pCrd_12_query_bits_pCrdType;
  logic [10:0] g1_io_pCrd_12_query_bits_srcID, i1_io_pCrd_12_query_bits_srcID;
  logic g1_io_pCrd_13_query_valid, i1_io_pCrd_13_query_valid;
  logic [3:0] g1_io_pCrd_13_query_bits_pCrdType, i1_io_pCrd_13_query_bits_pCrdType;
  logic [10:0] g1_io_pCrd_13_query_bits_srcID, i1_io_pCrd_13_query_bits_srcID;
  logic g1_io_pCrd_14_query_valid, i1_io_pCrd_14_query_valid;
  logic [3:0] g1_io_pCrd_14_query_bits_pCrdType, i1_io_pCrd_14_query_bits_pCrdType;
  logic [10:0] g1_io_pCrd_14_query_bits_srcID, i1_io_pCrd_14_query_bits_srcID;
  logic g1_io_pCrd_15_query_valid, i1_io_pCrd_15_query_valid;
  logic [3:0] g1_io_pCrd_15_query_bits_pCrdType, i1_io_pCrd_15_query_bits_pCrdType;
  logic [10:0] g1_io_pCrd_15_query_bits_srcID, i1_io_pCrd_15_query_bits_srcID;
  logic [5:0] g1_io_perf_0_value, i1_io_perf_0_value;
  logic [5:0] g1_io_perf_1_value, i1_io_perf_1_value;
  logic [5:0] g1_io_perf_3_value, i1_io_perf_3_value;
  logic [5:0] g1_io_perf_4_value, i1_io_perf_4_value;
  logic [5:0] g1_io_perf_5_value, i1_io_perf_5_value;
  logic [5:0] g1_io_perf_6_value, i1_io_perf_6_value;
  logic [5:0] g1_io_perf_7_value, i1_io_perf_7_value;
  logic [5:0] g1_io_perf_8_value, i1_io_perf_8_value;
  logic [5:0] g1_io_perf_9_value, i1_io_perf_9_value;
  logic [5:0] g1_io_perf_10_value, i1_io_perf_10_value;
  logic [5:0] g1_io_perf_11_value, i1_io_perf_11_value;
  logic [5:0] g1_io_perf_12_value, i1_io_perf_12_value;
  logic [5:0] g1_io_perf_13_value, i1_io_perf_13_value;
  logic [5:0] g1_io_perf_14_value, i1_io_perf_14_value;
  logic [5:0] g1_io_perf_15_value, i1_io_perf_15_value;
  logic [5:0] g1_io_perf_16_value, i1_io_perf_16_value;
  logic g1_boreChildrenBd_bore_ack, i1_boreChildrenBd_bore_ack;
  logic [136:0] g1_boreChildrenBd_bore_outdata, i1_boreChildrenBd_bore_outdata;
  logic g2_io_in_a_ready, i2_io_in_a_ready;
  logic g2_io_in_b_valid, i2_io_in_b_valid;
  logic [2:0] g2_io_in_b_bits_opcode, i2_io_in_b_bits_opcode;
  logic [1:0] g2_io_in_b_bits_param, i2_io_in_b_bits_param;
  logic [47:0] g2_io_in_b_bits_address, i2_io_in_b_bits_address;
  logic [255:0] g2_io_in_b_bits_data, i2_io_in_b_bits_data;
  logic g2_io_in_c_ready, i2_io_in_c_ready;
  logic g2_io_in_d_valid, i2_io_in_d_valid;
  logic [3:0] g2_io_in_d_bits_opcode, i2_io_in_d_bits_opcode;
  logic [1:0] g2_io_in_d_bits_param, i2_io_in_d_bits_param;
  logic [6:0] g2_io_in_d_bits_source, i2_io_in_d_bits_source;
  logic [7:0] g2_io_in_d_bits_sink, i2_io_in_d_bits_sink;
  logic g2_io_in_d_bits_denied, i2_io_in_d_bits_denied;
  logic g2_io_in_d_bits_echo_isKeyword, i2_io_in_d_bits_echo_isKeyword;
  logic [255:0] g2_io_in_d_bits_data, i2_io_in_d_bits_data;
  logic g2_io_in_d_bits_corrupt, i2_io_in_d_bits_corrupt;
  logic g2_io_l1Hint_valid, i2_io_l1Hint_valid;
  logic [31:0] g2_io_l1Hint_bits_sourceId, i2_io_l1Hint_bits_sourceId;
  logic g2_io_l1Hint_bits_isKeyword, i2_io_l1Hint_bits_isKeyword;
  logic g2_io_prefetch_train_valid, i2_io_prefetch_train_valid;
  logic [32:0] g2_io_prefetch_train_bits_tag, i2_io_prefetch_train_bits_tag;
  logic [8:0] g2_io_prefetch_train_bits_set, i2_io_prefetch_train_bits_set;
  logic g2_io_prefetch_train_bits_needT, i2_io_prefetch_train_bits_needT;
  logic [6:0] g2_io_prefetch_train_bits_source, i2_io_prefetch_train_bits_source;
  logic [43:0] g2_io_prefetch_train_bits_vaddr, i2_io_prefetch_train_bits_vaddr;
  logic g2_io_prefetch_train_bits_hit, i2_io_prefetch_train_bits_hit;
  logic g2_io_prefetch_train_bits_prefetched, i2_io_prefetch_train_bits_prefetched;
  logic [2:0] g2_io_prefetch_train_bits_pfsource, i2_io_prefetch_train_bits_pfsource;
  logic [4:0] g2_io_prefetch_train_bits_reqsource, i2_io_prefetch_train_bits_reqsource;
  logic g2_io_prefetch_req_ready, i2_io_prefetch_req_ready;
  logic g2_io_prefetch_resp_valid, i2_io_prefetch_resp_valid;
  logic [32:0] g2_io_prefetch_resp_bits_tag, i2_io_prefetch_resp_bits_tag;
  logic [8:0] g2_io_prefetch_resp_bits_set, i2_io_prefetch_resp_bits_set;
  logic [43:0] g2_io_prefetch_resp_bits_vaddr, i2_io_prefetch_resp_bits_vaddr;
  logic [4:0] g2_io_prefetch_resp_bits_pfSource, i2_io_prefetch_resp_bits_pfSource;
  logic g2_io_dirResult_valid, i2_io_dirResult_valid;
  logic g2_io_dirResult_bits_hit, i2_io_dirResult_bits_hit;
  logic g2_io_dirResult_bits_meta_prefetch, i2_io_dirResult_bits_meta_prefetch;
  logic [2:0] g2_io_dirResult_bits_meta_prefetchSrc, i2_io_dirResult_bits_meta_prefetchSrc;
  logic [2:0] g2_io_dirResult_bits_replacerInfo_channel, i2_io_dirResult_bits_replacerInfo_channel;
  logic [4:0] g2_io_dirResult_bits_replacerInfo_reqSource, i2_io_dirResult_bits_replacerInfo_reqSource;
  logic g2_io_hitPfInMSHR_valid, i2_io_hitPfInMSHR_valid;
  logic [2:0] g2_io_hitPfInMSHR_bits, i2_io_hitPfInMSHR_bits;
  logic g2_io_pfSent_valid, i2_io_pfSent_valid;
  logic [4:0] g2_io_pfSent_bits, i2_io_pfSent_bits;
  logic g2_io_pfLateInMSHR_valid, i2_io_pfLateInMSHR_valid;
  logic [4:0] g2_io_pfLateInMSHR_bits, i2_io_pfLateInMSHR_bits;
  logic g2_io_error_valid, i2_io_error_valid;
  logic g2_io_error_bits_valid, i2_io_error_bits_valid;
  logic [45:0] g2_io_error_bits_address, i2_io_error_bits_address;
  logic g2_io_l2Miss, i2_io_l2Miss;
  logic g2_io_msStatus_0_valid, i2_io_msStatus_0_valid;
  logic [2:0] g2_io_msStatus_0_bits_channel, i2_io_msStatus_0_bits_channel;
  logic [8:0] g2_io_msStatus_0_bits_set, i2_io_msStatus_0_bits_set;
  logic [30:0] g2_io_msStatus_0_bits_reqTag, i2_io_msStatus_0_bits_reqTag;
  logic g2_io_msStatus_0_bits_is_miss, i2_io_msStatus_0_bits_is_miss;
  logic g2_io_msStatus_0_bits_is_prefetch, i2_io_msStatus_0_bits_is_prefetch;
  logic g2_io_msStatus_1_valid, i2_io_msStatus_1_valid;
  logic [2:0] g2_io_msStatus_1_bits_channel, i2_io_msStatus_1_bits_channel;
  logic [8:0] g2_io_msStatus_1_bits_set, i2_io_msStatus_1_bits_set;
  logic [30:0] g2_io_msStatus_1_bits_reqTag, i2_io_msStatus_1_bits_reqTag;
  logic g2_io_msStatus_1_bits_is_miss, i2_io_msStatus_1_bits_is_miss;
  logic g2_io_msStatus_1_bits_is_prefetch, i2_io_msStatus_1_bits_is_prefetch;
  logic g2_io_msStatus_2_valid, i2_io_msStatus_2_valid;
  logic [2:0] g2_io_msStatus_2_bits_channel, i2_io_msStatus_2_bits_channel;
  logic [8:0] g2_io_msStatus_2_bits_set, i2_io_msStatus_2_bits_set;
  logic [30:0] g2_io_msStatus_2_bits_reqTag, i2_io_msStatus_2_bits_reqTag;
  logic g2_io_msStatus_2_bits_is_miss, i2_io_msStatus_2_bits_is_miss;
  logic g2_io_msStatus_2_bits_is_prefetch, i2_io_msStatus_2_bits_is_prefetch;
  logic g2_io_msStatus_3_valid, i2_io_msStatus_3_valid;
  logic [2:0] g2_io_msStatus_3_bits_channel, i2_io_msStatus_3_bits_channel;
  logic [8:0] g2_io_msStatus_3_bits_set, i2_io_msStatus_3_bits_set;
  logic [30:0] g2_io_msStatus_3_bits_reqTag, i2_io_msStatus_3_bits_reqTag;
  logic g2_io_msStatus_3_bits_is_miss, i2_io_msStatus_3_bits_is_miss;
  logic g2_io_msStatus_3_bits_is_prefetch, i2_io_msStatus_3_bits_is_prefetch;
  logic g2_io_msStatus_4_valid, i2_io_msStatus_4_valid;
  logic [2:0] g2_io_msStatus_4_bits_channel, i2_io_msStatus_4_bits_channel;
  logic [8:0] g2_io_msStatus_4_bits_set, i2_io_msStatus_4_bits_set;
  logic [30:0] g2_io_msStatus_4_bits_reqTag, i2_io_msStatus_4_bits_reqTag;
  logic g2_io_msStatus_4_bits_is_miss, i2_io_msStatus_4_bits_is_miss;
  logic g2_io_msStatus_4_bits_is_prefetch, i2_io_msStatus_4_bits_is_prefetch;
  logic g2_io_msStatus_5_valid, i2_io_msStatus_5_valid;
  logic [2:0] g2_io_msStatus_5_bits_channel, i2_io_msStatus_5_bits_channel;
  logic [8:0] g2_io_msStatus_5_bits_set, i2_io_msStatus_5_bits_set;
  logic [30:0] g2_io_msStatus_5_bits_reqTag, i2_io_msStatus_5_bits_reqTag;
  logic g2_io_msStatus_5_bits_is_miss, i2_io_msStatus_5_bits_is_miss;
  logic g2_io_msStatus_5_bits_is_prefetch, i2_io_msStatus_5_bits_is_prefetch;
  logic g2_io_msStatus_6_valid, i2_io_msStatus_6_valid;
  logic [2:0] g2_io_msStatus_6_bits_channel, i2_io_msStatus_6_bits_channel;
  logic [8:0] g2_io_msStatus_6_bits_set, i2_io_msStatus_6_bits_set;
  logic [30:0] g2_io_msStatus_6_bits_reqTag, i2_io_msStatus_6_bits_reqTag;
  logic g2_io_msStatus_6_bits_is_miss, i2_io_msStatus_6_bits_is_miss;
  logic g2_io_msStatus_6_bits_is_prefetch, i2_io_msStatus_6_bits_is_prefetch;
  logic g2_io_msStatus_7_valid, i2_io_msStatus_7_valid;
  logic [2:0] g2_io_msStatus_7_bits_channel, i2_io_msStatus_7_bits_channel;
  logic [8:0] g2_io_msStatus_7_bits_set, i2_io_msStatus_7_bits_set;
  logic [30:0] g2_io_msStatus_7_bits_reqTag, i2_io_msStatus_7_bits_reqTag;
  logic g2_io_msStatus_7_bits_is_miss, i2_io_msStatus_7_bits_is_miss;
  logic g2_io_msStatus_7_bits_is_prefetch, i2_io_msStatus_7_bits_is_prefetch;
  logic g2_io_msStatus_8_valid, i2_io_msStatus_8_valid;
  logic [2:0] g2_io_msStatus_8_bits_channel, i2_io_msStatus_8_bits_channel;
  logic [8:0] g2_io_msStatus_8_bits_set, i2_io_msStatus_8_bits_set;
  logic [30:0] g2_io_msStatus_8_bits_reqTag, i2_io_msStatus_8_bits_reqTag;
  logic g2_io_msStatus_8_bits_is_miss, i2_io_msStatus_8_bits_is_miss;
  logic g2_io_msStatus_8_bits_is_prefetch, i2_io_msStatus_8_bits_is_prefetch;
  logic g2_io_msStatus_9_valid, i2_io_msStatus_9_valid;
  logic [2:0] g2_io_msStatus_9_bits_channel, i2_io_msStatus_9_bits_channel;
  logic [8:0] g2_io_msStatus_9_bits_set, i2_io_msStatus_9_bits_set;
  logic [30:0] g2_io_msStatus_9_bits_reqTag, i2_io_msStatus_9_bits_reqTag;
  logic g2_io_msStatus_9_bits_is_miss, i2_io_msStatus_9_bits_is_miss;
  logic g2_io_msStatus_9_bits_is_prefetch, i2_io_msStatus_9_bits_is_prefetch;
  logic g2_io_msStatus_10_valid, i2_io_msStatus_10_valid;
  logic [2:0] g2_io_msStatus_10_bits_channel, i2_io_msStatus_10_bits_channel;
  logic [8:0] g2_io_msStatus_10_bits_set, i2_io_msStatus_10_bits_set;
  logic [30:0] g2_io_msStatus_10_bits_reqTag, i2_io_msStatus_10_bits_reqTag;
  logic g2_io_msStatus_10_bits_is_miss, i2_io_msStatus_10_bits_is_miss;
  logic g2_io_msStatus_10_bits_is_prefetch, i2_io_msStatus_10_bits_is_prefetch;
  logic g2_io_msStatus_11_valid, i2_io_msStatus_11_valid;
  logic [2:0] g2_io_msStatus_11_bits_channel, i2_io_msStatus_11_bits_channel;
  logic [8:0] g2_io_msStatus_11_bits_set, i2_io_msStatus_11_bits_set;
  logic [30:0] g2_io_msStatus_11_bits_reqTag, i2_io_msStatus_11_bits_reqTag;
  logic g2_io_msStatus_11_bits_is_miss, i2_io_msStatus_11_bits_is_miss;
  logic g2_io_msStatus_11_bits_is_prefetch, i2_io_msStatus_11_bits_is_prefetch;
  logic g2_io_msStatus_12_valid, i2_io_msStatus_12_valid;
  logic [2:0] g2_io_msStatus_12_bits_channel, i2_io_msStatus_12_bits_channel;
  logic [8:0] g2_io_msStatus_12_bits_set, i2_io_msStatus_12_bits_set;
  logic [30:0] g2_io_msStatus_12_bits_reqTag, i2_io_msStatus_12_bits_reqTag;
  logic g2_io_msStatus_12_bits_is_miss, i2_io_msStatus_12_bits_is_miss;
  logic g2_io_msStatus_12_bits_is_prefetch, i2_io_msStatus_12_bits_is_prefetch;
  logic g2_io_msStatus_13_valid, i2_io_msStatus_13_valid;
  logic [2:0] g2_io_msStatus_13_bits_channel, i2_io_msStatus_13_bits_channel;
  logic [8:0] g2_io_msStatus_13_bits_set, i2_io_msStatus_13_bits_set;
  logic [30:0] g2_io_msStatus_13_bits_reqTag, i2_io_msStatus_13_bits_reqTag;
  logic g2_io_msStatus_13_bits_is_miss, i2_io_msStatus_13_bits_is_miss;
  logic g2_io_msStatus_13_bits_is_prefetch, i2_io_msStatus_13_bits_is_prefetch;
  logic g2_io_msStatus_14_valid, i2_io_msStatus_14_valid;
  logic [2:0] g2_io_msStatus_14_bits_channel, i2_io_msStatus_14_bits_channel;
  logic [8:0] g2_io_msStatus_14_bits_set, i2_io_msStatus_14_bits_set;
  logic [30:0] g2_io_msStatus_14_bits_reqTag, i2_io_msStatus_14_bits_reqTag;
  logic g2_io_msStatus_14_bits_is_miss, i2_io_msStatus_14_bits_is_miss;
  logic g2_io_msStatus_14_bits_is_prefetch, i2_io_msStatus_14_bits_is_prefetch;
  logic g2_io_msStatus_15_valid, i2_io_msStatus_15_valid;
  logic [2:0] g2_io_msStatus_15_bits_channel, i2_io_msStatus_15_bits_channel;
  logic [8:0] g2_io_msStatus_15_bits_set, i2_io_msStatus_15_bits_set;
  logic [30:0] g2_io_msStatus_15_bits_reqTag, i2_io_msStatus_15_bits_reqTag;
  logic g2_io_msStatus_15_bits_is_miss, i2_io_msStatus_15_bits_is_miss;
  logic g2_io_msStatus_15_bits_is_prefetch, i2_io_msStatus_15_bits_is_prefetch;
  logic g2_io_msAlloc_0_valid, i2_io_msAlloc_0_valid;
  logic [2:0] g2_io_msAlloc_0_bits_channel, i2_io_msAlloc_0_bits_channel;
  logic g2_io_msAlloc_0_bits_is_miss, i2_io_msAlloc_0_bits_is_miss;
  logic g2_io_msAlloc_0_bits_is_prefetch, i2_io_msAlloc_0_bits_is_prefetch;
  logic g2_io_msAlloc_1_valid, i2_io_msAlloc_1_valid;
  logic [2:0] g2_io_msAlloc_1_bits_channel, i2_io_msAlloc_1_bits_channel;
  logic g2_io_msAlloc_1_bits_is_miss, i2_io_msAlloc_1_bits_is_miss;
  logic g2_io_msAlloc_1_bits_is_prefetch, i2_io_msAlloc_1_bits_is_prefetch;
  logic g2_io_msAlloc_2_valid, i2_io_msAlloc_2_valid;
  logic [2:0] g2_io_msAlloc_2_bits_channel, i2_io_msAlloc_2_bits_channel;
  logic g2_io_msAlloc_2_bits_is_miss, i2_io_msAlloc_2_bits_is_miss;
  logic g2_io_msAlloc_2_bits_is_prefetch, i2_io_msAlloc_2_bits_is_prefetch;
  logic g2_io_msAlloc_3_valid, i2_io_msAlloc_3_valid;
  logic [2:0] g2_io_msAlloc_3_bits_channel, i2_io_msAlloc_3_bits_channel;
  logic g2_io_msAlloc_3_bits_is_miss, i2_io_msAlloc_3_bits_is_miss;
  logic g2_io_msAlloc_3_bits_is_prefetch, i2_io_msAlloc_3_bits_is_prefetch;
  logic g2_io_msAlloc_4_valid, i2_io_msAlloc_4_valid;
  logic [2:0] g2_io_msAlloc_4_bits_channel, i2_io_msAlloc_4_bits_channel;
  logic g2_io_msAlloc_4_bits_is_miss, i2_io_msAlloc_4_bits_is_miss;
  logic g2_io_msAlloc_4_bits_is_prefetch, i2_io_msAlloc_4_bits_is_prefetch;
  logic g2_io_msAlloc_5_valid, i2_io_msAlloc_5_valid;
  logic [2:0] g2_io_msAlloc_5_bits_channel, i2_io_msAlloc_5_bits_channel;
  logic g2_io_msAlloc_5_bits_is_miss, i2_io_msAlloc_5_bits_is_miss;
  logic g2_io_msAlloc_5_bits_is_prefetch, i2_io_msAlloc_5_bits_is_prefetch;
  logic g2_io_msAlloc_6_valid, i2_io_msAlloc_6_valid;
  logic [2:0] g2_io_msAlloc_6_bits_channel, i2_io_msAlloc_6_bits_channel;
  logic g2_io_msAlloc_6_bits_is_miss, i2_io_msAlloc_6_bits_is_miss;
  logic g2_io_msAlloc_6_bits_is_prefetch, i2_io_msAlloc_6_bits_is_prefetch;
  logic g2_io_msAlloc_7_valid, i2_io_msAlloc_7_valid;
  logic [2:0] g2_io_msAlloc_7_bits_channel, i2_io_msAlloc_7_bits_channel;
  logic g2_io_msAlloc_7_bits_is_miss, i2_io_msAlloc_7_bits_is_miss;
  logic g2_io_msAlloc_7_bits_is_prefetch, i2_io_msAlloc_7_bits_is_prefetch;
  logic g2_io_msAlloc_8_valid, i2_io_msAlloc_8_valid;
  logic [2:0] g2_io_msAlloc_8_bits_channel, i2_io_msAlloc_8_bits_channel;
  logic g2_io_msAlloc_8_bits_is_miss, i2_io_msAlloc_8_bits_is_miss;
  logic g2_io_msAlloc_8_bits_is_prefetch, i2_io_msAlloc_8_bits_is_prefetch;
  logic g2_io_msAlloc_9_valid, i2_io_msAlloc_9_valid;
  logic [2:0] g2_io_msAlloc_9_bits_channel, i2_io_msAlloc_9_bits_channel;
  logic g2_io_msAlloc_9_bits_is_miss, i2_io_msAlloc_9_bits_is_miss;
  logic g2_io_msAlloc_9_bits_is_prefetch, i2_io_msAlloc_9_bits_is_prefetch;
  logic g2_io_msAlloc_10_valid, i2_io_msAlloc_10_valid;
  logic [2:0] g2_io_msAlloc_10_bits_channel, i2_io_msAlloc_10_bits_channel;
  logic g2_io_msAlloc_10_bits_is_miss, i2_io_msAlloc_10_bits_is_miss;
  logic g2_io_msAlloc_10_bits_is_prefetch, i2_io_msAlloc_10_bits_is_prefetch;
  logic g2_io_msAlloc_11_valid, i2_io_msAlloc_11_valid;
  logic [2:0] g2_io_msAlloc_11_bits_channel, i2_io_msAlloc_11_bits_channel;
  logic g2_io_msAlloc_11_bits_is_miss, i2_io_msAlloc_11_bits_is_miss;
  logic g2_io_msAlloc_11_bits_is_prefetch, i2_io_msAlloc_11_bits_is_prefetch;
  logic g2_io_msAlloc_12_valid, i2_io_msAlloc_12_valid;
  logic [2:0] g2_io_msAlloc_12_bits_channel, i2_io_msAlloc_12_bits_channel;
  logic g2_io_msAlloc_12_bits_is_miss, i2_io_msAlloc_12_bits_is_miss;
  logic g2_io_msAlloc_12_bits_is_prefetch, i2_io_msAlloc_12_bits_is_prefetch;
  logic g2_io_msAlloc_13_valid, i2_io_msAlloc_13_valid;
  logic [2:0] g2_io_msAlloc_13_bits_channel, i2_io_msAlloc_13_bits_channel;
  logic g2_io_msAlloc_13_bits_is_miss, i2_io_msAlloc_13_bits_is_miss;
  logic g2_io_msAlloc_13_bits_is_prefetch, i2_io_msAlloc_13_bits_is_prefetch;
  logic g2_io_msAlloc_14_valid, i2_io_msAlloc_14_valid;
  logic [2:0] g2_io_msAlloc_14_bits_channel, i2_io_msAlloc_14_bits_channel;
  logic g2_io_msAlloc_14_bits_is_miss, i2_io_msAlloc_14_bits_is_miss;
  logic g2_io_msAlloc_14_bits_is_prefetch, i2_io_msAlloc_14_bits_is_prefetch;
  logic g2_io_msAlloc_15_valid, i2_io_msAlloc_15_valid;
  logic [2:0] g2_io_msAlloc_15_bits_channel, i2_io_msAlloc_15_bits_channel;
  logic g2_io_msAlloc_15_bits_is_miss, i2_io_msAlloc_15_bits_is_miss;
  logic g2_io_msAlloc_15_bits_is_prefetch, i2_io_msAlloc_15_bits_is_prefetch;
  logic g2_io_out_tx_req_valid, i2_io_out_tx_req_valid;
  logic [3:0] g2_io_out_tx_req_bits_qos, i2_io_out_tx_req_bits_qos;
  logic [11:0] g2_io_out_tx_req_bits_txnID, i2_io_out_tx_req_bits_txnID;
  logic [10:0] g2_io_out_tx_req_bits_returnNID, i2_io_out_tx_req_bits_returnNID;
  logic g2_io_out_tx_req_bits_stashNIDValid, i2_io_out_tx_req_bits_stashNIDValid;
  logic [11:0] g2_io_out_tx_req_bits_returnTxnID, i2_io_out_tx_req_bits_returnTxnID;
  logic [6:0] g2_io_out_tx_req_bits_opcode, i2_io_out_tx_req_bits_opcode;
  logic [47:0] g2_io_out_tx_req_bits_addr, i2_io_out_tx_req_bits_addr;
  logic g2_io_out_tx_req_bits_ns, i2_io_out_tx_req_bits_ns;
  logic g2_io_out_tx_req_bits_likelyshared, i2_io_out_tx_req_bits_likelyshared;
  logic g2_io_out_tx_req_bits_allowRetry, i2_io_out_tx_req_bits_allowRetry;
  logic [1:0] g2_io_out_tx_req_bits_order, i2_io_out_tx_req_bits_order;
  logic [3:0] g2_io_out_tx_req_bits_pCrdType, i2_io_out_tx_req_bits_pCrdType;
  logic g2_io_out_tx_req_bits_memAttr_allocate, i2_io_out_tx_req_bits_memAttr_allocate;
  logic g2_io_out_tx_req_bits_memAttr_cacheable, i2_io_out_tx_req_bits_memAttr_cacheable;
  logic g2_io_out_tx_req_bits_memAttr_device, i2_io_out_tx_req_bits_memAttr_device;
  logic g2_io_out_tx_req_bits_memAttr_ewa, i2_io_out_tx_req_bits_memAttr_ewa;
  logic g2_io_out_tx_req_bits_snpAttr, i2_io_out_tx_req_bits_snpAttr;
  logic [7:0] g2_io_out_tx_req_bits_lpIDWithPadding, i2_io_out_tx_req_bits_lpIDWithPadding;
  logic g2_io_out_tx_req_bits_snoopMe, i2_io_out_tx_req_bits_snoopMe;
  logic g2_io_out_tx_req_bits_expCompAck, i2_io_out_tx_req_bits_expCompAck;
  logic [1:0] g2_io_out_tx_req_bits_tagOp, i2_io_out_tx_req_bits_tagOp;
  logic g2_io_out_tx_req_bits_traceTag, i2_io_out_tx_req_bits_traceTag;
  logic g2_io_out_tx_req_bits_mpam_perfMonGroup, i2_io_out_tx_req_bits_mpam_perfMonGroup;
  logic [8:0] g2_io_out_tx_req_bits_mpam_partID, i2_io_out_tx_req_bits_mpam_partID;
  logic g2_io_out_tx_req_bits_mpam_mpamNS, i2_io_out_tx_req_bits_mpam_mpamNS;
  logic [3:0] g2_io_out_tx_req_bits_rsvdc, i2_io_out_tx_req_bits_rsvdc;
  logic g2_io_out_tx_rsp_valid, i2_io_out_tx_rsp_valid;
  logic [3:0] g2_io_out_tx_rsp_bits_qos, i2_io_out_tx_rsp_bits_qos;
  logic [10:0] g2_io_out_tx_rsp_bits_tgtID, i2_io_out_tx_rsp_bits_tgtID;
  logic [11:0] g2_io_out_tx_rsp_bits_txnID, i2_io_out_tx_rsp_bits_txnID;
  logic [4:0] g2_io_out_tx_rsp_bits_opcode, i2_io_out_tx_rsp_bits_opcode;
  logic [1:0] g2_io_out_tx_rsp_bits_respErr, i2_io_out_tx_rsp_bits_respErr;
  logic [2:0] g2_io_out_tx_rsp_bits_resp, i2_io_out_tx_rsp_bits_resp;
  logic [2:0] g2_io_out_tx_rsp_bits_fwdState, i2_io_out_tx_rsp_bits_fwdState;
  logic [2:0] g2_io_out_tx_rsp_bits_cBusy, i2_io_out_tx_rsp_bits_cBusy;
  logic [11:0] g2_io_out_tx_rsp_bits_dbID, i2_io_out_tx_rsp_bits_dbID;
  logic [3:0] g2_io_out_tx_rsp_bits_pCrdType, i2_io_out_tx_rsp_bits_pCrdType;
  logic [1:0] g2_io_out_tx_rsp_bits_tagOp, i2_io_out_tx_rsp_bits_tagOp;
  logic g2_io_out_tx_rsp_bits_traceTag, i2_io_out_tx_rsp_bits_traceTag;
  logic g2_io_out_tx_dat_valid, i2_io_out_tx_dat_valid;
  logic [10:0] g2_io_out_tx_dat_bits_tgtID, i2_io_out_tx_dat_bits_tgtID;
  logic [11:0] g2_io_out_tx_dat_bits_txnID, i2_io_out_tx_dat_bits_txnID;
  logic [10:0] g2_io_out_tx_dat_bits_homeNID, i2_io_out_tx_dat_bits_homeNID;
  logic [3:0] g2_io_out_tx_dat_bits_opcode, i2_io_out_tx_dat_bits_opcode;
  logic [1:0] g2_io_out_tx_dat_bits_respErr, i2_io_out_tx_dat_bits_respErr;
  logic [2:0] g2_io_out_tx_dat_bits_resp, i2_io_out_tx_dat_bits_resp;
  logic [3:0] g2_io_out_tx_dat_bits_dataSource, i2_io_out_tx_dat_bits_dataSource;
  logic [11:0] g2_io_out_tx_dat_bits_dbID, i2_io_out_tx_dat_bits_dbID;
  logic [1:0] g2_io_out_tx_dat_bits_ccID, i2_io_out_tx_dat_bits_ccID;
  logic [1:0] g2_io_out_tx_dat_bits_dataID, i2_io_out_tx_dat_bits_dataID;
  logic g2_io_out_tx_dat_bits_traceTag, i2_io_out_tx_dat_bits_traceTag;
  logic [31:0] g2_io_out_tx_dat_bits_be, i2_io_out_tx_dat_bits_be;
  logic [255:0] g2_io_out_tx_dat_bits_data, i2_io_out_tx_dat_bits_data;
  logic [31:0] g2_io_out_tx_dat_bits_dataCheck, i2_io_out_tx_dat_bits_dataCheck;
  logic [3:0] g2_io_out_tx_dat_bits_poison, i2_io_out_tx_dat_bits_poison;
  logic g2_io_out_rx_snp_ready, i2_io_out_rx_snp_ready;
  logic g2_io_pCrd_0_query_valid, i2_io_pCrd_0_query_valid;
  logic [3:0] g2_io_pCrd_0_query_bits_pCrdType, i2_io_pCrd_0_query_bits_pCrdType;
  logic [10:0] g2_io_pCrd_0_query_bits_srcID, i2_io_pCrd_0_query_bits_srcID;
  logic g2_io_pCrd_1_query_valid, i2_io_pCrd_1_query_valid;
  logic [3:0] g2_io_pCrd_1_query_bits_pCrdType, i2_io_pCrd_1_query_bits_pCrdType;
  logic [10:0] g2_io_pCrd_1_query_bits_srcID, i2_io_pCrd_1_query_bits_srcID;
  logic g2_io_pCrd_2_query_valid, i2_io_pCrd_2_query_valid;
  logic [3:0] g2_io_pCrd_2_query_bits_pCrdType, i2_io_pCrd_2_query_bits_pCrdType;
  logic [10:0] g2_io_pCrd_2_query_bits_srcID, i2_io_pCrd_2_query_bits_srcID;
  logic g2_io_pCrd_3_query_valid, i2_io_pCrd_3_query_valid;
  logic [3:0] g2_io_pCrd_3_query_bits_pCrdType, i2_io_pCrd_3_query_bits_pCrdType;
  logic [10:0] g2_io_pCrd_3_query_bits_srcID, i2_io_pCrd_3_query_bits_srcID;
  logic g2_io_pCrd_4_query_valid, i2_io_pCrd_4_query_valid;
  logic [3:0] g2_io_pCrd_4_query_bits_pCrdType, i2_io_pCrd_4_query_bits_pCrdType;
  logic [10:0] g2_io_pCrd_4_query_bits_srcID, i2_io_pCrd_4_query_bits_srcID;
  logic g2_io_pCrd_5_query_valid, i2_io_pCrd_5_query_valid;
  logic [3:0] g2_io_pCrd_5_query_bits_pCrdType, i2_io_pCrd_5_query_bits_pCrdType;
  logic [10:0] g2_io_pCrd_5_query_bits_srcID, i2_io_pCrd_5_query_bits_srcID;
  logic g2_io_pCrd_6_query_valid, i2_io_pCrd_6_query_valid;
  logic [3:0] g2_io_pCrd_6_query_bits_pCrdType, i2_io_pCrd_6_query_bits_pCrdType;
  logic [10:0] g2_io_pCrd_6_query_bits_srcID, i2_io_pCrd_6_query_bits_srcID;
  logic g2_io_pCrd_7_query_valid, i2_io_pCrd_7_query_valid;
  logic [3:0] g2_io_pCrd_7_query_bits_pCrdType, i2_io_pCrd_7_query_bits_pCrdType;
  logic [10:0] g2_io_pCrd_7_query_bits_srcID, i2_io_pCrd_7_query_bits_srcID;
  logic g2_io_pCrd_8_query_valid, i2_io_pCrd_8_query_valid;
  logic [3:0] g2_io_pCrd_8_query_bits_pCrdType, i2_io_pCrd_8_query_bits_pCrdType;
  logic [10:0] g2_io_pCrd_8_query_bits_srcID, i2_io_pCrd_8_query_bits_srcID;
  logic g2_io_pCrd_9_query_valid, i2_io_pCrd_9_query_valid;
  logic [3:0] g2_io_pCrd_9_query_bits_pCrdType, i2_io_pCrd_9_query_bits_pCrdType;
  logic [10:0] g2_io_pCrd_9_query_bits_srcID, i2_io_pCrd_9_query_bits_srcID;
  logic g2_io_pCrd_10_query_valid, i2_io_pCrd_10_query_valid;
  logic [3:0] g2_io_pCrd_10_query_bits_pCrdType, i2_io_pCrd_10_query_bits_pCrdType;
  logic [10:0] g2_io_pCrd_10_query_bits_srcID, i2_io_pCrd_10_query_bits_srcID;
  logic g2_io_pCrd_11_query_valid, i2_io_pCrd_11_query_valid;
  logic [3:0] g2_io_pCrd_11_query_bits_pCrdType, i2_io_pCrd_11_query_bits_pCrdType;
  logic [10:0] g2_io_pCrd_11_query_bits_srcID, i2_io_pCrd_11_query_bits_srcID;
  logic g2_io_pCrd_12_query_valid, i2_io_pCrd_12_query_valid;
  logic [3:0] g2_io_pCrd_12_query_bits_pCrdType, i2_io_pCrd_12_query_bits_pCrdType;
  logic [10:0] g2_io_pCrd_12_query_bits_srcID, i2_io_pCrd_12_query_bits_srcID;
  logic g2_io_pCrd_13_query_valid, i2_io_pCrd_13_query_valid;
  logic [3:0] g2_io_pCrd_13_query_bits_pCrdType, i2_io_pCrd_13_query_bits_pCrdType;
  logic [10:0] g2_io_pCrd_13_query_bits_srcID, i2_io_pCrd_13_query_bits_srcID;
  logic g2_io_pCrd_14_query_valid, i2_io_pCrd_14_query_valid;
  logic [3:0] g2_io_pCrd_14_query_bits_pCrdType, i2_io_pCrd_14_query_bits_pCrdType;
  logic [10:0] g2_io_pCrd_14_query_bits_srcID, i2_io_pCrd_14_query_bits_srcID;
  logic g2_io_pCrd_15_query_valid, i2_io_pCrd_15_query_valid;
  logic [3:0] g2_io_pCrd_15_query_bits_pCrdType, i2_io_pCrd_15_query_bits_pCrdType;
  logic [10:0] g2_io_pCrd_15_query_bits_srcID, i2_io_pCrd_15_query_bits_srcID;
  logic [5:0] g2_io_perf_0_value, i2_io_perf_0_value;
  logic [5:0] g2_io_perf_1_value, i2_io_perf_1_value;
  logic [5:0] g2_io_perf_3_value, i2_io_perf_3_value;
  logic [5:0] g2_io_perf_4_value, i2_io_perf_4_value;
  logic [5:0] g2_io_perf_5_value, i2_io_perf_5_value;
  logic [5:0] g2_io_perf_6_value, i2_io_perf_6_value;
  logic [5:0] g2_io_perf_7_value, i2_io_perf_7_value;
  logic [5:0] g2_io_perf_8_value, i2_io_perf_8_value;
  logic [5:0] g2_io_perf_9_value, i2_io_perf_9_value;
  logic [5:0] g2_io_perf_10_value, i2_io_perf_10_value;
  logic [5:0] g2_io_perf_11_value, i2_io_perf_11_value;
  logic [5:0] g2_io_perf_12_value, i2_io_perf_12_value;
  logic [5:0] g2_io_perf_13_value, i2_io_perf_13_value;
  logic [5:0] g2_io_perf_14_value, i2_io_perf_14_value;
  logic [5:0] g2_io_perf_15_value, i2_io_perf_15_value;
  logic [5:0] g2_io_perf_16_value, i2_io_perf_16_value;
  logic g2_boreChildrenBd_bore_ack, i2_boreChildrenBd_bore_ack;
  logic [136:0] g2_boreChildrenBd_bore_outdata, i2_boreChildrenBd_bore_outdata;
  logic g3_io_in_a_ready, i3_io_in_a_ready;
  logic g3_io_in_b_valid, i3_io_in_b_valid;
  logic [2:0] g3_io_in_b_bits_opcode, i3_io_in_b_bits_opcode;
  logic [1:0] g3_io_in_b_bits_param, i3_io_in_b_bits_param;
  logic [47:0] g3_io_in_b_bits_address, i3_io_in_b_bits_address;
  logic [255:0] g3_io_in_b_bits_data, i3_io_in_b_bits_data;
  logic g3_io_in_c_ready, i3_io_in_c_ready;
  logic g3_io_in_d_valid, i3_io_in_d_valid;
  logic [3:0] g3_io_in_d_bits_opcode, i3_io_in_d_bits_opcode;
  logic [1:0] g3_io_in_d_bits_param, i3_io_in_d_bits_param;
  logic [6:0] g3_io_in_d_bits_source, i3_io_in_d_bits_source;
  logic [7:0] g3_io_in_d_bits_sink, i3_io_in_d_bits_sink;
  logic g3_io_in_d_bits_denied, i3_io_in_d_bits_denied;
  logic g3_io_in_d_bits_echo_isKeyword, i3_io_in_d_bits_echo_isKeyword;
  logic [255:0] g3_io_in_d_bits_data, i3_io_in_d_bits_data;
  logic g3_io_in_d_bits_corrupt, i3_io_in_d_bits_corrupt;
  logic g3_io_l1Hint_valid, i3_io_l1Hint_valid;
  logic [31:0] g3_io_l1Hint_bits_sourceId, i3_io_l1Hint_bits_sourceId;
  logic g3_io_l1Hint_bits_isKeyword, i3_io_l1Hint_bits_isKeyword;
  logic g3_io_prefetch_train_valid, i3_io_prefetch_train_valid;
  logic [32:0] g3_io_prefetch_train_bits_tag, i3_io_prefetch_train_bits_tag;
  logic [8:0] g3_io_prefetch_train_bits_set, i3_io_prefetch_train_bits_set;
  logic g3_io_prefetch_train_bits_needT, i3_io_prefetch_train_bits_needT;
  logic [6:0] g3_io_prefetch_train_bits_source, i3_io_prefetch_train_bits_source;
  logic [43:0] g3_io_prefetch_train_bits_vaddr, i3_io_prefetch_train_bits_vaddr;
  logic g3_io_prefetch_train_bits_hit, i3_io_prefetch_train_bits_hit;
  logic g3_io_prefetch_train_bits_prefetched, i3_io_prefetch_train_bits_prefetched;
  logic [2:0] g3_io_prefetch_train_bits_pfsource, i3_io_prefetch_train_bits_pfsource;
  logic [4:0] g3_io_prefetch_train_bits_reqsource, i3_io_prefetch_train_bits_reqsource;
  logic g3_io_prefetch_req_ready, i3_io_prefetch_req_ready;
  logic g3_io_prefetch_resp_valid, i3_io_prefetch_resp_valid;
  logic [32:0] g3_io_prefetch_resp_bits_tag, i3_io_prefetch_resp_bits_tag;
  logic [8:0] g3_io_prefetch_resp_bits_set, i3_io_prefetch_resp_bits_set;
  logic [43:0] g3_io_prefetch_resp_bits_vaddr, i3_io_prefetch_resp_bits_vaddr;
  logic [4:0] g3_io_prefetch_resp_bits_pfSource, i3_io_prefetch_resp_bits_pfSource;
  logic g3_io_dirResult_valid, i3_io_dirResult_valid;
  logic g3_io_dirResult_bits_hit, i3_io_dirResult_bits_hit;
  logic g3_io_dirResult_bits_meta_prefetch, i3_io_dirResult_bits_meta_prefetch;
  logic [2:0] g3_io_dirResult_bits_meta_prefetchSrc, i3_io_dirResult_bits_meta_prefetchSrc;
  logic [2:0] g3_io_dirResult_bits_replacerInfo_channel, i3_io_dirResult_bits_replacerInfo_channel;
  logic [4:0] g3_io_dirResult_bits_replacerInfo_reqSource, i3_io_dirResult_bits_replacerInfo_reqSource;
  logic g3_io_hitPfInMSHR_valid, i3_io_hitPfInMSHR_valid;
  logic [2:0] g3_io_hitPfInMSHR_bits, i3_io_hitPfInMSHR_bits;
  logic g3_io_pfSent_valid, i3_io_pfSent_valid;
  logic [4:0] g3_io_pfSent_bits, i3_io_pfSent_bits;
  logic g3_io_pfLateInMSHR_valid, i3_io_pfLateInMSHR_valid;
  logic [4:0] g3_io_pfLateInMSHR_bits, i3_io_pfLateInMSHR_bits;
  logic g3_io_error_valid, i3_io_error_valid;
  logic g3_io_error_bits_valid, i3_io_error_bits_valid;
  logic [45:0] g3_io_error_bits_address, i3_io_error_bits_address;
  logic g3_io_l2Miss, i3_io_l2Miss;
  logic g3_io_msStatus_0_valid, i3_io_msStatus_0_valid;
  logic [2:0] g3_io_msStatus_0_bits_channel, i3_io_msStatus_0_bits_channel;
  logic [8:0] g3_io_msStatus_0_bits_set, i3_io_msStatus_0_bits_set;
  logic [30:0] g3_io_msStatus_0_bits_reqTag, i3_io_msStatus_0_bits_reqTag;
  logic g3_io_msStatus_0_bits_is_miss, i3_io_msStatus_0_bits_is_miss;
  logic g3_io_msStatus_0_bits_is_prefetch, i3_io_msStatus_0_bits_is_prefetch;
  logic g3_io_msStatus_1_valid, i3_io_msStatus_1_valid;
  logic [2:0] g3_io_msStatus_1_bits_channel, i3_io_msStatus_1_bits_channel;
  logic [8:0] g3_io_msStatus_1_bits_set, i3_io_msStatus_1_bits_set;
  logic [30:0] g3_io_msStatus_1_bits_reqTag, i3_io_msStatus_1_bits_reqTag;
  logic g3_io_msStatus_1_bits_is_miss, i3_io_msStatus_1_bits_is_miss;
  logic g3_io_msStatus_1_bits_is_prefetch, i3_io_msStatus_1_bits_is_prefetch;
  logic g3_io_msStatus_2_valid, i3_io_msStatus_2_valid;
  logic [2:0] g3_io_msStatus_2_bits_channel, i3_io_msStatus_2_bits_channel;
  logic [8:0] g3_io_msStatus_2_bits_set, i3_io_msStatus_2_bits_set;
  logic [30:0] g3_io_msStatus_2_bits_reqTag, i3_io_msStatus_2_bits_reqTag;
  logic g3_io_msStatus_2_bits_is_miss, i3_io_msStatus_2_bits_is_miss;
  logic g3_io_msStatus_2_bits_is_prefetch, i3_io_msStatus_2_bits_is_prefetch;
  logic g3_io_msStatus_3_valid, i3_io_msStatus_3_valid;
  logic [2:0] g3_io_msStatus_3_bits_channel, i3_io_msStatus_3_bits_channel;
  logic [8:0] g3_io_msStatus_3_bits_set, i3_io_msStatus_3_bits_set;
  logic [30:0] g3_io_msStatus_3_bits_reqTag, i3_io_msStatus_3_bits_reqTag;
  logic g3_io_msStatus_3_bits_is_miss, i3_io_msStatus_3_bits_is_miss;
  logic g3_io_msStatus_3_bits_is_prefetch, i3_io_msStatus_3_bits_is_prefetch;
  logic g3_io_msStatus_4_valid, i3_io_msStatus_4_valid;
  logic [2:0] g3_io_msStatus_4_bits_channel, i3_io_msStatus_4_bits_channel;
  logic [8:0] g3_io_msStatus_4_bits_set, i3_io_msStatus_4_bits_set;
  logic [30:0] g3_io_msStatus_4_bits_reqTag, i3_io_msStatus_4_bits_reqTag;
  logic g3_io_msStatus_4_bits_is_miss, i3_io_msStatus_4_bits_is_miss;
  logic g3_io_msStatus_4_bits_is_prefetch, i3_io_msStatus_4_bits_is_prefetch;
  logic g3_io_msStatus_5_valid, i3_io_msStatus_5_valid;
  logic [2:0] g3_io_msStatus_5_bits_channel, i3_io_msStatus_5_bits_channel;
  logic [8:0] g3_io_msStatus_5_bits_set, i3_io_msStatus_5_bits_set;
  logic [30:0] g3_io_msStatus_5_bits_reqTag, i3_io_msStatus_5_bits_reqTag;
  logic g3_io_msStatus_5_bits_is_miss, i3_io_msStatus_5_bits_is_miss;
  logic g3_io_msStatus_5_bits_is_prefetch, i3_io_msStatus_5_bits_is_prefetch;
  logic g3_io_msStatus_6_valid, i3_io_msStatus_6_valid;
  logic [2:0] g3_io_msStatus_6_bits_channel, i3_io_msStatus_6_bits_channel;
  logic [8:0] g3_io_msStatus_6_bits_set, i3_io_msStatus_6_bits_set;
  logic [30:0] g3_io_msStatus_6_bits_reqTag, i3_io_msStatus_6_bits_reqTag;
  logic g3_io_msStatus_6_bits_is_miss, i3_io_msStatus_6_bits_is_miss;
  logic g3_io_msStatus_6_bits_is_prefetch, i3_io_msStatus_6_bits_is_prefetch;
  logic g3_io_msStatus_7_valid, i3_io_msStatus_7_valid;
  logic [2:0] g3_io_msStatus_7_bits_channel, i3_io_msStatus_7_bits_channel;
  logic [8:0] g3_io_msStatus_7_bits_set, i3_io_msStatus_7_bits_set;
  logic [30:0] g3_io_msStatus_7_bits_reqTag, i3_io_msStatus_7_bits_reqTag;
  logic g3_io_msStatus_7_bits_is_miss, i3_io_msStatus_7_bits_is_miss;
  logic g3_io_msStatus_7_bits_is_prefetch, i3_io_msStatus_7_bits_is_prefetch;
  logic g3_io_msStatus_8_valid, i3_io_msStatus_8_valid;
  logic [2:0] g3_io_msStatus_8_bits_channel, i3_io_msStatus_8_bits_channel;
  logic [8:0] g3_io_msStatus_8_bits_set, i3_io_msStatus_8_bits_set;
  logic [30:0] g3_io_msStatus_8_bits_reqTag, i3_io_msStatus_8_bits_reqTag;
  logic g3_io_msStatus_8_bits_is_miss, i3_io_msStatus_8_bits_is_miss;
  logic g3_io_msStatus_8_bits_is_prefetch, i3_io_msStatus_8_bits_is_prefetch;
  logic g3_io_msStatus_9_valid, i3_io_msStatus_9_valid;
  logic [2:0] g3_io_msStatus_9_bits_channel, i3_io_msStatus_9_bits_channel;
  logic [8:0] g3_io_msStatus_9_bits_set, i3_io_msStatus_9_bits_set;
  logic [30:0] g3_io_msStatus_9_bits_reqTag, i3_io_msStatus_9_bits_reqTag;
  logic g3_io_msStatus_9_bits_is_miss, i3_io_msStatus_9_bits_is_miss;
  logic g3_io_msStatus_9_bits_is_prefetch, i3_io_msStatus_9_bits_is_prefetch;
  logic g3_io_msStatus_10_valid, i3_io_msStatus_10_valid;
  logic [2:0] g3_io_msStatus_10_bits_channel, i3_io_msStatus_10_bits_channel;
  logic [8:0] g3_io_msStatus_10_bits_set, i3_io_msStatus_10_bits_set;
  logic [30:0] g3_io_msStatus_10_bits_reqTag, i3_io_msStatus_10_bits_reqTag;
  logic g3_io_msStatus_10_bits_is_miss, i3_io_msStatus_10_bits_is_miss;
  logic g3_io_msStatus_10_bits_is_prefetch, i3_io_msStatus_10_bits_is_prefetch;
  logic g3_io_msStatus_11_valid, i3_io_msStatus_11_valid;
  logic [2:0] g3_io_msStatus_11_bits_channel, i3_io_msStatus_11_bits_channel;
  logic [8:0] g3_io_msStatus_11_bits_set, i3_io_msStatus_11_bits_set;
  logic [30:0] g3_io_msStatus_11_bits_reqTag, i3_io_msStatus_11_bits_reqTag;
  logic g3_io_msStatus_11_bits_is_miss, i3_io_msStatus_11_bits_is_miss;
  logic g3_io_msStatus_11_bits_is_prefetch, i3_io_msStatus_11_bits_is_prefetch;
  logic g3_io_msStatus_12_valid, i3_io_msStatus_12_valid;
  logic [2:0] g3_io_msStatus_12_bits_channel, i3_io_msStatus_12_bits_channel;
  logic [8:0] g3_io_msStatus_12_bits_set, i3_io_msStatus_12_bits_set;
  logic [30:0] g3_io_msStatus_12_bits_reqTag, i3_io_msStatus_12_bits_reqTag;
  logic g3_io_msStatus_12_bits_is_miss, i3_io_msStatus_12_bits_is_miss;
  logic g3_io_msStatus_12_bits_is_prefetch, i3_io_msStatus_12_bits_is_prefetch;
  logic g3_io_msStatus_13_valid, i3_io_msStatus_13_valid;
  logic [2:0] g3_io_msStatus_13_bits_channel, i3_io_msStatus_13_bits_channel;
  logic [8:0] g3_io_msStatus_13_bits_set, i3_io_msStatus_13_bits_set;
  logic [30:0] g3_io_msStatus_13_bits_reqTag, i3_io_msStatus_13_bits_reqTag;
  logic g3_io_msStatus_13_bits_is_miss, i3_io_msStatus_13_bits_is_miss;
  logic g3_io_msStatus_13_bits_is_prefetch, i3_io_msStatus_13_bits_is_prefetch;
  logic g3_io_msStatus_14_valid, i3_io_msStatus_14_valid;
  logic [2:0] g3_io_msStatus_14_bits_channel, i3_io_msStatus_14_bits_channel;
  logic [8:0] g3_io_msStatus_14_bits_set, i3_io_msStatus_14_bits_set;
  logic [30:0] g3_io_msStatus_14_bits_reqTag, i3_io_msStatus_14_bits_reqTag;
  logic g3_io_msStatus_14_bits_is_miss, i3_io_msStatus_14_bits_is_miss;
  logic g3_io_msStatus_14_bits_is_prefetch, i3_io_msStatus_14_bits_is_prefetch;
  logic g3_io_msStatus_15_valid, i3_io_msStatus_15_valid;
  logic [2:0] g3_io_msStatus_15_bits_channel, i3_io_msStatus_15_bits_channel;
  logic [8:0] g3_io_msStatus_15_bits_set, i3_io_msStatus_15_bits_set;
  logic [30:0] g3_io_msStatus_15_bits_reqTag, i3_io_msStatus_15_bits_reqTag;
  logic g3_io_msStatus_15_bits_is_miss, i3_io_msStatus_15_bits_is_miss;
  logic g3_io_msStatus_15_bits_is_prefetch, i3_io_msStatus_15_bits_is_prefetch;
  logic g3_io_msAlloc_0_valid, i3_io_msAlloc_0_valid;
  logic [2:0] g3_io_msAlloc_0_bits_channel, i3_io_msAlloc_0_bits_channel;
  logic g3_io_msAlloc_0_bits_is_miss, i3_io_msAlloc_0_bits_is_miss;
  logic g3_io_msAlloc_0_bits_is_prefetch, i3_io_msAlloc_0_bits_is_prefetch;
  logic g3_io_msAlloc_1_valid, i3_io_msAlloc_1_valid;
  logic [2:0] g3_io_msAlloc_1_bits_channel, i3_io_msAlloc_1_bits_channel;
  logic g3_io_msAlloc_1_bits_is_miss, i3_io_msAlloc_1_bits_is_miss;
  logic g3_io_msAlloc_1_bits_is_prefetch, i3_io_msAlloc_1_bits_is_prefetch;
  logic g3_io_msAlloc_2_valid, i3_io_msAlloc_2_valid;
  logic [2:0] g3_io_msAlloc_2_bits_channel, i3_io_msAlloc_2_bits_channel;
  logic g3_io_msAlloc_2_bits_is_miss, i3_io_msAlloc_2_bits_is_miss;
  logic g3_io_msAlloc_2_bits_is_prefetch, i3_io_msAlloc_2_bits_is_prefetch;
  logic g3_io_msAlloc_3_valid, i3_io_msAlloc_3_valid;
  logic [2:0] g3_io_msAlloc_3_bits_channel, i3_io_msAlloc_3_bits_channel;
  logic g3_io_msAlloc_3_bits_is_miss, i3_io_msAlloc_3_bits_is_miss;
  logic g3_io_msAlloc_3_bits_is_prefetch, i3_io_msAlloc_3_bits_is_prefetch;
  logic g3_io_msAlloc_4_valid, i3_io_msAlloc_4_valid;
  logic [2:0] g3_io_msAlloc_4_bits_channel, i3_io_msAlloc_4_bits_channel;
  logic g3_io_msAlloc_4_bits_is_miss, i3_io_msAlloc_4_bits_is_miss;
  logic g3_io_msAlloc_4_bits_is_prefetch, i3_io_msAlloc_4_bits_is_prefetch;
  logic g3_io_msAlloc_5_valid, i3_io_msAlloc_5_valid;
  logic [2:0] g3_io_msAlloc_5_bits_channel, i3_io_msAlloc_5_bits_channel;
  logic g3_io_msAlloc_5_bits_is_miss, i3_io_msAlloc_5_bits_is_miss;
  logic g3_io_msAlloc_5_bits_is_prefetch, i3_io_msAlloc_5_bits_is_prefetch;
  logic g3_io_msAlloc_6_valid, i3_io_msAlloc_6_valid;
  logic [2:0] g3_io_msAlloc_6_bits_channel, i3_io_msAlloc_6_bits_channel;
  logic g3_io_msAlloc_6_bits_is_miss, i3_io_msAlloc_6_bits_is_miss;
  logic g3_io_msAlloc_6_bits_is_prefetch, i3_io_msAlloc_6_bits_is_prefetch;
  logic g3_io_msAlloc_7_valid, i3_io_msAlloc_7_valid;
  logic [2:0] g3_io_msAlloc_7_bits_channel, i3_io_msAlloc_7_bits_channel;
  logic g3_io_msAlloc_7_bits_is_miss, i3_io_msAlloc_7_bits_is_miss;
  logic g3_io_msAlloc_7_bits_is_prefetch, i3_io_msAlloc_7_bits_is_prefetch;
  logic g3_io_msAlloc_8_valid, i3_io_msAlloc_8_valid;
  logic [2:0] g3_io_msAlloc_8_bits_channel, i3_io_msAlloc_8_bits_channel;
  logic g3_io_msAlloc_8_bits_is_miss, i3_io_msAlloc_8_bits_is_miss;
  logic g3_io_msAlloc_8_bits_is_prefetch, i3_io_msAlloc_8_bits_is_prefetch;
  logic g3_io_msAlloc_9_valid, i3_io_msAlloc_9_valid;
  logic [2:0] g3_io_msAlloc_9_bits_channel, i3_io_msAlloc_9_bits_channel;
  logic g3_io_msAlloc_9_bits_is_miss, i3_io_msAlloc_9_bits_is_miss;
  logic g3_io_msAlloc_9_bits_is_prefetch, i3_io_msAlloc_9_bits_is_prefetch;
  logic g3_io_msAlloc_10_valid, i3_io_msAlloc_10_valid;
  logic [2:0] g3_io_msAlloc_10_bits_channel, i3_io_msAlloc_10_bits_channel;
  logic g3_io_msAlloc_10_bits_is_miss, i3_io_msAlloc_10_bits_is_miss;
  logic g3_io_msAlloc_10_bits_is_prefetch, i3_io_msAlloc_10_bits_is_prefetch;
  logic g3_io_msAlloc_11_valid, i3_io_msAlloc_11_valid;
  logic [2:0] g3_io_msAlloc_11_bits_channel, i3_io_msAlloc_11_bits_channel;
  logic g3_io_msAlloc_11_bits_is_miss, i3_io_msAlloc_11_bits_is_miss;
  logic g3_io_msAlloc_11_bits_is_prefetch, i3_io_msAlloc_11_bits_is_prefetch;
  logic g3_io_msAlloc_12_valid, i3_io_msAlloc_12_valid;
  logic [2:0] g3_io_msAlloc_12_bits_channel, i3_io_msAlloc_12_bits_channel;
  logic g3_io_msAlloc_12_bits_is_miss, i3_io_msAlloc_12_bits_is_miss;
  logic g3_io_msAlloc_12_bits_is_prefetch, i3_io_msAlloc_12_bits_is_prefetch;
  logic g3_io_msAlloc_13_valid, i3_io_msAlloc_13_valid;
  logic [2:0] g3_io_msAlloc_13_bits_channel, i3_io_msAlloc_13_bits_channel;
  logic g3_io_msAlloc_13_bits_is_miss, i3_io_msAlloc_13_bits_is_miss;
  logic g3_io_msAlloc_13_bits_is_prefetch, i3_io_msAlloc_13_bits_is_prefetch;
  logic g3_io_msAlloc_14_valid, i3_io_msAlloc_14_valid;
  logic [2:0] g3_io_msAlloc_14_bits_channel, i3_io_msAlloc_14_bits_channel;
  logic g3_io_msAlloc_14_bits_is_miss, i3_io_msAlloc_14_bits_is_miss;
  logic g3_io_msAlloc_14_bits_is_prefetch, i3_io_msAlloc_14_bits_is_prefetch;
  logic g3_io_msAlloc_15_valid, i3_io_msAlloc_15_valid;
  logic [2:0] g3_io_msAlloc_15_bits_channel, i3_io_msAlloc_15_bits_channel;
  logic g3_io_msAlloc_15_bits_is_miss, i3_io_msAlloc_15_bits_is_miss;
  logic g3_io_msAlloc_15_bits_is_prefetch, i3_io_msAlloc_15_bits_is_prefetch;
  logic g3_io_out_tx_req_valid, i3_io_out_tx_req_valid;
  logic [3:0] g3_io_out_tx_req_bits_qos, i3_io_out_tx_req_bits_qos;
  logic [11:0] g3_io_out_tx_req_bits_txnID, i3_io_out_tx_req_bits_txnID;
  logic [10:0] g3_io_out_tx_req_bits_returnNID, i3_io_out_tx_req_bits_returnNID;
  logic g3_io_out_tx_req_bits_stashNIDValid, i3_io_out_tx_req_bits_stashNIDValid;
  logic [11:0] g3_io_out_tx_req_bits_returnTxnID, i3_io_out_tx_req_bits_returnTxnID;
  logic [6:0] g3_io_out_tx_req_bits_opcode, i3_io_out_tx_req_bits_opcode;
  logic [47:0] g3_io_out_tx_req_bits_addr, i3_io_out_tx_req_bits_addr;
  logic g3_io_out_tx_req_bits_ns, i3_io_out_tx_req_bits_ns;
  logic g3_io_out_tx_req_bits_likelyshared, i3_io_out_tx_req_bits_likelyshared;
  logic g3_io_out_tx_req_bits_allowRetry, i3_io_out_tx_req_bits_allowRetry;
  logic [1:0] g3_io_out_tx_req_bits_order, i3_io_out_tx_req_bits_order;
  logic [3:0] g3_io_out_tx_req_bits_pCrdType, i3_io_out_tx_req_bits_pCrdType;
  logic g3_io_out_tx_req_bits_memAttr_allocate, i3_io_out_tx_req_bits_memAttr_allocate;
  logic g3_io_out_tx_req_bits_memAttr_cacheable, i3_io_out_tx_req_bits_memAttr_cacheable;
  logic g3_io_out_tx_req_bits_memAttr_device, i3_io_out_tx_req_bits_memAttr_device;
  logic g3_io_out_tx_req_bits_memAttr_ewa, i3_io_out_tx_req_bits_memAttr_ewa;
  logic g3_io_out_tx_req_bits_snpAttr, i3_io_out_tx_req_bits_snpAttr;
  logic [7:0] g3_io_out_tx_req_bits_lpIDWithPadding, i3_io_out_tx_req_bits_lpIDWithPadding;
  logic g3_io_out_tx_req_bits_snoopMe, i3_io_out_tx_req_bits_snoopMe;
  logic g3_io_out_tx_req_bits_expCompAck, i3_io_out_tx_req_bits_expCompAck;
  logic [1:0] g3_io_out_tx_req_bits_tagOp, i3_io_out_tx_req_bits_tagOp;
  logic g3_io_out_tx_req_bits_traceTag, i3_io_out_tx_req_bits_traceTag;
  logic g3_io_out_tx_req_bits_mpam_perfMonGroup, i3_io_out_tx_req_bits_mpam_perfMonGroup;
  logic [8:0] g3_io_out_tx_req_bits_mpam_partID, i3_io_out_tx_req_bits_mpam_partID;
  logic g3_io_out_tx_req_bits_mpam_mpamNS, i3_io_out_tx_req_bits_mpam_mpamNS;
  logic [3:0] g3_io_out_tx_req_bits_rsvdc, i3_io_out_tx_req_bits_rsvdc;
  logic g3_io_out_tx_rsp_valid, i3_io_out_tx_rsp_valid;
  logic [3:0] g3_io_out_tx_rsp_bits_qos, i3_io_out_tx_rsp_bits_qos;
  logic [10:0] g3_io_out_tx_rsp_bits_tgtID, i3_io_out_tx_rsp_bits_tgtID;
  logic [11:0] g3_io_out_tx_rsp_bits_txnID, i3_io_out_tx_rsp_bits_txnID;
  logic [4:0] g3_io_out_tx_rsp_bits_opcode, i3_io_out_tx_rsp_bits_opcode;
  logic [1:0] g3_io_out_tx_rsp_bits_respErr, i3_io_out_tx_rsp_bits_respErr;
  logic [2:0] g3_io_out_tx_rsp_bits_resp, i3_io_out_tx_rsp_bits_resp;
  logic [2:0] g3_io_out_tx_rsp_bits_fwdState, i3_io_out_tx_rsp_bits_fwdState;
  logic [2:0] g3_io_out_tx_rsp_bits_cBusy, i3_io_out_tx_rsp_bits_cBusy;
  logic [11:0] g3_io_out_tx_rsp_bits_dbID, i3_io_out_tx_rsp_bits_dbID;
  logic [3:0] g3_io_out_tx_rsp_bits_pCrdType, i3_io_out_tx_rsp_bits_pCrdType;
  logic [1:0] g3_io_out_tx_rsp_bits_tagOp, i3_io_out_tx_rsp_bits_tagOp;
  logic g3_io_out_tx_rsp_bits_traceTag, i3_io_out_tx_rsp_bits_traceTag;
  logic g3_io_out_tx_dat_valid, i3_io_out_tx_dat_valid;
  logic [10:0] g3_io_out_tx_dat_bits_tgtID, i3_io_out_tx_dat_bits_tgtID;
  logic [11:0] g3_io_out_tx_dat_bits_txnID, i3_io_out_tx_dat_bits_txnID;
  logic [10:0] g3_io_out_tx_dat_bits_homeNID, i3_io_out_tx_dat_bits_homeNID;
  logic [3:0] g3_io_out_tx_dat_bits_opcode, i3_io_out_tx_dat_bits_opcode;
  logic [1:0] g3_io_out_tx_dat_bits_respErr, i3_io_out_tx_dat_bits_respErr;
  logic [2:0] g3_io_out_tx_dat_bits_resp, i3_io_out_tx_dat_bits_resp;
  logic [3:0] g3_io_out_tx_dat_bits_dataSource, i3_io_out_tx_dat_bits_dataSource;
  logic [11:0] g3_io_out_tx_dat_bits_dbID, i3_io_out_tx_dat_bits_dbID;
  logic [1:0] g3_io_out_tx_dat_bits_ccID, i3_io_out_tx_dat_bits_ccID;
  logic [1:0] g3_io_out_tx_dat_bits_dataID, i3_io_out_tx_dat_bits_dataID;
  logic g3_io_out_tx_dat_bits_traceTag, i3_io_out_tx_dat_bits_traceTag;
  logic [31:0] g3_io_out_tx_dat_bits_be, i3_io_out_tx_dat_bits_be;
  logic [255:0] g3_io_out_tx_dat_bits_data, i3_io_out_tx_dat_bits_data;
  logic [31:0] g3_io_out_tx_dat_bits_dataCheck, i3_io_out_tx_dat_bits_dataCheck;
  logic [3:0] g3_io_out_tx_dat_bits_poison, i3_io_out_tx_dat_bits_poison;
  logic g3_io_out_rx_snp_ready, i3_io_out_rx_snp_ready;
  logic g3_io_pCrd_0_query_valid, i3_io_pCrd_0_query_valid;
  logic [3:0] g3_io_pCrd_0_query_bits_pCrdType, i3_io_pCrd_0_query_bits_pCrdType;
  logic [10:0] g3_io_pCrd_0_query_bits_srcID, i3_io_pCrd_0_query_bits_srcID;
  logic g3_io_pCrd_1_query_valid, i3_io_pCrd_1_query_valid;
  logic [3:0] g3_io_pCrd_1_query_bits_pCrdType, i3_io_pCrd_1_query_bits_pCrdType;
  logic [10:0] g3_io_pCrd_1_query_bits_srcID, i3_io_pCrd_1_query_bits_srcID;
  logic g3_io_pCrd_2_query_valid, i3_io_pCrd_2_query_valid;
  logic [3:0] g3_io_pCrd_2_query_bits_pCrdType, i3_io_pCrd_2_query_bits_pCrdType;
  logic [10:0] g3_io_pCrd_2_query_bits_srcID, i3_io_pCrd_2_query_bits_srcID;
  logic g3_io_pCrd_3_query_valid, i3_io_pCrd_3_query_valid;
  logic [3:0] g3_io_pCrd_3_query_bits_pCrdType, i3_io_pCrd_3_query_bits_pCrdType;
  logic [10:0] g3_io_pCrd_3_query_bits_srcID, i3_io_pCrd_3_query_bits_srcID;
  logic g3_io_pCrd_4_query_valid, i3_io_pCrd_4_query_valid;
  logic [3:0] g3_io_pCrd_4_query_bits_pCrdType, i3_io_pCrd_4_query_bits_pCrdType;
  logic [10:0] g3_io_pCrd_4_query_bits_srcID, i3_io_pCrd_4_query_bits_srcID;
  logic g3_io_pCrd_5_query_valid, i3_io_pCrd_5_query_valid;
  logic [3:0] g3_io_pCrd_5_query_bits_pCrdType, i3_io_pCrd_5_query_bits_pCrdType;
  logic [10:0] g3_io_pCrd_5_query_bits_srcID, i3_io_pCrd_5_query_bits_srcID;
  logic g3_io_pCrd_6_query_valid, i3_io_pCrd_6_query_valid;
  logic [3:0] g3_io_pCrd_6_query_bits_pCrdType, i3_io_pCrd_6_query_bits_pCrdType;
  logic [10:0] g3_io_pCrd_6_query_bits_srcID, i3_io_pCrd_6_query_bits_srcID;
  logic g3_io_pCrd_7_query_valid, i3_io_pCrd_7_query_valid;
  logic [3:0] g3_io_pCrd_7_query_bits_pCrdType, i3_io_pCrd_7_query_bits_pCrdType;
  logic [10:0] g3_io_pCrd_7_query_bits_srcID, i3_io_pCrd_7_query_bits_srcID;
  logic g3_io_pCrd_8_query_valid, i3_io_pCrd_8_query_valid;
  logic [3:0] g3_io_pCrd_8_query_bits_pCrdType, i3_io_pCrd_8_query_bits_pCrdType;
  logic [10:0] g3_io_pCrd_8_query_bits_srcID, i3_io_pCrd_8_query_bits_srcID;
  logic g3_io_pCrd_9_query_valid, i3_io_pCrd_9_query_valid;
  logic [3:0] g3_io_pCrd_9_query_bits_pCrdType, i3_io_pCrd_9_query_bits_pCrdType;
  logic [10:0] g3_io_pCrd_9_query_bits_srcID, i3_io_pCrd_9_query_bits_srcID;
  logic g3_io_pCrd_10_query_valid, i3_io_pCrd_10_query_valid;
  logic [3:0] g3_io_pCrd_10_query_bits_pCrdType, i3_io_pCrd_10_query_bits_pCrdType;
  logic [10:0] g3_io_pCrd_10_query_bits_srcID, i3_io_pCrd_10_query_bits_srcID;
  logic g3_io_pCrd_11_query_valid, i3_io_pCrd_11_query_valid;
  logic [3:0] g3_io_pCrd_11_query_bits_pCrdType, i3_io_pCrd_11_query_bits_pCrdType;
  logic [10:0] g3_io_pCrd_11_query_bits_srcID, i3_io_pCrd_11_query_bits_srcID;
  logic g3_io_pCrd_12_query_valid, i3_io_pCrd_12_query_valid;
  logic [3:0] g3_io_pCrd_12_query_bits_pCrdType, i3_io_pCrd_12_query_bits_pCrdType;
  logic [10:0] g3_io_pCrd_12_query_bits_srcID, i3_io_pCrd_12_query_bits_srcID;
  logic g3_io_pCrd_13_query_valid, i3_io_pCrd_13_query_valid;
  logic [3:0] g3_io_pCrd_13_query_bits_pCrdType, i3_io_pCrd_13_query_bits_pCrdType;
  logic [10:0] g3_io_pCrd_13_query_bits_srcID, i3_io_pCrd_13_query_bits_srcID;
  logic g3_io_pCrd_14_query_valid, i3_io_pCrd_14_query_valid;
  logic [3:0] g3_io_pCrd_14_query_bits_pCrdType, i3_io_pCrd_14_query_bits_pCrdType;
  logic [10:0] g3_io_pCrd_14_query_bits_srcID, i3_io_pCrd_14_query_bits_srcID;
  logic g3_io_pCrd_15_query_valid, i3_io_pCrd_15_query_valid;
  logic [3:0] g3_io_pCrd_15_query_bits_pCrdType, i3_io_pCrd_15_query_bits_pCrdType;
  logic [10:0] g3_io_pCrd_15_query_bits_srcID, i3_io_pCrd_15_query_bits_srcID;
  logic [5:0] g3_io_perf_0_value, i3_io_perf_0_value;
  logic [5:0] g3_io_perf_1_value, i3_io_perf_1_value;
  logic [5:0] g3_io_perf_3_value, i3_io_perf_3_value;
  logic [5:0] g3_io_perf_4_value, i3_io_perf_4_value;
  logic [5:0] g3_io_perf_5_value, i3_io_perf_5_value;
  logic [5:0] g3_io_perf_6_value, i3_io_perf_6_value;
  logic [5:0] g3_io_perf_7_value, i3_io_perf_7_value;
  logic [5:0] g3_io_perf_8_value, i3_io_perf_8_value;
  logic [5:0] g3_io_perf_9_value, i3_io_perf_9_value;
  logic [5:0] g3_io_perf_10_value, i3_io_perf_10_value;
  logic [5:0] g3_io_perf_11_value, i3_io_perf_11_value;
  logic [5:0] g3_io_perf_12_value, i3_io_perf_12_value;
  logic [5:0] g3_io_perf_13_value, i3_io_perf_13_value;
  logic [5:0] g3_io_perf_14_value, i3_io_perf_14_value;
  logic [5:0] g3_io_perf_15_value, i3_io_perf_15_value;
  logic [5:0] g3_io_perf_16_value, i3_io_perf_16_value;
  logic g3_boreChildrenBd_bore_ack, i3_boreChildrenBd_bore_ack;
  logic [136:0] g3_boreChildrenBd_bore_outdata, i3_boreChildrenBd_bore_outdata;

  Slice u_g0 (
    .clock(clock),
    .reset(reset),
    .io_in_a_ready(g0_io_in_a_ready),
    .io_in_a_valid(io_in_a_valid),
    .io_in_a_bits_opcode(io_in_a_bits_opcode),
    .io_in_a_bits_param(io_in_a_bits_param),
    .io_in_a_bits_size(io_in_a_bits_size),
    .io_in_a_bits_source(io_in_a_bits_source),
    .io_in_a_bits_address(io_in_a_bits_address),
    .io_in_a_bits_user_reqSource(io_in_a_bits_user_reqSource),
    .io_in_a_bits_user_alias(io_in_a_bits_user_alias),
    .io_in_a_bits_user_vaddr(io_in_a_bits_user_vaddr),
    .io_in_a_bits_user_needHint(io_in_a_bits_user_needHint),
    .io_in_a_bits_echo_isKeyword(io_in_a_bits_echo_isKeyword),
    .io_in_a_bits_corrupt(io_in_a_bits_corrupt),
    .io_in_b_ready(io_in_b_ready),
    .io_in_b_valid(g0_io_in_b_valid),
    .io_in_b_bits_opcode(g0_io_in_b_bits_opcode),
    .io_in_b_bits_param(g0_io_in_b_bits_param),
    .io_in_b_bits_address(g0_io_in_b_bits_address),
    .io_in_b_bits_data(g0_io_in_b_bits_data),
    .io_in_c_ready(g0_io_in_c_ready),
    .io_in_c_valid(io_in_c_valid),
    .io_in_c_bits_opcode(io_in_c_bits_opcode),
    .io_in_c_bits_param(io_in_c_bits_param),
    .io_in_c_bits_size(io_in_c_bits_size),
    .io_in_c_bits_source(io_in_c_bits_source),
    .io_in_c_bits_address(io_in_c_bits_address),
    .io_in_c_bits_data(io_in_c_bits_data),
    .io_in_c_bits_corrupt(io_in_c_bits_corrupt),
    .io_in_d_ready(io_in_d_ready),
    .io_in_d_valid(g0_io_in_d_valid),
    .io_in_d_bits_opcode(g0_io_in_d_bits_opcode),
    .io_in_d_bits_param(g0_io_in_d_bits_param),
    .io_in_d_bits_source(g0_io_in_d_bits_source),
    .io_in_d_bits_sink(g0_io_in_d_bits_sink),
    .io_in_d_bits_denied(g0_io_in_d_bits_denied),
    .io_in_d_bits_echo_isKeyword(g0_io_in_d_bits_echo_isKeyword),
    .io_in_d_bits_data(g0_io_in_d_bits_data),
    .io_in_d_bits_corrupt(g0_io_in_d_bits_corrupt),
    .io_in_e_valid(io_in_e_valid),
    .io_in_e_bits_sink(io_in_e_bits_sink),
    .io_l1Hint_ready(io_l1Hint_ready),
    .io_l1Hint_valid(g0_io_l1Hint_valid),
    .io_l1Hint_bits_sourceId(g0_io_l1Hint_bits_sourceId),
    .io_l1Hint_bits_isKeyword(g0_io_l1Hint_bits_isKeyword),
    .io_prefetch_train_ready(io_prefetch_train_ready),
    .io_prefetch_train_valid(g0_io_prefetch_train_valid),
    .io_prefetch_train_bits_tag(g0_io_prefetch_train_bits_tag),
    .io_prefetch_train_bits_set(g0_io_prefetch_train_bits_set),
    .io_prefetch_train_bits_needT(g0_io_prefetch_train_bits_needT),
    .io_prefetch_train_bits_source(g0_io_prefetch_train_bits_source),
    .io_prefetch_train_bits_vaddr(g0_io_prefetch_train_bits_vaddr),
    .io_prefetch_train_bits_hit(g0_io_prefetch_train_bits_hit),
    .io_prefetch_train_bits_prefetched(g0_io_prefetch_train_bits_prefetched),
    .io_prefetch_train_bits_pfsource(g0_io_prefetch_train_bits_pfsource),
    .io_prefetch_train_bits_reqsource(g0_io_prefetch_train_bits_reqsource),
    .io_prefetch_req_ready(g0_io_prefetch_req_ready),
    .io_prefetch_req_valid(io_prefetch_req_valid),
    .io_prefetch_req_bits_tag(io_prefetch_req_bits_tag),
    .io_prefetch_req_bits_set(io_prefetch_req_bits_set),
    .io_prefetch_req_bits_vaddr(io_prefetch_req_bits_vaddr),
    .io_prefetch_req_bits_needT(io_prefetch_req_bits_needT),
    .io_prefetch_req_bits_source(io_prefetch_req_bits_source),
    .io_prefetch_req_bits_pfSource(io_prefetch_req_bits_pfSource),
    .io_prefetch_resp_ready(io_prefetch_resp_ready),
    .io_prefetch_resp_valid(g0_io_prefetch_resp_valid),
    .io_prefetch_resp_bits_tag(g0_io_prefetch_resp_bits_tag),
    .io_prefetch_resp_bits_set(g0_io_prefetch_resp_bits_set),
    .io_prefetch_resp_bits_vaddr(g0_io_prefetch_resp_bits_vaddr),
    .io_prefetch_resp_bits_pfSource(g0_io_prefetch_resp_bits_pfSource),
    .io_dirResult_valid(g0_io_dirResult_valid),
    .io_dirResult_bits_hit(g0_io_dirResult_bits_hit),
    .io_dirResult_bits_meta_prefetch(g0_io_dirResult_bits_meta_prefetch),
    .io_dirResult_bits_meta_prefetchSrc(g0_io_dirResult_bits_meta_prefetchSrc),
    .io_dirResult_bits_replacerInfo_channel(g0_io_dirResult_bits_replacerInfo_channel),
    .io_dirResult_bits_replacerInfo_reqSource(g0_io_dirResult_bits_replacerInfo_reqSource),
    .io_hitPfInMSHR_valid(g0_io_hitPfInMSHR_valid),
    .io_hitPfInMSHR_bits(g0_io_hitPfInMSHR_bits),
    .io_pfSent_valid(g0_io_pfSent_valid),
    .io_pfSent_bits(g0_io_pfSent_bits),
    .io_pfLateInMSHR_valid(g0_io_pfLateInMSHR_valid),
    .io_pfLateInMSHR_bits(g0_io_pfLateInMSHR_bits),
    .io_error_valid(g0_io_error_valid),
    .io_error_bits_valid(g0_io_error_bits_valid),
    .io_error_bits_address(g0_io_error_bits_address),
    .io_l2Miss(g0_io_l2Miss),
    .io_msStatus_0_valid(g0_io_msStatus_0_valid),
    .io_msStatus_0_bits_channel(g0_io_msStatus_0_bits_channel),
    .io_msStatus_0_bits_set(g0_io_msStatus_0_bits_set),
    .io_msStatus_0_bits_reqTag(g0_io_msStatus_0_bits_reqTag),
    .io_msStatus_0_bits_is_miss(g0_io_msStatus_0_bits_is_miss),
    .io_msStatus_0_bits_is_prefetch(g0_io_msStatus_0_bits_is_prefetch),
    .io_msStatus_1_valid(g0_io_msStatus_1_valid),
    .io_msStatus_1_bits_channel(g0_io_msStatus_1_bits_channel),
    .io_msStatus_1_bits_set(g0_io_msStatus_1_bits_set),
    .io_msStatus_1_bits_reqTag(g0_io_msStatus_1_bits_reqTag),
    .io_msStatus_1_bits_is_miss(g0_io_msStatus_1_bits_is_miss),
    .io_msStatus_1_bits_is_prefetch(g0_io_msStatus_1_bits_is_prefetch),
    .io_msStatus_2_valid(g0_io_msStatus_2_valid),
    .io_msStatus_2_bits_channel(g0_io_msStatus_2_bits_channel),
    .io_msStatus_2_bits_set(g0_io_msStatus_2_bits_set),
    .io_msStatus_2_bits_reqTag(g0_io_msStatus_2_bits_reqTag),
    .io_msStatus_2_bits_is_miss(g0_io_msStatus_2_bits_is_miss),
    .io_msStatus_2_bits_is_prefetch(g0_io_msStatus_2_bits_is_prefetch),
    .io_msStatus_3_valid(g0_io_msStatus_3_valid),
    .io_msStatus_3_bits_channel(g0_io_msStatus_3_bits_channel),
    .io_msStatus_3_bits_set(g0_io_msStatus_3_bits_set),
    .io_msStatus_3_bits_reqTag(g0_io_msStatus_3_bits_reqTag),
    .io_msStatus_3_bits_is_miss(g0_io_msStatus_3_bits_is_miss),
    .io_msStatus_3_bits_is_prefetch(g0_io_msStatus_3_bits_is_prefetch),
    .io_msStatus_4_valid(g0_io_msStatus_4_valid),
    .io_msStatus_4_bits_channel(g0_io_msStatus_4_bits_channel),
    .io_msStatus_4_bits_set(g0_io_msStatus_4_bits_set),
    .io_msStatus_4_bits_reqTag(g0_io_msStatus_4_bits_reqTag),
    .io_msStatus_4_bits_is_miss(g0_io_msStatus_4_bits_is_miss),
    .io_msStatus_4_bits_is_prefetch(g0_io_msStatus_4_bits_is_prefetch),
    .io_msStatus_5_valid(g0_io_msStatus_5_valid),
    .io_msStatus_5_bits_channel(g0_io_msStatus_5_bits_channel),
    .io_msStatus_5_bits_set(g0_io_msStatus_5_bits_set),
    .io_msStatus_5_bits_reqTag(g0_io_msStatus_5_bits_reqTag),
    .io_msStatus_5_bits_is_miss(g0_io_msStatus_5_bits_is_miss),
    .io_msStatus_5_bits_is_prefetch(g0_io_msStatus_5_bits_is_prefetch),
    .io_msStatus_6_valid(g0_io_msStatus_6_valid),
    .io_msStatus_6_bits_channel(g0_io_msStatus_6_bits_channel),
    .io_msStatus_6_bits_set(g0_io_msStatus_6_bits_set),
    .io_msStatus_6_bits_reqTag(g0_io_msStatus_6_bits_reqTag),
    .io_msStatus_6_bits_is_miss(g0_io_msStatus_6_bits_is_miss),
    .io_msStatus_6_bits_is_prefetch(g0_io_msStatus_6_bits_is_prefetch),
    .io_msStatus_7_valid(g0_io_msStatus_7_valid),
    .io_msStatus_7_bits_channel(g0_io_msStatus_7_bits_channel),
    .io_msStatus_7_bits_set(g0_io_msStatus_7_bits_set),
    .io_msStatus_7_bits_reqTag(g0_io_msStatus_7_bits_reqTag),
    .io_msStatus_7_bits_is_miss(g0_io_msStatus_7_bits_is_miss),
    .io_msStatus_7_bits_is_prefetch(g0_io_msStatus_7_bits_is_prefetch),
    .io_msStatus_8_valid(g0_io_msStatus_8_valid),
    .io_msStatus_8_bits_channel(g0_io_msStatus_8_bits_channel),
    .io_msStatus_8_bits_set(g0_io_msStatus_8_bits_set),
    .io_msStatus_8_bits_reqTag(g0_io_msStatus_8_bits_reqTag),
    .io_msStatus_8_bits_is_miss(g0_io_msStatus_8_bits_is_miss),
    .io_msStatus_8_bits_is_prefetch(g0_io_msStatus_8_bits_is_prefetch),
    .io_msStatus_9_valid(g0_io_msStatus_9_valid),
    .io_msStatus_9_bits_channel(g0_io_msStatus_9_bits_channel),
    .io_msStatus_9_bits_set(g0_io_msStatus_9_bits_set),
    .io_msStatus_9_bits_reqTag(g0_io_msStatus_9_bits_reqTag),
    .io_msStatus_9_bits_is_miss(g0_io_msStatus_9_bits_is_miss),
    .io_msStatus_9_bits_is_prefetch(g0_io_msStatus_9_bits_is_prefetch),
    .io_msStatus_10_valid(g0_io_msStatus_10_valid),
    .io_msStatus_10_bits_channel(g0_io_msStatus_10_bits_channel),
    .io_msStatus_10_bits_set(g0_io_msStatus_10_bits_set),
    .io_msStatus_10_bits_reqTag(g0_io_msStatus_10_bits_reqTag),
    .io_msStatus_10_bits_is_miss(g0_io_msStatus_10_bits_is_miss),
    .io_msStatus_10_bits_is_prefetch(g0_io_msStatus_10_bits_is_prefetch),
    .io_msStatus_11_valid(g0_io_msStatus_11_valid),
    .io_msStatus_11_bits_channel(g0_io_msStatus_11_bits_channel),
    .io_msStatus_11_bits_set(g0_io_msStatus_11_bits_set),
    .io_msStatus_11_bits_reqTag(g0_io_msStatus_11_bits_reqTag),
    .io_msStatus_11_bits_is_miss(g0_io_msStatus_11_bits_is_miss),
    .io_msStatus_11_bits_is_prefetch(g0_io_msStatus_11_bits_is_prefetch),
    .io_msStatus_12_valid(g0_io_msStatus_12_valid),
    .io_msStatus_12_bits_channel(g0_io_msStatus_12_bits_channel),
    .io_msStatus_12_bits_set(g0_io_msStatus_12_bits_set),
    .io_msStatus_12_bits_reqTag(g0_io_msStatus_12_bits_reqTag),
    .io_msStatus_12_bits_is_miss(g0_io_msStatus_12_bits_is_miss),
    .io_msStatus_12_bits_is_prefetch(g0_io_msStatus_12_bits_is_prefetch),
    .io_msStatus_13_valid(g0_io_msStatus_13_valid),
    .io_msStatus_13_bits_channel(g0_io_msStatus_13_bits_channel),
    .io_msStatus_13_bits_set(g0_io_msStatus_13_bits_set),
    .io_msStatus_13_bits_reqTag(g0_io_msStatus_13_bits_reqTag),
    .io_msStatus_13_bits_is_miss(g0_io_msStatus_13_bits_is_miss),
    .io_msStatus_13_bits_is_prefetch(g0_io_msStatus_13_bits_is_prefetch),
    .io_msStatus_14_valid(g0_io_msStatus_14_valid),
    .io_msStatus_14_bits_channel(g0_io_msStatus_14_bits_channel),
    .io_msStatus_14_bits_set(g0_io_msStatus_14_bits_set),
    .io_msStatus_14_bits_reqTag(g0_io_msStatus_14_bits_reqTag),
    .io_msStatus_14_bits_is_miss(g0_io_msStatus_14_bits_is_miss),
    .io_msStatus_14_bits_is_prefetch(g0_io_msStatus_14_bits_is_prefetch),
    .io_msStatus_15_valid(g0_io_msStatus_15_valid),
    .io_msStatus_15_bits_channel(g0_io_msStatus_15_bits_channel),
    .io_msStatus_15_bits_set(g0_io_msStatus_15_bits_set),
    .io_msStatus_15_bits_reqTag(g0_io_msStatus_15_bits_reqTag),
    .io_msStatus_15_bits_is_miss(g0_io_msStatus_15_bits_is_miss),
    .io_msStatus_15_bits_is_prefetch(g0_io_msStatus_15_bits_is_prefetch),
    .io_msAlloc_0_valid(g0_io_msAlloc_0_valid),
    .io_msAlloc_0_bits_channel(g0_io_msAlloc_0_bits_channel),
    .io_msAlloc_0_bits_is_miss(g0_io_msAlloc_0_bits_is_miss),
    .io_msAlloc_0_bits_is_prefetch(g0_io_msAlloc_0_bits_is_prefetch),
    .io_msAlloc_1_valid(g0_io_msAlloc_1_valid),
    .io_msAlloc_1_bits_channel(g0_io_msAlloc_1_bits_channel),
    .io_msAlloc_1_bits_is_miss(g0_io_msAlloc_1_bits_is_miss),
    .io_msAlloc_1_bits_is_prefetch(g0_io_msAlloc_1_bits_is_prefetch),
    .io_msAlloc_2_valid(g0_io_msAlloc_2_valid),
    .io_msAlloc_2_bits_channel(g0_io_msAlloc_2_bits_channel),
    .io_msAlloc_2_bits_is_miss(g0_io_msAlloc_2_bits_is_miss),
    .io_msAlloc_2_bits_is_prefetch(g0_io_msAlloc_2_bits_is_prefetch),
    .io_msAlloc_3_valid(g0_io_msAlloc_3_valid),
    .io_msAlloc_3_bits_channel(g0_io_msAlloc_3_bits_channel),
    .io_msAlloc_3_bits_is_miss(g0_io_msAlloc_3_bits_is_miss),
    .io_msAlloc_3_bits_is_prefetch(g0_io_msAlloc_3_bits_is_prefetch),
    .io_msAlloc_4_valid(g0_io_msAlloc_4_valid),
    .io_msAlloc_4_bits_channel(g0_io_msAlloc_4_bits_channel),
    .io_msAlloc_4_bits_is_miss(g0_io_msAlloc_4_bits_is_miss),
    .io_msAlloc_4_bits_is_prefetch(g0_io_msAlloc_4_bits_is_prefetch),
    .io_msAlloc_5_valid(g0_io_msAlloc_5_valid),
    .io_msAlloc_5_bits_channel(g0_io_msAlloc_5_bits_channel),
    .io_msAlloc_5_bits_is_miss(g0_io_msAlloc_5_bits_is_miss),
    .io_msAlloc_5_bits_is_prefetch(g0_io_msAlloc_5_bits_is_prefetch),
    .io_msAlloc_6_valid(g0_io_msAlloc_6_valid),
    .io_msAlloc_6_bits_channel(g0_io_msAlloc_6_bits_channel),
    .io_msAlloc_6_bits_is_miss(g0_io_msAlloc_6_bits_is_miss),
    .io_msAlloc_6_bits_is_prefetch(g0_io_msAlloc_6_bits_is_prefetch),
    .io_msAlloc_7_valid(g0_io_msAlloc_7_valid),
    .io_msAlloc_7_bits_channel(g0_io_msAlloc_7_bits_channel),
    .io_msAlloc_7_bits_is_miss(g0_io_msAlloc_7_bits_is_miss),
    .io_msAlloc_7_bits_is_prefetch(g0_io_msAlloc_7_bits_is_prefetch),
    .io_msAlloc_8_valid(g0_io_msAlloc_8_valid),
    .io_msAlloc_8_bits_channel(g0_io_msAlloc_8_bits_channel),
    .io_msAlloc_8_bits_is_miss(g0_io_msAlloc_8_bits_is_miss),
    .io_msAlloc_8_bits_is_prefetch(g0_io_msAlloc_8_bits_is_prefetch),
    .io_msAlloc_9_valid(g0_io_msAlloc_9_valid),
    .io_msAlloc_9_bits_channel(g0_io_msAlloc_9_bits_channel),
    .io_msAlloc_9_bits_is_miss(g0_io_msAlloc_9_bits_is_miss),
    .io_msAlloc_9_bits_is_prefetch(g0_io_msAlloc_9_bits_is_prefetch),
    .io_msAlloc_10_valid(g0_io_msAlloc_10_valid),
    .io_msAlloc_10_bits_channel(g0_io_msAlloc_10_bits_channel),
    .io_msAlloc_10_bits_is_miss(g0_io_msAlloc_10_bits_is_miss),
    .io_msAlloc_10_bits_is_prefetch(g0_io_msAlloc_10_bits_is_prefetch),
    .io_msAlloc_11_valid(g0_io_msAlloc_11_valid),
    .io_msAlloc_11_bits_channel(g0_io_msAlloc_11_bits_channel),
    .io_msAlloc_11_bits_is_miss(g0_io_msAlloc_11_bits_is_miss),
    .io_msAlloc_11_bits_is_prefetch(g0_io_msAlloc_11_bits_is_prefetch),
    .io_msAlloc_12_valid(g0_io_msAlloc_12_valid),
    .io_msAlloc_12_bits_channel(g0_io_msAlloc_12_bits_channel),
    .io_msAlloc_12_bits_is_miss(g0_io_msAlloc_12_bits_is_miss),
    .io_msAlloc_12_bits_is_prefetch(g0_io_msAlloc_12_bits_is_prefetch),
    .io_msAlloc_13_valid(g0_io_msAlloc_13_valid),
    .io_msAlloc_13_bits_channel(g0_io_msAlloc_13_bits_channel),
    .io_msAlloc_13_bits_is_miss(g0_io_msAlloc_13_bits_is_miss),
    .io_msAlloc_13_bits_is_prefetch(g0_io_msAlloc_13_bits_is_prefetch),
    .io_msAlloc_14_valid(g0_io_msAlloc_14_valid),
    .io_msAlloc_14_bits_channel(g0_io_msAlloc_14_bits_channel),
    .io_msAlloc_14_bits_is_miss(g0_io_msAlloc_14_bits_is_miss),
    .io_msAlloc_14_bits_is_prefetch(g0_io_msAlloc_14_bits_is_prefetch),
    .io_msAlloc_15_valid(g0_io_msAlloc_15_valid),
    .io_msAlloc_15_bits_channel(g0_io_msAlloc_15_bits_channel),
    .io_msAlloc_15_bits_is_miss(g0_io_msAlloc_15_bits_is_miss),
    .io_msAlloc_15_bits_is_prefetch(g0_io_msAlloc_15_bits_is_prefetch),
    .io_out_tx_req_ready(io_out_tx_req_ready),
    .io_out_tx_req_valid(g0_io_out_tx_req_valid),
    .io_out_tx_req_bits_qos(g0_io_out_tx_req_bits_qos),
    .io_out_tx_req_bits_txnID(g0_io_out_tx_req_bits_txnID),
    .io_out_tx_req_bits_returnNID(g0_io_out_tx_req_bits_returnNID),
    .io_out_tx_req_bits_stashNIDValid(g0_io_out_tx_req_bits_stashNIDValid),
    .io_out_tx_req_bits_returnTxnID(g0_io_out_tx_req_bits_returnTxnID),
    .io_out_tx_req_bits_opcode(g0_io_out_tx_req_bits_opcode),
    .io_out_tx_req_bits_addr(g0_io_out_tx_req_bits_addr),
    .io_out_tx_req_bits_ns(g0_io_out_tx_req_bits_ns),
    .io_out_tx_req_bits_likelyshared(g0_io_out_tx_req_bits_likelyshared),
    .io_out_tx_req_bits_allowRetry(g0_io_out_tx_req_bits_allowRetry),
    .io_out_tx_req_bits_order(g0_io_out_tx_req_bits_order),
    .io_out_tx_req_bits_pCrdType(g0_io_out_tx_req_bits_pCrdType),
    .io_out_tx_req_bits_memAttr_allocate(g0_io_out_tx_req_bits_memAttr_allocate),
    .io_out_tx_req_bits_memAttr_cacheable(g0_io_out_tx_req_bits_memAttr_cacheable),
    .io_out_tx_req_bits_memAttr_device(g0_io_out_tx_req_bits_memAttr_device),
    .io_out_tx_req_bits_memAttr_ewa(g0_io_out_tx_req_bits_memAttr_ewa),
    .io_out_tx_req_bits_snpAttr(g0_io_out_tx_req_bits_snpAttr),
    .io_out_tx_req_bits_lpIDWithPadding(g0_io_out_tx_req_bits_lpIDWithPadding),
    .io_out_tx_req_bits_snoopMe(g0_io_out_tx_req_bits_snoopMe),
    .io_out_tx_req_bits_expCompAck(g0_io_out_tx_req_bits_expCompAck),
    .io_out_tx_req_bits_tagOp(g0_io_out_tx_req_bits_tagOp),
    .io_out_tx_req_bits_traceTag(g0_io_out_tx_req_bits_traceTag),
    .io_out_tx_req_bits_mpam_perfMonGroup(g0_io_out_tx_req_bits_mpam_perfMonGroup),
    .io_out_tx_req_bits_mpam_partID(g0_io_out_tx_req_bits_mpam_partID),
    .io_out_tx_req_bits_mpam_mpamNS(g0_io_out_tx_req_bits_mpam_mpamNS),
    .io_out_tx_req_bits_rsvdc(g0_io_out_tx_req_bits_rsvdc),
    .io_out_tx_rsp_ready(io_out_tx_rsp_ready),
    .io_out_tx_rsp_valid(g0_io_out_tx_rsp_valid),
    .io_out_tx_rsp_bits_qos(g0_io_out_tx_rsp_bits_qos),
    .io_out_tx_rsp_bits_tgtID(g0_io_out_tx_rsp_bits_tgtID),
    .io_out_tx_rsp_bits_txnID(g0_io_out_tx_rsp_bits_txnID),
    .io_out_tx_rsp_bits_opcode(g0_io_out_tx_rsp_bits_opcode),
    .io_out_tx_rsp_bits_respErr(g0_io_out_tx_rsp_bits_respErr),
    .io_out_tx_rsp_bits_resp(g0_io_out_tx_rsp_bits_resp),
    .io_out_tx_rsp_bits_fwdState(g0_io_out_tx_rsp_bits_fwdState),
    .io_out_tx_rsp_bits_cBusy(g0_io_out_tx_rsp_bits_cBusy),
    .io_out_tx_rsp_bits_dbID(g0_io_out_tx_rsp_bits_dbID),
    .io_out_tx_rsp_bits_pCrdType(g0_io_out_tx_rsp_bits_pCrdType),
    .io_out_tx_rsp_bits_tagOp(g0_io_out_tx_rsp_bits_tagOp),
    .io_out_tx_rsp_bits_traceTag(g0_io_out_tx_rsp_bits_traceTag),
    .io_out_tx_dat_ready(io_out_tx_dat_ready),
    .io_out_tx_dat_valid(g0_io_out_tx_dat_valid),
    .io_out_tx_dat_bits_tgtID(g0_io_out_tx_dat_bits_tgtID),
    .io_out_tx_dat_bits_txnID(g0_io_out_tx_dat_bits_txnID),
    .io_out_tx_dat_bits_homeNID(g0_io_out_tx_dat_bits_homeNID),
    .io_out_tx_dat_bits_opcode(g0_io_out_tx_dat_bits_opcode),
    .io_out_tx_dat_bits_respErr(g0_io_out_tx_dat_bits_respErr),
    .io_out_tx_dat_bits_resp(g0_io_out_tx_dat_bits_resp),
    .io_out_tx_dat_bits_dataSource(g0_io_out_tx_dat_bits_dataSource),
    .io_out_tx_dat_bits_dbID(g0_io_out_tx_dat_bits_dbID),
    .io_out_tx_dat_bits_ccID(g0_io_out_tx_dat_bits_ccID),
    .io_out_tx_dat_bits_dataID(g0_io_out_tx_dat_bits_dataID),
    .io_out_tx_dat_bits_traceTag(g0_io_out_tx_dat_bits_traceTag),
    .io_out_tx_dat_bits_be(g0_io_out_tx_dat_bits_be),
    .io_out_tx_dat_bits_data(g0_io_out_tx_dat_bits_data),
    .io_out_tx_dat_bits_dataCheck(g0_io_out_tx_dat_bits_dataCheck),
    .io_out_tx_dat_bits_poison(g0_io_out_tx_dat_bits_poison),
    .io_out_rx_rsp_valid(io_out_rx_rsp_valid),
    .io_out_rx_rsp_bits_srcID(io_out_rx_rsp_bits_srcID),
    .io_out_rx_rsp_bits_txnID(io_out_rx_rsp_bits_txnID),
    .io_out_rx_rsp_bits_opcode(io_out_rx_rsp_bits_opcode),
    .io_out_rx_rsp_bits_respErr(io_out_rx_rsp_bits_respErr),
    .io_out_rx_rsp_bits_resp(io_out_rx_rsp_bits_resp),
    .io_out_rx_rsp_bits_dbID(io_out_rx_rsp_bits_dbID),
    .io_out_rx_rsp_bits_pCrdType(io_out_rx_rsp_bits_pCrdType),
    .io_out_rx_rsp_bits_traceTag(io_out_rx_rsp_bits_traceTag),
    .io_out_rx_dat_valid(io_out_rx_dat_valid),
    .io_out_rx_dat_bits_txnID(io_out_rx_dat_bits_txnID),
    .io_out_rx_dat_bits_homeNID(io_out_rx_dat_bits_homeNID),
    .io_out_rx_dat_bits_opcode(io_out_rx_dat_bits_opcode),
    .io_out_rx_dat_bits_respErr(io_out_rx_dat_bits_respErr),
    .io_out_rx_dat_bits_resp(io_out_rx_dat_bits_resp),
    .io_out_rx_dat_bits_dbID(io_out_rx_dat_bits_dbID),
    .io_out_rx_dat_bits_dataID(io_out_rx_dat_bits_dataID),
    .io_out_rx_dat_bits_traceTag(io_out_rx_dat_bits_traceTag),
    .io_out_rx_dat_bits_data(io_out_rx_dat_bits_data),
    .io_out_rx_dat_bits_dataCheck(io_out_rx_dat_bits_dataCheck),
    .io_out_rx_dat_bits_poison(io_out_rx_dat_bits_poison),
    .io_out_rx_snp_ready(g0_io_out_rx_snp_ready),
    .io_out_rx_snp_valid(io_out_rx_snp_valid),
    .io_out_rx_snp_bits_qos(io_out_rx_snp_bits_qos),
    .io_out_rx_snp_bits_srcID(io_out_rx_snp_bits_srcID),
    .io_out_rx_snp_bits_txnID(io_out_rx_snp_bits_txnID),
    .io_out_rx_snp_bits_fwdNID(io_out_rx_snp_bits_fwdNID),
    .io_out_rx_snp_bits_fwdTxnID(io_out_rx_snp_bits_fwdTxnID),
    .io_out_rx_snp_bits_opcode(io_out_rx_snp_bits_opcode),
    .io_out_rx_snp_bits_addr(io_out_rx_snp_bits_addr),
    .io_out_rx_snp_bits_ns(io_out_rx_snp_bits_ns),
    .io_out_rx_snp_bits_doNotGoToSD(io_out_rx_snp_bits_doNotGoToSD),
    .io_out_rx_snp_bits_retToSrc(io_out_rx_snp_bits_retToSrc),
    .io_out_rx_snp_bits_traceTag(io_out_rx_snp_bits_traceTag),
    .io_out_rx_snp_bits_mpam_perfMonGroup(io_out_rx_snp_bits_mpam_perfMonGroup),
    .io_out_rx_snp_bits_mpam_partID(io_out_rx_snp_bits_mpam_partID),
    .io_out_rx_snp_bits_mpam_mpamNS(io_out_rx_snp_bits_mpam_mpamNS),
    .io_pCrd_0_query_valid(g0_io_pCrd_0_query_valid),
    .io_pCrd_0_query_bits_pCrdType(g0_io_pCrd_0_query_bits_pCrdType),
    .io_pCrd_0_query_bits_srcID(g0_io_pCrd_0_query_bits_srcID),
    .io_pCrd_0_grant(io_pCrd_0_grant),
    .io_pCrd_1_query_valid(g0_io_pCrd_1_query_valid),
    .io_pCrd_1_query_bits_pCrdType(g0_io_pCrd_1_query_bits_pCrdType),
    .io_pCrd_1_query_bits_srcID(g0_io_pCrd_1_query_bits_srcID),
    .io_pCrd_1_grant(io_pCrd_1_grant),
    .io_pCrd_2_query_valid(g0_io_pCrd_2_query_valid),
    .io_pCrd_2_query_bits_pCrdType(g0_io_pCrd_2_query_bits_pCrdType),
    .io_pCrd_2_query_bits_srcID(g0_io_pCrd_2_query_bits_srcID),
    .io_pCrd_2_grant(io_pCrd_2_grant),
    .io_pCrd_3_query_valid(g0_io_pCrd_3_query_valid),
    .io_pCrd_3_query_bits_pCrdType(g0_io_pCrd_3_query_bits_pCrdType),
    .io_pCrd_3_query_bits_srcID(g0_io_pCrd_3_query_bits_srcID),
    .io_pCrd_3_grant(io_pCrd_3_grant),
    .io_pCrd_4_query_valid(g0_io_pCrd_4_query_valid),
    .io_pCrd_4_query_bits_pCrdType(g0_io_pCrd_4_query_bits_pCrdType),
    .io_pCrd_4_query_bits_srcID(g0_io_pCrd_4_query_bits_srcID),
    .io_pCrd_4_grant(io_pCrd_4_grant),
    .io_pCrd_5_query_valid(g0_io_pCrd_5_query_valid),
    .io_pCrd_5_query_bits_pCrdType(g0_io_pCrd_5_query_bits_pCrdType),
    .io_pCrd_5_query_bits_srcID(g0_io_pCrd_5_query_bits_srcID),
    .io_pCrd_5_grant(io_pCrd_5_grant),
    .io_pCrd_6_query_valid(g0_io_pCrd_6_query_valid),
    .io_pCrd_6_query_bits_pCrdType(g0_io_pCrd_6_query_bits_pCrdType),
    .io_pCrd_6_query_bits_srcID(g0_io_pCrd_6_query_bits_srcID),
    .io_pCrd_6_grant(io_pCrd_6_grant),
    .io_pCrd_7_query_valid(g0_io_pCrd_7_query_valid),
    .io_pCrd_7_query_bits_pCrdType(g0_io_pCrd_7_query_bits_pCrdType),
    .io_pCrd_7_query_bits_srcID(g0_io_pCrd_7_query_bits_srcID),
    .io_pCrd_7_grant(io_pCrd_7_grant),
    .io_pCrd_8_query_valid(g0_io_pCrd_8_query_valid),
    .io_pCrd_8_query_bits_pCrdType(g0_io_pCrd_8_query_bits_pCrdType),
    .io_pCrd_8_query_bits_srcID(g0_io_pCrd_8_query_bits_srcID),
    .io_pCrd_8_grant(io_pCrd_8_grant),
    .io_pCrd_9_query_valid(g0_io_pCrd_9_query_valid),
    .io_pCrd_9_query_bits_pCrdType(g0_io_pCrd_9_query_bits_pCrdType),
    .io_pCrd_9_query_bits_srcID(g0_io_pCrd_9_query_bits_srcID),
    .io_pCrd_9_grant(io_pCrd_9_grant),
    .io_pCrd_10_query_valid(g0_io_pCrd_10_query_valid),
    .io_pCrd_10_query_bits_pCrdType(g0_io_pCrd_10_query_bits_pCrdType),
    .io_pCrd_10_query_bits_srcID(g0_io_pCrd_10_query_bits_srcID),
    .io_pCrd_10_grant(io_pCrd_10_grant),
    .io_pCrd_11_query_valid(g0_io_pCrd_11_query_valid),
    .io_pCrd_11_query_bits_pCrdType(g0_io_pCrd_11_query_bits_pCrdType),
    .io_pCrd_11_query_bits_srcID(g0_io_pCrd_11_query_bits_srcID),
    .io_pCrd_11_grant(io_pCrd_11_grant),
    .io_pCrd_12_query_valid(g0_io_pCrd_12_query_valid),
    .io_pCrd_12_query_bits_pCrdType(g0_io_pCrd_12_query_bits_pCrdType),
    .io_pCrd_12_query_bits_srcID(g0_io_pCrd_12_query_bits_srcID),
    .io_pCrd_12_grant(io_pCrd_12_grant),
    .io_pCrd_13_query_valid(g0_io_pCrd_13_query_valid),
    .io_pCrd_13_query_bits_pCrdType(g0_io_pCrd_13_query_bits_pCrdType),
    .io_pCrd_13_query_bits_srcID(g0_io_pCrd_13_query_bits_srcID),
    .io_pCrd_13_grant(io_pCrd_13_grant),
    .io_pCrd_14_query_valid(g0_io_pCrd_14_query_valid),
    .io_pCrd_14_query_bits_pCrdType(g0_io_pCrd_14_query_bits_pCrdType),
    .io_pCrd_14_query_bits_srcID(g0_io_pCrd_14_query_bits_srcID),
    .io_pCrd_14_grant(io_pCrd_14_grant),
    .io_pCrd_15_query_valid(g0_io_pCrd_15_query_valid),
    .io_pCrd_15_query_bits_pCrdType(g0_io_pCrd_15_query_bits_pCrdType),
    .io_pCrd_15_query_bits_srcID(g0_io_pCrd_15_query_bits_srcID),
    .io_pCrd_15_grant(io_pCrd_15_grant),
    .io_perf_0_value(g0_io_perf_0_value),
    .io_perf_1_value(g0_io_perf_1_value),
    .io_perf_3_value(g0_io_perf_3_value),
    .io_perf_4_value(g0_io_perf_4_value),
    .io_perf_5_value(g0_io_perf_5_value),
    .io_perf_6_value(g0_io_perf_6_value),
    .io_perf_7_value(g0_io_perf_7_value),
    .io_perf_8_value(g0_io_perf_8_value),
    .io_perf_9_value(g0_io_perf_9_value),
    .io_perf_10_value(g0_io_perf_10_value),
    .io_perf_11_value(g0_io_perf_11_value),
    .io_perf_12_value(g0_io_perf_12_value),
    .io_perf_13_value(g0_io_perf_13_value),
    .io_perf_14_value(g0_io_perf_14_value),
    .io_perf_15_value(g0_io_perf_15_value),
    .io_perf_16_value(g0_io_perf_16_value),
    .sigFromSrams_bore_ram_hold(sigFromSrams_bore_ram_hold),
    .sigFromSrams_bore_ram_bypass(sigFromSrams_bore_ram_bypass),
    .sigFromSrams_bore_ram_bp_clken(sigFromSrams_bore_ram_bp_clken),
    .sigFromSrams_bore_ram_aux_clk(sigFromSrams_bore_ram_aux_clk),
    .sigFromSrams_bore_ram_aux_ckbp(sigFromSrams_bore_ram_aux_ckbp),
    .sigFromSrams_bore_ram_mcp_hold(sigFromSrams_bore_ram_mcp_hold),
    .sigFromSrams_bore_cgen(sigFromSrams_bore_cgen),
    .sigFromSrams_bore_1_ram_hold(sigFromSrams_bore_1_ram_hold),
    .sigFromSrams_bore_1_ram_bypass(sigFromSrams_bore_1_ram_bypass),
    .sigFromSrams_bore_1_ram_bp_clken(sigFromSrams_bore_1_ram_bp_clken),
    .sigFromSrams_bore_1_ram_aux_clk(sigFromSrams_bore_1_ram_aux_clk),
    .sigFromSrams_bore_1_ram_aux_ckbp(sigFromSrams_bore_1_ram_aux_ckbp),
    .sigFromSrams_bore_1_ram_mcp_hold(sigFromSrams_bore_1_ram_mcp_hold),
    .sigFromSrams_bore_1_cgen(sigFromSrams_bore_1_cgen),
    .sigFromSrams_bore_2_ram_hold(sigFromSrams_bore_2_ram_hold),
    .sigFromSrams_bore_2_ram_bypass(sigFromSrams_bore_2_ram_bypass),
    .sigFromSrams_bore_2_ram_bp_clken(sigFromSrams_bore_2_ram_bp_clken),
    .sigFromSrams_bore_2_ram_aux_clk(sigFromSrams_bore_2_ram_aux_clk),
    .sigFromSrams_bore_2_ram_aux_ckbp(sigFromSrams_bore_2_ram_aux_ckbp),
    .sigFromSrams_bore_2_ram_mcp_hold(sigFromSrams_bore_2_ram_mcp_hold),
    .sigFromSrams_bore_2_cgen(sigFromSrams_bore_2_cgen),
    .sigFromSrams_bore_3_ram_hold(sigFromSrams_bore_3_ram_hold),
    .sigFromSrams_bore_3_ram_bypass(sigFromSrams_bore_3_ram_bypass),
    .sigFromSrams_bore_3_ram_bp_clken(sigFromSrams_bore_3_ram_bp_clken),
    .sigFromSrams_bore_3_ram_aux_clk(sigFromSrams_bore_3_ram_aux_clk),
    .sigFromSrams_bore_3_ram_aux_ckbp(sigFromSrams_bore_3_ram_aux_ckbp),
    .sigFromSrams_bore_3_ram_mcp_hold(sigFromSrams_bore_3_ram_mcp_hold),
    .sigFromSrams_bore_3_cgen(sigFromSrams_bore_3_cgen),
    .sigFromSrams_bore_4_ram_hold(sigFromSrams_bore_4_ram_hold),
    .sigFromSrams_bore_4_ram_bypass(sigFromSrams_bore_4_ram_bypass),
    .sigFromSrams_bore_4_ram_bp_clken(sigFromSrams_bore_4_ram_bp_clken),
    .sigFromSrams_bore_4_ram_aux_clk(sigFromSrams_bore_4_ram_aux_clk),
    .sigFromSrams_bore_4_ram_aux_ckbp(sigFromSrams_bore_4_ram_aux_ckbp),
    .sigFromSrams_bore_4_ram_mcp_hold(sigFromSrams_bore_4_ram_mcp_hold),
    .sigFromSrams_bore_4_cgen(sigFromSrams_bore_4_cgen),
    .sigFromSrams_bore_5_ram_hold(sigFromSrams_bore_5_ram_hold),
    .sigFromSrams_bore_5_ram_bypass(sigFromSrams_bore_5_ram_bypass),
    .sigFromSrams_bore_5_ram_bp_clken(sigFromSrams_bore_5_ram_bp_clken),
    .sigFromSrams_bore_5_ram_aux_clk(sigFromSrams_bore_5_ram_aux_clk),
    .sigFromSrams_bore_5_ram_aux_ckbp(sigFromSrams_bore_5_ram_aux_ckbp),
    .sigFromSrams_bore_5_ram_mcp_hold(sigFromSrams_bore_5_ram_mcp_hold),
    .sigFromSrams_bore_5_cgen(sigFromSrams_bore_5_cgen),
    .sigFromSrams_bore_6_ram_hold(sigFromSrams_bore_6_ram_hold),
    .sigFromSrams_bore_6_ram_bypass(sigFromSrams_bore_6_ram_bypass),
    .sigFromSrams_bore_6_ram_bp_clken(sigFromSrams_bore_6_ram_bp_clken),
    .sigFromSrams_bore_6_ram_aux_clk(sigFromSrams_bore_6_ram_aux_clk),
    .sigFromSrams_bore_6_ram_aux_ckbp(sigFromSrams_bore_6_ram_aux_ckbp),
    .sigFromSrams_bore_6_ram_mcp_hold(sigFromSrams_bore_6_ram_mcp_hold),
    .sigFromSrams_bore_6_cgen(sigFromSrams_bore_6_cgen),
    .sigFromSrams_bore_7_ram_hold(sigFromSrams_bore_7_ram_hold),
    .sigFromSrams_bore_7_ram_bypass(sigFromSrams_bore_7_ram_bypass),
    .sigFromSrams_bore_7_ram_bp_clken(sigFromSrams_bore_7_ram_bp_clken),
    .sigFromSrams_bore_7_ram_aux_clk(sigFromSrams_bore_7_ram_aux_clk),
    .sigFromSrams_bore_7_ram_aux_ckbp(sigFromSrams_bore_7_ram_aux_ckbp),
    .sigFromSrams_bore_7_ram_mcp_hold(sigFromSrams_bore_7_ram_mcp_hold),
    .sigFromSrams_bore_7_cgen(sigFromSrams_bore_7_cgen),
    .sigFromSrams_bore_8_ram_hold(sigFromSrams_bore_8_ram_hold),
    .sigFromSrams_bore_8_ram_bypass(sigFromSrams_bore_8_ram_bypass),
    .sigFromSrams_bore_8_ram_bp_clken(sigFromSrams_bore_8_ram_bp_clken),
    .sigFromSrams_bore_8_ram_aux_clk(sigFromSrams_bore_8_ram_aux_clk),
    .sigFromSrams_bore_8_ram_aux_ckbp(sigFromSrams_bore_8_ram_aux_ckbp),
    .sigFromSrams_bore_8_ram_mcp_hold(sigFromSrams_bore_8_ram_mcp_hold),
    .sigFromSrams_bore_8_cgen(sigFromSrams_bore_8_cgen),
    .sigFromSrams_bore_9_ram_hold(sigFromSrams_bore_9_ram_hold),
    .sigFromSrams_bore_9_ram_bypass(sigFromSrams_bore_9_ram_bypass),
    .sigFromSrams_bore_9_ram_bp_clken(sigFromSrams_bore_9_ram_bp_clken),
    .sigFromSrams_bore_9_ram_aux_clk(sigFromSrams_bore_9_ram_aux_clk),
    .sigFromSrams_bore_9_ram_aux_ckbp(sigFromSrams_bore_9_ram_aux_ckbp),
    .sigFromSrams_bore_9_ram_mcp_hold(sigFromSrams_bore_9_ram_mcp_hold),
    .sigFromSrams_bore_9_cgen(sigFromSrams_bore_9_cgen),
    .sigFromSrams_bore_10_ram_hold(sigFromSrams_bore_10_ram_hold),
    .sigFromSrams_bore_10_ram_bypass(sigFromSrams_bore_10_ram_bypass),
    .sigFromSrams_bore_10_ram_bp_clken(sigFromSrams_bore_10_ram_bp_clken),
    .sigFromSrams_bore_10_ram_aux_clk(sigFromSrams_bore_10_ram_aux_clk),
    .sigFromSrams_bore_10_ram_aux_ckbp(sigFromSrams_bore_10_ram_aux_ckbp),
    .sigFromSrams_bore_10_ram_mcp_hold(sigFromSrams_bore_10_ram_mcp_hold),
    .sigFromSrams_bore_10_cgen(sigFromSrams_bore_10_cgen),
    .boreChildrenBd_bore_array(4'(boreChildrenBd_bore_array)),
    .boreChildrenBd_bore_all(boreChildrenBd_bore_all),
    .boreChildrenBd_bore_req(boreChildrenBd_bore_req),
    .boreChildrenBd_bore_ack(g0_boreChildrenBd_bore_ack),
    .boreChildrenBd_bore_writeen(boreChildrenBd_bore_writeen),
    .boreChildrenBd_bore_be(boreChildrenBd_bore_be),
    .boreChildrenBd_bore_addr(boreChildrenBd_bore_addr),
    .boreChildrenBd_bore_indata(boreChildrenBd_bore_indata),
    .boreChildrenBd_bore_readen(boreChildrenBd_bore_readen),
    .boreChildrenBd_bore_addr_rd(boreChildrenBd_bore_addr_rd),
    .boreChildrenBd_bore_outdata(g0_boreChildrenBd_bore_outdata)
  );
  Slice_xs u_i0 (
    .clock(clock),
    .reset(reset),
    .io_in_a_ready(i0_io_in_a_ready),
    .io_in_a_valid(io_in_a_valid),
    .io_in_a_bits_opcode(io_in_a_bits_opcode),
    .io_in_a_bits_param(io_in_a_bits_param),
    .io_in_a_bits_size(io_in_a_bits_size),
    .io_in_a_bits_source(io_in_a_bits_source),
    .io_in_a_bits_address(io_in_a_bits_address),
    .io_in_a_bits_user_reqSource(io_in_a_bits_user_reqSource),
    .io_in_a_bits_user_alias(io_in_a_bits_user_alias),
    .io_in_a_bits_user_vaddr(io_in_a_bits_user_vaddr),
    .io_in_a_bits_user_needHint(io_in_a_bits_user_needHint),
    .io_in_a_bits_echo_isKeyword(io_in_a_bits_echo_isKeyword),
    .io_in_a_bits_corrupt(io_in_a_bits_corrupt),
    .io_in_b_ready(io_in_b_ready),
    .io_in_b_valid(i0_io_in_b_valid),
    .io_in_b_bits_opcode(i0_io_in_b_bits_opcode),
    .io_in_b_bits_param(i0_io_in_b_bits_param),
    .io_in_b_bits_address(i0_io_in_b_bits_address),
    .io_in_b_bits_data(i0_io_in_b_bits_data),
    .io_in_c_ready(i0_io_in_c_ready),
    .io_in_c_valid(io_in_c_valid),
    .io_in_c_bits_opcode(io_in_c_bits_opcode),
    .io_in_c_bits_param(io_in_c_bits_param),
    .io_in_c_bits_size(io_in_c_bits_size),
    .io_in_c_bits_source(io_in_c_bits_source),
    .io_in_c_bits_address(io_in_c_bits_address),
    .io_in_c_bits_data(io_in_c_bits_data),
    .io_in_c_bits_corrupt(io_in_c_bits_corrupt),
    .io_in_d_ready(io_in_d_ready),
    .io_in_d_valid(i0_io_in_d_valid),
    .io_in_d_bits_opcode(i0_io_in_d_bits_opcode),
    .io_in_d_bits_param(i0_io_in_d_bits_param),
    .io_in_d_bits_source(i0_io_in_d_bits_source),
    .io_in_d_bits_sink(i0_io_in_d_bits_sink),
    .io_in_d_bits_denied(i0_io_in_d_bits_denied),
    .io_in_d_bits_echo_isKeyword(i0_io_in_d_bits_echo_isKeyword),
    .io_in_d_bits_data(i0_io_in_d_bits_data),
    .io_in_d_bits_corrupt(i0_io_in_d_bits_corrupt),
    .io_in_e_valid(io_in_e_valid),
    .io_in_e_bits_sink(io_in_e_bits_sink),
    .io_l1Hint_ready(io_l1Hint_ready),
    .io_l1Hint_valid(i0_io_l1Hint_valid),
    .io_l1Hint_bits_sourceId(i0_io_l1Hint_bits_sourceId),
    .io_l1Hint_bits_isKeyword(i0_io_l1Hint_bits_isKeyword),
    .io_prefetch_train_ready(io_prefetch_train_ready),
    .io_prefetch_train_valid(i0_io_prefetch_train_valid),
    .io_prefetch_train_bits_tag(i0_io_prefetch_train_bits_tag),
    .io_prefetch_train_bits_set(i0_io_prefetch_train_bits_set),
    .io_prefetch_train_bits_needT(i0_io_prefetch_train_bits_needT),
    .io_prefetch_train_bits_source(i0_io_prefetch_train_bits_source),
    .io_prefetch_train_bits_vaddr(i0_io_prefetch_train_bits_vaddr),
    .io_prefetch_train_bits_hit(i0_io_prefetch_train_bits_hit),
    .io_prefetch_train_bits_prefetched(i0_io_prefetch_train_bits_prefetched),
    .io_prefetch_train_bits_pfsource(i0_io_prefetch_train_bits_pfsource),
    .io_prefetch_train_bits_reqsource(i0_io_prefetch_train_bits_reqsource),
    .io_prefetch_req_ready(i0_io_prefetch_req_ready),
    .io_prefetch_req_valid(io_prefetch_req_valid),
    .io_prefetch_req_bits_tag(io_prefetch_req_bits_tag),
    .io_prefetch_req_bits_set(io_prefetch_req_bits_set),
    .io_prefetch_req_bits_vaddr(io_prefetch_req_bits_vaddr),
    .io_prefetch_req_bits_needT(io_prefetch_req_bits_needT),
    .io_prefetch_req_bits_source(io_prefetch_req_bits_source),
    .io_prefetch_req_bits_pfSource(io_prefetch_req_bits_pfSource),
    .io_prefetch_resp_ready(io_prefetch_resp_ready),
    .io_prefetch_resp_valid(i0_io_prefetch_resp_valid),
    .io_prefetch_resp_bits_tag(i0_io_prefetch_resp_bits_tag),
    .io_prefetch_resp_bits_set(i0_io_prefetch_resp_bits_set),
    .io_prefetch_resp_bits_vaddr(i0_io_prefetch_resp_bits_vaddr),
    .io_prefetch_resp_bits_pfSource(i0_io_prefetch_resp_bits_pfSource),
    .io_dirResult_valid(i0_io_dirResult_valid),
    .io_dirResult_bits_hit(i0_io_dirResult_bits_hit),
    .io_dirResult_bits_meta_prefetch(i0_io_dirResult_bits_meta_prefetch),
    .io_dirResult_bits_meta_prefetchSrc(i0_io_dirResult_bits_meta_prefetchSrc),
    .io_dirResult_bits_replacerInfo_channel(i0_io_dirResult_bits_replacerInfo_channel),
    .io_dirResult_bits_replacerInfo_reqSource(i0_io_dirResult_bits_replacerInfo_reqSource),
    .io_hitPfInMSHR_valid(i0_io_hitPfInMSHR_valid),
    .io_hitPfInMSHR_bits(i0_io_hitPfInMSHR_bits),
    .io_pfSent_valid(i0_io_pfSent_valid),
    .io_pfSent_bits(i0_io_pfSent_bits),
    .io_pfLateInMSHR_valid(i0_io_pfLateInMSHR_valid),
    .io_pfLateInMSHR_bits(i0_io_pfLateInMSHR_bits),
    .io_error_valid(i0_io_error_valid),
    .io_error_bits_valid(i0_io_error_bits_valid),
    .io_error_bits_address(i0_io_error_bits_address),
    .io_l2Miss(i0_io_l2Miss),
    .io_msStatus_0_valid(i0_io_msStatus_0_valid),
    .io_msStatus_0_bits_channel(i0_io_msStatus_0_bits_channel),
    .io_msStatus_0_bits_set(i0_io_msStatus_0_bits_set),
    .io_msStatus_0_bits_reqTag(i0_io_msStatus_0_bits_reqTag),
    .io_msStatus_0_bits_is_miss(i0_io_msStatus_0_bits_is_miss),
    .io_msStatus_0_bits_is_prefetch(i0_io_msStatus_0_bits_is_prefetch),
    .io_msStatus_1_valid(i0_io_msStatus_1_valid),
    .io_msStatus_1_bits_channel(i0_io_msStatus_1_bits_channel),
    .io_msStatus_1_bits_set(i0_io_msStatus_1_bits_set),
    .io_msStatus_1_bits_reqTag(i0_io_msStatus_1_bits_reqTag),
    .io_msStatus_1_bits_is_miss(i0_io_msStatus_1_bits_is_miss),
    .io_msStatus_1_bits_is_prefetch(i0_io_msStatus_1_bits_is_prefetch),
    .io_msStatus_2_valid(i0_io_msStatus_2_valid),
    .io_msStatus_2_bits_channel(i0_io_msStatus_2_bits_channel),
    .io_msStatus_2_bits_set(i0_io_msStatus_2_bits_set),
    .io_msStatus_2_bits_reqTag(i0_io_msStatus_2_bits_reqTag),
    .io_msStatus_2_bits_is_miss(i0_io_msStatus_2_bits_is_miss),
    .io_msStatus_2_bits_is_prefetch(i0_io_msStatus_2_bits_is_prefetch),
    .io_msStatus_3_valid(i0_io_msStatus_3_valid),
    .io_msStatus_3_bits_channel(i0_io_msStatus_3_bits_channel),
    .io_msStatus_3_bits_set(i0_io_msStatus_3_bits_set),
    .io_msStatus_3_bits_reqTag(i0_io_msStatus_3_bits_reqTag),
    .io_msStatus_3_bits_is_miss(i0_io_msStatus_3_bits_is_miss),
    .io_msStatus_3_bits_is_prefetch(i0_io_msStatus_3_bits_is_prefetch),
    .io_msStatus_4_valid(i0_io_msStatus_4_valid),
    .io_msStatus_4_bits_channel(i0_io_msStatus_4_bits_channel),
    .io_msStatus_4_bits_set(i0_io_msStatus_4_bits_set),
    .io_msStatus_4_bits_reqTag(i0_io_msStatus_4_bits_reqTag),
    .io_msStatus_4_bits_is_miss(i0_io_msStatus_4_bits_is_miss),
    .io_msStatus_4_bits_is_prefetch(i0_io_msStatus_4_bits_is_prefetch),
    .io_msStatus_5_valid(i0_io_msStatus_5_valid),
    .io_msStatus_5_bits_channel(i0_io_msStatus_5_bits_channel),
    .io_msStatus_5_bits_set(i0_io_msStatus_5_bits_set),
    .io_msStatus_5_bits_reqTag(i0_io_msStatus_5_bits_reqTag),
    .io_msStatus_5_bits_is_miss(i0_io_msStatus_5_bits_is_miss),
    .io_msStatus_5_bits_is_prefetch(i0_io_msStatus_5_bits_is_prefetch),
    .io_msStatus_6_valid(i0_io_msStatus_6_valid),
    .io_msStatus_6_bits_channel(i0_io_msStatus_6_bits_channel),
    .io_msStatus_6_bits_set(i0_io_msStatus_6_bits_set),
    .io_msStatus_6_bits_reqTag(i0_io_msStatus_6_bits_reqTag),
    .io_msStatus_6_bits_is_miss(i0_io_msStatus_6_bits_is_miss),
    .io_msStatus_6_bits_is_prefetch(i0_io_msStatus_6_bits_is_prefetch),
    .io_msStatus_7_valid(i0_io_msStatus_7_valid),
    .io_msStatus_7_bits_channel(i0_io_msStatus_7_bits_channel),
    .io_msStatus_7_bits_set(i0_io_msStatus_7_bits_set),
    .io_msStatus_7_bits_reqTag(i0_io_msStatus_7_bits_reqTag),
    .io_msStatus_7_bits_is_miss(i0_io_msStatus_7_bits_is_miss),
    .io_msStatus_7_bits_is_prefetch(i0_io_msStatus_7_bits_is_prefetch),
    .io_msStatus_8_valid(i0_io_msStatus_8_valid),
    .io_msStatus_8_bits_channel(i0_io_msStatus_8_bits_channel),
    .io_msStatus_8_bits_set(i0_io_msStatus_8_bits_set),
    .io_msStatus_8_bits_reqTag(i0_io_msStatus_8_bits_reqTag),
    .io_msStatus_8_bits_is_miss(i0_io_msStatus_8_bits_is_miss),
    .io_msStatus_8_bits_is_prefetch(i0_io_msStatus_8_bits_is_prefetch),
    .io_msStatus_9_valid(i0_io_msStatus_9_valid),
    .io_msStatus_9_bits_channel(i0_io_msStatus_9_bits_channel),
    .io_msStatus_9_bits_set(i0_io_msStatus_9_bits_set),
    .io_msStatus_9_bits_reqTag(i0_io_msStatus_9_bits_reqTag),
    .io_msStatus_9_bits_is_miss(i0_io_msStatus_9_bits_is_miss),
    .io_msStatus_9_bits_is_prefetch(i0_io_msStatus_9_bits_is_prefetch),
    .io_msStatus_10_valid(i0_io_msStatus_10_valid),
    .io_msStatus_10_bits_channel(i0_io_msStatus_10_bits_channel),
    .io_msStatus_10_bits_set(i0_io_msStatus_10_bits_set),
    .io_msStatus_10_bits_reqTag(i0_io_msStatus_10_bits_reqTag),
    .io_msStatus_10_bits_is_miss(i0_io_msStatus_10_bits_is_miss),
    .io_msStatus_10_bits_is_prefetch(i0_io_msStatus_10_bits_is_prefetch),
    .io_msStatus_11_valid(i0_io_msStatus_11_valid),
    .io_msStatus_11_bits_channel(i0_io_msStatus_11_bits_channel),
    .io_msStatus_11_bits_set(i0_io_msStatus_11_bits_set),
    .io_msStatus_11_bits_reqTag(i0_io_msStatus_11_bits_reqTag),
    .io_msStatus_11_bits_is_miss(i0_io_msStatus_11_bits_is_miss),
    .io_msStatus_11_bits_is_prefetch(i0_io_msStatus_11_bits_is_prefetch),
    .io_msStatus_12_valid(i0_io_msStatus_12_valid),
    .io_msStatus_12_bits_channel(i0_io_msStatus_12_bits_channel),
    .io_msStatus_12_bits_set(i0_io_msStatus_12_bits_set),
    .io_msStatus_12_bits_reqTag(i0_io_msStatus_12_bits_reqTag),
    .io_msStatus_12_bits_is_miss(i0_io_msStatus_12_bits_is_miss),
    .io_msStatus_12_bits_is_prefetch(i0_io_msStatus_12_bits_is_prefetch),
    .io_msStatus_13_valid(i0_io_msStatus_13_valid),
    .io_msStatus_13_bits_channel(i0_io_msStatus_13_bits_channel),
    .io_msStatus_13_bits_set(i0_io_msStatus_13_bits_set),
    .io_msStatus_13_bits_reqTag(i0_io_msStatus_13_bits_reqTag),
    .io_msStatus_13_bits_is_miss(i0_io_msStatus_13_bits_is_miss),
    .io_msStatus_13_bits_is_prefetch(i0_io_msStatus_13_bits_is_prefetch),
    .io_msStatus_14_valid(i0_io_msStatus_14_valid),
    .io_msStatus_14_bits_channel(i0_io_msStatus_14_bits_channel),
    .io_msStatus_14_bits_set(i0_io_msStatus_14_bits_set),
    .io_msStatus_14_bits_reqTag(i0_io_msStatus_14_bits_reqTag),
    .io_msStatus_14_bits_is_miss(i0_io_msStatus_14_bits_is_miss),
    .io_msStatus_14_bits_is_prefetch(i0_io_msStatus_14_bits_is_prefetch),
    .io_msStatus_15_valid(i0_io_msStatus_15_valid),
    .io_msStatus_15_bits_channel(i0_io_msStatus_15_bits_channel),
    .io_msStatus_15_bits_set(i0_io_msStatus_15_bits_set),
    .io_msStatus_15_bits_reqTag(i0_io_msStatus_15_bits_reqTag),
    .io_msStatus_15_bits_is_miss(i0_io_msStatus_15_bits_is_miss),
    .io_msStatus_15_bits_is_prefetch(i0_io_msStatus_15_bits_is_prefetch),
    .io_msAlloc_0_valid(i0_io_msAlloc_0_valid),
    .io_msAlloc_0_bits_channel(i0_io_msAlloc_0_bits_channel),
    .io_msAlloc_0_bits_is_miss(i0_io_msAlloc_0_bits_is_miss),
    .io_msAlloc_0_bits_is_prefetch(i0_io_msAlloc_0_bits_is_prefetch),
    .io_msAlloc_1_valid(i0_io_msAlloc_1_valid),
    .io_msAlloc_1_bits_channel(i0_io_msAlloc_1_bits_channel),
    .io_msAlloc_1_bits_is_miss(i0_io_msAlloc_1_bits_is_miss),
    .io_msAlloc_1_bits_is_prefetch(i0_io_msAlloc_1_bits_is_prefetch),
    .io_msAlloc_2_valid(i0_io_msAlloc_2_valid),
    .io_msAlloc_2_bits_channel(i0_io_msAlloc_2_bits_channel),
    .io_msAlloc_2_bits_is_miss(i0_io_msAlloc_2_bits_is_miss),
    .io_msAlloc_2_bits_is_prefetch(i0_io_msAlloc_2_bits_is_prefetch),
    .io_msAlloc_3_valid(i0_io_msAlloc_3_valid),
    .io_msAlloc_3_bits_channel(i0_io_msAlloc_3_bits_channel),
    .io_msAlloc_3_bits_is_miss(i0_io_msAlloc_3_bits_is_miss),
    .io_msAlloc_3_bits_is_prefetch(i0_io_msAlloc_3_bits_is_prefetch),
    .io_msAlloc_4_valid(i0_io_msAlloc_4_valid),
    .io_msAlloc_4_bits_channel(i0_io_msAlloc_4_bits_channel),
    .io_msAlloc_4_bits_is_miss(i0_io_msAlloc_4_bits_is_miss),
    .io_msAlloc_4_bits_is_prefetch(i0_io_msAlloc_4_bits_is_prefetch),
    .io_msAlloc_5_valid(i0_io_msAlloc_5_valid),
    .io_msAlloc_5_bits_channel(i0_io_msAlloc_5_bits_channel),
    .io_msAlloc_5_bits_is_miss(i0_io_msAlloc_5_bits_is_miss),
    .io_msAlloc_5_bits_is_prefetch(i0_io_msAlloc_5_bits_is_prefetch),
    .io_msAlloc_6_valid(i0_io_msAlloc_6_valid),
    .io_msAlloc_6_bits_channel(i0_io_msAlloc_6_bits_channel),
    .io_msAlloc_6_bits_is_miss(i0_io_msAlloc_6_bits_is_miss),
    .io_msAlloc_6_bits_is_prefetch(i0_io_msAlloc_6_bits_is_prefetch),
    .io_msAlloc_7_valid(i0_io_msAlloc_7_valid),
    .io_msAlloc_7_bits_channel(i0_io_msAlloc_7_bits_channel),
    .io_msAlloc_7_bits_is_miss(i0_io_msAlloc_7_bits_is_miss),
    .io_msAlloc_7_bits_is_prefetch(i0_io_msAlloc_7_bits_is_prefetch),
    .io_msAlloc_8_valid(i0_io_msAlloc_8_valid),
    .io_msAlloc_8_bits_channel(i0_io_msAlloc_8_bits_channel),
    .io_msAlloc_8_bits_is_miss(i0_io_msAlloc_8_bits_is_miss),
    .io_msAlloc_8_bits_is_prefetch(i0_io_msAlloc_8_bits_is_prefetch),
    .io_msAlloc_9_valid(i0_io_msAlloc_9_valid),
    .io_msAlloc_9_bits_channel(i0_io_msAlloc_9_bits_channel),
    .io_msAlloc_9_bits_is_miss(i0_io_msAlloc_9_bits_is_miss),
    .io_msAlloc_9_bits_is_prefetch(i0_io_msAlloc_9_bits_is_prefetch),
    .io_msAlloc_10_valid(i0_io_msAlloc_10_valid),
    .io_msAlloc_10_bits_channel(i0_io_msAlloc_10_bits_channel),
    .io_msAlloc_10_bits_is_miss(i0_io_msAlloc_10_bits_is_miss),
    .io_msAlloc_10_bits_is_prefetch(i0_io_msAlloc_10_bits_is_prefetch),
    .io_msAlloc_11_valid(i0_io_msAlloc_11_valid),
    .io_msAlloc_11_bits_channel(i0_io_msAlloc_11_bits_channel),
    .io_msAlloc_11_bits_is_miss(i0_io_msAlloc_11_bits_is_miss),
    .io_msAlloc_11_bits_is_prefetch(i0_io_msAlloc_11_bits_is_prefetch),
    .io_msAlloc_12_valid(i0_io_msAlloc_12_valid),
    .io_msAlloc_12_bits_channel(i0_io_msAlloc_12_bits_channel),
    .io_msAlloc_12_bits_is_miss(i0_io_msAlloc_12_bits_is_miss),
    .io_msAlloc_12_bits_is_prefetch(i0_io_msAlloc_12_bits_is_prefetch),
    .io_msAlloc_13_valid(i0_io_msAlloc_13_valid),
    .io_msAlloc_13_bits_channel(i0_io_msAlloc_13_bits_channel),
    .io_msAlloc_13_bits_is_miss(i0_io_msAlloc_13_bits_is_miss),
    .io_msAlloc_13_bits_is_prefetch(i0_io_msAlloc_13_bits_is_prefetch),
    .io_msAlloc_14_valid(i0_io_msAlloc_14_valid),
    .io_msAlloc_14_bits_channel(i0_io_msAlloc_14_bits_channel),
    .io_msAlloc_14_bits_is_miss(i0_io_msAlloc_14_bits_is_miss),
    .io_msAlloc_14_bits_is_prefetch(i0_io_msAlloc_14_bits_is_prefetch),
    .io_msAlloc_15_valid(i0_io_msAlloc_15_valid),
    .io_msAlloc_15_bits_channel(i0_io_msAlloc_15_bits_channel),
    .io_msAlloc_15_bits_is_miss(i0_io_msAlloc_15_bits_is_miss),
    .io_msAlloc_15_bits_is_prefetch(i0_io_msAlloc_15_bits_is_prefetch),
    .io_out_tx_req_ready(io_out_tx_req_ready),
    .io_out_tx_req_valid(i0_io_out_tx_req_valid),
    .io_out_tx_req_bits_qos(i0_io_out_tx_req_bits_qos),
    .io_out_tx_req_bits_txnID(i0_io_out_tx_req_bits_txnID),
    .io_out_tx_req_bits_returnNID(i0_io_out_tx_req_bits_returnNID),
    .io_out_tx_req_bits_stashNIDValid(i0_io_out_tx_req_bits_stashNIDValid),
    .io_out_tx_req_bits_returnTxnID(i0_io_out_tx_req_bits_returnTxnID),
    .io_out_tx_req_bits_opcode(i0_io_out_tx_req_bits_opcode),
    .io_out_tx_req_bits_addr(i0_io_out_tx_req_bits_addr),
    .io_out_tx_req_bits_ns(i0_io_out_tx_req_bits_ns),
    .io_out_tx_req_bits_likelyshared(i0_io_out_tx_req_bits_likelyshared),
    .io_out_tx_req_bits_allowRetry(i0_io_out_tx_req_bits_allowRetry),
    .io_out_tx_req_bits_order(i0_io_out_tx_req_bits_order),
    .io_out_tx_req_bits_pCrdType(i0_io_out_tx_req_bits_pCrdType),
    .io_out_tx_req_bits_memAttr_allocate(i0_io_out_tx_req_bits_memAttr_allocate),
    .io_out_tx_req_bits_memAttr_cacheable(i0_io_out_tx_req_bits_memAttr_cacheable),
    .io_out_tx_req_bits_memAttr_device(i0_io_out_tx_req_bits_memAttr_device),
    .io_out_tx_req_bits_memAttr_ewa(i0_io_out_tx_req_bits_memAttr_ewa),
    .io_out_tx_req_bits_snpAttr(i0_io_out_tx_req_bits_snpAttr),
    .io_out_tx_req_bits_lpIDWithPadding(i0_io_out_tx_req_bits_lpIDWithPadding),
    .io_out_tx_req_bits_snoopMe(i0_io_out_tx_req_bits_snoopMe),
    .io_out_tx_req_bits_expCompAck(i0_io_out_tx_req_bits_expCompAck),
    .io_out_tx_req_bits_tagOp(i0_io_out_tx_req_bits_tagOp),
    .io_out_tx_req_bits_traceTag(i0_io_out_tx_req_bits_traceTag),
    .io_out_tx_req_bits_mpam_perfMonGroup(i0_io_out_tx_req_bits_mpam_perfMonGroup),
    .io_out_tx_req_bits_mpam_partID(i0_io_out_tx_req_bits_mpam_partID),
    .io_out_tx_req_bits_mpam_mpamNS(i0_io_out_tx_req_bits_mpam_mpamNS),
    .io_out_tx_req_bits_rsvdc(i0_io_out_tx_req_bits_rsvdc),
    .io_out_tx_rsp_ready(io_out_tx_rsp_ready),
    .io_out_tx_rsp_valid(i0_io_out_tx_rsp_valid),
    .io_out_tx_rsp_bits_qos(i0_io_out_tx_rsp_bits_qos),
    .io_out_tx_rsp_bits_tgtID(i0_io_out_tx_rsp_bits_tgtID),
    .io_out_tx_rsp_bits_txnID(i0_io_out_tx_rsp_bits_txnID),
    .io_out_tx_rsp_bits_opcode(i0_io_out_tx_rsp_bits_opcode),
    .io_out_tx_rsp_bits_respErr(i0_io_out_tx_rsp_bits_respErr),
    .io_out_tx_rsp_bits_resp(i0_io_out_tx_rsp_bits_resp),
    .io_out_tx_rsp_bits_fwdState(i0_io_out_tx_rsp_bits_fwdState),
    .io_out_tx_rsp_bits_cBusy(i0_io_out_tx_rsp_bits_cBusy),
    .io_out_tx_rsp_bits_dbID(i0_io_out_tx_rsp_bits_dbID),
    .io_out_tx_rsp_bits_pCrdType(i0_io_out_tx_rsp_bits_pCrdType),
    .io_out_tx_rsp_bits_tagOp(i0_io_out_tx_rsp_bits_tagOp),
    .io_out_tx_rsp_bits_traceTag(i0_io_out_tx_rsp_bits_traceTag),
    .io_out_tx_dat_ready(io_out_tx_dat_ready),
    .io_out_tx_dat_valid(i0_io_out_tx_dat_valid),
    .io_out_tx_dat_bits_tgtID(i0_io_out_tx_dat_bits_tgtID),
    .io_out_tx_dat_bits_txnID(i0_io_out_tx_dat_bits_txnID),
    .io_out_tx_dat_bits_homeNID(i0_io_out_tx_dat_bits_homeNID),
    .io_out_tx_dat_bits_opcode(i0_io_out_tx_dat_bits_opcode),
    .io_out_tx_dat_bits_respErr(i0_io_out_tx_dat_bits_respErr),
    .io_out_tx_dat_bits_resp(i0_io_out_tx_dat_bits_resp),
    .io_out_tx_dat_bits_dataSource(i0_io_out_tx_dat_bits_dataSource),
    .io_out_tx_dat_bits_dbID(i0_io_out_tx_dat_bits_dbID),
    .io_out_tx_dat_bits_ccID(i0_io_out_tx_dat_bits_ccID),
    .io_out_tx_dat_bits_dataID(i0_io_out_tx_dat_bits_dataID),
    .io_out_tx_dat_bits_traceTag(i0_io_out_tx_dat_bits_traceTag),
    .io_out_tx_dat_bits_be(i0_io_out_tx_dat_bits_be),
    .io_out_tx_dat_bits_data(i0_io_out_tx_dat_bits_data),
    .io_out_tx_dat_bits_dataCheck(i0_io_out_tx_dat_bits_dataCheck),
    .io_out_tx_dat_bits_poison(i0_io_out_tx_dat_bits_poison),
    .io_out_rx_rsp_valid(io_out_rx_rsp_valid),
    .io_out_rx_rsp_bits_srcID(io_out_rx_rsp_bits_srcID),
    .io_out_rx_rsp_bits_txnID(io_out_rx_rsp_bits_txnID),
    .io_out_rx_rsp_bits_opcode(io_out_rx_rsp_bits_opcode),
    .io_out_rx_rsp_bits_respErr(io_out_rx_rsp_bits_respErr),
    .io_out_rx_rsp_bits_resp(io_out_rx_rsp_bits_resp),
    .io_out_rx_rsp_bits_dbID(io_out_rx_rsp_bits_dbID),
    .io_out_rx_rsp_bits_pCrdType(io_out_rx_rsp_bits_pCrdType),
    .io_out_rx_rsp_bits_traceTag(io_out_rx_rsp_bits_traceTag),
    .io_out_rx_dat_valid(io_out_rx_dat_valid),
    .io_out_rx_dat_bits_txnID(io_out_rx_dat_bits_txnID),
    .io_out_rx_dat_bits_homeNID(io_out_rx_dat_bits_homeNID),
    .io_out_rx_dat_bits_opcode(io_out_rx_dat_bits_opcode),
    .io_out_rx_dat_bits_respErr(io_out_rx_dat_bits_respErr),
    .io_out_rx_dat_bits_resp(io_out_rx_dat_bits_resp),
    .io_out_rx_dat_bits_dbID(io_out_rx_dat_bits_dbID),
    .io_out_rx_dat_bits_dataID(io_out_rx_dat_bits_dataID),
    .io_out_rx_dat_bits_traceTag(io_out_rx_dat_bits_traceTag),
    .io_out_rx_dat_bits_data(io_out_rx_dat_bits_data),
    .io_out_rx_dat_bits_dataCheck(io_out_rx_dat_bits_dataCheck),
    .io_out_rx_dat_bits_poison(io_out_rx_dat_bits_poison),
    .io_out_rx_snp_ready(i0_io_out_rx_snp_ready),
    .io_out_rx_snp_valid(io_out_rx_snp_valid),
    .io_out_rx_snp_bits_qos(io_out_rx_snp_bits_qos),
    .io_out_rx_snp_bits_srcID(io_out_rx_snp_bits_srcID),
    .io_out_rx_snp_bits_txnID(io_out_rx_snp_bits_txnID),
    .io_out_rx_snp_bits_fwdNID(io_out_rx_snp_bits_fwdNID),
    .io_out_rx_snp_bits_fwdTxnID(io_out_rx_snp_bits_fwdTxnID),
    .io_out_rx_snp_bits_opcode(io_out_rx_snp_bits_opcode),
    .io_out_rx_snp_bits_addr(io_out_rx_snp_bits_addr),
    .io_out_rx_snp_bits_ns(io_out_rx_snp_bits_ns),
    .io_out_rx_snp_bits_doNotGoToSD(io_out_rx_snp_bits_doNotGoToSD),
    .io_out_rx_snp_bits_retToSrc(io_out_rx_snp_bits_retToSrc),
    .io_out_rx_snp_bits_traceTag(io_out_rx_snp_bits_traceTag),
    .io_out_rx_snp_bits_mpam_perfMonGroup(io_out_rx_snp_bits_mpam_perfMonGroup),
    .io_out_rx_snp_bits_mpam_partID(io_out_rx_snp_bits_mpam_partID),
    .io_out_rx_snp_bits_mpam_mpamNS(io_out_rx_snp_bits_mpam_mpamNS),
    .io_pCrd_0_query_valid(i0_io_pCrd_0_query_valid),
    .io_pCrd_0_query_bits_pCrdType(i0_io_pCrd_0_query_bits_pCrdType),
    .io_pCrd_0_query_bits_srcID(i0_io_pCrd_0_query_bits_srcID),
    .io_pCrd_0_grant(io_pCrd_0_grant),
    .io_pCrd_1_query_valid(i0_io_pCrd_1_query_valid),
    .io_pCrd_1_query_bits_pCrdType(i0_io_pCrd_1_query_bits_pCrdType),
    .io_pCrd_1_query_bits_srcID(i0_io_pCrd_1_query_bits_srcID),
    .io_pCrd_1_grant(io_pCrd_1_grant),
    .io_pCrd_2_query_valid(i0_io_pCrd_2_query_valid),
    .io_pCrd_2_query_bits_pCrdType(i0_io_pCrd_2_query_bits_pCrdType),
    .io_pCrd_2_query_bits_srcID(i0_io_pCrd_2_query_bits_srcID),
    .io_pCrd_2_grant(io_pCrd_2_grant),
    .io_pCrd_3_query_valid(i0_io_pCrd_3_query_valid),
    .io_pCrd_3_query_bits_pCrdType(i0_io_pCrd_3_query_bits_pCrdType),
    .io_pCrd_3_query_bits_srcID(i0_io_pCrd_3_query_bits_srcID),
    .io_pCrd_3_grant(io_pCrd_3_grant),
    .io_pCrd_4_query_valid(i0_io_pCrd_4_query_valid),
    .io_pCrd_4_query_bits_pCrdType(i0_io_pCrd_4_query_bits_pCrdType),
    .io_pCrd_4_query_bits_srcID(i0_io_pCrd_4_query_bits_srcID),
    .io_pCrd_4_grant(io_pCrd_4_grant),
    .io_pCrd_5_query_valid(i0_io_pCrd_5_query_valid),
    .io_pCrd_5_query_bits_pCrdType(i0_io_pCrd_5_query_bits_pCrdType),
    .io_pCrd_5_query_bits_srcID(i0_io_pCrd_5_query_bits_srcID),
    .io_pCrd_5_grant(io_pCrd_5_grant),
    .io_pCrd_6_query_valid(i0_io_pCrd_6_query_valid),
    .io_pCrd_6_query_bits_pCrdType(i0_io_pCrd_6_query_bits_pCrdType),
    .io_pCrd_6_query_bits_srcID(i0_io_pCrd_6_query_bits_srcID),
    .io_pCrd_6_grant(io_pCrd_6_grant),
    .io_pCrd_7_query_valid(i0_io_pCrd_7_query_valid),
    .io_pCrd_7_query_bits_pCrdType(i0_io_pCrd_7_query_bits_pCrdType),
    .io_pCrd_7_query_bits_srcID(i0_io_pCrd_7_query_bits_srcID),
    .io_pCrd_7_grant(io_pCrd_7_grant),
    .io_pCrd_8_query_valid(i0_io_pCrd_8_query_valid),
    .io_pCrd_8_query_bits_pCrdType(i0_io_pCrd_8_query_bits_pCrdType),
    .io_pCrd_8_query_bits_srcID(i0_io_pCrd_8_query_bits_srcID),
    .io_pCrd_8_grant(io_pCrd_8_grant),
    .io_pCrd_9_query_valid(i0_io_pCrd_9_query_valid),
    .io_pCrd_9_query_bits_pCrdType(i0_io_pCrd_9_query_bits_pCrdType),
    .io_pCrd_9_query_bits_srcID(i0_io_pCrd_9_query_bits_srcID),
    .io_pCrd_9_grant(io_pCrd_9_grant),
    .io_pCrd_10_query_valid(i0_io_pCrd_10_query_valid),
    .io_pCrd_10_query_bits_pCrdType(i0_io_pCrd_10_query_bits_pCrdType),
    .io_pCrd_10_query_bits_srcID(i0_io_pCrd_10_query_bits_srcID),
    .io_pCrd_10_grant(io_pCrd_10_grant),
    .io_pCrd_11_query_valid(i0_io_pCrd_11_query_valid),
    .io_pCrd_11_query_bits_pCrdType(i0_io_pCrd_11_query_bits_pCrdType),
    .io_pCrd_11_query_bits_srcID(i0_io_pCrd_11_query_bits_srcID),
    .io_pCrd_11_grant(io_pCrd_11_grant),
    .io_pCrd_12_query_valid(i0_io_pCrd_12_query_valid),
    .io_pCrd_12_query_bits_pCrdType(i0_io_pCrd_12_query_bits_pCrdType),
    .io_pCrd_12_query_bits_srcID(i0_io_pCrd_12_query_bits_srcID),
    .io_pCrd_12_grant(io_pCrd_12_grant),
    .io_pCrd_13_query_valid(i0_io_pCrd_13_query_valid),
    .io_pCrd_13_query_bits_pCrdType(i0_io_pCrd_13_query_bits_pCrdType),
    .io_pCrd_13_query_bits_srcID(i0_io_pCrd_13_query_bits_srcID),
    .io_pCrd_13_grant(io_pCrd_13_grant),
    .io_pCrd_14_query_valid(i0_io_pCrd_14_query_valid),
    .io_pCrd_14_query_bits_pCrdType(i0_io_pCrd_14_query_bits_pCrdType),
    .io_pCrd_14_query_bits_srcID(i0_io_pCrd_14_query_bits_srcID),
    .io_pCrd_14_grant(io_pCrd_14_grant),
    .io_pCrd_15_query_valid(i0_io_pCrd_15_query_valid),
    .io_pCrd_15_query_bits_pCrdType(i0_io_pCrd_15_query_bits_pCrdType),
    .io_pCrd_15_query_bits_srcID(i0_io_pCrd_15_query_bits_srcID),
    .io_pCrd_15_grant(io_pCrd_15_grant),
    .io_perf_0_value(i0_io_perf_0_value),
    .io_perf_1_value(i0_io_perf_1_value),
    .io_perf_3_value(i0_io_perf_3_value),
    .io_perf_4_value(i0_io_perf_4_value),
    .io_perf_5_value(i0_io_perf_5_value),
    .io_perf_6_value(i0_io_perf_6_value),
    .io_perf_7_value(i0_io_perf_7_value),
    .io_perf_8_value(i0_io_perf_8_value),
    .io_perf_9_value(i0_io_perf_9_value),
    .io_perf_10_value(i0_io_perf_10_value),
    .io_perf_11_value(i0_io_perf_11_value),
    .io_perf_12_value(i0_io_perf_12_value),
    .io_perf_13_value(i0_io_perf_13_value),
    .io_perf_14_value(i0_io_perf_14_value),
    .io_perf_15_value(i0_io_perf_15_value),
    .io_perf_16_value(i0_io_perf_16_value),
    .sigFromSrams_bore_ram_hold(sigFromSrams_bore_ram_hold),
    .sigFromSrams_bore_ram_bypass(sigFromSrams_bore_ram_bypass),
    .sigFromSrams_bore_ram_bp_clken(sigFromSrams_bore_ram_bp_clken),
    .sigFromSrams_bore_ram_aux_clk(sigFromSrams_bore_ram_aux_clk),
    .sigFromSrams_bore_ram_aux_ckbp(sigFromSrams_bore_ram_aux_ckbp),
    .sigFromSrams_bore_ram_mcp_hold(sigFromSrams_bore_ram_mcp_hold),
    .sigFromSrams_bore_cgen(sigFromSrams_bore_cgen),
    .sigFromSrams_bore_1_ram_hold(sigFromSrams_bore_1_ram_hold),
    .sigFromSrams_bore_1_ram_bypass(sigFromSrams_bore_1_ram_bypass),
    .sigFromSrams_bore_1_ram_bp_clken(sigFromSrams_bore_1_ram_bp_clken),
    .sigFromSrams_bore_1_ram_aux_clk(sigFromSrams_bore_1_ram_aux_clk),
    .sigFromSrams_bore_1_ram_aux_ckbp(sigFromSrams_bore_1_ram_aux_ckbp),
    .sigFromSrams_bore_1_ram_mcp_hold(sigFromSrams_bore_1_ram_mcp_hold),
    .sigFromSrams_bore_1_cgen(sigFromSrams_bore_1_cgen),
    .sigFromSrams_bore_2_ram_hold(sigFromSrams_bore_2_ram_hold),
    .sigFromSrams_bore_2_ram_bypass(sigFromSrams_bore_2_ram_bypass),
    .sigFromSrams_bore_2_ram_bp_clken(sigFromSrams_bore_2_ram_bp_clken),
    .sigFromSrams_bore_2_ram_aux_clk(sigFromSrams_bore_2_ram_aux_clk),
    .sigFromSrams_bore_2_ram_aux_ckbp(sigFromSrams_bore_2_ram_aux_ckbp),
    .sigFromSrams_bore_2_ram_mcp_hold(sigFromSrams_bore_2_ram_mcp_hold),
    .sigFromSrams_bore_2_cgen(sigFromSrams_bore_2_cgen),
    .sigFromSrams_bore_3_ram_hold(sigFromSrams_bore_3_ram_hold),
    .sigFromSrams_bore_3_ram_bypass(sigFromSrams_bore_3_ram_bypass),
    .sigFromSrams_bore_3_ram_bp_clken(sigFromSrams_bore_3_ram_bp_clken),
    .sigFromSrams_bore_3_ram_aux_clk(sigFromSrams_bore_3_ram_aux_clk),
    .sigFromSrams_bore_3_ram_aux_ckbp(sigFromSrams_bore_3_ram_aux_ckbp),
    .sigFromSrams_bore_3_ram_mcp_hold(sigFromSrams_bore_3_ram_mcp_hold),
    .sigFromSrams_bore_3_cgen(sigFromSrams_bore_3_cgen),
    .sigFromSrams_bore_4_ram_hold(sigFromSrams_bore_4_ram_hold),
    .sigFromSrams_bore_4_ram_bypass(sigFromSrams_bore_4_ram_bypass),
    .sigFromSrams_bore_4_ram_bp_clken(sigFromSrams_bore_4_ram_bp_clken),
    .sigFromSrams_bore_4_ram_aux_clk(sigFromSrams_bore_4_ram_aux_clk),
    .sigFromSrams_bore_4_ram_aux_ckbp(sigFromSrams_bore_4_ram_aux_ckbp),
    .sigFromSrams_bore_4_ram_mcp_hold(sigFromSrams_bore_4_ram_mcp_hold),
    .sigFromSrams_bore_4_cgen(sigFromSrams_bore_4_cgen),
    .sigFromSrams_bore_5_ram_hold(sigFromSrams_bore_5_ram_hold),
    .sigFromSrams_bore_5_ram_bypass(sigFromSrams_bore_5_ram_bypass),
    .sigFromSrams_bore_5_ram_bp_clken(sigFromSrams_bore_5_ram_bp_clken),
    .sigFromSrams_bore_5_ram_aux_clk(sigFromSrams_bore_5_ram_aux_clk),
    .sigFromSrams_bore_5_ram_aux_ckbp(sigFromSrams_bore_5_ram_aux_ckbp),
    .sigFromSrams_bore_5_ram_mcp_hold(sigFromSrams_bore_5_ram_mcp_hold),
    .sigFromSrams_bore_5_cgen(sigFromSrams_bore_5_cgen),
    .sigFromSrams_bore_6_ram_hold(sigFromSrams_bore_6_ram_hold),
    .sigFromSrams_bore_6_ram_bypass(sigFromSrams_bore_6_ram_bypass),
    .sigFromSrams_bore_6_ram_bp_clken(sigFromSrams_bore_6_ram_bp_clken),
    .sigFromSrams_bore_6_ram_aux_clk(sigFromSrams_bore_6_ram_aux_clk),
    .sigFromSrams_bore_6_ram_aux_ckbp(sigFromSrams_bore_6_ram_aux_ckbp),
    .sigFromSrams_bore_6_ram_mcp_hold(sigFromSrams_bore_6_ram_mcp_hold),
    .sigFromSrams_bore_6_cgen(sigFromSrams_bore_6_cgen),
    .sigFromSrams_bore_7_ram_hold(sigFromSrams_bore_7_ram_hold),
    .sigFromSrams_bore_7_ram_bypass(sigFromSrams_bore_7_ram_bypass),
    .sigFromSrams_bore_7_ram_bp_clken(sigFromSrams_bore_7_ram_bp_clken),
    .sigFromSrams_bore_7_ram_aux_clk(sigFromSrams_bore_7_ram_aux_clk),
    .sigFromSrams_bore_7_ram_aux_ckbp(sigFromSrams_bore_7_ram_aux_ckbp),
    .sigFromSrams_bore_7_ram_mcp_hold(sigFromSrams_bore_7_ram_mcp_hold),
    .sigFromSrams_bore_7_cgen(sigFromSrams_bore_7_cgen),
    .sigFromSrams_bore_8_ram_hold(sigFromSrams_bore_8_ram_hold),
    .sigFromSrams_bore_8_ram_bypass(sigFromSrams_bore_8_ram_bypass),
    .sigFromSrams_bore_8_ram_bp_clken(sigFromSrams_bore_8_ram_bp_clken),
    .sigFromSrams_bore_8_ram_aux_clk(sigFromSrams_bore_8_ram_aux_clk),
    .sigFromSrams_bore_8_ram_aux_ckbp(sigFromSrams_bore_8_ram_aux_ckbp),
    .sigFromSrams_bore_8_ram_mcp_hold(sigFromSrams_bore_8_ram_mcp_hold),
    .sigFromSrams_bore_8_cgen(sigFromSrams_bore_8_cgen),
    .sigFromSrams_bore_9_ram_hold(sigFromSrams_bore_9_ram_hold),
    .sigFromSrams_bore_9_ram_bypass(sigFromSrams_bore_9_ram_bypass),
    .sigFromSrams_bore_9_ram_bp_clken(sigFromSrams_bore_9_ram_bp_clken),
    .sigFromSrams_bore_9_ram_aux_clk(sigFromSrams_bore_9_ram_aux_clk),
    .sigFromSrams_bore_9_ram_aux_ckbp(sigFromSrams_bore_9_ram_aux_ckbp),
    .sigFromSrams_bore_9_ram_mcp_hold(sigFromSrams_bore_9_ram_mcp_hold),
    .sigFromSrams_bore_9_cgen(sigFromSrams_bore_9_cgen),
    .sigFromSrams_bore_10_ram_hold(sigFromSrams_bore_10_ram_hold),
    .sigFromSrams_bore_10_ram_bypass(sigFromSrams_bore_10_ram_bypass),
    .sigFromSrams_bore_10_ram_bp_clken(sigFromSrams_bore_10_ram_bp_clken),
    .sigFromSrams_bore_10_ram_aux_clk(sigFromSrams_bore_10_ram_aux_clk),
    .sigFromSrams_bore_10_ram_aux_ckbp(sigFromSrams_bore_10_ram_aux_ckbp),
    .sigFromSrams_bore_10_ram_mcp_hold(sigFromSrams_bore_10_ram_mcp_hold),
    .sigFromSrams_bore_10_cgen(sigFromSrams_bore_10_cgen),
    .boreChildrenBd_bore_array(4'(boreChildrenBd_bore_array)),
    .boreChildrenBd_bore_all(boreChildrenBd_bore_all),
    .boreChildrenBd_bore_req(boreChildrenBd_bore_req),
    .boreChildrenBd_bore_ack(i0_boreChildrenBd_bore_ack),
    .boreChildrenBd_bore_writeen(boreChildrenBd_bore_writeen),
    .boreChildrenBd_bore_be(boreChildrenBd_bore_be),
    .boreChildrenBd_bore_addr(boreChildrenBd_bore_addr),
    .boreChildrenBd_bore_indata(boreChildrenBd_bore_indata),
    .boreChildrenBd_bore_readen(boreChildrenBd_bore_readen),
    .boreChildrenBd_bore_addr_rd(boreChildrenBd_bore_addr_rd),
    .boreChildrenBd_bore_outdata(i0_boreChildrenBd_bore_outdata)
  );
  Slice_1 u_g1 (
    .clock(clock),
    .reset(reset),
    .io_in_a_ready(g1_io_in_a_ready),
    .io_in_a_valid(io_in_a_valid),
    .io_in_a_bits_opcode(io_in_a_bits_opcode),
    .io_in_a_bits_param(io_in_a_bits_param),
    .io_in_a_bits_size(io_in_a_bits_size),
    .io_in_a_bits_source(io_in_a_bits_source),
    .io_in_a_bits_address(io_in_a_bits_address),
    .io_in_a_bits_user_reqSource(io_in_a_bits_user_reqSource),
    .io_in_a_bits_user_alias(io_in_a_bits_user_alias),
    .io_in_a_bits_user_vaddr(io_in_a_bits_user_vaddr),
    .io_in_a_bits_user_needHint(io_in_a_bits_user_needHint),
    .io_in_a_bits_echo_isKeyword(io_in_a_bits_echo_isKeyword),
    .io_in_a_bits_corrupt(io_in_a_bits_corrupt),
    .io_in_b_ready(io_in_b_ready),
    .io_in_b_valid(g1_io_in_b_valid),
    .io_in_b_bits_opcode(g1_io_in_b_bits_opcode),
    .io_in_b_bits_param(g1_io_in_b_bits_param),
    .io_in_b_bits_address(g1_io_in_b_bits_address),
    .io_in_b_bits_data(g1_io_in_b_bits_data),
    .io_in_c_ready(g1_io_in_c_ready),
    .io_in_c_valid(io_in_c_valid),
    .io_in_c_bits_opcode(io_in_c_bits_opcode),
    .io_in_c_bits_param(io_in_c_bits_param),
    .io_in_c_bits_size(io_in_c_bits_size),
    .io_in_c_bits_source(io_in_c_bits_source),
    .io_in_c_bits_address(io_in_c_bits_address),
    .io_in_c_bits_data(io_in_c_bits_data),
    .io_in_c_bits_corrupt(io_in_c_bits_corrupt),
    .io_in_d_ready(io_in_d_ready),
    .io_in_d_valid(g1_io_in_d_valid),
    .io_in_d_bits_opcode(g1_io_in_d_bits_opcode),
    .io_in_d_bits_param(g1_io_in_d_bits_param),
    .io_in_d_bits_source(g1_io_in_d_bits_source),
    .io_in_d_bits_sink(g1_io_in_d_bits_sink),
    .io_in_d_bits_denied(g1_io_in_d_bits_denied),
    .io_in_d_bits_echo_isKeyword(g1_io_in_d_bits_echo_isKeyword),
    .io_in_d_bits_data(g1_io_in_d_bits_data),
    .io_in_d_bits_corrupt(g1_io_in_d_bits_corrupt),
    .io_in_e_valid(io_in_e_valid),
    .io_in_e_bits_sink(io_in_e_bits_sink),
    .io_l1Hint_ready(io_l1Hint_ready),
    .io_l1Hint_valid(g1_io_l1Hint_valid),
    .io_l1Hint_bits_sourceId(g1_io_l1Hint_bits_sourceId),
    .io_l1Hint_bits_isKeyword(g1_io_l1Hint_bits_isKeyword),
    .io_prefetch_train_ready(io_prefetch_train_ready),
    .io_prefetch_train_valid(g1_io_prefetch_train_valid),
    .io_prefetch_train_bits_tag(g1_io_prefetch_train_bits_tag),
    .io_prefetch_train_bits_set(g1_io_prefetch_train_bits_set),
    .io_prefetch_train_bits_needT(g1_io_prefetch_train_bits_needT),
    .io_prefetch_train_bits_source(g1_io_prefetch_train_bits_source),
    .io_prefetch_train_bits_vaddr(g1_io_prefetch_train_bits_vaddr),
    .io_prefetch_train_bits_hit(g1_io_prefetch_train_bits_hit),
    .io_prefetch_train_bits_prefetched(g1_io_prefetch_train_bits_prefetched),
    .io_prefetch_train_bits_pfsource(g1_io_prefetch_train_bits_pfsource),
    .io_prefetch_train_bits_reqsource(g1_io_prefetch_train_bits_reqsource),
    .io_prefetch_req_ready(g1_io_prefetch_req_ready),
    .io_prefetch_req_valid(io_prefetch_req_valid),
    .io_prefetch_req_bits_tag(io_prefetch_req_bits_tag),
    .io_prefetch_req_bits_set(io_prefetch_req_bits_set),
    .io_prefetch_req_bits_vaddr(io_prefetch_req_bits_vaddr),
    .io_prefetch_req_bits_needT(io_prefetch_req_bits_needT),
    .io_prefetch_req_bits_source(io_prefetch_req_bits_source),
    .io_prefetch_req_bits_pfSource(io_prefetch_req_bits_pfSource),
    .io_prefetch_resp_ready(io_prefetch_resp_ready),
    .io_prefetch_resp_valid(g1_io_prefetch_resp_valid),
    .io_prefetch_resp_bits_tag(g1_io_prefetch_resp_bits_tag),
    .io_prefetch_resp_bits_set(g1_io_prefetch_resp_bits_set),
    .io_prefetch_resp_bits_vaddr(g1_io_prefetch_resp_bits_vaddr),
    .io_prefetch_resp_bits_pfSource(g1_io_prefetch_resp_bits_pfSource),
    .io_dirResult_valid(g1_io_dirResult_valid),
    .io_dirResult_bits_hit(g1_io_dirResult_bits_hit),
    .io_dirResult_bits_meta_prefetch(g1_io_dirResult_bits_meta_prefetch),
    .io_dirResult_bits_meta_prefetchSrc(g1_io_dirResult_bits_meta_prefetchSrc),
    .io_dirResult_bits_replacerInfo_channel(g1_io_dirResult_bits_replacerInfo_channel),
    .io_dirResult_bits_replacerInfo_reqSource(g1_io_dirResult_bits_replacerInfo_reqSource),
    .io_hitPfInMSHR_valid(g1_io_hitPfInMSHR_valid),
    .io_hitPfInMSHR_bits(g1_io_hitPfInMSHR_bits),
    .io_pfSent_valid(g1_io_pfSent_valid),
    .io_pfSent_bits(g1_io_pfSent_bits),
    .io_pfLateInMSHR_valid(g1_io_pfLateInMSHR_valid),
    .io_pfLateInMSHR_bits(g1_io_pfLateInMSHR_bits),
    .io_error_valid(g1_io_error_valid),
    .io_error_bits_valid(g1_io_error_bits_valid),
    .io_error_bits_address(g1_io_error_bits_address),
    .io_l2Miss(g1_io_l2Miss),
    .io_msStatus_0_valid(g1_io_msStatus_0_valid),
    .io_msStatus_0_bits_channel(g1_io_msStatus_0_bits_channel),
    .io_msStatus_0_bits_set(g1_io_msStatus_0_bits_set),
    .io_msStatus_0_bits_reqTag(g1_io_msStatus_0_bits_reqTag),
    .io_msStatus_0_bits_is_miss(g1_io_msStatus_0_bits_is_miss),
    .io_msStatus_0_bits_is_prefetch(g1_io_msStatus_0_bits_is_prefetch),
    .io_msStatus_1_valid(g1_io_msStatus_1_valid),
    .io_msStatus_1_bits_channel(g1_io_msStatus_1_bits_channel),
    .io_msStatus_1_bits_set(g1_io_msStatus_1_bits_set),
    .io_msStatus_1_bits_reqTag(g1_io_msStatus_1_bits_reqTag),
    .io_msStatus_1_bits_is_miss(g1_io_msStatus_1_bits_is_miss),
    .io_msStatus_1_bits_is_prefetch(g1_io_msStatus_1_bits_is_prefetch),
    .io_msStatus_2_valid(g1_io_msStatus_2_valid),
    .io_msStatus_2_bits_channel(g1_io_msStatus_2_bits_channel),
    .io_msStatus_2_bits_set(g1_io_msStatus_2_bits_set),
    .io_msStatus_2_bits_reqTag(g1_io_msStatus_2_bits_reqTag),
    .io_msStatus_2_bits_is_miss(g1_io_msStatus_2_bits_is_miss),
    .io_msStatus_2_bits_is_prefetch(g1_io_msStatus_2_bits_is_prefetch),
    .io_msStatus_3_valid(g1_io_msStatus_3_valid),
    .io_msStatus_3_bits_channel(g1_io_msStatus_3_bits_channel),
    .io_msStatus_3_bits_set(g1_io_msStatus_3_bits_set),
    .io_msStatus_3_bits_reqTag(g1_io_msStatus_3_bits_reqTag),
    .io_msStatus_3_bits_is_miss(g1_io_msStatus_3_bits_is_miss),
    .io_msStatus_3_bits_is_prefetch(g1_io_msStatus_3_bits_is_prefetch),
    .io_msStatus_4_valid(g1_io_msStatus_4_valid),
    .io_msStatus_4_bits_channel(g1_io_msStatus_4_bits_channel),
    .io_msStatus_4_bits_set(g1_io_msStatus_4_bits_set),
    .io_msStatus_4_bits_reqTag(g1_io_msStatus_4_bits_reqTag),
    .io_msStatus_4_bits_is_miss(g1_io_msStatus_4_bits_is_miss),
    .io_msStatus_4_bits_is_prefetch(g1_io_msStatus_4_bits_is_prefetch),
    .io_msStatus_5_valid(g1_io_msStatus_5_valid),
    .io_msStatus_5_bits_channel(g1_io_msStatus_5_bits_channel),
    .io_msStatus_5_bits_set(g1_io_msStatus_5_bits_set),
    .io_msStatus_5_bits_reqTag(g1_io_msStatus_5_bits_reqTag),
    .io_msStatus_5_bits_is_miss(g1_io_msStatus_5_bits_is_miss),
    .io_msStatus_5_bits_is_prefetch(g1_io_msStatus_5_bits_is_prefetch),
    .io_msStatus_6_valid(g1_io_msStatus_6_valid),
    .io_msStatus_6_bits_channel(g1_io_msStatus_6_bits_channel),
    .io_msStatus_6_bits_set(g1_io_msStatus_6_bits_set),
    .io_msStatus_6_bits_reqTag(g1_io_msStatus_6_bits_reqTag),
    .io_msStatus_6_bits_is_miss(g1_io_msStatus_6_bits_is_miss),
    .io_msStatus_6_bits_is_prefetch(g1_io_msStatus_6_bits_is_prefetch),
    .io_msStatus_7_valid(g1_io_msStatus_7_valid),
    .io_msStatus_7_bits_channel(g1_io_msStatus_7_bits_channel),
    .io_msStatus_7_bits_set(g1_io_msStatus_7_bits_set),
    .io_msStatus_7_bits_reqTag(g1_io_msStatus_7_bits_reqTag),
    .io_msStatus_7_bits_is_miss(g1_io_msStatus_7_bits_is_miss),
    .io_msStatus_7_bits_is_prefetch(g1_io_msStatus_7_bits_is_prefetch),
    .io_msStatus_8_valid(g1_io_msStatus_8_valid),
    .io_msStatus_8_bits_channel(g1_io_msStatus_8_bits_channel),
    .io_msStatus_8_bits_set(g1_io_msStatus_8_bits_set),
    .io_msStatus_8_bits_reqTag(g1_io_msStatus_8_bits_reqTag),
    .io_msStatus_8_bits_is_miss(g1_io_msStatus_8_bits_is_miss),
    .io_msStatus_8_bits_is_prefetch(g1_io_msStatus_8_bits_is_prefetch),
    .io_msStatus_9_valid(g1_io_msStatus_9_valid),
    .io_msStatus_9_bits_channel(g1_io_msStatus_9_bits_channel),
    .io_msStatus_9_bits_set(g1_io_msStatus_9_bits_set),
    .io_msStatus_9_bits_reqTag(g1_io_msStatus_9_bits_reqTag),
    .io_msStatus_9_bits_is_miss(g1_io_msStatus_9_bits_is_miss),
    .io_msStatus_9_bits_is_prefetch(g1_io_msStatus_9_bits_is_prefetch),
    .io_msStatus_10_valid(g1_io_msStatus_10_valid),
    .io_msStatus_10_bits_channel(g1_io_msStatus_10_bits_channel),
    .io_msStatus_10_bits_set(g1_io_msStatus_10_bits_set),
    .io_msStatus_10_bits_reqTag(g1_io_msStatus_10_bits_reqTag),
    .io_msStatus_10_bits_is_miss(g1_io_msStatus_10_bits_is_miss),
    .io_msStatus_10_bits_is_prefetch(g1_io_msStatus_10_bits_is_prefetch),
    .io_msStatus_11_valid(g1_io_msStatus_11_valid),
    .io_msStatus_11_bits_channel(g1_io_msStatus_11_bits_channel),
    .io_msStatus_11_bits_set(g1_io_msStatus_11_bits_set),
    .io_msStatus_11_bits_reqTag(g1_io_msStatus_11_bits_reqTag),
    .io_msStatus_11_bits_is_miss(g1_io_msStatus_11_bits_is_miss),
    .io_msStatus_11_bits_is_prefetch(g1_io_msStatus_11_bits_is_prefetch),
    .io_msStatus_12_valid(g1_io_msStatus_12_valid),
    .io_msStatus_12_bits_channel(g1_io_msStatus_12_bits_channel),
    .io_msStatus_12_bits_set(g1_io_msStatus_12_bits_set),
    .io_msStatus_12_bits_reqTag(g1_io_msStatus_12_bits_reqTag),
    .io_msStatus_12_bits_is_miss(g1_io_msStatus_12_bits_is_miss),
    .io_msStatus_12_bits_is_prefetch(g1_io_msStatus_12_bits_is_prefetch),
    .io_msStatus_13_valid(g1_io_msStatus_13_valid),
    .io_msStatus_13_bits_channel(g1_io_msStatus_13_bits_channel),
    .io_msStatus_13_bits_set(g1_io_msStatus_13_bits_set),
    .io_msStatus_13_bits_reqTag(g1_io_msStatus_13_bits_reqTag),
    .io_msStatus_13_bits_is_miss(g1_io_msStatus_13_bits_is_miss),
    .io_msStatus_13_bits_is_prefetch(g1_io_msStatus_13_bits_is_prefetch),
    .io_msStatus_14_valid(g1_io_msStatus_14_valid),
    .io_msStatus_14_bits_channel(g1_io_msStatus_14_bits_channel),
    .io_msStatus_14_bits_set(g1_io_msStatus_14_bits_set),
    .io_msStatus_14_bits_reqTag(g1_io_msStatus_14_bits_reqTag),
    .io_msStatus_14_bits_is_miss(g1_io_msStatus_14_bits_is_miss),
    .io_msStatus_14_bits_is_prefetch(g1_io_msStatus_14_bits_is_prefetch),
    .io_msStatus_15_valid(g1_io_msStatus_15_valid),
    .io_msStatus_15_bits_channel(g1_io_msStatus_15_bits_channel),
    .io_msStatus_15_bits_set(g1_io_msStatus_15_bits_set),
    .io_msStatus_15_bits_reqTag(g1_io_msStatus_15_bits_reqTag),
    .io_msStatus_15_bits_is_miss(g1_io_msStatus_15_bits_is_miss),
    .io_msStatus_15_bits_is_prefetch(g1_io_msStatus_15_bits_is_prefetch),
    .io_msAlloc_0_valid(g1_io_msAlloc_0_valid),
    .io_msAlloc_0_bits_channel(g1_io_msAlloc_0_bits_channel),
    .io_msAlloc_0_bits_is_miss(g1_io_msAlloc_0_bits_is_miss),
    .io_msAlloc_0_bits_is_prefetch(g1_io_msAlloc_0_bits_is_prefetch),
    .io_msAlloc_1_valid(g1_io_msAlloc_1_valid),
    .io_msAlloc_1_bits_channel(g1_io_msAlloc_1_bits_channel),
    .io_msAlloc_1_bits_is_miss(g1_io_msAlloc_1_bits_is_miss),
    .io_msAlloc_1_bits_is_prefetch(g1_io_msAlloc_1_bits_is_prefetch),
    .io_msAlloc_2_valid(g1_io_msAlloc_2_valid),
    .io_msAlloc_2_bits_channel(g1_io_msAlloc_2_bits_channel),
    .io_msAlloc_2_bits_is_miss(g1_io_msAlloc_2_bits_is_miss),
    .io_msAlloc_2_bits_is_prefetch(g1_io_msAlloc_2_bits_is_prefetch),
    .io_msAlloc_3_valid(g1_io_msAlloc_3_valid),
    .io_msAlloc_3_bits_channel(g1_io_msAlloc_3_bits_channel),
    .io_msAlloc_3_bits_is_miss(g1_io_msAlloc_3_bits_is_miss),
    .io_msAlloc_3_bits_is_prefetch(g1_io_msAlloc_3_bits_is_prefetch),
    .io_msAlloc_4_valid(g1_io_msAlloc_4_valid),
    .io_msAlloc_4_bits_channel(g1_io_msAlloc_4_bits_channel),
    .io_msAlloc_4_bits_is_miss(g1_io_msAlloc_4_bits_is_miss),
    .io_msAlloc_4_bits_is_prefetch(g1_io_msAlloc_4_bits_is_prefetch),
    .io_msAlloc_5_valid(g1_io_msAlloc_5_valid),
    .io_msAlloc_5_bits_channel(g1_io_msAlloc_5_bits_channel),
    .io_msAlloc_5_bits_is_miss(g1_io_msAlloc_5_bits_is_miss),
    .io_msAlloc_5_bits_is_prefetch(g1_io_msAlloc_5_bits_is_prefetch),
    .io_msAlloc_6_valid(g1_io_msAlloc_6_valid),
    .io_msAlloc_6_bits_channel(g1_io_msAlloc_6_bits_channel),
    .io_msAlloc_6_bits_is_miss(g1_io_msAlloc_6_bits_is_miss),
    .io_msAlloc_6_bits_is_prefetch(g1_io_msAlloc_6_bits_is_prefetch),
    .io_msAlloc_7_valid(g1_io_msAlloc_7_valid),
    .io_msAlloc_7_bits_channel(g1_io_msAlloc_7_bits_channel),
    .io_msAlloc_7_bits_is_miss(g1_io_msAlloc_7_bits_is_miss),
    .io_msAlloc_7_bits_is_prefetch(g1_io_msAlloc_7_bits_is_prefetch),
    .io_msAlloc_8_valid(g1_io_msAlloc_8_valid),
    .io_msAlloc_8_bits_channel(g1_io_msAlloc_8_bits_channel),
    .io_msAlloc_8_bits_is_miss(g1_io_msAlloc_8_bits_is_miss),
    .io_msAlloc_8_bits_is_prefetch(g1_io_msAlloc_8_bits_is_prefetch),
    .io_msAlloc_9_valid(g1_io_msAlloc_9_valid),
    .io_msAlloc_9_bits_channel(g1_io_msAlloc_9_bits_channel),
    .io_msAlloc_9_bits_is_miss(g1_io_msAlloc_9_bits_is_miss),
    .io_msAlloc_9_bits_is_prefetch(g1_io_msAlloc_9_bits_is_prefetch),
    .io_msAlloc_10_valid(g1_io_msAlloc_10_valid),
    .io_msAlloc_10_bits_channel(g1_io_msAlloc_10_bits_channel),
    .io_msAlloc_10_bits_is_miss(g1_io_msAlloc_10_bits_is_miss),
    .io_msAlloc_10_bits_is_prefetch(g1_io_msAlloc_10_bits_is_prefetch),
    .io_msAlloc_11_valid(g1_io_msAlloc_11_valid),
    .io_msAlloc_11_bits_channel(g1_io_msAlloc_11_bits_channel),
    .io_msAlloc_11_bits_is_miss(g1_io_msAlloc_11_bits_is_miss),
    .io_msAlloc_11_bits_is_prefetch(g1_io_msAlloc_11_bits_is_prefetch),
    .io_msAlloc_12_valid(g1_io_msAlloc_12_valid),
    .io_msAlloc_12_bits_channel(g1_io_msAlloc_12_bits_channel),
    .io_msAlloc_12_bits_is_miss(g1_io_msAlloc_12_bits_is_miss),
    .io_msAlloc_12_bits_is_prefetch(g1_io_msAlloc_12_bits_is_prefetch),
    .io_msAlloc_13_valid(g1_io_msAlloc_13_valid),
    .io_msAlloc_13_bits_channel(g1_io_msAlloc_13_bits_channel),
    .io_msAlloc_13_bits_is_miss(g1_io_msAlloc_13_bits_is_miss),
    .io_msAlloc_13_bits_is_prefetch(g1_io_msAlloc_13_bits_is_prefetch),
    .io_msAlloc_14_valid(g1_io_msAlloc_14_valid),
    .io_msAlloc_14_bits_channel(g1_io_msAlloc_14_bits_channel),
    .io_msAlloc_14_bits_is_miss(g1_io_msAlloc_14_bits_is_miss),
    .io_msAlloc_14_bits_is_prefetch(g1_io_msAlloc_14_bits_is_prefetch),
    .io_msAlloc_15_valid(g1_io_msAlloc_15_valid),
    .io_msAlloc_15_bits_channel(g1_io_msAlloc_15_bits_channel),
    .io_msAlloc_15_bits_is_miss(g1_io_msAlloc_15_bits_is_miss),
    .io_msAlloc_15_bits_is_prefetch(g1_io_msAlloc_15_bits_is_prefetch),
    .io_out_tx_req_ready(io_out_tx_req_ready),
    .io_out_tx_req_valid(g1_io_out_tx_req_valid),
    .io_out_tx_req_bits_qos(g1_io_out_tx_req_bits_qos),
    .io_out_tx_req_bits_txnID(g1_io_out_tx_req_bits_txnID),
    .io_out_tx_req_bits_returnNID(g1_io_out_tx_req_bits_returnNID),
    .io_out_tx_req_bits_stashNIDValid(g1_io_out_tx_req_bits_stashNIDValid),
    .io_out_tx_req_bits_returnTxnID(g1_io_out_tx_req_bits_returnTxnID),
    .io_out_tx_req_bits_opcode(g1_io_out_tx_req_bits_opcode),
    .io_out_tx_req_bits_addr(g1_io_out_tx_req_bits_addr),
    .io_out_tx_req_bits_ns(g1_io_out_tx_req_bits_ns),
    .io_out_tx_req_bits_likelyshared(g1_io_out_tx_req_bits_likelyshared),
    .io_out_tx_req_bits_allowRetry(g1_io_out_tx_req_bits_allowRetry),
    .io_out_tx_req_bits_order(g1_io_out_tx_req_bits_order),
    .io_out_tx_req_bits_pCrdType(g1_io_out_tx_req_bits_pCrdType),
    .io_out_tx_req_bits_memAttr_allocate(g1_io_out_tx_req_bits_memAttr_allocate),
    .io_out_tx_req_bits_memAttr_cacheable(g1_io_out_tx_req_bits_memAttr_cacheable),
    .io_out_tx_req_bits_memAttr_device(g1_io_out_tx_req_bits_memAttr_device),
    .io_out_tx_req_bits_memAttr_ewa(g1_io_out_tx_req_bits_memAttr_ewa),
    .io_out_tx_req_bits_snpAttr(g1_io_out_tx_req_bits_snpAttr),
    .io_out_tx_req_bits_lpIDWithPadding(g1_io_out_tx_req_bits_lpIDWithPadding),
    .io_out_tx_req_bits_snoopMe(g1_io_out_tx_req_bits_snoopMe),
    .io_out_tx_req_bits_expCompAck(g1_io_out_tx_req_bits_expCompAck),
    .io_out_tx_req_bits_tagOp(g1_io_out_tx_req_bits_tagOp),
    .io_out_tx_req_bits_traceTag(g1_io_out_tx_req_bits_traceTag),
    .io_out_tx_req_bits_mpam_perfMonGroup(g1_io_out_tx_req_bits_mpam_perfMonGroup),
    .io_out_tx_req_bits_mpam_partID(g1_io_out_tx_req_bits_mpam_partID),
    .io_out_tx_req_bits_mpam_mpamNS(g1_io_out_tx_req_bits_mpam_mpamNS),
    .io_out_tx_req_bits_rsvdc(g1_io_out_tx_req_bits_rsvdc),
    .io_out_tx_rsp_ready(io_out_tx_rsp_ready),
    .io_out_tx_rsp_valid(g1_io_out_tx_rsp_valid),
    .io_out_tx_rsp_bits_qos(g1_io_out_tx_rsp_bits_qos),
    .io_out_tx_rsp_bits_tgtID(g1_io_out_tx_rsp_bits_tgtID),
    .io_out_tx_rsp_bits_txnID(g1_io_out_tx_rsp_bits_txnID),
    .io_out_tx_rsp_bits_opcode(g1_io_out_tx_rsp_bits_opcode),
    .io_out_tx_rsp_bits_respErr(g1_io_out_tx_rsp_bits_respErr),
    .io_out_tx_rsp_bits_resp(g1_io_out_tx_rsp_bits_resp),
    .io_out_tx_rsp_bits_fwdState(g1_io_out_tx_rsp_bits_fwdState),
    .io_out_tx_rsp_bits_cBusy(g1_io_out_tx_rsp_bits_cBusy),
    .io_out_tx_rsp_bits_dbID(g1_io_out_tx_rsp_bits_dbID),
    .io_out_tx_rsp_bits_pCrdType(g1_io_out_tx_rsp_bits_pCrdType),
    .io_out_tx_rsp_bits_tagOp(g1_io_out_tx_rsp_bits_tagOp),
    .io_out_tx_rsp_bits_traceTag(g1_io_out_tx_rsp_bits_traceTag),
    .io_out_tx_dat_ready(io_out_tx_dat_ready),
    .io_out_tx_dat_valid(g1_io_out_tx_dat_valid),
    .io_out_tx_dat_bits_tgtID(g1_io_out_tx_dat_bits_tgtID),
    .io_out_tx_dat_bits_txnID(g1_io_out_tx_dat_bits_txnID),
    .io_out_tx_dat_bits_homeNID(g1_io_out_tx_dat_bits_homeNID),
    .io_out_tx_dat_bits_opcode(g1_io_out_tx_dat_bits_opcode),
    .io_out_tx_dat_bits_respErr(g1_io_out_tx_dat_bits_respErr),
    .io_out_tx_dat_bits_resp(g1_io_out_tx_dat_bits_resp),
    .io_out_tx_dat_bits_dataSource(g1_io_out_tx_dat_bits_dataSource),
    .io_out_tx_dat_bits_dbID(g1_io_out_tx_dat_bits_dbID),
    .io_out_tx_dat_bits_ccID(g1_io_out_tx_dat_bits_ccID),
    .io_out_tx_dat_bits_dataID(g1_io_out_tx_dat_bits_dataID),
    .io_out_tx_dat_bits_traceTag(g1_io_out_tx_dat_bits_traceTag),
    .io_out_tx_dat_bits_be(g1_io_out_tx_dat_bits_be),
    .io_out_tx_dat_bits_data(g1_io_out_tx_dat_bits_data),
    .io_out_tx_dat_bits_dataCheck(g1_io_out_tx_dat_bits_dataCheck),
    .io_out_tx_dat_bits_poison(g1_io_out_tx_dat_bits_poison),
    .io_out_rx_rsp_valid(io_out_rx_rsp_valid),
    .io_out_rx_rsp_bits_srcID(io_out_rx_rsp_bits_srcID),
    .io_out_rx_rsp_bits_txnID(io_out_rx_rsp_bits_txnID),
    .io_out_rx_rsp_bits_opcode(io_out_rx_rsp_bits_opcode),
    .io_out_rx_rsp_bits_respErr(io_out_rx_rsp_bits_respErr),
    .io_out_rx_rsp_bits_resp(io_out_rx_rsp_bits_resp),
    .io_out_rx_rsp_bits_dbID(io_out_rx_rsp_bits_dbID),
    .io_out_rx_rsp_bits_pCrdType(io_out_rx_rsp_bits_pCrdType),
    .io_out_rx_rsp_bits_traceTag(io_out_rx_rsp_bits_traceTag),
    .io_out_rx_dat_valid(io_out_rx_dat_valid),
    .io_out_rx_dat_bits_txnID(io_out_rx_dat_bits_txnID),
    .io_out_rx_dat_bits_homeNID(io_out_rx_dat_bits_homeNID),
    .io_out_rx_dat_bits_opcode(io_out_rx_dat_bits_opcode),
    .io_out_rx_dat_bits_respErr(io_out_rx_dat_bits_respErr),
    .io_out_rx_dat_bits_resp(io_out_rx_dat_bits_resp),
    .io_out_rx_dat_bits_dbID(io_out_rx_dat_bits_dbID),
    .io_out_rx_dat_bits_dataID(io_out_rx_dat_bits_dataID),
    .io_out_rx_dat_bits_traceTag(io_out_rx_dat_bits_traceTag),
    .io_out_rx_dat_bits_data(io_out_rx_dat_bits_data),
    .io_out_rx_dat_bits_dataCheck(io_out_rx_dat_bits_dataCheck),
    .io_out_rx_dat_bits_poison(io_out_rx_dat_bits_poison),
    .io_out_rx_snp_ready(g1_io_out_rx_snp_ready),
    .io_out_rx_snp_valid(io_out_rx_snp_valid),
    .io_out_rx_snp_bits_qos(io_out_rx_snp_bits_qos),
    .io_out_rx_snp_bits_srcID(io_out_rx_snp_bits_srcID),
    .io_out_rx_snp_bits_txnID(io_out_rx_snp_bits_txnID),
    .io_out_rx_snp_bits_fwdNID(io_out_rx_snp_bits_fwdNID),
    .io_out_rx_snp_bits_fwdTxnID(io_out_rx_snp_bits_fwdTxnID),
    .io_out_rx_snp_bits_opcode(io_out_rx_snp_bits_opcode),
    .io_out_rx_snp_bits_addr(io_out_rx_snp_bits_addr),
    .io_out_rx_snp_bits_ns(io_out_rx_snp_bits_ns),
    .io_out_rx_snp_bits_doNotGoToSD(io_out_rx_snp_bits_doNotGoToSD),
    .io_out_rx_snp_bits_retToSrc(io_out_rx_snp_bits_retToSrc),
    .io_out_rx_snp_bits_traceTag(io_out_rx_snp_bits_traceTag),
    .io_out_rx_snp_bits_mpam_perfMonGroup(io_out_rx_snp_bits_mpam_perfMonGroup),
    .io_out_rx_snp_bits_mpam_partID(io_out_rx_snp_bits_mpam_partID),
    .io_out_rx_snp_bits_mpam_mpamNS(io_out_rx_snp_bits_mpam_mpamNS),
    .io_pCrd_0_query_valid(g1_io_pCrd_0_query_valid),
    .io_pCrd_0_query_bits_pCrdType(g1_io_pCrd_0_query_bits_pCrdType),
    .io_pCrd_0_query_bits_srcID(g1_io_pCrd_0_query_bits_srcID),
    .io_pCrd_0_grant(io_pCrd_0_grant),
    .io_pCrd_1_query_valid(g1_io_pCrd_1_query_valid),
    .io_pCrd_1_query_bits_pCrdType(g1_io_pCrd_1_query_bits_pCrdType),
    .io_pCrd_1_query_bits_srcID(g1_io_pCrd_1_query_bits_srcID),
    .io_pCrd_1_grant(io_pCrd_1_grant),
    .io_pCrd_2_query_valid(g1_io_pCrd_2_query_valid),
    .io_pCrd_2_query_bits_pCrdType(g1_io_pCrd_2_query_bits_pCrdType),
    .io_pCrd_2_query_bits_srcID(g1_io_pCrd_2_query_bits_srcID),
    .io_pCrd_2_grant(io_pCrd_2_grant),
    .io_pCrd_3_query_valid(g1_io_pCrd_3_query_valid),
    .io_pCrd_3_query_bits_pCrdType(g1_io_pCrd_3_query_bits_pCrdType),
    .io_pCrd_3_query_bits_srcID(g1_io_pCrd_3_query_bits_srcID),
    .io_pCrd_3_grant(io_pCrd_3_grant),
    .io_pCrd_4_query_valid(g1_io_pCrd_4_query_valid),
    .io_pCrd_4_query_bits_pCrdType(g1_io_pCrd_4_query_bits_pCrdType),
    .io_pCrd_4_query_bits_srcID(g1_io_pCrd_4_query_bits_srcID),
    .io_pCrd_4_grant(io_pCrd_4_grant),
    .io_pCrd_5_query_valid(g1_io_pCrd_5_query_valid),
    .io_pCrd_5_query_bits_pCrdType(g1_io_pCrd_5_query_bits_pCrdType),
    .io_pCrd_5_query_bits_srcID(g1_io_pCrd_5_query_bits_srcID),
    .io_pCrd_5_grant(io_pCrd_5_grant),
    .io_pCrd_6_query_valid(g1_io_pCrd_6_query_valid),
    .io_pCrd_6_query_bits_pCrdType(g1_io_pCrd_6_query_bits_pCrdType),
    .io_pCrd_6_query_bits_srcID(g1_io_pCrd_6_query_bits_srcID),
    .io_pCrd_6_grant(io_pCrd_6_grant),
    .io_pCrd_7_query_valid(g1_io_pCrd_7_query_valid),
    .io_pCrd_7_query_bits_pCrdType(g1_io_pCrd_7_query_bits_pCrdType),
    .io_pCrd_7_query_bits_srcID(g1_io_pCrd_7_query_bits_srcID),
    .io_pCrd_7_grant(io_pCrd_7_grant),
    .io_pCrd_8_query_valid(g1_io_pCrd_8_query_valid),
    .io_pCrd_8_query_bits_pCrdType(g1_io_pCrd_8_query_bits_pCrdType),
    .io_pCrd_8_query_bits_srcID(g1_io_pCrd_8_query_bits_srcID),
    .io_pCrd_8_grant(io_pCrd_8_grant),
    .io_pCrd_9_query_valid(g1_io_pCrd_9_query_valid),
    .io_pCrd_9_query_bits_pCrdType(g1_io_pCrd_9_query_bits_pCrdType),
    .io_pCrd_9_query_bits_srcID(g1_io_pCrd_9_query_bits_srcID),
    .io_pCrd_9_grant(io_pCrd_9_grant),
    .io_pCrd_10_query_valid(g1_io_pCrd_10_query_valid),
    .io_pCrd_10_query_bits_pCrdType(g1_io_pCrd_10_query_bits_pCrdType),
    .io_pCrd_10_query_bits_srcID(g1_io_pCrd_10_query_bits_srcID),
    .io_pCrd_10_grant(io_pCrd_10_grant),
    .io_pCrd_11_query_valid(g1_io_pCrd_11_query_valid),
    .io_pCrd_11_query_bits_pCrdType(g1_io_pCrd_11_query_bits_pCrdType),
    .io_pCrd_11_query_bits_srcID(g1_io_pCrd_11_query_bits_srcID),
    .io_pCrd_11_grant(io_pCrd_11_grant),
    .io_pCrd_12_query_valid(g1_io_pCrd_12_query_valid),
    .io_pCrd_12_query_bits_pCrdType(g1_io_pCrd_12_query_bits_pCrdType),
    .io_pCrd_12_query_bits_srcID(g1_io_pCrd_12_query_bits_srcID),
    .io_pCrd_12_grant(io_pCrd_12_grant),
    .io_pCrd_13_query_valid(g1_io_pCrd_13_query_valid),
    .io_pCrd_13_query_bits_pCrdType(g1_io_pCrd_13_query_bits_pCrdType),
    .io_pCrd_13_query_bits_srcID(g1_io_pCrd_13_query_bits_srcID),
    .io_pCrd_13_grant(io_pCrd_13_grant),
    .io_pCrd_14_query_valid(g1_io_pCrd_14_query_valid),
    .io_pCrd_14_query_bits_pCrdType(g1_io_pCrd_14_query_bits_pCrdType),
    .io_pCrd_14_query_bits_srcID(g1_io_pCrd_14_query_bits_srcID),
    .io_pCrd_14_grant(io_pCrd_14_grant),
    .io_pCrd_15_query_valid(g1_io_pCrd_15_query_valid),
    .io_pCrd_15_query_bits_pCrdType(g1_io_pCrd_15_query_bits_pCrdType),
    .io_pCrd_15_query_bits_srcID(g1_io_pCrd_15_query_bits_srcID),
    .io_pCrd_15_grant(io_pCrd_15_grant),
    .io_perf_0_value(g1_io_perf_0_value),
    .io_perf_1_value(g1_io_perf_1_value),
    .io_perf_3_value(g1_io_perf_3_value),
    .io_perf_4_value(g1_io_perf_4_value),
    .io_perf_5_value(g1_io_perf_5_value),
    .io_perf_6_value(g1_io_perf_6_value),
    .io_perf_7_value(g1_io_perf_7_value),
    .io_perf_8_value(g1_io_perf_8_value),
    .io_perf_9_value(g1_io_perf_9_value),
    .io_perf_10_value(g1_io_perf_10_value),
    .io_perf_11_value(g1_io_perf_11_value),
    .io_perf_12_value(g1_io_perf_12_value),
    .io_perf_13_value(g1_io_perf_13_value),
    .io_perf_14_value(g1_io_perf_14_value),
    .io_perf_15_value(g1_io_perf_15_value),
    .io_perf_16_value(g1_io_perf_16_value),
    .sigFromSrams_bore_ram_hold(sigFromSrams_bore_ram_hold),
    .sigFromSrams_bore_ram_bypass(sigFromSrams_bore_ram_bypass),
    .sigFromSrams_bore_ram_bp_clken(sigFromSrams_bore_ram_bp_clken),
    .sigFromSrams_bore_ram_aux_clk(sigFromSrams_bore_ram_aux_clk),
    .sigFromSrams_bore_ram_aux_ckbp(sigFromSrams_bore_ram_aux_ckbp),
    .sigFromSrams_bore_ram_mcp_hold(sigFromSrams_bore_ram_mcp_hold),
    .sigFromSrams_bore_cgen(sigFromSrams_bore_cgen),
    .sigFromSrams_bore_1_ram_hold(sigFromSrams_bore_1_ram_hold),
    .sigFromSrams_bore_1_ram_bypass(sigFromSrams_bore_1_ram_bypass),
    .sigFromSrams_bore_1_ram_bp_clken(sigFromSrams_bore_1_ram_bp_clken),
    .sigFromSrams_bore_1_ram_aux_clk(sigFromSrams_bore_1_ram_aux_clk),
    .sigFromSrams_bore_1_ram_aux_ckbp(sigFromSrams_bore_1_ram_aux_ckbp),
    .sigFromSrams_bore_1_ram_mcp_hold(sigFromSrams_bore_1_ram_mcp_hold),
    .sigFromSrams_bore_1_cgen(sigFromSrams_bore_1_cgen),
    .sigFromSrams_bore_2_ram_hold(sigFromSrams_bore_2_ram_hold),
    .sigFromSrams_bore_2_ram_bypass(sigFromSrams_bore_2_ram_bypass),
    .sigFromSrams_bore_2_ram_bp_clken(sigFromSrams_bore_2_ram_bp_clken),
    .sigFromSrams_bore_2_ram_aux_clk(sigFromSrams_bore_2_ram_aux_clk),
    .sigFromSrams_bore_2_ram_aux_ckbp(sigFromSrams_bore_2_ram_aux_ckbp),
    .sigFromSrams_bore_2_ram_mcp_hold(sigFromSrams_bore_2_ram_mcp_hold),
    .sigFromSrams_bore_2_cgen(sigFromSrams_bore_2_cgen),
    .sigFromSrams_bore_3_ram_hold(sigFromSrams_bore_3_ram_hold),
    .sigFromSrams_bore_3_ram_bypass(sigFromSrams_bore_3_ram_bypass),
    .sigFromSrams_bore_3_ram_bp_clken(sigFromSrams_bore_3_ram_bp_clken),
    .sigFromSrams_bore_3_ram_aux_clk(sigFromSrams_bore_3_ram_aux_clk),
    .sigFromSrams_bore_3_ram_aux_ckbp(sigFromSrams_bore_3_ram_aux_ckbp),
    .sigFromSrams_bore_3_ram_mcp_hold(sigFromSrams_bore_3_ram_mcp_hold),
    .sigFromSrams_bore_3_cgen(sigFromSrams_bore_3_cgen),
    .sigFromSrams_bore_4_ram_hold(sigFromSrams_bore_4_ram_hold),
    .sigFromSrams_bore_4_ram_bypass(sigFromSrams_bore_4_ram_bypass),
    .sigFromSrams_bore_4_ram_bp_clken(sigFromSrams_bore_4_ram_bp_clken),
    .sigFromSrams_bore_4_ram_aux_clk(sigFromSrams_bore_4_ram_aux_clk),
    .sigFromSrams_bore_4_ram_aux_ckbp(sigFromSrams_bore_4_ram_aux_ckbp),
    .sigFromSrams_bore_4_ram_mcp_hold(sigFromSrams_bore_4_ram_mcp_hold),
    .sigFromSrams_bore_4_cgen(sigFromSrams_bore_4_cgen),
    .sigFromSrams_bore_5_ram_hold(sigFromSrams_bore_5_ram_hold),
    .sigFromSrams_bore_5_ram_bypass(sigFromSrams_bore_5_ram_bypass),
    .sigFromSrams_bore_5_ram_bp_clken(sigFromSrams_bore_5_ram_bp_clken),
    .sigFromSrams_bore_5_ram_aux_clk(sigFromSrams_bore_5_ram_aux_clk),
    .sigFromSrams_bore_5_ram_aux_ckbp(sigFromSrams_bore_5_ram_aux_ckbp),
    .sigFromSrams_bore_5_ram_mcp_hold(sigFromSrams_bore_5_ram_mcp_hold),
    .sigFromSrams_bore_5_cgen(sigFromSrams_bore_5_cgen),
    .sigFromSrams_bore_6_ram_hold(sigFromSrams_bore_6_ram_hold),
    .sigFromSrams_bore_6_ram_bypass(sigFromSrams_bore_6_ram_bypass),
    .sigFromSrams_bore_6_ram_bp_clken(sigFromSrams_bore_6_ram_bp_clken),
    .sigFromSrams_bore_6_ram_aux_clk(sigFromSrams_bore_6_ram_aux_clk),
    .sigFromSrams_bore_6_ram_aux_ckbp(sigFromSrams_bore_6_ram_aux_ckbp),
    .sigFromSrams_bore_6_ram_mcp_hold(sigFromSrams_bore_6_ram_mcp_hold),
    .sigFromSrams_bore_6_cgen(sigFromSrams_bore_6_cgen),
    .sigFromSrams_bore_7_ram_hold(sigFromSrams_bore_7_ram_hold),
    .sigFromSrams_bore_7_ram_bypass(sigFromSrams_bore_7_ram_bypass),
    .sigFromSrams_bore_7_ram_bp_clken(sigFromSrams_bore_7_ram_bp_clken),
    .sigFromSrams_bore_7_ram_aux_clk(sigFromSrams_bore_7_ram_aux_clk),
    .sigFromSrams_bore_7_ram_aux_ckbp(sigFromSrams_bore_7_ram_aux_ckbp),
    .sigFromSrams_bore_7_ram_mcp_hold(sigFromSrams_bore_7_ram_mcp_hold),
    .sigFromSrams_bore_7_cgen(sigFromSrams_bore_7_cgen),
    .sigFromSrams_bore_8_ram_hold(sigFromSrams_bore_8_ram_hold),
    .sigFromSrams_bore_8_ram_bypass(sigFromSrams_bore_8_ram_bypass),
    .sigFromSrams_bore_8_ram_bp_clken(sigFromSrams_bore_8_ram_bp_clken),
    .sigFromSrams_bore_8_ram_aux_clk(sigFromSrams_bore_8_ram_aux_clk),
    .sigFromSrams_bore_8_ram_aux_ckbp(sigFromSrams_bore_8_ram_aux_ckbp),
    .sigFromSrams_bore_8_ram_mcp_hold(sigFromSrams_bore_8_ram_mcp_hold),
    .sigFromSrams_bore_8_cgen(sigFromSrams_bore_8_cgen),
    .sigFromSrams_bore_9_ram_hold(sigFromSrams_bore_9_ram_hold),
    .sigFromSrams_bore_9_ram_bypass(sigFromSrams_bore_9_ram_bypass),
    .sigFromSrams_bore_9_ram_bp_clken(sigFromSrams_bore_9_ram_bp_clken),
    .sigFromSrams_bore_9_ram_aux_clk(sigFromSrams_bore_9_ram_aux_clk),
    .sigFromSrams_bore_9_ram_aux_ckbp(sigFromSrams_bore_9_ram_aux_ckbp),
    .sigFromSrams_bore_9_ram_mcp_hold(sigFromSrams_bore_9_ram_mcp_hold),
    .sigFromSrams_bore_9_cgen(sigFromSrams_bore_9_cgen),
    .sigFromSrams_bore_10_ram_hold(sigFromSrams_bore_10_ram_hold),
    .sigFromSrams_bore_10_ram_bypass(sigFromSrams_bore_10_ram_bypass),
    .sigFromSrams_bore_10_ram_bp_clken(sigFromSrams_bore_10_ram_bp_clken),
    .sigFromSrams_bore_10_ram_aux_clk(sigFromSrams_bore_10_ram_aux_clk),
    .sigFromSrams_bore_10_ram_aux_ckbp(sigFromSrams_bore_10_ram_aux_ckbp),
    .sigFromSrams_bore_10_ram_mcp_hold(sigFromSrams_bore_10_ram_mcp_hold),
    .sigFromSrams_bore_10_cgen(sigFromSrams_bore_10_cgen),
    .boreChildrenBd_bore_array(5'(boreChildrenBd_bore_array)),
    .boreChildrenBd_bore_all(boreChildrenBd_bore_all),
    .boreChildrenBd_bore_req(boreChildrenBd_bore_req),
    .boreChildrenBd_bore_ack(g1_boreChildrenBd_bore_ack),
    .boreChildrenBd_bore_writeen(boreChildrenBd_bore_writeen),
    .boreChildrenBd_bore_be(boreChildrenBd_bore_be),
    .boreChildrenBd_bore_addr(boreChildrenBd_bore_addr),
    .boreChildrenBd_bore_indata(boreChildrenBd_bore_indata),
    .boreChildrenBd_bore_readen(boreChildrenBd_bore_readen),
    .boreChildrenBd_bore_addr_rd(boreChildrenBd_bore_addr_rd),
    .boreChildrenBd_bore_outdata(g1_boreChildrenBd_bore_outdata)
  );
  Slice_1_xs u_i1 (
    .clock(clock),
    .reset(reset),
    .io_in_a_ready(i1_io_in_a_ready),
    .io_in_a_valid(io_in_a_valid),
    .io_in_a_bits_opcode(io_in_a_bits_opcode),
    .io_in_a_bits_param(io_in_a_bits_param),
    .io_in_a_bits_size(io_in_a_bits_size),
    .io_in_a_bits_source(io_in_a_bits_source),
    .io_in_a_bits_address(io_in_a_bits_address),
    .io_in_a_bits_user_reqSource(io_in_a_bits_user_reqSource),
    .io_in_a_bits_user_alias(io_in_a_bits_user_alias),
    .io_in_a_bits_user_vaddr(io_in_a_bits_user_vaddr),
    .io_in_a_bits_user_needHint(io_in_a_bits_user_needHint),
    .io_in_a_bits_echo_isKeyword(io_in_a_bits_echo_isKeyword),
    .io_in_a_bits_corrupt(io_in_a_bits_corrupt),
    .io_in_b_ready(io_in_b_ready),
    .io_in_b_valid(i1_io_in_b_valid),
    .io_in_b_bits_opcode(i1_io_in_b_bits_opcode),
    .io_in_b_bits_param(i1_io_in_b_bits_param),
    .io_in_b_bits_address(i1_io_in_b_bits_address),
    .io_in_b_bits_data(i1_io_in_b_bits_data),
    .io_in_c_ready(i1_io_in_c_ready),
    .io_in_c_valid(io_in_c_valid),
    .io_in_c_bits_opcode(io_in_c_bits_opcode),
    .io_in_c_bits_param(io_in_c_bits_param),
    .io_in_c_bits_size(io_in_c_bits_size),
    .io_in_c_bits_source(io_in_c_bits_source),
    .io_in_c_bits_address(io_in_c_bits_address),
    .io_in_c_bits_data(io_in_c_bits_data),
    .io_in_c_bits_corrupt(io_in_c_bits_corrupt),
    .io_in_d_ready(io_in_d_ready),
    .io_in_d_valid(i1_io_in_d_valid),
    .io_in_d_bits_opcode(i1_io_in_d_bits_opcode),
    .io_in_d_bits_param(i1_io_in_d_bits_param),
    .io_in_d_bits_source(i1_io_in_d_bits_source),
    .io_in_d_bits_sink(i1_io_in_d_bits_sink),
    .io_in_d_bits_denied(i1_io_in_d_bits_denied),
    .io_in_d_bits_echo_isKeyword(i1_io_in_d_bits_echo_isKeyword),
    .io_in_d_bits_data(i1_io_in_d_bits_data),
    .io_in_d_bits_corrupt(i1_io_in_d_bits_corrupt),
    .io_in_e_valid(io_in_e_valid),
    .io_in_e_bits_sink(io_in_e_bits_sink),
    .io_l1Hint_ready(io_l1Hint_ready),
    .io_l1Hint_valid(i1_io_l1Hint_valid),
    .io_l1Hint_bits_sourceId(i1_io_l1Hint_bits_sourceId),
    .io_l1Hint_bits_isKeyword(i1_io_l1Hint_bits_isKeyword),
    .io_prefetch_train_ready(io_prefetch_train_ready),
    .io_prefetch_train_valid(i1_io_prefetch_train_valid),
    .io_prefetch_train_bits_tag(i1_io_prefetch_train_bits_tag),
    .io_prefetch_train_bits_set(i1_io_prefetch_train_bits_set),
    .io_prefetch_train_bits_needT(i1_io_prefetch_train_bits_needT),
    .io_prefetch_train_bits_source(i1_io_prefetch_train_bits_source),
    .io_prefetch_train_bits_vaddr(i1_io_prefetch_train_bits_vaddr),
    .io_prefetch_train_bits_hit(i1_io_prefetch_train_bits_hit),
    .io_prefetch_train_bits_prefetched(i1_io_prefetch_train_bits_prefetched),
    .io_prefetch_train_bits_pfsource(i1_io_prefetch_train_bits_pfsource),
    .io_prefetch_train_bits_reqsource(i1_io_prefetch_train_bits_reqsource),
    .io_prefetch_req_ready(i1_io_prefetch_req_ready),
    .io_prefetch_req_valid(io_prefetch_req_valid),
    .io_prefetch_req_bits_tag(io_prefetch_req_bits_tag),
    .io_prefetch_req_bits_set(io_prefetch_req_bits_set),
    .io_prefetch_req_bits_vaddr(io_prefetch_req_bits_vaddr),
    .io_prefetch_req_bits_needT(io_prefetch_req_bits_needT),
    .io_prefetch_req_bits_source(io_prefetch_req_bits_source),
    .io_prefetch_req_bits_pfSource(io_prefetch_req_bits_pfSource),
    .io_prefetch_resp_ready(io_prefetch_resp_ready),
    .io_prefetch_resp_valid(i1_io_prefetch_resp_valid),
    .io_prefetch_resp_bits_tag(i1_io_prefetch_resp_bits_tag),
    .io_prefetch_resp_bits_set(i1_io_prefetch_resp_bits_set),
    .io_prefetch_resp_bits_vaddr(i1_io_prefetch_resp_bits_vaddr),
    .io_prefetch_resp_bits_pfSource(i1_io_prefetch_resp_bits_pfSource),
    .io_dirResult_valid(i1_io_dirResult_valid),
    .io_dirResult_bits_hit(i1_io_dirResult_bits_hit),
    .io_dirResult_bits_meta_prefetch(i1_io_dirResult_bits_meta_prefetch),
    .io_dirResult_bits_meta_prefetchSrc(i1_io_dirResult_bits_meta_prefetchSrc),
    .io_dirResult_bits_replacerInfo_channel(i1_io_dirResult_bits_replacerInfo_channel),
    .io_dirResult_bits_replacerInfo_reqSource(i1_io_dirResult_bits_replacerInfo_reqSource),
    .io_hitPfInMSHR_valid(i1_io_hitPfInMSHR_valid),
    .io_hitPfInMSHR_bits(i1_io_hitPfInMSHR_bits),
    .io_pfSent_valid(i1_io_pfSent_valid),
    .io_pfSent_bits(i1_io_pfSent_bits),
    .io_pfLateInMSHR_valid(i1_io_pfLateInMSHR_valid),
    .io_pfLateInMSHR_bits(i1_io_pfLateInMSHR_bits),
    .io_error_valid(i1_io_error_valid),
    .io_error_bits_valid(i1_io_error_bits_valid),
    .io_error_bits_address(i1_io_error_bits_address),
    .io_l2Miss(i1_io_l2Miss),
    .io_msStatus_0_valid(i1_io_msStatus_0_valid),
    .io_msStatus_0_bits_channel(i1_io_msStatus_0_bits_channel),
    .io_msStatus_0_bits_set(i1_io_msStatus_0_bits_set),
    .io_msStatus_0_bits_reqTag(i1_io_msStatus_0_bits_reqTag),
    .io_msStatus_0_bits_is_miss(i1_io_msStatus_0_bits_is_miss),
    .io_msStatus_0_bits_is_prefetch(i1_io_msStatus_0_bits_is_prefetch),
    .io_msStatus_1_valid(i1_io_msStatus_1_valid),
    .io_msStatus_1_bits_channel(i1_io_msStatus_1_bits_channel),
    .io_msStatus_1_bits_set(i1_io_msStatus_1_bits_set),
    .io_msStatus_1_bits_reqTag(i1_io_msStatus_1_bits_reqTag),
    .io_msStatus_1_bits_is_miss(i1_io_msStatus_1_bits_is_miss),
    .io_msStatus_1_bits_is_prefetch(i1_io_msStatus_1_bits_is_prefetch),
    .io_msStatus_2_valid(i1_io_msStatus_2_valid),
    .io_msStatus_2_bits_channel(i1_io_msStatus_2_bits_channel),
    .io_msStatus_2_bits_set(i1_io_msStatus_2_bits_set),
    .io_msStatus_2_bits_reqTag(i1_io_msStatus_2_bits_reqTag),
    .io_msStatus_2_bits_is_miss(i1_io_msStatus_2_bits_is_miss),
    .io_msStatus_2_bits_is_prefetch(i1_io_msStatus_2_bits_is_prefetch),
    .io_msStatus_3_valid(i1_io_msStatus_3_valid),
    .io_msStatus_3_bits_channel(i1_io_msStatus_3_bits_channel),
    .io_msStatus_3_bits_set(i1_io_msStatus_3_bits_set),
    .io_msStatus_3_bits_reqTag(i1_io_msStatus_3_bits_reqTag),
    .io_msStatus_3_bits_is_miss(i1_io_msStatus_3_bits_is_miss),
    .io_msStatus_3_bits_is_prefetch(i1_io_msStatus_3_bits_is_prefetch),
    .io_msStatus_4_valid(i1_io_msStatus_4_valid),
    .io_msStatus_4_bits_channel(i1_io_msStatus_4_bits_channel),
    .io_msStatus_4_bits_set(i1_io_msStatus_4_bits_set),
    .io_msStatus_4_bits_reqTag(i1_io_msStatus_4_bits_reqTag),
    .io_msStatus_4_bits_is_miss(i1_io_msStatus_4_bits_is_miss),
    .io_msStatus_4_bits_is_prefetch(i1_io_msStatus_4_bits_is_prefetch),
    .io_msStatus_5_valid(i1_io_msStatus_5_valid),
    .io_msStatus_5_bits_channel(i1_io_msStatus_5_bits_channel),
    .io_msStatus_5_bits_set(i1_io_msStatus_5_bits_set),
    .io_msStatus_5_bits_reqTag(i1_io_msStatus_5_bits_reqTag),
    .io_msStatus_5_bits_is_miss(i1_io_msStatus_5_bits_is_miss),
    .io_msStatus_5_bits_is_prefetch(i1_io_msStatus_5_bits_is_prefetch),
    .io_msStatus_6_valid(i1_io_msStatus_6_valid),
    .io_msStatus_6_bits_channel(i1_io_msStatus_6_bits_channel),
    .io_msStatus_6_bits_set(i1_io_msStatus_6_bits_set),
    .io_msStatus_6_bits_reqTag(i1_io_msStatus_6_bits_reqTag),
    .io_msStatus_6_bits_is_miss(i1_io_msStatus_6_bits_is_miss),
    .io_msStatus_6_bits_is_prefetch(i1_io_msStatus_6_bits_is_prefetch),
    .io_msStatus_7_valid(i1_io_msStatus_7_valid),
    .io_msStatus_7_bits_channel(i1_io_msStatus_7_bits_channel),
    .io_msStatus_7_bits_set(i1_io_msStatus_7_bits_set),
    .io_msStatus_7_bits_reqTag(i1_io_msStatus_7_bits_reqTag),
    .io_msStatus_7_bits_is_miss(i1_io_msStatus_7_bits_is_miss),
    .io_msStatus_7_bits_is_prefetch(i1_io_msStatus_7_bits_is_prefetch),
    .io_msStatus_8_valid(i1_io_msStatus_8_valid),
    .io_msStatus_8_bits_channel(i1_io_msStatus_8_bits_channel),
    .io_msStatus_8_bits_set(i1_io_msStatus_8_bits_set),
    .io_msStatus_8_bits_reqTag(i1_io_msStatus_8_bits_reqTag),
    .io_msStatus_8_bits_is_miss(i1_io_msStatus_8_bits_is_miss),
    .io_msStatus_8_bits_is_prefetch(i1_io_msStatus_8_bits_is_prefetch),
    .io_msStatus_9_valid(i1_io_msStatus_9_valid),
    .io_msStatus_9_bits_channel(i1_io_msStatus_9_bits_channel),
    .io_msStatus_9_bits_set(i1_io_msStatus_9_bits_set),
    .io_msStatus_9_bits_reqTag(i1_io_msStatus_9_bits_reqTag),
    .io_msStatus_9_bits_is_miss(i1_io_msStatus_9_bits_is_miss),
    .io_msStatus_9_bits_is_prefetch(i1_io_msStatus_9_bits_is_prefetch),
    .io_msStatus_10_valid(i1_io_msStatus_10_valid),
    .io_msStatus_10_bits_channel(i1_io_msStatus_10_bits_channel),
    .io_msStatus_10_bits_set(i1_io_msStatus_10_bits_set),
    .io_msStatus_10_bits_reqTag(i1_io_msStatus_10_bits_reqTag),
    .io_msStatus_10_bits_is_miss(i1_io_msStatus_10_bits_is_miss),
    .io_msStatus_10_bits_is_prefetch(i1_io_msStatus_10_bits_is_prefetch),
    .io_msStatus_11_valid(i1_io_msStatus_11_valid),
    .io_msStatus_11_bits_channel(i1_io_msStatus_11_bits_channel),
    .io_msStatus_11_bits_set(i1_io_msStatus_11_bits_set),
    .io_msStatus_11_bits_reqTag(i1_io_msStatus_11_bits_reqTag),
    .io_msStatus_11_bits_is_miss(i1_io_msStatus_11_bits_is_miss),
    .io_msStatus_11_bits_is_prefetch(i1_io_msStatus_11_bits_is_prefetch),
    .io_msStatus_12_valid(i1_io_msStatus_12_valid),
    .io_msStatus_12_bits_channel(i1_io_msStatus_12_bits_channel),
    .io_msStatus_12_bits_set(i1_io_msStatus_12_bits_set),
    .io_msStatus_12_bits_reqTag(i1_io_msStatus_12_bits_reqTag),
    .io_msStatus_12_bits_is_miss(i1_io_msStatus_12_bits_is_miss),
    .io_msStatus_12_bits_is_prefetch(i1_io_msStatus_12_bits_is_prefetch),
    .io_msStatus_13_valid(i1_io_msStatus_13_valid),
    .io_msStatus_13_bits_channel(i1_io_msStatus_13_bits_channel),
    .io_msStatus_13_bits_set(i1_io_msStatus_13_bits_set),
    .io_msStatus_13_bits_reqTag(i1_io_msStatus_13_bits_reqTag),
    .io_msStatus_13_bits_is_miss(i1_io_msStatus_13_bits_is_miss),
    .io_msStatus_13_bits_is_prefetch(i1_io_msStatus_13_bits_is_prefetch),
    .io_msStatus_14_valid(i1_io_msStatus_14_valid),
    .io_msStatus_14_bits_channel(i1_io_msStatus_14_bits_channel),
    .io_msStatus_14_bits_set(i1_io_msStatus_14_bits_set),
    .io_msStatus_14_bits_reqTag(i1_io_msStatus_14_bits_reqTag),
    .io_msStatus_14_bits_is_miss(i1_io_msStatus_14_bits_is_miss),
    .io_msStatus_14_bits_is_prefetch(i1_io_msStatus_14_bits_is_prefetch),
    .io_msStatus_15_valid(i1_io_msStatus_15_valid),
    .io_msStatus_15_bits_channel(i1_io_msStatus_15_bits_channel),
    .io_msStatus_15_bits_set(i1_io_msStatus_15_bits_set),
    .io_msStatus_15_bits_reqTag(i1_io_msStatus_15_bits_reqTag),
    .io_msStatus_15_bits_is_miss(i1_io_msStatus_15_bits_is_miss),
    .io_msStatus_15_bits_is_prefetch(i1_io_msStatus_15_bits_is_prefetch),
    .io_msAlloc_0_valid(i1_io_msAlloc_0_valid),
    .io_msAlloc_0_bits_channel(i1_io_msAlloc_0_bits_channel),
    .io_msAlloc_0_bits_is_miss(i1_io_msAlloc_0_bits_is_miss),
    .io_msAlloc_0_bits_is_prefetch(i1_io_msAlloc_0_bits_is_prefetch),
    .io_msAlloc_1_valid(i1_io_msAlloc_1_valid),
    .io_msAlloc_1_bits_channel(i1_io_msAlloc_1_bits_channel),
    .io_msAlloc_1_bits_is_miss(i1_io_msAlloc_1_bits_is_miss),
    .io_msAlloc_1_bits_is_prefetch(i1_io_msAlloc_1_bits_is_prefetch),
    .io_msAlloc_2_valid(i1_io_msAlloc_2_valid),
    .io_msAlloc_2_bits_channel(i1_io_msAlloc_2_bits_channel),
    .io_msAlloc_2_bits_is_miss(i1_io_msAlloc_2_bits_is_miss),
    .io_msAlloc_2_bits_is_prefetch(i1_io_msAlloc_2_bits_is_prefetch),
    .io_msAlloc_3_valid(i1_io_msAlloc_3_valid),
    .io_msAlloc_3_bits_channel(i1_io_msAlloc_3_bits_channel),
    .io_msAlloc_3_bits_is_miss(i1_io_msAlloc_3_bits_is_miss),
    .io_msAlloc_3_bits_is_prefetch(i1_io_msAlloc_3_bits_is_prefetch),
    .io_msAlloc_4_valid(i1_io_msAlloc_4_valid),
    .io_msAlloc_4_bits_channel(i1_io_msAlloc_4_bits_channel),
    .io_msAlloc_4_bits_is_miss(i1_io_msAlloc_4_bits_is_miss),
    .io_msAlloc_4_bits_is_prefetch(i1_io_msAlloc_4_bits_is_prefetch),
    .io_msAlloc_5_valid(i1_io_msAlloc_5_valid),
    .io_msAlloc_5_bits_channel(i1_io_msAlloc_5_bits_channel),
    .io_msAlloc_5_bits_is_miss(i1_io_msAlloc_5_bits_is_miss),
    .io_msAlloc_5_bits_is_prefetch(i1_io_msAlloc_5_bits_is_prefetch),
    .io_msAlloc_6_valid(i1_io_msAlloc_6_valid),
    .io_msAlloc_6_bits_channel(i1_io_msAlloc_6_bits_channel),
    .io_msAlloc_6_bits_is_miss(i1_io_msAlloc_6_bits_is_miss),
    .io_msAlloc_6_bits_is_prefetch(i1_io_msAlloc_6_bits_is_prefetch),
    .io_msAlloc_7_valid(i1_io_msAlloc_7_valid),
    .io_msAlloc_7_bits_channel(i1_io_msAlloc_7_bits_channel),
    .io_msAlloc_7_bits_is_miss(i1_io_msAlloc_7_bits_is_miss),
    .io_msAlloc_7_bits_is_prefetch(i1_io_msAlloc_7_bits_is_prefetch),
    .io_msAlloc_8_valid(i1_io_msAlloc_8_valid),
    .io_msAlloc_8_bits_channel(i1_io_msAlloc_8_bits_channel),
    .io_msAlloc_8_bits_is_miss(i1_io_msAlloc_8_bits_is_miss),
    .io_msAlloc_8_bits_is_prefetch(i1_io_msAlloc_8_bits_is_prefetch),
    .io_msAlloc_9_valid(i1_io_msAlloc_9_valid),
    .io_msAlloc_9_bits_channel(i1_io_msAlloc_9_bits_channel),
    .io_msAlloc_9_bits_is_miss(i1_io_msAlloc_9_bits_is_miss),
    .io_msAlloc_9_bits_is_prefetch(i1_io_msAlloc_9_bits_is_prefetch),
    .io_msAlloc_10_valid(i1_io_msAlloc_10_valid),
    .io_msAlloc_10_bits_channel(i1_io_msAlloc_10_bits_channel),
    .io_msAlloc_10_bits_is_miss(i1_io_msAlloc_10_bits_is_miss),
    .io_msAlloc_10_bits_is_prefetch(i1_io_msAlloc_10_bits_is_prefetch),
    .io_msAlloc_11_valid(i1_io_msAlloc_11_valid),
    .io_msAlloc_11_bits_channel(i1_io_msAlloc_11_bits_channel),
    .io_msAlloc_11_bits_is_miss(i1_io_msAlloc_11_bits_is_miss),
    .io_msAlloc_11_bits_is_prefetch(i1_io_msAlloc_11_bits_is_prefetch),
    .io_msAlloc_12_valid(i1_io_msAlloc_12_valid),
    .io_msAlloc_12_bits_channel(i1_io_msAlloc_12_bits_channel),
    .io_msAlloc_12_bits_is_miss(i1_io_msAlloc_12_bits_is_miss),
    .io_msAlloc_12_bits_is_prefetch(i1_io_msAlloc_12_bits_is_prefetch),
    .io_msAlloc_13_valid(i1_io_msAlloc_13_valid),
    .io_msAlloc_13_bits_channel(i1_io_msAlloc_13_bits_channel),
    .io_msAlloc_13_bits_is_miss(i1_io_msAlloc_13_bits_is_miss),
    .io_msAlloc_13_bits_is_prefetch(i1_io_msAlloc_13_bits_is_prefetch),
    .io_msAlloc_14_valid(i1_io_msAlloc_14_valid),
    .io_msAlloc_14_bits_channel(i1_io_msAlloc_14_bits_channel),
    .io_msAlloc_14_bits_is_miss(i1_io_msAlloc_14_bits_is_miss),
    .io_msAlloc_14_bits_is_prefetch(i1_io_msAlloc_14_bits_is_prefetch),
    .io_msAlloc_15_valid(i1_io_msAlloc_15_valid),
    .io_msAlloc_15_bits_channel(i1_io_msAlloc_15_bits_channel),
    .io_msAlloc_15_bits_is_miss(i1_io_msAlloc_15_bits_is_miss),
    .io_msAlloc_15_bits_is_prefetch(i1_io_msAlloc_15_bits_is_prefetch),
    .io_out_tx_req_ready(io_out_tx_req_ready),
    .io_out_tx_req_valid(i1_io_out_tx_req_valid),
    .io_out_tx_req_bits_qos(i1_io_out_tx_req_bits_qos),
    .io_out_tx_req_bits_txnID(i1_io_out_tx_req_bits_txnID),
    .io_out_tx_req_bits_returnNID(i1_io_out_tx_req_bits_returnNID),
    .io_out_tx_req_bits_stashNIDValid(i1_io_out_tx_req_bits_stashNIDValid),
    .io_out_tx_req_bits_returnTxnID(i1_io_out_tx_req_bits_returnTxnID),
    .io_out_tx_req_bits_opcode(i1_io_out_tx_req_bits_opcode),
    .io_out_tx_req_bits_addr(i1_io_out_tx_req_bits_addr),
    .io_out_tx_req_bits_ns(i1_io_out_tx_req_bits_ns),
    .io_out_tx_req_bits_likelyshared(i1_io_out_tx_req_bits_likelyshared),
    .io_out_tx_req_bits_allowRetry(i1_io_out_tx_req_bits_allowRetry),
    .io_out_tx_req_bits_order(i1_io_out_tx_req_bits_order),
    .io_out_tx_req_bits_pCrdType(i1_io_out_tx_req_bits_pCrdType),
    .io_out_tx_req_bits_memAttr_allocate(i1_io_out_tx_req_bits_memAttr_allocate),
    .io_out_tx_req_bits_memAttr_cacheable(i1_io_out_tx_req_bits_memAttr_cacheable),
    .io_out_tx_req_bits_memAttr_device(i1_io_out_tx_req_bits_memAttr_device),
    .io_out_tx_req_bits_memAttr_ewa(i1_io_out_tx_req_bits_memAttr_ewa),
    .io_out_tx_req_bits_snpAttr(i1_io_out_tx_req_bits_snpAttr),
    .io_out_tx_req_bits_lpIDWithPadding(i1_io_out_tx_req_bits_lpIDWithPadding),
    .io_out_tx_req_bits_snoopMe(i1_io_out_tx_req_bits_snoopMe),
    .io_out_tx_req_bits_expCompAck(i1_io_out_tx_req_bits_expCompAck),
    .io_out_tx_req_bits_tagOp(i1_io_out_tx_req_bits_tagOp),
    .io_out_tx_req_bits_traceTag(i1_io_out_tx_req_bits_traceTag),
    .io_out_tx_req_bits_mpam_perfMonGroup(i1_io_out_tx_req_bits_mpam_perfMonGroup),
    .io_out_tx_req_bits_mpam_partID(i1_io_out_tx_req_bits_mpam_partID),
    .io_out_tx_req_bits_mpam_mpamNS(i1_io_out_tx_req_bits_mpam_mpamNS),
    .io_out_tx_req_bits_rsvdc(i1_io_out_tx_req_bits_rsvdc),
    .io_out_tx_rsp_ready(io_out_tx_rsp_ready),
    .io_out_tx_rsp_valid(i1_io_out_tx_rsp_valid),
    .io_out_tx_rsp_bits_qos(i1_io_out_tx_rsp_bits_qos),
    .io_out_tx_rsp_bits_tgtID(i1_io_out_tx_rsp_bits_tgtID),
    .io_out_tx_rsp_bits_txnID(i1_io_out_tx_rsp_bits_txnID),
    .io_out_tx_rsp_bits_opcode(i1_io_out_tx_rsp_bits_opcode),
    .io_out_tx_rsp_bits_respErr(i1_io_out_tx_rsp_bits_respErr),
    .io_out_tx_rsp_bits_resp(i1_io_out_tx_rsp_bits_resp),
    .io_out_tx_rsp_bits_fwdState(i1_io_out_tx_rsp_bits_fwdState),
    .io_out_tx_rsp_bits_cBusy(i1_io_out_tx_rsp_bits_cBusy),
    .io_out_tx_rsp_bits_dbID(i1_io_out_tx_rsp_bits_dbID),
    .io_out_tx_rsp_bits_pCrdType(i1_io_out_tx_rsp_bits_pCrdType),
    .io_out_tx_rsp_bits_tagOp(i1_io_out_tx_rsp_bits_tagOp),
    .io_out_tx_rsp_bits_traceTag(i1_io_out_tx_rsp_bits_traceTag),
    .io_out_tx_dat_ready(io_out_tx_dat_ready),
    .io_out_tx_dat_valid(i1_io_out_tx_dat_valid),
    .io_out_tx_dat_bits_tgtID(i1_io_out_tx_dat_bits_tgtID),
    .io_out_tx_dat_bits_txnID(i1_io_out_tx_dat_bits_txnID),
    .io_out_tx_dat_bits_homeNID(i1_io_out_tx_dat_bits_homeNID),
    .io_out_tx_dat_bits_opcode(i1_io_out_tx_dat_bits_opcode),
    .io_out_tx_dat_bits_respErr(i1_io_out_tx_dat_bits_respErr),
    .io_out_tx_dat_bits_resp(i1_io_out_tx_dat_bits_resp),
    .io_out_tx_dat_bits_dataSource(i1_io_out_tx_dat_bits_dataSource),
    .io_out_tx_dat_bits_dbID(i1_io_out_tx_dat_bits_dbID),
    .io_out_tx_dat_bits_ccID(i1_io_out_tx_dat_bits_ccID),
    .io_out_tx_dat_bits_dataID(i1_io_out_tx_dat_bits_dataID),
    .io_out_tx_dat_bits_traceTag(i1_io_out_tx_dat_bits_traceTag),
    .io_out_tx_dat_bits_be(i1_io_out_tx_dat_bits_be),
    .io_out_tx_dat_bits_data(i1_io_out_tx_dat_bits_data),
    .io_out_tx_dat_bits_dataCheck(i1_io_out_tx_dat_bits_dataCheck),
    .io_out_tx_dat_bits_poison(i1_io_out_tx_dat_bits_poison),
    .io_out_rx_rsp_valid(io_out_rx_rsp_valid),
    .io_out_rx_rsp_bits_srcID(io_out_rx_rsp_bits_srcID),
    .io_out_rx_rsp_bits_txnID(io_out_rx_rsp_bits_txnID),
    .io_out_rx_rsp_bits_opcode(io_out_rx_rsp_bits_opcode),
    .io_out_rx_rsp_bits_respErr(io_out_rx_rsp_bits_respErr),
    .io_out_rx_rsp_bits_resp(io_out_rx_rsp_bits_resp),
    .io_out_rx_rsp_bits_dbID(io_out_rx_rsp_bits_dbID),
    .io_out_rx_rsp_bits_pCrdType(io_out_rx_rsp_bits_pCrdType),
    .io_out_rx_rsp_bits_traceTag(io_out_rx_rsp_bits_traceTag),
    .io_out_rx_dat_valid(io_out_rx_dat_valid),
    .io_out_rx_dat_bits_txnID(io_out_rx_dat_bits_txnID),
    .io_out_rx_dat_bits_homeNID(io_out_rx_dat_bits_homeNID),
    .io_out_rx_dat_bits_opcode(io_out_rx_dat_bits_opcode),
    .io_out_rx_dat_bits_respErr(io_out_rx_dat_bits_respErr),
    .io_out_rx_dat_bits_resp(io_out_rx_dat_bits_resp),
    .io_out_rx_dat_bits_dbID(io_out_rx_dat_bits_dbID),
    .io_out_rx_dat_bits_dataID(io_out_rx_dat_bits_dataID),
    .io_out_rx_dat_bits_traceTag(io_out_rx_dat_bits_traceTag),
    .io_out_rx_dat_bits_data(io_out_rx_dat_bits_data),
    .io_out_rx_dat_bits_dataCheck(io_out_rx_dat_bits_dataCheck),
    .io_out_rx_dat_bits_poison(io_out_rx_dat_bits_poison),
    .io_out_rx_snp_ready(i1_io_out_rx_snp_ready),
    .io_out_rx_snp_valid(io_out_rx_snp_valid),
    .io_out_rx_snp_bits_qos(io_out_rx_snp_bits_qos),
    .io_out_rx_snp_bits_srcID(io_out_rx_snp_bits_srcID),
    .io_out_rx_snp_bits_txnID(io_out_rx_snp_bits_txnID),
    .io_out_rx_snp_bits_fwdNID(io_out_rx_snp_bits_fwdNID),
    .io_out_rx_snp_bits_fwdTxnID(io_out_rx_snp_bits_fwdTxnID),
    .io_out_rx_snp_bits_opcode(io_out_rx_snp_bits_opcode),
    .io_out_rx_snp_bits_addr(io_out_rx_snp_bits_addr),
    .io_out_rx_snp_bits_ns(io_out_rx_snp_bits_ns),
    .io_out_rx_snp_bits_doNotGoToSD(io_out_rx_snp_bits_doNotGoToSD),
    .io_out_rx_snp_bits_retToSrc(io_out_rx_snp_bits_retToSrc),
    .io_out_rx_snp_bits_traceTag(io_out_rx_snp_bits_traceTag),
    .io_out_rx_snp_bits_mpam_perfMonGroup(io_out_rx_snp_bits_mpam_perfMonGroup),
    .io_out_rx_snp_bits_mpam_partID(io_out_rx_snp_bits_mpam_partID),
    .io_out_rx_snp_bits_mpam_mpamNS(io_out_rx_snp_bits_mpam_mpamNS),
    .io_pCrd_0_query_valid(i1_io_pCrd_0_query_valid),
    .io_pCrd_0_query_bits_pCrdType(i1_io_pCrd_0_query_bits_pCrdType),
    .io_pCrd_0_query_bits_srcID(i1_io_pCrd_0_query_bits_srcID),
    .io_pCrd_0_grant(io_pCrd_0_grant),
    .io_pCrd_1_query_valid(i1_io_pCrd_1_query_valid),
    .io_pCrd_1_query_bits_pCrdType(i1_io_pCrd_1_query_bits_pCrdType),
    .io_pCrd_1_query_bits_srcID(i1_io_pCrd_1_query_bits_srcID),
    .io_pCrd_1_grant(io_pCrd_1_grant),
    .io_pCrd_2_query_valid(i1_io_pCrd_2_query_valid),
    .io_pCrd_2_query_bits_pCrdType(i1_io_pCrd_2_query_bits_pCrdType),
    .io_pCrd_2_query_bits_srcID(i1_io_pCrd_2_query_bits_srcID),
    .io_pCrd_2_grant(io_pCrd_2_grant),
    .io_pCrd_3_query_valid(i1_io_pCrd_3_query_valid),
    .io_pCrd_3_query_bits_pCrdType(i1_io_pCrd_3_query_bits_pCrdType),
    .io_pCrd_3_query_bits_srcID(i1_io_pCrd_3_query_bits_srcID),
    .io_pCrd_3_grant(io_pCrd_3_grant),
    .io_pCrd_4_query_valid(i1_io_pCrd_4_query_valid),
    .io_pCrd_4_query_bits_pCrdType(i1_io_pCrd_4_query_bits_pCrdType),
    .io_pCrd_4_query_bits_srcID(i1_io_pCrd_4_query_bits_srcID),
    .io_pCrd_4_grant(io_pCrd_4_grant),
    .io_pCrd_5_query_valid(i1_io_pCrd_5_query_valid),
    .io_pCrd_5_query_bits_pCrdType(i1_io_pCrd_5_query_bits_pCrdType),
    .io_pCrd_5_query_bits_srcID(i1_io_pCrd_5_query_bits_srcID),
    .io_pCrd_5_grant(io_pCrd_5_grant),
    .io_pCrd_6_query_valid(i1_io_pCrd_6_query_valid),
    .io_pCrd_6_query_bits_pCrdType(i1_io_pCrd_6_query_bits_pCrdType),
    .io_pCrd_6_query_bits_srcID(i1_io_pCrd_6_query_bits_srcID),
    .io_pCrd_6_grant(io_pCrd_6_grant),
    .io_pCrd_7_query_valid(i1_io_pCrd_7_query_valid),
    .io_pCrd_7_query_bits_pCrdType(i1_io_pCrd_7_query_bits_pCrdType),
    .io_pCrd_7_query_bits_srcID(i1_io_pCrd_7_query_bits_srcID),
    .io_pCrd_7_grant(io_pCrd_7_grant),
    .io_pCrd_8_query_valid(i1_io_pCrd_8_query_valid),
    .io_pCrd_8_query_bits_pCrdType(i1_io_pCrd_8_query_bits_pCrdType),
    .io_pCrd_8_query_bits_srcID(i1_io_pCrd_8_query_bits_srcID),
    .io_pCrd_8_grant(io_pCrd_8_grant),
    .io_pCrd_9_query_valid(i1_io_pCrd_9_query_valid),
    .io_pCrd_9_query_bits_pCrdType(i1_io_pCrd_9_query_bits_pCrdType),
    .io_pCrd_9_query_bits_srcID(i1_io_pCrd_9_query_bits_srcID),
    .io_pCrd_9_grant(io_pCrd_9_grant),
    .io_pCrd_10_query_valid(i1_io_pCrd_10_query_valid),
    .io_pCrd_10_query_bits_pCrdType(i1_io_pCrd_10_query_bits_pCrdType),
    .io_pCrd_10_query_bits_srcID(i1_io_pCrd_10_query_bits_srcID),
    .io_pCrd_10_grant(io_pCrd_10_grant),
    .io_pCrd_11_query_valid(i1_io_pCrd_11_query_valid),
    .io_pCrd_11_query_bits_pCrdType(i1_io_pCrd_11_query_bits_pCrdType),
    .io_pCrd_11_query_bits_srcID(i1_io_pCrd_11_query_bits_srcID),
    .io_pCrd_11_grant(io_pCrd_11_grant),
    .io_pCrd_12_query_valid(i1_io_pCrd_12_query_valid),
    .io_pCrd_12_query_bits_pCrdType(i1_io_pCrd_12_query_bits_pCrdType),
    .io_pCrd_12_query_bits_srcID(i1_io_pCrd_12_query_bits_srcID),
    .io_pCrd_12_grant(io_pCrd_12_grant),
    .io_pCrd_13_query_valid(i1_io_pCrd_13_query_valid),
    .io_pCrd_13_query_bits_pCrdType(i1_io_pCrd_13_query_bits_pCrdType),
    .io_pCrd_13_query_bits_srcID(i1_io_pCrd_13_query_bits_srcID),
    .io_pCrd_13_grant(io_pCrd_13_grant),
    .io_pCrd_14_query_valid(i1_io_pCrd_14_query_valid),
    .io_pCrd_14_query_bits_pCrdType(i1_io_pCrd_14_query_bits_pCrdType),
    .io_pCrd_14_query_bits_srcID(i1_io_pCrd_14_query_bits_srcID),
    .io_pCrd_14_grant(io_pCrd_14_grant),
    .io_pCrd_15_query_valid(i1_io_pCrd_15_query_valid),
    .io_pCrd_15_query_bits_pCrdType(i1_io_pCrd_15_query_bits_pCrdType),
    .io_pCrd_15_query_bits_srcID(i1_io_pCrd_15_query_bits_srcID),
    .io_pCrd_15_grant(io_pCrd_15_grant),
    .io_perf_0_value(i1_io_perf_0_value),
    .io_perf_1_value(i1_io_perf_1_value),
    .io_perf_3_value(i1_io_perf_3_value),
    .io_perf_4_value(i1_io_perf_4_value),
    .io_perf_5_value(i1_io_perf_5_value),
    .io_perf_6_value(i1_io_perf_6_value),
    .io_perf_7_value(i1_io_perf_7_value),
    .io_perf_8_value(i1_io_perf_8_value),
    .io_perf_9_value(i1_io_perf_9_value),
    .io_perf_10_value(i1_io_perf_10_value),
    .io_perf_11_value(i1_io_perf_11_value),
    .io_perf_12_value(i1_io_perf_12_value),
    .io_perf_13_value(i1_io_perf_13_value),
    .io_perf_14_value(i1_io_perf_14_value),
    .io_perf_15_value(i1_io_perf_15_value),
    .io_perf_16_value(i1_io_perf_16_value),
    .sigFromSrams_bore_ram_hold(sigFromSrams_bore_ram_hold),
    .sigFromSrams_bore_ram_bypass(sigFromSrams_bore_ram_bypass),
    .sigFromSrams_bore_ram_bp_clken(sigFromSrams_bore_ram_bp_clken),
    .sigFromSrams_bore_ram_aux_clk(sigFromSrams_bore_ram_aux_clk),
    .sigFromSrams_bore_ram_aux_ckbp(sigFromSrams_bore_ram_aux_ckbp),
    .sigFromSrams_bore_ram_mcp_hold(sigFromSrams_bore_ram_mcp_hold),
    .sigFromSrams_bore_cgen(sigFromSrams_bore_cgen),
    .sigFromSrams_bore_1_ram_hold(sigFromSrams_bore_1_ram_hold),
    .sigFromSrams_bore_1_ram_bypass(sigFromSrams_bore_1_ram_bypass),
    .sigFromSrams_bore_1_ram_bp_clken(sigFromSrams_bore_1_ram_bp_clken),
    .sigFromSrams_bore_1_ram_aux_clk(sigFromSrams_bore_1_ram_aux_clk),
    .sigFromSrams_bore_1_ram_aux_ckbp(sigFromSrams_bore_1_ram_aux_ckbp),
    .sigFromSrams_bore_1_ram_mcp_hold(sigFromSrams_bore_1_ram_mcp_hold),
    .sigFromSrams_bore_1_cgen(sigFromSrams_bore_1_cgen),
    .sigFromSrams_bore_2_ram_hold(sigFromSrams_bore_2_ram_hold),
    .sigFromSrams_bore_2_ram_bypass(sigFromSrams_bore_2_ram_bypass),
    .sigFromSrams_bore_2_ram_bp_clken(sigFromSrams_bore_2_ram_bp_clken),
    .sigFromSrams_bore_2_ram_aux_clk(sigFromSrams_bore_2_ram_aux_clk),
    .sigFromSrams_bore_2_ram_aux_ckbp(sigFromSrams_bore_2_ram_aux_ckbp),
    .sigFromSrams_bore_2_ram_mcp_hold(sigFromSrams_bore_2_ram_mcp_hold),
    .sigFromSrams_bore_2_cgen(sigFromSrams_bore_2_cgen),
    .sigFromSrams_bore_3_ram_hold(sigFromSrams_bore_3_ram_hold),
    .sigFromSrams_bore_3_ram_bypass(sigFromSrams_bore_3_ram_bypass),
    .sigFromSrams_bore_3_ram_bp_clken(sigFromSrams_bore_3_ram_bp_clken),
    .sigFromSrams_bore_3_ram_aux_clk(sigFromSrams_bore_3_ram_aux_clk),
    .sigFromSrams_bore_3_ram_aux_ckbp(sigFromSrams_bore_3_ram_aux_ckbp),
    .sigFromSrams_bore_3_ram_mcp_hold(sigFromSrams_bore_3_ram_mcp_hold),
    .sigFromSrams_bore_3_cgen(sigFromSrams_bore_3_cgen),
    .sigFromSrams_bore_4_ram_hold(sigFromSrams_bore_4_ram_hold),
    .sigFromSrams_bore_4_ram_bypass(sigFromSrams_bore_4_ram_bypass),
    .sigFromSrams_bore_4_ram_bp_clken(sigFromSrams_bore_4_ram_bp_clken),
    .sigFromSrams_bore_4_ram_aux_clk(sigFromSrams_bore_4_ram_aux_clk),
    .sigFromSrams_bore_4_ram_aux_ckbp(sigFromSrams_bore_4_ram_aux_ckbp),
    .sigFromSrams_bore_4_ram_mcp_hold(sigFromSrams_bore_4_ram_mcp_hold),
    .sigFromSrams_bore_4_cgen(sigFromSrams_bore_4_cgen),
    .sigFromSrams_bore_5_ram_hold(sigFromSrams_bore_5_ram_hold),
    .sigFromSrams_bore_5_ram_bypass(sigFromSrams_bore_5_ram_bypass),
    .sigFromSrams_bore_5_ram_bp_clken(sigFromSrams_bore_5_ram_bp_clken),
    .sigFromSrams_bore_5_ram_aux_clk(sigFromSrams_bore_5_ram_aux_clk),
    .sigFromSrams_bore_5_ram_aux_ckbp(sigFromSrams_bore_5_ram_aux_ckbp),
    .sigFromSrams_bore_5_ram_mcp_hold(sigFromSrams_bore_5_ram_mcp_hold),
    .sigFromSrams_bore_5_cgen(sigFromSrams_bore_5_cgen),
    .sigFromSrams_bore_6_ram_hold(sigFromSrams_bore_6_ram_hold),
    .sigFromSrams_bore_6_ram_bypass(sigFromSrams_bore_6_ram_bypass),
    .sigFromSrams_bore_6_ram_bp_clken(sigFromSrams_bore_6_ram_bp_clken),
    .sigFromSrams_bore_6_ram_aux_clk(sigFromSrams_bore_6_ram_aux_clk),
    .sigFromSrams_bore_6_ram_aux_ckbp(sigFromSrams_bore_6_ram_aux_ckbp),
    .sigFromSrams_bore_6_ram_mcp_hold(sigFromSrams_bore_6_ram_mcp_hold),
    .sigFromSrams_bore_6_cgen(sigFromSrams_bore_6_cgen),
    .sigFromSrams_bore_7_ram_hold(sigFromSrams_bore_7_ram_hold),
    .sigFromSrams_bore_7_ram_bypass(sigFromSrams_bore_7_ram_bypass),
    .sigFromSrams_bore_7_ram_bp_clken(sigFromSrams_bore_7_ram_bp_clken),
    .sigFromSrams_bore_7_ram_aux_clk(sigFromSrams_bore_7_ram_aux_clk),
    .sigFromSrams_bore_7_ram_aux_ckbp(sigFromSrams_bore_7_ram_aux_ckbp),
    .sigFromSrams_bore_7_ram_mcp_hold(sigFromSrams_bore_7_ram_mcp_hold),
    .sigFromSrams_bore_7_cgen(sigFromSrams_bore_7_cgen),
    .sigFromSrams_bore_8_ram_hold(sigFromSrams_bore_8_ram_hold),
    .sigFromSrams_bore_8_ram_bypass(sigFromSrams_bore_8_ram_bypass),
    .sigFromSrams_bore_8_ram_bp_clken(sigFromSrams_bore_8_ram_bp_clken),
    .sigFromSrams_bore_8_ram_aux_clk(sigFromSrams_bore_8_ram_aux_clk),
    .sigFromSrams_bore_8_ram_aux_ckbp(sigFromSrams_bore_8_ram_aux_ckbp),
    .sigFromSrams_bore_8_ram_mcp_hold(sigFromSrams_bore_8_ram_mcp_hold),
    .sigFromSrams_bore_8_cgen(sigFromSrams_bore_8_cgen),
    .sigFromSrams_bore_9_ram_hold(sigFromSrams_bore_9_ram_hold),
    .sigFromSrams_bore_9_ram_bypass(sigFromSrams_bore_9_ram_bypass),
    .sigFromSrams_bore_9_ram_bp_clken(sigFromSrams_bore_9_ram_bp_clken),
    .sigFromSrams_bore_9_ram_aux_clk(sigFromSrams_bore_9_ram_aux_clk),
    .sigFromSrams_bore_9_ram_aux_ckbp(sigFromSrams_bore_9_ram_aux_ckbp),
    .sigFromSrams_bore_9_ram_mcp_hold(sigFromSrams_bore_9_ram_mcp_hold),
    .sigFromSrams_bore_9_cgen(sigFromSrams_bore_9_cgen),
    .sigFromSrams_bore_10_ram_hold(sigFromSrams_bore_10_ram_hold),
    .sigFromSrams_bore_10_ram_bypass(sigFromSrams_bore_10_ram_bypass),
    .sigFromSrams_bore_10_ram_bp_clken(sigFromSrams_bore_10_ram_bp_clken),
    .sigFromSrams_bore_10_ram_aux_clk(sigFromSrams_bore_10_ram_aux_clk),
    .sigFromSrams_bore_10_ram_aux_ckbp(sigFromSrams_bore_10_ram_aux_ckbp),
    .sigFromSrams_bore_10_ram_mcp_hold(sigFromSrams_bore_10_ram_mcp_hold),
    .sigFromSrams_bore_10_cgen(sigFromSrams_bore_10_cgen),
    .boreChildrenBd_bore_array(5'(boreChildrenBd_bore_array)),
    .boreChildrenBd_bore_all(boreChildrenBd_bore_all),
    .boreChildrenBd_bore_req(boreChildrenBd_bore_req),
    .boreChildrenBd_bore_ack(i1_boreChildrenBd_bore_ack),
    .boreChildrenBd_bore_writeen(boreChildrenBd_bore_writeen),
    .boreChildrenBd_bore_be(boreChildrenBd_bore_be),
    .boreChildrenBd_bore_addr(boreChildrenBd_bore_addr),
    .boreChildrenBd_bore_indata(boreChildrenBd_bore_indata),
    .boreChildrenBd_bore_readen(boreChildrenBd_bore_readen),
    .boreChildrenBd_bore_addr_rd(boreChildrenBd_bore_addr_rd),
    .boreChildrenBd_bore_outdata(i1_boreChildrenBd_bore_outdata)
  );
  Slice_2 u_g2 (
    .clock(clock),
    .reset(reset),
    .io_in_a_ready(g2_io_in_a_ready),
    .io_in_a_valid(io_in_a_valid),
    .io_in_a_bits_opcode(io_in_a_bits_opcode),
    .io_in_a_bits_param(io_in_a_bits_param),
    .io_in_a_bits_size(io_in_a_bits_size),
    .io_in_a_bits_source(io_in_a_bits_source),
    .io_in_a_bits_address(io_in_a_bits_address),
    .io_in_a_bits_user_reqSource(io_in_a_bits_user_reqSource),
    .io_in_a_bits_user_alias(io_in_a_bits_user_alias),
    .io_in_a_bits_user_vaddr(io_in_a_bits_user_vaddr),
    .io_in_a_bits_user_needHint(io_in_a_bits_user_needHint),
    .io_in_a_bits_echo_isKeyword(io_in_a_bits_echo_isKeyword),
    .io_in_a_bits_corrupt(io_in_a_bits_corrupt),
    .io_in_b_ready(io_in_b_ready),
    .io_in_b_valid(g2_io_in_b_valid),
    .io_in_b_bits_opcode(g2_io_in_b_bits_opcode),
    .io_in_b_bits_param(g2_io_in_b_bits_param),
    .io_in_b_bits_address(g2_io_in_b_bits_address),
    .io_in_b_bits_data(g2_io_in_b_bits_data),
    .io_in_c_ready(g2_io_in_c_ready),
    .io_in_c_valid(io_in_c_valid),
    .io_in_c_bits_opcode(io_in_c_bits_opcode),
    .io_in_c_bits_param(io_in_c_bits_param),
    .io_in_c_bits_size(io_in_c_bits_size),
    .io_in_c_bits_source(io_in_c_bits_source),
    .io_in_c_bits_address(io_in_c_bits_address),
    .io_in_c_bits_data(io_in_c_bits_data),
    .io_in_c_bits_corrupt(io_in_c_bits_corrupt),
    .io_in_d_ready(io_in_d_ready),
    .io_in_d_valid(g2_io_in_d_valid),
    .io_in_d_bits_opcode(g2_io_in_d_bits_opcode),
    .io_in_d_bits_param(g2_io_in_d_bits_param),
    .io_in_d_bits_source(g2_io_in_d_bits_source),
    .io_in_d_bits_sink(g2_io_in_d_bits_sink),
    .io_in_d_bits_denied(g2_io_in_d_bits_denied),
    .io_in_d_bits_echo_isKeyword(g2_io_in_d_bits_echo_isKeyword),
    .io_in_d_bits_data(g2_io_in_d_bits_data),
    .io_in_d_bits_corrupt(g2_io_in_d_bits_corrupt),
    .io_in_e_valid(io_in_e_valid),
    .io_in_e_bits_sink(io_in_e_bits_sink),
    .io_l1Hint_ready(io_l1Hint_ready),
    .io_l1Hint_valid(g2_io_l1Hint_valid),
    .io_l1Hint_bits_sourceId(g2_io_l1Hint_bits_sourceId),
    .io_l1Hint_bits_isKeyword(g2_io_l1Hint_bits_isKeyword),
    .io_prefetch_train_ready(io_prefetch_train_ready),
    .io_prefetch_train_valid(g2_io_prefetch_train_valid),
    .io_prefetch_train_bits_tag(g2_io_prefetch_train_bits_tag),
    .io_prefetch_train_bits_set(g2_io_prefetch_train_bits_set),
    .io_prefetch_train_bits_needT(g2_io_prefetch_train_bits_needT),
    .io_prefetch_train_bits_source(g2_io_prefetch_train_bits_source),
    .io_prefetch_train_bits_vaddr(g2_io_prefetch_train_bits_vaddr),
    .io_prefetch_train_bits_hit(g2_io_prefetch_train_bits_hit),
    .io_prefetch_train_bits_prefetched(g2_io_prefetch_train_bits_prefetched),
    .io_prefetch_train_bits_pfsource(g2_io_prefetch_train_bits_pfsource),
    .io_prefetch_train_bits_reqsource(g2_io_prefetch_train_bits_reqsource),
    .io_prefetch_req_ready(g2_io_prefetch_req_ready),
    .io_prefetch_req_valid(io_prefetch_req_valid),
    .io_prefetch_req_bits_tag(io_prefetch_req_bits_tag),
    .io_prefetch_req_bits_set(io_prefetch_req_bits_set),
    .io_prefetch_req_bits_vaddr(io_prefetch_req_bits_vaddr),
    .io_prefetch_req_bits_needT(io_prefetch_req_bits_needT),
    .io_prefetch_req_bits_source(io_prefetch_req_bits_source),
    .io_prefetch_req_bits_pfSource(io_prefetch_req_bits_pfSource),
    .io_prefetch_resp_ready(io_prefetch_resp_ready),
    .io_prefetch_resp_valid(g2_io_prefetch_resp_valid),
    .io_prefetch_resp_bits_tag(g2_io_prefetch_resp_bits_tag),
    .io_prefetch_resp_bits_set(g2_io_prefetch_resp_bits_set),
    .io_prefetch_resp_bits_vaddr(g2_io_prefetch_resp_bits_vaddr),
    .io_prefetch_resp_bits_pfSource(g2_io_prefetch_resp_bits_pfSource),
    .io_dirResult_valid(g2_io_dirResult_valid),
    .io_dirResult_bits_hit(g2_io_dirResult_bits_hit),
    .io_dirResult_bits_meta_prefetch(g2_io_dirResult_bits_meta_prefetch),
    .io_dirResult_bits_meta_prefetchSrc(g2_io_dirResult_bits_meta_prefetchSrc),
    .io_dirResult_bits_replacerInfo_channel(g2_io_dirResult_bits_replacerInfo_channel),
    .io_dirResult_bits_replacerInfo_reqSource(g2_io_dirResult_bits_replacerInfo_reqSource),
    .io_hitPfInMSHR_valid(g2_io_hitPfInMSHR_valid),
    .io_hitPfInMSHR_bits(g2_io_hitPfInMSHR_bits),
    .io_pfSent_valid(g2_io_pfSent_valid),
    .io_pfSent_bits(g2_io_pfSent_bits),
    .io_pfLateInMSHR_valid(g2_io_pfLateInMSHR_valid),
    .io_pfLateInMSHR_bits(g2_io_pfLateInMSHR_bits),
    .io_error_valid(g2_io_error_valid),
    .io_error_bits_valid(g2_io_error_bits_valid),
    .io_error_bits_address(g2_io_error_bits_address),
    .io_l2Miss(g2_io_l2Miss),
    .io_msStatus_0_valid(g2_io_msStatus_0_valid),
    .io_msStatus_0_bits_channel(g2_io_msStatus_0_bits_channel),
    .io_msStatus_0_bits_set(g2_io_msStatus_0_bits_set),
    .io_msStatus_0_bits_reqTag(g2_io_msStatus_0_bits_reqTag),
    .io_msStatus_0_bits_is_miss(g2_io_msStatus_0_bits_is_miss),
    .io_msStatus_0_bits_is_prefetch(g2_io_msStatus_0_bits_is_prefetch),
    .io_msStatus_1_valid(g2_io_msStatus_1_valid),
    .io_msStatus_1_bits_channel(g2_io_msStatus_1_bits_channel),
    .io_msStatus_1_bits_set(g2_io_msStatus_1_bits_set),
    .io_msStatus_1_bits_reqTag(g2_io_msStatus_1_bits_reqTag),
    .io_msStatus_1_bits_is_miss(g2_io_msStatus_1_bits_is_miss),
    .io_msStatus_1_bits_is_prefetch(g2_io_msStatus_1_bits_is_prefetch),
    .io_msStatus_2_valid(g2_io_msStatus_2_valid),
    .io_msStatus_2_bits_channel(g2_io_msStatus_2_bits_channel),
    .io_msStatus_2_bits_set(g2_io_msStatus_2_bits_set),
    .io_msStatus_2_bits_reqTag(g2_io_msStatus_2_bits_reqTag),
    .io_msStatus_2_bits_is_miss(g2_io_msStatus_2_bits_is_miss),
    .io_msStatus_2_bits_is_prefetch(g2_io_msStatus_2_bits_is_prefetch),
    .io_msStatus_3_valid(g2_io_msStatus_3_valid),
    .io_msStatus_3_bits_channel(g2_io_msStatus_3_bits_channel),
    .io_msStatus_3_bits_set(g2_io_msStatus_3_bits_set),
    .io_msStatus_3_bits_reqTag(g2_io_msStatus_3_bits_reqTag),
    .io_msStatus_3_bits_is_miss(g2_io_msStatus_3_bits_is_miss),
    .io_msStatus_3_bits_is_prefetch(g2_io_msStatus_3_bits_is_prefetch),
    .io_msStatus_4_valid(g2_io_msStatus_4_valid),
    .io_msStatus_4_bits_channel(g2_io_msStatus_4_bits_channel),
    .io_msStatus_4_bits_set(g2_io_msStatus_4_bits_set),
    .io_msStatus_4_bits_reqTag(g2_io_msStatus_4_bits_reqTag),
    .io_msStatus_4_bits_is_miss(g2_io_msStatus_4_bits_is_miss),
    .io_msStatus_4_bits_is_prefetch(g2_io_msStatus_4_bits_is_prefetch),
    .io_msStatus_5_valid(g2_io_msStatus_5_valid),
    .io_msStatus_5_bits_channel(g2_io_msStatus_5_bits_channel),
    .io_msStatus_5_bits_set(g2_io_msStatus_5_bits_set),
    .io_msStatus_5_bits_reqTag(g2_io_msStatus_5_bits_reqTag),
    .io_msStatus_5_bits_is_miss(g2_io_msStatus_5_bits_is_miss),
    .io_msStatus_5_bits_is_prefetch(g2_io_msStatus_5_bits_is_prefetch),
    .io_msStatus_6_valid(g2_io_msStatus_6_valid),
    .io_msStatus_6_bits_channel(g2_io_msStatus_6_bits_channel),
    .io_msStatus_6_bits_set(g2_io_msStatus_6_bits_set),
    .io_msStatus_6_bits_reqTag(g2_io_msStatus_6_bits_reqTag),
    .io_msStatus_6_bits_is_miss(g2_io_msStatus_6_bits_is_miss),
    .io_msStatus_6_bits_is_prefetch(g2_io_msStatus_6_bits_is_prefetch),
    .io_msStatus_7_valid(g2_io_msStatus_7_valid),
    .io_msStatus_7_bits_channel(g2_io_msStatus_7_bits_channel),
    .io_msStatus_7_bits_set(g2_io_msStatus_7_bits_set),
    .io_msStatus_7_bits_reqTag(g2_io_msStatus_7_bits_reqTag),
    .io_msStatus_7_bits_is_miss(g2_io_msStatus_7_bits_is_miss),
    .io_msStatus_7_bits_is_prefetch(g2_io_msStatus_7_bits_is_prefetch),
    .io_msStatus_8_valid(g2_io_msStatus_8_valid),
    .io_msStatus_8_bits_channel(g2_io_msStatus_8_bits_channel),
    .io_msStatus_8_bits_set(g2_io_msStatus_8_bits_set),
    .io_msStatus_8_bits_reqTag(g2_io_msStatus_8_bits_reqTag),
    .io_msStatus_8_bits_is_miss(g2_io_msStatus_8_bits_is_miss),
    .io_msStatus_8_bits_is_prefetch(g2_io_msStatus_8_bits_is_prefetch),
    .io_msStatus_9_valid(g2_io_msStatus_9_valid),
    .io_msStatus_9_bits_channel(g2_io_msStatus_9_bits_channel),
    .io_msStatus_9_bits_set(g2_io_msStatus_9_bits_set),
    .io_msStatus_9_bits_reqTag(g2_io_msStatus_9_bits_reqTag),
    .io_msStatus_9_bits_is_miss(g2_io_msStatus_9_bits_is_miss),
    .io_msStatus_9_bits_is_prefetch(g2_io_msStatus_9_bits_is_prefetch),
    .io_msStatus_10_valid(g2_io_msStatus_10_valid),
    .io_msStatus_10_bits_channel(g2_io_msStatus_10_bits_channel),
    .io_msStatus_10_bits_set(g2_io_msStatus_10_bits_set),
    .io_msStatus_10_bits_reqTag(g2_io_msStatus_10_bits_reqTag),
    .io_msStatus_10_bits_is_miss(g2_io_msStatus_10_bits_is_miss),
    .io_msStatus_10_bits_is_prefetch(g2_io_msStatus_10_bits_is_prefetch),
    .io_msStatus_11_valid(g2_io_msStatus_11_valid),
    .io_msStatus_11_bits_channel(g2_io_msStatus_11_bits_channel),
    .io_msStatus_11_bits_set(g2_io_msStatus_11_bits_set),
    .io_msStatus_11_bits_reqTag(g2_io_msStatus_11_bits_reqTag),
    .io_msStatus_11_bits_is_miss(g2_io_msStatus_11_bits_is_miss),
    .io_msStatus_11_bits_is_prefetch(g2_io_msStatus_11_bits_is_prefetch),
    .io_msStatus_12_valid(g2_io_msStatus_12_valid),
    .io_msStatus_12_bits_channel(g2_io_msStatus_12_bits_channel),
    .io_msStatus_12_bits_set(g2_io_msStatus_12_bits_set),
    .io_msStatus_12_bits_reqTag(g2_io_msStatus_12_bits_reqTag),
    .io_msStatus_12_bits_is_miss(g2_io_msStatus_12_bits_is_miss),
    .io_msStatus_12_bits_is_prefetch(g2_io_msStatus_12_bits_is_prefetch),
    .io_msStatus_13_valid(g2_io_msStatus_13_valid),
    .io_msStatus_13_bits_channel(g2_io_msStatus_13_bits_channel),
    .io_msStatus_13_bits_set(g2_io_msStatus_13_bits_set),
    .io_msStatus_13_bits_reqTag(g2_io_msStatus_13_bits_reqTag),
    .io_msStatus_13_bits_is_miss(g2_io_msStatus_13_bits_is_miss),
    .io_msStatus_13_bits_is_prefetch(g2_io_msStatus_13_bits_is_prefetch),
    .io_msStatus_14_valid(g2_io_msStatus_14_valid),
    .io_msStatus_14_bits_channel(g2_io_msStatus_14_bits_channel),
    .io_msStatus_14_bits_set(g2_io_msStatus_14_bits_set),
    .io_msStatus_14_bits_reqTag(g2_io_msStatus_14_bits_reqTag),
    .io_msStatus_14_bits_is_miss(g2_io_msStatus_14_bits_is_miss),
    .io_msStatus_14_bits_is_prefetch(g2_io_msStatus_14_bits_is_prefetch),
    .io_msStatus_15_valid(g2_io_msStatus_15_valid),
    .io_msStatus_15_bits_channel(g2_io_msStatus_15_bits_channel),
    .io_msStatus_15_bits_set(g2_io_msStatus_15_bits_set),
    .io_msStatus_15_bits_reqTag(g2_io_msStatus_15_bits_reqTag),
    .io_msStatus_15_bits_is_miss(g2_io_msStatus_15_bits_is_miss),
    .io_msStatus_15_bits_is_prefetch(g2_io_msStatus_15_bits_is_prefetch),
    .io_msAlloc_0_valid(g2_io_msAlloc_0_valid),
    .io_msAlloc_0_bits_channel(g2_io_msAlloc_0_bits_channel),
    .io_msAlloc_0_bits_is_miss(g2_io_msAlloc_0_bits_is_miss),
    .io_msAlloc_0_bits_is_prefetch(g2_io_msAlloc_0_bits_is_prefetch),
    .io_msAlloc_1_valid(g2_io_msAlloc_1_valid),
    .io_msAlloc_1_bits_channel(g2_io_msAlloc_1_bits_channel),
    .io_msAlloc_1_bits_is_miss(g2_io_msAlloc_1_bits_is_miss),
    .io_msAlloc_1_bits_is_prefetch(g2_io_msAlloc_1_bits_is_prefetch),
    .io_msAlloc_2_valid(g2_io_msAlloc_2_valid),
    .io_msAlloc_2_bits_channel(g2_io_msAlloc_2_bits_channel),
    .io_msAlloc_2_bits_is_miss(g2_io_msAlloc_2_bits_is_miss),
    .io_msAlloc_2_bits_is_prefetch(g2_io_msAlloc_2_bits_is_prefetch),
    .io_msAlloc_3_valid(g2_io_msAlloc_3_valid),
    .io_msAlloc_3_bits_channel(g2_io_msAlloc_3_bits_channel),
    .io_msAlloc_3_bits_is_miss(g2_io_msAlloc_3_bits_is_miss),
    .io_msAlloc_3_bits_is_prefetch(g2_io_msAlloc_3_bits_is_prefetch),
    .io_msAlloc_4_valid(g2_io_msAlloc_4_valid),
    .io_msAlloc_4_bits_channel(g2_io_msAlloc_4_bits_channel),
    .io_msAlloc_4_bits_is_miss(g2_io_msAlloc_4_bits_is_miss),
    .io_msAlloc_4_bits_is_prefetch(g2_io_msAlloc_4_bits_is_prefetch),
    .io_msAlloc_5_valid(g2_io_msAlloc_5_valid),
    .io_msAlloc_5_bits_channel(g2_io_msAlloc_5_bits_channel),
    .io_msAlloc_5_bits_is_miss(g2_io_msAlloc_5_bits_is_miss),
    .io_msAlloc_5_bits_is_prefetch(g2_io_msAlloc_5_bits_is_prefetch),
    .io_msAlloc_6_valid(g2_io_msAlloc_6_valid),
    .io_msAlloc_6_bits_channel(g2_io_msAlloc_6_bits_channel),
    .io_msAlloc_6_bits_is_miss(g2_io_msAlloc_6_bits_is_miss),
    .io_msAlloc_6_bits_is_prefetch(g2_io_msAlloc_6_bits_is_prefetch),
    .io_msAlloc_7_valid(g2_io_msAlloc_7_valid),
    .io_msAlloc_7_bits_channel(g2_io_msAlloc_7_bits_channel),
    .io_msAlloc_7_bits_is_miss(g2_io_msAlloc_7_bits_is_miss),
    .io_msAlloc_7_bits_is_prefetch(g2_io_msAlloc_7_bits_is_prefetch),
    .io_msAlloc_8_valid(g2_io_msAlloc_8_valid),
    .io_msAlloc_8_bits_channel(g2_io_msAlloc_8_bits_channel),
    .io_msAlloc_8_bits_is_miss(g2_io_msAlloc_8_bits_is_miss),
    .io_msAlloc_8_bits_is_prefetch(g2_io_msAlloc_8_bits_is_prefetch),
    .io_msAlloc_9_valid(g2_io_msAlloc_9_valid),
    .io_msAlloc_9_bits_channel(g2_io_msAlloc_9_bits_channel),
    .io_msAlloc_9_bits_is_miss(g2_io_msAlloc_9_bits_is_miss),
    .io_msAlloc_9_bits_is_prefetch(g2_io_msAlloc_9_bits_is_prefetch),
    .io_msAlloc_10_valid(g2_io_msAlloc_10_valid),
    .io_msAlloc_10_bits_channel(g2_io_msAlloc_10_bits_channel),
    .io_msAlloc_10_bits_is_miss(g2_io_msAlloc_10_bits_is_miss),
    .io_msAlloc_10_bits_is_prefetch(g2_io_msAlloc_10_bits_is_prefetch),
    .io_msAlloc_11_valid(g2_io_msAlloc_11_valid),
    .io_msAlloc_11_bits_channel(g2_io_msAlloc_11_bits_channel),
    .io_msAlloc_11_bits_is_miss(g2_io_msAlloc_11_bits_is_miss),
    .io_msAlloc_11_bits_is_prefetch(g2_io_msAlloc_11_bits_is_prefetch),
    .io_msAlloc_12_valid(g2_io_msAlloc_12_valid),
    .io_msAlloc_12_bits_channel(g2_io_msAlloc_12_bits_channel),
    .io_msAlloc_12_bits_is_miss(g2_io_msAlloc_12_bits_is_miss),
    .io_msAlloc_12_bits_is_prefetch(g2_io_msAlloc_12_bits_is_prefetch),
    .io_msAlloc_13_valid(g2_io_msAlloc_13_valid),
    .io_msAlloc_13_bits_channel(g2_io_msAlloc_13_bits_channel),
    .io_msAlloc_13_bits_is_miss(g2_io_msAlloc_13_bits_is_miss),
    .io_msAlloc_13_bits_is_prefetch(g2_io_msAlloc_13_bits_is_prefetch),
    .io_msAlloc_14_valid(g2_io_msAlloc_14_valid),
    .io_msAlloc_14_bits_channel(g2_io_msAlloc_14_bits_channel),
    .io_msAlloc_14_bits_is_miss(g2_io_msAlloc_14_bits_is_miss),
    .io_msAlloc_14_bits_is_prefetch(g2_io_msAlloc_14_bits_is_prefetch),
    .io_msAlloc_15_valid(g2_io_msAlloc_15_valid),
    .io_msAlloc_15_bits_channel(g2_io_msAlloc_15_bits_channel),
    .io_msAlloc_15_bits_is_miss(g2_io_msAlloc_15_bits_is_miss),
    .io_msAlloc_15_bits_is_prefetch(g2_io_msAlloc_15_bits_is_prefetch),
    .io_out_tx_req_ready(io_out_tx_req_ready),
    .io_out_tx_req_valid(g2_io_out_tx_req_valid),
    .io_out_tx_req_bits_qos(g2_io_out_tx_req_bits_qos),
    .io_out_tx_req_bits_txnID(g2_io_out_tx_req_bits_txnID),
    .io_out_tx_req_bits_returnNID(g2_io_out_tx_req_bits_returnNID),
    .io_out_tx_req_bits_stashNIDValid(g2_io_out_tx_req_bits_stashNIDValid),
    .io_out_tx_req_bits_returnTxnID(g2_io_out_tx_req_bits_returnTxnID),
    .io_out_tx_req_bits_opcode(g2_io_out_tx_req_bits_opcode),
    .io_out_tx_req_bits_addr(g2_io_out_tx_req_bits_addr),
    .io_out_tx_req_bits_ns(g2_io_out_tx_req_bits_ns),
    .io_out_tx_req_bits_likelyshared(g2_io_out_tx_req_bits_likelyshared),
    .io_out_tx_req_bits_allowRetry(g2_io_out_tx_req_bits_allowRetry),
    .io_out_tx_req_bits_order(g2_io_out_tx_req_bits_order),
    .io_out_tx_req_bits_pCrdType(g2_io_out_tx_req_bits_pCrdType),
    .io_out_tx_req_bits_memAttr_allocate(g2_io_out_tx_req_bits_memAttr_allocate),
    .io_out_tx_req_bits_memAttr_cacheable(g2_io_out_tx_req_bits_memAttr_cacheable),
    .io_out_tx_req_bits_memAttr_device(g2_io_out_tx_req_bits_memAttr_device),
    .io_out_tx_req_bits_memAttr_ewa(g2_io_out_tx_req_bits_memAttr_ewa),
    .io_out_tx_req_bits_snpAttr(g2_io_out_tx_req_bits_snpAttr),
    .io_out_tx_req_bits_lpIDWithPadding(g2_io_out_tx_req_bits_lpIDWithPadding),
    .io_out_tx_req_bits_snoopMe(g2_io_out_tx_req_bits_snoopMe),
    .io_out_tx_req_bits_expCompAck(g2_io_out_tx_req_bits_expCompAck),
    .io_out_tx_req_bits_tagOp(g2_io_out_tx_req_bits_tagOp),
    .io_out_tx_req_bits_traceTag(g2_io_out_tx_req_bits_traceTag),
    .io_out_tx_req_bits_mpam_perfMonGroup(g2_io_out_tx_req_bits_mpam_perfMonGroup),
    .io_out_tx_req_bits_mpam_partID(g2_io_out_tx_req_bits_mpam_partID),
    .io_out_tx_req_bits_mpam_mpamNS(g2_io_out_tx_req_bits_mpam_mpamNS),
    .io_out_tx_req_bits_rsvdc(g2_io_out_tx_req_bits_rsvdc),
    .io_out_tx_rsp_ready(io_out_tx_rsp_ready),
    .io_out_tx_rsp_valid(g2_io_out_tx_rsp_valid),
    .io_out_tx_rsp_bits_qos(g2_io_out_tx_rsp_bits_qos),
    .io_out_tx_rsp_bits_tgtID(g2_io_out_tx_rsp_bits_tgtID),
    .io_out_tx_rsp_bits_txnID(g2_io_out_tx_rsp_bits_txnID),
    .io_out_tx_rsp_bits_opcode(g2_io_out_tx_rsp_bits_opcode),
    .io_out_tx_rsp_bits_respErr(g2_io_out_tx_rsp_bits_respErr),
    .io_out_tx_rsp_bits_resp(g2_io_out_tx_rsp_bits_resp),
    .io_out_tx_rsp_bits_fwdState(g2_io_out_tx_rsp_bits_fwdState),
    .io_out_tx_rsp_bits_cBusy(g2_io_out_tx_rsp_bits_cBusy),
    .io_out_tx_rsp_bits_dbID(g2_io_out_tx_rsp_bits_dbID),
    .io_out_tx_rsp_bits_pCrdType(g2_io_out_tx_rsp_bits_pCrdType),
    .io_out_tx_rsp_bits_tagOp(g2_io_out_tx_rsp_bits_tagOp),
    .io_out_tx_rsp_bits_traceTag(g2_io_out_tx_rsp_bits_traceTag),
    .io_out_tx_dat_ready(io_out_tx_dat_ready),
    .io_out_tx_dat_valid(g2_io_out_tx_dat_valid),
    .io_out_tx_dat_bits_tgtID(g2_io_out_tx_dat_bits_tgtID),
    .io_out_tx_dat_bits_txnID(g2_io_out_tx_dat_bits_txnID),
    .io_out_tx_dat_bits_homeNID(g2_io_out_tx_dat_bits_homeNID),
    .io_out_tx_dat_bits_opcode(g2_io_out_tx_dat_bits_opcode),
    .io_out_tx_dat_bits_respErr(g2_io_out_tx_dat_bits_respErr),
    .io_out_tx_dat_bits_resp(g2_io_out_tx_dat_bits_resp),
    .io_out_tx_dat_bits_dataSource(g2_io_out_tx_dat_bits_dataSource),
    .io_out_tx_dat_bits_dbID(g2_io_out_tx_dat_bits_dbID),
    .io_out_tx_dat_bits_ccID(g2_io_out_tx_dat_bits_ccID),
    .io_out_tx_dat_bits_dataID(g2_io_out_tx_dat_bits_dataID),
    .io_out_tx_dat_bits_traceTag(g2_io_out_tx_dat_bits_traceTag),
    .io_out_tx_dat_bits_be(g2_io_out_tx_dat_bits_be),
    .io_out_tx_dat_bits_data(g2_io_out_tx_dat_bits_data),
    .io_out_tx_dat_bits_dataCheck(g2_io_out_tx_dat_bits_dataCheck),
    .io_out_tx_dat_bits_poison(g2_io_out_tx_dat_bits_poison),
    .io_out_rx_rsp_valid(io_out_rx_rsp_valid),
    .io_out_rx_rsp_bits_srcID(io_out_rx_rsp_bits_srcID),
    .io_out_rx_rsp_bits_txnID(io_out_rx_rsp_bits_txnID),
    .io_out_rx_rsp_bits_opcode(io_out_rx_rsp_bits_opcode),
    .io_out_rx_rsp_bits_respErr(io_out_rx_rsp_bits_respErr),
    .io_out_rx_rsp_bits_resp(io_out_rx_rsp_bits_resp),
    .io_out_rx_rsp_bits_dbID(io_out_rx_rsp_bits_dbID),
    .io_out_rx_rsp_bits_pCrdType(io_out_rx_rsp_bits_pCrdType),
    .io_out_rx_rsp_bits_traceTag(io_out_rx_rsp_bits_traceTag),
    .io_out_rx_dat_valid(io_out_rx_dat_valid),
    .io_out_rx_dat_bits_txnID(io_out_rx_dat_bits_txnID),
    .io_out_rx_dat_bits_homeNID(io_out_rx_dat_bits_homeNID),
    .io_out_rx_dat_bits_opcode(io_out_rx_dat_bits_opcode),
    .io_out_rx_dat_bits_respErr(io_out_rx_dat_bits_respErr),
    .io_out_rx_dat_bits_resp(io_out_rx_dat_bits_resp),
    .io_out_rx_dat_bits_dbID(io_out_rx_dat_bits_dbID),
    .io_out_rx_dat_bits_dataID(io_out_rx_dat_bits_dataID),
    .io_out_rx_dat_bits_traceTag(io_out_rx_dat_bits_traceTag),
    .io_out_rx_dat_bits_data(io_out_rx_dat_bits_data),
    .io_out_rx_dat_bits_dataCheck(io_out_rx_dat_bits_dataCheck),
    .io_out_rx_dat_bits_poison(io_out_rx_dat_bits_poison),
    .io_out_rx_snp_ready(g2_io_out_rx_snp_ready),
    .io_out_rx_snp_valid(io_out_rx_snp_valid),
    .io_out_rx_snp_bits_qos(io_out_rx_snp_bits_qos),
    .io_out_rx_snp_bits_srcID(io_out_rx_snp_bits_srcID),
    .io_out_rx_snp_bits_txnID(io_out_rx_snp_bits_txnID),
    .io_out_rx_snp_bits_fwdNID(io_out_rx_snp_bits_fwdNID),
    .io_out_rx_snp_bits_fwdTxnID(io_out_rx_snp_bits_fwdTxnID),
    .io_out_rx_snp_bits_opcode(io_out_rx_snp_bits_opcode),
    .io_out_rx_snp_bits_addr(io_out_rx_snp_bits_addr),
    .io_out_rx_snp_bits_ns(io_out_rx_snp_bits_ns),
    .io_out_rx_snp_bits_doNotGoToSD(io_out_rx_snp_bits_doNotGoToSD),
    .io_out_rx_snp_bits_retToSrc(io_out_rx_snp_bits_retToSrc),
    .io_out_rx_snp_bits_traceTag(io_out_rx_snp_bits_traceTag),
    .io_out_rx_snp_bits_mpam_perfMonGroup(io_out_rx_snp_bits_mpam_perfMonGroup),
    .io_out_rx_snp_bits_mpam_partID(io_out_rx_snp_bits_mpam_partID),
    .io_out_rx_snp_bits_mpam_mpamNS(io_out_rx_snp_bits_mpam_mpamNS),
    .io_pCrd_0_query_valid(g2_io_pCrd_0_query_valid),
    .io_pCrd_0_query_bits_pCrdType(g2_io_pCrd_0_query_bits_pCrdType),
    .io_pCrd_0_query_bits_srcID(g2_io_pCrd_0_query_bits_srcID),
    .io_pCrd_0_grant(io_pCrd_0_grant),
    .io_pCrd_1_query_valid(g2_io_pCrd_1_query_valid),
    .io_pCrd_1_query_bits_pCrdType(g2_io_pCrd_1_query_bits_pCrdType),
    .io_pCrd_1_query_bits_srcID(g2_io_pCrd_1_query_bits_srcID),
    .io_pCrd_1_grant(io_pCrd_1_grant),
    .io_pCrd_2_query_valid(g2_io_pCrd_2_query_valid),
    .io_pCrd_2_query_bits_pCrdType(g2_io_pCrd_2_query_bits_pCrdType),
    .io_pCrd_2_query_bits_srcID(g2_io_pCrd_2_query_bits_srcID),
    .io_pCrd_2_grant(io_pCrd_2_grant),
    .io_pCrd_3_query_valid(g2_io_pCrd_3_query_valid),
    .io_pCrd_3_query_bits_pCrdType(g2_io_pCrd_3_query_bits_pCrdType),
    .io_pCrd_3_query_bits_srcID(g2_io_pCrd_3_query_bits_srcID),
    .io_pCrd_3_grant(io_pCrd_3_grant),
    .io_pCrd_4_query_valid(g2_io_pCrd_4_query_valid),
    .io_pCrd_4_query_bits_pCrdType(g2_io_pCrd_4_query_bits_pCrdType),
    .io_pCrd_4_query_bits_srcID(g2_io_pCrd_4_query_bits_srcID),
    .io_pCrd_4_grant(io_pCrd_4_grant),
    .io_pCrd_5_query_valid(g2_io_pCrd_5_query_valid),
    .io_pCrd_5_query_bits_pCrdType(g2_io_pCrd_5_query_bits_pCrdType),
    .io_pCrd_5_query_bits_srcID(g2_io_pCrd_5_query_bits_srcID),
    .io_pCrd_5_grant(io_pCrd_5_grant),
    .io_pCrd_6_query_valid(g2_io_pCrd_6_query_valid),
    .io_pCrd_6_query_bits_pCrdType(g2_io_pCrd_6_query_bits_pCrdType),
    .io_pCrd_6_query_bits_srcID(g2_io_pCrd_6_query_bits_srcID),
    .io_pCrd_6_grant(io_pCrd_6_grant),
    .io_pCrd_7_query_valid(g2_io_pCrd_7_query_valid),
    .io_pCrd_7_query_bits_pCrdType(g2_io_pCrd_7_query_bits_pCrdType),
    .io_pCrd_7_query_bits_srcID(g2_io_pCrd_7_query_bits_srcID),
    .io_pCrd_7_grant(io_pCrd_7_grant),
    .io_pCrd_8_query_valid(g2_io_pCrd_8_query_valid),
    .io_pCrd_8_query_bits_pCrdType(g2_io_pCrd_8_query_bits_pCrdType),
    .io_pCrd_8_query_bits_srcID(g2_io_pCrd_8_query_bits_srcID),
    .io_pCrd_8_grant(io_pCrd_8_grant),
    .io_pCrd_9_query_valid(g2_io_pCrd_9_query_valid),
    .io_pCrd_9_query_bits_pCrdType(g2_io_pCrd_9_query_bits_pCrdType),
    .io_pCrd_9_query_bits_srcID(g2_io_pCrd_9_query_bits_srcID),
    .io_pCrd_9_grant(io_pCrd_9_grant),
    .io_pCrd_10_query_valid(g2_io_pCrd_10_query_valid),
    .io_pCrd_10_query_bits_pCrdType(g2_io_pCrd_10_query_bits_pCrdType),
    .io_pCrd_10_query_bits_srcID(g2_io_pCrd_10_query_bits_srcID),
    .io_pCrd_10_grant(io_pCrd_10_grant),
    .io_pCrd_11_query_valid(g2_io_pCrd_11_query_valid),
    .io_pCrd_11_query_bits_pCrdType(g2_io_pCrd_11_query_bits_pCrdType),
    .io_pCrd_11_query_bits_srcID(g2_io_pCrd_11_query_bits_srcID),
    .io_pCrd_11_grant(io_pCrd_11_grant),
    .io_pCrd_12_query_valid(g2_io_pCrd_12_query_valid),
    .io_pCrd_12_query_bits_pCrdType(g2_io_pCrd_12_query_bits_pCrdType),
    .io_pCrd_12_query_bits_srcID(g2_io_pCrd_12_query_bits_srcID),
    .io_pCrd_12_grant(io_pCrd_12_grant),
    .io_pCrd_13_query_valid(g2_io_pCrd_13_query_valid),
    .io_pCrd_13_query_bits_pCrdType(g2_io_pCrd_13_query_bits_pCrdType),
    .io_pCrd_13_query_bits_srcID(g2_io_pCrd_13_query_bits_srcID),
    .io_pCrd_13_grant(io_pCrd_13_grant),
    .io_pCrd_14_query_valid(g2_io_pCrd_14_query_valid),
    .io_pCrd_14_query_bits_pCrdType(g2_io_pCrd_14_query_bits_pCrdType),
    .io_pCrd_14_query_bits_srcID(g2_io_pCrd_14_query_bits_srcID),
    .io_pCrd_14_grant(io_pCrd_14_grant),
    .io_pCrd_15_query_valid(g2_io_pCrd_15_query_valid),
    .io_pCrd_15_query_bits_pCrdType(g2_io_pCrd_15_query_bits_pCrdType),
    .io_pCrd_15_query_bits_srcID(g2_io_pCrd_15_query_bits_srcID),
    .io_pCrd_15_grant(io_pCrd_15_grant),
    .io_perf_0_value(g2_io_perf_0_value),
    .io_perf_1_value(g2_io_perf_1_value),
    .io_perf_3_value(g2_io_perf_3_value),
    .io_perf_4_value(g2_io_perf_4_value),
    .io_perf_5_value(g2_io_perf_5_value),
    .io_perf_6_value(g2_io_perf_6_value),
    .io_perf_7_value(g2_io_perf_7_value),
    .io_perf_8_value(g2_io_perf_8_value),
    .io_perf_9_value(g2_io_perf_9_value),
    .io_perf_10_value(g2_io_perf_10_value),
    .io_perf_11_value(g2_io_perf_11_value),
    .io_perf_12_value(g2_io_perf_12_value),
    .io_perf_13_value(g2_io_perf_13_value),
    .io_perf_14_value(g2_io_perf_14_value),
    .io_perf_15_value(g2_io_perf_15_value),
    .io_perf_16_value(g2_io_perf_16_value),
    .sigFromSrams_bore_ram_hold(sigFromSrams_bore_ram_hold),
    .sigFromSrams_bore_ram_bypass(sigFromSrams_bore_ram_bypass),
    .sigFromSrams_bore_ram_bp_clken(sigFromSrams_bore_ram_bp_clken),
    .sigFromSrams_bore_ram_aux_clk(sigFromSrams_bore_ram_aux_clk),
    .sigFromSrams_bore_ram_aux_ckbp(sigFromSrams_bore_ram_aux_ckbp),
    .sigFromSrams_bore_ram_mcp_hold(sigFromSrams_bore_ram_mcp_hold),
    .sigFromSrams_bore_cgen(sigFromSrams_bore_cgen),
    .sigFromSrams_bore_1_ram_hold(sigFromSrams_bore_1_ram_hold),
    .sigFromSrams_bore_1_ram_bypass(sigFromSrams_bore_1_ram_bypass),
    .sigFromSrams_bore_1_ram_bp_clken(sigFromSrams_bore_1_ram_bp_clken),
    .sigFromSrams_bore_1_ram_aux_clk(sigFromSrams_bore_1_ram_aux_clk),
    .sigFromSrams_bore_1_ram_aux_ckbp(sigFromSrams_bore_1_ram_aux_ckbp),
    .sigFromSrams_bore_1_ram_mcp_hold(sigFromSrams_bore_1_ram_mcp_hold),
    .sigFromSrams_bore_1_cgen(sigFromSrams_bore_1_cgen),
    .sigFromSrams_bore_2_ram_hold(sigFromSrams_bore_2_ram_hold),
    .sigFromSrams_bore_2_ram_bypass(sigFromSrams_bore_2_ram_bypass),
    .sigFromSrams_bore_2_ram_bp_clken(sigFromSrams_bore_2_ram_bp_clken),
    .sigFromSrams_bore_2_ram_aux_clk(sigFromSrams_bore_2_ram_aux_clk),
    .sigFromSrams_bore_2_ram_aux_ckbp(sigFromSrams_bore_2_ram_aux_ckbp),
    .sigFromSrams_bore_2_ram_mcp_hold(sigFromSrams_bore_2_ram_mcp_hold),
    .sigFromSrams_bore_2_cgen(sigFromSrams_bore_2_cgen),
    .sigFromSrams_bore_3_ram_hold(sigFromSrams_bore_3_ram_hold),
    .sigFromSrams_bore_3_ram_bypass(sigFromSrams_bore_3_ram_bypass),
    .sigFromSrams_bore_3_ram_bp_clken(sigFromSrams_bore_3_ram_bp_clken),
    .sigFromSrams_bore_3_ram_aux_clk(sigFromSrams_bore_3_ram_aux_clk),
    .sigFromSrams_bore_3_ram_aux_ckbp(sigFromSrams_bore_3_ram_aux_ckbp),
    .sigFromSrams_bore_3_ram_mcp_hold(sigFromSrams_bore_3_ram_mcp_hold),
    .sigFromSrams_bore_3_cgen(sigFromSrams_bore_3_cgen),
    .sigFromSrams_bore_4_ram_hold(sigFromSrams_bore_4_ram_hold),
    .sigFromSrams_bore_4_ram_bypass(sigFromSrams_bore_4_ram_bypass),
    .sigFromSrams_bore_4_ram_bp_clken(sigFromSrams_bore_4_ram_bp_clken),
    .sigFromSrams_bore_4_ram_aux_clk(sigFromSrams_bore_4_ram_aux_clk),
    .sigFromSrams_bore_4_ram_aux_ckbp(sigFromSrams_bore_4_ram_aux_ckbp),
    .sigFromSrams_bore_4_ram_mcp_hold(sigFromSrams_bore_4_ram_mcp_hold),
    .sigFromSrams_bore_4_cgen(sigFromSrams_bore_4_cgen),
    .sigFromSrams_bore_5_ram_hold(sigFromSrams_bore_5_ram_hold),
    .sigFromSrams_bore_5_ram_bypass(sigFromSrams_bore_5_ram_bypass),
    .sigFromSrams_bore_5_ram_bp_clken(sigFromSrams_bore_5_ram_bp_clken),
    .sigFromSrams_bore_5_ram_aux_clk(sigFromSrams_bore_5_ram_aux_clk),
    .sigFromSrams_bore_5_ram_aux_ckbp(sigFromSrams_bore_5_ram_aux_ckbp),
    .sigFromSrams_bore_5_ram_mcp_hold(sigFromSrams_bore_5_ram_mcp_hold),
    .sigFromSrams_bore_5_cgen(sigFromSrams_bore_5_cgen),
    .sigFromSrams_bore_6_ram_hold(sigFromSrams_bore_6_ram_hold),
    .sigFromSrams_bore_6_ram_bypass(sigFromSrams_bore_6_ram_bypass),
    .sigFromSrams_bore_6_ram_bp_clken(sigFromSrams_bore_6_ram_bp_clken),
    .sigFromSrams_bore_6_ram_aux_clk(sigFromSrams_bore_6_ram_aux_clk),
    .sigFromSrams_bore_6_ram_aux_ckbp(sigFromSrams_bore_6_ram_aux_ckbp),
    .sigFromSrams_bore_6_ram_mcp_hold(sigFromSrams_bore_6_ram_mcp_hold),
    .sigFromSrams_bore_6_cgen(sigFromSrams_bore_6_cgen),
    .sigFromSrams_bore_7_ram_hold(sigFromSrams_bore_7_ram_hold),
    .sigFromSrams_bore_7_ram_bypass(sigFromSrams_bore_7_ram_bypass),
    .sigFromSrams_bore_7_ram_bp_clken(sigFromSrams_bore_7_ram_bp_clken),
    .sigFromSrams_bore_7_ram_aux_clk(sigFromSrams_bore_7_ram_aux_clk),
    .sigFromSrams_bore_7_ram_aux_ckbp(sigFromSrams_bore_7_ram_aux_ckbp),
    .sigFromSrams_bore_7_ram_mcp_hold(sigFromSrams_bore_7_ram_mcp_hold),
    .sigFromSrams_bore_7_cgen(sigFromSrams_bore_7_cgen),
    .sigFromSrams_bore_8_ram_hold(sigFromSrams_bore_8_ram_hold),
    .sigFromSrams_bore_8_ram_bypass(sigFromSrams_bore_8_ram_bypass),
    .sigFromSrams_bore_8_ram_bp_clken(sigFromSrams_bore_8_ram_bp_clken),
    .sigFromSrams_bore_8_ram_aux_clk(sigFromSrams_bore_8_ram_aux_clk),
    .sigFromSrams_bore_8_ram_aux_ckbp(sigFromSrams_bore_8_ram_aux_ckbp),
    .sigFromSrams_bore_8_ram_mcp_hold(sigFromSrams_bore_8_ram_mcp_hold),
    .sigFromSrams_bore_8_cgen(sigFromSrams_bore_8_cgen),
    .sigFromSrams_bore_9_ram_hold(sigFromSrams_bore_9_ram_hold),
    .sigFromSrams_bore_9_ram_bypass(sigFromSrams_bore_9_ram_bypass),
    .sigFromSrams_bore_9_ram_bp_clken(sigFromSrams_bore_9_ram_bp_clken),
    .sigFromSrams_bore_9_ram_aux_clk(sigFromSrams_bore_9_ram_aux_clk),
    .sigFromSrams_bore_9_ram_aux_ckbp(sigFromSrams_bore_9_ram_aux_ckbp),
    .sigFromSrams_bore_9_ram_mcp_hold(sigFromSrams_bore_9_ram_mcp_hold),
    .sigFromSrams_bore_9_cgen(sigFromSrams_bore_9_cgen),
    .sigFromSrams_bore_10_ram_hold(sigFromSrams_bore_10_ram_hold),
    .sigFromSrams_bore_10_ram_bypass(sigFromSrams_bore_10_ram_bypass),
    .sigFromSrams_bore_10_ram_bp_clken(sigFromSrams_bore_10_ram_bp_clken),
    .sigFromSrams_bore_10_ram_aux_clk(sigFromSrams_bore_10_ram_aux_clk),
    .sigFromSrams_bore_10_ram_aux_ckbp(sigFromSrams_bore_10_ram_aux_ckbp),
    .sigFromSrams_bore_10_ram_mcp_hold(sigFromSrams_bore_10_ram_mcp_hold),
    .sigFromSrams_bore_10_cgen(sigFromSrams_bore_10_cgen),
    .boreChildrenBd_bore_array(6'(boreChildrenBd_bore_array)),
    .boreChildrenBd_bore_all(boreChildrenBd_bore_all),
    .boreChildrenBd_bore_req(boreChildrenBd_bore_req),
    .boreChildrenBd_bore_ack(g2_boreChildrenBd_bore_ack),
    .boreChildrenBd_bore_writeen(boreChildrenBd_bore_writeen),
    .boreChildrenBd_bore_be(boreChildrenBd_bore_be),
    .boreChildrenBd_bore_addr(boreChildrenBd_bore_addr),
    .boreChildrenBd_bore_indata(boreChildrenBd_bore_indata),
    .boreChildrenBd_bore_readen(boreChildrenBd_bore_readen),
    .boreChildrenBd_bore_addr_rd(boreChildrenBd_bore_addr_rd),
    .boreChildrenBd_bore_outdata(g2_boreChildrenBd_bore_outdata)
  );
  Slice_2_xs u_i2 (
    .clock(clock),
    .reset(reset),
    .io_in_a_ready(i2_io_in_a_ready),
    .io_in_a_valid(io_in_a_valid),
    .io_in_a_bits_opcode(io_in_a_bits_opcode),
    .io_in_a_bits_param(io_in_a_bits_param),
    .io_in_a_bits_size(io_in_a_bits_size),
    .io_in_a_bits_source(io_in_a_bits_source),
    .io_in_a_bits_address(io_in_a_bits_address),
    .io_in_a_bits_user_reqSource(io_in_a_bits_user_reqSource),
    .io_in_a_bits_user_alias(io_in_a_bits_user_alias),
    .io_in_a_bits_user_vaddr(io_in_a_bits_user_vaddr),
    .io_in_a_bits_user_needHint(io_in_a_bits_user_needHint),
    .io_in_a_bits_echo_isKeyword(io_in_a_bits_echo_isKeyword),
    .io_in_a_bits_corrupt(io_in_a_bits_corrupt),
    .io_in_b_ready(io_in_b_ready),
    .io_in_b_valid(i2_io_in_b_valid),
    .io_in_b_bits_opcode(i2_io_in_b_bits_opcode),
    .io_in_b_bits_param(i2_io_in_b_bits_param),
    .io_in_b_bits_address(i2_io_in_b_bits_address),
    .io_in_b_bits_data(i2_io_in_b_bits_data),
    .io_in_c_ready(i2_io_in_c_ready),
    .io_in_c_valid(io_in_c_valid),
    .io_in_c_bits_opcode(io_in_c_bits_opcode),
    .io_in_c_bits_param(io_in_c_bits_param),
    .io_in_c_bits_size(io_in_c_bits_size),
    .io_in_c_bits_source(io_in_c_bits_source),
    .io_in_c_bits_address(io_in_c_bits_address),
    .io_in_c_bits_data(io_in_c_bits_data),
    .io_in_c_bits_corrupt(io_in_c_bits_corrupt),
    .io_in_d_ready(io_in_d_ready),
    .io_in_d_valid(i2_io_in_d_valid),
    .io_in_d_bits_opcode(i2_io_in_d_bits_opcode),
    .io_in_d_bits_param(i2_io_in_d_bits_param),
    .io_in_d_bits_source(i2_io_in_d_bits_source),
    .io_in_d_bits_sink(i2_io_in_d_bits_sink),
    .io_in_d_bits_denied(i2_io_in_d_bits_denied),
    .io_in_d_bits_echo_isKeyword(i2_io_in_d_bits_echo_isKeyword),
    .io_in_d_bits_data(i2_io_in_d_bits_data),
    .io_in_d_bits_corrupt(i2_io_in_d_bits_corrupt),
    .io_in_e_valid(io_in_e_valid),
    .io_in_e_bits_sink(io_in_e_bits_sink),
    .io_l1Hint_ready(io_l1Hint_ready),
    .io_l1Hint_valid(i2_io_l1Hint_valid),
    .io_l1Hint_bits_sourceId(i2_io_l1Hint_bits_sourceId),
    .io_l1Hint_bits_isKeyword(i2_io_l1Hint_bits_isKeyword),
    .io_prefetch_train_ready(io_prefetch_train_ready),
    .io_prefetch_train_valid(i2_io_prefetch_train_valid),
    .io_prefetch_train_bits_tag(i2_io_prefetch_train_bits_tag),
    .io_prefetch_train_bits_set(i2_io_prefetch_train_bits_set),
    .io_prefetch_train_bits_needT(i2_io_prefetch_train_bits_needT),
    .io_prefetch_train_bits_source(i2_io_prefetch_train_bits_source),
    .io_prefetch_train_bits_vaddr(i2_io_prefetch_train_bits_vaddr),
    .io_prefetch_train_bits_hit(i2_io_prefetch_train_bits_hit),
    .io_prefetch_train_bits_prefetched(i2_io_prefetch_train_bits_prefetched),
    .io_prefetch_train_bits_pfsource(i2_io_prefetch_train_bits_pfsource),
    .io_prefetch_train_bits_reqsource(i2_io_prefetch_train_bits_reqsource),
    .io_prefetch_req_ready(i2_io_prefetch_req_ready),
    .io_prefetch_req_valid(io_prefetch_req_valid),
    .io_prefetch_req_bits_tag(io_prefetch_req_bits_tag),
    .io_prefetch_req_bits_set(io_prefetch_req_bits_set),
    .io_prefetch_req_bits_vaddr(io_prefetch_req_bits_vaddr),
    .io_prefetch_req_bits_needT(io_prefetch_req_bits_needT),
    .io_prefetch_req_bits_source(io_prefetch_req_bits_source),
    .io_prefetch_req_bits_pfSource(io_prefetch_req_bits_pfSource),
    .io_prefetch_resp_ready(io_prefetch_resp_ready),
    .io_prefetch_resp_valid(i2_io_prefetch_resp_valid),
    .io_prefetch_resp_bits_tag(i2_io_prefetch_resp_bits_tag),
    .io_prefetch_resp_bits_set(i2_io_prefetch_resp_bits_set),
    .io_prefetch_resp_bits_vaddr(i2_io_prefetch_resp_bits_vaddr),
    .io_prefetch_resp_bits_pfSource(i2_io_prefetch_resp_bits_pfSource),
    .io_dirResult_valid(i2_io_dirResult_valid),
    .io_dirResult_bits_hit(i2_io_dirResult_bits_hit),
    .io_dirResult_bits_meta_prefetch(i2_io_dirResult_bits_meta_prefetch),
    .io_dirResult_bits_meta_prefetchSrc(i2_io_dirResult_bits_meta_prefetchSrc),
    .io_dirResult_bits_replacerInfo_channel(i2_io_dirResult_bits_replacerInfo_channel),
    .io_dirResult_bits_replacerInfo_reqSource(i2_io_dirResult_bits_replacerInfo_reqSource),
    .io_hitPfInMSHR_valid(i2_io_hitPfInMSHR_valid),
    .io_hitPfInMSHR_bits(i2_io_hitPfInMSHR_bits),
    .io_pfSent_valid(i2_io_pfSent_valid),
    .io_pfSent_bits(i2_io_pfSent_bits),
    .io_pfLateInMSHR_valid(i2_io_pfLateInMSHR_valid),
    .io_pfLateInMSHR_bits(i2_io_pfLateInMSHR_bits),
    .io_error_valid(i2_io_error_valid),
    .io_error_bits_valid(i2_io_error_bits_valid),
    .io_error_bits_address(i2_io_error_bits_address),
    .io_l2Miss(i2_io_l2Miss),
    .io_msStatus_0_valid(i2_io_msStatus_0_valid),
    .io_msStatus_0_bits_channel(i2_io_msStatus_0_bits_channel),
    .io_msStatus_0_bits_set(i2_io_msStatus_0_bits_set),
    .io_msStatus_0_bits_reqTag(i2_io_msStatus_0_bits_reqTag),
    .io_msStatus_0_bits_is_miss(i2_io_msStatus_0_bits_is_miss),
    .io_msStatus_0_bits_is_prefetch(i2_io_msStatus_0_bits_is_prefetch),
    .io_msStatus_1_valid(i2_io_msStatus_1_valid),
    .io_msStatus_1_bits_channel(i2_io_msStatus_1_bits_channel),
    .io_msStatus_1_bits_set(i2_io_msStatus_1_bits_set),
    .io_msStatus_1_bits_reqTag(i2_io_msStatus_1_bits_reqTag),
    .io_msStatus_1_bits_is_miss(i2_io_msStatus_1_bits_is_miss),
    .io_msStatus_1_bits_is_prefetch(i2_io_msStatus_1_bits_is_prefetch),
    .io_msStatus_2_valid(i2_io_msStatus_2_valid),
    .io_msStatus_2_bits_channel(i2_io_msStatus_2_bits_channel),
    .io_msStatus_2_bits_set(i2_io_msStatus_2_bits_set),
    .io_msStatus_2_bits_reqTag(i2_io_msStatus_2_bits_reqTag),
    .io_msStatus_2_bits_is_miss(i2_io_msStatus_2_bits_is_miss),
    .io_msStatus_2_bits_is_prefetch(i2_io_msStatus_2_bits_is_prefetch),
    .io_msStatus_3_valid(i2_io_msStatus_3_valid),
    .io_msStatus_3_bits_channel(i2_io_msStatus_3_bits_channel),
    .io_msStatus_3_bits_set(i2_io_msStatus_3_bits_set),
    .io_msStatus_3_bits_reqTag(i2_io_msStatus_3_bits_reqTag),
    .io_msStatus_3_bits_is_miss(i2_io_msStatus_3_bits_is_miss),
    .io_msStatus_3_bits_is_prefetch(i2_io_msStatus_3_bits_is_prefetch),
    .io_msStatus_4_valid(i2_io_msStatus_4_valid),
    .io_msStatus_4_bits_channel(i2_io_msStatus_4_bits_channel),
    .io_msStatus_4_bits_set(i2_io_msStatus_4_bits_set),
    .io_msStatus_4_bits_reqTag(i2_io_msStatus_4_bits_reqTag),
    .io_msStatus_4_bits_is_miss(i2_io_msStatus_4_bits_is_miss),
    .io_msStatus_4_bits_is_prefetch(i2_io_msStatus_4_bits_is_prefetch),
    .io_msStatus_5_valid(i2_io_msStatus_5_valid),
    .io_msStatus_5_bits_channel(i2_io_msStatus_5_bits_channel),
    .io_msStatus_5_bits_set(i2_io_msStatus_5_bits_set),
    .io_msStatus_5_bits_reqTag(i2_io_msStatus_5_bits_reqTag),
    .io_msStatus_5_bits_is_miss(i2_io_msStatus_5_bits_is_miss),
    .io_msStatus_5_bits_is_prefetch(i2_io_msStatus_5_bits_is_prefetch),
    .io_msStatus_6_valid(i2_io_msStatus_6_valid),
    .io_msStatus_6_bits_channel(i2_io_msStatus_6_bits_channel),
    .io_msStatus_6_bits_set(i2_io_msStatus_6_bits_set),
    .io_msStatus_6_bits_reqTag(i2_io_msStatus_6_bits_reqTag),
    .io_msStatus_6_bits_is_miss(i2_io_msStatus_6_bits_is_miss),
    .io_msStatus_6_bits_is_prefetch(i2_io_msStatus_6_bits_is_prefetch),
    .io_msStatus_7_valid(i2_io_msStatus_7_valid),
    .io_msStatus_7_bits_channel(i2_io_msStatus_7_bits_channel),
    .io_msStatus_7_bits_set(i2_io_msStatus_7_bits_set),
    .io_msStatus_7_bits_reqTag(i2_io_msStatus_7_bits_reqTag),
    .io_msStatus_7_bits_is_miss(i2_io_msStatus_7_bits_is_miss),
    .io_msStatus_7_bits_is_prefetch(i2_io_msStatus_7_bits_is_prefetch),
    .io_msStatus_8_valid(i2_io_msStatus_8_valid),
    .io_msStatus_8_bits_channel(i2_io_msStatus_8_bits_channel),
    .io_msStatus_8_bits_set(i2_io_msStatus_8_bits_set),
    .io_msStatus_8_bits_reqTag(i2_io_msStatus_8_bits_reqTag),
    .io_msStatus_8_bits_is_miss(i2_io_msStatus_8_bits_is_miss),
    .io_msStatus_8_bits_is_prefetch(i2_io_msStatus_8_bits_is_prefetch),
    .io_msStatus_9_valid(i2_io_msStatus_9_valid),
    .io_msStatus_9_bits_channel(i2_io_msStatus_9_bits_channel),
    .io_msStatus_9_bits_set(i2_io_msStatus_9_bits_set),
    .io_msStatus_9_bits_reqTag(i2_io_msStatus_9_bits_reqTag),
    .io_msStatus_9_bits_is_miss(i2_io_msStatus_9_bits_is_miss),
    .io_msStatus_9_bits_is_prefetch(i2_io_msStatus_9_bits_is_prefetch),
    .io_msStatus_10_valid(i2_io_msStatus_10_valid),
    .io_msStatus_10_bits_channel(i2_io_msStatus_10_bits_channel),
    .io_msStatus_10_bits_set(i2_io_msStatus_10_bits_set),
    .io_msStatus_10_bits_reqTag(i2_io_msStatus_10_bits_reqTag),
    .io_msStatus_10_bits_is_miss(i2_io_msStatus_10_bits_is_miss),
    .io_msStatus_10_bits_is_prefetch(i2_io_msStatus_10_bits_is_prefetch),
    .io_msStatus_11_valid(i2_io_msStatus_11_valid),
    .io_msStatus_11_bits_channel(i2_io_msStatus_11_bits_channel),
    .io_msStatus_11_bits_set(i2_io_msStatus_11_bits_set),
    .io_msStatus_11_bits_reqTag(i2_io_msStatus_11_bits_reqTag),
    .io_msStatus_11_bits_is_miss(i2_io_msStatus_11_bits_is_miss),
    .io_msStatus_11_bits_is_prefetch(i2_io_msStatus_11_bits_is_prefetch),
    .io_msStatus_12_valid(i2_io_msStatus_12_valid),
    .io_msStatus_12_bits_channel(i2_io_msStatus_12_bits_channel),
    .io_msStatus_12_bits_set(i2_io_msStatus_12_bits_set),
    .io_msStatus_12_bits_reqTag(i2_io_msStatus_12_bits_reqTag),
    .io_msStatus_12_bits_is_miss(i2_io_msStatus_12_bits_is_miss),
    .io_msStatus_12_bits_is_prefetch(i2_io_msStatus_12_bits_is_prefetch),
    .io_msStatus_13_valid(i2_io_msStatus_13_valid),
    .io_msStatus_13_bits_channel(i2_io_msStatus_13_bits_channel),
    .io_msStatus_13_bits_set(i2_io_msStatus_13_bits_set),
    .io_msStatus_13_bits_reqTag(i2_io_msStatus_13_bits_reqTag),
    .io_msStatus_13_bits_is_miss(i2_io_msStatus_13_bits_is_miss),
    .io_msStatus_13_bits_is_prefetch(i2_io_msStatus_13_bits_is_prefetch),
    .io_msStatus_14_valid(i2_io_msStatus_14_valid),
    .io_msStatus_14_bits_channel(i2_io_msStatus_14_bits_channel),
    .io_msStatus_14_bits_set(i2_io_msStatus_14_bits_set),
    .io_msStatus_14_bits_reqTag(i2_io_msStatus_14_bits_reqTag),
    .io_msStatus_14_bits_is_miss(i2_io_msStatus_14_bits_is_miss),
    .io_msStatus_14_bits_is_prefetch(i2_io_msStatus_14_bits_is_prefetch),
    .io_msStatus_15_valid(i2_io_msStatus_15_valid),
    .io_msStatus_15_bits_channel(i2_io_msStatus_15_bits_channel),
    .io_msStatus_15_bits_set(i2_io_msStatus_15_bits_set),
    .io_msStatus_15_bits_reqTag(i2_io_msStatus_15_bits_reqTag),
    .io_msStatus_15_bits_is_miss(i2_io_msStatus_15_bits_is_miss),
    .io_msStatus_15_bits_is_prefetch(i2_io_msStatus_15_bits_is_prefetch),
    .io_msAlloc_0_valid(i2_io_msAlloc_0_valid),
    .io_msAlloc_0_bits_channel(i2_io_msAlloc_0_bits_channel),
    .io_msAlloc_0_bits_is_miss(i2_io_msAlloc_0_bits_is_miss),
    .io_msAlloc_0_bits_is_prefetch(i2_io_msAlloc_0_bits_is_prefetch),
    .io_msAlloc_1_valid(i2_io_msAlloc_1_valid),
    .io_msAlloc_1_bits_channel(i2_io_msAlloc_1_bits_channel),
    .io_msAlloc_1_bits_is_miss(i2_io_msAlloc_1_bits_is_miss),
    .io_msAlloc_1_bits_is_prefetch(i2_io_msAlloc_1_bits_is_prefetch),
    .io_msAlloc_2_valid(i2_io_msAlloc_2_valid),
    .io_msAlloc_2_bits_channel(i2_io_msAlloc_2_bits_channel),
    .io_msAlloc_2_bits_is_miss(i2_io_msAlloc_2_bits_is_miss),
    .io_msAlloc_2_bits_is_prefetch(i2_io_msAlloc_2_bits_is_prefetch),
    .io_msAlloc_3_valid(i2_io_msAlloc_3_valid),
    .io_msAlloc_3_bits_channel(i2_io_msAlloc_3_bits_channel),
    .io_msAlloc_3_bits_is_miss(i2_io_msAlloc_3_bits_is_miss),
    .io_msAlloc_3_bits_is_prefetch(i2_io_msAlloc_3_bits_is_prefetch),
    .io_msAlloc_4_valid(i2_io_msAlloc_4_valid),
    .io_msAlloc_4_bits_channel(i2_io_msAlloc_4_bits_channel),
    .io_msAlloc_4_bits_is_miss(i2_io_msAlloc_4_bits_is_miss),
    .io_msAlloc_4_bits_is_prefetch(i2_io_msAlloc_4_bits_is_prefetch),
    .io_msAlloc_5_valid(i2_io_msAlloc_5_valid),
    .io_msAlloc_5_bits_channel(i2_io_msAlloc_5_bits_channel),
    .io_msAlloc_5_bits_is_miss(i2_io_msAlloc_5_bits_is_miss),
    .io_msAlloc_5_bits_is_prefetch(i2_io_msAlloc_5_bits_is_prefetch),
    .io_msAlloc_6_valid(i2_io_msAlloc_6_valid),
    .io_msAlloc_6_bits_channel(i2_io_msAlloc_6_bits_channel),
    .io_msAlloc_6_bits_is_miss(i2_io_msAlloc_6_bits_is_miss),
    .io_msAlloc_6_bits_is_prefetch(i2_io_msAlloc_6_bits_is_prefetch),
    .io_msAlloc_7_valid(i2_io_msAlloc_7_valid),
    .io_msAlloc_7_bits_channel(i2_io_msAlloc_7_bits_channel),
    .io_msAlloc_7_bits_is_miss(i2_io_msAlloc_7_bits_is_miss),
    .io_msAlloc_7_bits_is_prefetch(i2_io_msAlloc_7_bits_is_prefetch),
    .io_msAlloc_8_valid(i2_io_msAlloc_8_valid),
    .io_msAlloc_8_bits_channel(i2_io_msAlloc_8_bits_channel),
    .io_msAlloc_8_bits_is_miss(i2_io_msAlloc_8_bits_is_miss),
    .io_msAlloc_8_bits_is_prefetch(i2_io_msAlloc_8_bits_is_prefetch),
    .io_msAlloc_9_valid(i2_io_msAlloc_9_valid),
    .io_msAlloc_9_bits_channel(i2_io_msAlloc_9_bits_channel),
    .io_msAlloc_9_bits_is_miss(i2_io_msAlloc_9_bits_is_miss),
    .io_msAlloc_9_bits_is_prefetch(i2_io_msAlloc_9_bits_is_prefetch),
    .io_msAlloc_10_valid(i2_io_msAlloc_10_valid),
    .io_msAlloc_10_bits_channel(i2_io_msAlloc_10_bits_channel),
    .io_msAlloc_10_bits_is_miss(i2_io_msAlloc_10_bits_is_miss),
    .io_msAlloc_10_bits_is_prefetch(i2_io_msAlloc_10_bits_is_prefetch),
    .io_msAlloc_11_valid(i2_io_msAlloc_11_valid),
    .io_msAlloc_11_bits_channel(i2_io_msAlloc_11_bits_channel),
    .io_msAlloc_11_bits_is_miss(i2_io_msAlloc_11_bits_is_miss),
    .io_msAlloc_11_bits_is_prefetch(i2_io_msAlloc_11_bits_is_prefetch),
    .io_msAlloc_12_valid(i2_io_msAlloc_12_valid),
    .io_msAlloc_12_bits_channel(i2_io_msAlloc_12_bits_channel),
    .io_msAlloc_12_bits_is_miss(i2_io_msAlloc_12_bits_is_miss),
    .io_msAlloc_12_bits_is_prefetch(i2_io_msAlloc_12_bits_is_prefetch),
    .io_msAlloc_13_valid(i2_io_msAlloc_13_valid),
    .io_msAlloc_13_bits_channel(i2_io_msAlloc_13_bits_channel),
    .io_msAlloc_13_bits_is_miss(i2_io_msAlloc_13_bits_is_miss),
    .io_msAlloc_13_bits_is_prefetch(i2_io_msAlloc_13_bits_is_prefetch),
    .io_msAlloc_14_valid(i2_io_msAlloc_14_valid),
    .io_msAlloc_14_bits_channel(i2_io_msAlloc_14_bits_channel),
    .io_msAlloc_14_bits_is_miss(i2_io_msAlloc_14_bits_is_miss),
    .io_msAlloc_14_bits_is_prefetch(i2_io_msAlloc_14_bits_is_prefetch),
    .io_msAlloc_15_valid(i2_io_msAlloc_15_valid),
    .io_msAlloc_15_bits_channel(i2_io_msAlloc_15_bits_channel),
    .io_msAlloc_15_bits_is_miss(i2_io_msAlloc_15_bits_is_miss),
    .io_msAlloc_15_bits_is_prefetch(i2_io_msAlloc_15_bits_is_prefetch),
    .io_out_tx_req_ready(io_out_tx_req_ready),
    .io_out_tx_req_valid(i2_io_out_tx_req_valid),
    .io_out_tx_req_bits_qos(i2_io_out_tx_req_bits_qos),
    .io_out_tx_req_bits_txnID(i2_io_out_tx_req_bits_txnID),
    .io_out_tx_req_bits_returnNID(i2_io_out_tx_req_bits_returnNID),
    .io_out_tx_req_bits_stashNIDValid(i2_io_out_tx_req_bits_stashNIDValid),
    .io_out_tx_req_bits_returnTxnID(i2_io_out_tx_req_bits_returnTxnID),
    .io_out_tx_req_bits_opcode(i2_io_out_tx_req_bits_opcode),
    .io_out_tx_req_bits_addr(i2_io_out_tx_req_bits_addr),
    .io_out_tx_req_bits_ns(i2_io_out_tx_req_bits_ns),
    .io_out_tx_req_bits_likelyshared(i2_io_out_tx_req_bits_likelyshared),
    .io_out_tx_req_bits_allowRetry(i2_io_out_tx_req_bits_allowRetry),
    .io_out_tx_req_bits_order(i2_io_out_tx_req_bits_order),
    .io_out_tx_req_bits_pCrdType(i2_io_out_tx_req_bits_pCrdType),
    .io_out_tx_req_bits_memAttr_allocate(i2_io_out_tx_req_bits_memAttr_allocate),
    .io_out_tx_req_bits_memAttr_cacheable(i2_io_out_tx_req_bits_memAttr_cacheable),
    .io_out_tx_req_bits_memAttr_device(i2_io_out_tx_req_bits_memAttr_device),
    .io_out_tx_req_bits_memAttr_ewa(i2_io_out_tx_req_bits_memAttr_ewa),
    .io_out_tx_req_bits_snpAttr(i2_io_out_tx_req_bits_snpAttr),
    .io_out_tx_req_bits_lpIDWithPadding(i2_io_out_tx_req_bits_lpIDWithPadding),
    .io_out_tx_req_bits_snoopMe(i2_io_out_tx_req_bits_snoopMe),
    .io_out_tx_req_bits_expCompAck(i2_io_out_tx_req_bits_expCompAck),
    .io_out_tx_req_bits_tagOp(i2_io_out_tx_req_bits_tagOp),
    .io_out_tx_req_bits_traceTag(i2_io_out_tx_req_bits_traceTag),
    .io_out_tx_req_bits_mpam_perfMonGroup(i2_io_out_tx_req_bits_mpam_perfMonGroup),
    .io_out_tx_req_bits_mpam_partID(i2_io_out_tx_req_bits_mpam_partID),
    .io_out_tx_req_bits_mpam_mpamNS(i2_io_out_tx_req_bits_mpam_mpamNS),
    .io_out_tx_req_bits_rsvdc(i2_io_out_tx_req_bits_rsvdc),
    .io_out_tx_rsp_ready(io_out_tx_rsp_ready),
    .io_out_tx_rsp_valid(i2_io_out_tx_rsp_valid),
    .io_out_tx_rsp_bits_qos(i2_io_out_tx_rsp_bits_qos),
    .io_out_tx_rsp_bits_tgtID(i2_io_out_tx_rsp_bits_tgtID),
    .io_out_tx_rsp_bits_txnID(i2_io_out_tx_rsp_bits_txnID),
    .io_out_tx_rsp_bits_opcode(i2_io_out_tx_rsp_bits_opcode),
    .io_out_tx_rsp_bits_respErr(i2_io_out_tx_rsp_bits_respErr),
    .io_out_tx_rsp_bits_resp(i2_io_out_tx_rsp_bits_resp),
    .io_out_tx_rsp_bits_fwdState(i2_io_out_tx_rsp_bits_fwdState),
    .io_out_tx_rsp_bits_cBusy(i2_io_out_tx_rsp_bits_cBusy),
    .io_out_tx_rsp_bits_dbID(i2_io_out_tx_rsp_bits_dbID),
    .io_out_tx_rsp_bits_pCrdType(i2_io_out_tx_rsp_bits_pCrdType),
    .io_out_tx_rsp_bits_tagOp(i2_io_out_tx_rsp_bits_tagOp),
    .io_out_tx_rsp_bits_traceTag(i2_io_out_tx_rsp_bits_traceTag),
    .io_out_tx_dat_ready(io_out_tx_dat_ready),
    .io_out_tx_dat_valid(i2_io_out_tx_dat_valid),
    .io_out_tx_dat_bits_tgtID(i2_io_out_tx_dat_bits_tgtID),
    .io_out_tx_dat_bits_txnID(i2_io_out_tx_dat_bits_txnID),
    .io_out_tx_dat_bits_homeNID(i2_io_out_tx_dat_bits_homeNID),
    .io_out_tx_dat_bits_opcode(i2_io_out_tx_dat_bits_opcode),
    .io_out_tx_dat_bits_respErr(i2_io_out_tx_dat_bits_respErr),
    .io_out_tx_dat_bits_resp(i2_io_out_tx_dat_bits_resp),
    .io_out_tx_dat_bits_dataSource(i2_io_out_tx_dat_bits_dataSource),
    .io_out_tx_dat_bits_dbID(i2_io_out_tx_dat_bits_dbID),
    .io_out_tx_dat_bits_ccID(i2_io_out_tx_dat_bits_ccID),
    .io_out_tx_dat_bits_dataID(i2_io_out_tx_dat_bits_dataID),
    .io_out_tx_dat_bits_traceTag(i2_io_out_tx_dat_bits_traceTag),
    .io_out_tx_dat_bits_be(i2_io_out_tx_dat_bits_be),
    .io_out_tx_dat_bits_data(i2_io_out_tx_dat_bits_data),
    .io_out_tx_dat_bits_dataCheck(i2_io_out_tx_dat_bits_dataCheck),
    .io_out_tx_dat_bits_poison(i2_io_out_tx_dat_bits_poison),
    .io_out_rx_rsp_valid(io_out_rx_rsp_valid),
    .io_out_rx_rsp_bits_srcID(io_out_rx_rsp_bits_srcID),
    .io_out_rx_rsp_bits_txnID(io_out_rx_rsp_bits_txnID),
    .io_out_rx_rsp_bits_opcode(io_out_rx_rsp_bits_opcode),
    .io_out_rx_rsp_bits_respErr(io_out_rx_rsp_bits_respErr),
    .io_out_rx_rsp_bits_resp(io_out_rx_rsp_bits_resp),
    .io_out_rx_rsp_bits_dbID(io_out_rx_rsp_bits_dbID),
    .io_out_rx_rsp_bits_pCrdType(io_out_rx_rsp_bits_pCrdType),
    .io_out_rx_rsp_bits_traceTag(io_out_rx_rsp_bits_traceTag),
    .io_out_rx_dat_valid(io_out_rx_dat_valid),
    .io_out_rx_dat_bits_txnID(io_out_rx_dat_bits_txnID),
    .io_out_rx_dat_bits_homeNID(io_out_rx_dat_bits_homeNID),
    .io_out_rx_dat_bits_opcode(io_out_rx_dat_bits_opcode),
    .io_out_rx_dat_bits_respErr(io_out_rx_dat_bits_respErr),
    .io_out_rx_dat_bits_resp(io_out_rx_dat_bits_resp),
    .io_out_rx_dat_bits_dbID(io_out_rx_dat_bits_dbID),
    .io_out_rx_dat_bits_dataID(io_out_rx_dat_bits_dataID),
    .io_out_rx_dat_bits_traceTag(io_out_rx_dat_bits_traceTag),
    .io_out_rx_dat_bits_data(io_out_rx_dat_bits_data),
    .io_out_rx_dat_bits_dataCheck(io_out_rx_dat_bits_dataCheck),
    .io_out_rx_dat_bits_poison(io_out_rx_dat_bits_poison),
    .io_out_rx_snp_ready(i2_io_out_rx_snp_ready),
    .io_out_rx_snp_valid(io_out_rx_snp_valid),
    .io_out_rx_snp_bits_qos(io_out_rx_snp_bits_qos),
    .io_out_rx_snp_bits_srcID(io_out_rx_snp_bits_srcID),
    .io_out_rx_snp_bits_txnID(io_out_rx_snp_bits_txnID),
    .io_out_rx_snp_bits_fwdNID(io_out_rx_snp_bits_fwdNID),
    .io_out_rx_snp_bits_fwdTxnID(io_out_rx_snp_bits_fwdTxnID),
    .io_out_rx_snp_bits_opcode(io_out_rx_snp_bits_opcode),
    .io_out_rx_snp_bits_addr(io_out_rx_snp_bits_addr),
    .io_out_rx_snp_bits_ns(io_out_rx_snp_bits_ns),
    .io_out_rx_snp_bits_doNotGoToSD(io_out_rx_snp_bits_doNotGoToSD),
    .io_out_rx_snp_bits_retToSrc(io_out_rx_snp_bits_retToSrc),
    .io_out_rx_snp_bits_traceTag(io_out_rx_snp_bits_traceTag),
    .io_out_rx_snp_bits_mpam_perfMonGroup(io_out_rx_snp_bits_mpam_perfMonGroup),
    .io_out_rx_snp_bits_mpam_partID(io_out_rx_snp_bits_mpam_partID),
    .io_out_rx_snp_bits_mpam_mpamNS(io_out_rx_snp_bits_mpam_mpamNS),
    .io_pCrd_0_query_valid(i2_io_pCrd_0_query_valid),
    .io_pCrd_0_query_bits_pCrdType(i2_io_pCrd_0_query_bits_pCrdType),
    .io_pCrd_0_query_bits_srcID(i2_io_pCrd_0_query_bits_srcID),
    .io_pCrd_0_grant(io_pCrd_0_grant),
    .io_pCrd_1_query_valid(i2_io_pCrd_1_query_valid),
    .io_pCrd_1_query_bits_pCrdType(i2_io_pCrd_1_query_bits_pCrdType),
    .io_pCrd_1_query_bits_srcID(i2_io_pCrd_1_query_bits_srcID),
    .io_pCrd_1_grant(io_pCrd_1_grant),
    .io_pCrd_2_query_valid(i2_io_pCrd_2_query_valid),
    .io_pCrd_2_query_bits_pCrdType(i2_io_pCrd_2_query_bits_pCrdType),
    .io_pCrd_2_query_bits_srcID(i2_io_pCrd_2_query_bits_srcID),
    .io_pCrd_2_grant(io_pCrd_2_grant),
    .io_pCrd_3_query_valid(i2_io_pCrd_3_query_valid),
    .io_pCrd_3_query_bits_pCrdType(i2_io_pCrd_3_query_bits_pCrdType),
    .io_pCrd_3_query_bits_srcID(i2_io_pCrd_3_query_bits_srcID),
    .io_pCrd_3_grant(io_pCrd_3_grant),
    .io_pCrd_4_query_valid(i2_io_pCrd_4_query_valid),
    .io_pCrd_4_query_bits_pCrdType(i2_io_pCrd_4_query_bits_pCrdType),
    .io_pCrd_4_query_bits_srcID(i2_io_pCrd_4_query_bits_srcID),
    .io_pCrd_4_grant(io_pCrd_4_grant),
    .io_pCrd_5_query_valid(i2_io_pCrd_5_query_valid),
    .io_pCrd_5_query_bits_pCrdType(i2_io_pCrd_5_query_bits_pCrdType),
    .io_pCrd_5_query_bits_srcID(i2_io_pCrd_5_query_bits_srcID),
    .io_pCrd_5_grant(io_pCrd_5_grant),
    .io_pCrd_6_query_valid(i2_io_pCrd_6_query_valid),
    .io_pCrd_6_query_bits_pCrdType(i2_io_pCrd_6_query_bits_pCrdType),
    .io_pCrd_6_query_bits_srcID(i2_io_pCrd_6_query_bits_srcID),
    .io_pCrd_6_grant(io_pCrd_6_grant),
    .io_pCrd_7_query_valid(i2_io_pCrd_7_query_valid),
    .io_pCrd_7_query_bits_pCrdType(i2_io_pCrd_7_query_bits_pCrdType),
    .io_pCrd_7_query_bits_srcID(i2_io_pCrd_7_query_bits_srcID),
    .io_pCrd_7_grant(io_pCrd_7_grant),
    .io_pCrd_8_query_valid(i2_io_pCrd_8_query_valid),
    .io_pCrd_8_query_bits_pCrdType(i2_io_pCrd_8_query_bits_pCrdType),
    .io_pCrd_8_query_bits_srcID(i2_io_pCrd_8_query_bits_srcID),
    .io_pCrd_8_grant(io_pCrd_8_grant),
    .io_pCrd_9_query_valid(i2_io_pCrd_9_query_valid),
    .io_pCrd_9_query_bits_pCrdType(i2_io_pCrd_9_query_bits_pCrdType),
    .io_pCrd_9_query_bits_srcID(i2_io_pCrd_9_query_bits_srcID),
    .io_pCrd_9_grant(io_pCrd_9_grant),
    .io_pCrd_10_query_valid(i2_io_pCrd_10_query_valid),
    .io_pCrd_10_query_bits_pCrdType(i2_io_pCrd_10_query_bits_pCrdType),
    .io_pCrd_10_query_bits_srcID(i2_io_pCrd_10_query_bits_srcID),
    .io_pCrd_10_grant(io_pCrd_10_grant),
    .io_pCrd_11_query_valid(i2_io_pCrd_11_query_valid),
    .io_pCrd_11_query_bits_pCrdType(i2_io_pCrd_11_query_bits_pCrdType),
    .io_pCrd_11_query_bits_srcID(i2_io_pCrd_11_query_bits_srcID),
    .io_pCrd_11_grant(io_pCrd_11_grant),
    .io_pCrd_12_query_valid(i2_io_pCrd_12_query_valid),
    .io_pCrd_12_query_bits_pCrdType(i2_io_pCrd_12_query_bits_pCrdType),
    .io_pCrd_12_query_bits_srcID(i2_io_pCrd_12_query_bits_srcID),
    .io_pCrd_12_grant(io_pCrd_12_grant),
    .io_pCrd_13_query_valid(i2_io_pCrd_13_query_valid),
    .io_pCrd_13_query_bits_pCrdType(i2_io_pCrd_13_query_bits_pCrdType),
    .io_pCrd_13_query_bits_srcID(i2_io_pCrd_13_query_bits_srcID),
    .io_pCrd_13_grant(io_pCrd_13_grant),
    .io_pCrd_14_query_valid(i2_io_pCrd_14_query_valid),
    .io_pCrd_14_query_bits_pCrdType(i2_io_pCrd_14_query_bits_pCrdType),
    .io_pCrd_14_query_bits_srcID(i2_io_pCrd_14_query_bits_srcID),
    .io_pCrd_14_grant(io_pCrd_14_grant),
    .io_pCrd_15_query_valid(i2_io_pCrd_15_query_valid),
    .io_pCrd_15_query_bits_pCrdType(i2_io_pCrd_15_query_bits_pCrdType),
    .io_pCrd_15_query_bits_srcID(i2_io_pCrd_15_query_bits_srcID),
    .io_pCrd_15_grant(io_pCrd_15_grant),
    .io_perf_0_value(i2_io_perf_0_value),
    .io_perf_1_value(i2_io_perf_1_value),
    .io_perf_3_value(i2_io_perf_3_value),
    .io_perf_4_value(i2_io_perf_4_value),
    .io_perf_5_value(i2_io_perf_5_value),
    .io_perf_6_value(i2_io_perf_6_value),
    .io_perf_7_value(i2_io_perf_7_value),
    .io_perf_8_value(i2_io_perf_8_value),
    .io_perf_9_value(i2_io_perf_9_value),
    .io_perf_10_value(i2_io_perf_10_value),
    .io_perf_11_value(i2_io_perf_11_value),
    .io_perf_12_value(i2_io_perf_12_value),
    .io_perf_13_value(i2_io_perf_13_value),
    .io_perf_14_value(i2_io_perf_14_value),
    .io_perf_15_value(i2_io_perf_15_value),
    .io_perf_16_value(i2_io_perf_16_value),
    .sigFromSrams_bore_ram_hold(sigFromSrams_bore_ram_hold),
    .sigFromSrams_bore_ram_bypass(sigFromSrams_bore_ram_bypass),
    .sigFromSrams_bore_ram_bp_clken(sigFromSrams_bore_ram_bp_clken),
    .sigFromSrams_bore_ram_aux_clk(sigFromSrams_bore_ram_aux_clk),
    .sigFromSrams_bore_ram_aux_ckbp(sigFromSrams_bore_ram_aux_ckbp),
    .sigFromSrams_bore_ram_mcp_hold(sigFromSrams_bore_ram_mcp_hold),
    .sigFromSrams_bore_cgen(sigFromSrams_bore_cgen),
    .sigFromSrams_bore_1_ram_hold(sigFromSrams_bore_1_ram_hold),
    .sigFromSrams_bore_1_ram_bypass(sigFromSrams_bore_1_ram_bypass),
    .sigFromSrams_bore_1_ram_bp_clken(sigFromSrams_bore_1_ram_bp_clken),
    .sigFromSrams_bore_1_ram_aux_clk(sigFromSrams_bore_1_ram_aux_clk),
    .sigFromSrams_bore_1_ram_aux_ckbp(sigFromSrams_bore_1_ram_aux_ckbp),
    .sigFromSrams_bore_1_ram_mcp_hold(sigFromSrams_bore_1_ram_mcp_hold),
    .sigFromSrams_bore_1_cgen(sigFromSrams_bore_1_cgen),
    .sigFromSrams_bore_2_ram_hold(sigFromSrams_bore_2_ram_hold),
    .sigFromSrams_bore_2_ram_bypass(sigFromSrams_bore_2_ram_bypass),
    .sigFromSrams_bore_2_ram_bp_clken(sigFromSrams_bore_2_ram_bp_clken),
    .sigFromSrams_bore_2_ram_aux_clk(sigFromSrams_bore_2_ram_aux_clk),
    .sigFromSrams_bore_2_ram_aux_ckbp(sigFromSrams_bore_2_ram_aux_ckbp),
    .sigFromSrams_bore_2_ram_mcp_hold(sigFromSrams_bore_2_ram_mcp_hold),
    .sigFromSrams_bore_2_cgen(sigFromSrams_bore_2_cgen),
    .sigFromSrams_bore_3_ram_hold(sigFromSrams_bore_3_ram_hold),
    .sigFromSrams_bore_3_ram_bypass(sigFromSrams_bore_3_ram_bypass),
    .sigFromSrams_bore_3_ram_bp_clken(sigFromSrams_bore_3_ram_bp_clken),
    .sigFromSrams_bore_3_ram_aux_clk(sigFromSrams_bore_3_ram_aux_clk),
    .sigFromSrams_bore_3_ram_aux_ckbp(sigFromSrams_bore_3_ram_aux_ckbp),
    .sigFromSrams_bore_3_ram_mcp_hold(sigFromSrams_bore_3_ram_mcp_hold),
    .sigFromSrams_bore_3_cgen(sigFromSrams_bore_3_cgen),
    .sigFromSrams_bore_4_ram_hold(sigFromSrams_bore_4_ram_hold),
    .sigFromSrams_bore_4_ram_bypass(sigFromSrams_bore_4_ram_bypass),
    .sigFromSrams_bore_4_ram_bp_clken(sigFromSrams_bore_4_ram_bp_clken),
    .sigFromSrams_bore_4_ram_aux_clk(sigFromSrams_bore_4_ram_aux_clk),
    .sigFromSrams_bore_4_ram_aux_ckbp(sigFromSrams_bore_4_ram_aux_ckbp),
    .sigFromSrams_bore_4_ram_mcp_hold(sigFromSrams_bore_4_ram_mcp_hold),
    .sigFromSrams_bore_4_cgen(sigFromSrams_bore_4_cgen),
    .sigFromSrams_bore_5_ram_hold(sigFromSrams_bore_5_ram_hold),
    .sigFromSrams_bore_5_ram_bypass(sigFromSrams_bore_5_ram_bypass),
    .sigFromSrams_bore_5_ram_bp_clken(sigFromSrams_bore_5_ram_bp_clken),
    .sigFromSrams_bore_5_ram_aux_clk(sigFromSrams_bore_5_ram_aux_clk),
    .sigFromSrams_bore_5_ram_aux_ckbp(sigFromSrams_bore_5_ram_aux_ckbp),
    .sigFromSrams_bore_5_ram_mcp_hold(sigFromSrams_bore_5_ram_mcp_hold),
    .sigFromSrams_bore_5_cgen(sigFromSrams_bore_5_cgen),
    .sigFromSrams_bore_6_ram_hold(sigFromSrams_bore_6_ram_hold),
    .sigFromSrams_bore_6_ram_bypass(sigFromSrams_bore_6_ram_bypass),
    .sigFromSrams_bore_6_ram_bp_clken(sigFromSrams_bore_6_ram_bp_clken),
    .sigFromSrams_bore_6_ram_aux_clk(sigFromSrams_bore_6_ram_aux_clk),
    .sigFromSrams_bore_6_ram_aux_ckbp(sigFromSrams_bore_6_ram_aux_ckbp),
    .sigFromSrams_bore_6_ram_mcp_hold(sigFromSrams_bore_6_ram_mcp_hold),
    .sigFromSrams_bore_6_cgen(sigFromSrams_bore_6_cgen),
    .sigFromSrams_bore_7_ram_hold(sigFromSrams_bore_7_ram_hold),
    .sigFromSrams_bore_7_ram_bypass(sigFromSrams_bore_7_ram_bypass),
    .sigFromSrams_bore_7_ram_bp_clken(sigFromSrams_bore_7_ram_bp_clken),
    .sigFromSrams_bore_7_ram_aux_clk(sigFromSrams_bore_7_ram_aux_clk),
    .sigFromSrams_bore_7_ram_aux_ckbp(sigFromSrams_bore_7_ram_aux_ckbp),
    .sigFromSrams_bore_7_ram_mcp_hold(sigFromSrams_bore_7_ram_mcp_hold),
    .sigFromSrams_bore_7_cgen(sigFromSrams_bore_7_cgen),
    .sigFromSrams_bore_8_ram_hold(sigFromSrams_bore_8_ram_hold),
    .sigFromSrams_bore_8_ram_bypass(sigFromSrams_bore_8_ram_bypass),
    .sigFromSrams_bore_8_ram_bp_clken(sigFromSrams_bore_8_ram_bp_clken),
    .sigFromSrams_bore_8_ram_aux_clk(sigFromSrams_bore_8_ram_aux_clk),
    .sigFromSrams_bore_8_ram_aux_ckbp(sigFromSrams_bore_8_ram_aux_ckbp),
    .sigFromSrams_bore_8_ram_mcp_hold(sigFromSrams_bore_8_ram_mcp_hold),
    .sigFromSrams_bore_8_cgen(sigFromSrams_bore_8_cgen),
    .sigFromSrams_bore_9_ram_hold(sigFromSrams_bore_9_ram_hold),
    .sigFromSrams_bore_9_ram_bypass(sigFromSrams_bore_9_ram_bypass),
    .sigFromSrams_bore_9_ram_bp_clken(sigFromSrams_bore_9_ram_bp_clken),
    .sigFromSrams_bore_9_ram_aux_clk(sigFromSrams_bore_9_ram_aux_clk),
    .sigFromSrams_bore_9_ram_aux_ckbp(sigFromSrams_bore_9_ram_aux_ckbp),
    .sigFromSrams_bore_9_ram_mcp_hold(sigFromSrams_bore_9_ram_mcp_hold),
    .sigFromSrams_bore_9_cgen(sigFromSrams_bore_9_cgen),
    .sigFromSrams_bore_10_ram_hold(sigFromSrams_bore_10_ram_hold),
    .sigFromSrams_bore_10_ram_bypass(sigFromSrams_bore_10_ram_bypass),
    .sigFromSrams_bore_10_ram_bp_clken(sigFromSrams_bore_10_ram_bp_clken),
    .sigFromSrams_bore_10_ram_aux_clk(sigFromSrams_bore_10_ram_aux_clk),
    .sigFromSrams_bore_10_ram_aux_ckbp(sigFromSrams_bore_10_ram_aux_ckbp),
    .sigFromSrams_bore_10_ram_mcp_hold(sigFromSrams_bore_10_ram_mcp_hold),
    .sigFromSrams_bore_10_cgen(sigFromSrams_bore_10_cgen),
    .boreChildrenBd_bore_array(6'(boreChildrenBd_bore_array)),
    .boreChildrenBd_bore_all(boreChildrenBd_bore_all),
    .boreChildrenBd_bore_req(boreChildrenBd_bore_req),
    .boreChildrenBd_bore_ack(i2_boreChildrenBd_bore_ack),
    .boreChildrenBd_bore_writeen(boreChildrenBd_bore_writeen),
    .boreChildrenBd_bore_be(boreChildrenBd_bore_be),
    .boreChildrenBd_bore_addr(boreChildrenBd_bore_addr),
    .boreChildrenBd_bore_indata(boreChildrenBd_bore_indata),
    .boreChildrenBd_bore_readen(boreChildrenBd_bore_readen),
    .boreChildrenBd_bore_addr_rd(boreChildrenBd_bore_addr_rd),
    .boreChildrenBd_bore_outdata(i2_boreChildrenBd_bore_outdata)
  );
  Slice_3 u_g3 (
    .clock(clock),
    .reset(reset),
    .io_in_a_ready(g3_io_in_a_ready),
    .io_in_a_valid(io_in_a_valid),
    .io_in_a_bits_opcode(io_in_a_bits_opcode),
    .io_in_a_bits_param(io_in_a_bits_param),
    .io_in_a_bits_size(io_in_a_bits_size),
    .io_in_a_bits_source(io_in_a_bits_source),
    .io_in_a_bits_address(io_in_a_bits_address),
    .io_in_a_bits_user_reqSource(io_in_a_bits_user_reqSource),
    .io_in_a_bits_user_alias(io_in_a_bits_user_alias),
    .io_in_a_bits_user_vaddr(io_in_a_bits_user_vaddr),
    .io_in_a_bits_user_needHint(io_in_a_bits_user_needHint),
    .io_in_a_bits_echo_isKeyword(io_in_a_bits_echo_isKeyword),
    .io_in_a_bits_corrupt(io_in_a_bits_corrupt),
    .io_in_b_ready(io_in_b_ready),
    .io_in_b_valid(g3_io_in_b_valid),
    .io_in_b_bits_opcode(g3_io_in_b_bits_opcode),
    .io_in_b_bits_param(g3_io_in_b_bits_param),
    .io_in_b_bits_address(g3_io_in_b_bits_address),
    .io_in_b_bits_data(g3_io_in_b_bits_data),
    .io_in_c_ready(g3_io_in_c_ready),
    .io_in_c_valid(io_in_c_valid),
    .io_in_c_bits_opcode(io_in_c_bits_opcode),
    .io_in_c_bits_param(io_in_c_bits_param),
    .io_in_c_bits_size(io_in_c_bits_size),
    .io_in_c_bits_source(io_in_c_bits_source),
    .io_in_c_bits_address(io_in_c_bits_address),
    .io_in_c_bits_data(io_in_c_bits_data),
    .io_in_c_bits_corrupt(io_in_c_bits_corrupt),
    .io_in_d_ready(io_in_d_ready),
    .io_in_d_valid(g3_io_in_d_valid),
    .io_in_d_bits_opcode(g3_io_in_d_bits_opcode),
    .io_in_d_bits_param(g3_io_in_d_bits_param),
    .io_in_d_bits_source(g3_io_in_d_bits_source),
    .io_in_d_bits_sink(g3_io_in_d_bits_sink),
    .io_in_d_bits_denied(g3_io_in_d_bits_denied),
    .io_in_d_bits_echo_isKeyword(g3_io_in_d_bits_echo_isKeyword),
    .io_in_d_bits_data(g3_io_in_d_bits_data),
    .io_in_d_bits_corrupt(g3_io_in_d_bits_corrupt),
    .io_in_e_valid(io_in_e_valid),
    .io_in_e_bits_sink(io_in_e_bits_sink),
    .io_l1Hint_ready(io_l1Hint_ready),
    .io_l1Hint_valid(g3_io_l1Hint_valid),
    .io_l1Hint_bits_sourceId(g3_io_l1Hint_bits_sourceId),
    .io_l1Hint_bits_isKeyword(g3_io_l1Hint_bits_isKeyword),
    .io_prefetch_train_ready(io_prefetch_train_ready),
    .io_prefetch_train_valid(g3_io_prefetch_train_valid),
    .io_prefetch_train_bits_tag(g3_io_prefetch_train_bits_tag),
    .io_prefetch_train_bits_set(g3_io_prefetch_train_bits_set),
    .io_prefetch_train_bits_needT(g3_io_prefetch_train_bits_needT),
    .io_prefetch_train_bits_source(g3_io_prefetch_train_bits_source),
    .io_prefetch_train_bits_vaddr(g3_io_prefetch_train_bits_vaddr),
    .io_prefetch_train_bits_hit(g3_io_prefetch_train_bits_hit),
    .io_prefetch_train_bits_prefetched(g3_io_prefetch_train_bits_prefetched),
    .io_prefetch_train_bits_pfsource(g3_io_prefetch_train_bits_pfsource),
    .io_prefetch_train_bits_reqsource(g3_io_prefetch_train_bits_reqsource),
    .io_prefetch_req_ready(g3_io_prefetch_req_ready),
    .io_prefetch_req_valid(io_prefetch_req_valid),
    .io_prefetch_req_bits_tag(io_prefetch_req_bits_tag),
    .io_prefetch_req_bits_set(io_prefetch_req_bits_set),
    .io_prefetch_req_bits_vaddr(io_prefetch_req_bits_vaddr),
    .io_prefetch_req_bits_needT(io_prefetch_req_bits_needT),
    .io_prefetch_req_bits_source(io_prefetch_req_bits_source),
    .io_prefetch_req_bits_pfSource(io_prefetch_req_bits_pfSource),
    .io_prefetch_resp_ready(io_prefetch_resp_ready),
    .io_prefetch_resp_valid(g3_io_prefetch_resp_valid),
    .io_prefetch_resp_bits_tag(g3_io_prefetch_resp_bits_tag),
    .io_prefetch_resp_bits_set(g3_io_prefetch_resp_bits_set),
    .io_prefetch_resp_bits_vaddr(g3_io_prefetch_resp_bits_vaddr),
    .io_prefetch_resp_bits_pfSource(g3_io_prefetch_resp_bits_pfSource),
    .io_dirResult_valid(g3_io_dirResult_valid),
    .io_dirResult_bits_hit(g3_io_dirResult_bits_hit),
    .io_dirResult_bits_meta_prefetch(g3_io_dirResult_bits_meta_prefetch),
    .io_dirResult_bits_meta_prefetchSrc(g3_io_dirResult_bits_meta_prefetchSrc),
    .io_dirResult_bits_replacerInfo_channel(g3_io_dirResult_bits_replacerInfo_channel),
    .io_dirResult_bits_replacerInfo_reqSource(g3_io_dirResult_bits_replacerInfo_reqSource),
    .io_hitPfInMSHR_valid(g3_io_hitPfInMSHR_valid),
    .io_hitPfInMSHR_bits(g3_io_hitPfInMSHR_bits),
    .io_pfSent_valid(g3_io_pfSent_valid),
    .io_pfSent_bits(g3_io_pfSent_bits),
    .io_pfLateInMSHR_valid(g3_io_pfLateInMSHR_valid),
    .io_pfLateInMSHR_bits(g3_io_pfLateInMSHR_bits),
    .io_error_valid(g3_io_error_valid),
    .io_error_bits_valid(g3_io_error_bits_valid),
    .io_error_bits_address(g3_io_error_bits_address),
    .io_l2Miss(g3_io_l2Miss),
    .io_msStatus_0_valid(g3_io_msStatus_0_valid),
    .io_msStatus_0_bits_channel(g3_io_msStatus_0_bits_channel),
    .io_msStatus_0_bits_set(g3_io_msStatus_0_bits_set),
    .io_msStatus_0_bits_reqTag(g3_io_msStatus_0_bits_reqTag),
    .io_msStatus_0_bits_is_miss(g3_io_msStatus_0_bits_is_miss),
    .io_msStatus_0_bits_is_prefetch(g3_io_msStatus_0_bits_is_prefetch),
    .io_msStatus_1_valid(g3_io_msStatus_1_valid),
    .io_msStatus_1_bits_channel(g3_io_msStatus_1_bits_channel),
    .io_msStatus_1_bits_set(g3_io_msStatus_1_bits_set),
    .io_msStatus_1_bits_reqTag(g3_io_msStatus_1_bits_reqTag),
    .io_msStatus_1_bits_is_miss(g3_io_msStatus_1_bits_is_miss),
    .io_msStatus_1_bits_is_prefetch(g3_io_msStatus_1_bits_is_prefetch),
    .io_msStatus_2_valid(g3_io_msStatus_2_valid),
    .io_msStatus_2_bits_channel(g3_io_msStatus_2_bits_channel),
    .io_msStatus_2_bits_set(g3_io_msStatus_2_bits_set),
    .io_msStatus_2_bits_reqTag(g3_io_msStatus_2_bits_reqTag),
    .io_msStatus_2_bits_is_miss(g3_io_msStatus_2_bits_is_miss),
    .io_msStatus_2_bits_is_prefetch(g3_io_msStatus_2_bits_is_prefetch),
    .io_msStatus_3_valid(g3_io_msStatus_3_valid),
    .io_msStatus_3_bits_channel(g3_io_msStatus_3_bits_channel),
    .io_msStatus_3_bits_set(g3_io_msStatus_3_bits_set),
    .io_msStatus_3_bits_reqTag(g3_io_msStatus_3_bits_reqTag),
    .io_msStatus_3_bits_is_miss(g3_io_msStatus_3_bits_is_miss),
    .io_msStatus_3_bits_is_prefetch(g3_io_msStatus_3_bits_is_prefetch),
    .io_msStatus_4_valid(g3_io_msStatus_4_valid),
    .io_msStatus_4_bits_channel(g3_io_msStatus_4_bits_channel),
    .io_msStatus_4_bits_set(g3_io_msStatus_4_bits_set),
    .io_msStatus_4_bits_reqTag(g3_io_msStatus_4_bits_reqTag),
    .io_msStatus_4_bits_is_miss(g3_io_msStatus_4_bits_is_miss),
    .io_msStatus_4_bits_is_prefetch(g3_io_msStatus_4_bits_is_prefetch),
    .io_msStatus_5_valid(g3_io_msStatus_5_valid),
    .io_msStatus_5_bits_channel(g3_io_msStatus_5_bits_channel),
    .io_msStatus_5_bits_set(g3_io_msStatus_5_bits_set),
    .io_msStatus_5_bits_reqTag(g3_io_msStatus_5_bits_reqTag),
    .io_msStatus_5_bits_is_miss(g3_io_msStatus_5_bits_is_miss),
    .io_msStatus_5_bits_is_prefetch(g3_io_msStatus_5_bits_is_prefetch),
    .io_msStatus_6_valid(g3_io_msStatus_6_valid),
    .io_msStatus_6_bits_channel(g3_io_msStatus_6_bits_channel),
    .io_msStatus_6_bits_set(g3_io_msStatus_6_bits_set),
    .io_msStatus_6_bits_reqTag(g3_io_msStatus_6_bits_reqTag),
    .io_msStatus_6_bits_is_miss(g3_io_msStatus_6_bits_is_miss),
    .io_msStatus_6_bits_is_prefetch(g3_io_msStatus_6_bits_is_prefetch),
    .io_msStatus_7_valid(g3_io_msStatus_7_valid),
    .io_msStatus_7_bits_channel(g3_io_msStatus_7_bits_channel),
    .io_msStatus_7_bits_set(g3_io_msStatus_7_bits_set),
    .io_msStatus_7_bits_reqTag(g3_io_msStatus_7_bits_reqTag),
    .io_msStatus_7_bits_is_miss(g3_io_msStatus_7_bits_is_miss),
    .io_msStatus_7_bits_is_prefetch(g3_io_msStatus_7_bits_is_prefetch),
    .io_msStatus_8_valid(g3_io_msStatus_8_valid),
    .io_msStatus_8_bits_channel(g3_io_msStatus_8_bits_channel),
    .io_msStatus_8_bits_set(g3_io_msStatus_8_bits_set),
    .io_msStatus_8_bits_reqTag(g3_io_msStatus_8_bits_reqTag),
    .io_msStatus_8_bits_is_miss(g3_io_msStatus_8_bits_is_miss),
    .io_msStatus_8_bits_is_prefetch(g3_io_msStatus_8_bits_is_prefetch),
    .io_msStatus_9_valid(g3_io_msStatus_9_valid),
    .io_msStatus_9_bits_channel(g3_io_msStatus_9_bits_channel),
    .io_msStatus_9_bits_set(g3_io_msStatus_9_bits_set),
    .io_msStatus_9_bits_reqTag(g3_io_msStatus_9_bits_reqTag),
    .io_msStatus_9_bits_is_miss(g3_io_msStatus_9_bits_is_miss),
    .io_msStatus_9_bits_is_prefetch(g3_io_msStatus_9_bits_is_prefetch),
    .io_msStatus_10_valid(g3_io_msStatus_10_valid),
    .io_msStatus_10_bits_channel(g3_io_msStatus_10_bits_channel),
    .io_msStatus_10_bits_set(g3_io_msStatus_10_bits_set),
    .io_msStatus_10_bits_reqTag(g3_io_msStatus_10_bits_reqTag),
    .io_msStatus_10_bits_is_miss(g3_io_msStatus_10_bits_is_miss),
    .io_msStatus_10_bits_is_prefetch(g3_io_msStatus_10_bits_is_prefetch),
    .io_msStatus_11_valid(g3_io_msStatus_11_valid),
    .io_msStatus_11_bits_channel(g3_io_msStatus_11_bits_channel),
    .io_msStatus_11_bits_set(g3_io_msStatus_11_bits_set),
    .io_msStatus_11_bits_reqTag(g3_io_msStatus_11_bits_reqTag),
    .io_msStatus_11_bits_is_miss(g3_io_msStatus_11_bits_is_miss),
    .io_msStatus_11_bits_is_prefetch(g3_io_msStatus_11_bits_is_prefetch),
    .io_msStatus_12_valid(g3_io_msStatus_12_valid),
    .io_msStatus_12_bits_channel(g3_io_msStatus_12_bits_channel),
    .io_msStatus_12_bits_set(g3_io_msStatus_12_bits_set),
    .io_msStatus_12_bits_reqTag(g3_io_msStatus_12_bits_reqTag),
    .io_msStatus_12_bits_is_miss(g3_io_msStatus_12_bits_is_miss),
    .io_msStatus_12_bits_is_prefetch(g3_io_msStatus_12_bits_is_prefetch),
    .io_msStatus_13_valid(g3_io_msStatus_13_valid),
    .io_msStatus_13_bits_channel(g3_io_msStatus_13_bits_channel),
    .io_msStatus_13_bits_set(g3_io_msStatus_13_bits_set),
    .io_msStatus_13_bits_reqTag(g3_io_msStatus_13_bits_reqTag),
    .io_msStatus_13_bits_is_miss(g3_io_msStatus_13_bits_is_miss),
    .io_msStatus_13_bits_is_prefetch(g3_io_msStatus_13_bits_is_prefetch),
    .io_msStatus_14_valid(g3_io_msStatus_14_valid),
    .io_msStatus_14_bits_channel(g3_io_msStatus_14_bits_channel),
    .io_msStatus_14_bits_set(g3_io_msStatus_14_bits_set),
    .io_msStatus_14_bits_reqTag(g3_io_msStatus_14_bits_reqTag),
    .io_msStatus_14_bits_is_miss(g3_io_msStatus_14_bits_is_miss),
    .io_msStatus_14_bits_is_prefetch(g3_io_msStatus_14_bits_is_prefetch),
    .io_msStatus_15_valid(g3_io_msStatus_15_valid),
    .io_msStatus_15_bits_channel(g3_io_msStatus_15_bits_channel),
    .io_msStatus_15_bits_set(g3_io_msStatus_15_bits_set),
    .io_msStatus_15_bits_reqTag(g3_io_msStatus_15_bits_reqTag),
    .io_msStatus_15_bits_is_miss(g3_io_msStatus_15_bits_is_miss),
    .io_msStatus_15_bits_is_prefetch(g3_io_msStatus_15_bits_is_prefetch),
    .io_msAlloc_0_valid(g3_io_msAlloc_0_valid),
    .io_msAlloc_0_bits_channel(g3_io_msAlloc_0_bits_channel),
    .io_msAlloc_0_bits_is_miss(g3_io_msAlloc_0_bits_is_miss),
    .io_msAlloc_0_bits_is_prefetch(g3_io_msAlloc_0_bits_is_prefetch),
    .io_msAlloc_1_valid(g3_io_msAlloc_1_valid),
    .io_msAlloc_1_bits_channel(g3_io_msAlloc_1_bits_channel),
    .io_msAlloc_1_bits_is_miss(g3_io_msAlloc_1_bits_is_miss),
    .io_msAlloc_1_bits_is_prefetch(g3_io_msAlloc_1_bits_is_prefetch),
    .io_msAlloc_2_valid(g3_io_msAlloc_2_valid),
    .io_msAlloc_2_bits_channel(g3_io_msAlloc_2_bits_channel),
    .io_msAlloc_2_bits_is_miss(g3_io_msAlloc_2_bits_is_miss),
    .io_msAlloc_2_bits_is_prefetch(g3_io_msAlloc_2_bits_is_prefetch),
    .io_msAlloc_3_valid(g3_io_msAlloc_3_valid),
    .io_msAlloc_3_bits_channel(g3_io_msAlloc_3_bits_channel),
    .io_msAlloc_3_bits_is_miss(g3_io_msAlloc_3_bits_is_miss),
    .io_msAlloc_3_bits_is_prefetch(g3_io_msAlloc_3_bits_is_prefetch),
    .io_msAlloc_4_valid(g3_io_msAlloc_4_valid),
    .io_msAlloc_4_bits_channel(g3_io_msAlloc_4_bits_channel),
    .io_msAlloc_4_bits_is_miss(g3_io_msAlloc_4_bits_is_miss),
    .io_msAlloc_4_bits_is_prefetch(g3_io_msAlloc_4_bits_is_prefetch),
    .io_msAlloc_5_valid(g3_io_msAlloc_5_valid),
    .io_msAlloc_5_bits_channel(g3_io_msAlloc_5_bits_channel),
    .io_msAlloc_5_bits_is_miss(g3_io_msAlloc_5_bits_is_miss),
    .io_msAlloc_5_bits_is_prefetch(g3_io_msAlloc_5_bits_is_prefetch),
    .io_msAlloc_6_valid(g3_io_msAlloc_6_valid),
    .io_msAlloc_6_bits_channel(g3_io_msAlloc_6_bits_channel),
    .io_msAlloc_6_bits_is_miss(g3_io_msAlloc_6_bits_is_miss),
    .io_msAlloc_6_bits_is_prefetch(g3_io_msAlloc_6_bits_is_prefetch),
    .io_msAlloc_7_valid(g3_io_msAlloc_7_valid),
    .io_msAlloc_7_bits_channel(g3_io_msAlloc_7_bits_channel),
    .io_msAlloc_7_bits_is_miss(g3_io_msAlloc_7_bits_is_miss),
    .io_msAlloc_7_bits_is_prefetch(g3_io_msAlloc_7_bits_is_prefetch),
    .io_msAlloc_8_valid(g3_io_msAlloc_8_valid),
    .io_msAlloc_8_bits_channel(g3_io_msAlloc_8_bits_channel),
    .io_msAlloc_8_bits_is_miss(g3_io_msAlloc_8_bits_is_miss),
    .io_msAlloc_8_bits_is_prefetch(g3_io_msAlloc_8_bits_is_prefetch),
    .io_msAlloc_9_valid(g3_io_msAlloc_9_valid),
    .io_msAlloc_9_bits_channel(g3_io_msAlloc_9_bits_channel),
    .io_msAlloc_9_bits_is_miss(g3_io_msAlloc_9_bits_is_miss),
    .io_msAlloc_9_bits_is_prefetch(g3_io_msAlloc_9_bits_is_prefetch),
    .io_msAlloc_10_valid(g3_io_msAlloc_10_valid),
    .io_msAlloc_10_bits_channel(g3_io_msAlloc_10_bits_channel),
    .io_msAlloc_10_bits_is_miss(g3_io_msAlloc_10_bits_is_miss),
    .io_msAlloc_10_bits_is_prefetch(g3_io_msAlloc_10_bits_is_prefetch),
    .io_msAlloc_11_valid(g3_io_msAlloc_11_valid),
    .io_msAlloc_11_bits_channel(g3_io_msAlloc_11_bits_channel),
    .io_msAlloc_11_bits_is_miss(g3_io_msAlloc_11_bits_is_miss),
    .io_msAlloc_11_bits_is_prefetch(g3_io_msAlloc_11_bits_is_prefetch),
    .io_msAlloc_12_valid(g3_io_msAlloc_12_valid),
    .io_msAlloc_12_bits_channel(g3_io_msAlloc_12_bits_channel),
    .io_msAlloc_12_bits_is_miss(g3_io_msAlloc_12_bits_is_miss),
    .io_msAlloc_12_bits_is_prefetch(g3_io_msAlloc_12_bits_is_prefetch),
    .io_msAlloc_13_valid(g3_io_msAlloc_13_valid),
    .io_msAlloc_13_bits_channel(g3_io_msAlloc_13_bits_channel),
    .io_msAlloc_13_bits_is_miss(g3_io_msAlloc_13_bits_is_miss),
    .io_msAlloc_13_bits_is_prefetch(g3_io_msAlloc_13_bits_is_prefetch),
    .io_msAlloc_14_valid(g3_io_msAlloc_14_valid),
    .io_msAlloc_14_bits_channel(g3_io_msAlloc_14_bits_channel),
    .io_msAlloc_14_bits_is_miss(g3_io_msAlloc_14_bits_is_miss),
    .io_msAlloc_14_bits_is_prefetch(g3_io_msAlloc_14_bits_is_prefetch),
    .io_msAlloc_15_valid(g3_io_msAlloc_15_valid),
    .io_msAlloc_15_bits_channel(g3_io_msAlloc_15_bits_channel),
    .io_msAlloc_15_bits_is_miss(g3_io_msAlloc_15_bits_is_miss),
    .io_msAlloc_15_bits_is_prefetch(g3_io_msAlloc_15_bits_is_prefetch),
    .io_out_tx_req_ready(io_out_tx_req_ready),
    .io_out_tx_req_valid(g3_io_out_tx_req_valid),
    .io_out_tx_req_bits_qos(g3_io_out_tx_req_bits_qos),
    .io_out_tx_req_bits_txnID(g3_io_out_tx_req_bits_txnID),
    .io_out_tx_req_bits_returnNID(g3_io_out_tx_req_bits_returnNID),
    .io_out_tx_req_bits_stashNIDValid(g3_io_out_tx_req_bits_stashNIDValid),
    .io_out_tx_req_bits_returnTxnID(g3_io_out_tx_req_bits_returnTxnID),
    .io_out_tx_req_bits_opcode(g3_io_out_tx_req_bits_opcode),
    .io_out_tx_req_bits_addr(g3_io_out_tx_req_bits_addr),
    .io_out_tx_req_bits_ns(g3_io_out_tx_req_bits_ns),
    .io_out_tx_req_bits_likelyshared(g3_io_out_tx_req_bits_likelyshared),
    .io_out_tx_req_bits_allowRetry(g3_io_out_tx_req_bits_allowRetry),
    .io_out_tx_req_bits_order(g3_io_out_tx_req_bits_order),
    .io_out_tx_req_bits_pCrdType(g3_io_out_tx_req_bits_pCrdType),
    .io_out_tx_req_bits_memAttr_allocate(g3_io_out_tx_req_bits_memAttr_allocate),
    .io_out_tx_req_bits_memAttr_cacheable(g3_io_out_tx_req_bits_memAttr_cacheable),
    .io_out_tx_req_bits_memAttr_device(g3_io_out_tx_req_bits_memAttr_device),
    .io_out_tx_req_bits_memAttr_ewa(g3_io_out_tx_req_bits_memAttr_ewa),
    .io_out_tx_req_bits_snpAttr(g3_io_out_tx_req_bits_snpAttr),
    .io_out_tx_req_bits_lpIDWithPadding(g3_io_out_tx_req_bits_lpIDWithPadding),
    .io_out_tx_req_bits_snoopMe(g3_io_out_tx_req_bits_snoopMe),
    .io_out_tx_req_bits_expCompAck(g3_io_out_tx_req_bits_expCompAck),
    .io_out_tx_req_bits_tagOp(g3_io_out_tx_req_bits_tagOp),
    .io_out_tx_req_bits_traceTag(g3_io_out_tx_req_bits_traceTag),
    .io_out_tx_req_bits_mpam_perfMonGroup(g3_io_out_tx_req_bits_mpam_perfMonGroup),
    .io_out_tx_req_bits_mpam_partID(g3_io_out_tx_req_bits_mpam_partID),
    .io_out_tx_req_bits_mpam_mpamNS(g3_io_out_tx_req_bits_mpam_mpamNS),
    .io_out_tx_req_bits_rsvdc(g3_io_out_tx_req_bits_rsvdc),
    .io_out_tx_rsp_ready(io_out_tx_rsp_ready),
    .io_out_tx_rsp_valid(g3_io_out_tx_rsp_valid),
    .io_out_tx_rsp_bits_qos(g3_io_out_tx_rsp_bits_qos),
    .io_out_tx_rsp_bits_tgtID(g3_io_out_tx_rsp_bits_tgtID),
    .io_out_tx_rsp_bits_txnID(g3_io_out_tx_rsp_bits_txnID),
    .io_out_tx_rsp_bits_opcode(g3_io_out_tx_rsp_bits_opcode),
    .io_out_tx_rsp_bits_respErr(g3_io_out_tx_rsp_bits_respErr),
    .io_out_tx_rsp_bits_resp(g3_io_out_tx_rsp_bits_resp),
    .io_out_tx_rsp_bits_fwdState(g3_io_out_tx_rsp_bits_fwdState),
    .io_out_tx_rsp_bits_cBusy(g3_io_out_tx_rsp_bits_cBusy),
    .io_out_tx_rsp_bits_dbID(g3_io_out_tx_rsp_bits_dbID),
    .io_out_tx_rsp_bits_pCrdType(g3_io_out_tx_rsp_bits_pCrdType),
    .io_out_tx_rsp_bits_tagOp(g3_io_out_tx_rsp_bits_tagOp),
    .io_out_tx_rsp_bits_traceTag(g3_io_out_tx_rsp_bits_traceTag),
    .io_out_tx_dat_ready(io_out_tx_dat_ready),
    .io_out_tx_dat_valid(g3_io_out_tx_dat_valid),
    .io_out_tx_dat_bits_tgtID(g3_io_out_tx_dat_bits_tgtID),
    .io_out_tx_dat_bits_txnID(g3_io_out_tx_dat_bits_txnID),
    .io_out_tx_dat_bits_homeNID(g3_io_out_tx_dat_bits_homeNID),
    .io_out_tx_dat_bits_opcode(g3_io_out_tx_dat_bits_opcode),
    .io_out_tx_dat_bits_respErr(g3_io_out_tx_dat_bits_respErr),
    .io_out_tx_dat_bits_resp(g3_io_out_tx_dat_bits_resp),
    .io_out_tx_dat_bits_dataSource(g3_io_out_tx_dat_bits_dataSource),
    .io_out_tx_dat_bits_dbID(g3_io_out_tx_dat_bits_dbID),
    .io_out_tx_dat_bits_ccID(g3_io_out_tx_dat_bits_ccID),
    .io_out_tx_dat_bits_dataID(g3_io_out_tx_dat_bits_dataID),
    .io_out_tx_dat_bits_traceTag(g3_io_out_tx_dat_bits_traceTag),
    .io_out_tx_dat_bits_be(g3_io_out_tx_dat_bits_be),
    .io_out_tx_dat_bits_data(g3_io_out_tx_dat_bits_data),
    .io_out_tx_dat_bits_dataCheck(g3_io_out_tx_dat_bits_dataCheck),
    .io_out_tx_dat_bits_poison(g3_io_out_tx_dat_bits_poison),
    .io_out_rx_rsp_valid(io_out_rx_rsp_valid),
    .io_out_rx_rsp_bits_srcID(io_out_rx_rsp_bits_srcID),
    .io_out_rx_rsp_bits_txnID(io_out_rx_rsp_bits_txnID),
    .io_out_rx_rsp_bits_opcode(io_out_rx_rsp_bits_opcode),
    .io_out_rx_rsp_bits_respErr(io_out_rx_rsp_bits_respErr),
    .io_out_rx_rsp_bits_resp(io_out_rx_rsp_bits_resp),
    .io_out_rx_rsp_bits_dbID(io_out_rx_rsp_bits_dbID),
    .io_out_rx_rsp_bits_pCrdType(io_out_rx_rsp_bits_pCrdType),
    .io_out_rx_rsp_bits_traceTag(io_out_rx_rsp_bits_traceTag),
    .io_out_rx_dat_valid(io_out_rx_dat_valid),
    .io_out_rx_dat_bits_txnID(io_out_rx_dat_bits_txnID),
    .io_out_rx_dat_bits_homeNID(io_out_rx_dat_bits_homeNID),
    .io_out_rx_dat_bits_opcode(io_out_rx_dat_bits_opcode),
    .io_out_rx_dat_bits_respErr(io_out_rx_dat_bits_respErr),
    .io_out_rx_dat_bits_resp(io_out_rx_dat_bits_resp),
    .io_out_rx_dat_bits_dbID(io_out_rx_dat_bits_dbID),
    .io_out_rx_dat_bits_dataID(io_out_rx_dat_bits_dataID),
    .io_out_rx_dat_bits_traceTag(io_out_rx_dat_bits_traceTag),
    .io_out_rx_dat_bits_data(io_out_rx_dat_bits_data),
    .io_out_rx_dat_bits_dataCheck(io_out_rx_dat_bits_dataCheck),
    .io_out_rx_dat_bits_poison(io_out_rx_dat_bits_poison),
    .io_out_rx_snp_ready(g3_io_out_rx_snp_ready),
    .io_out_rx_snp_valid(io_out_rx_snp_valid),
    .io_out_rx_snp_bits_qos(io_out_rx_snp_bits_qos),
    .io_out_rx_snp_bits_srcID(io_out_rx_snp_bits_srcID),
    .io_out_rx_snp_bits_txnID(io_out_rx_snp_bits_txnID),
    .io_out_rx_snp_bits_fwdNID(io_out_rx_snp_bits_fwdNID),
    .io_out_rx_snp_bits_fwdTxnID(io_out_rx_snp_bits_fwdTxnID),
    .io_out_rx_snp_bits_opcode(io_out_rx_snp_bits_opcode),
    .io_out_rx_snp_bits_addr(io_out_rx_snp_bits_addr),
    .io_out_rx_snp_bits_ns(io_out_rx_snp_bits_ns),
    .io_out_rx_snp_bits_doNotGoToSD(io_out_rx_snp_bits_doNotGoToSD),
    .io_out_rx_snp_bits_retToSrc(io_out_rx_snp_bits_retToSrc),
    .io_out_rx_snp_bits_traceTag(io_out_rx_snp_bits_traceTag),
    .io_out_rx_snp_bits_mpam_perfMonGroup(io_out_rx_snp_bits_mpam_perfMonGroup),
    .io_out_rx_snp_bits_mpam_partID(io_out_rx_snp_bits_mpam_partID),
    .io_out_rx_snp_bits_mpam_mpamNS(io_out_rx_snp_bits_mpam_mpamNS),
    .io_pCrd_0_query_valid(g3_io_pCrd_0_query_valid),
    .io_pCrd_0_query_bits_pCrdType(g3_io_pCrd_0_query_bits_pCrdType),
    .io_pCrd_0_query_bits_srcID(g3_io_pCrd_0_query_bits_srcID),
    .io_pCrd_0_grant(io_pCrd_0_grant),
    .io_pCrd_1_query_valid(g3_io_pCrd_1_query_valid),
    .io_pCrd_1_query_bits_pCrdType(g3_io_pCrd_1_query_bits_pCrdType),
    .io_pCrd_1_query_bits_srcID(g3_io_pCrd_1_query_bits_srcID),
    .io_pCrd_1_grant(io_pCrd_1_grant),
    .io_pCrd_2_query_valid(g3_io_pCrd_2_query_valid),
    .io_pCrd_2_query_bits_pCrdType(g3_io_pCrd_2_query_bits_pCrdType),
    .io_pCrd_2_query_bits_srcID(g3_io_pCrd_2_query_bits_srcID),
    .io_pCrd_2_grant(io_pCrd_2_grant),
    .io_pCrd_3_query_valid(g3_io_pCrd_3_query_valid),
    .io_pCrd_3_query_bits_pCrdType(g3_io_pCrd_3_query_bits_pCrdType),
    .io_pCrd_3_query_bits_srcID(g3_io_pCrd_3_query_bits_srcID),
    .io_pCrd_3_grant(io_pCrd_3_grant),
    .io_pCrd_4_query_valid(g3_io_pCrd_4_query_valid),
    .io_pCrd_4_query_bits_pCrdType(g3_io_pCrd_4_query_bits_pCrdType),
    .io_pCrd_4_query_bits_srcID(g3_io_pCrd_4_query_bits_srcID),
    .io_pCrd_4_grant(io_pCrd_4_grant),
    .io_pCrd_5_query_valid(g3_io_pCrd_5_query_valid),
    .io_pCrd_5_query_bits_pCrdType(g3_io_pCrd_5_query_bits_pCrdType),
    .io_pCrd_5_query_bits_srcID(g3_io_pCrd_5_query_bits_srcID),
    .io_pCrd_5_grant(io_pCrd_5_grant),
    .io_pCrd_6_query_valid(g3_io_pCrd_6_query_valid),
    .io_pCrd_6_query_bits_pCrdType(g3_io_pCrd_6_query_bits_pCrdType),
    .io_pCrd_6_query_bits_srcID(g3_io_pCrd_6_query_bits_srcID),
    .io_pCrd_6_grant(io_pCrd_6_grant),
    .io_pCrd_7_query_valid(g3_io_pCrd_7_query_valid),
    .io_pCrd_7_query_bits_pCrdType(g3_io_pCrd_7_query_bits_pCrdType),
    .io_pCrd_7_query_bits_srcID(g3_io_pCrd_7_query_bits_srcID),
    .io_pCrd_7_grant(io_pCrd_7_grant),
    .io_pCrd_8_query_valid(g3_io_pCrd_8_query_valid),
    .io_pCrd_8_query_bits_pCrdType(g3_io_pCrd_8_query_bits_pCrdType),
    .io_pCrd_8_query_bits_srcID(g3_io_pCrd_8_query_bits_srcID),
    .io_pCrd_8_grant(io_pCrd_8_grant),
    .io_pCrd_9_query_valid(g3_io_pCrd_9_query_valid),
    .io_pCrd_9_query_bits_pCrdType(g3_io_pCrd_9_query_bits_pCrdType),
    .io_pCrd_9_query_bits_srcID(g3_io_pCrd_9_query_bits_srcID),
    .io_pCrd_9_grant(io_pCrd_9_grant),
    .io_pCrd_10_query_valid(g3_io_pCrd_10_query_valid),
    .io_pCrd_10_query_bits_pCrdType(g3_io_pCrd_10_query_bits_pCrdType),
    .io_pCrd_10_query_bits_srcID(g3_io_pCrd_10_query_bits_srcID),
    .io_pCrd_10_grant(io_pCrd_10_grant),
    .io_pCrd_11_query_valid(g3_io_pCrd_11_query_valid),
    .io_pCrd_11_query_bits_pCrdType(g3_io_pCrd_11_query_bits_pCrdType),
    .io_pCrd_11_query_bits_srcID(g3_io_pCrd_11_query_bits_srcID),
    .io_pCrd_11_grant(io_pCrd_11_grant),
    .io_pCrd_12_query_valid(g3_io_pCrd_12_query_valid),
    .io_pCrd_12_query_bits_pCrdType(g3_io_pCrd_12_query_bits_pCrdType),
    .io_pCrd_12_query_bits_srcID(g3_io_pCrd_12_query_bits_srcID),
    .io_pCrd_12_grant(io_pCrd_12_grant),
    .io_pCrd_13_query_valid(g3_io_pCrd_13_query_valid),
    .io_pCrd_13_query_bits_pCrdType(g3_io_pCrd_13_query_bits_pCrdType),
    .io_pCrd_13_query_bits_srcID(g3_io_pCrd_13_query_bits_srcID),
    .io_pCrd_13_grant(io_pCrd_13_grant),
    .io_pCrd_14_query_valid(g3_io_pCrd_14_query_valid),
    .io_pCrd_14_query_bits_pCrdType(g3_io_pCrd_14_query_bits_pCrdType),
    .io_pCrd_14_query_bits_srcID(g3_io_pCrd_14_query_bits_srcID),
    .io_pCrd_14_grant(io_pCrd_14_grant),
    .io_pCrd_15_query_valid(g3_io_pCrd_15_query_valid),
    .io_pCrd_15_query_bits_pCrdType(g3_io_pCrd_15_query_bits_pCrdType),
    .io_pCrd_15_query_bits_srcID(g3_io_pCrd_15_query_bits_srcID),
    .io_pCrd_15_grant(io_pCrd_15_grant),
    .io_perf_0_value(g3_io_perf_0_value),
    .io_perf_1_value(g3_io_perf_1_value),
    .io_perf_3_value(g3_io_perf_3_value),
    .io_perf_4_value(g3_io_perf_4_value),
    .io_perf_5_value(g3_io_perf_5_value),
    .io_perf_6_value(g3_io_perf_6_value),
    .io_perf_7_value(g3_io_perf_7_value),
    .io_perf_8_value(g3_io_perf_8_value),
    .io_perf_9_value(g3_io_perf_9_value),
    .io_perf_10_value(g3_io_perf_10_value),
    .io_perf_11_value(g3_io_perf_11_value),
    .io_perf_12_value(g3_io_perf_12_value),
    .io_perf_13_value(g3_io_perf_13_value),
    .io_perf_14_value(g3_io_perf_14_value),
    .io_perf_15_value(g3_io_perf_15_value),
    .io_perf_16_value(g3_io_perf_16_value),
    .sigFromSrams_bore_ram_hold(sigFromSrams_bore_ram_hold),
    .sigFromSrams_bore_ram_bypass(sigFromSrams_bore_ram_bypass),
    .sigFromSrams_bore_ram_bp_clken(sigFromSrams_bore_ram_bp_clken),
    .sigFromSrams_bore_ram_aux_clk(sigFromSrams_bore_ram_aux_clk),
    .sigFromSrams_bore_ram_aux_ckbp(sigFromSrams_bore_ram_aux_ckbp),
    .sigFromSrams_bore_ram_mcp_hold(sigFromSrams_bore_ram_mcp_hold),
    .sigFromSrams_bore_cgen(sigFromSrams_bore_cgen),
    .sigFromSrams_bore_1_ram_hold(sigFromSrams_bore_1_ram_hold),
    .sigFromSrams_bore_1_ram_bypass(sigFromSrams_bore_1_ram_bypass),
    .sigFromSrams_bore_1_ram_bp_clken(sigFromSrams_bore_1_ram_bp_clken),
    .sigFromSrams_bore_1_ram_aux_clk(sigFromSrams_bore_1_ram_aux_clk),
    .sigFromSrams_bore_1_ram_aux_ckbp(sigFromSrams_bore_1_ram_aux_ckbp),
    .sigFromSrams_bore_1_ram_mcp_hold(sigFromSrams_bore_1_ram_mcp_hold),
    .sigFromSrams_bore_1_cgen(sigFromSrams_bore_1_cgen),
    .sigFromSrams_bore_2_ram_hold(sigFromSrams_bore_2_ram_hold),
    .sigFromSrams_bore_2_ram_bypass(sigFromSrams_bore_2_ram_bypass),
    .sigFromSrams_bore_2_ram_bp_clken(sigFromSrams_bore_2_ram_bp_clken),
    .sigFromSrams_bore_2_ram_aux_clk(sigFromSrams_bore_2_ram_aux_clk),
    .sigFromSrams_bore_2_ram_aux_ckbp(sigFromSrams_bore_2_ram_aux_ckbp),
    .sigFromSrams_bore_2_ram_mcp_hold(sigFromSrams_bore_2_ram_mcp_hold),
    .sigFromSrams_bore_2_cgen(sigFromSrams_bore_2_cgen),
    .sigFromSrams_bore_3_ram_hold(sigFromSrams_bore_3_ram_hold),
    .sigFromSrams_bore_3_ram_bypass(sigFromSrams_bore_3_ram_bypass),
    .sigFromSrams_bore_3_ram_bp_clken(sigFromSrams_bore_3_ram_bp_clken),
    .sigFromSrams_bore_3_ram_aux_clk(sigFromSrams_bore_3_ram_aux_clk),
    .sigFromSrams_bore_3_ram_aux_ckbp(sigFromSrams_bore_3_ram_aux_ckbp),
    .sigFromSrams_bore_3_ram_mcp_hold(sigFromSrams_bore_3_ram_mcp_hold),
    .sigFromSrams_bore_3_cgen(sigFromSrams_bore_3_cgen),
    .sigFromSrams_bore_4_ram_hold(sigFromSrams_bore_4_ram_hold),
    .sigFromSrams_bore_4_ram_bypass(sigFromSrams_bore_4_ram_bypass),
    .sigFromSrams_bore_4_ram_bp_clken(sigFromSrams_bore_4_ram_bp_clken),
    .sigFromSrams_bore_4_ram_aux_clk(sigFromSrams_bore_4_ram_aux_clk),
    .sigFromSrams_bore_4_ram_aux_ckbp(sigFromSrams_bore_4_ram_aux_ckbp),
    .sigFromSrams_bore_4_ram_mcp_hold(sigFromSrams_bore_4_ram_mcp_hold),
    .sigFromSrams_bore_4_cgen(sigFromSrams_bore_4_cgen),
    .sigFromSrams_bore_5_ram_hold(sigFromSrams_bore_5_ram_hold),
    .sigFromSrams_bore_5_ram_bypass(sigFromSrams_bore_5_ram_bypass),
    .sigFromSrams_bore_5_ram_bp_clken(sigFromSrams_bore_5_ram_bp_clken),
    .sigFromSrams_bore_5_ram_aux_clk(sigFromSrams_bore_5_ram_aux_clk),
    .sigFromSrams_bore_5_ram_aux_ckbp(sigFromSrams_bore_5_ram_aux_ckbp),
    .sigFromSrams_bore_5_ram_mcp_hold(sigFromSrams_bore_5_ram_mcp_hold),
    .sigFromSrams_bore_5_cgen(sigFromSrams_bore_5_cgen),
    .sigFromSrams_bore_6_ram_hold(sigFromSrams_bore_6_ram_hold),
    .sigFromSrams_bore_6_ram_bypass(sigFromSrams_bore_6_ram_bypass),
    .sigFromSrams_bore_6_ram_bp_clken(sigFromSrams_bore_6_ram_bp_clken),
    .sigFromSrams_bore_6_ram_aux_clk(sigFromSrams_bore_6_ram_aux_clk),
    .sigFromSrams_bore_6_ram_aux_ckbp(sigFromSrams_bore_6_ram_aux_ckbp),
    .sigFromSrams_bore_6_ram_mcp_hold(sigFromSrams_bore_6_ram_mcp_hold),
    .sigFromSrams_bore_6_cgen(sigFromSrams_bore_6_cgen),
    .sigFromSrams_bore_7_ram_hold(sigFromSrams_bore_7_ram_hold),
    .sigFromSrams_bore_7_ram_bypass(sigFromSrams_bore_7_ram_bypass),
    .sigFromSrams_bore_7_ram_bp_clken(sigFromSrams_bore_7_ram_bp_clken),
    .sigFromSrams_bore_7_ram_aux_clk(sigFromSrams_bore_7_ram_aux_clk),
    .sigFromSrams_bore_7_ram_aux_ckbp(sigFromSrams_bore_7_ram_aux_ckbp),
    .sigFromSrams_bore_7_ram_mcp_hold(sigFromSrams_bore_7_ram_mcp_hold),
    .sigFromSrams_bore_7_cgen(sigFromSrams_bore_7_cgen),
    .sigFromSrams_bore_8_ram_hold(sigFromSrams_bore_8_ram_hold),
    .sigFromSrams_bore_8_ram_bypass(sigFromSrams_bore_8_ram_bypass),
    .sigFromSrams_bore_8_ram_bp_clken(sigFromSrams_bore_8_ram_bp_clken),
    .sigFromSrams_bore_8_ram_aux_clk(sigFromSrams_bore_8_ram_aux_clk),
    .sigFromSrams_bore_8_ram_aux_ckbp(sigFromSrams_bore_8_ram_aux_ckbp),
    .sigFromSrams_bore_8_ram_mcp_hold(sigFromSrams_bore_8_ram_mcp_hold),
    .sigFromSrams_bore_8_cgen(sigFromSrams_bore_8_cgen),
    .sigFromSrams_bore_9_ram_hold(sigFromSrams_bore_9_ram_hold),
    .sigFromSrams_bore_9_ram_bypass(sigFromSrams_bore_9_ram_bypass),
    .sigFromSrams_bore_9_ram_bp_clken(sigFromSrams_bore_9_ram_bp_clken),
    .sigFromSrams_bore_9_ram_aux_clk(sigFromSrams_bore_9_ram_aux_clk),
    .sigFromSrams_bore_9_ram_aux_ckbp(sigFromSrams_bore_9_ram_aux_ckbp),
    .sigFromSrams_bore_9_ram_mcp_hold(sigFromSrams_bore_9_ram_mcp_hold),
    .sigFromSrams_bore_9_cgen(sigFromSrams_bore_9_cgen),
    .sigFromSrams_bore_10_ram_hold(sigFromSrams_bore_10_ram_hold),
    .sigFromSrams_bore_10_ram_bypass(sigFromSrams_bore_10_ram_bypass),
    .sigFromSrams_bore_10_ram_bp_clken(sigFromSrams_bore_10_ram_bp_clken),
    .sigFromSrams_bore_10_ram_aux_clk(sigFromSrams_bore_10_ram_aux_clk),
    .sigFromSrams_bore_10_ram_aux_ckbp(sigFromSrams_bore_10_ram_aux_ckbp),
    .sigFromSrams_bore_10_ram_mcp_hold(sigFromSrams_bore_10_ram_mcp_hold),
    .sigFromSrams_bore_10_cgen(sigFromSrams_bore_10_cgen),
    .boreChildrenBd_bore_array(6'(boreChildrenBd_bore_array)),
    .boreChildrenBd_bore_all(boreChildrenBd_bore_all),
    .boreChildrenBd_bore_req(boreChildrenBd_bore_req),
    .boreChildrenBd_bore_ack(g3_boreChildrenBd_bore_ack),
    .boreChildrenBd_bore_writeen(boreChildrenBd_bore_writeen),
    .boreChildrenBd_bore_be(boreChildrenBd_bore_be),
    .boreChildrenBd_bore_addr(boreChildrenBd_bore_addr),
    .boreChildrenBd_bore_indata(boreChildrenBd_bore_indata),
    .boreChildrenBd_bore_readen(boreChildrenBd_bore_readen),
    .boreChildrenBd_bore_addr_rd(boreChildrenBd_bore_addr_rd),
    .boreChildrenBd_bore_outdata(g3_boreChildrenBd_bore_outdata)
  );
  Slice_3_xs u_i3 (
    .clock(clock),
    .reset(reset),
    .io_in_a_ready(i3_io_in_a_ready),
    .io_in_a_valid(io_in_a_valid),
    .io_in_a_bits_opcode(io_in_a_bits_opcode),
    .io_in_a_bits_param(io_in_a_bits_param),
    .io_in_a_bits_size(io_in_a_bits_size),
    .io_in_a_bits_source(io_in_a_bits_source),
    .io_in_a_bits_address(io_in_a_bits_address),
    .io_in_a_bits_user_reqSource(io_in_a_bits_user_reqSource),
    .io_in_a_bits_user_alias(io_in_a_bits_user_alias),
    .io_in_a_bits_user_vaddr(io_in_a_bits_user_vaddr),
    .io_in_a_bits_user_needHint(io_in_a_bits_user_needHint),
    .io_in_a_bits_echo_isKeyword(io_in_a_bits_echo_isKeyword),
    .io_in_a_bits_corrupt(io_in_a_bits_corrupt),
    .io_in_b_ready(io_in_b_ready),
    .io_in_b_valid(i3_io_in_b_valid),
    .io_in_b_bits_opcode(i3_io_in_b_bits_opcode),
    .io_in_b_bits_param(i3_io_in_b_bits_param),
    .io_in_b_bits_address(i3_io_in_b_bits_address),
    .io_in_b_bits_data(i3_io_in_b_bits_data),
    .io_in_c_ready(i3_io_in_c_ready),
    .io_in_c_valid(io_in_c_valid),
    .io_in_c_bits_opcode(io_in_c_bits_opcode),
    .io_in_c_bits_param(io_in_c_bits_param),
    .io_in_c_bits_size(io_in_c_bits_size),
    .io_in_c_bits_source(io_in_c_bits_source),
    .io_in_c_bits_address(io_in_c_bits_address),
    .io_in_c_bits_data(io_in_c_bits_data),
    .io_in_c_bits_corrupt(io_in_c_bits_corrupt),
    .io_in_d_ready(io_in_d_ready),
    .io_in_d_valid(i3_io_in_d_valid),
    .io_in_d_bits_opcode(i3_io_in_d_bits_opcode),
    .io_in_d_bits_param(i3_io_in_d_bits_param),
    .io_in_d_bits_source(i3_io_in_d_bits_source),
    .io_in_d_bits_sink(i3_io_in_d_bits_sink),
    .io_in_d_bits_denied(i3_io_in_d_bits_denied),
    .io_in_d_bits_echo_isKeyword(i3_io_in_d_bits_echo_isKeyword),
    .io_in_d_bits_data(i3_io_in_d_bits_data),
    .io_in_d_bits_corrupt(i3_io_in_d_bits_corrupt),
    .io_in_e_valid(io_in_e_valid),
    .io_in_e_bits_sink(io_in_e_bits_sink),
    .io_l1Hint_ready(io_l1Hint_ready),
    .io_l1Hint_valid(i3_io_l1Hint_valid),
    .io_l1Hint_bits_sourceId(i3_io_l1Hint_bits_sourceId),
    .io_l1Hint_bits_isKeyword(i3_io_l1Hint_bits_isKeyword),
    .io_prefetch_train_ready(io_prefetch_train_ready),
    .io_prefetch_train_valid(i3_io_prefetch_train_valid),
    .io_prefetch_train_bits_tag(i3_io_prefetch_train_bits_tag),
    .io_prefetch_train_bits_set(i3_io_prefetch_train_bits_set),
    .io_prefetch_train_bits_needT(i3_io_prefetch_train_bits_needT),
    .io_prefetch_train_bits_source(i3_io_prefetch_train_bits_source),
    .io_prefetch_train_bits_vaddr(i3_io_prefetch_train_bits_vaddr),
    .io_prefetch_train_bits_hit(i3_io_prefetch_train_bits_hit),
    .io_prefetch_train_bits_prefetched(i3_io_prefetch_train_bits_prefetched),
    .io_prefetch_train_bits_pfsource(i3_io_prefetch_train_bits_pfsource),
    .io_prefetch_train_bits_reqsource(i3_io_prefetch_train_bits_reqsource),
    .io_prefetch_req_ready(i3_io_prefetch_req_ready),
    .io_prefetch_req_valid(io_prefetch_req_valid),
    .io_prefetch_req_bits_tag(io_prefetch_req_bits_tag),
    .io_prefetch_req_bits_set(io_prefetch_req_bits_set),
    .io_prefetch_req_bits_vaddr(io_prefetch_req_bits_vaddr),
    .io_prefetch_req_bits_needT(io_prefetch_req_bits_needT),
    .io_prefetch_req_bits_source(io_prefetch_req_bits_source),
    .io_prefetch_req_bits_pfSource(io_prefetch_req_bits_pfSource),
    .io_prefetch_resp_ready(io_prefetch_resp_ready),
    .io_prefetch_resp_valid(i3_io_prefetch_resp_valid),
    .io_prefetch_resp_bits_tag(i3_io_prefetch_resp_bits_tag),
    .io_prefetch_resp_bits_set(i3_io_prefetch_resp_bits_set),
    .io_prefetch_resp_bits_vaddr(i3_io_prefetch_resp_bits_vaddr),
    .io_prefetch_resp_bits_pfSource(i3_io_prefetch_resp_bits_pfSource),
    .io_dirResult_valid(i3_io_dirResult_valid),
    .io_dirResult_bits_hit(i3_io_dirResult_bits_hit),
    .io_dirResult_bits_meta_prefetch(i3_io_dirResult_bits_meta_prefetch),
    .io_dirResult_bits_meta_prefetchSrc(i3_io_dirResult_bits_meta_prefetchSrc),
    .io_dirResult_bits_replacerInfo_channel(i3_io_dirResult_bits_replacerInfo_channel),
    .io_dirResult_bits_replacerInfo_reqSource(i3_io_dirResult_bits_replacerInfo_reqSource),
    .io_hitPfInMSHR_valid(i3_io_hitPfInMSHR_valid),
    .io_hitPfInMSHR_bits(i3_io_hitPfInMSHR_bits),
    .io_pfSent_valid(i3_io_pfSent_valid),
    .io_pfSent_bits(i3_io_pfSent_bits),
    .io_pfLateInMSHR_valid(i3_io_pfLateInMSHR_valid),
    .io_pfLateInMSHR_bits(i3_io_pfLateInMSHR_bits),
    .io_error_valid(i3_io_error_valid),
    .io_error_bits_valid(i3_io_error_bits_valid),
    .io_error_bits_address(i3_io_error_bits_address),
    .io_l2Miss(i3_io_l2Miss),
    .io_msStatus_0_valid(i3_io_msStatus_0_valid),
    .io_msStatus_0_bits_channel(i3_io_msStatus_0_bits_channel),
    .io_msStatus_0_bits_set(i3_io_msStatus_0_bits_set),
    .io_msStatus_0_bits_reqTag(i3_io_msStatus_0_bits_reqTag),
    .io_msStatus_0_bits_is_miss(i3_io_msStatus_0_bits_is_miss),
    .io_msStatus_0_bits_is_prefetch(i3_io_msStatus_0_bits_is_prefetch),
    .io_msStatus_1_valid(i3_io_msStatus_1_valid),
    .io_msStatus_1_bits_channel(i3_io_msStatus_1_bits_channel),
    .io_msStatus_1_bits_set(i3_io_msStatus_1_bits_set),
    .io_msStatus_1_bits_reqTag(i3_io_msStatus_1_bits_reqTag),
    .io_msStatus_1_bits_is_miss(i3_io_msStatus_1_bits_is_miss),
    .io_msStatus_1_bits_is_prefetch(i3_io_msStatus_1_bits_is_prefetch),
    .io_msStatus_2_valid(i3_io_msStatus_2_valid),
    .io_msStatus_2_bits_channel(i3_io_msStatus_2_bits_channel),
    .io_msStatus_2_bits_set(i3_io_msStatus_2_bits_set),
    .io_msStatus_2_bits_reqTag(i3_io_msStatus_2_bits_reqTag),
    .io_msStatus_2_bits_is_miss(i3_io_msStatus_2_bits_is_miss),
    .io_msStatus_2_bits_is_prefetch(i3_io_msStatus_2_bits_is_prefetch),
    .io_msStatus_3_valid(i3_io_msStatus_3_valid),
    .io_msStatus_3_bits_channel(i3_io_msStatus_3_bits_channel),
    .io_msStatus_3_bits_set(i3_io_msStatus_3_bits_set),
    .io_msStatus_3_bits_reqTag(i3_io_msStatus_3_bits_reqTag),
    .io_msStatus_3_bits_is_miss(i3_io_msStatus_3_bits_is_miss),
    .io_msStatus_3_bits_is_prefetch(i3_io_msStatus_3_bits_is_prefetch),
    .io_msStatus_4_valid(i3_io_msStatus_4_valid),
    .io_msStatus_4_bits_channel(i3_io_msStatus_4_bits_channel),
    .io_msStatus_4_bits_set(i3_io_msStatus_4_bits_set),
    .io_msStatus_4_bits_reqTag(i3_io_msStatus_4_bits_reqTag),
    .io_msStatus_4_bits_is_miss(i3_io_msStatus_4_bits_is_miss),
    .io_msStatus_4_bits_is_prefetch(i3_io_msStatus_4_bits_is_prefetch),
    .io_msStatus_5_valid(i3_io_msStatus_5_valid),
    .io_msStatus_5_bits_channel(i3_io_msStatus_5_bits_channel),
    .io_msStatus_5_bits_set(i3_io_msStatus_5_bits_set),
    .io_msStatus_5_bits_reqTag(i3_io_msStatus_5_bits_reqTag),
    .io_msStatus_5_bits_is_miss(i3_io_msStatus_5_bits_is_miss),
    .io_msStatus_5_bits_is_prefetch(i3_io_msStatus_5_bits_is_prefetch),
    .io_msStatus_6_valid(i3_io_msStatus_6_valid),
    .io_msStatus_6_bits_channel(i3_io_msStatus_6_bits_channel),
    .io_msStatus_6_bits_set(i3_io_msStatus_6_bits_set),
    .io_msStatus_6_bits_reqTag(i3_io_msStatus_6_bits_reqTag),
    .io_msStatus_6_bits_is_miss(i3_io_msStatus_6_bits_is_miss),
    .io_msStatus_6_bits_is_prefetch(i3_io_msStatus_6_bits_is_prefetch),
    .io_msStatus_7_valid(i3_io_msStatus_7_valid),
    .io_msStatus_7_bits_channel(i3_io_msStatus_7_bits_channel),
    .io_msStatus_7_bits_set(i3_io_msStatus_7_bits_set),
    .io_msStatus_7_bits_reqTag(i3_io_msStatus_7_bits_reqTag),
    .io_msStatus_7_bits_is_miss(i3_io_msStatus_7_bits_is_miss),
    .io_msStatus_7_bits_is_prefetch(i3_io_msStatus_7_bits_is_prefetch),
    .io_msStatus_8_valid(i3_io_msStatus_8_valid),
    .io_msStatus_8_bits_channel(i3_io_msStatus_8_bits_channel),
    .io_msStatus_8_bits_set(i3_io_msStatus_8_bits_set),
    .io_msStatus_8_bits_reqTag(i3_io_msStatus_8_bits_reqTag),
    .io_msStatus_8_bits_is_miss(i3_io_msStatus_8_bits_is_miss),
    .io_msStatus_8_bits_is_prefetch(i3_io_msStatus_8_bits_is_prefetch),
    .io_msStatus_9_valid(i3_io_msStatus_9_valid),
    .io_msStatus_9_bits_channel(i3_io_msStatus_9_bits_channel),
    .io_msStatus_9_bits_set(i3_io_msStatus_9_bits_set),
    .io_msStatus_9_bits_reqTag(i3_io_msStatus_9_bits_reqTag),
    .io_msStatus_9_bits_is_miss(i3_io_msStatus_9_bits_is_miss),
    .io_msStatus_9_bits_is_prefetch(i3_io_msStatus_9_bits_is_prefetch),
    .io_msStatus_10_valid(i3_io_msStatus_10_valid),
    .io_msStatus_10_bits_channel(i3_io_msStatus_10_bits_channel),
    .io_msStatus_10_bits_set(i3_io_msStatus_10_bits_set),
    .io_msStatus_10_bits_reqTag(i3_io_msStatus_10_bits_reqTag),
    .io_msStatus_10_bits_is_miss(i3_io_msStatus_10_bits_is_miss),
    .io_msStatus_10_bits_is_prefetch(i3_io_msStatus_10_bits_is_prefetch),
    .io_msStatus_11_valid(i3_io_msStatus_11_valid),
    .io_msStatus_11_bits_channel(i3_io_msStatus_11_bits_channel),
    .io_msStatus_11_bits_set(i3_io_msStatus_11_bits_set),
    .io_msStatus_11_bits_reqTag(i3_io_msStatus_11_bits_reqTag),
    .io_msStatus_11_bits_is_miss(i3_io_msStatus_11_bits_is_miss),
    .io_msStatus_11_bits_is_prefetch(i3_io_msStatus_11_bits_is_prefetch),
    .io_msStatus_12_valid(i3_io_msStatus_12_valid),
    .io_msStatus_12_bits_channel(i3_io_msStatus_12_bits_channel),
    .io_msStatus_12_bits_set(i3_io_msStatus_12_bits_set),
    .io_msStatus_12_bits_reqTag(i3_io_msStatus_12_bits_reqTag),
    .io_msStatus_12_bits_is_miss(i3_io_msStatus_12_bits_is_miss),
    .io_msStatus_12_bits_is_prefetch(i3_io_msStatus_12_bits_is_prefetch),
    .io_msStatus_13_valid(i3_io_msStatus_13_valid),
    .io_msStatus_13_bits_channel(i3_io_msStatus_13_bits_channel),
    .io_msStatus_13_bits_set(i3_io_msStatus_13_bits_set),
    .io_msStatus_13_bits_reqTag(i3_io_msStatus_13_bits_reqTag),
    .io_msStatus_13_bits_is_miss(i3_io_msStatus_13_bits_is_miss),
    .io_msStatus_13_bits_is_prefetch(i3_io_msStatus_13_bits_is_prefetch),
    .io_msStatus_14_valid(i3_io_msStatus_14_valid),
    .io_msStatus_14_bits_channel(i3_io_msStatus_14_bits_channel),
    .io_msStatus_14_bits_set(i3_io_msStatus_14_bits_set),
    .io_msStatus_14_bits_reqTag(i3_io_msStatus_14_bits_reqTag),
    .io_msStatus_14_bits_is_miss(i3_io_msStatus_14_bits_is_miss),
    .io_msStatus_14_bits_is_prefetch(i3_io_msStatus_14_bits_is_prefetch),
    .io_msStatus_15_valid(i3_io_msStatus_15_valid),
    .io_msStatus_15_bits_channel(i3_io_msStatus_15_bits_channel),
    .io_msStatus_15_bits_set(i3_io_msStatus_15_bits_set),
    .io_msStatus_15_bits_reqTag(i3_io_msStatus_15_bits_reqTag),
    .io_msStatus_15_bits_is_miss(i3_io_msStatus_15_bits_is_miss),
    .io_msStatus_15_bits_is_prefetch(i3_io_msStatus_15_bits_is_prefetch),
    .io_msAlloc_0_valid(i3_io_msAlloc_0_valid),
    .io_msAlloc_0_bits_channel(i3_io_msAlloc_0_bits_channel),
    .io_msAlloc_0_bits_is_miss(i3_io_msAlloc_0_bits_is_miss),
    .io_msAlloc_0_bits_is_prefetch(i3_io_msAlloc_0_bits_is_prefetch),
    .io_msAlloc_1_valid(i3_io_msAlloc_1_valid),
    .io_msAlloc_1_bits_channel(i3_io_msAlloc_1_bits_channel),
    .io_msAlloc_1_bits_is_miss(i3_io_msAlloc_1_bits_is_miss),
    .io_msAlloc_1_bits_is_prefetch(i3_io_msAlloc_1_bits_is_prefetch),
    .io_msAlloc_2_valid(i3_io_msAlloc_2_valid),
    .io_msAlloc_2_bits_channel(i3_io_msAlloc_2_bits_channel),
    .io_msAlloc_2_bits_is_miss(i3_io_msAlloc_2_bits_is_miss),
    .io_msAlloc_2_bits_is_prefetch(i3_io_msAlloc_2_bits_is_prefetch),
    .io_msAlloc_3_valid(i3_io_msAlloc_3_valid),
    .io_msAlloc_3_bits_channel(i3_io_msAlloc_3_bits_channel),
    .io_msAlloc_3_bits_is_miss(i3_io_msAlloc_3_bits_is_miss),
    .io_msAlloc_3_bits_is_prefetch(i3_io_msAlloc_3_bits_is_prefetch),
    .io_msAlloc_4_valid(i3_io_msAlloc_4_valid),
    .io_msAlloc_4_bits_channel(i3_io_msAlloc_4_bits_channel),
    .io_msAlloc_4_bits_is_miss(i3_io_msAlloc_4_bits_is_miss),
    .io_msAlloc_4_bits_is_prefetch(i3_io_msAlloc_4_bits_is_prefetch),
    .io_msAlloc_5_valid(i3_io_msAlloc_5_valid),
    .io_msAlloc_5_bits_channel(i3_io_msAlloc_5_bits_channel),
    .io_msAlloc_5_bits_is_miss(i3_io_msAlloc_5_bits_is_miss),
    .io_msAlloc_5_bits_is_prefetch(i3_io_msAlloc_5_bits_is_prefetch),
    .io_msAlloc_6_valid(i3_io_msAlloc_6_valid),
    .io_msAlloc_6_bits_channel(i3_io_msAlloc_6_bits_channel),
    .io_msAlloc_6_bits_is_miss(i3_io_msAlloc_6_bits_is_miss),
    .io_msAlloc_6_bits_is_prefetch(i3_io_msAlloc_6_bits_is_prefetch),
    .io_msAlloc_7_valid(i3_io_msAlloc_7_valid),
    .io_msAlloc_7_bits_channel(i3_io_msAlloc_7_bits_channel),
    .io_msAlloc_7_bits_is_miss(i3_io_msAlloc_7_bits_is_miss),
    .io_msAlloc_7_bits_is_prefetch(i3_io_msAlloc_7_bits_is_prefetch),
    .io_msAlloc_8_valid(i3_io_msAlloc_8_valid),
    .io_msAlloc_8_bits_channel(i3_io_msAlloc_8_bits_channel),
    .io_msAlloc_8_bits_is_miss(i3_io_msAlloc_8_bits_is_miss),
    .io_msAlloc_8_bits_is_prefetch(i3_io_msAlloc_8_bits_is_prefetch),
    .io_msAlloc_9_valid(i3_io_msAlloc_9_valid),
    .io_msAlloc_9_bits_channel(i3_io_msAlloc_9_bits_channel),
    .io_msAlloc_9_bits_is_miss(i3_io_msAlloc_9_bits_is_miss),
    .io_msAlloc_9_bits_is_prefetch(i3_io_msAlloc_9_bits_is_prefetch),
    .io_msAlloc_10_valid(i3_io_msAlloc_10_valid),
    .io_msAlloc_10_bits_channel(i3_io_msAlloc_10_bits_channel),
    .io_msAlloc_10_bits_is_miss(i3_io_msAlloc_10_bits_is_miss),
    .io_msAlloc_10_bits_is_prefetch(i3_io_msAlloc_10_bits_is_prefetch),
    .io_msAlloc_11_valid(i3_io_msAlloc_11_valid),
    .io_msAlloc_11_bits_channel(i3_io_msAlloc_11_bits_channel),
    .io_msAlloc_11_bits_is_miss(i3_io_msAlloc_11_bits_is_miss),
    .io_msAlloc_11_bits_is_prefetch(i3_io_msAlloc_11_bits_is_prefetch),
    .io_msAlloc_12_valid(i3_io_msAlloc_12_valid),
    .io_msAlloc_12_bits_channel(i3_io_msAlloc_12_bits_channel),
    .io_msAlloc_12_bits_is_miss(i3_io_msAlloc_12_bits_is_miss),
    .io_msAlloc_12_bits_is_prefetch(i3_io_msAlloc_12_bits_is_prefetch),
    .io_msAlloc_13_valid(i3_io_msAlloc_13_valid),
    .io_msAlloc_13_bits_channel(i3_io_msAlloc_13_bits_channel),
    .io_msAlloc_13_bits_is_miss(i3_io_msAlloc_13_bits_is_miss),
    .io_msAlloc_13_bits_is_prefetch(i3_io_msAlloc_13_bits_is_prefetch),
    .io_msAlloc_14_valid(i3_io_msAlloc_14_valid),
    .io_msAlloc_14_bits_channel(i3_io_msAlloc_14_bits_channel),
    .io_msAlloc_14_bits_is_miss(i3_io_msAlloc_14_bits_is_miss),
    .io_msAlloc_14_bits_is_prefetch(i3_io_msAlloc_14_bits_is_prefetch),
    .io_msAlloc_15_valid(i3_io_msAlloc_15_valid),
    .io_msAlloc_15_bits_channel(i3_io_msAlloc_15_bits_channel),
    .io_msAlloc_15_bits_is_miss(i3_io_msAlloc_15_bits_is_miss),
    .io_msAlloc_15_bits_is_prefetch(i3_io_msAlloc_15_bits_is_prefetch),
    .io_out_tx_req_ready(io_out_tx_req_ready),
    .io_out_tx_req_valid(i3_io_out_tx_req_valid),
    .io_out_tx_req_bits_qos(i3_io_out_tx_req_bits_qos),
    .io_out_tx_req_bits_txnID(i3_io_out_tx_req_bits_txnID),
    .io_out_tx_req_bits_returnNID(i3_io_out_tx_req_bits_returnNID),
    .io_out_tx_req_bits_stashNIDValid(i3_io_out_tx_req_bits_stashNIDValid),
    .io_out_tx_req_bits_returnTxnID(i3_io_out_tx_req_bits_returnTxnID),
    .io_out_tx_req_bits_opcode(i3_io_out_tx_req_bits_opcode),
    .io_out_tx_req_bits_addr(i3_io_out_tx_req_bits_addr),
    .io_out_tx_req_bits_ns(i3_io_out_tx_req_bits_ns),
    .io_out_tx_req_bits_likelyshared(i3_io_out_tx_req_bits_likelyshared),
    .io_out_tx_req_bits_allowRetry(i3_io_out_tx_req_bits_allowRetry),
    .io_out_tx_req_bits_order(i3_io_out_tx_req_bits_order),
    .io_out_tx_req_bits_pCrdType(i3_io_out_tx_req_bits_pCrdType),
    .io_out_tx_req_bits_memAttr_allocate(i3_io_out_tx_req_bits_memAttr_allocate),
    .io_out_tx_req_bits_memAttr_cacheable(i3_io_out_tx_req_bits_memAttr_cacheable),
    .io_out_tx_req_bits_memAttr_device(i3_io_out_tx_req_bits_memAttr_device),
    .io_out_tx_req_bits_memAttr_ewa(i3_io_out_tx_req_bits_memAttr_ewa),
    .io_out_tx_req_bits_snpAttr(i3_io_out_tx_req_bits_snpAttr),
    .io_out_tx_req_bits_lpIDWithPadding(i3_io_out_tx_req_bits_lpIDWithPadding),
    .io_out_tx_req_bits_snoopMe(i3_io_out_tx_req_bits_snoopMe),
    .io_out_tx_req_bits_expCompAck(i3_io_out_tx_req_bits_expCompAck),
    .io_out_tx_req_bits_tagOp(i3_io_out_tx_req_bits_tagOp),
    .io_out_tx_req_bits_traceTag(i3_io_out_tx_req_bits_traceTag),
    .io_out_tx_req_bits_mpam_perfMonGroup(i3_io_out_tx_req_bits_mpam_perfMonGroup),
    .io_out_tx_req_bits_mpam_partID(i3_io_out_tx_req_bits_mpam_partID),
    .io_out_tx_req_bits_mpam_mpamNS(i3_io_out_tx_req_bits_mpam_mpamNS),
    .io_out_tx_req_bits_rsvdc(i3_io_out_tx_req_bits_rsvdc),
    .io_out_tx_rsp_ready(io_out_tx_rsp_ready),
    .io_out_tx_rsp_valid(i3_io_out_tx_rsp_valid),
    .io_out_tx_rsp_bits_qos(i3_io_out_tx_rsp_bits_qos),
    .io_out_tx_rsp_bits_tgtID(i3_io_out_tx_rsp_bits_tgtID),
    .io_out_tx_rsp_bits_txnID(i3_io_out_tx_rsp_bits_txnID),
    .io_out_tx_rsp_bits_opcode(i3_io_out_tx_rsp_bits_opcode),
    .io_out_tx_rsp_bits_respErr(i3_io_out_tx_rsp_bits_respErr),
    .io_out_tx_rsp_bits_resp(i3_io_out_tx_rsp_bits_resp),
    .io_out_tx_rsp_bits_fwdState(i3_io_out_tx_rsp_bits_fwdState),
    .io_out_tx_rsp_bits_cBusy(i3_io_out_tx_rsp_bits_cBusy),
    .io_out_tx_rsp_bits_dbID(i3_io_out_tx_rsp_bits_dbID),
    .io_out_tx_rsp_bits_pCrdType(i3_io_out_tx_rsp_bits_pCrdType),
    .io_out_tx_rsp_bits_tagOp(i3_io_out_tx_rsp_bits_tagOp),
    .io_out_tx_rsp_bits_traceTag(i3_io_out_tx_rsp_bits_traceTag),
    .io_out_tx_dat_ready(io_out_tx_dat_ready),
    .io_out_tx_dat_valid(i3_io_out_tx_dat_valid),
    .io_out_tx_dat_bits_tgtID(i3_io_out_tx_dat_bits_tgtID),
    .io_out_tx_dat_bits_txnID(i3_io_out_tx_dat_bits_txnID),
    .io_out_tx_dat_bits_homeNID(i3_io_out_tx_dat_bits_homeNID),
    .io_out_tx_dat_bits_opcode(i3_io_out_tx_dat_bits_opcode),
    .io_out_tx_dat_bits_respErr(i3_io_out_tx_dat_bits_respErr),
    .io_out_tx_dat_bits_resp(i3_io_out_tx_dat_bits_resp),
    .io_out_tx_dat_bits_dataSource(i3_io_out_tx_dat_bits_dataSource),
    .io_out_tx_dat_bits_dbID(i3_io_out_tx_dat_bits_dbID),
    .io_out_tx_dat_bits_ccID(i3_io_out_tx_dat_bits_ccID),
    .io_out_tx_dat_bits_dataID(i3_io_out_tx_dat_bits_dataID),
    .io_out_tx_dat_bits_traceTag(i3_io_out_tx_dat_bits_traceTag),
    .io_out_tx_dat_bits_be(i3_io_out_tx_dat_bits_be),
    .io_out_tx_dat_bits_data(i3_io_out_tx_dat_bits_data),
    .io_out_tx_dat_bits_dataCheck(i3_io_out_tx_dat_bits_dataCheck),
    .io_out_tx_dat_bits_poison(i3_io_out_tx_dat_bits_poison),
    .io_out_rx_rsp_valid(io_out_rx_rsp_valid),
    .io_out_rx_rsp_bits_srcID(io_out_rx_rsp_bits_srcID),
    .io_out_rx_rsp_bits_txnID(io_out_rx_rsp_bits_txnID),
    .io_out_rx_rsp_bits_opcode(io_out_rx_rsp_bits_opcode),
    .io_out_rx_rsp_bits_respErr(io_out_rx_rsp_bits_respErr),
    .io_out_rx_rsp_bits_resp(io_out_rx_rsp_bits_resp),
    .io_out_rx_rsp_bits_dbID(io_out_rx_rsp_bits_dbID),
    .io_out_rx_rsp_bits_pCrdType(io_out_rx_rsp_bits_pCrdType),
    .io_out_rx_rsp_bits_traceTag(io_out_rx_rsp_bits_traceTag),
    .io_out_rx_dat_valid(io_out_rx_dat_valid),
    .io_out_rx_dat_bits_txnID(io_out_rx_dat_bits_txnID),
    .io_out_rx_dat_bits_homeNID(io_out_rx_dat_bits_homeNID),
    .io_out_rx_dat_bits_opcode(io_out_rx_dat_bits_opcode),
    .io_out_rx_dat_bits_respErr(io_out_rx_dat_bits_respErr),
    .io_out_rx_dat_bits_resp(io_out_rx_dat_bits_resp),
    .io_out_rx_dat_bits_dbID(io_out_rx_dat_bits_dbID),
    .io_out_rx_dat_bits_dataID(io_out_rx_dat_bits_dataID),
    .io_out_rx_dat_bits_traceTag(io_out_rx_dat_bits_traceTag),
    .io_out_rx_dat_bits_data(io_out_rx_dat_bits_data),
    .io_out_rx_dat_bits_dataCheck(io_out_rx_dat_bits_dataCheck),
    .io_out_rx_dat_bits_poison(io_out_rx_dat_bits_poison),
    .io_out_rx_snp_ready(i3_io_out_rx_snp_ready),
    .io_out_rx_snp_valid(io_out_rx_snp_valid),
    .io_out_rx_snp_bits_qos(io_out_rx_snp_bits_qos),
    .io_out_rx_snp_bits_srcID(io_out_rx_snp_bits_srcID),
    .io_out_rx_snp_bits_txnID(io_out_rx_snp_bits_txnID),
    .io_out_rx_snp_bits_fwdNID(io_out_rx_snp_bits_fwdNID),
    .io_out_rx_snp_bits_fwdTxnID(io_out_rx_snp_bits_fwdTxnID),
    .io_out_rx_snp_bits_opcode(io_out_rx_snp_bits_opcode),
    .io_out_rx_snp_bits_addr(io_out_rx_snp_bits_addr),
    .io_out_rx_snp_bits_ns(io_out_rx_snp_bits_ns),
    .io_out_rx_snp_bits_doNotGoToSD(io_out_rx_snp_bits_doNotGoToSD),
    .io_out_rx_snp_bits_retToSrc(io_out_rx_snp_bits_retToSrc),
    .io_out_rx_snp_bits_traceTag(io_out_rx_snp_bits_traceTag),
    .io_out_rx_snp_bits_mpam_perfMonGroup(io_out_rx_snp_bits_mpam_perfMonGroup),
    .io_out_rx_snp_bits_mpam_partID(io_out_rx_snp_bits_mpam_partID),
    .io_out_rx_snp_bits_mpam_mpamNS(io_out_rx_snp_bits_mpam_mpamNS),
    .io_pCrd_0_query_valid(i3_io_pCrd_0_query_valid),
    .io_pCrd_0_query_bits_pCrdType(i3_io_pCrd_0_query_bits_pCrdType),
    .io_pCrd_0_query_bits_srcID(i3_io_pCrd_0_query_bits_srcID),
    .io_pCrd_0_grant(io_pCrd_0_grant),
    .io_pCrd_1_query_valid(i3_io_pCrd_1_query_valid),
    .io_pCrd_1_query_bits_pCrdType(i3_io_pCrd_1_query_bits_pCrdType),
    .io_pCrd_1_query_bits_srcID(i3_io_pCrd_1_query_bits_srcID),
    .io_pCrd_1_grant(io_pCrd_1_grant),
    .io_pCrd_2_query_valid(i3_io_pCrd_2_query_valid),
    .io_pCrd_2_query_bits_pCrdType(i3_io_pCrd_2_query_bits_pCrdType),
    .io_pCrd_2_query_bits_srcID(i3_io_pCrd_2_query_bits_srcID),
    .io_pCrd_2_grant(io_pCrd_2_grant),
    .io_pCrd_3_query_valid(i3_io_pCrd_3_query_valid),
    .io_pCrd_3_query_bits_pCrdType(i3_io_pCrd_3_query_bits_pCrdType),
    .io_pCrd_3_query_bits_srcID(i3_io_pCrd_3_query_bits_srcID),
    .io_pCrd_3_grant(io_pCrd_3_grant),
    .io_pCrd_4_query_valid(i3_io_pCrd_4_query_valid),
    .io_pCrd_4_query_bits_pCrdType(i3_io_pCrd_4_query_bits_pCrdType),
    .io_pCrd_4_query_bits_srcID(i3_io_pCrd_4_query_bits_srcID),
    .io_pCrd_4_grant(io_pCrd_4_grant),
    .io_pCrd_5_query_valid(i3_io_pCrd_5_query_valid),
    .io_pCrd_5_query_bits_pCrdType(i3_io_pCrd_5_query_bits_pCrdType),
    .io_pCrd_5_query_bits_srcID(i3_io_pCrd_5_query_bits_srcID),
    .io_pCrd_5_grant(io_pCrd_5_grant),
    .io_pCrd_6_query_valid(i3_io_pCrd_6_query_valid),
    .io_pCrd_6_query_bits_pCrdType(i3_io_pCrd_6_query_bits_pCrdType),
    .io_pCrd_6_query_bits_srcID(i3_io_pCrd_6_query_bits_srcID),
    .io_pCrd_6_grant(io_pCrd_6_grant),
    .io_pCrd_7_query_valid(i3_io_pCrd_7_query_valid),
    .io_pCrd_7_query_bits_pCrdType(i3_io_pCrd_7_query_bits_pCrdType),
    .io_pCrd_7_query_bits_srcID(i3_io_pCrd_7_query_bits_srcID),
    .io_pCrd_7_grant(io_pCrd_7_grant),
    .io_pCrd_8_query_valid(i3_io_pCrd_8_query_valid),
    .io_pCrd_8_query_bits_pCrdType(i3_io_pCrd_8_query_bits_pCrdType),
    .io_pCrd_8_query_bits_srcID(i3_io_pCrd_8_query_bits_srcID),
    .io_pCrd_8_grant(io_pCrd_8_grant),
    .io_pCrd_9_query_valid(i3_io_pCrd_9_query_valid),
    .io_pCrd_9_query_bits_pCrdType(i3_io_pCrd_9_query_bits_pCrdType),
    .io_pCrd_9_query_bits_srcID(i3_io_pCrd_9_query_bits_srcID),
    .io_pCrd_9_grant(io_pCrd_9_grant),
    .io_pCrd_10_query_valid(i3_io_pCrd_10_query_valid),
    .io_pCrd_10_query_bits_pCrdType(i3_io_pCrd_10_query_bits_pCrdType),
    .io_pCrd_10_query_bits_srcID(i3_io_pCrd_10_query_bits_srcID),
    .io_pCrd_10_grant(io_pCrd_10_grant),
    .io_pCrd_11_query_valid(i3_io_pCrd_11_query_valid),
    .io_pCrd_11_query_bits_pCrdType(i3_io_pCrd_11_query_bits_pCrdType),
    .io_pCrd_11_query_bits_srcID(i3_io_pCrd_11_query_bits_srcID),
    .io_pCrd_11_grant(io_pCrd_11_grant),
    .io_pCrd_12_query_valid(i3_io_pCrd_12_query_valid),
    .io_pCrd_12_query_bits_pCrdType(i3_io_pCrd_12_query_bits_pCrdType),
    .io_pCrd_12_query_bits_srcID(i3_io_pCrd_12_query_bits_srcID),
    .io_pCrd_12_grant(io_pCrd_12_grant),
    .io_pCrd_13_query_valid(i3_io_pCrd_13_query_valid),
    .io_pCrd_13_query_bits_pCrdType(i3_io_pCrd_13_query_bits_pCrdType),
    .io_pCrd_13_query_bits_srcID(i3_io_pCrd_13_query_bits_srcID),
    .io_pCrd_13_grant(io_pCrd_13_grant),
    .io_pCrd_14_query_valid(i3_io_pCrd_14_query_valid),
    .io_pCrd_14_query_bits_pCrdType(i3_io_pCrd_14_query_bits_pCrdType),
    .io_pCrd_14_query_bits_srcID(i3_io_pCrd_14_query_bits_srcID),
    .io_pCrd_14_grant(io_pCrd_14_grant),
    .io_pCrd_15_query_valid(i3_io_pCrd_15_query_valid),
    .io_pCrd_15_query_bits_pCrdType(i3_io_pCrd_15_query_bits_pCrdType),
    .io_pCrd_15_query_bits_srcID(i3_io_pCrd_15_query_bits_srcID),
    .io_pCrd_15_grant(io_pCrd_15_grant),
    .io_perf_0_value(i3_io_perf_0_value),
    .io_perf_1_value(i3_io_perf_1_value),
    .io_perf_3_value(i3_io_perf_3_value),
    .io_perf_4_value(i3_io_perf_4_value),
    .io_perf_5_value(i3_io_perf_5_value),
    .io_perf_6_value(i3_io_perf_6_value),
    .io_perf_7_value(i3_io_perf_7_value),
    .io_perf_8_value(i3_io_perf_8_value),
    .io_perf_9_value(i3_io_perf_9_value),
    .io_perf_10_value(i3_io_perf_10_value),
    .io_perf_11_value(i3_io_perf_11_value),
    .io_perf_12_value(i3_io_perf_12_value),
    .io_perf_13_value(i3_io_perf_13_value),
    .io_perf_14_value(i3_io_perf_14_value),
    .io_perf_15_value(i3_io_perf_15_value),
    .io_perf_16_value(i3_io_perf_16_value),
    .sigFromSrams_bore_ram_hold(sigFromSrams_bore_ram_hold),
    .sigFromSrams_bore_ram_bypass(sigFromSrams_bore_ram_bypass),
    .sigFromSrams_bore_ram_bp_clken(sigFromSrams_bore_ram_bp_clken),
    .sigFromSrams_bore_ram_aux_clk(sigFromSrams_bore_ram_aux_clk),
    .sigFromSrams_bore_ram_aux_ckbp(sigFromSrams_bore_ram_aux_ckbp),
    .sigFromSrams_bore_ram_mcp_hold(sigFromSrams_bore_ram_mcp_hold),
    .sigFromSrams_bore_cgen(sigFromSrams_bore_cgen),
    .sigFromSrams_bore_1_ram_hold(sigFromSrams_bore_1_ram_hold),
    .sigFromSrams_bore_1_ram_bypass(sigFromSrams_bore_1_ram_bypass),
    .sigFromSrams_bore_1_ram_bp_clken(sigFromSrams_bore_1_ram_bp_clken),
    .sigFromSrams_bore_1_ram_aux_clk(sigFromSrams_bore_1_ram_aux_clk),
    .sigFromSrams_bore_1_ram_aux_ckbp(sigFromSrams_bore_1_ram_aux_ckbp),
    .sigFromSrams_bore_1_ram_mcp_hold(sigFromSrams_bore_1_ram_mcp_hold),
    .sigFromSrams_bore_1_cgen(sigFromSrams_bore_1_cgen),
    .sigFromSrams_bore_2_ram_hold(sigFromSrams_bore_2_ram_hold),
    .sigFromSrams_bore_2_ram_bypass(sigFromSrams_bore_2_ram_bypass),
    .sigFromSrams_bore_2_ram_bp_clken(sigFromSrams_bore_2_ram_bp_clken),
    .sigFromSrams_bore_2_ram_aux_clk(sigFromSrams_bore_2_ram_aux_clk),
    .sigFromSrams_bore_2_ram_aux_ckbp(sigFromSrams_bore_2_ram_aux_ckbp),
    .sigFromSrams_bore_2_ram_mcp_hold(sigFromSrams_bore_2_ram_mcp_hold),
    .sigFromSrams_bore_2_cgen(sigFromSrams_bore_2_cgen),
    .sigFromSrams_bore_3_ram_hold(sigFromSrams_bore_3_ram_hold),
    .sigFromSrams_bore_3_ram_bypass(sigFromSrams_bore_3_ram_bypass),
    .sigFromSrams_bore_3_ram_bp_clken(sigFromSrams_bore_3_ram_bp_clken),
    .sigFromSrams_bore_3_ram_aux_clk(sigFromSrams_bore_3_ram_aux_clk),
    .sigFromSrams_bore_3_ram_aux_ckbp(sigFromSrams_bore_3_ram_aux_ckbp),
    .sigFromSrams_bore_3_ram_mcp_hold(sigFromSrams_bore_3_ram_mcp_hold),
    .sigFromSrams_bore_3_cgen(sigFromSrams_bore_3_cgen),
    .sigFromSrams_bore_4_ram_hold(sigFromSrams_bore_4_ram_hold),
    .sigFromSrams_bore_4_ram_bypass(sigFromSrams_bore_4_ram_bypass),
    .sigFromSrams_bore_4_ram_bp_clken(sigFromSrams_bore_4_ram_bp_clken),
    .sigFromSrams_bore_4_ram_aux_clk(sigFromSrams_bore_4_ram_aux_clk),
    .sigFromSrams_bore_4_ram_aux_ckbp(sigFromSrams_bore_4_ram_aux_ckbp),
    .sigFromSrams_bore_4_ram_mcp_hold(sigFromSrams_bore_4_ram_mcp_hold),
    .sigFromSrams_bore_4_cgen(sigFromSrams_bore_4_cgen),
    .sigFromSrams_bore_5_ram_hold(sigFromSrams_bore_5_ram_hold),
    .sigFromSrams_bore_5_ram_bypass(sigFromSrams_bore_5_ram_bypass),
    .sigFromSrams_bore_5_ram_bp_clken(sigFromSrams_bore_5_ram_bp_clken),
    .sigFromSrams_bore_5_ram_aux_clk(sigFromSrams_bore_5_ram_aux_clk),
    .sigFromSrams_bore_5_ram_aux_ckbp(sigFromSrams_bore_5_ram_aux_ckbp),
    .sigFromSrams_bore_5_ram_mcp_hold(sigFromSrams_bore_5_ram_mcp_hold),
    .sigFromSrams_bore_5_cgen(sigFromSrams_bore_5_cgen),
    .sigFromSrams_bore_6_ram_hold(sigFromSrams_bore_6_ram_hold),
    .sigFromSrams_bore_6_ram_bypass(sigFromSrams_bore_6_ram_bypass),
    .sigFromSrams_bore_6_ram_bp_clken(sigFromSrams_bore_6_ram_bp_clken),
    .sigFromSrams_bore_6_ram_aux_clk(sigFromSrams_bore_6_ram_aux_clk),
    .sigFromSrams_bore_6_ram_aux_ckbp(sigFromSrams_bore_6_ram_aux_ckbp),
    .sigFromSrams_bore_6_ram_mcp_hold(sigFromSrams_bore_6_ram_mcp_hold),
    .sigFromSrams_bore_6_cgen(sigFromSrams_bore_6_cgen),
    .sigFromSrams_bore_7_ram_hold(sigFromSrams_bore_7_ram_hold),
    .sigFromSrams_bore_7_ram_bypass(sigFromSrams_bore_7_ram_bypass),
    .sigFromSrams_bore_7_ram_bp_clken(sigFromSrams_bore_7_ram_bp_clken),
    .sigFromSrams_bore_7_ram_aux_clk(sigFromSrams_bore_7_ram_aux_clk),
    .sigFromSrams_bore_7_ram_aux_ckbp(sigFromSrams_bore_7_ram_aux_ckbp),
    .sigFromSrams_bore_7_ram_mcp_hold(sigFromSrams_bore_7_ram_mcp_hold),
    .sigFromSrams_bore_7_cgen(sigFromSrams_bore_7_cgen),
    .sigFromSrams_bore_8_ram_hold(sigFromSrams_bore_8_ram_hold),
    .sigFromSrams_bore_8_ram_bypass(sigFromSrams_bore_8_ram_bypass),
    .sigFromSrams_bore_8_ram_bp_clken(sigFromSrams_bore_8_ram_bp_clken),
    .sigFromSrams_bore_8_ram_aux_clk(sigFromSrams_bore_8_ram_aux_clk),
    .sigFromSrams_bore_8_ram_aux_ckbp(sigFromSrams_bore_8_ram_aux_ckbp),
    .sigFromSrams_bore_8_ram_mcp_hold(sigFromSrams_bore_8_ram_mcp_hold),
    .sigFromSrams_bore_8_cgen(sigFromSrams_bore_8_cgen),
    .sigFromSrams_bore_9_ram_hold(sigFromSrams_bore_9_ram_hold),
    .sigFromSrams_bore_9_ram_bypass(sigFromSrams_bore_9_ram_bypass),
    .sigFromSrams_bore_9_ram_bp_clken(sigFromSrams_bore_9_ram_bp_clken),
    .sigFromSrams_bore_9_ram_aux_clk(sigFromSrams_bore_9_ram_aux_clk),
    .sigFromSrams_bore_9_ram_aux_ckbp(sigFromSrams_bore_9_ram_aux_ckbp),
    .sigFromSrams_bore_9_ram_mcp_hold(sigFromSrams_bore_9_ram_mcp_hold),
    .sigFromSrams_bore_9_cgen(sigFromSrams_bore_9_cgen),
    .sigFromSrams_bore_10_ram_hold(sigFromSrams_bore_10_ram_hold),
    .sigFromSrams_bore_10_ram_bypass(sigFromSrams_bore_10_ram_bypass),
    .sigFromSrams_bore_10_ram_bp_clken(sigFromSrams_bore_10_ram_bp_clken),
    .sigFromSrams_bore_10_ram_aux_clk(sigFromSrams_bore_10_ram_aux_clk),
    .sigFromSrams_bore_10_ram_aux_ckbp(sigFromSrams_bore_10_ram_aux_ckbp),
    .sigFromSrams_bore_10_ram_mcp_hold(sigFromSrams_bore_10_ram_mcp_hold),
    .sigFromSrams_bore_10_cgen(sigFromSrams_bore_10_cgen),
    .boreChildrenBd_bore_array(6'(boreChildrenBd_bore_array)),
    .boreChildrenBd_bore_all(boreChildrenBd_bore_all),
    .boreChildrenBd_bore_req(boreChildrenBd_bore_req),
    .boreChildrenBd_bore_ack(i3_boreChildrenBd_bore_ack),
    .boreChildrenBd_bore_writeen(boreChildrenBd_bore_writeen),
    .boreChildrenBd_bore_be(boreChildrenBd_bore_be),
    .boreChildrenBd_bore_addr(boreChildrenBd_bore_addr),
    .boreChildrenBd_bore_indata(boreChildrenBd_bore_indata),
    .boreChildrenBd_bore_readen(boreChildrenBd_bore_readen),
    .boreChildrenBd_bore_addr_rd(boreChildrenBd_bore_addr_rd),
    .boreChildrenBd_bore_outdata(i3_boreChildrenBd_bore_outdata)
  );

  function automatic logic [3:0] pick_a_opcode();
    case ($urandom_range(0, 9))
      0, 1: return 4'h4;  2: return 4'h5;  3, 4, 5: return 4'h6;  6, 7: return 4'h7;
      default: return 4'($urandom);
    endcase
  endfunction
  // 地址 = {tag 31 位, set 9 位, bank 2 位, offset 6 位}；tag 压到 0..15（> 8 路，逼出替换）、set 0..3
  function automatic logic [47:0] pick_addr();
    return {31'($urandom_range(0, 15)), 9'($urandom_range(0, 3)), 2'($urandom),
            ($urandom_range(0, 7) == 0) ? 6'($urandom) : 6'h0};
  endfunction

  // RXRSP opcode：RetryAck 3 / Comp 4 / CompDBIDResp 5 / DBIDResp 6 / PCrdGrant 7 / ReadReceipt 8 /
  //               RespSepData B，另 1/8 全随机
  function automatic logic [4:0] pick_rsp_opcode();
    case ($urandom_range(0, 7))
      0: return 5'h3;  1: return 5'h4;  2: return 5'h5;  3: return 5'h6;
      4: return 5'h8;  5: return 5'hB;  6: return 5'h7;  default: return 5'($urandom);
    endcase
  endfunction
  // CHI 响应只发给"合法"的 MSHR（看 golden 第 0 对的 MSHR 状态；四对激励相同）：
  //   kind 0 = RXDAT（CompData/DataSepResp）：数据没收齐（!w_grantlast）且没被 retry；
  //   kind 1 = RetryAck：请求已发出、还没收到任何响应（读：!w_grantfirst && !w_grant；写：!w_releaseack）；
  //   kind 2 = 其余 RXRSP：还在等响应（!w_grant 或 !w_releaseack）且没被 retry。
  // 乱发会把 MSHR 推进不可能的状态（例如拿到数据后又被 retry、retry 后又来数据）而永不释放，
  // 整个 slice 随之停摆 —— 真实 CHI 下这些序列不会出现。没有合法对象时本拍不发（valid=0）。
  function automatic int pick_target(input int kind);
    int c[$];
    if (u_g0.mshrCtl.mshrs_0.req_valid && !u_g0.mshrCtl.mshrs_0.gotRetryAck && (
          kind == 0 ? !u_g0.mshrCtl.mshrs_0.state_w_grantlast :
          kind == 1 ? (u_g0.mshrCtl.mshrs_0.state_s_acquire && !u_g0.mshrCtl.mshrs_0.state_w_grantfirst && !u_g0.mshrCtl.mshrs_0.state_w_grant ||
                       u_g0.mshrCtl.mshrs_0.state_s_release && !u_g0.mshrCtl.mshrs_0.state_w_releaseack) :
                      (!u_g0.mshrCtl.mshrs_0.state_w_grant || !u_g0.mshrCtl.mshrs_0.state_w_releaseack))) c.push_back(0);
    if (u_g0.mshrCtl.mshrs_1.req_valid && !u_g0.mshrCtl.mshrs_1.gotRetryAck && (
          kind == 0 ? !u_g0.mshrCtl.mshrs_1.state_w_grantlast :
          kind == 1 ? (u_g0.mshrCtl.mshrs_1.state_s_acquire && !u_g0.mshrCtl.mshrs_1.state_w_grantfirst && !u_g0.mshrCtl.mshrs_1.state_w_grant ||
                       u_g0.mshrCtl.mshrs_1.state_s_release && !u_g0.mshrCtl.mshrs_1.state_w_releaseack) :
                      (!u_g0.mshrCtl.mshrs_1.state_w_grant || !u_g0.mshrCtl.mshrs_1.state_w_releaseack))) c.push_back(1);
    if (u_g0.mshrCtl.mshrs_2.req_valid && !u_g0.mshrCtl.mshrs_2.gotRetryAck && (
          kind == 0 ? !u_g0.mshrCtl.mshrs_2.state_w_grantlast :
          kind == 1 ? (u_g0.mshrCtl.mshrs_2.state_s_acquire && !u_g0.mshrCtl.mshrs_2.state_w_grantfirst && !u_g0.mshrCtl.mshrs_2.state_w_grant ||
                       u_g0.mshrCtl.mshrs_2.state_s_release && !u_g0.mshrCtl.mshrs_2.state_w_releaseack) :
                      (!u_g0.mshrCtl.mshrs_2.state_w_grant || !u_g0.mshrCtl.mshrs_2.state_w_releaseack))) c.push_back(2);
    if (u_g0.mshrCtl.mshrs_3.req_valid && !u_g0.mshrCtl.mshrs_3.gotRetryAck && (
          kind == 0 ? !u_g0.mshrCtl.mshrs_3.state_w_grantlast :
          kind == 1 ? (u_g0.mshrCtl.mshrs_3.state_s_acquire && !u_g0.mshrCtl.mshrs_3.state_w_grantfirst && !u_g0.mshrCtl.mshrs_3.state_w_grant ||
                       u_g0.mshrCtl.mshrs_3.state_s_release && !u_g0.mshrCtl.mshrs_3.state_w_releaseack) :
                      (!u_g0.mshrCtl.mshrs_3.state_w_grant || !u_g0.mshrCtl.mshrs_3.state_w_releaseack))) c.push_back(3);
    if (u_g0.mshrCtl.mshrs_4.req_valid && !u_g0.mshrCtl.mshrs_4.gotRetryAck && (
          kind == 0 ? !u_g0.mshrCtl.mshrs_4.state_w_grantlast :
          kind == 1 ? (u_g0.mshrCtl.mshrs_4.state_s_acquire && !u_g0.mshrCtl.mshrs_4.state_w_grantfirst && !u_g0.mshrCtl.mshrs_4.state_w_grant ||
                       u_g0.mshrCtl.mshrs_4.state_s_release && !u_g0.mshrCtl.mshrs_4.state_w_releaseack) :
                      (!u_g0.mshrCtl.mshrs_4.state_w_grant || !u_g0.mshrCtl.mshrs_4.state_w_releaseack))) c.push_back(4);
    if (u_g0.mshrCtl.mshrs_5.req_valid && !u_g0.mshrCtl.mshrs_5.gotRetryAck && (
          kind == 0 ? !u_g0.mshrCtl.mshrs_5.state_w_grantlast :
          kind == 1 ? (u_g0.mshrCtl.mshrs_5.state_s_acquire && !u_g0.mshrCtl.mshrs_5.state_w_grantfirst && !u_g0.mshrCtl.mshrs_5.state_w_grant ||
                       u_g0.mshrCtl.mshrs_5.state_s_release && !u_g0.mshrCtl.mshrs_5.state_w_releaseack) :
                      (!u_g0.mshrCtl.mshrs_5.state_w_grant || !u_g0.mshrCtl.mshrs_5.state_w_releaseack))) c.push_back(5);
    if (u_g0.mshrCtl.mshrs_6.req_valid && !u_g0.mshrCtl.mshrs_6.gotRetryAck && (
          kind == 0 ? !u_g0.mshrCtl.mshrs_6.state_w_grantlast :
          kind == 1 ? (u_g0.mshrCtl.mshrs_6.state_s_acquire && !u_g0.mshrCtl.mshrs_6.state_w_grantfirst && !u_g0.mshrCtl.mshrs_6.state_w_grant ||
                       u_g0.mshrCtl.mshrs_6.state_s_release && !u_g0.mshrCtl.mshrs_6.state_w_releaseack) :
                      (!u_g0.mshrCtl.mshrs_6.state_w_grant || !u_g0.mshrCtl.mshrs_6.state_w_releaseack))) c.push_back(6);
    if (u_g0.mshrCtl.mshrs_7.req_valid && !u_g0.mshrCtl.mshrs_7.gotRetryAck && (
          kind == 0 ? !u_g0.mshrCtl.mshrs_7.state_w_grantlast :
          kind == 1 ? (u_g0.mshrCtl.mshrs_7.state_s_acquire && !u_g0.mshrCtl.mshrs_7.state_w_grantfirst && !u_g0.mshrCtl.mshrs_7.state_w_grant ||
                       u_g0.mshrCtl.mshrs_7.state_s_release && !u_g0.mshrCtl.mshrs_7.state_w_releaseack) :
                      (!u_g0.mshrCtl.mshrs_7.state_w_grant || !u_g0.mshrCtl.mshrs_7.state_w_releaseack))) c.push_back(7);
    if (u_g0.mshrCtl.mshrs_8.req_valid && !u_g0.mshrCtl.mshrs_8.gotRetryAck && (
          kind == 0 ? !u_g0.mshrCtl.mshrs_8.state_w_grantlast :
          kind == 1 ? (u_g0.mshrCtl.mshrs_8.state_s_acquire && !u_g0.mshrCtl.mshrs_8.state_w_grantfirst && !u_g0.mshrCtl.mshrs_8.state_w_grant ||
                       u_g0.mshrCtl.mshrs_8.state_s_release && !u_g0.mshrCtl.mshrs_8.state_w_releaseack) :
                      (!u_g0.mshrCtl.mshrs_8.state_w_grant || !u_g0.mshrCtl.mshrs_8.state_w_releaseack))) c.push_back(8);
    if (u_g0.mshrCtl.mshrs_9.req_valid && !u_g0.mshrCtl.mshrs_9.gotRetryAck && (
          kind == 0 ? !u_g0.mshrCtl.mshrs_9.state_w_grantlast :
          kind == 1 ? (u_g0.mshrCtl.mshrs_9.state_s_acquire && !u_g0.mshrCtl.mshrs_9.state_w_grantfirst && !u_g0.mshrCtl.mshrs_9.state_w_grant ||
                       u_g0.mshrCtl.mshrs_9.state_s_release && !u_g0.mshrCtl.mshrs_9.state_w_releaseack) :
                      (!u_g0.mshrCtl.mshrs_9.state_w_grant || !u_g0.mshrCtl.mshrs_9.state_w_releaseack))) c.push_back(9);
    if (u_g0.mshrCtl.mshrs_10.req_valid && !u_g0.mshrCtl.mshrs_10.gotRetryAck && (
          kind == 0 ? !u_g0.mshrCtl.mshrs_10.state_w_grantlast :
          kind == 1 ? (u_g0.mshrCtl.mshrs_10.state_s_acquire && !u_g0.mshrCtl.mshrs_10.state_w_grantfirst && !u_g0.mshrCtl.mshrs_10.state_w_grant ||
                       u_g0.mshrCtl.mshrs_10.state_s_release && !u_g0.mshrCtl.mshrs_10.state_w_releaseack) :
                      (!u_g0.mshrCtl.mshrs_10.state_w_grant || !u_g0.mshrCtl.mshrs_10.state_w_releaseack))) c.push_back(10);
    if (u_g0.mshrCtl.mshrs_11.req_valid && !u_g0.mshrCtl.mshrs_11.gotRetryAck && (
          kind == 0 ? !u_g0.mshrCtl.mshrs_11.state_w_grantlast :
          kind == 1 ? (u_g0.mshrCtl.mshrs_11.state_s_acquire && !u_g0.mshrCtl.mshrs_11.state_w_grantfirst && !u_g0.mshrCtl.mshrs_11.state_w_grant ||
                       u_g0.mshrCtl.mshrs_11.state_s_release && !u_g0.mshrCtl.mshrs_11.state_w_releaseack) :
                      (!u_g0.mshrCtl.mshrs_11.state_w_grant || !u_g0.mshrCtl.mshrs_11.state_w_releaseack))) c.push_back(11);
    if (u_g0.mshrCtl.mshrs_12.req_valid && !u_g0.mshrCtl.mshrs_12.gotRetryAck && (
          kind == 0 ? !u_g0.mshrCtl.mshrs_12.state_w_grantlast :
          kind == 1 ? (u_g0.mshrCtl.mshrs_12.state_s_acquire && !u_g0.mshrCtl.mshrs_12.state_w_grantfirst && !u_g0.mshrCtl.mshrs_12.state_w_grant ||
                       u_g0.mshrCtl.mshrs_12.state_s_release && !u_g0.mshrCtl.mshrs_12.state_w_releaseack) :
                      (!u_g0.mshrCtl.mshrs_12.state_w_grant || !u_g0.mshrCtl.mshrs_12.state_w_releaseack))) c.push_back(12);
    if (u_g0.mshrCtl.mshrs_13.req_valid && !u_g0.mshrCtl.mshrs_13.gotRetryAck && (
          kind == 0 ? !u_g0.mshrCtl.mshrs_13.state_w_grantlast :
          kind == 1 ? (u_g0.mshrCtl.mshrs_13.state_s_acquire && !u_g0.mshrCtl.mshrs_13.state_w_grantfirst && !u_g0.mshrCtl.mshrs_13.state_w_grant ||
                       u_g0.mshrCtl.mshrs_13.state_s_release && !u_g0.mshrCtl.mshrs_13.state_w_releaseack) :
                      (!u_g0.mshrCtl.mshrs_13.state_w_grant || !u_g0.mshrCtl.mshrs_13.state_w_releaseack))) c.push_back(13);
    if (u_g0.mshrCtl.mshrs_14.req_valid && !u_g0.mshrCtl.mshrs_14.gotRetryAck && (
          kind == 0 ? !u_g0.mshrCtl.mshrs_14.state_w_grantlast :
          kind == 1 ? (u_g0.mshrCtl.mshrs_14.state_s_acquire && !u_g0.mshrCtl.mshrs_14.state_w_grantfirst && !u_g0.mshrCtl.mshrs_14.state_w_grant ||
                       u_g0.mshrCtl.mshrs_14.state_s_release && !u_g0.mshrCtl.mshrs_14.state_w_releaseack) :
                      (!u_g0.mshrCtl.mshrs_14.state_w_grant || !u_g0.mshrCtl.mshrs_14.state_w_releaseack))) c.push_back(14);
    if (u_g0.mshrCtl.mshrs_15.req_valid && !u_g0.mshrCtl.mshrs_15.gotRetryAck && (
          kind == 0 ? !u_g0.mshrCtl.mshrs_15.state_w_grantlast :
          kind == 1 ? (u_g0.mshrCtl.mshrs_15.state_s_acquire && !u_g0.mshrCtl.mshrs_15.state_w_grantfirst && !u_g0.mshrCtl.mshrs_15.state_w_grant ||
                       u_g0.mshrCtl.mshrs_15.state_s_release && !u_g0.mshrCtl.mshrs_15.state_w_releaseack) :
                      (!u_g0.mshrCtl.mshrs_15.state_w_grant || !u_g0.mshrCtl.mshrs_15.state_w_releaseack))) c.push_back(15);
    if (c.size() == 0) return -1;
    return c[$urandom_range(0, c.size() - 1)];
  endfunction

  task automatic drive();
    io_in_a_valid = ($urandom_range(0, 3) == 0);
    io_in_a_bits_opcode = pick_a_opcode();
    io_in_a_bits_param = 3'($urandom);
    io_in_a_bits_size = ($urandom_range(0, 7) == 0) ? 3'($urandom) : 3'h6;
    io_in_a_bits_source = 7'($urandom_range(0, 7));
    io_in_a_bits_address = pick_addr();
    io_in_a_bits_user_reqSource = 5'($urandom);
    io_in_a_bits_user_alias = 2'($urandom);
    io_in_a_bits_user_vaddr = 44'({$urandom, $urandom});
    io_in_a_bits_user_needHint = 1'($urandom);
    io_in_a_bits_echo_isKeyword = 1'($urandom);
    io_in_a_bits_corrupt = ($urandom_range(0, 31) == 0);
    io_in_b_ready = ($urandom_range(0, 9) < 8);
    io_in_c_valid = ($urandom_range(0, 9) == 0);
    io_in_c_bits_opcode = ($urandom_range(0, 9) == 0) ? 3'($urandom) : 3'($urandom_range(4, 7));
    io_in_c_bits_param = 3'($urandom);
    io_in_c_bits_size = ($urandom_range(0, 7) == 0) ? 3'($urandom) : 3'h6;
    io_in_c_bits_source = 7'($urandom_range(0, 7));
    io_in_c_bits_address = pick_addr();
    io_in_c_bits_data = 256'({$urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom});
    io_in_c_bits_corrupt = ($urandom_range(0, 31) == 0);
    io_in_d_ready = ($urandom_range(0, 9) < 8);
    io_in_e_valid = ($urandom_range(0, 4) == 0);
    io_in_e_bits_sink = 8'($urandom_range(0, 16));
    io_l1Hint_ready = ($urandom_range(0, 9) < 8);
    io_prefetch_train_ready = ($urandom_range(0, 9) < 8);
    io_prefetch_req_valid = ($urandom_range(0, 15) == 0);
    io_prefetch_req_bits_tag = 33'($urandom_range(0, 15));
    io_prefetch_req_bits_set = 9'($urandom_range(0, 3));
    io_prefetch_req_bits_vaddr = 44'({$urandom, $urandom});
    io_prefetch_req_bits_needT = 1'($urandom);
    io_prefetch_req_bits_source = 7'($urandom_range(0, 7));
    io_prefetch_req_bits_pfSource = 5'($urandom);
    io_prefetch_resp_ready = ($urandom_range(0, 9) < 8);
    io_out_tx_req_ready = ($urandom_range(0, 9) < 8);
    io_out_tx_rsp_ready = ($urandom_range(0, 9) < 8);
    io_out_tx_dat_ready = ($urandom_range(0, 9) < 8);
    io_out_rx_rsp_valid = (slow_phase() ? ($urandom_range(0, 31) == 0) : ($urandom_range(0, 3) == 0));
    io_out_rx_rsp_bits_srcID = ($urandom_range(0, 15) == 0) ? 11'($urandom) : 11'($urandom_range(0, 1));
    io_out_rx_rsp_bits_txnID = 12'($urandom_range(0, 15));
    io_out_rx_rsp_bits_opcode = pick_rsp_opcode();
    io_out_rx_rsp_bits_respErr = ($urandom_range(0, 15) == 0) ? 2'($urandom) : 2'h0;
    io_out_rx_rsp_bits_resp = 3'($urandom);
    io_out_rx_rsp_bits_dbID = 12'($urandom);
    io_out_rx_rsp_bits_pCrdType = 4'($urandom);
    io_out_rx_rsp_bits_traceTag = 1'($urandom);
    io_out_rx_dat_valid = (slow_phase() ? ($urandom_range(0, 31) == 0) : ($urandom_range(0, 3) == 0));
    io_out_rx_dat_bits_txnID = 12'($urandom_range(0, 15));
    io_out_rx_dat_bits_homeNID = ($urandom_range(0, 15) == 0) ? 11'($urandom) : 11'($urandom_range(0, 1));
    io_out_rx_dat_bits_opcode = ($urandom_range(0, 7) == 0) ? 4'($urandom) : (($urandom_range(0, 3) == 0) ? 4'hB : 4'h4);
    io_out_rx_dat_bits_respErr = ($urandom_range(0, 15) == 0) ? 2'($urandom) : 2'h0;
    io_out_rx_dat_bits_resp = 3'($urandom);
    io_out_rx_dat_bits_dbID = 12'($urandom);
    io_out_rx_dat_bits_dataID = 2'($urandom_range(0, 1)) << 1;
    io_out_rx_dat_bits_traceTag = 1'($urandom);
    io_out_rx_dat_bits_data = 256'({$urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom});
    io_out_rx_dat_bits_dataCheck = 32'($urandom);
    io_out_rx_dat_bits_poison = ($urandom_range(0, 15) == 0) ? 4'($urandom) : 4'h0;
    io_out_rx_snp_valid = ($urandom_range(0, 9) == 0);
    io_out_rx_snp_bits_qos = 4'($urandom);
    io_out_rx_snp_bits_srcID = ($urandom_range(0, 15) == 0) ? 11'($urandom) : 11'($urandom_range(0, 1));
    io_out_rx_snp_bits_txnID = 12'($urandom);
    io_out_rx_snp_bits_fwdNID = 11'($urandom);
    io_out_rx_snp_bits_fwdTxnID = 12'($urandom);
    io_out_rx_snp_bits_opcode = ($urandom_range(0, 3) == 0) ? 5'($urandom) : 5'($urandom_range(1, 10));
    io_out_rx_snp_bits_addr = pick_addr() >> 3;
    io_out_rx_snp_bits_ns = 1'($urandom);
    io_out_rx_snp_bits_doNotGoToSD = 1'($urandom);
    io_out_rx_snp_bits_retToSrc = 1'($urandom);
    io_out_rx_snp_bits_traceTag = 1'($urandom);
    io_out_rx_snp_bits_mpam_perfMonGroup = 1'($urandom);
    io_out_rx_snp_bits_mpam_partID = 9'($urandom);
    io_out_rx_snp_bits_mpam_mpamNS = 1'($urandom);
    io_pCrd_0_grant = g0_io_pCrd_0_query_valid && ($urandom_range(0, 3) == 0);
    io_pCrd_1_grant = g0_io_pCrd_1_query_valid && ($urandom_range(0, 3) == 0);
    io_pCrd_2_grant = g0_io_pCrd_2_query_valid && ($urandom_range(0, 3) == 0);
    io_pCrd_3_grant = g0_io_pCrd_3_query_valid && ($urandom_range(0, 3) == 0);
    io_pCrd_4_grant = g0_io_pCrd_4_query_valid && ($urandom_range(0, 3) == 0);
    io_pCrd_5_grant = g0_io_pCrd_5_query_valid && ($urandom_range(0, 3) == 0);
    io_pCrd_6_grant = g0_io_pCrd_6_query_valid && ($urandom_range(0, 3) == 0);
    io_pCrd_7_grant = g0_io_pCrd_7_query_valid && ($urandom_range(0, 3) == 0);
    io_pCrd_8_grant = g0_io_pCrd_8_query_valid && ($urandom_range(0, 3) == 0);
    io_pCrd_9_grant = g0_io_pCrd_9_query_valid && ($urandom_range(0, 3) == 0);
    io_pCrd_10_grant = g0_io_pCrd_10_query_valid && ($urandom_range(0, 3) == 0);
    io_pCrd_11_grant = g0_io_pCrd_11_query_valid && ($urandom_range(0, 3) == 0);
    io_pCrd_12_grant = g0_io_pCrd_12_query_valid && ($urandom_range(0, 3) == 0);
    io_pCrd_13_grant = g0_io_pCrd_13_query_valid && ($urandom_range(0, 3) == 0);
    io_pCrd_14_grant = g0_io_pCrd_14_query_valid && ($urandom_range(0, 3) == 0);
    io_pCrd_15_grant = g0_io_pCrd_15_query_valid && ($urandom_range(0, 3) == 0);
    sigFromSrams_bore_ram_hold = ($urandom_range(0, 63) == 0);
    sigFromSrams_bore_ram_bypass = ($urandom_range(0, 63) == 0);
    sigFromSrams_bore_ram_bp_clken = ($urandom_range(0, 63) == 0);
    sigFromSrams_bore_ram_aux_clk = 1'b0;
    sigFromSrams_bore_ram_aux_ckbp = 1'b0;
    sigFromSrams_bore_ram_mcp_hold = ($urandom_range(0, 63) == 0);
    sigFromSrams_bore_cgen = ($urandom_range(0, 63) == 0);
    sigFromSrams_bore_1_ram_hold = ($urandom_range(0, 63) == 0);
    sigFromSrams_bore_1_ram_bypass = ($urandom_range(0, 63) == 0);
    sigFromSrams_bore_1_ram_bp_clken = ($urandom_range(0, 63) == 0);
    sigFromSrams_bore_1_ram_aux_clk = 1'b0;
    sigFromSrams_bore_1_ram_aux_ckbp = 1'b0;
    sigFromSrams_bore_1_ram_mcp_hold = ($urandom_range(0, 63) == 0);
    sigFromSrams_bore_1_cgen = ($urandom_range(0, 63) == 0);
    sigFromSrams_bore_2_ram_hold = ($urandom_range(0, 63) == 0);
    sigFromSrams_bore_2_ram_bypass = ($urandom_range(0, 63) == 0);
    sigFromSrams_bore_2_ram_bp_clken = ($urandom_range(0, 63) == 0);
    sigFromSrams_bore_2_ram_aux_clk = 1'b0;
    sigFromSrams_bore_2_ram_aux_ckbp = 1'b0;
    sigFromSrams_bore_2_ram_mcp_hold = ($urandom_range(0, 63) == 0);
    sigFromSrams_bore_2_cgen = ($urandom_range(0, 63) == 0);
    sigFromSrams_bore_3_ram_hold = ($urandom_range(0, 63) == 0);
    sigFromSrams_bore_3_ram_bypass = ($urandom_range(0, 63) == 0);
    sigFromSrams_bore_3_ram_bp_clken = ($urandom_range(0, 63) == 0);
    sigFromSrams_bore_3_ram_aux_clk = 1'b0;
    sigFromSrams_bore_3_ram_aux_ckbp = 1'b0;
    sigFromSrams_bore_3_ram_mcp_hold = ($urandom_range(0, 63) == 0);
    sigFromSrams_bore_3_cgen = ($urandom_range(0, 63) == 0);
    sigFromSrams_bore_4_ram_hold = ($urandom_range(0, 63) == 0);
    sigFromSrams_bore_4_ram_bypass = ($urandom_range(0, 63) == 0);
    sigFromSrams_bore_4_ram_bp_clken = ($urandom_range(0, 63) == 0);
    sigFromSrams_bore_4_ram_aux_clk = 1'b0;
    sigFromSrams_bore_4_ram_aux_ckbp = 1'b0;
    sigFromSrams_bore_4_ram_mcp_hold = ($urandom_range(0, 63) == 0);
    sigFromSrams_bore_4_cgen = ($urandom_range(0, 63) == 0);
    sigFromSrams_bore_5_ram_hold = ($urandom_range(0, 63) == 0);
    sigFromSrams_bore_5_ram_bypass = ($urandom_range(0, 63) == 0);
    sigFromSrams_bore_5_ram_bp_clken = ($urandom_range(0, 63) == 0);
    sigFromSrams_bore_5_ram_aux_clk = 1'b0;
    sigFromSrams_bore_5_ram_aux_ckbp = 1'b0;
    sigFromSrams_bore_5_ram_mcp_hold = ($urandom_range(0, 63) == 0);
    sigFromSrams_bore_5_cgen = ($urandom_range(0, 63) == 0);
    sigFromSrams_bore_6_ram_hold = ($urandom_range(0, 63) == 0);
    sigFromSrams_bore_6_ram_bypass = ($urandom_range(0, 63) == 0);
    sigFromSrams_bore_6_ram_bp_clken = ($urandom_range(0, 63) == 0);
    sigFromSrams_bore_6_ram_aux_clk = 1'b0;
    sigFromSrams_bore_6_ram_aux_ckbp = 1'b0;
    sigFromSrams_bore_6_ram_mcp_hold = ($urandom_range(0, 63) == 0);
    sigFromSrams_bore_6_cgen = ($urandom_range(0, 63) == 0);
    sigFromSrams_bore_7_ram_hold = ($urandom_range(0, 63) == 0);
    sigFromSrams_bore_7_ram_bypass = ($urandom_range(0, 63) == 0);
    sigFromSrams_bore_7_ram_bp_clken = ($urandom_range(0, 63) == 0);
    sigFromSrams_bore_7_ram_aux_clk = 1'b0;
    sigFromSrams_bore_7_ram_aux_ckbp = 1'b0;
    sigFromSrams_bore_7_ram_mcp_hold = ($urandom_range(0, 63) == 0);
    sigFromSrams_bore_7_cgen = ($urandom_range(0, 63) == 0);
    sigFromSrams_bore_8_ram_hold = ($urandom_range(0, 63) == 0);
    sigFromSrams_bore_8_ram_bypass = ($urandom_range(0, 63) == 0);
    sigFromSrams_bore_8_ram_bp_clken = ($urandom_range(0, 63) == 0);
    sigFromSrams_bore_8_ram_aux_clk = 1'b0;
    sigFromSrams_bore_8_ram_aux_ckbp = 1'b0;
    sigFromSrams_bore_8_ram_mcp_hold = ($urandom_range(0, 63) == 0);
    sigFromSrams_bore_8_cgen = ($urandom_range(0, 63) == 0);
    sigFromSrams_bore_9_ram_hold = ($urandom_range(0, 63) == 0);
    sigFromSrams_bore_9_ram_bypass = ($urandom_range(0, 63) == 0);
    sigFromSrams_bore_9_ram_bp_clken = ($urandom_range(0, 63) == 0);
    sigFromSrams_bore_9_ram_aux_clk = 1'b0;
    sigFromSrams_bore_9_ram_aux_ckbp = 1'b0;
    sigFromSrams_bore_9_ram_mcp_hold = ($urandom_range(0, 63) == 0);
    sigFromSrams_bore_9_cgen = ($urandom_range(0, 63) == 0);
    sigFromSrams_bore_10_ram_hold = ($urandom_range(0, 63) == 0);
    sigFromSrams_bore_10_ram_bypass = ($urandom_range(0, 63) == 0);
    sigFromSrams_bore_10_ram_bp_clken = ($urandom_range(0, 63) == 0);
    sigFromSrams_bore_10_ram_aux_clk = 1'b0;
    sigFromSrams_bore_10_ram_aux_ckbp = 1'b0;
    sigFromSrams_bore_10_ram_mcp_hold = ($urandom_range(0, 63) == 0);
    sigFromSrams_bore_10_cgen = ($urandom_range(0, 63) == 0);
    boreChildrenBd_bore_array = 6'($urandom);
    boreChildrenBd_bore_all = mbist_phase() ? 1'($urandom) : ($urandom_range(0, 255) == 0);
    boreChildrenBd_bore_req = mbist_phase() ? 1'b1 : ($urandom_range(0, 255) == 0);
    boreChildrenBd_bore_writeen = mbist_phase() ? 1'($urandom) : ($urandom_range(0, 255) == 0);
    boreChildrenBd_bore_be = 8'($urandom);
    boreChildrenBd_bore_addr = 13'($urandom);
    boreChildrenBd_bore_indata = 137'({$urandom, $urandom, $urandom, $urandom, $urandom});
    boreChildrenBd_bore_readen = mbist_phase() ? 1'($urandom) : ($urandom_range(0, 255) == 0);
    boreChildrenBd_bore_addr_rd = 13'($urandom);
    if (io_out_rx_dat_valid) begin
      automatic int t = pick_target(0);
      if (t < 0) io_out_rx_dat_valid = 1'b0; else io_out_rx_dat_bits_txnID = 12'(t);
    end
    if (io_out_rx_rsp_valid && io_out_rx_rsp_bits_opcode != 5'h7) begin   // PCrdGrant 不带 txnID 语义
      automatic int t = pick_target(io_out_rx_rsp_bits_opcode == 5'h3 ? 1 : 2);
      if (t < 0) io_out_rx_rsp_valid = 1'b0; else io_out_rx_rsp_bits_txnID = 12'(t);
    end
    reset = ($urandom_range(0, 19999) == 0);
  endtask

  `define CK(k, nm) begin checks++; if (g``k``_``nm !== i``k``_``nm) begin errors++; \
    if (errors <= 40) $display("[cycle %0d] MISMATCH pair%0d %s golden=%h impl=%h", cyc, k, `"nm`", \
                               g``k``_``nm, i``k``_``nm); \
    end end
  task automatic check();
    `CK(0, io_in_a_ready)
    `CK(0, io_in_b_valid)
    `CK(0, io_in_b_bits_opcode)
    `CK(0, io_in_b_bits_param)
    `CK(0, io_in_b_bits_address)
    `CK(0, io_in_b_bits_data)
    `CK(0, io_in_c_ready)
    `CK(0, io_in_d_valid)
    `CK(0, io_in_d_bits_opcode)
    `CK(0, io_in_d_bits_param)
    `CK(0, io_in_d_bits_source)
    `CK(0, io_in_d_bits_sink)
    `CK(0, io_in_d_bits_denied)
    `CK(0, io_in_d_bits_echo_isKeyword)
    `CK(0, io_in_d_bits_data)
    `CK(0, io_in_d_bits_corrupt)
    `CK(0, io_l1Hint_valid)
    `CK(0, io_l1Hint_bits_sourceId)
    `CK(0, io_l1Hint_bits_isKeyword)
    `CK(0, io_prefetch_train_valid)
    `CK(0, io_prefetch_train_bits_tag)
    `CK(0, io_prefetch_train_bits_set)
    `CK(0, io_prefetch_train_bits_needT)
    `CK(0, io_prefetch_train_bits_source)
    `CK(0, io_prefetch_train_bits_vaddr)
    `CK(0, io_prefetch_train_bits_hit)
    `CK(0, io_prefetch_train_bits_prefetched)
    `CK(0, io_prefetch_train_bits_pfsource)
    `CK(0, io_prefetch_train_bits_reqsource)
    `CK(0, io_prefetch_req_ready)
    `CK(0, io_prefetch_resp_valid)
    `CK(0, io_prefetch_resp_bits_tag)
    `CK(0, io_prefetch_resp_bits_set)
    `CK(0, io_prefetch_resp_bits_vaddr)
    `CK(0, io_prefetch_resp_bits_pfSource)
    `CK(0, io_dirResult_valid)
    `CK(0, io_dirResult_bits_hit)
    `CK(0, io_dirResult_bits_meta_prefetch)
    `CK(0, io_dirResult_bits_meta_prefetchSrc)
    `CK(0, io_dirResult_bits_replacerInfo_channel)
    `CK(0, io_dirResult_bits_replacerInfo_reqSource)
    `CK(0, io_hitPfInMSHR_valid)
    `CK(0, io_hitPfInMSHR_bits)
    `CK(0, io_pfSent_valid)
    `CK(0, io_pfSent_bits)
    `CK(0, io_pfLateInMSHR_valid)
    `CK(0, io_pfLateInMSHR_bits)
    `CK(0, io_error_valid)
    `CK(0, io_error_bits_valid)
    `CK(0, io_error_bits_address)
    `CK(0, io_l2Miss)
    `CK(0, io_msStatus_0_valid)
    `CK(0, io_msStatus_0_bits_channel)
    `CK(0, io_msStatus_0_bits_set)
    `CK(0, io_msStatus_0_bits_reqTag)
    `CK(0, io_msStatus_0_bits_is_miss)
    `CK(0, io_msStatus_0_bits_is_prefetch)
    `CK(0, io_msStatus_1_valid)
    `CK(0, io_msStatus_1_bits_channel)
    `CK(0, io_msStatus_1_bits_set)
    `CK(0, io_msStatus_1_bits_reqTag)
    `CK(0, io_msStatus_1_bits_is_miss)
    `CK(0, io_msStatus_1_bits_is_prefetch)
    `CK(0, io_msStatus_2_valid)
    `CK(0, io_msStatus_2_bits_channel)
    `CK(0, io_msStatus_2_bits_set)
    `CK(0, io_msStatus_2_bits_reqTag)
    `CK(0, io_msStatus_2_bits_is_miss)
    `CK(0, io_msStatus_2_bits_is_prefetch)
    `CK(0, io_msStatus_3_valid)
    `CK(0, io_msStatus_3_bits_channel)
    `CK(0, io_msStatus_3_bits_set)
    `CK(0, io_msStatus_3_bits_reqTag)
    `CK(0, io_msStatus_3_bits_is_miss)
    `CK(0, io_msStatus_3_bits_is_prefetch)
    `CK(0, io_msStatus_4_valid)
    `CK(0, io_msStatus_4_bits_channel)
    `CK(0, io_msStatus_4_bits_set)
    `CK(0, io_msStatus_4_bits_reqTag)
    `CK(0, io_msStatus_4_bits_is_miss)
    `CK(0, io_msStatus_4_bits_is_prefetch)
    `CK(0, io_msStatus_5_valid)
    `CK(0, io_msStatus_5_bits_channel)
    `CK(0, io_msStatus_5_bits_set)
    `CK(0, io_msStatus_5_bits_reqTag)
    `CK(0, io_msStatus_5_bits_is_miss)
    `CK(0, io_msStatus_5_bits_is_prefetch)
    `CK(0, io_msStatus_6_valid)
    `CK(0, io_msStatus_6_bits_channel)
    `CK(0, io_msStatus_6_bits_set)
    `CK(0, io_msStatus_6_bits_reqTag)
    `CK(0, io_msStatus_6_bits_is_miss)
    `CK(0, io_msStatus_6_bits_is_prefetch)
    `CK(0, io_msStatus_7_valid)
    `CK(0, io_msStatus_7_bits_channel)
    `CK(0, io_msStatus_7_bits_set)
    `CK(0, io_msStatus_7_bits_reqTag)
    `CK(0, io_msStatus_7_bits_is_miss)
    `CK(0, io_msStatus_7_bits_is_prefetch)
    `CK(0, io_msStatus_8_valid)
    `CK(0, io_msStatus_8_bits_channel)
    `CK(0, io_msStatus_8_bits_set)
    `CK(0, io_msStatus_8_bits_reqTag)
    `CK(0, io_msStatus_8_bits_is_miss)
    `CK(0, io_msStatus_8_bits_is_prefetch)
    `CK(0, io_msStatus_9_valid)
    `CK(0, io_msStatus_9_bits_channel)
    `CK(0, io_msStatus_9_bits_set)
    `CK(0, io_msStatus_9_bits_reqTag)
    `CK(0, io_msStatus_9_bits_is_miss)
    `CK(0, io_msStatus_9_bits_is_prefetch)
    `CK(0, io_msStatus_10_valid)
    `CK(0, io_msStatus_10_bits_channel)
    `CK(0, io_msStatus_10_bits_set)
    `CK(0, io_msStatus_10_bits_reqTag)
    `CK(0, io_msStatus_10_bits_is_miss)
    `CK(0, io_msStatus_10_bits_is_prefetch)
    `CK(0, io_msStatus_11_valid)
    `CK(0, io_msStatus_11_bits_channel)
    `CK(0, io_msStatus_11_bits_set)
    `CK(0, io_msStatus_11_bits_reqTag)
    `CK(0, io_msStatus_11_bits_is_miss)
    `CK(0, io_msStatus_11_bits_is_prefetch)
    `CK(0, io_msStatus_12_valid)
    `CK(0, io_msStatus_12_bits_channel)
    `CK(0, io_msStatus_12_bits_set)
    `CK(0, io_msStatus_12_bits_reqTag)
    `CK(0, io_msStatus_12_bits_is_miss)
    `CK(0, io_msStatus_12_bits_is_prefetch)
    `CK(0, io_msStatus_13_valid)
    `CK(0, io_msStatus_13_bits_channel)
    `CK(0, io_msStatus_13_bits_set)
    `CK(0, io_msStatus_13_bits_reqTag)
    `CK(0, io_msStatus_13_bits_is_miss)
    `CK(0, io_msStatus_13_bits_is_prefetch)
    `CK(0, io_msStatus_14_valid)
    `CK(0, io_msStatus_14_bits_channel)
    `CK(0, io_msStatus_14_bits_set)
    `CK(0, io_msStatus_14_bits_reqTag)
    `CK(0, io_msStatus_14_bits_is_miss)
    `CK(0, io_msStatus_14_bits_is_prefetch)
    `CK(0, io_msStatus_15_valid)
    `CK(0, io_msStatus_15_bits_channel)
    `CK(0, io_msStatus_15_bits_set)
    `CK(0, io_msStatus_15_bits_reqTag)
    `CK(0, io_msStatus_15_bits_is_miss)
    `CK(0, io_msStatus_15_bits_is_prefetch)
    `CK(0, io_msAlloc_0_valid)
    `CK(0, io_msAlloc_0_bits_channel)
    `CK(0, io_msAlloc_0_bits_is_miss)
    `CK(0, io_msAlloc_0_bits_is_prefetch)
    `CK(0, io_msAlloc_1_valid)
    `CK(0, io_msAlloc_1_bits_channel)
    `CK(0, io_msAlloc_1_bits_is_miss)
    `CK(0, io_msAlloc_1_bits_is_prefetch)
    `CK(0, io_msAlloc_2_valid)
    `CK(0, io_msAlloc_2_bits_channel)
    `CK(0, io_msAlloc_2_bits_is_miss)
    `CK(0, io_msAlloc_2_bits_is_prefetch)
    `CK(0, io_msAlloc_3_valid)
    `CK(0, io_msAlloc_3_bits_channel)
    `CK(0, io_msAlloc_3_bits_is_miss)
    `CK(0, io_msAlloc_3_bits_is_prefetch)
    `CK(0, io_msAlloc_4_valid)
    `CK(0, io_msAlloc_4_bits_channel)
    `CK(0, io_msAlloc_4_bits_is_miss)
    `CK(0, io_msAlloc_4_bits_is_prefetch)
    `CK(0, io_msAlloc_5_valid)
    `CK(0, io_msAlloc_5_bits_channel)
    `CK(0, io_msAlloc_5_bits_is_miss)
    `CK(0, io_msAlloc_5_bits_is_prefetch)
    `CK(0, io_msAlloc_6_valid)
    `CK(0, io_msAlloc_6_bits_channel)
    `CK(0, io_msAlloc_6_bits_is_miss)
    `CK(0, io_msAlloc_6_bits_is_prefetch)
    `CK(0, io_msAlloc_7_valid)
    `CK(0, io_msAlloc_7_bits_channel)
    `CK(0, io_msAlloc_7_bits_is_miss)
    `CK(0, io_msAlloc_7_bits_is_prefetch)
    `CK(0, io_msAlloc_8_valid)
    `CK(0, io_msAlloc_8_bits_channel)
    `CK(0, io_msAlloc_8_bits_is_miss)
    `CK(0, io_msAlloc_8_bits_is_prefetch)
    `CK(0, io_msAlloc_9_valid)
    `CK(0, io_msAlloc_9_bits_channel)
    `CK(0, io_msAlloc_9_bits_is_miss)
    `CK(0, io_msAlloc_9_bits_is_prefetch)
    `CK(0, io_msAlloc_10_valid)
    `CK(0, io_msAlloc_10_bits_channel)
    `CK(0, io_msAlloc_10_bits_is_miss)
    `CK(0, io_msAlloc_10_bits_is_prefetch)
    `CK(0, io_msAlloc_11_valid)
    `CK(0, io_msAlloc_11_bits_channel)
    `CK(0, io_msAlloc_11_bits_is_miss)
    `CK(0, io_msAlloc_11_bits_is_prefetch)
    `CK(0, io_msAlloc_12_valid)
    `CK(0, io_msAlloc_12_bits_channel)
    `CK(0, io_msAlloc_12_bits_is_miss)
    `CK(0, io_msAlloc_12_bits_is_prefetch)
    `CK(0, io_msAlloc_13_valid)
    `CK(0, io_msAlloc_13_bits_channel)
    `CK(0, io_msAlloc_13_bits_is_miss)
    `CK(0, io_msAlloc_13_bits_is_prefetch)
    `CK(0, io_msAlloc_14_valid)
    `CK(0, io_msAlloc_14_bits_channel)
    `CK(0, io_msAlloc_14_bits_is_miss)
    `CK(0, io_msAlloc_14_bits_is_prefetch)
    `CK(0, io_msAlloc_15_valid)
    `CK(0, io_msAlloc_15_bits_channel)
    `CK(0, io_msAlloc_15_bits_is_miss)
    `CK(0, io_msAlloc_15_bits_is_prefetch)
    `CK(0, io_out_tx_req_valid)
    `CK(0, io_out_tx_req_bits_qos)
    `CK(0, io_out_tx_req_bits_txnID)
    `CK(0, io_out_tx_req_bits_returnNID)
    `CK(0, io_out_tx_req_bits_stashNIDValid)
    `CK(0, io_out_tx_req_bits_returnTxnID)
    `CK(0, io_out_tx_req_bits_opcode)
    `CK(0, io_out_tx_req_bits_addr)
    `CK(0, io_out_tx_req_bits_ns)
    `CK(0, io_out_tx_req_bits_likelyshared)
    `CK(0, io_out_tx_req_bits_allowRetry)
    `CK(0, io_out_tx_req_bits_order)
    `CK(0, io_out_tx_req_bits_pCrdType)
    `CK(0, io_out_tx_req_bits_memAttr_allocate)
    `CK(0, io_out_tx_req_bits_memAttr_cacheable)
    `CK(0, io_out_tx_req_bits_memAttr_device)
    `CK(0, io_out_tx_req_bits_memAttr_ewa)
    `CK(0, io_out_tx_req_bits_snpAttr)
    `CK(0, io_out_tx_req_bits_lpIDWithPadding)
    `CK(0, io_out_tx_req_bits_snoopMe)
    `CK(0, io_out_tx_req_bits_expCompAck)
    `CK(0, io_out_tx_req_bits_tagOp)
    `CK(0, io_out_tx_req_bits_traceTag)
    `CK(0, io_out_tx_req_bits_mpam_perfMonGroup)
    `CK(0, io_out_tx_req_bits_mpam_partID)
    `CK(0, io_out_tx_req_bits_mpam_mpamNS)
    `CK(0, io_out_tx_req_bits_rsvdc)
    `CK(0, io_out_tx_rsp_valid)
    `CK(0, io_out_tx_rsp_bits_qos)
    `CK(0, io_out_tx_rsp_bits_tgtID)
    `CK(0, io_out_tx_rsp_bits_txnID)
    `CK(0, io_out_tx_rsp_bits_opcode)
    `CK(0, io_out_tx_rsp_bits_respErr)
    `CK(0, io_out_tx_rsp_bits_resp)
    `CK(0, io_out_tx_rsp_bits_fwdState)
    `CK(0, io_out_tx_rsp_bits_cBusy)
    `CK(0, io_out_tx_rsp_bits_dbID)
    `CK(0, io_out_tx_rsp_bits_pCrdType)
    `CK(0, io_out_tx_rsp_bits_tagOp)
    `CK(0, io_out_tx_rsp_bits_traceTag)
    `CK(0, io_out_tx_dat_valid)
    `CK(0, io_out_tx_dat_bits_tgtID)
    `CK(0, io_out_tx_dat_bits_txnID)
    `CK(0, io_out_tx_dat_bits_homeNID)
    `CK(0, io_out_tx_dat_bits_opcode)
    `CK(0, io_out_tx_dat_bits_respErr)
    `CK(0, io_out_tx_dat_bits_resp)
    `CK(0, io_out_tx_dat_bits_dataSource)
    `CK(0, io_out_tx_dat_bits_dbID)
    `CK(0, io_out_tx_dat_bits_ccID)
    `CK(0, io_out_tx_dat_bits_dataID)
    `CK(0, io_out_tx_dat_bits_traceTag)
    `CK(0, io_out_tx_dat_bits_be)
    `CK(0, io_out_tx_dat_bits_data)
    `CK(0, io_out_tx_dat_bits_dataCheck)
    `CK(0, io_out_tx_dat_bits_poison)
    `CK(0, io_out_rx_snp_ready)
    `CK(0, io_pCrd_0_query_valid)
    `CK(0, io_pCrd_0_query_bits_pCrdType)
    `CK(0, io_pCrd_0_query_bits_srcID)
    `CK(0, io_pCrd_1_query_valid)
    `CK(0, io_pCrd_1_query_bits_pCrdType)
    `CK(0, io_pCrd_1_query_bits_srcID)
    `CK(0, io_pCrd_2_query_valid)
    `CK(0, io_pCrd_2_query_bits_pCrdType)
    `CK(0, io_pCrd_2_query_bits_srcID)
    `CK(0, io_pCrd_3_query_valid)
    `CK(0, io_pCrd_3_query_bits_pCrdType)
    `CK(0, io_pCrd_3_query_bits_srcID)
    `CK(0, io_pCrd_4_query_valid)
    `CK(0, io_pCrd_4_query_bits_pCrdType)
    `CK(0, io_pCrd_4_query_bits_srcID)
    `CK(0, io_pCrd_5_query_valid)
    `CK(0, io_pCrd_5_query_bits_pCrdType)
    `CK(0, io_pCrd_5_query_bits_srcID)
    `CK(0, io_pCrd_6_query_valid)
    `CK(0, io_pCrd_6_query_bits_pCrdType)
    `CK(0, io_pCrd_6_query_bits_srcID)
    `CK(0, io_pCrd_7_query_valid)
    `CK(0, io_pCrd_7_query_bits_pCrdType)
    `CK(0, io_pCrd_7_query_bits_srcID)
    `CK(0, io_pCrd_8_query_valid)
    `CK(0, io_pCrd_8_query_bits_pCrdType)
    `CK(0, io_pCrd_8_query_bits_srcID)
    `CK(0, io_pCrd_9_query_valid)
    `CK(0, io_pCrd_9_query_bits_pCrdType)
    `CK(0, io_pCrd_9_query_bits_srcID)
    `CK(0, io_pCrd_10_query_valid)
    `CK(0, io_pCrd_10_query_bits_pCrdType)
    `CK(0, io_pCrd_10_query_bits_srcID)
    `CK(0, io_pCrd_11_query_valid)
    `CK(0, io_pCrd_11_query_bits_pCrdType)
    `CK(0, io_pCrd_11_query_bits_srcID)
    `CK(0, io_pCrd_12_query_valid)
    `CK(0, io_pCrd_12_query_bits_pCrdType)
    `CK(0, io_pCrd_12_query_bits_srcID)
    `CK(0, io_pCrd_13_query_valid)
    `CK(0, io_pCrd_13_query_bits_pCrdType)
    `CK(0, io_pCrd_13_query_bits_srcID)
    `CK(0, io_pCrd_14_query_valid)
    `CK(0, io_pCrd_14_query_bits_pCrdType)
    `CK(0, io_pCrd_14_query_bits_srcID)
    `CK(0, io_pCrd_15_query_valid)
    `CK(0, io_pCrd_15_query_bits_pCrdType)
    `CK(0, io_pCrd_15_query_bits_srcID)
    `CK(0, io_perf_0_value)
    `CK(0, io_perf_1_value)
    `CK(0, io_perf_3_value)
    `CK(0, io_perf_4_value)
    `CK(0, io_perf_5_value)
    `CK(0, io_perf_6_value)
    `CK(0, io_perf_7_value)
    `CK(0, io_perf_8_value)
    `CK(0, io_perf_9_value)
    `CK(0, io_perf_10_value)
    `CK(0, io_perf_11_value)
    `CK(0, io_perf_12_value)
    `CK(0, io_perf_13_value)
    `CK(0, io_perf_14_value)
    `CK(0, io_perf_15_value)
    `CK(0, io_perf_16_value)
    `CK(0, boreChildrenBd_bore_ack)
    `CK(0, boreChildrenBd_bore_outdata)
    `CK(1, io_in_a_ready)
    `CK(1, io_in_b_valid)
    `CK(1, io_in_b_bits_opcode)
    `CK(1, io_in_b_bits_param)
    `CK(1, io_in_b_bits_address)
    `CK(1, io_in_b_bits_data)
    `CK(1, io_in_c_ready)
    `CK(1, io_in_d_valid)
    `CK(1, io_in_d_bits_opcode)
    `CK(1, io_in_d_bits_param)
    `CK(1, io_in_d_bits_source)
    `CK(1, io_in_d_bits_sink)
    `CK(1, io_in_d_bits_denied)
    `CK(1, io_in_d_bits_echo_isKeyword)
    `CK(1, io_in_d_bits_data)
    `CK(1, io_in_d_bits_corrupt)
    `CK(1, io_l1Hint_valid)
    `CK(1, io_l1Hint_bits_sourceId)
    `CK(1, io_l1Hint_bits_isKeyword)
    `CK(1, io_prefetch_train_valid)
    `CK(1, io_prefetch_train_bits_tag)
    `CK(1, io_prefetch_train_bits_set)
    `CK(1, io_prefetch_train_bits_needT)
    `CK(1, io_prefetch_train_bits_source)
    `CK(1, io_prefetch_train_bits_vaddr)
    `CK(1, io_prefetch_train_bits_hit)
    `CK(1, io_prefetch_train_bits_prefetched)
    `CK(1, io_prefetch_train_bits_pfsource)
    `CK(1, io_prefetch_train_bits_reqsource)
    `CK(1, io_prefetch_req_ready)
    `CK(1, io_prefetch_resp_valid)
    `CK(1, io_prefetch_resp_bits_tag)
    `CK(1, io_prefetch_resp_bits_set)
    `CK(1, io_prefetch_resp_bits_vaddr)
    `CK(1, io_prefetch_resp_bits_pfSource)
    `CK(1, io_dirResult_valid)
    `CK(1, io_dirResult_bits_hit)
    `CK(1, io_dirResult_bits_meta_prefetch)
    `CK(1, io_dirResult_bits_meta_prefetchSrc)
    `CK(1, io_dirResult_bits_replacerInfo_channel)
    `CK(1, io_dirResult_bits_replacerInfo_reqSource)
    `CK(1, io_hitPfInMSHR_valid)
    `CK(1, io_hitPfInMSHR_bits)
    `CK(1, io_pfSent_valid)
    `CK(1, io_pfSent_bits)
    `CK(1, io_pfLateInMSHR_valid)
    `CK(1, io_pfLateInMSHR_bits)
    `CK(1, io_error_valid)
    `CK(1, io_error_bits_valid)
    `CK(1, io_error_bits_address)
    `CK(1, io_l2Miss)
    `CK(1, io_msStatus_0_valid)
    `CK(1, io_msStatus_0_bits_channel)
    `CK(1, io_msStatus_0_bits_set)
    `CK(1, io_msStatus_0_bits_reqTag)
    `CK(1, io_msStatus_0_bits_is_miss)
    `CK(1, io_msStatus_0_bits_is_prefetch)
    `CK(1, io_msStatus_1_valid)
    `CK(1, io_msStatus_1_bits_channel)
    `CK(1, io_msStatus_1_bits_set)
    `CK(1, io_msStatus_1_bits_reqTag)
    `CK(1, io_msStatus_1_bits_is_miss)
    `CK(1, io_msStatus_1_bits_is_prefetch)
    `CK(1, io_msStatus_2_valid)
    `CK(1, io_msStatus_2_bits_channel)
    `CK(1, io_msStatus_2_bits_set)
    `CK(1, io_msStatus_2_bits_reqTag)
    `CK(1, io_msStatus_2_bits_is_miss)
    `CK(1, io_msStatus_2_bits_is_prefetch)
    `CK(1, io_msStatus_3_valid)
    `CK(1, io_msStatus_3_bits_channel)
    `CK(1, io_msStatus_3_bits_set)
    `CK(1, io_msStatus_3_bits_reqTag)
    `CK(1, io_msStatus_3_bits_is_miss)
    `CK(1, io_msStatus_3_bits_is_prefetch)
    `CK(1, io_msStatus_4_valid)
    `CK(1, io_msStatus_4_bits_channel)
    `CK(1, io_msStatus_4_bits_set)
    `CK(1, io_msStatus_4_bits_reqTag)
    `CK(1, io_msStatus_4_bits_is_miss)
    `CK(1, io_msStatus_4_bits_is_prefetch)
    `CK(1, io_msStatus_5_valid)
    `CK(1, io_msStatus_5_bits_channel)
    `CK(1, io_msStatus_5_bits_set)
    `CK(1, io_msStatus_5_bits_reqTag)
    `CK(1, io_msStatus_5_bits_is_miss)
    `CK(1, io_msStatus_5_bits_is_prefetch)
    `CK(1, io_msStatus_6_valid)
    `CK(1, io_msStatus_6_bits_channel)
    `CK(1, io_msStatus_6_bits_set)
    `CK(1, io_msStatus_6_bits_reqTag)
    `CK(1, io_msStatus_6_bits_is_miss)
    `CK(1, io_msStatus_6_bits_is_prefetch)
    `CK(1, io_msStatus_7_valid)
    `CK(1, io_msStatus_7_bits_channel)
    `CK(1, io_msStatus_7_bits_set)
    `CK(1, io_msStatus_7_bits_reqTag)
    `CK(1, io_msStatus_7_bits_is_miss)
    `CK(1, io_msStatus_7_bits_is_prefetch)
    `CK(1, io_msStatus_8_valid)
    `CK(1, io_msStatus_8_bits_channel)
    `CK(1, io_msStatus_8_bits_set)
    `CK(1, io_msStatus_8_bits_reqTag)
    `CK(1, io_msStatus_8_bits_is_miss)
    `CK(1, io_msStatus_8_bits_is_prefetch)
    `CK(1, io_msStatus_9_valid)
    `CK(1, io_msStatus_9_bits_channel)
    `CK(1, io_msStatus_9_bits_set)
    `CK(1, io_msStatus_9_bits_reqTag)
    `CK(1, io_msStatus_9_bits_is_miss)
    `CK(1, io_msStatus_9_bits_is_prefetch)
    `CK(1, io_msStatus_10_valid)
    `CK(1, io_msStatus_10_bits_channel)
    `CK(1, io_msStatus_10_bits_set)
    `CK(1, io_msStatus_10_bits_reqTag)
    `CK(1, io_msStatus_10_bits_is_miss)
    `CK(1, io_msStatus_10_bits_is_prefetch)
    `CK(1, io_msStatus_11_valid)
    `CK(1, io_msStatus_11_bits_channel)
    `CK(1, io_msStatus_11_bits_set)
    `CK(1, io_msStatus_11_bits_reqTag)
    `CK(1, io_msStatus_11_bits_is_miss)
    `CK(1, io_msStatus_11_bits_is_prefetch)
    `CK(1, io_msStatus_12_valid)
    `CK(1, io_msStatus_12_bits_channel)
    `CK(1, io_msStatus_12_bits_set)
    `CK(1, io_msStatus_12_bits_reqTag)
    `CK(1, io_msStatus_12_bits_is_miss)
    `CK(1, io_msStatus_12_bits_is_prefetch)
    `CK(1, io_msStatus_13_valid)
    `CK(1, io_msStatus_13_bits_channel)
    `CK(1, io_msStatus_13_bits_set)
    `CK(1, io_msStatus_13_bits_reqTag)
    `CK(1, io_msStatus_13_bits_is_miss)
    `CK(1, io_msStatus_13_bits_is_prefetch)
    `CK(1, io_msStatus_14_valid)
    `CK(1, io_msStatus_14_bits_channel)
    `CK(1, io_msStatus_14_bits_set)
    `CK(1, io_msStatus_14_bits_reqTag)
    `CK(1, io_msStatus_14_bits_is_miss)
    `CK(1, io_msStatus_14_bits_is_prefetch)
    `CK(1, io_msStatus_15_valid)
    `CK(1, io_msStatus_15_bits_channel)
    `CK(1, io_msStatus_15_bits_set)
    `CK(1, io_msStatus_15_bits_reqTag)
    `CK(1, io_msStatus_15_bits_is_miss)
    `CK(1, io_msStatus_15_bits_is_prefetch)
    `CK(1, io_msAlloc_0_valid)
    `CK(1, io_msAlloc_0_bits_channel)
    `CK(1, io_msAlloc_0_bits_is_miss)
    `CK(1, io_msAlloc_0_bits_is_prefetch)
    `CK(1, io_msAlloc_1_valid)
    `CK(1, io_msAlloc_1_bits_channel)
    `CK(1, io_msAlloc_1_bits_is_miss)
    `CK(1, io_msAlloc_1_bits_is_prefetch)
    `CK(1, io_msAlloc_2_valid)
    `CK(1, io_msAlloc_2_bits_channel)
    `CK(1, io_msAlloc_2_bits_is_miss)
    `CK(1, io_msAlloc_2_bits_is_prefetch)
    `CK(1, io_msAlloc_3_valid)
    `CK(1, io_msAlloc_3_bits_channel)
    `CK(1, io_msAlloc_3_bits_is_miss)
    `CK(1, io_msAlloc_3_bits_is_prefetch)
    `CK(1, io_msAlloc_4_valid)
    `CK(1, io_msAlloc_4_bits_channel)
    `CK(1, io_msAlloc_4_bits_is_miss)
    `CK(1, io_msAlloc_4_bits_is_prefetch)
    `CK(1, io_msAlloc_5_valid)
    `CK(1, io_msAlloc_5_bits_channel)
    `CK(1, io_msAlloc_5_bits_is_miss)
    `CK(1, io_msAlloc_5_bits_is_prefetch)
    `CK(1, io_msAlloc_6_valid)
    `CK(1, io_msAlloc_6_bits_channel)
    `CK(1, io_msAlloc_6_bits_is_miss)
    `CK(1, io_msAlloc_6_bits_is_prefetch)
    `CK(1, io_msAlloc_7_valid)
    `CK(1, io_msAlloc_7_bits_channel)
    `CK(1, io_msAlloc_7_bits_is_miss)
    `CK(1, io_msAlloc_7_bits_is_prefetch)
    `CK(1, io_msAlloc_8_valid)
    `CK(1, io_msAlloc_8_bits_channel)
    `CK(1, io_msAlloc_8_bits_is_miss)
    `CK(1, io_msAlloc_8_bits_is_prefetch)
    `CK(1, io_msAlloc_9_valid)
    `CK(1, io_msAlloc_9_bits_channel)
    `CK(1, io_msAlloc_9_bits_is_miss)
    `CK(1, io_msAlloc_9_bits_is_prefetch)
    `CK(1, io_msAlloc_10_valid)
    `CK(1, io_msAlloc_10_bits_channel)
    `CK(1, io_msAlloc_10_bits_is_miss)
    `CK(1, io_msAlloc_10_bits_is_prefetch)
    `CK(1, io_msAlloc_11_valid)
    `CK(1, io_msAlloc_11_bits_channel)
    `CK(1, io_msAlloc_11_bits_is_miss)
    `CK(1, io_msAlloc_11_bits_is_prefetch)
    `CK(1, io_msAlloc_12_valid)
    `CK(1, io_msAlloc_12_bits_channel)
    `CK(1, io_msAlloc_12_bits_is_miss)
    `CK(1, io_msAlloc_12_bits_is_prefetch)
    `CK(1, io_msAlloc_13_valid)
    `CK(1, io_msAlloc_13_bits_channel)
    `CK(1, io_msAlloc_13_bits_is_miss)
    `CK(1, io_msAlloc_13_bits_is_prefetch)
    `CK(1, io_msAlloc_14_valid)
    `CK(1, io_msAlloc_14_bits_channel)
    `CK(1, io_msAlloc_14_bits_is_miss)
    `CK(1, io_msAlloc_14_bits_is_prefetch)
    `CK(1, io_msAlloc_15_valid)
    `CK(1, io_msAlloc_15_bits_channel)
    `CK(1, io_msAlloc_15_bits_is_miss)
    `CK(1, io_msAlloc_15_bits_is_prefetch)
    `CK(1, io_out_tx_req_valid)
    `CK(1, io_out_tx_req_bits_qos)
    `CK(1, io_out_tx_req_bits_txnID)
    `CK(1, io_out_tx_req_bits_returnNID)
    `CK(1, io_out_tx_req_bits_stashNIDValid)
    `CK(1, io_out_tx_req_bits_returnTxnID)
    `CK(1, io_out_tx_req_bits_opcode)
    `CK(1, io_out_tx_req_bits_addr)
    `CK(1, io_out_tx_req_bits_ns)
    `CK(1, io_out_tx_req_bits_likelyshared)
    `CK(1, io_out_tx_req_bits_allowRetry)
    `CK(1, io_out_tx_req_bits_order)
    `CK(1, io_out_tx_req_bits_pCrdType)
    `CK(1, io_out_tx_req_bits_memAttr_allocate)
    `CK(1, io_out_tx_req_bits_memAttr_cacheable)
    `CK(1, io_out_tx_req_bits_memAttr_device)
    `CK(1, io_out_tx_req_bits_memAttr_ewa)
    `CK(1, io_out_tx_req_bits_snpAttr)
    `CK(1, io_out_tx_req_bits_lpIDWithPadding)
    `CK(1, io_out_tx_req_bits_snoopMe)
    `CK(1, io_out_tx_req_bits_expCompAck)
    `CK(1, io_out_tx_req_bits_tagOp)
    `CK(1, io_out_tx_req_bits_traceTag)
    `CK(1, io_out_tx_req_bits_mpam_perfMonGroup)
    `CK(1, io_out_tx_req_bits_mpam_partID)
    `CK(1, io_out_tx_req_bits_mpam_mpamNS)
    `CK(1, io_out_tx_req_bits_rsvdc)
    `CK(1, io_out_tx_rsp_valid)
    `CK(1, io_out_tx_rsp_bits_qos)
    `CK(1, io_out_tx_rsp_bits_tgtID)
    `CK(1, io_out_tx_rsp_bits_txnID)
    `CK(1, io_out_tx_rsp_bits_opcode)
    `CK(1, io_out_tx_rsp_bits_respErr)
    `CK(1, io_out_tx_rsp_bits_resp)
    `CK(1, io_out_tx_rsp_bits_fwdState)
    `CK(1, io_out_tx_rsp_bits_cBusy)
    `CK(1, io_out_tx_rsp_bits_dbID)
    `CK(1, io_out_tx_rsp_bits_pCrdType)
    `CK(1, io_out_tx_rsp_bits_tagOp)
    `CK(1, io_out_tx_rsp_bits_traceTag)
    `CK(1, io_out_tx_dat_valid)
    `CK(1, io_out_tx_dat_bits_tgtID)
    `CK(1, io_out_tx_dat_bits_txnID)
    `CK(1, io_out_tx_dat_bits_homeNID)
    `CK(1, io_out_tx_dat_bits_opcode)
    `CK(1, io_out_tx_dat_bits_respErr)
    `CK(1, io_out_tx_dat_bits_resp)
    `CK(1, io_out_tx_dat_bits_dataSource)
    `CK(1, io_out_tx_dat_bits_dbID)
    `CK(1, io_out_tx_dat_bits_ccID)
    `CK(1, io_out_tx_dat_bits_dataID)
    `CK(1, io_out_tx_dat_bits_traceTag)
    `CK(1, io_out_tx_dat_bits_be)
    `CK(1, io_out_tx_dat_bits_data)
    `CK(1, io_out_tx_dat_bits_dataCheck)
    `CK(1, io_out_tx_dat_bits_poison)
    `CK(1, io_out_rx_snp_ready)
    `CK(1, io_pCrd_0_query_valid)
    `CK(1, io_pCrd_0_query_bits_pCrdType)
    `CK(1, io_pCrd_0_query_bits_srcID)
    `CK(1, io_pCrd_1_query_valid)
    `CK(1, io_pCrd_1_query_bits_pCrdType)
    `CK(1, io_pCrd_1_query_bits_srcID)
    `CK(1, io_pCrd_2_query_valid)
    `CK(1, io_pCrd_2_query_bits_pCrdType)
    `CK(1, io_pCrd_2_query_bits_srcID)
    `CK(1, io_pCrd_3_query_valid)
    `CK(1, io_pCrd_3_query_bits_pCrdType)
    `CK(1, io_pCrd_3_query_bits_srcID)
    `CK(1, io_pCrd_4_query_valid)
    `CK(1, io_pCrd_4_query_bits_pCrdType)
    `CK(1, io_pCrd_4_query_bits_srcID)
    `CK(1, io_pCrd_5_query_valid)
    `CK(1, io_pCrd_5_query_bits_pCrdType)
    `CK(1, io_pCrd_5_query_bits_srcID)
    `CK(1, io_pCrd_6_query_valid)
    `CK(1, io_pCrd_6_query_bits_pCrdType)
    `CK(1, io_pCrd_6_query_bits_srcID)
    `CK(1, io_pCrd_7_query_valid)
    `CK(1, io_pCrd_7_query_bits_pCrdType)
    `CK(1, io_pCrd_7_query_bits_srcID)
    `CK(1, io_pCrd_8_query_valid)
    `CK(1, io_pCrd_8_query_bits_pCrdType)
    `CK(1, io_pCrd_8_query_bits_srcID)
    `CK(1, io_pCrd_9_query_valid)
    `CK(1, io_pCrd_9_query_bits_pCrdType)
    `CK(1, io_pCrd_9_query_bits_srcID)
    `CK(1, io_pCrd_10_query_valid)
    `CK(1, io_pCrd_10_query_bits_pCrdType)
    `CK(1, io_pCrd_10_query_bits_srcID)
    `CK(1, io_pCrd_11_query_valid)
    `CK(1, io_pCrd_11_query_bits_pCrdType)
    `CK(1, io_pCrd_11_query_bits_srcID)
    `CK(1, io_pCrd_12_query_valid)
    `CK(1, io_pCrd_12_query_bits_pCrdType)
    `CK(1, io_pCrd_12_query_bits_srcID)
    `CK(1, io_pCrd_13_query_valid)
    `CK(1, io_pCrd_13_query_bits_pCrdType)
    `CK(1, io_pCrd_13_query_bits_srcID)
    `CK(1, io_pCrd_14_query_valid)
    `CK(1, io_pCrd_14_query_bits_pCrdType)
    `CK(1, io_pCrd_14_query_bits_srcID)
    `CK(1, io_pCrd_15_query_valid)
    `CK(1, io_pCrd_15_query_bits_pCrdType)
    `CK(1, io_pCrd_15_query_bits_srcID)
    `CK(1, io_perf_0_value)
    `CK(1, io_perf_1_value)
    `CK(1, io_perf_3_value)
    `CK(1, io_perf_4_value)
    `CK(1, io_perf_5_value)
    `CK(1, io_perf_6_value)
    `CK(1, io_perf_7_value)
    `CK(1, io_perf_8_value)
    `CK(1, io_perf_9_value)
    `CK(1, io_perf_10_value)
    `CK(1, io_perf_11_value)
    `CK(1, io_perf_12_value)
    `CK(1, io_perf_13_value)
    `CK(1, io_perf_14_value)
    `CK(1, io_perf_15_value)
    `CK(1, io_perf_16_value)
    `CK(1, boreChildrenBd_bore_ack)
    `CK(1, boreChildrenBd_bore_outdata)
    `CK(2, io_in_a_ready)
    `CK(2, io_in_b_valid)
    `CK(2, io_in_b_bits_opcode)
    `CK(2, io_in_b_bits_param)
    `CK(2, io_in_b_bits_address)
    `CK(2, io_in_b_bits_data)
    `CK(2, io_in_c_ready)
    `CK(2, io_in_d_valid)
    `CK(2, io_in_d_bits_opcode)
    `CK(2, io_in_d_bits_param)
    `CK(2, io_in_d_bits_source)
    `CK(2, io_in_d_bits_sink)
    `CK(2, io_in_d_bits_denied)
    `CK(2, io_in_d_bits_echo_isKeyword)
    `CK(2, io_in_d_bits_data)
    `CK(2, io_in_d_bits_corrupt)
    `CK(2, io_l1Hint_valid)
    `CK(2, io_l1Hint_bits_sourceId)
    `CK(2, io_l1Hint_bits_isKeyword)
    `CK(2, io_prefetch_train_valid)
    `CK(2, io_prefetch_train_bits_tag)
    `CK(2, io_prefetch_train_bits_set)
    `CK(2, io_prefetch_train_bits_needT)
    `CK(2, io_prefetch_train_bits_source)
    `CK(2, io_prefetch_train_bits_vaddr)
    `CK(2, io_prefetch_train_bits_hit)
    `CK(2, io_prefetch_train_bits_prefetched)
    `CK(2, io_prefetch_train_bits_pfsource)
    `CK(2, io_prefetch_train_bits_reqsource)
    `CK(2, io_prefetch_req_ready)
    `CK(2, io_prefetch_resp_valid)
    `CK(2, io_prefetch_resp_bits_tag)
    `CK(2, io_prefetch_resp_bits_set)
    `CK(2, io_prefetch_resp_bits_vaddr)
    `CK(2, io_prefetch_resp_bits_pfSource)
    `CK(2, io_dirResult_valid)
    `CK(2, io_dirResult_bits_hit)
    `CK(2, io_dirResult_bits_meta_prefetch)
    `CK(2, io_dirResult_bits_meta_prefetchSrc)
    `CK(2, io_dirResult_bits_replacerInfo_channel)
    `CK(2, io_dirResult_bits_replacerInfo_reqSource)
    `CK(2, io_hitPfInMSHR_valid)
    `CK(2, io_hitPfInMSHR_bits)
    `CK(2, io_pfSent_valid)
    `CK(2, io_pfSent_bits)
    `CK(2, io_pfLateInMSHR_valid)
    `CK(2, io_pfLateInMSHR_bits)
    `CK(2, io_error_valid)
    `CK(2, io_error_bits_valid)
    `CK(2, io_error_bits_address)
    `CK(2, io_l2Miss)
    `CK(2, io_msStatus_0_valid)
    `CK(2, io_msStatus_0_bits_channel)
    `CK(2, io_msStatus_0_bits_set)
    `CK(2, io_msStatus_0_bits_reqTag)
    `CK(2, io_msStatus_0_bits_is_miss)
    `CK(2, io_msStatus_0_bits_is_prefetch)
    `CK(2, io_msStatus_1_valid)
    `CK(2, io_msStatus_1_bits_channel)
    `CK(2, io_msStatus_1_bits_set)
    `CK(2, io_msStatus_1_bits_reqTag)
    `CK(2, io_msStatus_1_bits_is_miss)
    `CK(2, io_msStatus_1_bits_is_prefetch)
    `CK(2, io_msStatus_2_valid)
    `CK(2, io_msStatus_2_bits_channel)
    `CK(2, io_msStatus_2_bits_set)
    `CK(2, io_msStatus_2_bits_reqTag)
    `CK(2, io_msStatus_2_bits_is_miss)
    `CK(2, io_msStatus_2_bits_is_prefetch)
    `CK(2, io_msStatus_3_valid)
    `CK(2, io_msStatus_3_bits_channel)
    `CK(2, io_msStatus_3_bits_set)
    `CK(2, io_msStatus_3_bits_reqTag)
    `CK(2, io_msStatus_3_bits_is_miss)
    `CK(2, io_msStatus_3_bits_is_prefetch)
    `CK(2, io_msStatus_4_valid)
    `CK(2, io_msStatus_4_bits_channel)
    `CK(2, io_msStatus_4_bits_set)
    `CK(2, io_msStatus_4_bits_reqTag)
    `CK(2, io_msStatus_4_bits_is_miss)
    `CK(2, io_msStatus_4_bits_is_prefetch)
    `CK(2, io_msStatus_5_valid)
    `CK(2, io_msStatus_5_bits_channel)
    `CK(2, io_msStatus_5_bits_set)
    `CK(2, io_msStatus_5_bits_reqTag)
    `CK(2, io_msStatus_5_bits_is_miss)
    `CK(2, io_msStatus_5_bits_is_prefetch)
    `CK(2, io_msStatus_6_valid)
    `CK(2, io_msStatus_6_bits_channel)
    `CK(2, io_msStatus_6_bits_set)
    `CK(2, io_msStatus_6_bits_reqTag)
    `CK(2, io_msStatus_6_bits_is_miss)
    `CK(2, io_msStatus_6_bits_is_prefetch)
    `CK(2, io_msStatus_7_valid)
    `CK(2, io_msStatus_7_bits_channel)
    `CK(2, io_msStatus_7_bits_set)
    `CK(2, io_msStatus_7_bits_reqTag)
    `CK(2, io_msStatus_7_bits_is_miss)
    `CK(2, io_msStatus_7_bits_is_prefetch)
    `CK(2, io_msStatus_8_valid)
    `CK(2, io_msStatus_8_bits_channel)
    `CK(2, io_msStatus_8_bits_set)
    `CK(2, io_msStatus_8_bits_reqTag)
    `CK(2, io_msStatus_8_bits_is_miss)
    `CK(2, io_msStatus_8_bits_is_prefetch)
    `CK(2, io_msStatus_9_valid)
    `CK(2, io_msStatus_9_bits_channel)
    `CK(2, io_msStatus_9_bits_set)
    `CK(2, io_msStatus_9_bits_reqTag)
    `CK(2, io_msStatus_9_bits_is_miss)
    `CK(2, io_msStatus_9_bits_is_prefetch)
    `CK(2, io_msStatus_10_valid)
    `CK(2, io_msStatus_10_bits_channel)
    `CK(2, io_msStatus_10_bits_set)
    `CK(2, io_msStatus_10_bits_reqTag)
    `CK(2, io_msStatus_10_bits_is_miss)
    `CK(2, io_msStatus_10_bits_is_prefetch)
    `CK(2, io_msStatus_11_valid)
    `CK(2, io_msStatus_11_bits_channel)
    `CK(2, io_msStatus_11_bits_set)
    `CK(2, io_msStatus_11_bits_reqTag)
    `CK(2, io_msStatus_11_bits_is_miss)
    `CK(2, io_msStatus_11_bits_is_prefetch)
    `CK(2, io_msStatus_12_valid)
    `CK(2, io_msStatus_12_bits_channel)
    `CK(2, io_msStatus_12_bits_set)
    `CK(2, io_msStatus_12_bits_reqTag)
    `CK(2, io_msStatus_12_bits_is_miss)
    `CK(2, io_msStatus_12_bits_is_prefetch)
    `CK(2, io_msStatus_13_valid)
    `CK(2, io_msStatus_13_bits_channel)
    `CK(2, io_msStatus_13_bits_set)
    `CK(2, io_msStatus_13_bits_reqTag)
    `CK(2, io_msStatus_13_bits_is_miss)
    `CK(2, io_msStatus_13_bits_is_prefetch)
    `CK(2, io_msStatus_14_valid)
    `CK(2, io_msStatus_14_bits_channel)
    `CK(2, io_msStatus_14_bits_set)
    `CK(2, io_msStatus_14_bits_reqTag)
    `CK(2, io_msStatus_14_bits_is_miss)
    `CK(2, io_msStatus_14_bits_is_prefetch)
    `CK(2, io_msStatus_15_valid)
    `CK(2, io_msStatus_15_bits_channel)
    `CK(2, io_msStatus_15_bits_set)
    `CK(2, io_msStatus_15_bits_reqTag)
    `CK(2, io_msStatus_15_bits_is_miss)
    `CK(2, io_msStatus_15_bits_is_prefetch)
    `CK(2, io_msAlloc_0_valid)
    `CK(2, io_msAlloc_0_bits_channel)
    `CK(2, io_msAlloc_0_bits_is_miss)
    `CK(2, io_msAlloc_0_bits_is_prefetch)
    `CK(2, io_msAlloc_1_valid)
    `CK(2, io_msAlloc_1_bits_channel)
    `CK(2, io_msAlloc_1_bits_is_miss)
    `CK(2, io_msAlloc_1_bits_is_prefetch)
    `CK(2, io_msAlloc_2_valid)
    `CK(2, io_msAlloc_2_bits_channel)
    `CK(2, io_msAlloc_2_bits_is_miss)
    `CK(2, io_msAlloc_2_bits_is_prefetch)
    `CK(2, io_msAlloc_3_valid)
    `CK(2, io_msAlloc_3_bits_channel)
    `CK(2, io_msAlloc_3_bits_is_miss)
    `CK(2, io_msAlloc_3_bits_is_prefetch)
    `CK(2, io_msAlloc_4_valid)
    `CK(2, io_msAlloc_4_bits_channel)
    `CK(2, io_msAlloc_4_bits_is_miss)
    `CK(2, io_msAlloc_4_bits_is_prefetch)
    `CK(2, io_msAlloc_5_valid)
    `CK(2, io_msAlloc_5_bits_channel)
    `CK(2, io_msAlloc_5_bits_is_miss)
    `CK(2, io_msAlloc_5_bits_is_prefetch)
    `CK(2, io_msAlloc_6_valid)
    `CK(2, io_msAlloc_6_bits_channel)
    `CK(2, io_msAlloc_6_bits_is_miss)
    `CK(2, io_msAlloc_6_bits_is_prefetch)
    `CK(2, io_msAlloc_7_valid)
    `CK(2, io_msAlloc_7_bits_channel)
    `CK(2, io_msAlloc_7_bits_is_miss)
    `CK(2, io_msAlloc_7_bits_is_prefetch)
    `CK(2, io_msAlloc_8_valid)
    `CK(2, io_msAlloc_8_bits_channel)
    `CK(2, io_msAlloc_8_bits_is_miss)
    `CK(2, io_msAlloc_8_bits_is_prefetch)
    `CK(2, io_msAlloc_9_valid)
    `CK(2, io_msAlloc_9_bits_channel)
    `CK(2, io_msAlloc_9_bits_is_miss)
    `CK(2, io_msAlloc_9_bits_is_prefetch)
    `CK(2, io_msAlloc_10_valid)
    `CK(2, io_msAlloc_10_bits_channel)
    `CK(2, io_msAlloc_10_bits_is_miss)
    `CK(2, io_msAlloc_10_bits_is_prefetch)
    `CK(2, io_msAlloc_11_valid)
    `CK(2, io_msAlloc_11_bits_channel)
    `CK(2, io_msAlloc_11_bits_is_miss)
    `CK(2, io_msAlloc_11_bits_is_prefetch)
    `CK(2, io_msAlloc_12_valid)
    `CK(2, io_msAlloc_12_bits_channel)
    `CK(2, io_msAlloc_12_bits_is_miss)
    `CK(2, io_msAlloc_12_bits_is_prefetch)
    `CK(2, io_msAlloc_13_valid)
    `CK(2, io_msAlloc_13_bits_channel)
    `CK(2, io_msAlloc_13_bits_is_miss)
    `CK(2, io_msAlloc_13_bits_is_prefetch)
    `CK(2, io_msAlloc_14_valid)
    `CK(2, io_msAlloc_14_bits_channel)
    `CK(2, io_msAlloc_14_bits_is_miss)
    `CK(2, io_msAlloc_14_bits_is_prefetch)
    `CK(2, io_msAlloc_15_valid)
    `CK(2, io_msAlloc_15_bits_channel)
    `CK(2, io_msAlloc_15_bits_is_miss)
    `CK(2, io_msAlloc_15_bits_is_prefetch)
    `CK(2, io_out_tx_req_valid)
    `CK(2, io_out_tx_req_bits_qos)
    `CK(2, io_out_tx_req_bits_txnID)
    `CK(2, io_out_tx_req_bits_returnNID)
    `CK(2, io_out_tx_req_bits_stashNIDValid)
    `CK(2, io_out_tx_req_bits_returnTxnID)
    `CK(2, io_out_tx_req_bits_opcode)
    `CK(2, io_out_tx_req_bits_addr)
    `CK(2, io_out_tx_req_bits_ns)
    `CK(2, io_out_tx_req_bits_likelyshared)
    `CK(2, io_out_tx_req_bits_allowRetry)
    `CK(2, io_out_tx_req_bits_order)
    `CK(2, io_out_tx_req_bits_pCrdType)
    `CK(2, io_out_tx_req_bits_memAttr_allocate)
    `CK(2, io_out_tx_req_bits_memAttr_cacheable)
    `CK(2, io_out_tx_req_bits_memAttr_device)
    `CK(2, io_out_tx_req_bits_memAttr_ewa)
    `CK(2, io_out_tx_req_bits_snpAttr)
    `CK(2, io_out_tx_req_bits_lpIDWithPadding)
    `CK(2, io_out_tx_req_bits_snoopMe)
    `CK(2, io_out_tx_req_bits_expCompAck)
    `CK(2, io_out_tx_req_bits_tagOp)
    `CK(2, io_out_tx_req_bits_traceTag)
    `CK(2, io_out_tx_req_bits_mpam_perfMonGroup)
    `CK(2, io_out_tx_req_bits_mpam_partID)
    `CK(2, io_out_tx_req_bits_mpam_mpamNS)
    `CK(2, io_out_tx_req_bits_rsvdc)
    `CK(2, io_out_tx_rsp_valid)
    `CK(2, io_out_tx_rsp_bits_qos)
    `CK(2, io_out_tx_rsp_bits_tgtID)
    `CK(2, io_out_tx_rsp_bits_txnID)
    `CK(2, io_out_tx_rsp_bits_opcode)
    `CK(2, io_out_tx_rsp_bits_respErr)
    `CK(2, io_out_tx_rsp_bits_resp)
    `CK(2, io_out_tx_rsp_bits_fwdState)
    `CK(2, io_out_tx_rsp_bits_cBusy)
    `CK(2, io_out_tx_rsp_bits_dbID)
    `CK(2, io_out_tx_rsp_bits_pCrdType)
    `CK(2, io_out_tx_rsp_bits_tagOp)
    `CK(2, io_out_tx_rsp_bits_traceTag)
    `CK(2, io_out_tx_dat_valid)
    `CK(2, io_out_tx_dat_bits_tgtID)
    `CK(2, io_out_tx_dat_bits_txnID)
    `CK(2, io_out_tx_dat_bits_homeNID)
    `CK(2, io_out_tx_dat_bits_opcode)
    `CK(2, io_out_tx_dat_bits_respErr)
    `CK(2, io_out_tx_dat_bits_resp)
    `CK(2, io_out_tx_dat_bits_dataSource)
    `CK(2, io_out_tx_dat_bits_dbID)
    `CK(2, io_out_tx_dat_bits_ccID)
    `CK(2, io_out_tx_dat_bits_dataID)
    `CK(2, io_out_tx_dat_bits_traceTag)
    `CK(2, io_out_tx_dat_bits_be)
    `CK(2, io_out_tx_dat_bits_data)
    `CK(2, io_out_tx_dat_bits_dataCheck)
    `CK(2, io_out_tx_dat_bits_poison)
    `CK(2, io_out_rx_snp_ready)
    `CK(2, io_pCrd_0_query_valid)
    `CK(2, io_pCrd_0_query_bits_pCrdType)
    `CK(2, io_pCrd_0_query_bits_srcID)
    `CK(2, io_pCrd_1_query_valid)
    `CK(2, io_pCrd_1_query_bits_pCrdType)
    `CK(2, io_pCrd_1_query_bits_srcID)
    `CK(2, io_pCrd_2_query_valid)
    `CK(2, io_pCrd_2_query_bits_pCrdType)
    `CK(2, io_pCrd_2_query_bits_srcID)
    `CK(2, io_pCrd_3_query_valid)
    `CK(2, io_pCrd_3_query_bits_pCrdType)
    `CK(2, io_pCrd_3_query_bits_srcID)
    `CK(2, io_pCrd_4_query_valid)
    `CK(2, io_pCrd_4_query_bits_pCrdType)
    `CK(2, io_pCrd_4_query_bits_srcID)
    `CK(2, io_pCrd_5_query_valid)
    `CK(2, io_pCrd_5_query_bits_pCrdType)
    `CK(2, io_pCrd_5_query_bits_srcID)
    `CK(2, io_pCrd_6_query_valid)
    `CK(2, io_pCrd_6_query_bits_pCrdType)
    `CK(2, io_pCrd_6_query_bits_srcID)
    `CK(2, io_pCrd_7_query_valid)
    `CK(2, io_pCrd_7_query_bits_pCrdType)
    `CK(2, io_pCrd_7_query_bits_srcID)
    `CK(2, io_pCrd_8_query_valid)
    `CK(2, io_pCrd_8_query_bits_pCrdType)
    `CK(2, io_pCrd_8_query_bits_srcID)
    `CK(2, io_pCrd_9_query_valid)
    `CK(2, io_pCrd_9_query_bits_pCrdType)
    `CK(2, io_pCrd_9_query_bits_srcID)
    `CK(2, io_pCrd_10_query_valid)
    `CK(2, io_pCrd_10_query_bits_pCrdType)
    `CK(2, io_pCrd_10_query_bits_srcID)
    `CK(2, io_pCrd_11_query_valid)
    `CK(2, io_pCrd_11_query_bits_pCrdType)
    `CK(2, io_pCrd_11_query_bits_srcID)
    `CK(2, io_pCrd_12_query_valid)
    `CK(2, io_pCrd_12_query_bits_pCrdType)
    `CK(2, io_pCrd_12_query_bits_srcID)
    `CK(2, io_pCrd_13_query_valid)
    `CK(2, io_pCrd_13_query_bits_pCrdType)
    `CK(2, io_pCrd_13_query_bits_srcID)
    `CK(2, io_pCrd_14_query_valid)
    `CK(2, io_pCrd_14_query_bits_pCrdType)
    `CK(2, io_pCrd_14_query_bits_srcID)
    `CK(2, io_pCrd_15_query_valid)
    `CK(2, io_pCrd_15_query_bits_pCrdType)
    `CK(2, io_pCrd_15_query_bits_srcID)
    `CK(2, io_perf_0_value)
    `CK(2, io_perf_1_value)
    `CK(2, io_perf_3_value)
    `CK(2, io_perf_4_value)
    `CK(2, io_perf_5_value)
    `CK(2, io_perf_6_value)
    `CK(2, io_perf_7_value)
    `CK(2, io_perf_8_value)
    `CK(2, io_perf_9_value)
    `CK(2, io_perf_10_value)
    `CK(2, io_perf_11_value)
    `CK(2, io_perf_12_value)
    `CK(2, io_perf_13_value)
    `CK(2, io_perf_14_value)
    `CK(2, io_perf_15_value)
    `CK(2, io_perf_16_value)
    `CK(2, boreChildrenBd_bore_ack)
    `CK(2, boreChildrenBd_bore_outdata)
    `CK(3, io_in_a_ready)
    `CK(3, io_in_b_valid)
    `CK(3, io_in_b_bits_opcode)
    `CK(3, io_in_b_bits_param)
    `CK(3, io_in_b_bits_address)
    `CK(3, io_in_b_bits_data)
    `CK(3, io_in_c_ready)
    `CK(3, io_in_d_valid)
    `CK(3, io_in_d_bits_opcode)
    `CK(3, io_in_d_bits_param)
    `CK(3, io_in_d_bits_source)
    `CK(3, io_in_d_bits_sink)
    `CK(3, io_in_d_bits_denied)
    `CK(3, io_in_d_bits_echo_isKeyword)
    `CK(3, io_in_d_bits_data)
    `CK(3, io_in_d_bits_corrupt)
    `CK(3, io_l1Hint_valid)
    `CK(3, io_l1Hint_bits_sourceId)
    `CK(3, io_l1Hint_bits_isKeyword)
    `CK(3, io_prefetch_train_valid)
    `CK(3, io_prefetch_train_bits_tag)
    `CK(3, io_prefetch_train_bits_set)
    `CK(3, io_prefetch_train_bits_needT)
    `CK(3, io_prefetch_train_bits_source)
    `CK(3, io_prefetch_train_bits_vaddr)
    `CK(3, io_prefetch_train_bits_hit)
    `CK(3, io_prefetch_train_bits_prefetched)
    `CK(3, io_prefetch_train_bits_pfsource)
    `CK(3, io_prefetch_train_bits_reqsource)
    `CK(3, io_prefetch_req_ready)
    `CK(3, io_prefetch_resp_valid)
    `CK(3, io_prefetch_resp_bits_tag)
    `CK(3, io_prefetch_resp_bits_set)
    `CK(3, io_prefetch_resp_bits_vaddr)
    `CK(3, io_prefetch_resp_bits_pfSource)
    `CK(3, io_dirResult_valid)
    `CK(3, io_dirResult_bits_hit)
    `CK(3, io_dirResult_bits_meta_prefetch)
    `CK(3, io_dirResult_bits_meta_prefetchSrc)
    `CK(3, io_dirResult_bits_replacerInfo_channel)
    `CK(3, io_dirResult_bits_replacerInfo_reqSource)
    `CK(3, io_hitPfInMSHR_valid)
    `CK(3, io_hitPfInMSHR_bits)
    `CK(3, io_pfSent_valid)
    `CK(3, io_pfSent_bits)
    `CK(3, io_pfLateInMSHR_valid)
    `CK(3, io_pfLateInMSHR_bits)
    `CK(3, io_error_valid)
    `CK(3, io_error_bits_valid)
    `CK(3, io_error_bits_address)
    `CK(3, io_l2Miss)
    `CK(3, io_msStatus_0_valid)
    `CK(3, io_msStatus_0_bits_channel)
    `CK(3, io_msStatus_0_bits_set)
    `CK(3, io_msStatus_0_bits_reqTag)
    `CK(3, io_msStatus_0_bits_is_miss)
    `CK(3, io_msStatus_0_bits_is_prefetch)
    `CK(3, io_msStatus_1_valid)
    `CK(3, io_msStatus_1_bits_channel)
    `CK(3, io_msStatus_1_bits_set)
    `CK(3, io_msStatus_1_bits_reqTag)
    `CK(3, io_msStatus_1_bits_is_miss)
    `CK(3, io_msStatus_1_bits_is_prefetch)
    `CK(3, io_msStatus_2_valid)
    `CK(3, io_msStatus_2_bits_channel)
    `CK(3, io_msStatus_2_bits_set)
    `CK(3, io_msStatus_2_bits_reqTag)
    `CK(3, io_msStatus_2_bits_is_miss)
    `CK(3, io_msStatus_2_bits_is_prefetch)
    `CK(3, io_msStatus_3_valid)
    `CK(3, io_msStatus_3_bits_channel)
    `CK(3, io_msStatus_3_bits_set)
    `CK(3, io_msStatus_3_bits_reqTag)
    `CK(3, io_msStatus_3_bits_is_miss)
    `CK(3, io_msStatus_3_bits_is_prefetch)
    `CK(3, io_msStatus_4_valid)
    `CK(3, io_msStatus_4_bits_channel)
    `CK(3, io_msStatus_4_bits_set)
    `CK(3, io_msStatus_4_bits_reqTag)
    `CK(3, io_msStatus_4_bits_is_miss)
    `CK(3, io_msStatus_4_bits_is_prefetch)
    `CK(3, io_msStatus_5_valid)
    `CK(3, io_msStatus_5_bits_channel)
    `CK(3, io_msStatus_5_bits_set)
    `CK(3, io_msStatus_5_bits_reqTag)
    `CK(3, io_msStatus_5_bits_is_miss)
    `CK(3, io_msStatus_5_bits_is_prefetch)
    `CK(3, io_msStatus_6_valid)
    `CK(3, io_msStatus_6_bits_channel)
    `CK(3, io_msStatus_6_bits_set)
    `CK(3, io_msStatus_6_bits_reqTag)
    `CK(3, io_msStatus_6_bits_is_miss)
    `CK(3, io_msStatus_6_bits_is_prefetch)
    `CK(3, io_msStatus_7_valid)
    `CK(3, io_msStatus_7_bits_channel)
    `CK(3, io_msStatus_7_bits_set)
    `CK(3, io_msStatus_7_bits_reqTag)
    `CK(3, io_msStatus_7_bits_is_miss)
    `CK(3, io_msStatus_7_bits_is_prefetch)
    `CK(3, io_msStatus_8_valid)
    `CK(3, io_msStatus_8_bits_channel)
    `CK(3, io_msStatus_8_bits_set)
    `CK(3, io_msStatus_8_bits_reqTag)
    `CK(3, io_msStatus_8_bits_is_miss)
    `CK(3, io_msStatus_8_bits_is_prefetch)
    `CK(3, io_msStatus_9_valid)
    `CK(3, io_msStatus_9_bits_channel)
    `CK(3, io_msStatus_9_bits_set)
    `CK(3, io_msStatus_9_bits_reqTag)
    `CK(3, io_msStatus_9_bits_is_miss)
    `CK(3, io_msStatus_9_bits_is_prefetch)
    `CK(3, io_msStatus_10_valid)
    `CK(3, io_msStatus_10_bits_channel)
    `CK(3, io_msStatus_10_bits_set)
    `CK(3, io_msStatus_10_bits_reqTag)
    `CK(3, io_msStatus_10_bits_is_miss)
    `CK(3, io_msStatus_10_bits_is_prefetch)
    `CK(3, io_msStatus_11_valid)
    `CK(3, io_msStatus_11_bits_channel)
    `CK(3, io_msStatus_11_bits_set)
    `CK(3, io_msStatus_11_bits_reqTag)
    `CK(3, io_msStatus_11_bits_is_miss)
    `CK(3, io_msStatus_11_bits_is_prefetch)
    `CK(3, io_msStatus_12_valid)
    `CK(3, io_msStatus_12_bits_channel)
    `CK(3, io_msStatus_12_bits_set)
    `CK(3, io_msStatus_12_bits_reqTag)
    `CK(3, io_msStatus_12_bits_is_miss)
    `CK(3, io_msStatus_12_bits_is_prefetch)
    `CK(3, io_msStatus_13_valid)
    `CK(3, io_msStatus_13_bits_channel)
    `CK(3, io_msStatus_13_bits_set)
    `CK(3, io_msStatus_13_bits_reqTag)
    `CK(3, io_msStatus_13_bits_is_miss)
    `CK(3, io_msStatus_13_bits_is_prefetch)
    `CK(3, io_msStatus_14_valid)
    `CK(3, io_msStatus_14_bits_channel)
    `CK(3, io_msStatus_14_bits_set)
    `CK(3, io_msStatus_14_bits_reqTag)
    `CK(3, io_msStatus_14_bits_is_miss)
    `CK(3, io_msStatus_14_bits_is_prefetch)
    `CK(3, io_msStatus_15_valid)
    `CK(3, io_msStatus_15_bits_channel)
    `CK(3, io_msStatus_15_bits_set)
    `CK(3, io_msStatus_15_bits_reqTag)
    `CK(3, io_msStatus_15_bits_is_miss)
    `CK(3, io_msStatus_15_bits_is_prefetch)
    `CK(3, io_msAlloc_0_valid)
    `CK(3, io_msAlloc_0_bits_channel)
    `CK(3, io_msAlloc_0_bits_is_miss)
    `CK(3, io_msAlloc_0_bits_is_prefetch)
    `CK(3, io_msAlloc_1_valid)
    `CK(3, io_msAlloc_1_bits_channel)
    `CK(3, io_msAlloc_1_bits_is_miss)
    `CK(3, io_msAlloc_1_bits_is_prefetch)
    `CK(3, io_msAlloc_2_valid)
    `CK(3, io_msAlloc_2_bits_channel)
    `CK(3, io_msAlloc_2_bits_is_miss)
    `CK(3, io_msAlloc_2_bits_is_prefetch)
    `CK(3, io_msAlloc_3_valid)
    `CK(3, io_msAlloc_3_bits_channel)
    `CK(3, io_msAlloc_3_bits_is_miss)
    `CK(3, io_msAlloc_3_bits_is_prefetch)
    `CK(3, io_msAlloc_4_valid)
    `CK(3, io_msAlloc_4_bits_channel)
    `CK(3, io_msAlloc_4_bits_is_miss)
    `CK(3, io_msAlloc_4_bits_is_prefetch)
    `CK(3, io_msAlloc_5_valid)
    `CK(3, io_msAlloc_5_bits_channel)
    `CK(3, io_msAlloc_5_bits_is_miss)
    `CK(3, io_msAlloc_5_bits_is_prefetch)
    `CK(3, io_msAlloc_6_valid)
    `CK(3, io_msAlloc_6_bits_channel)
    `CK(3, io_msAlloc_6_bits_is_miss)
    `CK(3, io_msAlloc_6_bits_is_prefetch)
    `CK(3, io_msAlloc_7_valid)
    `CK(3, io_msAlloc_7_bits_channel)
    `CK(3, io_msAlloc_7_bits_is_miss)
    `CK(3, io_msAlloc_7_bits_is_prefetch)
    `CK(3, io_msAlloc_8_valid)
    `CK(3, io_msAlloc_8_bits_channel)
    `CK(3, io_msAlloc_8_bits_is_miss)
    `CK(3, io_msAlloc_8_bits_is_prefetch)
    `CK(3, io_msAlloc_9_valid)
    `CK(3, io_msAlloc_9_bits_channel)
    `CK(3, io_msAlloc_9_bits_is_miss)
    `CK(3, io_msAlloc_9_bits_is_prefetch)
    `CK(3, io_msAlloc_10_valid)
    `CK(3, io_msAlloc_10_bits_channel)
    `CK(3, io_msAlloc_10_bits_is_miss)
    `CK(3, io_msAlloc_10_bits_is_prefetch)
    `CK(3, io_msAlloc_11_valid)
    `CK(3, io_msAlloc_11_bits_channel)
    `CK(3, io_msAlloc_11_bits_is_miss)
    `CK(3, io_msAlloc_11_bits_is_prefetch)
    `CK(3, io_msAlloc_12_valid)
    `CK(3, io_msAlloc_12_bits_channel)
    `CK(3, io_msAlloc_12_bits_is_miss)
    `CK(3, io_msAlloc_12_bits_is_prefetch)
    `CK(3, io_msAlloc_13_valid)
    `CK(3, io_msAlloc_13_bits_channel)
    `CK(3, io_msAlloc_13_bits_is_miss)
    `CK(3, io_msAlloc_13_bits_is_prefetch)
    `CK(3, io_msAlloc_14_valid)
    `CK(3, io_msAlloc_14_bits_channel)
    `CK(3, io_msAlloc_14_bits_is_miss)
    `CK(3, io_msAlloc_14_bits_is_prefetch)
    `CK(3, io_msAlloc_15_valid)
    `CK(3, io_msAlloc_15_bits_channel)
    `CK(3, io_msAlloc_15_bits_is_miss)
    `CK(3, io_msAlloc_15_bits_is_prefetch)
    `CK(3, io_out_tx_req_valid)
    `CK(3, io_out_tx_req_bits_qos)
    `CK(3, io_out_tx_req_bits_txnID)
    `CK(3, io_out_tx_req_bits_returnNID)
    `CK(3, io_out_tx_req_bits_stashNIDValid)
    `CK(3, io_out_tx_req_bits_returnTxnID)
    `CK(3, io_out_tx_req_bits_opcode)
    `CK(3, io_out_tx_req_bits_addr)
    `CK(3, io_out_tx_req_bits_ns)
    `CK(3, io_out_tx_req_bits_likelyshared)
    `CK(3, io_out_tx_req_bits_allowRetry)
    `CK(3, io_out_tx_req_bits_order)
    `CK(3, io_out_tx_req_bits_pCrdType)
    `CK(3, io_out_tx_req_bits_memAttr_allocate)
    `CK(3, io_out_tx_req_bits_memAttr_cacheable)
    `CK(3, io_out_tx_req_bits_memAttr_device)
    `CK(3, io_out_tx_req_bits_memAttr_ewa)
    `CK(3, io_out_tx_req_bits_snpAttr)
    `CK(3, io_out_tx_req_bits_lpIDWithPadding)
    `CK(3, io_out_tx_req_bits_snoopMe)
    `CK(3, io_out_tx_req_bits_expCompAck)
    `CK(3, io_out_tx_req_bits_tagOp)
    `CK(3, io_out_tx_req_bits_traceTag)
    `CK(3, io_out_tx_req_bits_mpam_perfMonGroup)
    `CK(3, io_out_tx_req_bits_mpam_partID)
    `CK(3, io_out_tx_req_bits_mpam_mpamNS)
    `CK(3, io_out_tx_req_bits_rsvdc)
    `CK(3, io_out_tx_rsp_valid)
    `CK(3, io_out_tx_rsp_bits_qos)
    `CK(3, io_out_tx_rsp_bits_tgtID)
    `CK(3, io_out_tx_rsp_bits_txnID)
    `CK(3, io_out_tx_rsp_bits_opcode)
    `CK(3, io_out_tx_rsp_bits_respErr)
    `CK(3, io_out_tx_rsp_bits_resp)
    `CK(3, io_out_tx_rsp_bits_fwdState)
    `CK(3, io_out_tx_rsp_bits_cBusy)
    `CK(3, io_out_tx_rsp_bits_dbID)
    `CK(3, io_out_tx_rsp_bits_pCrdType)
    `CK(3, io_out_tx_rsp_bits_tagOp)
    `CK(3, io_out_tx_rsp_bits_traceTag)
    `CK(3, io_out_tx_dat_valid)
    `CK(3, io_out_tx_dat_bits_tgtID)
    `CK(3, io_out_tx_dat_bits_txnID)
    `CK(3, io_out_tx_dat_bits_homeNID)
    `CK(3, io_out_tx_dat_bits_opcode)
    `CK(3, io_out_tx_dat_bits_respErr)
    `CK(3, io_out_tx_dat_bits_resp)
    `CK(3, io_out_tx_dat_bits_dataSource)
    `CK(3, io_out_tx_dat_bits_dbID)
    `CK(3, io_out_tx_dat_bits_ccID)
    `CK(3, io_out_tx_dat_bits_dataID)
    `CK(3, io_out_tx_dat_bits_traceTag)
    `CK(3, io_out_tx_dat_bits_be)
    `CK(3, io_out_tx_dat_bits_data)
    `CK(3, io_out_tx_dat_bits_dataCheck)
    `CK(3, io_out_tx_dat_bits_poison)
    `CK(3, io_out_rx_snp_ready)
    `CK(3, io_pCrd_0_query_valid)
    `CK(3, io_pCrd_0_query_bits_pCrdType)
    `CK(3, io_pCrd_0_query_bits_srcID)
    `CK(3, io_pCrd_1_query_valid)
    `CK(3, io_pCrd_1_query_bits_pCrdType)
    `CK(3, io_pCrd_1_query_bits_srcID)
    `CK(3, io_pCrd_2_query_valid)
    `CK(3, io_pCrd_2_query_bits_pCrdType)
    `CK(3, io_pCrd_2_query_bits_srcID)
    `CK(3, io_pCrd_3_query_valid)
    `CK(3, io_pCrd_3_query_bits_pCrdType)
    `CK(3, io_pCrd_3_query_bits_srcID)
    `CK(3, io_pCrd_4_query_valid)
    `CK(3, io_pCrd_4_query_bits_pCrdType)
    `CK(3, io_pCrd_4_query_bits_srcID)
    `CK(3, io_pCrd_5_query_valid)
    `CK(3, io_pCrd_5_query_bits_pCrdType)
    `CK(3, io_pCrd_5_query_bits_srcID)
    `CK(3, io_pCrd_6_query_valid)
    `CK(3, io_pCrd_6_query_bits_pCrdType)
    `CK(3, io_pCrd_6_query_bits_srcID)
    `CK(3, io_pCrd_7_query_valid)
    `CK(3, io_pCrd_7_query_bits_pCrdType)
    `CK(3, io_pCrd_7_query_bits_srcID)
    `CK(3, io_pCrd_8_query_valid)
    `CK(3, io_pCrd_8_query_bits_pCrdType)
    `CK(3, io_pCrd_8_query_bits_srcID)
    `CK(3, io_pCrd_9_query_valid)
    `CK(3, io_pCrd_9_query_bits_pCrdType)
    `CK(3, io_pCrd_9_query_bits_srcID)
    `CK(3, io_pCrd_10_query_valid)
    `CK(3, io_pCrd_10_query_bits_pCrdType)
    `CK(3, io_pCrd_10_query_bits_srcID)
    `CK(3, io_pCrd_11_query_valid)
    `CK(3, io_pCrd_11_query_bits_pCrdType)
    `CK(3, io_pCrd_11_query_bits_srcID)
    `CK(3, io_pCrd_12_query_valid)
    `CK(3, io_pCrd_12_query_bits_pCrdType)
    `CK(3, io_pCrd_12_query_bits_srcID)
    `CK(3, io_pCrd_13_query_valid)
    `CK(3, io_pCrd_13_query_bits_pCrdType)
    `CK(3, io_pCrd_13_query_bits_srcID)
    `CK(3, io_pCrd_14_query_valid)
    `CK(3, io_pCrd_14_query_bits_pCrdType)
    `CK(3, io_pCrd_14_query_bits_srcID)
    `CK(3, io_pCrd_15_query_valid)
    `CK(3, io_pCrd_15_query_bits_pCrdType)
    `CK(3, io_pCrd_15_query_bits_srcID)
    `CK(3, io_perf_0_value)
    `CK(3, io_perf_1_value)
    `CK(3, io_perf_3_value)
    `CK(3, io_perf_4_value)
    `CK(3, io_perf_5_value)
    `CK(3, io_perf_6_value)
    `CK(3, io_perf_7_value)
    `CK(3, io_perf_8_value)
    `CK(3, io_perf_9_value)
    `CK(3, io_perf_10_value)
    `CK(3, io_perf_11_value)
    `CK(3, io_perf_12_value)
    `CK(3, io_perf_13_value)
    `CK(3, io_perf_14_value)
    `CK(3, io_perf_15_value)
    `CK(3, io_perf_16_value)
    `CK(3, boreChildrenBd_bore_ack)
    `CK(3, boreChildrenBd_bore_outdata)
  endtask

  longint cov [23];
  localparam string COV_NAME [23] = '{"A 收下", "C 收下", "D 发出", "B(Probe) 发出", "E 收下", "TXREQ 发出", "TXRSP 发出", "TXDAT 发出", "RXSNP 收下", "MSHR 分配", "目录命中", "目录缺失", "MSHR 全占", "releaseBuf 写(MainPipe)", "refillBuf 写(RXDAT)", "数据阵列写", "L1 hint", "预取 train", "预取 resp", "预取 sent", "L2 miss", "dirResult", "MBIST ack"};
  task automatic sample();
    if (u_g0.io_in_a_valid & u_g0.io_in_a_ready) cov[0]++;
    if (u_g0.io_in_c_valid & u_g0.io_in_c_ready) cov[1]++;
    if (u_g0.io_in_d_valid & u_g0.io_in_d_ready) cov[2]++;
    if (u_g0.io_in_b_valid & u_g0.io_in_b_ready) cov[3]++;
    if (u_g0.io_in_e_valid) cov[4]++;
    if (u_g0.io_out_tx_req_valid & u_g0.io_out_tx_req_ready) cov[5]++;
    if (u_g0.io_out_tx_rsp_valid & u_g0.io_out_tx_rsp_ready) cov[6]++;
    if (u_g0.io_out_tx_dat_valid & u_g0.io_out_tx_dat_ready) cov[7]++;
    if (u_g0.io_out_rx_snp_valid & u_g0.io_out_rx_snp_ready) cov[8]++;
    if (u_g0._mainPipe_io_toMSHRCtl_mshr_alloc_s3_valid) cov[9]++;
    if (u_g0._directory_io_resp_valid & u_g0._directory_io_resp_bits_hit) cov[10]++;
    if (u_g0._directory_io_resp_valid & ~u_g0._directory_io_resp_bits_hit) cov[11]++;
    if (u_g0.io_msStatus_15_valid & u_g0.io_msStatus_0_valid) cov[12]++;
    if (u_g0._mainPipe_io_releaseBufWrite_valid) cov[13]++;
    if (u_g0._rxdat_io_refillBufWrite_valid) cov[14]++;
    if (u_g0._mainPipe_io_toDS_en_s3 & u_g0._mainPipe_io_toDS_req_s3_bits_wen) cov[15]++;
    if (u_g0.io_l1Hint_valid) cov[16]++;
    if (u_g0.io_prefetch_train_valid) cov[17]++;
    if (u_g0.io_prefetch_resp_valid) cov[18]++;
    if (u_g0.io_pfSent_valid) cov[19]++;
    if (u_g0.io_l2Miss) cov[20]++;
    if (u_g0.io_dirResult_valid) cov[21]++;
    if (u_g0.boreChildrenBd_bore_ack) cov[22]++;
  endtask

  task automatic sync_init();
    force u_i0.u_core.mshrCtl.u_core.mshrs[0].entry.u_core.tgtid_rcompack = u_g0.mshrCtl.mshrs_0.tgtid_rcompack;
    force u_i0.u_core.mshrCtl.u_core.mshrs[0].entry.u_core.txnid_rcompack = u_g0.mshrCtl.mshrs_0.txnid_rcompack;
    force u_i0.u_core.mshrCtl.u_core.mshrs[0].entry.u_core.tgtid_wcompack = u_g0.mshrCtl.mshrs_0.tgtid_wcompack;
    force u_i0.u_core.mshrCtl.u_core.mshrs[0].entry.u_core.txnid_wcompack = u_g0.mshrCtl.mshrs_0.txnid_wcompack;
    force u_i0.u_core.mshrCtl.u_core.mshrs[0].entry.u_core.srcid_retryack = u_g0.mshrCtl.mshrs_0.srcid_retryack;
    force u_i0.u_core.mshrCtl.u_core.mshrs[0].entry.u_core.acquire_ts = u_g0.mshrCtl.mshrs_0.acquire_ts;
    force u_i0.u_core.mshrCtl.u_core.mshrs[0].entry.u_core.release_ts = u_g0.mshrCtl.mshrs_0.release_ts;
    force u_i0.u_core.mshrCtl.u_core.mshrs[0].entry.u_core.acquire_period_valid_REG = u_g0.mshrCtl.mshrs_0.acquire_period_valid_REG;
    force u_i0.u_core.mshrCtl.u_core.mshrs[0].entry.u_core.release_period_valid_REG = u_g0.mshrCtl.mshrs_0.release_period_valid_REG;
    force u_i0.u_core.mshrCtl.u_core.mshrs[0].entry.u_core.REG = u_g0.mshrCtl.mshrs_0.REG;
    force u_i0.u_core.mshrCtl.u_core.mshrs[0].entry.u_core.REG_1 = u_g0.mshrCtl.mshrs_0.REG_1;
    force u_i0.u_core.mshrCtl.u_core.mshrs[0].entry.u_core.REG_2 = u_g0.mshrCtl.mshrs_0.REG_2;
    force u_i0.u_core.mshrCtl.u_core.mshrs[0].entry.u_core.REG_3 = u_g0.mshrCtl.mshrs_0.REG_3;
    force u_i0.u_core.mshrCtl.u_core.mshrs[1].entry.u_core.tgtid_rcompack = u_g0.mshrCtl.mshrs_1.tgtid_rcompack;
    force u_i0.u_core.mshrCtl.u_core.mshrs[1].entry.u_core.txnid_rcompack = u_g0.mshrCtl.mshrs_1.txnid_rcompack;
    force u_i0.u_core.mshrCtl.u_core.mshrs[1].entry.u_core.tgtid_wcompack = u_g0.mshrCtl.mshrs_1.tgtid_wcompack;
    force u_i0.u_core.mshrCtl.u_core.mshrs[1].entry.u_core.txnid_wcompack = u_g0.mshrCtl.mshrs_1.txnid_wcompack;
    force u_i0.u_core.mshrCtl.u_core.mshrs[1].entry.u_core.srcid_retryack = u_g0.mshrCtl.mshrs_1.srcid_retryack;
    force u_i0.u_core.mshrCtl.u_core.mshrs[1].entry.u_core.acquire_ts = u_g0.mshrCtl.mshrs_1.acquire_ts;
    force u_i0.u_core.mshrCtl.u_core.mshrs[1].entry.u_core.release_ts = u_g0.mshrCtl.mshrs_1.release_ts;
    force u_i0.u_core.mshrCtl.u_core.mshrs[1].entry.u_core.acquire_period_valid_REG = u_g0.mshrCtl.mshrs_1.acquire_period_valid_REG;
    force u_i0.u_core.mshrCtl.u_core.mshrs[1].entry.u_core.release_period_valid_REG = u_g0.mshrCtl.mshrs_1.release_period_valid_REG;
    force u_i0.u_core.mshrCtl.u_core.mshrs[1].entry.u_core.REG = u_g0.mshrCtl.mshrs_1.REG;
    force u_i0.u_core.mshrCtl.u_core.mshrs[1].entry.u_core.REG_1 = u_g0.mshrCtl.mshrs_1.REG_1;
    force u_i0.u_core.mshrCtl.u_core.mshrs[1].entry.u_core.REG_2 = u_g0.mshrCtl.mshrs_1.REG_2;
    force u_i0.u_core.mshrCtl.u_core.mshrs[1].entry.u_core.REG_3 = u_g0.mshrCtl.mshrs_1.REG_3;
    force u_i0.u_core.mshrCtl.u_core.mshrs[2].entry.u_core.tgtid_rcompack = u_g0.mshrCtl.mshrs_2.tgtid_rcompack;
    force u_i0.u_core.mshrCtl.u_core.mshrs[2].entry.u_core.txnid_rcompack = u_g0.mshrCtl.mshrs_2.txnid_rcompack;
    force u_i0.u_core.mshrCtl.u_core.mshrs[2].entry.u_core.tgtid_wcompack = u_g0.mshrCtl.mshrs_2.tgtid_wcompack;
    force u_i0.u_core.mshrCtl.u_core.mshrs[2].entry.u_core.txnid_wcompack = u_g0.mshrCtl.mshrs_2.txnid_wcompack;
    force u_i0.u_core.mshrCtl.u_core.mshrs[2].entry.u_core.srcid_retryack = u_g0.mshrCtl.mshrs_2.srcid_retryack;
    force u_i0.u_core.mshrCtl.u_core.mshrs[2].entry.u_core.acquire_ts = u_g0.mshrCtl.mshrs_2.acquire_ts;
    force u_i0.u_core.mshrCtl.u_core.mshrs[2].entry.u_core.release_ts = u_g0.mshrCtl.mshrs_2.release_ts;
    force u_i0.u_core.mshrCtl.u_core.mshrs[2].entry.u_core.acquire_period_valid_REG = u_g0.mshrCtl.mshrs_2.acquire_period_valid_REG;
    force u_i0.u_core.mshrCtl.u_core.mshrs[2].entry.u_core.release_period_valid_REG = u_g0.mshrCtl.mshrs_2.release_period_valid_REG;
    force u_i0.u_core.mshrCtl.u_core.mshrs[2].entry.u_core.REG = u_g0.mshrCtl.mshrs_2.REG;
    force u_i0.u_core.mshrCtl.u_core.mshrs[2].entry.u_core.REG_1 = u_g0.mshrCtl.mshrs_2.REG_1;
    force u_i0.u_core.mshrCtl.u_core.mshrs[2].entry.u_core.REG_2 = u_g0.mshrCtl.mshrs_2.REG_2;
    force u_i0.u_core.mshrCtl.u_core.mshrs[2].entry.u_core.REG_3 = u_g0.mshrCtl.mshrs_2.REG_3;
    force u_i0.u_core.mshrCtl.u_core.mshrs[3].entry.u_core.tgtid_rcompack = u_g0.mshrCtl.mshrs_3.tgtid_rcompack;
    force u_i0.u_core.mshrCtl.u_core.mshrs[3].entry.u_core.txnid_rcompack = u_g0.mshrCtl.mshrs_3.txnid_rcompack;
    force u_i0.u_core.mshrCtl.u_core.mshrs[3].entry.u_core.tgtid_wcompack = u_g0.mshrCtl.mshrs_3.tgtid_wcompack;
    force u_i0.u_core.mshrCtl.u_core.mshrs[3].entry.u_core.txnid_wcompack = u_g0.mshrCtl.mshrs_3.txnid_wcompack;
    force u_i0.u_core.mshrCtl.u_core.mshrs[3].entry.u_core.srcid_retryack = u_g0.mshrCtl.mshrs_3.srcid_retryack;
    force u_i0.u_core.mshrCtl.u_core.mshrs[3].entry.u_core.acquire_ts = u_g0.mshrCtl.mshrs_3.acquire_ts;
    force u_i0.u_core.mshrCtl.u_core.mshrs[3].entry.u_core.release_ts = u_g0.mshrCtl.mshrs_3.release_ts;
    force u_i0.u_core.mshrCtl.u_core.mshrs[3].entry.u_core.acquire_period_valid_REG = u_g0.mshrCtl.mshrs_3.acquire_period_valid_REG;
    force u_i0.u_core.mshrCtl.u_core.mshrs[3].entry.u_core.release_period_valid_REG = u_g0.mshrCtl.mshrs_3.release_period_valid_REG;
    force u_i0.u_core.mshrCtl.u_core.mshrs[3].entry.u_core.REG = u_g0.mshrCtl.mshrs_3.REG;
    force u_i0.u_core.mshrCtl.u_core.mshrs[3].entry.u_core.REG_1 = u_g0.mshrCtl.mshrs_3.REG_1;
    force u_i0.u_core.mshrCtl.u_core.mshrs[3].entry.u_core.REG_2 = u_g0.mshrCtl.mshrs_3.REG_2;
    force u_i0.u_core.mshrCtl.u_core.mshrs[3].entry.u_core.REG_3 = u_g0.mshrCtl.mshrs_3.REG_3;
    force u_i0.u_core.mshrCtl.u_core.mshrs[4].entry.u_core.tgtid_rcompack = u_g0.mshrCtl.mshrs_4.tgtid_rcompack;
    force u_i0.u_core.mshrCtl.u_core.mshrs[4].entry.u_core.txnid_rcompack = u_g0.mshrCtl.mshrs_4.txnid_rcompack;
    force u_i0.u_core.mshrCtl.u_core.mshrs[4].entry.u_core.tgtid_wcompack = u_g0.mshrCtl.mshrs_4.tgtid_wcompack;
    force u_i0.u_core.mshrCtl.u_core.mshrs[4].entry.u_core.txnid_wcompack = u_g0.mshrCtl.mshrs_4.txnid_wcompack;
    force u_i0.u_core.mshrCtl.u_core.mshrs[4].entry.u_core.srcid_retryack = u_g0.mshrCtl.mshrs_4.srcid_retryack;
    force u_i0.u_core.mshrCtl.u_core.mshrs[4].entry.u_core.acquire_ts = u_g0.mshrCtl.mshrs_4.acquire_ts;
    force u_i0.u_core.mshrCtl.u_core.mshrs[4].entry.u_core.release_ts = u_g0.mshrCtl.mshrs_4.release_ts;
    force u_i0.u_core.mshrCtl.u_core.mshrs[4].entry.u_core.acquire_period_valid_REG = u_g0.mshrCtl.mshrs_4.acquire_period_valid_REG;
    force u_i0.u_core.mshrCtl.u_core.mshrs[4].entry.u_core.release_period_valid_REG = u_g0.mshrCtl.mshrs_4.release_period_valid_REG;
    force u_i0.u_core.mshrCtl.u_core.mshrs[4].entry.u_core.REG = u_g0.mshrCtl.mshrs_4.REG;
    force u_i0.u_core.mshrCtl.u_core.mshrs[4].entry.u_core.REG_1 = u_g0.mshrCtl.mshrs_4.REG_1;
    force u_i0.u_core.mshrCtl.u_core.mshrs[4].entry.u_core.REG_2 = u_g0.mshrCtl.mshrs_4.REG_2;
    force u_i0.u_core.mshrCtl.u_core.mshrs[4].entry.u_core.REG_3 = u_g0.mshrCtl.mshrs_4.REG_3;
    force u_i0.u_core.mshrCtl.u_core.mshrs[5].entry.u_core.tgtid_rcompack = u_g0.mshrCtl.mshrs_5.tgtid_rcompack;
    force u_i0.u_core.mshrCtl.u_core.mshrs[5].entry.u_core.txnid_rcompack = u_g0.mshrCtl.mshrs_5.txnid_rcompack;
    force u_i0.u_core.mshrCtl.u_core.mshrs[5].entry.u_core.tgtid_wcompack = u_g0.mshrCtl.mshrs_5.tgtid_wcompack;
    force u_i0.u_core.mshrCtl.u_core.mshrs[5].entry.u_core.txnid_wcompack = u_g0.mshrCtl.mshrs_5.txnid_wcompack;
    force u_i0.u_core.mshrCtl.u_core.mshrs[5].entry.u_core.srcid_retryack = u_g0.mshrCtl.mshrs_5.srcid_retryack;
    force u_i0.u_core.mshrCtl.u_core.mshrs[5].entry.u_core.acquire_ts = u_g0.mshrCtl.mshrs_5.acquire_ts;
    force u_i0.u_core.mshrCtl.u_core.mshrs[5].entry.u_core.release_ts = u_g0.mshrCtl.mshrs_5.release_ts;
    force u_i0.u_core.mshrCtl.u_core.mshrs[5].entry.u_core.acquire_period_valid_REG = u_g0.mshrCtl.mshrs_5.acquire_period_valid_REG;
    force u_i0.u_core.mshrCtl.u_core.mshrs[5].entry.u_core.release_period_valid_REG = u_g0.mshrCtl.mshrs_5.release_period_valid_REG;
    force u_i0.u_core.mshrCtl.u_core.mshrs[5].entry.u_core.REG = u_g0.mshrCtl.mshrs_5.REG;
    force u_i0.u_core.mshrCtl.u_core.mshrs[5].entry.u_core.REG_1 = u_g0.mshrCtl.mshrs_5.REG_1;
    force u_i0.u_core.mshrCtl.u_core.mshrs[5].entry.u_core.REG_2 = u_g0.mshrCtl.mshrs_5.REG_2;
    force u_i0.u_core.mshrCtl.u_core.mshrs[5].entry.u_core.REG_3 = u_g0.mshrCtl.mshrs_5.REG_3;
    force u_i0.u_core.mshrCtl.u_core.mshrs[6].entry.u_core.tgtid_rcompack = u_g0.mshrCtl.mshrs_6.tgtid_rcompack;
    force u_i0.u_core.mshrCtl.u_core.mshrs[6].entry.u_core.txnid_rcompack = u_g0.mshrCtl.mshrs_6.txnid_rcompack;
    force u_i0.u_core.mshrCtl.u_core.mshrs[6].entry.u_core.tgtid_wcompack = u_g0.mshrCtl.mshrs_6.tgtid_wcompack;
    force u_i0.u_core.mshrCtl.u_core.mshrs[6].entry.u_core.txnid_wcompack = u_g0.mshrCtl.mshrs_6.txnid_wcompack;
    force u_i0.u_core.mshrCtl.u_core.mshrs[6].entry.u_core.srcid_retryack = u_g0.mshrCtl.mshrs_6.srcid_retryack;
    force u_i0.u_core.mshrCtl.u_core.mshrs[6].entry.u_core.acquire_ts = u_g0.mshrCtl.mshrs_6.acquire_ts;
    force u_i0.u_core.mshrCtl.u_core.mshrs[6].entry.u_core.release_ts = u_g0.mshrCtl.mshrs_6.release_ts;
    force u_i0.u_core.mshrCtl.u_core.mshrs[6].entry.u_core.acquire_period_valid_REG = u_g0.mshrCtl.mshrs_6.acquire_period_valid_REG;
    force u_i0.u_core.mshrCtl.u_core.mshrs[6].entry.u_core.release_period_valid_REG = u_g0.mshrCtl.mshrs_6.release_period_valid_REG;
    force u_i0.u_core.mshrCtl.u_core.mshrs[6].entry.u_core.REG = u_g0.mshrCtl.mshrs_6.REG;
    force u_i0.u_core.mshrCtl.u_core.mshrs[6].entry.u_core.REG_1 = u_g0.mshrCtl.mshrs_6.REG_1;
    force u_i0.u_core.mshrCtl.u_core.mshrs[6].entry.u_core.REG_2 = u_g0.mshrCtl.mshrs_6.REG_2;
    force u_i0.u_core.mshrCtl.u_core.mshrs[6].entry.u_core.REG_3 = u_g0.mshrCtl.mshrs_6.REG_3;
    force u_i0.u_core.mshrCtl.u_core.mshrs[7].entry.u_core.tgtid_rcompack = u_g0.mshrCtl.mshrs_7.tgtid_rcompack;
    force u_i0.u_core.mshrCtl.u_core.mshrs[7].entry.u_core.txnid_rcompack = u_g0.mshrCtl.mshrs_7.txnid_rcompack;
    force u_i0.u_core.mshrCtl.u_core.mshrs[7].entry.u_core.tgtid_wcompack = u_g0.mshrCtl.mshrs_7.tgtid_wcompack;
    force u_i0.u_core.mshrCtl.u_core.mshrs[7].entry.u_core.txnid_wcompack = u_g0.mshrCtl.mshrs_7.txnid_wcompack;
    force u_i0.u_core.mshrCtl.u_core.mshrs[7].entry.u_core.srcid_retryack = u_g0.mshrCtl.mshrs_7.srcid_retryack;
    force u_i0.u_core.mshrCtl.u_core.mshrs[7].entry.u_core.acquire_ts = u_g0.mshrCtl.mshrs_7.acquire_ts;
    force u_i0.u_core.mshrCtl.u_core.mshrs[7].entry.u_core.release_ts = u_g0.mshrCtl.mshrs_7.release_ts;
    force u_i0.u_core.mshrCtl.u_core.mshrs[7].entry.u_core.acquire_period_valid_REG = u_g0.mshrCtl.mshrs_7.acquire_period_valid_REG;
    force u_i0.u_core.mshrCtl.u_core.mshrs[7].entry.u_core.release_period_valid_REG = u_g0.mshrCtl.mshrs_7.release_period_valid_REG;
    force u_i0.u_core.mshrCtl.u_core.mshrs[7].entry.u_core.REG = u_g0.mshrCtl.mshrs_7.REG;
    force u_i0.u_core.mshrCtl.u_core.mshrs[7].entry.u_core.REG_1 = u_g0.mshrCtl.mshrs_7.REG_1;
    force u_i0.u_core.mshrCtl.u_core.mshrs[7].entry.u_core.REG_2 = u_g0.mshrCtl.mshrs_7.REG_2;
    force u_i0.u_core.mshrCtl.u_core.mshrs[7].entry.u_core.REG_3 = u_g0.mshrCtl.mshrs_7.REG_3;
    force u_i0.u_core.mshrCtl.u_core.mshrs[8].entry.u_core.tgtid_rcompack = u_g0.mshrCtl.mshrs_8.tgtid_rcompack;
    force u_i0.u_core.mshrCtl.u_core.mshrs[8].entry.u_core.txnid_rcompack = u_g0.mshrCtl.mshrs_8.txnid_rcompack;
    force u_i0.u_core.mshrCtl.u_core.mshrs[8].entry.u_core.tgtid_wcompack = u_g0.mshrCtl.mshrs_8.tgtid_wcompack;
    force u_i0.u_core.mshrCtl.u_core.mshrs[8].entry.u_core.txnid_wcompack = u_g0.mshrCtl.mshrs_8.txnid_wcompack;
    force u_i0.u_core.mshrCtl.u_core.mshrs[8].entry.u_core.srcid_retryack = u_g0.mshrCtl.mshrs_8.srcid_retryack;
    force u_i0.u_core.mshrCtl.u_core.mshrs[8].entry.u_core.acquire_ts = u_g0.mshrCtl.mshrs_8.acquire_ts;
    force u_i0.u_core.mshrCtl.u_core.mshrs[8].entry.u_core.release_ts = u_g0.mshrCtl.mshrs_8.release_ts;
    force u_i0.u_core.mshrCtl.u_core.mshrs[8].entry.u_core.acquire_period_valid_REG = u_g0.mshrCtl.mshrs_8.acquire_period_valid_REG;
    force u_i0.u_core.mshrCtl.u_core.mshrs[8].entry.u_core.release_period_valid_REG = u_g0.mshrCtl.mshrs_8.release_period_valid_REG;
    force u_i0.u_core.mshrCtl.u_core.mshrs[8].entry.u_core.REG = u_g0.mshrCtl.mshrs_8.REG;
    force u_i0.u_core.mshrCtl.u_core.mshrs[8].entry.u_core.REG_1 = u_g0.mshrCtl.mshrs_8.REG_1;
    force u_i0.u_core.mshrCtl.u_core.mshrs[8].entry.u_core.REG_2 = u_g0.mshrCtl.mshrs_8.REG_2;
    force u_i0.u_core.mshrCtl.u_core.mshrs[8].entry.u_core.REG_3 = u_g0.mshrCtl.mshrs_8.REG_3;
    force u_i0.u_core.mshrCtl.u_core.mshrs[9].entry.u_core.tgtid_rcompack = u_g0.mshrCtl.mshrs_9.tgtid_rcompack;
    force u_i0.u_core.mshrCtl.u_core.mshrs[9].entry.u_core.txnid_rcompack = u_g0.mshrCtl.mshrs_9.txnid_rcompack;
    force u_i0.u_core.mshrCtl.u_core.mshrs[9].entry.u_core.tgtid_wcompack = u_g0.mshrCtl.mshrs_9.tgtid_wcompack;
    force u_i0.u_core.mshrCtl.u_core.mshrs[9].entry.u_core.txnid_wcompack = u_g0.mshrCtl.mshrs_9.txnid_wcompack;
    force u_i0.u_core.mshrCtl.u_core.mshrs[9].entry.u_core.srcid_retryack = u_g0.mshrCtl.mshrs_9.srcid_retryack;
    force u_i0.u_core.mshrCtl.u_core.mshrs[9].entry.u_core.acquire_ts = u_g0.mshrCtl.mshrs_9.acquire_ts;
    force u_i0.u_core.mshrCtl.u_core.mshrs[9].entry.u_core.release_ts = u_g0.mshrCtl.mshrs_9.release_ts;
    force u_i0.u_core.mshrCtl.u_core.mshrs[9].entry.u_core.acquire_period_valid_REG = u_g0.mshrCtl.mshrs_9.acquire_period_valid_REG;
    force u_i0.u_core.mshrCtl.u_core.mshrs[9].entry.u_core.release_period_valid_REG = u_g0.mshrCtl.mshrs_9.release_period_valid_REG;
    force u_i0.u_core.mshrCtl.u_core.mshrs[9].entry.u_core.REG = u_g0.mshrCtl.mshrs_9.REG;
    force u_i0.u_core.mshrCtl.u_core.mshrs[9].entry.u_core.REG_1 = u_g0.mshrCtl.mshrs_9.REG_1;
    force u_i0.u_core.mshrCtl.u_core.mshrs[9].entry.u_core.REG_2 = u_g0.mshrCtl.mshrs_9.REG_2;
    force u_i0.u_core.mshrCtl.u_core.mshrs[9].entry.u_core.REG_3 = u_g0.mshrCtl.mshrs_9.REG_3;
    force u_i0.u_core.mshrCtl.u_core.mshrs[10].entry.u_core.tgtid_rcompack = u_g0.mshrCtl.mshrs_10.tgtid_rcompack;
    force u_i0.u_core.mshrCtl.u_core.mshrs[10].entry.u_core.txnid_rcompack = u_g0.mshrCtl.mshrs_10.txnid_rcompack;
    force u_i0.u_core.mshrCtl.u_core.mshrs[10].entry.u_core.tgtid_wcompack = u_g0.mshrCtl.mshrs_10.tgtid_wcompack;
    force u_i0.u_core.mshrCtl.u_core.mshrs[10].entry.u_core.txnid_wcompack = u_g0.mshrCtl.mshrs_10.txnid_wcompack;
    force u_i0.u_core.mshrCtl.u_core.mshrs[10].entry.u_core.srcid_retryack = u_g0.mshrCtl.mshrs_10.srcid_retryack;
    force u_i0.u_core.mshrCtl.u_core.mshrs[10].entry.u_core.acquire_ts = u_g0.mshrCtl.mshrs_10.acquire_ts;
    force u_i0.u_core.mshrCtl.u_core.mshrs[10].entry.u_core.release_ts = u_g0.mshrCtl.mshrs_10.release_ts;
    force u_i0.u_core.mshrCtl.u_core.mshrs[10].entry.u_core.acquire_period_valid_REG = u_g0.mshrCtl.mshrs_10.acquire_period_valid_REG;
    force u_i0.u_core.mshrCtl.u_core.mshrs[10].entry.u_core.release_period_valid_REG = u_g0.mshrCtl.mshrs_10.release_period_valid_REG;
    force u_i0.u_core.mshrCtl.u_core.mshrs[10].entry.u_core.REG = u_g0.mshrCtl.mshrs_10.REG;
    force u_i0.u_core.mshrCtl.u_core.mshrs[10].entry.u_core.REG_1 = u_g0.mshrCtl.mshrs_10.REG_1;
    force u_i0.u_core.mshrCtl.u_core.mshrs[10].entry.u_core.REG_2 = u_g0.mshrCtl.mshrs_10.REG_2;
    force u_i0.u_core.mshrCtl.u_core.mshrs[10].entry.u_core.REG_3 = u_g0.mshrCtl.mshrs_10.REG_3;
    force u_i0.u_core.mshrCtl.u_core.mshrs[11].entry.u_core.tgtid_rcompack = u_g0.mshrCtl.mshrs_11.tgtid_rcompack;
    force u_i0.u_core.mshrCtl.u_core.mshrs[11].entry.u_core.txnid_rcompack = u_g0.mshrCtl.mshrs_11.txnid_rcompack;
    force u_i0.u_core.mshrCtl.u_core.mshrs[11].entry.u_core.tgtid_wcompack = u_g0.mshrCtl.mshrs_11.tgtid_wcompack;
    force u_i0.u_core.mshrCtl.u_core.mshrs[11].entry.u_core.txnid_wcompack = u_g0.mshrCtl.mshrs_11.txnid_wcompack;
    force u_i0.u_core.mshrCtl.u_core.mshrs[11].entry.u_core.srcid_retryack = u_g0.mshrCtl.mshrs_11.srcid_retryack;
    force u_i0.u_core.mshrCtl.u_core.mshrs[11].entry.u_core.acquire_ts = u_g0.mshrCtl.mshrs_11.acquire_ts;
    force u_i0.u_core.mshrCtl.u_core.mshrs[11].entry.u_core.release_ts = u_g0.mshrCtl.mshrs_11.release_ts;
    force u_i0.u_core.mshrCtl.u_core.mshrs[11].entry.u_core.acquire_period_valid_REG = u_g0.mshrCtl.mshrs_11.acquire_period_valid_REG;
    force u_i0.u_core.mshrCtl.u_core.mshrs[11].entry.u_core.release_period_valid_REG = u_g0.mshrCtl.mshrs_11.release_period_valid_REG;
    force u_i0.u_core.mshrCtl.u_core.mshrs[11].entry.u_core.REG = u_g0.mshrCtl.mshrs_11.REG;
    force u_i0.u_core.mshrCtl.u_core.mshrs[11].entry.u_core.REG_1 = u_g0.mshrCtl.mshrs_11.REG_1;
    force u_i0.u_core.mshrCtl.u_core.mshrs[11].entry.u_core.REG_2 = u_g0.mshrCtl.mshrs_11.REG_2;
    force u_i0.u_core.mshrCtl.u_core.mshrs[11].entry.u_core.REG_3 = u_g0.mshrCtl.mshrs_11.REG_3;
    force u_i0.u_core.mshrCtl.u_core.mshrs[12].entry.u_core.tgtid_rcompack = u_g0.mshrCtl.mshrs_12.tgtid_rcompack;
    force u_i0.u_core.mshrCtl.u_core.mshrs[12].entry.u_core.txnid_rcompack = u_g0.mshrCtl.mshrs_12.txnid_rcompack;
    force u_i0.u_core.mshrCtl.u_core.mshrs[12].entry.u_core.tgtid_wcompack = u_g0.mshrCtl.mshrs_12.tgtid_wcompack;
    force u_i0.u_core.mshrCtl.u_core.mshrs[12].entry.u_core.txnid_wcompack = u_g0.mshrCtl.mshrs_12.txnid_wcompack;
    force u_i0.u_core.mshrCtl.u_core.mshrs[12].entry.u_core.srcid_retryack = u_g0.mshrCtl.mshrs_12.srcid_retryack;
    force u_i0.u_core.mshrCtl.u_core.mshrs[12].entry.u_core.acquire_ts = u_g0.mshrCtl.mshrs_12.acquire_ts;
    force u_i0.u_core.mshrCtl.u_core.mshrs[12].entry.u_core.release_ts = u_g0.mshrCtl.mshrs_12.release_ts;
    force u_i0.u_core.mshrCtl.u_core.mshrs[12].entry.u_core.acquire_period_valid_REG = u_g0.mshrCtl.mshrs_12.acquire_period_valid_REG;
    force u_i0.u_core.mshrCtl.u_core.mshrs[12].entry.u_core.release_period_valid_REG = u_g0.mshrCtl.mshrs_12.release_period_valid_REG;
    force u_i0.u_core.mshrCtl.u_core.mshrs[12].entry.u_core.REG = u_g0.mshrCtl.mshrs_12.REG;
    force u_i0.u_core.mshrCtl.u_core.mshrs[12].entry.u_core.REG_1 = u_g0.mshrCtl.mshrs_12.REG_1;
    force u_i0.u_core.mshrCtl.u_core.mshrs[12].entry.u_core.REG_2 = u_g0.mshrCtl.mshrs_12.REG_2;
    force u_i0.u_core.mshrCtl.u_core.mshrs[12].entry.u_core.REG_3 = u_g0.mshrCtl.mshrs_12.REG_3;
    force u_i0.u_core.mshrCtl.u_core.mshrs[13].entry.u_core.tgtid_rcompack = u_g0.mshrCtl.mshrs_13.tgtid_rcompack;
    force u_i0.u_core.mshrCtl.u_core.mshrs[13].entry.u_core.txnid_rcompack = u_g0.mshrCtl.mshrs_13.txnid_rcompack;
    force u_i0.u_core.mshrCtl.u_core.mshrs[13].entry.u_core.tgtid_wcompack = u_g0.mshrCtl.mshrs_13.tgtid_wcompack;
    force u_i0.u_core.mshrCtl.u_core.mshrs[13].entry.u_core.txnid_wcompack = u_g0.mshrCtl.mshrs_13.txnid_wcompack;
    force u_i0.u_core.mshrCtl.u_core.mshrs[13].entry.u_core.srcid_retryack = u_g0.mshrCtl.mshrs_13.srcid_retryack;
    force u_i0.u_core.mshrCtl.u_core.mshrs[13].entry.u_core.acquire_ts = u_g0.mshrCtl.mshrs_13.acquire_ts;
    force u_i0.u_core.mshrCtl.u_core.mshrs[13].entry.u_core.release_ts = u_g0.mshrCtl.mshrs_13.release_ts;
    force u_i0.u_core.mshrCtl.u_core.mshrs[13].entry.u_core.acquire_period_valid_REG = u_g0.mshrCtl.mshrs_13.acquire_period_valid_REG;
    force u_i0.u_core.mshrCtl.u_core.mshrs[13].entry.u_core.release_period_valid_REG = u_g0.mshrCtl.mshrs_13.release_period_valid_REG;
    force u_i0.u_core.mshrCtl.u_core.mshrs[13].entry.u_core.REG = u_g0.mshrCtl.mshrs_13.REG;
    force u_i0.u_core.mshrCtl.u_core.mshrs[13].entry.u_core.REG_1 = u_g0.mshrCtl.mshrs_13.REG_1;
    force u_i0.u_core.mshrCtl.u_core.mshrs[13].entry.u_core.REG_2 = u_g0.mshrCtl.mshrs_13.REG_2;
    force u_i0.u_core.mshrCtl.u_core.mshrs[13].entry.u_core.REG_3 = u_g0.mshrCtl.mshrs_13.REG_3;
    force u_i0.u_core.mshrCtl.u_core.mshrs[14].entry.u_core.tgtid_rcompack = u_g0.mshrCtl.mshrs_14.tgtid_rcompack;
    force u_i0.u_core.mshrCtl.u_core.mshrs[14].entry.u_core.txnid_rcompack = u_g0.mshrCtl.mshrs_14.txnid_rcompack;
    force u_i0.u_core.mshrCtl.u_core.mshrs[14].entry.u_core.tgtid_wcompack = u_g0.mshrCtl.mshrs_14.tgtid_wcompack;
    force u_i0.u_core.mshrCtl.u_core.mshrs[14].entry.u_core.txnid_wcompack = u_g0.mshrCtl.mshrs_14.txnid_wcompack;
    force u_i0.u_core.mshrCtl.u_core.mshrs[14].entry.u_core.srcid_retryack = u_g0.mshrCtl.mshrs_14.srcid_retryack;
    force u_i0.u_core.mshrCtl.u_core.mshrs[14].entry.u_core.acquire_ts = u_g0.mshrCtl.mshrs_14.acquire_ts;
    force u_i0.u_core.mshrCtl.u_core.mshrs[14].entry.u_core.release_ts = u_g0.mshrCtl.mshrs_14.release_ts;
    force u_i0.u_core.mshrCtl.u_core.mshrs[14].entry.u_core.acquire_period_valid_REG = u_g0.mshrCtl.mshrs_14.acquire_period_valid_REG;
    force u_i0.u_core.mshrCtl.u_core.mshrs[14].entry.u_core.release_period_valid_REG = u_g0.mshrCtl.mshrs_14.release_period_valid_REG;
    force u_i0.u_core.mshrCtl.u_core.mshrs[14].entry.u_core.REG = u_g0.mshrCtl.mshrs_14.REG;
    force u_i0.u_core.mshrCtl.u_core.mshrs[14].entry.u_core.REG_1 = u_g0.mshrCtl.mshrs_14.REG_1;
    force u_i0.u_core.mshrCtl.u_core.mshrs[14].entry.u_core.REG_2 = u_g0.mshrCtl.mshrs_14.REG_2;
    force u_i0.u_core.mshrCtl.u_core.mshrs[14].entry.u_core.REG_3 = u_g0.mshrCtl.mshrs_14.REG_3;
    force u_i0.u_core.mshrCtl.u_core.mshrs[15].entry.u_core.tgtid_rcompack = u_g0.mshrCtl.mshrs_15.tgtid_rcompack;
    force u_i0.u_core.mshrCtl.u_core.mshrs[15].entry.u_core.txnid_rcompack = u_g0.mshrCtl.mshrs_15.txnid_rcompack;
    force u_i0.u_core.mshrCtl.u_core.mshrs[15].entry.u_core.tgtid_wcompack = u_g0.mshrCtl.mshrs_15.tgtid_wcompack;
    force u_i0.u_core.mshrCtl.u_core.mshrs[15].entry.u_core.txnid_wcompack = u_g0.mshrCtl.mshrs_15.txnid_wcompack;
    force u_i0.u_core.mshrCtl.u_core.mshrs[15].entry.u_core.srcid_retryack = u_g0.mshrCtl.mshrs_15.srcid_retryack;
    force u_i0.u_core.mshrCtl.u_core.mshrs[15].entry.u_core.acquire_ts = u_g0.mshrCtl.mshrs_15.acquire_ts;
    force u_i0.u_core.mshrCtl.u_core.mshrs[15].entry.u_core.release_ts = u_g0.mshrCtl.mshrs_15.release_ts;
    force u_i0.u_core.mshrCtl.u_core.mshrs[15].entry.u_core.acquire_period_valid_REG = u_g0.mshrCtl.mshrs_15.acquire_period_valid_REG;
    force u_i0.u_core.mshrCtl.u_core.mshrs[15].entry.u_core.release_period_valid_REG = u_g0.mshrCtl.mshrs_15.release_period_valid_REG;
    force u_i0.u_core.mshrCtl.u_core.mshrs[15].entry.u_core.REG = u_g0.mshrCtl.mshrs_15.REG;
    force u_i0.u_core.mshrCtl.u_core.mshrs[15].entry.u_core.REG_1 = u_g0.mshrCtl.mshrs_15.REG_1;
    force u_i0.u_core.mshrCtl.u_core.mshrs[15].entry.u_core.REG_2 = u_g0.mshrCtl.mshrs_15.REG_2;
    force u_i0.u_core.mshrCtl.u_core.mshrs[15].entry.u_core.REG_3 = u_g0.mshrCtl.mshrs_15.REG_3;
    force u_i0.u_core.mshrCtl.u_core.io_perf_0_value_REG = u_g0.mshrCtl.io_perf_0_value_REG;
    force u_i0.u_core.mshrCtl.u_core.io_perf_0_value_REG_1 = u_g0.mshrCtl.io_perf_0_value_REG_1;
    force u_i0.u_core.mshrCtl.u_core.io_perf_1_value_REG = u_g0.mshrCtl.io_perf_1_value_REG;
    force u_i0.u_core.mshrCtl.u_core.io_perf_1_value_REG_1 = u_g0.mshrCtl.io_perf_1_value_REG_1;
    force u_i0.u_core.mshrCtl.u_core.io_perf_3_value_REG = u_g0.mshrCtl.io_perf_3_value_REG;
    force u_i0.u_core.mshrCtl.u_core.io_perf_3_value_REG_1 = u_g0.mshrCtl.io_perf_3_value_REG_1;
    force u_i0.u_core.mshrCtl.u_core.REG = u_g0.mshrCtl.REG;
    force u_i0.u_core.mainPipe.u_core.data_s4 = u_g0.mainPipe.data_s4;
    force u_i0.u_core.mainPipe.u_core.data_s5 = u_g0.mainPipe.data_s5;
    force u_i0.u_core.mainPipe.u_core.s3DropValid_d1 = u_g0.mainPipe.REG;
    force u_i0.u_core.mainPipe.u_core.reqDrop_s3_d1 = u_g0.mainPipe.reqDropped_s5_REG;
    force u_i0.u_core.mainPipe.u_core.reqDrop_s3_d2 = u_g0.mainPipe.reqDropped_s5_REG_1;
    force u_i0.u_core.mainPipe.u_core.reqDrop_s4_d1 = u_g0.mainPipe.reqDropped_s5_REG_2;
    u_i0.u_core.mainPipe.customL1Hint.hintQueue.ram_ext.Memory = u_g0.mainPipe.customL1Hint.hintQueue.ram_ext.Memory;
    u_i0.u_core.mainPipe.customL1Hint.hint_s1Queue.ram_ext.Memory = u_g0.mainPipe.customL1Hint.hint_s1Queue.ram_ext.Memory;
    force u_i0.u_core.mainPipe.u_core.perf_d1[0] = u_g0.mainPipe.io_perf_0_value_REG;
    force u_i0.u_core.mainPipe.u_core.perf[0] = u_g0.mainPipe.io_perf_0_value_REG_1;
    force u_i0.u_core.mainPipe.u_core.perf_d1[1] = u_g0.mainPipe.io_perf_1_value_REG;
    force u_i0.u_core.mainPipe.u_core.perf[1] = u_g0.mainPipe.io_perf_1_value_REG_1;
    force u_i0.u_core.mainPipe.u_core.perf_d1[2] = u_g0.mainPipe.io_perf_2_value_REG;
    force u_i0.u_core.mainPipe.u_core.perf[2] = u_g0.mainPipe.io_perf_2_value_REG_1;
    force u_i0.u_core.mainPipe.u_core.perf_d1[3] = u_g0.mainPipe.io_perf_3_value_REG;
    force u_i0.u_core.mainPipe.u_core.perf[3] = u_g0.mainPipe.io_perf_3_value_REG_1;
    force u_i0.u_core.mainPipe.u_core.perf_d1[4] = u_g0.mainPipe.io_perf_4_value_REG;
    force u_i0.u_core.mainPipe.u_core.perf[4] = u_g0.mainPipe.io_perf_4_value_REG_1;
    force u_i0.u_core.mainPipe.u_core.perf_d1[5] = u_g0.mainPipe.io_perf_5_value_REG;
    force u_i0.u_core.mainPipe.u_core.perf[5] = u_g0.mainPipe.io_perf_5_value_REG_1;
    force u_i0.u_core.mainPipe.u_core.perf_d1[6] = u_g0.mainPipe.io_perf_6_value_REG;
    force u_i0.u_core.mainPipe.u_core.perf[6] = u_g0.mainPipe.io_perf_6_value_REG_1;
    force u_i0.u_core.mainPipe.u_core.perf_d1[7] = u_g0.mainPipe.io_perf_7_value_REG;
    force u_i0.u_core.mainPipe.u_core.perf[7] = u_g0.mainPipe.io_perf_7_value_REG_1;
    force u_i0.u_core.mainPipe.u_core.perf_d1[8] = u_g0.mainPipe.io_perf_8_value_REG;
    force u_i0.u_core.mainPipe.u_core.perf[8] = u_g0.mainPipe.io_perf_8_value_REG_1;
    force u_i0.u_core.mainPipe.u_core.perf_d1[9] = u_g0.mainPipe.io_perf_9_value_REG;
    force u_i0.u_core.mainPipe.u_core.perf[9] = u_g0.mainPipe.io_perf_9_value_REG_1;
    force u_i0.u_core.mainPipe.u_core.perf_d1[10] = u_g0.mainPipe.io_perf_10_value_REG;
    force u_i0.u_core.mainPipe.u_core.perf[10] = u_g0.mainPipe.io_perf_10_value_REG_1;
    force u_i0.u_core.mainPipe.u_core.perf_d1[11] = u_g0.mainPipe.io_perf_11_value_REG;
    force u_i0.u_core.mainPipe.u_core.perf[11] = u_g0.mainPipe.io_perf_11_value_REG_1;
    force u_i0.u_core.mainPipe.u_core.perf_d1[12] = u_g0.mainPipe.io_perf_12_value_REG;
    force u_i0.u_core.mainPipe.u_core.perf[12] = u_g0.mainPipe.io_perf_12_value_REG_1;
    u_i0.u_core.grantBuf.grantQueue.ram_ext.Memory = u_g0.grantBuf.grantQueue.ram_ext.Memory;
    u_i0.u_core.grantBuf.grantQueueData0.ram_data_data_ext.Memory = u_g0.grantBuf.grantQueueData0.ram_data_data_ext.Memory;
    u_i0.u_core.grantBuf.grantQueueData1.ram_data_data_ext.Memory = u_g0.grantBuf.grantQueueData1.ram_data_data_ext.Memory;
    u_i0.u_core.grantBuf.pftRespQueue.ram_ext.Memory = u_g0.grantBuf.pftRespQueue.ram_ext.Memory;
    force u_i0.u_core.grantBuf.u_core.validPrev[0] = u_g0.grantBuf.REG;
    force u_i0.u_core.grantBuf.u_core.histValidPrev[0] = u_g0.grantBuf.enable_REG;
    force u_i0.u_core.grantBuf.u_core.validPrev[1] = u_g0.grantBuf.REG_1;
    force u_i0.u_core.grantBuf.u_core.histValidPrev[1] = u_g0.grantBuf.enable_REG_1;
    force u_i0.u_core.grantBuf.u_core.validPrev[2] = u_g0.grantBuf.REG_2;
    force u_i0.u_core.grantBuf.u_core.histValidPrev[2] = u_g0.grantBuf.enable_REG_2;
    force u_i0.u_core.grantBuf.u_core.validPrev[3] = u_g0.grantBuf.REG_3;
    force u_i0.u_core.grantBuf.u_core.histValidPrev[3] = u_g0.grantBuf.enable_REG_3;
    force u_i0.u_core.grantBuf.u_core.validPrev[4] = u_g0.grantBuf.REG_4;
    force u_i0.u_core.grantBuf.u_core.histValidPrev[4] = u_g0.grantBuf.enable_REG_4;
    force u_i0.u_core.grantBuf.u_core.validPrev[5] = u_g0.grantBuf.REG_5;
    force u_i0.u_core.grantBuf.u_core.histValidPrev[5] = u_g0.grantBuf.enable_REG_5;
    force u_i0.u_core.grantBuf.u_core.validPrev[6] = u_g0.grantBuf.REG_6;
    force u_i0.u_core.grantBuf.u_core.histValidPrev[6] = u_g0.grantBuf.enable_REG_6;
    force u_i0.u_core.grantBuf.u_core.validPrev[7] = u_g0.grantBuf.REG_7;
    force u_i0.u_core.grantBuf.u_core.histValidPrev[7] = u_g0.grantBuf.enable_REG_7;
    force u_i0.u_core.grantBuf.u_core.validPrev[8] = u_g0.grantBuf.REG_8;
    force u_i0.u_core.grantBuf.u_core.histValidPrev[8] = u_g0.grantBuf.enable_REG_8;
    force u_i0.u_core.grantBuf.u_core.validPrev[9] = u_g0.grantBuf.REG_9;
    force u_i0.u_core.grantBuf.u_core.histValidPrev[9] = u_g0.grantBuf.enable_REG_9;
    force u_i0.u_core.grantBuf.u_core.validPrev[10] = u_g0.grantBuf.REG_10;
    force u_i0.u_core.grantBuf.u_core.histValidPrev[10] = u_g0.grantBuf.enable_REG_10;
    force u_i0.u_core.grantBuf.u_core.validPrev[11] = u_g0.grantBuf.REG_11;
    force u_i0.u_core.grantBuf.u_core.histValidPrev[11] = u_g0.grantBuf.enable_REG_11;
    force u_i0.u_core.grantBuf.u_core.validPrev[12] = u_g0.grantBuf.REG_12;
    force u_i0.u_core.grantBuf.u_core.histValidPrev[12] = u_g0.grantBuf.enable_REG_12;
    force u_i0.u_core.grantBuf.u_core.validPrev[13] = u_g0.grantBuf.REG_13;
    force u_i0.u_core.grantBuf.u_core.histValidPrev[13] = u_g0.grantBuf.enable_REG_13;
    force u_i0.u_core.grantBuf.u_core.validPrev[14] = u_g0.grantBuf.REG_14;
    force u_i0.u_core.grantBuf.u_core.histValidPrev[14] = u_g0.grantBuf.enable_REG_14;
    force u_i0.u_core.grantBuf.u_core.validPrev[15] = u_g0.grantBuf.REG_15;
    force u_i0.u_core.grantBuf.u_core.histValidPrev[15] = u_g0.grantBuf.enable_REG_15;
    u_i0.u_core.rxsnp.queue.ram_ext.Memory = u_g0.rxsnp.queue.ram_ext.Memory;
    force u_i0.u_core.rxsnp.u_core.replPrevForBlock[0] = u_g0.rxsnp.replaceBlockSnpMask_REG;
    force u_i0.u_core.rxsnp.u_core.replPrevForNest[0] = u_g0.rxsnp.replaceNestSnpMask_REG;
    force u_i0.u_core.rxsnp.u_core.replPrevForBlock[1] = u_g0.rxsnp.replaceBlockSnpMask_REG_1;
    force u_i0.u_core.rxsnp.u_core.replPrevForNest[1] = u_g0.rxsnp.replaceNestSnpMask_REG_1;
    force u_i0.u_core.rxsnp.u_core.replPrevForBlock[2] = u_g0.rxsnp.replaceBlockSnpMask_REG_2;
    force u_i0.u_core.rxsnp.u_core.replPrevForNest[2] = u_g0.rxsnp.replaceNestSnpMask_REG_2;
    force u_i0.u_core.rxsnp.u_core.replPrevForBlock[3] = u_g0.rxsnp.replaceBlockSnpMask_REG_3;
    force u_i0.u_core.rxsnp.u_core.replPrevForNest[3] = u_g0.rxsnp.replaceNestSnpMask_REG_3;
    force u_i0.u_core.rxsnp.u_core.replPrevForBlock[4] = u_g0.rxsnp.replaceBlockSnpMask_REG_4;
    force u_i0.u_core.rxsnp.u_core.replPrevForNest[4] = u_g0.rxsnp.replaceNestSnpMask_REG_4;
    force u_i0.u_core.rxsnp.u_core.replPrevForBlock[5] = u_g0.rxsnp.replaceBlockSnpMask_REG_5;
    force u_i0.u_core.rxsnp.u_core.replPrevForNest[5] = u_g0.rxsnp.replaceNestSnpMask_REG_5;
    force u_i0.u_core.rxsnp.u_core.replPrevForBlock[6] = u_g0.rxsnp.replaceBlockSnpMask_REG_6;
    force u_i0.u_core.rxsnp.u_core.replPrevForNest[6] = u_g0.rxsnp.replaceNestSnpMask_REG_6;
    force u_i0.u_core.rxsnp.u_core.replPrevForBlock[7] = u_g0.rxsnp.replaceBlockSnpMask_REG_7;
    force u_i0.u_core.rxsnp.u_core.replPrevForNest[7] = u_g0.rxsnp.replaceNestSnpMask_REG_7;
    force u_i0.u_core.rxsnp.u_core.replPrevForBlock[8] = u_g0.rxsnp.replaceBlockSnpMask_REG_8;
    force u_i0.u_core.rxsnp.u_core.replPrevForNest[8] = u_g0.rxsnp.replaceNestSnpMask_REG_8;
    force u_i0.u_core.rxsnp.u_core.replPrevForBlock[9] = u_g0.rxsnp.replaceBlockSnpMask_REG_9;
    force u_i0.u_core.rxsnp.u_core.replPrevForNest[9] = u_g0.rxsnp.replaceNestSnpMask_REG_9;
    force u_i0.u_core.rxsnp.u_core.replPrevForBlock[10] = u_g0.rxsnp.replaceBlockSnpMask_REG_10;
    force u_i0.u_core.rxsnp.u_core.replPrevForNest[10] = u_g0.rxsnp.replaceNestSnpMask_REG_10;
    force u_i0.u_core.rxsnp.u_core.replPrevForBlock[11] = u_g0.rxsnp.replaceBlockSnpMask_REG_11;
    force u_i0.u_core.rxsnp.u_core.replPrevForNest[11] = u_g0.rxsnp.replaceNestSnpMask_REG_11;
    force u_i0.u_core.rxsnp.u_core.replPrevForBlock[12] = u_g0.rxsnp.replaceBlockSnpMask_REG_12;
    force u_i0.u_core.rxsnp.u_core.replPrevForNest[12] = u_g0.rxsnp.replaceNestSnpMask_REG_12;
    force u_i0.u_core.rxsnp.u_core.replPrevForBlock[13] = u_g0.rxsnp.replaceBlockSnpMask_REG_13;
    force u_i0.u_core.rxsnp.u_core.replPrevForNest[13] = u_g0.rxsnp.replaceNestSnpMask_REG_13;
    force u_i0.u_core.rxsnp.u_core.replPrevForBlock[14] = u_g0.rxsnp.replaceBlockSnpMask_REG_14;
    force u_i0.u_core.rxsnp.u_core.replPrevForNest[14] = u_g0.rxsnp.replaceNestSnpMask_REG_14;
    force u_i0.u_core.rxsnp.u_core.replPrevForBlock[15] = u_g0.rxsnp.replaceBlockSnpMask_REG_15;
    force u_i0.u_core.rxsnp.u_core.replPrevForNest[15] = u_g0.rxsnp.replaceNestSnpMask_REG_15;
    force u_i0.u_core.reqBuf.chosenQ.u_core.ram = u_g0.reqBuf.chosenQ.ram;
    force u_i0.u_core.reqBuf.u_core.hitPfPrev_set = u_g0.reqBuf.io_hasHitPfInMSHR_valid_REG_set;
    force u_i0.u_core.reqBuf.u_core.hitPfPrev_tag = u_g0.reqBuf.io_hasHitPfInMSHR_valid_REG_tag;
    force u_i0.u_core.reqBuf.u_core.mergeAPrev_set = u_g0.reqBuf.io_hasMergeA_REG_set;
    force u_i0.u_core.reqBuf.u_core.mergeAPrev_tag = u_g0.reqBuf.io_hasMergeA_REG_tag;
    force u_i0.u_core.reqBuf.u_core.sameSetS3Valid[0] = u_g0.reqBuf.canFlow_sameSet_s3_REG;
    force u_i0.u_core.reqBuf.u_core.sameSetS3Set[0] = u_g0.reqBuf.canFlow_sameSet_s3_r;
    force u_i0.u_core.reqBuf.u_core.sameSetS3Valid[1] = u_g0.reqBuf.buffer_rdy_sameSet_s3_REG;
    force u_i0.u_core.reqBuf.u_core.sameSetS3Set[1] = u_g0.reqBuf.buffer_rdy_sameSet_s3_r;
    force u_i0.u_core.reqBuf.u_core.sameSetS3Valid[2] = u_g0.reqBuf.buffer_0_rdy_sameSet_s3_REG;
    force u_i0.u_core.reqBuf.u_core.sameSetS3Set[2] = u_g0.reqBuf.buffer_0_rdy_sameSet_s3_r;
    force u_i0.u_core.reqBuf.u_core.sameSetS3Valid[3] = u_g0.reqBuf.buffer_1_rdy_sameSet_s3_REG;
    force u_i0.u_core.reqBuf.u_core.sameSetS3Set[3] = u_g0.reqBuf.buffer_1_rdy_sameSet_s3_r;
    force u_i0.u_core.reqBuf.u_core.sameSetS3Valid[4] = u_g0.reqBuf.buffer_2_rdy_sameSet_s3_REG;
    force u_i0.u_core.reqBuf.u_core.sameSetS3Set[4] = u_g0.reqBuf.buffer_2_rdy_sameSet_s3_r;
    force u_i0.u_core.reqBuf.u_core.sameSetS3Valid[5] = u_g0.reqBuf.buffer_3_rdy_sameSet_s3_REG;
    force u_i0.u_core.reqBuf.u_core.sameSetS3Set[5] = u_g0.reqBuf.buffer_3_rdy_sameSet_s3_r;
    force u_i0.u_core.sinkC.u_core.bufRespStage[0] = u_g0.sinkC.r_0;
    force u_i0.u_core.sinkC.u_core.bufRespStage[1] = u_g0.sinkC.r_1;
    force u_i0.u_core.sinkC.u_core.bufRespOut[0] = u_g0.sinkC.REG_0;
    force u_i0.u_core.sinkC.u_core.bufRespOut[1] = u_g0.sinkC.REG_1;
    force u_i0.u_core.sinkC.u_core.refillIdReg = u_g0.sinkC.io_refillBufWrite_bits_id_REG;
    force u_i0.u_core.sinkC.u_core.refillBufIdxReg = u_g0.sinkC.io_refillBufWrite_bits_data_data_REG;
    force u_i0.u_core.sinkC.u_core.taskFirePrev = u_g0.sinkC.REG_1_0;
    force u_i0.u_core.sinkC.u_core.taskBufIdxPrev = u_g0.sinkC.REG_2;
    force u_i0.u_core.reqArb.u_core.ds_mcp2_stall = u_g0.reqArb.ds_mcp2_stall;
    force u_i0.u_core.refillBuf.u_core.buffer[0][0] = u_g0.refillBuf.buffer_0_0;
    force u_i0.u_core.refillBuf.u_core.buffer[0][1] = u_g0.refillBuf.buffer_0_1;
    force u_i0.u_core.refillBuf.u_core.buffer[1][0] = u_g0.refillBuf.buffer_1_0;
    force u_i0.u_core.refillBuf.u_core.buffer[1][1] = u_g0.refillBuf.buffer_1_1;
    force u_i0.u_core.refillBuf.u_core.buffer[2][0] = u_g0.refillBuf.buffer_2_0;
    force u_i0.u_core.refillBuf.u_core.buffer[2][1] = u_g0.refillBuf.buffer_2_1;
    force u_i0.u_core.refillBuf.u_core.buffer[3][0] = u_g0.refillBuf.buffer_3_0;
    force u_i0.u_core.refillBuf.u_core.buffer[3][1] = u_g0.refillBuf.buffer_3_1;
    force u_i0.u_core.refillBuf.u_core.buffer[4][0] = u_g0.refillBuf.buffer_4_0;
    force u_i0.u_core.refillBuf.u_core.buffer[4][1] = u_g0.refillBuf.buffer_4_1;
    force u_i0.u_core.refillBuf.u_core.buffer[5][0] = u_g0.refillBuf.buffer_5_0;
    force u_i0.u_core.refillBuf.u_core.buffer[5][1] = u_g0.refillBuf.buffer_5_1;
    force u_i0.u_core.refillBuf.u_core.buffer[6][0] = u_g0.refillBuf.buffer_6_0;
    force u_i0.u_core.refillBuf.u_core.buffer[6][1] = u_g0.refillBuf.buffer_6_1;
    force u_i0.u_core.refillBuf.u_core.buffer[7][0] = u_g0.refillBuf.buffer_7_0;
    force u_i0.u_core.refillBuf.u_core.buffer[7][1] = u_g0.refillBuf.buffer_7_1;
    force u_i0.u_core.refillBuf.u_core.buffer[8][0] = u_g0.refillBuf.buffer_8_0;
    force u_i0.u_core.refillBuf.u_core.buffer[8][1] = u_g0.refillBuf.buffer_8_1;
    force u_i0.u_core.refillBuf.u_core.buffer[9][0] = u_g0.refillBuf.buffer_9_0;
    force u_i0.u_core.refillBuf.u_core.buffer[9][1] = u_g0.refillBuf.buffer_9_1;
    force u_i0.u_core.refillBuf.u_core.buffer[10][0] = u_g0.refillBuf.buffer_10_0;
    force u_i0.u_core.refillBuf.u_core.buffer[10][1] = u_g0.refillBuf.buffer_10_1;
    force u_i0.u_core.refillBuf.u_core.buffer[11][0] = u_g0.refillBuf.buffer_11_0;
    force u_i0.u_core.refillBuf.u_core.buffer[11][1] = u_g0.refillBuf.buffer_11_1;
    force u_i0.u_core.refillBuf.u_core.buffer[12][0] = u_g0.refillBuf.buffer_12_0;
    force u_i0.u_core.refillBuf.u_core.buffer[12][1] = u_g0.refillBuf.buffer_12_1;
    force u_i0.u_core.refillBuf.u_core.buffer[13][0] = u_g0.refillBuf.buffer_13_0;
    force u_i0.u_core.refillBuf.u_core.buffer[13][1] = u_g0.refillBuf.buffer_13_1;
    force u_i0.u_core.refillBuf.u_core.buffer[14][0] = u_g0.refillBuf.buffer_14_0;
    force u_i0.u_core.refillBuf.u_core.buffer[14][1] = u_g0.refillBuf.buffer_14_1;
    force u_i0.u_core.refillBuf.u_core.buffer[15][0] = u_g0.refillBuf.buffer_15_0;
    force u_i0.u_core.refillBuf.u_core.buffer[15][1] = u_g0.refillBuf.buffer_15_1;
    force u_i0.u_core.releaseBuf.u_core.buffer[0][0] = u_g0.releaseBuf.buffer_0_0;
    force u_i0.u_core.releaseBuf.u_core.buffer[0][1] = u_g0.releaseBuf.buffer_0_1;
    force u_i0.u_core.releaseBuf.u_core.buffer[1][0] = u_g0.releaseBuf.buffer_1_0;
    force u_i0.u_core.releaseBuf.u_core.buffer[1][1] = u_g0.releaseBuf.buffer_1_1;
    force u_i0.u_core.releaseBuf.u_core.buffer[2][0] = u_g0.releaseBuf.buffer_2_0;
    force u_i0.u_core.releaseBuf.u_core.buffer[2][1] = u_g0.releaseBuf.buffer_2_1;
    force u_i0.u_core.releaseBuf.u_core.buffer[3][0] = u_g0.releaseBuf.buffer_3_0;
    force u_i0.u_core.releaseBuf.u_core.buffer[3][1] = u_g0.releaseBuf.buffer_3_1;
    force u_i0.u_core.releaseBuf.u_core.buffer[4][0] = u_g0.releaseBuf.buffer_4_0;
    force u_i0.u_core.releaseBuf.u_core.buffer[4][1] = u_g0.releaseBuf.buffer_4_1;
    force u_i0.u_core.releaseBuf.u_core.buffer[5][0] = u_g0.releaseBuf.buffer_5_0;
    force u_i0.u_core.releaseBuf.u_core.buffer[5][1] = u_g0.releaseBuf.buffer_5_1;
    force u_i0.u_core.releaseBuf.u_core.buffer[6][0] = u_g0.releaseBuf.buffer_6_0;
    force u_i0.u_core.releaseBuf.u_core.buffer[6][1] = u_g0.releaseBuf.buffer_6_1;
    force u_i0.u_core.releaseBuf.u_core.buffer[7][0] = u_g0.releaseBuf.buffer_7_0;
    force u_i0.u_core.releaseBuf.u_core.buffer[7][1] = u_g0.releaseBuf.buffer_7_1;
    force u_i0.u_core.releaseBuf.u_core.buffer[8][0] = u_g0.releaseBuf.buffer_8_0;
    force u_i0.u_core.releaseBuf.u_core.buffer[8][1] = u_g0.releaseBuf.buffer_8_1;
    force u_i0.u_core.releaseBuf.u_core.buffer[9][0] = u_g0.releaseBuf.buffer_9_0;
    force u_i0.u_core.releaseBuf.u_core.buffer[9][1] = u_g0.releaseBuf.buffer_9_1;
    force u_i0.u_core.releaseBuf.u_core.buffer[10][0] = u_g0.releaseBuf.buffer_10_0;
    force u_i0.u_core.releaseBuf.u_core.buffer[10][1] = u_g0.releaseBuf.buffer_10_1;
    force u_i0.u_core.releaseBuf.u_core.buffer[11][0] = u_g0.releaseBuf.buffer_11_0;
    force u_i0.u_core.releaseBuf.u_core.buffer[11][1] = u_g0.releaseBuf.buffer_11_1;
    force u_i0.u_core.releaseBuf.u_core.buffer[12][0] = u_g0.releaseBuf.buffer_12_0;
    force u_i0.u_core.releaseBuf.u_core.buffer[12][1] = u_g0.releaseBuf.buffer_12_1;
    force u_i0.u_core.releaseBuf.u_core.buffer[13][0] = u_g0.releaseBuf.buffer_13_0;
    force u_i0.u_core.releaseBuf.u_core.buffer[13][1] = u_g0.releaseBuf.buffer_13_1;
    force u_i0.u_core.releaseBuf.u_core.buffer[14][0] = u_g0.releaseBuf.buffer_14_0;
    force u_i0.u_core.releaseBuf.u_core.buffer[14][1] = u_g0.releaseBuf.buffer_14_1;
    force u_i0.u_core.releaseBuf.u_core.buffer[15][0] = u_g0.releaseBuf.buffer_15_0;
    force u_i0.u_core.releaseBuf.u_core.buffer[15][1] = u_g0.releaseBuf.buffer_15_1;
    u_i0.u_core.txdat.queue.ram_ext.Memory = u_g0.txdat.queue.ram_ext.Memory;
    u_i0.u_core.txdat.queueData0.ram_data_ext.Memory = u_g0.txdat.queueData0.ram_data_ext.Memory;
    u_i0.u_core.txdat.queueData1.ram_data_ext.Memory = u_g0.txdat.queueData1.ram_data_ext.Memory;
    u_i0.directory.tagArray.array_0_0_0.array.array.array_14_ext.ram = u_g0.directory.tagArray.array_0_0_0.array.array.array_14_ext.ram;
    u_i0.directory.tagArray.array_0_0_0.array.array.array_14_ext.reg_RW0_addr = u_g0.directory.tagArray.array_0_0_0.array.array.array_14_ext.reg_RW0_addr;
    u_i0.directory.tagArray.array_0_0_0.array.array.array_14_ext.reg_RW0_ren = u_g0.directory.tagArray.array_0_0_0.array.array.array_14_ext.reg_RW0_ren;
    force u_i0.directory.tagArray.array_0_0_0.u_core.rdataReg = u_g0.directory.tagArray.array_0_0_0.rdataReg;
    u_i0.directory.tagArray.array_0_0_1.array.array.array_14_ext.ram = u_g0.directory.tagArray.array_0_0_1.array.array.array_14_ext.ram;
    u_i0.directory.tagArray.array_0_0_1.array.array.array_14_ext.reg_RW0_addr = u_g0.directory.tagArray.array_0_0_1.array.array.array_14_ext.reg_RW0_addr;
    u_i0.directory.tagArray.array_0_0_1.array.array.array_14_ext.reg_RW0_ren = u_g0.directory.tagArray.array_0_0_1.array.array.array_14_ext.reg_RW0_ren;
    force u_i0.directory.tagArray.array_0_0_1.u_core.rdataReg = u_g0.directory.tagArray.array_0_0_1.rdataReg;
    u_i0.directory.tagArray.array_0_1_0.array.array.array_14_ext.ram = u_g0.directory.tagArray.array_0_1_0.array.array.array_14_ext.ram;
    u_i0.directory.tagArray.array_0_1_0.array.array.array_14_ext.reg_RW0_addr = u_g0.directory.tagArray.array_0_1_0.array.array.array_14_ext.reg_RW0_addr;
    u_i0.directory.tagArray.array_0_1_0.array.array.array_14_ext.reg_RW0_ren = u_g0.directory.tagArray.array_0_1_0.array.array.array_14_ext.reg_RW0_ren;
    force u_i0.directory.tagArray.array_0_1_0.u_core.rdataReg = u_g0.directory.tagArray.array_0_1_0.rdataReg;
    u_i0.directory.tagArray.array_0_1_1.array.array.array_14_ext.ram = u_g0.directory.tagArray.array_0_1_1.array.array.array_14_ext.ram;
    u_i0.directory.tagArray.array_0_1_1.array.array.array_14_ext.reg_RW0_addr = u_g0.directory.tagArray.array_0_1_1.array.array.array_14_ext.reg_RW0_addr;
    u_i0.directory.tagArray.array_0_1_1.array.array.array_14_ext.reg_RW0_ren = u_g0.directory.tagArray.array_0_1_1.array.array.array_14_ext.reg_RW0_ren;
    force u_i0.directory.tagArray.array_0_1_1.u_core.rdataReg = u_g0.directory.tagArray.array_0_1_1.rdataReg;
    u_i0.directory.metaArray.array.array.array_15_ext.ram = u_g0.directory.metaArray.array.array.array_15_ext.ram;
    u_i0.directory.metaArray.array.array.array_15_ext.reg_RW0_addr = u_g0.directory.metaArray.array.array.array_15_ext.reg_RW0_addr;
    u_i0.directory.metaArray.array.array.array_15_ext.reg_RW0_ren = u_g0.directory.metaArray.array.array.array_15_ext.reg_RW0_ren;
    force u_i0.directory.metaArray.u_core.rdataReg = u_g0.directory.metaArray.rdataReg;
    u_i0.directory.replacer_sram_opt.array.array.array_16_ext.ram = u_g0.directory.replacer_sram_opt.array.array.array_16_ext.ram;
    u_i0.directory.replacer_sram_opt.array.array.array_16_ext.reg_RW0_addr = u_g0.directory.replacer_sram_opt.array.array.array_16_ext.reg_RW0_addr;
    u_i0.directory.replacer_sram_opt.array.array.array_16_ext.reg_RW0_ren = u_g0.directory.replacer_sram_opt.array.array.array_16_ext.reg_RW0_ren;
    force u_i0.directory.replacer_sram_opt.u_core.rdataReg = u_g0.directory.replacer_sram_opt.rdataReg;
    u_i0.directory.origin_bit_opt.array.array.array_17_ext.ram = u_g0.directory.origin_bit_opt.array.array.array_17_ext.ram;
    u_i0.directory.origin_bit_opt.array.array.array_17_ext.reg_RW0_addr = u_g0.directory.origin_bit_opt.array.array.array_17_ext.reg_RW0_addr;
    u_i0.directory.origin_bit_opt.array.array.array_17_ext.reg_RW0_ren = u_g0.directory.origin_bit_opt.array.array.array_17_ext.reg_RW0_ren;
    force u_i0.directory.origin_bit_opt.u_core.rdataReg = u_g0.directory.origin_bit_opt.rdataReg;
    u_i0.dataStorage.array.array_0_0_0.array.array.array_18_ext.ram = u_g0.dataStorage.array.array_0_0_0.array.array.array_18_ext.ram;
    u_i0.dataStorage.array.array_0_0_0.array.array.array_18_ext.reg_RW0_addr = u_g0.dataStorage.array.array_0_0_0.array.array.array_18_ext.reg_RW0_addr;
    u_i0.dataStorage.array.array_0_0_0.array.array.array_18_ext.reg_RW0_ren = u_g0.dataStorage.array.array_0_0_0.array.array.array_18_ext.reg_RW0_ren;
    force u_i0.dataStorage.array.array_0_0_0.u_core.rdataReg = u_g0.dataStorage.array.array_0_0_0.rdataReg;
    u_i0.dataStorage.array.array_0_0_1.array.array.array_18_ext.ram = u_g0.dataStorage.array.array_0_0_1.array.array.array_18_ext.ram;
    u_i0.dataStorage.array.array_0_0_1.array.array.array_18_ext.reg_RW0_addr = u_g0.dataStorage.array.array_0_0_1.array.array.array_18_ext.reg_RW0_addr;
    u_i0.dataStorage.array.array_0_0_1.array.array.array_18_ext.reg_RW0_ren = u_g0.dataStorage.array.array_0_0_1.array.array.array_18_ext.reg_RW0_ren;
    force u_i0.dataStorage.array.array_0_0_1.u_core.rdataReg = u_g0.dataStorage.array.array_0_0_1.rdataReg;
    u_i0.dataStorage.array.array_0_0_2.array.array.array_18_ext.ram = u_g0.dataStorage.array.array_0_0_2.array.array.array_18_ext.ram;
    u_i0.dataStorage.array.array_0_0_2.array.array.array_18_ext.reg_RW0_addr = u_g0.dataStorage.array.array_0_0_2.array.array.array_18_ext.reg_RW0_addr;
    u_i0.dataStorage.array.array_0_0_2.array.array.array_18_ext.reg_RW0_ren = u_g0.dataStorage.array.array_0_0_2.array.array.array_18_ext.reg_RW0_ren;
    force u_i0.dataStorage.array.array_0_0_2.u_core.rdataReg = u_g0.dataStorage.array.array_0_0_2.rdataReg;
    u_i0.dataStorage.array.array_0_0_3.array.array.array_18_ext.ram = u_g0.dataStorage.array.array_0_0_3.array.array.array_18_ext.ram;
    u_i0.dataStorage.array.array_0_0_3.array.array.array_18_ext.reg_RW0_addr = u_g0.dataStorage.array.array_0_0_3.array.array.array_18_ext.reg_RW0_addr;
    u_i0.dataStorage.array.array_0_0_3.array.array.array_18_ext.reg_RW0_ren = u_g0.dataStorage.array.array_0_0_3.array.array.array_18_ext.reg_RW0_ren;
    force u_i0.dataStorage.array.array_0_0_3.u_core.rdataReg = u_g0.dataStorage.array.array_0_0_3.rdataReg;
    force u_i0.dataStorage.u_core.error_REG = u_g0.dataStorage.error_REG;
    force u_i0.dataStorage.u_core.error_REG_1 = u_g0.dataStorage.error_REG_1;
    force u_i0.mbistPl.u_core.g_node_return.pipelineDataOutReg = u_g0.mbistPl.pipelineDataOutReg;
    u_i0.u_core.txreq.u_core.queue.ram_ext.Memory = u_g0.txreq.queue.ram_ext.Memory;
    u_i0.u_core.txrsp.u_core.queue.ram_ext.Memory = u_g0.txrsp.queue.ram_ext.Memory;
    force u_i0.u_core.io_error_bits_REG_valid = u_g0.io_error_bits_REG_valid;
    force u_i0.u_core.io_error_bits_REG_address = u_g0.io_error_bits_REG_address;
    force u_i0.u_core.io_perf_0_value_REG = u_g0.io_perf_0_value_REG;
    force u_i0.u_core.io_perf_0_value_REG_1 = u_g0.io_perf_0_value_REG_1;
    force u_i0.u_core.io_perf_1_value_REG = u_g0.io_perf_1_value_REG;
    force u_i0.u_core.io_perf_1_value_REG_1 = u_g0.io_perf_1_value_REG_1;
    force u_i0.u_core.io_perf_3_value_REG = u_g0.io_perf_3_value_REG;
    force u_i0.u_core.io_perf_3_value_REG_1 = u_g0.io_perf_3_value_REG_1;
    force u_i0.u_core.io_perf_4_value_REG = u_g0.io_perf_4_value_REG;
    force u_i0.u_core.io_perf_4_value_REG_1 = u_g0.io_perf_4_value_REG_1;
    force u_i0.u_core.io_perf_5_value_REG = u_g0.io_perf_5_value_REG;
    force u_i0.u_core.io_perf_5_value_REG_1 = u_g0.io_perf_5_value_REG_1;
    force u_i0.u_core.io_perf_6_value_REG = u_g0.io_perf_6_value_REG;
    force u_i0.u_core.io_perf_6_value_REG_1 = u_g0.io_perf_6_value_REG_1;
    force u_i0.u_core.io_perf_7_value_REG = u_g0.io_perf_7_value_REG;
    force u_i0.u_core.io_perf_7_value_REG_1 = u_g0.io_perf_7_value_REG_1;
    force u_i0.u_core.io_perf_8_value_REG = u_g0.io_perf_8_value_REG;
    force u_i0.u_core.io_perf_8_value_REG_1 = u_g0.io_perf_8_value_REG_1;
    force u_i0.u_core.io_perf_9_value_REG = u_g0.io_perf_9_value_REG;
    force u_i0.u_core.io_perf_9_value_REG_1 = u_g0.io_perf_9_value_REG_1;
    force u_i0.u_core.io_perf_10_value_REG = u_g0.io_perf_10_value_REG;
    force u_i0.u_core.io_perf_10_value_REG_1 = u_g0.io_perf_10_value_REG_1;
    force u_i0.u_core.io_perf_11_value_REG = u_g0.io_perf_11_value_REG;
    force u_i0.u_core.io_perf_11_value_REG_1 = u_g0.io_perf_11_value_REG_1;
    force u_i0.u_core.io_perf_12_value_REG = u_g0.io_perf_12_value_REG;
    force u_i0.u_core.io_perf_12_value_REG_1 = u_g0.io_perf_12_value_REG_1;
    force u_i0.u_core.io_perf_13_value_REG = u_g0.io_perf_13_value_REG;
    force u_i0.u_core.io_perf_13_value_REG_1 = u_g0.io_perf_13_value_REG_1;
    force u_i0.u_core.io_perf_14_value_REG = u_g0.io_perf_14_value_REG;
    force u_i0.u_core.io_perf_14_value_REG_1 = u_g0.io_perf_14_value_REG_1;
    force u_i0.u_core.io_perf_15_value_REG = u_g0.io_perf_15_value_REG;
    force u_i0.u_core.io_perf_15_value_REG_1 = u_g0.io_perf_15_value_REG_1;
    force u_i0.u_core.io_perf_16_value_REG = u_g0.io_perf_16_value_REG;
    force u_i0.u_core.io_perf_16_value_REG_1 = u_g0.io_perf_16_value_REG_1;
    force u_i1.u_core.mshrCtl.u_core.mshrs[0].entry.u_core.tgtid_rcompack = u_g1.mshrCtl.mshrs_0.tgtid_rcompack;
    force u_i1.u_core.mshrCtl.u_core.mshrs[0].entry.u_core.txnid_rcompack = u_g1.mshrCtl.mshrs_0.txnid_rcompack;
    force u_i1.u_core.mshrCtl.u_core.mshrs[0].entry.u_core.tgtid_wcompack = u_g1.mshrCtl.mshrs_0.tgtid_wcompack;
    force u_i1.u_core.mshrCtl.u_core.mshrs[0].entry.u_core.txnid_wcompack = u_g1.mshrCtl.mshrs_0.txnid_wcompack;
    force u_i1.u_core.mshrCtl.u_core.mshrs[0].entry.u_core.srcid_retryack = u_g1.mshrCtl.mshrs_0.srcid_retryack;
    force u_i1.u_core.mshrCtl.u_core.mshrs[0].entry.u_core.acquire_ts = u_g1.mshrCtl.mshrs_0.acquire_ts;
    force u_i1.u_core.mshrCtl.u_core.mshrs[0].entry.u_core.release_ts = u_g1.mshrCtl.mshrs_0.release_ts;
    force u_i1.u_core.mshrCtl.u_core.mshrs[0].entry.u_core.acquire_period_valid_REG = u_g1.mshrCtl.mshrs_0.acquire_period_valid_REG;
    force u_i1.u_core.mshrCtl.u_core.mshrs[0].entry.u_core.release_period_valid_REG = u_g1.mshrCtl.mshrs_0.release_period_valid_REG;
    force u_i1.u_core.mshrCtl.u_core.mshrs[0].entry.u_core.REG = u_g1.mshrCtl.mshrs_0.REG;
    force u_i1.u_core.mshrCtl.u_core.mshrs[0].entry.u_core.REG_1 = u_g1.mshrCtl.mshrs_0.REG_1;
    force u_i1.u_core.mshrCtl.u_core.mshrs[0].entry.u_core.REG_2 = u_g1.mshrCtl.mshrs_0.REG_2;
    force u_i1.u_core.mshrCtl.u_core.mshrs[0].entry.u_core.REG_3 = u_g1.mshrCtl.mshrs_0.REG_3;
    force u_i1.u_core.mshrCtl.u_core.mshrs[1].entry.u_core.tgtid_rcompack = u_g1.mshrCtl.mshrs_1.tgtid_rcompack;
    force u_i1.u_core.mshrCtl.u_core.mshrs[1].entry.u_core.txnid_rcompack = u_g1.mshrCtl.mshrs_1.txnid_rcompack;
    force u_i1.u_core.mshrCtl.u_core.mshrs[1].entry.u_core.tgtid_wcompack = u_g1.mshrCtl.mshrs_1.tgtid_wcompack;
    force u_i1.u_core.mshrCtl.u_core.mshrs[1].entry.u_core.txnid_wcompack = u_g1.mshrCtl.mshrs_1.txnid_wcompack;
    force u_i1.u_core.mshrCtl.u_core.mshrs[1].entry.u_core.srcid_retryack = u_g1.mshrCtl.mshrs_1.srcid_retryack;
    force u_i1.u_core.mshrCtl.u_core.mshrs[1].entry.u_core.acquire_ts = u_g1.mshrCtl.mshrs_1.acquire_ts;
    force u_i1.u_core.mshrCtl.u_core.mshrs[1].entry.u_core.release_ts = u_g1.mshrCtl.mshrs_1.release_ts;
    force u_i1.u_core.mshrCtl.u_core.mshrs[1].entry.u_core.acquire_period_valid_REG = u_g1.mshrCtl.mshrs_1.acquire_period_valid_REG;
    force u_i1.u_core.mshrCtl.u_core.mshrs[1].entry.u_core.release_period_valid_REG = u_g1.mshrCtl.mshrs_1.release_period_valid_REG;
    force u_i1.u_core.mshrCtl.u_core.mshrs[1].entry.u_core.REG = u_g1.mshrCtl.mshrs_1.REG;
    force u_i1.u_core.mshrCtl.u_core.mshrs[1].entry.u_core.REG_1 = u_g1.mshrCtl.mshrs_1.REG_1;
    force u_i1.u_core.mshrCtl.u_core.mshrs[1].entry.u_core.REG_2 = u_g1.mshrCtl.mshrs_1.REG_2;
    force u_i1.u_core.mshrCtl.u_core.mshrs[1].entry.u_core.REG_3 = u_g1.mshrCtl.mshrs_1.REG_3;
    force u_i1.u_core.mshrCtl.u_core.mshrs[2].entry.u_core.tgtid_rcompack = u_g1.mshrCtl.mshrs_2.tgtid_rcompack;
    force u_i1.u_core.mshrCtl.u_core.mshrs[2].entry.u_core.txnid_rcompack = u_g1.mshrCtl.mshrs_2.txnid_rcompack;
    force u_i1.u_core.mshrCtl.u_core.mshrs[2].entry.u_core.tgtid_wcompack = u_g1.mshrCtl.mshrs_2.tgtid_wcompack;
    force u_i1.u_core.mshrCtl.u_core.mshrs[2].entry.u_core.txnid_wcompack = u_g1.mshrCtl.mshrs_2.txnid_wcompack;
    force u_i1.u_core.mshrCtl.u_core.mshrs[2].entry.u_core.srcid_retryack = u_g1.mshrCtl.mshrs_2.srcid_retryack;
    force u_i1.u_core.mshrCtl.u_core.mshrs[2].entry.u_core.acquire_ts = u_g1.mshrCtl.mshrs_2.acquire_ts;
    force u_i1.u_core.mshrCtl.u_core.mshrs[2].entry.u_core.release_ts = u_g1.mshrCtl.mshrs_2.release_ts;
    force u_i1.u_core.mshrCtl.u_core.mshrs[2].entry.u_core.acquire_period_valid_REG = u_g1.mshrCtl.mshrs_2.acquire_period_valid_REG;
    force u_i1.u_core.mshrCtl.u_core.mshrs[2].entry.u_core.release_period_valid_REG = u_g1.mshrCtl.mshrs_2.release_period_valid_REG;
    force u_i1.u_core.mshrCtl.u_core.mshrs[2].entry.u_core.REG = u_g1.mshrCtl.mshrs_2.REG;
    force u_i1.u_core.mshrCtl.u_core.mshrs[2].entry.u_core.REG_1 = u_g1.mshrCtl.mshrs_2.REG_1;
    force u_i1.u_core.mshrCtl.u_core.mshrs[2].entry.u_core.REG_2 = u_g1.mshrCtl.mshrs_2.REG_2;
    force u_i1.u_core.mshrCtl.u_core.mshrs[2].entry.u_core.REG_3 = u_g1.mshrCtl.mshrs_2.REG_3;
    force u_i1.u_core.mshrCtl.u_core.mshrs[3].entry.u_core.tgtid_rcompack = u_g1.mshrCtl.mshrs_3.tgtid_rcompack;
    force u_i1.u_core.mshrCtl.u_core.mshrs[3].entry.u_core.txnid_rcompack = u_g1.mshrCtl.mshrs_3.txnid_rcompack;
    force u_i1.u_core.mshrCtl.u_core.mshrs[3].entry.u_core.tgtid_wcompack = u_g1.mshrCtl.mshrs_3.tgtid_wcompack;
    force u_i1.u_core.mshrCtl.u_core.mshrs[3].entry.u_core.txnid_wcompack = u_g1.mshrCtl.mshrs_3.txnid_wcompack;
    force u_i1.u_core.mshrCtl.u_core.mshrs[3].entry.u_core.srcid_retryack = u_g1.mshrCtl.mshrs_3.srcid_retryack;
    force u_i1.u_core.mshrCtl.u_core.mshrs[3].entry.u_core.acquire_ts = u_g1.mshrCtl.mshrs_3.acquire_ts;
    force u_i1.u_core.mshrCtl.u_core.mshrs[3].entry.u_core.release_ts = u_g1.mshrCtl.mshrs_3.release_ts;
    force u_i1.u_core.mshrCtl.u_core.mshrs[3].entry.u_core.acquire_period_valid_REG = u_g1.mshrCtl.mshrs_3.acquire_period_valid_REG;
    force u_i1.u_core.mshrCtl.u_core.mshrs[3].entry.u_core.release_period_valid_REG = u_g1.mshrCtl.mshrs_3.release_period_valid_REG;
    force u_i1.u_core.mshrCtl.u_core.mshrs[3].entry.u_core.REG = u_g1.mshrCtl.mshrs_3.REG;
    force u_i1.u_core.mshrCtl.u_core.mshrs[3].entry.u_core.REG_1 = u_g1.mshrCtl.mshrs_3.REG_1;
    force u_i1.u_core.mshrCtl.u_core.mshrs[3].entry.u_core.REG_2 = u_g1.mshrCtl.mshrs_3.REG_2;
    force u_i1.u_core.mshrCtl.u_core.mshrs[3].entry.u_core.REG_3 = u_g1.mshrCtl.mshrs_3.REG_3;
    force u_i1.u_core.mshrCtl.u_core.mshrs[4].entry.u_core.tgtid_rcompack = u_g1.mshrCtl.mshrs_4.tgtid_rcompack;
    force u_i1.u_core.mshrCtl.u_core.mshrs[4].entry.u_core.txnid_rcompack = u_g1.mshrCtl.mshrs_4.txnid_rcompack;
    force u_i1.u_core.mshrCtl.u_core.mshrs[4].entry.u_core.tgtid_wcompack = u_g1.mshrCtl.mshrs_4.tgtid_wcompack;
    force u_i1.u_core.mshrCtl.u_core.mshrs[4].entry.u_core.txnid_wcompack = u_g1.mshrCtl.mshrs_4.txnid_wcompack;
    force u_i1.u_core.mshrCtl.u_core.mshrs[4].entry.u_core.srcid_retryack = u_g1.mshrCtl.mshrs_4.srcid_retryack;
    force u_i1.u_core.mshrCtl.u_core.mshrs[4].entry.u_core.acquire_ts = u_g1.mshrCtl.mshrs_4.acquire_ts;
    force u_i1.u_core.mshrCtl.u_core.mshrs[4].entry.u_core.release_ts = u_g1.mshrCtl.mshrs_4.release_ts;
    force u_i1.u_core.mshrCtl.u_core.mshrs[4].entry.u_core.acquire_period_valid_REG = u_g1.mshrCtl.mshrs_4.acquire_period_valid_REG;
    force u_i1.u_core.mshrCtl.u_core.mshrs[4].entry.u_core.release_period_valid_REG = u_g1.mshrCtl.mshrs_4.release_period_valid_REG;
    force u_i1.u_core.mshrCtl.u_core.mshrs[4].entry.u_core.REG = u_g1.mshrCtl.mshrs_4.REG;
    force u_i1.u_core.mshrCtl.u_core.mshrs[4].entry.u_core.REG_1 = u_g1.mshrCtl.mshrs_4.REG_1;
    force u_i1.u_core.mshrCtl.u_core.mshrs[4].entry.u_core.REG_2 = u_g1.mshrCtl.mshrs_4.REG_2;
    force u_i1.u_core.mshrCtl.u_core.mshrs[4].entry.u_core.REG_3 = u_g1.mshrCtl.mshrs_4.REG_3;
    force u_i1.u_core.mshrCtl.u_core.mshrs[5].entry.u_core.tgtid_rcompack = u_g1.mshrCtl.mshrs_5.tgtid_rcompack;
    force u_i1.u_core.mshrCtl.u_core.mshrs[5].entry.u_core.txnid_rcompack = u_g1.mshrCtl.mshrs_5.txnid_rcompack;
    force u_i1.u_core.mshrCtl.u_core.mshrs[5].entry.u_core.tgtid_wcompack = u_g1.mshrCtl.mshrs_5.tgtid_wcompack;
    force u_i1.u_core.mshrCtl.u_core.mshrs[5].entry.u_core.txnid_wcompack = u_g1.mshrCtl.mshrs_5.txnid_wcompack;
    force u_i1.u_core.mshrCtl.u_core.mshrs[5].entry.u_core.srcid_retryack = u_g1.mshrCtl.mshrs_5.srcid_retryack;
    force u_i1.u_core.mshrCtl.u_core.mshrs[5].entry.u_core.acquire_ts = u_g1.mshrCtl.mshrs_5.acquire_ts;
    force u_i1.u_core.mshrCtl.u_core.mshrs[5].entry.u_core.release_ts = u_g1.mshrCtl.mshrs_5.release_ts;
    force u_i1.u_core.mshrCtl.u_core.mshrs[5].entry.u_core.acquire_period_valid_REG = u_g1.mshrCtl.mshrs_5.acquire_period_valid_REG;
    force u_i1.u_core.mshrCtl.u_core.mshrs[5].entry.u_core.release_period_valid_REG = u_g1.mshrCtl.mshrs_5.release_period_valid_REG;
    force u_i1.u_core.mshrCtl.u_core.mshrs[5].entry.u_core.REG = u_g1.mshrCtl.mshrs_5.REG;
    force u_i1.u_core.mshrCtl.u_core.mshrs[5].entry.u_core.REG_1 = u_g1.mshrCtl.mshrs_5.REG_1;
    force u_i1.u_core.mshrCtl.u_core.mshrs[5].entry.u_core.REG_2 = u_g1.mshrCtl.mshrs_5.REG_2;
    force u_i1.u_core.mshrCtl.u_core.mshrs[5].entry.u_core.REG_3 = u_g1.mshrCtl.mshrs_5.REG_3;
    force u_i1.u_core.mshrCtl.u_core.mshrs[6].entry.u_core.tgtid_rcompack = u_g1.mshrCtl.mshrs_6.tgtid_rcompack;
    force u_i1.u_core.mshrCtl.u_core.mshrs[6].entry.u_core.txnid_rcompack = u_g1.mshrCtl.mshrs_6.txnid_rcompack;
    force u_i1.u_core.mshrCtl.u_core.mshrs[6].entry.u_core.tgtid_wcompack = u_g1.mshrCtl.mshrs_6.tgtid_wcompack;
    force u_i1.u_core.mshrCtl.u_core.mshrs[6].entry.u_core.txnid_wcompack = u_g1.mshrCtl.mshrs_6.txnid_wcompack;
    force u_i1.u_core.mshrCtl.u_core.mshrs[6].entry.u_core.srcid_retryack = u_g1.mshrCtl.mshrs_6.srcid_retryack;
    force u_i1.u_core.mshrCtl.u_core.mshrs[6].entry.u_core.acquire_ts = u_g1.mshrCtl.mshrs_6.acquire_ts;
    force u_i1.u_core.mshrCtl.u_core.mshrs[6].entry.u_core.release_ts = u_g1.mshrCtl.mshrs_6.release_ts;
    force u_i1.u_core.mshrCtl.u_core.mshrs[6].entry.u_core.acquire_period_valid_REG = u_g1.mshrCtl.mshrs_6.acquire_period_valid_REG;
    force u_i1.u_core.mshrCtl.u_core.mshrs[6].entry.u_core.release_period_valid_REG = u_g1.mshrCtl.mshrs_6.release_period_valid_REG;
    force u_i1.u_core.mshrCtl.u_core.mshrs[6].entry.u_core.REG = u_g1.mshrCtl.mshrs_6.REG;
    force u_i1.u_core.mshrCtl.u_core.mshrs[6].entry.u_core.REG_1 = u_g1.mshrCtl.mshrs_6.REG_1;
    force u_i1.u_core.mshrCtl.u_core.mshrs[6].entry.u_core.REG_2 = u_g1.mshrCtl.mshrs_6.REG_2;
    force u_i1.u_core.mshrCtl.u_core.mshrs[6].entry.u_core.REG_3 = u_g1.mshrCtl.mshrs_6.REG_3;
    force u_i1.u_core.mshrCtl.u_core.mshrs[7].entry.u_core.tgtid_rcompack = u_g1.mshrCtl.mshrs_7.tgtid_rcompack;
    force u_i1.u_core.mshrCtl.u_core.mshrs[7].entry.u_core.txnid_rcompack = u_g1.mshrCtl.mshrs_7.txnid_rcompack;
    force u_i1.u_core.mshrCtl.u_core.mshrs[7].entry.u_core.tgtid_wcompack = u_g1.mshrCtl.mshrs_7.tgtid_wcompack;
    force u_i1.u_core.mshrCtl.u_core.mshrs[7].entry.u_core.txnid_wcompack = u_g1.mshrCtl.mshrs_7.txnid_wcompack;
    force u_i1.u_core.mshrCtl.u_core.mshrs[7].entry.u_core.srcid_retryack = u_g1.mshrCtl.mshrs_7.srcid_retryack;
    force u_i1.u_core.mshrCtl.u_core.mshrs[7].entry.u_core.acquire_ts = u_g1.mshrCtl.mshrs_7.acquire_ts;
    force u_i1.u_core.mshrCtl.u_core.mshrs[7].entry.u_core.release_ts = u_g1.mshrCtl.mshrs_7.release_ts;
    force u_i1.u_core.mshrCtl.u_core.mshrs[7].entry.u_core.acquire_period_valid_REG = u_g1.mshrCtl.mshrs_7.acquire_period_valid_REG;
    force u_i1.u_core.mshrCtl.u_core.mshrs[7].entry.u_core.release_period_valid_REG = u_g1.mshrCtl.mshrs_7.release_period_valid_REG;
    force u_i1.u_core.mshrCtl.u_core.mshrs[7].entry.u_core.REG = u_g1.mshrCtl.mshrs_7.REG;
    force u_i1.u_core.mshrCtl.u_core.mshrs[7].entry.u_core.REG_1 = u_g1.mshrCtl.mshrs_7.REG_1;
    force u_i1.u_core.mshrCtl.u_core.mshrs[7].entry.u_core.REG_2 = u_g1.mshrCtl.mshrs_7.REG_2;
    force u_i1.u_core.mshrCtl.u_core.mshrs[7].entry.u_core.REG_3 = u_g1.mshrCtl.mshrs_7.REG_3;
    force u_i1.u_core.mshrCtl.u_core.mshrs[8].entry.u_core.tgtid_rcompack = u_g1.mshrCtl.mshrs_8.tgtid_rcompack;
    force u_i1.u_core.mshrCtl.u_core.mshrs[8].entry.u_core.txnid_rcompack = u_g1.mshrCtl.mshrs_8.txnid_rcompack;
    force u_i1.u_core.mshrCtl.u_core.mshrs[8].entry.u_core.tgtid_wcompack = u_g1.mshrCtl.mshrs_8.tgtid_wcompack;
    force u_i1.u_core.mshrCtl.u_core.mshrs[8].entry.u_core.txnid_wcompack = u_g1.mshrCtl.mshrs_8.txnid_wcompack;
    force u_i1.u_core.mshrCtl.u_core.mshrs[8].entry.u_core.srcid_retryack = u_g1.mshrCtl.mshrs_8.srcid_retryack;
    force u_i1.u_core.mshrCtl.u_core.mshrs[8].entry.u_core.acquire_ts = u_g1.mshrCtl.mshrs_8.acquire_ts;
    force u_i1.u_core.mshrCtl.u_core.mshrs[8].entry.u_core.release_ts = u_g1.mshrCtl.mshrs_8.release_ts;
    force u_i1.u_core.mshrCtl.u_core.mshrs[8].entry.u_core.acquire_period_valid_REG = u_g1.mshrCtl.mshrs_8.acquire_period_valid_REG;
    force u_i1.u_core.mshrCtl.u_core.mshrs[8].entry.u_core.release_period_valid_REG = u_g1.mshrCtl.mshrs_8.release_period_valid_REG;
    force u_i1.u_core.mshrCtl.u_core.mshrs[8].entry.u_core.REG = u_g1.mshrCtl.mshrs_8.REG;
    force u_i1.u_core.mshrCtl.u_core.mshrs[8].entry.u_core.REG_1 = u_g1.mshrCtl.mshrs_8.REG_1;
    force u_i1.u_core.mshrCtl.u_core.mshrs[8].entry.u_core.REG_2 = u_g1.mshrCtl.mshrs_8.REG_2;
    force u_i1.u_core.mshrCtl.u_core.mshrs[8].entry.u_core.REG_3 = u_g1.mshrCtl.mshrs_8.REG_3;
    force u_i1.u_core.mshrCtl.u_core.mshrs[9].entry.u_core.tgtid_rcompack = u_g1.mshrCtl.mshrs_9.tgtid_rcompack;
    force u_i1.u_core.mshrCtl.u_core.mshrs[9].entry.u_core.txnid_rcompack = u_g1.mshrCtl.mshrs_9.txnid_rcompack;
    force u_i1.u_core.mshrCtl.u_core.mshrs[9].entry.u_core.tgtid_wcompack = u_g1.mshrCtl.mshrs_9.tgtid_wcompack;
    force u_i1.u_core.mshrCtl.u_core.mshrs[9].entry.u_core.txnid_wcompack = u_g1.mshrCtl.mshrs_9.txnid_wcompack;
    force u_i1.u_core.mshrCtl.u_core.mshrs[9].entry.u_core.srcid_retryack = u_g1.mshrCtl.mshrs_9.srcid_retryack;
    force u_i1.u_core.mshrCtl.u_core.mshrs[9].entry.u_core.acquire_ts = u_g1.mshrCtl.mshrs_9.acquire_ts;
    force u_i1.u_core.mshrCtl.u_core.mshrs[9].entry.u_core.release_ts = u_g1.mshrCtl.mshrs_9.release_ts;
    force u_i1.u_core.mshrCtl.u_core.mshrs[9].entry.u_core.acquire_period_valid_REG = u_g1.mshrCtl.mshrs_9.acquire_period_valid_REG;
    force u_i1.u_core.mshrCtl.u_core.mshrs[9].entry.u_core.release_period_valid_REG = u_g1.mshrCtl.mshrs_9.release_period_valid_REG;
    force u_i1.u_core.mshrCtl.u_core.mshrs[9].entry.u_core.REG = u_g1.mshrCtl.mshrs_9.REG;
    force u_i1.u_core.mshrCtl.u_core.mshrs[9].entry.u_core.REG_1 = u_g1.mshrCtl.mshrs_9.REG_1;
    force u_i1.u_core.mshrCtl.u_core.mshrs[9].entry.u_core.REG_2 = u_g1.mshrCtl.mshrs_9.REG_2;
    force u_i1.u_core.mshrCtl.u_core.mshrs[9].entry.u_core.REG_3 = u_g1.mshrCtl.mshrs_9.REG_3;
    force u_i1.u_core.mshrCtl.u_core.mshrs[10].entry.u_core.tgtid_rcompack = u_g1.mshrCtl.mshrs_10.tgtid_rcompack;
    force u_i1.u_core.mshrCtl.u_core.mshrs[10].entry.u_core.txnid_rcompack = u_g1.mshrCtl.mshrs_10.txnid_rcompack;
    force u_i1.u_core.mshrCtl.u_core.mshrs[10].entry.u_core.tgtid_wcompack = u_g1.mshrCtl.mshrs_10.tgtid_wcompack;
    force u_i1.u_core.mshrCtl.u_core.mshrs[10].entry.u_core.txnid_wcompack = u_g1.mshrCtl.mshrs_10.txnid_wcompack;
    force u_i1.u_core.mshrCtl.u_core.mshrs[10].entry.u_core.srcid_retryack = u_g1.mshrCtl.mshrs_10.srcid_retryack;
    force u_i1.u_core.mshrCtl.u_core.mshrs[10].entry.u_core.acquire_ts = u_g1.mshrCtl.mshrs_10.acquire_ts;
    force u_i1.u_core.mshrCtl.u_core.mshrs[10].entry.u_core.release_ts = u_g1.mshrCtl.mshrs_10.release_ts;
    force u_i1.u_core.mshrCtl.u_core.mshrs[10].entry.u_core.acquire_period_valid_REG = u_g1.mshrCtl.mshrs_10.acquire_period_valid_REG;
    force u_i1.u_core.mshrCtl.u_core.mshrs[10].entry.u_core.release_period_valid_REG = u_g1.mshrCtl.mshrs_10.release_period_valid_REG;
    force u_i1.u_core.mshrCtl.u_core.mshrs[10].entry.u_core.REG = u_g1.mshrCtl.mshrs_10.REG;
    force u_i1.u_core.mshrCtl.u_core.mshrs[10].entry.u_core.REG_1 = u_g1.mshrCtl.mshrs_10.REG_1;
    force u_i1.u_core.mshrCtl.u_core.mshrs[10].entry.u_core.REG_2 = u_g1.mshrCtl.mshrs_10.REG_2;
    force u_i1.u_core.mshrCtl.u_core.mshrs[10].entry.u_core.REG_3 = u_g1.mshrCtl.mshrs_10.REG_3;
    force u_i1.u_core.mshrCtl.u_core.mshrs[11].entry.u_core.tgtid_rcompack = u_g1.mshrCtl.mshrs_11.tgtid_rcompack;
    force u_i1.u_core.mshrCtl.u_core.mshrs[11].entry.u_core.txnid_rcompack = u_g1.mshrCtl.mshrs_11.txnid_rcompack;
    force u_i1.u_core.mshrCtl.u_core.mshrs[11].entry.u_core.tgtid_wcompack = u_g1.mshrCtl.mshrs_11.tgtid_wcompack;
    force u_i1.u_core.mshrCtl.u_core.mshrs[11].entry.u_core.txnid_wcompack = u_g1.mshrCtl.mshrs_11.txnid_wcompack;
    force u_i1.u_core.mshrCtl.u_core.mshrs[11].entry.u_core.srcid_retryack = u_g1.mshrCtl.mshrs_11.srcid_retryack;
    force u_i1.u_core.mshrCtl.u_core.mshrs[11].entry.u_core.acquire_ts = u_g1.mshrCtl.mshrs_11.acquire_ts;
    force u_i1.u_core.mshrCtl.u_core.mshrs[11].entry.u_core.release_ts = u_g1.mshrCtl.mshrs_11.release_ts;
    force u_i1.u_core.mshrCtl.u_core.mshrs[11].entry.u_core.acquire_period_valid_REG = u_g1.mshrCtl.mshrs_11.acquire_period_valid_REG;
    force u_i1.u_core.mshrCtl.u_core.mshrs[11].entry.u_core.release_period_valid_REG = u_g1.mshrCtl.mshrs_11.release_period_valid_REG;
    force u_i1.u_core.mshrCtl.u_core.mshrs[11].entry.u_core.REG = u_g1.mshrCtl.mshrs_11.REG;
    force u_i1.u_core.mshrCtl.u_core.mshrs[11].entry.u_core.REG_1 = u_g1.mshrCtl.mshrs_11.REG_1;
    force u_i1.u_core.mshrCtl.u_core.mshrs[11].entry.u_core.REG_2 = u_g1.mshrCtl.mshrs_11.REG_2;
    force u_i1.u_core.mshrCtl.u_core.mshrs[11].entry.u_core.REG_3 = u_g1.mshrCtl.mshrs_11.REG_3;
    force u_i1.u_core.mshrCtl.u_core.mshrs[12].entry.u_core.tgtid_rcompack = u_g1.mshrCtl.mshrs_12.tgtid_rcompack;
    force u_i1.u_core.mshrCtl.u_core.mshrs[12].entry.u_core.txnid_rcompack = u_g1.mshrCtl.mshrs_12.txnid_rcompack;
    force u_i1.u_core.mshrCtl.u_core.mshrs[12].entry.u_core.tgtid_wcompack = u_g1.mshrCtl.mshrs_12.tgtid_wcompack;
    force u_i1.u_core.mshrCtl.u_core.mshrs[12].entry.u_core.txnid_wcompack = u_g1.mshrCtl.mshrs_12.txnid_wcompack;
    force u_i1.u_core.mshrCtl.u_core.mshrs[12].entry.u_core.srcid_retryack = u_g1.mshrCtl.mshrs_12.srcid_retryack;
    force u_i1.u_core.mshrCtl.u_core.mshrs[12].entry.u_core.acquire_ts = u_g1.mshrCtl.mshrs_12.acquire_ts;
    force u_i1.u_core.mshrCtl.u_core.mshrs[12].entry.u_core.release_ts = u_g1.mshrCtl.mshrs_12.release_ts;
    force u_i1.u_core.mshrCtl.u_core.mshrs[12].entry.u_core.acquire_period_valid_REG = u_g1.mshrCtl.mshrs_12.acquire_period_valid_REG;
    force u_i1.u_core.mshrCtl.u_core.mshrs[12].entry.u_core.release_period_valid_REG = u_g1.mshrCtl.mshrs_12.release_period_valid_REG;
    force u_i1.u_core.mshrCtl.u_core.mshrs[12].entry.u_core.REG = u_g1.mshrCtl.mshrs_12.REG;
    force u_i1.u_core.mshrCtl.u_core.mshrs[12].entry.u_core.REG_1 = u_g1.mshrCtl.mshrs_12.REG_1;
    force u_i1.u_core.mshrCtl.u_core.mshrs[12].entry.u_core.REG_2 = u_g1.mshrCtl.mshrs_12.REG_2;
    force u_i1.u_core.mshrCtl.u_core.mshrs[12].entry.u_core.REG_3 = u_g1.mshrCtl.mshrs_12.REG_3;
    force u_i1.u_core.mshrCtl.u_core.mshrs[13].entry.u_core.tgtid_rcompack = u_g1.mshrCtl.mshrs_13.tgtid_rcompack;
    force u_i1.u_core.mshrCtl.u_core.mshrs[13].entry.u_core.txnid_rcompack = u_g1.mshrCtl.mshrs_13.txnid_rcompack;
    force u_i1.u_core.mshrCtl.u_core.mshrs[13].entry.u_core.tgtid_wcompack = u_g1.mshrCtl.mshrs_13.tgtid_wcompack;
    force u_i1.u_core.mshrCtl.u_core.mshrs[13].entry.u_core.txnid_wcompack = u_g1.mshrCtl.mshrs_13.txnid_wcompack;
    force u_i1.u_core.mshrCtl.u_core.mshrs[13].entry.u_core.srcid_retryack = u_g1.mshrCtl.mshrs_13.srcid_retryack;
    force u_i1.u_core.mshrCtl.u_core.mshrs[13].entry.u_core.acquire_ts = u_g1.mshrCtl.mshrs_13.acquire_ts;
    force u_i1.u_core.mshrCtl.u_core.mshrs[13].entry.u_core.release_ts = u_g1.mshrCtl.mshrs_13.release_ts;
    force u_i1.u_core.mshrCtl.u_core.mshrs[13].entry.u_core.acquire_period_valid_REG = u_g1.mshrCtl.mshrs_13.acquire_period_valid_REG;
    force u_i1.u_core.mshrCtl.u_core.mshrs[13].entry.u_core.release_period_valid_REG = u_g1.mshrCtl.mshrs_13.release_period_valid_REG;
    force u_i1.u_core.mshrCtl.u_core.mshrs[13].entry.u_core.REG = u_g1.mshrCtl.mshrs_13.REG;
    force u_i1.u_core.mshrCtl.u_core.mshrs[13].entry.u_core.REG_1 = u_g1.mshrCtl.mshrs_13.REG_1;
    force u_i1.u_core.mshrCtl.u_core.mshrs[13].entry.u_core.REG_2 = u_g1.mshrCtl.mshrs_13.REG_2;
    force u_i1.u_core.mshrCtl.u_core.mshrs[13].entry.u_core.REG_3 = u_g1.mshrCtl.mshrs_13.REG_3;
    force u_i1.u_core.mshrCtl.u_core.mshrs[14].entry.u_core.tgtid_rcompack = u_g1.mshrCtl.mshrs_14.tgtid_rcompack;
    force u_i1.u_core.mshrCtl.u_core.mshrs[14].entry.u_core.txnid_rcompack = u_g1.mshrCtl.mshrs_14.txnid_rcompack;
    force u_i1.u_core.mshrCtl.u_core.mshrs[14].entry.u_core.tgtid_wcompack = u_g1.mshrCtl.mshrs_14.tgtid_wcompack;
    force u_i1.u_core.mshrCtl.u_core.mshrs[14].entry.u_core.txnid_wcompack = u_g1.mshrCtl.mshrs_14.txnid_wcompack;
    force u_i1.u_core.mshrCtl.u_core.mshrs[14].entry.u_core.srcid_retryack = u_g1.mshrCtl.mshrs_14.srcid_retryack;
    force u_i1.u_core.mshrCtl.u_core.mshrs[14].entry.u_core.acquire_ts = u_g1.mshrCtl.mshrs_14.acquire_ts;
    force u_i1.u_core.mshrCtl.u_core.mshrs[14].entry.u_core.release_ts = u_g1.mshrCtl.mshrs_14.release_ts;
    force u_i1.u_core.mshrCtl.u_core.mshrs[14].entry.u_core.acquire_period_valid_REG = u_g1.mshrCtl.mshrs_14.acquire_period_valid_REG;
    force u_i1.u_core.mshrCtl.u_core.mshrs[14].entry.u_core.release_period_valid_REG = u_g1.mshrCtl.mshrs_14.release_period_valid_REG;
    force u_i1.u_core.mshrCtl.u_core.mshrs[14].entry.u_core.REG = u_g1.mshrCtl.mshrs_14.REG;
    force u_i1.u_core.mshrCtl.u_core.mshrs[14].entry.u_core.REG_1 = u_g1.mshrCtl.mshrs_14.REG_1;
    force u_i1.u_core.mshrCtl.u_core.mshrs[14].entry.u_core.REG_2 = u_g1.mshrCtl.mshrs_14.REG_2;
    force u_i1.u_core.mshrCtl.u_core.mshrs[14].entry.u_core.REG_3 = u_g1.mshrCtl.mshrs_14.REG_3;
    force u_i1.u_core.mshrCtl.u_core.mshrs[15].entry.u_core.tgtid_rcompack = u_g1.mshrCtl.mshrs_15.tgtid_rcompack;
    force u_i1.u_core.mshrCtl.u_core.mshrs[15].entry.u_core.txnid_rcompack = u_g1.mshrCtl.mshrs_15.txnid_rcompack;
    force u_i1.u_core.mshrCtl.u_core.mshrs[15].entry.u_core.tgtid_wcompack = u_g1.mshrCtl.mshrs_15.tgtid_wcompack;
    force u_i1.u_core.mshrCtl.u_core.mshrs[15].entry.u_core.txnid_wcompack = u_g1.mshrCtl.mshrs_15.txnid_wcompack;
    force u_i1.u_core.mshrCtl.u_core.mshrs[15].entry.u_core.srcid_retryack = u_g1.mshrCtl.mshrs_15.srcid_retryack;
    force u_i1.u_core.mshrCtl.u_core.mshrs[15].entry.u_core.acquire_ts = u_g1.mshrCtl.mshrs_15.acquire_ts;
    force u_i1.u_core.mshrCtl.u_core.mshrs[15].entry.u_core.release_ts = u_g1.mshrCtl.mshrs_15.release_ts;
    force u_i1.u_core.mshrCtl.u_core.mshrs[15].entry.u_core.acquire_period_valid_REG = u_g1.mshrCtl.mshrs_15.acquire_period_valid_REG;
    force u_i1.u_core.mshrCtl.u_core.mshrs[15].entry.u_core.release_period_valid_REG = u_g1.mshrCtl.mshrs_15.release_period_valid_REG;
    force u_i1.u_core.mshrCtl.u_core.mshrs[15].entry.u_core.REG = u_g1.mshrCtl.mshrs_15.REG;
    force u_i1.u_core.mshrCtl.u_core.mshrs[15].entry.u_core.REG_1 = u_g1.mshrCtl.mshrs_15.REG_1;
    force u_i1.u_core.mshrCtl.u_core.mshrs[15].entry.u_core.REG_2 = u_g1.mshrCtl.mshrs_15.REG_2;
    force u_i1.u_core.mshrCtl.u_core.mshrs[15].entry.u_core.REG_3 = u_g1.mshrCtl.mshrs_15.REG_3;
    force u_i1.u_core.mshrCtl.u_core.io_perf_0_value_REG = u_g1.mshrCtl.io_perf_0_value_REG;
    force u_i1.u_core.mshrCtl.u_core.io_perf_0_value_REG_1 = u_g1.mshrCtl.io_perf_0_value_REG_1;
    force u_i1.u_core.mshrCtl.u_core.io_perf_1_value_REG = u_g1.mshrCtl.io_perf_1_value_REG;
    force u_i1.u_core.mshrCtl.u_core.io_perf_1_value_REG_1 = u_g1.mshrCtl.io_perf_1_value_REG_1;
    force u_i1.u_core.mshrCtl.u_core.io_perf_3_value_REG = u_g1.mshrCtl.io_perf_3_value_REG;
    force u_i1.u_core.mshrCtl.u_core.io_perf_3_value_REG_1 = u_g1.mshrCtl.io_perf_3_value_REG_1;
    force u_i1.u_core.mshrCtl.u_core.REG = u_g1.mshrCtl.REG;
    force u_i1.u_core.mainPipe.u_core.data_s4 = u_g1.mainPipe.data_s4;
    force u_i1.u_core.mainPipe.u_core.data_s5 = u_g1.mainPipe.data_s5;
    force u_i1.u_core.mainPipe.u_core.s3DropValid_d1 = u_g1.mainPipe.REG;
    force u_i1.u_core.mainPipe.u_core.reqDrop_s3_d1 = u_g1.mainPipe.reqDropped_s5_REG;
    force u_i1.u_core.mainPipe.u_core.reqDrop_s3_d2 = u_g1.mainPipe.reqDropped_s5_REG_1;
    force u_i1.u_core.mainPipe.u_core.reqDrop_s4_d1 = u_g1.mainPipe.reqDropped_s5_REG_2;
    u_i1.u_core.mainPipe.customL1Hint.hintQueue.ram_ext.Memory = u_g1.mainPipe.customL1Hint.hintQueue.ram_ext.Memory;
    u_i1.u_core.mainPipe.customL1Hint.hint_s1Queue.ram_ext.Memory = u_g1.mainPipe.customL1Hint.hint_s1Queue.ram_ext.Memory;
    force u_i1.u_core.mainPipe.u_core.perf_d1[0] = u_g1.mainPipe.io_perf_0_value_REG;
    force u_i1.u_core.mainPipe.u_core.perf[0] = u_g1.mainPipe.io_perf_0_value_REG_1;
    force u_i1.u_core.mainPipe.u_core.perf_d1[1] = u_g1.mainPipe.io_perf_1_value_REG;
    force u_i1.u_core.mainPipe.u_core.perf[1] = u_g1.mainPipe.io_perf_1_value_REG_1;
    force u_i1.u_core.mainPipe.u_core.perf_d1[2] = u_g1.mainPipe.io_perf_2_value_REG;
    force u_i1.u_core.mainPipe.u_core.perf[2] = u_g1.mainPipe.io_perf_2_value_REG_1;
    force u_i1.u_core.mainPipe.u_core.perf_d1[3] = u_g1.mainPipe.io_perf_3_value_REG;
    force u_i1.u_core.mainPipe.u_core.perf[3] = u_g1.mainPipe.io_perf_3_value_REG_1;
    force u_i1.u_core.mainPipe.u_core.perf_d1[4] = u_g1.mainPipe.io_perf_4_value_REG;
    force u_i1.u_core.mainPipe.u_core.perf[4] = u_g1.mainPipe.io_perf_4_value_REG_1;
    force u_i1.u_core.mainPipe.u_core.perf_d1[5] = u_g1.mainPipe.io_perf_5_value_REG;
    force u_i1.u_core.mainPipe.u_core.perf[5] = u_g1.mainPipe.io_perf_5_value_REG_1;
    force u_i1.u_core.mainPipe.u_core.perf_d1[6] = u_g1.mainPipe.io_perf_6_value_REG;
    force u_i1.u_core.mainPipe.u_core.perf[6] = u_g1.mainPipe.io_perf_6_value_REG_1;
    force u_i1.u_core.mainPipe.u_core.perf_d1[7] = u_g1.mainPipe.io_perf_7_value_REG;
    force u_i1.u_core.mainPipe.u_core.perf[7] = u_g1.mainPipe.io_perf_7_value_REG_1;
    force u_i1.u_core.mainPipe.u_core.perf_d1[8] = u_g1.mainPipe.io_perf_8_value_REG;
    force u_i1.u_core.mainPipe.u_core.perf[8] = u_g1.mainPipe.io_perf_8_value_REG_1;
    force u_i1.u_core.mainPipe.u_core.perf_d1[9] = u_g1.mainPipe.io_perf_9_value_REG;
    force u_i1.u_core.mainPipe.u_core.perf[9] = u_g1.mainPipe.io_perf_9_value_REG_1;
    force u_i1.u_core.mainPipe.u_core.perf_d1[10] = u_g1.mainPipe.io_perf_10_value_REG;
    force u_i1.u_core.mainPipe.u_core.perf[10] = u_g1.mainPipe.io_perf_10_value_REG_1;
    force u_i1.u_core.mainPipe.u_core.perf_d1[11] = u_g1.mainPipe.io_perf_11_value_REG;
    force u_i1.u_core.mainPipe.u_core.perf[11] = u_g1.mainPipe.io_perf_11_value_REG_1;
    force u_i1.u_core.mainPipe.u_core.perf_d1[12] = u_g1.mainPipe.io_perf_12_value_REG;
    force u_i1.u_core.mainPipe.u_core.perf[12] = u_g1.mainPipe.io_perf_12_value_REG_1;
    u_i1.u_core.grantBuf.grantQueue.ram_ext.Memory = u_g1.grantBuf.grantQueue.ram_ext.Memory;
    u_i1.u_core.grantBuf.grantQueueData0.ram_data_data_ext.Memory = u_g1.grantBuf.grantQueueData0.ram_data_data_ext.Memory;
    u_i1.u_core.grantBuf.grantQueueData1.ram_data_data_ext.Memory = u_g1.grantBuf.grantQueueData1.ram_data_data_ext.Memory;
    u_i1.u_core.grantBuf.pftRespQueue.ram_ext.Memory = u_g1.grantBuf.pftRespQueue.ram_ext.Memory;
    force u_i1.u_core.grantBuf.u_core.validPrev[0] = u_g1.grantBuf.REG;
    force u_i1.u_core.grantBuf.u_core.histValidPrev[0] = u_g1.grantBuf.enable_REG;
    force u_i1.u_core.grantBuf.u_core.validPrev[1] = u_g1.grantBuf.REG_1;
    force u_i1.u_core.grantBuf.u_core.histValidPrev[1] = u_g1.grantBuf.enable_REG_1;
    force u_i1.u_core.grantBuf.u_core.validPrev[2] = u_g1.grantBuf.REG_2;
    force u_i1.u_core.grantBuf.u_core.histValidPrev[2] = u_g1.grantBuf.enable_REG_2;
    force u_i1.u_core.grantBuf.u_core.validPrev[3] = u_g1.grantBuf.REG_3;
    force u_i1.u_core.grantBuf.u_core.histValidPrev[3] = u_g1.grantBuf.enable_REG_3;
    force u_i1.u_core.grantBuf.u_core.validPrev[4] = u_g1.grantBuf.REG_4;
    force u_i1.u_core.grantBuf.u_core.histValidPrev[4] = u_g1.grantBuf.enable_REG_4;
    force u_i1.u_core.grantBuf.u_core.validPrev[5] = u_g1.grantBuf.REG_5;
    force u_i1.u_core.grantBuf.u_core.histValidPrev[5] = u_g1.grantBuf.enable_REG_5;
    force u_i1.u_core.grantBuf.u_core.validPrev[6] = u_g1.grantBuf.REG_6;
    force u_i1.u_core.grantBuf.u_core.histValidPrev[6] = u_g1.grantBuf.enable_REG_6;
    force u_i1.u_core.grantBuf.u_core.validPrev[7] = u_g1.grantBuf.REG_7;
    force u_i1.u_core.grantBuf.u_core.histValidPrev[7] = u_g1.grantBuf.enable_REG_7;
    force u_i1.u_core.grantBuf.u_core.validPrev[8] = u_g1.grantBuf.REG_8;
    force u_i1.u_core.grantBuf.u_core.histValidPrev[8] = u_g1.grantBuf.enable_REG_8;
    force u_i1.u_core.grantBuf.u_core.validPrev[9] = u_g1.grantBuf.REG_9;
    force u_i1.u_core.grantBuf.u_core.histValidPrev[9] = u_g1.grantBuf.enable_REG_9;
    force u_i1.u_core.grantBuf.u_core.validPrev[10] = u_g1.grantBuf.REG_10;
    force u_i1.u_core.grantBuf.u_core.histValidPrev[10] = u_g1.grantBuf.enable_REG_10;
    force u_i1.u_core.grantBuf.u_core.validPrev[11] = u_g1.grantBuf.REG_11;
    force u_i1.u_core.grantBuf.u_core.histValidPrev[11] = u_g1.grantBuf.enable_REG_11;
    force u_i1.u_core.grantBuf.u_core.validPrev[12] = u_g1.grantBuf.REG_12;
    force u_i1.u_core.grantBuf.u_core.histValidPrev[12] = u_g1.grantBuf.enable_REG_12;
    force u_i1.u_core.grantBuf.u_core.validPrev[13] = u_g1.grantBuf.REG_13;
    force u_i1.u_core.grantBuf.u_core.histValidPrev[13] = u_g1.grantBuf.enable_REG_13;
    force u_i1.u_core.grantBuf.u_core.validPrev[14] = u_g1.grantBuf.REG_14;
    force u_i1.u_core.grantBuf.u_core.histValidPrev[14] = u_g1.grantBuf.enable_REG_14;
    force u_i1.u_core.grantBuf.u_core.validPrev[15] = u_g1.grantBuf.REG_15;
    force u_i1.u_core.grantBuf.u_core.histValidPrev[15] = u_g1.grantBuf.enable_REG_15;
    u_i1.u_core.rxsnp.queue.ram_ext.Memory = u_g1.rxsnp.queue.ram_ext.Memory;
    force u_i1.u_core.rxsnp.u_core.replPrevForBlock[0] = u_g1.rxsnp.replaceBlockSnpMask_REG;
    force u_i1.u_core.rxsnp.u_core.replPrevForNest[0] = u_g1.rxsnp.replaceNestSnpMask_REG;
    force u_i1.u_core.rxsnp.u_core.replPrevForBlock[1] = u_g1.rxsnp.replaceBlockSnpMask_REG_1;
    force u_i1.u_core.rxsnp.u_core.replPrevForNest[1] = u_g1.rxsnp.replaceNestSnpMask_REG_1;
    force u_i1.u_core.rxsnp.u_core.replPrevForBlock[2] = u_g1.rxsnp.replaceBlockSnpMask_REG_2;
    force u_i1.u_core.rxsnp.u_core.replPrevForNest[2] = u_g1.rxsnp.replaceNestSnpMask_REG_2;
    force u_i1.u_core.rxsnp.u_core.replPrevForBlock[3] = u_g1.rxsnp.replaceBlockSnpMask_REG_3;
    force u_i1.u_core.rxsnp.u_core.replPrevForNest[3] = u_g1.rxsnp.replaceNestSnpMask_REG_3;
    force u_i1.u_core.rxsnp.u_core.replPrevForBlock[4] = u_g1.rxsnp.replaceBlockSnpMask_REG_4;
    force u_i1.u_core.rxsnp.u_core.replPrevForNest[4] = u_g1.rxsnp.replaceNestSnpMask_REG_4;
    force u_i1.u_core.rxsnp.u_core.replPrevForBlock[5] = u_g1.rxsnp.replaceBlockSnpMask_REG_5;
    force u_i1.u_core.rxsnp.u_core.replPrevForNest[5] = u_g1.rxsnp.replaceNestSnpMask_REG_5;
    force u_i1.u_core.rxsnp.u_core.replPrevForBlock[6] = u_g1.rxsnp.replaceBlockSnpMask_REG_6;
    force u_i1.u_core.rxsnp.u_core.replPrevForNest[6] = u_g1.rxsnp.replaceNestSnpMask_REG_6;
    force u_i1.u_core.rxsnp.u_core.replPrevForBlock[7] = u_g1.rxsnp.replaceBlockSnpMask_REG_7;
    force u_i1.u_core.rxsnp.u_core.replPrevForNest[7] = u_g1.rxsnp.replaceNestSnpMask_REG_7;
    force u_i1.u_core.rxsnp.u_core.replPrevForBlock[8] = u_g1.rxsnp.replaceBlockSnpMask_REG_8;
    force u_i1.u_core.rxsnp.u_core.replPrevForNest[8] = u_g1.rxsnp.replaceNestSnpMask_REG_8;
    force u_i1.u_core.rxsnp.u_core.replPrevForBlock[9] = u_g1.rxsnp.replaceBlockSnpMask_REG_9;
    force u_i1.u_core.rxsnp.u_core.replPrevForNest[9] = u_g1.rxsnp.replaceNestSnpMask_REG_9;
    force u_i1.u_core.rxsnp.u_core.replPrevForBlock[10] = u_g1.rxsnp.replaceBlockSnpMask_REG_10;
    force u_i1.u_core.rxsnp.u_core.replPrevForNest[10] = u_g1.rxsnp.replaceNestSnpMask_REG_10;
    force u_i1.u_core.rxsnp.u_core.replPrevForBlock[11] = u_g1.rxsnp.replaceBlockSnpMask_REG_11;
    force u_i1.u_core.rxsnp.u_core.replPrevForNest[11] = u_g1.rxsnp.replaceNestSnpMask_REG_11;
    force u_i1.u_core.rxsnp.u_core.replPrevForBlock[12] = u_g1.rxsnp.replaceBlockSnpMask_REG_12;
    force u_i1.u_core.rxsnp.u_core.replPrevForNest[12] = u_g1.rxsnp.replaceNestSnpMask_REG_12;
    force u_i1.u_core.rxsnp.u_core.replPrevForBlock[13] = u_g1.rxsnp.replaceBlockSnpMask_REG_13;
    force u_i1.u_core.rxsnp.u_core.replPrevForNest[13] = u_g1.rxsnp.replaceNestSnpMask_REG_13;
    force u_i1.u_core.rxsnp.u_core.replPrevForBlock[14] = u_g1.rxsnp.replaceBlockSnpMask_REG_14;
    force u_i1.u_core.rxsnp.u_core.replPrevForNest[14] = u_g1.rxsnp.replaceNestSnpMask_REG_14;
    force u_i1.u_core.rxsnp.u_core.replPrevForBlock[15] = u_g1.rxsnp.replaceBlockSnpMask_REG_15;
    force u_i1.u_core.rxsnp.u_core.replPrevForNest[15] = u_g1.rxsnp.replaceNestSnpMask_REG_15;
    force u_i1.u_core.reqBuf.chosenQ.u_core.ram = u_g1.reqBuf.chosenQ.ram;
    force u_i1.u_core.reqBuf.u_core.hitPfPrev_set = u_g1.reqBuf.io_hasHitPfInMSHR_valid_REG_set;
    force u_i1.u_core.reqBuf.u_core.hitPfPrev_tag = u_g1.reqBuf.io_hasHitPfInMSHR_valid_REG_tag;
    force u_i1.u_core.reqBuf.u_core.mergeAPrev_set = u_g1.reqBuf.io_hasMergeA_REG_set;
    force u_i1.u_core.reqBuf.u_core.mergeAPrev_tag = u_g1.reqBuf.io_hasMergeA_REG_tag;
    force u_i1.u_core.reqBuf.u_core.sameSetS3Valid[0] = u_g1.reqBuf.canFlow_sameSet_s3_REG;
    force u_i1.u_core.reqBuf.u_core.sameSetS3Set[0] = u_g1.reqBuf.canFlow_sameSet_s3_r;
    force u_i1.u_core.reqBuf.u_core.sameSetS3Valid[1] = u_g1.reqBuf.buffer_rdy_sameSet_s3_REG;
    force u_i1.u_core.reqBuf.u_core.sameSetS3Set[1] = u_g1.reqBuf.buffer_rdy_sameSet_s3_r;
    force u_i1.u_core.reqBuf.u_core.sameSetS3Valid[2] = u_g1.reqBuf.buffer_0_rdy_sameSet_s3_REG;
    force u_i1.u_core.reqBuf.u_core.sameSetS3Set[2] = u_g1.reqBuf.buffer_0_rdy_sameSet_s3_r;
    force u_i1.u_core.reqBuf.u_core.sameSetS3Valid[3] = u_g1.reqBuf.buffer_1_rdy_sameSet_s3_REG;
    force u_i1.u_core.reqBuf.u_core.sameSetS3Set[3] = u_g1.reqBuf.buffer_1_rdy_sameSet_s3_r;
    force u_i1.u_core.reqBuf.u_core.sameSetS3Valid[4] = u_g1.reqBuf.buffer_2_rdy_sameSet_s3_REG;
    force u_i1.u_core.reqBuf.u_core.sameSetS3Set[4] = u_g1.reqBuf.buffer_2_rdy_sameSet_s3_r;
    force u_i1.u_core.reqBuf.u_core.sameSetS3Valid[5] = u_g1.reqBuf.buffer_3_rdy_sameSet_s3_REG;
    force u_i1.u_core.reqBuf.u_core.sameSetS3Set[5] = u_g1.reqBuf.buffer_3_rdy_sameSet_s3_r;
    force u_i1.u_core.sinkC.u_core.bufRespStage[0] = u_g1.sinkC.r_0;
    force u_i1.u_core.sinkC.u_core.bufRespStage[1] = u_g1.sinkC.r_1;
    force u_i1.u_core.sinkC.u_core.bufRespOut[0] = u_g1.sinkC.REG_0;
    force u_i1.u_core.sinkC.u_core.bufRespOut[1] = u_g1.sinkC.REG_1;
    force u_i1.u_core.sinkC.u_core.refillIdReg = u_g1.sinkC.io_refillBufWrite_bits_id_REG;
    force u_i1.u_core.sinkC.u_core.refillBufIdxReg = u_g1.sinkC.io_refillBufWrite_bits_data_data_REG;
    force u_i1.u_core.sinkC.u_core.taskFirePrev = u_g1.sinkC.REG_1_0;
    force u_i1.u_core.sinkC.u_core.taskBufIdxPrev = u_g1.sinkC.REG_2;
    force u_i1.u_core.reqArb.u_core.ds_mcp2_stall = u_g1.reqArb.ds_mcp2_stall;
    force u_i1.u_core.refillBuf.u_core.buffer[0][0] = u_g1.refillBuf.buffer_0_0;
    force u_i1.u_core.refillBuf.u_core.buffer[0][1] = u_g1.refillBuf.buffer_0_1;
    force u_i1.u_core.refillBuf.u_core.buffer[1][0] = u_g1.refillBuf.buffer_1_0;
    force u_i1.u_core.refillBuf.u_core.buffer[1][1] = u_g1.refillBuf.buffer_1_1;
    force u_i1.u_core.refillBuf.u_core.buffer[2][0] = u_g1.refillBuf.buffer_2_0;
    force u_i1.u_core.refillBuf.u_core.buffer[2][1] = u_g1.refillBuf.buffer_2_1;
    force u_i1.u_core.refillBuf.u_core.buffer[3][0] = u_g1.refillBuf.buffer_3_0;
    force u_i1.u_core.refillBuf.u_core.buffer[3][1] = u_g1.refillBuf.buffer_3_1;
    force u_i1.u_core.refillBuf.u_core.buffer[4][0] = u_g1.refillBuf.buffer_4_0;
    force u_i1.u_core.refillBuf.u_core.buffer[4][1] = u_g1.refillBuf.buffer_4_1;
    force u_i1.u_core.refillBuf.u_core.buffer[5][0] = u_g1.refillBuf.buffer_5_0;
    force u_i1.u_core.refillBuf.u_core.buffer[5][1] = u_g1.refillBuf.buffer_5_1;
    force u_i1.u_core.refillBuf.u_core.buffer[6][0] = u_g1.refillBuf.buffer_6_0;
    force u_i1.u_core.refillBuf.u_core.buffer[6][1] = u_g1.refillBuf.buffer_6_1;
    force u_i1.u_core.refillBuf.u_core.buffer[7][0] = u_g1.refillBuf.buffer_7_0;
    force u_i1.u_core.refillBuf.u_core.buffer[7][1] = u_g1.refillBuf.buffer_7_1;
    force u_i1.u_core.refillBuf.u_core.buffer[8][0] = u_g1.refillBuf.buffer_8_0;
    force u_i1.u_core.refillBuf.u_core.buffer[8][1] = u_g1.refillBuf.buffer_8_1;
    force u_i1.u_core.refillBuf.u_core.buffer[9][0] = u_g1.refillBuf.buffer_9_0;
    force u_i1.u_core.refillBuf.u_core.buffer[9][1] = u_g1.refillBuf.buffer_9_1;
    force u_i1.u_core.refillBuf.u_core.buffer[10][0] = u_g1.refillBuf.buffer_10_0;
    force u_i1.u_core.refillBuf.u_core.buffer[10][1] = u_g1.refillBuf.buffer_10_1;
    force u_i1.u_core.refillBuf.u_core.buffer[11][0] = u_g1.refillBuf.buffer_11_0;
    force u_i1.u_core.refillBuf.u_core.buffer[11][1] = u_g1.refillBuf.buffer_11_1;
    force u_i1.u_core.refillBuf.u_core.buffer[12][0] = u_g1.refillBuf.buffer_12_0;
    force u_i1.u_core.refillBuf.u_core.buffer[12][1] = u_g1.refillBuf.buffer_12_1;
    force u_i1.u_core.refillBuf.u_core.buffer[13][0] = u_g1.refillBuf.buffer_13_0;
    force u_i1.u_core.refillBuf.u_core.buffer[13][1] = u_g1.refillBuf.buffer_13_1;
    force u_i1.u_core.refillBuf.u_core.buffer[14][0] = u_g1.refillBuf.buffer_14_0;
    force u_i1.u_core.refillBuf.u_core.buffer[14][1] = u_g1.refillBuf.buffer_14_1;
    force u_i1.u_core.refillBuf.u_core.buffer[15][0] = u_g1.refillBuf.buffer_15_0;
    force u_i1.u_core.refillBuf.u_core.buffer[15][1] = u_g1.refillBuf.buffer_15_1;
    force u_i1.u_core.releaseBuf.u_core.buffer[0][0] = u_g1.releaseBuf.buffer_0_0;
    force u_i1.u_core.releaseBuf.u_core.buffer[0][1] = u_g1.releaseBuf.buffer_0_1;
    force u_i1.u_core.releaseBuf.u_core.buffer[1][0] = u_g1.releaseBuf.buffer_1_0;
    force u_i1.u_core.releaseBuf.u_core.buffer[1][1] = u_g1.releaseBuf.buffer_1_1;
    force u_i1.u_core.releaseBuf.u_core.buffer[2][0] = u_g1.releaseBuf.buffer_2_0;
    force u_i1.u_core.releaseBuf.u_core.buffer[2][1] = u_g1.releaseBuf.buffer_2_1;
    force u_i1.u_core.releaseBuf.u_core.buffer[3][0] = u_g1.releaseBuf.buffer_3_0;
    force u_i1.u_core.releaseBuf.u_core.buffer[3][1] = u_g1.releaseBuf.buffer_3_1;
    force u_i1.u_core.releaseBuf.u_core.buffer[4][0] = u_g1.releaseBuf.buffer_4_0;
    force u_i1.u_core.releaseBuf.u_core.buffer[4][1] = u_g1.releaseBuf.buffer_4_1;
    force u_i1.u_core.releaseBuf.u_core.buffer[5][0] = u_g1.releaseBuf.buffer_5_0;
    force u_i1.u_core.releaseBuf.u_core.buffer[5][1] = u_g1.releaseBuf.buffer_5_1;
    force u_i1.u_core.releaseBuf.u_core.buffer[6][0] = u_g1.releaseBuf.buffer_6_0;
    force u_i1.u_core.releaseBuf.u_core.buffer[6][1] = u_g1.releaseBuf.buffer_6_1;
    force u_i1.u_core.releaseBuf.u_core.buffer[7][0] = u_g1.releaseBuf.buffer_7_0;
    force u_i1.u_core.releaseBuf.u_core.buffer[7][1] = u_g1.releaseBuf.buffer_7_1;
    force u_i1.u_core.releaseBuf.u_core.buffer[8][0] = u_g1.releaseBuf.buffer_8_0;
    force u_i1.u_core.releaseBuf.u_core.buffer[8][1] = u_g1.releaseBuf.buffer_8_1;
    force u_i1.u_core.releaseBuf.u_core.buffer[9][0] = u_g1.releaseBuf.buffer_9_0;
    force u_i1.u_core.releaseBuf.u_core.buffer[9][1] = u_g1.releaseBuf.buffer_9_1;
    force u_i1.u_core.releaseBuf.u_core.buffer[10][0] = u_g1.releaseBuf.buffer_10_0;
    force u_i1.u_core.releaseBuf.u_core.buffer[10][1] = u_g1.releaseBuf.buffer_10_1;
    force u_i1.u_core.releaseBuf.u_core.buffer[11][0] = u_g1.releaseBuf.buffer_11_0;
    force u_i1.u_core.releaseBuf.u_core.buffer[11][1] = u_g1.releaseBuf.buffer_11_1;
    force u_i1.u_core.releaseBuf.u_core.buffer[12][0] = u_g1.releaseBuf.buffer_12_0;
    force u_i1.u_core.releaseBuf.u_core.buffer[12][1] = u_g1.releaseBuf.buffer_12_1;
    force u_i1.u_core.releaseBuf.u_core.buffer[13][0] = u_g1.releaseBuf.buffer_13_0;
    force u_i1.u_core.releaseBuf.u_core.buffer[13][1] = u_g1.releaseBuf.buffer_13_1;
    force u_i1.u_core.releaseBuf.u_core.buffer[14][0] = u_g1.releaseBuf.buffer_14_0;
    force u_i1.u_core.releaseBuf.u_core.buffer[14][1] = u_g1.releaseBuf.buffer_14_1;
    force u_i1.u_core.releaseBuf.u_core.buffer[15][0] = u_g1.releaseBuf.buffer_15_0;
    force u_i1.u_core.releaseBuf.u_core.buffer[15][1] = u_g1.releaseBuf.buffer_15_1;
    u_i1.u_core.txdat.queue.ram_ext.Memory = u_g1.txdat.queue.ram_ext.Memory;
    u_i1.u_core.txdat.queueData0.ram_data_ext.Memory = u_g1.txdat.queueData0.ram_data_ext.Memory;
    u_i1.u_core.txdat.queueData1.ram_data_ext.Memory = u_g1.txdat.queueData1.ram_data_ext.Memory;
    u_i1.directory.tagArray.array_0_0_0.array.array.array_14_ext.ram = u_g1.directory.tagArray.array_0_0_0.array.array.array_14_ext.ram;
    u_i1.directory.tagArray.array_0_0_0.array.array.array_14_ext.reg_RW0_addr = u_g1.directory.tagArray.array_0_0_0.array.array.array_14_ext.reg_RW0_addr;
    u_i1.directory.tagArray.array_0_0_0.array.array.array_14_ext.reg_RW0_ren = u_g1.directory.tagArray.array_0_0_0.array.array.array_14_ext.reg_RW0_ren;
    force u_i1.directory.tagArray.array_0_0_0.u_core.rdataReg = u_g1.directory.tagArray.array_0_0_0.rdataReg;
    u_i1.directory.tagArray.array_0_0_1.array.array.array_14_ext.ram = u_g1.directory.tagArray.array_0_0_1.array.array.array_14_ext.ram;
    u_i1.directory.tagArray.array_0_0_1.array.array.array_14_ext.reg_RW0_addr = u_g1.directory.tagArray.array_0_0_1.array.array.array_14_ext.reg_RW0_addr;
    u_i1.directory.tagArray.array_0_0_1.array.array.array_14_ext.reg_RW0_ren = u_g1.directory.tagArray.array_0_0_1.array.array.array_14_ext.reg_RW0_ren;
    force u_i1.directory.tagArray.array_0_0_1.u_core.rdataReg = u_g1.directory.tagArray.array_0_0_1.rdataReg;
    u_i1.directory.tagArray.array_0_1_0.array.array.array_14_ext.ram = u_g1.directory.tagArray.array_0_1_0.array.array.array_14_ext.ram;
    u_i1.directory.tagArray.array_0_1_0.array.array.array_14_ext.reg_RW0_addr = u_g1.directory.tagArray.array_0_1_0.array.array.array_14_ext.reg_RW0_addr;
    u_i1.directory.tagArray.array_0_1_0.array.array.array_14_ext.reg_RW0_ren = u_g1.directory.tagArray.array_0_1_0.array.array.array_14_ext.reg_RW0_ren;
    force u_i1.directory.tagArray.array_0_1_0.u_core.rdataReg = u_g1.directory.tagArray.array_0_1_0.rdataReg;
    u_i1.directory.tagArray.array_0_1_1.array.array.array_14_ext.ram = u_g1.directory.tagArray.array_0_1_1.array.array.array_14_ext.ram;
    u_i1.directory.tagArray.array_0_1_1.array.array.array_14_ext.reg_RW0_addr = u_g1.directory.tagArray.array_0_1_1.array.array.array_14_ext.reg_RW0_addr;
    u_i1.directory.tagArray.array_0_1_1.array.array.array_14_ext.reg_RW0_ren = u_g1.directory.tagArray.array_0_1_1.array.array.array_14_ext.reg_RW0_ren;
    force u_i1.directory.tagArray.array_0_1_1.u_core.rdataReg = u_g1.directory.tagArray.array_0_1_1.rdataReg;
    u_i1.directory.metaArray.array.array.array_15_ext.ram = u_g1.directory.metaArray.array.array.array_15_ext.ram;
    u_i1.directory.metaArray.array.array.array_15_ext.reg_RW0_addr = u_g1.directory.metaArray.array.array.array_15_ext.reg_RW0_addr;
    u_i1.directory.metaArray.array.array.array_15_ext.reg_RW0_ren = u_g1.directory.metaArray.array.array.array_15_ext.reg_RW0_ren;
    force u_i1.directory.metaArray.u_core.rdataReg = u_g1.directory.metaArray.rdataReg;
    u_i1.directory.replacer_sram_opt.array.array.array_16_ext.ram = u_g1.directory.replacer_sram_opt.array.array.array_16_ext.ram;
    u_i1.directory.replacer_sram_opt.array.array.array_16_ext.reg_RW0_addr = u_g1.directory.replacer_sram_opt.array.array.array_16_ext.reg_RW0_addr;
    u_i1.directory.replacer_sram_opt.array.array.array_16_ext.reg_RW0_ren = u_g1.directory.replacer_sram_opt.array.array.array_16_ext.reg_RW0_ren;
    force u_i1.directory.replacer_sram_opt.u_core.rdataReg = u_g1.directory.replacer_sram_opt.rdataReg;
    u_i1.directory.origin_bit_opt.array.array.array_17_ext.ram = u_g1.directory.origin_bit_opt.array.array.array_17_ext.ram;
    u_i1.directory.origin_bit_opt.array.array.array_17_ext.reg_RW0_addr = u_g1.directory.origin_bit_opt.array.array.array_17_ext.reg_RW0_addr;
    u_i1.directory.origin_bit_opt.array.array.array_17_ext.reg_RW0_ren = u_g1.directory.origin_bit_opt.array.array.array_17_ext.reg_RW0_ren;
    force u_i1.directory.origin_bit_opt.u_core.rdataReg = u_g1.directory.origin_bit_opt.rdataReg;
    u_i1.dataStorage.array.array_0_0_0.array.array.array_18_ext.ram = u_g1.dataStorage.array.array_0_0_0.array.array.array_18_ext.ram;
    u_i1.dataStorage.array.array_0_0_0.array.array.array_18_ext.reg_RW0_addr = u_g1.dataStorage.array.array_0_0_0.array.array.array_18_ext.reg_RW0_addr;
    u_i1.dataStorage.array.array_0_0_0.array.array.array_18_ext.reg_RW0_ren = u_g1.dataStorage.array.array_0_0_0.array.array.array_18_ext.reg_RW0_ren;
    force u_i1.dataStorage.array.array_0_0_0.u_core.rdataReg = u_g1.dataStorage.array.array_0_0_0.rdataReg;
    u_i1.dataStorage.array.array_0_0_1.array.array.array_18_ext.ram = u_g1.dataStorage.array.array_0_0_1.array.array.array_18_ext.ram;
    u_i1.dataStorage.array.array_0_0_1.array.array.array_18_ext.reg_RW0_addr = u_g1.dataStorage.array.array_0_0_1.array.array.array_18_ext.reg_RW0_addr;
    u_i1.dataStorage.array.array_0_0_1.array.array.array_18_ext.reg_RW0_ren = u_g1.dataStorage.array.array_0_0_1.array.array.array_18_ext.reg_RW0_ren;
    force u_i1.dataStorage.array.array_0_0_1.u_core.rdataReg = u_g1.dataStorage.array.array_0_0_1.rdataReg;
    u_i1.dataStorage.array.array_0_0_2.array.array.array_18_ext.ram = u_g1.dataStorage.array.array_0_0_2.array.array.array_18_ext.ram;
    u_i1.dataStorage.array.array_0_0_2.array.array.array_18_ext.reg_RW0_addr = u_g1.dataStorage.array.array_0_0_2.array.array.array_18_ext.reg_RW0_addr;
    u_i1.dataStorage.array.array_0_0_2.array.array.array_18_ext.reg_RW0_ren = u_g1.dataStorage.array.array_0_0_2.array.array.array_18_ext.reg_RW0_ren;
    force u_i1.dataStorage.array.array_0_0_2.u_core.rdataReg = u_g1.dataStorage.array.array_0_0_2.rdataReg;
    u_i1.dataStorage.array.array_0_0_3.array.array.array_18_ext.ram = u_g1.dataStorage.array.array_0_0_3.array.array.array_18_ext.ram;
    u_i1.dataStorage.array.array_0_0_3.array.array.array_18_ext.reg_RW0_addr = u_g1.dataStorage.array.array_0_0_3.array.array.array_18_ext.reg_RW0_addr;
    u_i1.dataStorage.array.array_0_0_3.array.array.array_18_ext.reg_RW0_ren = u_g1.dataStorage.array.array_0_0_3.array.array.array_18_ext.reg_RW0_ren;
    force u_i1.dataStorage.array.array_0_0_3.u_core.rdataReg = u_g1.dataStorage.array.array_0_0_3.rdataReg;
    force u_i1.dataStorage.u_core.error_REG = u_g1.dataStorage.error_REG;
    force u_i1.dataStorage.u_core.error_REG_1 = u_g1.dataStorage.error_REG_1;
    force u_i1.mbistPl.u_core.g_node_return.pipelineDataOutReg = u_g1.mbistPl.pipelineDataOutReg;
    u_i1.u_core.txreq.u_core.queue.ram_ext.Memory = u_g1.txreq.queue.ram_ext.Memory;
    u_i1.u_core.txrsp.u_core.queue.ram_ext.Memory = u_g1.txrsp.queue.ram_ext.Memory;
    force u_i1.u_core.io_error_bits_REG_valid = u_g1.io_error_bits_REG_valid;
    force u_i1.u_core.io_error_bits_REG_address = u_g1.io_error_bits_REG_address;
    force u_i1.u_core.io_perf_0_value_REG = u_g1.io_perf_0_value_REG;
    force u_i1.u_core.io_perf_0_value_REG_1 = u_g1.io_perf_0_value_REG_1;
    force u_i1.u_core.io_perf_1_value_REG = u_g1.io_perf_1_value_REG;
    force u_i1.u_core.io_perf_1_value_REG_1 = u_g1.io_perf_1_value_REG_1;
    force u_i1.u_core.io_perf_3_value_REG = u_g1.io_perf_3_value_REG;
    force u_i1.u_core.io_perf_3_value_REG_1 = u_g1.io_perf_3_value_REG_1;
    force u_i1.u_core.io_perf_4_value_REG = u_g1.io_perf_4_value_REG;
    force u_i1.u_core.io_perf_4_value_REG_1 = u_g1.io_perf_4_value_REG_1;
    force u_i1.u_core.io_perf_5_value_REG = u_g1.io_perf_5_value_REG;
    force u_i1.u_core.io_perf_5_value_REG_1 = u_g1.io_perf_5_value_REG_1;
    force u_i1.u_core.io_perf_6_value_REG = u_g1.io_perf_6_value_REG;
    force u_i1.u_core.io_perf_6_value_REG_1 = u_g1.io_perf_6_value_REG_1;
    force u_i1.u_core.io_perf_7_value_REG = u_g1.io_perf_7_value_REG;
    force u_i1.u_core.io_perf_7_value_REG_1 = u_g1.io_perf_7_value_REG_1;
    force u_i1.u_core.io_perf_8_value_REG = u_g1.io_perf_8_value_REG;
    force u_i1.u_core.io_perf_8_value_REG_1 = u_g1.io_perf_8_value_REG_1;
    force u_i1.u_core.io_perf_9_value_REG = u_g1.io_perf_9_value_REG;
    force u_i1.u_core.io_perf_9_value_REG_1 = u_g1.io_perf_9_value_REG_1;
    force u_i1.u_core.io_perf_10_value_REG = u_g1.io_perf_10_value_REG;
    force u_i1.u_core.io_perf_10_value_REG_1 = u_g1.io_perf_10_value_REG_1;
    force u_i1.u_core.io_perf_11_value_REG = u_g1.io_perf_11_value_REG;
    force u_i1.u_core.io_perf_11_value_REG_1 = u_g1.io_perf_11_value_REG_1;
    force u_i1.u_core.io_perf_12_value_REG = u_g1.io_perf_12_value_REG;
    force u_i1.u_core.io_perf_12_value_REG_1 = u_g1.io_perf_12_value_REG_1;
    force u_i1.u_core.io_perf_13_value_REG = u_g1.io_perf_13_value_REG;
    force u_i1.u_core.io_perf_13_value_REG_1 = u_g1.io_perf_13_value_REG_1;
    force u_i1.u_core.io_perf_14_value_REG = u_g1.io_perf_14_value_REG;
    force u_i1.u_core.io_perf_14_value_REG_1 = u_g1.io_perf_14_value_REG_1;
    force u_i1.u_core.io_perf_15_value_REG = u_g1.io_perf_15_value_REG;
    force u_i1.u_core.io_perf_15_value_REG_1 = u_g1.io_perf_15_value_REG_1;
    force u_i1.u_core.io_perf_16_value_REG = u_g1.io_perf_16_value_REG;
    force u_i1.u_core.io_perf_16_value_REG_1 = u_g1.io_perf_16_value_REG_1;
    force u_i2.u_core.mshrCtl.u_core.mshrs[0].entry.u_core.tgtid_rcompack = u_g2.mshrCtl.mshrs_0.tgtid_rcompack;
    force u_i2.u_core.mshrCtl.u_core.mshrs[0].entry.u_core.txnid_rcompack = u_g2.mshrCtl.mshrs_0.txnid_rcompack;
    force u_i2.u_core.mshrCtl.u_core.mshrs[0].entry.u_core.tgtid_wcompack = u_g2.mshrCtl.mshrs_0.tgtid_wcompack;
    force u_i2.u_core.mshrCtl.u_core.mshrs[0].entry.u_core.txnid_wcompack = u_g2.mshrCtl.mshrs_0.txnid_wcompack;
    force u_i2.u_core.mshrCtl.u_core.mshrs[0].entry.u_core.srcid_retryack = u_g2.mshrCtl.mshrs_0.srcid_retryack;
    force u_i2.u_core.mshrCtl.u_core.mshrs[0].entry.u_core.acquire_ts = u_g2.mshrCtl.mshrs_0.acquire_ts;
    force u_i2.u_core.mshrCtl.u_core.mshrs[0].entry.u_core.release_ts = u_g2.mshrCtl.mshrs_0.release_ts;
    force u_i2.u_core.mshrCtl.u_core.mshrs[0].entry.u_core.acquire_period_valid_REG = u_g2.mshrCtl.mshrs_0.acquire_period_valid_REG;
    force u_i2.u_core.mshrCtl.u_core.mshrs[0].entry.u_core.release_period_valid_REG = u_g2.mshrCtl.mshrs_0.release_period_valid_REG;
    force u_i2.u_core.mshrCtl.u_core.mshrs[0].entry.u_core.REG = u_g2.mshrCtl.mshrs_0.REG;
    force u_i2.u_core.mshrCtl.u_core.mshrs[0].entry.u_core.REG_1 = u_g2.mshrCtl.mshrs_0.REG_1;
    force u_i2.u_core.mshrCtl.u_core.mshrs[0].entry.u_core.REG_2 = u_g2.mshrCtl.mshrs_0.REG_2;
    force u_i2.u_core.mshrCtl.u_core.mshrs[0].entry.u_core.REG_3 = u_g2.mshrCtl.mshrs_0.REG_3;
    force u_i2.u_core.mshrCtl.u_core.mshrs[1].entry.u_core.tgtid_rcompack = u_g2.mshrCtl.mshrs_1.tgtid_rcompack;
    force u_i2.u_core.mshrCtl.u_core.mshrs[1].entry.u_core.txnid_rcompack = u_g2.mshrCtl.mshrs_1.txnid_rcompack;
    force u_i2.u_core.mshrCtl.u_core.mshrs[1].entry.u_core.tgtid_wcompack = u_g2.mshrCtl.mshrs_1.tgtid_wcompack;
    force u_i2.u_core.mshrCtl.u_core.mshrs[1].entry.u_core.txnid_wcompack = u_g2.mshrCtl.mshrs_1.txnid_wcompack;
    force u_i2.u_core.mshrCtl.u_core.mshrs[1].entry.u_core.srcid_retryack = u_g2.mshrCtl.mshrs_1.srcid_retryack;
    force u_i2.u_core.mshrCtl.u_core.mshrs[1].entry.u_core.acquire_ts = u_g2.mshrCtl.mshrs_1.acquire_ts;
    force u_i2.u_core.mshrCtl.u_core.mshrs[1].entry.u_core.release_ts = u_g2.mshrCtl.mshrs_1.release_ts;
    force u_i2.u_core.mshrCtl.u_core.mshrs[1].entry.u_core.acquire_period_valid_REG = u_g2.mshrCtl.mshrs_1.acquire_period_valid_REG;
    force u_i2.u_core.mshrCtl.u_core.mshrs[1].entry.u_core.release_period_valid_REG = u_g2.mshrCtl.mshrs_1.release_period_valid_REG;
    force u_i2.u_core.mshrCtl.u_core.mshrs[1].entry.u_core.REG = u_g2.mshrCtl.mshrs_1.REG;
    force u_i2.u_core.mshrCtl.u_core.mshrs[1].entry.u_core.REG_1 = u_g2.mshrCtl.mshrs_1.REG_1;
    force u_i2.u_core.mshrCtl.u_core.mshrs[1].entry.u_core.REG_2 = u_g2.mshrCtl.mshrs_1.REG_2;
    force u_i2.u_core.mshrCtl.u_core.mshrs[1].entry.u_core.REG_3 = u_g2.mshrCtl.mshrs_1.REG_3;
    force u_i2.u_core.mshrCtl.u_core.mshrs[2].entry.u_core.tgtid_rcompack = u_g2.mshrCtl.mshrs_2.tgtid_rcompack;
    force u_i2.u_core.mshrCtl.u_core.mshrs[2].entry.u_core.txnid_rcompack = u_g2.mshrCtl.mshrs_2.txnid_rcompack;
    force u_i2.u_core.mshrCtl.u_core.mshrs[2].entry.u_core.tgtid_wcompack = u_g2.mshrCtl.mshrs_2.tgtid_wcompack;
    force u_i2.u_core.mshrCtl.u_core.mshrs[2].entry.u_core.txnid_wcompack = u_g2.mshrCtl.mshrs_2.txnid_wcompack;
    force u_i2.u_core.mshrCtl.u_core.mshrs[2].entry.u_core.srcid_retryack = u_g2.mshrCtl.mshrs_2.srcid_retryack;
    force u_i2.u_core.mshrCtl.u_core.mshrs[2].entry.u_core.acquire_ts = u_g2.mshrCtl.mshrs_2.acquire_ts;
    force u_i2.u_core.mshrCtl.u_core.mshrs[2].entry.u_core.release_ts = u_g2.mshrCtl.mshrs_2.release_ts;
    force u_i2.u_core.mshrCtl.u_core.mshrs[2].entry.u_core.acquire_period_valid_REG = u_g2.mshrCtl.mshrs_2.acquire_period_valid_REG;
    force u_i2.u_core.mshrCtl.u_core.mshrs[2].entry.u_core.release_period_valid_REG = u_g2.mshrCtl.mshrs_2.release_period_valid_REG;
    force u_i2.u_core.mshrCtl.u_core.mshrs[2].entry.u_core.REG = u_g2.mshrCtl.mshrs_2.REG;
    force u_i2.u_core.mshrCtl.u_core.mshrs[2].entry.u_core.REG_1 = u_g2.mshrCtl.mshrs_2.REG_1;
    force u_i2.u_core.mshrCtl.u_core.mshrs[2].entry.u_core.REG_2 = u_g2.mshrCtl.mshrs_2.REG_2;
    force u_i2.u_core.mshrCtl.u_core.mshrs[2].entry.u_core.REG_3 = u_g2.mshrCtl.mshrs_2.REG_3;
    force u_i2.u_core.mshrCtl.u_core.mshrs[3].entry.u_core.tgtid_rcompack = u_g2.mshrCtl.mshrs_3.tgtid_rcompack;
    force u_i2.u_core.mshrCtl.u_core.mshrs[3].entry.u_core.txnid_rcompack = u_g2.mshrCtl.mshrs_3.txnid_rcompack;
    force u_i2.u_core.mshrCtl.u_core.mshrs[3].entry.u_core.tgtid_wcompack = u_g2.mshrCtl.mshrs_3.tgtid_wcompack;
    force u_i2.u_core.mshrCtl.u_core.mshrs[3].entry.u_core.txnid_wcompack = u_g2.mshrCtl.mshrs_3.txnid_wcompack;
    force u_i2.u_core.mshrCtl.u_core.mshrs[3].entry.u_core.srcid_retryack = u_g2.mshrCtl.mshrs_3.srcid_retryack;
    force u_i2.u_core.mshrCtl.u_core.mshrs[3].entry.u_core.acquire_ts = u_g2.mshrCtl.mshrs_3.acquire_ts;
    force u_i2.u_core.mshrCtl.u_core.mshrs[3].entry.u_core.release_ts = u_g2.mshrCtl.mshrs_3.release_ts;
    force u_i2.u_core.mshrCtl.u_core.mshrs[3].entry.u_core.acquire_period_valid_REG = u_g2.mshrCtl.mshrs_3.acquire_period_valid_REG;
    force u_i2.u_core.mshrCtl.u_core.mshrs[3].entry.u_core.release_period_valid_REG = u_g2.mshrCtl.mshrs_3.release_period_valid_REG;
    force u_i2.u_core.mshrCtl.u_core.mshrs[3].entry.u_core.REG = u_g2.mshrCtl.mshrs_3.REG;
    force u_i2.u_core.mshrCtl.u_core.mshrs[3].entry.u_core.REG_1 = u_g2.mshrCtl.mshrs_3.REG_1;
    force u_i2.u_core.mshrCtl.u_core.mshrs[3].entry.u_core.REG_2 = u_g2.mshrCtl.mshrs_3.REG_2;
    force u_i2.u_core.mshrCtl.u_core.mshrs[3].entry.u_core.REG_3 = u_g2.mshrCtl.mshrs_3.REG_3;
    force u_i2.u_core.mshrCtl.u_core.mshrs[4].entry.u_core.tgtid_rcompack = u_g2.mshrCtl.mshrs_4.tgtid_rcompack;
    force u_i2.u_core.mshrCtl.u_core.mshrs[4].entry.u_core.txnid_rcompack = u_g2.mshrCtl.mshrs_4.txnid_rcompack;
    force u_i2.u_core.mshrCtl.u_core.mshrs[4].entry.u_core.tgtid_wcompack = u_g2.mshrCtl.mshrs_4.tgtid_wcompack;
    force u_i2.u_core.mshrCtl.u_core.mshrs[4].entry.u_core.txnid_wcompack = u_g2.mshrCtl.mshrs_4.txnid_wcompack;
    force u_i2.u_core.mshrCtl.u_core.mshrs[4].entry.u_core.srcid_retryack = u_g2.mshrCtl.mshrs_4.srcid_retryack;
    force u_i2.u_core.mshrCtl.u_core.mshrs[4].entry.u_core.acquire_ts = u_g2.mshrCtl.mshrs_4.acquire_ts;
    force u_i2.u_core.mshrCtl.u_core.mshrs[4].entry.u_core.release_ts = u_g2.mshrCtl.mshrs_4.release_ts;
    force u_i2.u_core.mshrCtl.u_core.mshrs[4].entry.u_core.acquire_period_valid_REG = u_g2.mshrCtl.mshrs_4.acquire_period_valid_REG;
    force u_i2.u_core.mshrCtl.u_core.mshrs[4].entry.u_core.release_period_valid_REG = u_g2.mshrCtl.mshrs_4.release_period_valid_REG;
    force u_i2.u_core.mshrCtl.u_core.mshrs[4].entry.u_core.REG = u_g2.mshrCtl.mshrs_4.REG;
    force u_i2.u_core.mshrCtl.u_core.mshrs[4].entry.u_core.REG_1 = u_g2.mshrCtl.mshrs_4.REG_1;
    force u_i2.u_core.mshrCtl.u_core.mshrs[4].entry.u_core.REG_2 = u_g2.mshrCtl.mshrs_4.REG_2;
    force u_i2.u_core.mshrCtl.u_core.mshrs[4].entry.u_core.REG_3 = u_g2.mshrCtl.mshrs_4.REG_3;
    force u_i2.u_core.mshrCtl.u_core.mshrs[5].entry.u_core.tgtid_rcompack = u_g2.mshrCtl.mshrs_5.tgtid_rcompack;
    force u_i2.u_core.mshrCtl.u_core.mshrs[5].entry.u_core.txnid_rcompack = u_g2.mshrCtl.mshrs_5.txnid_rcompack;
    force u_i2.u_core.mshrCtl.u_core.mshrs[5].entry.u_core.tgtid_wcompack = u_g2.mshrCtl.mshrs_5.tgtid_wcompack;
    force u_i2.u_core.mshrCtl.u_core.mshrs[5].entry.u_core.txnid_wcompack = u_g2.mshrCtl.mshrs_5.txnid_wcompack;
    force u_i2.u_core.mshrCtl.u_core.mshrs[5].entry.u_core.srcid_retryack = u_g2.mshrCtl.mshrs_5.srcid_retryack;
    force u_i2.u_core.mshrCtl.u_core.mshrs[5].entry.u_core.acquire_ts = u_g2.mshrCtl.mshrs_5.acquire_ts;
    force u_i2.u_core.mshrCtl.u_core.mshrs[5].entry.u_core.release_ts = u_g2.mshrCtl.mshrs_5.release_ts;
    force u_i2.u_core.mshrCtl.u_core.mshrs[5].entry.u_core.acquire_period_valid_REG = u_g2.mshrCtl.mshrs_5.acquire_period_valid_REG;
    force u_i2.u_core.mshrCtl.u_core.mshrs[5].entry.u_core.release_period_valid_REG = u_g2.mshrCtl.mshrs_5.release_period_valid_REG;
    force u_i2.u_core.mshrCtl.u_core.mshrs[5].entry.u_core.REG = u_g2.mshrCtl.mshrs_5.REG;
    force u_i2.u_core.mshrCtl.u_core.mshrs[5].entry.u_core.REG_1 = u_g2.mshrCtl.mshrs_5.REG_1;
    force u_i2.u_core.mshrCtl.u_core.mshrs[5].entry.u_core.REG_2 = u_g2.mshrCtl.mshrs_5.REG_2;
    force u_i2.u_core.mshrCtl.u_core.mshrs[5].entry.u_core.REG_3 = u_g2.mshrCtl.mshrs_5.REG_3;
    force u_i2.u_core.mshrCtl.u_core.mshrs[6].entry.u_core.tgtid_rcompack = u_g2.mshrCtl.mshrs_6.tgtid_rcompack;
    force u_i2.u_core.mshrCtl.u_core.mshrs[6].entry.u_core.txnid_rcompack = u_g2.mshrCtl.mshrs_6.txnid_rcompack;
    force u_i2.u_core.mshrCtl.u_core.mshrs[6].entry.u_core.tgtid_wcompack = u_g2.mshrCtl.mshrs_6.tgtid_wcompack;
    force u_i2.u_core.mshrCtl.u_core.mshrs[6].entry.u_core.txnid_wcompack = u_g2.mshrCtl.mshrs_6.txnid_wcompack;
    force u_i2.u_core.mshrCtl.u_core.mshrs[6].entry.u_core.srcid_retryack = u_g2.mshrCtl.mshrs_6.srcid_retryack;
    force u_i2.u_core.mshrCtl.u_core.mshrs[6].entry.u_core.acquire_ts = u_g2.mshrCtl.mshrs_6.acquire_ts;
    force u_i2.u_core.mshrCtl.u_core.mshrs[6].entry.u_core.release_ts = u_g2.mshrCtl.mshrs_6.release_ts;
    force u_i2.u_core.mshrCtl.u_core.mshrs[6].entry.u_core.acquire_period_valid_REG = u_g2.mshrCtl.mshrs_6.acquire_period_valid_REG;
    force u_i2.u_core.mshrCtl.u_core.mshrs[6].entry.u_core.release_period_valid_REG = u_g2.mshrCtl.mshrs_6.release_period_valid_REG;
    force u_i2.u_core.mshrCtl.u_core.mshrs[6].entry.u_core.REG = u_g2.mshrCtl.mshrs_6.REG;
    force u_i2.u_core.mshrCtl.u_core.mshrs[6].entry.u_core.REG_1 = u_g2.mshrCtl.mshrs_6.REG_1;
    force u_i2.u_core.mshrCtl.u_core.mshrs[6].entry.u_core.REG_2 = u_g2.mshrCtl.mshrs_6.REG_2;
    force u_i2.u_core.mshrCtl.u_core.mshrs[6].entry.u_core.REG_3 = u_g2.mshrCtl.mshrs_6.REG_3;
    force u_i2.u_core.mshrCtl.u_core.mshrs[7].entry.u_core.tgtid_rcompack = u_g2.mshrCtl.mshrs_7.tgtid_rcompack;
    force u_i2.u_core.mshrCtl.u_core.mshrs[7].entry.u_core.txnid_rcompack = u_g2.mshrCtl.mshrs_7.txnid_rcompack;
    force u_i2.u_core.mshrCtl.u_core.mshrs[7].entry.u_core.tgtid_wcompack = u_g2.mshrCtl.mshrs_7.tgtid_wcompack;
    force u_i2.u_core.mshrCtl.u_core.mshrs[7].entry.u_core.txnid_wcompack = u_g2.mshrCtl.mshrs_7.txnid_wcompack;
    force u_i2.u_core.mshrCtl.u_core.mshrs[7].entry.u_core.srcid_retryack = u_g2.mshrCtl.mshrs_7.srcid_retryack;
    force u_i2.u_core.mshrCtl.u_core.mshrs[7].entry.u_core.acquire_ts = u_g2.mshrCtl.mshrs_7.acquire_ts;
    force u_i2.u_core.mshrCtl.u_core.mshrs[7].entry.u_core.release_ts = u_g2.mshrCtl.mshrs_7.release_ts;
    force u_i2.u_core.mshrCtl.u_core.mshrs[7].entry.u_core.acquire_period_valid_REG = u_g2.mshrCtl.mshrs_7.acquire_period_valid_REG;
    force u_i2.u_core.mshrCtl.u_core.mshrs[7].entry.u_core.release_period_valid_REG = u_g2.mshrCtl.mshrs_7.release_period_valid_REG;
    force u_i2.u_core.mshrCtl.u_core.mshrs[7].entry.u_core.REG = u_g2.mshrCtl.mshrs_7.REG;
    force u_i2.u_core.mshrCtl.u_core.mshrs[7].entry.u_core.REG_1 = u_g2.mshrCtl.mshrs_7.REG_1;
    force u_i2.u_core.mshrCtl.u_core.mshrs[7].entry.u_core.REG_2 = u_g2.mshrCtl.mshrs_7.REG_2;
    force u_i2.u_core.mshrCtl.u_core.mshrs[7].entry.u_core.REG_3 = u_g2.mshrCtl.mshrs_7.REG_3;
    force u_i2.u_core.mshrCtl.u_core.mshrs[8].entry.u_core.tgtid_rcompack = u_g2.mshrCtl.mshrs_8.tgtid_rcompack;
    force u_i2.u_core.mshrCtl.u_core.mshrs[8].entry.u_core.txnid_rcompack = u_g2.mshrCtl.mshrs_8.txnid_rcompack;
    force u_i2.u_core.mshrCtl.u_core.mshrs[8].entry.u_core.tgtid_wcompack = u_g2.mshrCtl.mshrs_8.tgtid_wcompack;
    force u_i2.u_core.mshrCtl.u_core.mshrs[8].entry.u_core.txnid_wcompack = u_g2.mshrCtl.mshrs_8.txnid_wcompack;
    force u_i2.u_core.mshrCtl.u_core.mshrs[8].entry.u_core.srcid_retryack = u_g2.mshrCtl.mshrs_8.srcid_retryack;
    force u_i2.u_core.mshrCtl.u_core.mshrs[8].entry.u_core.acquire_ts = u_g2.mshrCtl.mshrs_8.acquire_ts;
    force u_i2.u_core.mshrCtl.u_core.mshrs[8].entry.u_core.release_ts = u_g2.mshrCtl.mshrs_8.release_ts;
    force u_i2.u_core.mshrCtl.u_core.mshrs[8].entry.u_core.acquire_period_valid_REG = u_g2.mshrCtl.mshrs_8.acquire_period_valid_REG;
    force u_i2.u_core.mshrCtl.u_core.mshrs[8].entry.u_core.release_period_valid_REG = u_g2.mshrCtl.mshrs_8.release_period_valid_REG;
    force u_i2.u_core.mshrCtl.u_core.mshrs[8].entry.u_core.REG = u_g2.mshrCtl.mshrs_8.REG;
    force u_i2.u_core.mshrCtl.u_core.mshrs[8].entry.u_core.REG_1 = u_g2.mshrCtl.mshrs_8.REG_1;
    force u_i2.u_core.mshrCtl.u_core.mshrs[8].entry.u_core.REG_2 = u_g2.mshrCtl.mshrs_8.REG_2;
    force u_i2.u_core.mshrCtl.u_core.mshrs[8].entry.u_core.REG_3 = u_g2.mshrCtl.mshrs_8.REG_3;
    force u_i2.u_core.mshrCtl.u_core.mshrs[9].entry.u_core.tgtid_rcompack = u_g2.mshrCtl.mshrs_9.tgtid_rcompack;
    force u_i2.u_core.mshrCtl.u_core.mshrs[9].entry.u_core.txnid_rcompack = u_g2.mshrCtl.mshrs_9.txnid_rcompack;
    force u_i2.u_core.mshrCtl.u_core.mshrs[9].entry.u_core.tgtid_wcompack = u_g2.mshrCtl.mshrs_9.tgtid_wcompack;
    force u_i2.u_core.mshrCtl.u_core.mshrs[9].entry.u_core.txnid_wcompack = u_g2.mshrCtl.mshrs_9.txnid_wcompack;
    force u_i2.u_core.mshrCtl.u_core.mshrs[9].entry.u_core.srcid_retryack = u_g2.mshrCtl.mshrs_9.srcid_retryack;
    force u_i2.u_core.mshrCtl.u_core.mshrs[9].entry.u_core.acquire_ts = u_g2.mshrCtl.mshrs_9.acquire_ts;
    force u_i2.u_core.mshrCtl.u_core.mshrs[9].entry.u_core.release_ts = u_g2.mshrCtl.mshrs_9.release_ts;
    force u_i2.u_core.mshrCtl.u_core.mshrs[9].entry.u_core.acquire_period_valid_REG = u_g2.mshrCtl.mshrs_9.acquire_period_valid_REG;
    force u_i2.u_core.mshrCtl.u_core.mshrs[9].entry.u_core.release_period_valid_REG = u_g2.mshrCtl.mshrs_9.release_period_valid_REG;
    force u_i2.u_core.mshrCtl.u_core.mshrs[9].entry.u_core.REG = u_g2.mshrCtl.mshrs_9.REG;
    force u_i2.u_core.mshrCtl.u_core.mshrs[9].entry.u_core.REG_1 = u_g2.mshrCtl.mshrs_9.REG_1;
    force u_i2.u_core.mshrCtl.u_core.mshrs[9].entry.u_core.REG_2 = u_g2.mshrCtl.mshrs_9.REG_2;
    force u_i2.u_core.mshrCtl.u_core.mshrs[9].entry.u_core.REG_3 = u_g2.mshrCtl.mshrs_9.REG_3;
    force u_i2.u_core.mshrCtl.u_core.mshrs[10].entry.u_core.tgtid_rcompack = u_g2.mshrCtl.mshrs_10.tgtid_rcompack;
    force u_i2.u_core.mshrCtl.u_core.mshrs[10].entry.u_core.txnid_rcompack = u_g2.mshrCtl.mshrs_10.txnid_rcompack;
    force u_i2.u_core.mshrCtl.u_core.mshrs[10].entry.u_core.tgtid_wcompack = u_g2.mshrCtl.mshrs_10.tgtid_wcompack;
    force u_i2.u_core.mshrCtl.u_core.mshrs[10].entry.u_core.txnid_wcompack = u_g2.mshrCtl.mshrs_10.txnid_wcompack;
    force u_i2.u_core.mshrCtl.u_core.mshrs[10].entry.u_core.srcid_retryack = u_g2.mshrCtl.mshrs_10.srcid_retryack;
    force u_i2.u_core.mshrCtl.u_core.mshrs[10].entry.u_core.acquire_ts = u_g2.mshrCtl.mshrs_10.acquire_ts;
    force u_i2.u_core.mshrCtl.u_core.mshrs[10].entry.u_core.release_ts = u_g2.mshrCtl.mshrs_10.release_ts;
    force u_i2.u_core.mshrCtl.u_core.mshrs[10].entry.u_core.acquire_period_valid_REG = u_g2.mshrCtl.mshrs_10.acquire_period_valid_REG;
    force u_i2.u_core.mshrCtl.u_core.mshrs[10].entry.u_core.release_period_valid_REG = u_g2.mshrCtl.mshrs_10.release_period_valid_REG;
    force u_i2.u_core.mshrCtl.u_core.mshrs[10].entry.u_core.REG = u_g2.mshrCtl.mshrs_10.REG;
    force u_i2.u_core.mshrCtl.u_core.mshrs[10].entry.u_core.REG_1 = u_g2.mshrCtl.mshrs_10.REG_1;
    force u_i2.u_core.mshrCtl.u_core.mshrs[10].entry.u_core.REG_2 = u_g2.mshrCtl.mshrs_10.REG_2;
    force u_i2.u_core.mshrCtl.u_core.mshrs[10].entry.u_core.REG_3 = u_g2.mshrCtl.mshrs_10.REG_3;
    force u_i2.u_core.mshrCtl.u_core.mshrs[11].entry.u_core.tgtid_rcompack = u_g2.mshrCtl.mshrs_11.tgtid_rcompack;
    force u_i2.u_core.mshrCtl.u_core.mshrs[11].entry.u_core.txnid_rcompack = u_g2.mshrCtl.mshrs_11.txnid_rcompack;
    force u_i2.u_core.mshrCtl.u_core.mshrs[11].entry.u_core.tgtid_wcompack = u_g2.mshrCtl.mshrs_11.tgtid_wcompack;
    force u_i2.u_core.mshrCtl.u_core.mshrs[11].entry.u_core.txnid_wcompack = u_g2.mshrCtl.mshrs_11.txnid_wcompack;
    force u_i2.u_core.mshrCtl.u_core.mshrs[11].entry.u_core.srcid_retryack = u_g2.mshrCtl.mshrs_11.srcid_retryack;
    force u_i2.u_core.mshrCtl.u_core.mshrs[11].entry.u_core.acquire_ts = u_g2.mshrCtl.mshrs_11.acquire_ts;
    force u_i2.u_core.mshrCtl.u_core.mshrs[11].entry.u_core.release_ts = u_g2.mshrCtl.mshrs_11.release_ts;
    force u_i2.u_core.mshrCtl.u_core.mshrs[11].entry.u_core.acquire_period_valid_REG = u_g2.mshrCtl.mshrs_11.acquire_period_valid_REG;
    force u_i2.u_core.mshrCtl.u_core.mshrs[11].entry.u_core.release_period_valid_REG = u_g2.mshrCtl.mshrs_11.release_period_valid_REG;
    force u_i2.u_core.mshrCtl.u_core.mshrs[11].entry.u_core.REG = u_g2.mshrCtl.mshrs_11.REG;
    force u_i2.u_core.mshrCtl.u_core.mshrs[11].entry.u_core.REG_1 = u_g2.mshrCtl.mshrs_11.REG_1;
    force u_i2.u_core.mshrCtl.u_core.mshrs[11].entry.u_core.REG_2 = u_g2.mshrCtl.mshrs_11.REG_2;
    force u_i2.u_core.mshrCtl.u_core.mshrs[11].entry.u_core.REG_3 = u_g2.mshrCtl.mshrs_11.REG_3;
    force u_i2.u_core.mshrCtl.u_core.mshrs[12].entry.u_core.tgtid_rcompack = u_g2.mshrCtl.mshrs_12.tgtid_rcompack;
    force u_i2.u_core.mshrCtl.u_core.mshrs[12].entry.u_core.txnid_rcompack = u_g2.mshrCtl.mshrs_12.txnid_rcompack;
    force u_i2.u_core.mshrCtl.u_core.mshrs[12].entry.u_core.tgtid_wcompack = u_g2.mshrCtl.mshrs_12.tgtid_wcompack;
    force u_i2.u_core.mshrCtl.u_core.mshrs[12].entry.u_core.txnid_wcompack = u_g2.mshrCtl.mshrs_12.txnid_wcompack;
    force u_i2.u_core.mshrCtl.u_core.mshrs[12].entry.u_core.srcid_retryack = u_g2.mshrCtl.mshrs_12.srcid_retryack;
    force u_i2.u_core.mshrCtl.u_core.mshrs[12].entry.u_core.acquire_ts = u_g2.mshrCtl.mshrs_12.acquire_ts;
    force u_i2.u_core.mshrCtl.u_core.mshrs[12].entry.u_core.release_ts = u_g2.mshrCtl.mshrs_12.release_ts;
    force u_i2.u_core.mshrCtl.u_core.mshrs[12].entry.u_core.acquire_period_valid_REG = u_g2.mshrCtl.mshrs_12.acquire_period_valid_REG;
    force u_i2.u_core.mshrCtl.u_core.mshrs[12].entry.u_core.release_period_valid_REG = u_g2.mshrCtl.mshrs_12.release_period_valid_REG;
    force u_i2.u_core.mshrCtl.u_core.mshrs[12].entry.u_core.REG = u_g2.mshrCtl.mshrs_12.REG;
    force u_i2.u_core.mshrCtl.u_core.mshrs[12].entry.u_core.REG_1 = u_g2.mshrCtl.mshrs_12.REG_1;
    force u_i2.u_core.mshrCtl.u_core.mshrs[12].entry.u_core.REG_2 = u_g2.mshrCtl.mshrs_12.REG_2;
    force u_i2.u_core.mshrCtl.u_core.mshrs[12].entry.u_core.REG_3 = u_g2.mshrCtl.mshrs_12.REG_3;
    force u_i2.u_core.mshrCtl.u_core.mshrs[13].entry.u_core.tgtid_rcompack = u_g2.mshrCtl.mshrs_13.tgtid_rcompack;
    force u_i2.u_core.mshrCtl.u_core.mshrs[13].entry.u_core.txnid_rcompack = u_g2.mshrCtl.mshrs_13.txnid_rcompack;
    force u_i2.u_core.mshrCtl.u_core.mshrs[13].entry.u_core.tgtid_wcompack = u_g2.mshrCtl.mshrs_13.tgtid_wcompack;
    force u_i2.u_core.mshrCtl.u_core.mshrs[13].entry.u_core.txnid_wcompack = u_g2.mshrCtl.mshrs_13.txnid_wcompack;
    force u_i2.u_core.mshrCtl.u_core.mshrs[13].entry.u_core.srcid_retryack = u_g2.mshrCtl.mshrs_13.srcid_retryack;
    force u_i2.u_core.mshrCtl.u_core.mshrs[13].entry.u_core.acquire_ts = u_g2.mshrCtl.mshrs_13.acquire_ts;
    force u_i2.u_core.mshrCtl.u_core.mshrs[13].entry.u_core.release_ts = u_g2.mshrCtl.mshrs_13.release_ts;
    force u_i2.u_core.mshrCtl.u_core.mshrs[13].entry.u_core.acquire_period_valid_REG = u_g2.mshrCtl.mshrs_13.acquire_period_valid_REG;
    force u_i2.u_core.mshrCtl.u_core.mshrs[13].entry.u_core.release_period_valid_REG = u_g2.mshrCtl.mshrs_13.release_period_valid_REG;
    force u_i2.u_core.mshrCtl.u_core.mshrs[13].entry.u_core.REG = u_g2.mshrCtl.mshrs_13.REG;
    force u_i2.u_core.mshrCtl.u_core.mshrs[13].entry.u_core.REG_1 = u_g2.mshrCtl.mshrs_13.REG_1;
    force u_i2.u_core.mshrCtl.u_core.mshrs[13].entry.u_core.REG_2 = u_g2.mshrCtl.mshrs_13.REG_2;
    force u_i2.u_core.mshrCtl.u_core.mshrs[13].entry.u_core.REG_3 = u_g2.mshrCtl.mshrs_13.REG_3;
    force u_i2.u_core.mshrCtl.u_core.mshrs[14].entry.u_core.tgtid_rcompack = u_g2.mshrCtl.mshrs_14.tgtid_rcompack;
    force u_i2.u_core.mshrCtl.u_core.mshrs[14].entry.u_core.txnid_rcompack = u_g2.mshrCtl.mshrs_14.txnid_rcompack;
    force u_i2.u_core.mshrCtl.u_core.mshrs[14].entry.u_core.tgtid_wcompack = u_g2.mshrCtl.mshrs_14.tgtid_wcompack;
    force u_i2.u_core.mshrCtl.u_core.mshrs[14].entry.u_core.txnid_wcompack = u_g2.mshrCtl.mshrs_14.txnid_wcompack;
    force u_i2.u_core.mshrCtl.u_core.mshrs[14].entry.u_core.srcid_retryack = u_g2.mshrCtl.mshrs_14.srcid_retryack;
    force u_i2.u_core.mshrCtl.u_core.mshrs[14].entry.u_core.acquire_ts = u_g2.mshrCtl.mshrs_14.acquire_ts;
    force u_i2.u_core.mshrCtl.u_core.mshrs[14].entry.u_core.release_ts = u_g2.mshrCtl.mshrs_14.release_ts;
    force u_i2.u_core.mshrCtl.u_core.mshrs[14].entry.u_core.acquire_period_valid_REG = u_g2.mshrCtl.mshrs_14.acquire_period_valid_REG;
    force u_i2.u_core.mshrCtl.u_core.mshrs[14].entry.u_core.release_period_valid_REG = u_g2.mshrCtl.mshrs_14.release_period_valid_REG;
    force u_i2.u_core.mshrCtl.u_core.mshrs[14].entry.u_core.REG = u_g2.mshrCtl.mshrs_14.REG;
    force u_i2.u_core.mshrCtl.u_core.mshrs[14].entry.u_core.REG_1 = u_g2.mshrCtl.mshrs_14.REG_1;
    force u_i2.u_core.mshrCtl.u_core.mshrs[14].entry.u_core.REG_2 = u_g2.mshrCtl.mshrs_14.REG_2;
    force u_i2.u_core.mshrCtl.u_core.mshrs[14].entry.u_core.REG_3 = u_g2.mshrCtl.mshrs_14.REG_3;
    force u_i2.u_core.mshrCtl.u_core.mshrs[15].entry.u_core.tgtid_rcompack = u_g2.mshrCtl.mshrs_15.tgtid_rcompack;
    force u_i2.u_core.mshrCtl.u_core.mshrs[15].entry.u_core.txnid_rcompack = u_g2.mshrCtl.mshrs_15.txnid_rcompack;
    force u_i2.u_core.mshrCtl.u_core.mshrs[15].entry.u_core.tgtid_wcompack = u_g2.mshrCtl.mshrs_15.tgtid_wcompack;
    force u_i2.u_core.mshrCtl.u_core.mshrs[15].entry.u_core.txnid_wcompack = u_g2.mshrCtl.mshrs_15.txnid_wcompack;
    force u_i2.u_core.mshrCtl.u_core.mshrs[15].entry.u_core.srcid_retryack = u_g2.mshrCtl.mshrs_15.srcid_retryack;
    force u_i2.u_core.mshrCtl.u_core.mshrs[15].entry.u_core.acquire_ts = u_g2.mshrCtl.mshrs_15.acquire_ts;
    force u_i2.u_core.mshrCtl.u_core.mshrs[15].entry.u_core.release_ts = u_g2.mshrCtl.mshrs_15.release_ts;
    force u_i2.u_core.mshrCtl.u_core.mshrs[15].entry.u_core.acquire_period_valid_REG = u_g2.mshrCtl.mshrs_15.acquire_period_valid_REG;
    force u_i2.u_core.mshrCtl.u_core.mshrs[15].entry.u_core.release_period_valid_REG = u_g2.mshrCtl.mshrs_15.release_period_valid_REG;
    force u_i2.u_core.mshrCtl.u_core.mshrs[15].entry.u_core.REG = u_g2.mshrCtl.mshrs_15.REG;
    force u_i2.u_core.mshrCtl.u_core.mshrs[15].entry.u_core.REG_1 = u_g2.mshrCtl.mshrs_15.REG_1;
    force u_i2.u_core.mshrCtl.u_core.mshrs[15].entry.u_core.REG_2 = u_g2.mshrCtl.mshrs_15.REG_2;
    force u_i2.u_core.mshrCtl.u_core.mshrs[15].entry.u_core.REG_3 = u_g2.mshrCtl.mshrs_15.REG_3;
    force u_i2.u_core.mshrCtl.u_core.io_perf_0_value_REG = u_g2.mshrCtl.io_perf_0_value_REG;
    force u_i2.u_core.mshrCtl.u_core.io_perf_0_value_REG_1 = u_g2.mshrCtl.io_perf_0_value_REG_1;
    force u_i2.u_core.mshrCtl.u_core.io_perf_1_value_REG = u_g2.mshrCtl.io_perf_1_value_REG;
    force u_i2.u_core.mshrCtl.u_core.io_perf_1_value_REG_1 = u_g2.mshrCtl.io_perf_1_value_REG_1;
    force u_i2.u_core.mshrCtl.u_core.io_perf_3_value_REG = u_g2.mshrCtl.io_perf_3_value_REG;
    force u_i2.u_core.mshrCtl.u_core.io_perf_3_value_REG_1 = u_g2.mshrCtl.io_perf_3_value_REG_1;
    force u_i2.u_core.mshrCtl.u_core.REG = u_g2.mshrCtl.REG;
    force u_i2.u_core.mainPipe.u_core.data_s4 = u_g2.mainPipe.data_s4;
    force u_i2.u_core.mainPipe.u_core.data_s5 = u_g2.mainPipe.data_s5;
    force u_i2.u_core.mainPipe.u_core.s3DropValid_d1 = u_g2.mainPipe.REG;
    force u_i2.u_core.mainPipe.u_core.reqDrop_s3_d1 = u_g2.mainPipe.reqDropped_s5_REG;
    force u_i2.u_core.mainPipe.u_core.reqDrop_s3_d2 = u_g2.mainPipe.reqDropped_s5_REG_1;
    force u_i2.u_core.mainPipe.u_core.reqDrop_s4_d1 = u_g2.mainPipe.reqDropped_s5_REG_2;
    u_i2.u_core.mainPipe.customL1Hint.hintQueue.ram_ext.Memory = u_g2.mainPipe.customL1Hint.hintQueue.ram_ext.Memory;
    u_i2.u_core.mainPipe.customL1Hint.hint_s1Queue.ram_ext.Memory = u_g2.mainPipe.customL1Hint.hint_s1Queue.ram_ext.Memory;
    force u_i2.u_core.mainPipe.u_core.perf_d1[0] = u_g2.mainPipe.io_perf_0_value_REG;
    force u_i2.u_core.mainPipe.u_core.perf[0] = u_g2.mainPipe.io_perf_0_value_REG_1;
    force u_i2.u_core.mainPipe.u_core.perf_d1[1] = u_g2.mainPipe.io_perf_1_value_REG;
    force u_i2.u_core.mainPipe.u_core.perf[1] = u_g2.mainPipe.io_perf_1_value_REG_1;
    force u_i2.u_core.mainPipe.u_core.perf_d1[2] = u_g2.mainPipe.io_perf_2_value_REG;
    force u_i2.u_core.mainPipe.u_core.perf[2] = u_g2.mainPipe.io_perf_2_value_REG_1;
    force u_i2.u_core.mainPipe.u_core.perf_d1[3] = u_g2.mainPipe.io_perf_3_value_REG;
    force u_i2.u_core.mainPipe.u_core.perf[3] = u_g2.mainPipe.io_perf_3_value_REG_1;
    force u_i2.u_core.mainPipe.u_core.perf_d1[4] = u_g2.mainPipe.io_perf_4_value_REG;
    force u_i2.u_core.mainPipe.u_core.perf[4] = u_g2.mainPipe.io_perf_4_value_REG_1;
    force u_i2.u_core.mainPipe.u_core.perf_d1[5] = u_g2.mainPipe.io_perf_5_value_REG;
    force u_i2.u_core.mainPipe.u_core.perf[5] = u_g2.mainPipe.io_perf_5_value_REG_1;
    force u_i2.u_core.mainPipe.u_core.perf_d1[6] = u_g2.mainPipe.io_perf_6_value_REG;
    force u_i2.u_core.mainPipe.u_core.perf[6] = u_g2.mainPipe.io_perf_6_value_REG_1;
    force u_i2.u_core.mainPipe.u_core.perf_d1[7] = u_g2.mainPipe.io_perf_7_value_REG;
    force u_i2.u_core.mainPipe.u_core.perf[7] = u_g2.mainPipe.io_perf_7_value_REG_1;
    force u_i2.u_core.mainPipe.u_core.perf_d1[8] = u_g2.mainPipe.io_perf_8_value_REG;
    force u_i2.u_core.mainPipe.u_core.perf[8] = u_g2.mainPipe.io_perf_8_value_REG_1;
    force u_i2.u_core.mainPipe.u_core.perf_d1[9] = u_g2.mainPipe.io_perf_9_value_REG;
    force u_i2.u_core.mainPipe.u_core.perf[9] = u_g2.mainPipe.io_perf_9_value_REG_1;
    force u_i2.u_core.mainPipe.u_core.perf_d1[10] = u_g2.mainPipe.io_perf_10_value_REG;
    force u_i2.u_core.mainPipe.u_core.perf[10] = u_g2.mainPipe.io_perf_10_value_REG_1;
    force u_i2.u_core.mainPipe.u_core.perf_d1[11] = u_g2.mainPipe.io_perf_11_value_REG;
    force u_i2.u_core.mainPipe.u_core.perf[11] = u_g2.mainPipe.io_perf_11_value_REG_1;
    force u_i2.u_core.mainPipe.u_core.perf_d1[12] = u_g2.mainPipe.io_perf_12_value_REG;
    force u_i2.u_core.mainPipe.u_core.perf[12] = u_g2.mainPipe.io_perf_12_value_REG_1;
    u_i2.u_core.grantBuf.grantQueue.ram_ext.Memory = u_g2.grantBuf.grantQueue.ram_ext.Memory;
    u_i2.u_core.grantBuf.grantQueueData0.ram_data_data_ext.Memory = u_g2.grantBuf.grantQueueData0.ram_data_data_ext.Memory;
    u_i2.u_core.grantBuf.grantQueueData1.ram_data_data_ext.Memory = u_g2.grantBuf.grantQueueData1.ram_data_data_ext.Memory;
    u_i2.u_core.grantBuf.pftRespQueue.ram_ext.Memory = u_g2.grantBuf.pftRespQueue.ram_ext.Memory;
    force u_i2.u_core.grantBuf.u_core.validPrev[0] = u_g2.grantBuf.REG;
    force u_i2.u_core.grantBuf.u_core.histValidPrev[0] = u_g2.grantBuf.enable_REG;
    force u_i2.u_core.grantBuf.u_core.validPrev[1] = u_g2.grantBuf.REG_1;
    force u_i2.u_core.grantBuf.u_core.histValidPrev[1] = u_g2.grantBuf.enable_REG_1;
    force u_i2.u_core.grantBuf.u_core.validPrev[2] = u_g2.grantBuf.REG_2;
    force u_i2.u_core.grantBuf.u_core.histValidPrev[2] = u_g2.grantBuf.enable_REG_2;
    force u_i2.u_core.grantBuf.u_core.validPrev[3] = u_g2.grantBuf.REG_3;
    force u_i2.u_core.grantBuf.u_core.histValidPrev[3] = u_g2.grantBuf.enable_REG_3;
    force u_i2.u_core.grantBuf.u_core.validPrev[4] = u_g2.grantBuf.REG_4;
    force u_i2.u_core.grantBuf.u_core.histValidPrev[4] = u_g2.grantBuf.enable_REG_4;
    force u_i2.u_core.grantBuf.u_core.validPrev[5] = u_g2.grantBuf.REG_5;
    force u_i2.u_core.grantBuf.u_core.histValidPrev[5] = u_g2.grantBuf.enable_REG_5;
    force u_i2.u_core.grantBuf.u_core.validPrev[6] = u_g2.grantBuf.REG_6;
    force u_i2.u_core.grantBuf.u_core.histValidPrev[6] = u_g2.grantBuf.enable_REG_6;
    force u_i2.u_core.grantBuf.u_core.validPrev[7] = u_g2.grantBuf.REG_7;
    force u_i2.u_core.grantBuf.u_core.histValidPrev[7] = u_g2.grantBuf.enable_REG_7;
    force u_i2.u_core.grantBuf.u_core.validPrev[8] = u_g2.grantBuf.REG_8;
    force u_i2.u_core.grantBuf.u_core.histValidPrev[8] = u_g2.grantBuf.enable_REG_8;
    force u_i2.u_core.grantBuf.u_core.validPrev[9] = u_g2.grantBuf.REG_9;
    force u_i2.u_core.grantBuf.u_core.histValidPrev[9] = u_g2.grantBuf.enable_REG_9;
    force u_i2.u_core.grantBuf.u_core.validPrev[10] = u_g2.grantBuf.REG_10;
    force u_i2.u_core.grantBuf.u_core.histValidPrev[10] = u_g2.grantBuf.enable_REG_10;
    force u_i2.u_core.grantBuf.u_core.validPrev[11] = u_g2.grantBuf.REG_11;
    force u_i2.u_core.grantBuf.u_core.histValidPrev[11] = u_g2.grantBuf.enable_REG_11;
    force u_i2.u_core.grantBuf.u_core.validPrev[12] = u_g2.grantBuf.REG_12;
    force u_i2.u_core.grantBuf.u_core.histValidPrev[12] = u_g2.grantBuf.enable_REG_12;
    force u_i2.u_core.grantBuf.u_core.validPrev[13] = u_g2.grantBuf.REG_13;
    force u_i2.u_core.grantBuf.u_core.histValidPrev[13] = u_g2.grantBuf.enable_REG_13;
    force u_i2.u_core.grantBuf.u_core.validPrev[14] = u_g2.grantBuf.REG_14;
    force u_i2.u_core.grantBuf.u_core.histValidPrev[14] = u_g2.grantBuf.enable_REG_14;
    force u_i2.u_core.grantBuf.u_core.validPrev[15] = u_g2.grantBuf.REG_15;
    force u_i2.u_core.grantBuf.u_core.histValidPrev[15] = u_g2.grantBuf.enable_REG_15;
    u_i2.u_core.rxsnp.queue.ram_ext.Memory = u_g2.rxsnp.queue.ram_ext.Memory;
    force u_i2.u_core.rxsnp.u_core.replPrevForBlock[0] = u_g2.rxsnp.replaceBlockSnpMask_REG;
    force u_i2.u_core.rxsnp.u_core.replPrevForNest[0] = u_g2.rxsnp.replaceNestSnpMask_REG;
    force u_i2.u_core.rxsnp.u_core.replPrevForBlock[1] = u_g2.rxsnp.replaceBlockSnpMask_REG_1;
    force u_i2.u_core.rxsnp.u_core.replPrevForNest[1] = u_g2.rxsnp.replaceNestSnpMask_REG_1;
    force u_i2.u_core.rxsnp.u_core.replPrevForBlock[2] = u_g2.rxsnp.replaceBlockSnpMask_REG_2;
    force u_i2.u_core.rxsnp.u_core.replPrevForNest[2] = u_g2.rxsnp.replaceNestSnpMask_REG_2;
    force u_i2.u_core.rxsnp.u_core.replPrevForBlock[3] = u_g2.rxsnp.replaceBlockSnpMask_REG_3;
    force u_i2.u_core.rxsnp.u_core.replPrevForNest[3] = u_g2.rxsnp.replaceNestSnpMask_REG_3;
    force u_i2.u_core.rxsnp.u_core.replPrevForBlock[4] = u_g2.rxsnp.replaceBlockSnpMask_REG_4;
    force u_i2.u_core.rxsnp.u_core.replPrevForNest[4] = u_g2.rxsnp.replaceNestSnpMask_REG_4;
    force u_i2.u_core.rxsnp.u_core.replPrevForBlock[5] = u_g2.rxsnp.replaceBlockSnpMask_REG_5;
    force u_i2.u_core.rxsnp.u_core.replPrevForNest[5] = u_g2.rxsnp.replaceNestSnpMask_REG_5;
    force u_i2.u_core.rxsnp.u_core.replPrevForBlock[6] = u_g2.rxsnp.replaceBlockSnpMask_REG_6;
    force u_i2.u_core.rxsnp.u_core.replPrevForNest[6] = u_g2.rxsnp.replaceNestSnpMask_REG_6;
    force u_i2.u_core.rxsnp.u_core.replPrevForBlock[7] = u_g2.rxsnp.replaceBlockSnpMask_REG_7;
    force u_i2.u_core.rxsnp.u_core.replPrevForNest[7] = u_g2.rxsnp.replaceNestSnpMask_REG_7;
    force u_i2.u_core.rxsnp.u_core.replPrevForBlock[8] = u_g2.rxsnp.replaceBlockSnpMask_REG_8;
    force u_i2.u_core.rxsnp.u_core.replPrevForNest[8] = u_g2.rxsnp.replaceNestSnpMask_REG_8;
    force u_i2.u_core.rxsnp.u_core.replPrevForBlock[9] = u_g2.rxsnp.replaceBlockSnpMask_REG_9;
    force u_i2.u_core.rxsnp.u_core.replPrevForNest[9] = u_g2.rxsnp.replaceNestSnpMask_REG_9;
    force u_i2.u_core.rxsnp.u_core.replPrevForBlock[10] = u_g2.rxsnp.replaceBlockSnpMask_REG_10;
    force u_i2.u_core.rxsnp.u_core.replPrevForNest[10] = u_g2.rxsnp.replaceNestSnpMask_REG_10;
    force u_i2.u_core.rxsnp.u_core.replPrevForBlock[11] = u_g2.rxsnp.replaceBlockSnpMask_REG_11;
    force u_i2.u_core.rxsnp.u_core.replPrevForNest[11] = u_g2.rxsnp.replaceNestSnpMask_REG_11;
    force u_i2.u_core.rxsnp.u_core.replPrevForBlock[12] = u_g2.rxsnp.replaceBlockSnpMask_REG_12;
    force u_i2.u_core.rxsnp.u_core.replPrevForNest[12] = u_g2.rxsnp.replaceNestSnpMask_REG_12;
    force u_i2.u_core.rxsnp.u_core.replPrevForBlock[13] = u_g2.rxsnp.replaceBlockSnpMask_REG_13;
    force u_i2.u_core.rxsnp.u_core.replPrevForNest[13] = u_g2.rxsnp.replaceNestSnpMask_REG_13;
    force u_i2.u_core.rxsnp.u_core.replPrevForBlock[14] = u_g2.rxsnp.replaceBlockSnpMask_REG_14;
    force u_i2.u_core.rxsnp.u_core.replPrevForNest[14] = u_g2.rxsnp.replaceNestSnpMask_REG_14;
    force u_i2.u_core.rxsnp.u_core.replPrevForBlock[15] = u_g2.rxsnp.replaceBlockSnpMask_REG_15;
    force u_i2.u_core.rxsnp.u_core.replPrevForNest[15] = u_g2.rxsnp.replaceNestSnpMask_REG_15;
    force u_i2.u_core.reqBuf.chosenQ.u_core.ram = u_g2.reqBuf.chosenQ.ram;
    force u_i2.u_core.reqBuf.u_core.hitPfPrev_set = u_g2.reqBuf.io_hasHitPfInMSHR_valid_REG_set;
    force u_i2.u_core.reqBuf.u_core.hitPfPrev_tag = u_g2.reqBuf.io_hasHitPfInMSHR_valid_REG_tag;
    force u_i2.u_core.reqBuf.u_core.mergeAPrev_set = u_g2.reqBuf.io_hasMergeA_REG_set;
    force u_i2.u_core.reqBuf.u_core.mergeAPrev_tag = u_g2.reqBuf.io_hasMergeA_REG_tag;
    force u_i2.u_core.reqBuf.u_core.sameSetS3Valid[0] = u_g2.reqBuf.canFlow_sameSet_s3_REG;
    force u_i2.u_core.reqBuf.u_core.sameSetS3Set[0] = u_g2.reqBuf.canFlow_sameSet_s3_r;
    force u_i2.u_core.reqBuf.u_core.sameSetS3Valid[1] = u_g2.reqBuf.buffer_rdy_sameSet_s3_REG;
    force u_i2.u_core.reqBuf.u_core.sameSetS3Set[1] = u_g2.reqBuf.buffer_rdy_sameSet_s3_r;
    force u_i2.u_core.reqBuf.u_core.sameSetS3Valid[2] = u_g2.reqBuf.buffer_0_rdy_sameSet_s3_REG;
    force u_i2.u_core.reqBuf.u_core.sameSetS3Set[2] = u_g2.reqBuf.buffer_0_rdy_sameSet_s3_r;
    force u_i2.u_core.reqBuf.u_core.sameSetS3Valid[3] = u_g2.reqBuf.buffer_1_rdy_sameSet_s3_REG;
    force u_i2.u_core.reqBuf.u_core.sameSetS3Set[3] = u_g2.reqBuf.buffer_1_rdy_sameSet_s3_r;
    force u_i2.u_core.reqBuf.u_core.sameSetS3Valid[4] = u_g2.reqBuf.buffer_2_rdy_sameSet_s3_REG;
    force u_i2.u_core.reqBuf.u_core.sameSetS3Set[4] = u_g2.reqBuf.buffer_2_rdy_sameSet_s3_r;
    force u_i2.u_core.reqBuf.u_core.sameSetS3Valid[5] = u_g2.reqBuf.buffer_3_rdy_sameSet_s3_REG;
    force u_i2.u_core.reqBuf.u_core.sameSetS3Set[5] = u_g2.reqBuf.buffer_3_rdy_sameSet_s3_r;
    force u_i2.u_core.sinkC.u_core.bufRespStage[0] = u_g2.sinkC.r_0;
    force u_i2.u_core.sinkC.u_core.bufRespStage[1] = u_g2.sinkC.r_1;
    force u_i2.u_core.sinkC.u_core.bufRespOut[0] = u_g2.sinkC.REG_0;
    force u_i2.u_core.sinkC.u_core.bufRespOut[1] = u_g2.sinkC.REG_1;
    force u_i2.u_core.sinkC.u_core.refillIdReg = u_g2.sinkC.io_refillBufWrite_bits_id_REG;
    force u_i2.u_core.sinkC.u_core.refillBufIdxReg = u_g2.sinkC.io_refillBufWrite_bits_data_data_REG;
    force u_i2.u_core.sinkC.u_core.taskFirePrev = u_g2.sinkC.REG_1_0;
    force u_i2.u_core.sinkC.u_core.taskBufIdxPrev = u_g2.sinkC.REG_2;
    force u_i2.u_core.reqArb.u_core.ds_mcp2_stall = u_g2.reqArb.ds_mcp2_stall;
    force u_i2.u_core.refillBuf.u_core.buffer[0][0] = u_g2.refillBuf.buffer_0_0;
    force u_i2.u_core.refillBuf.u_core.buffer[0][1] = u_g2.refillBuf.buffer_0_1;
    force u_i2.u_core.refillBuf.u_core.buffer[1][0] = u_g2.refillBuf.buffer_1_0;
    force u_i2.u_core.refillBuf.u_core.buffer[1][1] = u_g2.refillBuf.buffer_1_1;
    force u_i2.u_core.refillBuf.u_core.buffer[2][0] = u_g2.refillBuf.buffer_2_0;
    force u_i2.u_core.refillBuf.u_core.buffer[2][1] = u_g2.refillBuf.buffer_2_1;
    force u_i2.u_core.refillBuf.u_core.buffer[3][0] = u_g2.refillBuf.buffer_3_0;
    force u_i2.u_core.refillBuf.u_core.buffer[3][1] = u_g2.refillBuf.buffer_3_1;
    force u_i2.u_core.refillBuf.u_core.buffer[4][0] = u_g2.refillBuf.buffer_4_0;
    force u_i2.u_core.refillBuf.u_core.buffer[4][1] = u_g2.refillBuf.buffer_4_1;
    force u_i2.u_core.refillBuf.u_core.buffer[5][0] = u_g2.refillBuf.buffer_5_0;
    force u_i2.u_core.refillBuf.u_core.buffer[5][1] = u_g2.refillBuf.buffer_5_1;
    force u_i2.u_core.refillBuf.u_core.buffer[6][0] = u_g2.refillBuf.buffer_6_0;
    force u_i2.u_core.refillBuf.u_core.buffer[6][1] = u_g2.refillBuf.buffer_6_1;
    force u_i2.u_core.refillBuf.u_core.buffer[7][0] = u_g2.refillBuf.buffer_7_0;
    force u_i2.u_core.refillBuf.u_core.buffer[7][1] = u_g2.refillBuf.buffer_7_1;
    force u_i2.u_core.refillBuf.u_core.buffer[8][0] = u_g2.refillBuf.buffer_8_0;
    force u_i2.u_core.refillBuf.u_core.buffer[8][1] = u_g2.refillBuf.buffer_8_1;
    force u_i2.u_core.refillBuf.u_core.buffer[9][0] = u_g2.refillBuf.buffer_9_0;
    force u_i2.u_core.refillBuf.u_core.buffer[9][1] = u_g2.refillBuf.buffer_9_1;
    force u_i2.u_core.refillBuf.u_core.buffer[10][0] = u_g2.refillBuf.buffer_10_0;
    force u_i2.u_core.refillBuf.u_core.buffer[10][1] = u_g2.refillBuf.buffer_10_1;
    force u_i2.u_core.refillBuf.u_core.buffer[11][0] = u_g2.refillBuf.buffer_11_0;
    force u_i2.u_core.refillBuf.u_core.buffer[11][1] = u_g2.refillBuf.buffer_11_1;
    force u_i2.u_core.refillBuf.u_core.buffer[12][0] = u_g2.refillBuf.buffer_12_0;
    force u_i2.u_core.refillBuf.u_core.buffer[12][1] = u_g2.refillBuf.buffer_12_1;
    force u_i2.u_core.refillBuf.u_core.buffer[13][0] = u_g2.refillBuf.buffer_13_0;
    force u_i2.u_core.refillBuf.u_core.buffer[13][1] = u_g2.refillBuf.buffer_13_1;
    force u_i2.u_core.refillBuf.u_core.buffer[14][0] = u_g2.refillBuf.buffer_14_0;
    force u_i2.u_core.refillBuf.u_core.buffer[14][1] = u_g2.refillBuf.buffer_14_1;
    force u_i2.u_core.refillBuf.u_core.buffer[15][0] = u_g2.refillBuf.buffer_15_0;
    force u_i2.u_core.refillBuf.u_core.buffer[15][1] = u_g2.refillBuf.buffer_15_1;
    force u_i2.u_core.releaseBuf.u_core.buffer[0][0] = u_g2.releaseBuf.buffer_0_0;
    force u_i2.u_core.releaseBuf.u_core.buffer[0][1] = u_g2.releaseBuf.buffer_0_1;
    force u_i2.u_core.releaseBuf.u_core.buffer[1][0] = u_g2.releaseBuf.buffer_1_0;
    force u_i2.u_core.releaseBuf.u_core.buffer[1][1] = u_g2.releaseBuf.buffer_1_1;
    force u_i2.u_core.releaseBuf.u_core.buffer[2][0] = u_g2.releaseBuf.buffer_2_0;
    force u_i2.u_core.releaseBuf.u_core.buffer[2][1] = u_g2.releaseBuf.buffer_2_1;
    force u_i2.u_core.releaseBuf.u_core.buffer[3][0] = u_g2.releaseBuf.buffer_3_0;
    force u_i2.u_core.releaseBuf.u_core.buffer[3][1] = u_g2.releaseBuf.buffer_3_1;
    force u_i2.u_core.releaseBuf.u_core.buffer[4][0] = u_g2.releaseBuf.buffer_4_0;
    force u_i2.u_core.releaseBuf.u_core.buffer[4][1] = u_g2.releaseBuf.buffer_4_1;
    force u_i2.u_core.releaseBuf.u_core.buffer[5][0] = u_g2.releaseBuf.buffer_5_0;
    force u_i2.u_core.releaseBuf.u_core.buffer[5][1] = u_g2.releaseBuf.buffer_5_1;
    force u_i2.u_core.releaseBuf.u_core.buffer[6][0] = u_g2.releaseBuf.buffer_6_0;
    force u_i2.u_core.releaseBuf.u_core.buffer[6][1] = u_g2.releaseBuf.buffer_6_1;
    force u_i2.u_core.releaseBuf.u_core.buffer[7][0] = u_g2.releaseBuf.buffer_7_0;
    force u_i2.u_core.releaseBuf.u_core.buffer[7][1] = u_g2.releaseBuf.buffer_7_1;
    force u_i2.u_core.releaseBuf.u_core.buffer[8][0] = u_g2.releaseBuf.buffer_8_0;
    force u_i2.u_core.releaseBuf.u_core.buffer[8][1] = u_g2.releaseBuf.buffer_8_1;
    force u_i2.u_core.releaseBuf.u_core.buffer[9][0] = u_g2.releaseBuf.buffer_9_0;
    force u_i2.u_core.releaseBuf.u_core.buffer[9][1] = u_g2.releaseBuf.buffer_9_1;
    force u_i2.u_core.releaseBuf.u_core.buffer[10][0] = u_g2.releaseBuf.buffer_10_0;
    force u_i2.u_core.releaseBuf.u_core.buffer[10][1] = u_g2.releaseBuf.buffer_10_1;
    force u_i2.u_core.releaseBuf.u_core.buffer[11][0] = u_g2.releaseBuf.buffer_11_0;
    force u_i2.u_core.releaseBuf.u_core.buffer[11][1] = u_g2.releaseBuf.buffer_11_1;
    force u_i2.u_core.releaseBuf.u_core.buffer[12][0] = u_g2.releaseBuf.buffer_12_0;
    force u_i2.u_core.releaseBuf.u_core.buffer[12][1] = u_g2.releaseBuf.buffer_12_1;
    force u_i2.u_core.releaseBuf.u_core.buffer[13][0] = u_g2.releaseBuf.buffer_13_0;
    force u_i2.u_core.releaseBuf.u_core.buffer[13][1] = u_g2.releaseBuf.buffer_13_1;
    force u_i2.u_core.releaseBuf.u_core.buffer[14][0] = u_g2.releaseBuf.buffer_14_0;
    force u_i2.u_core.releaseBuf.u_core.buffer[14][1] = u_g2.releaseBuf.buffer_14_1;
    force u_i2.u_core.releaseBuf.u_core.buffer[15][0] = u_g2.releaseBuf.buffer_15_0;
    force u_i2.u_core.releaseBuf.u_core.buffer[15][1] = u_g2.releaseBuf.buffer_15_1;
    u_i2.u_core.txdat.queue.ram_ext.Memory = u_g2.txdat.queue.ram_ext.Memory;
    u_i2.u_core.txdat.queueData0.ram_data_ext.Memory = u_g2.txdat.queueData0.ram_data_ext.Memory;
    u_i2.u_core.txdat.queueData1.ram_data_ext.Memory = u_g2.txdat.queueData1.ram_data_ext.Memory;
    u_i2.directory.tagArray.array_0_0_0.array.array.array_14_ext.ram = u_g2.directory.tagArray.array_0_0_0.array.array.array_14_ext.ram;
    u_i2.directory.tagArray.array_0_0_0.array.array.array_14_ext.reg_RW0_addr = u_g2.directory.tagArray.array_0_0_0.array.array.array_14_ext.reg_RW0_addr;
    u_i2.directory.tagArray.array_0_0_0.array.array.array_14_ext.reg_RW0_ren = u_g2.directory.tagArray.array_0_0_0.array.array.array_14_ext.reg_RW0_ren;
    force u_i2.directory.tagArray.array_0_0_0.u_core.rdataReg = u_g2.directory.tagArray.array_0_0_0.rdataReg;
    u_i2.directory.tagArray.array_0_0_1.array.array.array_14_ext.ram = u_g2.directory.tagArray.array_0_0_1.array.array.array_14_ext.ram;
    u_i2.directory.tagArray.array_0_0_1.array.array.array_14_ext.reg_RW0_addr = u_g2.directory.tagArray.array_0_0_1.array.array.array_14_ext.reg_RW0_addr;
    u_i2.directory.tagArray.array_0_0_1.array.array.array_14_ext.reg_RW0_ren = u_g2.directory.tagArray.array_0_0_1.array.array.array_14_ext.reg_RW0_ren;
    force u_i2.directory.tagArray.array_0_0_1.u_core.rdataReg = u_g2.directory.tagArray.array_0_0_1.rdataReg;
    u_i2.directory.tagArray.array_0_1_0.array.array.array_14_ext.ram = u_g2.directory.tagArray.array_0_1_0.array.array.array_14_ext.ram;
    u_i2.directory.tagArray.array_0_1_0.array.array.array_14_ext.reg_RW0_addr = u_g2.directory.tagArray.array_0_1_0.array.array.array_14_ext.reg_RW0_addr;
    u_i2.directory.tagArray.array_0_1_0.array.array.array_14_ext.reg_RW0_ren = u_g2.directory.tagArray.array_0_1_0.array.array.array_14_ext.reg_RW0_ren;
    force u_i2.directory.tagArray.array_0_1_0.u_core.rdataReg = u_g2.directory.tagArray.array_0_1_0.rdataReg;
    u_i2.directory.tagArray.array_0_1_1.array.array.array_14_ext.ram = u_g2.directory.tagArray.array_0_1_1.array.array.array_14_ext.ram;
    u_i2.directory.tagArray.array_0_1_1.array.array.array_14_ext.reg_RW0_addr = u_g2.directory.tagArray.array_0_1_1.array.array.array_14_ext.reg_RW0_addr;
    u_i2.directory.tagArray.array_0_1_1.array.array.array_14_ext.reg_RW0_ren = u_g2.directory.tagArray.array_0_1_1.array.array.array_14_ext.reg_RW0_ren;
    force u_i2.directory.tagArray.array_0_1_1.u_core.rdataReg = u_g2.directory.tagArray.array_0_1_1.rdataReg;
    u_i2.directory.metaArray.array.array.array_15_ext.ram = u_g2.directory.metaArray.array.array.array_15_ext.ram;
    u_i2.directory.metaArray.array.array.array_15_ext.reg_RW0_addr = u_g2.directory.metaArray.array.array.array_15_ext.reg_RW0_addr;
    u_i2.directory.metaArray.array.array.array_15_ext.reg_RW0_ren = u_g2.directory.metaArray.array.array.array_15_ext.reg_RW0_ren;
    force u_i2.directory.metaArray.u_core.rdataReg = u_g2.directory.metaArray.rdataReg;
    u_i2.directory.replacer_sram_opt.array.array.array_16_ext.ram = u_g2.directory.replacer_sram_opt.array.array.array_16_ext.ram;
    u_i2.directory.replacer_sram_opt.array.array.array_16_ext.reg_RW0_addr = u_g2.directory.replacer_sram_opt.array.array.array_16_ext.reg_RW0_addr;
    u_i2.directory.replacer_sram_opt.array.array.array_16_ext.reg_RW0_ren = u_g2.directory.replacer_sram_opt.array.array.array_16_ext.reg_RW0_ren;
    force u_i2.directory.replacer_sram_opt.u_core.rdataReg = u_g2.directory.replacer_sram_opt.rdataReg;
    u_i2.directory.origin_bit_opt.array.array.array_17_ext.ram = u_g2.directory.origin_bit_opt.array.array.array_17_ext.ram;
    u_i2.directory.origin_bit_opt.array.array.array_17_ext.reg_RW0_addr = u_g2.directory.origin_bit_opt.array.array.array_17_ext.reg_RW0_addr;
    u_i2.directory.origin_bit_opt.array.array.array_17_ext.reg_RW0_ren = u_g2.directory.origin_bit_opt.array.array.array_17_ext.reg_RW0_ren;
    force u_i2.directory.origin_bit_opt.u_core.rdataReg = u_g2.directory.origin_bit_opt.rdataReg;
    u_i2.dataStorage.array.array_0_0_0.array.array.array_18_ext.ram = u_g2.dataStorage.array.array_0_0_0.array.array.array_18_ext.ram;
    u_i2.dataStorage.array.array_0_0_0.array.array.array_18_ext.reg_RW0_addr = u_g2.dataStorage.array.array_0_0_0.array.array.array_18_ext.reg_RW0_addr;
    u_i2.dataStorage.array.array_0_0_0.array.array.array_18_ext.reg_RW0_ren = u_g2.dataStorage.array.array_0_0_0.array.array.array_18_ext.reg_RW0_ren;
    force u_i2.dataStorage.array.array_0_0_0.u_core.rdataReg = u_g2.dataStorage.array.array_0_0_0.rdataReg;
    u_i2.dataStorage.array.array_0_0_1.array.array.array_18_ext.ram = u_g2.dataStorage.array.array_0_0_1.array.array.array_18_ext.ram;
    u_i2.dataStorage.array.array_0_0_1.array.array.array_18_ext.reg_RW0_addr = u_g2.dataStorage.array.array_0_0_1.array.array.array_18_ext.reg_RW0_addr;
    u_i2.dataStorage.array.array_0_0_1.array.array.array_18_ext.reg_RW0_ren = u_g2.dataStorage.array.array_0_0_1.array.array.array_18_ext.reg_RW0_ren;
    force u_i2.dataStorage.array.array_0_0_1.u_core.rdataReg = u_g2.dataStorage.array.array_0_0_1.rdataReg;
    u_i2.dataStorage.array.array_0_0_2.array.array.array_18_ext.ram = u_g2.dataStorage.array.array_0_0_2.array.array.array_18_ext.ram;
    u_i2.dataStorage.array.array_0_0_2.array.array.array_18_ext.reg_RW0_addr = u_g2.dataStorage.array.array_0_0_2.array.array.array_18_ext.reg_RW0_addr;
    u_i2.dataStorage.array.array_0_0_2.array.array.array_18_ext.reg_RW0_ren = u_g2.dataStorage.array.array_0_0_2.array.array.array_18_ext.reg_RW0_ren;
    force u_i2.dataStorage.array.array_0_0_2.u_core.rdataReg = u_g2.dataStorage.array.array_0_0_2.rdataReg;
    u_i2.dataStorage.array.array_0_0_3.array.array.array_18_ext.ram = u_g2.dataStorage.array.array_0_0_3.array.array.array_18_ext.ram;
    u_i2.dataStorage.array.array_0_0_3.array.array.array_18_ext.reg_RW0_addr = u_g2.dataStorage.array.array_0_0_3.array.array.array_18_ext.reg_RW0_addr;
    u_i2.dataStorage.array.array_0_0_3.array.array.array_18_ext.reg_RW0_ren = u_g2.dataStorage.array.array_0_0_3.array.array.array_18_ext.reg_RW0_ren;
    force u_i2.dataStorage.array.array_0_0_3.u_core.rdataReg = u_g2.dataStorage.array.array_0_0_3.rdataReg;
    force u_i2.dataStorage.u_core.error_REG = u_g2.dataStorage.error_REG;
    force u_i2.dataStorage.u_core.error_REG_1 = u_g2.dataStorage.error_REG_1;
    force u_i2.mbistPl.u_core.g_node_return.pipelineDataOutReg = u_g2.mbistPl.pipelineDataOutReg;
    u_i2.u_core.txreq.u_core.queue.ram_ext.Memory = u_g2.txreq.queue.ram_ext.Memory;
    u_i2.u_core.txrsp.u_core.queue.ram_ext.Memory = u_g2.txrsp.queue.ram_ext.Memory;
    force u_i2.u_core.io_error_bits_REG_valid = u_g2.io_error_bits_REG_valid;
    force u_i2.u_core.io_error_bits_REG_address = u_g2.io_error_bits_REG_address;
    force u_i2.u_core.io_perf_0_value_REG = u_g2.io_perf_0_value_REG;
    force u_i2.u_core.io_perf_0_value_REG_1 = u_g2.io_perf_0_value_REG_1;
    force u_i2.u_core.io_perf_1_value_REG = u_g2.io_perf_1_value_REG;
    force u_i2.u_core.io_perf_1_value_REG_1 = u_g2.io_perf_1_value_REG_1;
    force u_i2.u_core.io_perf_3_value_REG = u_g2.io_perf_3_value_REG;
    force u_i2.u_core.io_perf_3_value_REG_1 = u_g2.io_perf_3_value_REG_1;
    force u_i2.u_core.io_perf_4_value_REG = u_g2.io_perf_4_value_REG;
    force u_i2.u_core.io_perf_4_value_REG_1 = u_g2.io_perf_4_value_REG_1;
    force u_i2.u_core.io_perf_5_value_REG = u_g2.io_perf_5_value_REG;
    force u_i2.u_core.io_perf_5_value_REG_1 = u_g2.io_perf_5_value_REG_1;
    force u_i2.u_core.io_perf_6_value_REG = u_g2.io_perf_6_value_REG;
    force u_i2.u_core.io_perf_6_value_REG_1 = u_g2.io_perf_6_value_REG_1;
    force u_i2.u_core.io_perf_7_value_REG = u_g2.io_perf_7_value_REG;
    force u_i2.u_core.io_perf_7_value_REG_1 = u_g2.io_perf_7_value_REG_1;
    force u_i2.u_core.io_perf_8_value_REG = u_g2.io_perf_8_value_REG;
    force u_i2.u_core.io_perf_8_value_REG_1 = u_g2.io_perf_8_value_REG_1;
    force u_i2.u_core.io_perf_9_value_REG = u_g2.io_perf_9_value_REG;
    force u_i2.u_core.io_perf_9_value_REG_1 = u_g2.io_perf_9_value_REG_1;
    force u_i2.u_core.io_perf_10_value_REG = u_g2.io_perf_10_value_REG;
    force u_i2.u_core.io_perf_10_value_REG_1 = u_g2.io_perf_10_value_REG_1;
    force u_i2.u_core.io_perf_11_value_REG = u_g2.io_perf_11_value_REG;
    force u_i2.u_core.io_perf_11_value_REG_1 = u_g2.io_perf_11_value_REG_1;
    force u_i2.u_core.io_perf_12_value_REG = u_g2.io_perf_12_value_REG;
    force u_i2.u_core.io_perf_12_value_REG_1 = u_g2.io_perf_12_value_REG_1;
    force u_i2.u_core.io_perf_13_value_REG = u_g2.io_perf_13_value_REG;
    force u_i2.u_core.io_perf_13_value_REG_1 = u_g2.io_perf_13_value_REG_1;
    force u_i2.u_core.io_perf_14_value_REG = u_g2.io_perf_14_value_REG;
    force u_i2.u_core.io_perf_14_value_REG_1 = u_g2.io_perf_14_value_REG_1;
    force u_i2.u_core.io_perf_15_value_REG = u_g2.io_perf_15_value_REG;
    force u_i2.u_core.io_perf_15_value_REG_1 = u_g2.io_perf_15_value_REG_1;
    force u_i2.u_core.io_perf_16_value_REG = u_g2.io_perf_16_value_REG;
    force u_i2.u_core.io_perf_16_value_REG_1 = u_g2.io_perf_16_value_REG_1;
    force u_i3.u_core.mshrCtl.u_core.mshrs[0].entry.u_core.tgtid_rcompack = u_g3.mshrCtl.mshrs_0.tgtid_rcompack;
    force u_i3.u_core.mshrCtl.u_core.mshrs[0].entry.u_core.txnid_rcompack = u_g3.mshrCtl.mshrs_0.txnid_rcompack;
    force u_i3.u_core.mshrCtl.u_core.mshrs[0].entry.u_core.tgtid_wcompack = u_g3.mshrCtl.mshrs_0.tgtid_wcompack;
    force u_i3.u_core.mshrCtl.u_core.mshrs[0].entry.u_core.txnid_wcompack = u_g3.mshrCtl.mshrs_0.txnid_wcompack;
    force u_i3.u_core.mshrCtl.u_core.mshrs[0].entry.u_core.srcid_retryack = u_g3.mshrCtl.mshrs_0.srcid_retryack;
    force u_i3.u_core.mshrCtl.u_core.mshrs[0].entry.u_core.acquire_ts = u_g3.mshrCtl.mshrs_0.acquire_ts;
    force u_i3.u_core.mshrCtl.u_core.mshrs[0].entry.u_core.release_ts = u_g3.mshrCtl.mshrs_0.release_ts;
    force u_i3.u_core.mshrCtl.u_core.mshrs[0].entry.u_core.acquire_period_valid_REG = u_g3.mshrCtl.mshrs_0.acquire_period_valid_REG;
    force u_i3.u_core.mshrCtl.u_core.mshrs[0].entry.u_core.release_period_valid_REG = u_g3.mshrCtl.mshrs_0.release_period_valid_REG;
    force u_i3.u_core.mshrCtl.u_core.mshrs[0].entry.u_core.REG = u_g3.mshrCtl.mshrs_0.REG;
    force u_i3.u_core.mshrCtl.u_core.mshrs[0].entry.u_core.REG_1 = u_g3.mshrCtl.mshrs_0.REG_1;
    force u_i3.u_core.mshrCtl.u_core.mshrs[0].entry.u_core.REG_2 = u_g3.mshrCtl.mshrs_0.REG_2;
    force u_i3.u_core.mshrCtl.u_core.mshrs[0].entry.u_core.REG_3 = u_g3.mshrCtl.mshrs_0.REG_3;
    force u_i3.u_core.mshrCtl.u_core.mshrs[1].entry.u_core.tgtid_rcompack = u_g3.mshrCtl.mshrs_1.tgtid_rcompack;
    force u_i3.u_core.mshrCtl.u_core.mshrs[1].entry.u_core.txnid_rcompack = u_g3.mshrCtl.mshrs_1.txnid_rcompack;
    force u_i3.u_core.mshrCtl.u_core.mshrs[1].entry.u_core.tgtid_wcompack = u_g3.mshrCtl.mshrs_1.tgtid_wcompack;
    force u_i3.u_core.mshrCtl.u_core.mshrs[1].entry.u_core.txnid_wcompack = u_g3.mshrCtl.mshrs_1.txnid_wcompack;
    force u_i3.u_core.mshrCtl.u_core.mshrs[1].entry.u_core.srcid_retryack = u_g3.mshrCtl.mshrs_1.srcid_retryack;
    force u_i3.u_core.mshrCtl.u_core.mshrs[1].entry.u_core.acquire_ts = u_g3.mshrCtl.mshrs_1.acquire_ts;
    force u_i3.u_core.mshrCtl.u_core.mshrs[1].entry.u_core.release_ts = u_g3.mshrCtl.mshrs_1.release_ts;
    force u_i3.u_core.mshrCtl.u_core.mshrs[1].entry.u_core.acquire_period_valid_REG = u_g3.mshrCtl.mshrs_1.acquire_period_valid_REG;
    force u_i3.u_core.mshrCtl.u_core.mshrs[1].entry.u_core.release_period_valid_REG = u_g3.mshrCtl.mshrs_1.release_period_valid_REG;
    force u_i3.u_core.mshrCtl.u_core.mshrs[1].entry.u_core.REG = u_g3.mshrCtl.mshrs_1.REG;
    force u_i3.u_core.mshrCtl.u_core.mshrs[1].entry.u_core.REG_1 = u_g3.mshrCtl.mshrs_1.REG_1;
    force u_i3.u_core.mshrCtl.u_core.mshrs[1].entry.u_core.REG_2 = u_g3.mshrCtl.mshrs_1.REG_2;
    force u_i3.u_core.mshrCtl.u_core.mshrs[1].entry.u_core.REG_3 = u_g3.mshrCtl.mshrs_1.REG_3;
    force u_i3.u_core.mshrCtl.u_core.mshrs[2].entry.u_core.tgtid_rcompack = u_g3.mshrCtl.mshrs_2.tgtid_rcompack;
    force u_i3.u_core.mshrCtl.u_core.mshrs[2].entry.u_core.txnid_rcompack = u_g3.mshrCtl.mshrs_2.txnid_rcompack;
    force u_i3.u_core.mshrCtl.u_core.mshrs[2].entry.u_core.tgtid_wcompack = u_g3.mshrCtl.mshrs_2.tgtid_wcompack;
    force u_i3.u_core.mshrCtl.u_core.mshrs[2].entry.u_core.txnid_wcompack = u_g3.mshrCtl.mshrs_2.txnid_wcompack;
    force u_i3.u_core.mshrCtl.u_core.mshrs[2].entry.u_core.srcid_retryack = u_g3.mshrCtl.mshrs_2.srcid_retryack;
    force u_i3.u_core.mshrCtl.u_core.mshrs[2].entry.u_core.acquire_ts = u_g3.mshrCtl.mshrs_2.acquire_ts;
    force u_i3.u_core.mshrCtl.u_core.mshrs[2].entry.u_core.release_ts = u_g3.mshrCtl.mshrs_2.release_ts;
    force u_i3.u_core.mshrCtl.u_core.mshrs[2].entry.u_core.acquire_period_valid_REG = u_g3.mshrCtl.mshrs_2.acquire_period_valid_REG;
    force u_i3.u_core.mshrCtl.u_core.mshrs[2].entry.u_core.release_period_valid_REG = u_g3.mshrCtl.mshrs_2.release_period_valid_REG;
    force u_i3.u_core.mshrCtl.u_core.mshrs[2].entry.u_core.REG = u_g3.mshrCtl.mshrs_2.REG;
    force u_i3.u_core.mshrCtl.u_core.mshrs[2].entry.u_core.REG_1 = u_g3.mshrCtl.mshrs_2.REG_1;
    force u_i3.u_core.mshrCtl.u_core.mshrs[2].entry.u_core.REG_2 = u_g3.mshrCtl.mshrs_2.REG_2;
    force u_i3.u_core.mshrCtl.u_core.mshrs[2].entry.u_core.REG_3 = u_g3.mshrCtl.mshrs_2.REG_3;
    force u_i3.u_core.mshrCtl.u_core.mshrs[3].entry.u_core.tgtid_rcompack = u_g3.mshrCtl.mshrs_3.tgtid_rcompack;
    force u_i3.u_core.mshrCtl.u_core.mshrs[3].entry.u_core.txnid_rcompack = u_g3.mshrCtl.mshrs_3.txnid_rcompack;
    force u_i3.u_core.mshrCtl.u_core.mshrs[3].entry.u_core.tgtid_wcompack = u_g3.mshrCtl.mshrs_3.tgtid_wcompack;
    force u_i3.u_core.mshrCtl.u_core.mshrs[3].entry.u_core.txnid_wcompack = u_g3.mshrCtl.mshrs_3.txnid_wcompack;
    force u_i3.u_core.mshrCtl.u_core.mshrs[3].entry.u_core.srcid_retryack = u_g3.mshrCtl.mshrs_3.srcid_retryack;
    force u_i3.u_core.mshrCtl.u_core.mshrs[3].entry.u_core.acquire_ts = u_g3.mshrCtl.mshrs_3.acquire_ts;
    force u_i3.u_core.mshrCtl.u_core.mshrs[3].entry.u_core.release_ts = u_g3.mshrCtl.mshrs_3.release_ts;
    force u_i3.u_core.mshrCtl.u_core.mshrs[3].entry.u_core.acquire_period_valid_REG = u_g3.mshrCtl.mshrs_3.acquire_period_valid_REG;
    force u_i3.u_core.mshrCtl.u_core.mshrs[3].entry.u_core.release_period_valid_REG = u_g3.mshrCtl.mshrs_3.release_period_valid_REG;
    force u_i3.u_core.mshrCtl.u_core.mshrs[3].entry.u_core.REG = u_g3.mshrCtl.mshrs_3.REG;
    force u_i3.u_core.mshrCtl.u_core.mshrs[3].entry.u_core.REG_1 = u_g3.mshrCtl.mshrs_3.REG_1;
    force u_i3.u_core.mshrCtl.u_core.mshrs[3].entry.u_core.REG_2 = u_g3.mshrCtl.mshrs_3.REG_2;
    force u_i3.u_core.mshrCtl.u_core.mshrs[3].entry.u_core.REG_3 = u_g3.mshrCtl.mshrs_3.REG_3;
    force u_i3.u_core.mshrCtl.u_core.mshrs[4].entry.u_core.tgtid_rcompack = u_g3.mshrCtl.mshrs_4.tgtid_rcompack;
    force u_i3.u_core.mshrCtl.u_core.mshrs[4].entry.u_core.txnid_rcompack = u_g3.mshrCtl.mshrs_4.txnid_rcompack;
    force u_i3.u_core.mshrCtl.u_core.mshrs[4].entry.u_core.tgtid_wcompack = u_g3.mshrCtl.mshrs_4.tgtid_wcompack;
    force u_i3.u_core.mshrCtl.u_core.mshrs[4].entry.u_core.txnid_wcompack = u_g3.mshrCtl.mshrs_4.txnid_wcompack;
    force u_i3.u_core.mshrCtl.u_core.mshrs[4].entry.u_core.srcid_retryack = u_g3.mshrCtl.mshrs_4.srcid_retryack;
    force u_i3.u_core.mshrCtl.u_core.mshrs[4].entry.u_core.acquire_ts = u_g3.mshrCtl.mshrs_4.acquire_ts;
    force u_i3.u_core.mshrCtl.u_core.mshrs[4].entry.u_core.release_ts = u_g3.mshrCtl.mshrs_4.release_ts;
    force u_i3.u_core.mshrCtl.u_core.mshrs[4].entry.u_core.acquire_period_valid_REG = u_g3.mshrCtl.mshrs_4.acquire_period_valid_REG;
    force u_i3.u_core.mshrCtl.u_core.mshrs[4].entry.u_core.release_period_valid_REG = u_g3.mshrCtl.mshrs_4.release_period_valid_REG;
    force u_i3.u_core.mshrCtl.u_core.mshrs[4].entry.u_core.REG = u_g3.mshrCtl.mshrs_4.REG;
    force u_i3.u_core.mshrCtl.u_core.mshrs[4].entry.u_core.REG_1 = u_g3.mshrCtl.mshrs_4.REG_1;
    force u_i3.u_core.mshrCtl.u_core.mshrs[4].entry.u_core.REG_2 = u_g3.mshrCtl.mshrs_4.REG_2;
    force u_i3.u_core.mshrCtl.u_core.mshrs[4].entry.u_core.REG_3 = u_g3.mshrCtl.mshrs_4.REG_3;
    force u_i3.u_core.mshrCtl.u_core.mshrs[5].entry.u_core.tgtid_rcompack = u_g3.mshrCtl.mshrs_5.tgtid_rcompack;
    force u_i3.u_core.mshrCtl.u_core.mshrs[5].entry.u_core.txnid_rcompack = u_g3.mshrCtl.mshrs_5.txnid_rcompack;
    force u_i3.u_core.mshrCtl.u_core.mshrs[5].entry.u_core.tgtid_wcompack = u_g3.mshrCtl.mshrs_5.tgtid_wcompack;
    force u_i3.u_core.mshrCtl.u_core.mshrs[5].entry.u_core.txnid_wcompack = u_g3.mshrCtl.mshrs_5.txnid_wcompack;
    force u_i3.u_core.mshrCtl.u_core.mshrs[5].entry.u_core.srcid_retryack = u_g3.mshrCtl.mshrs_5.srcid_retryack;
    force u_i3.u_core.mshrCtl.u_core.mshrs[5].entry.u_core.acquire_ts = u_g3.mshrCtl.mshrs_5.acquire_ts;
    force u_i3.u_core.mshrCtl.u_core.mshrs[5].entry.u_core.release_ts = u_g3.mshrCtl.mshrs_5.release_ts;
    force u_i3.u_core.mshrCtl.u_core.mshrs[5].entry.u_core.acquire_period_valid_REG = u_g3.mshrCtl.mshrs_5.acquire_period_valid_REG;
    force u_i3.u_core.mshrCtl.u_core.mshrs[5].entry.u_core.release_period_valid_REG = u_g3.mshrCtl.mshrs_5.release_period_valid_REG;
    force u_i3.u_core.mshrCtl.u_core.mshrs[5].entry.u_core.REG = u_g3.mshrCtl.mshrs_5.REG;
    force u_i3.u_core.mshrCtl.u_core.mshrs[5].entry.u_core.REG_1 = u_g3.mshrCtl.mshrs_5.REG_1;
    force u_i3.u_core.mshrCtl.u_core.mshrs[5].entry.u_core.REG_2 = u_g3.mshrCtl.mshrs_5.REG_2;
    force u_i3.u_core.mshrCtl.u_core.mshrs[5].entry.u_core.REG_3 = u_g3.mshrCtl.mshrs_5.REG_3;
    force u_i3.u_core.mshrCtl.u_core.mshrs[6].entry.u_core.tgtid_rcompack = u_g3.mshrCtl.mshrs_6.tgtid_rcompack;
    force u_i3.u_core.mshrCtl.u_core.mshrs[6].entry.u_core.txnid_rcompack = u_g3.mshrCtl.mshrs_6.txnid_rcompack;
    force u_i3.u_core.mshrCtl.u_core.mshrs[6].entry.u_core.tgtid_wcompack = u_g3.mshrCtl.mshrs_6.tgtid_wcompack;
    force u_i3.u_core.mshrCtl.u_core.mshrs[6].entry.u_core.txnid_wcompack = u_g3.mshrCtl.mshrs_6.txnid_wcompack;
    force u_i3.u_core.mshrCtl.u_core.mshrs[6].entry.u_core.srcid_retryack = u_g3.mshrCtl.mshrs_6.srcid_retryack;
    force u_i3.u_core.mshrCtl.u_core.mshrs[6].entry.u_core.acquire_ts = u_g3.mshrCtl.mshrs_6.acquire_ts;
    force u_i3.u_core.mshrCtl.u_core.mshrs[6].entry.u_core.release_ts = u_g3.mshrCtl.mshrs_6.release_ts;
    force u_i3.u_core.mshrCtl.u_core.mshrs[6].entry.u_core.acquire_period_valid_REG = u_g3.mshrCtl.mshrs_6.acquire_period_valid_REG;
    force u_i3.u_core.mshrCtl.u_core.mshrs[6].entry.u_core.release_period_valid_REG = u_g3.mshrCtl.mshrs_6.release_period_valid_REG;
    force u_i3.u_core.mshrCtl.u_core.mshrs[6].entry.u_core.REG = u_g3.mshrCtl.mshrs_6.REG;
    force u_i3.u_core.mshrCtl.u_core.mshrs[6].entry.u_core.REG_1 = u_g3.mshrCtl.mshrs_6.REG_1;
    force u_i3.u_core.mshrCtl.u_core.mshrs[6].entry.u_core.REG_2 = u_g3.mshrCtl.mshrs_6.REG_2;
    force u_i3.u_core.mshrCtl.u_core.mshrs[6].entry.u_core.REG_3 = u_g3.mshrCtl.mshrs_6.REG_3;
    force u_i3.u_core.mshrCtl.u_core.mshrs[7].entry.u_core.tgtid_rcompack = u_g3.mshrCtl.mshrs_7.tgtid_rcompack;
    force u_i3.u_core.mshrCtl.u_core.mshrs[7].entry.u_core.txnid_rcompack = u_g3.mshrCtl.mshrs_7.txnid_rcompack;
    force u_i3.u_core.mshrCtl.u_core.mshrs[7].entry.u_core.tgtid_wcompack = u_g3.mshrCtl.mshrs_7.tgtid_wcompack;
    force u_i3.u_core.mshrCtl.u_core.mshrs[7].entry.u_core.txnid_wcompack = u_g3.mshrCtl.mshrs_7.txnid_wcompack;
    force u_i3.u_core.mshrCtl.u_core.mshrs[7].entry.u_core.srcid_retryack = u_g3.mshrCtl.mshrs_7.srcid_retryack;
    force u_i3.u_core.mshrCtl.u_core.mshrs[7].entry.u_core.acquire_ts = u_g3.mshrCtl.mshrs_7.acquire_ts;
    force u_i3.u_core.mshrCtl.u_core.mshrs[7].entry.u_core.release_ts = u_g3.mshrCtl.mshrs_7.release_ts;
    force u_i3.u_core.mshrCtl.u_core.mshrs[7].entry.u_core.acquire_period_valid_REG = u_g3.mshrCtl.mshrs_7.acquire_period_valid_REG;
    force u_i3.u_core.mshrCtl.u_core.mshrs[7].entry.u_core.release_period_valid_REG = u_g3.mshrCtl.mshrs_7.release_period_valid_REG;
    force u_i3.u_core.mshrCtl.u_core.mshrs[7].entry.u_core.REG = u_g3.mshrCtl.mshrs_7.REG;
    force u_i3.u_core.mshrCtl.u_core.mshrs[7].entry.u_core.REG_1 = u_g3.mshrCtl.mshrs_7.REG_1;
    force u_i3.u_core.mshrCtl.u_core.mshrs[7].entry.u_core.REG_2 = u_g3.mshrCtl.mshrs_7.REG_2;
    force u_i3.u_core.mshrCtl.u_core.mshrs[7].entry.u_core.REG_3 = u_g3.mshrCtl.mshrs_7.REG_3;
    force u_i3.u_core.mshrCtl.u_core.mshrs[8].entry.u_core.tgtid_rcompack = u_g3.mshrCtl.mshrs_8.tgtid_rcompack;
    force u_i3.u_core.mshrCtl.u_core.mshrs[8].entry.u_core.txnid_rcompack = u_g3.mshrCtl.mshrs_8.txnid_rcompack;
    force u_i3.u_core.mshrCtl.u_core.mshrs[8].entry.u_core.tgtid_wcompack = u_g3.mshrCtl.mshrs_8.tgtid_wcompack;
    force u_i3.u_core.mshrCtl.u_core.mshrs[8].entry.u_core.txnid_wcompack = u_g3.mshrCtl.mshrs_8.txnid_wcompack;
    force u_i3.u_core.mshrCtl.u_core.mshrs[8].entry.u_core.srcid_retryack = u_g3.mshrCtl.mshrs_8.srcid_retryack;
    force u_i3.u_core.mshrCtl.u_core.mshrs[8].entry.u_core.acquire_ts = u_g3.mshrCtl.mshrs_8.acquire_ts;
    force u_i3.u_core.mshrCtl.u_core.mshrs[8].entry.u_core.release_ts = u_g3.mshrCtl.mshrs_8.release_ts;
    force u_i3.u_core.mshrCtl.u_core.mshrs[8].entry.u_core.acquire_period_valid_REG = u_g3.mshrCtl.mshrs_8.acquire_period_valid_REG;
    force u_i3.u_core.mshrCtl.u_core.mshrs[8].entry.u_core.release_period_valid_REG = u_g3.mshrCtl.mshrs_8.release_period_valid_REG;
    force u_i3.u_core.mshrCtl.u_core.mshrs[8].entry.u_core.REG = u_g3.mshrCtl.mshrs_8.REG;
    force u_i3.u_core.mshrCtl.u_core.mshrs[8].entry.u_core.REG_1 = u_g3.mshrCtl.mshrs_8.REG_1;
    force u_i3.u_core.mshrCtl.u_core.mshrs[8].entry.u_core.REG_2 = u_g3.mshrCtl.mshrs_8.REG_2;
    force u_i3.u_core.mshrCtl.u_core.mshrs[8].entry.u_core.REG_3 = u_g3.mshrCtl.mshrs_8.REG_3;
    force u_i3.u_core.mshrCtl.u_core.mshrs[9].entry.u_core.tgtid_rcompack = u_g3.mshrCtl.mshrs_9.tgtid_rcompack;
    force u_i3.u_core.mshrCtl.u_core.mshrs[9].entry.u_core.txnid_rcompack = u_g3.mshrCtl.mshrs_9.txnid_rcompack;
    force u_i3.u_core.mshrCtl.u_core.mshrs[9].entry.u_core.tgtid_wcompack = u_g3.mshrCtl.mshrs_9.tgtid_wcompack;
    force u_i3.u_core.mshrCtl.u_core.mshrs[9].entry.u_core.txnid_wcompack = u_g3.mshrCtl.mshrs_9.txnid_wcompack;
    force u_i3.u_core.mshrCtl.u_core.mshrs[9].entry.u_core.srcid_retryack = u_g3.mshrCtl.mshrs_9.srcid_retryack;
    force u_i3.u_core.mshrCtl.u_core.mshrs[9].entry.u_core.acquire_ts = u_g3.mshrCtl.mshrs_9.acquire_ts;
    force u_i3.u_core.mshrCtl.u_core.mshrs[9].entry.u_core.release_ts = u_g3.mshrCtl.mshrs_9.release_ts;
    force u_i3.u_core.mshrCtl.u_core.mshrs[9].entry.u_core.acquire_period_valid_REG = u_g3.mshrCtl.mshrs_9.acquire_period_valid_REG;
    force u_i3.u_core.mshrCtl.u_core.mshrs[9].entry.u_core.release_period_valid_REG = u_g3.mshrCtl.mshrs_9.release_period_valid_REG;
    force u_i3.u_core.mshrCtl.u_core.mshrs[9].entry.u_core.REG = u_g3.mshrCtl.mshrs_9.REG;
    force u_i3.u_core.mshrCtl.u_core.mshrs[9].entry.u_core.REG_1 = u_g3.mshrCtl.mshrs_9.REG_1;
    force u_i3.u_core.mshrCtl.u_core.mshrs[9].entry.u_core.REG_2 = u_g3.mshrCtl.mshrs_9.REG_2;
    force u_i3.u_core.mshrCtl.u_core.mshrs[9].entry.u_core.REG_3 = u_g3.mshrCtl.mshrs_9.REG_3;
    force u_i3.u_core.mshrCtl.u_core.mshrs[10].entry.u_core.tgtid_rcompack = u_g3.mshrCtl.mshrs_10.tgtid_rcompack;
    force u_i3.u_core.mshrCtl.u_core.mshrs[10].entry.u_core.txnid_rcompack = u_g3.mshrCtl.mshrs_10.txnid_rcompack;
    force u_i3.u_core.mshrCtl.u_core.mshrs[10].entry.u_core.tgtid_wcompack = u_g3.mshrCtl.mshrs_10.tgtid_wcompack;
    force u_i3.u_core.mshrCtl.u_core.mshrs[10].entry.u_core.txnid_wcompack = u_g3.mshrCtl.mshrs_10.txnid_wcompack;
    force u_i3.u_core.mshrCtl.u_core.mshrs[10].entry.u_core.srcid_retryack = u_g3.mshrCtl.mshrs_10.srcid_retryack;
    force u_i3.u_core.mshrCtl.u_core.mshrs[10].entry.u_core.acquire_ts = u_g3.mshrCtl.mshrs_10.acquire_ts;
    force u_i3.u_core.mshrCtl.u_core.mshrs[10].entry.u_core.release_ts = u_g3.mshrCtl.mshrs_10.release_ts;
    force u_i3.u_core.mshrCtl.u_core.mshrs[10].entry.u_core.acquire_period_valid_REG = u_g3.mshrCtl.mshrs_10.acquire_period_valid_REG;
    force u_i3.u_core.mshrCtl.u_core.mshrs[10].entry.u_core.release_period_valid_REG = u_g3.mshrCtl.mshrs_10.release_period_valid_REG;
    force u_i3.u_core.mshrCtl.u_core.mshrs[10].entry.u_core.REG = u_g3.mshrCtl.mshrs_10.REG;
    force u_i3.u_core.mshrCtl.u_core.mshrs[10].entry.u_core.REG_1 = u_g3.mshrCtl.mshrs_10.REG_1;
    force u_i3.u_core.mshrCtl.u_core.mshrs[10].entry.u_core.REG_2 = u_g3.mshrCtl.mshrs_10.REG_2;
    force u_i3.u_core.mshrCtl.u_core.mshrs[10].entry.u_core.REG_3 = u_g3.mshrCtl.mshrs_10.REG_3;
    force u_i3.u_core.mshrCtl.u_core.mshrs[11].entry.u_core.tgtid_rcompack = u_g3.mshrCtl.mshrs_11.tgtid_rcompack;
    force u_i3.u_core.mshrCtl.u_core.mshrs[11].entry.u_core.txnid_rcompack = u_g3.mshrCtl.mshrs_11.txnid_rcompack;
    force u_i3.u_core.mshrCtl.u_core.mshrs[11].entry.u_core.tgtid_wcompack = u_g3.mshrCtl.mshrs_11.tgtid_wcompack;
    force u_i3.u_core.mshrCtl.u_core.mshrs[11].entry.u_core.txnid_wcompack = u_g3.mshrCtl.mshrs_11.txnid_wcompack;
    force u_i3.u_core.mshrCtl.u_core.mshrs[11].entry.u_core.srcid_retryack = u_g3.mshrCtl.mshrs_11.srcid_retryack;
    force u_i3.u_core.mshrCtl.u_core.mshrs[11].entry.u_core.acquire_ts = u_g3.mshrCtl.mshrs_11.acquire_ts;
    force u_i3.u_core.mshrCtl.u_core.mshrs[11].entry.u_core.release_ts = u_g3.mshrCtl.mshrs_11.release_ts;
    force u_i3.u_core.mshrCtl.u_core.mshrs[11].entry.u_core.acquire_period_valid_REG = u_g3.mshrCtl.mshrs_11.acquire_period_valid_REG;
    force u_i3.u_core.mshrCtl.u_core.mshrs[11].entry.u_core.release_period_valid_REG = u_g3.mshrCtl.mshrs_11.release_period_valid_REG;
    force u_i3.u_core.mshrCtl.u_core.mshrs[11].entry.u_core.REG = u_g3.mshrCtl.mshrs_11.REG;
    force u_i3.u_core.mshrCtl.u_core.mshrs[11].entry.u_core.REG_1 = u_g3.mshrCtl.mshrs_11.REG_1;
    force u_i3.u_core.mshrCtl.u_core.mshrs[11].entry.u_core.REG_2 = u_g3.mshrCtl.mshrs_11.REG_2;
    force u_i3.u_core.mshrCtl.u_core.mshrs[11].entry.u_core.REG_3 = u_g3.mshrCtl.mshrs_11.REG_3;
    force u_i3.u_core.mshrCtl.u_core.mshrs[12].entry.u_core.tgtid_rcompack = u_g3.mshrCtl.mshrs_12.tgtid_rcompack;
    force u_i3.u_core.mshrCtl.u_core.mshrs[12].entry.u_core.txnid_rcompack = u_g3.mshrCtl.mshrs_12.txnid_rcompack;
    force u_i3.u_core.mshrCtl.u_core.mshrs[12].entry.u_core.tgtid_wcompack = u_g3.mshrCtl.mshrs_12.tgtid_wcompack;
    force u_i3.u_core.mshrCtl.u_core.mshrs[12].entry.u_core.txnid_wcompack = u_g3.mshrCtl.mshrs_12.txnid_wcompack;
    force u_i3.u_core.mshrCtl.u_core.mshrs[12].entry.u_core.srcid_retryack = u_g3.mshrCtl.mshrs_12.srcid_retryack;
    force u_i3.u_core.mshrCtl.u_core.mshrs[12].entry.u_core.acquire_ts = u_g3.mshrCtl.mshrs_12.acquire_ts;
    force u_i3.u_core.mshrCtl.u_core.mshrs[12].entry.u_core.release_ts = u_g3.mshrCtl.mshrs_12.release_ts;
    force u_i3.u_core.mshrCtl.u_core.mshrs[12].entry.u_core.acquire_period_valid_REG = u_g3.mshrCtl.mshrs_12.acquire_period_valid_REG;
    force u_i3.u_core.mshrCtl.u_core.mshrs[12].entry.u_core.release_period_valid_REG = u_g3.mshrCtl.mshrs_12.release_period_valid_REG;
    force u_i3.u_core.mshrCtl.u_core.mshrs[12].entry.u_core.REG = u_g3.mshrCtl.mshrs_12.REG;
    force u_i3.u_core.mshrCtl.u_core.mshrs[12].entry.u_core.REG_1 = u_g3.mshrCtl.mshrs_12.REG_1;
    force u_i3.u_core.mshrCtl.u_core.mshrs[12].entry.u_core.REG_2 = u_g3.mshrCtl.mshrs_12.REG_2;
    force u_i3.u_core.mshrCtl.u_core.mshrs[12].entry.u_core.REG_3 = u_g3.mshrCtl.mshrs_12.REG_3;
    force u_i3.u_core.mshrCtl.u_core.mshrs[13].entry.u_core.tgtid_rcompack = u_g3.mshrCtl.mshrs_13.tgtid_rcompack;
    force u_i3.u_core.mshrCtl.u_core.mshrs[13].entry.u_core.txnid_rcompack = u_g3.mshrCtl.mshrs_13.txnid_rcompack;
    force u_i3.u_core.mshrCtl.u_core.mshrs[13].entry.u_core.tgtid_wcompack = u_g3.mshrCtl.mshrs_13.tgtid_wcompack;
    force u_i3.u_core.mshrCtl.u_core.mshrs[13].entry.u_core.txnid_wcompack = u_g3.mshrCtl.mshrs_13.txnid_wcompack;
    force u_i3.u_core.mshrCtl.u_core.mshrs[13].entry.u_core.srcid_retryack = u_g3.mshrCtl.mshrs_13.srcid_retryack;
    force u_i3.u_core.mshrCtl.u_core.mshrs[13].entry.u_core.acquire_ts = u_g3.mshrCtl.mshrs_13.acquire_ts;
    force u_i3.u_core.mshrCtl.u_core.mshrs[13].entry.u_core.release_ts = u_g3.mshrCtl.mshrs_13.release_ts;
    force u_i3.u_core.mshrCtl.u_core.mshrs[13].entry.u_core.acquire_period_valid_REG = u_g3.mshrCtl.mshrs_13.acquire_period_valid_REG;
    force u_i3.u_core.mshrCtl.u_core.mshrs[13].entry.u_core.release_period_valid_REG = u_g3.mshrCtl.mshrs_13.release_period_valid_REG;
    force u_i3.u_core.mshrCtl.u_core.mshrs[13].entry.u_core.REG = u_g3.mshrCtl.mshrs_13.REG;
    force u_i3.u_core.mshrCtl.u_core.mshrs[13].entry.u_core.REG_1 = u_g3.mshrCtl.mshrs_13.REG_1;
    force u_i3.u_core.mshrCtl.u_core.mshrs[13].entry.u_core.REG_2 = u_g3.mshrCtl.mshrs_13.REG_2;
    force u_i3.u_core.mshrCtl.u_core.mshrs[13].entry.u_core.REG_3 = u_g3.mshrCtl.mshrs_13.REG_3;
    force u_i3.u_core.mshrCtl.u_core.mshrs[14].entry.u_core.tgtid_rcompack = u_g3.mshrCtl.mshrs_14.tgtid_rcompack;
    force u_i3.u_core.mshrCtl.u_core.mshrs[14].entry.u_core.txnid_rcompack = u_g3.mshrCtl.mshrs_14.txnid_rcompack;
    force u_i3.u_core.mshrCtl.u_core.mshrs[14].entry.u_core.tgtid_wcompack = u_g3.mshrCtl.mshrs_14.tgtid_wcompack;
    force u_i3.u_core.mshrCtl.u_core.mshrs[14].entry.u_core.txnid_wcompack = u_g3.mshrCtl.mshrs_14.txnid_wcompack;
    force u_i3.u_core.mshrCtl.u_core.mshrs[14].entry.u_core.srcid_retryack = u_g3.mshrCtl.mshrs_14.srcid_retryack;
    force u_i3.u_core.mshrCtl.u_core.mshrs[14].entry.u_core.acquire_ts = u_g3.mshrCtl.mshrs_14.acquire_ts;
    force u_i3.u_core.mshrCtl.u_core.mshrs[14].entry.u_core.release_ts = u_g3.mshrCtl.mshrs_14.release_ts;
    force u_i3.u_core.mshrCtl.u_core.mshrs[14].entry.u_core.acquire_period_valid_REG = u_g3.mshrCtl.mshrs_14.acquire_period_valid_REG;
    force u_i3.u_core.mshrCtl.u_core.mshrs[14].entry.u_core.release_period_valid_REG = u_g3.mshrCtl.mshrs_14.release_period_valid_REG;
    force u_i3.u_core.mshrCtl.u_core.mshrs[14].entry.u_core.REG = u_g3.mshrCtl.mshrs_14.REG;
    force u_i3.u_core.mshrCtl.u_core.mshrs[14].entry.u_core.REG_1 = u_g3.mshrCtl.mshrs_14.REG_1;
    force u_i3.u_core.mshrCtl.u_core.mshrs[14].entry.u_core.REG_2 = u_g3.mshrCtl.mshrs_14.REG_2;
    force u_i3.u_core.mshrCtl.u_core.mshrs[14].entry.u_core.REG_3 = u_g3.mshrCtl.mshrs_14.REG_3;
    force u_i3.u_core.mshrCtl.u_core.mshrs[15].entry.u_core.tgtid_rcompack = u_g3.mshrCtl.mshrs_15.tgtid_rcompack;
    force u_i3.u_core.mshrCtl.u_core.mshrs[15].entry.u_core.txnid_rcompack = u_g3.mshrCtl.mshrs_15.txnid_rcompack;
    force u_i3.u_core.mshrCtl.u_core.mshrs[15].entry.u_core.tgtid_wcompack = u_g3.mshrCtl.mshrs_15.tgtid_wcompack;
    force u_i3.u_core.mshrCtl.u_core.mshrs[15].entry.u_core.txnid_wcompack = u_g3.mshrCtl.mshrs_15.txnid_wcompack;
    force u_i3.u_core.mshrCtl.u_core.mshrs[15].entry.u_core.srcid_retryack = u_g3.mshrCtl.mshrs_15.srcid_retryack;
    force u_i3.u_core.mshrCtl.u_core.mshrs[15].entry.u_core.acquire_ts = u_g3.mshrCtl.mshrs_15.acquire_ts;
    force u_i3.u_core.mshrCtl.u_core.mshrs[15].entry.u_core.release_ts = u_g3.mshrCtl.mshrs_15.release_ts;
    force u_i3.u_core.mshrCtl.u_core.mshrs[15].entry.u_core.acquire_period_valid_REG = u_g3.mshrCtl.mshrs_15.acquire_period_valid_REG;
    force u_i3.u_core.mshrCtl.u_core.mshrs[15].entry.u_core.release_period_valid_REG = u_g3.mshrCtl.mshrs_15.release_period_valid_REG;
    force u_i3.u_core.mshrCtl.u_core.mshrs[15].entry.u_core.REG = u_g3.mshrCtl.mshrs_15.REG;
    force u_i3.u_core.mshrCtl.u_core.mshrs[15].entry.u_core.REG_1 = u_g3.mshrCtl.mshrs_15.REG_1;
    force u_i3.u_core.mshrCtl.u_core.mshrs[15].entry.u_core.REG_2 = u_g3.mshrCtl.mshrs_15.REG_2;
    force u_i3.u_core.mshrCtl.u_core.mshrs[15].entry.u_core.REG_3 = u_g3.mshrCtl.mshrs_15.REG_3;
    force u_i3.u_core.mshrCtl.u_core.io_perf_0_value_REG = u_g3.mshrCtl.io_perf_0_value_REG;
    force u_i3.u_core.mshrCtl.u_core.io_perf_0_value_REG_1 = u_g3.mshrCtl.io_perf_0_value_REG_1;
    force u_i3.u_core.mshrCtl.u_core.io_perf_1_value_REG = u_g3.mshrCtl.io_perf_1_value_REG;
    force u_i3.u_core.mshrCtl.u_core.io_perf_1_value_REG_1 = u_g3.mshrCtl.io_perf_1_value_REG_1;
    force u_i3.u_core.mshrCtl.u_core.io_perf_3_value_REG = u_g3.mshrCtl.io_perf_3_value_REG;
    force u_i3.u_core.mshrCtl.u_core.io_perf_3_value_REG_1 = u_g3.mshrCtl.io_perf_3_value_REG_1;
    force u_i3.u_core.mshrCtl.u_core.REG = u_g3.mshrCtl.REG;
    force u_i3.u_core.mainPipe.u_core.data_s4 = u_g3.mainPipe.data_s4;
    force u_i3.u_core.mainPipe.u_core.data_s5 = u_g3.mainPipe.data_s5;
    force u_i3.u_core.mainPipe.u_core.s3DropValid_d1 = u_g3.mainPipe.REG;
    force u_i3.u_core.mainPipe.u_core.reqDrop_s3_d1 = u_g3.mainPipe.reqDropped_s5_REG;
    force u_i3.u_core.mainPipe.u_core.reqDrop_s3_d2 = u_g3.mainPipe.reqDropped_s5_REG_1;
    force u_i3.u_core.mainPipe.u_core.reqDrop_s4_d1 = u_g3.mainPipe.reqDropped_s5_REG_2;
    u_i3.u_core.mainPipe.customL1Hint.hintQueue.ram_ext.Memory = u_g3.mainPipe.customL1Hint.hintQueue.ram_ext.Memory;
    u_i3.u_core.mainPipe.customL1Hint.hint_s1Queue.ram_ext.Memory = u_g3.mainPipe.customL1Hint.hint_s1Queue.ram_ext.Memory;
    force u_i3.u_core.mainPipe.u_core.perf_d1[0] = u_g3.mainPipe.io_perf_0_value_REG;
    force u_i3.u_core.mainPipe.u_core.perf[0] = u_g3.mainPipe.io_perf_0_value_REG_1;
    force u_i3.u_core.mainPipe.u_core.perf_d1[1] = u_g3.mainPipe.io_perf_1_value_REG;
    force u_i3.u_core.mainPipe.u_core.perf[1] = u_g3.mainPipe.io_perf_1_value_REG_1;
    force u_i3.u_core.mainPipe.u_core.perf_d1[2] = u_g3.mainPipe.io_perf_2_value_REG;
    force u_i3.u_core.mainPipe.u_core.perf[2] = u_g3.mainPipe.io_perf_2_value_REG_1;
    force u_i3.u_core.mainPipe.u_core.perf_d1[3] = u_g3.mainPipe.io_perf_3_value_REG;
    force u_i3.u_core.mainPipe.u_core.perf[3] = u_g3.mainPipe.io_perf_3_value_REG_1;
    force u_i3.u_core.mainPipe.u_core.perf_d1[4] = u_g3.mainPipe.io_perf_4_value_REG;
    force u_i3.u_core.mainPipe.u_core.perf[4] = u_g3.mainPipe.io_perf_4_value_REG_1;
    force u_i3.u_core.mainPipe.u_core.perf_d1[5] = u_g3.mainPipe.io_perf_5_value_REG;
    force u_i3.u_core.mainPipe.u_core.perf[5] = u_g3.mainPipe.io_perf_5_value_REG_1;
    force u_i3.u_core.mainPipe.u_core.perf_d1[6] = u_g3.mainPipe.io_perf_6_value_REG;
    force u_i3.u_core.mainPipe.u_core.perf[6] = u_g3.mainPipe.io_perf_6_value_REG_1;
    force u_i3.u_core.mainPipe.u_core.perf_d1[7] = u_g3.mainPipe.io_perf_7_value_REG;
    force u_i3.u_core.mainPipe.u_core.perf[7] = u_g3.mainPipe.io_perf_7_value_REG_1;
    force u_i3.u_core.mainPipe.u_core.perf_d1[8] = u_g3.mainPipe.io_perf_8_value_REG;
    force u_i3.u_core.mainPipe.u_core.perf[8] = u_g3.mainPipe.io_perf_8_value_REG_1;
    force u_i3.u_core.mainPipe.u_core.perf_d1[9] = u_g3.mainPipe.io_perf_9_value_REG;
    force u_i3.u_core.mainPipe.u_core.perf[9] = u_g3.mainPipe.io_perf_9_value_REG_1;
    force u_i3.u_core.mainPipe.u_core.perf_d1[10] = u_g3.mainPipe.io_perf_10_value_REG;
    force u_i3.u_core.mainPipe.u_core.perf[10] = u_g3.mainPipe.io_perf_10_value_REG_1;
    force u_i3.u_core.mainPipe.u_core.perf_d1[11] = u_g3.mainPipe.io_perf_11_value_REG;
    force u_i3.u_core.mainPipe.u_core.perf[11] = u_g3.mainPipe.io_perf_11_value_REG_1;
    force u_i3.u_core.mainPipe.u_core.perf_d1[12] = u_g3.mainPipe.io_perf_12_value_REG;
    force u_i3.u_core.mainPipe.u_core.perf[12] = u_g3.mainPipe.io_perf_12_value_REG_1;
    u_i3.u_core.grantBuf.grantQueue.ram_ext.Memory = u_g3.grantBuf.grantQueue.ram_ext.Memory;
    u_i3.u_core.grantBuf.grantQueueData0.ram_data_data_ext.Memory = u_g3.grantBuf.grantQueueData0.ram_data_data_ext.Memory;
    u_i3.u_core.grantBuf.grantQueueData1.ram_data_data_ext.Memory = u_g3.grantBuf.grantQueueData1.ram_data_data_ext.Memory;
    u_i3.u_core.grantBuf.pftRespQueue.ram_ext.Memory = u_g3.grantBuf.pftRespQueue.ram_ext.Memory;
    force u_i3.u_core.grantBuf.u_core.validPrev[0] = u_g3.grantBuf.REG;
    force u_i3.u_core.grantBuf.u_core.histValidPrev[0] = u_g3.grantBuf.enable_REG;
    force u_i3.u_core.grantBuf.u_core.validPrev[1] = u_g3.grantBuf.REG_1;
    force u_i3.u_core.grantBuf.u_core.histValidPrev[1] = u_g3.grantBuf.enable_REG_1;
    force u_i3.u_core.grantBuf.u_core.validPrev[2] = u_g3.grantBuf.REG_2;
    force u_i3.u_core.grantBuf.u_core.histValidPrev[2] = u_g3.grantBuf.enable_REG_2;
    force u_i3.u_core.grantBuf.u_core.validPrev[3] = u_g3.grantBuf.REG_3;
    force u_i3.u_core.grantBuf.u_core.histValidPrev[3] = u_g3.grantBuf.enable_REG_3;
    force u_i3.u_core.grantBuf.u_core.validPrev[4] = u_g3.grantBuf.REG_4;
    force u_i3.u_core.grantBuf.u_core.histValidPrev[4] = u_g3.grantBuf.enable_REG_4;
    force u_i3.u_core.grantBuf.u_core.validPrev[5] = u_g3.grantBuf.REG_5;
    force u_i3.u_core.grantBuf.u_core.histValidPrev[5] = u_g3.grantBuf.enable_REG_5;
    force u_i3.u_core.grantBuf.u_core.validPrev[6] = u_g3.grantBuf.REG_6;
    force u_i3.u_core.grantBuf.u_core.histValidPrev[6] = u_g3.grantBuf.enable_REG_6;
    force u_i3.u_core.grantBuf.u_core.validPrev[7] = u_g3.grantBuf.REG_7;
    force u_i3.u_core.grantBuf.u_core.histValidPrev[7] = u_g3.grantBuf.enable_REG_7;
    force u_i3.u_core.grantBuf.u_core.validPrev[8] = u_g3.grantBuf.REG_8;
    force u_i3.u_core.grantBuf.u_core.histValidPrev[8] = u_g3.grantBuf.enable_REG_8;
    force u_i3.u_core.grantBuf.u_core.validPrev[9] = u_g3.grantBuf.REG_9;
    force u_i3.u_core.grantBuf.u_core.histValidPrev[9] = u_g3.grantBuf.enable_REG_9;
    force u_i3.u_core.grantBuf.u_core.validPrev[10] = u_g3.grantBuf.REG_10;
    force u_i3.u_core.grantBuf.u_core.histValidPrev[10] = u_g3.grantBuf.enable_REG_10;
    force u_i3.u_core.grantBuf.u_core.validPrev[11] = u_g3.grantBuf.REG_11;
    force u_i3.u_core.grantBuf.u_core.histValidPrev[11] = u_g3.grantBuf.enable_REG_11;
    force u_i3.u_core.grantBuf.u_core.validPrev[12] = u_g3.grantBuf.REG_12;
    force u_i3.u_core.grantBuf.u_core.histValidPrev[12] = u_g3.grantBuf.enable_REG_12;
    force u_i3.u_core.grantBuf.u_core.validPrev[13] = u_g3.grantBuf.REG_13;
    force u_i3.u_core.grantBuf.u_core.histValidPrev[13] = u_g3.grantBuf.enable_REG_13;
    force u_i3.u_core.grantBuf.u_core.validPrev[14] = u_g3.grantBuf.REG_14;
    force u_i3.u_core.grantBuf.u_core.histValidPrev[14] = u_g3.grantBuf.enable_REG_14;
    force u_i3.u_core.grantBuf.u_core.validPrev[15] = u_g3.grantBuf.REG_15;
    force u_i3.u_core.grantBuf.u_core.histValidPrev[15] = u_g3.grantBuf.enable_REG_15;
    u_i3.u_core.rxsnp.queue.ram_ext.Memory = u_g3.rxsnp.queue.ram_ext.Memory;
    force u_i3.u_core.rxsnp.u_core.replPrevForBlock[0] = u_g3.rxsnp.replaceBlockSnpMask_REG;
    force u_i3.u_core.rxsnp.u_core.replPrevForNest[0] = u_g3.rxsnp.replaceNestSnpMask_REG;
    force u_i3.u_core.rxsnp.u_core.replPrevForBlock[1] = u_g3.rxsnp.replaceBlockSnpMask_REG_1;
    force u_i3.u_core.rxsnp.u_core.replPrevForNest[1] = u_g3.rxsnp.replaceNestSnpMask_REG_1;
    force u_i3.u_core.rxsnp.u_core.replPrevForBlock[2] = u_g3.rxsnp.replaceBlockSnpMask_REG_2;
    force u_i3.u_core.rxsnp.u_core.replPrevForNest[2] = u_g3.rxsnp.replaceNestSnpMask_REG_2;
    force u_i3.u_core.rxsnp.u_core.replPrevForBlock[3] = u_g3.rxsnp.replaceBlockSnpMask_REG_3;
    force u_i3.u_core.rxsnp.u_core.replPrevForNest[3] = u_g3.rxsnp.replaceNestSnpMask_REG_3;
    force u_i3.u_core.rxsnp.u_core.replPrevForBlock[4] = u_g3.rxsnp.replaceBlockSnpMask_REG_4;
    force u_i3.u_core.rxsnp.u_core.replPrevForNest[4] = u_g3.rxsnp.replaceNestSnpMask_REG_4;
    force u_i3.u_core.rxsnp.u_core.replPrevForBlock[5] = u_g3.rxsnp.replaceBlockSnpMask_REG_5;
    force u_i3.u_core.rxsnp.u_core.replPrevForNest[5] = u_g3.rxsnp.replaceNestSnpMask_REG_5;
    force u_i3.u_core.rxsnp.u_core.replPrevForBlock[6] = u_g3.rxsnp.replaceBlockSnpMask_REG_6;
    force u_i3.u_core.rxsnp.u_core.replPrevForNest[6] = u_g3.rxsnp.replaceNestSnpMask_REG_6;
    force u_i3.u_core.rxsnp.u_core.replPrevForBlock[7] = u_g3.rxsnp.replaceBlockSnpMask_REG_7;
    force u_i3.u_core.rxsnp.u_core.replPrevForNest[7] = u_g3.rxsnp.replaceNestSnpMask_REG_7;
    force u_i3.u_core.rxsnp.u_core.replPrevForBlock[8] = u_g3.rxsnp.replaceBlockSnpMask_REG_8;
    force u_i3.u_core.rxsnp.u_core.replPrevForNest[8] = u_g3.rxsnp.replaceNestSnpMask_REG_8;
    force u_i3.u_core.rxsnp.u_core.replPrevForBlock[9] = u_g3.rxsnp.replaceBlockSnpMask_REG_9;
    force u_i3.u_core.rxsnp.u_core.replPrevForNest[9] = u_g3.rxsnp.replaceNestSnpMask_REG_9;
    force u_i3.u_core.rxsnp.u_core.replPrevForBlock[10] = u_g3.rxsnp.replaceBlockSnpMask_REG_10;
    force u_i3.u_core.rxsnp.u_core.replPrevForNest[10] = u_g3.rxsnp.replaceNestSnpMask_REG_10;
    force u_i3.u_core.rxsnp.u_core.replPrevForBlock[11] = u_g3.rxsnp.replaceBlockSnpMask_REG_11;
    force u_i3.u_core.rxsnp.u_core.replPrevForNest[11] = u_g3.rxsnp.replaceNestSnpMask_REG_11;
    force u_i3.u_core.rxsnp.u_core.replPrevForBlock[12] = u_g3.rxsnp.replaceBlockSnpMask_REG_12;
    force u_i3.u_core.rxsnp.u_core.replPrevForNest[12] = u_g3.rxsnp.replaceNestSnpMask_REG_12;
    force u_i3.u_core.rxsnp.u_core.replPrevForBlock[13] = u_g3.rxsnp.replaceBlockSnpMask_REG_13;
    force u_i3.u_core.rxsnp.u_core.replPrevForNest[13] = u_g3.rxsnp.replaceNestSnpMask_REG_13;
    force u_i3.u_core.rxsnp.u_core.replPrevForBlock[14] = u_g3.rxsnp.replaceBlockSnpMask_REG_14;
    force u_i3.u_core.rxsnp.u_core.replPrevForNest[14] = u_g3.rxsnp.replaceNestSnpMask_REG_14;
    force u_i3.u_core.rxsnp.u_core.replPrevForBlock[15] = u_g3.rxsnp.replaceBlockSnpMask_REG_15;
    force u_i3.u_core.rxsnp.u_core.replPrevForNest[15] = u_g3.rxsnp.replaceNestSnpMask_REG_15;
    force u_i3.u_core.reqBuf.chosenQ.u_core.ram = u_g3.reqBuf.chosenQ.ram;
    force u_i3.u_core.reqBuf.u_core.hitPfPrev_set = u_g3.reqBuf.io_hasHitPfInMSHR_valid_REG_set;
    force u_i3.u_core.reqBuf.u_core.hitPfPrev_tag = u_g3.reqBuf.io_hasHitPfInMSHR_valid_REG_tag;
    force u_i3.u_core.reqBuf.u_core.mergeAPrev_set = u_g3.reqBuf.io_hasMergeA_REG_set;
    force u_i3.u_core.reqBuf.u_core.mergeAPrev_tag = u_g3.reqBuf.io_hasMergeA_REG_tag;
    force u_i3.u_core.reqBuf.u_core.sameSetS3Valid[0] = u_g3.reqBuf.canFlow_sameSet_s3_REG;
    force u_i3.u_core.reqBuf.u_core.sameSetS3Set[0] = u_g3.reqBuf.canFlow_sameSet_s3_r;
    force u_i3.u_core.reqBuf.u_core.sameSetS3Valid[1] = u_g3.reqBuf.buffer_rdy_sameSet_s3_REG;
    force u_i3.u_core.reqBuf.u_core.sameSetS3Set[1] = u_g3.reqBuf.buffer_rdy_sameSet_s3_r;
    force u_i3.u_core.reqBuf.u_core.sameSetS3Valid[2] = u_g3.reqBuf.buffer_0_rdy_sameSet_s3_REG;
    force u_i3.u_core.reqBuf.u_core.sameSetS3Set[2] = u_g3.reqBuf.buffer_0_rdy_sameSet_s3_r;
    force u_i3.u_core.reqBuf.u_core.sameSetS3Valid[3] = u_g3.reqBuf.buffer_1_rdy_sameSet_s3_REG;
    force u_i3.u_core.reqBuf.u_core.sameSetS3Set[3] = u_g3.reqBuf.buffer_1_rdy_sameSet_s3_r;
    force u_i3.u_core.reqBuf.u_core.sameSetS3Valid[4] = u_g3.reqBuf.buffer_2_rdy_sameSet_s3_REG;
    force u_i3.u_core.reqBuf.u_core.sameSetS3Set[4] = u_g3.reqBuf.buffer_2_rdy_sameSet_s3_r;
    force u_i3.u_core.reqBuf.u_core.sameSetS3Valid[5] = u_g3.reqBuf.buffer_3_rdy_sameSet_s3_REG;
    force u_i3.u_core.reqBuf.u_core.sameSetS3Set[5] = u_g3.reqBuf.buffer_3_rdy_sameSet_s3_r;
    force u_i3.u_core.sinkC.u_core.bufRespStage[0] = u_g3.sinkC.r_0;
    force u_i3.u_core.sinkC.u_core.bufRespStage[1] = u_g3.sinkC.r_1;
    force u_i3.u_core.sinkC.u_core.bufRespOut[0] = u_g3.sinkC.REG_0;
    force u_i3.u_core.sinkC.u_core.bufRespOut[1] = u_g3.sinkC.REG_1;
    force u_i3.u_core.sinkC.u_core.refillIdReg = u_g3.sinkC.io_refillBufWrite_bits_id_REG;
    force u_i3.u_core.sinkC.u_core.refillBufIdxReg = u_g3.sinkC.io_refillBufWrite_bits_data_data_REG;
    force u_i3.u_core.sinkC.u_core.taskFirePrev = u_g3.sinkC.REG_1_0;
    force u_i3.u_core.sinkC.u_core.taskBufIdxPrev = u_g3.sinkC.REG_2;
    force u_i3.u_core.reqArb.u_core.ds_mcp2_stall = u_g3.reqArb.ds_mcp2_stall;
    force u_i3.u_core.refillBuf.u_core.buffer[0][0] = u_g3.refillBuf.buffer_0_0;
    force u_i3.u_core.refillBuf.u_core.buffer[0][1] = u_g3.refillBuf.buffer_0_1;
    force u_i3.u_core.refillBuf.u_core.buffer[1][0] = u_g3.refillBuf.buffer_1_0;
    force u_i3.u_core.refillBuf.u_core.buffer[1][1] = u_g3.refillBuf.buffer_1_1;
    force u_i3.u_core.refillBuf.u_core.buffer[2][0] = u_g3.refillBuf.buffer_2_0;
    force u_i3.u_core.refillBuf.u_core.buffer[2][1] = u_g3.refillBuf.buffer_2_1;
    force u_i3.u_core.refillBuf.u_core.buffer[3][0] = u_g3.refillBuf.buffer_3_0;
    force u_i3.u_core.refillBuf.u_core.buffer[3][1] = u_g3.refillBuf.buffer_3_1;
    force u_i3.u_core.refillBuf.u_core.buffer[4][0] = u_g3.refillBuf.buffer_4_0;
    force u_i3.u_core.refillBuf.u_core.buffer[4][1] = u_g3.refillBuf.buffer_4_1;
    force u_i3.u_core.refillBuf.u_core.buffer[5][0] = u_g3.refillBuf.buffer_5_0;
    force u_i3.u_core.refillBuf.u_core.buffer[5][1] = u_g3.refillBuf.buffer_5_1;
    force u_i3.u_core.refillBuf.u_core.buffer[6][0] = u_g3.refillBuf.buffer_6_0;
    force u_i3.u_core.refillBuf.u_core.buffer[6][1] = u_g3.refillBuf.buffer_6_1;
    force u_i3.u_core.refillBuf.u_core.buffer[7][0] = u_g3.refillBuf.buffer_7_0;
    force u_i3.u_core.refillBuf.u_core.buffer[7][1] = u_g3.refillBuf.buffer_7_1;
    force u_i3.u_core.refillBuf.u_core.buffer[8][0] = u_g3.refillBuf.buffer_8_0;
    force u_i3.u_core.refillBuf.u_core.buffer[8][1] = u_g3.refillBuf.buffer_8_1;
    force u_i3.u_core.refillBuf.u_core.buffer[9][0] = u_g3.refillBuf.buffer_9_0;
    force u_i3.u_core.refillBuf.u_core.buffer[9][1] = u_g3.refillBuf.buffer_9_1;
    force u_i3.u_core.refillBuf.u_core.buffer[10][0] = u_g3.refillBuf.buffer_10_0;
    force u_i3.u_core.refillBuf.u_core.buffer[10][1] = u_g3.refillBuf.buffer_10_1;
    force u_i3.u_core.refillBuf.u_core.buffer[11][0] = u_g3.refillBuf.buffer_11_0;
    force u_i3.u_core.refillBuf.u_core.buffer[11][1] = u_g3.refillBuf.buffer_11_1;
    force u_i3.u_core.refillBuf.u_core.buffer[12][0] = u_g3.refillBuf.buffer_12_0;
    force u_i3.u_core.refillBuf.u_core.buffer[12][1] = u_g3.refillBuf.buffer_12_1;
    force u_i3.u_core.refillBuf.u_core.buffer[13][0] = u_g3.refillBuf.buffer_13_0;
    force u_i3.u_core.refillBuf.u_core.buffer[13][1] = u_g3.refillBuf.buffer_13_1;
    force u_i3.u_core.refillBuf.u_core.buffer[14][0] = u_g3.refillBuf.buffer_14_0;
    force u_i3.u_core.refillBuf.u_core.buffer[14][1] = u_g3.refillBuf.buffer_14_1;
    force u_i3.u_core.refillBuf.u_core.buffer[15][0] = u_g3.refillBuf.buffer_15_0;
    force u_i3.u_core.refillBuf.u_core.buffer[15][1] = u_g3.refillBuf.buffer_15_1;
    force u_i3.u_core.releaseBuf.u_core.buffer[0][0] = u_g3.releaseBuf.buffer_0_0;
    force u_i3.u_core.releaseBuf.u_core.buffer[0][1] = u_g3.releaseBuf.buffer_0_1;
    force u_i3.u_core.releaseBuf.u_core.buffer[1][0] = u_g3.releaseBuf.buffer_1_0;
    force u_i3.u_core.releaseBuf.u_core.buffer[1][1] = u_g3.releaseBuf.buffer_1_1;
    force u_i3.u_core.releaseBuf.u_core.buffer[2][0] = u_g3.releaseBuf.buffer_2_0;
    force u_i3.u_core.releaseBuf.u_core.buffer[2][1] = u_g3.releaseBuf.buffer_2_1;
    force u_i3.u_core.releaseBuf.u_core.buffer[3][0] = u_g3.releaseBuf.buffer_3_0;
    force u_i3.u_core.releaseBuf.u_core.buffer[3][1] = u_g3.releaseBuf.buffer_3_1;
    force u_i3.u_core.releaseBuf.u_core.buffer[4][0] = u_g3.releaseBuf.buffer_4_0;
    force u_i3.u_core.releaseBuf.u_core.buffer[4][1] = u_g3.releaseBuf.buffer_4_1;
    force u_i3.u_core.releaseBuf.u_core.buffer[5][0] = u_g3.releaseBuf.buffer_5_0;
    force u_i3.u_core.releaseBuf.u_core.buffer[5][1] = u_g3.releaseBuf.buffer_5_1;
    force u_i3.u_core.releaseBuf.u_core.buffer[6][0] = u_g3.releaseBuf.buffer_6_0;
    force u_i3.u_core.releaseBuf.u_core.buffer[6][1] = u_g3.releaseBuf.buffer_6_1;
    force u_i3.u_core.releaseBuf.u_core.buffer[7][0] = u_g3.releaseBuf.buffer_7_0;
    force u_i3.u_core.releaseBuf.u_core.buffer[7][1] = u_g3.releaseBuf.buffer_7_1;
    force u_i3.u_core.releaseBuf.u_core.buffer[8][0] = u_g3.releaseBuf.buffer_8_0;
    force u_i3.u_core.releaseBuf.u_core.buffer[8][1] = u_g3.releaseBuf.buffer_8_1;
    force u_i3.u_core.releaseBuf.u_core.buffer[9][0] = u_g3.releaseBuf.buffer_9_0;
    force u_i3.u_core.releaseBuf.u_core.buffer[9][1] = u_g3.releaseBuf.buffer_9_1;
    force u_i3.u_core.releaseBuf.u_core.buffer[10][0] = u_g3.releaseBuf.buffer_10_0;
    force u_i3.u_core.releaseBuf.u_core.buffer[10][1] = u_g3.releaseBuf.buffer_10_1;
    force u_i3.u_core.releaseBuf.u_core.buffer[11][0] = u_g3.releaseBuf.buffer_11_0;
    force u_i3.u_core.releaseBuf.u_core.buffer[11][1] = u_g3.releaseBuf.buffer_11_1;
    force u_i3.u_core.releaseBuf.u_core.buffer[12][0] = u_g3.releaseBuf.buffer_12_0;
    force u_i3.u_core.releaseBuf.u_core.buffer[12][1] = u_g3.releaseBuf.buffer_12_1;
    force u_i3.u_core.releaseBuf.u_core.buffer[13][0] = u_g3.releaseBuf.buffer_13_0;
    force u_i3.u_core.releaseBuf.u_core.buffer[13][1] = u_g3.releaseBuf.buffer_13_1;
    force u_i3.u_core.releaseBuf.u_core.buffer[14][0] = u_g3.releaseBuf.buffer_14_0;
    force u_i3.u_core.releaseBuf.u_core.buffer[14][1] = u_g3.releaseBuf.buffer_14_1;
    force u_i3.u_core.releaseBuf.u_core.buffer[15][0] = u_g3.releaseBuf.buffer_15_0;
    force u_i3.u_core.releaseBuf.u_core.buffer[15][1] = u_g3.releaseBuf.buffer_15_1;
    u_i3.u_core.txdat.queue.ram_ext.Memory = u_g3.txdat.queue.ram_ext.Memory;
    u_i3.u_core.txdat.queueData0.ram_data_ext.Memory = u_g3.txdat.queueData0.ram_data_ext.Memory;
    u_i3.u_core.txdat.queueData1.ram_data_ext.Memory = u_g3.txdat.queueData1.ram_data_ext.Memory;
    u_i3.directory.tagArray.array_0_0_0.array.array.array_14_ext.ram = u_g3.directory.tagArray.array_0_0_0.array.array.array_14_ext.ram;
    u_i3.directory.tagArray.array_0_0_0.array.array.array_14_ext.reg_RW0_addr = u_g3.directory.tagArray.array_0_0_0.array.array.array_14_ext.reg_RW0_addr;
    u_i3.directory.tagArray.array_0_0_0.array.array.array_14_ext.reg_RW0_ren = u_g3.directory.tagArray.array_0_0_0.array.array.array_14_ext.reg_RW0_ren;
    force u_i3.directory.tagArray.array_0_0_0.u_core.rdataReg = u_g3.directory.tagArray.array_0_0_0.rdataReg;
    u_i3.directory.tagArray.array_0_0_1.array.array.array_14_ext.ram = u_g3.directory.tagArray.array_0_0_1.array.array.array_14_ext.ram;
    u_i3.directory.tagArray.array_0_0_1.array.array.array_14_ext.reg_RW0_addr = u_g3.directory.tagArray.array_0_0_1.array.array.array_14_ext.reg_RW0_addr;
    u_i3.directory.tagArray.array_0_0_1.array.array.array_14_ext.reg_RW0_ren = u_g3.directory.tagArray.array_0_0_1.array.array.array_14_ext.reg_RW0_ren;
    force u_i3.directory.tagArray.array_0_0_1.u_core.rdataReg = u_g3.directory.tagArray.array_0_0_1.rdataReg;
    u_i3.directory.tagArray.array_0_1_0.array.array.array_14_ext.ram = u_g3.directory.tagArray.array_0_1_0.array.array.array_14_ext.ram;
    u_i3.directory.tagArray.array_0_1_0.array.array.array_14_ext.reg_RW0_addr = u_g3.directory.tagArray.array_0_1_0.array.array.array_14_ext.reg_RW0_addr;
    u_i3.directory.tagArray.array_0_1_0.array.array.array_14_ext.reg_RW0_ren = u_g3.directory.tagArray.array_0_1_0.array.array.array_14_ext.reg_RW0_ren;
    force u_i3.directory.tagArray.array_0_1_0.u_core.rdataReg = u_g3.directory.tagArray.array_0_1_0.rdataReg;
    u_i3.directory.tagArray.array_0_1_1.array.array.array_14_ext.ram = u_g3.directory.tagArray.array_0_1_1.array.array.array_14_ext.ram;
    u_i3.directory.tagArray.array_0_1_1.array.array.array_14_ext.reg_RW0_addr = u_g3.directory.tagArray.array_0_1_1.array.array.array_14_ext.reg_RW0_addr;
    u_i3.directory.tagArray.array_0_1_1.array.array.array_14_ext.reg_RW0_ren = u_g3.directory.tagArray.array_0_1_1.array.array.array_14_ext.reg_RW0_ren;
    force u_i3.directory.tagArray.array_0_1_1.u_core.rdataReg = u_g3.directory.tagArray.array_0_1_1.rdataReg;
    u_i3.directory.metaArray.array.array.array_15_ext.ram = u_g3.directory.metaArray.array.array.array_15_ext.ram;
    u_i3.directory.metaArray.array.array.array_15_ext.reg_RW0_addr = u_g3.directory.metaArray.array.array.array_15_ext.reg_RW0_addr;
    u_i3.directory.metaArray.array.array.array_15_ext.reg_RW0_ren = u_g3.directory.metaArray.array.array.array_15_ext.reg_RW0_ren;
    force u_i3.directory.metaArray.u_core.rdataReg = u_g3.directory.metaArray.rdataReg;
    u_i3.directory.replacer_sram_opt.array.array.array_16_ext.ram = u_g3.directory.replacer_sram_opt.array.array.array_16_ext.ram;
    u_i3.directory.replacer_sram_opt.array.array.array_16_ext.reg_RW0_addr = u_g3.directory.replacer_sram_opt.array.array.array_16_ext.reg_RW0_addr;
    u_i3.directory.replacer_sram_opt.array.array.array_16_ext.reg_RW0_ren = u_g3.directory.replacer_sram_opt.array.array.array_16_ext.reg_RW0_ren;
    force u_i3.directory.replacer_sram_opt.u_core.rdataReg = u_g3.directory.replacer_sram_opt.rdataReg;
    u_i3.directory.origin_bit_opt.array.array.array_17_ext.ram = u_g3.directory.origin_bit_opt.array.array.array_17_ext.ram;
    u_i3.directory.origin_bit_opt.array.array.array_17_ext.reg_RW0_addr = u_g3.directory.origin_bit_opt.array.array.array_17_ext.reg_RW0_addr;
    u_i3.directory.origin_bit_opt.array.array.array_17_ext.reg_RW0_ren = u_g3.directory.origin_bit_opt.array.array.array_17_ext.reg_RW0_ren;
    force u_i3.directory.origin_bit_opt.u_core.rdataReg = u_g3.directory.origin_bit_opt.rdataReg;
    u_i3.dataStorage.array.array_0_0_0.array.array.array_18_ext.ram = u_g3.dataStorage.array.array_0_0_0.array.array.array_18_ext.ram;
    u_i3.dataStorage.array.array_0_0_0.array.array.array_18_ext.reg_RW0_addr = u_g3.dataStorage.array.array_0_0_0.array.array.array_18_ext.reg_RW0_addr;
    u_i3.dataStorage.array.array_0_0_0.array.array.array_18_ext.reg_RW0_ren = u_g3.dataStorage.array.array_0_0_0.array.array.array_18_ext.reg_RW0_ren;
    force u_i3.dataStorage.array.array_0_0_0.u_core.rdataReg = u_g3.dataStorage.array.array_0_0_0.rdataReg;
    u_i3.dataStorage.array.array_0_0_1.array.array.array_18_ext.ram = u_g3.dataStorage.array.array_0_0_1.array.array.array_18_ext.ram;
    u_i3.dataStorage.array.array_0_0_1.array.array.array_18_ext.reg_RW0_addr = u_g3.dataStorage.array.array_0_0_1.array.array.array_18_ext.reg_RW0_addr;
    u_i3.dataStorage.array.array_0_0_1.array.array.array_18_ext.reg_RW0_ren = u_g3.dataStorage.array.array_0_0_1.array.array.array_18_ext.reg_RW0_ren;
    force u_i3.dataStorage.array.array_0_0_1.u_core.rdataReg = u_g3.dataStorage.array.array_0_0_1.rdataReg;
    u_i3.dataStorage.array.array_0_0_2.array.array.array_18_ext.ram = u_g3.dataStorage.array.array_0_0_2.array.array.array_18_ext.ram;
    u_i3.dataStorage.array.array_0_0_2.array.array.array_18_ext.reg_RW0_addr = u_g3.dataStorage.array.array_0_0_2.array.array.array_18_ext.reg_RW0_addr;
    u_i3.dataStorage.array.array_0_0_2.array.array.array_18_ext.reg_RW0_ren = u_g3.dataStorage.array.array_0_0_2.array.array.array_18_ext.reg_RW0_ren;
    force u_i3.dataStorage.array.array_0_0_2.u_core.rdataReg = u_g3.dataStorage.array.array_0_0_2.rdataReg;
    u_i3.dataStorage.array.array_0_0_3.array.array.array_18_ext.ram = u_g3.dataStorage.array.array_0_0_3.array.array.array_18_ext.ram;
    u_i3.dataStorage.array.array_0_0_3.array.array.array_18_ext.reg_RW0_addr = u_g3.dataStorage.array.array_0_0_3.array.array.array_18_ext.reg_RW0_addr;
    u_i3.dataStorage.array.array_0_0_3.array.array.array_18_ext.reg_RW0_ren = u_g3.dataStorage.array.array_0_0_3.array.array.array_18_ext.reg_RW0_ren;
    force u_i3.dataStorage.array.array_0_0_3.u_core.rdataReg = u_g3.dataStorage.array.array_0_0_3.rdataReg;
    force u_i3.dataStorage.u_core.error_REG = u_g3.dataStorage.error_REG;
    force u_i3.dataStorage.u_core.error_REG_1 = u_g3.dataStorage.error_REG_1;
    force u_i3.mbistPl.u_core.g_node_return.pipelineDataOutReg = u_g3.mbistPl.pipelineDataOutReg;
    u_i3.u_core.txreq.u_core.queue.ram_ext.Memory = u_g3.txreq.queue.ram_ext.Memory;
    u_i3.u_core.txrsp.u_core.queue.ram_ext.Memory = u_g3.txrsp.queue.ram_ext.Memory;
    force u_i3.u_core.io_error_bits_REG_valid = u_g3.io_error_bits_REG_valid;
    force u_i3.u_core.io_error_bits_REG_address = u_g3.io_error_bits_REG_address;
    force u_i3.u_core.io_perf_0_value_REG = u_g3.io_perf_0_value_REG;
    force u_i3.u_core.io_perf_0_value_REG_1 = u_g3.io_perf_0_value_REG_1;
    force u_i3.u_core.io_perf_1_value_REG = u_g3.io_perf_1_value_REG;
    force u_i3.u_core.io_perf_1_value_REG_1 = u_g3.io_perf_1_value_REG_1;
    force u_i3.u_core.io_perf_3_value_REG = u_g3.io_perf_3_value_REG;
    force u_i3.u_core.io_perf_3_value_REG_1 = u_g3.io_perf_3_value_REG_1;
    force u_i3.u_core.io_perf_4_value_REG = u_g3.io_perf_4_value_REG;
    force u_i3.u_core.io_perf_4_value_REG_1 = u_g3.io_perf_4_value_REG_1;
    force u_i3.u_core.io_perf_5_value_REG = u_g3.io_perf_5_value_REG;
    force u_i3.u_core.io_perf_5_value_REG_1 = u_g3.io_perf_5_value_REG_1;
    force u_i3.u_core.io_perf_6_value_REG = u_g3.io_perf_6_value_REG;
    force u_i3.u_core.io_perf_6_value_REG_1 = u_g3.io_perf_6_value_REG_1;
    force u_i3.u_core.io_perf_7_value_REG = u_g3.io_perf_7_value_REG;
    force u_i3.u_core.io_perf_7_value_REG_1 = u_g3.io_perf_7_value_REG_1;
    force u_i3.u_core.io_perf_8_value_REG = u_g3.io_perf_8_value_REG;
    force u_i3.u_core.io_perf_8_value_REG_1 = u_g3.io_perf_8_value_REG_1;
    force u_i3.u_core.io_perf_9_value_REG = u_g3.io_perf_9_value_REG;
    force u_i3.u_core.io_perf_9_value_REG_1 = u_g3.io_perf_9_value_REG_1;
    force u_i3.u_core.io_perf_10_value_REG = u_g3.io_perf_10_value_REG;
    force u_i3.u_core.io_perf_10_value_REG_1 = u_g3.io_perf_10_value_REG_1;
    force u_i3.u_core.io_perf_11_value_REG = u_g3.io_perf_11_value_REG;
    force u_i3.u_core.io_perf_11_value_REG_1 = u_g3.io_perf_11_value_REG_1;
    force u_i3.u_core.io_perf_12_value_REG = u_g3.io_perf_12_value_REG;
    force u_i3.u_core.io_perf_12_value_REG_1 = u_g3.io_perf_12_value_REG_1;
    force u_i3.u_core.io_perf_13_value_REG = u_g3.io_perf_13_value_REG;
    force u_i3.u_core.io_perf_13_value_REG_1 = u_g3.io_perf_13_value_REG_1;
    force u_i3.u_core.io_perf_14_value_REG = u_g3.io_perf_14_value_REG;
    force u_i3.u_core.io_perf_14_value_REG_1 = u_g3.io_perf_14_value_REG_1;
    force u_i3.u_core.io_perf_15_value_REG = u_g3.io_perf_15_value_REG;
    force u_i3.u_core.io_perf_15_value_REG_1 = u_g3.io_perf_15_value_REG_1;
    force u_i3.u_core.io_perf_16_value_REG = u_g3.io_perf_16_value_REG;
    force u_i3.u_core.io_perf_16_value_REG_1 = u_g3.io_perf_16_value_REG_1;
    #1;
    release u_i0.u_core.mshrCtl.u_core.mshrs[0].entry.u_core.tgtid_rcompack;
    release u_i0.u_core.mshrCtl.u_core.mshrs[0].entry.u_core.txnid_rcompack;
    release u_i0.u_core.mshrCtl.u_core.mshrs[0].entry.u_core.tgtid_wcompack;
    release u_i0.u_core.mshrCtl.u_core.mshrs[0].entry.u_core.txnid_wcompack;
    release u_i0.u_core.mshrCtl.u_core.mshrs[0].entry.u_core.srcid_retryack;
    release u_i0.u_core.mshrCtl.u_core.mshrs[0].entry.u_core.acquire_ts;
    release u_i0.u_core.mshrCtl.u_core.mshrs[0].entry.u_core.release_ts;
    release u_i0.u_core.mshrCtl.u_core.mshrs[0].entry.u_core.acquire_period_valid_REG;
    release u_i0.u_core.mshrCtl.u_core.mshrs[0].entry.u_core.release_period_valid_REG;
    release u_i0.u_core.mshrCtl.u_core.mshrs[0].entry.u_core.REG;
    release u_i0.u_core.mshrCtl.u_core.mshrs[0].entry.u_core.REG_1;
    release u_i0.u_core.mshrCtl.u_core.mshrs[0].entry.u_core.REG_2;
    release u_i0.u_core.mshrCtl.u_core.mshrs[0].entry.u_core.REG_3;
    release u_i0.u_core.mshrCtl.u_core.mshrs[1].entry.u_core.tgtid_rcompack;
    release u_i0.u_core.mshrCtl.u_core.mshrs[1].entry.u_core.txnid_rcompack;
    release u_i0.u_core.mshrCtl.u_core.mshrs[1].entry.u_core.tgtid_wcompack;
    release u_i0.u_core.mshrCtl.u_core.mshrs[1].entry.u_core.txnid_wcompack;
    release u_i0.u_core.mshrCtl.u_core.mshrs[1].entry.u_core.srcid_retryack;
    release u_i0.u_core.mshrCtl.u_core.mshrs[1].entry.u_core.acquire_ts;
    release u_i0.u_core.mshrCtl.u_core.mshrs[1].entry.u_core.release_ts;
    release u_i0.u_core.mshrCtl.u_core.mshrs[1].entry.u_core.acquire_period_valid_REG;
    release u_i0.u_core.mshrCtl.u_core.mshrs[1].entry.u_core.release_period_valid_REG;
    release u_i0.u_core.mshrCtl.u_core.mshrs[1].entry.u_core.REG;
    release u_i0.u_core.mshrCtl.u_core.mshrs[1].entry.u_core.REG_1;
    release u_i0.u_core.mshrCtl.u_core.mshrs[1].entry.u_core.REG_2;
    release u_i0.u_core.mshrCtl.u_core.mshrs[1].entry.u_core.REG_3;
    release u_i0.u_core.mshrCtl.u_core.mshrs[2].entry.u_core.tgtid_rcompack;
    release u_i0.u_core.mshrCtl.u_core.mshrs[2].entry.u_core.txnid_rcompack;
    release u_i0.u_core.mshrCtl.u_core.mshrs[2].entry.u_core.tgtid_wcompack;
    release u_i0.u_core.mshrCtl.u_core.mshrs[2].entry.u_core.txnid_wcompack;
    release u_i0.u_core.mshrCtl.u_core.mshrs[2].entry.u_core.srcid_retryack;
    release u_i0.u_core.mshrCtl.u_core.mshrs[2].entry.u_core.acquire_ts;
    release u_i0.u_core.mshrCtl.u_core.mshrs[2].entry.u_core.release_ts;
    release u_i0.u_core.mshrCtl.u_core.mshrs[2].entry.u_core.acquire_period_valid_REG;
    release u_i0.u_core.mshrCtl.u_core.mshrs[2].entry.u_core.release_period_valid_REG;
    release u_i0.u_core.mshrCtl.u_core.mshrs[2].entry.u_core.REG;
    release u_i0.u_core.mshrCtl.u_core.mshrs[2].entry.u_core.REG_1;
    release u_i0.u_core.mshrCtl.u_core.mshrs[2].entry.u_core.REG_2;
    release u_i0.u_core.mshrCtl.u_core.mshrs[2].entry.u_core.REG_3;
    release u_i0.u_core.mshrCtl.u_core.mshrs[3].entry.u_core.tgtid_rcompack;
    release u_i0.u_core.mshrCtl.u_core.mshrs[3].entry.u_core.txnid_rcompack;
    release u_i0.u_core.mshrCtl.u_core.mshrs[3].entry.u_core.tgtid_wcompack;
    release u_i0.u_core.mshrCtl.u_core.mshrs[3].entry.u_core.txnid_wcompack;
    release u_i0.u_core.mshrCtl.u_core.mshrs[3].entry.u_core.srcid_retryack;
    release u_i0.u_core.mshrCtl.u_core.mshrs[3].entry.u_core.acquire_ts;
    release u_i0.u_core.mshrCtl.u_core.mshrs[3].entry.u_core.release_ts;
    release u_i0.u_core.mshrCtl.u_core.mshrs[3].entry.u_core.acquire_period_valid_REG;
    release u_i0.u_core.mshrCtl.u_core.mshrs[3].entry.u_core.release_period_valid_REG;
    release u_i0.u_core.mshrCtl.u_core.mshrs[3].entry.u_core.REG;
    release u_i0.u_core.mshrCtl.u_core.mshrs[3].entry.u_core.REG_1;
    release u_i0.u_core.mshrCtl.u_core.mshrs[3].entry.u_core.REG_2;
    release u_i0.u_core.mshrCtl.u_core.mshrs[3].entry.u_core.REG_3;
    release u_i0.u_core.mshrCtl.u_core.mshrs[4].entry.u_core.tgtid_rcompack;
    release u_i0.u_core.mshrCtl.u_core.mshrs[4].entry.u_core.txnid_rcompack;
    release u_i0.u_core.mshrCtl.u_core.mshrs[4].entry.u_core.tgtid_wcompack;
    release u_i0.u_core.mshrCtl.u_core.mshrs[4].entry.u_core.txnid_wcompack;
    release u_i0.u_core.mshrCtl.u_core.mshrs[4].entry.u_core.srcid_retryack;
    release u_i0.u_core.mshrCtl.u_core.mshrs[4].entry.u_core.acquire_ts;
    release u_i0.u_core.mshrCtl.u_core.mshrs[4].entry.u_core.release_ts;
    release u_i0.u_core.mshrCtl.u_core.mshrs[4].entry.u_core.acquire_period_valid_REG;
    release u_i0.u_core.mshrCtl.u_core.mshrs[4].entry.u_core.release_period_valid_REG;
    release u_i0.u_core.mshrCtl.u_core.mshrs[4].entry.u_core.REG;
    release u_i0.u_core.mshrCtl.u_core.mshrs[4].entry.u_core.REG_1;
    release u_i0.u_core.mshrCtl.u_core.mshrs[4].entry.u_core.REG_2;
    release u_i0.u_core.mshrCtl.u_core.mshrs[4].entry.u_core.REG_3;
    release u_i0.u_core.mshrCtl.u_core.mshrs[5].entry.u_core.tgtid_rcompack;
    release u_i0.u_core.mshrCtl.u_core.mshrs[5].entry.u_core.txnid_rcompack;
    release u_i0.u_core.mshrCtl.u_core.mshrs[5].entry.u_core.tgtid_wcompack;
    release u_i0.u_core.mshrCtl.u_core.mshrs[5].entry.u_core.txnid_wcompack;
    release u_i0.u_core.mshrCtl.u_core.mshrs[5].entry.u_core.srcid_retryack;
    release u_i0.u_core.mshrCtl.u_core.mshrs[5].entry.u_core.acquire_ts;
    release u_i0.u_core.mshrCtl.u_core.mshrs[5].entry.u_core.release_ts;
    release u_i0.u_core.mshrCtl.u_core.mshrs[5].entry.u_core.acquire_period_valid_REG;
    release u_i0.u_core.mshrCtl.u_core.mshrs[5].entry.u_core.release_period_valid_REG;
    release u_i0.u_core.mshrCtl.u_core.mshrs[5].entry.u_core.REG;
    release u_i0.u_core.mshrCtl.u_core.mshrs[5].entry.u_core.REG_1;
    release u_i0.u_core.mshrCtl.u_core.mshrs[5].entry.u_core.REG_2;
    release u_i0.u_core.mshrCtl.u_core.mshrs[5].entry.u_core.REG_3;
    release u_i0.u_core.mshrCtl.u_core.mshrs[6].entry.u_core.tgtid_rcompack;
    release u_i0.u_core.mshrCtl.u_core.mshrs[6].entry.u_core.txnid_rcompack;
    release u_i0.u_core.mshrCtl.u_core.mshrs[6].entry.u_core.tgtid_wcompack;
    release u_i0.u_core.mshrCtl.u_core.mshrs[6].entry.u_core.txnid_wcompack;
    release u_i0.u_core.mshrCtl.u_core.mshrs[6].entry.u_core.srcid_retryack;
    release u_i0.u_core.mshrCtl.u_core.mshrs[6].entry.u_core.acquire_ts;
    release u_i0.u_core.mshrCtl.u_core.mshrs[6].entry.u_core.release_ts;
    release u_i0.u_core.mshrCtl.u_core.mshrs[6].entry.u_core.acquire_period_valid_REG;
    release u_i0.u_core.mshrCtl.u_core.mshrs[6].entry.u_core.release_period_valid_REG;
    release u_i0.u_core.mshrCtl.u_core.mshrs[6].entry.u_core.REG;
    release u_i0.u_core.mshrCtl.u_core.mshrs[6].entry.u_core.REG_1;
    release u_i0.u_core.mshrCtl.u_core.mshrs[6].entry.u_core.REG_2;
    release u_i0.u_core.mshrCtl.u_core.mshrs[6].entry.u_core.REG_3;
    release u_i0.u_core.mshrCtl.u_core.mshrs[7].entry.u_core.tgtid_rcompack;
    release u_i0.u_core.mshrCtl.u_core.mshrs[7].entry.u_core.txnid_rcompack;
    release u_i0.u_core.mshrCtl.u_core.mshrs[7].entry.u_core.tgtid_wcompack;
    release u_i0.u_core.mshrCtl.u_core.mshrs[7].entry.u_core.txnid_wcompack;
    release u_i0.u_core.mshrCtl.u_core.mshrs[7].entry.u_core.srcid_retryack;
    release u_i0.u_core.mshrCtl.u_core.mshrs[7].entry.u_core.acquire_ts;
    release u_i0.u_core.mshrCtl.u_core.mshrs[7].entry.u_core.release_ts;
    release u_i0.u_core.mshrCtl.u_core.mshrs[7].entry.u_core.acquire_period_valid_REG;
    release u_i0.u_core.mshrCtl.u_core.mshrs[7].entry.u_core.release_period_valid_REG;
    release u_i0.u_core.mshrCtl.u_core.mshrs[7].entry.u_core.REG;
    release u_i0.u_core.mshrCtl.u_core.mshrs[7].entry.u_core.REG_1;
    release u_i0.u_core.mshrCtl.u_core.mshrs[7].entry.u_core.REG_2;
    release u_i0.u_core.mshrCtl.u_core.mshrs[7].entry.u_core.REG_3;
    release u_i0.u_core.mshrCtl.u_core.mshrs[8].entry.u_core.tgtid_rcompack;
    release u_i0.u_core.mshrCtl.u_core.mshrs[8].entry.u_core.txnid_rcompack;
    release u_i0.u_core.mshrCtl.u_core.mshrs[8].entry.u_core.tgtid_wcompack;
    release u_i0.u_core.mshrCtl.u_core.mshrs[8].entry.u_core.txnid_wcompack;
    release u_i0.u_core.mshrCtl.u_core.mshrs[8].entry.u_core.srcid_retryack;
    release u_i0.u_core.mshrCtl.u_core.mshrs[8].entry.u_core.acquire_ts;
    release u_i0.u_core.mshrCtl.u_core.mshrs[8].entry.u_core.release_ts;
    release u_i0.u_core.mshrCtl.u_core.mshrs[8].entry.u_core.acquire_period_valid_REG;
    release u_i0.u_core.mshrCtl.u_core.mshrs[8].entry.u_core.release_period_valid_REG;
    release u_i0.u_core.mshrCtl.u_core.mshrs[8].entry.u_core.REG;
    release u_i0.u_core.mshrCtl.u_core.mshrs[8].entry.u_core.REG_1;
    release u_i0.u_core.mshrCtl.u_core.mshrs[8].entry.u_core.REG_2;
    release u_i0.u_core.mshrCtl.u_core.mshrs[8].entry.u_core.REG_3;
    release u_i0.u_core.mshrCtl.u_core.mshrs[9].entry.u_core.tgtid_rcompack;
    release u_i0.u_core.mshrCtl.u_core.mshrs[9].entry.u_core.txnid_rcompack;
    release u_i0.u_core.mshrCtl.u_core.mshrs[9].entry.u_core.tgtid_wcompack;
    release u_i0.u_core.mshrCtl.u_core.mshrs[9].entry.u_core.txnid_wcompack;
    release u_i0.u_core.mshrCtl.u_core.mshrs[9].entry.u_core.srcid_retryack;
    release u_i0.u_core.mshrCtl.u_core.mshrs[9].entry.u_core.acquire_ts;
    release u_i0.u_core.mshrCtl.u_core.mshrs[9].entry.u_core.release_ts;
    release u_i0.u_core.mshrCtl.u_core.mshrs[9].entry.u_core.acquire_period_valid_REG;
    release u_i0.u_core.mshrCtl.u_core.mshrs[9].entry.u_core.release_period_valid_REG;
    release u_i0.u_core.mshrCtl.u_core.mshrs[9].entry.u_core.REG;
    release u_i0.u_core.mshrCtl.u_core.mshrs[9].entry.u_core.REG_1;
    release u_i0.u_core.mshrCtl.u_core.mshrs[9].entry.u_core.REG_2;
    release u_i0.u_core.mshrCtl.u_core.mshrs[9].entry.u_core.REG_3;
    release u_i0.u_core.mshrCtl.u_core.mshrs[10].entry.u_core.tgtid_rcompack;
    release u_i0.u_core.mshrCtl.u_core.mshrs[10].entry.u_core.txnid_rcompack;
    release u_i0.u_core.mshrCtl.u_core.mshrs[10].entry.u_core.tgtid_wcompack;
    release u_i0.u_core.mshrCtl.u_core.mshrs[10].entry.u_core.txnid_wcompack;
    release u_i0.u_core.mshrCtl.u_core.mshrs[10].entry.u_core.srcid_retryack;
    release u_i0.u_core.mshrCtl.u_core.mshrs[10].entry.u_core.acquire_ts;
    release u_i0.u_core.mshrCtl.u_core.mshrs[10].entry.u_core.release_ts;
    release u_i0.u_core.mshrCtl.u_core.mshrs[10].entry.u_core.acquire_period_valid_REG;
    release u_i0.u_core.mshrCtl.u_core.mshrs[10].entry.u_core.release_period_valid_REG;
    release u_i0.u_core.mshrCtl.u_core.mshrs[10].entry.u_core.REG;
    release u_i0.u_core.mshrCtl.u_core.mshrs[10].entry.u_core.REG_1;
    release u_i0.u_core.mshrCtl.u_core.mshrs[10].entry.u_core.REG_2;
    release u_i0.u_core.mshrCtl.u_core.mshrs[10].entry.u_core.REG_3;
    release u_i0.u_core.mshrCtl.u_core.mshrs[11].entry.u_core.tgtid_rcompack;
    release u_i0.u_core.mshrCtl.u_core.mshrs[11].entry.u_core.txnid_rcompack;
    release u_i0.u_core.mshrCtl.u_core.mshrs[11].entry.u_core.tgtid_wcompack;
    release u_i0.u_core.mshrCtl.u_core.mshrs[11].entry.u_core.txnid_wcompack;
    release u_i0.u_core.mshrCtl.u_core.mshrs[11].entry.u_core.srcid_retryack;
    release u_i0.u_core.mshrCtl.u_core.mshrs[11].entry.u_core.acquire_ts;
    release u_i0.u_core.mshrCtl.u_core.mshrs[11].entry.u_core.release_ts;
    release u_i0.u_core.mshrCtl.u_core.mshrs[11].entry.u_core.acquire_period_valid_REG;
    release u_i0.u_core.mshrCtl.u_core.mshrs[11].entry.u_core.release_period_valid_REG;
    release u_i0.u_core.mshrCtl.u_core.mshrs[11].entry.u_core.REG;
    release u_i0.u_core.mshrCtl.u_core.mshrs[11].entry.u_core.REG_1;
    release u_i0.u_core.mshrCtl.u_core.mshrs[11].entry.u_core.REG_2;
    release u_i0.u_core.mshrCtl.u_core.mshrs[11].entry.u_core.REG_3;
    release u_i0.u_core.mshrCtl.u_core.mshrs[12].entry.u_core.tgtid_rcompack;
    release u_i0.u_core.mshrCtl.u_core.mshrs[12].entry.u_core.txnid_rcompack;
    release u_i0.u_core.mshrCtl.u_core.mshrs[12].entry.u_core.tgtid_wcompack;
    release u_i0.u_core.mshrCtl.u_core.mshrs[12].entry.u_core.txnid_wcompack;
    release u_i0.u_core.mshrCtl.u_core.mshrs[12].entry.u_core.srcid_retryack;
    release u_i0.u_core.mshrCtl.u_core.mshrs[12].entry.u_core.acquire_ts;
    release u_i0.u_core.mshrCtl.u_core.mshrs[12].entry.u_core.release_ts;
    release u_i0.u_core.mshrCtl.u_core.mshrs[12].entry.u_core.acquire_period_valid_REG;
    release u_i0.u_core.mshrCtl.u_core.mshrs[12].entry.u_core.release_period_valid_REG;
    release u_i0.u_core.mshrCtl.u_core.mshrs[12].entry.u_core.REG;
    release u_i0.u_core.mshrCtl.u_core.mshrs[12].entry.u_core.REG_1;
    release u_i0.u_core.mshrCtl.u_core.mshrs[12].entry.u_core.REG_2;
    release u_i0.u_core.mshrCtl.u_core.mshrs[12].entry.u_core.REG_3;
    release u_i0.u_core.mshrCtl.u_core.mshrs[13].entry.u_core.tgtid_rcompack;
    release u_i0.u_core.mshrCtl.u_core.mshrs[13].entry.u_core.txnid_rcompack;
    release u_i0.u_core.mshrCtl.u_core.mshrs[13].entry.u_core.tgtid_wcompack;
    release u_i0.u_core.mshrCtl.u_core.mshrs[13].entry.u_core.txnid_wcompack;
    release u_i0.u_core.mshrCtl.u_core.mshrs[13].entry.u_core.srcid_retryack;
    release u_i0.u_core.mshrCtl.u_core.mshrs[13].entry.u_core.acquire_ts;
    release u_i0.u_core.mshrCtl.u_core.mshrs[13].entry.u_core.release_ts;
    release u_i0.u_core.mshrCtl.u_core.mshrs[13].entry.u_core.acquire_period_valid_REG;
    release u_i0.u_core.mshrCtl.u_core.mshrs[13].entry.u_core.release_period_valid_REG;
    release u_i0.u_core.mshrCtl.u_core.mshrs[13].entry.u_core.REG;
    release u_i0.u_core.mshrCtl.u_core.mshrs[13].entry.u_core.REG_1;
    release u_i0.u_core.mshrCtl.u_core.mshrs[13].entry.u_core.REG_2;
    release u_i0.u_core.mshrCtl.u_core.mshrs[13].entry.u_core.REG_3;
    release u_i0.u_core.mshrCtl.u_core.mshrs[14].entry.u_core.tgtid_rcompack;
    release u_i0.u_core.mshrCtl.u_core.mshrs[14].entry.u_core.txnid_rcompack;
    release u_i0.u_core.mshrCtl.u_core.mshrs[14].entry.u_core.tgtid_wcompack;
    release u_i0.u_core.mshrCtl.u_core.mshrs[14].entry.u_core.txnid_wcompack;
    release u_i0.u_core.mshrCtl.u_core.mshrs[14].entry.u_core.srcid_retryack;
    release u_i0.u_core.mshrCtl.u_core.mshrs[14].entry.u_core.acquire_ts;
    release u_i0.u_core.mshrCtl.u_core.mshrs[14].entry.u_core.release_ts;
    release u_i0.u_core.mshrCtl.u_core.mshrs[14].entry.u_core.acquire_period_valid_REG;
    release u_i0.u_core.mshrCtl.u_core.mshrs[14].entry.u_core.release_period_valid_REG;
    release u_i0.u_core.mshrCtl.u_core.mshrs[14].entry.u_core.REG;
    release u_i0.u_core.mshrCtl.u_core.mshrs[14].entry.u_core.REG_1;
    release u_i0.u_core.mshrCtl.u_core.mshrs[14].entry.u_core.REG_2;
    release u_i0.u_core.mshrCtl.u_core.mshrs[14].entry.u_core.REG_3;
    release u_i0.u_core.mshrCtl.u_core.mshrs[15].entry.u_core.tgtid_rcompack;
    release u_i0.u_core.mshrCtl.u_core.mshrs[15].entry.u_core.txnid_rcompack;
    release u_i0.u_core.mshrCtl.u_core.mshrs[15].entry.u_core.tgtid_wcompack;
    release u_i0.u_core.mshrCtl.u_core.mshrs[15].entry.u_core.txnid_wcompack;
    release u_i0.u_core.mshrCtl.u_core.mshrs[15].entry.u_core.srcid_retryack;
    release u_i0.u_core.mshrCtl.u_core.mshrs[15].entry.u_core.acquire_ts;
    release u_i0.u_core.mshrCtl.u_core.mshrs[15].entry.u_core.release_ts;
    release u_i0.u_core.mshrCtl.u_core.mshrs[15].entry.u_core.acquire_period_valid_REG;
    release u_i0.u_core.mshrCtl.u_core.mshrs[15].entry.u_core.release_period_valid_REG;
    release u_i0.u_core.mshrCtl.u_core.mshrs[15].entry.u_core.REG;
    release u_i0.u_core.mshrCtl.u_core.mshrs[15].entry.u_core.REG_1;
    release u_i0.u_core.mshrCtl.u_core.mshrs[15].entry.u_core.REG_2;
    release u_i0.u_core.mshrCtl.u_core.mshrs[15].entry.u_core.REG_3;
    release u_i0.u_core.mshrCtl.u_core.io_perf_0_value_REG;
    release u_i0.u_core.mshrCtl.u_core.io_perf_0_value_REG_1;
    release u_i0.u_core.mshrCtl.u_core.io_perf_1_value_REG;
    release u_i0.u_core.mshrCtl.u_core.io_perf_1_value_REG_1;
    release u_i0.u_core.mshrCtl.u_core.io_perf_3_value_REG;
    release u_i0.u_core.mshrCtl.u_core.io_perf_3_value_REG_1;
    release u_i0.u_core.mshrCtl.u_core.REG;
    release u_i0.u_core.mainPipe.u_core.data_s4;
    release u_i0.u_core.mainPipe.u_core.data_s5;
    release u_i0.u_core.mainPipe.u_core.s3DropValid_d1;
    release u_i0.u_core.mainPipe.u_core.reqDrop_s3_d1;
    release u_i0.u_core.mainPipe.u_core.reqDrop_s3_d2;
    release u_i0.u_core.mainPipe.u_core.reqDrop_s4_d1;
    release u_i0.u_core.mainPipe.u_core.perf_d1[0];
    release u_i0.u_core.mainPipe.u_core.perf[0];
    release u_i0.u_core.mainPipe.u_core.perf_d1[1];
    release u_i0.u_core.mainPipe.u_core.perf[1];
    release u_i0.u_core.mainPipe.u_core.perf_d1[2];
    release u_i0.u_core.mainPipe.u_core.perf[2];
    release u_i0.u_core.mainPipe.u_core.perf_d1[3];
    release u_i0.u_core.mainPipe.u_core.perf[3];
    release u_i0.u_core.mainPipe.u_core.perf_d1[4];
    release u_i0.u_core.mainPipe.u_core.perf[4];
    release u_i0.u_core.mainPipe.u_core.perf_d1[5];
    release u_i0.u_core.mainPipe.u_core.perf[5];
    release u_i0.u_core.mainPipe.u_core.perf_d1[6];
    release u_i0.u_core.mainPipe.u_core.perf[6];
    release u_i0.u_core.mainPipe.u_core.perf_d1[7];
    release u_i0.u_core.mainPipe.u_core.perf[7];
    release u_i0.u_core.mainPipe.u_core.perf_d1[8];
    release u_i0.u_core.mainPipe.u_core.perf[8];
    release u_i0.u_core.mainPipe.u_core.perf_d1[9];
    release u_i0.u_core.mainPipe.u_core.perf[9];
    release u_i0.u_core.mainPipe.u_core.perf_d1[10];
    release u_i0.u_core.mainPipe.u_core.perf[10];
    release u_i0.u_core.mainPipe.u_core.perf_d1[11];
    release u_i0.u_core.mainPipe.u_core.perf[11];
    release u_i0.u_core.mainPipe.u_core.perf_d1[12];
    release u_i0.u_core.mainPipe.u_core.perf[12];
    release u_i0.u_core.grantBuf.u_core.validPrev[0];
    release u_i0.u_core.grantBuf.u_core.histValidPrev[0];
    release u_i0.u_core.grantBuf.u_core.validPrev[1];
    release u_i0.u_core.grantBuf.u_core.histValidPrev[1];
    release u_i0.u_core.grantBuf.u_core.validPrev[2];
    release u_i0.u_core.grantBuf.u_core.histValidPrev[2];
    release u_i0.u_core.grantBuf.u_core.validPrev[3];
    release u_i0.u_core.grantBuf.u_core.histValidPrev[3];
    release u_i0.u_core.grantBuf.u_core.validPrev[4];
    release u_i0.u_core.grantBuf.u_core.histValidPrev[4];
    release u_i0.u_core.grantBuf.u_core.validPrev[5];
    release u_i0.u_core.grantBuf.u_core.histValidPrev[5];
    release u_i0.u_core.grantBuf.u_core.validPrev[6];
    release u_i0.u_core.grantBuf.u_core.histValidPrev[6];
    release u_i0.u_core.grantBuf.u_core.validPrev[7];
    release u_i0.u_core.grantBuf.u_core.histValidPrev[7];
    release u_i0.u_core.grantBuf.u_core.validPrev[8];
    release u_i0.u_core.grantBuf.u_core.histValidPrev[8];
    release u_i0.u_core.grantBuf.u_core.validPrev[9];
    release u_i0.u_core.grantBuf.u_core.histValidPrev[9];
    release u_i0.u_core.grantBuf.u_core.validPrev[10];
    release u_i0.u_core.grantBuf.u_core.histValidPrev[10];
    release u_i0.u_core.grantBuf.u_core.validPrev[11];
    release u_i0.u_core.grantBuf.u_core.histValidPrev[11];
    release u_i0.u_core.grantBuf.u_core.validPrev[12];
    release u_i0.u_core.grantBuf.u_core.histValidPrev[12];
    release u_i0.u_core.grantBuf.u_core.validPrev[13];
    release u_i0.u_core.grantBuf.u_core.histValidPrev[13];
    release u_i0.u_core.grantBuf.u_core.validPrev[14];
    release u_i0.u_core.grantBuf.u_core.histValidPrev[14];
    release u_i0.u_core.grantBuf.u_core.validPrev[15];
    release u_i0.u_core.grantBuf.u_core.histValidPrev[15];
    release u_i0.u_core.rxsnp.u_core.replPrevForBlock[0];
    release u_i0.u_core.rxsnp.u_core.replPrevForNest[0];
    release u_i0.u_core.rxsnp.u_core.replPrevForBlock[1];
    release u_i0.u_core.rxsnp.u_core.replPrevForNest[1];
    release u_i0.u_core.rxsnp.u_core.replPrevForBlock[2];
    release u_i0.u_core.rxsnp.u_core.replPrevForNest[2];
    release u_i0.u_core.rxsnp.u_core.replPrevForBlock[3];
    release u_i0.u_core.rxsnp.u_core.replPrevForNest[3];
    release u_i0.u_core.rxsnp.u_core.replPrevForBlock[4];
    release u_i0.u_core.rxsnp.u_core.replPrevForNest[4];
    release u_i0.u_core.rxsnp.u_core.replPrevForBlock[5];
    release u_i0.u_core.rxsnp.u_core.replPrevForNest[5];
    release u_i0.u_core.rxsnp.u_core.replPrevForBlock[6];
    release u_i0.u_core.rxsnp.u_core.replPrevForNest[6];
    release u_i0.u_core.rxsnp.u_core.replPrevForBlock[7];
    release u_i0.u_core.rxsnp.u_core.replPrevForNest[7];
    release u_i0.u_core.rxsnp.u_core.replPrevForBlock[8];
    release u_i0.u_core.rxsnp.u_core.replPrevForNest[8];
    release u_i0.u_core.rxsnp.u_core.replPrevForBlock[9];
    release u_i0.u_core.rxsnp.u_core.replPrevForNest[9];
    release u_i0.u_core.rxsnp.u_core.replPrevForBlock[10];
    release u_i0.u_core.rxsnp.u_core.replPrevForNest[10];
    release u_i0.u_core.rxsnp.u_core.replPrevForBlock[11];
    release u_i0.u_core.rxsnp.u_core.replPrevForNest[11];
    release u_i0.u_core.rxsnp.u_core.replPrevForBlock[12];
    release u_i0.u_core.rxsnp.u_core.replPrevForNest[12];
    release u_i0.u_core.rxsnp.u_core.replPrevForBlock[13];
    release u_i0.u_core.rxsnp.u_core.replPrevForNest[13];
    release u_i0.u_core.rxsnp.u_core.replPrevForBlock[14];
    release u_i0.u_core.rxsnp.u_core.replPrevForNest[14];
    release u_i0.u_core.rxsnp.u_core.replPrevForBlock[15];
    release u_i0.u_core.rxsnp.u_core.replPrevForNest[15];
    release u_i0.u_core.reqBuf.chosenQ.u_core.ram;
    release u_i0.u_core.reqBuf.u_core.hitPfPrev_set;
    release u_i0.u_core.reqBuf.u_core.hitPfPrev_tag;
    release u_i0.u_core.reqBuf.u_core.mergeAPrev_set;
    release u_i0.u_core.reqBuf.u_core.mergeAPrev_tag;
    release u_i0.u_core.reqBuf.u_core.sameSetS3Valid[0];
    release u_i0.u_core.reqBuf.u_core.sameSetS3Set[0];
    release u_i0.u_core.reqBuf.u_core.sameSetS3Valid[1];
    release u_i0.u_core.reqBuf.u_core.sameSetS3Set[1];
    release u_i0.u_core.reqBuf.u_core.sameSetS3Valid[2];
    release u_i0.u_core.reqBuf.u_core.sameSetS3Set[2];
    release u_i0.u_core.reqBuf.u_core.sameSetS3Valid[3];
    release u_i0.u_core.reqBuf.u_core.sameSetS3Set[3];
    release u_i0.u_core.reqBuf.u_core.sameSetS3Valid[4];
    release u_i0.u_core.reqBuf.u_core.sameSetS3Set[4];
    release u_i0.u_core.reqBuf.u_core.sameSetS3Valid[5];
    release u_i0.u_core.reqBuf.u_core.sameSetS3Set[5];
    release u_i0.u_core.sinkC.u_core.bufRespStage[0];
    release u_i0.u_core.sinkC.u_core.bufRespStage[1];
    release u_i0.u_core.sinkC.u_core.bufRespOut[0];
    release u_i0.u_core.sinkC.u_core.bufRespOut[1];
    release u_i0.u_core.sinkC.u_core.refillIdReg;
    release u_i0.u_core.sinkC.u_core.refillBufIdxReg;
    release u_i0.u_core.sinkC.u_core.taskFirePrev;
    release u_i0.u_core.sinkC.u_core.taskBufIdxPrev;
    release u_i0.u_core.reqArb.u_core.ds_mcp2_stall;
    release u_i0.u_core.refillBuf.u_core.buffer[0][0];
    release u_i0.u_core.refillBuf.u_core.buffer[0][1];
    release u_i0.u_core.refillBuf.u_core.buffer[1][0];
    release u_i0.u_core.refillBuf.u_core.buffer[1][1];
    release u_i0.u_core.refillBuf.u_core.buffer[2][0];
    release u_i0.u_core.refillBuf.u_core.buffer[2][1];
    release u_i0.u_core.refillBuf.u_core.buffer[3][0];
    release u_i0.u_core.refillBuf.u_core.buffer[3][1];
    release u_i0.u_core.refillBuf.u_core.buffer[4][0];
    release u_i0.u_core.refillBuf.u_core.buffer[4][1];
    release u_i0.u_core.refillBuf.u_core.buffer[5][0];
    release u_i0.u_core.refillBuf.u_core.buffer[5][1];
    release u_i0.u_core.refillBuf.u_core.buffer[6][0];
    release u_i0.u_core.refillBuf.u_core.buffer[6][1];
    release u_i0.u_core.refillBuf.u_core.buffer[7][0];
    release u_i0.u_core.refillBuf.u_core.buffer[7][1];
    release u_i0.u_core.refillBuf.u_core.buffer[8][0];
    release u_i0.u_core.refillBuf.u_core.buffer[8][1];
    release u_i0.u_core.refillBuf.u_core.buffer[9][0];
    release u_i0.u_core.refillBuf.u_core.buffer[9][1];
    release u_i0.u_core.refillBuf.u_core.buffer[10][0];
    release u_i0.u_core.refillBuf.u_core.buffer[10][1];
    release u_i0.u_core.refillBuf.u_core.buffer[11][0];
    release u_i0.u_core.refillBuf.u_core.buffer[11][1];
    release u_i0.u_core.refillBuf.u_core.buffer[12][0];
    release u_i0.u_core.refillBuf.u_core.buffer[12][1];
    release u_i0.u_core.refillBuf.u_core.buffer[13][0];
    release u_i0.u_core.refillBuf.u_core.buffer[13][1];
    release u_i0.u_core.refillBuf.u_core.buffer[14][0];
    release u_i0.u_core.refillBuf.u_core.buffer[14][1];
    release u_i0.u_core.refillBuf.u_core.buffer[15][0];
    release u_i0.u_core.refillBuf.u_core.buffer[15][1];
    release u_i0.u_core.releaseBuf.u_core.buffer[0][0];
    release u_i0.u_core.releaseBuf.u_core.buffer[0][1];
    release u_i0.u_core.releaseBuf.u_core.buffer[1][0];
    release u_i0.u_core.releaseBuf.u_core.buffer[1][1];
    release u_i0.u_core.releaseBuf.u_core.buffer[2][0];
    release u_i0.u_core.releaseBuf.u_core.buffer[2][1];
    release u_i0.u_core.releaseBuf.u_core.buffer[3][0];
    release u_i0.u_core.releaseBuf.u_core.buffer[3][1];
    release u_i0.u_core.releaseBuf.u_core.buffer[4][0];
    release u_i0.u_core.releaseBuf.u_core.buffer[4][1];
    release u_i0.u_core.releaseBuf.u_core.buffer[5][0];
    release u_i0.u_core.releaseBuf.u_core.buffer[5][1];
    release u_i0.u_core.releaseBuf.u_core.buffer[6][0];
    release u_i0.u_core.releaseBuf.u_core.buffer[6][1];
    release u_i0.u_core.releaseBuf.u_core.buffer[7][0];
    release u_i0.u_core.releaseBuf.u_core.buffer[7][1];
    release u_i0.u_core.releaseBuf.u_core.buffer[8][0];
    release u_i0.u_core.releaseBuf.u_core.buffer[8][1];
    release u_i0.u_core.releaseBuf.u_core.buffer[9][0];
    release u_i0.u_core.releaseBuf.u_core.buffer[9][1];
    release u_i0.u_core.releaseBuf.u_core.buffer[10][0];
    release u_i0.u_core.releaseBuf.u_core.buffer[10][1];
    release u_i0.u_core.releaseBuf.u_core.buffer[11][0];
    release u_i0.u_core.releaseBuf.u_core.buffer[11][1];
    release u_i0.u_core.releaseBuf.u_core.buffer[12][0];
    release u_i0.u_core.releaseBuf.u_core.buffer[12][1];
    release u_i0.u_core.releaseBuf.u_core.buffer[13][0];
    release u_i0.u_core.releaseBuf.u_core.buffer[13][1];
    release u_i0.u_core.releaseBuf.u_core.buffer[14][0];
    release u_i0.u_core.releaseBuf.u_core.buffer[14][1];
    release u_i0.u_core.releaseBuf.u_core.buffer[15][0];
    release u_i0.u_core.releaseBuf.u_core.buffer[15][1];
    release u_i0.directory.tagArray.array_0_0_0.u_core.rdataReg;
    release u_i0.directory.tagArray.array_0_0_1.u_core.rdataReg;
    release u_i0.directory.tagArray.array_0_1_0.u_core.rdataReg;
    release u_i0.directory.tagArray.array_0_1_1.u_core.rdataReg;
    release u_i0.directory.metaArray.u_core.rdataReg;
    release u_i0.directory.replacer_sram_opt.u_core.rdataReg;
    release u_i0.directory.origin_bit_opt.u_core.rdataReg;
    release u_i0.dataStorage.array.array_0_0_0.u_core.rdataReg;
    release u_i0.dataStorage.array.array_0_0_1.u_core.rdataReg;
    release u_i0.dataStorage.array.array_0_0_2.u_core.rdataReg;
    release u_i0.dataStorage.array.array_0_0_3.u_core.rdataReg;
    release u_i0.dataStorage.u_core.error_REG;
    release u_i0.dataStorage.u_core.error_REG_1;
    release u_i0.mbistPl.u_core.g_node_return.pipelineDataOutReg;
    release u_i0.u_core.io_error_bits_REG_valid;
    release u_i0.u_core.io_error_bits_REG_address;
    release u_i0.u_core.io_perf_0_value_REG;
    release u_i0.u_core.io_perf_0_value_REG_1;
    release u_i0.u_core.io_perf_1_value_REG;
    release u_i0.u_core.io_perf_1_value_REG_1;
    release u_i0.u_core.io_perf_3_value_REG;
    release u_i0.u_core.io_perf_3_value_REG_1;
    release u_i0.u_core.io_perf_4_value_REG;
    release u_i0.u_core.io_perf_4_value_REG_1;
    release u_i0.u_core.io_perf_5_value_REG;
    release u_i0.u_core.io_perf_5_value_REG_1;
    release u_i0.u_core.io_perf_6_value_REG;
    release u_i0.u_core.io_perf_6_value_REG_1;
    release u_i0.u_core.io_perf_7_value_REG;
    release u_i0.u_core.io_perf_7_value_REG_1;
    release u_i0.u_core.io_perf_8_value_REG;
    release u_i0.u_core.io_perf_8_value_REG_1;
    release u_i0.u_core.io_perf_9_value_REG;
    release u_i0.u_core.io_perf_9_value_REG_1;
    release u_i0.u_core.io_perf_10_value_REG;
    release u_i0.u_core.io_perf_10_value_REG_1;
    release u_i0.u_core.io_perf_11_value_REG;
    release u_i0.u_core.io_perf_11_value_REG_1;
    release u_i0.u_core.io_perf_12_value_REG;
    release u_i0.u_core.io_perf_12_value_REG_1;
    release u_i0.u_core.io_perf_13_value_REG;
    release u_i0.u_core.io_perf_13_value_REG_1;
    release u_i0.u_core.io_perf_14_value_REG;
    release u_i0.u_core.io_perf_14_value_REG_1;
    release u_i0.u_core.io_perf_15_value_REG;
    release u_i0.u_core.io_perf_15_value_REG_1;
    release u_i0.u_core.io_perf_16_value_REG;
    release u_i0.u_core.io_perf_16_value_REG_1;
    release u_i1.u_core.mshrCtl.u_core.mshrs[0].entry.u_core.tgtid_rcompack;
    release u_i1.u_core.mshrCtl.u_core.mshrs[0].entry.u_core.txnid_rcompack;
    release u_i1.u_core.mshrCtl.u_core.mshrs[0].entry.u_core.tgtid_wcompack;
    release u_i1.u_core.mshrCtl.u_core.mshrs[0].entry.u_core.txnid_wcompack;
    release u_i1.u_core.mshrCtl.u_core.mshrs[0].entry.u_core.srcid_retryack;
    release u_i1.u_core.mshrCtl.u_core.mshrs[0].entry.u_core.acquire_ts;
    release u_i1.u_core.mshrCtl.u_core.mshrs[0].entry.u_core.release_ts;
    release u_i1.u_core.mshrCtl.u_core.mshrs[0].entry.u_core.acquire_period_valid_REG;
    release u_i1.u_core.mshrCtl.u_core.mshrs[0].entry.u_core.release_period_valid_REG;
    release u_i1.u_core.mshrCtl.u_core.mshrs[0].entry.u_core.REG;
    release u_i1.u_core.mshrCtl.u_core.mshrs[0].entry.u_core.REG_1;
    release u_i1.u_core.mshrCtl.u_core.mshrs[0].entry.u_core.REG_2;
    release u_i1.u_core.mshrCtl.u_core.mshrs[0].entry.u_core.REG_3;
    release u_i1.u_core.mshrCtl.u_core.mshrs[1].entry.u_core.tgtid_rcompack;
    release u_i1.u_core.mshrCtl.u_core.mshrs[1].entry.u_core.txnid_rcompack;
    release u_i1.u_core.mshrCtl.u_core.mshrs[1].entry.u_core.tgtid_wcompack;
    release u_i1.u_core.mshrCtl.u_core.mshrs[1].entry.u_core.txnid_wcompack;
    release u_i1.u_core.mshrCtl.u_core.mshrs[1].entry.u_core.srcid_retryack;
    release u_i1.u_core.mshrCtl.u_core.mshrs[1].entry.u_core.acquire_ts;
    release u_i1.u_core.mshrCtl.u_core.mshrs[1].entry.u_core.release_ts;
    release u_i1.u_core.mshrCtl.u_core.mshrs[1].entry.u_core.acquire_period_valid_REG;
    release u_i1.u_core.mshrCtl.u_core.mshrs[1].entry.u_core.release_period_valid_REG;
    release u_i1.u_core.mshrCtl.u_core.mshrs[1].entry.u_core.REG;
    release u_i1.u_core.mshrCtl.u_core.mshrs[1].entry.u_core.REG_1;
    release u_i1.u_core.mshrCtl.u_core.mshrs[1].entry.u_core.REG_2;
    release u_i1.u_core.mshrCtl.u_core.mshrs[1].entry.u_core.REG_3;
    release u_i1.u_core.mshrCtl.u_core.mshrs[2].entry.u_core.tgtid_rcompack;
    release u_i1.u_core.mshrCtl.u_core.mshrs[2].entry.u_core.txnid_rcompack;
    release u_i1.u_core.mshrCtl.u_core.mshrs[2].entry.u_core.tgtid_wcompack;
    release u_i1.u_core.mshrCtl.u_core.mshrs[2].entry.u_core.txnid_wcompack;
    release u_i1.u_core.mshrCtl.u_core.mshrs[2].entry.u_core.srcid_retryack;
    release u_i1.u_core.mshrCtl.u_core.mshrs[2].entry.u_core.acquire_ts;
    release u_i1.u_core.mshrCtl.u_core.mshrs[2].entry.u_core.release_ts;
    release u_i1.u_core.mshrCtl.u_core.mshrs[2].entry.u_core.acquire_period_valid_REG;
    release u_i1.u_core.mshrCtl.u_core.mshrs[2].entry.u_core.release_period_valid_REG;
    release u_i1.u_core.mshrCtl.u_core.mshrs[2].entry.u_core.REG;
    release u_i1.u_core.mshrCtl.u_core.mshrs[2].entry.u_core.REG_1;
    release u_i1.u_core.mshrCtl.u_core.mshrs[2].entry.u_core.REG_2;
    release u_i1.u_core.mshrCtl.u_core.mshrs[2].entry.u_core.REG_3;
    release u_i1.u_core.mshrCtl.u_core.mshrs[3].entry.u_core.tgtid_rcompack;
    release u_i1.u_core.mshrCtl.u_core.mshrs[3].entry.u_core.txnid_rcompack;
    release u_i1.u_core.mshrCtl.u_core.mshrs[3].entry.u_core.tgtid_wcompack;
    release u_i1.u_core.mshrCtl.u_core.mshrs[3].entry.u_core.txnid_wcompack;
    release u_i1.u_core.mshrCtl.u_core.mshrs[3].entry.u_core.srcid_retryack;
    release u_i1.u_core.mshrCtl.u_core.mshrs[3].entry.u_core.acquire_ts;
    release u_i1.u_core.mshrCtl.u_core.mshrs[3].entry.u_core.release_ts;
    release u_i1.u_core.mshrCtl.u_core.mshrs[3].entry.u_core.acquire_period_valid_REG;
    release u_i1.u_core.mshrCtl.u_core.mshrs[3].entry.u_core.release_period_valid_REG;
    release u_i1.u_core.mshrCtl.u_core.mshrs[3].entry.u_core.REG;
    release u_i1.u_core.mshrCtl.u_core.mshrs[3].entry.u_core.REG_1;
    release u_i1.u_core.mshrCtl.u_core.mshrs[3].entry.u_core.REG_2;
    release u_i1.u_core.mshrCtl.u_core.mshrs[3].entry.u_core.REG_3;
    release u_i1.u_core.mshrCtl.u_core.mshrs[4].entry.u_core.tgtid_rcompack;
    release u_i1.u_core.mshrCtl.u_core.mshrs[4].entry.u_core.txnid_rcompack;
    release u_i1.u_core.mshrCtl.u_core.mshrs[4].entry.u_core.tgtid_wcompack;
    release u_i1.u_core.mshrCtl.u_core.mshrs[4].entry.u_core.txnid_wcompack;
    release u_i1.u_core.mshrCtl.u_core.mshrs[4].entry.u_core.srcid_retryack;
    release u_i1.u_core.mshrCtl.u_core.mshrs[4].entry.u_core.acquire_ts;
    release u_i1.u_core.mshrCtl.u_core.mshrs[4].entry.u_core.release_ts;
    release u_i1.u_core.mshrCtl.u_core.mshrs[4].entry.u_core.acquire_period_valid_REG;
    release u_i1.u_core.mshrCtl.u_core.mshrs[4].entry.u_core.release_period_valid_REG;
    release u_i1.u_core.mshrCtl.u_core.mshrs[4].entry.u_core.REG;
    release u_i1.u_core.mshrCtl.u_core.mshrs[4].entry.u_core.REG_1;
    release u_i1.u_core.mshrCtl.u_core.mshrs[4].entry.u_core.REG_2;
    release u_i1.u_core.mshrCtl.u_core.mshrs[4].entry.u_core.REG_3;
    release u_i1.u_core.mshrCtl.u_core.mshrs[5].entry.u_core.tgtid_rcompack;
    release u_i1.u_core.mshrCtl.u_core.mshrs[5].entry.u_core.txnid_rcompack;
    release u_i1.u_core.mshrCtl.u_core.mshrs[5].entry.u_core.tgtid_wcompack;
    release u_i1.u_core.mshrCtl.u_core.mshrs[5].entry.u_core.txnid_wcompack;
    release u_i1.u_core.mshrCtl.u_core.mshrs[5].entry.u_core.srcid_retryack;
    release u_i1.u_core.mshrCtl.u_core.mshrs[5].entry.u_core.acquire_ts;
    release u_i1.u_core.mshrCtl.u_core.mshrs[5].entry.u_core.release_ts;
    release u_i1.u_core.mshrCtl.u_core.mshrs[5].entry.u_core.acquire_period_valid_REG;
    release u_i1.u_core.mshrCtl.u_core.mshrs[5].entry.u_core.release_period_valid_REG;
    release u_i1.u_core.mshrCtl.u_core.mshrs[5].entry.u_core.REG;
    release u_i1.u_core.mshrCtl.u_core.mshrs[5].entry.u_core.REG_1;
    release u_i1.u_core.mshrCtl.u_core.mshrs[5].entry.u_core.REG_2;
    release u_i1.u_core.mshrCtl.u_core.mshrs[5].entry.u_core.REG_3;
    release u_i1.u_core.mshrCtl.u_core.mshrs[6].entry.u_core.tgtid_rcompack;
    release u_i1.u_core.mshrCtl.u_core.mshrs[6].entry.u_core.txnid_rcompack;
    release u_i1.u_core.mshrCtl.u_core.mshrs[6].entry.u_core.tgtid_wcompack;
    release u_i1.u_core.mshrCtl.u_core.mshrs[6].entry.u_core.txnid_wcompack;
    release u_i1.u_core.mshrCtl.u_core.mshrs[6].entry.u_core.srcid_retryack;
    release u_i1.u_core.mshrCtl.u_core.mshrs[6].entry.u_core.acquire_ts;
    release u_i1.u_core.mshrCtl.u_core.mshrs[6].entry.u_core.release_ts;
    release u_i1.u_core.mshrCtl.u_core.mshrs[6].entry.u_core.acquire_period_valid_REG;
    release u_i1.u_core.mshrCtl.u_core.mshrs[6].entry.u_core.release_period_valid_REG;
    release u_i1.u_core.mshrCtl.u_core.mshrs[6].entry.u_core.REG;
    release u_i1.u_core.mshrCtl.u_core.mshrs[6].entry.u_core.REG_1;
    release u_i1.u_core.mshrCtl.u_core.mshrs[6].entry.u_core.REG_2;
    release u_i1.u_core.mshrCtl.u_core.mshrs[6].entry.u_core.REG_3;
    release u_i1.u_core.mshrCtl.u_core.mshrs[7].entry.u_core.tgtid_rcompack;
    release u_i1.u_core.mshrCtl.u_core.mshrs[7].entry.u_core.txnid_rcompack;
    release u_i1.u_core.mshrCtl.u_core.mshrs[7].entry.u_core.tgtid_wcompack;
    release u_i1.u_core.mshrCtl.u_core.mshrs[7].entry.u_core.txnid_wcompack;
    release u_i1.u_core.mshrCtl.u_core.mshrs[7].entry.u_core.srcid_retryack;
    release u_i1.u_core.mshrCtl.u_core.mshrs[7].entry.u_core.acquire_ts;
    release u_i1.u_core.mshrCtl.u_core.mshrs[7].entry.u_core.release_ts;
    release u_i1.u_core.mshrCtl.u_core.mshrs[7].entry.u_core.acquire_period_valid_REG;
    release u_i1.u_core.mshrCtl.u_core.mshrs[7].entry.u_core.release_period_valid_REG;
    release u_i1.u_core.mshrCtl.u_core.mshrs[7].entry.u_core.REG;
    release u_i1.u_core.mshrCtl.u_core.mshrs[7].entry.u_core.REG_1;
    release u_i1.u_core.mshrCtl.u_core.mshrs[7].entry.u_core.REG_2;
    release u_i1.u_core.mshrCtl.u_core.mshrs[7].entry.u_core.REG_3;
    release u_i1.u_core.mshrCtl.u_core.mshrs[8].entry.u_core.tgtid_rcompack;
    release u_i1.u_core.mshrCtl.u_core.mshrs[8].entry.u_core.txnid_rcompack;
    release u_i1.u_core.mshrCtl.u_core.mshrs[8].entry.u_core.tgtid_wcompack;
    release u_i1.u_core.mshrCtl.u_core.mshrs[8].entry.u_core.txnid_wcompack;
    release u_i1.u_core.mshrCtl.u_core.mshrs[8].entry.u_core.srcid_retryack;
    release u_i1.u_core.mshrCtl.u_core.mshrs[8].entry.u_core.acquire_ts;
    release u_i1.u_core.mshrCtl.u_core.mshrs[8].entry.u_core.release_ts;
    release u_i1.u_core.mshrCtl.u_core.mshrs[8].entry.u_core.acquire_period_valid_REG;
    release u_i1.u_core.mshrCtl.u_core.mshrs[8].entry.u_core.release_period_valid_REG;
    release u_i1.u_core.mshrCtl.u_core.mshrs[8].entry.u_core.REG;
    release u_i1.u_core.mshrCtl.u_core.mshrs[8].entry.u_core.REG_1;
    release u_i1.u_core.mshrCtl.u_core.mshrs[8].entry.u_core.REG_2;
    release u_i1.u_core.mshrCtl.u_core.mshrs[8].entry.u_core.REG_3;
    release u_i1.u_core.mshrCtl.u_core.mshrs[9].entry.u_core.tgtid_rcompack;
    release u_i1.u_core.mshrCtl.u_core.mshrs[9].entry.u_core.txnid_rcompack;
    release u_i1.u_core.mshrCtl.u_core.mshrs[9].entry.u_core.tgtid_wcompack;
    release u_i1.u_core.mshrCtl.u_core.mshrs[9].entry.u_core.txnid_wcompack;
    release u_i1.u_core.mshrCtl.u_core.mshrs[9].entry.u_core.srcid_retryack;
    release u_i1.u_core.mshrCtl.u_core.mshrs[9].entry.u_core.acquire_ts;
    release u_i1.u_core.mshrCtl.u_core.mshrs[9].entry.u_core.release_ts;
    release u_i1.u_core.mshrCtl.u_core.mshrs[9].entry.u_core.acquire_period_valid_REG;
    release u_i1.u_core.mshrCtl.u_core.mshrs[9].entry.u_core.release_period_valid_REG;
    release u_i1.u_core.mshrCtl.u_core.mshrs[9].entry.u_core.REG;
    release u_i1.u_core.mshrCtl.u_core.mshrs[9].entry.u_core.REG_1;
    release u_i1.u_core.mshrCtl.u_core.mshrs[9].entry.u_core.REG_2;
    release u_i1.u_core.mshrCtl.u_core.mshrs[9].entry.u_core.REG_3;
    release u_i1.u_core.mshrCtl.u_core.mshrs[10].entry.u_core.tgtid_rcompack;
    release u_i1.u_core.mshrCtl.u_core.mshrs[10].entry.u_core.txnid_rcompack;
    release u_i1.u_core.mshrCtl.u_core.mshrs[10].entry.u_core.tgtid_wcompack;
    release u_i1.u_core.mshrCtl.u_core.mshrs[10].entry.u_core.txnid_wcompack;
    release u_i1.u_core.mshrCtl.u_core.mshrs[10].entry.u_core.srcid_retryack;
    release u_i1.u_core.mshrCtl.u_core.mshrs[10].entry.u_core.acquire_ts;
    release u_i1.u_core.mshrCtl.u_core.mshrs[10].entry.u_core.release_ts;
    release u_i1.u_core.mshrCtl.u_core.mshrs[10].entry.u_core.acquire_period_valid_REG;
    release u_i1.u_core.mshrCtl.u_core.mshrs[10].entry.u_core.release_period_valid_REG;
    release u_i1.u_core.mshrCtl.u_core.mshrs[10].entry.u_core.REG;
    release u_i1.u_core.mshrCtl.u_core.mshrs[10].entry.u_core.REG_1;
    release u_i1.u_core.mshrCtl.u_core.mshrs[10].entry.u_core.REG_2;
    release u_i1.u_core.mshrCtl.u_core.mshrs[10].entry.u_core.REG_3;
    release u_i1.u_core.mshrCtl.u_core.mshrs[11].entry.u_core.tgtid_rcompack;
    release u_i1.u_core.mshrCtl.u_core.mshrs[11].entry.u_core.txnid_rcompack;
    release u_i1.u_core.mshrCtl.u_core.mshrs[11].entry.u_core.tgtid_wcompack;
    release u_i1.u_core.mshrCtl.u_core.mshrs[11].entry.u_core.txnid_wcompack;
    release u_i1.u_core.mshrCtl.u_core.mshrs[11].entry.u_core.srcid_retryack;
    release u_i1.u_core.mshrCtl.u_core.mshrs[11].entry.u_core.acquire_ts;
    release u_i1.u_core.mshrCtl.u_core.mshrs[11].entry.u_core.release_ts;
    release u_i1.u_core.mshrCtl.u_core.mshrs[11].entry.u_core.acquire_period_valid_REG;
    release u_i1.u_core.mshrCtl.u_core.mshrs[11].entry.u_core.release_period_valid_REG;
    release u_i1.u_core.mshrCtl.u_core.mshrs[11].entry.u_core.REG;
    release u_i1.u_core.mshrCtl.u_core.mshrs[11].entry.u_core.REG_1;
    release u_i1.u_core.mshrCtl.u_core.mshrs[11].entry.u_core.REG_2;
    release u_i1.u_core.mshrCtl.u_core.mshrs[11].entry.u_core.REG_3;
    release u_i1.u_core.mshrCtl.u_core.mshrs[12].entry.u_core.tgtid_rcompack;
    release u_i1.u_core.mshrCtl.u_core.mshrs[12].entry.u_core.txnid_rcompack;
    release u_i1.u_core.mshrCtl.u_core.mshrs[12].entry.u_core.tgtid_wcompack;
    release u_i1.u_core.mshrCtl.u_core.mshrs[12].entry.u_core.txnid_wcompack;
    release u_i1.u_core.mshrCtl.u_core.mshrs[12].entry.u_core.srcid_retryack;
    release u_i1.u_core.mshrCtl.u_core.mshrs[12].entry.u_core.acquire_ts;
    release u_i1.u_core.mshrCtl.u_core.mshrs[12].entry.u_core.release_ts;
    release u_i1.u_core.mshrCtl.u_core.mshrs[12].entry.u_core.acquire_period_valid_REG;
    release u_i1.u_core.mshrCtl.u_core.mshrs[12].entry.u_core.release_period_valid_REG;
    release u_i1.u_core.mshrCtl.u_core.mshrs[12].entry.u_core.REG;
    release u_i1.u_core.mshrCtl.u_core.mshrs[12].entry.u_core.REG_1;
    release u_i1.u_core.mshrCtl.u_core.mshrs[12].entry.u_core.REG_2;
    release u_i1.u_core.mshrCtl.u_core.mshrs[12].entry.u_core.REG_3;
    release u_i1.u_core.mshrCtl.u_core.mshrs[13].entry.u_core.tgtid_rcompack;
    release u_i1.u_core.mshrCtl.u_core.mshrs[13].entry.u_core.txnid_rcompack;
    release u_i1.u_core.mshrCtl.u_core.mshrs[13].entry.u_core.tgtid_wcompack;
    release u_i1.u_core.mshrCtl.u_core.mshrs[13].entry.u_core.txnid_wcompack;
    release u_i1.u_core.mshrCtl.u_core.mshrs[13].entry.u_core.srcid_retryack;
    release u_i1.u_core.mshrCtl.u_core.mshrs[13].entry.u_core.acquire_ts;
    release u_i1.u_core.mshrCtl.u_core.mshrs[13].entry.u_core.release_ts;
    release u_i1.u_core.mshrCtl.u_core.mshrs[13].entry.u_core.acquire_period_valid_REG;
    release u_i1.u_core.mshrCtl.u_core.mshrs[13].entry.u_core.release_period_valid_REG;
    release u_i1.u_core.mshrCtl.u_core.mshrs[13].entry.u_core.REG;
    release u_i1.u_core.mshrCtl.u_core.mshrs[13].entry.u_core.REG_1;
    release u_i1.u_core.mshrCtl.u_core.mshrs[13].entry.u_core.REG_2;
    release u_i1.u_core.mshrCtl.u_core.mshrs[13].entry.u_core.REG_3;
    release u_i1.u_core.mshrCtl.u_core.mshrs[14].entry.u_core.tgtid_rcompack;
    release u_i1.u_core.mshrCtl.u_core.mshrs[14].entry.u_core.txnid_rcompack;
    release u_i1.u_core.mshrCtl.u_core.mshrs[14].entry.u_core.tgtid_wcompack;
    release u_i1.u_core.mshrCtl.u_core.mshrs[14].entry.u_core.txnid_wcompack;
    release u_i1.u_core.mshrCtl.u_core.mshrs[14].entry.u_core.srcid_retryack;
    release u_i1.u_core.mshrCtl.u_core.mshrs[14].entry.u_core.acquire_ts;
    release u_i1.u_core.mshrCtl.u_core.mshrs[14].entry.u_core.release_ts;
    release u_i1.u_core.mshrCtl.u_core.mshrs[14].entry.u_core.acquire_period_valid_REG;
    release u_i1.u_core.mshrCtl.u_core.mshrs[14].entry.u_core.release_period_valid_REG;
    release u_i1.u_core.mshrCtl.u_core.mshrs[14].entry.u_core.REG;
    release u_i1.u_core.mshrCtl.u_core.mshrs[14].entry.u_core.REG_1;
    release u_i1.u_core.mshrCtl.u_core.mshrs[14].entry.u_core.REG_2;
    release u_i1.u_core.mshrCtl.u_core.mshrs[14].entry.u_core.REG_3;
    release u_i1.u_core.mshrCtl.u_core.mshrs[15].entry.u_core.tgtid_rcompack;
    release u_i1.u_core.mshrCtl.u_core.mshrs[15].entry.u_core.txnid_rcompack;
    release u_i1.u_core.mshrCtl.u_core.mshrs[15].entry.u_core.tgtid_wcompack;
    release u_i1.u_core.mshrCtl.u_core.mshrs[15].entry.u_core.txnid_wcompack;
    release u_i1.u_core.mshrCtl.u_core.mshrs[15].entry.u_core.srcid_retryack;
    release u_i1.u_core.mshrCtl.u_core.mshrs[15].entry.u_core.acquire_ts;
    release u_i1.u_core.mshrCtl.u_core.mshrs[15].entry.u_core.release_ts;
    release u_i1.u_core.mshrCtl.u_core.mshrs[15].entry.u_core.acquire_period_valid_REG;
    release u_i1.u_core.mshrCtl.u_core.mshrs[15].entry.u_core.release_period_valid_REG;
    release u_i1.u_core.mshrCtl.u_core.mshrs[15].entry.u_core.REG;
    release u_i1.u_core.mshrCtl.u_core.mshrs[15].entry.u_core.REG_1;
    release u_i1.u_core.mshrCtl.u_core.mshrs[15].entry.u_core.REG_2;
    release u_i1.u_core.mshrCtl.u_core.mshrs[15].entry.u_core.REG_3;
    release u_i1.u_core.mshrCtl.u_core.io_perf_0_value_REG;
    release u_i1.u_core.mshrCtl.u_core.io_perf_0_value_REG_1;
    release u_i1.u_core.mshrCtl.u_core.io_perf_1_value_REG;
    release u_i1.u_core.mshrCtl.u_core.io_perf_1_value_REG_1;
    release u_i1.u_core.mshrCtl.u_core.io_perf_3_value_REG;
    release u_i1.u_core.mshrCtl.u_core.io_perf_3_value_REG_1;
    release u_i1.u_core.mshrCtl.u_core.REG;
    release u_i1.u_core.mainPipe.u_core.data_s4;
    release u_i1.u_core.mainPipe.u_core.data_s5;
    release u_i1.u_core.mainPipe.u_core.s3DropValid_d1;
    release u_i1.u_core.mainPipe.u_core.reqDrop_s3_d1;
    release u_i1.u_core.mainPipe.u_core.reqDrop_s3_d2;
    release u_i1.u_core.mainPipe.u_core.reqDrop_s4_d1;
    release u_i1.u_core.mainPipe.u_core.perf_d1[0];
    release u_i1.u_core.mainPipe.u_core.perf[0];
    release u_i1.u_core.mainPipe.u_core.perf_d1[1];
    release u_i1.u_core.mainPipe.u_core.perf[1];
    release u_i1.u_core.mainPipe.u_core.perf_d1[2];
    release u_i1.u_core.mainPipe.u_core.perf[2];
    release u_i1.u_core.mainPipe.u_core.perf_d1[3];
    release u_i1.u_core.mainPipe.u_core.perf[3];
    release u_i1.u_core.mainPipe.u_core.perf_d1[4];
    release u_i1.u_core.mainPipe.u_core.perf[4];
    release u_i1.u_core.mainPipe.u_core.perf_d1[5];
    release u_i1.u_core.mainPipe.u_core.perf[5];
    release u_i1.u_core.mainPipe.u_core.perf_d1[6];
    release u_i1.u_core.mainPipe.u_core.perf[6];
    release u_i1.u_core.mainPipe.u_core.perf_d1[7];
    release u_i1.u_core.mainPipe.u_core.perf[7];
    release u_i1.u_core.mainPipe.u_core.perf_d1[8];
    release u_i1.u_core.mainPipe.u_core.perf[8];
    release u_i1.u_core.mainPipe.u_core.perf_d1[9];
    release u_i1.u_core.mainPipe.u_core.perf[9];
    release u_i1.u_core.mainPipe.u_core.perf_d1[10];
    release u_i1.u_core.mainPipe.u_core.perf[10];
    release u_i1.u_core.mainPipe.u_core.perf_d1[11];
    release u_i1.u_core.mainPipe.u_core.perf[11];
    release u_i1.u_core.mainPipe.u_core.perf_d1[12];
    release u_i1.u_core.mainPipe.u_core.perf[12];
    release u_i1.u_core.grantBuf.u_core.validPrev[0];
    release u_i1.u_core.grantBuf.u_core.histValidPrev[0];
    release u_i1.u_core.grantBuf.u_core.validPrev[1];
    release u_i1.u_core.grantBuf.u_core.histValidPrev[1];
    release u_i1.u_core.grantBuf.u_core.validPrev[2];
    release u_i1.u_core.grantBuf.u_core.histValidPrev[2];
    release u_i1.u_core.grantBuf.u_core.validPrev[3];
    release u_i1.u_core.grantBuf.u_core.histValidPrev[3];
    release u_i1.u_core.grantBuf.u_core.validPrev[4];
    release u_i1.u_core.grantBuf.u_core.histValidPrev[4];
    release u_i1.u_core.grantBuf.u_core.validPrev[5];
    release u_i1.u_core.grantBuf.u_core.histValidPrev[5];
    release u_i1.u_core.grantBuf.u_core.validPrev[6];
    release u_i1.u_core.grantBuf.u_core.histValidPrev[6];
    release u_i1.u_core.grantBuf.u_core.validPrev[7];
    release u_i1.u_core.grantBuf.u_core.histValidPrev[7];
    release u_i1.u_core.grantBuf.u_core.validPrev[8];
    release u_i1.u_core.grantBuf.u_core.histValidPrev[8];
    release u_i1.u_core.grantBuf.u_core.validPrev[9];
    release u_i1.u_core.grantBuf.u_core.histValidPrev[9];
    release u_i1.u_core.grantBuf.u_core.validPrev[10];
    release u_i1.u_core.grantBuf.u_core.histValidPrev[10];
    release u_i1.u_core.grantBuf.u_core.validPrev[11];
    release u_i1.u_core.grantBuf.u_core.histValidPrev[11];
    release u_i1.u_core.grantBuf.u_core.validPrev[12];
    release u_i1.u_core.grantBuf.u_core.histValidPrev[12];
    release u_i1.u_core.grantBuf.u_core.validPrev[13];
    release u_i1.u_core.grantBuf.u_core.histValidPrev[13];
    release u_i1.u_core.grantBuf.u_core.validPrev[14];
    release u_i1.u_core.grantBuf.u_core.histValidPrev[14];
    release u_i1.u_core.grantBuf.u_core.validPrev[15];
    release u_i1.u_core.grantBuf.u_core.histValidPrev[15];
    release u_i1.u_core.rxsnp.u_core.replPrevForBlock[0];
    release u_i1.u_core.rxsnp.u_core.replPrevForNest[0];
    release u_i1.u_core.rxsnp.u_core.replPrevForBlock[1];
    release u_i1.u_core.rxsnp.u_core.replPrevForNest[1];
    release u_i1.u_core.rxsnp.u_core.replPrevForBlock[2];
    release u_i1.u_core.rxsnp.u_core.replPrevForNest[2];
    release u_i1.u_core.rxsnp.u_core.replPrevForBlock[3];
    release u_i1.u_core.rxsnp.u_core.replPrevForNest[3];
    release u_i1.u_core.rxsnp.u_core.replPrevForBlock[4];
    release u_i1.u_core.rxsnp.u_core.replPrevForNest[4];
    release u_i1.u_core.rxsnp.u_core.replPrevForBlock[5];
    release u_i1.u_core.rxsnp.u_core.replPrevForNest[5];
    release u_i1.u_core.rxsnp.u_core.replPrevForBlock[6];
    release u_i1.u_core.rxsnp.u_core.replPrevForNest[6];
    release u_i1.u_core.rxsnp.u_core.replPrevForBlock[7];
    release u_i1.u_core.rxsnp.u_core.replPrevForNest[7];
    release u_i1.u_core.rxsnp.u_core.replPrevForBlock[8];
    release u_i1.u_core.rxsnp.u_core.replPrevForNest[8];
    release u_i1.u_core.rxsnp.u_core.replPrevForBlock[9];
    release u_i1.u_core.rxsnp.u_core.replPrevForNest[9];
    release u_i1.u_core.rxsnp.u_core.replPrevForBlock[10];
    release u_i1.u_core.rxsnp.u_core.replPrevForNest[10];
    release u_i1.u_core.rxsnp.u_core.replPrevForBlock[11];
    release u_i1.u_core.rxsnp.u_core.replPrevForNest[11];
    release u_i1.u_core.rxsnp.u_core.replPrevForBlock[12];
    release u_i1.u_core.rxsnp.u_core.replPrevForNest[12];
    release u_i1.u_core.rxsnp.u_core.replPrevForBlock[13];
    release u_i1.u_core.rxsnp.u_core.replPrevForNest[13];
    release u_i1.u_core.rxsnp.u_core.replPrevForBlock[14];
    release u_i1.u_core.rxsnp.u_core.replPrevForNest[14];
    release u_i1.u_core.rxsnp.u_core.replPrevForBlock[15];
    release u_i1.u_core.rxsnp.u_core.replPrevForNest[15];
    release u_i1.u_core.reqBuf.chosenQ.u_core.ram;
    release u_i1.u_core.reqBuf.u_core.hitPfPrev_set;
    release u_i1.u_core.reqBuf.u_core.hitPfPrev_tag;
    release u_i1.u_core.reqBuf.u_core.mergeAPrev_set;
    release u_i1.u_core.reqBuf.u_core.mergeAPrev_tag;
    release u_i1.u_core.reqBuf.u_core.sameSetS3Valid[0];
    release u_i1.u_core.reqBuf.u_core.sameSetS3Set[0];
    release u_i1.u_core.reqBuf.u_core.sameSetS3Valid[1];
    release u_i1.u_core.reqBuf.u_core.sameSetS3Set[1];
    release u_i1.u_core.reqBuf.u_core.sameSetS3Valid[2];
    release u_i1.u_core.reqBuf.u_core.sameSetS3Set[2];
    release u_i1.u_core.reqBuf.u_core.sameSetS3Valid[3];
    release u_i1.u_core.reqBuf.u_core.sameSetS3Set[3];
    release u_i1.u_core.reqBuf.u_core.sameSetS3Valid[4];
    release u_i1.u_core.reqBuf.u_core.sameSetS3Set[4];
    release u_i1.u_core.reqBuf.u_core.sameSetS3Valid[5];
    release u_i1.u_core.reqBuf.u_core.sameSetS3Set[5];
    release u_i1.u_core.sinkC.u_core.bufRespStage[0];
    release u_i1.u_core.sinkC.u_core.bufRespStage[1];
    release u_i1.u_core.sinkC.u_core.bufRespOut[0];
    release u_i1.u_core.sinkC.u_core.bufRespOut[1];
    release u_i1.u_core.sinkC.u_core.refillIdReg;
    release u_i1.u_core.sinkC.u_core.refillBufIdxReg;
    release u_i1.u_core.sinkC.u_core.taskFirePrev;
    release u_i1.u_core.sinkC.u_core.taskBufIdxPrev;
    release u_i1.u_core.reqArb.u_core.ds_mcp2_stall;
    release u_i1.u_core.refillBuf.u_core.buffer[0][0];
    release u_i1.u_core.refillBuf.u_core.buffer[0][1];
    release u_i1.u_core.refillBuf.u_core.buffer[1][0];
    release u_i1.u_core.refillBuf.u_core.buffer[1][1];
    release u_i1.u_core.refillBuf.u_core.buffer[2][0];
    release u_i1.u_core.refillBuf.u_core.buffer[2][1];
    release u_i1.u_core.refillBuf.u_core.buffer[3][0];
    release u_i1.u_core.refillBuf.u_core.buffer[3][1];
    release u_i1.u_core.refillBuf.u_core.buffer[4][0];
    release u_i1.u_core.refillBuf.u_core.buffer[4][1];
    release u_i1.u_core.refillBuf.u_core.buffer[5][0];
    release u_i1.u_core.refillBuf.u_core.buffer[5][1];
    release u_i1.u_core.refillBuf.u_core.buffer[6][0];
    release u_i1.u_core.refillBuf.u_core.buffer[6][1];
    release u_i1.u_core.refillBuf.u_core.buffer[7][0];
    release u_i1.u_core.refillBuf.u_core.buffer[7][1];
    release u_i1.u_core.refillBuf.u_core.buffer[8][0];
    release u_i1.u_core.refillBuf.u_core.buffer[8][1];
    release u_i1.u_core.refillBuf.u_core.buffer[9][0];
    release u_i1.u_core.refillBuf.u_core.buffer[9][1];
    release u_i1.u_core.refillBuf.u_core.buffer[10][0];
    release u_i1.u_core.refillBuf.u_core.buffer[10][1];
    release u_i1.u_core.refillBuf.u_core.buffer[11][0];
    release u_i1.u_core.refillBuf.u_core.buffer[11][1];
    release u_i1.u_core.refillBuf.u_core.buffer[12][0];
    release u_i1.u_core.refillBuf.u_core.buffer[12][1];
    release u_i1.u_core.refillBuf.u_core.buffer[13][0];
    release u_i1.u_core.refillBuf.u_core.buffer[13][1];
    release u_i1.u_core.refillBuf.u_core.buffer[14][0];
    release u_i1.u_core.refillBuf.u_core.buffer[14][1];
    release u_i1.u_core.refillBuf.u_core.buffer[15][0];
    release u_i1.u_core.refillBuf.u_core.buffer[15][1];
    release u_i1.u_core.releaseBuf.u_core.buffer[0][0];
    release u_i1.u_core.releaseBuf.u_core.buffer[0][1];
    release u_i1.u_core.releaseBuf.u_core.buffer[1][0];
    release u_i1.u_core.releaseBuf.u_core.buffer[1][1];
    release u_i1.u_core.releaseBuf.u_core.buffer[2][0];
    release u_i1.u_core.releaseBuf.u_core.buffer[2][1];
    release u_i1.u_core.releaseBuf.u_core.buffer[3][0];
    release u_i1.u_core.releaseBuf.u_core.buffer[3][1];
    release u_i1.u_core.releaseBuf.u_core.buffer[4][0];
    release u_i1.u_core.releaseBuf.u_core.buffer[4][1];
    release u_i1.u_core.releaseBuf.u_core.buffer[5][0];
    release u_i1.u_core.releaseBuf.u_core.buffer[5][1];
    release u_i1.u_core.releaseBuf.u_core.buffer[6][0];
    release u_i1.u_core.releaseBuf.u_core.buffer[6][1];
    release u_i1.u_core.releaseBuf.u_core.buffer[7][0];
    release u_i1.u_core.releaseBuf.u_core.buffer[7][1];
    release u_i1.u_core.releaseBuf.u_core.buffer[8][0];
    release u_i1.u_core.releaseBuf.u_core.buffer[8][1];
    release u_i1.u_core.releaseBuf.u_core.buffer[9][0];
    release u_i1.u_core.releaseBuf.u_core.buffer[9][1];
    release u_i1.u_core.releaseBuf.u_core.buffer[10][0];
    release u_i1.u_core.releaseBuf.u_core.buffer[10][1];
    release u_i1.u_core.releaseBuf.u_core.buffer[11][0];
    release u_i1.u_core.releaseBuf.u_core.buffer[11][1];
    release u_i1.u_core.releaseBuf.u_core.buffer[12][0];
    release u_i1.u_core.releaseBuf.u_core.buffer[12][1];
    release u_i1.u_core.releaseBuf.u_core.buffer[13][0];
    release u_i1.u_core.releaseBuf.u_core.buffer[13][1];
    release u_i1.u_core.releaseBuf.u_core.buffer[14][0];
    release u_i1.u_core.releaseBuf.u_core.buffer[14][1];
    release u_i1.u_core.releaseBuf.u_core.buffer[15][0];
    release u_i1.u_core.releaseBuf.u_core.buffer[15][1];
    release u_i1.directory.tagArray.array_0_0_0.u_core.rdataReg;
    release u_i1.directory.tagArray.array_0_0_1.u_core.rdataReg;
    release u_i1.directory.tagArray.array_0_1_0.u_core.rdataReg;
    release u_i1.directory.tagArray.array_0_1_1.u_core.rdataReg;
    release u_i1.directory.metaArray.u_core.rdataReg;
    release u_i1.directory.replacer_sram_opt.u_core.rdataReg;
    release u_i1.directory.origin_bit_opt.u_core.rdataReg;
    release u_i1.dataStorage.array.array_0_0_0.u_core.rdataReg;
    release u_i1.dataStorage.array.array_0_0_1.u_core.rdataReg;
    release u_i1.dataStorage.array.array_0_0_2.u_core.rdataReg;
    release u_i1.dataStorage.array.array_0_0_3.u_core.rdataReg;
    release u_i1.dataStorage.u_core.error_REG;
    release u_i1.dataStorage.u_core.error_REG_1;
    release u_i1.mbistPl.u_core.g_node_return.pipelineDataOutReg;
    release u_i1.u_core.io_error_bits_REG_valid;
    release u_i1.u_core.io_error_bits_REG_address;
    release u_i1.u_core.io_perf_0_value_REG;
    release u_i1.u_core.io_perf_0_value_REG_1;
    release u_i1.u_core.io_perf_1_value_REG;
    release u_i1.u_core.io_perf_1_value_REG_1;
    release u_i1.u_core.io_perf_3_value_REG;
    release u_i1.u_core.io_perf_3_value_REG_1;
    release u_i1.u_core.io_perf_4_value_REG;
    release u_i1.u_core.io_perf_4_value_REG_1;
    release u_i1.u_core.io_perf_5_value_REG;
    release u_i1.u_core.io_perf_5_value_REG_1;
    release u_i1.u_core.io_perf_6_value_REG;
    release u_i1.u_core.io_perf_6_value_REG_1;
    release u_i1.u_core.io_perf_7_value_REG;
    release u_i1.u_core.io_perf_7_value_REG_1;
    release u_i1.u_core.io_perf_8_value_REG;
    release u_i1.u_core.io_perf_8_value_REG_1;
    release u_i1.u_core.io_perf_9_value_REG;
    release u_i1.u_core.io_perf_9_value_REG_1;
    release u_i1.u_core.io_perf_10_value_REG;
    release u_i1.u_core.io_perf_10_value_REG_1;
    release u_i1.u_core.io_perf_11_value_REG;
    release u_i1.u_core.io_perf_11_value_REG_1;
    release u_i1.u_core.io_perf_12_value_REG;
    release u_i1.u_core.io_perf_12_value_REG_1;
    release u_i1.u_core.io_perf_13_value_REG;
    release u_i1.u_core.io_perf_13_value_REG_1;
    release u_i1.u_core.io_perf_14_value_REG;
    release u_i1.u_core.io_perf_14_value_REG_1;
    release u_i1.u_core.io_perf_15_value_REG;
    release u_i1.u_core.io_perf_15_value_REG_1;
    release u_i1.u_core.io_perf_16_value_REG;
    release u_i1.u_core.io_perf_16_value_REG_1;
    release u_i2.u_core.mshrCtl.u_core.mshrs[0].entry.u_core.tgtid_rcompack;
    release u_i2.u_core.mshrCtl.u_core.mshrs[0].entry.u_core.txnid_rcompack;
    release u_i2.u_core.mshrCtl.u_core.mshrs[0].entry.u_core.tgtid_wcompack;
    release u_i2.u_core.mshrCtl.u_core.mshrs[0].entry.u_core.txnid_wcompack;
    release u_i2.u_core.mshrCtl.u_core.mshrs[0].entry.u_core.srcid_retryack;
    release u_i2.u_core.mshrCtl.u_core.mshrs[0].entry.u_core.acquire_ts;
    release u_i2.u_core.mshrCtl.u_core.mshrs[0].entry.u_core.release_ts;
    release u_i2.u_core.mshrCtl.u_core.mshrs[0].entry.u_core.acquire_period_valid_REG;
    release u_i2.u_core.mshrCtl.u_core.mshrs[0].entry.u_core.release_period_valid_REG;
    release u_i2.u_core.mshrCtl.u_core.mshrs[0].entry.u_core.REG;
    release u_i2.u_core.mshrCtl.u_core.mshrs[0].entry.u_core.REG_1;
    release u_i2.u_core.mshrCtl.u_core.mshrs[0].entry.u_core.REG_2;
    release u_i2.u_core.mshrCtl.u_core.mshrs[0].entry.u_core.REG_3;
    release u_i2.u_core.mshrCtl.u_core.mshrs[1].entry.u_core.tgtid_rcompack;
    release u_i2.u_core.mshrCtl.u_core.mshrs[1].entry.u_core.txnid_rcompack;
    release u_i2.u_core.mshrCtl.u_core.mshrs[1].entry.u_core.tgtid_wcompack;
    release u_i2.u_core.mshrCtl.u_core.mshrs[1].entry.u_core.txnid_wcompack;
    release u_i2.u_core.mshrCtl.u_core.mshrs[1].entry.u_core.srcid_retryack;
    release u_i2.u_core.mshrCtl.u_core.mshrs[1].entry.u_core.acquire_ts;
    release u_i2.u_core.mshrCtl.u_core.mshrs[1].entry.u_core.release_ts;
    release u_i2.u_core.mshrCtl.u_core.mshrs[1].entry.u_core.acquire_period_valid_REG;
    release u_i2.u_core.mshrCtl.u_core.mshrs[1].entry.u_core.release_period_valid_REG;
    release u_i2.u_core.mshrCtl.u_core.mshrs[1].entry.u_core.REG;
    release u_i2.u_core.mshrCtl.u_core.mshrs[1].entry.u_core.REG_1;
    release u_i2.u_core.mshrCtl.u_core.mshrs[1].entry.u_core.REG_2;
    release u_i2.u_core.mshrCtl.u_core.mshrs[1].entry.u_core.REG_3;
    release u_i2.u_core.mshrCtl.u_core.mshrs[2].entry.u_core.tgtid_rcompack;
    release u_i2.u_core.mshrCtl.u_core.mshrs[2].entry.u_core.txnid_rcompack;
    release u_i2.u_core.mshrCtl.u_core.mshrs[2].entry.u_core.tgtid_wcompack;
    release u_i2.u_core.mshrCtl.u_core.mshrs[2].entry.u_core.txnid_wcompack;
    release u_i2.u_core.mshrCtl.u_core.mshrs[2].entry.u_core.srcid_retryack;
    release u_i2.u_core.mshrCtl.u_core.mshrs[2].entry.u_core.acquire_ts;
    release u_i2.u_core.mshrCtl.u_core.mshrs[2].entry.u_core.release_ts;
    release u_i2.u_core.mshrCtl.u_core.mshrs[2].entry.u_core.acquire_period_valid_REG;
    release u_i2.u_core.mshrCtl.u_core.mshrs[2].entry.u_core.release_period_valid_REG;
    release u_i2.u_core.mshrCtl.u_core.mshrs[2].entry.u_core.REG;
    release u_i2.u_core.mshrCtl.u_core.mshrs[2].entry.u_core.REG_1;
    release u_i2.u_core.mshrCtl.u_core.mshrs[2].entry.u_core.REG_2;
    release u_i2.u_core.mshrCtl.u_core.mshrs[2].entry.u_core.REG_3;
    release u_i2.u_core.mshrCtl.u_core.mshrs[3].entry.u_core.tgtid_rcompack;
    release u_i2.u_core.mshrCtl.u_core.mshrs[3].entry.u_core.txnid_rcompack;
    release u_i2.u_core.mshrCtl.u_core.mshrs[3].entry.u_core.tgtid_wcompack;
    release u_i2.u_core.mshrCtl.u_core.mshrs[3].entry.u_core.txnid_wcompack;
    release u_i2.u_core.mshrCtl.u_core.mshrs[3].entry.u_core.srcid_retryack;
    release u_i2.u_core.mshrCtl.u_core.mshrs[3].entry.u_core.acquire_ts;
    release u_i2.u_core.mshrCtl.u_core.mshrs[3].entry.u_core.release_ts;
    release u_i2.u_core.mshrCtl.u_core.mshrs[3].entry.u_core.acquire_period_valid_REG;
    release u_i2.u_core.mshrCtl.u_core.mshrs[3].entry.u_core.release_period_valid_REG;
    release u_i2.u_core.mshrCtl.u_core.mshrs[3].entry.u_core.REG;
    release u_i2.u_core.mshrCtl.u_core.mshrs[3].entry.u_core.REG_1;
    release u_i2.u_core.mshrCtl.u_core.mshrs[3].entry.u_core.REG_2;
    release u_i2.u_core.mshrCtl.u_core.mshrs[3].entry.u_core.REG_3;
    release u_i2.u_core.mshrCtl.u_core.mshrs[4].entry.u_core.tgtid_rcompack;
    release u_i2.u_core.mshrCtl.u_core.mshrs[4].entry.u_core.txnid_rcompack;
    release u_i2.u_core.mshrCtl.u_core.mshrs[4].entry.u_core.tgtid_wcompack;
    release u_i2.u_core.mshrCtl.u_core.mshrs[4].entry.u_core.txnid_wcompack;
    release u_i2.u_core.mshrCtl.u_core.mshrs[4].entry.u_core.srcid_retryack;
    release u_i2.u_core.mshrCtl.u_core.mshrs[4].entry.u_core.acquire_ts;
    release u_i2.u_core.mshrCtl.u_core.mshrs[4].entry.u_core.release_ts;
    release u_i2.u_core.mshrCtl.u_core.mshrs[4].entry.u_core.acquire_period_valid_REG;
    release u_i2.u_core.mshrCtl.u_core.mshrs[4].entry.u_core.release_period_valid_REG;
    release u_i2.u_core.mshrCtl.u_core.mshrs[4].entry.u_core.REG;
    release u_i2.u_core.mshrCtl.u_core.mshrs[4].entry.u_core.REG_1;
    release u_i2.u_core.mshrCtl.u_core.mshrs[4].entry.u_core.REG_2;
    release u_i2.u_core.mshrCtl.u_core.mshrs[4].entry.u_core.REG_3;
    release u_i2.u_core.mshrCtl.u_core.mshrs[5].entry.u_core.tgtid_rcompack;
    release u_i2.u_core.mshrCtl.u_core.mshrs[5].entry.u_core.txnid_rcompack;
    release u_i2.u_core.mshrCtl.u_core.mshrs[5].entry.u_core.tgtid_wcompack;
    release u_i2.u_core.mshrCtl.u_core.mshrs[5].entry.u_core.txnid_wcompack;
    release u_i2.u_core.mshrCtl.u_core.mshrs[5].entry.u_core.srcid_retryack;
    release u_i2.u_core.mshrCtl.u_core.mshrs[5].entry.u_core.acquire_ts;
    release u_i2.u_core.mshrCtl.u_core.mshrs[5].entry.u_core.release_ts;
    release u_i2.u_core.mshrCtl.u_core.mshrs[5].entry.u_core.acquire_period_valid_REG;
    release u_i2.u_core.mshrCtl.u_core.mshrs[5].entry.u_core.release_period_valid_REG;
    release u_i2.u_core.mshrCtl.u_core.mshrs[5].entry.u_core.REG;
    release u_i2.u_core.mshrCtl.u_core.mshrs[5].entry.u_core.REG_1;
    release u_i2.u_core.mshrCtl.u_core.mshrs[5].entry.u_core.REG_2;
    release u_i2.u_core.mshrCtl.u_core.mshrs[5].entry.u_core.REG_3;
    release u_i2.u_core.mshrCtl.u_core.mshrs[6].entry.u_core.tgtid_rcompack;
    release u_i2.u_core.mshrCtl.u_core.mshrs[6].entry.u_core.txnid_rcompack;
    release u_i2.u_core.mshrCtl.u_core.mshrs[6].entry.u_core.tgtid_wcompack;
    release u_i2.u_core.mshrCtl.u_core.mshrs[6].entry.u_core.txnid_wcompack;
    release u_i2.u_core.mshrCtl.u_core.mshrs[6].entry.u_core.srcid_retryack;
    release u_i2.u_core.mshrCtl.u_core.mshrs[6].entry.u_core.acquire_ts;
    release u_i2.u_core.mshrCtl.u_core.mshrs[6].entry.u_core.release_ts;
    release u_i2.u_core.mshrCtl.u_core.mshrs[6].entry.u_core.acquire_period_valid_REG;
    release u_i2.u_core.mshrCtl.u_core.mshrs[6].entry.u_core.release_period_valid_REG;
    release u_i2.u_core.mshrCtl.u_core.mshrs[6].entry.u_core.REG;
    release u_i2.u_core.mshrCtl.u_core.mshrs[6].entry.u_core.REG_1;
    release u_i2.u_core.mshrCtl.u_core.mshrs[6].entry.u_core.REG_2;
    release u_i2.u_core.mshrCtl.u_core.mshrs[6].entry.u_core.REG_3;
    release u_i2.u_core.mshrCtl.u_core.mshrs[7].entry.u_core.tgtid_rcompack;
    release u_i2.u_core.mshrCtl.u_core.mshrs[7].entry.u_core.txnid_rcompack;
    release u_i2.u_core.mshrCtl.u_core.mshrs[7].entry.u_core.tgtid_wcompack;
    release u_i2.u_core.mshrCtl.u_core.mshrs[7].entry.u_core.txnid_wcompack;
    release u_i2.u_core.mshrCtl.u_core.mshrs[7].entry.u_core.srcid_retryack;
    release u_i2.u_core.mshrCtl.u_core.mshrs[7].entry.u_core.acquire_ts;
    release u_i2.u_core.mshrCtl.u_core.mshrs[7].entry.u_core.release_ts;
    release u_i2.u_core.mshrCtl.u_core.mshrs[7].entry.u_core.acquire_period_valid_REG;
    release u_i2.u_core.mshrCtl.u_core.mshrs[7].entry.u_core.release_period_valid_REG;
    release u_i2.u_core.mshrCtl.u_core.mshrs[7].entry.u_core.REG;
    release u_i2.u_core.mshrCtl.u_core.mshrs[7].entry.u_core.REG_1;
    release u_i2.u_core.mshrCtl.u_core.mshrs[7].entry.u_core.REG_2;
    release u_i2.u_core.mshrCtl.u_core.mshrs[7].entry.u_core.REG_3;
    release u_i2.u_core.mshrCtl.u_core.mshrs[8].entry.u_core.tgtid_rcompack;
    release u_i2.u_core.mshrCtl.u_core.mshrs[8].entry.u_core.txnid_rcompack;
    release u_i2.u_core.mshrCtl.u_core.mshrs[8].entry.u_core.tgtid_wcompack;
    release u_i2.u_core.mshrCtl.u_core.mshrs[8].entry.u_core.txnid_wcompack;
    release u_i2.u_core.mshrCtl.u_core.mshrs[8].entry.u_core.srcid_retryack;
    release u_i2.u_core.mshrCtl.u_core.mshrs[8].entry.u_core.acquire_ts;
    release u_i2.u_core.mshrCtl.u_core.mshrs[8].entry.u_core.release_ts;
    release u_i2.u_core.mshrCtl.u_core.mshrs[8].entry.u_core.acquire_period_valid_REG;
    release u_i2.u_core.mshrCtl.u_core.mshrs[8].entry.u_core.release_period_valid_REG;
    release u_i2.u_core.mshrCtl.u_core.mshrs[8].entry.u_core.REG;
    release u_i2.u_core.mshrCtl.u_core.mshrs[8].entry.u_core.REG_1;
    release u_i2.u_core.mshrCtl.u_core.mshrs[8].entry.u_core.REG_2;
    release u_i2.u_core.mshrCtl.u_core.mshrs[8].entry.u_core.REG_3;
    release u_i2.u_core.mshrCtl.u_core.mshrs[9].entry.u_core.tgtid_rcompack;
    release u_i2.u_core.mshrCtl.u_core.mshrs[9].entry.u_core.txnid_rcompack;
    release u_i2.u_core.mshrCtl.u_core.mshrs[9].entry.u_core.tgtid_wcompack;
    release u_i2.u_core.mshrCtl.u_core.mshrs[9].entry.u_core.txnid_wcompack;
    release u_i2.u_core.mshrCtl.u_core.mshrs[9].entry.u_core.srcid_retryack;
    release u_i2.u_core.mshrCtl.u_core.mshrs[9].entry.u_core.acquire_ts;
    release u_i2.u_core.mshrCtl.u_core.mshrs[9].entry.u_core.release_ts;
    release u_i2.u_core.mshrCtl.u_core.mshrs[9].entry.u_core.acquire_period_valid_REG;
    release u_i2.u_core.mshrCtl.u_core.mshrs[9].entry.u_core.release_period_valid_REG;
    release u_i2.u_core.mshrCtl.u_core.mshrs[9].entry.u_core.REG;
    release u_i2.u_core.mshrCtl.u_core.mshrs[9].entry.u_core.REG_1;
    release u_i2.u_core.mshrCtl.u_core.mshrs[9].entry.u_core.REG_2;
    release u_i2.u_core.mshrCtl.u_core.mshrs[9].entry.u_core.REG_3;
    release u_i2.u_core.mshrCtl.u_core.mshrs[10].entry.u_core.tgtid_rcompack;
    release u_i2.u_core.mshrCtl.u_core.mshrs[10].entry.u_core.txnid_rcompack;
    release u_i2.u_core.mshrCtl.u_core.mshrs[10].entry.u_core.tgtid_wcompack;
    release u_i2.u_core.mshrCtl.u_core.mshrs[10].entry.u_core.txnid_wcompack;
    release u_i2.u_core.mshrCtl.u_core.mshrs[10].entry.u_core.srcid_retryack;
    release u_i2.u_core.mshrCtl.u_core.mshrs[10].entry.u_core.acquire_ts;
    release u_i2.u_core.mshrCtl.u_core.mshrs[10].entry.u_core.release_ts;
    release u_i2.u_core.mshrCtl.u_core.mshrs[10].entry.u_core.acquire_period_valid_REG;
    release u_i2.u_core.mshrCtl.u_core.mshrs[10].entry.u_core.release_period_valid_REG;
    release u_i2.u_core.mshrCtl.u_core.mshrs[10].entry.u_core.REG;
    release u_i2.u_core.mshrCtl.u_core.mshrs[10].entry.u_core.REG_1;
    release u_i2.u_core.mshrCtl.u_core.mshrs[10].entry.u_core.REG_2;
    release u_i2.u_core.mshrCtl.u_core.mshrs[10].entry.u_core.REG_3;
    release u_i2.u_core.mshrCtl.u_core.mshrs[11].entry.u_core.tgtid_rcompack;
    release u_i2.u_core.mshrCtl.u_core.mshrs[11].entry.u_core.txnid_rcompack;
    release u_i2.u_core.mshrCtl.u_core.mshrs[11].entry.u_core.tgtid_wcompack;
    release u_i2.u_core.mshrCtl.u_core.mshrs[11].entry.u_core.txnid_wcompack;
    release u_i2.u_core.mshrCtl.u_core.mshrs[11].entry.u_core.srcid_retryack;
    release u_i2.u_core.mshrCtl.u_core.mshrs[11].entry.u_core.acquire_ts;
    release u_i2.u_core.mshrCtl.u_core.mshrs[11].entry.u_core.release_ts;
    release u_i2.u_core.mshrCtl.u_core.mshrs[11].entry.u_core.acquire_period_valid_REG;
    release u_i2.u_core.mshrCtl.u_core.mshrs[11].entry.u_core.release_period_valid_REG;
    release u_i2.u_core.mshrCtl.u_core.mshrs[11].entry.u_core.REG;
    release u_i2.u_core.mshrCtl.u_core.mshrs[11].entry.u_core.REG_1;
    release u_i2.u_core.mshrCtl.u_core.mshrs[11].entry.u_core.REG_2;
    release u_i2.u_core.mshrCtl.u_core.mshrs[11].entry.u_core.REG_3;
    release u_i2.u_core.mshrCtl.u_core.mshrs[12].entry.u_core.tgtid_rcompack;
    release u_i2.u_core.mshrCtl.u_core.mshrs[12].entry.u_core.txnid_rcompack;
    release u_i2.u_core.mshrCtl.u_core.mshrs[12].entry.u_core.tgtid_wcompack;
    release u_i2.u_core.mshrCtl.u_core.mshrs[12].entry.u_core.txnid_wcompack;
    release u_i2.u_core.mshrCtl.u_core.mshrs[12].entry.u_core.srcid_retryack;
    release u_i2.u_core.mshrCtl.u_core.mshrs[12].entry.u_core.acquire_ts;
    release u_i2.u_core.mshrCtl.u_core.mshrs[12].entry.u_core.release_ts;
    release u_i2.u_core.mshrCtl.u_core.mshrs[12].entry.u_core.acquire_period_valid_REG;
    release u_i2.u_core.mshrCtl.u_core.mshrs[12].entry.u_core.release_period_valid_REG;
    release u_i2.u_core.mshrCtl.u_core.mshrs[12].entry.u_core.REG;
    release u_i2.u_core.mshrCtl.u_core.mshrs[12].entry.u_core.REG_1;
    release u_i2.u_core.mshrCtl.u_core.mshrs[12].entry.u_core.REG_2;
    release u_i2.u_core.mshrCtl.u_core.mshrs[12].entry.u_core.REG_3;
    release u_i2.u_core.mshrCtl.u_core.mshrs[13].entry.u_core.tgtid_rcompack;
    release u_i2.u_core.mshrCtl.u_core.mshrs[13].entry.u_core.txnid_rcompack;
    release u_i2.u_core.mshrCtl.u_core.mshrs[13].entry.u_core.tgtid_wcompack;
    release u_i2.u_core.mshrCtl.u_core.mshrs[13].entry.u_core.txnid_wcompack;
    release u_i2.u_core.mshrCtl.u_core.mshrs[13].entry.u_core.srcid_retryack;
    release u_i2.u_core.mshrCtl.u_core.mshrs[13].entry.u_core.acquire_ts;
    release u_i2.u_core.mshrCtl.u_core.mshrs[13].entry.u_core.release_ts;
    release u_i2.u_core.mshrCtl.u_core.mshrs[13].entry.u_core.acquire_period_valid_REG;
    release u_i2.u_core.mshrCtl.u_core.mshrs[13].entry.u_core.release_period_valid_REG;
    release u_i2.u_core.mshrCtl.u_core.mshrs[13].entry.u_core.REG;
    release u_i2.u_core.mshrCtl.u_core.mshrs[13].entry.u_core.REG_1;
    release u_i2.u_core.mshrCtl.u_core.mshrs[13].entry.u_core.REG_2;
    release u_i2.u_core.mshrCtl.u_core.mshrs[13].entry.u_core.REG_3;
    release u_i2.u_core.mshrCtl.u_core.mshrs[14].entry.u_core.tgtid_rcompack;
    release u_i2.u_core.mshrCtl.u_core.mshrs[14].entry.u_core.txnid_rcompack;
    release u_i2.u_core.mshrCtl.u_core.mshrs[14].entry.u_core.tgtid_wcompack;
    release u_i2.u_core.mshrCtl.u_core.mshrs[14].entry.u_core.txnid_wcompack;
    release u_i2.u_core.mshrCtl.u_core.mshrs[14].entry.u_core.srcid_retryack;
    release u_i2.u_core.mshrCtl.u_core.mshrs[14].entry.u_core.acquire_ts;
    release u_i2.u_core.mshrCtl.u_core.mshrs[14].entry.u_core.release_ts;
    release u_i2.u_core.mshrCtl.u_core.mshrs[14].entry.u_core.acquire_period_valid_REG;
    release u_i2.u_core.mshrCtl.u_core.mshrs[14].entry.u_core.release_period_valid_REG;
    release u_i2.u_core.mshrCtl.u_core.mshrs[14].entry.u_core.REG;
    release u_i2.u_core.mshrCtl.u_core.mshrs[14].entry.u_core.REG_1;
    release u_i2.u_core.mshrCtl.u_core.mshrs[14].entry.u_core.REG_2;
    release u_i2.u_core.mshrCtl.u_core.mshrs[14].entry.u_core.REG_3;
    release u_i2.u_core.mshrCtl.u_core.mshrs[15].entry.u_core.tgtid_rcompack;
    release u_i2.u_core.mshrCtl.u_core.mshrs[15].entry.u_core.txnid_rcompack;
    release u_i2.u_core.mshrCtl.u_core.mshrs[15].entry.u_core.tgtid_wcompack;
    release u_i2.u_core.mshrCtl.u_core.mshrs[15].entry.u_core.txnid_wcompack;
    release u_i2.u_core.mshrCtl.u_core.mshrs[15].entry.u_core.srcid_retryack;
    release u_i2.u_core.mshrCtl.u_core.mshrs[15].entry.u_core.acquire_ts;
    release u_i2.u_core.mshrCtl.u_core.mshrs[15].entry.u_core.release_ts;
    release u_i2.u_core.mshrCtl.u_core.mshrs[15].entry.u_core.acquire_period_valid_REG;
    release u_i2.u_core.mshrCtl.u_core.mshrs[15].entry.u_core.release_period_valid_REG;
    release u_i2.u_core.mshrCtl.u_core.mshrs[15].entry.u_core.REG;
    release u_i2.u_core.mshrCtl.u_core.mshrs[15].entry.u_core.REG_1;
    release u_i2.u_core.mshrCtl.u_core.mshrs[15].entry.u_core.REG_2;
    release u_i2.u_core.mshrCtl.u_core.mshrs[15].entry.u_core.REG_3;
    release u_i2.u_core.mshrCtl.u_core.io_perf_0_value_REG;
    release u_i2.u_core.mshrCtl.u_core.io_perf_0_value_REG_1;
    release u_i2.u_core.mshrCtl.u_core.io_perf_1_value_REG;
    release u_i2.u_core.mshrCtl.u_core.io_perf_1_value_REG_1;
    release u_i2.u_core.mshrCtl.u_core.io_perf_3_value_REG;
    release u_i2.u_core.mshrCtl.u_core.io_perf_3_value_REG_1;
    release u_i2.u_core.mshrCtl.u_core.REG;
    release u_i2.u_core.mainPipe.u_core.data_s4;
    release u_i2.u_core.mainPipe.u_core.data_s5;
    release u_i2.u_core.mainPipe.u_core.s3DropValid_d1;
    release u_i2.u_core.mainPipe.u_core.reqDrop_s3_d1;
    release u_i2.u_core.mainPipe.u_core.reqDrop_s3_d2;
    release u_i2.u_core.mainPipe.u_core.reqDrop_s4_d1;
    release u_i2.u_core.mainPipe.u_core.perf_d1[0];
    release u_i2.u_core.mainPipe.u_core.perf[0];
    release u_i2.u_core.mainPipe.u_core.perf_d1[1];
    release u_i2.u_core.mainPipe.u_core.perf[1];
    release u_i2.u_core.mainPipe.u_core.perf_d1[2];
    release u_i2.u_core.mainPipe.u_core.perf[2];
    release u_i2.u_core.mainPipe.u_core.perf_d1[3];
    release u_i2.u_core.mainPipe.u_core.perf[3];
    release u_i2.u_core.mainPipe.u_core.perf_d1[4];
    release u_i2.u_core.mainPipe.u_core.perf[4];
    release u_i2.u_core.mainPipe.u_core.perf_d1[5];
    release u_i2.u_core.mainPipe.u_core.perf[5];
    release u_i2.u_core.mainPipe.u_core.perf_d1[6];
    release u_i2.u_core.mainPipe.u_core.perf[6];
    release u_i2.u_core.mainPipe.u_core.perf_d1[7];
    release u_i2.u_core.mainPipe.u_core.perf[7];
    release u_i2.u_core.mainPipe.u_core.perf_d1[8];
    release u_i2.u_core.mainPipe.u_core.perf[8];
    release u_i2.u_core.mainPipe.u_core.perf_d1[9];
    release u_i2.u_core.mainPipe.u_core.perf[9];
    release u_i2.u_core.mainPipe.u_core.perf_d1[10];
    release u_i2.u_core.mainPipe.u_core.perf[10];
    release u_i2.u_core.mainPipe.u_core.perf_d1[11];
    release u_i2.u_core.mainPipe.u_core.perf[11];
    release u_i2.u_core.mainPipe.u_core.perf_d1[12];
    release u_i2.u_core.mainPipe.u_core.perf[12];
    release u_i2.u_core.grantBuf.u_core.validPrev[0];
    release u_i2.u_core.grantBuf.u_core.histValidPrev[0];
    release u_i2.u_core.grantBuf.u_core.validPrev[1];
    release u_i2.u_core.grantBuf.u_core.histValidPrev[1];
    release u_i2.u_core.grantBuf.u_core.validPrev[2];
    release u_i2.u_core.grantBuf.u_core.histValidPrev[2];
    release u_i2.u_core.grantBuf.u_core.validPrev[3];
    release u_i2.u_core.grantBuf.u_core.histValidPrev[3];
    release u_i2.u_core.grantBuf.u_core.validPrev[4];
    release u_i2.u_core.grantBuf.u_core.histValidPrev[4];
    release u_i2.u_core.grantBuf.u_core.validPrev[5];
    release u_i2.u_core.grantBuf.u_core.histValidPrev[5];
    release u_i2.u_core.grantBuf.u_core.validPrev[6];
    release u_i2.u_core.grantBuf.u_core.histValidPrev[6];
    release u_i2.u_core.grantBuf.u_core.validPrev[7];
    release u_i2.u_core.grantBuf.u_core.histValidPrev[7];
    release u_i2.u_core.grantBuf.u_core.validPrev[8];
    release u_i2.u_core.grantBuf.u_core.histValidPrev[8];
    release u_i2.u_core.grantBuf.u_core.validPrev[9];
    release u_i2.u_core.grantBuf.u_core.histValidPrev[9];
    release u_i2.u_core.grantBuf.u_core.validPrev[10];
    release u_i2.u_core.grantBuf.u_core.histValidPrev[10];
    release u_i2.u_core.grantBuf.u_core.validPrev[11];
    release u_i2.u_core.grantBuf.u_core.histValidPrev[11];
    release u_i2.u_core.grantBuf.u_core.validPrev[12];
    release u_i2.u_core.grantBuf.u_core.histValidPrev[12];
    release u_i2.u_core.grantBuf.u_core.validPrev[13];
    release u_i2.u_core.grantBuf.u_core.histValidPrev[13];
    release u_i2.u_core.grantBuf.u_core.validPrev[14];
    release u_i2.u_core.grantBuf.u_core.histValidPrev[14];
    release u_i2.u_core.grantBuf.u_core.validPrev[15];
    release u_i2.u_core.grantBuf.u_core.histValidPrev[15];
    release u_i2.u_core.rxsnp.u_core.replPrevForBlock[0];
    release u_i2.u_core.rxsnp.u_core.replPrevForNest[0];
    release u_i2.u_core.rxsnp.u_core.replPrevForBlock[1];
    release u_i2.u_core.rxsnp.u_core.replPrevForNest[1];
    release u_i2.u_core.rxsnp.u_core.replPrevForBlock[2];
    release u_i2.u_core.rxsnp.u_core.replPrevForNest[2];
    release u_i2.u_core.rxsnp.u_core.replPrevForBlock[3];
    release u_i2.u_core.rxsnp.u_core.replPrevForNest[3];
    release u_i2.u_core.rxsnp.u_core.replPrevForBlock[4];
    release u_i2.u_core.rxsnp.u_core.replPrevForNest[4];
    release u_i2.u_core.rxsnp.u_core.replPrevForBlock[5];
    release u_i2.u_core.rxsnp.u_core.replPrevForNest[5];
    release u_i2.u_core.rxsnp.u_core.replPrevForBlock[6];
    release u_i2.u_core.rxsnp.u_core.replPrevForNest[6];
    release u_i2.u_core.rxsnp.u_core.replPrevForBlock[7];
    release u_i2.u_core.rxsnp.u_core.replPrevForNest[7];
    release u_i2.u_core.rxsnp.u_core.replPrevForBlock[8];
    release u_i2.u_core.rxsnp.u_core.replPrevForNest[8];
    release u_i2.u_core.rxsnp.u_core.replPrevForBlock[9];
    release u_i2.u_core.rxsnp.u_core.replPrevForNest[9];
    release u_i2.u_core.rxsnp.u_core.replPrevForBlock[10];
    release u_i2.u_core.rxsnp.u_core.replPrevForNest[10];
    release u_i2.u_core.rxsnp.u_core.replPrevForBlock[11];
    release u_i2.u_core.rxsnp.u_core.replPrevForNest[11];
    release u_i2.u_core.rxsnp.u_core.replPrevForBlock[12];
    release u_i2.u_core.rxsnp.u_core.replPrevForNest[12];
    release u_i2.u_core.rxsnp.u_core.replPrevForBlock[13];
    release u_i2.u_core.rxsnp.u_core.replPrevForNest[13];
    release u_i2.u_core.rxsnp.u_core.replPrevForBlock[14];
    release u_i2.u_core.rxsnp.u_core.replPrevForNest[14];
    release u_i2.u_core.rxsnp.u_core.replPrevForBlock[15];
    release u_i2.u_core.rxsnp.u_core.replPrevForNest[15];
    release u_i2.u_core.reqBuf.chosenQ.u_core.ram;
    release u_i2.u_core.reqBuf.u_core.hitPfPrev_set;
    release u_i2.u_core.reqBuf.u_core.hitPfPrev_tag;
    release u_i2.u_core.reqBuf.u_core.mergeAPrev_set;
    release u_i2.u_core.reqBuf.u_core.mergeAPrev_tag;
    release u_i2.u_core.reqBuf.u_core.sameSetS3Valid[0];
    release u_i2.u_core.reqBuf.u_core.sameSetS3Set[0];
    release u_i2.u_core.reqBuf.u_core.sameSetS3Valid[1];
    release u_i2.u_core.reqBuf.u_core.sameSetS3Set[1];
    release u_i2.u_core.reqBuf.u_core.sameSetS3Valid[2];
    release u_i2.u_core.reqBuf.u_core.sameSetS3Set[2];
    release u_i2.u_core.reqBuf.u_core.sameSetS3Valid[3];
    release u_i2.u_core.reqBuf.u_core.sameSetS3Set[3];
    release u_i2.u_core.reqBuf.u_core.sameSetS3Valid[4];
    release u_i2.u_core.reqBuf.u_core.sameSetS3Set[4];
    release u_i2.u_core.reqBuf.u_core.sameSetS3Valid[5];
    release u_i2.u_core.reqBuf.u_core.sameSetS3Set[5];
    release u_i2.u_core.sinkC.u_core.bufRespStage[0];
    release u_i2.u_core.sinkC.u_core.bufRespStage[1];
    release u_i2.u_core.sinkC.u_core.bufRespOut[0];
    release u_i2.u_core.sinkC.u_core.bufRespOut[1];
    release u_i2.u_core.sinkC.u_core.refillIdReg;
    release u_i2.u_core.sinkC.u_core.refillBufIdxReg;
    release u_i2.u_core.sinkC.u_core.taskFirePrev;
    release u_i2.u_core.sinkC.u_core.taskBufIdxPrev;
    release u_i2.u_core.reqArb.u_core.ds_mcp2_stall;
    release u_i2.u_core.refillBuf.u_core.buffer[0][0];
    release u_i2.u_core.refillBuf.u_core.buffer[0][1];
    release u_i2.u_core.refillBuf.u_core.buffer[1][0];
    release u_i2.u_core.refillBuf.u_core.buffer[1][1];
    release u_i2.u_core.refillBuf.u_core.buffer[2][0];
    release u_i2.u_core.refillBuf.u_core.buffer[2][1];
    release u_i2.u_core.refillBuf.u_core.buffer[3][0];
    release u_i2.u_core.refillBuf.u_core.buffer[3][1];
    release u_i2.u_core.refillBuf.u_core.buffer[4][0];
    release u_i2.u_core.refillBuf.u_core.buffer[4][1];
    release u_i2.u_core.refillBuf.u_core.buffer[5][0];
    release u_i2.u_core.refillBuf.u_core.buffer[5][1];
    release u_i2.u_core.refillBuf.u_core.buffer[6][0];
    release u_i2.u_core.refillBuf.u_core.buffer[6][1];
    release u_i2.u_core.refillBuf.u_core.buffer[7][0];
    release u_i2.u_core.refillBuf.u_core.buffer[7][1];
    release u_i2.u_core.refillBuf.u_core.buffer[8][0];
    release u_i2.u_core.refillBuf.u_core.buffer[8][1];
    release u_i2.u_core.refillBuf.u_core.buffer[9][0];
    release u_i2.u_core.refillBuf.u_core.buffer[9][1];
    release u_i2.u_core.refillBuf.u_core.buffer[10][0];
    release u_i2.u_core.refillBuf.u_core.buffer[10][1];
    release u_i2.u_core.refillBuf.u_core.buffer[11][0];
    release u_i2.u_core.refillBuf.u_core.buffer[11][1];
    release u_i2.u_core.refillBuf.u_core.buffer[12][0];
    release u_i2.u_core.refillBuf.u_core.buffer[12][1];
    release u_i2.u_core.refillBuf.u_core.buffer[13][0];
    release u_i2.u_core.refillBuf.u_core.buffer[13][1];
    release u_i2.u_core.refillBuf.u_core.buffer[14][0];
    release u_i2.u_core.refillBuf.u_core.buffer[14][1];
    release u_i2.u_core.refillBuf.u_core.buffer[15][0];
    release u_i2.u_core.refillBuf.u_core.buffer[15][1];
    release u_i2.u_core.releaseBuf.u_core.buffer[0][0];
    release u_i2.u_core.releaseBuf.u_core.buffer[0][1];
    release u_i2.u_core.releaseBuf.u_core.buffer[1][0];
    release u_i2.u_core.releaseBuf.u_core.buffer[1][1];
    release u_i2.u_core.releaseBuf.u_core.buffer[2][0];
    release u_i2.u_core.releaseBuf.u_core.buffer[2][1];
    release u_i2.u_core.releaseBuf.u_core.buffer[3][0];
    release u_i2.u_core.releaseBuf.u_core.buffer[3][1];
    release u_i2.u_core.releaseBuf.u_core.buffer[4][0];
    release u_i2.u_core.releaseBuf.u_core.buffer[4][1];
    release u_i2.u_core.releaseBuf.u_core.buffer[5][0];
    release u_i2.u_core.releaseBuf.u_core.buffer[5][1];
    release u_i2.u_core.releaseBuf.u_core.buffer[6][0];
    release u_i2.u_core.releaseBuf.u_core.buffer[6][1];
    release u_i2.u_core.releaseBuf.u_core.buffer[7][0];
    release u_i2.u_core.releaseBuf.u_core.buffer[7][1];
    release u_i2.u_core.releaseBuf.u_core.buffer[8][0];
    release u_i2.u_core.releaseBuf.u_core.buffer[8][1];
    release u_i2.u_core.releaseBuf.u_core.buffer[9][0];
    release u_i2.u_core.releaseBuf.u_core.buffer[9][1];
    release u_i2.u_core.releaseBuf.u_core.buffer[10][0];
    release u_i2.u_core.releaseBuf.u_core.buffer[10][1];
    release u_i2.u_core.releaseBuf.u_core.buffer[11][0];
    release u_i2.u_core.releaseBuf.u_core.buffer[11][1];
    release u_i2.u_core.releaseBuf.u_core.buffer[12][0];
    release u_i2.u_core.releaseBuf.u_core.buffer[12][1];
    release u_i2.u_core.releaseBuf.u_core.buffer[13][0];
    release u_i2.u_core.releaseBuf.u_core.buffer[13][1];
    release u_i2.u_core.releaseBuf.u_core.buffer[14][0];
    release u_i2.u_core.releaseBuf.u_core.buffer[14][1];
    release u_i2.u_core.releaseBuf.u_core.buffer[15][0];
    release u_i2.u_core.releaseBuf.u_core.buffer[15][1];
    release u_i2.directory.tagArray.array_0_0_0.u_core.rdataReg;
    release u_i2.directory.tagArray.array_0_0_1.u_core.rdataReg;
    release u_i2.directory.tagArray.array_0_1_0.u_core.rdataReg;
    release u_i2.directory.tagArray.array_0_1_1.u_core.rdataReg;
    release u_i2.directory.metaArray.u_core.rdataReg;
    release u_i2.directory.replacer_sram_opt.u_core.rdataReg;
    release u_i2.directory.origin_bit_opt.u_core.rdataReg;
    release u_i2.dataStorage.array.array_0_0_0.u_core.rdataReg;
    release u_i2.dataStorage.array.array_0_0_1.u_core.rdataReg;
    release u_i2.dataStorage.array.array_0_0_2.u_core.rdataReg;
    release u_i2.dataStorage.array.array_0_0_3.u_core.rdataReg;
    release u_i2.dataStorage.u_core.error_REG;
    release u_i2.dataStorage.u_core.error_REG_1;
    release u_i2.mbistPl.u_core.g_node_return.pipelineDataOutReg;
    release u_i2.u_core.io_error_bits_REG_valid;
    release u_i2.u_core.io_error_bits_REG_address;
    release u_i2.u_core.io_perf_0_value_REG;
    release u_i2.u_core.io_perf_0_value_REG_1;
    release u_i2.u_core.io_perf_1_value_REG;
    release u_i2.u_core.io_perf_1_value_REG_1;
    release u_i2.u_core.io_perf_3_value_REG;
    release u_i2.u_core.io_perf_3_value_REG_1;
    release u_i2.u_core.io_perf_4_value_REG;
    release u_i2.u_core.io_perf_4_value_REG_1;
    release u_i2.u_core.io_perf_5_value_REG;
    release u_i2.u_core.io_perf_5_value_REG_1;
    release u_i2.u_core.io_perf_6_value_REG;
    release u_i2.u_core.io_perf_6_value_REG_1;
    release u_i2.u_core.io_perf_7_value_REG;
    release u_i2.u_core.io_perf_7_value_REG_1;
    release u_i2.u_core.io_perf_8_value_REG;
    release u_i2.u_core.io_perf_8_value_REG_1;
    release u_i2.u_core.io_perf_9_value_REG;
    release u_i2.u_core.io_perf_9_value_REG_1;
    release u_i2.u_core.io_perf_10_value_REG;
    release u_i2.u_core.io_perf_10_value_REG_1;
    release u_i2.u_core.io_perf_11_value_REG;
    release u_i2.u_core.io_perf_11_value_REG_1;
    release u_i2.u_core.io_perf_12_value_REG;
    release u_i2.u_core.io_perf_12_value_REG_1;
    release u_i2.u_core.io_perf_13_value_REG;
    release u_i2.u_core.io_perf_13_value_REG_1;
    release u_i2.u_core.io_perf_14_value_REG;
    release u_i2.u_core.io_perf_14_value_REG_1;
    release u_i2.u_core.io_perf_15_value_REG;
    release u_i2.u_core.io_perf_15_value_REG_1;
    release u_i2.u_core.io_perf_16_value_REG;
    release u_i2.u_core.io_perf_16_value_REG_1;
    release u_i3.u_core.mshrCtl.u_core.mshrs[0].entry.u_core.tgtid_rcompack;
    release u_i3.u_core.mshrCtl.u_core.mshrs[0].entry.u_core.txnid_rcompack;
    release u_i3.u_core.mshrCtl.u_core.mshrs[0].entry.u_core.tgtid_wcompack;
    release u_i3.u_core.mshrCtl.u_core.mshrs[0].entry.u_core.txnid_wcompack;
    release u_i3.u_core.mshrCtl.u_core.mshrs[0].entry.u_core.srcid_retryack;
    release u_i3.u_core.mshrCtl.u_core.mshrs[0].entry.u_core.acquire_ts;
    release u_i3.u_core.mshrCtl.u_core.mshrs[0].entry.u_core.release_ts;
    release u_i3.u_core.mshrCtl.u_core.mshrs[0].entry.u_core.acquire_period_valid_REG;
    release u_i3.u_core.mshrCtl.u_core.mshrs[0].entry.u_core.release_period_valid_REG;
    release u_i3.u_core.mshrCtl.u_core.mshrs[0].entry.u_core.REG;
    release u_i3.u_core.mshrCtl.u_core.mshrs[0].entry.u_core.REG_1;
    release u_i3.u_core.mshrCtl.u_core.mshrs[0].entry.u_core.REG_2;
    release u_i3.u_core.mshrCtl.u_core.mshrs[0].entry.u_core.REG_3;
    release u_i3.u_core.mshrCtl.u_core.mshrs[1].entry.u_core.tgtid_rcompack;
    release u_i3.u_core.mshrCtl.u_core.mshrs[1].entry.u_core.txnid_rcompack;
    release u_i3.u_core.mshrCtl.u_core.mshrs[1].entry.u_core.tgtid_wcompack;
    release u_i3.u_core.mshrCtl.u_core.mshrs[1].entry.u_core.txnid_wcompack;
    release u_i3.u_core.mshrCtl.u_core.mshrs[1].entry.u_core.srcid_retryack;
    release u_i3.u_core.mshrCtl.u_core.mshrs[1].entry.u_core.acquire_ts;
    release u_i3.u_core.mshrCtl.u_core.mshrs[1].entry.u_core.release_ts;
    release u_i3.u_core.mshrCtl.u_core.mshrs[1].entry.u_core.acquire_period_valid_REG;
    release u_i3.u_core.mshrCtl.u_core.mshrs[1].entry.u_core.release_period_valid_REG;
    release u_i3.u_core.mshrCtl.u_core.mshrs[1].entry.u_core.REG;
    release u_i3.u_core.mshrCtl.u_core.mshrs[1].entry.u_core.REG_1;
    release u_i3.u_core.mshrCtl.u_core.mshrs[1].entry.u_core.REG_2;
    release u_i3.u_core.mshrCtl.u_core.mshrs[1].entry.u_core.REG_3;
    release u_i3.u_core.mshrCtl.u_core.mshrs[2].entry.u_core.tgtid_rcompack;
    release u_i3.u_core.mshrCtl.u_core.mshrs[2].entry.u_core.txnid_rcompack;
    release u_i3.u_core.mshrCtl.u_core.mshrs[2].entry.u_core.tgtid_wcompack;
    release u_i3.u_core.mshrCtl.u_core.mshrs[2].entry.u_core.txnid_wcompack;
    release u_i3.u_core.mshrCtl.u_core.mshrs[2].entry.u_core.srcid_retryack;
    release u_i3.u_core.mshrCtl.u_core.mshrs[2].entry.u_core.acquire_ts;
    release u_i3.u_core.mshrCtl.u_core.mshrs[2].entry.u_core.release_ts;
    release u_i3.u_core.mshrCtl.u_core.mshrs[2].entry.u_core.acquire_period_valid_REG;
    release u_i3.u_core.mshrCtl.u_core.mshrs[2].entry.u_core.release_period_valid_REG;
    release u_i3.u_core.mshrCtl.u_core.mshrs[2].entry.u_core.REG;
    release u_i3.u_core.mshrCtl.u_core.mshrs[2].entry.u_core.REG_1;
    release u_i3.u_core.mshrCtl.u_core.mshrs[2].entry.u_core.REG_2;
    release u_i3.u_core.mshrCtl.u_core.mshrs[2].entry.u_core.REG_3;
    release u_i3.u_core.mshrCtl.u_core.mshrs[3].entry.u_core.tgtid_rcompack;
    release u_i3.u_core.mshrCtl.u_core.mshrs[3].entry.u_core.txnid_rcompack;
    release u_i3.u_core.mshrCtl.u_core.mshrs[3].entry.u_core.tgtid_wcompack;
    release u_i3.u_core.mshrCtl.u_core.mshrs[3].entry.u_core.txnid_wcompack;
    release u_i3.u_core.mshrCtl.u_core.mshrs[3].entry.u_core.srcid_retryack;
    release u_i3.u_core.mshrCtl.u_core.mshrs[3].entry.u_core.acquire_ts;
    release u_i3.u_core.mshrCtl.u_core.mshrs[3].entry.u_core.release_ts;
    release u_i3.u_core.mshrCtl.u_core.mshrs[3].entry.u_core.acquire_period_valid_REG;
    release u_i3.u_core.mshrCtl.u_core.mshrs[3].entry.u_core.release_period_valid_REG;
    release u_i3.u_core.mshrCtl.u_core.mshrs[3].entry.u_core.REG;
    release u_i3.u_core.mshrCtl.u_core.mshrs[3].entry.u_core.REG_1;
    release u_i3.u_core.mshrCtl.u_core.mshrs[3].entry.u_core.REG_2;
    release u_i3.u_core.mshrCtl.u_core.mshrs[3].entry.u_core.REG_3;
    release u_i3.u_core.mshrCtl.u_core.mshrs[4].entry.u_core.tgtid_rcompack;
    release u_i3.u_core.mshrCtl.u_core.mshrs[4].entry.u_core.txnid_rcompack;
    release u_i3.u_core.mshrCtl.u_core.mshrs[4].entry.u_core.tgtid_wcompack;
    release u_i3.u_core.mshrCtl.u_core.mshrs[4].entry.u_core.txnid_wcompack;
    release u_i3.u_core.mshrCtl.u_core.mshrs[4].entry.u_core.srcid_retryack;
    release u_i3.u_core.mshrCtl.u_core.mshrs[4].entry.u_core.acquire_ts;
    release u_i3.u_core.mshrCtl.u_core.mshrs[4].entry.u_core.release_ts;
    release u_i3.u_core.mshrCtl.u_core.mshrs[4].entry.u_core.acquire_period_valid_REG;
    release u_i3.u_core.mshrCtl.u_core.mshrs[4].entry.u_core.release_period_valid_REG;
    release u_i3.u_core.mshrCtl.u_core.mshrs[4].entry.u_core.REG;
    release u_i3.u_core.mshrCtl.u_core.mshrs[4].entry.u_core.REG_1;
    release u_i3.u_core.mshrCtl.u_core.mshrs[4].entry.u_core.REG_2;
    release u_i3.u_core.mshrCtl.u_core.mshrs[4].entry.u_core.REG_3;
    release u_i3.u_core.mshrCtl.u_core.mshrs[5].entry.u_core.tgtid_rcompack;
    release u_i3.u_core.mshrCtl.u_core.mshrs[5].entry.u_core.txnid_rcompack;
    release u_i3.u_core.mshrCtl.u_core.mshrs[5].entry.u_core.tgtid_wcompack;
    release u_i3.u_core.mshrCtl.u_core.mshrs[5].entry.u_core.txnid_wcompack;
    release u_i3.u_core.mshrCtl.u_core.mshrs[5].entry.u_core.srcid_retryack;
    release u_i3.u_core.mshrCtl.u_core.mshrs[5].entry.u_core.acquire_ts;
    release u_i3.u_core.mshrCtl.u_core.mshrs[5].entry.u_core.release_ts;
    release u_i3.u_core.mshrCtl.u_core.mshrs[5].entry.u_core.acquire_period_valid_REG;
    release u_i3.u_core.mshrCtl.u_core.mshrs[5].entry.u_core.release_period_valid_REG;
    release u_i3.u_core.mshrCtl.u_core.mshrs[5].entry.u_core.REG;
    release u_i3.u_core.mshrCtl.u_core.mshrs[5].entry.u_core.REG_1;
    release u_i3.u_core.mshrCtl.u_core.mshrs[5].entry.u_core.REG_2;
    release u_i3.u_core.mshrCtl.u_core.mshrs[5].entry.u_core.REG_3;
    release u_i3.u_core.mshrCtl.u_core.mshrs[6].entry.u_core.tgtid_rcompack;
    release u_i3.u_core.mshrCtl.u_core.mshrs[6].entry.u_core.txnid_rcompack;
    release u_i3.u_core.mshrCtl.u_core.mshrs[6].entry.u_core.tgtid_wcompack;
    release u_i3.u_core.mshrCtl.u_core.mshrs[6].entry.u_core.txnid_wcompack;
    release u_i3.u_core.mshrCtl.u_core.mshrs[6].entry.u_core.srcid_retryack;
    release u_i3.u_core.mshrCtl.u_core.mshrs[6].entry.u_core.acquire_ts;
    release u_i3.u_core.mshrCtl.u_core.mshrs[6].entry.u_core.release_ts;
    release u_i3.u_core.mshrCtl.u_core.mshrs[6].entry.u_core.acquire_period_valid_REG;
    release u_i3.u_core.mshrCtl.u_core.mshrs[6].entry.u_core.release_period_valid_REG;
    release u_i3.u_core.mshrCtl.u_core.mshrs[6].entry.u_core.REG;
    release u_i3.u_core.mshrCtl.u_core.mshrs[6].entry.u_core.REG_1;
    release u_i3.u_core.mshrCtl.u_core.mshrs[6].entry.u_core.REG_2;
    release u_i3.u_core.mshrCtl.u_core.mshrs[6].entry.u_core.REG_3;
    release u_i3.u_core.mshrCtl.u_core.mshrs[7].entry.u_core.tgtid_rcompack;
    release u_i3.u_core.mshrCtl.u_core.mshrs[7].entry.u_core.txnid_rcompack;
    release u_i3.u_core.mshrCtl.u_core.mshrs[7].entry.u_core.tgtid_wcompack;
    release u_i3.u_core.mshrCtl.u_core.mshrs[7].entry.u_core.txnid_wcompack;
    release u_i3.u_core.mshrCtl.u_core.mshrs[7].entry.u_core.srcid_retryack;
    release u_i3.u_core.mshrCtl.u_core.mshrs[7].entry.u_core.acquire_ts;
    release u_i3.u_core.mshrCtl.u_core.mshrs[7].entry.u_core.release_ts;
    release u_i3.u_core.mshrCtl.u_core.mshrs[7].entry.u_core.acquire_period_valid_REG;
    release u_i3.u_core.mshrCtl.u_core.mshrs[7].entry.u_core.release_period_valid_REG;
    release u_i3.u_core.mshrCtl.u_core.mshrs[7].entry.u_core.REG;
    release u_i3.u_core.mshrCtl.u_core.mshrs[7].entry.u_core.REG_1;
    release u_i3.u_core.mshrCtl.u_core.mshrs[7].entry.u_core.REG_2;
    release u_i3.u_core.mshrCtl.u_core.mshrs[7].entry.u_core.REG_3;
    release u_i3.u_core.mshrCtl.u_core.mshrs[8].entry.u_core.tgtid_rcompack;
    release u_i3.u_core.mshrCtl.u_core.mshrs[8].entry.u_core.txnid_rcompack;
    release u_i3.u_core.mshrCtl.u_core.mshrs[8].entry.u_core.tgtid_wcompack;
    release u_i3.u_core.mshrCtl.u_core.mshrs[8].entry.u_core.txnid_wcompack;
    release u_i3.u_core.mshrCtl.u_core.mshrs[8].entry.u_core.srcid_retryack;
    release u_i3.u_core.mshrCtl.u_core.mshrs[8].entry.u_core.acquire_ts;
    release u_i3.u_core.mshrCtl.u_core.mshrs[8].entry.u_core.release_ts;
    release u_i3.u_core.mshrCtl.u_core.mshrs[8].entry.u_core.acquire_period_valid_REG;
    release u_i3.u_core.mshrCtl.u_core.mshrs[8].entry.u_core.release_period_valid_REG;
    release u_i3.u_core.mshrCtl.u_core.mshrs[8].entry.u_core.REG;
    release u_i3.u_core.mshrCtl.u_core.mshrs[8].entry.u_core.REG_1;
    release u_i3.u_core.mshrCtl.u_core.mshrs[8].entry.u_core.REG_2;
    release u_i3.u_core.mshrCtl.u_core.mshrs[8].entry.u_core.REG_3;
    release u_i3.u_core.mshrCtl.u_core.mshrs[9].entry.u_core.tgtid_rcompack;
    release u_i3.u_core.mshrCtl.u_core.mshrs[9].entry.u_core.txnid_rcompack;
    release u_i3.u_core.mshrCtl.u_core.mshrs[9].entry.u_core.tgtid_wcompack;
    release u_i3.u_core.mshrCtl.u_core.mshrs[9].entry.u_core.txnid_wcompack;
    release u_i3.u_core.mshrCtl.u_core.mshrs[9].entry.u_core.srcid_retryack;
    release u_i3.u_core.mshrCtl.u_core.mshrs[9].entry.u_core.acquire_ts;
    release u_i3.u_core.mshrCtl.u_core.mshrs[9].entry.u_core.release_ts;
    release u_i3.u_core.mshrCtl.u_core.mshrs[9].entry.u_core.acquire_period_valid_REG;
    release u_i3.u_core.mshrCtl.u_core.mshrs[9].entry.u_core.release_period_valid_REG;
    release u_i3.u_core.mshrCtl.u_core.mshrs[9].entry.u_core.REG;
    release u_i3.u_core.mshrCtl.u_core.mshrs[9].entry.u_core.REG_1;
    release u_i3.u_core.mshrCtl.u_core.mshrs[9].entry.u_core.REG_2;
    release u_i3.u_core.mshrCtl.u_core.mshrs[9].entry.u_core.REG_3;
    release u_i3.u_core.mshrCtl.u_core.mshrs[10].entry.u_core.tgtid_rcompack;
    release u_i3.u_core.mshrCtl.u_core.mshrs[10].entry.u_core.txnid_rcompack;
    release u_i3.u_core.mshrCtl.u_core.mshrs[10].entry.u_core.tgtid_wcompack;
    release u_i3.u_core.mshrCtl.u_core.mshrs[10].entry.u_core.txnid_wcompack;
    release u_i3.u_core.mshrCtl.u_core.mshrs[10].entry.u_core.srcid_retryack;
    release u_i3.u_core.mshrCtl.u_core.mshrs[10].entry.u_core.acquire_ts;
    release u_i3.u_core.mshrCtl.u_core.mshrs[10].entry.u_core.release_ts;
    release u_i3.u_core.mshrCtl.u_core.mshrs[10].entry.u_core.acquire_period_valid_REG;
    release u_i3.u_core.mshrCtl.u_core.mshrs[10].entry.u_core.release_period_valid_REG;
    release u_i3.u_core.mshrCtl.u_core.mshrs[10].entry.u_core.REG;
    release u_i3.u_core.mshrCtl.u_core.mshrs[10].entry.u_core.REG_1;
    release u_i3.u_core.mshrCtl.u_core.mshrs[10].entry.u_core.REG_2;
    release u_i3.u_core.mshrCtl.u_core.mshrs[10].entry.u_core.REG_3;
    release u_i3.u_core.mshrCtl.u_core.mshrs[11].entry.u_core.tgtid_rcompack;
    release u_i3.u_core.mshrCtl.u_core.mshrs[11].entry.u_core.txnid_rcompack;
    release u_i3.u_core.mshrCtl.u_core.mshrs[11].entry.u_core.tgtid_wcompack;
    release u_i3.u_core.mshrCtl.u_core.mshrs[11].entry.u_core.txnid_wcompack;
    release u_i3.u_core.mshrCtl.u_core.mshrs[11].entry.u_core.srcid_retryack;
    release u_i3.u_core.mshrCtl.u_core.mshrs[11].entry.u_core.acquire_ts;
    release u_i3.u_core.mshrCtl.u_core.mshrs[11].entry.u_core.release_ts;
    release u_i3.u_core.mshrCtl.u_core.mshrs[11].entry.u_core.acquire_period_valid_REG;
    release u_i3.u_core.mshrCtl.u_core.mshrs[11].entry.u_core.release_period_valid_REG;
    release u_i3.u_core.mshrCtl.u_core.mshrs[11].entry.u_core.REG;
    release u_i3.u_core.mshrCtl.u_core.mshrs[11].entry.u_core.REG_1;
    release u_i3.u_core.mshrCtl.u_core.mshrs[11].entry.u_core.REG_2;
    release u_i3.u_core.mshrCtl.u_core.mshrs[11].entry.u_core.REG_3;
    release u_i3.u_core.mshrCtl.u_core.mshrs[12].entry.u_core.tgtid_rcompack;
    release u_i3.u_core.mshrCtl.u_core.mshrs[12].entry.u_core.txnid_rcompack;
    release u_i3.u_core.mshrCtl.u_core.mshrs[12].entry.u_core.tgtid_wcompack;
    release u_i3.u_core.mshrCtl.u_core.mshrs[12].entry.u_core.txnid_wcompack;
    release u_i3.u_core.mshrCtl.u_core.mshrs[12].entry.u_core.srcid_retryack;
    release u_i3.u_core.mshrCtl.u_core.mshrs[12].entry.u_core.acquire_ts;
    release u_i3.u_core.mshrCtl.u_core.mshrs[12].entry.u_core.release_ts;
    release u_i3.u_core.mshrCtl.u_core.mshrs[12].entry.u_core.acquire_period_valid_REG;
    release u_i3.u_core.mshrCtl.u_core.mshrs[12].entry.u_core.release_period_valid_REG;
    release u_i3.u_core.mshrCtl.u_core.mshrs[12].entry.u_core.REG;
    release u_i3.u_core.mshrCtl.u_core.mshrs[12].entry.u_core.REG_1;
    release u_i3.u_core.mshrCtl.u_core.mshrs[12].entry.u_core.REG_2;
    release u_i3.u_core.mshrCtl.u_core.mshrs[12].entry.u_core.REG_3;
    release u_i3.u_core.mshrCtl.u_core.mshrs[13].entry.u_core.tgtid_rcompack;
    release u_i3.u_core.mshrCtl.u_core.mshrs[13].entry.u_core.txnid_rcompack;
    release u_i3.u_core.mshrCtl.u_core.mshrs[13].entry.u_core.tgtid_wcompack;
    release u_i3.u_core.mshrCtl.u_core.mshrs[13].entry.u_core.txnid_wcompack;
    release u_i3.u_core.mshrCtl.u_core.mshrs[13].entry.u_core.srcid_retryack;
    release u_i3.u_core.mshrCtl.u_core.mshrs[13].entry.u_core.acquire_ts;
    release u_i3.u_core.mshrCtl.u_core.mshrs[13].entry.u_core.release_ts;
    release u_i3.u_core.mshrCtl.u_core.mshrs[13].entry.u_core.acquire_period_valid_REG;
    release u_i3.u_core.mshrCtl.u_core.mshrs[13].entry.u_core.release_period_valid_REG;
    release u_i3.u_core.mshrCtl.u_core.mshrs[13].entry.u_core.REG;
    release u_i3.u_core.mshrCtl.u_core.mshrs[13].entry.u_core.REG_1;
    release u_i3.u_core.mshrCtl.u_core.mshrs[13].entry.u_core.REG_2;
    release u_i3.u_core.mshrCtl.u_core.mshrs[13].entry.u_core.REG_3;
    release u_i3.u_core.mshrCtl.u_core.mshrs[14].entry.u_core.tgtid_rcompack;
    release u_i3.u_core.mshrCtl.u_core.mshrs[14].entry.u_core.txnid_rcompack;
    release u_i3.u_core.mshrCtl.u_core.mshrs[14].entry.u_core.tgtid_wcompack;
    release u_i3.u_core.mshrCtl.u_core.mshrs[14].entry.u_core.txnid_wcompack;
    release u_i3.u_core.mshrCtl.u_core.mshrs[14].entry.u_core.srcid_retryack;
    release u_i3.u_core.mshrCtl.u_core.mshrs[14].entry.u_core.acquire_ts;
    release u_i3.u_core.mshrCtl.u_core.mshrs[14].entry.u_core.release_ts;
    release u_i3.u_core.mshrCtl.u_core.mshrs[14].entry.u_core.acquire_period_valid_REG;
    release u_i3.u_core.mshrCtl.u_core.mshrs[14].entry.u_core.release_period_valid_REG;
    release u_i3.u_core.mshrCtl.u_core.mshrs[14].entry.u_core.REG;
    release u_i3.u_core.mshrCtl.u_core.mshrs[14].entry.u_core.REG_1;
    release u_i3.u_core.mshrCtl.u_core.mshrs[14].entry.u_core.REG_2;
    release u_i3.u_core.mshrCtl.u_core.mshrs[14].entry.u_core.REG_3;
    release u_i3.u_core.mshrCtl.u_core.mshrs[15].entry.u_core.tgtid_rcompack;
    release u_i3.u_core.mshrCtl.u_core.mshrs[15].entry.u_core.txnid_rcompack;
    release u_i3.u_core.mshrCtl.u_core.mshrs[15].entry.u_core.tgtid_wcompack;
    release u_i3.u_core.mshrCtl.u_core.mshrs[15].entry.u_core.txnid_wcompack;
    release u_i3.u_core.mshrCtl.u_core.mshrs[15].entry.u_core.srcid_retryack;
    release u_i3.u_core.mshrCtl.u_core.mshrs[15].entry.u_core.acquire_ts;
    release u_i3.u_core.mshrCtl.u_core.mshrs[15].entry.u_core.release_ts;
    release u_i3.u_core.mshrCtl.u_core.mshrs[15].entry.u_core.acquire_period_valid_REG;
    release u_i3.u_core.mshrCtl.u_core.mshrs[15].entry.u_core.release_period_valid_REG;
    release u_i3.u_core.mshrCtl.u_core.mshrs[15].entry.u_core.REG;
    release u_i3.u_core.mshrCtl.u_core.mshrs[15].entry.u_core.REG_1;
    release u_i3.u_core.mshrCtl.u_core.mshrs[15].entry.u_core.REG_2;
    release u_i3.u_core.mshrCtl.u_core.mshrs[15].entry.u_core.REG_3;
    release u_i3.u_core.mshrCtl.u_core.io_perf_0_value_REG;
    release u_i3.u_core.mshrCtl.u_core.io_perf_0_value_REG_1;
    release u_i3.u_core.mshrCtl.u_core.io_perf_1_value_REG;
    release u_i3.u_core.mshrCtl.u_core.io_perf_1_value_REG_1;
    release u_i3.u_core.mshrCtl.u_core.io_perf_3_value_REG;
    release u_i3.u_core.mshrCtl.u_core.io_perf_3_value_REG_1;
    release u_i3.u_core.mshrCtl.u_core.REG;
    release u_i3.u_core.mainPipe.u_core.data_s4;
    release u_i3.u_core.mainPipe.u_core.data_s5;
    release u_i3.u_core.mainPipe.u_core.s3DropValid_d1;
    release u_i3.u_core.mainPipe.u_core.reqDrop_s3_d1;
    release u_i3.u_core.mainPipe.u_core.reqDrop_s3_d2;
    release u_i3.u_core.mainPipe.u_core.reqDrop_s4_d1;
    release u_i3.u_core.mainPipe.u_core.perf_d1[0];
    release u_i3.u_core.mainPipe.u_core.perf[0];
    release u_i3.u_core.mainPipe.u_core.perf_d1[1];
    release u_i3.u_core.mainPipe.u_core.perf[1];
    release u_i3.u_core.mainPipe.u_core.perf_d1[2];
    release u_i3.u_core.mainPipe.u_core.perf[2];
    release u_i3.u_core.mainPipe.u_core.perf_d1[3];
    release u_i3.u_core.mainPipe.u_core.perf[3];
    release u_i3.u_core.mainPipe.u_core.perf_d1[4];
    release u_i3.u_core.mainPipe.u_core.perf[4];
    release u_i3.u_core.mainPipe.u_core.perf_d1[5];
    release u_i3.u_core.mainPipe.u_core.perf[5];
    release u_i3.u_core.mainPipe.u_core.perf_d1[6];
    release u_i3.u_core.mainPipe.u_core.perf[6];
    release u_i3.u_core.mainPipe.u_core.perf_d1[7];
    release u_i3.u_core.mainPipe.u_core.perf[7];
    release u_i3.u_core.mainPipe.u_core.perf_d1[8];
    release u_i3.u_core.mainPipe.u_core.perf[8];
    release u_i3.u_core.mainPipe.u_core.perf_d1[9];
    release u_i3.u_core.mainPipe.u_core.perf[9];
    release u_i3.u_core.mainPipe.u_core.perf_d1[10];
    release u_i3.u_core.mainPipe.u_core.perf[10];
    release u_i3.u_core.mainPipe.u_core.perf_d1[11];
    release u_i3.u_core.mainPipe.u_core.perf[11];
    release u_i3.u_core.mainPipe.u_core.perf_d1[12];
    release u_i3.u_core.mainPipe.u_core.perf[12];
    release u_i3.u_core.grantBuf.u_core.validPrev[0];
    release u_i3.u_core.grantBuf.u_core.histValidPrev[0];
    release u_i3.u_core.grantBuf.u_core.validPrev[1];
    release u_i3.u_core.grantBuf.u_core.histValidPrev[1];
    release u_i3.u_core.grantBuf.u_core.validPrev[2];
    release u_i3.u_core.grantBuf.u_core.histValidPrev[2];
    release u_i3.u_core.grantBuf.u_core.validPrev[3];
    release u_i3.u_core.grantBuf.u_core.histValidPrev[3];
    release u_i3.u_core.grantBuf.u_core.validPrev[4];
    release u_i3.u_core.grantBuf.u_core.histValidPrev[4];
    release u_i3.u_core.grantBuf.u_core.validPrev[5];
    release u_i3.u_core.grantBuf.u_core.histValidPrev[5];
    release u_i3.u_core.grantBuf.u_core.validPrev[6];
    release u_i3.u_core.grantBuf.u_core.histValidPrev[6];
    release u_i3.u_core.grantBuf.u_core.validPrev[7];
    release u_i3.u_core.grantBuf.u_core.histValidPrev[7];
    release u_i3.u_core.grantBuf.u_core.validPrev[8];
    release u_i3.u_core.grantBuf.u_core.histValidPrev[8];
    release u_i3.u_core.grantBuf.u_core.validPrev[9];
    release u_i3.u_core.grantBuf.u_core.histValidPrev[9];
    release u_i3.u_core.grantBuf.u_core.validPrev[10];
    release u_i3.u_core.grantBuf.u_core.histValidPrev[10];
    release u_i3.u_core.grantBuf.u_core.validPrev[11];
    release u_i3.u_core.grantBuf.u_core.histValidPrev[11];
    release u_i3.u_core.grantBuf.u_core.validPrev[12];
    release u_i3.u_core.grantBuf.u_core.histValidPrev[12];
    release u_i3.u_core.grantBuf.u_core.validPrev[13];
    release u_i3.u_core.grantBuf.u_core.histValidPrev[13];
    release u_i3.u_core.grantBuf.u_core.validPrev[14];
    release u_i3.u_core.grantBuf.u_core.histValidPrev[14];
    release u_i3.u_core.grantBuf.u_core.validPrev[15];
    release u_i3.u_core.grantBuf.u_core.histValidPrev[15];
    release u_i3.u_core.rxsnp.u_core.replPrevForBlock[0];
    release u_i3.u_core.rxsnp.u_core.replPrevForNest[0];
    release u_i3.u_core.rxsnp.u_core.replPrevForBlock[1];
    release u_i3.u_core.rxsnp.u_core.replPrevForNest[1];
    release u_i3.u_core.rxsnp.u_core.replPrevForBlock[2];
    release u_i3.u_core.rxsnp.u_core.replPrevForNest[2];
    release u_i3.u_core.rxsnp.u_core.replPrevForBlock[3];
    release u_i3.u_core.rxsnp.u_core.replPrevForNest[3];
    release u_i3.u_core.rxsnp.u_core.replPrevForBlock[4];
    release u_i3.u_core.rxsnp.u_core.replPrevForNest[4];
    release u_i3.u_core.rxsnp.u_core.replPrevForBlock[5];
    release u_i3.u_core.rxsnp.u_core.replPrevForNest[5];
    release u_i3.u_core.rxsnp.u_core.replPrevForBlock[6];
    release u_i3.u_core.rxsnp.u_core.replPrevForNest[6];
    release u_i3.u_core.rxsnp.u_core.replPrevForBlock[7];
    release u_i3.u_core.rxsnp.u_core.replPrevForNest[7];
    release u_i3.u_core.rxsnp.u_core.replPrevForBlock[8];
    release u_i3.u_core.rxsnp.u_core.replPrevForNest[8];
    release u_i3.u_core.rxsnp.u_core.replPrevForBlock[9];
    release u_i3.u_core.rxsnp.u_core.replPrevForNest[9];
    release u_i3.u_core.rxsnp.u_core.replPrevForBlock[10];
    release u_i3.u_core.rxsnp.u_core.replPrevForNest[10];
    release u_i3.u_core.rxsnp.u_core.replPrevForBlock[11];
    release u_i3.u_core.rxsnp.u_core.replPrevForNest[11];
    release u_i3.u_core.rxsnp.u_core.replPrevForBlock[12];
    release u_i3.u_core.rxsnp.u_core.replPrevForNest[12];
    release u_i3.u_core.rxsnp.u_core.replPrevForBlock[13];
    release u_i3.u_core.rxsnp.u_core.replPrevForNest[13];
    release u_i3.u_core.rxsnp.u_core.replPrevForBlock[14];
    release u_i3.u_core.rxsnp.u_core.replPrevForNest[14];
    release u_i3.u_core.rxsnp.u_core.replPrevForBlock[15];
    release u_i3.u_core.rxsnp.u_core.replPrevForNest[15];
    release u_i3.u_core.reqBuf.chosenQ.u_core.ram;
    release u_i3.u_core.reqBuf.u_core.hitPfPrev_set;
    release u_i3.u_core.reqBuf.u_core.hitPfPrev_tag;
    release u_i3.u_core.reqBuf.u_core.mergeAPrev_set;
    release u_i3.u_core.reqBuf.u_core.mergeAPrev_tag;
    release u_i3.u_core.reqBuf.u_core.sameSetS3Valid[0];
    release u_i3.u_core.reqBuf.u_core.sameSetS3Set[0];
    release u_i3.u_core.reqBuf.u_core.sameSetS3Valid[1];
    release u_i3.u_core.reqBuf.u_core.sameSetS3Set[1];
    release u_i3.u_core.reqBuf.u_core.sameSetS3Valid[2];
    release u_i3.u_core.reqBuf.u_core.sameSetS3Set[2];
    release u_i3.u_core.reqBuf.u_core.sameSetS3Valid[3];
    release u_i3.u_core.reqBuf.u_core.sameSetS3Set[3];
    release u_i3.u_core.reqBuf.u_core.sameSetS3Valid[4];
    release u_i3.u_core.reqBuf.u_core.sameSetS3Set[4];
    release u_i3.u_core.reqBuf.u_core.sameSetS3Valid[5];
    release u_i3.u_core.reqBuf.u_core.sameSetS3Set[5];
    release u_i3.u_core.sinkC.u_core.bufRespStage[0];
    release u_i3.u_core.sinkC.u_core.bufRespStage[1];
    release u_i3.u_core.sinkC.u_core.bufRespOut[0];
    release u_i3.u_core.sinkC.u_core.bufRespOut[1];
    release u_i3.u_core.sinkC.u_core.refillIdReg;
    release u_i3.u_core.sinkC.u_core.refillBufIdxReg;
    release u_i3.u_core.sinkC.u_core.taskFirePrev;
    release u_i3.u_core.sinkC.u_core.taskBufIdxPrev;
    release u_i3.u_core.reqArb.u_core.ds_mcp2_stall;
    release u_i3.u_core.refillBuf.u_core.buffer[0][0];
    release u_i3.u_core.refillBuf.u_core.buffer[0][1];
    release u_i3.u_core.refillBuf.u_core.buffer[1][0];
    release u_i3.u_core.refillBuf.u_core.buffer[1][1];
    release u_i3.u_core.refillBuf.u_core.buffer[2][0];
    release u_i3.u_core.refillBuf.u_core.buffer[2][1];
    release u_i3.u_core.refillBuf.u_core.buffer[3][0];
    release u_i3.u_core.refillBuf.u_core.buffer[3][1];
    release u_i3.u_core.refillBuf.u_core.buffer[4][0];
    release u_i3.u_core.refillBuf.u_core.buffer[4][1];
    release u_i3.u_core.refillBuf.u_core.buffer[5][0];
    release u_i3.u_core.refillBuf.u_core.buffer[5][1];
    release u_i3.u_core.refillBuf.u_core.buffer[6][0];
    release u_i3.u_core.refillBuf.u_core.buffer[6][1];
    release u_i3.u_core.refillBuf.u_core.buffer[7][0];
    release u_i3.u_core.refillBuf.u_core.buffer[7][1];
    release u_i3.u_core.refillBuf.u_core.buffer[8][0];
    release u_i3.u_core.refillBuf.u_core.buffer[8][1];
    release u_i3.u_core.refillBuf.u_core.buffer[9][0];
    release u_i3.u_core.refillBuf.u_core.buffer[9][1];
    release u_i3.u_core.refillBuf.u_core.buffer[10][0];
    release u_i3.u_core.refillBuf.u_core.buffer[10][1];
    release u_i3.u_core.refillBuf.u_core.buffer[11][0];
    release u_i3.u_core.refillBuf.u_core.buffer[11][1];
    release u_i3.u_core.refillBuf.u_core.buffer[12][0];
    release u_i3.u_core.refillBuf.u_core.buffer[12][1];
    release u_i3.u_core.refillBuf.u_core.buffer[13][0];
    release u_i3.u_core.refillBuf.u_core.buffer[13][1];
    release u_i3.u_core.refillBuf.u_core.buffer[14][0];
    release u_i3.u_core.refillBuf.u_core.buffer[14][1];
    release u_i3.u_core.refillBuf.u_core.buffer[15][0];
    release u_i3.u_core.refillBuf.u_core.buffer[15][1];
    release u_i3.u_core.releaseBuf.u_core.buffer[0][0];
    release u_i3.u_core.releaseBuf.u_core.buffer[0][1];
    release u_i3.u_core.releaseBuf.u_core.buffer[1][0];
    release u_i3.u_core.releaseBuf.u_core.buffer[1][1];
    release u_i3.u_core.releaseBuf.u_core.buffer[2][0];
    release u_i3.u_core.releaseBuf.u_core.buffer[2][1];
    release u_i3.u_core.releaseBuf.u_core.buffer[3][0];
    release u_i3.u_core.releaseBuf.u_core.buffer[3][1];
    release u_i3.u_core.releaseBuf.u_core.buffer[4][0];
    release u_i3.u_core.releaseBuf.u_core.buffer[4][1];
    release u_i3.u_core.releaseBuf.u_core.buffer[5][0];
    release u_i3.u_core.releaseBuf.u_core.buffer[5][1];
    release u_i3.u_core.releaseBuf.u_core.buffer[6][0];
    release u_i3.u_core.releaseBuf.u_core.buffer[6][1];
    release u_i3.u_core.releaseBuf.u_core.buffer[7][0];
    release u_i3.u_core.releaseBuf.u_core.buffer[7][1];
    release u_i3.u_core.releaseBuf.u_core.buffer[8][0];
    release u_i3.u_core.releaseBuf.u_core.buffer[8][1];
    release u_i3.u_core.releaseBuf.u_core.buffer[9][0];
    release u_i3.u_core.releaseBuf.u_core.buffer[9][1];
    release u_i3.u_core.releaseBuf.u_core.buffer[10][0];
    release u_i3.u_core.releaseBuf.u_core.buffer[10][1];
    release u_i3.u_core.releaseBuf.u_core.buffer[11][0];
    release u_i3.u_core.releaseBuf.u_core.buffer[11][1];
    release u_i3.u_core.releaseBuf.u_core.buffer[12][0];
    release u_i3.u_core.releaseBuf.u_core.buffer[12][1];
    release u_i3.u_core.releaseBuf.u_core.buffer[13][0];
    release u_i3.u_core.releaseBuf.u_core.buffer[13][1];
    release u_i3.u_core.releaseBuf.u_core.buffer[14][0];
    release u_i3.u_core.releaseBuf.u_core.buffer[14][1];
    release u_i3.u_core.releaseBuf.u_core.buffer[15][0];
    release u_i3.u_core.releaseBuf.u_core.buffer[15][1];
    release u_i3.directory.tagArray.array_0_0_0.u_core.rdataReg;
    release u_i3.directory.tagArray.array_0_0_1.u_core.rdataReg;
    release u_i3.directory.tagArray.array_0_1_0.u_core.rdataReg;
    release u_i3.directory.tagArray.array_0_1_1.u_core.rdataReg;
    release u_i3.directory.metaArray.u_core.rdataReg;
    release u_i3.directory.replacer_sram_opt.u_core.rdataReg;
    release u_i3.directory.origin_bit_opt.u_core.rdataReg;
    release u_i3.dataStorage.array.array_0_0_0.u_core.rdataReg;
    release u_i3.dataStorage.array.array_0_0_1.u_core.rdataReg;
    release u_i3.dataStorage.array.array_0_0_2.u_core.rdataReg;
    release u_i3.dataStorage.array.array_0_0_3.u_core.rdataReg;
    release u_i3.dataStorage.u_core.error_REG;
    release u_i3.dataStorage.u_core.error_REG_1;
    release u_i3.mbistPl.u_core.g_node_return.pipelineDataOutReg;
    release u_i3.u_core.io_error_bits_REG_valid;
    release u_i3.u_core.io_error_bits_REG_address;
    release u_i3.u_core.io_perf_0_value_REG;
    release u_i3.u_core.io_perf_0_value_REG_1;
    release u_i3.u_core.io_perf_1_value_REG;
    release u_i3.u_core.io_perf_1_value_REG_1;
    release u_i3.u_core.io_perf_3_value_REG;
    release u_i3.u_core.io_perf_3_value_REG_1;
    release u_i3.u_core.io_perf_4_value_REG;
    release u_i3.u_core.io_perf_4_value_REG_1;
    release u_i3.u_core.io_perf_5_value_REG;
    release u_i3.u_core.io_perf_5_value_REG_1;
    release u_i3.u_core.io_perf_6_value_REG;
    release u_i3.u_core.io_perf_6_value_REG_1;
    release u_i3.u_core.io_perf_7_value_REG;
    release u_i3.u_core.io_perf_7_value_REG_1;
    release u_i3.u_core.io_perf_8_value_REG;
    release u_i3.u_core.io_perf_8_value_REG_1;
    release u_i3.u_core.io_perf_9_value_REG;
    release u_i3.u_core.io_perf_9_value_REG_1;
    release u_i3.u_core.io_perf_10_value_REG;
    release u_i3.u_core.io_perf_10_value_REG_1;
    release u_i3.u_core.io_perf_11_value_REG;
    release u_i3.u_core.io_perf_11_value_REG_1;
    release u_i3.u_core.io_perf_12_value_REG;
    release u_i3.u_core.io_perf_12_value_REG_1;
    release u_i3.u_core.io_perf_13_value_REG;
    release u_i3.u_core.io_perf_13_value_REG_1;
    release u_i3.u_core.io_perf_14_value_REG;
    release u_i3.u_core.io_perf_14_value_REG_1;
    release u_i3.u_core.io_perf_15_value_REG;
    release u_i3.u_core.io_perf_15_value_REG_1;
    release u_i3.u_core.io_perf_16_value_REG;
    release u_i3.u_core.io_perf_16_value_REG_1;
  endtask

  initial begin
    if (!$value$plusargs("ncycles=%d", NCYCLES)) NCYCLES = 200000;
    foreach (cov[k]) cov[k] = 0;
    drive(); reset = 1'b1;
    #1;
    sync_init();          // 未复位寄存器两侧同初值（见文件头）
    repeat (8) @(posedge clock);
    #1; drive(); reset = 1'b0;
    repeat (NCYCLES) begin
      @(posedge clock); #1; cyc++;
      check(); sample(); drive();
    end
    begin
      int zero = 0;
      foreach (cov[k]) begin
        $display("COVER %-24s %0d", COV_NAME[k], cov[k]);
        if (cov[k] == 0) zero++;
      end
      $display("checks=%0d errors=%0d cover_zero=%0d", checks, errors, zero);
      if (errors == 0 && zero == 0) $display("TEST PASSED");
      else $display("TEST FAILED");
    end
    $finish;
  end
endmodule
