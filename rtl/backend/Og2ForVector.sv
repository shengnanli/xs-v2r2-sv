// 自动生成: scripts/gen_og2forvector.py —— 勿手改 (逻辑为从设计意图的可读重写)
// Og2ForVector: 向量操作数收集 stage-2 流水寄存器组 (7 通道 payload 打拍 + flush 冲刷)。
// 详见脚本头注释。无子模块; flush 命中用命名 flushHit 函数替换 golden _GEN/_T_ 临时量。
module Og2ForVector(
  input  clock,
  input  reset,
  input  io_flush_valid,
  input  io_flush_bits_robIdx_flag,
  input  [7:0] io_flush_bits_robIdx_value,
  input  io_flush_bits_level,
  input  io_fromOg1VfArith_2_0_valid,
  input  [34:0] io_fromOg1VfArith_2_0_bits_fuType,
  input  [8:0] io_fromOg1VfArith_2_0_bits_fuOpType,
  input  [127:0] io_fromOg1VfArith_2_0_bits_src_0,
  input  [127:0] io_fromOg1VfArith_2_0_bits_src_1,
  input  [127:0] io_fromOg1VfArith_2_0_bits_src_2,
  input  [127:0] io_fromOg1VfArith_2_0_bits_src_3,
  input  [127:0] io_fromOg1VfArith_2_0_bits_src_4,
  input  io_fromOg1VfArith_2_0_bits_robIdx_flag,
  input  [7:0] io_fromOg1VfArith_2_0_bits_robIdx_value,
  input  [6:0] io_fromOg1VfArith_2_0_bits_pdest,
  input  io_fromOg1VfArith_2_0_bits_vecWen,
  input  io_fromOg1VfArith_2_0_bits_v0Wen,
  input  io_fromOg1VfArith_2_0_bits_fpu_wflags,
  input  io_fromOg1VfArith_2_0_bits_vpu_vma,
  input  io_fromOg1VfArith_2_0_bits_vpu_vta,
  input  [1:0] io_fromOg1VfArith_2_0_bits_vpu_vsew,
  input  [2:0] io_fromOg1VfArith_2_0_bits_vpu_vlmul,
  input  io_fromOg1VfArith_2_0_bits_vpu_vm,
  input  [7:0] io_fromOg1VfArith_2_0_bits_vpu_vstart,
  input  [6:0] io_fromOg1VfArith_2_0_bits_vpu_vuopIdx,
  input  io_fromOg1VfArith_2_0_bits_vpu_isExt,
  input  io_fromOg1VfArith_2_0_bits_vpu_isNarrow,
  input  io_fromOg1VfArith_2_0_bits_vpu_isDstMask,
  input  io_fromOg1VfArith_2_0_bits_vpu_isOpMask,
  input  [3:0] io_fromOg1VfArith_2_0_bits_dataSources_0_value,
  input  [3:0] io_fromOg1VfArith_2_0_bits_dataSources_1_value,
  input  [3:0] io_fromOg1VfArith_2_0_bits_dataSources_2_value,
  input  [3:0] io_fromOg1VfArith_2_0_bits_dataSources_3_value,
  input  [3:0] io_fromOg1VfArith_2_0_bits_dataSources_4_value,
  input  [63:0] io_fromOg1VfArith_2_0_bits_perfDebugInfo_enqRsTime,
  input  [63:0] io_fromOg1VfArith_2_0_bits_perfDebugInfo_selectTime,
  input  [63:0] io_fromOg1VfArith_2_0_bits_perfDebugInfo_issueTime,
  input  io_fromOg1VfArith_1_1_valid,
  input  [34:0] io_fromOg1VfArith_1_1_bits_fuType,
  input  [8:0] io_fromOg1VfArith_1_1_bits_fuOpType,
  input  [127:0] io_fromOg1VfArith_1_1_bits_src_0,
  input  [127:0] io_fromOg1VfArith_1_1_bits_src_1,
  input  [127:0] io_fromOg1VfArith_1_1_bits_src_2,
  input  [127:0] io_fromOg1VfArith_1_1_bits_src_3,
  input  [127:0] io_fromOg1VfArith_1_1_bits_src_4,
  input  io_fromOg1VfArith_1_1_bits_robIdx_flag,
  input  [7:0] io_fromOg1VfArith_1_1_bits_robIdx_value,
  input  [7:0] io_fromOg1VfArith_1_1_bits_pdest,
  input  io_fromOg1VfArith_1_1_bits_fpWen,
  input  io_fromOg1VfArith_1_1_bits_vecWen,
  input  io_fromOg1VfArith_1_1_bits_v0Wen,
  input  io_fromOg1VfArith_1_1_bits_fpu_wflags,
  input  io_fromOg1VfArith_1_1_bits_vpu_vma,
  input  io_fromOg1VfArith_1_1_bits_vpu_vta,
  input  [1:0] io_fromOg1VfArith_1_1_bits_vpu_vsew,
  input  [2:0] io_fromOg1VfArith_1_1_bits_vpu_vlmul,
  input  io_fromOg1VfArith_1_1_bits_vpu_vm,
  input  [7:0] io_fromOg1VfArith_1_1_bits_vpu_vstart,
  input  io_fromOg1VfArith_1_1_bits_vpu_fpu_isFoldTo1_2,
  input  io_fromOg1VfArith_1_1_bits_vpu_fpu_isFoldTo1_4,
  input  io_fromOg1VfArith_1_1_bits_vpu_fpu_isFoldTo1_8,
  input  [6:0] io_fromOg1VfArith_1_1_bits_vpu_vuopIdx,
  input  io_fromOg1VfArith_1_1_bits_vpu_lastUop,
  input  io_fromOg1VfArith_1_1_bits_vpu_isNarrow,
  input  io_fromOg1VfArith_1_1_bits_vpu_isDstMask,
  input  [3:0] io_fromOg1VfArith_1_1_bits_dataSources_0_value,
  input  [3:0] io_fromOg1VfArith_1_1_bits_dataSources_1_value,
  input  [3:0] io_fromOg1VfArith_1_1_bits_dataSources_2_value,
  input  [3:0] io_fromOg1VfArith_1_1_bits_dataSources_3_value,
  input  [3:0] io_fromOg1VfArith_1_1_bits_dataSources_4_value,
  input  [63:0] io_fromOg1VfArith_1_1_bits_perfDebugInfo_enqRsTime,
  input  [63:0] io_fromOg1VfArith_1_1_bits_perfDebugInfo_selectTime,
  input  [63:0] io_fromOg1VfArith_1_1_bits_perfDebugInfo_issueTime,
  input  io_fromOg1VfArith_1_0_valid,
  input  [34:0] io_fromOg1VfArith_1_0_bits_fuType,
  input  [8:0] io_fromOg1VfArith_1_0_bits_fuOpType,
  input  [127:0] io_fromOg1VfArith_1_0_bits_src_0,
  input  [127:0] io_fromOg1VfArith_1_0_bits_src_1,
  input  [127:0] io_fromOg1VfArith_1_0_bits_src_2,
  input  [127:0] io_fromOg1VfArith_1_0_bits_src_3,
  input  [127:0] io_fromOg1VfArith_1_0_bits_src_4,
  input  io_fromOg1VfArith_1_0_bits_robIdx_flag,
  input  [7:0] io_fromOg1VfArith_1_0_bits_robIdx_value,
  input  [6:0] io_fromOg1VfArith_1_0_bits_pdest,
  input  io_fromOg1VfArith_1_0_bits_vecWen,
  input  io_fromOg1VfArith_1_0_bits_v0Wen,
  input  io_fromOg1VfArith_1_0_bits_fpu_wflags,
  input  io_fromOg1VfArith_1_0_bits_vpu_vma,
  input  io_fromOg1VfArith_1_0_bits_vpu_vta,
  input  [1:0] io_fromOg1VfArith_1_0_bits_vpu_vsew,
  input  [2:0] io_fromOg1VfArith_1_0_bits_vpu_vlmul,
  input  io_fromOg1VfArith_1_0_bits_vpu_vm,
  input  [7:0] io_fromOg1VfArith_1_0_bits_vpu_vstart,
  input  [6:0] io_fromOg1VfArith_1_0_bits_vpu_vuopIdx,
  input  io_fromOg1VfArith_1_0_bits_vpu_isExt,
  input  io_fromOg1VfArith_1_0_bits_vpu_isNarrow,
  input  io_fromOg1VfArith_1_0_bits_vpu_isDstMask,
  input  io_fromOg1VfArith_1_0_bits_vpu_isOpMask,
  input  [3:0] io_fromOg1VfArith_1_0_bits_dataSources_0_value,
  input  [3:0] io_fromOg1VfArith_1_0_bits_dataSources_1_value,
  input  [3:0] io_fromOg1VfArith_1_0_bits_dataSources_2_value,
  input  [3:0] io_fromOg1VfArith_1_0_bits_dataSources_3_value,
  input  [3:0] io_fromOg1VfArith_1_0_bits_dataSources_4_value,
  input  [63:0] io_fromOg1VfArith_1_0_bits_perfDebugInfo_enqRsTime,
  input  [63:0] io_fromOg1VfArith_1_0_bits_perfDebugInfo_selectTime,
  input  [63:0] io_fromOg1VfArith_1_0_bits_perfDebugInfo_issueTime,
  input  io_fromOg1VfArith_0_1_valid,
  input  [34:0] io_fromOg1VfArith_0_1_bits_fuType,
  input  [8:0] io_fromOg1VfArith_0_1_bits_fuOpType,
  input  [127:0] io_fromOg1VfArith_0_1_bits_src_0,
  input  [127:0] io_fromOg1VfArith_0_1_bits_src_1,
  input  [127:0] io_fromOg1VfArith_0_1_bits_src_2,
  input  [127:0] io_fromOg1VfArith_0_1_bits_src_3,
  input  [127:0] io_fromOg1VfArith_0_1_bits_src_4,
  input  io_fromOg1VfArith_0_1_bits_robIdx_flag,
  input  [7:0] io_fromOg1VfArith_0_1_bits_robIdx_value,
  input  [7:0] io_fromOg1VfArith_0_1_bits_pdest,
  input  io_fromOg1VfArith_0_1_bits_rfWen,
  input  io_fromOg1VfArith_0_1_bits_fpWen,
  input  io_fromOg1VfArith_0_1_bits_vecWen,
  input  io_fromOg1VfArith_0_1_bits_v0Wen,
  input  io_fromOg1VfArith_0_1_bits_vlWen,
  input  io_fromOg1VfArith_0_1_bits_fpu_wflags,
  input  io_fromOg1VfArith_0_1_bits_vpu_vma,
  input  io_fromOg1VfArith_0_1_bits_vpu_vta,
  input  [1:0] io_fromOg1VfArith_0_1_bits_vpu_vsew,
  input  [2:0] io_fromOg1VfArith_0_1_bits_vpu_vlmul,
  input  io_fromOg1VfArith_0_1_bits_vpu_vm,
  input  [7:0] io_fromOg1VfArith_0_1_bits_vpu_vstart,
  input  io_fromOg1VfArith_0_1_bits_vpu_fpu_isFoldTo1_2,
  input  io_fromOg1VfArith_0_1_bits_vpu_fpu_isFoldTo1_4,
  input  io_fromOg1VfArith_0_1_bits_vpu_fpu_isFoldTo1_8,
  input  [6:0] io_fromOg1VfArith_0_1_bits_vpu_vuopIdx,
  input  io_fromOg1VfArith_0_1_bits_vpu_lastUop,
  input  io_fromOg1VfArith_0_1_bits_vpu_isNarrow,
  input  io_fromOg1VfArith_0_1_bits_vpu_isDstMask,
  input  [3:0] io_fromOg1VfArith_0_1_bits_dataSources_0_value,
  input  [3:0] io_fromOg1VfArith_0_1_bits_dataSources_1_value,
  input  [3:0] io_fromOg1VfArith_0_1_bits_dataSources_2_value,
  input  [3:0] io_fromOg1VfArith_0_1_bits_dataSources_3_value,
  input  [3:0] io_fromOg1VfArith_0_1_bits_dataSources_4_value,
  input  [63:0] io_fromOg1VfArith_0_1_bits_perfDebugInfo_enqRsTime,
  input  [63:0] io_fromOg1VfArith_0_1_bits_perfDebugInfo_selectTime,
  input  [63:0] io_fromOg1VfArith_0_1_bits_perfDebugInfo_issueTime,
  input  io_fromOg1VfArith_0_0_valid,
  input  [34:0] io_fromOg1VfArith_0_0_bits_fuType,
  input  [8:0] io_fromOg1VfArith_0_0_bits_fuOpType,
  input  [127:0] io_fromOg1VfArith_0_0_bits_src_0,
  input  [127:0] io_fromOg1VfArith_0_0_bits_src_1,
  input  [127:0] io_fromOg1VfArith_0_0_bits_src_2,
  input  [127:0] io_fromOg1VfArith_0_0_bits_src_3,
  input  [127:0] io_fromOg1VfArith_0_0_bits_src_4,
  input  io_fromOg1VfArith_0_0_bits_robIdx_flag,
  input  [7:0] io_fromOg1VfArith_0_0_bits_robIdx_value,
  input  [6:0] io_fromOg1VfArith_0_0_bits_pdest,
  input  io_fromOg1VfArith_0_0_bits_vecWen,
  input  io_fromOg1VfArith_0_0_bits_v0Wen,
  input  io_fromOg1VfArith_0_0_bits_fpu_wflags,
  input  io_fromOg1VfArith_0_0_bits_vpu_vma,
  input  io_fromOg1VfArith_0_0_bits_vpu_vta,
  input  [1:0] io_fromOg1VfArith_0_0_bits_vpu_vsew,
  input  [2:0] io_fromOg1VfArith_0_0_bits_vpu_vlmul,
  input  io_fromOg1VfArith_0_0_bits_vpu_vm,
  input  [7:0] io_fromOg1VfArith_0_0_bits_vpu_vstart,
  input  [6:0] io_fromOg1VfArith_0_0_bits_vpu_vuopIdx,
  input  io_fromOg1VfArith_0_0_bits_vpu_isExt,
  input  io_fromOg1VfArith_0_0_bits_vpu_isNarrow,
  input  io_fromOg1VfArith_0_0_bits_vpu_isDstMask,
  input  io_fromOg1VfArith_0_0_bits_vpu_isOpMask,
  input  [3:0] io_fromOg1VfArith_0_0_bits_dataSources_0_value,
  input  [3:0] io_fromOg1VfArith_0_0_bits_dataSources_1_value,
  input  [3:0] io_fromOg1VfArith_0_0_bits_dataSources_2_value,
  input  [3:0] io_fromOg1VfArith_0_0_bits_dataSources_3_value,
  input  [3:0] io_fromOg1VfArith_0_0_bits_dataSources_4_value,
  input  [63:0] io_fromOg1VfArith_0_0_bits_perfDebugInfo_enqRsTime,
  input  [63:0] io_fromOg1VfArith_0_0_bits_perfDebugInfo_selectTime,
  input  [63:0] io_fromOg1VfArith_0_0_bits_perfDebugInfo_issueTime,
  input  io_fromOg1VecMem_1_0_valid,
  input  [34:0] io_fromOg1VecMem_1_0_bits_fuType,
  input  [8:0] io_fromOg1VecMem_1_0_bits_fuOpType,
  input  [127:0] io_fromOg1VecMem_1_0_bits_src_0,
  input  [127:0] io_fromOg1VecMem_1_0_bits_src_1,
  input  [127:0] io_fromOg1VecMem_1_0_bits_src_2,
  input  [127:0] io_fromOg1VecMem_1_0_bits_src_3,
  input  [127:0] io_fromOg1VecMem_1_0_bits_src_4,
  input  io_fromOg1VecMem_1_0_bits_robIdx_flag,
  input  [7:0] io_fromOg1VecMem_1_0_bits_robIdx_value,
  input  [6:0] io_fromOg1VecMem_1_0_bits_pdest,
  input  io_fromOg1VecMem_1_0_bits_vecWen,
  input  io_fromOg1VecMem_1_0_bits_v0Wen,
  input  io_fromOg1VecMem_1_0_bits_vlWen,
  input  io_fromOg1VecMem_1_0_bits_vpu_vma,
  input  io_fromOg1VecMem_1_0_bits_vpu_vta,
  input  [1:0] io_fromOg1VecMem_1_0_bits_vpu_vsew,
  input  [2:0] io_fromOg1VecMem_1_0_bits_vpu_vlmul,
  input  io_fromOg1VecMem_1_0_bits_vpu_vm,
  input  [7:0] io_fromOg1VecMem_1_0_bits_vpu_vstart,
  input  [6:0] io_fromOg1VecMem_1_0_bits_vpu_vuopIdx,
  input  io_fromOg1VecMem_1_0_bits_vpu_lastUop,
  input  [127:0] io_fromOg1VecMem_1_0_bits_vpu_vmask,
  input  [2:0] io_fromOg1VecMem_1_0_bits_vpu_nf,
  input  [1:0] io_fromOg1VecMem_1_0_bits_vpu_veew,
  input  io_fromOg1VecMem_1_0_bits_vpu_isVleff,
  input  io_fromOg1VecMem_1_0_bits_ftqIdx_flag,
  input  [5:0] io_fromOg1VecMem_1_0_bits_ftqIdx_value,
  input  [3:0] io_fromOg1VecMem_1_0_bits_ftqOffset,
  input  [4:0] io_fromOg1VecMem_1_0_bits_numLsElem,
  input  io_fromOg1VecMem_1_0_bits_sqIdx_flag,
  input  [5:0] io_fromOg1VecMem_1_0_bits_sqIdx_value,
  input  io_fromOg1VecMem_1_0_bits_lqIdx_flag,
  input  [6:0] io_fromOg1VecMem_1_0_bits_lqIdx_value,
  input  [3:0] io_fromOg1VecMem_1_0_bits_dataSources_0_value,
  input  [3:0] io_fromOg1VecMem_1_0_bits_dataSources_1_value,
  input  [3:0] io_fromOg1VecMem_1_0_bits_dataSources_2_value,
  input  [3:0] io_fromOg1VecMem_1_0_bits_dataSources_3_value,
  input  [3:0] io_fromOg1VecMem_1_0_bits_dataSources_4_value,
  input  [63:0] io_fromOg1VecMem_1_0_bits_perfDebugInfo_enqRsTime,
  input  [63:0] io_fromOg1VecMem_1_0_bits_perfDebugInfo_selectTime,
  input  [63:0] io_fromOg1VecMem_1_0_bits_perfDebugInfo_issueTime,
  input  io_fromOg1VecMem_0_0_valid,
  input  [34:0] io_fromOg1VecMem_0_0_bits_fuType,
  input  [8:0] io_fromOg1VecMem_0_0_bits_fuOpType,
  input  [127:0] io_fromOg1VecMem_0_0_bits_src_0,
  input  [127:0] io_fromOg1VecMem_0_0_bits_src_1,
  input  [127:0] io_fromOg1VecMem_0_0_bits_src_2,
  input  [127:0] io_fromOg1VecMem_0_0_bits_src_3,
  input  [127:0] io_fromOg1VecMem_0_0_bits_src_4,
  input  io_fromOg1VecMem_0_0_bits_robIdx_flag,
  input  [7:0] io_fromOg1VecMem_0_0_bits_robIdx_value,
  input  [6:0] io_fromOg1VecMem_0_0_bits_pdest,
  input  io_fromOg1VecMem_0_0_bits_vecWen,
  input  io_fromOg1VecMem_0_0_bits_v0Wen,
  input  io_fromOg1VecMem_0_0_bits_vlWen,
  input  io_fromOg1VecMem_0_0_bits_vpu_vma,
  input  io_fromOg1VecMem_0_0_bits_vpu_vta,
  input  [1:0] io_fromOg1VecMem_0_0_bits_vpu_vsew,
  input  [2:0] io_fromOg1VecMem_0_0_bits_vpu_vlmul,
  input  io_fromOg1VecMem_0_0_bits_vpu_vm,
  input  [7:0] io_fromOg1VecMem_0_0_bits_vpu_vstart,
  input  [6:0] io_fromOg1VecMem_0_0_bits_vpu_vuopIdx,
  input  io_fromOg1VecMem_0_0_bits_vpu_lastUop,
  input  [127:0] io_fromOg1VecMem_0_0_bits_vpu_vmask,
  input  [2:0] io_fromOg1VecMem_0_0_bits_vpu_nf,
  input  [1:0] io_fromOg1VecMem_0_0_bits_vpu_veew,
  input  io_fromOg1VecMem_0_0_bits_vpu_isVleff,
  input  io_fromOg1VecMem_0_0_bits_ftqIdx_flag,
  input  [5:0] io_fromOg1VecMem_0_0_bits_ftqIdx_value,
  input  [3:0] io_fromOg1VecMem_0_0_bits_ftqOffset,
  input  [4:0] io_fromOg1VecMem_0_0_bits_numLsElem,
  input  io_fromOg1VecMem_0_0_bits_sqIdx_flag,
  input  [5:0] io_fromOg1VecMem_0_0_bits_sqIdx_value,
  input  io_fromOg1VecMem_0_0_bits_lqIdx_flag,
  input  [6:0] io_fromOg1VecMem_0_0_bits_lqIdx_value,
  input  [3:0] io_fromOg1VecMem_0_0_bits_dataSources_0_value,
  input  [3:0] io_fromOg1VecMem_0_0_bits_dataSources_1_value,
  input  [3:0] io_fromOg1VecMem_0_0_bits_dataSources_2_value,
  input  [3:0] io_fromOg1VecMem_0_0_bits_dataSources_3_value,
  input  [3:0] io_fromOg1VecMem_0_0_bits_dataSources_4_value,
  input  [63:0] io_fromOg1VecMem_0_0_bits_perfDebugInfo_enqRsTime,
  input  [63:0] io_fromOg1VecMem_0_0_bits_perfDebugInfo_selectTime,
  input  [63:0] io_fromOg1VecMem_0_0_bits_perfDebugInfo_issueTime,
  input  [31:0] io_fromOg1ImmInfo_1_imm,
  input  [3:0] io_fromOg1ImmInfo_1_immType,
  input  io_toVfArithExu_2_0_ready,
  output io_toVfArithExu_2_0_valid,
  output [34:0] io_toVfArithExu_2_0_bits_fuType,
  output [8:0] io_toVfArithExu_2_0_bits_fuOpType,
  output [127:0] io_toVfArithExu_2_0_bits_src_0,
  output [127:0] io_toVfArithExu_2_0_bits_src_1,
  output [127:0] io_toVfArithExu_2_0_bits_src_2,
  output [127:0] io_toVfArithExu_2_0_bits_src_3,
  output [127:0] io_toVfArithExu_2_0_bits_src_4,
  output io_toVfArithExu_2_0_bits_robIdx_flag,
  output [7:0] io_toVfArithExu_2_0_bits_robIdx_value,
  output [6:0] io_toVfArithExu_2_0_bits_pdest,
  output io_toVfArithExu_2_0_bits_vecWen,
  output io_toVfArithExu_2_0_bits_v0Wen,
  output io_toVfArithExu_2_0_bits_fpu_wflags,
  output io_toVfArithExu_2_0_bits_vpu_vma,
  output io_toVfArithExu_2_0_bits_vpu_vta,
  output [1:0] io_toVfArithExu_2_0_bits_vpu_vsew,
  output [2:0] io_toVfArithExu_2_0_bits_vpu_vlmul,
  output io_toVfArithExu_2_0_bits_vpu_vm,
  output [7:0] io_toVfArithExu_2_0_bits_vpu_vstart,
  output [6:0] io_toVfArithExu_2_0_bits_vpu_vuopIdx,
  output io_toVfArithExu_2_0_bits_vpu_isExt,
  output io_toVfArithExu_2_0_bits_vpu_isNarrow,
  output io_toVfArithExu_2_0_bits_vpu_isDstMask,
  output io_toVfArithExu_2_0_bits_vpu_isOpMask,
  output [3:0] io_toVfArithExu_2_0_bits_dataSources_0_value,
  output [3:0] io_toVfArithExu_2_0_bits_dataSources_1_value,
  output [3:0] io_toVfArithExu_2_0_bits_dataSources_2_value,
  output [3:0] io_toVfArithExu_2_0_bits_dataSources_3_value,
  output [3:0] io_toVfArithExu_2_0_bits_dataSources_4_value,
  output [63:0] io_toVfArithExu_2_0_bits_perfDebugInfo_enqRsTime,
  output [63:0] io_toVfArithExu_2_0_bits_perfDebugInfo_selectTime,
  output [63:0] io_toVfArithExu_2_0_bits_perfDebugInfo_issueTime,
  output io_toVfArithExu_1_1_valid,
  output [34:0] io_toVfArithExu_1_1_bits_fuType,
  output [8:0] io_toVfArithExu_1_1_bits_fuOpType,
  output [127:0] io_toVfArithExu_1_1_bits_src_0,
  output [127:0] io_toVfArithExu_1_1_bits_src_1,
  output [127:0] io_toVfArithExu_1_1_bits_src_2,
  output [127:0] io_toVfArithExu_1_1_bits_src_3,
  output [127:0] io_toVfArithExu_1_1_bits_src_4,
  output io_toVfArithExu_1_1_bits_robIdx_flag,
  output [7:0] io_toVfArithExu_1_1_bits_robIdx_value,
  output [7:0] io_toVfArithExu_1_1_bits_pdest,
  output io_toVfArithExu_1_1_bits_fpWen,
  output io_toVfArithExu_1_1_bits_vecWen,
  output io_toVfArithExu_1_1_bits_v0Wen,
  output io_toVfArithExu_1_1_bits_fpu_wflags,
  output io_toVfArithExu_1_1_bits_vpu_vma,
  output io_toVfArithExu_1_1_bits_vpu_vta,
  output [1:0] io_toVfArithExu_1_1_bits_vpu_vsew,
  output [2:0] io_toVfArithExu_1_1_bits_vpu_vlmul,
  output io_toVfArithExu_1_1_bits_vpu_vm,
  output [7:0] io_toVfArithExu_1_1_bits_vpu_vstart,
  output io_toVfArithExu_1_1_bits_vpu_fpu_isFoldTo1_2,
  output io_toVfArithExu_1_1_bits_vpu_fpu_isFoldTo1_4,
  output io_toVfArithExu_1_1_bits_vpu_fpu_isFoldTo1_8,
  output [6:0] io_toVfArithExu_1_1_bits_vpu_vuopIdx,
  output io_toVfArithExu_1_1_bits_vpu_lastUop,
  output io_toVfArithExu_1_1_bits_vpu_isNarrow,
  output io_toVfArithExu_1_1_bits_vpu_isDstMask,
  output [3:0] io_toVfArithExu_1_1_bits_dataSources_0_value,
  output [3:0] io_toVfArithExu_1_1_bits_dataSources_1_value,
  output [3:0] io_toVfArithExu_1_1_bits_dataSources_2_value,
  output [3:0] io_toVfArithExu_1_1_bits_dataSources_3_value,
  output [3:0] io_toVfArithExu_1_1_bits_dataSources_4_value,
  output [63:0] io_toVfArithExu_1_1_bits_perfDebugInfo_enqRsTime,
  output [63:0] io_toVfArithExu_1_1_bits_perfDebugInfo_selectTime,
  output [63:0] io_toVfArithExu_1_1_bits_perfDebugInfo_issueTime,
  input  io_toVfArithExu_1_0_ready,
  output io_toVfArithExu_1_0_valid,
  output [34:0] io_toVfArithExu_1_0_bits_fuType,
  output [8:0] io_toVfArithExu_1_0_bits_fuOpType,
  output [127:0] io_toVfArithExu_1_0_bits_src_0,
  output [127:0] io_toVfArithExu_1_0_bits_src_1,
  output [127:0] io_toVfArithExu_1_0_bits_src_2,
  output [127:0] io_toVfArithExu_1_0_bits_src_3,
  output [127:0] io_toVfArithExu_1_0_bits_src_4,
  output io_toVfArithExu_1_0_bits_robIdx_flag,
  output [7:0] io_toVfArithExu_1_0_bits_robIdx_value,
  output [6:0] io_toVfArithExu_1_0_bits_pdest,
  output io_toVfArithExu_1_0_bits_vecWen,
  output io_toVfArithExu_1_0_bits_v0Wen,
  output io_toVfArithExu_1_0_bits_fpu_wflags,
  output io_toVfArithExu_1_0_bits_vpu_vma,
  output io_toVfArithExu_1_0_bits_vpu_vta,
  output [1:0] io_toVfArithExu_1_0_bits_vpu_vsew,
  output [2:0] io_toVfArithExu_1_0_bits_vpu_vlmul,
  output io_toVfArithExu_1_0_bits_vpu_vm,
  output [7:0] io_toVfArithExu_1_0_bits_vpu_vstart,
  output [6:0] io_toVfArithExu_1_0_bits_vpu_vuopIdx,
  output io_toVfArithExu_1_0_bits_vpu_isExt,
  output io_toVfArithExu_1_0_bits_vpu_isNarrow,
  output io_toVfArithExu_1_0_bits_vpu_isDstMask,
  output io_toVfArithExu_1_0_bits_vpu_isOpMask,
  output [3:0] io_toVfArithExu_1_0_bits_dataSources_0_value,
  output [3:0] io_toVfArithExu_1_0_bits_dataSources_1_value,
  output [3:0] io_toVfArithExu_1_0_bits_dataSources_2_value,
  output [3:0] io_toVfArithExu_1_0_bits_dataSources_3_value,
  output [3:0] io_toVfArithExu_1_0_bits_dataSources_4_value,
  output [63:0] io_toVfArithExu_1_0_bits_perfDebugInfo_enqRsTime,
  output [63:0] io_toVfArithExu_1_0_bits_perfDebugInfo_selectTime,
  output [63:0] io_toVfArithExu_1_0_bits_perfDebugInfo_issueTime,
  output io_toVfArithExu_0_1_valid,
  output [34:0] io_toVfArithExu_0_1_bits_fuType,
  output [8:0] io_toVfArithExu_0_1_bits_fuOpType,
  output [127:0] io_toVfArithExu_0_1_bits_src_0,
  output [127:0] io_toVfArithExu_0_1_bits_src_1,
  output [127:0] io_toVfArithExu_0_1_bits_src_2,
  output [127:0] io_toVfArithExu_0_1_bits_src_3,
  output [127:0] io_toVfArithExu_0_1_bits_src_4,
  output io_toVfArithExu_0_1_bits_robIdx_flag,
  output [7:0] io_toVfArithExu_0_1_bits_robIdx_value,
  output [7:0] io_toVfArithExu_0_1_bits_pdest,
  output io_toVfArithExu_0_1_bits_rfWen,
  output io_toVfArithExu_0_1_bits_fpWen,
  output io_toVfArithExu_0_1_bits_vecWen,
  output io_toVfArithExu_0_1_bits_v0Wen,
  output io_toVfArithExu_0_1_bits_vlWen,
  output io_toVfArithExu_0_1_bits_fpu_wflags,
  output io_toVfArithExu_0_1_bits_vpu_vma,
  output io_toVfArithExu_0_1_bits_vpu_vta,
  output [1:0] io_toVfArithExu_0_1_bits_vpu_vsew,
  output [2:0] io_toVfArithExu_0_1_bits_vpu_vlmul,
  output io_toVfArithExu_0_1_bits_vpu_vm,
  output [7:0] io_toVfArithExu_0_1_bits_vpu_vstart,
  output io_toVfArithExu_0_1_bits_vpu_fpu_isFoldTo1_2,
  output io_toVfArithExu_0_1_bits_vpu_fpu_isFoldTo1_4,
  output io_toVfArithExu_0_1_bits_vpu_fpu_isFoldTo1_8,
  output [6:0] io_toVfArithExu_0_1_bits_vpu_vuopIdx,
  output io_toVfArithExu_0_1_bits_vpu_lastUop,
  output io_toVfArithExu_0_1_bits_vpu_isNarrow,
  output io_toVfArithExu_0_1_bits_vpu_isDstMask,
  output [3:0] io_toVfArithExu_0_1_bits_dataSources_0_value,
  output [3:0] io_toVfArithExu_0_1_bits_dataSources_1_value,
  output [3:0] io_toVfArithExu_0_1_bits_dataSources_2_value,
  output [3:0] io_toVfArithExu_0_1_bits_dataSources_3_value,
  output [3:0] io_toVfArithExu_0_1_bits_dataSources_4_value,
  output [63:0] io_toVfArithExu_0_1_bits_perfDebugInfo_enqRsTime,
  output [63:0] io_toVfArithExu_0_1_bits_perfDebugInfo_selectTime,
  output [63:0] io_toVfArithExu_0_1_bits_perfDebugInfo_issueTime,
  input  io_toVfArithExu_0_0_ready,
  output io_toVfArithExu_0_0_valid,
  output [34:0] io_toVfArithExu_0_0_bits_fuType,
  output [8:0] io_toVfArithExu_0_0_bits_fuOpType,
  output [127:0] io_toVfArithExu_0_0_bits_src_0,
  output [127:0] io_toVfArithExu_0_0_bits_src_1,
  output [127:0] io_toVfArithExu_0_0_bits_src_2,
  output [127:0] io_toVfArithExu_0_0_bits_src_3,
  output [127:0] io_toVfArithExu_0_0_bits_src_4,
  output io_toVfArithExu_0_0_bits_robIdx_flag,
  output [7:0] io_toVfArithExu_0_0_bits_robIdx_value,
  output [6:0] io_toVfArithExu_0_0_bits_pdest,
  output io_toVfArithExu_0_0_bits_vecWen,
  output io_toVfArithExu_0_0_bits_v0Wen,
  output io_toVfArithExu_0_0_bits_fpu_wflags,
  output io_toVfArithExu_0_0_bits_vpu_vma,
  output io_toVfArithExu_0_0_bits_vpu_vta,
  output [1:0] io_toVfArithExu_0_0_bits_vpu_vsew,
  output [2:0] io_toVfArithExu_0_0_bits_vpu_vlmul,
  output io_toVfArithExu_0_0_bits_vpu_vm,
  output [7:0] io_toVfArithExu_0_0_bits_vpu_vstart,
  output [6:0] io_toVfArithExu_0_0_bits_vpu_vuopIdx,
  output io_toVfArithExu_0_0_bits_vpu_isExt,
  output io_toVfArithExu_0_0_bits_vpu_isNarrow,
  output io_toVfArithExu_0_0_bits_vpu_isDstMask,
  output io_toVfArithExu_0_0_bits_vpu_isOpMask,
  output [3:0] io_toVfArithExu_0_0_bits_dataSources_0_value,
  output [3:0] io_toVfArithExu_0_0_bits_dataSources_1_value,
  output [3:0] io_toVfArithExu_0_0_bits_dataSources_2_value,
  output [3:0] io_toVfArithExu_0_0_bits_dataSources_3_value,
  output [3:0] io_toVfArithExu_0_0_bits_dataSources_4_value,
  output [63:0] io_toVfArithExu_0_0_bits_perfDebugInfo_enqRsTime,
  output [63:0] io_toVfArithExu_0_0_bits_perfDebugInfo_selectTime,
  output [63:0] io_toVfArithExu_0_0_bits_perfDebugInfo_issueTime,
  input  io_toVecMemExu_1_0_ready,
  output io_toVecMemExu_1_0_valid,
  output [34:0] io_toVecMemExu_1_0_bits_fuType,
  output [8:0] io_toVecMemExu_1_0_bits_fuOpType,
  output [127:0] io_toVecMemExu_1_0_bits_src_0,
  output [127:0] io_toVecMemExu_1_0_bits_src_1,
  output [127:0] io_toVecMemExu_1_0_bits_src_2,
  output [127:0] io_toVecMemExu_1_0_bits_src_3,
  output [127:0] io_toVecMemExu_1_0_bits_src_4,
  output io_toVecMemExu_1_0_bits_robIdx_flag,
  output [7:0] io_toVecMemExu_1_0_bits_robIdx_value,
  output [6:0] io_toVecMemExu_1_0_bits_pdest,
  output io_toVecMemExu_1_0_bits_vecWen,
  output io_toVecMemExu_1_0_bits_v0Wen,
  output io_toVecMemExu_1_0_bits_vlWen,
  output io_toVecMemExu_1_0_bits_vpu_vma,
  output io_toVecMemExu_1_0_bits_vpu_vta,
  output [1:0] io_toVecMemExu_1_0_bits_vpu_vsew,
  output [2:0] io_toVecMemExu_1_0_bits_vpu_vlmul,
  output io_toVecMemExu_1_0_bits_vpu_vm,
  output [7:0] io_toVecMemExu_1_0_bits_vpu_vstart,
  output [6:0] io_toVecMemExu_1_0_bits_vpu_vuopIdx,
  output io_toVecMemExu_1_0_bits_vpu_lastUop,
  output [127:0] io_toVecMemExu_1_0_bits_vpu_vmask,
  output [2:0] io_toVecMemExu_1_0_bits_vpu_nf,
  output [1:0] io_toVecMemExu_1_0_bits_vpu_veew,
  output io_toVecMemExu_1_0_bits_vpu_isVleff,
  output io_toVecMemExu_1_0_bits_ftqIdx_flag,
  output [5:0] io_toVecMemExu_1_0_bits_ftqIdx_value,
  output [3:0] io_toVecMemExu_1_0_bits_ftqOffset,
  output [4:0] io_toVecMemExu_1_0_bits_numLsElem,
  output io_toVecMemExu_1_0_bits_sqIdx_flag,
  output [5:0] io_toVecMemExu_1_0_bits_sqIdx_value,
  output io_toVecMemExu_1_0_bits_lqIdx_flag,
  output [6:0] io_toVecMemExu_1_0_bits_lqIdx_value,
  output [3:0] io_toVecMemExu_1_0_bits_dataSources_0_value,
  output [3:0] io_toVecMemExu_1_0_bits_dataSources_1_value,
  output [3:0] io_toVecMemExu_1_0_bits_dataSources_2_value,
  output [3:0] io_toVecMemExu_1_0_bits_dataSources_3_value,
  output [3:0] io_toVecMemExu_1_0_bits_dataSources_4_value,
  output [63:0] io_toVecMemExu_1_0_bits_perfDebugInfo_enqRsTime,
  output [63:0] io_toVecMemExu_1_0_bits_perfDebugInfo_selectTime,
  output [63:0] io_toVecMemExu_1_0_bits_perfDebugInfo_issueTime,
  input  io_toVecMemExu_0_0_ready,
  output io_toVecMemExu_0_0_valid,
  output [34:0] io_toVecMemExu_0_0_bits_fuType,
  output [8:0] io_toVecMemExu_0_0_bits_fuOpType,
  output [127:0] io_toVecMemExu_0_0_bits_src_0,
  output [127:0] io_toVecMemExu_0_0_bits_src_1,
  output [127:0] io_toVecMemExu_0_0_bits_src_2,
  output [127:0] io_toVecMemExu_0_0_bits_src_3,
  output [127:0] io_toVecMemExu_0_0_bits_src_4,
  output io_toVecMemExu_0_0_bits_robIdx_flag,
  output [7:0] io_toVecMemExu_0_0_bits_robIdx_value,
  output [6:0] io_toVecMemExu_0_0_bits_pdest,
  output io_toVecMemExu_0_0_bits_vecWen,
  output io_toVecMemExu_0_0_bits_v0Wen,
  output io_toVecMemExu_0_0_bits_vlWen,
  output io_toVecMemExu_0_0_bits_vpu_vma,
  output io_toVecMemExu_0_0_bits_vpu_vta,
  output [1:0] io_toVecMemExu_0_0_bits_vpu_vsew,
  output [2:0] io_toVecMemExu_0_0_bits_vpu_vlmul,
  output io_toVecMemExu_0_0_bits_vpu_vm,
  output [7:0] io_toVecMemExu_0_0_bits_vpu_vstart,
  output [6:0] io_toVecMemExu_0_0_bits_vpu_vuopIdx,
  output io_toVecMemExu_0_0_bits_vpu_lastUop,
  output [127:0] io_toVecMemExu_0_0_bits_vpu_vmask,
  output [2:0] io_toVecMemExu_0_0_bits_vpu_nf,
  output [1:0] io_toVecMemExu_0_0_bits_vpu_veew,
  output io_toVecMemExu_0_0_bits_vpu_isVleff,
  output io_toVecMemExu_0_0_bits_ftqIdx_flag,
  output [5:0] io_toVecMemExu_0_0_bits_ftqIdx_value,
  output [3:0] io_toVecMemExu_0_0_bits_ftqOffset,
  output [4:0] io_toVecMemExu_0_0_bits_numLsElem,
  output io_toVecMemExu_0_0_bits_sqIdx_flag,
  output [5:0] io_toVecMemExu_0_0_bits_sqIdx_value,
  output io_toVecMemExu_0_0_bits_lqIdx_flag,
  output [6:0] io_toVecMemExu_0_0_bits_lqIdx_value,
  output [3:0] io_toVecMemExu_0_0_bits_dataSources_0_value,
  output [3:0] io_toVecMemExu_0_0_bits_dataSources_1_value,
  output [3:0] io_toVecMemExu_0_0_bits_dataSources_2_value,
  output [3:0] io_toVecMemExu_0_0_bits_dataSources_3_value,
  output [3:0] io_toVecMemExu_0_0_bits_dataSources_4_value,
  output [63:0] io_toVecMemExu_0_0_bits_perfDebugInfo_enqRsTime,
  output [63:0] io_toVecMemExu_0_0_bits_perfDebugInfo_selectTime,
  output [63:0] io_toVecMemExu_0_0_bits_perfDebugInfo_issueTime,
  output io_toVfIQOg2Resp_2_0_valid,
  output [1:0] io_toVfIQOg2Resp_2_0_bits_resp,
  output io_toVfIQOg2Resp_1_1_valid,
  output io_toVfIQOg2Resp_1_0_valid,
  output [1:0] io_toVfIQOg2Resp_1_0_bits_resp,
  output io_toVfIQOg2Resp_0_1_valid,
  output io_toVfIQOg2Resp_0_0_valid,
  output [1:0] io_toVfIQOg2Resp_0_0_bits_resp,
  output io_toMemIQOg2Resp_1_0_valid,
  output [1:0] io_toMemIQOg2Resp_1_0_bits_resp,
  output io_toMemIQOg2Resp_0_0_valid,
  output [1:0] io_toMemIQOg2Resp_0_0_bits_resp,
  output [31:0] io_toBypassNetworkImmInfo_1_imm,
  output [3:0] io_toBypassNetworkImmInfo_1_immType
);

  // ---- stage-2 payload / valid / flush-pipeline 寄存器 (golden 同名, 忠实复刻) ----
  reg  s2_toExuValid_4_0;
  reg  s2_toExuValid_3_0;
  reg  s2_toExuValid_2_0;
  reg  s2_toExuValid_1_1;
  reg  s2_toExuValid_1_0;
  reg  s2_toExuValid_0_1;
  reg  s2_toExuValid_0_0;
  reg  [34:0] s2_toExuData_4_0_fuType;
  reg  [8:0] s2_toExuData_4_0_fuOpType;
  reg  [127:0] s2_toExuData_4_0_src_0;
  reg  [127:0] s2_toExuData_4_0_src_1;
  reg  [127:0] s2_toExuData_4_0_src_2;
  reg  [127:0] s2_toExuData_4_0_src_3;
  reg  [127:0] s2_toExuData_4_0_src_4;
  reg  s2_toExuData_4_0_robIdx_flag;
  reg  [7:0] s2_toExuData_4_0_robIdx_value;
  reg  [6:0] s2_toExuData_4_0_pdest;
  reg  s2_toExuData_4_0_vecWen;
  reg  s2_toExuData_4_0_v0Wen;
  reg  s2_toExuData_4_0_vlWen;
  reg  s2_toExuData_4_0_vpu_vma;
  reg  s2_toExuData_4_0_vpu_vta;
  reg  [1:0] s2_toExuData_4_0_vpu_vsew;
  reg  [2:0] s2_toExuData_4_0_vpu_vlmul;
  reg  s2_toExuData_4_0_vpu_vm;
  reg  [7:0] s2_toExuData_4_0_vpu_vstart;
  reg  [6:0] s2_toExuData_4_0_vpu_vuopIdx;
  reg  s2_toExuData_4_0_vpu_lastUop;
  reg  [127:0] s2_toExuData_4_0_vpu_vmask;
  reg  [2:0] s2_toExuData_4_0_vpu_nf;
  reg  [1:0] s2_toExuData_4_0_vpu_veew;
  reg  s2_toExuData_4_0_vpu_isVleff;
  reg  s2_toExuData_4_0_ftqIdx_flag;
  reg  [5:0] s2_toExuData_4_0_ftqIdx_value;
  reg  [3:0] s2_toExuData_4_0_ftqOffset;
  reg  [4:0] s2_toExuData_4_0_numLsElem;
  reg  s2_toExuData_4_0_sqIdx_flag;
  reg  [5:0] s2_toExuData_4_0_sqIdx_value;
  reg  s2_toExuData_4_0_lqIdx_flag;
  reg  [6:0] s2_toExuData_4_0_lqIdx_value;
  reg  [3:0] s2_toExuData_4_0_dataSources_0_value;
  reg  [3:0] s2_toExuData_4_0_dataSources_1_value;
  reg  [3:0] s2_toExuData_4_0_dataSources_2_value;
  reg  [3:0] s2_toExuData_4_0_dataSources_3_value;
  reg  [3:0] s2_toExuData_4_0_dataSources_4_value;
  reg  [63:0] s2_toExuData_4_0_perfDebugInfo_enqRsTime;
  reg  [63:0] s2_toExuData_4_0_perfDebugInfo_selectTime;
  reg  [63:0] s2_toExuData_4_0_perfDebugInfo_issueTime;
  reg  [34:0] s2_toExuData_3_0_fuType;
  reg  [8:0] s2_toExuData_3_0_fuOpType;
  reg  [127:0] s2_toExuData_3_0_src_0;
  reg  [127:0] s2_toExuData_3_0_src_1;
  reg  [127:0] s2_toExuData_3_0_src_2;
  reg  [127:0] s2_toExuData_3_0_src_3;
  reg  [127:0] s2_toExuData_3_0_src_4;
  reg  s2_toExuData_3_0_robIdx_flag;
  reg  [7:0] s2_toExuData_3_0_robIdx_value;
  reg  [6:0] s2_toExuData_3_0_pdest;
  reg  s2_toExuData_3_0_vecWen;
  reg  s2_toExuData_3_0_v0Wen;
  reg  s2_toExuData_3_0_vlWen;
  reg  s2_toExuData_3_0_vpu_vma;
  reg  s2_toExuData_3_0_vpu_vta;
  reg  [1:0] s2_toExuData_3_0_vpu_vsew;
  reg  [2:0] s2_toExuData_3_0_vpu_vlmul;
  reg  s2_toExuData_3_0_vpu_vm;
  reg  [7:0] s2_toExuData_3_0_vpu_vstart;
  reg  [6:0] s2_toExuData_3_0_vpu_vuopIdx;
  reg  s2_toExuData_3_0_vpu_lastUop;
  reg  [127:0] s2_toExuData_3_0_vpu_vmask;
  reg  [2:0] s2_toExuData_3_0_vpu_nf;
  reg  [1:0] s2_toExuData_3_0_vpu_veew;
  reg  s2_toExuData_3_0_vpu_isVleff;
  reg  s2_toExuData_3_0_ftqIdx_flag;
  reg  [5:0] s2_toExuData_3_0_ftqIdx_value;
  reg  [3:0] s2_toExuData_3_0_ftqOffset;
  reg  [4:0] s2_toExuData_3_0_numLsElem;
  reg  s2_toExuData_3_0_sqIdx_flag;
  reg  [5:0] s2_toExuData_3_0_sqIdx_value;
  reg  s2_toExuData_3_0_lqIdx_flag;
  reg  [6:0] s2_toExuData_3_0_lqIdx_value;
  reg  [3:0] s2_toExuData_3_0_dataSources_0_value;
  reg  [3:0] s2_toExuData_3_0_dataSources_1_value;
  reg  [3:0] s2_toExuData_3_0_dataSources_2_value;
  reg  [3:0] s2_toExuData_3_0_dataSources_3_value;
  reg  [3:0] s2_toExuData_3_0_dataSources_4_value;
  reg  [63:0] s2_toExuData_3_0_perfDebugInfo_enqRsTime;
  reg  [63:0] s2_toExuData_3_0_perfDebugInfo_selectTime;
  reg  [63:0] s2_toExuData_3_0_perfDebugInfo_issueTime;
  reg  [34:0] s2_toExuData_2_0_fuType;
  reg  [8:0] s2_toExuData_2_0_fuOpType;
  reg  [127:0] s2_toExuData_2_0_src_0;
  reg  [127:0] s2_toExuData_2_0_src_1;
  reg  [127:0] s2_toExuData_2_0_src_2;
  reg  [127:0] s2_toExuData_2_0_src_3;
  reg  [127:0] s2_toExuData_2_0_src_4;
  reg  s2_toExuData_2_0_robIdx_flag;
  reg  [7:0] s2_toExuData_2_0_robIdx_value;
  reg  [6:0] s2_toExuData_2_0_pdest;
  reg  s2_toExuData_2_0_vecWen;
  reg  s2_toExuData_2_0_v0Wen;
  reg  s2_toExuData_2_0_fpu_wflags;
  reg  s2_toExuData_2_0_vpu_vma;
  reg  s2_toExuData_2_0_vpu_vta;
  reg  [1:0] s2_toExuData_2_0_vpu_vsew;
  reg  [2:0] s2_toExuData_2_0_vpu_vlmul;
  reg  s2_toExuData_2_0_vpu_vm;
  reg  [7:0] s2_toExuData_2_0_vpu_vstart;
  reg  [6:0] s2_toExuData_2_0_vpu_vuopIdx;
  reg  s2_toExuData_2_0_vpu_isExt;
  reg  s2_toExuData_2_0_vpu_isNarrow;
  reg  s2_toExuData_2_0_vpu_isDstMask;
  reg  s2_toExuData_2_0_vpu_isOpMask;
  reg  [3:0] s2_toExuData_2_0_dataSources_0_value;
  reg  [3:0] s2_toExuData_2_0_dataSources_1_value;
  reg  [3:0] s2_toExuData_2_0_dataSources_2_value;
  reg  [3:0] s2_toExuData_2_0_dataSources_3_value;
  reg  [3:0] s2_toExuData_2_0_dataSources_4_value;
  reg  [63:0] s2_toExuData_2_0_perfDebugInfo_enqRsTime;
  reg  [63:0] s2_toExuData_2_0_perfDebugInfo_selectTime;
  reg  [63:0] s2_toExuData_2_0_perfDebugInfo_issueTime;
  reg  [34:0] s2_toExuData_1_1_fuType;
  reg  [8:0] s2_toExuData_1_1_fuOpType;
  reg  [127:0] s2_toExuData_1_1_src_0;
  reg  [127:0] s2_toExuData_1_1_src_1;
  reg  [127:0] s2_toExuData_1_1_src_2;
  reg  [127:0] s2_toExuData_1_1_src_3;
  reg  [127:0] s2_toExuData_1_1_src_4;
  reg  s2_toExuData_1_1_robIdx_flag;
  reg  [7:0] s2_toExuData_1_1_robIdx_value;
  reg  [7:0] s2_toExuData_1_1_pdest;
  reg  s2_toExuData_1_1_fpWen;
  reg  s2_toExuData_1_1_vecWen;
  reg  s2_toExuData_1_1_v0Wen;
  reg  s2_toExuData_1_1_fpu_wflags;
  reg  s2_toExuData_1_1_vpu_vma;
  reg  s2_toExuData_1_1_vpu_vta;
  reg  [1:0] s2_toExuData_1_1_vpu_vsew;
  reg  [2:0] s2_toExuData_1_1_vpu_vlmul;
  reg  s2_toExuData_1_1_vpu_vm;
  reg  [7:0] s2_toExuData_1_1_vpu_vstart;
  reg  s2_toExuData_1_1_vpu_fpu_isFoldTo1_2;
  reg  s2_toExuData_1_1_vpu_fpu_isFoldTo1_4;
  reg  s2_toExuData_1_1_vpu_fpu_isFoldTo1_8;
  reg  [6:0] s2_toExuData_1_1_vpu_vuopIdx;
  reg  s2_toExuData_1_1_vpu_lastUop;
  reg  s2_toExuData_1_1_vpu_isNarrow;
  reg  s2_toExuData_1_1_vpu_isDstMask;
  reg  [3:0] s2_toExuData_1_1_dataSources_0_value;
  reg  [3:0] s2_toExuData_1_1_dataSources_1_value;
  reg  [3:0] s2_toExuData_1_1_dataSources_2_value;
  reg  [3:0] s2_toExuData_1_1_dataSources_3_value;
  reg  [3:0] s2_toExuData_1_1_dataSources_4_value;
  reg  [63:0] s2_toExuData_1_1_perfDebugInfo_enqRsTime;
  reg  [63:0] s2_toExuData_1_1_perfDebugInfo_selectTime;
  reg  [63:0] s2_toExuData_1_1_perfDebugInfo_issueTime;
  reg  [34:0] s2_toExuData_1_0_fuType;
  reg  [8:0] s2_toExuData_1_0_fuOpType;
  reg  [127:0] s2_toExuData_1_0_src_0;
  reg  [127:0] s2_toExuData_1_0_src_1;
  reg  [127:0] s2_toExuData_1_0_src_2;
  reg  [127:0] s2_toExuData_1_0_src_3;
  reg  [127:0] s2_toExuData_1_0_src_4;
  reg  s2_toExuData_1_0_robIdx_flag;
  reg  [7:0] s2_toExuData_1_0_robIdx_value;
  reg  [6:0] s2_toExuData_1_0_pdest;
  reg  s2_toExuData_1_0_vecWen;
  reg  s2_toExuData_1_0_v0Wen;
  reg  s2_toExuData_1_0_fpu_wflags;
  reg  s2_toExuData_1_0_vpu_vma;
  reg  s2_toExuData_1_0_vpu_vta;
  reg  [1:0] s2_toExuData_1_0_vpu_vsew;
  reg  [2:0] s2_toExuData_1_0_vpu_vlmul;
  reg  s2_toExuData_1_0_vpu_vm;
  reg  [7:0] s2_toExuData_1_0_vpu_vstart;
  reg  [6:0] s2_toExuData_1_0_vpu_vuopIdx;
  reg  s2_toExuData_1_0_vpu_isExt;
  reg  s2_toExuData_1_0_vpu_isNarrow;
  reg  s2_toExuData_1_0_vpu_isDstMask;
  reg  s2_toExuData_1_0_vpu_isOpMask;
  reg  [3:0] s2_toExuData_1_0_dataSources_0_value;
  reg  [3:0] s2_toExuData_1_0_dataSources_1_value;
  reg  [3:0] s2_toExuData_1_0_dataSources_2_value;
  reg  [3:0] s2_toExuData_1_0_dataSources_3_value;
  reg  [3:0] s2_toExuData_1_0_dataSources_4_value;
  reg  [63:0] s2_toExuData_1_0_perfDebugInfo_enqRsTime;
  reg  [63:0] s2_toExuData_1_0_perfDebugInfo_selectTime;
  reg  [63:0] s2_toExuData_1_0_perfDebugInfo_issueTime;
  reg  [34:0] s2_toExuData_0_1_fuType;
  reg  [8:0] s2_toExuData_0_1_fuOpType;
  reg  [127:0] s2_toExuData_0_1_src_0;
  reg  [127:0] s2_toExuData_0_1_src_1;
  reg  [127:0] s2_toExuData_0_1_src_2;
  reg  [127:0] s2_toExuData_0_1_src_3;
  reg  [127:0] s2_toExuData_0_1_src_4;
  reg  s2_toExuData_0_1_robIdx_flag;
  reg  [7:0] s2_toExuData_0_1_robIdx_value;
  reg  [7:0] s2_toExuData_0_1_pdest;
  reg  s2_toExuData_0_1_rfWen;
  reg  s2_toExuData_0_1_fpWen;
  reg  s2_toExuData_0_1_vecWen;
  reg  s2_toExuData_0_1_v0Wen;
  reg  s2_toExuData_0_1_vlWen;
  reg  s2_toExuData_0_1_fpu_wflags;
  reg  s2_toExuData_0_1_vpu_vma;
  reg  s2_toExuData_0_1_vpu_vta;
  reg  [1:0] s2_toExuData_0_1_vpu_vsew;
  reg  [2:0] s2_toExuData_0_1_vpu_vlmul;
  reg  s2_toExuData_0_1_vpu_vm;
  reg  [7:0] s2_toExuData_0_1_vpu_vstart;
  reg  s2_toExuData_0_1_vpu_fpu_isFoldTo1_2;
  reg  s2_toExuData_0_1_vpu_fpu_isFoldTo1_4;
  reg  s2_toExuData_0_1_vpu_fpu_isFoldTo1_8;
  reg  [6:0] s2_toExuData_0_1_vpu_vuopIdx;
  reg  s2_toExuData_0_1_vpu_lastUop;
  reg  s2_toExuData_0_1_vpu_isNarrow;
  reg  s2_toExuData_0_1_vpu_isDstMask;
  reg  [3:0] s2_toExuData_0_1_dataSources_0_value;
  reg  [3:0] s2_toExuData_0_1_dataSources_1_value;
  reg  [3:0] s2_toExuData_0_1_dataSources_2_value;
  reg  [3:0] s2_toExuData_0_1_dataSources_3_value;
  reg  [3:0] s2_toExuData_0_1_dataSources_4_value;
  reg  [63:0] s2_toExuData_0_1_perfDebugInfo_enqRsTime;
  reg  [63:0] s2_toExuData_0_1_perfDebugInfo_selectTime;
  reg  [63:0] s2_toExuData_0_1_perfDebugInfo_issueTime;
  reg  [34:0] s2_toExuData_0_0_fuType;
  reg  [8:0] s2_toExuData_0_0_fuOpType;
  reg  [127:0] s2_toExuData_0_0_src_0;
  reg  [127:0] s2_toExuData_0_0_src_1;
  reg  [127:0] s2_toExuData_0_0_src_2;
  reg  [127:0] s2_toExuData_0_0_src_3;
  reg  [127:0] s2_toExuData_0_0_src_4;
  reg  s2_toExuData_0_0_robIdx_flag;
  reg  [7:0] s2_toExuData_0_0_robIdx_value;
  reg  [6:0] s2_toExuData_0_0_pdest;
  reg  s2_toExuData_0_0_vecWen;
  reg  s2_toExuData_0_0_v0Wen;
  reg  s2_toExuData_0_0_fpu_wflags;
  reg  s2_toExuData_0_0_vpu_vma;
  reg  s2_toExuData_0_0_vpu_vta;
  reg  [1:0] s2_toExuData_0_0_vpu_vsew;
  reg  [2:0] s2_toExuData_0_0_vpu_vlmul;
  reg  s2_toExuData_0_0_vpu_vm;
  reg  [7:0] s2_toExuData_0_0_vpu_vstart;
  reg  [6:0] s2_toExuData_0_0_vpu_vuopIdx;
  reg  s2_toExuData_0_0_vpu_isExt;
  reg  s2_toExuData_0_0_vpu_isNarrow;
  reg  s2_toExuData_0_0_vpu_isDstMask;
  reg  s2_toExuData_0_0_vpu_isOpMask;
  reg  [3:0] s2_toExuData_0_0_dataSources_0_value;
  reg  [3:0] s2_toExuData_0_0_dataSources_1_value;
  reg  [3:0] s2_toExuData_0_0_dataSources_2_value;
  reg  [3:0] s2_toExuData_0_0_dataSources_3_value;
  reg  [3:0] s2_toExuData_0_0_dataSources_4_value;
  reg  [63:0] s2_toExuData_0_0_perfDebugInfo_enqRsTime;
  reg  [63:0] s2_toExuData_0_0_perfDebugInfo_selectTime;
  reg  [63:0] s2_toExuData_0_0_perfDebugInfo_issueTime;
  reg  s2_flush_next_valid_last_REG;
  reg  s2_flush_next_bits_r_robIdx_flag;
  reg  [7:0] s2_flush_next_bits_r_robIdx_value;
  reg  s2_flush_next_bits_r_level;
  reg  s2_flush_next_valid_last_REG_1;
  reg  s2_flush_next_bits_r_1_robIdx_flag;
  reg  [7:0] s2_flush_next_bits_r_1_robIdx_value;
  reg  s2_flush_next_bits_r_1_level;
  reg  s2_flush_next_valid_last_REG_2;
  reg  s2_flush_next_bits_r_2_robIdx_flag;
  reg  [7:0] s2_flush_next_bits_r_2_robIdx_value;
  reg  s2_flush_next_bits_r_2_level;
  reg  s2_flush_next_valid_last_REG_3;
  reg  s2_flush_next_bits_r_3_robIdx_flag;
  reg  [7:0] s2_flush_next_bits_r_3_robIdx_value;
  reg  s2_flush_next_bits_r_3_level;
  reg  s2_flush_next_valid_last_REG_4;
  reg  s2_flush_next_bits_r_4_robIdx_flag;
  reg  [7:0] s2_flush_next_bits_r_4_robIdx_value;
  reg  s2_flush_next_bits_r_4_level;
  reg  s2_flush_next_valid_last_REG_5;
  reg  s2_flush_next_bits_r_5_robIdx_flag;
  reg  [7:0] s2_flush_next_bits_r_5_robIdx_value;
  reg  s2_flush_next_bits_r_5_level;
  reg  s2_flush_next_valid_last_REG_6;
  reg  s2_flush_next_bits_r_6_robIdx_flag;
  reg  [7:0] s2_flush_next_bits_r_6_robIdx_value;
  reg  s2_flush_next_bits_r_6_level;
  reg  [31:0] r_1_imm;
  reg  [3:0] r_1_immType;

  // robIdxHit(a, fFlag, fValue, fLevel) = flush 命中该 uop:
  //   fLevel & a==f (精确同一条 flushItself) | (a.flag ^ f.flag ^ a.value > f.value)
  //   (a 不比 f 更老 => 被更老/同源 flush 冲刷)。
  function automatic logic robIdxHit(
      input logic       aFlag, input logic [7:0] aValue,
      input logic       fFlag, input logic [7:0] fValue, input logic fLevel);
    robIdxHit = fLevel & ({aFlag, aValue} == {fFlag, fValue})
              | (aFlag ^ fFlag ^ (aValue > fValue));
  endfunction

  // 每条通道: 未被当拍/上拍 flush 命中 & 上游 valid => 下拍 valid。
  wire flushHit_0_0 =
      (s2_flush_next_valid_last_REG
       & robIdxHit(io_fromOg1VfArith_0_0_bits_robIdx_flag, io_fromOg1VfArith_0_0_bits_robIdx_value,
                   s2_flush_next_bits_r_robIdx_flag,
                   s2_flush_next_bits_r_robIdx_value,
                   s2_flush_next_bits_r_level))
      | (io_flush_valid
         & robIdxHit(io_fromOg1VfArith_0_0_bits_robIdx_flag, io_fromOg1VfArith_0_0_bits_robIdx_value,
                     io_flush_bits_robIdx_flag, io_flush_bits_robIdx_value,
                     io_flush_bits_level));
  wire fire_0_0 = io_fromOg1VfArith_0_0_valid & ~flushHit_0_0;
  wire flushHit_0_1 =
      (s2_flush_next_valid_last_REG_1
       & robIdxHit(io_fromOg1VfArith_0_1_bits_robIdx_flag, io_fromOg1VfArith_0_1_bits_robIdx_value,
                   s2_flush_next_bits_r_1_robIdx_flag,
                   s2_flush_next_bits_r_1_robIdx_value,
                   s2_flush_next_bits_r_1_level))
      | (io_flush_valid
         & robIdxHit(io_fromOg1VfArith_0_1_bits_robIdx_flag, io_fromOg1VfArith_0_1_bits_robIdx_value,
                     io_flush_bits_robIdx_flag, io_flush_bits_robIdx_value,
                     io_flush_bits_level));
  wire fire_0_1 = io_fromOg1VfArith_0_1_valid & ~flushHit_0_1;
  wire flushHit_1_0 =
      (s2_flush_next_valid_last_REG_2
       & robIdxHit(io_fromOg1VfArith_1_0_bits_robIdx_flag, io_fromOg1VfArith_1_0_bits_robIdx_value,
                   s2_flush_next_bits_r_2_robIdx_flag,
                   s2_flush_next_bits_r_2_robIdx_value,
                   s2_flush_next_bits_r_2_level))
      | (io_flush_valid
         & robIdxHit(io_fromOg1VfArith_1_0_bits_robIdx_flag, io_fromOg1VfArith_1_0_bits_robIdx_value,
                     io_flush_bits_robIdx_flag, io_flush_bits_robIdx_value,
                     io_flush_bits_level));
  wire fire_1_0 = io_fromOg1VfArith_1_0_valid & ~flushHit_1_0;
  wire flushHit_1_1 =
      (s2_flush_next_valid_last_REG_3
       & robIdxHit(io_fromOg1VfArith_1_1_bits_robIdx_flag, io_fromOg1VfArith_1_1_bits_robIdx_value,
                   s2_flush_next_bits_r_3_robIdx_flag,
                   s2_flush_next_bits_r_3_robIdx_value,
                   s2_flush_next_bits_r_3_level))
      | (io_flush_valid
         & robIdxHit(io_fromOg1VfArith_1_1_bits_robIdx_flag, io_fromOg1VfArith_1_1_bits_robIdx_value,
                     io_flush_bits_robIdx_flag, io_flush_bits_robIdx_value,
                     io_flush_bits_level));
  wire fire_1_1 = io_fromOg1VfArith_1_1_valid & ~flushHit_1_1;
  wire flushHit_2_0 =
      (s2_flush_next_valid_last_REG_4
       & robIdxHit(io_fromOg1VfArith_2_0_bits_robIdx_flag, io_fromOg1VfArith_2_0_bits_robIdx_value,
                   s2_flush_next_bits_r_4_robIdx_flag,
                   s2_flush_next_bits_r_4_robIdx_value,
                   s2_flush_next_bits_r_4_level))
      | (io_flush_valid
         & robIdxHit(io_fromOg1VfArith_2_0_bits_robIdx_flag, io_fromOg1VfArith_2_0_bits_robIdx_value,
                     io_flush_bits_robIdx_flag, io_flush_bits_robIdx_value,
                     io_flush_bits_level));
  wire fire_2_0 = io_fromOg1VfArith_2_0_valid & ~flushHit_2_0;
  wire flushHit_3_0 =
      (s2_flush_next_valid_last_REG_5
       & robIdxHit(io_fromOg1VecMem_0_0_bits_robIdx_flag, io_fromOg1VecMem_0_0_bits_robIdx_value,
                   s2_flush_next_bits_r_5_robIdx_flag,
                   s2_flush_next_bits_r_5_robIdx_value,
                   s2_flush_next_bits_r_5_level))
      | (io_flush_valid
         & robIdxHit(io_fromOg1VecMem_0_0_bits_robIdx_flag, io_fromOg1VecMem_0_0_bits_robIdx_value,
                     io_flush_bits_robIdx_flag, io_flush_bits_robIdx_value,
                     io_flush_bits_level));
  wire fire_3_0 = io_fromOg1VecMem_0_0_valid & ~flushHit_3_0;
  wire flushHit_4_0 =
      (s2_flush_next_valid_last_REG_6
       & robIdxHit(io_fromOg1VecMem_1_0_bits_robIdx_flag, io_fromOg1VecMem_1_0_bits_robIdx_value,
                   s2_flush_next_bits_r_6_robIdx_flag,
                   s2_flush_next_bits_r_6_robIdx_value,
                   s2_flush_next_bits_r_6_level))
      | (io_flush_valid
         & robIdxHit(io_fromOg1VecMem_1_0_bits_robIdx_flag, io_fromOg1VecMem_1_0_bits_robIdx_value,
                     io_flush_bits_robIdx_flag, io_flush_bits_robIdx_value,
                     io_flush_bits_level));
  wire fire_4_0 = io_fromOg1VecMem_1_0_valid & ~flushHit_4_0;

  always @(posedge clock) begin
    s2_toExuValid_0_0 <= fire_0_0;
    s2_toExuValid_0_1 <= fire_0_1;
    s2_toExuValid_1_0 <= fire_1_0;
    s2_toExuValid_1_1 <= fire_1_1;
    s2_toExuValid_2_0 <= fire_2_0;
    s2_toExuValid_3_0 <= fire_3_0;
    s2_toExuValid_4_0 <= fire_4_0;

    if (fire_0_0) begin
      s2_toExuData_0_0_fuType <= io_fromOg1VfArith_0_0_bits_fuType;
      s2_toExuData_0_0_fuOpType <= io_fromOg1VfArith_0_0_bits_fuOpType;
      s2_toExuData_0_0_src_0 <= io_fromOg1VfArith_0_0_bits_src_0;
      s2_toExuData_0_0_src_1 <= io_fromOg1VfArith_0_0_bits_src_1;
      s2_toExuData_0_0_src_2 <= io_fromOg1VfArith_0_0_bits_src_2;
      s2_toExuData_0_0_src_3 <= io_fromOg1VfArith_0_0_bits_src_3;
      s2_toExuData_0_0_src_4 <= io_fromOg1VfArith_0_0_bits_src_4;
      s2_toExuData_0_0_robIdx_flag <= io_fromOg1VfArith_0_0_bits_robIdx_flag;
      s2_toExuData_0_0_robIdx_value <= io_fromOg1VfArith_0_0_bits_robIdx_value;
      s2_toExuData_0_0_pdest <= io_fromOg1VfArith_0_0_bits_pdest;
      s2_toExuData_0_0_vecWen <= io_fromOg1VfArith_0_0_bits_vecWen;
      s2_toExuData_0_0_v0Wen <= io_fromOg1VfArith_0_0_bits_v0Wen;
      s2_toExuData_0_0_fpu_wflags <= io_fromOg1VfArith_0_0_bits_fpu_wflags;
      s2_toExuData_0_0_vpu_vma <= io_fromOg1VfArith_0_0_bits_vpu_vma;
      s2_toExuData_0_0_vpu_vta <= io_fromOg1VfArith_0_0_bits_vpu_vta;
      s2_toExuData_0_0_vpu_vsew <= io_fromOg1VfArith_0_0_bits_vpu_vsew;
      s2_toExuData_0_0_vpu_vlmul <= io_fromOg1VfArith_0_0_bits_vpu_vlmul;
      s2_toExuData_0_0_vpu_vm <= io_fromOg1VfArith_0_0_bits_vpu_vm;
      s2_toExuData_0_0_vpu_vstart <= io_fromOg1VfArith_0_0_bits_vpu_vstart;
      s2_toExuData_0_0_vpu_vuopIdx <= io_fromOg1VfArith_0_0_bits_vpu_vuopIdx;
      s2_toExuData_0_0_vpu_isExt <= io_fromOg1VfArith_0_0_bits_vpu_isExt;
      s2_toExuData_0_0_vpu_isNarrow <= io_fromOg1VfArith_0_0_bits_vpu_isNarrow;
      s2_toExuData_0_0_vpu_isDstMask <= io_fromOg1VfArith_0_0_bits_vpu_isDstMask;
      s2_toExuData_0_0_vpu_isOpMask <= io_fromOg1VfArith_0_0_bits_vpu_isOpMask;
      s2_toExuData_0_0_dataSources_0_value <= io_fromOg1VfArith_0_0_bits_dataSources_0_value;
      s2_toExuData_0_0_dataSources_1_value <= io_fromOg1VfArith_0_0_bits_dataSources_1_value;
      s2_toExuData_0_0_dataSources_2_value <= io_fromOg1VfArith_0_0_bits_dataSources_2_value;
      s2_toExuData_0_0_dataSources_3_value <= io_fromOg1VfArith_0_0_bits_dataSources_3_value;
      s2_toExuData_0_0_dataSources_4_value <= io_fromOg1VfArith_0_0_bits_dataSources_4_value;
      s2_toExuData_0_0_perfDebugInfo_enqRsTime <= io_fromOg1VfArith_0_0_bits_perfDebugInfo_enqRsTime;
      s2_toExuData_0_0_perfDebugInfo_selectTime <= io_fromOg1VfArith_0_0_bits_perfDebugInfo_selectTime;
      s2_toExuData_0_0_perfDebugInfo_issueTime <= io_fromOg1VfArith_0_0_bits_perfDebugInfo_issueTime;
    end
    if (fire_0_1) begin
      s2_toExuData_0_1_fuType <= io_fromOg1VfArith_0_1_bits_fuType;
      s2_toExuData_0_1_fuOpType <= io_fromOg1VfArith_0_1_bits_fuOpType;
      s2_toExuData_0_1_src_0 <= io_fromOg1VfArith_0_1_bits_src_0;
      s2_toExuData_0_1_src_1 <= io_fromOg1VfArith_0_1_bits_src_1;
      s2_toExuData_0_1_src_2 <= io_fromOg1VfArith_0_1_bits_src_2;
      s2_toExuData_0_1_src_3 <= io_fromOg1VfArith_0_1_bits_src_3;
      s2_toExuData_0_1_src_4 <= io_fromOg1VfArith_0_1_bits_src_4;
      s2_toExuData_0_1_robIdx_flag <= io_fromOg1VfArith_0_1_bits_robIdx_flag;
      s2_toExuData_0_1_robIdx_value <= io_fromOg1VfArith_0_1_bits_robIdx_value;
      s2_toExuData_0_1_pdest <= io_fromOg1VfArith_0_1_bits_pdest;
      s2_toExuData_0_1_rfWen <= io_fromOg1VfArith_0_1_bits_rfWen;
      s2_toExuData_0_1_fpWen <= io_fromOg1VfArith_0_1_bits_fpWen;
      s2_toExuData_0_1_vecWen <= io_fromOg1VfArith_0_1_bits_vecWen;
      s2_toExuData_0_1_v0Wen <= io_fromOg1VfArith_0_1_bits_v0Wen;
      s2_toExuData_0_1_vlWen <= io_fromOg1VfArith_0_1_bits_vlWen;
      s2_toExuData_0_1_fpu_wflags <= io_fromOg1VfArith_0_1_bits_fpu_wflags;
      s2_toExuData_0_1_vpu_vma <= io_fromOg1VfArith_0_1_bits_vpu_vma;
      s2_toExuData_0_1_vpu_vta <= io_fromOg1VfArith_0_1_bits_vpu_vta;
      s2_toExuData_0_1_vpu_vsew <= io_fromOg1VfArith_0_1_bits_vpu_vsew;
      s2_toExuData_0_1_vpu_vlmul <= io_fromOg1VfArith_0_1_bits_vpu_vlmul;
      s2_toExuData_0_1_vpu_vm <= io_fromOg1VfArith_0_1_bits_vpu_vm;
      s2_toExuData_0_1_vpu_vstart <= io_fromOg1VfArith_0_1_bits_vpu_vstart;
      s2_toExuData_0_1_vpu_fpu_isFoldTo1_2 <= io_fromOg1VfArith_0_1_bits_vpu_fpu_isFoldTo1_2;
      s2_toExuData_0_1_vpu_fpu_isFoldTo1_4 <= io_fromOg1VfArith_0_1_bits_vpu_fpu_isFoldTo1_4;
      s2_toExuData_0_1_vpu_fpu_isFoldTo1_8 <= io_fromOg1VfArith_0_1_bits_vpu_fpu_isFoldTo1_8;
      s2_toExuData_0_1_vpu_vuopIdx <= io_fromOg1VfArith_0_1_bits_vpu_vuopIdx;
      s2_toExuData_0_1_vpu_lastUop <= io_fromOg1VfArith_0_1_bits_vpu_lastUop;
      s2_toExuData_0_1_vpu_isNarrow <= io_fromOg1VfArith_0_1_bits_vpu_isNarrow;
      s2_toExuData_0_1_vpu_isDstMask <= io_fromOg1VfArith_0_1_bits_vpu_isDstMask;
      s2_toExuData_0_1_dataSources_0_value <= io_fromOg1VfArith_0_1_bits_dataSources_0_value;
      s2_toExuData_0_1_dataSources_1_value <= io_fromOg1VfArith_0_1_bits_dataSources_1_value;
      s2_toExuData_0_1_dataSources_2_value <= io_fromOg1VfArith_0_1_bits_dataSources_2_value;
      s2_toExuData_0_1_dataSources_3_value <= io_fromOg1VfArith_0_1_bits_dataSources_3_value;
      s2_toExuData_0_1_dataSources_4_value <= io_fromOg1VfArith_0_1_bits_dataSources_4_value;
      s2_toExuData_0_1_perfDebugInfo_enqRsTime <= io_fromOg1VfArith_0_1_bits_perfDebugInfo_enqRsTime;
      s2_toExuData_0_1_perfDebugInfo_selectTime <= io_fromOg1VfArith_0_1_bits_perfDebugInfo_selectTime;
      s2_toExuData_0_1_perfDebugInfo_issueTime <= io_fromOg1VfArith_0_1_bits_perfDebugInfo_issueTime;
    end
    if (fire_1_0) begin
      s2_toExuData_1_0_fuType <= io_fromOg1VfArith_1_0_bits_fuType;
      s2_toExuData_1_0_fuOpType <= io_fromOg1VfArith_1_0_bits_fuOpType;
      s2_toExuData_1_0_src_0 <= io_fromOg1VfArith_1_0_bits_src_0;
      s2_toExuData_1_0_src_1 <= io_fromOg1VfArith_1_0_bits_src_1;
      s2_toExuData_1_0_src_2 <= io_fromOg1VfArith_1_0_bits_src_2;
      s2_toExuData_1_0_src_3 <= io_fromOg1VfArith_1_0_bits_src_3;
      s2_toExuData_1_0_src_4 <= io_fromOg1VfArith_1_0_bits_src_4;
      s2_toExuData_1_0_robIdx_flag <= io_fromOg1VfArith_1_0_bits_robIdx_flag;
      s2_toExuData_1_0_robIdx_value <= io_fromOg1VfArith_1_0_bits_robIdx_value;
      s2_toExuData_1_0_pdest <= io_fromOg1VfArith_1_0_bits_pdest;
      s2_toExuData_1_0_vecWen <= io_fromOg1VfArith_1_0_bits_vecWen;
      s2_toExuData_1_0_v0Wen <= io_fromOg1VfArith_1_0_bits_v0Wen;
      s2_toExuData_1_0_fpu_wflags <= io_fromOg1VfArith_1_0_bits_fpu_wflags;
      s2_toExuData_1_0_vpu_vma <= io_fromOg1VfArith_1_0_bits_vpu_vma;
      s2_toExuData_1_0_vpu_vta <= io_fromOg1VfArith_1_0_bits_vpu_vta;
      s2_toExuData_1_0_vpu_vsew <= io_fromOg1VfArith_1_0_bits_vpu_vsew;
      s2_toExuData_1_0_vpu_vlmul <= io_fromOg1VfArith_1_0_bits_vpu_vlmul;
      s2_toExuData_1_0_vpu_vm <= io_fromOg1VfArith_1_0_bits_vpu_vm;
      s2_toExuData_1_0_vpu_vstart <= io_fromOg1VfArith_1_0_bits_vpu_vstart;
      s2_toExuData_1_0_vpu_vuopIdx <= io_fromOg1VfArith_1_0_bits_vpu_vuopIdx;
      s2_toExuData_1_0_vpu_isExt <= io_fromOg1VfArith_1_0_bits_vpu_isExt;
      s2_toExuData_1_0_vpu_isNarrow <= io_fromOg1VfArith_1_0_bits_vpu_isNarrow;
      s2_toExuData_1_0_vpu_isDstMask <= io_fromOg1VfArith_1_0_bits_vpu_isDstMask;
      s2_toExuData_1_0_vpu_isOpMask <= io_fromOg1VfArith_1_0_bits_vpu_isOpMask;
      s2_toExuData_1_0_dataSources_0_value <= io_fromOg1VfArith_1_0_bits_dataSources_0_value;
      s2_toExuData_1_0_dataSources_1_value <= io_fromOg1VfArith_1_0_bits_dataSources_1_value;
      s2_toExuData_1_0_dataSources_2_value <= io_fromOg1VfArith_1_0_bits_dataSources_2_value;
      s2_toExuData_1_0_dataSources_3_value <= io_fromOg1VfArith_1_0_bits_dataSources_3_value;
      s2_toExuData_1_0_dataSources_4_value <= io_fromOg1VfArith_1_0_bits_dataSources_4_value;
      s2_toExuData_1_0_perfDebugInfo_enqRsTime <= io_fromOg1VfArith_1_0_bits_perfDebugInfo_enqRsTime;
      s2_toExuData_1_0_perfDebugInfo_selectTime <= io_fromOg1VfArith_1_0_bits_perfDebugInfo_selectTime;
      s2_toExuData_1_0_perfDebugInfo_issueTime <= io_fromOg1VfArith_1_0_bits_perfDebugInfo_issueTime;
    end
    if (fire_1_1) begin
      s2_toExuData_1_1_fuType <= io_fromOg1VfArith_1_1_bits_fuType;
      s2_toExuData_1_1_fuOpType <= io_fromOg1VfArith_1_1_bits_fuOpType;
      s2_toExuData_1_1_src_0 <= io_fromOg1VfArith_1_1_bits_src_0;
      s2_toExuData_1_1_src_1 <= io_fromOg1VfArith_1_1_bits_src_1;
      s2_toExuData_1_1_src_2 <= io_fromOg1VfArith_1_1_bits_src_2;
      s2_toExuData_1_1_src_3 <= io_fromOg1VfArith_1_1_bits_src_3;
      s2_toExuData_1_1_src_4 <= io_fromOg1VfArith_1_1_bits_src_4;
      s2_toExuData_1_1_robIdx_flag <= io_fromOg1VfArith_1_1_bits_robIdx_flag;
      s2_toExuData_1_1_robIdx_value <= io_fromOg1VfArith_1_1_bits_robIdx_value;
      s2_toExuData_1_1_pdest <= io_fromOg1VfArith_1_1_bits_pdest;
      s2_toExuData_1_1_fpWen <= io_fromOg1VfArith_1_1_bits_fpWen;
      s2_toExuData_1_1_vecWen <= io_fromOg1VfArith_1_1_bits_vecWen;
      s2_toExuData_1_1_v0Wen <= io_fromOg1VfArith_1_1_bits_v0Wen;
      s2_toExuData_1_1_fpu_wflags <= io_fromOg1VfArith_1_1_bits_fpu_wflags;
      s2_toExuData_1_1_vpu_vma <= io_fromOg1VfArith_1_1_bits_vpu_vma;
      s2_toExuData_1_1_vpu_vta <= io_fromOg1VfArith_1_1_bits_vpu_vta;
      s2_toExuData_1_1_vpu_vsew <= io_fromOg1VfArith_1_1_bits_vpu_vsew;
      s2_toExuData_1_1_vpu_vlmul <= io_fromOg1VfArith_1_1_bits_vpu_vlmul;
      s2_toExuData_1_1_vpu_vm <= io_fromOg1VfArith_1_1_bits_vpu_vm;
      s2_toExuData_1_1_vpu_vstart <= io_fromOg1VfArith_1_1_bits_vpu_vstart;
      s2_toExuData_1_1_vpu_fpu_isFoldTo1_2 <= io_fromOg1VfArith_1_1_bits_vpu_fpu_isFoldTo1_2;
      s2_toExuData_1_1_vpu_fpu_isFoldTo1_4 <= io_fromOg1VfArith_1_1_bits_vpu_fpu_isFoldTo1_4;
      s2_toExuData_1_1_vpu_fpu_isFoldTo1_8 <= io_fromOg1VfArith_1_1_bits_vpu_fpu_isFoldTo1_8;
      s2_toExuData_1_1_vpu_vuopIdx <= io_fromOg1VfArith_1_1_bits_vpu_vuopIdx;
      s2_toExuData_1_1_vpu_lastUop <= io_fromOg1VfArith_1_1_bits_vpu_lastUop;
      s2_toExuData_1_1_vpu_isNarrow <= io_fromOg1VfArith_1_1_bits_vpu_isNarrow;
      s2_toExuData_1_1_vpu_isDstMask <= io_fromOg1VfArith_1_1_bits_vpu_isDstMask;
      s2_toExuData_1_1_dataSources_0_value <= io_fromOg1VfArith_1_1_bits_dataSources_0_value;
      s2_toExuData_1_1_dataSources_1_value <= io_fromOg1VfArith_1_1_bits_dataSources_1_value;
      s2_toExuData_1_1_dataSources_2_value <= io_fromOg1VfArith_1_1_bits_dataSources_2_value;
      s2_toExuData_1_1_dataSources_3_value <= io_fromOg1VfArith_1_1_bits_dataSources_3_value;
      s2_toExuData_1_1_dataSources_4_value <= io_fromOg1VfArith_1_1_bits_dataSources_4_value;
      s2_toExuData_1_1_perfDebugInfo_enqRsTime <= io_fromOg1VfArith_1_1_bits_perfDebugInfo_enqRsTime;
      s2_toExuData_1_1_perfDebugInfo_selectTime <= io_fromOg1VfArith_1_1_bits_perfDebugInfo_selectTime;
      s2_toExuData_1_1_perfDebugInfo_issueTime <= io_fromOg1VfArith_1_1_bits_perfDebugInfo_issueTime;
    end
    if (fire_2_0) begin
      s2_toExuData_2_0_fuType <= io_fromOg1VfArith_2_0_bits_fuType;
      s2_toExuData_2_0_fuOpType <= io_fromOg1VfArith_2_0_bits_fuOpType;
      s2_toExuData_2_0_src_0 <= io_fromOg1VfArith_2_0_bits_src_0;
      s2_toExuData_2_0_src_1 <= io_fromOg1VfArith_2_0_bits_src_1;
      s2_toExuData_2_0_src_2 <= io_fromOg1VfArith_2_0_bits_src_2;
      s2_toExuData_2_0_src_3 <= io_fromOg1VfArith_2_0_bits_src_3;
      s2_toExuData_2_0_src_4 <= io_fromOg1VfArith_2_0_bits_src_4;
      s2_toExuData_2_0_robIdx_flag <= io_fromOg1VfArith_2_0_bits_robIdx_flag;
      s2_toExuData_2_0_robIdx_value <= io_fromOg1VfArith_2_0_bits_robIdx_value;
      s2_toExuData_2_0_pdest <= io_fromOg1VfArith_2_0_bits_pdest;
      s2_toExuData_2_0_vecWen <= io_fromOg1VfArith_2_0_bits_vecWen;
      s2_toExuData_2_0_v0Wen <= io_fromOg1VfArith_2_0_bits_v0Wen;
      s2_toExuData_2_0_fpu_wflags <= io_fromOg1VfArith_2_0_bits_fpu_wflags;
      s2_toExuData_2_0_vpu_vma <= io_fromOg1VfArith_2_0_bits_vpu_vma;
      s2_toExuData_2_0_vpu_vta <= io_fromOg1VfArith_2_0_bits_vpu_vta;
      s2_toExuData_2_0_vpu_vsew <= io_fromOg1VfArith_2_0_bits_vpu_vsew;
      s2_toExuData_2_0_vpu_vlmul <= io_fromOg1VfArith_2_0_bits_vpu_vlmul;
      s2_toExuData_2_0_vpu_vm <= io_fromOg1VfArith_2_0_bits_vpu_vm;
      s2_toExuData_2_0_vpu_vstart <= io_fromOg1VfArith_2_0_bits_vpu_vstart;
      s2_toExuData_2_0_vpu_vuopIdx <= io_fromOg1VfArith_2_0_bits_vpu_vuopIdx;
      s2_toExuData_2_0_vpu_isExt <= io_fromOg1VfArith_2_0_bits_vpu_isExt;
      s2_toExuData_2_0_vpu_isNarrow <= io_fromOg1VfArith_2_0_bits_vpu_isNarrow;
      s2_toExuData_2_0_vpu_isDstMask <= io_fromOg1VfArith_2_0_bits_vpu_isDstMask;
      s2_toExuData_2_0_vpu_isOpMask <= io_fromOg1VfArith_2_0_bits_vpu_isOpMask;
      s2_toExuData_2_0_dataSources_0_value <= io_fromOg1VfArith_2_0_bits_dataSources_0_value;
      s2_toExuData_2_0_dataSources_1_value <= io_fromOg1VfArith_2_0_bits_dataSources_1_value;
      s2_toExuData_2_0_dataSources_2_value <= io_fromOg1VfArith_2_0_bits_dataSources_2_value;
      s2_toExuData_2_0_dataSources_3_value <= io_fromOg1VfArith_2_0_bits_dataSources_3_value;
      s2_toExuData_2_0_dataSources_4_value <= io_fromOg1VfArith_2_0_bits_dataSources_4_value;
      s2_toExuData_2_0_perfDebugInfo_enqRsTime <= io_fromOg1VfArith_2_0_bits_perfDebugInfo_enqRsTime;
      s2_toExuData_2_0_perfDebugInfo_selectTime <= io_fromOg1VfArith_2_0_bits_perfDebugInfo_selectTime;
      s2_toExuData_2_0_perfDebugInfo_issueTime <= io_fromOg1VfArith_2_0_bits_perfDebugInfo_issueTime;
    end
    if (fire_3_0) begin
      s2_toExuData_3_0_fuType <= io_fromOg1VecMem_0_0_bits_fuType;
      s2_toExuData_3_0_fuOpType <= io_fromOg1VecMem_0_0_bits_fuOpType;
      s2_toExuData_3_0_src_0 <= io_fromOg1VecMem_0_0_bits_src_0;
      s2_toExuData_3_0_src_1 <= io_fromOg1VecMem_0_0_bits_src_1;
      s2_toExuData_3_0_src_2 <= io_fromOg1VecMem_0_0_bits_src_2;
      s2_toExuData_3_0_src_3 <= io_fromOg1VecMem_0_0_bits_src_3;
      s2_toExuData_3_0_src_4 <= io_fromOg1VecMem_0_0_bits_src_4;
      s2_toExuData_3_0_robIdx_flag <= io_fromOg1VecMem_0_0_bits_robIdx_flag;
      s2_toExuData_3_0_robIdx_value <= io_fromOg1VecMem_0_0_bits_robIdx_value;
      s2_toExuData_3_0_pdest <= io_fromOg1VecMem_0_0_bits_pdest;
      s2_toExuData_3_0_vecWen <= io_fromOg1VecMem_0_0_bits_vecWen;
      s2_toExuData_3_0_v0Wen <= io_fromOg1VecMem_0_0_bits_v0Wen;
      s2_toExuData_3_0_vlWen <= io_fromOg1VecMem_0_0_bits_vlWen;
      s2_toExuData_3_0_vpu_vma <= io_fromOg1VecMem_0_0_bits_vpu_vma;
      s2_toExuData_3_0_vpu_vta <= io_fromOg1VecMem_0_0_bits_vpu_vta;
      s2_toExuData_3_0_vpu_vsew <= io_fromOg1VecMem_0_0_bits_vpu_vsew;
      s2_toExuData_3_0_vpu_vlmul <= io_fromOg1VecMem_0_0_bits_vpu_vlmul;
      s2_toExuData_3_0_vpu_vm <= io_fromOg1VecMem_0_0_bits_vpu_vm;
      s2_toExuData_3_0_vpu_vstart <= io_fromOg1VecMem_0_0_bits_vpu_vstart;
      s2_toExuData_3_0_vpu_vuopIdx <= io_fromOg1VecMem_0_0_bits_vpu_vuopIdx;
      s2_toExuData_3_0_vpu_lastUop <= io_fromOg1VecMem_0_0_bits_vpu_lastUop;
      s2_toExuData_3_0_vpu_vmask <= io_fromOg1VecMem_0_0_bits_vpu_vmask;
      s2_toExuData_3_0_vpu_nf <= io_fromOg1VecMem_0_0_bits_vpu_nf;
      s2_toExuData_3_0_vpu_veew <= io_fromOg1VecMem_0_0_bits_vpu_veew;
      s2_toExuData_3_0_vpu_isVleff <= io_fromOg1VecMem_0_0_bits_vpu_isVleff;
      s2_toExuData_3_0_ftqIdx_flag <= io_fromOg1VecMem_0_0_bits_ftqIdx_flag;
      s2_toExuData_3_0_ftqIdx_value <= io_fromOg1VecMem_0_0_bits_ftqIdx_value;
      s2_toExuData_3_0_ftqOffset <= io_fromOg1VecMem_0_0_bits_ftqOffset;
      s2_toExuData_3_0_numLsElem <= io_fromOg1VecMem_0_0_bits_numLsElem;
      s2_toExuData_3_0_sqIdx_flag <= io_fromOg1VecMem_0_0_bits_sqIdx_flag;
      s2_toExuData_3_0_sqIdx_value <= io_fromOg1VecMem_0_0_bits_sqIdx_value;
      s2_toExuData_3_0_lqIdx_flag <= io_fromOg1VecMem_0_0_bits_lqIdx_flag;
      s2_toExuData_3_0_lqIdx_value <= io_fromOg1VecMem_0_0_bits_lqIdx_value;
      s2_toExuData_3_0_dataSources_0_value <= io_fromOg1VecMem_0_0_bits_dataSources_0_value;
      s2_toExuData_3_0_dataSources_1_value <= io_fromOg1VecMem_0_0_bits_dataSources_1_value;
      s2_toExuData_3_0_dataSources_2_value <= io_fromOg1VecMem_0_0_bits_dataSources_2_value;
      s2_toExuData_3_0_dataSources_3_value <= io_fromOg1VecMem_0_0_bits_dataSources_3_value;
      s2_toExuData_3_0_dataSources_4_value <= io_fromOg1VecMem_0_0_bits_dataSources_4_value;
      s2_toExuData_3_0_perfDebugInfo_enqRsTime <= io_fromOg1VecMem_0_0_bits_perfDebugInfo_enqRsTime;
      s2_toExuData_3_0_perfDebugInfo_selectTime <= io_fromOg1VecMem_0_0_bits_perfDebugInfo_selectTime;
      s2_toExuData_3_0_perfDebugInfo_issueTime <= io_fromOg1VecMem_0_0_bits_perfDebugInfo_issueTime;
    end
    if (fire_4_0) begin
      s2_toExuData_4_0_fuType <= io_fromOg1VecMem_1_0_bits_fuType;
      s2_toExuData_4_0_fuOpType <= io_fromOg1VecMem_1_0_bits_fuOpType;
      s2_toExuData_4_0_src_0 <= io_fromOg1VecMem_1_0_bits_src_0;
      s2_toExuData_4_0_src_1 <= io_fromOg1VecMem_1_0_bits_src_1;
      s2_toExuData_4_0_src_2 <= io_fromOg1VecMem_1_0_bits_src_2;
      s2_toExuData_4_0_src_3 <= io_fromOg1VecMem_1_0_bits_src_3;
      s2_toExuData_4_0_src_4 <= io_fromOg1VecMem_1_0_bits_src_4;
      s2_toExuData_4_0_robIdx_flag <= io_fromOg1VecMem_1_0_bits_robIdx_flag;
      s2_toExuData_4_0_robIdx_value <= io_fromOg1VecMem_1_0_bits_robIdx_value;
      s2_toExuData_4_0_pdest <= io_fromOg1VecMem_1_0_bits_pdest;
      s2_toExuData_4_0_vecWen <= io_fromOg1VecMem_1_0_bits_vecWen;
      s2_toExuData_4_0_v0Wen <= io_fromOg1VecMem_1_0_bits_v0Wen;
      s2_toExuData_4_0_vlWen <= io_fromOg1VecMem_1_0_bits_vlWen;
      s2_toExuData_4_0_vpu_vma <= io_fromOg1VecMem_1_0_bits_vpu_vma;
      s2_toExuData_4_0_vpu_vta <= io_fromOg1VecMem_1_0_bits_vpu_vta;
      s2_toExuData_4_0_vpu_vsew <= io_fromOg1VecMem_1_0_bits_vpu_vsew;
      s2_toExuData_4_0_vpu_vlmul <= io_fromOg1VecMem_1_0_bits_vpu_vlmul;
      s2_toExuData_4_0_vpu_vm <= io_fromOg1VecMem_1_0_bits_vpu_vm;
      s2_toExuData_4_0_vpu_vstart <= io_fromOg1VecMem_1_0_bits_vpu_vstart;
      s2_toExuData_4_0_vpu_vuopIdx <= io_fromOg1VecMem_1_0_bits_vpu_vuopIdx;
      s2_toExuData_4_0_vpu_lastUop <= io_fromOg1VecMem_1_0_bits_vpu_lastUop;
      s2_toExuData_4_0_vpu_vmask <= io_fromOg1VecMem_1_0_bits_vpu_vmask;
      s2_toExuData_4_0_vpu_nf <= io_fromOg1VecMem_1_0_bits_vpu_nf;
      s2_toExuData_4_0_vpu_veew <= io_fromOg1VecMem_1_0_bits_vpu_veew;
      s2_toExuData_4_0_vpu_isVleff <= io_fromOg1VecMem_1_0_bits_vpu_isVleff;
      s2_toExuData_4_0_ftqIdx_flag <= io_fromOg1VecMem_1_0_bits_ftqIdx_flag;
      s2_toExuData_4_0_ftqIdx_value <= io_fromOg1VecMem_1_0_bits_ftqIdx_value;
      s2_toExuData_4_0_ftqOffset <= io_fromOg1VecMem_1_0_bits_ftqOffset;
      s2_toExuData_4_0_numLsElem <= io_fromOg1VecMem_1_0_bits_numLsElem;
      s2_toExuData_4_0_sqIdx_flag <= io_fromOg1VecMem_1_0_bits_sqIdx_flag;
      s2_toExuData_4_0_sqIdx_value <= io_fromOg1VecMem_1_0_bits_sqIdx_value;
      s2_toExuData_4_0_lqIdx_flag <= io_fromOg1VecMem_1_0_bits_lqIdx_flag;
      s2_toExuData_4_0_lqIdx_value <= io_fromOg1VecMem_1_0_bits_lqIdx_value;
      s2_toExuData_4_0_dataSources_0_value <= io_fromOg1VecMem_1_0_bits_dataSources_0_value;
      s2_toExuData_4_0_dataSources_1_value <= io_fromOg1VecMem_1_0_bits_dataSources_1_value;
      s2_toExuData_4_0_dataSources_2_value <= io_fromOg1VecMem_1_0_bits_dataSources_2_value;
      s2_toExuData_4_0_dataSources_3_value <= io_fromOg1VecMem_1_0_bits_dataSources_3_value;
      s2_toExuData_4_0_dataSources_4_value <= io_fromOg1VecMem_1_0_bits_dataSources_4_value;
      s2_toExuData_4_0_perfDebugInfo_enqRsTime <= io_fromOg1VecMem_1_0_bits_perfDebugInfo_enqRsTime;
      s2_toExuData_4_0_perfDebugInfo_selectTime <= io_fromOg1VecMem_1_0_bits_perfDebugInfo_selectTime;
      s2_toExuData_4_0_perfDebugInfo_issueTime <= io_fromOg1VecMem_1_0_bits_perfDebugInfo_issueTime;
    end

    // flush 信息延迟一拍副本 (s2_flush := RegNext(io.flush) 的 bits 部分)。
    if (io_flush_valid) begin
      s2_flush_next_bits_r_robIdx_flag  <= io_flush_bits_robIdx_flag;
      s2_flush_next_bits_r_robIdx_value <= io_flush_bits_robIdx_value;
      s2_flush_next_bits_r_level        <= io_flush_bits_level;
      s2_flush_next_bits_r_1_robIdx_flag  <= io_flush_bits_robIdx_flag;
      s2_flush_next_bits_r_1_robIdx_value <= io_flush_bits_robIdx_value;
      s2_flush_next_bits_r_1_level        <= io_flush_bits_level;
      s2_flush_next_bits_r_2_robIdx_flag  <= io_flush_bits_robIdx_flag;
      s2_flush_next_bits_r_2_robIdx_value <= io_flush_bits_robIdx_value;
      s2_flush_next_bits_r_2_level        <= io_flush_bits_level;
      s2_flush_next_bits_r_3_robIdx_flag  <= io_flush_bits_robIdx_flag;
      s2_flush_next_bits_r_3_robIdx_value <= io_flush_bits_robIdx_value;
      s2_flush_next_bits_r_3_level        <= io_flush_bits_level;
      s2_flush_next_bits_r_4_robIdx_flag  <= io_flush_bits_robIdx_flag;
      s2_flush_next_bits_r_4_robIdx_value <= io_flush_bits_robIdx_value;
      s2_flush_next_bits_r_4_level        <= io_flush_bits_level;
      s2_flush_next_bits_r_5_robIdx_flag  <= io_flush_bits_robIdx_flag;
      s2_flush_next_bits_r_5_robIdx_value <= io_flush_bits_robIdx_value;
      s2_flush_next_bits_r_5_level        <= io_flush_bits_level;
      s2_flush_next_bits_r_6_robIdx_flag  <= io_flush_bits_robIdx_flag;
      s2_flush_next_bits_r_6_robIdx_value <= io_flush_bits_robIdx_value;
      s2_flush_next_bits_r_6_level        <= io_flush_bits_level;
    end

    // 立即数随 VfArith(0_1) 一并打拍 (io.fromOg1ImmInfo(1))。
    if (io_fromOg1VfArith_0_1_valid) begin
      r_1_imm     <= io_fromOg1ImmInfo_1_imm;
      r_1_immType <= io_fromOg1ImmInfo_1_immType;
    end
  end

  // flush valid 延迟一拍 (复位清零)。
  always @(posedge clock or posedge reset) begin
    if (reset) begin
      s2_flush_next_valid_last_REG <= 1'h0;
      s2_flush_next_valid_last_REG_1 <= 1'h0;
      s2_flush_next_valid_last_REG_2 <= 1'h0;
      s2_flush_next_valid_last_REG_3 <= 1'h0;
      s2_flush_next_valid_last_REG_4 <= 1'h0;
      s2_flush_next_valid_last_REG_5 <= 1'h0;
      s2_flush_next_valid_last_REG_6 <= 1'h0;
    end
    else begin
      s2_flush_next_valid_last_REG <= io_flush_valid;
      s2_flush_next_valid_last_REG_1 <= io_flush_valid;
      s2_flush_next_valid_last_REG_2 <= io_flush_valid;
      s2_flush_next_valid_last_REG_3 <= io_flush_valid;
      s2_flush_next_valid_last_REG_4 <= io_flush_valid;
      s2_flush_next_valid_last_REG_5 <= io_flush_valid;
      s2_flush_next_valid_last_REG_6 <= io_flush_valid;
    end
  end

  // ---- 输出连线 (寄存器直读 + Og2Resp 应答) ----
  assign io_toVfArithExu_2_0_valid = s2_toExuValid_2_0;
  assign io_toVfArithExu_2_0_bits_fuType = s2_toExuData_2_0_fuType;
  assign io_toVfArithExu_2_0_bits_fuOpType = s2_toExuData_2_0_fuOpType;
  assign io_toVfArithExu_2_0_bits_src_0 = s2_toExuData_2_0_src_0;
  assign io_toVfArithExu_2_0_bits_src_1 = s2_toExuData_2_0_src_1;
  assign io_toVfArithExu_2_0_bits_src_2 = s2_toExuData_2_0_src_2;
  assign io_toVfArithExu_2_0_bits_src_3 = s2_toExuData_2_0_src_3;
  assign io_toVfArithExu_2_0_bits_src_4 = s2_toExuData_2_0_src_4;
  assign io_toVfArithExu_2_0_bits_robIdx_flag = s2_toExuData_2_0_robIdx_flag;
  assign io_toVfArithExu_2_0_bits_robIdx_value = s2_toExuData_2_0_robIdx_value;
  assign io_toVfArithExu_2_0_bits_pdest = s2_toExuData_2_0_pdest;
  assign io_toVfArithExu_2_0_bits_vecWen = s2_toExuData_2_0_vecWen;
  assign io_toVfArithExu_2_0_bits_v0Wen = s2_toExuData_2_0_v0Wen;
  assign io_toVfArithExu_2_0_bits_fpu_wflags = s2_toExuData_2_0_fpu_wflags;
  assign io_toVfArithExu_2_0_bits_vpu_vma = s2_toExuData_2_0_vpu_vma;
  assign io_toVfArithExu_2_0_bits_vpu_vta = s2_toExuData_2_0_vpu_vta;
  assign io_toVfArithExu_2_0_bits_vpu_vsew = s2_toExuData_2_0_vpu_vsew;
  assign io_toVfArithExu_2_0_bits_vpu_vlmul = s2_toExuData_2_0_vpu_vlmul;
  assign io_toVfArithExu_2_0_bits_vpu_vm = s2_toExuData_2_0_vpu_vm;
  assign io_toVfArithExu_2_0_bits_vpu_vstart = s2_toExuData_2_0_vpu_vstart;
  assign io_toVfArithExu_2_0_bits_vpu_vuopIdx = s2_toExuData_2_0_vpu_vuopIdx;
  assign io_toVfArithExu_2_0_bits_vpu_isExt = s2_toExuData_2_0_vpu_isExt;
  assign io_toVfArithExu_2_0_bits_vpu_isNarrow = s2_toExuData_2_0_vpu_isNarrow;
  assign io_toVfArithExu_2_0_bits_vpu_isDstMask = s2_toExuData_2_0_vpu_isDstMask;
  assign io_toVfArithExu_2_0_bits_vpu_isOpMask = s2_toExuData_2_0_vpu_isOpMask;
  assign io_toVfArithExu_2_0_bits_dataSources_0_value = s2_toExuData_2_0_dataSources_0_value;
  assign io_toVfArithExu_2_0_bits_dataSources_1_value = s2_toExuData_2_0_dataSources_1_value;
  assign io_toVfArithExu_2_0_bits_dataSources_2_value = s2_toExuData_2_0_dataSources_2_value;
  assign io_toVfArithExu_2_0_bits_dataSources_3_value = s2_toExuData_2_0_dataSources_3_value;
  assign io_toVfArithExu_2_0_bits_dataSources_4_value = s2_toExuData_2_0_dataSources_4_value;
  assign io_toVfArithExu_2_0_bits_perfDebugInfo_enqRsTime = s2_toExuData_2_0_perfDebugInfo_enqRsTime;
  assign io_toVfArithExu_2_0_bits_perfDebugInfo_selectTime = s2_toExuData_2_0_perfDebugInfo_selectTime;
  assign io_toVfArithExu_2_0_bits_perfDebugInfo_issueTime = s2_toExuData_2_0_perfDebugInfo_issueTime;
  assign io_toVfArithExu_1_1_valid = s2_toExuValid_1_1;
  assign io_toVfArithExu_1_1_bits_fuType = s2_toExuData_1_1_fuType;
  assign io_toVfArithExu_1_1_bits_fuOpType = s2_toExuData_1_1_fuOpType;
  assign io_toVfArithExu_1_1_bits_src_0 = s2_toExuData_1_1_src_0;
  assign io_toVfArithExu_1_1_bits_src_1 = s2_toExuData_1_1_src_1;
  assign io_toVfArithExu_1_1_bits_src_2 = s2_toExuData_1_1_src_2;
  assign io_toVfArithExu_1_1_bits_src_3 = s2_toExuData_1_1_src_3;
  assign io_toVfArithExu_1_1_bits_src_4 = s2_toExuData_1_1_src_4;
  assign io_toVfArithExu_1_1_bits_robIdx_flag = s2_toExuData_1_1_robIdx_flag;
  assign io_toVfArithExu_1_1_bits_robIdx_value = s2_toExuData_1_1_robIdx_value;
  assign io_toVfArithExu_1_1_bits_pdest = s2_toExuData_1_1_pdest;
  assign io_toVfArithExu_1_1_bits_fpWen = s2_toExuData_1_1_fpWen;
  assign io_toVfArithExu_1_1_bits_vecWen = s2_toExuData_1_1_vecWen;
  assign io_toVfArithExu_1_1_bits_v0Wen = s2_toExuData_1_1_v0Wen;
  assign io_toVfArithExu_1_1_bits_fpu_wflags = s2_toExuData_1_1_fpu_wflags;
  assign io_toVfArithExu_1_1_bits_vpu_vma = s2_toExuData_1_1_vpu_vma;
  assign io_toVfArithExu_1_1_bits_vpu_vta = s2_toExuData_1_1_vpu_vta;
  assign io_toVfArithExu_1_1_bits_vpu_vsew = s2_toExuData_1_1_vpu_vsew;
  assign io_toVfArithExu_1_1_bits_vpu_vlmul = s2_toExuData_1_1_vpu_vlmul;
  assign io_toVfArithExu_1_1_bits_vpu_vm = s2_toExuData_1_1_vpu_vm;
  assign io_toVfArithExu_1_1_bits_vpu_vstart = s2_toExuData_1_1_vpu_vstart;
  assign io_toVfArithExu_1_1_bits_vpu_fpu_isFoldTo1_2 = s2_toExuData_1_1_vpu_fpu_isFoldTo1_2;
  assign io_toVfArithExu_1_1_bits_vpu_fpu_isFoldTo1_4 = s2_toExuData_1_1_vpu_fpu_isFoldTo1_4;
  assign io_toVfArithExu_1_1_bits_vpu_fpu_isFoldTo1_8 = s2_toExuData_1_1_vpu_fpu_isFoldTo1_8;
  assign io_toVfArithExu_1_1_bits_vpu_vuopIdx = s2_toExuData_1_1_vpu_vuopIdx;
  assign io_toVfArithExu_1_1_bits_vpu_lastUop = s2_toExuData_1_1_vpu_lastUop;
  assign io_toVfArithExu_1_1_bits_vpu_isNarrow = s2_toExuData_1_1_vpu_isNarrow;
  assign io_toVfArithExu_1_1_bits_vpu_isDstMask = s2_toExuData_1_1_vpu_isDstMask;
  assign io_toVfArithExu_1_1_bits_dataSources_0_value = s2_toExuData_1_1_dataSources_0_value;
  assign io_toVfArithExu_1_1_bits_dataSources_1_value = s2_toExuData_1_1_dataSources_1_value;
  assign io_toVfArithExu_1_1_bits_dataSources_2_value = s2_toExuData_1_1_dataSources_2_value;
  assign io_toVfArithExu_1_1_bits_dataSources_3_value = s2_toExuData_1_1_dataSources_3_value;
  assign io_toVfArithExu_1_1_bits_dataSources_4_value = s2_toExuData_1_1_dataSources_4_value;
  assign io_toVfArithExu_1_1_bits_perfDebugInfo_enqRsTime = s2_toExuData_1_1_perfDebugInfo_enqRsTime;
  assign io_toVfArithExu_1_1_bits_perfDebugInfo_selectTime = s2_toExuData_1_1_perfDebugInfo_selectTime;
  assign io_toVfArithExu_1_1_bits_perfDebugInfo_issueTime = s2_toExuData_1_1_perfDebugInfo_issueTime;
  assign io_toVfArithExu_1_0_valid = s2_toExuValid_1_0;
  assign io_toVfArithExu_1_0_bits_fuType = s2_toExuData_1_0_fuType;
  assign io_toVfArithExu_1_0_bits_fuOpType = s2_toExuData_1_0_fuOpType;
  assign io_toVfArithExu_1_0_bits_src_0 = s2_toExuData_1_0_src_0;
  assign io_toVfArithExu_1_0_bits_src_1 = s2_toExuData_1_0_src_1;
  assign io_toVfArithExu_1_0_bits_src_2 = s2_toExuData_1_0_src_2;
  assign io_toVfArithExu_1_0_bits_src_3 = s2_toExuData_1_0_src_3;
  assign io_toVfArithExu_1_0_bits_src_4 = s2_toExuData_1_0_src_4;
  assign io_toVfArithExu_1_0_bits_robIdx_flag = s2_toExuData_1_0_robIdx_flag;
  assign io_toVfArithExu_1_0_bits_robIdx_value = s2_toExuData_1_0_robIdx_value;
  assign io_toVfArithExu_1_0_bits_pdest = s2_toExuData_1_0_pdest;
  assign io_toVfArithExu_1_0_bits_vecWen = s2_toExuData_1_0_vecWen;
  assign io_toVfArithExu_1_0_bits_v0Wen = s2_toExuData_1_0_v0Wen;
  assign io_toVfArithExu_1_0_bits_fpu_wflags = s2_toExuData_1_0_fpu_wflags;
  assign io_toVfArithExu_1_0_bits_vpu_vma = s2_toExuData_1_0_vpu_vma;
  assign io_toVfArithExu_1_0_bits_vpu_vta = s2_toExuData_1_0_vpu_vta;
  assign io_toVfArithExu_1_0_bits_vpu_vsew = s2_toExuData_1_0_vpu_vsew;
  assign io_toVfArithExu_1_0_bits_vpu_vlmul = s2_toExuData_1_0_vpu_vlmul;
  assign io_toVfArithExu_1_0_bits_vpu_vm = s2_toExuData_1_0_vpu_vm;
  assign io_toVfArithExu_1_0_bits_vpu_vstart = s2_toExuData_1_0_vpu_vstart;
  assign io_toVfArithExu_1_0_bits_vpu_vuopIdx = s2_toExuData_1_0_vpu_vuopIdx;
  assign io_toVfArithExu_1_0_bits_vpu_isExt = s2_toExuData_1_0_vpu_isExt;
  assign io_toVfArithExu_1_0_bits_vpu_isNarrow = s2_toExuData_1_0_vpu_isNarrow;
  assign io_toVfArithExu_1_0_bits_vpu_isDstMask = s2_toExuData_1_0_vpu_isDstMask;
  assign io_toVfArithExu_1_0_bits_vpu_isOpMask = s2_toExuData_1_0_vpu_isOpMask;
  assign io_toVfArithExu_1_0_bits_dataSources_0_value = s2_toExuData_1_0_dataSources_0_value;
  assign io_toVfArithExu_1_0_bits_dataSources_1_value = s2_toExuData_1_0_dataSources_1_value;
  assign io_toVfArithExu_1_0_bits_dataSources_2_value = s2_toExuData_1_0_dataSources_2_value;
  assign io_toVfArithExu_1_0_bits_dataSources_3_value = s2_toExuData_1_0_dataSources_3_value;
  assign io_toVfArithExu_1_0_bits_dataSources_4_value = s2_toExuData_1_0_dataSources_4_value;
  assign io_toVfArithExu_1_0_bits_perfDebugInfo_enqRsTime = s2_toExuData_1_0_perfDebugInfo_enqRsTime;
  assign io_toVfArithExu_1_0_bits_perfDebugInfo_selectTime = s2_toExuData_1_0_perfDebugInfo_selectTime;
  assign io_toVfArithExu_1_0_bits_perfDebugInfo_issueTime = s2_toExuData_1_0_perfDebugInfo_issueTime;
  assign io_toVfArithExu_0_1_valid = s2_toExuValid_0_1;
  assign io_toVfArithExu_0_1_bits_fuType = s2_toExuData_0_1_fuType;
  assign io_toVfArithExu_0_1_bits_fuOpType = s2_toExuData_0_1_fuOpType;
  assign io_toVfArithExu_0_1_bits_src_0 = s2_toExuData_0_1_src_0;
  assign io_toVfArithExu_0_1_bits_src_1 = s2_toExuData_0_1_src_1;
  assign io_toVfArithExu_0_1_bits_src_2 = s2_toExuData_0_1_src_2;
  assign io_toVfArithExu_0_1_bits_src_3 = s2_toExuData_0_1_src_3;
  assign io_toVfArithExu_0_1_bits_src_4 = s2_toExuData_0_1_src_4;
  assign io_toVfArithExu_0_1_bits_robIdx_flag = s2_toExuData_0_1_robIdx_flag;
  assign io_toVfArithExu_0_1_bits_robIdx_value = s2_toExuData_0_1_robIdx_value;
  assign io_toVfArithExu_0_1_bits_pdest = s2_toExuData_0_1_pdest;
  assign io_toVfArithExu_0_1_bits_rfWen = s2_toExuData_0_1_rfWen;
  assign io_toVfArithExu_0_1_bits_fpWen = s2_toExuData_0_1_fpWen;
  assign io_toVfArithExu_0_1_bits_vecWen = s2_toExuData_0_1_vecWen;
  assign io_toVfArithExu_0_1_bits_v0Wen = s2_toExuData_0_1_v0Wen;
  assign io_toVfArithExu_0_1_bits_vlWen = s2_toExuData_0_1_vlWen;
  assign io_toVfArithExu_0_1_bits_fpu_wflags = s2_toExuData_0_1_fpu_wflags;
  assign io_toVfArithExu_0_1_bits_vpu_vma = s2_toExuData_0_1_vpu_vma;
  assign io_toVfArithExu_0_1_bits_vpu_vta = s2_toExuData_0_1_vpu_vta;
  assign io_toVfArithExu_0_1_bits_vpu_vsew = s2_toExuData_0_1_vpu_vsew;
  assign io_toVfArithExu_0_1_bits_vpu_vlmul = s2_toExuData_0_1_vpu_vlmul;
  assign io_toVfArithExu_0_1_bits_vpu_vm = s2_toExuData_0_1_vpu_vm;
  assign io_toVfArithExu_0_1_bits_vpu_vstart = s2_toExuData_0_1_vpu_vstart;
  assign io_toVfArithExu_0_1_bits_vpu_fpu_isFoldTo1_2 = s2_toExuData_0_1_vpu_fpu_isFoldTo1_2;
  assign io_toVfArithExu_0_1_bits_vpu_fpu_isFoldTo1_4 = s2_toExuData_0_1_vpu_fpu_isFoldTo1_4;
  assign io_toVfArithExu_0_1_bits_vpu_fpu_isFoldTo1_8 = s2_toExuData_0_1_vpu_fpu_isFoldTo1_8;
  assign io_toVfArithExu_0_1_bits_vpu_vuopIdx = s2_toExuData_0_1_vpu_vuopIdx;
  assign io_toVfArithExu_0_1_bits_vpu_lastUop = s2_toExuData_0_1_vpu_lastUop;
  assign io_toVfArithExu_0_1_bits_vpu_isNarrow = s2_toExuData_0_1_vpu_isNarrow;
  assign io_toVfArithExu_0_1_bits_vpu_isDstMask = s2_toExuData_0_1_vpu_isDstMask;
  assign io_toVfArithExu_0_1_bits_dataSources_0_value = s2_toExuData_0_1_dataSources_0_value;
  assign io_toVfArithExu_0_1_bits_dataSources_1_value = s2_toExuData_0_1_dataSources_1_value;
  assign io_toVfArithExu_0_1_bits_dataSources_2_value = s2_toExuData_0_1_dataSources_2_value;
  assign io_toVfArithExu_0_1_bits_dataSources_3_value = s2_toExuData_0_1_dataSources_3_value;
  assign io_toVfArithExu_0_1_bits_dataSources_4_value = s2_toExuData_0_1_dataSources_4_value;
  assign io_toVfArithExu_0_1_bits_perfDebugInfo_enqRsTime = s2_toExuData_0_1_perfDebugInfo_enqRsTime;
  assign io_toVfArithExu_0_1_bits_perfDebugInfo_selectTime = s2_toExuData_0_1_perfDebugInfo_selectTime;
  assign io_toVfArithExu_0_1_bits_perfDebugInfo_issueTime = s2_toExuData_0_1_perfDebugInfo_issueTime;
  assign io_toVfArithExu_0_0_valid = s2_toExuValid_0_0;
  assign io_toVfArithExu_0_0_bits_fuType = s2_toExuData_0_0_fuType;
  assign io_toVfArithExu_0_0_bits_fuOpType = s2_toExuData_0_0_fuOpType;
  assign io_toVfArithExu_0_0_bits_src_0 = s2_toExuData_0_0_src_0;
  assign io_toVfArithExu_0_0_bits_src_1 = s2_toExuData_0_0_src_1;
  assign io_toVfArithExu_0_0_bits_src_2 = s2_toExuData_0_0_src_2;
  assign io_toVfArithExu_0_0_bits_src_3 = s2_toExuData_0_0_src_3;
  assign io_toVfArithExu_0_0_bits_src_4 = s2_toExuData_0_0_src_4;
  assign io_toVfArithExu_0_0_bits_robIdx_flag = s2_toExuData_0_0_robIdx_flag;
  assign io_toVfArithExu_0_0_bits_robIdx_value = s2_toExuData_0_0_robIdx_value;
  assign io_toVfArithExu_0_0_bits_pdest = s2_toExuData_0_0_pdest;
  assign io_toVfArithExu_0_0_bits_vecWen = s2_toExuData_0_0_vecWen;
  assign io_toVfArithExu_0_0_bits_v0Wen = s2_toExuData_0_0_v0Wen;
  assign io_toVfArithExu_0_0_bits_fpu_wflags = s2_toExuData_0_0_fpu_wflags;
  assign io_toVfArithExu_0_0_bits_vpu_vma = s2_toExuData_0_0_vpu_vma;
  assign io_toVfArithExu_0_0_bits_vpu_vta = s2_toExuData_0_0_vpu_vta;
  assign io_toVfArithExu_0_0_bits_vpu_vsew = s2_toExuData_0_0_vpu_vsew;
  assign io_toVfArithExu_0_0_bits_vpu_vlmul = s2_toExuData_0_0_vpu_vlmul;
  assign io_toVfArithExu_0_0_bits_vpu_vm = s2_toExuData_0_0_vpu_vm;
  assign io_toVfArithExu_0_0_bits_vpu_vstart = s2_toExuData_0_0_vpu_vstart;
  assign io_toVfArithExu_0_0_bits_vpu_vuopIdx = s2_toExuData_0_0_vpu_vuopIdx;
  assign io_toVfArithExu_0_0_bits_vpu_isExt = s2_toExuData_0_0_vpu_isExt;
  assign io_toVfArithExu_0_0_bits_vpu_isNarrow = s2_toExuData_0_0_vpu_isNarrow;
  assign io_toVfArithExu_0_0_bits_vpu_isDstMask = s2_toExuData_0_0_vpu_isDstMask;
  assign io_toVfArithExu_0_0_bits_vpu_isOpMask = s2_toExuData_0_0_vpu_isOpMask;
  assign io_toVfArithExu_0_0_bits_dataSources_0_value = s2_toExuData_0_0_dataSources_0_value;
  assign io_toVfArithExu_0_0_bits_dataSources_1_value = s2_toExuData_0_0_dataSources_1_value;
  assign io_toVfArithExu_0_0_bits_dataSources_2_value = s2_toExuData_0_0_dataSources_2_value;
  assign io_toVfArithExu_0_0_bits_dataSources_3_value = s2_toExuData_0_0_dataSources_3_value;
  assign io_toVfArithExu_0_0_bits_dataSources_4_value = s2_toExuData_0_0_dataSources_4_value;
  assign io_toVfArithExu_0_0_bits_perfDebugInfo_enqRsTime = s2_toExuData_0_0_perfDebugInfo_enqRsTime;
  assign io_toVfArithExu_0_0_bits_perfDebugInfo_selectTime = s2_toExuData_0_0_perfDebugInfo_selectTime;
  assign io_toVfArithExu_0_0_bits_perfDebugInfo_issueTime = s2_toExuData_0_0_perfDebugInfo_issueTime;
  assign io_toVecMemExu_1_0_valid = s2_toExuValid_4_0;
  assign io_toVecMemExu_1_0_bits_fuType = s2_toExuData_4_0_fuType;
  assign io_toVecMemExu_1_0_bits_fuOpType = s2_toExuData_4_0_fuOpType;
  assign io_toVecMemExu_1_0_bits_src_0 = s2_toExuData_4_0_src_0;
  assign io_toVecMemExu_1_0_bits_src_1 = s2_toExuData_4_0_src_1;
  assign io_toVecMemExu_1_0_bits_src_2 = s2_toExuData_4_0_src_2;
  assign io_toVecMemExu_1_0_bits_src_3 = s2_toExuData_4_0_src_3;
  assign io_toVecMemExu_1_0_bits_src_4 = s2_toExuData_4_0_src_4;
  assign io_toVecMemExu_1_0_bits_robIdx_flag = s2_toExuData_4_0_robIdx_flag;
  assign io_toVecMemExu_1_0_bits_robIdx_value = s2_toExuData_4_0_robIdx_value;
  assign io_toVecMemExu_1_0_bits_pdest = s2_toExuData_4_0_pdest;
  assign io_toVecMemExu_1_0_bits_vecWen = s2_toExuData_4_0_vecWen;
  assign io_toVecMemExu_1_0_bits_v0Wen = s2_toExuData_4_0_v0Wen;
  assign io_toVecMemExu_1_0_bits_vlWen = s2_toExuData_4_0_vlWen;
  assign io_toVecMemExu_1_0_bits_vpu_vma = s2_toExuData_4_0_vpu_vma;
  assign io_toVecMemExu_1_0_bits_vpu_vta = s2_toExuData_4_0_vpu_vta;
  assign io_toVecMemExu_1_0_bits_vpu_vsew = s2_toExuData_4_0_vpu_vsew;
  assign io_toVecMemExu_1_0_bits_vpu_vlmul = s2_toExuData_4_0_vpu_vlmul;
  assign io_toVecMemExu_1_0_bits_vpu_vm = s2_toExuData_4_0_vpu_vm;
  assign io_toVecMemExu_1_0_bits_vpu_vstart = s2_toExuData_4_0_vpu_vstart;
  assign io_toVecMemExu_1_0_bits_vpu_vuopIdx = s2_toExuData_4_0_vpu_vuopIdx;
  assign io_toVecMemExu_1_0_bits_vpu_lastUop = s2_toExuData_4_0_vpu_lastUop;
  assign io_toVecMemExu_1_0_bits_vpu_vmask = s2_toExuData_4_0_vpu_vmask;
  assign io_toVecMemExu_1_0_bits_vpu_nf = s2_toExuData_4_0_vpu_nf;
  assign io_toVecMemExu_1_0_bits_vpu_veew = s2_toExuData_4_0_vpu_veew;
  assign io_toVecMemExu_1_0_bits_vpu_isVleff = s2_toExuData_4_0_vpu_isVleff;
  assign io_toVecMemExu_1_0_bits_ftqIdx_flag = s2_toExuData_4_0_ftqIdx_flag;
  assign io_toVecMemExu_1_0_bits_ftqIdx_value = s2_toExuData_4_0_ftqIdx_value;
  assign io_toVecMemExu_1_0_bits_ftqOffset = s2_toExuData_4_0_ftqOffset;
  assign io_toVecMemExu_1_0_bits_numLsElem = s2_toExuData_4_0_numLsElem;
  assign io_toVecMemExu_1_0_bits_sqIdx_flag = s2_toExuData_4_0_sqIdx_flag;
  assign io_toVecMemExu_1_0_bits_sqIdx_value = s2_toExuData_4_0_sqIdx_value;
  assign io_toVecMemExu_1_0_bits_lqIdx_flag = s2_toExuData_4_0_lqIdx_flag;
  assign io_toVecMemExu_1_0_bits_lqIdx_value = s2_toExuData_4_0_lqIdx_value;
  assign io_toVecMemExu_1_0_bits_dataSources_0_value = s2_toExuData_4_0_dataSources_0_value;
  assign io_toVecMemExu_1_0_bits_dataSources_1_value = s2_toExuData_4_0_dataSources_1_value;
  assign io_toVecMemExu_1_0_bits_dataSources_2_value = s2_toExuData_4_0_dataSources_2_value;
  assign io_toVecMemExu_1_0_bits_dataSources_3_value = s2_toExuData_4_0_dataSources_3_value;
  assign io_toVecMemExu_1_0_bits_dataSources_4_value = s2_toExuData_4_0_dataSources_4_value;
  assign io_toVecMemExu_1_0_bits_perfDebugInfo_enqRsTime = s2_toExuData_4_0_perfDebugInfo_enqRsTime;
  assign io_toVecMemExu_1_0_bits_perfDebugInfo_selectTime = s2_toExuData_4_0_perfDebugInfo_selectTime;
  assign io_toVecMemExu_1_0_bits_perfDebugInfo_issueTime = s2_toExuData_4_0_perfDebugInfo_issueTime;
  assign io_toVecMemExu_0_0_valid = s2_toExuValid_3_0;
  assign io_toVecMemExu_0_0_bits_fuType = s2_toExuData_3_0_fuType;
  assign io_toVecMemExu_0_0_bits_fuOpType = s2_toExuData_3_0_fuOpType;
  assign io_toVecMemExu_0_0_bits_src_0 = s2_toExuData_3_0_src_0;
  assign io_toVecMemExu_0_0_bits_src_1 = s2_toExuData_3_0_src_1;
  assign io_toVecMemExu_0_0_bits_src_2 = s2_toExuData_3_0_src_2;
  assign io_toVecMemExu_0_0_bits_src_3 = s2_toExuData_3_0_src_3;
  assign io_toVecMemExu_0_0_bits_src_4 = s2_toExuData_3_0_src_4;
  assign io_toVecMemExu_0_0_bits_robIdx_flag = s2_toExuData_3_0_robIdx_flag;
  assign io_toVecMemExu_0_0_bits_robIdx_value = s2_toExuData_3_0_robIdx_value;
  assign io_toVecMemExu_0_0_bits_pdest = s2_toExuData_3_0_pdest;
  assign io_toVecMemExu_0_0_bits_vecWen = s2_toExuData_3_0_vecWen;
  assign io_toVecMemExu_0_0_bits_v0Wen = s2_toExuData_3_0_v0Wen;
  assign io_toVecMemExu_0_0_bits_vlWen = s2_toExuData_3_0_vlWen;
  assign io_toVecMemExu_0_0_bits_vpu_vma = s2_toExuData_3_0_vpu_vma;
  assign io_toVecMemExu_0_0_bits_vpu_vta = s2_toExuData_3_0_vpu_vta;
  assign io_toVecMemExu_0_0_bits_vpu_vsew = s2_toExuData_3_0_vpu_vsew;
  assign io_toVecMemExu_0_0_bits_vpu_vlmul = s2_toExuData_3_0_vpu_vlmul;
  assign io_toVecMemExu_0_0_bits_vpu_vm = s2_toExuData_3_0_vpu_vm;
  assign io_toVecMemExu_0_0_bits_vpu_vstart = s2_toExuData_3_0_vpu_vstart;
  assign io_toVecMemExu_0_0_bits_vpu_vuopIdx = s2_toExuData_3_0_vpu_vuopIdx;
  assign io_toVecMemExu_0_0_bits_vpu_lastUop = s2_toExuData_3_0_vpu_lastUop;
  assign io_toVecMemExu_0_0_bits_vpu_vmask = s2_toExuData_3_0_vpu_vmask;
  assign io_toVecMemExu_0_0_bits_vpu_nf = s2_toExuData_3_0_vpu_nf;
  assign io_toVecMemExu_0_0_bits_vpu_veew = s2_toExuData_3_0_vpu_veew;
  assign io_toVecMemExu_0_0_bits_vpu_isVleff = s2_toExuData_3_0_vpu_isVleff;
  assign io_toVecMemExu_0_0_bits_ftqIdx_flag = s2_toExuData_3_0_ftqIdx_flag;
  assign io_toVecMemExu_0_0_bits_ftqIdx_value = s2_toExuData_3_0_ftqIdx_value;
  assign io_toVecMemExu_0_0_bits_ftqOffset = s2_toExuData_3_0_ftqOffset;
  assign io_toVecMemExu_0_0_bits_numLsElem = s2_toExuData_3_0_numLsElem;
  assign io_toVecMemExu_0_0_bits_sqIdx_flag = s2_toExuData_3_0_sqIdx_flag;
  assign io_toVecMemExu_0_0_bits_sqIdx_value = s2_toExuData_3_0_sqIdx_value;
  assign io_toVecMemExu_0_0_bits_lqIdx_flag = s2_toExuData_3_0_lqIdx_flag;
  assign io_toVecMemExu_0_0_bits_lqIdx_value = s2_toExuData_3_0_lqIdx_value;
  assign io_toVecMemExu_0_0_bits_dataSources_0_value = s2_toExuData_3_0_dataSources_0_value;
  assign io_toVecMemExu_0_0_bits_dataSources_1_value = s2_toExuData_3_0_dataSources_1_value;
  assign io_toVecMemExu_0_0_bits_dataSources_2_value = s2_toExuData_3_0_dataSources_2_value;
  assign io_toVecMemExu_0_0_bits_dataSources_3_value = s2_toExuData_3_0_dataSources_3_value;
  assign io_toVecMemExu_0_0_bits_dataSources_4_value = s2_toExuData_3_0_dataSources_4_value;
  assign io_toVecMemExu_0_0_bits_perfDebugInfo_enqRsTime = s2_toExuData_3_0_perfDebugInfo_enqRsTime;
  assign io_toVecMemExu_0_0_bits_perfDebugInfo_selectTime = s2_toExuData_3_0_perfDebugInfo_selectTime;
  assign io_toVecMemExu_0_0_bits_perfDebugInfo_issueTime = s2_toExuData_3_0_perfDebugInfo_issueTime;
  assign io_toVfIQOg2Resp_2_0_valid = s2_toExuValid_2_0;
  assign io_toVfIQOg2Resp_2_0_bits_resp = s2_toExuValid_2_0 & ~io_toVfArithExu_2_0_ready ? 2'h0 : 2'h3;
  assign io_toVfIQOg2Resp_1_1_valid = s2_toExuValid_1_1;
  assign io_toVfIQOg2Resp_1_0_valid = s2_toExuValid_1_0;
  assign io_toVfIQOg2Resp_1_0_bits_resp = s2_toExuValid_1_0 & ~io_toVfArithExu_1_0_ready ? 2'h0 : 2'h3;
  assign io_toVfIQOg2Resp_0_1_valid = s2_toExuValid_0_1;
  assign io_toVfIQOg2Resp_0_0_valid = s2_toExuValid_0_0;
  assign io_toVfIQOg2Resp_0_0_bits_resp = s2_toExuValid_0_0 & ~io_toVfArithExu_0_0_ready ? 2'h0 : 2'h3;
  assign io_toMemIQOg2Resp_1_0_valid = s2_toExuValid_4_0;
  assign io_toMemIQOg2Resp_1_0_bits_resp = {1'h0, ~(s2_toExuValid_4_0 & ~io_toVecMemExu_1_0_ready)};
  assign io_toMemIQOg2Resp_0_0_valid = s2_toExuValid_3_0;
  assign io_toMemIQOg2Resp_0_0_bits_resp = {1'h0, ~(s2_toExuValid_3_0 & ~io_toVecMemExu_0_0_ready)};
  assign io_toBypassNetworkImmInfo_1_imm = r_1_imm;
  assign io_toBypassNetworkImmInfo_1_immType = r_1_immType;
endmodule
