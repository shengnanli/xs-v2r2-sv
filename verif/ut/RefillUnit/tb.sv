// 自动生成: gen_tb.py —— 勿手改
`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 200000;
  int unsigned WARMUP  = 8;
  bit clk = 0, rst;
  int errors = 0, checks = 0, cyc = 0;
  always #5 clk = ~clk;

  logic io_alloc_valid;
  logic io_alloc_bits_state_w_snpRsp;
  logic [11:0] io_alloc_bits_task_set;
  logic [1:0] io_alloc_bits_task_bank;
  logic [27:0] io_alloc_bits_task_tag;
  logic [5:0] io_alloc_bits_task_off;
  logic [2:0] io_alloc_bits_task_size;
  logic [3:0] io_alloc_bits_task_bufID;
  logic [11:0] io_alloc_bits_task_reqID;
  logic io_alloc_bits_task_replSnp;
  logic io_alloc_bits_task_snpVec_0;
  logic [10:0] io_alloc_bits_task_tgtID;
  logic [10:0] io_alloc_bits_task_srcID;
  logic [11:0] io_alloc_bits_task_txnID;
  logic [11:0] io_alloc_bits_task_dbID;
  logic [10:0] io_alloc_bits_task_fwdNID;
  logic [11:0] io_alloc_bits_task_fwdTxnID;
  logic [6:0] io_alloc_bits_task_chiOpcode;
  logic [2:0] io_alloc_bits_task_resp;
  logic [2:0] io_alloc_bits_task_fwdState;
  logic [3:0] io_alloc_bits_task_pCrdType;
  logic io_alloc_bits_task_retToSrc;
  logic io_alloc_bits_task_doNotGoToSD;
  logic io_alloc_bits_task_expCompAck;
  logic io_alloc_bits_task_allowRetry;
  logic [1:0] io_alloc_bits_task_order;
  logic io_alloc_bits_task_memAttr_allocate;
  logic io_alloc_bits_task_memAttr_cacheable;
  logic io_alloc_bits_task_memAttr_device;
  logic io_alloc_bits_task_memAttr_ewa;
  logic io_alloc_bits_task_snpAttr;
  logic io_alloc_bits_dirResult_clients_hit;
  logic io_alloc_bits_dirResult_clients_meta_0_valid;
  logic io_alloc_bits_isWrite;
  logic io_task_ready;
  logic io_respData_valid;
  logic [11:0] io_respData_bits_txnID;
  logic [6:0] io_respData_bits_opcode;
  logic [2:0] io_respData_bits_resp;
  logic [10:0] io_respData_bits_srcID;
  logic [1:0] io_respData_bits_dataID;
  logic [255:0] io_respData_bits_data_data;
  logic io_resp_valid;
  logic [11:0] io_resp_bits_txnID;
  logic [6:0] io_resp_bits_opcode;
  logic [10:0] io_resp_bits_srcID;
  logic io_read_valid;
  logic [3:0] io_read_bits_id;
  wire g_io_task_valid;
  wire i_io_task_valid;
  wire [11:0] g_io_task_bits_set;
  wire [11:0] i_io_task_bits_set;
  wire [1:0] g_io_task_bits_bank;
  wire [1:0] i_io_task_bits_bank;
  wire [27:0] g_io_task_bits_tag;
  wire [27:0] i_io_task_bits_tag;
  wire [5:0] g_io_task_bits_off;
  wire [5:0] i_io_task_bits_off;
  wire [2:0] g_io_task_bits_size;
  wire [2:0] i_io_task_bits_size;
  wire g_io_task_bits_refillTask;
  wire i_io_task_bits_refillTask;
  wire [3:0] g_io_task_bits_bufID;
  wire [3:0] i_io_task_bits_bufID;
  wire [11:0] g_io_task_bits_reqID;
  wire [11:0] i_io_task_bits_reqID;
  wire g_io_task_bits_replSnp;
  wire i_io_task_bits_replSnp;
  wire g_io_task_bits_snpVec_0;
  wire i_io_task_bits_snpVec_0;
  wire [10:0] g_io_task_bits_tgtID;
  wire [10:0] i_io_task_bits_tgtID;
  wire [10:0] g_io_task_bits_srcID;
  wire [10:0] i_io_task_bits_srcID;
  wire [11:0] g_io_task_bits_txnID;
  wire [11:0] i_io_task_bits_txnID;
  wire [11:0] g_io_task_bits_dbID;
  wire [11:0] i_io_task_bits_dbID;
  wire [10:0] g_io_task_bits_fwdNID;
  wire [10:0] i_io_task_bits_fwdNID;
  wire [11:0] g_io_task_bits_fwdTxnID;
  wire [11:0] i_io_task_bits_fwdTxnID;
  wire [6:0] g_io_task_bits_chiOpcode;
  wire [6:0] i_io_task_bits_chiOpcode;
  wire [2:0] g_io_task_bits_resp;
  wire [2:0] i_io_task_bits_resp;
  wire [2:0] g_io_task_bits_fwdState;
  wire [2:0] i_io_task_bits_fwdState;
  wire [3:0] g_io_task_bits_pCrdType;
  wire [3:0] i_io_task_bits_pCrdType;
  wire g_io_task_bits_retToSrc;
  wire i_io_task_bits_retToSrc;
  wire g_io_task_bits_doNotGoToSD;
  wire i_io_task_bits_doNotGoToSD;
  wire g_io_task_bits_expCompAck;
  wire i_io_task_bits_expCompAck;
  wire g_io_task_bits_allowRetry;
  wire i_io_task_bits_allowRetry;
  wire [1:0] g_io_task_bits_order;
  wire [1:0] i_io_task_bits_order;
  wire g_io_task_bits_memAttr_allocate;
  wire i_io_task_bits_memAttr_allocate;
  wire g_io_task_bits_memAttr_cacheable;
  wire i_io_task_bits_memAttr_cacheable;
  wire g_io_task_bits_memAttr_device;
  wire i_io_task_bits_memAttr_device;
  wire g_io_task_bits_memAttr_ewa;
  wire i_io_task_bits_memAttr_ewa;
  wire g_io_task_bits_snpAttr;
  wire i_io_task_bits_snpAttr;
  wire [255:0] g_io_data_data_0_data;
  wire [255:0] i_io_data_data_0_data;
  wire [255:0] g_io_data_data_1_data;
  wire [255:0] i_io_data_data_1_data;
  wire g_io_refillInfo_0_valid;
  wire i_io_refillInfo_0_valid;
  wire [11:0] g_io_refillInfo_0_bits_set;
  wire [11:0] i_io_refillInfo_0_bits_set;
  wire [27:0] g_io_refillInfo_0_bits_tag;
  wire [27:0] i_io_refillInfo_0_bits_tag;
  wire [11:0] g_io_refillInfo_0_bits_reqID;
  wire [11:0] i_io_refillInfo_0_bits_reqID;
  wire g_io_refillInfo_1_valid;
  wire i_io_refillInfo_1_valid;
  wire [11:0] g_io_refillInfo_1_bits_set;
  wire [11:0] i_io_refillInfo_1_bits_set;
  wire [27:0] g_io_refillInfo_1_bits_tag;
  wire [27:0] i_io_refillInfo_1_bits_tag;
  wire [11:0] g_io_refillInfo_1_bits_reqID;
  wire [11:0] i_io_refillInfo_1_bits_reqID;
  wire g_io_refillInfo_2_valid;
  wire i_io_refillInfo_2_valid;
  wire [11:0] g_io_refillInfo_2_bits_set;
  wire [11:0] i_io_refillInfo_2_bits_set;
  wire [27:0] g_io_refillInfo_2_bits_tag;
  wire [27:0] i_io_refillInfo_2_bits_tag;
  wire [11:0] g_io_refillInfo_2_bits_reqID;
  wire [11:0] i_io_refillInfo_2_bits_reqID;
  wire g_io_refillInfo_3_valid;
  wire i_io_refillInfo_3_valid;
  wire [11:0] g_io_refillInfo_3_bits_set;
  wire [11:0] i_io_refillInfo_3_bits_set;
  wire [27:0] g_io_refillInfo_3_bits_tag;
  wire [27:0] i_io_refillInfo_3_bits_tag;
  wire [11:0] g_io_refillInfo_3_bits_reqID;
  wire [11:0] i_io_refillInfo_3_bits_reqID;
  wire g_io_refillInfo_4_valid;
  wire i_io_refillInfo_4_valid;
  wire [11:0] g_io_refillInfo_4_bits_set;
  wire [11:0] i_io_refillInfo_4_bits_set;
  wire [27:0] g_io_refillInfo_4_bits_tag;
  wire [27:0] i_io_refillInfo_4_bits_tag;
  wire [11:0] g_io_refillInfo_4_bits_reqID;
  wire [11:0] i_io_refillInfo_4_bits_reqID;
  wire g_io_refillInfo_5_valid;
  wire i_io_refillInfo_5_valid;
  wire [11:0] g_io_refillInfo_5_bits_set;
  wire [11:0] i_io_refillInfo_5_bits_set;
  wire [27:0] g_io_refillInfo_5_bits_tag;
  wire [27:0] i_io_refillInfo_5_bits_tag;
  wire [11:0] g_io_refillInfo_5_bits_reqID;
  wire [11:0] i_io_refillInfo_5_bits_reqID;
  wire g_io_refillInfo_6_valid;
  wire i_io_refillInfo_6_valid;
  wire [11:0] g_io_refillInfo_6_bits_set;
  wire [11:0] i_io_refillInfo_6_bits_set;
  wire [27:0] g_io_refillInfo_6_bits_tag;
  wire [27:0] i_io_refillInfo_6_bits_tag;
  wire [11:0] g_io_refillInfo_6_bits_reqID;
  wire [11:0] i_io_refillInfo_6_bits_reqID;
  wire g_io_refillInfo_7_valid;
  wire i_io_refillInfo_7_valid;
  wire [11:0] g_io_refillInfo_7_bits_set;
  wire [11:0] i_io_refillInfo_7_bits_set;
  wire [27:0] g_io_refillInfo_7_bits_tag;
  wire [27:0] i_io_refillInfo_7_bits_tag;
  wire [11:0] g_io_refillInfo_7_bits_reqID;
  wire [11:0] i_io_refillInfo_7_bits_reqID;
  wire g_io_refillInfo_8_valid;
  wire i_io_refillInfo_8_valid;
  wire [11:0] g_io_refillInfo_8_bits_set;
  wire [11:0] i_io_refillInfo_8_bits_set;
  wire [27:0] g_io_refillInfo_8_bits_tag;
  wire [27:0] i_io_refillInfo_8_bits_tag;
  wire [11:0] g_io_refillInfo_8_bits_reqID;
  wire [11:0] i_io_refillInfo_8_bits_reqID;
  wire g_io_refillInfo_9_valid;
  wire i_io_refillInfo_9_valid;
  wire [11:0] g_io_refillInfo_9_bits_set;
  wire [11:0] i_io_refillInfo_9_bits_set;
  wire [27:0] g_io_refillInfo_9_bits_tag;
  wire [27:0] i_io_refillInfo_9_bits_tag;
  wire [11:0] g_io_refillInfo_9_bits_reqID;
  wire [11:0] i_io_refillInfo_9_bits_reqID;
  wire g_io_refillInfo_10_valid;
  wire i_io_refillInfo_10_valid;
  wire [11:0] g_io_refillInfo_10_bits_set;
  wire [11:0] i_io_refillInfo_10_bits_set;
  wire [27:0] g_io_refillInfo_10_bits_tag;
  wire [27:0] i_io_refillInfo_10_bits_tag;
  wire [11:0] g_io_refillInfo_10_bits_reqID;
  wire [11:0] i_io_refillInfo_10_bits_reqID;
  wire g_io_refillInfo_11_valid;
  wire i_io_refillInfo_11_valid;
  wire [11:0] g_io_refillInfo_11_bits_set;
  wire [11:0] i_io_refillInfo_11_bits_set;
  wire [27:0] g_io_refillInfo_11_bits_tag;
  wire [27:0] i_io_refillInfo_11_bits_tag;
  wire [11:0] g_io_refillInfo_11_bits_reqID;
  wire [11:0] i_io_refillInfo_11_bits_reqID;
  wire g_io_refillInfo_12_valid;
  wire i_io_refillInfo_12_valid;
  wire [11:0] g_io_refillInfo_12_bits_set;
  wire [11:0] i_io_refillInfo_12_bits_set;
  wire [27:0] g_io_refillInfo_12_bits_tag;
  wire [27:0] i_io_refillInfo_12_bits_tag;
  wire [11:0] g_io_refillInfo_12_bits_reqID;
  wire [11:0] i_io_refillInfo_12_bits_reqID;
  wire g_io_refillInfo_13_valid;
  wire i_io_refillInfo_13_valid;
  wire [11:0] g_io_refillInfo_13_bits_set;
  wire [11:0] i_io_refillInfo_13_bits_set;
  wire [27:0] g_io_refillInfo_13_bits_tag;
  wire [27:0] i_io_refillInfo_13_bits_tag;
  wire [11:0] g_io_refillInfo_13_bits_reqID;
  wire [11:0] i_io_refillInfo_13_bits_reqID;
  wire g_io_refillInfo_14_valid;
  wire i_io_refillInfo_14_valid;
  wire [11:0] g_io_refillInfo_14_bits_set;
  wire [11:0] i_io_refillInfo_14_bits_set;
  wire [27:0] g_io_refillInfo_14_bits_tag;
  wire [27:0] i_io_refillInfo_14_bits_tag;
  wire [11:0] g_io_refillInfo_14_bits_reqID;
  wire [11:0] i_io_refillInfo_14_bits_reqID;
  wire g_io_refillInfo_15_valid;
  wire i_io_refillInfo_15_valid;
  wire [11:0] g_io_refillInfo_15_bits_set;
  wire [11:0] i_io_refillInfo_15_bits_set;
  wire [27:0] g_io_refillInfo_15_bits_tag;
  wire [27:0] i_io_refillInfo_15_bits_tag;
  wire [11:0] g_io_refillInfo_15_bits_reqID;
  wire [11:0] i_io_refillInfo_15_bits_reqID;

  RefillUnit dut_g (
    .clock(clk), .reset(rst),
    .io_alloc_valid(io_alloc_valid),
    .io_alloc_bits_state_w_snpRsp(io_alloc_bits_state_w_snpRsp),
    .io_alloc_bits_task_set(io_alloc_bits_task_set),
    .io_alloc_bits_task_bank(io_alloc_bits_task_bank),
    .io_alloc_bits_task_tag(io_alloc_bits_task_tag),
    .io_alloc_bits_task_off(io_alloc_bits_task_off),
    .io_alloc_bits_task_size(io_alloc_bits_task_size),
    .io_alloc_bits_task_bufID(io_alloc_bits_task_bufID),
    .io_alloc_bits_task_reqID(io_alloc_bits_task_reqID),
    .io_alloc_bits_task_replSnp(io_alloc_bits_task_replSnp),
    .io_alloc_bits_task_snpVec_0(io_alloc_bits_task_snpVec_0),
    .io_alloc_bits_task_tgtID(io_alloc_bits_task_tgtID),
    .io_alloc_bits_task_srcID(io_alloc_bits_task_srcID),
    .io_alloc_bits_task_txnID(io_alloc_bits_task_txnID),
    .io_alloc_bits_task_dbID(io_alloc_bits_task_dbID),
    .io_alloc_bits_task_fwdNID(io_alloc_bits_task_fwdNID),
    .io_alloc_bits_task_fwdTxnID(io_alloc_bits_task_fwdTxnID),
    .io_alloc_bits_task_chiOpcode(io_alloc_bits_task_chiOpcode),
    .io_alloc_bits_task_resp(io_alloc_bits_task_resp),
    .io_alloc_bits_task_fwdState(io_alloc_bits_task_fwdState),
    .io_alloc_bits_task_pCrdType(io_alloc_bits_task_pCrdType),
    .io_alloc_bits_task_retToSrc(io_alloc_bits_task_retToSrc),
    .io_alloc_bits_task_doNotGoToSD(io_alloc_bits_task_doNotGoToSD),
    .io_alloc_bits_task_expCompAck(io_alloc_bits_task_expCompAck),
    .io_alloc_bits_task_allowRetry(io_alloc_bits_task_allowRetry),
    .io_alloc_bits_task_order(io_alloc_bits_task_order),
    .io_alloc_bits_task_memAttr_allocate(io_alloc_bits_task_memAttr_allocate),
    .io_alloc_bits_task_memAttr_cacheable(io_alloc_bits_task_memAttr_cacheable),
    .io_alloc_bits_task_memAttr_device(io_alloc_bits_task_memAttr_device),
    .io_alloc_bits_task_memAttr_ewa(io_alloc_bits_task_memAttr_ewa),
    .io_alloc_bits_task_snpAttr(io_alloc_bits_task_snpAttr),
    .io_alloc_bits_dirResult_clients_hit(io_alloc_bits_dirResult_clients_hit),
    .io_alloc_bits_dirResult_clients_meta_0_valid(io_alloc_bits_dirResult_clients_meta_0_valid),
    .io_alloc_bits_isWrite(io_alloc_bits_isWrite),
    .io_task_ready(io_task_ready),
    .io_respData_valid(io_respData_valid),
    .io_respData_bits_txnID(io_respData_bits_txnID),
    .io_respData_bits_opcode(io_respData_bits_opcode),
    .io_respData_bits_resp(io_respData_bits_resp),
    .io_respData_bits_srcID(io_respData_bits_srcID),
    .io_respData_bits_dataID(io_respData_bits_dataID),
    .io_respData_bits_data_data(io_respData_bits_data_data),
    .io_resp_valid(io_resp_valid),
    .io_resp_bits_txnID(io_resp_bits_txnID),
    .io_resp_bits_opcode(io_resp_bits_opcode),
    .io_resp_bits_srcID(io_resp_bits_srcID),
    .io_read_valid(io_read_valid),
    .io_read_bits_id(io_read_bits_id),
    .io_task_valid(g_io_task_valid),
    .io_task_bits_set(g_io_task_bits_set),
    .io_task_bits_bank(g_io_task_bits_bank),
    .io_task_bits_tag(g_io_task_bits_tag),
    .io_task_bits_off(g_io_task_bits_off),
    .io_task_bits_size(g_io_task_bits_size),
    .io_task_bits_refillTask(g_io_task_bits_refillTask),
    .io_task_bits_bufID(g_io_task_bits_bufID),
    .io_task_bits_reqID(g_io_task_bits_reqID),
    .io_task_bits_replSnp(g_io_task_bits_replSnp),
    .io_task_bits_snpVec_0(g_io_task_bits_snpVec_0),
    .io_task_bits_tgtID(g_io_task_bits_tgtID),
    .io_task_bits_srcID(g_io_task_bits_srcID),
    .io_task_bits_txnID(g_io_task_bits_txnID),
    .io_task_bits_dbID(g_io_task_bits_dbID),
    .io_task_bits_fwdNID(g_io_task_bits_fwdNID),
    .io_task_bits_fwdTxnID(g_io_task_bits_fwdTxnID),
    .io_task_bits_chiOpcode(g_io_task_bits_chiOpcode),
    .io_task_bits_resp(g_io_task_bits_resp),
    .io_task_bits_fwdState(g_io_task_bits_fwdState),
    .io_task_bits_pCrdType(g_io_task_bits_pCrdType),
    .io_task_bits_retToSrc(g_io_task_bits_retToSrc),
    .io_task_bits_doNotGoToSD(g_io_task_bits_doNotGoToSD),
    .io_task_bits_expCompAck(g_io_task_bits_expCompAck),
    .io_task_bits_allowRetry(g_io_task_bits_allowRetry),
    .io_task_bits_order(g_io_task_bits_order),
    .io_task_bits_memAttr_allocate(g_io_task_bits_memAttr_allocate),
    .io_task_bits_memAttr_cacheable(g_io_task_bits_memAttr_cacheable),
    .io_task_bits_memAttr_device(g_io_task_bits_memAttr_device),
    .io_task_bits_memAttr_ewa(g_io_task_bits_memAttr_ewa),
    .io_task_bits_snpAttr(g_io_task_bits_snpAttr),
    .io_data_data_0_data(g_io_data_data_0_data),
    .io_data_data_1_data(g_io_data_data_1_data),
    .io_refillInfo_0_valid(g_io_refillInfo_0_valid),
    .io_refillInfo_0_bits_set(g_io_refillInfo_0_bits_set),
    .io_refillInfo_0_bits_tag(g_io_refillInfo_0_bits_tag),
    .io_refillInfo_0_bits_reqID(g_io_refillInfo_0_bits_reqID),
    .io_refillInfo_1_valid(g_io_refillInfo_1_valid),
    .io_refillInfo_1_bits_set(g_io_refillInfo_1_bits_set),
    .io_refillInfo_1_bits_tag(g_io_refillInfo_1_bits_tag),
    .io_refillInfo_1_bits_reqID(g_io_refillInfo_1_bits_reqID),
    .io_refillInfo_2_valid(g_io_refillInfo_2_valid),
    .io_refillInfo_2_bits_set(g_io_refillInfo_2_bits_set),
    .io_refillInfo_2_bits_tag(g_io_refillInfo_2_bits_tag),
    .io_refillInfo_2_bits_reqID(g_io_refillInfo_2_bits_reqID),
    .io_refillInfo_3_valid(g_io_refillInfo_3_valid),
    .io_refillInfo_3_bits_set(g_io_refillInfo_3_bits_set),
    .io_refillInfo_3_bits_tag(g_io_refillInfo_3_bits_tag),
    .io_refillInfo_3_bits_reqID(g_io_refillInfo_3_bits_reqID),
    .io_refillInfo_4_valid(g_io_refillInfo_4_valid),
    .io_refillInfo_4_bits_set(g_io_refillInfo_4_bits_set),
    .io_refillInfo_4_bits_tag(g_io_refillInfo_4_bits_tag),
    .io_refillInfo_4_bits_reqID(g_io_refillInfo_4_bits_reqID),
    .io_refillInfo_5_valid(g_io_refillInfo_5_valid),
    .io_refillInfo_5_bits_set(g_io_refillInfo_5_bits_set),
    .io_refillInfo_5_bits_tag(g_io_refillInfo_5_bits_tag),
    .io_refillInfo_5_bits_reqID(g_io_refillInfo_5_bits_reqID),
    .io_refillInfo_6_valid(g_io_refillInfo_6_valid),
    .io_refillInfo_6_bits_set(g_io_refillInfo_6_bits_set),
    .io_refillInfo_6_bits_tag(g_io_refillInfo_6_bits_tag),
    .io_refillInfo_6_bits_reqID(g_io_refillInfo_6_bits_reqID),
    .io_refillInfo_7_valid(g_io_refillInfo_7_valid),
    .io_refillInfo_7_bits_set(g_io_refillInfo_7_bits_set),
    .io_refillInfo_7_bits_tag(g_io_refillInfo_7_bits_tag),
    .io_refillInfo_7_bits_reqID(g_io_refillInfo_7_bits_reqID),
    .io_refillInfo_8_valid(g_io_refillInfo_8_valid),
    .io_refillInfo_8_bits_set(g_io_refillInfo_8_bits_set),
    .io_refillInfo_8_bits_tag(g_io_refillInfo_8_bits_tag),
    .io_refillInfo_8_bits_reqID(g_io_refillInfo_8_bits_reqID),
    .io_refillInfo_9_valid(g_io_refillInfo_9_valid),
    .io_refillInfo_9_bits_set(g_io_refillInfo_9_bits_set),
    .io_refillInfo_9_bits_tag(g_io_refillInfo_9_bits_tag),
    .io_refillInfo_9_bits_reqID(g_io_refillInfo_9_bits_reqID),
    .io_refillInfo_10_valid(g_io_refillInfo_10_valid),
    .io_refillInfo_10_bits_set(g_io_refillInfo_10_bits_set),
    .io_refillInfo_10_bits_tag(g_io_refillInfo_10_bits_tag),
    .io_refillInfo_10_bits_reqID(g_io_refillInfo_10_bits_reqID),
    .io_refillInfo_11_valid(g_io_refillInfo_11_valid),
    .io_refillInfo_11_bits_set(g_io_refillInfo_11_bits_set),
    .io_refillInfo_11_bits_tag(g_io_refillInfo_11_bits_tag),
    .io_refillInfo_11_bits_reqID(g_io_refillInfo_11_bits_reqID),
    .io_refillInfo_12_valid(g_io_refillInfo_12_valid),
    .io_refillInfo_12_bits_set(g_io_refillInfo_12_bits_set),
    .io_refillInfo_12_bits_tag(g_io_refillInfo_12_bits_tag),
    .io_refillInfo_12_bits_reqID(g_io_refillInfo_12_bits_reqID),
    .io_refillInfo_13_valid(g_io_refillInfo_13_valid),
    .io_refillInfo_13_bits_set(g_io_refillInfo_13_bits_set),
    .io_refillInfo_13_bits_tag(g_io_refillInfo_13_bits_tag),
    .io_refillInfo_13_bits_reqID(g_io_refillInfo_13_bits_reqID),
    .io_refillInfo_14_valid(g_io_refillInfo_14_valid),
    .io_refillInfo_14_bits_set(g_io_refillInfo_14_bits_set),
    .io_refillInfo_14_bits_tag(g_io_refillInfo_14_bits_tag),
    .io_refillInfo_14_bits_reqID(g_io_refillInfo_14_bits_reqID),
    .io_refillInfo_15_valid(g_io_refillInfo_15_valid),
    .io_refillInfo_15_bits_set(g_io_refillInfo_15_bits_set),
    .io_refillInfo_15_bits_tag(g_io_refillInfo_15_bits_tag),
    .io_refillInfo_15_bits_reqID(g_io_refillInfo_15_bits_reqID)
  );

  RefillUnit_xs dut_i (
    .clock(clk), .reset(rst),
    .io_alloc_valid(io_alloc_valid),
    .io_alloc_bits_state_w_snpRsp(io_alloc_bits_state_w_snpRsp),
    .io_alloc_bits_task_set(io_alloc_bits_task_set),
    .io_alloc_bits_task_bank(io_alloc_bits_task_bank),
    .io_alloc_bits_task_tag(io_alloc_bits_task_tag),
    .io_alloc_bits_task_off(io_alloc_bits_task_off),
    .io_alloc_bits_task_size(io_alloc_bits_task_size),
    .io_alloc_bits_task_bufID(io_alloc_bits_task_bufID),
    .io_alloc_bits_task_reqID(io_alloc_bits_task_reqID),
    .io_alloc_bits_task_replSnp(io_alloc_bits_task_replSnp),
    .io_alloc_bits_task_snpVec_0(io_alloc_bits_task_snpVec_0),
    .io_alloc_bits_task_tgtID(io_alloc_bits_task_tgtID),
    .io_alloc_bits_task_srcID(io_alloc_bits_task_srcID),
    .io_alloc_bits_task_txnID(io_alloc_bits_task_txnID),
    .io_alloc_bits_task_dbID(io_alloc_bits_task_dbID),
    .io_alloc_bits_task_fwdNID(io_alloc_bits_task_fwdNID),
    .io_alloc_bits_task_fwdTxnID(io_alloc_bits_task_fwdTxnID),
    .io_alloc_bits_task_chiOpcode(io_alloc_bits_task_chiOpcode),
    .io_alloc_bits_task_resp(io_alloc_bits_task_resp),
    .io_alloc_bits_task_fwdState(io_alloc_bits_task_fwdState),
    .io_alloc_bits_task_pCrdType(io_alloc_bits_task_pCrdType),
    .io_alloc_bits_task_retToSrc(io_alloc_bits_task_retToSrc),
    .io_alloc_bits_task_doNotGoToSD(io_alloc_bits_task_doNotGoToSD),
    .io_alloc_bits_task_expCompAck(io_alloc_bits_task_expCompAck),
    .io_alloc_bits_task_allowRetry(io_alloc_bits_task_allowRetry),
    .io_alloc_bits_task_order(io_alloc_bits_task_order),
    .io_alloc_bits_task_memAttr_allocate(io_alloc_bits_task_memAttr_allocate),
    .io_alloc_bits_task_memAttr_cacheable(io_alloc_bits_task_memAttr_cacheable),
    .io_alloc_bits_task_memAttr_device(io_alloc_bits_task_memAttr_device),
    .io_alloc_bits_task_memAttr_ewa(io_alloc_bits_task_memAttr_ewa),
    .io_alloc_bits_task_snpAttr(io_alloc_bits_task_snpAttr),
    .io_alloc_bits_dirResult_clients_hit(io_alloc_bits_dirResult_clients_hit),
    .io_alloc_bits_dirResult_clients_meta_0_valid(io_alloc_bits_dirResult_clients_meta_0_valid),
    .io_alloc_bits_isWrite(io_alloc_bits_isWrite),
    .io_task_ready(io_task_ready),
    .io_respData_valid(io_respData_valid),
    .io_respData_bits_txnID(io_respData_bits_txnID),
    .io_respData_bits_opcode(io_respData_bits_opcode),
    .io_respData_bits_resp(io_respData_bits_resp),
    .io_respData_bits_srcID(io_respData_bits_srcID),
    .io_respData_bits_dataID(io_respData_bits_dataID),
    .io_respData_bits_data_data(io_respData_bits_data_data),
    .io_resp_valid(io_resp_valid),
    .io_resp_bits_txnID(io_resp_bits_txnID),
    .io_resp_bits_opcode(io_resp_bits_opcode),
    .io_resp_bits_srcID(io_resp_bits_srcID),
    .io_read_valid(io_read_valid),
    .io_read_bits_id(io_read_bits_id),
    .io_task_valid(i_io_task_valid),
    .io_task_bits_set(i_io_task_bits_set),
    .io_task_bits_bank(i_io_task_bits_bank),
    .io_task_bits_tag(i_io_task_bits_tag),
    .io_task_bits_off(i_io_task_bits_off),
    .io_task_bits_size(i_io_task_bits_size),
    .io_task_bits_refillTask(i_io_task_bits_refillTask),
    .io_task_bits_bufID(i_io_task_bits_bufID),
    .io_task_bits_reqID(i_io_task_bits_reqID),
    .io_task_bits_replSnp(i_io_task_bits_replSnp),
    .io_task_bits_snpVec_0(i_io_task_bits_snpVec_0),
    .io_task_bits_tgtID(i_io_task_bits_tgtID),
    .io_task_bits_srcID(i_io_task_bits_srcID),
    .io_task_bits_txnID(i_io_task_bits_txnID),
    .io_task_bits_dbID(i_io_task_bits_dbID),
    .io_task_bits_fwdNID(i_io_task_bits_fwdNID),
    .io_task_bits_fwdTxnID(i_io_task_bits_fwdTxnID),
    .io_task_bits_chiOpcode(i_io_task_bits_chiOpcode),
    .io_task_bits_resp(i_io_task_bits_resp),
    .io_task_bits_fwdState(i_io_task_bits_fwdState),
    .io_task_bits_pCrdType(i_io_task_bits_pCrdType),
    .io_task_bits_retToSrc(i_io_task_bits_retToSrc),
    .io_task_bits_doNotGoToSD(i_io_task_bits_doNotGoToSD),
    .io_task_bits_expCompAck(i_io_task_bits_expCompAck),
    .io_task_bits_allowRetry(i_io_task_bits_allowRetry),
    .io_task_bits_order(i_io_task_bits_order),
    .io_task_bits_memAttr_allocate(i_io_task_bits_memAttr_allocate),
    .io_task_bits_memAttr_cacheable(i_io_task_bits_memAttr_cacheable),
    .io_task_bits_memAttr_device(i_io_task_bits_memAttr_device),
    .io_task_bits_memAttr_ewa(i_io_task_bits_memAttr_ewa),
    .io_task_bits_snpAttr(i_io_task_bits_snpAttr),
    .io_data_data_0_data(i_io_data_data_0_data),
    .io_data_data_1_data(i_io_data_data_1_data),
    .io_refillInfo_0_valid(i_io_refillInfo_0_valid),
    .io_refillInfo_0_bits_set(i_io_refillInfo_0_bits_set),
    .io_refillInfo_0_bits_tag(i_io_refillInfo_0_bits_tag),
    .io_refillInfo_0_bits_reqID(i_io_refillInfo_0_bits_reqID),
    .io_refillInfo_1_valid(i_io_refillInfo_1_valid),
    .io_refillInfo_1_bits_set(i_io_refillInfo_1_bits_set),
    .io_refillInfo_1_bits_tag(i_io_refillInfo_1_bits_tag),
    .io_refillInfo_1_bits_reqID(i_io_refillInfo_1_bits_reqID),
    .io_refillInfo_2_valid(i_io_refillInfo_2_valid),
    .io_refillInfo_2_bits_set(i_io_refillInfo_2_bits_set),
    .io_refillInfo_2_bits_tag(i_io_refillInfo_2_bits_tag),
    .io_refillInfo_2_bits_reqID(i_io_refillInfo_2_bits_reqID),
    .io_refillInfo_3_valid(i_io_refillInfo_3_valid),
    .io_refillInfo_3_bits_set(i_io_refillInfo_3_bits_set),
    .io_refillInfo_3_bits_tag(i_io_refillInfo_3_bits_tag),
    .io_refillInfo_3_bits_reqID(i_io_refillInfo_3_bits_reqID),
    .io_refillInfo_4_valid(i_io_refillInfo_4_valid),
    .io_refillInfo_4_bits_set(i_io_refillInfo_4_bits_set),
    .io_refillInfo_4_bits_tag(i_io_refillInfo_4_bits_tag),
    .io_refillInfo_4_bits_reqID(i_io_refillInfo_4_bits_reqID),
    .io_refillInfo_5_valid(i_io_refillInfo_5_valid),
    .io_refillInfo_5_bits_set(i_io_refillInfo_5_bits_set),
    .io_refillInfo_5_bits_tag(i_io_refillInfo_5_bits_tag),
    .io_refillInfo_5_bits_reqID(i_io_refillInfo_5_bits_reqID),
    .io_refillInfo_6_valid(i_io_refillInfo_6_valid),
    .io_refillInfo_6_bits_set(i_io_refillInfo_6_bits_set),
    .io_refillInfo_6_bits_tag(i_io_refillInfo_6_bits_tag),
    .io_refillInfo_6_bits_reqID(i_io_refillInfo_6_bits_reqID),
    .io_refillInfo_7_valid(i_io_refillInfo_7_valid),
    .io_refillInfo_7_bits_set(i_io_refillInfo_7_bits_set),
    .io_refillInfo_7_bits_tag(i_io_refillInfo_7_bits_tag),
    .io_refillInfo_7_bits_reqID(i_io_refillInfo_7_bits_reqID),
    .io_refillInfo_8_valid(i_io_refillInfo_8_valid),
    .io_refillInfo_8_bits_set(i_io_refillInfo_8_bits_set),
    .io_refillInfo_8_bits_tag(i_io_refillInfo_8_bits_tag),
    .io_refillInfo_8_bits_reqID(i_io_refillInfo_8_bits_reqID),
    .io_refillInfo_9_valid(i_io_refillInfo_9_valid),
    .io_refillInfo_9_bits_set(i_io_refillInfo_9_bits_set),
    .io_refillInfo_9_bits_tag(i_io_refillInfo_9_bits_tag),
    .io_refillInfo_9_bits_reqID(i_io_refillInfo_9_bits_reqID),
    .io_refillInfo_10_valid(i_io_refillInfo_10_valid),
    .io_refillInfo_10_bits_set(i_io_refillInfo_10_bits_set),
    .io_refillInfo_10_bits_tag(i_io_refillInfo_10_bits_tag),
    .io_refillInfo_10_bits_reqID(i_io_refillInfo_10_bits_reqID),
    .io_refillInfo_11_valid(i_io_refillInfo_11_valid),
    .io_refillInfo_11_bits_set(i_io_refillInfo_11_bits_set),
    .io_refillInfo_11_bits_tag(i_io_refillInfo_11_bits_tag),
    .io_refillInfo_11_bits_reqID(i_io_refillInfo_11_bits_reqID),
    .io_refillInfo_12_valid(i_io_refillInfo_12_valid),
    .io_refillInfo_12_bits_set(i_io_refillInfo_12_bits_set),
    .io_refillInfo_12_bits_tag(i_io_refillInfo_12_bits_tag),
    .io_refillInfo_12_bits_reqID(i_io_refillInfo_12_bits_reqID),
    .io_refillInfo_13_valid(i_io_refillInfo_13_valid),
    .io_refillInfo_13_bits_set(i_io_refillInfo_13_bits_set),
    .io_refillInfo_13_bits_tag(i_io_refillInfo_13_bits_tag),
    .io_refillInfo_13_bits_reqID(i_io_refillInfo_13_bits_reqID),
    .io_refillInfo_14_valid(i_io_refillInfo_14_valid),
    .io_refillInfo_14_bits_set(i_io_refillInfo_14_bits_set),
    .io_refillInfo_14_bits_tag(i_io_refillInfo_14_bits_tag),
    .io_refillInfo_14_bits_reqID(i_io_refillInfo_14_bits_reqID),
    .io_refillInfo_15_valid(i_io_refillInfo_15_valid),
    .io_refillInfo_15_bits_set(i_io_refillInfo_15_bits_set),
    .io_refillInfo_15_bits_tag(i_io_refillInfo_15_bits_tag),
    .io_refillInfo_15_bits_reqID(i_io_refillInfo_15_bits_reqID)
  );

  // 随机激励: 对每个输入独立取随机值; 部分字段偏置以覆盖控制路径
  task automatic drive_random();
    io_alloc_valid = $random;
    io_alloc_bits_state_w_snpRsp = $random;
    io_alloc_bits_task_set = $random;
    io_alloc_bits_task_bank = $random;
    io_alloc_bits_task_tag = $random;
    io_alloc_bits_task_off = $random;
    io_alloc_bits_task_size = $random;
    io_alloc_bits_task_bufID = $random;
    io_alloc_bits_task_reqID = $random;
    io_alloc_bits_task_replSnp = $random;
    io_alloc_bits_task_snpVec_0 = $random;
    io_alloc_bits_task_tgtID = $random;
    io_alloc_bits_task_srcID = $random;
    io_alloc_bits_task_txnID = $random;
    io_alloc_bits_task_dbID = $random;
    io_alloc_bits_task_fwdNID = $random;
    io_alloc_bits_task_fwdTxnID = $random;
    io_alloc_bits_task_chiOpcode = $random;
    io_alloc_bits_task_resp = $random;
    io_alloc_bits_task_fwdState = $random;
    io_alloc_bits_task_pCrdType = $random;
    io_alloc_bits_task_retToSrc = $random;
    io_alloc_bits_task_doNotGoToSD = $random;
    io_alloc_bits_task_expCompAck = $random;
    io_alloc_bits_task_allowRetry = $random;
    io_alloc_bits_task_order = $random;
    io_alloc_bits_task_memAttr_allocate = $random;
    io_alloc_bits_task_memAttr_cacheable = $random;
    io_alloc_bits_task_memAttr_device = $random;
    io_alloc_bits_task_memAttr_ewa = $random;
    io_alloc_bits_task_snpAttr = $random;
    io_alloc_bits_dirResult_clients_hit = $random;
    io_alloc_bits_dirResult_clients_meta_0_valid = $random;
    io_alloc_bits_isWrite = $random;
    io_task_ready = $random;
    io_respData_valid = $random;
    io_respData_bits_txnID = $random;
    io_respData_bits_opcode = $random;
    io_respData_bits_resp = $random;
    io_respData_bits_srcID = $random;
    io_respData_bits_dataID = $random;
    io_respData_bits_data_data = {$random,$random,$random,$random,$random,$random,$random,$random};
    io_resp_valid = $random;
    io_resp_bits_txnID = $random;
    io_resp_bits_opcode = $random;
    io_resp_bits_srcID = $random;
    io_read_valid = $random;
    io_read_bits_id = $random;
    // 偏置: 使控制路径更常被触发
    if (($random & 1) == 0) io_alloc_valid = 1'b1;
    io_alloc_bits_task_reqID = {8'h0, $random} & 12'hF;  // 收窄 reqID 到 0..15
    io_respData_bits_txnID   = {8'h0, $random} & 12'hF;  // 命中 buffer reqID
    io_resp_bits_txnID       = {8'h0, $random} & 12'hF;
    // opcode 偏置到 SnpRespData/SnpResp(=0x1)
    if (($random & 1) == 0) io_respData_bits_opcode = 7'h1;
    if (($random & 1) == 0) io_resp_bits_opcode = 7'h1;
    // resp 偏置到 I(=0)以触发 cancel; srcID 偏置到 0 以触发 snpVec 清位
    if (($random & 3) == 0) io_respData_bits_resp = 3'h0;
    if (($random & 1) == 0) io_respData_bits_srcID = 11'h0;
    if (($random & 1) == 0) io_resp_bits_srcID = 11'h0;
    // task_ready 多数为高以触发 issue fire; read 偶发触发 dealloc
    if (($random & 3) != 0) io_task_ready = 1'b1;
    if (($random & 7) != 0) io_read_valid = 1'b0;
  endtask

  task automatic check_outputs();
    checks++;
    if (g_io_task_valid !== i_io_task_valid) begin errors++; if (errors<=20) $display("[%0d] MISMATCH io_task_valid: g=%h i=%h", cyc, g_io_task_valid, i_io_task_valid); end
    if (g_io_task_bits_set !== i_io_task_bits_set) begin errors++; if (errors<=20) $display("[%0d] MISMATCH io_task_bits_set: g=%h i=%h", cyc, g_io_task_bits_set, i_io_task_bits_set); end
    if (g_io_task_bits_bank !== i_io_task_bits_bank) begin errors++; if (errors<=20) $display("[%0d] MISMATCH io_task_bits_bank: g=%h i=%h", cyc, g_io_task_bits_bank, i_io_task_bits_bank); end
    if (g_io_task_bits_tag !== i_io_task_bits_tag) begin errors++; if (errors<=20) $display("[%0d] MISMATCH io_task_bits_tag: g=%h i=%h", cyc, g_io_task_bits_tag, i_io_task_bits_tag); end
    if (g_io_task_bits_off !== i_io_task_bits_off) begin errors++; if (errors<=20) $display("[%0d] MISMATCH io_task_bits_off: g=%h i=%h", cyc, g_io_task_bits_off, i_io_task_bits_off); end
    if (g_io_task_bits_size !== i_io_task_bits_size) begin errors++; if (errors<=20) $display("[%0d] MISMATCH io_task_bits_size: g=%h i=%h", cyc, g_io_task_bits_size, i_io_task_bits_size); end
    if (g_io_task_bits_refillTask !== i_io_task_bits_refillTask) begin errors++; if (errors<=20) $display("[%0d] MISMATCH io_task_bits_refillTask: g=%h i=%h", cyc, g_io_task_bits_refillTask, i_io_task_bits_refillTask); end
    if (g_io_task_bits_bufID !== i_io_task_bits_bufID) begin errors++; if (errors<=20) $display("[%0d] MISMATCH io_task_bits_bufID: g=%h i=%h", cyc, g_io_task_bits_bufID, i_io_task_bits_bufID); end
    if (g_io_task_bits_reqID !== i_io_task_bits_reqID) begin errors++; if (errors<=20) $display("[%0d] MISMATCH io_task_bits_reqID: g=%h i=%h", cyc, g_io_task_bits_reqID, i_io_task_bits_reqID); end
    if (g_io_task_bits_replSnp !== i_io_task_bits_replSnp) begin errors++; if (errors<=20) $display("[%0d] MISMATCH io_task_bits_replSnp: g=%h i=%h", cyc, g_io_task_bits_replSnp, i_io_task_bits_replSnp); end
    if (g_io_task_bits_snpVec_0 !== i_io_task_bits_snpVec_0) begin errors++; if (errors<=20) $display("[%0d] MISMATCH io_task_bits_snpVec_0: g=%h i=%h", cyc, g_io_task_bits_snpVec_0, i_io_task_bits_snpVec_0); end
    if (g_io_task_bits_tgtID !== i_io_task_bits_tgtID) begin errors++; if (errors<=20) $display("[%0d] MISMATCH io_task_bits_tgtID: g=%h i=%h", cyc, g_io_task_bits_tgtID, i_io_task_bits_tgtID); end
    if (g_io_task_bits_srcID !== i_io_task_bits_srcID) begin errors++; if (errors<=20) $display("[%0d] MISMATCH io_task_bits_srcID: g=%h i=%h", cyc, g_io_task_bits_srcID, i_io_task_bits_srcID); end
    if (g_io_task_bits_txnID !== i_io_task_bits_txnID) begin errors++; if (errors<=20) $display("[%0d] MISMATCH io_task_bits_txnID: g=%h i=%h", cyc, g_io_task_bits_txnID, i_io_task_bits_txnID); end
    if (g_io_task_bits_dbID !== i_io_task_bits_dbID) begin errors++; if (errors<=20) $display("[%0d] MISMATCH io_task_bits_dbID: g=%h i=%h", cyc, g_io_task_bits_dbID, i_io_task_bits_dbID); end
    if (g_io_task_bits_fwdNID !== i_io_task_bits_fwdNID) begin errors++; if (errors<=20) $display("[%0d] MISMATCH io_task_bits_fwdNID: g=%h i=%h", cyc, g_io_task_bits_fwdNID, i_io_task_bits_fwdNID); end
    if (g_io_task_bits_fwdTxnID !== i_io_task_bits_fwdTxnID) begin errors++; if (errors<=20) $display("[%0d] MISMATCH io_task_bits_fwdTxnID: g=%h i=%h", cyc, g_io_task_bits_fwdTxnID, i_io_task_bits_fwdTxnID); end
    if (g_io_task_bits_chiOpcode !== i_io_task_bits_chiOpcode) begin errors++; if (errors<=20) $display("[%0d] MISMATCH io_task_bits_chiOpcode: g=%h i=%h", cyc, g_io_task_bits_chiOpcode, i_io_task_bits_chiOpcode); end
    if (g_io_task_bits_resp !== i_io_task_bits_resp) begin errors++; if (errors<=20) $display("[%0d] MISMATCH io_task_bits_resp: g=%h i=%h", cyc, g_io_task_bits_resp, i_io_task_bits_resp); end
    if (g_io_task_bits_fwdState !== i_io_task_bits_fwdState) begin errors++; if (errors<=20) $display("[%0d] MISMATCH io_task_bits_fwdState: g=%h i=%h", cyc, g_io_task_bits_fwdState, i_io_task_bits_fwdState); end
    if (g_io_task_bits_pCrdType !== i_io_task_bits_pCrdType) begin errors++; if (errors<=20) $display("[%0d] MISMATCH io_task_bits_pCrdType: g=%h i=%h", cyc, g_io_task_bits_pCrdType, i_io_task_bits_pCrdType); end
    if (g_io_task_bits_retToSrc !== i_io_task_bits_retToSrc) begin errors++; if (errors<=20) $display("[%0d] MISMATCH io_task_bits_retToSrc: g=%h i=%h", cyc, g_io_task_bits_retToSrc, i_io_task_bits_retToSrc); end
    if (g_io_task_bits_doNotGoToSD !== i_io_task_bits_doNotGoToSD) begin errors++; if (errors<=20) $display("[%0d] MISMATCH io_task_bits_doNotGoToSD: g=%h i=%h", cyc, g_io_task_bits_doNotGoToSD, i_io_task_bits_doNotGoToSD); end
    if (g_io_task_bits_expCompAck !== i_io_task_bits_expCompAck) begin errors++; if (errors<=20) $display("[%0d] MISMATCH io_task_bits_expCompAck: g=%h i=%h", cyc, g_io_task_bits_expCompAck, i_io_task_bits_expCompAck); end
    if (g_io_task_bits_allowRetry !== i_io_task_bits_allowRetry) begin errors++; if (errors<=20) $display("[%0d] MISMATCH io_task_bits_allowRetry: g=%h i=%h", cyc, g_io_task_bits_allowRetry, i_io_task_bits_allowRetry); end
    if (g_io_task_bits_order !== i_io_task_bits_order) begin errors++; if (errors<=20) $display("[%0d] MISMATCH io_task_bits_order: g=%h i=%h", cyc, g_io_task_bits_order, i_io_task_bits_order); end
    if (g_io_task_bits_memAttr_allocate !== i_io_task_bits_memAttr_allocate) begin errors++; if (errors<=20) $display("[%0d] MISMATCH io_task_bits_memAttr_allocate: g=%h i=%h", cyc, g_io_task_bits_memAttr_allocate, i_io_task_bits_memAttr_allocate); end
    if (g_io_task_bits_memAttr_cacheable !== i_io_task_bits_memAttr_cacheable) begin errors++; if (errors<=20) $display("[%0d] MISMATCH io_task_bits_memAttr_cacheable: g=%h i=%h", cyc, g_io_task_bits_memAttr_cacheable, i_io_task_bits_memAttr_cacheable); end
    if (g_io_task_bits_memAttr_device !== i_io_task_bits_memAttr_device) begin errors++; if (errors<=20) $display("[%0d] MISMATCH io_task_bits_memAttr_device: g=%h i=%h", cyc, g_io_task_bits_memAttr_device, i_io_task_bits_memAttr_device); end
    if (g_io_task_bits_memAttr_ewa !== i_io_task_bits_memAttr_ewa) begin errors++; if (errors<=20) $display("[%0d] MISMATCH io_task_bits_memAttr_ewa: g=%h i=%h", cyc, g_io_task_bits_memAttr_ewa, i_io_task_bits_memAttr_ewa); end
    if (g_io_task_bits_snpAttr !== i_io_task_bits_snpAttr) begin errors++; if (errors<=20) $display("[%0d] MISMATCH io_task_bits_snpAttr: g=%h i=%h", cyc, g_io_task_bits_snpAttr, i_io_task_bits_snpAttr); end
    if (g_io_data_data_0_data !== i_io_data_data_0_data) begin errors++; if (errors<=20) $display("[%0d] MISMATCH io_data_data_0_data: g=%h i=%h", cyc, g_io_data_data_0_data, i_io_data_data_0_data); end
    if (g_io_data_data_1_data !== i_io_data_data_1_data) begin errors++; if (errors<=20) $display("[%0d] MISMATCH io_data_data_1_data: g=%h i=%h", cyc, g_io_data_data_1_data, i_io_data_data_1_data); end
    if (g_io_refillInfo_0_valid !== i_io_refillInfo_0_valid) begin errors++; if (errors<=20) $display("[%0d] MISMATCH io_refillInfo_0_valid: g=%h i=%h", cyc, g_io_refillInfo_0_valid, i_io_refillInfo_0_valid); end
    if (g_io_refillInfo_0_bits_set !== i_io_refillInfo_0_bits_set) begin errors++; if (errors<=20) $display("[%0d] MISMATCH io_refillInfo_0_bits_set: g=%h i=%h", cyc, g_io_refillInfo_0_bits_set, i_io_refillInfo_0_bits_set); end
    if (g_io_refillInfo_0_bits_tag !== i_io_refillInfo_0_bits_tag) begin errors++; if (errors<=20) $display("[%0d] MISMATCH io_refillInfo_0_bits_tag: g=%h i=%h", cyc, g_io_refillInfo_0_bits_tag, i_io_refillInfo_0_bits_tag); end
    if (g_io_refillInfo_0_bits_reqID !== i_io_refillInfo_0_bits_reqID) begin errors++; if (errors<=20) $display("[%0d] MISMATCH io_refillInfo_0_bits_reqID: g=%h i=%h", cyc, g_io_refillInfo_0_bits_reqID, i_io_refillInfo_0_bits_reqID); end
    if (g_io_refillInfo_1_valid !== i_io_refillInfo_1_valid) begin errors++; if (errors<=20) $display("[%0d] MISMATCH io_refillInfo_1_valid: g=%h i=%h", cyc, g_io_refillInfo_1_valid, i_io_refillInfo_1_valid); end
    if (g_io_refillInfo_1_bits_set !== i_io_refillInfo_1_bits_set) begin errors++; if (errors<=20) $display("[%0d] MISMATCH io_refillInfo_1_bits_set: g=%h i=%h", cyc, g_io_refillInfo_1_bits_set, i_io_refillInfo_1_bits_set); end
    if (g_io_refillInfo_1_bits_tag !== i_io_refillInfo_1_bits_tag) begin errors++; if (errors<=20) $display("[%0d] MISMATCH io_refillInfo_1_bits_tag: g=%h i=%h", cyc, g_io_refillInfo_1_bits_tag, i_io_refillInfo_1_bits_tag); end
    if (g_io_refillInfo_1_bits_reqID !== i_io_refillInfo_1_bits_reqID) begin errors++; if (errors<=20) $display("[%0d] MISMATCH io_refillInfo_1_bits_reqID: g=%h i=%h", cyc, g_io_refillInfo_1_bits_reqID, i_io_refillInfo_1_bits_reqID); end
    if (g_io_refillInfo_2_valid !== i_io_refillInfo_2_valid) begin errors++; if (errors<=20) $display("[%0d] MISMATCH io_refillInfo_2_valid: g=%h i=%h", cyc, g_io_refillInfo_2_valid, i_io_refillInfo_2_valid); end
    if (g_io_refillInfo_2_bits_set !== i_io_refillInfo_2_bits_set) begin errors++; if (errors<=20) $display("[%0d] MISMATCH io_refillInfo_2_bits_set: g=%h i=%h", cyc, g_io_refillInfo_2_bits_set, i_io_refillInfo_2_bits_set); end
    if (g_io_refillInfo_2_bits_tag !== i_io_refillInfo_2_bits_tag) begin errors++; if (errors<=20) $display("[%0d] MISMATCH io_refillInfo_2_bits_tag: g=%h i=%h", cyc, g_io_refillInfo_2_bits_tag, i_io_refillInfo_2_bits_tag); end
    if (g_io_refillInfo_2_bits_reqID !== i_io_refillInfo_2_bits_reqID) begin errors++; if (errors<=20) $display("[%0d] MISMATCH io_refillInfo_2_bits_reqID: g=%h i=%h", cyc, g_io_refillInfo_2_bits_reqID, i_io_refillInfo_2_bits_reqID); end
    if (g_io_refillInfo_3_valid !== i_io_refillInfo_3_valid) begin errors++; if (errors<=20) $display("[%0d] MISMATCH io_refillInfo_3_valid: g=%h i=%h", cyc, g_io_refillInfo_3_valid, i_io_refillInfo_3_valid); end
    if (g_io_refillInfo_3_bits_set !== i_io_refillInfo_3_bits_set) begin errors++; if (errors<=20) $display("[%0d] MISMATCH io_refillInfo_3_bits_set: g=%h i=%h", cyc, g_io_refillInfo_3_bits_set, i_io_refillInfo_3_bits_set); end
    if (g_io_refillInfo_3_bits_tag !== i_io_refillInfo_3_bits_tag) begin errors++; if (errors<=20) $display("[%0d] MISMATCH io_refillInfo_3_bits_tag: g=%h i=%h", cyc, g_io_refillInfo_3_bits_tag, i_io_refillInfo_3_bits_tag); end
    if (g_io_refillInfo_3_bits_reqID !== i_io_refillInfo_3_bits_reqID) begin errors++; if (errors<=20) $display("[%0d] MISMATCH io_refillInfo_3_bits_reqID: g=%h i=%h", cyc, g_io_refillInfo_3_bits_reqID, i_io_refillInfo_3_bits_reqID); end
    if (g_io_refillInfo_4_valid !== i_io_refillInfo_4_valid) begin errors++; if (errors<=20) $display("[%0d] MISMATCH io_refillInfo_4_valid: g=%h i=%h", cyc, g_io_refillInfo_4_valid, i_io_refillInfo_4_valid); end
    if (g_io_refillInfo_4_bits_set !== i_io_refillInfo_4_bits_set) begin errors++; if (errors<=20) $display("[%0d] MISMATCH io_refillInfo_4_bits_set: g=%h i=%h", cyc, g_io_refillInfo_4_bits_set, i_io_refillInfo_4_bits_set); end
    if (g_io_refillInfo_4_bits_tag !== i_io_refillInfo_4_bits_tag) begin errors++; if (errors<=20) $display("[%0d] MISMATCH io_refillInfo_4_bits_tag: g=%h i=%h", cyc, g_io_refillInfo_4_bits_tag, i_io_refillInfo_4_bits_tag); end
    if (g_io_refillInfo_4_bits_reqID !== i_io_refillInfo_4_bits_reqID) begin errors++; if (errors<=20) $display("[%0d] MISMATCH io_refillInfo_4_bits_reqID: g=%h i=%h", cyc, g_io_refillInfo_4_bits_reqID, i_io_refillInfo_4_bits_reqID); end
    if (g_io_refillInfo_5_valid !== i_io_refillInfo_5_valid) begin errors++; if (errors<=20) $display("[%0d] MISMATCH io_refillInfo_5_valid: g=%h i=%h", cyc, g_io_refillInfo_5_valid, i_io_refillInfo_5_valid); end
    if (g_io_refillInfo_5_bits_set !== i_io_refillInfo_5_bits_set) begin errors++; if (errors<=20) $display("[%0d] MISMATCH io_refillInfo_5_bits_set: g=%h i=%h", cyc, g_io_refillInfo_5_bits_set, i_io_refillInfo_5_bits_set); end
    if (g_io_refillInfo_5_bits_tag !== i_io_refillInfo_5_bits_tag) begin errors++; if (errors<=20) $display("[%0d] MISMATCH io_refillInfo_5_bits_tag: g=%h i=%h", cyc, g_io_refillInfo_5_bits_tag, i_io_refillInfo_5_bits_tag); end
    if (g_io_refillInfo_5_bits_reqID !== i_io_refillInfo_5_bits_reqID) begin errors++; if (errors<=20) $display("[%0d] MISMATCH io_refillInfo_5_bits_reqID: g=%h i=%h", cyc, g_io_refillInfo_5_bits_reqID, i_io_refillInfo_5_bits_reqID); end
    if (g_io_refillInfo_6_valid !== i_io_refillInfo_6_valid) begin errors++; if (errors<=20) $display("[%0d] MISMATCH io_refillInfo_6_valid: g=%h i=%h", cyc, g_io_refillInfo_6_valid, i_io_refillInfo_6_valid); end
    if (g_io_refillInfo_6_bits_set !== i_io_refillInfo_6_bits_set) begin errors++; if (errors<=20) $display("[%0d] MISMATCH io_refillInfo_6_bits_set: g=%h i=%h", cyc, g_io_refillInfo_6_bits_set, i_io_refillInfo_6_bits_set); end
    if (g_io_refillInfo_6_bits_tag !== i_io_refillInfo_6_bits_tag) begin errors++; if (errors<=20) $display("[%0d] MISMATCH io_refillInfo_6_bits_tag: g=%h i=%h", cyc, g_io_refillInfo_6_bits_tag, i_io_refillInfo_6_bits_tag); end
    if (g_io_refillInfo_6_bits_reqID !== i_io_refillInfo_6_bits_reqID) begin errors++; if (errors<=20) $display("[%0d] MISMATCH io_refillInfo_6_bits_reqID: g=%h i=%h", cyc, g_io_refillInfo_6_bits_reqID, i_io_refillInfo_6_bits_reqID); end
    if (g_io_refillInfo_7_valid !== i_io_refillInfo_7_valid) begin errors++; if (errors<=20) $display("[%0d] MISMATCH io_refillInfo_7_valid: g=%h i=%h", cyc, g_io_refillInfo_7_valid, i_io_refillInfo_7_valid); end
    if (g_io_refillInfo_7_bits_set !== i_io_refillInfo_7_bits_set) begin errors++; if (errors<=20) $display("[%0d] MISMATCH io_refillInfo_7_bits_set: g=%h i=%h", cyc, g_io_refillInfo_7_bits_set, i_io_refillInfo_7_bits_set); end
    if (g_io_refillInfo_7_bits_tag !== i_io_refillInfo_7_bits_tag) begin errors++; if (errors<=20) $display("[%0d] MISMATCH io_refillInfo_7_bits_tag: g=%h i=%h", cyc, g_io_refillInfo_7_bits_tag, i_io_refillInfo_7_bits_tag); end
    if (g_io_refillInfo_7_bits_reqID !== i_io_refillInfo_7_bits_reqID) begin errors++; if (errors<=20) $display("[%0d] MISMATCH io_refillInfo_7_bits_reqID: g=%h i=%h", cyc, g_io_refillInfo_7_bits_reqID, i_io_refillInfo_7_bits_reqID); end
    if (g_io_refillInfo_8_valid !== i_io_refillInfo_8_valid) begin errors++; if (errors<=20) $display("[%0d] MISMATCH io_refillInfo_8_valid: g=%h i=%h", cyc, g_io_refillInfo_8_valid, i_io_refillInfo_8_valid); end
    if (g_io_refillInfo_8_bits_set !== i_io_refillInfo_8_bits_set) begin errors++; if (errors<=20) $display("[%0d] MISMATCH io_refillInfo_8_bits_set: g=%h i=%h", cyc, g_io_refillInfo_8_bits_set, i_io_refillInfo_8_bits_set); end
    if (g_io_refillInfo_8_bits_tag !== i_io_refillInfo_8_bits_tag) begin errors++; if (errors<=20) $display("[%0d] MISMATCH io_refillInfo_8_bits_tag: g=%h i=%h", cyc, g_io_refillInfo_8_bits_tag, i_io_refillInfo_8_bits_tag); end
    if (g_io_refillInfo_8_bits_reqID !== i_io_refillInfo_8_bits_reqID) begin errors++; if (errors<=20) $display("[%0d] MISMATCH io_refillInfo_8_bits_reqID: g=%h i=%h", cyc, g_io_refillInfo_8_bits_reqID, i_io_refillInfo_8_bits_reqID); end
    if (g_io_refillInfo_9_valid !== i_io_refillInfo_9_valid) begin errors++; if (errors<=20) $display("[%0d] MISMATCH io_refillInfo_9_valid: g=%h i=%h", cyc, g_io_refillInfo_9_valid, i_io_refillInfo_9_valid); end
    if (g_io_refillInfo_9_bits_set !== i_io_refillInfo_9_bits_set) begin errors++; if (errors<=20) $display("[%0d] MISMATCH io_refillInfo_9_bits_set: g=%h i=%h", cyc, g_io_refillInfo_9_bits_set, i_io_refillInfo_9_bits_set); end
    if (g_io_refillInfo_9_bits_tag !== i_io_refillInfo_9_bits_tag) begin errors++; if (errors<=20) $display("[%0d] MISMATCH io_refillInfo_9_bits_tag: g=%h i=%h", cyc, g_io_refillInfo_9_bits_tag, i_io_refillInfo_9_bits_tag); end
    if (g_io_refillInfo_9_bits_reqID !== i_io_refillInfo_9_bits_reqID) begin errors++; if (errors<=20) $display("[%0d] MISMATCH io_refillInfo_9_bits_reqID: g=%h i=%h", cyc, g_io_refillInfo_9_bits_reqID, i_io_refillInfo_9_bits_reqID); end
    if (g_io_refillInfo_10_valid !== i_io_refillInfo_10_valid) begin errors++; if (errors<=20) $display("[%0d] MISMATCH io_refillInfo_10_valid: g=%h i=%h", cyc, g_io_refillInfo_10_valid, i_io_refillInfo_10_valid); end
    if (g_io_refillInfo_10_bits_set !== i_io_refillInfo_10_bits_set) begin errors++; if (errors<=20) $display("[%0d] MISMATCH io_refillInfo_10_bits_set: g=%h i=%h", cyc, g_io_refillInfo_10_bits_set, i_io_refillInfo_10_bits_set); end
    if (g_io_refillInfo_10_bits_tag !== i_io_refillInfo_10_bits_tag) begin errors++; if (errors<=20) $display("[%0d] MISMATCH io_refillInfo_10_bits_tag: g=%h i=%h", cyc, g_io_refillInfo_10_bits_tag, i_io_refillInfo_10_bits_tag); end
    if (g_io_refillInfo_10_bits_reqID !== i_io_refillInfo_10_bits_reqID) begin errors++; if (errors<=20) $display("[%0d] MISMATCH io_refillInfo_10_bits_reqID: g=%h i=%h", cyc, g_io_refillInfo_10_bits_reqID, i_io_refillInfo_10_bits_reqID); end
    if (g_io_refillInfo_11_valid !== i_io_refillInfo_11_valid) begin errors++; if (errors<=20) $display("[%0d] MISMATCH io_refillInfo_11_valid: g=%h i=%h", cyc, g_io_refillInfo_11_valid, i_io_refillInfo_11_valid); end
    if (g_io_refillInfo_11_bits_set !== i_io_refillInfo_11_bits_set) begin errors++; if (errors<=20) $display("[%0d] MISMATCH io_refillInfo_11_bits_set: g=%h i=%h", cyc, g_io_refillInfo_11_bits_set, i_io_refillInfo_11_bits_set); end
    if (g_io_refillInfo_11_bits_tag !== i_io_refillInfo_11_bits_tag) begin errors++; if (errors<=20) $display("[%0d] MISMATCH io_refillInfo_11_bits_tag: g=%h i=%h", cyc, g_io_refillInfo_11_bits_tag, i_io_refillInfo_11_bits_tag); end
    if (g_io_refillInfo_11_bits_reqID !== i_io_refillInfo_11_bits_reqID) begin errors++; if (errors<=20) $display("[%0d] MISMATCH io_refillInfo_11_bits_reqID: g=%h i=%h", cyc, g_io_refillInfo_11_bits_reqID, i_io_refillInfo_11_bits_reqID); end
    if (g_io_refillInfo_12_valid !== i_io_refillInfo_12_valid) begin errors++; if (errors<=20) $display("[%0d] MISMATCH io_refillInfo_12_valid: g=%h i=%h", cyc, g_io_refillInfo_12_valid, i_io_refillInfo_12_valid); end
    if (g_io_refillInfo_12_bits_set !== i_io_refillInfo_12_bits_set) begin errors++; if (errors<=20) $display("[%0d] MISMATCH io_refillInfo_12_bits_set: g=%h i=%h", cyc, g_io_refillInfo_12_bits_set, i_io_refillInfo_12_bits_set); end
    if (g_io_refillInfo_12_bits_tag !== i_io_refillInfo_12_bits_tag) begin errors++; if (errors<=20) $display("[%0d] MISMATCH io_refillInfo_12_bits_tag: g=%h i=%h", cyc, g_io_refillInfo_12_bits_tag, i_io_refillInfo_12_bits_tag); end
    if (g_io_refillInfo_12_bits_reqID !== i_io_refillInfo_12_bits_reqID) begin errors++; if (errors<=20) $display("[%0d] MISMATCH io_refillInfo_12_bits_reqID: g=%h i=%h", cyc, g_io_refillInfo_12_bits_reqID, i_io_refillInfo_12_bits_reqID); end
    if (g_io_refillInfo_13_valid !== i_io_refillInfo_13_valid) begin errors++; if (errors<=20) $display("[%0d] MISMATCH io_refillInfo_13_valid: g=%h i=%h", cyc, g_io_refillInfo_13_valid, i_io_refillInfo_13_valid); end
    if (g_io_refillInfo_13_bits_set !== i_io_refillInfo_13_bits_set) begin errors++; if (errors<=20) $display("[%0d] MISMATCH io_refillInfo_13_bits_set: g=%h i=%h", cyc, g_io_refillInfo_13_bits_set, i_io_refillInfo_13_bits_set); end
    if (g_io_refillInfo_13_bits_tag !== i_io_refillInfo_13_bits_tag) begin errors++; if (errors<=20) $display("[%0d] MISMATCH io_refillInfo_13_bits_tag: g=%h i=%h", cyc, g_io_refillInfo_13_bits_tag, i_io_refillInfo_13_bits_tag); end
    if (g_io_refillInfo_13_bits_reqID !== i_io_refillInfo_13_bits_reqID) begin errors++; if (errors<=20) $display("[%0d] MISMATCH io_refillInfo_13_bits_reqID: g=%h i=%h", cyc, g_io_refillInfo_13_bits_reqID, i_io_refillInfo_13_bits_reqID); end
    if (g_io_refillInfo_14_valid !== i_io_refillInfo_14_valid) begin errors++; if (errors<=20) $display("[%0d] MISMATCH io_refillInfo_14_valid: g=%h i=%h", cyc, g_io_refillInfo_14_valid, i_io_refillInfo_14_valid); end
    if (g_io_refillInfo_14_bits_set !== i_io_refillInfo_14_bits_set) begin errors++; if (errors<=20) $display("[%0d] MISMATCH io_refillInfo_14_bits_set: g=%h i=%h", cyc, g_io_refillInfo_14_bits_set, i_io_refillInfo_14_bits_set); end
    if (g_io_refillInfo_14_bits_tag !== i_io_refillInfo_14_bits_tag) begin errors++; if (errors<=20) $display("[%0d] MISMATCH io_refillInfo_14_bits_tag: g=%h i=%h", cyc, g_io_refillInfo_14_bits_tag, i_io_refillInfo_14_bits_tag); end
    if (g_io_refillInfo_14_bits_reqID !== i_io_refillInfo_14_bits_reqID) begin errors++; if (errors<=20) $display("[%0d] MISMATCH io_refillInfo_14_bits_reqID: g=%h i=%h", cyc, g_io_refillInfo_14_bits_reqID, i_io_refillInfo_14_bits_reqID); end
    if (g_io_refillInfo_15_valid !== i_io_refillInfo_15_valid) begin errors++; if (errors<=20) $display("[%0d] MISMATCH io_refillInfo_15_valid: g=%h i=%h", cyc, g_io_refillInfo_15_valid, i_io_refillInfo_15_valid); end
    if (g_io_refillInfo_15_bits_set !== i_io_refillInfo_15_bits_set) begin errors++; if (errors<=20) $display("[%0d] MISMATCH io_refillInfo_15_bits_set: g=%h i=%h", cyc, g_io_refillInfo_15_bits_set, i_io_refillInfo_15_bits_set); end
    if (g_io_refillInfo_15_bits_tag !== i_io_refillInfo_15_bits_tag) begin errors++; if (errors<=20) $display("[%0d] MISMATCH io_refillInfo_15_bits_tag: g=%h i=%h", cyc, g_io_refillInfo_15_bits_tag, i_io_refillInfo_15_bits_tag); end
    if (g_io_refillInfo_15_bits_reqID !== i_io_refillInfo_15_bits_reqID) begin errors++; if (errors<=20) $display("[%0d] MISMATCH io_refillInfo_15_bits_reqID: g=%h i=%h", cyc, g_io_refillInfo_15_bits_reqID, i_io_refillInfo_15_bits_reqID); end
  endtask

  initial begin
    rst = 1'b1;
    io_alloc_valid = '0;
    io_alloc_bits_state_w_snpRsp = '0;
    io_alloc_bits_task_set = '0;
    io_alloc_bits_task_bank = '0;
    io_alloc_bits_task_tag = '0;
    io_alloc_bits_task_off = '0;
    io_alloc_bits_task_size = '0;
    io_alloc_bits_task_bufID = '0;
    io_alloc_bits_task_reqID = '0;
    io_alloc_bits_task_replSnp = '0;
    io_alloc_bits_task_snpVec_0 = '0;
    io_alloc_bits_task_tgtID = '0;
    io_alloc_bits_task_srcID = '0;
    io_alloc_bits_task_txnID = '0;
    io_alloc_bits_task_dbID = '0;
    io_alloc_bits_task_fwdNID = '0;
    io_alloc_bits_task_fwdTxnID = '0;
    io_alloc_bits_task_chiOpcode = '0;
    io_alloc_bits_task_resp = '0;
    io_alloc_bits_task_fwdState = '0;
    io_alloc_bits_task_pCrdType = '0;
    io_alloc_bits_task_retToSrc = '0;
    io_alloc_bits_task_doNotGoToSD = '0;
    io_alloc_bits_task_expCompAck = '0;
    io_alloc_bits_task_allowRetry = '0;
    io_alloc_bits_task_order = '0;
    io_alloc_bits_task_memAttr_allocate = '0;
    io_alloc_bits_task_memAttr_cacheable = '0;
    io_alloc_bits_task_memAttr_device = '0;
    io_alloc_bits_task_memAttr_ewa = '0;
    io_alloc_bits_task_snpAttr = '0;
    io_alloc_bits_dirResult_clients_hit = '0;
    io_alloc_bits_dirResult_clients_meta_0_valid = '0;
    io_alloc_bits_isWrite = '0;
    io_task_ready = '0;
    io_respData_valid = '0;
    io_respData_bits_txnID = '0;
    io_respData_bits_opcode = '0;
    io_respData_bits_resp = '0;
    io_respData_bits_srcID = '0;
    io_respData_bits_dataID = '0;
    io_respData_bits_data_data = '0;
    io_resp_valid = '0;
    io_resp_bits_txnID = '0;
    io_resp_bits_opcode = '0;
    io_resp_bits_srcID = '0;
    io_read_valid = '0;
    io_read_bits_id = '0;
    repeat (6) @(posedge clk);
    @(negedge clk); rst = 1'b0;
    for (cyc = 0; cyc < NCYCLES; cyc++) begin
      @(negedge clk);
      drive_random();
      @(posedge clk);
      #1;
      if (cyc >= WARMUP) check_outputs();
    end
    if (errors == 0)
      $display("TEST PASSED: checks=%0d errors=0", checks);
    else
      $display("TEST FAILED: checks=%0d errors=%0d", checks, errors);
    $finish;
  end
endmodule
