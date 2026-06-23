// 自动生成:scripts/gen_iq_ffmac.py —— 勿手改
// EntriesFaluFmac golden 同名扁平 wrapper —— 例化可读核 xs_EntriesFaluFmac_core。
module EntriesFaluFmac import iq_ffmac_pkg::*; (
  input  clock,
  input  reset,
  input  io_flush_valid,
  input  io_flush_bits_robIdx_flag,
  input  [7:0] io_flush_bits_robIdx_value,
  input  io_flush_bits_level,
  input  io_enq_0_valid,
  input  io_enq_0_bits_status_robIdx_flag,
  input  [7:0] io_enq_0_bits_status_robIdx_value,
  input  io_enq_0_bits_status_fuType_11,
  input  io_enq_0_bits_status_fuType_12,
  input  [7:0] io_enq_0_bits_status_srcStatus_0_psrc,
  input  [3:0] io_enq_0_bits_status_srcStatus_0_srcType,
  input  io_enq_0_bits_status_srcStatus_0_srcState,
  input  [3:0] io_enq_0_bits_status_srcStatus_0_dataSources_value,
  input  [7:0] io_enq_0_bits_status_srcStatus_1_psrc,
  input  [3:0] io_enq_0_bits_status_srcStatus_1_srcType,
  input  io_enq_0_bits_status_srcStatus_1_srcState,
  input  [3:0] io_enq_0_bits_status_srcStatus_1_dataSources_value,
  input  [7:0] io_enq_0_bits_status_srcStatus_2_psrc,
  input  [3:0] io_enq_0_bits_status_srcStatus_2_srcType,
  input  io_enq_0_bits_status_srcStatus_2_srcState,
  input  [3:0] io_enq_0_bits_status_srcStatus_2_dataSources_value,
  input  [8:0] io_enq_0_bits_payload_fuOpType,
  input  io_enq_0_bits_payload_rfWen,
  input  io_enq_0_bits_payload_fpWen,
  input  io_enq_0_bits_payload_fpu_wflags,
  input  [1:0] io_enq_0_bits_payload_fpu_fmt,
  input  [2:0] io_enq_0_bits_payload_fpu_rm,
  input  [7:0] io_enq_0_bits_payload_pdest,
  input  io_enq_1_valid,
  input  io_enq_1_bits_status_robIdx_flag,
  input  [7:0] io_enq_1_bits_status_robIdx_value,
  input  io_enq_1_bits_status_fuType_11,
  input  io_enq_1_bits_status_fuType_12,
  input  [7:0] io_enq_1_bits_status_srcStatus_0_psrc,
  input  [3:0] io_enq_1_bits_status_srcStatus_0_srcType,
  input  io_enq_1_bits_status_srcStatus_0_srcState,
  input  [3:0] io_enq_1_bits_status_srcStatus_0_dataSources_value,
  input  [7:0] io_enq_1_bits_status_srcStatus_1_psrc,
  input  [3:0] io_enq_1_bits_status_srcStatus_1_srcType,
  input  io_enq_1_bits_status_srcStatus_1_srcState,
  input  [3:0] io_enq_1_bits_status_srcStatus_1_dataSources_value,
  input  [7:0] io_enq_1_bits_status_srcStatus_2_psrc,
  input  [3:0] io_enq_1_bits_status_srcStatus_2_srcType,
  input  io_enq_1_bits_status_srcStatus_2_srcState,
  input  [3:0] io_enq_1_bits_status_srcStatus_2_dataSources_value,
  input  [8:0] io_enq_1_bits_payload_fuOpType,
  input  io_enq_1_bits_payload_rfWen,
  input  io_enq_1_bits_payload_fpWen,
  input  io_enq_1_bits_payload_fpu_wflags,
  input  [1:0] io_enq_1_bits_payload_fpu_fmt,
  input  [2:0] io_enq_1_bits_payload_fpu_rm,
  input  [7:0] io_enq_1_bits_payload_pdest,
  input  io_og0Resp_0_valid,
  input  io_og1Resp_0_valid,
  input  io_deqSelOH_0_valid,
  input  [17:0] io_deqSelOH_0_bits,
  input  [1:0] io_enqEntryOldestSel_0_bits,
  input  io_simpEntryOldestSel_0_valid,
  input  [1:0] io_simpEntryOldestSel_0_bits,
  input  io_compEntryOldestSel_0_valid,
  input  [13:0] io_compEntryOldestSel_0_bits,
  input  io_wakeUpFromWB_5_valid,
  input  io_wakeUpFromWB_5_bits_fpWen,
  input  [7:0] io_wakeUpFromWB_5_bits_pdest,
  input  io_wakeUpFromWB_4_valid,
  input  io_wakeUpFromWB_4_bits_fpWen,
  input  [7:0] io_wakeUpFromWB_4_bits_pdest,
  input  io_wakeUpFromWB_3_valid,
  input  io_wakeUpFromWB_3_bits_fpWen,
  input  [7:0] io_wakeUpFromWB_3_bits_pdest,
  input  io_wakeUpFromWB_2_valid,
  input  io_wakeUpFromWB_2_bits_fpWen,
  input  [7:0] io_wakeUpFromWB_2_bits_pdest,
  input  io_wakeUpFromWB_1_valid,
  input  io_wakeUpFromWB_1_bits_fpWen,
  input  [7:0] io_wakeUpFromWB_1_bits_pdest,
  input  io_wakeUpFromWB_0_valid,
  input  io_wakeUpFromWB_0_bits_fpWen,
  input  [7:0] io_wakeUpFromWB_0_bits_pdest,
  input  io_wakeUpFromIQ_2_bits_fpWen,
  input  [7:0] io_wakeUpFromIQ_2_bits_pdest,
  input  io_wakeUpFromIQ_1_bits_fpWen,
  input  [7:0] io_wakeUpFromIQ_1_bits_pdest,
  input  io_wakeUpFromIQ_0_bits_fpWen,
  input  [7:0] io_wakeUpFromIQ_0_bits_pdest,
  input  io_wakeUpFromIQ_0_bits_is0Lat,
  input  io_wakeUpFromWBDelayed_5_valid,
  input  io_wakeUpFromWBDelayed_5_bits_fpWen,
  input  [7:0] io_wakeUpFromWBDelayed_5_bits_pdest,
  input  io_wakeUpFromWBDelayed_4_valid,
  input  io_wakeUpFromWBDelayed_4_bits_fpWen,
  input  [7:0] io_wakeUpFromWBDelayed_4_bits_pdest,
  input  io_wakeUpFromWBDelayed_3_valid,
  input  io_wakeUpFromWBDelayed_3_bits_fpWen,
  input  [7:0] io_wakeUpFromWBDelayed_3_bits_pdest,
  input  io_wakeUpFromWBDelayed_2_valid,
  input  io_wakeUpFromWBDelayed_2_bits_fpWen,
  input  [7:0] io_wakeUpFromWBDelayed_2_bits_pdest,
  input  io_wakeUpFromWBDelayed_1_valid,
  input  io_wakeUpFromWBDelayed_1_bits_fpWen,
  input  [7:0] io_wakeUpFromWBDelayed_1_bits_pdest,
  input  io_wakeUpFromWBDelayed_0_valid,
  input  io_wakeUpFromWBDelayed_0_bits_fpWen,
  input  [7:0] io_wakeUpFromWBDelayed_0_bits_pdest,
  input  io_wakeUpFromIQDelayed_2_bits_fpWen,
  input  [7:0] io_wakeUpFromIQDelayed_2_bits_pdest,
  input  io_wakeUpFromIQDelayed_1_bits_fpWen,
  input  [7:0] io_wakeUpFromIQDelayed_1_bits_pdest,
  input  io_wakeUpFromIQDelayed_0_bits_fpWen,
  input  [7:0] io_wakeUpFromIQDelayed_0_bits_pdest,
  input  io_wakeUpFromIQDelayed_0_bits_is0Lat,
  input  io_og0Cancel_8,
  output [17:0] io_valid,
  output [17:0] io_issued,
  output [17:0] io_canIssue,
  output [34:0] io_fuType_0,
  output [34:0] io_fuType_1,
  output [34:0] io_fuType_2,
  output [34:0] io_fuType_3,
  output [34:0] io_fuType_4,
  output [34:0] io_fuType_5,
  output [34:0] io_fuType_6,
  output [34:0] io_fuType_7,
  output [34:0] io_fuType_8,
  output [34:0] io_fuType_9,
  output [34:0] io_fuType_10,
  output [34:0] io_fuType_11,
  output [34:0] io_fuType_12,
  output [34:0] io_fuType_13,
  output [34:0] io_fuType_14,
  output [34:0] io_fuType_15,
  output [34:0] io_fuType_16,
  output [34:0] io_fuType_17,
  output [3:0] io_dataSources_0_0_value,
  output [3:0] io_dataSources_0_1_value,
  output [3:0] io_dataSources_0_2_value,
  output [3:0] io_dataSources_1_0_value,
  output [3:0] io_dataSources_1_1_value,
  output [3:0] io_dataSources_1_2_value,
  output [3:0] io_dataSources_2_0_value,
  output [3:0] io_dataSources_2_1_value,
  output [3:0] io_dataSources_2_2_value,
  output [3:0] io_dataSources_3_0_value,
  output [3:0] io_dataSources_3_1_value,
  output [3:0] io_dataSources_3_2_value,
  output [3:0] io_dataSources_4_0_value,
  output [3:0] io_dataSources_4_1_value,
  output [3:0] io_dataSources_4_2_value,
  output [3:0] io_dataSources_5_0_value,
  output [3:0] io_dataSources_5_1_value,
  output [3:0] io_dataSources_5_2_value,
  output [3:0] io_dataSources_6_0_value,
  output [3:0] io_dataSources_6_1_value,
  output [3:0] io_dataSources_6_2_value,
  output [3:0] io_dataSources_7_0_value,
  output [3:0] io_dataSources_7_1_value,
  output [3:0] io_dataSources_7_2_value,
  output [3:0] io_dataSources_8_0_value,
  output [3:0] io_dataSources_8_1_value,
  output [3:0] io_dataSources_8_2_value,
  output [3:0] io_dataSources_9_0_value,
  output [3:0] io_dataSources_9_1_value,
  output [3:0] io_dataSources_9_2_value,
  output [3:0] io_dataSources_10_0_value,
  output [3:0] io_dataSources_10_1_value,
  output [3:0] io_dataSources_10_2_value,
  output [3:0] io_dataSources_11_0_value,
  output [3:0] io_dataSources_11_1_value,
  output [3:0] io_dataSources_11_2_value,
  output [3:0] io_dataSources_12_0_value,
  output [3:0] io_dataSources_12_1_value,
  output [3:0] io_dataSources_12_2_value,
  output [3:0] io_dataSources_13_0_value,
  output [3:0] io_dataSources_13_1_value,
  output [3:0] io_dataSources_13_2_value,
  output [3:0] io_dataSources_14_0_value,
  output [3:0] io_dataSources_14_1_value,
  output [3:0] io_dataSources_14_2_value,
  output [3:0] io_dataSources_15_0_value,
  output [3:0] io_dataSources_15_1_value,
  output [3:0] io_dataSources_15_2_value,
  output [3:0] io_dataSources_16_0_value,
  output [3:0] io_dataSources_16_1_value,
  output [3:0] io_dataSources_16_2_value,
  output [3:0] io_dataSources_17_0_value,
  output [3:0] io_dataSources_17_1_value,
  output [3:0] io_dataSources_17_2_value,
  output [1:0] io_exuSources_0_0_value,
  output [1:0] io_exuSources_0_1_value,
  output [1:0] io_exuSources_0_2_value,
  output [1:0] io_exuSources_1_0_value,
  output [1:0] io_exuSources_1_1_value,
  output [1:0] io_exuSources_1_2_value,
  output [1:0] io_exuSources_2_0_value,
  output [1:0] io_exuSources_2_1_value,
  output [1:0] io_exuSources_2_2_value,
  output [1:0] io_exuSources_3_0_value,
  output [1:0] io_exuSources_3_1_value,
  output [1:0] io_exuSources_3_2_value,
  output [1:0] io_exuSources_4_0_value,
  output [1:0] io_exuSources_4_1_value,
  output [1:0] io_exuSources_4_2_value,
  output [1:0] io_exuSources_5_0_value,
  output [1:0] io_exuSources_5_1_value,
  output [1:0] io_exuSources_5_2_value,
  output [1:0] io_exuSources_6_0_value,
  output [1:0] io_exuSources_6_1_value,
  output [1:0] io_exuSources_6_2_value,
  output [1:0] io_exuSources_7_0_value,
  output [1:0] io_exuSources_7_1_value,
  output [1:0] io_exuSources_7_2_value,
  output [1:0] io_exuSources_8_0_value,
  output [1:0] io_exuSources_8_1_value,
  output [1:0] io_exuSources_8_2_value,
  output [1:0] io_exuSources_9_0_value,
  output [1:0] io_exuSources_9_1_value,
  output [1:0] io_exuSources_9_2_value,
  output [1:0] io_exuSources_10_0_value,
  output [1:0] io_exuSources_10_1_value,
  output [1:0] io_exuSources_10_2_value,
  output [1:0] io_exuSources_11_0_value,
  output [1:0] io_exuSources_11_1_value,
  output [1:0] io_exuSources_11_2_value,
  output [1:0] io_exuSources_12_0_value,
  output [1:0] io_exuSources_12_1_value,
  output [1:0] io_exuSources_12_2_value,
  output [1:0] io_exuSources_13_0_value,
  output [1:0] io_exuSources_13_1_value,
  output [1:0] io_exuSources_13_2_value,
  output [1:0] io_exuSources_14_0_value,
  output [1:0] io_exuSources_14_1_value,
  output [1:0] io_exuSources_14_2_value,
  output [1:0] io_exuSources_15_0_value,
  output [1:0] io_exuSources_15_1_value,
  output [1:0] io_exuSources_15_2_value,
  output [1:0] io_exuSources_16_0_value,
  output [1:0] io_exuSources_16_1_value,
  output [1:0] io_exuSources_16_2_value,
  output [1:0] io_exuSources_17_0_value,
  output [1:0] io_exuSources_17_1_value,
  output [1:0] io_exuSources_17_2_value,
  output io_deqEntry_0_bits_status_robIdx_flag,
  output [7:0] io_deqEntry_0_bits_status_robIdx_value,
  output io_deqEntry_0_bits_status_fuType_11,
  output io_deqEntry_0_bits_status_fuType_12,
  output [7:0] io_deqEntry_0_bits_status_srcStatus_0_psrc,
  output [3:0] io_deqEntry_0_bits_status_srcStatus_0_srcType,
  output [7:0] io_deqEntry_0_bits_status_srcStatus_1_psrc,
  output [3:0] io_deqEntry_0_bits_status_srcStatus_1_srcType,
  output [7:0] io_deqEntry_0_bits_status_srcStatus_2_psrc,
  output [3:0] io_deqEntry_0_bits_status_srcStatus_2_srcType,
  output [8:0] io_deqEntry_0_bits_payload_fuOpType,
  output io_deqEntry_0_bits_payload_rfWen,
  output io_deqEntry_0_bits_payload_fpWen,
  output io_deqEntry_0_bits_payload_fpu_wflags,
  output [1:0] io_deqEntry_0_bits_payload_fpu_fmt,
  output [2:0] io_deqEntry_0_bits_payload_fpu_rm,
  output [7:0] io_deqEntry_0_bits_payload_pdest,
  input  [1:0] io_simpEntryDeqSelVec_0,
  input  [1:0] io_simpEntryDeqSelVec_1,
  output [1:0] io_simpEntryEnqSelVec_0,
  output [1:0] io_simpEntryEnqSelVec_1,
  output [13:0] io_compEntryEnqSelVec_0,
  output [13:0] io_compEntryEnqSelVec_1
);
  logic                 c_flush_valid, c_flush_rob_flag, c_flush_level;
  logic [7:0]           c_flush_rob_value;
  logic [1:0]           c_enq_valid;
  entry_t [1:0]         c_enq_bits;
  wk_wb_t [5:0]         c_wk_wb, c_wk_wb_d;
  wk_iq_t [2:0]         c_wk_iq, c_wk_iq_d;
  logic [26:0]          c_og0cancel;
  logic                 c_og0resp_valid, c_og1resp_valid;
  logic                 c_deq_sel_oh_valid;
  logic [17:0]          c_deq_sel_oh_bits;
  logic [1:0]           c_enq_oldest_sel_bits;
  logic                 c_simp_oldest_sel_valid, c_comp_oldest_sel_valid;
  logic [1:0]           c_simp_oldest_sel_bits;
  logic [13:0]          c_comp_oldest_sel_bits;
  logic [1:0][1:0]      c_simp_deq_sel_vec;
  logic [17:0]          c_valid, c_issued, c_can_issue;
  logic [17:0][34:0]    c_fu_type;
  logic [17:0][2:0][3:0] c_data_sources;
  logic [17:0][2:0][1:0] c_exu_sources;
  entry_t               c_deq_entry;
  logic                 c_cancel_deq;
  logic [1:0][1:0]      c_simp_enq_sel_vec;
  logic [1:0][13:0]     c_comp_enq_sel_vec;
  always_comb begin
    c_og0cancel = '0; // 仅 og0Cancel[8] 被引用,其余位置 0
    c_enq_bits = '0;
    c_wk_iq = '0; c_wk_iq_d = '0; c_wk_wb = '0; c_wk_wb_d = '0;
    c_flush_valid = io_flush_valid;
    c_flush_rob_flag = io_flush_bits_robIdx_flag;
    c_flush_rob_value = io_flush_bits_robIdx_value;
    c_flush_level = io_flush_bits_level;
    c_enq_valid[0] = io_enq_0_valid;
    c_enq_bits[0].status.rob_flag = io_enq_0_bits_status_robIdx_flag;
    c_enq_bits[0].status.rob_value = io_enq_0_bits_status_robIdx_value;
    c_enq_bits[0].status.fu_type[11] = io_enq_0_bits_status_fuType_11;
    c_enq_bits[0].status.fu_type[12] = io_enq_0_bits_status_fuType_12;
    c_enq_bits[0].status.src[0].psrc = io_enq_0_bits_status_srcStatus_0_psrc;
    c_enq_bits[0].status.src[0].src_type = io_enq_0_bits_status_srcStatus_0_srcType;
    c_enq_bits[0].status.src[0].src_state = io_enq_0_bits_status_srcStatus_0_srcState;
    c_enq_bits[0].status.src[0].data_src = io_enq_0_bits_status_srcStatus_0_dataSources_value;
    c_enq_bits[0].status.src[1].psrc = io_enq_0_bits_status_srcStatus_1_psrc;
    c_enq_bits[0].status.src[1].src_type = io_enq_0_bits_status_srcStatus_1_srcType;
    c_enq_bits[0].status.src[1].src_state = io_enq_0_bits_status_srcStatus_1_srcState;
    c_enq_bits[0].status.src[1].data_src = io_enq_0_bits_status_srcStatus_1_dataSources_value;
    c_enq_bits[0].status.src[2].psrc = io_enq_0_bits_status_srcStatus_2_psrc;
    c_enq_bits[0].status.src[2].src_type = io_enq_0_bits_status_srcStatus_2_srcType;
    c_enq_bits[0].status.src[2].src_state = io_enq_0_bits_status_srcStatus_2_srcState;
    c_enq_bits[0].status.src[2].data_src = io_enq_0_bits_status_srcStatus_2_dataSources_value;
    c_enq_bits[0].payload.fu_op_type = io_enq_0_bits_payload_fuOpType;
    c_enq_bits[0].payload.rf_wen = io_enq_0_bits_payload_rfWen;
    c_enq_bits[0].payload.fp_wen = io_enq_0_bits_payload_fpWen;
    c_enq_bits[0].payload.fpu_wflags = io_enq_0_bits_payload_fpu_wflags;
    c_enq_bits[0].payload.fpu_fmt = io_enq_0_bits_payload_fpu_fmt;
    c_enq_bits[0].payload.fpu_rm = io_enq_0_bits_payload_fpu_rm;
    c_enq_bits[0].payload.pdest = io_enq_0_bits_payload_pdest;
    c_enq_valid[1] = io_enq_1_valid;
    c_enq_bits[1].status.rob_flag = io_enq_1_bits_status_robIdx_flag;
    c_enq_bits[1].status.rob_value = io_enq_1_bits_status_robIdx_value;
    c_enq_bits[1].status.fu_type[11] = io_enq_1_bits_status_fuType_11;
    c_enq_bits[1].status.fu_type[12] = io_enq_1_bits_status_fuType_12;
    c_enq_bits[1].status.src[0].psrc = io_enq_1_bits_status_srcStatus_0_psrc;
    c_enq_bits[1].status.src[0].src_type = io_enq_1_bits_status_srcStatus_0_srcType;
    c_enq_bits[1].status.src[0].src_state = io_enq_1_bits_status_srcStatus_0_srcState;
    c_enq_bits[1].status.src[0].data_src = io_enq_1_bits_status_srcStatus_0_dataSources_value;
    c_enq_bits[1].status.src[1].psrc = io_enq_1_bits_status_srcStatus_1_psrc;
    c_enq_bits[1].status.src[1].src_type = io_enq_1_bits_status_srcStatus_1_srcType;
    c_enq_bits[1].status.src[1].src_state = io_enq_1_bits_status_srcStatus_1_srcState;
    c_enq_bits[1].status.src[1].data_src = io_enq_1_bits_status_srcStatus_1_dataSources_value;
    c_enq_bits[1].status.src[2].psrc = io_enq_1_bits_status_srcStatus_2_psrc;
    c_enq_bits[1].status.src[2].src_type = io_enq_1_bits_status_srcStatus_2_srcType;
    c_enq_bits[1].status.src[2].src_state = io_enq_1_bits_status_srcStatus_2_srcState;
    c_enq_bits[1].status.src[2].data_src = io_enq_1_bits_status_srcStatus_2_dataSources_value;
    c_enq_bits[1].payload.fu_op_type = io_enq_1_bits_payload_fuOpType;
    c_enq_bits[1].payload.rf_wen = io_enq_1_bits_payload_rfWen;
    c_enq_bits[1].payload.fp_wen = io_enq_1_bits_payload_fpWen;
    c_enq_bits[1].payload.fpu_wflags = io_enq_1_bits_payload_fpu_wflags;
    c_enq_bits[1].payload.fpu_fmt = io_enq_1_bits_payload_fpu_fmt;
    c_enq_bits[1].payload.fpu_rm = io_enq_1_bits_payload_fpu_rm;
    c_enq_bits[1].payload.pdest = io_enq_1_bits_payload_pdest;
    c_og0resp_valid = io_og0Resp_0_valid;
    c_og1resp_valid = io_og1Resp_0_valid;
    c_deq_sel_oh_valid = io_deqSelOH_0_valid;
    c_deq_sel_oh_bits = io_deqSelOH_0_bits;
    c_enq_oldest_sel_bits = io_enqEntryOldestSel_0_bits;
    c_simp_oldest_sel_valid = io_simpEntryOldestSel_0_valid;
    c_simp_oldest_sel_bits = io_simpEntryOldestSel_0_bits;
    c_comp_oldest_sel_valid = io_compEntryOldestSel_0_valid;
    c_comp_oldest_sel_bits = io_compEntryOldestSel_0_bits;
    c_wk_wb[5].valid = io_wakeUpFromWB_5_valid;
    c_wk_wb[5].fp_wen = io_wakeUpFromWB_5_bits_fpWen;
    c_wk_wb[5].pdest = io_wakeUpFromWB_5_bits_pdest;
    c_wk_wb[4].valid = io_wakeUpFromWB_4_valid;
    c_wk_wb[4].fp_wen = io_wakeUpFromWB_4_bits_fpWen;
    c_wk_wb[4].pdest = io_wakeUpFromWB_4_bits_pdest;
    c_wk_wb[3].valid = io_wakeUpFromWB_3_valid;
    c_wk_wb[3].fp_wen = io_wakeUpFromWB_3_bits_fpWen;
    c_wk_wb[3].pdest = io_wakeUpFromWB_3_bits_pdest;
    c_wk_wb[2].valid = io_wakeUpFromWB_2_valid;
    c_wk_wb[2].fp_wen = io_wakeUpFromWB_2_bits_fpWen;
    c_wk_wb[2].pdest = io_wakeUpFromWB_2_bits_pdest;
    c_wk_wb[1].valid = io_wakeUpFromWB_1_valid;
    c_wk_wb[1].fp_wen = io_wakeUpFromWB_1_bits_fpWen;
    c_wk_wb[1].pdest = io_wakeUpFromWB_1_bits_pdest;
    c_wk_wb[0].valid = io_wakeUpFromWB_0_valid;
    c_wk_wb[0].fp_wen = io_wakeUpFromWB_0_bits_fpWen;
    c_wk_wb[0].pdest = io_wakeUpFromWB_0_bits_pdest;
    c_wk_iq[2].fp_wen = io_wakeUpFromIQ_2_bits_fpWen;
    c_wk_iq[2].pdest = io_wakeUpFromIQ_2_bits_pdest;
    c_wk_iq[1].fp_wen = io_wakeUpFromIQ_1_bits_fpWen;
    c_wk_iq[1].pdest = io_wakeUpFromIQ_1_bits_pdest;
    c_wk_iq[0].fp_wen = io_wakeUpFromIQ_0_bits_fpWen;
    c_wk_iq[0].pdest = io_wakeUpFromIQ_0_bits_pdest;
    c_wk_iq[0].is0lat = io_wakeUpFromIQ_0_bits_is0Lat;
    c_wk_wb_d[5].valid = io_wakeUpFromWBDelayed_5_valid;
    c_wk_wb_d[5].fp_wen = io_wakeUpFromWBDelayed_5_bits_fpWen;
    c_wk_wb_d[5].pdest = io_wakeUpFromWBDelayed_5_bits_pdest;
    c_wk_wb_d[4].valid = io_wakeUpFromWBDelayed_4_valid;
    c_wk_wb_d[4].fp_wen = io_wakeUpFromWBDelayed_4_bits_fpWen;
    c_wk_wb_d[4].pdest = io_wakeUpFromWBDelayed_4_bits_pdest;
    c_wk_wb_d[3].valid = io_wakeUpFromWBDelayed_3_valid;
    c_wk_wb_d[3].fp_wen = io_wakeUpFromWBDelayed_3_bits_fpWen;
    c_wk_wb_d[3].pdest = io_wakeUpFromWBDelayed_3_bits_pdest;
    c_wk_wb_d[2].valid = io_wakeUpFromWBDelayed_2_valid;
    c_wk_wb_d[2].fp_wen = io_wakeUpFromWBDelayed_2_bits_fpWen;
    c_wk_wb_d[2].pdest = io_wakeUpFromWBDelayed_2_bits_pdest;
    c_wk_wb_d[1].valid = io_wakeUpFromWBDelayed_1_valid;
    c_wk_wb_d[1].fp_wen = io_wakeUpFromWBDelayed_1_bits_fpWen;
    c_wk_wb_d[1].pdest = io_wakeUpFromWBDelayed_1_bits_pdest;
    c_wk_wb_d[0].valid = io_wakeUpFromWBDelayed_0_valid;
    c_wk_wb_d[0].fp_wen = io_wakeUpFromWBDelayed_0_bits_fpWen;
    c_wk_wb_d[0].pdest = io_wakeUpFromWBDelayed_0_bits_pdest;
    c_wk_iq_d[2].fp_wen = io_wakeUpFromIQDelayed_2_bits_fpWen;
    c_wk_iq_d[2].pdest = io_wakeUpFromIQDelayed_2_bits_pdest;
    c_wk_iq_d[1].fp_wen = io_wakeUpFromIQDelayed_1_bits_fpWen;
    c_wk_iq_d[1].pdest = io_wakeUpFromIQDelayed_1_bits_pdest;
    c_wk_iq_d[0].fp_wen = io_wakeUpFromIQDelayed_0_bits_fpWen;
    c_wk_iq_d[0].pdest = io_wakeUpFromIQDelayed_0_bits_pdest;
    c_wk_iq_d[0].is0lat = io_wakeUpFromIQDelayed_0_bits_is0Lat;
    c_og0cancel[8] = io_og0Cancel_8;
    c_simp_deq_sel_vec[0] = io_simpEntryDeqSelVec_0;
    c_simp_deq_sel_vec[1] = io_simpEntryDeqSelVec_1;
  end
  assign io_valid = c_valid;
  assign io_issued = c_issued;
  assign io_canIssue = c_can_issue;
  assign io_fuType_0 = c_fu_type[0];
  assign io_fuType_1 = c_fu_type[1];
  assign io_fuType_2 = c_fu_type[2];
  assign io_fuType_3 = c_fu_type[3];
  assign io_fuType_4 = c_fu_type[4];
  assign io_fuType_5 = c_fu_type[5];
  assign io_fuType_6 = c_fu_type[6];
  assign io_fuType_7 = c_fu_type[7];
  assign io_fuType_8 = c_fu_type[8];
  assign io_fuType_9 = c_fu_type[9];
  assign io_fuType_10 = c_fu_type[10];
  assign io_fuType_11 = c_fu_type[11];
  assign io_fuType_12 = c_fu_type[12];
  assign io_fuType_13 = c_fu_type[13];
  assign io_fuType_14 = c_fu_type[14];
  assign io_fuType_15 = c_fu_type[15];
  assign io_fuType_16 = c_fu_type[16];
  assign io_fuType_17 = c_fu_type[17];
  assign io_dataSources_0_0_value = c_data_sources[0][0];
  assign io_dataSources_0_1_value = c_data_sources[0][1];
  assign io_dataSources_0_2_value = c_data_sources[0][2];
  assign io_dataSources_1_0_value = c_data_sources[1][0];
  assign io_dataSources_1_1_value = c_data_sources[1][1];
  assign io_dataSources_1_2_value = c_data_sources[1][2];
  assign io_dataSources_2_0_value = c_data_sources[2][0];
  assign io_dataSources_2_1_value = c_data_sources[2][1];
  assign io_dataSources_2_2_value = c_data_sources[2][2];
  assign io_dataSources_3_0_value = c_data_sources[3][0];
  assign io_dataSources_3_1_value = c_data_sources[3][1];
  assign io_dataSources_3_2_value = c_data_sources[3][2];
  assign io_dataSources_4_0_value = c_data_sources[4][0];
  assign io_dataSources_4_1_value = c_data_sources[4][1];
  assign io_dataSources_4_2_value = c_data_sources[4][2];
  assign io_dataSources_5_0_value = c_data_sources[5][0];
  assign io_dataSources_5_1_value = c_data_sources[5][1];
  assign io_dataSources_5_2_value = c_data_sources[5][2];
  assign io_dataSources_6_0_value = c_data_sources[6][0];
  assign io_dataSources_6_1_value = c_data_sources[6][1];
  assign io_dataSources_6_2_value = c_data_sources[6][2];
  assign io_dataSources_7_0_value = c_data_sources[7][0];
  assign io_dataSources_7_1_value = c_data_sources[7][1];
  assign io_dataSources_7_2_value = c_data_sources[7][2];
  assign io_dataSources_8_0_value = c_data_sources[8][0];
  assign io_dataSources_8_1_value = c_data_sources[8][1];
  assign io_dataSources_8_2_value = c_data_sources[8][2];
  assign io_dataSources_9_0_value = c_data_sources[9][0];
  assign io_dataSources_9_1_value = c_data_sources[9][1];
  assign io_dataSources_9_2_value = c_data_sources[9][2];
  assign io_dataSources_10_0_value = c_data_sources[10][0];
  assign io_dataSources_10_1_value = c_data_sources[10][1];
  assign io_dataSources_10_2_value = c_data_sources[10][2];
  assign io_dataSources_11_0_value = c_data_sources[11][0];
  assign io_dataSources_11_1_value = c_data_sources[11][1];
  assign io_dataSources_11_2_value = c_data_sources[11][2];
  assign io_dataSources_12_0_value = c_data_sources[12][0];
  assign io_dataSources_12_1_value = c_data_sources[12][1];
  assign io_dataSources_12_2_value = c_data_sources[12][2];
  assign io_dataSources_13_0_value = c_data_sources[13][0];
  assign io_dataSources_13_1_value = c_data_sources[13][1];
  assign io_dataSources_13_2_value = c_data_sources[13][2];
  assign io_dataSources_14_0_value = c_data_sources[14][0];
  assign io_dataSources_14_1_value = c_data_sources[14][1];
  assign io_dataSources_14_2_value = c_data_sources[14][2];
  assign io_dataSources_15_0_value = c_data_sources[15][0];
  assign io_dataSources_15_1_value = c_data_sources[15][1];
  assign io_dataSources_15_2_value = c_data_sources[15][2];
  assign io_dataSources_16_0_value = c_data_sources[16][0];
  assign io_dataSources_16_1_value = c_data_sources[16][1];
  assign io_dataSources_16_2_value = c_data_sources[16][2];
  assign io_dataSources_17_0_value = c_data_sources[17][0];
  assign io_dataSources_17_1_value = c_data_sources[17][1];
  assign io_dataSources_17_2_value = c_data_sources[17][2];
  assign io_exuSources_0_0_value = c_exu_sources[0][0];
  assign io_exuSources_0_1_value = c_exu_sources[0][1];
  assign io_exuSources_0_2_value = c_exu_sources[0][2];
  assign io_exuSources_1_0_value = c_exu_sources[1][0];
  assign io_exuSources_1_1_value = c_exu_sources[1][1];
  assign io_exuSources_1_2_value = c_exu_sources[1][2];
  assign io_exuSources_2_0_value = c_exu_sources[2][0];
  assign io_exuSources_2_1_value = c_exu_sources[2][1];
  assign io_exuSources_2_2_value = c_exu_sources[2][2];
  assign io_exuSources_3_0_value = c_exu_sources[3][0];
  assign io_exuSources_3_1_value = c_exu_sources[3][1];
  assign io_exuSources_3_2_value = c_exu_sources[3][2];
  assign io_exuSources_4_0_value = c_exu_sources[4][0];
  assign io_exuSources_4_1_value = c_exu_sources[4][1];
  assign io_exuSources_4_2_value = c_exu_sources[4][2];
  assign io_exuSources_5_0_value = c_exu_sources[5][0];
  assign io_exuSources_5_1_value = c_exu_sources[5][1];
  assign io_exuSources_5_2_value = c_exu_sources[5][2];
  assign io_exuSources_6_0_value = c_exu_sources[6][0];
  assign io_exuSources_6_1_value = c_exu_sources[6][1];
  assign io_exuSources_6_2_value = c_exu_sources[6][2];
  assign io_exuSources_7_0_value = c_exu_sources[7][0];
  assign io_exuSources_7_1_value = c_exu_sources[7][1];
  assign io_exuSources_7_2_value = c_exu_sources[7][2];
  assign io_exuSources_8_0_value = c_exu_sources[8][0];
  assign io_exuSources_8_1_value = c_exu_sources[8][1];
  assign io_exuSources_8_2_value = c_exu_sources[8][2];
  assign io_exuSources_9_0_value = c_exu_sources[9][0];
  assign io_exuSources_9_1_value = c_exu_sources[9][1];
  assign io_exuSources_9_2_value = c_exu_sources[9][2];
  assign io_exuSources_10_0_value = c_exu_sources[10][0];
  assign io_exuSources_10_1_value = c_exu_sources[10][1];
  assign io_exuSources_10_2_value = c_exu_sources[10][2];
  assign io_exuSources_11_0_value = c_exu_sources[11][0];
  assign io_exuSources_11_1_value = c_exu_sources[11][1];
  assign io_exuSources_11_2_value = c_exu_sources[11][2];
  assign io_exuSources_12_0_value = c_exu_sources[12][0];
  assign io_exuSources_12_1_value = c_exu_sources[12][1];
  assign io_exuSources_12_2_value = c_exu_sources[12][2];
  assign io_exuSources_13_0_value = c_exu_sources[13][0];
  assign io_exuSources_13_1_value = c_exu_sources[13][1];
  assign io_exuSources_13_2_value = c_exu_sources[13][2];
  assign io_exuSources_14_0_value = c_exu_sources[14][0];
  assign io_exuSources_14_1_value = c_exu_sources[14][1];
  assign io_exuSources_14_2_value = c_exu_sources[14][2];
  assign io_exuSources_15_0_value = c_exu_sources[15][0];
  assign io_exuSources_15_1_value = c_exu_sources[15][1];
  assign io_exuSources_15_2_value = c_exu_sources[15][2];
  assign io_exuSources_16_0_value = c_exu_sources[16][0];
  assign io_exuSources_16_1_value = c_exu_sources[16][1];
  assign io_exuSources_16_2_value = c_exu_sources[16][2];
  assign io_exuSources_17_0_value = c_exu_sources[17][0];
  assign io_exuSources_17_1_value = c_exu_sources[17][1];
  assign io_exuSources_17_2_value = c_exu_sources[17][2];
  assign io_deqEntry_0_bits_status_robIdx_flag = c_deq_entry.status.rob_flag;
  assign io_deqEntry_0_bits_status_robIdx_value = c_deq_entry.status.rob_value;
  assign io_deqEntry_0_bits_status_fuType_11 = c_deq_entry.status.fu_type[11];
  assign io_deqEntry_0_bits_status_fuType_12 = c_deq_entry.status.fu_type[12];
  assign io_deqEntry_0_bits_status_srcStatus_0_psrc = c_deq_entry.status.src[0].psrc;
  assign io_deqEntry_0_bits_status_srcStatus_0_srcType = c_deq_entry.status.src[0].src_type;
  assign io_deqEntry_0_bits_status_srcStatus_1_psrc = c_deq_entry.status.src[1].psrc;
  assign io_deqEntry_0_bits_status_srcStatus_1_srcType = c_deq_entry.status.src[1].src_type;
  assign io_deqEntry_0_bits_status_srcStatus_2_psrc = c_deq_entry.status.src[2].psrc;
  assign io_deqEntry_0_bits_status_srcStatus_2_srcType = c_deq_entry.status.src[2].src_type;
  assign io_deqEntry_0_bits_payload_fuOpType = c_deq_entry.payload.fu_op_type;
  assign io_deqEntry_0_bits_payload_rfWen = c_deq_entry.payload.rf_wen;
  assign io_deqEntry_0_bits_payload_fpWen = c_deq_entry.payload.fp_wen;
  assign io_deqEntry_0_bits_payload_fpu_wflags = c_deq_entry.payload.fpu_wflags;
  assign io_deqEntry_0_bits_payload_fpu_fmt = c_deq_entry.payload.fpu_fmt;
  assign io_deqEntry_0_bits_payload_fpu_rm = c_deq_entry.payload.fpu_rm;
  assign io_deqEntry_0_bits_payload_pdest = c_deq_entry.payload.pdest;
  assign io_simpEntryEnqSelVec_0 = c_simp_enq_sel_vec[0];
  assign io_simpEntryEnqSelVec_1 = c_simp_enq_sel_vec[1];
  assign io_compEntryEnqSelVec_0 = c_comp_enq_sel_vec[0];
  assign io_compEntryEnqSelVec_1 = c_comp_enq_sel_vec[1];
  xs_EntriesFaluFmac_core u_core (
    .clock(clock), .reset(reset),
    .flush_valid(c_flush_valid), .flush_rob_flag(c_flush_rob_flag),
    .flush_rob_value(c_flush_rob_value), .flush_level(c_flush_level),
    .enq_valid(c_enq_valid), .enq_bits(c_enq_bits),
    .wk_wb(c_wk_wb), .wk_iq(c_wk_iq), .wk_wb_d(c_wk_wb_d), .wk_iq_d(c_wk_iq_d),
    .og0cancel(c_og0cancel),
    .og0resp_valid(c_og0resp_valid), .og1resp_valid(c_og1resp_valid),
    .deq_sel_oh_valid(c_deq_sel_oh_valid), .deq_sel_oh_bits(c_deq_sel_oh_bits),
    .enq_oldest_sel_bits(c_enq_oldest_sel_bits),
    .simp_oldest_sel_valid(c_simp_oldest_sel_valid), .simp_oldest_sel_bits(c_simp_oldest_sel_bits),
    .comp_oldest_sel_valid(c_comp_oldest_sel_valid), .comp_oldest_sel_bits(c_comp_oldest_sel_bits),
    .simp_deq_sel_vec(c_simp_deq_sel_vec),
    .o_valid(c_valid), .o_issued(c_issued), .o_can_issue(c_can_issue),
    .o_fu_type(c_fu_type), .o_data_sources(c_data_sources), .o_exu_sources(c_exu_sources),
    .o_deq_entry(c_deq_entry), .o_cancel_deq(c_cancel_deq),
    .o_simp_enq_sel_vec(c_simp_enq_sel_vec), .o_comp_enq_sel_vec(c_comp_enq_sel_vec)
  );
endmodule
