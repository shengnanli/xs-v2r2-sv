// 自动生成:scripts/gen_iq_abjivvi.py —— 勿手改
// EntriesAluBrhJmpI2fVsetriwiVsetriwvfI2v golden 同名扁平 wrapper —— 例化可读核 xs_EntriesAluBrhJmpI2fVsetriwiVsetriwvfI2v_core。
module EntriesAluBrhJmpI2fVsetriwiVsetriwvfI2v_xs import iq_abjivvi_pkg::*; (
  input  clock,
  input  reset,
  input  io_flush_valid,
  input  io_flush_bits_robIdx_flag,
  input  [7:0] io_flush_bits_robIdx_value,
  input  io_flush_bits_level,
  input  io_enq_0_valid,
  input  io_enq_0_bits_status_robIdx_flag,
  input  [7:0] io_enq_0_bits_status_robIdx_value,
  input  io_enq_0_bits_status_fuType_0,
  input  io_enq_0_bits_status_fuType_1,
  input  io_enq_0_bits_status_fuType_2,
  input  io_enq_0_bits_status_fuType_3,
  input  io_enq_0_bits_status_fuType_6,
  input  io_enq_0_bits_status_fuType_28,
  input  io_enq_0_bits_status_fuType_29,
  input  [7:0] io_enq_0_bits_status_srcStatus_0_psrc,
  input  [3:0] io_enq_0_bits_status_srcStatus_0_srcType,
  input  io_enq_0_bits_status_srcStatus_0_srcState,
  input  [3:0] io_enq_0_bits_status_srcStatus_0_dataSources_value,
  input  [1:0] io_enq_0_bits_status_srcStatus_0_srcLoadDependency_0,
  input  [1:0] io_enq_0_bits_status_srcStatus_0_srcLoadDependency_1,
  input  [1:0] io_enq_0_bits_status_srcStatus_0_srcLoadDependency_2,
  input  io_enq_0_bits_status_srcStatus_0_useRegCache,
  input  [4:0] io_enq_0_bits_status_srcStatus_0_regCacheIdx,
  input  [7:0] io_enq_0_bits_status_srcStatus_1_psrc,
  input  [3:0] io_enq_0_bits_status_srcStatus_1_srcType,
  input  io_enq_0_bits_status_srcStatus_1_srcState,
  input  [3:0] io_enq_0_bits_status_srcStatus_1_dataSources_value,
  input  [1:0] io_enq_0_bits_status_srcStatus_1_srcLoadDependency_0,
  input  [1:0] io_enq_0_bits_status_srcStatus_1_srcLoadDependency_1,
  input  [1:0] io_enq_0_bits_status_srcStatus_1_srcLoadDependency_2,
  input  io_enq_0_bits_status_srcStatus_1_useRegCache,
  input  [4:0] io_enq_0_bits_status_srcStatus_1_regCacheIdx,
  input  [31:0] io_enq_0_bits_imm,
  input  io_enq_0_bits_payload_preDecodeInfo_isRVC,
  input  io_enq_0_bits_payload_pred_taken,
  input  io_enq_0_bits_payload_ftqPtr_flag,
  input  [5:0] io_enq_0_bits_payload_ftqPtr_value,
  input  [3:0] io_enq_0_bits_payload_ftqOffset,
  input  [8:0] io_enq_0_bits_payload_fuOpType,
  input  io_enq_0_bits_payload_rfWen,
  input  io_enq_0_bits_payload_fpWen,
  input  io_enq_0_bits_payload_vecWen,
  input  io_enq_0_bits_payload_v0Wen,
  input  io_enq_0_bits_payload_vlWen,
  input  [3:0] io_enq_0_bits_payload_selImm,
  input  [1:0] io_enq_0_bits_payload_fpu_typeTagOut,
  input  io_enq_0_bits_payload_fpu_wflags,
  input  [1:0] io_enq_0_bits_payload_fpu_typ,
  input  [2:0] io_enq_0_bits_payload_fpu_rm,
  input  [1:0] io_enq_0_bits_payload_srcLoadDependency_0_0,
  input  [1:0] io_enq_0_bits_payload_srcLoadDependency_0_1,
  input  [1:0] io_enq_0_bits_payload_srcLoadDependency_0_2,
  input  [1:0] io_enq_0_bits_payload_srcLoadDependency_1_0,
  input  [1:0] io_enq_0_bits_payload_srcLoadDependency_1_1,
  input  [1:0] io_enq_0_bits_payload_srcLoadDependency_1_2,
  input  [7:0] io_enq_0_bits_payload_pdest,
  input  io_enq_1_valid,
  input  io_enq_1_bits_status_robIdx_flag,
  input  [7:0] io_enq_1_bits_status_robIdx_value,
  input  io_enq_1_bits_status_fuType_0,
  input  io_enq_1_bits_status_fuType_1,
  input  io_enq_1_bits_status_fuType_2,
  input  io_enq_1_bits_status_fuType_3,
  input  io_enq_1_bits_status_fuType_6,
  input  io_enq_1_bits_status_fuType_28,
  input  io_enq_1_bits_status_fuType_29,
  input  [7:0] io_enq_1_bits_status_srcStatus_0_psrc,
  input  [3:0] io_enq_1_bits_status_srcStatus_0_srcType,
  input  io_enq_1_bits_status_srcStatus_0_srcState,
  input  [3:0] io_enq_1_bits_status_srcStatus_0_dataSources_value,
  input  [1:0] io_enq_1_bits_status_srcStatus_0_srcLoadDependency_0,
  input  [1:0] io_enq_1_bits_status_srcStatus_0_srcLoadDependency_1,
  input  [1:0] io_enq_1_bits_status_srcStatus_0_srcLoadDependency_2,
  input  io_enq_1_bits_status_srcStatus_0_useRegCache,
  input  [4:0] io_enq_1_bits_status_srcStatus_0_regCacheIdx,
  input  [7:0] io_enq_1_bits_status_srcStatus_1_psrc,
  input  [3:0] io_enq_1_bits_status_srcStatus_1_srcType,
  input  io_enq_1_bits_status_srcStatus_1_srcState,
  input  [3:0] io_enq_1_bits_status_srcStatus_1_dataSources_value,
  input  [1:0] io_enq_1_bits_status_srcStatus_1_srcLoadDependency_0,
  input  [1:0] io_enq_1_bits_status_srcStatus_1_srcLoadDependency_1,
  input  [1:0] io_enq_1_bits_status_srcStatus_1_srcLoadDependency_2,
  input  io_enq_1_bits_status_srcStatus_1_useRegCache,
  input  [4:0] io_enq_1_bits_status_srcStatus_1_regCacheIdx,
  input  [31:0] io_enq_1_bits_imm,
  input  io_enq_1_bits_payload_preDecodeInfo_isRVC,
  input  io_enq_1_bits_payload_pred_taken,
  input  io_enq_1_bits_payload_ftqPtr_flag,
  input  [5:0] io_enq_1_bits_payload_ftqPtr_value,
  input  [3:0] io_enq_1_bits_payload_ftqOffset,
  input  [8:0] io_enq_1_bits_payload_fuOpType,
  input  io_enq_1_bits_payload_rfWen,
  input  io_enq_1_bits_payload_fpWen,
  input  io_enq_1_bits_payload_vecWen,
  input  io_enq_1_bits_payload_v0Wen,
  input  io_enq_1_bits_payload_vlWen,
  input  [3:0] io_enq_1_bits_payload_selImm,
  input  [1:0] io_enq_1_bits_payload_fpu_typeTagOut,
  input  io_enq_1_bits_payload_fpu_wflags,
  input  [1:0] io_enq_1_bits_payload_fpu_typ,
  input  [2:0] io_enq_1_bits_payload_fpu_rm,
  input  [1:0] io_enq_1_bits_payload_srcLoadDependency_0_0,
  input  [1:0] io_enq_1_bits_payload_srcLoadDependency_0_1,
  input  [1:0] io_enq_1_bits_payload_srcLoadDependency_0_2,
  input  [1:0] io_enq_1_bits_payload_srcLoadDependency_1_0,
  input  [1:0] io_enq_1_bits_payload_srcLoadDependency_1_1,
  input  [1:0] io_enq_1_bits_payload_srcLoadDependency_1_2,
  input  [7:0] io_enq_1_bits_payload_pdest,
  input  io_og0Resp_0_valid,
  input  io_og0Resp_1_valid,
  input  io_og1Resp_0_valid,
  input  io_og1Resp_1_valid,
  input  io_deqSelOH_0_valid,
  input  [23:0] io_deqSelOH_0_bits,
  input  io_deqSelOH_1_valid,
  input  [23:0] io_deqSelOH_1_bits,
  input  [1:0] io_enqEntryOldestSel_0_bits,
  input  [1:0] io_enqEntryOldestSel_1_bits,
  input  io_simpEntryOldestSel_0_valid,
  input  [5:0] io_simpEntryOldestSel_0_bits,
  input  io_simpEntryOldestSel_1_valid,
  input  [5:0] io_simpEntryOldestSel_1_bits,
  input  io_compEntryOldestSel_0_valid,
  input  [15:0] io_compEntryOldestSel_0_bits,
  input  io_compEntryOldestSel_1_valid,
  input  [15:0] io_compEntryOldestSel_1_bits,
  input  io_wakeUpFromWB_3_valid,
  input  io_wakeUpFromWB_3_bits_rfWen,
  input  [7:0] io_wakeUpFromWB_3_bits_pdest,
  input  io_wakeUpFromWB_2_valid,
  input  io_wakeUpFromWB_2_bits_rfWen,
  input  [7:0] io_wakeUpFromWB_2_bits_pdest,
  input  io_wakeUpFromWB_1_valid,
  input  io_wakeUpFromWB_1_bits_rfWen,
  input  [7:0] io_wakeUpFromWB_1_bits_pdest,
  input  io_wakeUpFromWB_0_valid,
  input  io_wakeUpFromWB_0_bits_rfWen,
  input  [7:0] io_wakeUpFromWB_0_bits_pdest,
  input  io_wakeUpFromIQ_6_bits_rfWen,
  input  [7:0] io_wakeUpFromIQ_6_bits_pdest,
  input  [4:0] io_wakeUpFromIQ_6_bits_rcDest,
  input  io_wakeUpFromIQ_5_bits_rfWen,
  input  [7:0] io_wakeUpFromIQ_5_bits_pdest,
  input  [4:0] io_wakeUpFromIQ_5_bits_rcDest,
  input  io_wakeUpFromIQ_4_bits_rfWen,
  input  [7:0] io_wakeUpFromIQ_4_bits_pdest,
  input  [4:0] io_wakeUpFromIQ_4_bits_rcDest,
  input  io_wakeUpFromIQ_3_bits_rfWen,
  input  [7:0] io_wakeUpFromIQ_3_bits_pdest,
  input  [1:0] io_wakeUpFromIQ_3_bits_loadDependency_0,
  input  [1:0] io_wakeUpFromIQ_3_bits_loadDependency_1,
  input  [1:0] io_wakeUpFromIQ_3_bits_loadDependency_2,
  input  [4:0] io_wakeUpFromIQ_3_bits_rcDest,
  input  io_wakeUpFromIQ_2_bits_rfWen,
  input  [7:0] io_wakeUpFromIQ_2_bits_pdest,
  input  [1:0] io_wakeUpFromIQ_2_bits_loadDependency_0,
  input  [1:0] io_wakeUpFromIQ_2_bits_loadDependency_1,
  input  [1:0] io_wakeUpFromIQ_2_bits_loadDependency_2,
  input  [4:0] io_wakeUpFromIQ_2_bits_rcDest,
  input  io_wakeUpFromIQ_1_bits_rfWen,
  input  [7:0] io_wakeUpFromIQ_1_bits_pdest,
  input  [1:0] io_wakeUpFromIQ_1_bits_loadDependency_0,
  input  [1:0] io_wakeUpFromIQ_1_bits_loadDependency_1,
  input  [1:0] io_wakeUpFromIQ_1_bits_loadDependency_2,
  input  io_wakeUpFromIQ_1_bits_is0Lat,
  input  [4:0] io_wakeUpFromIQ_1_bits_rcDest,
  input  io_wakeUpFromIQ_0_bits_rfWen,
  input  [7:0] io_wakeUpFromIQ_0_bits_pdest,
  input  [1:0] io_wakeUpFromIQ_0_bits_loadDependency_0,
  input  [1:0] io_wakeUpFromIQ_0_bits_loadDependency_1,
  input  [1:0] io_wakeUpFromIQ_0_bits_loadDependency_2,
  input  io_wakeUpFromIQ_0_bits_is0Lat,
  input  [4:0] io_wakeUpFromIQ_0_bits_rcDest,
  input  io_wakeUpFromWBDelayed_3_valid,
  input  io_wakeUpFromWBDelayed_3_bits_rfWen,
  input  [7:0] io_wakeUpFromWBDelayed_3_bits_pdest,
  input  io_wakeUpFromWBDelayed_2_valid,
  input  io_wakeUpFromWBDelayed_2_bits_rfWen,
  input  [7:0] io_wakeUpFromWBDelayed_2_bits_pdest,
  input  io_wakeUpFromWBDelayed_1_valid,
  input  io_wakeUpFromWBDelayed_1_bits_rfWen,
  input  [7:0] io_wakeUpFromWBDelayed_1_bits_pdest,
  input  io_wakeUpFromWBDelayed_0_valid,
  input  io_wakeUpFromWBDelayed_0_bits_rfWen,
  input  [7:0] io_wakeUpFromWBDelayed_0_bits_pdest,
  input  io_wakeUpFromIQDelayed_6_bits_rfWen,
  input  [7:0] io_wakeUpFromIQDelayed_6_bits_pdest,
  input  [4:0] io_wakeUpFromIQDelayed_6_bits_rcDest,
  input  io_wakeUpFromIQDelayed_5_bits_rfWen,
  input  [7:0] io_wakeUpFromIQDelayed_5_bits_pdest,
  input  [4:0] io_wakeUpFromIQDelayed_5_bits_rcDest,
  input  io_wakeUpFromIQDelayed_4_bits_rfWen,
  input  [7:0] io_wakeUpFromIQDelayed_4_bits_pdest,
  input  [4:0] io_wakeUpFromIQDelayed_4_bits_rcDest,
  input  io_wakeUpFromIQDelayed_3_bits_rfWen,
  input  [7:0] io_wakeUpFromIQDelayed_3_bits_pdest,
  input  [1:0] io_wakeUpFromIQDelayed_3_bits_loadDependency_0,
  input  [1:0] io_wakeUpFromIQDelayed_3_bits_loadDependency_1,
  input  [1:0] io_wakeUpFromIQDelayed_3_bits_loadDependency_2,
  input  [4:0] io_wakeUpFromIQDelayed_3_bits_rcDest,
  input  io_wakeUpFromIQDelayed_2_bits_rfWen,
  input  [7:0] io_wakeUpFromIQDelayed_2_bits_pdest,
  input  [1:0] io_wakeUpFromIQDelayed_2_bits_loadDependency_0,
  input  [1:0] io_wakeUpFromIQDelayed_2_bits_loadDependency_1,
  input  [1:0] io_wakeUpFromIQDelayed_2_bits_loadDependency_2,
  input  [4:0] io_wakeUpFromIQDelayed_2_bits_rcDest,
  input  io_wakeUpFromIQDelayed_1_bits_rfWen,
  input  [7:0] io_wakeUpFromIQDelayed_1_bits_pdest,
  input  [1:0] io_wakeUpFromIQDelayed_1_bits_loadDependency_0,
  input  [1:0] io_wakeUpFromIQDelayed_1_bits_loadDependency_1,
  input  [1:0] io_wakeUpFromIQDelayed_1_bits_loadDependency_2,
  input  io_wakeUpFromIQDelayed_1_bits_is0Lat,
  input  [4:0] io_wakeUpFromIQDelayed_1_bits_rcDest,
  input  io_wakeUpFromIQDelayed_0_bits_rfWen,
  input  [7:0] io_wakeUpFromIQDelayed_0_bits_pdest,
  input  [1:0] io_wakeUpFromIQDelayed_0_bits_loadDependency_0,
  input  [1:0] io_wakeUpFromIQDelayed_0_bits_loadDependency_1,
  input  [1:0] io_wakeUpFromIQDelayed_0_bits_loadDependency_2,
  input  io_wakeUpFromIQDelayed_0_bits_is0Lat,
  input  [4:0] io_wakeUpFromIQDelayed_0_bits_rcDest,
  input  io_og0Cancel_0,
  input  io_og0Cancel_2,
  input  io_og0Cancel_4,
  input  io_og0Cancel_6,
  input  io_ldCancel_0_ld2Cancel,
  input  io_ldCancel_1_ld2Cancel,
  input  io_ldCancel_2_ld2Cancel,
  output [23:0] io_valid,
  output [23:0] io_issued,
  output [23:0] io_canIssue,
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
  output [34:0] io_fuType_18,
  output [34:0] io_fuType_19,
  output [34:0] io_fuType_20,
  output [34:0] io_fuType_21,
  output [34:0] io_fuType_22,
  output [34:0] io_fuType_23,
  output [3:0] io_dataSources_0_0_value,
  output [3:0] io_dataSources_0_1_value,
  output [3:0] io_dataSources_1_0_value,
  output [3:0] io_dataSources_1_1_value,
  output [3:0] io_dataSources_2_0_value,
  output [3:0] io_dataSources_2_1_value,
  output [3:0] io_dataSources_3_0_value,
  output [3:0] io_dataSources_3_1_value,
  output [3:0] io_dataSources_4_0_value,
  output [3:0] io_dataSources_4_1_value,
  output [3:0] io_dataSources_5_0_value,
  output [3:0] io_dataSources_5_1_value,
  output [3:0] io_dataSources_6_0_value,
  output [3:0] io_dataSources_6_1_value,
  output [3:0] io_dataSources_7_0_value,
  output [3:0] io_dataSources_7_1_value,
  output [3:0] io_dataSources_8_0_value,
  output [3:0] io_dataSources_8_1_value,
  output [3:0] io_dataSources_9_0_value,
  output [3:0] io_dataSources_9_1_value,
  output [3:0] io_dataSources_10_0_value,
  output [3:0] io_dataSources_10_1_value,
  output [3:0] io_dataSources_11_0_value,
  output [3:0] io_dataSources_11_1_value,
  output [3:0] io_dataSources_12_0_value,
  output [3:0] io_dataSources_12_1_value,
  output [3:0] io_dataSources_13_0_value,
  output [3:0] io_dataSources_13_1_value,
  output [3:0] io_dataSources_14_0_value,
  output [3:0] io_dataSources_14_1_value,
  output [3:0] io_dataSources_15_0_value,
  output [3:0] io_dataSources_15_1_value,
  output [3:0] io_dataSources_16_0_value,
  output [3:0] io_dataSources_16_1_value,
  output [3:0] io_dataSources_17_0_value,
  output [3:0] io_dataSources_17_1_value,
  output [3:0] io_dataSources_18_0_value,
  output [3:0] io_dataSources_18_1_value,
  output [3:0] io_dataSources_19_0_value,
  output [3:0] io_dataSources_19_1_value,
  output [3:0] io_dataSources_20_0_value,
  output [3:0] io_dataSources_20_1_value,
  output [3:0] io_dataSources_21_0_value,
  output [3:0] io_dataSources_21_1_value,
  output [3:0] io_dataSources_22_0_value,
  output [3:0] io_dataSources_22_1_value,
  output [3:0] io_dataSources_23_0_value,
  output [3:0] io_dataSources_23_1_value,
  output [1:0] io_loadDependency_0_0,
  output [1:0] io_loadDependency_0_1,
  output [1:0] io_loadDependency_0_2,
  output [1:0] io_loadDependency_1_0,
  output [1:0] io_loadDependency_1_1,
  output [1:0] io_loadDependency_1_2,
  output [1:0] io_loadDependency_2_0,
  output [1:0] io_loadDependency_2_1,
  output [1:0] io_loadDependency_2_2,
  output [1:0] io_loadDependency_3_0,
  output [1:0] io_loadDependency_3_1,
  output [1:0] io_loadDependency_3_2,
  output [1:0] io_loadDependency_4_0,
  output [1:0] io_loadDependency_4_1,
  output [1:0] io_loadDependency_4_2,
  output [1:0] io_loadDependency_5_0,
  output [1:0] io_loadDependency_5_1,
  output [1:0] io_loadDependency_5_2,
  output [1:0] io_loadDependency_6_0,
  output [1:0] io_loadDependency_6_1,
  output [1:0] io_loadDependency_6_2,
  output [1:0] io_loadDependency_7_0,
  output [1:0] io_loadDependency_7_1,
  output [1:0] io_loadDependency_7_2,
  output [1:0] io_loadDependency_8_0,
  output [1:0] io_loadDependency_8_1,
  output [1:0] io_loadDependency_8_2,
  output [1:0] io_loadDependency_9_0,
  output [1:0] io_loadDependency_9_1,
  output [1:0] io_loadDependency_9_2,
  output [1:0] io_loadDependency_10_0,
  output [1:0] io_loadDependency_10_1,
  output [1:0] io_loadDependency_10_2,
  output [1:0] io_loadDependency_11_0,
  output [1:0] io_loadDependency_11_1,
  output [1:0] io_loadDependency_11_2,
  output [1:0] io_loadDependency_12_0,
  output [1:0] io_loadDependency_12_1,
  output [1:0] io_loadDependency_12_2,
  output [1:0] io_loadDependency_13_0,
  output [1:0] io_loadDependency_13_1,
  output [1:0] io_loadDependency_13_2,
  output [1:0] io_loadDependency_14_0,
  output [1:0] io_loadDependency_14_1,
  output [1:0] io_loadDependency_14_2,
  output [1:0] io_loadDependency_15_0,
  output [1:0] io_loadDependency_15_1,
  output [1:0] io_loadDependency_15_2,
  output [1:0] io_loadDependency_16_0,
  output [1:0] io_loadDependency_16_1,
  output [1:0] io_loadDependency_16_2,
  output [1:0] io_loadDependency_17_0,
  output [1:0] io_loadDependency_17_1,
  output [1:0] io_loadDependency_17_2,
  output [1:0] io_loadDependency_18_0,
  output [1:0] io_loadDependency_18_1,
  output [1:0] io_loadDependency_18_2,
  output [1:0] io_loadDependency_19_0,
  output [1:0] io_loadDependency_19_1,
  output [1:0] io_loadDependency_19_2,
  output [1:0] io_loadDependency_20_0,
  output [1:0] io_loadDependency_20_1,
  output [1:0] io_loadDependency_20_2,
  output [1:0] io_loadDependency_21_0,
  output [1:0] io_loadDependency_21_1,
  output [1:0] io_loadDependency_21_2,
  output [1:0] io_loadDependency_22_0,
  output [1:0] io_loadDependency_22_1,
  output [1:0] io_loadDependency_22_2,
  output [1:0] io_loadDependency_23_0,
  output [1:0] io_loadDependency_23_1,
  output [1:0] io_loadDependency_23_2,
  output [2:0] io_exuSources_0_0_value,
  output [2:0] io_exuSources_0_1_value,
  output [2:0] io_exuSources_1_0_value,
  output [2:0] io_exuSources_1_1_value,
  output [2:0] io_exuSources_2_0_value,
  output [2:0] io_exuSources_2_1_value,
  output [2:0] io_exuSources_3_0_value,
  output [2:0] io_exuSources_3_1_value,
  output [2:0] io_exuSources_4_0_value,
  output [2:0] io_exuSources_4_1_value,
  output [2:0] io_exuSources_5_0_value,
  output [2:0] io_exuSources_5_1_value,
  output [2:0] io_exuSources_6_0_value,
  output [2:0] io_exuSources_6_1_value,
  output [2:0] io_exuSources_7_0_value,
  output [2:0] io_exuSources_7_1_value,
  output [2:0] io_exuSources_8_0_value,
  output [2:0] io_exuSources_8_1_value,
  output [2:0] io_exuSources_9_0_value,
  output [2:0] io_exuSources_9_1_value,
  output [2:0] io_exuSources_10_0_value,
  output [2:0] io_exuSources_10_1_value,
  output [2:0] io_exuSources_11_0_value,
  output [2:0] io_exuSources_11_1_value,
  output [2:0] io_exuSources_12_0_value,
  output [2:0] io_exuSources_12_1_value,
  output [2:0] io_exuSources_13_0_value,
  output [2:0] io_exuSources_13_1_value,
  output [2:0] io_exuSources_14_0_value,
  output [2:0] io_exuSources_14_1_value,
  output [2:0] io_exuSources_15_0_value,
  output [2:0] io_exuSources_15_1_value,
  output [2:0] io_exuSources_16_0_value,
  output [2:0] io_exuSources_16_1_value,
  output [2:0] io_exuSources_17_0_value,
  output [2:0] io_exuSources_17_1_value,
  output [2:0] io_exuSources_18_0_value,
  output [2:0] io_exuSources_18_1_value,
  output [2:0] io_exuSources_19_0_value,
  output [2:0] io_exuSources_19_1_value,
  output [2:0] io_exuSources_20_0_value,
  output [2:0] io_exuSources_20_1_value,
  output [2:0] io_exuSources_21_0_value,
  output [2:0] io_exuSources_21_1_value,
  output [2:0] io_exuSources_22_0_value,
  output [2:0] io_exuSources_22_1_value,
  output [2:0] io_exuSources_23_0_value,
  output [2:0] io_exuSources_23_1_value,
  output io_deqEntry_0_bits_status_robIdx_flag,
  output [7:0] io_deqEntry_0_bits_status_robIdx_value,
  output io_deqEntry_0_bits_status_fuType_0,
  output io_deqEntry_0_bits_status_fuType_1,
  output io_deqEntry_0_bits_status_fuType_2,
  output io_deqEntry_0_bits_status_fuType_3,
  output io_deqEntry_0_bits_status_fuType_6,
  output io_deqEntry_0_bits_status_fuType_28,
  output io_deqEntry_0_bits_status_fuType_29,
  output [7:0] io_deqEntry_0_bits_status_srcStatus_0_psrc,
  output [3:0] io_deqEntry_0_bits_status_srcStatus_0_srcType,
  output [4:0] io_deqEntry_0_bits_status_srcStatus_0_regCacheIdx,
  output [7:0] io_deqEntry_0_bits_status_srcStatus_1_psrc,
  output [3:0] io_deqEntry_0_bits_status_srcStatus_1_srcType,
  output [4:0] io_deqEntry_0_bits_status_srcStatus_1_regCacheIdx,
  output [31:0] io_deqEntry_0_bits_imm,
  output [8:0] io_deqEntry_0_bits_payload_fuOpType,
  output io_deqEntry_0_bits_payload_rfWen,
  output [3:0] io_deqEntry_0_bits_payload_selImm,
  output [7:0] io_deqEntry_0_bits_payload_pdest,
  output io_deqEntry_1_bits_status_robIdx_flag,
  output [7:0] io_deqEntry_1_bits_status_robIdx_value,
  output io_deqEntry_1_bits_status_fuType_0,
  output io_deqEntry_1_bits_status_fuType_1,
  output io_deqEntry_1_bits_status_fuType_2,
  output io_deqEntry_1_bits_status_fuType_3,
  output io_deqEntry_1_bits_status_fuType_6,
  output io_deqEntry_1_bits_status_fuType_28,
  output io_deqEntry_1_bits_status_fuType_29,
  output [7:0] io_deqEntry_1_bits_status_srcStatus_0_psrc,
  output [3:0] io_deqEntry_1_bits_status_srcStatus_0_srcType,
  output [4:0] io_deqEntry_1_bits_status_srcStatus_0_regCacheIdx,
  output [7:0] io_deqEntry_1_bits_status_srcStatus_1_psrc,
  output [3:0] io_deqEntry_1_bits_status_srcStatus_1_srcType,
  output [4:0] io_deqEntry_1_bits_status_srcStatus_1_regCacheIdx,
  output [31:0] io_deqEntry_1_bits_imm,
  output io_deqEntry_1_bits_payload_preDecodeInfo_isRVC,
  output io_deqEntry_1_bits_payload_pred_taken,
  output io_deqEntry_1_bits_payload_ftqPtr_flag,
  output [5:0] io_deqEntry_1_bits_payload_ftqPtr_value,
  output [3:0] io_deqEntry_1_bits_payload_ftqOffset,
  output [8:0] io_deqEntry_1_bits_payload_fuOpType,
  output io_deqEntry_1_bits_payload_rfWen,
  output io_deqEntry_1_bits_payload_fpWen,
  output io_deqEntry_1_bits_payload_vecWen,
  output io_deqEntry_1_bits_payload_v0Wen,
  output io_deqEntry_1_bits_payload_vlWen,
  output [3:0] io_deqEntry_1_bits_payload_selImm,
  output [1:0] io_deqEntry_1_bits_payload_fpu_typeTagOut,
  output io_deqEntry_1_bits_payload_fpu_wflags,
  output [1:0] io_deqEntry_1_bits_payload_fpu_typ,
  output [2:0] io_deqEntry_1_bits_payload_fpu_rm,
  output [7:0] io_deqEntry_1_bits_payload_pdest,
  output io_cancelDeqVec_0,
  output io_cancelDeqVec_1,
  input  [5:0] io_simpEntryDeqSelVec_0,
  input  [5:0] io_simpEntryDeqSelVec_1,
  output [5:0] io_simpEntryEnqSelVec_0,
  output [5:0] io_simpEntryEnqSelVec_1,
  output [15:0] io_compEntryEnqSelVec_0,
  output [15:0] io_compEntryEnqSelVec_1
);
  logic                 c_flush_valid, c_flush_rob_flag, c_flush_level;
  logic [7:0]           c_flush_rob_value;
  logic [1:0]           c_enq_valid;
  entry_t [1:0]         c_enq_bits;
  enq_src_ld_t [1:0]    c_enq_src_load_dep; // 入队 srcLoadDependency(不入 payload,单独喂 enqDelayIn1)
  wk_wb_t [3:0]         c_wk_wb, c_wk_wb_d;
  wk_iq_t [6:0]         c_wk_iq, c_wk_iq_d;
  logic [26:0]          c_og0cancel, c_og1cancel;
  ld_cancel_t [2:0]     c_ldcancel;
  logic [1:0]           c_og0resp_valid, c_og1resp_valid;
  logic [1:0]           c_deq_ready, c_deq_sel_oh_valid;
  logic [1:0][23:0]     c_deq_sel_oh_bits;
  logic [1:0][1:0]      c_enq_oldest_sel_bits;
  logic [1:0]           c_simp_oldest_sel_valid, c_comp_oldest_sel_valid;
  logic [1:0][5:0]      c_simp_oldest_sel_bits;
  logic [1:0][15:0]     c_comp_oldest_sel_bits;
  logic [1:0][5:0]      c_simp_deq_sel_vec;
  logic [23:0]          c_valid, c_issued, c_can_issue;
  logic [23:0][34:0]    c_fu_type;
  logic [23:0][1:0][3:0] c_data_sources;
  logic [23:0][1:0][2:0] c_exu_sources;
  logic [23:0][2:0][1:0] c_load_dependency;
  entry_t [1:0]         c_deq_entry;
  logic [1:0]           c_cancel_deq;
  logic [1:0][5:0]      c_simp_enq_sel_vec;
  logic [1:0][15:0]     c_comp_enq_sel_vec;
  assign c_deq_ready = 2'b11; // golden 已将 deqReady 折叠为常量 1
  always_comb begin
    c_og1cancel = '0; // Entries 顶层未引 og1Cancel,置 0
    c_og0cancel = '0;
    c_enq_bits = '0;
    c_enq_src_load_dep = '0;
    c_wk_iq = '0; c_wk_iq_d = '0; c_wk_wb = '0; c_wk_wb_d = '0; c_ldcancel = '0;
    c_flush_valid = io_flush_valid;
    c_flush_rob_flag = io_flush_bits_robIdx_flag;
    c_flush_rob_value = io_flush_bits_robIdx_value;
    c_flush_level = io_flush_bits_level;
    c_enq_valid[0] = io_enq_0_valid;
    c_enq_bits[0].status.rob_flag = io_enq_0_bits_status_robIdx_flag;
    c_enq_bits[0].status.rob_value = io_enq_0_bits_status_robIdx_value;
    // fuType 紧凑存储:按 FU_TYPE_KEEP_MASK 升序装填保留位 {0,1,2,3,6,28,29}→槽{0..6}
    c_enq_bits[0].status.fu_type[0] = io_enq_0_bits_status_fuType_0;
    c_enq_bits[0].status.fu_type[1] = io_enq_0_bits_status_fuType_1;
    c_enq_bits[0].status.fu_type[2] = io_enq_0_bits_status_fuType_2;
    c_enq_bits[0].status.fu_type[3] = io_enq_0_bits_status_fuType_3;
    c_enq_bits[0].status.fu_type[4] = io_enq_0_bits_status_fuType_6;
    c_enq_bits[0].status.fu_type[5] = io_enq_0_bits_status_fuType_28;
    c_enq_bits[0].status.fu_type[6] = io_enq_0_bits_status_fuType_29;
    c_enq_bits[0].status.src[0].psrc = io_enq_0_bits_status_srcStatus_0_psrc;
    c_enq_bits[0].status.src[0].src_type = io_enq_0_bits_status_srcStatus_0_srcType;
    c_enq_bits[0].status.src[0].src_state = io_enq_0_bits_status_srcStatus_0_srcState;
    c_enq_bits[0].status.src[0].data_src = io_enq_0_bits_status_srcStatus_0_dataSources_value;
    c_enq_bits[0].status.src[0].ld_dep[0] = io_enq_0_bits_status_srcStatus_0_srcLoadDependency_0;
    c_enq_bits[0].status.src[0].ld_dep[1] = io_enq_0_bits_status_srcStatus_0_srcLoadDependency_1;
    c_enq_bits[0].status.src[0].ld_dep[2] = io_enq_0_bits_status_srcStatus_0_srcLoadDependency_2;
    c_enq_bits[0].status.src[0].use_rc = io_enq_0_bits_status_srcStatus_0_useRegCache;
    c_enq_bits[0].status.src[0].rc_idx = io_enq_0_bits_status_srcStatus_0_regCacheIdx;
    c_enq_bits[0].status.src[1].psrc = io_enq_0_bits_status_srcStatus_1_psrc;
    c_enq_bits[0].status.src[1].src_type = io_enq_0_bits_status_srcStatus_1_srcType;
    c_enq_bits[0].status.src[1].src_state = io_enq_0_bits_status_srcStatus_1_srcState;
    c_enq_bits[0].status.src[1].data_src = io_enq_0_bits_status_srcStatus_1_dataSources_value;
    c_enq_bits[0].status.src[1].ld_dep[0] = io_enq_0_bits_status_srcStatus_1_srcLoadDependency_0;
    c_enq_bits[0].status.src[1].ld_dep[1] = io_enq_0_bits_status_srcStatus_1_srcLoadDependency_1;
    c_enq_bits[0].status.src[1].ld_dep[2] = io_enq_0_bits_status_srcStatus_1_srcLoadDependency_2;
    c_enq_bits[0].status.src[1].use_rc = io_enq_0_bits_status_srcStatus_1_useRegCache;
    c_enq_bits[0].status.src[1].rc_idx = io_enq_0_bits_status_srcStatus_1_regCacheIdx;
    c_enq_bits[0].imm = io_enq_0_bits_imm;
    c_enq_bits[0].payload.pre_decode_isrvc = io_enq_0_bits_payload_preDecodeInfo_isRVC;
    c_enq_bits[0].payload.pred_taken = io_enq_0_bits_payload_pred_taken;
    c_enq_bits[0].payload.ftq_flag = io_enq_0_bits_payload_ftqPtr_flag;
    c_enq_bits[0].payload.ftq_value = io_enq_0_bits_payload_ftqPtr_value;
    c_enq_bits[0].payload.ftq_offset = io_enq_0_bits_payload_ftqOffset;
    c_enq_bits[0].payload.fu_op_type = io_enq_0_bits_payload_fuOpType;
    c_enq_bits[0].payload.rf_wen = io_enq_0_bits_payload_rfWen;
    c_enq_bits[0].payload.fp_wen = io_enq_0_bits_payload_fpWen;
    c_enq_bits[0].payload.vec_wen = io_enq_0_bits_payload_vecWen;
    c_enq_bits[0].payload.v0_wen = io_enq_0_bits_payload_v0Wen;
    c_enq_bits[0].payload.vl_wen = io_enq_0_bits_payload_vlWen;
    c_enq_bits[0].payload.sel_imm = io_enq_0_bits_payload_selImm;
    c_enq_bits[0].payload.fpu_type_tag_out = io_enq_0_bits_payload_fpu_typeTagOut;
    c_enq_bits[0].payload.fpu_wflags = io_enq_0_bits_payload_fpu_wflags;
    c_enq_bits[0].payload.fpu_typ = io_enq_0_bits_payload_fpu_typ;
    c_enq_bits[0].payload.fpu_rm = io_enq_0_bits_payload_fpu_rm;
    c_enq_src_load_dep[0][0][0] = io_enq_0_bits_payload_srcLoadDependency_0_0;
    c_enq_src_load_dep[0][0][1] = io_enq_0_bits_payload_srcLoadDependency_0_1;
    c_enq_src_load_dep[0][0][2] = io_enq_0_bits_payload_srcLoadDependency_0_2;
    c_enq_src_load_dep[0][1][0] = io_enq_0_bits_payload_srcLoadDependency_1_0;
    c_enq_src_load_dep[0][1][1] = io_enq_0_bits_payload_srcLoadDependency_1_1;
    c_enq_src_load_dep[0][1][2] = io_enq_0_bits_payload_srcLoadDependency_1_2;
    c_enq_bits[0].payload.pdest = io_enq_0_bits_payload_pdest;
    c_enq_valid[1] = io_enq_1_valid;
    c_enq_bits[1].status.rob_flag = io_enq_1_bits_status_robIdx_flag;
    c_enq_bits[1].status.rob_value = io_enq_1_bits_status_robIdx_value;
    // fuType 紧凑存储:按 FU_TYPE_KEEP_MASK 升序装填保留位 {0,1,2,3,6,28,29}→槽{0..6}
    c_enq_bits[1].status.fu_type[0] = io_enq_1_bits_status_fuType_0;
    c_enq_bits[1].status.fu_type[1] = io_enq_1_bits_status_fuType_1;
    c_enq_bits[1].status.fu_type[2] = io_enq_1_bits_status_fuType_2;
    c_enq_bits[1].status.fu_type[3] = io_enq_1_bits_status_fuType_3;
    c_enq_bits[1].status.fu_type[4] = io_enq_1_bits_status_fuType_6;
    c_enq_bits[1].status.fu_type[5] = io_enq_1_bits_status_fuType_28;
    c_enq_bits[1].status.fu_type[6] = io_enq_1_bits_status_fuType_29;
    c_enq_bits[1].status.src[0].psrc = io_enq_1_bits_status_srcStatus_0_psrc;
    c_enq_bits[1].status.src[0].src_type = io_enq_1_bits_status_srcStatus_0_srcType;
    c_enq_bits[1].status.src[0].src_state = io_enq_1_bits_status_srcStatus_0_srcState;
    c_enq_bits[1].status.src[0].data_src = io_enq_1_bits_status_srcStatus_0_dataSources_value;
    c_enq_bits[1].status.src[0].ld_dep[0] = io_enq_1_bits_status_srcStatus_0_srcLoadDependency_0;
    c_enq_bits[1].status.src[0].ld_dep[1] = io_enq_1_bits_status_srcStatus_0_srcLoadDependency_1;
    c_enq_bits[1].status.src[0].ld_dep[2] = io_enq_1_bits_status_srcStatus_0_srcLoadDependency_2;
    c_enq_bits[1].status.src[0].use_rc = io_enq_1_bits_status_srcStatus_0_useRegCache;
    c_enq_bits[1].status.src[0].rc_idx = io_enq_1_bits_status_srcStatus_0_regCacheIdx;
    c_enq_bits[1].status.src[1].psrc = io_enq_1_bits_status_srcStatus_1_psrc;
    c_enq_bits[1].status.src[1].src_type = io_enq_1_bits_status_srcStatus_1_srcType;
    c_enq_bits[1].status.src[1].src_state = io_enq_1_bits_status_srcStatus_1_srcState;
    c_enq_bits[1].status.src[1].data_src = io_enq_1_bits_status_srcStatus_1_dataSources_value;
    c_enq_bits[1].status.src[1].ld_dep[0] = io_enq_1_bits_status_srcStatus_1_srcLoadDependency_0;
    c_enq_bits[1].status.src[1].ld_dep[1] = io_enq_1_bits_status_srcStatus_1_srcLoadDependency_1;
    c_enq_bits[1].status.src[1].ld_dep[2] = io_enq_1_bits_status_srcStatus_1_srcLoadDependency_2;
    c_enq_bits[1].status.src[1].use_rc = io_enq_1_bits_status_srcStatus_1_useRegCache;
    c_enq_bits[1].status.src[1].rc_idx = io_enq_1_bits_status_srcStatus_1_regCacheIdx;
    c_enq_bits[1].imm = io_enq_1_bits_imm;
    c_enq_bits[1].payload.pre_decode_isrvc = io_enq_1_bits_payload_preDecodeInfo_isRVC;
    c_enq_bits[1].payload.pred_taken = io_enq_1_bits_payload_pred_taken;
    c_enq_bits[1].payload.ftq_flag = io_enq_1_bits_payload_ftqPtr_flag;
    c_enq_bits[1].payload.ftq_value = io_enq_1_bits_payload_ftqPtr_value;
    c_enq_bits[1].payload.ftq_offset = io_enq_1_bits_payload_ftqOffset;
    c_enq_bits[1].payload.fu_op_type = io_enq_1_bits_payload_fuOpType;
    c_enq_bits[1].payload.rf_wen = io_enq_1_bits_payload_rfWen;
    c_enq_bits[1].payload.fp_wen = io_enq_1_bits_payload_fpWen;
    c_enq_bits[1].payload.vec_wen = io_enq_1_bits_payload_vecWen;
    c_enq_bits[1].payload.v0_wen = io_enq_1_bits_payload_v0Wen;
    c_enq_bits[1].payload.vl_wen = io_enq_1_bits_payload_vlWen;
    c_enq_bits[1].payload.sel_imm = io_enq_1_bits_payload_selImm;
    c_enq_bits[1].payload.fpu_type_tag_out = io_enq_1_bits_payload_fpu_typeTagOut;
    c_enq_bits[1].payload.fpu_wflags = io_enq_1_bits_payload_fpu_wflags;
    c_enq_bits[1].payload.fpu_typ = io_enq_1_bits_payload_fpu_typ;
    c_enq_bits[1].payload.fpu_rm = io_enq_1_bits_payload_fpu_rm;
    c_enq_src_load_dep[1][0][0] = io_enq_1_bits_payload_srcLoadDependency_0_0;
    c_enq_src_load_dep[1][0][1] = io_enq_1_bits_payload_srcLoadDependency_0_1;
    c_enq_src_load_dep[1][0][2] = io_enq_1_bits_payload_srcLoadDependency_0_2;
    c_enq_src_load_dep[1][1][0] = io_enq_1_bits_payload_srcLoadDependency_1_0;
    c_enq_src_load_dep[1][1][1] = io_enq_1_bits_payload_srcLoadDependency_1_1;
    c_enq_src_load_dep[1][1][2] = io_enq_1_bits_payload_srcLoadDependency_1_2;
    c_enq_bits[1].payload.pdest = io_enq_1_bits_payload_pdest;
    c_og0resp_valid[0] = io_og0Resp_0_valid;
    c_og0resp_valid[1] = io_og0Resp_1_valid;
    c_og1resp_valid[0] = io_og1Resp_0_valid;
    c_og1resp_valid[1] = io_og1Resp_1_valid;
    c_deq_sel_oh_valid[0] = io_deqSelOH_0_valid;
    c_deq_sel_oh_bits[0] = io_deqSelOH_0_bits;
    c_deq_sel_oh_valid[1] = io_deqSelOH_1_valid;
    c_deq_sel_oh_bits[1] = io_deqSelOH_1_bits;
    c_enq_oldest_sel_bits[0] = io_enqEntryOldestSel_0_bits;
    c_enq_oldest_sel_bits[1] = io_enqEntryOldestSel_1_bits;
    c_simp_oldest_sel_valid[0] = io_simpEntryOldestSel_0_valid;
    c_simp_oldest_sel_bits[0] = io_simpEntryOldestSel_0_bits;
    c_simp_oldest_sel_valid[1] = io_simpEntryOldestSel_1_valid;
    c_simp_oldest_sel_bits[1] = io_simpEntryOldestSel_1_bits;
    c_comp_oldest_sel_valid[0] = io_compEntryOldestSel_0_valid;
    c_comp_oldest_sel_bits[0] = io_compEntryOldestSel_0_bits;
    c_comp_oldest_sel_valid[1] = io_compEntryOldestSel_1_valid;
    c_comp_oldest_sel_bits[1] = io_compEntryOldestSel_1_bits;
    c_wk_wb[3].valid = io_wakeUpFromWB_3_valid;
    c_wk_wb[3].rf_wen = io_wakeUpFromWB_3_bits_rfWen;
    c_wk_wb[3].pdest = io_wakeUpFromWB_3_bits_pdest;
    c_wk_wb[2].valid = io_wakeUpFromWB_2_valid;
    c_wk_wb[2].rf_wen = io_wakeUpFromWB_2_bits_rfWen;
    c_wk_wb[2].pdest = io_wakeUpFromWB_2_bits_pdest;
    c_wk_wb[1].valid = io_wakeUpFromWB_1_valid;
    c_wk_wb[1].rf_wen = io_wakeUpFromWB_1_bits_rfWen;
    c_wk_wb[1].pdest = io_wakeUpFromWB_1_bits_pdest;
    c_wk_wb[0].valid = io_wakeUpFromWB_0_valid;
    c_wk_wb[0].rf_wen = io_wakeUpFromWB_0_bits_rfWen;
    c_wk_wb[0].pdest = io_wakeUpFromWB_0_bits_pdest;
    c_wk_iq[6].rf_wen = io_wakeUpFromIQ_6_bits_rfWen;
    c_wk_iq[6].pdest = io_wakeUpFromIQ_6_bits_pdest;
    c_wk_iq[6].rc_dest = io_wakeUpFromIQ_6_bits_rcDest;
    c_wk_iq[5].rf_wen = io_wakeUpFromIQ_5_bits_rfWen;
    c_wk_iq[5].pdest = io_wakeUpFromIQ_5_bits_pdest;
    c_wk_iq[5].rc_dest = io_wakeUpFromIQ_5_bits_rcDest;
    c_wk_iq[4].rf_wen = io_wakeUpFromIQ_4_bits_rfWen;
    c_wk_iq[4].pdest = io_wakeUpFromIQ_4_bits_pdest;
    c_wk_iq[4].rc_dest = io_wakeUpFromIQ_4_bits_rcDest;
    c_wk_iq[3].rf_wen = io_wakeUpFromIQ_3_bits_rfWen;
    c_wk_iq[3].pdest = io_wakeUpFromIQ_3_bits_pdest;
    c_wk_iq[3].ld_dep[0] = io_wakeUpFromIQ_3_bits_loadDependency_0;
    c_wk_iq[3].ld_dep[1] = io_wakeUpFromIQ_3_bits_loadDependency_1;
    c_wk_iq[3].ld_dep[2] = io_wakeUpFromIQ_3_bits_loadDependency_2;
    c_wk_iq[3].rc_dest = io_wakeUpFromIQ_3_bits_rcDest;
    c_wk_iq[2].rf_wen = io_wakeUpFromIQ_2_bits_rfWen;
    c_wk_iq[2].pdest = io_wakeUpFromIQ_2_bits_pdest;
    c_wk_iq[2].ld_dep[0] = io_wakeUpFromIQ_2_bits_loadDependency_0;
    c_wk_iq[2].ld_dep[1] = io_wakeUpFromIQ_2_bits_loadDependency_1;
    c_wk_iq[2].ld_dep[2] = io_wakeUpFromIQ_2_bits_loadDependency_2;
    c_wk_iq[2].rc_dest = io_wakeUpFromIQ_2_bits_rcDest;
    c_wk_iq[1].rf_wen = io_wakeUpFromIQ_1_bits_rfWen;
    c_wk_iq[1].pdest = io_wakeUpFromIQ_1_bits_pdest;
    c_wk_iq[1].ld_dep[0] = io_wakeUpFromIQ_1_bits_loadDependency_0;
    c_wk_iq[1].ld_dep[1] = io_wakeUpFromIQ_1_bits_loadDependency_1;
    c_wk_iq[1].ld_dep[2] = io_wakeUpFromIQ_1_bits_loadDependency_2;
    c_wk_iq[1].is0lat = io_wakeUpFromIQ_1_bits_is0Lat;
    c_wk_iq[1].rc_dest = io_wakeUpFromIQ_1_bits_rcDest;
    c_wk_iq[0].rf_wen = io_wakeUpFromIQ_0_bits_rfWen;
    c_wk_iq[0].pdest = io_wakeUpFromIQ_0_bits_pdest;
    c_wk_iq[0].ld_dep[0] = io_wakeUpFromIQ_0_bits_loadDependency_0;
    c_wk_iq[0].ld_dep[1] = io_wakeUpFromIQ_0_bits_loadDependency_1;
    c_wk_iq[0].ld_dep[2] = io_wakeUpFromIQ_0_bits_loadDependency_2;
    c_wk_iq[0].is0lat = io_wakeUpFromIQ_0_bits_is0Lat;
    c_wk_iq[0].rc_dest = io_wakeUpFromIQ_0_bits_rcDest;
    c_wk_wb_d[3].valid = io_wakeUpFromWBDelayed_3_valid;
    c_wk_wb_d[3].rf_wen = io_wakeUpFromWBDelayed_3_bits_rfWen;
    c_wk_wb_d[3].pdest = io_wakeUpFromWBDelayed_3_bits_pdest;
    c_wk_wb_d[2].valid = io_wakeUpFromWBDelayed_2_valid;
    c_wk_wb_d[2].rf_wen = io_wakeUpFromWBDelayed_2_bits_rfWen;
    c_wk_wb_d[2].pdest = io_wakeUpFromWBDelayed_2_bits_pdest;
    c_wk_wb_d[1].valid = io_wakeUpFromWBDelayed_1_valid;
    c_wk_wb_d[1].rf_wen = io_wakeUpFromWBDelayed_1_bits_rfWen;
    c_wk_wb_d[1].pdest = io_wakeUpFromWBDelayed_1_bits_pdest;
    c_wk_wb_d[0].valid = io_wakeUpFromWBDelayed_0_valid;
    c_wk_wb_d[0].rf_wen = io_wakeUpFromWBDelayed_0_bits_rfWen;
    c_wk_wb_d[0].pdest = io_wakeUpFromWBDelayed_0_bits_pdest;
    c_wk_iq_d[6].rf_wen = io_wakeUpFromIQDelayed_6_bits_rfWen;
    c_wk_iq_d[6].pdest = io_wakeUpFromIQDelayed_6_bits_pdest;
    c_wk_iq_d[6].rc_dest = io_wakeUpFromIQDelayed_6_bits_rcDest;
    c_wk_iq_d[5].rf_wen = io_wakeUpFromIQDelayed_5_bits_rfWen;
    c_wk_iq_d[5].pdest = io_wakeUpFromIQDelayed_5_bits_pdest;
    c_wk_iq_d[5].rc_dest = io_wakeUpFromIQDelayed_5_bits_rcDest;
    c_wk_iq_d[4].rf_wen = io_wakeUpFromIQDelayed_4_bits_rfWen;
    c_wk_iq_d[4].pdest = io_wakeUpFromIQDelayed_4_bits_pdest;
    c_wk_iq_d[4].rc_dest = io_wakeUpFromIQDelayed_4_bits_rcDest;
    c_wk_iq_d[3].rf_wen = io_wakeUpFromIQDelayed_3_bits_rfWen;
    c_wk_iq_d[3].pdest = io_wakeUpFromIQDelayed_3_bits_pdest;
    c_wk_iq_d[3].ld_dep[0] = io_wakeUpFromIQDelayed_3_bits_loadDependency_0;
    c_wk_iq_d[3].ld_dep[1] = io_wakeUpFromIQDelayed_3_bits_loadDependency_1;
    c_wk_iq_d[3].ld_dep[2] = io_wakeUpFromIQDelayed_3_bits_loadDependency_2;
    c_wk_iq_d[3].rc_dest = io_wakeUpFromIQDelayed_3_bits_rcDest;
    c_wk_iq_d[2].rf_wen = io_wakeUpFromIQDelayed_2_bits_rfWen;
    c_wk_iq_d[2].pdest = io_wakeUpFromIQDelayed_2_bits_pdest;
    c_wk_iq_d[2].ld_dep[0] = io_wakeUpFromIQDelayed_2_bits_loadDependency_0;
    c_wk_iq_d[2].ld_dep[1] = io_wakeUpFromIQDelayed_2_bits_loadDependency_1;
    c_wk_iq_d[2].ld_dep[2] = io_wakeUpFromIQDelayed_2_bits_loadDependency_2;
    c_wk_iq_d[2].rc_dest = io_wakeUpFromIQDelayed_2_bits_rcDest;
    c_wk_iq_d[1].rf_wen = io_wakeUpFromIQDelayed_1_bits_rfWen;
    c_wk_iq_d[1].pdest = io_wakeUpFromIQDelayed_1_bits_pdest;
    c_wk_iq_d[1].ld_dep[0] = io_wakeUpFromIQDelayed_1_bits_loadDependency_0;
    c_wk_iq_d[1].ld_dep[1] = io_wakeUpFromIQDelayed_1_bits_loadDependency_1;
    c_wk_iq_d[1].ld_dep[2] = io_wakeUpFromIQDelayed_1_bits_loadDependency_2;
    c_wk_iq_d[1].is0lat = io_wakeUpFromIQDelayed_1_bits_is0Lat;
    c_wk_iq_d[1].rc_dest = io_wakeUpFromIQDelayed_1_bits_rcDest;
    c_wk_iq_d[0].rf_wen = io_wakeUpFromIQDelayed_0_bits_rfWen;
    c_wk_iq_d[0].pdest = io_wakeUpFromIQDelayed_0_bits_pdest;
    c_wk_iq_d[0].ld_dep[0] = io_wakeUpFromIQDelayed_0_bits_loadDependency_0;
    c_wk_iq_d[0].ld_dep[1] = io_wakeUpFromIQDelayed_0_bits_loadDependency_1;
    c_wk_iq_d[0].ld_dep[2] = io_wakeUpFromIQDelayed_0_bits_loadDependency_2;
    c_wk_iq_d[0].is0lat = io_wakeUpFromIQDelayed_0_bits_is0Lat;
    c_wk_iq_d[0].rc_dest = io_wakeUpFromIQDelayed_0_bits_rcDest;
    c_og0cancel[0] = io_og0Cancel_0;
    c_og0cancel[2] = io_og0Cancel_2;
    c_og0cancel[4] = io_og0Cancel_4;
    c_og0cancel[6] = io_og0Cancel_6;
    c_ldcancel[0].ld2_cancel = io_ldCancel_0_ld2Cancel;
    c_ldcancel[1].ld2_cancel = io_ldCancel_1_ld2Cancel;
    c_ldcancel[2].ld2_cancel = io_ldCancel_2_ld2Cancel;
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
  assign io_fuType_18 = c_fu_type[18];
  assign io_fuType_19 = c_fu_type[19];
  assign io_fuType_20 = c_fu_type[20];
  assign io_fuType_21 = c_fu_type[21];
  assign io_fuType_22 = c_fu_type[22];
  assign io_fuType_23 = c_fu_type[23];
  assign io_dataSources_0_0_value = c_data_sources[0][0];
  assign io_dataSources_0_1_value = c_data_sources[0][1];
  assign io_dataSources_1_0_value = c_data_sources[1][0];
  assign io_dataSources_1_1_value = c_data_sources[1][1];
  assign io_dataSources_2_0_value = c_data_sources[2][0];
  assign io_dataSources_2_1_value = c_data_sources[2][1];
  assign io_dataSources_3_0_value = c_data_sources[3][0];
  assign io_dataSources_3_1_value = c_data_sources[3][1];
  assign io_dataSources_4_0_value = c_data_sources[4][0];
  assign io_dataSources_4_1_value = c_data_sources[4][1];
  assign io_dataSources_5_0_value = c_data_sources[5][0];
  assign io_dataSources_5_1_value = c_data_sources[5][1];
  assign io_dataSources_6_0_value = c_data_sources[6][0];
  assign io_dataSources_6_1_value = c_data_sources[6][1];
  assign io_dataSources_7_0_value = c_data_sources[7][0];
  assign io_dataSources_7_1_value = c_data_sources[7][1];
  assign io_dataSources_8_0_value = c_data_sources[8][0];
  assign io_dataSources_8_1_value = c_data_sources[8][1];
  assign io_dataSources_9_0_value = c_data_sources[9][0];
  assign io_dataSources_9_1_value = c_data_sources[9][1];
  assign io_dataSources_10_0_value = c_data_sources[10][0];
  assign io_dataSources_10_1_value = c_data_sources[10][1];
  assign io_dataSources_11_0_value = c_data_sources[11][0];
  assign io_dataSources_11_1_value = c_data_sources[11][1];
  assign io_dataSources_12_0_value = c_data_sources[12][0];
  assign io_dataSources_12_1_value = c_data_sources[12][1];
  assign io_dataSources_13_0_value = c_data_sources[13][0];
  assign io_dataSources_13_1_value = c_data_sources[13][1];
  assign io_dataSources_14_0_value = c_data_sources[14][0];
  assign io_dataSources_14_1_value = c_data_sources[14][1];
  assign io_dataSources_15_0_value = c_data_sources[15][0];
  assign io_dataSources_15_1_value = c_data_sources[15][1];
  assign io_dataSources_16_0_value = c_data_sources[16][0];
  assign io_dataSources_16_1_value = c_data_sources[16][1];
  assign io_dataSources_17_0_value = c_data_sources[17][0];
  assign io_dataSources_17_1_value = c_data_sources[17][1];
  assign io_dataSources_18_0_value = c_data_sources[18][0];
  assign io_dataSources_18_1_value = c_data_sources[18][1];
  assign io_dataSources_19_0_value = c_data_sources[19][0];
  assign io_dataSources_19_1_value = c_data_sources[19][1];
  assign io_dataSources_20_0_value = c_data_sources[20][0];
  assign io_dataSources_20_1_value = c_data_sources[20][1];
  assign io_dataSources_21_0_value = c_data_sources[21][0];
  assign io_dataSources_21_1_value = c_data_sources[21][1];
  assign io_dataSources_22_0_value = c_data_sources[22][0];
  assign io_dataSources_22_1_value = c_data_sources[22][1];
  assign io_dataSources_23_0_value = c_data_sources[23][0];
  assign io_dataSources_23_1_value = c_data_sources[23][1];
  assign io_loadDependency_0_0 = c_load_dependency[0][0];
  assign io_loadDependency_0_1 = c_load_dependency[0][1];
  assign io_loadDependency_0_2 = c_load_dependency[0][2];
  assign io_loadDependency_1_0 = c_load_dependency[1][0];
  assign io_loadDependency_1_1 = c_load_dependency[1][1];
  assign io_loadDependency_1_2 = c_load_dependency[1][2];
  assign io_loadDependency_2_0 = c_load_dependency[2][0];
  assign io_loadDependency_2_1 = c_load_dependency[2][1];
  assign io_loadDependency_2_2 = c_load_dependency[2][2];
  assign io_loadDependency_3_0 = c_load_dependency[3][0];
  assign io_loadDependency_3_1 = c_load_dependency[3][1];
  assign io_loadDependency_3_2 = c_load_dependency[3][2];
  assign io_loadDependency_4_0 = c_load_dependency[4][0];
  assign io_loadDependency_4_1 = c_load_dependency[4][1];
  assign io_loadDependency_4_2 = c_load_dependency[4][2];
  assign io_loadDependency_5_0 = c_load_dependency[5][0];
  assign io_loadDependency_5_1 = c_load_dependency[5][1];
  assign io_loadDependency_5_2 = c_load_dependency[5][2];
  assign io_loadDependency_6_0 = c_load_dependency[6][0];
  assign io_loadDependency_6_1 = c_load_dependency[6][1];
  assign io_loadDependency_6_2 = c_load_dependency[6][2];
  assign io_loadDependency_7_0 = c_load_dependency[7][0];
  assign io_loadDependency_7_1 = c_load_dependency[7][1];
  assign io_loadDependency_7_2 = c_load_dependency[7][2];
  assign io_loadDependency_8_0 = c_load_dependency[8][0];
  assign io_loadDependency_8_1 = c_load_dependency[8][1];
  assign io_loadDependency_8_2 = c_load_dependency[8][2];
  assign io_loadDependency_9_0 = c_load_dependency[9][0];
  assign io_loadDependency_9_1 = c_load_dependency[9][1];
  assign io_loadDependency_9_2 = c_load_dependency[9][2];
  assign io_loadDependency_10_0 = c_load_dependency[10][0];
  assign io_loadDependency_10_1 = c_load_dependency[10][1];
  assign io_loadDependency_10_2 = c_load_dependency[10][2];
  assign io_loadDependency_11_0 = c_load_dependency[11][0];
  assign io_loadDependency_11_1 = c_load_dependency[11][1];
  assign io_loadDependency_11_2 = c_load_dependency[11][2];
  assign io_loadDependency_12_0 = c_load_dependency[12][0];
  assign io_loadDependency_12_1 = c_load_dependency[12][1];
  assign io_loadDependency_12_2 = c_load_dependency[12][2];
  assign io_loadDependency_13_0 = c_load_dependency[13][0];
  assign io_loadDependency_13_1 = c_load_dependency[13][1];
  assign io_loadDependency_13_2 = c_load_dependency[13][2];
  assign io_loadDependency_14_0 = c_load_dependency[14][0];
  assign io_loadDependency_14_1 = c_load_dependency[14][1];
  assign io_loadDependency_14_2 = c_load_dependency[14][2];
  assign io_loadDependency_15_0 = c_load_dependency[15][0];
  assign io_loadDependency_15_1 = c_load_dependency[15][1];
  assign io_loadDependency_15_2 = c_load_dependency[15][2];
  assign io_loadDependency_16_0 = c_load_dependency[16][0];
  assign io_loadDependency_16_1 = c_load_dependency[16][1];
  assign io_loadDependency_16_2 = c_load_dependency[16][2];
  assign io_loadDependency_17_0 = c_load_dependency[17][0];
  assign io_loadDependency_17_1 = c_load_dependency[17][1];
  assign io_loadDependency_17_2 = c_load_dependency[17][2];
  assign io_loadDependency_18_0 = c_load_dependency[18][0];
  assign io_loadDependency_18_1 = c_load_dependency[18][1];
  assign io_loadDependency_18_2 = c_load_dependency[18][2];
  assign io_loadDependency_19_0 = c_load_dependency[19][0];
  assign io_loadDependency_19_1 = c_load_dependency[19][1];
  assign io_loadDependency_19_2 = c_load_dependency[19][2];
  assign io_loadDependency_20_0 = c_load_dependency[20][0];
  assign io_loadDependency_20_1 = c_load_dependency[20][1];
  assign io_loadDependency_20_2 = c_load_dependency[20][2];
  assign io_loadDependency_21_0 = c_load_dependency[21][0];
  assign io_loadDependency_21_1 = c_load_dependency[21][1];
  assign io_loadDependency_21_2 = c_load_dependency[21][2];
  assign io_loadDependency_22_0 = c_load_dependency[22][0];
  assign io_loadDependency_22_1 = c_load_dependency[22][1];
  assign io_loadDependency_22_2 = c_load_dependency[22][2];
  assign io_loadDependency_23_0 = c_load_dependency[23][0];
  assign io_loadDependency_23_1 = c_load_dependency[23][1];
  assign io_loadDependency_23_2 = c_load_dependency[23][2];
  assign io_exuSources_0_0_value = c_exu_sources[0][0];
  assign io_exuSources_0_1_value = c_exu_sources[0][1];
  assign io_exuSources_1_0_value = c_exu_sources[1][0];
  assign io_exuSources_1_1_value = c_exu_sources[1][1];
  assign io_exuSources_2_0_value = c_exu_sources[2][0];
  assign io_exuSources_2_1_value = c_exu_sources[2][1];
  assign io_exuSources_3_0_value = c_exu_sources[3][0];
  assign io_exuSources_3_1_value = c_exu_sources[3][1];
  assign io_exuSources_4_0_value = c_exu_sources[4][0];
  assign io_exuSources_4_1_value = c_exu_sources[4][1];
  assign io_exuSources_5_0_value = c_exu_sources[5][0];
  assign io_exuSources_5_1_value = c_exu_sources[5][1];
  assign io_exuSources_6_0_value = c_exu_sources[6][0];
  assign io_exuSources_6_1_value = c_exu_sources[6][1];
  assign io_exuSources_7_0_value = c_exu_sources[7][0];
  assign io_exuSources_7_1_value = c_exu_sources[7][1];
  assign io_exuSources_8_0_value = c_exu_sources[8][0];
  assign io_exuSources_8_1_value = c_exu_sources[8][1];
  assign io_exuSources_9_0_value = c_exu_sources[9][0];
  assign io_exuSources_9_1_value = c_exu_sources[9][1];
  assign io_exuSources_10_0_value = c_exu_sources[10][0];
  assign io_exuSources_10_1_value = c_exu_sources[10][1];
  assign io_exuSources_11_0_value = c_exu_sources[11][0];
  assign io_exuSources_11_1_value = c_exu_sources[11][1];
  assign io_exuSources_12_0_value = c_exu_sources[12][0];
  assign io_exuSources_12_1_value = c_exu_sources[12][1];
  assign io_exuSources_13_0_value = c_exu_sources[13][0];
  assign io_exuSources_13_1_value = c_exu_sources[13][1];
  assign io_exuSources_14_0_value = c_exu_sources[14][0];
  assign io_exuSources_14_1_value = c_exu_sources[14][1];
  assign io_exuSources_15_0_value = c_exu_sources[15][0];
  assign io_exuSources_15_1_value = c_exu_sources[15][1];
  assign io_exuSources_16_0_value = c_exu_sources[16][0];
  assign io_exuSources_16_1_value = c_exu_sources[16][1];
  assign io_exuSources_17_0_value = c_exu_sources[17][0];
  assign io_exuSources_17_1_value = c_exu_sources[17][1];
  assign io_exuSources_18_0_value = c_exu_sources[18][0];
  assign io_exuSources_18_1_value = c_exu_sources[18][1];
  assign io_exuSources_19_0_value = c_exu_sources[19][0];
  assign io_exuSources_19_1_value = c_exu_sources[19][1];
  assign io_exuSources_20_0_value = c_exu_sources[20][0];
  assign io_exuSources_20_1_value = c_exu_sources[20][1];
  assign io_exuSources_21_0_value = c_exu_sources[21][0];
  assign io_exuSources_21_1_value = c_exu_sources[21][1];
  assign io_exuSources_22_0_value = c_exu_sources[22][0];
  assign io_exuSources_22_1_value = c_exu_sources[22][1];
  assign io_exuSources_23_0_value = c_exu_sources[23][0];
  assign io_exuSources_23_1_value = c_exu_sources[23][1];
  assign io_deqEntry_0_bits_status_robIdx_flag = c_deq_entry[0].status.rob_flag;
  assign io_deqEntry_0_bits_status_robIdx_value = c_deq_entry[0].status.rob_value;
  // fuType 紧凑存储解包:保留位 {0,1,2,3,6,28,29} 存于槽 {0,1,2,3,4,5,6}
  assign io_deqEntry_0_bits_status_fuType_0 = c_deq_entry[0].status.fu_type[0];
  assign io_deqEntry_0_bits_status_fuType_1 = c_deq_entry[0].status.fu_type[1];
  assign io_deqEntry_0_bits_status_fuType_2 = c_deq_entry[0].status.fu_type[2];
  assign io_deqEntry_0_bits_status_fuType_3 = c_deq_entry[0].status.fu_type[3];
  assign io_deqEntry_0_bits_status_fuType_6 = c_deq_entry[0].status.fu_type[4];
  assign io_deqEntry_0_bits_status_fuType_28 = c_deq_entry[0].status.fu_type[5];
  assign io_deqEntry_0_bits_status_fuType_29 = c_deq_entry[0].status.fu_type[6];
  assign io_deqEntry_0_bits_status_srcStatus_0_psrc = c_deq_entry[0].status.src[0].psrc;
  assign io_deqEntry_0_bits_status_srcStatus_0_srcType = c_deq_entry[0].status.src[0].src_type;
  assign io_deqEntry_0_bits_status_srcStatus_0_regCacheIdx = c_deq_entry[0].status.src[0].rc_idx;
  assign io_deqEntry_0_bits_status_srcStatus_1_psrc = c_deq_entry[0].status.src[1].psrc;
  assign io_deqEntry_0_bits_status_srcStatus_1_srcType = c_deq_entry[0].status.src[1].src_type;
  assign io_deqEntry_0_bits_status_srcStatus_1_regCacheIdx = c_deq_entry[0].status.src[1].rc_idx;
  assign io_deqEntry_0_bits_imm = c_deq_entry[0].imm;
  assign io_deqEntry_0_bits_payload_fuOpType = c_deq_entry[0].payload.fu_op_type;
  assign io_deqEntry_0_bits_payload_rfWen = c_deq_entry[0].payload.rf_wen;
  assign io_deqEntry_0_bits_payload_selImm = c_deq_entry[0].payload.sel_imm;
  assign io_deqEntry_0_bits_payload_pdest = c_deq_entry[0].payload.pdest;
  assign io_deqEntry_1_bits_status_robIdx_flag = c_deq_entry[1].status.rob_flag;
  assign io_deqEntry_1_bits_status_robIdx_value = c_deq_entry[1].status.rob_value;
  assign io_deqEntry_1_bits_status_fuType_0 = c_deq_entry[1].status.fu_type[0];
  assign io_deqEntry_1_bits_status_fuType_1 = c_deq_entry[1].status.fu_type[1];
  assign io_deqEntry_1_bits_status_fuType_2 = c_deq_entry[1].status.fu_type[2];
  assign io_deqEntry_1_bits_status_fuType_3 = c_deq_entry[1].status.fu_type[3];
  assign io_deqEntry_1_bits_status_fuType_6 = c_deq_entry[1].status.fu_type[4];
  assign io_deqEntry_1_bits_status_fuType_28 = c_deq_entry[1].status.fu_type[5];
  assign io_deqEntry_1_bits_status_fuType_29 = c_deq_entry[1].status.fu_type[6];
  assign io_deqEntry_1_bits_status_srcStatus_0_psrc = c_deq_entry[1].status.src[0].psrc;
  assign io_deqEntry_1_bits_status_srcStatus_0_srcType = c_deq_entry[1].status.src[0].src_type;
  assign io_deqEntry_1_bits_status_srcStatus_0_regCacheIdx = c_deq_entry[1].status.src[0].rc_idx;
  assign io_deqEntry_1_bits_status_srcStatus_1_psrc = c_deq_entry[1].status.src[1].psrc;
  assign io_deqEntry_1_bits_status_srcStatus_1_srcType = c_deq_entry[1].status.src[1].src_type;
  assign io_deqEntry_1_bits_status_srcStatus_1_regCacheIdx = c_deq_entry[1].status.src[1].rc_idx;
  assign io_deqEntry_1_bits_imm = c_deq_entry[1].imm;
  assign io_deqEntry_1_bits_payload_preDecodeInfo_isRVC = c_deq_entry[1].payload.pre_decode_isrvc;
  assign io_deqEntry_1_bits_payload_pred_taken = c_deq_entry[1].payload.pred_taken;
  assign io_deqEntry_1_bits_payload_ftqPtr_flag = c_deq_entry[1].payload.ftq_flag;
  assign io_deqEntry_1_bits_payload_ftqPtr_value = c_deq_entry[1].payload.ftq_value;
  assign io_deqEntry_1_bits_payload_ftqOffset = c_deq_entry[1].payload.ftq_offset;
  assign io_deqEntry_1_bits_payload_fuOpType = c_deq_entry[1].payload.fu_op_type;
  assign io_deqEntry_1_bits_payload_rfWen = c_deq_entry[1].payload.rf_wen;
  assign io_deqEntry_1_bits_payload_fpWen = c_deq_entry[1].payload.fp_wen;
  assign io_deqEntry_1_bits_payload_vecWen = c_deq_entry[1].payload.vec_wen;
  assign io_deqEntry_1_bits_payload_v0Wen = c_deq_entry[1].payload.v0_wen;
  assign io_deqEntry_1_bits_payload_vlWen = c_deq_entry[1].payload.vl_wen;
  assign io_deqEntry_1_bits_payload_selImm = c_deq_entry[1].payload.sel_imm;
  assign io_deqEntry_1_bits_payload_fpu_typeTagOut = c_deq_entry[1].payload.fpu_type_tag_out;
  assign io_deqEntry_1_bits_payload_fpu_wflags = c_deq_entry[1].payload.fpu_wflags;
  assign io_deqEntry_1_bits_payload_fpu_typ = c_deq_entry[1].payload.fpu_typ;
  assign io_deqEntry_1_bits_payload_fpu_rm = c_deq_entry[1].payload.fpu_rm;
  assign io_deqEntry_1_bits_payload_pdest = c_deq_entry[1].payload.pdest;
  assign io_cancelDeqVec_0 = c_cancel_deq[0];
  assign io_cancelDeqVec_1 = c_cancel_deq[1];
  assign io_simpEntryEnqSelVec_0 = c_simp_enq_sel_vec[0];
  assign io_simpEntryEnqSelVec_1 = c_simp_enq_sel_vec[1];
  assign io_compEntryEnqSelVec_0 = c_comp_enq_sel_vec[0];
  assign io_compEntryEnqSelVec_1 = c_comp_enq_sel_vec[1];
  xs_EntriesAluBrhJmpI2fVsetriwiVsetriwvfI2v_core u_core (
    .clock(clock), .reset(reset),
    .flush_valid(c_flush_valid), .flush_rob_flag(c_flush_rob_flag),
    .flush_rob_value(c_flush_rob_value), .flush_level(c_flush_level),
    .enq_valid(c_enq_valid), .enq_bits(c_enq_bits), .enq_src_load_dep(c_enq_src_load_dep),
    .wk_wb(c_wk_wb), .wk_iq(c_wk_iq), .wk_wb_d(c_wk_wb_d), .wk_iq_d(c_wk_iq_d),
    .og0cancel(c_og0cancel), .og1cancel(c_og1cancel), .ldcancel(c_ldcancel),
    .og0resp_valid(c_og0resp_valid), .og1resp_valid(c_og1resp_valid),
    .deq_ready(c_deq_ready), .deq_sel_oh_valid(c_deq_sel_oh_valid),
    .deq_sel_oh_bits(c_deq_sel_oh_bits), .enq_oldest_sel_bits(c_enq_oldest_sel_bits),
    .simp_oldest_sel_valid(c_simp_oldest_sel_valid), .simp_oldest_sel_bits(c_simp_oldest_sel_bits),
    .comp_oldest_sel_valid(c_comp_oldest_sel_valid), .comp_oldest_sel_bits(c_comp_oldest_sel_bits),
    .simp_deq_sel_vec(c_simp_deq_sel_vec),
    .o_valid(c_valid), .o_issued(c_issued), .o_can_issue(c_can_issue),
    .o_fu_type(c_fu_type), .o_data_sources(c_data_sources), .o_exu_sources(c_exu_sources),
    .o_load_dependency(c_load_dependency), .o_deq_entry(c_deq_entry), .o_cancel_deq(c_cancel_deq),
    .o_simp_enq_sel_vec(c_simp_enq_sel_vec), .o_comp_enq_sel_vec(c_comp_enq_sel_vec)
  );
endmodule
