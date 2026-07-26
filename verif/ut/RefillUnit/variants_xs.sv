// RefillUnit 包装层(golden 同名扁平端口 ↔ xs_RefillUnit_core 的 struct/数组端口)。
// 仅做机械端口打包/拆包, 供 FM 对比与 ST 替换。
module RefillUnit_xs
  import xs_refillunit_pkg::*;
(
  input          clock,
  input          reset,
  input          io_alloc_valid,
  input          io_alloc_bits_state_w_snpRsp,
  input  [11:0]  io_alloc_bits_task_set,
  input  [1:0]   io_alloc_bits_task_bank,
  input  [27:0]  io_alloc_bits_task_tag,
  input  [5:0]   io_alloc_bits_task_off,
  input  [2:0]   io_alloc_bits_task_size,
  input  [3:0]   io_alloc_bits_task_bufID,
  input  [11:0]  io_alloc_bits_task_reqID,
  input          io_alloc_bits_task_replSnp,
  input          io_alloc_bits_task_snpVec_0,
  input  [10:0]  io_alloc_bits_task_tgtID,
  input  [10:0]  io_alloc_bits_task_srcID,
  input  [11:0]  io_alloc_bits_task_txnID,
  input  [11:0]  io_alloc_bits_task_dbID,
  input  [10:0]  io_alloc_bits_task_fwdNID,
  input  [11:0]  io_alloc_bits_task_fwdTxnID,
  input  [6:0]   io_alloc_bits_task_chiOpcode,
  input  [2:0]   io_alloc_bits_task_resp,
  input  [2:0]   io_alloc_bits_task_fwdState,
  input  [3:0]   io_alloc_bits_task_pCrdType,
  input          io_alloc_bits_task_retToSrc,
  input          io_alloc_bits_task_doNotGoToSD,
  input          io_alloc_bits_task_expCompAck,
  input          io_alloc_bits_task_allowRetry,
  input  [1:0]   io_alloc_bits_task_order,
  input          io_alloc_bits_task_memAttr_allocate,
  input          io_alloc_bits_task_memAttr_cacheable,
  input          io_alloc_bits_task_memAttr_device,
  input          io_alloc_bits_task_memAttr_ewa,
  input          io_alloc_bits_task_snpAttr,
  input          io_alloc_bits_dirResult_clients_hit,
  input          io_alloc_bits_dirResult_clients_meta_0_valid,
  input          io_alloc_bits_isWrite,
  input          io_task_ready,
  output         io_task_valid,
  output [11:0]  io_task_bits_set,
  output [1:0]   io_task_bits_bank,
  output [27:0]  io_task_bits_tag,
  output [5:0]   io_task_bits_off,
  output [2:0]   io_task_bits_size,
  output         io_task_bits_refillTask,
  output [3:0]   io_task_bits_bufID,
  output [11:0]  io_task_bits_reqID,
  output         io_task_bits_replSnp,
  output         io_task_bits_snpVec_0,
  output [10:0]  io_task_bits_tgtID,
  output [10:0]  io_task_bits_srcID,
  output [11:0]  io_task_bits_txnID,
  output [11:0]  io_task_bits_dbID,
  output [10:0]  io_task_bits_fwdNID,
  output [11:0]  io_task_bits_fwdTxnID,
  output [6:0]   io_task_bits_chiOpcode,
  output [2:0]   io_task_bits_resp,
  output [2:0]   io_task_bits_fwdState,
  output [3:0]   io_task_bits_pCrdType,
  output         io_task_bits_retToSrc,
  output         io_task_bits_doNotGoToSD,
  output         io_task_bits_expCompAck,
  output         io_task_bits_allowRetry,
  output [1:0]   io_task_bits_order,
  output         io_task_bits_memAttr_allocate,
  output         io_task_bits_memAttr_cacheable,
  output         io_task_bits_memAttr_device,
  output         io_task_bits_memAttr_ewa,
  output         io_task_bits_snpAttr,
  input          io_respData_valid,
  input  [11:0]  io_respData_bits_txnID,
  input  [6:0]   io_respData_bits_opcode,
  input  [2:0]   io_respData_bits_resp,
  input  [10:0]  io_respData_bits_srcID,
  input  [1:0]   io_respData_bits_dataID,
  input  [255:0] io_respData_bits_data_data,
  input          io_resp_valid,
  input  [11:0]  io_resp_bits_txnID,
  input  [6:0]   io_resp_bits_opcode,
  input  [10:0]  io_resp_bits_srcID,
  input          io_read_valid,
  input  [3:0]   io_read_bits_id,
  output [255:0] io_data_data_0_data,
  output [255:0] io_data_data_1_data,
  output         io_refillInfo_0_valid,
  output [11:0]  io_refillInfo_0_bits_set,
  output [27:0]  io_refillInfo_0_bits_tag,
  output [11:0]  io_refillInfo_0_bits_reqID,
  output         io_refillInfo_1_valid,
  output [11:0]  io_refillInfo_1_bits_set,
  output [27:0]  io_refillInfo_1_bits_tag,
  output [11:0]  io_refillInfo_1_bits_reqID,
  output         io_refillInfo_2_valid,
  output [11:0]  io_refillInfo_2_bits_set,
  output [27:0]  io_refillInfo_2_bits_tag,
  output [11:0]  io_refillInfo_2_bits_reqID,
  output         io_refillInfo_3_valid,
  output [11:0]  io_refillInfo_3_bits_set,
  output [27:0]  io_refillInfo_3_bits_tag,
  output [11:0]  io_refillInfo_3_bits_reqID,
  output         io_refillInfo_4_valid,
  output [11:0]  io_refillInfo_4_bits_set,
  output [27:0]  io_refillInfo_4_bits_tag,
  output [11:0]  io_refillInfo_4_bits_reqID,
  output         io_refillInfo_5_valid,
  output [11:0]  io_refillInfo_5_bits_set,
  output [27:0]  io_refillInfo_5_bits_tag,
  output [11:0]  io_refillInfo_5_bits_reqID,
  output         io_refillInfo_6_valid,
  output [11:0]  io_refillInfo_6_bits_set,
  output [27:0]  io_refillInfo_6_bits_tag,
  output [11:0]  io_refillInfo_6_bits_reqID,
  output         io_refillInfo_7_valid,
  output [11:0]  io_refillInfo_7_bits_set,
  output [27:0]  io_refillInfo_7_bits_tag,
  output [11:0]  io_refillInfo_7_bits_reqID,
  output         io_refillInfo_8_valid,
  output [11:0]  io_refillInfo_8_bits_set,
  output [27:0]  io_refillInfo_8_bits_tag,
  output [11:0]  io_refillInfo_8_bits_reqID,
  output         io_refillInfo_9_valid,
  output [11:0]  io_refillInfo_9_bits_set,
  output [27:0]  io_refillInfo_9_bits_tag,
  output [11:0]  io_refillInfo_9_bits_reqID,
  output         io_refillInfo_10_valid,
  output [11:0]  io_refillInfo_10_bits_set,
  output [27:0]  io_refillInfo_10_bits_tag,
  output [11:0]  io_refillInfo_10_bits_reqID,
  output         io_refillInfo_11_valid,
  output [11:0]  io_refillInfo_11_bits_set,
  output [27:0]  io_refillInfo_11_bits_tag,
  output [11:0]  io_refillInfo_11_bits_reqID,
  output         io_refillInfo_12_valid,
  output [11:0]  io_refillInfo_12_bits_set,
  output [27:0]  io_refillInfo_12_bits_tag,
  output [11:0]  io_refillInfo_12_bits_reqID,
  output         io_refillInfo_13_valid,
  output [11:0]  io_refillInfo_13_bits_set,
  output [27:0]  io_refillInfo_13_bits_tag,
  output [11:0]  io_refillInfo_13_bits_reqID,
  output         io_refillInfo_14_valid,
  output [11:0]  io_refillInfo_14_bits_set,
  output [27:0]  io_refillInfo_14_bits_tag,
  output [11:0]  io_refillInfo_14_bits_reqID,
  output         io_refillInfo_15_valid,
  output [11:0]  io_refillInfo_15_bits_set,
  output [27:0]  io_refillInfo_15_bits_tag,
  output [11:0]  io_refillInfo_15_bits_reqID
);

  // 入站 alloc task 打包(refillTask/bufID 由核内处理: refillTask 入队粘 1, bufID=insertIdx)
  task_t alloc_task;
  assign alloc_task = '{
    set:               io_alloc_bits_task_set,
    bank:              io_alloc_bits_task_bank,
    tag:               io_alloc_bits_task_tag,
    off:               io_alloc_bits_task_off,
    size:              io_alloc_bits_task_size,
    refillTask:        1'b0,
    bufID:             io_alloc_bits_task_bufID,
    reqID:             io_alloc_bits_task_reqID,
    replSnp:           io_alloc_bits_task_replSnp,
    snpVec_0:          io_alloc_bits_task_snpVec_0,
    tgtID:             io_alloc_bits_task_tgtID,
    srcID:             io_alloc_bits_task_srcID,
    txnID:             io_alloc_bits_task_txnID,
    dbID:              io_alloc_bits_task_dbID,
    fwdNID:            io_alloc_bits_task_fwdNID,
    fwdTxnID:          io_alloc_bits_task_fwdTxnID,
    chiOpcode:         io_alloc_bits_task_chiOpcode,
    resp:              io_alloc_bits_task_resp,
    fwdState:          io_alloc_bits_task_fwdState,
    pCrdType:          io_alloc_bits_task_pCrdType,
    retToSrc:          io_alloc_bits_task_retToSrc,
    doNotGoToSD:       io_alloc_bits_task_doNotGoToSD,
    expCompAck:        io_alloc_bits_task_expCompAck,
    allowRetry:        io_alloc_bits_task_allowRetry,
    order:             io_alloc_bits_task_order,
    memAttr_allocate:  io_alloc_bits_task_memAttr_allocate,
    memAttr_cacheable: io_alloc_bits_task_memAttr_cacheable,
    memAttr_device:    io_alloc_bits_task_memAttr_device,
    memAttr_ewa:       io_alloc_bits_task_memAttr_ewa,
    snpAttr:           io_alloc_bits_task_snpAttr
  };

  task_t                task_bits;
  logic [15:0]          rif_valid;
  logic [15:0][11:0]    rif_set;
  logic [15:0][27:0]    rif_tag;
  logic [15:0][11:0]    rif_reqID;

  xs_RefillUnit_core u_core (
    .clock                                        (clock),
    .reset                                        (reset),
    .io_alloc_valid                               (io_alloc_valid),
    .io_alloc_bits_state_w_snpRsp                 (io_alloc_bits_state_w_snpRsp),
    .io_alloc_task                                (alloc_task),
    .io_alloc_bits_dirResult_clients_hit          (io_alloc_bits_dirResult_clients_hit),
    .io_alloc_bits_dirResult_clients_meta_0_valid (io_alloc_bits_dirResult_clients_meta_0_valid),
    .io_alloc_bits_isWrite                        (io_alloc_bits_isWrite),
    .io_task_ready                                (io_task_ready),
    .io_task_valid                                (io_task_valid),
    .io_task_bits                                 (task_bits),
    .io_respData_valid                            (io_respData_valid),
    .io_respData_bits_txnID                       (io_respData_bits_txnID),
    .io_respData_bits_opcode                      (io_respData_bits_opcode),
    .io_respData_bits_resp                        (io_respData_bits_resp),
    .io_respData_bits_srcID                       (io_respData_bits_srcID),
    .io_respData_bits_dataID                      (io_respData_bits_dataID),
    .io_respData_bits_data_data                   (io_respData_bits_data_data),
    .io_resp_valid                                (io_resp_valid),
    .io_resp_bits_txnID                           (io_resp_bits_txnID),
    .io_resp_bits_opcode                          (io_resp_bits_opcode),
    .io_resp_bits_srcID                           (io_resp_bits_srcID),
    .io_read_valid                                (io_read_valid),
    .io_read_bits_id                              (io_read_bits_id),
    .io_data_data_0_data                          (io_data_data_0_data),
    .io_data_data_1_data                          (io_data_data_1_data),
    .io_refillInfo_valid                          (rif_valid),
    .io_refillInfo_set                            (rif_set),
    .io_refillInfo_tag                            (rif_tag),
    .io_refillInfo_reqID                          (rif_reqID)
  );

  // task 输出拆包
  assign io_task_bits_set               = task_bits.set;
  assign io_task_bits_bank              = task_bits.bank;
  assign io_task_bits_tag               = task_bits.tag;
  assign io_task_bits_off               = task_bits.off;
  assign io_task_bits_size              = task_bits.size;
  assign io_task_bits_refillTask        = task_bits.refillTask;
  assign io_task_bits_bufID             = task_bits.bufID;
  assign io_task_bits_reqID             = task_bits.reqID;
  assign io_task_bits_replSnp           = task_bits.replSnp;
  assign io_task_bits_snpVec_0          = task_bits.snpVec_0;
  assign io_task_bits_tgtID             = task_bits.tgtID;
  assign io_task_bits_srcID             = task_bits.srcID;
  assign io_task_bits_txnID             = task_bits.txnID;
  assign io_task_bits_dbID              = task_bits.dbID;
  assign io_task_bits_fwdNID            = task_bits.fwdNID;
  assign io_task_bits_fwdTxnID          = task_bits.fwdTxnID;
  assign io_task_bits_chiOpcode         = task_bits.chiOpcode;
  assign io_task_bits_resp              = task_bits.resp;
  assign io_task_bits_fwdState          = task_bits.fwdState;
  assign io_task_bits_pCrdType          = task_bits.pCrdType;
  assign io_task_bits_retToSrc          = task_bits.retToSrc;
  assign io_task_bits_doNotGoToSD       = task_bits.doNotGoToSD;
  assign io_task_bits_expCompAck        = task_bits.expCompAck;
  assign io_task_bits_allowRetry        = task_bits.allowRetry;
  assign io_task_bits_order             = task_bits.order;
  assign io_task_bits_memAttr_allocate  = task_bits.memAttr_allocate;
  assign io_task_bits_memAttr_cacheable = task_bits.memAttr_cacheable;
  assign io_task_bits_memAttr_device    = task_bits.memAttr_device;
  assign io_task_bits_memAttr_ewa       = task_bits.memAttr_ewa;
  assign io_task_bits_snpAttr           = task_bits.snpAttr;

  // refillInfo 拆包(16 路)
  assign io_refillInfo_0_valid  = rif_valid[0];  assign io_refillInfo_0_bits_set  = rif_set[0];  assign io_refillInfo_0_bits_tag  = rif_tag[0];  assign io_refillInfo_0_bits_reqID  = rif_reqID[0];
  assign io_refillInfo_1_valid  = rif_valid[1];  assign io_refillInfo_1_bits_set  = rif_set[1];  assign io_refillInfo_1_bits_tag  = rif_tag[1];  assign io_refillInfo_1_bits_reqID  = rif_reqID[1];
  assign io_refillInfo_2_valid  = rif_valid[2];  assign io_refillInfo_2_bits_set  = rif_set[2];  assign io_refillInfo_2_bits_tag  = rif_tag[2];  assign io_refillInfo_2_bits_reqID  = rif_reqID[2];
  assign io_refillInfo_3_valid  = rif_valid[3];  assign io_refillInfo_3_bits_set  = rif_set[3];  assign io_refillInfo_3_bits_tag  = rif_tag[3];  assign io_refillInfo_3_bits_reqID  = rif_reqID[3];
  assign io_refillInfo_4_valid  = rif_valid[4];  assign io_refillInfo_4_bits_set  = rif_set[4];  assign io_refillInfo_4_bits_tag  = rif_tag[4];  assign io_refillInfo_4_bits_reqID  = rif_reqID[4];
  assign io_refillInfo_5_valid  = rif_valid[5];  assign io_refillInfo_5_bits_set  = rif_set[5];  assign io_refillInfo_5_bits_tag  = rif_tag[5];  assign io_refillInfo_5_bits_reqID  = rif_reqID[5];
  assign io_refillInfo_6_valid  = rif_valid[6];  assign io_refillInfo_6_bits_set  = rif_set[6];  assign io_refillInfo_6_bits_tag  = rif_tag[6];  assign io_refillInfo_6_bits_reqID  = rif_reqID[6];
  assign io_refillInfo_7_valid  = rif_valid[7];  assign io_refillInfo_7_bits_set  = rif_set[7];  assign io_refillInfo_7_bits_tag  = rif_tag[7];  assign io_refillInfo_7_bits_reqID  = rif_reqID[7];
  assign io_refillInfo_8_valid  = rif_valid[8];  assign io_refillInfo_8_bits_set  = rif_set[8];  assign io_refillInfo_8_bits_tag  = rif_tag[8];  assign io_refillInfo_8_bits_reqID  = rif_reqID[8];
  assign io_refillInfo_9_valid  = rif_valid[9];  assign io_refillInfo_9_bits_set  = rif_set[9];  assign io_refillInfo_9_bits_tag  = rif_tag[9];  assign io_refillInfo_9_bits_reqID  = rif_reqID[9];
  assign io_refillInfo_10_valid = rif_valid[10]; assign io_refillInfo_10_bits_set = rif_set[10]; assign io_refillInfo_10_bits_tag = rif_tag[10]; assign io_refillInfo_10_bits_reqID = rif_reqID[10];
  assign io_refillInfo_11_valid = rif_valid[11]; assign io_refillInfo_11_bits_set = rif_set[11]; assign io_refillInfo_11_bits_tag = rif_tag[11]; assign io_refillInfo_11_bits_reqID = rif_reqID[11];
  assign io_refillInfo_12_valid = rif_valid[12]; assign io_refillInfo_12_bits_set = rif_set[12]; assign io_refillInfo_12_bits_tag = rif_tag[12]; assign io_refillInfo_12_bits_reqID = rif_reqID[12];
  assign io_refillInfo_13_valid = rif_valid[13]; assign io_refillInfo_13_bits_set = rif_set[13]; assign io_refillInfo_13_bits_tag = rif_tag[13]; assign io_refillInfo_13_bits_reqID = rif_reqID[13];
  assign io_refillInfo_14_valid = rif_valid[14]; assign io_refillInfo_14_bits_set = rif_set[14]; assign io_refillInfo_14_bits_tag = rif_tag[14]; assign io_refillInfo_14_bits_reqID = rif_reqID[14];
  assign io_refillInfo_15_valid = rif_valid[15]; assign io_refillInfo_15_bits_set = rif_set[15]; assign io_refillInfo_15_bits_tag = rif_tag[15]; assign io_refillInfo_15_bits_reqID = rif_reqID[15];

endmodule
