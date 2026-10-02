// =============================================================================
// Slice.sv —— CoupledL2（tl2chi）的一个 L2 slice：上接 L1 的 TileLink A/B/C/D/E，下接 CHI 的
//             TXREQ/TXRSP/TXDAT 与 RXSNP/RXRSP/RXDAT，按地址交织的 4 个 slice 之一（本文件 = slice 0）
//
// 对照 Scala：coupledL2/src/main/scala/coupledL2/tl2chi/Slice.scala（约 230 行，几乎全是 child 互连）。
//
// 数据流（一条 A 通道 miss 的一生）：
//   SinkA -> RequestBuffer -> RequestArb(s0-s2, 读目录) -> MainPipe(s2-s5, 拿目录结果决策)
//     · 命中：MainPipe 读数据阵列，经 GrantBuffer 从 D 通道回 Grant，等 E 通道 GrantAck；
//     · 缺失：MainPipe s3 分配 MSHR -> MSHRCtl 经 TXREQ 发 ReadXXX -> RXDAT 收 CompData（数据进
//       refillBuf）-> MSHR 发 CompAck(TXRSP) 并把 refill 任务交回 RequestArb -> MainPipe 写目录 /
//       数据阵列、经 GrantBuffer 回 Grant。被替换的脏行由 MainPipe 读出写进 releaseBuf，经 TXDAT 写回。
//   下层 snoop：RXSNP -> RequestArb（B 通道 task）-> MainPipe 直接回 SnpResp(TXRSP/TXDAT)，或分配
//     MSHR 先向上层发 Probe（SourceB，在 MSHRCtl 里），上层 ProbeAck 从 SinkC 回来。
//   上层 Release：SinkC -> RequestArb -> MainPipe 写目录 / 数据阵列（数据经 releaseBuf）。
//
// 本层自己的"真逻辑"很少（§1-§4，手写）：releaseBuf 读响应打一拍、错误报告打一拍、TopDown /
// 预取统计输出、性能事件打两拍。其余是 15 个 child 的互连，由
// scripts/gen_l2_slice.py 从 golden 端口表机械生成（GENERATED 区，勿手改）。
//
// ★四个变体（Slice / Slice_1..3）怎么共用一个核★：golden 的四份只差三处 —— 给 TXREQ 的 sliceId 常量、
// 目录 / 数据阵列 / MBIST 分发三个 child 的单态化版本（Directory_N 等，只差 MBIST 编号与 SRAM 宏实例）、
// MBIST bore 数组位宽。所以核只带参数 SLICE_ID；目录、数据阵列与 MBIST 分发放在各变体的 wrapper 里
// （本文件末尾的 Slice，以及生成的 Slice_1/2/3.sv），核与它们之间走 dir_* / ds_* 接口。
//
// ★忠实 golden 的几处（照抄，勿"优化"）★
//   · RequestArb 的 sinkB（snoop task）大多数字段、mshrTask 的少数字段是常量：源头恒常量，firtool
//     删了端口、常量留在 Slice 这一层（GENERATED(children) 里照 golden 原样连常量）。
//   · 性能事件只有 16 个（编号 0,1,3..16）：MSHRCtl 的 l2_cache_wr_refill（第 2 个）恒 0，端口被删。
//   · io_dirResult.valid 排除"MSHR 发起的 Grant 读目录"（那一拍 replResp 也有效）。
//   · 打拍寄存器保留 golden 名字（mainPipe_io_releaseBufResp_s3_valid_REG / io_perf_*_value_REG*）。
//
// BEGIN GENERATED(nav) —— scripts/gen_l2_slice.py 生成
// 本文件导航：
//   L1091 BEGIN GENERATED(core_wires)
//   L2609 §1 releaseBuf 读响应打一拍（Slice.scala: releaseBufResp_s3.valid := RegNext(r
//   L2620 §2 错误报告打一拍（io.error := RegNext(mainPipe.io.error)；valid 带复位，bits 不复位）
//   L2638 §3 TopDown / 预取统计输出（组合）
//   L2651 §4 性能事件（generatePerfEvent：每个事件打两拍再输出）
//   L2706 §5 child 互连（连线生成）
//   L2708 BEGIN GENERATED(to_dir_ds)
//   L3290 BEGIN GENERATED(children)
//   L7680 BEGIN GENERATED(wrapper)
//   L8194 §W1 核 <-> 目录（dir_*）/ 数据阵列（ds_*）的接口线
//   L8806 §W2 MBIST 分发线：mbistPl 的两路下行（路 0 -> 目录，路 1 -> 数据阵列）
//   L8830 §W3 可读核（本变体 SLICE_ID = 0）：除目录 / 数据阵列 / MBIST 分发外的全部 child 与本层逻辑
//   L9866 §W4 目录（tag / meta / 替换状态），本变体 = Directory
//   L10540 §W5 数据阵列，本变体 = DataStorage
//   L10593 §W6 MBIST 分发（L2Slice）：顶层 bore -> 目录（路 0）/ 数据阵列（路 1）
// END GENERATED(nav)
// =============================================================================
module xs_Slice_core #(
  parameter logic [1:0] SLICE_ID = 2'd0    // 本 slice 编号，只给 TXREQ（填进 CHI 请求的地址交织位）
) (
  // BEGIN GENERATED(core_ports) —— scripts/gen_l2_slice.py 从 golden 端口表生成，勿手改
  input  logic           clock,
  input  logic           reset,
  output logic           io_in_a_ready,
  input  logic           io_in_a_valid,
  input  logic [3:0]     io_in_a_bits_opcode,
  input  logic [2:0]     io_in_a_bits_param,
  input  logic [2:0]     io_in_a_bits_size,
  input  logic [6:0]     io_in_a_bits_source,
  input  logic [47:0]    io_in_a_bits_address,
  input  logic [4:0]     io_in_a_bits_user_reqSource,
  input  logic [1:0]     io_in_a_bits_user_alias,
  input  logic [43:0]    io_in_a_bits_user_vaddr,
  input  logic           io_in_a_bits_user_needHint,
  input  logic           io_in_a_bits_echo_isKeyword,
  input  logic           io_in_a_bits_corrupt,
  input  logic           io_in_b_ready,
  output logic           io_in_b_valid,
  output logic [2:0]     io_in_b_bits_opcode,
  output logic [1:0]     io_in_b_bits_param,
  output logic [47:0]    io_in_b_bits_address,
  output logic [255:0]   io_in_b_bits_data,
  output logic           io_in_c_ready,
  input  logic           io_in_c_valid,
  input  logic [2:0]     io_in_c_bits_opcode,
  input  logic [2:0]     io_in_c_bits_param,
  input  logic [2:0]     io_in_c_bits_size,
  input  logic [6:0]     io_in_c_bits_source,
  input  logic [47:0]    io_in_c_bits_address,
  input  logic [255:0]   io_in_c_bits_data,
  input  logic           io_in_c_bits_corrupt,
  input  logic           io_in_d_ready,
  output logic           io_in_d_valid,
  output logic [3:0]     io_in_d_bits_opcode,
  output logic [1:0]     io_in_d_bits_param,
  output logic [6:0]     io_in_d_bits_source,
  output logic [7:0]     io_in_d_bits_sink,
  output logic           io_in_d_bits_denied,
  output logic           io_in_d_bits_echo_isKeyword,
  output logic [255:0]   io_in_d_bits_data,
  output logic           io_in_d_bits_corrupt,
  input  logic           io_in_e_valid,
  input  logic [7:0]     io_in_e_bits_sink,
  input  logic           io_l1Hint_ready,
  output logic           io_l1Hint_valid,
  output logic [31:0]    io_l1Hint_bits_sourceId,
  output logic           io_l1Hint_bits_isKeyword,
  input  logic           io_prefetch_train_ready,
  output logic           io_prefetch_train_valid,
  output logic [32:0]    io_prefetch_train_bits_tag,
  output logic [8:0]     io_prefetch_train_bits_set,
  output logic           io_prefetch_train_bits_needT,
  output logic [6:0]     io_prefetch_train_bits_source,
  output logic [43:0]    io_prefetch_train_bits_vaddr,
  output logic           io_prefetch_train_bits_hit,
  output logic           io_prefetch_train_bits_prefetched,
  output logic [2:0]     io_prefetch_train_bits_pfsource,
  output logic [4:0]     io_prefetch_train_bits_reqsource,
  output logic           io_prefetch_req_ready,
  input  logic           io_prefetch_req_valid,
  input  logic [32:0]    io_prefetch_req_bits_tag,
  input  logic [8:0]     io_prefetch_req_bits_set,
  input  logic [43:0]    io_prefetch_req_bits_vaddr,
  input  logic           io_prefetch_req_bits_needT,
  input  logic [6:0]     io_prefetch_req_bits_source,
  input  logic [4:0]     io_prefetch_req_bits_pfSource,
  input  logic           io_prefetch_resp_ready,
  output logic           io_prefetch_resp_valid,
  output logic [32:0]    io_prefetch_resp_bits_tag,
  output logic [8:0]     io_prefetch_resp_bits_set,
  output logic [43:0]    io_prefetch_resp_bits_vaddr,
  output logic [4:0]     io_prefetch_resp_bits_pfSource,
  output logic           io_dirResult_valid,
  output logic           io_dirResult_bits_hit,
  output logic           io_dirResult_bits_meta_prefetch,
  output logic [2:0]     io_dirResult_bits_meta_prefetchSrc,
  output logic           io_hitPfInMSHR_valid,
  output logic [2:0]     io_hitPfInMSHR_bits,
  output logic           io_pfSent_valid,
  output logic [4:0]     io_pfSent_bits,
  output logic           io_pfLateInMSHR_valid,
  output logic [4:0]     io_pfLateInMSHR_bits,
  output logic           io_error_valid,
  output logic           io_error_bits_valid,
  output logic [45:0]    io_error_bits_address,
  output logic           io_l2Miss,
  output logic           io_msStatus_0_valid,
  output logic [2:0]     io_msStatus_0_bits_channel,
  output logic [8:0]     io_msStatus_0_bits_set,
  output logic [30:0]    io_msStatus_0_bits_reqTag,
  output logic           io_msStatus_0_bits_is_miss,
  output logic           io_msStatus_0_bits_is_prefetch,
  output logic           io_msStatus_1_valid,
  output logic [2:0]     io_msStatus_1_bits_channel,
  output logic [8:0]     io_msStatus_1_bits_set,
  output logic [30:0]    io_msStatus_1_bits_reqTag,
  output logic           io_msStatus_1_bits_is_miss,
  output logic           io_msStatus_1_bits_is_prefetch,
  output logic           io_msStatus_2_valid,
  output logic [2:0]     io_msStatus_2_bits_channel,
  output logic [8:0]     io_msStatus_2_bits_set,
  output logic [30:0]    io_msStatus_2_bits_reqTag,
  output logic           io_msStatus_2_bits_is_miss,
  output logic           io_msStatus_2_bits_is_prefetch,
  output logic           io_msStatus_3_valid,
  output logic [2:0]     io_msStatus_3_bits_channel,
  output logic [8:0]     io_msStatus_3_bits_set,
  output logic [30:0]    io_msStatus_3_bits_reqTag,
  output logic           io_msStatus_3_bits_is_miss,
  output logic           io_msStatus_3_bits_is_prefetch,
  output logic           io_msStatus_4_valid,
  output logic [2:0]     io_msStatus_4_bits_channel,
  output logic [8:0]     io_msStatus_4_bits_set,
  output logic [30:0]    io_msStatus_4_bits_reqTag,
  output logic           io_msStatus_4_bits_is_miss,
  output logic           io_msStatus_4_bits_is_prefetch,
  output logic           io_msStatus_5_valid,
  output logic [2:0]     io_msStatus_5_bits_channel,
  output logic [8:0]     io_msStatus_5_bits_set,
  output logic [30:0]    io_msStatus_5_bits_reqTag,
  output logic           io_msStatus_5_bits_is_miss,
  output logic           io_msStatus_5_bits_is_prefetch,
  output logic           io_msStatus_6_valid,
  output logic [2:0]     io_msStatus_6_bits_channel,
  output logic [8:0]     io_msStatus_6_bits_set,
  output logic [30:0]    io_msStatus_6_bits_reqTag,
  output logic           io_msStatus_6_bits_is_miss,
  output logic           io_msStatus_6_bits_is_prefetch,
  output logic           io_msStatus_7_valid,
  output logic [2:0]     io_msStatus_7_bits_channel,
  output logic [8:0]     io_msStatus_7_bits_set,
  output logic [30:0]    io_msStatus_7_bits_reqTag,
  output logic           io_msStatus_7_bits_is_miss,
  output logic           io_msStatus_7_bits_is_prefetch,
  output logic           io_msStatus_8_valid,
  output logic [2:0]     io_msStatus_8_bits_channel,
  output logic [8:0]     io_msStatus_8_bits_set,
  output logic [30:0]    io_msStatus_8_bits_reqTag,
  output logic           io_msStatus_8_bits_is_miss,
  output logic           io_msStatus_8_bits_is_prefetch,
  output logic           io_msStatus_9_valid,
  output logic [2:0]     io_msStatus_9_bits_channel,
  output logic [8:0]     io_msStatus_9_bits_set,
  output logic [30:0]    io_msStatus_9_bits_reqTag,
  output logic           io_msStatus_9_bits_is_miss,
  output logic           io_msStatus_9_bits_is_prefetch,
  output logic           io_msStatus_10_valid,
  output logic [2:0]     io_msStatus_10_bits_channel,
  output logic [8:0]     io_msStatus_10_bits_set,
  output logic [30:0]    io_msStatus_10_bits_reqTag,
  output logic           io_msStatus_10_bits_is_miss,
  output logic           io_msStatus_10_bits_is_prefetch,
  output logic           io_msStatus_11_valid,
  output logic [2:0]     io_msStatus_11_bits_channel,
  output logic [8:0]     io_msStatus_11_bits_set,
  output logic [30:0]    io_msStatus_11_bits_reqTag,
  output logic           io_msStatus_11_bits_is_miss,
  output logic           io_msStatus_11_bits_is_prefetch,
  output logic           io_msStatus_12_valid,
  output logic [2:0]     io_msStatus_12_bits_channel,
  output logic [8:0]     io_msStatus_12_bits_set,
  output logic [30:0]    io_msStatus_12_bits_reqTag,
  output logic           io_msStatus_12_bits_is_miss,
  output logic           io_msStatus_12_bits_is_prefetch,
  output logic           io_msStatus_13_valid,
  output logic [2:0]     io_msStatus_13_bits_channel,
  output logic [8:0]     io_msStatus_13_bits_set,
  output logic [30:0]    io_msStatus_13_bits_reqTag,
  output logic           io_msStatus_13_bits_is_miss,
  output logic           io_msStatus_13_bits_is_prefetch,
  output logic           io_msStatus_14_valid,
  output logic [2:0]     io_msStatus_14_bits_channel,
  output logic [8:0]     io_msStatus_14_bits_set,
  output logic [30:0]    io_msStatus_14_bits_reqTag,
  output logic           io_msStatus_14_bits_is_miss,
  output logic           io_msStatus_14_bits_is_prefetch,
  output logic           io_msStatus_15_valid,
  output logic [2:0]     io_msStatus_15_bits_channel,
  output logic [8:0]     io_msStatus_15_bits_set,
  output logic [30:0]    io_msStatus_15_bits_reqTag,
  output logic           io_msStatus_15_bits_is_miss,
  output logic           io_msStatus_15_bits_is_prefetch,
  output logic           io_msAlloc_0_valid,
  output logic [2:0]     io_msAlloc_0_bits_channel,
  output logic           io_msAlloc_0_bits_is_miss,
  output logic           io_msAlloc_0_bits_is_prefetch,
  output logic           io_msAlloc_1_valid,
  output logic [2:0]     io_msAlloc_1_bits_channel,
  output logic           io_msAlloc_1_bits_is_miss,
  output logic           io_msAlloc_1_bits_is_prefetch,
  output logic           io_msAlloc_2_valid,
  output logic [2:0]     io_msAlloc_2_bits_channel,
  output logic           io_msAlloc_2_bits_is_miss,
  output logic           io_msAlloc_2_bits_is_prefetch,
  output logic           io_msAlloc_3_valid,
  output logic [2:0]     io_msAlloc_3_bits_channel,
  output logic           io_msAlloc_3_bits_is_miss,
  output logic           io_msAlloc_3_bits_is_prefetch,
  output logic           io_msAlloc_4_valid,
  output logic [2:0]     io_msAlloc_4_bits_channel,
  output logic           io_msAlloc_4_bits_is_miss,
  output logic           io_msAlloc_4_bits_is_prefetch,
  output logic           io_msAlloc_5_valid,
  output logic [2:0]     io_msAlloc_5_bits_channel,
  output logic           io_msAlloc_5_bits_is_miss,
  output logic           io_msAlloc_5_bits_is_prefetch,
  output logic           io_msAlloc_6_valid,
  output logic [2:0]     io_msAlloc_6_bits_channel,
  output logic           io_msAlloc_6_bits_is_miss,
  output logic           io_msAlloc_6_bits_is_prefetch,
  output logic           io_msAlloc_7_valid,
  output logic [2:0]     io_msAlloc_7_bits_channel,
  output logic           io_msAlloc_7_bits_is_miss,
  output logic           io_msAlloc_7_bits_is_prefetch,
  output logic           io_msAlloc_8_valid,
  output logic [2:0]     io_msAlloc_8_bits_channel,
  output logic           io_msAlloc_8_bits_is_miss,
  output logic           io_msAlloc_8_bits_is_prefetch,
  output logic           io_msAlloc_9_valid,
  output logic [2:0]     io_msAlloc_9_bits_channel,
  output logic           io_msAlloc_9_bits_is_miss,
  output logic           io_msAlloc_9_bits_is_prefetch,
  output logic           io_msAlloc_10_valid,
  output logic [2:0]     io_msAlloc_10_bits_channel,
  output logic           io_msAlloc_10_bits_is_miss,
  output logic           io_msAlloc_10_bits_is_prefetch,
  output logic           io_msAlloc_11_valid,
  output logic [2:0]     io_msAlloc_11_bits_channel,
  output logic           io_msAlloc_11_bits_is_miss,
  output logic           io_msAlloc_11_bits_is_prefetch,
  output logic           io_msAlloc_12_valid,
  output logic [2:0]     io_msAlloc_12_bits_channel,
  output logic           io_msAlloc_12_bits_is_miss,
  output logic           io_msAlloc_12_bits_is_prefetch,
  output logic           io_msAlloc_13_valid,
  output logic [2:0]     io_msAlloc_13_bits_channel,
  output logic           io_msAlloc_13_bits_is_miss,
  output logic           io_msAlloc_13_bits_is_prefetch,
  output logic           io_msAlloc_14_valid,
  output logic [2:0]     io_msAlloc_14_bits_channel,
  output logic           io_msAlloc_14_bits_is_miss,
  output logic           io_msAlloc_14_bits_is_prefetch,
  output logic           io_msAlloc_15_valid,
  output logic [2:0]     io_msAlloc_15_bits_channel,
  output logic           io_msAlloc_15_bits_is_miss,
  output logic           io_msAlloc_15_bits_is_prefetch,
  input  logic           io_out_tx_req_ready,
  output logic           io_out_tx_req_valid,
  output logic [3:0]     io_out_tx_req_bits_qos,
  output logic [11:0]    io_out_tx_req_bits_txnID,
  output logic [10:0]    io_out_tx_req_bits_returnNID,
  output logic           io_out_tx_req_bits_stashNIDValid,
  output logic [11:0]    io_out_tx_req_bits_returnTxnID,
  output logic [6:0]     io_out_tx_req_bits_opcode,
  output logic [47:0]    io_out_tx_req_bits_addr,
  output logic           io_out_tx_req_bits_ns,
  output logic           io_out_tx_req_bits_likelyshared,
  output logic           io_out_tx_req_bits_allowRetry,
  output logic [1:0]     io_out_tx_req_bits_order,
  output logic [3:0]     io_out_tx_req_bits_pCrdType,
  output logic           io_out_tx_req_bits_memAttr_allocate,
  output logic           io_out_tx_req_bits_memAttr_cacheable,
  output logic           io_out_tx_req_bits_memAttr_device,
  output logic           io_out_tx_req_bits_memAttr_ewa,
  output logic           io_out_tx_req_bits_snpAttr,
  output logic [7:0]     io_out_tx_req_bits_lpIDWithPadding,
  output logic           io_out_tx_req_bits_snoopMe,
  output logic           io_out_tx_req_bits_expCompAck,
  output logic [1:0]     io_out_tx_req_bits_tagOp,
  output logic           io_out_tx_req_bits_traceTag,
  output logic           io_out_tx_req_bits_mpam_perfMonGroup,
  output logic [8:0]     io_out_tx_req_bits_mpam_partID,
  output logic           io_out_tx_req_bits_mpam_mpamNS,
  output logic [3:0]     io_out_tx_req_bits_rsvdc,
  input  logic           io_out_tx_rsp_ready,
  output logic           io_out_tx_rsp_valid,
  output logic [3:0]     io_out_tx_rsp_bits_qos,
  output logic [10:0]    io_out_tx_rsp_bits_tgtID,
  output logic [11:0]    io_out_tx_rsp_bits_txnID,
  output logic [4:0]     io_out_tx_rsp_bits_opcode,
  output logic [1:0]     io_out_tx_rsp_bits_respErr,
  output logic [2:0]     io_out_tx_rsp_bits_resp,
  output logic [2:0]     io_out_tx_rsp_bits_fwdState,
  output logic [2:0]     io_out_tx_rsp_bits_cBusy,
  output logic [11:0]    io_out_tx_rsp_bits_dbID,
  output logic [3:0]     io_out_tx_rsp_bits_pCrdType,
  output logic [1:0]     io_out_tx_rsp_bits_tagOp,
  output logic           io_out_tx_rsp_bits_traceTag,
  input  logic           io_out_tx_dat_ready,
  output logic           io_out_tx_dat_valid,
  output logic [10:0]    io_out_tx_dat_bits_tgtID,
  output logic [11:0]    io_out_tx_dat_bits_txnID,
  output logic [10:0]    io_out_tx_dat_bits_homeNID,
  output logic [3:0]     io_out_tx_dat_bits_opcode,
  output logic [1:0]     io_out_tx_dat_bits_respErr,
  output logic [2:0]     io_out_tx_dat_bits_resp,
  output logic [3:0]     io_out_tx_dat_bits_dataSource,
  output logic [11:0]    io_out_tx_dat_bits_dbID,
  output logic [1:0]     io_out_tx_dat_bits_ccID,
  output logic [1:0]     io_out_tx_dat_bits_dataID,
  output logic           io_out_tx_dat_bits_traceTag,
  output logic [31:0]    io_out_tx_dat_bits_be,
  output logic [255:0]   io_out_tx_dat_bits_data,
  output logic [31:0]    io_out_tx_dat_bits_dataCheck,
  output logic [3:0]     io_out_tx_dat_bits_poison,
  input  logic           io_out_rx_rsp_valid,
  input  logic [10:0]    io_out_rx_rsp_bits_srcID,
  input  logic [11:0]    io_out_rx_rsp_bits_txnID,
  input  logic [4:0]     io_out_rx_rsp_bits_opcode,
  input  logic [1:0]     io_out_rx_rsp_bits_respErr,
  input  logic [2:0]     io_out_rx_rsp_bits_resp,
  input  logic [11:0]    io_out_rx_rsp_bits_dbID,
  input  logic [3:0]     io_out_rx_rsp_bits_pCrdType,
  input  logic           io_out_rx_rsp_bits_traceTag,
  input  logic           io_out_rx_dat_valid,
  input  logic [11:0]    io_out_rx_dat_bits_txnID,
  input  logic [10:0]    io_out_rx_dat_bits_homeNID,
  input  logic [3:0]     io_out_rx_dat_bits_opcode,
  input  logic [1:0]     io_out_rx_dat_bits_respErr,
  input  logic [2:0]     io_out_rx_dat_bits_resp,
  input  logic [11:0]    io_out_rx_dat_bits_dbID,
  input  logic [1:0]     io_out_rx_dat_bits_dataID,
  input  logic           io_out_rx_dat_bits_traceTag,
  input  logic [255:0]   io_out_rx_dat_bits_data,
  input  logic [31:0]    io_out_rx_dat_bits_dataCheck,
  input  logic [3:0]     io_out_rx_dat_bits_poison,
  output logic           io_out_rx_snp_ready,
  input  logic           io_out_rx_snp_valid,
  input  logic [3:0]     io_out_rx_snp_bits_qos,
  input  logic [10:0]    io_out_rx_snp_bits_srcID,
  input  logic [11:0]    io_out_rx_snp_bits_txnID,
  input  logic [10:0]    io_out_rx_snp_bits_fwdNID,
  input  logic [11:0]    io_out_rx_snp_bits_fwdTxnID,
  input  logic [4:0]     io_out_rx_snp_bits_opcode,
  input  logic [44:0]    io_out_rx_snp_bits_addr,
  input  logic           io_out_rx_snp_bits_ns,
  input  logic           io_out_rx_snp_bits_doNotGoToSD,
  input  logic           io_out_rx_snp_bits_retToSrc,
  input  logic           io_out_rx_snp_bits_traceTag,
  input  logic           io_out_rx_snp_bits_mpam_perfMonGroup,
  input  logic [8:0]     io_out_rx_snp_bits_mpam_partID,
  input  logic           io_out_rx_snp_bits_mpam_mpamNS,
  output logic           io_pCrd_0_query_valid,
  output logic [3:0]     io_pCrd_0_query_bits_pCrdType,
  output logic [10:0]    io_pCrd_0_query_bits_srcID,
  input  logic           io_pCrd_0_grant,
  output logic           io_pCrd_1_query_valid,
  output logic [3:0]     io_pCrd_1_query_bits_pCrdType,
  output logic [10:0]    io_pCrd_1_query_bits_srcID,
  input  logic           io_pCrd_1_grant,
  output logic           io_pCrd_2_query_valid,
  output logic [3:0]     io_pCrd_2_query_bits_pCrdType,
  output logic [10:0]    io_pCrd_2_query_bits_srcID,
  input  logic           io_pCrd_2_grant,
  output logic           io_pCrd_3_query_valid,
  output logic [3:0]     io_pCrd_3_query_bits_pCrdType,
  output logic [10:0]    io_pCrd_3_query_bits_srcID,
  input  logic           io_pCrd_3_grant,
  output logic           io_pCrd_4_query_valid,
  output logic [3:0]     io_pCrd_4_query_bits_pCrdType,
  output logic [10:0]    io_pCrd_4_query_bits_srcID,
  input  logic           io_pCrd_4_grant,
  output logic           io_pCrd_5_query_valid,
  output logic [3:0]     io_pCrd_5_query_bits_pCrdType,
  output logic [10:0]    io_pCrd_5_query_bits_srcID,
  input  logic           io_pCrd_5_grant,
  output logic           io_pCrd_6_query_valid,
  output logic [3:0]     io_pCrd_6_query_bits_pCrdType,
  output logic [10:0]    io_pCrd_6_query_bits_srcID,
  input  logic           io_pCrd_6_grant,
  output logic           io_pCrd_7_query_valid,
  output logic [3:0]     io_pCrd_7_query_bits_pCrdType,
  output logic [10:0]    io_pCrd_7_query_bits_srcID,
  input  logic           io_pCrd_7_grant,
  output logic           io_pCrd_8_query_valid,
  output logic [3:0]     io_pCrd_8_query_bits_pCrdType,
  output logic [10:0]    io_pCrd_8_query_bits_srcID,
  input  logic           io_pCrd_8_grant,
  output logic           io_pCrd_9_query_valid,
  output logic [3:0]     io_pCrd_9_query_bits_pCrdType,
  output logic [10:0]    io_pCrd_9_query_bits_srcID,
  input  logic           io_pCrd_9_grant,
  output logic           io_pCrd_10_query_valid,
  output logic [3:0]     io_pCrd_10_query_bits_pCrdType,
  output logic [10:0]    io_pCrd_10_query_bits_srcID,
  input  logic           io_pCrd_10_grant,
  output logic           io_pCrd_11_query_valid,
  output logic [3:0]     io_pCrd_11_query_bits_pCrdType,
  output logic [10:0]    io_pCrd_11_query_bits_srcID,
  input  logic           io_pCrd_11_grant,
  output logic           io_pCrd_12_query_valid,
  output logic [3:0]     io_pCrd_12_query_bits_pCrdType,
  output logic [10:0]    io_pCrd_12_query_bits_srcID,
  input  logic           io_pCrd_12_grant,
  output logic           io_pCrd_13_query_valid,
  output logic [3:0]     io_pCrd_13_query_bits_pCrdType,
  output logic [10:0]    io_pCrd_13_query_bits_srcID,
  input  logic           io_pCrd_13_grant,
  output logic           io_pCrd_14_query_valid,
  output logic [3:0]     io_pCrd_14_query_bits_pCrdType,
  output logic [10:0]    io_pCrd_14_query_bits_srcID,
  input  logic           io_pCrd_14_grant,
  output logic           io_pCrd_15_query_valid,
  output logic [3:0]     io_pCrd_15_query_bits_pCrdType,
  output logic [10:0]    io_pCrd_15_query_bits_srcID,
  input  logic           io_pCrd_15_grant,
  output logic [5:0]     io_perf_0_value,
  output logic [5:0]     io_perf_1_value,
  output logic [5:0]     io_perf_3_value,
  output logic [5:0]     io_perf_4_value,
  output logic [5:0]     io_perf_5_value,
  output logic [5:0]     io_perf_6_value,
  output logic [5:0]     io_perf_7_value,
  output logic [5:0]     io_perf_8_value,
  output logic [5:0]     io_perf_9_value,
  output logic [5:0]     io_perf_10_value,
  output logic [5:0]     io_perf_11_value,
  output logic [5:0]     io_perf_12_value,
  output logic [5:0]     io_perf_13_value,
  output logic [5:0]     io_perf_14_value,
  output logic [5:0]     io_perf_15_value,
  output logic [5:0]     io_perf_16_value,
  input  logic           dir_read_ready,
  output logic           dir_read_valid,
  output logic [30:0]    dir_read_bits_tag,
  output logic [8:0]     dir_read_bits_set,
  output logic [7:0]     dir_read_bits_wayMask,
  output logic [2:0]     dir_read_bits_replacerInfo_channel,
  output logic [2:0]     dir_read_bits_replacerInfo_opcode,
  output logic [4:0]     dir_read_bits_replacerInfo_reqSource,
  output logic           dir_read_bits_replacerInfo_refill_prefetch,
  output logic           dir_read_bits_refill,
  output logic [7:0]     dir_read_bits_mshrId,
  output logic           dir_read_bits_cmoAll,
  output logic [2:0]     dir_read_bits_cmoWay,
  input  logic           dir_resp_valid,
  input  logic           dir_resp_bits_hit,
  input  logic [30:0]    dir_resp_bits_tag,
  input  logic [8:0]     dir_resp_bits_set,
  input  logic [2:0]     dir_resp_bits_way,
  input  logic           dir_resp_bits_meta_dirty,
  input  logic [1:0]     dir_resp_bits_meta_state,
  input  logic           dir_resp_bits_meta_clients,
  input  logic [1:0]     dir_resp_bits_meta_alias,
  input  logic           dir_resp_bits_meta_prefetch,
  input  logic [2:0]     dir_resp_bits_meta_prefetchSrc,
  input  logic           dir_resp_bits_meta_accessed,
  input  logic           dir_resp_bits_meta_tagErr,
  input  logic           dir_resp_bits_meta_dataErr,
  input  logic           dir_resp_bits_error,
  output logic           dir_metaWReq_valid,
  output logic [8:0]     dir_metaWReq_bits_set,
  output logic [7:0]     dir_metaWReq_bits_wayOH,
  output logic           dir_metaWReq_bits_wmeta_dirty,
  output logic [1:0]     dir_metaWReq_bits_wmeta_state,
  output logic           dir_metaWReq_bits_wmeta_clients,
  output logic [1:0]     dir_metaWReq_bits_wmeta_alias,
  output logic           dir_metaWReq_bits_wmeta_prefetch,
  output logic [2:0]     dir_metaWReq_bits_wmeta_prefetchSrc,
  output logic           dir_metaWReq_bits_wmeta_accessed,
  output logic           dir_metaWReq_bits_wmeta_tagErr,
  output logic           dir_metaWReq_bits_wmeta_dataErr,
  output logic           dir_tagWReq_valid,
  output logic [8:0]     dir_tagWReq_bits_set,
  output logic [2:0]     dir_tagWReq_bits_way,
  output logic [30:0]    dir_tagWReq_bits_wtag,
  input  logic           dir_replResp_valid,
  input  logic [30:0]    dir_replResp_bits_tag,
  input  logic [2:0]     dir_replResp_bits_way,
  input  logic           dir_replResp_bits_meta_dirty,
  input  logic [1:0]     dir_replResp_bits_meta_state,
  input  logic           dir_replResp_bits_meta_clients,
  input  logic [1:0]     dir_replResp_bits_meta_alias,
  input  logic           dir_replResp_bits_meta_prefetch,
  input  logic [2:0]     dir_replResp_bits_meta_prefetchSrc,
  input  logic           dir_replResp_bits_meta_accessed,
  input  logic           dir_replResp_bits_meta_tagErr,
  input  logic           dir_replResp_bits_meta_dataErr,
  input  logic [7:0]     dir_replResp_bits_mshrId,
  input  logic           dir_replResp_bits_retry,
  input  logic           dir_replResp_bits_error,
  output logic           dir_msInfo_0_valid,
  output logic [2:0]     dir_msInfo_0_bits_channel,
  output logic [8:0]     dir_msInfo_0_bits_set,
  output logic [2:0]     dir_msInfo_0_bits_way,
  output logic [30:0]    dir_msInfo_0_bits_reqTag,
  output logic           dir_msInfo_0_bits_willFree,
  output logic           dir_msInfo_0_bits_aliasTask,
  output logic           dir_msInfo_0_bits_needRelease,
  output logic           dir_msInfo_0_bits_blockRefill,
  output logic           dir_msInfo_0_bits_meta_dirty,
  output logic [1:0]     dir_msInfo_0_bits_meta_state,
  output logic           dir_msInfo_0_bits_meta_clients,
  output logic [1:0]     dir_msInfo_0_bits_meta_alias,
  output logic           dir_msInfo_0_bits_meta_prefetch,
  output logic [2:0]     dir_msInfo_0_bits_meta_prefetchSrc,
  output logic           dir_msInfo_0_bits_meta_accessed,
  output logic           dir_msInfo_0_bits_meta_tagErr,
  output logic           dir_msInfo_0_bits_meta_dataErr,
  output logic [30:0]    dir_msInfo_0_bits_metaTag,
  output logic           dir_msInfo_0_bits_dirHit,
  output logic           dir_msInfo_0_bits_isAcqOrPrefetch,
  output logic           dir_msInfo_0_bits_isPrefetch,
  output logic [2:0]     dir_msInfo_0_bits_param,
  output logic           dir_msInfo_0_bits_mergeA,
  output logic           dir_msInfo_0_bits_w_grantfirst,
  output logic           dir_msInfo_0_bits_s_release,
  output logic           dir_msInfo_0_bits_s_refill,
  output logic           dir_msInfo_0_bits_s_cmoresp,
  output logic           dir_msInfo_0_bits_s_cmometaw,
  output logic           dir_msInfo_0_bits_w_releaseack,
  output logic           dir_msInfo_0_bits_w_replResp,
  output logic           dir_msInfo_0_bits_w_rprobeacklast,
  output logic           dir_msInfo_0_bits_replaceData,
  output logic           dir_msInfo_0_bits_releaseToClean,
  output logic           dir_msInfo_1_valid,
  output logic [2:0]     dir_msInfo_1_bits_channel,
  output logic [8:0]     dir_msInfo_1_bits_set,
  output logic [2:0]     dir_msInfo_1_bits_way,
  output logic [30:0]    dir_msInfo_1_bits_reqTag,
  output logic           dir_msInfo_1_bits_willFree,
  output logic           dir_msInfo_1_bits_aliasTask,
  output logic           dir_msInfo_1_bits_needRelease,
  output logic           dir_msInfo_1_bits_blockRefill,
  output logic           dir_msInfo_1_bits_meta_dirty,
  output logic [1:0]     dir_msInfo_1_bits_meta_state,
  output logic           dir_msInfo_1_bits_meta_clients,
  output logic [1:0]     dir_msInfo_1_bits_meta_alias,
  output logic           dir_msInfo_1_bits_meta_prefetch,
  output logic [2:0]     dir_msInfo_1_bits_meta_prefetchSrc,
  output logic           dir_msInfo_1_bits_meta_accessed,
  output logic           dir_msInfo_1_bits_meta_tagErr,
  output logic           dir_msInfo_1_bits_meta_dataErr,
  output logic [30:0]    dir_msInfo_1_bits_metaTag,
  output logic           dir_msInfo_1_bits_dirHit,
  output logic           dir_msInfo_1_bits_isAcqOrPrefetch,
  output logic           dir_msInfo_1_bits_isPrefetch,
  output logic [2:0]     dir_msInfo_1_bits_param,
  output logic           dir_msInfo_1_bits_mergeA,
  output logic           dir_msInfo_1_bits_w_grantfirst,
  output logic           dir_msInfo_1_bits_s_release,
  output logic           dir_msInfo_1_bits_s_refill,
  output logic           dir_msInfo_1_bits_s_cmoresp,
  output logic           dir_msInfo_1_bits_s_cmometaw,
  output logic           dir_msInfo_1_bits_w_releaseack,
  output logic           dir_msInfo_1_bits_w_replResp,
  output logic           dir_msInfo_1_bits_w_rprobeacklast,
  output logic           dir_msInfo_1_bits_replaceData,
  output logic           dir_msInfo_1_bits_releaseToClean,
  output logic           dir_msInfo_2_valid,
  output logic [2:0]     dir_msInfo_2_bits_channel,
  output logic [8:0]     dir_msInfo_2_bits_set,
  output logic [2:0]     dir_msInfo_2_bits_way,
  output logic [30:0]    dir_msInfo_2_bits_reqTag,
  output logic           dir_msInfo_2_bits_willFree,
  output logic           dir_msInfo_2_bits_aliasTask,
  output logic           dir_msInfo_2_bits_needRelease,
  output logic           dir_msInfo_2_bits_blockRefill,
  output logic           dir_msInfo_2_bits_meta_dirty,
  output logic [1:0]     dir_msInfo_2_bits_meta_state,
  output logic           dir_msInfo_2_bits_meta_clients,
  output logic [1:0]     dir_msInfo_2_bits_meta_alias,
  output logic           dir_msInfo_2_bits_meta_prefetch,
  output logic [2:0]     dir_msInfo_2_bits_meta_prefetchSrc,
  output logic           dir_msInfo_2_bits_meta_accessed,
  output logic           dir_msInfo_2_bits_meta_tagErr,
  output logic           dir_msInfo_2_bits_meta_dataErr,
  output logic [30:0]    dir_msInfo_2_bits_metaTag,
  output logic           dir_msInfo_2_bits_dirHit,
  output logic           dir_msInfo_2_bits_isAcqOrPrefetch,
  output logic           dir_msInfo_2_bits_isPrefetch,
  output logic [2:0]     dir_msInfo_2_bits_param,
  output logic           dir_msInfo_2_bits_mergeA,
  output logic           dir_msInfo_2_bits_w_grantfirst,
  output logic           dir_msInfo_2_bits_s_release,
  output logic           dir_msInfo_2_bits_s_refill,
  output logic           dir_msInfo_2_bits_s_cmoresp,
  output logic           dir_msInfo_2_bits_s_cmometaw,
  output logic           dir_msInfo_2_bits_w_releaseack,
  output logic           dir_msInfo_2_bits_w_replResp,
  output logic           dir_msInfo_2_bits_w_rprobeacklast,
  output logic           dir_msInfo_2_bits_replaceData,
  output logic           dir_msInfo_2_bits_releaseToClean,
  output logic           dir_msInfo_3_valid,
  output logic [2:0]     dir_msInfo_3_bits_channel,
  output logic [8:0]     dir_msInfo_3_bits_set,
  output logic [2:0]     dir_msInfo_3_bits_way,
  output logic [30:0]    dir_msInfo_3_bits_reqTag,
  output logic           dir_msInfo_3_bits_willFree,
  output logic           dir_msInfo_3_bits_aliasTask,
  output logic           dir_msInfo_3_bits_needRelease,
  output logic           dir_msInfo_3_bits_blockRefill,
  output logic           dir_msInfo_3_bits_meta_dirty,
  output logic [1:0]     dir_msInfo_3_bits_meta_state,
  output logic           dir_msInfo_3_bits_meta_clients,
  output logic [1:0]     dir_msInfo_3_bits_meta_alias,
  output logic           dir_msInfo_3_bits_meta_prefetch,
  output logic [2:0]     dir_msInfo_3_bits_meta_prefetchSrc,
  output logic           dir_msInfo_3_bits_meta_accessed,
  output logic           dir_msInfo_3_bits_meta_tagErr,
  output logic           dir_msInfo_3_bits_meta_dataErr,
  output logic [30:0]    dir_msInfo_3_bits_metaTag,
  output logic           dir_msInfo_3_bits_dirHit,
  output logic           dir_msInfo_3_bits_isAcqOrPrefetch,
  output logic           dir_msInfo_3_bits_isPrefetch,
  output logic [2:0]     dir_msInfo_3_bits_param,
  output logic           dir_msInfo_3_bits_mergeA,
  output logic           dir_msInfo_3_bits_w_grantfirst,
  output logic           dir_msInfo_3_bits_s_release,
  output logic           dir_msInfo_3_bits_s_refill,
  output logic           dir_msInfo_3_bits_s_cmoresp,
  output logic           dir_msInfo_3_bits_s_cmometaw,
  output logic           dir_msInfo_3_bits_w_releaseack,
  output logic           dir_msInfo_3_bits_w_replResp,
  output logic           dir_msInfo_3_bits_w_rprobeacklast,
  output logic           dir_msInfo_3_bits_replaceData,
  output logic           dir_msInfo_3_bits_releaseToClean,
  output logic           dir_msInfo_4_valid,
  output logic [2:0]     dir_msInfo_4_bits_channel,
  output logic [8:0]     dir_msInfo_4_bits_set,
  output logic [2:0]     dir_msInfo_4_bits_way,
  output logic [30:0]    dir_msInfo_4_bits_reqTag,
  output logic           dir_msInfo_4_bits_willFree,
  output logic           dir_msInfo_4_bits_aliasTask,
  output logic           dir_msInfo_4_bits_needRelease,
  output logic           dir_msInfo_4_bits_blockRefill,
  output logic           dir_msInfo_4_bits_meta_dirty,
  output logic [1:0]     dir_msInfo_4_bits_meta_state,
  output logic           dir_msInfo_4_bits_meta_clients,
  output logic [1:0]     dir_msInfo_4_bits_meta_alias,
  output logic           dir_msInfo_4_bits_meta_prefetch,
  output logic [2:0]     dir_msInfo_4_bits_meta_prefetchSrc,
  output logic           dir_msInfo_4_bits_meta_accessed,
  output logic           dir_msInfo_4_bits_meta_tagErr,
  output logic           dir_msInfo_4_bits_meta_dataErr,
  output logic [30:0]    dir_msInfo_4_bits_metaTag,
  output logic           dir_msInfo_4_bits_dirHit,
  output logic           dir_msInfo_4_bits_isAcqOrPrefetch,
  output logic           dir_msInfo_4_bits_isPrefetch,
  output logic [2:0]     dir_msInfo_4_bits_param,
  output logic           dir_msInfo_4_bits_mergeA,
  output logic           dir_msInfo_4_bits_w_grantfirst,
  output logic           dir_msInfo_4_bits_s_release,
  output logic           dir_msInfo_4_bits_s_refill,
  output logic           dir_msInfo_4_bits_s_cmoresp,
  output logic           dir_msInfo_4_bits_s_cmometaw,
  output logic           dir_msInfo_4_bits_w_releaseack,
  output logic           dir_msInfo_4_bits_w_replResp,
  output logic           dir_msInfo_4_bits_w_rprobeacklast,
  output logic           dir_msInfo_4_bits_replaceData,
  output logic           dir_msInfo_4_bits_releaseToClean,
  output logic           dir_msInfo_5_valid,
  output logic [2:0]     dir_msInfo_5_bits_channel,
  output logic [8:0]     dir_msInfo_5_bits_set,
  output logic [2:0]     dir_msInfo_5_bits_way,
  output logic [30:0]    dir_msInfo_5_bits_reqTag,
  output logic           dir_msInfo_5_bits_willFree,
  output logic           dir_msInfo_5_bits_aliasTask,
  output logic           dir_msInfo_5_bits_needRelease,
  output logic           dir_msInfo_5_bits_blockRefill,
  output logic           dir_msInfo_5_bits_meta_dirty,
  output logic [1:0]     dir_msInfo_5_bits_meta_state,
  output logic           dir_msInfo_5_bits_meta_clients,
  output logic [1:0]     dir_msInfo_5_bits_meta_alias,
  output logic           dir_msInfo_5_bits_meta_prefetch,
  output logic [2:0]     dir_msInfo_5_bits_meta_prefetchSrc,
  output logic           dir_msInfo_5_bits_meta_accessed,
  output logic           dir_msInfo_5_bits_meta_tagErr,
  output logic           dir_msInfo_5_bits_meta_dataErr,
  output logic [30:0]    dir_msInfo_5_bits_metaTag,
  output logic           dir_msInfo_5_bits_dirHit,
  output logic           dir_msInfo_5_bits_isAcqOrPrefetch,
  output logic           dir_msInfo_5_bits_isPrefetch,
  output logic [2:0]     dir_msInfo_5_bits_param,
  output logic           dir_msInfo_5_bits_mergeA,
  output logic           dir_msInfo_5_bits_w_grantfirst,
  output logic           dir_msInfo_5_bits_s_release,
  output logic           dir_msInfo_5_bits_s_refill,
  output logic           dir_msInfo_5_bits_s_cmoresp,
  output logic           dir_msInfo_5_bits_s_cmometaw,
  output logic           dir_msInfo_5_bits_w_releaseack,
  output logic           dir_msInfo_5_bits_w_replResp,
  output logic           dir_msInfo_5_bits_w_rprobeacklast,
  output logic           dir_msInfo_5_bits_replaceData,
  output logic           dir_msInfo_5_bits_releaseToClean,
  output logic           dir_msInfo_6_valid,
  output logic [2:0]     dir_msInfo_6_bits_channel,
  output logic [8:0]     dir_msInfo_6_bits_set,
  output logic [2:0]     dir_msInfo_6_bits_way,
  output logic [30:0]    dir_msInfo_6_bits_reqTag,
  output logic           dir_msInfo_6_bits_willFree,
  output logic           dir_msInfo_6_bits_aliasTask,
  output logic           dir_msInfo_6_bits_needRelease,
  output logic           dir_msInfo_6_bits_blockRefill,
  output logic           dir_msInfo_6_bits_meta_dirty,
  output logic [1:0]     dir_msInfo_6_bits_meta_state,
  output logic           dir_msInfo_6_bits_meta_clients,
  output logic [1:0]     dir_msInfo_6_bits_meta_alias,
  output logic           dir_msInfo_6_bits_meta_prefetch,
  output logic [2:0]     dir_msInfo_6_bits_meta_prefetchSrc,
  output logic           dir_msInfo_6_bits_meta_accessed,
  output logic           dir_msInfo_6_bits_meta_tagErr,
  output logic           dir_msInfo_6_bits_meta_dataErr,
  output logic [30:0]    dir_msInfo_6_bits_metaTag,
  output logic           dir_msInfo_6_bits_dirHit,
  output logic           dir_msInfo_6_bits_isAcqOrPrefetch,
  output logic           dir_msInfo_6_bits_isPrefetch,
  output logic [2:0]     dir_msInfo_6_bits_param,
  output logic           dir_msInfo_6_bits_mergeA,
  output logic           dir_msInfo_6_bits_w_grantfirst,
  output logic           dir_msInfo_6_bits_s_release,
  output logic           dir_msInfo_6_bits_s_refill,
  output logic           dir_msInfo_6_bits_s_cmoresp,
  output logic           dir_msInfo_6_bits_s_cmometaw,
  output logic           dir_msInfo_6_bits_w_releaseack,
  output logic           dir_msInfo_6_bits_w_replResp,
  output logic           dir_msInfo_6_bits_w_rprobeacklast,
  output logic           dir_msInfo_6_bits_replaceData,
  output logic           dir_msInfo_6_bits_releaseToClean,
  output logic           dir_msInfo_7_valid,
  output logic [2:0]     dir_msInfo_7_bits_channel,
  output logic [8:0]     dir_msInfo_7_bits_set,
  output logic [2:0]     dir_msInfo_7_bits_way,
  output logic [30:0]    dir_msInfo_7_bits_reqTag,
  output logic           dir_msInfo_7_bits_willFree,
  output logic           dir_msInfo_7_bits_aliasTask,
  output logic           dir_msInfo_7_bits_needRelease,
  output logic           dir_msInfo_7_bits_blockRefill,
  output logic           dir_msInfo_7_bits_meta_dirty,
  output logic [1:0]     dir_msInfo_7_bits_meta_state,
  output logic           dir_msInfo_7_bits_meta_clients,
  output logic [1:0]     dir_msInfo_7_bits_meta_alias,
  output logic           dir_msInfo_7_bits_meta_prefetch,
  output logic [2:0]     dir_msInfo_7_bits_meta_prefetchSrc,
  output logic           dir_msInfo_7_bits_meta_accessed,
  output logic           dir_msInfo_7_bits_meta_tagErr,
  output logic           dir_msInfo_7_bits_meta_dataErr,
  output logic [30:0]    dir_msInfo_7_bits_metaTag,
  output logic           dir_msInfo_7_bits_dirHit,
  output logic           dir_msInfo_7_bits_isAcqOrPrefetch,
  output logic           dir_msInfo_7_bits_isPrefetch,
  output logic [2:0]     dir_msInfo_7_bits_param,
  output logic           dir_msInfo_7_bits_mergeA,
  output logic           dir_msInfo_7_bits_w_grantfirst,
  output logic           dir_msInfo_7_bits_s_release,
  output logic           dir_msInfo_7_bits_s_refill,
  output logic           dir_msInfo_7_bits_s_cmoresp,
  output logic           dir_msInfo_7_bits_s_cmometaw,
  output logic           dir_msInfo_7_bits_w_releaseack,
  output logic           dir_msInfo_7_bits_w_replResp,
  output logic           dir_msInfo_7_bits_w_rprobeacklast,
  output logic           dir_msInfo_7_bits_replaceData,
  output logic           dir_msInfo_7_bits_releaseToClean,
  output logic           dir_msInfo_8_valid,
  output logic [2:0]     dir_msInfo_8_bits_channel,
  output logic [8:0]     dir_msInfo_8_bits_set,
  output logic [2:0]     dir_msInfo_8_bits_way,
  output logic [30:0]    dir_msInfo_8_bits_reqTag,
  output logic           dir_msInfo_8_bits_willFree,
  output logic           dir_msInfo_8_bits_aliasTask,
  output logic           dir_msInfo_8_bits_needRelease,
  output logic           dir_msInfo_8_bits_blockRefill,
  output logic           dir_msInfo_8_bits_meta_dirty,
  output logic [1:0]     dir_msInfo_8_bits_meta_state,
  output logic           dir_msInfo_8_bits_meta_clients,
  output logic [1:0]     dir_msInfo_8_bits_meta_alias,
  output logic           dir_msInfo_8_bits_meta_prefetch,
  output logic [2:0]     dir_msInfo_8_bits_meta_prefetchSrc,
  output logic           dir_msInfo_8_bits_meta_accessed,
  output logic           dir_msInfo_8_bits_meta_tagErr,
  output logic           dir_msInfo_8_bits_meta_dataErr,
  output logic [30:0]    dir_msInfo_8_bits_metaTag,
  output logic           dir_msInfo_8_bits_dirHit,
  output logic           dir_msInfo_8_bits_isAcqOrPrefetch,
  output logic           dir_msInfo_8_bits_isPrefetch,
  output logic [2:0]     dir_msInfo_8_bits_param,
  output logic           dir_msInfo_8_bits_mergeA,
  output logic           dir_msInfo_8_bits_w_grantfirst,
  output logic           dir_msInfo_8_bits_s_release,
  output logic           dir_msInfo_8_bits_s_refill,
  output logic           dir_msInfo_8_bits_s_cmoresp,
  output logic           dir_msInfo_8_bits_s_cmometaw,
  output logic           dir_msInfo_8_bits_w_releaseack,
  output logic           dir_msInfo_8_bits_w_replResp,
  output logic           dir_msInfo_8_bits_w_rprobeacklast,
  output logic           dir_msInfo_8_bits_replaceData,
  output logic           dir_msInfo_8_bits_releaseToClean,
  output logic           dir_msInfo_9_valid,
  output logic [2:0]     dir_msInfo_9_bits_channel,
  output logic [8:0]     dir_msInfo_9_bits_set,
  output logic [2:0]     dir_msInfo_9_bits_way,
  output logic [30:0]    dir_msInfo_9_bits_reqTag,
  output logic           dir_msInfo_9_bits_willFree,
  output logic           dir_msInfo_9_bits_aliasTask,
  output logic           dir_msInfo_9_bits_needRelease,
  output logic           dir_msInfo_9_bits_blockRefill,
  output logic           dir_msInfo_9_bits_meta_dirty,
  output logic [1:0]     dir_msInfo_9_bits_meta_state,
  output logic           dir_msInfo_9_bits_meta_clients,
  output logic [1:0]     dir_msInfo_9_bits_meta_alias,
  output logic           dir_msInfo_9_bits_meta_prefetch,
  output logic [2:0]     dir_msInfo_9_bits_meta_prefetchSrc,
  output logic           dir_msInfo_9_bits_meta_accessed,
  output logic           dir_msInfo_9_bits_meta_tagErr,
  output logic           dir_msInfo_9_bits_meta_dataErr,
  output logic [30:0]    dir_msInfo_9_bits_metaTag,
  output logic           dir_msInfo_9_bits_dirHit,
  output logic           dir_msInfo_9_bits_isAcqOrPrefetch,
  output logic           dir_msInfo_9_bits_isPrefetch,
  output logic [2:0]     dir_msInfo_9_bits_param,
  output logic           dir_msInfo_9_bits_mergeA,
  output logic           dir_msInfo_9_bits_w_grantfirst,
  output logic           dir_msInfo_9_bits_s_release,
  output logic           dir_msInfo_9_bits_s_refill,
  output logic           dir_msInfo_9_bits_s_cmoresp,
  output logic           dir_msInfo_9_bits_s_cmometaw,
  output logic           dir_msInfo_9_bits_w_releaseack,
  output logic           dir_msInfo_9_bits_w_replResp,
  output logic           dir_msInfo_9_bits_w_rprobeacklast,
  output logic           dir_msInfo_9_bits_replaceData,
  output logic           dir_msInfo_9_bits_releaseToClean,
  output logic           dir_msInfo_10_valid,
  output logic [2:0]     dir_msInfo_10_bits_channel,
  output logic [8:0]     dir_msInfo_10_bits_set,
  output logic [2:0]     dir_msInfo_10_bits_way,
  output logic [30:0]    dir_msInfo_10_bits_reqTag,
  output logic           dir_msInfo_10_bits_willFree,
  output logic           dir_msInfo_10_bits_aliasTask,
  output logic           dir_msInfo_10_bits_needRelease,
  output logic           dir_msInfo_10_bits_blockRefill,
  output logic           dir_msInfo_10_bits_meta_dirty,
  output logic [1:0]     dir_msInfo_10_bits_meta_state,
  output logic           dir_msInfo_10_bits_meta_clients,
  output logic [1:0]     dir_msInfo_10_bits_meta_alias,
  output logic           dir_msInfo_10_bits_meta_prefetch,
  output logic [2:0]     dir_msInfo_10_bits_meta_prefetchSrc,
  output logic           dir_msInfo_10_bits_meta_accessed,
  output logic           dir_msInfo_10_bits_meta_tagErr,
  output logic           dir_msInfo_10_bits_meta_dataErr,
  output logic [30:0]    dir_msInfo_10_bits_metaTag,
  output logic           dir_msInfo_10_bits_dirHit,
  output logic           dir_msInfo_10_bits_isAcqOrPrefetch,
  output logic           dir_msInfo_10_bits_isPrefetch,
  output logic [2:0]     dir_msInfo_10_bits_param,
  output logic           dir_msInfo_10_bits_mergeA,
  output logic           dir_msInfo_10_bits_w_grantfirst,
  output logic           dir_msInfo_10_bits_s_release,
  output logic           dir_msInfo_10_bits_s_refill,
  output logic           dir_msInfo_10_bits_s_cmoresp,
  output logic           dir_msInfo_10_bits_s_cmometaw,
  output logic           dir_msInfo_10_bits_w_releaseack,
  output logic           dir_msInfo_10_bits_w_replResp,
  output logic           dir_msInfo_10_bits_w_rprobeacklast,
  output logic           dir_msInfo_10_bits_replaceData,
  output logic           dir_msInfo_10_bits_releaseToClean,
  output logic           dir_msInfo_11_valid,
  output logic [2:0]     dir_msInfo_11_bits_channel,
  output logic [8:0]     dir_msInfo_11_bits_set,
  output logic [2:0]     dir_msInfo_11_bits_way,
  output logic [30:0]    dir_msInfo_11_bits_reqTag,
  output logic           dir_msInfo_11_bits_willFree,
  output logic           dir_msInfo_11_bits_aliasTask,
  output logic           dir_msInfo_11_bits_needRelease,
  output logic           dir_msInfo_11_bits_blockRefill,
  output logic           dir_msInfo_11_bits_meta_dirty,
  output logic [1:0]     dir_msInfo_11_bits_meta_state,
  output logic           dir_msInfo_11_bits_meta_clients,
  output logic [1:0]     dir_msInfo_11_bits_meta_alias,
  output logic           dir_msInfo_11_bits_meta_prefetch,
  output logic [2:0]     dir_msInfo_11_bits_meta_prefetchSrc,
  output logic           dir_msInfo_11_bits_meta_accessed,
  output logic           dir_msInfo_11_bits_meta_tagErr,
  output logic           dir_msInfo_11_bits_meta_dataErr,
  output logic [30:0]    dir_msInfo_11_bits_metaTag,
  output logic           dir_msInfo_11_bits_dirHit,
  output logic           dir_msInfo_11_bits_isAcqOrPrefetch,
  output logic           dir_msInfo_11_bits_isPrefetch,
  output logic [2:0]     dir_msInfo_11_bits_param,
  output logic           dir_msInfo_11_bits_mergeA,
  output logic           dir_msInfo_11_bits_w_grantfirst,
  output logic           dir_msInfo_11_bits_s_release,
  output logic           dir_msInfo_11_bits_s_refill,
  output logic           dir_msInfo_11_bits_s_cmoresp,
  output logic           dir_msInfo_11_bits_s_cmometaw,
  output logic           dir_msInfo_11_bits_w_releaseack,
  output logic           dir_msInfo_11_bits_w_replResp,
  output logic           dir_msInfo_11_bits_w_rprobeacklast,
  output logic           dir_msInfo_11_bits_replaceData,
  output logic           dir_msInfo_11_bits_releaseToClean,
  output logic           dir_msInfo_12_valid,
  output logic [2:0]     dir_msInfo_12_bits_channel,
  output logic [8:0]     dir_msInfo_12_bits_set,
  output logic [2:0]     dir_msInfo_12_bits_way,
  output logic [30:0]    dir_msInfo_12_bits_reqTag,
  output logic           dir_msInfo_12_bits_willFree,
  output logic           dir_msInfo_12_bits_aliasTask,
  output logic           dir_msInfo_12_bits_needRelease,
  output logic           dir_msInfo_12_bits_blockRefill,
  output logic           dir_msInfo_12_bits_meta_dirty,
  output logic [1:0]     dir_msInfo_12_bits_meta_state,
  output logic           dir_msInfo_12_bits_meta_clients,
  output logic [1:0]     dir_msInfo_12_bits_meta_alias,
  output logic           dir_msInfo_12_bits_meta_prefetch,
  output logic [2:0]     dir_msInfo_12_bits_meta_prefetchSrc,
  output logic           dir_msInfo_12_bits_meta_accessed,
  output logic           dir_msInfo_12_bits_meta_tagErr,
  output logic           dir_msInfo_12_bits_meta_dataErr,
  output logic [30:0]    dir_msInfo_12_bits_metaTag,
  output logic           dir_msInfo_12_bits_dirHit,
  output logic           dir_msInfo_12_bits_isAcqOrPrefetch,
  output logic           dir_msInfo_12_bits_isPrefetch,
  output logic [2:0]     dir_msInfo_12_bits_param,
  output logic           dir_msInfo_12_bits_mergeA,
  output logic           dir_msInfo_12_bits_w_grantfirst,
  output logic           dir_msInfo_12_bits_s_release,
  output logic           dir_msInfo_12_bits_s_refill,
  output logic           dir_msInfo_12_bits_s_cmoresp,
  output logic           dir_msInfo_12_bits_s_cmometaw,
  output logic           dir_msInfo_12_bits_w_releaseack,
  output logic           dir_msInfo_12_bits_w_replResp,
  output logic           dir_msInfo_12_bits_w_rprobeacklast,
  output logic           dir_msInfo_12_bits_replaceData,
  output logic           dir_msInfo_12_bits_releaseToClean,
  output logic           dir_msInfo_13_valid,
  output logic [2:0]     dir_msInfo_13_bits_channel,
  output logic [8:0]     dir_msInfo_13_bits_set,
  output logic [2:0]     dir_msInfo_13_bits_way,
  output logic [30:0]    dir_msInfo_13_bits_reqTag,
  output logic           dir_msInfo_13_bits_willFree,
  output logic           dir_msInfo_13_bits_aliasTask,
  output logic           dir_msInfo_13_bits_needRelease,
  output logic           dir_msInfo_13_bits_blockRefill,
  output logic           dir_msInfo_13_bits_meta_dirty,
  output logic [1:0]     dir_msInfo_13_bits_meta_state,
  output logic           dir_msInfo_13_bits_meta_clients,
  output logic [1:0]     dir_msInfo_13_bits_meta_alias,
  output logic           dir_msInfo_13_bits_meta_prefetch,
  output logic [2:0]     dir_msInfo_13_bits_meta_prefetchSrc,
  output logic           dir_msInfo_13_bits_meta_accessed,
  output logic           dir_msInfo_13_bits_meta_tagErr,
  output logic           dir_msInfo_13_bits_meta_dataErr,
  output logic [30:0]    dir_msInfo_13_bits_metaTag,
  output logic           dir_msInfo_13_bits_dirHit,
  output logic           dir_msInfo_13_bits_isAcqOrPrefetch,
  output logic           dir_msInfo_13_bits_isPrefetch,
  output logic [2:0]     dir_msInfo_13_bits_param,
  output logic           dir_msInfo_13_bits_mergeA,
  output logic           dir_msInfo_13_bits_w_grantfirst,
  output logic           dir_msInfo_13_bits_s_release,
  output logic           dir_msInfo_13_bits_s_refill,
  output logic           dir_msInfo_13_bits_s_cmoresp,
  output logic           dir_msInfo_13_bits_s_cmometaw,
  output logic           dir_msInfo_13_bits_w_releaseack,
  output logic           dir_msInfo_13_bits_w_replResp,
  output logic           dir_msInfo_13_bits_w_rprobeacklast,
  output logic           dir_msInfo_13_bits_replaceData,
  output logic           dir_msInfo_13_bits_releaseToClean,
  output logic           dir_msInfo_14_valid,
  output logic [2:0]     dir_msInfo_14_bits_channel,
  output logic [8:0]     dir_msInfo_14_bits_set,
  output logic [2:0]     dir_msInfo_14_bits_way,
  output logic [30:0]    dir_msInfo_14_bits_reqTag,
  output logic           dir_msInfo_14_bits_willFree,
  output logic           dir_msInfo_14_bits_aliasTask,
  output logic           dir_msInfo_14_bits_needRelease,
  output logic           dir_msInfo_14_bits_blockRefill,
  output logic           dir_msInfo_14_bits_meta_dirty,
  output logic [1:0]     dir_msInfo_14_bits_meta_state,
  output logic           dir_msInfo_14_bits_meta_clients,
  output logic [1:0]     dir_msInfo_14_bits_meta_alias,
  output logic           dir_msInfo_14_bits_meta_prefetch,
  output logic [2:0]     dir_msInfo_14_bits_meta_prefetchSrc,
  output logic           dir_msInfo_14_bits_meta_accessed,
  output logic           dir_msInfo_14_bits_meta_tagErr,
  output logic           dir_msInfo_14_bits_meta_dataErr,
  output logic [30:0]    dir_msInfo_14_bits_metaTag,
  output logic           dir_msInfo_14_bits_dirHit,
  output logic           dir_msInfo_14_bits_isAcqOrPrefetch,
  output logic           dir_msInfo_14_bits_isPrefetch,
  output logic [2:0]     dir_msInfo_14_bits_param,
  output logic           dir_msInfo_14_bits_mergeA,
  output logic           dir_msInfo_14_bits_w_grantfirst,
  output logic           dir_msInfo_14_bits_s_release,
  output logic           dir_msInfo_14_bits_s_refill,
  output logic           dir_msInfo_14_bits_s_cmoresp,
  output logic           dir_msInfo_14_bits_s_cmometaw,
  output logic           dir_msInfo_14_bits_w_releaseack,
  output logic           dir_msInfo_14_bits_w_replResp,
  output logic           dir_msInfo_14_bits_w_rprobeacklast,
  output logic           dir_msInfo_14_bits_replaceData,
  output logic           dir_msInfo_14_bits_releaseToClean,
  output logic           dir_msInfo_15_valid,
  output logic [2:0]     dir_msInfo_15_bits_channel,
  output logic [8:0]     dir_msInfo_15_bits_set,
  output logic [2:0]     dir_msInfo_15_bits_way,
  output logic [30:0]    dir_msInfo_15_bits_reqTag,
  output logic           dir_msInfo_15_bits_willFree,
  output logic           dir_msInfo_15_bits_aliasTask,
  output logic           dir_msInfo_15_bits_needRelease,
  output logic           dir_msInfo_15_bits_blockRefill,
  output logic           dir_msInfo_15_bits_meta_dirty,
  output logic [1:0]     dir_msInfo_15_bits_meta_state,
  output logic           dir_msInfo_15_bits_meta_clients,
  output logic [1:0]     dir_msInfo_15_bits_meta_alias,
  output logic           dir_msInfo_15_bits_meta_prefetch,
  output logic [2:0]     dir_msInfo_15_bits_meta_prefetchSrc,
  output logic           dir_msInfo_15_bits_meta_accessed,
  output logic           dir_msInfo_15_bits_meta_tagErr,
  output logic           dir_msInfo_15_bits_meta_dataErr,
  output logic [30:0]    dir_msInfo_15_bits_metaTag,
  output logic           dir_msInfo_15_bits_dirHit,
  output logic           dir_msInfo_15_bits_isAcqOrPrefetch,
  output logic           dir_msInfo_15_bits_isPrefetch,
  output logic [2:0]     dir_msInfo_15_bits_param,
  output logic           dir_msInfo_15_bits_mergeA,
  output logic           dir_msInfo_15_bits_w_grantfirst,
  output logic           dir_msInfo_15_bits_s_release,
  output logic           dir_msInfo_15_bits_s_refill,
  output logic           dir_msInfo_15_bits_s_cmoresp,
  output logic           dir_msInfo_15_bits_s_cmometaw,
  output logic           dir_msInfo_15_bits_w_releaseack,
  output logic           dir_msInfo_15_bits_w_replResp,
  output logic           dir_msInfo_15_bits_w_rprobeacklast,
  output logic           dir_msInfo_15_bits_replaceData,
  output logic           dir_msInfo_15_bits_releaseToClean,
  output logic           ds_en,
  input  logic           ds_error,
  output logic           ds_req_valid,
  output logic [2:0]     ds_req_bits_way,
  output logic [8:0]     ds_req_bits_set,
  output logic           ds_req_bits_wen,
  input  logic [511:0]   ds_rdata_data,
  output logic [511:0]   ds_wdata_data
  // END GENERATED(core_ports)
);

  // BEGIN GENERATED(core_wires) —— scripts/gen_l2_slice.py 生成
  // 核内 child 的输出线：golden 的 `_<inst>_io_<port>` 在这里叫 `<inst>_<port>`
  // -- sinkA
  logic           sinkA_prefetchReq_ready;
  logic           sinkA_task_valid;
  logic [8:0]     sinkA_task_bits_set;
  logic [30:0]    sinkA_task_bits_tag;
  logic [5:0]     sinkA_task_bits_off;
  logic [1:0]     sinkA_task_bits_alias;
  logic [43:0]    sinkA_task_bits_vaddr;
  logic           sinkA_task_bits_isKeyword;
  logic [3:0]     sinkA_task_bits_opcode;
  logic [2:0]     sinkA_task_bits_param;
  logic [2:0]     sinkA_task_bits_size;
  logic [6:0]     sinkA_task_bits_sourceId;
  logic           sinkA_task_bits_corrupt;
  logic           sinkA_task_bits_fromL2pft;
  logic           sinkA_task_bits_needHint;
  logic [4:0]     sinkA_task_bits_reqSource;
  // -- sinkC
  logic           sinkC_task_valid;
  logic [2:0]     sinkC_task_bits_channel;
  logic [2:0]     sinkC_task_bits_txChannel;
  logic [8:0]     sinkC_task_bits_set;
  logic [30:0]    sinkC_task_bits_tag;
  logic [5:0]     sinkC_task_bits_off;
  logic [1:0]     sinkC_task_bits_alias;
  logic [43:0]    sinkC_task_bits_vaddr;
  logic           sinkC_task_bits_isKeyword;
  logic [3:0]     sinkC_task_bits_opcode;
  logic [2:0]     sinkC_task_bits_param;
  logic [2:0]     sinkC_task_bits_size;
  logic [6:0]     sinkC_task_bits_sourceId;
  logic [1:0]     sinkC_task_bits_bufIdx;
  logic           sinkC_task_bits_needProbeAckData;
  logic           sinkC_task_bits_denied;
  logic           sinkC_task_bits_corrupt;
  logic           sinkC_task_bits_mshrTask;
  logic [7:0]     sinkC_task_bits_mshrId;
  logic           sinkC_task_bits_aliasTask;
  logic           sinkC_task_bits_useProbeData;
  logic           sinkC_task_bits_mshrRetry;
  logic           sinkC_task_bits_readProbeDataDown;
  logic           sinkC_task_bits_fromL2pft;
  logic           sinkC_task_bits_needHint;
  logic           sinkC_task_bits_dirty;
  logic [2:0]     sinkC_task_bits_way;
  logic           sinkC_task_bits_meta_dirty;
  logic [1:0]     sinkC_task_bits_meta_state;
  logic           sinkC_task_bits_meta_clients;
  logic [1:0]     sinkC_task_bits_meta_alias;
  logic           sinkC_task_bits_meta_prefetch;
  logic [2:0]     sinkC_task_bits_meta_prefetchSrc;
  logic           sinkC_task_bits_meta_accessed;
  logic           sinkC_task_bits_meta_tagErr;
  logic           sinkC_task_bits_meta_dataErr;
  logic           sinkC_task_bits_metaWen;
  logic           sinkC_task_bits_tagWen;
  logic           sinkC_task_bits_dsWen;
  logic [7:0]     sinkC_task_bits_wayMask;
  logic           sinkC_task_bits_replTask;
  logic           sinkC_task_bits_cmoTask;
  logic           sinkC_task_bits_cmoAll;
  logic [4:0]     sinkC_task_bits_reqSource;
  logic           sinkC_task_bits_mergeA;
  logic [5:0]     sinkC_task_bits_aMergeTask_off;
  logic [1:0]     sinkC_task_bits_aMergeTask_alias;
  logic [43:0]    sinkC_task_bits_aMergeTask_vaddr;
  logic           sinkC_task_bits_aMergeTask_isKeyword;
  logic [2:0]     sinkC_task_bits_aMergeTask_opcode;
  logic [2:0]     sinkC_task_bits_aMergeTask_param;
  logic [6:0]     sinkC_task_bits_aMergeTask_sourceId;
  logic           sinkC_task_bits_aMergeTask_meta_dirty;
  logic [1:0]     sinkC_task_bits_aMergeTask_meta_state;
  logic           sinkC_task_bits_aMergeTask_meta_clients;
  logic [1:0]     sinkC_task_bits_aMergeTask_meta_alias;
  logic           sinkC_task_bits_aMergeTask_meta_prefetch;
  logic [2:0]     sinkC_task_bits_aMergeTask_meta_prefetchSrc;
  logic           sinkC_task_bits_aMergeTask_meta_accessed;
  logic           sinkC_task_bits_aMergeTask_meta_tagErr;
  logic           sinkC_task_bits_aMergeTask_meta_dataErr;
  logic           sinkC_task_bits_snpHitRelease;
  logic           sinkC_task_bits_snpHitReleaseToInval;
  logic           sinkC_task_bits_snpHitReleaseToClean;
  logic           sinkC_task_bits_snpHitReleaseWithData;
  logic [7:0]     sinkC_task_bits_snpHitReleaseIdx;
  logic           sinkC_task_bits_snpHitReleaseMeta_dirty;
  logic [1:0]     sinkC_task_bits_snpHitReleaseMeta_state;
  logic           sinkC_task_bits_snpHitReleaseMeta_clients;
  logic [1:0]     sinkC_task_bits_snpHitReleaseMeta_alias;
  logic           sinkC_task_bits_snpHitReleaseMeta_prefetch;
  logic [2:0]     sinkC_task_bits_snpHitReleaseMeta_prefetchSrc;
  logic           sinkC_task_bits_snpHitReleaseMeta_accessed;
  logic           sinkC_task_bits_snpHitReleaseMeta_tagErr;
  logic           sinkC_task_bits_snpHitReleaseMeta_dataErr;
  logic [10:0]    sinkC_task_bits_tgtID;
  logic [10:0]    sinkC_task_bits_srcID;
  logic [11:0]    sinkC_task_bits_txnID;
  logic [10:0]    sinkC_task_bits_homeNID;
  logic [11:0]    sinkC_task_bits_dbID;
  logic [10:0]    sinkC_task_bits_fwdNID;
  logic [11:0]    sinkC_task_bits_fwdTxnID;
  logic [6:0]     sinkC_task_bits_chiOpcode;
  logic [2:0]     sinkC_task_bits_resp;
  logic [2:0]     sinkC_task_bits_fwdState;
  logic [3:0]     sinkC_task_bits_pCrdType;
  logic           sinkC_task_bits_retToSrc;
  logic           sinkC_task_bits_likelyshared;
  logic           sinkC_task_bits_expCompAck;
  logic           sinkC_task_bits_allowRetry;
  logic           sinkC_task_bits_memAttr_allocate;
  logic           sinkC_task_bits_memAttr_cacheable;
  logic           sinkC_task_bits_memAttr_device;
  logic           sinkC_task_bits_memAttr_ewa;
  logic           sinkC_task_bits_traceTag;
  logic           sinkC_resp_valid;
  logic [8:0]     sinkC_resp_set;
  logic [30:0]    sinkC_resp_tag;
  logic [2:0]     sinkC_resp_respInfo_opcode;
  logic [2:0]     sinkC_resp_respInfo_param;
  logic           sinkC_resp_respInfo_last;
  logic           sinkC_resp_respInfo_denied;
  logic           sinkC_resp_respInfo_corrupt;
  logic           sinkC_releaseBufWrite_valid;
  logic [511:0]   sinkC_releaseBufWrite_bits_data_data;
  logic [255:0]   sinkC_bufResp_data_0;
  logic [255:0]   sinkC_bufResp_data_1;
  logic           sinkC_refillBufWrite_valid;
  logic [7:0]     sinkC_refillBufWrite_bits_id;
  logic [511:0]   sinkC_refillBufWrite_bits_data_data;
  // -- grantBuf
  logic           grantBuf_toReqArb_blockSinkReqEntrance_blockA_s1;
  logic           grantBuf_toReqArb_blockSinkReqEntrance_blockB_s1;
  logic           grantBuf_toReqArb_blockSinkReqEntrance_blockC_s1;
  logic           grantBuf_toReqArb_blockMSHRReqEntrance;
  logic           grantBuf_grantStatus_0_valid;
  logic [8:0]     grantBuf_grantStatus_0_set;
  logic [30:0]    grantBuf_grantStatus_0_tag;
  logic           grantBuf_grantStatus_1_valid;
  logic [8:0]     grantBuf_grantStatus_1_set;
  logic [30:0]    grantBuf_grantStatus_1_tag;
  logic           grantBuf_grantStatus_2_valid;
  logic [8:0]     grantBuf_grantStatus_2_set;
  logic [30:0]    grantBuf_grantStatus_2_tag;
  logic           grantBuf_grantStatus_3_valid;
  logic [8:0]     grantBuf_grantStatus_3_set;
  logic [30:0]    grantBuf_grantStatus_3_tag;
  logic           grantBuf_grantStatus_4_valid;
  logic [8:0]     grantBuf_grantStatus_4_set;
  logic [30:0]    grantBuf_grantStatus_4_tag;
  logic           grantBuf_grantStatus_5_valid;
  logic [8:0]     grantBuf_grantStatus_5_set;
  logic [30:0]    grantBuf_grantStatus_5_tag;
  logic           grantBuf_grantStatus_6_valid;
  logic [8:0]     grantBuf_grantStatus_6_set;
  logic [30:0]    grantBuf_grantStatus_6_tag;
  logic           grantBuf_grantStatus_7_valid;
  logic [8:0]     grantBuf_grantStatus_7_set;
  logic [30:0]    grantBuf_grantStatus_7_tag;
  logic           grantBuf_grantStatus_8_valid;
  logic [8:0]     grantBuf_grantStatus_8_set;
  logic [30:0]    grantBuf_grantStatus_8_tag;
  logic           grantBuf_grantStatus_9_valid;
  logic [8:0]     grantBuf_grantStatus_9_set;
  logic [30:0]    grantBuf_grantStatus_9_tag;
  logic           grantBuf_grantStatus_10_valid;
  logic [8:0]     grantBuf_grantStatus_10_set;
  logic [30:0]    grantBuf_grantStatus_10_tag;
  logic           grantBuf_grantStatus_11_valid;
  logic [8:0]     grantBuf_grantStatus_11_set;
  logic [30:0]    grantBuf_grantStatus_11_tag;
  logic           grantBuf_grantStatus_12_valid;
  logic [8:0]     grantBuf_grantStatus_12_set;
  logic [30:0]    grantBuf_grantStatus_12_tag;
  logic           grantBuf_grantStatus_13_valid;
  logic [8:0]     grantBuf_grantStatus_13_set;
  logic [30:0]    grantBuf_grantStatus_13_tag;
  logic           grantBuf_grantStatus_14_valid;
  logic [8:0]     grantBuf_grantStatus_14_set;
  logic [30:0]    grantBuf_grantStatus_14_tag;
  logic           grantBuf_grantStatus_15_valid;
  logic [8:0]     grantBuf_grantStatus_15_set;
  logic [30:0]    grantBuf_grantStatus_15_tag;
  // -- txreq
  logic           txreq_mshrReq_ready;
  logic           txreq_toReqArb_blockMSHRReqEntrance;
  // -- txdat
  logic           txdat_in_ready;
  logic           txdat_toReqArb_blockMSHRReqEntrance;
  logic           txdat_toReqArb_blockSinkBReqEntrance;
  // -- txrsp
  logic           txrsp_mshrRsp_ready;
  logic           txrsp_toReqArb_blockMSHRReqEntrance;
  logic           txrsp_toReqArb_blockSinkBReqEntrance;
  // -- rxsnp
  logic           rxsnp_task_valid;
  logic [8:0]     rxsnp_task_bits_set;
  logic [30:0]    rxsnp_task_bits_tag;
  logic [5:0]     rxsnp_task_bits_off;
  logic           rxsnp_task_bits_snpHitRelease;
  logic           rxsnp_task_bits_snpHitReleaseToInval;
  logic           rxsnp_task_bits_snpHitReleaseToClean;
  logic           rxsnp_task_bits_snpHitReleaseWithData;
  logic [7:0]     rxsnp_task_bits_snpHitReleaseIdx;
  logic           rxsnp_task_bits_snpHitReleaseMeta_dirty;
  logic [1:0]     rxsnp_task_bits_snpHitReleaseMeta_state;
  logic           rxsnp_task_bits_snpHitReleaseMeta_clients;
  logic [1:0]     rxsnp_task_bits_snpHitReleaseMeta_alias;
  logic           rxsnp_task_bits_snpHitReleaseMeta_prefetch;
  logic [2:0]     rxsnp_task_bits_snpHitReleaseMeta_prefetchSrc;
  logic           rxsnp_task_bits_snpHitReleaseMeta_accessed;
  logic           rxsnp_task_bits_snpHitReleaseMeta_tagErr;
  logic           rxsnp_task_bits_snpHitReleaseMeta_dataErr;
  logic [10:0]    rxsnp_task_bits_srcID;
  logic [11:0]    rxsnp_task_bits_txnID;
  logic [10:0]    rxsnp_task_bits_fwdNID;
  logic [11:0]    rxsnp_task_bits_fwdTxnID;
  logic [6:0]     rxsnp_task_bits_chiOpcode;
  logic           rxsnp_task_bits_retToSrc;
  logic           rxsnp_task_bits_traceTag;
  // -- rxdat
  logic           rxdat_in_valid;
  logic [7:0]     rxdat_in_mshrId;
  logic           rxdat_in_respInfo_last;
  logic           rxdat_in_respInfo_corrupt;
  logic [6:0]     rxdat_in_respInfo_chiOpcode;
  logic [10:0]    rxdat_in_respInfo_homeNID;
  logic [11:0]    rxdat_in_respInfo_dbID;
  logic [2:0]     rxdat_in_respInfo_resp;
  logic [1:0]     rxdat_in_respInfo_respErr;
  logic           rxdat_in_respInfo_traceTag;
  logic           rxdat_refillBufWrite_valid;
  logic [7:0]     rxdat_refillBufWrite_bits_id;
  logic [511:0]   rxdat_refillBufWrite_bits_data_data;
  logic [1:0]     rxdat_refillBufWrite_bits_beatMask;
  // -- rxrsp
  logic           rxrsp_in_valid;
  logic [7:0]     rxrsp_in_mshrId;
  logic [6:0]     rxrsp_in_respInfo_chiOpcode;
  logic [10:0]    rxrsp_in_respInfo_srcID;
  logic [11:0]    rxrsp_in_respInfo_dbID;
  logic [2:0]     rxrsp_in_respInfo_resp;
  logic [3:0]     rxrsp_in_respInfo_pCrdType;
  logic [1:0]     rxrsp_in_respInfo_respErr;
  logic           rxrsp_in_respInfo_traceTag;
  // -- refillBuf
  logic [511:0]   refillBuf_resp_data_data;
  // -- releaseBuf
  logic [511:0]   releaseBuf_resp_data_data;
  // -- reqArb
  logic           reqArb_sinkA_ready;
  logic           reqArb_s1Entrance_valid;
  logic [8:0]     reqArb_s1Entrance_bits_set;
  logic           reqArb_sinkB_ready;
  logic           reqArb_sinkC_ready;
  logic           reqArb_mshrTask_ready;
  logic           reqArb_dirRead_s1_valid;
  logic [30:0]    reqArb_dirRead_s1_bits_tag;
  logic [8:0]     reqArb_dirRead_s1_bits_set;
  logic [7:0]     reqArb_dirRead_s1_bits_wayMask;
  logic [2:0]     reqArb_dirRead_s1_bits_replacerInfo_channel;
  logic [2:0]     reqArb_dirRead_s1_bits_replacerInfo_opcode;
  logic [4:0]     reqArb_dirRead_s1_bits_replacerInfo_reqSource;
  logic           reqArb_dirRead_s1_bits_replacerInfo_refill_prefetch;
  logic           reqArb_dirRead_s1_bits_refill;
  logic [7:0]     reqArb_dirRead_s1_bits_mshrId;
  logic           reqArb_dirRead_s1_bits_cmoAll;
  logic [2:0]     reqArb_dirRead_s1_bits_cmoWay;
  logic           reqArb_taskToPipe_s2_valid;
  logic [2:0]     reqArb_taskToPipe_s2_bits_channel;
  logic [2:0]     reqArb_taskToPipe_s2_bits_txChannel;
  logic [8:0]     reqArb_taskToPipe_s2_bits_set;
  logic [30:0]    reqArb_taskToPipe_s2_bits_tag;
  logic [5:0]     reqArb_taskToPipe_s2_bits_off;
  logic [1:0]     reqArb_taskToPipe_s2_bits_alias;
  logic [43:0]    reqArb_taskToPipe_s2_bits_vaddr;
  logic           reqArb_taskToPipe_s2_bits_isKeyword;
  logic [3:0]     reqArb_taskToPipe_s2_bits_opcode;
  logic [2:0]     reqArb_taskToPipe_s2_bits_param;
  logic [2:0]     reqArb_taskToPipe_s2_bits_size;
  logic [6:0]     reqArb_taskToPipe_s2_bits_sourceId;
  logic [1:0]     reqArb_taskToPipe_s2_bits_bufIdx;
  logic           reqArb_taskToPipe_s2_bits_needProbeAckData;
  logic           reqArb_taskToPipe_s2_bits_denied;
  logic           reqArb_taskToPipe_s2_bits_corrupt;
  logic           reqArb_taskToPipe_s2_bits_mshrTask;
  logic [7:0]     reqArb_taskToPipe_s2_bits_mshrId;
  logic           reqArb_taskToPipe_s2_bits_aliasTask;
  logic           reqArb_taskToPipe_s2_bits_useProbeData;
  logic           reqArb_taskToPipe_s2_bits_mshrRetry;
  logic           reqArb_taskToPipe_s2_bits_readProbeDataDown;
  logic           reqArb_taskToPipe_s2_bits_fromL2pft;
  logic           reqArb_taskToPipe_s2_bits_needHint;
  logic           reqArb_taskToPipe_s2_bits_dirty;
  logic [2:0]     reqArb_taskToPipe_s2_bits_way;
  logic           reqArb_taskToPipe_s2_bits_meta_dirty;
  logic [1:0]     reqArb_taskToPipe_s2_bits_meta_state;
  logic           reqArb_taskToPipe_s2_bits_meta_clients;
  logic [1:0]     reqArb_taskToPipe_s2_bits_meta_alias;
  logic           reqArb_taskToPipe_s2_bits_meta_prefetch;
  logic [2:0]     reqArb_taskToPipe_s2_bits_meta_prefetchSrc;
  logic           reqArb_taskToPipe_s2_bits_meta_accessed;
  logic           reqArb_taskToPipe_s2_bits_meta_tagErr;
  logic           reqArb_taskToPipe_s2_bits_meta_dataErr;
  logic           reqArb_taskToPipe_s2_bits_metaWen;
  logic           reqArb_taskToPipe_s2_bits_tagWen;
  logic           reqArb_taskToPipe_s2_bits_dsWen;
  logic [7:0]     reqArb_taskToPipe_s2_bits_wayMask;
  logic           reqArb_taskToPipe_s2_bits_replTask;
  logic           reqArb_taskToPipe_s2_bits_cmoTask;
  logic           reqArb_taskToPipe_s2_bits_cmoAll;
  logic [4:0]     reqArb_taskToPipe_s2_bits_reqSource;
  logic           reqArb_taskToPipe_s2_bits_mergeA;
  logic [5:0]     reqArb_taskToPipe_s2_bits_aMergeTask_off;
  logic [1:0]     reqArb_taskToPipe_s2_bits_aMergeTask_alias;
  logic [43:0]    reqArb_taskToPipe_s2_bits_aMergeTask_vaddr;
  logic           reqArb_taskToPipe_s2_bits_aMergeTask_isKeyword;
  logic [2:0]     reqArb_taskToPipe_s2_bits_aMergeTask_opcode;
  logic [2:0]     reqArb_taskToPipe_s2_bits_aMergeTask_param;
  logic [6:0]     reqArb_taskToPipe_s2_bits_aMergeTask_sourceId;
  logic           reqArb_taskToPipe_s2_bits_aMergeTask_meta_dirty;
  logic [1:0]     reqArb_taskToPipe_s2_bits_aMergeTask_meta_state;
  logic           reqArb_taskToPipe_s2_bits_aMergeTask_meta_clients;
  logic [1:0]     reqArb_taskToPipe_s2_bits_aMergeTask_meta_alias;
  logic           reqArb_taskToPipe_s2_bits_aMergeTask_meta_prefetch;
  logic [2:0]     reqArb_taskToPipe_s2_bits_aMergeTask_meta_prefetchSrc;
  logic           reqArb_taskToPipe_s2_bits_aMergeTask_meta_accessed;
  logic           reqArb_taskToPipe_s2_bits_aMergeTask_meta_tagErr;
  logic           reqArb_taskToPipe_s2_bits_aMergeTask_meta_dataErr;
  logic           reqArb_taskToPipe_s2_bits_snpHitRelease;
  logic           reqArb_taskToPipe_s2_bits_snpHitReleaseToInval;
  logic           reqArb_taskToPipe_s2_bits_snpHitReleaseToClean;
  logic           reqArb_taskToPipe_s2_bits_snpHitReleaseWithData;
  logic [7:0]     reqArb_taskToPipe_s2_bits_snpHitReleaseIdx;
  logic           reqArb_taskToPipe_s2_bits_snpHitReleaseMeta_dirty;
  logic [1:0]     reqArb_taskToPipe_s2_bits_snpHitReleaseMeta_state;
  logic           reqArb_taskToPipe_s2_bits_snpHitReleaseMeta_clients;
  logic [1:0]     reqArb_taskToPipe_s2_bits_snpHitReleaseMeta_alias;
  logic           reqArb_taskToPipe_s2_bits_snpHitReleaseMeta_prefetch;
  logic [2:0]     reqArb_taskToPipe_s2_bits_snpHitReleaseMeta_prefetchSrc;
  logic           reqArb_taskToPipe_s2_bits_snpHitReleaseMeta_accessed;
  logic           reqArb_taskToPipe_s2_bits_snpHitReleaseMeta_tagErr;
  logic           reqArb_taskToPipe_s2_bits_snpHitReleaseMeta_dataErr;
  logic [10:0]    reqArb_taskToPipe_s2_bits_tgtID;
  logic [10:0]    reqArb_taskToPipe_s2_bits_srcID;
  logic [11:0]    reqArb_taskToPipe_s2_bits_txnID;
  logic [10:0]    reqArb_taskToPipe_s2_bits_homeNID;
  logic [11:0]    reqArb_taskToPipe_s2_bits_dbID;
  logic [10:0]    reqArb_taskToPipe_s2_bits_fwdNID;
  logic [11:0]    reqArb_taskToPipe_s2_bits_fwdTxnID;
  logic [6:0]     reqArb_taskToPipe_s2_bits_chiOpcode;
  logic [2:0]     reqArb_taskToPipe_s2_bits_resp;
  logic [2:0]     reqArb_taskToPipe_s2_bits_fwdState;
  logic [3:0]     reqArb_taskToPipe_s2_bits_pCrdType;
  logic           reqArb_taskToPipe_s2_bits_retToSrc;
  logic           reqArb_taskToPipe_s2_bits_likelyshared;
  logic           reqArb_taskToPipe_s2_bits_expCompAck;
  logic           reqArb_taskToPipe_s2_bits_allowRetry;
  logic           reqArb_taskToPipe_s2_bits_memAttr_allocate;
  logic           reqArb_taskToPipe_s2_bits_memAttr_cacheable;
  logic           reqArb_taskToPipe_s2_bits_memAttr_device;
  logic           reqArb_taskToPipe_s2_bits_memAttr_ewa;
  logic           reqArb_taskToPipe_s2_bits_traceTag;
  logic           reqArb_taskInfo_s1_valid;
  logic [2:0]     reqArb_taskInfo_s1_bits_channel;
  logic           reqArb_taskInfo_s1_bits_isKeyword;
  logic [3:0]     reqArb_taskInfo_s1_bits_opcode;
  logic [6:0]     reqArb_taskInfo_s1_bits_sourceId;
  logic           reqArb_taskInfo_s1_bits_mshrTask;
  logic           reqArb_taskInfo_s1_bits_mergeA;
  logic           reqArb_taskInfo_s1_bits_aMergeTask_isKeyword;
  logic [2:0]     reqArb_taskInfo_s1_bits_aMergeTask_opcode;
  logic [6:0]     reqArb_taskInfo_s1_bits_aMergeTask_sourceId;
  logic           reqArb_refillBufRead_s2_valid;
  logic [7:0]     reqArb_refillBufRead_s2_bits_id;
  logic           reqArb_releaseBufRead_s2_valid;
  logic [7:0]     reqArb_releaseBufRead_s2_bits_id;
  logic [30:0]    reqArb_status_s1_tags_1;
  logic [8:0]     reqArb_status_s1_sets_0;
  logic [8:0]     reqArb_status_s1_sets_1;
  logic [8:0]     reqArb_status_s1_sets_2;
  logic [8:0]     reqArb_status_s1_sets_3;
  logic           reqArb_status_vec_1_valid;
  logic [2:0]     reqArb_status_vec_1_bits_channel;
  logic           reqArb_status_vec_toTX_1_valid;
  logic [2:0]     reqArb_status_vec_toTX_1_bits_channel;
  logic [2:0]     reqArb_status_vec_toTX_1_bits_txChannel;
  logic           reqArb_status_vec_toTX_1_bits_mshrTask;
  // -- mainPipe
  logic           mainPipe_toReqArb_blockG_s1;
  logic           mainPipe_toReqArb_blockB_s1;
  logic           mainPipe_toReqArb_blockC_s1;
  logic           mainPipe_toReqBuf_0;
  logic           mainPipe_toReqBuf_1;
  logic           mainPipe_status_vec_toD_0_valid;
  logic [2:0]     mainPipe_status_vec_toD_0_bits_channel;
  logic           mainPipe_status_vec_toD_1_valid;
  logic [2:0]     mainPipe_status_vec_toD_1_bits_channel;
  logic           mainPipe_status_vec_toD_2_valid;
  logic [2:0]     mainPipe_status_vec_toD_2_bits_channel;
  logic           mainPipe_status_vec_toTX_0_valid;
  logic [2:0]     mainPipe_status_vec_toTX_0_bits_channel;
  logic [2:0]     mainPipe_status_vec_toTX_0_bits_txChannel;
  logic           mainPipe_status_vec_toTX_0_bits_mshrTask;
  logic           mainPipe_status_vec_toTX_1_valid;
  logic [2:0]     mainPipe_status_vec_toTX_1_bits_channel;
  logic [2:0]     mainPipe_status_vec_toTX_1_bits_txChannel;
  logic           mainPipe_status_vec_toTX_1_bits_mshrTask;
  logic           mainPipe_status_vec_toTX_2_valid;
  logic [2:0]     mainPipe_status_vec_toTX_2_bits_channel;
  logic [2:0]     mainPipe_status_vec_toTX_2_bits_txChannel;
  logic           mainPipe_status_vec_toTX_2_bits_mshrTask;
  logic           mainPipe_toMSHRCtl_mshr_alloc_s3_valid;
  logic           mainPipe_toMSHRCtl_mshr_alloc_s3_bits_dirResult_hit;
  logic [30:0]    mainPipe_toMSHRCtl_mshr_alloc_s3_bits_dirResult_tag;
  logic [8:0]     mainPipe_toMSHRCtl_mshr_alloc_s3_bits_dirResult_set;
  logic [2:0]     mainPipe_toMSHRCtl_mshr_alloc_s3_bits_dirResult_way;
  logic           mainPipe_toMSHRCtl_mshr_alloc_s3_bits_dirResult_meta_dirty;
  logic [1:0]     mainPipe_toMSHRCtl_mshr_alloc_s3_bits_dirResult_meta_state;
  logic           mainPipe_toMSHRCtl_mshr_alloc_s3_bits_dirResult_meta_clients;
  logic [1:0]     mainPipe_toMSHRCtl_mshr_alloc_s3_bits_dirResult_meta_alias;
  logic           mainPipe_toMSHRCtl_mshr_alloc_s3_bits_dirResult_meta_prefetch;
  logic [2:0]     mainPipe_toMSHRCtl_mshr_alloc_s3_bits_dirResult_meta_prefetchSrc;
  logic           mainPipe_toMSHRCtl_mshr_alloc_s3_bits_dirResult_meta_accessed;
  logic           mainPipe_toMSHRCtl_mshr_alloc_s3_bits_dirResult_meta_tagErr;
  logic           mainPipe_toMSHRCtl_mshr_alloc_s3_bits_dirResult_meta_dataErr;
  logic           mainPipe_toMSHRCtl_mshr_alloc_s3_bits_dirResult_error;
  logic           mainPipe_toMSHRCtl_mshr_alloc_s3_bits_state_s_acquire;
  logic           mainPipe_toMSHRCtl_mshr_alloc_s3_bits_state_s_rprobe;
  logic           mainPipe_toMSHRCtl_mshr_alloc_s3_bits_state_s_pprobe;
  logic           mainPipe_toMSHRCtl_mshr_alloc_s3_bits_state_s_release;
  logic           mainPipe_toMSHRCtl_mshr_alloc_s3_bits_state_s_probeack;
  logic           mainPipe_toMSHRCtl_mshr_alloc_s3_bits_state_s_refill;
  logic           mainPipe_toMSHRCtl_mshr_alloc_s3_bits_state_s_cmoresp;
  logic           mainPipe_toMSHRCtl_mshr_alloc_s3_bits_state_w_rprobeackfirst;
  logic           mainPipe_toMSHRCtl_mshr_alloc_s3_bits_state_w_rprobeacklast;
  logic           mainPipe_toMSHRCtl_mshr_alloc_s3_bits_state_w_pprobeackfirst;
  logic           mainPipe_toMSHRCtl_mshr_alloc_s3_bits_state_w_pprobeacklast;
  logic           mainPipe_toMSHRCtl_mshr_alloc_s3_bits_state_w_grantfirst;
  logic           mainPipe_toMSHRCtl_mshr_alloc_s3_bits_state_w_grantlast;
  logic           mainPipe_toMSHRCtl_mshr_alloc_s3_bits_state_w_grant;
  logic           mainPipe_toMSHRCtl_mshr_alloc_s3_bits_state_w_releaseack;
  logic           mainPipe_toMSHRCtl_mshr_alloc_s3_bits_state_w_replResp;
  logic           mainPipe_toMSHRCtl_mshr_alloc_s3_bits_state_s_rcompack;
  logic           mainPipe_toMSHRCtl_mshr_alloc_s3_bits_state_s_dct;
  logic [2:0]     mainPipe_toMSHRCtl_mshr_alloc_s3_bits_task_channel;
  logic [8:0]     mainPipe_toMSHRCtl_mshr_alloc_s3_bits_task_set;
  logic [30:0]    mainPipe_toMSHRCtl_mshr_alloc_s3_bits_task_tag;
  logic [5:0]     mainPipe_toMSHRCtl_mshr_alloc_s3_bits_task_off;
  logic [1:0]     mainPipe_toMSHRCtl_mshr_alloc_s3_bits_task_alias;
  logic           mainPipe_toMSHRCtl_mshr_alloc_s3_bits_task_isKeyword;
  logic [3:0]     mainPipe_toMSHRCtl_mshr_alloc_s3_bits_task_opcode;
  logic [2:0]     mainPipe_toMSHRCtl_mshr_alloc_s3_bits_task_param;
  logic [6:0]     mainPipe_toMSHRCtl_mshr_alloc_s3_bits_task_sourceId;
  logic           mainPipe_toMSHRCtl_mshr_alloc_s3_bits_task_denied;
  logic           mainPipe_toMSHRCtl_mshr_alloc_s3_bits_task_corrupt;
  logic           mainPipe_toMSHRCtl_mshr_alloc_s3_bits_task_aliasTask;
  logic           mainPipe_toMSHRCtl_mshr_alloc_s3_bits_task_fromL2pft;
  logic [4:0]     mainPipe_toMSHRCtl_mshr_alloc_s3_bits_task_reqSource;
  logic           mainPipe_toMSHRCtl_mshr_alloc_s3_bits_task_snpHitRelease;
  logic           mainPipe_toMSHRCtl_mshr_alloc_s3_bits_task_snpHitReleaseToInval;
  logic           mainPipe_toMSHRCtl_mshr_alloc_s3_bits_task_snpHitReleaseToClean;
  logic           mainPipe_toMSHRCtl_mshr_alloc_s3_bits_task_snpHitReleaseWithData;
  logic [7:0]     mainPipe_toMSHRCtl_mshr_alloc_s3_bits_task_snpHitReleaseIdx;
  logic           mainPipe_toMSHRCtl_mshr_alloc_s3_bits_task_snpHitReleaseMeta_dirty;
  logic [1:0]     mainPipe_toMSHRCtl_mshr_alloc_s3_bits_task_snpHitReleaseMeta_state;
  logic           mainPipe_toMSHRCtl_mshr_alloc_s3_bits_task_snpHitReleaseMeta_clients;
  logic [1:0]     mainPipe_toMSHRCtl_mshr_alloc_s3_bits_task_snpHitReleaseMeta_alias;
  logic           mainPipe_toMSHRCtl_mshr_alloc_s3_bits_task_snpHitReleaseMeta_prefetch;
  logic [2:0]     mainPipe_toMSHRCtl_mshr_alloc_s3_bits_task_snpHitReleaseMeta_prefetchSrc;
  logic           mainPipe_toMSHRCtl_mshr_alloc_s3_bits_task_snpHitReleaseMeta_accessed;
  logic           mainPipe_toMSHRCtl_mshr_alloc_s3_bits_task_snpHitReleaseMeta_tagErr;
  logic           mainPipe_toMSHRCtl_mshr_alloc_s3_bits_task_snpHitReleaseMeta_dataErr;
  logic [10:0]    mainPipe_toMSHRCtl_mshr_alloc_s3_bits_task_srcID;
  logic [11:0]    mainPipe_toMSHRCtl_mshr_alloc_s3_bits_task_txnID;
  logic [10:0]    mainPipe_toMSHRCtl_mshr_alloc_s3_bits_task_fwdNID;
  logic [11:0]    mainPipe_toMSHRCtl_mshr_alloc_s3_bits_task_fwdTxnID;
  logic [6:0]     mainPipe_toMSHRCtl_mshr_alloc_s3_bits_task_chiOpcode;
  logic           mainPipe_toMSHRCtl_mshr_alloc_s3_bits_task_retToSrc;
  logic           mainPipe_toMSHRCtl_mshr_alloc_s3_bits_task_traceTag;
  logic           mainPipe_toDS_en_s3;
  logic           mainPipe_toDS_req_s3_valid;
  logic [2:0]     mainPipe_toDS_req_s3_bits_way;
  logic [8:0]     mainPipe_toDS_req_s3_bits_set;
  logic           mainPipe_toDS_req_s3_bits_wen;
  logic [511:0]   mainPipe_toDS_wdata_s3_data;
  logic           mainPipe_toSourceD_valid;
  logic [2:0]     mainPipe_toSourceD_bits_task_channel;
  logic [2:0]     mainPipe_toSourceD_bits_task_txChannel;
  logic [8:0]     mainPipe_toSourceD_bits_task_set;
  logic [30:0]    mainPipe_toSourceD_bits_task_tag;
  logic [5:0]     mainPipe_toSourceD_bits_task_off;
  logic [1:0]     mainPipe_toSourceD_bits_task_alias;
  logic [43:0]    mainPipe_toSourceD_bits_task_vaddr;
  logic           mainPipe_toSourceD_bits_task_isKeyword;
  logic [3:0]     mainPipe_toSourceD_bits_task_opcode;
  logic [2:0]     mainPipe_toSourceD_bits_task_param;
  logic [2:0]     mainPipe_toSourceD_bits_task_size;
  logic [6:0]     mainPipe_toSourceD_bits_task_sourceId;
  logic [1:0]     mainPipe_toSourceD_bits_task_bufIdx;
  logic           mainPipe_toSourceD_bits_task_needProbeAckData;
  logic           mainPipe_toSourceD_bits_task_denied;
  logic           mainPipe_toSourceD_bits_task_corrupt;
  logic           mainPipe_toSourceD_bits_task_mshrTask;
  logic [7:0]     mainPipe_toSourceD_bits_task_mshrId;
  logic           mainPipe_toSourceD_bits_task_aliasTask;
  logic           mainPipe_toSourceD_bits_task_useProbeData;
  logic           mainPipe_toSourceD_bits_task_mshrRetry;
  logic           mainPipe_toSourceD_bits_task_readProbeDataDown;
  logic           mainPipe_toSourceD_bits_task_fromL2pft;
  logic           mainPipe_toSourceD_bits_task_needHint;
  logic           mainPipe_toSourceD_bits_task_dirty;
  logic [2:0]     mainPipe_toSourceD_bits_task_way;
  logic           mainPipe_toSourceD_bits_task_meta_dirty;
  logic [1:0]     mainPipe_toSourceD_bits_task_meta_state;
  logic           mainPipe_toSourceD_bits_task_meta_clients;
  logic [1:0]     mainPipe_toSourceD_bits_task_meta_alias;
  logic           mainPipe_toSourceD_bits_task_meta_prefetch;
  logic [2:0]     mainPipe_toSourceD_bits_task_meta_prefetchSrc;
  logic           mainPipe_toSourceD_bits_task_meta_accessed;
  logic           mainPipe_toSourceD_bits_task_meta_tagErr;
  logic           mainPipe_toSourceD_bits_task_meta_dataErr;
  logic           mainPipe_toSourceD_bits_task_metaWen;
  logic           mainPipe_toSourceD_bits_task_tagWen;
  logic           mainPipe_toSourceD_bits_task_dsWen;
  logic [7:0]     mainPipe_toSourceD_bits_task_wayMask;
  logic           mainPipe_toSourceD_bits_task_replTask;
  logic           mainPipe_toSourceD_bits_task_cmoTask;
  logic           mainPipe_toSourceD_bits_task_cmoAll;
  logic [4:0]     mainPipe_toSourceD_bits_task_reqSource;
  logic           mainPipe_toSourceD_bits_task_mergeA;
  logic [5:0]     mainPipe_toSourceD_bits_task_aMergeTask_off;
  logic [1:0]     mainPipe_toSourceD_bits_task_aMergeTask_alias;
  logic [43:0]    mainPipe_toSourceD_bits_task_aMergeTask_vaddr;
  logic           mainPipe_toSourceD_bits_task_aMergeTask_isKeyword;
  logic [2:0]     mainPipe_toSourceD_bits_task_aMergeTask_opcode;
  logic [2:0]     mainPipe_toSourceD_bits_task_aMergeTask_param;
  logic [6:0]     mainPipe_toSourceD_bits_task_aMergeTask_sourceId;
  logic           mainPipe_toSourceD_bits_task_aMergeTask_meta_dirty;
  logic [1:0]     mainPipe_toSourceD_bits_task_aMergeTask_meta_state;
  logic           mainPipe_toSourceD_bits_task_aMergeTask_meta_clients;
  logic [1:0]     mainPipe_toSourceD_bits_task_aMergeTask_meta_alias;
  logic           mainPipe_toSourceD_bits_task_aMergeTask_meta_prefetch;
  logic [2:0]     mainPipe_toSourceD_bits_task_aMergeTask_meta_prefetchSrc;
  logic           mainPipe_toSourceD_bits_task_aMergeTask_meta_accessed;
  logic           mainPipe_toSourceD_bits_task_aMergeTask_meta_tagErr;
  logic           mainPipe_toSourceD_bits_task_aMergeTask_meta_dataErr;
  logic           mainPipe_toSourceD_bits_task_snpHitRelease;
  logic           mainPipe_toSourceD_bits_task_snpHitReleaseToInval;
  logic           mainPipe_toSourceD_bits_task_snpHitReleaseToClean;
  logic           mainPipe_toSourceD_bits_task_snpHitReleaseWithData;
  logic [7:0]     mainPipe_toSourceD_bits_task_snpHitReleaseIdx;
  logic           mainPipe_toSourceD_bits_task_snpHitReleaseMeta_dirty;
  logic [1:0]     mainPipe_toSourceD_bits_task_snpHitReleaseMeta_state;
  logic           mainPipe_toSourceD_bits_task_snpHitReleaseMeta_clients;
  logic [1:0]     mainPipe_toSourceD_bits_task_snpHitReleaseMeta_alias;
  logic           mainPipe_toSourceD_bits_task_snpHitReleaseMeta_prefetch;
  logic [2:0]     mainPipe_toSourceD_bits_task_snpHitReleaseMeta_prefetchSrc;
  logic           mainPipe_toSourceD_bits_task_snpHitReleaseMeta_accessed;
  logic           mainPipe_toSourceD_bits_task_snpHitReleaseMeta_tagErr;
  logic           mainPipe_toSourceD_bits_task_snpHitReleaseMeta_dataErr;
  logic [10:0]    mainPipe_toSourceD_bits_task_tgtID;
  logic [10:0]    mainPipe_toSourceD_bits_task_srcID;
  logic [11:0]    mainPipe_toSourceD_bits_task_txnID;
  logic [10:0]    mainPipe_toSourceD_bits_task_homeNID;
  logic [11:0]    mainPipe_toSourceD_bits_task_dbID;
  logic [10:0]    mainPipe_toSourceD_bits_task_fwdNID;
  logic [11:0]    mainPipe_toSourceD_bits_task_fwdTxnID;
  logic [6:0]     mainPipe_toSourceD_bits_task_chiOpcode;
  logic [2:0]     mainPipe_toSourceD_bits_task_resp;
  logic [2:0]     mainPipe_toSourceD_bits_task_fwdState;
  logic [3:0]     mainPipe_toSourceD_bits_task_pCrdType;
  logic           mainPipe_toSourceD_bits_task_retToSrc;
  logic           mainPipe_toSourceD_bits_task_likelyshared;
  logic           mainPipe_toSourceD_bits_task_expCompAck;
  logic           mainPipe_toSourceD_bits_task_allowRetry;
  logic           mainPipe_toSourceD_bits_task_memAttr_allocate;
  logic           mainPipe_toSourceD_bits_task_memAttr_cacheable;
  logic           mainPipe_toSourceD_bits_task_memAttr_device;
  logic           mainPipe_toSourceD_bits_task_memAttr_ewa;
  logic           mainPipe_toSourceD_bits_task_traceTag;
  logic [511:0]   mainPipe_toSourceD_bits_data_data;
  logic           mainPipe_toTXREQ_valid;
  logic [10:0]    mainPipe_toTXREQ_bits_tgtID;
  logic [10:0]    mainPipe_toTXREQ_bits_srcID;
  logic [11:0]    mainPipe_toTXREQ_bits_txnID;
  logic [6:0]     mainPipe_toTXREQ_bits_opcode;
  logic [47:0]    mainPipe_toTXREQ_bits_addr;
  logic           mainPipe_toTXREQ_bits_likelyshared;
  logic           mainPipe_toTXREQ_bits_allowRetry;
  logic [3:0]     mainPipe_toTXREQ_bits_pCrdType;
  logic           mainPipe_toTXREQ_bits_memAttr_allocate;
  logic           mainPipe_toTXREQ_bits_memAttr_cacheable;
  logic           mainPipe_toTXREQ_bits_memAttr_device;
  logic           mainPipe_toTXREQ_bits_memAttr_ewa;
  logic           mainPipe_toTXREQ_bits_expCompAck;
  logic           mainPipe_toTXRSP_valid;
  logic [2:0]     mainPipe_toTXRSP_bits_txChannel;
  logic           mainPipe_toTXRSP_bits_denied;
  logic [10:0]    mainPipe_toTXRSP_bits_tgtID;
  logic [10:0]    mainPipe_toTXRSP_bits_srcID;
  logic [11:0]    mainPipe_toTXRSP_bits_txnID;
  logic [11:0]    mainPipe_toTXRSP_bits_dbID;
  logic [6:0]     mainPipe_toTXRSP_bits_chiOpcode;
  logic [2:0]     mainPipe_toTXRSP_bits_resp;
  logic [2:0]     mainPipe_toTXRSP_bits_fwdState;
  logic [3:0]     mainPipe_toTXRSP_bits_pCrdType;
  logic           mainPipe_toTXRSP_bits_traceTag;
  logic           mainPipe_toTXDAT_valid;
  logic [2:0]     mainPipe_toTXDAT_bits_task_channel;
  logic [2:0]     mainPipe_toTXDAT_bits_task_txChannel;
  logic [8:0]     mainPipe_toTXDAT_bits_task_set;
  logic [30:0]    mainPipe_toTXDAT_bits_task_tag;
  logic [5:0]     mainPipe_toTXDAT_bits_task_off;
  logic [1:0]     mainPipe_toTXDAT_bits_task_alias;
  logic [43:0]    mainPipe_toTXDAT_bits_task_vaddr;
  logic           mainPipe_toTXDAT_bits_task_isKeyword;
  logic [3:0]     mainPipe_toTXDAT_bits_task_opcode;
  logic [2:0]     mainPipe_toTXDAT_bits_task_param;
  logic [2:0]     mainPipe_toTXDAT_bits_task_size;
  logic [6:0]     mainPipe_toTXDAT_bits_task_sourceId;
  logic [1:0]     mainPipe_toTXDAT_bits_task_bufIdx;
  logic           mainPipe_toTXDAT_bits_task_needProbeAckData;
  logic           mainPipe_toTXDAT_bits_task_denied;
  logic           mainPipe_toTXDAT_bits_task_corrupt;
  logic           mainPipe_toTXDAT_bits_task_mshrTask;
  logic [7:0]     mainPipe_toTXDAT_bits_task_mshrId;
  logic           mainPipe_toTXDAT_bits_task_aliasTask;
  logic           mainPipe_toTXDAT_bits_task_useProbeData;
  logic           mainPipe_toTXDAT_bits_task_mshrRetry;
  logic           mainPipe_toTXDAT_bits_task_readProbeDataDown;
  logic           mainPipe_toTXDAT_bits_task_fromL2pft;
  logic           mainPipe_toTXDAT_bits_task_needHint;
  logic           mainPipe_toTXDAT_bits_task_dirty;
  logic [2:0]     mainPipe_toTXDAT_bits_task_way;
  logic           mainPipe_toTXDAT_bits_task_meta_dirty;
  logic [1:0]     mainPipe_toTXDAT_bits_task_meta_state;
  logic           mainPipe_toTXDAT_bits_task_meta_clients;
  logic [1:0]     mainPipe_toTXDAT_bits_task_meta_alias;
  logic           mainPipe_toTXDAT_bits_task_meta_prefetch;
  logic [2:0]     mainPipe_toTXDAT_bits_task_meta_prefetchSrc;
  logic           mainPipe_toTXDAT_bits_task_meta_accessed;
  logic           mainPipe_toTXDAT_bits_task_meta_tagErr;
  logic           mainPipe_toTXDAT_bits_task_meta_dataErr;
  logic           mainPipe_toTXDAT_bits_task_metaWen;
  logic           mainPipe_toTXDAT_bits_task_tagWen;
  logic           mainPipe_toTXDAT_bits_task_dsWen;
  logic [7:0]     mainPipe_toTXDAT_bits_task_wayMask;
  logic           mainPipe_toTXDAT_bits_task_replTask;
  logic           mainPipe_toTXDAT_bits_task_cmoTask;
  logic           mainPipe_toTXDAT_bits_task_cmoAll;
  logic [4:0]     mainPipe_toTXDAT_bits_task_reqSource;
  logic           mainPipe_toTXDAT_bits_task_mergeA;
  logic [5:0]     mainPipe_toTXDAT_bits_task_aMergeTask_off;
  logic [1:0]     mainPipe_toTXDAT_bits_task_aMergeTask_alias;
  logic [43:0]    mainPipe_toTXDAT_bits_task_aMergeTask_vaddr;
  logic           mainPipe_toTXDAT_bits_task_aMergeTask_isKeyword;
  logic [2:0]     mainPipe_toTXDAT_bits_task_aMergeTask_opcode;
  logic [2:0]     mainPipe_toTXDAT_bits_task_aMergeTask_param;
  logic [6:0]     mainPipe_toTXDAT_bits_task_aMergeTask_sourceId;
  logic           mainPipe_toTXDAT_bits_task_aMergeTask_meta_dirty;
  logic [1:0]     mainPipe_toTXDAT_bits_task_aMergeTask_meta_state;
  logic           mainPipe_toTXDAT_bits_task_aMergeTask_meta_clients;
  logic [1:0]     mainPipe_toTXDAT_bits_task_aMergeTask_meta_alias;
  logic           mainPipe_toTXDAT_bits_task_aMergeTask_meta_prefetch;
  logic [2:0]     mainPipe_toTXDAT_bits_task_aMergeTask_meta_prefetchSrc;
  logic           mainPipe_toTXDAT_bits_task_aMergeTask_meta_accessed;
  logic           mainPipe_toTXDAT_bits_task_aMergeTask_meta_tagErr;
  logic           mainPipe_toTXDAT_bits_task_aMergeTask_meta_dataErr;
  logic           mainPipe_toTXDAT_bits_task_snpHitRelease;
  logic           mainPipe_toTXDAT_bits_task_snpHitReleaseToInval;
  logic           mainPipe_toTXDAT_bits_task_snpHitReleaseToClean;
  logic           mainPipe_toTXDAT_bits_task_snpHitReleaseWithData;
  logic [7:0]     mainPipe_toTXDAT_bits_task_snpHitReleaseIdx;
  logic           mainPipe_toTXDAT_bits_task_snpHitReleaseMeta_dirty;
  logic [1:0]     mainPipe_toTXDAT_bits_task_snpHitReleaseMeta_state;
  logic           mainPipe_toTXDAT_bits_task_snpHitReleaseMeta_clients;
  logic [1:0]     mainPipe_toTXDAT_bits_task_snpHitReleaseMeta_alias;
  logic           mainPipe_toTXDAT_bits_task_snpHitReleaseMeta_prefetch;
  logic [2:0]     mainPipe_toTXDAT_bits_task_snpHitReleaseMeta_prefetchSrc;
  logic           mainPipe_toTXDAT_bits_task_snpHitReleaseMeta_accessed;
  logic           mainPipe_toTXDAT_bits_task_snpHitReleaseMeta_tagErr;
  logic           mainPipe_toTXDAT_bits_task_snpHitReleaseMeta_dataErr;
  logic [10:0]    mainPipe_toTXDAT_bits_task_tgtID;
  logic [10:0]    mainPipe_toTXDAT_bits_task_srcID;
  logic [11:0]    mainPipe_toTXDAT_bits_task_txnID;
  logic [10:0]    mainPipe_toTXDAT_bits_task_homeNID;
  logic [11:0]    mainPipe_toTXDAT_bits_task_dbID;
  logic [10:0]    mainPipe_toTXDAT_bits_task_fwdNID;
  logic [11:0]    mainPipe_toTXDAT_bits_task_fwdTxnID;
  logic [6:0]     mainPipe_toTXDAT_bits_task_chiOpcode;
  logic [2:0]     mainPipe_toTXDAT_bits_task_resp;
  logic [2:0]     mainPipe_toTXDAT_bits_task_fwdState;
  logic [3:0]     mainPipe_toTXDAT_bits_task_pCrdType;
  logic           mainPipe_toTXDAT_bits_task_retToSrc;
  logic           mainPipe_toTXDAT_bits_task_likelyshared;
  logic           mainPipe_toTXDAT_bits_task_expCompAck;
  logic           mainPipe_toTXDAT_bits_task_allowRetry;
  logic           mainPipe_toTXDAT_bits_task_memAttr_allocate;
  logic           mainPipe_toTXDAT_bits_task_memAttr_cacheable;
  logic           mainPipe_toTXDAT_bits_task_memAttr_device;
  logic           mainPipe_toTXDAT_bits_task_memAttr_ewa;
  logic           mainPipe_toTXDAT_bits_task_traceTag;
  logic [511:0]   mainPipe_toTXDAT_bits_data_data;
  logic           mainPipe_metaWReq_valid;
  logic [8:0]     mainPipe_metaWReq_bits_set;
  logic [7:0]     mainPipe_metaWReq_bits_wayOH;
  logic           mainPipe_metaWReq_bits_wmeta_dirty;
  logic [1:0]     mainPipe_metaWReq_bits_wmeta_state;
  logic           mainPipe_metaWReq_bits_wmeta_clients;
  logic [1:0]     mainPipe_metaWReq_bits_wmeta_alias;
  logic           mainPipe_metaWReq_bits_wmeta_prefetch;
  logic [2:0]     mainPipe_metaWReq_bits_wmeta_prefetchSrc;
  logic           mainPipe_metaWReq_bits_wmeta_accessed;
  logic           mainPipe_metaWReq_bits_wmeta_tagErr;
  logic           mainPipe_metaWReq_bits_wmeta_dataErr;
  logic           mainPipe_tagWReq_valid;
  logic [8:0]     mainPipe_tagWReq_bits_set;
  logic [2:0]     mainPipe_tagWReq_bits_way;
  logic [30:0]    mainPipe_tagWReq_bits_wtag;
  logic           mainPipe_releaseBufWrite_valid;
  logic [7:0]     mainPipe_releaseBufWrite_bits_id;
  logic [511:0]   mainPipe_releaseBufWrite_bits_data_data;
  logic           mainPipe_dsResp_valid;
  logic [7:0]     mainPipe_dsResp_bits_mshrId;
  logic           mainPipe_dsResp_bits_dataError;
  logic [8:0]     mainPipe_nestedwb_set;
  logic [30:0]    mainPipe_nestedwb_tag;
  logic           mainPipe_nestedwb_c_set_dirty;
  logic           mainPipe_nestedwb_c_set_tip;
  logic           mainPipe_nestedwb_b_inv_dirty;
  logic           mainPipe_nestedwb_b_toB;
  logic           mainPipe_nestedwb_b_toN;
  logic           mainPipe_nestedwb_b_toClean;
  logic           mainPipe_nestedwb_denied;
  logic           mainPipe_nestedwb_corrupt;
  logic [511:0]   mainPipe_nestedwbData_data;
  logic           mainPipe_error_valid;
  logic           mainPipe_error_bits_valid;
  logic [45:0]    mainPipe_error_bits_address;
  logic [5:0]     mainPipe_perf_0_value;
  logic [5:0]     mainPipe_perf_1_value;
  logic [5:0]     mainPipe_perf_2_value;
  logic [5:0]     mainPipe_perf_3_value;
  logic [5:0]     mainPipe_perf_4_value;
  logic [5:0]     mainPipe_perf_5_value;
  logic [5:0]     mainPipe_perf_6_value;
  logic [5:0]     mainPipe_perf_7_value;
  logic [5:0]     mainPipe_perf_8_value;
  logic [5:0]     mainPipe_perf_9_value;
  logic [5:0]     mainPipe_perf_10_value;
  logic [5:0]     mainPipe_perf_11_value;
  logic [5:0]     mainPipe_perf_12_value;
  // -- reqBuf
  logic           reqBuf_in_ready;
  logic           reqBuf_out_valid;
  logic [2:0]     reqBuf_out_bits_channel;
  logic [2:0]     reqBuf_out_bits_txChannel;
  logic [8:0]     reqBuf_out_bits_set;
  logic [30:0]    reqBuf_out_bits_tag;
  logic [5:0]     reqBuf_out_bits_off;
  logic [1:0]     reqBuf_out_bits_alias;
  logic [43:0]    reqBuf_out_bits_vaddr;
  logic           reqBuf_out_bits_isKeyword;
  logic [3:0]     reqBuf_out_bits_opcode;
  logic [2:0]     reqBuf_out_bits_param;
  logic [2:0]     reqBuf_out_bits_size;
  logic [6:0]     reqBuf_out_bits_sourceId;
  logic [1:0]     reqBuf_out_bits_bufIdx;
  logic           reqBuf_out_bits_needProbeAckData;
  logic           reqBuf_out_bits_denied;
  logic           reqBuf_out_bits_corrupt;
  logic           reqBuf_out_bits_mshrTask;
  logic [7:0]     reqBuf_out_bits_mshrId;
  logic           reqBuf_out_bits_aliasTask;
  logic           reqBuf_out_bits_useProbeData;
  logic           reqBuf_out_bits_mshrRetry;
  logic           reqBuf_out_bits_readProbeDataDown;
  logic           reqBuf_out_bits_fromL2pft;
  logic           reqBuf_out_bits_needHint;
  logic           reqBuf_out_bits_dirty;
  logic [2:0]     reqBuf_out_bits_way;
  logic           reqBuf_out_bits_meta_dirty;
  logic [1:0]     reqBuf_out_bits_meta_state;
  logic           reqBuf_out_bits_meta_clients;
  logic [1:0]     reqBuf_out_bits_meta_alias;
  logic           reqBuf_out_bits_meta_prefetch;
  logic [2:0]     reqBuf_out_bits_meta_prefetchSrc;
  logic           reqBuf_out_bits_meta_accessed;
  logic           reqBuf_out_bits_meta_tagErr;
  logic           reqBuf_out_bits_meta_dataErr;
  logic           reqBuf_out_bits_metaWen;
  logic           reqBuf_out_bits_tagWen;
  logic           reqBuf_out_bits_dsWen;
  logic           reqBuf_out_bits_replTask;
  logic           reqBuf_out_bits_cmoTask;
  logic           reqBuf_out_bits_cmoAll;
  logic [4:0]     reqBuf_out_bits_reqSource;
  logic           reqBuf_out_bits_mergeA;
  logic [5:0]     reqBuf_out_bits_aMergeTask_off;
  logic [1:0]     reqBuf_out_bits_aMergeTask_alias;
  logic [43:0]    reqBuf_out_bits_aMergeTask_vaddr;
  logic           reqBuf_out_bits_aMergeTask_isKeyword;
  logic [2:0]     reqBuf_out_bits_aMergeTask_opcode;
  logic [2:0]     reqBuf_out_bits_aMergeTask_param;
  logic [6:0]     reqBuf_out_bits_aMergeTask_sourceId;
  logic           reqBuf_out_bits_aMergeTask_meta_dirty;
  logic [1:0]     reqBuf_out_bits_aMergeTask_meta_state;
  logic           reqBuf_out_bits_aMergeTask_meta_clients;
  logic [1:0]     reqBuf_out_bits_aMergeTask_meta_alias;
  logic           reqBuf_out_bits_aMergeTask_meta_prefetch;
  logic [2:0]     reqBuf_out_bits_aMergeTask_meta_prefetchSrc;
  logic           reqBuf_out_bits_aMergeTask_meta_accessed;
  logic           reqBuf_out_bits_aMergeTask_meta_tagErr;
  logic           reqBuf_out_bits_aMergeTask_meta_dataErr;
  logic           reqBuf_out_bits_snpHitRelease;
  logic           reqBuf_out_bits_snpHitReleaseToInval;
  logic           reqBuf_out_bits_snpHitReleaseToClean;
  logic           reqBuf_out_bits_snpHitReleaseWithData;
  logic [7:0]     reqBuf_out_bits_snpHitReleaseIdx;
  logic           reqBuf_out_bits_snpHitReleaseMeta_dirty;
  logic [1:0]     reqBuf_out_bits_snpHitReleaseMeta_state;
  logic           reqBuf_out_bits_snpHitReleaseMeta_clients;
  logic [1:0]     reqBuf_out_bits_snpHitReleaseMeta_alias;
  logic           reqBuf_out_bits_snpHitReleaseMeta_prefetch;
  logic [2:0]     reqBuf_out_bits_snpHitReleaseMeta_prefetchSrc;
  logic           reqBuf_out_bits_snpHitReleaseMeta_accessed;
  logic           reqBuf_out_bits_snpHitReleaseMeta_tagErr;
  logic           reqBuf_out_bits_snpHitReleaseMeta_dataErr;
  logic [10:0]    reqBuf_out_bits_tgtID;
  logic [10:0]    reqBuf_out_bits_srcID;
  logic [11:0]    reqBuf_out_bits_txnID;
  logic [10:0]    reqBuf_out_bits_homeNID;
  logic [11:0]    reqBuf_out_bits_dbID;
  logic [10:0]    reqBuf_out_bits_fwdNID;
  logic [11:0]    reqBuf_out_bits_fwdTxnID;
  logic [6:0]     reqBuf_out_bits_chiOpcode;
  logic [2:0]     reqBuf_out_bits_resp;
  logic [2:0]     reqBuf_out_bits_fwdState;
  logic [3:0]     reqBuf_out_bits_pCrdType;
  logic           reqBuf_out_bits_retToSrc;
  logic           reqBuf_out_bits_likelyshared;
  logic           reqBuf_out_bits_expCompAck;
  logic           reqBuf_out_bits_allowRetry;
  logic           reqBuf_out_bits_memAttr_allocate;
  logic           reqBuf_out_bits_memAttr_cacheable;
  logic           reqBuf_out_bits_memAttr_device;
  logic           reqBuf_out_bits_memAttr_ewa;
  logic           reqBuf_out_bits_traceTag;
  logic           reqBuf_aMergeTask_valid;
  logic [7:0]     reqBuf_aMergeTask_bits_id;
  logic [5:0]     reqBuf_aMergeTask_bits_task_off;
  logic [1:0]     reqBuf_aMergeTask_bits_task_alias;
  logic [43:0]    reqBuf_aMergeTask_bits_task_vaddr;
  logic           reqBuf_aMergeTask_bits_task_isKeyword;
  logic [3:0]     reqBuf_aMergeTask_bits_task_opcode;
  logic [2:0]     reqBuf_aMergeTask_bits_task_param;
  logic [6:0]     reqBuf_aMergeTask_bits_task_sourceId;
  logic [30:0]    reqBuf_ATag;
  logic [8:0]     reqBuf_ASet;
  logic           reqBuf_hasMergeA;
  // -- mshrCtl
  logic           mshrCtl_toReqArb_blockA_s1;
  logic           mshrCtl_toReqArb_blockB_s1;
  logic [7:0]     mshrCtl_toMainPipe_mshr_alloc_ptr;
  logic           mshrCtl_mshrTask_valid;
  logic [2:0]     mshrCtl_mshrTask_bits_channel;
  logic [2:0]     mshrCtl_mshrTask_bits_txChannel;
  logic [8:0]     mshrCtl_mshrTask_bits_set;
  logic [30:0]    mshrCtl_mshrTask_bits_tag;
  logic [5:0]     mshrCtl_mshrTask_bits_off;
  logic [1:0]     mshrCtl_mshrTask_bits_alias;
  logic           mshrCtl_mshrTask_bits_isKeyword;
  logic [3:0]     mshrCtl_mshrTask_bits_opcode;
  logic [2:0]     mshrCtl_mshrTask_bits_param;
  logic [2:0]     mshrCtl_mshrTask_bits_size;
  logic [6:0]     mshrCtl_mshrTask_bits_sourceId;
  logic           mshrCtl_mshrTask_bits_denied;
  logic           mshrCtl_mshrTask_bits_corrupt;
  logic           mshrCtl_mshrTask_bits_mshrTask;
  logic [7:0]     mshrCtl_mshrTask_bits_mshrId;
  logic           mshrCtl_mshrTask_bits_aliasTask;
  logic           mshrCtl_mshrTask_bits_useProbeData;
  logic           mshrCtl_mshrTask_bits_mshrRetry;
  logic           mshrCtl_mshrTask_bits_readProbeDataDown;
  logic           mshrCtl_mshrTask_bits_fromL2pft;
  logic           mshrCtl_mshrTask_bits_dirty;
  logic [2:0]     mshrCtl_mshrTask_bits_way;
  logic           mshrCtl_mshrTask_bits_meta_dirty;
  logic [1:0]     mshrCtl_mshrTask_bits_meta_state;
  logic           mshrCtl_mshrTask_bits_meta_clients;
  logic [1:0]     mshrCtl_mshrTask_bits_meta_alias;
  logic           mshrCtl_mshrTask_bits_meta_prefetch;
  logic [2:0]     mshrCtl_mshrTask_bits_meta_prefetchSrc;
  logic           mshrCtl_mshrTask_bits_meta_accessed;
  logic           mshrCtl_mshrTask_bits_meta_tagErr;
  logic           mshrCtl_mshrTask_bits_meta_dataErr;
  logic           mshrCtl_mshrTask_bits_metaWen;
  logic           mshrCtl_mshrTask_bits_tagWen;
  logic           mshrCtl_mshrTask_bits_dsWen;
  logic           mshrCtl_mshrTask_bits_replTask;
  logic           mshrCtl_mshrTask_bits_cmoTask;
  logic [4:0]     mshrCtl_mshrTask_bits_reqSource;
  logic           mshrCtl_mshrTask_bits_mergeA;
  logic [5:0]     mshrCtl_mshrTask_bits_aMergeTask_off;
  logic [1:0]     mshrCtl_mshrTask_bits_aMergeTask_alias;
  logic [43:0]    mshrCtl_mshrTask_bits_aMergeTask_vaddr;
  logic           mshrCtl_mshrTask_bits_aMergeTask_isKeyword;
  logic [2:0]     mshrCtl_mshrTask_bits_aMergeTask_opcode;
  logic [2:0]     mshrCtl_mshrTask_bits_aMergeTask_param;
  logic [6:0]     mshrCtl_mshrTask_bits_aMergeTask_sourceId;
  logic           mshrCtl_mshrTask_bits_aMergeTask_meta_dirty;
  logic [1:0]     mshrCtl_mshrTask_bits_aMergeTask_meta_state;
  logic           mshrCtl_mshrTask_bits_aMergeTask_meta_clients;
  logic [1:0]     mshrCtl_mshrTask_bits_aMergeTask_meta_alias;
  logic           mshrCtl_mshrTask_bits_aMergeTask_meta_accessed;
  logic           mshrCtl_mshrTask_bits_snpHitRelease;
  logic           mshrCtl_mshrTask_bits_snpHitReleaseToInval;
  logic           mshrCtl_mshrTask_bits_snpHitReleaseToClean;
  logic           mshrCtl_mshrTask_bits_snpHitReleaseWithData;
  logic [7:0]     mshrCtl_mshrTask_bits_snpHitReleaseIdx;
  logic           mshrCtl_mshrTask_bits_snpHitReleaseMeta_dirty;
  logic [1:0]     mshrCtl_mshrTask_bits_snpHitReleaseMeta_state;
  logic           mshrCtl_mshrTask_bits_snpHitReleaseMeta_clients;
  logic [1:0]     mshrCtl_mshrTask_bits_snpHitReleaseMeta_alias;
  logic           mshrCtl_mshrTask_bits_snpHitReleaseMeta_prefetch;
  logic [2:0]     mshrCtl_mshrTask_bits_snpHitReleaseMeta_prefetchSrc;
  logic           mshrCtl_mshrTask_bits_snpHitReleaseMeta_accessed;
  logic           mshrCtl_mshrTask_bits_snpHitReleaseMeta_tagErr;
  logic           mshrCtl_mshrTask_bits_snpHitReleaseMeta_dataErr;
  logic [10:0]    mshrCtl_mshrTask_bits_tgtID;
  logic [11:0]    mshrCtl_mshrTask_bits_txnID;
  logic [10:0]    mshrCtl_mshrTask_bits_homeNID;
  logic [11:0]    mshrCtl_mshrTask_bits_dbID;
  logic [6:0]     mshrCtl_mshrTask_bits_chiOpcode;
  logic [2:0]     mshrCtl_mshrTask_bits_resp;
  logic [2:0]     mshrCtl_mshrTask_bits_fwdState;
  logic           mshrCtl_mshrTask_bits_retToSrc;
  logic           mshrCtl_mshrTask_bits_likelyshared;
  logic           mshrCtl_mshrTask_bits_expCompAck;
  logic           mshrCtl_mshrTask_bits_allowRetry;
  logic           mshrCtl_mshrTask_bits_memAttr_allocate;
  logic           mshrCtl_mshrTask_bits_memAttr_cacheable;
  logic           mshrCtl_mshrTask_bits_memAttr_ewa;
  logic           mshrCtl_mshrTask_bits_traceTag;
  logic           mshrCtl_toTXREQ_valid;
  logic [3:0]     mshrCtl_toTXREQ_bits_qos;
  logic [10:0]    mshrCtl_toTXREQ_bits_tgtID;
  logic [11:0]    mshrCtl_toTXREQ_bits_txnID;
  logic [6:0]     mshrCtl_toTXREQ_bits_opcode;
  logic [2:0]     mshrCtl_toTXREQ_bits_size;
  logic [47:0]    mshrCtl_toTXREQ_bits_addr;
  logic           mshrCtl_toTXREQ_bits_likelyshared;
  logic           mshrCtl_toTXREQ_bits_allowRetry;
  logic [3:0]     mshrCtl_toTXREQ_bits_pCrdType;
  logic           mshrCtl_toTXREQ_bits_memAttr_allocate;
  logic           mshrCtl_toTXREQ_bits_memAttr_cacheable;
  logic           mshrCtl_toTXREQ_bits_memAttr_ewa;
  logic           mshrCtl_toTXREQ_bits_snpAttr;
  logic           mshrCtl_toTXREQ_bits_expCompAck;
  logic           mshrCtl_toTXRSP_valid;
  logic [10:0]    mshrCtl_toTXRSP_bits_tgtID;
  logic [11:0]    mshrCtl_toTXRSP_bits_txnID;
  logic [4:0]     mshrCtl_toTXRSP_bits_opcode;
  logic           mshrCtl_toTXRSP_bits_traceTag;
  logic [7:0]     mshrCtl_releaseBufWriteId;
  logic           mshrCtl_nestedwbDataId_valid;
  logic [7:0]     mshrCtl_nestedwbDataId_bits;
  logic           mshrCtl_msInfo_0_valid;
  logic [2:0]     mshrCtl_msInfo_0_bits_channel;
  logic [8:0]     mshrCtl_msInfo_0_bits_set;
  logic [2:0]     mshrCtl_msInfo_0_bits_way;
  logic [30:0]    mshrCtl_msInfo_0_bits_reqTag;
  logic           mshrCtl_msInfo_0_bits_willFree;
  logic           mshrCtl_msInfo_0_bits_aliasTask;
  logic           mshrCtl_msInfo_0_bits_needRelease;
  logic           mshrCtl_msInfo_0_bits_blockRefill;
  logic           mshrCtl_msInfo_0_bits_meta_dirty;
  logic [1:0]     mshrCtl_msInfo_0_bits_meta_state;
  logic           mshrCtl_msInfo_0_bits_meta_clients;
  logic [1:0]     mshrCtl_msInfo_0_bits_meta_alias;
  logic           mshrCtl_msInfo_0_bits_meta_prefetch;
  logic [2:0]     mshrCtl_msInfo_0_bits_meta_prefetchSrc;
  logic           mshrCtl_msInfo_0_bits_meta_accessed;
  logic           mshrCtl_msInfo_0_bits_meta_tagErr;
  logic           mshrCtl_msInfo_0_bits_meta_dataErr;
  logic [30:0]    mshrCtl_msInfo_0_bits_metaTag;
  logic           mshrCtl_msInfo_0_bits_dirHit;
  logic           mshrCtl_msInfo_0_bits_isAcqOrPrefetch;
  logic           mshrCtl_msInfo_0_bits_isPrefetch;
  logic [2:0]     mshrCtl_msInfo_0_bits_param;
  logic           mshrCtl_msInfo_0_bits_mergeA;
  logic           mshrCtl_msInfo_0_bits_w_grantfirst;
  logic           mshrCtl_msInfo_0_bits_s_release;
  logic           mshrCtl_msInfo_0_bits_s_refill;
  logic           mshrCtl_msInfo_0_bits_s_cmoresp;
  logic           mshrCtl_msInfo_0_bits_s_cmometaw;
  logic           mshrCtl_msInfo_0_bits_w_releaseack;
  logic           mshrCtl_msInfo_0_bits_w_replResp;
  logic           mshrCtl_msInfo_0_bits_w_rprobeacklast;
  logic           mshrCtl_msInfo_0_bits_replaceData;
  logic           mshrCtl_msInfo_0_bits_releaseToClean;
  logic           mshrCtl_msInfo_1_valid;
  logic [2:0]     mshrCtl_msInfo_1_bits_channel;
  logic [8:0]     mshrCtl_msInfo_1_bits_set;
  logic [2:0]     mshrCtl_msInfo_1_bits_way;
  logic [30:0]    mshrCtl_msInfo_1_bits_reqTag;
  logic           mshrCtl_msInfo_1_bits_willFree;
  logic           mshrCtl_msInfo_1_bits_aliasTask;
  logic           mshrCtl_msInfo_1_bits_needRelease;
  logic           mshrCtl_msInfo_1_bits_blockRefill;
  logic           mshrCtl_msInfo_1_bits_meta_dirty;
  logic [1:0]     mshrCtl_msInfo_1_bits_meta_state;
  logic           mshrCtl_msInfo_1_bits_meta_clients;
  logic [1:0]     mshrCtl_msInfo_1_bits_meta_alias;
  logic           mshrCtl_msInfo_1_bits_meta_prefetch;
  logic [2:0]     mshrCtl_msInfo_1_bits_meta_prefetchSrc;
  logic           mshrCtl_msInfo_1_bits_meta_accessed;
  logic           mshrCtl_msInfo_1_bits_meta_tagErr;
  logic           mshrCtl_msInfo_1_bits_meta_dataErr;
  logic [30:0]    mshrCtl_msInfo_1_bits_metaTag;
  logic           mshrCtl_msInfo_1_bits_dirHit;
  logic           mshrCtl_msInfo_1_bits_isAcqOrPrefetch;
  logic           mshrCtl_msInfo_1_bits_isPrefetch;
  logic [2:0]     mshrCtl_msInfo_1_bits_param;
  logic           mshrCtl_msInfo_1_bits_mergeA;
  logic           mshrCtl_msInfo_1_bits_w_grantfirst;
  logic           mshrCtl_msInfo_1_bits_s_release;
  logic           mshrCtl_msInfo_1_bits_s_refill;
  logic           mshrCtl_msInfo_1_bits_s_cmoresp;
  logic           mshrCtl_msInfo_1_bits_s_cmometaw;
  logic           mshrCtl_msInfo_1_bits_w_releaseack;
  logic           mshrCtl_msInfo_1_bits_w_replResp;
  logic           mshrCtl_msInfo_1_bits_w_rprobeacklast;
  logic           mshrCtl_msInfo_1_bits_replaceData;
  logic           mshrCtl_msInfo_1_bits_releaseToClean;
  logic           mshrCtl_msInfo_2_valid;
  logic [2:0]     mshrCtl_msInfo_2_bits_channel;
  logic [8:0]     mshrCtl_msInfo_2_bits_set;
  logic [2:0]     mshrCtl_msInfo_2_bits_way;
  logic [30:0]    mshrCtl_msInfo_2_bits_reqTag;
  logic           mshrCtl_msInfo_2_bits_willFree;
  logic           mshrCtl_msInfo_2_bits_aliasTask;
  logic           mshrCtl_msInfo_2_bits_needRelease;
  logic           mshrCtl_msInfo_2_bits_blockRefill;
  logic           mshrCtl_msInfo_2_bits_meta_dirty;
  logic [1:0]     mshrCtl_msInfo_2_bits_meta_state;
  logic           mshrCtl_msInfo_2_bits_meta_clients;
  logic [1:0]     mshrCtl_msInfo_2_bits_meta_alias;
  logic           mshrCtl_msInfo_2_bits_meta_prefetch;
  logic [2:0]     mshrCtl_msInfo_2_bits_meta_prefetchSrc;
  logic           mshrCtl_msInfo_2_bits_meta_accessed;
  logic           mshrCtl_msInfo_2_bits_meta_tagErr;
  logic           mshrCtl_msInfo_2_bits_meta_dataErr;
  logic [30:0]    mshrCtl_msInfo_2_bits_metaTag;
  logic           mshrCtl_msInfo_2_bits_dirHit;
  logic           mshrCtl_msInfo_2_bits_isAcqOrPrefetch;
  logic           mshrCtl_msInfo_2_bits_isPrefetch;
  logic [2:0]     mshrCtl_msInfo_2_bits_param;
  logic           mshrCtl_msInfo_2_bits_mergeA;
  logic           mshrCtl_msInfo_2_bits_w_grantfirst;
  logic           mshrCtl_msInfo_2_bits_s_release;
  logic           mshrCtl_msInfo_2_bits_s_refill;
  logic           mshrCtl_msInfo_2_bits_s_cmoresp;
  logic           mshrCtl_msInfo_2_bits_s_cmometaw;
  logic           mshrCtl_msInfo_2_bits_w_releaseack;
  logic           mshrCtl_msInfo_2_bits_w_replResp;
  logic           mshrCtl_msInfo_2_bits_w_rprobeacklast;
  logic           mshrCtl_msInfo_2_bits_replaceData;
  logic           mshrCtl_msInfo_2_bits_releaseToClean;
  logic           mshrCtl_msInfo_3_valid;
  logic [2:0]     mshrCtl_msInfo_3_bits_channel;
  logic [8:0]     mshrCtl_msInfo_3_bits_set;
  logic [2:0]     mshrCtl_msInfo_3_bits_way;
  logic [30:0]    mshrCtl_msInfo_3_bits_reqTag;
  logic           mshrCtl_msInfo_3_bits_willFree;
  logic           mshrCtl_msInfo_3_bits_aliasTask;
  logic           mshrCtl_msInfo_3_bits_needRelease;
  logic           mshrCtl_msInfo_3_bits_blockRefill;
  logic           mshrCtl_msInfo_3_bits_meta_dirty;
  logic [1:0]     mshrCtl_msInfo_3_bits_meta_state;
  logic           mshrCtl_msInfo_3_bits_meta_clients;
  logic [1:0]     mshrCtl_msInfo_3_bits_meta_alias;
  logic           mshrCtl_msInfo_3_bits_meta_prefetch;
  logic [2:0]     mshrCtl_msInfo_3_bits_meta_prefetchSrc;
  logic           mshrCtl_msInfo_3_bits_meta_accessed;
  logic           mshrCtl_msInfo_3_bits_meta_tagErr;
  logic           mshrCtl_msInfo_3_bits_meta_dataErr;
  logic [30:0]    mshrCtl_msInfo_3_bits_metaTag;
  logic           mshrCtl_msInfo_3_bits_dirHit;
  logic           mshrCtl_msInfo_3_bits_isAcqOrPrefetch;
  logic           mshrCtl_msInfo_3_bits_isPrefetch;
  logic [2:0]     mshrCtl_msInfo_3_bits_param;
  logic           mshrCtl_msInfo_3_bits_mergeA;
  logic           mshrCtl_msInfo_3_bits_w_grantfirst;
  logic           mshrCtl_msInfo_3_bits_s_release;
  logic           mshrCtl_msInfo_3_bits_s_refill;
  logic           mshrCtl_msInfo_3_bits_s_cmoresp;
  logic           mshrCtl_msInfo_3_bits_s_cmometaw;
  logic           mshrCtl_msInfo_3_bits_w_releaseack;
  logic           mshrCtl_msInfo_3_bits_w_replResp;
  logic           mshrCtl_msInfo_3_bits_w_rprobeacklast;
  logic           mshrCtl_msInfo_3_bits_replaceData;
  logic           mshrCtl_msInfo_3_bits_releaseToClean;
  logic           mshrCtl_msInfo_4_valid;
  logic [2:0]     mshrCtl_msInfo_4_bits_channel;
  logic [8:0]     mshrCtl_msInfo_4_bits_set;
  logic [2:0]     mshrCtl_msInfo_4_bits_way;
  logic [30:0]    mshrCtl_msInfo_4_bits_reqTag;
  logic           mshrCtl_msInfo_4_bits_willFree;
  logic           mshrCtl_msInfo_4_bits_aliasTask;
  logic           mshrCtl_msInfo_4_bits_needRelease;
  logic           mshrCtl_msInfo_4_bits_blockRefill;
  logic           mshrCtl_msInfo_4_bits_meta_dirty;
  logic [1:0]     mshrCtl_msInfo_4_bits_meta_state;
  logic           mshrCtl_msInfo_4_bits_meta_clients;
  logic [1:0]     mshrCtl_msInfo_4_bits_meta_alias;
  logic           mshrCtl_msInfo_4_bits_meta_prefetch;
  logic [2:0]     mshrCtl_msInfo_4_bits_meta_prefetchSrc;
  logic           mshrCtl_msInfo_4_bits_meta_accessed;
  logic           mshrCtl_msInfo_4_bits_meta_tagErr;
  logic           mshrCtl_msInfo_4_bits_meta_dataErr;
  logic [30:0]    mshrCtl_msInfo_4_bits_metaTag;
  logic           mshrCtl_msInfo_4_bits_dirHit;
  logic           mshrCtl_msInfo_4_bits_isAcqOrPrefetch;
  logic           mshrCtl_msInfo_4_bits_isPrefetch;
  logic [2:0]     mshrCtl_msInfo_4_bits_param;
  logic           mshrCtl_msInfo_4_bits_mergeA;
  logic           mshrCtl_msInfo_4_bits_w_grantfirst;
  logic           mshrCtl_msInfo_4_bits_s_release;
  logic           mshrCtl_msInfo_4_bits_s_refill;
  logic           mshrCtl_msInfo_4_bits_s_cmoresp;
  logic           mshrCtl_msInfo_4_bits_s_cmometaw;
  logic           mshrCtl_msInfo_4_bits_w_releaseack;
  logic           mshrCtl_msInfo_4_bits_w_replResp;
  logic           mshrCtl_msInfo_4_bits_w_rprobeacklast;
  logic           mshrCtl_msInfo_4_bits_replaceData;
  logic           mshrCtl_msInfo_4_bits_releaseToClean;
  logic           mshrCtl_msInfo_5_valid;
  logic [2:0]     mshrCtl_msInfo_5_bits_channel;
  logic [8:0]     mshrCtl_msInfo_5_bits_set;
  logic [2:0]     mshrCtl_msInfo_5_bits_way;
  logic [30:0]    mshrCtl_msInfo_5_bits_reqTag;
  logic           mshrCtl_msInfo_5_bits_willFree;
  logic           mshrCtl_msInfo_5_bits_aliasTask;
  logic           mshrCtl_msInfo_5_bits_needRelease;
  logic           mshrCtl_msInfo_5_bits_blockRefill;
  logic           mshrCtl_msInfo_5_bits_meta_dirty;
  logic [1:0]     mshrCtl_msInfo_5_bits_meta_state;
  logic           mshrCtl_msInfo_5_bits_meta_clients;
  logic [1:0]     mshrCtl_msInfo_5_bits_meta_alias;
  logic           mshrCtl_msInfo_5_bits_meta_prefetch;
  logic [2:0]     mshrCtl_msInfo_5_bits_meta_prefetchSrc;
  logic           mshrCtl_msInfo_5_bits_meta_accessed;
  logic           mshrCtl_msInfo_5_bits_meta_tagErr;
  logic           mshrCtl_msInfo_5_bits_meta_dataErr;
  logic [30:0]    mshrCtl_msInfo_5_bits_metaTag;
  logic           mshrCtl_msInfo_5_bits_dirHit;
  logic           mshrCtl_msInfo_5_bits_isAcqOrPrefetch;
  logic           mshrCtl_msInfo_5_bits_isPrefetch;
  logic [2:0]     mshrCtl_msInfo_5_bits_param;
  logic           mshrCtl_msInfo_5_bits_mergeA;
  logic           mshrCtl_msInfo_5_bits_w_grantfirst;
  logic           mshrCtl_msInfo_5_bits_s_release;
  logic           mshrCtl_msInfo_5_bits_s_refill;
  logic           mshrCtl_msInfo_5_bits_s_cmoresp;
  logic           mshrCtl_msInfo_5_bits_s_cmometaw;
  logic           mshrCtl_msInfo_5_bits_w_releaseack;
  logic           mshrCtl_msInfo_5_bits_w_replResp;
  logic           mshrCtl_msInfo_5_bits_w_rprobeacklast;
  logic           mshrCtl_msInfo_5_bits_replaceData;
  logic           mshrCtl_msInfo_5_bits_releaseToClean;
  logic           mshrCtl_msInfo_6_valid;
  logic [2:0]     mshrCtl_msInfo_6_bits_channel;
  logic [8:0]     mshrCtl_msInfo_6_bits_set;
  logic [2:0]     mshrCtl_msInfo_6_bits_way;
  logic [30:0]    mshrCtl_msInfo_6_bits_reqTag;
  logic           mshrCtl_msInfo_6_bits_willFree;
  logic           mshrCtl_msInfo_6_bits_aliasTask;
  logic           mshrCtl_msInfo_6_bits_needRelease;
  logic           mshrCtl_msInfo_6_bits_blockRefill;
  logic           mshrCtl_msInfo_6_bits_meta_dirty;
  logic [1:0]     mshrCtl_msInfo_6_bits_meta_state;
  logic           mshrCtl_msInfo_6_bits_meta_clients;
  logic [1:0]     mshrCtl_msInfo_6_bits_meta_alias;
  logic           mshrCtl_msInfo_6_bits_meta_prefetch;
  logic [2:0]     mshrCtl_msInfo_6_bits_meta_prefetchSrc;
  logic           mshrCtl_msInfo_6_bits_meta_accessed;
  logic           mshrCtl_msInfo_6_bits_meta_tagErr;
  logic           mshrCtl_msInfo_6_bits_meta_dataErr;
  logic [30:0]    mshrCtl_msInfo_6_bits_metaTag;
  logic           mshrCtl_msInfo_6_bits_dirHit;
  logic           mshrCtl_msInfo_6_bits_isAcqOrPrefetch;
  logic           mshrCtl_msInfo_6_bits_isPrefetch;
  logic [2:0]     mshrCtl_msInfo_6_bits_param;
  logic           mshrCtl_msInfo_6_bits_mergeA;
  logic           mshrCtl_msInfo_6_bits_w_grantfirst;
  logic           mshrCtl_msInfo_6_bits_s_release;
  logic           mshrCtl_msInfo_6_bits_s_refill;
  logic           mshrCtl_msInfo_6_bits_s_cmoresp;
  logic           mshrCtl_msInfo_6_bits_s_cmometaw;
  logic           mshrCtl_msInfo_6_bits_w_releaseack;
  logic           mshrCtl_msInfo_6_bits_w_replResp;
  logic           mshrCtl_msInfo_6_bits_w_rprobeacklast;
  logic           mshrCtl_msInfo_6_bits_replaceData;
  logic           mshrCtl_msInfo_6_bits_releaseToClean;
  logic           mshrCtl_msInfo_7_valid;
  logic [2:0]     mshrCtl_msInfo_7_bits_channel;
  logic [8:0]     mshrCtl_msInfo_7_bits_set;
  logic [2:0]     mshrCtl_msInfo_7_bits_way;
  logic [30:0]    mshrCtl_msInfo_7_bits_reqTag;
  logic           mshrCtl_msInfo_7_bits_willFree;
  logic           mshrCtl_msInfo_7_bits_aliasTask;
  logic           mshrCtl_msInfo_7_bits_needRelease;
  logic           mshrCtl_msInfo_7_bits_blockRefill;
  logic           mshrCtl_msInfo_7_bits_meta_dirty;
  logic [1:0]     mshrCtl_msInfo_7_bits_meta_state;
  logic           mshrCtl_msInfo_7_bits_meta_clients;
  logic [1:0]     mshrCtl_msInfo_7_bits_meta_alias;
  logic           mshrCtl_msInfo_7_bits_meta_prefetch;
  logic [2:0]     mshrCtl_msInfo_7_bits_meta_prefetchSrc;
  logic           mshrCtl_msInfo_7_bits_meta_accessed;
  logic           mshrCtl_msInfo_7_bits_meta_tagErr;
  logic           mshrCtl_msInfo_7_bits_meta_dataErr;
  logic [30:0]    mshrCtl_msInfo_7_bits_metaTag;
  logic           mshrCtl_msInfo_7_bits_dirHit;
  logic           mshrCtl_msInfo_7_bits_isAcqOrPrefetch;
  logic           mshrCtl_msInfo_7_bits_isPrefetch;
  logic [2:0]     mshrCtl_msInfo_7_bits_param;
  logic           mshrCtl_msInfo_7_bits_mergeA;
  logic           mshrCtl_msInfo_7_bits_w_grantfirst;
  logic           mshrCtl_msInfo_7_bits_s_release;
  logic           mshrCtl_msInfo_7_bits_s_refill;
  logic           mshrCtl_msInfo_7_bits_s_cmoresp;
  logic           mshrCtl_msInfo_7_bits_s_cmometaw;
  logic           mshrCtl_msInfo_7_bits_w_releaseack;
  logic           mshrCtl_msInfo_7_bits_w_replResp;
  logic           mshrCtl_msInfo_7_bits_w_rprobeacklast;
  logic           mshrCtl_msInfo_7_bits_replaceData;
  logic           mshrCtl_msInfo_7_bits_releaseToClean;
  logic           mshrCtl_msInfo_8_valid;
  logic [2:0]     mshrCtl_msInfo_8_bits_channel;
  logic [8:0]     mshrCtl_msInfo_8_bits_set;
  logic [2:0]     mshrCtl_msInfo_8_bits_way;
  logic [30:0]    mshrCtl_msInfo_8_bits_reqTag;
  logic           mshrCtl_msInfo_8_bits_willFree;
  logic           mshrCtl_msInfo_8_bits_aliasTask;
  logic           mshrCtl_msInfo_8_bits_needRelease;
  logic           mshrCtl_msInfo_8_bits_blockRefill;
  logic           mshrCtl_msInfo_8_bits_meta_dirty;
  logic [1:0]     mshrCtl_msInfo_8_bits_meta_state;
  logic           mshrCtl_msInfo_8_bits_meta_clients;
  logic [1:0]     mshrCtl_msInfo_8_bits_meta_alias;
  logic           mshrCtl_msInfo_8_bits_meta_prefetch;
  logic [2:0]     mshrCtl_msInfo_8_bits_meta_prefetchSrc;
  logic           mshrCtl_msInfo_8_bits_meta_accessed;
  logic           mshrCtl_msInfo_8_bits_meta_tagErr;
  logic           mshrCtl_msInfo_8_bits_meta_dataErr;
  logic [30:0]    mshrCtl_msInfo_8_bits_metaTag;
  logic           mshrCtl_msInfo_8_bits_dirHit;
  logic           mshrCtl_msInfo_8_bits_isAcqOrPrefetch;
  logic           mshrCtl_msInfo_8_bits_isPrefetch;
  logic [2:0]     mshrCtl_msInfo_8_bits_param;
  logic           mshrCtl_msInfo_8_bits_mergeA;
  logic           mshrCtl_msInfo_8_bits_w_grantfirst;
  logic           mshrCtl_msInfo_8_bits_s_release;
  logic           mshrCtl_msInfo_8_bits_s_refill;
  logic           mshrCtl_msInfo_8_bits_s_cmoresp;
  logic           mshrCtl_msInfo_8_bits_s_cmometaw;
  logic           mshrCtl_msInfo_8_bits_w_releaseack;
  logic           mshrCtl_msInfo_8_bits_w_replResp;
  logic           mshrCtl_msInfo_8_bits_w_rprobeacklast;
  logic           mshrCtl_msInfo_8_bits_replaceData;
  logic           mshrCtl_msInfo_8_bits_releaseToClean;
  logic           mshrCtl_msInfo_9_valid;
  logic [2:0]     mshrCtl_msInfo_9_bits_channel;
  logic [8:0]     mshrCtl_msInfo_9_bits_set;
  logic [2:0]     mshrCtl_msInfo_9_bits_way;
  logic [30:0]    mshrCtl_msInfo_9_bits_reqTag;
  logic           mshrCtl_msInfo_9_bits_willFree;
  logic           mshrCtl_msInfo_9_bits_aliasTask;
  logic           mshrCtl_msInfo_9_bits_needRelease;
  logic           mshrCtl_msInfo_9_bits_blockRefill;
  logic           mshrCtl_msInfo_9_bits_meta_dirty;
  logic [1:0]     mshrCtl_msInfo_9_bits_meta_state;
  logic           mshrCtl_msInfo_9_bits_meta_clients;
  logic [1:0]     mshrCtl_msInfo_9_bits_meta_alias;
  logic           mshrCtl_msInfo_9_bits_meta_prefetch;
  logic [2:0]     mshrCtl_msInfo_9_bits_meta_prefetchSrc;
  logic           mshrCtl_msInfo_9_bits_meta_accessed;
  logic           mshrCtl_msInfo_9_bits_meta_tagErr;
  logic           mshrCtl_msInfo_9_bits_meta_dataErr;
  logic [30:0]    mshrCtl_msInfo_9_bits_metaTag;
  logic           mshrCtl_msInfo_9_bits_dirHit;
  logic           mshrCtl_msInfo_9_bits_isAcqOrPrefetch;
  logic           mshrCtl_msInfo_9_bits_isPrefetch;
  logic [2:0]     mshrCtl_msInfo_9_bits_param;
  logic           mshrCtl_msInfo_9_bits_mergeA;
  logic           mshrCtl_msInfo_9_bits_w_grantfirst;
  logic           mshrCtl_msInfo_9_bits_s_release;
  logic           mshrCtl_msInfo_9_bits_s_refill;
  logic           mshrCtl_msInfo_9_bits_s_cmoresp;
  logic           mshrCtl_msInfo_9_bits_s_cmometaw;
  logic           mshrCtl_msInfo_9_bits_w_releaseack;
  logic           mshrCtl_msInfo_9_bits_w_replResp;
  logic           mshrCtl_msInfo_9_bits_w_rprobeacklast;
  logic           mshrCtl_msInfo_9_bits_replaceData;
  logic           mshrCtl_msInfo_9_bits_releaseToClean;
  logic           mshrCtl_msInfo_10_valid;
  logic [2:0]     mshrCtl_msInfo_10_bits_channel;
  logic [8:0]     mshrCtl_msInfo_10_bits_set;
  logic [2:0]     mshrCtl_msInfo_10_bits_way;
  logic [30:0]    mshrCtl_msInfo_10_bits_reqTag;
  logic           mshrCtl_msInfo_10_bits_willFree;
  logic           mshrCtl_msInfo_10_bits_aliasTask;
  logic           mshrCtl_msInfo_10_bits_needRelease;
  logic           mshrCtl_msInfo_10_bits_blockRefill;
  logic           mshrCtl_msInfo_10_bits_meta_dirty;
  logic [1:0]     mshrCtl_msInfo_10_bits_meta_state;
  logic           mshrCtl_msInfo_10_bits_meta_clients;
  logic [1:0]     mshrCtl_msInfo_10_bits_meta_alias;
  logic           mshrCtl_msInfo_10_bits_meta_prefetch;
  logic [2:0]     mshrCtl_msInfo_10_bits_meta_prefetchSrc;
  logic           mshrCtl_msInfo_10_bits_meta_accessed;
  logic           mshrCtl_msInfo_10_bits_meta_tagErr;
  logic           mshrCtl_msInfo_10_bits_meta_dataErr;
  logic [30:0]    mshrCtl_msInfo_10_bits_metaTag;
  logic           mshrCtl_msInfo_10_bits_dirHit;
  logic           mshrCtl_msInfo_10_bits_isAcqOrPrefetch;
  logic           mshrCtl_msInfo_10_bits_isPrefetch;
  logic [2:0]     mshrCtl_msInfo_10_bits_param;
  logic           mshrCtl_msInfo_10_bits_mergeA;
  logic           mshrCtl_msInfo_10_bits_w_grantfirst;
  logic           mshrCtl_msInfo_10_bits_s_release;
  logic           mshrCtl_msInfo_10_bits_s_refill;
  logic           mshrCtl_msInfo_10_bits_s_cmoresp;
  logic           mshrCtl_msInfo_10_bits_s_cmometaw;
  logic           mshrCtl_msInfo_10_bits_w_releaseack;
  logic           mshrCtl_msInfo_10_bits_w_replResp;
  logic           mshrCtl_msInfo_10_bits_w_rprobeacklast;
  logic           mshrCtl_msInfo_10_bits_replaceData;
  logic           mshrCtl_msInfo_10_bits_releaseToClean;
  logic           mshrCtl_msInfo_11_valid;
  logic [2:0]     mshrCtl_msInfo_11_bits_channel;
  logic [8:0]     mshrCtl_msInfo_11_bits_set;
  logic [2:0]     mshrCtl_msInfo_11_bits_way;
  logic [30:0]    mshrCtl_msInfo_11_bits_reqTag;
  logic           mshrCtl_msInfo_11_bits_willFree;
  logic           mshrCtl_msInfo_11_bits_aliasTask;
  logic           mshrCtl_msInfo_11_bits_needRelease;
  logic           mshrCtl_msInfo_11_bits_blockRefill;
  logic           mshrCtl_msInfo_11_bits_meta_dirty;
  logic [1:0]     mshrCtl_msInfo_11_bits_meta_state;
  logic           mshrCtl_msInfo_11_bits_meta_clients;
  logic [1:0]     mshrCtl_msInfo_11_bits_meta_alias;
  logic           mshrCtl_msInfo_11_bits_meta_prefetch;
  logic [2:0]     mshrCtl_msInfo_11_bits_meta_prefetchSrc;
  logic           mshrCtl_msInfo_11_bits_meta_accessed;
  logic           mshrCtl_msInfo_11_bits_meta_tagErr;
  logic           mshrCtl_msInfo_11_bits_meta_dataErr;
  logic [30:0]    mshrCtl_msInfo_11_bits_metaTag;
  logic           mshrCtl_msInfo_11_bits_dirHit;
  logic           mshrCtl_msInfo_11_bits_isAcqOrPrefetch;
  logic           mshrCtl_msInfo_11_bits_isPrefetch;
  logic [2:0]     mshrCtl_msInfo_11_bits_param;
  logic           mshrCtl_msInfo_11_bits_mergeA;
  logic           mshrCtl_msInfo_11_bits_w_grantfirst;
  logic           mshrCtl_msInfo_11_bits_s_release;
  logic           mshrCtl_msInfo_11_bits_s_refill;
  logic           mshrCtl_msInfo_11_bits_s_cmoresp;
  logic           mshrCtl_msInfo_11_bits_s_cmometaw;
  logic           mshrCtl_msInfo_11_bits_w_releaseack;
  logic           mshrCtl_msInfo_11_bits_w_replResp;
  logic           mshrCtl_msInfo_11_bits_w_rprobeacklast;
  logic           mshrCtl_msInfo_11_bits_replaceData;
  logic           mshrCtl_msInfo_11_bits_releaseToClean;
  logic           mshrCtl_msInfo_12_valid;
  logic [2:0]     mshrCtl_msInfo_12_bits_channel;
  logic [8:0]     mshrCtl_msInfo_12_bits_set;
  logic [2:0]     mshrCtl_msInfo_12_bits_way;
  logic [30:0]    mshrCtl_msInfo_12_bits_reqTag;
  logic           mshrCtl_msInfo_12_bits_willFree;
  logic           mshrCtl_msInfo_12_bits_aliasTask;
  logic           mshrCtl_msInfo_12_bits_needRelease;
  logic           mshrCtl_msInfo_12_bits_blockRefill;
  logic           mshrCtl_msInfo_12_bits_meta_dirty;
  logic [1:0]     mshrCtl_msInfo_12_bits_meta_state;
  logic           mshrCtl_msInfo_12_bits_meta_clients;
  logic [1:0]     mshrCtl_msInfo_12_bits_meta_alias;
  logic           mshrCtl_msInfo_12_bits_meta_prefetch;
  logic [2:0]     mshrCtl_msInfo_12_bits_meta_prefetchSrc;
  logic           mshrCtl_msInfo_12_bits_meta_accessed;
  logic           mshrCtl_msInfo_12_bits_meta_tagErr;
  logic           mshrCtl_msInfo_12_bits_meta_dataErr;
  logic [30:0]    mshrCtl_msInfo_12_bits_metaTag;
  logic           mshrCtl_msInfo_12_bits_dirHit;
  logic           mshrCtl_msInfo_12_bits_isAcqOrPrefetch;
  logic           mshrCtl_msInfo_12_bits_isPrefetch;
  logic [2:0]     mshrCtl_msInfo_12_bits_param;
  logic           mshrCtl_msInfo_12_bits_mergeA;
  logic           mshrCtl_msInfo_12_bits_w_grantfirst;
  logic           mshrCtl_msInfo_12_bits_s_release;
  logic           mshrCtl_msInfo_12_bits_s_refill;
  logic           mshrCtl_msInfo_12_bits_s_cmoresp;
  logic           mshrCtl_msInfo_12_bits_s_cmometaw;
  logic           mshrCtl_msInfo_12_bits_w_releaseack;
  logic           mshrCtl_msInfo_12_bits_w_replResp;
  logic           mshrCtl_msInfo_12_bits_w_rprobeacklast;
  logic           mshrCtl_msInfo_12_bits_replaceData;
  logic           mshrCtl_msInfo_12_bits_releaseToClean;
  logic           mshrCtl_msInfo_13_valid;
  logic [2:0]     mshrCtl_msInfo_13_bits_channel;
  logic [8:0]     mshrCtl_msInfo_13_bits_set;
  logic [2:0]     mshrCtl_msInfo_13_bits_way;
  logic [30:0]    mshrCtl_msInfo_13_bits_reqTag;
  logic           mshrCtl_msInfo_13_bits_willFree;
  logic           mshrCtl_msInfo_13_bits_aliasTask;
  logic           mshrCtl_msInfo_13_bits_needRelease;
  logic           mshrCtl_msInfo_13_bits_blockRefill;
  logic           mshrCtl_msInfo_13_bits_meta_dirty;
  logic [1:0]     mshrCtl_msInfo_13_bits_meta_state;
  logic           mshrCtl_msInfo_13_bits_meta_clients;
  logic [1:0]     mshrCtl_msInfo_13_bits_meta_alias;
  logic           mshrCtl_msInfo_13_bits_meta_prefetch;
  logic [2:0]     mshrCtl_msInfo_13_bits_meta_prefetchSrc;
  logic           mshrCtl_msInfo_13_bits_meta_accessed;
  logic           mshrCtl_msInfo_13_bits_meta_tagErr;
  logic           mshrCtl_msInfo_13_bits_meta_dataErr;
  logic [30:0]    mshrCtl_msInfo_13_bits_metaTag;
  logic           mshrCtl_msInfo_13_bits_dirHit;
  logic           mshrCtl_msInfo_13_bits_isAcqOrPrefetch;
  logic           mshrCtl_msInfo_13_bits_isPrefetch;
  logic [2:0]     mshrCtl_msInfo_13_bits_param;
  logic           mshrCtl_msInfo_13_bits_mergeA;
  logic           mshrCtl_msInfo_13_bits_w_grantfirst;
  logic           mshrCtl_msInfo_13_bits_s_release;
  logic           mshrCtl_msInfo_13_bits_s_refill;
  logic           mshrCtl_msInfo_13_bits_s_cmoresp;
  logic           mshrCtl_msInfo_13_bits_s_cmometaw;
  logic           mshrCtl_msInfo_13_bits_w_releaseack;
  logic           mshrCtl_msInfo_13_bits_w_replResp;
  logic           mshrCtl_msInfo_13_bits_w_rprobeacklast;
  logic           mshrCtl_msInfo_13_bits_replaceData;
  logic           mshrCtl_msInfo_13_bits_releaseToClean;
  logic           mshrCtl_msInfo_14_valid;
  logic [2:0]     mshrCtl_msInfo_14_bits_channel;
  logic [8:0]     mshrCtl_msInfo_14_bits_set;
  logic [2:0]     mshrCtl_msInfo_14_bits_way;
  logic [30:0]    mshrCtl_msInfo_14_bits_reqTag;
  logic           mshrCtl_msInfo_14_bits_willFree;
  logic           mshrCtl_msInfo_14_bits_aliasTask;
  logic           mshrCtl_msInfo_14_bits_needRelease;
  logic           mshrCtl_msInfo_14_bits_blockRefill;
  logic           mshrCtl_msInfo_14_bits_meta_dirty;
  logic [1:0]     mshrCtl_msInfo_14_bits_meta_state;
  logic           mshrCtl_msInfo_14_bits_meta_clients;
  logic [1:0]     mshrCtl_msInfo_14_bits_meta_alias;
  logic           mshrCtl_msInfo_14_bits_meta_prefetch;
  logic [2:0]     mshrCtl_msInfo_14_bits_meta_prefetchSrc;
  logic           mshrCtl_msInfo_14_bits_meta_accessed;
  logic           mshrCtl_msInfo_14_bits_meta_tagErr;
  logic           mshrCtl_msInfo_14_bits_meta_dataErr;
  logic [30:0]    mshrCtl_msInfo_14_bits_metaTag;
  logic           mshrCtl_msInfo_14_bits_dirHit;
  logic           mshrCtl_msInfo_14_bits_isAcqOrPrefetch;
  logic           mshrCtl_msInfo_14_bits_isPrefetch;
  logic [2:0]     mshrCtl_msInfo_14_bits_param;
  logic           mshrCtl_msInfo_14_bits_mergeA;
  logic           mshrCtl_msInfo_14_bits_w_grantfirst;
  logic           mshrCtl_msInfo_14_bits_s_release;
  logic           mshrCtl_msInfo_14_bits_s_refill;
  logic           mshrCtl_msInfo_14_bits_s_cmoresp;
  logic           mshrCtl_msInfo_14_bits_s_cmometaw;
  logic           mshrCtl_msInfo_14_bits_w_releaseack;
  logic           mshrCtl_msInfo_14_bits_w_replResp;
  logic           mshrCtl_msInfo_14_bits_w_rprobeacklast;
  logic           mshrCtl_msInfo_14_bits_replaceData;
  logic           mshrCtl_msInfo_14_bits_releaseToClean;
  logic           mshrCtl_msInfo_15_valid;
  logic [2:0]     mshrCtl_msInfo_15_bits_channel;
  logic [8:0]     mshrCtl_msInfo_15_bits_set;
  logic [2:0]     mshrCtl_msInfo_15_bits_way;
  logic [30:0]    mshrCtl_msInfo_15_bits_reqTag;
  logic           mshrCtl_msInfo_15_bits_willFree;
  logic           mshrCtl_msInfo_15_bits_aliasTask;
  logic           mshrCtl_msInfo_15_bits_needRelease;
  logic           mshrCtl_msInfo_15_bits_blockRefill;
  logic           mshrCtl_msInfo_15_bits_meta_dirty;
  logic [1:0]     mshrCtl_msInfo_15_bits_meta_state;
  logic           mshrCtl_msInfo_15_bits_meta_clients;
  logic [1:0]     mshrCtl_msInfo_15_bits_meta_alias;
  logic           mshrCtl_msInfo_15_bits_meta_prefetch;
  logic [2:0]     mshrCtl_msInfo_15_bits_meta_prefetchSrc;
  logic           mshrCtl_msInfo_15_bits_meta_accessed;
  logic           mshrCtl_msInfo_15_bits_meta_tagErr;
  logic           mshrCtl_msInfo_15_bits_meta_dataErr;
  logic [30:0]    mshrCtl_msInfo_15_bits_metaTag;
  logic           mshrCtl_msInfo_15_bits_dirHit;
  logic           mshrCtl_msInfo_15_bits_isAcqOrPrefetch;
  logic           mshrCtl_msInfo_15_bits_isPrefetch;
  logic [2:0]     mshrCtl_msInfo_15_bits_param;
  logic           mshrCtl_msInfo_15_bits_mergeA;
  logic           mshrCtl_msInfo_15_bits_w_grantfirst;
  logic           mshrCtl_msInfo_15_bits_s_release;
  logic           mshrCtl_msInfo_15_bits_s_refill;
  logic           mshrCtl_msInfo_15_bits_s_cmoresp;
  logic           mshrCtl_msInfo_15_bits_s_cmometaw;
  logic           mshrCtl_msInfo_15_bits_w_releaseack;
  logic           mshrCtl_msInfo_15_bits_w_replResp;
  logic           mshrCtl_msInfo_15_bits_w_rprobeacklast;
  logic           mshrCtl_msInfo_15_bits_replaceData;
  logic           mshrCtl_msInfo_15_bits_releaseToClean;
  logic [5:0]     mshrCtl_perf_0_value;
  logic [5:0]     mshrCtl_perf_1_value;
  logic [5:0]     mshrCtl_perf_3_value;
  // END GENERATED(core_wires)

  // ===========================================================================
  // §1 releaseBuf 读响应打一拍（Slice.scala: releaseBufResp_s3.valid := RegNext(releaseBuf.io.r.valid)）
  //    RequestArb 在 s2 发读，MSHRBuffer 下一拍出数据，正好对上 MainPipe s3。
  //    （refillBuf 那一路的 valid MainPipe 没用，golden 里端口被删，故只有这一个寄存器。）
  // ===========================================================================
  logic mainPipe_io_releaseBufResp_s3_valid_REG;
  always_ff @(posedge clock or posedge reset) begin
    if (reset) mainPipe_io_releaseBufResp_s3_valid_REG <= 1'b0;
    else       mainPipe_io_releaseBufResp_s3_valid_REG <= reqArb_releaseBufRead_s2_valid;
  end

  // ===========================================================================
  // §2 错误报告打一拍（io.error := RegNext(mainPipe.io.error)；valid 带复位，bits 不复位）
  // ===========================================================================
  logic        io_error_valid_REG;
  logic        io_error_bits_REG_valid;
  logic [45:0] io_error_bits_REG_address;
  always_ff @(posedge clock or posedge reset) begin
    if (reset) io_error_valid_REG <= 1'b0;
    else       io_error_valid_REG <= mainPipe_error_valid;
  end
  always_ff @(posedge clock) begin
    io_error_bits_REG_valid   <= mainPipe_error_bits_valid;
    io_error_bits_REG_address <= mainPipe_error_bits_address;
  end
  assign io_error_valid        = io_error_valid_REG;
  assign io_error_bits_valid   = io_error_bits_REG_valid;
  assign io_error_bits_address = io_error_bits_REG_address;

  // ===========================================================================
  // §3 TopDown / 预取统计输出（组合）
  //    dirResult：目录读结果，但排除 MSHR 发起的 Grant 读目录（那一拍 replResp 同时有效）。
  //    pfSent：L2 预取请求被 SinkA 收下的那一拍，带上预取来源。
  // ===========================================================================
  assign io_dirResult_valid                 = dir_resp_valid & ~dir_replResp_valid;
  assign io_dirResult_bits_hit              = dir_resp_bits_hit;
  assign io_dirResult_bits_meta_prefetch    = dir_resp_bits_meta_prefetch;
  assign io_dirResult_bits_meta_prefetchSrc = dir_resp_bits_meta_prefetchSrc;
  assign io_prefetch_req_ready              = sinkA_prefetchReq_ready;
  assign io_pfSent_valid                    = sinkA_prefetchReq_ready & io_prefetch_req_valid;
  assign io_pfSent_bits                     = io_prefetch_req_bits_pfSource;

  // ===========================================================================
  // §4 性能事件（generatePerfEvent：每个事件打两拍再输出）
  //    事件表 = MSHRCtl 的 3 个（编号 0,1,3；第 2 个 l2_cache_wr_refill 恒 0 被删）+ MainPipe 的 13 个（4..16）。
  // ===========================================================================
  logic [5:0] io_perf_0_value_REG,  io_perf_0_value_REG_1;    // MSHRCtl: l2_cache_refill
  logic [5:0] io_perf_1_value_REG,  io_perf_1_value_REG_1;    // MSHRCtl: l2_cache_rd_refill
  logic [5:0] io_perf_3_value_REG,  io_perf_3_value_REG_1;    // MSHRCtl: l2_cache_long_miss
  logic [5:0] io_perf_4_value_REG,  io_perf_4_value_REG_1;    // MainPipe 事件 0
  logic [5:0] io_perf_5_value_REG,  io_perf_5_value_REG_1;    // MainPipe 事件 1
  logic [5:0] io_perf_6_value_REG,  io_perf_6_value_REG_1;    // MainPipe 事件 2
  logic [5:0] io_perf_7_value_REG,  io_perf_7_value_REG_1;    // MainPipe 事件 3
  logic [5:0] io_perf_8_value_REG,  io_perf_8_value_REG_1;    // MainPipe 事件 4
  logic [5:0] io_perf_9_value_REG,  io_perf_9_value_REG_1;    // MainPipe 事件 5
  logic [5:0] io_perf_10_value_REG, io_perf_10_value_REG_1;   // MainPipe 事件 6
  logic [5:0] io_perf_11_value_REG, io_perf_11_value_REG_1;   // MainPipe 事件 7
  logic [5:0] io_perf_12_value_REG, io_perf_12_value_REG_1;   // MainPipe 事件 8
  logic [5:0] io_perf_13_value_REG, io_perf_13_value_REG_1;   // MainPipe 事件 9
  logic [5:0] io_perf_14_value_REG, io_perf_14_value_REG_1;   // MainPipe 事件 10
  logic [5:0] io_perf_15_value_REG, io_perf_15_value_REG_1;   // MainPipe 事件 11
  logic [5:0] io_perf_16_value_REG, io_perf_16_value_REG_1;   // MainPipe 事件 12
  always_ff @(posedge clock) begin
    io_perf_0_value_REG  <= mshrCtl_perf_0_value;    io_perf_0_value_REG_1  <= io_perf_0_value_REG;
    io_perf_1_value_REG  <= mshrCtl_perf_1_value;    io_perf_1_value_REG_1  <= io_perf_1_value_REG;
    io_perf_3_value_REG  <= mshrCtl_perf_3_value;    io_perf_3_value_REG_1  <= io_perf_3_value_REG;
    io_perf_4_value_REG  <= mainPipe_perf_0_value;   io_perf_4_value_REG_1  <= io_perf_4_value_REG;
    io_perf_5_value_REG  <= mainPipe_perf_1_value;   io_perf_5_value_REG_1  <= io_perf_5_value_REG;
    io_perf_6_value_REG  <= mainPipe_perf_2_value;   io_perf_6_value_REG_1  <= io_perf_6_value_REG;
    io_perf_7_value_REG  <= mainPipe_perf_3_value;   io_perf_7_value_REG_1  <= io_perf_7_value_REG;
    io_perf_8_value_REG  <= mainPipe_perf_4_value;   io_perf_8_value_REG_1  <= io_perf_8_value_REG;
    io_perf_9_value_REG  <= mainPipe_perf_5_value;   io_perf_9_value_REG_1  <= io_perf_9_value_REG;
    io_perf_10_value_REG <= mainPipe_perf_6_value;   io_perf_10_value_REG_1 <= io_perf_10_value_REG;
    io_perf_11_value_REG <= mainPipe_perf_7_value;   io_perf_11_value_REG_1 <= io_perf_11_value_REG;
    io_perf_12_value_REG <= mainPipe_perf_8_value;   io_perf_12_value_REG_1 <= io_perf_12_value_REG;
    io_perf_13_value_REG <= mainPipe_perf_9_value;   io_perf_13_value_REG_1 <= io_perf_13_value_REG;
    io_perf_14_value_REG <= mainPipe_perf_10_value;  io_perf_14_value_REG_1 <= io_perf_14_value_REG;
    io_perf_15_value_REG <= mainPipe_perf_11_value;  io_perf_15_value_REG_1 <= io_perf_15_value_REG;
    io_perf_16_value_REG <= mainPipe_perf_12_value;  io_perf_16_value_REG_1 <= io_perf_16_value_REG;
  end
  assign io_perf_0_value  = io_perf_0_value_REG_1;
  assign io_perf_1_value  = io_perf_1_value_REG_1;
  assign io_perf_3_value  = io_perf_3_value_REG_1;
  assign io_perf_4_value  = io_perf_4_value_REG_1;
  assign io_perf_5_value  = io_perf_5_value_REG_1;
  assign io_perf_6_value  = io_perf_6_value_REG_1;
  assign io_perf_7_value  = io_perf_7_value_REG_1;
  assign io_perf_8_value  = io_perf_8_value_REG_1;
  assign io_perf_9_value  = io_perf_9_value_REG_1;
  assign io_perf_10_value = io_perf_10_value_REG_1;
  assign io_perf_11_value = io_perf_11_value_REG_1;
  assign io_perf_12_value = io_perf_12_value_REG_1;
  assign io_perf_13_value = io_perf_13_value_REG_1;
  assign io_perf_14_value = io_perf_14_value_REG_1;
  assign io_perf_15_value = io_perf_15_value_REG_1;
  assign io_perf_16_value = io_perf_16_value_REG_1;

  // ===========================================================================
  // §5 child 互连（连线生成）
  // ===========================================================================
  // BEGIN GENERATED(to_dir_ds) —— scripts/gen_l2_slice.py 生成
  // 核 -> 目录（dir_*）/ 数据阵列（ds_*）：这两个 child 在 wrapper 里
  assign dir_read_valid = reqArb_dirRead_s1_valid;
  assign dir_read_bits_tag = reqArb_dirRead_s1_bits_tag;
  assign dir_read_bits_set = reqArb_dirRead_s1_bits_set;
  assign dir_read_bits_wayMask = reqArb_dirRead_s1_bits_wayMask;
  assign dir_read_bits_replacerInfo_channel = reqArb_dirRead_s1_bits_replacerInfo_channel;
  assign dir_read_bits_replacerInfo_opcode = reqArb_dirRead_s1_bits_replacerInfo_opcode;
  assign dir_read_bits_replacerInfo_reqSource = reqArb_dirRead_s1_bits_replacerInfo_reqSource;
  assign dir_read_bits_replacerInfo_refill_prefetch = reqArb_dirRead_s1_bits_replacerInfo_refill_prefetch;
  assign dir_read_bits_refill = reqArb_dirRead_s1_bits_refill;
  assign dir_read_bits_mshrId = reqArb_dirRead_s1_bits_mshrId;
  assign dir_read_bits_cmoAll = reqArb_dirRead_s1_bits_cmoAll;
  assign dir_read_bits_cmoWay = reqArb_dirRead_s1_bits_cmoWay;
  assign dir_metaWReq_valid = mainPipe_metaWReq_valid;
  assign dir_metaWReq_bits_set = mainPipe_metaWReq_bits_set;
  assign dir_metaWReq_bits_wayOH = mainPipe_metaWReq_bits_wayOH;
  assign dir_metaWReq_bits_wmeta_dirty = mainPipe_metaWReq_bits_wmeta_dirty;
  assign dir_metaWReq_bits_wmeta_state = mainPipe_metaWReq_bits_wmeta_state;
  assign dir_metaWReq_bits_wmeta_clients = mainPipe_metaWReq_bits_wmeta_clients;
  assign dir_metaWReq_bits_wmeta_alias = mainPipe_metaWReq_bits_wmeta_alias;
  assign dir_metaWReq_bits_wmeta_prefetch = mainPipe_metaWReq_bits_wmeta_prefetch;
  assign dir_metaWReq_bits_wmeta_prefetchSrc = mainPipe_metaWReq_bits_wmeta_prefetchSrc;
  assign dir_metaWReq_bits_wmeta_accessed = mainPipe_metaWReq_bits_wmeta_accessed;
  assign dir_metaWReq_bits_wmeta_tagErr = mainPipe_metaWReq_bits_wmeta_tagErr;
  assign dir_metaWReq_bits_wmeta_dataErr = mainPipe_metaWReq_bits_wmeta_dataErr;
  assign dir_tagWReq_valid = mainPipe_tagWReq_valid;
  assign dir_tagWReq_bits_set = mainPipe_tagWReq_bits_set;
  assign dir_tagWReq_bits_way = mainPipe_tagWReq_bits_way;
  assign dir_tagWReq_bits_wtag = mainPipe_tagWReq_bits_wtag;
  assign dir_msInfo_0_valid = mshrCtl_msInfo_0_valid;
  assign dir_msInfo_0_bits_channel = mshrCtl_msInfo_0_bits_channel;
  assign dir_msInfo_0_bits_set = mshrCtl_msInfo_0_bits_set;
  assign dir_msInfo_0_bits_way = mshrCtl_msInfo_0_bits_way;
  assign dir_msInfo_0_bits_reqTag = mshrCtl_msInfo_0_bits_reqTag;
  assign dir_msInfo_0_bits_willFree = mshrCtl_msInfo_0_bits_willFree;
  assign dir_msInfo_0_bits_aliasTask = mshrCtl_msInfo_0_bits_aliasTask;
  assign dir_msInfo_0_bits_needRelease = mshrCtl_msInfo_0_bits_needRelease;
  assign dir_msInfo_0_bits_blockRefill = mshrCtl_msInfo_0_bits_blockRefill;
  assign dir_msInfo_0_bits_meta_dirty = mshrCtl_msInfo_0_bits_meta_dirty;
  assign dir_msInfo_0_bits_meta_state = mshrCtl_msInfo_0_bits_meta_state;
  assign dir_msInfo_0_bits_meta_clients = mshrCtl_msInfo_0_bits_meta_clients;
  assign dir_msInfo_0_bits_meta_alias = mshrCtl_msInfo_0_bits_meta_alias;
  assign dir_msInfo_0_bits_meta_prefetch = mshrCtl_msInfo_0_bits_meta_prefetch;
  assign dir_msInfo_0_bits_meta_prefetchSrc = mshrCtl_msInfo_0_bits_meta_prefetchSrc;
  assign dir_msInfo_0_bits_meta_accessed = mshrCtl_msInfo_0_bits_meta_accessed;
  assign dir_msInfo_0_bits_meta_tagErr = mshrCtl_msInfo_0_bits_meta_tagErr;
  assign dir_msInfo_0_bits_meta_dataErr = mshrCtl_msInfo_0_bits_meta_dataErr;
  assign dir_msInfo_0_bits_metaTag = mshrCtl_msInfo_0_bits_metaTag;
  assign dir_msInfo_0_bits_dirHit = mshrCtl_msInfo_0_bits_dirHit;
  assign dir_msInfo_0_bits_isAcqOrPrefetch = mshrCtl_msInfo_0_bits_isAcqOrPrefetch;
  assign dir_msInfo_0_bits_isPrefetch = mshrCtl_msInfo_0_bits_isPrefetch;
  assign dir_msInfo_0_bits_param = mshrCtl_msInfo_0_bits_param;
  assign dir_msInfo_0_bits_mergeA = mshrCtl_msInfo_0_bits_mergeA;
  assign dir_msInfo_0_bits_w_grantfirst = mshrCtl_msInfo_0_bits_w_grantfirst;
  assign dir_msInfo_0_bits_s_release = mshrCtl_msInfo_0_bits_s_release;
  assign dir_msInfo_0_bits_s_refill = mshrCtl_msInfo_0_bits_s_refill;
  assign dir_msInfo_0_bits_s_cmoresp = mshrCtl_msInfo_0_bits_s_cmoresp;
  assign dir_msInfo_0_bits_s_cmometaw = mshrCtl_msInfo_0_bits_s_cmometaw;
  assign dir_msInfo_0_bits_w_releaseack = mshrCtl_msInfo_0_bits_w_releaseack;
  assign dir_msInfo_0_bits_w_replResp = mshrCtl_msInfo_0_bits_w_replResp;
  assign dir_msInfo_0_bits_w_rprobeacklast = mshrCtl_msInfo_0_bits_w_rprobeacklast;
  assign dir_msInfo_0_bits_replaceData = mshrCtl_msInfo_0_bits_replaceData;
  assign dir_msInfo_0_bits_releaseToClean = mshrCtl_msInfo_0_bits_releaseToClean;
  assign dir_msInfo_1_valid = mshrCtl_msInfo_1_valid;
  assign dir_msInfo_1_bits_channel = mshrCtl_msInfo_1_bits_channel;
  assign dir_msInfo_1_bits_set = mshrCtl_msInfo_1_bits_set;
  assign dir_msInfo_1_bits_way = mshrCtl_msInfo_1_bits_way;
  assign dir_msInfo_1_bits_reqTag = mshrCtl_msInfo_1_bits_reqTag;
  assign dir_msInfo_1_bits_willFree = mshrCtl_msInfo_1_bits_willFree;
  assign dir_msInfo_1_bits_aliasTask = mshrCtl_msInfo_1_bits_aliasTask;
  assign dir_msInfo_1_bits_needRelease = mshrCtl_msInfo_1_bits_needRelease;
  assign dir_msInfo_1_bits_blockRefill = mshrCtl_msInfo_1_bits_blockRefill;
  assign dir_msInfo_1_bits_meta_dirty = mshrCtl_msInfo_1_bits_meta_dirty;
  assign dir_msInfo_1_bits_meta_state = mshrCtl_msInfo_1_bits_meta_state;
  assign dir_msInfo_1_bits_meta_clients = mshrCtl_msInfo_1_bits_meta_clients;
  assign dir_msInfo_1_bits_meta_alias = mshrCtl_msInfo_1_bits_meta_alias;
  assign dir_msInfo_1_bits_meta_prefetch = mshrCtl_msInfo_1_bits_meta_prefetch;
  assign dir_msInfo_1_bits_meta_prefetchSrc = mshrCtl_msInfo_1_bits_meta_prefetchSrc;
  assign dir_msInfo_1_bits_meta_accessed = mshrCtl_msInfo_1_bits_meta_accessed;
  assign dir_msInfo_1_bits_meta_tagErr = mshrCtl_msInfo_1_bits_meta_tagErr;
  assign dir_msInfo_1_bits_meta_dataErr = mshrCtl_msInfo_1_bits_meta_dataErr;
  assign dir_msInfo_1_bits_metaTag = mshrCtl_msInfo_1_bits_metaTag;
  assign dir_msInfo_1_bits_dirHit = mshrCtl_msInfo_1_bits_dirHit;
  assign dir_msInfo_1_bits_isAcqOrPrefetch = mshrCtl_msInfo_1_bits_isAcqOrPrefetch;
  assign dir_msInfo_1_bits_isPrefetch = mshrCtl_msInfo_1_bits_isPrefetch;
  assign dir_msInfo_1_bits_param = mshrCtl_msInfo_1_bits_param;
  assign dir_msInfo_1_bits_mergeA = mshrCtl_msInfo_1_bits_mergeA;
  assign dir_msInfo_1_bits_w_grantfirst = mshrCtl_msInfo_1_bits_w_grantfirst;
  assign dir_msInfo_1_bits_s_release = mshrCtl_msInfo_1_bits_s_release;
  assign dir_msInfo_1_bits_s_refill = mshrCtl_msInfo_1_bits_s_refill;
  assign dir_msInfo_1_bits_s_cmoresp = mshrCtl_msInfo_1_bits_s_cmoresp;
  assign dir_msInfo_1_bits_s_cmometaw = mshrCtl_msInfo_1_bits_s_cmometaw;
  assign dir_msInfo_1_bits_w_releaseack = mshrCtl_msInfo_1_bits_w_releaseack;
  assign dir_msInfo_1_bits_w_replResp = mshrCtl_msInfo_1_bits_w_replResp;
  assign dir_msInfo_1_bits_w_rprobeacklast = mshrCtl_msInfo_1_bits_w_rprobeacklast;
  assign dir_msInfo_1_bits_replaceData = mshrCtl_msInfo_1_bits_replaceData;
  assign dir_msInfo_1_bits_releaseToClean = mshrCtl_msInfo_1_bits_releaseToClean;
  assign dir_msInfo_2_valid = mshrCtl_msInfo_2_valid;
  assign dir_msInfo_2_bits_channel = mshrCtl_msInfo_2_bits_channel;
  assign dir_msInfo_2_bits_set = mshrCtl_msInfo_2_bits_set;
  assign dir_msInfo_2_bits_way = mshrCtl_msInfo_2_bits_way;
  assign dir_msInfo_2_bits_reqTag = mshrCtl_msInfo_2_bits_reqTag;
  assign dir_msInfo_2_bits_willFree = mshrCtl_msInfo_2_bits_willFree;
  assign dir_msInfo_2_bits_aliasTask = mshrCtl_msInfo_2_bits_aliasTask;
  assign dir_msInfo_2_bits_needRelease = mshrCtl_msInfo_2_bits_needRelease;
  assign dir_msInfo_2_bits_blockRefill = mshrCtl_msInfo_2_bits_blockRefill;
  assign dir_msInfo_2_bits_meta_dirty = mshrCtl_msInfo_2_bits_meta_dirty;
  assign dir_msInfo_2_bits_meta_state = mshrCtl_msInfo_2_bits_meta_state;
  assign dir_msInfo_2_bits_meta_clients = mshrCtl_msInfo_2_bits_meta_clients;
  assign dir_msInfo_2_bits_meta_alias = mshrCtl_msInfo_2_bits_meta_alias;
  assign dir_msInfo_2_bits_meta_prefetch = mshrCtl_msInfo_2_bits_meta_prefetch;
  assign dir_msInfo_2_bits_meta_prefetchSrc = mshrCtl_msInfo_2_bits_meta_prefetchSrc;
  assign dir_msInfo_2_bits_meta_accessed = mshrCtl_msInfo_2_bits_meta_accessed;
  assign dir_msInfo_2_bits_meta_tagErr = mshrCtl_msInfo_2_bits_meta_tagErr;
  assign dir_msInfo_2_bits_meta_dataErr = mshrCtl_msInfo_2_bits_meta_dataErr;
  assign dir_msInfo_2_bits_metaTag = mshrCtl_msInfo_2_bits_metaTag;
  assign dir_msInfo_2_bits_dirHit = mshrCtl_msInfo_2_bits_dirHit;
  assign dir_msInfo_2_bits_isAcqOrPrefetch = mshrCtl_msInfo_2_bits_isAcqOrPrefetch;
  assign dir_msInfo_2_bits_isPrefetch = mshrCtl_msInfo_2_bits_isPrefetch;
  assign dir_msInfo_2_bits_param = mshrCtl_msInfo_2_bits_param;
  assign dir_msInfo_2_bits_mergeA = mshrCtl_msInfo_2_bits_mergeA;
  assign dir_msInfo_2_bits_w_grantfirst = mshrCtl_msInfo_2_bits_w_grantfirst;
  assign dir_msInfo_2_bits_s_release = mshrCtl_msInfo_2_bits_s_release;
  assign dir_msInfo_2_bits_s_refill = mshrCtl_msInfo_2_bits_s_refill;
  assign dir_msInfo_2_bits_s_cmoresp = mshrCtl_msInfo_2_bits_s_cmoresp;
  assign dir_msInfo_2_bits_s_cmometaw = mshrCtl_msInfo_2_bits_s_cmometaw;
  assign dir_msInfo_2_bits_w_releaseack = mshrCtl_msInfo_2_bits_w_releaseack;
  assign dir_msInfo_2_bits_w_replResp = mshrCtl_msInfo_2_bits_w_replResp;
  assign dir_msInfo_2_bits_w_rprobeacklast = mshrCtl_msInfo_2_bits_w_rprobeacklast;
  assign dir_msInfo_2_bits_replaceData = mshrCtl_msInfo_2_bits_replaceData;
  assign dir_msInfo_2_bits_releaseToClean = mshrCtl_msInfo_2_bits_releaseToClean;
  assign dir_msInfo_3_valid = mshrCtl_msInfo_3_valid;
  assign dir_msInfo_3_bits_channel = mshrCtl_msInfo_3_bits_channel;
  assign dir_msInfo_3_bits_set = mshrCtl_msInfo_3_bits_set;
  assign dir_msInfo_3_bits_way = mshrCtl_msInfo_3_bits_way;
  assign dir_msInfo_3_bits_reqTag = mshrCtl_msInfo_3_bits_reqTag;
  assign dir_msInfo_3_bits_willFree = mshrCtl_msInfo_3_bits_willFree;
  assign dir_msInfo_3_bits_aliasTask = mshrCtl_msInfo_3_bits_aliasTask;
  assign dir_msInfo_3_bits_needRelease = mshrCtl_msInfo_3_bits_needRelease;
  assign dir_msInfo_3_bits_blockRefill = mshrCtl_msInfo_3_bits_blockRefill;
  assign dir_msInfo_3_bits_meta_dirty = mshrCtl_msInfo_3_bits_meta_dirty;
  assign dir_msInfo_3_bits_meta_state = mshrCtl_msInfo_3_bits_meta_state;
  assign dir_msInfo_3_bits_meta_clients = mshrCtl_msInfo_3_bits_meta_clients;
  assign dir_msInfo_3_bits_meta_alias = mshrCtl_msInfo_3_bits_meta_alias;
  assign dir_msInfo_3_bits_meta_prefetch = mshrCtl_msInfo_3_bits_meta_prefetch;
  assign dir_msInfo_3_bits_meta_prefetchSrc = mshrCtl_msInfo_3_bits_meta_prefetchSrc;
  assign dir_msInfo_3_bits_meta_accessed = mshrCtl_msInfo_3_bits_meta_accessed;
  assign dir_msInfo_3_bits_meta_tagErr = mshrCtl_msInfo_3_bits_meta_tagErr;
  assign dir_msInfo_3_bits_meta_dataErr = mshrCtl_msInfo_3_bits_meta_dataErr;
  assign dir_msInfo_3_bits_metaTag = mshrCtl_msInfo_3_bits_metaTag;
  assign dir_msInfo_3_bits_dirHit = mshrCtl_msInfo_3_bits_dirHit;
  assign dir_msInfo_3_bits_isAcqOrPrefetch = mshrCtl_msInfo_3_bits_isAcqOrPrefetch;
  assign dir_msInfo_3_bits_isPrefetch = mshrCtl_msInfo_3_bits_isPrefetch;
  assign dir_msInfo_3_bits_param = mshrCtl_msInfo_3_bits_param;
  assign dir_msInfo_3_bits_mergeA = mshrCtl_msInfo_3_bits_mergeA;
  assign dir_msInfo_3_bits_w_grantfirst = mshrCtl_msInfo_3_bits_w_grantfirst;
  assign dir_msInfo_3_bits_s_release = mshrCtl_msInfo_3_bits_s_release;
  assign dir_msInfo_3_bits_s_refill = mshrCtl_msInfo_3_bits_s_refill;
  assign dir_msInfo_3_bits_s_cmoresp = mshrCtl_msInfo_3_bits_s_cmoresp;
  assign dir_msInfo_3_bits_s_cmometaw = mshrCtl_msInfo_3_bits_s_cmometaw;
  assign dir_msInfo_3_bits_w_releaseack = mshrCtl_msInfo_3_bits_w_releaseack;
  assign dir_msInfo_3_bits_w_replResp = mshrCtl_msInfo_3_bits_w_replResp;
  assign dir_msInfo_3_bits_w_rprobeacklast = mshrCtl_msInfo_3_bits_w_rprobeacklast;
  assign dir_msInfo_3_bits_replaceData = mshrCtl_msInfo_3_bits_replaceData;
  assign dir_msInfo_3_bits_releaseToClean = mshrCtl_msInfo_3_bits_releaseToClean;
  assign dir_msInfo_4_valid = mshrCtl_msInfo_4_valid;
  assign dir_msInfo_4_bits_channel = mshrCtl_msInfo_4_bits_channel;
  assign dir_msInfo_4_bits_set = mshrCtl_msInfo_4_bits_set;
  assign dir_msInfo_4_bits_way = mshrCtl_msInfo_4_bits_way;
  assign dir_msInfo_4_bits_reqTag = mshrCtl_msInfo_4_bits_reqTag;
  assign dir_msInfo_4_bits_willFree = mshrCtl_msInfo_4_bits_willFree;
  assign dir_msInfo_4_bits_aliasTask = mshrCtl_msInfo_4_bits_aliasTask;
  assign dir_msInfo_4_bits_needRelease = mshrCtl_msInfo_4_bits_needRelease;
  assign dir_msInfo_4_bits_blockRefill = mshrCtl_msInfo_4_bits_blockRefill;
  assign dir_msInfo_4_bits_meta_dirty = mshrCtl_msInfo_4_bits_meta_dirty;
  assign dir_msInfo_4_bits_meta_state = mshrCtl_msInfo_4_bits_meta_state;
  assign dir_msInfo_4_bits_meta_clients = mshrCtl_msInfo_4_bits_meta_clients;
  assign dir_msInfo_4_bits_meta_alias = mshrCtl_msInfo_4_bits_meta_alias;
  assign dir_msInfo_4_bits_meta_prefetch = mshrCtl_msInfo_4_bits_meta_prefetch;
  assign dir_msInfo_4_bits_meta_prefetchSrc = mshrCtl_msInfo_4_bits_meta_prefetchSrc;
  assign dir_msInfo_4_bits_meta_accessed = mshrCtl_msInfo_4_bits_meta_accessed;
  assign dir_msInfo_4_bits_meta_tagErr = mshrCtl_msInfo_4_bits_meta_tagErr;
  assign dir_msInfo_4_bits_meta_dataErr = mshrCtl_msInfo_4_bits_meta_dataErr;
  assign dir_msInfo_4_bits_metaTag = mshrCtl_msInfo_4_bits_metaTag;
  assign dir_msInfo_4_bits_dirHit = mshrCtl_msInfo_4_bits_dirHit;
  assign dir_msInfo_4_bits_isAcqOrPrefetch = mshrCtl_msInfo_4_bits_isAcqOrPrefetch;
  assign dir_msInfo_4_bits_isPrefetch = mshrCtl_msInfo_4_bits_isPrefetch;
  assign dir_msInfo_4_bits_param = mshrCtl_msInfo_4_bits_param;
  assign dir_msInfo_4_bits_mergeA = mshrCtl_msInfo_4_bits_mergeA;
  assign dir_msInfo_4_bits_w_grantfirst = mshrCtl_msInfo_4_bits_w_grantfirst;
  assign dir_msInfo_4_bits_s_release = mshrCtl_msInfo_4_bits_s_release;
  assign dir_msInfo_4_bits_s_refill = mshrCtl_msInfo_4_bits_s_refill;
  assign dir_msInfo_4_bits_s_cmoresp = mshrCtl_msInfo_4_bits_s_cmoresp;
  assign dir_msInfo_4_bits_s_cmometaw = mshrCtl_msInfo_4_bits_s_cmometaw;
  assign dir_msInfo_4_bits_w_releaseack = mshrCtl_msInfo_4_bits_w_releaseack;
  assign dir_msInfo_4_bits_w_replResp = mshrCtl_msInfo_4_bits_w_replResp;
  assign dir_msInfo_4_bits_w_rprobeacklast = mshrCtl_msInfo_4_bits_w_rprobeacklast;
  assign dir_msInfo_4_bits_replaceData = mshrCtl_msInfo_4_bits_replaceData;
  assign dir_msInfo_4_bits_releaseToClean = mshrCtl_msInfo_4_bits_releaseToClean;
  assign dir_msInfo_5_valid = mshrCtl_msInfo_5_valid;
  assign dir_msInfo_5_bits_channel = mshrCtl_msInfo_5_bits_channel;
  assign dir_msInfo_5_bits_set = mshrCtl_msInfo_5_bits_set;
  assign dir_msInfo_5_bits_way = mshrCtl_msInfo_5_bits_way;
  assign dir_msInfo_5_bits_reqTag = mshrCtl_msInfo_5_bits_reqTag;
  assign dir_msInfo_5_bits_willFree = mshrCtl_msInfo_5_bits_willFree;
  assign dir_msInfo_5_bits_aliasTask = mshrCtl_msInfo_5_bits_aliasTask;
  assign dir_msInfo_5_bits_needRelease = mshrCtl_msInfo_5_bits_needRelease;
  assign dir_msInfo_5_bits_blockRefill = mshrCtl_msInfo_5_bits_blockRefill;
  assign dir_msInfo_5_bits_meta_dirty = mshrCtl_msInfo_5_bits_meta_dirty;
  assign dir_msInfo_5_bits_meta_state = mshrCtl_msInfo_5_bits_meta_state;
  assign dir_msInfo_5_bits_meta_clients = mshrCtl_msInfo_5_bits_meta_clients;
  assign dir_msInfo_5_bits_meta_alias = mshrCtl_msInfo_5_bits_meta_alias;
  assign dir_msInfo_5_bits_meta_prefetch = mshrCtl_msInfo_5_bits_meta_prefetch;
  assign dir_msInfo_5_bits_meta_prefetchSrc = mshrCtl_msInfo_5_bits_meta_prefetchSrc;
  assign dir_msInfo_5_bits_meta_accessed = mshrCtl_msInfo_5_bits_meta_accessed;
  assign dir_msInfo_5_bits_meta_tagErr = mshrCtl_msInfo_5_bits_meta_tagErr;
  assign dir_msInfo_5_bits_meta_dataErr = mshrCtl_msInfo_5_bits_meta_dataErr;
  assign dir_msInfo_5_bits_metaTag = mshrCtl_msInfo_5_bits_metaTag;
  assign dir_msInfo_5_bits_dirHit = mshrCtl_msInfo_5_bits_dirHit;
  assign dir_msInfo_5_bits_isAcqOrPrefetch = mshrCtl_msInfo_5_bits_isAcqOrPrefetch;
  assign dir_msInfo_5_bits_isPrefetch = mshrCtl_msInfo_5_bits_isPrefetch;
  assign dir_msInfo_5_bits_param = mshrCtl_msInfo_5_bits_param;
  assign dir_msInfo_5_bits_mergeA = mshrCtl_msInfo_5_bits_mergeA;
  assign dir_msInfo_5_bits_w_grantfirst = mshrCtl_msInfo_5_bits_w_grantfirst;
  assign dir_msInfo_5_bits_s_release = mshrCtl_msInfo_5_bits_s_release;
  assign dir_msInfo_5_bits_s_refill = mshrCtl_msInfo_5_bits_s_refill;
  assign dir_msInfo_5_bits_s_cmoresp = mshrCtl_msInfo_5_bits_s_cmoresp;
  assign dir_msInfo_5_bits_s_cmometaw = mshrCtl_msInfo_5_bits_s_cmometaw;
  assign dir_msInfo_5_bits_w_releaseack = mshrCtl_msInfo_5_bits_w_releaseack;
  assign dir_msInfo_5_bits_w_replResp = mshrCtl_msInfo_5_bits_w_replResp;
  assign dir_msInfo_5_bits_w_rprobeacklast = mshrCtl_msInfo_5_bits_w_rprobeacklast;
  assign dir_msInfo_5_bits_replaceData = mshrCtl_msInfo_5_bits_replaceData;
  assign dir_msInfo_5_bits_releaseToClean = mshrCtl_msInfo_5_bits_releaseToClean;
  assign dir_msInfo_6_valid = mshrCtl_msInfo_6_valid;
  assign dir_msInfo_6_bits_channel = mshrCtl_msInfo_6_bits_channel;
  assign dir_msInfo_6_bits_set = mshrCtl_msInfo_6_bits_set;
  assign dir_msInfo_6_bits_way = mshrCtl_msInfo_6_bits_way;
  assign dir_msInfo_6_bits_reqTag = mshrCtl_msInfo_6_bits_reqTag;
  assign dir_msInfo_6_bits_willFree = mshrCtl_msInfo_6_bits_willFree;
  assign dir_msInfo_6_bits_aliasTask = mshrCtl_msInfo_6_bits_aliasTask;
  assign dir_msInfo_6_bits_needRelease = mshrCtl_msInfo_6_bits_needRelease;
  assign dir_msInfo_6_bits_blockRefill = mshrCtl_msInfo_6_bits_blockRefill;
  assign dir_msInfo_6_bits_meta_dirty = mshrCtl_msInfo_6_bits_meta_dirty;
  assign dir_msInfo_6_bits_meta_state = mshrCtl_msInfo_6_bits_meta_state;
  assign dir_msInfo_6_bits_meta_clients = mshrCtl_msInfo_6_bits_meta_clients;
  assign dir_msInfo_6_bits_meta_alias = mshrCtl_msInfo_6_bits_meta_alias;
  assign dir_msInfo_6_bits_meta_prefetch = mshrCtl_msInfo_6_bits_meta_prefetch;
  assign dir_msInfo_6_bits_meta_prefetchSrc = mshrCtl_msInfo_6_bits_meta_prefetchSrc;
  assign dir_msInfo_6_bits_meta_accessed = mshrCtl_msInfo_6_bits_meta_accessed;
  assign dir_msInfo_6_bits_meta_tagErr = mshrCtl_msInfo_6_bits_meta_tagErr;
  assign dir_msInfo_6_bits_meta_dataErr = mshrCtl_msInfo_6_bits_meta_dataErr;
  assign dir_msInfo_6_bits_metaTag = mshrCtl_msInfo_6_bits_metaTag;
  assign dir_msInfo_6_bits_dirHit = mshrCtl_msInfo_6_bits_dirHit;
  assign dir_msInfo_6_bits_isAcqOrPrefetch = mshrCtl_msInfo_6_bits_isAcqOrPrefetch;
  assign dir_msInfo_6_bits_isPrefetch = mshrCtl_msInfo_6_bits_isPrefetch;
  assign dir_msInfo_6_bits_param = mshrCtl_msInfo_6_bits_param;
  assign dir_msInfo_6_bits_mergeA = mshrCtl_msInfo_6_bits_mergeA;
  assign dir_msInfo_6_bits_w_grantfirst = mshrCtl_msInfo_6_bits_w_grantfirst;
  assign dir_msInfo_6_bits_s_release = mshrCtl_msInfo_6_bits_s_release;
  assign dir_msInfo_6_bits_s_refill = mshrCtl_msInfo_6_bits_s_refill;
  assign dir_msInfo_6_bits_s_cmoresp = mshrCtl_msInfo_6_bits_s_cmoresp;
  assign dir_msInfo_6_bits_s_cmometaw = mshrCtl_msInfo_6_bits_s_cmometaw;
  assign dir_msInfo_6_bits_w_releaseack = mshrCtl_msInfo_6_bits_w_releaseack;
  assign dir_msInfo_6_bits_w_replResp = mshrCtl_msInfo_6_bits_w_replResp;
  assign dir_msInfo_6_bits_w_rprobeacklast = mshrCtl_msInfo_6_bits_w_rprobeacklast;
  assign dir_msInfo_6_bits_replaceData = mshrCtl_msInfo_6_bits_replaceData;
  assign dir_msInfo_6_bits_releaseToClean = mshrCtl_msInfo_6_bits_releaseToClean;
  assign dir_msInfo_7_valid = mshrCtl_msInfo_7_valid;
  assign dir_msInfo_7_bits_channel = mshrCtl_msInfo_7_bits_channel;
  assign dir_msInfo_7_bits_set = mshrCtl_msInfo_7_bits_set;
  assign dir_msInfo_7_bits_way = mshrCtl_msInfo_7_bits_way;
  assign dir_msInfo_7_bits_reqTag = mshrCtl_msInfo_7_bits_reqTag;
  assign dir_msInfo_7_bits_willFree = mshrCtl_msInfo_7_bits_willFree;
  assign dir_msInfo_7_bits_aliasTask = mshrCtl_msInfo_7_bits_aliasTask;
  assign dir_msInfo_7_bits_needRelease = mshrCtl_msInfo_7_bits_needRelease;
  assign dir_msInfo_7_bits_blockRefill = mshrCtl_msInfo_7_bits_blockRefill;
  assign dir_msInfo_7_bits_meta_dirty = mshrCtl_msInfo_7_bits_meta_dirty;
  assign dir_msInfo_7_bits_meta_state = mshrCtl_msInfo_7_bits_meta_state;
  assign dir_msInfo_7_bits_meta_clients = mshrCtl_msInfo_7_bits_meta_clients;
  assign dir_msInfo_7_bits_meta_alias = mshrCtl_msInfo_7_bits_meta_alias;
  assign dir_msInfo_7_bits_meta_prefetch = mshrCtl_msInfo_7_bits_meta_prefetch;
  assign dir_msInfo_7_bits_meta_prefetchSrc = mshrCtl_msInfo_7_bits_meta_prefetchSrc;
  assign dir_msInfo_7_bits_meta_accessed = mshrCtl_msInfo_7_bits_meta_accessed;
  assign dir_msInfo_7_bits_meta_tagErr = mshrCtl_msInfo_7_bits_meta_tagErr;
  assign dir_msInfo_7_bits_meta_dataErr = mshrCtl_msInfo_7_bits_meta_dataErr;
  assign dir_msInfo_7_bits_metaTag = mshrCtl_msInfo_7_bits_metaTag;
  assign dir_msInfo_7_bits_dirHit = mshrCtl_msInfo_7_bits_dirHit;
  assign dir_msInfo_7_bits_isAcqOrPrefetch = mshrCtl_msInfo_7_bits_isAcqOrPrefetch;
  assign dir_msInfo_7_bits_isPrefetch = mshrCtl_msInfo_7_bits_isPrefetch;
  assign dir_msInfo_7_bits_param = mshrCtl_msInfo_7_bits_param;
  assign dir_msInfo_7_bits_mergeA = mshrCtl_msInfo_7_bits_mergeA;
  assign dir_msInfo_7_bits_w_grantfirst = mshrCtl_msInfo_7_bits_w_grantfirst;
  assign dir_msInfo_7_bits_s_release = mshrCtl_msInfo_7_bits_s_release;
  assign dir_msInfo_7_bits_s_refill = mshrCtl_msInfo_7_bits_s_refill;
  assign dir_msInfo_7_bits_s_cmoresp = mshrCtl_msInfo_7_bits_s_cmoresp;
  assign dir_msInfo_7_bits_s_cmometaw = mshrCtl_msInfo_7_bits_s_cmometaw;
  assign dir_msInfo_7_bits_w_releaseack = mshrCtl_msInfo_7_bits_w_releaseack;
  assign dir_msInfo_7_bits_w_replResp = mshrCtl_msInfo_7_bits_w_replResp;
  assign dir_msInfo_7_bits_w_rprobeacklast = mshrCtl_msInfo_7_bits_w_rprobeacklast;
  assign dir_msInfo_7_bits_replaceData = mshrCtl_msInfo_7_bits_replaceData;
  assign dir_msInfo_7_bits_releaseToClean = mshrCtl_msInfo_7_bits_releaseToClean;
  assign dir_msInfo_8_valid = mshrCtl_msInfo_8_valid;
  assign dir_msInfo_8_bits_channel = mshrCtl_msInfo_8_bits_channel;
  assign dir_msInfo_8_bits_set = mshrCtl_msInfo_8_bits_set;
  assign dir_msInfo_8_bits_way = mshrCtl_msInfo_8_bits_way;
  assign dir_msInfo_8_bits_reqTag = mshrCtl_msInfo_8_bits_reqTag;
  assign dir_msInfo_8_bits_willFree = mshrCtl_msInfo_8_bits_willFree;
  assign dir_msInfo_8_bits_aliasTask = mshrCtl_msInfo_8_bits_aliasTask;
  assign dir_msInfo_8_bits_needRelease = mshrCtl_msInfo_8_bits_needRelease;
  assign dir_msInfo_8_bits_blockRefill = mshrCtl_msInfo_8_bits_blockRefill;
  assign dir_msInfo_8_bits_meta_dirty = mshrCtl_msInfo_8_bits_meta_dirty;
  assign dir_msInfo_8_bits_meta_state = mshrCtl_msInfo_8_bits_meta_state;
  assign dir_msInfo_8_bits_meta_clients = mshrCtl_msInfo_8_bits_meta_clients;
  assign dir_msInfo_8_bits_meta_alias = mshrCtl_msInfo_8_bits_meta_alias;
  assign dir_msInfo_8_bits_meta_prefetch = mshrCtl_msInfo_8_bits_meta_prefetch;
  assign dir_msInfo_8_bits_meta_prefetchSrc = mshrCtl_msInfo_8_bits_meta_prefetchSrc;
  assign dir_msInfo_8_bits_meta_accessed = mshrCtl_msInfo_8_bits_meta_accessed;
  assign dir_msInfo_8_bits_meta_tagErr = mshrCtl_msInfo_8_bits_meta_tagErr;
  assign dir_msInfo_8_bits_meta_dataErr = mshrCtl_msInfo_8_bits_meta_dataErr;
  assign dir_msInfo_8_bits_metaTag = mshrCtl_msInfo_8_bits_metaTag;
  assign dir_msInfo_8_bits_dirHit = mshrCtl_msInfo_8_bits_dirHit;
  assign dir_msInfo_8_bits_isAcqOrPrefetch = mshrCtl_msInfo_8_bits_isAcqOrPrefetch;
  assign dir_msInfo_8_bits_isPrefetch = mshrCtl_msInfo_8_bits_isPrefetch;
  assign dir_msInfo_8_bits_param = mshrCtl_msInfo_8_bits_param;
  assign dir_msInfo_8_bits_mergeA = mshrCtl_msInfo_8_bits_mergeA;
  assign dir_msInfo_8_bits_w_grantfirst = mshrCtl_msInfo_8_bits_w_grantfirst;
  assign dir_msInfo_8_bits_s_release = mshrCtl_msInfo_8_bits_s_release;
  assign dir_msInfo_8_bits_s_refill = mshrCtl_msInfo_8_bits_s_refill;
  assign dir_msInfo_8_bits_s_cmoresp = mshrCtl_msInfo_8_bits_s_cmoresp;
  assign dir_msInfo_8_bits_s_cmometaw = mshrCtl_msInfo_8_bits_s_cmometaw;
  assign dir_msInfo_8_bits_w_releaseack = mshrCtl_msInfo_8_bits_w_releaseack;
  assign dir_msInfo_8_bits_w_replResp = mshrCtl_msInfo_8_bits_w_replResp;
  assign dir_msInfo_8_bits_w_rprobeacklast = mshrCtl_msInfo_8_bits_w_rprobeacklast;
  assign dir_msInfo_8_bits_replaceData = mshrCtl_msInfo_8_bits_replaceData;
  assign dir_msInfo_8_bits_releaseToClean = mshrCtl_msInfo_8_bits_releaseToClean;
  assign dir_msInfo_9_valid = mshrCtl_msInfo_9_valid;
  assign dir_msInfo_9_bits_channel = mshrCtl_msInfo_9_bits_channel;
  assign dir_msInfo_9_bits_set = mshrCtl_msInfo_9_bits_set;
  assign dir_msInfo_9_bits_way = mshrCtl_msInfo_9_bits_way;
  assign dir_msInfo_9_bits_reqTag = mshrCtl_msInfo_9_bits_reqTag;
  assign dir_msInfo_9_bits_willFree = mshrCtl_msInfo_9_bits_willFree;
  assign dir_msInfo_9_bits_aliasTask = mshrCtl_msInfo_9_bits_aliasTask;
  assign dir_msInfo_9_bits_needRelease = mshrCtl_msInfo_9_bits_needRelease;
  assign dir_msInfo_9_bits_blockRefill = mshrCtl_msInfo_9_bits_blockRefill;
  assign dir_msInfo_9_bits_meta_dirty = mshrCtl_msInfo_9_bits_meta_dirty;
  assign dir_msInfo_9_bits_meta_state = mshrCtl_msInfo_9_bits_meta_state;
  assign dir_msInfo_9_bits_meta_clients = mshrCtl_msInfo_9_bits_meta_clients;
  assign dir_msInfo_9_bits_meta_alias = mshrCtl_msInfo_9_bits_meta_alias;
  assign dir_msInfo_9_bits_meta_prefetch = mshrCtl_msInfo_9_bits_meta_prefetch;
  assign dir_msInfo_9_bits_meta_prefetchSrc = mshrCtl_msInfo_9_bits_meta_prefetchSrc;
  assign dir_msInfo_9_bits_meta_accessed = mshrCtl_msInfo_9_bits_meta_accessed;
  assign dir_msInfo_9_bits_meta_tagErr = mshrCtl_msInfo_9_bits_meta_tagErr;
  assign dir_msInfo_9_bits_meta_dataErr = mshrCtl_msInfo_9_bits_meta_dataErr;
  assign dir_msInfo_9_bits_metaTag = mshrCtl_msInfo_9_bits_metaTag;
  assign dir_msInfo_9_bits_dirHit = mshrCtl_msInfo_9_bits_dirHit;
  assign dir_msInfo_9_bits_isAcqOrPrefetch = mshrCtl_msInfo_9_bits_isAcqOrPrefetch;
  assign dir_msInfo_9_bits_isPrefetch = mshrCtl_msInfo_9_bits_isPrefetch;
  assign dir_msInfo_9_bits_param = mshrCtl_msInfo_9_bits_param;
  assign dir_msInfo_9_bits_mergeA = mshrCtl_msInfo_9_bits_mergeA;
  assign dir_msInfo_9_bits_w_grantfirst = mshrCtl_msInfo_9_bits_w_grantfirst;
  assign dir_msInfo_9_bits_s_release = mshrCtl_msInfo_9_bits_s_release;
  assign dir_msInfo_9_bits_s_refill = mshrCtl_msInfo_9_bits_s_refill;
  assign dir_msInfo_9_bits_s_cmoresp = mshrCtl_msInfo_9_bits_s_cmoresp;
  assign dir_msInfo_9_bits_s_cmometaw = mshrCtl_msInfo_9_bits_s_cmometaw;
  assign dir_msInfo_9_bits_w_releaseack = mshrCtl_msInfo_9_bits_w_releaseack;
  assign dir_msInfo_9_bits_w_replResp = mshrCtl_msInfo_9_bits_w_replResp;
  assign dir_msInfo_9_bits_w_rprobeacklast = mshrCtl_msInfo_9_bits_w_rprobeacklast;
  assign dir_msInfo_9_bits_replaceData = mshrCtl_msInfo_9_bits_replaceData;
  assign dir_msInfo_9_bits_releaseToClean = mshrCtl_msInfo_9_bits_releaseToClean;
  assign dir_msInfo_10_valid = mshrCtl_msInfo_10_valid;
  assign dir_msInfo_10_bits_channel = mshrCtl_msInfo_10_bits_channel;
  assign dir_msInfo_10_bits_set = mshrCtl_msInfo_10_bits_set;
  assign dir_msInfo_10_bits_way = mshrCtl_msInfo_10_bits_way;
  assign dir_msInfo_10_bits_reqTag = mshrCtl_msInfo_10_bits_reqTag;
  assign dir_msInfo_10_bits_willFree = mshrCtl_msInfo_10_bits_willFree;
  assign dir_msInfo_10_bits_aliasTask = mshrCtl_msInfo_10_bits_aliasTask;
  assign dir_msInfo_10_bits_needRelease = mshrCtl_msInfo_10_bits_needRelease;
  assign dir_msInfo_10_bits_blockRefill = mshrCtl_msInfo_10_bits_blockRefill;
  assign dir_msInfo_10_bits_meta_dirty = mshrCtl_msInfo_10_bits_meta_dirty;
  assign dir_msInfo_10_bits_meta_state = mshrCtl_msInfo_10_bits_meta_state;
  assign dir_msInfo_10_bits_meta_clients = mshrCtl_msInfo_10_bits_meta_clients;
  assign dir_msInfo_10_bits_meta_alias = mshrCtl_msInfo_10_bits_meta_alias;
  assign dir_msInfo_10_bits_meta_prefetch = mshrCtl_msInfo_10_bits_meta_prefetch;
  assign dir_msInfo_10_bits_meta_prefetchSrc = mshrCtl_msInfo_10_bits_meta_prefetchSrc;
  assign dir_msInfo_10_bits_meta_accessed = mshrCtl_msInfo_10_bits_meta_accessed;
  assign dir_msInfo_10_bits_meta_tagErr = mshrCtl_msInfo_10_bits_meta_tagErr;
  assign dir_msInfo_10_bits_meta_dataErr = mshrCtl_msInfo_10_bits_meta_dataErr;
  assign dir_msInfo_10_bits_metaTag = mshrCtl_msInfo_10_bits_metaTag;
  assign dir_msInfo_10_bits_dirHit = mshrCtl_msInfo_10_bits_dirHit;
  assign dir_msInfo_10_bits_isAcqOrPrefetch = mshrCtl_msInfo_10_bits_isAcqOrPrefetch;
  assign dir_msInfo_10_bits_isPrefetch = mshrCtl_msInfo_10_bits_isPrefetch;
  assign dir_msInfo_10_bits_param = mshrCtl_msInfo_10_bits_param;
  assign dir_msInfo_10_bits_mergeA = mshrCtl_msInfo_10_bits_mergeA;
  assign dir_msInfo_10_bits_w_grantfirst = mshrCtl_msInfo_10_bits_w_grantfirst;
  assign dir_msInfo_10_bits_s_release = mshrCtl_msInfo_10_bits_s_release;
  assign dir_msInfo_10_bits_s_refill = mshrCtl_msInfo_10_bits_s_refill;
  assign dir_msInfo_10_bits_s_cmoresp = mshrCtl_msInfo_10_bits_s_cmoresp;
  assign dir_msInfo_10_bits_s_cmometaw = mshrCtl_msInfo_10_bits_s_cmometaw;
  assign dir_msInfo_10_bits_w_releaseack = mshrCtl_msInfo_10_bits_w_releaseack;
  assign dir_msInfo_10_bits_w_replResp = mshrCtl_msInfo_10_bits_w_replResp;
  assign dir_msInfo_10_bits_w_rprobeacklast = mshrCtl_msInfo_10_bits_w_rprobeacklast;
  assign dir_msInfo_10_bits_replaceData = mshrCtl_msInfo_10_bits_replaceData;
  assign dir_msInfo_10_bits_releaseToClean = mshrCtl_msInfo_10_bits_releaseToClean;
  assign dir_msInfo_11_valid = mshrCtl_msInfo_11_valid;
  assign dir_msInfo_11_bits_channel = mshrCtl_msInfo_11_bits_channel;
  assign dir_msInfo_11_bits_set = mshrCtl_msInfo_11_bits_set;
  assign dir_msInfo_11_bits_way = mshrCtl_msInfo_11_bits_way;
  assign dir_msInfo_11_bits_reqTag = mshrCtl_msInfo_11_bits_reqTag;
  assign dir_msInfo_11_bits_willFree = mshrCtl_msInfo_11_bits_willFree;
  assign dir_msInfo_11_bits_aliasTask = mshrCtl_msInfo_11_bits_aliasTask;
  assign dir_msInfo_11_bits_needRelease = mshrCtl_msInfo_11_bits_needRelease;
  assign dir_msInfo_11_bits_blockRefill = mshrCtl_msInfo_11_bits_blockRefill;
  assign dir_msInfo_11_bits_meta_dirty = mshrCtl_msInfo_11_bits_meta_dirty;
  assign dir_msInfo_11_bits_meta_state = mshrCtl_msInfo_11_bits_meta_state;
  assign dir_msInfo_11_bits_meta_clients = mshrCtl_msInfo_11_bits_meta_clients;
  assign dir_msInfo_11_bits_meta_alias = mshrCtl_msInfo_11_bits_meta_alias;
  assign dir_msInfo_11_bits_meta_prefetch = mshrCtl_msInfo_11_bits_meta_prefetch;
  assign dir_msInfo_11_bits_meta_prefetchSrc = mshrCtl_msInfo_11_bits_meta_prefetchSrc;
  assign dir_msInfo_11_bits_meta_accessed = mshrCtl_msInfo_11_bits_meta_accessed;
  assign dir_msInfo_11_bits_meta_tagErr = mshrCtl_msInfo_11_bits_meta_tagErr;
  assign dir_msInfo_11_bits_meta_dataErr = mshrCtl_msInfo_11_bits_meta_dataErr;
  assign dir_msInfo_11_bits_metaTag = mshrCtl_msInfo_11_bits_metaTag;
  assign dir_msInfo_11_bits_dirHit = mshrCtl_msInfo_11_bits_dirHit;
  assign dir_msInfo_11_bits_isAcqOrPrefetch = mshrCtl_msInfo_11_bits_isAcqOrPrefetch;
  assign dir_msInfo_11_bits_isPrefetch = mshrCtl_msInfo_11_bits_isPrefetch;
  assign dir_msInfo_11_bits_param = mshrCtl_msInfo_11_bits_param;
  assign dir_msInfo_11_bits_mergeA = mshrCtl_msInfo_11_bits_mergeA;
  assign dir_msInfo_11_bits_w_grantfirst = mshrCtl_msInfo_11_bits_w_grantfirst;
  assign dir_msInfo_11_bits_s_release = mshrCtl_msInfo_11_bits_s_release;
  assign dir_msInfo_11_bits_s_refill = mshrCtl_msInfo_11_bits_s_refill;
  assign dir_msInfo_11_bits_s_cmoresp = mshrCtl_msInfo_11_bits_s_cmoresp;
  assign dir_msInfo_11_bits_s_cmometaw = mshrCtl_msInfo_11_bits_s_cmometaw;
  assign dir_msInfo_11_bits_w_releaseack = mshrCtl_msInfo_11_bits_w_releaseack;
  assign dir_msInfo_11_bits_w_replResp = mshrCtl_msInfo_11_bits_w_replResp;
  assign dir_msInfo_11_bits_w_rprobeacklast = mshrCtl_msInfo_11_bits_w_rprobeacklast;
  assign dir_msInfo_11_bits_replaceData = mshrCtl_msInfo_11_bits_replaceData;
  assign dir_msInfo_11_bits_releaseToClean = mshrCtl_msInfo_11_bits_releaseToClean;
  assign dir_msInfo_12_valid = mshrCtl_msInfo_12_valid;
  assign dir_msInfo_12_bits_channel = mshrCtl_msInfo_12_bits_channel;
  assign dir_msInfo_12_bits_set = mshrCtl_msInfo_12_bits_set;
  assign dir_msInfo_12_bits_way = mshrCtl_msInfo_12_bits_way;
  assign dir_msInfo_12_bits_reqTag = mshrCtl_msInfo_12_bits_reqTag;
  assign dir_msInfo_12_bits_willFree = mshrCtl_msInfo_12_bits_willFree;
  assign dir_msInfo_12_bits_aliasTask = mshrCtl_msInfo_12_bits_aliasTask;
  assign dir_msInfo_12_bits_needRelease = mshrCtl_msInfo_12_bits_needRelease;
  assign dir_msInfo_12_bits_blockRefill = mshrCtl_msInfo_12_bits_blockRefill;
  assign dir_msInfo_12_bits_meta_dirty = mshrCtl_msInfo_12_bits_meta_dirty;
  assign dir_msInfo_12_bits_meta_state = mshrCtl_msInfo_12_bits_meta_state;
  assign dir_msInfo_12_bits_meta_clients = mshrCtl_msInfo_12_bits_meta_clients;
  assign dir_msInfo_12_bits_meta_alias = mshrCtl_msInfo_12_bits_meta_alias;
  assign dir_msInfo_12_bits_meta_prefetch = mshrCtl_msInfo_12_bits_meta_prefetch;
  assign dir_msInfo_12_bits_meta_prefetchSrc = mshrCtl_msInfo_12_bits_meta_prefetchSrc;
  assign dir_msInfo_12_bits_meta_accessed = mshrCtl_msInfo_12_bits_meta_accessed;
  assign dir_msInfo_12_bits_meta_tagErr = mshrCtl_msInfo_12_bits_meta_tagErr;
  assign dir_msInfo_12_bits_meta_dataErr = mshrCtl_msInfo_12_bits_meta_dataErr;
  assign dir_msInfo_12_bits_metaTag = mshrCtl_msInfo_12_bits_metaTag;
  assign dir_msInfo_12_bits_dirHit = mshrCtl_msInfo_12_bits_dirHit;
  assign dir_msInfo_12_bits_isAcqOrPrefetch = mshrCtl_msInfo_12_bits_isAcqOrPrefetch;
  assign dir_msInfo_12_bits_isPrefetch = mshrCtl_msInfo_12_bits_isPrefetch;
  assign dir_msInfo_12_bits_param = mshrCtl_msInfo_12_bits_param;
  assign dir_msInfo_12_bits_mergeA = mshrCtl_msInfo_12_bits_mergeA;
  assign dir_msInfo_12_bits_w_grantfirst = mshrCtl_msInfo_12_bits_w_grantfirst;
  assign dir_msInfo_12_bits_s_release = mshrCtl_msInfo_12_bits_s_release;
  assign dir_msInfo_12_bits_s_refill = mshrCtl_msInfo_12_bits_s_refill;
  assign dir_msInfo_12_bits_s_cmoresp = mshrCtl_msInfo_12_bits_s_cmoresp;
  assign dir_msInfo_12_bits_s_cmometaw = mshrCtl_msInfo_12_bits_s_cmometaw;
  assign dir_msInfo_12_bits_w_releaseack = mshrCtl_msInfo_12_bits_w_releaseack;
  assign dir_msInfo_12_bits_w_replResp = mshrCtl_msInfo_12_bits_w_replResp;
  assign dir_msInfo_12_bits_w_rprobeacklast = mshrCtl_msInfo_12_bits_w_rprobeacklast;
  assign dir_msInfo_12_bits_replaceData = mshrCtl_msInfo_12_bits_replaceData;
  assign dir_msInfo_12_bits_releaseToClean = mshrCtl_msInfo_12_bits_releaseToClean;
  assign dir_msInfo_13_valid = mshrCtl_msInfo_13_valid;
  assign dir_msInfo_13_bits_channel = mshrCtl_msInfo_13_bits_channel;
  assign dir_msInfo_13_bits_set = mshrCtl_msInfo_13_bits_set;
  assign dir_msInfo_13_bits_way = mshrCtl_msInfo_13_bits_way;
  assign dir_msInfo_13_bits_reqTag = mshrCtl_msInfo_13_bits_reqTag;
  assign dir_msInfo_13_bits_willFree = mshrCtl_msInfo_13_bits_willFree;
  assign dir_msInfo_13_bits_aliasTask = mshrCtl_msInfo_13_bits_aliasTask;
  assign dir_msInfo_13_bits_needRelease = mshrCtl_msInfo_13_bits_needRelease;
  assign dir_msInfo_13_bits_blockRefill = mshrCtl_msInfo_13_bits_blockRefill;
  assign dir_msInfo_13_bits_meta_dirty = mshrCtl_msInfo_13_bits_meta_dirty;
  assign dir_msInfo_13_bits_meta_state = mshrCtl_msInfo_13_bits_meta_state;
  assign dir_msInfo_13_bits_meta_clients = mshrCtl_msInfo_13_bits_meta_clients;
  assign dir_msInfo_13_bits_meta_alias = mshrCtl_msInfo_13_bits_meta_alias;
  assign dir_msInfo_13_bits_meta_prefetch = mshrCtl_msInfo_13_bits_meta_prefetch;
  assign dir_msInfo_13_bits_meta_prefetchSrc = mshrCtl_msInfo_13_bits_meta_prefetchSrc;
  assign dir_msInfo_13_bits_meta_accessed = mshrCtl_msInfo_13_bits_meta_accessed;
  assign dir_msInfo_13_bits_meta_tagErr = mshrCtl_msInfo_13_bits_meta_tagErr;
  assign dir_msInfo_13_bits_meta_dataErr = mshrCtl_msInfo_13_bits_meta_dataErr;
  assign dir_msInfo_13_bits_metaTag = mshrCtl_msInfo_13_bits_metaTag;
  assign dir_msInfo_13_bits_dirHit = mshrCtl_msInfo_13_bits_dirHit;
  assign dir_msInfo_13_bits_isAcqOrPrefetch = mshrCtl_msInfo_13_bits_isAcqOrPrefetch;
  assign dir_msInfo_13_bits_isPrefetch = mshrCtl_msInfo_13_bits_isPrefetch;
  assign dir_msInfo_13_bits_param = mshrCtl_msInfo_13_bits_param;
  assign dir_msInfo_13_bits_mergeA = mshrCtl_msInfo_13_bits_mergeA;
  assign dir_msInfo_13_bits_w_grantfirst = mshrCtl_msInfo_13_bits_w_grantfirst;
  assign dir_msInfo_13_bits_s_release = mshrCtl_msInfo_13_bits_s_release;
  assign dir_msInfo_13_bits_s_refill = mshrCtl_msInfo_13_bits_s_refill;
  assign dir_msInfo_13_bits_s_cmoresp = mshrCtl_msInfo_13_bits_s_cmoresp;
  assign dir_msInfo_13_bits_s_cmometaw = mshrCtl_msInfo_13_bits_s_cmometaw;
  assign dir_msInfo_13_bits_w_releaseack = mshrCtl_msInfo_13_bits_w_releaseack;
  assign dir_msInfo_13_bits_w_replResp = mshrCtl_msInfo_13_bits_w_replResp;
  assign dir_msInfo_13_bits_w_rprobeacklast = mshrCtl_msInfo_13_bits_w_rprobeacklast;
  assign dir_msInfo_13_bits_replaceData = mshrCtl_msInfo_13_bits_replaceData;
  assign dir_msInfo_13_bits_releaseToClean = mshrCtl_msInfo_13_bits_releaseToClean;
  assign dir_msInfo_14_valid = mshrCtl_msInfo_14_valid;
  assign dir_msInfo_14_bits_channel = mshrCtl_msInfo_14_bits_channel;
  assign dir_msInfo_14_bits_set = mshrCtl_msInfo_14_bits_set;
  assign dir_msInfo_14_bits_way = mshrCtl_msInfo_14_bits_way;
  assign dir_msInfo_14_bits_reqTag = mshrCtl_msInfo_14_bits_reqTag;
  assign dir_msInfo_14_bits_willFree = mshrCtl_msInfo_14_bits_willFree;
  assign dir_msInfo_14_bits_aliasTask = mshrCtl_msInfo_14_bits_aliasTask;
  assign dir_msInfo_14_bits_needRelease = mshrCtl_msInfo_14_bits_needRelease;
  assign dir_msInfo_14_bits_blockRefill = mshrCtl_msInfo_14_bits_blockRefill;
  assign dir_msInfo_14_bits_meta_dirty = mshrCtl_msInfo_14_bits_meta_dirty;
  assign dir_msInfo_14_bits_meta_state = mshrCtl_msInfo_14_bits_meta_state;
  assign dir_msInfo_14_bits_meta_clients = mshrCtl_msInfo_14_bits_meta_clients;
  assign dir_msInfo_14_bits_meta_alias = mshrCtl_msInfo_14_bits_meta_alias;
  assign dir_msInfo_14_bits_meta_prefetch = mshrCtl_msInfo_14_bits_meta_prefetch;
  assign dir_msInfo_14_bits_meta_prefetchSrc = mshrCtl_msInfo_14_bits_meta_prefetchSrc;
  assign dir_msInfo_14_bits_meta_accessed = mshrCtl_msInfo_14_bits_meta_accessed;
  assign dir_msInfo_14_bits_meta_tagErr = mshrCtl_msInfo_14_bits_meta_tagErr;
  assign dir_msInfo_14_bits_meta_dataErr = mshrCtl_msInfo_14_bits_meta_dataErr;
  assign dir_msInfo_14_bits_metaTag = mshrCtl_msInfo_14_bits_metaTag;
  assign dir_msInfo_14_bits_dirHit = mshrCtl_msInfo_14_bits_dirHit;
  assign dir_msInfo_14_bits_isAcqOrPrefetch = mshrCtl_msInfo_14_bits_isAcqOrPrefetch;
  assign dir_msInfo_14_bits_isPrefetch = mshrCtl_msInfo_14_bits_isPrefetch;
  assign dir_msInfo_14_bits_param = mshrCtl_msInfo_14_bits_param;
  assign dir_msInfo_14_bits_mergeA = mshrCtl_msInfo_14_bits_mergeA;
  assign dir_msInfo_14_bits_w_grantfirst = mshrCtl_msInfo_14_bits_w_grantfirst;
  assign dir_msInfo_14_bits_s_release = mshrCtl_msInfo_14_bits_s_release;
  assign dir_msInfo_14_bits_s_refill = mshrCtl_msInfo_14_bits_s_refill;
  assign dir_msInfo_14_bits_s_cmoresp = mshrCtl_msInfo_14_bits_s_cmoresp;
  assign dir_msInfo_14_bits_s_cmometaw = mshrCtl_msInfo_14_bits_s_cmometaw;
  assign dir_msInfo_14_bits_w_releaseack = mshrCtl_msInfo_14_bits_w_releaseack;
  assign dir_msInfo_14_bits_w_replResp = mshrCtl_msInfo_14_bits_w_replResp;
  assign dir_msInfo_14_bits_w_rprobeacklast = mshrCtl_msInfo_14_bits_w_rprobeacklast;
  assign dir_msInfo_14_bits_replaceData = mshrCtl_msInfo_14_bits_replaceData;
  assign dir_msInfo_14_bits_releaseToClean = mshrCtl_msInfo_14_bits_releaseToClean;
  assign dir_msInfo_15_valid = mshrCtl_msInfo_15_valid;
  assign dir_msInfo_15_bits_channel = mshrCtl_msInfo_15_bits_channel;
  assign dir_msInfo_15_bits_set = mshrCtl_msInfo_15_bits_set;
  assign dir_msInfo_15_bits_way = mshrCtl_msInfo_15_bits_way;
  assign dir_msInfo_15_bits_reqTag = mshrCtl_msInfo_15_bits_reqTag;
  assign dir_msInfo_15_bits_willFree = mshrCtl_msInfo_15_bits_willFree;
  assign dir_msInfo_15_bits_aliasTask = mshrCtl_msInfo_15_bits_aliasTask;
  assign dir_msInfo_15_bits_needRelease = mshrCtl_msInfo_15_bits_needRelease;
  assign dir_msInfo_15_bits_blockRefill = mshrCtl_msInfo_15_bits_blockRefill;
  assign dir_msInfo_15_bits_meta_dirty = mshrCtl_msInfo_15_bits_meta_dirty;
  assign dir_msInfo_15_bits_meta_state = mshrCtl_msInfo_15_bits_meta_state;
  assign dir_msInfo_15_bits_meta_clients = mshrCtl_msInfo_15_bits_meta_clients;
  assign dir_msInfo_15_bits_meta_alias = mshrCtl_msInfo_15_bits_meta_alias;
  assign dir_msInfo_15_bits_meta_prefetch = mshrCtl_msInfo_15_bits_meta_prefetch;
  assign dir_msInfo_15_bits_meta_prefetchSrc = mshrCtl_msInfo_15_bits_meta_prefetchSrc;
  assign dir_msInfo_15_bits_meta_accessed = mshrCtl_msInfo_15_bits_meta_accessed;
  assign dir_msInfo_15_bits_meta_tagErr = mshrCtl_msInfo_15_bits_meta_tagErr;
  assign dir_msInfo_15_bits_meta_dataErr = mshrCtl_msInfo_15_bits_meta_dataErr;
  assign dir_msInfo_15_bits_metaTag = mshrCtl_msInfo_15_bits_metaTag;
  assign dir_msInfo_15_bits_dirHit = mshrCtl_msInfo_15_bits_dirHit;
  assign dir_msInfo_15_bits_isAcqOrPrefetch = mshrCtl_msInfo_15_bits_isAcqOrPrefetch;
  assign dir_msInfo_15_bits_isPrefetch = mshrCtl_msInfo_15_bits_isPrefetch;
  assign dir_msInfo_15_bits_param = mshrCtl_msInfo_15_bits_param;
  assign dir_msInfo_15_bits_mergeA = mshrCtl_msInfo_15_bits_mergeA;
  assign dir_msInfo_15_bits_w_grantfirst = mshrCtl_msInfo_15_bits_w_grantfirst;
  assign dir_msInfo_15_bits_s_release = mshrCtl_msInfo_15_bits_s_release;
  assign dir_msInfo_15_bits_s_refill = mshrCtl_msInfo_15_bits_s_refill;
  assign dir_msInfo_15_bits_s_cmoresp = mshrCtl_msInfo_15_bits_s_cmoresp;
  assign dir_msInfo_15_bits_s_cmometaw = mshrCtl_msInfo_15_bits_s_cmometaw;
  assign dir_msInfo_15_bits_w_releaseack = mshrCtl_msInfo_15_bits_w_releaseack;
  assign dir_msInfo_15_bits_w_replResp = mshrCtl_msInfo_15_bits_w_replResp;
  assign dir_msInfo_15_bits_w_rprobeacklast = mshrCtl_msInfo_15_bits_w_rprobeacklast;
  assign dir_msInfo_15_bits_replaceData = mshrCtl_msInfo_15_bits_replaceData;
  assign dir_msInfo_15_bits_releaseToClean = mshrCtl_msInfo_15_bits_releaseToClean;
  assign ds_en = mainPipe_toDS_en_s3;
  assign ds_req_valid = mainPipe_toDS_req_s3_valid;
  assign ds_req_bits_way = mainPipe_toDS_req_s3_bits_way;
  assign ds_req_bits_set = mainPipe_toDS_req_s3_bits_set;
  assign ds_req_bits_wen = mainPipe_toDS_req_s3_bits_wen;
  assign ds_wdata_data = mainPipe_toDS_wdata_s3_data;
  // END GENERATED(to_dir_ds)

  // BEGIN GENERATED(children) —— scripts/gen_l2_slice.py 生成
  // SinkA：上层 A 通道（Get/Acquire/Hint/CMO）与 L2 预取请求的入口，转成内部 task 送 RequestBuffer
  SinkA sinkA (
    .clock                        (clock),
    .reset                        (reset),
    .io_a_ready                   (io_in_a_ready),
    .io_a_valid                   (io_in_a_valid),
    .io_a_bits_opcode             (io_in_a_bits_opcode),
    .io_a_bits_param              (io_in_a_bits_param),
    .io_a_bits_size               (io_in_a_bits_size),
    .io_a_bits_source             (io_in_a_bits_source),
    .io_a_bits_address            (io_in_a_bits_address),
    .io_a_bits_user_reqSource     (io_in_a_bits_user_reqSource),
    .io_a_bits_user_alias         (io_in_a_bits_user_alias),
    .io_a_bits_user_vaddr         (io_in_a_bits_user_vaddr),
    .io_a_bits_user_needHint      (io_in_a_bits_user_needHint),
    .io_a_bits_echo_isKeyword     (io_in_a_bits_echo_isKeyword),
    .io_a_bits_corrupt            (io_in_a_bits_corrupt),
    .io_prefetchReq_ready         (sinkA_prefetchReq_ready),
    .io_prefetchReq_valid         (io_prefetch_req_valid),
    .io_prefetchReq_bits_tag      (io_prefetch_req_bits_tag),
    .io_prefetchReq_bits_set      (io_prefetch_req_bits_set),
    .io_prefetchReq_bits_vaddr    (io_prefetch_req_bits_vaddr),
    .io_prefetchReq_bits_needT    (io_prefetch_req_bits_needT),
    .io_prefetchReq_bits_source   (io_prefetch_req_bits_source),
    .io_prefetchReq_bits_pfSource (io_prefetch_req_bits_pfSource),
    .io_task_ready                (reqBuf_in_ready),
    .io_task_valid                (sinkA_task_valid),
    .io_task_bits_set             (sinkA_task_bits_set),
    .io_task_bits_tag             (sinkA_task_bits_tag),
    .io_task_bits_off             (sinkA_task_bits_off),
    .io_task_bits_alias           (sinkA_task_bits_alias),
    .io_task_bits_vaddr           (sinkA_task_bits_vaddr),
    .io_task_bits_isKeyword       (sinkA_task_bits_isKeyword),
    .io_task_bits_opcode          (sinkA_task_bits_opcode),
    .io_task_bits_param           (sinkA_task_bits_param),
    .io_task_bits_size            (sinkA_task_bits_size),
    .io_task_bits_sourceId        (sinkA_task_bits_sourceId),
    .io_task_bits_corrupt         (sinkA_task_bits_corrupt),
    .io_task_bits_fromL2pft       (sinkA_task_bits_fromL2pft),
    .io_task_bits_needHint        (sinkA_task_bits_needHint),
    .io_task_bits_reqSource       (sinkA_task_bits_reqSource)
  );

  // SinkC：上层 C 通道（Release/ProbeAck）入口；数据写 releaseBuf/refillBuf，task 送 RequestArb，ProbeAck 响应送 MSHRCtl
  SinkC sinkC (
    .clock                                      (clock),
    .reset                                      (reset),
    .io_c_ready                                 (io_in_c_ready),
    .io_c_valid                                 (io_in_c_valid),
    .io_c_bits_opcode                           (io_in_c_bits_opcode),
    .io_c_bits_param                            (io_in_c_bits_param),
    .io_c_bits_size                             (io_in_c_bits_size),
    .io_c_bits_source                           (io_in_c_bits_source),
    .io_c_bits_address                          (io_in_c_bits_address),
    .io_c_bits_data                             (io_in_c_bits_data),
    .io_c_bits_corrupt                          (io_in_c_bits_corrupt),
    .io_task_ready                              (reqArb_sinkC_ready),
    .io_task_valid                              (sinkC_task_valid),
    .io_task_bits_channel                       (sinkC_task_bits_channel),
    .io_task_bits_txChannel                     (sinkC_task_bits_txChannel),
    .io_task_bits_set                           (sinkC_task_bits_set),
    .io_task_bits_tag                           (sinkC_task_bits_tag),
    .io_task_bits_off                           (sinkC_task_bits_off),
    .io_task_bits_alias                         (sinkC_task_bits_alias),
    .io_task_bits_vaddr                         (sinkC_task_bits_vaddr),
    .io_task_bits_isKeyword                     (sinkC_task_bits_isKeyword),
    .io_task_bits_opcode                        (sinkC_task_bits_opcode),
    .io_task_bits_param                         (sinkC_task_bits_param),
    .io_task_bits_size                          (sinkC_task_bits_size),
    .io_task_bits_sourceId                      (sinkC_task_bits_sourceId),
    .io_task_bits_bufIdx                        (sinkC_task_bits_bufIdx),
    .io_task_bits_needProbeAckData              (sinkC_task_bits_needProbeAckData),
    .io_task_bits_denied                        (sinkC_task_bits_denied),
    .io_task_bits_corrupt                       (sinkC_task_bits_corrupt),
    .io_task_bits_mshrTask                      (sinkC_task_bits_mshrTask),
    .io_task_bits_mshrId                        (sinkC_task_bits_mshrId),
    .io_task_bits_aliasTask                     (sinkC_task_bits_aliasTask),
    .io_task_bits_useProbeData                  (sinkC_task_bits_useProbeData),
    .io_task_bits_mshrRetry                     (sinkC_task_bits_mshrRetry),
    .io_task_bits_readProbeDataDown             (sinkC_task_bits_readProbeDataDown),
    .io_task_bits_fromL2pft                     (sinkC_task_bits_fromL2pft),
    .io_task_bits_needHint                      (sinkC_task_bits_needHint),
    .io_task_bits_dirty                         (sinkC_task_bits_dirty),
    .io_task_bits_way                           (sinkC_task_bits_way),
    .io_task_bits_meta_dirty                    (sinkC_task_bits_meta_dirty),
    .io_task_bits_meta_state                    (sinkC_task_bits_meta_state),
    .io_task_bits_meta_clients                  (sinkC_task_bits_meta_clients),
    .io_task_bits_meta_alias                    (sinkC_task_bits_meta_alias),
    .io_task_bits_meta_prefetch                 (sinkC_task_bits_meta_prefetch),
    .io_task_bits_meta_prefetchSrc              (sinkC_task_bits_meta_prefetchSrc),
    .io_task_bits_meta_accessed                 (sinkC_task_bits_meta_accessed),
    .io_task_bits_meta_tagErr                   (sinkC_task_bits_meta_tagErr),
    .io_task_bits_meta_dataErr                  (sinkC_task_bits_meta_dataErr),
    .io_task_bits_metaWen                       (sinkC_task_bits_metaWen),
    .io_task_bits_tagWen                        (sinkC_task_bits_tagWen),
    .io_task_bits_dsWen                         (sinkC_task_bits_dsWen),
    .io_task_bits_wayMask                       (sinkC_task_bits_wayMask),
    .io_task_bits_replTask                      (sinkC_task_bits_replTask),
    .io_task_bits_cmoTask                       (sinkC_task_bits_cmoTask),
    .io_task_bits_cmoAll                        (sinkC_task_bits_cmoAll),
    .io_task_bits_reqSource                     (sinkC_task_bits_reqSource),
    .io_task_bits_mergeA                        (sinkC_task_bits_mergeA),
    .io_task_bits_aMergeTask_off                (sinkC_task_bits_aMergeTask_off),
    .io_task_bits_aMergeTask_alias              (sinkC_task_bits_aMergeTask_alias),
    .io_task_bits_aMergeTask_vaddr              (sinkC_task_bits_aMergeTask_vaddr),
    .io_task_bits_aMergeTask_isKeyword          (sinkC_task_bits_aMergeTask_isKeyword),
    .io_task_bits_aMergeTask_opcode             (sinkC_task_bits_aMergeTask_opcode),
    .io_task_bits_aMergeTask_param              (sinkC_task_bits_aMergeTask_param),
    .io_task_bits_aMergeTask_sourceId           (sinkC_task_bits_aMergeTask_sourceId),
    .io_task_bits_aMergeTask_meta_dirty         (sinkC_task_bits_aMergeTask_meta_dirty),
    .io_task_bits_aMergeTask_meta_state         (sinkC_task_bits_aMergeTask_meta_state),
    .io_task_bits_aMergeTask_meta_clients       (sinkC_task_bits_aMergeTask_meta_clients),
    .io_task_bits_aMergeTask_meta_alias         (sinkC_task_bits_aMergeTask_meta_alias),
    .io_task_bits_aMergeTask_meta_prefetch      (sinkC_task_bits_aMergeTask_meta_prefetch),
    .io_task_bits_aMergeTask_meta_prefetchSrc   (sinkC_task_bits_aMergeTask_meta_prefetchSrc),
    .io_task_bits_aMergeTask_meta_accessed      (sinkC_task_bits_aMergeTask_meta_accessed),
    .io_task_bits_aMergeTask_meta_tagErr        (sinkC_task_bits_aMergeTask_meta_tagErr),
    .io_task_bits_aMergeTask_meta_dataErr       (sinkC_task_bits_aMergeTask_meta_dataErr),
    .io_task_bits_snpHitRelease                 (sinkC_task_bits_snpHitRelease),
    .io_task_bits_snpHitReleaseToInval          (sinkC_task_bits_snpHitReleaseToInval),
    .io_task_bits_snpHitReleaseToClean          (sinkC_task_bits_snpHitReleaseToClean),
    .io_task_bits_snpHitReleaseWithData         (sinkC_task_bits_snpHitReleaseWithData),
    .io_task_bits_snpHitReleaseIdx              (sinkC_task_bits_snpHitReleaseIdx),
    .io_task_bits_snpHitReleaseMeta_dirty       (sinkC_task_bits_snpHitReleaseMeta_dirty),
    .io_task_bits_snpHitReleaseMeta_state       (sinkC_task_bits_snpHitReleaseMeta_state),
    .io_task_bits_snpHitReleaseMeta_clients     (sinkC_task_bits_snpHitReleaseMeta_clients),
    .io_task_bits_snpHitReleaseMeta_alias       (sinkC_task_bits_snpHitReleaseMeta_alias),
    .io_task_bits_snpHitReleaseMeta_prefetch    (sinkC_task_bits_snpHitReleaseMeta_prefetch),
    .io_task_bits_snpHitReleaseMeta_prefetchSrc (sinkC_task_bits_snpHitReleaseMeta_prefetchSrc),
    .io_task_bits_snpHitReleaseMeta_accessed    (sinkC_task_bits_snpHitReleaseMeta_accessed),
    .io_task_bits_snpHitReleaseMeta_tagErr      (sinkC_task_bits_snpHitReleaseMeta_tagErr),
    .io_task_bits_snpHitReleaseMeta_dataErr     (sinkC_task_bits_snpHitReleaseMeta_dataErr),
    .io_task_bits_tgtID                         (sinkC_task_bits_tgtID),
    .io_task_bits_srcID                         (sinkC_task_bits_srcID),
    .io_task_bits_txnID                         (sinkC_task_bits_txnID),
    .io_task_bits_homeNID                       (sinkC_task_bits_homeNID),
    .io_task_bits_dbID                          (sinkC_task_bits_dbID),
    .io_task_bits_fwdNID                        (sinkC_task_bits_fwdNID),
    .io_task_bits_fwdTxnID                      (sinkC_task_bits_fwdTxnID),
    .io_task_bits_chiOpcode                     (sinkC_task_bits_chiOpcode),
    .io_task_bits_resp                          (sinkC_task_bits_resp),
    .io_task_bits_fwdState                      (sinkC_task_bits_fwdState),
    .io_task_bits_pCrdType                      (sinkC_task_bits_pCrdType),
    .io_task_bits_retToSrc                      (sinkC_task_bits_retToSrc),
    .io_task_bits_likelyshared                  (sinkC_task_bits_likelyshared),
    .io_task_bits_expCompAck                    (sinkC_task_bits_expCompAck),
    .io_task_bits_allowRetry                    (sinkC_task_bits_allowRetry),
    .io_task_bits_memAttr_allocate              (sinkC_task_bits_memAttr_allocate),
    .io_task_bits_memAttr_cacheable             (sinkC_task_bits_memAttr_cacheable),
    .io_task_bits_memAttr_device                (sinkC_task_bits_memAttr_device),
    .io_task_bits_memAttr_ewa                   (sinkC_task_bits_memAttr_ewa),
    .io_task_bits_traceTag                      (sinkC_task_bits_traceTag),
    .io_resp_valid                              (sinkC_resp_valid),
    .io_resp_set                                (sinkC_resp_set),
    .io_resp_tag                                (sinkC_resp_tag),
    .io_resp_respInfo_opcode                    (sinkC_resp_respInfo_opcode),
    .io_resp_respInfo_param                     (sinkC_resp_respInfo_param),
    .io_resp_respInfo_last                      (sinkC_resp_respInfo_last),
    .io_resp_respInfo_denied                    (sinkC_resp_respInfo_denied),
    .io_resp_respInfo_corrupt                   (sinkC_resp_respInfo_corrupt),
    .io_releaseBufWrite_valid                   (sinkC_releaseBufWrite_valid),
    .io_releaseBufWrite_bits_data_data          (sinkC_releaseBufWrite_bits_data_data),
    .io_bufResp_data_0                          (sinkC_bufResp_data_0),
    .io_bufResp_data_1                          (sinkC_bufResp_data_1),
    .io_refillBufWrite_valid                    (sinkC_refillBufWrite_valid),
    .io_refillBufWrite_bits_id                  (sinkC_refillBufWrite_bits_id),
    .io_refillBufWrite_bits_data_data           (sinkC_refillBufWrite_bits_data_data),
    .io_msInfo_0_valid                          (mshrCtl_msInfo_0_valid),
    .io_msInfo_0_bits_set                       (mshrCtl_msInfo_0_bits_set),
    .io_msInfo_0_bits_reqTag                    (mshrCtl_msInfo_0_bits_reqTag),
    .io_msInfo_0_bits_blockRefill               (mshrCtl_msInfo_0_bits_blockRefill),
    .io_msInfo_1_valid                          (mshrCtl_msInfo_1_valid),
    .io_msInfo_1_bits_set                       (mshrCtl_msInfo_1_bits_set),
    .io_msInfo_1_bits_reqTag                    (mshrCtl_msInfo_1_bits_reqTag),
    .io_msInfo_1_bits_blockRefill               (mshrCtl_msInfo_1_bits_blockRefill),
    .io_msInfo_2_valid                          (mshrCtl_msInfo_2_valid),
    .io_msInfo_2_bits_set                       (mshrCtl_msInfo_2_bits_set),
    .io_msInfo_2_bits_reqTag                    (mshrCtl_msInfo_2_bits_reqTag),
    .io_msInfo_2_bits_blockRefill               (mshrCtl_msInfo_2_bits_blockRefill),
    .io_msInfo_3_valid                          (mshrCtl_msInfo_3_valid),
    .io_msInfo_3_bits_set                       (mshrCtl_msInfo_3_bits_set),
    .io_msInfo_3_bits_reqTag                    (mshrCtl_msInfo_3_bits_reqTag),
    .io_msInfo_3_bits_blockRefill               (mshrCtl_msInfo_3_bits_blockRefill),
    .io_msInfo_4_valid                          (mshrCtl_msInfo_4_valid),
    .io_msInfo_4_bits_set                       (mshrCtl_msInfo_4_bits_set),
    .io_msInfo_4_bits_reqTag                    (mshrCtl_msInfo_4_bits_reqTag),
    .io_msInfo_4_bits_blockRefill               (mshrCtl_msInfo_4_bits_blockRefill),
    .io_msInfo_5_valid                          (mshrCtl_msInfo_5_valid),
    .io_msInfo_5_bits_set                       (mshrCtl_msInfo_5_bits_set),
    .io_msInfo_5_bits_reqTag                    (mshrCtl_msInfo_5_bits_reqTag),
    .io_msInfo_5_bits_blockRefill               (mshrCtl_msInfo_5_bits_blockRefill),
    .io_msInfo_6_valid                          (mshrCtl_msInfo_6_valid),
    .io_msInfo_6_bits_set                       (mshrCtl_msInfo_6_bits_set),
    .io_msInfo_6_bits_reqTag                    (mshrCtl_msInfo_6_bits_reqTag),
    .io_msInfo_6_bits_blockRefill               (mshrCtl_msInfo_6_bits_blockRefill),
    .io_msInfo_7_valid                          (mshrCtl_msInfo_7_valid),
    .io_msInfo_7_bits_set                       (mshrCtl_msInfo_7_bits_set),
    .io_msInfo_7_bits_reqTag                    (mshrCtl_msInfo_7_bits_reqTag),
    .io_msInfo_7_bits_blockRefill               (mshrCtl_msInfo_7_bits_blockRefill),
    .io_msInfo_8_valid                          (mshrCtl_msInfo_8_valid),
    .io_msInfo_8_bits_set                       (mshrCtl_msInfo_8_bits_set),
    .io_msInfo_8_bits_reqTag                    (mshrCtl_msInfo_8_bits_reqTag),
    .io_msInfo_8_bits_blockRefill               (mshrCtl_msInfo_8_bits_blockRefill),
    .io_msInfo_9_valid                          (mshrCtl_msInfo_9_valid),
    .io_msInfo_9_bits_set                       (mshrCtl_msInfo_9_bits_set),
    .io_msInfo_9_bits_reqTag                    (mshrCtl_msInfo_9_bits_reqTag),
    .io_msInfo_9_bits_blockRefill               (mshrCtl_msInfo_9_bits_blockRefill),
    .io_msInfo_10_valid                         (mshrCtl_msInfo_10_valid),
    .io_msInfo_10_bits_set                      (mshrCtl_msInfo_10_bits_set),
    .io_msInfo_10_bits_reqTag                   (mshrCtl_msInfo_10_bits_reqTag),
    .io_msInfo_10_bits_blockRefill              (mshrCtl_msInfo_10_bits_blockRefill),
    .io_msInfo_11_valid                         (mshrCtl_msInfo_11_valid),
    .io_msInfo_11_bits_set                      (mshrCtl_msInfo_11_bits_set),
    .io_msInfo_11_bits_reqTag                   (mshrCtl_msInfo_11_bits_reqTag),
    .io_msInfo_11_bits_blockRefill              (mshrCtl_msInfo_11_bits_blockRefill),
    .io_msInfo_12_valid                         (mshrCtl_msInfo_12_valid),
    .io_msInfo_12_bits_set                      (mshrCtl_msInfo_12_bits_set),
    .io_msInfo_12_bits_reqTag                   (mshrCtl_msInfo_12_bits_reqTag),
    .io_msInfo_12_bits_blockRefill              (mshrCtl_msInfo_12_bits_blockRefill),
    .io_msInfo_13_valid                         (mshrCtl_msInfo_13_valid),
    .io_msInfo_13_bits_set                      (mshrCtl_msInfo_13_bits_set),
    .io_msInfo_13_bits_reqTag                   (mshrCtl_msInfo_13_bits_reqTag),
    .io_msInfo_13_bits_blockRefill              (mshrCtl_msInfo_13_bits_blockRefill),
    .io_msInfo_14_valid                         (mshrCtl_msInfo_14_valid),
    .io_msInfo_14_bits_set                      (mshrCtl_msInfo_14_bits_set),
    .io_msInfo_14_bits_reqTag                   (mshrCtl_msInfo_14_bits_reqTag),
    .io_msInfo_14_bits_blockRefill              (mshrCtl_msInfo_14_bits_blockRefill),
    .io_msInfo_15_valid                         (mshrCtl_msInfo_15_valid),
    .io_msInfo_15_bits_set                      (mshrCtl_msInfo_15_bits_set),
    .io_msInfo_15_bits_reqTag                   (mshrCtl_msInfo_15_bits_reqTag),
    .io_msInfo_15_bits_blockRefill              (mshrCtl_msInfo_15_bits_blockRefill)
  );

  // GrantBuffer：上层 D 通道出口（Grant/AccessAck/HintAck）+ E 通道 GrantAck 回收；预取响应出口
  GrantBuffer grantBuf (
    .clock                                             (clock),
    .reset                                             (reset),
    .io_d_task_valid                                   (mainPipe_toSourceD_valid),
    .io_d_task_bits_task_channel                       (mainPipe_toSourceD_bits_task_channel),
    .io_d_task_bits_task_txChannel                     (mainPipe_toSourceD_bits_task_txChannel),
    .io_d_task_bits_task_set                           (mainPipe_toSourceD_bits_task_set),
    .io_d_task_bits_task_tag                           (mainPipe_toSourceD_bits_task_tag),
    .io_d_task_bits_task_off                           (mainPipe_toSourceD_bits_task_off),
    .io_d_task_bits_task_alias                         (mainPipe_toSourceD_bits_task_alias),
    .io_d_task_bits_task_vaddr                         (mainPipe_toSourceD_bits_task_vaddr),
    .io_d_task_bits_task_isKeyword                     (mainPipe_toSourceD_bits_task_isKeyword),
    .io_d_task_bits_task_opcode                        (mainPipe_toSourceD_bits_task_opcode),
    .io_d_task_bits_task_param                         (mainPipe_toSourceD_bits_task_param),
    .io_d_task_bits_task_size                          (mainPipe_toSourceD_bits_task_size),
    .io_d_task_bits_task_sourceId                      (mainPipe_toSourceD_bits_task_sourceId),
    .io_d_task_bits_task_bufIdx                        (mainPipe_toSourceD_bits_task_bufIdx),
    .io_d_task_bits_task_needProbeAckData              (mainPipe_toSourceD_bits_task_needProbeAckData),
    .io_d_task_bits_task_denied                        (mainPipe_toSourceD_bits_task_denied),
    .io_d_task_bits_task_corrupt                       (mainPipe_toSourceD_bits_task_corrupt),
    .io_d_task_bits_task_mshrTask                      (mainPipe_toSourceD_bits_task_mshrTask),
    .io_d_task_bits_task_mshrId                        (mainPipe_toSourceD_bits_task_mshrId),
    .io_d_task_bits_task_aliasTask                     (mainPipe_toSourceD_bits_task_aliasTask),
    .io_d_task_bits_task_useProbeData                  (mainPipe_toSourceD_bits_task_useProbeData),
    .io_d_task_bits_task_mshrRetry                     (mainPipe_toSourceD_bits_task_mshrRetry),
    .io_d_task_bits_task_readProbeDataDown             (mainPipe_toSourceD_bits_task_readProbeDataDown),
    .io_d_task_bits_task_fromL2pft                     (mainPipe_toSourceD_bits_task_fromL2pft),
    .io_d_task_bits_task_needHint                      (mainPipe_toSourceD_bits_task_needHint),
    .io_d_task_bits_task_dirty                         (mainPipe_toSourceD_bits_task_dirty),
    .io_d_task_bits_task_way                           (mainPipe_toSourceD_bits_task_way),
    .io_d_task_bits_task_meta_dirty                    (mainPipe_toSourceD_bits_task_meta_dirty),
    .io_d_task_bits_task_meta_state                    (mainPipe_toSourceD_bits_task_meta_state),
    .io_d_task_bits_task_meta_clients                  (mainPipe_toSourceD_bits_task_meta_clients),
    .io_d_task_bits_task_meta_alias                    (mainPipe_toSourceD_bits_task_meta_alias),
    .io_d_task_bits_task_meta_prefetch                 (mainPipe_toSourceD_bits_task_meta_prefetch),
    .io_d_task_bits_task_meta_prefetchSrc              (mainPipe_toSourceD_bits_task_meta_prefetchSrc),
    .io_d_task_bits_task_meta_accessed                 (mainPipe_toSourceD_bits_task_meta_accessed),
    .io_d_task_bits_task_meta_tagErr                   (mainPipe_toSourceD_bits_task_meta_tagErr),
    .io_d_task_bits_task_meta_dataErr                  (mainPipe_toSourceD_bits_task_meta_dataErr),
    .io_d_task_bits_task_metaWen                       (mainPipe_toSourceD_bits_task_metaWen),
    .io_d_task_bits_task_tagWen                        (mainPipe_toSourceD_bits_task_tagWen),
    .io_d_task_bits_task_dsWen                         (mainPipe_toSourceD_bits_task_dsWen),
    .io_d_task_bits_task_wayMask                       (mainPipe_toSourceD_bits_task_wayMask),
    .io_d_task_bits_task_replTask                      (mainPipe_toSourceD_bits_task_replTask),
    .io_d_task_bits_task_cmoTask                       (mainPipe_toSourceD_bits_task_cmoTask),
    .io_d_task_bits_task_cmoAll                        (mainPipe_toSourceD_bits_task_cmoAll),
    .io_d_task_bits_task_reqSource                     (mainPipe_toSourceD_bits_task_reqSource),
    .io_d_task_bits_task_mergeA                        (mainPipe_toSourceD_bits_task_mergeA),
    .io_d_task_bits_task_aMergeTask_off                (mainPipe_toSourceD_bits_task_aMergeTask_off),
    .io_d_task_bits_task_aMergeTask_alias              (mainPipe_toSourceD_bits_task_aMergeTask_alias),
    .io_d_task_bits_task_aMergeTask_vaddr              (mainPipe_toSourceD_bits_task_aMergeTask_vaddr),
    .io_d_task_bits_task_aMergeTask_isKeyword          (mainPipe_toSourceD_bits_task_aMergeTask_isKeyword),
    .io_d_task_bits_task_aMergeTask_opcode             (mainPipe_toSourceD_bits_task_aMergeTask_opcode),
    .io_d_task_bits_task_aMergeTask_param              (mainPipe_toSourceD_bits_task_aMergeTask_param),
    .io_d_task_bits_task_aMergeTask_sourceId           (mainPipe_toSourceD_bits_task_aMergeTask_sourceId),
    .io_d_task_bits_task_aMergeTask_meta_dirty         (mainPipe_toSourceD_bits_task_aMergeTask_meta_dirty),
    .io_d_task_bits_task_aMergeTask_meta_state         (mainPipe_toSourceD_bits_task_aMergeTask_meta_state),
    .io_d_task_bits_task_aMergeTask_meta_clients       (mainPipe_toSourceD_bits_task_aMergeTask_meta_clients),
    .io_d_task_bits_task_aMergeTask_meta_alias         (mainPipe_toSourceD_bits_task_aMergeTask_meta_alias),
    .io_d_task_bits_task_aMergeTask_meta_prefetch      (mainPipe_toSourceD_bits_task_aMergeTask_meta_prefetch),
    .io_d_task_bits_task_aMergeTask_meta_prefetchSrc   (mainPipe_toSourceD_bits_task_aMergeTask_meta_prefetchSrc),
    .io_d_task_bits_task_aMergeTask_meta_accessed      (mainPipe_toSourceD_bits_task_aMergeTask_meta_accessed),
    .io_d_task_bits_task_aMergeTask_meta_tagErr        (mainPipe_toSourceD_bits_task_aMergeTask_meta_tagErr),
    .io_d_task_bits_task_aMergeTask_meta_dataErr       (mainPipe_toSourceD_bits_task_aMergeTask_meta_dataErr),
    .io_d_task_bits_task_snpHitRelease                 (mainPipe_toSourceD_bits_task_snpHitRelease),
    .io_d_task_bits_task_snpHitReleaseToInval          (mainPipe_toSourceD_bits_task_snpHitReleaseToInval),
    .io_d_task_bits_task_snpHitReleaseToClean          (mainPipe_toSourceD_bits_task_snpHitReleaseToClean),
    .io_d_task_bits_task_snpHitReleaseWithData         (mainPipe_toSourceD_bits_task_snpHitReleaseWithData),
    .io_d_task_bits_task_snpHitReleaseIdx              (mainPipe_toSourceD_bits_task_snpHitReleaseIdx),
    .io_d_task_bits_task_snpHitReleaseMeta_dirty       (mainPipe_toSourceD_bits_task_snpHitReleaseMeta_dirty),
    .io_d_task_bits_task_snpHitReleaseMeta_state       (mainPipe_toSourceD_bits_task_snpHitReleaseMeta_state),
    .io_d_task_bits_task_snpHitReleaseMeta_clients     (mainPipe_toSourceD_bits_task_snpHitReleaseMeta_clients),
    .io_d_task_bits_task_snpHitReleaseMeta_alias       (mainPipe_toSourceD_bits_task_snpHitReleaseMeta_alias),
    .io_d_task_bits_task_snpHitReleaseMeta_prefetch    (mainPipe_toSourceD_bits_task_snpHitReleaseMeta_prefetch),
    .io_d_task_bits_task_snpHitReleaseMeta_prefetchSrc (mainPipe_toSourceD_bits_task_snpHitReleaseMeta_prefetchSrc),
    .io_d_task_bits_task_snpHitReleaseMeta_accessed    (mainPipe_toSourceD_bits_task_snpHitReleaseMeta_accessed),
    .io_d_task_bits_task_snpHitReleaseMeta_tagErr      (mainPipe_toSourceD_bits_task_snpHitReleaseMeta_tagErr),
    .io_d_task_bits_task_snpHitReleaseMeta_dataErr     (mainPipe_toSourceD_bits_task_snpHitReleaseMeta_dataErr),
    .io_d_task_bits_task_tgtID                         (mainPipe_toSourceD_bits_task_tgtID),
    .io_d_task_bits_task_srcID                         (mainPipe_toSourceD_bits_task_srcID),
    .io_d_task_bits_task_txnID                         (mainPipe_toSourceD_bits_task_txnID),
    .io_d_task_bits_task_homeNID                       (mainPipe_toSourceD_bits_task_homeNID),
    .io_d_task_bits_task_dbID                          (mainPipe_toSourceD_bits_task_dbID),
    .io_d_task_bits_task_fwdNID                        (mainPipe_toSourceD_bits_task_fwdNID),
    .io_d_task_bits_task_fwdTxnID                      (mainPipe_toSourceD_bits_task_fwdTxnID),
    .io_d_task_bits_task_chiOpcode                     (mainPipe_toSourceD_bits_task_chiOpcode),
    .io_d_task_bits_task_resp                          (mainPipe_toSourceD_bits_task_resp),
    .io_d_task_bits_task_fwdState                      (mainPipe_toSourceD_bits_task_fwdState),
    .io_d_task_bits_task_pCrdType                      (mainPipe_toSourceD_bits_task_pCrdType),
    .io_d_task_bits_task_retToSrc                      (mainPipe_toSourceD_bits_task_retToSrc),
    .io_d_task_bits_task_likelyshared                  (mainPipe_toSourceD_bits_task_likelyshared),
    .io_d_task_bits_task_expCompAck                    (mainPipe_toSourceD_bits_task_expCompAck),
    .io_d_task_bits_task_allowRetry                    (mainPipe_toSourceD_bits_task_allowRetry),
    .io_d_task_bits_task_memAttr_allocate              (mainPipe_toSourceD_bits_task_memAttr_allocate),
    .io_d_task_bits_task_memAttr_cacheable             (mainPipe_toSourceD_bits_task_memAttr_cacheable),
    .io_d_task_bits_task_memAttr_device                (mainPipe_toSourceD_bits_task_memAttr_device),
    .io_d_task_bits_task_memAttr_ewa                   (mainPipe_toSourceD_bits_task_memAttr_ewa),
    .io_d_task_bits_task_traceTag                      (mainPipe_toSourceD_bits_task_traceTag),
    .io_d_task_bits_data_data                          (mainPipe_toSourceD_bits_data_data),
    .io_d_ready                                        (io_in_d_ready),
    .io_d_valid                                        (io_in_d_valid),
    .io_d_bits_opcode                                  (io_in_d_bits_opcode),
    .io_d_bits_param                                   (io_in_d_bits_param),
    .io_d_bits_source                                  (io_in_d_bits_source),
    .io_d_bits_sink                                    (io_in_d_bits_sink),
    .io_d_bits_denied                                  (io_in_d_bits_denied),
    .io_d_bits_echo_isKeyword                          (io_in_d_bits_echo_isKeyword),
    .io_d_bits_data                                    (io_in_d_bits_data),
    .io_d_bits_corrupt                                 (io_in_d_bits_corrupt),
    .io_e_valid                                        (io_in_e_valid),
    .io_e_bits_sink                                    (io_in_e_bits_sink),
    .io_fromReqArb_status_s1_tags_1                    (reqArb_status_s1_tags_1),
    .io_fromReqArb_status_s1_sets_1                    (reqArb_status_s1_sets_1),
    .io_pipeStatusVec_1_valid                          (reqArb_status_vec_1_valid),
    .io_pipeStatusVec_1_bits_channel                   (reqArb_status_vec_1_bits_channel),
    .io_pipeStatusVec_2_valid                          (mainPipe_status_vec_toD_0_valid),
    .io_pipeStatusVec_2_bits_channel                   (mainPipe_status_vec_toD_0_bits_channel),
    .io_pipeStatusVec_3_valid                          (mainPipe_status_vec_toD_1_valid),
    .io_pipeStatusVec_3_bits_channel                   (mainPipe_status_vec_toD_1_bits_channel),
    .io_pipeStatusVec_4_valid                          (mainPipe_status_vec_toD_2_valid),
    .io_pipeStatusVec_4_bits_channel                   (mainPipe_status_vec_toD_2_bits_channel),
    .io_toReqArb_blockSinkReqEntrance_blockA_s1        (grantBuf_toReqArb_blockSinkReqEntrance_blockA_s1),
    .io_toReqArb_blockSinkReqEntrance_blockB_s1        (grantBuf_toReqArb_blockSinkReqEntrance_blockB_s1),
    .io_toReqArb_blockSinkReqEntrance_blockC_s1        (grantBuf_toReqArb_blockSinkReqEntrance_blockC_s1),
    .io_toReqArb_blockMSHRReqEntrance                  (grantBuf_toReqArb_blockMSHRReqEntrance),
    .io_prefetchResp_ready                             (io_prefetch_resp_ready),
    .io_prefetchResp_valid                             (io_prefetch_resp_valid),
    .io_prefetchResp_bits_tag                          (io_prefetch_resp_bits_tag),
    .io_prefetchResp_bits_set                          (io_prefetch_resp_bits_set),
    .io_prefetchResp_bits_vaddr                        (io_prefetch_resp_bits_vaddr),
    .io_prefetchResp_bits_pfSource                     (io_prefetch_resp_bits_pfSource),
    .io_grantStatus_0_valid                            (grantBuf_grantStatus_0_valid),
    .io_grantStatus_0_set                              (grantBuf_grantStatus_0_set),
    .io_grantStatus_0_tag                              (grantBuf_grantStatus_0_tag),
    .io_grantStatus_1_valid                            (grantBuf_grantStatus_1_valid),
    .io_grantStatus_1_set                              (grantBuf_grantStatus_1_set),
    .io_grantStatus_1_tag                              (grantBuf_grantStatus_1_tag),
    .io_grantStatus_2_valid                            (grantBuf_grantStatus_2_valid),
    .io_grantStatus_2_set                              (grantBuf_grantStatus_2_set),
    .io_grantStatus_2_tag                              (grantBuf_grantStatus_2_tag),
    .io_grantStatus_3_valid                            (grantBuf_grantStatus_3_valid),
    .io_grantStatus_3_set                              (grantBuf_grantStatus_3_set),
    .io_grantStatus_3_tag                              (grantBuf_grantStatus_3_tag),
    .io_grantStatus_4_valid                            (grantBuf_grantStatus_4_valid),
    .io_grantStatus_4_set                              (grantBuf_grantStatus_4_set),
    .io_grantStatus_4_tag                              (grantBuf_grantStatus_4_tag),
    .io_grantStatus_5_valid                            (grantBuf_grantStatus_5_valid),
    .io_grantStatus_5_set                              (grantBuf_grantStatus_5_set),
    .io_grantStatus_5_tag                              (grantBuf_grantStatus_5_tag),
    .io_grantStatus_6_valid                            (grantBuf_grantStatus_6_valid),
    .io_grantStatus_6_set                              (grantBuf_grantStatus_6_set),
    .io_grantStatus_6_tag                              (grantBuf_grantStatus_6_tag),
    .io_grantStatus_7_valid                            (grantBuf_grantStatus_7_valid),
    .io_grantStatus_7_set                              (grantBuf_grantStatus_7_set),
    .io_grantStatus_7_tag                              (grantBuf_grantStatus_7_tag),
    .io_grantStatus_8_valid                            (grantBuf_grantStatus_8_valid),
    .io_grantStatus_8_set                              (grantBuf_grantStatus_8_set),
    .io_grantStatus_8_tag                              (grantBuf_grantStatus_8_tag),
    .io_grantStatus_9_valid                            (grantBuf_grantStatus_9_valid),
    .io_grantStatus_9_set                              (grantBuf_grantStatus_9_set),
    .io_grantStatus_9_tag                              (grantBuf_grantStatus_9_tag),
    .io_grantStatus_10_valid                           (grantBuf_grantStatus_10_valid),
    .io_grantStatus_10_set                             (grantBuf_grantStatus_10_set),
    .io_grantStatus_10_tag                             (grantBuf_grantStatus_10_tag),
    .io_grantStatus_11_valid                           (grantBuf_grantStatus_11_valid),
    .io_grantStatus_11_set                             (grantBuf_grantStatus_11_set),
    .io_grantStatus_11_tag                             (grantBuf_grantStatus_11_tag),
    .io_grantStatus_12_valid                           (grantBuf_grantStatus_12_valid),
    .io_grantStatus_12_set                             (grantBuf_grantStatus_12_set),
    .io_grantStatus_12_tag                             (grantBuf_grantStatus_12_tag),
    .io_grantStatus_13_valid                           (grantBuf_grantStatus_13_valid),
    .io_grantStatus_13_set                             (grantBuf_grantStatus_13_set),
    .io_grantStatus_13_tag                             (grantBuf_grantStatus_13_tag),
    .io_grantStatus_14_valid                           (grantBuf_grantStatus_14_valid),
    .io_grantStatus_14_set                             (grantBuf_grantStatus_14_set),
    .io_grantStatus_14_tag                             (grantBuf_grantStatus_14_tag),
    .io_grantStatus_15_valid                           (grantBuf_grantStatus_15_valid),
    .io_grantStatus_15_set                             (grantBuf_grantStatus_15_set),
    .io_grantStatus_15_tag                             (grantBuf_grantStatus_15_tag)
  );

  // TXREQ：CHI 下行请求队列（MainPipe 的写回 / MSHR 的 Read*/Write* 请求），按 pipeStatusVec 反压
  TXREQ txreq (
    .clock                             (clock),
    .reset                             (reset),
    .io_pipeReq_valid                  (mainPipe_toTXREQ_valid),
    .io_pipeReq_bits_tgtID             (mainPipe_toTXREQ_bits_tgtID),
    .io_pipeReq_bits_srcID             (mainPipe_toTXREQ_bits_srcID),
    .io_pipeReq_bits_txnID             (mainPipe_toTXREQ_bits_txnID),
    .io_pipeReq_bits_opcode            (mainPipe_toTXREQ_bits_opcode),
    .io_pipeReq_bits_addr              (mainPipe_toTXREQ_bits_addr),
    .io_pipeReq_bits_likelyshared      (mainPipe_toTXREQ_bits_likelyshared),
    .io_pipeReq_bits_allowRetry        (mainPipe_toTXREQ_bits_allowRetry),
    .io_pipeReq_bits_pCrdType          (mainPipe_toTXREQ_bits_pCrdType),
    .io_pipeReq_bits_memAttr_allocate  (mainPipe_toTXREQ_bits_memAttr_allocate),
    .io_pipeReq_bits_memAttr_cacheable (mainPipe_toTXREQ_bits_memAttr_cacheable),
    .io_pipeReq_bits_memAttr_device    (mainPipe_toTXREQ_bits_memAttr_device),
    .io_pipeReq_bits_memAttr_ewa       (mainPipe_toTXREQ_bits_memAttr_ewa),
    .io_pipeReq_bits_expCompAck        (mainPipe_toTXREQ_bits_expCompAck),
    .io_mshrReq_ready                  (txreq_mshrReq_ready),
    .io_mshrReq_valid                  (mshrCtl_toTXREQ_valid),
    .io_mshrReq_bits_qos               (mshrCtl_toTXREQ_bits_qos),
    .io_mshrReq_bits_tgtID             (mshrCtl_toTXREQ_bits_tgtID),
    .io_mshrReq_bits_txnID             (mshrCtl_toTXREQ_bits_txnID),
    .io_mshrReq_bits_opcode            (mshrCtl_toTXREQ_bits_opcode),
    .io_mshrReq_bits_size              (mshrCtl_toTXREQ_bits_size),
    .io_mshrReq_bits_addr              (mshrCtl_toTXREQ_bits_addr),
    .io_mshrReq_bits_likelyshared      (mshrCtl_toTXREQ_bits_likelyshared),
    .io_mshrReq_bits_allowRetry        (mshrCtl_toTXREQ_bits_allowRetry),
    .io_mshrReq_bits_pCrdType          (mshrCtl_toTXREQ_bits_pCrdType),
    .io_mshrReq_bits_memAttr_allocate  (mshrCtl_toTXREQ_bits_memAttr_allocate),
    .io_mshrReq_bits_memAttr_cacheable (mshrCtl_toTXREQ_bits_memAttr_cacheable),
    .io_mshrReq_bits_memAttr_ewa       (mshrCtl_toTXREQ_bits_memAttr_ewa),
    .io_mshrReq_bits_snpAttr           (mshrCtl_toTXREQ_bits_snpAttr),
    .io_mshrReq_bits_expCompAck        (mshrCtl_toTXREQ_bits_expCompAck),
    .io_out_ready                      (io_out_tx_req_ready),
    .io_out_valid                      (io_out_tx_req_valid),
    .io_out_bits_qos                   (io_out_tx_req_bits_qos),
    .io_out_bits_txnID                 (io_out_tx_req_bits_txnID),
    .io_out_bits_returnNID             (io_out_tx_req_bits_returnNID),
    .io_out_bits_stashNIDValid         (io_out_tx_req_bits_stashNIDValid),
    .io_out_bits_returnTxnID           (io_out_tx_req_bits_returnTxnID),
    .io_out_bits_opcode                (io_out_tx_req_bits_opcode),
    .io_out_bits_addr                  (io_out_tx_req_bits_addr),
    .io_out_bits_ns                    (io_out_tx_req_bits_ns),
    .io_out_bits_likelyshared          (io_out_tx_req_bits_likelyshared),
    .io_out_bits_allowRetry            (io_out_tx_req_bits_allowRetry),
    .io_out_bits_order                 (io_out_tx_req_bits_order),
    .io_out_bits_pCrdType              (io_out_tx_req_bits_pCrdType),
    .io_out_bits_memAttr_allocate      (io_out_tx_req_bits_memAttr_allocate),
    .io_out_bits_memAttr_cacheable     (io_out_tx_req_bits_memAttr_cacheable),
    .io_out_bits_memAttr_device        (io_out_tx_req_bits_memAttr_device),
    .io_out_bits_memAttr_ewa           (io_out_tx_req_bits_memAttr_ewa),
    .io_out_bits_snpAttr               (io_out_tx_req_bits_snpAttr),
    .io_out_bits_lpIDWithPadding       (io_out_tx_req_bits_lpIDWithPadding),
    .io_out_bits_snoopMe               (io_out_tx_req_bits_snoopMe),
    .io_out_bits_expCompAck            (io_out_tx_req_bits_expCompAck),
    .io_out_bits_tagOp                 (io_out_tx_req_bits_tagOp),
    .io_out_bits_traceTag              (io_out_tx_req_bits_traceTag),
    .io_out_bits_mpam_perfMonGroup     (io_out_tx_req_bits_mpam_perfMonGroup),
    .io_out_bits_mpam_partID           (io_out_tx_req_bits_mpam_partID),
    .io_out_bits_mpam_mpamNS           (io_out_tx_req_bits_mpam_mpamNS),
    .io_out_bits_rsvdc                 (io_out_tx_req_bits_rsvdc),
    .io_pipeStatusVec_1_valid          (reqArb_status_vec_toTX_1_valid),
    .io_pipeStatusVec_1_bits_txChannel (reqArb_status_vec_toTX_1_bits_txChannel),
    .io_pipeStatusVec_1_bits_mshrTask  (reqArb_status_vec_toTX_1_bits_mshrTask),
    .io_pipeStatusVec_2_valid          (mainPipe_status_vec_toTX_0_valid),
    .io_pipeStatusVec_2_bits_txChannel (mainPipe_status_vec_toTX_0_bits_txChannel),
    .io_pipeStatusVec_2_bits_mshrTask  (mainPipe_status_vec_toTX_0_bits_mshrTask),
    .io_pipeStatusVec_3_valid          (mainPipe_status_vec_toTX_1_valid),
    .io_pipeStatusVec_3_bits_txChannel (mainPipe_status_vec_toTX_1_bits_txChannel),
    .io_pipeStatusVec_3_bits_mshrTask  (mainPipe_status_vec_toTX_1_bits_mshrTask),
    .io_pipeStatusVec_4_valid          (mainPipe_status_vec_toTX_2_valid),
    .io_pipeStatusVec_4_bits_txChannel (mainPipe_status_vec_toTX_2_bits_txChannel),
    .io_pipeStatusVec_4_bits_mshrTask  (mainPipe_status_vec_toTX_2_bits_mshrTask),
    .io_toReqArb_blockMSHRReqEntrance  (txreq_toReqArb_blockMSHRReqEntrance),
    .io_sliceId                        (SLICE_ID)
  );

  // TXDAT：CHI 下行数据队列（写回数据 / snoop 响应数据）
  TXDAT txdat (
    .clock                                         (clock),
    .reset                                         (reset),
    .io_in_ready                                   (txdat_in_ready),
    .io_in_valid                                   (mainPipe_toTXDAT_valid),
    .io_in_bits_task_channel                       (mainPipe_toTXDAT_bits_task_channel),
    .io_in_bits_task_txChannel                     (mainPipe_toTXDAT_bits_task_txChannel),
    .io_in_bits_task_set                           (mainPipe_toTXDAT_bits_task_set),
    .io_in_bits_task_tag                           (mainPipe_toTXDAT_bits_task_tag),
    .io_in_bits_task_off                           (mainPipe_toTXDAT_bits_task_off),
    .io_in_bits_task_alias                         (mainPipe_toTXDAT_bits_task_alias),
    .io_in_bits_task_vaddr                         (mainPipe_toTXDAT_bits_task_vaddr),
    .io_in_bits_task_isKeyword                     (mainPipe_toTXDAT_bits_task_isKeyword),
    .io_in_bits_task_opcode                        (mainPipe_toTXDAT_bits_task_opcode),
    .io_in_bits_task_param                         (mainPipe_toTXDAT_bits_task_param),
    .io_in_bits_task_size                          (mainPipe_toTXDAT_bits_task_size),
    .io_in_bits_task_sourceId                      (mainPipe_toTXDAT_bits_task_sourceId),
    .io_in_bits_task_bufIdx                        (mainPipe_toTXDAT_bits_task_bufIdx),
    .io_in_bits_task_needProbeAckData              (mainPipe_toTXDAT_bits_task_needProbeAckData),
    .io_in_bits_task_denied                        (mainPipe_toTXDAT_bits_task_denied),
    .io_in_bits_task_corrupt                       (mainPipe_toTXDAT_bits_task_corrupt),
    .io_in_bits_task_mshrTask                      (mainPipe_toTXDAT_bits_task_mshrTask),
    .io_in_bits_task_mshrId                        (mainPipe_toTXDAT_bits_task_mshrId),
    .io_in_bits_task_aliasTask                     (mainPipe_toTXDAT_bits_task_aliasTask),
    .io_in_bits_task_useProbeData                  (mainPipe_toTXDAT_bits_task_useProbeData),
    .io_in_bits_task_mshrRetry                     (mainPipe_toTXDAT_bits_task_mshrRetry),
    .io_in_bits_task_readProbeDataDown             (mainPipe_toTXDAT_bits_task_readProbeDataDown),
    .io_in_bits_task_fromL2pft                     (mainPipe_toTXDAT_bits_task_fromL2pft),
    .io_in_bits_task_needHint                      (mainPipe_toTXDAT_bits_task_needHint),
    .io_in_bits_task_dirty                         (mainPipe_toTXDAT_bits_task_dirty),
    .io_in_bits_task_way                           (mainPipe_toTXDAT_bits_task_way),
    .io_in_bits_task_meta_dirty                    (mainPipe_toTXDAT_bits_task_meta_dirty),
    .io_in_bits_task_meta_state                    (mainPipe_toTXDAT_bits_task_meta_state),
    .io_in_bits_task_meta_clients                  (mainPipe_toTXDAT_bits_task_meta_clients),
    .io_in_bits_task_meta_alias                    (mainPipe_toTXDAT_bits_task_meta_alias),
    .io_in_bits_task_meta_prefetch                 (mainPipe_toTXDAT_bits_task_meta_prefetch),
    .io_in_bits_task_meta_prefetchSrc              (mainPipe_toTXDAT_bits_task_meta_prefetchSrc),
    .io_in_bits_task_meta_accessed                 (mainPipe_toTXDAT_bits_task_meta_accessed),
    .io_in_bits_task_meta_tagErr                   (mainPipe_toTXDAT_bits_task_meta_tagErr),
    .io_in_bits_task_meta_dataErr                  (mainPipe_toTXDAT_bits_task_meta_dataErr),
    .io_in_bits_task_metaWen                       (mainPipe_toTXDAT_bits_task_metaWen),
    .io_in_bits_task_tagWen                        (mainPipe_toTXDAT_bits_task_tagWen),
    .io_in_bits_task_dsWen                         (mainPipe_toTXDAT_bits_task_dsWen),
    .io_in_bits_task_wayMask                       (mainPipe_toTXDAT_bits_task_wayMask),
    .io_in_bits_task_replTask                      (mainPipe_toTXDAT_bits_task_replTask),
    .io_in_bits_task_cmoTask                       (mainPipe_toTXDAT_bits_task_cmoTask),
    .io_in_bits_task_cmoAll                        (mainPipe_toTXDAT_bits_task_cmoAll),
    .io_in_bits_task_reqSource                     (mainPipe_toTXDAT_bits_task_reqSource),
    .io_in_bits_task_mergeA                        (mainPipe_toTXDAT_bits_task_mergeA),
    .io_in_bits_task_aMergeTask_off                (mainPipe_toTXDAT_bits_task_aMergeTask_off),
    .io_in_bits_task_aMergeTask_alias              (mainPipe_toTXDAT_bits_task_aMergeTask_alias),
    .io_in_bits_task_aMergeTask_vaddr              (mainPipe_toTXDAT_bits_task_aMergeTask_vaddr),
    .io_in_bits_task_aMergeTask_isKeyword          (mainPipe_toTXDAT_bits_task_aMergeTask_isKeyword),
    .io_in_bits_task_aMergeTask_opcode             (mainPipe_toTXDAT_bits_task_aMergeTask_opcode),
    .io_in_bits_task_aMergeTask_param              (mainPipe_toTXDAT_bits_task_aMergeTask_param),
    .io_in_bits_task_aMergeTask_sourceId           (mainPipe_toTXDAT_bits_task_aMergeTask_sourceId),
    .io_in_bits_task_aMergeTask_meta_dirty         (mainPipe_toTXDAT_bits_task_aMergeTask_meta_dirty),
    .io_in_bits_task_aMergeTask_meta_state         (mainPipe_toTXDAT_bits_task_aMergeTask_meta_state),
    .io_in_bits_task_aMergeTask_meta_clients       (mainPipe_toTXDAT_bits_task_aMergeTask_meta_clients),
    .io_in_bits_task_aMergeTask_meta_alias         (mainPipe_toTXDAT_bits_task_aMergeTask_meta_alias),
    .io_in_bits_task_aMergeTask_meta_prefetch      (mainPipe_toTXDAT_bits_task_aMergeTask_meta_prefetch),
    .io_in_bits_task_aMergeTask_meta_prefetchSrc   (mainPipe_toTXDAT_bits_task_aMergeTask_meta_prefetchSrc),
    .io_in_bits_task_aMergeTask_meta_accessed      (mainPipe_toTXDAT_bits_task_aMergeTask_meta_accessed),
    .io_in_bits_task_aMergeTask_meta_tagErr        (mainPipe_toTXDAT_bits_task_aMergeTask_meta_tagErr),
    .io_in_bits_task_aMergeTask_meta_dataErr       (mainPipe_toTXDAT_bits_task_aMergeTask_meta_dataErr),
    .io_in_bits_task_snpHitRelease                 (mainPipe_toTXDAT_bits_task_snpHitRelease),
    .io_in_bits_task_snpHitReleaseToInval          (mainPipe_toTXDAT_bits_task_snpHitReleaseToInval),
    .io_in_bits_task_snpHitReleaseToClean          (mainPipe_toTXDAT_bits_task_snpHitReleaseToClean),
    .io_in_bits_task_snpHitReleaseWithData         (mainPipe_toTXDAT_bits_task_snpHitReleaseWithData),
    .io_in_bits_task_snpHitReleaseIdx              (mainPipe_toTXDAT_bits_task_snpHitReleaseIdx),
    .io_in_bits_task_snpHitReleaseMeta_dirty       (mainPipe_toTXDAT_bits_task_snpHitReleaseMeta_dirty),
    .io_in_bits_task_snpHitReleaseMeta_state       (mainPipe_toTXDAT_bits_task_snpHitReleaseMeta_state),
    .io_in_bits_task_snpHitReleaseMeta_clients     (mainPipe_toTXDAT_bits_task_snpHitReleaseMeta_clients),
    .io_in_bits_task_snpHitReleaseMeta_alias       (mainPipe_toTXDAT_bits_task_snpHitReleaseMeta_alias),
    .io_in_bits_task_snpHitReleaseMeta_prefetch    (mainPipe_toTXDAT_bits_task_snpHitReleaseMeta_prefetch),
    .io_in_bits_task_snpHitReleaseMeta_prefetchSrc (mainPipe_toTXDAT_bits_task_snpHitReleaseMeta_prefetchSrc),
    .io_in_bits_task_snpHitReleaseMeta_accessed    (mainPipe_toTXDAT_bits_task_snpHitReleaseMeta_accessed),
    .io_in_bits_task_snpHitReleaseMeta_tagErr      (mainPipe_toTXDAT_bits_task_snpHitReleaseMeta_tagErr),
    .io_in_bits_task_snpHitReleaseMeta_dataErr     (mainPipe_toTXDAT_bits_task_snpHitReleaseMeta_dataErr),
    .io_in_bits_task_tgtID                         (mainPipe_toTXDAT_bits_task_tgtID),
    .io_in_bits_task_srcID                         (mainPipe_toTXDAT_bits_task_srcID),
    .io_in_bits_task_txnID                         (mainPipe_toTXDAT_bits_task_txnID),
    .io_in_bits_task_homeNID                       (mainPipe_toTXDAT_bits_task_homeNID),
    .io_in_bits_task_dbID                          (mainPipe_toTXDAT_bits_task_dbID),
    .io_in_bits_task_fwdNID                        (mainPipe_toTXDAT_bits_task_fwdNID),
    .io_in_bits_task_fwdTxnID                      (mainPipe_toTXDAT_bits_task_fwdTxnID),
    .io_in_bits_task_chiOpcode                     (mainPipe_toTXDAT_bits_task_chiOpcode),
    .io_in_bits_task_resp                          (mainPipe_toTXDAT_bits_task_resp),
    .io_in_bits_task_fwdState                      (mainPipe_toTXDAT_bits_task_fwdState),
    .io_in_bits_task_pCrdType                      (mainPipe_toTXDAT_bits_task_pCrdType),
    .io_in_bits_task_retToSrc                      (mainPipe_toTXDAT_bits_task_retToSrc),
    .io_in_bits_task_likelyshared                  (mainPipe_toTXDAT_bits_task_likelyshared),
    .io_in_bits_task_expCompAck                    (mainPipe_toTXDAT_bits_task_expCompAck),
    .io_in_bits_task_allowRetry                    (mainPipe_toTXDAT_bits_task_allowRetry),
    .io_in_bits_task_memAttr_allocate              (mainPipe_toTXDAT_bits_task_memAttr_allocate),
    .io_in_bits_task_memAttr_cacheable             (mainPipe_toTXDAT_bits_task_memAttr_cacheable),
    .io_in_bits_task_memAttr_device                (mainPipe_toTXDAT_bits_task_memAttr_device),
    .io_in_bits_task_memAttr_ewa                   (mainPipe_toTXDAT_bits_task_memAttr_ewa),
    .io_in_bits_task_traceTag                      (mainPipe_toTXDAT_bits_task_traceTag),
    .io_in_bits_data_data                          (mainPipe_toTXDAT_bits_data_data),
    .io_out_ready                                  (io_out_tx_dat_ready),
    .io_out_valid                                  (io_out_tx_dat_valid),
    .io_out_bits_tgtID                             (io_out_tx_dat_bits_tgtID),
    .io_out_bits_txnID                             (io_out_tx_dat_bits_txnID),
    .io_out_bits_homeNID                           (io_out_tx_dat_bits_homeNID),
    .io_out_bits_opcode                            (io_out_tx_dat_bits_opcode),
    .io_out_bits_respErr                           (io_out_tx_dat_bits_respErr),
    .io_out_bits_resp                              (io_out_tx_dat_bits_resp),
    .io_out_bits_dataSource                        (io_out_tx_dat_bits_dataSource),
    .io_out_bits_dbID                              (io_out_tx_dat_bits_dbID),
    .io_out_bits_ccID                              (io_out_tx_dat_bits_ccID),
    .io_out_bits_dataID                            (io_out_tx_dat_bits_dataID),
    .io_out_bits_traceTag                          (io_out_tx_dat_bits_traceTag),
    .io_out_bits_be                                (io_out_tx_dat_bits_be),
    .io_out_bits_data                              (io_out_tx_dat_bits_data),
    .io_out_bits_dataCheck                         (io_out_tx_dat_bits_dataCheck),
    .io_out_bits_poison                            (io_out_tx_dat_bits_poison),
    .io_pipeStatusVec_1_valid                      (reqArb_status_vec_toTX_1_valid),
    .io_pipeStatusVec_1_bits_channel               (reqArb_status_vec_toTX_1_bits_channel),
    .io_pipeStatusVec_1_bits_txChannel             (reqArb_status_vec_toTX_1_bits_txChannel),
    .io_pipeStatusVec_1_bits_mshrTask              (reqArb_status_vec_toTX_1_bits_mshrTask),
    .io_pipeStatusVec_2_valid                      (mainPipe_status_vec_toTX_0_valid),
    .io_pipeStatusVec_2_bits_channel               (mainPipe_status_vec_toTX_0_bits_channel),
    .io_pipeStatusVec_2_bits_txChannel             (mainPipe_status_vec_toTX_0_bits_txChannel),
    .io_pipeStatusVec_2_bits_mshrTask              (mainPipe_status_vec_toTX_0_bits_mshrTask),
    .io_pipeStatusVec_3_valid                      (mainPipe_status_vec_toTX_1_valid),
    .io_pipeStatusVec_3_bits_channel               (mainPipe_status_vec_toTX_1_bits_channel),
    .io_pipeStatusVec_3_bits_txChannel             (mainPipe_status_vec_toTX_1_bits_txChannel),
    .io_pipeStatusVec_3_bits_mshrTask              (mainPipe_status_vec_toTX_1_bits_mshrTask),
    .io_pipeStatusVec_4_valid                      (mainPipe_status_vec_toTX_2_valid),
    .io_pipeStatusVec_4_bits_channel               (mainPipe_status_vec_toTX_2_bits_channel),
    .io_pipeStatusVec_4_bits_txChannel             (mainPipe_status_vec_toTX_2_bits_txChannel),
    .io_pipeStatusVec_4_bits_mshrTask              (mainPipe_status_vec_toTX_2_bits_mshrTask),
    .io_toReqArb_blockMSHRReqEntrance              (txdat_toReqArb_blockMSHRReqEntrance),
    .io_toReqArb_blockSinkBReqEntrance             (txdat_toReqArb_blockSinkBReqEntrance)
  );

  // TXRSP：CHI 下行响应队列（MainPipe 的 SnpResp / MSHR 的 CompAck）
  TXRSP txrsp (
    .clock                             (clock),
    .reset                             (reset),
    .io_pipeRsp_valid                  (mainPipe_toTXRSP_valid),
    .io_pipeRsp_bits_txChannel         (mainPipe_toTXRSP_bits_txChannel),
    .io_pipeRsp_bits_denied            (mainPipe_toTXRSP_bits_denied),
    .io_pipeRsp_bits_tgtID             (mainPipe_toTXRSP_bits_tgtID),
    .io_pipeRsp_bits_srcID             (mainPipe_toTXRSP_bits_srcID),
    .io_pipeRsp_bits_txnID             (mainPipe_toTXRSP_bits_txnID),
    .io_pipeRsp_bits_dbID              (mainPipe_toTXRSP_bits_dbID),
    .io_pipeRsp_bits_chiOpcode         (mainPipe_toTXRSP_bits_chiOpcode),
    .io_pipeRsp_bits_resp              (mainPipe_toTXRSP_bits_resp),
    .io_pipeRsp_bits_fwdState          (mainPipe_toTXRSP_bits_fwdState),
    .io_pipeRsp_bits_pCrdType          (mainPipe_toTXRSP_bits_pCrdType),
    .io_pipeRsp_bits_traceTag          (mainPipe_toTXRSP_bits_traceTag),
    .io_mshrRsp_ready                  (txrsp_mshrRsp_ready),
    .io_mshrRsp_valid                  (mshrCtl_toTXRSP_valid),
    .io_mshrRsp_bits_tgtID             (mshrCtl_toTXRSP_bits_tgtID),
    .io_mshrRsp_bits_txnID             (mshrCtl_toTXRSP_bits_txnID),
    .io_mshrRsp_bits_opcode            (mshrCtl_toTXRSP_bits_opcode),
    .io_mshrRsp_bits_traceTag          (mshrCtl_toTXRSP_bits_traceTag),
    .io_out_ready                      (io_out_tx_rsp_ready),
    .io_out_valid                      (io_out_tx_rsp_valid),
    .io_out_bits_qos                   (io_out_tx_rsp_bits_qos),
    .io_out_bits_tgtID                 (io_out_tx_rsp_bits_tgtID),
    .io_out_bits_txnID                 (io_out_tx_rsp_bits_txnID),
    .io_out_bits_opcode                (io_out_tx_rsp_bits_opcode),
    .io_out_bits_respErr               (io_out_tx_rsp_bits_respErr),
    .io_out_bits_resp                  (io_out_tx_rsp_bits_resp),
    .io_out_bits_fwdState              (io_out_tx_rsp_bits_fwdState),
    .io_out_bits_cBusy                 (io_out_tx_rsp_bits_cBusy),
    .io_out_bits_dbID                  (io_out_tx_rsp_bits_dbID),
    .io_out_bits_pCrdType              (io_out_tx_rsp_bits_pCrdType),
    .io_out_bits_tagOp                 (io_out_tx_rsp_bits_tagOp),
    .io_out_bits_traceTag              (io_out_tx_rsp_bits_traceTag),
    .io_pipeStatusVec_1_valid          (reqArb_status_vec_toTX_1_valid),
    .io_pipeStatusVec_1_bits_channel   (reqArb_status_vec_toTX_1_bits_channel),
    .io_pipeStatusVec_1_bits_txChannel (reqArb_status_vec_toTX_1_bits_txChannel),
    .io_pipeStatusVec_1_bits_mshrTask  (reqArb_status_vec_toTX_1_bits_mshrTask),
    .io_pipeStatusVec_2_valid          (mainPipe_status_vec_toTX_0_valid),
    .io_pipeStatusVec_2_bits_channel   (mainPipe_status_vec_toTX_0_bits_channel),
    .io_pipeStatusVec_2_bits_txChannel (mainPipe_status_vec_toTX_0_bits_txChannel),
    .io_pipeStatusVec_2_bits_mshrTask  (mainPipe_status_vec_toTX_0_bits_mshrTask),
    .io_pipeStatusVec_3_valid          (mainPipe_status_vec_toTX_1_valid),
    .io_pipeStatusVec_3_bits_channel   (mainPipe_status_vec_toTX_1_bits_channel),
    .io_pipeStatusVec_3_bits_txChannel (mainPipe_status_vec_toTX_1_bits_txChannel),
    .io_pipeStatusVec_3_bits_mshrTask  (mainPipe_status_vec_toTX_1_bits_mshrTask),
    .io_pipeStatusVec_4_valid          (mainPipe_status_vec_toTX_2_valid),
    .io_pipeStatusVec_4_bits_channel   (mainPipe_status_vec_toTX_2_bits_channel),
    .io_pipeStatusVec_4_bits_txChannel (mainPipe_status_vec_toTX_2_bits_txChannel),
    .io_pipeStatusVec_4_bits_mshrTask  (mainPipe_status_vec_toTX_2_bits_mshrTask),
    .io_toReqArb_blockMSHRReqEntrance  (txrsp_toReqArb_blockMSHRReqEntrance),
    .io_toReqArb_blockSinkBReqEntrance (txrsp_toReqArb_blockSinkBReqEntrance)
  );

  // RXSNP：CHI 上行 snoop 接收，转成 B 通道 task 送 RequestArb（与在途 MSHR 冲突时挡住）
  RXSNP rxsnp (
    .clock                                      (clock),
    .reset                                      (reset),
    .io_rxsnp_ready                             (io_out_rx_snp_ready),
    .io_rxsnp_valid                             (io_out_rx_snp_valid),
    .io_rxsnp_bits_qos                          (io_out_rx_snp_bits_qos),
    .io_rxsnp_bits_srcID                        (io_out_rx_snp_bits_srcID),
    .io_rxsnp_bits_txnID                        (io_out_rx_snp_bits_txnID),
    .io_rxsnp_bits_fwdNID                       (io_out_rx_snp_bits_fwdNID),
    .io_rxsnp_bits_fwdTxnID                     (io_out_rx_snp_bits_fwdTxnID),
    .io_rxsnp_bits_opcode                       (io_out_rx_snp_bits_opcode),
    .io_rxsnp_bits_addr                         (io_out_rx_snp_bits_addr),
    .io_rxsnp_bits_ns                           (io_out_rx_snp_bits_ns),
    .io_rxsnp_bits_doNotGoToSD                  (io_out_rx_snp_bits_doNotGoToSD),
    .io_rxsnp_bits_retToSrc                     (io_out_rx_snp_bits_retToSrc),
    .io_rxsnp_bits_traceTag                     (io_out_rx_snp_bits_traceTag),
    .io_rxsnp_bits_mpam_perfMonGroup            (io_out_rx_snp_bits_mpam_perfMonGroup),
    .io_rxsnp_bits_mpam_partID                  (io_out_rx_snp_bits_mpam_partID),
    .io_rxsnp_bits_mpam_mpamNS                  (io_out_rx_snp_bits_mpam_mpamNS),
    .io_task_ready                              (reqArb_sinkB_ready),
    .io_task_valid                              (rxsnp_task_valid),
    .io_task_bits_set                           (rxsnp_task_bits_set),
    .io_task_bits_tag                           (rxsnp_task_bits_tag),
    .io_task_bits_off                           (rxsnp_task_bits_off),
    .io_task_bits_snpHitRelease                 (rxsnp_task_bits_snpHitRelease),
    .io_task_bits_snpHitReleaseToInval          (rxsnp_task_bits_snpHitReleaseToInval),
    .io_task_bits_snpHitReleaseToClean          (rxsnp_task_bits_snpHitReleaseToClean),
    .io_task_bits_snpHitReleaseWithData         (rxsnp_task_bits_snpHitReleaseWithData),
    .io_task_bits_snpHitReleaseIdx              (rxsnp_task_bits_snpHitReleaseIdx),
    .io_task_bits_snpHitReleaseMeta_dirty       (rxsnp_task_bits_snpHitReleaseMeta_dirty),
    .io_task_bits_snpHitReleaseMeta_state       (rxsnp_task_bits_snpHitReleaseMeta_state),
    .io_task_bits_snpHitReleaseMeta_clients     (rxsnp_task_bits_snpHitReleaseMeta_clients),
    .io_task_bits_snpHitReleaseMeta_alias       (rxsnp_task_bits_snpHitReleaseMeta_alias),
    .io_task_bits_snpHitReleaseMeta_prefetch    (rxsnp_task_bits_snpHitReleaseMeta_prefetch),
    .io_task_bits_snpHitReleaseMeta_prefetchSrc (rxsnp_task_bits_snpHitReleaseMeta_prefetchSrc),
    .io_task_bits_snpHitReleaseMeta_accessed    (rxsnp_task_bits_snpHitReleaseMeta_accessed),
    .io_task_bits_snpHitReleaseMeta_tagErr      (rxsnp_task_bits_snpHitReleaseMeta_tagErr),
    .io_task_bits_snpHitReleaseMeta_dataErr     (rxsnp_task_bits_snpHitReleaseMeta_dataErr),
    .io_task_bits_srcID                         (rxsnp_task_bits_srcID),
    .io_task_bits_txnID                         (rxsnp_task_bits_txnID),
    .io_task_bits_fwdNID                        (rxsnp_task_bits_fwdNID),
    .io_task_bits_fwdTxnID                      (rxsnp_task_bits_fwdTxnID),
    .io_task_bits_chiOpcode                     (rxsnp_task_bits_chiOpcode),
    .io_task_bits_retToSrc                      (rxsnp_task_bits_retToSrc),
    .io_task_bits_traceTag                      (rxsnp_task_bits_traceTag),
    .io_msInfo_0_valid                          (mshrCtl_msInfo_0_valid),
    .io_msInfo_0_bits_set                       (mshrCtl_msInfo_0_bits_set),
    .io_msInfo_0_bits_reqTag                    (mshrCtl_msInfo_0_bits_reqTag),
    .io_msInfo_0_bits_willFree                  (mshrCtl_msInfo_0_bits_willFree),
    .io_msInfo_0_bits_aliasTask                 (mshrCtl_msInfo_0_bits_aliasTask),
    .io_msInfo_0_bits_blockRefill               (mshrCtl_msInfo_0_bits_blockRefill),
    .io_msInfo_0_bits_meta_dirty                (mshrCtl_msInfo_0_bits_meta_dirty),
    .io_msInfo_0_bits_meta_state                (mshrCtl_msInfo_0_bits_meta_state),
    .io_msInfo_0_bits_meta_clients              (mshrCtl_msInfo_0_bits_meta_clients),
    .io_msInfo_0_bits_meta_alias                (mshrCtl_msInfo_0_bits_meta_alias),
    .io_msInfo_0_bits_meta_prefetch             (mshrCtl_msInfo_0_bits_meta_prefetch),
    .io_msInfo_0_bits_meta_prefetchSrc          (mshrCtl_msInfo_0_bits_meta_prefetchSrc),
    .io_msInfo_0_bits_meta_accessed             (mshrCtl_msInfo_0_bits_meta_accessed),
    .io_msInfo_0_bits_meta_tagErr               (mshrCtl_msInfo_0_bits_meta_tagErr),
    .io_msInfo_0_bits_meta_dataErr              (mshrCtl_msInfo_0_bits_meta_dataErr),
    .io_msInfo_0_bits_metaTag                   (mshrCtl_msInfo_0_bits_metaTag),
    .io_msInfo_0_bits_dirHit                    (mshrCtl_msInfo_0_bits_dirHit),
    .io_msInfo_0_bits_w_grantfirst              (mshrCtl_msInfo_0_bits_w_grantfirst),
    .io_msInfo_0_bits_s_release                 (mshrCtl_msInfo_0_bits_s_release),
    .io_msInfo_0_bits_s_cmoresp                 (mshrCtl_msInfo_0_bits_s_cmoresp),
    .io_msInfo_0_bits_s_cmometaw                (mshrCtl_msInfo_0_bits_s_cmometaw),
    .io_msInfo_0_bits_w_releaseack              (mshrCtl_msInfo_0_bits_w_releaseack),
    .io_msInfo_0_bits_w_replResp                (mshrCtl_msInfo_0_bits_w_replResp),
    .io_msInfo_0_bits_w_rprobeacklast           (mshrCtl_msInfo_0_bits_w_rprobeacklast),
    .io_msInfo_0_bits_replaceData               (mshrCtl_msInfo_0_bits_replaceData),
    .io_msInfo_0_bits_releaseToClean            (mshrCtl_msInfo_0_bits_releaseToClean),
    .io_msInfo_1_valid                          (mshrCtl_msInfo_1_valid),
    .io_msInfo_1_bits_set                       (mshrCtl_msInfo_1_bits_set),
    .io_msInfo_1_bits_reqTag                    (mshrCtl_msInfo_1_bits_reqTag),
    .io_msInfo_1_bits_willFree                  (mshrCtl_msInfo_1_bits_willFree),
    .io_msInfo_1_bits_aliasTask                 (mshrCtl_msInfo_1_bits_aliasTask),
    .io_msInfo_1_bits_blockRefill               (mshrCtl_msInfo_1_bits_blockRefill),
    .io_msInfo_1_bits_meta_dirty                (mshrCtl_msInfo_1_bits_meta_dirty),
    .io_msInfo_1_bits_meta_state                (mshrCtl_msInfo_1_bits_meta_state),
    .io_msInfo_1_bits_meta_clients              (mshrCtl_msInfo_1_bits_meta_clients),
    .io_msInfo_1_bits_meta_alias                (mshrCtl_msInfo_1_bits_meta_alias),
    .io_msInfo_1_bits_meta_prefetch             (mshrCtl_msInfo_1_bits_meta_prefetch),
    .io_msInfo_1_bits_meta_prefetchSrc          (mshrCtl_msInfo_1_bits_meta_prefetchSrc),
    .io_msInfo_1_bits_meta_accessed             (mshrCtl_msInfo_1_bits_meta_accessed),
    .io_msInfo_1_bits_meta_tagErr               (mshrCtl_msInfo_1_bits_meta_tagErr),
    .io_msInfo_1_bits_meta_dataErr              (mshrCtl_msInfo_1_bits_meta_dataErr),
    .io_msInfo_1_bits_metaTag                   (mshrCtl_msInfo_1_bits_metaTag),
    .io_msInfo_1_bits_dirHit                    (mshrCtl_msInfo_1_bits_dirHit),
    .io_msInfo_1_bits_w_grantfirst              (mshrCtl_msInfo_1_bits_w_grantfirst),
    .io_msInfo_1_bits_s_release                 (mshrCtl_msInfo_1_bits_s_release),
    .io_msInfo_1_bits_s_cmoresp                 (mshrCtl_msInfo_1_bits_s_cmoresp),
    .io_msInfo_1_bits_s_cmometaw                (mshrCtl_msInfo_1_bits_s_cmometaw),
    .io_msInfo_1_bits_w_releaseack              (mshrCtl_msInfo_1_bits_w_releaseack),
    .io_msInfo_1_bits_w_replResp                (mshrCtl_msInfo_1_bits_w_replResp),
    .io_msInfo_1_bits_w_rprobeacklast           (mshrCtl_msInfo_1_bits_w_rprobeacklast),
    .io_msInfo_1_bits_replaceData               (mshrCtl_msInfo_1_bits_replaceData),
    .io_msInfo_1_bits_releaseToClean            (mshrCtl_msInfo_1_bits_releaseToClean),
    .io_msInfo_2_valid                          (mshrCtl_msInfo_2_valid),
    .io_msInfo_2_bits_set                       (mshrCtl_msInfo_2_bits_set),
    .io_msInfo_2_bits_reqTag                    (mshrCtl_msInfo_2_bits_reqTag),
    .io_msInfo_2_bits_willFree                  (mshrCtl_msInfo_2_bits_willFree),
    .io_msInfo_2_bits_aliasTask                 (mshrCtl_msInfo_2_bits_aliasTask),
    .io_msInfo_2_bits_blockRefill               (mshrCtl_msInfo_2_bits_blockRefill),
    .io_msInfo_2_bits_meta_dirty                (mshrCtl_msInfo_2_bits_meta_dirty),
    .io_msInfo_2_bits_meta_state                (mshrCtl_msInfo_2_bits_meta_state),
    .io_msInfo_2_bits_meta_clients              (mshrCtl_msInfo_2_bits_meta_clients),
    .io_msInfo_2_bits_meta_alias                (mshrCtl_msInfo_2_bits_meta_alias),
    .io_msInfo_2_bits_meta_prefetch             (mshrCtl_msInfo_2_bits_meta_prefetch),
    .io_msInfo_2_bits_meta_prefetchSrc          (mshrCtl_msInfo_2_bits_meta_prefetchSrc),
    .io_msInfo_2_bits_meta_accessed             (mshrCtl_msInfo_2_bits_meta_accessed),
    .io_msInfo_2_bits_meta_tagErr               (mshrCtl_msInfo_2_bits_meta_tagErr),
    .io_msInfo_2_bits_meta_dataErr              (mshrCtl_msInfo_2_bits_meta_dataErr),
    .io_msInfo_2_bits_metaTag                   (mshrCtl_msInfo_2_bits_metaTag),
    .io_msInfo_2_bits_dirHit                    (mshrCtl_msInfo_2_bits_dirHit),
    .io_msInfo_2_bits_w_grantfirst              (mshrCtl_msInfo_2_bits_w_grantfirst),
    .io_msInfo_2_bits_s_release                 (mshrCtl_msInfo_2_bits_s_release),
    .io_msInfo_2_bits_s_cmoresp                 (mshrCtl_msInfo_2_bits_s_cmoresp),
    .io_msInfo_2_bits_s_cmometaw                (mshrCtl_msInfo_2_bits_s_cmometaw),
    .io_msInfo_2_bits_w_releaseack              (mshrCtl_msInfo_2_bits_w_releaseack),
    .io_msInfo_2_bits_w_replResp                (mshrCtl_msInfo_2_bits_w_replResp),
    .io_msInfo_2_bits_w_rprobeacklast           (mshrCtl_msInfo_2_bits_w_rprobeacklast),
    .io_msInfo_2_bits_replaceData               (mshrCtl_msInfo_2_bits_replaceData),
    .io_msInfo_2_bits_releaseToClean            (mshrCtl_msInfo_2_bits_releaseToClean),
    .io_msInfo_3_valid                          (mshrCtl_msInfo_3_valid),
    .io_msInfo_3_bits_set                       (mshrCtl_msInfo_3_bits_set),
    .io_msInfo_3_bits_reqTag                    (mshrCtl_msInfo_3_bits_reqTag),
    .io_msInfo_3_bits_willFree                  (mshrCtl_msInfo_3_bits_willFree),
    .io_msInfo_3_bits_aliasTask                 (mshrCtl_msInfo_3_bits_aliasTask),
    .io_msInfo_3_bits_blockRefill               (mshrCtl_msInfo_3_bits_blockRefill),
    .io_msInfo_3_bits_meta_dirty                (mshrCtl_msInfo_3_bits_meta_dirty),
    .io_msInfo_3_bits_meta_state                (mshrCtl_msInfo_3_bits_meta_state),
    .io_msInfo_3_bits_meta_clients              (mshrCtl_msInfo_3_bits_meta_clients),
    .io_msInfo_3_bits_meta_alias                (mshrCtl_msInfo_3_bits_meta_alias),
    .io_msInfo_3_bits_meta_prefetch             (mshrCtl_msInfo_3_bits_meta_prefetch),
    .io_msInfo_3_bits_meta_prefetchSrc          (mshrCtl_msInfo_3_bits_meta_prefetchSrc),
    .io_msInfo_3_bits_meta_accessed             (mshrCtl_msInfo_3_bits_meta_accessed),
    .io_msInfo_3_bits_meta_tagErr               (mshrCtl_msInfo_3_bits_meta_tagErr),
    .io_msInfo_3_bits_meta_dataErr              (mshrCtl_msInfo_3_bits_meta_dataErr),
    .io_msInfo_3_bits_metaTag                   (mshrCtl_msInfo_3_bits_metaTag),
    .io_msInfo_3_bits_dirHit                    (mshrCtl_msInfo_3_bits_dirHit),
    .io_msInfo_3_bits_w_grantfirst              (mshrCtl_msInfo_3_bits_w_grantfirst),
    .io_msInfo_3_bits_s_release                 (mshrCtl_msInfo_3_bits_s_release),
    .io_msInfo_3_bits_s_cmoresp                 (mshrCtl_msInfo_3_bits_s_cmoresp),
    .io_msInfo_3_bits_s_cmometaw                (mshrCtl_msInfo_3_bits_s_cmometaw),
    .io_msInfo_3_bits_w_releaseack              (mshrCtl_msInfo_3_bits_w_releaseack),
    .io_msInfo_3_bits_w_replResp                (mshrCtl_msInfo_3_bits_w_replResp),
    .io_msInfo_3_bits_w_rprobeacklast           (mshrCtl_msInfo_3_bits_w_rprobeacklast),
    .io_msInfo_3_bits_replaceData               (mshrCtl_msInfo_3_bits_replaceData),
    .io_msInfo_3_bits_releaseToClean            (mshrCtl_msInfo_3_bits_releaseToClean),
    .io_msInfo_4_valid                          (mshrCtl_msInfo_4_valid),
    .io_msInfo_4_bits_set                       (mshrCtl_msInfo_4_bits_set),
    .io_msInfo_4_bits_reqTag                    (mshrCtl_msInfo_4_bits_reqTag),
    .io_msInfo_4_bits_willFree                  (mshrCtl_msInfo_4_bits_willFree),
    .io_msInfo_4_bits_aliasTask                 (mshrCtl_msInfo_4_bits_aliasTask),
    .io_msInfo_4_bits_blockRefill               (mshrCtl_msInfo_4_bits_blockRefill),
    .io_msInfo_4_bits_meta_dirty                (mshrCtl_msInfo_4_bits_meta_dirty),
    .io_msInfo_4_bits_meta_state                (mshrCtl_msInfo_4_bits_meta_state),
    .io_msInfo_4_bits_meta_clients              (mshrCtl_msInfo_4_bits_meta_clients),
    .io_msInfo_4_bits_meta_alias                (mshrCtl_msInfo_4_bits_meta_alias),
    .io_msInfo_4_bits_meta_prefetch             (mshrCtl_msInfo_4_bits_meta_prefetch),
    .io_msInfo_4_bits_meta_prefetchSrc          (mshrCtl_msInfo_4_bits_meta_prefetchSrc),
    .io_msInfo_4_bits_meta_accessed             (mshrCtl_msInfo_4_bits_meta_accessed),
    .io_msInfo_4_bits_meta_tagErr               (mshrCtl_msInfo_4_bits_meta_tagErr),
    .io_msInfo_4_bits_meta_dataErr              (mshrCtl_msInfo_4_bits_meta_dataErr),
    .io_msInfo_4_bits_metaTag                   (mshrCtl_msInfo_4_bits_metaTag),
    .io_msInfo_4_bits_dirHit                    (mshrCtl_msInfo_4_bits_dirHit),
    .io_msInfo_4_bits_w_grantfirst              (mshrCtl_msInfo_4_bits_w_grantfirst),
    .io_msInfo_4_bits_s_release                 (mshrCtl_msInfo_4_bits_s_release),
    .io_msInfo_4_bits_s_cmoresp                 (mshrCtl_msInfo_4_bits_s_cmoresp),
    .io_msInfo_4_bits_s_cmometaw                (mshrCtl_msInfo_4_bits_s_cmometaw),
    .io_msInfo_4_bits_w_releaseack              (mshrCtl_msInfo_4_bits_w_releaseack),
    .io_msInfo_4_bits_w_replResp                (mshrCtl_msInfo_4_bits_w_replResp),
    .io_msInfo_4_bits_w_rprobeacklast           (mshrCtl_msInfo_4_bits_w_rprobeacklast),
    .io_msInfo_4_bits_replaceData               (mshrCtl_msInfo_4_bits_replaceData),
    .io_msInfo_4_bits_releaseToClean            (mshrCtl_msInfo_4_bits_releaseToClean),
    .io_msInfo_5_valid                          (mshrCtl_msInfo_5_valid),
    .io_msInfo_5_bits_set                       (mshrCtl_msInfo_5_bits_set),
    .io_msInfo_5_bits_reqTag                    (mshrCtl_msInfo_5_bits_reqTag),
    .io_msInfo_5_bits_willFree                  (mshrCtl_msInfo_5_bits_willFree),
    .io_msInfo_5_bits_aliasTask                 (mshrCtl_msInfo_5_bits_aliasTask),
    .io_msInfo_5_bits_blockRefill               (mshrCtl_msInfo_5_bits_blockRefill),
    .io_msInfo_5_bits_meta_dirty                (mshrCtl_msInfo_5_bits_meta_dirty),
    .io_msInfo_5_bits_meta_state                (mshrCtl_msInfo_5_bits_meta_state),
    .io_msInfo_5_bits_meta_clients              (mshrCtl_msInfo_5_bits_meta_clients),
    .io_msInfo_5_bits_meta_alias                (mshrCtl_msInfo_5_bits_meta_alias),
    .io_msInfo_5_bits_meta_prefetch             (mshrCtl_msInfo_5_bits_meta_prefetch),
    .io_msInfo_5_bits_meta_prefetchSrc          (mshrCtl_msInfo_5_bits_meta_prefetchSrc),
    .io_msInfo_5_bits_meta_accessed             (mshrCtl_msInfo_5_bits_meta_accessed),
    .io_msInfo_5_bits_meta_tagErr               (mshrCtl_msInfo_5_bits_meta_tagErr),
    .io_msInfo_5_bits_meta_dataErr              (mshrCtl_msInfo_5_bits_meta_dataErr),
    .io_msInfo_5_bits_metaTag                   (mshrCtl_msInfo_5_bits_metaTag),
    .io_msInfo_5_bits_dirHit                    (mshrCtl_msInfo_5_bits_dirHit),
    .io_msInfo_5_bits_w_grantfirst              (mshrCtl_msInfo_5_bits_w_grantfirst),
    .io_msInfo_5_bits_s_release                 (mshrCtl_msInfo_5_bits_s_release),
    .io_msInfo_5_bits_s_cmoresp                 (mshrCtl_msInfo_5_bits_s_cmoresp),
    .io_msInfo_5_bits_s_cmometaw                (mshrCtl_msInfo_5_bits_s_cmometaw),
    .io_msInfo_5_bits_w_releaseack              (mshrCtl_msInfo_5_bits_w_releaseack),
    .io_msInfo_5_bits_w_replResp                (mshrCtl_msInfo_5_bits_w_replResp),
    .io_msInfo_5_bits_w_rprobeacklast           (mshrCtl_msInfo_5_bits_w_rprobeacklast),
    .io_msInfo_5_bits_replaceData               (mshrCtl_msInfo_5_bits_replaceData),
    .io_msInfo_5_bits_releaseToClean            (mshrCtl_msInfo_5_bits_releaseToClean),
    .io_msInfo_6_valid                          (mshrCtl_msInfo_6_valid),
    .io_msInfo_6_bits_set                       (mshrCtl_msInfo_6_bits_set),
    .io_msInfo_6_bits_reqTag                    (mshrCtl_msInfo_6_bits_reqTag),
    .io_msInfo_6_bits_willFree                  (mshrCtl_msInfo_6_bits_willFree),
    .io_msInfo_6_bits_aliasTask                 (mshrCtl_msInfo_6_bits_aliasTask),
    .io_msInfo_6_bits_blockRefill               (mshrCtl_msInfo_6_bits_blockRefill),
    .io_msInfo_6_bits_meta_dirty                (mshrCtl_msInfo_6_bits_meta_dirty),
    .io_msInfo_6_bits_meta_state                (mshrCtl_msInfo_6_bits_meta_state),
    .io_msInfo_6_bits_meta_clients              (mshrCtl_msInfo_6_bits_meta_clients),
    .io_msInfo_6_bits_meta_alias                (mshrCtl_msInfo_6_bits_meta_alias),
    .io_msInfo_6_bits_meta_prefetch             (mshrCtl_msInfo_6_bits_meta_prefetch),
    .io_msInfo_6_bits_meta_prefetchSrc          (mshrCtl_msInfo_6_bits_meta_prefetchSrc),
    .io_msInfo_6_bits_meta_accessed             (mshrCtl_msInfo_6_bits_meta_accessed),
    .io_msInfo_6_bits_meta_tagErr               (mshrCtl_msInfo_6_bits_meta_tagErr),
    .io_msInfo_6_bits_meta_dataErr              (mshrCtl_msInfo_6_bits_meta_dataErr),
    .io_msInfo_6_bits_metaTag                   (mshrCtl_msInfo_6_bits_metaTag),
    .io_msInfo_6_bits_dirHit                    (mshrCtl_msInfo_6_bits_dirHit),
    .io_msInfo_6_bits_w_grantfirst              (mshrCtl_msInfo_6_bits_w_grantfirst),
    .io_msInfo_6_bits_s_release                 (mshrCtl_msInfo_6_bits_s_release),
    .io_msInfo_6_bits_s_cmoresp                 (mshrCtl_msInfo_6_bits_s_cmoresp),
    .io_msInfo_6_bits_s_cmometaw                (mshrCtl_msInfo_6_bits_s_cmometaw),
    .io_msInfo_6_bits_w_releaseack              (mshrCtl_msInfo_6_bits_w_releaseack),
    .io_msInfo_6_bits_w_replResp                (mshrCtl_msInfo_6_bits_w_replResp),
    .io_msInfo_6_bits_w_rprobeacklast           (mshrCtl_msInfo_6_bits_w_rprobeacklast),
    .io_msInfo_6_bits_replaceData               (mshrCtl_msInfo_6_bits_replaceData),
    .io_msInfo_6_bits_releaseToClean            (mshrCtl_msInfo_6_bits_releaseToClean),
    .io_msInfo_7_valid                          (mshrCtl_msInfo_7_valid),
    .io_msInfo_7_bits_set                       (mshrCtl_msInfo_7_bits_set),
    .io_msInfo_7_bits_reqTag                    (mshrCtl_msInfo_7_bits_reqTag),
    .io_msInfo_7_bits_willFree                  (mshrCtl_msInfo_7_bits_willFree),
    .io_msInfo_7_bits_aliasTask                 (mshrCtl_msInfo_7_bits_aliasTask),
    .io_msInfo_7_bits_blockRefill               (mshrCtl_msInfo_7_bits_blockRefill),
    .io_msInfo_7_bits_meta_dirty                (mshrCtl_msInfo_7_bits_meta_dirty),
    .io_msInfo_7_bits_meta_state                (mshrCtl_msInfo_7_bits_meta_state),
    .io_msInfo_7_bits_meta_clients              (mshrCtl_msInfo_7_bits_meta_clients),
    .io_msInfo_7_bits_meta_alias                (mshrCtl_msInfo_7_bits_meta_alias),
    .io_msInfo_7_bits_meta_prefetch             (mshrCtl_msInfo_7_bits_meta_prefetch),
    .io_msInfo_7_bits_meta_prefetchSrc          (mshrCtl_msInfo_7_bits_meta_prefetchSrc),
    .io_msInfo_7_bits_meta_accessed             (mshrCtl_msInfo_7_bits_meta_accessed),
    .io_msInfo_7_bits_meta_tagErr               (mshrCtl_msInfo_7_bits_meta_tagErr),
    .io_msInfo_7_bits_meta_dataErr              (mshrCtl_msInfo_7_bits_meta_dataErr),
    .io_msInfo_7_bits_metaTag                   (mshrCtl_msInfo_7_bits_metaTag),
    .io_msInfo_7_bits_dirHit                    (mshrCtl_msInfo_7_bits_dirHit),
    .io_msInfo_7_bits_w_grantfirst              (mshrCtl_msInfo_7_bits_w_grantfirst),
    .io_msInfo_7_bits_s_release                 (mshrCtl_msInfo_7_bits_s_release),
    .io_msInfo_7_bits_s_cmoresp                 (mshrCtl_msInfo_7_bits_s_cmoresp),
    .io_msInfo_7_bits_s_cmometaw                (mshrCtl_msInfo_7_bits_s_cmometaw),
    .io_msInfo_7_bits_w_releaseack              (mshrCtl_msInfo_7_bits_w_releaseack),
    .io_msInfo_7_bits_w_replResp                (mshrCtl_msInfo_7_bits_w_replResp),
    .io_msInfo_7_bits_w_rprobeacklast           (mshrCtl_msInfo_7_bits_w_rprobeacklast),
    .io_msInfo_7_bits_replaceData               (mshrCtl_msInfo_7_bits_replaceData),
    .io_msInfo_7_bits_releaseToClean            (mshrCtl_msInfo_7_bits_releaseToClean),
    .io_msInfo_8_valid                          (mshrCtl_msInfo_8_valid),
    .io_msInfo_8_bits_set                       (mshrCtl_msInfo_8_bits_set),
    .io_msInfo_8_bits_reqTag                    (mshrCtl_msInfo_8_bits_reqTag),
    .io_msInfo_8_bits_willFree                  (mshrCtl_msInfo_8_bits_willFree),
    .io_msInfo_8_bits_aliasTask                 (mshrCtl_msInfo_8_bits_aliasTask),
    .io_msInfo_8_bits_blockRefill               (mshrCtl_msInfo_8_bits_blockRefill),
    .io_msInfo_8_bits_meta_dirty                (mshrCtl_msInfo_8_bits_meta_dirty),
    .io_msInfo_8_bits_meta_state                (mshrCtl_msInfo_8_bits_meta_state),
    .io_msInfo_8_bits_meta_clients              (mshrCtl_msInfo_8_bits_meta_clients),
    .io_msInfo_8_bits_meta_alias                (mshrCtl_msInfo_8_bits_meta_alias),
    .io_msInfo_8_bits_meta_prefetch             (mshrCtl_msInfo_8_bits_meta_prefetch),
    .io_msInfo_8_bits_meta_prefetchSrc          (mshrCtl_msInfo_8_bits_meta_prefetchSrc),
    .io_msInfo_8_bits_meta_accessed             (mshrCtl_msInfo_8_bits_meta_accessed),
    .io_msInfo_8_bits_meta_tagErr               (mshrCtl_msInfo_8_bits_meta_tagErr),
    .io_msInfo_8_bits_meta_dataErr              (mshrCtl_msInfo_8_bits_meta_dataErr),
    .io_msInfo_8_bits_metaTag                   (mshrCtl_msInfo_8_bits_metaTag),
    .io_msInfo_8_bits_dirHit                    (mshrCtl_msInfo_8_bits_dirHit),
    .io_msInfo_8_bits_w_grantfirst              (mshrCtl_msInfo_8_bits_w_grantfirst),
    .io_msInfo_8_bits_s_release                 (mshrCtl_msInfo_8_bits_s_release),
    .io_msInfo_8_bits_s_cmoresp                 (mshrCtl_msInfo_8_bits_s_cmoresp),
    .io_msInfo_8_bits_s_cmometaw                (mshrCtl_msInfo_8_bits_s_cmometaw),
    .io_msInfo_8_bits_w_releaseack              (mshrCtl_msInfo_8_bits_w_releaseack),
    .io_msInfo_8_bits_w_replResp                (mshrCtl_msInfo_8_bits_w_replResp),
    .io_msInfo_8_bits_w_rprobeacklast           (mshrCtl_msInfo_8_bits_w_rprobeacklast),
    .io_msInfo_8_bits_replaceData               (mshrCtl_msInfo_8_bits_replaceData),
    .io_msInfo_8_bits_releaseToClean            (mshrCtl_msInfo_8_bits_releaseToClean),
    .io_msInfo_9_valid                          (mshrCtl_msInfo_9_valid),
    .io_msInfo_9_bits_set                       (mshrCtl_msInfo_9_bits_set),
    .io_msInfo_9_bits_reqTag                    (mshrCtl_msInfo_9_bits_reqTag),
    .io_msInfo_9_bits_willFree                  (mshrCtl_msInfo_9_bits_willFree),
    .io_msInfo_9_bits_aliasTask                 (mshrCtl_msInfo_9_bits_aliasTask),
    .io_msInfo_9_bits_blockRefill               (mshrCtl_msInfo_9_bits_blockRefill),
    .io_msInfo_9_bits_meta_dirty                (mshrCtl_msInfo_9_bits_meta_dirty),
    .io_msInfo_9_bits_meta_state                (mshrCtl_msInfo_9_bits_meta_state),
    .io_msInfo_9_bits_meta_clients              (mshrCtl_msInfo_9_bits_meta_clients),
    .io_msInfo_9_bits_meta_alias                (mshrCtl_msInfo_9_bits_meta_alias),
    .io_msInfo_9_bits_meta_prefetch             (mshrCtl_msInfo_9_bits_meta_prefetch),
    .io_msInfo_9_bits_meta_prefetchSrc          (mshrCtl_msInfo_9_bits_meta_prefetchSrc),
    .io_msInfo_9_bits_meta_accessed             (mshrCtl_msInfo_9_bits_meta_accessed),
    .io_msInfo_9_bits_meta_tagErr               (mshrCtl_msInfo_9_bits_meta_tagErr),
    .io_msInfo_9_bits_meta_dataErr              (mshrCtl_msInfo_9_bits_meta_dataErr),
    .io_msInfo_9_bits_metaTag                   (mshrCtl_msInfo_9_bits_metaTag),
    .io_msInfo_9_bits_dirHit                    (mshrCtl_msInfo_9_bits_dirHit),
    .io_msInfo_9_bits_w_grantfirst              (mshrCtl_msInfo_9_bits_w_grantfirst),
    .io_msInfo_9_bits_s_release                 (mshrCtl_msInfo_9_bits_s_release),
    .io_msInfo_9_bits_s_cmoresp                 (mshrCtl_msInfo_9_bits_s_cmoresp),
    .io_msInfo_9_bits_s_cmometaw                (mshrCtl_msInfo_9_bits_s_cmometaw),
    .io_msInfo_9_bits_w_releaseack              (mshrCtl_msInfo_9_bits_w_releaseack),
    .io_msInfo_9_bits_w_replResp                (mshrCtl_msInfo_9_bits_w_replResp),
    .io_msInfo_9_bits_w_rprobeacklast           (mshrCtl_msInfo_9_bits_w_rprobeacklast),
    .io_msInfo_9_bits_replaceData               (mshrCtl_msInfo_9_bits_replaceData),
    .io_msInfo_9_bits_releaseToClean            (mshrCtl_msInfo_9_bits_releaseToClean),
    .io_msInfo_10_valid                         (mshrCtl_msInfo_10_valid),
    .io_msInfo_10_bits_set                      (mshrCtl_msInfo_10_bits_set),
    .io_msInfo_10_bits_reqTag                   (mshrCtl_msInfo_10_bits_reqTag),
    .io_msInfo_10_bits_willFree                 (mshrCtl_msInfo_10_bits_willFree),
    .io_msInfo_10_bits_aliasTask                (mshrCtl_msInfo_10_bits_aliasTask),
    .io_msInfo_10_bits_blockRefill              (mshrCtl_msInfo_10_bits_blockRefill),
    .io_msInfo_10_bits_meta_dirty               (mshrCtl_msInfo_10_bits_meta_dirty),
    .io_msInfo_10_bits_meta_state               (mshrCtl_msInfo_10_bits_meta_state),
    .io_msInfo_10_bits_meta_clients             (mshrCtl_msInfo_10_bits_meta_clients),
    .io_msInfo_10_bits_meta_alias               (mshrCtl_msInfo_10_bits_meta_alias),
    .io_msInfo_10_bits_meta_prefetch            (mshrCtl_msInfo_10_bits_meta_prefetch),
    .io_msInfo_10_bits_meta_prefetchSrc         (mshrCtl_msInfo_10_bits_meta_prefetchSrc),
    .io_msInfo_10_bits_meta_accessed            (mshrCtl_msInfo_10_bits_meta_accessed),
    .io_msInfo_10_bits_meta_tagErr              (mshrCtl_msInfo_10_bits_meta_tagErr),
    .io_msInfo_10_bits_meta_dataErr             (mshrCtl_msInfo_10_bits_meta_dataErr),
    .io_msInfo_10_bits_metaTag                  (mshrCtl_msInfo_10_bits_metaTag),
    .io_msInfo_10_bits_dirHit                   (mshrCtl_msInfo_10_bits_dirHit),
    .io_msInfo_10_bits_w_grantfirst             (mshrCtl_msInfo_10_bits_w_grantfirst),
    .io_msInfo_10_bits_s_release                (mshrCtl_msInfo_10_bits_s_release),
    .io_msInfo_10_bits_s_cmoresp                (mshrCtl_msInfo_10_bits_s_cmoresp),
    .io_msInfo_10_bits_s_cmometaw               (mshrCtl_msInfo_10_bits_s_cmometaw),
    .io_msInfo_10_bits_w_releaseack             (mshrCtl_msInfo_10_bits_w_releaseack),
    .io_msInfo_10_bits_w_replResp               (mshrCtl_msInfo_10_bits_w_replResp),
    .io_msInfo_10_bits_w_rprobeacklast          (mshrCtl_msInfo_10_bits_w_rprobeacklast),
    .io_msInfo_10_bits_replaceData              (mshrCtl_msInfo_10_bits_replaceData),
    .io_msInfo_10_bits_releaseToClean           (mshrCtl_msInfo_10_bits_releaseToClean),
    .io_msInfo_11_valid                         (mshrCtl_msInfo_11_valid),
    .io_msInfo_11_bits_set                      (mshrCtl_msInfo_11_bits_set),
    .io_msInfo_11_bits_reqTag                   (mshrCtl_msInfo_11_bits_reqTag),
    .io_msInfo_11_bits_willFree                 (mshrCtl_msInfo_11_bits_willFree),
    .io_msInfo_11_bits_aliasTask                (mshrCtl_msInfo_11_bits_aliasTask),
    .io_msInfo_11_bits_blockRefill              (mshrCtl_msInfo_11_bits_blockRefill),
    .io_msInfo_11_bits_meta_dirty               (mshrCtl_msInfo_11_bits_meta_dirty),
    .io_msInfo_11_bits_meta_state               (mshrCtl_msInfo_11_bits_meta_state),
    .io_msInfo_11_bits_meta_clients             (mshrCtl_msInfo_11_bits_meta_clients),
    .io_msInfo_11_bits_meta_alias               (mshrCtl_msInfo_11_bits_meta_alias),
    .io_msInfo_11_bits_meta_prefetch            (mshrCtl_msInfo_11_bits_meta_prefetch),
    .io_msInfo_11_bits_meta_prefetchSrc         (mshrCtl_msInfo_11_bits_meta_prefetchSrc),
    .io_msInfo_11_bits_meta_accessed            (mshrCtl_msInfo_11_bits_meta_accessed),
    .io_msInfo_11_bits_meta_tagErr              (mshrCtl_msInfo_11_bits_meta_tagErr),
    .io_msInfo_11_bits_meta_dataErr             (mshrCtl_msInfo_11_bits_meta_dataErr),
    .io_msInfo_11_bits_metaTag                  (mshrCtl_msInfo_11_bits_metaTag),
    .io_msInfo_11_bits_dirHit                   (mshrCtl_msInfo_11_bits_dirHit),
    .io_msInfo_11_bits_w_grantfirst             (mshrCtl_msInfo_11_bits_w_grantfirst),
    .io_msInfo_11_bits_s_release                (mshrCtl_msInfo_11_bits_s_release),
    .io_msInfo_11_bits_s_cmoresp                (mshrCtl_msInfo_11_bits_s_cmoresp),
    .io_msInfo_11_bits_s_cmometaw               (mshrCtl_msInfo_11_bits_s_cmometaw),
    .io_msInfo_11_bits_w_releaseack             (mshrCtl_msInfo_11_bits_w_releaseack),
    .io_msInfo_11_bits_w_replResp               (mshrCtl_msInfo_11_bits_w_replResp),
    .io_msInfo_11_bits_w_rprobeacklast          (mshrCtl_msInfo_11_bits_w_rprobeacklast),
    .io_msInfo_11_bits_replaceData              (mshrCtl_msInfo_11_bits_replaceData),
    .io_msInfo_11_bits_releaseToClean           (mshrCtl_msInfo_11_bits_releaseToClean),
    .io_msInfo_12_valid                         (mshrCtl_msInfo_12_valid),
    .io_msInfo_12_bits_set                      (mshrCtl_msInfo_12_bits_set),
    .io_msInfo_12_bits_reqTag                   (mshrCtl_msInfo_12_bits_reqTag),
    .io_msInfo_12_bits_willFree                 (mshrCtl_msInfo_12_bits_willFree),
    .io_msInfo_12_bits_aliasTask                (mshrCtl_msInfo_12_bits_aliasTask),
    .io_msInfo_12_bits_blockRefill              (mshrCtl_msInfo_12_bits_blockRefill),
    .io_msInfo_12_bits_meta_dirty               (mshrCtl_msInfo_12_bits_meta_dirty),
    .io_msInfo_12_bits_meta_state               (mshrCtl_msInfo_12_bits_meta_state),
    .io_msInfo_12_bits_meta_clients             (mshrCtl_msInfo_12_bits_meta_clients),
    .io_msInfo_12_bits_meta_alias               (mshrCtl_msInfo_12_bits_meta_alias),
    .io_msInfo_12_bits_meta_prefetch            (mshrCtl_msInfo_12_bits_meta_prefetch),
    .io_msInfo_12_bits_meta_prefetchSrc         (mshrCtl_msInfo_12_bits_meta_prefetchSrc),
    .io_msInfo_12_bits_meta_accessed            (mshrCtl_msInfo_12_bits_meta_accessed),
    .io_msInfo_12_bits_meta_tagErr              (mshrCtl_msInfo_12_bits_meta_tagErr),
    .io_msInfo_12_bits_meta_dataErr             (mshrCtl_msInfo_12_bits_meta_dataErr),
    .io_msInfo_12_bits_metaTag                  (mshrCtl_msInfo_12_bits_metaTag),
    .io_msInfo_12_bits_dirHit                   (mshrCtl_msInfo_12_bits_dirHit),
    .io_msInfo_12_bits_w_grantfirst             (mshrCtl_msInfo_12_bits_w_grantfirst),
    .io_msInfo_12_bits_s_release                (mshrCtl_msInfo_12_bits_s_release),
    .io_msInfo_12_bits_s_cmoresp                (mshrCtl_msInfo_12_bits_s_cmoresp),
    .io_msInfo_12_bits_s_cmometaw               (mshrCtl_msInfo_12_bits_s_cmometaw),
    .io_msInfo_12_bits_w_releaseack             (mshrCtl_msInfo_12_bits_w_releaseack),
    .io_msInfo_12_bits_w_replResp               (mshrCtl_msInfo_12_bits_w_replResp),
    .io_msInfo_12_bits_w_rprobeacklast          (mshrCtl_msInfo_12_bits_w_rprobeacklast),
    .io_msInfo_12_bits_replaceData              (mshrCtl_msInfo_12_bits_replaceData),
    .io_msInfo_12_bits_releaseToClean           (mshrCtl_msInfo_12_bits_releaseToClean),
    .io_msInfo_13_valid                         (mshrCtl_msInfo_13_valid),
    .io_msInfo_13_bits_set                      (mshrCtl_msInfo_13_bits_set),
    .io_msInfo_13_bits_reqTag                   (mshrCtl_msInfo_13_bits_reqTag),
    .io_msInfo_13_bits_willFree                 (mshrCtl_msInfo_13_bits_willFree),
    .io_msInfo_13_bits_aliasTask                (mshrCtl_msInfo_13_bits_aliasTask),
    .io_msInfo_13_bits_blockRefill              (mshrCtl_msInfo_13_bits_blockRefill),
    .io_msInfo_13_bits_meta_dirty               (mshrCtl_msInfo_13_bits_meta_dirty),
    .io_msInfo_13_bits_meta_state               (mshrCtl_msInfo_13_bits_meta_state),
    .io_msInfo_13_bits_meta_clients             (mshrCtl_msInfo_13_bits_meta_clients),
    .io_msInfo_13_bits_meta_alias               (mshrCtl_msInfo_13_bits_meta_alias),
    .io_msInfo_13_bits_meta_prefetch            (mshrCtl_msInfo_13_bits_meta_prefetch),
    .io_msInfo_13_bits_meta_prefetchSrc         (mshrCtl_msInfo_13_bits_meta_prefetchSrc),
    .io_msInfo_13_bits_meta_accessed            (mshrCtl_msInfo_13_bits_meta_accessed),
    .io_msInfo_13_bits_meta_tagErr              (mshrCtl_msInfo_13_bits_meta_tagErr),
    .io_msInfo_13_bits_meta_dataErr             (mshrCtl_msInfo_13_bits_meta_dataErr),
    .io_msInfo_13_bits_metaTag                  (mshrCtl_msInfo_13_bits_metaTag),
    .io_msInfo_13_bits_dirHit                   (mshrCtl_msInfo_13_bits_dirHit),
    .io_msInfo_13_bits_w_grantfirst             (mshrCtl_msInfo_13_bits_w_grantfirst),
    .io_msInfo_13_bits_s_release                (mshrCtl_msInfo_13_bits_s_release),
    .io_msInfo_13_bits_s_cmoresp                (mshrCtl_msInfo_13_bits_s_cmoresp),
    .io_msInfo_13_bits_s_cmometaw               (mshrCtl_msInfo_13_bits_s_cmometaw),
    .io_msInfo_13_bits_w_releaseack             (mshrCtl_msInfo_13_bits_w_releaseack),
    .io_msInfo_13_bits_w_replResp               (mshrCtl_msInfo_13_bits_w_replResp),
    .io_msInfo_13_bits_w_rprobeacklast          (mshrCtl_msInfo_13_bits_w_rprobeacklast),
    .io_msInfo_13_bits_replaceData              (mshrCtl_msInfo_13_bits_replaceData),
    .io_msInfo_13_bits_releaseToClean           (mshrCtl_msInfo_13_bits_releaseToClean),
    .io_msInfo_14_valid                         (mshrCtl_msInfo_14_valid),
    .io_msInfo_14_bits_set                      (mshrCtl_msInfo_14_bits_set),
    .io_msInfo_14_bits_reqTag                   (mshrCtl_msInfo_14_bits_reqTag),
    .io_msInfo_14_bits_willFree                 (mshrCtl_msInfo_14_bits_willFree),
    .io_msInfo_14_bits_aliasTask                (mshrCtl_msInfo_14_bits_aliasTask),
    .io_msInfo_14_bits_blockRefill              (mshrCtl_msInfo_14_bits_blockRefill),
    .io_msInfo_14_bits_meta_dirty               (mshrCtl_msInfo_14_bits_meta_dirty),
    .io_msInfo_14_bits_meta_state               (mshrCtl_msInfo_14_bits_meta_state),
    .io_msInfo_14_bits_meta_clients             (mshrCtl_msInfo_14_bits_meta_clients),
    .io_msInfo_14_bits_meta_alias               (mshrCtl_msInfo_14_bits_meta_alias),
    .io_msInfo_14_bits_meta_prefetch            (mshrCtl_msInfo_14_bits_meta_prefetch),
    .io_msInfo_14_bits_meta_prefetchSrc         (mshrCtl_msInfo_14_bits_meta_prefetchSrc),
    .io_msInfo_14_bits_meta_accessed            (mshrCtl_msInfo_14_bits_meta_accessed),
    .io_msInfo_14_bits_meta_tagErr              (mshrCtl_msInfo_14_bits_meta_tagErr),
    .io_msInfo_14_bits_meta_dataErr             (mshrCtl_msInfo_14_bits_meta_dataErr),
    .io_msInfo_14_bits_metaTag                  (mshrCtl_msInfo_14_bits_metaTag),
    .io_msInfo_14_bits_dirHit                   (mshrCtl_msInfo_14_bits_dirHit),
    .io_msInfo_14_bits_w_grantfirst             (mshrCtl_msInfo_14_bits_w_grantfirst),
    .io_msInfo_14_bits_s_release                (mshrCtl_msInfo_14_bits_s_release),
    .io_msInfo_14_bits_s_cmoresp                (mshrCtl_msInfo_14_bits_s_cmoresp),
    .io_msInfo_14_bits_s_cmometaw               (mshrCtl_msInfo_14_bits_s_cmometaw),
    .io_msInfo_14_bits_w_releaseack             (mshrCtl_msInfo_14_bits_w_releaseack),
    .io_msInfo_14_bits_w_replResp               (mshrCtl_msInfo_14_bits_w_replResp),
    .io_msInfo_14_bits_w_rprobeacklast          (mshrCtl_msInfo_14_bits_w_rprobeacklast),
    .io_msInfo_14_bits_replaceData              (mshrCtl_msInfo_14_bits_replaceData),
    .io_msInfo_14_bits_releaseToClean           (mshrCtl_msInfo_14_bits_releaseToClean),
    .io_msInfo_15_valid                         (mshrCtl_msInfo_15_valid),
    .io_msInfo_15_bits_set                      (mshrCtl_msInfo_15_bits_set),
    .io_msInfo_15_bits_reqTag                   (mshrCtl_msInfo_15_bits_reqTag),
    .io_msInfo_15_bits_willFree                 (mshrCtl_msInfo_15_bits_willFree),
    .io_msInfo_15_bits_aliasTask                (mshrCtl_msInfo_15_bits_aliasTask),
    .io_msInfo_15_bits_blockRefill              (mshrCtl_msInfo_15_bits_blockRefill),
    .io_msInfo_15_bits_meta_dirty               (mshrCtl_msInfo_15_bits_meta_dirty),
    .io_msInfo_15_bits_meta_state               (mshrCtl_msInfo_15_bits_meta_state),
    .io_msInfo_15_bits_meta_clients             (mshrCtl_msInfo_15_bits_meta_clients),
    .io_msInfo_15_bits_meta_alias               (mshrCtl_msInfo_15_bits_meta_alias),
    .io_msInfo_15_bits_meta_prefetch            (mshrCtl_msInfo_15_bits_meta_prefetch),
    .io_msInfo_15_bits_meta_prefetchSrc         (mshrCtl_msInfo_15_bits_meta_prefetchSrc),
    .io_msInfo_15_bits_meta_accessed            (mshrCtl_msInfo_15_bits_meta_accessed),
    .io_msInfo_15_bits_meta_tagErr              (mshrCtl_msInfo_15_bits_meta_tagErr),
    .io_msInfo_15_bits_meta_dataErr             (mshrCtl_msInfo_15_bits_meta_dataErr),
    .io_msInfo_15_bits_metaTag                  (mshrCtl_msInfo_15_bits_metaTag),
    .io_msInfo_15_bits_dirHit                   (mshrCtl_msInfo_15_bits_dirHit),
    .io_msInfo_15_bits_w_grantfirst             (mshrCtl_msInfo_15_bits_w_grantfirst),
    .io_msInfo_15_bits_s_release                (mshrCtl_msInfo_15_bits_s_release),
    .io_msInfo_15_bits_s_cmoresp                (mshrCtl_msInfo_15_bits_s_cmoresp),
    .io_msInfo_15_bits_s_cmometaw               (mshrCtl_msInfo_15_bits_s_cmometaw),
    .io_msInfo_15_bits_w_releaseack             (mshrCtl_msInfo_15_bits_w_releaseack),
    .io_msInfo_15_bits_w_replResp               (mshrCtl_msInfo_15_bits_w_replResp),
    .io_msInfo_15_bits_w_rprobeacklast          (mshrCtl_msInfo_15_bits_w_rprobeacklast),
    .io_msInfo_15_bits_replaceData              (mshrCtl_msInfo_15_bits_replaceData),
    .io_msInfo_15_bits_releaseToClean           (mshrCtl_msInfo_15_bits_releaseToClean)
  );

  // RXDAT：CHI 上行数据（CompData），数据写 refillBuf、响应送 MSHRCtl
  RXDAT rxdat (
    .clock                            (clock),
    .reset                            (reset),
    .io_out_valid                     (io_out_rx_dat_valid),
    .io_out_bits_txnID                (io_out_rx_dat_bits_txnID),
    .io_out_bits_homeNID              (io_out_rx_dat_bits_homeNID),
    .io_out_bits_opcode               (io_out_rx_dat_bits_opcode),
    .io_out_bits_respErr              (io_out_rx_dat_bits_respErr),
    .io_out_bits_resp                 (io_out_rx_dat_bits_resp),
    .io_out_bits_dbID                 (io_out_rx_dat_bits_dbID),
    .io_out_bits_dataID               (io_out_rx_dat_bits_dataID),
    .io_out_bits_traceTag             (io_out_rx_dat_bits_traceTag),
    .io_out_bits_data                 (io_out_rx_dat_bits_data),
    .io_out_bits_dataCheck            (io_out_rx_dat_bits_dataCheck),
    .io_out_bits_poison               (io_out_rx_dat_bits_poison),
    .io_in_valid                      (rxdat_in_valid),
    .io_in_mshrId                     (rxdat_in_mshrId),
    .io_in_respInfo_last              (rxdat_in_respInfo_last),
    .io_in_respInfo_corrupt           (rxdat_in_respInfo_corrupt),
    .io_in_respInfo_chiOpcode         (rxdat_in_respInfo_chiOpcode),
    .io_in_respInfo_homeNID           (rxdat_in_respInfo_homeNID),
    .io_in_respInfo_dbID              (rxdat_in_respInfo_dbID),
    .io_in_respInfo_resp              (rxdat_in_respInfo_resp),
    .io_in_respInfo_respErr           (rxdat_in_respInfo_respErr),
    .io_in_respInfo_traceTag          (rxdat_in_respInfo_traceTag),
    .io_refillBufWrite_valid          (rxdat_refillBufWrite_valid),
    .io_refillBufWrite_bits_id        (rxdat_refillBufWrite_bits_id),
    .io_refillBufWrite_bits_data_data (rxdat_refillBufWrite_bits_data_data),
    .io_refillBufWrite_bits_beatMask  (rxdat_refillBufWrite_bits_beatMask)
  );

  // RXRSP：CHI 上行响应（Comp/DBIDResp/RetryAck/PCrdGrant），送 MSHRCtl
  RXRSP rxrsp (
    .io_out_valid             (io_out_rx_rsp_valid),
    .io_out_bits_srcID        (io_out_rx_rsp_bits_srcID),
    .io_out_bits_txnID        (io_out_rx_rsp_bits_txnID),
    .io_out_bits_opcode       (io_out_rx_rsp_bits_opcode),
    .io_out_bits_respErr      (io_out_rx_rsp_bits_respErr),
    .io_out_bits_resp         (io_out_rx_rsp_bits_resp),
    .io_out_bits_dbID         (io_out_rx_rsp_bits_dbID),
    .io_out_bits_pCrdType     (io_out_rx_rsp_bits_pCrdType),
    .io_out_bits_traceTag     (io_out_rx_rsp_bits_traceTag),
    .io_in_valid              (rxrsp_in_valid),
    .io_in_mshrId             (rxrsp_in_mshrId),
    .io_in_respInfo_chiOpcode (rxrsp_in_respInfo_chiOpcode),
    .io_in_respInfo_srcID     (rxrsp_in_respInfo_srcID),
    .io_in_respInfo_dbID      (rxrsp_in_respInfo_dbID),
    .io_in_respInfo_resp      (rxrsp_in_respInfo_resp),
    .io_in_respInfo_pCrdType  (rxrsp_in_respInfo_pCrdType),
    .io_in_respInfo_respErr   (rxrsp_in_respInfo_respErr),
    .io_in_respInfo_traceTag  (rxrsp_in_respInfo_traceTag)
  );

  // refillBuf（MSHRBuffer，2 写口）：refill 数据缓冲 —— 写口 0 = RXDAT，写口 1 = SinkC
  MSHRBuffer refillBuf (
    .clock                 (clock),
    .reset                 (reset),
    .io_r_valid            (reqArb_refillBufRead_s2_valid),
    .io_r_bits_id          (reqArb_refillBufRead_s2_bits_id),
    .io_resp_data_data     (refillBuf_resp_data_data),
    .io_w_0_valid          (rxdat_refillBufWrite_valid),
    .io_w_0_bits_id        (rxdat_refillBufWrite_bits_id),
    .io_w_0_bits_data_data (rxdat_refillBufWrite_bits_data_data),
    .io_w_0_bits_beatMask  (rxdat_refillBufWrite_bits_beatMask),
    .io_w_1_valid          (sinkC_refillBufWrite_valid),
    .io_w_1_bits_id        (sinkC_refillBufWrite_bits_id),
    .io_w_1_bits_data_data (sinkC_refillBufWrite_bits_data_data)
  );

  // releaseBuf（MSHRBuffer_1，3 写口）：release 数据缓冲 —— 写口 0 = 嵌套写回（MainPipe 数据 + MSHRCtl 给 ID），1 = SinkC Release，2 = MainPipe 读出的被替换行
  MSHRBuffer_1 releaseBuf (
    .clock                 (clock),
    .reset                 (reset),
    .io_r_valid            (reqArb_releaseBufRead_s2_valid),
    .io_r_bits_id          (reqArb_releaseBufRead_s2_bits_id),
    .io_resp_data_data     (releaseBuf_resp_data_data),
    .io_w_0_valid          (mshrCtl_nestedwbDataId_valid),
    .io_w_0_bits_id        (mshrCtl_nestedwbDataId_bits),
    .io_w_0_bits_data_data (mainPipe_nestedwbData_data),
    .io_w_1_valid          (sinkC_releaseBufWrite_valid),
    .io_w_1_bits_id        (mshrCtl_releaseBufWriteId),
    .io_w_1_bits_data_data (sinkC_releaseBufWrite_bits_data_data),
    .io_w_2_valid          (mainPipe_releaseBufWrite_valid),
    .io_w_2_bits_id        (mainPipe_releaseBufWrite_bits_id),
    .io_w_2_bits_data_data (mainPipe_releaseBufWrite_bits_data_data)
  );

  // RequestArb：s0-s2 请求仲裁（MSHR 任务 > snoop > C > A），发目录读、读 refill/release 缓冲
  //   注：sinkB 的多数字段、mshrTask 的少数字段在源头（RXSNP / MSHRCtl 仲裁器）恒为常量，firtool 删了那些端口，常量留在这里（照 golden 原样）
  RequestArb reqArb (
    .clock                                               (clock),
    .reset                                               (reset),
    .io_sinkA_ready                                      (reqArb_sinkA_ready),
    .io_sinkA_valid                                      (reqBuf_out_valid),
    .io_sinkA_bits_channel                               (reqBuf_out_bits_channel),
    .io_sinkA_bits_txChannel                             (reqBuf_out_bits_txChannel),
    .io_sinkA_bits_set                                   (reqBuf_out_bits_set),
    .io_sinkA_bits_tag                                   (reqBuf_out_bits_tag),
    .io_sinkA_bits_off                                   (reqBuf_out_bits_off),
    .io_sinkA_bits_alias                                 (reqBuf_out_bits_alias),
    .io_sinkA_bits_vaddr                                 (reqBuf_out_bits_vaddr),
    .io_sinkA_bits_isKeyword                             (reqBuf_out_bits_isKeyword),
    .io_sinkA_bits_opcode                                (reqBuf_out_bits_opcode),
    .io_sinkA_bits_param                                 (reqBuf_out_bits_param),
    .io_sinkA_bits_size                                  (reqBuf_out_bits_size),
    .io_sinkA_bits_sourceId                              (reqBuf_out_bits_sourceId),
    .io_sinkA_bits_bufIdx                                (reqBuf_out_bits_bufIdx),
    .io_sinkA_bits_needProbeAckData                      (reqBuf_out_bits_needProbeAckData),
    .io_sinkA_bits_denied                                (reqBuf_out_bits_denied),
    .io_sinkA_bits_corrupt                               (reqBuf_out_bits_corrupt),
    .io_sinkA_bits_mshrTask                              (reqBuf_out_bits_mshrTask),
    .io_sinkA_bits_mshrId                                (reqBuf_out_bits_mshrId),
    .io_sinkA_bits_aliasTask                             (reqBuf_out_bits_aliasTask),
    .io_sinkA_bits_useProbeData                          (reqBuf_out_bits_useProbeData),
    .io_sinkA_bits_mshrRetry                             (reqBuf_out_bits_mshrRetry),
    .io_sinkA_bits_readProbeDataDown                     (reqBuf_out_bits_readProbeDataDown),
    .io_sinkA_bits_fromL2pft                             (reqBuf_out_bits_fromL2pft),
    .io_sinkA_bits_needHint                              (reqBuf_out_bits_needHint),
    .io_sinkA_bits_dirty                                 (reqBuf_out_bits_dirty),
    .io_sinkA_bits_way                                   (reqBuf_out_bits_way),
    .io_sinkA_bits_meta_dirty                            (reqBuf_out_bits_meta_dirty),
    .io_sinkA_bits_meta_state                            (reqBuf_out_bits_meta_state),
    .io_sinkA_bits_meta_clients                          (reqBuf_out_bits_meta_clients),
    .io_sinkA_bits_meta_alias                            (reqBuf_out_bits_meta_alias),
    .io_sinkA_bits_meta_prefetch                         (reqBuf_out_bits_meta_prefetch),
    .io_sinkA_bits_meta_prefetchSrc                      (reqBuf_out_bits_meta_prefetchSrc),
    .io_sinkA_bits_meta_accessed                         (reqBuf_out_bits_meta_accessed),
    .io_sinkA_bits_meta_tagErr                           (reqBuf_out_bits_meta_tagErr),
    .io_sinkA_bits_meta_dataErr                          (reqBuf_out_bits_meta_dataErr),
    .io_sinkA_bits_metaWen                               (reqBuf_out_bits_metaWen),
    .io_sinkA_bits_tagWen                                (reqBuf_out_bits_tagWen),
    .io_sinkA_bits_dsWen                                 (reqBuf_out_bits_dsWen),
    .io_sinkA_bits_wayMask                               (8'hFF),
    .io_sinkA_bits_replTask                              (reqBuf_out_bits_replTask),
    .io_sinkA_bits_cmoTask                               (reqBuf_out_bits_cmoTask),
    .io_sinkA_bits_cmoAll                                (reqBuf_out_bits_cmoAll),
    .io_sinkA_bits_reqSource                             (reqBuf_out_bits_reqSource),
    .io_sinkA_bits_mergeA                                (reqBuf_out_bits_mergeA),
    .io_sinkA_bits_aMergeTask_off                        (reqBuf_out_bits_aMergeTask_off),
    .io_sinkA_bits_aMergeTask_alias                      (reqBuf_out_bits_aMergeTask_alias),
    .io_sinkA_bits_aMergeTask_vaddr                      (reqBuf_out_bits_aMergeTask_vaddr),
    .io_sinkA_bits_aMergeTask_isKeyword                  (reqBuf_out_bits_aMergeTask_isKeyword),
    .io_sinkA_bits_aMergeTask_opcode                     (reqBuf_out_bits_aMergeTask_opcode),
    .io_sinkA_bits_aMergeTask_param                      (reqBuf_out_bits_aMergeTask_param),
    .io_sinkA_bits_aMergeTask_sourceId                   (reqBuf_out_bits_aMergeTask_sourceId),
    .io_sinkA_bits_aMergeTask_meta_dirty                 (reqBuf_out_bits_aMergeTask_meta_dirty),
    .io_sinkA_bits_aMergeTask_meta_state                 (reqBuf_out_bits_aMergeTask_meta_state),
    .io_sinkA_bits_aMergeTask_meta_clients               (reqBuf_out_bits_aMergeTask_meta_clients),
    .io_sinkA_bits_aMergeTask_meta_alias                 (reqBuf_out_bits_aMergeTask_meta_alias),
    .io_sinkA_bits_aMergeTask_meta_prefetch              (reqBuf_out_bits_aMergeTask_meta_prefetch),
    .io_sinkA_bits_aMergeTask_meta_prefetchSrc           (reqBuf_out_bits_aMergeTask_meta_prefetchSrc),
    .io_sinkA_bits_aMergeTask_meta_accessed              (reqBuf_out_bits_aMergeTask_meta_accessed),
    .io_sinkA_bits_aMergeTask_meta_tagErr                (reqBuf_out_bits_aMergeTask_meta_tagErr),
    .io_sinkA_bits_aMergeTask_meta_dataErr               (reqBuf_out_bits_aMergeTask_meta_dataErr),
    .io_sinkA_bits_snpHitRelease                         (reqBuf_out_bits_snpHitRelease),
    .io_sinkA_bits_snpHitReleaseToInval                  (reqBuf_out_bits_snpHitReleaseToInval),
    .io_sinkA_bits_snpHitReleaseToClean                  (reqBuf_out_bits_snpHitReleaseToClean),
    .io_sinkA_bits_snpHitReleaseWithData                 (reqBuf_out_bits_snpHitReleaseWithData),
    .io_sinkA_bits_snpHitReleaseIdx                      (reqBuf_out_bits_snpHitReleaseIdx),
    .io_sinkA_bits_snpHitReleaseMeta_dirty               (reqBuf_out_bits_snpHitReleaseMeta_dirty),
    .io_sinkA_bits_snpHitReleaseMeta_state               (reqBuf_out_bits_snpHitReleaseMeta_state),
    .io_sinkA_bits_snpHitReleaseMeta_clients             (reqBuf_out_bits_snpHitReleaseMeta_clients),
    .io_sinkA_bits_snpHitReleaseMeta_alias               (reqBuf_out_bits_snpHitReleaseMeta_alias),
    .io_sinkA_bits_snpHitReleaseMeta_prefetch            (reqBuf_out_bits_snpHitReleaseMeta_prefetch),
    .io_sinkA_bits_snpHitReleaseMeta_prefetchSrc         (reqBuf_out_bits_snpHitReleaseMeta_prefetchSrc),
    .io_sinkA_bits_snpHitReleaseMeta_accessed            (reqBuf_out_bits_snpHitReleaseMeta_accessed),
    .io_sinkA_bits_snpHitReleaseMeta_tagErr              (reqBuf_out_bits_snpHitReleaseMeta_tagErr),
    .io_sinkA_bits_snpHitReleaseMeta_dataErr             (reqBuf_out_bits_snpHitReleaseMeta_dataErr),
    .io_sinkA_bits_tgtID                                 (reqBuf_out_bits_tgtID),
    .io_sinkA_bits_srcID                                 (reqBuf_out_bits_srcID),
    .io_sinkA_bits_txnID                                 (reqBuf_out_bits_txnID),
    .io_sinkA_bits_homeNID                               (reqBuf_out_bits_homeNID),
    .io_sinkA_bits_dbID                                  (reqBuf_out_bits_dbID),
    .io_sinkA_bits_fwdNID                                (reqBuf_out_bits_fwdNID),
    .io_sinkA_bits_fwdTxnID                              (reqBuf_out_bits_fwdTxnID),
    .io_sinkA_bits_chiOpcode                             (reqBuf_out_bits_chiOpcode),
    .io_sinkA_bits_resp                                  (reqBuf_out_bits_resp),
    .io_sinkA_bits_fwdState                              (reqBuf_out_bits_fwdState),
    .io_sinkA_bits_pCrdType                              (reqBuf_out_bits_pCrdType),
    .io_sinkA_bits_retToSrc                              (reqBuf_out_bits_retToSrc),
    .io_sinkA_bits_likelyshared                          (reqBuf_out_bits_likelyshared),
    .io_sinkA_bits_expCompAck                            (reqBuf_out_bits_expCompAck),
    .io_sinkA_bits_allowRetry                            (reqBuf_out_bits_allowRetry),
    .io_sinkA_bits_memAttr_allocate                      (reqBuf_out_bits_memAttr_allocate),
    .io_sinkA_bits_memAttr_cacheable                     (reqBuf_out_bits_memAttr_cacheable),
    .io_sinkA_bits_memAttr_device                        (reqBuf_out_bits_memAttr_device),
    .io_sinkA_bits_memAttr_ewa                           (reqBuf_out_bits_memAttr_ewa),
    .io_sinkA_bits_traceTag                              (reqBuf_out_bits_traceTag),
    .io_ATag                                             (reqBuf_ATag),
    .io_ASet                                             (reqBuf_ASet),
    .io_s1Entrance_valid                                 (reqArb_s1Entrance_valid),
    .io_s1Entrance_bits_set                              (reqArb_s1Entrance_bits_set),
    .io_sinkB_ready                                      (reqArb_sinkB_ready),
    .io_sinkB_valid                                      (rxsnp_task_valid),
    .io_sinkB_bits_channel                               (3'h2),
    .io_sinkB_bits_txChannel                             (3'h0),
    .io_sinkB_bits_set                                   (rxsnp_task_bits_set),
    .io_sinkB_bits_tag                                   (rxsnp_task_bits_tag),
    .io_sinkB_bits_off                                   (rxsnp_task_bits_off),
    .io_sinkB_bits_alias                                 (2'h0),
    .io_sinkB_bits_vaddr                                 (44'h0),
    .io_sinkB_bits_isKeyword                             (1'h0),
    .io_sinkB_bits_opcode                                (4'h0),
    .io_sinkB_bits_param                                 (3'h0),
    .io_sinkB_bits_size                                  (3'h6),
    .io_sinkB_bits_sourceId                              (7'h0),
    .io_sinkB_bits_bufIdx                                (2'h0),
    .io_sinkB_bits_needProbeAckData                      (1'h0),
    .io_sinkB_bits_denied                                (1'h0),
    .io_sinkB_bits_corrupt                               (1'h0),
    .io_sinkB_bits_mshrTask                              (1'h0),
    .io_sinkB_bits_mshrId                                (8'h0),
    .io_sinkB_bits_aliasTask                             (1'h0),
    .io_sinkB_bits_useProbeData                          (1'h0),
    .io_sinkB_bits_mshrRetry                             (1'h0),
    .io_sinkB_bits_readProbeDataDown                     (1'h0),
    .io_sinkB_bits_fromL2pft                             (1'h0),
    .io_sinkB_bits_needHint                              (1'h0),
    .io_sinkB_bits_dirty                                 (1'h0),
    .io_sinkB_bits_way                                   (3'h0),
    .io_sinkB_bits_meta_dirty                            (1'h0),
    .io_sinkB_bits_meta_state                            (2'h0),
    .io_sinkB_bits_meta_clients                          (1'h0),
    .io_sinkB_bits_meta_alias                            (2'h0),
    .io_sinkB_bits_meta_prefetch                         (1'h0),
    .io_sinkB_bits_meta_prefetchSrc                      (3'h0),
    .io_sinkB_bits_meta_accessed                         (1'h0),
    .io_sinkB_bits_meta_tagErr                           (1'h0),
    .io_sinkB_bits_meta_dataErr                          (1'h0),
    .io_sinkB_bits_metaWen                               (1'h0),
    .io_sinkB_bits_tagWen                                (1'h0),
    .io_sinkB_bits_dsWen                                 (1'h0),
    .io_sinkB_bits_wayMask                               (8'hFF),
    .io_sinkB_bits_replTask                              (1'h0),
    .io_sinkB_bits_cmoTask                               (1'h0),
    .io_sinkB_bits_cmoAll                                (1'h0),
    .io_sinkB_bits_reqSource                             (5'h0),
    .io_sinkB_bits_mergeA                                (1'h0),
    .io_sinkB_bits_aMergeTask_off                        (6'h0),
    .io_sinkB_bits_aMergeTask_alias                      (2'h0),
    .io_sinkB_bits_aMergeTask_vaddr                      (44'h0),
    .io_sinkB_bits_aMergeTask_isKeyword                  (1'h0),
    .io_sinkB_bits_aMergeTask_opcode                     (3'h0),
    .io_sinkB_bits_aMergeTask_param                      (3'h0),
    .io_sinkB_bits_aMergeTask_sourceId                   (7'h0),
    .io_sinkB_bits_aMergeTask_meta_dirty                 (1'h0),
    .io_sinkB_bits_aMergeTask_meta_state                 (2'h0),
    .io_sinkB_bits_aMergeTask_meta_clients               (1'h0),
    .io_sinkB_bits_aMergeTask_meta_alias                 (2'h0),
    .io_sinkB_bits_aMergeTask_meta_prefetch              (1'h0),
    .io_sinkB_bits_aMergeTask_meta_prefetchSrc           (3'h0),
    .io_sinkB_bits_aMergeTask_meta_accessed              (1'h0),
    .io_sinkB_bits_aMergeTask_meta_tagErr                (1'h0),
    .io_sinkB_bits_aMergeTask_meta_dataErr               (1'h0),
    .io_sinkB_bits_snpHitRelease                         (rxsnp_task_bits_snpHitRelease),
    .io_sinkB_bits_snpHitReleaseToInval                  (rxsnp_task_bits_snpHitReleaseToInval),
    .io_sinkB_bits_snpHitReleaseToClean                  (rxsnp_task_bits_snpHitReleaseToClean),
    .io_sinkB_bits_snpHitReleaseWithData                 (rxsnp_task_bits_snpHitReleaseWithData),
    .io_sinkB_bits_snpHitReleaseIdx                      (rxsnp_task_bits_snpHitReleaseIdx),
    .io_sinkB_bits_snpHitReleaseMeta_dirty               (rxsnp_task_bits_snpHitReleaseMeta_dirty),
    .io_sinkB_bits_snpHitReleaseMeta_state               (rxsnp_task_bits_snpHitReleaseMeta_state),
    .io_sinkB_bits_snpHitReleaseMeta_clients             (rxsnp_task_bits_snpHitReleaseMeta_clients),
    .io_sinkB_bits_snpHitReleaseMeta_alias               (rxsnp_task_bits_snpHitReleaseMeta_alias),
    .io_sinkB_bits_snpHitReleaseMeta_prefetch            (rxsnp_task_bits_snpHitReleaseMeta_prefetch),
    .io_sinkB_bits_snpHitReleaseMeta_prefetchSrc         (rxsnp_task_bits_snpHitReleaseMeta_prefetchSrc),
    .io_sinkB_bits_snpHitReleaseMeta_accessed            (rxsnp_task_bits_snpHitReleaseMeta_accessed),
    .io_sinkB_bits_snpHitReleaseMeta_tagErr              (rxsnp_task_bits_snpHitReleaseMeta_tagErr),
    .io_sinkB_bits_snpHitReleaseMeta_dataErr             (rxsnp_task_bits_snpHitReleaseMeta_dataErr),
    .io_sinkB_bits_tgtID                                 (11'h0),
    .io_sinkB_bits_srcID                                 (rxsnp_task_bits_srcID),
    .io_sinkB_bits_txnID                                 (rxsnp_task_bits_txnID),
    .io_sinkB_bits_homeNID                               (11'h0),
    .io_sinkB_bits_dbID                                  (12'h0),
    .io_sinkB_bits_fwdNID                                (rxsnp_task_bits_fwdNID),
    .io_sinkB_bits_fwdTxnID                              (rxsnp_task_bits_fwdTxnID),
    .io_sinkB_bits_chiOpcode                             (rxsnp_task_bits_chiOpcode),
    .io_sinkB_bits_resp                                  (3'h0),
    .io_sinkB_bits_fwdState                              (3'h0),
    .io_sinkB_bits_pCrdType                              (4'h0),
    .io_sinkB_bits_retToSrc                              (rxsnp_task_bits_retToSrc),
    .io_sinkB_bits_likelyshared                          (1'h0),
    .io_sinkB_bits_expCompAck                            (1'h0),
    .io_sinkB_bits_allowRetry                            (1'h0),
    .io_sinkB_bits_memAttr_allocate                      (1'h0),
    .io_sinkB_bits_memAttr_cacheable                     (1'h0),
    .io_sinkB_bits_memAttr_device                        (1'h0),
    .io_sinkB_bits_memAttr_ewa                           (1'h0),
    .io_sinkB_bits_traceTag                              (rxsnp_task_bits_traceTag),
    .io_sinkC_ready                                      (reqArb_sinkC_ready),
    .io_sinkC_valid                                      (sinkC_task_valid),
    .io_sinkC_bits_channel                               (sinkC_task_bits_channel),
    .io_sinkC_bits_txChannel                             (sinkC_task_bits_txChannel),
    .io_sinkC_bits_set                                   (sinkC_task_bits_set),
    .io_sinkC_bits_tag                                   (sinkC_task_bits_tag),
    .io_sinkC_bits_off                                   (sinkC_task_bits_off),
    .io_sinkC_bits_alias                                 (sinkC_task_bits_alias),
    .io_sinkC_bits_vaddr                                 (sinkC_task_bits_vaddr),
    .io_sinkC_bits_isKeyword                             (sinkC_task_bits_isKeyword),
    .io_sinkC_bits_opcode                                (sinkC_task_bits_opcode),
    .io_sinkC_bits_param                                 (sinkC_task_bits_param),
    .io_sinkC_bits_size                                  (sinkC_task_bits_size),
    .io_sinkC_bits_sourceId                              (sinkC_task_bits_sourceId),
    .io_sinkC_bits_bufIdx                                (sinkC_task_bits_bufIdx),
    .io_sinkC_bits_needProbeAckData                      (sinkC_task_bits_needProbeAckData),
    .io_sinkC_bits_denied                                (sinkC_task_bits_denied),
    .io_sinkC_bits_corrupt                               (sinkC_task_bits_corrupt),
    .io_sinkC_bits_mshrTask                              (sinkC_task_bits_mshrTask),
    .io_sinkC_bits_mshrId                                (sinkC_task_bits_mshrId),
    .io_sinkC_bits_aliasTask                             (sinkC_task_bits_aliasTask),
    .io_sinkC_bits_useProbeData                          (sinkC_task_bits_useProbeData),
    .io_sinkC_bits_mshrRetry                             (sinkC_task_bits_mshrRetry),
    .io_sinkC_bits_readProbeDataDown                     (sinkC_task_bits_readProbeDataDown),
    .io_sinkC_bits_fromL2pft                             (sinkC_task_bits_fromL2pft),
    .io_sinkC_bits_needHint                              (sinkC_task_bits_needHint),
    .io_sinkC_bits_dirty                                 (sinkC_task_bits_dirty),
    .io_sinkC_bits_way                                   (sinkC_task_bits_way),
    .io_sinkC_bits_meta_dirty                            (sinkC_task_bits_meta_dirty),
    .io_sinkC_bits_meta_state                            (sinkC_task_bits_meta_state),
    .io_sinkC_bits_meta_clients                          (sinkC_task_bits_meta_clients),
    .io_sinkC_bits_meta_alias                            (sinkC_task_bits_meta_alias),
    .io_sinkC_bits_meta_prefetch                         (sinkC_task_bits_meta_prefetch),
    .io_sinkC_bits_meta_prefetchSrc                      (sinkC_task_bits_meta_prefetchSrc),
    .io_sinkC_bits_meta_accessed                         (sinkC_task_bits_meta_accessed),
    .io_sinkC_bits_meta_tagErr                           (sinkC_task_bits_meta_tagErr),
    .io_sinkC_bits_meta_dataErr                          (sinkC_task_bits_meta_dataErr),
    .io_sinkC_bits_metaWen                               (sinkC_task_bits_metaWen),
    .io_sinkC_bits_tagWen                                (sinkC_task_bits_tagWen),
    .io_sinkC_bits_dsWen                                 (sinkC_task_bits_dsWen),
    .io_sinkC_bits_wayMask                               (sinkC_task_bits_wayMask),
    .io_sinkC_bits_replTask                              (sinkC_task_bits_replTask),
    .io_sinkC_bits_cmoTask                               (sinkC_task_bits_cmoTask),
    .io_sinkC_bits_cmoAll                                (sinkC_task_bits_cmoAll),
    .io_sinkC_bits_reqSource                             (sinkC_task_bits_reqSource),
    .io_sinkC_bits_mergeA                                (sinkC_task_bits_mergeA),
    .io_sinkC_bits_aMergeTask_off                        (sinkC_task_bits_aMergeTask_off),
    .io_sinkC_bits_aMergeTask_alias                      (sinkC_task_bits_aMergeTask_alias),
    .io_sinkC_bits_aMergeTask_vaddr                      (sinkC_task_bits_aMergeTask_vaddr),
    .io_sinkC_bits_aMergeTask_isKeyword                  (sinkC_task_bits_aMergeTask_isKeyword),
    .io_sinkC_bits_aMergeTask_opcode                     (sinkC_task_bits_aMergeTask_opcode),
    .io_sinkC_bits_aMergeTask_param                      (sinkC_task_bits_aMergeTask_param),
    .io_sinkC_bits_aMergeTask_sourceId                   (sinkC_task_bits_aMergeTask_sourceId),
    .io_sinkC_bits_aMergeTask_meta_dirty                 (sinkC_task_bits_aMergeTask_meta_dirty),
    .io_sinkC_bits_aMergeTask_meta_state                 (sinkC_task_bits_aMergeTask_meta_state),
    .io_sinkC_bits_aMergeTask_meta_clients               (sinkC_task_bits_aMergeTask_meta_clients),
    .io_sinkC_bits_aMergeTask_meta_alias                 (sinkC_task_bits_aMergeTask_meta_alias),
    .io_sinkC_bits_aMergeTask_meta_prefetch              (sinkC_task_bits_aMergeTask_meta_prefetch),
    .io_sinkC_bits_aMergeTask_meta_prefetchSrc           (sinkC_task_bits_aMergeTask_meta_prefetchSrc),
    .io_sinkC_bits_aMergeTask_meta_accessed              (sinkC_task_bits_aMergeTask_meta_accessed),
    .io_sinkC_bits_aMergeTask_meta_tagErr                (sinkC_task_bits_aMergeTask_meta_tagErr),
    .io_sinkC_bits_aMergeTask_meta_dataErr               (sinkC_task_bits_aMergeTask_meta_dataErr),
    .io_sinkC_bits_snpHitRelease                         (sinkC_task_bits_snpHitRelease),
    .io_sinkC_bits_snpHitReleaseToInval                  (sinkC_task_bits_snpHitReleaseToInval),
    .io_sinkC_bits_snpHitReleaseToClean                  (sinkC_task_bits_snpHitReleaseToClean),
    .io_sinkC_bits_snpHitReleaseWithData                 (sinkC_task_bits_snpHitReleaseWithData),
    .io_sinkC_bits_snpHitReleaseIdx                      (sinkC_task_bits_snpHitReleaseIdx),
    .io_sinkC_bits_snpHitReleaseMeta_dirty               (sinkC_task_bits_snpHitReleaseMeta_dirty),
    .io_sinkC_bits_snpHitReleaseMeta_state               (sinkC_task_bits_snpHitReleaseMeta_state),
    .io_sinkC_bits_snpHitReleaseMeta_clients             (sinkC_task_bits_snpHitReleaseMeta_clients),
    .io_sinkC_bits_snpHitReleaseMeta_alias               (sinkC_task_bits_snpHitReleaseMeta_alias),
    .io_sinkC_bits_snpHitReleaseMeta_prefetch            (sinkC_task_bits_snpHitReleaseMeta_prefetch),
    .io_sinkC_bits_snpHitReleaseMeta_prefetchSrc         (sinkC_task_bits_snpHitReleaseMeta_prefetchSrc),
    .io_sinkC_bits_snpHitReleaseMeta_accessed            (sinkC_task_bits_snpHitReleaseMeta_accessed),
    .io_sinkC_bits_snpHitReleaseMeta_tagErr              (sinkC_task_bits_snpHitReleaseMeta_tagErr),
    .io_sinkC_bits_snpHitReleaseMeta_dataErr             (sinkC_task_bits_snpHitReleaseMeta_dataErr),
    .io_sinkC_bits_tgtID                                 (sinkC_task_bits_tgtID),
    .io_sinkC_bits_srcID                                 (sinkC_task_bits_srcID),
    .io_sinkC_bits_txnID                                 (sinkC_task_bits_txnID),
    .io_sinkC_bits_homeNID                               (sinkC_task_bits_homeNID),
    .io_sinkC_bits_dbID                                  (sinkC_task_bits_dbID),
    .io_sinkC_bits_fwdNID                                (sinkC_task_bits_fwdNID),
    .io_sinkC_bits_fwdTxnID                              (sinkC_task_bits_fwdTxnID),
    .io_sinkC_bits_chiOpcode                             (sinkC_task_bits_chiOpcode),
    .io_sinkC_bits_resp                                  (sinkC_task_bits_resp),
    .io_sinkC_bits_fwdState                              (sinkC_task_bits_fwdState),
    .io_sinkC_bits_pCrdType                              (sinkC_task_bits_pCrdType),
    .io_sinkC_bits_retToSrc                              (sinkC_task_bits_retToSrc),
    .io_sinkC_bits_likelyshared                          (sinkC_task_bits_likelyshared),
    .io_sinkC_bits_expCompAck                            (sinkC_task_bits_expCompAck),
    .io_sinkC_bits_allowRetry                            (sinkC_task_bits_allowRetry),
    .io_sinkC_bits_memAttr_allocate                      (sinkC_task_bits_memAttr_allocate),
    .io_sinkC_bits_memAttr_cacheable                     (sinkC_task_bits_memAttr_cacheable),
    .io_sinkC_bits_memAttr_device                        (sinkC_task_bits_memAttr_device),
    .io_sinkC_bits_memAttr_ewa                           (sinkC_task_bits_memAttr_ewa),
    .io_sinkC_bits_traceTag                              (sinkC_task_bits_traceTag),
    .io_mshrTask_ready                                   (reqArb_mshrTask_ready),
    .io_mshrTask_valid                                   (mshrCtl_mshrTask_valid),
    .io_mshrTask_bits_channel                            (mshrCtl_mshrTask_bits_channel),
    .io_mshrTask_bits_txChannel                          (mshrCtl_mshrTask_bits_txChannel),
    .io_mshrTask_bits_set                                (mshrCtl_mshrTask_bits_set),
    .io_mshrTask_bits_tag                                (mshrCtl_mshrTask_bits_tag),
    .io_mshrTask_bits_off                                (mshrCtl_mshrTask_bits_off),
    .io_mshrTask_bits_alias                              (mshrCtl_mshrTask_bits_alias),
    .io_mshrTask_bits_vaddr                              (44'h0),
    .io_mshrTask_bits_isKeyword                          (mshrCtl_mshrTask_bits_isKeyword),
    .io_mshrTask_bits_opcode                             (mshrCtl_mshrTask_bits_opcode),
    .io_mshrTask_bits_param                              (mshrCtl_mshrTask_bits_param),
    .io_mshrTask_bits_size                               (mshrCtl_mshrTask_bits_size),
    .io_mshrTask_bits_sourceId                           (mshrCtl_mshrTask_bits_sourceId),
    .io_mshrTask_bits_bufIdx                             (2'h0),
    .io_mshrTask_bits_needProbeAckData                   (1'h0),
    .io_mshrTask_bits_denied                             (mshrCtl_mshrTask_bits_denied),
    .io_mshrTask_bits_corrupt                            (mshrCtl_mshrTask_bits_corrupt),
    .io_mshrTask_bits_mshrTask                           (mshrCtl_mshrTask_bits_mshrTask),
    .io_mshrTask_bits_mshrId                             (mshrCtl_mshrTask_bits_mshrId),
    .io_mshrTask_bits_aliasTask                          (mshrCtl_mshrTask_bits_aliasTask),
    .io_mshrTask_bits_useProbeData                       (mshrCtl_mshrTask_bits_useProbeData),
    .io_mshrTask_bits_mshrRetry                          (mshrCtl_mshrTask_bits_mshrRetry),
    .io_mshrTask_bits_readProbeDataDown                  (mshrCtl_mshrTask_bits_readProbeDataDown),
    .io_mshrTask_bits_fromL2pft                          (mshrCtl_mshrTask_bits_fromL2pft),
    .io_mshrTask_bits_needHint                           (1'h0),
    .io_mshrTask_bits_dirty                              (mshrCtl_mshrTask_bits_dirty),
    .io_mshrTask_bits_way                                (mshrCtl_mshrTask_bits_way),
    .io_mshrTask_bits_meta_dirty                         (mshrCtl_mshrTask_bits_meta_dirty),
    .io_mshrTask_bits_meta_state                         (mshrCtl_mshrTask_bits_meta_state),
    .io_mshrTask_bits_meta_clients                       (mshrCtl_mshrTask_bits_meta_clients),
    .io_mshrTask_bits_meta_alias                         (mshrCtl_mshrTask_bits_meta_alias),
    .io_mshrTask_bits_meta_prefetch                      (mshrCtl_mshrTask_bits_meta_prefetch),
    .io_mshrTask_bits_meta_prefetchSrc                   (mshrCtl_mshrTask_bits_meta_prefetchSrc),
    .io_mshrTask_bits_meta_accessed                      (mshrCtl_mshrTask_bits_meta_accessed),
    .io_mshrTask_bits_meta_tagErr                        (mshrCtl_mshrTask_bits_meta_tagErr),
    .io_mshrTask_bits_meta_dataErr                       (mshrCtl_mshrTask_bits_meta_dataErr),
    .io_mshrTask_bits_metaWen                            (mshrCtl_mshrTask_bits_metaWen),
    .io_mshrTask_bits_tagWen                             (mshrCtl_mshrTask_bits_tagWen),
    .io_mshrTask_bits_dsWen                              (mshrCtl_mshrTask_bits_dsWen),
    .io_mshrTask_bits_wayMask                            (8'h0),
    .io_mshrTask_bits_replTask                           (mshrCtl_mshrTask_bits_replTask),
    .io_mshrTask_bits_cmoTask                            (mshrCtl_mshrTask_bits_cmoTask),
    .io_mshrTask_bits_cmoAll                             (1'h0),
    .io_mshrTask_bits_reqSource                          (mshrCtl_mshrTask_bits_reqSource),
    .io_mshrTask_bits_mergeA                             (mshrCtl_mshrTask_bits_mergeA),
    .io_mshrTask_bits_aMergeTask_off                     (mshrCtl_mshrTask_bits_aMergeTask_off),
    .io_mshrTask_bits_aMergeTask_alias                   (mshrCtl_mshrTask_bits_aMergeTask_alias),
    .io_mshrTask_bits_aMergeTask_vaddr                   (mshrCtl_mshrTask_bits_aMergeTask_vaddr),
    .io_mshrTask_bits_aMergeTask_isKeyword               (mshrCtl_mshrTask_bits_aMergeTask_isKeyword),
    .io_mshrTask_bits_aMergeTask_opcode                  (mshrCtl_mshrTask_bits_aMergeTask_opcode),
    .io_mshrTask_bits_aMergeTask_param                   (mshrCtl_mshrTask_bits_aMergeTask_param),
    .io_mshrTask_bits_aMergeTask_sourceId                (mshrCtl_mshrTask_bits_aMergeTask_sourceId),
    .io_mshrTask_bits_aMergeTask_meta_dirty              (mshrCtl_mshrTask_bits_aMergeTask_meta_dirty),
    .io_mshrTask_bits_aMergeTask_meta_state              (mshrCtl_mshrTask_bits_aMergeTask_meta_state),
    .io_mshrTask_bits_aMergeTask_meta_clients            (mshrCtl_mshrTask_bits_aMergeTask_meta_clients),
    .io_mshrTask_bits_aMergeTask_meta_alias              (mshrCtl_mshrTask_bits_aMergeTask_meta_alias),
    .io_mshrTask_bits_aMergeTask_meta_prefetch           (1'h0),
    .io_mshrTask_bits_aMergeTask_meta_prefetchSrc        (3'h0),
    .io_mshrTask_bits_aMergeTask_meta_accessed           (mshrCtl_mshrTask_bits_aMergeTask_meta_accessed),
    .io_mshrTask_bits_aMergeTask_meta_tagErr             (1'h0),
    .io_mshrTask_bits_aMergeTask_meta_dataErr            (1'h0),
    .io_mshrTask_bits_snpHitRelease                      (mshrCtl_mshrTask_bits_snpHitRelease),
    .io_mshrTask_bits_snpHitReleaseToInval               (mshrCtl_mshrTask_bits_snpHitReleaseToInval),
    .io_mshrTask_bits_snpHitReleaseToClean               (mshrCtl_mshrTask_bits_snpHitReleaseToClean),
    .io_mshrTask_bits_snpHitReleaseWithData              (mshrCtl_mshrTask_bits_snpHitReleaseWithData),
    .io_mshrTask_bits_snpHitReleaseIdx                   (mshrCtl_mshrTask_bits_snpHitReleaseIdx),
    .io_mshrTask_bits_snpHitReleaseMeta_dirty            (mshrCtl_mshrTask_bits_snpHitReleaseMeta_dirty),
    .io_mshrTask_bits_snpHitReleaseMeta_state            (mshrCtl_mshrTask_bits_snpHitReleaseMeta_state),
    .io_mshrTask_bits_snpHitReleaseMeta_clients          (mshrCtl_mshrTask_bits_snpHitReleaseMeta_clients),
    .io_mshrTask_bits_snpHitReleaseMeta_alias            (mshrCtl_mshrTask_bits_snpHitReleaseMeta_alias),
    .io_mshrTask_bits_snpHitReleaseMeta_prefetch         (mshrCtl_mshrTask_bits_snpHitReleaseMeta_prefetch),
    .io_mshrTask_bits_snpHitReleaseMeta_prefetchSrc      (mshrCtl_mshrTask_bits_snpHitReleaseMeta_prefetchSrc),
    .io_mshrTask_bits_snpHitReleaseMeta_accessed         (mshrCtl_mshrTask_bits_snpHitReleaseMeta_accessed),
    .io_mshrTask_bits_snpHitReleaseMeta_tagErr           (mshrCtl_mshrTask_bits_snpHitReleaseMeta_tagErr),
    .io_mshrTask_bits_snpHitReleaseMeta_dataErr          (mshrCtl_mshrTask_bits_snpHitReleaseMeta_dataErr),
    .io_mshrTask_bits_tgtID                              (mshrCtl_mshrTask_bits_tgtID),
    .io_mshrTask_bits_srcID                              (11'h0),
    .io_mshrTask_bits_txnID                              (mshrCtl_mshrTask_bits_txnID),
    .io_mshrTask_bits_homeNID                            (mshrCtl_mshrTask_bits_homeNID),
    .io_mshrTask_bits_dbID                               (mshrCtl_mshrTask_bits_dbID),
    .io_mshrTask_bits_fwdNID                             (11'h0),
    .io_mshrTask_bits_fwdTxnID                           (12'h0),
    .io_mshrTask_bits_chiOpcode                          (mshrCtl_mshrTask_bits_chiOpcode),
    .io_mshrTask_bits_resp                               (mshrCtl_mshrTask_bits_resp),
    .io_mshrTask_bits_fwdState                           (mshrCtl_mshrTask_bits_fwdState),
    .io_mshrTask_bits_pCrdType                           (4'h0),
    .io_mshrTask_bits_retToSrc                           (mshrCtl_mshrTask_bits_retToSrc),
    .io_mshrTask_bits_likelyshared                       (mshrCtl_mshrTask_bits_likelyshared),
    .io_mshrTask_bits_expCompAck                         (mshrCtl_mshrTask_bits_expCompAck),
    .io_mshrTask_bits_allowRetry                         (mshrCtl_mshrTask_bits_allowRetry),
    .io_mshrTask_bits_memAttr_allocate                   (mshrCtl_mshrTask_bits_memAttr_allocate),
    .io_mshrTask_bits_memAttr_cacheable                  (mshrCtl_mshrTask_bits_memAttr_cacheable),
    .io_mshrTask_bits_memAttr_device                     (1'h0),
    .io_mshrTask_bits_memAttr_ewa                        (mshrCtl_mshrTask_bits_memAttr_ewa),
    .io_mshrTask_bits_traceTag                           (mshrCtl_mshrTask_bits_traceTag),
    .io_dirRead_s1_ready                                 (dir_read_ready),
    .io_dirRead_s1_valid                                 (reqArb_dirRead_s1_valid),
    .io_dirRead_s1_bits_tag                              (reqArb_dirRead_s1_bits_tag),
    .io_dirRead_s1_bits_set                              (reqArb_dirRead_s1_bits_set),
    .io_dirRead_s1_bits_wayMask                          (reqArb_dirRead_s1_bits_wayMask),
    .io_dirRead_s1_bits_replacerInfo_channel             (reqArb_dirRead_s1_bits_replacerInfo_channel),
    .io_dirRead_s1_bits_replacerInfo_opcode              (reqArb_dirRead_s1_bits_replacerInfo_opcode),
    .io_dirRead_s1_bits_replacerInfo_reqSource           (reqArb_dirRead_s1_bits_replacerInfo_reqSource),
    .io_dirRead_s1_bits_replacerInfo_refill_prefetch     (reqArb_dirRead_s1_bits_replacerInfo_refill_prefetch),
    .io_dirRead_s1_bits_refill                           (reqArb_dirRead_s1_bits_refill),
    .io_dirRead_s1_bits_mshrId                           (reqArb_dirRead_s1_bits_mshrId),
    .io_dirRead_s1_bits_cmoAll                           (reqArb_dirRead_s1_bits_cmoAll),
    .io_dirRead_s1_bits_cmoWay                           (reqArb_dirRead_s1_bits_cmoWay),
    .io_taskToPipe_s2_valid                              (reqArb_taskToPipe_s2_valid),
    .io_taskToPipe_s2_bits_channel                       (reqArb_taskToPipe_s2_bits_channel),
    .io_taskToPipe_s2_bits_txChannel                     (reqArb_taskToPipe_s2_bits_txChannel),
    .io_taskToPipe_s2_bits_set                           (reqArb_taskToPipe_s2_bits_set),
    .io_taskToPipe_s2_bits_tag                           (reqArb_taskToPipe_s2_bits_tag),
    .io_taskToPipe_s2_bits_off                           (reqArb_taskToPipe_s2_bits_off),
    .io_taskToPipe_s2_bits_alias                         (reqArb_taskToPipe_s2_bits_alias),
    .io_taskToPipe_s2_bits_vaddr                         (reqArb_taskToPipe_s2_bits_vaddr),
    .io_taskToPipe_s2_bits_isKeyword                     (reqArb_taskToPipe_s2_bits_isKeyword),
    .io_taskToPipe_s2_bits_opcode                        (reqArb_taskToPipe_s2_bits_opcode),
    .io_taskToPipe_s2_bits_param                         (reqArb_taskToPipe_s2_bits_param),
    .io_taskToPipe_s2_bits_size                          (reqArb_taskToPipe_s2_bits_size),
    .io_taskToPipe_s2_bits_sourceId                      (reqArb_taskToPipe_s2_bits_sourceId),
    .io_taskToPipe_s2_bits_bufIdx                        (reqArb_taskToPipe_s2_bits_bufIdx),
    .io_taskToPipe_s2_bits_needProbeAckData              (reqArb_taskToPipe_s2_bits_needProbeAckData),
    .io_taskToPipe_s2_bits_denied                        (reqArb_taskToPipe_s2_bits_denied),
    .io_taskToPipe_s2_bits_corrupt                       (reqArb_taskToPipe_s2_bits_corrupt),
    .io_taskToPipe_s2_bits_mshrTask                      (reqArb_taskToPipe_s2_bits_mshrTask),
    .io_taskToPipe_s2_bits_mshrId                        (reqArb_taskToPipe_s2_bits_mshrId),
    .io_taskToPipe_s2_bits_aliasTask                     (reqArb_taskToPipe_s2_bits_aliasTask),
    .io_taskToPipe_s2_bits_useProbeData                  (reqArb_taskToPipe_s2_bits_useProbeData),
    .io_taskToPipe_s2_bits_mshrRetry                     (reqArb_taskToPipe_s2_bits_mshrRetry),
    .io_taskToPipe_s2_bits_readProbeDataDown             (reqArb_taskToPipe_s2_bits_readProbeDataDown),
    .io_taskToPipe_s2_bits_fromL2pft                     (reqArb_taskToPipe_s2_bits_fromL2pft),
    .io_taskToPipe_s2_bits_needHint                      (reqArb_taskToPipe_s2_bits_needHint),
    .io_taskToPipe_s2_bits_dirty                         (reqArb_taskToPipe_s2_bits_dirty),
    .io_taskToPipe_s2_bits_way                           (reqArb_taskToPipe_s2_bits_way),
    .io_taskToPipe_s2_bits_meta_dirty                    (reqArb_taskToPipe_s2_bits_meta_dirty),
    .io_taskToPipe_s2_bits_meta_state                    (reqArb_taskToPipe_s2_bits_meta_state),
    .io_taskToPipe_s2_bits_meta_clients                  (reqArb_taskToPipe_s2_bits_meta_clients),
    .io_taskToPipe_s2_bits_meta_alias                    (reqArb_taskToPipe_s2_bits_meta_alias),
    .io_taskToPipe_s2_bits_meta_prefetch                 (reqArb_taskToPipe_s2_bits_meta_prefetch),
    .io_taskToPipe_s2_bits_meta_prefetchSrc              (reqArb_taskToPipe_s2_bits_meta_prefetchSrc),
    .io_taskToPipe_s2_bits_meta_accessed                 (reqArb_taskToPipe_s2_bits_meta_accessed),
    .io_taskToPipe_s2_bits_meta_tagErr                   (reqArb_taskToPipe_s2_bits_meta_tagErr),
    .io_taskToPipe_s2_bits_meta_dataErr                  (reqArb_taskToPipe_s2_bits_meta_dataErr),
    .io_taskToPipe_s2_bits_metaWen                       (reqArb_taskToPipe_s2_bits_metaWen),
    .io_taskToPipe_s2_bits_tagWen                        (reqArb_taskToPipe_s2_bits_tagWen),
    .io_taskToPipe_s2_bits_dsWen                         (reqArb_taskToPipe_s2_bits_dsWen),
    .io_taskToPipe_s2_bits_wayMask                       (reqArb_taskToPipe_s2_bits_wayMask),
    .io_taskToPipe_s2_bits_replTask                      (reqArb_taskToPipe_s2_bits_replTask),
    .io_taskToPipe_s2_bits_cmoTask                       (reqArb_taskToPipe_s2_bits_cmoTask),
    .io_taskToPipe_s2_bits_cmoAll                        (reqArb_taskToPipe_s2_bits_cmoAll),
    .io_taskToPipe_s2_bits_reqSource                     (reqArb_taskToPipe_s2_bits_reqSource),
    .io_taskToPipe_s2_bits_mergeA                        (reqArb_taskToPipe_s2_bits_mergeA),
    .io_taskToPipe_s2_bits_aMergeTask_off                (reqArb_taskToPipe_s2_bits_aMergeTask_off),
    .io_taskToPipe_s2_bits_aMergeTask_alias              (reqArb_taskToPipe_s2_bits_aMergeTask_alias),
    .io_taskToPipe_s2_bits_aMergeTask_vaddr              (reqArb_taskToPipe_s2_bits_aMergeTask_vaddr),
    .io_taskToPipe_s2_bits_aMergeTask_isKeyword          (reqArb_taskToPipe_s2_bits_aMergeTask_isKeyword),
    .io_taskToPipe_s2_bits_aMergeTask_opcode             (reqArb_taskToPipe_s2_bits_aMergeTask_opcode),
    .io_taskToPipe_s2_bits_aMergeTask_param              (reqArb_taskToPipe_s2_bits_aMergeTask_param),
    .io_taskToPipe_s2_bits_aMergeTask_sourceId           (reqArb_taskToPipe_s2_bits_aMergeTask_sourceId),
    .io_taskToPipe_s2_bits_aMergeTask_meta_dirty         (reqArb_taskToPipe_s2_bits_aMergeTask_meta_dirty),
    .io_taskToPipe_s2_bits_aMergeTask_meta_state         (reqArb_taskToPipe_s2_bits_aMergeTask_meta_state),
    .io_taskToPipe_s2_bits_aMergeTask_meta_clients       (reqArb_taskToPipe_s2_bits_aMergeTask_meta_clients),
    .io_taskToPipe_s2_bits_aMergeTask_meta_alias         (reqArb_taskToPipe_s2_bits_aMergeTask_meta_alias),
    .io_taskToPipe_s2_bits_aMergeTask_meta_prefetch      (reqArb_taskToPipe_s2_bits_aMergeTask_meta_prefetch),
    .io_taskToPipe_s2_bits_aMergeTask_meta_prefetchSrc   (reqArb_taskToPipe_s2_bits_aMergeTask_meta_prefetchSrc),
    .io_taskToPipe_s2_bits_aMergeTask_meta_accessed      (reqArb_taskToPipe_s2_bits_aMergeTask_meta_accessed),
    .io_taskToPipe_s2_bits_aMergeTask_meta_tagErr        (reqArb_taskToPipe_s2_bits_aMergeTask_meta_tagErr),
    .io_taskToPipe_s2_bits_aMergeTask_meta_dataErr       (reqArb_taskToPipe_s2_bits_aMergeTask_meta_dataErr),
    .io_taskToPipe_s2_bits_snpHitRelease                 (reqArb_taskToPipe_s2_bits_snpHitRelease),
    .io_taskToPipe_s2_bits_snpHitReleaseToInval          (reqArb_taskToPipe_s2_bits_snpHitReleaseToInval),
    .io_taskToPipe_s2_bits_snpHitReleaseToClean          (reqArb_taskToPipe_s2_bits_snpHitReleaseToClean),
    .io_taskToPipe_s2_bits_snpHitReleaseWithData         (reqArb_taskToPipe_s2_bits_snpHitReleaseWithData),
    .io_taskToPipe_s2_bits_snpHitReleaseIdx              (reqArb_taskToPipe_s2_bits_snpHitReleaseIdx),
    .io_taskToPipe_s2_bits_snpHitReleaseMeta_dirty       (reqArb_taskToPipe_s2_bits_snpHitReleaseMeta_dirty),
    .io_taskToPipe_s2_bits_snpHitReleaseMeta_state       (reqArb_taskToPipe_s2_bits_snpHitReleaseMeta_state),
    .io_taskToPipe_s2_bits_snpHitReleaseMeta_clients     (reqArb_taskToPipe_s2_bits_snpHitReleaseMeta_clients),
    .io_taskToPipe_s2_bits_snpHitReleaseMeta_alias       (reqArb_taskToPipe_s2_bits_snpHitReleaseMeta_alias),
    .io_taskToPipe_s2_bits_snpHitReleaseMeta_prefetch    (reqArb_taskToPipe_s2_bits_snpHitReleaseMeta_prefetch),
    .io_taskToPipe_s2_bits_snpHitReleaseMeta_prefetchSrc (reqArb_taskToPipe_s2_bits_snpHitReleaseMeta_prefetchSrc),
    .io_taskToPipe_s2_bits_snpHitReleaseMeta_accessed    (reqArb_taskToPipe_s2_bits_snpHitReleaseMeta_accessed),
    .io_taskToPipe_s2_bits_snpHitReleaseMeta_tagErr      (reqArb_taskToPipe_s2_bits_snpHitReleaseMeta_tagErr),
    .io_taskToPipe_s2_bits_snpHitReleaseMeta_dataErr     (reqArb_taskToPipe_s2_bits_snpHitReleaseMeta_dataErr),
    .io_taskToPipe_s2_bits_tgtID                         (reqArb_taskToPipe_s2_bits_tgtID),
    .io_taskToPipe_s2_bits_srcID                         (reqArb_taskToPipe_s2_bits_srcID),
    .io_taskToPipe_s2_bits_txnID                         (reqArb_taskToPipe_s2_bits_txnID),
    .io_taskToPipe_s2_bits_homeNID                       (reqArb_taskToPipe_s2_bits_homeNID),
    .io_taskToPipe_s2_bits_dbID                          (reqArb_taskToPipe_s2_bits_dbID),
    .io_taskToPipe_s2_bits_fwdNID                        (reqArb_taskToPipe_s2_bits_fwdNID),
    .io_taskToPipe_s2_bits_fwdTxnID                      (reqArb_taskToPipe_s2_bits_fwdTxnID),
    .io_taskToPipe_s2_bits_chiOpcode                     (reqArb_taskToPipe_s2_bits_chiOpcode),
    .io_taskToPipe_s2_bits_resp                          (reqArb_taskToPipe_s2_bits_resp),
    .io_taskToPipe_s2_bits_fwdState                      (reqArb_taskToPipe_s2_bits_fwdState),
    .io_taskToPipe_s2_bits_pCrdType                      (reqArb_taskToPipe_s2_bits_pCrdType),
    .io_taskToPipe_s2_bits_retToSrc                      (reqArb_taskToPipe_s2_bits_retToSrc),
    .io_taskToPipe_s2_bits_likelyshared                  (reqArb_taskToPipe_s2_bits_likelyshared),
    .io_taskToPipe_s2_bits_expCompAck                    (reqArb_taskToPipe_s2_bits_expCompAck),
    .io_taskToPipe_s2_bits_allowRetry                    (reqArb_taskToPipe_s2_bits_allowRetry),
    .io_taskToPipe_s2_bits_memAttr_allocate              (reqArb_taskToPipe_s2_bits_memAttr_allocate),
    .io_taskToPipe_s2_bits_memAttr_cacheable             (reqArb_taskToPipe_s2_bits_memAttr_cacheable),
    .io_taskToPipe_s2_bits_memAttr_device                (reqArb_taskToPipe_s2_bits_memAttr_device),
    .io_taskToPipe_s2_bits_memAttr_ewa                   (reqArb_taskToPipe_s2_bits_memAttr_ewa),
    .io_taskToPipe_s2_bits_traceTag                      (reqArb_taskToPipe_s2_bits_traceTag),
    .io_taskInfo_s1_valid                                (reqArb_taskInfo_s1_valid),
    .io_taskInfo_s1_bits_channel                         (reqArb_taskInfo_s1_bits_channel),
    .io_taskInfo_s1_bits_txChannel                       (),
    .io_taskInfo_s1_bits_set                             (),
    .io_taskInfo_s1_bits_tag                             (),
    .io_taskInfo_s1_bits_off                             (),
    .io_taskInfo_s1_bits_alias                           (),
    .io_taskInfo_s1_bits_vaddr                           (),
    .io_taskInfo_s1_bits_isKeyword                       (reqArb_taskInfo_s1_bits_isKeyword),
    .io_taskInfo_s1_bits_opcode                          (reqArb_taskInfo_s1_bits_opcode),
    .io_taskInfo_s1_bits_param                           (),
    .io_taskInfo_s1_bits_size                            (),
    .io_taskInfo_s1_bits_sourceId                        (reqArb_taskInfo_s1_bits_sourceId),
    .io_taskInfo_s1_bits_bufIdx                          (),
    .io_taskInfo_s1_bits_needProbeAckData                (),
    .io_taskInfo_s1_bits_denied                          (),
    .io_taskInfo_s1_bits_corrupt                         (),
    .io_taskInfo_s1_bits_mshrTask                        (reqArb_taskInfo_s1_bits_mshrTask),
    .io_taskInfo_s1_bits_mshrId                          (),
    .io_taskInfo_s1_bits_aliasTask                       (),
    .io_taskInfo_s1_bits_useProbeData                    (),
    .io_taskInfo_s1_bits_mshrRetry                       (),
    .io_taskInfo_s1_bits_readProbeDataDown               (),
    .io_taskInfo_s1_bits_fromL2pft                       (),
    .io_taskInfo_s1_bits_needHint                        (),
    .io_taskInfo_s1_bits_dirty                           (),
    .io_taskInfo_s1_bits_way                             (),
    .io_taskInfo_s1_bits_meta_dirty                      (),
    .io_taskInfo_s1_bits_meta_state                      (),
    .io_taskInfo_s1_bits_meta_clients                    (),
    .io_taskInfo_s1_bits_meta_alias                      (),
    .io_taskInfo_s1_bits_meta_prefetch                   (),
    .io_taskInfo_s1_bits_meta_prefetchSrc                (),
    .io_taskInfo_s1_bits_meta_accessed                   (),
    .io_taskInfo_s1_bits_meta_tagErr                     (),
    .io_taskInfo_s1_bits_meta_dataErr                    (),
    .io_taskInfo_s1_bits_metaWen                         (),
    .io_taskInfo_s1_bits_tagWen                          (),
    .io_taskInfo_s1_bits_dsWen                           (),
    .io_taskInfo_s1_bits_wayMask                         (),
    .io_taskInfo_s1_bits_replTask                        (),
    .io_taskInfo_s1_bits_cmoTask                         (),
    .io_taskInfo_s1_bits_cmoAll                          (),
    .io_taskInfo_s1_bits_reqSource                       (),
    .io_taskInfo_s1_bits_mergeA                          (reqArb_taskInfo_s1_bits_mergeA),
    .io_taskInfo_s1_bits_aMergeTask_off                  (),
    .io_taskInfo_s1_bits_aMergeTask_alias                (),
    .io_taskInfo_s1_bits_aMergeTask_vaddr                (),
    .io_taskInfo_s1_bits_aMergeTask_isKeyword            (reqArb_taskInfo_s1_bits_aMergeTask_isKeyword),
    .io_taskInfo_s1_bits_aMergeTask_opcode               (reqArb_taskInfo_s1_bits_aMergeTask_opcode),
    .io_taskInfo_s1_bits_aMergeTask_param                (),
    .io_taskInfo_s1_bits_aMergeTask_sourceId             (reqArb_taskInfo_s1_bits_aMergeTask_sourceId),
    .io_taskInfo_s1_bits_aMergeTask_meta_dirty           (),
    .io_taskInfo_s1_bits_aMergeTask_meta_state           (),
    .io_taskInfo_s1_bits_aMergeTask_meta_clients         (),
    .io_taskInfo_s1_bits_aMergeTask_meta_alias           (),
    .io_taskInfo_s1_bits_aMergeTask_meta_prefetch        (),
    .io_taskInfo_s1_bits_aMergeTask_meta_prefetchSrc     (),
    .io_taskInfo_s1_bits_aMergeTask_meta_accessed        (),
    .io_taskInfo_s1_bits_aMergeTask_meta_tagErr          (),
    .io_taskInfo_s1_bits_aMergeTask_meta_dataErr         (),
    .io_taskInfo_s1_bits_snpHitRelease                   (),
    .io_taskInfo_s1_bits_snpHitReleaseToInval            (),
    .io_taskInfo_s1_bits_snpHitReleaseToClean            (),
    .io_taskInfo_s1_bits_snpHitReleaseWithData           (),
    .io_taskInfo_s1_bits_snpHitReleaseIdx                (),
    .io_taskInfo_s1_bits_snpHitReleaseMeta_dirty         (),
    .io_taskInfo_s1_bits_snpHitReleaseMeta_state         (),
    .io_taskInfo_s1_bits_snpHitReleaseMeta_clients       (),
    .io_taskInfo_s1_bits_snpHitReleaseMeta_alias         (),
    .io_taskInfo_s1_bits_snpHitReleaseMeta_prefetch      (),
    .io_taskInfo_s1_bits_snpHitReleaseMeta_prefetchSrc   (),
    .io_taskInfo_s1_bits_snpHitReleaseMeta_accessed      (),
    .io_taskInfo_s1_bits_snpHitReleaseMeta_tagErr        (),
    .io_taskInfo_s1_bits_snpHitReleaseMeta_dataErr       (),
    .io_taskInfo_s1_bits_tgtID                           (),
    .io_taskInfo_s1_bits_srcID                           (),
    .io_taskInfo_s1_bits_txnID                           (),
    .io_taskInfo_s1_bits_homeNID                         (),
    .io_taskInfo_s1_bits_dbID                            (),
    .io_taskInfo_s1_bits_fwdNID                          (),
    .io_taskInfo_s1_bits_fwdTxnID                        (),
    .io_taskInfo_s1_bits_chiOpcode                       (),
    .io_taskInfo_s1_bits_resp                            (),
    .io_taskInfo_s1_bits_fwdState                        (),
    .io_taskInfo_s1_bits_pCrdType                        (),
    .io_taskInfo_s1_bits_retToSrc                        (),
    .io_taskInfo_s1_bits_likelyshared                    (),
    .io_taskInfo_s1_bits_expCompAck                      (),
    .io_taskInfo_s1_bits_allowRetry                      (),
    .io_taskInfo_s1_bits_memAttr_allocate                (),
    .io_taskInfo_s1_bits_memAttr_cacheable               (),
    .io_taskInfo_s1_bits_memAttr_device                  (),
    .io_taskInfo_s1_bits_memAttr_ewa                     (),
    .io_taskInfo_s1_bits_traceTag                        (),
    .io_refillBufRead_s2_valid                           (reqArb_refillBufRead_s2_valid),
    .io_refillBufRead_s2_bits_id                         (reqArb_refillBufRead_s2_bits_id),
    .io_releaseBufRead_s2_valid                          (reqArb_releaseBufRead_s2_valid),
    .io_releaseBufRead_s2_bits_id                        (reqArb_releaseBufRead_s2_bits_id),
    .io_status_s1_tags_0                                 (),
    .io_status_s1_tags_1                                 (reqArb_status_s1_tags_1),
    .io_status_s1_tags_2                                 (),
    .io_status_s1_tags_3                                 (),
    .io_status_s1_sets_0                                 (reqArb_status_s1_sets_0),
    .io_status_s1_sets_1                                 (reqArb_status_s1_sets_1),
    .io_status_s1_sets_2                                 (reqArb_status_s1_sets_2),
    .io_status_s1_sets_3                                 (reqArb_status_s1_sets_3),
    .io_status_vec_0_valid                               (),
    .io_status_vec_0_bits_channel                        (),
    .io_status_vec_1_valid                               (reqArb_status_vec_1_valid),
    .io_status_vec_1_bits_channel                        (reqArb_status_vec_1_bits_channel),
    .io_status_vec_toTX_0_valid                          (),
    .io_status_vec_toTX_0_bits_channel                   (),
    .io_status_vec_toTX_0_bits_txChannel                 (),
    .io_status_vec_toTX_0_bits_mshrTask                  (),
    .io_status_vec_toTX_1_valid                          (reqArb_status_vec_toTX_1_valid),
    .io_status_vec_toTX_1_bits_channel                   (reqArb_status_vec_toTX_1_bits_channel),
    .io_status_vec_toTX_1_bits_txChannel                 (reqArb_status_vec_toTX_1_bits_txChannel),
    .io_status_vec_toTX_1_bits_mshrTask                  (reqArb_status_vec_toTX_1_bits_mshrTask),
    .io_fromMSHRCtl_blockG_s1                            (1'h0),
    .io_fromMSHRCtl_blockA_s1                            (mshrCtl_toReqArb_blockA_s1),
    .io_fromMSHRCtl_blockB_s1                            (mshrCtl_toReqArb_blockB_s1),
    .io_fromMSHRCtl_blockC_s1                            (1'h0),
    .io_fromMainPipe_blockG_s1                           (mainPipe_toReqArb_blockG_s1),
    .io_fromMainPipe_blockA_s1                           (1'h0),
    .io_fromMainPipe_blockB_s1                           (mainPipe_toReqArb_blockB_s1),
    .io_fromMainPipe_blockC_s1                           (mainPipe_toReqArb_blockC_s1),
    .io_fromGrantBuffer_blockSinkReqEntrance_blockG_s1   (1'h0),
    .io_fromGrantBuffer_blockSinkReqEntrance_blockA_s1   (grantBuf_toReqArb_blockSinkReqEntrance_blockA_s1),
    .io_fromGrantBuffer_blockSinkReqEntrance_blockB_s1   (grantBuf_toReqArb_blockSinkReqEntrance_blockB_s1),
    .io_fromGrantBuffer_blockSinkReqEntrance_blockC_s1   (grantBuf_toReqArb_blockSinkReqEntrance_blockC_s1),
    .io_fromGrantBuffer_blockMSHRReqEntrance             (grantBuf_toReqArb_blockMSHRReqEntrance),
    .io_fromTXDAT_blockMSHRReqEntrance                   (txdat_toReqArb_blockMSHRReqEntrance),
    .io_fromTXDAT_blockSinkBReqEntrance                  (txdat_toReqArb_blockSinkBReqEntrance),
    .io_fromTXRSP_blockMSHRReqEntrance                   (txrsp_toReqArb_blockMSHRReqEntrance),
    .io_fromTXRSP_blockSinkBReqEntrance                  (txrsp_toReqArb_blockSinkBReqEntrance),
    .io_fromTXREQ_blockMSHRReqEntrance                   (txreq_toReqArb_blockMSHRReqEntrance),
    .io_msInfo_0_valid                                   (mshrCtl_msInfo_0_valid),
    .io_msInfo_0_bits_channel                            (mshrCtl_msInfo_0_bits_channel),
    .io_msInfo_0_bits_set                                (mshrCtl_msInfo_0_bits_set),
    .io_msInfo_0_bits_way                                (mshrCtl_msInfo_0_bits_way),
    .io_msInfo_0_bits_reqTag                             (mshrCtl_msInfo_0_bits_reqTag),
    .io_msInfo_0_bits_willFree                           (mshrCtl_msInfo_0_bits_willFree),
    .io_msInfo_0_bits_aliasTask                          (mshrCtl_msInfo_0_bits_aliasTask),
    .io_msInfo_0_bits_needRelease                        (mshrCtl_msInfo_0_bits_needRelease),
    .io_msInfo_0_bits_blockRefill                        (mshrCtl_msInfo_0_bits_blockRefill),
    .io_msInfo_0_bits_meta_dirty                         (mshrCtl_msInfo_0_bits_meta_dirty),
    .io_msInfo_0_bits_meta_state                         (mshrCtl_msInfo_0_bits_meta_state),
    .io_msInfo_0_bits_meta_clients                       (mshrCtl_msInfo_0_bits_meta_clients),
    .io_msInfo_0_bits_meta_alias                         (mshrCtl_msInfo_0_bits_meta_alias),
    .io_msInfo_0_bits_meta_prefetch                      (mshrCtl_msInfo_0_bits_meta_prefetch),
    .io_msInfo_0_bits_meta_prefetchSrc                   (mshrCtl_msInfo_0_bits_meta_prefetchSrc),
    .io_msInfo_0_bits_meta_accessed                      (mshrCtl_msInfo_0_bits_meta_accessed),
    .io_msInfo_0_bits_meta_tagErr                        (mshrCtl_msInfo_0_bits_meta_tagErr),
    .io_msInfo_0_bits_meta_dataErr                       (mshrCtl_msInfo_0_bits_meta_dataErr),
    .io_msInfo_0_bits_metaTag                            (mshrCtl_msInfo_0_bits_metaTag),
    .io_msInfo_0_bits_dirHit                             (mshrCtl_msInfo_0_bits_dirHit),
    .io_msInfo_0_bits_isAcqOrPrefetch                    (mshrCtl_msInfo_0_bits_isAcqOrPrefetch),
    .io_msInfo_0_bits_isPrefetch                         (mshrCtl_msInfo_0_bits_isPrefetch),
    .io_msInfo_0_bits_param                              (mshrCtl_msInfo_0_bits_param),
    .io_msInfo_0_bits_mergeA                             (mshrCtl_msInfo_0_bits_mergeA),
    .io_msInfo_0_bits_w_grantfirst                       (mshrCtl_msInfo_0_bits_w_grantfirst),
    .io_msInfo_0_bits_s_release                          (mshrCtl_msInfo_0_bits_s_release),
    .io_msInfo_0_bits_s_refill                           (mshrCtl_msInfo_0_bits_s_refill),
    .io_msInfo_0_bits_s_cmoresp                          (mshrCtl_msInfo_0_bits_s_cmoresp),
    .io_msInfo_0_bits_s_cmometaw                         (mshrCtl_msInfo_0_bits_s_cmometaw),
    .io_msInfo_0_bits_w_releaseack                       (mshrCtl_msInfo_0_bits_w_releaseack),
    .io_msInfo_0_bits_w_replResp                         (mshrCtl_msInfo_0_bits_w_replResp),
    .io_msInfo_0_bits_w_rprobeacklast                    (mshrCtl_msInfo_0_bits_w_rprobeacklast),
    .io_msInfo_0_bits_replaceData                        (mshrCtl_msInfo_0_bits_replaceData),
    .io_msInfo_0_bits_releaseToClean                     (mshrCtl_msInfo_0_bits_releaseToClean),
    .io_msInfo_1_valid                                   (mshrCtl_msInfo_1_valid),
    .io_msInfo_1_bits_channel                            (mshrCtl_msInfo_1_bits_channel),
    .io_msInfo_1_bits_set                                (mshrCtl_msInfo_1_bits_set),
    .io_msInfo_1_bits_way                                (mshrCtl_msInfo_1_bits_way),
    .io_msInfo_1_bits_reqTag                             (mshrCtl_msInfo_1_bits_reqTag),
    .io_msInfo_1_bits_willFree                           (mshrCtl_msInfo_1_bits_willFree),
    .io_msInfo_1_bits_aliasTask                          (mshrCtl_msInfo_1_bits_aliasTask),
    .io_msInfo_1_bits_needRelease                        (mshrCtl_msInfo_1_bits_needRelease),
    .io_msInfo_1_bits_blockRefill                        (mshrCtl_msInfo_1_bits_blockRefill),
    .io_msInfo_1_bits_meta_dirty                         (mshrCtl_msInfo_1_bits_meta_dirty),
    .io_msInfo_1_bits_meta_state                         (mshrCtl_msInfo_1_bits_meta_state),
    .io_msInfo_1_bits_meta_clients                       (mshrCtl_msInfo_1_bits_meta_clients),
    .io_msInfo_1_bits_meta_alias                         (mshrCtl_msInfo_1_bits_meta_alias),
    .io_msInfo_1_bits_meta_prefetch                      (mshrCtl_msInfo_1_bits_meta_prefetch),
    .io_msInfo_1_bits_meta_prefetchSrc                   (mshrCtl_msInfo_1_bits_meta_prefetchSrc),
    .io_msInfo_1_bits_meta_accessed                      (mshrCtl_msInfo_1_bits_meta_accessed),
    .io_msInfo_1_bits_meta_tagErr                        (mshrCtl_msInfo_1_bits_meta_tagErr),
    .io_msInfo_1_bits_meta_dataErr                       (mshrCtl_msInfo_1_bits_meta_dataErr),
    .io_msInfo_1_bits_metaTag                            (mshrCtl_msInfo_1_bits_metaTag),
    .io_msInfo_1_bits_dirHit                             (mshrCtl_msInfo_1_bits_dirHit),
    .io_msInfo_1_bits_isAcqOrPrefetch                    (mshrCtl_msInfo_1_bits_isAcqOrPrefetch),
    .io_msInfo_1_bits_isPrefetch                         (mshrCtl_msInfo_1_bits_isPrefetch),
    .io_msInfo_1_bits_param                              (mshrCtl_msInfo_1_bits_param),
    .io_msInfo_1_bits_mergeA                             (mshrCtl_msInfo_1_bits_mergeA),
    .io_msInfo_1_bits_w_grantfirst                       (mshrCtl_msInfo_1_bits_w_grantfirst),
    .io_msInfo_1_bits_s_release                          (mshrCtl_msInfo_1_bits_s_release),
    .io_msInfo_1_bits_s_refill                           (mshrCtl_msInfo_1_bits_s_refill),
    .io_msInfo_1_bits_s_cmoresp                          (mshrCtl_msInfo_1_bits_s_cmoresp),
    .io_msInfo_1_bits_s_cmometaw                         (mshrCtl_msInfo_1_bits_s_cmometaw),
    .io_msInfo_1_bits_w_releaseack                       (mshrCtl_msInfo_1_bits_w_releaseack),
    .io_msInfo_1_bits_w_replResp                         (mshrCtl_msInfo_1_bits_w_replResp),
    .io_msInfo_1_bits_w_rprobeacklast                    (mshrCtl_msInfo_1_bits_w_rprobeacklast),
    .io_msInfo_1_bits_replaceData                        (mshrCtl_msInfo_1_bits_replaceData),
    .io_msInfo_1_bits_releaseToClean                     (mshrCtl_msInfo_1_bits_releaseToClean),
    .io_msInfo_2_valid                                   (mshrCtl_msInfo_2_valid),
    .io_msInfo_2_bits_channel                            (mshrCtl_msInfo_2_bits_channel),
    .io_msInfo_2_bits_set                                (mshrCtl_msInfo_2_bits_set),
    .io_msInfo_2_bits_way                                (mshrCtl_msInfo_2_bits_way),
    .io_msInfo_2_bits_reqTag                             (mshrCtl_msInfo_2_bits_reqTag),
    .io_msInfo_2_bits_willFree                           (mshrCtl_msInfo_2_bits_willFree),
    .io_msInfo_2_bits_aliasTask                          (mshrCtl_msInfo_2_bits_aliasTask),
    .io_msInfo_2_bits_needRelease                        (mshrCtl_msInfo_2_bits_needRelease),
    .io_msInfo_2_bits_blockRefill                        (mshrCtl_msInfo_2_bits_blockRefill),
    .io_msInfo_2_bits_meta_dirty                         (mshrCtl_msInfo_2_bits_meta_dirty),
    .io_msInfo_2_bits_meta_state                         (mshrCtl_msInfo_2_bits_meta_state),
    .io_msInfo_2_bits_meta_clients                       (mshrCtl_msInfo_2_bits_meta_clients),
    .io_msInfo_2_bits_meta_alias                         (mshrCtl_msInfo_2_bits_meta_alias),
    .io_msInfo_2_bits_meta_prefetch                      (mshrCtl_msInfo_2_bits_meta_prefetch),
    .io_msInfo_2_bits_meta_prefetchSrc                   (mshrCtl_msInfo_2_bits_meta_prefetchSrc),
    .io_msInfo_2_bits_meta_accessed                      (mshrCtl_msInfo_2_bits_meta_accessed),
    .io_msInfo_2_bits_meta_tagErr                        (mshrCtl_msInfo_2_bits_meta_tagErr),
    .io_msInfo_2_bits_meta_dataErr                       (mshrCtl_msInfo_2_bits_meta_dataErr),
    .io_msInfo_2_bits_metaTag                            (mshrCtl_msInfo_2_bits_metaTag),
    .io_msInfo_2_bits_dirHit                             (mshrCtl_msInfo_2_bits_dirHit),
    .io_msInfo_2_bits_isAcqOrPrefetch                    (mshrCtl_msInfo_2_bits_isAcqOrPrefetch),
    .io_msInfo_2_bits_isPrefetch                         (mshrCtl_msInfo_2_bits_isPrefetch),
    .io_msInfo_2_bits_param                              (mshrCtl_msInfo_2_bits_param),
    .io_msInfo_2_bits_mergeA                             (mshrCtl_msInfo_2_bits_mergeA),
    .io_msInfo_2_bits_w_grantfirst                       (mshrCtl_msInfo_2_bits_w_grantfirst),
    .io_msInfo_2_bits_s_release                          (mshrCtl_msInfo_2_bits_s_release),
    .io_msInfo_2_bits_s_refill                           (mshrCtl_msInfo_2_bits_s_refill),
    .io_msInfo_2_bits_s_cmoresp                          (mshrCtl_msInfo_2_bits_s_cmoresp),
    .io_msInfo_2_bits_s_cmometaw                         (mshrCtl_msInfo_2_bits_s_cmometaw),
    .io_msInfo_2_bits_w_releaseack                       (mshrCtl_msInfo_2_bits_w_releaseack),
    .io_msInfo_2_bits_w_replResp                         (mshrCtl_msInfo_2_bits_w_replResp),
    .io_msInfo_2_bits_w_rprobeacklast                    (mshrCtl_msInfo_2_bits_w_rprobeacklast),
    .io_msInfo_2_bits_replaceData                        (mshrCtl_msInfo_2_bits_replaceData),
    .io_msInfo_2_bits_releaseToClean                     (mshrCtl_msInfo_2_bits_releaseToClean),
    .io_msInfo_3_valid                                   (mshrCtl_msInfo_3_valid),
    .io_msInfo_3_bits_channel                            (mshrCtl_msInfo_3_bits_channel),
    .io_msInfo_3_bits_set                                (mshrCtl_msInfo_3_bits_set),
    .io_msInfo_3_bits_way                                (mshrCtl_msInfo_3_bits_way),
    .io_msInfo_3_bits_reqTag                             (mshrCtl_msInfo_3_bits_reqTag),
    .io_msInfo_3_bits_willFree                           (mshrCtl_msInfo_3_bits_willFree),
    .io_msInfo_3_bits_aliasTask                          (mshrCtl_msInfo_3_bits_aliasTask),
    .io_msInfo_3_bits_needRelease                        (mshrCtl_msInfo_3_bits_needRelease),
    .io_msInfo_3_bits_blockRefill                        (mshrCtl_msInfo_3_bits_blockRefill),
    .io_msInfo_3_bits_meta_dirty                         (mshrCtl_msInfo_3_bits_meta_dirty),
    .io_msInfo_3_bits_meta_state                         (mshrCtl_msInfo_3_bits_meta_state),
    .io_msInfo_3_bits_meta_clients                       (mshrCtl_msInfo_3_bits_meta_clients),
    .io_msInfo_3_bits_meta_alias                         (mshrCtl_msInfo_3_bits_meta_alias),
    .io_msInfo_3_bits_meta_prefetch                      (mshrCtl_msInfo_3_bits_meta_prefetch),
    .io_msInfo_3_bits_meta_prefetchSrc                   (mshrCtl_msInfo_3_bits_meta_prefetchSrc),
    .io_msInfo_3_bits_meta_accessed                      (mshrCtl_msInfo_3_bits_meta_accessed),
    .io_msInfo_3_bits_meta_tagErr                        (mshrCtl_msInfo_3_bits_meta_tagErr),
    .io_msInfo_3_bits_meta_dataErr                       (mshrCtl_msInfo_3_bits_meta_dataErr),
    .io_msInfo_3_bits_metaTag                            (mshrCtl_msInfo_3_bits_metaTag),
    .io_msInfo_3_bits_dirHit                             (mshrCtl_msInfo_3_bits_dirHit),
    .io_msInfo_3_bits_isAcqOrPrefetch                    (mshrCtl_msInfo_3_bits_isAcqOrPrefetch),
    .io_msInfo_3_bits_isPrefetch                         (mshrCtl_msInfo_3_bits_isPrefetch),
    .io_msInfo_3_bits_param                              (mshrCtl_msInfo_3_bits_param),
    .io_msInfo_3_bits_mergeA                             (mshrCtl_msInfo_3_bits_mergeA),
    .io_msInfo_3_bits_w_grantfirst                       (mshrCtl_msInfo_3_bits_w_grantfirst),
    .io_msInfo_3_bits_s_release                          (mshrCtl_msInfo_3_bits_s_release),
    .io_msInfo_3_bits_s_refill                           (mshrCtl_msInfo_3_bits_s_refill),
    .io_msInfo_3_bits_s_cmoresp                          (mshrCtl_msInfo_3_bits_s_cmoresp),
    .io_msInfo_3_bits_s_cmometaw                         (mshrCtl_msInfo_3_bits_s_cmometaw),
    .io_msInfo_3_bits_w_releaseack                       (mshrCtl_msInfo_3_bits_w_releaseack),
    .io_msInfo_3_bits_w_replResp                         (mshrCtl_msInfo_3_bits_w_replResp),
    .io_msInfo_3_bits_w_rprobeacklast                    (mshrCtl_msInfo_3_bits_w_rprobeacklast),
    .io_msInfo_3_bits_replaceData                        (mshrCtl_msInfo_3_bits_replaceData),
    .io_msInfo_3_bits_releaseToClean                     (mshrCtl_msInfo_3_bits_releaseToClean),
    .io_msInfo_4_valid                                   (mshrCtl_msInfo_4_valid),
    .io_msInfo_4_bits_channel                            (mshrCtl_msInfo_4_bits_channel),
    .io_msInfo_4_bits_set                                (mshrCtl_msInfo_4_bits_set),
    .io_msInfo_4_bits_way                                (mshrCtl_msInfo_4_bits_way),
    .io_msInfo_4_bits_reqTag                             (mshrCtl_msInfo_4_bits_reqTag),
    .io_msInfo_4_bits_willFree                           (mshrCtl_msInfo_4_bits_willFree),
    .io_msInfo_4_bits_aliasTask                          (mshrCtl_msInfo_4_bits_aliasTask),
    .io_msInfo_4_bits_needRelease                        (mshrCtl_msInfo_4_bits_needRelease),
    .io_msInfo_4_bits_blockRefill                        (mshrCtl_msInfo_4_bits_blockRefill),
    .io_msInfo_4_bits_meta_dirty                         (mshrCtl_msInfo_4_bits_meta_dirty),
    .io_msInfo_4_bits_meta_state                         (mshrCtl_msInfo_4_bits_meta_state),
    .io_msInfo_4_bits_meta_clients                       (mshrCtl_msInfo_4_bits_meta_clients),
    .io_msInfo_4_bits_meta_alias                         (mshrCtl_msInfo_4_bits_meta_alias),
    .io_msInfo_4_bits_meta_prefetch                      (mshrCtl_msInfo_4_bits_meta_prefetch),
    .io_msInfo_4_bits_meta_prefetchSrc                   (mshrCtl_msInfo_4_bits_meta_prefetchSrc),
    .io_msInfo_4_bits_meta_accessed                      (mshrCtl_msInfo_4_bits_meta_accessed),
    .io_msInfo_4_bits_meta_tagErr                        (mshrCtl_msInfo_4_bits_meta_tagErr),
    .io_msInfo_4_bits_meta_dataErr                       (mshrCtl_msInfo_4_bits_meta_dataErr),
    .io_msInfo_4_bits_metaTag                            (mshrCtl_msInfo_4_bits_metaTag),
    .io_msInfo_4_bits_dirHit                             (mshrCtl_msInfo_4_bits_dirHit),
    .io_msInfo_4_bits_isAcqOrPrefetch                    (mshrCtl_msInfo_4_bits_isAcqOrPrefetch),
    .io_msInfo_4_bits_isPrefetch                         (mshrCtl_msInfo_4_bits_isPrefetch),
    .io_msInfo_4_bits_param                              (mshrCtl_msInfo_4_bits_param),
    .io_msInfo_4_bits_mergeA                             (mshrCtl_msInfo_4_bits_mergeA),
    .io_msInfo_4_bits_w_grantfirst                       (mshrCtl_msInfo_4_bits_w_grantfirst),
    .io_msInfo_4_bits_s_release                          (mshrCtl_msInfo_4_bits_s_release),
    .io_msInfo_4_bits_s_refill                           (mshrCtl_msInfo_4_bits_s_refill),
    .io_msInfo_4_bits_s_cmoresp                          (mshrCtl_msInfo_4_bits_s_cmoresp),
    .io_msInfo_4_bits_s_cmometaw                         (mshrCtl_msInfo_4_bits_s_cmometaw),
    .io_msInfo_4_bits_w_releaseack                       (mshrCtl_msInfo_4_bits_w_releaseack),
    .io_msInfo_4_bits_w_replResp                         (mshrCtl_msInfo_4_bits_w_replResp),
    .io_msInfo_4_bits_w_rprobeacklast                    (mshrCtl_msInfo_4_bits_w_rprobeacklast),
    .io_msInfo_4_bits_replaceData                        (mshrCtl_msInfo_4_bits_replaceData),
    .io_msInfo_4_bits_releaseToClean                     (mshrCtl_msInfo_4_bits_releaseToClean),
    .io_msInfo_5_valid                                   (mshrCtl_msInfo_5_valid),
    .io_msInfo_5_bits_channel                            (mshrCtl_msInfo_5_bits_channel),
    .io_msInfo_5_bits_set                                (mshrCtl_msInfo_5_bits_set),
    .io_msInfo_5_bits_way                                (mshrCtl_msInfo_5_bits_way),
    .io_msInfo_5_bits_reqTag                             (mshrCtl_msInfo_5_bits_reqTag),
    .io_msInfo_5_bits_willFree                           (mshrCtl_msInfo_5_bits_willFree),
    .io_msInfo_5_bits_aliasTask                          (mshrCtl_msInfo_5_bits_aliasTask),
    .io_msInfo_5_bits_needRelease                        (mshrCtl_msInfo_5_bits_needRelease),
    .io_msInfo_5_bits_blockRefill                        (mshrCtl_msInfo_5_bits_blockRefill),
    .io_msInfo_5_bits_meta_dirty                         (mshrCtl_msInfo_5_bits_meta_dirty),
    .io_msInfo_5_bits_meta_state                         (mshrCtl_msInfo_5_bits_meta_state),
    .io_msInfo_5_bits_meta_clients                       (mshrCtl_msInfo_5_bits_meta_clients),
    .io_msInfo_5_bits_meta_alias                         (mshrCtl_msInfo_5_bits_meta_alias),
    .io_msInfo_5_bits_meta_prefetch                      (mshrCtl_msInfo_5_bits_meta_prefetch),
    .io_msInfo_5_bits_meta_prefetchSrc                   (mshrCtl_msInfo_5_bits_meta_prefetchSrc),
    .io_msInfo_5_bits_meta_accessed                      (mshrCtl_msInfo_5_bits_meta_accessed),
    .io_msInfo_5_bits_meta_tagErr                        (mshrCtl_msInfo_5_bits_meta_tagErr),
    .io_msInfo_5_bits_meta_dataErr                       (mshrCtl_msInfo_5_bits_meta_dataErr),
    .io_msInfo_5_bits_metaTag                            (mshrCtl_msInfo_5_bits_metaTag),
    .io_msInfo_5_bits_dirHit                             (mshrCtl_msInfo_5_bits_dirHit),
    .io_msInfo_5_bits_isAcqOrPrefetch                    (mshrCtl_msInfo_5_bits_isAcqOrPrefetch),
    .io_msInfo_5_bits_isPrefetch                         (mshrCtl_msInfo_5_bits_isPrefetch),
    .io_msInfo_5_bits_param                              (mshrCtl_msInfo_5_bits_param),
    .io_msInfo_5_bits_mergeA                             (mshrCtl_msInfo_5_bits_mergeA),
    .io_msInfo_5_bits_w_grantfirst                       (mshrCtl_msInfo_5_bits_w_grantfirst),
    .io_msInfo_5_bits_s_release                          (mshrCtl_msInfo_5_bits_s_release),
    .io_msInfo_5_bits_s_refill                           (mshrCtl_msInfo_5_bits_s_refill),
    .io_msInfo_5_bits_s_cmoresp                          (mshrCtl_msInfo_5_bits_s_cmoresp),
    .io_msInfo_5_bits_s_cmometaw                         (mshrCtl_msInfo_5_bits_s_cmometaw),
    .io_msInfo_5_bits_w_releaseack                       (mshrCtl_msInfo_5_bits_w_releaseack),
    .io_msInfo_5_bits_w_replResp                         (mshrCtl_msInfo_5_bits_w_replResp),
    .io_msInfo_5_bits_w_rprobeacklast                    (mshrCtl_msInfo_5_bits_w_rprobeacklast),
    .io_msInfo_5_bits_replaceData                        (mshrCtl_msInfo_5_bits_replaceData),
    .io_msInfo_5_bits_releaseToClean                     (mshrCtl_msInfo_5_bits_releaseToClean),
    .io_msInfo_6_valid                                   (mshrCtl_msInfo_6_valid),
    .io_msInfo_6_bits_channel                            (mshrCtl_msInfo_6_bits_channel),
    .io_msInfo_6_bits_set                                (mshrCtl_msInfo_6_bits_set),
    .io_msInfo_6_bits_way                                (mshrCtl_msInfo_6_bits_way),
    .io_msInfo_6_bits_reqTag                             (mshrCtl_msInfo_6_bits_reqTag),
    .io_msInfo_6_bits_willFree                           (mshrCtl_msInfo_6_bits_willFree),
    .io_msInfo_6_bits_aliasTask                          (mshrCtl_msInfo_6_bits_aliasTask),
    .io_msInfo_6_bits_needRelease                        (mshrCtl_msInfo_6_bits_needRelease),
    .io_msInfo_6_bits_blockRefill                        (mshrCtl_msInfo_6_bits_blockRefill),
    .io_msInfo_6_bits_meta_dirty                         (mshrCtl_msInfo_6_bits_meta_dirty),
    .io_msInfo_6_bits_meta_state                         (mshrCtl_msInfo_6_bits_meta_state),
    .io_msInfo_6_bits_meta_clients                       (mshrCtl_msInfo_6_bits_meta_clients),
    .io_msInfo_6_bits_meta_alias                         (mshrCtl_msInfo_6_bits_meta_alias),
    .io_msInfo_6_bits_meta_prefetch                      (mshrCtl_msInfo_6_bits_meta_prefetch),
    .io_msInfo_6_bits_meta_prefetchSrc                   (mshrCtl_msInfo_6_bits_meta_prefetchSrc),
    .io_msInfo_6_bits_meta_accessed                      (mshrCtl_msInfo_6_bits_meta_accessed),
    .io_msInfo_6_bits_meta_tagErr                        (mshrCtl_msInfo_6_bits_meta_tagErr),
    .io_msInfo_6_bits_meta_dataErr                       (mshrCtl_msInfo_6_bits_meta_dataErr),
    .io_msInfo_6_bits_metaTag                            (mshrCtl_msInfo_6_bits_metaTag),
    .io_msInfo_6_bits_dirHit                             (mshrCtl_msInfo_6_bits_dirHit),
    .io_msInfo_6_bits_isAcqOrPrefetch                    (mshrCtl_msInfo_6_bits_isAcqOrPrefetch),
    .io_msInfo_6_bits_isPrefetch                         (mshrCtl_msInfo_6_bits_isPrefetch),
    .io_msInfo_6_bits_param                              (mshrCtl_msInfo_6_bits_param),
    .io_msInfo_6_bits_mergeA                             (mshrCtl_msInfo_6_bits_mergeA),
    .io_msInfo_6_bits_w_grantfirst                       (mshrCtl_msInfo_6_bits_w_grantfirst),
    .io_msInfo_6_bits_s_release                          (mshrCtl_msInfo_6_bits_s_release),
    .io_msInfo_6_bits_s_refill                           (mshrCtl_msInfo_6_bits_s_refill),
    .io_msInfo_6_bits_s_cmoresp                          (mshrCtl_msInfo_6_bits_s_cmoresp),
    .io_msInfo_6_bits_s_cmometaw                         (mshrCtl_msInfo_6_bits_s_cmometaw),
    .io_msInfo_6_bits_w_releaseack                       (mshrCtl_msInfo_6_bits_w_releaseack),
    .io_msInfo_6_bits_w_replResp                         (mshrCtl_msInfo_6_bits_w_replResp),
    .io_msInfo_6_bits_w_rprobeacklast                    (mshrCtl_msInfo_6_bits_w_rprobeacklast),
    .io_msInfo_6_bits_replaceData                        (mshrCtl_msInfo_6_bits_replaceData),
    .io_msInfo_6_bits_releaseToClean                     (mshrCtl_msInfo_6_bits_releaseToClean),
    .io_msInfo_7_valid                                   (mshrCtl_msInfo_7_valid),
    .io_msInfo_7_bits_channel                            (mshrCtl_msInfo_7_bits_channel),
    .io_msInfo_7_bits_set                                (mshrCtl_msInfo_7_bits_set),
    .io_msInfo_7_bits_way                                (mshrCtl_msInfo_7_bits_way),
    .io_msInfo_7_bits_reqTag                             (mshrCtl_msInfo_7_bits_reqTag),
    .io_msInfo_7_bits_willFree                           (mshrCtl_msInfo_7_bits_willFree),
    .io_msInfo_7_bits_aliasTask                          (mshrCtl_msInfo_7_bits_aliasTask),
    .io_msInfo_7_bits_needRelease                        (mshrCtl_msInfo_7_bits_needRelease),
    .io_msInfo_7_bits_blockRefill                        (mshrCtl_msInfo_7_bits_blockRefill),
    .io_msInfo_7_bits_meta_dirty                         (mshrCtl_msInfo_7_bits_meta_dirty),
    .io_msInfo_7_bits_meta_state                         (mshrCtl_msInfo_7_bits_meta_state),
    .io_msInfo_7_bits_meta_clients                       (mshrCtl_msInfo_7_bits_meta_clients),
    .io_msInfo_7_bits_meta_alias                         (mshrCtl_msInfo_7_bits_meta_alias),
    .io_msInfo_7_bits_meta_prefetch                      (mshrCtl_msInfo_7_bits_meta_prefetch),
    .io_msInfo_7_bits_meta_prefetchSrc                   (mshrCtl_msInfo_7_bits_meta_prefetchSrc),
    .io_msInfo_7_bits_meta_accessed                      (mshrCtl_msInfo_7_bits_meta_accessed),
    .io_msInfo_7_bits_meta_tagErr                        (mshrCtl_msInfo_7_bits_meta_tagErr),
    .io_msInfo_7_bits_meta_dataErr                       (mshrCtl_msInfo_7_bits_meta_dataErr),
    .io_msInfo_7_bits_metaTag                            (mshrCtl_msInfo_7_bits_metaTag),
    .io_msInfo_7_bits_dirHit                             (mshrCtl_msInfo_7_bits_dirHit),
    .io_msInfo_7_bits_isAcqOrPrefetch                    (mshrCtl_msInfo_7_bits_isAcqOrPrefetch),
    .io_msInfo_7_bits_isPrefetch                         (mshrCtl_msInfo_7_bits_isPrefetch),
    .io_msInfo_7_bits_param                              (mshrCtl_msInfo_7_bits_param),
    .io_msInfo_7_bits_mergeA                             (mshrCtl_msInfo_7_bits_mergeA),
    .io_msInfo_7_bits_w_grantfirst                       (mshrCtl_msInfo_7_bits_w_grantfirst),
    .io_msInfo_7_bits_s_release                          (mshrCtl_msInfo_7_bits_s_release),
    .io_msInfo_7_bits_s_refill                           (mshrCtl_msInfo_7_bits_s_refill),
    .io_msInfo_7_bits_s_cmoresp                          (mshrCtl_msInfo_7_bits_s_cmoresp),
    .io_msInfo_7_bits_s_cmometaw                         (mshrCtl_msInfo_7_bits_s_cmometaw),
    .io_msInfo_7_bits_w_releaseack                       (mshrCtl_msInfo_7_bits_w_releaseack),
    .io_msInfo_7_bits_w_replResp                         (mshrCtl_msInfo_7_bits_w_replResp),
    .io_msInfo_7_bits_w_rprobeacklast                    (mshrCtl_msInfo_7_bits_w_rprobeacklast),
    .io_msInfo_7_bits_replaceData                        (mshrCtl_msInfo_7_bits_replaceData),
    .io_msInfo_7_bits_releaseToClean                     (mshrCtl_msInfo_7_bits_releaseToClean),
    .io_msInfo_8_valid                                   (mshrCtl_msInfo_8_valid),
    .io_msInfo_8_bits_channel                            (mshrCtl_msInfo_8_bits_channel),
    .io_msInfo_8_bits_set                                (mshrCtl_msInfo_8_bits_set),
    .io_msInfo_8_bits_way                                (mshrCtl_msInfo_8_bits_way),
    .io_msInfo_8_bits_reqTag                             (mshrCtl_msInfo_8_bits_reqTag),
    .io_msInfo_8_bits_willFree                           (mshrCtl_msInfo_8_bits_willFree),
    .io_msInfo_8_bits_aliasTask                          (mshrCtl_msInfo_8_bits_aliasTask),
    .io_msInfo_8_bits_needRelease                        (mshrCtl_msInfo_8_bits_needRelease),
    .io_msInfo_8_bits_blockRefill                        (mshrCtl_msInfo_8_bits_blockRefill),
    .io_msInfo_8_bits_meta_dirty                         (mshrCtl_msInfo_8_bits_meta_dirty),
    .io_msInfo_8_bits_meta_state                         (mshrCtl_msInfo_8_bits_meta_state),
    .io_msInfo_8_bits_meta_clients                       (mshrCtl_msInfo_8_bits_meta_clients),
    .io_msInfo_8_bits_meta_alias                         (mshrCtl_msInfo_8_bits_meta_alias),
    .io_msInfo_8_bits_meta_prefetch                      (mshrCtl_msInfo_8_bits_meta_prefetch),
    .io_msInfo_8_bits_meta_prefetchSrc                   (mshrCtl_msInfo_8_bits_meta_prefetchSrc),
    .io_msInfo_8_bits_meta_accessed                      (mshrCtl_msInfo_8_bits_meta_accessed),
    .io_msInfo_8_bits_meta_tagErr                        (mshrCtl_msInfo_8_bits_meta_tagErr),
    .io_msInfo_8_bits_meta_dataErr                       (mshrCtl_msInfo_8_bits_meta_dataErr),
    .io_msInfo_8_bits_metaTag                            (mshrCtl_msInfo_8_bits_metaTag),
    .io_msInfo_8_bits_dirHit                             (mshrCtl_msInfo_8_bits_dirHit),
    .io_msInfo_8_bits_isAcqOrPrefetch                    (mshrCtl_msInfo_8_bits_isAcqOrPrefetch),
    .io_msInfo_8_bits_isPrefetch                         (mshrCtl_msInfo_8_bits_isPrefetch),
    .io_msInfo_8_bits_param                              (mshrCtl_msInfo_8_bits_param),
    .io_msInfo_8_bits_mergeA                             (mshrCtl_msInfo_8_bits_mergeA),
    .io_msInfo_8_bits_w_grantfirst                       (mshrCtl_msInfo_8_bits_w_grantfirst),
    .io_msInfo_8_bits_s_release                          (mshrCtl_msInfo_8_bits_s_release),
    .io_msInfo_8_bits_s_refill                           (mshrCtl_msInfo_8_bits_s_refill),
    .io_msInfo_8_bits_s_cmoresp                          (mshrCtl_msInfo_8_bits_s_cmoresp),
    .io_msInfo_8_bits_s_cmometaw                         (mshrCtl_msInfo_8_bits_s_cmometaw),
    .io_msInfo_8_bits_w_releaseack                       (mshrCtl_msInfo_8_bits_w_releaseack),
    .io_msInfo_8_bits_w_replResp                         (mshrCtl_msInfo_8_bits_w_replResp),
    .io_msInfo_8_bits_w_rprobeacklast                    (mshrCtl_msInfo_8_bits_w_rprobeacklast),
    .io_msInfo_8_bits_replaceData                        (mshrCtl_msInfo_8_bits_replaceData),
    .io_msInfo_8_bits_releaseToClean                     (mshrCtl_msInfo_8_bits_releaseToClean),
    .io_msInfo_9_valid                                   (mshrCtl_msInfo_9_valid),
    .io_msInfo_9_bits_channel                            (mshrCtl_msInfo_9_bits_channel),
    .io_msInfo_9_bits_set                                (mshrCtl_msInfo_9_bits_set),
    .io_msInfo_9_bits_way                                (mshrCtl_msInfo_9_bits_way),
    .io_msInfo_9_bits_reqTag                             (mshrCtl_msInfo_9_bits_reqTag),
    .io_msInfo_9_bits_willFree                           (mshrCtl_msInfo_9_bits_willFree),
    .io_msInfo_9_bits_aliasTask                          (mshrCtl_msInfo_9_bits_aliasTask),
    .io_msInfo_9_bits_needRelease                        (mshrCtl_msInfo_9_bits_needRelease),
    .io_msInfo_9_bits_blockRefill                        (mshrCtl_msInfo_9_bits_blockRefill),
    .io_msInfo_9_bits_meta_dirty                         (mshrCtl_msInfo_9_bits_meta_dirty),
    .io_msInfo_9_bits_meta_state                         (mshrCtl_msInfo_9_bits_meta_state),
    .io_msInfo_9_bits_meta_clients                       (mshrCtl_msInfo_9_bits_meta_clients),
    .io_msInfo_9_bits_meta_alias                         (mshrCtl_msInfo_9_bits_meta_alias),
    .io_msInfo_9_bits_meta_prefetch                      (mshrCtl_msInfo_9_bits_meta_prefetch),
    .io_msInfo_9_bits_meta_prefetchSrc                   (mshrCtl_msInfo_9_bits_meta_prefetchSrc),
    .io_msInfo_9_bits_meta_accessed                      (mshrCtl_msInfo_9_bits_meta_accessed),
    .io_msInfo_9_bits_meta_tagErr                        (mshrCtl_msInfo_9_bits_meta_tagErr),
    .io_msInfo_9_bits_meta_dataErr                       (mshrCtl_msInfo_9_bits_meta_dataErr),
    .io_msInfo_9_bits_metaTag                            (mshrCtl_msInfo_9_bits_metaTag),
    .io_msInfo_9_bits_dirHit                             (mshrCtl_msInfo_9_bits_dirHit),
    .io_msInfo_9_bits_isAcqOrPrefetch                    (mshrCtl_msInfo_9_bits_isAcqOrPrefetch),
    .io_msInfo_9_bits_isPrefetch                         (mshrCtl_msInfo_9_bits_isPrefetch),
    .io_msInfo_9_bits_param                              (mshrCtl_msInfo_9_bits_param),
    .io_msInfo_9_bits_mergeA                             (mshrCtl_msInfo_9_bits_mergeA),
    .io_msInfo_9_bits_w_grantfirst                       (mshrCtl_msInfo_9_bits_w_grantfirst),
    .io_msInfo_9_bits_s_release                          (mshrCtl_msInfo_9_bits_s_release),
    .io_msInfo_9_bits_s_refill                           (mshrCtl_msInfo_9_bits_s_refill),
    .io_msInfo_9_bits_s_cmoresp                          (mshrCtl_msInfo_9_bits_s_cmoresp),
    .io_msInfo_9_bits_s_cmometaw                         (mshrCtl_msInfo_9_bits_s_cmometaw),
    .io_msInfo_9_bits_w_releaseack                       (mshrCtl_msInfo_9_bits_w_releaseack),
    .io_msInfo_9_bits_w_replResp                         (mshrCtl_msInfo_9_bits_w_replResp),
    .io_msInfo_9_bits_w_rprobeacklast                    (mshrCtl_msInfo_9_bits_w_rprobeacklast),
    .io_msInfo_9_bits_replaceData                        (mshrCtl_msInfo_9_bits_replaceData),
    .io_msInfo_9_bits_releaseToClean                     (mshrCtl_msInfo_9_bits_releaseToClean),
    .io_msInfo_10_valid                                  (mshrCtl_msInfo_10_valid),
    .io_msInfo_10_bits_channel                           (mshrCtl_msInfo_10_bits_channel),
    .io_msInfo_10_bits_set                               (mshrCtl_msInfo_10_bits_set),
    .io_msInfo_10_bits_way                               (mshrCtl_msInfo_10_bits_way),
    .io_msInfo_10_bits_reqTag                            (mshrCtl_msInfo_10_bits_reqTag),
    .io_msInfo_10_bits_willFree                          (mshrCtl_msInfo_10_bits_willFree),
    .io_msInfo_10_bits_aliasTask                         (mshrCtl_msInfo_10_bits_aliasTask),
    .io_msInfo_10_bits_needRelease                       (mshrCtl_msInfo_10_bits_needRelease),
    .io_msInfo_10_bits_blockRefill                       (mshrCtl_msInfo_10_bits_blockRefill),
    .io_msInfo_10_bits_meta_dirty                        (mshrCtl_msInfo_10_bits_meta_dirty),
    .io_msInfo_10_bits_meta_state                        (mshrCtl_msInfo_10_bits_meta_state),
    .io_msInfo_10_bits_meta_clients                      (mshrCtl_msInfo_10_bits_meta_clients),
    .io_msInfo_10_bits_meta_alias                        (mshrCtl_msInfo_10_bits_meta_alias),
    .io_msInfo_10_bits_meta_prefetch                     (mshrCtl_msInfo_10_bits_meta_prefetch),
    .io_msInfo_10_bits_meta_prefetchSrc                  (mshrCtl_msInfo_10_bits_meta_prefetchSrc),
    .io_msInfo_10_bits_meta_accessed                     (mshrCtl_msInfo_10_bits_meta_accessed),
    .io_msInfo_10_bits_meta_tagErr                       (mshrCtl_msInfo_10_bits_meta_tagErr),
    .io_msInfo_10_bits_meta_dataErr                      (mshrCtl_msInfo_10_bits_meta_dataErr),
    .io_msInfo_10_bits_metaTag                           (mshrCtl_msInfo_10_bits_metaTag),
    .io_msInfo_10_bits_dirHit                            (mshrCtl_msInfo_10_bits_dirHit),
    .io_msInfo_10_bits_isAcqOrPrefetch                   (mshrCtl_msInfo_10_bits_isAcqOrPrefetch),
    .io_msInfo_10_bits_isPrefetch                        (mshrCtl_msInfo_10_bits_isPrefetch),
    .io_msInfo_10_bits_param                             (mshrCtl_msInfo_10_bits_param),
    .io_msInfo_10_bits_mergeA                            (mshrCtl_msInfo_10_bits_mergeA),
    .io_msInfo_10_bits_w_grantfirst                      (mshrCtl_msInfo_10_bits_w_grantfirst),
    .io_msInfo_10_bits_s_release                         (mshrCtl_msInfo_10_bits_s_release),
    .io_msInfo_10_bits_s_refill                          (mshrCtl_msInfo_10_bits_s_refill),
    .io_msInfo_10_bits_s_cmoresp                         (mshrCtl_msInfo_10_bits_s_cmoresp),
    .io_msInfo_10_bits_s_cmometaw                        (mshrCtl_msInfo_10_bits_s_cmometaw),
    .io_msInfo_10_bits_w_releaseack                      (mshrCtl_msInfo_10_bits_w_releaseack),
    .io_msInfo_10_bits_w_replResp                        (mshrCtl_msInfo_10_bits_w_replResp),
    .io_msInfo_10_bits_w_rprobeacklast                   (mshrCtl_msInfo_10_bits_w_rprobeacklast),
    .io_msInfo_10_bits_replaceData                       (mshrCtl_msInfo_10_bits_replaceData),
    .io_msInfo_10_bits_releaseToClean                    (mshrCtl_msInfo_10_bits_releaseToClean),
    .io_msInfo_11_valid                                  (mshrCtl_msInfo_11_valid),
    .io_msInfo_11_bits_channel                           (mshrCtl_msInfo_11_bits_channel),
    .io_msInfo_11_bits_set                               (mshrCtl_msInfo_11_bits_set),
    .io_msInfo_11_bits_way                               (mshrCtl_msInfo_11_bits_way),
    .io_msInfo_11_bits_reqTag                            (mshrCtl_msInfo_11_bits_reqTag),
    .io_msInfo_11_bits_willFree                          (mshrCtl_msInfo_11_bits_willFree),
    .io_msInfo_11_bits_aliasTask                         (mshrCtl_msInfo_11_bits_aliasTask),
    .io_msInfo_11_bits_needRelease                       (mshrCtl_msInfo_11_bits_needRelease),
    .io_msInfo_11_bits_blockRefill                       (mshrCtl_msInfo_11_bits_blockRefill),
    .io_msInfo_11_bits_meta_dirty                        (mshrCtl_msInfo_11_bits_meta_dirty),
    .io_msInfo_11_bits_meta_state                        (mshrCtl_msInfo_11_bits_meta_state),
    .io_msInfo_11_bits_meta_clients                      (mshrCtl_msInfo_11_bits_meta_clients),
    .io_msInfo_11_bits_meta_alias                        (mshrCtl_msInfo_11_bits_meta_alias),
    .io_msInfo_11_bits_meta_prefetch                     (mshrCtl_msInfo_11_bits_meta_prefetch),
    .io_msInfo_11_bits_meta_prefetchSrc                  (mshrCtl_msInfo_11_bits_meta_prefetchSrc),
    .io_msInfo_11_bits_meta_accessed                     (mshrCtl_msInfo_11_bits_meta_accessed),
    .io_msInfo_11_bits_meta_tagErr                       (mshrCtl_msInfo_11_bits_meta_tagErr),
    .io_msInfo_11_bits_meta_dataErr                      (mshrCtl_msInfo_11_bits_meta_dataErr),
    .io_msInfo_11_bits_metaTag                           (mshrCtl_msInfo_11_bits_metaTag),
    .io_msInfo_11_bits_dirHit                            (mshrCtl_msInfo_11_bits_dirHit),
    .io_msInfo_11_bits_isAcqOrPrefetch                   (mshrCtl_msInfo_11_bits_isAcqOrPrefetch),
    .io_msInfo_11_bits_isPrefetch                        (mshrCtl_msInfo_11_bits_isPrefetch),
    .io_msInfo_11_bits_param                             (mshrCtl_msInfo_11_bits_param),
    .io_msInfo_11_bits_mergeA                            (mshrCtl_msInfo_11_bits_mergeA),
    .io_msInfo_11_bits_w_grantfirst                      (mshrCtl_msInfo_11_bits_w_grantfirst),
    .io_msInfo_11_bits_s_release                         (mshrCtl_msInfo_11_bits_s_release),
    .io_msInfo_11_bits_s_refill                          (mshrCtl_msInfo_11_bits_s_refill),
    .io_msInfo_11_bits_s_cmoresp                         (mshrCtl_msInfo_11_bits_s_cmoresp),
    .io_msInfo_11_bits_s_cmometaw                        (mshrCtl_msInfo_11_bits_s_cmometaw),
    .io_msInfo_11_bits_w_releaseack                      (mshrCtl_msInfo_11_bits_w_releaseack),
    .io_msInfo_11_bits_w_replResp                        (mshrCtl_msInfo_11_bits_w_replResp),
    .io_msInfo_11_bits_w_rprobeacklast                   (mshrCtl_msInfo_11_bits_w_rprobeacklast),
    .io_msInfo_11_bits_replaceData                       (mshrCtl_msInfo_11_bits_replaceData),
    .io_msInfo_11_bits_releaseToClean                    (mshrCtl_msInfo_11_bits_releaseToClean),
    .io_msInfo_12_valid                                  (mshrCtl_msInfo_12_valid),
    .io_msInfo_12_bits_channel                           (mshrCtl_msInfo_12_bits_channel),
    .io_msInfo_12_bits_set                               (mshrCtl_msInfo_12_bits_set),
    .io_msInfo_12_bits_way                               (mshrCtl_msInfo_12_bits_way),
    .io_msInfo_12_bits_reqTag                            (mshrCtl_msInfo_12_bits_reqTag),
    .io_msInfo_12_bits_willFree                          (mshrCtl_msInfo_12_bits_willFree),
    .io_msInfo_12_bits_aliasTask                         (mshrCtl_msInfo_12_bits_aliasTask),
    .io_msInfo_12_bits_needRelease                       (mshrCtl_msInfo_12_bits_needRelease),
    .io_msInfo_12_bits_blockRefill                       (mshrCtl_msInfo_12_bits_blockRefill),
    .io_msInfo_12_bits_meta_dirty                        (mshrCtl_msInfo_12_bits_meta_dirty),
    .io_msInfo_12_bits_meta_state                        (mshrCtl_msInfo_12_bits_meta_state),
    .io_msInfo_12_bits_meta_clients                      (mshrCtl_msInfo_12_bits_meta_clients),
    .io_msInfo_12_bits_meta_alias                        (mshrCtl_msInfo_12_bits_meta_alias),
    .io_msInfo_12_bits_meta_prefetch                     (mshrCtl_msInfo_12_bits_meta_prefetch),
    .io_msInfo_12_bits_meta_prefetchSrc                  (mshrCtl_msInfo_12_bits_meta_prefetchSrc),
    .io_msInfo_12_bits_meta_accessed                     (mshrCtl_msInfo_12_bits_meta_accessed),
    .io_msInfo_12_bits_meta_tagErr                       (mshrCtl_msInfo_12_bits_meta_tagErr),
    .io_msInfo_12_bits_meta_dataErr                      (mshrCtl_msInfo_12_bits_meta_dataErr),
    .io_msInfo_12_bits_metaTag                           (mshrCtl_msInfo_12_bits_metaTag),
    .io_msInfo_12_bits_dirHit                            (mshrCtl_msInfo_12_bits_dirHit),
    .io_msInfo_12_bits_isAcqOrPrefetch                   (mshrCtl_msInfo_12_bits_isAcqOrPrefetch),
    .io_msInfo_12_bits_isPrefetch                        (mshrCtl_msInfo_12_bits_isPrefetch),
    .io_msInfo_12_bits_param                             (mshrCtl_msInfo_12_bits_param),
    .io_msInfo_12_bits_mergeA                            (mshrCtl_msInfo_12_bits_mergeA),
    .io_msInfo_12_bits_w_grantfirst                      (mshrCtl_msInfo_12_bits_w_grantfirst),
    .io_msInfo_12_bits_s_release                         (mshrCtl_msInfo_12_bits_s_release),
    .io_msInfo_12_bits_s_refill                          (mshrCtl_msInfo_12_bits_s_refill),
    .io_msInfo_12_bits_s_cmoresp                         (mshrCtl_msInfo_12_bits_s_cmoresp),
    .io_msInfo_12_bits_s_cmometaw                        (mshrCtl_msInfo_12_bits_s_cmometaw),
    .io_msInfo_12_bits_w_releaseack                      (mshrCtl_msInfo_12_bits_w_releaseack),
    .io_msInfo_12_bits_w_replResp                        (mshrCtl_msInfo_12_bits_w_replResp),
    .io_msInfo_12_bits_w_rprobeacklast                   (mshrCtl_msInfo_12_bits_w_rprobeacklast),
    .io_msInfo_12_bits_replaceData                       (mshrCtl_msInfo_12_bits_replaceData),
    .io_msInfo_12_bits_releaseToClean                    (mshrCtl_msInfo_12_bits_releaseToClean),
    .io_msInfo_13_valid                                  (mshrCtl_msInfo_13_valid),
    .io_msInfo_13_bits_channel                           (mshrCtl_msInfo_13_bits_channel),
    .io_msInfo_13_bits_set                               (mshrCtl_msInfo_13_bits_set),
    .io_msInfo_13_bits_way                               (mshrCtl_msInfo_13_bits_way),
    .io_msInfo_13_bits_reqTag                            (mshrCtl_msInfo_13_bits_reqTag),
    .io_msInfo_13_bits_willFree                          (mshrCtl_msInfo_13_bits_willFree),
    .io_msInfo_13_bits_aliasTask                         (mshrCtl_msInfo_13_bits_aliasTask),
    .io_msInfo_13_bits_needRelease                       (mshrCtl_msInfo_13_bits_needRelease),
    .io_msInfo_13_bits_blockRefill                       (mshrCtl_msInfo_13_bits_blockRefill),
    .io_msInfo_13_bits_meta_dirty                        (mshrCtl_msInfo_13_bits_meta_dirty),
    .io_msInfo_13_bits_meta_state                        (mshrCtl_msInfo_13_bits_meta_state),
    .io_msInfo_13_bits_meta_clients                      (mshrCtl_msInfo_13_bits_meta_clients),
    .io_msInfo_13_bits_meta_alias                        (mshrCtl_msInfo_13_bits_meta_alias),
    .io_msInfo_13_bits_meta_prefetch                     (mshrCtl_msInfo_13_bits_meta_prefetch),
    .io_msInfo_13_bits_meta_prefetchSrc                  (mshrCtl_msInfo_13_bits_meta_prefetchSrc),
    .io_msInfo_13_bits_meta_accessed                     (mshrCtl_msInfo_13_bits_meta_accessed),
    .io_msInfo_13_bits_meta_tagErr                       (mshrCtl_msInfo_13_bits_meta_tagErr),
    .io_msInfo_13_bits_meta_dataErr                      (mshrCtl_msInfo_13_bits_meta_dataErr),
    .io_msInfo_13_bits_metaTag                           (mshrCtl_msInfo_13_bits_metaTag),
    .io_msInfo_13_bits_dirHit                            (mshrCtl_msInfo_13_bits_dirHit),
    .io_msInfo_13_bits_isAcqOrPrefetch                   (mshrCtl_msInfo_13_bits_isAcqOrPrefetch),
    .io_msInfo_13_bits_isPrefetch                        (mshrCtl_msInfo_13_bits_isPrefetch),
    .io_msInfo_13_bits_param                             (mshrCtl_msInfo_13_bits_param),
    .io_msInfo_13_bits_mergeA                            (mshrCtl_msInfo_13_bits_mergeA),
    .io_msInfo_13_bits_w_grantfirst                      (mshrCtl_msInfo_13_bits_w_grantfirst),
    .io_msInfo_13_bits_s_release                         (mshrCtl_msInfo_13_bits_s_release),
    .io_msInfo_13_bits_s_refill                          (mshrCtl_msInfo_13_bits_s_refill),
    .io_msInfo_13_bits_s_cmoresp                         (mshrCtl_msInfo_13_bits_s_cmoresp),
    .io_msInfo_13_bits_s_cmometaw                        (mshrCtl_msInfo_13_bits_s_cmometaw),
    .io_msInfo_13_bits_w_releaseack                      (mshrCtl_msInfo_13_bits_w_releaseack),
    .io_msInfo_13_bits_w_replResp                        (mshrCtl_msInfo_13_bits_w_replResp),
    .io_msInfo_13_bits_w_rprobeacklast                   (mshrCtl_msInfo_13_bits_w_rprobeacklast),
    .io_msInfo_13_bits_replaceData                       (mshrCtl_msInfo_13_bits_replaceData),
    .io_msInfo_13_bits_releaseToClean                    (mshrCtl_msInfo_13_bits_releaseToClean),
    .io_msInfo_14_valid                                  (mshrCtl_msInfo_14_valid),
    .io_msInfo_14_bits_channel                           (mshrCtl_msInfo_14_bits_channel),
    .io_msInfo_14_bits_set                               (mshrCtl_msInfo_14_bits_set),
    .io_msInfo_14_bits_way                               (mshrCtl_msInfo_14_bits_way),
    .io_msInfo_14_bits_reqTag                            (mshrCtl_msInfo_14_bits_reqTag),
    .io_msInfo_14_bits_willFree                          (mshrCtl_msInfo_14_bits_willFree),
    .io_msInfo_14_bits_aliasTask                         (mshrCtl_msInfo_14_bits_aliasTask),
    .io_msInfo_14_bits_needRelease                       (mshrCtl_msInfo_14_bits_needRelease),
    .io_msInfo_14_bits_blockRefill                       (mshrCtl_msInfo_14_bits_blockRefill),
    .io_msInfo_14_bits_meta_dirty                        (mshrCtl_msInfo_14_bits_meta_dirty),
    .io_msInfo_14_bits_meta_state                        (mshrCtl_msInfo_14_bits_meta_state),
    .io_msInfo_14_bits_meta_clients                      (mshrCtl_msInfo_14_bits_meta_clients),
    .io_msInfo_14_bits_meta_alias                        (mshrCtl_msInfo_14_bits_meta_alias),
    .io_msInfo_14_bits_meta_prefetch                     (mshrCtl_msInfo_14_bits_meta_prefetch),
    .io_msInfo_14_bits_meta_prefetchSrc                  (mshrCtl_msInfo_14_bits_meta_prefetchSrc),
    .io_msInfo_14_bits_meta_accessed                     (mshrCtl_msInfo_14_bits_meta_accessed),
    .io_msInfo_14_bits_meta_tagErr                       (mshrCtl_msInfo_14_bits_meta_tagErr),
    .io_msInfo_14_bits_meta_dataErr                      (mshrCtl_msInfo_14_bits_meta_dataErr),
    .io_msInfo_14_bits_metaTag                           (mshrCtl_msInfo_14_bits_metaTag),
    .io_msInfo_14_bits_dirHit                            (mshrCtl_msInfo_14_bits_dirHit),
    .io_msInfo_14_bits_isAcqOrPrefetch                   (mshrCtl_msInfo_14_bits_isAcqOrPrefetch),
    .io_msInfo_14_bits_isPrefetch                        (mshrCtl_msInfo_14_bits_isPrefetch),
    .io_msInfo_14_bits_param                             (mshrCtl_msInfo_14_bits_param),
    .io_msInfo_14_bits_mergeA                            (mshrCtl_msInfo_14_bits_mergeA),
    .io_msInfo_14_bits_w_grantfirst                      (mshrCtl_msInfo_14_bits_w_grantfirst),
    .io_msInfo_14_bits_s_release                         (mshrCtl_msInfo_14_bits_s_release),
    .io_msInfo_14_bits_s_refill                          (mshrCtl_msInfo_14_bits_s_refill),
    .io_msInfo_14_bits_s_cmoresp                         (mshrCtl_msInfo_14_bits_s_cmoresp),
    .io_msInfo_14_bits_s_cmometaw                        (mshrCtl_msInfo_14_bits_s_cmometaw),
    .io_msInfo_14_bits_w_releaseack                      (mshrCtl_msInfo_14_bits_w_releaseack),
    .io_msInfo_14_bits_w_replResp                        (mshrCtl_msInfo_14_bits_w_replResp),
    .io_msInfo_14_bits_w_rprobeacklast                   (mshrCtl_msInfo_14_bits_w_rprobeacklast),
    .io_msInfo_14_bits_replaceData                       (mshrCtl_msInfo_14_bits_replaceData),
    .io_msInfo_14_bits_releaseToClean                    (mshrCtl_msInfo_14_bits_releaseToClean),
    .io_msInfo_15_valid                                  (mshrCtl_msInfo_15_valid),
    .io_msInfo_15_bits_channel                           (mshrCtl_msInfo_15_bits_channel),
    .io_msInfo_15_bits_set                               (mshrCtl_msInfo_15_bits_set),
    .io_msInfo_15_bits_way                               (mshrCtl_msInfo_15_bits_way),
    .io_msInfo_15_bits_reqTag                            (mshrCtl_msInfo_15_bits_reqTag),
    .io_msInfo_15_bits_willFree                          (mshrCtl_msInfo_15_bits_willFree),
    .io_msInfo_15_bits_aliasTask                         (mshrCtl_msInfo_15_bits_aliasTask),
    .io_msInfo_15_bits_needRelease                       (mshrCtl_msInfo_15_bits_needRelease),
    .io_msInfo_15_bits_blockRefill                       (mshrCtl_msInfo_15_bits_blockRefill),
    .io_msInfo_15_bits_meta_dirty                        (mshrCtl_msInfo_15_bits_meta_dirty),
    .io_msInfo_15_bits_meta_state                        (mshrCtl_msInfo_15_bits_meta_state),
    .io_msInfo_15_bits_meta_clients                      (mshrCtl_msInfo_15_bits_meta_clients),
    .io_msInfo_15_bits_meta_alias                        (mshrCtl_msInfo_15_bits_meta_alias),
    .io_msInfo_15_bits_meta_prefetch                     (mshrCtl_msInfo_15_bits_meta_prefetch),
    .io_msInfo_15_bits_meta_prefetchSrc                  (mshrCtl_msInfo_15_bits_meta_prefetchSrc),
    .io_msInfo_15_bits_meta_accessed                     (mshrCtl_msInfo_15_bits_meta_accessed),
    .io_msInfo_15_bits_meta_tagErr                       (mshrCtl_msInfo_15_bits_meta_tagErr),
    .io_msInfo_15_bits_meta_dataErr                      (mshrCtl_msInfo_15_bits_meta_dataErr),
    .io_msInfo_15_bits_metaTag                           (mshrCtl_msInfo_15_bits_metaTag),
    .io_msInfo_15_bits_dirHit                            (mshrCtl_msInfo_15_bits_dirHit),
    .io_msInfo_15_bits_isAcqOrPrefetch                   (mshrCtl_msInfo_15_bits_isAcqOrPrefetch),
    .io_msInfo_15_bits_isPrefetch                        (mshrCtl_msInfo_15_bits_isPrefetch),
    .io_msInfo_15_bits_param                             (mshrCtl_msInfo_15_bits_param),
    .io_msInfo_15_bits_mergeA                            (mshrCtl_msInfo_15_bits_mergeA),
    .io_msInfo_15_bits_w_grantfirst                      (mshrCtl_msInfo_15_bits_w_grantfirst),
    .io_msInfo_15_bits_s_release                         (mshrCtl_msInfo_15_bits_s_release),
    .io_msInfo_15_bits_s_refill                          (mshrCtl_msInfo_15_bits_s_refill),
    .io_msInfo_15_bits_s_cmoresp                         (mshrCtl_msInfo_15_bits_s_cmoresp),
    .io_msInfo_15_bits_s_cmometaw                        (mshrCtl_msInfo_15_bits_s_cmometaw),
    .io_msInfo_15_bits_w_releaseack                      (mshrCtl_msInfo_15_bits_w_releaseack),
    .io_msInfo_15_bits_w_replResp                        (mshrCtl_msInfo_15_bits_w_replResp),
    .io_msInfo_15_bits_w_rprobeacklast                   (mshrCtl_msInfo_15_bits_w_rprobeacklast),
    .io_msInfo_15_bits_replaceData                       (mshrCtl_msInfo_15_bits_replaceData),
    .io_msInfo_15_bits_releaseToClean                    (mshrCtl_msInfo_15_bits_releaseToClean)
  );

  // MainPipe：s2-s5 主流水，拿目录结果做决策：直接回应 / 分配 MSHR / 写目录与数据阵列
  MainPipe_1 mainPipe (
    .clock                                                              (clock),
    .reset                                                              (reset),
    .io_taskFromArb_s2_valid                                            (reqArb_taskToPipe_s2_valid),
    .io_taskFromArb_s2_bits_channel                                     (reqArb_taskToPipe_s2_bits_channel),
    .io_taskFromArb_s2_bits_txChannel                                   (reqArb_taskToPipe_s2_bits_txChannel),
    .io_taskFromArb_s2_bits_set                                         (reqArb_taskToPipe_s2_bits_set),
    .io_taskFromArb_s2_bits_tag                                         (reqArb_taskToPipe_s2_bits_tag),
    .io_taskFromArb_s2_bits_off                                         (reqArb_taskToPipe_s2_bits_off),
    .io_taskFromArb_s2_bits_alias                                       (reqArb_taskToPipe_s2_bits_alias),
    .io_taskFromArb_s2_bits_vaddr                                       (reqArb_taskToPipe_s2_bits_vaddr),
    .io_taskFromArb_s2_bits_isKeyword                                   (reqArb_taskToPipe_s2_bits_isKeyword),
    .io_taskFromArb_s2_bits_opcode                                      (reqArb_taskToPipe_s2_bits_opcode),
    .io_taskFromArb_s2_bits_param                                       (reqArb_taskToPipe_s2_bits_param),
    .io_taskFromArb_s2_bits_size                                        (reqArb_taskToPipe_s2_bits_size),
    .io_taskFromArb_s2_bits_sourceId                                    (reqArb_taskToPipe_s2_bits_sourceId),
    .io_taskFromArb_s2_bits_bufIdx                                      (reqArb_taskToPipe_s2_bits_bufIdx),
    .io_taskFromArb_s2_bits_needProbeAckData                            (reqArb_taskToPipe_s2_bits_needProbeAckData),
    .io_taskFromArb_s2_bits_denied                                      (reqArb_taskToPipe_s2_bits_denied),
    .io_taskFromArb_s2_bits_corrupt                                     (reqArb_taskToPipe_s2_bits_corrupt),
    .io_taskFromArb_s2_bits_mshrTask                                    (reqArb_taskToPipe_s2_bits_mshrTask),
    .io_taskFromArb_s2_bits_mshrId                                      (reqArb_taskToPipe_s2_bits_mshrId),
    .io_taskFromArb_s2_bits_aliasTask                                   (reqArb_taskToPipe_s2_bits_aliasTask),
    .io_taskFromArb_s2_bits_useProbeData                                (reqArb_taskToPipe_s2_bits_useProbeData),
    .io_taskFromArb_s2_bits_mshrRetry                                   (reqArb_taskToPipe_s2_bits_mshrRetry),
    .io_taskFromArb_s2_bits_readProbeDataDown                           (reqArb_taskToPipe_s2_bits_readProbeDataDown),
    .io_taskFromArb_s2_bits_fromL2pft                                   (reqArb_taskToPipe_s2_bits_fromL2pft),
    .io_taskFromArb_s2_bits_needHint                                    (reqArb_taskToPipe_s2_bits_needHint),
    .io_taskFromArb_s2_bits_dirty                                       (reqArb_taskToPipe_s2_bits_dirty),
    .io_taskFromArb_s2_bits_way                                         (reqArb_taskToPipe_s2_bits_way),
    .io_taskFromArb_s2_bits_meta_dirty                                  (reqArb_taskToPipe_s2_bits_meta_dirty),
    .io_taskFromArb_s2_bits_meta_state                                  (reqArb_taskToPipe_s2_bits_meta_state),
    .io_taskFromArb_s2_bits_meta_clients                                (reqArb_taskToPipe_s2_bits_meta_clients),
    .io_taskFromArb_s2_bits_meta_alias                                  (reqArb_taskToPipe_s2_bits_meta_alias),
    .io_taskFromArb_s2_bits_meta_prefetch                               (reqArb_taskToPipe_s2_bits_meta_prefetch),
    .io_taskFromArb_s2_bits_meta_prefetchSrc                            (reqArb_taskToPipe_s2_bits_meta_prefetchSrc),
    .io_taskFromArb_s2_bits_meta_accessed                               (reqArb_taskToPipe_s2_bits_meta_accessed),
    .io_taskFromArb_s2_bits_meta_tagErr                                 (reqArb_taskToPipe_s2_bits_meta_tagErr),
    .io_taskFromArb_s2_bits_meta_dataErr                                (reqArb_taskToPipe_s2_bits_meta_dataErr),
    .io_taskFromArb_s2_bits_metaWen                                     (reqArb_taskToPipe_s2_bits_metaWen),
    .io_taskFromArb_s2_bits_tagWen                                      (reqArb_taskToPipe_s2_bits_tagWen),
    .io_taskFromArb_s2_bits_dsWen                                       (reqArb_taskToPipe_s2_bits_dsWen),
    .io_taskFromArb_s2_bits_wayMask                                     (reqArb_taskToPipe_s2_bits_wayMask),
    .io_taskFromArb_s2_bits_replTask                                    (reqArb_taskToPipe_s2_bits_replTask),
    .io_taskFromArb_s2_bits_cmoTask                                     (reqArb_taskToPipe_s2_bits_cmoTask),
    .io_taskFromArb_s2_bits_cmoAll                                      (reqArb_taskToPipe_s2_bits_cmoAll),
    .io_taskFromArb_s2_bits_reqSource                                   (reqArb_taskToPipe_s2_bits_reqSource),
    .io_taskFromArb_s2_bits_mergeA                                      (reqArb_taskToPipe_s2_bits_mergeA),
    .io_taskFromArb_s2_bits_aMergeTask_off                              (reqArb_taskToPipe_s2_bits_aMergeTask_off),
    .io_taskFromArb_s2_bits_aMergeTask_alias                            (reqArb_taskToPipe_s2_bits_aMergeTask_alias),
    .io_taskFromArb_s2_bits_aMergeTask_vaddr                            (reqArb_taskToPipe_s2_bits_aMergeTask_vaddr),
    .io_taskFromArb_s2_bits_aMergeTask_isKeyword                        (reqArb_taskToPipe_s2_bits_aMergeTask_isKeyword),
    .io_taskFromArb_s2_bits_aMergeTask_opcode                           (reqArb_taskToPipe_s2_bits_aMergeTask_opcode),
    .io_taskFromArb_s2_bits_aMergeTask_param                            (reqArb_taskToPipe_s2_bits_aMergeTask_param),
    .io_taskFromArb_s2_bits_aMergeTask_sourceId                         (reqArb_taskToPipe_s2_bits_aMergeTask_sourceId),
    .io_taskFromArb_s2_bits_aMergeTask_meta_dirty                       (reqArb_taskToPipe_s2_bits_aMergeTask_meta_dirty),
    .io_taskFromArb_s2_bits_aMergeTask_meta_state                       (reqArb_taskToPipe_s2_bits_aMergeTask_meta_state),
    .io_taskFromArb_s2_bits_aMergeTask_meta_clients                     (reqArb_taskToPipe_s2_bits_aMergeTask_meta_clients),
    .io_taskFromArb_s2_bits_aMergeTask_meta_alias                       (reqArb_taskToPipe_s2_bits_aMergeTask_meta_alias),
    .io_taskFromArb_s2_bits_aMergeTask_meta_prefetch                    (reqArb_taskToPipe_s2_bits_aMergeTask_meta_prefetch),
    .io_taskFromArb_s2_bits_aMergeTask_meta_prefetchSrc                 (reqArb_taskToPipe_s2_bits_aMergeTask_meta_prefetchSrc),
    .io_taskFromArb_s2_bits_aMergeTask_meta_accessed                    (reqArb_taskToPipe_s2_bits_aMergeTask_meta_accessed),
    .io_taskFromArb_s2_bits_aMergeTask_meta_tagErr                      (reqArb_taskToPipe_s2_bits_aMergeTask_meta_tagErr),
    .io_taskFromArb_s2_bits_aMergeTask_meta_dataErr                     (reqArb_taskToPipe_s2_bits_aMergeTask_meta_dataErr),
    .io_taskFromArb_s2_bits_snpHitRelease                               (reqArb_taskToPipe_s2_bits_snpHitRelease),
    .io_taskFromArb_s2_bits_snpHitReleaseToInval                        (reqArb_taskToPipe_s2_bits_snpHitReleaseToInval),
    .io_taskFromArb_s2_bits_snpHitReleaseToClean                        (reqArb_taskToPipe_s2_bits_snpHitReleaseToClean),
    .io_taskFromArb_s2_bits_snpHitReleaseWithData                       (reqArb_taskToPipe_s2_bits_snpHitReleaseWithData),
    .io_taskFromArb_s2_bits_snpHitReleaseIdx                            (reqArb_taskToPipe_s2_bits_snpHitReleaseIdx),
    .io_taskFromArb_s2_bits_snpHitReleaseMeta_dirty                     (reqArb_taskToPipe_s2_bits_snpHitReleaseMeta_dirty),
    .io_taskFromArb_s2_bits_snpHitReleaseMeta_state                     (reqArb_taskToPipe_s2_bits_snpHitReleaseMeta_state),
    .io_taskFromArb_s2_bits_snpHitReleaseMeta_clients                   (reqArb_taskToPipe_s2_bits_snpHitReleaseMeta_clients),
    .io_taskFromArb_s2_bits_snpHitReleaseMeta_alias                     (reqArb_taskToPipe_s2_bits_snpHitReleaseMeta_alias),
    .io_taskFromArb_s2_bits_snpHitReleaseMeta_prefetch                  (reqArb_taskToPipe_s2_bits_snpHitReleaseMeta_prefetch),
    .io_taskFromArb_s2_bits_snpHitReleaseMeta_prefetchSrc               (reqArb_taskToPipe_s2_bits_snpHitReleaseMeta_prefetchSrc),
    .io_taskFromArb_s2_bits_snpHitReleaseMeta_accessed                  (reqArb_taskToPipe_s2_bits_snpHitReleaseMeta_accessed),
    .io_taskFromArb_s2_bits_snpHitReleaseMeta_tagErr                    (reqArb_taskToPipe_s2_bits_snpHitReleaseMeta_tagErr),
    .io_taskFromArb_s2_bits_snpHitReleaseMeta_dataErr                   (reqArb_taskToPipe_s2_bits_snpHitReleaseMeta_dataErr),
    .io_taskFromArb_s2_bits_tgtID                                       (reqArb_taskToPipe_s2_bits_tgtID),
    .io_taskFromArb_s2_bits_srcID                                       (reqArb_taskToPipe_s2_bits_srcID),
    .io_taskFromArb_s2_bits_txnID                                       (reqArb_taskToPipe_s2_bits_txnID),
    .io_taskFromArb_s2_bits_homeNID                                     (reqArb_taskToPipe_s2_bits_homeNID),
    .io_taskFromArb_s2_bits_dbID                                        (reqArb_taskToPipe_s2_bits_dbID),
    .io_taskFromArb_s2_bits_fwdNID                                      (reqArb_taskToPipe_s2_bits_fwdNID),
    .io_taskFromArb_s2_bits_fwdTxnID                                    (reqArb_taskToPipe_s2_bits_fwdTxnID),
    .io_taskFromArb_s2_bits_chiOpcode                                   (reqArb_taskToPipe_s2_bits_chiOpcode),
    .io_taskFromArb_s2_bits_resp                                        (reqArb_taskToPipe_s2_bits_resp),
    .io_taskFromArb_s2_bits_fwdState                                    (reqArb_taskToPipe_s2_bits_fwdState),
    .io_taskFromArb_s2_bits_pCrdType                                    (reqArb_taskToPipe_s2_bits_pCrdType),
    .io_taskFromArb_s2_bits_retToSrc                                    (reqArb_taskToPipe_s2_bits_retToSrc),
    .io_taskFromArb_s2_bits_likelyshared                                (reqArb_taskToPipe_s2_bits_likelyshared),
    .io_taskFromArb_s2_bits_expCompAck                                  (reqArb_taskToPipe_s2_bits_expCompAck),
    .io_taskFromArb_s2_bits_allowRetry                                  (reqArb_taskToPipe_s2_bits_allowRetry),
    .io_taskFromArb_s2_bits_memAttr_allocate                            (reqArb_taskToPipe_s2_bits_memAttr_allocate),
    .io_taskFromArb_s2_bits_memAttr_cacheable                           (reqArb_taskToPipe_s2_bits_memAttr_cacheable),
    .io_taskFromArb_s2_bits_memAttr_device                              (reqArb_taskToPipe_s2_bits_memAttr_device),
    .io_taskFromArb_s2_bits_memAttr_ewa                                 (reqArb_taskToPipe_s2_bits_memAttr_ewa),
    .io_taskFromArb_s2_bits_traceTag                                    (reqArb_taskToPipe_s2_bits_traceTag),
    .io_taskInfo_s1_valid                                               (reqArb_taskInfo_s1_valid),
    .io_taskInfo_s1_bits_channel                                        (reqArb_taskInfo_s1_bits_channel),
    .io_taskInfo_s1_bits_isKeyword                                      (reqArb_taskInfo_s1_bits_isKeyword),
    .io_taskInfo_s1_bits_opcode                                         (reqArb_taskInfo_s1_bits_opcode),
    .io_taskInfo_s1_bits_sourceId                                       (reqArb_taskInfo_s1_bits_sourceId),
    .io_taskInfo_s1_bits_mshrTask                                       (reqArb_taskInfo_s1_bits_mshrTask),
    .io_taskInfo_s1_bits_mergeA                                         (reqArb_taskInfo_s1_bits_mergeA),
    .io_taskInfo_s1_bits_aMergeTask_isKeyword                           (reqArb_taskInfo_s1_bits_aMergeTask_isKeyword),
    .io_taskInfo_s1_bits_aMergeTask_opcode                              (reqArb_taskInfo_s1_bits_aMergeTask_opcode),
    .io_taskInfo_s1_bits_aMergeTask_sourceId                            (reqArb_taskInfo_s1_bits_aMergeTask_sourceId),
    .io_fromReqArb_status_s1_tags_1                                     (reqArb_status_s1_tags_1),
    .io_fromReqArb_status_s1_sets_0                                     (reqArb_status_s1_sets_0),
    .io_fromReqArb_status_s1_sets_1                                     (reqArb_status_s1_sets_1),
    .io_fromReqArb_status_s1_sets_2                                     (reqArb_status_s1_sets_2),
    .io_fromReqArb_status_s1_sets_3                                     (reqArb_status_s1_sets_3),
    .io_toReqArb_blockG_s1                                              (mainPipe_toReqArb_blockG_s1),
    .io_toReqArb_blockB_s1                                              (mainPipe_toReqArb_blockB_s1),
    .io_toReqArb_blockC_s1                                              (mainPipe_toReqArb_blockC_s1),
    .io_toReqBuf_0                                                      (mainPipe_toReqBuf_0),
    .io_toReqBuf_1                                                      (mainPipe_toReqBuf_1),
    .io_status_vec_toD_0_valid                                          (mainPipe_status_vec_toD_0_valid),
    .io_status_vec_toD_0_bits_channel                                   (mainPipe_status_vec_toD_0_bits_channel),
    .io_status_vec_toD_1_valid                                          (mainPipe_status_vec_toD_1_valid),
    .io_status_vec_toD_1_bits_channel                                   (mainPipe_status_vec_toD_1_bits_channel),
    .io_status_vec_toD_2_valid                                          (mainPipe_status_vec_toD_2_valid),
    .io_status_vec_toD_2_bits_channel                                   (mainPipe_status_vec_toD_2_bits_channel),
    .io_status_vec_toTX_0_valid                                         (mainPipe_status_vec_toTX_0_valid),
    .io_status_vec_toTX_0_bits_channel                                  (mainPipe_status_vec_toTX_0_bits_channel),
    .io_status_vec_toTX_0_bits_txChannel                                (mainPipe_status_vec_toTX_0_bits_txChannel),
    .io_status_vec_toTX_0_bits_mshrTask                                 (mainPipe_status_vec_toTX_0_bits_mshrTask),
    .io_status_vec_toTX_1_valid                                         (mainPipe_status_vec_toTX_1_valid),
    .io_status_vec_toTX_1_bits_channel                                  (mainPipe_status_vec_toTX_1_bits_channel),
    .io_status_vec_toTX_1_bits_txChannel                                (mainPipe_status_vec_toTX_1_bits_txChannel),
    .io_status_vec_toTX_1_bits_mshrTask                                 (mainPipe_status_vec_toTX_1_bits_mshrTask),
    .io_status_vec_toTX_2_valid                                         (mainPipe_status_vec_toTX_2_valid),
    .io_status_vec_toTX_2_bits_channel                                  (mainPipe_status_vec_toTX_2_bits_channel),
    .io_status_vec_toTX_2_bits_txChannel                                (mainPipe_status_vec_toTX_2_bits_txChannel),
    .io_status_vec_toTX_2_bits_mshrTask                                 (mainPipe_status_vec_toTX_2_bits_mshrTask),
    .io_dirResp_s3_valid                                                (dir_resp_valid),
    .io_dirResp_s3_bits_hit                                             (dir_resp_bits_hit),
    .io_dirResp_s3_bits_tag                                             (dir_resp_bits_tag),
    .io_dirResp_s3_bits_set                                             (dir_resp_bits_set),
    .io_dirResp_s3_bits_way                                             (dir_resp_bits_way),
    .io_dirResp_s3_bits_meta_dirty                                      (dir_resp_bits_meta_dirty),
    .io_dirResp_s3_bits_meta_state                                      (dir_resp_bits_meta_state),
    .io_dirResp_s3_bits_meta_clients                                    (dir_resp_bits_meta_clients),
    .io_dirResp_s3_bits_meta_alias                                      (dir_resp_bits_meta_alias),
    .io_dirResp_s3_bits_meta_prefetch                                   (dir_resp_bits_meta_prefetch),
    .io_dirResp_s3_bits_meta_prefetchSrc                                (dir_resp_bits_meta_prefetchSrc),
    .io_dirResp_s3_bits_meta_accessed                                   (dir_resp_bits_meta_accessed),
    .io_dirResp_s3_bits_meta_tagErr                                     (dir_resp_bits_meta_tagErr),
    .io_dirResp_s3_bits_meta_dataErr                                    (dir_resp_bits_meta_dataErr),
    .io_dirResp_s3_bits_error                                           (dir_resp_bits_error),
    .io_replResp_valid                                                  (dir_replResp_valid),
    .io_replResp_bits_way                                               (dir_replResp_bits_way),
    .io_replResp_bits_meta_state                                        (dir_replResp_bits_meta_state),
    .io_replResp_bits_retry                                             (dir_replResp_bits_retry),
    .io_toMSHRCtl_mshr_alloc_s3_valid                                   (mainPipe_toMSHRCtl_mshr_alloc_s3_valid),
    .io_toMSHRCtl_mshr_alloc_s3_bits_dirResult_hit                      (mainPipe_toMSHRCtl_mshr_alloc_s3_bits_dirResult_hit),
    .io_toMSHRCtl_mshr_alloc_s3_bits_dirResult_tag                      (mainPipe_toMSHRCtl_mshr_alloc_s3_bits_dirResult_tag),
    .io_toMSHRCtl_mshr_alloc_s3_bits_dirResult_set                      (mainPipe_toMSHRCtl_mshr_alloc_s3_bits_dirResult_set),
    .io_toMSHRCtl_mshr_alloc_s3_bits_dirResult_way                      (mainPipe_toMSHRCtl_mshr_alloc_s3_bits_dirResult_way),
    .io_toMSHRCtl_mshr_alloc_s3_bits_dirResult_meta_dirty               (mainPipe_toMSHRCtl_mshr_alloc_s3_bits_dirResult_meta_dirty),
    .io_toMSHRCtl_mshr_alloc_s3_bits_dirResult_meta_state               (mainPipe_toMSHRCtl_mshr_alloc_s3_bits_dirResult_meta_state),
    .io_toMSHRCtl_mshr_alloc_s3_bits_dirResult_meta_clients             (mainPipe_toMSHRCtl_mshr_alloc_s3_bits_dirResult_meta_clients),
    .io_toMSHRCtl_mshr_alloc_s3_bits_dirResult_meta_alias               (mainPipe_toMSHRCtl_mshr_alloc_s3_bits_dirResult_meta_alias),
    .io_toMSHRCtl_mshr_alloc_s3_bits_dirResult_meta_prefetch            (mainPipe_toMSHRCtl_mshr_alloc_s3_bits_dirResult_meta_prefetch),
    .io_toMSHRCtl_mshr_alloc_s3_bits_dirResult_meta_prefetchSrc         (mainPipe_toMSHRCtl_mshr_alloc_s3_bits_dirResult_meta_prefetchSrc),
    .io_toMSHRCtl_mshr_alloc_s3_bits_dirResult_meta_accessed            (mainPipe_toMSHRCtl_mshr_alloc_s3_bits_dirResult_meta_accessed),
    .io_toMSHRCtl_mshr_alloc_s3_bits_dirResult_meta_tagErr              (mainPipe_toMSHRCtl_mshr_alloc_s3_bits_dirResult_meta_tagErr),
    .io_toMSHRCtl_mshr_alloc_s3_bits_dirResult_meta_dataErr             (mainPipe_toMSHRCtl_mshr_alloc_s3_bits_dirResult_meta_dataErr),
    .io_toMSHRCtl_mshr_alloc_s3_bits_dirResult_error                    (mainPipe_toMSHRCtl_mshr_alloc_s3_bits_dirResult_error),
    .io_toMSHRCtl_mshr_alloc_s3_bits_state_s_acquire                    (mainPipe_toMSHRCtl_mshr_alloc_s3_bits_state_s_acquire),
    .io_toMSHRCtl_mshr_alloc_s3_bits_state_s_rprobe                     (mainPipe_toMSHRCtl_mshr_alloc_s3_bits_state_s_rprobe),
    .io_toMSHRCtl_mshr_alloc_s3_bits_state_s_pprobe                     (mainPipe_toMSHRCtl_mshr_alloc_s3_bits_state_s_pprobe),
    .io_toMSHRCtl_mshr_alloc_s3_bits_state_s_release                    (mainPipe_toMSHRCtl_mshr_alloc_s3_bits_state_s_release),
    .io_toMSHRCtl_mshr_alloc_s3_bits_state_s_probeack                   (mainPipe_toMSHRCtl_mshr_alloc_s3_bits_state_s_probeack),
    .io_toMSHRCtl_mshr_alloc_s3_bits_state_s_refill                     (mainPipe_toMSHRCtl_mshr_alloc_s3_bits_state_s_refill),
    .io_toMSHRCtl_mshr_alloc_s3_bits_state_s_cmoresp                    (mainPipe_toMSHRCtl_mshr_alloc_s3_bits_state_s_cmoresp),
    .io_toMSHRCtl_mshr_alloc_s3_bits_state_w_rprobeackfirst             (mainPipe_toMSHRCtl_mshr_alloc_s3_bits_state_w_rprobeackfirst),
    .io_toMSHRCtl_mshr_alloc_s3_bits_state_w_rprobeacklast              (mainPipe_toMSHRCtl_mshr_alloc_s3_bits_state_w_rprobeacklast),
    .io_toMSHRCtl_mshr_alloc_s3_bits_state_w_pprobeackfirst             (mainPipe_toMSHRCtl_mshr_alloc_s3_bits_state_w_pprobeackfirst),
    .io_toMSHRCtl_mshr_alloc_s3_bits_state_w_pprobeacklast              (mainPipe_toMSHRCtl_mshr_alloc_s3_bits_state_w_pprobeacklast),
    .io_toMSHRCtl_mshr_alloc_s3_bits_state_w_grantfirst                 (mainPipe_toMSHRCtl_mshr_alloc_s3_bits_state_w_grantfirst),
    .io_toMSHRCtl_mshr_alloc_s3_bits_state_w_grantlast                  (mainPipe_toMSHRCtl_mshr_alloc_s3_bits_state_w_grantlast),
    .io_toMSHRCtl_mshr_alloc_s3_bits_state_w_grant                      (mainPipe_toMSHRCtl_mshr_alloc_s3_bits_state_w_grant),
    .io_toMSHRCtl_mshr_alloc_s3_bits_state_w_releaseack                 (mainPipe_toMSHRCtl_mshr_alloc_s3_bits_state_w_releaseack),
    .io_toMSHRCtl_mshr_alloc_s3_bits_state_w_replResp                   (mainPipe_toMSHRCtl_mshr_alloc_s3_bits_state_w_replResp),
    .io_toMSHRCtl_mshr_alloc_s3_bits_state_s_rcompack                   (mainPipe_toMSHRCtl_mshr_alloc_s3_bits_state_s_rcompack),
    .io_toMSHRCtl_mshr_alloc_s3_bits_state_s_dct                        (mainPipe_toMSHRCtl_mshr_alloc_s3_bits_state_s_dct),
    .io_toMSHRCtl_mshr_alloc_s3_bits_task_channel                       (mainPipe_toMSHRCtl_mshr_alloc_s3_bits_task_channel),
    .io_toMSHRCtl_mshr_alloc_s3_bits_task_set                           (mainPipe_toMSHRCtl_mshr_alloc_s3_bits_task_set),
    .io_toMSHRCtl_mshr_alloc_s3_bits_task_tag                           (mainPipe_toMSHRCtl_mshr_alloc_s3_bits_task_tag),
    .io_toMSHRCtl_mshr_alloc_s3_bits_task_off                           (mainPipe_toMSHRCtl_mshr_alloc_s3_bits_task_off),
    .io_toMSHRCtl_mshr_alloc_s3_bits_task_alias                         (mainPipe_toMSHRCtl_mshr_alloc_s3_bits_task_alias),
    .io_toMSHRCtl_mshr_alloc_s3_bits_task_isKeyword                     (mainPipe_toMSHRCtl_mshr_alloc_s3_bits_task_isKeyword),
    .io_toMSHRCtl_mshr_alloc_s3_bits_task_opcode                        (mainPipe_toMSHRCtl_mshr_alloc_s3_bits_task_opcode),
    .io_toMSHRCtl_mshr_alloc_s3_bits_task_param                         (mainPipe_toMSHRCtl_mshr_alloc_s3_bits_task_param),
    .io_toMSHRCtl_mshr_alloc_s3_bits_task_sourceId                      (mainPipe_toMSHRCtl_mshr_alloc_s3_bits_task_sourceId),
    .io_toMSHRCtl_mshr_alloc_s3_bits_task_denied                        (mainPipe_toMSHRCtl_mshr_alloc_s3_bits_task_denied),
    .io_toMSHRCtl_mshr_alloc_s3_bits_task_corrupt                       (mainPipe_toMSHRCtl_mshr_alloc_s3_bits_task_corrupt),
    .io_toMSHRCtl_mshr_alloc_s3_bits_task_aliasTask                     (mainPipe_toMSHRCtl_mshr_alloc_s3_bits_task_aliasTask),
    .io_toMSHRCtl_mshr_alloc_s3_bits_task_fromL2pft                     (mainPipe_toMSHRCtl_mshr_alloc_s3_bits_task_fromL2pft),
    .io_toMSHRCtl_mshr_alloc_s3_bits_task_reqSource                     (mainPipe_toMSHRCtl_mshr_alloc_s3_bits_task_reqSource),
    .io_toMSHRCtl_mshr_alloc_s3_bits_task_snpHitRelease                 (mainPipe_toMSHRCtl_mshr_alloc_s3_bits_task_snpHitRelease),
    .io_toMSHRCtl_mshr_alloc_s3_bits_task_snpHitReleaseToInval          (mainPipe_toMSHRCtl_mshr_alloc_s3_bits_task_snpHitReleaseToInval),
    .io_toMSHRCtl_mshr_alloc_s3_bits_task_snpHitReleaseToClean          (mainPipe_toMSHRCtl_mshr_alloc_s3_bits_task_snpHitReleaseToClean),
    .io_toMSHRCtl_mshr_alloc_s3_bits_task_snpHitReleaseWithData         (mainPipe_toMSHRCtl_mshr_alloc_s3_bits_task_snpHitReleaseWithData),
    .io_toMSHRCtl_mshr_alloc_s3_bits_task_snpHitReleaseIdx              (mainPipe_toMSHRCtl_mshr_alloc_s3_bits_task_snpHitReleaseIdx),
    .io_toMSHRCtl_mshr_alloc_s3_bits_task_snpHitReleaseMeta_dirty       (mainPipe_toMSHRCtl_mshr_alloc_s3_bits_task_snpHitReleaseMeta_dirty),
    .io_toMSHRCtl_mshr_alloc_s3_bits_task_snpHitReleaseMeta_state       (mainPipe_toMSHRCtl_mshr_alloc_s3_bits_task_snpHitReleaseMeta_state),
    .io_toMSHRCtl_mshr_alloc_s3_bits_task_snpHitReleaseMeta_clients     (mainPipe_toMSHRCtl_mshr_alloc_s3_bits_task_snpHitReleaseMeta_clients),
    .io_toMSHRCtl_mshr_alloc_s3_bits_task_snpHitReleaseMeta_alias       (mainPipe_toMSHRCtl_mshr_alloc_s3_bits_task_snpHitReleaseMeta_alias),
    .io_toMSHRCtl_mshr_alloc_s3_bits_task_snpHitReleaseMeta_prefetch    (mainPipe_toMSHRCtl_mshr_alloc_s3_bits_task_snpHitReleaseMeta_prefetch),
    .io_toMSHRCtl_mshr_alloc_s3_bits_task_snpHitReleaseMeta_prefetchSrc (mainPipe_toMSHRCtl_mshr_alloc_s3_bits_task_snpHitReleaseMeta_prefetchSrc),
    .io_toMSHRCtl_mshr_alloc_s3_bits_task_snpHitReleaseMeta_accessed    (mainPipe_toMSHRCtl_mshr_alloc_s3_bits_task_snpHitReleaseMeta_accessed),
    .io_toMSHRCtl_mshr_alloc_s3_bits_task_snpHitReleaseMeta_tagErr      (mainPipe_toMSHRCtl_mshr_alloc_s3_bits_task_snpHitReleaseMeta_tagErr),
    .io_toMSHRCtl_mshr_alloc_s3_bits_task_snpHitReleaseMeta_dataErr     (mainPipe_toMSHRCtl_mshr_alloc_s3_bits_task_snpHitReleaseMeta_dataErr),
    .io_toMSHRCtl_mshr_alloc_s3_bits_task_srcID                         (mainPipe_toMSHRCtl_mshr_alloc_s3_bits_task_srcID),
    .io_toMSHRCtl_mshr_alloc_s3_bits_task_txnID                         (mainPipe_toMSHRCtl_mshr_alloc_s3_bits_task_txnID),
    .io_toMSHRCtl_mshr_alloc_s3_bits_task_fwdNID                        (mainPipe_toMSHRCtl_mshr_alloc_s3_bits_task_fwdNID),
    .io_toMSHRCtl_mshr_alloc_s3_bits_task_fwdTxnID                      (mainPipe_toMSHRCtl_mshr_alloc_s3_bits_task_fwdTxnID),
    .io_toMSHRCtl_mshr_alloc_s3_bits_task_chiOpcode                     (mainPipe_toMSHRCtl_mshr_alloc_s3_bits_task_chiOpcode),
    .io_toMSHRCtl_mshr_alloc_s3_bits_task_retToSrc                      (mainPipe_toMSHRCtl_mshr_alloc_s3_bits_task_retToSrc),
    .io_toMSHRCtl_mshr_alloc_s3_bits_task_traceTag                      (mainPipe_toMSHRCtl_mshr_alloc_s3_bits_task_traceTag),
    .io_fromMSHRCtl_mshr_alloc_ptr                                      (mshrCtl_toMainPipe_mshr_alloc_ptr),
    .io_bufResp_data_0                                                  (sinkC_bufResp_data_0),
    .io_bufResp_data_1                                                  (sinkC_bufResp_data_1),
    .io_refillBufResp_s3_bits_data                                      (refillBuf_resp_data_data),
    .io_releaseBufResp_s3_valid                                         (mainPipe_io_releaseBufResp_s3_valid_REG),
    .io_releaseBufResp_s3_bits_data                                     (releaseBuf_resp_data_data),
    .io_toDS_en_s3                                                      (mainPipe_toDS_en_s3),
    .io_toDS_req_s3_valid                                               (mainPipe_toDS_req_s3_valid),
    .io_toDS_req_s3_bits_way                                            (mainPipe_toDS_req_s3_bits_way),
    .io_toDS_req_s3_bits_set                                            (mainPipe_toDS_req_s3_bits_set),
    .io_toDS_req_s3_bits_wen                                            (mainPipe_toDS_req_s3_bits_wen),
    .io_toDS_rdata_s5_data                                              (ds_rdata_data),
    .io_toDS_wdata_s3_data                                              (mainPipe_toDS_wdata_s3_data),
    .io_toDS_error_s5                                                   (ds_error),
    .io_toSourceD_valid                                                 (mainPipe_toSourceD_valid),
    .io_toSourceD_bits_task_channel                                     (mainPipe_toSourceD_bits_task_channel),
    .io_toSourceD_bits_task_txChannel                                   (mainPipe_toSourceD_bits_task_txChannel),
    .io_toSourceD_bits_task_set                                         (mainPipe_toSourceD_bits_task_set),
    .io_toSourceD_bits_task_tag                                         (mainPipe_toSourceD_bits_task_tag),
    .io_toSourceD_bits_task_off                                         (mainPipe_toSourceD_bits_task_off),
    .io_toSourceD_bits_task_alias                                       (mainPipe_toSourceD_bits_task_alias),
    .io_toSourceD_bits_task_vaddr                                       (mainPipe_toSourceD_bits_task_vaddr),
    .io_toSourceD_bits_task_isKeyword                                   (mainPipe_toSourceD_bits_task_isKeyword),
    .io_toSourceD_bits_task_opcode                                      (mainPipe_toSourceD_bits_task_opcode),
    .io_toSourceD_bits_task_param                                       (mainPipe_toSourceD_bits_task_param),
    .io_toSourceD_bits_task_size                                        (mainPipe_toSourceD_bits_task_size),
    .io_toSourceD_bits_task_sourceId                                    (mainPipe_toSourceD_bits_task_sourceId),
    .io_toSourceD_bits_task_bufIdx                                      (mainPipe_toSourceD_bits_task_bufIdx),
    .io_toSourceD_bits_task_needProbeAckData                            (mainPipe_toSourceD_bits_task_needProbeAckData),
    .io_toSourceD_bits_task_denied                                      (mainPipe_toSourceD_bits_task_denied),
    .io_toSourceD_bits_task_corrupt                                     (mainPipe_toSourceD_bits_task_corrupt),
    .io_toSourceD_bits_task_mshrTask                                    (mainPipe_toSourceD_bits_task_mshrTask),
    .io_toSourceD_bits_task_mshrId                                      (mainPipe_toSourceD_bits_task_mshrId),
    .io_toSourceD_bits_task_aliasTask                                   (mainPipe_toSourceD_bits_task_aliasTask),
    .io_toSourceD_bits_task_useProbeData                                (mainPipe_toSourceD_bits_task_useProbeData),
    .io_toSourceD_bits_task_mshrRetry                                   (mainPipe_toSourceD_bits_task_mshrRetry),
    .io_toSourceD_bits_task_readProbeDataDown                           (mainPipe_toSourceD_bits_task_readProbeDataDown),
    .io_toSourceD_bits_task_fromL2pft                                   (mainPipe_toSourceD_bits_task_fromL2pft),
    .io_toSourceD_bits_task_needHint                                    (mainPipe_toSourceD_bits_task_needHint),
    .io_toSourceD_bits_task_dirty                                       (mainPipe_toSourceD_bits_task_dirty),
    .io_toSourceD_bits_task_way                                         (mainPipe_toSourceD_bits_task_way),
    .io_toSourceD_bits_task_meta_dirty                                  (mainPipe_toSourceD_bits_task_meta_dirty),
    .io_toSourceD_bits_task_meta_state                                  (mainPipe_toSourceD_bits_task_meta_state),
    .io_toSourceD_bits_task_meta_clients                                (mainPipe_toSourceD_bits_task_meta_clients),
    .io_toSourceD_bits_task_meta_alias                                  (mainPipe_toSourceD_bits_task_meta_alias),
    .io_toSourceD_bits_task_meta_prefetch                               (mainPipe_toSourceD_bits_task_meta_prefetch),
    .io_toSourceD_bits_task_meta_prefetchSrc                            (mainPipe_toSourceD_bits_task_meta_prefetchSrc),
    .io_toSourceD_bits_task_meta_accessed                               (mainPipe_toSourceD_bits_task_meta_accessed),
    .io_toSourceD_bits_task_meta_tagErr                                 (mainPipe_toSourceD_bits_task_meta_tagErr),
    .io_toSourceD_bits_task_meta_dataErr                                (mainPipe_toSourceD_bits_task_meta_dataErr),
    .io_toSourceD_bits_task_metaWen                                     (mainPipe_toSourceD_bits_task_metaWen),
    .io_toSourceD_bits_task_tagWen                                      (mainPipe_toSourceD_bits_task_tagWen),
    .io_toSourceD_bits_task_dsWen                                       (mainPipe_toSourceD_bits_task_dsWen),
    .io_toSourceD_bits_task_wayMask                                     (mainPipe_toSourceD_bits_task_wayMask),
    .io_toSourceD_bits_task_replTask                                    (mainPipe_toSourceD_bits_task_replTask),
    .io_toSourceD_bits_task_cmoTask                                     (mainPipe_toSourceD_bits_task_cmoTask),
    .io_toSourceD_bits_task_cmoAll                                      (mainPipe_toSourceD_bits_task_cmoAll),
    .io_toSourceD_bits_task_reqSource                                   (mainPipe_toSourceD_bits_task_reqSource),
    .io_toSourceD_bits_task_mergeA                                      (mainPipe_toSourceD_bits_task_mergeA),
    .io_toSourceD_bits_task_aMergeTask_off                              (mainPipe_toSourceD_bits_task_aMergeTask_off),
    .io_toSourceD_bits_task_aMergeTask_alias                            (mainPipe_toSourceD_bits_task_aMergeTask_alias),
    .io_toSourceD_bits_task_aMergeTask_vaddr                            (mainPipe_toSourceD_bits_task_aMergeTask_vaddr),
    .io_toSourceD_bits_task_aMergeTask_isKeyword                        (mainPipe_toSourceD_bits_task_aMergeTask_isKeyword),
    .io_toSourceD_bits_task_aMergeTask_opcode                           (mainPipe_toSourceD_bits_task_aMergeTask_opcode),
    .io_toSourceD_bits_task_aMergeTask_param                            (mainPipe_toSourceD_bits_task_aMergeTask_param),
    .io_toSourceD_bits_task_aMergeTask_sourceId                         (mainPipe_toSourceD_bits_task_aMergeTask_sourceId),
    .io_toSourceD_bits_task_aMergeTask_meta_dirty                       (mainPipe_toSourceD_bits_task_aMergeTask_meta_dirty),
    .io_toSourceD_bits_task_aMergeTask_meta_state                       (mainPipe_toSourceD_bits_task_aMergeTask_meta_state),
    .io_toSourceD_bits_task_aMergeTask_meta_clients                     (mainPipe_toSourceD_bits_task_aMergeTask_meta_clients),
    .io_toSourceD_bits_task_aMergeTask_meta_alias                       (mainPipe_toSourceD_bits_task_aMergeTask_meta_alias),
    .io_toSourceD_bits_task_aMergeTask_meta_prefetch                    (mainPipe_toSourceD_bits_task_aMergeTask_meta_prefetch),
    .io_toSourceD_bits_task_aMergeTask_meta_prefetchSrc                 (mainPipe_toSourceD_bits_task_aMergeTask_meta_prefetchSrc),
    .io_toSourceD_bits_task_aMergeTask_meta_accessed                    (mainPipe_toSourceD_bits_task_aMergeTask_meta_accessed),
    .io_toSourceD_bits_task_aMergeTask_meta_tagErr                      (mainPipe_toSourceD_bits_task_aMergeTask_meta_tagErr),
    .io_toSourceD_bits_task_aMergeTask_meta_dataErr                     (mainPipe_toSourceD_bits_task_aMergeTask_meta_dataErr),
    .io_toSourceD_bits_task_snpHitRelease                               (mainPipe_toSourceD_bits_task_snpHitRelease),
    .io_toSourceD_bits_task_snpHitReleaseToInval                        (mainPipe_toSourceD_bits_task_snpHitReleaseToInval),
    .io_toSourceD_bits_task_snpHitReleaseToClean                        (mainPipe_toSourceD_bits_task_snpHitReleaseToClean),
    .io_toSourceD_bits_task_snpHitReleaseWithData                       (mainPipe_toSourceD_bits_task_snpHitReleaseWithData),
    .io_toSourceD_bits_task_snpHitReleaseIdx                            (mainPipe_toSourceD_bits_task_snpHitReleaseIdx),
    .io_toSourceD_bits_task_snpHitReleaseMeta_dirty                     (mainPipe_toSourceD_bits_task_snpHitReleaseMeta_dirty),
    .io_toSourceD_bits_task_snpHitReleaseMeta_state                     (mainPipe_toSourceD_bits_task_snpHitReleaseMeta_state),
    .io_toSourceD_bits_task_snpHitReleaseMeta_clients                   (mainPipe_toSourceD_bits_task_snpHitReleaseMeta_clients),
    .io_toSourceD_bits_task_snpHitReleaseMeta_alias                     (mainPipe_toSourceD_bits_task_snpHitReleaseMeta_alias),
    .io_toSourceD_bits_task_snpHitReleaseMeta_prefetch                  (mainPipe_toSourceD_bits_task_snpHitReleaseMeta_prefetch),
    .io_toSourceD_bits_task_snpHitReleaseMeta_prefetchSrc               (mainPipe_toSourceD_bits_task_snpHitReleaseMeta_prefetchSrc),
    .io_toSourceD_bits_task_snpHitReleaseMeta_accessed                  (mainPipe_toSourceD_bits_task_snpHitReleaseMeta_accessed),
    .io_toSourceD_bits_task_snpHitReleaseMeta_tagErr                    (mainPipe_toSourceD_bits_task_snpHitReleaseMeta_tagErr),
    .io_toSourceD_bits_task_snpHitReleaseMeta_dataErr                   (mainPipe_toSourceD_bits_task_snpHitReleaseMeta_dataErr),
    .io_toSourceD_bits_task_tgtID                                       (mainPipe_toSourceD_bits_task_tgtID),
    .io_toSourceD_bits_task_srcID                                       (mainPipe_toSourceD_bits_task_srcID),
    .io_toSourceD_bits_task_txnID                                       (mainPipe_toSourceD_bits_task_txnID),
    .io_toSourceD_bits_task_homeNID                                     (mainPipe_toSourceD_bits_task_homeNID),
    .io_toSourceD_bits_task_dbID                                        (mainPipe_toSourceD_bits_task_dbID),
    .io_toSourceD_bits_task_fwdNID                                      (mainPipe_toSourceD_bits_task_fwdNID),
    .io_toSourceD_bits_task_fwdTxnID                                    (mainPipe_toSourceD_bits_task_fwdTxnID),
    .io_toSourceD_bits_task_chiOpcode                                   (mainPipe_toSourceD_bits_task_chiOpcode),
    .io_toSourceD_bits_task_resp                                        (mainPipe_toSourceD_bits_task_resp),
    .io_toSourceD_bits_task_fwdState                                    (mainPipe_toSourceD_bits_task_fwdState),
    .io_toSourceD_bits_task_pCrdType                                    (mainPipe_toSourceD_bits_task_pCrdType),
    .io_toSourceD_bits_task_retToSrc                                    (mainPipe_toSourceD_bits_task_retToSrc),
    .io_toSourceD_bits_task_likelyshared                                (mainPipe_toSourceD_bits_task_likelyshared),
    .io_toSourceD_bits_task_expCompAck                                  (mainPipe_toSourceD_bits_task_expCompAck),
    .io_toSourceD_bits_task_allowRetry                                  (mainPipe_toSourceD_bits_task_allowRetry),
    .io_toSourceD_bits_task_memAttr_allocate                            (mainPipe_toSourceD_bits_task_memAttr_allocate),
    .io_toSourceD_bits_task_memAttr_cacheable                           (mainPipe_toSourceD_bits_task_memAttr_cacheable),
    .io_toSourceD_bits_task_memAttr_device                              (mainPipe_toSourceD_bits_task_memAttr_device),
    .io_toSourceD_bits_task_memAttr_ewa                                 (mainPipe_toSourceD_bits_task_memAttr_ewa),
    .io_toSourceD_bits_task_traceTag                                    (mainPipe_toSourceD_bits_task_traceTag),
    .io_toSourceD_bits_data_data                                        (mainPipe_toSourceD_bits_data_data),
    .io_toTXREQ_valid                                                   (mainPipe_toTXREQ_valid),
    .io_toTXREQ_bits_tgtID                                              (mainPipe_toTXREQ_bits_tgtID),
    .io_toTXREQ_bits_srcID                                              (mainPipe_toTXREQ_bits_srcID),
    .io_toTXREQ_bits_txnID                                              (mainPipe_toTXREQ_bits_txnID),
    .io_toTXREQ_bits_opcode                                             (mainPipe_toTXREQ_bits_opcode),
    .io_toTXREQ_bits_addr                                               (mainPipe_toTXREQ_bits_addr),
    .io_toTXREQ_bits_likelyshared                                       (mainPipe_toTXREQ_bits_likelyshared),
    .io_toTXREQ_bits_allowRetry                                         (mainPipe_toTXREQ_bits_allowRetry),
    .io_toTXREQ_bits_pCrdType                                           (mainPipe_toTXREQ_bits_pCrdType),
    .io_toTXREQ_bits_memAttr_allocate                                   (mainPipe_toTXREQ_bits_memAttr_allocate),
    .io_toTXREQ_bits_memAttr_cacheable                                  (mainPipe_toTXREQ_bits_memAttr_cacheable),
    .io_toTXREQ_bits_memAttr_device                                     (mainPipe_toTXREQ_bits_memAttr_device),
    .io_toTXREQ_bits_memAttr_ewa                                        (mainPipe_toTXREQ_bits_memAttr_ewa),
    .io_toTXREQ_bits_expCompAck                                         (mainPipe_toTXREQ_bits_expCompAck),
    .io_toTXRSP_valid                                                   (mainPipe_toTXRSP_valid),
    .io_toTXRSP_bits_txChannel                                          (mainPipe_toTXRSP_bits_txChannel),
    .io_toTXRSP_bits_denied                                             (mainPipe_toTXRSP_bits_denied),
    .io_toTXRSP_bits_tgtID                                              (mainPipe_toTXRSP_bits_tgtID),
    .io_toTXRSP_bits_srcID                                              (mainPipe_toTXRSP_bits_srcID),
    .io_toTXRSP_bits_txnID                                              (mainPipe_toTXRSP_bits_txnID),
    .io_toTXRSP_bits_dbID                                               (mainPipe_toTXRSP_bits_dbID),
    .io_toTXRSP_bits_chiOpcode                                          (mainPipe_toTXRSP_bits_chiOpcode),
    .io_toTXRSP_bits_resp                                               (mainPipe_toTXRSP_bits_resp),
    .io_toTXRSP_bits_fwdState                                           (mainPipe_toTXRSP_bits_fwdState),
    .io_toTXRSP_bits_pCrdType                                           (mainPipe_toTXRSP_bits_pCrdType),
    .io_toTXRSP_bits_traceTag                                           (mainPipe_toTXRSP_bits_traceTag),
    .io_toTXDAT_ready                                                   (txdat_in_ready),
    .io_toTXDAT_valid                                                   (mainPipe_toTXDAT_valid),
    .io_toTXDAT_bits_task_channel                                       (mainPipe_toTXDAT_bits_task_channel),
    .io_toTXDAT_bits_task_txChannel                                     (mainPipe_toTXDAT_bits_task_txChannel),
    .io_toTXDAT_bits_task_set                                           (mainPipe_toTXDAT_bits_task_set),
    .io_toTXDAT_bits_task_tag                                           (mainPipe_toTXDAT_bits_task_tag),
    .io_toTXDAT_bits_task_off                                           (mainPipe_toTXDAT_bits_task_off),
    .io_toTXDAT_bits_task_alias                                         (mainPipe_toTXDAT_bits_task_alias),
    .io_toTXDAT_bits_task_vaddr                                         (mainPipe_toTXDAT_bits_task_vaddr),
    .io_toTXDAT_bits_task_isKeyword                                     (mainPipe_toTXDAT_bits_task_isKeyword),
    .io_toTXDAT_bits_task_opcode                                        (mainPipe_toTXDAT_bits_task_opcode),
    .io_toTXDAT_bits_task_param                                         (mainPipe_toTXDAT_bits_task_param),
    .io_toTXDAT_bits_task_size                                          (mainPipe_toTXDAT_bits_task_size),
    .io_toTXDAT_bits_task_sourceId                                      (mainPipe_toTXDAT_bits_task_sourceId),
    .io_toTXDAT_bits_task_bufIdx                                        (mainPipe_toTXDAT_bits_task_bufIdx),
    .io_toTXDAT_bits_task_needProbeAckData                              (mainPipe_toTXDAT_bits_task_needProbeAckData),
    .io_toTXDAT_bits_task_denied                                        (mainPipe_toTXDAT_bits_task_denied),
    .io_toTXDAT_bits_task_corrupt                                       (mainPipe_toTXDAT_bits_task_corrupt),
    .io_toTXDAT_bits_task_mshrTask                                      (mainPipe_toTXDAT_bits_task_mshrTask),
    .io_toTXDAT_bits_task_mshrId                                        (mainPipe_toTXDAT_bits_task_mshrId),
    .io_toTXDAT_bits_task_aliasTask                                     (mainPipe_toTXDAT_bits_task_aliasTask),
    .io_toTXDAT_bits_task_useProbeData                                  (mainPipe_toTXDAT_bits_task_useProbeData),
    .io_toTXDAT_bits_task_mshrRetry                                     (mainPipe_toTXDAT_bits_task_mshrRetry),
    .io_toTXDAT_bits_task_readProbeDataDown                             (mainPipe_toTXDAT_bits_task_readProbeDataDown),
    .io_toTXDAT_bits_task_fromL2pft                                     (mainPipe_toTXDAT_bits_task_fromL2pft),
    .io_toTXDAT_bits_task_needHint                                      (mainPipe_toTXDAT_bits_task_needHint),
    .io_toTXDAT_bits_task_dirty                                         (mainPipe_toTXDAT_bits_task_dirty),
    .io_toTXDAT_bits_task_way                                           (mainPipe_toTXDAT_bits_task_way),
    .io_toTXDAT_bits_task_meta_dirty                                    (mainPipe_toTXDAT_bits_task_meta_dirty),
    .io_toTXDAT_bits_task_meta_state                                    (mainPipe_toTXDAT_bits_task_meta_state),
    .io_toTXDAT_bits_task_meta_clients                                  (mainPipe_toTXDAT_bits_task_meta_clients),
    .io_toTXDAT_bits_task_meta_alias                                    (mainPipe_toTXDAT_bits_task_meta_alias),
    .io_toTXDAT_bits_task_meta_prefetch                                 (mainPipe_toTXDAT_bits_task_meta_prefetch),
    .io_toTXDAT_bits_task_meta_prefetchSrc                              (mainPipe_toTXDAT_bits_task_meta_prefetchSrc),
    .io_toTXDAT_bits_task_meta_accessed                                 (mainPipe_toTXDAT_bits_task_meta_accessed),
    .io_toTXDAT_bits_task_meta_tagErr                                   (mainPipe_toTXDAT_bits_task_meta_tagErr),
    .io_toTXDAT_bits_task_meta_dataErr                                  (mainPipe_toTXDAT_bits_task_meta_dataErr),
    .io_toTXDAT_bits_task_metaWen                                       (mainPipe_toTXDAT_bits_task_metaWen),
    .io_toTXDAT_bits_task_tagWen                                        (mainPipe_toTXDAT_bits_task_tagWen),
    .io_toTXDAT_bits_task_dsWen                                         (mainPipe_toTXDAT_bits_task_dsWen),
    .io_toTXDAT_bits_task_wayMask                                       (mainPipe_toTXDAT_bits_task_wayMask),
    .io_toTXDAT_bits_task_replTask                                      (mainPipe_toTXDAT_bits_task_replTask),
    .io_toTXDAT_bits_task_cmoTask                                       (mainPipe_toTXDAT_bits_task_cmoTask),
    .io_toTXDAT_bits_task_cmoAll                                        (mainPipe_toTXDAT_bits_task_cmoAll),
    .io_toTXDAT_bits_task_reqSource                                     (mainPipe_toTXDAT_bits_task_reqSource),
    .io_toTXDAT_bits_task_mergeA                                        (mainPipe_toTXDAT_bits_task_mergeA),
    .io_toTXDAT_bits_task_aMergeTask_off                                (mainPipe_toTXDAT_bits_task_aMergeTask_off),
    .io_toTXDAT_bits_task_aMergeTask_alias                              (mainPipe_toTXDAT_bits_task_aMergeTask_alias),
    .io_toTXDAT_bits_task_aMergeTask_vaddr                              (mainPipe_toTXDAT_bits_task_aMergeTask_vaddr),
    .io_toTXDAT_bits_task_aMergeTask_isKeyword                          (mainPipe_toTXDAT_bits_task_aMergeTask_isKeyword),
    .io_toTXDAT_bits_task_aMergeTask_opcode                             (mainPipe_toTXDAT_bits_task_aMergeTask_opcode),
    .io_toTXDAT_bits_task_aMergeTask_param                              (mainPipe_toTXDAT_bits_task_aMergeTask_param),
    .io_toTXDAT_bits_task_aMergeTask_sourceId                           (mainPipe_toTXDAT_bits_task_aMergeTask_sourceId),
    .io_toTXDAT_bits_task_aMergeTask_meta_dirty                         (mainPipe_toTXDAT_bits_task_aMergeTask_meta_dirty),
    .io_toTXDAT_bits_task_aMergeTask_meta_state                         (mainPipe_toTXDAT_bits_task_aMergeTask_meta_state),
    .io_toTXDAT_bits_task_aMergeTask_meta_clients                       (mainPipe_toTXDAT_bits_task_aMergeTask_meta_clients),
    .io_toTXDAT_bits_task_aMergeTask_meta_alias                         (mainPipe_toTXDAT_bits_task_aMergeTask_meta_alias),
    .io_toTXDAT_bits_task_aMergeTask_meta_prefetch                      (mainPipe_toTXDAT_bits_task_aMergeTask_meta_prefetch),
    .io_toTXDAT_bits_task_aMergeTask_meta_prefetchSrc                   (mainPipe_toTXDAT_bits_task_aMergeTask_meta_prefetchSrc),
    .io_toTXDAT_bits_task_aMergeTask_meta_accessed                      (mainPipe_toTXDAT_bits_task_aMergeTask_meta_accessed),
    .io_toTXDAT_bits_task_aMergeTask_meta_tagErr                        (mainPipe_toTXDAT_bits_task_aMergeTask_meta_tagErr),
    .io_toTXDAT_bits_task_aMergeTask_meta_dataErr                       (mainPipe_toTXDAT_bits_task_aMergeTask_meta_dataErr),
    .io_toTXDAT_bits_task_snpHitRelease                                 (mainPipe_toTXDAT_bits_task_snpHitRelease),
    .io_toTXDAT_bits_task_snpHitReleaseToInval                          (mainPipe_toTXDAT_bits_task_snpHitReleaseToInval),
    .io_toTXDAT_bits_task_snpHitReleaseToClean                          (mainPipe_toTXDAT_bits_task_snpHitReleaseToClean),
    .io_toTXDAT_bits_task_snpHitReleaseWithData                         (mainPipe_toTXDAT_bits_task_snpHitReleaseWithData),
    .io_toTXDAT_bits_task_snpHitReleaseIdx                              (mainPipe_toTXDAT_bits_task_snpHitReleaseIdx),
    .io_toTXDAT_bits_task_snpHitReleaseMeta_dirty                       (mainPipe_toTXDAT_bits_task_snpHitReleaseMeta_dirty),
    .io_toTXDAT_bits_task_snpHitReleaseMeta_state                       (mainPipe_toTXDAT_bits_task_snpHitReleaseMeta_state),
    .io_toTXDAT_bits_task_snpHitReleaseMeta_clients                     (mainPipe_toTXDAT_bits_task_snpHitReleaseMeta_clients),
    .io_toTXDAT_bits_task_snpHitReleaseMeta_alias                       (mainPipe_toTXDAT_bits_task_snpHitReleaseMeta_alias),
    .io_toTXDAT_bits_task_snpHitReleaseMeta_prefetch                    (mainPipe_toTXDAT_bits_task_snpHitReleaseMeta_prefetch),
    .io_toTXDAT_bits_task_snpHitReleaseMeta_prefetchSrc                 (mainPipe_toTXDAT_bits_task_snpHitReleaseMeta_prefetchSrc),
    .io_toTXDAT_bits_task_snpHitReleaseMeta_accessed                    (mainPipe_toTXDAT_bits_task_snpHitReleaseMeta_accessed),
    .io_toTXDAT_bits_task_snpHitReleaseMeta_tagErr                      (mainPipe_toTXDAT_bits_task_snpHitReleaseMeta_tagErr),
    .io_toTXDAT_bits_task_snpHitReleaseMeta_dataErr                     (mainPipe_toTXDAT_bits_task_snpHitReleaseMeta_dataErr),
    .io_toTXDAT_bits_task_tgtID                                         (mainPipe_toTXDAT_bits_task_tgtID),
    .io_toTXDAT_bits_task_srcID                                         (mainPipe_toTXDAT_bits_task_srcID),
    .io_toTXDAT_bits_task_txnID                                         (mainPipe_toTXDAT_bits_task_txnID),
    .io_toTXDAT_bits_task_homeNID                                       (mainPipe_toTXDAT_bits_task_homeNID),
    .io_toTXDAT_bits_task_dbID                                          (mainPipe_toTXDAT_bits_task_dbID),
    .io_toTXDAT_bits_task_fwdNID                                        (mainPipe_toTXDAT_bits_task_fwdNID),
    .io_toTXDAT_bits_task_fwdTxnID                                      (mainPipe_toTXDAT_bits_task_fwdTxnID),
    .io_toTXDAT_bits_task_chiOpcode                                     (mainPipe_toTXDAT_bits_task_chiOpcode),
    .io_toTXDAT_bits_task_resp                                          (mainPipe_toTXDAT_bits_task_resp),
    .io_toTXDAT_bits_task_fwdState                                      (mainPipe_toTXDAT_bits_task_fwdState),
    .io_toTXDAT_bits_task_pCrdType                                      (mainPipe_toTXDAT_bits_task_pCrdType),
    .io_toTXDAT_bits_task_retToSrc                                      (mainPipe_toTXDAT_bits_task_retToSrc),
    .io_toTXDAT_bits_task_likelyshared                                  (mainPipe_toTXDAT_bits_task_likelyshared),
    .io_toTXDAT_bits_task_expCompAck                                    (mainPipe_toTXDAT_bits_task_expCompAck),
    .io_toTXDAT_bits_task_allowRetry                                    (mainPipe_toTXDAT_bits_task_allowRetry),
    .io_toTXDAT_bits_task_memAttr_allocate                              (mainPipe_toTXDAT_bits_task_memAttr_allocate),
    .io_toTXDAT_bits_task_memAttr_cacheable                             (mainPipe_toTXDAT_bits_task_memAttr_cacheable),
    .io_toTXDAT_bits_task_memAttr_device                                (mainPipe_toTXDAT_bits_task_memAttr_device),
    .io_toTXDAT_bits_task_memAttr_ewa                                   (mainPipe_toTXDAT_bits_task_memAttr_ewa),
    .io_toTXDAT_bits_task_traceTag                                      (mainPipe_toTXDAT_bits_task_traceTag),
    .io_toTXDAT_bits_data_data                                          (mainPipe_toTXDAT_bits_data_data),
    .io_metaWReq_valid                                                  (mainPipe_metaWReq_valid),
    .io_metaWReq_bits_set                                               (mainPipe_metaWReq_bits_set),
    .io_metaWReq_bits_wayOH                                             (mainPipe_metaWReq_bits_wayOH),
    .io_metaWReq_bits_wmeta_dirty                                       (mainPipe_metaWReq_bits_wmeta_dirty),
    .io_metaWReq_bits_wmeta_state                                       (mainPipe_metaWReq_bits_wmeta_state),
    .io_metaWReq_bits_wmeta_clients                                     (mainPipe_metaWReq_bits_wmeta_clients),
    .io_metaWReq_bits_wmeta_alias                                       (mainPipe_metaWReq_bits_wmeta_alias),
    .io_metaWReq_bits_wmeta_prefetch                                    (mainPipe_metaWReq_bits_wmeta_prefetch),
    .io_metaWReq_bits_wmeta_prefetchSrc                                 (mainPipe_metaWReq_bits_wmeta_prefetchSrc),
    .io_metaWReq_bits_wmeta_accessed                                    (mainPipe_metaWReq_bits_wmeta_accessed),
    .io_metaWReq_bits_wmeta_tagErr                                      (mainPipe_metaWReq_bits_wmeta_tagErr),
    .io_metaWReq_bits_wmeta_dataErr                                     (mainPipe_metaWReq_bits_wmeta_dataErr),
    .io_tagWReq_valid                                                   (mainPipe_tagWReq_valid),
    .io_tagWReq_bits_set                                                (mainPipe_tagWReq_bits_set),
    .io_tagWReq_bits_way                                                (mainPipe_tagWReq_bits_way),
    .io_tagWReq_bits_wtag                                               (mainPipe_tagWReq_bits_wtag),
    .io_releaseBufWrite_valid                                           (mainPipe_releaseBufWrite_valid),
    .io_releaseBufWrite_bits_id                                         (mainPipe_releaseBufWrite_bits_id),
    .io_releaseBufWrite_bits_data_data                                  (mainPipe_releaseBufWrite_bits_data_data),
    .io_dsResp_valid                                                    (mainPipe_dsResp_valid),
    .io_dsResp_bits_mshrId                                              (mainPipe_dsResp_bits_mshrId),
    .io_dsResp_bits_dataError                                           (mainPipe_dsResp_bits_dataError),
    .io_nestedwb_set                                                    (mainPipe_nestedwb_set),
    .io_nestedwb_tag                                                    (mainPipe_nestedwb_tag),
    .io_nestedwb_c_set_dirty                                            (mainPipe_nestedwb_c_set_dirty),
    .io_nestedwb_c_set_tip                                              (mainPipe_nestedwb_c_set_tip),
    .io_nestedwb_b_inv_dirty                                            (mainPipe_nestedwb_b_inv_dirty),
    .io_nestedwb_b_toB                                                  (mainPipe_nestedwb_b_toB),
    .io_nestedwb_b_toN                                                  (mainPipe_nestedwb_b_toN),
    .io_nestedwb_b_toClean                                              (mainPipe_nestedwb_b_toClean),
    .io_nestedwb_denied                                                 (mainPipe_nestedwb_denied),
    .io_nestedwb_corrupt                                                (mainPipe_nestedwb_corrupt),
    .io_nestedwbData_data                                               (mainPipe_nestedwbData_data),
    .io_l1Hint_ready                                                    (io_l1Hint_ready),
    .io_l1Hint_valid                                                    (io_l1Hint_valid),
    .io_l1Hint_bits_sourceId                                            (io_l1Hint_bits_sourceId),
    .io_l1Hint_bits_isKeyword                                           (io_l1Hint_bits_isKeyword),
    .io_prefetchTrain_ready                                             (io_prefetch_train_ready),
    .io_prefetchTrain_valid                                             (io_prefetch_train_valid),
    .io_prefetchTrain_bits_tag                                          (io_prefetch_train_bits_tag),
    .io_prefetchTrain_bits_set                                          (io_prefetch_train_bits_set),
    .io_prefetchTrain_bits_needT                                        (io_prefetch_train_bits_needT),
    .io_prefetchTrain_bits_source                                       (io_prefetch_train_bits_source),
    .io_prefetchTrain_bits_vaddr                                        (io_prefetch_train_bits_vaddr),
    .io_prefetchTrain_bits_hit                                          (io_prefetch_train_bits_hit),
    .io_prefetchTrain_bits_prefetched                                   (io_prefetch_train_bits_prefetched),
    .io_prefetchTrain_bits_pfsource                                     (io_prefetch_train_bits_pfsource),
    .io_prefetchTrain_bits_reqsource                                    (io_prefetch_train_bits_reqsource),
    .io_error_valid                                                     (mainPipe_error_valid),
    .io_error_bits_valid                                                (mainPipe_error_bits_valid),
    .io_error_bits_address                                              (mainPipe_error_bits_address),
    .io_perf_0_value                                                    (mainPipe_perf_0_value),
    .io_perf_1_value                                                    (mainPipe_perf_1_value),
    .io_perf_2_value                                                    (mainPipe_perf_2_value),
    .io_perf_3_value                                                    (mainPipe_perf_3_value),
    .io_perf_4_value                                                    (mainPipe_perf_4_value),
    .io_perf_5_value                                                    (mainPipe_perf_5_value),
    .io_perf_6_value                                                    (mainPipe_perf_6_value),
    .io_perf_7_value                                                    (mainPipe_perf_7_value),
    .io_perf_8_value                                                    (mainPipe_perf_8_value),
    .io_perf_9_value                                                    (mainPipe_perf_9_value),
    .io_perf_10_value                                                   (mainPipe_perf_10_value),
    .io_perf_11_value                                                   (mainPipe_perf_11_value),
    .io_perf_12_value                                                   (mainPipe_perf_12_value)
  );

  // RequestBuffer：A 通道请求缓冲，同 set 冲突的请求在这里等（并做 A 合并进 MSHR）
  RequestBuffer reqBuf (
    .clock                                     (clock),
    .reset                                     (reset),
    .io_in_ready                               (reqBuf_in_ready),
    .io_in_valid                               (sinkA_task_valid),
    .io_in_bits_set                            (sinkA_task_bits_set),
    .io_in_bits_tag                            (sinkA_task_bits_tag),
    .io_in_bits_off                            (sinkA_task_bits_off),
    .io_in_bits_alias                          (sinkA_task_bits_alias),
    .io_in_bits_vaddr                          (sinkA_task_bits_vaddr),
    .io_in_bits_isKeyword                      (sinkA_task_bits_isKeyword),
    .io_in_bits_opcode                         (sinkA_task_bits_opcode),
    .io_in_bits_param                          (sinkA_task_bits_param),
    .io_in_bits_size                           (sinkA_task_bits_size),
    .io_in_bits_sourceId                       (sinkA_task_bits_sourceId),
    .io_in_bits_corrupt                        (sinkA_task_bits_corrupt),
    .io_in_bits_fromL2pft                      (sinkA_task_bits_fromL2pft),
    .io_in_bits_needHint                       (sinkA_task_bits_needHint),
    .io_in_bits_reqSource                      (sinkA_task_bits_reqSource),
    .io_out_ready                              (reqArb_sinkA_ready),
    .io_out_valid                              (reqBuf_out_valid),
    .io_out_bits_channel                       (reqBuf_out_bits_channel),
    .io_out_bits_txChannel                     (reqBuf_out_bits_txChannel),
    .io_out_bits_set                           (reqBuf_out_bits_set),
    .io_out_bits_tag                           (reqBuf_out_bits_tag),
    .io_out_bits_off                           (reqBuf_out_bits_off),
    .io_out_bits_alias                         (reqBuf_out_bits_alias),
    .io_out_bits_vaddr                         (reqBuf_out_bits_vaddr),
    .io_out_bits_isKeyword                     (reqBuf_out_bits_isKeyword),
    .io_out_bits_opcode                        (reqBuf_out_bits_opcode),
    .io_out_bits_param                         (reqBuf_out_bits_param),
    .io_out_bits_size                          (reqBuf_out_bits_size),
    .io_out_bits_sourceId                      (reqBuf_out_bits_sourceId),
    .io_out_bits_bufIdx                        (reqBuf_out_bits_bufIdx),
    .io_out_bits_needProbeAckData              (reqBuf_out_bits_needProbeAckData),
    .io_out_bits_denied                        (reqBuf_out_bits_denied),
    .io_out_bits_corrupt                       (reqBuf_out_bits_corrupt),
    .io_out_bits_mshrTask                      (reqBuf_out_bits_mshrTask),
    .io_out_bits_mshrId                        (reqBuf_out_bits_mshrId),
    .io_out_bits_aliasTask                     (reqBuf_out_bits_aliasTask),
    .io_out_bits_useProbeData                  (reqBuf_out_bits_useProbeData),
    .io_out_bits_mshrRetry                     (reqBuf_out_bits_mshrRetry),
    .io_out_bits_readProbeDataDown             (reqBuf_out_bits_readProbeDataDown),
    .io_out_bits_fromL2pft                     (reqBuf_out_bits_fromL2pft),
    .io_out_bits_needHint                      (reqBuf_out_bits_needHint),
    .io_out_bits_dirty                         (reqBuf_out_bits_dirty),
    .io_out_bits_way                           (reqBuf_out_bits_way),
    .io_out_bits_meta_dirty                    (reqBuf_out_bits_meta_dirty),
    .io_out_bits_meta_state                    (reqBuf_out_bits_meta_state),
    .io_out_bits_meta_clients                  (reqBuf_out_bits_meta_clients),
    .io_out_bits_meta_alias                    (reqBuf_out_bits_meta_alias),
    .io_out_bits_meta_prefetch                 (reqBuf_out_bits_meta_prefetch),
    .io_out_bits_meta_prefetchSrc              (reqBuf_out_bits_meta_prefetchSrc),
    .io_out_bits_meta_accessed                 (reqBuf_out_bits_meta_accessed),
    .io_out_bits_meta_tagErr                   (reqBuf_out_bits_meta_tagErr),
    .io_out_bits_meta_dataErr                  (reqBuf_out_bits_meta_dataErr),
    .io_out_bits_metaWen                       (reqBuf_out_bits_metaWen),
    .io_out_bits_tagWen                        (reqBuf_out_bits_tagWen),
    .io_out_bits_dsWen                         (reqBuf_out_bits_dsWen),
    .io_out_bits_replTask                      (reqBuf_out_bits_replTask),
    .io_out_bits_cmoTask                       (reqBuf_out_bits_cmoTask),
    .io_out_bits_cmoAll                        (reqBuf_out_bits_cmoAll),
    .io_out_bits_reqSource                     (reqBuf_out_bits_reqSource),
    .io_out_bits_mergeA                        (reqBuf_out_bits_mergeA),
    .io_out_bits_aMergeTask_off                (reqBuf_out_bits_aMergeTask_off),
    .io_out_bits_aMergeTask_alias              (reqBuf_out_bits_aMergeTask_alias),
    .io_out_bits_aMergeTask_vaddr              (reqBuf_out_bits_aMergeTask_vaddr),
    .io_out_bits_aMergeTask_isKeyword          (reqBuf_out_bits_aMergeTask_isKeyword),
    .io_out_bits_aMergeTask_opcode             (reqBuf_out_bits_aMergeTask_opcode),
    .io_out_bits_aMergeTask_param              (reqBuf_out_bits_aMergeTask_param),
    .io_out_bits_aMergeTask_sourceId           (reqBuf_out_bits_aMergeTask_sourceId),
    .io_out_bits_aMergeTask_meta_dirty         (reqBuf_out_bits_aMergeTask_meta_dirty),
    .io_out_bits_aMergeTask_meta_state         (reqBuf_out_bits_aMergeTask_meta_state),
    .io_out_bits_aMergeTask_meta_clients       (reqBuf_out_bits_aMergeTask_meta_clients),
    .io_out_bits_aMergeTask_meta_alias         (reqBuf_out_bits_aMergeTask_meta_alias),
    .io_out_bits_aMergeTask_meta_prefetch      (reqBuf_out_bits_aMergeTask_meta_prefetch),
    .io_out_bits_aMergeTask_meta_prefetchSrc   (reqBuf_out_bits_aMergeTask_meta_prefetchSrc),
    .io_out_bits_aMergeTask_meta_accessed      (reqBuf_out_bits_aMergeTask_meta_accessed),
    .io_out_bits_aMergeTask_meta_tagErr        (reqBuf_out_bits_aMergeTask_meta_tagErr),
    .io_out_bits_aMergeTask_meta_dataErr       (reqBuf_out_bits_aMergeTask_meta_dataErr),
    .io_out_bits_snpHitRelease                 (reqBuf_out_bits_snpHitRelease),
    .io_out_bits_snpHitReleaseToInval          (reqBuf_out_bits_snpHitReleaseToInval),
    .io_out_bits_snpHitReleaseToClean          (reqBuf_out_bits_snpHitReleaseToClean),
    .io_out_bits_snpHitReleaseWithData         (reqBuf_out_bits_snpHitReleaseWithData),
    .io_out_bits_snpHitReleaseIdx              (reqBuf_out_bits_snpHitReleaseIdx),
    .io_out_bits_snpHitReleaseMeta_dirty       (reqBuf_out_bits_snpHitReleaseMeta_dirty),
    .io_out_bits_snpHitReleaseMeta_state       (reqBuf_out_bits_snpHitReleaseMeta_state),
    .io_out_bits_snpHitReleaseMeta_clients     (reqBuf_out_bits_snpHitReleaseMeta_clients),
    .io_out_bits_snpHitReleaseMeta_alias       (reqBuf_out_bits_snpHitReleaseMeta_alias),
    .io_out_bits_snpHitReleaseMeta_prefetch    (reqBuf_out_bits_snpHitReleaseMeta_prefetch),
    .io_out_bits_snpHitReleaseMeta_prefetchSrc (reqBuf_out_bits_snpHitReleaseMeta_prefetchSrc),
    .io_out_bits_snpHitReleaseMeta_accessed    (reqBuf_out_bits_snpHitReleaseMeta_accessed),
    .io_out_bits_snpHitReleaseMeta_tagErr      (reqBuf_out_bits_snpHitReleaseMeta_tagErr),
    .io_out_bits_snpHitReleaseMeta_dataErr     (reqBuf_out_bits_snpHitReleaseMeta_dataErr),
    .io_out_bits_tgtID                         (reqBuf_out_bits_tgtID),
    .io_out_bits_srcID                         (reqBuf_out_bits_srcID),
    .io_out_bits_txnID                         (reqBuf_out_bits_txnID),
    .io_out_bits_homeNID                       (reqBuf_out_bits_homeNID),
    .io_out_bits_dbID                          (reqBuf_out_bits_dbID),
    .io_out_bits_fwdNID                        (reqBuf_out_bits_fwdNID),
    .io_out_bits_fwdTxnID                      (reqBuf_out_bits_fwdTxnID),
    .io_out_bits_chiOpcode                     (reqBuf_out_bits_chiOpcode),
    .io_out_bits_resp                          (reqBuf_out_bits_resp),
    .io_out_bits_fwdState                      (reqBuf_out_bits_fwdState),
    .io_out_bits_pCrdType                      (reqBuf_out_bits_pCrdType),
    .io_out_bits_retToSrc                      (reqBuf_out_bits_retToSrc),
    .io_out_bits_likelyshared                  (reqBuf_out_bits_likelyshared),
    .io_out_bits_expCompAck                    (reqBuf_out_bits_expCompAck),
    .io_out_bits_allowRetry                    (reqBuf_out_bits_allowRetry),
    .io_out_bits_memAttr_allocate              (reqBuf_out_bits_memAttr_allocate),
    .io_out_bits_memAttr_cacheable             (reqBuf_out_bits_memAttr_cacheable),
    .io_out_bits_memAttr_device                (reqBuf_out_bits_memAttr_device),
    .io_out_bits_memAttr_ewa                   (reqBuf_out_bits_memAttr_ewa),
    .io_out_bits_traceTag                      (reqBuf_out_bits_traceTag),
    .io_mshrInfo_0_valid                       (mshrCtl_msInfo_0_valid),
    .io_mshrInfo_0_bits_channel                (mshrCtl_msInfo_0_bits_channel),
    .io_mshrInfo_0_bits_set                    (mshrCtl_msInfo_0_bits_set),
    .io_mshrInfo_0_bits_reqTag                 (mshrCtl_msInfo_0_bits_reqTag),
    .io_mshrInfo_0_bits_willFree               (mshrCtl_msInfo_0_bits_willFree),
    .io_mshrInfo_0_bits_needRelease            (mshrCtl_msInfo_0_bits_needRelease),
    .io_mshrInfo_0_bits_meta_prefetchSrc       (mshrCtl_msInfo_0_bits_meta_prefetchSrc),
    .io_mshrInfo_0_bits_metaTag                (mshrCtl_msInfo_0_bits_metaTag),
    .io_mshrInfo_0_bits_dirHit                 (mshrCtl_msInfo_0_bits_dirHit),
    .io_mshrInfo_0_bits_isAcqOrPrefetch        (mshrCtl_msInfo_0_bits_isAcqOrPrefetch),
    .io_mshrInfo_0_bits_isPrefetch             (mshrCtl_msInfo_0_bits_isPrefetch),
    .io_mshrInfo_0_bits_param                  (mshrCtl_msInfo_0_bits_param),
    .io_mshrInfo_0_bits_mergeA                 (mshrCtl_msInfo_0_bits_mergeA),
    .io_mshrInfo_0_bits_s_refill               (mshrCtl_msInfo_0_bits_s_refill),
    .io_mshrInfo_1_valid                       (mshrCtl_msInfo_1_valid),
    .io_mshrInfo_1_bits_channel                (mshrCtl_msInfo_1_bits_channel),
    .io_mshrInfo_1_bits_set                    (mshrCtl_msInfo_1_bits_set),
    .io_mshrInfo_1_bits_reqTag                 (mshrCtl_msInfo_1_bits_reqTag),
    .io_mshrInfo_1_bits_willFree               (mshrCtl_msInfo_1_bits_willFree),
    .io_mshrInfo_1_bits_needRelease            (mshrCtl_msInfo_1_bits_needRelease),
    .io_mshrInfo_1_bits_meta_prefetchSrc       (mshrCtl_msInfo_1_bits_meta_prefetchSrc),
    .io_mshrInfo_1_bits_metaTag                (mshrCtl_msInfo_1_bits_metaTag),
    .io_mshrInfo_1_bits_dirHit                 (mshrCtl_msInfo_1_bits_dirHit),
    .io_mshrInfo_1_bits_isAcqOrPrefetch        (mshrCtl_msInfo_1_bits_isAcqOrPrefetch),
    .io_mshrInfo_1_bits_isPrefetch             (mshrCtl_msInfo_1_bits_isPrefetch),
    .io_mshrInfo_1_bits_param                  (mshrCtl_msInfo_1_bits_param),
    .io_mshrInfo_1_bits_mergeA                 (mshrCtl_msInfo_1_bits_mergeA),
    .io_mshrInfo_1_bits_s_refill               (mshrCtl_msInfo_1_bits_s_refill),
    .io_mshrInfo_2_valid                       (mshrCtl_msInfo_2_valid),
    .io_mshrInfo_2_bits_channel                (mshrCtl_msInfo_2_bits_channel),
    .io_mshrInfo_2_bits_set                    (mshrCtl_msInfo_2_bits_set),
    .io_mshrInfo_2_bits_reqTag                 (mshrCtl_msInfo_2_bits_reqTag),
    .io_mshrInfo_2_bits_willFree               (mshrCtl_msInfo_2_bits_willFree),
    .io_mshrInfo_2_bits_needRelease            (mshrCtl_msInfo_2_bits_needRelease),
    .io_mshrInfo_2_bits_meta_prefetchSrc       (mshrCtl_msInfo_2_bits_meta_prefetchSrc),
    .io_mshrInfo_2_bits_metaTag                (mshrCtl_msInfo_2_bits_metaTag),
    .io_mshrInfo_2_bits_dirHit                 (mshrCtl_msInfo_2_bits_dirHit),
    .io_mshrInfo_2_bits_isAcqOrPrefetch        (mshrCtl_msInfo_2_bits_isAcqOrPrefetch),
    .io_mshrInfo_2_bits_isPrefetch             (mshrCtl_msInfo_2_bits_isPrefetch),
    .io_mshrInfo_2_bits_param                  (mshrCtl_msInfo_2_bits_param),
    .io_mshrInfo_2_bits_mergeA                 (mshrCtl_msInfo_2_bits_mergeA),
    .io_mshrInfo_2_bits_s_refill               (mshrCtl_msInfo_2_bits_s_refill),
    .io_mshrInfo_3_valid                       (mshrCtl_msInfo_3_valid),
    .io_mshrInfo_3_bits_channel                (mshrCtl_msInfo_3_bits_channel),
    .io_mshrInfo_3_bits_set                    (mshrCtl_msInfo_3_bits_set),
    .io_mshrInfo_3_bits_reqTag                 (mshrCtl_msInfo_3_bits_reqTag),
    .io_mshrInfo_3_bits_willFree               (mshrCtl_msInfo_3_bits_willFree),
    .io_mshrInfo_3_bits_needRelease            (mshrCtl_msInfo_3_bits_needRelease),
    .io_mshrInfo_3_bits_meta_prefetchSrc       (mshrCtl_msInfo_3_bits_meta_prefetchSrc),
    .io_mshrInfo_3_bits_metaTag                (mshrCtl_msInfo_3_bits_metaTag),
    .io_mshrInfo_3_bits_dirHit                 (mshrCtl_msInfo_3_bits_dirHit),
    .io_mshrInfo_3_bits_isAcqOrPrefetch        (mshrCtl_msInfo_3_bits_isAcqOrPrefetch),
    .io_mshrInfo_3_bits_isPrefetch             (mshrCtl_msInfo_3_bits_isPrefetch),
    .io_mshrInfo_3_bits_param                  (mshrCtl_msInfo_3_bits_param),
    .io_mshrInfo_3_bits_mergeA                 (mshrCtl_msInfo_3_bits_mergeA),
    .io_mshrInfo_3_bits_s_refill               (mshrCtl_msInfo_3_bits_s_refill),
    .io_mshrInfo_4_valid                       (mshrCtl_msInfo_4_valid),
    .io_mshrInfo_4_bits_channel                (mshrCtl_msInfo_4_bits_channel),
    .io_mshrInfo_4_bits_set                    (mshrCtl_msInfo_4_bits_set),
    .io_mshrInfo_4_bits_reqTag                 (mshrCtl_msInfo_4_bits_reqTag),
    .io_mshrInfo_4_bits_willFree               (mshrCtl_msInfo_4_bits_willFree),
    .io_mshrInfo_4_bits_needRelease            (mshrCtl_msInfo_4_bits_needRelease),
    .io_mshrInfo_4_bits_meta_prefetchSrc       (mshrCtl_msInfo_4_bits_meta_prefetchSrc),
    .io_mshrInfo_4_bits_metaTag                (mshrCtl_msInfo_4_bits_metaTag),
    .io_mshrInfo_4_bits_dirHit                 (mshrCtl_msInfo_4_bits_dirHit),
    .io_mshrInfo_4_bits_isAcqOrPrefetch        (mshrCtl_msInfo_4_bits_isAcqOrPrefetch),
    .io_mshrInfo_4_bits_isPrefetch             (mshrCtl_msInfo_4_bits_isPrefetch),
    .io_mshrInfo_4_bits_param                  (mshrCtl_msInfo_4_bits_param),
    .io_mshrInfo_4_bits_mergeA                 (mshrCtl_msInfo_4_bits_mergeA),
    .io_mshrInfo_4_bits_s_refill               (mshrCtl_msInfo_4_bits_s_refill),
    .io_mshrInfo_5_valid                       (mshrCtl_msInfo_5_valid),
    .io_mshrInfo_5_bits_channel                (mshrCtl_msInfo_5_bits_channel),
    .io_mshrInfo_5_bits_set                    (mshrCtl_msInfo_5_bits_set),
    .io_mshrInfo_5_bits_reqTag                 (mshrCtl_msInfo_5_bits_reqTag),
    .io_mshrInfo_5_bits_willFree               (mshrCtl_msInfo_5_bits_willFree),
    .io_mshrInfo_5_bits_needRelease            (mshrCtl_msInfo_5_bits_needRelease),
    .io_mshrInfo_5_bits_meta_prefetchSrc       (mshrCtl_msInfo_5_bits_meta_prefetchSrc),
    .io_mshrInfo_5_bits_metaTag                (mshrCtl_msInfo_5_bits_metaTag),
    .io_mshrInfo_5_bits_dirHit                 (mshrCtl_msInfo_5_bits_dirHit),
    .io_mshrInfo_5_bits_isAcqOrPrefetch        (mshrCtl_msInfo_5_bits_isAcqOrPrefetch),
    .io_mshrInfo_5_bits_isPrefetch             (mshrCtl_msInfo_5_bits_isPrefetch),
    .io_mshrInfo_5_bits_param                  (mshrCtl_msInfo_5_bits_param),
    .io_mshrInfo_5_bits_mergeA                 (mshrCtl_msInfo_5_bits_mergeA),
    .io_mshrInfo_5_bits_s_refill               (mshrCtl_msInfo_5_bits_s_refill),
    .io_mshrInfo_6_valid                       (mshrCtl_msInfo_6_valid),
    .io_mshrInfo_6_bits_channel                (mshrCtl_msInfo_6_bits_channel),
    .io_mshrInfo_6_bits_set                    (mshrCtl_msInfo_6_bits_set),
    .io_mshrInfo_6_bits_reqTag                 (mshrCtl_msInfo_6_bits_reqTag),
    .io_mshrInfo_6_bits_willFree               (mshrCtl_msInfo_6_bits_willFree),
    .io_mshrInfo_6_bits_needRelease            (mshrCtl_msInfo_6_bits_needRelease),
    .io_mshrInfo_6_bits_meta_prefetchSrc       (mshrCtl_msInfo_6_bits_meta_prefetchSrc),
    .io_mshrInfo_6_bits_metaTag                (mshrCtl_msInfo_6_bits_metaTag),
    .io_mshrInfo_6_bits_dirHit                 (mshrCtl_msInfo_6_bits_dirHit),
    .io_mshrInfo_6_bits_isAcqOrPrefetch        (mshrCtl_msInfo_6_bits_isAcqOrPrefetch),
    .io_mshrInfo_6_bits_isPrefetch             (mshrCtl_msInfo_6_bits_isPrefetch),
    .io_mshrInfo_6_bits_param                  (mshrCtl_msInfo_6_bits_param),
    .io_mshrInfo_6_bits_mergeA                 (mshrCtl_msInfo_6_bits_mergeA),
    .io_mshrInfo_6_bits_s_refill               (mshrCtl_msInfo_6_bits_s_refill),
    .io_mshrInfo_7_valid                       (mshrCtl_msInfo_7_valid),
    .io_mshrInfo_7_bits_channel                (mshrCtl_msInfo_7_bits_channel),
    .io_mshrInfo_7_bits_set                    (mshrCtl_msInfo_7_bits_set),
    .io_mshrInfo_7_bits_reqTag                 (mshrCtl_msInfo_7_bits_reqTag),
    .io_mshrInfo_7_bits_willFree               (mshrCtl_msInfo_7_bits_willFree),
    .io_mshrInfo_7_bits_needRelease            (mshrCtl_msInfo_7_bits_needRelease),
    .io_mshrInfo_7_bits_meta_prefetchSrc       (mshrCtl_msInfo_7_bits_meta_prefetchSrc),
    .io_mshrInfo_7_bits_metaTag                (mshrCtl_msInfo_7_bits_metaTag),
    .io_mshrInfo_7_bits_dirHit                 (mshrCtl_msInfo_7_bits_dirHit),
    .io_mshrInfo_7_bits_isAcqOrPrefetch        (mshrCtl_msInfo_7_bits_isAcqOrPrefetch),
    .io_mshrInfo_7_bits_isPrefetch             (mshrCtl_msInfo_7_bits_isPrefetch),
    .io_mshrInfo_7_bits_param                  (mshrCtl_msInfo_7_bits_param),
    .io_mshrInfo_7_bits_mergeA                 (mshrCtl_msInfo_7_bits_mergeA),
    .io_mshrInfo_7_bits_s_refill               (mshrCtl_msInfo_7_bits_s_refill),
    .io_mshrInfo_8_valid                       (mshrCtl_msInfo_8_valid),
    .io_mshrInfo_8_bits_channel                (mshrCtl_msInfo_8_bits_channel),
    .io_mshrInfo_8_bits_set                    (mshrCtl_msInfo_8_bits_set),
    .io_mshrInfo_8_bits_reqTag                 (mshrCtl_msInfo_8_bits_reqTag),
    .io_mshrInfo_8_bits_willFree               (mshrCtl_msInfo_8_bits_willFree),
    .io_mshrInfo_8_bits_needRelease            (mshrCtl_msInfo_8_bits_needRelease),
    .io_mshrInfo_8_bits_meta_prefetchSrc       (mshrCtl_msInfo_8_bits_meta_prefetchSrc),
    .io_mshrInfo_8_bits_metaTag                (mshrCtl_msInfo_8_bits_metaTag),
    .io_mshrInfo_8_bits_dirHit                 (mshrCtl_msInfo_8_bits_dirHit),
    .io_mshrInfo_8_bits_isAcqOrPrefetch        (mshrCtl_msInfo_8_bits_isAcqOrPrefetch),
    .io_mshrInfo_8_bits_isPrefetch             (mshrCtl_msInfo_8_bits_isPrefetch),
    .io_mshrInfo_8_bits_param                  (mshrCtl_msInfo_8_bits_param),
    .io_mshrInfo_8_bits_mergeA                 (mshrCtl_msInfo_8_bits_mergeA),
    .io_mshrInfo_8_bits_s_refill               (mshrCtl_msInfo_8_bits_s_refill),
    .io_mshrInfo_9_valid                       (mshrCtl_msInfo_9_valid),
    .io_mshrInfo_9_bits_channel                (mshrCtl_msInfo_9_bits_channel),
    .io_mshrInfo_9_bits_set                    (mshrCtl_msInfo_9_bits_set),
    .io_mshrInfo_9_bits_reqTag                 (mshrCtl_msInfo_9_bits_reqTag),
    .io_mshrInfo_9_bits_willFree               (mshrCtl_msInfo_9_bits_willFree),
    .io_mshrInfo_9_bits_needRelease            (mshrCtl_msInfo_9_bits_needRelease),
    .io_mshrInfo_9_bits_meta_prefetchSrc       (mshrCtl_msInfo_9_bits_meta_prefetchSrc),
    .io_mshrInfo_9_bits_metaTag                (mshrCtl_msInfo_9_bits_metaTag),
    .io_mshrInfo_9_bits_dirHit                 (mshrCtl_msInfo_9_bits_dirHit),
    .io_mshrInfo_9_bits_isAcqOrPrefetch        (mshrCtl_msInfo_9_bits_isAcqOrPrefetch),
    .io_mshrInfo_9_bits_isPrefetch             (mshrCtl_msInfo_9_bits_isPrefetch),
    .io_mshrInfo_9_bits_param                  (mshrCtl_msInfo_9_bits_param),
    .io_mshrInfo_9_bits_mergeA                 (mshrCtl_msInfo_9_bits_mergeA),
    .io_mshrInfo_9_bits_s_refill               (mshrCtl_msInfo_9_bits_s_refill),
    .io_mshrInfo_10_valid                      (mshrCtl_msInfo_10_valid),
    .io_mshrInfo_10_bits_channel               (mshrCtl_msInfo_10_bits_channel),
    .io_mshrInfo_10_bits_set                   (mshrCtl_msInfo_10_bits_set),
    .io_mshrInfo_10_bits_reqTag                (mshrCtl_msInfo_10_bits_reqTag),
    .io_mshrInfo_10_bits_willFree              (mshrCtl_msInfo_10_bits_willFree),
    .io_mshrInfo_10_bits_needRelease           (mshrCtl_msInfo_10_bits_needRelease),
    .io_mshrInfo_10_bits_meta_prefetchSrc      (mshrCtl_msInfo_10_bits_meta_prefetchSrc),
    .io_mshrInfo_10_bits_metaTag               (mshrCtl_msInfo_10_bits_metaTag),
    .io_mshrInfo_10_bits_dirHit                (mshrCtl_msInfo_10_bits_dirHit),
    .io_mshrInfo_10_bits_isAcqOrPrefetch       (mshrCtl_msInfo_10_bits_isAcqOrPrefetch),
    .io_mshrInfo_10_bits_isPrefetch            (mshrCtl_msInfo_10_bits_isPrefetch),
    .io_mshrInfo_10_bits_param                 (mshrCtl_msInfo_10_bits_param),
    .io_mshrInfo_10_bits_mergeA                (mshrCtl_msInfo_10_bits_mergeA),
    .io_mshrInfo_10_bits_s_refill              (mshrCtl_msInfo_10_bits_s_refill),
    .io_mshrInfo_11_valid                      (mshrCtl_msInfo_11_valid),
    .io_mshrInfo_11_bits_channel               (mshrCtl_msInfo_11_bits_channel),
    .io_mshrInfo_11_bits_set                   (mshrCtl_msInfo_11_bits_set),
    .io_mshrInfo_11_bits_reqTag                (mshrCtl_msInfo_11_bits_reqTag),
    .io_mshrInfo_11_bits_willFree              (mshrCtl_msInfo_11_bits_willFree),
    .io_mshrInfo_11_bits_needRelease           (mshrCtl_msInfo_11_bits_needRelease),
    .io_mshrInfo_11_bits_meta_prefetchSrc      (mshrCtl_msInfo_11_bits_meta_prefetchSrc),
    .io_mshrInfo_11_bits_metaTag               (mshrCtl_msInfo_11_bits_metaTag),
    .io_mshrInfo_11_bits_dirHit                (mshrCtl_msInfo_11_bits_dirHit),
    .io_mshrInfo_11_bits_isAcqOrPrefetch       (mshrCtl_msInfo_11_bits_isAcqOrPrefetch),
    .io_mshrInfo_11_bits_isPrefetch            (mshrCtl_msInfo_11_bits_isPrefetch),
    .io_mshrInfo_11_bits_param                 (mshrCtl_msInfo_11_bits_param),
    .io_mshrInfo_11_bits_mergeA                (mshrCtl_msInfo_11_bits_mergeA),
    .io_mshrInfo_11_bits_s_refill              (mshrCtl_msInfo_11_bits_s_refill),
    .io_mshrInfo_12_valid                      (mshrCtl_msInfo_12_valid),
    .io_mshrInfo_12_bits_channel               (mshrCtl_msInfo_12_bits_channel),
    .io_mshrInfo_12_bits_set                   (mshrCtl_msInfo_12_bits_set),
    .io_mshrInfo_12_bits_reqTag                (mshrCtl_msInfo_12_bits_reqTag),
    .io_mshrInfo_12_bits_willFree              (mshrCtl_msInfo_12_bits_willFree),
    .io_mshrInfo_12_bits_needRelease           (mshrCtl_msInfo_12_bits_needRelease),
    .io_mshrInfo_12_bits_meta_prefetchSrc      (mshrCtl_msInfo_12_bits_meta_prefetchSrc),
    .io_mshrInfo_12_bits_metaTag               (mshrCtl_msInfo_12_bits_metaTag),
    .io_mshrInfo_12_bits_dirHit                (mshrCtl_msInfo_12_bits_dirHit),
    .io_mshrInfo_12_bits_isAcqOrPrefetch       (mshrCtl_msInfo_12_bits_isAcqOrPrefetch),
    .io_mshrInfo_12_bits_isPrefetch            (mshrCtl_msInfo_12_bits_isPrefetch),
    .io_mshrInfo_12_bits_param                 (mshrCtl_msInfo_12_bits_param),
    .io_mshrInfo_12_bits_mergeA                (mshrCtl_msInfo_12_bits_mergeA),
    .io_mshrInfo_12_bits_s_refill              (mshrCtl_msInfo_12_bits_s_refill),
    .io_mshrInfo_13_valid                      (mshrCtl_msInfo_13_valid),
    .io_mshrInfo_13_bits_channel               (mshrCtl_msInfo_13_bits_channel),
    .io_mshrInfo_13_bits_set                   (mshrCtl_msInfo_13_bits_set),
    .io_mshrInfo_13_bits_reqTag                (mshrCtl_msInfo_13_bits_reqTag),
    .io_mshrInfo_13_bits_willFree              (mshrCtl_msInfo_13_bits_willFree),
    .io_mshrInfo_13_bits_needRelease           (mshrCtl_msInfo_13_bits_needRelease),
    .io_mshrInfo_13_bits_meta_prefetchSrc      (mshrCtl_msInfo_13_bits_meta_prefetchSrc),
    .io_mshrInfo_13_bits_metaTag               (mshrCtl_msInfo_13_bits_metaTag),
    .io_mshrInfo_13_bits_dirHit                (mshrCtl_msInfo_13_bits_dirHit),
    .io_mshrInfo_13_bits_isAcqOrPrefetch       (mshrCtl_msInfo_13_bits_isAcqOrPrefetch),
    .io_mshrInfo_13_bits_isPrefetch            (mshrCtl_msInfo_13_bits_isPrefetch),
    .io_mshrInfo_13_bits_param                 (mshrCtl_msInfo_13_bits_param),
    .io_mshrInfo_13_bits_mergeA                (mshrCtl_msInfo_13_bits_mergeA),
    .io_mshrInfo_13_bits_s_refill              (mshrCtl_msInfo_13_bits_s_refill),
    .io_mshrInfo_14_valid                      (mshrCtl_msInfo_14_valid),
    .io_mshrInfo_14_bits_channel               (mshrCtl_msInfo_14_bits_channel),
    .io_mshrInfo_14_bits_set                   (mshrCtl_msInfo_14_bits_set),
    .io_mshrInfo_14_bits_reqTag                (mshrCtl_msInfo_14_bits_reqTag),
    .io_mshrInfo_14_bits_willFree              (mshrCtl_msInfo_14_bits_willFree),
    .io_mshrInfo_14_bits_needRelease           (mshrCtl_msInfo_14_bits_needRelease),
    .io_mshrInfo_14_bits_meta_prefetchSrc      (mshrCtl_msInfo_14_bits_meta_prefetchSrc),
    .io_mshrInfo_14_bits_metaTag               (mshrCtl_msInfo_14_bits_metaTag),
    .io_mshrInfo_14_bits_dirHit                (mshrCtl_msInfo_14_bits_dirHit),
    .io_mshrInfo_14_bits_isAcqOrPrefetch       (mshrCtl_msInfo_14_bits_isAcqOrPrefetch),
    .io_mshrInfo_14_bits_isPrefetch            (mshrCtl_msInfo_14_bits_isPrefetch),
    .io_mshrInfo_14_bits_param                 (mshrCtl_msInfo_14_bits_param),
    .io_mshrInfo_14_bits_mergeA                (mshrCtl_msInfo_14_bits_mergeA),
    .io_mshrInfo_14_bits_s_refill              (mshrCtl_msInfo_14_bits_s_refill),
    .io_mshrInfo_15_valid                      (mshrCtl_msInfo_15_valid),
    .io_mshrInfo_15_bits_channel               (mshrCtl_msInfo_15_bits_channel),
    .io_mshrInfo_15_bits_set                   (mshrCtl_msInfo_15_bits_set),
    .io_mshrInfo_15_bits_reqTag                (mshrCtl_msInfo_15_bits_reqTag),
    .io_mshrInfo_15_bits_willFree              (mshrCtl_msInfo_15_bits_willFree),
    .io_mshrInfo_15_bits_needRelease           (mshrCtl_msInfo_15_bits_needRelease),
    .io_mshrInfo_15_bits_meta_prefetchSrc      (mshrCtl_msInfo_15_bits_meta_prefetchSrc),
    .io_mshrInfo_15_bits_metaTag               (mshrCtl_msInfo_15_bits_metaTag),
    .io_mshrInfo_15_bits_dirHit                (mshrCtl_msInfo_15_bits_dirHit),
    .io_mshrInfo_15_bits_isAcqOrPrefetch       (mshrCtl_msInfo_15_bits_isAcqOrPrefetch),
    .io_mshrInfo_15_bits_isPrefetch            (mshrCtl_msInfo_15_bits_isPrefetch),
    .io_mshrInfo_15_bits_param                 (mshrCtl_msInfo_15_bits_param),
    .io_mshrInfo_15_bits_mergeA                (mshrCtl_msInfo_15_bits_mergeA),
    .io_mshrInfo_15_bits_s_refill              (mshrCtl_msInfo_15_bits_s_refill),
    .io_aMergeTask_valid                       (reqBuf_aMergeTask_valid),
    .io_aMergeTask_bits_id                     (reqBuf_aMergeTask_bits_id),
    .io_aMergeTask_bits_task_off               (reqBuf_aMergeTask_bits_task_off),
    .io_aMergeTask_bits_task_alias             (reqBuf_aMergeTask_bits_task_alias),
    .io_aMergeTask_bits_task_vaddr             (reqBuf_aMergeTask_bits_task_vaddr),
    .io_aMergeTask_bits_task_isKeyword         (reqBuf_aMergeTask_bits_task_isKeyword),
    .io_aMergeTask_bits_task_opcode            (reqBuf_aMergeTask_bits_task_opcode),
    .io_aMergeTask_bits_task_param             (reqBuf_aMergeTask_bits_task_param),
    .io_aMergeTask_bits_task_sourceId          (reqBuf_aMergeTask_bits_task_sourceId),
    .io_mainPipeBlock_0                        (mainPipe_toReqBuf_0),
    .io_mainPipeBlock_1                        (mainPipe_toReqBuf_1),
    .io_taskFromArb_s2_valid                   (reqArb_taskToPipe_s2_valid),
    .io_taskFromArb_s2_bits_channel            (reqArb_taskToPipe_s2_bits_channel),
    .io_taskFromArb_s2_bits_set                (reqArb_taskToPipe_s2_bits_set),
    .io_taskFromArb_s2_bits_mshrTask           (reqArb_taskToPipe_s2_bits_mshrTask),
    .io_ATag                                   (reqBuf_ATag),
    .io_ASet                                   (reqBuf_ASet),
    .io_s1Entrance_valid                       (reqArb_s1Entrance_valid),
    .io_s1Entrance_bits_set                    (reqArb_s1Entrance_bits_set),
    .io_hasHitPfInMSHR_valid                   (io_hitPfInMSHR_valid),
    .io_hasHitPfInMSHR_bits                    (io_hitPfInMSHR_bits),
    .io_hasPfLateInMSHR_valid                  (io_pfLateInMSHR_valid),
    .io_hasPfLateInMSHR_bits                   (io_pfLateInMSHR_bits),
    .io_hasMergeA                              (reqBuf_hasMergeA)
  );

  // MSHRCtl：16 个 MSHR 的资源池，发 CHI 请求/响应、Probe（B 通道）与回 MainPipe 的任务
  MSHRCtl mshrCtl (
    .clock                                                                 (clock),
    .reset                                                                 (reset),
    .io_toReqArb_blockA_s1                                                 (mshrCtl_toReqArb_blockA_s1),
    .io_toReqArb_blockB_s1                                                 (mshrCtl_toReqArb_blockB_s1),
    .io_fromMainPipe_mshr_alloc_s3_valid                                   (mainPipe_toMSHRCtl_mshr_alloc_s3_valid),
    .io_fromMainPipe_mshr_alloc_s3_bits_dirResult_hit                      (mainPipe_toMSHRCtl_mshr_alloc_s3_bits_dirResult_hit),
    .io_fromMainPipe_mshr_alloc_s3_bits_dirResult_tag                      (mainPipe_toMSHRCtl_mshr_alloc_s3_bits_dirResult_tag),
    .io_fromMainPipe_mshr_alloc_s3_bits_dirResult_set                      (mainPipe_toMSHRCtl_mshr_alloc_s3_bits_dirResult_set),
    .io_fromMainPipe_mshr_alloc_s3_bits_dirResult_way                      (mainPipe_toMSHRCtl_mshr_alloc_s3_bits_dirResult_way),
    .io_fromMainPipe_mshr_alloc_s3_bits_dirResult_meta_dirty               (mainPipe_toMSHRCtl_mshr_alloc_s3_bits_dirResult_meta_dirty),
    .io_fromMainPipe_mshr_alloc_s3_bits_dirResult_meta_state               (mainPipe_toMSHRCtl_mshr_alloc_s3_bits_dirResult_meta_state),
    .io_fromMainPipe_mshr_alloc_s3_bits_dirResult_meta_clients             (mainPipe_toMSHRCtl_mshr_alloc_s3_bits_dirResult_meta_clients),
    .io_fromMainPipe_mshr_alloc_s3_bits_dirResult_meta_alias               (mainPipe_toMSHRCtl_mshr_alloc_s3_bits_dirResult_meta_alias),
    .io_fromMainPipe_mshr_alloc_s3_bits_dirResult_meta_prefetch            (mainPipe_toMSHRCtl_mshr_alloc_s3_bits_dirResult_meta_prefetch),
    .io_fromMainPipe_mshr_alloc_s3_bits_dirResult_meta_prefetchSrc         (mainPipe_toMSHRCtl_mshr_alloc_s3_bits_dirResult_meta_prefetchSrc),
    .io_fromMainPipe_mshr_alloc_s3_bits_dirResult_meta_accessed            (mainPipe_toMSHRCtl_mshr_alloc_s3_bits_dirResult_meta_accessed),
    .io_fromMainPipe_mshr_alloc_s3_bits_dirResult_meta_tagErr              (mainPipe_toMSHRCtl_mshr_alloc_s3_bits_dirResult_meta_tagErr),
    .io_fromMainPipe_mshr_alloc_s3_bits_dirResult_meta_dataErr             (mainPipe_toMSHRCtl_mshr_alloc_s3_bits_dirResult_meta_dataErr),
    .io_fromMainPipe_mshr_alloc_s3_bits_dirResult_error                    (mainPipe_toMSHRCtl_mshr_alloc_s3_bits_dirResult_error),
    .io_fromMainPipe_mshr_alloc_s3_bits_state_s_acquire                    (mainPipe_toMSHRCtl_mshr_alloc_s3_bits_state_s_acquire),
    .io_fromMainPipe_mshr_alloc_s3_bits_state_s_rprobe                     (mainPipe_toMSHRCtl_mshr_alloc_s3_bits_state_s_rprobe),
    .io_fromMainPipe_mshr_alloc_s3_bits_state_s_pprobe                     (mainPipe_toMSHRCtl_mshr_alloc_s3_bits_state_s_pprobe),
    .io_fromMainPipe_mshr_alloc_s3_bits_state_s_release                    (mainPipe_toMSHRCtl_mshr_alloc_s3_bits_state_s_release),
    .io_fromMainPipe_mshr_alloc_s3_bits_state_s_probeack                   (mainPipe_toMSHRCtl_mshr_alloc_s3_bits_state_s_probeack),
    .io_fromMainPipe_mshr_alloc_s3_bits_state_s_refill                     (mainPipe_toMSHRCtl_mshr_alloc_s3_bits_state_s_refill),
    .io_fromMainPipe_mshr_alloc_s3_bits_state_s_cmoresp                    (mainPipe_toMSHRCtl_mshr_alloc_s3_bits_state_s_cmoresp),
    .io_fromMainPipe_mshr_alloc_s3_bits_state_w_rprobeackfirst             (mainPipe_toMSHRCtl_mshr_alloc_s3_bits_state_w_rprobeackfirst),
    .io_fromMainPipe_mshr_alloc_s3_bits_state_w_rprobeacklast              (mainPipe_toMSHRCtl_mshr_alloc_s3_bits_state_w_rprobeacklast),
    .io_fromMainPipe_mshr_alloc_s3_bits_state_w_pprobeackfirst             (mainPipe_toMSHRCtl_mshr_alloc_s3_bits_state_w_pprobeackfirst),
    .io_fromMainPipe_mshr_alloc_s3_bits_state_w_pprobeacklast              (mainPipe_toMSHRCtl_mshr_alloc_s3_bits_state_w_pprobeacklast),
    .io_fromMainPipe_mshr_alloc_s3_bits_state_w_grantfirst                 (mainPipe_toMSHRCtl_mshr_alloc_s3_bits_state_w_grantfirst),
    .io_fromMainPipe_mshr_alloc_s3_bits_state_w_grantlast                  (mainPipe_toMSHRCtl_mshr_alloc_s3_bits_state_w_grantlast),
    .io_fromMainPipe_mshr_alloc_s3_bits_state_w_grant                      (mainPipe_toMSHRCtl_mshr_alloc_s3_bits_state_w_grant),
    .io_fromMainPipe_mshr_alloc_s3_bits_state_w_releaseack                 (mainPipe_toMSHRCtl_mshr_alloc_s3_bits_state_w_releaseack),
    .io_fromMainPipe_mshr_alloc_s3_bits_state_w_replResp                   (mainPipe_toMSHRCtl_mshr_alloc_s3_bits_state_w_replResp),
    .io_fromMainPipe_mshr_alloc_s3_bits_state_s_rcompack                   (mainPipe_toMSHRCtl_mshr_alloc_s3_bits_state_s_rcompack),
    .io_fromMainPipe_mshr_alloc_s3_bits_state_s_dct                        (mainPipe_toMSHRCtl_mshr_alloc_s3_bits_state_s_dct),
    .io_fromMainPipe_mshr_alloc_s3_bits_task_channel                       (mainPipe_toMSHRCtl_mshr_alloc_s3_bits_task_channel),
    .io_fromMainPipe_mshr_alloc_s3_bits_task_set                           (mainPipe_toMSHRCtl_mshr_alloc_s3_bits_task_set),
    .io_fromMainPipe_mshr_alloc_s3_bits_task_tag                           (mainPipe_toMSHRCtl_mshr_alloc_s3_bits_task_tag),
    .io_fromMainPipe_mshr_alloc_s3_bits_task_off                           (mainPipe_toMSHRCtl_mshr_alloc_s3_bits_task_off),
    .io_fromMainPipe_mshr_alloc_s3_bits_task_alias                         (mainPipe_toMSHRCtl_mshr_alloc_s3_bits_task_alias),
    .io_fromMainPipe_mshr_alloc_s3_bits_task_isKeyword                     (mainPipe_toMSHRCtl_mshr_alloc_s3_bits_task_isKeyword),
    .io_fromMainPipe_mshr_alloc_s3_bits_task_opcode                        (mainPipe_toMSHRCtl_mshr_alloc_s3_bits_task_opcode),
    .io_fromMainPipe_mshr_alloc_s3_bits_task_param                         (mainPipe_toMSHRCtl_mshr_alloc_s3_bits_task_param),
    .io_fromMainPipe_mshr_alloc_s3_bits_task_sourceId                      (mainPipe_toMSHRCtl_mshr_alloc_s3_bits_task_sourceId),
    .io_fromMainPipe_mshr_alloc_s3_bits_task_denied                        (mainPipe_toMSHRCtl_mshr_alloc_s3_bits_task_denied),
    .io_fromMainPipe_mshr_alloc_s3_bits_task_corrupt                       (mainPipe_toMSHRCtl_mshr_alloc_s3_bits_task_corrupt),
    .io_fromMainPipe_mshr_alloc_s3_bits_task_aliasTask                     (mainPipe_toMSHRCtl_mshr_alloc_s3_bits_task_aliasTask),
    .io_fromMainPipe_mshr_alloc_s3_bits_task_fromL2pft                     (mainPipe_toMSHRCtl_mshr_alloc_s3_bits_task_fromL2pft),
    .io_fromMainPipe_mshr_alloc_s3_bits_task_reqSource                     (mainPipe_toMSHRCtl_mshr_alloc_s3_bits_task_reqSource),
    .io_fromMainPipe_mshr_alloc_s3_bits_task_snpHitRelease                 (mainPipe_toMSHRCtl_mshr_alloc_s3_bits_task_snpHitRelease),
    .io_fromMainPipe_mshr_alloc_s3_bits_task_snpHitReleaseToInval          (mainPipe_toMSHRCtl_mshr_alloc_s3_bits_task_snpHitReleaseToInval),
    .io_fromMainPipe_mshr_alloc_s3_bits_task_snpHitReleaseToClean          (mainPipe_toMSHRCtl_mshr_alloc_s3_bits_task_snpHitReleaseToClean),
    .io_fromMainPipe_mshr_alloc_s3_bits_task_snpHitReleaseWithData         (mainPipe_toMSHRCtl_mshr_alloc_s3_bits_task_snpHitReleaseWithData),
    .io_fromMainPipe_mshr_alloc_s3_bits_task_snpHitReleaseIdx              (mainPipe_toMSHRCtl_mshr_alloc_s3_bits_task_snpHitReleaseIdx),
    .io_fromMainPipe_mshr_alloc_s3_bits_task_snpHitReleaseMeta_dirty       (mainPipe_toMSHRCtl_mshr_alloc_s3_bits_task_snpHitReleaseMeta_dirty),
    .io_fromMainPipe_mshr_alloc_s3_bits_task_snpHitReleaseMeta_state       (mainPipe_toMSHRCtl_mshr_alloc_s3_bits_task_snpHitReleaseMeta_state),
    .io_fromMainPipe_mshr_alloc_s3_bits_task_snpHitReleaseMeta_clients     (mainPipe_toMSHRCtl_mshr_alloc_s3_bits_task_snpHitReleaseMeta_clients),
    .io_fromMainPipe_mshr_alloc_s3_bits_task_snpHitReleaseMeta_alias       (mainPipe_toMSHRCtl_mshr_alloc_s3_bits_task_snpHitReleaseMeta_alias),
    .io_fromMainPipe_mshr_alloc_s3_bits_task_snpHitReleaseMeta_prefetch    (mainPipe_toMSHRCtl_mshr_alloc_s3_bits_task_snpHitReleaseMeta_prefetch),
    .io_fromMainPipe_mshr_alloc_s3_bits_task_snpHitReleaseMeta_prefetchSrc (mainPipe_toMSHRCtl_mshr_alloc_s3_bits_task_snpHitReleaseMeta_prefetchSrc),
    .io_fromMainPipe_mshr_alloc_s3_bits_task_snpHitReleaseMeta_accessed    (mainPipe_toMSHRCtl_mshr_alloc_s3_bits_task_snpHitReleaseMeta_accessed),
    .io_fromMainPipe_mshr_alloc_s3_bits_task_snpHitReleaseMeta_tagErr      (mainPipe_toMSHRCtl_mshr_alloc_s3_bits_task_snpHitReleaseMeta_tagErr),
    .io_fromMainPipe_mshr_alloc_s3_bits_task_snpHitReleaseMeta_dataErr     (mainPipe_toMSHRCtl_mshr_alloc_s3_bits_task_snpHitReleaseMeta_dataErr),
    .io_fromMainPipe_mshr_alloc_s3_bits_task_srcID                         (mainPipe_toMSHRCtl_mshr_alloc_s3_bits_task_srcID),
    .io_fromMainPipe_mshr_alloc_s3_bits_task_txnID                         (mainPipe_toMSHRCtl_mshr_alloc_s3_bits_task_txnID),
    .io_fromMainPipe_mshr_alloc_s3_bits_task_fwdNID                        (mainPipe_toMSHRCtl_mshr_alloc_s3_bits_task_fwdNID),
    .io_fromMainPipe_mshr_alloc_s3_bits_task_fwdTxnID                      (mainPipe_toMSHRCtl_mshr_alloc_s3_bits_task_fwdTxnID),
    .io_fromMainPipe_mshr_alloc_s3_bits_task_chiOpcode                     (mainPipe_toMSHRCtl_mshr_alloc_s3_bits_task_chiOpcode),
    .io_fromMainPipe_mshr_alloc_s3_bits_task_retToSrc                      (mainPipe_toMSHRCtl_mshr_alloc_s3_bits_task_retToSrc),
    .io_fromMainPipe_mshr_alloc_s3_bits_task_traceTag                      (mainPipe_toMSHRCtl_mshr_alloc_s3_bits_task_traceTag),
    .io_toMainPipe_mshr_alloc_ptr                                          (mshrCtl_toMainPipe_mshr_alloc_ptr),
    .io_mshrTask_ready                                                     (reqArb_mshrTask_ready),
    .io_mshrTask_valid                                                     (mshrCtl_mshrTask_valid),
    .io_mshrTask_bits_channel                                              (mshrCtl_mshrTask_bits_channel),
    .io_mshrTask_bits_txChannel                                            (mshrCtl_mshrTask_bits_txChannel),
    .io_mshrTask_bits_set                                                  (mshrCtl_mshrTask_bits_set),
    .io_mshrTask_bits_tag                                                  (mshrCtl_mshrTask_bits_tag),
    .io_mshrTask_bits_off                                                  (mshrCtl_mshrTask_bits_off),
    .io_mshrTask_bits_alias                                                (mshrCtl_mshrTask_bits_alias),
    .io_mshrTask_bits_isKeyword                                            (mshrCtl_mshrTask_bits_isKeyword),
    .io_mshrTask_bits_opcode                                               (mshrCtl_mshrTask_bits_opcode),
    .io_mshrTask_bits_param                                                (mshrCtl_mshrTask_bits_param),
    .io_mshrTask_bits_size                                                 (mshrCtl_mshrTask_bits_size),
    .io_mshrTask_bits_sourceId                                             (mshrCtl_mshrTask_bits_sourceId),
    .io_mshrTask_bits_denied                                               (mshrCtl_mshrTask_bits_denied),
    .io_mshrTask_bits_corrupt                                              (mshrCtl_mshrTask_bits_corrupt),
    .io_mshrTask_bits_mshrTask                                             (mshrCtl_mshrTask_bits_mshrTask),
    .io_mshrTask_bits_mshrId                                               (mshrCtl_mshrTask_bits_mshrId),
    .io_mshrTask_bits_aliasTask                                            (mshrCtl_mshrTask_bits_aliasTask),
    .io_mshrTask_bits_useProbeData                                         (mshrCtl_mshrTask_bits_useProbeData),
    .io_mshrTask_bits_mshrRetry                                            (mshrCtl_mshrTask_bits_mshrRetry),
    .io_mshrTask_bits_readProbeDataDown                                    (mshrCtl_mshrTask_bits_readProbeDataDown),
    .io_mshrTask_bits_fromL2pft                                            (mshrCtl_mshrTask_bits_fromL2pft),
    .io_mshrTask_bits_dirty                                                (mshrCtl_mshrTask_bits_dirty),
    .io_mshrTask_bits_way                                                  (mshrCtl_mshrTask_bits_way),
    .io_mshrTask_bits_meta_dirty                                           (mshrCtl_mshrTask_bits_meta_dirty),
    .io_mshrTask_bits_meta_state                                           (mshrCtl_mshrTask_bits_meta_state),
    .io_mshrTask_bits_meta_clients                                         (mshrCtl_mshrTask_bits_meta_clients),
    .io_mshrTask_bits_meta_alias                                           (mshrCtl_mshrTask_bits_meta_alias),
    .io_mshrTask_bits_meta_prefetch                                        (mshrCtl_mshrTask_bits_meta_prefetch),
    .io_mshrTask_bits_meta_prefetchSrc                                     (mshrCtl_mshrTask_bits_meta_prefetchSrc),
    .io_mshrTask_bits_meta_accessed                                        (mshrCtl_mshrTask_bits_meta_accessed),
    .io_mshrTask_bits_meta_tagErr                                          (mshrCtl_mshrTask_bits_meta_tagErr),
    .io_mshrTask_bits_meta_dataErr                                         (mshrCtl_mshrTask_bits_meta_dataErr),
    .io_mshrTask_bits_metaWen                                              (mshrCtl_mshrTask_bits_metaWen),
    .io_mshrTask_bits_tagWen                                               (mshrCtl_mshrTask_bits_tagWen),
    .io_mshrTask_bits_dsWen                                                (mshrCtl_mshrTask_bits_dsWen),
    .io_mshrTask_bits_replTask                                             (mshrCtl_mshrTask_bits_replTask),
    .io_mshrTask_bits_cmoTask                                              (mshrCtl_mshrTask_bits_cmoTask),
    .io_mshrTask_bits_reqSource                                            (mshrCtl_mshrTask_bits_reqSource),
    .io_mshrTask_bits_mergeA                                               (mshrCtl_mshrTask_bits_mergeA),
    .io_mshrTask_bits_aMergeTask_off                                       (mshrCtl_mshrTask_bits_aMergeTask_off),
    .io_mshrTask_bits_aMergeTask_alias                                     (mshrCtl_mshrTask_bits_aMergeTask_alias),
    .io_mshrTask_bits_aMergeTask_vaddr                                     (mshrCtl_mshrTask_bits_aMergeTask_vaddr),
    .io_mshrTask_bits_aMergeTask_isKeyword                                 (mshrCtl_mshrTask_bits_aMergeTask_isKeyword),
    .io_mshrTask_bits_aMergeTask_opcode                                    (mshrCtl_mshrTask_bits_aMergeTask_opcode),
    .io_mshrTask_bits_aMergeTask_param                                     (mshrCtl_mshrTask_bits_aMergeTask_param),
    .io_mshrTask_bits_aMergeTask_sourceId                                  (mshrCtl_mshrTask_bits_aMergeTask_sourceId),
    .io_mshrTask_bits_aMergeTask_meta_dirty                                (mshrCtl_mshrTask_bits_aMergeTask_meta_dirty),
    .io_mshrTask_bits_aMergeTask_meta_state                                (mshrCtl_mshrTask_bits_aMergeTask_meta_state),
    .io_mshrTask_bits_aMergeTask_meta_clients                              (mshrCtl_mshrTask_bits_aMergeTask_meta_clients),
    .io_mshrTask_bits_aMergeTask_meta_alias                                (mshrCtl_mshrTask_bits_aMergeTask_meta_alias),
    .io_mshrTask_bits_aMergeTask_meta_accessed                             (mshrCtl_mshrTask_bits_aMergeTask_meta_accessed),
    .io_mshrTask_bits_snpHitRelease                                        (mshrCtl_mshrTask_bits_snpHitRelease),
    .io_mshrTask_bits_snpHitReleaseToInval                                 (mshrCtl_mshrTask_bits_snpHitReleaseToInval),
    .io_mshrTask_bits_snpHitReleaseToClean                                 (mshrCtl_mshrTask_bits_snpHitReleaseToClean),
    .io_mshrTask_bits_snpHitReleaseWithData                                (mshrCtl_mshrTask_bits_snpHitReleaseWithData),
    .io_mshrTask_bits_snpHitReleaseIdx                                     (mshrCtl_mshrTask_bits_snpHitReleaseIdx),
    .io_mshrTask_bits_snpHitReleaseMeta_dirty                              (mshrCtl_mshrTask_bits_snpHitReleaseMeta_dirty),
    .io_mshrTask_bits_snpHitReleaseMeta_state                              (mshrCtl_mshrTask_bits_snpHitReleaseMeta_state),
    .io_mshrTask_bits_snpHitReleaseMeta_clients                            (mshrCtl_mshrTask_bits_snpHitReleaseMeta_clients),
    .io_mshrTask_bits_snpHitReleaseMeta_alias                              (mshrCtl_mshrTask_bits_snpHitReleaseMeta_alias),
    .io_mshrTask_bits_snpHitReleaseMeta_prefetch                           (mshrCtl_mshrTask_bits_snpHitReleaseMeta_prefetch),
    .io_mshrTask_bits_snpHitReleaseMeta_prefetchSrc                        (mshrCtl_mshrTask_bits_snpHitReleaseMeta_prefetchSrc),
    .io_mshrTask_bits_snpHitReleaseMeta_accessed                           (mshrCtl_mshrTask_bits_snpHitReleaseMeta_accessed),
    .io_mshrTask_bits_snpHitReleaseMeta_tagErr                             (mshrCtl_mshrTask_bits_snpHitReleaseMeta_tagErr),
    .io_mshrTask_bits_snpHitReleaseMeta_dataErr                            (mshrCtl_mshrTask_bits_snpHitReleaseMeta_dataErr),
    .io_mshrTask_bits_tgtID                                                (mshrCtl_mshrTask_bits_tgtID),
    .io_mshrTask_bits_txnID                                                (mshrCtl_mshrTask_bits_txnID),
    .io_mshrTask_bits_homeNID                                              (mshrCtl_mshrTask_bits_homeNID),
    .io_mshrTask_bits_dbID                                                 (mshrCtl_mshrTask_bits_dbID),
    .io_mshrTask_bits_chiOpcode                                            (mshrCtl_mshrTask_bits_chiOpcode),
    .io_mshrTask_bits_resp                                                 (mshrCtl_mshrTask_bits_resp),
    .io_mshrTask_bits_fwdState                                             (mshrCtl_mshrTask_bits_fwdState),
    .io_mshrTask_bits_retToSrc                                             (mshrCtl_mshrTask_bits_retToSrc),
    .io_mshrTask_bits_likelyshared                                         (mshrCtl_mshrTask_bits_likelyshared),
    .io_mshrTask_bits_expCompAck                                           (mshrCtl_mshrTask_bits_expCompAck),
    .io_mshrTask_bits_allowRetry                                           (mshrCtl_mshrTask_bits_allowRetry),
    .io_mshrTask_bits_memAttr_allocate                                     (mshrCtl_mshrTask_bits_memAttr_allocate),
    .io_mshrTask_bits_memAttr_cacheable                                    (mshrCtl_mshrTask_bits_memAttr_cacheable),
    .io_mshrTask_bits_memAttr_ewa                                          (mshrCtl_mshrTask_bits_memAttr_ewa),
    .io_mshrTask_bits_traceTag                                             (mshrCtl_mshrTask_bits_traceTag),
    .io_pipeStatusVec_0_valid                                              (reqArb_status_vec_1_valid),
    .io_pipeStatusVec_1_valid                                              (mainPipe_status_vec_toD_0_valid),
    .io_toTXREQ_ready                                                      (txreq_mshrReq_ready),
    .io_toTXREQ_valid                                                      (mshrCtl_toTXREQ_valid),
    .io_toTXREQ_bits_qos                                                   (mshrCtl_toTXREQ_bits_qos),
    .io_toTXREQ_bits_tgtID                                                 (mshrCtl_toTXREQ_bits_tgtID),
    .io_toTXREQ_bits_txnID                                                 (mshrCtl_toTXREQ_bits_txnID),
    .io_toTXREQ_bits_opcode                                                (mshrCtl_toTXREQ_bits_opcode),
    .io_toTXREQ_bits_size                                                  (mshrCtl_toTXREQ_bits_size),
    .io_toTXREQ_bits_addr                                                  (mshrCtl_toTXREQ_bits_addr),
    .io_toTXREQ_bits_likelyshared                                          (mshrCtl_toTXREQ_bits_likelyshared),
    .io_toTXREQ_bits_allowRetry                                            (mshrCtl_toTXREQ_bits_allowRetry),
    .io_toTXREQ_bits_pCrdType                                              (mshrCtl_toTXREQ_bits_pCrdType),
    .io_toTXREQ_bits_memAttr_allocate                                      (mshrCtl_toTXREQ_bits_memAttr_allocate),
    .io_toTXREQ_bits_memAttr_cacheable                                     (mshrCtl_toTXREQ_bits_memAttr_cacheable),
    .io_toTXREQ_bits_memAttr_ewa                                           (mshrCtl_toTXREQ_bits_memAttr_ewa),
    .io_toTXREQ_bits_snpAttr                                               (mshrCtl_toTXREQ_bits_snpAttr),
    .io_toTXREQ_bits_expCompAck                                            (mshrCtl_toTXREQ_bits_expCompAck),
    .io_toTXRSP_ready                                                      (txrsp_mshrRsp_ready),
    .io_toTXRSP_valid                                                      (mshrCtl_toTXRSP_valid),
    .io_toTXRSP_bits_tgtID                                                 (mshrCtl_toTXRSP_bits_tgtID),
    .io_toTXRSP_bits_txnID                                                 (mshrCtl_toTXRSP_bits_txnID),
    .io_toTXRSP_bits_opcode                                                (mshrCtl_toTXRSP_bits_opcode),
    .io_toTXRSP_bits_traceTag                                              (mshrCtl_toTXRSP_bits_traceTag),
    .io_toSourceB_ready                                                    (io_in_b_ready),
    .io_toSourceB_valid                                                    (io_in_b_valid),
    .io_toSourceB_bits_opcode                                              (io_in_b_bits_opcode),
    .io_toSourceB_bits_param                                               (io_in_b_bits_param),
    .io_toSourceB_bits_address                                             (io_in_b_bits_address),
    .io_toSourceB_bits_data                                                (io_in_b_bits_data),
    .io_grantStatus_0_valid                                                (grantBuf_grantStatus_0_valid),
    .io_grantStatus_0_set                                                  (grantBuf_grantStatus_0_set),
    .io_grantStatus_0_tag                                                  (grantBuf_grantStatus_0_tag),
    .io_grantStatus_1_valid                                                (grantBuf_grantStatus_1_valid),
    .io_grantStatus_1_set                                                  (grantBuf_grantStatus_1_set),
    .io_grantStatus_1_tag                                                  (grantBuf_grantStatus_1_tag),
    .io_grantStatus_2_valid                                                (grantBuf_grantStatus_2_valid),
    .io_grantStatus_2_set                                                  (grantBuf_grantStatus_2_set),
    .io_grantStatus_2_tag                                                  (grantBuf_grantStatus_2_tag),
    .io_grantStatus_3_valid                                                (grantBuf_grantStatus_3_valid),
    .io_grantStatus_3_set                                                  (grantBuf_grantStatus_3_set),
    .io_grantStatus_3_tag                                                  (grantBuf_grantStatus_3_tag),
    .io_grantStatus_4_valid                                                (grantBuf_grantStatus_4_valid),
    .io_grantStatus_4_set                                                  (grantBuf_grantStatus_4_set),
    .io_grantStatus_4_tag                                                  (grantBuf_grantStatus_4_tag),
    .io_grantStatus_5_valid                                                (grantBuf_grantStatus_5_valid),
    .io_grantStatus_5_set                                                  (grantBuf_grantStatus_5_set),
    .io_grantStatus_5_tag                                                  (grantBuf_grantStatus_5_tag),
    .io_grantStatus_6_valid                                                (grantBuf_grantStatus_6_valid),
    .io_grantStatus_6_set                                                  (grantBuf_grantStatus_6_set),
    .io_grantStatus_6_tag                                                  (grantBuf_grantStatus_6_tag),
    .io_grantStatus_7_valid                                                (grantBuf_grantStatus_7_valid),
    .io_grantStatus_7_set                                                  (grantBuf_grantStatus_7_set),
    .io_grantStatus_7_tag                                                  (grantBuf_grantStatus_7_tag),
    .io_grantStatus_8_valid                                                (grantBuf_grantStatus_8_valid),
    .io_grantStatus_8_set                                                  (grantBuf_grantStatus_8_set),
    .io_grantStatus_8_tag                                                  (grantBuf_grantStatus_8_tag),
    .io_grantStatus_9_valid                                                (grantBuf_grantStatus_9_valid),
    .io_grantStatus_9_set                                                  (grantBuf_grantStatus_9_set),
    .io_grantStatus_9_tag                                                  (grantBuf_grantStatus_9_tag),
    .io_grantStatus_10_valid                                               (grantBuf_grantStatus_10_valid),
    .io_grantStatus_10_set                                                 (grantBuf_grantStatus_10_set),
    .io_grantStatus_10_tag                                                 (grantBuf_grantStatus_10_tag),
    .io_grantStatus_11_valid                                               (grantBuf_grantStatus_11_valid),
    .io_grantStatus_11_set                                                 (grantBuf_grantStatus_11_set),
    .io_grantStatus_11_tag                                                 (grantBuf_grantStatus_11_tag),
    .io_grantStatus_12_valid                                               (grantBuf_grantStatus_12_valid),
    .io_grantStatus_12_set                                                 (grantBuf_grantStatus_12_set),
    .io_grantStatus_12_tag                                                 (grantBuf_grantStatus_12_tag),
    .io_grantStatus_13_valid                                               (grantBuf_grantStatus_13_valid),
    .io_grantStatus_13_set                                                 (grantBuf_grantStatus_13_set),
    .io_grantStatus_13_tag                                                 (grantBuf_grantStatus_13_tag),
    .io_grantStatus_14_valid                                               (grantBuf_grantStatus_14_valid),
    .io_grantStatus_14_set                                                 (grantBuf_grantStatus_14_set),
    .io_grantStatus_14_tag                                                 (grantBuf_grantStatus_14_tag),
    .io_grantStatus_15_valid                                               (grantBuf_grantStatus_15_valid),
    .io_grantStatus_15_set                                                 (grantBuf_grantStatus_15_set),
    .io_grantStatus_15_tag                                                 (grantBuf_grantStatus_15_tag),
    .io_resps_sinkC_valid                                                  (sinkC_resp_valid),
    .io_resps_sinkC_set                                                    (sinkC_resp_set),
    .io_resps_sinkC_tag                                                    (sinkC_resp_tag),
    .io_resps_sinkC_respInfo_opcode                                        (sinkC_resp_respInfo_opcode),
    .io_resps_sinkC_respInfo_param                                         (sinkC_resp_respInfo_param),
    .io_resps_sinkC_respInfo_last                                          (sinkC_resp_respInfo_last),
    .io_resps_sinkC_respInfo_denied                                        (sinkC_resp_respInfo_denied),
    .io_resps_sinkC_respInfo_corrupt                                       (sinkC_resp_respInfo_corrupt),
    .io_resps_rxrsp_valid                                                  (rxrsp_in_valid),
    .io_resps_rxrsp_mshrId                                                 (rxrsp_in_mshrId),
    .io_resps_rxrsp_respInfo_chiOpcode                                     (rxrsp_in_respInfo_chiOpcode),
    .io_resps_rxrsp_respInfo_srcID                                         (rxrsp_in_respInfo_srcID),
    .io_resps_rxrsp_respInfo_dbID                                          (rxrsp_in_respInfo_dbID),
    .io_resps_rxrsp_respInfo_resp                                          (rxrsp_in_respInfo_resp),
    .io_resps_rxrsp_respInfo_pCrdType                                      (rxrsp_in_respInfo_pCrdType),
    .io_resps_rxrsp_respInfo_respErr                                       (rxrsp_in_respInfo_respErr),
    .io_resps_rxrsp_respInfo_traceTag                                      (rxrsp_in_respInfo_traceTag),
    .io_resps_rxdat_valid                                                  (rxdat_in_valid),
    .io_resps_rxdat_mshrId                                                 (rxdat_in_mshrId),
    .io_resps_rxdat_respInfo_last                                          (rxdat_in_respInfo_last),
    .io_resps_rxdat_respInfo_corrupt                                       (rxdat_in_respInfo_corrupt),
    .io_resps_rxdat_respInfo_chiOpcode                                     (rxdat_in_respInfo_chiOpcode),
    .io_resps_rxdat_respInfo_homeNID                                       (rxdat_in_respInfo_homeNID),
    .io_resps_rxdat_respInfo_dbID                                          (rxdat_in_respInfo_dbID),
    .io_resps_rxdat_respInfo_resp                                          (rxdat_in_respInfo_resp),
    .io_resps_rxdat_respInfo_respErr                                       (rxdat_in_respInfo_respErr),
    .io_resps_rxdat_respInfo_traceTag                                      (rxdat_in_respInfo_traceTag),
    .io_releaseBufWriteId                                                  (mshrCtl_releaseBufWriteId),
    .io_dsResp_valid                                                       (mainPipe_dsResp_valid),
    .io_dsResp_bits_mshrId                                                 (mainPipe_dsResp_bits_mshrId),
    .io_dsResp_bits_dataError                                              (mainPipe_dsResp_bits_dataError),
    .io_nestedwb_set                                                       (mainPipe_nestedwb_set),
    .io_nestedwb_tag                                                       (mainPipe_nestedwb_tag),
    .io_nestedwb_c_set_dirty                                               (mainPipe_nestedwb_c_set_dirty),
    .io_nestedwb_c_set_tip                                                 (mainPipe_nestedwb_c_set_tip),
    .io_nestedwb_b_inv_dirty                                               (mainPipe_nestedwb_b_inv_dirty),
    .io_nestedwb_b_toB                                                     (mainPipe_nestedwb_b_toB),
    .io_nestedwb_b_toN                                                     (mainPipe_nestedwb_b_toN),
    .io_nestedwb_b_toClean                                                 (mainPipe_nestedwb_b_toClean),
    .io_nestedwb_denied                                                    (mainPipe_nestedwb_denied),
    .io_nestedwb_corrupt                                                   (mainPipe_nestedwb_corrupt),
    .io_nestedwbDataId_valid                                               (mshrCtl_nestedwbDataId_valid),
    .io_nestedwbDataId_bits                                                (mshrCtl_nestedwbDataId_bits),
    .io_msInfo_0_valid                                                     (mshrCtl_msInfo_0_valid),
    .io_msInfo_0_bits_channel                                              (mshrCtl_msInfo_0_bits_channel),
    .io_msInfo_0_bits_set                                                  (mshrCtl_msInfo_0_bits_set),
    .io_msInfo_0_bits_way                                                  (mshrCtl_msInfo_0_bits_way),
    .io_msInfo_0_bits_reqTag                                               (mshrCtl_msInfo_0_bits_reqTag),
    .io_msInfo_0_bits_willFree                                             (mshrCtl_msInfo_0_bits_willFree),
    .io_msInfo_0_bits_aliasTask                                            (mshrCtl_msInfo_0_bits_aliasTask),
    .io_msInfo_0_bits_needRelease                                          (mshrCtl_msInfo_0_bits_needRelease),
    .io_msInfo_0_bits_blockRefill                                          (mshrCtl_msInfo_0_bits_blockRefill),
    .io_msInfo_0_bits_meta_dirty                                           (mshrCtl_msInfo_0_bits_meta_dirty),
    .io_msInfo_0_bits_meta_state                                           (mshrCtl_msInfo_0_bits_meta_state),
    .io_msInfo_0_bits_meta_clients                                         (mshrCtl_msInfo_0_bits_meta_clients),
    .io_msInfo_0_bits_meta_alias                                           (mshrCtl_msInfo_0_bits_meta_alias),
    .io_msInfo_0_bits_meta_prefetch                                        (mshrCtl_msInfo_0_bits_meta_prefetch),
    .io_msInfo_0_bits_meta_prefetchSrc                                     (mshrCtl_msInfo_0_bits_meta_prefetchSrc),
    .io_msInfo_0_bits_meta_accessed                                        (mshrCtl_msInfo_0_bits_meta_accessed),
    .io_msInfo_0_bits_meta_tagErr                                          (mshrCtl_msInfo_0_bits_meta_tagErr),
    .io_msInfo_0_bits_meta_dataErr                                         (mshrCtl_msInfo_0_bits_meta_dataErr),
    .io_msInfo_0_bits_metaTag                                              (mshrCtl_msInfo_0_bits_metaTag),
    .io_msInfo_0_bits_dirHit                                               (mshrCtl_msInfo_0_bits_dirHit),
    .io_msInfo_0_bits_isAcqOrPrefetch                                      (mshrCtl_msInfo_0_bits_isAcqOrPrefetch),
    .io_msInfo_0_bits_isPrefetch                                           (mshrCtl_msInfo_0_bits_isPrefetch),
    .io_msInfo_0_bits_param                                                (mshrCtl_msInfo_0_bits_param),
    .io_msInfo_0_bits_mergeA                                               (mshrCtl_msInfo_0_bits_mergeA),
    .io_msInfo_0_bits_w_grantfirst                                         (mshrCtl_msInfo_0_bits_w_grantfirst),
    .io_msInfo_0_bits_s_release                                            (mshrCtl_msInfo_0_bits_s_release),
    .io_msInfo_0_bits_s_refill                                             (mshrCtl_msInfo_0_bits_s_refill),
    .io_msInfo_0_bits_s_cmoresp                                            (mshrCtl_msInfo_0_bits_s_cmoresp),
    .io_msInfo_0_bits_s_cmometaw                                           (mshrCtl_msInfo_0_bits_s_cmometaw),
    .io_msInfo_0_bits_w_releaseack                                         (mshrCtl_msInfo_0_bits_w_releaseack),
    .io_msInfo_0_bits_w_replResp                                           (mshrCtl_msInfo_0_bits_w_replResp),
    .io_msInfo_0_bits_w_rprobeacklast                                      (mshrCtl_msInfo_0_bits_w_rprobeacklast),
    .io_msInfo_0_bits_replaceData                                          (mshrCtl_msInfo_0_bits_replaceData),
    .io_msInfo_0_bits_releaseToClean                                       (mshrCtl_msInfo_0_bits_releaseToClean),
    .io_msInfo_1_valid                                                     (mshrCtl_msInfo_1_valid),
    .io_msInfo_1_bits_channel                                              (mshrCtl_msInfo_1_bits_channel),
    .io_msInfo_1_bits_set                                                  (mshrCtl_msInfo_1_bits_set),
    .io_msInfo_1_bits_way                                                  (mshrCtl_msInfo_1_bits_way),
    .io_msInfo_1_bits_reqTag                                               (mshrCtl_msInfo_1_bits_reqTag),
    .io_msInfo_1_bits_willFree                                             (mshrCtl_msInfo_1_bits_willFree),
    .io_msInfo_1_bits_aliasTask                                            (mshrCtl_msInfo_1_bits_aliasTask),
    .io_msInfo_1_bits_needRelease                                          (mshrCtl_msInfo_1_bits_needRelease),
    .io_msInfo_1_bits_blockRefill                                          (mshrCtl_msInfo_1_bits_blockRefill),
    .io_msInfo_1_bits_meta_dirty                                           (mshrCtl_msInfo_1_bits_meta_dirty),
    .io_msInfo_1_bits_meta_state                                           (mshrCtl_msInfo_1_bits_meta_state),
    .io_msInfo_1_bits_meta_clients                                         (mshrCtl_msInfo_1_bits_meta_clients),
    .io_msInfo_1_bits_meta_alias                                           (mshrCtl_msInfo_1_bits_meta_alias),
    .io_msInfo_1_bits_meta_prefetch                                        (mshrCtl_msInfo_1_bits_meta_prefetch),
    .io_msInfo_1_bits_meta_prefetchSrc                                     (mshrCtl_msInfo_1_bits_meta_prefetchSrc),
    .io_msInfo_1_bits_meta_accessed                                        (mshrCtl_msInfo_1_bits_meta_accessed),
    .io_msInfo_1_bits_meta_tagErr                                          (mshrCtl_msInfo_1_bits_meta_tagErr),
    .io_msInfo_1_bits_meta_dataErr                                         (mshrCtl_msInfo_1_bits_meta_dataErr),
    .io_msInfo_1_bits_metaTag                                              (mshrCtl_msInfo_1_bits_metaTag),
    .io_msInfo_1_bits_dirHit                                               (mshrCtl_msInfo_1_bits_dirHit),
    .io_msInfo_1_bits_isAcqOrPrefetch                                      (mshrCtl_msInfo_1_bits_isAcqOrPrefetch),
    .io_msInfo_1_bits_isPrefetch                                           (mshrCtl_msInfo_1_bits_isPrefetch),
    .io_msInfo_1_bits_param                                                (mshrCtl_msInfo_1_bits_param),
    .io_msInfo_1_bits_mergeA                                               (mshrCtl_msInfo_1_bits_mergeA),
    .io_msInfo_1_bits_w_grantfirst                                         (mshrCtl_msInfo_1_bits_w_grantfirst),
    .io_msInfo_1_bits_s_release                                            (mshrCtl_msInfo_1_bits_s_release),
    .io_msInfo_1_bits_s_refill                                             (mshrCtl_msInfo_1_bits_s_refill),
    .io_msInfo_1_bits_s_cmoresp                                            (mshrCtl_msInfo_1_bits_s_cmoresp),
    .io_msInfo_1_bits_s_cmometaw                                           (mshrCtl_msInfo_1_bits_s_cmometaw),
    .io_msInfo_1_bits_w_releaseack                                         (mshrCtl_msInfo_1_bits_w_releaseack),
    .io_msInfo_1_bits_w_replResp                                           (mshrCtl_msInfo_1_bits_w_replResp),
    .io_msInfo_1_bits_w_rprobeacklast                                      (mshrCtl_msInfo_1_bits_w_rprobeacklast),
    .io_msInfo_1_bits_replaceData                                          (mshrCtl_msInfo_1_bits_replaceData),
    .io_msInfo_1_bits_releaseToClean                                       (mshrCtl_msInfo_1_bits_releaseToClean),
    .io_msInfo_2_valid                                                     (mshrCtl_msInfo_2_valid),
    .io_msInfo_2_bits_channel                                              (mshrCtl_msInfo_2_bits_channel),
    .io_msInfo_2_bits_set                                                  (mshrCtl_msInfo_2_bits_set),
    .io_msInfo_2_bits_way                                                  (mshrCtl_msInfo_2_bits_way),
    .io_msInfo_2_bits_reqTag                                               (mshrCtl_msInfo_2_bits_reqTag),
    .io_msInfo_2_bits_willFree                                             (mshrCtl_msInfo_2_bits_willFree),
    .io_msInfo_2_bits_aliasTask                                            (mshrCtl_msInfo_2_bits_aliasTask),
    .io_msInfo_2_bits_needRelease                                          (mshrCtl_msInfo_2_bits_needRelease),
    .io_msInfo_2_bits_blockRefill                                          (mshrCtl_msInfo_2_bits_blockRefill),
    .io_msInfo_2_bits_meta_dirty                                           (mshrCtl_msInfo_2_bits_meta_dirty),
    .io_msInfo_2_bits_meta_state                                           (mshrCtl_msInfo_2_bits_meta_state),
    .io_msInfo_2_bits_meta_clients                                         (mshrCtl_msInfo_2_bits_meta_clients),
    .io_msInfo_2_bits_meta_alias                                           (mshrCtl_msInfo_2_bits_meta_alias),
    .io_msInfo_2_bits_meta_prefetch                                        (mshrCtl_msInfo_2_bits_meta_prefetch),
    .io_msInfo_2_bits_meta_prefetchSrc                                     (mshrCtl_msInfo_2_bits_meta_prefetchSrc),
    .io_msInfo_2_bits_meta_accessed                                        (mshrCtl_msInfo_2_bits_meta_accessed),
    .io_msInfo_2_bits_meta_tagErr                                          (mshrCtl_msInfo_2_bits_meta_tagErr),
    .io_msInfo_2_bits_meta_dataErr                                         (mshrCtl_msInfo_2_bits_meta_dataErr),
    .io_msInfo_2_bits_metaTag                                              (mshrCtl_msInfo_2_bits_metaTag),
    .io_msInfo_2_bits_dirHit                                               (mshrCtl_msInfo_2_bits_dirHit),
    .io_msInfo_2_bits_isAcqOrPrefetch                                      (mshrCtl_msInfo_2_bits_isAcqOrPrefetch),
    .io_msInfo_2_bits_isPrefetch                                           (mshrCtl_msInfo_2_bits_isPrefetch),
    .io_msInfo_2_bits_param                                                (mshrCtl_msInfo_2_bits_param),
    .io_msInfo_2_bits_mergeA                                               (mshrCtl_msInfo_2_bits_mergeA),
    .io_msInfo_2_bits_w_grantfirst                                         (mshrCtl_msInfo_2_bits_w_grantfirst),
    .io_msInfo_2_bits_s_release                                            (mshrCtl_msInfo_2_bits_s_release),
    .io_msInfo_2_bits_s_refill                                             (mshrCtl_msInfo_2_bits_s_refill),
    .io_msInfo_2_bits_s_cmoresp                                            (mshrCtl_msInfo_2_bits_s_cmoresp),
    .io_msInfo_2_bits_s_cmometaw                                           (mshrCtl_msInfo_2_bits_s_cmometaw),
    .io_msInfo_2_bits_w_releaseack                                         (mshrCtl_msInfo_2_bits_w_releaseack),
    .io_msInfo_2_bits_w_replResp                                           (mshrCtl_msInfo_2_bits_w_replResp),
    .io_msInfo_2_bits_w_rprobeacklast                                      (mshrCtl_msInfo_2_bits_w_rprobeacklast),
    .io_msInfo_2_bits_replaceData                                          (mshrCtl_msInfo_2_bits_replaceData),
    .io_msInfo_2_bits_releaseToClean                                       (mshrCtl_msInfo_2_bits_releaseToClean),
    .io_msInfo_3_valid                                                     (mshrCtl_msInfo_3_valid),
    .io_msInfo_3_bits_channel                                              (mshrCtl_msInfo_3_bits_channel),
    .io_msInfo_3_bits_set                                                  (mshrCtl_msInfo_3_bits_set),
    .io_msInfo_3_bits_way                                                  (mshrCtl_msInfo_3_bits_way),
    .io_msInfo_3_bits_reqTag                                               (mshrCtl_msInfo_3_bits_reqTag),
    .io_msInfo_3_bits_willFree                                             (mshrCtl_msInfo_3_bits_willFree),
    .io_msInfo_3_bits_aliasTask                                            (mshrCtl_msInfo_3_bits_aliasTask),
    .io_msInfo_3_bits_needRelease                                          (mshrCtl_msInfo_3_bits_needRelease),
    .io_msInfo_3_bits_blockRefill                                          (mshrCtl_msInfo_3_bits_blockRefill),
    .io_msInfo_3_bits_meta_dirty                                           (mshrCtl_msInfo_3_bits_meta_dirty),
    .io_msInfo_3_bits_meta_state                                           (mshrCtl_msInfo_3_bits_meta_state),
    .io_msInfo_3_bits_meta_clients                                         (mshrCtl_msInfo_3_bits_meta_clients),
    .io_msInfo_3_bits_meta_alias                                           (mshrCtl_msInfo_3_bits_meta_alias),
    .io_msInfo_3_bits_meta_prefetch                                        (mshrCtl_msInfo_3_bits_meta_prefetch),
    .io_msInfo_3_bits_meta_prefetchSrc                                     (mshrCtl_msInfo_3_bits_meta_prefetchSrc),
    .io_msInfo_3_bits_meta_accessed                                        (mshrCtl_msInfo_3_bits_meta_accessed),
    .io_msInfo_3_bits_meta_tagErr                                          (mshrCtl_msInfo_3_bits_meta_tagErr),
    .io_msInfo_3_bits_meta_dataErr                                         (mshrCtl_msInfo_3_bits_meta_dataErr),
    .io_msInfo_3_bits_metaTag                                              (mshrCtl_msInfo_3_bits_metaTag),
    .io_msInfo_3_bits_dirHit                                               (mshrCtl_msInfo_3_bits_dirHit),
    .io_msInfo_3_bits_isAcqOrPrefetch                                      (mshrCtl_msInfo_3_bits_isAcqOrPrefetch),
    .io_msInfo_3_bits_isPrefetch                                           (mshrCtl_msInfo_3_bits_isPrefetch),
    .io_msInfo_3_bits_param                                                (mshrCtl_msInfo_3_bits_param),
    .io_msInfo_3_bits_mergeA                                               (mshrCtl_msInfo_3_bits_mergeA),
    .io_msInfo_3_bits_w_grantfirst                                         (mshrCtl_msInfo_3_bits_w_grantfirst),
    .io_msInfo_3_bits_s_release                                            (mshrCtl_msInfo_3_bits_s_release),
    .io_msInfo_3_bits_s_refill                                             (mshrCtl_msInfo_3_bits_s_refill),
    .io_msInfo_3_bits_s_cmoresp                                            (mshrCtl_msInfo_3_bits_s_cmoresp),
    .io_msInfo_3_bits_s_cmometaw                                           (mshrCtl_msInfo_3_bits_s_cmometaw),
    .io_msInfo_3_bits_w_releaseack                                         (mshrCtl_msInfo_3_bits_w_releaseack),
    .io_msInfo_3_bits_w_replResp                                           (mshrCtl_msInfo_3_bits_w_replResp),
    .io_msInfo_3_bits_w_rprobeacklast                                      (mshrCtl_msInfo_3_bits_w_rprobeacklast),
    .io_msInfo_3_bits_replaceData                                          (mshrCtl_msInfo_3_bits_replaceData),
    .io_msInfo_3_bits_releaseToClean                                       (mshrCtl_msInfo_3_bits_releaseToClean),
    .io_msInfo_4_valid                                                     (mshrCtl_msInfo_4_valid),
    .io_msInfo_4_bits_channel                                              (mshrCtl_msInfo_4_bits_channel),
    .io_msInfo_4_bits_set                                                  (mshrCtl_msInfo_4_bits_set),
    .io_msInfo_4_bits_way                                                  (mshrCtl_msInfo_4_bits_way),
    .io_msInfo_4_bits_reqTag                                               (mshrCtl_msInfo_4_bits_reqTag),
    .io_msInfo_4_bits_willFree                                             (mshrCtl_msInfo_4_bits_willFree),
    .io_msInfo_4_bits_aliasTask                                            (mshrCtl_msInfo_4_bits_aliasTask),
    .io_msInfo_4_bits_needRelease                                          (mshrCtl_msInfo_4_bits_needRelease),
    .io_msInfo_4_bits_blockRefill                                          (mshrCtl_msInfo_4_bits_blockRefill),
    .io_msInfo_4_bits_meta_dirty                                           (mshrCtl_msInfo_4_bits_meta_dirty),
    .io_msInfo_4_bits_meta_state                                           (mshrCtl_msInfo_4_bits_meta_state),
    .io_msInfo_4_bits_meta_clients                                         (mshrCtl_msInfo_4_bits_meta_clients),
    .io_msInfo_4_bits_meta_alias                                           (mshrCtl_msInfo_4_bits_meta_alias),
    .io_msInfo_4_bits_meta_prefetch                                        (mshrCtl_msInfo_4_bits_meta_prefetch),
    .io_msInfo_4_bits_meta_prefetchSrc                                     (mshrCtl_msInfo_4_bits_meta_prefetchSrc),
    .io_msInfo_4_bits_meta_accessed                                        (mshrCtl_msInfo_4_bits_meta_accessed),
    .io_msInfo_4_bits_meta_tagErr                                          (mshrCtl_msInfo_4_bits_meta_tagErr),
    .io_msInfo_4_bits_meta_dataErr                                         (mshrCtl_msInfo_4_bits_meta_dataErr),
    .io_msInfo_4_bits_metaTag                                              (mshrCtl_msInfo_4_bits_metaTag),
    .io_msInfo_4_bits_dirHit                                               (mshrCtl_msInfo_4_bits_dirHit),
    .io_msInfo_4_bits_isAcqOrPrefetch                                      (mshrCtl_msInfo_4_bits_isAcqOrPrefetch),
    .io_msInfo_4_bits_isPrefetch                                           (mshrCtl_msInfo_4_bits_isPrefetch),
    .io_msInfo_4_bits_param                                                (mshrCtl_msInfo_4_bits_param),
    .io_msInfo_4_bits_mergeA                                               (mshrCtl_msInfo_4_bits_mergeA),
    .io_msInfo_4_bits_w_grantfirst                                         (mshrCtl_msInfo_4_bits_w_grantfirst),
    .io_msInfo_4_bits_s_release                                            (mshrCtl_msInfo_4_bits_s_release),
    .io_msInfo_4_bits_s_refill                                             (mshrCtl_msInfo_4_bits_s_refill),
    .io_msInfo_4_bits_s_cmoresp                                            (mshrCtl_msInfo_4_bits_s_cmoresp),
    .io_msInfo_4_bits_s_cmometaw                                           (mshrCtl_msInfo_4_bits_s_cmometaw),
    .io_msInfo_4_bits_w_releaseack                                         (mshrCtl_msInfo_4_bits_w_releaseack),
    .io_msInfo_4_bits_w_replResp                                           (mshrCtl_msInfo_4_bits_w_replResp),
    .io_msInfo_4_bits_w_rprobeacklast                                      (mshrCtl_msInfo_4_bits_w_rprobeacklast),
    .io_msInfo_4_bits_replaceData                                          (mshrCtl_msInfo_4_bits_replaceData),
    .io_msInfo_4_bits_releaseToClean                                       (mshrCtl_msInfo_4_bits_releaseToClean),
    .io_msInfo_5_valid                                                     (mshrCtl_msInfo_5_valid),
    .io_msInfo_5_bits_channel                                              (mshrCtl_msInfo_5_bits_channel),
    .io_msInfo_5_bits_set                                                  (mshrCtl_msInfo_5_bits_set),
    .io_msInfo_5_bits_way                                                  (mshrCtl_msInfo_5_bits_way),
    .io_msInfo_5_bits_reqTag                                               (mshrCtl_msInfo_5_bits_reqTag),
    .io_msInfo_5_bits_willFree                                             (mshrCtl_msInfo_5_bits_willFree),
    .io_msInfo_5_bits_aliasTask                                            (mshrCtl_msInfo_5_bits_aliasTask),
    .io_msInfo_5_bits_needRelease                                          (mshrCtl_msInfo_5_bits_needRelease),
    .io_msInfo_5_bits_blockRefill                                          (mshrCtl_msInfo_5_bits_blockRefill),
    .io_msInfo_5_bits_meta_dirty                                           (mshrCtl_msInfo_5_bits_meta_dirty),
    .io_msInfo_5_bits_meta_state                                           (mshrCtl_msInfo_5_bits_meta_state),
    .io_msInfo_5_bits_meta_clients                                         (mshrCtl_msInfo_5_bits_meta_clients),
    .io_msInfo_5_bits_meta_alias                                           (mshrCtl_msInfo_5_bits_meta_alias),
    .io_msInfo_5_bits_meta_prefetch                                        (mshrCtl_msInfo_5_bits_meta_prefetch),
    .io_msInfo_5_bits_meta_prefetchSrc                                     (mshrCtl_msInfo_5_bits_meta_prefetchSrc),
    .io_msInfo_5_bits_meta_accessed                                        (mshrCtl_msInfo_5_bits_meta_accessed),
    .io_msInfo_5_bits_meta_tagErr                                          (mshrCtl_msInfo_5_bits_meta_tagErr),
    .io_msInfo_5_bits_meta_dataErr                                         (mshrCtl_msInfo_5_bits_meta_dataErr),
    .io_msInfo_5_bits_metaTag                                              (mshrCtl_msInfo_5_bits_metaTag),
    .io_msInfo_5_bits_dirHit                                               (mshrCtl_msInfo_5_bits_dirHit),
    .io_msInfo_5_bits_isAcqOrPrefetch                                      (mshrCtl_msInfo_5_bits_isAcqOrPrefetch),
    .io_msInfo_5_bits_isPrefetch                                           (mshrCtl_msInfo_5_bits_isPrefetch),
    .io_msInfo_5_bits_param                                                (mshrCtl_msInfo_5_bits_param),
    .io_msInfo_5_bits_mergeA                                               (mshrCtl_msInfo_5_bits_mergeA),
    .io_msInfo_5_bits_w_grantfirst                                         (mshrCtl_msInfo_5_bits_w_grantfirst),
    .io_msInfo_5_bits_s_release                                            (mshrCtl_msInfo_5_bits_s_release),
    .io_msInfo_5_bits_s_refill                                             (mshrCtl_msInfo_5_bits_s_refill),
    .io_msInfo_5_bits_s_cmoresp                                            (mshrCtl_msInfo_5_bits_s_cmoresp),
    .io_msInfo_5_bits_s_cmometaw                                           (mshrCtl_msInfo_5_bits_s_cmometaw),
    .io_msInfo_5_bits_w_releaseack                                         (mshrCtl_msInfo_5_bits_w_releaseack),
    .io_msInfo_5_bits_w_replResp                                           (mshrCtl_msInfo_5_bits_w_replResp),
    .io_msInfo_5_bits_w_rprobeacklast                                      (mshrCtl_msInfo_5_bits_w_rprobeacklast),
    .io_msInfo_5_bits_replaceData                                          (mshrCtl_msInfo_5_bits_replaceData),
    .io_msInfo_5_bits_releaseToClean                                       (mshrCtl_msInfo_5_bits_releaseToClean),
    .io_msInfo_6_valid                                                     (mshrCtl_msInfo_6_valid),
    .io_msInfo_6_bits_channel                                              (mshrCtl_msInfo_6_bits_channel),
    .io_msInfo_6_bits_set                                                  (mshrCtl_msInfo_6_bits_set),
    .io_msInfo_6_bits_way                                                  (mshrCtl_msInfo_6_bits_way),
    .io_msInfo_6_bits_reqTag                                               (mshrCtl_msInfo_6_bits_reqTag),
    .io_msInfo_6_bits_willFree                                             (mshrCtl_msInfo_6_bits_willFree),
    .io_msInfo_6_bits_aliasTask                                            (mshrCtl_msInfo_6_bits_aliasTask),
    .io_msInfo_6_bits_needRelease                                          (mshrCtl_msInfo_6_bits_needRelease),
    .io_msInfo_6_bits_blockRefill                                          (mshrCtl_msInfo_6_bits_blockRefill),
    .io_msInfo_6_bits_meta_dirty                                           (mshrCtl_msInfo_6_bits_meta_dirty),
    .io_msInfo_6_bits_meta_state                                           (mshrCtl_msInfo_6_bits_meta_state),
    .io_msInfo_6_bits_meta_clients                                         (mshrCtl_msInfo_6_bits_meta_clients),
    .io_msInfo_6_bits_meta_alias                                           (mshrCtl_msInfo_6_bits_meta_alias),
    .io_msInfo_6_bits_meta_prefetch                                        (mshrCtl_msInfo_6_bits_meta_prefetch),
    .io_msInfo_6_bits_meta_prefetchSrc                                     (mshrCtl_msInfo_6_bits_meta_prefetchSrc),
    .io_msInfo_6_bits_meta_accessed                                        (mshrCtl_msInfo_6_bits_meta_accessed),
    .io_msInfo_6_bits_meta_tagErr                                          (mshrCtl_msInfo_6_bits_meta_tagErr),
    .io_msInfo_6_bits_meta_dataErr                                         (mshrCtl_msInfo_6_bits_meta_dataErr),
    .io_msInfo_6_bits_metaTag                                              (mshrCtl_msInfo_6_bits_metaTag),
    .io_msInfo_6_bits_dirHit                                               (mshrCtl_msInfo_6_bits_dirHit),
    .io_msInfo_6_bits_isAcqOrPrefetch                                      (mshrCtl_msInfo_6_bits_isAcqOrPrefetch),
    .io_msInfo_6_bits_isPrefetch                                           (mshrCtl_msInfo_6_bits_isPrefetch),
    .io_msInfo_6_bits_param                                                (mshrCtl_msInfo_6_bits_param),
    .io_msInfo_6_bits_mergeA                                               (mshrCtl_msInfo_6_bits_mergeA),
    .io_msInfo_6_bits_w_grantfirst                                         (mshrCtl_msInfo_6_bits_w_grantfirst),
    .io_msInfo_6_bits_s_release                                            (mshrCtl_msInfo_6_bits_s_release),
    .io_msInfo_6_bits_s_refill                                             (mshrCtl_msInfo_6_bits_s_refill),
    .io_msInfo_6_bits_s_cmoresp                                            (mshrCtl_msInfo_6_bits_s_cmoresp),
    .io_msInfo_6_bits_s_cmometaw                                           (mshrCtl_msInfo_6_bits_s_cmometaw),
    .io_msInfo_6_bits_w_releaseack                                         (mshrCtl_msInfo_6_bits_w_releaseack),
    .io_msInfo_6_bits_w_replResp                                           (mshrCtl_msInfo_6_bits_w_replResp),
    .io_msInfo_6_bits_w_rprobeacklast                                      (mshrCtl_msInfo_6_bits_w_rprobeacklast),
    .io_msInfo_6_bits_replaceData                                          (mshrCtl_msInfo_6_bits_replaceData),
    .io_msInfo_6_bits_releaseToClean                                       (mshrCtl_msInfo_6_bits_releaseToClean),
    .io_msInfo_7_valid                                                     (mshrCtl_msInfo_7_valid),
    .io_msInfo_7_bits_channel                                              (mshrCtl_msInfo_7_bits_channel),
    .io_msInfo_7_bits_set                                                  (mshrCtl_msInfo_7_bits_set),
    .io_msInfo_7_bits_way                                                  (mshrCtl_msInfo_7_bits_way),
    .io_msInfo_7_bits_reqTag                                               (mshrCtl_msInfo_7_bits_reqTag),
    .io_msInfo_7_bits_willFree                                             (mshrCtl_msInfo_7_bits_willFree),
    .io_msInfo_7_bits_aliasTask                                            (mshrCtl_msInfo_7_bits_aliasTask),
    .io_msInfo_7_bits_needRelease                                          (mshrCtl_msInfo_7_bits_needRelease),
    .io_msInfo_7_bits_blockRefill                                          (mshrCtl_msInfo_7_bits_blockRefill),
    .io_msInfo_7_bits_meta_dirty                                           (mshrCtl_msInfo_7_bits_meta_dirty),
    .io_msInfo_7_bits_meta_state                                           (mshrCtl_msInfo_7_bits_meta_state),
    .io_msInfo_7_bits_meta_clients                                         (mshrCtl_msInfo_7_bits_meta_clients),
    .io_msInfo_7_bits_meta_alias                                           (mshrCtl_msInfo_7_bits_meta_alias),
    .io_msInfo_7_bits_meta_prefetch                                        (mshrCtl_msInfo_7_bits_meta_prefetch),
    .io_msInfo_7_bits_meta_prefetchSrc                                     (mshrCtl_msInfo_7_bits_meta_prefetchSrc),
    .io_msInfo_7_bits_meta_accessed                                        (mshrCtl_msInfo_7_bits_meta_accessed),
    .io_msInfo_7_bits_meta_tagErr                                          (mshrCtl_msInfo_7_bits_meta_tagErr),
    .io_msInfo_7_bits_meta_dataErr                                         (mshrCtl_msInfo_7_bits_meta_dataErr),
    .io_msInfo_7_bits_metaTag                                              (mshrCtl_msInfo_7_bits_metaTag),
    .io_msInfo_7_bits_dirHit                                               (mshrCtl_msInfo_7_bits_dirHit),
    .io_msInfo_7_bits_isAcqOrPrefetch                                      (mshrCtl_msInfo_7_bits_isAcqOrPrefetch),
    .io_msInfo_7_bits_isPrefetch                                           (mshrCtl_msInfo_7_bits_isPrefetch),
    .io_msInfo_7_bits_param                                                (mshrCtl_msInfo_7_bits_param),
    .io_msInfo_7_bits_mergeA                                               (mshrCtl_msInfo_7_bits_mergeA),
    .io_msInfo_7_bits_w_grantfirst                                         (mshrCtl_msInfo_7_bits_w_grantfirst),
    .io_msInfo_7_bits_s_release                                            (mshrCtl_msInfo_7_bits_s_release),
    .io_msInfo_7_bits_s_refill                                             (mshrCtl_msInfo_7_bits_s_refill),
    .io_msInfo_7_bits_s_cmoresp                                            (mshrCtl_msInfo_7_bits_s_cmoresp),
    .io_msInfo_7_bits_s_cmometaw                                           (mshrCtl_msInfo_7_bits_s_cmometaw),
    .io_msInfo_7_bits_w_releaseack                                         (mshrCtl_msInfo_7_bits_w_releaseack),
    .io_msInfo_7_bits_w_replResp                                           (mshrCtl_msInfo_7_bits_w_replResp),
    .io_msInfo_7_bits_w_rprobeacklast                                      (mshrCtl_msInfo_7_bits_w_rprobeacklast),
    .io_msInfo_7_bits_replaceData                                          (mshrCtl_msInfo_7_bits_replaceData),
    .io_msInfo_7_bits_releaseToClean                                       (mshrCtl_msInfo_7_bits_releaseToClean),
    .io_msInfo_8_valid                                                     (mshrCtl_msInfo_8_valid),
    .io_msInfo_8_bits_channel                                              (mshrCtl_msInfo_8_bits_channel),
    .io_msInfo_8_bits_set                                                  (mshrCtl_msInfo_8_bits_set),
    .io_msInfo_8_bits_way                                                  (mshrCtl_msInfo_8_bits_way),
    .io_msInfo_8_bits_reqTag                                               (mshrCtl_msInfo_8_bits_reqTag),
    .io_msInfo_8_bits_willFree                                             (mshrCtl_msInfo_8_bits_willFree),
    .io_msInfo_8_bits_aliasTask                                            (mshrCtl_msInfo_8_bits_aliasTask),
    .io_msInfo_8_bits_needRelease                                          (mshrCtl_msInfo_8_bits_needRelease),
    .io_msInfo_8_bits_blockRefill                                          (mshrCtl_msInfo_8_bits_blockRefill),
    .io_msInfo_8_bits_meta_dirty                                           (mshrCtl_msInfo_8_bits_meta_dirty),
    .io_msInfo_8_bits_meta_state                                           (mshrCtl_msInfo_8_bits_meta_state),
    .io_msInfo_8_bits_meta_clients                                         (mshrCtl_msInfo_8_bits_meta_clients),
    .io_msInfo_8_bits_meta_alias                                           (mshrCtl_msInfo_8_bits_meta_alias),
    .io_msInfo_8_bits_meta_prefetch                                        (mshrCtl_msInfo_8_bits_meta_prefetch),
    .io_msInfo_8_bits_meta_prefetchSrc                                     (mshrCtl_msInfo_8_bits_meta_prefetchSrc),
    .io_msInfo_8_bits_meta_accessed                                        (mshrCtl_msInfo_8_bits_meta_accessed),
    .io_msInfo_8_bits_meta_tagErr                                          (mshrCtl_msInfo_8_bits_meta_tagErr),
    .io_msInfo_8_bits_meta_dataErr                                         (mshrCtl_msInfo_8_bits_meta_dataErr),
    .io_msInfo_8_bits_metaTag                                              (mshrCtl_msInfo_8_bits_metaTag),
    .io_msInfo_8_bits_dirHit                                               (mshrCtl_msInfo_8_bits_dirHit),
    .io_msInfo_8_bits_isAcqOrPrefetch                                      (mshrCtl_msInfo_8_bits_isAcqOrPrefetch),
    .io_msInfo_8_bits_isPrefetch                                           (mshrCtl_msInfo_8_bits_isPrefetch),
    .io_msInfo_8_bits_param                                                (mshrCtl_msInfo_8_bits_param),
    .io_msInfo_8_bits_mergeA                                               (mshrCtl_msInfo_8_bits_mergeA),
    .io_msInfo_8_bits_w_grantfirst                                         (mshrCtl_msInfo_8_bits_w_grantfirst),
    .io_msInfo_8_bits_s_release                                            (mshrCtl_msInfo_8_bits_s_release),
    .io_msInfo_8_bits_s_refill                                             (mshrCtl_msInfo_8_bits_s_refill),
    .io_msInfo_8_bits_s_cmoresp                                            (mshrCtl_msInfo_8_bits_s_cmoresp),
    .io_msInfo_8_bits_s_cmometaw                                           (mshrCtl_msInfo_8_bits_s_cmometaw),
    .io_msInfo_8_bits_w_releaseack                                         (mshrCtl_msInfo_8_bits_w_releaseack),
    .io_msInfo_8_bits_w_replResp                                           (mshrCtl_msInfo_8_bits_w_replResp),
    .io_msInfo_8_bits_w_rprobeacklast                                      (mshrCtl_msInfo_8_bits_w_rprobeacklast),
    .io_msInfo_8_bits_replaceData                                          (mshrCtl_msInfo_8_bits_replaceData),
    .io_msInfo_8_bits_releaseToClean                                       (mshrCtl_msInfo_8_bits_releaseToClean),
    .io_msInfo_9_valid                                                     (mshrCtl_msInfo_9_valid),
    .io_msInfo_9_bits_channel                                              (mshrCtl_msInfo_9_bits_channel),
    .io_msInfo_9_bits_set                                                  (mshrCtl_msInfo_9_bits_set),
    .io_msInfo_9_bits_way                                                  (mshrCtl_msInfo_9_bits_way),
    .io_msInfo_9_bits_reqTag                                               (mshrCtl_msInfo_9_bits_reqTag),
    .io_msInfo_9_bits_willFree                                             (mshrCtl_msInfo_9_bits_willFree),
    .io_msInfo_9_bits_aliasTask                                            (mshrCtl_msInfo_9_bits_aliasTask),
    .io_msInfo_9_bits_needRelease                                          (mshrCtl_msInfo_9_bits_needRelease),
    .io_msInfo_9_bits_blockRefill                                          (mshrCtl_msInfo_9_bits_blockRefill),
    .io_msInfo_9_bits_meta_dirty                                           (mshrCtl_msInfo_9_bits_meta_dirty),
    .io_msInfo_9_bits_meta_state                                           (mshrCtl_msInfo_9_bits_meta_state),
    .io_msInfo_9_bits_meta_clients                                         (mshrCtl_msInfo_9_bits_meta_clients),
    .io_msInfo_9_bits_meta_alias                                           (mshrCtl_msInfo_9_bits_meta_alias),
    .io_msInfo_9_bits_meta_prefetch                                        (mshrCtl_msInfo_9_bits_meta_prefetch),
    .io_msInfo_9_bits_meta_prefetchSrc                                     (mshrCtl_msInfo_9_bits_meta_prefetchSrc),
    .io_msInfo_9_bits_meta_accessed                                        (mshrCtl_msInfo_9_bits_meta_accessed),
    .io_msInfo_9_bits_meta_tagErr                                          (mshrCtl_msInfo_9_bits_meta_tagErr),
    .io_msInfo_9_bits_meta_dataErr                                         (mshrCtl_msInfo_9_bits_meta_dataErr),
    .io_msInfo_9_bits_metaTag                                              (mshrCtl_msInfo_9_bits_metaTag),
    .io_msInfo_9_bits_dirHit                                               (mshrCtl_msInfo_9_bits_dirHit),
    .io_msInfo_9_bits_isAcqOrPrefetch                                      (mshrCtl_msInfo_9_bits_isAcqOrPrefetch),
    .io_msInfo_9_bits_isPrefetch                                           (mshrCtl_msInfo_9_bits_isPrefetch),
    .io_msInfo_9_bits_param                                                (mshrCtl_msInfo_9_bits_param),
    .io_msInfo_9_bits_mergeA                                               (mshrCtl_msInfo_9_bits_mergeA),
    .io_msInfo_9_bits_w_grantfirst                                         (mshrCtl_msInfo_9_bits_w_grantfirst),
    .io_msInfo_9_bits_s_release                                            (mshrCtl_msInfo_9_bits_s_release),
    .io_msInfo_9_bits_s_refill                                             (mshrCtl_msInfo_9_bits_s_refill),
    .io_msInfo_9_bits_s_cmoresp                                            (mshrCtl_msInfo_9_bits_s_cmoresp),
    .io_msInfo_9_bits_s_cmometaw                                           (mshrCtl_msInfo_9_bits_s_cmometaw),
    .io_msInfo_9_bits_w_releaseack                                         (mshrCtl_msInfo_9_bits_w_releaseack),
    .io_msInfo_9_bits_w_replResp                                           (mshrCtl_msInfo_9_bits_w_replResp),
    .io_msInfo_9_bits_w_rprobeacklast                                      (mshrCtl_msInfo_9_bits_w_rprobeacklast),
    .io_msInfo_9_bits_replaceData                                          (mshrCtl_msInfo_9_bits_replaceData),
    .io_msInfo_9_bits_releaseToClean                                       (mshrCtl_msInfo_9_bits_releaseToClean),
    .io_msInfo_10_valid                                                    (mshrCtl_msInfo_10_valid),
    .io_msInfo_10_bits_channel                                             (mshrCtl_msInfo_10_bits_channel),
    .io_msInfo_10_bits_set                                                 (mshrCtl_msInfo_10_bits_set),
    .io_msInfo_10_bits_way                                                 (mshrCtl_msInfo_10_bits_way),
    .io_msInfo_10_bits_reqTag                                              (mshrCtl_msInfo_10_bits_reqTag),
    .io_msInfo_10_bits_willFree                                            (mshrCtl_msInfo_10_bits_willFree),
    .io_msInfo_10_bits_aliasTask                                           (mshrCtl_msInfo_10_bits_aliasTask),
    .io_msInfo_10_bits_needRelease                                         (mshrCtl_msInfo_10_bits_needRelease),
    .io_msInfo_10_bits_blockRefill                                         (mshrCtl_msInfo_10_bits_blockRefill),
    .io_msInfo_10_bits_meta_dirty                                          (mshrCtl_msInfo_10_bits_meta_dirty),
    .io_msInfo_10_bits_meta_state                                          (mshrCtl_msInfo_10_bits_meta_state),
    .io_msInfo_10_bits_meta_clients                                        (mshrCtl_msInfo_10_bits_meta_clients),
    .io_msInfo_10_bits_meta_alias                                          (mshrCtl_msInfo_10_bits_meta_alias),
    .io_msInfo_10_bits_meta_prefetch                                       (mshrCtl_msInfo_10_bits_meta_prefetch),
    .io_msInfo_10_bits_meta_prefetchSrc                                    (mshrCtl_msInfo_10_bits_meta_prefetchSrc),
    .io_msInfo_10_bits_meta_accessed                                       (mshrCtl_msInfo_10_bits_meta_accessed),
    .io_msInfo_10_bits_meta_tagErr                                         (mshrCtl_msInfo_10_bits_meta_tagErr),
    .io_msInfo_10_bits_meta_dataErr                                        (mshrCtl_msInfo_10_bits_meta_dataErr),
    .io_msInfo_10_bits_metaTag                                             (mshrCtl_msInfo_10_bits_metaTag),
    .io_msInfo_10_bits_dirHit                                              (mshrCtl_msInfo_10_bits_dirHit),
    .io_msInfo_10_bits_isAcqOrPrefetch                                     (mshrCtl_msInfo_10_bits_isAcqOrPrefetch),
    .io_msInfo_10_bits_isPrefetch                                          (mshrCtl_msInfo_10_bits_isPrefetch),
    .io_msInfo_10_bits_param                                               (mshrCtl_msInfo_10_bits_param),
    .io_msInfo_10_bits_mergeA                                              (mshrCtl_msInfo_10_bits_mergeA),
    .io_msInfo_10_bits_w_grantfirst                                        (mshrCtl_msInfo_10_bits_w_grantfirst),
    .io_msInfo_10_bits_s_release                                           (mshrCtl_msInfo_10_bits_s_release),
    .io_msInfo_10_bits_s_refill                                            (mshrCtl_msInfo_10_bits_s_refill),
    .io_msInfo_10_bits_s_cmoresp                                           (mshrCtl_msInfo_10_bits_s_cmoresp),
    .io_msInfo_10_bits_s_cmometaw                                          (mshrCtl_msInfo_10_bits_s_cmometaw),
    .io_msInfo_10_bits_w_releaseack                                        (mshrCtl_msInfo_10_bits_w_releaseack),
    .io_msInfo_10_bits_w_replResp                                          (mshrCtl_msInfo_10_bits_w_replResp),
    .io_msInfo_10_bits_w_rprobeacklast                                     (mshrCtl_msInfo_10_bits_w_rprobeacklast),
    .io_msInfo_10_bits_replaceData                                         (mshrCtl_msInfo_10_bits_replaceData),
    .io_msInfo_10_bits_releaseToClean                                      (mshrCtl_msInfo_10_bits_releaseToClean),
    .io_msInfo_11_valid                                                    (mshrCtl_msInfo_11_valid),
    .io_msInfo_11_bits_channel                                             (mshrCtl_msInfo_11_bits_channel),
    .io_msInfo_11_bits_set                                                 (mshrCtl_msInfo_11_bits_set),
    .io_msInfo_11_bits_way                                                 (mshrCtl_msInfo_11_bits_way),
    .io_msInfo_11_bits_reqTag                                              (mshrCtl_msInfo_11_bits_reqTag),
    .io_msInfo_11_bits_willFree                                            (mshrCtl_msInfo_11_bits_willFree),
    .io_msInfo_11_bits_aliasTask                                           (mshrCtl_msInfo_11_bits_aliasTask),
    .io_msInfo_11_bits_needRelease                                         (mshrCtl_msInfo_11_bits_needRelease),
    .io_msInfo_11_bits_blockRefill                                         (mshrCtl_msInfo_11_bits_blockRefill),
    .io_msInfo_11_bits_meta_dirty                                          (mshrCtl_msInfo_11_bits_meta_dirty),
    .io_msInfo_11_bits_meta_state                                          (mshrCtl_msInfo_11_bits_meta_state),
    .io_msInfo_11_bits_meta_clients                                        (mshrCtl_msInfo_11_bits_meta_clients),
    .io_msInfo_11_bits_meta_alias                                          (mshrCtl_msInfo_11_bits_meta_alias),
    .io_msInfo_11_bits_meta_prefetch                                       (mshrCtl_msInfo_11_bits_meta_prefetch),
    .io_msInfo_11_bits_meta_prefetchSrc                                    (mshrCtl_msInfo_11_bits_meta_prefetchSrc),
    .io_msInfo_11_bits_meta_accessed                                       (mshrCtl_msInfo_11_bits_meta_accessed),
    .io_msInfo_11_bits_meta_tagErr                                         (mshrCtl_msInfo_11_bits_meta_tagErr),
    .io_msInfo_11_bits_meta_dataErr                                        (mshrCtl_msInfo_11_bits_meta_dataErr),
    .io_msInfo_11_bits_metaTag                                             (mshrCtl_msInfo_11_bits_metaTag),
    .io_msInfo_11_bits_dirHit                                              (mshrCtl_msInfo_11_bits_dirHit),
    .io_msInfo_11_bits_isAcqOrPrefetch                                     (mshrCtl_msInfo_11_bits_isAcqOrPrefetch),
    .io_msInfo_11_bits_isPrefetch                                          (mshrCtl_msInfo_11_bits_isPrefetch),
    .io_msInfo_11_bits_param                                               (mshrCtl_msInfo_11_bits_param),
    .io_msInfo_11_bits_mergeA                                              (mshrCtl_msInfo_11_bits_mergeA),
    .io_msInfo_11_bits_w_grantfirst                                        (mshrCtl_msInfo_11_bits_w_grantfirst),
    .io_msInfo_11_bits_s_release                                           (mshrCtl_msInfo_11_bits_s_release),
    .io_msInfo_11_bits_s_refill                                            (mshrCtl_msInfo_11_bits_s_refill),
    .io_msInfo_11_bits_s_cmoresp                                           (mshrCtl_msInfo_11_bits_s_cmoresp),
    .io_msInfo_11_bits_s_cmometaw                                          (mshrCtl_msInfo_11_bits_s_cmometaw),
    .io_msInfo_11_bits_w_releaseack                                        (mshrCtl_msInfo_11_bits_w_releaseack),
    .io_msInfo_11_bits_w_replResp                                          (mshrCtl_msInfo_11_bits_w_replResp),
    .io_msInfo_11_bits_w_rprobeacklast                                     (mshrCtl_msInfo_11_bits_w_rprobeacklast),
    .io_msInfo_11_bits_replaceData                                         (mshrCtl_msInfo_11_bits_replaceData),
    .io_msInfo_11_bits_releaseToClean                                      (mshrCtl_msInfo_11_bits_releaseToClean),
    .io_msInfo_12_valid                                                    (mshrCtl_msInfo_12_valid),
    .io_msInfo_12_bits_channel                                             (mshrCtl_msInfo_12_bits_channel),
    .io_msInfo_12_bits_set                                                 (mshrCtl_msInfo_12_bits_set),
    .io_msInfo_12_bits_way                                                 (mshrCtl_msInfo_12_bits_way),
    .io_msInfo_12_bits_reqTag                                              (mshrCtl_msInfo_12_bits_reqTag),
    .io_msInfo_12_bits_willFree                                            (mshrCtl_msInfo_12_bits_willFree),
    .io_msInfo_12_bits_aliasTask                                           (mshrCtl_msInfo_12_bits_aliasTask),
    .io_msInfo_12_bits_needRelease                                         (mshrCtl_msInfo_12_bits_needRelease),
    .io_msInfo_12_bits_blockRefill                                         (mshrCtl_msInfo_12_bits_blockRefill),
    .io_msInfo_12_bits_meta_dirty                                          (mshrCtl_msInfo_12_bits_meta_dirty),
    .io_msInfo_12_bits_meta_state                                          (mshrCtl_msInfo_12_bits_meta_state),
    .io_msInfo_12_bits_meta_clients                                        (mshrCtl_msInfo_12_bits_meta_clients),
    .io_msInfo_12_bits_meta_alias                                          (mshrCtl_msInfo_12_bits_meta_alias),
    .io_msInfo_12_bits_meta_prefetch                                       (mshrCtl_msInfo_12_bits_meta_prefetch),
    .io_msInfo_12_bits_meta_prefetchSrc                                    (mshrCtl_msInfo_12_bits_meta_prefetchSrc),
    .io_msInfo_12_bits_meta_accessed                                       (mshrCtl_msInfo_12_bits_meta_accessed),
    .io_msInfo_12_bits_meta_tagErr                                         (mshrCtl_msInfo_12_bits_meta_tagErr),
    .io_msInfo_12_bits_meta_dataErr                                        (mshrCtl_msInfo_12_bits_meta_dataErr),
    .io_msInfo_12_bits_metaTag                                             (mshrCtl_msInfo_12_bits_metaTag),
    .io_msInfo_12_bits_dirHit                                              (mshrCtl_msInfo_12_bits_dirHit),
    .io_msInfo_12_bits_isAcqOrPrefetch                                     (mshrCtl_msInfo_12_bits_isAcqOrPrefetch),
    .io_msInfo_12_bits_isPrefetch                                          (mshrCtl_msInfo_12_bits_isPrefetch),
    .io_msInfo_12_bits_param                                               (mshrCtl_msInfo_12_bits_param),
    .io_msInfo_12_bits_mergeA                                              (mshrCtl_msInfo_12_bits_mergeA),
    .io_msInfo_12_bits_w_grantfirst                                        (mshrCtl_msInfo_12_bits_w_grantfirst),
    .io_msInfo_12_bits_s_release                                           (mshrCtl_msInfo_12_bits_s_release),
    .io_msInfo_12_bits_s_refill                                            (mshrCtl_msInfo_12_bits_s_refill),
    .io_msInfo_12_bits_s_cmoresp                                           (mshrCtl_msInfo_12_bits_s_cmoresp),
    .io_msInfo_12_bits_s_cmometaw                                          (mshrCtl_msInfo_12_bits_s_cmometaw),
    .io_msInfo_12_bits_w_releaseack                                        (mshrCtl_msInfo_12_bits_w_releaseack),
    .io_msInfo_12_bits_w_replResp                                          (mshrCtl_msInfo_12_bits_w_replResp),
    .io_msInfo_12_bits_w_rprobeacklast                                     (mshrCtl_msInfo_12_bits_w_rprobeacklast),
    .io_msInfo_12_bits_replaceData                                         (mshrCtl_msInfo_12_bits_replaceData),
    .io_msInfo_12_bits_releaseToClean                                      (mshrCtl_msInfo_12_bits_releaseToClean),
    .io_msInfo_13_valid                                                    (mshrCtl_msInfo_13_valid),
    .io_msInfo_13_bits_channel                                             (mshrCtl_msInfo_13_bits_channel),
    .io_msInfo_13_bits_set                                                 (mshrCtl_msInfo_13_bits_set),
    .io_msInfo_13_bits_way                                                 (mshrCtl_msInfo_13_bits_way),
    .io_msInfo_13_bits_reqTag                                              (mshrCtl_msInfo_13_bits_reqTag),
    .io_msInfo_13_bits_willFree                                            (mshrCtl_msInfo_13_bits_willFree),
    .io_msInfo_13_bits_aliasTask                                           (mshrCtl_msInfo_13_bits_aliasTask),
    .io_msInfo_13_bits_needRelease                                         (mshrCtl_msInfo_13_bits_needRelease),
    .io_msInfo_13_bits_blockRefill                                         (mshrCtl_msInfo_13_bits_blockRefill),
    .io_msInfo_13_bits_meta_dirty                                          (mshrCtl_msInfo_13_bits_meta_dirty),
    .io_msInfo_13_bits_meta_state                                          (mshrCtl_msInfo_13_bits_meta_state),
    .io_msInfo_13_bits_meta_clients                                        (mshrCtl_msInfo_13_bits_meta_clients),
    .io_msInfo_13_bits_meta_alias                                          (mshrCtl_msInfo_13_bits_meta_alias),
    .io_msInfo_13_bits_meta_prefetch                                       (mshrCtl_msInfo_13_bits_meta_prefetch),
    .io_msInfo_13_bits_meta_prefetchSrc                                    (mshrCtl_msInfo_13_bits_meta_prefetchSrc),
    .io_msInfo_13_bits_meta_accessed                                       (mshrCtl_msInfo_13_bits_meta_accessed),
    .io_msInfo_13_bits_meta_tagErr                                         (mshrCtl_msInfo_13_bits_meta_tagErr),
    .io_msInfo_13_bits_meta_dataErr                                        (mshrCtl_msInfo_13_bits_meta_dataErr),
    .io_msInfo_13_bits_metaTag                                             (mshrCtl_msInfo_13_bits_metaTag),
    .io_msInfo_13_bits_dirHit                                              (mshrCtl_msInfo_13_bits_dirHit),
    .io_msInfo_13_bits_isAcqOrPrefetch                                     (mshrCtl_msInfo_13_bits_isAcqOrPrefetch),
    .io_msInfo_13_bits_isPrefetch                                          (mshrCtl_msInfo_13_bits_isPrefetch),
    .io_msInfo_13_bits_param                                               (mshrCtl_msInfo_13_bits_param),
    .io_msInfo_13_bits_mergeA                                              (mshrCtl_msInfo_13_bits_mergeA),
    .io_msInfo_13_bits_w_grantfirst                                        (mshrCtl_msInfo_13_bits_w_grantfirst),
    .io_msInfo_13_bits_s_release                                           (mshrCtl_msInfo_13_bits_s_release),
    .io_msInfo_13_bits_s_refill                                            (mshrCtl_msInfo_13_bits_s_refill),
    .io_msInfo_13_bits_s_cmoresp                                           (mshrCtl_msInfo_13_bits_s_cmoresp),
    .io_msInfo_13_bits_s_cmometaw                                          (mshrCtl_msInfo_13_bits_s_cmometaw),
    .io_msInfo_13_bits_w_releaseack                                        (mshrCtl_msInfo_13_bits_w_releaseack),
    .io_msInfo_13_bits_w_replResp                                          (mshrCtl_msInfo_13_bits_w_replResp),
    .io_msInfo_13_bits_w_rprobeacklast                                     (mshrCtl_msInfo_13_bits_w_rprobeacklast),
    .io_msInfo_13_bits_replaceData                                         (mshrCtl_msInfo_13_bits_replaceData),
    .io_msInfo_13_bits_releaseToClean                                      (mshrCtl_msInfo_13_bits_releaseToClean),
    .io_msInfo_14_valid                                                    (mshrCtl_msInfo_14_valid),
    .io_msInfo_14_bits_channel                                             (mshrCtl_msInfo_14_bits_channel),
    .io_msInfo_14_bits_set                                                 (mshrCtl_msInfo_14_bits_set),
    .io_msInfo_14_bits_way                                                 (mshrCtl_msInfo_14_bits_way),
    .io_msInfo_14_bits_reqTag                                              (mshrCtl_msInfo_14_bits_reqTag),
    .io_msInfo_14_bits_willFree                                            (mshrCtl_msInfo_14_bits_willFree),
    .io_msInfo_14_bits_aliasTask                                           (mshrCtl_msInfo_14_bits_aliasTask),
    .io_msInfo_14_bits_needRelease                                         (mshrCtl_msInfo_14_bits_needRelease),
    .io_msInfo_14_bits_blockRefill                                         (mshrCtl_msInfo_14_bits_blockRefill),
    .io_msInfo_14_bits_meta_dirty                                          (mshrCtl_msInfo_14_bits_meta_dirty),
    .io_msInfo_14_bits_meta_state                                          (mshrCtl_msInfo_14_bits_meta_state),
    .io_msInfo_14_bits_meta_clients                                        (mshrCtl_msInfo_14_bits_meta_clients),
    .io_msInfo_14_bits_meta_alias                                          (mshrCtl_msInfo_14_bits_meta_alias),
    .io_msInfo_14_bits_meta_prefetch                                       (mshrCtl_msInfo_14_bits_meta_prefetch),
    .io_msInfo_14_bits_meta_prefetchSrc                                    (mshrCtl_msInfo_14_bits_meta_prefetchSrc),
    .io_msInfo_14_bits_meta_accessed                                       (mshrCtl_msInfo_14_bits_meta_accessed),
    .io_msInfo_14_bits_meta_tagErr                                         (mshrCtl_msInfo_14_bits_meta_tagErr),
    .io_msInfo_14_bits_meta_dataErr                                        (mshrCtl_msInfo_14_bits_meta_dataErr),
    .io_msInfo_14_bits_metaTag                                             (mshrCtl_msInfo_14_bits_metaTag),
    .io_msInfo_14_bits_dirHit                                              (mshrCtl_msInfo_14_bits_dirHit),
    .io_msInfo_14_bits_isAcqOrPrefetch                                     (mshrCtl_msInfo_14_bits_isAcqOrPrefetch),
    .io_msInfo_14_bits_isPrefetch                                          (mshrCtl_msInfo_14_bits_isPrefetch),
    .io_msInfo_14_bits_param                                               (mshrCtl_msInfo_14_bits_param),
    .io_msInfo_14_bits_mergeA                                              (mshrCtl_msInfo_14_bits_mergeA),
    .io_msInfo_14_bits_w_grantfirst                                        (mshrCtl_msInfo_14_bits_w_grantfirst),
    .io_msInfo_14_bits_s_release                                           (mshrCtl_msInfo_14_bits_s_release),
    .io_msInfo_14_bits_s_refill                                            (mshrCtl_msInfo_14_bits_s_refill),
    .io_msInfo_14_bits_s_cmoresp                                           (mshrCtl_msInfo_14_bits_s_cmoresp),
    .io_msInfo_14_bits_s_cmometaw                                          (mshrCtl_msInfo_14_bits_s_cmometaw),
    .io_msInfo_14_bits_w_releaseack                                        (mshrCtl_msInfo_14_bits_w_releaseack),
    .io_msInfo_14_bits_w_replResp                                          (mshrCtl_msInfo_14_bits_w_replResp),
    .io_msInfo_14_bits_w_rprobeacklast                                     (mshrCtl_msInfo_14_bits_w_rprobeacklast),
    .io_msInfo_14_bits_replaceData                                         (mshrCtl_msInfo_14_bits_replaceData),
    .io_msInfo_14_bits_releaseToClean                                      (mshrCtl_msInfo_14_bits_releaseToClean),
    .io_msInfo_15_valid                                                    (mshrCtl_msInfo_15_valid),
    .io_msInfo_15_bits_channel                                             (mshrCtl_msInfo_15_bits_channel),
    .io_msInfo_15_bits_set                                                 (mshrCtl_msInfo_15_bits_set),
    .io_msInfo_15_bits_way                                                 (mshrCtl_msInfo_15_bits_way),
    .io_msInfo_15_bits_reqTag                                              (mshrCtl_msInfo_15_bits_reqTag),
    .io_msInfo_15_bits_willFree                                            (mshrCtl_msInfo_15_bits_willFree),
    .io_msInfo_15_bits_aliasTask                                           (mshrCtl_msInfo_15_bits_aliasTask),
    .io_msInfo_15_bits_needRelease                                         (mshrCtl_msInfo_15_bits_needRelease),
    .io_msInfo_15_bits_blockRefill                                         (mshrCtl_msInfo_15_bits_blockRefill),
    .io_msInfo_15_bits_meta_dirty                                          (mshrCtl_msInfo_15_bits_meta_dirty),
    .io_msInfo_15_bits_meta_state                                          (mshrCtl_msInfo_15_bits_meta_state),
    .io_msInfo_15_bits_meta_clients                                        (mshrCtl_msInfo_15_bits_meta_clients),
    .io_msInfo_15_bits_meta_alias                                          (mshrCtl_msInfo_15_bits_meta_alias),
    .io_msInfo_15_bits_meta_prefetch                                       (mshrCtl_msInfo_15_bits_meta_prefetch),
    .io_msInfo_15_bits_meta_prefetchSrc                                    (mshrCtl_msInfo_15_bits_meta_prefetchSrc),
    .io_msInfo_15_bits_meta_accessed                                       (mshrCtl_msInfo_15_bits_meta_accessed),
    .io_msInfo_15_bits_meta_tagErr                                         (mshrCtl_msInfo_15_bits_meta_tagErr),
    .io_msInfo_15_bits_meta_dataErr                                        (mshrCtl_msInfo_15_bits_meta_dataErr),
    .io_msInfo_15_bits_metaTag                                             (mshrCtl_msInfo_15_bits_metaTag),
    .io_msInfo_15_bits_dirHit                                              (mshrCtl_msInfo_15_bits_dirHit),
    .io_msInfo_15_bits_isAcqOrPrefetch                                     (mshrCtl_msInfo_15_bits_isAcqOrPrefetch),
    .io_msInfo_15_bits_isPrefetch                                          (mshrCtl_msInfo_15_bits_isPrefetch),
    .io_msInfo_15_bits_param                                               (mshrCtl_msInfo_15_bits_param),
    .io_msInfo_15_bits_mergeA                                              (mshrCtl_msInfo_15_bits_mergeA),
    .io_msInfo_15_bits_w_grantfirst                                        (mshrCtl_msInfo_15_bits_w_grantfirst),
    .io_msInfo_15_bits_s_release                                           (mshrCtl_msInfo_15_bits_s_release),
    .io_msInfo_15_bits_s_refill                                            (mshrCtl_msInfo_15_bits_s_refill),
    .io_msInfo_15_bits_s_cmoresp                                           (mshrCtl_msInfo_15_bits_s_cmoresp),
    .io_msInfo_15_bits_s_cmometaw                                          (mshrCtl_msInfo_15_bits_s_cmometaw),
    .io_msInfo_15_bits_w_releaseack                                        (mshrCtl_msInfo_15_bits_w_releaseack),
    .io_msInfo_15_bits_w_replResp                                          (mshrCtl_msInfo_15_bits_w_replResp),
    .io_msInfo_15_bits_w_rprobeacklast                                     (mshrCtl_msInfo_15_bits_w_rprobeacklast),
    .io_msInfo_15_bits_replaceData                                         (mshrCtl_msInfo_15_bits_replaceData),
    .io_msInfo_15_bits_releaseToClean                                      (mshrCtl_msInfo_15_bits_releaseToClean),
    .io_aMergeTask_valid                                                   (reqBuf_aMergeTask_valid),
    .io_aMergeTask_bits_id                                                 (reqBuf_aMergeTask_bits_id),
    .io_aMergeTask_bits_task_off                                           (reqBuf_aMergeTask_bits_task_off),
    .io_aMergeTask_bits_task_alias                                         (reqBuf_aMergeTask_bits_task_alias),
    .io_aMergeTask_bits_task_vaddr                                         (reqBuf_aMergeTask_bits_task_vaddr),
    .io_aMergeTask_bits_task_isKeyword                                     (reqBuf_aMergeTask_bits_task_isKeyword),
    .io_aMergeTask_bits_task_opcode                                        (reqBuf_aMergeTask_bits_task_opcode),
    .io_aMergeTask_bits_task_param                                         (reqBuf_aMergeTask_bits_task_param),
    .io_aMergeTask_bits_task_sourceId                                      (reqBuf_aMergeTask_bits_task_sourceId),
    .io_replResp_valid                                                     (dir_replResp_valid),
    .io_replResp_bits_tag                                                  (dir_replResp_bits_tag),
    .io_replResp_bits_way                                                  (dir_replResp_bits_way),
    .io_replResp_bits_meta_dirty                                           (dir_replResp_bits_meta_dirty),
    .io_replResp_bits_meta_state                                           (dir_replResp_bits_meta_state),
    .io_replResp_bits_meta_clients                                         (dir_replResp_bits_meta_clients),
    .io_replResp_bits_meta_alias                                           (dir_replResp_bits_meta_alias),
    .io_replResp_bits_meta_prefetch                                        (dir_replResp_bits_meta_prefetch),
    .io_replResp_bits_meta_prefetchSrc                                     (dir_replResp_bits_meta_prefetchSrc),
    .io_replResp_bits_meta_accessed                                        (dir_replResp_bits_meta_accessed),
    .io_replResp_bits_meta_tagErr                                          (dir_replResp_bits_meta_tagErr),
    .io_replResp_bits_meta_dataErr                                         (dir_replResp_bits_meta_dataErr),
    .io_replResp_bits_mshrId                                               (dir_replResp_bits_mshrId),
    .io_replResp_bits_retry                                                (dir_replResp_bits_retry),
    .io_replResp_bits_error                                                (dir_replResp_bits_error),
    .io_msStatus_0_valid                                                   (io_msStatus_0_valid),
    .io_msStatus_0_bits_channel                                            (io_msStatus_0_bits_channel),
    .io_msStatus_0_bits_set                                                (io_msStatus_0_bits_set),
    .io_msStatus_0_bits_reqTag                                             (io_msStatus_0_bits_reqTag),
    .io_msStatus_0_bits_is_miss                                            (io_msStatus_0_bits_is_miss),
    .io_msStatus_0_bits_is_prefetch                                        (io_msStatus_0_bits_is_prefetch),
    .io_msStatus_1_valid                                                   (io_msStatus_1_valid),
    .io_msStatus_1_bits_channel                                            (io_msStatus_1_bits_channel),
    .io_msStatus_1_bits_set                                                (io_msStatus_1_bits_set),
    .io_msStatus_1_bits_reqTag                                             (io_msStatus_1_bits_reqTag),
    .io_msStatus_1_bits_is_miss                                            (io_msStatus_1_bits_is_miss),
    .io_msStatus_1_bits_is_prefetch                                        (io_msStatus_1_bits_is_prefetch),
    .io_msStatus_2_valid                                                   (io_msStatus_2_valid),
    .io_msStatus_2_bits_channel                                            (io_msStatus_2_bits_channel),
    .io_msStatus_2_bits_set                                                (io_msStatus_2_bits_set),
    .io_msStatus_2_bits_reqTag                                             (io_msStatus_2_bits_reqTag),
    .io_msStatus_2_bits_is_miss                                            (io_msStatus_2_bits_is_miss),
    .io_msStatus_2_bits_is_prefetch                                        (io_msStatus_2_bits_is_prefetch),
    .io_msStatus_3_valid                                                   (io_msStatus_3_valid),
    .io_msStatus_3_bits_channel                                            (io_msStatus_3_bits_channel),
    .io_msStatus_3_bits_set                                                (io_msStatus_3_bits_set),
    .io_msStatus_3_bits_reqTag                                             (io_msStatus_3_bits_reqTag),
    .io_msStatus_3_bits_is_miss                                            (io_msStatus_3_bits_is_miss),
    .io_msStatus_3_bits_is_prefetch                                        (io_msStatus_3_bits_is_prefetch),
    .io_msStatus_4_valid                                                   (io_msStatus_4_valid),
    .io_msStatus_4_bits_channel                                            (io_msStatus_4_bits_channel),
    .io_msStatus_4_bits_set                                                (io_msStatus_4_bits_set),
    .io_msStatus_4_bits_reqTag                                             (io_msStatus_4_bits_reqTag),
    .io_msStatus_4_bits_is_miss                                            (io_msStatus_4_bits_is_miss),
    .io_msStatus_4_bits_is_prefetch                                        (io_msStatus_4_bits_is_prefetch),
    .io_msStatus_5_valid                                                   (io_msStatus_5_valid),
    .io_msStatus_5_bits_channel                                            (io_msStatus_5_bits_channel),
    .io_msStatus_5_bits_set                                                (io_msStatus_5_bits_set),
    .io_msStatus_5_bits_reqTag                                             (io_msStatus_5_bits_reqTag),
    .io_msStatus_5_bits_is_miss                                            (io_msStatus_5_bits_is_miss),
    .io_msStatus_5_bits_is_prefetch                                        (io_msStatus_5_bits_is_prefetch),
    .io_msStatus_6_valid                                                   (io_msStatus_6_valid),
    .io_msStatus_6_bits_channel                                            (io_msStatus_6_bits_channel),
    .io_msStatus_6_bits_set                                                (io_msStatus_6_bits_set),
    .io_msStatus_6_bits_reqTag                                             (io_msStatus_6_bits_reqTag),
    .io_msStatus_6_bits_is_miss                                            (io_msStatus_6_bits_is_miss),
    .io_msStatus_6_bits_is_prefetch                                        (io_msStatus_6_bits_is_prefetch),
    .io_msStatus_7_valid                                                   (io_msStatus_7_valid),
    .io_msStatus_7_bits_channel                                            (io_msStatus_7_bits_channel),
    .io_msStatus_7_bits_set                                                (io_msStatus_7_bits_set),
    .io_msStatus_7_bits_reqTag                                             (io_msStatus_7_bits_reqTag),
    .io_msStatus_7_bits_is_miss                                            (io_msStatus_7_bits_is_miss),
    .io_msStatus_7_bits_is_prefetch                                        (io_msStatus_7_bits_is_prefetch),
    .io_msStatus_8_valid                                                   (io_msStatus_8_valid),
    .io_msStatus_8_bits_channel                                            (io_msStatus_8_bits_channel),
    .io_msStatus_8_bits_set                                                (io_msStatus_8_bits_set),
    .io_msStatus_8_bits_reqTag                                             (io_msStatus_8_bits_reqTag),
    .io_msStatus_8_bits_is_miss                                            (io_msStatus_8_bits_is_miss),
    .io_msStatus_8_bits_is_prefetch                                        (io_msStatus_8_bits_is_prefetch),
    .io_msStatus_9_valid                                                   (io_msStatus_9_valid),
    .io_msStatus_9_bits_channel                                            (io_msStatus_9_bits_channel),
    .io_msStatus_9_bits_set                                                (io_msStatus_9_bits_set),
    .io_msStatus_9_bits_reqTag                                             (io_msStatus_9_bits_reqTag),
    .io_msStatus_9_bits_is_miss                                            (io_msStatus_9_bits_is_miss),
    .io_msStatus_9_bits_is_prefetch                                        (io_msStatus_9_bits_is_prefetch),
    .io_msStatus_10_valid                                                  (io_msStatus_10_valid),
    .io_msStatus_10_bits_channel                                           (io_msStatus_10_bits_channel),
    .io_msStatus_10_bits_set                                               (io_msStatus_10_bits_set),
    .io_msStatus_10_bits_reqTag                                            (io_msStatus_10_bits_reqTag),
    .io_msStatus_10_bits_is_miss                                           (io_msStatus_10_bits_is_miss),
    .io_msStatus_10_bits_is_prefetch                                       (io_msStatus_10_bits_is_prefetch),
    .io_msStatus_11_valid                                                  (io_msStatus_11_valid),
    .io_msStatus_11_bits_channel                                           (io_msStatus_11_bits_channel),
    .io_msStatus_11_bits_set                                               (io_msStatus_11_bits_set),
    .io_msStatus_11_bits_reqTag                                            (io_msStatus_11_bits_reqTag),
    .io_msStatus_11_bits_is_miss                                           (io_msStatus_11_bits_is_miss),
    .io_msStatus_11_bits_is_prefetch                                       (io_msStatus_11_bits_is_prefetch),
    .io_msStatus_12_valid                                                  (io_msStatus_12_valid),
    .io_msStatus_12_bits_channel                                           (io_msStatus_12_bits_channel),
    .io_msStatus_12_bits_set                                               (io_msStatus_12_bits_set),
    .io_msStatus_12_bits_reqTag                                            (io_msStatus_12_bits_reqTag),
    .io_msStatus_12_bits_is_miss                                           (io_msStatus_12_bits_is_miss),
    .io_msStatus_12_bits_is_prefetch                                       (io_msStatus_12_bits_is_prefetch),
    .io_msStatus_13_valid                                                  (io_msStatus_13_valid),
    .io_msStatus_13_bits_channel                                           (io_msStatus_13_bits_channel),
    .io_msStatus_13_bits_set                                               (io_msStatus_13_bits_set),
    .io_msStatus_13_bits_reqTag                                            (io_msStatus_13_bits_reqTag),
    .io_msStatus_13_bits_is_miss                                           (io_msStatus_13_bits_is_miss),
    .io_msStatus_13_bits_is_prefetch                                       (io_msStatus_13_bits_is_prefetch),
    .io_msStatus_14_valid                                                  (io_msStatus_14_valid),
    .io_msStatus_14_bits_channel                                           (io_msStatus_14_bits_channel),
    .io_msStatus_14_bits_set                                               (io_msStatus_14_bits_set),
    .io_msStatus_14_bits_reqTag                                            (io_msStatus_14_bits_reqTag),
    .io_msStatus_14_bits_is_miss                                           (io_msStatus_14_bits_is_miss),
    .io_msStatus_14_bits_is_prefetch                                       (io_msStatus_14_bits_is_prefetch),
    .io_msStatus_15_valid                                                  (io_msStatus_15_valid),
    .io_msStatus_15_bits_channel                                           (io_msStatus_15_bits_channel),
    .io_msStatus_15_bits_set                                               (io_msStatus_15_bits_set),
    .io_msStatus_15_bits_reqTag                                            (io_msStatus_15_bits_reqTag),
    .io_msStatus_15_bits_is_miss                                           (io_msStatus_15_bits_is_miss),
    .io_msStatus_15_bits_is_prefetch                                       (io_msStatus_15_bits_is_prefetch),
    .io_msAlloc_0_valid                                                    (io_msAlloc_0_valid),
    .io_msAlloc_0_bits_channel                                             (io_msAlloc_0_bits_channel),
    .io_msAlloc_0_bits_is_miss                                             (io_msAlloc_0_bits_is_miss),
    .io_msAlloc_0_bits_is_prefetch                                         (io_msAlloc_0_bits_is_prefetch),
    .io_msAlloc_1_valid                                                    (io_msAlloc_1_valid),
    .io_msAlloc_1_bits_channel                                             (io_msAlloc_1_bits_channel),
    .io_msAlloc_1_bits_is_miss                                             (io_msAlloc_1_bits_is_miss),
    .io_msAlloc_1_bits_is_prefetch                                         (io_msAlloc_1_bits_is_prefetch),
    .io_msAlloc_2_valid                                                    (io_msAlloc_2_valid),
    .io_msAlloc_2_bits_channel                                             (io_msAlloc_2_bits_channel),
    .io_msAlloc_2_bits_is_miss                                             (io_msAlloc_2_bits_is_miss),
    .io_msAlloc_2_bits_is_prefetch                                         (io_msAlloc_2_bits_is_prefetch),
    .io_msAlloc_3_valid                                                    (io_msAlloc_3_valid),
    .io_msAlloc_3_bits_channel                                             (io_msAlloc_3_bits_channel),
    .io_msAlloc_3_bits_is_miss                                             (io_msAlloc_3_bits_is_miss),
    .io_msAlloc_3_bits_is_prefetch                                         (io_msAlloc_3_bits_is_prefetch),
    .io_msAlloc_4_valid                                                    (io_msAlloc_4_valid),
    .io_msAlloc_4_bits_channel                                             (io_msAlloc_4_bits_channel),
    .io_msAlloc_4_bits_is_miss                                             (io_msAlloc_4_bits_is_miss),
    .io_msAlloc_4_bits_is_prefetch                                         (io_msAlloc_4_bits_is_prefetch),
    .io_msAlloc_5_valid                                                    (io_msAlloc_5_valid),
    .io_msAlloc_5_bits_channel                                             (io_msAlloc_5_bits_channel),
    .io_msAlloc_5_bits_is_miss                                             (io_msAlloc_5_bits_is_miss),
    .io_msAlloc_5_bits_is_prefetch                                         (io_msAlloc_5_bits_is_prefetch),
    .io_msAlloc_6_valid                                                    (io_msAlloc_6_valid),
    .io_msAlloc_6_bits_channel                                             (io_msAlloc_6_bits_channel),
    .io_msAlloc_6_bits_is_miss                                             (io_msAlloc_6_bits_is_miss),
    .io_msAlloc_6_bits_is_prefetch                                         (io_msAlloc_6_bits_is_prefetch),
    .io_msAlloc_7_valid                                                    (io_msAlloc_7_valid),
    .io_msAlloc_7_bits_channel                                             (io_msAlloc_7_bits_channel),
    .io_msAlloc_7_bits_is_miss                                             (io_msAlloc_7_bits_is_miss),
    .io_msAlloc_7_bits_is_prefetch                                         (io_msAlloc_7_bits_is_prefetch),
    .io_msAlloc_8_valid                                                    (io_msAlloc_8_valid),
    .io_msAlloc_8_bits_channel                                             (io_msAlloc_8_bits_channel),
    .io_msAlloc_8_bits_is_miss                                             (io_msAlloc_8_bits_is_miss),
    .io_msAlloc_8_bits_is_prefetch                                         (io_msAlloc_8_bits_is_prefetch),
    .io_msAlloc_9_valid                                                    (io_msAlloc_9_valid),
    .io_msAlloc_9_bits_channel                                             (io_msAlloc_9_bits_channel),
    .io_msAlloc_9_bits_is_miss                                             (io_msAlloc_9_bits_is_miss),
    .io_msAlloc_9_bits_is_prefetch                                         (io_msAlloc_9_bits_is_prefetch),
    .io_msAlloc_10_valid                                                   (io_msAlloc_10_valid),
    .io_msAlloc_10_bits_channel                                            (io_msAlloc_10_bits_channel),
    .io_msAlloc_10_bits_is_miss                                            (io_msAlloc_10_bits_is_miss),
    .io_msAlloc_10_bits_is_prefetch                                        (io_msAlloc_10_bits_is_prefetch),
    .io_msAlloc_11_valid                                                   (io_msAlloc_11_valid),
    .io_msAlloc_11_bits_channel                                            (io_msAlloc_11_bits_channel),
    .io_msAlloc_11_bits_is_miss                                            (io_msAlloc_11_bits_is_miss),
    .io_msAlloc_11_bits_is_prefetch                                        (io_msAlloc_11_bits_is_prefetch),
    .io_msAlloc_12_valid                                                   (io_msAlloc_12_valid),
    .io_msAlloc_12_bits_channel                                            (io_msAlloc_12_bits_channel),
    .io_msAlloc_12_bits_is_miss                                            (io_msAlloc_12_bits_is_miss),
    .io_msAlloc_12_bits_is_prefetch                                        (io_msAlloc_12_bits_is_prefetch),
    .io_msAlloc_13_valid                                                   (io_msAlloc_13_valid),
    .io_msAlloc_13_bits_channel                                            (io_msAlloc_13_bits_channel),
    .io_msAlloc_13_bits_is_miss                                            (io_msAlloc_13_bits_is_miss),
    .io_msAlloc_13_bits_is_prefetch                                        (io_msAlloc_13_bits_is_prefetch),
    .io_msAlloc_14_valid                                                   (io_msAlloc_14_valid),
    .io_msAlloc_14_bits_channel                                            (io_msAlloc_14_bits_channel),
    .io_msAlloc_14_bits_is_miss                                            (io_msAlloc_14_bits_is_miss),
    .io_msAlloc_14_bits_is_prefetch                                        (io_msAlloc_14_bits_is_prefetch),
    .io_msAlloc_15_valid                                                   (io_msAlloc_15_valid),
    .io_msAlloc_15_bits_channel                                            (io_msAlloc_15_bits_channel),
    .io_msAlloc_15_bits_is_miss                                            (io_msAlloc_15_bits_is_miss),
    .io_msAlloc_15_bits_is_prefetch                                        (io_msAlloc_15_bits_is_prefetch),
    .io_pCrd_0_query_valid                                                 (io_pCrd_0_query_valid),
    .io_pCrd_0_query_bits_pCrdType                                         (io_pCrd_0_query_bits_pCrdType),
    .io_pCrd_0_query_bits_srcID                                            (io_pCrd_0_query_bits_srcID),
    .io_pCrd_0_grant                                                       (io_pCrd_0_grant),
    .io_pCrd_1_query_valid                                                 (io_pCrd_1_query_valid),
    .io_pCrd_1_query_bits_pCrdType                                         (io_pCrd_1_query_bits_pCrdType),
    .io_pCrd_1_query_bits_srcID                                            (io_pCrd_1_query_bits_srcID),
    .io_pCrd_1_grant                                                       (io_pCrd_1_grant),
    .io_pCrd_2_query_valid                                                 (io_pCrd_2_query_valid),
    .io_pCrd_2_query_bits_pCrdType                                         (io_pCrd_2_query_bits_pCrdType),
    .io_pCrd_2_query_bits_srcID                                            (io_pCrd_2_query_bits_srcID),
    .io_pCrd_2_grant                                                       (io_pCrd_2_grant),
    .io_pCrd_3_query_valid                                                 (io_pCrd_3_query_valid),
    .io_pCrd_3_query_bits_pCrdType                                         (io_pCrd_3_query_bits_pCrdType),
    .io_pCrd_3_query_bits_srcID                                            (io_pCrd_3_query_bits_srcID),
    .io_pCrd_3_grant                                                       (io_pCrd_3_grant),
    .io_pCrd_4_query_valid                                                 (io_pCrd_4_query_valid),
    .io_pCrd_4_query_bits_pCrdType                                         (io_pCrd_4_query_bits_pCrdType),
    .io_pCrd_4_query_bits_srcID                                            (io_pCrd_4_query_bits_srcID),
    .io_pCrd_4_grant                                                       (io_pCrd_4_grant),
    .io_pCrd_5_query_valid                                                 (io_pCrd_5_query_valid),
    .io_pCrd_5_query_bits_pCrdType                                         (io_pCrd_5_query_bits_pCrdType),
    .io_pCrd_5_query_bits_srcID                                            (io_pCrd_5_query_bits_srcID),
    .io_pCrd_5_grant                                                       (io_pCrd_5_grant),
    .io_pCrd_6_query_valid                                                 (io_pCrd_6_query_valid),
    .io_pCrd_6_query_bits_pCrdType                                         (io_pCrd_6_query_bits_pCrdType),
    .io_pCrd_6_query_bits_srcID                                            (io_pCrd_6_query_bits_srcID),
    .io_pCrd_6_grant                                                       (io_pCrd_6_grant),
    .io_pCrd_7_query_valid                                                 (io_pCrd_7_query_valid),
    .io_pCrd_7_query_bits_pCrdType                                         (io_pCrd_7_query_bits_pCrdType),
    .io_pCrd_7_query_bits_srcID                                            (io_pCrd_7_query_bits_srcID),
    .io_pCrd_7_grant                                                       (io_pCrd_7_grant),
    .io_pCrd_8_query_valid                                                 (io_pCrd_8_query_valid),
    .io_pCrd_8_query_bits_pCrdType                                         (io_pCrd_8_query_bits_pCrdType),
    .io_pCrd_8_query_bits_srcID                                            (io_pCrd_8_query_bits_srcID),
    .io_pCrd_8_grant                                                       (io_pCrd_8_grant),
    .io_pCrd_9_query_valid                                                 (io_pCrd_9_query_valid),
    .io_pCrd_9_query_bits_pCrdType                                         (io_pCrd_9_query_bits_pCrdType),
    .io_pCrd_9_query_bits_srcID                                            (io_pCrd_9_query_bits_srcID),
    .io_pCrd_9_grant                                                       (io_pCrd_9_grant),
    .io_pCrd_10_query_valid                                                (io_pCrd_10_query_valid),
    .io_pCrd_10_query_bits_pCrdType                                        (io_pCrd_10_query_bits_pCrdType),
    .io_pCrd_10_query_bits_srcID                                           (io_pCrd_10_query_bits_srcID),
    .io_pCrd_10_grant                                                      (io_pCrd_10_grant),
    .io_pCrd_11_query_valid                                                (io_pCrd_11_query_valid),
    .io_pCrd_11_query_bits_pCrdType                                        (io_pCrd_11_query_bits_pCrdType),
    .io_pCrd_11_query_bits_srcID                                           (io_pCrd_11_query_bits_srcID),
    .io_pCrd_11_grant                                                      (io_pCrd_11_grant),
    .io_pCrd_12_query_valid                                                (io_pCrd_12_query_valid),
    .io_pCrd_12_query_bits_pCrdType                                        (io_pCrd_12_query_bits_pCrdType),
    .io_pCrd_12_query_bits_srcID                                           (io_pCrd_12_query_bits_srcID),
    .io_pCrd_12_grant                                                      (io_pCrd_12_grant),
    .io_pCrd_13_query_valid                                                (io_pCrd_13_query_valid),
    .io_pCrd_13_query_bits_pCrdType                                        (io_pCrd_13_query_bits_pCrdType),
    .io_pCrd_13_query_bits_srcID                                           (io_pCrd_13_query_bits_srcID),
    .io_pCrd_13_grant                                                      (io_pCrd_13_grant),
    .io_pCrd_14_query_valid                                                (io_pCrd_14_query_valid),
    .io_pCrd_14_query_bits_pCrdType                                        (io_pCrd_14_query_bits_pCrdType),
    .io_pCrd_14_query_bits_srcID                                           (io_pCrd_14_query_bits_srcID),
    .io_pCrd_14_grant                                                      (io_pCrd_14_grant),
    .io_pCrd_15_query_valid                                                (io_pCrd_15_query_valid),
    .io_pCrd_15_query_bits_pCrdType                                        (io_pCrd_15_query_bits_pCrdType),
    .io_pCrd_15_query_bits_srcID                                           (io_pCrd_15_query_bits_srcID),
    .io_pCrd_15_grant                                                      (io_pCrd_15_grant),
    .io_l2Miss                                                             (io_l2Miss),
    .io_perf_0_value                                                       (mshrCtl_perf_0_value),
    .io_perf_1_value                                                       (mshrCtl_perf_1_value),
    .io_perf_3_value                                                       (mshrCtl_perf_3_value)
  );
  // END GENERATED(children)

endmodule

// BEGIN GENERATED(wrapper) —— scripts/gen_l2_slice.py 从 golden 端口表生成，勿手改
module Slice(
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
  input  [3:0]     boreChildrenBd_bore_array,
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
  logic [3:0]     mbist_dir_array;
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
  logic [3:0]     mbist_ds_array;
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

  // §W3 可读核（本变体 SLICE_ID = 0）：除目录 / 数据阵列 / MBIST 分发外的全部 child 与本层逻辑
  xs_Slice_core #(.SLICE_ID(2'd0)) u_core (
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

  // §W4 目录（tag / meta / 替换状态），本变体 = Directory
  Directory directory (
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

  // §W5 数据阵列，本变体 = DataStorage
  DataStorage dataStorage (
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

  // §W6 MBIST 分发（L2Slice）：顶层 bore -> 目录（路 0）/ 数据阵列（路 1）
  L2Slice mbistPl (
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
// END GENERATED(wrapper)
