// 自动生成: scripts/gen_iq_stamou.py(iq tb)—— 勿手改
`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 200000;
  bit clk=0, rst; int errors=0, checks=0;
  bit no_flush;
  always #5 clk = ~clk;
  logic io_flush_valid;
  logic io_flush_bits_robIdx_flag;
  logic [7:0] io_flush_bits_robIdx_value;
  logic io_flush_bits_level;
  logic io_enq_0_valid;
  logic [5:0] io_enq_0_bits_ftqPtr_value;
  logic [3:0] io_enq_0_bits_ftqOffset;
  logic [3:0] io_enq_0_bits_srcType_0;
  logic [34:0] io_enq_0_bits_fuType;
  logic [8:0] io_enq_0_bits_fuOpType;
  logic io_enq_0_bits_rfWen;
  logic [3:0] io_enq_0_bits_selImm;
  logic [31:0] io_enq_0_bits_imm;
  logic io_enq_0_bits_srcState_0;
  logic [1:0] io_enq_0_bits_srcLoadDependency_0_0;
  logic [1:0] io_enq_0_bits_srcLoadDependency_0_1;
  logic [1:0] io_enq_0_bits_srcLoadDependency_0_2;
  logic [7:0] io_enq_0_bits_psrc_0;
  logic [7:0] io_enq_0_bits_pdest;
  logic io_enq_0_bits_useRegCache_0;
  logic [4:0] io_enq_0_bits_regCacheIdx_0;
  logic io_enq_0_bits_robIdx_flag;
  logic [7:0] io_enq_0_bits_robIdx_value;
  logic io_enq_0_bits_sqIdx_flag;
  logic [5:0] io_enq_0_bits_sqIdx_value;
  logic io_enq_1_valid;
  logic [5:0] io_enq_1_bits_ftqPtr_value;
  logic [3:0] io_enq_1_bits_ftqOffset;
  logic [3:0] io_enq_1_bits_srcType_0;
  logic [34:0] io_enq_1_bits_fuType;
  logic [8:0] io_enq_1_bits_fuOpType;
  logic io_enq_1_bits_rfWen;
  logic [3:0] io_enq_1_bits_selImm;
  logic [31:0] io_enq_1_bits_imm;
  logic io_enq_1_bits_srcState_0;
  logic [1:0] io_enq_1_bits_srcLoadDependency_0_0;
  logic [1:0] io_enq_1_bits_srcLoadDependency_0_1;
  logic [1:0] io_enq_1_bits_srcLoadDependency_0_2;
  logic [7:0] io_enq_1_bits_psrc_0;
  logic [7:0] io_enq_1_bits_pdest;
  logic io_enq_1_bits_useRegCache_0;
  logic [4:0] io_enq_1_bits_regCacheIdx_0;
  logic io_enq_1_bits_robIdx_flag;
  logic [7:0] io_enq_1_bits_robIdx_value;
  logic io_enq_1_bits_sqIdx_flag;
  logic [5:0] io_enq_1_bits_sqIdx_value;
  logic io_og0Resp_0_valid;
  logic io_og1Resp_0_valid;
  logic [1:0] io_og1Resp_0_bits_resp;
  logic io_wakeupFromWB_3_valid;
  logic io_wakeupFromWB_3_bits_rfWen;
  logic [7:0] io_wakeupFromWB_3_bits_pdest;
  logic io_wakeupFromWB_2_valid;
  logic io_wakeupFromWB_2_bits_rfWen;
  logic [7:0] io_wakeupFromWB_2_bits_pdest;
  logic io_wakeupFromWB_1_valid;
  logic io_wakeupFromWB_1_bits_rfWen;
  logic [7:0] io_wakeupFromWB_1_bits_pdest;
  logic io_wakeupFromWB_0_valid;
  logic io_wakeupFromWB_0_bits_rfWen;
  logic [7:0] io_wakeupFromWB_0_bits_pdest;
  logic io_wakeupFromIQ_6_bits_rfWen;
  logic [7:0] io_wakeupFromIQ_6_bits_pdest;
  logic [4:0] io_wakeupFromIQ_6_bits_rcDest;
  logic io_wakeupFromIQ_5_bits_rfWen;
  logic [7:0] io_wakeupFromIQ_5_bits_pdest;
  logic [4:0] io_wakeupFromIQ_5_bits_rcDest;
  logic io_wakeupFromIQ_4_bits_rfWen;
  logic [7:0] io_wakeupFromIQ_4_bits_pdest;
  logic [4:0] io_wakeupFromIQ_4_bits_rcDest;
  logic io_wakeupFromIQ_3_bits_rfWen;
  logic [7:0] io_wakeupFromIQ_3_bits_pdest;
  logic [1:0] io_wakeupFromIQ_3_bits_loadDependency_0;
  logic [1:0] io_wakeupFromIQ_3_bits_loadDependency_1;
  logic [1:0] io_wakeupFromIQ_3_bits_loadDependency_2;
  logic [4:0] io_wakeupFromIQ_3_bits_rcDest;
  logic io_wakeupFromIQ_2_bits_rfWen;
  logic [7:0] io_wakeupFromIQ_2_bits_pdest;
  logic [1:0] io_wakeupFromIQ_2_bits_loadDependency_0;
  logic [1:0] io_wakeupFromIQ_2_bits_loadDependency_1;
  logic [1:0] io_wakeupFromIQ_2_bits_loadDependency_2;
  logic [4:0] io_wakeupFromIQ_2_bits_rcDest;
  logic io_wakeupFromIQ_1_bits_rfWen;
  logic [7:0] io_wakeupFromIQ_1_bits_pdest;
  logic [1:0] io_wakeupFromIQ_1_bits_loadDependency_0;
  logic [1:0] io_wakeupFromIQ_1_bits_loadDependency_1;
  logic [1:0] io_wakeupFromIQ_1_bits_loadDependency_2;
  logic io_wakeupFromIQ_1_bits_is0Lat;
  logic [4:0] io_wakeupFromIQ_1_bits_rcDest;
  logic io_wakeupFromIQ_0_bits_rfWen;
  logic [7:0] io_wakeupFromIQ_0_bits_pdest;
  logic [1:0] io_wakeupFromIQ_0_bits_loadDependency_0;
  logic [1:0] io_wakeupFromIQ_0_bits_loadDependency_1;
  logic [1:0] io_wakeupFromIQ_0_bits_loadDependency_2;
  logic io_wakeupFromIQ_0_bits_is0Lat;
  logic [4:0] io_wakeupFromIQ_0_bits_rcDest;
  logic io_wakeupFromWBDelayed_3_valid;
  logic io_wakeupFromWBDelayed_3_bits_rfWen;
  logic [7:0] io_wakeupFromWBDelayed_3_bits_pdest;
  logic io_wakeupFromWBDelayed_2_valid;
  logic io_wakeupFromWBDelayed_2_bits_rfWen;
  logic [7:0] io_wakeupFromWBDelayed_2_bits_pdest;
  logic io_wakeupFromWBDelayed_1_valid;
  logic io_wakeupFromWBDelayed_1_bits_rfWen;
  logic [7:0] io_wakeupFromWBDelayed_1_bits_pdest;
  logic io_wakeupFromWBDelayed_0_valid;
  logic io_wakeupFromWBDelayed_0_bits_rfWen;
  logic [7:0] io_wakeupFromWBDelayed_0_bits_pdest;
  logic io_wakeupFromIQDelayed_6_bits_rfWen;
  logic [7:0] io_wakeupFromIQDelayed_6_bits_pdest;
  logic [4:0] io_wakeupFromIQDelayed_6_bits_rcDest;
  logic io_wakeupFromIQDelayed_5_bits_rfWen;
  logic [7:0] io_wakeupFromIQDelayed_5_bits_pdest;
  logic [4:0] io_wakeupFromIQDelayed_5_bits_rcDest;
  logic io_wakeupFromIQDelayed_4_bits_rfWen;
  logic [7:0] io_wakeupFromIQDelayed_4_bits_pdest;
  logic [4:0] io_wakeupFromIQDelayed_4_bits_rcDest;
  logic io_wakeupFromIQDelayed_3_bits_rfWen;
  logic [7:0] io_wakeupFromIQDelayed_3_bits_pdest;
  logic [1:0] io_wakeupFromIQDelayed_3_bits_loadDependency_0;
  logic [1:0] io_wakeupFromIQDelayed_3_bits_loadDependency_1;
  logic [1:0] io_wakeupFromIQDelayed_3_bits_loadDependency_2;
  logic [4:0] io_wakeupFromIQDelayed_3_bits_rcDest;
  logic io_wakeupFromIQDelayed_2_bits_rfWen;
  logic [7:0] io_wakeupFromIQDelayed_2_bits_pdest;
  logic [1:0] io_wakeupFromIQDelayed_2_bits_loadDependency_0;
  logic [1:0] io_wakeupFromIQDelayed_2_bits_loadDependency_1;
  logic [1:0] io_wakeupFromIQDelayed_2_bits_loadDependency_2;
  logic [4:0] io_wakeupFromIQDelayed_2_bits_rcDest;
  logic io_wakeupFromIQDelayed_1_bits_rfWen;
  logic [7:0] io_wakeupFromIQDelayed_1_bits_pdest;
  logic [1:0] io_wakeupFromIQDelayed_1_bits_loadDependency_0;
  logic [1:0] io_wakeupFromIQDelayed_1_bits_loadDependency_1;
  logic [1:0] io_wakeupFromIQDelayed_1_bits_loadDependency_2;
  logic io_wakeupFromIQDelayed_1_bits_is0Lat;
  logic [4:0] io_wakeupFromIQDelayed_1_bits_rcDest;
  logic io_wakeupFromIQDelayed_0_bits_rfWen;
  logic [7:0] io_wakeupFromIQDelayed_0_bits_pdest;
  logic [1:0] io_wakeupFromIQDelayed_0_bits_loadDependency_0;
  logic [1:0] io_wakeupFromIQDelayed_0_bits_loadDependency_1;
  logic [1:0] io_wakeupFromIQDelayed_0_bits_loadDependency_2;
  logic io_wakeupFromIQDelayed_0_bits_is0Lat;
  logic [4:0] io_wakeupFromIQDelayed_0_bits_rcDest;
  logic io_og0Cancel_0;
  logic io_og0Cancel_2;
  logic io_og0Cancel_4;
  logic io_og0Cancel_6;
  logic io_ldCancel_0_ld2Cancel;
  logic io_ldCancel_1_ld2Cancel;
  logic io_ldCancel_2_ld2Cancel;
  logic io_deqDelay_0_ready;
  logic io_memIO_feedbackIO_0_feedbackSlow_valid;
  logic io_memIO_feedbackIO_0_feedbackSlow_bits_hit;
  logic io_memIO_feedbackIO_0_feedbackSlow_bits_sqIdx_flag;
  logic [5:0] io_memIO_feedbackIO_0_feedbackSlow_bits_sqIdx_value;
  wire g_io_enq_0_ready;
  wire i_io_enq_0_ready;
  wire g_io_enq_1_ready;
  wire i_io_enq_1_ready;
  wire [4:0] g_io_validCntDeqVec_0;
  wire [4:0] i_io_validCntDeqVec_0;
  wire g_io_deqDelay_0_valid;
  wire i_io_deqDelay_0_valid;
  wire [7:0] g_io_deqDelay_0_bits_rf_0_0_addr;
  wire [7:0] i_io_deqDelay_0_bits_rf_0_0_addr;
  wire [4:0] g_io_deqDelay_0_bits_rcIdx_0;
  wire [4:0] i_io_deqDelay_0_bits_rcIdx_0;
  wire [3:0] g_io_deqDelay_0_bits_immType;
  wire [3:0] i_io_deqDelay_0_bits_immType;
  wire [34:0] g_io_deqDelay_0_bits_common_fuType;
  wire [34:0] i_io_deqDelay_0_bits_common_fuType;
  wire [8:0] g_io_deqDelay_0_bits_common_fuOpType;
  wire [8:0] i_io_deqDelay_0_bits_common_fuOpType;
  wire [63:0] g_io_deqDelay_0_bits_common_imm;
  wire [63:0] i_io_deqDelay_0_bits_common_imm;
  wire g_io_deqDelay_0_bits_common_robIdx_flag;
  wire i_io_deqDelay_0_bits_common_robIdx_flag;
  wire [7:0] g_io_deqDelay_0_bits_common_robIdx_value;
  wire [7:0] i_io_deqDelay_0_bits_common_robIdx_value;
  wire g_io_deqDelay_0_bits_common_isFirstIssue;
  wire i_io_deqDelay_0_bits_common_isFirstIssue;
  wire [7:0] g_io_deqDelay_0_bits_common_pdest;
  wire [7:0] i_io_deqDelay_0_bits_common_pdest;
  wire g_io_deqDelay_0_bits_common_rfWen;
  wire i_io_deqDelay_0_bits_common_rfWen;
  wire [5:0] g_io_deqDelay_0_bits_common_ftqIdx_value;
  wire [5:0] i_io_deqDelay_0_bits_common_ftqIdx_value;
  wire [3:0] g_io_deqDelay_0_bits_common_ftqOffset;
  wire [3:0] i_io_deqDelay_0_bits_common_ftqOffset;
  wire g_io_deqDelay_0_bits_common_sqIdx_flag;
  wire i_io_deqDelay_0_bits_common_sqIdx_flag;
  wire [5:0] g_io_deqDelay_0_bits_common_sqIdx_value;
  wire [5:0] i_io_deqDelay_0_bits_common_sqIdx_value;
  wire [3:0] g_io_deqDelay_0_bits_common_dataSources_0_value;
  wire [3:0] i_io_deqDelay_0_bits_common_dataSources_0_value;
  wire [2:0] g_io_deqDelay_0_bits_common_exuSources_0_value;
  wire [2:0] i_io_deqDelay_0_bits_common_exuSources_0_value;
  wire [1:0] g_io_deqDelay_0_bits_common_loadDependency_0;
  wire [1:0] i_io_deqDelay_0_bits_common_loadDependency_0;
  wire [1:0] g_io_deqDelay_0_bits_common_loadDependency_1;
  wire [1:0] i_io_deqDelay_0_bits_common_loadDependency_1;
  wire [1:0] g_io_deqDelay_0_bits_common_loadDependency_2;
  wire [1:0] i_io_deqDelay_0_bits_common_loadDependency_2;
  IssueQueueStaMou u_g (
    .clock(clk), .reset(rst),
    .io_flush_valid(io_flush_valid),
    .io_flush_bits_robIdx_flag(io_flush_bits_robIdx_flag),
    .io_flush_bits_robIdx_value(io_flush_bits_robIdx_value),
    .io_flush_bits_level(io_flush_bits_level),
    .io_enq_0_valid(io_enq_0_valid),
    .io_enq_0_bits_ftqPtr_value(io_enq_0_bits_ftqPtr_value),
    .io_enq_0_bits_ftqOffset(io_enq_0_bits_ftqOffset),
    .io_enq_0_bits_srcType_0(io_enq_0_bits_srcType_0),
    .io_enq_0_bits_fuType(io_enq_0_bits_fuType),
    .io_enq_0_bits_fuOpType(io_enq_0_bits_fuOpType),
    .io_enq_0_bits_rfWen(io_enq_0_bits_rfWen),
    .io_enq_0_bits_selImm(io_enq_0_bits_selImm),
    .io_enq_0_bits_imm(io_enq_0_bits_imm),
    .io_enq_0_bits_srcState_0(io_enq_0_bits_srcState_0),
    .io_enq_0_bits_srcLoadDependency_0_0(io_enq_0_bits_srcLoadDependency_0_0),
    .io_enq_0_bits_srcLoadDependency_0_1(io_enq_0_bits_srcLoadDependency_0_1),
    .io_enq_0_bits_srcLoadDependency_0_2(io_enq_0_bits_srcLoadDependency_0_2),
    .io_enq_0_bits_psrc_0(io_enq_0_bits_psrc_0),
    .io_enq_0_bits_pdest(io_enq_0_bits_pdest),
    .io_enq_0_bits_useRegCache_0(io_enq_0_bits_useRegCache_0),
    .io_enq_0_bits_regCacheIdx_0(io_enq_0_bits_regCacheIdx_0),
    .io_enq_0_bits_robIdx_flag(io_enq_0_bits_robIdx_flag),
    .io_enq_0_bits_robIdx_value(io_enq_0_bits_robIdx_value),
    .io_enq_0_bits_sqIdx_flag(io_enq_0_bits_sqIdx_flag),
    .io_enq_0_bits_sqIdx_value(io_enq_0_bits_sqIdx_value),
    .io_enq_1_valid(io_enq_1_valid),
    .io_enq_1_bits_ftqPtr_value(io_enq_1_bits_ftqPtr_value),
    .io_enq_1_bits_ftqOffset(io_enq_1_bits_ftqOffset),
    .io_enq_1_bits_srcType_0(io_enq_1_bits_srcType_0),
    .io_enq_1_bits_fuType(io_enq_1_bits_fuType),
    .io_enq_1_bits_fuOpType(io_enq_1_bits_fuOpType),
    .io_enq_1_bits_rfWen(io_enq_1_bits_rfWen),
    .io_enq_1_bits_selImm(io_enq_1_bits_selImm),
    .io_enq_1_bits_imm(io_enq_1_bits_imm),
    .io_enq_1_bits_srcState_0(io_enq_1_bits_srcState_0),
    .io_enq_1_bits_srcLoadDependency_0_0(io_enq_1_bits_srcLoadDependency_0_0),
    .io_enq_1_bits_srcLoadDependency_0_1(io_enq_1_bits_srcLoadDependency_0_1),
    .io_enq_1_bits_srcLoadDependency_0_2(io_enq_1_bits_srcLoadDependency_0_2),
    .io_enq_1_bits_psrc_0(io_enq_1_bits_psrc_0),
    .io_enq_1_bits_pdest(io_enq_1_bits_pdest),
    .io_enq_1_bits_useRegCache_0(io_enq_1_bits_useRegCache_0),
    .io_enq_1_bits_regCacheIdx_0(io_enq_1_bits_regCacheIdx_0),
    .io_enq_1_bits_robIdx_flag(io_enq_1_bits_robIdx_flag),
    .io_enq_1_bits_robIdx_value(io_enq_1_bits_robIdx_value),
    .io_enq_1_bits_sqIdx_flag(io_enq_1_bits_sqIdx_flag),
    .io_enq_1_bits_sqIdx_value(io_enq_1_bits_sqIdx_value),
    .io_og0Resp_0_valid(io_og0Resp_0_valid),
    .io_og1Resp_0_valid(io_og1Resp_0_valid),
    .io_og1Resp_0_bits_resp(io_og1Resp_0_bits_resp),
    .io_wakeupFromWB_3_valid(io_wakeupFromWB_3_valid),
    .io_wakeupFromWB_3_bits_rfWen(io_wakeupFromWB_3_bits_rfWen),
    .io_wakeupFromWB_3_bits_pdest(io_wakeupFromWB_3_bits_pdest),
    .io_wakeupFromWB_2_valid(io_wakeupFromWB_2_valid),
    .io_wakeupFromWB_2_bits_rfWen(io_wakeupFromWB_2_bits_rfWen),
    .io_wakeupFromWB_2_bits_pdest(io_wakeupFromWB_2_bits_pdest),
    .io_wakeupFromWB_1_valid(io_wakeupFromWB_1_valid),
    .io_wakeupFromWB_1_bits_rfWen(io_wakeupFromWB_1_bits_rfWen),
    .io_wakeupFromWB_1_bits_pdest(io_wakeupFromWB_1_bits_pdest),
    .io_wakeupFromWB_0_valid(io_wakeupFromWB_0_valid),
    .io_wakeupFromWB_0_bits_rfWen(io_wakeupFromWB_0_bits_rfWen),
    .io_wakeupFromWB_0_bits_pdest(io_wakeupFromWB_0_bits_pdest),
    .io_wakeupFromIQ_6_bits_rfWen(io_wakeupFromIQ_6_bits_rfWen),
    .io_wakeupFromIQ_6_bits_pdest(io_wakeupFromIQ_6_bits_pdest),
    .io_wakeupFromIQ_6_bits_rcDest(io_wakeupFromIQ_6_bits_rcDest),
    .io_wakeupFromIQ_5_bits_rfWen(io_wakeupFromIQ_5_bits_rfWen),
    .io_wakeupFromIQ_5_bits_pdest(io_wakeupFromIQ_5_bits_pdest),
    .io_wakeupFromIQ_5_bits_rcDest(io_wakeupFromIQ_5_bits_rcDest),
    .io_wakeupFromIQ_4_bits_rfWen(io_wakeupFromIQ_4_bits_rfWen),
    .io_wakeupFromIQ_4_bits_pdest(io_wakeupFromIQ_4_bits_pdest),
    .io_wakeupFromIQ_4_bits_rcDest(io_wakeupFromIQ_4_bits_rcDest),
    .io_wakeupFromIQ_3_bits_rfWen(io_wakeupFromIQ_3_bits_rfWen),
    .io_wakeupFromIQ_3_bits_pdest(io_wakeupFromIQ_3_bits_pdest),
    .io_wakeupFromIQ_3_bits_loadDependency_0(io_wakeupFromIQ_3_bits_loadDependency_0),
    .io_wakeupFromIQ_3_bits_loadDependency_1(io_wakeupFromIQ_3_bits_loadDependency_1),
    .io_wakeupFromIQ_3_bits_loadDependency_2(io_wakeupFromIQ_3_bits_loadDependency_2),
    .io_wakeupFromIQ_3_bits_rcDest(io_wakeupFromIQ_3_bits_rcDest),
    .io_wakeupFromIQ_2_bits_rfWen(io_wakeupFromIQ_2_bits_rfWen),
    .io_wakeupFromIQ_2_bits_pdest(io_wakeupFromIQ_2_bits_pdest),
    .io_wakeupFromIQ_2_bits_loadDependency_0(io_wakeupFromIQ_2_bits_loadDependency_0),
    .io_wakeupFromIQ_2_bits_loadDependency_1(io_wakeupFromIQ_2_bits_loadDependency_1),
    .io_wakeupFromIQ_2_bits_loadDependency_2(io_wakeupFromIQ_2_bits_loadDependency_2),
    .io_wakeupFromIQ_2_bits_rcDest(io_wakeupFromIQ_2_bits_rcDest),
    .io_wakeupFromIQ_1_bits_rfWen(io_wakeupFromIQ_1_bits_rfWen),
    .io_wakeupFromIQ_1_bits_pdest(io_wakeupFromIQ_1_bits_pdest),
    .io_wakeupFromIQ_1_bits_loadDependency_0(io_wakeupFromIQ_1_bits_loadDependency_0),
    .io_wakeupFromIQ_1_bits_loadDependency_1(io_wakeupFromIQ_1_bits_loadDependency_1),
    .io_wakeupFromIQ_1_bits_loadDependency_2(io_wakeupFromIQ_1_bits_loadDependency_2),
    .io_wakeupFromIQ_1_bits_is0Lat(io_wakeupFromIQ_1_bits_is0Lat),
    .io_wakeupFromIQ_1_bits_rcDest(io_wakeupFromIQ_1_bits_rcDest),
    .io_wakeupFromIQ_0_bits_rfWen(io_wakeupFromIQ_0_bits_rfWen),
    .io_wakeupFromIQ_0_bits_pdest(io_wakeupFromIQ_0_bits_pdest),
    .io_wakeupFromIQ_0_bits_loadDependency_0(io_wakeupFromIQ_0_bits_loadDependency_0),
    .io_wakeupFromIQ_0_bits_loadDependency_1(io_wakeupFromIQ_0_bits_loadDependency_1),
    .io_wakeupFromIQ_0_bits_loadDependency_2(io_wakeupFromIQ_0_bits_loadDependency_2),
    .io_wakeupFromIQ_0_bits_is0Lat(io_wakeupFromIQ_0_bits_is0Lat),
    .io_wakeupFromIQ_0_bits_rcDest(io_wakeupFromIQ_0_bits_rcDest),
    .io_wakeupFromWBDelayed_3_valid(io_wakeupFromWBDelayed_3_valid),
    .io_wakeupFromWBDelayed_3_bits_rfWen(io_wakeupFromWBDelayed_3_bits_rfWen),
    .io_wakeupFromWBDelayed_3_bits_pdest(io_wakeupFromWBDelayed_3_bits_pdest),
    .io_wakeupFromWBDelayed_2_valid(io_wakeupFromWBDelayed_2_valid),
    .io_wakeupFromWBDelayed_2_bits_rfWen(io_wakeupFromWBDelayed_2_bits_rfWen),
    .io_wakeupFromWBDelayed_2_bits_pdest(io_wakeupFromWBDelayed_2_bits_pdest),
    .io_wakeupFromWBDelayed_1_valid(io_wakeupFromWBDelayed_1_valid),
    .io_wakeupFromWBDelayed_1_bits_rfWen(io_wakeupFromWBDelayed_1_bits_rfWen),
    .io_wakeupFromWBDelayed_1_bits_pdest(io_wakeupFromWBDelayed_1_bits_pdest),
    .io_wakeupFromWBDelayed_0_valid(io_wakeupFromWBDelayed_0_valid),
    .io_wakeupFromWBDelayed_0_bits_rfWen(io_wakeupFromWBDelayed_0_bits_rfWen),
    .io_wakeupFromWBDelayed_0_bits_pdest(io_wakeupFromWBDelayed_0_bits_pdest),
    .io_wakeupFromIQDelayed_6_bits_rfWen(io_wakeupFromIQDelayed_6_bits_rfWen),
    .io_wakeupFromIQDelayed_6_bits_pdest(io_wakeupFromIQDelayed_6_bits_pdest),
    .io_wakeupFromIQDelayed_6_bits_rcDest(io_wakeupFromIQDelayed_6_bits_rcDest),
    .io_wakeupFromIQDelayed_5_bits_rfWen(io_wakeupFromIQDelayed_5_bits_rfWen),
    .io_wakeupFromIQDelayed_5_bits_pdest(io_wakeupFromIQDelayed_5_bits_pdest),
    .io_wakeupFromIQDelayed_5_bits_rcDest(io_wakeupFromIQDelayed_5_bits_rcDest),
    .io_wakeupFromIQDelayed_4_bits_rfWen(io_wakeupFromIQDelayed_4_bits_rfWen),
    .io_wakeupFromIQDelayed_4_bits_pdest(io_wakeupFromIQDelayed_4_bits_pdest),
    .io_wakeupFromIQDelayed_4_bits_rcDest(io_wakeupFromIQDelayed_4_bits_rcDest),
    .io_wakeupFromIQDelayed_3_bits_rfWen(io_wakeupFromIQDelayed_3_bits_rfWen),
    .io_wakeupFromIQDelayed_3_bits_pdest(io_wakeupFromIQDelayed_3_bits_pdest),
    .io_wakeupFromIQDelayed_3_bits_loadDependency_0(io_wakeupFromIQDelayed_3_bits_loadDependency_0),
    .io_wakeupFromIQDelayed_3_bits_loadDependency_1(io_wakeupFromIQDelayed_3_bits_loadDependency_1),
    .io_wakeupFromIQDelayed_3_bits_loadDependency_2(io_wakeupFromIQDelayed_3_bits_loadDependency_2),
    .io_wakeupFromIQDelayed_3_bits_rcDest(io_wakeupFromIQDelayed_3_bits_rcDest),
    .io_wakeupFromIQDelayed_2_bits_rfWen(io_wakeupFromIQDelayed_2_bits_rfWen),
    .io_wakeupFromIQDelayed_2_bits_pdest(io_wakeupFromIQDelayed_2_bits_pdest),
    .io_wakeupFromIQDelayed_2_bits_loadDependency_0(io_wakeupFromIQDelayed_2_bits_loadDependency_0),
    .io_wakeupFromIQDelayed_2_bits_loadDependency_1(io_wakeupFromIQDelayed_2_bits_loadDependency_1),
    .io_wakeupFromIQDelayed_2_bits_loadDependency_2(io_wakeupFromIQDelayed_2_bits_loadDependency_2),
    .io_wakeupFromIQDelayed_2_bits_rcDest(io_wakeupFromIQDelayed_2_bits_rcDest),
    .io_wakeupFromIQDelayed_1_bits_rfWen(io_wakeupFromIQDelayed_1_bits_rfWen),
    .io_wakeupFromIQDelayed_1_bits_pdest(io_wakeupFromIQDelayed_1_bits_pdest),
    .io_wakeupFromIQDelayed_1_bits_loadDependency_0(io_wakeupFromIQDelayed_1_bits_loadDependency_0),
    .io_wakeupFromIQDelayed_1_bits_loadDependency_1(io_wakeupFromIQDelayed_1_bits_loadDependency_1),
    .io_wakeupFromIQDelayed_1_bits_loadDependency_2(io_wakeupFromIQDelayed_1_bits_loadDependency_2),
    .io_wakeupFromIQDelayed_1_bits_is0Lat(io_wakeupFromIQDelayed_1_bits_is0Lat),
    .io_wakeupFromIQDelayed_1_bits_rcDest(io_wakeupFromIQDelayed_1_bits_rcDest),
    .io_wakeupFromIQDelayed_0_bits_rfWen(io_wakeupFromIQDelayed_0_bits_rfWen),
    .io_wakeupFromIQDelayed_0_bits_pdest(io_wakeupFromIQDelayed_0_bits_pdest),
    .io_wakeupFromIQDelayed_0_bits_loadDependency_0(io_wakeupFromIQDelayed_0_bits_loadDependency_0),
    .io_wakeupFromIQDelayed_0_bits_loadDependency_1(io_wakeupFromIQDelayed_0_bits_loadDependency_1),
    .io_wakeupFromIQDelayed_0_bits_loadDependency_2(io_wakeupFromIQDelayed_0_bits_loadDependency_2),
    .io_wakeupFromIQDelayed_0_bits_is0Lat(io_wakeupFromIQDelayed_0_bits_is0Lat),
    .io_wakeupFromIQDelayed_0_bits_rcDest(io_wakeupFromIQDelayed_0_bits_rcDest),
    .io_og0Cancel_0(io_og0Cancel_0),
    .io_og0Cancel_2(io_og0Cancel_2),
    .io_og0Cancel_4(io_og0Cancel_4),
    .io_og0Cancel_6(io_og0Cancel_6),
    .io_ldCancel_0_ld2Cancel(io_ldCancel_0_ld2Cancel),
    .io_ldCancel_1_ld2Cancel(io_ldCancel_1_ld2Cancel),
    .io_ldCancel_2_ld2Cancel(io_ldCancel_2_ld2Cancel),
    .io_deqDelay_0_ready(io_deqDelay_0_ready),
    .io_memIO_feedbackIO_0_feedbackSlow_valid(io_memIO_feedbackIO_0_feedbackSlow_valid),
    .io_memIO_feedbackIO_0_feedbackSlow_bits_hit(io_memIO_feedbackIO_0_feedbackSlow_bits_hit),
    .io_memIO_feedbackIO_0_feedbackSlow_bits_sqIdx_flag(io_memIO_feedbackIO_0_feedbackSlow_bits_sqIdx_flag),
    .io_memIO_feedbackIO_0_feedbackSlow_bits_sqIdx_value(io_memIO_feedbackIO_0_feedbackSlow_bits_sqIdx_value),
    .io_enq_0_ready(g_io_enq_0_ready),
    .io_enq_1_ready(g_io_enq_1_ready),
    .io_validCntDeqVec_0(g_io_validCntDeqVec_0),
    .io_deqDelay_0_valid(g_io_deqDelay_0_valid),
    .io_deqDelay_0_bits_rf_0_0_addr(g_io_deqDelay_0_bits_rf_0_0_addr),
    .io_deqDelay_0_bits_rcIdx_0(g_io_deqDelay_0_bits_rcIdx_0),
    .io_deqDelay_0_bits_immType(g_io_deqDelay_0_bits_immType),
    .io_deqDelay_0_bits_common_fuType(g_io_deqDelay_0_bits_common_fuType),
    .io_deqDelay_0_bits_common_fuOpType(g_io_deqDelay_0_bits_common_fuOpType),
    .io_deqDelay_0_bits_common_imm(g_io_deqDelay_0_bits_common_imm),
    .io_deqDelay_0_bits_common_robIdx_flag(g_io_deqDelay_0_bits_common_robIdx_flag),
    .io_deqDelay_0_bits_common_robIdx_value(g_io_deqDelay_0_bits_common_robIdx_value),
    .io_deqDelay_0_bits_common_isFirstIssue(g_io_deqDelay_0_bits_common_isFirstIssue),
    .io_deqDelay_0_bits_common_pdest(g_io_deqDelay_0_bits_common_pdest),
    .io_deqDelay_0_bits_common_rfWen(g_io_deqDelay_0_bits_common_rfWen),
    .io_deqDelay_0_bits_common_ftqIdx_value(g_io_deqDelay_0_bits_common_ftqIdx_value),
    .io_deqDelay_0_bits_common_ftqOffset(g_io_deqDelay_0_bits_common_ftqOffset),
    .io_deqDelay_0_bits_common_sqIdx_flag(g_io_deqDelay_0_bits_common_sqIdx_flag),
    .io_deqDelay_0_bits_common_sqIdx_value(g_io_deqDelay_0_bits_common_sqIdx_value),
    .io_deqDelay_0_bits_common_dataSources_0_value(g_io_deqDelay_0_bits_common_dataSources_0_value),
    .io_deqDelay_0_bits_common_exuSources_0_value(g_io_deqDelay_0_bits_common_exuSources_0_value),
    .io_deqDelay_0_bits_common_loadDependency_0(g_io_deqDelay_0_bits_common_loadDependency_0),
    .io_deqDelay_0_bits_common_loadDependency_1(g_io_deqDelay_0_bits_common_loadDependency_1),
    .io_deqDelay_0_bits_common_loadDependency_2(g_io_deqDelay_0_bits_common_loadDependency_2)
  );
  IssueQueueStaMou_xs u_i (
    .clock(clk), .reset(rst),
    .io_flush_valid(io_flush_valid),
    .io_flush_bits_robIdx_flag(io_flush_bits_robIdx_flag),
    .io_flush_bits_robIdx_value(io_flush_bits_robIdx_value),
    .io_flush_bits_level(io_flush_bits_level),
    .io_enq_0_valid(io_enq_0_valid),
    .io_enq_0_bits_ftqPtr_value(io_enq_0_bits_ftqPtr_value),
    .io_enq_0_bits_ftqOffset(io_enq_0_bits_ftqOffset),
    .io_enq_0_bits_srcType_0(io_enq_0_bits_srcType_0),
    .io_enq_0_bits_fuType(io_enq_0_bits_fuType),
    .io_enq_0_bits_fuOpType(io_enq_0_bits_fuOpType),
    .io_enq_0_bits_rfWen(io_enq_0_bits_rfWen),
    .io_enq_0_bits_selImm(io_enq_0_bits_selImm),
    .io_enq_0_bits_imm(io_enq_0_bits_imm),
    .io_enq_0_bits_srcState_0(io_enq_0_bits_srcState_0),
    .io_enq_0_bits_srcLoadDependency_0_0(io_enq_0_bits_srcLoadDependency_0_0),
    .io_enq_0_bits_srcLoadDependency_0_1(io_enq_0_bits_srcLoadDependency_0_1),
    .io_enq_0_bits_srcLoadDependency_0_2(io_enq_0_bits_srcLoadDependency_0_2),
    .io_enq_0_bits_psrc_0(io_enq_0_bits_psrc_0),
    .io_enq_0_bits_pdest(io_enq_0_bits_pdest),
    .io_enq_0_bits_useRegCache_0(io_enq_0_bits_useRegCache_0),
    .io_enq_0_bits_regCacheIdx_0(io_enq_0_bits_regCacheIdx_0),
    .io_enq_0_bits_robIdx_flag(io_enq_0_bits_robIdx_flag),
    .io_enq_0_bits_robIdx_value(io_enq_0_bits_robIdx_value),
    .io_enq_0_bits_sqIdx_flag(io_enq_0_bits_sqIdx_flag),
    .io_enq_0_bits_sqIdx_value(io_enq_0_bits_sqIdx_value),
    .io_enq_1_valid(io_enq_1_valid),
    .io_enq_1_bits_ftqPtr_value(io_enq_1_bits_ftqPtr_value),
    .io_enq_1_bits_ftqOffset(io_enq_1_bits_ftqOffset),
    .io_enq_1_bits_srcType_0(io_enq_1_bits_srcType_0),
    .io_enq_1_bits_fuType(io_enq_1_bits_fuType),
    .io_enq_1_bits_fuOpType(io_enq_1_bits_fuOpType),
    .io_enq_1_bits_rfWen(io_enq_1_bits_rfWen),
    .io_enq_1_bits_selImm(io_enq_1_bits_selImm),
    .io_enq_1_bits_imm(io_enq_1_bits_imm),
    .io_enq_1_bits_srcState_0(io_enq_1_bits_srcState_0),
    .io_enq_1_bits_srcLoadDependency_0_0(io_enq_1_bits_srcLoadDependency_0_0),
    .io_enq_1_bits_srcLoadDependency_0_1(io_enq_1_bits_srcLoadDependency_0_1),
    .io_enq_1_bits_srcLoadDependency_0_2(io_enq_1_bits_srcLoadDependency_0_2),
    .io_enq_1_bits_psrc_0(io_enq_1_bits_psrc_0),
    .io_enq_1_bits_pdest(io_enq_1_bits_pdest),
    .io_enq_1_bits_useRegCache_0(io_enq_1_bits_useRegCache_0),
    .io_enq_1_bits_regCacheIdx_0(io_enq_1_bits_regCacheIdx_0),
    .io_enq_1_bits_robIdx_flag(io_enq_1_bits_robIdx_flag),
    .io_enq_1_bits_robIdx_value(io_enq_1_bits_robIdx_value),
    .io_enq_1_bits_sqIdx_flag(io_enq_1_bits_sqIdx_flag),
    .io_enq_1_bits_sqIdx_value(io_enq_1_bits_sqIdx_value),
    .io_og0Resp_0_valid(io_og0Resp_0_valid),
    .io_og1Resp_0_valid(io_og1Resp_0_valid),
    .io_og1Resp_0_bits_resp(io_og1Resp_0_bits_resp),
    .io_wakeupFromWB_3_valid(io_wakeupFromWB_3_valid),
    .io_wakeupFromWB_3_bits_rfWen(io_wakeupFromWB_3_bits_rfWen),
    .io_wakeupFromWB_3_bits_pdest(io_wakeupFromWB_3_bits_pdest),
    .io_wakeupFromWB_2_valid(io_wakeupFromWB_2_valid),
    .io_wakeupFromWB_2_bits_rfWen(io_wakeupFromWB_2_bits_rfWen),
    .io_wakeupFromWB_2_bits_pdest(io_wakeupFromWB_2_bits_pdest),
    .io_wakeupFromWB_1_valid(io_wakeupFromWB_1_valid),
    .io_wakeupFromWB_1_bits_rfWen(io_wakeupFromWB_1_bits_rfWen),
    .io_wakeupFromWB_1_bits_pdest(io_wakeupFromWB_1_bits_pdest),
    .io_wakeupFromWB_0_valid(io_wakeupFromWB_0_valid),
    .io_wakeupFromWB_0_bits_rfWen(io_wakeupFromWB_0_bits_rfWen),
    .io_wakeupFromWB_0_bits_pdest(io_wakeupFromWB_0_bits_pdest),
    .io_wakeupFromIQ_6_bits_rfWen(io_wakeupFromIQ_6_bits_rfWen),
    .io_wakeupFromIQ_6_bits_pdest(io_wakeupFromIQ_6_bits_pdest),
    .io_wakeupFromIQ_6_bits_rcDest(io_wakeupFromIQ_6_bits_rcDest),
    .io_wakeupFromIQ_5_bits_rfWen(io_wakeupFromIQ_5_bits_rfWen),
    .io_wakeupFromIQ_5_bits_pdest(io_wakeupFromIQ_5_bits_pdest),
    .io_wakeupFromIQ_5_bits_rcDest(io_wakeupFromIQ_5_bits_rcDest),
    .io_wakeupFromIQ_4_bits_rfWen(io_wakeupFromIQ_4_bits_rfWen),
    .io_wakeupFromIQ_4_bits_pdest(io_wakeupFromIQ_4_bits_pdest),
    .io_wakeupFromIQ_4_bits_rcDest(io_wakeupFromIQ_4_bits_rcDest),
    .io_wakeupFromIQ_3_bits_rfWen(io_wakeupFromIQ_3_bits_rfWen),
    .io_wakeupFromIQ_3_bits_pdest(io_wakeupFromIQ_3_bits_pdest),
    .io_wakeupFromIQ_3_bits_loadDependency_0(io_wakeupFromIQ_3_bits_loadDependency_0),
    .io_wakeupFromIQ_3_bits_loadDependency_1(io_wakeupFromIQ_3_bits_loadDependency_1),
    .io_wakeupFromIQ_3_bits_loadDependency_2(io_wakeupFromIQ_3_bits_loadDependency_2),
    .io_wakeupFromIQ_3_bits_rcDest(io_wakeupFromIQ_3_bits_rcDest),
    .io_wakeupFromIQ_2_bits_rfWen(io_wakeupFromIQ_2_bits_rfWen),
    .io_wakeupFromIQ_2_bits_pdest(io_wakeupFromIQ_2_bits_pdest),
    .io_wakeupFromIQ_2_bits_loadDependency_0(io_wakeupFromIQ_2_bits_loadDependency_0),
    .io_wakeupFromIQ_2_bits_loadDependency_1(io_wakeupFromIQ_2_bits_loadDependency_1),
    .io_wakeupFromIQ_2_bits_loadDependency_2(io_wakeupFromIQ_2_bits_loadDependency_2),
    .io_wakeupFromIQ_2_bits_rcDest(io_wakeupFromIQ_2_bits_rcDest),
    .io_wakeupFromIQ_1_bits_rfWen(io_wakeupFromIQ_1_bits_rfWen),
    .io_wakeupFromIQ_1_bits_pdest(io_wakeupFromIQ_1_bits_pdest),
    .io_wakeupFromIQ_1_bits_loadDependency_0(io_wakeupFromIQ_1_bits_loadDependency_0),
    .io_wakeupFromIQ_1_bits_loadDependency_1(io_wakeupFromIQ_1_bits_loadDependency_1),
    .io_wakeupFromIQ_1_bits_loadDependency_2(io_wakeupFromIQ_1_bits_loadDependency_2),
    .io_wakeupFromIQ_1_bits_is0Lat(io_wakeupFromIQ_1_bits_is0Lat),
    .io_wakeupFromIQ_1_bits_rcDest(io_wakeupFromIQ_1_bits_rcDest),
    .io_wakeupFromIQ_0_bits_rfWen(io_wakeupFromIQ_0_bits_rfWen),
    .io_wakeupFromIQ_0_bits_pdest(io_wakeupFromIQ_0_bits_pdest),
    .io_wakeupFromIQ_0_bits_loadDependency_0(io_wakeupFromIQ_0_bits_loadDependency_0),
    .io_wakeupFromIQ_0_bits_loadDependency_1(io_wakeupFromIQ_0_bits_loadDependency_1),
    .io_wakeupFromIQ_0_bits_loadDependency_2(io_wakeupFromIQ_0_bits_loadDependency_2),
    .io_wakeupFromIQ_0_bits_is0Lat(io_wakeupFromIQ_0_bits_is0Lat),
    .io_wakeupFromIQ_0_bits_rcDest(io_wakeupFromIQ_0_bits_rcDest),
    .io_wakeupFromWBDelayed_3_valid(io_wakeupFromWBDelayed_3_valid),
    .io_wakeupFromWBDelayed_3_bits_rfWen(io_wakeupFromWBDelayed_3_bits_rfWen),
    .io_wakeupFromWBDelayed_3_bits_pdest(io_wakeupFromWBDelayed_3_bits_pdest),
    .io_wakeupFromWBDelayed_2_valid(io_wakeupFromWBDelayed_2_valid),
    .io_wakeupFromWBDelayed_2_bits_rfWen(io_wakeupFromWBDelayed_2_bits_rfWen),
    .io_wakeupFromWBDelayed_2_bits_pdest(io_wakeupFromWBDelayed_2_bits_pdest),
    .io_wakeupFromWBDelayed_1_valid(io_wakeupFromWBDelayed_1_valid),
    .io_wakeupFromWBDelayed_1_bits_rfWen(io_wakeupFromWBDelayed_1_bits_rfWen),
    .io_wakeupFromWBDelayed_1_bits_pdest(io_wakeupFromWBDelayed_1_bits_pdest),
    .io_wakeupFromWBDelayed_0_valid(io_wakeupFromWBDelayed_0_valid),
    .io_wakeupFromWBDelayed_0_bits_rfWen(io_wakeupFromWBDelayed_0_bits_rfWen),
    .io_wakeupFromWBDelayed_0_bits_pdest(io_wakeupFromWBDelayed_0_bits_pdest),
    .io_wakeupFromIQDelayed_6_bits_rfWen(io_wakeupFromIQDelayed_6_bits_rfWen),
    .io_wakeupFromIQDelayed_6_bits_pdest(io_wakeupFromIQDelayed_6_bits_pdest),
    .io_wakeupFromIQDelayed_6_bits_rcDest(io_wakeupFromIQDelayed_6_bits_rcDest),
    .io_wakeupFromIQDelayed_5_bits_rfWen(io_wakeupFromIQDelayed_5_bits_rfWen),
    .io_wakeupFromIQDelayed_5_bits_pdest(io_wakeupFromIQDelayed_5_bits_pdest),
    .io_wakeupFromIQDelayed_5_bits_rcDest(io_wakeupFromIQDelayed_5_bits_rcDest),
    .io_wakeupFromIQDelayed_4_bits_rfWen(io_wakeupFromIQDelayed_4_bits_rfWen),
    .io_wakeupFromIQDelayed_4_bits_pdest(io_wakeupFromIQDelayed_4_bits_pdest),
    .io_wakeupFromIQDelayed_4_bits_rcDest(io_wakeupFromIQDelayed_4_bits_rcDest),
    .io_wakeupFromIQDelayed_3_bits_rfWen(io_wakeupFromIQDelayed_3_bits_rfWen),
    .io_wakeupFromIQDelayed_3_bits_pdest(io_wakeupFromIQDelayed_3_bits_pdest),
    .io_wakeupFromIQDelayed_3_bits_loadDependency_0(io_wakeupFromIQDelayed_3_bits_loadDependency_0),
    .io_wakeupFromIQDelayed_3_bits_loadDependency_1(io_wakeupFromIQDelayed_3_bits_loadDependency_1),
    .io_wakeupFromIQDelayed_3_bits_loadDependency_2(io_wakeupFromIQDelayed_3_bits_loadDependency_2),
    .io_wakeupFromIQDelayed_3_bits_rcDest(io_wakeupFromIQDelayed_3_bits_rcDest),
    .io_wakeupFromIQDelayed_2_bits_rfWen(io_wakeupFromIQDelayed_2_bits_rfWen),
    .io_wakeupFromIQDelayed_2_bits_pdest(io_wakeupFromIQDelayed_2_bits_pdest),
    .io_wakeupFromIQDelayed_2_bits_loadDependency_0(io_wakeupFromIQDelayed_2_bits_loadDependency_0),
    .io_wakeupFromIQDelayed_2_bits_loadDependency_1(io_wakeupFromIQDelayed_2_bits_loadDependency_1),
    .io_wakeupFromIQDelayed_2_bits_loadDependency_2(io_wakeupFromIQDelayed_2_bits_loadDependency_2),
    .io_wakeupFromIQDelayed_2_bits_rcDest(io_wakeupFromIQDelayed_2_bits_rcDest),
    .io_wakeupFromIQDelayed_1_bits_rfWen(io_wakeupFromIQDelayed_1_bits_rfWen),
    .io_wakeupFromIQDelayed_1_bits_pdest(io_wakeupFromIQDelayed_1_bits_pdest),
    .io_wakeupFromIQDelayed_1_bits_loadDependency_0(io_wakeupFromIQDelayed_1_bits_loadDependency_0),
    .io_wakeupFromIQDelayed_1_bits_loadDependency_1(io_wakeupFromIQDelayed_1_bits_loadDependency_1),
    .io_wakeupFromIQDelayed_1_bits_loadDependency_2(io_wakeupFromIQDelayed_1_bits_loadDependency_2),
    .io_wakeupFromIQDelayed_1_bits_is0Lat(io_wakeupFromIQDelayed_1_bits_is0Lat),
    .io_wakeupFromIQDelayed_1_bits_rcDest(io_wakeupFromIQDelayed_1_bits_rcDest),
    .io_wakeupFromIQDelayed_0_bits_rfWen(io_wakeupFromIQDelayed_0_bits_rfWen),
    .io_wakeupFromIQDelayed_0_bits_pdest(io_wakeupFromIQDelayed_0_bits_pdest),
    .io_wakeupFromIQDelayed_0_bits_loadDependency_0(io_wakeupFromIQDelayed_0_bits_loadDependency_0),
    .io_wakeupFromIQDelayed_0_bits_loadDependency_1(io_wakeupFromIQDelayed_0_bits_loadDependency_1),
    .io_wakeupFromIQDelayed_0_bits_loadDependency_2(io_wakeupFromIQDelayed_0_bits_loadDependency_2),
    .io_wakeupFromIQDelayed_0_bits_is0Lat(io_wakeupFromIQDelayed_0_bits_is0Lat),
    .io_wakeupFromIQDelayed_0_bits_rcDest(io_wakeupFromIQDelayed_0_bits_rcDest),
    .io_og0Cancel_0(io_og0Cancel_0),
    .io_og0Cancel_2(io_og0Cancel_2),
    .io_og0Cancel_4(io_og0Cancel_4),
    .io_og0Cancel_6(io_og0Cancel_6),
    .io_ldCancel_0_ld2Cancel(io_ldCancel_0_ld2Cancel),
    .io_ldCancel_1_ld2Cancel(io_ldCancel_1_ld2Cancel),
    .io_ldCancel_2_ld2Cancel(io_ldCancel_2_ld2Cancel),
    .io_deqDelay_0_ready(io_deqDelay_0_ready),
    .io_memIO_feedbackIO_0_feedbackSlow_valid(io_memIO_feedbackIO_0_feedbackSlow_valid),
    .io_memIO_feedbackIO_0_feedbackSlow_bits_hit(io_memIO_feedbackIO_0_feedbackSlow_bits_hit),
    .io_memIO_feedbackIO_0_feedbackSlow_bits_sqIdx_flag(io_memIO_feedbackIO_0_feedbackSlow_bits_sqIdx_flag),
    .io_memIO_feedbackIO_0_feedbackSlow_bits_sqIdx_value(io_memIO_feedbackIO_0_feedbackSlow_bits_sqIdx_value),
    .io_enq_0_ready(i_io_enq_0_ready),
    .io_enq_1_ready(i_io_enq_1_ready),
    .io_validCntDeqVec_0(i_io_validCntDeqVec_0),
    .io_deqDelay_0_valid(i_io_deqDelay_0_valid),
    .io_deqDelay_0_bits_rf_0_0_addr(i_io_deqDelay_0_bits_rf_0_0_addr),
    .io_deqDelay_0_bits_rcIdx_0(i_io_deqDelay_0_bits_rcIdx_0),
    .io_deqDelay_0_bits_immType(i_io_deqDelay_0_bits_immType),
    .io_deqDelay_0_bits_common_fuType(i_io_deqDelay_0_bits_common_fuType),
    .io_deqDelay_0_bits_common_fuOpType(i_io_deqDelay_0_bits_common_fuOpType),
    .io_deqDelay_0_bits_common_imm(i_io_deqDelay_0_bits_common_imm),
    .io_deqDelay_0_bits_common_robIdx_flag(i_io_deqDelay_0_bits_common_robIdx_flag),
    .io_deqDelay_0_bits_common_robIdx_value(i_io_deqDelay_0_bits_common_robIdx_value),
    .io_deqDelay_0_bits_common_isFirstIssue(i_io_deqDelay_0_bits_common_isFirstIssue),
    .io_deqDelay_0_bits_common_pdest(i_io_deqDelay_0_bits_common_pdest),
    .io_deqDelay_0_bits_common_rfWen(i_io_deqDelay_0_bits_common_rfWen),
    .io_deqDelay_0_bits_common_ftqIdx_value(i_io_deqDelay_0_bits_common_ftqIdx_value),
    .io_deqDelay_0_bits_common_ftqOffset(i_io_deqDelay_0_bits_common_ftqOffset),
    .io_deqDelay_0_bits_common_sqIdx_flag(i_io_deqDelay_0_bits_common_sqIdx_flag),
    .io_deqDelay_0_bits_common_sqIdx_value(i_io_deqDelay_0_bits_common_sqIdx_value),
    .io_deqDelay_0_bits_common_dataSources_0_value(i_io_deqDelay_0_bits_common_dataSources_0_value),
    .io_deqDelay_0_bits_common_exuSources_0_value(i_io_deqDelay_0_bits_common_exuSources_0_value),
    .io_deqDelay_0_bits_common_loadDependency_0(i_io_deqDelay_0_bits_common_loadDependency_0),
    .io_deqDelay_0_bits_common_loadDependency_1(i_io_deqDelay_0_bits_common_loadDependency_1),
    .io_deqDelay_0_bits_common_loadDependency_2(i_io_deqDelay_0_bits_common_loadDependency_2)
  );
  task drive_rand();
    io_flush_valid = $urandom;
    io_flush_bits_robIdx_flag = $urandom;
    io_flush_bits_robIdx_value = $urandom;
    io_flush_bits_level = $urandom;
    io_enq_0_valid = $urandom;
    io_enq_0_bits_ftqPtr_value = $urandom;
    io_enq_0_bits_ftqOffset = $urandom;
    io_enq_0_bits_srcType_0 = $urandom;
    io_enq_0_bits_fuType = $urandom;
    io_enq_0_bits_fuOpType = $urandom;
    io_enq_0_bits_rfWen = $urandom;
    io_enq_0_bits_selImm = $urandom;
    io_enq_0_bits_imm = $urandom;
    io_enq_0_bits_srcState_0 = $urandom;
    io_enq_0_bits_srcLoadDependency_0_0 = $urandom;
    io_enq_0_bits_srcLoadDependency_0_1 = $urandom;
    io_enq_0_bits_srcLoadDependency_0_2 = $urandom;
    io_enq_0_bits_psrc_0 = $urandom;
    io_enq_0_bits_pdest = $urandom;
    io_enq_0_bits_useRegCache_0 = $urandom;
    io_enq_0_bits_regCacheIdx_0 = $urandom;
    io_enq_0_bits_robIdx_flag = $urandom;
    io_enq_0_bits_robIdx_value = $urandom;
    io_enq_0_bits_sqIdx_flag = $urandom;
    io_enq_0_bits_sqIdx_value = $urandom;
    io_enq_1_valid = $urandom;
    io_enq_1_bits_ftqPtr_value = $urandom;
    io_enq_1_bits_ftqOffset = $urandom;
    io_enq_1_bits_srcType_0 = $urandom;
    io_enq_1_bits_fuType = $urandom;
    io_enq_1_bits_fuOpType = $urandom;
    io_enq_1_bits_rfWen = $urandom;
    io_enq_1_bits_selImm = $urandom;
    io_enq_1_bits_imm = $urandom;
    io_enq_1_bits_srcState_0 = $urandom;
    io_enq_1_bits_srcLoadDependency_0_0 = $urandom;
    io_enq_1_bits_srcLoadDependency_0_1 = $urandom;
    io_enq_1_bits_srcLoadDependency_0_2 = $urandom;
    io_enq_1_bits_psrc_0 = $urandom;
    io_enq_1_bits_pdest = $urandom;
    io_enq_1_bits_useRegCache_0 = $urandom;
    io_enq_1_bits_regCacheIdx_0 = $urandom;
    io_enq_1_bits_robIdx_flag = $urandom;
    io_enq_1_bits_robIdx_value = $urandom;
    io_enq_1_bits_sqIdx_flag = $urandom;
    io_enq_1_bits_sqIdx_value = $urandom;
    io_og0Resp_0_valid = $urandom;
    io_og1Resp_0_valid = $urandom;
    io_og1Resp_0_bits_resp = $urandom;
    io_wakeupFromWB_3_valid = $urandom;
    io_wakeupFromWB_3_bits_rfWen = $urandom;
    io_wakeupFromWB_3_bits_pdest = $urandom;
    io_wakeupFromWB_2_valid = $urandom;
    io_wakeupFromWB_2_bits_rfWen = $urandom;
    io_wakeupFromWB_2_bits_pdest = $urandom;
    io_wakeupFromWB_1_valid = $urandom;
    io_wakeupFromWB_1_bits_rfWen = $urandom;
    io_wakeupFromWB_1_bits_pdest = $urandom;
    io_wakeupFromWB_0_valid = $urandom;
    io_wakeupFromWB_0_bits_rfWen = $urandom;
    io_wakeupFromWB_0_bits_pdest = $urandom;
    io_wakeupFromIQ_6_bits_rfWen = $urandom;
    io_wakeupFromIQ_6_bits_pdest = $urandom;
    io_wakeupFromIQ_6_bits_rcDest = $urandom;
    io_wakeupFromIQ_5_bits_rfWen = $urandom;
    io_wakeupFromIQ_5_bits_pdest = $urandom;
    io_wakeupFromIQ_5_bits_rcDest = $urandom;
    io_wakeupFromIQ_4_bits_rfWen = $urandom;
    io_wakeupFromIQ_4_bits_pdest = $urandom;
    io_wakeupFromIQ_4_bits_rcDest = $urandom;
    io_wakeupFromIQ_3_bits_rfWen = $urandom;
    io_wakeupFromIQ_3_bits_pdest = $urandom;
    io_wakeupFromIQ_3_bits_loadDependency_0 = $urandom;
    io_wakeupFromIQ_3_bits_loadDependency_1 = $urandom;
    io_wakeupFromIQ_3_bits_loadDependency_2 = $urandom;
    io_wakeupFromIQ_3_bits_rcDest = $urandom;
    io_wakeupFromIQ_2_bits_rfWen = $urandom;
    io_wakeupFromIQ_2_bits_pdest = $urandom;
    io_wakeupFromIQ_2_bits_loadDependency_0 = $urandom;
    io_wakeupFromIQ_2_bits_loadDependency_1 = $urandom;
    io_wakeupFromIQ_2_bits_loadDependency_2 = $urandom;
    io_wakeupFromIQ_2_bits_rcDest = $urandom;
    io_wakeupFromIQ_1_bits_rfWen = $urandom;
    io_wakeupFromIQ_1_bits_pdest = $urandom;
    io_wakeupFromIQ_1_bits_loadDependency_0 = $urandom;
    io_wakeupFromIQ_1_bits_loadDependency_1 = $urandom;
    io_wakeupFromIQ_1_bits_loadDependency_2 = $urandom;
    io_wakeupFromIQ_1_bits_is0Lat = $urandom;
    io_wakeupFromIQ_1_bits_rcDest = $urandom;
    io_wakeupFromIQ_0_bits_rfWen = $urandom;
    io_wakeupFromIQ_0_bits_pdest = $urandom;
    io_wakeupFromIQ_0_bits_loadDependency_0 = $urandom;
    io_wakeupFromIQ_0_bits_loadDependency_1 = $urandom;
    io_wakeupFromIQ_0_bits_loadDependency_2 = $urandom;
    io_wakeupFromIQ_0_bits_is0Lat = $urandom;
    io_wakeupFromIQ_0_bits_rcDest = $urandom;
    io_wakeupFromWBDelayed_3_valid = $urandom;
    io_wakeupFromWBDelayed_3_bits_rfWen = $urandom;
    io_wakeupFromWBDelayed_3_bits_pdest = $urandom;
    io_wakeupFromWBDelayed_2_valid = $urandom;
    io_wakeupFromWBDelayed_2_bits_rfWen = $urandom;
    io_wakeupFromWBDelayed_2_bits_pdest = $urandom;
    io_wakeupFromWBDelayed_1_valid = $urandom;
    io_wakeupFromWBDelayed_1_bits_rfWen = $urandom;
    io_wakeupFromWBDelayed_1_bits_pdest = $urandom;
    io_wakeupFromWBDelayed_0_valid = $urandom;
    io_wakeupFromWBDelayed_0_bits_rfWen = $urandom;
    io_wakeupFromWBDelayed_0_bits_pdest = $urandom;
    io_wakeupFromIQDelayed_6_bits_rfWen = $urandom;
    io_wakeupFromIQDelayed_6_bits_pdest = $urandom;
    io_wakeupFromIQDelayed_6_bits_rcDest = $urandom;
    io_wakeupFromIQDelayed_5_bits_rfWen = $urandom;
    io_wakeupFromIQDelayed_5_bits_pdest = $urandom;
    io_wakeupFromIQDelayed_5_bits_rcDest = $urandom;
    io_wakeupFromIQDelayed_4_bits_rfWen = $urandom;
    io_wakeupFromIQDelayed_4_bits_pdest = $urandom;
    io_wakeupFromIQDelayed_4_bits_rcDest = $urandom;
    io_wakeupFromIQDelayed_3_bits_rfWen = $urandom;
    io_wakeupFromIQDelayed_3_bits_pdest = $urandom;
    io_wakeupFromIQDelayed_3_bits_loadDependency_0 = $urandom;
    io_wakeupFromIQDelayed_3_bits_loadDependency_1 = $urandom;
    io_wakeupFromIQDelayed_3_bits_loadDependency_2 = $urandom;
    io_wakeupFromIQDelayed_3_bits_rcDest = $urandom;
    io_wakeupFromIQDelayed_2_bits_rfWen = $urandom;
    io_wakeupFromIQDelayed_2_bits_pdest = $urandom;
    io_wakeupFromIQDelayed_2_bits_loadDependency_0 = $urandom;
    io_wakeupFromIQDelayed_2_bits_loadDependency_1 = $urandom;
    io_wakeupFromIQDelayed_2_bits_loadDependency_2 = $urandom;
    io_wakeupFromIQDelayed_2_bits_rcDest = $urandom;
    io_wakeupFromIQDelayed_1_bits_rfWen = $urandom;
    io_wakeupFromIQDelayed_1_bits_pdest = $urandom;
    io_wakeupFromIQDelayed_1_bits_loadDependency_0 = $urandom;
    io_wakeupFromIQDelayed_1_bits_loadDependency_1 = $urandom;
    io_wakeupFromIQDelayed_1_bits_loadDependency_2 = $urandom;
    io_wakeupFromIQDelayed_1_bits_is0Lat = $urandom;
    io_wakeupFromIQDelayed_1_bits_rcDest = $urandom;
    io_wakeupFromIQDelayed_0_bits_rfWen = $urandom;
    io_wakeupFromIQDelayed_0_bits_pdest = $urandom;
    io_wakeupFromIQDelayed_0_bits_loadDependency_0 = $urandom;
    io_wakeupFromIQDelayed_0_bits_loadDependency_1 = $urandom;
    io_wakeupFromIQDelayed_0_bits_loadDependency_2 = $urandom;
    io_wakeupFromIQDelayed_0_bits_is0Lat = $urandom;
    io_wakeupFromIQDelayed_0_bits_rcDest = $urandom;
    io_og0Cancel_0 = $urandom;
    io_og0Cancel_2 = $urandom;
    io_og0Cancel_4 = $urandom;
    io_og0Cancel_6 = $urandom;
    io_ldCancel_0_ld2Cancel = $urandom;
    io_ldCancel_1_ld2Cancel = $urandom;
    io_ldCancel_2_ld2Cancel = $urandom;
    io_deqDelay_0_ready = $urandom;
    io_memIO_feedbackIO_0_feedbackSlow_valid = $urandom;
    io_memIO_feedbackIO_0_feedbackSlow_bits_hit = $urandom;
    io_memIO_feedbackIO_0_feedbackSlow_bits_sqIdx_flag = $urandom;
    io_memIO_feedbackIO_0_feedbackSlow_bits_sqIdx_value = $urandom;
    // 适度降低各 valid/handshake 密度, 覆盖 enq/发射/背压/唤醒/mem feedback/重定向
    io_flush_valid = ($urandom % 4 == 0);
    io_enq_0_valid = ($urandom % 4 == 0);
    io_enq_1_valid = ($urandom % 4 == 0);
    io_wakeupFromWB_3_valid = ($urandom % 4 == 0);
    io_wakeupFromWB_2_valid = ($urandom % 4 == 0);
    io_wakeupFromWB_1_valid = ($urandom % 4 == 0);
    io_wakeupFromWB_0_valid = ($urandom % 4 == 0);
    io_wakeupFromWBDelayed_3_valid = ($urandom % 4 == 0);
    io_wakeupFromWBDelayed_2_valid = ($urandom % 4 == 0);
    io_wakeupFromWBDelayed_1_valid = ($urandom % 4 == 0);
    io_wakeupFromWBDelayed_0_valid = ($urandom % 4 == 0);
    io_memIO_feedbackIO_0_feedbackSlow_valid = ($urandom % 4 == 0);
    io_deqDelay_0_ready = ($urandom % 8 != 0);
    io_memIO_feedbackIO_0_feedbackSlow_valid = ($urandom % 6 == 0);
    if (no_flush) io_flush_valid = 1'b0;
    else io_flush_valid = ($urandom % 16 == 0);
  endtask
  task check();
    if (!$isunknown(g_io_enq_0_ready) && g_io_enq_0_ready !== i_io_enq_0_ready) begin errors++;
      if(errors<=120) $display("[%0t] io_enq_0_ready g=%h i=%h", $time, g_io_enq_0_ready, i_io_enq_0_ready); end
    if (!$isunknown(g_io_enq_1_ready) && g_io_enq_1_ready !== i_io_enq_1_ready) begin errors++;
      if(errors<=120) $display("[%0t] io_enq_1_ready g=%h i=%h", $time, g_io_enq_1_ready, i_io_enq_1_ready); end
    if (!$isunknown(g_io_validCntDeqVec_0) && g_io_validCntDeqVec_0 !== i_io_validCntDeqVec_0) begin errors++;
      if(errors<=120) $display("[%0t] io_validCntDeqVec_0 g=%h i=%h", $time, g_io_validCntDeqVec_0, i_io_validCntDeqVec_0); end
    if (!$isunknown(g_io_deqDelay_0_valid) && g_io_deqDelay_0_valid !== i_io_deqDelay_0_valid) begin errors++;
      if(errors<=120) $display("[%0t] io_deqDelay_0_valid g=%h i=%h", $time, g_io_deqDelay_0_valid, i_io_deqDelay_0_valid); end
    if (!$isunknown(g_io_deqDelay_0_bits_rf_0_0_addr) && g_io_deqDelay_0_bits_rf_0_0_addr !== i_io_deqDelay_0_bits_rf_0_0_addr) begin errors++;
      if(errors<=120) $display("[%0t] io_deqDelay_0_bits_rf_0_0_addr g=%h i=%h", $time, g_io_deqDelay_0_bits_rf_0_0_addr, i_io_deqDelay_0_bits_rf_0_0_addr); end
    if (!$isunknown(g_io_deqDelay_0_bits_rcIdx_0) && g_io_deqDelay_0_bits_rcIdx_0 !== i_io_deqDelay_0_bits_rcIdx_0) begin errors++;
      if(errors<=120) $display("[%0t] io_deqDelay_0_bits_rcIdx_0 g=%h i=%h", $time, g_io_deqDelay_0_bits_rcIdx_0, i_io_deqDelay_0_bits_rcIdx_0); end
    if (!$isunknown(g_io_deqDelay_0_bits_immType) && g_io_deqDelay_0_bits_immType !== i_io_deqDelay_0_bits_immType) begin errors++;
      if(errors<=120) $display("[%0t] io_deqDelay_0_bits_immType g=%h i=%h", $time, g_io_deqDelay_0_bits_immType, i_io_deqDelay_0_bits_immType); end
    if (!$isunknown(g_io_deqDelay_0_bits_common_fuType) && g_io_deqDelay_0_bits_common_fuType !== i_io_deqDelay_0_bits_common_fuType) begin errors++;
      if(errors<=120) $display("[%0t] io_deqDelay_0_bits_common_fuType g=%h i=%h", $time, g_io_deqDelay_0_bits_common_fuType, i_io_deqDelay_0_bits_common_fuType); end
    if (!$isunknown(g_io_deqDelay_0_bits_common_fuOpType) && g_io_deqDelay_0_bits_common_fuOpType !== i_io_deqDelay_0_bits_common_fuOpType) begin errors++;
      if(errors<=120) $display("[%0t] io_deqDelay_0_bits_common_fuOpType g=%h i=%h", $time, g_io_deqDelay_0_bits_common_fuOpType, i_io_deqDelay_0_bits_common_fuOpType); end
    if (!$isunknown(g_io_deqDelay_0_bits_common_imm) && g_io_deqDelay_0_bits_common_imm !== i_io_deqDelay_0_bits_common_imm) begin errors++;
      if(errors<=120) $display("[%0t] io_deqDelay_0_bits_common_imm g=%h i=%h", $time, g_io_deqDelay_0_bits_common_imm, i_io_deqDelay_0_bits_common_imm); end
    if (!$isunknown(g_io_deqDelay_0_bits_common_robIdx_flag) && g_io_deqDelay_0_bits_common_robIdx_flag !== i_io_deqDelay_0_bits_common_robIdx_flag) begin errors++;
      if(errors<=120) $display("[%0t] io_deqDelay_0_bits_common_robIdx_flag g=%h i=%h", $time, g_io_deqDelay_0_bits_common_robIdx_flag, i_io_deqDelay_0_bits_common_robIdx_flag); end
    if (!$isunknown(g_io_deqDelay_0_bits_common_robIdx_value) && g_io_deqDelay_0_bits_common_robIdx_value !== i_io_deqDelay_0_bits_common_robIdx_value) begin errors++;
      if(errors<=120) $display("[%0t] io_deqDelay_0_bits_common_robIdx_value g=%h i=%h", $time, g_io_deqDelay_0_bits_common_robIdx_value, i_io_deqDelay_0_bits_common_robIdx_value); end
    if (!$isunknown(g_io_deqDelay_0_bits_common_isFirstIssue) && g_io_deqDelay_0_bits_common_isFirstIssue !== i_io_deqDelay_0_bits_common_isFirstIssue) begin errors++;
      if(errors<=120) $display("[%0t] io_deqDelay_0_bits_common_isFirstIssue g=%h i=%h", $time, g_io_deqDelay_0_bits_common_isFirstIssue, i_io_deqDelay_0_bits_common_isFirstIssue); end
    if (!$isunknown(g_io_deqDelay_0_bits_common_pdest) && g_io_deqDelay_0_bits_common_pdest !== i_io_deqDelay_0_bits_common_pdest) begin errors++;
      if(errors<=120) $display("[%0t] io_deqDelay_0_bits_common_pdest g=%h i=%h", $time, g_io_deqDelay_0_bits_common_pdest, i_io_deqDelay_0_bits_common_pdest); end
    if (!$isunknown(g_io_deqDelay_0_bits_common_rfWen) && g_io_deqDelay_0_bits_common_rfWen !== i_io_deqDelay_0_bits_common_rfWen) begin errors++;
      if(errors<=120) $display("[%0t] io_deqDelay_0_bits_common_rfWen g=%h i=%h", $time, g_io_deqDelay_0_bits_common_rfWen, i_io_deqDelay_0_bits_common_rfWen); end
    if (!$isunknown(g_io_deqDelay_0_bits_common_ftqIdx_value) && g_io_deqDelay_0_bits_common_ftqIdx_value !== i_io_deqDelay_0_bits_common_ftqIdx_value) begin errors++;
      if(errors<=120) $display("[%0t] io_deqDelay_0_bits_common_ftqIdx_value g=%h i=%h", $time, g_io_deqDelay_0_bits_common_ftqIdx_value, i_io_deqDelay_0_bits_common_ftqIdx_value); end
    if (!$isunknown(g_io_deqDelay_0_bits_common_ftqOffset) && g_io_deqDelay_0_bits_common_ftqOffset !== i_io_deqDelay_0_bits_common_ftqOffset) begin errors++;
      if(errors<=120) $display("[%0t] io_deqDelay_0_bits_common_ftqOffset g=%h i=%h", $time, g_io_deqDelay_0_bits_common_ftqOffset, i_io_deqDelay_0_bits_common_ftqOffset); end
    if (!$isunknown(g_io_deqDelay_0_bits_common_sqIdx_flag) && g_io_deqDelay_0_bits_common_sqIdx_flag !== i_io_deqDelay_0_bits_common_sqIdx_flag) begin errors++;
      if(errors<=120) $display("[%0t] io_deqDelay_0_bits_common_sqIdx_flag g=%h i=%h", $time, g_io_deqDelay_0_bits_common_sqIdx_flag, i_io_deqDelay_0_bits_common_sqIdx_flag); end
    if (!$isunknown(g_io_deqDelay_0_bits_common_sqIdx_value) && g_io_deqDelay_0_bits_common_sqIdx_value !== i_io_deqDelay_0_bits_common_sqIdx_value) begin errors++;
      if(errors<=120) $display("[%0t] io_deqDelay_0_bits_common_sqIdx_value g=%h i=%h", $time, g_io_deqDelay_0_bits_common_sqIdx_value, i_io_deqDelay_0_bits_common_sqIdx_value); end
    if (!$isunknown(g_io_deqDelay_0_bits_common_dataSources_0_value) && g_io_deqDelay_0_bits_common_dataSources_0_value !== i_io_deqDelay_0_bits_common_dataSources_0_value) begin errors++;
      if(errors<=120) $display("[%0t] io_deqDelay_0_bits_common_dataSources_0_value g=%h i=%h", $time, g_io_deqDelay_0_bits_common_dataSources_0_value, i_io_deqDelay_0_bits_common_dataSources_0_value); end
    if (!$isunknown(g_io_deqDelay_0_bits_common_exuSources_0_value) && g_io_deqDelay_0_bits_common_exuSources_0_value !== i_io_deqDelay_0_bits_common_exuSources_0_value) begin errors++;
      if(errors<=120) $display("[%0t] io_deqDelay_0_bits_common_exuSources_0_value g=%h i=%h", $time, g_io_deqDelay_0_bits_common_exuSources_0_value, i_io_deqDelay_0_bits_common_exuSources_0_value); end
    if (!$isunknown(g_io_deqDelay_0_bits_common_loadDependency_0) && g_io_deqDelay_0_bits_common_loadDependency_0 !== i_io_deqDelay_0_bits_common_loadDependency_0) begin errors++;
      if(errors<=120) $display("[%0t] io_deqDelay_0_bits_common_loadDependency_0 g=%h i=%h", $time, g_io_deqDelay_0_bits_common_loadDependency_0, i_io_deqDelay_0_bits_common_loadDependency_0); end
    if (!$isunknown(g_io_deqDelay_0_bits_common_loadDependency_1) && g_io_deqDelay_0_bits_common_loadDependency_1 !== i_io_deqDelay_0_bits_common_loadDependency_1) begin errors++;
      if(errors<=120) $display("[%0t] io_deqDelay_0_bits_common_loadDependency_1 g=%h i=%h", $time, g_io_deqDelay_0_bits_common_loadDependency_1, i_io_deqDelay_0_bits_common_loadDependency_1); end
    if (!$isunknown(g_io_deqDelay_0_bits_common_loadDependency_2) && g_io_deqDelay_0_bits_common_loadDependency_2 !== i_io_deqDelay_0_bits_common_loadDependency_2) begin errors++;
      if(errors<=120) $display("[%0t] io_deqDelay_0_bits_common_loadDependency_2 g=%h i=%h", $time, g_io_deqDelay_0_bits_common_loadDependency_2, i_io_deqDelay_0_bits_common_loadDependency_2); end
    checks++;
  endtask
  initial begin
    no_flush = $test$plusargs("NO_FLUSH");
    rst = 1; drive_rand();
    repeat (16) @(posedge clk); rst = 0;
    repeat (NCYCLES) begin
      @(negedge clk); drive_rand();
      @(posedge clk); #1 check();
    end
    $display("checks=%0d errors=%0d", checks, errors);
    if (errors==0 && checks>1000) $display("TEST PASSED"); else $display("TEST FAILED");
    $finish;
  end
endmodule
