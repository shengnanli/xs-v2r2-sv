// 自动生成:scripts/gen_iq_vfmavialufixvfalu.py —— 勿手改
// EntriesVfmaVialuFixVfalu golden 同名扁平 wrapper —— 例化可读核 xs_EntriesVfmaVialuFixVfalu_core。
module EntriesVfmaVialuFixVfalu_xs import iq_vfmavialufixvfalu_pkg::*; (
  input  clock,
  input  reset,
  input  io_flush_valid,
  input  io_flush_bits_robIdx_flag,
  input  [7:0] io_flush_bits_robIdx_value,
  input  io_flush_bits_level,
  input  io_enq_0_valid,
  input  io_enq_0_bits_status_robIdx_flag,
  input  [7:0] io_enq_0_bits_status_robIdx_value,
  input  io_enq_0_bits_status_fuType_19,
  input  io_enq_0_bits_status_fuType_24,
  input  io_enq_0_bits_status_fuType_25,
  input  [6:0] io_enq_0_bits_status_srcStatus_0_psrc,
  input  [3:0] io_enq_0_bits_status_srcStatus_0_srcType,
  input  io_enq_0_bits_status_srcStatus_0_srcState,
  input  [3:0] io_enq_0_bits_status_srcStatus_0_dataSources_value,
  input  [6:0] io_enq_0_bits_status_srcStatus_1_psrc,
  input  [3:0] io_enq_0_bits_status_srcStatus_1_srcType,
  input  io_enq_0_bits_status_srcStatus_1_srcState,
  input  [3:0] io_enq_0_bits_status_srcStatus_1_dataSources_value,
  input  [6:0] io_enq_0_bits_status_srcStatus_2_psrc,
  input  [3:0] io_enq_0_bits_status_srcStatus_2_srcType,
  input  io_enq_0_bits_status_srcStatus_2_srcState,
  input  [3:0] io_enq_0_bits_status_srcStatus_2_dataSources_value,
  input  [6:0] io_enq_0_bits_status_srcStatus_3_psrc,
  input  [3:0] io_enq_0_bits_status_srcStatus_3_srcType,
  input  io_enq_0_bits_status_srcStatus_3_srcState,
  input  [3:0] io_enq_0_bits_status_srcStatus_3_dataSources_value,
  input  [6:0] io_enq_0_bits_status_srcStatus_4_psrc,
  input  [3:0] io_enq_0_bits_status_srcStatus_4_srcType,
  input  io_enq_0_bits_status_srcStatus_4_srcState,
  input  [3:0] io_enq_0_bits_status_srcStatus_4_dataSources_value,
  input  [8:0] io_enq_0_bits_payload_fuOpType,
  input  io_enq_0_bits_payload_fpWen,
  input  io_enq_0_bits_payload_vecWen,
  input  io_enq_0_bits_payload_v0Wen,
  input  io_enq_0_bits_payload_fpu_wflags,
  input  io_enq_0_bits_payload_vpu_vma,
  input  io_enq_0_bits_payload_vpu_vta,
  input  [1:0] io_enq_0_bits_payload_vpu_vsew,
  input  [2:0] io_enq_0_bits_payload_vpu_vlmul,
  input  io_enq_0_bits_payload_vpu_vm,
  input  [7:0] io_enq_0_bits_payload_vpu_vstart,
  input  io_enq_0_bits_payload_vpu_fpu_isFoldTo1_2,
  input  io_enq_0_bits_payload_vpu_fpu_isFoldTo1_4,
  input  io_enq_0_bits_payload_vpu_fpu_isFoldTo1_8,
  input  io_enq_0_bits_payload_vpu_isExt,
  input  io_enq_0_bits_payload_vpu_isNarrow,
  input  io_enq_0_bits_payload_vpu_isDstMask,
  input  io_enq_0_bits_payload_vpu_isOpMask,
  input  io_enq_0_bits_payload_vpu_isDependOldVd,
  input  io_enq_0_bits_payload_vpu_isWritePartVd,
  input  [6:0] io_enq_0_bits_payload_uopIdx,
  input  io_enq_0_bits_payload_lastUop,
  input  [7:0] io_enq_0_bits_payload_pdest,
  input  io_enq_1_valid,
  input  io_enq_1_bits_status_robIdx_flag,
  input  [7:0] io_enq_1_bits_status_robIdx_value,
  input  io_enq_1_bits_status_fuType_19,
  input  io_enq_1_bits_status_fuType_24,
  input  io_enq_1_bits_status_fuType_25,
  input  [6:0] io_enq_1_bits_status_srcStatus_0_psrc,
  input  [3:0] io_enq_1_bits_status_srcStatus_0_srcType,
  input  io_enq_1_bits_status_srcStatus_0_srcState,
  input  [3:0] io_enq_1_bits_status_srcStatus_0_dataSources_value,
  input  [6:0] io_enq_1_bits_status_srcStatus_1_psrc,
  input  [3:0] io_enq_1_bits_status_srcStatus_1_srcType,
  input  io_enq_1_bits_status_srcStatus_1_srcState,
  input  [3:0] io_enq_1_bits_status_srcStatus_1_dataSources_value,
  input  [6:0] io_enq_1_bits_status_srcStatus_2_psrc,
  input  [3:0] io_enq_1_bits_status_srcStatus_2_srcType,
  input  io_enq_1_bits_status_srcStatus_2_srcState,
  input  [3:0] io_enq_1_bits_status_srcStatus_2_dataSources_value,
  input  [6:0] io_enq_1_bits_status_srcStatus_3_psrc,
  input  [3:0] io_enq_1_bits_status_srcStatus_3_srcType,
  input  io_enq_1_bits_status_srcStatus_3_srcState,
  input  [3:0] io_enq_1_bits_status_srcStatus_3_dataSources_value,
  input  [6:0] io_enq_1_bits_status_srcStatus_4_psrc,
  input  [3:0] io_enq_1_bits_status_srcStatus_4_srcType,
  input  io_enq_1_bits_status_srcStatus_4_srcState,
  input  [3:0] io_enq_1_bits_status_srcStatus_4_dataSources_value,
  input  [8:0] io_enq_1_bits_payload_fuOpType,
  input  io_enq_1_bits_payload_fpWen,
  input  io_enq_1_bits_payload_vecWen,
  input  io_enq_1_bits_payload_v0Wen,
  input  io_enq_1_bits_payload_fpu_wflags,
  input  io_enq_1_bits_payload_vpu_vma,
  input  io_enq_1_bits_payload_vpu_vta,
  input  [1:0] io_enq_1_bits_payload_vpu_vsew,
  input  [2:0] io_enq_1_bits_payload_vpu_vlmul,
  input  io_enq_1_bits_payload_vpu_vm,
  input  [7:0] io_enq_1_bits_payload_vpu_vstart,
  input  io_enq_1_bits_payload_vpu_fpu_isFoldTo1_2,
  input  io_enq_1_bits_payload_vpu_fpu_isFoldTo1_4,
  input  io_enq_1_bits_payload_vpu_fpu_isFoldTo1_8,
  input  io_enq_1_bits_payload_vpu_isExt,
  input  io_enq_1_bits_payload_vpu_isNarrow,
  input  io_enq_1_bits_payload_vpu_isDstMask,
  input  io_enq_1_bits_payload_vpu_isOpMask,
  input  io_enq_1_bits_payload_vpu_isDependOldVd,
  input  io_enq_1_bits_payload_vpu_isWritePartVd,
  input  [6:0] io_enq_1_bits_payload_uopIdx,
  input  io_enq_1_bits_payload_lastUop,
  input  [7:0] io_enq_1_bits_payload_pdest,
  input  io_og0Resp_0_valid,
  input  io_og0Resp_1_valid,
  input  io_og1Resp_0_valid,
  input  io_og1Resp_1_valid,
  input  io_og2Resp_0_valid,
  input  [1:0] io_og2Resp_0_bits_resp,
  input  io_og2Resp_1_valid,
  input  io_deqSelOH_0_valid,
  input  [15:0] io_deqSelOH_0_bits,
  input  io_deqSelOH_1_valid,
  input  [15:0] io_deqSelOH_1_bits,
  input  [1:0] io_enqEntryOldestSel_0_bits,
  input  [1:0] io_enqEntryOldestSel_1_bits,
  input  io_simpEntryOldestSel_0_valid,
  input  [1:0] io_simpEntryOldestSel_0_bits,
  input  io_simpEntryOldestSel_1_valid,
  input  [1:0] io_simpEntryOldestSel_1_bits,
  input  io_compEntryOldestSel_0_valid,
  input  [11:0] io_compEntryOldestSel_0_bits,
  input  io_compEntryOldestSel_1_valid,
  input  [11:0] io_compEntryOldestSel_1_bits,
  input  io_wakeUpFromWB_15_valid,
  input  io_wakeUpFromWB_15_bits_vlWen,
  input  [7:0] io_wakeUpFromWB_15_bits_pdest,
  input  io_wakeUpFromWB_14_valid,
  input  io_wakeUpFromWB_14_bits_vlWen,
  input  [7:0] io_wakeUpFromWB_14_bits_pdest,
  input  io_wakeUpFromWB_13_valid,
  input  io_wakeUpFromWB_13_bits_vlWen,
  input  [7:0] io_wakeUpFromWB_13_bits_pdest,
  input  io_wakeUpFromWB_12_valid,
  input  io_wakeUpFromWB_12_bits_vlWen,
  input  [7:0] io_wakeUpFromWB_12_bits_pdest,
  input  io_wakeUpFromWB_11_valid,
  input  io_wakeUpFromWB_11_bits_v0Wen,
  input  [7:0] io_wakeUpFromWB_11_bits_pdest,
  input  io_wakeUpFromWB_10_valid,
  input  io_wakeUpFromWB_10_bits_v0Wen,
  input  [7:0] io_wakeUpFromWB_10_bits_pdest,
  input  io_wakeUpFromWB_9_valid,
  input  io_wakeUpFromWB_9_bits_v0Wen,
  input  [7:0] io_wakeUpFromWB_9_bits_pdest,
  input  io_wakeUpFromWB_8_valid,
  input  io_wakeUpFromWB_8_bits_v0Wen,
  input  [7:0] io_wakeUpFromWB_8_bits_pdest,
  input  io_wakeUpFromWB_7_valid,
  input  io_wakeUpFromWB_7_bits_v0Wen,
  input  [7:0] io_wakeUpFromWB_7_bits_pdest,
  input  io_wakeUpFromWB_6_valid,
  input  io_wakeUpFromWB_6_bits_v0Wen,
  input  [7:0] io_wakeUpFromWB_6_bits_pdest,
  input  io_wakeUpFromWB_5_valid,
  input  io_wakeUpFromWB_5_bits_vecWen,
  input  [7:0] io_wakeUpFromWB_5_bits_pdest,
  input  io_wakeUpFromWB_4_valid,
  input  io_wakeUpFromWB_4_bits_vecWen,
  input  [7:0] io_wakeUpFromWB_4_bits_pdest,
  input  io_wakeUpFromWB_3_valid,
  input  io_wakeUpFromWB_3_bits_vecWen,
  input  [7:0] io_wakeUpFromWB_3_bits_pdest,
  input  io_wakeUpFromWB_2_valid,
  input  io_wakeUpFromWB_2_bits_vecWen,
  input  [7:0] io_wakeUpFromWB_2_bits_pdest,
  input  io_wakeUpFromWB_1_valid,
  input  io_wakeUpFromWB_1_bits_vecWen,
  input  [7:0] io_wakeUpFromWB_1_bits_pdest,
  input  io_wakeUpFromWB_0_valid,
  input  io_wakeUpFromWB_0_bits_vecWen,
  input  [7:0] io_wakeUpFromWB_0_bits_pdest,
  input  io_wakeUpFromWBDelayed_15_valid,
  input  io_wakeUpFromWBDelayed_15_bits_vlWen,
  input  [7:0] io_wakeUpFromWBDelayed_15_bits_pdest,
  input  io_wakeUpFromWBDelayed_14_valid,
  input  io_wakeUpFromWBDelayed_14_bits_vlWen,
  input  [7:0] io_wakeUpFromWBDelayed_14_bits_pdest,
  input  io_wakeUpFromWBDelayed_13_valid,
  input  io_wakeUpFromWBDelayed_13_bits_vlWen,
  input  [7:0] io_wakeUpFromWBDelayed_13_bits_pdest,
  input  io_wakeUpFromWBDelayed_12_valid,
  input  io_wakeUpFromWBDelayed_12_bits_vlWen,
  input  [7:0] io_wakeUpFromWBDelayed_12_bits_pdest,
  input  io_wakeUpFromWBDelayed_11_valid,
  input  io_wakeUpFromWBDelayed_11_bits_v0Wen,
  input  [7:0] io_wakeUpFromWBDelayed_11_bits_pdest,
  input  io_wakeUpFromWBDelayed_10_valid,
  input  io_wakeUpFromWBDelayed_10_bits_v0Wen,
  input  [7:0] io_wakeUpFromWBDelayed_10_bits_pdest,
  input  io_wakeUpFromWBDelayed_9_valid,
  input  io_wakeUpFromWBDelayed_9_bits_v0Wen,
  input  [7:0] io_wakeUpFromWBDelayed_9_bits_pdest,
  input  io_wakeUpFromWBDelayed_8_valid,
  input  io_wakeUpFromWBDelayed_8_bits_v0Wen,
  input  [7:0] io_wakeUpFromWBDelayed_8_bits_pdest,
  input  io_wakeUpFromWBDelayed_7_valid,
  input  io_wakeUpFromWBDelayed_7_bits_v0Wen,
  input  [7:0] io_wakeUpFromWBDelayed_7_bits_pdest,
  input  io_wakeUpFromWBDelayed_6_valid,
  input  io_wakeUpFromWBDelayed_6_bits_v0Wen,
  input  [7:0] io_wakeUpFromWBDelayed_6_bits_pdest,
  input  io_wakeUpFromWBDelayed_5_valid,
  input  io_wakeUpFromWBDelayed_5_bits_vecWen,
  input  [7:0] io_wakeUpFromWBDelayed_5_bits_pdest,
  input  io_wakeUpFromWBDelayed_4_valid,
  input  io_wakeUpFromWBDelayed_4_bits_vecWen,
  input  [7:0] io_wakeUpFromWBDelayed_4_bits_pdest,
  input  io_wakeUpFromWBDelayed_3_valid,
  input  io_wakeUpFromWBDelayed_3_bits_vecWen,
  input  [7:0] io_wakeUpFromWBDelayed_3_bits_pdest,
  input  io_wakeUpFromWBDelayed_2_valid,
  input  io_wakeUpFromWBDelayed_2_bits_vecWen,
  input  [7:0] io_wakeUpFromWBDelayed_2_bits_pdest,
  input  io_wakeUpFromWBDelayed_1_valid,
  input  io_wakeUpFromWBDelayed_1_bits_vecWen,
  input  [7:0] io_wakeUpFromWBDelayed_1_bits_pdest,
  input  io_wakeUpFromWBDelayed_0_valid,
  input  io_wakeUpFromWBDelayed_0_bits_vecWen,
  input  [7:0] io_wakeUpFromWBDelayed_0_bits_pdest,
  input  io_vlFromIntIsZero,
  input  io_vlFromIntIsVlmax,
  input  io_vlFromVfIsZero,
  input  io_vlFromVfIsVlmax,
  output [15:0] io_valid,
  output [15:0] io_issued,
  output [15:0] io_canIssue,
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
  output [3:0] io_dataSources_0_0_value,
  output [3:0] io_dataSources_0_1_value,
  output [3:0] io_dataSources_0_2_value,
  output [3:0] io_dataSources_0_3_value,
  output [3:0] io_dataSources_0_4_value,
  output [3:0] io_dataSources_1_0_value,
  output [3:0] io_dataSources_1_1_value,
  output [3:0] io_dataSources_1_2_value,
  output [3:0] io_dataSources_1_3_value,
  output [3:0] io_dataSources_1_4_value,
  output [3:0] io_dataSources_2_0_value,
  output [3:0] io_dataSources_2_1_value,
  output [3:0] io_dataSources_2_2_value,
  output [3:0] io_dataSources_2_3_value,
  output [3:0] io_dataSources_2_4_value,
  output [3:0] io_dataSources_3_0_value,
  output [3:0] io_dataSources_3_1_value,
  output [3:0] io_dataSources_3_2_value,
  output [3:0] io_dataSources_3_3_value,
  output [3:0] io_dataSources_3_4_value,
  output [3:0] io_dataSources_4_0_value,
  output [3:0] io_dataSources_4_1_value,
  output [3:0] io_dataSources_4_2_value,
  output [3:0] io_dataSources_4_3_value,
  output [3:0] io_dataSources_4_4_value,
  output [3:0] io_dataSources_5_0_value,
  output [3:0] io_dataSources_5_1_value,
  output [3:0] io_dataSources_5_2_value,
  output [3:0] io_dataSources_5_3_value,
  output [3:0] io_dataSources_5_4_value,
  output [3:0] io_dataSources_6_0_value,
  output [3:0] io_dataSources_6_1_value,
  output [3:0] io_dataSources_6_2_value,
  output [3:0] io_dataSources_6_3_value,
  output [3:0] io_dataSources_6_4_value,
  output [3:0] io_dataSources_7_0_value,
  output [3:0] io_dataSources_7_1_value,
  output [3:0] io_dataSources_7_2_value,
  output [3:0] io_dataSources_7_3_value,
  output [3:0] io_dataSources_7_4_value,
  output [3:0] io_dataSources_8_0_value,
  output [3:0] io_dataSources_8_1_value,
  output [3:0] io_dataSources_8_2_value,
  output [3:0] io_dataSources_8_3_value,
  output [3:0] io_dataSources_8_4_value,
  output [3:0] io_dataSources_9_0_value,
  output [3:0] io_dataSources_9_1_value,
  output [3:0] io_dataSources_9_2_value,
  output [3:0] io_dataSources_9_3_value,
  output [3:0] io_dataSources_9_4_value,
  output [3:0] io_dataSources_10_0_value,
  output [3:0] io_dataSources_10_1_value,
  output [3:0] io_dataSources_10_2_value,
  output [3:0] io_dataSources_10_3_value,
  output [3:0] io_dataSources_10_4_value,
  output [3:0] io_dataSources_11_0_value,
  output [3:0] io_dataSources_11_1_value,
  output [3:0] io_dataSources_11_2_value,
  output [3:0] io_dataSources_11_3_value,
  output [3:0] io_dataSources_11_4_value,
  output [3:0] io_dataSources_12_0_value,
  output [3:0] io_dataSources_12_1_value,
  output [3:0] io_dataSources_12_2_value,
  output [3:0] io_dataSources_12_3_value,
  output [3:0] io_dataSources_12_4_value,
  output [3:0] io_dataSources_13_0_value,
  output [3:0] io_dataSources_13_1_value,
  output [3:0] io_dataSources_13_2_value,
  output [3:0] io_dataSources_13_3_value,
  output [3:0] io_dataSources_13_4_value,
  output [3:0] io_dataSources_14_0_value,
  output [3:0] io_dataSources_14_1_value,
  output [3:0] io_dataSources_14_2_value,
  output [3:0] io_dataSources_14_3_value,
  output [3:0] io_dataSources_14_4_value,
  output [3:0] io_dataSources_15_0_value,
  output [3:0] io_dataSources_15_1_value,
  output [3:0] io_dataSources_15_2_value,
  output [3:0] io_dataSources_15_3_value,
  output [3:0] io_dataSources_15_4_value,
  output io_deqEntry_0_bits_status_robIdx_flag,
  output [7:0] io_deqEntry_0_bits_status_robIdx_value,
  output io_deqEntry_0_bits_status_fuType_19,
  output io_deqEntry_0_bits_status_fuType_24,
  output io_deqEntry_0_bits_status_fuType_25,
  output [6:0] io_deqEntry_0_bits_status_srcStatus_0_psrc,
  output [3:0] io_deqEntry_0_bits_status_srcStatus_0_srcType,
  output [6:0] io_deqEntry_0_bits_status_srcStatus_1_psrc,
  output [3:0] io_deqEntry_0_bits_status_srcStatus_1_srcType,
  output [6:0] io_deqEntry_0_bits_status_srcStatus_2_psrc,
  output [3:0] io_deqEntry_0_bits_status_srcStatus_2_srcType,
  output [6:0] io_deqEntry_0_bits_status_srcStatus_3_psrc,
  output [3:0] io_deqEntry_0_bits_status_srcStatus_3_srcType,
  output [6:0] io_deqEntry_0_bits_status_srcStatus_4_psrc,
  output [3:0] io_deqEntry_0_bits_status_srcStatus_4_srcType,
  output [8:0] io_deqEntry_0_bits_payload_fuOpType,
  output io_deqEntry_0_bits_payload_vecWen,
  output io_deqEntry_0_bits_payload_v0Wen,
  output io_deqEntry_0_bits_payload_fpu_wflags,
  output io_deqEntry_0_bits_payload_vpu_vma,
  output io_deqEntry_0_bits_payload_vpu_vta,
  output [1:0] io_deqEntry_0_bits_payload_vpu_vsew,
  output [2:0] io_deqEntry_0_bits_payload_vpu_vlmul,
  output io_deqEntry_0_bits_payload_vpu_vm,
  output [7:0] io_deqEntry_0_bits_payload_vpu_vstart,
  output io_deqEntry_0_bits_payload_vpu_isExt,
  output io_deqEntry_0_bits_payload_vpu_isNarrow,
  output io_deqEntry_0_bits_payload_vpu_isDstMask,
  output io_deqEntry_0_bits_payload_vpu_isOpMask,
  output [6:0] io_deqEntry_0_bits_payload_uopIdx,
  output [7:0] io_deqEntry_0_bits_payload_pdest,
  output io_deqEntry_1_bits_status_robIdx_flag,
  output [7:0] io_deqEntry_1_bits_status_robIdx_value,
  output io_deqEntry_1_bits_status_fuType_19,
  output io_deqEntry_1_bits_status_fuType_24,
  output io_deqEntry_1_bits_status_fuType_25,
  output [6:0] io_deqEntry_1_bits_status_srcStatus_0_psrc,
  output [3:0] io_deqEntry_1_bits_status_srcStatus_0_srcType,
  output [6:0] io_deqEntry_1_bits_status_srcStatus_1_psrc,
  output [3:0] io_deqEntry_1_bits_status_srcStatus_1_srcType,
  output [6:0] io_deqEntry_1_bits_status_srcStatus_2_psrc,
  output [3:0] io_deqEntry_1_bits_status_srcStatus_2_srcType,
  output [6:0] io_deqEntry_1_bits_status_srcStatus_3_psrc,
  output [3:0] io_deqEntry_1_bits_status_srcStatus_3_srcType,
  output [6:0] io_deqEntry_1_bits_status_srcStatus_4_psrc,
  output [3:0] io_deqEntry_1_bits_status_srcStatus_4_srcType,
  output [8:0] io_deqEntry_1_bits_payload_fuOpType,
  output io_deqEntry_1_bits_payload_fpWen,
  output io_deqEntry_1_bits_payload_vecWen,
  output io_deqEntry_1_bits_payload_v0Wen,
  output io_deqEntry_1_bits_payload_fpu_wflags,
  output io_deqEntry_1_bits_payload_vpu_vma,
  output io_deqEntry_1_bits_payload_vpu_vta,
  output [1:0] io_deqEntry_1_bits_payload_vpu_vsew,
  output [2:0] io_deqEntry_1_bits_payload_vpu_vlmul,
  output io_deqEntry_1_bits_payload_vpu_vm,
  output [7:0] io_deqEntry_1_bits_payload_vpu_vstart,
  output io_deqEntry_1_bits_payload_vpu_fpu_isFoldTo1_2,
  output io_deqEntry_1_bits_payload_vpu_fpu_isFoldTo1_4,
  output io_deqEntry_1_bits_payload_vpu_fpu_isFoldTo1_8,
  output io_deqEntry_1_bits_payload_vpu_isNarrow,
  output io_deqEntry_1_bits_payload_vpu_isDstMask,
  output [6:0] io_deqEntry_1_bits_payload_uopIdx,
  output io_deqEntry_1_bits_payload_lastUop,
  output [7:0] io_deqEntry_1_bits_payload_pdest,
  input  [1:0] io_simpEntryDeqSelVec_0,
  input  [1:0] io_simpEntryDeqSelVec_1,
  output [1:0] io_simpEntryEnqSelVec_0,
  output [1:0] io_simpEntryEnqSelVec_1,
  output [11:0] io_compEntryEnqSelVec_0,
  output [11:0] io_compEntryEnqSelVec_1
);
  logic                  c_flush_valid, c_flush_rob_flag, c_flush_level;
  logic [7:0]            c_flush_rob_value;
  logic [1:0]            c_enq_valid;
  entry_t [1:0]          c_enq_bits;
  wk_wb_t [15:0]         c_wk_wb, c_wk_wb_d;
  vl_info_t              c_vl;
  og_resp_t [1:0]        c_og_resp;
  logic [1:0]            c_deq_sel_oh_valid;
  logic [1:0][15:0]      c_deq_sel_oh_bits;
  logic [1:0][1:0]       c_enq_oldest_sel_bits;
  logic [1:0]            c_simp_oldest_sel_valid, c_comp_oldest_sel_valid;
  logic [1:0][1:0]       c_simp_oldest_sel_bits;
  logic [1:0][11:0]      c_comp_oldest_sel_bits;
  logic [1:0][1:0]       c_simp_deq_sel_vec;
  logic [15:0]           c_valid, c_issued, c_can_issue;
  logic [15:0][34:0]     c_fu_type;
  logic [15:0][4:0][3:0] c_data_sources;
  entry_t [1:0]          c_deq_entry;
  logic [1:0][1:0]       c_simp_enq_sel_vec;
  logic [1:0][11:0]      c_comp_enq_sel_vec;
  always_comb begin
    c_enq_bits = '0;
    c_wk_wb = '0; c_wk_wb_d = '0;
    c_flush_valid = io_flush_valid;
    c_flush_rob_flag = io_flush_bits_robIdx_flag;
    c_flush_rob_value = io_flush_bits_robIdx_value;
    c_flush_level = io_flush_bits_level;
    c_enq_valid[0] = io_enq_0_valid;
    c_enq_bits[0].status.rob_flag = io_enq_0_bits_status_robIdx_flag;
    c_enq_bits[0].status.rob_value = io_enq_0_bits_status_robIdx_value;
    c_enq_bits[0].status.fu_type_vialuf = io_enq_0_bits_status_fuType_19;
    c_enq_bits[0].status.fu_type_vfalu = io_enq_0_bits_status_fuType_24;
    c_enq_bits[0].status.fu_type_vfma = io_enq_0_bits_status_fuType_25;
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
    c_enq_bits[0].status.src[3].psrc = io_enq_0_bits_status_srcStatus_3_psrc;
    c_enq_bits[0].status.src[3].src_type = io_enq_0_bits_status_srcStatus_3_srcType;
    c_enq_bits[0].status.src[3].src_state = io_enq_0_bits_status_srcStatus_3_srcState;
    c_enq_bits[0].status.src[3].data_src = io_enq_0_bits_status_srcStatus_3_dataSources_value;
    c_enq_bits[0].status.src[4].psrc = io_enq_0_bits_status_srcStatus_4_psrc;
    c_enq_bits[0].status.src[4].src_type = io_enq_0_bits_status_srcStatus_4_srcType;
    c_enq_bits[0].status.src[4].src_state = io_enq_0_bits_status_srcStatus_4_srcState;
    c_enq_bits[0].status.src[4].data_src = io_enq_0_bits_status_srcStatus_4_dataSources_value;
    c_enq_bits[0].payload.fu_op_type = io_enq_0_bits_payload_fuOpType;
    c_enq_bits[0].payload.fp_wen = io_enq_0_bits_payload_fpWen;
    c_enq_bits[0].payload.vec_wen = io_enq_0_bits_payload_vecWen;
    c_enq_bits[0].payload.v0_wen = io_enq_0_bits_payload_v0Wen;
    c_enq_bits[0].payload.fpu_wflags = io_enq_0_bits_payload_fpu_wflags;
    c_enq_bits[0].payload.vpu.vma = io_enq_0_bits_payload_vpu_vma;
    c_enq_bits[0].payload.vpu.vta = io_enq_0_bits_payload_vpu_vta;
    c_enq_bits[0].payload.vpu.vsew = io_enq_0_bits_payload_vpu_vsew;
    c_enq_bits[0].payload.vpu.vlmul = io_enq_0_bits_payload_vpu_vlmul;
    c_enq_bits[0].payload.vpu.vm = io_enq_0_bits_payload_vpu_vm;
    c_enq_bits[0].payload.vpu.vstart = io_enq_0_bits_payload_vpu_vstart;
    c_enq_bits[0].payload.vpu.fpu_is_fold_to_1_2 = io_enq_0_bits_payload_vpu_fpu_isFoldTo1_2;
    c_enq_bits[0].payload.vpu.fpu_is_fold_to_1_4 = io_enq_0_bits_payload_vpu_fpu_isFoldTo1_4;
    c_enq_bits[0].payload.vpu.fpu_is_fold_to_1_8 = io_enq_0_bits_payload_vpu_fpu_isFoldTo1_8;
    c_enq_bits[0].payload.vpu.is_ext = io_enq_0_bits_payload_vpu_isExt;
    c_enq_bits[0].payload.vpu.is_narrow = io_enq_0_bits_payload_vpu_isNarrow;
    c_enq_bits[0].payload.vpu.is_dst_mask = io_enq_0_bits_payload_vpu_isDstMask;
    c_enq_bits[0].payload.vpu.is_op_mask = io_enq_0_bits_payload_vpu_isOpMask;
    c_enq_bits[0].payload.vpu.is_depend_old_vd = io_enq_0_bits_payload_vpu_isDependOldVd;
    c_enq_bits[0].payload.vpu.is_write_part_vd = io_enq_0_bits_payload_vpu_isWritePartVd;
    c_enq_bits[0].payload.uop_idx = io_enq_0_bits_payload_uopIdx;
    c_enq_bits[0].payload.last_uop = io_enq_0_bits_payload_lastUop;
    c_enq_bits[0].payload.pdest = io_enq_0_bits_payload_pdest;
    c_enq_valid[1] = io_enq_1_valid;
    c_enq_bits[1].status.rob_flag = io_enq_1_bits_status_robIdx_flag;
    c_enq_bits[1].status.rob_value = io_enq_1_bits_status_robIdx_value;
    c_enq_bits[1].status.fu_type_vialuf = io_enq_1_bits_status_fuType_19;
    c_enq_bits[1].status.fu_type_vfalu = io_enq_1_bits_status_fuType_24;
    c_enq_bits[1].status.fu_type_vfma = io_enq_1_bits_status_fuType_25;
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
    c_enq_bits[1].status.src[3].psrc = io_enq_1_bits_status_srcStatus_3_psrc;
    c_enq_bits[1].status.src[3].src_type = io_enq_1_bits_status_srcStatus_3_srcType;
    c_enq_bits[1].status.src[3].src_state = io_enq_1_bits_status_srcStatus_3_srcState;
    c_enq_bits[1].status.src[3].data_src = io_enq_1_bits_status_srcStatus_3_dataSources_value;
    c_enq_bits[1].status.src[4].psrc = io_enq_1_bits_status_srcStatus_4_psrc;
    c_enq_bits[1].status.src[4].src_type = io_enq_1_bits_status_srcStatus_4_srcType;
    c_enq_bits[1].status.src[4].src_state = io_enq_1_bits_status_srcStatus_4_srcState;
    c_enq_bits[1].status.src[4].data_src = io_enq_1_bits_status_srcStatus_4_dataSources_value;
    c_enq_bits[1].payload.fu_op_type = io_enq_1_bits_payload_fuOpType;
    c_enq_bits[1].payload.fp_wen = io_enq_1_bits_payload_fpWen;
    c_enq_bits[1].payload.vec_wen = io_enq_1_bits_payload_vecWen;
    c_enq_bits[1].payload.v0_wen = io_enq_1_bits_payload_v0Wen;
    c_enq_bits[1].payload.fpu_wflags = io_enq_1_bits_payload_fpu_wflags;
    c_enq_bits[1].payload.vpu.vma = io_enq_1_bits_payload_vpu_vma;
    c_enq_bits[1].payload.vpu.vta = io_enq_1_bits_payload_vpu_vta;
    c_enq_bits[1].payload.vpu.vsew = io_enq_1_bits_payload_vpu_vsew;
    c_enq_bits[1].payload.vpu.vlmul = io_enq_1_bits_payload_vpu_vlmul;
    c_enq_bits[1].payload.vpu.vm = io_enq_1_bits_payload_vpu_vm;
    c_enq_bits[1].payload.vpu.vstart = io_enq_1_bits_payload_vpu_vstart;
    c_enq_bits[1].payload.vpu.fpu_is_fold_to_1_2 = io_enq_1_bits_payload_vpu_fpu_isFoldTo1_2;
    c_enq_bits[1].payload.vpu.fpu_is_fold_to_1_4 = io_enq_1_bits_payload_vpu_fpu_isFoldTo1_4;
    c_enq_bits[1].payload.vpu.fpu_is_fold_to_1_8 = io_enq_1_bits_payload_vpu_fpu_isFoldTo1_8;
    c_enq_bits[1].payload.vpu.is_ext = io_enq_1_bits_payload_vpu_isExt;
    c_enq_bits[1].payload.vpu.is_narrow = io_enq_1_bits_payload_vpu_isNarrow;
    c_enq_bits[1].payload.vpu.is_dst_mask = io_enq_1_bits_payload_vpu_isDstMask;
    c_enq_bits[1].payload.vpu.is_op_mask = io_enq_1_bits_payload_vpu_isOpMask;
    c_enq_bits[1].payload.vpu.is_depend_old_vd = io_enq_1_bits_payload_vpu_isDependOldVd;
    c_enq_bits[1].payload.vpu.is_write_part_vd = io_enq_1_bits_payload_vpu_isWritePartVd;
    c_enq_bits[1].payload.uop_idx = io_enq_1_bits_payload_uopIdx;
    c_enq_bits[1].payload.last_uop = io_enq_1_bits_payload_lastUop;
    c_enq_bits[1].payload.pdest = io_enq_1_bits_payload_pdest;
    c_og_resp[0].og0_valid = io_og0Resp_0_valid;
    c_og_resp[1].og0_valid = io_og0Resp_1_valid;
    c_og_resp[0].og1_valid = io_og1Resp_0_valid;
    c_og_resp[1].og1_valid = io_og1Resp_1_valid;
    c_og_resp[0].og2_valid = io_og2Resp_0_valid;
    c_og_resp[0].og2_resp = io_og2Resp_0_bits_resp;
    c_og_resp[1].og2_valid = io_og2Resp_1_valid;
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
    c_wk_wb[15].valid = io_wakeUpFromWB_15_valid;
    c_wk_wb[15].wen = io_wakeUpFromWB_15_bits_vlWen;
    c_wk_wb[15].pdest = io_wakeUpFromWB_15_bits_pdest;
    c_wk_wb[14].valid = io_wakeUpFromWB_14_valid;
    c_wk_wb[14].wen = io_wakeUpFromWB_14_bits_vlWen;
    c_wk_wb[14].pdest = io_wakeUpFromWB_14_bits_pdest;
    c_wk_wb[13].valid = io_wakeUpFromWB_13_valid;
    c_wk_wb[13].wen = io_wakeUpFromWB_13_bits_vlWen;
    c_wk_wb[13].pdest = io_wakeUpFromWB_13_bits_pdest;
    c_wk_wb[12].valid = io_wakeUpFromWB_12_valid;
    c_wk_wb[12].wen = io_wakeUpFromWB_12_bits_vlWen;
    c_wk_wb[12].pdest = io_wakeUpFromWB_12_bits_pdest;
    c_wk_wb[11].valid = io_wakeUpFromWB_11_valid;
    c_wk_wb[11].wen = io_wakeUpFromWB_11_bits_v0Wen;
    c_wk_wb[11].pdest = io_wakeUpFromWB_11_bits_pdest;
    c_wk_wb[10].valid = io_wakeUpFromWB_10_valid;
    c_wk_wb[10].wen = io_wakeUpFromWB_10_bits_v0Wen;
    c_wk_wb[10].pdest = io_wakeUpFromWB_10_bits_pdest;
    c_wk_wb[9].valid = io_wakeUpFromWB_9_valid;
    c_wk_wb[9].wen = io_wakeUpFromWB_9_bits_v0Wen;
    c_wk_wb[9].pdest = io_wakeUpFromWB_9_bits_pdest;
    c_wk_wb[8].valid = io_wakeUpFromWB_8_valid;
    c_wk_wb[8].wen = io_wakeUpFromWB_8_bits_v0Wen;
    c_wk_wb[8].pdest = io_wakeUpFromWB_8_bits_pdest;
    c_wk_wb[7].valid = io_wakeUpFromWB_7_valid;
    c_wk_wb[7].wen = io_wakeUpFromWB_7_bits_v0Wen;
    c_wk_wb[7].pdest = io_wakeUpFromWB_7_bits_pdest;
    c_wk_wb[6].valid = io_wakeUpFromWB_6_valid;
    c_wk_wb[6].wen = io_wakeUpFromWB_6_bits_v0Wen;
    c_wk_wb[6].pdest = io_wakeUpFromWB_6_bits_pdest;
    c_wk_wb[5].valid = io_wakeUpFromWB_5_valid;
    c_wk_wb[5].wen = io_wakeUpFromWB_5_bits_vecWen;
    c_wk_wb[5].pdest = io_wakeUpFromWB_5_bits_pdest;
    c_wk_wb[4].valid = io_wakeUpFromWB_4_valid;
    c_wk_wb[4].wen = io_wakeUpFromWB_4_bits_vecWen;
    c_wk_wb[4].pdest = io_wakeUpFromWB_4_bits_pdest;
    c_wk_wb[3].valid = io_wakeUpFromWB_3_valid;
    c_wk_wb[3].wen = io_wakeUpFromWB_3_bits_vecWen;
    c_wk_wb[3].pdest = io_wakeUpFromWB_3_bits_pdest;
    c_wk_wb[2].valid = io_wakeUpFromWB_2_valid;
    c_wk_wb[2].wen = io_wakeUpFromWB_2_bits_vecWen;
    c_wk_wb[2].pdest = io_wakeUpFromWB_2_bits_pdest;
    c_wk_wb[1].valid = io_wakeUpFromWB_1_valid;
    c_wk_wb[1].wen = io_wakeUpFromWB_1_bits_vecWen;
    c_wk_wb[1].pdest = io_wakeUpFromWB_1_bits_pdest;
    c_wk_wb[0].valid = io_wakeUpFromWB_0_valid;
    c_wk_wb[0].wen = io_wakeUpFromWB_0_bits_vecWen;
    c_wk_wb[0].pdest = io_wakeUpFromWB_0_bits_pdest;
    c_wk_wb_d[15].valid = io_wakeUpFromWBDelayed_15_valid;
    c_wk_wb_d[15].wen = io_wakeUpFromWBDelayed_15_bits_vlWen;
    c_wk_wb_d[15].pdest = io_wakeUpFromWBDelayed_15_bits_pdest;
    c_wk_wb_d[14].valid = io_wakeUpFromWBDelayed_14_valid;
    c_wk_wb_d[14].wen = io_wakeUpFromWBDelayed_14_bits_vlWen;
    c_wk_wb_d[14].pdest = io_wakeUpFromWBDelayed_14_bits_pdest;
    c_wk_wb_d[13].valid = io_wakeUpFromWBDelayed_13_valid;
    c_wk_wb_d[13].wen = io_wakeUpFromWBDelayed_13_bits_vlWen;
    c_wk_wb_d[13].pdest = io_wakeUpFromWBDelayed_13_bits_pdest;
    c_wk_wb_d[12].valid = io_wakeUpFromWBDelayed_12_valid;
    c_wk_wb_d[12].wen = io_wakeUpFromWBDelayed_12_bits_vlWen;
    c_wk_wb_d[12].pdest = io_wakeUpFromWBDelayed_12_bits_pdest;
    c_wk_wb_d[11].valid = io_wakeUpFromWBDelayed_11_valid;
    c_wk_wb_d[11].wen = io_wakeUpFromWBDelayed_11_bits_v0Wen;
    c_wk_wb_d[11].pdest = io_wakeUpFromWBDelayed_11_bits_pdest;
    c_wk_wb_d[10].valid = io_wakeUpFromWBDelayed_10_valid;
    c_wk_wb_d[10].wen = io_wakeUpFromWBDelayed_10_bits_v0Wen;
    c_wk_wb_d[10].pdest = io_wakeUpFromWBDelayed_10_bits_pdest;
    c_wk_wb_d[9].valid = io_wakeUpFromWBDelayed_9_valid;
    c_wk_wb_d[9].wen = io_wakeUpFromWBDelayed_9_bits_v0Wen;
    c_wk_wb_d[9].pdest = io_wakeUpFromWBDelayed_9_bits_pdest;
    c_wk_wb_d[8].valid = io_wakeUpFromWBDelayed_8_valid;
    c_wk_wb_d[8].wen = io_wakeUpFromWBDelayed_8_bits_v0Wen;
    c_wk_wb_d[8].pdest = io_wakeUpFromWBDelayed_8_bits_pdest;
    c_wk_wb_d[7].valid = io_wakeUpFromWBDelayed_7_valid;
    c_wk_wb_d[7].wen = io_wakeUpFromWBDelayed_7_bits_v0Wen;
    c_wk_wb_d[7].pdest = io_wakeUpFromWBDelayed_7_bits_pdest;
    c_wk_wb_d[6].valid = io_wakeUpFromWBDelayed_6_valid;
    c_wk_wb_d[6].wen = io_wakeUpFromWBDelayed_6_bits_v0Wen;
    c_wk_wb_d[6].pdest = io_wakeUpFromWBDelayed_6_bits_pdest;
    c_wk_wb_d[5].valid = io_wakeUpFromWBDelayed_5_valid;
    c_wk_wb_d[5].wen = io_wakeUpFromWBDelayed_5_bits_vecWen;
    c_wk_wb_d[5].pdest = io_wakeUpFromWBDelayed_5_bits_pdest;
    c_wk_wb_d[4].valid = io_wakeUpFromWBDelayed_4_valid;
    c_wk_wb_d[4].wen = io_wakeUpFromWBDelayed_4_bits_vecWen;
    c_wk_wb_d[4].pdest = io_wakeUpFromWBDelayed_4_bits_pdest;
    c_wk_wb_d[3].valid = io_wakeUpFromWBDelayed_3_valid;
    c_wk_wb_d[3].wen = io_wakeUpFromWBDelayed_3_bits_vecWen;
    c_wk_wb_d[3].pdest = io_wakeUpFromWBDelayed_3_bits_pdest;
    c_wk_wb_d[2].valid = io_wakeUpFromWBDelayed_2_valid;
    c_wk_wb_d[2].wen = io_wakeUpFromWBDelayed_2_bits_vecWen;
    c_wk_wb_d[2].pdest = io_wakeUpFromWBDelayed_2_bits_pdest;
    c_wk_wb_d[1].valid = io_wakeUpFromWBDelayed_1_valid;
    c_wk_wb_d[1].wen = io_wakeUpFromWBDelayed_1_bits_vecWen;
    c_wk_wb_d[1].pdest = io_wakeUpFromWBDelayed_1_bits_pdest;
    c_wk_wb_d[0].valid = io_wakeUpFromWBDelayed_0_valid;
    c_wk_wb_d[0].wen = io_wakeUpFromWBDelayed_0_bits_vecWen;
    c_wk_wb_d[0].pdest = io_wakeUpFromWBDelayed_0_bits_pdest;
    c_vl.int_is_zero = io_vlFromIntIsZero;
    c_vl.int_is_vlmax = io_vlFromIntIsVlmax;
    c_vl.vf_is_zero = io_vlFromVfIsZero;
    c_vl.vf_is_vlmax = io_vlFromVfIsVlmax;
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
  assign io_dataSources_0_0_value = c_data_sources[0][0];
  assign io_dataSources_0_1_value = c_data_sources[0][1];
  assign io_dataSources_0_2_value = c_data_sources[0][2];
  assign io_dataSources_0_3_value = c_data_sources[0][3];
  assign io_dataSources_0_4_value = c_data_sources[0][4];
  assign io_dataSources_1_0_value = c_data_sources[1][0];
  assign io_dataSources_1_1_value = c_data_sources[1][1];
  assign io_dataSources_1_2_value = c_data_sources[1][2];
  assign io_dataSources_1_3_value = c_data_sources[1][3];
  assign io_dataSources_1_4_value = c_data_sources[1][4];
  assign io_dataSources_2_0_value = c_data_sources[2][0];
  assign io_dataSources_2_1_value = c_data_sources[2][1];
  assign io_dataSources_2_2_value = c_data_sources[2][2];
  assign io_dataSources_2_3_value = c_data_sources[2][3];
  assign io_dataSources_2_4_value = c_data_sources[2][4];
  assign io_dataSources_3_0_value = c_data_sources[3][0];
  assign io_dataSources_3_1_value = c_data_sources[3][1];
  assign io_dataSources_3_2_value = c_data_sources[3][2];
  assign io_dataSources_3_3_value = c_data_sources[3][3];
  assign io_dataSources_3_4_value = c_data_sources[3][4];
  assign io_dataSources_4_0_value = c_data_sources[4][0];
  assign io_dataSources_4_1_value = c_data_sources[4][1];
  assign io_dataSources_4_2_value = c_data_sources[4][2];
  assign io_dataSources_4_3_value = c_data_sources[4][3];
  assign io_dataSources_4_4_value = c_data_sources[4][4];
  assign io_dataSources_5_0_value = c_data_sources[5][0];
  assign io_dataSources_5_1_value = c_data_sources[5][1];
  assign io_dataSources_5_2_value = c_data_sources[5][2];
  assign io_dataSources_5_3_value = c_data_sources[5][3];
  assign io_dataSources_5_4_value = c_data_sources[5][4];
  assign io_dataSources_6_0_value = c_data_sources[6][0];
  assign io_dataSources_6_1_value = c_data_sources[6][1];
  assign io_dataSources_6_2_value = c_data_sources[6][2];
  assign io_dataSources_6_3_value = c_data_sources[6][3];
  assign io_dataSources_6_4_value = c_data_sources[6][4];
  assign io_dataSources_7_0_value = c_data_sources[7][0];
  assign io_dataSources_7_1_value = c_data_sources[7][1];
  assign io_dataSources_7_2_value = c_data_sources[7][2];
  assign io_dataSources_7_3_value = c_data_sources[7][3];
  assign io_dataSources_7_4_value = c_data_sources[7][4];
  assign io_dataSources_8_0_value = c_data_sources[8][0];
  assign io_dataSources_8_1_value = c_data_sources[8][1];
  assign io_dataSources_8_2_value = c_data_sources[8][2];
  assign io_dataSources_8_3_value = c_data_sources[8][3];
  assign io_dataSources_8_4_value = c_data_sources[8][4];
  assign io_dataSources_9_0_value = c_data_sources[9][0];
  assign io_dataSources_9_1_value = c_data_sources[9][1];
  assign io_dataSources_9_2_value = c_data_sources[9][2];
  assign io_dataSources_9_3_value = c_data_sources[9][3];
  assign io_dataSources_9_4_value = c_data_sources[9][4];
  assign io_dataSources_10_0_value = c_data_sources[10][0];
  assign io_dataSources_10_1_value = c_data_sources[10][1];
  assign io_dataSources_10_2_value = c_data_sources[10][2];
  assign io_dataSources_10_3_value = c_data_sources[10][3];
  assign io_dataSources_10_4_value = c_data_sources[10][4];
  assign io_dataSources_11_0_value = c_data_sources[11][0];
  assign io_dataSources_11_1_value = c_data_sources[11][1];
  assign io_dataSources_11_2_value = c_data_sources[11][2];
  assign io_dataSources_11_3_value = c_data_sources[11][3];
  assign io_dataSources_11_4_value = c_data_sources[11][4];
  assign io_dataSources_12_0_value = c_data_sources[12][0];
  assign io_dataSources_12_1_value = c_data_sources[12][1];
  assign io_dataSources_12_2_value = c_data_sources[12][2];
  assign io_dataSources_12_3_value = c_data_sources[12][3];
  assign io_dataSources_12_4_value = c_data_sources[12][4];
  assign io_dataSources_13_0_value = c_data_sources[13][0];
  assign io_dataSources_13_1_value = c_data_sources[13][1];
  assign io_dataSources_13_2_value = c_data_sources[13][2];
  assign io_dataSources_13_3_value = c_data_sources[13][3];
  assign io_dataSources_13_4_value = c_data_sources[13][4];
  assign io_dataSources_14_0_value = c_data_sources[14][0];
  assign io_dataSources_14_1_value = c_data_sources[14][1];
  assign io_dataSources_14_2_value = c_data_sources[14][2];
  assign io_dataSources_14_3_value = c_data_sources[14][3];
  assign io_dataSources_14_4_value = c_data_sources[14][4];
  assign io_dataSources_15_0_value = c_data_sources[15][0];
  assign io_dataSources_15_1_value = c_data_sources[15][1];
  assign io_dataSources_15_2_value = c_data_sources[15][2];
  assign io_dataSources_15_3_value = c_data_sources[15][3];
  assign io_dataSources_15_4_value = c_data_sources[15][4];
  assign io_deqEntry_0_bits_status_robIdx_flag = c_deq_entry[0].status.rob_flag;
  assign io_deqEntry_0_bits_status_robIdx_value = c_deq_entry[0].status.rob_value;
  assign io_deqEntry_0_bits_status_fuType_19 = c_deq_entry[0].status.fu_type_vialuf;
  assign io_deqEntry_0_bits_status_fuType_24 = c_deq_entry[0].status.fu_type_vfalu;
  assign io_deqEntry_0_bits_status_fuType_25 = c_deq_entry[0].status.fu_type_vfma;
  assign io_deqEntry_0_bits_status_srcStatus_0_psrc = c_deq_entry[0].status.src[0].psrc;
  assign io_deqEntry_0_bits_status_srcStatus_0_srcType = c_deq_entry[0].status.src[0].src_type;
  assign io_deqEntry_0_bits_status_srcStatus_1_psrc = c_deq_entry[0].status.src[1].psrc;
  assign io_deqEntry_0_bits_status_srcStatus_1_srcType = c_deq_entry[0].status.src[1].src_type;
  assign io_deqEntry_0_bits_status_srcStatus_2_psrc = c_deq_entry[0].status.src[2].psrc;
  assign io_deqEntry_0_bits_status_srcStatus_2_srcType = c_deq_entry[0].status.src[2].src_type;
  assign io_deqEntry_0_bits_status_srcStatus_3_psrc = c_deq_entry[0].status.src[3].psrc;
  assign io_deqEntry_0_bits_status_srcStatus_3_srcType = c_deq_entry[0].status.src[3].src_type;
  assign io_deqEntry_0_bits_status_srcStatus_4_psrc = c_deq_entry[0].status.src[4].psrc;
  assign io_deqEntry_0_bits_status_srcStatus_4_srcType = c_deq_entry[0].status.src[4].src_type;
  assign io_deqEntry_0_bits_payload_fuOpType = c_deq_entry[0].payload.fu_op_type;
  assign io_deqEntry_0_bits_payload_vecWen = c_deq_entry[0].payload.vec_wen;
  assign io_deqEntry_0_bits_payload_v0Wen = c_deq_entry[0].payload.v0_wen;
  assign io_deqEntry_0_bits_payload_fpu_wflags = c_deq_entry[0].payload.fpu_wflags;
  assign io_deqEntry_0_bits_payload_vpu_vma = c_deq_entry[0].payload.vpu.vma;
  assign io_deqEntry_0_bits_payload_vpu_vta = c_deq_entry[0].payload.vpu.vta;
  assign io_deqEntry_0_bits_payload_vpu_vsew = c_deq_entry[0].payload.vpu.vsew;
  assign io_deqEntry_0_bits_payload_vpu_vlmul = c_deq_entry[0].payload.vpu.vlmul;
  assign io_deqEntry_0_bits_payload_vpu_vm = c_deq_entry[0].payload.vpu.vm;
  assign io_deqEntry_0_bits_payload_vpu_vstart = c_deq_entry[0].payload.vpu.vstart;
  assign io_deqEntry_0_bits_payload_vpu_isExt = c_deq_entry[0].payload.vpu.is_ext;
  assign io_deqEntry_0_bits_payload_vpu_isNarrow = c_deq_entry[0].payload.vpu.is_narrow;
  assign io_deqEntry_0_bits_payload_vpu_isDstMask = c_deq_entry[0].payload.vpu.is_dst_mask;
  assign io_deqEntry_0_bits_payload_vpu_isOpMask = c_deq_entry[0].payload.vpu.is_op_mask;
  assign io_deqEntry_0_bits_payload_uopIdx = c_deq_entry[0].payload.uop_idx;
  assign io_deqEntry_0_bits_payload_pdest = c_deq_entry[0].payload.pdest;
  assign io_deqEntry_1_bits_status_robIdx_flag = c_deq_entry[1].status.rob_flag;
  assign io_deqEntry_1_bits_status_robIdx_value = c_deq_entry[1].status.rob_value;
  assign io_deqEntry_1_bits_status_fuType_19 = c_deq_entry[1].status.fu_type_vialuf;
  assign io_deqEntry_1_bits_status_fuType_24 = c_deq_entry[1].status.fu_type_vfalu;
  assign io_deqEntry_1_bits_status_fuType_25 = c_deq_entry[1].status.fu_type_vfma;
  assign io_deqEntry_1_bits_status_srcStatus_0_psrc = c_deq_entry[1].status.src[0].psrc;
  assign io_deqEntry_1_bits_status_srcStatus_0_srcType = c_deq_entry[1].status.src[0].src_type;
  assign io_deqEntry_1_bits_status_srcStatus_1_psrc = c_deq_entry[1].status.src[1].psrc;
  assign io_deqEntry_1_bits_status_srcStatus_1_srcType = c_deq_entry[1].status.src[1].src_type;
  assign io_deqEntry_1_bits_status_srcStatus_2_psrc = c_deq_entry[1].status.src[2].psrc;
  assign io_deqEntry_1_bits_status_srcStatus_2_srcType = c_deq_entry[1].status.src[2].src_type;
  assign io_deqEntry_1_bits_status_srcStatus_3_psrc = c_deq_entry[1].status.src[3].psrc;
  assign io_deqEntry_1_bits_status_srcStatus_3_srcType = c_deq_entry[1].status.src[3].src_type;
  assign io_deqEntry_1_bits_status_srcStatus_4_psrc = c_deq_entry[1].status.src[4].psrc;
  assign io_deqEntry_1_bits_status_srcStatus_4_srcType = c_deq_entry[1].status.src[4].src_type;
  assign io_deqEntry_1_bits_payload_fuOpType = c_deq_entry[1].payload.fu_op_type;
  assign io_deqEntry_1_bits_payload_fpWen = c_deq_entry[1].payload.fp_wen;
  assign io_deqEntry_1_bits_payload_vecWen = c_deq_entry[1].payload.vec_wen;
  assign io_deqEntry_1_bits_payload_v0Wen = c_deq_entry[1].payload.v0_wen;
  assign io_deqEntry_1_bits_payload_fpu_wflags = c_deq_entry[1].payload.fpu_wflags;
  assign io_deqEntry_1_bits_payload_vpu_vma = c_deq_entry[1].payload.vpu.vma;
  assign io_deqEntry_1_bits_payload_vpu_vta = c_deq_entry[1].payload.vpu.vta;
  assign io_deqEntry_1_bits_payload_vpu_vsew = c_deq_entry[1].payload.vpu.vsew;
  assign io_deqEntry_1_bits_payload_vpu_vlmul = c_deq_entry[1].payload.vpu.vlmul;
  assign io_deqEntry_1_bits_payload_vpu_vm = c_deq_entry[1].payload.vpu.vm;
  assign io_deqEntry_1_bits_payload_vpu_vstart = c_deq_entry[1].payload.vpu.vstart;
  assign io_deqEntry_1_bits_payload_vpu_fpu_isFoldTo1_2 = c_deq_entry[1].payload.vpu.fpu_is_fold_to_1_2;
  assign io_deqEntry_1_bits_payload_vpu_fpu_isFoldTo1_4 = c_deq_entry[1].payload.vpu.fpu_is_fold_to_1_4;
  assign io_deqEntry_1_bits_payload_vpu_fpu_isFoldTo1_8 = c_deq_entry[1].payload.vpu.fpu_is_fold_to_1_8;
  assign io_deqEntry_1_bits_payload_vpu_isNarrow = c_deq_entry[1].payload.vpu.is_narrow;
  assign io_deqEntry_1_bits_payload_vpu_isDstMask = c_deq_entry[1].payload.vpu.is_dst_mask;
  assign io_deqEntry_1_bits_payload_uopIdx = c_deq_entry[1].payload.uop_idx;
  assign io_deqEntry_1_bits_payload_lastUop = c_deq_entry[1].payload.last_uop;
  assign io_deqEntry_1_bits_payload_pdest = c_deq_entry[1].payload.pdest;
  assign io_simpEntryEnqSelVec_0 = c_simp_enq_sel_vec[0];
  assign io_simpEntryEnqSelVec_1 = c_simp_enq_sel_vec[1];
  assign io_compEntryEnqSelVec_0 = c_comp_enq_sel_vec[0];
  assign io_compEntryEnqSelVec_1 = c_comp_enq_sel_vec[1];
  xs_EntriesVfmaVialuFixVfalu_core u_core (
    .clock(clock), .reset(reset),
    .flush_valid(c_flush_valid), .flush_rob_flag(c_flush_rob_flag),
    .flush_rob_value(c_flush_rob_value), .flush_level(c_flush_level),
    .enq_valid(c_enq_valid), .enq_bits(c_enq_bits),
    .wk_wb(c_wk_wb), .wk_wb_d(c_wk_wb_d),
    .vl_info(c_vl),
    .og_resp(c_og_resp),
    .deq_sel_oh_valid(c_deq_sel_oh_valid), .deq_sel_oh_bits(c_deq_sel_oh_bits),
    .enq_oldest_sel_bits(c_enq_oldest_sel_bits),
    .simp_oldest_sel_valid(c_simp_oldest_sel_valid), .simp_oldest_sel_bits(c_simp_oldest_sel_bits),
    .comp_oldest_sel_valid(c_comp_oldest_sel_valid), .comp_oldest_sel_bits(c_comp_oldest_sel_bits),
    .simp_deq_sel_vec(c_simp_deq_sel_vec),
    .o_valid(c_valid), .o_issued(c_issued), .o_can_issue(c_can_issue),
    .o_fu_type(c_fu_type), .o_data_sources(c_data_sources),
    .o_deq_entry(c_deq_entry),
    .o_simp_enq_sel_vec(c_simp_enq_sel_vec), .o_comp_enq_sel_vec(c_comp_enq_sel_vec)
  );
endmodule
