// RXSNP —— CHI RX-Snoop 接收/阻塞路由核 (可读重写, 手写 SV)
//
// 语义对应 coupledL2/tl2chi/RXSNP.scala:
//   * queue: 2 深 CHI-SNP 缓冲(golden Queue2_CHISNP, 内含 ram_2x98)。本核例化它,
//     FM 两侧均引入同一 golden 子模块做白盒等价(非黑盒)。
//   * task:  由 deq 出的 snp 地址拆成 {tag[44:14], set[13:5], off={addr[2:0],3'h0}}
//     并组装 TaskBundle 输出(io_task_*)。
//   * 16 路 MSHR 快照(io_msInfo_N)与 task 地址的组合匹配, 产生三种阻塞/嵌套掩码:
//       reqBlockSnpMask   : 命中 reqTag 的在飞请求, 需阻塞 snoop
//       cmoBlockSnp       : 命中 metaTag 且脏命中的 CMO/release, 需阻塞
//       replaceBlockSnp   : 命中 metaTag 的替换流(rProbe 未完), 需阻塞
//       replaceNestSnpMask: 命中 metaTag 的替换流(rProbe 已完), 需嵌套→驱动 snpHitRelease*
//     stall = |reqBlockSnpMask | replaceBlockSnp | cmoBlockSnp
//   * 32 个 RegNext(w_replResp) 延迟寄存器: golden 把同一 RegNext 复制成
//     replaceBlockSnpMask_REG_N(16) + replaceNestSnpMask_REG_N(16)。二者逐位相同,
//     本核用单份 replResp_d[N], 靠 verification_merge_duplicated_registers 与 golden 32 份配对。
//   * stallCnt(64bit): 仅在 `ifndef SYNTHESIS 的死锁断言里被读; SYNTHESIS 下 cone-dead。
//     忠实保留(async-reset), 与 golden stallCnt 形成对称死寄存器 bijection。
//
// 无 _GEN_/_T_ 机器噪声; 16 路匹配用 genvar+显式 assign(不在 generate 内用函数读模块信号)。

