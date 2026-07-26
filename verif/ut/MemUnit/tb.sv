// 自动生成: gen_tb.py —— 勿手改
`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 200000;
  int unsigned WARMUP  = 8;
  bit clk = 0, rst;
  int errors = 0, checks = 0, cyc = 0;
  always #5 clk = ~clk;

  logic io_fromMainPipe_alloc_s4_valid;
  logic io_fromMainPipe_alloc_s4_bits_state_s_issueDat;
  logic io_fromMainPipe_alloc_s4_bits_state_w_datRsp;
  logic io_fromMainPipe_alloc_s4_bits_state_w_dbid;
  logic io_fromMainPipe_alloc_s4_bits_state_w_comp;
  logic [11:0] io_fromMainPipe_alloc_s4_bits_task_set;
  logic [1:0] io_fromMainPipe_alloc_s4_bits_task_bank;
  logic [27:0] io_fromMainPipe_alloc_s4_bits_task_tag;
  logic [5:0] io_fromMainPipe_alloc_s4_bits_task_off;
  logic io_fromMainPipe_alloc_s4_bits_task_refillTask;
  logic [3:0] io_fromMainPipe_alloc_s4_bits_task_bufID;
  logic [11:0] io_fromMainPipe_alloc_s4_bits_task_reqID;
  logic io_fromMainPipe_alloc_s4_bits_task_replSnp;
  logic io_fromMainPipe_alloc_s4_bits_task_snpVec_0;
  logic [10:0] io_fromMainPipe_alloc_s4_bits_task_tgtID;
  logic [10:0] io_fromMainPipe_alloc_s4_bits_task_srcID;
  logic [11:0] io_fromMainPipe_alloc_s4_bits_task_txnID;
  logic [10:0] io_fromMainPipe_alloc_s4_bits_task_homeNID;
  logic [11:0] io_fromMainPipe_alloc_s4_bits_task_dbID;
  logic [10:0] io_fromMainPipe_alloc_s4_bits_task_fwdNID;
  logic [11:0] io_fromMainPipe_alloc_s4_bits_task_fwdTxnID;
  logic [6:0] io_fromMainPipe_alloc_s4_bits_task_chiOpcode;
  logic [2:0] io_fromMainPipe_alloc_s4_bits_task_resp;
  logic [2:0] io_fromMainPipe_alloc_s4_bits_task_fwdState;
  logic [3:0] io_fromMainPipe_alloc_s4_bits_task_pCrdType;
  logic io_fromMainPipe_alloc_s4_bits_task_retToSrc;
  logic io_fromMainPipe_alloc_s4_bits_task_doNotGoToSD;
  logic io_fromMainPipe_alloc_s6_valid;
  logic [11:0] io_fromMainPipe_alloc_s6_bits_task_set;
  logic [1:0] io_fromMainPipe_alloc_s6_bits_task_bank;
  logic [27:0] io_fromMainPipe_alloc_s6_bits_task_tag;
  logic [5:0] io_fromMainPipe_alloc_s6_bits_task_off;
  logic [2:0] io_fromMainPipe_alloc_s6_bits_task_size;
  logic io_fromMainPipe_alloc_s6_bits_task_refillTask;
  logic [3:0] io_fromMainPipe_alloc_s6_bits_task_bufID;
  logic [11:0] io_fromMainPipe_alloc_s6_bits_task_reqID;
  logic io_fromMainPipe_alloc_s6_bits_task_replSnp;
  logic io_fromMainPipe_alloc_s6_bits_task_snpVec_0;
  logic [10:0] io_fromMainPipe_alloc_s6_bits_task_tgtID;
  logic [10:0] io_fromMainPipe_alloc_s6_bits_task_srcID;
  logic [11:0] io_fromMainPipe_alloc_s6_bits_task_txnID;
  logic [10:0] io_fromMainPipe_alloc_s6_bits_task_homeNID;
  logic [11:0] io_fromMainPipe_alloc_s6_bits_task_dbID;
  logic [10:0] io_fromMainPipe_alloc_s6_bits_task_fwdNID;
  logic [11:0] io_fromMainPipe_alloc_s6_bits_task_fwdTxnID;
  logic [6:0] io_fromMainPipe_alloc_s6_bits_task_chiOpcode;
  logic [2:0] io_fromMainPipe_alloc_s6_bits_task_resp;
  logic [2:0] io_fromMainPipe_alloc_s6_bits_task_fwdState;
  logic [3:0] io_fromMainPipe_alloc_s6_bits_task_pCrdType;
  logic io_fromMainPipe_alloc_s6_bits_task_retToSrc;
  logic io_fromMainPipe_alloc_s6_bits_task_doNotGoToSD;
  logic io_fromMainPipe_alloc_s6_bits_task_expCompAck;
  logic io_fromMainPipe_alloc_s6_bits_task_allowRetry;
  logic [1:0] io_fromMainPipe_alloc_s6_bits_task_order;
  logic io_fromMainPipe_alloc_s6_bits_task_memAttr_allocate;
  logic io_fromMainPipe_alloc_s6_bits_task_memAttr_cacheable;
  logic io_fromMainPipe_alloc_s6_bits_task_memAttr_device;
  logic io_fromMainPipe_alloc_s6_bits_task_memAttr_ewa;
  logic io_fromMainPipe_alloc_s6_bits_task_snpAttr;
  logic [255:0] io_fromMainPipe_alloc_s6_bits_data_data_0_data;
  logic [255:0] io_fromMainPipe_alloc_s6_bits_data_data_1_data;
  logic io_urgentRead_valid;
  logic [11:0] io_urgentRead_bits_set;
  logic [1:0] io_urgentRead_bits_bank;
  logic [27:0] io_urgentRead_bits_tag;
  logic [10:0] io_urgentRead_bits_tgtID;
  logic [10:0] io_urgentRead_bits_srcID;
  logic [11:0] io_urgentRead_bits_txnID;
  logic [3:0] io_urgentRead_bits_pCrdType;
  logic io_snRxrsp_valid;
  logic [11:0] io_snRxrsp_bits_txnID;
  logic [11:0] io_snRxrsp_bits_dbID;
  logic [6:0] io_snRxrsp_bits_opcode;
  logic io_rnRxdat_valid;
  logic [11:0] io_rnRxdat_bits_txnID;
  logic [2:0] io_rnRxdat_bits_resp;
  logic [1:0] io_rnRxdat_bits_dataID;
  logic [255:0] io_rnRxdat_bits_data_data;
  logic io_rnRxrsp_valid;
  logic [11:0] io_rnRxrsp_bits_txnID;
  logic io_txreq_ready;
  logic io_txdat_ready;
  logic io_respInfo_0_valid;
  logic [6:0] io_respInfo_0_bits_opcode;
  logic [11:0] io_respInfo_0_bits_reqID;
  logic io_respInfo_0_bits_w_snpRsp;
  logic io_respInfo_0_bits_w_compdata;
  logic io_respInfo_1_valid;
  logic [6:0] io_respInfo_1_bits_opcode;
  logic [11:0] io_respInfo_1_bits_reqID;
  logic io_respInfo_1_bits_w_snpRsp;
  logic io_respInfo_1_bits_w_compdata;
  logic io_respInfo_2_valid;
  logic [6:0] io_respInfo_2_bits_opcode;
  logic [11:0] io_respInfo_2_bits_reqID;
  logic io_respInfo_2_bits_w_snpRsp;
  logic io_respInfo_2_bits_w_compdata;
  logic io_respInfo_3_valid;
  logic [6:0] io_respInfo_3_bits_opcode;
  logic [11:0] io_respInfo_3_bits_reqID;
  logic io_respInfo_3_bits_w_snpRsp;
  logic io_respInfo_3_bits_w_compdata;
  logic io_respInfo_4_valid;
  logic [6:0] io_respInfo_4_bits_opcode;
  logic [11:0] io_respInfo_4_bits_reqID;
  logic io_respInfo_4_bits_w_snpRsp;
  logic io_respInfo_4_bits_w_compdata;
  logic io_respInfo_5_valid;
  logic [6:0] io_respInfo_5_bits_opcode;
  logic [11:0] io_respInfo_5_bits_reqID;
  logic io_respInfo_5_bits_w_snpRsp;
  logic io_respInfo_5_bits_w_compdata;
  logic io_respInfo_6_valid;
  logic [6:0] io_respInfo_6_bits_opcode;
  logic [11:0] io_respInfo_6_bits_reqID;
  logic io_respInfo_6_bits_w_snpRsp;
  logic io_respInfo_6_bits_w_compdata;
  logic io_respInfo_7_valid;
  logic [6:0] io_respInfo_7_bits_opcode;
  logic [11:0] io_respInfo_7_bits_reqID;
  logic io_respInfo_7_bits_w_snpRsp;
  logic io_respInfo_7_bits_w_compdata;
  logic io_respInfo_8_valid;
  logic [6:0] io_respInfo_8_bits_opcode;
  logic [11:0] io_respInfo_8_bits_reqID;
  logic io_respInfo_8_bits_w_snpRsp;
  logic io_respInfo_8_bits_w_compdata;
  logic io_respInfo_9_valid;
  logic [6:0] io_respInfo_9_bits_opcode;
  logic [11:0] io_respInfo_9_bits_reqID;
  logic io_respInfo_9_bits_w_snpRsp;
  logic io_respInfo_9_bits_w_compdata;
  logic io_respInfo_10_valid;
  logic [6:0] io_respInfo_10_bits_opcode;
  logic [11:0] io_respInfo_10_bits_reqID;
  logic io_respInfo_10_bits_w_snpRsp;
  logic io_respInfo_10_bits_w_compdata;
  logic io_respInfo_11_valid;
  logic [6:0] io_respInfo_11_bits_opcode;
  logic [11:0] io_respInfo_11_bits_reqID;
  logic io_respInfo_11_bits_w_snpRsp;
  logic io_respInfo_11_bits_w_compdata;
  logic io_respInfo_12_valid;
  logic [6:0] io_respInfo_12_bits_opcode;
  logic [11:0] io_respInfo_12_bits_reqID;
  logic io_respInfo_12_bits_w_snpRsp;
  logic io_respInfo_12_bits_w_compdata;
  logic io_respInfo_13_valid;
  logic [6:0] io_respInfo_13_bits_opcode;
  logic [11:0] io_respInfo_13_bits_reqID;
  logic io_respInfo_13_bits_w_snpRsp;
  logic io_respInfo_13_bits_w_compdata;
  logic io_respInfo_14_valid;
  logic [6:0] io_respInfo_14_bits_opcode;
  logic [11:0] io_respInfo_14_bits_reqID;
  logic io_respInfo_14_bits_w_snpRsp;
  logic io_respInfo_14_bits_w_compdata;
  logic io_respInfo_15_valid;
  logic [6:0] io_respInfo_15_bits_opcode;
  logic [11:0] io_respInfo_15_bits_reqID;
  logic io_respInfo_15_bits_w_snpRsp;
  logic io_respInfo_15_bits_w_compdata;
  wire g_io_urgentRead_ready;
  wire i_io_urgentRead_ready;
  wire g_io_txreq_valid;
  wire i_io_txreq_valid;
  wire [11:0] g_io_txreq_bits_set;
  wire [11:0] i_io_txreq_bits_set;
  wire [1:0] g_io_txreq_bits_bank;
  wire [1:0] i_io_txreq_bits_bank;
  wire [27:0] g_io_txreq_bits_tag;
  wire [27:0] i_io_txreq_bits_tag;
  wire [2:0] g_io_txreq_bits_size;
  wire [2:0] i_io_txreq_bits_size;
  wire [10:0] g_io_txreq_bits_tgtID;
  wire [10:0] i_io_txreq_bits_tgtID;
  wire [10:0] g_io_txreq_bits_srcID;
  wire [10:0] i_io_txreq_bits_srcID;
  wire [11:0] g_io_txreq_bits_txnID;
  wire [11:0] i_io_txreq_bits_txnID;
  wire [6:0] g_io_txreq_bits_chiOpcode;
  wire [6:0] i_io_txreq_bits_chiOpcode;
  wire [3:0] g_io_txreq_bits_pCrdType;
  wire [3:0] i_io_txreq_bits_pCrdType;
  wire g_io_txreq_bits_expCompAck;
  wire i_io_txreq_bits_expCompAck;
  wire g_io_txreq_bits_allowRetry;
  wire i_io_txreq_bits_allowRetry;
  wire [1:0] g_io_txreq_bits_order;
  wire [1:0] i_io_txreq_bits_order;
  wire g_io_txreq_bits_memAttr_allocate;
  wire i_io_txreq_bits_memAttr_allocate;
  wire g_io_txreq_bits_memAttr_cacheable;
  wire i_io_txreq_bits_memAttr_cacheable;
  wire g_io_txreq_bits_memAttr_device;
  wire i_io_txreq_bits_memAttr_device;
  wire g_io_txreq_bits_memAttr_ewa;
  wire i_io_txreq_bits_memAttr_ewa;
  wire g_io_txreq_bits_snpAttr;
  wire i_io_txreq_bits_snpAttr;
  wire g_io_txdat_valid;
  wire i_io_txdat_valid;
  wire [10:0] g_io_txdat_bits_task_tgtID;
  wire [10:0] i_io_txdat_bits_task_tgtID;
  wire [10:0] g_io_txdat_bits_task_srcID;
  wire [10:0] i_io_txdat_bits_task_srcID;
  wire [11:0] g_io_txdat_bits_task_txnID;
  wire [11:0] i_io_txdat_bits_task_txnID;
  wire [10:0] g_io_txdat_bits_task_homeNID;
  wire [10:0] i_io_txdat_bits_task_homeNID;
  wire [11:0] g_io_txdat_bits_task_dbID;
  wire [11:0] i_io_txdat_bits_task_dbID;
  wire [2:0] g_io_txdat_bits_task_resp;
  wire [2:0] i_io_txdat_bits_task_resp;
  wire [2:0] g_io_txdat_bits_task_fwdState;
  wire [2:0] i_io_txdat_bits_task_fwdState;
  wire [255:0] g_io_txdat_bits_data_data_0_data;
  wire [255:0] i_io_txdat_bits_data_data_0_data;
  wire [255:0] g_io_txdat_bits_data_data_1_data;
  wire [255:0] i_io_txdat_bits_data_data_1_data;
  wire g_io_bypassData_0_valid;
  wire i_io_bypassData_0_valid;
  wire [11:0] g_io_bypassData_0_bits_txnID;
  wire [11:0] i_io_bypassData_0_bits_txnID;
  wire [6:0] g_io_bypassData_0_bits_opcode;
  wire [6:0] i_io_bypassData_0_bits_opcode;
  wire [255:0] g_io_bypassData_0_bits_data_data;
  wire [255:0] i_io_bypassData_0_bits_data_data;
  wire g_io_bypassData_1_valid;
  wire i_io_bypassData_1_valid;
  wire [11:0] g_io_bypassData_1_bits_txnID;
  wire [11:0] i_io_bypassData_1_bits_txnID;
  wire [6:0] g_io_bypassData_1_bits_opcode;
  wire [6:0] i_io_bypassData_1_bits_opcode;
  wire [1:0] g_io_bypassData_1_bits_dataID;
  wire [1:0] i_io_bypassData_1_bits_dataID;
  wire [255:0] g_io_bypassData_1_bits_data_data;
  wire [255:0] i_io_bypassData_1_bits_data_data;
  wire g_io_memInfo_0_valid;
  wire i_io_memInfo_0_valid;
  wire [11:0] g_io_memInfo_0_bits_set;
  wire [11:0] i_io_memInfo_0_bits_set;
  wire [27:0] g_io_memInfo_0_bits_tag;
  wire [27:0] i_io_memInfo_0_bits_tag;
  wire [6:0] g_io_memInfo_0_bits_opcode;
  wire [6:0] i_io_memInfo_0_bits_opcode;
  wire [11:0] g_io_memInfo_0_bits_reqID;
  wire [11:0] i_io_memInfo_0_bits_reqID;
  wire g_io_memInfo_0_bits_w_datRsp;
  wire i_io_memInfo_0_bits_w_datRsp;
  wire g_io_memInfo_1_valid;
  wire i_io_memInfo_1_valid;
  wire [11:0] g_io_memInfo_1_bits_set;
  wire [11:0] i_io_memInfo_1_bits_set;
  wire [27:0] g_io_memInfo_1_bits_tag;
  wire [27:0] i_io_memInfo_1_bits_tag;
  wire [6:0] g_io_memInfo_1_bits_opcode;
  wire [6:0] i_io_memInfo_1_bits_opcode;
  wire [11:0] g_io_memInfo_1_bits_reqID;
  wire [11:0] i_io_memInfo_1_bits_reqID;
  wire g_io_memInfo_1_bits_w_datRsp;
  wire i_io_memInfo_1_bits_w_datRsp;
  wire g_io_memInfo_2_valid;
  wire i_io_memInfo_2_valid;
  wire [11:0] g_io_memInfo_2_bits_set;
  wire [11:0] i_io_memInfo_2_bits_set;
  wire [27:0] g_io_memInfo_2_bits_tag;
  wire [27:0] i_io_memInfo_2_bits_tag;
  wire [6:0] g_io_memInfo_2_bits_opcode;
  wire [6:0] i_io_memInfo_2_bits_opcode;
  wire [11:0] g_io_memInfo_2_bits_reqID;
  wire [11:0] i_io_memInfo_2_bits_reqID;
  wire g_io_memInfo_2_bits_w_datRsp;
  wire i_io_memInfo_2_bits_w_datRsp;
  wire g_io_memInfo_3_valid;
  wire i_io_memInfo_3_valid;
  wire [11:0] g_io_memInfo_3_bits_set;
  wire [11:0] i_io_memInfo_3_bits_set;
  wire [27:0] g_io_memInfo_3_bits_tag;
  wire [27:0] i_io_memInfo_3_bits_tag;
  wire [6:0] g_io_memInfo_3_bits_opcode;
  wire [6:0] i_io_memInfo_3_bits_opcode;
  wire [11:0] g_io_memInfo_3_bits_reqID;
  wire [11:0] i_io_memInfo_3_bits_reqID;
  wire g_io_memInfo_3_bits_w_datRsp;
  wire i_io_memInfo_3_bits_w_datRsp;
  wire g_io_memInfo_4_valid;
  wire i_io_memInfo_4_valid;
  wire [11:0] g_io_memInfo_4_bits_set;
  wire [11:0] i_io_memInfo_4_bits_set;
  wire [27:0] g_io_memInfo_4_bits_tag;
  wire [27:0] i_io_memInfo_4_bits_tag;
  wire [6:0] g_io_memInfo_4_bits_opcode;
  wire [6:0] i_io_memInfo_4_bits_opcode;
  wire [11:0] g_io_memInfo_4_bits_reqID;
  wire [11:0] i_io_memInfo_4_bits_reqID;
  wire g_io_memInfo_4_bits_w_datRsp;
  wire i_io_memInfo_4_bits_w_datRsp;
  wire g_io_memInfo_5_valid;
  wire i_io_memInfo_5_valid;
  wire [11:0] g_io_memInfo_5_bits_set;
  wire [11:0] i_io_memInfo_5_bits_set;
  wire [27:0] g_io_memInfo_5_bits_tag;
  wire [27:0] i_io_memInfo_5_bits_tag;
  wire [6:0] g_io_memInfo_5_bits_opcode;
  wire [6:0] i_io_memInfo_5_bits_opcode;
  wire [11:0] g_io_memInfo_5_bits_reqID;
  wire [11:0] i_io_memInfo_5_bits_reqID;
  wire g_io_memInfo_5_bits_w_datRsp;
  wire i_io_memInfo_5_bits_w_datRsp;
  wire g_io_memInfo_6_valid;
  wire i_io_memInfo_6_valid;
  wire [11:0] g_io_memInfo_6_bits_set;
  wire [11:0] i_io_memInfo_6_bits_set;
  wire [27:0] g_io_memInfo_6_bits_tag;
  wire [27:0] i_io_memInfo_6_bits_tag;
  wire [6:0] g_io_memInfo_6_bits_opcode;
  wire [6:0] i_io_memInfo_6_bits_opcode;
  wire [11:0] g_io_memInfo_6_bits_reqID;
  wire [11:0] i_io_memInfo_6_bits_reqID;
  wire g_io_memInfo_6_bits_w_datRsp;
  wire i_io_memInfo_6_bits_w_datRsp;
  wire g_io_memInfo_7_valid;
  wire i_io_memInfo_7_valid;
  wire [11:0] g_io_memInfo_7_bits_set;
  wire [11:0] i_io_memInfo_7_bits_set;
  wire [27:0] g_io_memInfo_7_bits_tag;
  wire [27:0] i_io_memInfo_7_bits_tag;
  wire [6:0] g_io_memInfo_7_bits_opcode;
  wire [6:0] i_io_memInfo_7_bits_opcode;
  wire [11:0] g_io_memInfo_7_bits_reqID;
  wire [11:0] i_io_memInfo_7_bits_reqID;
  wire g_io_memInfo_7_bits_w_datRsp;
  wire i_io_memInfo_7_bits_w_datRsp;
  wire g_io_memInfo_8_valid;
  wire i_io_memInfo_8_valid;
  wire [11:0] g_io_memInfo_8_bits_set;
  wire [11:0] i_io_memInfo_8_bits_set;
  wire [27:0] g_io_memInfo_8_bits_tag;
  wire [27:0] i_io_memInfo_8_bits_tag;
  wire [6:0] g_io_memInfo_8_bits_opcode;
  wire [6:0] i_io_memInfo_8_bits_opcode;
  wire [11:0] g_io_memInfo_8_bits_reqID;
  wire [11:0] i_io_memInfo_8_bits_reqID;
  wire g_io_memInfo_8_bits_w_datRsp;
  wire i_io_memInfo_8_bits_w_datRsp;
  wire g_io_memInfo_9_valid;
  wire i_io_memInfo_9_valid;
  wire [11:0] g_io_memInfo_9_bits_set;
  wire [11:0] i_io_memInfo_9_bits_set;
  wire [27:0] g_io_memInfo_9_bits_tag;
  wire [27:0] i_io_memInfo_9_bits_tag;
  wire [6:0] g_io_memInfo_9_bits_opcode;
  wire [6:0] i_io_memInfo_9_bits_opcode;
  wire [11:0] g_io_memInfo_9_bits_reqID;
  wire [11:0] i_io_memInfo_9_bits_reqID;
  wire g_io_memInfo_9_bits_w_datRsp;
  wire i_io_memInfo_9_bits_w_datRsp;
  wire g_io_memInfo_10_valid;
  wire i_io_memInfo_10_valid;
  wire [11:0] g_io_memInfo_10_bits_set;
  wire [11:0] i_io_memInfo_10_bits_set;
  wire [27:0] g_io_memInfo_10_bits_tag;
  wire [27:0] i_io_memInfo_10_bits_tag;
  wire [6:0] g_io_memInfo_10_bits_opcode;
  wire [6:0] i_io_memInfo_10_bits_opcode;
  wire [11:0] g_io_memInfo_10_bits_reqID;
  wire [11:0] i_io_memInfo_10_bits_reqID;
  wire g_io_memInfo_10_bits_w_datRsp;
  wire i_io_memInfo_10_bits_w_datRsp;
  wire g_io_memInfo_11_valid;
  wire i_io_memInfo_11_valid;
  wire [11:0] g_io_memInfo_11_bits_set;
  wire [11:0] i_io_memInfo_11_bits_set;
  wire [27:0] g_io_memInfo_11_bits_tag;
  wire [27:0] i_io_memInfo_11_bits_tag;
  wire [6:0] g_io_memInfo_11_bits_opcode;
  wire [6:0] i_io_memInfo_11_bits_opcode;
  wire [11:0] g_io_memInfo_11_bits_reqID;
  wire [11:0] i_io_memInfo_11_bits_reqID;
  wire g_io_memInfo_11_bits_w_datRsp;
  wire i_io_memInfo_11_bits_w_datRsp;
  wire g_io_memInfo_12_valid;
  wire i_io_memInfo_12_valid;
  wire [11:0] g_io_memInfo_12_bits_set;
  wire [11:0] i_io_memInfo_12_bits_set;
  wire [27:0] g_io_memInfo_12_bits_tag;
  wire [27:0] i_io_memInfo_12_bits_tag;
  wire [6:0] g_io_memInfo_12_bits_opcode;
  wire [6:0] i_io_memInfo_12_bits_opcode;
  wire [11:0] g_io_memInfo_12_bits_reqID;
  wire [11:0] i_io_memInfo_12_bits_reqID;
  wire g_io_memInfo_12_bits_w_datRsp;
  wire i_io_memInfo_12_bits_w_datRsp;
  wire g_io_memInfo_13_valid;
  wire i_io_memInfo_13_valid;
  wire [11:0] g_io_memInfo_13_bits_set;
  wire [11:0] i_io_memInfo_13_bits_set;
  wire [27:0] g_io_memInfo_13_bits_tag;
  wire [27:0] i_io_memInfo_13_bits_tag;
  wire [6:0] g_io_memInfo_13_bits_opcode;
  wire [6:0] i_io_memInfo_13_bits_opcode;
  wire [11:0] g_io_memInfo_13_bits_reqID;
  wire [11:0] i_io_memInfo_13_bits_reqID;
  wire g_io_memInfo_13_bits_w_datRsp;
  wire i_io_memInfo_13_bits_w_datRsp;
  wire g_io_memInfo_14_valid;
  wire i_io_memInfo_14_valid;
  wire [11:0] g_io_memInfo_14_bits_set;
  wire [11:0] i_io_memInfo_14_bits_set;
  wire [27:0] g_io_memInfo_14_bits_tag;
  wire [27:0] i_io_memInfo_14_bits_tag;
  wire [6:0] g_io_memInfo_14_bits_opcode;
  wire [6:0] i_io_memInfo_14_bits_opcode;
  wire [11:0] g_io_memInfo_14_bits_reqID;
  wire [11:0] i_io_memInfo_14_bits_reqID;
  wire g_io_memInfo_14_bits_w_datRsp;
  wire i_io_memInfo_14_bits_w_datRsp;
  wire g_io_memInfo_15_valid;
  wire i_io_memInfo_15_valid;
  wire [11:0] g_io_memInfo_15_bits_set;
  wire [11:0] i_io_memInfo_15_bits_set;
  wire [27:0] g_io_memInfo_15_bits_tag;
  wire [27:0] i_io_memInfo_15_bits_tag;
  wire [6:0] g_io_memInfo_15_bits_opcode;
  wire [6:0] i_io_memInfo_15_bits_opcode;
  wire [11:0] g_io_memInfo_15_bits_reqID;
  wire [11:0] i_io_memInfo_15_bits_reqID;
  wire g_io_memInfo_15_bits_w_datRsp;
  wire i_io_memInfo_15_bits_w_datRsp;

  MemUnit dut_g (
    .clock(clk), .reset(rst),
    .io_fromMainPipe_alloc_s4_valid(io_fromMainPipe_alloc_s4_valid),
    .io_fromMainPipe_alloc_s4_bits_state_s_issueDat(io_fromMainPipe_alloc_s4_bits_state_s_issueDat),
    .io_fromMainPipe_alloc_s4_bits_state_w_datRsp(io_fromMainPipe_alloc_s4_bits_state_w_datRsp),
    .io_fromMainPipe_alloc_s4_bits_state_w_dbid(io_fromMainPipe_alloc_s4_bits_state_w_dbid),
    .io_fromMainPipe_alloc_s4_bits_state_w_comp(io_fromMainPipe_alloc_s4_bits_state_w_comp),
    .io_fromMainPipe_alloc_s4_bits_task_set(io_fromMainPipe_alloc_s4_bits_task_set),
    .io_fromMainPipe_alloc_s4_bits_task_bank(io_fromMainPipe_alloc_s4_bits_task_bank),
    .io_fromMainPipe_alloc_s4_bits_task_tag(io_fromMainPipe_alloc_s4_bits_task_tag),
    .io_fromMainPipe_alloc_s4_bits_task_off(io_fromMainPipe_alloc_s4_bits_task_off),
    .io_fromMainPipe_alloc_s4_bits_task_refillTask(io_fromMainPipe_alloc_s4_bits_task_refillTask),
    .io_fromMainPipe_alloc_s4_bits_task_bufID(io_fromMainPipe_alloc_s4_bits_task_bufID),
    .io_fromMainPipe_alloc_s4_bits_task_reqID(io_fromMainPipe_alloc_s4_bits_task_reqID),
    .io_fromMainPipe_alloc_s4_bits_task_replSnp(io_fromMainPipe_alloc_s4_bits_task_replSnp),
    .io_fromMainPipe_alloc_s4_bits_task_snpVec_0(io_fromMainPipe_alloc_s4_bits_task_snpVec_0),
    .io_fromMainPipe_alloc_s4_bits_task_tgtID(io_fromMainPipe_alloc_s4_bits_task_tgtID),
    .io_fromMainPipe_alloc_s4_bits_task_srcID(io_fromMainPipe_alloc_s4_bits_task_srcID),
    .io_fromMainPipe_alloc_s4_bits_task_txnID(io_fromMainPipe_alloc_s4_bits_task_txnID),
    .io_fromMainPipe_alloc_s4_bits_task_homeNID(io_fromMainPipe_alloc_s4_bits_task_homeNID),
    .io_fromMainPipe_alloc_s4_bits_task_dbID(io_fromMainPipe_alloc_s4_bits_task_dbID),
    .io_fromMainPipe_alloc_s4_bits_task_fwdNID(io_fromMainPipe_alloc_s4_bits_task_fwdNID),
    .io_fromMainPipe_alloc_s4_bits_task_fwdTxnID(io_fromMainPipe_alloc_s4_bits_task_fwdTxnID),
    .io_fromMainPipe_alloc_s4_bits_task_chiOpcode(io_fromMainPipe_alloc_s4_bits_task_chiOpcode),
    .io_fromMainPipe_alloc_s4_bits_task_resp(io_fromMainPipe_alloc_s4_bits_task_resp),
    .io_fromMainPipe_alloc_s4_bits_task_fwdState(io_fromMainPipe_alloc_s4_bits_task_fwdState),
    .io_fromMainPipe_alloc_s4_bits_task_pCrdType(io_fromMainPipe_alloc_s4_bits_task_pCrdType),
    .io_fromMainPipe_alloc_s4_bits_task_retToSrc(io_fromMainPipe_alloc_s4_bits_task_retToSrc),
    .io_fromMainPipe_alloc_s4_bits_task_doNotGoToSD(io_fromMainPipe_alloc_s4_bits_task_doNotGoToSD),
    .io_fromMainPipe_alloc_s6_valid(io_fromMainPipe_alloc_s6_valid),
    .io_fromMainPipe_alloc_s6_bits_task_set(io_fromMainPipe_alloc_s6_bits_task_set),
    .io_fromMainPipe_alloc_s6_bits_task_bank(io_fromMainPipe_alloc_s6_bits_task_bank),
    .io_fromMainPipe_alloc_s6_bits_task_tag(io_fromMainPipe_alloc_s6_bits_task_tag),
    .io_fromMainPipe_alloc_s6_bits_task_off(io_fromMainPipe_alloc_s6_bits_task_off),
    .io_fromMainPipe_alloc_s6_bits_task_size(io_fromMainPipe_alloc_s6_bits_task_size),
    .io_fromMainPipe_alloc_s6_bits_task_refillTask(io_fromMainPipe_alloc_s6_bits_task_refillTask),
    .io_fromMainPipe_alloc_s6_bits_task_bufID(io_fromMainPipe_alloc_s6_bits_task_bufID),
    .io_fromMainPipe_alloc_s6_bits_task_reqID(io_fromMainPipe_alloc_s6_bits_task_reqID),
    .io_fromMainPipe_alloc_s6_bits_task_replSnp(io_fromMainPipe_alloc_s6_bits_task_replSnp),
    .io_fromMainPipe_alloc_s6_bits_task_snpVec_0(io_fromMainPipe_alloc_s6_bits_task_snpVec_0),
    .io_fromMainPipe_alloc_s6_bits_task_tgtID(io_fromMainPipe_alloc_s6_bits_task_tgtID),
    .io_fromMainPipe_alloc_s6_bits_task_srcID(io_fromMainPipe_alloc_s6_bits_task_srcID),
    .io_fromMainPipe_alloc_s6_bits_task_txnID(io_fromMainPipe_alloc_s6_bits_task_txnID),
    .io_fromMainPipe_alloc_s6_bits_task_homeNID(io_fromMainPipe_alloc_s6_bits_task_homeNID),
    .io_fromMainPipe_alloc_s6_bits_task_dbID(io_fromMainPipe_alloc_s6_bits_task_dbID),
    .io_fromMainPipe_alloc_s6_bits_task_fwdNID(io_fromMainPipe_alloc_s6_bits_task_fwdNID),
    .io_fromMainPipe_alloc_s6_bits_task_fwdTxnID(io_fromMainPipe_alloc_s6_bits_task_fwdTxnID),
    .io_fromMainPipe_alloc_s6_bits_task_chiOpcode(io_fromMainPipe_alloc_s6_bits_task_chiOpcode),
    .io_fromMainPipe_alloc_s6_bits_task_resp(io_fromMainPipe_alloc_s6_bits_task_resp),
    .io_fromMainPipe_alloc_s6_bits_task_fwdState(io_fromMainPipe_alloc_s6_bits_task_fwdState),
    .io_fromMainPipe_alloc_s6_bits_task_pCrdType(io_fromMainPipe_alloc_s6_bits_task_pCrdType),
    .io_fromMainPipe_alloc_s6_bits_task_retToSrc(io_fromMainPipe_alloc_s6_bits_task_retToSrc),
    .io_fromMainPipe_alloc_s6_bits_task_doNotGoToSD(io_fromMainPipe_alloc_s6_bits_task_doNotGoToSD),
    .io_fromMainPipe_alloc_s6_bits_task_expCompAck(io_fromMainPipe_alloc_s6_bits_task_expCompAck),
    .io_fromMainPipe_alloc_s6_bits_task_allowRetry(io_fromMainPipe_alloc_s6_bits_task_allowRetry),
    .io_fromMainPipe_alloc_s6_bits_task_order(io_fromMainPipe_alloc_s6_bits_task_order),
    .io_fromMainPipe_alloc_s6_bits_task_memAttr_allocate(io_fromMainPipe_alloc_s6_bits_task_memAttr_allocate),
    .io_fromMainPipe_alloc_s6_bits_task_memAttr_cacheable(io_fromMainPipe_alloc_s6_bits_task_memAttr_cacheable),
    .io_fromMainPipe_alloc_s6_bits_task_memAttr_device(io_fromMainPipe_alloc_s6_bits_task_memAttr_device),
    .io_fromMainPipe_alloc_s6_bits_task_memAttr_ewa(io_fromMainPipe_alloc_s6_bits_task_memAttr_ewa),
    .io_fromMainPipe_alloc_s6_bits_task_snpAttr(io_fromMainPipe_alloc_s6_bits_task_snpAttr),
    .io_fromMainPipe_alloc_s6_bits_data_data_0_data(io_fromMainPipe_alloc_s6_bits_data_data_0_data),
    .io_fromMainPipe_alloc_s6_bits_data_data_1_data(io_fromMainPipe_alloc_s6_bits_data_data_1_data),
    .io_urgentRead_valid(io_urgentRead_valid),
    .io_urgentRead_bits_set(io_urgentRead_bits_set),
    .io_urgentRead_bits_bank(io_urgentRead_bits_bank),
    .io_urgentRead_bits_tag(io_urgentRead_bits_tag),
    .io_urgentRead_bits_tgtID(io_urgentRead_bits_tgtID),
    .io_urgentRead_bits_srcID(io_urgentRead_bits_srcID),
    .io_urgentRead_bits_txnID(io_urgentRead_bits_txnID),
    .io_urgentRead_bits_pCrdType(io_urgentRead_bits_pCrdType),
    .io_snRxrsp_valid(io_snRxrsp_valid),
    .io_snRxrsp_bits_txnID(io_snRxrsp_bits_txnID),
    .io_snRxrsp_bits_dbID(io_snRxrsp_bits_dbID),
    .io_snRxrsp_bits_opcode(io_snRxrsp_bits_opcode),
    .io_rnRxdat_valid(io_rnRxdat_valid),
    .io_rnRxdat_bits_txnID(io_rnRxdat_bits_txnID),
    .io_rnRxdat_bits_resp(io_rnRxdat_bits_resp),
    .io_rnRxdat_bits_dataID(io_rnRxdat_bits_dataID),
    .io_rnRxdat_bits_data_data(io_rnRxdat_bits_data_data),
    .io_rnRxrsp_valid(io_rnRxrsp_valid),
    .io_rnRxrsp_bits_txnID(io_rnRxrsp_bits_txnID),
    .io_txreq_ready(io_txreq_ready),
    .io_txdat_ready(io_txdat_ready),
    .io_respInfo_0_valid(io_respInfo_0_valid),
    .io_respInfo_0_bits_opcode(io_respInfo_0_bits_opcode),
    .io_respInfo_0_bits_reqID(io_respInfo_0_bits_reqID),
    .io_respInfo_0_bits_w_snpRsp(io_respInfo_0_bits_w_snpRsp),
    .io_respInfo_0_bits_w_compdata(io_respInfo_0_bits_w_compdata),
    .io_respInfo_1_valid(io_respInfo_1_valid),
    .io_respInfo_1_bits_opcode(io_respInfo_1_bits_opcode),
    .io_respInfo_1_bits_reqID(io_respInfo_1_bits_reqID),
    .io_respInfo_1_bits_w_snpRsp(io_respInfo_1_bits_w_snpRsp),
    .io_respInfo_1_bits_w_compdata(io_respInfo_1_bits_w_compdata),
    .io_respInfo_2_valid(io_respInfo_2_valid),
    .io_respInfo_2_bits_opcode(io_respInfo_2_bits_opcode),
    .io_respInfo_2_bits_reqID(io_respInfo_2_bits_reqID),
    .io_respInfo_2_bits_w_snpRsp(io_respInfo_2_bits_w_snpRsp),
    .io_respInfo_2_bits_w_compdata(io_respInfo_2_bits_w_compdata),
    .io_respInfo_3_valid(io_respInfo_3_valid),
    .io_respInfo_3_bits_opcode(io_respInfo_3_bits_opcode),
    .io_respInfo_3_bits_reqID(io_respInfo_3_bits_reqID),
    .io_respInfo_3_bits_w_snpRsp(io_respInfo_3_bits_w_snpRsp),
    .io_respInfo_3_bits_w_compdata(io_respInfo_3_bits_w_compdata),
    .io_respInfo_4_valid(io_respInfo_4_valid),
    .io_respInfo_4_bits_opcode(io_respInfo_4_bits_opcode),
    .io_respInfo_4_bits_reqID(io_respInfo_4_bits_reqID),
    .io_respInfo_4_bits_w_snpRsp(io_respInfo_4_bits_w_snpRsp),
    .io_respInfo_4_bits_w_compdata(io_respInfo_4_bits_w_compdata),
    .io_respInfo_5_valid(io_respInfo_5_valid),
    .io_respInfo_5_bits_opcode(io_respInfo_5_bits_opcode),
    .io_respInfo_5_bits_reqID(io_respInfo_5_bits_reqID),
    .io_respInfo_5_bits_w_snpRsp(io_respInfo_5_bits_w_snpRsp),
    .io_respInfo_5_bits_w_compdata(io_respInfo_5_bits_w_compdata),
    .io_respInfo_6_valid(io_respInfo_6_valid),
    .io_respInfo_6_bits_opcode(io_respInfo_6_bits_opcode),
    .io_respInfo_6_bits_reqID(io_respInfo_6_bits_reqID),
    .io_respInfo_6_bits_w_snpRsp(io_respInfo_6_bits_w_snpRsp),
    .io_respInfo_6_bits_w_compdata(io_respInfo_6_bits_w_compdata),
    .io_respInfo_7_valid(io_respInfo_7_valid),
    .io_respInfo_7_bits_opcode(io_respInfo_7_bits_opcode),
    .io_respInfo_7_bits_reqID(io_respInfo_7_bits_reqID),
    .io_respInfo_7_bits_w_snpRsp(io_respInfo_7_bits_w_snpRsp),
    .io_respInfo_7_bits_w_compdata(io_respInfo_7_bits_w_compdata),
    .io_respInfo_8_valid(io_respInfo_8_valid),
    .io_respInfo_8_bits_opcode(io_respInfo_8_bits_opcode),
    .io_respInfo_8_bits_reqID(io_respInfo_8_bits_reqID),
    .io_respInfo_8_bits_w_snpRsp(io_respInfo_8_bits_w_snpRsp),
    .io_respInfo_8_bits_w_compdata(io_respInfo_8_bits_w_compdata),
    .io_respInfo_9_valid(io_respInfo_9_valid),
    .io_respInfo_9_bits_opcode(io_respInfo_9_bits_opcode),
    .io_respInfo_9_bits_reqID(io_respInfo_9_bits_reqID),
    .io_respInfo_9_bits_w_snpRsp(io_respInfo_9_bits_w_snpRsp),
    .io_respInfo_9_bits_w_compdata(io_respInfo_9_bits_w_compdata),
    .io_respInfo_10_valid(io_respInfo_10_valid),
    .io_respInfo_10_bits_opcode(io_respInfo_10_bits_opcode),
    .io_respInfo_10_bits_reqID(io_respInfo_10_bits_reqID),
    .io_respInfo_10_bits_w_snpRsp(io_respInfo_10_bits_w_snpRsp),
    .io_respInfo_10_bits_w_compdata(io_respInfo_10_bits_w_compdata),
    .io_respInfo_11_valid(io_respInfo_11_valid),
    .io_respInfo_11_bits_opcode(io_respInfo_11_bits_opcode),
    .io_respInfo_11_bits_reqID(io_respInfo_11_bits_reqID),
    .io_respInfo_11_bits_w_snpRsp(io_respInfo_11_bits_w_snpRsp),
    .io_respInfo_11_bits_w_compdata(io_respInfo_11_bits_w_compdata),
    .io_respInfo_12_valid(io_respInfo_12_valid),
    .io_respInfo_12_bits_opcode(io_respInfo_12_bits_opcode),
    .io_respInfo_12_bits_reqID(io_respInfo_12_bits_reqID),
    .io_respInfo_12_bits_w_snpRsp(io_respInfo_12_bits_w_snpRsp),
    .io_respInfo_12_bits_w_compdata(io_respInfo_12_bits_w_compdata),
    .io_respInfo_13_valid(io_respInfo_13_valid),
    .io_respInfo_13_bits_opcode(io_respInfo_13_bits_opcode),
    .io_respInfo_13_bits_reqID(io_respInfo_13_bits_reqID),
    .io_respInfo_13_bits_w_snpRsp(io_respInfo_13_bits_w_snpRsp),
    .io_respInfo_13_bits_w_compdata(io_respInfo_13_bits_w_compdata),
    .io_respInfo_14_valid(io_respInfo_14_valid),
    .io_respInfo_14_bits_opcode(io_respInfo_14_bits_opcode),
    .io_respInfo_14_bits_reqID(io_respInfo_14_bits_reqID),
    .io_respInfo_14_bits_w_snpRsp(io_respInfo_14_bits_w_snpRsp),
    .io_respInfo_14_bits_w_compdata(io_respInfo_14_bits_w_compdata),
    .io_respInfo_15_valid(io_respInfo_15_valid),
    .io_respInfo_15_bits_opcode(io_respInfo_15_bits_opcode),
    .io_respInfo_15_bits_reqID(io_respInfo_15_bits_reqID),
    .io_respInfo_15_bits_w_snpRsp(io_respInfo_15_bits_w_snpRsp),
    .io_respInfo_15_bits_w_compdata(io_respInfo_15_bits_w_compdata),
    .io_urgentRead_ready(g_io_urgentRead_ready),
    .io_txreq_valid(g_io_txreq_valid),
    .io_txreq_bits_set(g_io_txreq_bits_set),
    .io_txreq_bits_bank(g_io_txreq_bits_bank),
    .io_txreq_bits_tag(g_io_txreq_bits_tag),
    .io_txreq_bits_size(g_io_txreq_bits_size),
    .io_txreq_bits_tgtID(g_io_txreq_bits_tgtID),
    .io_txreq_bits_srcID(g_io_txreq_bits_srcID),
    .io_txreq_bits_txnID(g_io_txreq_bits_txnID),
    .io_txreq_bits_chiOpcode(g_io_txreq_bits_chiOpcode),
    .io_txreq_bits_pCrdType(g_io_txreq_bits_pCrdType),
    .io_txreq_bits_expCompAck(g_io_txreq_bits_expCompAck),
    .io_txreq_bits_allowRetry(g_io_txreq_bits_allowRetry),
    .io_txreq_bits_order(g_io_txreq_bits_order),
    .io_txreq_bits_memAttr_allocate(g_io_txreq_bits_memAttr_allocate),
    .io_txreq_bits_memAttr_cacheable(g_io_txreq_bits_memAttr_cacheable),
    .io_txreq_bits_memAttr_device(g_io_txreq_bits_memAttr_device),
    .io_txreq_bits_memAttr_ewa(g_io_txreq_bits_memAttr_ewa),
    .io_txreq_bits_snpAttr(g_io_txreq_bits_snpAttr),
    .io_txdat_valid(g_io_txdat_valid),
    .io_txdat_bits_task_tgtID(g_io_txdat_bits_task_tgtID),
    .io_txdat_bits_task_srcID(g_io_txdat_bits_task_srcID),
    .io_txdat_bits_task_txnID(g_io_txdat_bits_task_txnID),
    .io_txdat_bits_task_homeNID(g_io_txdat_bits_task_homeNID),
    .io_txdat_bits_task_dbID(g_io_txdat_bits_task_dbID),
    .io_txdat_bits_task_resp(g_io_txdat_bits_task_resp),
    .io_txdat_bits_task_fwdState(g_io_txdat_bits_task_fwdState),
    .io_txdat_bits_data_data_0_data(g_io_txdat_bits_data_data_0_data),
    .io_txdat_bits_data_data_1_data(g_io_txdat_bits_data_data_1_data),
    .io_bypassData_0_valid(g_io_bypassData_0_valid),
    .io_bypassData_0_bits_txnID(g_io_bypassData_0_bits_txnID),
    .io_bypassData_0_bits_opcode(g_io_bypassData_0_bits_opcode),
    .io_bypassData_0_bits_data_data(g_io_bypassData_0_bits_data_data),
    .io_bypassData_1_valid(g_io_bypassData_1_valid),
    .io_bypassData_1_bits_txnID(g_io_bypassData_1_bits_txnID),
    .io_bypassData_1_bits_opcode(g_io_bypassData_1_bits_opcode),
    .io_bypassData_1_bits_dataID(g_io_bypassData_1_bits_dataID),
    .io_bypassData_1_bits_data_data(g_io_bypassData_1_bits_data_data),
    .io_memInfo_0_valid(g_io_memInfo_0_valid),
    .io_memInfo_0_bits_set(g_io_memInfo_0_bits_set),
    .io_memInfo_0_bits_tag(g_io_memInfo_0_bits_tag),
    .io_memInfo_0_bits_opcode(g_io_memInfo_0_bits_opcode),
    .io_memInfo_0_bits_reqID(g_io_memInfo_0_bits_reqID),
    .io_memInfo_0_bits_w_datRsp(g_io_memInfo_0_bits_w_datRsp),
    .io_memInfo_1_valid(g_io_memInfo_1_valid),
    .io_memInfo_1_bits_set(g_io_memInfo_1_bits_set),
    .io_memInfo_1_bits_tag(g_io_memInfo_1_bits_tag),
    .io_memInfo_1_bits_opcode(g_io_memInfo_1_bits_opcode),
    .io_memInfo_1_bits_reqID(g_io_memInfo_1_bits_reqID),
    .io_memInfo_1_bits_w_datRsp(g_io_memInfo_1_bits_w_datRsp),
    .io_memInfo_2_valid(g_io_memInfo_2_valid),
    .io_memInfo_2_bits_set(g_io_memInfo_2_bits_set),
    .io_memInfo_2_bits_tag(g_io_memInfo_2_bits_tag),
    .io_memInfo_2_bits_opcode(g_io_memInfo_2_bits_opcode),
    .io_memInfo_2_bits_reqID(g_io_memInfo_2_bits_reqID),
    .io_memInfo_2_bits_w_datRsp(g_io_memInfo_2_bits_w_datRsp),
    .io_memInfo_3_valid(g_io_memInfo_3_valid),
    .io_memInfo_3_bits_set(g_io_memInfo_3_bits_set),
    .io_memInfo_3_bits_tag(g_io_memInfo_3_bits_tag),
    .io_memInfo_3_bits_opcode(g_io_memInfo_3_bits_opcode),
    .io_memInfo_3_bits_reqID(g_io_memInfo_3_bits_reqID),
    .io_memInfo_3_bits_w_datRsp(g_io_memInfo_3_bits_w_datRsp),
    .io_memInfo_4_valid(g_io_memInfo_4_valid),
    .io_memInfo_4_bits_set(g_io_memInfo_4_bits_set),
    .io_memInfo_4_bits_tag(g_io_memInfo_4_bits_tag),
    .io_memInfo_4_bits_opcode(g_io_memInfo_4_bits_opcode),
    .io_memInfo_4_bits_reqID(g_io_memInfo_4_bits_reqID),
    .io_memInfo_4_bits_w_datRsp(g_io_memInfo_4_bits_w_datRsp),
    .io_memInfo_5_valid(g_io_memInfo_5_valid),
    .io_memInfo_5_bits_set(g_io_memInfo_5_bits_set),
    .io_memInfo_5_bits_tag(g_io_memInfo_5_bits_tag),
    .io_memInfo_5_bits_opcode(g_io_memInfo_5_bits_opcode),
    .io_memInfo_5_bits_reqID(g_io_memInfo_5_bits_reqID),
    .io_memInfo_5_bits_w_datRsp(g_io_memInfo_5_bits_w_datRsp),
    .io_memInfo_6_valid(g_io_memInfo_6_valid),
    .io_memInfo_6_bits_set(g_io_memInfo_6_bits_set),
    .io_memInfo_6_bits_tag(g_io_memInfo_6_bits_tag),
    .io_memInfo_6_bits_opcode(g_io_memInfo_6_bits_opcode),
    .io_memInfo_6_bits_reqID(g_io_memInfo_6_bits_reqID),
    .io_memInfo_6_bits_w_datRsp(g_io_memInfo_6_bits_w_datRsp),
    .io_memInfo_7_valid(g_io_memInfo_7_valid),
    .io_memInfo_7_bits_set(g_io_memInfo_7_bits_set),
    .io_memInfo_7_bits_tag(g_io_memInfo_7_bits_tag),
    .io_memInfo_7_bits_opcode(g_io_memInfo_7_bits_opcode),
    .io_memInfo_7_bits_reqID(g_io_memInfo_7_bits_reqID),
    .io_memInfo_7_bits_w_datRsp(g_io_memInfo_7_bits_w_datRsp),
    .io_memInfo_8_valid(g_io_memInfo_8_valid),
    .io_memInfo_8_bits_set(g_io_memInfo_8_bits_set),
    .io_memInfo_8_bits_tag(g_io_memInfo_8_bits_tag),
    .io_memInfo_8_bits_opcode(g_io_memInfo_8_bits_opcode),
    .io_memInfo_8_bits_reqID(g_io_memInfo_8_bits_reqID),
    .io_memInfo_8_bits_w_datRsp(g_io_memInfo_8_bits_w_datRsp),
    .io_memInfo_9_valid(g_io_memInfo_9_valid),
    .io_memInfo_9_bits_set(g_io_memInfo_9_bits_set),
    .io_memInfo_9_bits_tag(g_io_memInfo_9_bits_tag),
    .io_memInfo_9_bits_opcode(g_io_memInfo_9_bits_opcode),
    .io_memInfo_9_bits_reqID(g_io_memInfo_9_bits_reqID),
    .io_memInfo_9_bits_w_datRsp(g_io_memInfo_9_bits_w_datRsp),
    .io_memInfo_10_valid(g_io_memInfo_10_valid),
    .io_memInfo_10_bits_set(g_io_memInfo_10_bits_set),
    .io_memInfo_10_bits_tag(g_io_memInfo_10_bits_tag),
    .io_memInfo_10_bits_opcode(g_io_memInfo_10_bits_opcode),
    .io_memInfo_10_bits_reqID(g_io_memInfo_10_bits_reqID),
    .io_memInfo_10_bits_w_datRsp(g_io_memInfo_10_bits_w_datRsp),
    .io_memInfo_11_valid(g_io_memInfo_11_valid),
    .io_memInfo_11_bits_set(g_io_memInfo_11_bits_set),
    .io_memInfo_11_bits_tag(g_io_memInfo_11_bits_tag),
    .io_memInfo_11_bits_opcode(g_io_memInfo_11_bits_opcode),
    .io_memInfo_11_bits_reqID(g_io_memInfo_11_bits_reqID),
    .io_memInfo_11_bits_w_datRsp(g_io_memInfo_11_bits_w_datRsp),
    .io_memInfo_12_valid(g_io_memInfo_12_valid),
    .io_memInfo_12_bits_set(g_io_memInfo_12_bits_set),
    .io_memInfo_12_bits_tag(g_io_memInfo_12_bits_tag),
    .io_memInfo_12_bits_opcode(g_io_memInfo_12_bits_opcode),
    .io_memInfo_12_bits_reqID(g_io_memInfo_12_bits_reqID),
    .io_memInfo_12_bits_w_datRsp(g_io_memInfo_12_bits_w_datRsp),
    .io_memInfo_13_valid(g_io_memInfo_13_valid),
    .io_memInfo_13_bits_set(g_io_memInfo_13_bits_set),
    .io_memInfo_13_bits_tag(g_io_memInfo_13_bits_tag),
    .io_memInfo_13_bits_opcode(g_io_memInfo_13_bits_opcode),
    .io_memInfo_13_bits_reqID(g_io_memInfo_13_bits_reqID),
    .io_memInfo_13_bits_w_datRsp(g_io_memInfo_13_bits_w_datRsp),
    .io_memInfo_14_valid(g_io_memInfo_14_valid),
    .io_memInfo_14_bits_set(g_io_memInfo_14_bits_set),
    .io_memInfo_14_bits_tag(g_io_memInfo_14_bits_tag),
    .io_memInfo_14_bits_opcode(g_io_memInfo_14_bits_opcode),
    .io_memInfo_14_bits_reqID(g_io_memInfo_14_bits_reqID),
    .io_memInfo_14_bits_w_datRsp(g_io_memInfo_14_bits_w_datRsp),
    .io_memInfo_15_valid(g_io_memInfo_15_valid),
    .io_memInfo_15_bits_set(g_io_memInfo_15_bits_set),
    .io_memInfo_15_bits_tag(g_io_memInfo_15_bits_tag),
    .io_memInfo_15_bits_opcode(g_io_memInfo_15_bits_opcode),
    .io_memInfo_15_bits_reqID(g_io_memInfo_15_bits_reqID),
    .io_memInfo_15_bits_w_datRsp(g_io_memInfo_15_bits_w_datRsp)
  );

  MemUnit_xs dut_i (
    .clock(clk), .reset(rst),
    .io_fromMainPipe_alloc_s4_valid(io_fromMainPipe_alloc_s4_valid),
    .io_fromMainPipe_alloc_s4_bits_state_s_issueDat(io_fromMainPipe_alloc_s4_bits_state_s_issueDat),
    .io_fromMainPipe_alloc_s4_bits_state_w_datRsp(io_fromMainPipe_alloc_s4_bits_state_w_datRsp),
    .io_fromMainPipe_alloc_s4_bits_state_w_dbid(io_fromMainPipe_alloc_s4_bits_state_w_dbid),
    .io_fromMainPipe_alloc_s4_bits_state_w_comp(io_fromMainPipe_alloc_s4_bits_state_w_comp),
    .io_fromMainPipe_alloc_s4_bits_task_set(io_fromMainPipe_alloc_s4_bits_task_set),
    .io_fromMainPipe_alloc_s4_bits_task_bank(io_fromMainPipe_alloc_s4_bits_task_bank),
    .io_fromMainPipe_alloc_s4_bits_task_tag(io_fromMainPipe_alloc_s4_bits_task_tag),
    .io_fromMainPipe_alloc_s4_bits_task_off(io_fromMainPipe_alloc_s4_bits_task_off),
    .io_fromMainPipe_alloc_s4_bits_task_refillTask(io_fromMainPipe_alloc_s4_bits_task_refillTask),
    .io_fromMainPipe_alloc_s4_bits_task_bufID(io_fromMainPipe_alloc_s4_bits_task_bufID),
    .io_fromMainPipe_alloc_s4_bits_task_reqID(io_fromMainPipe_alloc_s4_bits_task_reqID),
    .io_fromMainPipe_alloc_s4_bits_task_replSnp(io_fromMainPipe_alloc_s4_bits_task_replSnp),
    .io_fromMainPipe_alloc_s4_bits_task_snpVec_0(io_fromMainPipe_alloc_s4_bits_task_snpVec_0),
    .io_fromMainPipe_alloc_s4_bits_task_tgtID(io_fromMainPipe_alloc_s4_bits_task_tgtID),
    .io_fromMainPipe_alloc_s4_bits_task_srcID(io_fromMainPipe_alloc_s4_bits_task_srcID),
    .io_fromMainPipe_alloc_s4_bits_task_txnID(io_fromMainPipe_alloc_s4_bits_task_txnID),
    .io_fromMainPipe_alloc_s4_bits_task_homeNID(io_fromMainPipe_alloc_s4_bits_task_homeNID),
    .io_fromMainPipe_alloc_s4_bits_task_dbID(io_fromMainPipe_alloc_s4_bits_task_dbID),
    .io_fromMainPipe_alloc_s4_bits_task_fwdNID(io_fromMainPipe_alloc_s4_bits_task_fwdNID),
    .io_fromMainPipe_alloc_s4_bits_task_fwdTxnID(io_fromMainPipe_alloc_s4_bits_task_fwdTxnID),
    .io_fromMainPipe_alloc_s4_bits_task_chiOpcode(io_fromMainPipe_alloc_s4_bits_task_chiOpcode),
    .io_fromMainPipe_alloc_s4_bits_task_resp(io_fromMainPipe_alloc_s4_bits_task_resp),
    .io_fromMainPipe_alloc_s4_bits_task_fwdState(io_fromMainPipe_alloc_s4_bits_task_fwdState),
    .io_fromMainPipe_alloc_s4_bits_task_pCrdType(io_fromMainPipe_alloc_s4_bits_task_pCrdType),
    .io_fromMainPipe_alloc_s4_bits_task_retToSrc(io_fromMainPipe_alloc_s4_bits_task_retToSrc),
    .io_fromMainPipe_alloc_s4_bits_task_doNotGoToSD(io_fromMainPipe_alloc_s4_bits_task_doNotGoToSD),
    .io_fromMainPipe_alloc_s6_valid(io_fromMainPipe_alloc_s6_valid),
    .io_fromMainPipe_alloc_s6_bits_task_set(io_fromMainPipe_alloc_s6_bits_task_set),
    .io_fromMainPipe_alloc_s6_bits_task_bank(io_fromMainPipe_alloc_s6_bits_task_bank),
    .io_fromMainPipe_alloc_s6_bits_task_tag(io_fromMainPipe_alloc_s6_bits_task_tag),
    .io_fromMainPipe_alloc_s6_bits_task_off(io_fromMainPipe_alloc_s6_bits_task_off),
    .io_fromMainPipe_alloc_s6_bits_task_size(io_fromMainPipe_alloc_s6_bits_task_size),
    .io_fromMainPipe_alloc_s6_bits_task_refillTask(io_fromMainPipe_alloc_s6_bits_task_refillTask),
    .io_fromMainPipe_alloc_s6_bits_task_bufID(io_fromMainPipe_alloc_s6_bits_task_bufID),
    .io_fromMainPipe_alloc_s6_bits_task_reqID(io_fromMainPipe_alloc_s6_bits_task_reqID),
    .io_fromMainPipe_alloc_s6_bits_task_replSnp(io_fromMainPipe_alloc_s6_bits_task_replSnp),
    .io_fromMainPipe_alloc_s6_bits_task_snpVec_0(io_fromMainPipe_alloc_s6_bits_task_snpVec_0),
    .io_fromMainPipe_alloc_s6_bits_task_tgtID(io_fromMainPipe_alloc_s6_bits_task_tgtID),
    .io_fromMainPipe_alloc_s6_bits_task_srcID(io_fromMainPipe_alloc_s6_bits_task_srcID),
    .io_fromMainPipe_alloc_s6_bits_task_txnID(io_fromMainPipe_alloc_s6_bits_task_txnID),
    .io_fromMainPipe_alloc_s6_bits_task_homeNID(io_fromMainPipe_alloc_s6_bits_task_homeNID),
    .io_fromMainPipe_alloc_s6_bits_task_dbID(io_fromMainPipe_alloc_s6_bits_task_dbID),
    .io_fromMainPipe_alloc_s6_bits_task_fwdNID(io_fromMainPipe_alloc_s6_bits_task_fwdNID),
    .io_fromMainPipe_alloc_s6_bits_task_fwdTxnID(io_fromMainPipe_alloc_s6_bits_task_fwdTxnID),
    .io_fromMainPipe_alloc_s6_bits_task_chiOpcode(io_fromMainPipe_alloc_s6_bits_task_chiOpcode),
    .io_fromMainPipe_alloc_s6_bits_task_resp(io_fromMainPipe_alloc_s6_bits_task_resp),
    .io_fromMainPipe_alloc_s6_bits_task_fwdState(io_fromMainPipe_alloc_s6_bits_task_fwdState),
    .io_fromMainPipe_alloc_s6_bits_task_pCrdType(io_fromMainPipe_alloc_s6_bits_task_pCrdType),
    .io_fromMainPipe_alloc_s6_bits_task_retToSrc(io_fromMainPipe_alloc_s6_bits_task_retToSrc),
    .io_fromMainPipe_alloc_s6_bits_task_doNotGoToSD(io_fromMainPipe_alloc_s6_bits_task_doNotGoToSD),
    .io_fromMainPipe_alloc_s6_bits_task_expCompAck(io_fromMainPipe_alloc_s6_bits_task_expCompAck),
    .io_fromMainPipe_alloc_s6_bits_task_allowRetry(io_fromMainPipe_alloc_s6_bits_task_allowRetry),
    .io_fromMainPipe_alloc_s6_bits_task_order(io_fromMainPipe_alloc_s6_bits_task_order),
    .io_fromMainPipe_alloc_s6_bits_task_memAttr_allocate(io_fromMainPipe_alloc_s6_bits_task_memAttr_allocate),
    .io_fromMainPipe_alloc_s6_bits_task_memAttr_cacheable(io_fromMainPipe_alloc_s6_bits_task_memAttr_cacheable),
    .io_fromMainPipe_alloc_s6_bits_task_memAttr_device(io_fromMainPipe_alloc_s6_bits_task_memAttr_device),
    .io_fromMainPipe_alloc_s6_bits_task_memAttr_ewa(io_fromMainPipe_alloc_s6_bits_task_memAttr_ewa),
    .io_fromMainPipe_alloc_s6_bits_task_snpAttr(io_fromMainPipe_alloc_s6_bits_task_snpAttr),
    .io_fromMainPipe_alloc_s6_bits_data_data_0_data(io_fromMainPipe_alloc_s6_bits_data_data_0_data),
    .io_fromMainPipe_alloc_s6_bits_data_data_1_data(io_fromMainPipe_alloc_s6_bits_data_data_1_data),
    .io_urgentRead_valid(io_urgentRead_valid),
    .io_urgentRead_bits_set(io_urgentRead_bits_set),
    .io_urgentRead_bits_bank(io_urgentRead_bits_bank),
    .io_urgentRead_bits_tag(io_urgentRead_bits_tag),
    .io_urgentRead_bits_tgtID(io_urgentRead_bits_tgtID),
    .io_urgentRead_bits_srcID(io_urgentRead_bits_srcID),
    .io_urgentRead_bits_txnID(io_urgentRead_bits_txnID),
    .io_urgentRead_bits_pCrdType(io_urgentRead_bits_pCrdType),
    .io_snRxrsp_valid(io_snRxrsp_valid),
    .io_snRxrsp_bits_txnID(io_snRxrsp_bits_txnID),
    .io_snRxrsp_bits_dbID(io_snRxrsp_bits_dbID),
    .io_snRxrsp_bits_opcode(io_snRxrsp_bits_opcode),
    .io_rnRxdat_valid(io_rnRxdat_valid),
    .io_rnRxdat_bits_txnID(io_rnRxdat_bits_txnID),
    .io_rnRxdat_bits_resp(io_rnRxdat_bits_resp),
    .io_rnRxdat_bits_dataID(io_rnRxdat_bits_dataID),
    .io_rnRxdat_bits_data_data(io_rnRxdat_bits_data_data),
    .io_rnRxrsp_valid(io_rnRxrsp_valid),
    .io_rnRxrsp_bits_txnID(io_rnRxrsp_bits_txnID),
    .io_txreq_ready(io_txreq_ready),
    .io_txdat_ready(io_txdat_ready),
    .io_respInfo_0_valid(io_respInfo_0_valid),
    .io_respInfo_0_bits_opcode(io_respInfo_0_bits_opcode),
    .io_respInfo_0_bits_reqID(io_respInfo_0_bits_reqID),
    .io_respInfo_0_bits_w_snpRsp(io_respInfo_0_bits_w_snpRsp),
    .io_respInfo_0_bits_w_compdata(io_respInfo_0_bits_w_compdata),
    .io_respInfo_1_valid(io_respInfo_1_valid),
    .io_respInfo_1_bits_opcode(io_respInfo_1_bits_opcode),
    .io_respInfo_1_bits_reqID(io_respInfo_1_bits_reqID),
    .io_respInfo_1_bits_w_snpRsp(io_respInfo_1_bits_w_snpRsp),
    .io_respInfo_1_bits_w_compdata(io_respInfo_1_bits_w_compdata),
    .io_respInfo_2_valid(io_respInfo_2_valid),
    .io_respInfo_2_bits_opcode(io_respInfo_2_bits_opcode),
    .io_respInfo_2_bits_reqID(io_respInfo_2_bits_reqID),
    .io_respInfo_2_bits_w_snpRsp(io_respInfo_2_bits_w_snpRsp),
    .io_respInfo_2_bits_w_compdata(io_respInfo_2_bits_w_compdata),
    .io_respInfo_3_valid(io_respInfo_3_valid),
    .io_respInfo_3_bits_opcode(io_respInfo_3_bits_opcode),
    .io_respInfo_3_bits_reqID(io_respInfo_3_bits_reqID),
    .io_respInfo_3_bits_w_snpRsp(io_respInfo_3_bits_w_snpRsp),
    .io_respInfo_3_bits_w_compdata(io_respInfo_3_bits_w_compdata),
    .io_respInfo_4_valid(io_respInfo_4_valid),
    .io_respInfo_4_bits_opcode(io_respInfo_4_bits_opcode),
    .io_respInfo_4_bits_reqID(io_respInfo_4_bits_reqID),
    .io_respInfo_4_bits_w_snpRsp(io_respInfo_4_bits_w_snpRsp),
    .io_respInfo_4_bits_w_compdata(io_respInfo_4_bits_w_compdata),
    .io_respInfo_5_valid(io_respInfo_5_valid),
    .io_respInfo_5_bits_opcode(io_respInfo_5_bits_opcode),
    .io_respInfo_5_bits_reqID(io_respInfo_5_bits_reqID),
    .io_respInfo_5_bits_w_snpRsp(io_respInfo_5_bits_w_snpRsp),
    .io_respInfo_5_bits_w_compdata(io_respInfo_5_bits_w_compdata),
    .io_respInfo_6_valid(io_respInfo_6_valid),
    .io_respInfo_6_bits_opcode(io_respInfo_6_bits_opcode),
    .io_respInfo_6_bits_reqID(io_respInfo_6_bits_reqID),
    .io_respInfo_6_bits_w_snpRsp(io_respInfo_6_bits_w_snpRsp),
    .io_respInfo_6_bits_w_compdata(io_respInfo_6_bits_w_compdata),
    .io_respInfo_7_valid(io_respInfo_7_valid),
    .io_respInfo_7_bits_opcode(io_respInfo_7_bits_opcode),
    .io_respInfo_7_bits_reqID(io_respInfo_7_bits_reqID),
    .io_respInfo_7_bits_w_snpRsp(io_respInfo_7_bits_w_snpRsp),
    .io_respInfo_7_bits_w_compdata(io_respInfo_7_bits_w_compdata),
    .io_respInfo_8_valid(io_respInfo_8_valid),
    .io_respInfo_8_bits_opcode(io_respInfo_8_bits_opcode),
    .io_respInfo_8_bits_reqID(io_respInfo_8_bits_reqID),
    .io_respInfo_8_bits_w_snpRsp(io_respInfo_8_bits_w_snpRsp),
    .io_respInfo_8_bits_w_compdata(io_respInfo_8_bits_w_compdata),
    .io_respInfo_9_valid(io_respInfo_9_valid),
    .io_respInfo_9_bits_opcode(io_respInfo_9_bits_opcode),
    .io_respInfo_9_bits_reqID(io_respInfo_9_bits_reqID),
    .io_respInfo_9_bits_w_snpRsp(io_respInfo_9_bits_w_snpRsp),
    .io_respInfo_9_bits_w_compdata(io_respInfo_9_bits_w_compdata),
    .io_respInfo_10_valid(io_respInfo_10_valid),
    .io_respInfo_10_bits_opcode(io_respInfo_10_bits_opcode),
    .io_respInfo_10_bits_reqID(io_respInfo_10_bits_reqID),
    .io_respInfo_10_bits_w_snpRsp(io_respInfo_10_bits_w_snpRsp),
    .io_respInfo_10_bits_w_compdata(io_respInfo_10_bits_w_compdata),
    .io_respInfo_11_valid(io_respInfo_11_valid),
    .io_respInfo_11_bits_opcode(io_respInfo_11_bits_opcode),
    .io_respInfo_11_bits_reqID(io_respInfo_11_bits_reqID),
    .io_respInfo_11_bits_w_snpRsp(io_respInfo_11_bits_w_snpRsp),
    .io_respInfo_11_bits_w_compdata(io_respInfo_11_bits_w_compdata),
    .io_respInfo_12_valid(io_respInfo_12_valid),
    .io_respInfo_12_bits_opcode(io_respInfo_12_bits_opcode),
    .io_respInfo_12_bits_reqID(io_respInfo_12_bits_reqID),
    .io_respInfo_12_bits_w_snpRsp(io_respInfo_12_bits_w_snpRsp),
    .io_respInfo_12_bits_w_compdata(io_respInfo_12_bits_w_compdata),
    .io_respInfo_13_valid(io_respInfo_13_valid),
    .io_respInfo_13_bits_opcode(io_respInfo_13_bits_opcode),
    .io_respInfo_13_bits_reqID(io_respInfo_13_bits_reqID),
    .io_respInfo_13_bits_w_snpRsp(io_respInfo_13_bits_w_snpRsp),
    .io_respInfo_13_bits_w_compdata(io_respInfo_13_bits_w_compdata),
    .io_respInfo_14_valid(io_respInfo_14_valid),
    .io_respInfo_14_bits_opcode(io_respInfo_14_bits_opcode),
    .io_respInfo_14_bits_reqID(io_respInfo_14_bits_reqID),
    .io_respInfo_14_bits_w_snpRsp(io_respInfo_14_bits_w_snpRsp),
    .io_respInfo_14_bits_w_compdata(io_respInfo_14_bits_w_compdata),
    .io_respInfo_15_valid(io_respInfo_15_valid),
    .io_respInfo_15_bits_opcode(io_respInfo_15_bits_opcode),
    .io_respInfo_15_bits_reqID(io_respInfo_15_bits_reqID),
    .io_respInfo_15_bits_w_snpRsp(io_respInfo_15_bits_w_snpRsp),
    .io_respInfo_15_bits_w_compdata(io_respInfo_15_bits_w_compdata),
    .io_urgentRead_ready(i_io_urgentRead_ready),
    .io_txreq_valid(i_io_txreq_valid),
    .io_txreq_bits_set(i_io_txreq_bits_set),
    .io_txreq_bits_bank(i_io_txreq_bits_bank),
    .io_txreq_bits_tag(i_io_txreq_bits_tag),
    .io_txreq_bits_size(i_io_txreq_bits_size),
    .io_txreq_bits_tgtID(i_io_txreq_bits_tgtID),
    .io_txreq_bits_srcID(i_io_txreq_bits_srcID),
    .io_txreq_bits_txnID(i_io_txreq_bits_txnID),
    .io_txreq_bits_chiOpcode(i_io_txreq_bits_chiOpcode),
    .io_txreq_bits_pCrdType(i_io_txreq_bits_pCrdType),
    .io_txreq_bits_expCompAck(i_io_txreq_bits_expCompAck),
    .io_txreq_bits_allowRetry(i_io_txreq_bits_allowRetry),
    .io_txreq_bits_order(i_io_txreq_bits_order),
    .io_txreq_bits_memAttr_allocate(i_io_txreq_bits_memAttr_allocate),
    .io_txreq_bits_memAttr_cacheable(i_io_txreq_bits_memAttr_cacheable),
    .io_txreq_bits_memAttr_device(i_io_txreq_bits_memAttr_device),
    .io_txreq_bits_memAttr_ewa(i_io_txreq_bits_memAttr_ewa),
    .io_txreq_bits_snpAttr(i_io_txreq_bits_snpAttr),
    .io_txdat_valid(i_io_txdat_valid),
    .io_txdat_bits_task_tgtID(i_io_txdat_bits_task_tgtID),
    .io_txdat_bits_task_srcID(i_io_txdat_bits_task_srcID),
    .io_txdat_bits_task_txnID(i_io_txdat_bits_task_txnID),
    .io_txdat_bits_task_homeNID(i_io_txdat_bits_task_homeNID),
    .io_txdat_bits_task_dbID(i_io_txdat_bits_task_dbID),
    .io_txdat_bits_task_resp(i_io_txdat_bits_task_resp),
    .io_txdat_bits_task_fwdState(i_io_txdat_bits_task_fwdState),
    .io_txdat_bits_data_data_0_data(i_io_txdat_bits_data_data_0_data),
    .io_txdat_bits_data_data_1_data(i_io_txdat_bits_data_data_1_data),
    .io_bypassData_0_valid(i_io_bypassData_0_valid),
    .io_bypassData_0_bits_txnID(i_io_bypassData_0_bits_txnID),
    .io_bypassData_0_bits_opcode(i_io_bypassData_0_bits_opcode),
    .io_bypassData_0_bits_data_data(i_io_bypassData_0_bits_data_data),
    .io_bypassData_1_valid(i_io_bypassData_1_valid),
    .io_bypassData_1_bits_txnID(i_io_bypassData_1_bits_txnID),
    .io_bypassData_1_bits_opcode(i_io_bypassData_1_bits_opcode),
    .io_bypassData_1_bits_dataID(i_io_bypassData_1_bits_dataID),
    .io_bypassData_1_bits_data_data(i_io_bypassData_1_bits_data_data),
    .io_memInfo_0_valid(i_io_memInfo_0_valid),
    .io_memInfo_0_bits_set(i_io_memInfo_0_bits_set),
    .io_memInfo_0_bits_tag(i_io_memInfo_0_bits_tag),
    .io_memInfo_0_bits_opcode(i_io_memInfo_0_bits_opcode),
    .io_memInfo_0_bits_reqID(i_io_memInfo_0_bits_reqID),
    .io_memInfo_0_bits_w_datRsp(i_io_memInfo_0_bits_w_datRsp),
    .io_memInfo_1_valid(i_io_memInfo_1_valid),
    .io_memInfo_1_bits_set(i_io_memInfo_1_bits_set),
    .io_memInfo_1_bits_tag(i_io_memInfo_1_bits_tag),
    .io_memInfo_1_bits_opcode(i_io_memInfo_1_bits_opcode),
    .io_memInfo_1_bits_reqID(i_io_memInfo_1_bits_reqID),
    .io_memInfo_1_bits_w_datRsp(i_io_memInfo_1_bits_w_datRsp),
    .io_memInfo_2_valid(i_io_memInfo_2_valid),
    .io_memInfo_2_bits_set(i_io_memInfo_2_bits_set),
    .io_memInfo_2_bits_tag(i_io_memInfo_2_bits_tag),
    .io_memInfo_2_bits_opcode(i_io_memInfo_2_bits_opcode),
    .io_memInfo_2_bits_reqID(i_io_memInfo_2_bits_reqID),
    .io_memInfo_2_bits_w_datRsp(i_io_memInfo_2_bits_w_datRsp),
    .io_memInfo_3_valid(i_io_memInfo_3_valid),
    .io_memInfo_3_bits_set(i_io_memInfo_3_bits_set),
    .io_memInfo_3_bits_tag(i_io_memInfo_3_bits_tag),
    .io_memInfo_3_bits_opcode(i_io_memInfo_3_bits_opcode),
    .io_memInfo_3_bits_reqID(i_io_memInfo_3_bits_reqID),
    .io_memInfo_3_bits_w_datRsp(i_io_memInfo_3_bits_w_datRsp),
    .io_memInfo_4_valid(i_io_memInfo_4_valid),
    .io_memInfo_4_bits_set(i_io_memInfo_4_bits_set),
    .io_memInfo_4_bits_tag(i_io_memInfo_4_bits_tag),
    .io_memInfo_4_bits_opcode(i_io_memInfo_4_bits_opcode),
    .io_memInfo_4_bits_reqID(i_io_memInfo_4_bits_reqID),
    .io_memInfo_4_bits_w_datRsp(i_io_memInfo_4_bits_w_datRsp),
    .io_memInfo_5_valid(i_io_memInfo_5_valid),
    .io_memInfo_5_bits_set(i_io_memInfo_5_bits_set),
    .io_memInfo_5_bits_tag(i_io_memInfo_5_bits_tag),
    .io_memInfo_5_bits_opcode(i_io_memInfo_5_bits_opcode),
    .io_memInfo_5_bits_reqID(i_io_memInfo_5_bits_reqID),
    .io_memInfo_5_bits_w_datRsp(i_io_memInfo_5_bits_w_datRsp),
    .io_memInfo_6_valid(i_io_memInfo_6_valid),
    .io_memInfo_6_bits_set(i_io_memInfo_6_bits_set),
    .io_memInfo_6_bits_tag(i_io_memInfo_6_bits_tag),
    .io_memInfo_6_bits_opcode(i_io_memInfo_6_bits_opcode),
    .io_memInfo_6_bits_reqID(i_io_memInfo_6_bits_reqID),
    .io_memInfo_6_bits_w_datRsp(i_io_memInfo_6_bits_w_datRsp),
    .io_memInfo_7_valid(i_io_memInfo_7_valid),
    .io_memInfo_7_bits_set(i_io_memInfo_7_bits_set),
    .io_memInfo_7_bits_tag(i_io_memInfo_7_bits_tag),
    .io_memInfo_7_bits_opcode(i_io_memInfo_7_bits_opcode),
    .io_memInfo_7_bits_reqID(i_io_memInfo_7_bits_reqID),
    .io_memInfo_7_bits_w_datRsp(i_io_memInfo_7_bits_w_datRsp),
    .io_memInfo_8_valid(i_io_memInfo_8_valid),
    .io_memInfo_8_bits_set(i_io_memInfo_8_bits_set),
    .io_memInfo_8_bits_tag(i_io_memInfo_8_bits_tag),
    .io_memInfo_8_bits_opcode(i_io_memInfo_8_bits_opcode),
    .io_memInfo_8_bits_reqID(i_io_memInfo_8_bits_reqID),
    .io_memInfo_8_bits_w_datRsp(i_io_memInfo_8_bits_w_datRsp),
    .io_memInfo_9_valid(i_io_memInfo_9_valid),
    .io_memInfo_9_bits_set(i_io_memInfo_9_bits_set),
    .io_memInfo_9_bits_tag(i_io_memInfo_9_bits_tag),
    .io_memInfo_9_bits_opcode(i_io_memInfo_9_bits_opcode),
    .io_memInfo_9_bits_reqID(i_io_memInfo_9_bits_reqID),
    .io_memInfo_9_bits_w_datRsp(i_io_memInfo_9_bits_w_datRsp),
    .io_memInfo_10_valid(i_io_memInfo_10_valid),
    .io_memInfo_10_bits_set(i_io_memInfo_10_bits_set),
    .io_memInfo_10_bits_tag(i_io_memInfo_10_bits_tag),
    .io_memInfo_10_bits_opcode(i_io_memInfo_10_bits_opcode),
    .io_memInfo_10_bits_reqID(i_io_memInfo_10_bits_reqID),
    .io_memInfo_10_bits_w_datRsp(i_io_memInfo_10_bits_w_datRsp),
    .io_memInfo_11_valid(i_io_memInfo_11_valid),
    .io_memInfo_11_bits_set(i_io_memInfo_11_bits_set),
    .io_memInfo_11_bits_tag(i_io_memInfo_11_bits_tag),
    .io_memInfo_11_bits_opcode(i_io_memInfo_11_bits_opcode),
    .io_memInfo_11_bits_reqID(i_io_memInfo_11_bits_reqID),
    .io_memInfo_11_bits_w_datRsp(i_io_memInfo_11_bits_w_datRsp),
    .io_memInfo_12_valid(i_io_memInfo_12_valid),
    .io_memInfo_12_bits_set(i_io_memInfo_12_bits_set),
    .io_memInfo_12_bits_tag(i_io_memInfo_12_bits_tag),
    .io_memInfo_12_bits_opcode(i_io_memInfo_12_bits_opcode),
    .io_memInfo_12_bits_reqID(i_io_memInfo_12_bits_reqID),
    .io_memInfo_12_bits_w_datRsp(i_io_memInfo_12_bits_w_datRsp),
    .io_memInfo_13_valid(i_io_memInfo_13_valid),
    .io_memInfo_13_bits_set(i_io_memInfo_13_bits_set),
    .io_memInfo_13_bits_tag(i_io_memInfo_13_bits_tag),
    .io_memInfo_13_bits_opcode(i_io_memInfo_13_bits_opcode),
    .io_memInfo_13_bits_reqID(i_io_memInfo_13_bits_reqID),
    .io_memInfo_13_bits_w_datRsp(i_io_memInfo_13_bits_w_datRsp),
    .io_memInfo_14_valid(i_io_memInfo_14_valid),
    .io_memInfo_14_bits_set(i_io_memInfo_14_bits_set),
    .io_memInfo_14_bits_tag(i_io_memInfo_14_bits_tag),
    .io_memInfo_14_bits_opcode(i_io_memInfo_14_bits_opcode),
    .io_memInfo_14_bits_reqID(i_io_memInfo_14_bits_reqID),
    .io_memInfo_14_bits_w_datRsp(i_io_memInfo_14_bits_w_datRsp),
    .io_memInfo_15_valid(i_io_memInfo_15_valid),
    .io_memInfo_15_bits_set(i_io_memInfo_15_bits_set),
    .io_memInfo_15_bits_tag(i_io_memInfo_15_bits_tag),
    .io_memInfo_15_bits_opcode(i_io_memInfo_15_bits_opcode),
    .io_memInfo_15_bits_reqID(i_io_memInfo_15_bits_reqID),
    .io_memInfo_15_bits_w_datRsp(i_io_memInfo_15_bits_w_datRsp)
  );

  task automatic drive_random();
    io_fromMainPipe_alloc_s4_valid = $random;
    io_fromMainPipe_alloc_s4_bits_state_s_issueDat = $random;
    io_fromMainPipe_alloc_s4_bits_state_w_datRsp = $random;
    io_fromMainPipe_alloc_s4_bits_state_w_dbid = $random;
    io_fromMainPipe_alloc_s4_bits_state_w_comp = $random;
    io_fromMainPipe_alloc_s4_bits_task_set = $random;
    io_fromMainPipe_alloc_s4_bits_task_bank = $random;
    io_fromMainPipe_alloc_s4_bits_task_tag = $random;
    io_fromMainPipe_alloc_s4_bits_task_off = $random;
    io_fromMainPipe_alloc_s4_bits_task_refillTask = $random;
    io_fromMainPipe_alloc_s4_bits_task_bufID = $random;
    io_fromMainPipe_alloc_s4_bits_task_reqID = $random;
    io_fromMainPipe_alloc_s4_bits_task_replSnp = $random;
    io_fromMainPipe_alloc_s4_bits_task_snpVec_0 = $random;
    io_fromMainPipe_alloc_s4_bits_task_tgtID = $random;
    io_fromMainPipe_alloc_s4_bits_task_srcID = $random;
    io_fromMainPipe_alloc_s4_bits_task_txnID = $random;
    io_fromMainPipe_alloc_s4_bits_task_homeNID = $random;
    io_fromMainPipe_alloc_s4_bits_task_dbID = $random;
    io_fromMainPipe_alloc_s4_bits_task_fwdNID = $random;
    io_fromMainPipe_alloc_s4_bits_task_fwdTxnID = $random;
    io_fromMainPipe_alloc_s4_bits_task_chiOpcode = $random;
    io_fromMainPipe_alloc_s4_bits_task_resp = $random;
    io_fromMainPipe_alloc_s4_bits_task_fwdState = $random;
    io_fromMainPipe_alloc_s4_bits_task_pCrdType = $random;
    io_fromMainPipe_alloc_s4_bits_task_retToSrc = $random;
    io_fromMainPipe_alloc_s4_bits_task_doNotGoToSD = $random;
    io_fromMainPipe_alloc_s6_valid = $random;
    io_fromMainPipe_alloc_s6_bits_task_set = $random;
    io_fromMainPipe_alloc_s6_bits_task_bank = $random;
    io_fromMainPipe_alloc_s6_bits_task_tag = $random;
    io_fromMainPipe_alloc_s6_bits_task_off = $random;
    io_fromMainPipe_alloc_s6_bits_task_size = $random;
    io_fromMainPipe_alloc_s6_bits_task_refillTask = $random;
    io_fromMainPipe_alloc_s6_bits_task_bufID = $random;
    io_fromMainPipe_alloc_s6_bits_task_reqID = $random;
    io_fromMainPipe_alloc_s6_bits_task_replSnp = $random;
    io_fromMainPipe_alloc_s6_bits_task_snpVec_0 = $random;
    io_fromMainPipe_alloc_s6_bits_task_tgtID = $random;
    io_fromMainPipe_alloc_s6_bits_task_srcID = $random;
    io_fromMainPipe_alloc_s6_bits_task_txnID = $random;
    io_fromMainPipe_alloc_s6_bits_task_homeNID = $random;
    io_fromMainPipe_alloc_s6_bits_task_dbID = $random;
    io_fromMainPipe_alloc_s6_bits_task_fwdNID = $random;
    io_fromMainPipe_alloc_s6_bits_task_fwdTxnID = $random;
    io_fromMainPipe_alloc_s6_bits_task_chiOpcode = $random;
    io_fromMainPipe_alloc_s6_bits_task_resp = $random;
    io_fromMainPipe_alloc_s6_bits_task_fwdState = $random;
    io_fromMainPipe_alloc_s6_bits_task_pCrdType = $random;
    io_fromMainPipe_alloc_s6_bits_task_retToSrc = $random;
    io_fromMainPipe_alloc_s6_bits_task_doNotGoToSD = $random;
    io_fromMainPipe_alloc_s6_bits_task_expCompAck = $random;
    io_fromMainPipe_alloc_s6_bits_task_allowRetry = $random;
    io_fromMainPipe_alloc_s6_bits_task_order = $random;
    io_fromMainPipe_alloc_s6_bits_task_memAttr_allocate = $random;
    io_fromMainPipe_alloc_s6_bits_task_memAttr_cacheable = $random;
    io_fromMainPipe_alloc_s6_bits_task_memAttr_device = $random;
    io_fromMainPipe_alloc_s6_bits_task_memAttr_ewa = $random;
    io_fromMainPipe_alloc_s6_bits_task_snpAttr = $random;
    io_fromMainPipe_alloc_s6_bits_data_data_0_data = {$random,$random,$random,$random,$random,$random,$random,$random};
    io_fromMainPipe_alloc_s6_bits_data_data_1_data = {$random,$random,$random,$random,$random,$random,$random,$random};
    io_urgentRead_valid = $random;
    io_urgentRead_bits_set = $random;
    io_urgentRead_bits_bank = $random;
    io_urgentRead_bits_tag = $random;
    io_urgentRead_bits_tgtID = $random;
    io_urgentRead_bits_srcID = $random;
    io_urgentRead_bits_txnID = $random;
    io_urgentRead_bits_pCrdType = $random;
    io_snRxrsp_valid = $random;
    io_snRxrsp_bits_txnID = $random;
    io_snRxrsp_bits_dbID = $random;
    io_snRxrsp_bits_opcode = $random;
    io_rnRxdat_valid = $random;
    io_rnRxdat_bits_txnID = $random;
    io_rnRxdat_bits_resp = $random;
    io_rnRxdat_bits_dataID = $random;
    io_rnRxdat_bits_data_data = {$random,$random,$random,$random,$random,$random,$random,$random};
    io_rnRxrsp_valid = $random;
    io_rnRxrsp_bits_txnID = $random;
    io_txreq_ready = $random;
    io_txdat_ready = $random;
    io_respInfo_0_valid = $random;
    io_respInfo_0_bits_opcode = $random;
    io_respInfo_0_bits_reqID = $random;
    io_respInfo_0_bits_w_snpRsp = $random;
    io_respInfo_0_bits_w_compdata = $random;
    io_respInfo_1_valid = $random;
    io_respInfo_1_bits_opcode = $random;
    io_respInfo_1_bits_reqID = $random;
    io_respInfo_1_bits_w_snpRsp = $random;
    io_respInfo_1_bits_w_compdata = $random;
    io_respInfo_2_valid = $random;
    io_respInfo_2_bits_opcode = $random;
    io_respInfo_2_bits_reqID = $random;
    io_respInfo_2_bits_w_snpRsp = $random;
    io_respInfo_2_bits_w_compdata = $random;
    io_respInfo_3_valid = $random;
    io_respInfo_3_bits_opcode = $random;
    io_respInfo_3_bits_reqID = $random;
    io_respInfo_3_bits_w_snpRsp = $random;
    io_respInfo_3_bits_w_compdata = $random;
    io_respInfo_4_valid = $random;
    io_respInfo_4_bits_opcode = $random;
    io_respInfo_4_bits_reqID = $random;
    io_respInfo_4_bits_w_snpRsp = $random;
    io_respInfo_4_bits_w_compdata = $random;
    io_respInfo_5_valid = $random;
    io_respInfo_5_bits_opcode = $random;
    io_respInfo_5_bits_reqID = $random;
    io_respInfo_5_bits_w_snpRsp = $random;
    io_respInfo_5_bits_w_compdata = $random;
    io_respInfo_6_valid = $random;
    io_respInfo_6_bits_opcode = $random;
    io_respInfo_6_bits_reqID = $random;
    io_respInfo_6_bits_w_snpRsp = $random;
    io_respInfo_6_bits_w_compdata = $random;
    io_respInfo_7_valid = $random;
    io_respInfo_7_bits_opcode = $random;
    io_respInfo_7_bits_reqID = $random;
    io_respInfo_7_bits_w_snpRsp = $random;
    io_respInfo_7_bits_w_compdata = $random;
    io_respInfo_8_valid = $random;
    io_respInfo_8_bits_opcode = $random;
    io_respInfo_8_bits_reqID = $random;
    io_respInfo_8_bits_w_snpRsp = $random;
    io_respInfo_8_bits_w_compdata = $random;
    io_respInfo_9_valid = $random;
    io_respInfo_9_bits_opcode = $random;
    io_respInfo_9_bits_reqID = $random;
    io_respInfo_9_bits_w_snpRsp = $random;
    io_respInfo_9_bits_w_compdata = $random;
    io_respInfo_10_valid = $random;
    io_respInfo_10_bits_opcode = $random;
    io_respInfo_10_bits_reqID = $random;
    io_respInfo_10_bits_w_snpRsp = $random;
    io_respInfo_10_bits_w_compdata = $random;
    io_respInfo_11_valid = $random;
    io_respInfo_11_bits_opcode = $random;
    io_respInfo_11_bits_reqID = $random;
    io_respInfo_11_bits_w_snpRsp = $random;
    io_respInfo_11_bits_w_compdata = $random;
    io_respInfo_12_valid = $random;
    io_respInfo_12_bits_opcode = $random;
    io_respInfo_12_bits_reqID = $random;
    io_respInfo_12_bits_w_snpRsp = $random;
    io_respInfo_12_bits_w_compdata = $random;
    io_respInfo_13_valid = $random;
    io_respInfo_13_bits_opcode = $random;
    io_respInfo_13_bits_reqID = $random;
    io_respInfo_13_bits_w_snpRsp = $random;
    io_respInfo_13_bits_w_compdata = $random;
    io_respInfo_14_valid = $random;
    io_respInfo_14_bits_opcode = $random;
    io_respInfo_14_bits_reqID = $random;
    io_respInfo_14_bits_w_snpRsp = $random;
    io_respInfo_14_bits_w_compdata = $random;
    io_respInfo_15_valid = $random;
    io_respInfo_15_bits_opcode = $random;
    io_respInfo_15_bits_reqID = $random;
    io_respInfo_15_bits_w_snpRsp = $random;
    io_respInfo_15_bits_w_compdata = $random;
    // 偏置: 使控制路径更常被触发
    if (($random & 3) != 0) io_txreq_ready = 1'b1;
    if (($random & 3) != 0) io_txdat_ready = 1'b1;
    case ($random & 3) 0: io_snRxrsp_bits_opcode = 7'h4; 1: io_snRxrsp_bits_opcode = 7'h5; 2: io_snRxrsp_bits_opcode = 7'h6; default: ; endcase
    if (($random & 1) == 0) io_fromMainPipe_alloc_s4_bits_task_chiOpcode = 7'h1D;
    if (($random & 1) == 0) io_fromMainPipe_alloc_s6_bits_task_chiOpcode = 7'h1D;
    if (($random & 7) == 0) io_fromMainPipe_alloc_s4_bits_task_chiOpcode = 7'h4;
    if (($random & 1) == 0) io_rnRxdat_bits_resp = io_rnRxdat_bits_resp | 3'h4;
    if (($random & 7) == 0) begin io_respInfo_0_bits_w_snpRsp = 1'b1; io_respInfo_0_bits_w_compdata = 1'b0; io_respInfo_0_bits_opcode = ($random & 1) ? 7'h7 : 7'h26; end
    if (($random & 7) == 0) begin io_respInfo_1_bits_w_snpRsp = 1'b1; io_respInfo_1_bits_w_compdata = 1'b0; io_respInfo_1_bits_opcode = ($random & 1) ? 7'h7 : 7'h26; end
    if (($random & 7) == 0) begin io_respInfo_2_bits_w_snpRsp = 1'b1; io_respInfo_2_bits_w_compdata = 1'b0; io_respInfo_2_bits_opcode = ($random & 1) ? 7'h7 : 7'h26; end
    if (($random & 7) == 0) begin io_respInfo_3_bits_w_snpRsp = 1'b1; io_respInfo_3_bits_w_compdata = 1'b0; io_respInfo_3_bits_opcode = ($random & 1) ? 7'h7 : 7'h26; end
    if (($random & 7) == 0) begin io_respInfo_4_bits_w_snpRsp = 1'b1; io_respInfo_4_bits_w_compdata = 1'b0; io_respInfo_4_bits_opcode = ($random & 1) ? 7'h7 : 7'h26; end
    if (($random & 7) == 0) begin io_respInfo_5_bits_w_snpRsp = 1'b1; io_respInfo_5_bits_w_compdata = 1'b0; io_respInfo_5_bits_opcode = ($random & 1) ? 7'h7 : 7'h26; end
    if (($random & 7) == 0) begin io_respInfo_6_bits_w_snpRsp = 1'b1; io_respInfo_6_bits_w_compdata = 1'b0; io_respInfo_6_bits_opcode = ($random & 1) ? 7'h7 : 7'h26; end
    if (($random & 7) == 0) begin io_respInfo_7_bits_w_snpRsp = 1'b1; io_respInfo_7_bits_w_compdata = 1'b0; io_respInfo_7_bits_opcode = ($random & 1) ? 7'h7 : 7'h26; end
    if (($random & 7) == 0) begin io_respInfo_8_bits_w_snpRsp = 1'b1; io_respInfo_8_bits_w_compdata = 1'b0; io_respInfo_8_bits_opcode = ($random & 1) ? 7'h7 : 7'h26; end
    if (($random & 7) == 0) begin io_respInfo_9_bits_w_snpRsp = 1'b1; io_respInfo_9_bits_w_compdata = 1'b0; io_respInfo_9_bits_opcode = ($random & 1) ? 7'h7 : 7'h26; end
    if (($random & 7) == 0) begin io_respInfo_10_bits_w_snpRsp = 1'b1; io_respInfo_10_bits_w_compdata = 1'b0; io_respInfo_10_bits_opcode = ($random & 1) ? 7'h7 : 7'h26; end
    if (($random & 7) == 0) begin io_respInfo_11_bits_w_snpRsp = 1'b1; io_respInfo_11_bits_w_compdata = 1'b0; io_respInfo_11_bits_opcode = ($random & 1) ? 7'h7 : 7'h26; end
    if (($random & 7) == 0) begin io_respInfo_12_bits_w_snpRsp = 1'b1; io_respInfo_12_bits_w_compdata = 1'b0; io_respInfo_12_bits_opcode = ($random & 1) ? 7'h7 : 7'h26; end
    if (($random & 7) == 0) begin io_respInfo_13_bits_w_snpRsp = 1'b1; io_respInfo_13_bits_w_compdata = 1'b0; io_respInfo_13_bits_opcode = ($random & 1) ? 7'h7 : 7'h26; end
    if (($random & 7) == 0) begin io_respInfo_14_bits_w_snpRsp = 1'b1; io_respInfo_14_bits_w_compdata = 1'b0; io_respInfo_14_bits_opcode = ($random & 1) ? 7'h7 : 7'h26; end
    if (($random & 7) == 0) begin io_respInfo_15_bits_w_snpRsp = 1'b1; io_respInfo_15_bits_w_compdata = 1'b0; io_respInfo_15_bits_opcode = ($random & 1) ? 7'h7 : 7'h26; end
    io_rnRxdat_bits_txnID = io_rnRxdat_bits_txnID & 12'h1F;
    io_rnRxrsp_bits_txnID = io_rnRxrsp_bits_txnID & 12'h1F;
    io_snRxrsp_bits_txnID = io_snRxrsp_bits_txnID & 12'h1F;
    io_fromMainPipe_alloc_s4_bits_task_reqID = io_fromMainPipe_alloc_s4_bits_task_reqID & 12'h1F;
    io_fromMainPipe_alloc_s6_bits_task_reqID = io_fromMainPipe_alloc_s6_bits_task_reqID & 12'h1F;
    io_urgentRead_bits_set = io_urgentRead_bits_set & 12'h7;
    io_fromMainPipe_alloc_s4_bits_task_set = io_fromMainPipe_alloc_s4_bits_task_set & 12'h7;
    io_fromMainPipe_alloc_s6_bits_task_set = io_fromMainPipe_alloc_s6_bits_task_set & 12'h7;
    io_urgentRead_bits_tag = io_urgentRead_bits_tag & 28'h3;
    io_fromMainPipe_alloc_s4_bits_task_tag = io_fromMainPipe_alloc_s4_bits_task_tag & 28'h3;
    io_fromMainPipe_alloc_s6_bits_task_tag = io_fromMainPipe_alloc_s6_bits_task_tag & 28'h3;
  endtask

  task automatic check_outputs();
    checks++;
    if (g_io_urgentRead_ready !== i_io_urgentRead_ready) begin errors++; if (errors<=30) $display("[%0d] MISMATCH io_urgentRead_ready: g=%h i=%h", cyc, g_io_urgentRead_ready, i_io_urgentRead_ready); end
    if (g_io_txreq_valid !== i_io_txreq_valid) begin errors++; if (errors<=30) $display("[%0d] MISMATCH io_txreq_valid: g=%h i=%h", cyc, g_io_txreq_valid, i_io_txreq_valid); end
    if (g_io_txreq_bits_set !== i_io_txreq_bits_set) begin errors++; if (errors<=30) $display("[%0d] MISMATCH io_txreq_bits_set: g=%h i=%h", cyc, g_io_txreq_bits_set, i_io_txreq_bits_set); end
    if (g_io_txreq_bits_bank !== i_io_txreq_bits_bank) begin errors++; if (errors<=30) $display("[%0d] MISMATCH io_txreq_bits_bank: g=%h i=%h", cyc, g_io_txreq_bits_bank, i_io_txreq_bits_bank); end
    if (g_io_txreq_bits_tag !== i_io_txreq_bits_tag) begin errors++; if (errors<=30) $display("[%0d] MISMATCH io_txreq_bits_tag: g=%h i=%h", cyc, g_io_txreq_bits_tag, i_io_txreq_bits_tag); end
    if (g_io_txreq_bits_size !== i_io_txreq_bits_size) begin errors++; if (errors<=30) $display("[%0d] MISMATCH io_txreq_bits_size: g=%h i=%h", cyc, g_io_txreq_bits_size, i_io_txreq_bits_size); end
    if (g_io_txreq_bits_tgtID !== i_io_txreq_bits_tgtID) begin errors++; if (errors<=30) $display("[%0d] MISMATCH io_txreq_bits_tgtID: g=%h i=%h", cyc, g_io_txreq_bits_tgtID, i_io_txreq_bits_tgtID); end
    if (g_io_txreq_bits_srcID !== i_io_txreq_bits_srcID) begin errors++; if (errors<=30) $display("[%0d] MISMATCH io_txreq_bits_srcID: g=%h i=%h", cyc, g_io_txreq_bits_srcID, i_io_txreq_bits_srcID); end
    if (g_io_txreq_bits_txnID !== i_io_txreq_bits_txnID) begin errors++; if (errors<=30) $display("[%0d] MISMATCH io_txreq_bits_txnID: g=%h i=%h", cyc, g_io_txreq_bits_txnID, i_io_txreq_bits_txnID); end
    if (g_io_txreq_bits_chiOpcode !== i_io_txreq_bits_chiOpcode) begin errors++; if (errors<=30) $display("[%0d] MISMATCH io_txreq_bits_chiOpcode: g=%h i=%h", cyc, g_io_txreq_bits_chiOpcode, i_io_txreq_bits_chiOpcode); end
    if (g_io_txreq_bits_pCrdType !== i_io_txreq_bits_pCrdType) begin errors++; if (errors<=30) $display("[%0d] MISMATCH io_txreq_bits_pCrdType: g=%h i=%h", cyc, g_io_txreq_bits_pCrdType, i_io_txreq_bits_pCrdType); end
    if (g_io_txreq_bits_expCompAck !== i_io_txreq_bits_expCompAck) begin errors++; if (errors<=30) $display("[%0d] MISMATCH io_txreq_bits_expCompAck: g=%h i=%h", cyc, g_io_txreq_bits_expCompAck, i_io_txreq_bits_expCompAck); end
    if (g_io_txreq_bits_allowRetry !== i_io_txreq_bits_allowRetry) begin errors++; if (errors<=30) $display("[%0d] MISMATCH io_txreq_bits_allowRetry: g=%h i=%h", cyc, g_io_txreq_bits_allowRetry, i_io_txreq_bits_allowRetry); end
    if (g_io_txreq_bits_order !== i_io_txreq_bits_order) begin errors++; if (errors<=30) $display("[%0d] MISMATCH io_txreq_bits_order: g=%h i=%h", cyc, g_io_txreq_bits_order, i_io_txreq_bits_order); end
    if (g_io_txreq_bits_memAttr_allocate !== i_io_txreq_bits_memAttr_allocate) begin errors++; if (errors<=30) $display("[%0d] MISMATCH io_txreq_bits_memAttr_allocate: g=%h i=%h", cyc, g_io_txreq_bits_memAttr_allocate, i_io_txreq_bits_memAttr_allocate); end
    if (g_io_txreq_bits_memAttr_cacheable !== i_io_txreq_bits_memAttr_cacheable) begin errors++; if (errors<=30) $display("[%0d] MISMATCH io_txreq_bits_memAttr_cacheable: g=%h i=%h", cyc, g_io_txreq_bits_memAttr_cacheable, i_io_txreq_bits_memAttr_cacheable); end
    if (g_io_txreq_bits_memAttr_device !== i_io_txreq_bits_memAttr_device) begin errors++; if (errors<=30) $display("[%0d] MISMATCH io_txreq_bits_memAttr_device: g=%h i=%h", cyc, g_io_txreq_bits_memAttr_device, i_io_txreq_bits_memAttr_device); end
    if (g_io_txreq_bits_memAttr_ewa !== i_io_txreq_bits_memAttr_ewa) begin errors++; if (errors<=30) $display("[%0d] MISMATCH io_txreq_bits_memAttr_ewa: g=%h i=%h", cyc, g_io_txreq_bits_memAttr_ewa, i_io_txreq_bits_memAttr_ewa); end
    if (g_io_txreq_bits_snpAttr !== i_io_txreq_bits_snpAttr) begin errors++; if (errors<=30) $display("[%0d] MISMATCH io_txreq_bits_snpAttr: g=%h i=%h", cyc, g_io_txreq_bits_snpAttr, i_io_txreq_bits_snpAttr); end
    if (g_io_txdat_valid !== i_io_txdat_valid) begin errors++; if (errors<=30) $display("[%0d] MISMATCH io_txdat_valid: g=%h i=%h", cyc, g_io_txdat_valid, i_io_txdat_valid); end
    if (g_io_txdat_bits_task_tgtID !== i_io_txdat_bits_task_tgtID) begin errors++; if (errors<=30) $display("[%0d] MISMATCH io_txdat_bits_task_tgtID: g=%h i=%h", cyc, g_io_txdat_bits_task_tgtID, i_io_txdat_bits_task_tgtID); end
    if (g_io_txdat_bits_task_srcID !== i_io_txdat_bits_task_srcID) begin errors++; if (errors<=30) $display("[%0d] MISMATCH io_txdat_bits_task_srcID: g=%h i=%h", cyc, g_io_txdat_bits_task_srcID, i_io_txdat_bits_task_srcID); end
    if (g_io_txdat_bits_task_txnID !== i_io_txdat_bits_task_txnID) begin errors++; if (errors<=30) $display("[%0d] MISMATCH io_txdat_bits_task_txnID: g=%h i=%h", cyc, g_io_txdat_bits_task_txnID, i_io_txdat_bits_task_txnID); end
    if (g_io_txdat_bits_task_homeNID !== i_io_txdat_bits_task_homeNID) begin errors++; if (errors<=30) $display("[%0d] MISMATCH io_txdat_bits_task_homeNID: g=%h i=%h", cyc, g_io_txdat_bits_task_homeNID, i_io_txdat_bits_task_homeNID); end
    if (g_io_txdat_bits_task_dbID !== i_io_txdat_bits_task_dbID) begin errors++; if (errors<=30) $display("[%0d] MISMATCH io_txdat_bits_task_dbID: g=%h i=%h", cyc, g_io_txdat_bits_task_dbID, i_io_txdat_bits_task_dbID); end
    if (g_io_txdat_bits_task_resp !== i_io_txdat_bits_task_resp) begin errors++; if (errors<=30) $display("[%0d] MISMATCH io_txdat_bits_task_resp: g=%h i=%h", cyc, g_io_txdat_bits_task_resp, i_io_txdat_bits_task_resp); end
    if (g_io_txdat_bits_task_fwdState !== i_io_txdat_bits_task_fwdState) begin errors++; if (errors<=30) $display("[%0d] MISMATCH io_txdat_bits_task_fwdState: g=%h i=%h", cyc, g_io_txdat_bits_task_fwdState, i_io_txdat_bits_task_fwdState); end
    if (g_io_txdat_bits_data_data_0_data !== i_io_txdat_bits_data_data_0_data) begin errors++; if (errors<=30) $display("[%0d] MISMATCH io_txdat_bits_data_data_0_data: g=%h i=%h", cyc, g_io_txdat_bits_data_data_0_data, i_io_txdat_bits_data_data_0_data); end
    if (g_io_txdat_bits_data_data_1_data !== i_io_txdat_bits_data_data_1_data) begin errors++; if (errors<=30) $display("[%0d] MISMATCH io_txdat_bits_data_data_1_data: g=%h i=%h", cyc, g_io_txdat_bits_data_data_1_data, i_io_txdat_bits_data_data_1_data); end
    if (g_io_bypassData_0_valid !== i_io_bypassData_0_valid) begin errors++; if (errors<=30) $display("[%0d] MISMATCH io_bypassData_0_valid: g=%h i=%h", cyc, g_io_bypassData_0_valid, i_io_bypassData_0_valid); end
    if (g_io_bypassData_0_bits_txnID !== i_io_bypassData_0_bits_txnID) begin errors++; if (errors<=30) $display("[%0d] MISMATCH io_bypassData_0_bits_txnID: g=%h i=%h", cyc, g_io_bypassData_0_bits_txnID, i_io_bypassData_0_bits_txnID); end
    if (g_io_bypassData_0_bits_opcode !== i_io_bypassData_0_bits_opcode) begin errors++; if (errors<=30) $display("[%0d] MISMATCH io_bypassData_0_bits_opcode: g=%h i=%h", cyc, g_io_bypassData_0_bits_opcode, i_io_bypassData_0_bits_opcode); end
    if (g_io_bypassData_0_bits_data_data !== i_io_bypassData_0_bits_data_data) begin errors++; if (errors<=30) $display("[%0d] MISMATCH io_bypassData_0_bits_data_data: g=%h i=%h", cyc, g_io_bypassData_0_bits_data_data, i_io_bypassData_0_bits_data_data); end
    if (g_io_bypassData_1_valid !== i_io_bypassData_1_valid) begin errors++; if (errors<=30) $display("[%0d] MISMATCH io_bypassData_1_valid: g=%h i=%h", cyc, g_io_bypassData_1_valid, i_io_bypassData_1_valid); end
    if (g_io_bypassData_1_bits_txnID !== i_io_bypassData_1_bits_txnID) begin errors++; if (errors<=30) $display("[%0d] MISMATCH io_bypassData_1_bits_txnID: g=%h i=%h", cyc, g_io_bypassData_1_bits_txnID, i_io_bypassData_1_bits_txnID); end
    if (g_io_bypassData_1_bits_opcode !== i_io_bypassData_1_bits_opcode) begin errors++; if (errors<=30) $display("[%0d] MISMATCH io_bypassData_1_bits_opcode: g=%h i=%h", cyc, g_io_bypassData_1_bits_opcode, i_io_bypassData_1_bits_opcode); end
    if (g_io_bypassData_1_bits_dataID !== i_io_bypassData_1_bits_dataID) begin errors++; if (errors<=30) $display("[%0d] MISMATCH io_bypassData_1_bits_dataID: g=%h i=%h", cyc, g_io_bypassData_1_bits_dataID, i_io_bypassData_1_bits_dataID); end
    if (g_io_bypassData_1_bits_data_data !== i_io_bypassData_1_bits_data_data) begin errors++; if (errors<=30) $display("[%0d] MISMATCH io_bypassData_1_bits_data_data: g=%h i=%h", cyc, g_io_bypassData_1_bits_data_data, i_io_bypassData_1_bits_data_data); end
    if (g_io_memInfo_0_valid !== i_io_memInfo_0_valid) begin errors++; if (errors<=30) $display("[%0d] MISMATCH io_memInfo_0_valid: g=%h i=%h", cyc, g_io_memInfo_0_valid, i_io_memInfo_0_valid); end
    if (g_io_memInfo_0_bits_set !== i_io_memInfo_0_bits_set) begin errors++; if (errors<=30) $display("[%0d] MISMATCH io_memInfo_0_bits_set: g=%h i=%h", cyc, g_io_memInfo_0_bits_set, i_io_memInfo_0_bits_set); end
    if (g_io_memInfo_0_bits_tag !== i_io_memInfo_0_bits_tag) begin errors++; if (errors<=30) $display("[%0d] MISMATCH io_memInfo_0_bits_tag: g=%h i=%h", cyc, g_io_memInfo_0_bits_tag, i_io_memInfo_0_bits_tag); end
    if (g_io_memInfo_0_bits_opcode !== i_io_memInfo_0_bits_opcode) begin errors++; if (errors<=30) $display("[%0d] MISMATCH io_memInfo_0_bits_opcode: g=%h i=%h", cyc, g_io_memInfo_0_bits_opcode, i_io_memInfo_0_bits_opcode); end
    if (g_io_memInfo_0_bits_reqID !== i_io_memInfo_0_bits_reqID) begin errors++; if (errors<=30) $display("[%0d] MISMATCH io_memInfo_0_bits_reqID: g=%h i=%h", cyc, g_io_memInfo_0_bits_reqID, i_io_memInfo_0_bits_reqID); end
    if (g_io_memInfo_0_bits_w_datRsp !== i_io_memInfo_0_bits_w_datRsp) begin errors++; if (errors<=30) $display("[%0d] MISMATCH io_memInfo_0_bits_w_datRsp: g=%h i=%h", cyc, g_io_memInfo_0_bits_w_datRsp, i_io_memInfo_0_bits_w_datRsp); end
    if (g_io_memInfo_1_valid !== i_io_memInfo_1_valid) begin errors++; if (errors<=30) $display("[%0d] MISMATCH io_memInfo_1_valid: g=%h i=%h", cyc, g_io_memInfo_1_valid, i_io_memInfo_1_valid); end
    if (g_io_memInfo_1_bits_set !== i_io_memInfo_1_bits_set) begin errors++; if (errors<=30) $display("[%0d] MISMATCH io_memInfo_1_bits_set: g=%h i=%h", cyc, g_io_memInfo_1_bits_set, i_io_memInfo_1_bits_set); end
    if (g_io_memInfo_1_bits_tag !== i_io_memInfo_1_bits_tag) begin errors++; if (errors<=30) $display("[%0d] MISMATCH io_memInfo_1_bits_tag: g=%h i=%h", cyc, g_io_memInfo_1_bits_tag, i_io_memInfo_1_bits_tag); end
    if (g_io_memInfo_1_bits_opcode !== i_io_memInfo_1_bits_opcode) begin errors++; if (errors<=30) $display("[%0d] MISMATCH io_memInfo_1_bits_opcode: g=%h i=%h", cyc, g_io_memInfo_1_bits_opcode, i_io_memInfo_1_bits_opcode); end
    if (g_io_memInfo_1_bits_reqID !== i_io_memInfo_1_bits_reqID) begin errors++; if (errors<=30) $display("[%0d] MISMATCH io_memInfo_1_bits_reqID: g=%h i=%h", cyc, g_io_memInfo_1_bits_reqID, i_io_memInfo_1_bits_reqID); end
    if (g_io_memInfo_1_bits_w_datRsp !== i_io_memInfo_1_bits_w_datRsp) begin errors++; if (errors<=30) $display("[%0d] MISMATCH io_memInfo_1_bits_w_datRsp: g=%h i=%h", cyc, g_io_memInfo_1_bits_w_datRsp, i_io_memInfo_1_bits_w_datRsp); end
    if (g_io_memInfo_2_valid !== i_io_memInfo_2_valid) begin errors++; if (errors<=30) $display("[%0d] MISMATCH io_memInfo_2_valid: g=%h i=%h", cyc, g_io_memInfo_2_valid, i_io_memInfo_2_valid); end
    if (g_io_memInfo_2_bits_set !== i_io_memInfo_2_bits_set) begin errors++; if (errors<=30) $display("[%0d] MISMATCH io_memInfo_2_bits_set: g=%h i=%h", cyc, g_io_memInfo_2_bits_set, i_io_memInfo_2_bits_set); end
    if (g_io_memInfo_2_bits_tag !== i_io_memInfo_2_bits_tag) begin errors++; if (errors<=30) $display("[%0d] MISMATCH io_memInfo_2_bits_tag: g=%h i=%h", cyc, g_io_memInfo_2_bits_tag, i_io_memInfo_2_bits_tag); end
    if (g_io_memInfo_2_bits_opcode !== i_io_memInfo_2_bits_opcode) begin errors++; if (errors<=30) $display("[%0d] MISMATCH io_memInfo_2_bits_opcode: g=%h i=%h", cyc, g_io_memInfo_2_bits_opcode, i_io_memInfo_2_bits_opcode); end
    if (g_io_memInfo_2_bits_reqID !== i_io_memInfo_2_bits_reqID) begin errors++; if (errors<=30) $display("[%0d] MISMATCH io_memInfo_2_bits_reqID: g=%h i=%h", cyc, g_io_memInfo_2_bits_reqID, i_io_memInfo_2_bits_reqID); end
    if (g_io_memInfo_2_bits_w_datRsp !== i_io_memInfo_2_bits_w_datRsp) begin errors++; if (errors<=30) $display("[%0d] MISMATCH io_memInfo_2_bits_w_datRsp: g=%h i=%h", cyc, g_io_memInfo_2_bits_w_datRsp, i_io_memInfo_2_bits_w_datRsp); end
    if (g_io_memInfo_3_valid !== i_io_memInfo_3_valid) begin errors++; if (errors<=30) $display("[%0d] MISMATCH io_memInfo_3_valid: g=%h i=%h", cyc, g_io_memInfo_3_valid, i_io_memInfo_3_valid); end
    if (g_io_memInfo_3_bits_set !== i_io_memInfo_3_bits_set) begin errors++; if (errors<=30) $display("[%0d] MISMATCH io_memInfo_3_bits_set: g=%h i=%h", cyc, g_io_memInfo_3_bits_set, i_io_memInfo_3_bits_set); end
    if (g_io_memInfo_3_bits_tag !== i_io_memInfo_3_bits_tag) begin errors++; if (errors<=30) $display("[%0d] MISMATCH io_memInfo_3_bits_tag: g=%h i=%h", cyc, g_io_memInfo_3_bits_tag, i_io_memInfo_3_bits_tag); end
    if (g_io_memInfo_3_bits_opcode !== i_io_memInfo_3_bits_opcode) begin errors++; if (errors<=30) $display("[%0d] MISMATCH io_memInfo_3_bits_opcode: g=%h i=%h", cyc, g_io_memInfo_3_bits_opcode, i_io_memInfo_3_bits_opcode); end
    if (g_io_memInfo_3_bits_reqID !== i_io_memInfo_3_bits_reqID) begin errors++; if (errors<=30) $display("[%0d] MISMATCH io_memInfo_3_bits_reqID: g=%h i=%h", cyc, g_io_memInfo_3_bits_reqID, i_io_memInfo_3_bits_reqID); end
    if (g_io_memInfo_3_bits_w_datRsp !== i_io_memInfo_3_bits_w_datRsp) begin errors++; if (errors<=30) $display("[%0d] MISMATCH io_memInfo_3_bits_w_datRsp: g=%h i=%h", cyc, g_io_memInfo_3_bits_w_datRsp, i_io_memInfo_3_bits_w_datRsp); end
    if (g_io_memInfo_4_valid !== i_io_memInfo_4_valid) begin errors++; if (errors<=30) $display("[%0d] MISMATCH io_memInfo_4_valid: g=%h i=%h", cyc, g_io_memInfo_4_valid, i_io_memInfo_4_valid); end
    if (g_io_memInfo_4_bits_set !== i_io_memInfo_4_bits_set) begin errors++; if (errors<=30) $display("[%0d] MISMATCH io_memInfo_4_bits_set: g=%h i=%h", cyc, g_io_memInfo_4_bits_set, i_io_memInfo_4_bits_set); end
    if (g_io_memInfo_4_bits_tag !== i_io_memInfo_4_bits_tag) begin errors++; if (errors<=30) $display("[%0d] MISMATCH io_memInfo_4_bits_tag: g=%h i=%h", cyc, g_io_memInfo_4_bits_tag, i_io_memInfo_4_bits_tag); end
    if (g_io_memInfo_4_bits_opcode !== i_io_memInfo_4_bits_opcode) begin errors++; if (errors<=30) $display("[%0d] MISMATCH io_memInfo_4_bits_opcode: g=%h i=%h", cyc, g_io_memInfo_4_bits_opcode, i_io_memInfo_4_bits_opcode); end
    if (g_io_memInfo_4_bits_reqID !== i_io_memInfo_4_bits_reqID) begin errors++; if (errors<=30) $display("[%0d] MISMATCH io_memInfo_4_bits_reqID: g=%h i=%h", cyc, g_io_memInfo_4_bits_reqID, i_io_memInfo_4_bits_reqID); end
    if (g_io_memInfo_4_bits_w_datRsp !== i_io_memInfo_4_bits_w_datRsp) begin errors++; if (errors<=30) $display("[%0d] MISMATCH io_memInfo_4_bits_w_datRsp: g=%h i=%h", cyc, g_io_memInfo_4_bits_w_datRsp, i_io_memInfo_4_bits_w_datRsp); end
    if (g_io_memInfo_5_valid !== i_io_memInfo_5_valid) begin errors++; if (errors<=30) $display("[%0d] MISMATCH io_memInfo_5_valid: g=%h i=%h", cyc, g_io_memInfo_5_valid, i_io_memInfo_5_valid); end
    if (g_io_memInfo_5_bits_set !== i_io_memInfo_5_bits_set) begin errors++; if (errors<=30) $display("[%0d] MISMATCH io_memInfo_5_bits_set: g=%h i=%h", cyc, g_io_memInfo_5_bits_set, i_io_memInfo_5_bits_set); end
    if (g_io_memInfo_5_bits_tag !== i_io_memInfo_5_bits_tag) begin errors++; if (errors<=30) $display("[%0d] MISMATCH io_memInfo_5_bits_tag: g=%h i=%h", cyc, g_io_memInfo_5_bits_tag, i_io_memInfo_5_bits_tag); end
    if (g_io_memInfo_5_bits_opcode !== i_io_memInfo_5_bits_opcode) begin errors++; if (errors<=30) $display("[%0d] MISMATCH io_memInfo_5_bits_opcode: g=%h i=%h", cyc, g_io_memInfo_5_bits_opcode, i_io_memInfo_5_bits_opcode); end
    if (g_io_memInfo_5_bits_reqID !== i_io_memInfo_5_bits_reqID) begin errors++; if (errors<=30) $display("[%0d] MISMATCH io_memInfo_5_bits_reqID: g=%h i=%h", cyc, g_io_memInfo_5_bits_reqID, i_io_memInfo_5_bits_reqID); end
    if (g_io_memInfo_5_bits_w_datRsp !== i_io_memInfo_5_bits_w_datRsp) begin errors++; if (errors<=30) $display("[%0d] MISMATCH io_memInfo_5_bits_w_datRsp: g=%h i=%h", cyc, g_io_memInfo_5_bits_w_datRsp, i_io_memInfo_5_bits_w_datRsp); end
    if (g_io_memInfo_6_valid !== i_io_memInfo_6_valid) begin errors++; if (errors<=30) $display("[%0d] MISMATCH io_memInfo_6_valid: g=%h i=%h", cyc, g_io_memInfo_6_valid, i_io_memInfo_6_valid); end
    if (g_io_memInfo_6_bits_set !== i_io_memInfo_6_bits_set) begin errors++; if (errors<=30) $display("[%0d] MISMATCH io_memInfo_6_bits_set: g=%h i=%h", cyc, g_io_memInfo_6_bits_set, i_io_memInfo_6_bits_set); end
    if (g_io_memInfo_6_bits_tag !== i_io_memInfo_6_bits_tag) begin errors++; if (errors<=30) $display("[%0d] MISMATCH io_memInfo_6_bits_tag: g=%h i=%h", cyc, g_io_memInfo_6_bits_tag, i_io_memInfo_6_bits_tag); end
    if (g_io_memInfo_6_bits_opcode !== i_io_memInfo_6_bits_opcode) begin errors++; if (errors<=30) $display("[%0d] MISMATCH io_memInfo_6_bits_opcode: g=%h i=%h", cyc, g_io_memInfo_6_bits_opcode, i_io_memInfo_6_bits_opcode); end
    if (g_io_memInfo_6_bits_reqID !== i_io_memInfo_6_bits_reqID) begin errors++; if (errors<=30) $display("[%0d] MISMATCH io_memInfo_6_bits_reqID: g=%h i=%h", cyc, g_io_memInfo_6_bits_reqID, i_io_memInfo_6_bits_reqID); end
    if (g_io_memInfo_6_bits_w_datRsp !== i_io_memInfo_6_bits_w_datRsp) begin errors++; if (errors<=30) $display("[%0d] MISMATCH io_memInfo_6_bits_w_datRsp: g=%h i=%h", cyc, g_io_memInfo_6_bits_w_datRsp, i_io_memInfo_6_bits_w_datRsp); end
    if (g_io_memInfo_7_valid !== i_io_memInfo_7_valid) begin errors++; if (errors<=30) $display("[%0d] MISMATCH io_memInfo_7_valid: g=%h i=%h", cyc, g_io_memInfo_7_valid, i_io_memInfo_7_valid); end
    if (g_io_memInfo_7_bits_set !== i_io_memInfo_7_bits_set) begin errors++; if (errors<=30) $display("[%0d] MISMATCH io_memInfo_7_bits_set: g=%h i=%h", cyc, g_io_memInfo_7_bits_set, i_io_memInfo_7_bits_set); end
    if (g_io_memInfo_7_bits_tag !== i_io_memInfo_7_bits_tag) begin errors++; if (errors<=30) $display("[%0d] MISMATCH io_memInfo_7_bits_tag: g=%h i=%h", cyc, g_io_memInfo_7_bits_tag, i_io_memInfo_7_bits_tag); end
    if (g_io_memInfo_7_bits_opcode !== i_io_memInfo_7_bits_opcode) begin errors++; if (errors<=30) $display("[%0d] MISMATCH io_memInfo_7_bits_opcode: g=%h i=%h", cyc, g_io_memInfo_7_bits_opcode, i_io_memInfo_7_bits_opcode); end
    if (g_io_memInfo_7_bits_reqID !== i_io_memInfo_7_bits_reqID) begin errors++; if (errors<=30) $display("[%0d] MISMATCH io_memInfo_7_bits_reqID: g=%h i=%h", cyc, g_io_memInfo_7_bits_reqID, i_io_memInfo_7_bits_reqID); end
    if (g_io_memInfo_7_bits_w_datRsp !== i_io_memInfo_7_bits_w_datRsp) begin errors++; if (errors<=30) $display("[%0d] MISMATCH io_memInfo_7_bits_w_datRsp: g=%h i=%h", cyc, g_io_memInfo_7_bits_w_datRsp, i_io_memInfo_7_bits_w_datRsp); end
    if (g_io_memInfo_8_valid !== i_io_memInfo_8_valid) begin errors++; if (errors<=30) $display("[%0d] MISMATCH io_memInfo_8_valid: g=%h i=%h", cyc, g_io_memInfo_8_valid, i_io_memInfo_8_valid); end
    if (g_io_memInfo_8_bits_set !== i_io_memInfo_8_bits_set) begin errors++; if (errors<=30) $display("[%0d] MISMATCH io_memInfo_8_bits_set: g=%h i=%h", cyc, g_io_memInfo_8_bits_set, i_io_memInfo_8_bits_set); end
    if (g_io_memInfo_8_bits_tag !== i_io_memInfo_8_bits_tag) begin errors++; if (errors<=30) $display("[%0d] MISMATCH io_memInfo_8_bits_tag: g=%h i=%h", cyc, g_io_memInfo_8_bits_tag, i_io_memInfo_8_bits_tag); end
    if (g_io_memInfo_8_bits_opcode !== i_io_memInfo_8_bits_opcode) begin errors++; if (errors<=30) $display("[%0d] MISMATCH io_memInfo_8_bits_opcode: g=%h i=%h", cyc, g_io_memInfo_8_bits_opcode, i_io_memInfo_8_bits_opcode); end
    if (g_io_memInfo_8_bits_reqID !== i_io_memInfo_8_bits_reqID) begin errors++; if (errors<=30) $display("[%0d] MISMATCH io_memInfo_8_bits_reqID: g=%h i=%h", cyc, g_io_memInfo_8_bits_reqID, i_io_memInfo_8_bits_reqID); end
    if (g_io_memInfo_8_bits_w_datRsp !== i_io_memInfo_8_bits_w_datRsp) begin errors++; if (errors<=30) $display("[%0d] MISMATCH io_memInfo_8_bits_w_datRsp: g=%h i=%h", cyc, g_io_memInfo_8_bits_w_datRsp, i_io_memInfo_8_bits_w_datRsp); end
    if (g_io_memInfo_9_valid !== i_io_memInfo_9_valid) begin errors++; if (errors<=30) $display("[%0d] MISMATCH io_memInfo_9_valid: g=%h i=%h", cyc, g_io_memInfo_9_valid, i_io_memInfo_9_valid); end
    if (g_io_memInfo_9_bits_set !== i_io_memInfo_9_bits_set) begin errors++; if (errors<=30) $display("[%0d] MISMATCH io_memInfo_9_bits_set: g=%h i=%h", cyc, g_io_memInfo_9_bits_set, i_io_memInfo_9_bits_set); end
    if (g_io_memInfo_9_bits_tag !== i_io_memInfo_9_bits_tag) begin errors++; if (errors<=30) $display("[%0d] MISMATCH io_memInfo_9_bits_tag: g=%h i=%h", cyc, g_io_memInfo_9_bits_tag, i_io_memInfo_9_bits_tag); end
    if (g_io_memInfo_9_bits_opcode !== i_io_memInfo_9_bits_opcode) begin errors++; if (errors<=30) $display("[%0d] MISMATCH io_memInfo_9_bits_opcode: g=%h i=%h", cyc, g_io_memInfo_9_bits_opcode, i_io_memInfo_9_bits_opcode); end
    if (g_io_memInfo_9_bits_reqID !== i_io_memInfo_9_bits_reqID) begin errors++; if (errors<=30) $display("[%0d] MISMATCH io_memInfo_9_bits_reqID: g=%h i=%h", cyc, g_io_memInfo_9_bits_reqID, i_io_memInfo_9_bits_reqID); end
    if (g_io_memInfo_9_bits_w_datRsp !== i_io_memInfo_9_bits_w_datRsp) begin errors++; if (errors<=30) $display("[%0d] MISMATCH io_memInfo_9_bits_w_datRsp: g=%h i=%h", cyc, g_io_memInfo_9_bits_w_datRsp, i_io_memInfo_9_bits_w_datRsp); end
    if (g_io_memInfo_10_valid !== i_io_memInfo_10_valid) begin errors++; if (errors<=30) $display("[%0d] MISMATCH io_memInfo_10_valid: g=%h i=%h", cyc, g_io_memInfo_10_valid, i_io_memInfo_10_valid); end
    if (g_io_memInfo_10_bits_set !== i_io_memInfo_10_bits_set) begin errors++; if (errors<=30) $display("[%0d] MISMATCH io_memInfo_10_bits_set: g=%h i=%h", cyc, g_io_memInfo_10_bits_set, i_io_memInfo_10_bits_set); end
    if (g_io_memInfo_10_bits_tag !== i_io_memInfo_10_bits_tag) begin errors++; if (errors<=30) $display("[%0d] MISMATCH io_memInfo_10_bits_tag: g=%h i=%h", cyc, g_io_memInfo_10_bits_tag, i_io_memInfo_10_bits_tag); end
    if (g_io_memInfo_10_bits_opcode !== i_io_memInfo_10_bits_opcode) begin errors++; if (errors<=30) $display("[%0d] MISMATCH io_memInfo_10_bits_opcode: g=%h i=%h", cyc, g_io_memInfo_10_bits_opcode, i_io_memInfo_10_bits_opcode); end
    if (g_io_memInfo_10_bits_reqID !== i_io_memInfo_10_bits_reqID) begin errors++; if (errors<=30) $display("[%0d] MISMATCH io_memInfo_10_bits_reqID: g=%h i=%h", cyc, g_io_memInfo_10_bits_reqID, i_io_memInfo_10_bits_reqID); end
    if (g_io_memInfo_10_bits_w_datRsp !== i_io_memInfo_10_bits_w_datRsp) begin errors++; if (errors<=30) $display("[%0d] MISMATCH io_memInfo_10_bits_w_datRsp: g=%h i=%h", cyc, g_io_memInfo_10_bits_w_datRsp, i_io_memInfo_10_bits_w_datRsp); end
    if (g_io_memInfo_11_valid !== i_io_memInfo_11_valid) begin errors++; if (errors<=30) $display("[%0d] MISMATCH io_memInfo_11_valid: g=%h i=%h", cyc, g_io_memInfo_11_valid, i_io_memInfo_11_valid); end
    if (g_io_memInfo_11_bits_set !== i_io_memInfo_11_bits_set) begin errors++; if (errors<=30) $display("[%0d] MISMATCH io_memInfo_11_bits_set: g=%h i=%h", cyc, g_io_memInfo_11_bits_set, i_io_memInfo_11_bits_set); end
    if (g_io_memInfo_11_bits_tag !== i_io_memInfo_11_bits_tag) begin errors++; if (errors<=30) $display("[%0d] MISMATCH io_memInfo_11_bits_tag: g=%h i=%h", cyc, g_io_memInfo_11_bits_tag, i_io_memInfo_11_bits_tag); end
    if (g_io_memInfo_11_bits_opcode !== i_io_memInfo_11_bits_opcode) begin errors++; if (errors<=30) $display("[%0d] MISMATCH io_memInfo_11_bits_opcode: g=%h i=%h", cyc, g_io_memInfo_11_bits_opcode, i_io_memInfo_11_bits_opcode); end
    if (g_io_memInfo_11_bits_reqID !== i_io_memInfo_11_bits_reqID) begin errors++; if (errors<=30) $display("[%0d] MISMATCH io_memInfo_11_bits_reqID: g=%h i=%h", cyc, g_io_memInfo_11_bits_reqID, i_io_memInfo_11_bits_reqID); end
    if (g_io_memInfo_11_bits_w_datRsp !== i_io_memInfo_11_bits_w_datRsp) begin errors++; if (errors<=30) $display("[%0d] MISMATCH io_memInfo_11_bits_w_datRsp: g=%h i=%h", cyc, g_io_memInfo_11_bits_w_datRsp, i_io_memInfo_11_bits_w_datRsp); end
    if (g_io_memInfo_12_valid !== i_io_memInfo_12_valid) begin errors++; if (errors<=30) $display("[%0d] MISMATCH io_memInfo_12_valid: g=%h i=%h", cyc, g_io_memInfo_12_valid, i_io_memInfo_12_valid); end
    if (g_io_memInfo_12_bits_set !== i_io_memInfo_12_bits_set) begin errors++; if (errors<=30) $display("[%0d] MISMATCH io_memInfo_12_bits_set: g=%h i=%h", cyc, g_io_memInfo_12_bits_set, i_io_memInfo_12_bits_set); end
    if (g_io_memInfo_12_bits_tag !== i_io_memInfo_12_bits_tag) begin errors++; if (errors<=30) $display("[%0d] MISMATCH io_memInfo_12_bits_tag: g=%h i=%h", cyc, g_io_memInfo_12_bits_tag, i_io_memInfo_12_bits_tag); end
    if (g_io_memInfo_12_bits_opcode !== i_io_memInfo_12_bits_opcode) begin errors++; if (errors<=30) $display("[%0d] MISMATCH io_memInfo_12_bits_opcode: g=%h i=%h", cyc, g_io_memInfo_12_bits_opcode, i_io_memInfo_12_bits_opcode); end
    if (g_io_memInfo_12_bits_reqID !== i_io_memInfo_12_bits_reqID) begin errors++; if (errors<=30) $display("[%0d] MISMATCH io_memInfo_12_bits_reqID: g=%h i=%h", cyc, g_io_memInfo_12_bits_reqID, i_io_memInfo_12_bits_reqID); end
    if (g_io_memInfo_12_bits_w_datRsp !== i_io_memInfo_12_bits_w_datRsp) begin errors++; if (errors<=30) $display("[%0d] MISMATCH io_memInfo_12_bits_w_datRsp: g=%h i=%h", cyc, g_io_memInfo_12_bits_w_datRsp, i_io_memInfo_12_bits_w_datRsp); end
    if (g_io_memInfo_13_valid !== i_io_memInfo_13_valid) begin errors++; if (errors<=30) $display("[%0d] MISMATCH io_memInfo_13_valid: g=%h i=%h", cyc, g_io_memInfo_13_valid, i_io_memInfo_13_valid); end
    if (g_io_memInfo_13_bits_set !== i_io_memInfo_13_bits_set) begin errors++; if (errors<=30) $display("[%0d] MISMATCH io_memInfo_13_bits_set: g=%h i=%h", cyc, g_io_memInfo_13_bits_set, i_io_memInfo_13_bits_set); end
    if (g_io_memInfo_13_bits_tag !== i_io_memInfo_13_bits_tag) begin errors++; if (errors<=30) $display("[%0d] MISMATCH io_memInfo_13_bits_tag: g=%h i=%h", cyc, g_io_memInfo_13_bits_tag, i_io_memInfo_13_bits_tag); end
    if (g_io_memInfo_13_bits_opcode !== i_io_memInfo_13_bits_opcode) begin errors++; if (errors<=30) $display("[%0d] MISMATCH io_memInfo_13_bits_opcode: g=%h i=%h", cyc, g_io_memInfo_13_bits_opcode, i_io_memInfo_13_bits_opcode); end
    if (g_io_memInfo_13_bits_reqID !== i_io_memInfo_13_bits_reqID) begin errors++; if (errors<=30) $display("[%0d] MISMATCH io_memInfo_13_bits_reqID: g=%h i=%h", cyc, g_io_memInfo_13_bits_reqID, i_io_memInfo_13_bits_reqID); end
    if (g_io_memInfo_13_bits_w_datRsp !== i_io_memInfo_13_bits_w_datRsp) begin errors++; if (errors<=30) $display("[%0d] MISMATCH io_memInfo_13_bits_w_datRsp: g=%h i=%h", cyc, g_io_memInfo_13_bits_w_datRsp, i_io_memInfo_13_bits_w_datRsp); end
    if (g_io_memInfo_14_valid !== i_io_memInfo_14_valid) begin errors++; if (errors<=30) $display("[%0d] MISMATCH io_memInfo_14_valid: g=%h i=%h", cyc, g_io_memInfo_14_valid, i_io_memInfo_14_valid); end
    if (g_io_memInfo_14_bits_set !== i_io_memInfo_14_bits_set) begin errors++; if (errors<=30) $display("[%0d] MISMATCH io_memInfo_14_bits_set: g=%h i=%h", cyc, g_io_memInfo_14_bits_set, i_io_memInfo_14_bits_set); end
    if (g_io_memInfo_14_bits_tag !== i_io_memInfo_14_bits_tag) begin errors++; if (errors<=30) $display("[%0d] MISMATCH io_memInfo_14_bits_tag: g=%h i=%h", cyc, g_io_memInfo_14_bits_tag, i_io_memInfo_14_bits_tag); end
    if (g_io_memInfo_14_bits_opcode !== i_io_memInfo_14_bits_opcode) begin errors++; if (errors<=30) $display("[%0d] MISMATCH io_memInfo_14_bits_opcode: g=%h i=%h", cyc, g_io_memInfo_14_bits_opcode, i_io_memInfo_14_bits_opcode); end
    if (g_io_memInfo_14_bits_reqID !== i_io_memInfo_14_bits_reqID) begin errors++; if (errors<=30) $display("[%0d] MISMATCH io_memInfo_14_bits_reqID: g=%h i=%h", cyc, g_io_memInfo_14_bits_reqID, i_io_memInfo_14_bits_reqID); end
    if (g_io_memInfo_14_bits_w_datRsp !== i_io_memInfo_14_bits_w_datRsp) begin errors++; if (errors<=30) $display("[%0d] MISMATCH io_memInfo_14_bits_w_datRsp: g=%h i=%h", cyc, g_io_memInfo_14_bits_w_datRsp, i_io_memInfo_14_bits_w_datRsp); end
    if (g_io_memInfo_15_valid !== i_io_memInfo_15_valid) begin errors++; if (errors<=30) $display("[%0d] MISMATCH io_memInfo_15_valid: g=%h i=%h", cyc, g_io_memInfo_15_valid, i_io_memInfo_15_valid); end
    if (g_io_memInfo_15_bits_set !== i_io_memInfo_15_bits_set) begin errors++; if (errors<=30) $display("[%0d] MISMATCH io_memInfo_15_bits_set: g=%h i=%h", cyc, g_io_memInfo_15_bits_set, i_io_memInfo_15_bits_set); end
    if (g_io_memInfo_15_bits_tag !== i_io_memInfo_15_bits_tag) begin errors++; if (errors<=30) $display("[%0d] MISMATCH io_memInfo_15_bits_tag: g=%h i=%h", cyc, g_io_memInfo_15_bits_tag, i_io_memInfo_15_bits_tag); end
    if (g_io_memInfo_15_bits_opcode !== i_io_memInfo_15_bits_opcode) begin errors++; if (errors<=30) $display("[%0d] MISMATCH io_memInfo_15_bits_opcode: g=%h i=%h", cyc, g_io_memInfo_15_bits_opcode, i_io_memInfo_15_bits_opcode); end
    if (g_io_memInfo_15_bits_reqID !== i_io_memInfo_15_bits_reqID) begin errors++; if (errors<=30) $display("[%0d] MISMATCH io_memInfo_15_bits_reqID: g=%h i=%h", cyc, g_io_memInfo_15_bits_reqID, i_io_memInfo_15_bits_reqID); end
    if (g_io_memInfo_15_bits_w_datRsp !== i_io_memInfo_15_bits_w_datRsp) begin errors++; if (errors<=30) $display("[%0d] MISMATCH io_memInfo_15_bits_w_datRsp: g=%h i=%h", cyc, g_io_memInfo_15_bits_w_datRsp, i_io_memInfo_15_bits_w_datRsp); end
  endtask

  initial begin
    rst = 1'b1;
    io_fromMainPipe_alloc_s4_valid = '0;
    io_fromMainPipe_alloc_s4_bits_state_s_issueDat = '0;
    io_fromMainPipe_alloc_s4_bits_state_w_datRsp = '0;
    io_fromMainPipe_alloc_s4_bits_state_w_dbid = '0;
    io_fromMainPipe_alloc_s4_bits_state_w_comp = '0;
    io_fromMainPipe_alloc_s4_bits_task_set = '0;
    io_fromMainPipe_alloc_s4_bits_task_bank = '0;
    io_fromMainPipe_alloc_s4_bits_task_tag = '0;
    io_fromMainPipe_alloc_s4_bits_task_off = '0;
    io_fromMainPipe_alloc_s4_bits_task_refillTask = '0;
    io_fromMainPipe_alloc_s4_bits_task_bufID = '0;
    io_fromMainPipe_alloc_s4_bits_task_reqID = '0;
    io_fromMainPipe_alloc_s4_bits_task_replSnp = '0;
    io_fromMainPipe_alloc_s4_bits_task_snpVec_0 = '0;
    io_fromMainPipe_alloc_s4_bits_task_tgtID = '0;
    io_fromMainPipe_alloc_s4_bits_task_srcID = '0;
    io_fromMainPipe_alloc_s4_bits_task_txnID = '0;
    io_fromMainPipe_alloc_s4_bits_task_homeNID = '0;
    io_fromMainPipe_alloc_s4_bits_task_dbID = '0;
    io_fromMainPipe_alloc_s4_bits_task_fwdNID = '0;
    io_fromMainPipe_alloc_s4_bits_task_fwdTxnID = '0;
    io_fromMainPipe_alloc_s4_bits_task_chiOpcode = '0;
    io_fromMainPipe_alloc_s4_bits_task_resp = '0;
    io_fromMainPipe_alloc_s4_bits_task_fwdState = '0;
    io_fromMainPipe_alloc_s4_bits_task_pCrdType = '0;
    io_fromMainPipe_alloc_s4_bits_task_retToSrc = '0;
    io_fromMainPipe_alloc_s4_bits_task_doNotGoToSD = '0;
    io_fromMainPipe_alloc_s6_valid = '0;
    io_fromMainPipe_alloc_s6_bits_task_set = '0;
    io_fromMainPipe_alloc_s6_bits_task_bank = '0;
    io_fromMainPipe_alloc_s6_bits_task_tag = '0;
    io_fromMainPipe_alloc_s6_bits_task_off = '0;
    io_fromMainPipe_alloc_s6_bits_task_size = '0;
    io_fromMainPipe_alloc_s6_bits_task_refillTask = '0;
    io_fromMainPipe_alloc_s6_bits_task_bufID = '0;
    io_fromMainPipe_alloc_s6_bits_task_reqID = '0;
    io_fromMainPipe_alloc_s6_bits_task_replSnp = '0;
    io_fromMainPipe_alloc_s6_bits_task_snpVec_0 = '0;
    io_fromMainPipe_alloc_s6_bits_task_tgtID = '0;
    io_fromMainPipe_alloc_s6_bits_task_srcID = '0;
    io_fromMainPipe_alloc_s6_bits_task_txnID = '0;
    io_fromMainPipe_alloc_s6_bits_task_homeNID = '0;
    io_fromMainPipe_alloc_s6_bits_task_dbID = '0;
    io_fromMainPipe_alloc_s6_bits_task_fwdNID = '0;
    io_fromMainPipe_alloc_s6_bits_task_fwdTxnID = '0;
    io_fromMainPipe_alloc_s6_bits_task_chiOpcode = '0;
    io_fromMainPipe_alloc_s6_bits_task_resp = '0;
    io_fromMainPipe_alloc_s6_bits_task_fwdState = '0;
    io_fromMainPipe_alloc_s6_bits_task_pCrdType = '0;
    io_fromMainPipe_alloc_s6_bits_task_retToSrc = '0;
    io_fromMainPipe_alloc_s6_bits_task_doNotGoToSD = '0;
    io_fromMainPipe_alloc_s6_bits_task_expCompAck = '0;
    io_fromMainPipe_alloc_s6_bits_task_allowRetry = '0;
    io_fromMainPipe_alloc_s6_bits_task_order = '0;
    io_fromMainPipe_alloc_s6_bits_task_memAttr_allocate = '0;
    io_fromMainPipe_alloc_s6_bits_task_memAttr_cacheable = '0;
    io_fromMainPipe_alloc_s6_bits_task_memAttr_device = '0;
    io_fromMainPipe_alloc_s6_bits_task_memAttr_ewa = '0;
    io_fromMainPipe_alloc_s6_bits_task_snpAttr = '0;
    io_fromMainPipe_alloc_s6_bits_data_data_0_data = '0;
    io_fromMainPipe_alloc_s6_bits_data_data_1_data = '0;
    io_urgentRead_valid = '0;
    io_urgentRead_bits_set = '0;
    io_urgentRead_bits_bank = '0;
    io_urgentRead_bits_tag = '0;
    io_urgentRead_bits_tgtID = '0;
    io_urgentRead_bits_srcID = '0;
    io_urgentRead_bits_txnID = '0;
    io_urgentRead_bits_pCrdType = '0;
    io_snRxrsp_valid = '0;
    io_snRxrsp_bits_txnID = '0;
    io_snRxrsp_bits_dbID = '0;
    io_snRxrsp_bits_opcode = '0;
    io_rnRxdat_valid = '0;
    io_rnRxdat_bits_txnID = '0;
    io_rnRxdat_bits_resp = '0;
    io_rnRxdat_bits_dataID = '0;
    io_rnRxdat_bits_data_data = '0;
    io_rnRxrsp_valid = '0;
    io_rnRxrsp_bits_txnID = '0;
    io_txreq_ready = '0;
    io_txdat_ready = '0;
    io_respInfo_0_valid = '0;
    io_respInfo_0_bits_opcode = '0;
    io_respInfo_0_bits_reqID = '0;
    io_respInfo_0_bits_w_snpRsp = '0;
    io_respInfo_0_bits_w_compdata = '0;
    io_respInfo_1_valid = '0;
    io_respInfo_1_bits_opcode = '0;
    io_respInfo_1_bits_reqID = '0;
    io_respInfo_1_bits_w_snpRsp = '0;
    io_respInfo_1_bits_w_compdata = '0;
    io_respInfo_2_valid = '0;
    io_respInfo_2_bits_opcode = '0;
    io_respInfo_2_bits_reqID = '0;
    io_respInfo_2_bits_w_snpRsp = '0;
    io_respInfo_2_bits_w_compdata = '0;
    io_respInfo_3_valid = '0;
    io_respInfo_3_bits_opcode = '0;
    io_respInfo_3_bits_reqID = '0;
    io_respInfo_3_bits_w_snpRsp = '0;
    io_respInfo_3_bits_w_compdata = '0;
    io_respInfo_4_valid = '0;
    io_respInfo_4_bits_opcode = '0;
    io_respInfo_4_bits_reqID = '0;
    io_respInfo_4_bits_w_snpRsp = '0;
    io_respInfo_4_bits_w_compdata = '0;
    io_respInfo_5_valid = '0;
    io_respInfo_5_bits_opcode = '0;
    io_respInfo_5_bits_reqID = '0;
    io_respInfo_5_bits_w_snpRsp = '0;
    io_respInfo_5_bits_w_compdata = '0;
    io_respInfo_6_valid = '0;
    io_respInfo_6_bits_opcode = '0;
    io_respInfo_6_bits_reqID = '0;
    io_respInfo_6_bits_w_snpRsp = '0;
    io_respInfo_6_bits_w_compdata = '0;
    io_respInfo_7_valid = '0;
    io_respInfo_7_bits_opcode = '0;
    io_respInfo_7_bits_reqID = '0;
    io_respInfo_7_bits_w_snpRsp = '0;
    io_respInfo_7_bits_w_compdata = '0;
    io_respInfo_8_valid = '0;
    io_respInfo_8_bits_opcode = '0;
    io_respInfo_8_bits_reqID = '0;
    io_respInfo_8_bits_w_snpRsp = '0;
    io_respInfo_8_bits_w_compdata = '0;
    io_respInfo_9_valid = '0;
    io_respInfo_9_bits_opcode = '0;
    io_respInfo_9_bits_reqID = '0;
    io_respInfo_9_bits_w_snpRsp = '0;
    io_respInfo_9_bits_w_compdata = '0;
    io_respInfo_10_valid = '0;
    io_respInfo_10_bits_opcode = '0;
    io_respInfo_10_bits_reqID = '0;
    io_respInfo_10_bits_w_snpRsp = '0;
    io_respInfo_10_bits_w_compdata = '0;
    io_respInfo_11_valid = '0;
    io_respInfo_11_bits_opcode = '0;
    io_respInfo_11_bits_reqID = '0;
    io_respInfo_11_bits_w_snpRsp = '0;
    io_respInfo_11_bits_w_compdata = '0;
    io_respInfo_12_valid = '0;
    io_respInfo_12_bits_opcode = '0;
    io_respInfo_12_bits_reqID = '0;
    io_respInfo_12_bits_w_snpRsp = '0;
    io_respInfo_12_bits_w_compdata = '0;
    io_respInfo_13_valid = '0;
    io_respInfo_13_bits_opcode = '0;
    io_respInfo_13_bits_reqID = '0;
    io_respInfo_13_bits_w_snpRsp = '0;
    io_respInfo_13_bits_w_compdata = '0;
    io_respInfo_14_valid = '0;
    io_respInfo_14_bits_opcode = '0;
    io_respInfo_14_bits_reqID = '0;
    io_respInfo_14_bits_w_snpRsp = '0;
    io_respInfo_14_bits_w_compdata = '0;
    io_respInfo_15_valid = '0;
    io_respInfo_15_bits_opcode = '0;
    io_respInfo_15_bits_reqID = '0;
    io_respInfo_15_bits_w_snpRsp = '0;
    io_respInfo_15_bits_w_compdata = '0;
    repeat (6) @(posedge clk);
    @(negedge clk); rst = 1'b0;
    for (cyc = 0; cyc < NCYCLES; cyc++) begin
      @(negedge clk);
      drive_random();
      @(posedge clk);
      #1;
      if (cyc >= WARMUP) check_outputs();
    end
    if (errors == 0) $display("TEST PASSED: checks=%0d errors=0", checks);
    else $display("TEST FAILED: checks=%0d errors=%0d", checks, errors);
    $finish;
  end
endmodule
