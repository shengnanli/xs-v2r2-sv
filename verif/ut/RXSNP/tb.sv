// 自动生成：scripts/gen_l2slice_ut.py —— 勿手改（命令行见同目录 Makefile 的 gentb）
// 目标：RXSNP
// golden <T> 与派生 <T>_xs 双例化，同激励逐拍 4 态比全部输出；覆盖闸见文件尾。
`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 200000;
  bit clock = 0;
  always #5 clock = ~clock;
  logic reset;
  longint checks = 0, errors = 0;
  longint cyc = 0;   // 复位释放后的拍号（--narrow 表达式可用它做分相激励）
  function automatic logic [4095:0] rnd(input int w);
    logic [4095:0] v;
    v = '0;
    for (int i = 0; i < w; i += 32) v[i+:32] = $urandom;
    return v;
  endfunction

  // ======================= RXSNP =======================
  logic RXSNP__io_rxsnp_valid;
  logic [3:0] RXSNP__io_rxsnp_bits_qos;
  logic [10:0] RXSNP__io_rxsnp_bits_srcID;
  logic [11:0] RXSNP__io_rxsnp_bits_txnID;
  logic [10:0] RXSNP__io_rxsnp_bits_fwdNID;
  logic [11:0] RXSNP__io_rxsnp_bits_fwdTxnID;
  logic [4:0] RXSNP__io_rxsnp_bits_opcode;
  logic [44:0] RXSNP__io_rxsnp_bits_addr;
  logic RXSNP__io_rxsnp_bits_ns;
  logic RXSNP__io_rxsnp_bits_doNotGoToSD;
  logic RXSNP__io_rxsnp_bits_retToSrc;
  logic RXSNP__io_rxsnp_bits_traceTag;
  logic RXSNP__io_rxsnp_bits_mpam_perfMonGroup;
  logic [8:0] RXSNP__io_rxsnp_bits_mpam_partID;
  logic RXSNP__io_rxsnp_bits_mpam_mpamNS;
  logic RXSNP__io_task_ready;
  logic RXSNP__io_msInfo_0_valid;
  logic [8:0] RXSNP__io_msInfo_0_bits_set;
  logic [30:0] RXSNP__io_msInfo_0_bits_reqTag;
  logic RXSNP__io_msInfo_0_bits_willFree;
  logic RXSNP__io_msInfo_0_bits_aliasTask;
  logic RXSNP__io_msInfo_0_bits_blockRefill;
  logic RXSNP__io_msInfo_0_bits_meta_dirty;
  logic [1:0] RXSNP__io_msInfo_0_bits_meta_state;
  logic RXSNP__io_msInfo_0_bits_meta_clients;
  logic [1:0] RXSNP__io_msInfo_0_bits_meta_alias;
  logic RXSNP__io_msInfo_0_bits_meta_prefetch;
  logic [2:0] RXSNP__io_msInfo_0_bits_meta_prefetchSrc;
  logic RXSNP__io_msInfo_0_bits_meta_accessed;
  logic RXSNP__io_msInfo_0_bits_meta_tagErr;
  logic RXSNP__io_msInfo_0_bits_meta_dataErr;
  logic [30:0] RXSNP__io_msInfo_0_bits_metaTag;
  logic RXSNP__io_msInfo_0_bits_dirHit;
  logic RXSNP__io_msInfo_0_bits_w_grantfirst;
  logic RXSNP__io_msInfo_0_bits_s_release;
  logic RXSNP__io_msInfo_0_bits_s_cmoresp;
  logic RXSNP__io_msInfo_0_bits_s_cmometaw;
  logic RXSNP__io_msInfo_0_bits_w_releaseack;
  logic RXSNP__io_msInfo_0_bits_w_replResp;
  logic RXSNP__io_msInfo_0_bits_w_rprobeacklast;
  logic RXSNP__io_msInfo_0_bits_replaceData;
  logic RXSNP__io_msInfo_0_bits_releaseToClean;
  logic RXSNP__io_msInfo_1_valid;
  logic [8:0] RXSNP__io_msInfo_1_bits_set;
  logic [30:0] RXSNP__io_msInfo_1_bits_reqTag;
  logic RXSNP__io_msInfo_1_bits_willFree;
  logic RXSNP__io_msInfo_1_bits_aliasTask;
  logic RXSNP__io_msInfo_1_bits_blockRefill;
  logic RXSNP__io_msInfo_1_bits_meta_dirty;
  logic [1:0] RXSNP__io_msInfo_1_bits_meta_state;
  logic RXSNP__io_msInfo_1_bits_meta_clients;
  logic [1:0] RXSNP__io_msInfo_1_bits_meta_alias;
  logic RXSNP__io_msInfo_1_bits_meta_prefetch;
  logic [2:0] RXSNP__io_msInfo_1_bits_meta_prefetchSrc;
  logic RXSNP__io_msInfo_1_bits_meta_accessed;
  logic RXSNP__io_msInfo_1_bits_meta_tagErr;
  logic RXSNP__io_msInfo_1_bits_meta_dataErr;
  logic [30:0] RXSNP__io_msInfo_1_bits_metaTag;
  logic RXSNP__io_msInfo_1_bits_dirHit;
  logic RXSNP__io_msInfo_1_bits_w_grantfirst;
  logic RXSNP__io_msInfo_1_bits_s_release;
  logic RXSNP__io_msInfo_1_bits_s_cmoresp;
  logic RXSNP__io_msInfo_1_bits_s_cmometaw;
  logic RXSNP__io_msInfo_1_bits_w_releaseack;
  logic RXSNP__io_msInfo_1_bits_w_replResp;
  logic RXSNP__io_msInfo_1_bits_w_rprobeacklast;
  logic RXSNP__io_msInfo_1_bits_replaceData;
  logic RXSNP__io_msInfo_1_bits_releaseToClean;
  logic RXSNP__io_msInfo_2_valid;
  logic [8:0] RXSNP__io_msInfo_2_bits_set;
  logic [30:0] RXSNP__io_msInfo_2_bits_reqTag;
  logic RXSNP__io_msInfo_2_bits_willFree;
  logic RXSNP__io_msInfo_2_bits_aliasTask;
  logic RXSNP__io_msInfo_2_bits_blockRefill;
  logic RXSNP__io_msInfo_2_bits_meta_dirty;
  logic [1:0] RXSNP__io_msInfo_2_bits_meta_state;
  logic RXSNP__io_msInfo_2_bits_meta_clients;
  logic [1:0] RXSNP__io_msInfo_2_bits_meta_alias;
  logic RXSNP__io_msInfo_2_bits_meta_prefetch;
  logic [2:0] RXSNP__io_msInfo_2_bits_meta_prefetchSrc;
  logic RXSNP__io_msInfo_2_bits_meta_accessed;
  logic RXSNP__io_msInfo_2_bits_meta_tagErr;
  logic RXSNP__io_msInfo_2_bits_meta_dataErr;
  logic [30:0] RXSNP__io_msInfo_2_bits_metaTag;
  logic RXSNP__io_msInfo_2_bits_dirHit;
  logic RXSNP__io_msInfo_2_bits_w_grantfirst;
  logic RXSNP__io_msInfo_2_bits_s_release;
  logic RXSNP__io_msInfo_2_bits_s_cmoresp;
  logic RXSNP__io_msInfo_2_bits_s_cmometaw;
  logic RXSNP__io_msInfo_2_bits_w_releaseack;
  logic RXSNP__io_msInfo_2_bits_w_replResp;
  logic RXSNP__io_msInfo_2_bits_w_rprobeacklast;
  logic RXSNP__io_msInfo_2_bits_replaceData;
  logic RXSNP__io_msInfo_2_bits_releaseToClean;
  logic RXSNP__io_msInfo_3_valid;
  logic [8:0] RXSNP__io_msInfo_3_bits_set;
  logic [30:0] RXSNP__io_msInfo_3_bits_reqTag;
  logic RXSNP__io_msInfo_3_bits_willFree;
  logic RXSNP__io_msInfo_3_bits_aliasTask;
  logic RXSNP__io_msInfo_3_bits_blockRefill;
  logic RXSNP__io_msInfo_3_bits_meta_dirty;
  logic [1:0] RXSNP__io_msInfo_3_bits_meta_state;
  logic RXSNP__io_msInfo_3_bits_meta_clients;
  logic [1:0] RXSNP__io_msInfo_3_bits_meta_alias;
  logic RXSNP__io_msInfo_3_bits_meta_prefetch;
  logic [2:0] RXSNP__io_msInfo_3_bits_meta_prefetchSrc;
  logic RXSNP__io_msInfo_3_bits_meta_accessed;
  logic RXSNP__io_msInfo_3_bits_meta_tagErr;
  logic RXSNP__io_msInfo_3_bits_meta_dataErr;
  logic [30:0] RXSNP__io_msInfo_3_bits_metaTag;
  logic RXSNP__io_msInfo_3_bits_dirHit;
  logic RXSNP__io_msInfo_3_bits_w_grantfirst;
  logic RXSNP__io_msInfo_3_bits_s_release;
  logic RXSNP__io_msInfo_3_bits_s_cmoresp;
  logic RXSNP__io_msInfo_3_bits_s_cmometaw;
  logic RXSNP__io_msInfo_3_bits_w_releaseack;
  logic RXSNP__io_msInfo_3_bits_w_replResp;
  logic RXSNP__io_msInfo_3_bits_w_rprobeacklast;
  logic RXSNP__io_msInfo_3_bits_replaceData;
  logic RXSNP__io_msInfo_3_bits_releaseToClean;
  logic RXSNP__io_msInfo_4_valid;
  logic [8:0] RXSNP__io_msInfo_4_bits_set;
  logic [30:0] RXSNP__io_msInfo_4_bits_reqTag;
  logic RXSNP__io_msInfo_4_bits_willFree;
  logic RXSNP__io_msInfo_4_bits_aliasTask;
  logic RXSNP__io_msInfo_4_bits_blockRefill;
  logic RXSNP__io_msInfo_4_bits_meta_dirty;
  logic [1:0] RXSNP__io_msInfo_4_bits_meta_state;
  logic RXSNP__io_msInfo_4_bits_meta_clients;
  logic [1:0] RXSNP__io_msInfo_4_bits_meta_alias;
  logic RXSNP__io_msInfo_4_bits_meta_prefetch;
  logic [2:0] RXSNP__io_msInfo_4_bits_meta_prefetchSrc;
  logic RXSNP__io_msInfo_4_bits_meta_accessed;
  logic RXSNP__io_msInfo_4_bits_meta_tagErr;
  logic RXSNP__io_msInfo_4_bits_meta_dataErr;
  logic [30:0] RXSNP__io_msInfo_4_bits_metaTag;
  logic RXSNP__io_msInfo_4_bits_dirHit;
  logic RXSNP__io_msInfo_4_bits_w_grantfirst;
  logic RXSNP__io_msInfo_4_bits_s_release;
  logic RXSNP__io_msInfo_4_bits_s_cmoresp;
  logic RXSNP__io_msInfo_4_bits_s_cmometaw;
  logic RXSNP__io_msInfo_4_bits_w_releaseack;
  logic RXSNP__io_msInfo_4_bits_w_replResp;
  logic RXSNP__io_msInfo_4_bits_w_rprobeacklast;
  logic RXSNP__io_msInfo_4_bits_replaceData;
  logic RXSNP__io_msInfo_4_bits_releaseToClean;
  logic RXSNP__io_msInfo_5_valid;
  logic [8:0] RXSNP__io_msInfo_5_bits_set;
  logic [30:0] RXSNP__io_msInfo_5_bits_reqTag;
  logic RXSNP__io_msInfo_5_bits_willFree;
  logic RXSNP__io_msInfo_5_bits_aliasTask;
  logic RXSNP__io_msInfo_5_bits_blockRefill;
  logic RXSNP__io_msInfo_5_bits_meta_dirty;
  logic [1:0] RXSNP__io_msInfo_5_bits_meta_state;
  logic RXSNP__io_msInfo_5_bits_meta_clients;
  logic [1:0] RXSNP__io_msInfo_5_bits_meta_alias;
  logic RXSNP__io_msInfo_5_bits_meta_prefetch;
  logic [2:0] RXSNP__io_msInfo_5_bits_meta_prefetchSrc;
  logic RXSNP__io_msInfo_5_bits_meta_accessed;
  logic RXSNP__io_msInfo_5_bits_meta_tagErr;
  logic RXSNP__io_msInfo_5_bits_meta_dataErr;
  logic [30:0] RXSNP__io_msInfo_5_bits_metaTag;
  logic RXSNP__io_msInfo_5_bits_dirHit;
  logic RXSNP__io_msInfo_5_bits_w_grantfirst;
  logic RXSNP__io_msInfo_5_bits_s_release;
  logic RXSNP__io_msInfo_5_bits_s_cmoresp;
  logic RXSNP__io_msInfo_5_bits_s_cmometaw;
  logic RXSNP__io_msInfo_5_bits_w_releaseack;
  logic RXSNP__io_msInfo_5_bits_w_replResp;
  logic RXSNP__io_msInfo_5_bits_w_rprobeacklast;
  logic RXSNP__io_msInfo_5_bits_replaceData;
  logic RXSNP__io_msInfo_5_bits_releaseToClean;
  logic RXSNP__io_msInfo_6_valid;
  logic [8:0] RXSNP__io_msInfo_6_bits_set;
  logic [30:0] RXSNP__io_msInfo_6_bits_reqTag;
  logic RXSNP__io_msInfo_6_bits_willFree;
  logic RXSNP__io_msInfo_6_bits_aliasTask;
  logic RXSNP__io_msInfo_6_bits_blockRefill;
  logic RXSNP__io_msInfo_6_bits_meta_dirty;
  logic [1:0] RXSNP__io_msInfo_6_bits_meta_state;
  logic RXSNP__io_msInfo_6_bits_meta_clients;
  logic [1:0] RXSNP__io_msInfo_6_bits_meta_alias;
  logic RXSNP__io_msInfo_6_bits_meta_prefetch;
  logic [2:0] RXSNP__io_msInfo_6_bits_meta_prefetchSrc;
  logic RXSNP__io_msInfo_6_bits_meta_accessed;
  logic RXSNP__io_msInfo_6_bits_meta_tagErr;
  logic RXSNP__io_msInfo_6_bits_meta_dataErr;
  logic [30:0] RXSNP__io_msInfo_6_bits_metaTag;
  logic RXSNP__io_msInfo_6_bits_dirHit;
  logic RXSNP__io_msInfo_6_bits_w_grantfirst;
  logic RXSNP__io_msInfo_6_bits_s_release;
  logic RXSNP__io_msInfo_6_bits_s_cmoresp;
  logic RXSNP__io_msInfo_6_bits_s_cmometaw;
  logic RXSNP__io_msInfo_6_bits_w_releaseack;
  logic RXSNP__io_msInfo_6_bits_w_replResp;
  logic RXSNP__io_msInfo_6_bits_w_rprobeacklast;
  logic RXSNP__io_msInfo_6_bits_replaceData;
  logic RXSNP__io_msInfo_6_bits_releaseToClean;
  logic RXSNP__io_msInfo_7_valid;
  logic [8:0] RXSNP__io_msInfo_7_bits_set;
  logic [30:0] RXSNP__io_msInfo_7_bits_reqTag;
  logic RXSNP__io_msInfo_7_bits_willFree;
  logic RXSNP__io_msInfo_7_bits_aliasTask;
  logic RXSNP__io_msInfo_7_bits_blockRefill;
  logic RXSNP__io_msInfo_7_bits_meta_dirty;
  logic [1:0] RXSNP__io_msInfo_7_bits_meta_state;
  logic RXSNP__io_msInfo_7_bits_meta_clients;
  logic [1:0] RXSNP__io_msInfo_7_bits_meta_alias;
  logic RXSNP__io_msInfo_7_bits_meta_prefetch;
  logic [2:0] RXSNP__io_msInfo_7_bits_meta_prefetchSrc;
  logic RXSNP__io_msInfo_7_bits_meta_accessed;
  logic RXSNP__io_msInfo_7_bits_meta_tagErr;
  logic RXSNP__io_msInfo_7_bits_meta_dataErr;
  logic [30:0] RXSNP__io_msInfo_7_bits_metaTag;
  logic RXSNP__io_msInfo_7_bits_dirHit;
  logic RXSNP__io_msInfo_7_bits_w_grantfirst;
  logic RXSNP__io_msInfo_7_bits_s_release;
  logic RXSNP__io_msInfo_7_bits_s_cmoresp;
  logic RXSNP__io_msInfo_7_bits_s_cmometaw;
  logic RXSNP__io_msInfo_7_bits_w_releaseack;
  logic RXSNP__io_msInfo_7_bits_w_replResp;
  logic RXSNP__io_msInfo_7_bits_w_rprobeacklast;
  logic RXSNP__io_msInfo_7_bits_replaceData;
  logic RXSNP__io_msInfo_7_bits_releaseToClean;
  logic RXSNP__io_msInfo_8_valid;
  logic [8:0] RXSNP__io_msInfo_8_bits_set;
  logic [30:0] RXSNP__io_msInfo_8_bits_reqTag;
  logic RXSNP__io_msInfo_8_bits_willFree;
  logic RXSNP__io_msInfo_8_bits_aliasTask;
  logic RXSNP__io_msInfo_8_bits_blockRefill;
  logic RXSNP__io_msInfo_8_bits_meta_dirty;
  logic [1:0] RXSNP__io_msInfo_8_bits_meta_state;
  logic RXSNP__io_msInfo_8_bits_meta_clients;
  logic [1:0] RXSNP__io_msInfo_8_bits_meta_alias;
  logic RXSNP__io_msInfo_8_bits_meta_prefetch;
  logic [2:0] RXSNP__io_msInfo_8_bits_meta_prefetchSrc;
  logic RXSNP__io_msInfo_8_bits_meta_accessed;
  logic RXSNP__io_msInfo_8_bits_meta_tagErr;
  logic RXSNP__io_msInfo_8_bits_meta_dataErr;
  logic [30:0] RXSNP__io_msInfo_8_bits_metaTag;
  logic RXSNP__io_msInfo_8_bits_dirHit;
  logic RXSNP__io_msInfo_8_bits_w_grantfirst;
  logic RXSNP__io_msInfo_8_bits_s_release;
  logic RXSNP__io_msInfo_8_bits_s_cmoresp;
  logic RXSNP__io_msInfo_8_bits_s_cmometaw;
  logic RXSNP__io_msInfo_8_bits_w_releaseack;
  logic RXSNP__io_msInfo_8_bits_w_replResp;
  logic RXSNP__io_msInfo_8_bits_w_rprobeacklast;
  logic RXSNP__io_msInfo_8_bits_replaceData;
  logic RXSNP__io_msInfo_8_bits_releaseToClean;
  logic RXSNP__io_msInfo_9_valid;
  logic [8:0] RXSNP__io_msInfo_9_bits_set;
  logic [30:0] RXSNP__io_msInfo_9_bits_reqTag;
  logic RXSNP__io_msInfo_9_bits_willFree;
  logic RXSNP__io_msInfo_9_bits_aliasTask;
  logic RXSNP__io_msInfo_9_bits_blockRefill;
  logic RXSNP__io_msInfo_9_bits_meta_dirty;
  logic [1:0] RXSNP__io_msInfo_9_bits_meta_state;
  logic RXSNP__io_msInfo_9_bits_meta_clients;
  logic [1:0] RXSNP__io_msInfo_9_bits_meta_alias;
  logic RXSNP__io_msInfo_9_bits_meta_prefetch;
  logic [2:0] RXSNP__io_msInfo_9_bits_meta_prefetchSrc;
  logic RXSNP__io_msInfo_9_bits_meta_accessed;
  logic RXSNP__io_msInfo_9_bits_meta_tagErr;
  logic RXSNP__io_msInfo_9_bits_meta_dataErr;
  logic [30:0] RXSNP__io_msInfo_9_bits_metaTag;
  logic RXSNP__io_msInfo_9_bits_dirHit;
  logic RXSNP__io_msInfo_9_bits_w_grantfirst;
  logic RXSNP__io_msInfo_9_bits_s_release;
  logic RXSNP__io_msInfo_9_bits_s_cmoresp;
  logic RXSNP__io_msInfo_9_bits_s_cmometaw;
  logic RXSNP__io_msInfo_9_bits_w_releaseack;
  logic RXSNP__io_msInfo_9_bits_w_replResp;
  logic RXSNP__io_msInfo_9_bits_w_rprobeacklast;
  logic RXSNP__io_msInfo_9_bits_replaceData;
  logic RXSNP__io_msInfo_9_bits_releaseToClean;
  logic RXSNP__io_msInfo_10_valid;
  logic [8:0] RXSNP__io_msInfo_10_bits_set;
  logic [30:0] RXSNP__io_msInfo_10_bits_reqTag;
  logic RXSNP__io_msInfo_10_bits_willFree;
  logic RXSNP__io_msInfo_10_bits_aliasTask;
  logic RXSNP__io_msInfo_10_bits_blockRefill;
  logic RXSNP__io_msInfo_10_bits_meta_dirty;
  logic [1:0] RXSNP__io_msInfo_10_bits_meta_state;
  logic RXSNP__io_msInfo_10_bits_meta_clients;
  logic [1:0] RXSNP__io_msInfo_10_bits_meta_alias;
  logic RXSNP__io_msInfo_10_bits_meta_prefetch;
  logic [2:0] RXSNP__io_msInfo_10_bits_meta_prefetchSrc;
  logic RXSNP__io_msInfo_10_bits_meta_accessed;
  logic RXSNP__io_msInfo_10_bits_meta_tagErr;
  logic RXSNP__io_msInfo_10_bits_meta_dataErr;
  logic [30:0] RXSNP__io_msInfo_10_bits_metaTag;
  logic RXSNP__io_msInfo_10_bits_dirHit;
  logic RXSNP__io_msInfo_10_bits_w_grantfirst;
  logic RXSNP__io_msInfo_10_bits_s_release;
  logic RXSNP__io_msInfo_10_bits_s_cmoresp;
  logic RXSNP__io_msInfo_10_bits_s_cmometaw;
  logic RXSNP__io_msInfo_10_bits_w_releaseack;
  logic RXSNP__io_msInfo_10_bits_w_replResp;
  logic RXSNP__io_msInfo_10_bits_w_rprobeacklast;
  logic RXSNP__io_msInfo_10_bits_replaceData;
  logic RXSNP__io_msInfo_10_bits_releaseToClean;
  logic RXSNP__io_msInfo_11_valid;
  logic [8:0] RXSNP__io_msInfo_11_bits_set;
  logic [30:0] RXSNP__io_msInfo_11_bits_reqTag;
  logic RXSNP__io_msInfo_11_bits_willFree;
  logic RXSNP__io_msInfo_11_bits_aliasTask;
  logic RXSNP__io_msInfo_11_bits_blockRefill;
  logic RXSNP__io_msInfo_11_bits_meta_dirty;
  logic [1:0] RXSNP__io_msInfo_11_bits_meta_state;
  logic RXSNP__io_msInfo_11_bits_meta_clients;
  logic [1:0] RXSNP__io_msInfo_11_bits_meta_alias;
  logic RXSNP__io_msInfo_11_bits_meta_prefetch;
  logic [2:0] RXSNP__io_msInfo_11_bits_meta_prefetchSrc;
  logic RXSNP__io_msInfo_11_bits_meta_accessed;
  logic RXSNP__io_msInfo_11_bits_meta_tagErr;
  logic RXSNP__io_msInfo_11_bits_meta_dataErr;
  logic [30:0] RXSNP__io_msInfo_11_bits_metaTag;
  logic RXSNP__io_msInfo_11_bits_dirHit;
  logic RXSNP__io_msInfo_11_bits_w_grantfirst;
  logic RXSNP__io_msInfo_11_bits_s_release;
  logic RXSNP__io_msInfo_11_bits_s_cmoresp;
  logic RXSNP__io_msInfo_11_bits_s_cmometaw;
  logic RXSNP__io_msInfo_11_bits_w_releaseack;
  logic RXSNP__io_msInfo_11_bits_w_replResp;
  logic RXSNP__io_msInfo_11_bits_w_rprobeacklast;
  logic RXSNP__io_msInfo_11_bits_replaceData;
  logic RXSNP__io_msInfo_11_bits_releaseToClean;
  logic RXSNP__io_msInfo_12_valid;
  logic [8:0] RXSNP__io_msInfo_12_bits_set;
  logic [30:0] RXSNP__io_msInfo_12_bits_reqTag;
  logic RXSNP__io_msInfo_12_bits_willFree;
  logic RXSNP__io_msInfo_12_bits_aliasTask;
  logic RXSNP__io_msInfo_12_bits_blockRefill;
  logic RXSNP__io_msInfo_12_bits_meta_dirty;
  logic [1:0] RXSNP__io_msInfo_12_bits_meta_state;
  logic RXSNP__io_msInfo_12_bits_meta_clients;
  logic [1:0] RXSNP__io_msInfo_12_bits_meta_alias;
  logic RXSNP__io_msInfo_12_bits_meta_prefetch;
  logic [2:0] RXSNP__io_msInfo_12_bits_meta_prefetchSrc;
  logic RXSNP__io_msInfo_12_bits_meta_accessed;
  logic RXSNP__io_msInfo_12_bits_meta_tagErr;
  logic RXSNP__io_msInfo_12_bits_meta_dataErr;
  logic [30:0] RXSNP__io_msInfo_12_bits_metaTag;
  logic RXSNP__io_msInfo_12_bits_dirHit;
  logic RXSNP__io_msInfo_12_bits_w_grantfirst;
  logic RXSNP__io_msInfo_12_bits_s_release;
  logic RXSNP__io_msInfo_12_bits_s_cmoresp;
  logic RXSNP__io_msInfo_12_bits_s_cmometaw;
  logic RXSNP__io_msInfo_12_bits_w_releaseack;
  logic RXSNP__io_msInfo_12_bits_w_replResp;
  logic RXSNP__io_msInfo_12_bits_w_rprobeacklast;
  logic RXSNP__io_msInfo_12_bits_replaceData;
  logic RXSNP__io_msInfo_12_bits_releaseToClean;
  logic RXSNP__io_msInfo_13_valid;
  logic [8:0] RXSNP__io_msInfo_13_bits_set;
  logic [30:0] RXSNP__io_msInfo_13_bits_reqTag;
  logic RXSNP__io_msInfo_13_bits_willFree;
  logic RXSNP__io_msInfo_13_bits_aliasTask;
  logic RXSNP__io_msInfo_13_bits_blockRefill;
  logic RXSNP__io_msInfo_13_bits_meta_dirty;
  logic [1:0] RXSNP__io_msInfo_13_bits_meta_state;
  logic RXSNP__io_msInfo_13_bits_meta_clients;
  logic [1:0] RXSNP__io_msInfo_13_bits_meta_alias;
  logic RXSNP__io_msInfo_13_bits_meta_prefetch;
  logic [2:0] RXSNP__io_msInfo_13_bits_meta_prefetchSrc;
  logic RXSNP__io_msInfo_13_bits_meta_accessed;
  logic RXSNP__io_msInfo_13_bits_meta_tagErr;
  logic RXSNP__io_msInfo_13_bits_meta_dataErr;
  logic [30:0] RXSNP__io_msInfo_13_bits_metaTag;
  logic RXSNP__io_msInfo_13_bits_dirHit;
  logic RXSNP__io_msInfo_13_bits_w_grantfirst;
  logic RXSNP__io_msInfo_13_bits_s_release;
  logic RXSNP__io_msInfo_13_bits_s_cmoresp;
  logic RXSNP__io_msInfo_13_bits_s_cmometaw;
  logic RXSNP__io_msInfo_13_bits_w_releaseack;
  logic RXSNP__io_msInfo_13_bits_w_replResp;
  logic RXSNP__io_msInfo_13_bits_w_rprobeacklast;
  logic RXSNP__io_msInfo_13_bits_replaceData;
  logic RXSNP__io_msInfo_13_bits_releaseToClean;
  logic RXSNP__io_msInfo_14_valid;
  logic [8:0] RXSNP__io_msInfo_14_bits_set;
  logic [30:0] RXSNP__io_msInfo_14_bits_reqTag;
  logic RXSNP__io_msInfo_14_bits_willFree;
  logic RXSNP__io_msInfo_14_bits_aliasTask;
  logic RXSNP__io_msInfo_14_bits_blockRefill;
  logic RXSNP__io_msInfo_14_bits_meta_dirty;
  logic [1:0] RXSNP__io_msInfo_14_bits_meta_state;
  logic RXSNP__io_msInfo_14_bits_meta_clients;
  logic [1:0] RXSNP__io_msInfo_14_bits_meta_alias;
  logic RXSNP__io_msInfo_14_bits_meta_prefetch;
  logic [2:0] RXSNP__io_msInfo_14_bits_meta_prefetchSrc;
  logic RXSNP__io_msInfo_14_bits_meta_accessed;
  logic RXSNP__io_msInfo_14_bits_meta_tagErr;
  logic RXSNP__io_msInfo_14_bits_meta_dataErr;
  logic [30:0] RXSNP__io_msInfo_14_bits_metaTag;
  logic RXSNP__io_msInfo_14_bits_dirHit;
  logic RXSNP__io_msInfo_14_bits_w_grantfirst;
  logic RXSNP__io_msInfo_14_bits_s_release;
  logic RXSNP__io_msInfo_14_bits_s_cmoresp;
  logic RXSNP__io_msInfo_14_bits_s_cmometaw;
  logic RXSNP__io_msInfo_14_bits_w_releaseack;
  logic RXSNP__io_msInfo_14_bits_w_replResp;
  logic RXSNP__io_msInfo_14_bits_w_rprobeacklast;
  logic RXSNP__io_msInfo_14_bits_replaceData;
  logic RXSNP__io_msInfo_14_bits_releaseToClean;
  logic RXSNP__io_msInfo_15_valid;
  logic [8:0] RXSNP__io_msInfo_15_bits_set;
  logic [30:0] RXSNP__io_msInfo_15_bits_reqTag;
  logic RXSNP__io_msInfo_15_bits_willFree;
  logic RXSNP__io_msInfo_15_bits_aliasTask;
  logic RXSNP__io_msInfo_15_bits_blockRefill;
  logic RXSNP__io_msInfo_15_bits_meta_dirty;
  logic [1:0] RXSNP__io_msInfo_15_bits_meta_state;
  logic RXSNP__io_msInfo_15_bits_meta_clients;
  logic [1:0] RXSNP__io_msInfo_15_bits_meta_alias;
  logic RXSNP__io_msInfo_15_bits_meta_prefetch;
  logic [2:0] RXSNP__io_msInfo_15_bits_meta_prefetchSrc;
  logic RXSNP__io_msInfo_15_bits_meta_accessed;
  logic RXSNP__io_msInfo_15_bits_meta_tagErr;
  logic RXSNP__io_msInfo_15_bits_meta_dataErr;
  logic [30:0] RXSNP__io_msInfo_15_bits_metaTag;
  logic RXSNP__io_msInfo_15_bits_dirHit;
  logic RXSNP__io_msInfo_15_bits_w_grantfirst;
  logic RXSNP__io_msInfo_15_bits_s_release;
  logic RXSNP__io_msInfo_15_bits_s_cmoresp;
  logic RXSNP__io_msInfo_15_bits_s_cmometaw;
  logic RXSNP__io_msInfo_15_bits_w_releaseack;
  logic RXSNP__io_msInfo_15_bits_w_replResp;
  logic RXSNP__io_msInfo_15_bits_w_rprobeacklast;
  logic RXSNP__io_msInfo_15_bits_replaceData;
  logic RXSNP__io_msInfo_15_bits_releaseToClean;
  wire  g_RXSNP__io_rxsnp_ready;
  wire  i_RXSNP__io_rxsnp_ready;
  logic p_RXSNP__io_rxsnp_ready;
  bit   t_RXSNP__io_rxsnp_ready;
  wire  g_RXSNP__io_task_valid;
  wire  i_RXSNP__io_task_valid;
  logic p_RXSNP__io_task_valid;
  bit   t_RXSNP__io_task_valid;
  wire  [8:0] g_RXSNP__io_task_bits_set;
  wire  [8:0] i_RXSNP__io_task_bits_set;
  logic [8:0] p_RXSNP__io_task_bits_set;
  bit   t_RXSNP__io_task_bits_set;
  wire  [30:0] g_RXSNP__io_task_bits_tag;
  wire  [30:0] i_RXSNP__io_task_bits_tag;
  logic [30:0] p_RXSNP__io_task_bits_tag;
  bit   t_RXSNP__io_task_bits_tag;
  wire  [5:0] g_RXSNP__io_task_bits_off;
  wire  [5:0] i_RXSNP__io_task_bits_off;
  logic [5:0] p_RXSNP__io_task_bits_off;
  bit   t_RXSNP__io_task_bits_off;
  wire  g_RXSNP__io_task_bits_snpHitRelease;
  wire  i_RXSNP__io_task_bits_snpHitRelease;
  logic p_RXSNP__io_task_bits_snpHitRelease;
  bit   t_RXSNP__io_task_bits_snpHitRelease;
  wire  g_RXSNP__io_task_bits_snpHitReleaseToInval;
  wire  i_RXSNP__io_task_bits_snpHitReleaseToInval;
  logic p_RXSNP__io_task_bits_snpHitReleaseToInval;
  bit   t_RXSNP__io_task_bits_snpHitReleaseToInval;
  wire  g_RXSNP__io_task_bits_snpHitReleaseToClean;
  wire  i_RXSNP__io_task_bits_snpHitReleaseToClean;
  logic p_RXSNP__io_task_bits_snpHitReleaseToClean;
  bit   t_RXSNP__io_task_bits_snpHitReleaseToClean;
  wire  g_RXSNP__io_task_bits_snpHitReleaseWithData;
  wire  i_RXSNP__io_task_bits_snpHitReleaseWithData;
  logic p_RXSNP__io_task_bits_snpHitReleaseWithData;
  bit   t_RXSNP__io_task_bits_snpHitReleaseWithData;
  wire  [7:0] g_RXSNP__io_task_bits_snpHitReleaseIdx;
  wire  [7:0] i_RXSNP__io_task_bits_snpHitReleaseIdx;
  logic [7:0] p_RXSNP__io_task_bits_snpHitReleaseIdx;
  bit   t_RXSNP__io_task_bits_snpHitReleaseIdx;
  wire  g_RXSNP__io_task_bits_snpHitReleaseMeta_dirty;
  wire  i_RXSNP__io_task_bits_snpHitReleaseMeta_dirty;
  logic p_RXSNP__io_task_bits_snpHitReleaseMeta_dirty;
  bit   t_RXSNP__io_task_bits_snpHitReleaseMeta_dirty;
  wire  [1:0] g_RXSNP__io_task_bits_snpHitReleaseMeta_state;
  wire  [1:0] i_RXSNP__io_task_bits_snpHitReleaseMeta_state;
  logic [1:0] p_RXSNP__io_task_bits_snpHitReleaseMeta_state;
  bit   t_RXSNP__io_task_bits_snpHitReleaseMeta_state;
  wire  g_RXSNP__io_task_bits_snpHitReleaseMeta_clients;
  wire  i_RXSNP__io_task_bits_snpHitReleaseMeta_clients;
  logic p_RXSNP__io_task_bits_snpHitReleaseMeta_clients;
  bit   t_RXSNP__io_task_bits_snpHitReleaseMeta_clients;
  wire  [1:0] g_RXSNP__io_task_bits_snpHitReleaseMeta_alias;
  wire  [1:0] i_RXSNP__io_task_bits_snpHitReleaseMeta_alias;
  logic [1:0] p_RXSNP__io_task_bits_snpHitReleaseMeta_alias;
  bit   t_RXSNP__io_task_bits_snpHitReleaseMeta_alias;
  wire  g_RXSNP__io_task_bits_snpHitReleaseMeta_prefetch;
  wire  i_RXSNP__io_task_bits_snpHitReleaseMeta_prefetch;
  logic p_RXSNP__io_task_bits_snpHitReleaseMeta_prefetch;
  bit   t_RXSNP__io_task_bits_snpHitReleaseMeta_prefetch;
  wire  [2:0] g_RXSNP__io_task_bits_snpHitReleaseMeta_prefetchSrc;
  wire  [2:0] i_RXSNP__io_task_bits_snpHitReleaseMeta_prefetchSrc;
  logic [2:0] p_RXSNP__io_task_bits_snpHitReleaseMeta_prefetchSrc;
  bit   t_RXSNP__io_task_bits_snpHitReleaseMeta_prefetchSrc;
  wire  g_RXSNP__io_task_bits_snpHitReleaseMeta_accessed;
  wire  i_RXSNP__io_task_bits_snpHitReleaseMeta_accessed;
  logic p_RXSNP__io_task_bits_snpHitReleaseMeta_accessed;
  bit   t_RXSNP__io_task_bits_snpHitReleaseMeta_accessed;
  wire  g_RXSNP__io_task_bits_snpHitReleaseMeta_tagErr;
  wire  i_RXSNP__io_task_bits_snpHitReleaseMeta_tagErr;
  logic p_RXSNP__io_task_bits_snpHitReleaseMeta_tagErr;
  bit   t_RXSNP__io_task_bits_snpHitReleaseMeta_tagErr;
  wire  g_RXSNP__io_task_bits_snpHitReleaseMeta_dataErr;
  wire  i_RXSNP__io_task_bits_snpHitReleaseMeta_dataErr;
  logic p_RXSNP__io_task_bits_snpHitReleaseMeta_dataErr;
  bit   t_RXSNP__io_task_bits_snpHitReleaseMeta_dataErr;
  wire  [10:0] g_RXSNP__io_task_bits_srcID;
  wire  [10:0] i_RXSNP__io_task_bits_srcID;
  logic [10:0] p_RXSNP__io_task_bits_srcID;
  bit   t_RXSNP__io_task_bits_srcID;
  wire  [11:0] g_RXSNP__io_task_bits_txnID;
  wire  [11:0] i_RXSNP__io_task_bits_txnID;
  logic [11:0] p_RXSNP__io_task_bits_txnID;
  bit   t_RXSNP__io_task_bits_txnID;
  wire  [10:0] g_RXSNP__io_task_bits_fwdNID;
  wire  [10:0] i_RXSNP__io_task_bits_fwdNID;
  logic [10:0] p_RXSNP__io_task_bits_fwdNID;
  bit   t_RXSNP__io_task_bits_fwdNID;
  wire  [11:0] g_RXSNP__io_task_bits_fwdTxnID;
  wire  [11:0] i_RXSNP__io_task_bits_fwdTxnID;
  logic [11:0] p_RXSNP__io_task_bits_fwdTxnID;
  bit   t_RXSNP__io_task_bits_fwdTxnID;
  wire  [6:0] g_RXSNP__io_task_bits_chiOpcode;
  wire  [6:0] i_RXSNP__io_task_bits_chiOpcode;
  logic [6:0] p_RXSNP__io_task_bits_chiOpcode;
  bit   t_RXSNP__io_task_bits_chiOpcode;
  wire  g_RXSNP__io_task_bits_retToSrc;
  wire  i_RXSNP__io_task_bits_retToSrc;
  logic p_RXSNP__io_task_bits_retToSrc;
  bit   t_RXSNP__io_task_bits_retToSrc;
  wire  g_RXSNP__io_task_bits_traceTag;
  wire  i_RXSNP__io_task_bits_traceTag;
  logic p_RXSNP__io_task_bits_traceTag;
  bit   t_RXSNP__io_task_bits_traceTag;
  RXSNP u_g_RXSNP (
    .clock (clock),
    .reset (reset),
    .io_rxsnp_ready (g_RXSNP__io_rxsnp_ready),
    .io_rxsnp_valid (RXSNP__io_rxsnp_valid),
    .io_rxsnp_bits_qos (RXSNP__io_rxsnp_bits_qos),
    .io_rxsnp_bits_srcID (RXSNP__io_rxsnp_bits_srcID),
    .io_rxsnp_bits_txnID (RXSNP__io_rxsnp_bits_txnID),
    .io_rxsnp_bits_fwdNID (RXSNP__io_rxsnp_bits_fwdNID),
    .io_rxsnp_bits_fwdTxnID (RXSNP__io_rxsnp_bits_fwdTxnID),
    .io_rxsnp_bits_opcode (RXSNP__io_rxsnp_bits_opcode),
    .io_rxsnp_bits_addr (RXSNP__io_rxsnp_bits_addr),
    .io_rxsnp_bits_ns (RXSNP__io_rxsnp_bits_ns),
    .io_rxsnp_bits_doNotGoToSD (RXSNP__io_rxsnp_bits_doNotGoToSD),
    .io_rxsnp_bits_retToSrc (RXSNP__io_rxsnp_bits_retToSrc),
    .io_rxsnp_bits_traceTag (RXSNP__io_rxsnp_bits_traceTag),
    .io_rxsnp_bits_mpam_perfMonGroup (RXSNP__io_rxsnp_bits_mpam_perfMonGroup),
    .io_rxsnp_bits_mpam_partID (RXSNP__io_rxsnp_bits_mpam_partID),
    .io_rxsnp_bits_mpam_mpamNS (RXSNP__io_rxsnp_bits_mpam_mpamNS),
    .io_task_ready (RXSNP__io_task_ready),
    .io_task_valid (g_RXSNP__io_task_valid),
    .io_task_bits_set (g_RXSNP__io_task_bits_set),
    .io_task_bits_tag (g_RXSNP__io_task_bits_tag),
    .io_task_bits_off (g_RXSNP__io_task_bits_off),
    .io_task_bits_snpHitRelease (g_RXSNP__io_task_bits_snpHitRelease),
    .io_task_bits_snpHitReleaseToInval (g_RXSNP__io_task_bits_snpHitReleaseToInval),
    .io_task_bits_snpHitReleaseToClean (g_RXSNP__io_task_bits_snpHitReleaseToClean),
    .io_task_bits_snpHitReleaseWithData (g_RXSNP__io_task_bits_snpHitReleaseWithData),
    .io_task_bits_snpHitReleaseIdx (g_RXSNP__io_task_bits_snpHitReleaseIdx),
    .io_task_bits_snpHitReleaseMeta_dirty (g_RXSNP__io_task_bits_snpHitReleaseMeta_dirty),
    .io_task_bits_snpHitReleaseMeta_state (g_RXSNP__io_task_bits_snpHitReleaseMeta_state),
    .io_task_bits_snpHitReleaseMeta_clients (g_RXSNP__io_task_bits_snpHitReleaseMeta_clients),
    .io_task_bits_snpHitReleaseMeta_alias (g_RXSNP__io_task_bits_snpHitReleaseMeta_alias),
    .io_task_bits_snpHitReleaseMeta_prefetch (g_RXSNP__io_task_bits_snpHitReleaseMeta_prefetch),
    .io_task_bits_snpHitReleaseMeta_prefetchSrc (g_RXSNP__io_task_bits_snpHitReleaseMeta_prefetchSrc),
    .io_task_bits_snpHitReleaseMeta_accessed (g_RXSNP__io_task_bits_snpHitReleaseMeta_accessed),
    .io_task_bits_snpHitReleaseMeta_tagErr (g_RXSNP__io_task_bits_snpHitReleaseMeta_tagErr),
    .io_task_bits_snpHitReleaseMeta_dataErr (g_RXSNP__io_task_bits_snpHitReleaseMeta_dataErr),
    .io_task_bits_srcID (g_RXSNP__io_task_bits_srcID),
    .io_task_bits_txnID (g_RXSNP__io_task_bits_txnID),
    .io_task_bits_fwdNID (g_RXSNP__io_task_bits_fwdNID),
    .io_task_bits_fwdTxnID (g_RXSNP__io_task_bits_fwdTxnID),
    .io_task_bits_chiOpcode (g_RXSNP__io_task_bits_chiOpcode),
    .io_task_bits_retToSrc (g_RXSNP__io_task_bits_retToSrc),
    .io_task_bits_traceTag (g_RXSNP__io_task_bits_traceTag),
    .io_msInfo_0_valid (RXSNP__io_msInfo_0_valid),
    .io_msInfo_0_bits_set (RXSNP__io_msInfo_0_bits_set),
    .io_msInfo_0_bits_reqTag (RXSNP__io_msInfo_0_bits_reqTag),
    .io_msInfo_0_bits_willFree (RXSNP__io_msInfo_0_bits_willFree),
    .io_msInfo_0_bits_aliasTask (RXSNP__io_msInfo_0_bits_aliasTask),
    .io_msInfo_0_bits_blockRefill (RXSNP__io_msInfo_0_bits_blockRefill),
    .io_msInfo_0_bits_meta_dirty (RXSNP__io_msInfo_0_bits_meta_dirty),
    .io_msInfo_0_bits_meta_state (RXSNP__io_msInfo_0_bits_meta_state),
    .io_msInfo_0_bits_meta_clients (RXSNP__io_msInfo_0_bits_meta_clients),
    .io_msInfo_0_bits_meta_alias (RXSNP__io_msInfo_0_bits_meta_alias),
    .io_msInfo_0_bits_meta_prefetch (RXSNP__io_msInfo_0_bits_meta_prefetch),
    .io_msInfo_0_bits_meta_prefetchSrc (RXSNP__io_msInfo_0_bits_meta_prefetchSrc),
    .io_msInfo_0_bits_meta_accessed (RXSNP__io_msInfo_0_bits_meta_accessed),
    .io_msInfo_0_bits_meta_tagErr (RXSNP__io_msInfo_0_bits_meta_tagErr),
    .io_msInfo_0_bits_meta_dataErr (RXSNP__io_msInfo_0_bits_meta_dataErr),
    .io_msInfo_0_bits_metaTag (RXSNP__io_msInfo_0_bits_metaTag),
    .io_msInfo_0_bits_dirHit (RXSNP__io_msInfo_0_bits_dirHit),
    .io_msInfo_0_bits_w_grantfirst (RXSNP__io_msInfo_0_bits_w_grantfirst),
    .io_msInfo_0_bits_s_release (RXSNP__io_msInfo_0_bits_s_release),
    .io_msInfo_0_bits_s_cmoresp (RXSNP__io_msInfo_0_bits_s_cmoresp),
    .io_msInfo_0_bits_s_cmometaw (RXSNP__io_msInfo_0_bits_s_cmometaw),
    .io_msInfo_0_bits_w_releaseack (RXSNP__io_msInfo_0_bits_w_releaseack),
    .io_msInfo_0_bits_w_replResp (RXSNP__io_msInfo_0_bits_w_replResp),
    .io_msInfo_0_bits_w_rprobeacklast (RXSNP__io_msInfo_0_bits_w_rprobeacklast),
    .io_msInfo_0_bits_replaceData (RXSNP__io_msInfo_0_bits_replaceData),
    .io_msInfo_0_bits_releaseToClean (RXSNP__io_msInfo_0_bits_releaseToClean),
    .io_msInfo_1_valid (RXSNP__io_msInfo_1_valid),
    .io_msInfo_1_bits_set (RXSNP__io_msInfo_1_bits_set),
    .io_msInfo_1_bits_reqTag (RXSNP__io_msInfo_1_bits_reqTag),
    .io_msInfo_1_bits_willFree (RXSNP__io_msInfo_1_bits_willFree),
    .io_msInfo_1_bits_aliasTask (RXSNP__io_msInfo_1_bits_aliasTask),
    .io_msInfo_1_bits_blockRefill (RXSNP__io_msInfo_1_bits_blockRefill),
    .io_msInfo_1_bits_meta_dirty (RXSNP__io_msInfo_1_bits_meta_dirty),
    .io_msInfo_1_bits_meta_state (RXSNP__io_msInfo_1_bits_meta_state),
    .io_msInfo_1_bits_meta_clients (RXSNP__io_msInfo_1_bits_meta_clients),
    .io_msInfo_1_bits_meta_alias (RXSNP__io_msInfo_1_bits_meta_alias),
    .io_msInfo_1_bits_meta_prefetch (RXSNP__io_msInfo_1_bits_meta_prefetch),
    .io_msInfo_1_bits_meta_prefetchSrc (RXSNP__io_msInfo_1_bits_meta_prefetchSrc),
    .io_msInfo_1_bits_meta_accessed (RXSNP__io_msInfo_1_bits_meta_accessed),
    .io_msInfo_1_bits_meta_tagErr (RXSNP__io_msInfo_1_bits_meta_tagErr),
    .io_msInfo_1_bits_meta_dataErr (RXSNP__io_msInfo_1_bits_meta_dataErr),
    .io_msInfo_1_bits_metaTag (RXSNP__io_msInfo_1_bits_metaTag),
    .io_msInfo_1_bits_dirHit (RXSNP__io_msInfo_1_bits_dirHit),
    .io_msInfo_1_bits_w_grantfirst (RXSNP__io_msInfo_1_bits_w_grantfirst),
    .io_msInfo_1_bits_s_release (RXSNP__io_msInfo_1_bits_s_release),
    .io_msInfo_1_bits_s_cmoresp (RXSNP__io_msInfo_1_bits_s_cmoresp),
    .io_msInfo_1_bits_s_cmometaw (RXSNP__io_msInfo_1_bits_s_cmometaw),
    .io_msInfo_1_bits_w_releaseack (RXSNP__io_msInfo_1_bits_w_releaseack),
    .io_msInfo_1_bits_w_replResp (RXSNP__io_msInfo_1_bits_w_replResp),
    .io_msInfo_1_bits_w_rprobeacklast (RXSNP__io_msInfo_1_bits_w_rprobeacklast),
    .io_msInfo_1_bits_replaceData (RXSNP__io_msInfo_1_bits_replaceData),
    .io_msInfo_1_bits_releaseToClean (RXSNP__io_msInfo_1_bits_releaseToClean),
    .io_msInfo_2_valid (RXSNP__io_msInfo_2_valid),
    .io_msInfo_2_bits_set (RXSNP__io_msInfo_2_bits_set),
    .io_msInfo_2_bits_reqTag (RXSNP__io_msInfo_2_bits_reqTag),
    .io_msInfo_2_bits_willFree (RXSNP__io_msInfo_2_bits_willFree),
    .io_msInfo_2_bits_aliasTask (RXSNP__io_msInfo_2_bits_aliasTask),
    .io_msInfo_2_bits_blockRefill (RXSNP__io_msInfo_2_bits_blockRefill),
    .io_msInfo_2_bits_meta_dirty (RXSNP__io_msInfo_2_bits_meta_dirty),
    .io_msInfo_2_bits_meta_state (RXSNP__io_msInfo_2_bits_meta_state),
    .io_msInfo_2_bits_meta_clients (RXSNP__io_msInfo_2_bits_meta_clients),
    .io_msInfo_2_bits_meta_alias (RXSNP__io_msInfo_2_bits_meta_alias),
    .io_msInfo_2_bits_meta_prefetch (RXSNP__io_msInfo_2_bits_meta_prefetch),
    .io_msInfo_2_bits_meta_prefetchSrc (RXSNP__io_msInfo_2_bits_meta_prefetchSrc),
    .io_msInfo_2_bits_meta_accessed (RXSNP__io_msInfo_2_bits_meta_accessed),
    .io_msInfo_2_bits_meta_tagErr (RXSNP__io_msInfo_2_bits_meta_tagErr),
    .io_msInfo_2_bits_meta_dataErr (RXSNP__io_msInfo_2_bits_meta_dataErr),
    .io_msInfo_2_bits_metaTag (RXSNP__io_msInfo_2_bits_metaTag),
    .io_msInfo_2_bits_dirHit (RXSNP__io_msInfo_2_bits_dirHit),
    .io_msInfo_2_bits_w_grantfirst (RXSNP__io_msInfo_2_bits_w_grantfirst),
    .io_msInfo_2_bits_s_release (RXSNP__io_msInfo_2_bits_s_release),
    .io_msInfo_2_bits_s_cmoresp (RXSNP__io_msInfo_2_bits_s_cmoresp),
    .io_msInfo_2_bits_s_cmometaw (RXSNP__io_msInfo_2_bits_s_cmometaw),
    .io_msInfo_2_bits_w_releaseack (RXSNP__io_msInfo_2_bits_w_releaseack),
    .io_msInfo_2_bits_w_replResp (RXSNP__io_msInfo_2_bits_w_replResp),
    .io_msInfo_2_bits_w_rprobeacklast (RXSNP__io_msInfo_2_bits_w_rprobeacklast),
    .io_msInfo_2_bits_replaceData (RXSNP__io_msInfo_2_bits_replaceData),
    .io_msInfo_2_bits_releaseToClean (RXSNP__io_msInfo_2_bits_releaseToClean),
    .io_msInfo_3_valid (RXSNP__io_msInfo_3_valid),
    .io_msInfo_3_bits_set (RXSNP__io_msInfo_3_bits_set),
    .io_msInfo_3_bits_reqTag (RXSNP__io_msInfo_3_bits_reqTag),
    .io_msInfo_3_bits_willFree (RXSNP__io_msInfo_3_bits_willFree),
    .io_msInfo_3_bits_aliasTask (RXSNP__io_msInfo_3_bits_aliasTask),
    .io_msInfo_3_bits_blockRefill (RXSNP__io_msInfo_3_bits_blockRefill),
    .io_msInfo_3_bits_meta_dirty (RXSNP__io_msInfo_3_bits_meta_dirty),
    .io_msInfo_3_bits_meta_state (RXSNP__io_msInfo_3_bits_meta_state),
    .io_msInfo_3_bits_meta_clients (RXSNP__io_msInfo_3_bits_meta_clients),
    .io_msInfo_3_bits_meta_alias (RXSNP__io_msInfo_3_bits_meta_alias),
    .io_msInfo_3_bits_meta_prefetch (RXSNP__io_msInfo_3_bits_meta_prefetch),
    .io_msInfo_3_bits_meta_prefetchSrc (RXSNP__io_msInfo_3_bits_meta_prefetchSrc),
    .io_msInfo_3_bits_meta_accessed (RXSNP__io_msInfo_3_bits_meta_accessed),
    .io_msInfo_3_bits_meta_tagErr (RXSNP__io_msInfo_3_bits_meta_tagErr),
    .io_msInfo_3_bits_meta_dataErr (RXSNP__io_msInfo_3_bits_meta_dataErr),
    .io_msInfo_3_bits_metaTag (RXSNP__io_msInfo_3_bits_metaTag),
    .io_msInfo_3_bits_dirHit (RXSNP__io_msInfo_3_bits_dirHit),
    .io_msInfo_3_bits_w_grantfirst (RXSNP__io_msInfo_3_bits_w_grantfirst),
    .io_msInfo_3_bits_s_release (RXSNP__io_msInfo_3_bits_s_release),
    .io_msInfo_3_bits_s_cmoresp (RXSNP__io_msInfo_3_bits_s_cmoresp),
    .io_msInfo_3_bits_s_cmometaw (RXSNP__io_msInfo_3_bits_s_cmometaw),
    .io_msInfo_3_bits_w_releaseack (RXSNP__io_msInfo_3_bits_w_releaseack),
    .io_msInfo_3_bits_w_replResp (RXSNP__io_msInfo_3_bits_w_replResp),
    .io_msInfo_3_bits_w_rprobeacklast (RXSNP__io_msInfo_3_bits_w_rprobeacklast),
    .io_msInfo_3_bits_replaceData (RXSNP__io_msInfo_3_bits_replaceData),
    .io_msInfo_3_bits_releaseToClean (RXSNP__io_msInfo_3_bits_releaseToClean),
    .io_msInfo_4_valid (RXSNP__io_msInfo_4_valid),
    .io_msInfo_4_bits_set (RXSNP__io_msInfo_4_bits_set),
    .io_msInfo_4_bits_reqTag (RXSNP__io_msInfo_4_bits_reqTag),
    .io_msInfo_4_bits_willFree (RXSNP__io_msInfo_4_bits_willFree),
    .io_msInfo_4_bits_aliasTask (RXSNP__io_msInfo_4_bits_aliasTask),
    .io_msInfo_4_bits_blockRefill (RXSNP__io_msInfo_4_bits_blockRefill),
    .io_msInfo_4_bits_meta_dirty (RXSNP__io_msInfo_4_bits_meta_dirty),
    .io_msInfo_4_bits_meta_state (RXSNP__io_msInfo_4_bits_meta_state),
    .io_msInfo_4_bits_meta_clients (RXSNP__io_msInfo_4_bits_meta_clients),
    .io_msInfo_4_bits_meta_alias (RXSNP__io_msInfo_4_bits_meta_alias),
    .io_msInfo_4_bits_meta_prefetch (RXSNP__io_msInfo_4_bits_meta_prefetch),
    .io_msInfo_4_bits_meta_prefetchSrc (RXSNP__io_msInfo_4_bits_meta_prefetchSrc),
    .io_msInfo_4_bits_meta_accessed (RXSNP__io_msInfo_4_bits_meta_accessed),
    .io_msInfo_4_bits_meta_tagErr (RXSNP__io_msInfo_4_bits_meta_tagErr),
    .io_msInfo_4_bits_meta_dataErr (RXSNP__io_msInfo_4_bits_meta_dataErr),
    .io_msInfo_4_bits_metaTag (RXSNP__io_msInfo_4_bits_metaTag),
    .io_msInfo_4_bits_dirHit (RXSNP__io_msInfo_4_bits_dirHit),
    .io_msInfo_4_bits_w_grantfirst (RXSNP__io_msInfo_4_bits_w_grantfirst),
    .io_msInfo_4_bits_s_release (RXSNP__io_msInfo_4_bits_s_release),
    .io_msInfo_4_bits_s_cmoresp (RXSNP__io_msInfo_4_bits_s_cmoresp),
    .io_msInfo_4_bits_s_cmometaw (RXSNP__io_msInfo_4_bits_s_cmometaw),
    .io_msInfo_4_bits_w_releaseack (RXSNP__io_msInfo_4_bits_w_releaseack),
    .io_msInfo_4_bits_w_replResp (RXSNP__io_msInfo_4_bits_w_replResp),
    .io_msInfo_4_bits_w_rprobeacklast (RXSNP__io_msInfo_4_bits_w_rprobeacklast),
    .io_msInfo_4_bits_replaceData (RXSNP__io_msInfo_4_bits_replaceData),
    .io_msInfo_4_bits_releaseToClean (RXSNP__io_msInfo_4_bits_releaseToClean),
    .io_msInfo_5_valid (RXSNP__io_msInfo_5_valid),
    .io_msInfo_5_bits_set (RXSNP__io_msInfo_5_bits_set),
    .io_msInfo_5_bits_reqTag (RXSNP__io_msInfo_5_bits_reqTag),
    .io_msInfo_5_bits_willFree (RXSNP__io_msInfo_5_bits_willFree),
    .io_msInfo_5_bits_aliasTask (RXSNP__io_msInfo_5_bits_aliasTask),
    .io_msInfo_5_bits_blockRefill (RXSNP__io_msInfo_5_bits_blockRefill),
    .io_msInfo_5_bits_meta_dirty (RXSNP__io_msInfo_5_bits_meta_dirty),
    .io_msInfo_5_bits_meta_state (RXSNP__io_msInfo_5_bits_meta_state),
    .io_msInfo_5_bits_meta_clients (RXSNP__io_msInfo_5_bits_meta_clients),
    .io_msInfo_5_bits_meta_alias (RXSNP__io_msInfo_5_bits_meta_alias),
    .io_msInfo_5_bits_meta_prefetch (RXSNP__io_msInfo_5_bits_meta_prefetch),
    .io_msInfo_5_bits_meta_prefetchSrc (RXSNP__io_msInfo_5_bits_meta_prefetchSrc),
    .io_msInfo_5_bits_meta_accessed (RXSNP__io_msInfo_5_bits_meta_accessed),
    .io_msInfo_5_bits_meta_tagErr (RXSNP__io_msInfo_5_bits_meta_tagErr),
    .io_msInfo_5_bits_meta_dataErr (RXSNP__io_msInfo_5_bits_meta_dataErr),
    .io_msInfo_5_bits_metaTag (RXSNP__io_msInfo_5_bits_metaTag),
    .io_msInfo_5_bits_dirHit (RXSNP__io_msInfo_5_bits_dirHit),
    .io_msInfo_5_bits_w_grantfirst (RXSNP__io_msInfo_5_bits_w_grantfirst),
    .io_msInfo_5_bits_s_release (RXSNP__io_msInfo_5_bits_s_release),
    .io_msInfo_5_bits_s_cmoresp (RXSNP__io_msInfo_5_bits_s_cmoresp),
    .io_msInfo_5_bits_s_cmometaw (RXSNP__io_msInfo_5_bits_s_cmometaw),
    .io_msInfo_5_bits_w_releaseack (RXSNP__io_msInfo_5_bits_w_releaseack),
    .io_msInfo_5_bits_w_replResp (RXSNP__io_msInfo_5_bits_w_replResp),
    .io_msInfo_5_bits_w_rprobeacklast (RXSNP__io_msInfo_5_bits_w_rprobeacklast),
    .io_msInfo_5_bits_replaceData (RXSNP__io_msInfo_5_bits_replaceData),
    .io_msInfo_5_bits_releaseToClean (RXSNP__io_msInfo_5_bits_releaseToClean),
    .io_msInfo_6_valid (RXSNP__io_msInfo_6_valid),
    .io_msInfo_6_bits_set (RXSNP__io_msInfo_6_bits_set),
    .io_msInfo_6_bits_reqTag (RXSNP__io_msInfo_6_bits_reqTag),
    .io_msInfo_6_bits_willFree (RXSNP__io_msInfo_6_bits_willFree),
    .io_msInfo_6_bits_aliasTask (RXSNP__io_msInfo_6_bits_aliasTask),
    .io_msInfo_6_bits_blockRefill (RXSNP__io_msInfo_6_bits_blockRefill),
    .io_msInfo_6_bits_meta_dirty (RXSNP__io_msInfo_6_bits_meta_dirty),
    .io_msInfo_6_bits_meta_state (RXSNP__io_msInfo_6_bits_meta_state),
    .io_msInfo_6_bits_meta_clients (RXSNP__io_msInfo_6_bits_meta_clients),
    .io_msInfo_6_bits_meta_alias (RXSNP__io_msInfo_6_bits_meta_alias),
    .io_msInfo_6_bits_meta_prefetch (RXSNP__io_msInfo_6_bits_meta_prefetch),
    .io_msInfo_6_bits_meta_prefetchSrc (RXSNP__io_msInfo_6_bits_meta_prefetchSrc),
    .io_msInfo_6_bits_meta_accessed (RXSNP__io_msInfo_6_bits_meta_accessed),
    .io_msInfo_6_bits_meta_tagErr (RXSNP__io_msInfo_6_bits_meta_tagErr),
    .io_msInfo_6_bits_meta_dataErr (RXSNP__io_msInfo_6_bits_meta_dataErr),
    .io_msInfo_6_bits_metaTag (RXSNP__io_msInfo_6_bits_metaTag),
    .io_msInfo_6_bits_dirHit (RXSNP__io_msInfo_6_bits_dirHit),
    .io_msInfo_6_bits_w_grantfirst (RXSNP__io_msInfo_6_bits_w_grantfirst),
    .io_msInfo_6_bits_s_release (RXSNP__io_msInfo_6_bits_s_release),
    .io_msInfo_6_bits_s_cmoresp (RXSNP__io_msInfo_6_bits_s_cmoresp),
    .io_msInfo_6_bits_s_cmometaw (RXSNP__io_msInfo_6_bits_s_cmometaw),
    .io_msInfo_6_bits_w_releaseack (RXSNP__io_msInfo_6_bits_w_releaseack),
    .io_msInfo_6_bits_w_replResp (RXSNP__io_msInfo_6_bits_w_replResp),
    .io_msInfo_6_bits_w_rprobeacklast (RXSNP__io_msInfo_6_bits_w_rprobeacklast),
    .io_msInfo_6_bits_replaceData (RXSNP__io_msInfo_6_bits_replaceData),
    .io_msInfo_6_bits_releaseToClean (RXSNP__io_msInfo_6_bits_releaseToClean),
    .io_msInfo_7_valid (RXSNP__io_msInfo_7_valid),
    .io_msInfo_7_bits_set (RXSNP__io_msInfo_7_bits_set),
    .io_msInfo_7_bits_reqTag (RXSNP__io_msInfo_7_bits_reqTag),
    .io_msInfo_7_bits_willFree (RXSNP__io_msInfo_7_bits_willFree),
    .io_msInfo_7_bits_aliasTask (RXSNP__io_msInfo_7_bits_aliasTask),
    .io_msInfo_7_bits_blockRefill (RXSNP__io_msInfo_7_bits_blockRefill),
    .io_msInfo_7_bits_meta_dirty (RXSNP__io_msInfo_7_bits_meta_dirty),
    .io_msInfo_7_bits_meta_state (RXSNP__io_msInfo_7_bits_meta_state),
    .io_msInfo_7_bits_meta_clients (RXSNP__io_msInfo_7_bits_meta_clients),
    .io_msInfo_7_bits_meta_alias (RXSNP__io_msInfo_7_bits_meta_alias),
    .io_msInfo_7_bits_meta_prefetch (RXSNP__io_msInfo_7_bits_meta_prefetch),
    .io_msInfo_7_bits_meta_prefetchSrc (RXSNP__io_msInfo_7_bits_meta_prefetchSrc),
    .io_msInfo_7_bits_meta_accessed (RXSNP__io_msInfo_7_bits_meta_accessed),
    .io_msInfo_7_bits_meta_tagErr (RXSNP__io_msInfo_7_bits_meta_tagErr),
    .io_msInfo_7_bits_meta_dataErr (RXSNP__io_msInfo_7_bits_meta_dataErr),
    .io_msInfo_7_bits_metaTag (RXSNP__io_msInfo_7_bits_metaTag),
    .io_msInfo_7_bits_dirHit (RXSNP__io_msInfo_7_bits_dirHit),
    .io_msInfo_7_bits_w_grantfirst (RXSNP__io_msInfo_7_bits_w_grantfirst),
    .io_msInfo_7_bits_s_release (RXSNP__io_msInfo_7_bits_s_release),
    .io_msInfo_7_bits_s_cmoresp (RXSNP__io_msInfo_7_bits_s_cmoresp),
    .io_msInfo_7_bits_s_cmometaw (RXSNP__io_msInfo_7_bits_s_cmometaw),
    .io_msInfo_7_bits_w_releaseack (RXSNP__io_msInfo_7_bits_w_releaseack),
    .io_msInfo_7_bits_w_replResp (RXSNP__io_msInfo_7_bits_w_replResp),
    .io_msInfo_7_bits_w_rprobeacklast (RXSNP__io_msInfo_7_bits_w_rprobeacklast),
    .io_msInfo_7_bits_replaceData (RXSNP__io_msInfo_7_bits_replaceData),
    .io_msInfo_7_bits_releaseToClean (RXSNP__io_msInfo_7_bits_releaseToClean),
    .io_msInfo_8_valid (RXSNP__io_msInfo_8_valid),
    .io_msInfo_8_bits_set (RXSNP__io_msInfo_8_bits_set),
    .io_msInfo_8_bits_reqTag (RXSNP__io_msInfo_8_bits_reqTag),
    .io_msInfo_8_bits_willFree (RXSNP__io_msInfo_8_bits_willFree),
    .io_msInfo_8_bits_aliasTask (RXSNP__io_msInfo_8_bits_aliasTask),
    .io_msInfo_8_bits_blockRefill (RXSNP__io_msInfo_8_bits_blockRefill),
    .io_msInfo_8_bits_meta_dirty (RXSNP__io_msInfo_8_bits_meta_dirty),
    .io_msInfo_8_bits_meta_state (RXSNP__io_msInfo_8_bits_meta_state),
    .io_msInfo_8_bits_meta_clients (RXSNP__io_msInfo_8_bits_meta_clients),
    .io_msInfo_8_bits_meta_alias (RXSNP__io_msInfo_8_bits_meta_alias),
    .io_msInfo_8_bits_meta_prefetch (RXSNP__io_msInfo_8_bits_meta_prefetch),
    .io_msInfo_8_bits_meta_prefetchSrc (RXSNP__io_msInfo_8_bits_meta_prefetchSrc),
    .io_msInfo_8_bits_meta_accessed (RXSNP__io_msInfo_8_bits_meta_accessed),
    .io_msInfo_8_bits_meta_tagErr (RXSNP__io_msInfo_8_bits_meta_tagErr),
    .io_msInfo_8_bits_meta_dataErr (RXSNP__io_msInfo_8_bits_meta_dataErr),
    .io_msInfo_8_bits_metaTag (RXSNP__io_msInfo_8_bits_metaTag),
    .io_msInfo_8_bits_dirHit (RXSNP__io_msInfo_8_bits_dirHit),
    .io_msInfo_8_bits_w_grantfirst (RXSNP__io_msInfo_8_bits_w_grantfirst),
    .io_msInfo_8_bits_s_release (RXSNP__io_msInfo_8_bits_s_release),
    .io_msInfo_8_bits_s_cmoresp (RXSNP__io_msInfo_8_bits_s_cmoresp),
    .io_msInfo_8_bits_s_cmometaw (RXSNP__io_msInfo_8_bits_s_cmometaw),
    .io_msInfo_8_bits_w_releaseack (RXSNP__io_msInfo_8_bits_w_releaseack),
    .io_msInfo_8_bits_w_replResp (RXSNP__io_msInfo_8_bits_w_replResp),
    .io_msInfo_8_bits_w_rprobeacklast (RXSNP__io_msInfo_8_bits_w_rprobeacklast),
    .io_msInfo_8_bits_replaceData (RXSNP__io_msInfo_8_bits_replaceData),
    .io_msInfo_8_bits_releaseToClean (RXSNP__io_msInfo_8_bits_releaseToClean),
    .io_msInfo_9_valid (RXSNP__io_msInfo_9_valid),
    .io_msInfo_9_bits_set (RXSNP__io_msInfo_9_bits_set),
    .io_msInfo_9_bits_reqTag (RXSNP__io_msInfo_9_bits_reqTag),
    .io_msInfo_9_bits_willFree (RXSNP__io_msInfo_9_bits_willFree),
    .io_msInfo_9_bits_aliasTask (RXSNP__io_msInfo_9_bits_aliasTask),
    .io_msInfo_9_bits_blockRefill (RXSNP__io_msInfo_9_bits_blockRefill),
    .io_msInfo_9_bits_meta_dirty (RXSNP__io_msInfo_9_bits_meta_dirty),
    .io_msInfo_9_bits_meta_state (RXSNP__io_msInfo_9_bits_meta_state),
    .io_msInfo_9_bits_meta_clients (RXSNP__io_msInfo_9_bits_meta_clients),
    .io_msInfo_9_bits_meta_alias (RXSNP__io_msInfo_9_bits_meta_alias),
    .io_msInfo_9_bits_meta_prefetch (RXSNP__io_msInfo_9_bits_meta_prefetch),
    .io_msInfo_9_bits_meta_prefetchSrc (RXSNP__io_msInfo_9_bits_meta_prefetchSrc),
    .io_msInfo_9_bits_meta_accessed (RXSNP__io_msInfo_9_bits_meta_accessed),
    .io_msInfo_9_bits_meta_tagErr (RXSNP__io_msInfo_9_bits_meta_tagErr),
    .io_msInfo_9_bits_meta_dataErr (RXSNP__io_msInfo_9_bits_meta_dataErr),
    .io_msInfo_9_bits_metaTag (RXSNP__io_msInfo_9_bits_metaTag),
    .io_msInfo_9_bits_dirHit (RXSNP__io_msInfo_9_bits_dirHit),
    .io_msInfo_9_bits_w_grantfirst (RXSNP__io_msInfo_9_bits_w_grantfirst),
    .io_msInfo_9_bits_s_release (RXSNP__io_msInfo_9_bits_s_release),
    .io_msInfo_9_bits_s_cmoresp (RXSNP__io_msInfo_9_bits_s_cmoresp),
    .io_msInfo_9_bits_s_cmometaw (RXSNP__io_msInfo_9_bits_s_cmometaw),
    .io_msInfo_9_bits_w_releaseack (RXSNP__io_msInfo_9_bits_w_releaseack),
    .io_msInfo_9_bits_w_replResp (RXSNP__io_msInfo_9_bits_w_replResp),
    .io_msInfo_9_bits_w_rprobeacklast (RXSNP__io_msInfo_9_bits_w_rprobeacklast),
    .io_msInfo_9_bits_replaceData (RXSNP__io_msInfo_9_bits_replaceData),
    .io_msInfo_9_bits_releaseToClean (RXSNP__io_msInfo_9_bits_releaseToClean),
    .io_msInfo_10_valid (RXSNP__io_msInfo_10_valid),
    .io_msInfo_10_bits_set (RXSNP__io_msInfo_10_bits_set),
    .io_msInfo_10_bits_reqTag (RXSNP__io_msInfo_10_bits_reqTag),
    .io_msInfo_10_bits_willFree (RXSNP__io_msInfo_10_bits_willFree),
    .io_msInfo_10_bits_aliasTask (RXSNP__io_msInfo_10_bits_aliasTask),
    .io_msInfo_10_bits_blockRefill (RXSNP__io_msInfo_10_bits_blockRefill),
    .io_msInfo_10_bits_meta_dirty (RXSNP__io_msInfo_10_bits_meta_dirty),
    .io_msInfo_10_bits_meta_state (RXSNP__io_msInfo_10_bits_meta_state),
    .io_msInfo_10_bits_meta_clients (RXSNP__io_msInfo_10_bits_meta_clients),
    .io_msInfo_10_bits_meta_alias (RXSNP__io_msInfo_10_bits_meta_alias),
    .io_msInfo_10_bits_meta_prefetch (RXSNP__io_msInfo_10_bits_meta_prefetch),
    .io_msInfo_10_bits_meta_prefetchSrc (RXSNP__io_msInfo_10_bits_meta_prefetchSrc),
    .io_msInfo_10_bits_meta_accessed (RXSNP__io_msInfo_10_bits_meta_accessed),
    .io_msInfo_10_bits_meta_tagErr (RXSNP__io_msInfo_10_bits_meta_tagErr),
    .io_msInfo_10_bits_meta_dataErr (RXSNP__io_msInfo_10_bits_meta_dataErr),
    .io_msInfo_10_bits_metaTag (RXSNP__io_msInfo_10_bits_metaTag),
    .io_msInfo_10_bits_dirHit (RXSNP__io_msInfo_10_bits_dirHit),
    .io_msInfo_10_bits_w_grantfirst (RXSNP__io_msInfo_10_bits_w_grantfirst),
    .io_msInfo_10_bits_s_release (RXSNP__io_msInfo_10_bits_s_release),
    .io_msInfo_10_bits_s_cmoresp (RXSNP__io_msInfo_10_bits_s_cmoresp),
    .io_msInfo_10_bits_s_cmometaw (RXSNP__io_msInfo_10_bits_s_cmometaw),
    .io_msInfo_10_bits_w_releaseack (RXSNP__io_msInfo_10_bits_w_releaseack),
    .io_msInfo_10_bits_w_replResp (RXSNP__io_msInfo_10_bits_w_replResp),
    .io_msInfo_10_bits_w_rprobeacklast (RXSNP__io_msInfo_10_bits_w_rprobeacklast),
    .io_msInfo_10_bits_replaceData (RXSNP__io_msInfo_10_bits_replaceData),
    .io_msInfo_10_bits_releaseToClean (RXSNP__io_msInfo_10_bits_releaseToClean),
    .io_msInfo_11_valid (RXSNP__io_msInfo_11_valid),
    .io_msInfo_11_bits_set (RXSNP__io_msInfo_11_bits_set),
    .io_msInfo_11_bits_reqTag (RXSNP__io_msInfo_11_bits_reqTag),
    .io_msInfo_11_bits_willFree (RXSNP__io_msInfo_11_bits_willFree),
    .io_msInfo_11_bits_aliasTask (RXSNP__io_msInfo_11_bits_aliasTask),
    .io_msInfo_11_bits_blockRefill (RXSNP__io_msInfo_11_bits_blockRefill),
    .io_msInfo_11_bits_meta_dirty (RXSNP__io_msInfo_11_bits_meta_dirty),
    .io_msInfo_11_bits_meta_state (RXSNP__io_msInfo_11_bits_meta_state),
    .io_msInfo_11_bits_meta_clients (RXSNP__io_msInfo_11_bits_meta_clients),
    .io_msInfo_11_bits_meta_alias (RXSNP__io_msInfo_11_bits_meta_alias),
    .io_msInfo_11_bits_meta_prefetch (RXSNP__io_msInfo_11_bits_meta_prefetch),
    .io_msInfo_11_bits_meta_prefetchSrc (RXSNP__io_msInfo_11_bits_meta_prefetchSrc),
    .io_msInfo_11_bits_meta_accessed (RXSNP__io_msInfo_11_bits_meta_accessed),
    .io_msInfo_11_bits_meta_tagErr (RXSNP__io_msInfo_11_bits_meta_tagErr),
    .io_msInfo_11_bits_meta_dataErr (RXSNP__io_msInfo_11_bits_meta_dataErr),
    .io_msInfo_11_bits_metaTag (RXSNP__io_msInfo_11_bits_metaTag),
    .io_msInfo_11_bits_dirHit (RXSNP__io_msInfo_11_bits_dirHit),
    .io_msInfo_11_bits_w_grantfirst (RXSNP__io_msInfo_11_bits_w_grantfirst),
    .io_msInfo_11_bits_s_release (RXSNP__io_msInfo_11_bits_s_release),
    .io_msInfo_11_bits_s_cmoresp (RXSNP__io_msInfo_11_bits_s_cmoresp),
    .io_msInfo_11_bits_s_cmometaw (RXSNP__io_msInfo_11_bits_s_cmometaw),
    .io_msInfo_11_bits_w_releaseack (RXSNP__io_msInfo_11_bits_w_releaseack),
    .io_msInfo_11_bits_w_replResp (RXSNP__io_msInfo_11_bits_w_replResp),
    .io_msInfo_11_bits_w_rprobeacklast (RXSNP__io_msInfo_11_bits_w_rprobeacklast),
    .io_msInfo_11_bits_replaceData (RXSNP__io_msInfo_11_bits_replaceData),
    .io_msInfo_11_bits_releaseToClean (RXSNP__io_msInfo_11_bits_releaseToClean),
    .io_msInfo_12_valid (RXSNP__io_msInfo_12_valid),
    .io_msInfo_12_bits_set (RXSNP__io_msInfo_12_bits_set),
    .io_msInfo_12_bits_reqTag (RXSNP__io_msInfo_12_bits_reqTag),
    .io_msInfo_12_bits_willFree (RXSNP__io_msInfo_12_bits_willFree),
    .io_msInfo_12_bits_aliasTask (RXSNP__io_msInfo_12_bits_aliasTask),
    .io_msInfo_12_bits_blockRefill (RXSNP__io_msInfo_12_bits_blockRefill),
    .io_msInfo_12_bits_meta_dirty (RXSNP__io_msInfo_12_bits_meta_dirty),
    .io_msInfo_12_bits_meta_state (RXSNP__io_msInfo_12_bits_meta_state),
    .io_msInfo_12_bits_meta_clients (RXSNP__io_msInfo_12_bits_meta_clients),
    .io_msInfo_12_bits_meta_alias (RXSNP__io_msInfo_12_bits_meta_alias),
    .io_msInfo_12_bits_meta_prefetch (RXSNP__io_msInfo_12_bits_meta_prefetch),
    .io_msInfo_12_bits_meta_prefetchSrc (RXSNP__io_msInfo_12_bits_meta_prefetchSrc),
    .io_msInfo_12_bits_meta_accessed (RXSNP__io_msInfo_12_bits_meta_accessed),
    .io_msInfo_12_bits_meta_tagErr (RXSNP__io_msInfo_12_bits_meta_tagErr),
    .io_msInfo_12_bits_meta_dataErr (RXSNP__io_msInfo_12_bits_meta_dataErr),
    .io_msInfo_12_bits_metaTag (RXSNP__io_msInfo_12_bits_metaTag),
    .io_msInfo_12_bits_dirHit (RXSNP__io_msInfo_12_bits_dirHit),
    .io_msInfo_12_bits_w_grantfirst (RXSNP__io_msInfo_12_bits_w_grantfirst),
    .io_msInfo_12_bits_s_release (RXSNP__io_msInfo_12_bits_s_release),
    .io_msInfo_12_bits_s_cmoresp (RXSNP__io_msInfo_12_bits_s_cmoresp),
    .io_msInfo_12_bits_s_cmometaw (RXSNP__io_msInfo_12_bits_s_cmometaw),
    .io_msInfo_12_bits_w_releaseack (RXSNP__io_msInfo_12_bits_w_releaseack),
    .io_msInfo_12_bits_w_replResp (RXSNP__io_msInfo_12_bits_w_replResp),
    .io_msInfo_12_bits_w_rprobeacklast (RXSNP__io_msInfo_12_bits_w_rprobeacklast),
    .io_msInfo_12_bits_replaceData (RXSNP__io_msInfo_12_bits_replaceData),
    .io_msInfo_12_bits_releaseToClean (RXSNP__io_msInfo_12_bits_releaseToClean),
    .io_msInfo_13_valid (RXSNP__io_msInfo_13_valid),
    .io_msInfo_13_bits_set (RXSNP__io_msInfo_13_bits_set),
    .io_msInfo_13_bits_reqTag (RXSNP__io_msInfo_13_bits_reqTag),
    .io_msInfo_13_bits_willFree (RXSNP__io_msInfo_13_bits_willFree),
    .io_msInfo_13_bits_aliasTask (RXSNP__io_msInfo_13_bits_aliasTask),
    .io_msInfo_13_bits_blockRefill (RXSNP__io_msInfo_13_bits_blockRefill),
    .io_msInfo_13_bits_meta_dirty (RXSNP__io_msInfo_13_bits_meta_dirty),
    .io_msInfo_13_bits_meta_state (RXSNP__io_msInfo_13_bits_meta_state),
    .io_msInfo_13_bits_meta_clients (RXSNP__io_msInfo_13_bits_meta_clients),
    .io_msInfo_13_bits_meta_alias (RXSNP__io_msInfo_13_bits_meta_alias),
    .io_msInfo_13_bits_meta_prefetch (RXSNP__io_msInfo_13_bits_meta_prefetch),
    .io_msInfo_13_bits_meta_prefetchSrc (RXSNP__io_msInfo_13_bits_meta_prefetchSrc),
    .io_msInfo_13_bits_meta_accessed (RXSNP__io_msInfo_13_bits_meta_accessed),
    .io_msInfo_13_bits_meta_tagErr (RXSNP__io_msInfo_13_bits_meta_tagErr),
    .io_msInfo_13_bits_meta_dataErr (RXSNP__io_msInfo_13_bits_meta_dataErr),
    .io_msInfo_13_bits_metaTag (RXSNP__io_msInfo_13_bits_metaTag),
    .io_msInfo_13_bits_dirHit (RXSNP__io_msInfo_13_bits_dirHit),
    .io_msInfo_13_bits_w_grantfirst (RXSNP__io_msInfo_13_bits_w_grantfirst),
    .io_msInfo_13_bits_s_release (RXSNP__io_msInfo_13_bits_s_release),
    .io_msInfo_13_bits_s_cmoresp (RXSNP__io_msInfo_13_bits_s_cmoresp),
    .io_msInfo_13_bits_s_cmometaw (RXSNP__io_msInfo_13_bits_s_cmometaw),
    .io_msInfo_13_bits_w_releaseack (RXSNP__io_msInfo_13_bits_w_releaseack),
    .io_msInfo_13_bits_w_replResp (RXSNP__io_msInfo_13_bits_w_replResp),
    .io_msInfo_13_bits_w_rprobeacklast (RXSNP__io_msInfo_13_bits_w_rprobeacklast),
    .io_msInfo_13_bits_replaceData (RXSNP__io_msInfo_13_bits_replaceData),
    .io_msInfo_13_bits_releaseToClean (RXSNP__io_msInfo_13_bits_releaseToClean),
    .io_msInfo_14_valid (RXSNP__io_msInfo_14_valid),
    .io_msInfo_14_bits_set (RXSNP__io_msInfo_14_bits_set),
    .io_msInfo_14_bits_reqTag (RXSNP__io_msInfo_14_bits_reqTag),
    .io_msInfo_14_bits_willFree (RXSNP__io_msInfo_14_bits_willFree),
    .io_msInfo_14_bits_aliasTask (RXSNP__io_msInfo_14_bits_aliasTask),
    .io_msInfo_14_bits_blockRefill (RXSNP__io_msInfo_14_bits_blockRefill),
    .io_msInfo_14_bits_meta_dirty (RXSNP__io_msInfo_14_bits_meta_dirty),
    .io_msInfo_14_bits_meta_state (RXSNP__io_msInfo_14_bits_meta_state),
    .io_msInfo_14_bits_meta_clients (RXSNP__io_msInfo_14_bits_meta_clients),
    .io_msInfo_14_bits_meta_alias (RXSNP__io_msInfo_14_bits_meta_alias),
    .io_msInfo_14_bits_meta_prefetch (RXSNP__io_msInfo_14_bits_meta_prefetch),
    .io_msInfo_14_bits_meta_prefetchSrc (RXSNP__io_msInfo_14_bits_meta_prefetchSrc),
    .io_msInfo_14_bits_meta_accessed (RXSNP__io_msInfo_14_bits_meta_accessed),
    .io_msInfo_14_bits_meta_tagErr (RXSNP__io_msInfo_14_bits_meta_tagErr),
    .io_msInfo_14_bits_meta_dataErr (RXSNP__io_msInfo_14_bits_meta_dataErr),
    .io_msInfo_14_bits_metaTag (RXSNP__io_msInfo_14_bits_metaTag),
    .io_msInfo_14_bits_dirHit (RXSNP__io_msInfo_14_bits_dirHit),
    .io_msInfo_14_bits_w_grantfirst (RXSNP__io_msInfo_14_bits_w_grantfirst),
    .io_msInfo_14_bits_s_release (RXSNP__io_msInfo_14_bits_s_release),
    .io_msInfo_14_bits_s_cmoresp (RXSNP__io_msInfo_14_bits_s_cmoresp),
    .io_msInfo_14_bits_s_cmometaw (RXSNP__io_msInfo_14_bits_s_cmometaw),
    .io_msInfo_14_bits_w_releaseack (RXSNP__io_msInfo_14_bits_w_releaseack),
    .io_msInfo_14_bits_w_replResp (RXSNP__io_msInfo_14_bits_w_replResp),
    .io_msInfo_14_bits_w_rprobeacklast (RXSNP__io_msInfo_14_bits_w_rprobeacklast),
    .io_msInfo_14_bits_replaceData (RXSNP__io_msInfo_14_bits_replaceData),
    .io_msInfo_14_bits_releaseToClean (RXSNP__io_msInfo_14_bits_releaseToClean),
    .io_msInfo_15_valid (RXSNP__io_msInfo_15_valid),
    .io_msInfo_15_bits_set (RXSNP__io_msInfo_15_bits_set),
    .io_msInfo_15_bits_reqTag (RXSNP__io_msInfo_15_bits_reqTag),
    .io_msInfo_15_bits_willFree (RXSNP__io_msInfo_15_bits_willFree),
    .io_msInfo_15_bits_aliasTask (RXSNP__io_msInfo_15_bits_aliasTask),
    .io_msInfo_15_bits_blockRefill (RXSNP__io_msInfo_15_bits_blockRefill),
    .io_msInfo_15_bits_meta_dirty (RXSNP__io_msInfo_15_bits_meta_dirty),
    .io_msInfo_15_bits_meta_state (RXSNP__io_msInfo_15_bits_meta_state),
    .io_msInfo_15_bits_meta_clients (RXSNP__io_msInfo_15_bits_meta_clients),
    .io_msInfo_15_bits_meta_alias (RXSNP__io_msInfo_15_bits_meta_alias),
    .io_msInfo_15_bits_meta_prefetch (RXSNP__io_msInfo_15_bits_meta_prefetch),
    .io_msInfo_15_bits_meta_prefetchSrc (RXSNP__io_msInfo_15_bits_meta_prefetchSrc),
    .io_msInfo_15_bits_meta_accessed (RXSNP__io_msInfo_15_bits_meta_accessed),
    .io_msInfo_15_bits_meta_tagErr (RXSNP__io_msInfo_15_bits_meta_tagErr),
    .io_msInfo_15_bits_meta_dataErr (RXSNP__io_msInfo_15_bits_meta_dataErr),
    .io_msInfo_15_bits_metaTag (RXSNP__io_msInfo_15_bits_metaTag),
    .io_msInfo_15_bits_dirHit (RXSNP__io_msInfo_15_bits_dirHit),
    .io_msInfo_15_bits_w_grantfirst (RXSNP__io_msInfo_15_bits_w_grantfirst),
    .io_msInfo_15_bits_s_release (RXSNP__io_msInfo_15_bits_s_release),
    .io_msInfo_15_bits_s_cmoresp (RXSNP__io_msInfo_15_bits_s_cmoresp),
    .io_msInfo_15_bits_s_cmometaw (RXSNP__io_msInfo_15_bits_s_cmometaw),
    .io_msInfo_15_bits_w_releaseack (RXSNP__io_msInfo_15_bits_w_releaseack),
    .io_msInfo_15_bits_w_replResp (RXSNP__io_msInfo_15_bits_w_replResp),
    .io_msInfo_15_bits_w_rprobeacklast (RXSNP__io_msInfo_15_bits_w_rprobeacklast),
    .io_msInfo_15_bits_replaceData (RXSNP__io_msInfo_15_bits_replaceData),
    .io_msInfo_15_bits_releaseToClean (RXSNP__io_msInfo_15_bits_releaseToClean)
  );
  RXSNP_xs u_i_RXSNP (
    .clock (clock),
    .reset (reset),
    .io_rxsnp_ready (i_RXSNP__io_rxsnp_ready),
    .io_rxsnp_valid (RXSNP__io_rxsnp_valid),
    .io_rxsnp_bits_qos (RXSNP__io_rxsnp_bits_qos),
    .io_rxsnp_bits_srcID (RXSNP__io_rxsnp_bits_srcID),
    .io_rxsnp_bits_txnID (RXSNP__io_rxsnp_bits_txnID),
    .io_rxsnp_bits_fwdNID (RXSNP__io_rxsnp_bits_fwdNID),
    .io_rxsnp_bits_fwdTxnID (RXSNP__io_rxsnp_bits_fwdTxnID),
    .io_rxsnp_bits_opcode (RXSNP__io_rxsnp_bits_opcode),
    .io_rxsnp_bits_addr (RXSNP__io_rxsnp_bits_addr),
    .io_rxsnp_bits_ns (RXSNP__io_rxsnp_bits_ns),
    .io_rxsnp_bits_doNotGoToSD (RXSNP__io_rxsnp_bits_doNotGoToSD),
    .io_rxsnp_bits_retToSrc (RXSNP__io_rxsnp_bits_retToSrc),
    .io_rxsnp_bits_traceTag (RXSNP__io_rxsnp_bits_traceTag),
    .io_rxsnp_bits_mpam_perfMonGroup (RXSNP__io_rxsnp_bits_mpam_perfMonGroup),
    .io_rxsnp_bits_mpam_partID (RXSNP__io_rxsnp_bits_mpam_partID),
    .io_rxsnp_bits_mpam_mpamNS (RXSNP__io_rxsnp_bits_mpam_mpamNS),
    .io_task_ready (RXSNP__io_task_ready),
    .io_task_valid (i_RXSNP__io_task_valid),
    .io_task_bits_set (i_RXSNP__io_task_bits_set),
    .io_task_bits_tag (i_RXSNP__io_task_bits_tag),
    .io_task_bits_off (i_RXSNP__io_task_bits_off),
    .io_task_bits_snpHitRelease (i_RXSNP__io_task_bits_snpHitRelease),
    .io_task_bits_snpHitReleaseToInval (i_RXSNP__io_task_bits_snpHitReleaseToInval),
    .io_task_bits_snpHitReleaseToClean (i_RXSNP__io_task_bits_snpHitReleaseToClean),
    .io_task_bits_snpHitReleaseWithData (i_RXSNP__io_task_bits_snpHitReleaseWithData),
    .io_task_bits_snpHitReleaseIdx (i_RXSNP__io_task_bits_snpHitReleaseIdx),
    .io_task_bits_snpHitReleaseMeta_dirty (i_RXSNP__io_task_bits_snpHitReleaseMeta_dirty),
    .io_task_bits_snpHitReleaseMeta_state (i_RXSNP__io_task_bits_snpHitReleaseMeta_state),
    .io_task_bits_snpHitReleaseMeta_clients (i_RXSNP__io_task_bits_snpHitReleaseMeta_clients),
    .io_task_bits_snpHitReleaseMeta_alias (i_RXSNP__io_task_bits_snpHitReleaseMeta_alias),
    .io_task_bits_snpHitReleaseMeta_prefetch (i_RXSNP__io_task_bits_snpHitReleaseMeta_prefetch),
    .io_task_bits_snpHitReleaseMeta_prefetchSrc (i_RXSNP__io_task_bits_snpHitReleaseMeta_prefetchSrc),
    .io_task_bits_snpHitReleaseMeta_accessed (i_RXSNP__io_task_bits_snpHitReleaseMeta_accessed),
    .io_task_bits_snpHitReleaseMeta_tagErr (i_RXSNP__io_task_bits_snpHitReleaseMeta_tagErr),
    .io_task_bits_snpHitReleaseMeta_dataErr (i_RXSNP__io_task_bits_snpHitReleaseMeta_dataErr),
    .io_task_bits_srcID (i_RXSNP__io_task_bits_srcID),
    .io_task_bits_txnID (i_RXSNP__io_task_bits_txnID),
    .io_task_bits_fwdNID (i_RXSNP__io_task_bits_fwdNID),
    .io_task_bits_fwdTxnID (i_RXSNP__io_task_bits_fwdTxnID),
    .io_task_bits_chiOpcode (i_RXSNP__io_task_bits_chiOpcode),
    .io_task_bits_retToSrc (i_RXSNP__io_task_bits_retToSrc),
    .io_task_bits_traceTag (i_RXSNP__io_task_bits_traceTag),
    .io_msInfo_0_valid (RXSNP__io_msInfo_0_valid),
    .io_msInfo_0_bits_set (RXSNP__io_msInfo_0_bits_set),
    .io_msInfo_0_bits_reqTag (RXSNP__io_msInfo_0_bits_reqTag),
    .io_msInfo_0_bits_willFree (RXSNP__io_msInfo_0_bits_willFree),
    .io_msInfo_0_bits_aliasTask (RXSNP__io_msInfo_0_bits_aliasTask),
    .io_msInfo_0_bits_blockRefill (RXSNP__io_msInfo_0_bits_blockRefill),
    .io_msInfo_0_bits_meta_dirty (RXSNP__io_msInfo_0_bits_meta_dirty),
    .io_msInfo_0_bits_meta_state (RXSNP__io_msInfo_0_bits_meta_state),
    .io_msInfo_0_bits_meta_clients (RXSNP__io_msInfo_0_bits_meta_clients),
    .io_msInfo_0_bits_meta_alias (RXSNP__io_msInfo_0_bits_meta_alias),
    .io_msInfo_0_bits_meta_prefetch (RXSNP__io_msInfo_0_bits_meta_prefetch),
    .io_msInfo_0_bits_meta_prefetchSrc (RXSNP__io_msInfo_0_bits_meta_prefetchSrc),
    .io_msInfo_0_bits_meta_accessed (RXSNP__io_msInfo_0_bits_meta_accessed),
    .io_msInfo_0_bits_meta_tagErr (RXSNP__io_msInfo_0_bits_meta_tagErr),
    .io_msInfo_0_bits_meta_dataErr (RXSNP__io_msInfo_0_bits_meta_dataErr),
    .io_msInfo_0_bits_metaTag (RXSNP__io_msInfo_0_bits_metaTag),
    .io_msInfo_0_bits_dirHit (RXSNP__io_msInfo_0_bits_dirHit),
    .io_msInfo_0_bits_w_grantfirst (RXSNP__io_msInfo_0_bits_w_grantfirst),
    .io_msInfo_0_bits_s_release (RXSNP__io_msInfo_0_bits_s_release),
    .io_msInfo_0_bits_s_cmoresp (RXSNP__io_msInfo_0_bits_s_cmoresp),
    .io_msInfo_0_bits_s_cmometaw (RXSNP__io_msInfo_0_bits_s_cmometaw),
    .io_msInfo_0_bits_w_releaseack (RXSNP__io_msInfo_0_bits_w_releaseack),
    .io_msInfo_0_bits_w_replResp (RXSNP__io_msInfo_0_bits_w_replResp),
    .io_msInfo_0_bits_w_rprobeacklast (RXSNP__io_msInfo_0_bits_w_rprobeacklast),
    .io_msInfo_0_bits_replaceData (RXSNP__io_msInfo_0_bits_replaceData),
    .io_msInfo_0_bits_releaseToClean (RXSNP__io_msInfo_0_bits_releaseToClean),
    .io_msInfo_1_valid (RXSNP__io_msInfo_1_valid),
    .io_msInfo_1_bits_set (RXSNP__io_msInfo_1_bits_set),
    .io_msInfo_1_bits_reqTag (RXSNP__io_msInfo_1_bits_reqTag),
    .io_msInfo_1_bits_willFree (RXSNP__io_msInfo_1_bits_willFree),
    .io_msInfo_1_bits_aliasTask (RXSNP__io_msInfo_1_bits_aliasTask),
    .io_msInfo_1_bits_blockRefill (RXSNP__io_msInfo_1_bits_blockRefill),
    .io_msInfo_1_bits_meta_dirty (RXSNP__io_msInfo_1_bits_meta_dirty),
    .io_msInfo_1_bits_meta_state (RXSNP__io_msInfo_1_bits_meta_state),
    .io_msInfo_1_bits_meta_clients (RXSNP__io_msInfo_1_bits_meta_clients),
    .io_msInfo_1_bits_meta_alias (RXSNP__io_msInfo_1_bits_meta_alias),
    .io_msInfo_1_bits_meta_prefetch (RXSNP__io_msInfo_1_bits_meta_prefetch),
    .io_msInfo_1_bits_meta_prefetchSrc (RXSNP__io_msInfo_1_bits_meta_prefetchSrc),
    .io_msInfo_1_bits_meta_accessed (RXSNP__io_msInfo_1_bits_meta_accessed),
    .io_msInfo_1_bits_meta_tagErr (RXSNP__io_msInfo_1_bits_meta_tagErr),
    .io_msInfo_1_bits_meta_dataErr (RXSNP__io_msInfo_1_bits_meta_dataErr),
    .io_msInfo_1_bits_metaTag (RXSNP__io_msInfo_1_bits_metaTag),
    .io_msInfo_1_bits_dirHit (RXSNP__io_msInfo_1_bits_dirHit),
    .io_msInfo_1_bits_w_grantfirst (RXSNP__io_msInfo_1_bits_w_grantfirst),
    .io_msInfo_1_bits_s_release (RXSNP__io_msInfo_1_bits_s_release),
    .io_msInfo_1_bits_s_cmoresp (RXSNP__io_msInfo_1_bits_s_cmoresp),
    .io_msInfo_1_bits_s_cmometaw (RXSNP__io_msInfo_1_bits_s_cmometaw),
    .io_msInfo_1_bits_w_releaseack (RXSNP__io_msInfo_1_bits_w_releaseack),
    .io_msInfo_1_bits_w_replResp (RXSNP__io_msInfo_1_bits_w_replResp),
    .io_msInfo_1_bits_w_rprobeacklast (RXSNP__io_msInfo_1_bits_w_rprobeacklast),
    .io_msInfo_1_bits_replaceData (RXSNP__io_msInfo_1_bits_replaceData),
    .io_msInfo_1_bits_releaseToClean (RXSNP__io_msInfo_1_bits_releaseToClean),
    .io_msInfo_2_valid (RXSNP__io_msInfo_2_valid),
    .io_msInfo_2_bits_set (RXSNP__io_msInfo_2_bits_set),
    .io_msInfo_2_bits_reqTag (RXSNP__io_msInfo_2_bits_reqTag),
    .io_msInfo_2_bits_willFree (RXSNP__io_msInfo_2_bits_willFree),
    .io_msInfo_2_bits_aliasTask (RXSNP__io_msInfo_2_bits_aliasTask),
    .io_msInfo_2_bits_blockRefill (RXSNP__io_msInfo_2_bits_blockRefill),
    .io_msInfo_2_bits_meta_dirty (RXSNP__io_msInfo_2_bits_meta_dirty),
    .io_msInfo_2_bits_meta_state (RXSNP__io_msInfo_2_bits_meta_state),
    .io_msInfo_2_bits_meta_clients (RXSNP__io_msInfo_2_bits_meta_clients),
    .io_msInfo_2_bits_meta_alias (RXSNP__io_msInfo_2_bits_meta_alias),
    .io_msInfo_2_bits_meta_prefetch (RXSNP__io_msInfo_2_bits_meta_prefetch),
    .io_msInfo_2_bits_meta_prefetchSrc (RXSNP__io_msInfo_2_bits_meta_prefetchSrc),
    .io_msInfo_2_bits_meta_accessed (RXSNP__io_msInfo_2_bits_meta_accessed),
    .io_msInfo_2_bits_meta_tagErr (RXSNP__io_msInfo_2_bits_meta_tagErr),
    .io_msInfo_2_bits_meta_dataErr (RXSNP__io_msInfo_2_bits_meta_dataErr),
    .io_msInfo_2_bits_metaTag (RXSNP__io_msInfo_2_bits_metaTag),
    .io_msInfo_2_bits_dirHit (RXSNP__io_msInfo_2_bits_dirHit),
    .io_msInfo_2_bits_w_grantfirst (RXSNP__io_msInfo_2_bits_w_grantfirst),
    .io_msInfo_2_bits_s_release (RXSNP__io_msInfo_2_bits_s_release),
    .io_msInfo_2_bits_s_cmoresp (RXSNP__io_msInfo_2_bits_s_cmoresp),
    .io_msInfo_2_bits_s_cmometaw (RXSNP__io_msInfo_2_bits_s_cmometaw),
    .io_msInfo_2_bits_w_releaseack (RXSNP__io_msInfo_2_bits_w_releaseack),
    .io_msInfo_2_bits_w_replResp (RXSNP__io_msInfo_2_bits_w_replResp),
    .io_msInfo_2_bits_w_rprobeacklast (RXSNP__io_msInfo_2_bits_w_rprobeacklast),
    .io_msInfo_2_bits_replaceData (RXSNP__io_msInfo_2_bits_replaceData),
    .io_msInfo_2_bits_releaseToClean (RXSNP__io_msInfo_2_bits_releaseToClean),
    .io_msInfo_3_valid (RXSNP__io_msInfo_3_valid),
    .io_msInfo_3_bits_set (RXSNP__io_msInfo_3_bits_set),
    .io_msInfo_3_bits_reqTag (RXSNP__io_msInfo_3_bits_reqTag),
    .io_msInfo_3_bits_willFree (RXSNP__io_msInfo_3_bits_willFree),
    .io_msInfo_3_bits_aliasTask (RXSNP__io_msInfo_3_bits_aliasTask),
    .io_msInfo_3_bits_blockRefill (RXSNP__io_msInfo_3_bits_blockRefill),
    .io_msInfo_3_bits_meta_dirty (RXSNP__io_msInfo_3_bits_meta_dirty),
    .io_msInfo_3_bits_meta_state (RXSNP__io_msInfo_3_bits_meta_state),
    .io_msInfo_3_bits_meta_clients (RXSNP__io_msInfo_3_bits_meta_clients),
    .io_msInfo_3_bits_meta_alias (RXSNP__io_msInfo_3_bits_meta_alias),
    .io_msInfo_3_bits_meta_prefetch (RXSNP__io_msInfo_3_bits_meta_prefetch),
    .io_msInfo_3_bits_meta_prefetchSrc (RXSNP__io_msInfo_3_bits_meta_prefetchSrc),
    .io_msInfo_3_bits_meta_accessed (RXSNP__io_msInfo_3_bits_meta_accessed),
    .io_msInfo_3_bits_meta_tagErr (RXSNP__io_msInfo_3_bits_meta_tagErr),
    .io_msInfo_3_bits_meta_dataErr (RXSNP__io_msInfo_3_bits_meta_dataErr),
    .io_msInfo_3_bits_metaTag (RXSNP__io_msInfo_3_bits_metaTag),
    .io_msInfo_3_bits_dirHit (RXSNP__io_msInfo_3_bits_dirHit),
    .io_msInfo_3_bits_w_grantfirst (RXSNP__io_msInfo_3_bits_w_grantfirst),
    .io_msInfo_3_bits_s_release (RXSNP__io_msInfo_3_bits_s_release),
    .io_msInfo_3_bits_s_cmoresp (RXSNP__io_msInfo_3_bits_s_cmoresp),
    .io_msInfo_3_bits_s_cmometaw (RXSNP__io_msInfo_3_bits_s_cmometaw),
    .io_msInfo_3_bits_w_releaseack (RXSNP__io_msInfo_3_bits_w_releaseack),
    .io_msInfo_3_bits_w_replResp (RXSNP__io_msInfo_3_bits_w_replResp),
    .io_msInfo_3_bits_w_rprobeacklast (RXSNP__io_msInfo_3_bits_w_rprobeacklast),
    .io_msInfo_3_bits_replaceData (RXSNP__io_msInfo_3_bits_replaceData),
    .io_msInfo_3_bits_releaseToClean (RXSNP__io_msInfo_3_bits_releaseToClean),
    .io_msInfo_4_valid (RXSNP__io_msInfo_4_valid),
    .io_msInfo_4_bits_set (RXSNP__io_msInfo_4_bits_set),
    .io_msInfo_4_bits_reqTag (RXSNP__io_msInfo_4_bits_reqTag),
    .io_msInfo_4_bits_willFree (RXSNP__io_msInfo_4_bits_willFree),
    .io_msInfo_4_bits_aliasTask (RXSNP__io_msInfo_4_bits_aliasTask),
    .io_msInfo_4_bits_blockRefill (RXSNP__io_msInfo_4_bits_blockRefill),
    .io_msInfo_4_bits_meta_dirty (RXSNP__io_msInfo_4_bits_meta_dirty),
    .io_msInfo_4_bits_meta_state (RXSNP__io_msInfo_4_bits_meta_state),
    .io_msInfo_4_bits_meta_clients (RXSNP__io_msInfo_4_bits_meta_clients),
    .io_msInfo_4_bits_meta_alias (RXSNP__io_msInfo_4_bits_meta_alias),
    .io_msInfo_4_bits_meta_prefetch (RXSNP__io_msInfo_4_bits_meta_prefetch),
    .io_msInfo_4_bits_meta_prefetchSrc (RXSNP__io_msInfo_4_bits_meta_prefetchSrc),
    .io_msInfo_4_bits_meta_accessed (RXSNP__io_msInfo_4_bits_meta_accessed),
    .io_msInfo_4_bits_meta_tagErr (RXSNP__io_msInfo_4_bits_meta_tagErr),
    .io_msInfo_4_bits_meta_dataErr (RXSNP__io_msInfo_4_bits_meta_dataErr),
    .io_msInfo_4_bits_metaTag (RXSNP__io_msInfo_4_bits_metaTag),
    .io_msInfo_4_bits_dirHit (RXSNP__io_msInfo_4_bits_dirHit),
    .io_msInfo_4_bits_w_grantfirst (RXSNP__io_msInfo_4_bits_w_grantfirst),
    .io_msInfo_4_bits_s_release (RXSNP__io_msInfo_4_bits_s_release),
    .io_msInfo_4_bits_s_cmoresp (RXSNP__io_msInfo_4_bits_s_cmoresp),
    .io_msInfo_4_bits_s_cmometaw (RXSNP__io_msInfo_4_bits_s_cmometaw),
    .io_msInfo_4_bits_w_releaseack (RXSNP__io_msInfo_4_bits_w_releaseack),
    .io_msInfo_4_bits_w_replResp (RXSNP__io_msInfo_4_bits_w_replResp),
    .io_msInfo_4_bits_w_rprobeacklast (RXSNP__io_msInfo_4_bits_w_rprobeacklast),
    .io_msInfo_4_bits_replaceData (RXSNP__io_msInfo_4_bits_replaceData),
    .io_msInfo_4_bits_releaseToClean (RXSNP__io_msInfo_4_bits_releaseToClean),
    .io_msInfo_5_valid (RXSNP__io_msInfo_5_valid),
    .io_msInfo_5_bits_set (RXSNP__io_msInfo_5_bits_set),
    .io_msInfo_5_bits_reqTag (RXSNP__io_msInfo_5_bits_reqTag),
    .io_msInfo_5_bits_willFree (RXSNP__io_msInfo_5_bits_willFree),
    .io_msInfo_5_bits_aliasTask (RXSNP__io_msInfo_5_bits_aliasTask),
    .io_msInfo_5_bits_blockRefill (RXSNP__io_msInfo_5_bits_blockRefill),
    .io_msInfo_5_bits_meta_dirty (RXSNP__io_msInfo_5_bits_meta_dirty),
    .io_msInfo_5_bits_meta_state (RXSNP__io_msInfo_5_bits_meta_state),
    .io_msInfo_5_bits_meta_clients (RXSNP__io_msInfo_5_bits_meta_clients),
    .io_msInfo_5_bits_meta_alias (RXSNP__io_msInfo_5_bits_meta_alias),
    .io_msInfo_5_bits_meta_prefetch (RXSNP__io_msInfo_5_bits_meta_prefetch),
    .io_msInfo_5_bits_meta_prefetchSrc (RXSNP__io_msInfo_5_bits_meta_prefetchSrc),
    .io_msInfo_5_bits_meta_accessed (RXSNP__io_msInfo_5_bits_meta_accessed),
    .io_msInfo_5_bits_meta_tagErr (RXSNP__io_msInfo_5_bits_meta_tagErr),
    .io_msInfo_5_bits_meta_dataErr (RXSNP__io_msInfo_5_bits_meta_dataErr),
    .io_msInfo_5_bits_metaTag (RXSNP__io_msInfo_5_bits_metaTag),
    .io_msInfo_5_bits_dirHit (RXSNP__io_msInfo_5_bits_dirHit),
    .io_msInfo_5_bits_w_grantfirst (RXSNP__io_msInfo_5_bits_w_grantfirst),
    .io_msInfo_5_bits_s_release (RXSNP__io_msInfo_5_bits_s_release),
    .io_msInfo_5_bits_s_cmoresp (RXSNP__io_msInfo_5_bits_s_cmoresp),
    .io_msInfo_5_bits_s_cmometaw (RXSNP__io_msInfo_5_bits_s_cmometaw),
    .io_msInfo_5_bits_w_releaseack (RXSNP__io_msInfo_5_bits_w_releaseack),
    .io_msInfo_5_bits_w_replResp (RXSNP__io_msInfo_5_bits_w_replResp),
    .io_msInfo_5_bits_w_rprobeacklast (RXSNP__io_msInfo_5_bits_w_rprobeacklast),
    .io_msInfo_5_bits_replaceData (RXSNP__io_msInfo_5_bits_replaceData),
    .io_msInfo_5_bits_releaseToClean (RXSNP__io_msInfo_5_bits_releaseToClean),
    .io_msInfo_6_valid (RXSNP__io_msInfo_6_valid),
    .io_msInfo_6_bits_set (RXSNP__io_msInfo_6_bits_set),
    .io_msInfo_6_bits_reqTag (RXSNP__io_msInfo_6_bits_reqTag),
    .io_msInfo_6_bits_willFree (RXSNP__io_msInfo_6_bits_willFree),
    .io_msInfo_6_bits_aliasTask (RXSNP__io_msInfo_6_bits_aliasTask),
    .io_msInfo_6_bits_blockRefill (RXSNP__io_msInfo_6_bits_blockRefill),
    .io_msInfo_6_bits_meta_dirty (RXSNP__io_msInfo_6_bits_meta_dirty),
    .io_msInfo_6_bits_meta_state (RXSNP__io_msInfo_6_bits_meta_state),
    .io_msInfo_6_bits_meta_clients (RXSNP__io_msInfo_6_bits_meta_clients),
    .io_msInfo_6_bits_meta_alias (RXSNP__io_msInfo_6_bits_meta_alias),
    .io_msInfo_6_bits_meta_prefetch (RXSNP__io_msInfo_6_bits_meta_prefetch),
    .io_msInfo_6_bits_meta_prefetchSrc (RXSNP__io_msInfo_6_bits_meta_prefetchSrc),
    .io_msInfo_6_bits_meta_accessed (RXSNP__io_msInfo_6_bits_meta_accessed),
    .io_msInfo_6_bits_meta_tagErr (RXSNP__io_msInfo_6_bits_meta_tagErr),
    .io_msInfo_6_bits_meta_dataErr (RXSNP__io_msInfo_6_bits_meta_dataErr),
    .io_msInfo_6_bits_metaTag (RXSNP__io_msInfo_6_bits_metaTag),
    .io_msInfo_6_bits_dirHit (RXSNP__io_msInfo_6_bits_dirHit),
    .io_msInfo_6_bits_w_grantfirst (RXSNP__io_msInfo_6_bits_w_grantfirst),
    .io_msInfo_6_bits_s_release (RXSNP__io_msInfo_6_bits_s_release),
    .io_msInfo_6_bits_s_cmoresp (RXSNP__io_msInfo_6_bits_s_cmoresp),
    .io_msInfo_6_bits_s_cmometaw (RXSNP__io_msInfo_6_bits_s_cmometaw),
    .io_msInfo_6_bits_w_releaseack (RXSNP__io_msInfo_6_bits_w_releaseack),
    .io_msInfo_6_bits_w_replResp (RXSNP__io_msInfo_6_bits_w_replResp),
    .io_msInfo_6_bits_w_rprobeacklast (RXSNP__io_msInfo_6_bits_w_rprobeacklast),
    .io_msInfo_6_bits_replaceData (RXSNP__io_msInfo_6_bits_replaceData),
    .io_msInfo_6_bits_releaseToClean (RXSNP__io_msInfo_6_bits_releaseToClean),
    .io_msInfo_7_valid (RXSNP__io_msInfo_7_valid),
    .io_msInfo_7_bits_set (RXSNP__io_msInfo_7_bits_set),
    .io_msInfo_7_bits_reqTag (RXSNP__io_msInfo_7_bits_reqTag),
    .io_msInfo_7_bits_willFree (RXSNP__io_msInfo_7_bits_willFree),
    .io_msInfo_7_bits_aliasTask (RXSNP__io_msInfo_7_bits_aliasTask),
    .io_msInfo_7_bits_blockRefill (RXSNP__io_msInfo_7_bits_blockRefill),
    .io_msInfo_7_bits_meta_dirty (RXSNP__io_msInfo_7_bits_meta_dirty),
    .io_msInfo_7_bits_meta_state (RXSNP__io_msInfo_7_bits_meta_state),
    .io_msInfo_7_bits_meta_clients (RXSNP__io_msInfo_7_bits_meta_clients),
    .io_msInfo_7_bits_meta_alias (RXSNP__io_msInfo_7_bits_meta_alias),
    .io_msInfo_7_bits_meta_prefetch (RXSNP__io_msInfo_7_bits_meta_prefetch),
    .io_msInfo_7_bits_meta_prefetchSrc (RXSNP__io_msInfo_7_bits_meta_prefetchSrc),
    .io_msInfo_7_bits_meta_accessed (RXSNP__io_msInfo_7_bits_meta_accessed),
    .io_msInfo_7_bits_meta_tagErr (RXSNP__io_msInfo_7_bits_meta_tagErr),
    .io_msInfo_7_bits_meta_dataErr (RXSNP__io_msInfo_7_bits_meta_dataErr),
    .io_msInfo_7_bits_metaTag (RXSNP__io_msInfo_7_bits_metaTag),
    .io_msInfo_7_bits_dirHit (RXSNP__io_msInfo_7_bits_dirHit),
    .io_msInfo_7_bits_w_grantfirst (RXSNP__io_msInfo_7_bits_w_grantfirst),
    .io_msInfo_7_bits_s_release (RXSNP__io_msInfo_7_bits_s_release),
    .io_msInfo_7_bits_s_cmoresp (RXSNP__io_msInfo_7_bits_s_cmoresp),
    .io_msInfo_7_bits_s_cmometaw (RXSNP__io_msInfo_7_bits_s_cmometaw),
    .io_msInfo_7_bits_w_releaseack (RXSNP__io_msInfo_7_bits_w_releaseack),
    .io_msInfo_7_bits_w_replResp (RXSNP__io_msInfo_7_bits_w_replResp),
    .io_msInfo_7_bits_w_rprobeacklast (RXSNP__io_msInfo_7_bits_w_rprobeacklast),
    .io_msInfo_7_bits_replaceData (RXSNP__io_msInfo_7_bits_replaceData),
    .io_msInfo_7_bits_releaseToClean (RXSNP__io_msInfo_7_bits_releaseToClean),
    .io_msInfo_8_valid (RXSNP__io_msInfo_8_valid),
    .io_msInfo_8_bits_set (RXSNP__io_msInfo_8_bits_set),
    .io_msInfo_8_bits_reqTag (RXSNP__io_msInfo_8_bits_reqTag),
    .io_msInfo_8_bits_willFree (RXSNP__io_msInfo_8_bits_willFree),
    .io_msInfo_8_bits_aliasTask (RXSNP__io_msInfo_8_bits_aliasTask),
    .io_msInfo_8_bits_blockRefill (RXSNP__io_msInfo_8_bits_blockRefill),
    .io_msInfo_8_bits_meta_dirty (RXSNP__io_msInfo_8_bits_meta_dirty),
    .io_msInfo_8_bits_meta_state (RXSNP__io_msInfo_8_bits_meta_state),
    .io_msInfo_8_bits_meta_clients (RXSNP__io_msInfo_8_bits_meta_clients),
    .io_msInfo_8_bits_meta_alias (RXSNP__io_msInfo_8_bits_meta_alias),
    .io_msInfo_8_bits_meta_prefetch (RXSNP__io_msInfo_8_bits_meta_prefetch),
    .io_msInfo_8_bits_meta_prefetchSrc (RXSNP__io_msInfo_8_bits_meta_prefetchSrc),
    .io_msInfo_8_bits_meta_accessed (RXSNP__io_msInfo_8_bits_meta_accessed),
    .io_msInfo_8_bits_meta_tagErr (RXSNP__io_msInfo_8_bits_meta_tagErr),
    .io_msInfo_8_bits_meta_dataErr (RXSNP__io_msInfo_8_bits_meta_dataErr),
    .io_msInfo_8_bits_metaTag (RXSNP__io_msInfo_8_bits_metaTag),
    .io_msInfo_8_bits_dirHit (RXSNP__io_msInfo_8_bits_dirHit),
    .io_msInfo_8_bits_w_grantfirst (RXSNP__io_msInfo_8_bits_w_grantfirst),
    .io_msInfo_8_bits_s_release (RXSNP__io_msInfo_8_bits_s_release),
    .io_msInfo_8_bits_s_cmoresp (RXSNP__io_msInfo_8_bits_s_cmoresp),
    .io_msInfo_8_bits_s_cmometaw (RXSNP__io_msInfo_8_bits_s_cmometaw),
    .io_msInfo_8_bits_w_releaseack (RXSNP__io_msInfo_8_bits_w_releaseack),
    .io_msInfo_8_bits_w_replResp (RXSNP__io_msInfo_8_bits_w_replResp),
    .io_msInfo_8_bits_w_rprobeacklast (RXSNP__io_msInfo_8_bits_w_rprobeacklast),
    .io_msInfo_8_bits_replaceData (RXSNP__io_msInfo_8_bits_replaceData),
    .io_msInfo_8_bits_releaseToClean (RXSNP__io_msInfo_8_bits_releaseToClean),
    .io_msInfo_9_valid (RXSNP__io_msInfo_9_valid),
    .io_msInfo_9_bits_set (RXSNP__io_msInfo_9_bits_set),
    .io_msInfo_9_bits_reqTag (RXSNP__io_msInfo_9_bits_reqTag),
    .io_msInfo_9_bits_willFree (RXSNP__io_msInfo_9_bits_willFree),
    .io_msInfo_9_bits_aliasTask (RXSNP__io_msInfo_9_bits_aliasTask),
    .io_msInfo_9_bits_blockRefill (RXSNP__io_msInfo_9_bits_blockRefill),
    .io_msInfo_9_bits_meta_dirty (RXSNP__io_msInfo_9_bits_meta_dirty),
    .io_msInfo_9_bits_meta_state (RXSNP__io_msInfo_9_bits_meta_state),
    .io_msInfo_9_bits_meta_clients (RXSNP__io_msInfo_9_bits_meta_clients),
    .io_msInfo_9_bits_meta_alias (RXSNP__io_msInfo_9_bits_meta_alias),
    .io_msInfo_9_bits_meta_prefetch (RXSNP__io_msInfo_9_bits_meta_prefetch),
    .io_msInfo_9_bits_meta_prefetchSrc (RXSNP__io_msInfo_9_bits_meta_prefetchSrc),
    .io_msInfo_9_bits_meta_accessed (RXSNP__io_msInfo_9_bits_meta_accessed),
    .io_msInfo_9_bits_meta_tagErr (RXSNP__io_msInfo_9_bits_meta_tagErr),
    .io_msInfo_9_bits_meta_dataErr (RXSNP__io_msInfo_9_bits_meta_dataErr),
    .io_msInfo_9_bits_metaTag (RXSNP__io_msInfo_9_bits_metaTag),
    .io_msInfo_9_bits_dirHit (RXSNP__io_msInfo_9_bits_dirHit),
    .io_msInfo_9_bits_w_grantfirst (RXSNP__io_msInfo_9_bits_w_grantfirst),
    .io_msInfo_9_bits_s_release (RXSNP__io_msInfo_9_bits_s_release),
    .io_msInfo_9_bits_s_cmoresp (RXSNP__io_msInfo_9_bits_s_cmoresp),
    .io_msInfo_9_bits_s_cmometaw (RXSNP__io_msInfo_9_bits_s_cmometaw),
    .io_msInfo_9_bits_w_releaseack (RXSNP__io_msInfo_9_bits_w_releaseack),
    .io_msInfo_9_bits_w_replResp (RXSNP__io_msInfo_9_bits_w_replResp),
    .io_msInfo_9_bits_w_rprobeacklast (RXSNP__io_msInfo_9_bits_w_rprobeacklast),
    .io_msInfo_9_bits_replaceData (RXSNP__io_msInfo_9_bits_replaceData),
    .io_msInfo_9_bits_releaseToClean (RXSNP__io_msInfo_9_bits_releaseToClean),
    .io_msInfo_10_valid (RXSNP__io_msInfo_10_valid),
    .io_msInfo_10_bits_set (RXSNP__io_msInfo_10_bits_set),
    .io_msInfo_10_bits_reqTag (RXSNP__io_msInfo_10_bits_reqTag),
    .io_msInfo_10_bits_willFree (RXSNP__io_msInfo_10_bits_willFree),
    .io_msInfo_10_bits_aliasTask (RXSNP__io_msInfo_10_bits_aliasTask),
    .io_msInfo_10_bits_blockRefill (RXSNP__io_msInfo_10_bits_blockRefill),
    .io_msInfo_10_bits_meta_dirty (RXSNP__io_msInfo_10_bits_meta_dirty),
    .io_msInfo_10_bits_meta_state (RXSNP__io_msInfo_10_bits_meta_state),
    .io_msInfo_10_bits_meta_clients (RXSNP__io_msInfo_10_bits_meta_clients),
    .io_msInfo_10_bits_meta_alias (RXSNP__io_msInfo_10_bits_meta_alias),
    .io_msInfo_10_bits_meta_prefetch (RXSNP__io_msInfo_10_bits_meta_prefetch),
    .io_msInfo_10_bits_meta_prefetchSrc (RXSNP__io_msInfo_10_bits_meta_prefetchSrc),
    .io_msInfo_10_bits_meta_accessed (RXSNP__io_msInfo_10_bits_meta_accessed),
    .io_msInfo_10_bits_meta_tagErr (RXSNP__io_msInfo_10_bits_meta_tagErr),
    .io_msInfo_10_bits_meta_dataErr (RXSNP__io_msInfo_10_bits_meta_dataErr),
    .io_msInfo_10_bits_metaTag (RXSNP__io_msInfo_10_bits_metaTag),
    .io_msInfo_10_bits_dirHit (RXSNP__io_msInfo_10_bits_dirHit),
    .io_msInfo_10_bits_w_grantfirst (RXSNP__io_msInfo_10_bits_w_grantfirst),
    .io_msInfo_10_bits_s_release (RXSNP__io_msInfo_10_bits_s_release),
    .io_msInfo_10_bits_s_cmoresp (RXSNP__io_msInfo_10_bits_s_cmoresp),
    .io_msInfo_10_bits_s_cmometaw (RXSNP__io_msInfo_10_bits_s_cmometaw),
    .io_msInfo_10_bits_w_releaseack (RXSNP__io_msInfo_10_bits_w_releaseack),
    .io_msInfo_10_bits_w_replResp (RXSNP__io_msInfo_10_bits_w_replResp),
    .io_msInfo_10_bits_w_rprobeacklast (RXSNP__io_msInfo_10_bits_w_rprobeacklast),
    .io_msInfo_10_bits_replaceData (RXSNP__io_msInfo_10_bits_replaceData),
    .io_msInfo_10_bits_releaseToClean (RXSNP__io_msInfo_10_bits_releaseToClean),
    .io_msInfo_11_valid (RXSNP__io_msInfo_11_valid),
    .io_msInfo_11_bits_set (RXSNP__io_msInfo_11_bits_set),
    .io_msInfo_11_bits_reqTag (RXSNP__io_msInfo_11_bits_reqTag),
    .io_msInfo_11_bits_willFree (RXSNP__io_msInfo_11_bits_willFree),
    .io_msInfo_11_bits_aliasTask (RXSNP__io_msInfo_11_bits_aliasTask),
    .io_msInfo_11_bits_blockRefill (RXSNP__io_msInfo_11_bits_blockRefill),
    .io_msInfo_11_bits_meta_dirty (RXSNP__io_msInfo_11_bits_meta_dirty),
    .io_msInfo_11_bits_meta_state (RXSNP__io_msInfo_11_bits_meta_state),
    .io_msInfo_11_bits_meta_clients (RXSNP__io_msInfo_11_bits_meta_clients),
    .io_msInfo_11_bits_meta_alias (RXSNP__io_msInfo_11_bits_meta_alias),
    .io_msInfo_11_bits_meta_prefetch (RXSNP__io_msInfo_11_bits_meta_prefetch),
    .io_msInfo_11_bits_meta_prefetchSrc (RXSNP__io_msInfo_11_bits_meta_prefetchSrc),
    .io_msInfo_11_bits_meta_accessed (RXSNP__io_msInfo_11_bits_meta_accessed),
    .io_msInfo_11_bits_meta_tagErr (RXSNP__io_msInfo_11_bits_meta_tagErr),
    .io_msInfo_11_bits_meta_dataErr (RXSNP__io_msInfo_11_bits_meta_dataErr),
    .io_msInfo_11_bits_metaTag (RXSNP__io_msInfo_11_bits_metaTag),
    .io_msInfo_11_bits_dirHit (RXSNP__io_msInfo_11_bits_dirHit),
    .io_msInfo_11_bits_w_grantfirst (RXSNP__io_msInfo_11_bits_w_grantfirst),
    .io_msInfo_11_bits_s_release (RXSNP__io_msInfo_11_bits_s_release),
    .io_msInfo_11_bits_s_cmoresp (RXSNP__io_msInfo_11_bits_s_cmoresp),
    .io_msInfo_11_bits_s_cmometaw (RXSNP__io_msInfo_11_bits_s_cmometaw),
    .io_msInfo_11_bits_w_releaseack (RXSNP__io_msInfo_11_bits_w_releaseack),
    .io_msInfo_11_bits_w_replResp (RXSNP__io_msInfo_11_bits_w_replResp),
    .io_msInfo_11_bits_w_rprobeacklast (RXSNP__io_msInfo_11_bits_w_rprobeacklast),
    .io_msInfo_11_bits_replaceData (RXSNP__io_msInfo_11_bits_replaceData),
    .io_msInfo_11_bits_releaseToClean (RXSNP__io_msInfo_11_bits_releaseToClean),
    .io_msInfo_12_valid (RXSNP__io_msInfo_12_valid),
    .io_msInfo_12_bits_set (RXSNP__io_msInfo_12_bits_set),
    .io_msInfo_12_bits_reqTag (RXSNP__io_msInfo_12_bits_reqTag),
    .io_msInfo_12_bits_willFree (RXSNP__io_msInfo_12_bits_willFree),
    .io_msInfo_12_bits_aliasTask (RXSNP__io_msInfo_12_bits_aliasTask),
    .io_msInfo_12_bits_blockRefill (RXSNP__io_msInfo_12_bits_blockRefill),
    .io_msInfo_12_bits_meta_dirty (RXSNP__io_msInfo_12_bits_meta_dirty),
    .io_msInfo_12_bits_meta_state (RXSNP__io_msInfo_12_bits_meta_state),
    .io_msInfo_12_bits_meta_clients (RXSNP__io_msInfo_12_bits_meta_clients),
    .io_msInfo_12_bits_meta_alias (RXSNP__io_msInfo_12_bits_meta_alias),
    .io_msInfo_12_bits_meta_prefetch (RXSNP__io_msInfo_12_bits_meta_prefetch),
    .io_msInfo_12_bits_meta_prefetchSrc (RXSNP__io_msInfo_12_bits_meta_prefetchSrc),
    .io_msInfo_12_bits_meta_accessed (RXSNP__io_msInfo_12_bits_meta_accessed),
    .io_msInfo_12_bits_meta_tagErr (RXSNP__io_msInfo_12_bits_meta_tagErr),
    .io_msInfo_12_bits_meta_dataErr (RXSNP__io_msInfo_12_bits_meta_dataErr),
    .io_msInfo_12_bits_metaTag (RXSNP__io_msInfo_12_bits_metaTag),
    .io_msInfo_12_bits_dirHit (RXSNP__io_msInfo_12_bits_dirHit),
    .io_msInfo_12_bits_w_grantfirst (RXSNP__io_msInfo_12_bits_w_grantfirst),
    .io_msInfo_12_bits_s_release (RXSNP__io_msInfo_12_bits_s_release),
    .io_msInfo_12_bits_s_cmoresp (RXSNP__io_msInfo_12_bits_s_cmoresp),
    .io_msInfo_12_bits_s_cmometaw (RXSNP__io_msInfo_12_bits_s_cmometaw),
    .io_msInfo_12_bits_w_releaseack (RXSNP__io_msInfo_12_bits_w_releaseack),
    .io_msInfo_12_bits_w_replResp (RXSNP__io_msInfo_12_bits_w_replResp),
    .io_msInfo_12_bits_w_rprobeacklast (RXSNP__io_msInfo_12_bits_w_rprobeacklast),
    .io_msInfo_12_bits_replaceData (RXSNP__io_msInfo_12_bits_replaceData),
    .io_msInfo_12_bits_releaseToClean (RXSNP__io_msInfo_12_bits_releaseToClean),
    .io_msInfo_13_valid (RXSNP__io_msInfo_13_valid),
    .io_msInfo_13_bits_set (RXSNP__io_msInfo_13_bits_set),
    .io_msInfo_13_bits_reqTag (RXSNP__io_msInfo_13_bits_reqTag),
    .io_msInfo_13_bits_willFree (RXSNP__io_msInfo_13_bits_willFree),
    .io_msInfo_13_bits_aliasTask (RXSNP__io_msInfo_13_bits_aliasTask),
    .io_msInfo_13_bits_blockRefill (RXSNP__io_msInfo_13_bits_blockRefill),
    .io_msInfo_13_bits_meta_dirty (RXSNP__io_msInfo_13_bits_meta_dirty),
    .io_msInfo_13_bits_meta_state (RXSNP__io_msInfo_13_bits_meta_state),
    .io_msInfo_13_bits_meta_clients (RXSNP__io_msInfo_13_bits_meta_clients),
    .io_msInfo_13_bits_meta_alias (RXSNP__io_msInfo_13_bits_meta_alias),
    .io_msInfo_13_bits_meta_prefetch (RXSNP__io_msInfo_13_bits_meta_prefetch),
    .io_msInfo_13_bits_meta_prefetchSrc (RXSNP__io_msInfo_13_bits_meta_prefetchSrc),
    .io_msInfo_13_bits_meta_accessed (RXSNP__io_msInfo_13_bits_meta_accessed),
    .io_msInfo_13_bits_meta_tagErr (RXSNP__io_msInfo_13_bits_meta_tagErr),
    .io_msInfo_13_bits_meta_dataErr (RXSNP__io_msInfo_13_bits_meta_dataErr),
    .io_msInfo_13_bits_metaTag (RXSNP__io_msInfo_13_bits_metaTag),
    .io_msInfo_13_bits_dirHit (RXSNP__io_msInfo_13_bits_dirHit),
    .io_msInfo_13_bits_w_grantfirst (RXSNP__io_msInfo_13_bits_w_grantfirst),
    .io_msInfo_13_bits_s_release (RXSNP__io_msInfo_13_bits_s_release),
    .io_msInfo_13_bits_s_cmoresp (RXSNP__io_msInfo_13_bits_s_cmoresp),
    .io_msInfo_13_bits_s_cmometaw (RXSNP__io_msInfo_13_bits_s_cmometaw),
    .io_msInfo_13_bits_w_releaseack (RXSNP__io_msInfo_13_bits_w_releaseack),
    .io_msInfo_13_bits_w_replResp (RXSNP__io_msInfo_13_bits_w_replResp),
    .io_msInfo_13_bits_w_rprobeacklast (RXSNP__io_msInfo_13_bits_w_rprobeacklast),
    .io_msInfo_13_bits_replaceData (RXSNP__io_msInfo_13_bits_replaceData),
    .io_msInfo_13_bits_releaseToClean (RXSNP__io_msInfo_13_bits_releaseToClean),
    .io_msInfo_14_valid (RXSNP__io_msInfo_14_valid),
    .io_msInfo_14_bits_set (RXSNP__io_msInfo_14_bits_set),
    .io_msInfo_14_bits_reqTag (RXSNP__io_msInfo_14_bits_reqTag),
    .io_msInfo_14_bits_willFree (RXSNP__io_msInfo_14_bits_willFree),
    .io_msInfo_14_bits_aliasTask (RXSNP__io_msInfo_14_bits_aliasTask),
    .io_msInfo_14_bits_blockRefill (RXSNP__io_msInfo_14_bits_blockRefill),
    .io_msInfo_14_bits_meta_dirty (RXSNP__io_msInfo_14_bits_meta_dirty),
    .io_msInfo_14_bits_meta_state (RXSNP__io_msInfo_14_bits_meta_state),
    .io_msInfo_14_bits_meta_clients (RXSNP__io_msInfo_14_bits_meta_clients),
    .io_msInfo_14_bits_meta_alias (RXSNP__io_msInfo_14_bits_meta_alias),
    .io_msInfo_14_bits_meta_prefetch (RXSNP__io_msInfo_14_bits_meta_prefetch),
    .io_msInfo_14_bits_meta_prefetchSrc (RXSNP__io_msInfo_14_bits_meta_prefetchSrc),
    .io_msInfo_14_bits_meta_accessed (RXSNP__io_msInfo_14_bits_meta_accessed),
    .io_msInfo_14_bits_meta_tagErr (RXSNP__io_msInfo_14_bits_meta_tagErr),
    .io_msInfo_14_bits_meta_dataErr (RXSNP__io_msInfo_14_bits_meta_dataErr),
    .io_msInfo_14_bits_metaTag (RXSNP__io_msInfo_14_bits_metaTag),
    .io_msInfo_14_bits_dirHit (RXSNP__io_msInfo_14_bits_dirHit),
    .io_msInfo_14_bits_w_grantfirst (RXSNP__io_msInfo_14_bits_w_grantfirst),
    .io_msInfo_14_bits_s_release (RXSNP__io_msInfo_14_bits_s_release),
    .io_msInfo_14_bits_s_cmoresp (RXSNP__io_msInfo_14_bits_s_cmoresp),
    .io_msInfo_14_bits_s_cmometaw (RXSNP__io_msInfo_14_bits_s_cmometaw),
    .io_msInfo_14_bits_w_releaseack (RXSNP__io_msInfo_14_bits_w_releaseack),
    .io_msInfo_14_bits_w_replResp (RXSNP__io_msInfo_14_bits_w_replResp),
    .io_msInfo_14_bits_w_rprobeacklast (RXSNP__io_msInfo_14_bits_w_rprobeacklast),
    .io_msInfo_14_bits_replaceData (RXSNP__io_msInfo_14_bits_replaceData),
    .io_msInfo_14_bits_releaseToClean (RXSNP__io_msInfo_14_bits_releaseToClean),
    .io_msInfo_15_valid (RXSNP__io_msInfo_15_valid),
    .io_msInfo_15_bits_set (RXSNP__io_msInfo_15_bits_set),
    .io_msInfo_15_bits_reqTag (RXSNP__io_msInfo_15_bits_reqTag),
    .io_msInfo_15_bits_willFree (RXSNP__io_msInfo_15_bits_willFree),
    .io_msInfo_15_bits_aliasTask (RXSNP__io_msInfo_15_bits_aliasTask),
    .io_msInfo_15_bits_blockRefill (RXSNP__io_msInfo_15_bits_blockRefill),
    .io_msInfo_15_bits_meta_dirty (RXSNP__io_msInfo_15_bits_meta_dirty),
    .io_msInfo_15_bits_meta_state (RXSNP__io_msInfo_15_bits_meta_state),
    .io_msInfo_15_bits_meta_clients (RXSNP__io_msInfo_15_bits_meta_clients),
    .io_msInfo_15_bits_meta_alias (RXSNP__io_msInfo_15_bits_meta_alias),
    .io_msInfo_15_bits_meta_prefetch (RXSNP__io_msInfo_15_bits_meta_prefetch),
    .io_msInfo_15_bits_meta_prefetchSrc (RXSNP__io_msInfo_15_bits_meta_prefetchSrc),
    .io_msInfo_15_bits_meta_accessed (RXSNP__io_msInfo_15_bits_meta_accessed),
    .io_msInfo_15_bits_meta_tagErr (RXSNP__io_msInfo_15_bits_meta_tagErr),
    .io_msInfo_15_bits_meta_dataErr (RXSNP__io_msInfo_15_bits_meta_dataErr),
    .io_msInfo_15_bits_metaTag (RXSNP__io_msInfo_15_bits_metaTag),
    .io_msInfo_15_bits_dirHit (RXSNP__io_msInfo_15_bits_dirHit),
    .io_msInfo_15_bits_w_grantfirst (RXSNP__io_msInfo_15_bits_w_grantfirst),
    .io_msInfo_15_bits_s_release (RXSNP__io_msInfo_15_bits_s_release),
    .io_msInfo_15_bits_s_cmoresp (RXSNP__io_msInfo_15_bits_s_cmoresp),
    .io_msInfo_15_bits_s_cmometaw (RXSNP__io_msInfo_15_bits_s_cmometaw),
    .io_msInfo_15_bits_w_releaseack (RXSNP__io_msInfo_15_bits_w_releaseack),
    .io_msInfo_15_bits_w_replResp (RXSNP__io_msInfo_15_bits_w_replResp),
    .io_msInfo_15_bits_w_rprobeacklast (RXSNP__io_msInfo_15_bits_w_rprobeacklast),
    .io_msInfo_15_bits_replaceData (RXSNP__io_msInfo_15_bits_replaceData),
    .io_msInfo_15_bits_releaseToClean (RXSNP__io_msInfo_15_bits_releaseToClean)
  );
  task automatic drive_RXSNP();
    RXSNP__io_rxsnp_valid = $urandom % 2;
    RXSNP__io_rxsnp_bits_qos = rnd(4);
    RXSNP__io_rxsnp_bits_srcID = rnd(11);
    RXSNP__io_rxsnp_bits_txnID = rnd(12);
    RXSNP__io_rxsnp_bits_fwdNID = rnd(11);
    RXSNP__io_rxsnp_bits_fwdTxnID = rnd(12);
    RXSNP__io_rxsnp_bits_opcode = rnd(5);
    RXSNP__io_rxsnp_bits_addr = {30'h0, 1'($urandom), 8'h0, 1'($urandom), 5'($urandom)};
    RXSNP__io_rxsnp_bits_ns = $urandom % 2;
    RXSNP__io_rxsnp_bits_doNotGoToSD = $urandom % 2;
    RXSNP__io_rxsnp_bits_retToSrc = $urandom % 2;
    RXSNP__io_rxsnp_bits_traceTag = $urandom % 2;
    RXSNP__io_rxsnp_bits_mpam_perfMonGroup = $urandom % 2;
    RXSNP__io_rxsnp_bits_mpam_partID = rnd(9);
    RXSNP__io_rxsnp_bits_mpam_mpamNS = $urandom % 2;
    RXSNP__io_task_ready = (($urandom % 4) != 0);
    RXSNP__io_msInfo_0_valid = (($urandom % 4) == 0);
    RXSNP__io_msInfo_0_bits_set = 9'($urandom_range(0, 1));
    RXSNP__io_msInfo_0_bits_reqTag = 31'($urandom_range(0, 1));
    RXSNP__io_msInfo_0_bits_willFree = $urandom % 2;
    RXSNP__io_msInfo_0_bits_aliasTask = $urandom % 2;
    RXSNP__io_msInfo_0_bits_blockRefill = $urandom % 2;
    RXSNP__io_msInfo_0_bits_meta_dirty = $urandom % 2;
    RXSNP__io_msInfo_0_bits_meta_state = rnd(2);
    RXSNP__io_msInfo_0_bits_meta_clients = $urandom % 2;
    RXSNP__io_msInfo_0_bits_meta_alias = rnd(2);
    RXSNP__io_msInfo_0_bits_meta_prefetch = $urandom % 2;
    RXSNP__io_msInfo_0_bits_meta_prefetchSrc = rnd(3);
    RXSNP__io_msInfo_0_bits_meta_accessed = $urandom % 2;
    RXSNP__io_msInfo_0_bits_meta_tagErr = $urandom % 2;
    RXSNP__io_msInfo_0_bits_meta_dataErr = $urandom % 2;
    RXSNP__io_msInfo_0_bits_metaTag = 31'($urandom_range(0, 1));
    RXSNP__io_msInfo_0_bits_dirHit = $urandom % 2;
    RXSNP__io_msInfo_0_bits_w_grantfirst = $urandom % 2;
    RXSNP__io_msInfo_0_bits_s_release = $urandom % 2;
    RXSNP__io_msInfo_0_bits_s_cmoresp = $urandom % 2;
    RXSNP__io_msInfo_0_bits_s_cmometaw = $urandom % 2;
    RXSNP__io_msInfo_0_bits_w_releaseack = $urandom % 2;
    RXSNP__io_msInfo_0_bits_w_replResp = $urandom % 2;
    RXSNP__io_msInfo_0_bits_w_rprobeacklast = $urandom % 2;
    RXSNP__io_msInfo_0_bits_replaceData = $urandom % 2;
    RXSNP__io_msInfo_0_bits_releaseToClean = $urandom % 2;
    RXSNP__io_msInfo_1_valid = (($urandom % 4) == 0);
    RXSNP__io_msInfo_1_bits_set = 9'($urandom_range(0, 1));
    RXSNP__io_msInfo_1_bits_reqTag = 31'($urandom_range(0, 1));
    RXSNP__io_msInfo_1_bits_willFree = $urandom % 2;
    RXSNP__io_msInfo_1_bits_aliasTask = $urandom % 2;
    RXSNP__io_msInfo_1_bits_blockRefill = $urandom % 2;
    RXSNP__io_msInfo_1_bits_meta_dirty = $urandom % 2;
    RXSNP__io_msInfo_1_bits_meta_state = rnd(2);
    RXSNP__io_msInfo_1_bits_meta_clients = $urandom % 2;
    RXSNP__io_msInfo_1_bits_meta_alias = rnd(2);
    RXSNP__io_msInfo_1_bits_meta_prefetch = $urandom % 2;
    RXSNP__io_msInfo_1_bits_meta_prefetchSrc = rnd(3);
    RXSNP__io_msInfo_1_bits_meta_accessed = $urandom % 2;
    RXSNP__io_msInfo_1_bits_meta_tagErr = $urandom % 2;
    RXSNP__io_msInfo_1_bits_meta_dataErr = $urandom % 2;
    RXSNP__io_msInfo_1_bits_metaTag = 31'($urandom_range(0, 1));
    RXSNP__io_msInfo_1_bits_dirHit = $urandom % 2;
    RXSNP__io_msInfo_1_bits_w_grantfirst = $urandom % 2;
    RXSNP__io_msInfo_1_bits_s_release = $urandom % 2;
    RXSNP__io_msInfo_1_bits_s_cmoresp = $urandom % 2;
    RXSNP__io_msInfo_1_bits_s_cmometaw = $urandom % 2;
    RXSNP__io_msInfo_1_bits_w_releaseack = $urandom % 2;
    RXSNP__io_msInfo_1_bits_w_replResp = $urandom % 2;
    RXSNP__io_msInfo_1_bits_w_rprobeacklast = $urandom % 2;
    RXSNP__io_msInfo_1_bits_replaceData = $urandom % 2;
    RXSNP__io_msInfo_1_bits_releaseToClean = $urandom % 2;
    RXSNP__io_msInfo_2_valid = (($urandom % 4) == 0);
    RXSNP__io_msInfo_2_bits_set = 9'($urandom_range(0, 1));
    RXSNP__io_msInfo_2_bits_reqTag = 31'($urandom_range(0, 1));
    RXSNP__io_msInfo_2_bits_willFree = $urandom % 2;
    RXSNP__io_msInfo_2_bits_aliasTask = $urandom % 2;
    RXSNP__io_msInfo_2_bits_blockRefill = $urandom % 2;
    RXSNP__io_msInfo_2_bits_meta_dirty = $urandom % 2;
    RXSNP__io_msInfo_2_bits_meta_state = rnd(2);
    RXSNP__io_msInfo_2_bits_meta_clients = $urandom % 2;
    RXSNP__io_msInfo_2_bits_meta_alias = rnd(2);
    RXSNP__io_msInfo_2_bits_meta_prefetch = $urandom % 2;
    RXSNP__io_msInfo_2_bits_meta_prefetchSrc = rnd(3);
    RXSNP__io_msInfo_2_bits_meta_accessed = $urandom % 2;
    RXSNP__io_msInfo_2_bits_meta_tagErr = $urandom % 2;
    RXSNP__io_msInfo_2_bits_meta_dataErr = $urandom % 2;
    RXSNP__io_msInfo_2_bits_metaTag = 31'($urandom_range(0, 1));
    RXSNP__io_msInfo_2_bits_dirHit = $urandom % 2;
    RXSNP__io_msInfo_2_bits_w_grantfirst = $urandom % 2;
    RXSNP__io_msInfo_2_bits_s_release = $urandom % 2;
    RXSNP__io_msInfo_2_bits_s_cmoresp = $urandom % 2;
    RXSNP__io_msInfo_2_bits_s_cmometaw = $urandom % 2;
    RXSNP__io_msInfo_2_bits_w_releaseack = $urandom % 2;
    RXSNP__io_msInfo_2_bits_w_replResp = $urandom % 2;
    RXSNP__io_msInfo_2_bits_w_rprobeacklast = $urandom % 2;
    RXSNP__io_msInfo_2_bits_replaceData = $urandom % 2;
    RXSNP__io_msInfo_2_bits_releaseToClean = $urandom % 2;
    RXSNP__io_msInfo_3_valid = (($urandom % 4) == 0);
    RXSNP__io_msInfo_3_bits_set = 9'($urandom_range(0, 1));
    RXSNP__io_msInfo_3_bits_reqTag = 31'($urandom_range(0, 1));
    RXSNP__io_msInfo_3_bits_willFree = $urandom % 2;
    RXSNP__io_msInfo_3_bits_aliasTask = $urandom % 2;
    RXSNP__io_msInfo_3_bits_blockRefill = $urandom % 2;
    RXSNP__io_msInfo_3_bits_meta_dirty = $urandom % 2;
    RXSNP__io_msInfo_3_bits_meta_state = rnd(2);
    RXSNP__io_msInfo_3_bits_meta_clients = $urandom % 2;
    RXSNP__io_msInfo_3_bits_meta_alias = rnd(2);
    RXSNP__io_msInfo_3_bits_meta_prefetch = $urandom % 2;
    RXSNP__io_msInfo_3_bits_meta_prefetchSrc = rnd(3);
    RXSNP__io_msInfo_3_bits_meta_accessed = $urandom % 2;
    RXSNP__io_msInfo_3_bits_meta_tagErr = $urandom % 2;
    RXSNP__io_msInfo_3_bits_meta_dataErr = $urandom % 2;
    RXSNP__io_msInfo_3_bits_metaTag = 31'($urandom_range(0, 1));
    RXSNP__io_msInfo_3_bits_dirHit = $urandom % 2;
    RXSNP__io_msInfo_3_bits_w_grantfirst = $urandom % 2;
    RXSNP__io_msInfo_3_bits_s_release = $urandom % 2;
    RXSNP__io_msInfo_3_bits_s_cmoresp = $urandom % 2;
    RXSNP__io_msInfo_3_bits_s_cmometaw = $urandom % 2;
    RXSNP__io_msInfo_3_bits_w_releaseack = $urandom % 2;
    RXSNP__io_msInfo_3_bits_w_replResp = $urandom % 2;
    RXSNP__io_msInfo_3_bits_w_rprobeacklast = $urandom % 2;
    RXSNP__io_msInfo_3_bits_replaceData = $urandom % 2;
    RXSNP__io_msInfo_3_bits_releaseToClean = $urandom % 2;
    RXSNP__io_msInfo_4_valid = (($urandom % 4) == 0);
    RXSNP__io_msInfo_4_bits_set = 9'($urandom_range(0, 1));
    RXSNP__io_msInfo_4_bits_reqTag = 31'($urandom_range(0, 1));
    RXSNP__io_msInfo_4_bits_willFree = $urandom % 2;
    RXSNP__io_msInfo_4_bits_aliasTask = $urandom % 2;
    RXSNP__io_msInfo_4_bits_blockRefill = $urandom % 2;
    RXSNP__io_msInfo_4_bits_meta_dirty = $urandom % 2;
    RXSNP__io_msInfo_4_bits_meta_state = rnd(2);
    RXSNP__io_msInfo_4_bits_meta_clients = $urandom % 2;
    RXSNP__io_msInfo_4_bits_meta_alias = rnd(2);
    RXSNP__io_msInfo_4_bits_meta_prefetch = $urandom % 2;
    RXSNP__io_msInfo_4_bits_meta_prefetchSrc = rnd(3);
    RXSNP__io_msInfo_4_bits_meta_accessed = $urandom % 2;
    RXSNP__io_msInfo_4_bits_meta_tagErr = $urandom % 2;
    RXSNP__io_msInfo_4_bits_meta_dataErr = $urandom % 2;
    RXSNP__io_msInfo_4_bits_metaTag = 31'($urandom_range(0, 1));
    RXSNP__io_msInfo_4_bits_dirHit = $urandom % 2;
    RXSNP__io_msInfo_4_bits_w_grantfirst = $urandom % 2;
    RXSNP__io_msInfo_4_bits_s_release = $urandom % 2;
    RXSNP__io_msInfo_4_bits_s_cmoresp = $urandom % 2;
    RXSNP__io_msInfo_4_bits_s_cmometaw = $urandom % 2;
    RXSNP__io_msInfo_4_bits_w_releaseack = $urandom % 2;
    RXSNP__io_msInfo_4_bits_w_replResp = $urandom % 2;
    RXSNP__io_msInfo_4_bits_w_rprobeacklast = $urandom % 2;
    RXSNP__io_msInfo_4_bits_replaceData = $urandom % 2;
    RXSNP__io_msInfo_4_bits_releaseToClean = $urandom % 2;
    RXSNP__io_msInfo_5_valid = (($urandom % 4) == 0);
    RXSNP__io_msInfo_5_bits_set = 9'($urandom_range(0, 1));
    RXSNP__io_msInfo_5_bits_reqTag = 31'($urandom_range(0, 1));
    RXSNP__io_msInfo_5_bits_willFree = $urandom % 2;
    RXSNP__io_msInfo_5_bits_aliasTask = $urandom % 2;
    RXSNP__io_msInfo_5_bits_blockRefill = $urandom % 2;
    RXSNP__io_msInfo_5_bits_meta_dirty = $urandom % 2;
    RXSNP__io_msInfo_5_bits_meta_state = rnd(2);
    RXSNP__io_msInfo_5_bits_meta_clients = $urandom % 2;
    RXSNP__io_msInfo_5_bits_meta_alias = rnd(2);
    RXSNP__io_msInfo_5_bits_meta_prefetch = $urandom % 2;
    RXSNP__io_msInfo_5_bits_meta_prefetchSrc = rnd(3);
    RXSNP__io_msInfo_5_bits_meta_accessed = $urandom % 2;
    RXSNP__io_msInfo_5_bits_meta_tagErr = $urandom % 2;
    RXSNP__io_msInfo_5_bits_meta_dataErr = $urandom % 2;
    RXSNP__io_msInfo_5_bits_metaTag = 31'($urandom_range(0, 1));
    RXSNP__io_msInfo_5_bits_dirHit = $urandom % 2;
    RXSNP__io_msInfo_5_bits_w_grantfirst = $urandom % 2;
    RXSNP__io_msInfo_5_bits_s_release = $urandom % 2;
    RXSNP__io_msInfo_5_bits_s_cmoresp = $urandom % 2;
    RXSNP__io_msInfo_5_bits_s_cmometaw = $urandom % 2;
    RXSNP__io_msInfo_5_bits_w_releaseack = $urandom % 2;
    RXSNP__io_msInfo_5_bits_w_replResp = $urandom % 2;
    RXSNP__io_msInfo_5_bits_w_rprobeacklast = $urandom % 2;
    RXSNP__io_msInfo_5_bits_replaceData = $urandom % 2;
    RXSNP__io_msInfo_5_bits_releaseToClean = $urandom % 2;
    RXSNP__io_msInfo_6_valid = (($urandom % 4) == 0);
    RXSNP__io_msInfo_6_bits_set = 9'($urandom_range(0, 1));
    RXSNP__io_msInfo_6_bits_reqTag = 31'($urandom_range(0, 1));
    RXSNP__io_msInfo_6_bits_willFree = $urandom % 2;
    RXSNP__io_msInfo_6_bits_aliasTask = $urandom % 2;
    RXSNP__io_msInfo_6_bits_blockRefill = $urandom % 2;
    RXSNP__io_msInfo_6_bits_meta_dirty = $urandom % 2;
    RXSNP__io_msInfo_6_bits_meta_state = rnd(2);
    RXSNP__io_msInfo_6_bits_meta_clients = $urandom % 2;
    RXSNP__io_msInfo_6_bits_meta_alias = rnd(2);
    RXSNP__io_msInfo_6_bits_meta_prefetch = $urandom % 2;
    RXSNP__io_msInfo_6_bits_meta_prefetchSrc = rnd(3);
    RXSNP__io_msInfo_6_bits_meta_accessed = $urandom % 2;
    RXSNP__io_msInfo_6_bits_meta_tagErr = $urandom % 2;
    RXSNP__io_msInfo_6_bits_meta_dataErr = $urandom % 2;
    RXSNP__io_msInfo_6_bits_metaTag = 31'($urandom_range(0, 1));
    RXSNP__io_msInfo_6_bits_dirHit = $urandom % 2;
    RXSNP__io_msInfo_6_bits_w_grantfirst = $urandom % 2;
    RXSNP__io_msInfo_6_bits_s_release = $urandom % 2;
    RXSNP__io_msInfo_6_bits_s_cmoresp = $urandom % 2;
    RXSNP__io_msInfo_6_bits_s_cmometaw = $urandom % 2;
    RXSNP__io_msInfo_6_bits_w_releaseack = $urandom % 2;
    RXSNP__io_msInfo_6_bits_w_replResp = $urandom % 2;
    RXSNP__io_msInfo_6_bits_w_rprobeacklast = $urandom % 2;
    RXSNP__io_msInfo_6_bits_replaceData = $urandom % 2;
    RXSNP__io_msInfo_6_bits_releaseToClean = $urandom % 2;
    RXSNP__io_msInfo_7_valid = (($urandom % 4) == 0);
    RXSNP__io_msInfo_7_bits_set = 9'($urandom_range(0, 1));
    RXSNP__io_msInfo_7_bits_reqTag = 31'($urandom_range(0, 1));
    RXSNP__io_msInfo_7_bits_willFree = $urandom % 2;
    RXSNP__io_msInfo_7_bits_aliasTask = $urandom % 2;
    RXSNP__io_msInfo_7_bits_blockRefill = $urandom % 2;
    RXSNP__io_msInfo_7_bits_meta_dirty = $urandom % 2;
    RXSNP__io_msInfo_7_bits_meta_state = rnd(2);
    RXSNP__io_msInfo_7_bits_meta_clients = $urandom % 2;
    RXSNP__io_msInfo_7_bits_meta_alias = rnd(2);
    RXSNP__io_msInfo_7_bits_meta_prefetch = $urandom % 2;
    RXSNP__io_msInfo_7_bits_meta_prefetchSrc = rnd(3);
    RXSNP__io_msInfo_7_bits_meta_accessed = $urandom % 2;
    RXSNP__io_msInfo_7_bits_meta_tagErr = $urandom % 2;
    RXSNP__io_msInfo_7_bits_meta_dataErr = $urandom % 2;
    RXSNP__io_msInfo_7_bits_metaTag = 31'($urandom_range(0, 1));
    RXSNP__io_msInfo_7_bits_dirHit = $urandom % 2;
    RXSNP__io_msInfo_7_bits_w_grantfirst = $urandom % 2;
    RXSNP__io_msInfo_7_bits_s_release = $urandom % 2;
    RXSNP__io_msInfo_7_bits_s_cmoresp = $urandom % 2;
    RXSNP__io_msInfo_7_bits_s_cmometaw = $urandom % 2;
    RXSNP__io_msInfo_7_bits_w_releaseack = $urandom % 2;
    RXSNP__io_msInfo_7_bits_w_replResp = $urandom % 2;
    RXSNP__io_msInfo_7_bits_w_rprobeacklast = $urandom % 2;
    RXSNP__io_msInfo_7_bits_replaceData = $urandom % 2;
    RXSNP__io_msInfo_7_bits_releaseToClean = $urandom % 2;
    RXSNP__io_msInfo_8_valid = (($urandom % 4) == 0);
    RXSNP__io_msInfo_8_bits_set = 9'($urandom_range(0, 1));
    RXSNP__io_msInfo_8_bits_reqTag = 31'($urandom_range(0, 1));
    RXSNP__io_msInfo_8_bits_willFree = $urandom % 2;
    RXSNP__io_msInfo_8_bits_aliasTask = $urandom % 2;
    RXSNP__io_msInfo_8_bits_blockRefill = $urandom % 2;
    RXSNP__io_msInfo_8_bits_meta_dirty = $urandom % 2;
    RXSNP__io_msInfo_8_bits_meta_state = rnd(2);
    RXSNP__io_msInfo_8_bits_meta_clients = $urandom % 2;
    RXSNP__io_msInfo_8_bits_meta_alias = rnd(2);
    RXSNP__io_msInfo_8_bits_meta_prefetch = $urandom % 2;
    RXSNP__io_msInfo_8_bits_meta_prefetchSrc = rnd(3);
    RXSNP__io_msInfo_8_bits_meta_accessed = $urandom % 2;
    RXSNP__io_msInfo_8_bits_meta_tagErr = $urandom % 2;
    RXSNP__io_msInfo_8_bits_meta_dataErr = $urandom % 2;
    RXSNP__io_msInfo_8_bits_metaTag = 31'($urandom_range(0, 1));
    RXSNP__io_msInfo_8_bits_dirHit = $urandom % 2;
    RXSNP__io_msInfo_8_bits_w_grantfirst = $urandom % 2;
    RXSNP__io_msInfo_8_bits_s_release = $urandom % 2;
    RXSNP__io_msInfo_8_bits_s_cmoresp = $urandom % 2;
    RXSNP__io_msInfo_8_bits_s_cmometaw = $urandom % 2;
    RXSNP__io_msInfo_8_bits_w_releaseack = $urandom % 2;
    RXSNP__io_msInfo_8_bits_w_replResp = $urandom % 2;
    RXSNP__io_msInfo_8_bits_w_rprobeacklast = $urandom % 2;
    RXSNP__io_msInfo_8_bits_replaceData = $urandom % 2;
    RXSNP__io_msInfo_8_bits_releaseToClean = $urandom % 2;
    RXSNP__io_msInfo_9_valid = (($urandom % 4) == 0);
    RXSNP__io_msInfo_9_bits_set = 9'($urandom_range(0, 1));
    RXSNP__io_msInfo_9_bits_reqTag = 31'($urandom_range(0, 1));
    RXSNP__io_msInfo_9_bits_willFree = $urandom % 2;
    RXSNP__io_msInfo_9_bits_aliasTask = $urandom % 2;
    RXSNP__io_msInfo_9_bits_blockRefill = $urandom % 2;
    RXSNP__io_msInfo_9_bits_meta_dirty = $urandom % 2;
    RXSNP__io_msInfo_9_bits_meta_state = rnd(2);
    RXSNP__io_msInfo_9_bits_meta_clients = $urandom % 2;
    RXSNP__io_msInfo_9_bits_meta_alias = rnd(2);
    RXSNP__io_msInfo_9_bits_meta_prefetch = $urandom % 2;
    RXSNP__io_msInfo_9_bits_meta_prefetchSrc = rnd(3);
    RXSNP__io_msInfo_9_bits_meta_accessed = $urandom % 2;
    RXSNP__io_msInfo_9_bits_meta_tagErr = $urandom % 2;
    RXSNP__io_msInfo_9_bits_meta_dataErr = $urandom % 2;
    RXSNP__io_msInfo_9_bits_metaTag = 31'($urandom_range(0, 1));
    RXSNP__io_msInfo_9_bits_dirHit = $urandom % 2;
    RXSNP__io_msInfo_9_bits_w_grantfirst = $urandom % 2;
    RXSNP__io_msInfo_9_bits_s_release = $urandom % 2;
    RXSNP__io_msInfo_9_bits_s_cmoresp = $urandom % 2;
    RXSNP__io_msInfo_9_bits_s_cmometaw = $urandom % 2;
    RXSNP__io_msInfo_9_bits_w_releaseack = $urandom % 2;
    RXSNP__io_msInfo_9_bits_w_replResp = $urandom % 2;
    RXSNP__io_msInfo_9_bits_w_rprobeacklast = $urandom % 2;
    RXSNP__io_msInfo_9_bits_replaceData = $urandom % 2;
    RXSNP__io_msInfo_9_bits_releaseToClean = $urandom % 2;
    RXSNP__io_msInfo_10_valid = (($urandom % 4) == 0);
    RXSNP__io_msInfo_10_bits_set = 9'($urandom_range(0, 1));
    RXSNP__io_msInfo_10_bits_reqTag = 31'($urandom_range(0, 1));
    RXSNP__io_msInfo_10_bits_willFree = $urandom % 2;
    RXSNP__io_msInfo_10_bits_aliasTask = $urandom % 2;
    RXSNP__io_msInfo_10_bits_blockRefill = $urandom % 2;
    RXSNP__io_msInfo_10_bits_meta_dirty = $urandom % 2;
    RXSNP__io_msInfo_10_bits_meta_state = rnd(2);
    RXSNP__io_msInfo_10_bits_meta_clients = $urandom % 2;
    RXSNP__io_msInfo_10_bits_meta_alias = rnd(2);
    RXSNP__io_msInfo_10_bits_meta_prefetch = $urandom % 2;
    RXSNP__io_msInfo_10_bits_meta_prefetchSrc = rnd(3);
    RXSNP__io_msInfo_10_bits_meta_accessed = $urandom % 2;
    RXSNP__io_msInfo_10_bits_meta_tagErr = $urandom % 2;
    RXSNP__io_msInfo_10_bits_meta_dataErr = $urandom % 2;
    RXSNP__io_msInfo_10_bits_metaTag = 31'($urandom_range(0, 1));
    RXSNP__io_msInfo_10_bits_dirHit = $urandom % 2;
    RXSNP__io_msInfo_10_bits_w_grantfirst = $urandom % 2;
    RXSNP__io_msInfo_10_bits_s_release = $urandom % 2;
    RXSNP__io_msInfo_10_bits_s_cmoresp = $urandom % 2;
    RXSNP__io_msInfo_10_bits_s_cmometaw = $urandom % 2;
    RXSNP__io_msInfo_10_bits_w_releaseack = $urandom % 2;
    RXSNP__io_msInfo_10_bits_w_replResp = $urandom % 2;
    RXSNP__io_msInfo_10_bits_w_rprobeacklast = $urandom % 2;
    RXSNP__io_msInfo_10_bits_replaceData = $urandom % 2;
    RXSNP__io_msInfo_10_bits_releaseToClean = $urandom % 2;
    RXSNP__io_msInfo_11_valid = (($urandom % 4) == 0);
    RXSNP__io_msInfo_11_bits_set = 9'($urandom_range(0, 1));
    RXSNP__io_msInfo_11_bits_reqTag = 31'($urandom_range(0, 1));
    RXSNP__io_msInfo_11_bits_willFree = $urandom % 2;
    RXSNP__io_msInfo_11_bits_aliasTask = $urandom % 2;
    RXSNP__io_msInfo_11_bits_blockRefill = $urandom % 2;
    RXSNP__io_msInfo_11_bits_meta_dirty = $urandom % 2;
    RXSNP__io_msInfo_11_bits_meta_state = rnd(2);
    RXSNP__io_msInfo_11_bits_meta_clients = $urandom % 2;
    RXSNP__io_msInfo_11_bits_meta_alias = rnd(2);
    RXSNP__io_msInfo_11_bits_meta_prefetch = $urandom % 2;
    RXSNP__io_msInfo_11_bits_meta_prefetchSrc = rnd(3);
    RXSNP__io_msInfo_11_bits_meta_accessed = $urandom % 2;
    RXSNP__io_msInfo_11_bits_meta_tagErr = $urandom % 2;
    RXSNP__io_msInfo_11_bits_meta_dataErr = $urandom % 2;
    RXSNP__io_msInfo_11_bits_metaTag = 31'($urandom_range(0, 1));
    RXSNP__io_msInfo_11_bits_dirHit = $urandom % 2;
    RXSNP__io_msInfo_11_bits_w_grantfirst = $urandom % 2;
    RXSNP__io_msInfo_11_bits_s_release = $urandom % 2;
    RXSNP__io_msInfo_11_bits_s_cmoresp = $urandom % 2;
    RXSNP__io_msInfo_11_bits_s_cmometaw = $urandom % 2;
    RXSNP__io_msInfo_11_bits_w_releaseack = $urandom % 2;
    RXSNP__io_msInfo_11_bits_w_replResp = $urandom % 2;
    RXSNP__io_msInfo_11_bits_w_rprobeacklast = $urandom % 2;
    RXSNP__io_msInfo_11_bits_replaceData = $urandom % 2;
    RXSNP__io_msInfo_11_bits_releaseToClean = $urandom % 2;
    RXSNP__io_msInfo_12_valid = (($urandom % 4) == 0);
    RXSNP__io_msInfo_12_bits_set = 9'($urandom_range(0, 1));
    RXSNP__io_msInfo_12_bits_reqTag = 31'($urandom_range(0, 1));
    RXSNP__io_msInfo_12_bits_willFree = $urandom % 2;
    RXSNP__io_msInfo_12_bits_aliasTask = $urandom % 2;
    RXSNP__io_msInfo_12_bits_blockRefill = $urandom % 2;
    RXSNP__io_msInfo_12_bits_meta_dirty = $urandom % 2;
    RXSNP__io_msInfo_12_bits_meta_state = rnd(2);
    RXSNP__io_msInfo_12_bits_meta_clients = $urandom % 2;
    RXSNP__io_msInfo_12_bits_meta_alias = rnd(2);
    RXSNP__io_msInfo_12_bits_meta_prefetch = $urandom % 2;
    RXSNP__io_msInfo_12_bits_meta_prefetchSrc = rnd(3);
    RXSNP__io_msInfo_12_bits_meta_accessed = $urandom % 2;
    RXSNP__io_msInfo_12_bits_meta_tagErr = $urandom % 2;
    RXSNP__io_msInfo_12_bits_meta_dataErr = $urandom % 2;
    RXSNP__io_msInfo_12_bits_metaTag = 31'($urandom_range(0, 1));
    RXSNP__io_msInfo_12_bits_dirHit = $urandom % 2;
    RXSNP__io_msInfo_12_bits_w_grantfirst = $urandom % 2;
    RXSNP__io_msInfo_12_bits_s_release = $urandom % 2;
    RXSNP__io_msInfo_12_bits_s_cmoresp = $urandom % 2;
    RXSNP__io_msInfo_12_bits_s_cmometaw = $urandom % 2;
    RXSNP__io_msInfo_12_bits_w_releaseack = $urandom % 2;
    RXSNP__io_msInfo_12_bits_w_replResp = $urandom % 2;
    RXSNP__io_msInfo_12_bits_w_rprobeacklast = $urandom % 2;
    RXSNP__io_msInfo_12_bits_replaceData = $urandom % 2;
    RXSNP__io_msInfo_12_bits_releaseToClean = $urandom % 2;
    RXSNP__io_msInfo_13_valid = (($urandom % 4) == 0);
    RXSNP__io_msInfo_13_bits_set = 9'($urandom_range(0, 1));
    RXSNP__io_msInfo_13_bits_reqTag = 31'($urandom_range(0, 1));
    RXSNP__io_msInfo_13_bits_willFree = $urandom % 2;
    RXSNP__io_msInfo_13_bits_aliasTask = $urandom % 2;
    RXSNP__io_msInfo_13_bits_blockRefill = $urandom % 2;
    RXSNP__io_msInfo_13_bits_meta_dirty = $urandom % 2;
    RXSNP__io_msInfo_13_bits_meta_state = rnd(2);
    RXSNP__io_msInfo_13_bits_meta_clients = $urandom % 2;
    RXSNP__io_msInfo_13_bits_meta_alias = rnd(2);
    RXSNP__io_msInfo_13_bits_meta_prefetch = $urandom % 2;
    RXSNP__io_msInfo_13_bits_meta_prefetchSrc = rnd(3);
    RXSNP__io_msInfo_13_bits_meta_accessed = $urandom % 2;
    RXSNP__io_msInfo_13_bits_meta_tagErr = $urandom % 2;
    RXSNP__io_msInfo_13_bits_meta_dataErr = $urandom % 2;
    RXSNP__io_msInfo_13_bits_metaTag = 31'($urandom_range(0, 1));
    RXSNP__io_msInfo_13_bits_dirHit = $urandom % 2;
    RXSNP__io_msInfo_13_bits_w_grantfirst = $urandom % 2;
    RXSNP__io_msInfo_13_bits_s_release = $urandom % 2;
    RXSNP__io_msInfo_13_bits_s_cmoresp = $urandom % 2;
    RXSNP__io_msInfo_13_bits_s_cmometaw = $urandom % 2;
    RXSNP__io_msInfo_13_bits_w_releaseack = $urandom % 2;
    RXSNP__io_msInfo_13_bits_w_replResp = $urandom % 2;
    RXSNP__io_msInfo_13_bits_w_rprobeacklast = $urandom % 2;
    RXSNP__io_msInfo_13_bits_replaceData = $urandom % 2;
    RXSNP__io_msInfo_13_bits_releaseToClean = $urandom % 2;
    RXSNP__io_msInfo_14_valid = (($urandom % 4) == 0);
    RXSNP__io_msInfo_14_bits_set = 9'($urandom_range(0, 1));
    RXSNP__io_msInfo_14_bits_reqTag = 31'($urandom_range(0, 1));
    RXSNP__io_msInfo_14_bits_willFree = $urandom % 2;
    RXSNP__io_msInfo_14_bits_aliasTask = $urandom % 2;
    RXSNP__io_msInfo_14_bits_blockRefill = $urandom % 2;
    RXSNP__io_msInfo_14_bits_meta_dirty = $urandom % 2;
    RXSNP__io_msInfo_14_bits_meta_state = rnd(2);
    RXSNP__io_msInfo_14_bits_meta_clients = $urandom % 2;
    RXSNP__io_msInfo_14_bits_meta_alias = rnd(2);
    RXSNP__io_msInfo_14_bits_meta_prefetch = $urandom % 2;
    RXSNP__io_msInfo_14_bits_meta_prefetchSrc = rnd(3);
    RXSNP__io_msInfo_14_bits_meta_accessed = $urandom % 2;
    RXSNP__io_msInfo_14_bits_meta_tagErr = $urandom % 2;
    RXSNP__io_msInfo_14_bits_meta_dataErr = $urandom % 2;
    RXSNP__io_msInfo_14_bits_metaTag = 31'($urandom_range(0, 1));
    RXSNP__io_msInfo_14_bits_dirHit = $urandom % 2;
    RXSNP__io_msInfo_14_bits_w_grantfirst = $urandom % 2;
    RXSNP__io_msInfo_14_bits_s_release = $urandom % 2;
    RXSNP__io_msInfo_14_bits_s_cmoresp = $urandom % 2;
    RXSNP__io_msInfo_14_bits_s_cmometaw = $urandom % 2;
    RXSNP__io_msInfo_14_bits_w_releaseack = $urandom % 2;
    RXSNP__io_msInfo_14_bits_w_replResp = $urandom % 2;
    RXSNP__io_msInfo_14_bits_w_rprobeacklast = $urandom % 2;
    RXSNP__io_msInfo_14_bits_replaceData = $urandom % 2;
    RXSNP__io_msInfo_14_bits_releaseToClean = $urandom % 2;
    RXSNP__io_msInfo_15_valid = (($urandom % 4) == 0);
    RXSNP__io_msInfo_15_bits_set = 9'($urandom_range(0, 1));
    RXSNP__io_msInfo_15_bits_reqTag = 31'($urandom_range(0, 1));
    RXSNP__io_msInfo_15_bits_willFree = $urandom % 2;
    RXSNP__io_msInfo_15_bits_aliasTask = $urandom % 2;
    RXSNP__io_msInfo_15_bits_blockRefill = $urandom % 2;
    RXSNP__io_msInfo_15_bits_meta_dirty = $urandom % 2;
    RXSNP__io_msInfo_15_bits_meta_state = rnd(2);
    RXSNP__io_msInfo_15_bits_meta_clients = $urandom % 2;
    RXSNP__io_msInfo_15_bits_meta_alias = rnd(2);
    RXSNP__io_msInfo_15_bits_meta_prefetch = $urandom % 2;
    RXSNP__io_msInfo_15_bits_meta_prefetchSrc = rnd(3);
    RXSNP__io_msInfo_15_bits_meta_accessed = $urandom % 2;
    RXSNP__io_msInfo_15_bits_meta_tagErr = $urandom % 2;
    RXSNP__io_msInfo_15_bits_meta_dataErr = $urandom % 2;
    RXSNP__io_msInfo_15_bits_metaTag = 31'($urandom_range(0, 1));
    RXSNP__io_msInfo_15_bits_dirHit = $urandom % 2;
    RXSNP__io_msInfo_15_bits_w_grantfirst = $urandom % 2;
    RXSNP__io_msInfo_15_bits_s_release = $urandom % 2;
    RXSNP__io_msInfo_15_bits_s_cmoresp = $urandom % 2;
    RXSNP__io_msInfo_15_bits_s_cmometaw = $urandom % 2;
    RXSNP__io_msInfo_15_bits_w_releaseack = $urandom % 2;
    RXSNP__io_msInfo_15_bits_w_replResp = $urandom % 2;
    RXSNP__io_msInfo_15_bits_w_rprobeacklast = $urandom % 2;
    RXSNP__io_msInfo_15_bits_replaceData = $urandom % 2;
    RXSNP__io_msInfo_15_bits_releaseToClean = $urandom % 2;
  endtask
  task automatic check_RXSNP();
    checks++;
    if (g_RXSNP__io_rxsnp_ready !== i_RXSNP__io_rxsnp_ready) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RXSNP.io_rxsnp_ready g=%h i=%h", cyc, g_RXSNP__io_rxsnp_ready, i_RXSNP__io_rxsnp_ready);
    end
    if (g_RXSNP__io_rxsnp_ready !== p_RXSNP__io_rxsnp_ready) t_RXSNP__io_rxsnp_ready = 1'b1;
    p_RXSNP__io_rxsnp_ready = g_RXSNP__io_rxsnp_ready;
    checks++;
    if (g_RXSNP__io_task_valid !== i_RXSNP__io_task_valid) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RXSNP.io_task_valid g=%h i=%h", cyc, g_RXSNP__io_task_valid, i_RXSNP__io_task_valid);
    end
    if (g_RXSNP__io_task_valid !== p_RXSNP__io_task_valid) t_RXSNP__io_task_valid = 1'b1;
    p_RXSNP__io_task_valid = g_RXSNP__io_task_valid;
    checks++;
    if (g_RXSNP__io_task_bits_set !== i_RXSNP__io_task_bits_set) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RXSNP.io_task_bits_set g=%h i=%h", cyc, g_RXSNP__io_task_bits_set, i_RXSNP__io_task_bits_set);
    end
    if (g_RXSNP__io_task_bits_set !== p_RXSNP__io_task_bits_set) t_RXSNP__io_task_bits_set = 1'b1;
    p_RXSNP__io_task_bits_set = g_RXSNP__io_task_bits_set;
    checks++;
    if (g_RXSNP__io_task_bits_tag !== i_RXSNP__io_task_bits_tag) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RXSNP.io_task_bits_tag g=%h i=%h", cyc, g_RXSNP__io_task_bits_tag, i_RXSNP__io_task_bits_tag);
    end
    if (g_RXSNP__io_task_bits_tag !== p_RXSNP__io_task_bits_tag) t_RXSNP__io_task_bits_tag = 1'b1;
    p_RXSNP__io_task_bits_tag = g_RXSNP__io_task_bits_tag;
    checks++;
    if (g_RXSNP__io_task_bits_off !== i_RXSNP__io_task_bits_off) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RXSNP.io_task_bits_off g=%h i=%h", cyc, g_RXSNP__io_task_bits_off, i_RXSNP__io_task_bits_off);
    end
    if (g_RXSNP__io_task_bits_off !== p_RXSNP__io_task_bits_off) t_RXSNP__io_task_bits_off = 1'b1;
    p_RXSNP__io_task_bits_off = g_RXSNP__io_task_bits_off;
    checks++;
    if (g_RXSNP__io_task_bits_snpHitRelease !== i_RXSNP__io_task_bits_snpHitRelease) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RXSNP.io_task_bits_snpHitRelease g=%h i=%h", cyc, g_RXSNP__io_task_bits_snpHitRelease, i_RXSNP__io_task_bits_snpHitRelease);
    end
    if (g_RXSNP__io_task_bits_snpHitRelease !== p_RXSNP__io_task_bits_snpHitRelease) t_RXSNP__io_task_bits_snpHitRelease = 1'b1;
    p_RXSNP__io_task_bits_snpHitRelease = g_RXSNP__io_task_bits_snpHitRelease;
    checks++;
    if (g_RXSNP__io_task_bits_snpHitReleaseToInval !== i_RXSNP__io_task_bits_snpHitReleaseToInval) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RXSNP.io_task_bits_snpHitReleaseToInval g=%h i=%h", cyc, g_RXSNP__io_task_bits_snpHitReleaseToInval, i_RXSNP__io_task_bits_snpHitReleaseToInval);
    end
    if (g_RXSNP__io_task_bits_snpHitReleaseToInval !== p_RXSNP__io_task_bits_snpHitReleaseToInval) t_RXSNP__io_task_bits_snpHitReleaseToInval = 1'b1;
    p_RXSNP__io_task_bits_snpHitReleaseToInval = g_RXSNP__io_task_bits_snpHitReleaseToInval;
    checks++;
    if (g_RXSNP__io_task_bits_snpHitReleaseToClean !== i_RXSNP__io_task_bits_snpHitReleaseToClean) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RXSNP.io_task_bits_snpHitReleaseToClean g=%h i=%h", cyc, g_RXSNP__io_task_bits_snpHitReleaseToClean, i_RXSNP__io_task_bits_snpHitReleaseToClean);
    end
    if (g_RXSNP__io_task_bits_snpHitReleaseToClean !== p_RXSNP__io_task_bits_snpHitReleaseToClean) t_RXSNP__io_task_bits_snpHitReleaseToClean = 1'b1;
    p_RXSNP__io_task_bits_snpHitReleaseToClean = g_RXSNP__io_task_bits_snpHitReleaseToClean;
    checks++;
    if (g_RXSNP__io_task_bits_snpHitReleaseWithData !== i_RXSNP__io_task_bits_snpHitReleaseWithData) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RXSNP.io_task_bits_snpHitReleaseWithData g=%h i=%h", cyc, g_RXSNP__io_task_bits_snpHitReleaseWithData, i_RXSNP__io_task_bits_snpHitReleaseWithData);
    end
    if (g_RXSNP__io_task_bits_snpHitReleaseWithData !== p_RXSNP__io_task_bits_snpHitReleaseWithData) t_RXSNP__io_task_bits_snpHitReleaseWithData = 1'b1;
    p_RXSNP__io_task_bits_snpHitReleaseWithData = g_RXSNP__io_task_bits_snpHitReleaseWithData;
    checks++;
    if (g_RXSNP__io_task_bits_snpHitReleaseIdx !== i_RXSNP__io_task_bits_snpHitReleaseIdx) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RXSNP.io_task_bits_snpHitReleaseIdx g=%h i=%h", cyc, g_RXSNP__io_task_bits_snpHitReleaseIdx, i_RXSNP__io_task_bits_snpHitReleaseIdx);
    end
    if (g_RXSNP__io_task_bits_snpHitReleaseIdx !== p_RXSNP__io_task_bits_snpHitReleaseIdx) t_RXSNP__io_task_bits_snpHitReleaseIdx = 1'b1;
    p_RXSNP__io_task_bits_snpHitReleaseIdx = g_RXSNP__io_task_bits_snpHitReleaseIdx;
    checks++;
    if (g_RXSNP__io_task_bits_snpHitReleaseMeta_dirty !== i_RXSNP__io_task_bits_snpHitReleaseMeta_dirty) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RXSNP.io_task_bits_snpHitReleaseMeta_dirty g=%h i=%h", cyc, g_RXSNP__io_task_bits_snpHitReleaseMeta_dirty, i_RXSNP__io_task_bits_snpHitReleaseMeta_dirty);
    end
    if (g_RXSNP__io_task_bits_snpHitReleaseMeta_dirty !== p_RXSNP__io_task_bits_snpHitReleaseMeta_dirty) t_RXSNP__io_task_bits_snpHitReleaseMeta_dirty = 1'b1;
    p_RXSNP__io_task_bits_snpHitReleaseMeta_dirty = g_RXSNP__io_task_bits_snpHitReleaseMeta_dirty;
    checks++;
    if (g_RXSNP__io_task_bits_snpHitReleaseMeta_state !== i_RXSNP__io_task_bits_snpHitReleaseMeta_state) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RXSNP.io_task_bits_snpHitReleaseMeta_state g=%h i=%h", cyc, g_RXSNP__io_task_bits_snpHitReleaseMeta_state, i_RXSNP__io_task_bits_snpHitReleaseMeta_state);
    end
    if (g_RXSNP__io_task_bits_snpHitReleaseMeta_state !== p_RXSNP__io_task_bits_snpHitReleaseMeta_state) t_RXSNP__io_task_bits_snpHitReleaseMeta_state = 1'b1;
    p_RXSNP__io_task_bits_snpHitReleaseMeta_state = g_RXSNP__io_task_bits_snpHitReleaseMeta_state;
    checks++;
    if (g_RXSNP__io_task_bits_snpHitReleaseMeta_clients !== i_RXSNP__io_task_bits_snpHitReleaseMeta_clients) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RXSNP.io_task_bits_snpHitReleaseMeta_clients g=%h i=%h", cyc, g_RXSNP__io_task_bits_snpHitReleaseMeta_clients, i_RXSNP__io_task_bits_snpHitReleaseMeta_clients);
    end
    if (g_RXSNP__io_task_bits_snpHitReleaseMeta_clients !== p_RXSNP__io_task_bits_snpHitReleaseMeta_clients) t_RXSNP__io_task_bits_snpHitReleaseMeta_clients = 1'b1;
    p_RXSNP__io_task_bits_snpHitReleaseMeta_clients = g_RXSNP__io_task_bits_snpHitReleaseMeta_clients;
    checks++;
    if (g_RXSNP__io_task_bits_snpHitReleaseMeta_alias !== i_RXSNP__io_task_bits_snpHitReleaseMeta_alias) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RXSNP.io_task_bits_snpHitReleaseMeta_alias g=%h i=%h", cyc, g_RXSNP__io_task_bits_snpHitReleaseMeta_alias, i_RXSNP__io_task_bits_snpHitReleaseMeta_alias);
    end
    if (g_RXSNP__io_task_bits_snpHitReleaseMeta_alias !== p_RXSNP__io_task_bits_snpHitReleaseMeta_alias) t_RXSNP__io_task_bits_snpHitReleaseMeta_alias = 1'b1;
    p_RXSNP__io_task_bits_snpHitReleaseMeta_alias = g_RXSNP__io_task_bits_snpHitReleaseMeta_alias;
    checks++;
    if (g_RXSNP__io_task_bits_snpHitReleaseMeta_prefetch !== i_RXSNP__io_task_bits_snpHitReleaseMeta_prefetch) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RXSNP.io_task_bits_snpHitReleaseMeta_prefetch g=%h i=%h", cyc, g_RXSNP__io_task_bits_snpHitReleaseMeta_prefetch, i_RXSNP__io_task_bits_snpHitReleaseMeta_prefetch);
    end
    if (g_RXSNP__io_task_bits_snpHitReleaseMeta_prefetch !== p_RXSNP__io_task_bits_snpHitReleaseMeta_prefetch) t_RXSNP__io_task_bits_snpHitReleaseMeta_prefetch = 1'b1;
    p_RXSNP__io_task_bits_snpHitReleaseMeta_prefetch = g_RXSNP__io_task_bits_snpHitReleaseMeta_prefetch;
    checks++;
    if (g_RXSNP__io_task_bits_snpHitReleaseMeta_prefetchSrc !== i_RXSNP__io_task_bits_snpHitReleaseMeta_prefetchSrc) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RXSNP.io_task_bits_snpHitReleaseMeta_prefetchSrc g=%h i=%h", cyc, g_RXSNP__io_task_bits_snpHitReleaseMeta_prefetchSrc, i_RXSNP__io_task_bits_snpHitReleaseMeta_prefetchSrc);
    end
    if (g_RXSNP__io_task_bits_snpHitReleaseMeta_prefetchSrc !== p_RXSNP__io_task_bits_snpHitReleaseMeta_prefetchSrc) t_RXSNP__io_task_bits_snpHitReleaseMeta_prefetchSrc = 1'b1;
    p_RXSNP__io_task_bits_snpHitReleaseMeta_prefetchSrc = g_RXSNP__io_task_bits_snpHitReleaseMeta_prefetchSrc;
    checks++;
    if (g_RXSNP__io_task_bits_snpHitReleaseMeta_accessed !== i_RXSNP__io_task_bits_snpHitReleaseMeta_accessed) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RXSNP.io_task_bits_snpHitReleaseMeta_accessed g=%h i=%h", cyc, g_RXSNP__io_task_bits_snpHitReleaseMeta_accessed, i_RXSNP__io_task_bits_snpHitReleaseMeta_accessed);
    end
    if (g_RXSNP__io_task_bits_snpHitReleaseMeta_accessed !== p_RXSNP__io_task_bits_snpHitReleaseMeta_accessed) t_RXSNP__io_task_bits_snpHitReleaseMeta_accessed = 1'b1;
    p_RXSNP__io_task_bits_snpHitReleaseMeta_accessed = g_RXSNP__io_task_bits_snpHitReleaseMeta_accessed;
    checks++;
    if (g_RXSNP__io_task_bits_snpHitReleaseMeta_tagErr !== i_RXSNP__io_task_bits_snpHitReleaseMeta_tagErr) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RXSNP.io_task_bits_snpHitReleaseMeta_tagErr g=%h i=%h", cyc, g_RXSNP__io_task_bits_snpHitReleaseMeta_tagErr, i_RXSNP__io_task_bits_snpHitReleaseMeta_tagErr);
    end
    if (g_RXSNP__io_task_bits_snpHitReleaseMeta_tagErr !== p_RXSNP__io_task_bits_snpHitReleaseMeta_tagErr) t_RXSNP__io_task_bits_snpHitReleaseMeta_tagErr = 1'b1;
    p_RXSNP__io_task_bits_snpHitReleaseMeta_tagErr = g_RXSNP__io_task_bits_snpHitReleaseMeta_tagErr;
    checks++;
    if (g_RXSNP__io_task_bits_snpHitReleaseMeta_dataErr !== i_RXSNP__io_task_bits_snpHitReleaseMeta_dataErr) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RXSNP.io_task_bits_snpHitReleaseMeta_dataErr g=%h i=%h", cyc, g_RXSNP__io_task_bits_snpHitReleaseMeta_dataErr, i_RXSNP__io_task_bits_snpHitReleaseMeta_dataErr);
    end
    if (g_RXSNP__io_task_bits_snpHitReleaseMeta_dataErr !== p_RXSNP__io_task_bits_snpHitReleaseMeta_dataErr) t_RXSNP__io_task_bits_snpHitReleaseMeta_dataErr = 1'b1;
    p_RXSNP__io_task_bits_snpHitReleaseMeta_dataErr = g_RXSNP__io_task_bits_snpHitReleaseMeta_dataErr;
    checks++;
    if (g_RXSNP__io_task_bits_srcID !== i_RXSNP__io_task_bits_srcID) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RXSNP.io_task_bits_srcID g=%h i=%h", cyc, g_RXSNP__io_task_bits_srcID, i_RXSNP__io_task_bits_srcID);
    end
    if (g_RXSNP__io_task_bits_srcID !== p_RXSNP__io_task_bits_srcID) t_RXSNP__io_task_bits_srcID = 1'b1;
    p_RXSNP__io_task_bits_srcID = g_RXSNP__io_task_bits_srcID;
    checks++;
    if (g_RXSNP__io_task_bits_txnID !== i_RXSNP__io_task_bits_txnID) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RXSNP.io_task_bits_txnID g=%h i=%h", cyc, g_RXSNP__io_task_bits_txnID, i_RXSNP__io_task_bits_txnID);
    end
    if (g_RXSNP__io_task_bits_txnID !== p_RXSNP__io_task_bits_txnID) t_RXSNP__io_task_bits_txnID = 1'b1;
    p_RXSNP__io_task_bits_txnID = g_RXSNP__io_task_bits_txnID;
    checks++;
    if (g_RXSNP__io_task_bits_fwdNID !== i_RXSNP__io_task_bits_fwdNID) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RXSNP.io_task_bits_fwdNID g=%h i=%h", cyc, g_RXSNP__io_task_bits_fwdNID, i_RXSNP__io_task_bits_fwdNID);
    end
    if (g_RXSNP__io_task_bits_fwdNID !== p_RXSNP__io_task_bits_fwdNID) t_RXSNP__io_task_bits_fwdNID = 1'b1;
    p_RXSNP__io_task_bits_fwdNID = g_RXSNP__io_task_bits_fwdNID;
    checks++;
    if (g_RXSNP__io_task_bits_fwdTxnID !== i_RXSNP__io_task_bits_fwdTxnID) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RXSNP.io_task_bits_fwdTxnID g=%h i=%h", cyc, g_RXSNP__io_task_bits_fwdTxnID, i_RXSNP__io_task_bits_fwdTxnID);
    end
    if (g_RXSNP__io_task_bits_fwdTxnID !== p_RXSNP__io_task_bits_fwdTxnID) t_RXSNP__io_task_bits_fwdTxnID = 1'b1;
    p_RXSNP__io_task_bits_fwdTxnID = g_RXSNP__io_task_bits_fwdTxnID;
    checks++;
    if (g_RXSNP__io_task_bits_chiOpcode !== i_RXSNP__io_task_bits_chiOpcode) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RXSNP.io_task_bits_chiOpcode g=%h i=%h", cyc, g_RXSNP__io_task_bits_chiOpcode, i_RXSNP__io_task_bits_chiOpcode);
    end
    if (g_RXSNP__io_task_bits_chiOpcode !== p_RXSNP__io_task_bits_chiOpcode) t_RXSNP__io_task_bits_chiOpcode = 1'b1;
    p_RXSNP__io_task_bits_chiOpcode = g_RXSNP__io_task_bits_chiOpcode;
    checks++;
    if (g_RXSNP__io_task_bits_retToSrc !== i_RXSNP__io_task_bits_retToSrc) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RXSNP.io_task_bits_retToSrc g=%h i=%h", cyc, g_RXSNP__io_task_bits_retToSrc, i_RXSNP__io_task_bits_retToSrc);
    end
    if (g_RXSNP__io_task_bits_retToSrc !== p_RXSNP__io_task_bits_retToSrc) t_RXSNP__io_task_bits_retToSrc = 1'b1;
    p_RXSNP__io_task_bits_retToSrc = g_RXSNP__io_task_bits_retToSrc;
    checks++;
    if (g_RXSNP__io_task_bits_traceTag !== i_RXSNP__io_task_bits_traceTag) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RXSNP.io_task_bits_traceTag g=%h i=%h", cyc, g_RXSNP__io_task_bits_traceTag, i_RXSNP__io_task_bits_traceTag);
    end
    if (g_RXSNP__io_task_bits_traceTag !== p_RXSNP__io_task_bits_traceTag) t_RXSNP__io_task_bits_traceTag = 1'b1;
    p_RXSNP__io_task_bits_traceTag = g_RXSNP__io_task_bits_traceTag;
  endtask
  longint cov_RXSNP_stall = 0;
  longint cov_RXSNP_fire = 0;
  longint cov_RXSNP_nest = 0;
  longint cov_RXSNP_nestIdxNZ = 0;
  longint cov_RXSNP_replBlk = 0;
  task automatic cover_RXSNP();
    if (u_g_RXSNP.stall) cov_RXSNP_stall++;
    if (u_g_RXSNP._GEN) cov_RXSNP_fire++;
    if (u_g_RXSNP.io_task_bits_snpHitRelease && u_g_RXSNP.io_task_valid) cov_RXSNP_nest++;
    if (u_g_RXSNP.io_task_bits_snpHitRelease && u_g_RXSNP.io_task_bits_snpHitReleaseIdx != 0) cov_RXSNP_nestIdxNZ++;
    if (u_g_RXSNP.replaceBlockSnp) cov_RXSNP_replBlk++;
  endtask
  task automatic preinit_RXSNP();
  endtask
  task automatic sync_RXSNP();
    u_i_RXSNP.queue.ram_ext.Memory = u_g_RXSNP.queue.ram_ext.Memory;
    force u_i_RXSNP.u_core.replPrevForBlock[0] = u_g_RXSNP.replaceBlockSnpMask_REG;
    #0 release u_i_RXSNP.u_core.replPrevForBlock[0];
    force u_i_RXSNP.u_core.replPrevForNest[0] = u_g_RXSNP.replaceNestSnpMask_REG;
    #0 release u_i_RXSNP.u_core.replPrevForNest[0];
    force u_i_RXSNP.u_core.replPrevForBlock[1] = u_g_RXSNP.replaceBlockSnpMask_REG_1;
    #0 release u_i_RXSNP.u_core.replPrevForBlock[1];
    force u_i_RXSNP.u_core.replPrevForNest[1] = u_g_RXSNP.replaceNestSnpMask_REG_1;
    #0 release u_i_RXSNP.u_core.replPrevForNest[1];
    force u_i_RXSNP.u_core.replPrevForBlock[2] = u_g_RXSNP.replaceBlockSnpMask_REG_2;
    #0 release u_i_RXSNP.u_core.replPrevForBlock[2];
    force u_i_RXSNP.u_core.replPrevForNest[2] = u_g_RXSNP.replaceNestSnpMask_REG_2;
    #0 release u_i_RXSNP.u_core.replPrevForNest[2];
    force u_i_RXSNP.u_core.replPrevForBlock[3] = u_g_RXSNP.replaceBlockSnpMask_REG_3;
    #0 release u_i_RXSNP.u_core.replPrevForBlock[3];
    force u_i_RXSNP.u_core.replPrevForNest[3] = u_g_RXSNP.replaceNestSnpMask_REG_3;
    #0 release u_i_RXSNP.u_core.replPrevForNest[3];
    force u_i_RXSNP.u_core.replPrevForBlock[4] = u_g_RXSNP.replaceBlockSnpMask_REG_4;
    #0 release u_i_RXSNP.u_core.replPrevForBlock[4];
    force u_i_RXSNP.u_core.replPrevForNest[4] = u_g_RXSNP.replaceNestSnpMask_REG_4;
    #0 release u_i_RXSNP.u_core.replPrevForNest[4];
    force u_i_RXSNP.u_core.replPrevForBlock[5] = u_g_RXSNP.replaceBlockSnpMask_REG_5;
    #0 release u_i_RXSNP.u_core.replPrevForBlock[5];
    force u_i_RXSNP.u_core.replPrevForNest[5] = u_g_RXSNP.replaceNestSnpMask_REG_5;
    #0 release u_i_RXSNP.u_core.replPrevForNest[5];
    force u_i_RXSNP.u_core.replPrevForBlock[6] = u_g_RXSNP.replaceBlockSnpMask_REG_6;
    #0 release u_i_RXSNP.u_core.replPrevForBlock[6];
    force u_i_RXSNP.u_core.replPrevForNest[6] = u_g_RXSNP.replaceNestSnpMask_REG_6;
    #0 release u_i_RXSNP.u_core.replPrevForNest[6];
    force u_i_RXSNP.u_core.replPrevForBlock[7] = u_g_RXSNP.replaceBlockSnpMask_REG_7;
    #0 release u_i_RXSNP.u_core.replPrevForBlock[7];
    force u_i_RXSNP.u_core.replPrevForNest[7] = u_g_RXSNP.replaceNestSnpMask_REG_7;
    #0 release u_i_RXSNP.u_core.replPrevForNest[7];
    force u_i_RXSNP.u_core.replPrevForBlock[8] = u_g_RXSNP.replaceBlockSnpMask_REG_8;
    #0 release u_i_RXSNP.u_core.replPrevForBlock[8];
    force u_i_RXSNP.u_core.replPrevForNest[8] = u_g_RXSNP.replaceNestSnpMask_REG_8;
    #0 release u_i_RXSNP.u_core.replPrevForNest[8];
    force u_i_RXSNP.u_core.replPrevForBlock[9] = u_g_RXSNP.replaceBlockSnpMask_REG_9;
    #0 release u_i_RXSNP.u_core.replPrevForBlock[9];
    force u_i_RXSNP.u_core.replPrevForNest[9] = u_g_RXSNP.replaceNestSnpMask_REG_9;
    #0 release u_i_RXSNP.u_core.replPrevForNest[9];
    force u_i_RXSNP.u_core.replPrevForBlock[10] = u_g_RXSNP.replaceBlockSnpMask_REG_10;
    #0 release u_i_RXSNP.u_core.replPrevForBlock[10];
    force u_i_RXSNP.u_core.replPrevForNest[10] = u_g_RXSNP.replaceNestSnpMask_REG_10;
    #0 release u_i_RXSNP.u_core.replPrevForNest[10];
    force u_i_RXSNP.u_core.replPrevForBlock[11] = u_g_RXSNP.replaceBlockSnpMask_REG_11;
    #0 release u_i_RXSNP.u_core.replPrevForBlock[11];
    force u_i_RXSNP.u_core.replPrevForNest[11] = u_g_RXSNP.replaceNestSnpMask_REG_11;
    #0 release u_i_RXSNP.u_core.replPrevForNest[11];
    force u_i_RXSNP.u_core.replPrevForBlock[12] = u_g_RXSNP.replaceBlockSnpMask_REG_12;
    #0 release u_i_RXSNP.u_core.replPrevForBlock[12];
    force u_i_RXSNP.u_core.replPrevForNest[12] = u_g_RXSNP.replaceNestSnpMask_REG_12;
    #0 release u_i_RXSNP.u_core.replPrevForNest[12];
    force u_i_RXSNP.u_core.replPrevForBlock[13] = u_g_RXSNP.replaceBlockSnpMask_REG_13;
    #0 release u_i_RXSNP.u_core.replPrevForBlock[13];
    force u_i_RXSNP.u_core.replPrevForNest[13] = u_g_RXSNP.replaceNestSnpMask_REG_13;
    #0 release u_i_RXSNP.u_core.replPrevForNest[13];
    force u_i_RXSNP.u_core.replPrevForBlock[14] = u_g_RXSNP.replaceBlockSnpMask_REG_14;
    #0 release u_i_RXSNP.u_core.replPrevForBlock[14];
    force u_i_RXSNP.u_core.replPrevForNest[14] = u_g_RXSNP.replaceNestSnpMask_REG_14;
    #0 release u_i_RXSNP.u_core.replPrevForNest[14];
    force u_i_RXSNP.u_core.replPrevForBlock[15] = u_g_RXSNP.replaceBlockSnpMask_REG_15;
    #0 release u_i_RXSNP.u_core.replPrevForBlock[15];
    force u_i_RXSNP.u_core.replPrevForNest[15] = u_g_RXSNP.replaceNestSnpMask_REG_15;
    #0 release u_i_RXSNP.u_core.replPrevForNest[15];
  endtask

  bit covfail = 0;
  initial begin
    void'($value$plusargs("ncycles=%d", NCYCLES));
    reset = 1'b1;
    drive_RXSNP();
    #1;
    preinit_RXSNP();
    sync_RXSNP();
    repeat (5) @(posedge clock);
    @(negedge clock) reset = 1'b0;
    for (cyc = 0; cyc < NCYCLES; cyc++) begin
      @(negedge clock);
      if (reset) reset = 1'b0; else if (($urandom % 5000) == 0) reset = 1'b1;
      drive_RXSNP();
      #1;
      check_RXSNP();
      cover_RXSNP();
    end
    begin int tg; tg = 0;
      if (t_RXSNP__io_rxsnp_ready) tg++; else $display("COV: RXSNP.io_rxsnp_ready never toggled");
      if (t_RXSNP__io_task_valid) tg++; else $display("COV: RXSNP.io_task_valid never toggled");
      if (t_RXSNP__io_task_bits_set) tg++; else $display("COV: RXSNP.io_task_bits_set never toggled");
      if (t_RXSNP__io_task_bits_tag) tg++; else $display("COV: RXSNP.io_task_bits_tag never toggled");
      if (t_RXSNP__io_task_bits_off) tg++; else $display("COV: RXSNP.io_task_bits_off never toggled");
      if (t_RXSNP__io_task_bits_snpHitRelease) tg++; else $display("COV: RXSNP.io_task_bits_snpHitRelease never toggled");
      if (t_RXSNP__io_task_bits_snpHitReleaseToInval) tg++; else $display("COV: RXSNP.io_task_bits_snpHitReleaseToInval never toggled");
      if (t_RXSNP__io_task_bits_snpHitReleaseToClean) tg++; else $display("COV: RXSNP.io_task_bits_snpHitReleaseToClean never toggled");
      if (t_RXSNP__io_task_bits_snpHitReleaseWithData) tg++; else $display("COV: RXSNP.io_task_bits_snpHitReleaseWithData never toggled");
      if (t_RXSNP__io_task_bits_snpHitReleaseIdx) tg++; else $display("COV: RXSNP.io_task_bits_snpHitReleaseIdx never toggled");
      if (t_RXSNP__io_task_bits_snpHitReleaseMeta_dirty) tg++; else $display("COV: RXSNP.io_task_bits_snpHitReleaseMeta_dirty never toggled");
      if (t_RXSNP__io_task_bits_snpHitReleaseMeta_state) tg++; else $display("COV: RXSNP.io_task_bits_snpHitReleaseMeta_state never toggled");
      if (t_RXSNP__io_task_bits_snpHitReleaseMeta_clients) tg++; else $display("COV: RXSNP.io_task_bits_snpHitReleaseMeta_clients never toggled");
      if (t_RXSNP__io_task_bits_snpHitReleaseMeta_alias) tg++; else $display("COV: RXSNP.io_task_bits_snpHitReleaseMeta_alias never toggled");
      if (t_RXSNP__io_task_bits_snpHitReleaseMeta_prefetch) tg++; else $display("COV: RXSNP.io_task_bits_snpHitReleaseMeta_prefetch never toggled");
      if (t_RXSNP__io_task_bits_snpHitReleaseMeta_prefetchSrc) tg++; else $display("COV: RXSNP.io_task_bits_snpHitReleaseMeta_prefetchSrc never toggled");
      if (t_RXSNP__io_task_bits_snpHitReleaseMeta_accessed) tg++; else $display("COV: RXSNP.io_task_bits_snpHitReleaseMeta_accessed never toggled");
      if (t_RXSNP__io_task_bits_snpHitReleaseMeta_tagErr) tg++; else $display("COV: RXSNP.io_task_bits_snpHitReleaseMeta_tagErr never toggled");
      if (t_RXSNP__io_task_bits_snpHitReleaseMeta_dataErr) tg++; else $display("COV: RXSNP.io_task_bits_snpHitReleaseMeta_dataErr never toggled");
      if (t_RXSNP__io_task_bits_srcID) tg++; else $display("COV: RXSNP.io_task_bits_srcID never toggled");
      if (t_RXSNP__io_task_bits_txnID) tg++; else $display("COV: RXSNP.io_task_bits_txnID never toggled");
      if (t_RXSNP__io_task_bits_fwdNID) tg++; else $display("COV: RXSNP.io_task_bits_fwdNID never toggled");
      if (t_RXSNP__io_task_bits_fwdTxnID) tg++; else $display("COV: RXSNP.io_task_bits_fwdTxnID never toggled");
      if (t_RXSNP__io_task_bits_chiOpcode) tg++; else $display("COV: RXSNP.io_task_bits_chiOpcode never toggled");
      if (t_RXSNP__io_task_bits_retToSrc) tg++; else $display("COV: RXSNP.io_task_bits_retToSrc never toggled");
      if (t_RXSNP__io_task_bits_traceTag) tg++; else $display("COV: RXSNP.io_task_bits_traceTag never toggled");
      $display("RXSNP: toggled=%0d/26 (need >= 26)", tg);
      if (tg < 26) covfail = 1;
      $display("RXSNP: cover stall = %0d", cov_RXSNP_stall);
      if (cov_RXSNP_stall == 0) covfail = 1;
      $display("RXSNP: cover fire = %0d", cov_RXSNP_fire);
      if (cov_RXSNP_fire == 0) covfail = 1;
      $display("RXSNP: cover nest = %0d", cov_RXSNP_nest);
      if (cov_RXSNP_nest == 0) covfail = 1;
      $display("RXSNP: cover nestIdxNZ = %0d", cov_RXSNP_nestIdxNZ);
      if (cov_RXSNP_nestIdxNZ == 0) covfail = 1;
      $display("RXSNP: cover replBlk = %0d", cov_RXSNP_replBlk);
      if (cov_RXSNP_replBlk == 0) covfail = 1;
    end
    $display("checks=%0d errors=%0d", checks, errors);
    if (errors != 0) begin $display("TEST FAILED (mismatch)"); $fatal(1); end
    if (checks == 0 || covfail) begin $display("TEST FAILED (coverage)"); $fatal(1); end
    $display("TEST PASSED");
    $finish;
  end
endmodule