module xs_RXSNP_core(
  input         clock,
  input         reset,
  output        io_rxsnp_ready,
  input         io_rxsnp_valid,
  input  [3:0]  io_rxsnp_bits_qos,
  input  [10:0] io_rxsnp_bits_srcID,
  input  [11:0] io_rxsnp_bits_txnID,
  input  [10:0] io_rxsnp_bits_fwdNID,
  input  [11:0] io_rxsnp_bits_fwdTxnID,
  input  [4:0]  io_rxsnp_bits_opcode,
  input  [44:0] io_rxsnp_bits_addr,
  input         io_rxsnp_bits_ns,
  input         io_rxsnp_bits_doNotGoToSD,
  input         io_rxsnp_bits_retToSrc,
  input         io_rxsnp_bits_traceTag,
  input         io_rxsnp_bits_mpam_perfMonGroup,
  input  [8:0]  io_rxsnp_bits_mpam_partID,
  input         io_rxsnp_bits_mpam_mpamNS,
  input         io_task_ready,
  output        io_task_valid,
  output [8:0]  io_task_bits_set,
  output [30:0] io_task_bits_tag,
  output [5:0]  io_task_bits_off,
  output        io_task_bits_snpHitRelease,
  output        io_task_bits_snpHitReleaseToInval,
  output        io_task_bits_snpHitReleaseToClean,
  output        io_task_bits_snpHitReleaseWithData,
  output [7:0]  io_task_bits_snpHitReleaseIdx,
  output        io_task_bits_snpHitReleaseMeta_dirty,
  output [1:0]  io_task_bits_snpHitReleaseMeta_state,
  output        io_task_bits_snpHitReleaseMeta_clients,
  output [1:0]  io_task_bits_snpHitReleaseMeta_alias,
  output        io_task_bits_snpHitReleaseMeta_prefetch,
  output [2:0]  io_task_bits_snpHitReleaseMeta_prefetchSrc,
  output        io_task_bits_snpHitReleaseMeta_accessed,
  output        io_task_bits_snpHitReleaseMeta_tagErr,
  output        io_task_bits_snpHitReleaseMeta_dataErr,
  output [10:0] io_task_bits_srcID,
  output [11:0] io_task_bits_txnID,
  output [10:0] io_task_bits_fwdNID,
  output [11:0] io_task_bits_fwdTxnID,
  output [6:0]  io_task_bits_chiOpcode,
  output        io_task_bits_retToSrc,
  output        io_task_bits_traceTag,
  // 16 路 MSHR 信息快照 (ValidIO(MSHRInfo))
  input         io_msInfo_0_valid,
  input  [8:0]  io_msInfo_0_bits_set,
  input  [30:0] io_msInfo_0_bits_reqTag,
  input         io_msInfo_0_bits_willFree,
  input         io_msInfo_0_bits_aliasTask,
  input         io_msInfo_0_bits_blockRefill,
  input         io_msInfo_0_bits_meta_dirty,
  input  [1:0]  io_msInfo_0_bits_meta_state,
  input         io_msInfo_0_bits_meta_clients,
  input  [1:0]  io_msInfo_0_bits_meta_alias,
  input         io_msInfo_0_bits_meta_prefetch,
  input  [2:0]  io_msInfo_0_bits_meta_prefetchSrc,
  input         io_msInfo_0_bits_meta_accessed,
  input         io_msInfo_0_bits_meta_tagErr,
  input         io_msInfo_0_bits_meta_dataErr,
  input  [30:0] io_msInfo_0_bits_metaTag,
  input         io_msInfo_0_bits_dirHit,
  input         io_msInfo_0_bits_w_grantfirst,
  input         io_msInfo_0_bits_s_release,
  input         io_msInfo_0_bits_s_cmoresp,
  input         io_msInfo_0_bits_s_cmometaw,
  input         io_msInfo_0_bits_w_releaseack,
  input         io_msInfo_0_bits_w_replResp,
  input         io_msInfo_0_bits_w_rprobeacklast,
  input         io_msInfo_0_bits_replaceData,
  input         io_msInfo_0_bits_releaseToClean,
  input         io_msInfo_1_valid,
  input  [8:0]  io_msInfo_1_bits_set,
  input  [30:0] io_msInfo_1_bits_reqTag,
  input         io_msInfo_1_bits_willFree,
  input         io_msInfo_1_bits_aliasTask,
  input         io_msInfo_1_bits_blockRefill,
  input         io_msInfo_1_bits_meta_dirty,
  input  [1:0]  io_msInfo_1_bits_meta_state,
  input         io_msInfo_1_bits_meta_clients,
  input  [1:0]  io_msInfo_1_bits_meta_alias,
  input         io_msInfo_1_bits_meta_prefetch,
  input  [2:0]  io_msInfo_1_bits_meta_prefetchSrc,
  input         io_msInfo_1_bits_meta_accessed,
  input         io_msInfo_1_bits_meta_tagErr,
  input         io_msInfo_1_bits_meta_dataErr,
  input  [30:0] io_msInfo_1_bits_metaTag,
  input         io_msInfo_1_bits_dirHit,
  input         io_msInfo_1_bits_w_grantfirst,
  input         io_msInfo_1_bits_s_release,
  input         io_msInfo_1_bits_s_cmoresp,
  input         io_msInfo_1_bits_s_cmometaw,
  input         io_msInfo_1_bits_w_releaseack,
  input         io_msInfo_1_bits_w_replResp,
  input         io_msInfo_1_bits_w_rprobeacklast,
  input         io_msInfo_1_bits_replaceData,
  input         io_msInfo_1_bits_releaseToClean,
  input         io_msInfo_2_valid,
  input  [8:0]  io_msInfo_2_bits_set,
  input  [30:0] io_msInfo_2_bits_reqTag,
  input         io_msInfo_2_bits_willFree,
  input         io_msInfo_2_bits_aliasTask,
  input         io_msInfo_2_bits_blockRefill,
  input         io_msInfo_2_bits_meta_dirty,
  input  [1:0]  io_msInfo_2_bits_meta_state,
  input         io_msInfo_2_bits_meta_clients,
  input  [1:0]  io_msInfo_2_bits_meta_alias,
  input         io_msInfo_2_bits_meta_prefetch,
  input  [2:0]  io_msInfo_2_bits_meta_prefetchSrc,
  input         io_msInfo_2_bits_meta_accessed,
  input         io_msInfo_2_bits_meta_tagErr,
  input         io_msInfo_2_bits_meta_dataErr,
  input  [30:0] io_msInfo_2_bits_metaTag,
  input         io_msInfo_2_bits_dirHit,
  input         io_msInfo_2_bits_w_grantfirst,
  input         io_msInfo_2_bits_s_release,
  input         io_msInfo_2_bits_s_cmoresp,
  input         io_msInfo_2_bits_s_cmometaw,
  input         io_msInfo_2_bits_w_releaseack,
  input         io_msInfo_2_bits_w_replResp,
  input         io_msInfo_2_bits_w_rprobeacklast,
  input         io_msInfo_2_bits_replaceData,
  input         io_msInfo_2_bits_releaseToClean,
  input         io_msInfo_3_valid,
  input  [8:0]  io_msInfo_3_bits_set,
  input  [30:0] io_msInfo_3_bits_reqTag,
  input         io_msInfo_3_bits_willFree,
  input         io_msInfo_3_bits_aliasTask,
  input         io_msInfo_3_bits_blockRefill,
  input         io_msInfo_3_bits_meta_dirty,
  input  [1:0]  io_msInfo_3_bits_meta_state,
  input         io_msInfo_3_bits_meta_clients,
  input  [1:0]  io_msInfo_3_bits_meta_alias,
  input         io_msInfo_3_bits_meta_prefetch,
  input  [2:0]  io_msInfo_3_bits_meta_prefetchSrc,
  input         io_msInfo_3_bits_meta_accessed,
  input         io_msInfo_3_bits_meta_tagErr,
  input         io_msInfo_3_bits_meta_dataErr,
  input  [30:0] io_msInfo_3_bits_metaTag,
  input         io_msInfo_3_bits_dirHit,
  input         io_msInfo_3_bits_w_grantfirst,
  input         io_msInfo_3_bits_s_release,
  input         io_msInfo_3_bits_s_cmoresp,
  input         io_msInfo_3_bits_s_cmometaw,
  input         io_msInfo_3_bits_w_releaseack,
  input         io_msInfo_3_bits_w_replResp,
  input         io_msInfo_3_bits_w_rprobeacklast,
  input         io_msInfo_3_bits_replaceData,
  input         io_msInfo_3_bits_releaseToClean,
  input         io_msInfo_4_valid,
  input  [8:0]  io_msInfo_4_bits_set,
  input  [30:0] io_msInfo_4_bits_reqTag,
  input         io_msInfo_4_bits_willFree,
  input         io_msInfo_4_bits_aliasTask,
  input         io_msInfo_4_bits_blockRefill,
  input         io_msInfo_4_bits_meta_dirty,
  input  [1:0]  io_msInfo_4_bits_meta_state,
  input         io_msInfo_4_bits_meta_clients,
  input  [1:0]  io_msInfo_4_bits_meta_alias,
  input         io_msInfo_4_bits_meta_prefetch,
  input  [2:0]  io_msInfo_4_bits_meta_prefetchSrc,
  input         io_msInfo_4_bits_meta_accessed,
  input         io_msInfo_4_bits_meta_tagErr,
  input         io_msInfo_4_bits_meta_dataErr,
  input  [30:0] io_msInfo_4_bits_metaTag,
  input         io_msInfo_4_bits_dirHit,
  input         io_msInfo_4_bits_w_grantfirst,
  input         io_msInfo_4_bits_s_release,
  input         io_msInfo_4_bits_s_cmoresp,
  input         io_msInfo_4_bits_s_cmometaw,
  input         io_msInfo_4_bits_w_releaseack,
  input         io_msInfo_4_bits_w_replResp,
  input         io_msInfo_4_bits_w_rprobeacklast,
  input         io_msInfo_4_bits_replaceData,
  input         io_msInfo_4_bits_releaseToClean,
  input         io_msInfo_5_valid,
  input  [8:0]  io_msInfo_5_bits_set,
  input  [30:0] io_msInfo_5_bits_reqTag,
  input         io_msInfo_5_bits_willFree,
  input         io_msInfo_5_bits_aliasTask,
  input         io_msInfo_5_bits_blockRefill,
  input         io_msInfo_5_bits_meta_dirty,
  input  [1:0]  io_msInfo_5_bits_meta_state,
  input         io_msInfo_5_bits_meta_clients,
  input  [1:0]  io_msInfo_5_bits_meta_alias,
  input         io_msInfo_5_bits_meta_prefetch,
  input  [2:0]  io_msInfo_5_bits_meta_prefetchSrc,
  input         io_msInfo_5_bits_meta_accessed,
  input         io_msInfo_5_bits_meta_tagErr,
  input         io_msInfo_5_bits_meta_dataErr,
  input  [30:0] io_msInfo_5_bits_metaTag,
  input         io_msInfo_5_bits_dirHit,
  input         io_msInfo_5_bits_w_grantfirst,
  input         io_msInfo_5_bits_s_release,
  input         io_msInfo_5_bits_s_cmoresp,
  input         io_msInfo_5_bits_s_cmometaw,
  input         io_msInfo_5_bits_w_releaseack,
  input         io_msInfo_5_bits_w_replResp,
  input         io_msInfo_5_bits_w_rprobeacklast,
  input         io_msInfo_5_bits_replaceData,
  input         io_msInfo_5_bits_releaseToClean,
  input         io_msInfo_6_valid,
  input  [8:0]  io_msInfo_6_bits_set,
  input  [30:0] io_msInfo_6_bits_reqTag,
  input         io_msInfo_6_bits_willFree,
  input         io_msInfo_6_bits_aliasTask,
  input         io_msInfo_6_bits_blockRefill,
  input         io_msInfo_6_bits_meta_dirty,
  input  [1:0]  io_msInfo_6_bits_meta_state,
  input         io_msInfo_6_bits_meta_clients,
  input  [1:0]  io_msInfo_6_bits_meta_alias,
  input         io_msInfo_6_bits_meta_prefetch,
  input  [2:0]  io_msInfo_6_bits_meta_prefetchSrc,
  input         io_msInfo_6_bits_meta_accessed,
  input         io_msInfo_6_bits_meta_tagErr,
  input         io_msInfo_6_bits_meta_dataErr,
  input  [30:0] io_msInfo_6_bits_metaTag,
  input         io_msInfo_6_bits_dirHit,
  input         io_msInfo_6_bits_w_grantfirst,
  input         io_msInfo_6_bits_s_release,
  input         io_msInfo_6_bits_s_cmoresp,
  input         io_msInfo_6_bits_s_cmometaw,
  input         io_msInfo_6_bits_w_releaseack,
  input         io_msInfo_6_bits_w_replResp,
  input         io_msInfo_6_bits_w_rprobeacklast,
  input         io_msInfo_6_bits_replaceData,
  input         io_msInfo_6_bits_releaseToClean,
  input         io_msInfo_7_valid,
  input  [8:0]  io_msInfo_7_bits_set,
  input  [30:0] io_msInfo_7_bits_reqTag,
  input         io_msInfo_7_bits_willFree,
  input         io_msInfo_7_bits_aliasTask,
  input         io_msInfo_7_bits_blockRefill,
  input         io_msInfo_7_bits_meta_dirty,
  input  [1:0]  io_msInfo_7_bits_meta_state,
  input         io_msInfo_7_bits_meta_clients,
  input  [1:0]  io_msInfo_7_bits_meta_alias,
  input         io_msInfo_7_bits_meta_prefetch,
  input  [2:0]  io_msInfo_7_bits_meta_prefetchSrc,
  input         io_msInfo_7_bits_meta_accessed,
  input         io_msInfo_7_bits_meta_tagErr,
  input         io_msInfo_7_bits_meta_dataErr,
  input  [30:0] io_msInfo_7_bits_metaTag,
  input         io_msInfo_7_bits_dirHit,
  input         io_msInfo_7_bits_w_grantfirst,
  input         io_msInfo_7_bits_s_release,
  input         io_msInfo_7_bits_s_cmoresp,
  input         io_msInfo_7_bits_s_cmometaw,
  input         io_msInfo_7_bits_w_releaseack,
  input         io_msInfo_7_bits_w_replResp,
  input         io_msInfo_7_bits_w_rprobeacklast,
  input         io_msInfo_7_bits_replaceData,
  input         io_msInfo_7_bits_releaseToClean,
  input         io_msInfo_8_valid,
  input  [8:0]  io_msInfo_8_bits_set,
  input  [30:0] io_msInfo_8_bits_reqTag,
  input         io_msInfo_8_bits_willFree,
  input         io_msInfo_8_bits_aliasTask,
  input         io_msInfo_8_bits_blockRefill,
  input         io_msInfo_8_bits_meta_dirty,
  input  [1:0]  io_msInfo_8_bits_meta_state,
  input         io_msInfo_8_bits_meta_clients,
  input  [1:0]  io_msInfo_8_bits_meta_alias,
  input         io_msInfo_8_bits_meta_prefetch,
  input  [2:0]  io_msInfo_8_bits_meta_prefetchSrc,
  input         io_msInfo_8_bits_meta_accessed,
  input         io_msInfo_8_bits_meta_tagErr,
  input         io_msInfo_8_bits_meta_dataErr,
  input  [30:0] io_msInfo_8_bits_metaTag,
  input         io_msInfo_8_bits_dirHit,
  input         io_msInfo_8_bits_w_grantfirst,
  input         io_msInfo_8_bits_s_release,
  input         io_msInfo_8_bits_s_cmoresp,
  input         io_msInfo_8_bits_s_cmometaw,
  input         io_msInfo_8_bits_w_releaseack,
  input         io_msInfo_8_bits_w_replResp,
  input         io_msInfo_8_bits_w_rprobeacklast,
  input         io_msInfo_8_bits_replaceData,
  input         io_msInfo_8_bits_releaseToClean,
  input         io_msInfo_9_valid,
  input  [8:0]  io_msInfo_9_bits_set,
  input  [30:0] io_msInfo_9_bits_reqTag,
  input         io_msInfo_9_bits_willFree,
  input         io_msInfo_9_bits_aliasTask,
  input         io_msInfo_9_bits_blockRefill,
  input         io_msInfo_9_bits_meta_dirty,
  input  [1:0]  io_msInfo_9_bits_meta_state,
  input         io_msInfo_9_bits_meta_clients,
  input  [1:0]  io_msInfo_9_bits_meta_alias,
  input         io_msInfo_9_bits_meta_prefetch,
  input  [2:0]  io_msInfo_9_bits_meta_prefetchSrc,
  input         io_msInfo_9_bits_meta_accessed,
  input         io_msInfo_9_bits_meta_tagErr,
  input         io_msInfo_9_bits_meta_dataErr,
  input  [30:0] io_msInfo_9_bits_metaTag,
  input         io_msInfo_9_bits_dirHit,
  input         io_msInfo_9_bits_w_grantfirst,
  input         io_msInfo_9_bits_s_release,
  input         io_msInfo_9_bits_s_cmoresp,
  input         io_msInfo_9_bits_s_cmometaw,
  input         io_msInfo_9_bits_w_releaseack,
  input         io_msInfo_9_bits_w_replResp,
  input         io_msInfo_9_bits_w_rprobeacklast,
  input         io_msInfo_9_bits_replaceData,
  input         io_msInfo_9_bits_releaseToClean,
  input         io_msInfo_10_valid,
  input  [8:0]  io_msInfo_10_bits_set,
  input  [30:0] io_msInfo_10_bits_reqTag,
  input         io_msInfo_10_bits_willFree,
  input         io_msInfo_10_bits_aliasTask,
  input         io_msInfo_10_bits_blockRefill,
  input         io_msInfo_10_bits_meta_dirty,
  input  [1:0]  io_msInfo_10_bits_meta_state,
  input         io_msInfo_10_bits_meta_clients,
  input  [1:0]  io_msInfo_10_bits_meta_alias,
  input         io_msInfo_10_bits_meta_prefetch,
  input  [2:0]  io_msInfo_10_bits_meta_prefetchSrc,
  input         io_msInfo_10_bits_meta_accessed,
  input         io_msInfo_10_bits_meta_tagErr,
  input         io_msInfo_10_bits_meta_dataErr,
  input  [30:0] io_msInfo_10_bits_metaTag,
  input         io_msInfo_10_bits_dirHit,
  input         io_msInfo_10_bits_w_grantfirst,
  input         io_msInfo_10_bits_s_release,
  input         io_msInfo_10_bits_s_cmoresp,
  input         io_msInfo_10_bits_s_cmometaw,
  input         io_msInfo_10_bits_w_releaseack,
  input         io_msInfo_10_bits_w_replResp,
  input         io_msInfo_10_bits_w_rprobeacklast,
  input         io_msInfo_10_bits_replaceData,
  input         io_msInfo_10_bits_releaseToClean,
  input         io_msInfo_11_valid,
  input  [8:0]  io_msInfo_11_bits_set,
  input  [30:0] io_msInfo_11_bits_reqTag,
  input         io_msInfo_11_bits_willFree,
  input         io_msInfo_11_bits_aliasTask,
  input         io_msInfo_11_bits_blockRefill,
  input         io_msInfo_11_bits_meta_dirty,
  input  [1:0]  io_msInfo_11_bits_meta_state,
  input         io_msInfo_11_bits_meta_clients,
  input  [1:0]  io_msInfo_11_bits_meta_alias,
  input         io_msInfo_11_bits_meta_prefetch,
  input  [2:0]  io_msInfo_11_bits_meta_prefetchSrc,
  input         io_msInfo_11_bits_meta_accessed,
  input         io_msInfo_11_bits_meta_tagErr,
  input         io_msInfo_11_bits_meta_dataErr,
  input  [30:0] io_msInfo_11_bits_metaTag,
  input         io_msInfo_11_bits_dirHit,
  input         io_msInfo_11_bits_w_grantfirst,
  input         io_msInfo_11_bits_s_release,
  input         io_msInfo_11_bits_s_cmoresp,
  input         io_msInfo_11_bits_s_cmometaw,
  input         io_msInfo_11_bits_w_releaseack,
  input         io_msInfo_11_bits_w_replResp,
  input         io_msInfo_11_bits_w_rprobeacklast,
  input         io_msInfo_11_bits_replaceData,
  input         io_msInfo_11_bits_releaseToClean,
  input         io_msInfo_12_valid,
  input  [8:0]  io_msInfo_12_bits_set,
  input  [30:0] io_msInfo_12_bits_reqTag,
  input         io_msInfo_12_bits_willFree,
  input         io_msInfo_12_bits_aliasTask,
  input         io_msInfo_12_bits_blockRefill,
  input         io_msInfo_12_bits_meta_dirty,
  input  [1:0]  io_msInfo_12_bits_meta_state,
  input         io_msInfo_12_bits_meta_clients,
  input  [1:0]  io_msInfo_12_bits_meta_alias,
  input         io_msInfo_12_bits_meta_prefetch,
  input  [2:0]  io_msInfo_12_bits_meta_prefetchSrc,
  input         io_msInfo_12_bits_meta_accessed,
  input         io_msInfo_12_bits_meta_tagErr,
  input         io_msInfo_12_bits_meta_dataErr,
  input  [30:0] io_msInfo_12_bits_metaTag,
  input         io_msInfo_12_bits_dirHit,
  input         io_msInfo_12_bits_w_grantfirst,
  input         io_msInfo_12_bits_s_release,
  input         io_msInfo_12_bits_s_cmoresp,
  input         io_msInfo_12_bits_s_cmometaw,
  input         io_msInfo_12_bits_w_releaseack,
  input         io_msInfo_12_bits_w_replResp,
  input         io_msInfo_12_bits_w_rprobeacklast,
  input         io_msInfo_12_bits_replaceData,
  input         io_msInfo_12_bits_releaseToClean,
  input         io_msInfo_13_valid,
  input  [8:0]  io_msInfo_13_bits_set,
  input  [30:0] io_msInfo_13_bits_reqTag,
  input         io_msInfo_13_bits_willFree,
  input         io_msInfo_13_bits_aliasTask,
  input         io_msInfo_13_bits_blockRefill,
  input         io_msInfo_13_bits_meta_dirty,
  input  [1:0]  io_msInfo_13_bits_meta_state,
  input         io_msInfo_13_bits_meta_clients,
  input  [1:0]  io_msInfo_13_bits_meta_alias,
  input         io_msInfo_13_bits_meta_prefetch,
  input  [2:0]  io_msInfo_13_bits_meta_prefetchSrc,
  input         io_msInfo_13_bits_meta_accessed,
  input         io_msInfo_13_bits_meta_tagErr,
  input         io_msInfo_13_bits_meta_dataErr,
  input  [30:0] io_msInfo_13_bits_metaTag,
  input         io_msInfo_13_bits_dirHit,
  input         io_msInfo_13_bits_w_grantfirst,
  input         io_msInfo_13_bits_s_release,
  input         io_msInfo_13_bits_s_cmoresp,
  input         io_msInfo_13_bits_s_cmometaw,
  input         io_msInfo_13_bits_w_releaseack,
  input         io_msInfo_13_bits_w_replResp,
  input         io_msInfo_13_bits_w_rprobeacklast,
  input         io_msInfo_13_bits_replaceData,
  input         io_msInfo_13_bits_releaseToClean,
  input         io_msInfo_14_valid,
  input  [8:0]  io_msInfo_14_bits_set,
  input  [30:0] io_msInfo_14_bits_reqTag,
  input         io_msInfo_14_bits_willFree,
  input         io_msInfo_14_bits_aliasTask,
  input         io_msInfo_14_bits_blockRefill,
  input         io_msInfo_14_bits_meta_dirty,
  input  [1:0]  io_msInfo_14_bits_meta_state,
  input         io_msInfo_14_bits_meta_clients,
  input  [1:0]  io_msInfo_14_bits_meta_alias,
  input         io_msInfo_14_bits_meta_prefetch,
  input  [2:0]  io_msInfo_14_bits_meta_prefetchSrc,
  input         io_msInfo_14_bits_meta_accessed,
  input         io_msInfo_14_bits_meta_tagErr,
  input         io_msInfo_14_bits_meta_dataErr,
  input  [30:0] io_msInfo_14_bits_metaTag,
  input         io_msInfo_14_bits_dirHit,
  input         io_msInfo_14_bits_w_grantfirst,
  input         io_msInfo_14_bits_s_release,
  input         io_msInfo_14_bits_s_cmoresp,
  input         io_msInfo_14_bits_s_cmometaw,
  input         io_msInfo_14_bits_w_releaseack,
  input         io_msInfo_14_bits_w_replResp,
  input         io_msInfo_14_bits_w_rprobeacklast,
  input         io_msInfo_14_bits_replaceData,
  input         io_msInfo_14_bits_releaseToClean,
  input         io_msInfo_15_valid,
  input  [8:0]  io_msInfo_15_bits_set,
  input  [30:0] io_msInfo_15_bits_reqTag,
  input         io_msInfo_15_bits_willFree,
  input         io_msInfo_15_bits_aliasTask,
  input         io_msInfo_15_bits_blockRefill,
  input         io_msInfo_15_bits_meta_dirty,
  input  [1:0]  io_msInfo_15_bits_meta_state,
  input         io_msInfo_15_bits_meta_clients,
  input  [1:0]  io_msInfo_15_bits_meta_alias,
  input         io_msInfo_15_bits_meta_prefetch,
  input  [2:0]  io_msInfo_15_bits_meta_prefetchSrc,
  input         io_msInfo_15_bits_meta_accessed,
  input         io_msInfo_15_bits_meta_tagErr,
  input         io_msInfo_15_bits_meta_dataErr,
  input  [30:0] io_msInfo_15_bits_metaTag,
  input         io_msInfo_15_bits_dirHit,
  input         io_msInfo_15_bits_w_grantfirst,
  input         io_msInfo_15_bits_s_release,
  input         io_msInfo_15_bits_s_cmoresp,
  input         io_msInfo_15_bits_s_cmometaw,
  input         io_msInfo_15_bits_w_releaseack,
  input         io_msInfo_15_bits_w_replResp,
  input         io_msInfo_15_bits_w_rprobeacklast,
  input         io_msInfo_15_bits_replaceData,
  input         io_msInfo_15_bits_releaseToClean
);

  localparam int MSHRS = 16;

  // -------------------------------------------------------------------------
  // 1) 把 16 路扁平 msInfo 端口打包成数组, 便于 genvar 组合匹配。
  // -------------------------------------------------------------------------
  logic         ms_valid          [MSHRS];
  logic [8:0]   ms_set            [MSHRS];
  logic [30:0]  ms_reqTag         [MSHRS];
  logic [30:0]  ms_metaTag        [MSHRS];
  logic         ms_willFree       [MSHRS];
  logic         ms_aliasTask      [MSHRS];
  logic         ms_blockRefill    [MSHRS];
  logic         ms_dirHit         [MSHRS];
  logic [1:0]   ms_meta_state     [MSHRS];
  logic         ms_meta_dirty     [MSHRS];
  logic         ms_meta_clients   [MSHRS];
  logic [1:0]   ms_meta_alias     [MSHRS];
  logic         ms_meta_prefetch  [MSHRS];
  logic [2:0]   ms_meta_prefetchSrc[MSHRS];
  logic         ms_meta_accessed  [MSHRS];
  logic         ms_meta_tagErr    [MSHRS];
  logic         ms_meta_dataErr   [MSHRS];
  logic         ms_w_grantfirst   [MSHRS];
  logic         ms_s_release      [MSHRS];
  logic         ms_s_cmoresp      [MSHRS];
  logic         ms_s_cmometaw     [MSHRS];
  logic         ms_w_releaseack   [MSHRS];
  logic         ms_w_replResp     [MSHRS];
  logic         ms_w_rprobeacklast[MSHRS];
  logic         ms_replaceData    [MSHRS];
  logic         ms_releaseToClean [MSHRS];

  always_comb begin
    ms_valid[0]=io_msInfo_0_valid; ms_set[0]=io_msInfo_0_bits_set; ms_reqTag[0]=io_msInfo_0_bits_reqTag; ms_metaTag[0]=io_msInfo_0_bits_metaTag; ms_willFree[0]=io_msInfo_0_bits_willFree; ms_aliasTask[0]=io_msInfo_0_bits_aliasTask; ms_blockRefill[0]=io_msInfo_0_bits_blockRefill; ms_dirHit[0]=io_msInfo_0_bits_dirHit; ms_meta_state[0]=io_msInfo_0_bits_meta_state; ms_meta_dirty[0]=io_msInfo_0_bits_meta_dirty; ms_meta_clients[0]=io_msInfo_0_bits_meta_clients; ms_meta_alias[0]=io_msInfo_0_bits_meta_alias; ms_meta_prefetch[0]=io_msInfo_0_bits_meta_prefetch; ms_meta_prefetchSrc[0]=io_msInfo_0_bits_meta_prefetchSrc; ms_meta_accessed[0]=io_msInfo_0_bits_meta_accessed; ms_meta_tagErr[0]=io_msInfo_0_bits_meta_tagErr; ms_meta_dataErr[0]=io_msInfo_0_bits_meta_dataErr; ms_w_grantfirst[0]=io_msInfo_0_bits_w_grantfirst; ms_s_release[0]=io_msInfo_0_bits_s_release; ms_s_cmoresp[0]=io_msInfo_0_bits_s_cmoresp; ms_s_cmometaw[0]=io_msInfo_0_bits_s_cmometaw; ms_w_releaseack[0]=io_msInfo_0_bits_w_releaseack; ms_w_replResp[0]=io_msInfo_0_bits_w_replResp; ms_w_rprobeacklast[0]=io_msInfo_0_bits_w_rprobeacklast; ms_replaceData[0]=io_msInfo_0_bits_replaceData; ms_releaseToClean[0]=io_msInfo_0_bits_releaseToClean;
    ms_valid[1]=io_msInfo_1_valid; ms_set[1]=io_msInfo_1_bits_set; ms_reqTag[1]=io_msInfo_1_bits_reqTag; ms_metaTag[1]=io_msInfo_1_bits_metaTag; ms_willFree[1]=io_msInfo_1_bits_willFree; ms_aliasTask[1]=io_msInfo_1_bits_aliasTask; ms_blockRefill[1]=io_msInfo_1_bits_blockRefill; ms_dirHit[1]=io_msInfo_1_bits_dirHit; ms_meta_state[1]=io_msInfo_1_bits_meta_state; ms_meta_dirty[1]=io_msInfo_1_bits_meta_dirty; ms_meta_clients[1]=io_msInfo_1_bits_meta_clients; ms_meta_alias[1]=io_msInfo_1_bits_meta_alias; ms_meta_prefetch[1]=io_msInfo_1_bits_meta_prefetch; ms_meta_prefetchSrc[1]=io_msInfo_1_bits_meta_prefetchSrc; ms_meta_accessed[1]=io_msInfo_1_bits_meta_accessed; ms_meta_tagErr[1]=io_msInfo_1_bits_meta_tagErr; ms_meta_dataErr[1]=io_msInfo_1_bits_meta_dataErr; ms_w_grantfirst[1]=io_msInfo_1_bits_w_grantfirst; ms_s_release[1]=io_msInfo_1_bits_s_release; ms_s_cmoresp[1]=io_msInfo_1_bits_s_cmoresp; ms_s_cmometaw[1]=io_msInfo_1_bits_s_cmometaw; ms_w_releaseack[1]=io_msInfo_1_bits_w_releaseack; ms_w_replResp[1]=io_msInfo_1_bits_w_replResp; ms_w_rprobeacklast[1]=io_msInfo_1_bits_w_rprobeacklast; ms_replaceData[1]=io_msInfo_1_bits_replaceData; ms_releaseToClean[1]=io_msInfo_1_bits_releaseToClean;
    ms_valid[2]=io_msInfo_2_valid; ms_set[2]=io_msInfo_2_bits_set; ms_reqTag[2]=io_msInfo_2_bits_reqTag; ms_metaTag[2]=io_msInfo_2_bits_metaTag; ms_willFree[2]=io_msInfo_2_bits_willFree; ms_aliasTask[2]=io_msInfo_2_bits_aliasTask; ms_blockRefill[2]=io_msInfo_2_bits_blockRefill; ms_dirHit[2]=io_msInfo_2_bits_dirHit; ms_meta_state[2]=io_msInfo_2_bits_meta_state; ms_meta_dirty[2]=io_msInfo_2_bits_meta_dirty; ms_meta_clients[2]=io_msInfo_2_bits_meta_clients; ms_meta_alias[2]=io_msInfo_2_bits_meta_alias; ms_meta_prefetch[2]=io_msInfo_2_bits_meta_prefetch; ms_meta_prefetchSrc[2]=io_msInfo_2_bits_meta_prefetchSrc; ms_meta_accessed[2]=io_msInfo_2_bits_meta_accessed; ms_meta_tagErr[2]=io_msInfo_2_bits_meta_tagErr; ms_meta_dataErr[2]=io_msInfo_2_bits_meta_dataErr; ms_w_grantfirst[2]=io_msInfo_2_bits_w_grantfirst; ms_s_release[2]=io_msInfo_2_bits_s_release; ms_s_cmoresp[2]=io_msInfo_2_bits_s_cmoresp; ms_s_cmometaw[2]=io_msInfo_2_bits_s_cmometaw; ms_w_releaseack[2]=io_msInfo_2_bits_w_releaseack; ms_w_replResp[2]=io_msInfo_2_bits_w_replResp; ms_w_rprobeacklast[2]=io_msInfo_2_bits_w_rprobeacklast; ms_replaceData[2]=io_msInfo_2_bits_replaceData; ms_releaseToClean[2]=io_msInfo_2_bits_releaseToClean;
    ms_valid[3]=io_msInfo_3_valid; ms_set[3]=io_msInfo_3_bits_set; ms_reqTag[3]=io_msInfo_3_bits_reqTag; ms_metaTag[3]=io_msInfo_3_bits_metaTag; ms_willFree[3]=io_msInfo_3_bits_willFree; ms_aliasTask[3]=io_msInfo_3_bits_aliasTask; ms_blockRefill[3]=io_msInfo_3_bits_blockRefill; ms_dirHit[3]=io_msInfo_3_bits_dirHit; ms_meta_state[3]=io_msInfo_3_bits_meta_state; ms_meta_dirty[3]=io_msInfo_3_bits_meta_dirty; ms_meta_clients[3]=io_msInfo_3_bits_meta_clients; ms_meta_alias[3]=io_msInfo_3_bits_meta_alias; ms_meta_prefetch[3]=io_msInfo_3_bits_meta_prefetch; ms_meta_prefetchSrc[3]=io_msInfo_3_bits_meta_prefetchSrc; ms_meta_accessed[3]=io_msInfo_3_bits_meta_accessed; ms_meta_tagErr[3]=io_msInfo_3_bits_meta_tagErr; ms_meta_dataErr[3]=io_msInfo_3_bits_meta_dataErr; ms_w_grantfirst[3]=io_msInfo_3_bits_w_grantfirst; ms_s_release[3]=io_msInfo_3_bits_s_release; ms_s_cmoresp[3]=io_msInfo_3_bits_s_cmoresp; ms_s_cmometaw[3]=io_msInfo_3_bits_s_cmometaw; ms_w_releaseack[3]=io_msInfo_3_bits_w_releaseack; ms_w_replResp[3]=io_msInfo_3_bits_w_replResp; ms_w_rprobeacklast[3]=io_msInfo_3_bits_w_rprobeacklast; ms_replaceData[3]=io_msInfo_3_bits_replaceData; ms_releaseToClean[3]=io_msInfo_3_bits_releaseToClean;
    ms_valid[4]=io_msInfo_4_valid; ms_set[4]=io_msInfo_4_bits_set; ms_reqTag[4]=io_msInfo_4_bits_reqTag; ms_metaTag[4]=io_msInfo_4_bits_metaTag; ms_willFree[4]=io_msInfo_4_bits_willFree; ms_aliasTask[4]=io_msInfo_4_bits_aliasTask; ms_blockRefill[4]=io_msInfo_4_bits_blockRefill; ms_dirHit[4]=io_msInfo_4_bits_dirHit; ms_meta_state[4]=io_msInfo_4_bits_meta_state; ms_meta_dirty[4]=io_msInfo_4_bits_meta_dirty; ms_meta_clients[4]=io_msInfo_4_bits_meta_clients; ms_meta_alias[4]=io_msInfo_4_bits_meta_alias; ms_meta_prefetch[4]=io_msInfo_4_bits_meta_prefetch; ms_meta_prefetchSrc[4]=io_msInfo_4_bits_meta_prefetchSrc; ms_meta_accessed[4]=io_msInfo_4_bits_meta_accessed; ms_meta_tagErr[4]=io_msInfo_4_bits_meta_tagErr; ms_meta_dataErr[4]=io_msInfo_4_bits_meta_dataErr; ms_w_grantfirst[4]=io_msInfo_4_bits_w_grantfirst; ms_s_release[4]=io_msInfo_4_bits_s_release; ms_s_cmoresp[4]=io_msInfo_4_bits_s_cmoresp; ms_s_cmometaw[4]=io_msInfo_4_bits_s_cmometaw; ms_w_releaseack[4]=io_msInfo_4_bits_w_releaseack; ms_w_replResp[4]=io_msInfo_4_bits_w_replResp; ms_w_rprobeacklast[4]=io_msInfo_4_bits_w_rprobeacklast; ms_replaceData[4]=io_msInfo_4_bits_replaceData; ms_releaseToClean[4]=io_msInfo_4_bits_releaseToClean;
    ms_valid[5]=io_msInfo_5_valid; ms_set[5]=io_msInfo_5_bits_set; ms_reqTag[5]=io_msInfo_5_bits_reqTag; ms_metaTag[5]=io_msInfo_5_bits_metaTag; ms_willFree[5]=io_msInfo_5_bits_willFree; ms_aliasTask[5]=io_msInfo_5_bits_aliasTask; ms_blockRefill[5]=io_msInfo_5_bits_blockRefill; ms_dirHit[5]=io_msInfo_5_bits_dirHit; ms_meta_state[5]=io_msInfo_5_bits_meta_state; ms_meta_dirty[5]=io_msInfo_5_bits_meta_dirty; ms_meta_clients[5]=io_msInfo_5_bits_meta_clients; ms_meta_alias[5]=io_msInfo_5_bits_meta_alias; ms_meta_prefetch[5]=io_msInfo_5_bits_meta_prefetch; ms_meta_prefetchSrc[5]=io_msInfo_5_bits_meta_prefetchSrc; ms_meta_accessed[5]=io_msInfo_5_bits_meta_accessed; ms_meta_tagErr[5]=io_msInfo_5_bits_meta_tagErr; ms_meta_dataErr[5]=io_msInfo_5_bits_meta_dataErr; ms_w_grantfirst[5]=io_msInfo_5_bits_w_grantfirst; ms_s_release[5]=io_msInfo_5_bits_s_release; ms_s_cmoresp[5]=io_msInfo_5_bits_s_cmoresp; ms_s_cmometaw[5]=io_msInfo_5_bits_s_cmometaw; ms_w_releaseack[5]=io_msInfo_5_bits_w_releaseack; ms_w_replResp[5]=io_msInfo_5_bits_w_replResp; ms_w_rprobeacklast[5]=io_msInfo_5_bits_w_rprobeacklast; ms_replaceData[5]=io_msInfo_5_bits_replaceData; ms_releaseToClean[5]=io_msInfo_5_bits_releaseToClean;
    ms_valid[6]=io_msInfo_6_valid; ms_set[6]=io_msInfo_6_bits_set; ms_reqTag[6]=io_msInfo_6_bits_reqTag; ms_metaTag[6]=io_msInfo_6_bits_metaTag; ms_willFree[6]=io_msInfo_6_bits_willFree; ms_aliasTask[6]=io_msInfo_6_bits_aliasTask; ms_blockRefill[6]=io_msInfo_6_bits_blockRefill; ms_dirHit[6]=io_msInfo_6_bits_dirHit; ms_meta_state[6]=io_msInfo_6_bits_meta_state; ms_meta_dirty[6]=io_msInfo_6_bits_meta_dirty; ms_meta_clients[6]=io_msInfo_6_bits_meta_clients; ms_meta_alias[6]=io_msInfo_6_bits_meta_alias; ms_meta_prefetch[6]=io_msInfo_6_bits_meta_prefetch; ms_meta_prefetchSrc[6]=io_msInfo_6_bits_meta_prefetchSrc; ms_meta_accessed[6]=io_msInfo_6_bits_meta_accessed; ms_meta_tagErr[6]=io_msInfo_6_bits_meta_tagErr; ms_meta_dataErr[6]=io_msInfo_6_bits_meta_dataErr; ms_w_grantfirst[6]=io_msInfo_6_bits_w_grantfirst; ms_s_release[6]=io_msInfo_6_bits_s_release; ms_s_cmoresp[6]=io_msInfo_6_bits_s_cmoresp; ms_s_cmometaw[6]=io_msInfo_6_bits_s_cmometaw; ms_w_releaseack[6]=io_msInfo_6_bits_w_releaseack; ms_w_replResp[6]=io_msInfo_6_bits_w_replResp; ms_w_rprobeacklast[6]=io_msInfo_6_bits_w_rprobeacklast; ms_replaceData[6]=io_msInfo_6_bits_replaceData; ms_releaseToClean[6]=io_msInfo_6_bits_releaseToClean;
    ms_valid[7]=io_msInfo_7_valid; ms_set[7]=io_msInfo_7_bits_set; ms_reqTag[7]=io_msInfo_7_bits_reqTag; ms_metaTag[7]=io_msInfo_7_bits_metaTag; ms_willFree[7]=io_msInfo_7_bits_willFree; ms_aliasTask[7]=io_msInfo_7_bits_aliasTask; ms_blockRefill[7]=io_msInfo_7_bits_blockRefill; ms_dirHit[7]=io_msInfo_7_bits_dirHit; ms_meta_state[7]=io_msInfo_7_bits_meta_state; ms_meta_dirty[7]=io_msInfo_7_bits_meta_dirty; ms_meta_clients[7]=io_msInfo_7_bits_meta_clients; ms_meta_alias[7]=io_msInfo_7_bits_meta_alias; ms_meta_prefetch[7]=io_msInfo_7_bits_meta_prefetch; ms_meta_prefetchSrc[7]=io_msInfo_7_bits_meta_prefetchSrc; ms_meta_accessed[7]=io_msInfo_7_bits_meta_accessed; ms_meta_tagErr[7]=io_msInfo_7_bits_meta_tagErr; ms_meta_dataErr[7]=io_msInfo_7_bits_meta_dataErr; ms_w_grantfirst[7]=io_msInfo_7_bits_w_grantfirst; ms_s_release[7]=io_msInfo_7_bits_s_release; ms_s_cmoresp[7]=io_msInfo_7_bits_s_cmoresp; ms_s_cmometaw[7]=io_msInfo_7_bits_s_cmometaw; ms_w_releaseack[7]=io_msInfo_7_bits_w_releaseack; ms_w_replResp[7]=io_msInfo_7_bits_w_replResp; ms_w_rprobeacklast[7]=io_msInfo_7_bits_w_rprobeacklast; ms_replaceData[7]=io_msInfo_7_bits_replaceData; ms_releaseToClean[7]=io_msInfo_7_bits_releaseToClean;
    ms_valid[8]=io_msInfo_8_valid; ms_set[8]=io_msInfo_8_bits_set; ms_reqTag[8]=io_msInfo_8_bits_reqTag; ms_metaTag[8]=io_msInfo_8_bits_metaTag; ms_willFree[8]=io_msInfo_8_bits_willFree; ms_aliasTask[8]=io_msInfo_8_bits_aliasTask; ms_blockRefill[8]=io_msInfo_8_bits_blockRefill; ms_dirHit[8]=io_msInfo_8_bits_dirHit; ms_meta_state[8]=io_msInfo_8_bits_meta_state; ms_meta_dirty[8]=io_msInfo_8_bits_meta_dirty; ms_meta_clients[8]=io_msInfo_8_bits_meta_clients; ms_meta_alias[8]=io_msInfo_8_bits_meta_alias; ms_meta_prefetch[8]=io_msInfo_8_bits_meta_prefetch; ms_meta_prefetchSrc[8]=io_msInfo_8_bits_meta_prefetchSrc; ms_meta_accessed[8]=io_msInfo_8_bits_meta_accessed; ms_meta_tagErr[8]=io_msInfo_8_bits_meta_tagErr; ms_meta_dataErr[8]=io_msInfo_8_bits_meta_dataErr; ms_w_grantfirst[8]=io_msInfo_8_bits_w_grantfirst; ms_s_release[8]=io_msInfo_8_bits_s_release; ms_s_cmoresp[8]=io_msInfo_8_bits_s_cmoresp; ms_s_cmometaw[8]=io_msInfo_8_bits_s_cmometaw; ms_w_releaseack[8]=io_msInfo_8_bits_w_releaseack; ms_w_replResp[8]=io_msInfo_8_bits_w_replResp; ms_w_rprobeacklast[8]=io_msInfo_8_bits_w_rprobeacklast; ms_replaceData[8]=io_msInfo_8_bits_replaceData; ms_releaseToClean[8]=io_msInfo_8_bits_releaseToClean;
    ms_valid[9]=io_msInfo_9_valid; ms_set[9]=io_msInfo_9_bits_set; ms_reqTag[9]=io_msInfo_9_bits_reqTag; ms_metaTag[9]=io_msInfo_9_bits_metaTag; ms_willFree[9]=io_msInfo_9_bits_willFree; ms_aliasTask[9]=io_msInfo_9_bits_aliasTask; ms_blockRefill[9]=io_msInfo_9_bits_blockRefill; ms_dirHit[9]=io_msInfo_9_bits_dirHit; ms_meta_state[9]=io_msInfo_9_bits_meta_state; ms_meta_dirty[9]=io_msInfo_9_bits_meta_dirty; ms_meta_clients[9]=io_msInfo_9_bits_meta_clients; ms_meta_alias[9]=io_msInfo_9_bits_meta_alias; ms_meta_prefetch[9]=io_msInfo_9_bits_meta_prefetch; ms_meta_prefetchSrc[9]=io_msInfo_9_bits_meta_prefetchSrc; ms_meta_accessed[9]=io_msInfo_9_bits_meta_accessed; ms_meta_tagErr[9]=io_msInfo_9_bits_meta_tagErr; ms_meta_dataErr[9]=io_msInfo_9_bits_meta_dataErr; ms_w_grantfirst[9]=io_msInfo_9_bits_w_grantfirst; ms_s_release[9]=io_msInfo_9_bits_s_release; ms_s_cmoresp[9]=io_msInfo_9_bits_s_cmoresp; ms_s_cmometaw[9]=io_msInfo_9_bits_s_cmometaw; ms_w_releaseack[9]=io_msInfo_9_bits_w_releaseack; ms_w_replResp[9]=io_msInfo_9_bits_w_replResp; ms_w_rprobeacklast[9]=io_msInfo_9_bits_w_rprobeacklast; ms_replaceData[9]=io_msInfo_9_bits_replaceData; ms_releaseToClean[9]=io_msInfo_9_bits_releaseToClean;
    ms_valid[10]=io_msInfo_10_valid; ms_set[10]=io_msInfo_10_bits_set; ms_reqTag[10]=io_msInfo_10_bits_reqTag; ms_metaTag[10]=io_msInfo_10_bits_metaTag; ms_willFree[10]=io_msInfo_10_bits_willFree; ms_aliasTask[10]=io_msInfo_10_bits_aliasTask; ms_blockRefill[10]=io_msInfo_10_bits_blockRefill; ms_dirHit[10]=io_msInfo_10_bits_dirHit; ms_meta_state[10]=io_msInfo_10_bits_meta_state; ms_meta_dirty[10]=io_msInfo_10_bits_meta_dirty; ms_meta_clients[10]=io_msInfo_10_bits_meta_clients; ms_meta_alias[10]=io_msInfo_10_bits_meta_alias; ms_meta_prefetch[10]=io_msInfo_10_bits_meta_prefetch; ms_meta_prefetchSrc[10]=io_msInfo_10_bits_meta_prefetchSrc; ms_meta_accessed[10]=io_msInfo_10_bits_meta_accessed; ms_meta_tagErr[10]=io_msInfo_10_bits_meta_tagErr; ms_meta_dataErr[10]=io_msInfo_10_bits_meta_dataErr; ms_w_grantfirst[10]=io_msInfo_10_bits_w_grantfirst; ms_s_release[10]=io_msInfo_10_bits_s_release; ms_s_cmoresp[10]=io_msInfo_10_bits_s_cmoresp; ms_s_cmometaw[10]=io_msInfo_10_bits_s_cmometaw; ms_w_releaseack[10]=io_msInfo_10_bits_w_releaseack; ms_w_replResp[10]=io_msInfo_10_bits_w_replResp; ms_w_rprobeacklast[10]=io_msInfo_10_bits_w_rprobeacklast; ms_replaceData[10]=io_msInfo_10_bits_replaceData; ms_releaseToClean[10]=io_msInfo_10_bits_releaseToClean;
    ms_valid[11]=io_msInfo_11_valid; ms_set[11]=io_msInfo_11_bits_set; ms_reqTag[11]=io_msInfo_11_bits_reqTag; ms_metaTag[11]=io_msInfo_11_bits_metaTag; ms_willFree[11]=io_msInfo_11_bits_willFree; ms_aliasTask[11]=io_msInfo_11_bits_aliasTask; ms_blockRefill[11]=io_msInfo_11_bits_blockRefill; ms_dirHit[11]=io_msInfo_11_bits_dirHit; ms_meta_state[11]=io_msInfo_11_bits_meta_state; ms_meta_dirty[11]=io_msInfo_11_bits_meta_dirty; ms_meta_clients[11]=io_msInfo_11_bits_meta_clients; ms_meta_alias[11]=io_msInfo_11_bits_meta_alias; ms_meta_prefetch[11]=io_msInfo_11_bits_meta_prefetch; ms_meta_prefetchSrc[11]=io_msInfo_11_bits_meta_prefetchSrc; ms_meta_accessed[11]=io_msInfo_11_bits_meta_accessed; ms_meta_tagErr[11]=io_msInfo_11_bits_meta_tagErr; ms_meta_dataErr[11]=io_msInfo_11_bits_meta_dataErr; ms_w_grantfirst[11]=io_msInfo_11_bits_w_grantfirst; ms_s_release[11]=io_msInfo_11_bits_s_release; ms_s_cmoresp[11]=io_msInfo_11_bits_s_cmoresp; ms_s_cmometaw[11]=io_msInfo_11_bits_s_cmometaw; ms_w_releaseack[11]=io_msInfo_11_bits_w_releaseack; ms_w_replResp[11]=io_msInfo_11_bits_w_replResp; ms_w_rprobeacklast[11]=io_msInfo_11_bits_w_rprobeacklast; ms_replaceData[11]=io_msInfo_11_bits_replaceData; ms_releaseToClean[11]=io_msInfo_11_bits_releaseToClean;
    ms_valid[12]=io_msInfo_12_valid; ms_set[12]=io_msInfo_12_bits_set; ms_reqTag[12]=io_msInfo_12_bits_reqTag; ms_metaTag[12]=io_msInfo_12_bits_metaTag; ms_willFree[12]=io_msInfo_12_bits_willFree; ms_aliasTask[12]=io_msInfo_12_bits_aliasTask; ms_blockRefill[12]=io_msInfo_12_bits_blockRefill; ms_dirHit[12]=io_msInfo_12_bits_dirHit; ms_meta_state[12]=io_msInfo_12_bits_meta_state; ms_meta_dirty[12]=io_msInfo_12_bits_meta_dirty; ms_meta_clients[12]=io_msInfo_12_bits_meta_clients; ms_meta_alias[12]=io_msInfo_12_bits_meta_alias; ms_meta_prefetch[12]=io_msInfo_12_bits_meta_prefetch; ms_meta_prefetchSrc[12]=io_msInfo_12_bits_meta_prefetchSrc; ms_meta_accessed[12]=io_msInfo_12_bits_meta_accessed; ms_meta_tagErr[12]=io_msInfo_12_bits_meta_tagErr; ms_meta_dataErr[12]=io_msInfo_12_bits_meta_dataErr; ms_w_grantfirst[12]=io_msInfo_12_bits_w_grantfirst; ms_s_release[12]=io_msInfo_12_bits_s_release; ms_s_cmoresp[12]=io_msInfo_12_bits_s_cmoresp; ms_s_cmometaw[12]=io_msInfo_12_bits_s_cmometaw; ms_w_releaseack[12]=io_msInfo_12_bits_w_releaseack; ms_w_replResp[12]=io_msInfo_12_bits_w_replResp; ms_w_rprobeacklast[12]=io_msInfo_12_bits_w_rprobeacklast; ms_replaceData[12]=io_msInfo_12_bits_replaceData; ms_releaseToClean[12]=io_msInfo_12_bits_releaseToClean;
    ms_valid[13]=io_msInfo_13_valid; ms_set[13]=io_msInfo_13_bits_set; ms_reqTag[13]=io_msInfo_13_bits_reqTag; ms_metaTag[13]=io_msInfo_13_bits_metaTag; ms_willFree[13]=io_msInfo_13_bits_willFree; ms_aliasTask[13]=io_msInfo_13_bits_aliasTask; ms_blockRefill[13]=io_msInfo_13_bits_blockRefill; ms_dirHit[13]=io_msInfo_13_bits_dirHit; ms_meta_state[13]=io_msInfo_13_bits_meta_state; ms_meta_dirty[13]=io_msInfo_13_bits_meta_dirty; ms_meta_clients[13]=io_msInfo_13_bits_meta_clients; ms_meta_alias[13]=io_msInfo_13_bits_meta_alias; ms_meta_prefetch[13]=io_msInfo_13_bits_meta_prefetch; ms_meta_prefetchSrc[13]=io_msInfo_13_bits_meta_prefetchSrc; ms_meta_accessed[13]=io_msInfo_13_bits_meta_accessed; ms_meta_tagErr[13]=io_msInfo_13_bits_meta_tagErr; ms_meta_dataErr[13]=io_msInfo_13_bits_meta_dataErr; ms_w_grantfirst[13]=io_msInfo_13_bits_w_grantfirst; ms_s_release[13]=io_msInfo_13_bits_s_release; ms_s_cmoresp[13]=io_msInfo_13_bits_s_cmoresp; ms_s_cmometaw[13]=io_msInfo_13_bits_s_cmometaw; ms_w_releaseack[13]=io_msInfo_13_bits_w_releaseack; ms_w_replResp[13]=io_msInfo_13_bits_w_replResp; ms_w_rprobeacklast[13]=io_msInfo_13_bits_w_rprobeacklast; ms_replaceData[13]=io_msInfo_13_bits_replaceData; ms_releaseToClean[13]=io_msInfo_13_bits_releaseToClean;
    ms_valid[14]=io_msInfo_14_valid; ms_set[14]=io_msInfo_14_bits_set; ms_reqTag[14]=io_msInfo_14_bits_reqTag; ms_metaTag[14]=io_msInfo_14_bits_metaTag; ms_willFree[14]=io_msInfo_14_bits_willFree; ms_aliasTask[14]=io_msInfo_14_bits_aliasTask; ms_blockRefill[14]=io_msInfo_14_bits_blockRefill; ms_dirHit[14]=io_msInfo_14_bits_dirHit; ms_meta_state[14]=io_msInfo_14_bits_meta_state; ms_meta_dirty[14]=io_msInfo_14_bits_meta_dirty; ms_meta_clients[14]=io_msInfo_14_bits_meta_clients; ms_meta_alias[14]=io_msInfo_14_bits_meta_alias; ms_meta_prefetch[14]=io_msInfo_14_bits_meta_prefetch; ms_meta_prefetchSrc[14]=io_msInfo_14_bits_meta_prefetchSrc; ms_meta_accessed[14]=io_msInfo_14_bits_meta_accessed; ms_meta_tagErr[14]=io_msInfo_14_bits_meta_tagErr; ms_meta_dataErr[14]=io_msInfo_14_bits_meta_dataErr; ms_w_grantfirst[14]=io_msInfo_14_bits_w_grantfirst; ms_s_release[14]=io_msInfo_14_bits_s_release; ms_s_cmoresp[14]=io_msInfo_14_bits_s_cmoresp; ms_s_cmometaw[14]=io_msInfo_14_bits_s_cmometaw; ms_w_releaseack[14]=io_msInfo_14_bits_w_releaseack; ms_w_replResp[14]=io_msInfo_14_bits_w_replResp; ms_w_rprobeacklast[14]=io_msInfo_14_bits_w_rprobeacklast; ms_replaceData[14]=io_msInfo_14_bits_replaceData; ms_releaseToClean[14]=io_msInfo_14_bits_releaseToClean;
    ms_valid[15]=io_msInfo_15_valid; ms_set[15]=io_msInfo_15_bits_set; ms_reqTag[15]=io_msInfo_15_bits_reqTag; ms_metaTag[15]=io_msInfo_15_bits_metaTag; ms_willFree[15]=io_msInfo_15_bits_willFree; ms_aliasTask[15]=io_msInfo_15_bits_aliasTask; ms_blockRefill[15]=io_msInfo_15_bits_blockRefill; ms_dirHit[15]=io_msInfo_15_bits_dirHit; ms_meta_state[15]=io_msInfo_15_bits_meta_state; ms_meta_dirty[15]=io_msInfo_15_bits_meta_dirty; ms_meta_clients[15]=io_msInfo_15_bits_meta_clients; ms_meta_alias[15]=io_msInfo_15_bits_meta_alias; ms_meta_prefetch[15]=io_msInfo_15_bits_meta_prefetch; ms_meta_prefetchSrc[15]=io_msInfo_15_bits_meta_prefetchSrc; ms_meta_accessed[15]=io_msInfo_15_bits_meta_accessed; ms_meta_tagErr[15]=io_msInfo_15_bits_meta_tagErr; ms_meta_dataErr[15]=io_msInfo_15_bits_meta_dataErr; ms_w_grantfirst[15]=io_msInfo_15_bits_w_grantfirst; ms_s_release[15]=io_msInfo_15_bits_s_release; ms_s_cmoresp[15]=io_msInfo_15_bits_s_cmoresp; ms_s_cmometaw[15]=io_msInfo_15_bits_s_cmometaw; ms_w_releaseack[15]=io_msInfo_15_bits_w_releaseack; ms_w_replResp[15]=io_msInfo_15_bits_w_replResp; ms_w_rprobeacklast[15]=io_msInfo_15_bits_w_rprobeacklast; ms_replaceData[15]=io_msInfo_15_bits_replaceData; ms_releaseToClean[15]=io_msInfo_15_bits_releaseToClean;
  end

  // -------------------------------------------------------------------------
  // 2) 2 深 CHI-SNP 缓冲(golden Queue2_CHISNP 白盒)
  // -------------------------------------------------------------------------
  wire        deq_valid;
  wire [11:0] deq_txnID;
  wire [4:0]  deq_opcode;
  wire [44:0] deq_addr;
  wire        rxsnp_ready;   // deq.ready = task.ready & ~stall

  Queue2_CHISNP queue (
    .clock                         (clock),
    .reset                         (reset),
    .io_enq_ready                  (io_rxsnp_ready),
    .io_enq_valid                  (io_rxsnp_valid),
    .io_enq_bits_qos               (io_rxsnp_bits_qos),
    .io_enq_bits_srcID             (io_rxsnp_bits_srcID),
    .io_enq_bits_txnID             (io_rxsnp_bits_txnID),
    .io_enq_bits_fwdNID            (io_rxsnp_bits_fwdNID),
    .io_enq_bits_fwdTxnID          (io_rxsnp_bits_fwdTxnID),
    .io_enq_bits_opcode            (io_rxsnp_bits_opcode),
    .io_enq_bits_addr              (io_rxsnp_bits_addr),
    .io_enq_bits_ns                (io_rxsnp_bits_ns),
    .io_enq_bits_doNotGoToSD       (io_rxsnp_bits_doNotGoToSD),
    .io_enq_bits_retToSrc          (io_rxsnp_bits_retToSrc),
    .io_enq_bits_traceTag          (io_rxsnp_bits_traceTag),
    .io_enq_bits_mpam_perfMonGroup (io_rxsnp_bits_mpam_perfMonGroup),
    .io_enq_bits_mpam_partID       (io_rxsnp_bits_mpam_partID),
    .io_enq_bits_mpam_mpamNS       (io_rxsnp_bits_mpam_mpamNS),
    .io_deq_ready                  (rxsnp_ready),
    .io_deq_valid                  (deq_valid),
    .io_deq_bits_srcID             (io_task_bits_srcID),
    .io_deq_bits_txnID             (deq_txnID),
    .io_deq_bits_fwdNID            (io_task_bits_fwdNID),
    .io_deq_bits_fwdTxnID          (io_task_bits_fwdTxnID),
    .io_deq_bits_opcode            (deq_opcode),
    .io_deq_bits_addr              (deq_addr),
    .io_deq_bits_retToSrc          (io_task_bits_retToSrc),
    .io_deq_bits_traceTag          (io_task_bits_traceTag)
  );

  // -------------------------------------------------------------------------
  // 3) 地址→task 拆分。CHI SNP addr 比全地址少 3 位, 需补 {addr,3'h0} 再拆。
  //      tag = fullAddr[47:17] = addr[44:14]
  //      set = fullAddr[16: 8] = addr[13:5]
  //      off = fullAddr[ 7: 0] 的低 6 位 = {addr[2:0],3'h0}
  // -------------------------------------------------------------------------
  wire [30:0] task_tag = deq_addr[44:14];
  wire [8:0]  task_set = deq_addr[13:5];
  wire [5:0]  task_off = {deq_addr[2:0], 3'h0};

  // -------------------------------------------------------------------------
  // 4) 32 个 RegNext(w_replResp) 延迟寄存器(单份, 靠 merge-dup 与 golden 两份配对)。
  // -------------------------------------------------------------------------
  reg [MSHRS-1:0] replResp_d;
  always @(posedge clock) begin
    for (int k = 0; k < MSHRS; k++)
      replResp_d[k] <= ms_w_replResp[k];
  end

  // -------------------------------------------------------------------------
  // 5) 16 路组合匹配(genvar, 显式 assign)。
  // -------------------------------------------------------------------------
  wire        set_hit     [MSHRS];
  wire        reqTag_hit  [MSHRS];
  wire        metaTag_hit [MSHRS];
  wire [15:0] reqBlockSnpMask;
  wire [15:0] replaceBlockSnpMask;
  wire [15:0] cmoBlockSnpMask;
  wire [15:0] replaceNestSnpMask;

  genvar gi;
  generate
    for (gi = 0; gi < MSHRS; gi = gi + 1) begin : g_mask
      assign set_hit[gi]     = (ms_set[gi]     == task_set);
      assign reqTag_hit[gi]  = (ms_reqTag[gi]  == task_tag);
      assign metaTag_hit[gi] = (ms_metaTag[gi] == task_tag);

      // reqBlockSnp: 命中在飞请求 reqTag, 需阻塞 snoop (见 Scala [2][3][5][6])
      assign reqBlockSnpMask[gi] =
        ms_valid[gi] & set_hit[gi] & reqTag_hit[gi]
        & ( ms_w_grantfirst[gi]
          | (ms_aliasTask[gi] & ~ms_w_rprobeacklast[gi])
          | (~ms_s_cmoresp[gi] & (~ms_w_rprobeacklast[gi] | ~ms_s_cmometaw[gi])) )
        & (ms_blockRefill[gi] | ms_w_releaseack[gi])
        & ~ms_willFree[gi];

      // cmoBlockSnp: 命中 metaTag 且脏命中的 CMO/release 未完, 需阻塞
      assign cmoBlockSnpMask[gi] =
        ms_valid[gi] & set_hit[gi] & metaTag_hit[gi]
        & ms_dirHit[gi] & (|ms_meta_state[gi])
        & ~ms_s_cmoresp[gi]
        & (~ms_s_release[gi] | ~ms_w_rprobeacklast[gi])
        & ~ms_willFree[gi];

      // replaceBlockSnp: 命中 metaTag 的替换流, rProbe 未完成时阻塞
      assign replaceBlockSnpMask[gi] =
        ms_valid[gi] & set_hit[gi] & metaTag_hit[gi]
        & ~ms_dirHit[gi] & (|ms_meta_state[gi])
        & ms_s_cmoresp[gi] & ms_w_replResp[gi]
        & (~ms_w_rprobeacklast[gi] | ms_w_releaseack[gi] | ~replResp_d[gi])
        & ~ms_willFree[gi];

      // replaceNestSnp: 命中 metaTag 的替换流, rProbe 已完成→嵌套 snoop
      assign replaceNestSnpMask[gi] =
        ms_valid[gi] & set_hit[gi] & metaTag_hit[gi]
        & (~ms_dirHit[gi] | ~ms_s_cmoresp[gi]) & (|ms_meta_state[gi])
        & replResp_d[gi] & ms_w_rprobeacklast[gi] & ~ms_w_releaseack[gi];
    end
  endgenerate

  wire stall = (|reqBlockSnpMask) | (|replaceBlockSnpMask) | (|cmoBlockSnpMask);
  assign rxsnp_ready = io_task_ready & ~stall;

  // -------------------------------------------------------------------------
  // 6) snpHitRelease* 输出: 命中的嵌套条目(唯一)之 meta / release 属性。
  //    PopCount(replaceNestSnpMask)<=1(golden 断言保证), 用 OR-归约选中条目。
  // -------------------------------------------------------------------------
  wire [15:0] releaseToInvalMask;
  wire [15:0] releaseToCleanMask;
  wire [15:0] replaceDataMask;
  generate
    for (gi = 0; gi < MSHRS; gi = gi + 1) begin : g_sel
      assign releaseToInvalMask[gi] = replaceNestSnpMask[gi] & ~ms_releaseToClean[gi];
      assign releaseToCleanMask[gi] = replaceNestSnpMask[gi] &  ms_releaseToClean[gi];
      assign replaceDataMask[gi]    = replaceNestSnpMask[gi] &  ms_replaceData[gi];
    end
  endgenerate

  // 选中条目的 meta (OR-归约, 未命中项贡献 0)
  logic        snpMeta_dirty;
  logic [1:0]  snpMeta_state;
  logic        snpMeta_clients;
  logic [1:0]  snpMeta_alias;
  logic        snpMeta_prefetch;
  logic [2:0]  snpMeta_prefetchSrc;
  logic        snpMeta_accessed;
  logic        snpMeta_tagErr;
  logic        snpMeta_dataErr;
  always_comb begin
    snpMeta_dirty       = 1'b0;
    snpMeta_state       = 2'h0;
    snpMeta_clients     = 1'b0;
    snpMeta_alias       = 2'h0;
    snpMeta_prefetch    = 1'b0;
    snpMeta_prefetchSrc = 3'h0;
    snpMeta_accessed    = 1'b0;
    snpMeta_tagErr      = 1'b0;
    snpMeta_dataErr     = 1'b0;
    for (int k = 0; k < MSHRS; k++) begin
      if (replaceNestSnpMask[k]) begin
        snpMeta_dirty       |= ms_meta_dirty[k];
        snpMeta_state       |= ms_meta_state[k];
        snpMeta_clients     |= ms_meta_clients[k];
        snpMeta_alias       |= ms_meta_alias[k];
        snpMeta_prefetch    |= ms_meta_prefetch[k];
        snpMeta_prefetchSrc |= ms_meta_prefetchSrc[k];
        snpMeta_accessed    |= ms_meta_accessed[k];
        snpMeta_tagErr      |= ms_meta_tagErr[k];
        snpMeta_dataErr     |= ms_meta_dataErr[k];
      end
    end
  end

  // snpHitReleaseIdx = PriorityEncoder(replaceNestSnpMask) (低位优先), 8bit {4'h0,4bit}
  logic [3:0] nest_idx;
  always_comb begin
    nest_idx = 4'hF;                       // 默认(全 0 时): golden 15
    for (int k = MSHRS-1; k >= 0; k--)
      if (replaceNestSnpMask[k]) nest_idx = k[3:0];
  end

  // -------------------------------------------------------------------------
  // 7) stallCnt: 仅在死锁断言里被读; SYNTHESIS 下 cone-dead。忠实保留 async-reset。
  // -------------------------------------------------------------------------
  wire rxsnp_fire = rxsnp_ready & deq_valid;
  reg [63:0] stallCnt;
  always @(posedge clock or posedge reset) begin
    if (reset)
      stallCnt <= 64'h0;
    else if (rxsnp_fire)
      stallCnt <= 64'h0;
    else if (deq_valid & ~rxsnp_ready)
      stallCnt <= stallCnt + 64'h1;
  end
`ifndef SYNTHESIS
  // 死锁监视断言(与 golden RXSNP.scala:129 一致); SYNTHESIS 下不生成, stallCnt 变死寄存器。
  localparam [63:0] STALL_CNT_MAX = 64'h6D60; // 28000
  always @(posedge clock) begin
    if (!reset && stallCnt > STALL_CNT_MAX)
      $fwrite(32'h80000002, "Assertion failed: stallCnt full!\n");
  end
`endif

  // -------------------------------------------------------------------------
  // 8) 输出组装
  // -------------------------------------------------------------------------
  assign io_task_valid                        = deq_valid & ~stall;
  assign io_task_bits_set                     = task_set;
  assign io_task_bits_tag                     = task_tag;
  assign io_task_bits_off                     = task_off;
  assign io_task_bits_txnID                   = deq_txnID;
  assign io_task_bits_chiOpcode               = {2'h0, deq_opcode};

  assign io_task_bits_snpHitRelease           = |replaceNestSnpMask;
  assign io_task_bits_snpHitReleaseToInval    = |releaseToInvalMask;
  assign io_task_bits_snpHitReleaseToClean    = |releaseToCleanMask;
  assign io_task_bits_snpHitReleaseWithData   = |replaceDataMask;
  assign io_task_bits_snpHitReleaseIdx        = {4'h0, nest_idx};

  assign io_task_bits_snpHitReleaseMeta_dirty       = snpMeta_dirty;
  assign io_task_bits_snpHitReleaseMeta_state       = snpMeta_state;
  assign io_task_bits_snpHitReleaseMeta_clients     = snpMeta_clients;
  assign io_task_bits_snpHitReleaseMeta_alias       = snpMeta_alias;
  assign io_task_bits_snpHitReleaseMeta_prefetch    = snpMeta_prefetch;
  assign io_task_bits_snpHitReleaseMeta_prefetchSrc = snpMeta_prefetchSrc;
  assign io_task_bits_snpHitReleaseMeta_accessed    = snpMeta_accessed;
  assign io_task_bits_snpHitReleaseMeta_tagErr      = snpMeta_tagErr;
  assign io_task_bits_snpHitReleaseMeta_dataErr     = snpMeta_dataErr;

endmodule
