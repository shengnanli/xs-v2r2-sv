// ResponseUnit 包装层: golden 同名扁平端口 ↔ xs_ResponseUnit_core struct/数组端口。
// 仅机械打包/拆包, 供 FM 对比与 ST 替换。
module ResponseUnit
  import xs_responseunit_pkg::*;
(
  input           clock,
  input           reset,
  input           io_fromMainPipe_alloc_s4_valid,
  input           io_fromMainPipe_alloc_s4_bits_state_w_datRsp,
  input           io_fromMainPipe_alloc_s4_bits_state_w_snpRsp,
  input           io_fromMainPipe_alloc_s4_bits_state_w_compack,
  input           io_fromMainPipe_alloc_s4_bits_state_w_comp,
  input  [11:0]   io_fromMainPipe_alloc_s4_bits_task_set,
  input  [1:0]    io_fromMainPipe_alloc_s4_bits_task_bank,
  input  [27:0]   io_fromMainPipe_alloc_s4_bits_task_tag,
  input  [5:0]    io_fromMainPipe_alloc_s4_bits_task_off,
  input  [2:0]    io_fromMainPipe_alloc_s4_bits_task_size,
  input           io_fromMainPipe_alloc_s4_bits_task_refillTask,
  input  [3:0]    io_fromMainPipe_alloc_s4_bits_task_bufID,
  input  [11:0]   io_fromMainPipe_alloc_s4_bits_task_reqID,
  input           io_fromMainPipe_alloc_s4_bits_task_replSnp,
  input           io_fromMainPipe_alloc_s4_bits_task_snpVec_0,
  input  [10:0]   io_fromMainPipe_alloc_s4_bits_task_tgtID,
  input  [10:0]   io_fromMainPipe_alloc_s4_bits_task_srcID,
  input  [11:0]   io_fromMainPipe_alloc_s4_bits_task_txnID,
  input  [10:0]   io_fromMainPipe_alloc_s4_bits_task_homeNID,
  input  [11:0]   io_fromMainPipe_alloc_s4_bits_task_dbID,
  input  [10:0]   io_fromMainPipe_alloc_s4_bits_task_fwdNID,
  input  [11:0]   io_fromMainPipe_alloc_s4_bits_task_fwdTxnID,
  input  [6:0]    io_fromMainPipe_alloc_s4_bits_task_chiOpcode,
  input  [2:0]    io_fromMainPipe_alloc_s4_bits_task_resp,
  input  [2:0]    io_fromMainPipe_alloc_s4_bits_task_fwdState,
  input  [3:0]    io_fromMainPipe_alloc_s4_bits_task_pCrdType,
  input           io_fromMainPipe_alloc_s4_bits_task_retToSrc,
  input           io_fromMainPipe_alloc_s4_bits_task_doNotGoToSD,
  input           io_fromMainPipe_alloc_s4_bits_task_expCompAck,
  input           io_fromMainPipe_alloc_s4_bits_task_allowRetry,
  input  [1:0]    io_fromMainPipe_alloc_s4_bits_task_order,
  input           io_fromMainPipe_alloc_s4_bits_task_memAttr_allocate,
  input           io_fromMainPipe_alloc_s4_bits_task_memAttr_cacheable,
  input           io_fromMainPipe_alloc_s4_bits_task_memAttr_device,
  input           io_fromMainPipe_alloc_s4_bits_task_memAttr_ewa,
  input           io_fromMainPipe_alloc_s4_bits_task_snpAttr,
  input           io_fromMainPipe_alloc_s4_bits_is_miss,
  input           io_fromMainPipe_alloc_s6_valid,
  input           io_fromMainPipe_alloc_s6_bits_state_w_snpRsp,
  input  [11:0]   io_fromMainPipe_alloc_s6_bits_task_set,
  input  [1:0]    io_fromMainPipe_alloc_s6_bits_task_bank,
  input  [27:0]   io_fromMainPipe_alloc_s6_bits_task_tag,
  input  [5:0]    io_fromMainPipe_alloc_s6_bits_task_off,
  input  [2:0]    io_fromMainPipe_alloc_s6_bits_task_size,
  input           io_fromMainPipe_alloc_s6_bits_task_refillTask,
  input  [3:0]    io_fromMainPipe_alloc_s6_bits_task_bufID,
  input  [11:0]   io_fromMainPipe_alloc_s6_bits_task_reqID,
  input           io_fromMainPipe_alloc_s6_bits_task_replSnp,
  input           io_fromMainPipe_alloc_s6_bits_task_snpVec_0,
  input  [10:0]   io_fromMainPipe_alloc_s6_bits_task_tgtID,
  input  [10:0]   io_fromMainPipe_alloc_s6_bits_task_srcID,
  input  [11:0]   io_fromMainPipe_alloc_s6_bits_task_txnID,
  input  [10:0]   io_fromMainPipe_alloc_s6_bits_task_homeNID,
  input  [11:0]   io_fromMainPipe_alloc_s6_bits_task_dbID,
  input  [10:0]   io_fromMainPipe_alloc_s6_bits_task_fwdNID,
  input  [11:0]   io_fromMainPipe_alloc_s6_bits_task_fwdTxnID,
  input  [6:0]    io_fromMainPipe_alloc_s6_bits_task_chiOpcode,
  input  [2:0]    io_fromMainPipe_alloc_s6_bits_task_resp,
  input  [2:0]    io_fromMainPipe_alloc_s6_bits_task_fwdState,
  input  [3:0]    io_fromMainPipe_alloc_s6_bits_task_pCrdType,
  input           io_fromMainPipe_alloc_s6_bits_task_retToSrc,
  input           io_fromMainPipe_alloc_s6_bits_task_doNotGoToSD,
  input           io_fromMainPipe_alloc_s6_bits_task_expCompAck,
  input           io_fromMainPipe_alloc_s6_bits_task_allowRetry,
  input  [1:0]    io_fromMainPipe_alloc_s6_bits_task_order,
  input           io_fromMainPipe_alloc_s6_bits_task_memAttr_allocate,
  input           io_fromMainPipe_alloc_s6_bits_task_memAttr_cacheable,
  input           io_fromMainPipe_alloc_s6_bits_task_memAttr_device,
  input           io_fromMainPipe_alloc_s6_bits_task_memAttr_ewa,
  input           io_fromMainPipe_alloc_s6_bits_task_snpAttr,
  input  [255:0]  io_fromMainPipe_alloc_s6_bits_data_data_0_data,
  input  [255:0]  io_fromMainPipe_alloc_s6_bits_data_data_1_data,
  input           io_snRxdat_valid,
  input  [11:0]   io_snRxdat_bits_txnID,
  input  [6:0]    io_snRxdat_bits_opcode,
  input  [1:0]    io_snRxdat_bits_dataID,
  input  [255:0]  io_snRxdat_bits_data_data,
  input           io_snRxrsp_valid,
  input  [11:0]   io_snRxrsp_bits_txnID,
  input  [6:0]    io_snRxrsp_bits_opcode,
  input           io_bypassData_0_valid,
  input  [11:0]   io_bypassData_0_bits_txnID,
  input  [6:0]    io_bypassData_0_bits_opcode,
  input  [255:0]  io_bypassData_0_bits_data_data,
  input           io_bypassData_1_valid,
  input  [11:0]   io_bypassData_1_bits_txnID,
  input  [6:0]    io_bypassData_1_bits_opcode,
  input  [1:0]    io_bypassData_1_bits_dataID,
  input  [255:0]  io_bypassData_1_bits_data_data,
  input           io_rnRxdat_valid,
  input  [11:0]   io_rnRxdat_bits_txnID,
  input  [6:0]    io_rnRxdat_bits_opcode,
  input  [2:0]    io_rnRxdat_bits_resp,
  input  [10:0]   io_rnRxdat_bits_srcID,
  input  [1:0]    io_rnRxdat_bits_dataID,
  input  [255:0]  io_rnRxdat_bits_data_data,
  input           io_rnRxrsp_valid,
  input  [11:0]   io_rnRxrsp_bits_txnID,
  input  [6:0]    io_rnRxrsp_bits_opcode,
  input  [10:0]   io_rnRxrsp_bits_srcID,
  input           io_txrsp_ready,
  output          io_txrsp_valid,
  output [10:0]   io_txrsp_bits_tgtID,
  output [10:0]   io_txrsp_bits_srcID,
  output [11:0]   io_txrsp_bits_txnID,
  output [11:0]   io_txrsp_bits_dbID,
  output [6:0]    io_txrsp_bits_chiOpcode,
  output [2:0]    io_txrsp_bits_resp,
  output [2:0]    io_txrsp_bits_fwdState,
  output [3:0]    io_txrsp_bits_pCrdType,
  input           io_txdat_ready,
  output          io_txdat_valid,
  output [10:0]   io_txdat_bits_task_tgtID,
  output [10:0]   io_txdat_bits_task_srcID,
  output [11:0]   io_txdat_bits_task_txnID,
  output [10:0]   io_txdat_bits_task_homeNID,
  output [11:0]   io_txdat_bits_task_dbID,
  output [2:0]    io_txdat_bits_task_resp,
  output [2:0]    io_txdat_bits_task_fwdState,
  output [255:0]  io_txdat_bits_data_data_0_data,
  output [255:0]  io_txdat_bits_data_data_1_data,
  output          io_respInfo_0_valid,
  output [11:0]   io_respInfo_0_bits_set,
  output [27:0]   io_respInfo_0_bits_tag,
  output [6:0]    io_respInfo_0_bits_opcode,
  output [11:0]   io_respInfo_0_bits_reqID,
  output          io_respInfo_0_bits_w_snpRsp,
  output          io_respInfo_0_bits_w_compdata,
  output          io_respInfo_0_bits_w_compack,
  output          io_respInfo_0_bits_is_miss,
  output          io_respInfo_1_valid,
  output [11:0]   io_respInfo_1_bits_set,
  output [27:0]   io_respInfo_1_bits_tag,
  output [6:0]    io_respInfo_1_bits_opcode,
  output [11:0]   io_respInfo_1_bits_reqID,
  output          io_respInfo_1_bits_w_snpRsp,
  output          io_respInfo_1_bits_w_compdata,
  output          io_respInfo_1_bits_w_compack,
  output          io_respInfo_1_bits_is_miss,
  output          io_respInfo_2_valid,
  output [11:0]   io_respInfo_2_bits_set,
  output [27:0]   io_respInfo_2_bits_tag,
  output [6:0]    io_respInfo_2_bits_opcode,
  output [11:0]   io_respInfo_2_bits_reqID,
  output          io_respInfo_2_bits_w_snpRsp,
  output          io_respInfo_2_bits_w_compdata,
  output          io_respInfo_2_bits_w_compack,
  output          io_respInfo_2_bits_is_miss,
  output          io_respInfo_3_valid,
  output [11:0]   io_respInfo_3_bits_set,
  output [27:0]   io_respInfo_3_bits_tag,
  output [6:0]    io_respInfo_3_bits_opcode,
  output [11:0]   io_respInfo_3_bits_reqID,
  output          io_respInfo_3_bits_w_snpRsp,
  output          io_respInfo_3_bits_w_compdata,
  output          io_respInfo_3_bits_w_compack,
  output          io_respInfo_3_bits_is_miss,
  output          io_respInfo_4_valid,
  output [11:0]   io_respInfo_4_bits_set,
  output [27:0]   io_respInfo_4_bits_tag,
  output [6:0]    io_respInfo_4_bits_opcode,
  output [11:0]   io_respInfo_4_bits_reqID,
  output          io_respInfo_4_bits_w_snpRsp,
  output          io_respInfo_4_bits_w_compdata,
  output          io_respInfo_4_bits_w_compack,
  output          io_respInfo_4_bits_is_miss,
  output          io_respInfo_5_valid,
  output [11:0]   io_respInfo_5_bits_set,
  output [27:0]   io_respInfo_5_bits_tag,
  output [6:0]    io_respInfo_5_bits_opcode,
  output [11:0]   io_respInfo_5_bits_reqID,
  output          io_respInfo_5_bits_w_snpRsp,
  output          io_respInfo_5_bits_w_compdata,
  output          io_respInfo_5_bits_w_compack,
  output          io_respInfo_5_bits_is_miss,
  output          io_respInfo_6_valid,
  output [11:0]   io_respInfo_6_bits_set,
  output [27:0]   io_respInfo_6_bits_tag,
  output [6:0]    io_respInfo_6_bits_opcode,
  output [11:0]   io_respInfo_6_bits_reqID,
  output          io_respInfo_6_bits_w_snpRsp,
  output          io_respInfo_6_bits_w_compdata,
  output          io_respInfo_6_bits_w_compack,
  output          io_respInfo_6_bits_is_miss,
  output          io_respInfo_7_valid,
  output [11:0]   io_respInfo_7_bits_set,
  output [27:0]   io_respInfo_7_bits_tag,
  output [6:0]    io_respInfo_7_bits_opcode,
  output [11:0]   io_respInfo_7_bits_reqID,
  output          io_respInfo_7_bits_w_snpRsp,
  output          io_respInfo_7_bits_w_compdata,
  output          io_respInfo_7_bits_w_compack,
  output          io_respInfo_7_bits_is_miss,
  output          io_respInfo_8_valid,
  output [11:0]   io_respInfo_8_bits_set,
  output [27:0]   io_respInfo_8_bits_tag,
  output [6:0]    io_respInfo_8_bits_opcode,
  output [11:0]   io_respInfo_8_bits_reqID,
  output          io_respInfo_8_bits_w_snpRsp,
  output          io_respInfo_8_bits_w_compdata,
  output          io_respInfo_8_bits_w_compack,
  output          io_respInfo_8_bits_is_miss,
  output          io_respInfo_9_valid,
  output [11:0]   io_respInfo_9_bits_set,
  output [27:0]   io_respInfo_9_bits_tag,
  output [6:0]    io_respInfo_9_bits_opcode,
  output [11:0]   io_respInfo_9_bits_reqID,
  output          io_respInfo_9_bits_w_snpRsp,
  output          io_respInfo_9_bits_w_compdata,
  output          io_respInfo_9_bits_w_compack,
  output          io_respInfo_9_bits_is_miss,
  output          io_respInfo_10_valid,
  output [11:0]   io_respInfo_10_bits_set,
  output [27:0]   io_respInfo_10_bits_tag,
  output [6:0]    io_respInfo_10_bits_opcode,
  output [11:0]   io_respInfo_10_bits_reqID,
  output          io_respInfo_10_bits_w_snpRsp,
  output          io_respInfo_10_bits_w_compdata,
  output          io_respInfo_10_bits_w_compack,
  output          io_respInfo_10_bits_is_miss,
  output          io_respInfo_11_valid,
  output [11:0]   io_respInfo_11_bits_set,
  output [27:0]   io_respInfo_11_bits_tag,
  output [6:0]    io_respInfo_11_bits_opcode,
  output [11:0]   io_respInfo_11_bits_reqID,
  output          io_respInfo_11_bits_w_snpRsp,
  output          io_respInfo_11_bits_w_compdata,
  output          io_respInfo_11_bits_w_compack,
  output          io_respInfo_11_bits_is_miss,
  output          io_respInfo_12_valid,
  output [11:0]   io_respInfo_12_bits_set,
  output [27:0]   io_respInfo_12_bits_tag,
  output [6:0]    io_respInfo_12_bits_opcode,
  output [11:0]   io_respInfo_12_bits_reqID,
  output          io_respInfo_12_bits_w_snpRsp,
  output          io_respInfo_12_bits_w_compdata,
  output          io_respInfo_12_bits_w_compack,
  output          io_respInfo_12_bits_is_miss,
  output          io_respInfo_13_valid,
  output [11:0]   io_respInfo_13_bits_set,
  output [27:0]   io_respInfo_13_bits_tag,
  output [6:0]    io_respInfo_13_bits_opcode,
  output [11:0]   io_respInfo_13_bits_reqID,
  output          io_respInfo_13_bits_w_snpRsp,
  output          io_respInfo_13_bits_w_compdata,
  output          io_respInfo_13_bits_w_compack,
  output          io_respInfo_13_bits_is_miss,
  output          io_respInfo_14_valid,
  output [11:0]   io_respInfo_14_bits_set,
  output [27:0]   io_respInfo_14_bits_tag,
  output [6:0]    io_respInfo_14_bits_opcode,
  output [11:0]   io_respInfo_14_bits_reqID,
  output          io_respInfo_14_bits_w_snpRsp,
  output          io_respInfo_14_bits_w_compdata,
  output          io_respInfo_14_bits_w_compack,
  output          io_respInfo_14_bits_is_miss,
  output          io_respInfo_15_valid,
  output [11:0]   io_respInfo_15_bits_set,
  output [27:0]   io_respInfo_15_bits_tag,
  output [6:0]    io_respInfo_15_bits_opcode,
  output [11:0]   io_respInfo_15_bits_reqID,
  output          io_respInfo_15_bits_w_snpRsp,
  output          io_respInfo_15_bits_w_compdata,
  output          io_respInfo_15_bits_w_compack,
  output          io_respInfo_15_bits_is_miss,
  input           io_urgentRead_ready,
  output          io_urgentRead_valid,
  output [11:0]   io_urgentRead_bits_set,
  output [1:0]    io_urgentRead_bits_bank,
  output [27:0]   io_urgentRead_bits_tag,
  output [10:0]   io_urgentRead_bits_tgtID,
  output [10:0]   io_urgentRead_bits_srcID,
  output [11:0]   io_urgentRead_bits_txnID,
  output [3:0]    io_urgentRead_bits_pCrdType
);

  ru_task_t s4_task, s6_task;
  assign s4_task = '{set: io_fromMainPipe_alloc_s4_bits_task_set, bank: io_fromMainPipe_alloc_s4_bits_task_bank, tag: io_fromMainPipe_alloc_s4_bits_task_tag, off: io_fromMainPipe_alloc_s4_bits_task_off, size: io_fromMainPipe_alloc_s4_bits_task_size, refillTask: io_fromMainPipe_alloc_s4_bits_task_refillTask, bufID: io_fromMainPipe_alloc_s4_bits_task_bufID, reqID: io_fromMainPipe_alloc_s4_bits_task_reqID, replSnp: io_fromMainPipe_alloc_s4_bits_task_replSnp, snpVec_0: io_fromMainPipe_alloc_s4_bits_task_snpVec_0, tgtID: io_fromMainPipe_alloc_s4_bits_task_tgtID, srcID: io_fromMainPipe_alloc_s4_bits_task_srcID, txnID: io_fromMainPipe_alloc_s4_bits_task_txnID, homeNID: io_fromMainPipe_alloc_s4_bits_task_homeNID, dbID: io_fromMainPipe_alloc_s4_bits_task_dbID, fwdNID: io_fromMainPipe_alloc_s4_bits_task_fwdNID, fwdTxnID: io_fromMainPipe_alloc_s4_bits_task_fwdTxnID, chiOpcode: io_fromMainPipe_alloc_s4_bits_task_chiOpcode, resp: io_fromMainPipe_alloc_s4_bits_task_resp, fwdState: io_fromMainPipe_alloc_s4_bits_task_fwdState, pCrdType: io_fromMainPipe_alloc_s4_bits_task_pCrdType, retToSrc: io_fromMainPipe_alloc_s4_bits_task_retToSrc, doNotGoToSD: io_fromMainPipe_alloc_s4_bits_task_doNotGoToSD, expCompAck: io_fromMainPipe_alloc_s4_bits_task_expCompAck, allowRetry: io_fromMainPipe_alloc_s4_bits_task_allowRetry, order: io_fromMainPipe_alloc_s4_bits_task_order, memAttr_allocate: io_fromMainPipe_alloc_s4_bits_task_memAttr_allocate, memAttr_cacheable: io_fromMainPipe_alloc_s4_bits_task_memAttr_cacheable, memAttr_device: io_fromMainPipe_alloc_s4_bits_task_memAttr_device, memAttr_ewa: io_fromMainPipe_alloc_s4_bits_task_memAttr_ewa, snpAttr: io_fromMainPipe_alloc_s4_bits_task_snpAttr};
  assign s6_task = '{set: io_fromMainPipe_alloc_s6_bits_task_set, bank: io_fromMainPipe_alloc_s6_bits_task_bank, tag: io_fromMainPipe_alloc_s6_bits_task_tag, off: io_fromMainPipe_alloc_s6_bits_task_off, size: io_fromMainPipe_alloc_s6_bits_task_size, refillTask: io_fromMainPipe_alloc_s6_bits_task_refillTask, bufID: io_fromMainPipe_alloc_s6_bits_task_bufID, reqID: io_fromMainPipe_alloc_s6_bits_task_reqID, replSnp: io_fromMainPipe_alloc_s6_bits_task_replSnp, snpVec_0: io_fromMainPipe_alloc_s6_bits_task_snpVec_0, tgtID: io_fromMainPipe_alloc_s6_bits_task_tgtID, srcID: io_fromMainPipe_alloc_s6_bits_task_srcID, txnID: io_fromMainPipe_alloc_s6_bits_task_txnID, homeNID: io_fromMainPipe_alloc_s6_bits_task_homeNID, dbID: io_fromMainPipe_alloc_s6_bits_task_dbID, fwdNID: io_fromMainPipe_alloc_s6_bits_task_fwdNID, fwdTxnID: io_fromMainPipe_alloc_s6_bits_task_fwdTxnID, chiOpcode: io_fromMainPipe_alloc_s6_bits_task_chiOpcode, resp: io_fromMainPipe_alloc_s6_bits_task_resp, fwdState: io_fromMainPipe_alloc_s6_bits_task_fwdState, pCrdType: io_fromMainPipe_alloc_s6_bits_task_pCrdType, retToSrc: io_fromMainPipe_alloc_s6_bits_task_retToSrc, doNotGoToSD: io_fromMainPipe_alloc_s6_bits_task_doNotGoToSD, expCompAck: io_fromMainPipe_alloc_s6_bits_task_expCompAck, allowRetry: io_fromMainPipe_alloc_s6_bits_task_allowRetry, order: io_fromMainPipe_alloc_s6_bits_task_order, memAttr_allocate: io_fromMainPipe_alloc_s6_bits_task_memAttr_allocate, memAttr_cacheable: io_fromMainPipe_alloc_s6_bits_task_memAttr_cacheable, memAttr_device: io_fromMainPipe_alloc_s6_bits_task_memAttr_device, memAttr_ewa: io_fromMainPipe_alloc_s6_bits_task_memAttr_ewa, snpAttr: io_fromMainPipe_alloc_s6_bits_task_snpAttr};

  // respInfo[16] 输出数组 → 扁平端口拆包
  logic [N-1:0]       ri_valid;
  logic [N-1:0][11:0] ri_set;
  logic [N-1:0][27:0] ri_tag;
  logic [N-1:0][6:0]  ri_opcode;
  logic [N-1:0][11:0] ri_reqID;
  logic [N-1:0]       ri_w_snpRsp, ri_w_compdata, ri_w_compack, ri_is_miss;

  xs_ResponseUnit_core u_core (
    .clock (clock), .reset (reset),
    .io_fromMainPipe_alloc_s4_bits_task (s4_task),
    .io_fromMainPipe_alloc_s6_bits_task (s6_task),
    .io_fromMainPipe_alloc_s4_valid (io_fromMainPipe_alloc_s4_valid),
    .io_fromMainPipe_alloc_s4_bits_state_w_datRsp (io_fromMainPipe_alloc_s4_bits_state_w_datRsp),
    .io_fromMainPipe_alloc_s4_bits_state_w_snpRsp (io_fromMainPipe_alloc_s4_bits_state_w_snpRsp),
    .io_fromMainPipe_alloc_s4_bits_state_w_compack (io_fromMainPipe_alloc_s4_bits_state_w_compack),
    .io_fromMainPipe_alloc_s4_bits_state_w_comp (io_fromMainPipe_alloc_s4_bits_state_w_comp),
    .io_fromMainPipe_alloc_s4_bits_is_miss (io_fromMainPipe_alloc_s4_bits_is_miss),
    .io_fromMainPipe_alloc_s6_valid (io_fromMainPipe_alloc_s6_valid),
    .io_fromMainPipe_alloc_s6_bits_state_w_snpRsp (io_fromMainPipe_alloc_s6_bits_state_w_snpRsp),
    .io_fromMainPipe_alloc_s6_bits_data_data_0_data (io_fromMainPipe_alloc_s6_bits_data_data_0_data),
    .io_fromMainPipe_alloc_s6_bits_data_data_1_data (io_fromMainPipe_alloc_s6_bits_data_data_1_data),
    .io_snRxdat_valid (io_snRxdat_valid),
    .io_snRxdat_bits_txnID (io_snRxdat_bits_txnID),
    .io_snRxdat_bits_opcode (io_snRxdat_bits_opcode),
    .io_snRxdat_bits_dataID (io_snRxdat_bits_dataID),
    .io_snRxdat_bits_data_data (io_snRxdat_bits_data_data),
    .io_snRxrsp_valid (io_snRxrsp_valid),
    .io_snRxrsp_bits_txnID (io_snRxrsp_bits_txnID),
    .io_snRxrsp_bits_opcode (io_snRxrsp_bits_opcode),
    .io_bypassData_0_valid (io_bypassData_0_valid),
    .io_bypassData_0_bits_txnID (io_bypassData_0_bits_txnID),
    .io_bypassData_0_bits_opcode (io_bypassData_0_bits_opcode),
    .io_bypassData_0_bits_data_data (io_bypassData_0_bits_data_data),
    .io_bypassData_1_valid (io_bypassData_1_valid),
    .io_bypassData_1_bits_txnID (io_bypassData_1_bits_txnID),
    .io_bypassData_1_bits_opcode (io_bypassData_1_bits_opcode),
    .io_bypassData_1_bits_dataID (io_bypassData_1_bits_dataID),
    .io_bypassData_1_bits_data_data (io_bypassData_1_bits_data_data),
    .io_rnRxdat_valid (io_rnRxdat_valid),
    .io_rnRxdat_bits_txnID (io_rnRxdat_bits_txnID),
    .io_rnRxdat_bits_opcode (io_rnRxdat_bits_opcode),
    .io_rnRxdat_bits_resp (io_rnRxdat_bits_resp),
    .io_rnRxdat_bits_srcID (io_rnRxdat_bits_srcID),
    .io_rnRxdat_bits_dataID (io_rnRxdat_bits_dataID),
    .io_rnRxdat_bits_data_data (io_rnRxdat_bits_data_data),
    .io_rnRxrsp_valid (io_rnRxrsp_valid),
    .io_rnRxrsp_bits_txnID (io_rnRxrsp_bits_txnID),
    .io_rnRxrsp_bits_opcode (io_rnRxrsp_bits_opcode),
    .io_rnRxrsp_bits_srcID (io_rnRxrsp_bits_srcID),
    .io_txrsp_ready (io_txrsp_ready),
    .io_txdat_ready (io_txdat_ready),
    .io_urgentRead_ready (io_urgentRead_ready),
    .io_txrsp_valid (io_txrsp_valid),
    .io_txrsp_bits_tgtID (io_txrsp_bits_tgtID),
    .io_txrsp_bits_srcID (io_txrsp_bits_srcID),
    .io_txrsp_bits_txnID (io_txrsp_bits_txnID),
    .io_txrsp_bits_dbID (io_txrsp_bits_dbID),
    .io_txrsp_bits_chiOpcode (io_txrsp_bits_chiOpcode),
    .io_txrsp_bits_resp (io_txrsp_bits_resp),
    .io_txrsp_bits_fwdState (io_txrsp_bits_fwdState),
    .io_txrsp_bits_pCrdType (io_txrsp_bits_pCrdType),
    .io_txdat_valid (io_txdat_valid),
    .io_txdat_bits_task_tgtID (io_txdat_bits_task_tgtID),
    .io_txdat_bits_task_srcID (io_txdat_bits_task_srcID),
    .io_txdat_bits_task_txnID (io_txdat_bits_task_txnID),
    .io_txdat_bits_task_homeNID (io_txdat_bits_task_homeNID),
    .io_txdat_bits_task_dbID (io_txdat_bits_task_dbID),
    .io_txdat_bits_task_resp (io_txdat_bits_task_resp),
    .io_txdat_bits_task_fwdState (io_txdat_bits_task_fwdState),
    .io_txdat_bits_data_data_0_data (io_txdat_bits_data_data_0_data),
    .io_txdat_bits_data_data_1_data (io_txdat_bits_data_data_1_data),
    .io_urgentRead_valid (io_urgentRead_valid),
    .io_urgentRead_bits_set (io_urgentRead_bits_set),
    .io_urgentRead_bits_bank (io_urgentRead_bits_bank),
    .io_urgentRead_bits_tag (io_urgentRead_bits_tag),
    .io_urgentRead_bits_tgtID (io_urgentRead_bits_tgtID),
    .io_urgentRead_bits_srcID (io_urgentRead_bits_srcID),
    .io_urgentRead_bits_txnID (io_urgentRead_bits_txnID),
    .io_urgentRead_bits_pCrdType (io_urgentRead_bits_pCrdType),
    .io_respInfo_valid (ri_valid),
    .io_respInfo_set (ri_set),
    .io_respInfo_tag (ri_tag),
    .io_respInfo_opcode (ri_opcode),
    .io_respInfo_reqID (ri_reqID),
    .io_respInfo_w_snpRsp (ri_w_snpRsp),
    .io_respInfo_w_compdata (ri_w_compdata),
    .io_respInfo_w_compack (ri_w_compack),
    .io_respInfo_is_miss (ri_is_miss)
  );

  assign io_respInfo_0_valid       = ri_valid[0];
  assign io_respInfo_0_bits_set    = ri_set[0];
  assign io_respInfo_0_bits_tag    = ri_tag[0];
  assign io_respInfo_0_bits_opcode = ri_opcode[0];
  assign io_respInfo_0_bits_reqID  = ri_reqID[0];
  assign io_respInfo_0_bits_w_snpRsp  = ri_w_snpRsp[0];
  assign io_respInfo_0_bits_w_compdata= ri_w_compdata[0];
  assign io_respInfo_0_bits_w_compack = ri_w_compack[0];
  assign io_respInfo_0_bits_is_miss   = ri_is_miss[0];
  assign io_respInfo_1_valid       = ri_valid[1];
  assign io_respInfo_1_bits_set    = ri_set[1];
  assign io_respInfo_1_bits_tag    = ri_tag[1];
  assign io_respInfo_1_bits_opcode = ri_opcode[1];
  assign io_respInfo_1_bits_reqID  = ri_reqID[1];
  assign io_respInfo_1_bits_w_snpRsp  = ri_w_snpRsp[1];
  assign io_respInfo_1_bits_w_compdata= ri_w_compdata[1];
  assign io_respInfo_1_bits_w_compack = ri_w_compack[1];
  assign io_respInfo_1_bits_is_miss   = ri_is_miss[1];
  assign io_respInfo_2_valid       = ri_valid[2];
  assign io_respInfo_2_bits_set    = ri_set[2];
  assign io_respInfo_2_bits_tag    = ri_tag[2];
  assign io_respInfo_2_bits_opcode = ri_opcode[2];
  assign io_respInfo_2_bits_reqID  = ri_reqID[2];
  assign io_respInfo_2_bits_w_snpRsp  = ri_w_snpRsp[2];
  assign io_respInfo_2_bits_w_compdata= ri_w_compdata[2];
  assign io_respInfo_2_bits_w_compack = ri_w_compack[2];
  assign io_respInfo_2_bits_is_miss   = ri_is_miss[2];
  assign io_respInfo_3_valid       = ri_valid[3];
  assign io_respInfo_3_bits_set    = ri_set[3];
  assign io_respInfo_3_bits_tag    = ri_tag[3];
  assign io_respInfo_3_bits_opcode = ri_opcode[3];
  assign io_respInfo_3_bits_reqID  = ri_reqID[3];
  assign io_respInfo_3_bits_w_snpRsp  = ri_w_snpRsp[3];
  assign io_respInfo_3_bits_w_compdata= ri_w_compdata[3];
  assign io_respInfo_3_bits_w_compack = ri_w_compack[3];
  assign io_respInfo_3_bits_is_miss   = ri_is_miss[3];
  assign io_respInfo_4_valid       = ri_valid[4];
  assign io_respInfo_4_bits_set    = ri_set[4];
  assign io_respInfo_4_bits_tag    = ri_tag[4];
  assign io_respInfo_4_bits_opcode = ri_opcode[4];
  assign io_respInfo_4_bits_reqID  = ri_reqID[4];
  assign io_respInfo_4_bits_w_snpRsp  = ri_w_snpRsp[4];
  assign io_respInfo_4_bits_w_compdata= ri_w_compdata[4];
  assign io_respInfo_4_bits_w_compack = ri_w_compack[4];
  assign io_respInfo_4_bits_is_miss   = ri_is_miss[4];
  assign io_respInfo_5_valid       = ri_valid[5];
  assign io_respInfo_5_bits_set    = ri_set[5];
  assign io_respInfo_5_bits_tag    = ri_tag[5];
  assign io_respInfo_5_bits_opcode = ri_opcode[5];
  assign io_respInfo_5_bits_reqID  = ri_reqID[5];
  assign io_respInfo_5_bits_w_snpRsp  = ri_w_snpRsp[5];
  assign io_respInfo_5_bits_w_compdata= ri_w_compdata[5];
  assign io_respInfo_5_bits_w_compack = ri_w_compack[5];
  assign io_respInfo_5_bits_is_miss   = ri_is_miss[5];
  assign io_respInfo_6_valid       = ri_valid[6];
  assign io_respInfo_6_bits_set    = ri_set[6];
  assign io_respInfo_6_bits_tag    = ri_tag[6];
  assign io_respInfo_6_bits_opcode = ri_opcode[6];
  assign io_respInfo_6_bits_reqID  = ri_reqID[6];
  assign io_respInfo_6_bits_w_snpRsp  = ri_w_snpRsp[6];
  assign io_respInfo_6_bits_w_compdata= ri_w_compdata[6];
  assign io_respInfo_6_bits_w_compack = ri_w_compack[6];
  assign io_respInfo_6_bits_is_miss   = ri_is_miss[6];
  assign io_respInfo_7_valid       = ri_valid[7];
  assign io_respInfo_7_bits_set    = ri_set[7];
  assign io_respInfo_7_bits_tag    = ri_tag[7];
  assign io_respInfo_7_bits_opcode = ri_opcode[7];
  assign io_respInfo_7_bits_reqID  = ri_reqID[7];
  assign io_respInfo_7_bits_w_snpRsp  = ri_w_snpRsp[7];
  assign io_respInfo_7_bits_w_compdata= ri_w_compdata[7];
  assign io_respInfo_7_bits_w_compack = ri_w_compack[7];
  assign io_respInfo_7_bits_is_miss   = ri_is_miss[7];
  assign io_respInfo_8_valid       = ri_valid[8];
  assign io_respInfo_8_bits_set    = ri_set[8];
  assign io_respInfo_8_bits_tag    = ri_tag[8];
  assign io_respInfo_8_bits_opcode = ri_opcode[8];
  assign io_respInfo_8_bits_reqID  = ri_reqID[8];
  assign io_respInfo_8_bits_w_snpRsp  = ri_w_snpRsp[8];
  assign io_respInfo_8_bits_w_compdata= ri_w_compdata[8];
  assign io_respInfo_8_bits_w_compack = ri_w_compack[8];
  assign io_respInfo_8_bits_is_miss   = ri_is_miss[8];
  assign io_respInfo_9_valid       = ri_valid[9];
  assign io_respInfo_9_bits_set    = ri_set[9];
  assign io_respInfo_9_bits_tag    = ri_tag[9];
  assign io_respInfo_9_bits_opcode = ri_opcode[9];
  assign io_respInfo_9_bits_reqID  = ri_reqID[9];
  assign io_respInfo_9_bits_w_snpRsp  = ri_w_snpRsp[9];
  assign io_respInfo_9_bits_w_compdata= ri_w_compdata[9];
  assign io_respInfo_9_bits_w_compack = ri_w_compack[9];
  assign io_respInfo_9_bits_is_miss   = ri_is_miss[9];
  assign io_respInfo_10_valid       = ri_valid[10];
  assign io_respInfo_10_bits_set    = ri_set[10];
  assign io_respInfo_10_bits_tag    = ri_tag[10];
  assign io_respInfo_10_bits_opcode = ri_opcode[10];
  assign io_respInfo_10_bits_reqID  = ri_reqID[10];
  assign io_respInfo_10_bits_w_snpRsp  = ri_w_snpRsp[10];
  assign io_respInfo_10_bits_w_compdata= ri_w_compdata[10];
  assign io_respInfo_10_bits_w_compack = ri_w_compack[10];
  assign io_respInfo_10_bits_is_miss   = ri_is_miss[10];
  assign io_respInfo_11_valid       = ri_valid[11];
  assign io_respInfo_11_bits_set    = ri_set[11];
  assign io_respInfo_11_bits_tag    = ri_tag[11];
  assign io_respInfo_11_bits_opcode = ri_opcode[11];
  assign io_respInfo_11_bits_reqID  = ri_reqID[11];
  assign io_respInfo_11_bits_w_snpRsp  = ri_w_snpRsp[11];
  assign io_respInfo_11_bits_w_compdata= ri_w_compdata[11];
  assign io_respInfo_11_bits_w_compack = ri_w_compack[11];
  assign io_respInfo_11_bits_is_miss   = ri_is_miss[11];
  assign io_respInfo_12_valid       = ri_valid[12];
  assign io_respInfo_12_bits_set    = ri_set[12];
  assign io_respInfo_12_bits_tag    = ri_tag[12];
  assign io_respInfo_12_bits_opcode = ri_opcode[12];
  assign io_respInfo_12_bits_reqID  = ri_reqID[12];
  assign io_respInfo_12_bits_w_snpRsp  = ri_w_snpRsp[12];
  assign io_respInfo_12_bits_w_compdata= ri_w_compdata[12];
  assign io_respInfo_12_bits_w_compack = ri_w_compack[12];
  assign io_respInfo_12_bits_is_miss   = ri_is_miss[12];
  assign io_respInfo_13_valid       = ri_valid[13];
  assign io_respInfo_13_bits_set    = ri_set[13];
  assign io_respInfo_13_bits_tag    = ri_tag[13];
  assign io_respInfo_13_bits_opcode = ri_opcode[13];
  assign io_respInfo_13_bits_reqID  = ri_reqID[13];
  assign io_respInfo_13_bits_w_snpRsp  = ri_w_snpRsp[13];
  assign io_respInfo_13_bits_w_compdata= ri_w_compdata[13];
  assign io_respInfo_13_bits_w_compack = ri_w_compack[13];
  assign io_respInfo_13_bits_is_miss   = ri_is_miss[13];
  assign io_respInfo_14_valid       = ri_valid[14];
  assign io_respInfo_14_bits_set    = ri_set[14];
  assign io_respInfo_14_bits_tag    = ri_tag[14];
  assign io_respInfo_14_bits_opcode = ri_opcode[14];
  assign io_respInfo_14_bits_reqID  = ri_reqID[14];
  assign io_respInfo_14_bits_w_snpRsp  = ri_w_snpRsp[14];
  assign io_respInfo_14_bits_w_compdata= ri_w_compdata[14];
  assign io_respInfo_14_bits_w_compack = ri_w_compack[14];
  assign io_respInfo_14_bits_is_miss   = ri_is_miss[14];
  assign io_respInfo_15_valid       = ri_valid[15];
  assign io_respInfo_15_bits_set    = ri_set[15];
  assign io_respInfo_15_bits_tag    = ri_tag[15];
  assign io_respInfo_15_bits_opcode = ri_opcode[15];
  assign io_respInfo_15_bits_reqID  = ri_reqID[15];
  assign io_respInfo_15_bits_w_snpRsp  = ri_w_snpRsp[15];
  assign io_respInfo_15_bits_w_compdata= ri_w_compdata[15];
  assign io_respInfo_15_bits_w_compack = ri_w_compack[15];
  assign io_respInfo_15_bits_is_miss   = ri_is_miss[15];

endmodule
