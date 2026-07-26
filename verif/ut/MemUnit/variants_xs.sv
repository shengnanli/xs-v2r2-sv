// MemUnit 包装层(golden 同名扁平端口 ↔ xs_MemUnit_core 的 struct/数组端口)。
// 仅做机械端口打包/拆包, 供 FM 对比与 ST 替换。两个 FastArbiter 在核内例化。
module MemUnit_xs
  import xs_memunit_pkg::*;
(
  input           clock,
  input           reset,
  input           io_fromMainPipe_alloc_s4_valid,
  input           io_fromMainPipe_alloc_s4_bits_state_s_issueDat,
  input           io_fromMainPipe_alloc_s4_bits_state_w_datRsp,
  input           io_fromMainPipe_alloc_s4_bits_state_w_dbid,
  input           io_fromMainPipe_alloc_s4_bits_state_w_comp,
  input  [11:0]   io_fromMainPipe_alloc_s4_bits_task_set,
  input  [1:0]    io_fromMainPipe_alloc_s4_bits_task_bank,
  input  [27:0]   io_fromMainPipe_alloc_s4_bits_task_tag,
  input  [5:0]    io_fromMainPipe_alloc_s4_bits_task_off,
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
  input           io_fromMainPipe_alloc_s6_valid,
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
  output          io_urgentRead_ready,
  input           io_urgentRead_valid,
  input  [11:0]   io_urgentRead_bits_set,
  input  [1:0]    io_urgentRead_bits_bank,
  input  [27:0]   io_urgentRead_bits_tag,
  input  [10:0]   io_urgentRead_bits_tgtID,
  input  [10:0]   io_urgentRead_bits_srcID,
  input  [11:0]   io_urgentRead_bits_txnID,
  input  [3:0]    io_urgentRead_bits_pCrdType,
  input           io_snRxrsp_valid,
  input  [11:0]   io_snRxrsp_bits_txnID,
  input  [11:0]   io_snRxrsp_bits_dbID,
  input  [6:0]    io_snRxrsp_bits_opcode,
  input           io_rnRxdat_valid,
  input  [11:0]   io_rnRxdat_bits_txnID,
  input  [2:0]    io_rnRxdat_bits_resp,
  input  [1:0]    io_rnRxdat_bits_dataID,
  input  [255:0]  io_rnRxdat_bits_data_data,
  input           io_rnRxrsp_valid,
  input  [11:0]   io_rnRxrsp_bits_txnID,
  input           io_txreq_ready,
  output          io_txreq_valid,
  output [11:0]   io_txreq_bits_set,
  output [1:0]    io_txreq_bits_bank,
  output [27:0]   io_txreq_bits_tag,
  output [2:0]    io_txreq_bits_size,
  output [10:0]   io_txreq_bits_tgtID,
  output [10:0]   io_txreq_bits_srcID,
  output [11:0]   io_txreq_bits_txnID,
  output [6:0]    io_txreq_bits_chiOpcode,
  output [3:0]    io_txreq_bits_pCrdType,
  output          io_txreq_bits_expCompAck,
  output          io_txreq_bits_allowRetry,
  output [1:0]    io_txreq_bits_order,
  output          io_txreq_bits_memAttr_allocate,
  output          io_txreq_bits_memAttr_cacheable,
  output          io_txreq_bits_memAttr_device,
  output          io_txreq_bits_memAttr_ewa,
  output          io_txreq_bits_snpAttr,
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
  output          io_bypassData_0_valid,
  output [11:0]   io_bypassData_0_bits_txnID,
  output [6:0]    io_bypassData_0_bits_opcode,
  output [255:0]  io_bypassData_0_bits_data_data,
  output          io_bypassData_1_valid,
  output [11:0]   io_bypassData_1_bits_txnID,
  output [6:0]    io_bypassData_1_bits_opcode,
  output [1:0]    io_bypassData_1_bits_dataID,
  output [255:0]  io_bypassData_1_bits_data_data,
  output          io_memInfo_0_valid,
  output [11:0]   io_memInfo_0_bits_set,
  output [27:0]   io_memInfo_0_bits_tag,
  output [6:0]    io_memInfo_0_bits_opcode,
  output [11:0]   io_memInfo_0_bits_reqID,
  output          io_memInfo_0_bits_w_datRsp,
  output          io_memInfo_1_valid,
  output [11:0]   io_memInfo_1_bits_set,
  output [27:0]   io_memInfo_1_bits_tag,
  output [6:0]    io_memInfo_1_bits_opcode,
  output [11:0]   io_memInfo_1_bits_reqID,
  output          io_memInfo_1_bits_w_datRsp,
  output          io_memInfo_2_valid,
  output [11:0]   io_memInfo_2_bits_set,
  output [27:0]   io_memInfo_2_bits_tag,
  output [6:0]    io_memInfo_2_bits_opcode,
  output [11:0]   io_memInfo_2_bits_reqID,
  output          io_memInfo_2_bits_w_datRsp,
  output          io_memInfo_3_valid,
  output [11:0]   io_memInfo_3_bits_set,
  output [27:0]   io_memInfo_3_bits_tag,
  output [6:0]    io_memInfo_3_bits_opcode,
  output [11:0]   io_memInfo_3_bits_reqID,
  output          io_memInfo_3_bits_w_datRsp,
  output          io_memInfo_4_valid,
  output [11:0]   io_memInfo_4_bits_set,
  output [27:0]   io_memInfo_4_bits_tag,
  output [6:0]    io_memInfo_4_bits_opcode,
  output [11:0]   io_memInfo_4_bits_reqID,
  output          io_memInfo_4_bits_w_datRsp,
  output          io_memInfo_5_valid,
  output [11:0]   io_memInfo_5_bits_set,
  output [27:0]   io_memInfo_5_bits_tag,
  output [6:0]    io_memInfo_5_bits_opcode,
  output [11:0]   io_memInfo_5_bits_reqID,
  output          io_memInfo_5_bits_w_datRsp,
  output          io_memInfo_6_valid,
  output [11:0]   io_memInfo_6_bits_set,
  output [27:0]   io_memInfo_6_bits_tag,
  output [6:0]    io_memInfo_6_bits_opcode,
  output [11:0]   io_memInfo_6_bits_reqID,
  output          io_memInfo_6_bits_w_datRsp,
  output          io_memInfo_7_valid,
  output [11:0]   io_memInfo_7_bits_set,
  output [27:0]   io_memInfo_7_bits_tag,
  output [6:0]    io_memInfo_7_bits_opcode,
  output [11:0]   io_memInfo_7_bits_reqID,
  output          io_memInfo_7_bits_w_datRsp,
  output          io_memInfo_8_valid,
  output [11:0]   io_memInfo_8_bits_set,
  output [27:0]   io_memInfo_8_bits_tag,
  output [6:0]    io_memInfo_8_bits_opcode,
  output [11:0]   io_memInfo_8_bits_reqID,
  output          io_memInfo_8_bits_w_datRsp,
  output          io_memInfo_9_valid,
  output [11:0]   io_memInfo_9_bits_set,
  output [27:0]   io_memInfo_9_bits_tag,
  output [6:0]    io_memInfo_9_bits_opcode,
  output [11:0]   io_memInfo_9_bits_reqID,
  output          io_memInfo_9_bits_w_datRsp,
  output          io_memInfo_10_valid,
  output [11:0]   io_memInfo_10_bits_set,
  output [27:0]   io_memInfo_10_bits_tag,
  output [6:0]    io_memInfo_10_bits_opcode,
  output [11:0]   io_memInfo_10_bits_reqID,
  output          io_memInfo_10_bits_w_datRsp,
  output          io_memInfo_11_valid,
  output [11:0]   io_memInfo_11_bits_set,
  output [27:0]   io_memInfo_11_bits_tag,
  output [6:0]    io_memInfo_11_bits_opcode,
  output [11:0]   io_memInfo_11_bits_reqID,
  output          io_memInfo_11_bits_w_datRsp,
  output          io_memInfo_12_valid,
  output [11:0]   io_memInfo_12_bits_set,
  output [27:0]   io_memInfo_12_bits_tag,
  output [6:0]    io_memInfo_12_bits_opcode,
  output [11:0]   io_memInfo_12_bits_reqID,
  output          io_memInfo_12_bits_w_datRsp,
  output          io_memInfo_13_valid,
  output [11:0]   io_memInfo_13_bits_set,
  output [27:0]   io_memInfo_13_bits_tag,
  output [6:0]    io_memInfo_13_bits_opcode,
  output [11:0]   io_memInfo_13_bits_reqID,
  output          io_memInfo_13_bits_w_datRsp,
  output          io_memInfo_14_valid,
  output [11:0]   io_memInfo_14_bits_set,
  output [27:0]   io_memInfo_14_bits_tag,
  output [6:0]    io_memInfo_14_bits_opcode,
  output [11:0]   io_memInfo_14_bits_reqID,
  output          io_memInfo_14_bits_w_datRsp,
  output          io_memInfo_15_valid,
  output [11:0]   io_memInfo_15_bits_set,
  output [27:0]   io_memInfo_15_bits_tag,
  output [6:0]    io_memInfo_15_bits_opcode,
  output [11:0]   io_memInfo_15_bits_reqID,
  output          io_memInfo_15_bits_w_datRsp,
  input           io_respInfo_0_valid,
  input  [6:0]    io_respInfo_0_bits_opcode,
  input  [11:0]   io_respInfo_0_bits_reqID,
  input           io_respInfo_0_bits_w_snpRsp,
  input           io_respInfo_0_bits_w_compdata,
  input           io_respInfo_1_valid,
  input  [6:0]    io_respInfo_1_bits_opcode,
  input  [11:0]   io_respInfo_1_bits_reqID,
  input           io_respInfo_1_bits_w_snpRsp,
  input           io_respInfo_1_bits_w_compdata,
  input           io_respInfo_2_valid,
  input  [6:0]    io_respInfo_2_bits_opcode,
  input  [11:0]   io_respInfo_2_bits_reqID,
  input           io_respInfo_2_bits_w_snpRsp,
  input           io_respInfo_2_bits_w_compdata,
  input           io_respInfo_3_valid,
  input  [6:0]    io_respInfo_3_bits_opcode,
  input  [11:0]   io_respInfo_3_bits_reqID,
  input           io_respInfo_3_bits_w_snpRsp,
  input           io_respInfo_3_bits_w_compdata,
  input           io_respInfo_4_valid,
  input  [6:0]    io_respInfo_4_bits_opcode,
  input  [11:0]   io_respInfo_4_bits_reqID,
  input           io_respInfo_4_bits_w_snpRsp,
  input           io_respInfo_4_bits_w_compdata,
  input           io_respInfo_5_valid,
  input  [6:0]    io_respInfo_5_bits_opcode,
  input  [11:0]   io_respInfo_5_bits_reqID,
  input           io_respInfo_5_bits_w_snpRsp,
  input           io_respInfo_5_bits_w_compdata,
  input           io_respInfo_6_valid,
  input  [6:0]    io_respInfo_6_bits_opcode,
  input  [11:0]   io_respInfo_6_bits_reqID,
  input           io_respInfo_6_bits_w_snpRsp,
  input           io_respInfo_6_bits_w_compdata,
  input           io_respInfo_7_valid,
  input  [6:0]    io_respInfo_7_bits_opcode,
  input  [11:0]   io_respInfo_7_bits_reqID,
  input           io_respInfo_7_bits_w_snpRsp,
  input           io_respInfo_7_bits_w_compdata,
  input           io_respInfo_8_valid,
  input  [6:0]    io_respInfo_8_bits_opcode,
  input  [11:0]   io_respInfo_8_bits_reqID,
  input           io_respInfo_8_bits_w_snpRsp,
  input           io_respInfo_8_bits_w_compdata,
  input           io_respInfo_9_valid,
  input  [6:0]    io_respInfo_9_bits_opcode,
  input  [11:0]   io_respInfo_9_bits_reqID,
  input           io_respInfo_9_bits_w_snpRsp,
  input           io_respInfo_9_bits_w_compdata,
  input           io_respInfo_10_valid,
  input  [6:0]    io_respInfo_10_bits_opcode,
  input  [11:0]   io_respInfo_10_bits_reqID,
  input           io_respInfo_10_bits_w_snpRsp,
  input           io_respInfo_10_bits_w_compdata,
  input           io_respInfo_11_valid,
  input  [6:0]    io_respInfo_11_bits_opcode,
  input  [11:0]   io_respInfo_11_bits_reqID,
  input           io_respInfo_11_bits_w_snpRsp,
  input           io_respInfo_11_bits_w_compdata,
  input           io_respInfo_12_valid,
  input  [6:0]    io_respInfo_12_bits_opcode,
  input  [11:0]   io_respInfo_12_bits_reqID,
  input           io_respInfo_12_bits_w_snpRsp,
  input           io_respInfo_12_bits_w_compdata,
  input           io_respInfo_13_valid,
  input  [6:0]    io_respInfo_13_bits_opcode,
  input  [11:0]   io_respInfo_13_bits_reqID,
  input           io_respInfo_13_bits_w_snpRsp,
  input           io_respInfo_13_bits_w_compdata,
  input           io_respInfo_14_valid,
  input  [6:0]    io_respInfo_14_bits_opcode,
  input  [11:0]   io_respInfo_14_bits_reqID,
  input           io_respInfo_14_bits_w_snpRsp,
  input           io_respInfo_14_bits_w_compdata,
  input           io_respInfo_15_valid,
  input  [6:0]    io_respInfo_15_bits_opcode,
  input  [11:0]   io_respInfo_15_bits_reqID,
  input           io_respInfo_15_bits_w_snpRsp,
  input           io_respInfo_15_bits_w_compdata
);

  // -------- alloc_s4 打包 --------
  alloc_s4_t alloc_s4;
  mem_task_t s4_task;
  assign s4_task = '{
    set: io_fromMainPipe_alloc_s4_bits_task_set,
    bank: io_fromMainPipe_alloc_s4_bits_task_bank,
    tag: io_fromMainPipe_alloc_s4_bits_task_tag,
    off: io_fromMainPipe_alloc_s4_bits_task_off,
    size: '0,
    refillTask: io_fromMainPipe_alloc_s4_bits_task_refillTask,
    bufID: io_fromMainPipe_alloc_s4_bits_task_bufID,
    reqID: io_fromMainPipe_alloc_s4_bits_task_reqID,
    replSnp: io_fromMainPipe_alloc_s4_bits_task_replSnp,
    snpVec_0: io_fromMainPipe_alloc_s4_bits_task_snpVec_0,
    tgtID: io_fromMainPipe_alloc_s4_bits_task_tgtID,
    srcID: io_fromMainPipe_alloc_s4_bits_task_srcID,
    txnID: io_fromMainPipe_alloc_s4_bits_task_txnID,
    homeNID: io_fromMainPipe_alloc_s4_bits_task_homeNID,
    dbID: io_fromMainPipe_alloc_s4_bits_task_dbID,
    fwdNID: io_fromMainPipe_alloc_s4_bits_task_fwdNID,
    fwdTxnID: io_fromMainPipe_alloc_s4_bits_task_fwdTxnID,
    chiOpcode: io_fromMainPipe_alloc_s4_bits_task_chiOpcode,
    resp: io_fromMainPipe_alloc_s4_bits_task_resp,
    fwdState: io_fromMainPipe_alloc_s4_bits_task_fwdState,
    pCrdType: io_fromMainPipe_alloc_s4_bits_task_pCrdType,
    retToSrc: io_fromMainPipe_alloc_s4_bits_task_retToSrc,
    doNotGoToSD: io_fromMainPipe_alloc_s4_bits_task_doNotGoToSD,
    expCompAck: '0,
    allowRetry: '0,
    order: '0,
    memAttr_allocate: '0,
    memAttr_cacheable: '0,
    memAttr_device: '0,
    memAttr_ewa: '0,
    snpAttr: '0
  };
  assign alloc_s4 = '{
    state_s_issueDat: io_fromMainPipe_alloc_s4_bits_state_s_issueDat,
    state_w_datRsp:   io_fromMainPipe_alloc_s4_bits_state_w_datRsp,
    state_w_dbid:     io_fromMainPipe_alloc_s4_bits_state_w_dbid,
    state_w_comp:     io_fromMainPipe_alloc_s4_bits_state_w_comp,
    task_bits:        s4_task
  };

  // -------- alloc_s6 打包 --------
  alloc_s6_t alloc_s6;
  mem_task_t s6_task;
  assign s6_task = '{
    set: io_fromMainPipe_alloc_s6_bits_task_set,
    bank: io_fromMainPipe_alloc_s6_bits_task_bank,
    tag: io_fromMainPipe_alloc_s6_bits_task_tag,
    off: io_fromMainPipe_alloc_s6_bits_task_off,
    size: io_fromMainPipe_alloc_s6_bits_task_size,
    refillTask: io_fromMainPipe_alloc_s6_bits_task_refillTask,
    bufID: io_fromMainPipe_alloc_s6_bits_task_bufID,
    reqID: io_fromMainPipe_alloc_s6_bits_task_reqID,
    replSnp: io_fromMainPipe_alloc_s6_bits_task_replSnp,
    snpVec_0: io_fromMainPipe_alloc_s6_bits_task_snpVec_0,
    tgtID: io_fromMainPipe_alloc_s6_bits_task_tgtID,
    srcID: io_fromMainPipe_alloc_s6_bits_task_srcID,
    txnID: io_fromMainPipe_alloc_s6_bits_task_txnID,
    homeNID: io_fromMainPipe_alloc_s6_bits_task_homeNID,
    dbID: io_fromMainPipe_alloc_s6_bits_task_dbID,
    fwdNID: io_fromMainPipe_alloc_s6_bits_task_fwdNID,
    fwdTxnID: io_fromMainPipe_alloc_s6_bits_task_fwdTxnID,
    chiOpcode: io_fromMainPipe_alloc_s6_bits_task_chiOpcode,
    resp: io_fromMainPipe_alloc_s6_bits_task_resp,
    fwdState: io_fromMainPipe_alloc_s6_bits_task_fwdState,
    pCrdType: io_fromMainPipe_alloc_s6_bits_task_pCrdType,
    retToSrc: io_fromMainPipe_alloc_s6_bits_task_retToSrc,
    doNotGoToSD: io_fromMainPipe_alloc_s6_bits_task_doNotGoToSD,
    expCompAck: io_fromMainPipe_alloc_s6_bits_task_expCompAck,
    allowRetry: io_fromMainPipe_alloc_s6_bits_task_allowRetry,
    order: io_fromMainPipe_alloc_s6_bits_task_order,
    memAttr_allocate: io_fromMainPipe_alloc_s6_bits_task_memAttr_allocate,
    memAttr_cacheable: io_fromMainPipe_alloc_s6_bits_task_memAttr_cacheable,
    memAttr_device: io_fromMainPipe_alloc_s6_bits_task_memAttr_device,
    memAttr_ewa: io_fromMainPipe_alloc_s6_bits_task_memAttr_ewa,
    snpAttr: io_fromMainPipe_alloc_s6_bits_task_snpAttr
  };
  assign alloc_s6 = '{
    task_bits: s6_task,
    data0:     io_fromMainPipe_alloc_s6_bits_data_data_0_data,
    data1:     io_fromMainPipe_alloc_s6_bits_data_data_1_data
  };

  // -------- respInfo 打包为数组 --------
  resp_info_t [15:0] respArr;
  assign respArr[0] = '{valid: io_respInfo_0_valid, opcode: io_respInfo_0_bits_opcode, reqID: io_respInfo_0_bits_reqID, w_snpRsp: io_respInfo_0_bits_w_snpRsp, w_compdata: io_respInfo_0_bits_w_compdata};
  assign respArr[1] = '{valid: io_respInfo_1_valid, opcode: io_respInfo_1_bits_opcode, reqID: io_respInfo_1_bits_reqID, w_snpRsp: io_respInfo_1_bits_w_snpRsp, w_compdata: io_respInfo_1_bits_w_compdata};
  assign respArr[2] = '{valid: io_respInfo_2_valid, opcode: io_respInfo_2_bits_opcode, reqID: io_respInfo_2_bits_reqID, w_snpRsp: io_respInfo_2_bits_w_snpRsp, w_compdata: io_respInfo_2_bits_w_compdata};
  assign respArr[3] = '{valid: io_respInfo_3_valid, opcode: io_respInfo_3_bits_opcode, reqID: io_respInfo_3_bits_reqID, w_snpRsp: io_respInfo_3_bits_w_snpRsp, w_compdata: io_respInfo_3_bits_w_compdata};
  assign respArr[4] = '{valid: io_respInfo_4_valid, opcode: io_respInfo_4_bits_opcode, reqID: io_respInfo_4_bits_reqID, w_snpRsp: io_respInfo_4_bits_w_snpRsp, w_compdata: io_respInfo_4_bits_w_compdata};
  assign respArr[5] = '{valid: io_respInfo_5_valid, opcode: io_respInfo_5_bits_opcode, reqID: io_respInfo_5_bits_reqID, w_snpRsp: io_respInfo_5_bits_w_snpRsp, w_compdata: io_respInfo_5_bits_w_compdata};
  assign respArr[6] = '{valid: io_respInfo_6_valid, opcode: io_respInfo_6_bits_opcode, reqID: io_respInfo_6_bits_reqID, w_snpRsp: io_respInfo_6_bits_w_snpRsp, w_compdata: io_respInfo_6_bits_w_compdata};
  assign respArr[7] = '{valid: io_respInfo_7_valid, opcode: io_respInfo_7_bits_opcode, reqID: io_respInfo_7_bits_reqID, w_snpRsp: io_respInfo_7_bits_w_snpRsp, w_compdata: io_respInfo_7_bits_w_compdata};
  assign respArr[8] = '{valid: io_respInfo_8_valid, opcode: io_respInfo_8_bits_opcode, reqID: io_respInfo_8_bits_reqID, w_snpRsp: io_respInfo_8_bits_w_snpRsp, w_compdata: io_respInfo_8_bits_w_compdata};
  assign respArr[9] = '{valid: io_respInfo_9_valid, opcode: io_respInfo_9_bits_opcode, reqID: io_respInfo_9_bits_reqID, w_snpRsp: io_respInfo_9_bits_w_snpRsp, w_compdata: io_respInfo_9_bits_w_compdata};
  assign respArr[10] = '{valid: io_respInfo_10_valid, opcode: io_respInfo_10_bits_opcode, reqID: io_respInfo_10_bits_reqID, w_snpRsp: io_respInfo_10_bits_w_snpRsp, w_compdata: io_respInfo_10_bits_w_compdata};
  assign respArr[11] = '{valid: io_respInfo_11_valid, opcode: io_respInfo_11_bits_opcode, reqID: io_respInfo_11_bits_reqID, w_snpRsp: io_respInfo_11_bits_w_snpRsp, w_compdata: io_respInfo_11_bits_w_compdata};
  assign respArr[12] = '{valid: io_respInfo_12_valid, opcode: io_respInfo_12_bits_opcode, reqID: io_respInfo_12_bits_reqID, w_snpRsp: io_respInfo_12_bits_w_snpRsp, w_compdata: io_respInfo_12_bits_w_compdata};
  assign respArr[13] = '{valid: io_respInfo_13_valid, opcode: io_respInfo_13_bits_opcode, reqID: io_respInfo_13_bits_reqID, w_snpRsp: io_respInfo_13_bits_w_snpRsp, w_compdata: io_respInfo_13_bits_w_compdata};
  assign respArr[14] = '{valid: io_respInfo_14_valid, opcode: io_respInfo_14_bits_opcode, reqID: io_respInfo_14_bits_reqID, w_snpRsp: io_respInfo_14_bits_w_snpRsp, w_compdata: io_respInfo_14_bits_w_compdata};
  assign respArr[15] = '{valid: io_respInfo_15_valid, opcode: io_respInfo_15_bits_opcode, reqID: io_respInfo_15_bits_reqID, w_snpRsp: io_respInfo_15_bits_w_snpRsp, w_compdata: io_respInfo_15_bits_w_compdata};

  // -------- memInfo 数组 ↔ 扁平输出 --------
  logic [15:0]        mi_valid;
  logic [11:0]        mi_set    [15:0];
  logic [27:0]        mi_tag    [15:0];
  logic [6:0]         mi_opcode [15:0];
  logic [11:0]        mi_reqID  [15:0];
  logic               mi_wdat   [15:0];
  assign io_memInfo_0_valid = mi_valid[0];
  assign io_memInfo_0_bits_set = mi_set[0];
  assign io_memInfo_0_bits_tag = mi_tag[0];
  assign io_memInfo_0_bits_opcode = mi_opcode[0];
  assign io_memInfo_0_bits_reqID = mi_reqID[0];
  assign io_memInfo_0_bits_w_datRsp = mi_wdat[0];
  assign io_memInfo_1_valid = mi_valid[1];
  assign io_memInfo_1_bits_set = mi_set[1];
  assign io_memInfo_1_bits_tag = mi_tag[1];
  assign io_memInfo_1_bits_opcode = mi_opcode[1];
  assign io_memInfo_1_bits_reqID = mi_reqID[1];
  assign io_memInfo_1_bits_w_datRsp = mi_wdat[1];
  assign io_memInfo_2_valid = mi_valid[2];
  assign io_memInfo_2_bits_set = mi_set[2];
  assign io_memInfo_2_bits_tag = mi_tag[2];
  assign io_memInfo_2_bits_opcode = mi_opcode[2];
  assign io_memInfo_2_bits_reqID = mi_reqID[2];
  assign io_memInfo_2_bits_w_datRsp = mi_wdat[2];
  assign io_memInfo_3_valid = mi_valid[3];
  assign io_memInfo_3_bits_set = mi_set[3];
  assign io_memInfo_3_bits_tag = mi_tag[3];
  assign io_memInfo_3_bits_opcode = mi_opcode[3];
  assign io_memInfo_3_bits_reqID = mi_reqID[3];
  assign io_memInfo_3_bits_w_datRsp = mi_wdat[3];
  assign io_memInfo_4_valid = mi_valid[4];
  assign io_memInfo_4_bits_set = mi_set[4];
  assign io_memInfo_4_bits_tag = mi_tag[4];
  assign io_memInfo_4_bits_opcode = mi_opcode[4];
  assign io_memInfo_4_bits_reqID = mi_reqID[4];
  assign io_memInfo_4_bits_w_datRsp = mi_wdat[4];
  assign io_memInfo_5_valid = mi_valid[5];
  assign io_memInfo_5_bits_set = mi_set[5];
  assign io_memInfo_5_bits_tag = mi_tag[5];
  assign io_memInfo_5_bits_opcode = mi_opcode[5];
  assign io_memInfo_5_bits_reqID = mi_reqID[5];
  assign io_memInfo_5_bits_w_datRsp = mi_wdat[5];
  assign io_memInfo_6_valid = mi_valid[6];
  assign io_memInfo_6_bits_set = mi_set[6];
  assign io_memInfo_6_bits_tag = mi_tag[6];
  assign io_memInfo_6_bits_opcode = mi_opcode[6];
  assign io_memInfo_6_bits_reqID = mi_reqID[6];
  assign io_memInfo_6_bits_w_datRsp = mi_wdat[6];
  assign io_memInfo_7_valid = mi_valid[7];
  assign io_memInfo_7_bits_set = mi_set[7];
  assign io_memInfo_7_bits_tag = mi_tag[7];
  assign io_memInfo_7_bits_opcode = mi_opcode[7];
  assign io_memInfo_7_bits_reqID = mi_reqID[7];
  assign io_memInfo_7_bits_w_datRsp = mi_wdat[7];
  assign io_memInfo_8_valid = mi_valid[8];
  assign io_memInfo_8_bits_set = mi_set[8];
  assign io_memInfo_8_bits_tag = mi_tag[8];
  assign io_memInfo_8_bits_opcode = mi_opcode[8];
  assign io_memInfo_8_bits_reqID = mi_reqID[8];
  assign io_memInfo_8_bits_w_datRsp = mi_wdat[8];
  assign io_memInfo_9_valid = mi_valid[9];
  assign io_memInfo_9_bits_set = mi_set[9];
  assign io_memInfo_9_bits_tag = mi_tag[9];
  assign io_memInfo_9_bits_opcode = mi_opcode[9];
  assign io_memInfo_9_bits_reqID = mi_reqID[9];
  assign io_memInfo_9_bits_w_datRsp = mi_wdat[9];
  assign io_memInfo_10_valid = mi_valid[10];
  assign io_memInfo_10_bits_set = mi_set[10];
  assign io_memInfo_10_bits_tag = mi_tag[10];
  assign io_memInfo_10_bits_opcode = mi_opcode[10];
  assign io_memInfo_10_bits_reqID = mi_reqID[10];
  assign io_memInfo_10_bits_w_datRsp = mi_wdat[10];
  assign io_memInfo_11_valid = mi_valid[11];
  assign io_memInfo_11_bits_set = mi_set[11];
  assign io_memInfo_11_bits_tag = mi_tag[11];
  assign io_memInfo_11_bits_opcode = mi_opcode[11];
  assign io_memInfo_11_bits_reqID = mi_reqID[11];
  assign io_memInfo_11_bits_w_datRsp = mi_wdat[11];
  assign io_memInfo_12_valid = mi_valid[12];
  assign io_memInfo_12_bits_set = mi_set[12];
  assign io_memInfo_12_bits_tag = mi_tag[12];
  assign io_memInfo_12_bits_opcode = mi_opcode[12];
  assign io_memInfo_12_bits_reqID = mi_reqID[12];
  assign io_memInfo_12_bits_w_datRsp = mi_wdat[12];
  assign io_memInfo_13_valid = mi_valid[13];
  assign io_memInfo_13_bits_set = mi_set[13];
  assign io_memInfo_13_bits_tag = mi_tag[13];
  assign io_memInfo_13_bits_opcode = mi_opcode[13];
  assign io_memInfo_13_bits_reqID = mi_reqID[13];
  assign io_memInfo_13_bits_w_datRsp = mi_wdat[13];
  assign io_memInfo_14_valid = mi_valid[14];
  assign io_memInfo_14_bits_set = mi_set[14];
  assign io_memInfo_14_bits_tag = mi_tag[14];
  assign io_memInfo_14_bits_opcode = mi_opcode[14];
  assign io_memInfo_14_bits_reqID = mi_reqID[14];
  assign io_memInfo_14_bits_w_datRsp = mi_wdat[14];
  assign io_memInfo_15_valid = mi_valid[15];
  assign io_memInfo_15_bits_set = mi_set[15];
  assign io_memInfo_15_bits_tag = mi_tag[15];
  assign io_memInfo_15_bits_opcode = mi_opcode[15];
  assign io_memInfo_15_bits_reqID = mi_reqID[15];
  assign io_memInfo_15_bits_w_datRsp = mi_wdat[15];

  xs_MemUnit_core u_core (
    .clock (clock),
    .reset (reset),
    .io_alloc_s4_valid (io_fromMainPipe_alloc_s4_valid),
    .io_alloc_s4 (alloc_s4),
    .io_alloc_s6_valid (io_fromMainPipe_alloc_s6_valid),
    .io_alloc_s6 (alloc_s6),
    .io_urgentRead_valid (io_urgentRead_valid),
    .io_urgentRead_ready (io_urgentRead_ready),
    .io_urgentRead_bits_set (io_urgentRead_bits_set),
    .io_urgentRead_bits_bank (io_urgentRead_bits_bank),
    .io_urgentRead_bits_tag (io_urgentRead_bits_tag),
    .io_urgentRead_bits_tgtID (io_urgentRead_bits_tgtID),
    .io_urgentRead_bits_srcID (io_urgentRead_bits_srcID),
    .io_urgentRead_bits_txnID (io_urgentRead_bits_txnID),
    .io_urgentRead_bits_pCrdType (io_urgentRead_bits_pCrdType),
    .io_snRxrsp_valid (io_snRxrsp_valid),
    .io_snRxrsp_bits_txnID (io_snRxrsp_bits_txnID),
    .io_snRxrsp_bits_dbID (io_snRxrsp_bits_dbID),
    .io_snRxrsp_bits_opcode (io_snRxrsp_bits_opcode),
    .io_rnRxdat_valid (io_rnRxdat_valid),
    .io_rnRxdat_bits_txnID (io_rnRxdat_bits_txnID),
    .io_rnRxdat_bits_resp (io_rnRxdat_bits_resp),
    .io_rnRxdat_bits_dataID (io_rnRxdat_bits_dataID),
    .io_rnRxdat_bits_data_data (io_rnRxdat_bits_data_data),
    .io_rnRxrsp_valid (io_rnRxrsp_valid),
    .io_rnRxrsp_bits_txnID (io_rnRxrsp_bits_txnID),
    .io_txreq_ready (io_txreq_ready),
    .io_txreq_valid (io_txreq_valid),
    .io_txreq_bits_set (io_txreq_bits_set),
    .io_txreq_bits_bank (io_txreq_bits_bank),
    .io_txreq_bits_tag (io_txreq_bits_tag),
    .io_txreq_bits_size (io_txreq_bits_size),
    .io_txreq_bits_tgtID (io_txreq_bits_tgtID),
    .io_txreq_bits_srcID (io_txreq_bits_srcID),
    .io_txreq_bits_txnID (io_txreq_bits_txnID),
    .io_txreq_bits_chiOpcode (io_txreq_bits_chiOpcode),
    .io_txreq_bits_pCrdType (io_txreq_bits_pCrdType),
    .io_txreq_bits_expCompAck (io_txreq_bits_expCompAck),
    .io_txreq_bits_allowRetry (io_txreq_bits_allowRetry),
    .io_txreq_bits_order (io_txreq_bits_order),
    .io_txreq_bits_memAttr_allocate (io_txreq_bits_memAttr_allocate),
    .io_txreq_bits_memAttr_cacheable (io_txreq_bits_memAttr_cacheable),
    .io_txreq_bits_memAttr_device (io_txreq_bits_memAttr_device),
    .io_txreq_bits_memAttr_ewa (io_txreq_bits_memAttr_ewa),
    .io_txreq_bits_snpAttr (io_txreq_bits_snpAttr),
    .io_txdat_ready (io_txdat_ready),
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
    .io_bypassData_0_valid (io_bypassData_0_valid),
    .io_bypassData_0_bits_txnID (io_bypassData_0_bits_txnID),
    .io_bypassData_0_bits_opcode (io_bypassData_0_bits_opcode),
    .io_bypassData_0_bits_data_data (io_bypassData_0_bits_data_data),
    .io_bypassData_1_valid (io_bypassData_1_valid),
    .io_bypassData_1_bits_txnID (io_bypassData_1_bits_txnID),
    .io_bypassData_1_bits_opcode (io_bypassData_1_bits_opcode),
    .io_bypassData_1_bits_dataID (io_bypassData_1_bits_dataID),
    .io_bypassData_1_bits_data_data (io_bypassData_1_bits_data_data),
    .io_memInfo_valid (mi_valid),
    .io_memInfo_set (mi_set),
    .io_memInfo_tag (mi_tag),
    .io_memInfo_opcode (mi_opcode),
    .io_memInfo_reqID (mi_reqID),
    .io_memInfo_w_datRsp (mi_wdat),
    .io_respInfo (respArr)
  );

endmodule
