// 自动生成: RXSNP 双例化逐拍比对 golden RXSNP vs 可读 RXSNP_xs。
`timescale 1ns/1ps
`define CHK(SIG) begin \
  if (!$isunknown(g_``SIG)) begin \
    checks++; \
    if (g_``SIG !== i_``SIG) begin \
      errors++; \
      if (errors <= 30) $display("[%0t] MISMATCH %s g=%0h i=%0h", $time, `"SIG`", g_``SIG, i_``SIG); \
    end \
  end \
end
module tb;
  int unsigned NCYCLES = 200000;
  bit clock = 0; bit reset; int errors = 0; int checks = 0;
  always #5 clock = ~clock;
  logic io_rxsnp_valid;
  logic [3:0] io_rxsnp_bits_qos;
  logic [10:0] io_rxsnp_bits_srcID;
  logic [11:0] io_rxsnp_bits_txnID;
  logic [10:0] io_rxsnp_bits_fwdNID;
  logic [11:0] io_rxsnp_bits_fwdTxnID;
  logic [4:0] io_rxsnp_bits_opcode;
  logic [44:0] io_rxsnp_bits_addr;
  logic io_rxsnp_bits_ns;
  logic io_rxsnp_bits_doNotGoToSD;
  logic io_rxsnp_bits_retToSrc;
  logic io_rxsnp_bits_traceTag;
  logic io_rxsnp_bits_mpam_perfMonGroup;
  logic [8:0] io_rxsnp_bits_mpam_partID;
  logic io_rxsnp_bits_mpam_mpamNS;
  logic io_task_ready;
  logic io_msInfo_0_valid;
  logic [8:0] io_msInfo_0_bits_set;
  logic [30:0] io_msInfo_0_bits_reqTag;
  logic io_msInfo_0_bits_willFree;
  logic io_msInfo_0_bits_aliasTask;
  logic io_msInfo_0_bits_blockRefill;
  logic io_msInfo_0_bits_meta_dirty;
  logic [1:0] io_msInfo_0_bits_meta_state;
  logic io_msInfo_0_bits_meta_clients;
  logic [1:0] io_msInfo_0_bits_meta_alias;
  logic io_msInfo_0_bits_meta_prefetch;
  logic [2:0] io_msInfo_0_bits_meta_prefetchSrc;
  logic io_msInfo_0_bits_meta_accessed;
  logic io_msInfo_0_bits_meta_tagErr;
  logic io_msInfo_0_bits_meta_dataErr;
  logic [30:0] io_msInfo_0_bits_metaTag;
  logic io_msInfo_0_bits_dirHit;
  logic io_msInfo_0_bits_w_grantfirst;
  logic io_msInfo_0_bits_s_release;
  logic io_msInfo_0_bits_s_cmoresp;
  logic io_msInfo_0_bits_s_cmometaw;
  logic io_msInfo_0_bits_w_releaseack;
  logic io_msInfo_0_bits_w_replResp;
  logic io_msInfo_0_bits_w_rprobeacklast;
  logic io_msInfo_0_bits_replaceData;
  logic io_msInfo_0_bits_releaseToClean;
  logic io_msInfo_1_valid;
  logic [8:0] io_msInfo_1_bits_set;
  logic [30:0] io_msInfo_1_bits_reqTag;
  logic io_msInfo_1_bits_willFree;
  logic io_msInfo_1_bits_aliasTask;
  logic io_msInfo_1_bits_blockRefill;
  logic io_msInfo_1_bits_meta_dirty;
  logic [1:0] io_msInfo_1_bits_meta_state;
  logic io_msInfo_1_bits_meta_clients;
  logic [1:0] io_msInfo_1_bits_meta_alias;
  logic io_msInfo_1_bits_meta_prefetch;
  logic [2:0] io_msInfo_1_bits_meta_prefetchSrc;
  logic io_msInfo_1_bits_meta_accessed;
  logic io_msInfo_1_bits_meta_tagErr;
  logic io_msInfo_1_bits_meta_dataErr;
  logic [30:0] io_msInfo_1_bits_metaTag;
  logic io_msInfo_1_bits_dirHit;
  logic io_msInfo_1_bits_w_grantfirst;
  logic io_msInfo_1_bits_s_release;
  logic io_msInfo_1_bits_s_cmoresp;
  logic io_msInfo_1_bits_s_cmometaw;
  logic io_msInfo_1_bits_w_releaseack;
  logic io_msInfo_1_bits_w_replResp;
  logic io_msInfo_1_bits_w_rprobeacklast;
  logic io_msInfo_1_bits_replaceData;
  logic io_msInfo_1_bits_releaseToClean;
  logic io_msInfo_2_valid;
  logic [8:0] io_msInfo_2_bits_set;
  logic [30:0] io_msInfo_2_bits_reqTag;
  logic io_msInfo_2_bits_willFree;
  logic io_msInfo_2_bits_aliasTask;
  logic io_msInfo_2_bits_blockRefill;
  logic io_msInfo_2_bits_meta_dirty;
  logic [1:0] io_msInfo_2_bits_meta_state;
  logic io_msInfo_2_bits_meta_clients;
  logic [1:0] io_msInfo_2_bits_meta_alias;
  logic io_msInfo_2_bits_meta_prefetch;
  logic [2:0] io_msInfo_2_bits_meta_prefetchSrc;
  logic io_msInfo_2_bits_meta_accessed;
  logic io_msInfo_2_bits_meta_tagErr;
  logic io_msInfo_2_bits_meta_dataErr;
  logic [30:0] io_msInfo_2_bits_metaTag;
  logic io_msInfo_2_bits_dirHit;
  logic io_msInfo_2_bits_w_grantfirst;
  logic io_msInfo_2_bits_s_release;
  logic io_msInfo_2_bits_s_cmoresp;
  logic io_msInfo_2_bits_s_cmometaw;
  logic io_msInfo_2_bits_w_releaseack;
  logic io_msInfo_2_bits_w_replResp;
  logic io_msInfo_2_bits_w_rprobeacklast;
  logic io_msInfo_2_bits_replaceData;
  logic io_msInfo_2_bits_releaseToClean;
  logic io_msInfo_3_valid;
  logic [8:0] io_msInfo_3_bits_set;
  logic [30:0] io_msInfo_3_bits_reqTag;
  logic io_msInfo_3_bits_willFree;
  logic io_msInfo_3_bits_aliasTask;
  logic io_msInfo_3_bits_blockRefill;
  logic io_msInfo_3_bits_meta_dirty;
  logic [1:0] io_msInfo_3_bits_meta_state;
  logic io_msInfo_3_bits_meta_clients;
  logic [1:0] io_msInfo_3_bits_meta_alias;
  logic io_msInfo_3_bits_meta_prefetch;
  logic [2:0] io_msInfo_3_bits_meta_prefetchSrc;
  logic io_msInfo_3_bits_meta_accessed;
  logic io_msInfo_3_bits_meta_tagErr;
  logic io_msInfo_3_bits_meta_dataErr;
  logic [30:0] io_msInfo_3_bits_metaTag;
  logic io_msInfo_3_bits_dirHit;
  logic io_msInfo_3_bits_w_grantfirst;
  logic io_msInfo_3_bits_s_release;
  logic io_msInfo_3_bits_s_cmoresp;
  logic io_msInfo_3_bits_s_cmometaw;
  logic io_msInfo_3_bits_w_releaseack;
  logic io_msInfo_3_bits_w_replResp;
  logic io_msInfo_3_bits_w_rprobeacklast;
  logic io_msInfo_3_bits_replaceData;
  logic io_msInfo_3_bits_releaseToClean;
  logic io_msInfo_4_valid;
  logic [8:0] io_msInfo_4_bits_set;
  logic [30:0] io_msInfo_4_bits_reqTag;
  logic io_msInfo_4_bits_willFree;
  logic io_msInfo_4_bits_aliasTask;
  logic io_msInfo_4_bits_blockRefill;
  logic io_msInfo_4_bits_meta_dirty;
  logic [1:0] io_msInfo_4_bits_meta_state;
  logic io_msInfo_4_bits_meta_clients;
  logic [1:0] io_msInfo_4_bits_meta_alias;
  logic io_msInfo_4_bits_meta_prefetch;
  logic [2:0] io_msInfo_4_bits_meta_prefetchSrc;
  logic io_msInfo_4_bits_meta_accessed;
  logic io_msInfo_4_bits_meta_tagErr;
  logic io_msInfo_4_bits_meta_dataErr;
  logic [30:0] io_msInfo_4_bits_metaTag;
  logic io_msInfo_4_bits_dirHit;
  logic io_msInfo_4_bits_w_grantfirst;
  logic io_msInfo_4_bits_s_release;
  logic io_msInfo_4_bits_s_cmoresp;
  logic io_msInfo_4_bits_s_cmometaw;
  logic io_msInfo_4_bits_w_releaseack;
  logic io_msInfo_4_bits_w_replResp;
  logic io_msInfo_4_bits_w_rprobeacklast;
  logic io_msInfo_4_bits_replaceData;
  logic io_msInfo_4_bits_releaseToClean;
  logic io_msInfo_5_valid;
  logic [8:0] io_msInfo_5_bits_set;
  logic [30:0] io_msInfo_5_bits_reqTag;
  logic io_msInfo_5_bits_willFree;
  logic io_msInfo_5_bits_aliasTask;
  logic io_msInfo_5_bits_blockRefill;
  logic io_msInfo_5_bits_meta_dirty;
  logic [1:0] io_msInfo_5_bits_meta_state;
  logic io_msInfo_5_bits_meta_clients;
  logic [1:0] io_msInfo_5_bits_meta_alias;
  logic io_msInfo_5_bits_meta_prefetch;
  logic [2:0] io_msInfo_5_bits_meta_prefetchSrc;
  logic io_msInfo_5_bits_meta_accessed;
  logic io_msInfo_5_bits_meta_tagErr;
  logic io_msInfo_5_bits_meta_dataErr;
  logic [30:0] io_msInfo_5_bits_metaTag;
  logic io_msInfo_5_bits_dirHit;
  logic io_msInfo_5_bits_w_grantfirst;
  logic io_msInfo_5_bits_s_release;
  logic io_msInfo_5_bits_s_cmoresp;
  logic io_msInfo_5_bits_s_cmometaw;
  logic io_msInfo_5_bits_w_releaseack;
  logic io_msInfo_5_bits_w_replResp;
  logic io_msInfo_5_bits_w_rprobeacklast;
  logic io_msInfo_5_bits_replaceData;
  logic io_msInfo_5_bits_releaseToClean;
  logic io_msInfo_6_valid;
  logic [8:0] io_msInfo_6_bits_set;
  logic [30:0] io_msInfo_6_bits_reqTag;
  logic io_msInfo_6_bits_willFree;
  logic io_msInfo_6_bits_aliasTask;
  logic io_msInfo_6_bits_blockRefill;
  logic io_msInfo_6_bits_meta_dirty;
  logic [1:0] io_msInfo_6_bits_meta_state;
  logic io_msInfo_6_bits_meta_clients;
  logic [1:0] io_msInfo_6_bits_meta_alias;
  logic io_msInfo_6_bits_meta_prefetch;
  logic [2:0] io_msInfo_6_bits_meta_prefetchSrc;
  logic io_msInfo_6_bits_meta_accessed;
  logic io_msInfo_6_bits_meta_tagErr;
  logic io_msInfo_6_bits_meta_dataErr;
  logic [30:0] io_msInfo_6_bits_metaTag;
  logic io_msInfo_6_bits_dirHit;
  logic io_msInfo_6_bits_w_grantfirst;
  logic io_msInfo_6_bits_s_release;
  logic io_msInfo_6_bits_s_cmoresp;
  logic io_msInfo_6_bits_s_cmometaw;
  logic io_msInfo_6_bits_w_releaseack;
  logic io_msInfo_6_bits_w_replResp;
  logic io_msInfo_6_bits_w_rprobeacklast;
  logic io_msInfo_6_bits_replaceData;
  logic io_msInfo_6_bits_releaseToClean;
  logic io_msInfo_7_valid;
  logic [8:0] io_msInfo_7_bits_set;
  logic [30:0] io_msInfo_7_bits_reqTag;
  logic io_msInfo_7_bits_willFree;
  logic io_msInfo_7_bits_aliasTask;
  logic io_msInfo_7_bits_blockRefill;
  logic io_msInfo_7_bits_meta_dirty;
  logic [1:0] io_msInfo_7_bits_meta_state;
  logic io_msInfo_7_bits_meta_clients;
  logic [1:0] io_msInfo_7_bits_meta_alias;
  logic io_msInfo_7_bits_meta_prefetch;
  logic [2:0] io_msInfo_7_bits_meta_prefetchSrc;
  logic io_msInfo_7_bits_meta_accessed;
  logic io_msInfo_7_bits_meta_tagErr;
  logic io_msInfo_7_bits_meta_dataErr;
  logic [30:0] io_msInfo_7_bits_metaTag;
  logic io_msInfo_7_bits_dirHit;
  logic io_msInfo_7_bits_w_grantfirst;
  logic io_msInfo_7_bits_s_release;
  logic io_msInfo_7_bits_s_cmoresp;
  logic io_msInfo_7_bits_s_cmometaw;
  logic io_msInfo_7_bits_w_releaseack;
  logic io_msInfo_7_bits_w_replResp;
  logic io_msInfo_7_bits_w_rprobeacklast;
  logic io_msInfo_7_bits_replaceData;
  logic io_msInfo_7_bits_releaseToClean;
  logic io_msInfo_8_valid;
  logic [8:0] io_msInfo_8_bits_set;
  logic [30:0] io_msInfo_8_bits_reqTag;
  logic io_msInfo_8_bits_willFree;
  logic io_msInfo_8_bits_aliasTask;
  logic io_msInfo_8_bits_blockRefill;
  logic io_msInfo_8_bits_meta_dirty;
  logic [1:0] io_msInfo_8_bits_meta_state;
  logic io_msInfo_8_bits_meta_clients;
  logic [1:0] io_msInfo_8_bits_meta_alias;
  logic io_msInfo_8_bits_meta_prefetch;
  logic [2:0] io_msInfo_8_bits_meta_prefetchSrc;
  logic io_msInfo_8_bits_meta_accessed;
  logic io_msInfo_8_bits_meta_tagErr;
  logic io_msInfo_8_bits_meta_dataErr;
  logic [30:0] io_msInfo_8_bits_metaTag;
  logic io_msInfo_8_bits_dirHit;
  logic io_msInfo_8_bits_w_grantfirst;
  logic io_msInfo_8_bits_s_release;
  logic io_msInfo_8_bits_s_cmoresp;
  logic io_msInfo_8_bits_s_cmometaw;
  logic io_msInfo_8_bits_w_releaseack;
  logic io_msInfo_8_bits_w_replResp;
  logic io_msInfo_8_bits_w_rprobeacklast;
  logic io_msInfo_8_bits_replaceData;
  logic io_msInfo_8_bits_releaseToClean;
  logic io_msInfo_9_valid;
  logic [8:0] io_msInfo_9_bits_set;
  logic [30:0] io_msInfo_9_bits_reqTag;
  logic io_msInfo_9_bits_willFree;
  logic io_msInfo_9_bits_aliasTask;
  logic io_msInfo_9_bits_blockRefill;
  logic io_msInfo_9_bits_meta_dirty;
  logic [1:0] io_msInfo_9_bits_meta_state;
  logic io_msInfo_9_bits_meta_clients;
  logic [1:0] io_msInfo_9_bits_meta_alias;
  logic io_msInfo_9_bits_meta_prefetch;
  logic [2:0] io_msInfo_9_bits_meta_prefetchSrc;
  logic io_msInfo_9_bits_meta_accessed;
  logic io_msInfo_9_bits_meta_tagErr;
  logic io_msInfo_9_bits_meta_dataErr;
  logic [30:0] io_msInfo_9_bits_metaTag;
  logic io_msInfo_9_bits_dirHit;
  logic io_msInfo_9_bits_w_grantfirst;
  logic io_msInfo_9_bits_s_release;
  logic io_msInfo_9_bits_s_cmoresp;
  logic io_msInfo_9_bits_s_cmometaw;
  logic io_msInfo_9_bits_w_releaseack;
  logic io_msInfo_9_bits_w_replResp;
  logic io_msInfo_9_bits_w_rprobeacklast;
  logic io_msInfo_9_bits_replaceData;
  logic io_msInfo_9_bits_releaseToClean;
  logic io_msInfo_10_valid;
  logic [8:0] io_msInfo_10_bits_set;
  logic [30:0] io_msInfo_10_bits_reqTag;
  logic io_msInfo_10_bits_willFree;
  logic io_msInfo_10_bits_aliasTask;
  logic io_msInfo_10_bits_blockRefill;
  logic io_msInfo_10_bits_meta_dirty;
  logic [1:0] io_msInfo_10_bits_meta_state;
  logic io_msInfo_10_bits_meta_clients;
  logic [1:0] io_msInfo_10_bits_meta_alias;
  logic io_msInfo_10_bits_meta_prefetch;
  logic [2:0] io_msInfo_10_bits_meta_prefetchSrc;
  logic io_msInfo_10_bits_meta_accessed;
  logic io_msInfo_10_bits_meta_tagErr;
  logic io_msInfo_10_bits_meta_dataErr;
  logic [30:0] io_msInfo_10_bits_metaTag;
  logic io_msInfo_10_bits_dirHit;
  logic io_msInfo_10_bits_w_grantfirst;
  logic io_msInfo_10_bits_s_release;
  logic io_msInfo_10_bits_s_cmoresp;
  logic io_msInfo_10_bits_s_cmometaw;
  logic io_msInfo_10_bits_w_releaseack;
  logic io_msInfo_10_bits_w_replResp;
  logic io_msInfo_10_bits_w_rprobeacklast;
  logic io_msInfo_10_bits_replaceData;
  logic io_msInfo_10_bits_releaseToClean;
  logic io_msInfo_11_valid;
  logic [8:0] io_msInfo_11_bits_set;
  logic [30:0] io_msInfo_11_bits_reqTag;
  logic io_msInfo_11_bits_willFree;
  logic io_msInfo_11_bits_aliasTask;
  logic io_msInfo_11_bits_blockRefill;
  logic io_msInfo_11_bits_meta_dirty;
  logic [1:0] io_msInfo_11_bits_meta_state;
  logic io_msInfo_11_bits_meta_clients;
  logic [1:0] io_msInfo_11_bits_meta_alias;
  logic io_msInfo_11_bits_meta_prefetch;
  logic [2:0] io_msInfo_11_bits_meta_prefetchSrc;
  logic io_msInfo_11_bits_meta_accessed;
  logic io_msInfo_11_bits_meta_tagErr;
  logic io_msInfo_11_bits_meta_dataErr;
  logic [30:0] io_msInfo_11_bits_metaTag;
  logic io_msInfo_11_bits_dirHit;
  logic io_msInfo_11_bits_w_grantfirst;
  logic io_msInfo_11_bits_s_release;
  logic io_msInfo_11_bits_s_cmoresp;
  logic io_msInfo_11_bits_s_cmometaw;
  logic io_msInfo_11_bits_w_releaseack;
  logic io_msInfo_11_bits_w_replResp;
  logic io_msInfo_11_bits_w_rprobeacklast;
  logic io_msInfo_11_bits_replaceData;
  logic io_msInfo_11_bits_releaseToClean;
  logic io_msInfo_12_valid;
  logic [8:0] io_msInfo_12_bits_set;
  logic [30:0] io_msInfo_12_bits_reqTag;
  logic io_msInfo_12_bits_willFree;
  logic io_msInfo_12_bits_aliasTask;
  logic io_msInfo_12_bits_blockRefill;
  logic io_msInfo_12_bits_meta_dirty;
  logic [1:0] io_msInfo_12_bits_meta_state;
  logic io_msInfo_12_bits_meta_clients;
  logic [1:0] io_msInfo_12_bits_meta_alias;
  logic io_msInfo_12_bits_meta_prefetch;
  logic [2:0] io_msInfo_12_bits_meta_prefetchSrc;
  logic io_msInfo_12_bits_meta_accessed;
  logic io_msInfo_12_bits_meta_tagErr;
  logic io_msInfo_12_bits_meta_dataErr;
  logic [30:0] io_msInfo_12_bits_metaTag;
  logic io_msInfo_12_bits_dirHit;
  logic io_msInfo_12_bits_w_grantfirst;
  logic io_msInfo_12_bits_s_release;
  logic io_msInfo_12_bits_s_cmoresp;
  logic io_msInfo_12_bits_s_cmometaw;
  logic io_msInfo_12_bits_w_releaseack;
  logic io_msInfo_12_bits_w_replResp;
  logic io_msInfo_12_bits_w_rprobeacklast;
  logic io_msInfo_12_bits_replaceData;
  logic io_msInfo_12_bits_releaseToClean;
  logic io_msInfo_13_valid;
  logic [8:0] io_msInfo_13_bits_set;
  logic [30:0] io_msInfo_13_bits_reqTag;
  logic io_msInfo_13_bits_willFree;
  logic io_msInfo_13_bits_aliasTask;
  logic io_msInfo_13_bits_blockRefill;
  logic io_msInfo_13_bits_meta_dirty;
  logic [1:0] io_msInfo_13_bits_meta_state;
  logic io_msInfo_13_bits_meta_clients;
  logic [1:0] io_msInfo_13_bits_meta_alias;
  logic io_msInfo_13_bits_meta_prefetch;
  logic [2:0] io_msInfo_13_bits_meta_prefetchSrc;
  logic io_msInfo_13_bits_meta_accessed;
  logic io_msInfo_13_bits_meta_tagErr;
  logic io_msInfo_13_bits_meta_dataErr;
  logic [30:0] io_msInfo_13_bits_metaTag;
  logic io_msInfo_13_bits_dirHit;
  logic io_msInfo_13_bits_w_grantfirst;
  logic io_msInfo_13_bits_s_release;
  logic io_msInfo_13_bits_s_cmoresp;
  logic io_msInfo_13_bits_s_cmometaw;
  logic io_msInfo_13_bits_w_releaseack;
  logic io_msInfo_13_bits_w_replResp;
  logic io_msInfo_13_bits_w_rprobeacklast;
  logic io_msInfo_13_bits_replaceData;
  logic io_msInfo_13_bits_releaseToClean;
  logic io_msInfo_14_valid;
  logic [8:0] io_msInfo_14_bits_set;
  logic [30:0] io_msInfo_14_bits_reqTag;
  logic io_msInfo_14_bits_willFree;
  logic io_msInfo_14_bits_aliasTask;
  logic io_msInfo_14_bits_blockRefill;
  logic io_msInfo_14_bits_meta_dirty;
  logic [1:0] io_msInfo_14_bits_meta_state;
  logic io_msInfo_14_bits_meta_clients;
  logic [1:0] io_msInfo_14_bits_meta_alias;
  logic io_msInfo_14_bits_meta_prefetch;
  logic [2:0] io_msInfo_14_bits_meta_prefetchSrc;
  logic io_msInfo_14_bits_meta_accessed;
  logic io_msInfo_14_bits_meta_tagErr;
  logic io_msInfo_14_bits_meta_dataErr;
  logic [30:0] io_msInfo_14_bits_metaTag;
  logic io_msInfo_14_bits_dirHit;
  logic io_msInfo_14_bits_w_grantfirst;
  logic io_msInfo_14_bits_s_release;
  logic io_msInfo_14_bits_s_cmoresp;
  logic io_msInfo_14_bits_s_cmometaw;
  logic io_msInfo_14_bits_w_releaseack;
  logic io_msInfo_14_bits_w_replResp;
  logic io_msInfo_14_bits_w_rprobeacklast;
  logic io_msInfo_14_bits_replaceData;
  logic io_msInfo_14_bits_releaseToClean;
  logic io_msInfo_15_valid;
  logic [8:0] io_msInfo_15_bits_set;
  logic [30:0] io_msInfo_15_bits_reqTag;
  logic io_msInfo_15_bits_willFree;
  logic io_msInfo_15_bits_aliasTask;
  logic io_msInfo_15_bits_blockRefill;
  logic io_msInfo_15_bits_meta_dirty;
  logic [1:0] io_msInfo_15_bits_meta_state;
  logic io_msInfo_15_bits_meta_clients;
  logic [1:0] io_msInfo_15_bits_meta_alias;
  logic io_msInfo_15_bits_meta_prefetch;
  logic [2:0] io_msInfo_15_bits_meta_prefetchSrc;
  logic io_msInfo_15_bits_meta_accessed;
  logic io_msInfo_15_bits_meta_tagErr;
  logic io_msInfo_15_bits_meta_dataErr;
  logic [30:0] io_msInfo_15_bits_metaTag;
  logic io_msInfo_15_bits_dirHit;
  logic io_msInfo_15_bits_w_grantfirst;
  logic io_msInfo_15_bits_s_release;
  logic io_msInfo_15_bits_s_cmoresp;
  logic io_msInfo_15_bits_s_cmometaw;
  logic io_msInfo_15_bits_w_releaseack;
  logic io_msInfo_15_bits_w_replResp;
  logic io_msInfo_15_bits_w_rprobeacklast;
  logic io_msInfo_15_bits_replaceData;
  logic io_msInfo_15_bits_releaseToClean;
  logic g_io_rxsnp_ready;
  logic i_io_rxsnp_ready;
  logic g_io_task_valid;
  logic i_io_task_valid;
  logic [8:0] g_io_task_bits_set;
  logic [8:0] i_io_task_bits_set;
  logic [30:0] g_io_task_bits_tag;
  logic [30:0] i_io_task_bits_tag;
  logic [5:0] g_io_task_bits_off;
  logic [5:0] i_io_task_bits_off;
  logic g_io_task_bits_snpHitRelease;
  logic i_io_task_bits_snpHitRelease;
  logic g_io_task_bits_snpHitReleaseToInval;
  logic i_io_task_bits_snpHitReleaseToInval;
  logic g_io_task_bits_snpHitReleaseToClean;
  logic i_io_task_bits_snpHitReleaseToClean;
  logic g_io_task_bits_snpHitReleaseWithData;
  logic i_io_task_bits_snpHitReleaseWithData;
  logic [7:0] g_io_task_bits_snpHitReleaseIdx;
  logic [7:0] i_io_task_bits_snpHitReleaseIdx;
  logic g_io_task_bits_snpHitReleaseMeta_dirty;
  logic i_io_task_bits_snpHitReleaseMeta_dirty;
  logic [1:0] g_io_task_bits_snpHitReleaseMeta_state;
  logic [1:0] i_io_task_bits_snpHitReleaseMeta_state;
  logic g_io_task_bits_snpHitReleaseMeta_clients;
  logic i_io_task_bits_snpHitReleaseMeta_clients;
  logic [1:0] g_io_task_bits_snpHitReleaseMeta_alias;
  logic [1:0] i_io_task_bits_snpHitReleaseMeta_alias;
  logic g_io_task_bits_snpHitReleaseMeta_prefetch;
  logic i_io_task_bits_snpHitReleaseMeta_prefetch;
  logic [2:0] g_io_task_bits_snpHitReleaseMeta_prefetchSrc;
  logic [2:0] i_io_task_bits_snpHitReleaseMeta_prefetchSrc;
  logic g_io_task_bits_snpHitReleaseMeta_accessed;
  logic i_io_task_bits_snpHitReleaseMeta_accessed;
  logic g_io_task_bits_snpHitReleaseMeta_tagErr;
  logic i_io_task_bits_snpHitReleaseMeta_tagErr;
  logic g_io_task_bits_snpHitReleaseMeta_dataErr;
  logic i_io_task_bits_snpHitReleaseMeta_dataErr;
  logic [10:0] g_io_task_bits_srcID;
  logic [10:0] i_io_task_bits_srcID;
  logic [11:0] g_io_task_bits_txnID;
  logic [11:0] i_io_task_bits_txnID;
  logic [10:0] g_io_task_bits_fwdNID;
  logic [10:0] i_io_task_bits_fwdNID;
  logic [11:0] g_io_task_bits_fwdTxnID;
  logic [11:0] i_io_task_bits_fwdTxnID;
  logic [6:0] g_io_task_bits_chiOpcode;
  logic [6:0] i_io_task_bits_chiOpcode;
  logic g_io_task_bits_retToSrc;
  logic i_io_task_bits_retToSrc;
  logic g_io_task_bits_traceTag;
  logic i_io_task_bits_traceTag;

  RXSNP u_g (
    .clock(clock),
    .reset(reset),
    .io_rxsnp_ready(g_io_rxsnp_ready),
    .io_rxsnp_valid(io_rxsnp_valid),
    .io_rxsnp_bits_qos(io_rxsnp_bits_qos),
    .io_rxsnp_bits_srcID(io_rxsnp_bits_srcID),
    .io_rxsnp_bits_txnID(io_rxsnp_bits_txnID),
    .io_rxsnp_bits_fwdNID(io_rxsnp_bits_fwdNID),
    .io_rxsnp_bits_fwdTxnID(io_rxsnp_bits_fwdTxnID),
    .io_rxsnp_bits_opcode(io_rxsnp_bits_opcode),
    .io_rxsnp_bits_addr(io_rxsnp_bits_addr),
    .io_rxsnp_bits_ns(io_rxsnp_bits_ns),
    .io_rxsnp_bits_doNotGoToSD(io_rxsnp_bits_doNotGoToSD),
    .io_rxsnp_bits_retToSrc(io_rxsnp_bits_retToSrc),
    .io_rxsnp_bits_traceTag(io_rxsnp_bits_traceTag),
    .io_rxsnp_bits_mpam_perfMonGroup(io_rxsnp_bits_mpam_perfMonGroup),
    .io_rxsnp_bits_mpam_partID(io_rxsnp_bits_mpam_partID),
    .io_rxsnp_bits_mpam_mpamNS(io_rxsnp_bits_mpam_mpamNS),
    .io_task_ready(io_task_ready),
    .io_task_valid(g_io_task_valid),
    .io_task_bits_set(g_io_task_bits_set),
    .io_task_bits_tag(g_io_task_bits_tag),
    .io_task_bits_off(g_io_task_bits_off),
    .io_task_bits_snpHitRelease(g_io_task_bits_snpHitRelease),
    .io_task_bits_snpHitReleaseToInval(g_io_task_bits_snpHitReleaseToInval),
    .io_task_bits_snpHitReleaseToClean(g_io_task_bits_snpHitReleaseToClean),
    .io_task_bits_snpHitReleaseWithData(g_io_task_bits_snpHitReleaseWithData),
    .io_task_bits_snpHitReleaseIdx(g_io_task_bits_snpHitReleaseIdx),
    .io_task_bits_snpHitReleaseMeta_dirty(g_io_task_bits_snpHitReleaseMeta_dirty),
    .io_task_bits_snpHitReleaseMeta_state(g_io_task_bits_snpHitReleaseMeta_state),
    .io_task_bits_snpHitReleaseMeta_clients(g_io_task_bits_snpHitReleaseMeta_clients),
    .io_task_bits_snpHitReleaseMeta_alias(g_io_task_bits_snpHitReleaseMeta_alias),
    .io_task_bits_snpHitReleaseMeta_prefetch(g_io_task_bits_snpHitReleaseMeta_prefetch),
    .io_task_bits_snpHitReleaseMeta_prefetchSrc(g_io_task_bits_snpHitReleaseMeta_prefetchSrc),
    .io_task_bits_snpHitReleaseMeta_accessed(g_io_task_bits_snpHitReleaseMeta_accessed),
    .io_task_bits_snpHitReleaseMeta_tagErr(g_io_task_bits_snpHitReleaseMeta_tagErr),
    .io_task_bits_snpHitReleaseMeta_dataErr(g_io_task_bits_snpHitReleaseMeta_dataErr),
    .io_task_bits_srcID(g_io_task_bits_srcID),
    .io_task_bits_txnID(g_io_task_bits_txnID),
    .io_task_bits_fwdNID(g_io_task_bits_fwdNID),
    .io_task_bits_fwdTxnID(g_io_task_bits_fwdTxnID),
    .io_task_bits_chiOpcode(g_io_task_bits_chiOpcode),
    .io_task_bits_retToSrc(g_io_task_bits_retToSrc),
    .io_task_bits_traceTag(g_io_task_bits_traceTag),
    .io_msInfo_0_valid(io_msInfo_0_valid),
    .io_msInfo_0_bits_set(io_msInfo_0_bits_set),
    .io_msInfo_0_bits_reqTag(io_msInfo_0_bits_reqTag),
    .io_msInfo_0_bits_willFree(io_msInfo_0_bits_willFree),
    .io_msInfo_0_bits_aliasTask(io_msInfo_0_bits_aliasTask),
    .io_msInfo_0_bits_blockRefill(io_msInfo_0_bits_blockRefill),
    .io_msInfo_0_bits_meta_dirty(io_msInfo_0_bits_meta_dirty),
    .io_msInfo_0_bits_meta_state(io_msInfo_0_bits_meta_state),
    .io_msInfo_0_bits_meta_clients(io_msInfo_0_bits_meta_clients),
    .io_msInfo_0_bits_meta_alias(io_msInfo_0_bits_meta_alias),
    .io_msInfo_0_bits_meta_prefetch(io_msInfo_0_bits_meta_prefetch),
    .io_msInfo_0_bits_meta_prefetchSrc(io_msInfo_0_bits_meta_prefetchSrc),
    .io_msInfo_0_bits_meta_accessed(io_msInfo_0_bits_meta_accessed),
    .io_msInfo_0_bits_meta_tagErr(io_msInfo_0_bits_meta_tagErr),
    .io_msInfo_0_bits_meta_dataErr(io_msInfo_0_bits_meta_dataErr),
    .io_msInfo_0_bits_metaTag(io_msInfo_0_bits_metaTag),
    .io_msInfo_0_bits_dirHit(io_msInfo_0_bits_dirHit),
    .io_msInfo_0_bits_w_grantfirst(io_msInfo_0_bits_w_grantfirst),
    .io_msInfo_0_bits_s_release(io_msInfo_0_bits_s_release),
    .io_msInfo_0_bits_s_cmoresp(io_msInfo_0_bits_s_cmoresp),
    .io_msInfo_0_bits_s_cmometaw(io_msInfo_0_bits_s_cmometaw),
    .io_msInfo_0_bits_w_releaseack(io_msInfo_0_bits_w_releaseack),
    .io_msInfo_0_bits_w_replResp(io_msInfo_0_bits_w_replResp),
    .io_msInfo_0_bits_w_rprobeacklast(io_msInfo_0_bits_w_rprobeacklast),
    .io_msInfo_0_bits_replaceData(io_msInfo_0_bits_replaceData),
    .io_msInfo_0_bits_releaseToClean(io_msInfo_0_bits_releaseToClean),
    .io_msInfo_1_valid(io_msInfo_1_valid),
    .io_msInfo_1_bits_set(io_msInfo_1_bits_set),
    .io_msInfo_1_bits_reqTag(io_msInfo_1_bits_reqTag),
    .io_msInfo_1_bits_willFree(io_msInfo_1_bits_willFree),
    .io_msInfo_1_bits_aliasTask(io_msInfo_1_bits_aliasTask),
    .io_msInfo_1_bits_blockRefill(io_msInfo_1_bits_blockRefill),
    .io_msInfo_1_bits_meta_dirty(io_msInfo_1_bits_meta_dirty),
    .io_msInfo_1_bits_meta_state(io_msInfo_1_bits_meta_state),
    .io_msInfo_1_bits_meta_clients(io_msInfo_1_bits_meta_clients),
    .io_msInfo_1_bits_meta_alias(io_msInfo_1_bits_meta_alias),
    .io_msInfo_1_bits_meta_prefetch(io_msInfo_1_bits_meta_prefetch),
    .io_msInfo_1_bits_meta_prefetchSrc(io_msInfo_1_bits_meta_prefetchSrc),
    .io_msInfo_1_bits_meta_accessed(io_msInfo_1_bits_meta_accessed),
    .io_msInfo_1_bits_meta_tagErr(io_msInfo_1_bits_meta_tagErr),
    .io_msInfo_1_bits_meta_dataErr(io_msInfo_1_bits_meta_dataErr),
    .io_msInfo_1_bits_metaTag(io_msInfo_1_bits_metaTag),
    .io_msInfo_1_bits_dirHit(io_msInfo_1_bits_dirHit),
    .io_msInfo_1_bits_w_grantfirst(io_msInfo_1_bits_w_grantfirst),
    .io_msInfo_1_bits_s_release(io_msInfo_1_bits_s_release),
    .io_msInfo_1_bits_s_cmoresp(io_msInfo_1_bits_s_cmoresp),
    .io_msInfo_1_bits_s_cmometaw(io_msInfo_1_bits_s_cmometaw),
    .io_msInfo_1_bits_w_releaseack(io_msInfo_1_bits_w_releaseack),
    .io_msInfo_1_bits_w_replResp(io_msInfo_1_bits_w_replResp),
    .io_msInfo_1_bits_w_rprobeacklast(io_msInfo_1_bits_w_rprobeacklast),
    .io_msInfo_1_bits_replaceData(io_msInfo_1_bits_replaceData),
    .io_msInfo_1_bits_releaseToClean(io_msInfo_1_bits_releaseToClean),
    .io_msInfo_2_valid(io_msInfo_2_valid),
    .io_msInfo_2_bits_set(io_msInfo_2_bits_set),
    .io_msInfo_2_bits_reqTag(io_msInfo_2_bits_reqTag),
    .io_msInfo_2_bits_willFree(io_msInfo_2_bits_willFree),
    .io_msInfo_2_bits_aliasTask(io_msInfo_2_bits_aliasTask),
    .io_msInfo_2_bits_blockRefill(io_msInfo_2_bits_blockRefill),
    .io_msInfo_2_bits_meta_dirty(io_msInfo_2_bits_meta_dirty),
    .io_msInfo_2_bits_meta_state(io_msInfo_2_bits_meta_state),
    .io_msInfo_2_bits_meta_clients(io_msInfo_2_bits_meta_clients),
    .io_msInfo_2_bits_meta_alias(io_msInfo_2_bits_meta_alias),
    .io_msInfo_2_bits_meta_prefetch(io_msInfo_2_bits_meta_prefetch),
    .io_msInfo_2_bits_meta_prefetchSrc(io_msInfo_2_bits_meta_prefetchSrc),
    .io_msInfo_2_bits_meta_accessed(io_msInfo_2_bits_meta_accessed),
    .io_msInfo_2_bits_meta_tagErr(io_msInfo_2_bits_meta_tagErr),
    .io_msInfo_2_bits_meta_dataErr(io_msInfo_2_bits_meta_dataErr),
    .io_msInfo_2_bits_metaTag(io_msInfo_2_bits_metaTag),
    .io_msInfo_2_bits_dirHit(io_msInfo_2_bits_dirHit),
    .io_msInfo_2_bits_w_grantfirst(io_msInfo_2_bits_w_grantfirst),
    .io_msInfo_2_bits_s_release(io_msInfo_2_bits_s_release),
    .io_msInfo_2_bits_s_cmoresp(io_msInfo_2_bits_s_cmoresp),
    .io_msInfo_2_bits_s_cmometaw(io_msInfo_2_bits_s_cmometaw),
    .io_msInfo_2_bits_w_releaseack(io_msInfo_2_bits_w_releaseack),
    .io_msInfo_2_bits_w_replResp(io_msInfo_2_bits_w_replResp),
    .io_msInfo_2_bits_w_rprobeacklast(io_msInfo_2_bits_w_rprobeacklast),
    .io_msInfo_2_bits_replaceData(io_msInfo_2_bits_replaceData),
    .io_msInfo_2_bits_releaseToClean(io_msInfo_2_bits_releaseToClean),
    .io_msInfo_3_valid(io_msInfo_3_valid),
    .io_msInfo_3_bits_set(io_msInfo_3_bits_set),
    .io_msInfo_3_bits_reqTag(io_msInfo_3_bits_reqTag),
    .io_msInfo_3_bits_willFree(io_msInfo_3_bits_willFree),
    .io_msInfo_3_bits_aliasTask(io_msInfo_3_bits_aliasTask),
    .io_msInfo_3_bits_blockRefill(io_msInfo_3_bits_blockRefill),
    .io_msInfo_3_bits_meta_dirty(io_msInfo_3_bits_meta_dirty),
    .io_msInfo_3_bits_meta_state(io_msInfo_3_bits_meta_state),
    .io_msInfo_3_bits_meta_clients(io_msInfo_3_bits_meta_clients),
    .io_msInfo_3_bits_meta_alias(io_msInfo_3_bits_meta_alias),
    .io_msInfo_3_bits_meta_prefetch(io_msInfo_3_bits_meta_prefetch),
    .io_msInfo_3_bits_meta_prefetchSrc(io_msInfo_3_bits_meta_prefetchSrc),
    .io_msInfo_3_bits_meta_accessed(io_msInfo_3_bits_meta_accessed),
    .io_msInfo_3_bits_meta_tagErr(io_msInfo_3_bits_meta_tagErr),
    .io_msInfo_3_bits_meta_dataErr(io_msInfo_3_bits_meta_dataErr),
    .io_msInfo_3_bits_metaTag(io_msInfo_3_bits_metaTag),
    .io_msInfo_3_bits_dirHit(io_msInfo_3_bits_dirHit),
    .io_msInfo_3_bits_w_grantfirst(io_msInfo_3_bits_w_grantfirst),
    .io_msInfo_3_bits_s_release(io_msInfo_3_bits_s_release),
    .io_msInfo_3_bits_s_cmoresp(io_msInfo_3_bits_s_cmoresp),
    .io_msInfo_3_bits_s_cmometaw(io_msInfo_3_bits_s_cmometaw),
    .io_msInfo_3_bits_w_releaseack(io_msInfo_3_bits_w_releaseack),
    .io_msInfo_3_bits_w_replResp(io_msInfo_3_bits_w_replResp),
    .io_msInfo_3_bits_w_rprobeacklast(io_msInfo_3_bits_w_rprobeacklast),
    .io_msInfo_3_bits_replaceData(io_msInfo_3_bits_replaceData),
    .io_msInfo_3_bits_releaseToClean(io_msInfo_3_bits_releaseToClean),
    .io_msInfo_4_valid(io_msInfo_4_valid),
    .io_msInfo_4_bits_set(io_msInfo_4_bits_set),
    .io_msInfo_4_bits_reqTag(io_msInfo_4_bits_reqTag),
    .io_msInfo_4_bits_willFree(io_msInfo_4_bits_willFree),
    .io_msInfo_4_bits_aliasTask(io_msInfo_4_bits_aliasTask),
    .io_msInfo_4_bits_blockRefill(io_msInfo_4_bits_blockRefill),
    .io_msInfo_4_bits_meta_dirty(io_msInfo_4_bits_meta_dirty),
    .io_msInfo_4_bits_meta_state(io_msInfo_4_bits_meta_state),
    .io_msInfo_4_bits_meta_clients(io_msInfo_4_bits_meta_clients),
    .io_msInfo_4_bits_meta_alias(io_msInfo_4_bits_meta_alias),
    .io_msInfo_4_bits_meta_prefetch(io_msInfo_4_bits_meta_prefetch),
    .io_msInfo_4_bits_meta_prefetchSrc(io_msInfo_4_bits_meta_prefetchSrc),
    .io_msInfo_4_bits_meta_accessed(io_msInfo_4_bits_meta_accessed),
    .io_msInfo_4_bits_meta_tagErr(io_msInfo_4_bits_meta_tagErr),
    .io_msInfo_4_bits_meta_dataErr(io_msInfo_4_bits_meta_dataErr),
    .io_msInfo_4_bits_metaTag(io_msInfo_4_bits_metaTag),
    .io_msInfo_4_bits_dirHit(io_msInfo_4_bits_dirHit),
    .io_msInfo_4_bits_w_grantfirst(io_msInfo_4_bits_w_grantfirst),
    .io_msInfo_4_bits_s_release(io_msInfo_4_bits_s_release),
    .io_msInfo_4_bits_s_cmoresp(io_msInfo_4_bits_s_cmoresp),
    .io_msInfo_4_bits_s_cmometaw(io_msInfo_4_bits_s_cmometaw),
    .io_msInfo_4_bits_w_releaseack(io_msInfo_4_bits_w_releaseack),
    .io_msInfo_4_bits_w_replResp(io_msInfo_4_bits_w_replResp),
    .io_msInfo_4_bits_w_rprobeacklast(io_msInfo_4_bits_w_rprobeacklast),
    .io_msInfo_4_bits_replaceData(io_msInfo_4_bits_replaceData),
    .io_msInfo_4_bits_releaseToClean(io_msInfo_4_bits_releaseToClean),
    .io_msInfo_5_valid(io_msInfo_5_valid),
    .io_msInfo_5_bits_set(io_msInfo_5_bits_set),
    .io_msInfo_5_bits_reqTag(io_msInfo_5_bits_reqTag),
    .io_msInfo_5_bits_willFree(io_msInfo_5_bits_willFree),
    .io_msInfo_5_bits_aliasTask(io_msInfo_5_bits_aliasTask),
    .io_msInfo_5_bits_blockRefill(io_msInfo_5_bits_blockRefill),
    .io_msInfo_5_bits_meta_dirty(io_msInfo_5_bits_meta_dirty),
    .io_msInfo_5_bits_meta_state(io_msInfo_5_bits_meta_state),
    .io_msInfo_5_bits_meta_clients(io_msInfo_5_bits_meta_clients),
    .io_msInfo_5_bits_meta_alias(io_msInfo_5_bits_meta_alias),
    .io_msInfo_5_bits_meta_prefetch(io_msInfo_5_bits_meta_prefetch),
    .io_msInfo_5_bits_meta_prefetchSrc(io_msInfo_5_bits_meta_prefetchSrc),
    .io_msInfo_5_bits_meta_accessed(io_msInfo_5_bits_meta_accessed),
    .io_msInfo_5_bits_meta_tagErr(io_msInfo_5_bits_meta_tagErr),
    .io_msInfo_5_bits_meta_dataErr(io_msInfo_5_bits_meta_dataErr),
    .io_msInfo_5_bits_metaTag(io_msInfo_5_bits_metaTag),
    .io_msInfo_5_bits_dirHit(io_msInfo_5_bits_dirHit),
    .io_msInfo_5_bits_w_grantfirst(io_msInfo_5_bits_w_grantfirst),
    .io_msInfo_5_bits_s_release(io_msInfo_5_bits_s_release),
    .io_msInfo_5_bits_s_cmoresp(io_msInfo_5_bits_s_cmoresp),
    .io_msInfo_5_bits_s_cmometaw(io_msInfo_5_bits_s_cmometaw),
    .io_msInfo_5_bits_w_releaseack(io_msInfo_5_bits_w_releaseack),
    .io_msInfo_5_bits_w_replResp(io_msInfo_5_bits_w_replResp),
    .io_msInfo_5_bits_w_rprobeacklast(io_msInfo_5_bits_w_rprobeacklast),
    .io_msInfo_5_bits_replaceData(io_msInfo_5_bits_replaceData),
    .io_msInfo_5_bits_releaseToClean(io_msInfo_5_bits_releaseToClean),
    .io_msInfo_6_valid(io_msInfo_6_valid),
    .io_msInfo_6_bits_set(io_msInfo_6_bits_set),
    .io_msInfo_6_bits_reqTag(io_msInfo_6_bits_reqTag),
    .io_msInfo_6_bits_willFree(io_msInfo_6_bits_willFree),
    .io_msInfo_6_bits_aliasTask(io_msInfo_6_bits_aliasTask),
    .io_msInfo_6_bits_blockRefill(io_msInfo_6_bits_blockRefill),
    .io_msInfo_6_bits_meta_dirty(io_msInfo_6_bits_meta_dirty),
    .io_msInfo_6_bits_meta_state(io_msInfo_6_bits_meta_state),
    .io_msInfo_6_bits_meta_clients(io_msInfo_6_bits_meta_clients),
    .io_msInfo_6_bits_meta_alias(io_msInfo_6_bits_meta_alias),
    .io_msInfo_6_bits_meta_prefetch(io_msInfo_6_bits_meta_prefetch),
    .io_msInfo_6_bits_meta_prefetchSrc(io_msInfo_6_bits_meta_prefetchSrc),
    .io_msInfo_6_bits_meta_accessed(io_msInfo_6_bits_meta_accessed),
    .io_msInfo_6_bits_meta_tagErr(io_msInfo_6_bits_meta_tagErr),
    .io_msInfo_6_bits_meta_dataErr(io_msInfo_6_bits_meta_dataErr),
    .io_msInfo_6_bits_metaTag(io_msInfo_6_bits_metaTag),
    .io_msInfo_6_bits_dirHit(io_msInfo_6_bits_dirHit),
    .io_msInfo_6_bits_w_grantfirst(io_msInfo_6_bits_w_grantfirst),
    .io_msInfo_6_bits_s_release(io_msInfo_6_bits_s_release),
    .io_msInfo_6_bits_s_cmoresp(io_msInfo_6_bits_s_cmoresp),
    .io_msInfo_6_bits_s_cmometaw(io_msInfo_6_bits_s_cmometaw),
    .io_msInfo_6_bits_w_releaseack(io_msInfo_6_bits_w_releaseack),
    .io_msInfo_6_bits_w_replResp(io_msInfo_6_bits_w_replResp),
    .io_msInfo_6_bits_w_rprobeacklast(io_msInfo_6_bits_w_rprobeacklast),
    .io_msInfo_6_bits_replaceData(io_msInfo_6_bits_replaceData),
    .io_msInfo_6_bits_releaseToClean(io_msInfo_6_bits_releaseToClean),
    .io_msInfo_7_valid(io_msInfo_7_valid),
    .io_msInfo_7_bits_set(io_msInfo_7_bits_set),
    .io_msInfo_7_bits_reqTag(io_msInfo_7_bits_reqTag),
    .io_msInfo_7_bits_willFree(io_msInfo_7_bits_willFree),
    .io_msInfo_7_bits_aliasTask(io_msInfo_7_bits_aliasTask),
    .io_msInfo_7_bits_blockRefill(io_msInfo_7_bits_blockRefill),
    .io_msInfo_7_bits_meta_dirty(io_msInfo_7_bits_meta_dirty),
    .io_msInfo_7_bits_meta_state(io_msInfo_7_bits_meta_state),
    .io_msInfo_7_bits_meta_clients(io_msInfo_7_bits_meta_clients),
    .io_msInfo_7_bits_meta_alias(io_msInfo_7_bits_meta_alias),
    .io_msInfo_7_bits_meta_prefetch(io_msInfo_7_bits_meta_prefetch),
    .io_msInfo_7_bits_meta_prefetchSrc(io_msInfo_7_bits_meta_prefetchSrc),
    .io_msInfo_7_bits_meta_accessed(io_msInfo_7_bits_meta_accessed),
    .io_msInfo_7_bits_meta_tagErr(io_msInfo_7_bits_meta_tagErr),
    .io_msInfo_7_bits_meta_dataErr(io_msInfo_7_bits_meta_dataErr),
    .io_msInfo_7_bits_metaTag(io_msInfo_7_bits_metaTag),
    .io_msInfo_7_bits_dirHit(io_msInfo_7_bits_dirHit),
    .io_msInfo_7_bits_w_grantfirst(io_msInfo_7_bits_w_grantfirst),
    .io_msInfo_7_bits_s_release(io_msInfo_7_bits_s_release),
    .io_msInfo_7_bits_s_cmoresp(io_msInfo_7_bits_s_cmoresp),
    .io_msInfo_7_bits_s_cmometaw(io_msInfo_7_bits_s_cmometaw),
    .io_msInfo_7_bits_w_releaseack(io_msInfo_7_bits_w_releaseack),
    .io_msInfo_7_bits_w_replResp(io_msInfo_7_bits_w_replResp),
    .io_msInfo_7_bits_w_rprobeacklast(io_msInfo_7_bits_w_rprobeacklast),
    .io_msInfo_7_bits_replaceData(io_msInfo_7_bits_replaceData),
    .io_msInfo_7_bits_releaseToClean(io_msInfo_7_bits_releaseToClean),
    .io_msInfo_8_valid(io_msInfo_8_valid),
    .io_msInfo_8_bits_set(io_msInfo_8_bits_set),
    .io_msInfo_8_bits_reqTag(io_msInfo_8_bits_reqTag),
    .io_msInfo_8_bits_willFree(io_msInfo_8_bits_willFree),
    .io_msInfo_8_bits_aliasTask(io_msInfo_8_bits_aliasTask),
    .io_msInfo_8_bits_blockRefill(io_msInfo_8_bits_blockRefill),
    .io_msInfo_8_bits_meta_dirty(io_msInfo_8_bits_meta_dirty),
    .io_msInfo_8_bits_meta_state(io_msInfo_8_bits_meta_state),
    .io_msInfo_8_bits_meta_clients(io_msInfo_8_bits_meta_clients),
    .io_msInfo_8_bits_meta_alias(io_msInfo_8_bits_meta_alias),
    .io_msInfo_8_bits_meta_prefetch(io_msInfo_8_bits_meta_prefetch),
    .io_msInfo_8_bits_meta_prefetchSrc(io_msInfo_8_bits_meta_prefetchSrc),
    .io_msInfo_8_bits_meta_accessed(io_msInfo_8_bits_meta_accessed),
    .io_msInfo_8_bits_meta_tagErr(io_msInfo_8_bits_meta_tagErr),
    .io_msInfo_8_bits_meta_dataErr(io_msInfo_8_bits_meta_dataErr),
    .io_msInfo_8_bits_metaTag(io_msInfo_8_bits_metaTag),
    .io_msInfo_8_bits_dirHit(io_msInfo_8_bits_dirHit),
    .io_msInfo_8_bits_w_grantfirst(io_msInfo_8_bits_w_grantfirst),
    .io_msInfo_8_bits_s_release(io_msInfo_8_bits_s_release),
    .io_msInfo_8_bits_s_cmoresp(io_msInfo_8_bits_s_cmoresp),
    .io_msInfo_8_bits_s_cmometaw(io_msInfo_8_bits_s_cmometaw),
    .io_msInfo_8_bits_w_releaseack(io_msInfo_8_bits_w_releaseack),
    .io_msInfo_8_bits_w_replResp(io_msInfo_8_bits_w_replResp),
    .io_msInfo_8_bits_w_rprobeacklast(io_msInfo_8_bits_w_rprobeacklast),
    .io_msInfo_8_bits_replaceData(io_msInfo_8_bits_replaceData),
    .io_msInfo_8_bits_releaseToClean(io_msInfo_8_bits_releaseToClean),
    .io_msInfo_9_valid(io_msInfo_9_valid),
    .io_msInfo_9_bits_set(io_msInfo_9_bits_set),
    .io_msInfo_9_bits_reqTag(io_msInfo_9_bits_reqTag),
    .io_msInfo_9_bits_willFree(io_msInfo_9_bits_willFree),
    .io_msInfo_9_bits_aliasTask(io_msInfo_9_bits_aliasTask),
    .io_msInfo_9_bits_blockRefill(io_msInfo_9_bits_blockRefill),
    .io_msInfo_9_bits_meta_dirty(io_msInfo_9_bits_meta_dirty),
    .io_msInfo_9_bits_meta_state(io_msInfo_9_bits_meta_state),
    .io_msInfo_9_bits_meta_clients(io_msInfo_9_bits_meta_clients),
    .io_msInfo_9_bits_meta_alias(io_msInfo_9_bits_meta_alias),
    .io_msInfo_9_bits_meta_prefetch(io_msInfo_9_bits_meta_prefetch),
    .io_msInfo_9_bits_meta_prefetchSrc(io_msInfo_9_bits_meta_prefetchSrc),
    .io_msInfo_9_bits_meta_accessed(io_msInfo_9_bits_meta_accessed),
    .io_msInfo_9_bits_meta_tagErr(io_msInfo_9_bits_meta_tagErr),
    .io_msInfo_9_bits_meta_dataErr(io_msInfo_9_bits_meta_dataErr),
    .io_msInfo_9_bits_metaTag(io_msInfo_9_bits_metaTag),
    .io_msInfo_9_bits_dirHit(io_msInfo_9_bits_dirHit),
    .io_msInfo_9_bits_w_grantfirst(io_msInfo_9_bits_w_grantfirst),
    .io_msInfo_9_bits_s_release(io_msInfo_9_bits_s_release),
    .io_msInfo_9_bits_s_cmoresp(io_msInfo_9_bits_s_cmoresp),
    .io_msInfo_9_bits_s_cmometaw(io_msInfo_9_bits_s_cmometaw),
    .io_msInfo_9_bits_w_releaseack(io_msInfo_9_bits_w_releaseack),
    .io_msInfo_9_bits_w_replResp(io_msInfo_9_bits_w_replResp),
    .io_msInfo_9_bits_w_rprobeacklast(io_msInfo_9_bits_w_rprobeacklast),
    .io_msInfo_9_bits_replaceData(io_msInfo_9_bits_replaceData),
    .io_msInfo_9_bits_releaseToClean(io_msInfo_9_bits_releaseToClean),
    .io_msInfo_10_valid(io_msInfo_10_valid),
    .io_msInfo_10_bits_set(io_msInfo_10_bits_set),
    .io_msInfo_10_bits_reqTag(io_msInfo_10_bits_reqTag),
    .io_msInfo_10_bits_willFree(io_msInfo_10_bits_willFree),
    .io_msInfo_10_bits_aliasTask(io_msInfo_10_bits_aliasTask),
    .io_msInfo_10_bits_blockRefill(io_msInfo_10_bits_blockRefill),
    .io_msInfo_10_bits_meta_dirty(io_msInfo_10_bits_meta_dirty),
    .io_msInfo_10_bits_meta_state(io_msInfo_10_bits_meta_state),
    .io_msInfo_10_bits_meta_clients(io_msInfo_10_bits_meta_clients),
    .io_msInfo_10_bits_meta_alias(io_msInfo_10_bits_meta_alias),
    .io_msInfo_10_bits_meta_prefetch(io_msInfo_10_bits_meta_prefetch),
    .io_msInfo_10_bits_meta_prefetchSrc(io_msInfo_10_bits_meta_prefetchSrc),
    .io_msInfo_10_bits_meta_accessed(io_msInfo_10_bits_meta_accessed),
    .io_msInfo_10_bits_meta_tagErr(io_msInfo_10_bits_meta_tagErr),
    .io_msInfo_10_bits_meta_dataErr(io_msInfo_10_bits_meta_dataErr),
    .io_msInfo_10_bits_metaTag(io_msInfo_10_bits_metaTag),
    .io_msInfo_10_bits_dirHit(io_msInfo_10_bits_dirHit),
    .io_msInfo_10_bits_w_grantfirst(io_msInfo_10_bits_w_grantfirst),
    .io_msInfo_10_bits_s_release(io_msInfo_10_bits_s_release),
    .io_msInfo_10_bits_s_cmoresp(io_msInfo_10_bits_s_cmoresp),
    .io_msInfo_10_bits_s_cmometaw(io_msInfo_10_bits_s_cmometaw),
    .io_msInfo_10_bits_w_releaseack(io_msInfo_10_bits_w_releaseack),
    .io_msInfo_10_bits_w_replResp(io_msInfo_10_bits_w_replResp),
    .io_msInfo_10_bits_w_rprobeacklast(io_msInfo_10_bits_w_rprobeacklast),
    .io_msInfo_10_bits_replaceData(io_msInfo_10_bits_replaceData),
    .io_msInfo_10_bits_releaseToClean(io_msInfo_10_bits_releaseToClean),
    .io_msInfo_11_valid(io_msInfo_11_valid),
    .io_msInfo_11_bits_set(io_msInfo_11_bits_set),
    .io_msInfo_11_bits_reqTag(io_msInfo_11_bits_reqTag),
    .io_msInfo_11_bits_willFree(io_msInfo_11_bits_willFree),
    .io_msInfo_11_bits_aliasTask(io_msInfo_11_bits_aliasTask),
    .io_msInfo_11_bits_blockRefill(io_msInfo_11_bits_blockRefill),
    .io_msInfo_11_bits_meta_dirty(io_msInfo_11_bits_meta_dirty),
    .io_msInfo_11_bits_meta_state(io_msInfo_11_bits_meta_state),
    .io_msInfo_11_bits_meta_clients(io_msInfo_11_bits_meta_clients),
    .io_msInfo_11_bits_meta_alias(io_msInfo_11_bits_meta_alias),
    .io_msInfo_11_bits_meta_prefetch(io_msInfo_11_bits_meta_prefetch),
    .io_msInfo_11_bits_meta_prefetchSrc(io_msInfo_11_bits_meta_prefetchSrc),
    .io_msInfo_11_bits_meta_accessed(io_msInfo_11_bits_meta_accessed),
    .io_msInfo_11_bits_meta_tagErr(io_msInfo_11_bits_meta_tagErr),
    .io_msInfo_11_bits_meta_dataErr(io_msInfo_11_bits_meta_dataErr),
    .io_msInfo_11_bits_metaTag(io_msInfo_11_bits_metaTag),
    .io_msInfo_11_bits_dirHit(io_msInfo_11_bits_dirHit),
    .io_msInfo_11_bits_w_grantfirst(io_msInfo_11_bits_w_grantfirst),
    .io_msInfo_11_bits_s_release(io_msInfo_11_bits_s_release),
    .io_msInfo_11_bits_s_cmoresp(io_msInfo_11_bits_s_cmoresp),
    .io_msInfo_11_bits_s_cmometaw(io_msInfo_11_bits_s_cmometaw),
    .io_msInfo_11_bits_w_releaseack(io_msInfo_11_bits_w_releaseack),
    .io_msInfo_11_bits_w_replResp(io_msInfo_11_bits_w_replResp),
    .io_msInfo_11_bits_w_rprobeacklast(io_msInfo_11_bits_w_rprobeacklast),
    .io_msInfo_11_bits_replaceData(io_msInfo_11_bits_replaceData),
    .io_msInfo_11_bits_releaseToClean(io_msInfo_11_bits_releaseToClean),
    .io_msInfo_12_valid(io_msInfo_12_valid),
    .io_msInfo_12_bits_set(io_msInfo_12_bits_set),
    .io_msInfo_12_bits_reqTag(io_msInfo_12_bits_reqTag),
    .io_msInfo_12_bits_willFree(io_msInfo_12_bits_willFree),
    .io_msInfo_12_bits_aliasTask(io_msInfo_12_bits_aliasTask),
    .io_msInfo_12_bits_blockRefill(io_msInfo_12_bits_blockRefill),
    .io_msInfo_12_bits_meta_dirty(io_msInfo_12_bits_meta_dirty),
    .io_msInfo_12_bits_meta_state(io_msInfo_12_bits_meta_state),
    .io_msInfo_12_bits_meta_clients(io_msInfo_12_bits_meta_clients),
    .io_msInfo_12_bits_meta_alias(io_msInfo_12_bits_meta_alias),
    .io_msInfo_12_bits_meta_prefetch(io_msInfo_12_bits_meta_prefetch),
    .io_msInfo_12_bits_meta_prefetchSrc(io_msInfo_12_bits_meta_prefetchSrc),
    .io_msInfo_12_bits_meta_accessed(io_msInfo_12_bits_meta_accessed),
    .io_msInfo_12_bits_meta_tagErr(io_msInfo_12_bits_meta_tagErr),
    .io_msInfo_12_bits_meta_dataErr(io_msInfo_12_bits_meta_dataErr),
    .io_msInfo_12_bits_metaTag(io_msInfo_12_bits_metaTag),
    .io_msInfo_12_bits_dirHit(io_msInfo_12_bits_dirHit),
    .io_msInfo_12_bits_w_grantfirst(io_msInfo_12_bits_w_grantfirst),
    .io_msInfo_12_bits_s_release(io_msInfo_12_bits_s_release),
    .io_msInfo_12_bits_s_cmoresp(io_msInfo_12_bits_s_cmoresp),
    .io_msInfo_12_bits_s_cmometaw(io_msInfo_12_bits_s_cmometaw),
    .io_msInfo_12_bits_w_releaseack(io_msInfo_12_bits_w_releaseack),
    .io_msInfo_12_bits_w_replResp(io_msInfo_12_bits_w_replResp),
    .io_msInfo_12_bits_w_rprobeacklast(io_msInfo_12_bits_w_rprobeacklast),
    .io_msInfo_12_bits_replaceData(io_msInfo_12_bits_replaceData),
    .io_msInfo_12_bits_releaseToClean(io_msInfo_12_bits_releaseToClean),
    .io_msInfo_13_valid(io_msInfo_13_valid),
    .io_msInfo_13_bits_set(io_msInfo_13_bits_set),
    .io_msInfo_13_bits_reqTag(io_msInfo_13_bits_reqTag),
    .io_msInfo_13_bits_willFree(io_msInfo_13_bits_willFree),
    .io_msInfo_13_bits_aliasTask(io_msInfo_13_bits_aliasTask),
    .io_msInfo_13_bits_blockRefill(io_msInfo_13_bits_blockRefill),
    .io_msInfo_13_bits_meta_dirty(io_msInfo_13_bits_meta_dirty),
    .io_msInfo_13_bits_meta_state(io_msInfo_13_bits_meta_state),
    .io_msInfo_13_bits_meta_clients(io_msInfo_13_bits_meta_clients),
    .io_msInfo_13_bits_meta_alias(io_msInfo_13_bits_meta_alias),
    .io_msInfo_13_bits_meta_prefetch(io_msInfo_13_bits_meta_prefetch),
    .io_msInfo_13_bits_meta_prefetchSrc(io_msInfo_13_bits_meta_prefetchSrc),
    .io_msInfo_13_bits_meta_accessed(io_msInfo_13_bits_meta_accessed),
    .io_msInfo_13_bits_meta_tagErr(io_msInfo_13_bits_meta_tagErr),
    .io_msInfo_13_bits_meta_dataErr(io_msInfo_13_bits_meta_dataErr),
    .io_msInfo_13_bits_metaTag(io_msInfo_13_bits_metaTag),
    .io_msInfo_13_bits_dirHit(io_msInfo_13_bits_dirHit),
    .io_msInfo_13_bits_w_grantfirst(io_msInfo_13_bits_w_grantfirst),
    .io_msInfo_13_bits_s_release(io_msInfo_13_bits_s_release),
    .io_msInfo_13_bits_s_cmoresp(io_msInfo_13_bits_s_cmoresp),
    .io_msInfo_13_bits_s_cmometaw(io_msInfo_13_bits_s_cmometaw),
    .io_msInfo_13_bits_w_releaseack(io_msInfo_13_bits_w_releaseack),
    .io_msInfo_13_bits_w_replResp(io_msInfo_13_bits_w_replResp),
    .io_msInfo_13_bits_w_rprobeacklast(io_msInfo_13_bits_w_rprobeacklast),
    .io_msInfo_13_bits_replaceData(io_msInfo_13_bits_replaceData),
    .io_msInfo_13_bits_releaseToClean(io_msInfo_13_bits_releaseToClean),
    .io_msInfo_14_valid(io_msInfo_14_valid),
    .io_msInfo_14_bits_set(io_msInfo_14_bits_set),
    .io_msInfo_14_bits_reqTag(io_msInfo_14_bits_reqTag),
    .io_msInfo_14_bits_willFree(io_msInfo_14_bits_willFree),
    .io_msInfo_14_bits_aliasTask(io_msInfo_14_bits_aliasTask),
    .io_msInfo_14_bits_blockRefill(io_msInfo_14_bits_blockRefill),
    .io_msInfo_14_bits_meta_dirty(io_msInfo_14_bits_meta_dirty),
    .io_msInfo_14_bits_meta_state(io_msInfo_14_bits_meta_state),
    .io_msInfo_14_bits_meta_clients(io_msInfo_14_bits_meta_clients),
    .io_msInfo_14_bits_meta_alias(io_msInfo_14_bits_meta_alias),
    .io_msInfo_14_bits_meta_prefetch(io_msInfo_14_bits_meta_prefetch),
    .io_msInfo_14_bits_meta_prefetchSrc(io_msInfo_14_bits_meta_prefetchSrc),
    .io_msInfo_14_bits_meta_accessed(io_msInfo_14_bits_meta_accessed),
    .io_msInfo_14_bits_meta_tagErr(io_msInfo_14_bits_meta_tagErr),
    .io_msInfo_14_bits_meta_dataErr(io_msInfo_14_bits_meta_dataErr),
    .io_msInfo_14_bits_metaTag(io_msInfo_14_bits_metaTag),
    .io_msInfo_14_bits_dirHit(io_msInfo_14_bits_dirHit),
    .io_msInfo_14_bits_w_grantfirst(io_msInfo_14_bits_w_grantfirst),
    .io_msInfo_14_bits_s_release(io_msInfo_14_bits_s_release),
    .io_msInfo_14_bits_s_cmoresp(io_msInfo_14_bits_s_cmoresp),
    .io_msInfo_14_bits_s_cmometaw(io_msInfo_14_bits_s_cmometaw),
    .io_msInfo_14_bits_w_releaseack(io_msInfo_14_bits_w_releaseack),
    .io_msInfo_14_bits_w_replResp(io_msInfo_14_bits_w_replResp),
    .io_msInfo_14_bits_w_rprobeacklast(io_msInfo_14_bits_w_rprobeacklast),
    .io_msInfo_14_bits_replaceData(io_msInfo_14_bits_replaceData),
    .io_msInfo_14_bits_releaseToClean(io_msInfo_14_bits_releaseToClean),
    .io_msInfo_15_valid(io_msInfo_15_valid),
    .io_msInfo_15_bits_set(io_msInfo_15_bits_set),
    .io_msInfo_15_bits_reqTag(io_msInfo_15_bits_reqTag),
    .io_msInfo_15_bits_willFree(io_msInfo_15_bits_willFree),
    .io_msInfo_15_bits_aliasTask(io_msInfo_15_bits_aliasTask),
    .io_msInfo_15_bits_blockRefill(io_msInfo_15_bits_blockRefill),
    .io_msInfo_15_bits_meta_dirty(io_msInfo_15_bits_meta_dirty),
    .io_msInfo_15_bits_meta_state(io_msInfo_15_bits_meta_state),
    .io_msInfo_15_bits_meta_clients(io_msInfo_15_bits_meta_clients),
    .io_msInfo_15_bits_meta_alias(io_msInfo_15_bits_meta_alias),
    .io_msInfo_15_bits_meta_prefetch(io_msInfo_15_bits_meta_prefetch),
    .io_msInfo_15_bits_meta_prefetchSrc(io_msInfo_15_bits_meta_prefetchSrc),
    .io_msInfo_15_bits_meta_accessed(io_msInfo_15_bits_meta_accessed),
    .io_msInfo_15_bits_meta_tagErr(io_msInfo_15_bits_meta_tagErr),
    .io_msInfo_15_bits_meta_dataErr(io_msInfo_15_bits_meta_dataErr),
    .io_msInfo_15_bits_metaTag(io_msInfo_15_bits_metaTag),
    .io_msInfo_15_bits_dirHit(io_msInfo_15_bits_dirHit),
    .io_msInfo_15_bits_w_grantfirst(io_msInfo_15_bits_w_grantfirst),
    .io_msInfo_15_bits_s_release(io_msInfo_15_bits_s_release),
    .io_msInfo_15_bits_s_cmoresp(io_msInfo_15_bits_s_cmoresp),
    .io_msInfo_15_bits_s_cmometaw(io_msInfo_15_bits_s_cmometaw),
    .io_msInfo_15_bits_w_releaseack(io_msInfo_15_bits_w_releaseack),
    .io_msInfo_15_bits_w_replResp(io_msInfo_15_bits_w_replResp),
    .io_msInfo_15_bits_w_rprobeacklast(io_msInfo_15_bits_w_rprobeacklast),
    .io_msInfo_15_bits_replaceData(io_msInfo_15_bits_replaceData),
    .io_msInfo_15_bits_releaseToClean(io_msInfo_15_bits_releaseToClean)
  );
  RXSNP_xs u_i (
    .clock(clock),
    .reset(reset),
    .io_rxsnp_ready(i_io_rxsnp_ready),
    .io_rxsnp_valid(io_rxsnp_valid),
    .io_rxsnp_bits_qos(io_rxsnp_bits_qos),
    .io_rxsnp_bits_srcID(io_rxsnp_bits_srcID),
    .io_rxsnp_bits_txnID(io_rxsnp_bits_txnID),
    .io_rxsnp_bits_fwdNID(io_rxsnp_bits_fwdNID),
    .io_rxsnp_bits_fwdTxnID(io_rxsnp_bits_fwdTxnID),
    .io_rxsnp_bits_opcode(io_rxsnp_bits_opcode),
    .io_rxsnp_bits_addr(io_rxsnp_bits_addr),
    .io_rxsnp_bits_ns(io_rxsnp_bits_ns),
    .io_rxsnp_bits_doNotGoToSD(io_rxsnp_bits_doNotGoToSD),
    .io_rxsnp_bits_retToSrc(io_rxsnp_bits_retToSrc),
    .io_rxsnp_bits_traceTag(io_rxsnp_bits_traceTag),
    .io_rxsnp_bits_mpam_perfMonGroup(io_rxsnp_bits_mpam_perfMonGroup),
    .io_rxsnp_bits_mpam_partID(io_rxsnp_bits_mpam_partID),
    .io_rxsnp_bits_mpam_mpamNS(io_rxsnp_bits_mpam_mpamNS),
    .io_task_ready(io_task_ready),
    .io_task_valid(i_io_task_valid),
    .io_task_bits_set(i_io_task_bits_set),
    .io_task_bits_tag(i_io_task_bits_tag),
    .io_task_bits_off(i_io_task_bits_off),
    .io_task_bits_snpHitRelease(i_io_task_bits_snpHitRelease),
    .io_task_bits_snpHitReleaseToInval(i_io_task_bits_snpHitReleaseToInval),
    .io_task_bits_snpHitReleaseToClean(i_io_task_bits_snpHitReleaseToClean),
    .io_task_bits_snpHitReleaseWithData(i_io_task_bits_snpHitReleaseWithData),
    .io_task_bits_snpHitReleaseIdx(i_io_task_bits_snpHitReleaseIdx),
    .io_task_bits_snpHitReleaseMeta_dirty(i_io_task_bits_snpHitReleaseMeta_dirty),
    .io_task_bits_snpHitReleaseMeta_state(i_io_task_bits_snpHitReleaseMeta_state),
    .io_task_bits_snpHitReleaseMeta_clients(i_io_task_bits_snpHitReleaseMeta_clients),
    .io_task_bits_snpHitReleaseMeta_alias(i_io_task_bits_snpHitReleaseMeta_alias),
    .io_task_bits_snpHitReleaseMeta_prefetch(i_io_task_bits_snpHitReleaseMeta_prefetch),
    .io_task_bits_snpHitReleaseMeta_prefetchSrc(i_io_task_bits_snpHitReleaseMeta_prefetchSrc),
    .io_task_bits_snpHitReleaseMeta_accessed(i_io_task_bits_snpHitReleaseMeta_accessed),
    .io_task_bits_snpHitReleaseMeta_tagErr(i_io_task_bits_snpHitReleaseMeta_tagErr),
    .io_task_bits_snpHitReleaseMeta_dataErr(i_io_task_bits_snpHitReleaseMeta_dataErr),
    .io_task_bits_srcID(i_io_task_bits_srcID),
    .io_task_bits_txnID(i_io_task_bits_txnID),
    .io_task_bits_fwdNID(i_io_task_bits_fwdNID),
    .io_task_bits_fwdTxnID(i_io_task_bits_fwdTxnID),
    .io_task_bits_chiOpcode(i_io_task_bits_chiOpcode),
    .io_task_bits_retToSrc(i_io_task_bits_retToSrc),
    .io_task_bits_traceTag(i_io_task_bits_traceTag),
    .io_msInfo_0_valid(io_msInfo_0_valid),
    .io_msInfo_0_bits_set(io_msInfo_0_bits_set),
    .io_msInfo_0_bits_reqTag(io_msInfo_0_bits_reqTag),
    .io_msInfo_0_bits_willFree(io_msInfo_0_bits_willFree),
    .io_msInfo_0_bits_aliasTask(io_msInfo_0_bits_aliasTask),
    .io_msInfo_0_bits_blockRefill(io_msInfo_0_bits_blockRefill),
    .io_msInfo_0_bits_meta_dirty(io_msInfo_0_bits_meta_dirty),
    .io_msInfo_0_bits_meta_state(io_msInfo_0_bits_meta_state),
    .io_msInfo_0_bits_meta_clients(io_msInfo_0_bits_meta_clients),
    .io_msInfo_0_bits_meta_alias(io_msInfo_0_bits_meta_alias),
    .io_msInfo_0_bits_meta_prefetch(io_msInfo_0_bits_meta_prefetch),
    .io_msInfo_0_bits_meta_prefetchSrc(io_msInfo_0_bits_meta_prefetchSrc),
    .io_msInfo_0_bits_meta_accessed(io_msInfo_0_bits_meta_accessed),
    .io_msInfo_0_bits_meta_tagErr(io_msInfo_0_bits_meta_tagErr),
    .io_msInfo_0_bits_meta_dataErr(io_msInfo_0_bits_meta_dataErr),
    .io_msInfo_0_bits_metaTag(io_msInfo_0_bits_metaTag),
    .io_msInfo_0_bits_dirHit(io_msInfo_0_bits_dirHit),
    .io_msInfo_0_bits_w_grantfirst(io_msInfo_0_bits_w_grantfirst),
    .io_msInfo_0_bits_s_release(io_msInfo_0_bits_s_release),
    .io_msInfo_0_bits_s_cmoresp(io_msInfo_0_bits_s_cmoresp),
    .io_msInfo_0_bits_s_cmometaw(io_msInfo_0_bits_s_cmometaw),
    .io_msInfo_0_bits_w_releaseack(io_msInfo_0_bits_w_releaseack),
    .io_msInfo_0_bits_w_replResp(io_msInfo_0_bits_w_replResp),
    .io_msInfo_0_bits_w_rprobeacklast(io_msInfo_0_bits_w_rprobeacklast),
    .io_msInfo_0_bits_replaceData(io_msInfo_0_bits_replaceData),
    .io_msInfo_0_bits_releaseToClean(io_msInfo_0_bits_releaseToClean),
    .io_msInfo_1_valid(io_msInfo_1_valid),
    .io_msInfo_1_bits_set(io_msInfo_1_bits_set),
    .io_msInfo_1_bits_reqTag(io_msInfo_1_bits_reqTag),
    .io_msInfo_1_bits_willFree(io_msInfo_1_bits_willFree),
    .io_msInfo_1_bits_aliasTask(io_msInfo_1_bits_aliasTask),
    .io_msInfo_1_bits_blockRefill(io_msInfo_1_bits_blockRefill),
    .io_msInfo_1_bits_meta_dirty(io_msInfo_1_bits_meta_dirty),
    .io_msInfo_1_bits_meta_state(io_msInfo_1_bits_meta_state),
    .io_msInfo_1_bits_meta_clients(io_msInfo_1_bits_meta_clients),
    .io_msInfo_1_bits_meta_alias(io_msInfo_1_bits_meta_alias),
    .io_msInfo_1_bits_meta_prefetch(io_msInfo_1_bits_meta_prefetch),
    .io_msInfo_1_bits_meta_prefetchSrc(io_msInfo_1_bits_meta_prefetchSrc),
    .io_msInfo_1_bits_meta_accessed(io_msInfo_1_bits_meta_accessed),
    .io_msInfo_1_bits_meta_tagErr(io_msInfo_1_bits_meta_tagErr),
    .io_msInfo_1_bits_meta_dataErr(io_msInfo_1_bits_meta_dataErr),
    .io_msInfo_1_bits_metaTag(io_msInfo_1_bits_metaTag),
    .io_msInfo_1_bits_dirHit(io_msInfo_1_bits_dirHit),
    .io_msInfo_1_bits_w_grantfirst(io_msInfo_1_bits_w_grantfirst),
    .io_msInfo_1_bits_s_release(io_msInfo_1_bits_s_release),
    .io_msInfo_1_bits_s_cmoresp(io_msInfo_1_bits_s_cmoresp),
    .io_msInfo_1_bits_s_cmometaw(io_msInfo_1_bits_s_cmometaw),
    .io_msInfo_1_bits_w_releaseack(io_msInfo_1_bits_w_releaseack),
    .io_msInfo_1_bits_w_replResp(io_msInfo_1_bits_w_replResp),
    .io_msInfo_1_bits_w_rprobeacklast(io_msInfo_1_bits_w_rprobeacklast),
    .io_msInfo_1_bits_replaceData(io_msInfo_1_bits_replaceData),
    .io_msInfo_1_bits_releaseToClean(io_msInfo_1_bits_releaseToClean),
    .io_msInfo_2_valid(io_msInfo_2_valid),
    .io_msInfo_2_bits_set(io_msInfo_2_bits_set),
    .io_msInfo_2_bits_reqTag(io_msInfo_2_bits_reqTag),
    .io_msInfo_2_bits_willFree(io_msInfo_2_bits_willFree),
    .io_msInfo_2_bits_aliasTask(io_msInfo_2_bits_aliasTask),
    .io_msInfo_2_bits_blockRefill(io_msInfo_2_bits_blockRefill),
    .io_msInfo_2_bits_meta_dirty(io_msInfo_2_bits_meta_dirty),
    .io_msInfo_2_bits_meta_state(io_msInfo_2_bits_meta_state),
    .io_msInfo_2_bits_meta_clients(io_msInfo_2_bits_meta_clients),
    .io_msInfo_2_bits_meta_alias(io_msInfo_2_bits_meta_alias),
    .io_msInfo_2_bits_meta_prefetch(io_msInfo_2_bits_meta_prefetch),
    .io_msInfo_2_bits_meta_prefetchSrc(io_msInfo_2_bits_meta_prefetchSrc),
    .io_msInfo_2_bits_meta_accessed(io_msInfo_2_bits_meta_accessed),
    .io_msInfo_2_bits_meta_tagErr(io_msInfo_2_bits_meta_tagErr),
    .io_msInfo_2_bits_meta_dataErr(io_msInfo_2_bits_meta_dataErr),
    .io_msInfo_2_bits_metaTag(io_msInfo_2_bits_metaTag),
    .io_msInfo_2_bits_dirHit(io_msInfo_2_bits_dirHit),
    .io_msInfo_2_bits_w_grantfirst(io_msInfo_2_bits_w_grantfirst),
    .io_msInfo_2_bits_s_release(io_msInfo_2_bits_s_release),
    .io_msInfo_2_bits_s_cmoresp(io_msInfo_2_bits_s_cmoresp),
    .io_msInfo_2_bits_s_cmometaw(io_msInfo_2_bits_s_cmometaw),
    .io_msInfo_2_bits_w_releaseack(io_msInfo_2_bits_w_releaseack),
    .io_msInfo_2_bits_w_replResp(io_msInfo_2_bits_w_replResp),
    .io_msInfo_2_bits_w_rprobeacklast(io_msInfo_2_bits_w_rprobeacklast),
    .io_msInfo_2_bits_replaceData(io_msInfo_2_bits_replaceData),
    .io_msInfo_2_bits_releaseToClean(io_msInfo_2_bits_releaseToClean),
    .io_msInfo_3_valid(io_msInfo_3_valid),
    .io_msInfo_3_bits_set(io_msInfo_3_bits_set),
    .io_msInfo_3_bits_reqTag(io_msInfo_3_bits_reqTag),
    .io_msInfo_3_bits_willFree(io_msInfo_3_bits_willFree),
    .io_msInfo_3_bits_aliasTask(io_msInfo_3_bits_aliasTask),
    .io_msInfo_3_bits_blockRefill(io_msInfo_3_bits_blockRefill),
    .io_msInfo_3_bits_meta_dirty(io_msInfo_3_bits_meta_dirty),
    .io_msInfo_3_bits_meta_state(io_msInfo_3_bits_meta_state),
    .io_msInfo_3_bits_meta_clients(io_msInfo_3_bits_meta_clients),
    .io_msInfo_3_bits_meta_alias(io_msInfo_3_bits_meta_alias),
    .io_msInfo_3_bits_meta_prefetch(io_msInfo_3_bits_meta_prefetch),
    .io_msInfo_3_bits_meta_prefetchSrc(io_msInfo_3_bits_meta_prefetchSrc),
    .io_msInfo_3_bits_meta_accessed(io_msInfo_3_bits_meta_accessed),
    .io_msInfo_3_bits_meta_tagErr(io_msInfo_3_bits_meta_tagErr),
    .io_msInfo_3_bits_meta_dataErr(io_msInfo_3_bits_meta_dataErr),
    .io_msInfo_3_bits_metaTag(io_msInfo_3_bits_metaTag),
    .io_msInfo_3_bits_dirHit(io_msInfo_3_bits_dirHit),
    .io_msInfo_3_bits_w_grantfirst(io_msInfo_3_bits_w_grantfirst),
    .io_msInfo_3_bits_s_release(io_msInfo_3_bits_s_release),
    .io_msInfo_3_bits_s_cmoresp(io_msInfo_3_bits_s_cmoresp),
    .io_msInfo_3_bits_s_cmometaw(io_msInfo_3_bits_s_cmometaw),
    .io_msInfo_3_bits_w_releaseack(io_msInfo_3_bits_w_releaseack),
    .io_msInfo_3_bits_w_replResp(io_msInfo_3_bits_w_replResp),
    .io_msInfo_3_bits_w_rprobeacklast(io_msInfo_3_bits_w_rprobeacklast),
    .io_msInfo_3_bits_replaceData(io_msInfo_3_bits_replaceData),
    .io_msInfo_3_bits_releaseToClean(io_msInfo_3_bits_releaseToClean),
    .io_msInfo_4_valid(io_msInfo_4_valid),
    .io_msInfo_4_bits_set(io_msInfo_4_bits_set),
    .io_msInfo_4_bits_reqTag(io_msInfo_4_bits_reqTag),
    .io_msInfo_4_bits_willFree(io_msInfo_4_bits_willFree),
    .io_msInfo_4_bits_aliasTask(io_msInfo_4_bits_aliasTask),
    .io_msInfo_4_bits_blockRefill(io_msInfo_4_bits_blockRefill),
    .io_msInfo_4_bits_meta_dirty(io_msInfo_4_bits_meta_dirty),
    .io_msInfo_4_bits_meta_state(io_msInfo_4_bits_meta_state),
    .io_msInfo_4_bits_meta_clients(io_msInfo_4_bits_meta_clients),
    .io_msInfo_4_bits_meta_alias(io_msInfo_4_bits_meta_alias),
    .io_msInfo_4_bits_meta_prefetch(io_msInfo_4_bits_meta_prefetch),
    .io_msInfo_4_bits_meta_prefetchSrc(io_msInfo_4_bits_meta_prefetchSrc),
    .io_msInfo_4_bits_meta_accessed(io_msInfo_4_bits_meta_accessed),
    .io_msInfo_4_bits_meta_tagErr(io_msInfo_4_bits_meta_tagErr),
    .io_msInfo_4_bits_meta_dataErr(io_msInfo_4_bits_meta_dataErr),
    .io_msInfo_4_bits_metaTag(io_msInfo_4_bits_metaTag),
    .io_msInfo_4_bits_dirHit(io_msInfo_4_bits_dirHit),
    .io_msInfo_4_bits_w_grantfirst(io_msInfo_4_bits_w_grantfirst),
    .io_msInfo_4_bits_s_release(io_msInfo_4_bits_s_release),
    .io_msInfo_4_bits_s_cmoresp(io_msInfo_4_bits_s_cmoresp),
    .io_msInfo_4_bits_s_cmometaw(io_msInfo_4_bits_s_cmometaw),
    .io_msInfo_4_bits_w_releaseack(io_msInfo_4_bits_w_releaseack),
    .io_msInfo_4_bits_w_replResp(io_msInfo_4_bits_w_replResp),
    .io_msInfo_4_bits_w_rprobeacklast(io_msInfo_4_bits_w_rprobeacklast),
    .io_msInfo_4_bits_replaceData(io_msInfo_4_bits_replaceData),
    .io_msInfo_4_bits_releaseToClean(io_msInfo_4_bits_releaseToClean),
    .io_msInfo_5_valid(io_msInfo_5_valid),
    .io_msInfo_5_bits_set(io_msInfo_5_bits_set),
    .io_msInfo_5_bits_reqTag(io_msInfo_5_bits_reqTag),
    .io_msInfo_5_bits_willFree(io_msInfo_5_bits_willFree),
    .io_msInfo_5_bits_aliasTask(io_msInfo_5_bits_aliasTask),
    .io_msInfo_5_bits_blockRefill(io_msInfo_5_bits_blockRefill),
    .io_msInfo_5_bits_meta_dirty(io_msInfo_5_bits_meta_dirty),
    .io_msInfo_5_bits_meta_state(io_msInfo_5_bits_meta_state),
    .io_msInfo_5_bits_meta_clients(io_msInfo_5_bits_meta_clients),
    .io_msInfo_5_bits_meta_alias(io_msInfo_5_bits_meta_alias),
    .io_msInfo_5_bits_meta_prefetch(io_msInfo_5_bits_meta_prefetch),
    .io_msInfo_5_bits_meta_prefetchSrc(io_msInfo_5_bits_meta_prefetchSrc),
    .io_msInfo_5_bits_meta_accessed(io_msInfo_5_bits_meta_accessed),
    .io_msInfo_5_bits_meta_tagErr(io_msInfo_5_bits_meta_tagErr),
    .io_msInfo_5_bits_meta_dataErr(io_msInfo_5_bits_meta_dataErr),
    .io_msInfo_5_bits_metaTag(io_msInfo_5_bits_metaTag),
    .io_msInfo_5_bits_dirHit(io_msInfo_5_bits_dirHit),
    .io_msInfo_5_bits_w_grantfirst(io_msInfo_5_bits_w_grantfirst),
    .io_msInfo_5_bits_s_release(io_msInfo_5_bits_s_release),
    .io_msInfo_5_bits_s_cmoresp(io_msInfo_5_bits_s_cmoresp),
    .io_msInfo_5_bits_s_cmometaw(io_msInfo_5_bits_s_cmometaw),
    .io_msInfo_5_bits_w_releaseack(io_msInfo_5_bits_w_releaseack),
    .io_msInfo_5_bits_w_replResp(io_msInfo_5_bits_w_replResp),
    .io_msInfo_5_bits_w_rprobeacklast(io_msInfo_5_bits_w_rprobeacklast),
    .io_msInfo_5_bits_replaceData(io_msInfo_5_bits_replaceData),
    .io_msInfo_5_bits_releaseToClean(io_msInfo_5_bits_releaseToClean),
    .io_msInfo_6_valid(io_msInfo_6_valid),
    .io_msInfo_6_bits_set(io_msInfo_6_bits_set),
    .io_msInfo_6_bits_reqTag(io_msInfo_6_bits_reqTag),
    .io_msInfo_6_bits_willFree(io_msInfo_6_bits_willFree),
    .io_msInfo_6_bits_aliasTask(io_msInfo_6_bits_aliasTask),
    .io_msInfo_6_bits_blockRefill(io_msInfo_6_bits_blockRefill),
    .io_msInfo_6_bits_meta_dirty(io_msInfo_6_bits_meta_dirty),
    .io_msInfo_6_bits_meta_state(io_msInfo_6_bits_meta_state),
    .io_msInfo_6_bits_meta_clients(io_msInfo_6_bits_meta_clients),
    .io_msInfo_6_bits_meta_alias(io_msInfo_6_bits_meta_alias),
    .io_msInfo_6_bits_meta_prefetch(io_msInfo_6_bits_meta_prefetch),
    .io_msInfo_6_bits_meta_prefetchSrc(io_msInfo_6_bits_meta_prefetchSrc),
    .io_msInfo_6_bits_meta_accessed(io_msInfo_6_bits_meta_accessed),
    .io_msInfo_6_bits_meta_tagErr(io_msInfo_6_bits_meta_tagErr),
    .io_msInfo_6_bits_meta_dataErr(io_msInfo_6_bits_meta_dataErr),
    .io_msInfo_6_bits_metaTag(io_msInfo_6_bits_metaTag),
    .io_msInfo_6_bits_dirHit(io_msInfo_6_bits_dirHit),
    .io_msInfo_6_bits_w_grantfirst(io_msInfo_6_bits_w_grantfirst),
    .io_msInfo_6_bits_s_release(io_msInfo_6_bits_s_release),
    .io_msInfo_6_bits_s_cmoresp(io_msInfo_6_bits_s_cmoresp),
    .io_msInfo_6_bits_s_cmometaw(io_msInfo_6_bits_s_cmometaw),
    .io_msInfo_6_bits_w_releaseack(io_msInfo_6_bits_w_releaseack),
    .io_msInfo_6_bits_w_replResp(io_msInfo_6_bits_w_replResp),
    .io_msInfo_6_bits_w_rprobeacklast(io_msInfo_6_bits_w_rprobeacklast),
    .io_msInfo_6_bits_replaceData(io_msInfo_6_bits_replaceData),
    .io_msInfo_6_bits_releaseToClean(io_msInfo_6_bits_releaseToClean),
    .io_msInfo_7_valid(io_msInfo_7_valid),
    .io_msInfo_7_bits_set(io_msInfo_7_bits_set),
    .io_msInfo_7_bits_reqTag(io_msInfo_7_bits_reqTag),
    .io_msInfo_7_bits_willFree(io_msInfo_7_bits_willFree),
    .io_msInfo_7_bits_aliasTask(io_msInfo_7_bits_aliasTask),
    .io_msInfo_7_bits_blockRefill(io_msInfo_7_bits_blockRefill),
    .io_msInfo_7_bits_meta_dirty(io_msInfo_7_bits_meta_dirty),
    .io_msInfo_7_bits_meta_state(io_msInfo_7_bits_meta_state),
    .io_msInfo_7_bits_meta_clients(io_msInfo_7_bits_meta_clients),
    .io_msInfo_7_bits_meta_alias(io_msInfo_7_bits_meta_alias),
    .io_msInfo_7_bits_meta_prefetch(io_msInfo_7_bits_meta_prefetch),
    .io_msInfo_7_bits_meta_prefetchSrc(io_msInfo_7_bits_meta_prefetchSrc),
    .io_msInfo_7_bits_meta_accessed(io_msInfo_7_bits_meta_accessed),
    .io_msInfo_7_bits_meta_tagErr(io_msInfo_7_bits_meta_tagErr),
    .io_msInfo_7_bits_meta_dataErr(io_msInfo_7_bits_meta_dataErr),
    .io_msInfo_7_bits_metaTag(io_msInfo_7_bits_metaTag),
    .io_msInfo_7_bits_dirHit(io_msInfo_7_bits_dirHit),
    .io_msInfo_7_bits_w_grantfirst(io_msInfo_7_bits_w_grantfirst),
    .io_msInfo_7_bits_s_release(io_msInfo_7_bits_s_release),
    .io_msInfo_7_bits_s_cmoresp(io_msInfo_7_bits_s_cmoresp),
    .io_msInfo_7_bits_s_cmometaw(io_msInfo_7_bits_s_cmometaw),
    .io_msInfo_7_bits_w_releaseack(io_msInfo_7_bits_w_releaseack),
    .io_msInfo_7_bits_w_replResp(io_msInfo_7_bits_w_replResp),
    .io_msInfo_7_bits_w_rprobeacklast(io_msInfo_7_bits_w_rprobeacklast),
    .io_msInfo_7_bits_replaceData(io_msInfo_7_bits_replaceData),
    .io_msInfo_7_bits_releaseToClean(io_msInfo_7_bits_releaseToClean),
    .io_msInfo_8_valid(io_msInfo_8_valid),
    .io_msInfo_8_bits_set(io_msInfo_8_bits_set),
    .io_msInfo_8_bits_reqTag(io_msInfo_8_bits_reqTag),
    .io_msInfo_8_bits_willFree(io_msInfo_8_bits_willFree),
    .io_msInfo_8_bits_aliasTask(io_msInfo_8_bits_aliasTask),
    .io_msInfo_8_bits_blockRefill(io_msInfo_8_bits_blockRefill),
    .io_msInfo_8_bits_meta_dirty(io_msInfo_8_bits_meta_dirty),
    .io_msInfo_8_bits_meta_state(io_msInfo_8_bits_meta_state),
    .io_msInfo_8_bits_meta_clients(io_msInfo_8_bits_meta_clients),
    .io_msInfo_8_bits_meta_alias(io_msInfo_8_bits_meta_alias),
    .io_msInfo_8_bits_meta_prefetch(io_msInfo_8_bits_meta_prefetch),
    .io_msInfo_8_bits_meta_prefetchSrc(io_msInfo_8_bits_meta_prefetchSrc),
    .io_msInfo_8_bits_meta_accessed(io_msInfo_8_bits_meta_accessed),
    .io_msInfo_8_bits_meta_tagErr(io_msInfo_8_bits_meta_tagErr),
    .io_msInfo_8_bits_meta_dataErr(io_msInfo_8_bits_meta_dataErr),
    .io_msInfo_8_bits_metaTag(io_msInfo_8_bits_metaTag),
    .io_msInfo_8_bits_dirHit(io_msInfo_8_bits_dirHit),
    .io_msInfo_8_bits_w_grantfirst(io_msInfo_8_bits_w_grantfirst),
    .io_msInfo_8_bits_s_release(io_msInfo_8_bits_s_release),
    .io_msInfo_8_bits_s_cmoresp(io_msInfo_8_bits_s_cmoresp),
    .io_msInfo_8_bits_s_cmometaw(io_msInfo_8_bits_s_cmometaw),
    .io_msInfo_8_bits_w_releaseack(io_msInfo_8_bits_w_releaseack),
    .io_msInfo_8_bits_w_replResp(io_msInfo_8_bits_w_replResp),
    .io_msInfo_8_bits_w_rprobeacklast(io_msInfo_8_bits_w_rprobeacklast),
    .io_msInfo_8_bits_replaceData(io_msInfo_8_bits_replaceData),
    .io_msInfo_8_bits_releaseToClean(io_msInfo_8_bits_releaseToClean),
    .io_msInfo_9_valid(io_msInfo_9_valid),
    .io_msInfo_9_bits_set(io_msInfo_9_bits_set),
    .io_msInfo_9_bits_reqTag(io_msInfo_9_bits_reqTag),
    .io_msInfo_9_bits_willFree(io_msInfo_9_bits_willFree),
    .io_msInfo_9_bits_aliasTask(io_msInfo_9_bits_aliasTask),
    .io_msInfo_9_bits_blockRefill(io_msInfo_9_bits_blockRefill),
    .io_msInfo_9_bits_meta_dirty(io_msInfo_9_bits_meta_dirty),
    .io_msInfo_9_bits_meta_state(io_msInfo_9_bits_meta_state),
    .io_msInfo_9_bits_meta_clients(io_msInfo_9_bits_meta_clients),
    .io_msInfo_9_bits_meta_alias(io_msInfo_9_bits_meta_alias),
    .io_msInfo_9_bits_meta_prefetch(io_msInfo_9_bits_meta_prefetch),
    .io_msInfo_9_bits_meta_prefetchSrc(io_msInfo_9_bits_meta_prefetchSrc),
    .io_msInfo_9_bits_meta_accessed(io_msInfo_9_bits_meta_accessed),
    .io_msInfo_9_bits_meta_tagErr(io_msInfo_9_bits_meta_tagErr),
    .io_msInfo_9_bits_meta_dataErr(io_msInfo_9_bits_meta_dataErr),
    .io_msInfo_9_bits_metaTag(io_msInfo_9_bits_metaTag),
    .io_msInfo_9_bits_dirHit(io_msInfo_9_bits_dirHit),
    .io_msInfo_9_bits_w_grantfirst(io_msInfo_9_bits_w_grantfirst),
    .io_msInfo_9_bits_s_release(io_msInfo_9_bits_s_release),
    .io_msInfo_9_bits_s_cmoresp(io_msInfo_9_bits_s_cmoresp),
    .io_msInfo_9_bits_s_cmometaw(io_msInfo_9_bits_s_cmometaw),
    .io_msInfo_9_bits_w_releaseack(io_msInfo_9_bits_w_releaseack),
    .io_msInfo_9_bits_w_replResp(io_msInfo_9_bits_w_replResp),
    .io_msInfo_9_bits_w_rprobeacklast(io_msInfo_9_bits_w_rprobeacklast),
    .io_msInfo_9_bits_replaceData(io_msInfo_9_bits_replaceData),
    .io_msInfo_9_bits_releaseToClean(io_msInfo_9_bits_releaseToClean),
    .io_msInfo_10_valid(io_msInfo_10_valid),
    .io_msInfo_10_bits_set(io_msInfo_10_bits_set),
    .io_msInfo_10_bits_reqTag(io_msInfo_10_bits_reqTag),
    .io_msInfo_10_bits_willFree(io_msInfo_10_bits_willFree),
    .io_msInfo_10_bits_aliasTask(io_msInfo_10_bits_aliasTask),
    .io_msInfo_10_bits_blockRefill(io_msInfo_10_bits_blockRefill),
    .io_msInfo_10_bits_meta_dirty(io_msInfo_10_bits_meta_dirty),
    .io_msInfo_10_bits_meta_state(io_msInfo_10_bits_meta_state),
    .io_msInfo_10_bits_meta_clients(io_msInfo_10_bits_meta_clients),
    .io_msInfo_10_bits_meta_alias(io_msInfo_10_bits_meta_alias),
    .io_msInfo_10_bits_meta_prefetch(io_msInfo_10_bits_meta_prefetch),
    .io_msInfo_10_bits_meta_prefetchSrc(io_msInfo_10_bits_meta_prefetchSrc),
    .io_msInfo_10_bits_meta_accessed(io_msInfo_10_bits_meta_accessed),
    .io_msInfo_10_bits_meta_tagErr(io_msInfo_10_bits_meta_tagErr),
    .io_msInfo_10_bits_meta_dataErr(io_msInfo_10_bits_meta_dataErr),
    .io_msInfo_10_bits_metaTag(io_msInfo_10_bits_metaTag),
    .io_msInfo_10_bits_dirHit(io_msInfo_10_bits_dirHit),
    .io_msInfo_10_bits_w_grantfirst(io_msInfo_10_bits_w_grantfirst),
    .io_msInfo_10_bits_s_release(io_msInfo_10_bits_s_release),
    .io_msInfo_10_bits_s_cmoresp(io_msInfo_10_bits_s_cmoresp),
    .io_msInfo_10_bits_s_cmometaw(io_msInfo_10_bits_s_cmometaw),
    .io_msInfo_10_bits_w_releaseack(io_msInfo_10_bits_w_releaseack),
    .io_msInfo_10_bits_w_replResp(io_msInfo_10_bits_w_replResp),
    .io_msInfo_10_bits_w_rprobeacklast(io_msInfo_10_bits_w_rprobeacklast),
    .io_msInfo_10_bits_replaceData(io_msInfo_10_bits_replaceData),
    .io_msInfo_10_bits_releaseToClean(io_msInfo_10_bits_releaseToClean),
    .io_msInfo_11_valid(io_msInfo_11_valid),
    .io_msInfo_11_bits_set(io_msInfo_11_bits_set),
    .io_msInfo_11_bits_reqTag(io_msInfo_11_bits_reqTag),
    .io_msInfo_11_bits_willFree(io_msInfo_11_bits_willFree),
    .io_msInfo_11_bits_aliasTask(io_msInfo_11_bits_aliasTask),
    .io_msInfo_11_bits_blockRefill(io_msInfo_11_bits_blockRefill),
    .io_msInfo_11_bits_meta_dirty(io_msInfo_11_bits_meta_dirty),
    .io_msInfo_11_bits_meta_state(io_msInfo_11_bits_meta_state),
    .io_msInfo_11_bits_meta_clients(io_msInfo_11_bits_meta_clients),
    .io_msInfo_11_bits_meta_alias(io_msInfo_11_bits_meta_alias),
    .io_msInfo_11_bits_meta_prefetch(io_msInfo_11_bits_meta_prefetch),
    .io_msInfo_11_bits_meta_prefetchSrc(io_msInfo_11_bits_meta_prefetchSrc),
    .io_msInfo_11_bits_meta_accessed(io_msInfo_11_bits_meta_accessed),
    .io_msInfo_11_bits_meta_tagErr(io_msInfo_11_bits_meta_tagErr),
    .io_msInfo_11_bits_meta_dataErr(io_msInfo_11_bits_meta_dataErr),
    .io_msInfo_11_bits_metaTag(io_msInfo_11_bits_metaTag),
    .io_msInfo_11_bits_dirHit(io_msInfo_11_bits_dirHit),
    .io_msInfo_11_bits_w_grantfirst(io_msInfo_11_bits_w_grantfirst),
    .io_msInfo_11_bits_s_release(io_msInfo_11_bits_s_release),
    .io_msInfo_11_bits_s_cmoresp(io_msInfo_11_bits_s_cmoresp),
    .io_msInfo_11_bits_s_cmometaw(io_msInfo_11_bits_s_cmometaw),
    .io_msInfo_11_bits_w_releaseack(io_msInfo_11_bits_w_releaseack),
    .io_msInfo_11_bits_w_replResp(io_msInfo_11_bits_w_replResp),
    .io_msInfo_11_bits_w_rprobeacklast(io_msInfo_11_bits_w_rprobeacklast),
    .io_msInfo_11_bits_replaceData(io_msInfo_11_bits_replaceData),
    .io_msInfo_11_bits_releaseToClean(io_msInfo_11_bits_releaseToClean),
    .io_msInfo_12_valid(io_msInfo_12_valid),
    .io_msInfo_12_bits_set(io_msInfo_12_bits_set),
    .io_msInfo_12_bits_reqTag(io_msInfo_12_bits_reqTag),
    .io_msInfo_12_bits_willFree(io_msInfo_12_bits_willFree),
    .io_msInfo_12_bits_aliasTask(io_msInfo_12_bits_aliasTask),
    .io_msInfo_12_bits_blockRefill(io_msInfo_12_bits_blockRefill),
    .io_msInfo_12_bits_meta_dirty(io_msInfo_12_bits_meta_dirty),
    .io_msInfo_12_bits_meta_state(io_msInfo_12_bits_meta_state),
    .io_msInfo_12_bits_meta_clients(io_msInfo_12_bits_meta_clients),
    .io_msInfo_12_bits_meta_alias(io_msInfo_12_bits_meta_alias),
    .io_msInfo_12_bits_meta_prefetch(io_msInfo_12_bits_meta_prefetch),
    .io_msInfo_12_bits_meta_prefetchSrc(io_msInfo_12_bits_meta_prefetchSrc),
    .io_msInfo_12_bits_meta_accessed(io_msInfo_12_bits_meta_accessed),
    .io_msInfo_12_bits_meta_tagErr(io_msInfo_12_bits_meta_tagErr),
    .io_msInfo_12_bits_meta_dataErr(io_msInfo_12_bits_meta_dataErr),
    .io_msInfo_12_bits_metaTag(io_msInfo_12_bits_metaTag),
    .io_msInfo_12_bits_dirHit(io_msInfo_12_bits_dirHit),
    .io_msInfo_12_bits_w_grantfirst(io_msInfo_12_bits_w_grantfirst),
    .io_msInfo_12_bits_s_release(io_msInfo_12_bits_s_release),
    .io_msInfo_12_bits_s_cmoresp(io_msInfo_12_bits_s_cmoresp),
    .io_msInfo_12_bits_s_cmometaw(io_msInfo_12_bits_s_cmometaw),
    .io_msInfo_12_bits_w_releaseack(io_msInfo_12_bits_w_releaseack),
    .io_msInfo_12_bits_w_replResp(io_msInfo_12_bits_w_replResp),
    .io_msInfo_12_bits_w_rprobeacklast(io_msInfo_12_bits_w_rprobeacklast),
    .io_msInfo_12_bits_replaceData(io_msInfo_12_bits_replaceData),
    .io_msInfo_12_bits_releaseToClean(io_msInfo_12_bits_releaseToClean),
    .io_msInfo_13_valid(io_msInfo_13_valid),
    .io_msInfo_13_bits_set(io_msInfo_13_bits_set),
    .io_msInfo_13_bits_reqTag(io_msInfo_13_bits_reqTag),
    .io_msInfo_13_bits_willFree(io_msInfo_13_bits_willFree),
    .io_msInfo_13_bits_aliasTask(io_msInfo_13_bits_aliasTask),
    .io_msInfo_13_bits_blockRefill(io_msInfo_13_bits_blockRefill),
    .io_msInfo_13_bits_meta_dirty(io_msInfo_13_bits_meta_dirty),
    .io_msInfo_13_bits_meta_state(io_msInfo_13_bits_meta_state),
    .io_msInfo_13_bits_meta_clients(io_msInfo_13_bits_meta_clients),
    .io_msInfo_13_bits_meta_alias(io_msInfo_13_bits_meta_alias),
    .io_msInfo_13_bits_meta_prefetch(io_msInfo_13_bits_meta_prefetch),
    .io_msInfo_13_bits_meta_prefetchSrc(io_msInfo_13_bits_meta_prefetchSrc),
    .io_msInfo_13_bits_meta_accessed(io_msInfo_13_bits_meta_accessed),
    .io_msInfo_13_bits_meta_tagErr(io_msInfo_13_bits_meta_tagErr),
    .io_msInfo_13_bits_meta_dataErr(io_msInfo_13_bits_meta_dataErr),
    .io_msInfo_13_bits_metaTag(io_msInfo_13_bits_metaTag),
    .io_msInfo_13_bits_dirHit(io_msInfo_13_bits_dirHit),
    .io_msInfo_13_bits_w_grantfirst(io_msInfo_13_bits_w_grantfirst),
    .io_msInfo_13_bits_s_release(io_msInfo_13_bits_s_release),
    .io_msInfo_13_bits_s_cmoresp(io_msInfo_13_bits_s_cmoresp),
    .io_msInfo_13_bits_s_cmometaw(io_msInfo_13_bits_s_cmometaw),
    .io_msInfo_13_bits_w_releaseack(io_msInfo_13_bits_w_releaseack),
    .io_msInfo_13_bits_w_replResp(io_msInfo_13_bits_w_replResp),
    .io_msInfo_13_bits_w_rprobeacklast(io_msInfo_13_bits_w_rprobeacklast),
    .io_msInfo_13_bits_replaceData(io_msInfo_13_bits_replaceData),
    .io_msInfo_13_bits_releaseToClean(io_msInfo_13_bits_releaseToClean),
    .io_msInfo_14_valid(io_msInfo_14_valid),
    .io_msInfo_14_bits_set(io_msInfo_14_bits_set),
    .io_msInfo_14_bits_reqTag(io_msInfo_14_bits_reqTag),
    .io_msInfo_14_bits_willFree(io_msInfo_14_bits_willFree),
    .io_msInfo_14_bits_aliasTask(io_msInfo_14_bits_aliasTask),
    .io_msInfo_14_bits_blockRefill(io_msInfo_14_bits_blockRefill),
    .io_msInfo_14_bits_meta_dirty(io_msInfo_14_bits_meta_dirty),
    .io_msInfo_14_bits_meta_state(io_msInfo_14_bits_meta_state),
    .io_msInfo_14_bits_meta_clients(io_msInfo_14_bits_meta_clients),
    .io_msInfo_14_bits_meta_alias(io_msInfo_14_bits_meta_alias),
    .io_msInfo_14_bits_meta_prefetch(io_msInfo_14_bits_meta_prefetch),
    .io_msInfo_14_bits_meta_prefetchSrc(io_msInfo_14_bits_meta_prefetchSrc),
    .io_msInfo_14_bits_meta_accessed(io_msInfo_14_bits_meta_accessed),
    .io_msInfo_14_bits_meta_tagErr(io_msInfo_14_bits_meta_tagErr),
    .io_msInfo_14_bits_meta_dataErr(io_msInfo_14_bits_meta_dataErr),
    .io_msInfo_14_bits_metaTag(io_msInfo_14_bits_metaTag),
    .io_msInfo_14_bits_dirHit(io_msInfo_14_bits_dirHit),
    .io_msInfo_14_bits_w_grantfirst(io_msInfo_14_bits_w_grantfirst),
    .io_msInfo_14_bits_s_release(io_msInfo_14_bits_s_release),
    .io_msInfo_14_bits_s_cmoresp(io_msInfo_14_bits_s_cmoresp),
    .io_msInfo_14_bits_s_cmometaw(io_msInfo_14_bits_s_cmometaw),
    .io_msInfo_14_bits_w_releaseack(io_msInfo_14_bits_w_releaseack),
    .io_msInfo_14_bits_w_replResp(io_msInfo_14_bits_w_replResp),
    .io_msInfo_14_bits_w_rprobeacklast(io_msInfo_14_bits_w_rprobeacklast),
    .io_msInfo_14_bits_replaceData(io_msInfo_14_bits_replaceData),
    .io_msInfo_14_bits_releaseToClean(io_msInfo_14_bits_releaseToClean),
    .io_msInfo_15_valid(io_msInfo_15_valid),
    .io_msInfo_15_bits_set(io_msInfo_15_bits_set),
    .io_msInfo_15_bits_reqTag(io_msInfo_15_bits_reqTag),
    .io_msInfo_15_bits_willFree(io_msInfo_15_bits_willFree),
    .io_msInfo_15_bits_aliasTask(io_msInfo_15_bits_aliasTask),
    .io_msInfo_15_bits_blockRefill(io_msInfo_15_bits_blockRefill),
    .io_msInfo_15_bits_meta_dirty(io_msInfo_15_bits_meta_dirty),
    .io_msInfo_15_bits_meta_state(io_msInfo_15_bits_meta_state),
    .io_msInfo_15_bits_meta_clients(io_msInfo_15_bits_meta_clients),
    .io_msInfo_15_bits_meta_alias(io_msInfo_15_bits_meta_alias),
    .io_msInfo_15_bits_meta_prefetch(io_msInfo_15_bits_meta_prefetch),
    .io_msInfo_15_bits_meta_prefetchSrc(io_msInfo_15_bits_meta_prefetchSrc),
    .io_msInfo_15_bits_meta_accessed(io_msInfo_15_bits_meta_accessed),
    .io_msInfo_15_bits_meta_tagErr(io_msInfo_15_bits_meta_tagErr),
    .io_msInfo_15_bits_meta_dataErr(io_msInfo_15_bits_meta_dataErr),
    .io_msInfo_15_bits_metaTag(io_msInfo_15_bits_metaTag),
    .io_msInfo_15_bits_dirHit(io_msInfo_15_bits_dirHit),
    .io_msInfo_15_bits_w_grantfirst(io_msInfo_15_bits_w_grantfirst),
    .io_msInfo_15_bits_s_release(io_msInfo_15_bits_s_release),
    .io_msInfo_15_bits_s_cmoresp(io_msInfo_15_bits_s_cmoresp),
    .io_msInfo_15_bits_s_cmometaw(io_msInfo_15_bits_s_cmometaw),
    .io_msInfo_15_bits_w_releaseack(io_msInfo_15_bits_w_releaseack),
    .io_msInfo_15_bits_w_replResp(io_msInfo_15_bits_w_replResp),
    .io_msInfo_15_bits_w_rprobeacklast(io_msInfo_15_bits_w_rprobeacklast),
    .io_msInfo_15_bits_replaceData(io_msInfo_15_bits_replaceData),
    .io_msInfo_15_bits_releaseToClean(io_msInfo_15_bits_releaseToClean)
  );

  task automatic drive_random();
    io_rxsnp_valid = ($urandom_range(0,1) == 0);
    io_rxsnp_bits_qos = $urandom;
    io_rxsnp_bits_srcID = $urandom;
    io_rxsnp_bits_txnID = $urandom;
    io_rxsnp_bits_fwdNID = $urandom;
    io_rxsnp_bits_fwdTxnID = $urandom;
    io_rxsnp_bits_opcode = $urandom;
    io_rxsnp_bits_addr = $urandom;
    io_rxsnp_bits_ns = $urandom;
    io_rxsnp_bits_doNotGoToSD = $urandom;
    io_rxsnp_bits_retToSrc = $urandom;
    io_rxsnp_bits_traceTag = $urandom;
    io_rxsnp_bits_mpam_perfMonGroup = $urandom;
    io_rxsnp_bits_mpam_partID = $urandom;
    io_rxsnp_bits_mpam_mpamNS = $urandom;
    io_task_ready = ($urandom_range(0,3) != 0);
    io_msInfo_0_valid = $urandom;
    io_msInfo_0_bits_set = $urandom;
    io_msInfo_0_bits_reqTag = $urandom;
    io_msInfo_0_bits_willFree = $urandom;
    io_msInfo_0_bits_aliasTask = $urandom;
    io_msInfo_0_bits_blockRefill = $urandom;
    io_msInfo_0_bits_meta_dirty = $urandom;
    io_msInfo_0_bits_meta_state = $urandom;
    io_msInfo_0_bits_meta_clients = $urandom;
    io_msInfo_0_bits_meta_alias = $urandom;
    io_msInfo_0_bits_meta_prefetch = $urandom;
    io_msInfo_0_bits_meta_prefetchSrc = $urandom;
    io_msInfo_0_bits_meta_accessed = $urandom;
    io_msInfo_0_bits_meta_tagErr = $urandom;
    io_msInfo_0_bits_meta_dataErr = $urandom;
    io_msInfo_0_bits_metaTag = $urandom;
    io_msInfo_0_bits_dirHit = $urandom;
    io_msInfo_0_bits_w_grantfirst = $urandom;
    io_msInfo_0_bits_s_release = $urandom;
    io_msInfo_0_bits_s_cmoresp = $urandom;
    io_msInfo_0_bits_s_cmometaw = $urandom;
    io_msInfo_0_bits_w_releaseack = $urandom;
    io_msInfo_0_bits_w_replResp = $urandom;
    io_msInfo_0_bits_w_rprobeacklast = $urandom;
    io_msInfo_0_bits_replaceData = $urandom;
    io_msInfo_0_bits_releaseToClean = $urandom;
    io_msInfo_1_valid = $urandom;
    io_msInfo_1_bits_set = $urandom;
    io_msInfo_1_bits_reqTag = $urandom;
    io_msInfo_1_bits_willFree = $urandom;
    io_msInfo_1_bits_aliasTask = $urandom;
    io_msInfo_1_bits_blockRefill = $urandom;
    io_msInfo_1_bits_meta_dirty = $urandom;
    io_msInfo_1_bits_meta_state = $urandom;
    io_msInfo_1_bits_meta_clients = $urandom;
    io_msInfo_1_bits_meta_alias = $urandom;
    io_msInfo_1_bits_meta_prefetch = $urandom;
    io_msInfo_1_bits_meta_prefetchSrc = $urandom;
    io_msInfo_1_bits_meta_accessed = $urandom;
    io_msInfo_1_bits_meta_tagErr = $urandom;
    io_msInfo_1_bits_meta_dataErr = $urandom;
    io_msInfo_1_bits_metaTag = $urandom;
    io_msInfo_1_bits_dirHit = $urandom;
    io_msInfo_1_bits_w_grantfirst = $urandom;
    io_msInfo_1_bits_s_release = $urandom;
    io_msInfo_1_bits_s_cmoresp = $urandom;
    io_msInfo_1_bits_s_cmometaw = $urandom;
    io_msInfo_1_bits_w_releaseack = $urandom;
    io_msInfo_1_bits_w_replResp = $urandom;
    io_msInfo_1_bits_w_rprobeacklast = $urandom;
    io_msInfo_1_bits_replaceData = $urandom;
    io_msInfo_1_bits_releaseToClean = $urandom;
    io_msInfo_2_valid = $urandom;
    io_msInfo_2_bits_set = $urandom;
    io_msInfo_2_bits_reqTag = $urandom;
    io_msInfo_2_bits_willFree = $urandom;
    io_msInfo_2_bits_aliasTask = $urandom;
    io_msInfo_2_bits_blockRefill = $urandom;
    io_msInfo_2_bits_meta_dirty = $urandom;
    io_msInfo_2_bits_meta_state = $urandom;
    io_msInfo_2_bits_meta_clients = $urandom;
    io_msInfo_2_bits_meta_alias = $urandom;
    io_msInfo_2_bits_meta_prefetch = $urandom;
    io_msInfo_2_bits_meta_prefetchSrc = $urandom;
    io_msInfo_2_bits_meta_accessed = $urandom;
    io_msInfo_2_bits_meta_tagErr = $urandom;
    io_msInfo_2_bits_meta_dataErr = $urandom;
    io_msInfo_2_bits_metaTag = $urandom;
    io_msInfo_2_bits_dirHit = $urandom;
    io_msInfo_2_bits_w_grantfirst = $urandom;
    io_msInfo_2_bits_s_release = $urandom;
    io_msInfo_2_bits_s_cmoresp = $urandom;
    io_msInfo_2_bits_s_cmometaw = $urandom;
    io_msInfo_2_bits_w_releaseack = $urandom;
    io_msInfo_2_bits_w_replResp = $urandom;
    io_msInfo_2_bits_w_rprobeacklast = $urandom;
    io_msInfo_2_bits_replaceData = $urandom;
    io_msInfo_2_bits_releaseToClean = $urandom;
    io_msInfo_3_valid = $urandom;
    io_msInfo_3_bits_set = $urandom;
    io_msInfo_3_bits_reqTag = $urandom;
    io_msInfo_3_bits_willFree = $urandom;
    io_msInfo_3_bits_aliasTask = $urandom;
    io_msInfo_3_bits_blockRefill = $urandom;
    io_msInfo_3_bits_meta_dirty = $urandom;
    io_msInfo_3_bits_meta_state = $urandom;
    io_msInfo_3_bits_meta_clients = $urandom;
    io_msInfo_3_bits_meta_alias = $urandom;
    io_msInfo_3_bits_meta_prefetch = $urandom;
    io_msInfo_3_bits_meta_prefetchSrc = $urandom;
    io_msInfo_3_bits_meta_accessed = $urandom;
    io_msInfo_3_bits_meta_tagErr = $urandom;
    io_msInfo_3_bits_meta_dataErr = $urandom;
    io_msInfo_3_bits_metaTag = $urandom;
    io_msInfo_3_bits_dirHit = $urandom;
    io_msInfo_3_bits_w_grantfirst = $urandom;
    io_msInfo_3_bits_s_release = $urandom;
    io_msInfo_3_bits_s_cmoresp = $urandom;
    io_msInfo_3_bits_s_cmometaw = $urandom;
    io_msInfo_3_bits_w_releaseack = $urandom;
    io_msInfo_3_bits_w_replResp = $urandom;
    io_msInfo_3_bits_w_rprobeacklast = $urandom;
    io_msInfo_3_bits_replaceData = $urandom;
    io_msInfo_3_bits_releaseToClean = $urandom;
    io_msInfo_4_valid = $urandom;
    io_msInfo_4_bits_set = $urandom;
    io_msInfo_4_bits_reqTag = $urandom;
    io_msInfo_4_bits_willFree = $urandom;
    io_msInfo_4_bits_aliasTask = $urandom;
    io_msInfo_4_bits_blockRefill = $urandom;
    io_msInfo_4_bits_meta_dirty = $urandom;
    io_msInfo_4_bits_meta_state = $urandom;
    io_msInfo_4_bits_meta_clients = $urandom;
    io_msInfo_4_bits_meta_alias = $urandom;
    io_msInfo_4_bits_meta_prefetch = $urandom;
    io_msInfo_4_bits_meta_prefetchSrc = $urandom;
    io_msInfo_4_bits_meta_accessed = $urandom;
    io_msInfo_4_bits_meta_tagErr = $urandom;
    io_msInfo_4_bits_meta_dataErr = $urandom;
    io_msInfo_4_bits_metaTag = $urandom;
    io_msInfo_4_bits_dirHit = $urandom;
    io_msInfo_4_bits_w_grantfirst = $urandom;
    io_msInfo_4_bits_s_release = $urandom;
    io_msInfo_4_bits_s_cmoresp = $urandom;
    io_msInfo_4_bits_s_cmometaw = $urandom;
    io_msInfo_4_bits_w_releaseack = $urandom;
    io_msInfo_4_bits_w_replResp = $urandom;
    io_msInfo_4_bits_w_rprobeacklast = $urandom;
    io_msInfo_4_bits_replaceData = $urandom;
    io_msInfo_4_bits_releaseToClean = $urandom;
    io_msInfo_5_valid = $urandom;
    io_msInfo_5_bits_set = $urandom;
    io_msInfo_5_bits_reqTag = $urandom;
    io_msInfo_5_bits_willFree = $urandom;
    io_msInfo_5_bits_aliasTask = $urandom;
    io_msInfo_5_bits_blockRefill = $urandom;
    io_msInfo_5_bits_meta_dirty = $urandom;
    io_msInfo_5_bits_meta_state = $urandom;
    io_msInfo_5_bits_meta_clients = $urandom;
    io_msInfo_5_bits_meta_alias = $urandom;
    io_msInfo_5_bits_meta_prefetch = $urandom;
    io_msInfo_5_bits_meta_prefetchSrc = $urandom;
    io_msInfo_5_bits_meta_accessed = $urandom;
    io_msInfo_5_bits_meta_tagErr = $urandom;
    io_msInfo_5_bits_meta_dataErr = $urandom;
    io_msInfo_5_bits_metaTag = $urandom;
    io_msInfo_5_bits_dirHit = $urandom;
    io_msInfo_5_bits_w_grantfirst = $urandom;
    io_msInfo_5_bits_s_release = $urandom;
    io_msInfo_5_bits_s_cmoresp = $urandom;
    io_msInfo_5_bits_s_cmometaw = $urandom;
    io_msInfo_5_bits_w_releaseack = $urandom;
    io_msInfo_5_bits_w_replResp = $urandom;
    io_msInfo_5_bits_w_rprobeacklast = $urandom;
    io_msInfo_5_bits_replaceData = $urandom;
    io_msInfo_5_bits_releaseToClean = $urandom;
    io_msInfo_6_valid = $urandom;
    io_msInfo_6_bits_set = $urandom;
    io_msInfo_6_bits_reqTag = $urandom;
    io_msInfo_6_bits_willFree = $urandom;
    io_msInfo_6_bits_aliasTask = $urandom;
    io_msInfo_6_bits_blockRefill = $urandom;
    io_msInfo_6_bits_meta_dirty = $urandom;
    io_msInfo_6_bits_meta_state = $urandom;
    io_msInfo_6_bits_meta_clients = $urandom;
    io_msInfo_6_bits_meta_alias = $urandom;
    io_msInfo_6_bits_meta_prefetch = $urandom;
    io_msInfo_6_bits_meta_prefetchSrc = $urandom;
    io_msInfo_6_bits_meta_accessed = $urandom;
    io_msInfo_6_bits_meta_tagErr = $urandom;
    io_msInfo_6_bits_meta_dataErr = $urandom;
    io_msInfo_6_bits_metaTag = $urandom;
    io_msInfo_6_bits_dirHit = $urandom;
    io_msInfo_6_bits_w_grantfirst = $urandom;
    io_msInfo_6_bits_s_release = $urandom;
    io_msInfo_6_bits_s_cmoresp = $urandom;
    io_msInfo_6_bits_s_cmometaw = $urandom;
    io_msInfo_6_bits_w_releaseack = $urandom;
    io_msInfo_6_bits_w_replResp = $urandom;
    io_msInfo_6_bits_w_rprobeacklast = $urandom;
    io_msInfo_6_bits_replaceData = $urandom;
    io_msInfo_6_bits_releaseToClean = $urandom;
    io_msInfo_7_valid = $urandom;
    io_msInfo_7_bits_set = $urandom;
    io_msInfo_7_bits_reqTag = $urandom;
    io_msInfo_7_bits_willFree = $urandom;
    io_msInfo_7_bits_aliasTask = $urandom;
    io_msInfo_7_bits_blockRefill = $urandom;
    io_msInfo_7_bits_meta_dirty = $urandom;
    io_msInfo_7_bits_meta_state = $urandom;
    io_msInfo_7_bits_meta_clients = $urandom;
    io_msInfo_7_bits_meta_alias = $urandom;
    io_msInfo_7_bits_meta_prefetch = $urandom;
    io_msInfo_7_bits_meta_prefetchSrc = $urandom;
    io_msInfo_7_bits_meta_accessed = $urandom;
    io_msInfo_7_bits_meta_tagErr = $urandom;
    io_msInfo_7_bits_meta_dataErr = $urandom;
    io_msInfo_7_bits_metaTag = $urandom;
    io_msInfo_7_bits_dirHit = $urandom;
    io_msInfo_7_bits_w_grantfirst = $urandom;
    io_msInfo_7_bits_s_release = $urandom;
    io_msInfo_7_bits_s_cmoresp = $urandom;
    io_msInfo_7_bits_s_cmometaw = $urandom;
    io_msInfo_7_bits_w_releaseack = $urandom;
    io_msInfo_7_bits_w_replResp = $urandom;
    io_msInfo_7_bits_w_rprobeacklast = $urandom;
    io_msInfo_7_bits_replaceData = $urandom;
    io_msInfo_7_bits_releaseToClean = $urandom;
    io_msInfo_8_valid = $urandom;
    io_msInfo_8_bits_set = $urandom;
    io_msInfo_8_bits_reqTag = $urandom;
    io_msInfo_8_bits_willFree = $urandom;
    io_msInfo_8_bits_aliasTask = $urandom;
    io_msInfo_8_bits_blockRefill = $urandom;
    io_msInfo_8_bits_meta_dirty = $urandom;
    io_msInfo_8_bits_meta_state = $urandom;
    io_msInfo_8_bits_meta_clients = $urandom;
    io_msInfo_8_bits_meta_alias = $urandom;
    io_msInfo_8_bits_meta_prefetch = $urandom;
    io_msInfo_8_bits_meta_prefetchSrc = $urandom;
    io_msInfo_8_bits_meta_accessed = $urandom;
    io_msInfo_8_bits_meta_tagErr = $urandom;
    io_msInfo_8_bits_meta_dataErr = $urandom;
    io_msInfo_8_bits_metaTag = $urandom;
    io_msInfo_8_bits_dirHit = $urandom;
    io_msInfo_8_bits_w_grantfirst = $urandom;
    io_msInfo_8_bits_s_release = $urandom;
    io_msInfo_8_bits_s_cmoresp = $urandom;
    io_msInfo_8_bits_s_cmometaw = $urandom;
    io_msInfo_8_bits_w_releaseack = $urandom;
    io_msInfo_8_bits_w_replResp = $urandom;
    io_msInfo_8_bits_w_rprobeacklast = $urandom;
    io_msInfo_8_bits_replaceData = $urandom;
    io_msInfo_8_bits_releaseToClean = $urandom;
    io_msInfo_9_valid = $urandom;
    io_msInfo_9_bits_set = $urandom;
    io_msInfo_9_bits_reqTag = $urandom;
    io_msInfo_9_bits_willFree = $urandom;
    io_msInfo_9_bits_aliasTask = $urandom;
    io_msInfo_9_bits_blockRefill = $urandom;
    io_msInfo_9_bits_meta_dirty = $urandom;
    io_msInfo_9_bits_meta_state = $urandom;
    io_msInfo_9_bits_meta_clients = $urandom;
    io_msInfo_9_bits_meta_alias = $urandom;
    io_msInfo_9_bits_meta_prefetch = $urandom;
    io_msInfo_9_bits_meta_prefetchSrc = $urandom;
    io_msInfo_9_bits_meta_accessed = $urandom;
    io_msInfo_9_bits_meta_tagErr = $urandom;
    io_msInfo_9_bits_meta_dataErr = $urandom;
    io_msInfo_9_bits_metaTag = $urandom;
    io_msInfo_9_bits_dirHit = $urandom;
    io_msInfo_9_bits_w_grantfirst = $urandom;
    io_msInfo_9_bits_s_release = $urandom;
    io_msInfo_9_bits_s_cmoresp = $urandom;
    io_msInfo_9_bits_s_cmometaw = $urandom;
    io_msInfo_9_bits_w_releaseack = $urandom;
    io_msInfo_9_bits_w_replResp = $urandom;
    io_msInfo_9_bits_w_rprobeacklast = $urandom;
    io_msInfo_9_bits_replaceData = $urandom;
    io_msInfo_9_bits_releaseToClean = $urandom;
    io_msInfo_10_valid = $urandom;
    io_msInfo_10_bits_set = $urandom;
    io_msInfo_10_bits_reqTag = $urandom;
    io_msInfo_10_bits_willFree = $urandom;
    io_msInfo_10_bits_aliasTask = $urandom;
    io_msInfo_10_bits_blockRefill = $urandom;
    io_msInfo_10_bits_meta_dirty = $urandom;
    io_msInfo_10_bits_meta_state = $urandom;
    io_msInfo_10_bits_meta_clients = $urandom;
    io_msInfo_10_bits_meta_alias = $urandom;
    io_msInfo_10_bits_meta_prefetch = $urandom;
    io_msInfo_10_bits_meta_prefetchSrc = $urandom;
    io_msInfo_10_bits_meta_accessed = $urandom;
    io_msInfo_10_bits_meta_tagErr = $urandom;
    io_msInfo_10_bits_meta_dataErr = $urandom;
    io_msInfo_10_bits_metaTag = $urandom;
    io_msInfo_10_bits_dirHit = $urandom;
    io_msInfo_10_bits_w_grantfirst = $urandom;
    io_msInfo_10_bits_s_release = $urandom;
    io_msInfo_10_bits_s_cmoresp = $urandom;
    io_msInfo_10_bits_s_cmometaw = $urandom;
    io_msInfo_10_bits_w_releaseack = $urandom;
    io_msInfo_10_bits_w_replResp = $urandom;
    io_msInfo_10_bits_w_rprobeacklast = $urandom;
    io_msInfo_10_bits_replaceData = $urandom;
    io_msInfo_10_bits_releaseToClean = $urandom;
    io_msInfo_11_valid = $urandom;
    io_msInfo_11_bits_set = $urandom;
    io_msInfo_11_bits_reqTag = $urandom;
    io_msInfo_11_bits_willFree = $urandom;
    io_msInfo_11_bits_aliasTask = $urandom;
    io_msInfo_11_bits_blockRefill = $urandom;
    io_msInfo_11_bits_meta_dirty = $urandom;
    io_msInfo_11_bits_meta_state = $urandom;
    io_msInfo_11_bits_meta_clients = $urandom;
    io_msInfo_11_bits_meta_alias = $urandom;
    io_msInfo_11_bits_meta_prefetch = $urandom;
    io_msInfo_11_bits_meta_prefetchSrc = $urandom;
    io_msInfo_11_bits_meta_accessed = $urandom;
    io_msInfo_11_bits_meta_tagErr = $urandom;
    io_msInfo_11_bits_meta_dataErr = $urandom;
    io_msInfo_11_bits_metaTag = $urandom;
    io_msInfo_11_bits_dirHit = $urandom;
    io_msInfo_11_bits_w_grantfirst = $urandom;
    io_msInfo_11_bits_s_release = $urandom;
    io_msInfo_11_bits_s_cmoresp = $urandom;
    io_msInfo_11_bits_s_cmometaw = $urandom;
    io_msInfo_11_bits_w_releaseack = $urandom;
    io_msInfo_11_bits_w_replResp = $urandom;
    io_msInfo_11_bits_w_rprobeacklast = $urandom;
    io_msInfo_11_bits_replaceData = $urandom;
    io_msInfo_11_bits_releaseToClean = $urandom;
    io_msInfo_12_valid = $urandom;
    io_msInfo_12_bits_set = $urandom;
    io_msInfo_12_bits_reqTag = $urandom;
    io_msInfo_12_bits_willFree = $urandom;
    io_msInfo_12_bits_aliasTask = $urandom;
    io_msInfo_12_bits_blockRefill = $urandom;
    io_msInfo_12_bits_meta_dirty = $urandom;
    io_msInfo_12_bits_meta_state = $urandom;
    io_msInfo_12_bits_meta_clients = $urandom;
    io_msInfo_12_bits_meta_alias = $urandom;
    io_msInfo_12_bits_meta_prefetch = $urandom;
    io_msInfo_12_bits_meta_prefetchSrc = $urandom;
    io_msInfo_12_bits_meta_accessed = $urandom;
    io_msInfo_12_bits_meta_tagErr = $urandom;
    io_msInfo_12_bits_meta_dataErr = $urandom;
    io_msInfo_12_bits_metaTag = $urandom;
    io_msInfo_12_bits_dirHit = $urandom;
    io_msInfo_12_bits_w_grantfirst = $urandom;
    io_msInfo_12_bits_s_release = $urandom;
    io_msInfo_12_bits_s_cmoresp = $urandom;
    io_msInfo_12_bits_s_cmometaw = $urandom;
    io_msInfo_12_bits_w_releaseack = $urandom;
    io_msInfo_12_bits_w_replResp = $urandom;
    io_msInfo_12_bits_w_rprobeacklast = $urandom;
    io_msInfo_12_bits_replaceData = $urandom;
    io_msInfo_12_bits_releaseToClean = $urandom;
    io_msInfo_13_valid = $urandom;
    io_msInfo_13_bits_set = $urandom;
    io_msInfo_13_bits_reqTag = $urandom;
    io_msInfo_13_bits_willFree = $urandom;
    io_msInfo_13_bits_aliasTask = $urandom;
    io_msInfo_13_bits_blockRefill = $urandom;
    io_msInfo_13_bits_meta_dirty = $urandom;
    io_msInfo_13_bits_meta_state = $urandom;
    io_msInfo_13_bits_meta_clients = $urandom;
    io_msInfo_13_bits_meta_alias = $urandom;
    io_msInfo_13_bits_meta_prefetch = $urandom;
    io_msInfo_13_bits_meta_prefetchSrc = $urandom;
    io_msInfo_13_bits_meta_accessed = $urandom;
    io_msInfo_13_bits_meta_tagErr = $urandom;
    io_msInfo_13_bits_meta_dataErr = $urandom;
    io_msInfo_13_bits_metaTag = $urandom;
    io_msInfo_13_bits_dirHit = $urandom;
    io_msInfo_13_bits_w_grantfirst = $urandom;
    io_msInfo_13_bits_s_release = $urandom;
    io_msInfo_13_bits_s_cmoresp = $urandom;
    io_msInfo_13_bits_s_cmometaw = $urandom;
    io_msInfo_13_bits_w_releaseack = $urandom;
    io_msInfo_13_bits_w_replResp = $urandom;
    io_msInfo_13_bits_w_rprobeacklast = $urandom;
    io_msInfo_13_bits_replaceData = $urandom;
    io_msInfo_13_bits_releaseToClean = $urandom;
    io_msInfo_14_valid = $urandom;
    io_msInfo_14_bits_set = $urandom;
    io_msInfo_14_bits_reqTag = $urandom;
    io_msInfo_14_bits_willFree = $urandom;
    io_msInfo_14_bits_aliasTask = $urandom;
    io_msInfo_14_bits_blockRefill = $urandom;
    io_msInfo_14_bits_meta_dirty = $urandom;
    io_msInfo_14_bits_meta_state = $urandom;
    io_msInfo_14_bits_meta_clients = $urandom;
    io_msInfo_14_bits_meta_alias = $urandom;
    io_msInfo_14_bits_meta_prefetch = $urandom;
    io_msInfo_14_bits_meta_prefetchSrc = $urandom;
    io_msInfo_14_bits_meta_accessed = $urandom;
    io_msInfo_14_bits_meta_tagErr = $urandom;
    io_msInfo_14_bits_meta_dataErr = $urandom;
    io_msInfo_14_bits_metaTag = $urandom;
    io_msInfo_14_bits_dirHit = $urandom;
    io_msInfo_14_bits_w_grantfirst = $urandom;
    io_msInfo_14_bits_s_release = $urandom;
    io_msInfo_14_bits_s_cmoresp = $urandom;
    io_msInfo_14_bits_s_cmometaw = $urandom;
    io_msInfo_14_bits_w_releaseack = $urandom;
    io_msInfo_14_bits_w_replResp = $urandom;
    io_msInfo_14_bits_w_rprobeacklast = $urandom;
    io_msInfo_14_bits_replaceData = $urandom;
    io_msInfo_14_bits_releaseToClean = $urandom;
    io_msInfo_15_valid = $urandom;
    io_msInfo_15_bits_set = $urandom;
    io_msInfo_15_bits_reqTag = $urandom;
    io_msInfo_15_bits_willFree = $urandom;
    io_msInfo_15_bits_aliasTask = $urandom;
    io_msInfo_15_bits_blockRefill = $urandom;
    io_msInfo_15_bits_meta_dirty = $urandom;
    io_msInfo_15_bits_meta_state = $urandom;
    io_msInfo_15_bits_meta_clients = $urandom;
    io_msInfo_15_bits_meta_alias = $urandom;
    io_msInfo_15_bits_meta_prefetch = $urandom;
    io_msInfo_15_bits_meta_prefetchSrc = $urandom;
    io_msInfo_15_bits_meta_accessed = $urandom;
    io_msInfo_15_bits_meta_tagErr = $urandom;
    io_msInfo_15_bits_meta_dataErr = $urandom;
    io_msInfo_15_bits_metaTag = $urandom;
    io_msInfo_15_bits_dirHit = $urandom;
    io_msInfo_15_bits_w_grantfirst = $urandom;
    io_msInfo_15_bits_s_release = $urandom;
    io_msInfo_15_bits_s_cmoresp = $urandom;
    io_msInfo_15_bits_s_cmometaw = $urandom;
    io_msInfo_15_bits_w_releaseack = $urandom;
    io_msInfo_15_bits_w_replResp = $urandom;
    io_msInfo_15_bits_w_rprobeacklast = $urandom;
    io_msInfo_15_bits_replaceData = $urandom;
    io_msInfo_15_bits_releaseToClean = $urandom;
  endtask

  task automatic check_outputs();
    `CHK(io_rxsnp_ready)
    `CHK(io_task_valid)
    `CHK(io_task_bits_set)
    `CHK(io_task_bits_tag)
    `CHK(io_task_bits_off)
    `CHK(io_task_bits_snpHitRelease)
    `CHK(io_task_bits_snpHitReleaseToInval)
    `CHK(io_task_bits_snpHitReleaseToClean)
    `CHK(io_task_bits_snpHitReleaseWithData)
    `CHK(io_task_bits_snpHitReleaseIdx)
    `CHK(io_task_bits_snpHitReleaseMeta_dirty)
    `CHK(io_task_bits_snpHitReleaseMeta_state)
    `CHK(io_task_bits_snpHitReleaseMeta_clients)
    `CHK(io_task_bits_snpHitReleaseMeta_alias)
    `CHK(io_task_bits_snpHitReleaseMeta_prefetch)
    `CHK(io_task_bits_snpHitReleaseMeta_prefetchSrc)
    `CHK(io_task_bits_snpHitReleaseMeta_accessed)
    `CHK(io_task_bits_snpHitReleaseMeta_tagErr)
    `CHK(io_task_bits_snpHitReleaseMeta_dataErr)
    `CHK(io_task_bits_srcID)
    `CHK(io_task_bits_txnID)
    `CHK(io_task_bits_fwdNID)
    `CHK(io_task_bits_fwdTxnID)
    `CHK(io_task_bits_chiOpcode)
    `CHK(io_task_bits_retToSrc)
    `CHK(io_task_bits_traceTag)
  endtask

  initial begin
    if ($value$plusargs("NCYCLES=%d", NCYCLES)) begin end
    reset = 1'b1;
    io_rxsnp_valid = '0;
    io_rxsnp_bits_qos = '0;
    io_rxsnp_bits_srcID = '0;
    io_rxsnp_bits_txnID = '0;
    io_rxsnp_bits_fwdNID = '0;
    io_rxsnp_bits_fwdTxnID = '0;
    io_rxsnp_bits_opcode = '0;
    io_rxsnp_bits_addr = '0;
    io_rxsnp_bits_ns = '0;
    io_rxsnp_bits_doNotGoToSD = '0;
    io_rxsnp_bits_retToSrc = '0;
    io_rxsnp_bits_traceTag = '0;
    io_rxsnp_bits_mpam_perfMonGroup = '0;
    io_rxsnp_bits_mpam_partID = '0;
    io_rxsnp_bits_mpam_mpamNS = '0;
    io_task_ready = '0;
    io_msInfo_0_valid = '0;
    io_msInfo_0_bits_set = '0;
    io_msInfo_0_bits_reqTag = '0;
    io_msInfo_0_bits_willFree = '0;
    io_msInfo_0_bits_aliasTask = '0;
    io_msInfo_0_bits_blockRefill = '0;
    io_msInfo_0_bits_meta_dirty = '0;
    io_msInfo_0_bits_meta_state = '0;
    io_msInfo_0_bits_meta_clients = '0;
    io_msInfo_0_bits_meta_alias = '0;
    io_msInfo_0_bits_meta_prefetch = '0;
    io_msInfo_0_bits_meta_prefetchSrc = '0;
    io_msInfo_0_bits_meta_accessed = '0;
    io_msInfo_0_bits_meta_tagErr = '0;
    io_msInfo_0_bits_meta_dataErr = '0;
    io_msInfo_0_bits_metaTag = '0;
    io_msInfo_0_bits_dirHit = '0;
    io_msInfo_0_bits_w_grantfirst = '0;
    io_msInfo_0_bits_s_release = '0;
    io_msInfo_0_bits_s_cmoresp = '0;
    io_msInfo_0_bits_s_cmometaw = '0;
    io_msInfo_0_bits_w_releaseack = '0;
    io_msInfo_0_bits_w_replResp = '0;
    io_msInfo_0_bits_w_rprobeacklast = '0;
    io_msInfo_0_bits_replaceData = '0;
    io_msInfo_0_bits_releaseToClean = '0;
    io_msInfo_1_valid = '0;
    io_msInfo_1_bits_set = '0;
    io_msInfo_1_bits_reqTag = '0;
    io_msInfo_1_bits_willFree = '0;
    io_msInfo_1_bits_aliasTask = '0;
    io_msInfo_1_bits_blockRefill = '0;
    io_msInfo_1_bits_meta_dirty = '0;
    io_msInfo_1_bits_meta_state = '0;
    io_msInfo_1_bits_meta_clients = '0;
    io_msInfo_1_bits_meta_alias = '0;
    io_msInfo_1_bits_meta_prefetch = '0;
    io_msInfo_1_bits_meta_prefetchSrc = '0;
    io_msInfo_1_bits_meta_accessed = '0;
    io_msInfo_1_bits_meta_tagErr = '0;
    io_msInfo_1_bits_meta_dataErr = '0;
    io_msInfo_1_bits_metaTag = '0;
    io_msInfo_1_bits_dirHit = '0;
    io_msInfo_1_bits_w_grantfirst = '0;
    io_msInfo_1_bits_s_release = '0;
    io_msInfo_1_bits_s_cmoresp = '0;
    io_msInfo_1_bits_s_cmometaw = '0;
    io_msInfo_1_bits_w_releaseack = '0;
    io_msInfo_1_bits_w_replResp = '0;
    io_msInfo_1_bits_w_rprobeacklast = '0;
    io_msInfo_1_bits_replaceData = '0;
    io_msInfo_1_bits_releaseToClean = '0;
    io_msInfo_2_valid = '0;
    io_msInfo_2_bits_set = '0;
    io_msInfo_2_bits_reqTag = '0;
    io_msInfo_2_bits_willFree = '0;
    io_msInfo_2_bits_aliasTask = '0;
    io_msInfo_2_bits_blockRefill = '0;
    io_msInfo_2_bits_meta_dirty = '0;
    io_msInfo_2_bits_meta_state = '0;
    io_msInfo_2_bits_meta_clients = '0;
    io_msInfo_2_bits_meta_alias = '0;
    io_msInfo_2_bits_meta_prefetch = '0;
    io_msInfo_2_bits_meta_prefetchSrc = '0;
    io_msInfo_2_bits_meta_accessed = '0;
    io_msInfo_2_bits_meta_tagErr = '0;
    io_msInfo_2_bits_meta_dataErr = '0;
    io_msInfo_2_bits_metaTag = '0;
    io_msInfo_2_bits_dirHit = '0;
    io_msInfo_2_bits_w_grantfirst = '0;
    io_msInfo_2_bits_s_release = '0;
    io_msInfo_2_bits_s_cmoresp = '0;
    io_msInfo_2_bits_s_cmometaw = '0;
    io_msInfo_2_bits_w_releaseack = '0;
    io_msInfo_2_bits_w_replResp = '0;
    io_msInfo_2_bits_w_rprobeacklast = '0;
    io_msInfo_2_bits_replaceData = '0;
    io_msInfo_2_bits_releaseToClean = '0;
    io_msInfo_3_valid = '0;
    io_msInfo_3_bits_set = '0;
    io_msInfo_3_bits_reqTag = '0;
    io_msInfo_3_bits_willFree = '0;
    io_msInfo_3_bits_aliasTask = '0;
    io_msInfo_3_bits_blockRefill = '0;
    io_msInfo_3_bits_meta_dirty = '0;
    io_msInfo_3_bits_meta_state = '0;
    io_msInfo_3_bits_meta_clients = '0;
    io_msInfo_3_bits_meta_alias = '0;
    io_msInfo_3_bits_meta_prefetch = '0;
    io_msInfo_3_bits_meta_prefetchSrc = '0;
    io_msInfo_3_bits_meta_accessed = '0;
    io_msInfo_3_bits_meta_tagErr = '0;
    io_msInfo_3_bits_meta_dataErr = '0;
    io_msInfo_3_bits_metaTag = '0;
    io_msInfo_3_bits_dirHit = '0;
    io_msInfo_3_bits_w_grantfirst = '0;
    io_msInfo_3_bits_s_release = '0;
    io_msInfo_3_bits_s_cmoresp = '0;
    io_msInfo_3_bits_s_cmometaw = '0;
    io_msInfo_3_bits_w_releaseack = '0;
    io_msInfo_3_bits_w_replResp = '0;
    io_msInfo_3_bits_w_rprobeacklast = '0;
    io_msInfo_3_bits_replaceData = '0;
    io_msInfo_3_bits_releaseToClean = '0;
    io_msInfo_4_valid = '0;
    io_msInfo_4_bits_set = '0;
    io_msInfo_4_bits_reqTag = '0;
    io_msInfo_4_bits_willFree = '0;
    io_msInfo_4_bits_aliasTask = '0;
    io_msInfo_4_bits_blockRefill = '0;
    io_msInfo_4_bits_meta_dirty = '0;
    io_msInfo_4_bits_meta_state = '0;
    io_msInfo_4_bits_meta_clients = '0;
    io_msInfo_4_bits_meta_alias = '0;
    io_msInfo_4_bits_meta_prefetch = '0;
    io_msInfo_4_bits_meta_prefetchSrc = '0;
    io_msInfo_4_bits_meta_accessed = '0;
    io_msInfo_4_bits_meta_tagErr = '0;
    io_msInfo_4_bits_meta_dataErr = '0;
    io_msInfo_4_bits_metaTag = '0;
    io_msInfo_4_bits_dirHit = '0;
    io_msInfo_4_bits_w_grantfirst = '0;
    io_msInfo_4_bits_s_release = '0;
    io_msInfo_4_bits_s_cmoresp = '0;
    io_msInfo_4_bits_s_cmometaw = '0;
    io_msInfo_4_bits_w_releaseack = '0;
    io_msInfo_4_bits_w_replResp = '0;
    io_msInfo_4_bits_w_rprobeacklast = '0;
    io_msInfo_4_bits_replaceData = '0;
    io_msInfo_4_bits_releaseToClean = '0;
    io_msInfo_5_valid = '0;
    io_msInfo_5_bits_set = '0;
    io_msInfo_5_bits_reqTag = '0;
    io_msInfo_5_bits_willFree = '0;
    io_msInfo_5_bits_aliasTask = '0;
    io_msInfo_5_bits_blockRefill = '0;
    io_msInfo_5_bits_meta_dirty = '0;
    io_msInfo_5_bits_meta_state = '0;
    io_msInfo_5_bits_meta_clients = '0;
    io_msInfo_5_bits_meta_alias = '0;
    io_msInfo_5_bits_meta_prefetch = '0;
    io_msInfo_5_bits_meta_prefetchSrc = '0;
    io_msInfo_5_bits_meta_accessed = '0;
    io_msInfo_5_bits_meta_tagErr = '0;
    io_msInfo_5_bits_meta_dataErr = '0;
    io_msInfo_5_bits_metaTag = '0;
    io_msInfo_5_bits_dirHit = '0;
    io_msInfo_5_bits_w_grantfirst = '0;
    io_msInfo_5_bits_s_release = '0;
    io_msInfo_5_bits_s_cmoresp = '0;
    io_msInfo_5_bits_s_cmometaw = '0;
    io_msInfo_5_bits_w_releaseack = '0;
    io_msInfo_5_bits_w_replResp = '0;
    io_msInfo_5_bits_w_rprobeacklast = '0;
    io_msInfo_5_bits_replaceData = '0;
    io_msInfo_5_bits_releaseToClean = '0;
    io_msInfo_6_valid = '0;
    io_msInfo_6_bits_set = '0;
    io_msInfo_6_bits_reqTag = '0;
    io_msInfo_6_bits_willFree = '0;
    io_msInfo_6_bits_aliasTask = '0;
    io_msInfo_6_bits_blockRefill = '0;
    io_msInfo_6_bits_meta_dirty = '0;
    io_msInfo_6_bits_meta_state = '0;
    io_msInfo_6_bits_meta_clients = '0;
    io_msInfo_6_bits_meta_alias = '0;
    io_msInfo_6_bits_meta_prefetch = '0;
    io_msInfo_6_bits_meta_prefetchSrc = '0;
    io_msInfo_6_bits_meta_accessed = '0;
    io_msInfo_6_bits_meta_tagErr = '0;
    io_msInfo_6_bits_meta_dataErr = '0;
    io_msInfo_6_bits_metaTag = '0;
    io_msInfo_6_bits_dirHit = '0;
    io_msInfo_6_bits_w_grantfirst = '0;
    io_msInfo_6_bits_s_release = '0;
    io_msInfo_6_bits_s_cmoresp = '0;
    io_msInfo_6_bits_s_cmometaw = '0;
    io_msInfo_6_bits_w_releaseack = '0;
    io_msInfo_6_bits_w_replResp = '0;
    io_msInfo_6_bits_w_rprobeacklast = '0;
    io_msInfo_6_bits_replaceData = '0;
    io_msInfo_6_bits_releaseToClean = '0;
    io_msInfo_7_valid = '0;
    io_msInfo_7_bits_set = '0;
    io_msInfo_7_bits_reqTag = '0;
    io_msInfo_7_bits_willFree = '0;
    io_msInfo_7_bits_aliasTask = '0;
    io_msInfo_7_bits_blockRefill = '0;
    io_msInfo_7_bits_meta_dirty = '0;
    io_msInfo_7_bits_meta_state = '0;
    io_msInfo_7_bits_meta_clients = '0;
    io_msInfo_7_bits_meta_alias = '0;
    io_msInfo_7_bits_meta_prefetch = '0;
    io_msInfo_7_bits_meta_prefetchSrc = '0;
    io_msInfo_7_bits_meta_accessed = '0;
    io_msInfo_7_bits_meta_tagErr = '0;
    io_msInfo_7_bits_meta_dataErr = '0;
    io_msInfo_7_bits_metaTag = '0;
    io_msInfo_7_bits_dirHit = '0;
    io_msInfo_7_bits_w_grantfirst = '0;
    io_msInfo_7_bits_s_release = '0;
    io_msInfo_7_bits_s_cmoresp = '0;
    io_msInfo_7_bits_s_cmometaw = '0;
    io_msInfo_7_bits_w_releaseack = '0;
    io_msInfo_7_bits_w_replResp = '0;
    io_msInfo_7_bits_w_rprobeacklast = '0;
    io_msInfo_7_bits_replaceData = '0;
    io_msInfo_7_bits_releaseToClean = '0;
    io_msInfo_8_valid = '0;
    io_msInfo_8_bits_set = '0;
    io_msInfo_8_bits_reqTag = '0;
    io_msInfo_8_bits_willFree = '0;
    io_msInfo_8_bits_aliasTask = '0;
    io_msInfo_8_bits_blockRefill = '0;
    io_msInfo_8_bits_meta_dirty = '0;
    io_msInfo_8_bits_meta_state = '0;
    io_msInfo_8_bits_meta_clients = '0;
    io_msInfo_8_bits_meta_alias = '0;
    io_msInfo_8_bits_meta_prefetch = '0;
    io_msInfo_8_bits_meta_prefetchSrc = '0;
    io_msInfo_8_bits_meta_accessed = '0;
    io_msInfo_8_bits_meta_tagErr = '0;
    io_msInfo_8_bits_meta_dataErr = '0;
    io_msInfo_8_bits_metaTag = '0;
    io_msInfo_8_bits_dirHit = '0;
    io_msInfo_8_bits_w_grantfirst = '0;
    io_msInfo_8_bits_s_release = '0;
    io_msInfo_8_bits_s_cmoresp = '0;
    io_msInfo_8_bits_s_cmometaw = '0;
    io_msInfo_8_bits_w_releaseack = '0;
    io_msInfo_8_bits_w_replResp = '0;
    io_msInfo_8_bits_w_rprobeacklast = '0;
    io_msInfo_8_bits_replaceData = '0;
    io_msInfo_8_bits_releaseToClean = '0;
    io_msInfo_9_valid = '0;
    io_msInfo_9_bits_set = '0;
    io_msInfo_9_bits_reqTag = '0;
    io_msInfo_9_bits_willFree = '0;
    io_msInfo_9_bits_aliasTask = '0;
    io_msInfo_9_bits_blockRefill = '0;
    io_msInfo_9_bits_meta_dirty = '0;
    io_msInfo_9_bits_meta_state = '0;
    io_msInfo_9_bits_meta_clients = '0;
    io_msInfo_9_bits_meta_alias = '0;
    io_msInfo_9_bits_meta_prefetch = '0;
    io_msInfo_9_bits_meta_prefetchSrc = '0;
    io_msInfo_9_bits_meta_accessed = '0;
    io_msInfo_9_bits_meta_tagErr = '0;
    io_msInfo_9_bits_meta_dataErr = '0;
    io_msInfo_9_bits_metaTag = '0;
    io_msInfo_9_bits_dirHit = '0;
    io_msInfo_9_bits_w_grantfirst = '0;
    io_msInfo_9_bits_s_release = '0;
    io_msInfo_9_bits_s_cmoresp = '0;
    io_msInfo_9_bits_s_cmometaw = '0;
    io_msInfo_9_bits_w_releaseack = '0;
    io_msInfo_9_bits_w_replResp = '0;
    io_msInfo_9_bits_w_rprobeacklast = '0;
    io_msInfo_9_bits_replaceData = '0;
    io_msInfo_9_bits_releaseToClean = '0;
    io_msInfo_10_valid = '0;
    io_msInfo_10_bits_set = '0;
    io_msInfo_10_bits_reqTag = '0;
    io_msInfo_10_bits_willFree = '0;
    io_msInfo_10_bits_aliasTask = '0;
    io_msInfo_10_bits_blockRefill = '0;
    io_msInfo_10_bits_meta_dirty = '0;
    io_msInfo_10_bits_meta_state = '0;
    io_msInfo_10_bits_meta_clients = '0;
    io_msInfo_10_bits_meta_alias = '0;
    io_msInfo_10_bits_meta_prefetch = '0;
    io_msInfo_10_bits_meta_prefetchSrc = '0;
    io_msInfo_10_bits_meta_accessed = '0;
    io_msInfo_10_bits_meta_tagErr = '0;
    io_msInfo_10_bits_meta_dataErr = '0;
    io_msInfo_10_bits_metaTag = '0;
    io_msInfo_10_bits_dirHit = '0;
    io_msInfo_10_bits_w_grantfirst = '0;
    io_msInfo_10_bits_s_release = '0;
    io_msInfo_10_bits_s_cmoresp = '0;
    io_msInfo_10_bits_s_cmometaw = '0;
    io_msInfo_10_bits_w_releaseack = '0;
    io_msInfo_10_bits_w_replResp = '0;
    io_msInfo_10_bits_w_rprobeacklast = '0;
    io_msInfo_10_bits_replaceData = '0;
    io_msInfo_10_bits_releaseToClean = '0;
    io_msInfo_11_valid = '0;
    io_msInfo_11_bits_set = '0;
    io_msInfo_11_bits_reqTag = '0;
    io_msInfo_11_bits_willFree = '0;
    io_msInfo_11_bits_aliasTask = '0;
    io_msInfo_11_bits_blockRefill = '0;
    io_msInfo_11_bits_meta_dirty = '0;
    io_msInfo_11_bits_meta_state = '0;
    io_msInfo_11_bits_meta_clients = '0;
    io_msInfo_11_bits_meta_alias = '0;
    io_msInfo_11_bits_meta_prefetch = '0;
    io_msInfo_11_bits_meta_prefetchSrc = '0;
    io_msInfo_11_bits_meta_accessed = '0;
    io_msInfo_11_bits_meta_tagErr = '0;
    io_msInfo_11_bits_meta_dataErr = '0;
    io_msInfo_11_bits_metaTag = '0;
    io_msInfo_11_bits_dirHit = '0;
    io_msInfo_11_bits_w_grantfirst = '0;
    io_msInfo_11_bits_s_release = '0;
    io_msInfo_11_bits_s_cmoresp = '0;
    io_msInfo_11_bits_s_cmometaw = '0;
    io_msInfo_11_bits_w_releaseack = '0;
    io_msInfo_11_bits_w_replResp = '0;
    io_msInfo_11_bits_w_rprobeacklast = '0;
    io_msInfo_11_bits_replaceData = '0;
    io_msInfo_11_bits_releaseToClean = '0;
    io_msInfo_12_valid = '0;
    io_msInfo_12_bits_set = '0;
    io_msInfo_12_bits_reqTag = '0;
    io_msInfo_12_bits_willFree = '0;
    io_msInfo_12_bits_aliasTask = '0;
    io_msInfo_12_bits_blockRefill = '0;
    io_msInfo_12_bits_meta_dirty = '0;
    io_msInfo_12_bits_meta_state = '0;
    io_msInfo_12_bits_meta_clients = '0;
    io_msInfo_12_bits_meta_alias = '0;
    io_msInfo_12_bits_meta_prefetch = '0;
    io_msInfo_12_bits_meta_prefetchSrc = '0;
    io_msInfo_12_bits_meta_accessed = '0;
    io_msInfo_12_bits_meta_tagErr = '0;
    io_msInfo_12_bits_meta_dataErr = '0;
    io_msInfo_12_bits_metaTag = '0;
    io_msInfo_12_bits_dirHit = '0;
    io_msInfo_12_bits_w_grantfirst = '0;
    io_msInfo_12_bits_s_release = '0;
    io_msInfo_12_bits_s_cmoresp = '0;
    io_msInfo_12_bits_s_cmometaw = '0;
    io_msInfo_12_bits_w_releaseack = '0;
    io_msInfo_12_bits_w_replResp = '0;
    io_msInfo_12_bits_w_rprobeacklast = '0;
    io_msInfo_12_bits_replaceData = '0;
    io_msInfo_12_bits_releaseToClean = '0;
    io_msInfo_13_valid = '0;
    io_msInfo_13_bits_set = '0;
    io_msInfo_13_bits_reqTag = '0;
    io_msInfo_13_bits_willFree = '0;
    io_msInfo_13_bits_aliasTask = '0;
    io_msInfo_13_bits_blockRefill = '0;
    io_msInfo_13_bits_meta_dirty = '0;
    io_msInfo_13_bits_meta_state = '0;
    io_msInfo_13_bits_meta_clients = '0;
    io_msInfo_13_bits_meta_alias = '0;
    io_msInfo_13_bits_meta_prefetch = '0;
    io_msInfo_13_bits_meta_prefetchSrc = '0;
    io_msInfo_13_bits_meta_accessed = '0;
    io_msInfo_13_bits_meta_tagErr = '0;
    io_msInfo_13_bits_meta_dataErr = '0;
    io_msInfo_13_bits_metaTag = '0;
    io_msInfo_13_bits_dirHit = '0;
    io_msInfo_13_bits_w_grantfirst = '0;
    io_msInfo_13_bits_s_release = '0;
    io_msInfo_13_bits_s_cmoresp = '0;
    io_msInfo_13_bits_s_cmometaw = '0;
    io_msInfo_13_bits_w_releaseack = '0;
    io_msInfo_13_bits_w_replResp = '0;
    io_msInfo_13_bits_w_rprobeacklast = '0;
    io_msInfo_13_bits_replaceData = '0;
    io_msInfo_13_bits_releaseToClean = '0;
    io_msInfo_14_valid = '0;
    io_msInfo_14_bits_set = '0;
    io_msInfo_14_bits_reqTag = '0;
    io_msInfo_14_bits_willFree = '0;
    io_msInfo_14_bits_aliasTask = '0;
    io_msInfo_14_bits_blockRefill = '0;
    io_msInfo_14_bits_meta_dirty = '0;
    io_msInfo_14_bits_meta_state = '0;
    io_msInfo_14_bits_meta_clients = '0;
    io_msInfo_14_bits_meta_alias = '0;
    io_msInfo_14_bits_meta_prefetch = '0;
    io_msInfo_14_bits_meta_prefetchSrc = '0;
    io_msInfo_14_bits_meta_accessed = '0;
    io_msInfo_14_bits_meta_tagErr = '0;
    io_msInfo_14_bits_meta_dataErr = '0;
    io_msInfo_14_bits_metaTag = '0;
    io_msInfo_14_bits_dirHit = '0;
    io_msInfo_14_bits_w_grantfirst = '0;
    io_msInfo_14_bits_s_release = '0;
    io_msInfo_14_bits_s_cmoresp = '0;
    io_msInfo_14_bits_s_cmometaw = '0;
    io_msInfo_14_bits_w_releaseack = '0;
    io_msInfo_14_bits_w_replResp = '0;
    io_msInfo_14_bits_w_rprobeacklast = '0;
    io_msInfo_14_bits_replaceData = '0;
    io_msInfo_14_bits_releaseToClean = '0;
    io_msInfo_15_valid = '0;
    io_msInfo_15_bits_set = '0;
    io_msInfo_15_bits_reqTag = '0;
    io_msInfo_15_bits_willFree = '0;
    io_msInfo_15_bits_aliasTask = '0;
    io_msInfo_15_bits_blockRefill = '0;
    io_msInfo_15_bits_meta_dirty = '0;
    io_msInfo_15_bits_meta_state = '0;
    io_msInfo_15_bits_meta_clients = '0;
    io_msInfo_15_bits_meta_alias = '0;
    io_msInfo_15_bits_meta_prefetch = '0;
    io_msInfo_15_bits_meta_prefetchSrc = '0;
    io_msInfo_15_bits_meta_accessed = '0;
    io_msInfo_15_bits_meta_tagErr = '0;
    io_msInfo_15_bits_meta_dataErr = '0;
    io_msInfo_15_bits_metaTag = '0;
    io_msInfo_15_bits_dirHit = '0;
    io_msInfo_15_bits_w_grantfirst = '0;
    io_msInfo_15_bits_s_release = '0;
    io_msInfo_15_bits_s_cmoresp = '0;
    io_msInfo_15_bits_s_cmometaw = '0;
    io_msInfo_15_bits_w_releaseack = '0;
    io_msInfo_15_bits_w_replResp = '0;
    io_msInfo_15_bits_w_rprobeacklast = '0;
    io_msInfo_15_bits_replaceData = '0;
    io_msInfo_15_bits_releaseToClean = '0;
    repeat (5) @(posedge clock);
    reset = 1'b0;
    repeat (NCYCLES) begin
      @(negedge clock);
      drive_random();
      #1 check_outputs();
      @(posedge clock);
    end
    $display("RXSNP checks=%0d errors=%0d", checks, errors);
    if (errors == 0) begin $display("TEST PASSED"); $finish; end
    $display("TEST FAILED"); $fatal(1);
  end
endmodule
`undef CHK
