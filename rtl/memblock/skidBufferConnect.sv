// =====================================================================
// skidBufferConnect.sv —— 向量拆分单元里"拆分流水 → 拆分缓冲"之间的 skid 缓冲（切断 ready 的组合路径）
// ---------------------------------------------------------------------
// 位置（Chisel: xiangshan/mem/vector/VecCommon.scala 的 skidBuffer / skidBufferConnect）：
//   VLSplitImp / VSSplitImp 各例化一个（实例名都叫 VSSplitSkidBuffer，同一个 golden 模块）。
// 机制：两个状态。
//   empty：输入直通输出（out.valid = in.valid，out.bits = in.bits），对上游恒 ready；
//          若这一拍上游给了数据而下游不收（且没被冲刷），把数据暂存进 dataBuffer，转 skid。
//   skid ：输出取 dataBuffer，对上游不 ready；下游收走或被冲刷 → 回 empty。
//   于是上游看到的 ready（= 是否 empty）只由寄存器决定，不再组合依赖下游的 ready。
// 怪癖（照 golden）：
//   · 暂存条件不看 flush（!out.ready && in.fire 就存），只有"是否转 skid"看 flush；
//   · skid 状态下 out.valid 恒 1；empty 状态下即使正被 flush，out.valid 仍跟随 in.valid
//     （冲刷由下游自己再判一次 redirect）。
//   · payload 是一整份 VLSBundle：golden 留下 182 个字段的暂存寄存器，其中只有 89 个字段上游
//     真有驱动（有输入端口），其余字段上游恒 0、端口被 firtool 消掉——但暂存寄存器与输出端口
//     还在（下游模块的端口表需要它们），照写：存 0、直通 0。
// 文件结构：xs_SkidBuffer_core（手写：状态机与握手）→ golden 同名 wrapper（生成：逐字段的
//   暂存寄存器 + 二选一，字段集合照 golden；scripts/gen_vsplit.py）。
// =====================================================================

module xs_SkidBuffer_core (
  input  logic clock,
  input  logic reset,
  input  logic in_valid,
  output logic in_ready,
  input  logic flush,
  input  logic out_ready,
  output logic out_valid,
  output logic capture,       // 这一拍把输入暂存
  output logic use_buffer     // 输出取暂存值
);

  logic state;                // 0 = empty，1 = skid
  logic in_fire;

  assign in_ready   = ~state;
  assign in_fire    = in_valid & in_ready;
  assign capture    = ~out_ready & in_fire;
  assign use_buffer = state;
  assign out_valid  = in_valid | state;

  always_ff @(posedge clock or posedge reset) begin
    if (reset)      state <= 1'b0;
    else if (state) state <= ~(out_ready | flush);     // skid：被收走或被冲刷就清空
    else            state <= capture & ~flush;         // empty：下游不收且没被冲刷才转 skid
  end

endmodule

// =====================================================================
// skidBufferConnect —— golden 同名 wrapper（生成）
// =====================================================================
// BEGIN GENERATED(wrapper) —— scripts/gen_vsplit.py 生成，勿手改
module skidBufferConnect
(
  input          clock,
  input          reset,
  output         io_in_ready,
  input          io_in_valid,
  input  [15:0]  io_in_bits_flowMask,
  input  [127:0] io_in_bits_data,
  input  [63:0]  io_in_bits_baseAddr,
  input  [63:0]  io_in_bits_uopAddr,
  input  [127:0] io_in_bits_stride,
  input  [4:0]   io_in_bits_flowNum,
  input  [1:0]   io_in_bits_eew,
  input  [2:0]   io_in_bits_sew,
  input  [2:0]   io_in_bits_emul,
  input  [2:0]   io_in_bits_lmul,
  input  [2:0]   io_in_bits_instType,
  input  [4:0]   io_in_bits_indexedSplitOffset,
  input  [49:0]  io_in_bits_uop_pc,
  input          io_in_bits_uop_ftqPtr_flag,
  input  [5:0]   io_in_bits_uop_ftqPtr_value,
  input  [3:0]   io_in_bits_uop_ftqOffset,
  input  [34:0]  io_in_bits_uop_fuType,
  input  [8:0]   io_in_bits_uop_fuOpType,
  input          io_in_bits_uop_vecWen,
  input          io_in_bits_uop_v0Wen,
  input          io_in_bits_uop_vlWen,
  input          io_in_bits_uop_vpu_vill,
  input          io_in_bits_uop_vpu_vma,
  input          io_in_bits_uop_vpu_vta,
  input  [1:0]   io_in_bits_uop_vpu_vsew,
  input  [2:0]   io_in_bits_uop_vpu_vlmul,
  input          io_in_bits_uop_vpu_specVill,
  input          io_in_bits_uop_vpu_specVma,
  input          io_in_bits_uop_vpu_specVta,
  input  [1:0]   io_in_bits_uop_vpu_specVsew,
  input  [2:0]   io_in_bits_uop_vpu_specVlmul,
  input          io_in_bits_uop_vpu_vm,
  input  [7:0]   io_in_bits_uop_vpu_vstart,
  input  [2:0]   io_in_bits_uop_vpu_frm,
  input          io_in_bits_uop_vpu_fpu_isFpToVecInst,
  input          io_in_bits_uop_vpu_fpu_isFP32Instr,
  input          io_in_bits_uop_vpu_fpu_isFP64Instr,
  input          io_in_bits_uop_vpu_fpu_isReduction,
  input          io_in_bits_uop_vpu_fpu_isFoldTo1_2,
  input          io_in_bits_uop_vpu_fpu_isFoldTo1_4,
  input          io_in_bits_uop_vpu_fpu_isFoldTo1_8,
  input  [1:0]   io_in_bits_uop_vpu_vxrm,
  input  [6:0]   io_in_bits_uop_vpu_vuopIdx,
  input          io_in_bits_uop_vpu_lastUop,
  input  [127:0] io_in_bits_uop_vpu_vmask,
  input  [7:0]   io_in_bits_uop_vpu_vl,
  input  [2:0]   io_in_bits_uop_vpu_nf,
  input  [1:0]   io_in_bits_uop_vpu_veew,
  input          io_in_bits_uop_vpu_isReverse,
  input          io_in_bits_uop_vpu_isExt,
  input          io_in_bits_uop_vpu_isNarrow,
  input          io_in_bits_uop_vpu_isDstMask,
  input          io_in_bits_uop_vpu_isOpMask,
  input          io_in_bits_uop_vpu_isMove,
  input          io_in_bits_uop_vpu_isDependOldVd,
  input          io_in_bits_uop_vpu_isWritePartVd,
  input          io_in_bits_uop_vpu_isVleff,
  input  [6:0]   io_in_bits_uop_uopIdx,
  input          io_in_bits_uop_lastUop,
  input  [6:0]   io_in_bits_uop_numUops,
  input  [7:0]   io_in_bits_uop_pdest,
  input          io_in_bits_uop_robIdx_flag,
  input  [7:0]   io_in_bits_uop_robIdx_value,
  input          io_in_bits_uop_debugInfo_eliminatedMove,
  input  [63:0]  io_in_bits_uop_debugInfo_renameTime,
  input  [63:0]  io_in_bits_uop_debugInfo_dispatchTime,
  input  [63:0]  io_in_bits_uop_debugInfo_enqRsTime,
  input  [63:0]  io_in_bits_uop_debugInfo_selectTime,
  input  [63:0]  io_in_bits_uop_debugInfo_issueTime,
  input  [63:0]  io_in_bits_uop_debugInfo_writebackTime,
  input  [63:0]  io_in_bits_uop_debugInfo_runahead_checkpoint_id,
  input  [63:0]  io_in_bits_uop_debugInfo_tlbFirstReqTime,
  input  [63:0]  io_in_bits_uop_debugInfo_tlbRespTime,
  input  [55:0]  io_in_bits_uop_debug_seqNum_seqNum,
  input  [7:0]   io_in_bits_uop_debug_seqNum_uopIdx,
  input          io_in_bits_uop_lqIdx_flag,
  input  [6:0]   io_in_bits_uop_lqIdx_value,
  input          io_in_bits_uop_sqIdx_flag,
  input  [5:0]   io_in_bits_uop_sqIdx_value,
  input  [4:0]   io_in_bits_uop_numLsElem,
  input          io_in_bits_preIsSplit,
  input  [3:0]   io_in_bits_mBIndex,
  input  [2:0]   io_in_bits_alignedType,
  input  [7:0]   io_in_bits_indexVlMaxInVd,
  input  [3:0]   io_in_bits_usLowBitsAddr,
  input          io_in_bits_usAligned128,
  input  [31:0]  io_in_bits_usMask,
  input          io_in_bits_isVecPartReplay,
  input  [15:0]  io_in_bits_vecReplayFlowMask,
  input          io_flush,
  input          io_out_ready,
  output         io_out_valid,
  output [15:0]  io_out_bits_flowMask,
  output [127:0] io_out_bits_data,
  output [63:0]  io_out_bits_baseAddr,
  output [63:0]  io_out_bits_uopAddr,
  output [127:0] io_out_bits_stride,
  output [4:0]   io_out_bits_flowNum,
  output [1:0]   io_out_bits_eew,
  output [2:0]   io_out_bits_sew,
  output [2:0]   io_out_bits_emul,
  output [2:0]   io_out_bits_lmul,
  output [2:0]   io_out_bits_instType,
  output [4:0]   io_out_bits_indexedSplitOffset,
  output [31:0]  io_out_bits_uop_instr,
  output [49:0]  io_out_bits_uop_pc,
  output [9:0]   io_out_bits_uop_foldpc,
  output         io_out_bits_uop_exceptionVec_5,
  output         io_out_bits_uop_exceptionVec_7,
  output         io_out_bits_uop_exceptionVec_13,
  output         io_out_bits_uop_exceptionVec_15,
  output         io_out_bits_uop_exceptionVec_19,
  output         io_out_bits_uop_exceptionVec_21,
  output         io_out_bits_uop_exceptionVec_23,
  output         io_out_bits_uop_isFetchMalAddr,
  output         io_out_bits_uop_hasException,
  output [3:0]   io_out_bits_uop_trigger,
  output         io_out_bits_uop_preDecodeInfo_valid,
  output         io_out_bits_uop_preDecodeInfo_isRVC,
  output [1:0]   io_out_bits_uop_preDecodeInfo_brType,
  output         io_out_bits_uop_preDecodeInfo_isCall,
  output         io_out_bits_uop_preDecodeInfo_isRet,
  output         io_out_bits_uop_pred_taken,
  output         io_out_bits_uop_crossPageIPFFix,
  output         io_out_bits_uop_ftqPtr_flag,
  output [5:0]   io_out_bits_uop_ftqPtr_value,
  output [3:0]   io_out_bits_uop_ftqOffset,
  output         io_out_bits_uop_satpFlushFirstFetchFault,
  output [3:0]   io_out_bits_uop_srcType_0,
  output [3:0]   io_out_bits_uop_srcType_1,
  output [3:0]   io_out_bits_uop_srcType_2,
  output [3:0]   io_out_bits_uop_srcType_3,
  output [3:0]   io_out_bits_uop_srcType_4,
  output [5:0]   io_out_bits_uop_ldest,
  output [34:0]  io_out_bits_uop_fuType,
  output [8:0]   io_out_bits_uop_fuOpType,
  output         io_out_bits_uop_rfWen,
  output         io_out_bits_uop_fpWen,
  output         io_out_bits_uop_vecWen,
  output         io_out_bits_uop_v0Wen,
  output         io_out_bits_uop_vlWen,
  output         io_out_bits_uop_isXSTrap,
  output         io_out_bits_uop_waitForward,
  output         io_out_bits_uop_blockBackward,
  output         io_out_bits_uop_canRobCompress,
  output [3:0]   io_out_bits_uop_selImm,
  output [1:0]   io_out_bits_uop_fpu_typeTagOut,
  output         io_out_bits_uop_fpu_wflags,
  output [1:0]   io_out_bits_uop_fpu_typ,
  output [1:0]   io_out_bits_uop_fpu_fmt,
  output [2:0]   io_out_bits_uop_fpu_rm,
  output         io_out_bits_uop_vpu_vill,
  output         io_out_bits_uop_vpu_vma,
  output         io_out_bits_uop_vpu_vta,
  output [1:0]   io_out_bits_uop_vpu_vsew,
  output [2:0]   io_out_bits_uop_vpu_vlmul,
  output         io_out_bits_uop_vpu_specVill,
  output         io_out_bits_uop_vpu_specVma,
  output         io_out_bits_uop_vpu_specVta,
  output [1:0]   io_out_bits_uop_vpu_specVsew,
  output [2:0]   io_out_bits_uop_vpu_specVlmul,
  output         io_out_bits_uop_vpu_vm,
  output [7:0]   io_out_bits_uop_vpu_vstart,
  output [2:0]   io_out_bits_uop_vpu_frm,
  output         io_out_bits_uop_vpu_fpu_isFpToVecInst,
  output         io_out_bits_uop_vpu_fpu_isFP32Instr,
  output         io_out_bits_uop_vpu_fpu_isFP64Instr,
  output         io_out_bits_uop_vpu_fpu_isReduction,
  output         io_out_bits_uop_vpu_fpu_isFoldTo1_2,
  output         io_out_bits_uop_vpu_fpu_isFoldTo1_4,
  output         io_out_bits_uop_vpu_fpu_isFoldTo1_8,
  output [1:0]   io_out_bits_uop_vpu_vxrm,
  output [6:0]   io_out_bits_uop_vpu_vuopIdx,
  output         io_out_bits_uop_vpu_lastUop,
  output [127:0] io_out_bits_uop_vpu_vmask,
  output [7:0]   io_out_bits_uop_vpu_vl,
  output [2:0]   io_out_bits_uop_vpu_nf,
  output [1:0]   io_out_bits_uop_vpu_veew,
  output         io_out_bits_uop_vpu_isReverse,
  output         io_out_bits_uop_vpu_isExt,
  output         io_out_bits_uop_vpu_isNarrow,
  output         io_out_bits_uop_vpu_isDstMask,
  output         io_out_bits_uop_vpu_isOpMask,
  output         io_out_bits_uop_vpu_isMove,
  output         io_out_bits_uop_vpu_isDependOldVd,
  output         io_out_bits_uop_vpu_isWritePartVd,
  output         io_out_bits_uop_vpu_isVleff,
  output         io_out_bits_uop_vlsInstr,
  output         io_out_bits_uop_wfflags,
  output         io_out_bits_uop_isMove,
  output         io_out_bits_uop_isDropAmocasSta,
  output [6:0]   io_out_bits_uop_uopIdx,
  output         io_out_bits_uop_isVset,
  output         io_out_bits_uop_firstUop,
  output         io_out_bits_uop_lastUop,
  output [6:0]   io_out_bits_uop_numUops,
  output [6:0]   io_out_bits_uop_numWB,
  output [2:0]   io_out_bits_uop_commitType,
  output         io_out_bits_uop_srcState_0,
  output         io_out_bits_uop_srcState_1,
  output         io_out_bits_uop_srcState_2,
  output         io_out_bits_uop_srcState_3,
  output         io_out_bits_uop_srcState_4,
  output [1:0]   io_out_bits_uop_srcLoadDependency_0_0,
  output [1:0]   io_out_bits_uop_srcLoadDependency_0_1,
  output [1:0]   io_out_bits_uop_srcLoadDependency_0_2,
  output [1:0]   io_out_bits_uop_srcLoadDependency_1_0,
  output [1:0]   io_out_bits_uop_srcLoadDependency_1_1,
  output [1:0]   io_out_bits_uop_srcLoadDependency_1_2,
  output [1:0]   io_out_bits_uop_srcLoadDependency_2_0,
  output [1:0]   io_out_bits_uop_srcLoadDependency_2_1,
  output [1:0]   io_out_bits_uop_srcLoadDependency_2_2,
  output [1:0]   io_out_bits_uop_srcLoadDependency_3_0,
  output [1:0]   io_out_bits_uop_srcLoadDependency_3_1,
  output [1:0]   io_out_bits_uop_srcLoadDependency_3_2,
  output [1:0]   io_out_bits_uop_srcLoadDependency_4_0,
  output [1:0]   io_out_bits_uop_srcLoadDependency_4_1,
  output [1:0]   io_out_bits_uop_srcLoadDependency_4_2,
  output [7:0]   io_out_bits_uop_psrc_0,
  output [7:0]   io_out_bits_uop_psrc_1,
  output [7:0]   io_out_bits_uop_psrc_2,
  output [7:0]   io_out_bits_uop_psrc_3,
  output [7:0]   io_out_bits_uop_psrc_4,
  output [7:0]   io_out_bits_uop_pdest,
  output         io_out_bits_uop_useRegCache_0,
  output         io_out_bits_uop_useRegCache_1,
  output [4:0]   io_out_bits_uop_regCacheIdx_0,
  output [4:0]   io_out_bits_uop_regCacheIdx_1,
  output         io_out_bits_uop_robIdx_flag,
  output [7:0]   io_out_bits_uop_robIdx_value,
  output [2:0]   io_out_bits_uop_instrSize,
  output         io_out_bits_uop_dirtyFs,
  output         io_out_bits_uop_dirtyVs,
  output [3:0]   io_out_bits_uop_traceBlockInPipe_itype,
  output [3:0]   io_out_bits_uop_traceBlockInPipe_iretire,
  output         io_out_bits_uop_traceBlockInPipe_ilastsize,
  output         io_out_bits_uop_eliminatedMove,
  output         io_out_bits_uop_snapshot,
  output         io_out_bits_uop_debugInfo_eliminatedMove,
  output [63:0]  io_out_bits_uop_debugInfo_renameTime,
  output [63:0]  io_out_bits_uop_debugInfo_dispatchTime,
  output [63:0]  io_out_bits_uop_debugInfo_enqRsTime,
  output [63:0]  io_out_bits_uop_debugInfo_selectTime,
  output [63:0]  io_out_bits_uop_debugInfo_issueTime,
  output [63:0]  io_out_bits_uop_debugInfo_writebackTime,
  output [63:0]  io_out_bits_uop_debugInfo_runahead_checkpoint_id,
  output [63:0]  io_out_bits_uop_debugInfo_tlbFirstReqTime,
  output [63:0]  io_out_bits_uop_debugInfo_tlbRespTime,
  output [55:0]  io_out_bits_uop_debug_seqNum_seqNum,
  output [7:0]   io_out_bits_uop_debug_seqNum_uopIdx,
  output         io_out_bits_uop_storeSetHit,
  output         io_out_bits_uop_waitForRobIdx_flag,
  output [7:0]   io_out_bits_uop_waitForRobIdx_value,
  output         io_out_bits_uop_loadWaitBit,
  output         io_out_bits_uop_loadWaitStrict,
  output [4:0]   io_out_bits_uop_ssid,
  output         io_out_bits_uop_lqIdx_flag,
  output [6:0]   io_out_bits_uop_lqIdx_value,
  output         io_out_bits_uop_sqIdx_flag,
  output [5:0]   io_out_bits_uop_sqIdx_value,
  output         io_out_bits_uop_singleStep,
  output         io_out_bits_uop_replayInst,
  output [34:0]  io_out_bits_uop_debug_fuType,
  output         io_out_bits_uop_debug_sim_trig,
  output [4:0]   io_out_bits_uop_numLsElem,
  output         io_out_bits_preIsSplit,
  output [3:0]   io_out_bits_mBIndex,
  output [2:0]   io_out_bits_alignedType,
  output [7:0]   io_out_bits_indexVlMaxInVd,
  output [3:0]   io_out_bits_usLowBitsAddr,
  output         io_out_bits_usAligned128,
  output [31:0]  io_out_bits_usMask,
  output         io_out_bits_isVecPartReplay,
  output [15:0]  io_out_bits_vecReplayFlowMask
);

  logic capture;      // 这一拍把输入暂存进 dataBuffer
  logic use_buffer;   // 输出取 dataBuffer（否则直通输入）

  xs_SkidBuffer_core u_core (
    .clock      (clock),
    .reset      (reset),
    .in_valid   (io_in_valid),
    .in_ready   (io_in_ready),
    .flush      (io_flush),
    .out_ready  (io_out_ready),
    .out_valid  (io_out_valid),
    .capture    (capture),
    .use_buffer (use_buffer)
  );

  // ---- 暂存寄存器：182 个字段（golden 的字段集合）；其中 89 个上游有驱动，其余 93 个上游恒 0（端口被消掉），暂存的也是 0 ----
  logic [15:0]   dataBuffer_flowMask;
  logic [127:0]  dataBuffer_data;
  logic [63:0]   dataBuffer_baseAddr;
  logic [63:0]   dataBuffer_uopAddr;
  logic [127:0]  dataBuffer_stride;
  logic [4:0]    dataBuffer_flowNum;
  logic [1:0]    dataBuffer_eew;
  logic [2:0]    dataBuffer_sew;
  logic [2:0]    dataBuffer_emul;
  logic [2:0]    dataBuffer_lmul;
  logic [2:0]    dataBuffer_instType;
  logic [4:0]    dataBuffer_indexedSplitOffset;
  logic [31:0]   dataBuffer_uop_instr;
  logic [49:0]   dataBuffer_uop_pc;
  logic [9:0]    dataBuffer_uop_foldpc;
  logic          dataBuffer_uop_exceptionVec_5;
  logic          dataBuffer_uop_exceptionVec_7;
  logic          dataBuffer_uop_exceptionVec_13;
  logic          dataBuffer_uop_exceptionVec_15;
  logic          dataBuffer_uop_exceptionVec_19;
  logic          dataBuffer_uop_exceptionVec_21;
  logic          dataBuffer_uop_exceptionVec_23;
  logic          dataBuffer_uop_isFetchMalAddr;
  logic          dataBuffer_uop_hasException;
  logic [3:0]    dataBuffer_uop_trigger;
  logic          dataBuffer_uop_preDecodeInfo_valid;
  logic          dataBuffer_uop_preDecodeInfo_isRVC;
  logic [1:0]    dataBuffer_uop_preDecodeInfo_brType;
  logic          dataBuffer_uop_preDecodeInfo_isCall;
  logic          dataBuffer_uop_preDecodeInfo_isRet;
  logic          dataBuffer_uop_pred_taken;
  logic          dataBuffer_uop_crossPageIPFFix;
  logic          dataBuffer_uop_ftqPtr_flag;
  logic [5:0]    dataBuffer_uop_ftqPtr_value;
  logic [3:0]    dataBuffer_uop_ftqOffset;
  logic          dataBuffer_uop_satpFlushFirstFetchFault;
  logic [3:0]    dataBuffer_uop_srcType_0;
  logic [3:0]    dataBuffer_uop_srcType_1;
  logic [3:0]    dataBuffer_uop_srcType_2;
  logic [3:0]    dataBuffer_uop_srcType_3;
  logic [3:0]    dataBuffer_uop_srcType_4;
  logic [5:0]    dataBuffer_uop_ldest;
  logic [34:0]   dataBuffer_uop_fuType;
  logic [8:0]    dataBuffer_uop_fuOpType;
  logic          dataBuffer_uop_rfWen;
  logic          dataBuffer_uop_fpWen;
  logic          dataBuffer_uop_vecWen;
  logic          dataBuffer_uop_v0Wen;
  logic          dataBuffer_uop_vlWen;
  logic          dataBuffer_uop_isXSTrap;
  logic          dataBuffer_uop_waitForward;
  logic          dataBuffer_uop_blockBackward;
  logic          dataBuffer_uop_canRobCompress;
  logic [3:0]    dataBuffer_uop_selImm;
  logic [1:0]    dataBuffer_uop_fpu_typeTagOut;
  logic          dataBuffer_uop_fpu_wflags;
  logic [1:0]    dataBuffer_uop_fpu_typ;
  logic [1:0]    dataBuffer_uop_fpu_fmt;
  logic [2:0]    dataBuffer_uop_fpu_rm;
  logic          dataBuffer_uop_vpu_vill;
  logic          dataBuffer_uop_vpu_vma;
  logic          dataBuffer_uop_vpu_vta;
  logic [1:0]    dataBuffer_uop_vpu_vsew;
  logic [2:0]    dataBuffer_uop_vpu_vlmul;
  logic          dataBuffer_uop_vpu_specVill;
  logic          dataBuffer_uop_vpu_specVma;
  logic          dataBuffer_uop_vpu_specVta;
  logic [1:0]    dataBuffer_uop_vpu_specVsew;
  logic [2:0]    dataBuffer_uop_vpu_specVlmul;
  logic          dataBuffer_uop_vpu_vm;
  logic [7:0]    dataBuffer_uop_vpu_vstart;
  logic [2:0]    dataBuffer_uop_vpu_frm;
  logic          dataBuffer_uop_vpu_fpu_isFpToVecInst;
  logic          dataBuffer_uop_vpu_fpu_isFP32Instr;
  logic          dataBuffer_uop_vpu_fpu_isFP64Instr;
  logic          dataBuffer_uop_vpu_fpu_isReduction;
  logic          dataBuffer_uop_vpu_fpu_isFoldTo1_2;
  logic          dataBuffer_uop_vpu_fpu_isFoldTo1_4;
  logic          dataBuffer_uop_vpu_fpu_isFoldTo1_8;
  logic [1:0]    dataBuffer_uop_vpu_vxrm;
  logic [6:0]    dataBuffer_uop_vpu_vuopIdx;
  logic          dataBuffer_uop_vpu_lastUop;
  logic [127:0]  dataBuffer_uop_vpu_vmask;
  logic [7:0]    dataBuffer_uop_vpu_vl;
  logic [2:0]    dataBuffer_uop_vpu_nf;
  logic [1:0]    dataBuffer_uop_vpu_veew;
  logic          dataBuffer_uop_vpu_isReverse;
  logic          dataBuffer_uop_vpu_isExt;
  logic          dataBuffer_uop_vpu_isNarrow;
  logic          dataBuffer_uop_vpu_isDstMask;
  logic          dataBuffer_uop_vpu_isOpMask;
  logic          dataBuffer_uop_vpu_isMove;
  logic          dataBuffer_uop_vpu_isDependOldVd;
  logic          dataBuffer_uop_vpu_isWritePartVd;
  logic          dataBuffer_uop_vpu_isVleff;
  logic          dataBuffer_uop_vlsInstr;
  logic          dataBuffer_uop_wfflags;
  logic          dataBuffer_uop_isMove;
  logic          dataBuffer_uop_isDropAmocasSta;
  logic [6:0]    dataBuffer_uop_uopIdx;
  logic          dataBuffer_uop_isVset;
  logic          dataBuffer_uop_firstUop;
  logic          dataBuffer_uop_lastUop;
  logic [6:0]    dataBuffer_uop_numUops;
  logic [6:0]    dataBuffer_uop_numWB;
  logic [2:0]    dataBuffer_uop_commitType;
  logic          dataBuffer_uop_srcState_0;
  logic          dataBuffer_uop_srcState_1;
  logic          dataBuffer_uop_srcState_2;
  logic          dataBuffer_uop_srcState_3;
  logic          dataBuffer_uop_srcState_4;
  logic [1:0]    dataBuffer_uop_srcLoadDependency_0_0;
  logic [1:0]    dataBuffer_uop_srcLoadDependency_0_1;
  logic [1:0]    dataBuffer_uop_srcLoadDependency_0_2;
  logic [1:0]    dataBuffer_uop_srcLoadDependency_1_0;
  logic [1:0]    dataBuffer_uop_srcLoadDependency_1_1;
  logic [1:0]    dataBuffer_uop_srcLoadDependency_1_2;
  logic [1:0]    dataBuffer_uop_srcLoadDependency_2_0;
  logic [1:0]    dataBuffer_uop_srcLoadDependency_2_1;
  logic [1:0]    dataBuffer_uop_srcLoadDependency_2_2;
  logic [1:0]    dataBuffer_uop_srcLoadDependency_3_0;
  logic [1:0]    dataBuffer_uop_srcLoadDependency_3_1;
  logic [1:0]    dataBuffer_uop_srcLoadDependency_3_2;
  logic [1:0]    dataBuffer_uop_srcLoadDependency_4_0;
  logic [1:0]    dataBuffer_uop_srcLoadDependency_4_1;
  logic [1:0]    dataBuffer_uop_srcLoadDependency_4_2;
  logic [7:0]    dataBuffer_uop_psrc_0;
  logic [7:0]    dataBuffer_uop_psrc_1;
  logic [7:0]    dataBuffer_uop_psrc_2;
  logic [7:0]    dataBuffer_uop_psrc_3;
  logic [7:0]    dataBuffer_uop_psrc_4;
  logic [7:0]    dataBuffer_uop_pdest;
  logic          dataBuffer_uop_useRegCache_0;
  logic          dataBuffer_uop_useRegCache_1;
  logic [4:0]    dataBuffer_uop_regCacheIdx_0;
  logic [4:0]    dataBuffer_uop_regCacheIdx_1;
  logic          dataBuffer_uop_robIdx_flag;
  logic [7:0]    dataBuffer_uop_robIdx_value;
  logic [2:0]    dataBuffer_uop_instrSize;
  logic          dataBuffer_uop_dirtyFs;
  logic          dataBuffer_uop_dirtyVs;
  logic [3:0]    dataBuffer_uop_traceBlockInPipe_itype;
  logic [3:0]    dataBuffer_uop_traceBlockInPipe_iretire;
  logic          dataBuffer_uop_traceBlockInPipe_ilastsize;
  logic          dataBuffer_uop_eliminatedMove;
  logic          dataBuffer_uop_snapshot;
  logic          dataBuffer_uop_debugInfo_eliminatedMove;
  logic [63:0]   dataBuffer_uop_debugInfo_renameTime;
  logic [63:0]   dataBuffer_uop_debugInfo_dispatchTime;
  logic [63:0]   dataBuffer_uop_debugInfo_enqRsTime;
  logic [63:0]   dataBuffer_uop_debugInfo_selectTime;
  logic [63:0]   dataBuffer_uop_debugInfo_issueTime;
  logic [63:0]   dataBuffer_uop_debugInfo_writebackTime;
  logic [63:0]   dataBuffer_uop_debugInfo_runahead_checkpoint_id;
  logic [63:0]   dataBuffer_uop_debugInfo_tlbFirstReqTime;
  logic [63:0]   dataBuffer_uop_debugInfo_tlbRespTime;
  logic [55:0]   dataBuffer_uop_debug_seqNum_seqNum;
  logic [7:0]    dataBuffer_uop_debug_seqNum_uopIdx;
  logic          dataBuffer_uop_storeSetHit;
  logic          dataBuffer_uop_waitForRobIdx_flag;
  logic [7:0]    dataBuffer_uop_waitForRobIdx_value;
  logic          dataBuffer_uop_loadWaitBit;
  logic          dataBuffer_uop_loadWaitStrict;
  logic [4:0]    dataBuffer_uop_ssid;
  logic          dataBuffer_uop_lqIdx_flag;
  logic [6:0]    dataBuffer_uop_lqIdx_value;
  logic          dataBuffer_uop_sqIdx_flag;
  logic [5:0]    dataBuffer_uop_sqIdx_value;
  logic          dataBuffer_uop_singleStep;
  logic          dataBuffer_uop_replayInst;
  logic [34:0]   dataBuffer_uop_debug_fuType;
  logic          dataBuffer_uop_debug_sim_trig;
  logic [4:0]    dataBuffer_uop_numLsElem;
  logic          dataBuffer_preIsSplit;
  logic [3:0]    dataBuffer_mBIndex;
  logic [2:0]    dataBuffer_alignedType;
  logic [7:0]    dataBuffer_indexVlMaxInVd;
  logic [3:0]    dataBuffer_usLowBitsAddr;
  logic          dataBuffer_usAligned128;
  logic [31:0]   dataBuffer_usMask;
  logic          dataBuffer_isVecPartReplay;
  logic [15:0]   dataBuffer_vecReplayFlowMask;
  always_ff @(posedge clock) begin
    if (capture) begin
      dataBuffer_flowMask <= io_in_bits_flowMask;
      dataBuffer_data <= io_in_bits_data;
      dataBuffer_baseAddr <= io_in_bits_baseAddr;
      dataBuffer_uopAddr <= io_in_bits_uopAddr;
      dataBuffer_stride <= io_in_bits_stride;
      dataBuffer_flowNum <= io_in_bits_flowNum;
      dataBuffer_eew <= io_in_bits_eew;
      dataBuffer_sew <= io_in_bits_sew;
      dataBuffer_emul <= io_in_bits_emul;
      dataBuffer_lmul <= io_in_bits_lmul;
      dataBuffer_instType <= io_in_bits_instType;
      dataBuffer_indexedSplitOffset <= io_in_bits_indexedSplitOffset;
      dataBuffer_uop_instr <= '0;
      dataBuffer_uop_pc <= io_in_bits_uop_pc;
      dataBuffer_uop_foldpc <= '0;
      dataBuffer_uop_exceptionVec_5 <= '0;
      dataBuffer_uop_exceptionVec_7 <= '0;
      dataBuffer_uop_exceptionVec_13 <= '0;
      dataBuffer_uop_exceptionVec_15 <= '0;
      dataBuffer_uop_exceptionVec_19 <= '0;
      dataBuffer_uop_exceptionVec_21 <= '0;
      dataBuffer_uop_exceptionVec_23 <= '0;
      dataBuffer_uop_isFetchMalAddr <= '0;
      dataBuffer_uop_hasException <= '0;
      dataBuffer_uop_trigger <= '0;
      dataBuffer_uop_preDecodeInfo_valid <= '0;
      dataBuffer_uop_preDecodeInfo_isRVC <= '0;
      dataBuffer_uop_preDecodeInfo_brType <= '0;
      dataBuffer_uop_preDecodeInfo_isCall <= '0;
      dataBuffer_uop_preDecodeInfo_isRet <= '0;
      dataBuffer_uop_pred_taken <= '0;
      dataBuffer_uop_crossPageIPFFix <= '0;
      dataBuffer_uop_ftqPtr_flag <= io_in_bits_uop_ftqPtr_flag;
      dataBuffer_uop_ftqPtr_value <= io_in_bits_uop_ftqPtr_value;
      dataBuffer_uop_ftqOffset <= io_in_bits_uop_ftqOffset;
      dataBuffer_uop_satpFlushFirstFetchFault <= '0;
      dataBuffer_uop_srcType_0 <= '0;
      dataBuffer_uop_srcType_1 <= '0;
      dataBuffer_uop_srcType_2 <= '0;
      dataBuffer_uop_srcType_3 <= '0;
      dataBuffer_uop_srcType_4 <= '0;
      dataBuffer_uop_ldest <= '0;
      dataBuffer_uop_fuType <= io_in_bits_uop_fuType;
      dataBuffer_uop_fuOpType <= io_in_bits_uop_fuOpType;
      dataBuffer_uop_rfWen <= '0;
      dataBuffer_uop_fpWen <= '0;
      dataBuffer_uop_vecWen <= io_in_bits_uop_vecWen;
      dataBuffer_uop_v0Wen <= io_in_bits_uop_v0Wen;
      dataBuffer_uop_vlWen <= io_in_bits_uop_vlWen;
      dataBuffer_uop_isXSTrap <= '0;
      dataBuffer_uop_waitForward <= '0;
      dataBuffer_uop_blockBackward <= '0;
      dataBuffer_uop_canRobCompress <= '0;
      dataBuffer_uop_selImm <= '0;
      dataBuffer_uop_fpu_typeTagOut <= '0;
      dataBuffer_uop_fpu_wflags <= '0;
      dataBuffer_uop_fpu_typ <= '0;
      dataBuffer_uop_fpu_fmt <= '0;
      dataBuffer_uop_fpu_rm <= '0;
      dataBuffer_uop_vpu_vill <= io_in_bits_uop_vpu_vill;
      dataBuffer_uop_vpu_vma <= io_in_bits_uop_vpu_vma;
      dataBuffer_uop_vpu_vta <= io_in_bits_uop_vpu_vta;
      dataBuffer_uop_vpu_vsew <= io_in_bits_uop_vpu_vsew;
      dataBuffer_uop_vpu_vlmul <= io_in_bits_uop_vpu_vlmul;
      dataBuffer_uop_vpu_specVill <= io_in_bits_uop_vpu_specVill;
      dataBuffer_uop_vpu_specVma <= io_in_bits_uop_vpu_specVma;
      dataBuffer_uop_vpu_specVta <= io_in_bits_uop_vpu_specVta;
      dataBuffer_uop_vpu_specVsew <= io_in_bits_uop_vpu_specVsew;
      dataBuffer_uop_vpu_specVlmul <= io_in_bits_uop_vpu_specVlmul;
      dataBuffer_uop_vpu_vm <= io_in_bits_uop_vpu_vm;
      dataBuffer_uop_vpu_vstart <= io_in_bits_uop_vpu_vstart;
      dataBuffer_uop_vpu_frm <= io_in_bits_uop_vpu_frm;
      dataBuffer_uop_vpu_fpu_isFpToVecInst <= io_in_bits_uop_vpu_fpu_isFpToVecInst;
      dataBuffer_uop_vpu_fpu_isFP32Instr <= io_in_bits_uop_vpu_fpu_isFP32Instr;
      dataBuffer_uop_vpu_fpu_isFP64Instr <= io_in_bits_uop_vpu_fpu_isFP64Instr;
      dataBuffer_uop_vpu_fpu_isReduction <= io_in_bits_uop_vpu_fpu_isReduction;
      dataBuffer_uop_vpu_fpu_isFoldTo1_2 <= io_in_bits_uop_vpu_fpu_isFoldTo1_2;
      dataBuffer_uop_vpu_fpu_isFoldTo1_4 <= io_in_bits_uop_vpu_fpu_isFoldTo1_4;
      dataBuffer_uop_vpu_fpu_isFoldTo1_8 <= io_in_bits_uop_vpu_fpu_isFoldTo1_8;
      dataBuffer_uop_vpu_vxrm <= io_in_bits_uop_vpu_vxrm;
      dataBuffer_uop_vpu_vuopIdx <= io_in_bits_uop_vpu_vuopIdx;
      dataBuffer_uop_vpu_lastUop <= io_in_bits_uop_vpu_lastUop;
      dataBuffer_uop_vpu_vmask <= io_in_bits_uop_vpu_vmask;
      dataBuffer_uop_vpu_vl <= io_in_bits_uop_vpu_vl;
      dataBuffer_uop_vpu_nf <= io_in_bits_uop_vpu_nf;
      dataBuffer_uop_vpu_veew <= io_in_bits_uop_vpu_veew;
      dataBuffer_uop_vpu_isReverse <= io_in_bits_uop_vpu_isReverse;
      dataBuffer_uop_vpu_isExt <= io_in_bits_uop_vpu_isExt;
      dataBuffer_uop_vpu_isNarrow <= io_in_bits_uop_vpu_isNarrow;
      dataBuffer_uop_vpu_isDstMask <= io_in_bits_uop_vpu_isDstMask;
      dataBuffer_uop_vpu_isOpMask <= io_in_bits_uop_vpu_isOpMask;
      dataBuffer_uop_vpu_isMove <= io_in_bits_uop_vpu_isMove;
      dataBuffer_uop_vpu_isDependOldVd <= io_in_bits_uop_vpu_isDependOldVd;
      dataBuffer_uop_vpu_isWritePartVd <= io_in_bits_uop_vpu_isWritePartVd;
      dataBuffer_uop_vpu_isVleff <= io_in_bits_uop_vpu_isVleff;
      dataBuffer_uop_vlsInstr <= '0;
      dataBuffer_uop_wfflags <= '0;
      dataBuffer_uop_isMove <= '0;
      dataBuffer_uop_isDropAmocasSta <= '0;
      dataBuffer_uop_uopIdx <= io_in_bits_uop_uopIdx;
      dataBuffer_uop_isVset <= '0;
      dataBuffer_uop_firstUop <= '0;
      dataBuffer_uop_lastUop <= io_in_bits_uop_lastUop;
      dataBuffer_uop_numUops <= io_in_bits_uop_numUops;
      dataBuffer_uop_numWB <= '0;
      dataBuffer_uop_commitType <= '0;
      dataBuffer_uop_srcState_0 <= '0;
      dataBuffer_uop_srcState_1 <= '0;
      dataBuffer_uop_srcState_2 <= '0;
      dataBuffer_uop_srcState_3 <= '0;
      dataBuffer_uop_srcState_4 <= '0;
      dataBuffer_uop_srcLoadDependency_0_0 <= '0;
      dataBuffer_uop_srcLoadDependency_0_1 <= '0;
      dataBuffer_uop_srcLoadDependency_0_2 <= '0;
      dataBuffer_uop_srcLoadDependency_1_0 <= '0;
      dataBuffer_uop_srcLoadDependency_1_1 <= '0;
      dataBuffer_uop_srcLoadDependency_1_2 <= '0;
      dataBuffer_uop_srcLoadDependency_2_0 <= '0;
      dataBuffer_uop_srcLoadDependency_2_1 <= '0;
      dataBuffer_uop_srcLoadDependency_2_2 <= '0;
      dataBuffer_uop_srcLoadDependency_3_0 <= '0;
      dataBuffer_uop_srcLoadDependency_3_1 <= '0;
      dataBuffer_uop_srcLoadDependency_3_2 <= '0;
      dataBuffer_uop_srcLoadDependency_4_0 <= '0;
      dataBuffer_uop_srcLoadDependency_4_1 <= '0;
      dataBuffer_uop_srcLoadDependency_4_2 <= '0;
      dataBuffer_uop_psrc_0 <= '0;
      dataBuffer_uop_psrc_1 <= '0;
      dataBuffer_uop_psrc_2 <= '0;
      dataBuffer_uop_psrc_3 <= '0;
      dataBuffer_uop_psrc_4 <= '0;
      dataBuffer_uop_pdest <= io_in_bits_uop_pdest;
      dataBuffer_uop_useRegCache_0 <= '0;
      dataBuffer_uop_useRegCache_1 <= '0;
      dataBuffer_uop_regCacheIdx_0 <= '0;
      dataBuffer_uop_regCacheIdx_1 <= '0;
      dataBuffer_uop_robIdx_flag <= io_in_bits_uop_robIdx_flag;
      dataBuffer_uop_robIdx_value <= io_in_bits_uop_robIdx_value;
      dataBuffer_uop_instrSize <= '0;
      dataBuffer_uop_dirtyFs <= '0;
      dataBuffer_uop_dirtyVs <= '0;
      dataBuffer_uop_traceBlockInPipe_itype <= '0;
      dataBuffer_uop_traceBlockInPipe_iretire <= '0;
      dataBuffer_uop_traceBlockInPipe_ilastsize <= '0;
      dataBuffer_uop_eliminatedMove <= '0;
      dataBuffer_uop_snapshot <= '0;
      dataBuffer_uop_debugInfo_eliminatedMove <= io_in_bits_uop_debugInfo_eliminatedMove;
      dataBuffer_uop_debugInfo_renameTime <= io_in_bits_uop_debugInfo_renameTime;
      dataBuffer_uop_debugInfo_dispatchTime <= io_in_bits_uop_debugInfo_dispatchTime;
      dataBuffer_uop_debugInfo_enqRsTime <= io_in_bits_uop_debugInfo_enqRsTime;
      dataBuffer_uop_debugInfo_selectTime <= io_in_bits_uop_debugInfo_selectTime;
      dataBuffer_uop_debugInfo_issueTime <= io_in_bits_uop_debugInfo_issueTime;
      dataBuffer_uop_debugInfo_writebackTime <= io_in_bits_uop_debugInfo_writebackTime;
      dataBuffer_uop_debugInfo_runahead_checkpoint_id <= io_in_bits_uop_debugInfo_runahead_checkpoint_id;
      dataBuffer_uop_debugInfo_tlbFirstReqTime <= io_in_bits_uop_debugInfo_tlbFirstReqTime;
      dataBuffer_uop_debugInfo_tlbRespTime <= io_in_bits_uop_debugInfo_tlbRespTime;
      dataBuffer_uop_debug_seqNum_seqNum <= io_in_bits_uop_debug_seqNum_seqNum;
      dataBuffer_uop_debug_seqNum_uopIdx <= io_in_bits_uop_debug_seqNum_uopIdx;
      dataBuffer_uop_storeSetHit <= '0;
      dataBuffer_uop_waitForRobIdx_flag <= '0;
      dataBuffer_uop_waitForRobIdx_value <= '0;
      dataBuffer_uop_loadWaitBit <= '0;
      dataBuffer_uop_loadWaitStrict <= '0;
      dataBuffer_uop_ssid <= '0;
      dataBuffer_uop_lqIdx_flag <= io_in_bits_uop_lqIdx_flag;
      dataBuffer_uop_lqIdx_value <= io_in_bits_uop_lqIdx_value;
      dataBuffer_uop_sqIdx_flag <= io_in_bits_uop_sqIdx_flag;
      dataBuffer_uop_sqIdx_value <= io_in_bits_uop_sqIdx_value;
      dataBuffer_uop_singleStep <= '0;
      dataBuffer_uop_replayInst <= '0;
      dataBuffer_uop_debug_fuType <= '0;
      dataBuffer_uop_debug_sim_trig <= '0;
      dataBuffer_uop_numLsElem <= io_in_bits_uop_numLsElem;
      dataBuffer_preIsSplit <= io_in_bits_preIsSplit;
      dataBuffer_mBIndex <= io_in_bits_mBIndex;
      dataBuffer_alignedType <= io_in_bits_alignedType;
      dataBuffer_indexVlMaxInVd <= io_in_bits_indexVlMaxInVd;
      dataBuffer_usLowBitsAddr <= io_in_bits_usLowBitsAddr;
      dataBuffer_usAligned128 <= io_in_bits_usAligned128;
      dataBuffer_usMask <= io_in_bits_usMask;
      dataBuffer_isVecPartReplay <= io_in_bits_isVecPartReplay;
      dataBuffer_vecReplayFlowMask <= io_in_bits_vecReplayFlowMask;
    end
  end

  // ---- 输出：skid 状态取暂存值，否则直通（上游恒 0 的字段直通值就是 0）----
  assign io_out_bits_flowMask = use_buffer ? dataBuffer_flowMask : io_in_bits_flowMask;
  assign io_out_bits_data = use_buffer ? dataBuffer_data : io_in_bits_data;
  assign io_out_bits_baseAddr = use_buffer ? dataBuffer_baseAddr : io_in_bits_baseAddr;
  assign io_out_bits_uopAddr = use_buffer ? dataBuffer_uopAddr : io_in_bits_uopAddr;
  assign io_out_bits_stride = use_buffer ? dataBuffer_stride : io_in_bits_stride;
  assign io_out_bits_flowNum = use_buffer ? dataBuffer_flowNum : io_in_bits_flowNum;
  assign io_out_bits_eew = use_buffer ? dataBuffer_eew : io_in_bits_eew;
  assign io_out_bits_sew = use_buffer ? dataBuffer_sew : io_in_bits_sew;
  assign io_out_bits_emul = use_buffer ? dataBuffer_emul : io_in_bits_emul;
  assign io_out_bits_lmul = use_buffer ? dataBuffer_lmul : io_in_bits_lmul;
  assign io_out_bits_instType = use_buffer ? dataBuffer_instType : io_in_bits_instType;
  assign io_out_bits_indexedSplitOffset = use_buffer ? dataBuffer_indexedSplitOffset : io_in_bits_indexedSplitOffset;
  assign io_out_bits_uop_instr = use_buffer ? dataBuffer_uop_instr : '0;
  assign io_out_bits_uop_pc = use_buffer ? dataBuffer_uop_pc : io_in_bits_uop_pc;
  assign io_out_bits_uop_foldpc = use_buffer ? dataBuffer_uop_foldpc : '0;
  assign io_out_bits_uop_exceptionVec_5 = use_buffer ? dataBuffer_uop_exceptionVec_5 : '0;
  assign io_out_bits_uop_exceptionVec_7 = use_buffer ? dataBuffer_uop_exceptionVec_7 : '0;
  assign io_out_bits_uop_exceptionVec_13 = use_buffer ? dataBuffer_uop_exceptionVec_13 : '0;
  assign io_out_bits_uop_exceptionVec_15 = use_buffer ? dataBuffer_uop_exceptionVec_15 : '0;
  assign io_out_bits_uop_exceptionVec_19 = use_buffer ? dataBuffer_uop_exceptionVec_19 : '0;
  assign io_out_bits_uop_exceptionVec_21 = use_buffer ? dataBuffer_uop_exceptionVec_21 : '0;
  assign io_out_bits_uop_exceptionVec_23 = use_buffer ? dataBuffer_uop_exceptionVec_23 : '0;
  assign io_out_bits_uop_isFetchMalAddr = use_buffer ? dataBuffer_uop_isFetchMalAddr : '0;
  assign io_out_bits_uop_hasException = use_buffer ? dataBuffer_uop_hasException : '0;
  assign io_out_bits_uop_trigger = use_buffer ? dataBuffer_uop_trigger : '0;
  assign io_out_bits_uop_preDecodeInfo_valid = use_buffer ? dataBuffer_uop_preDecodeInfo_valid : '0;
  assign io_out_bits_uop_preDecodeInfo_isRVC = use_buffer ? dataBuffer_uop_preDecodeInfo_isRVC : '0;
  assign io_out_bits_uop_preDecodeInfo_brType = use_buffer ? dataBuffer_uop_preDecodeInfo_brType : '0;
  assign io_out_bits_uop_preDecodeInfo_isCall = use_buffer ? dataBuffer_uop_preDecodeInfo_isCall : '0;
  assign io_out_bits_uop_preDecodeInfo_isRet = use_buffer ? dataBuffer_uop_preDecodeInfo_isRet : '0;
  assign io_out_bits_uop_pred_taken = use_buffer ? dataBuffer_uop_pred_taken : '0;
  assign io_out_bits_uop_crossPageIPFFix = use_buffer ? dataBuffer_uop_crossPageIPFFix : '0;
  assign io_out_bits_uop_ftqPtr_flag = use_buffer ? dataBuffer_uop_ftqPtr_flag : io_in_bits_uop_ftqPtr_flag;
  assign io_out_bits_uop_ftqPtr_value = use_buffer ? dataBuffer_uop_ftqPtr_value : io_in_bits_uop_ftqPtr_value;
  assign io_out_bits_uop_ftqOffset = use_buffer ? dataBuffer_uop_ftqOffset : io_in_bits_uop_ftqOffset;
  assign io_out_bits_uop_satpFlushFirstFetchFault = use_buffer ? dataBuffer_uop_satpFlushFirstFetchFault : '0;
  assign io_out_bits_uop_srcType_0 = use_buffer ? dataBuffer_uop_srcType_0 : '0;
  assign io_out_bits_uop_srcType_1 = use_buffer ? dataBuffer_uop_srcType_1 : '0;
  assign io_out_bits_uop_srcType_2 = use_buffer ? dataBuffer_uop_srcType_2 : '0;
  assign io_out_bits_uop_srcType_3 = use_buffer ? dataBuffer_uop_srcType_3 : '0;
  assign io_out_bits_uop_srcType_4 = use_buffer ? dataBuffer_uop_srcType_4 : '0;
  assign io_out_bits_uop_ldest = use_buffer ? dataBuffer_uop_ldest : '0;
  assign io_out_bits_uop_fuType = use_buffer ? dataBuffer_uop_fuType : io_in_bits_uop_fuType;
  assign io_out_bits_uop_fuOpType = use_buffer ? dataBuffer_uop_fuOpType : io_in_bits_uop_fuOpType;
  assign io_out_bits_uop_rfWen = use_buffer ? dataBuffer_uop_rfWen : '0;
  assign io_out_bits_uop_fpWen = use_buffer ? dataBuffer_uop_fpWen : '0;
  assign io_out_bits_uop_vecWen = use_buffer ? dataBuffer_uop_vecWen : io_in_bits_uop_vecWen;
  assign io_out_bits_uop_v0Wen = use_buffer ? dataBuffer_uop_v0Wen : io_in_bits_uop_v0Wen;
  assign io_out_bits_uop_vlWen = use_buffer ? dataBuffer_uop_vlWen : io_in_bits_uop_vlWen;
  assign io_out_bits_uop_isXSTrap = use_buffer ? dataBuffer_uop_isXSTrap : '0;
  assign io_out_bits_uop_waitForward = use_buffer ? dataBuffer_uop_waitForward : '0;
  assign io_out_bits_uop_blockBackward = use_buffer ? dataBuffer_uop_blockBackward : '0;
  assign io_out_bits_uop_canRobCompress = use_buffer ? dataBuffer_uop_canRobCompress : '0;
  assign io_out_bits_uop_selImm = use_buffer ? dataBuffer_uop_selImm : '0;
  assign io_out_bits_uop_fpu_typeTagOut = use_buffer ? dataBuffer_uop_fpu_typeTagOut : '0;
  assign io_out_bits_uop_fpu_wflags = use_buffer ? dataBuffer_uop_fpu_wflags : '0;
  assign io_out_bits_uop_fpu_typ = use_buffer ? dataBuffer_uop_fpu_typ : '0;
  assign io_out_bits_uop_fpu_fmt = use_buffer ? dataBuffer_uop_fpu_fmt : '0;
  assign io_out_bits_uop_fpu_rm = use_buffer ? dataBuffer_uop_fpu_rm : '0;
  assign io_out_bits_uop_vpu_vill = use_buffer ? dataBuffer_uop_vpu_vill : io_in_bits_uop_vpu_vill;
  assign io_out_bits_uop_vpu_vma = use_buffer ? dataBuffer_uop_vpu_vma : io_in_bits_uop_vpu_vma;
  assign io_out_bits_uop_vpu_vta = use_buffer ? dataBuffer_uop_vpu_vta : io_in_bits_uop_vpu_vta;
  assign io_out_bits_uop_vpu_vsew = use_buffer ? dataBuffer_uop_vpu_vsew : io_in_bits_uop_vpu_vsew;
  assign io_out_bits_uop_vpu_vlmul = use_buffer ? dataBuffer_uop_vpu_vlmul : io_in_bits_uop_vpu_vlmul;
  assign io_out_bits_uop_vpu_specVill = use_buffer ? dataBuffer_uop_vpu_specVill : io_in_bits_uop_vpu_specVill;
  assign io_out_bits_uop_vpu_specVma = use_buffer ? dataBuffer_uop_vpu_specVma : io_in_bits_uop_vpu_specVma;
  assign io_out_bits_uop_vpu_specVta = use_buffer ? dataBuffer_uop_vpu_specVta : io_in_bits_uop_vpu_specVta;
  assign io_out_bits_uop_vpu_specVsew = use_buffer ? dataBuffer_uop_vpu_specVsew : io_in_bits_uop_vpu_specVsew;
  assign io_out_bits_uop_vpu_specVlmul = use_buffer ? dataBuffer_uop_vpu_specVlmul : io_in_bits_uop_vpu_specVlmul;
  assign io_out_bits_uop_vpu_vm = use_buffer ? dataBuffer_uop_vpu_vm : io_in_bits_uop_vpu_vm;
  assign io_out_bits_uop_vpu_vstart = use_buffer ? dataBuffer_uop_vpu_vstart : io_in_bits_uop_vpu_vstart;
  assign io_out_bits_uop_vpu_frm = use_buffer ? dataBuffer_uop_vpu_frm : io_in_bits_uop_vpu_frm;
  assign io_out_bits_uop_vpu_fpu_isFpToVecInst = use_buffer ? dataBuffer_uop_vpu_fpu_isFpToVecInst : io_in_bits_uop_vpu_fpu_isFpToVecInst;
  assign io_out_bits_uop_vpu_fpu_isFP32Instr = use_buffer ? dataBuffer_uop_vpu_fpu_isFP32Instr : io_in_bits_uop_vpu_fpu_isFP32Instr;
  assign io_out_bits_uop_vpu_fpu_isFP64Instr = use_buffer ? dataBuffer_uop_vpu_fpu_isFP64Instr : io_in_bits_uop_vpu_fpu_isFP64Instr;
  assign io_out_bits_uop_vpu_fpu_isReduction = use_buffer ? dataBuffer_uop_vpu_fpu_isReduction : io_in_bits_uop_vpu_fpu_isReduction;
  assign io_out_bits_uop_vpu_fpu_isFoldTo1_2 = use_buffer ? dataBuffer_uop_vpu_fpu_isFoldTo1_2 : io_in_bits_uop_vpu_fpu_isFoldTo1_2;
  assign io_out_bits_uop_vpu_fpu_isFoldTo1_4 = use_buffer ? dataBuffer_uop_vpu_fpu_isFoldTo1_4 : io_in_bits_uop_vpu_fpu_isFoldTo1_4;
  assign io_out_bits_uop_vpu_fpu_isFoldTo1_8 = use_buffer ? dataBuffer_uop_vpu_fpu_isFoldTo1_8 : io_in_bits_uop_vpu_fpu_isFoldTo1_8;
  assign io_out_bits_uop_vpu_vxrm = use_buffer ? dataBuffer_uop_vpu_vxrm : io_in_bits_uop_vpu_vxrm;
  assign io_out_bits_uop_vpu_vuopIdx = use_buffer ? dataBuffer_uop_vpu_vuopIdx : io_in_bits_uop_vpu_vuopIdx;
  assign io_out_bits_uop_vpu_lastUop = use_buffer ? dataBuffer_uop_vpu_lastUop : io_in_bits_uop_vpu_lastUop;
  assign io_out_bits_uop_vpu_vmask = use_buffer ? dataBuffer_uop_vpu_vmask : io_in_bits_uop_vpu_vmask;
  assign io_out_bits_uop_vpu_vl = use_buffer ? dataBuffer_uop_vpu_vl : io_in_bits_uop_vpu_vl;
  assign io_out_bits_uop_vpu_nf = use_buffer ? dataBuffer_uop_vpu_nf : io_in_bits_uop_vpu_nf;
  assign io_out_bits_uop_vpu_veew = use_buffer ? dataBuffer_uop_vpu_veew : io_in_bits_uop_vpu_veew;
  assign io_out_bits_uop_vpu_isReverse = use_buffer ? dataBuffer_uop_vpu_isReverse : io_in_bits_uop_vpu_isReverse;
  assign io_out_bits_uop_vpu_isExt = use_buffer ? dataBuffer_uop_vpu_isExt : io_in_bits_uop_vpu_isExt;
  assign io_out_bits_uop_vpu_isNarrow = use_buffer ? dataBuffer_uop_vpu_isNarrow : io_in_bits_uop_vpu_isNarrow;
  assign io_out_bits_uop_vpu_isDstMask = use_buffer ? dataBuffer_uop_vpu_isDstMask : io_in_bits_uop_vpu_isDstMask;
  assign io_out_bits_uop_vpu_isOpMask = use_buffer ? dataBuffer_uop_vpu_isOpMask : io_in_bits_uop_vpu_isOpMask;
  assign io_out_bits_uop_vpu_isMove = use_buffer ? dataBuffer_uop_vpu_isMove : io_in_bits_uop_vpu_isMove;
  assign io_out_bits_uop_vpu_isDependOldVd = use_buffer ? dataBuffer_uop_vpu_isDependOldVd : io_in_bits_uop_vpu_isDependOldVd;
  assign io_out_bits_uop_vpu_isWritePartVd = use_buffer ? dataBuffer_uop_vpu_isWritePartVd : io_in_bits_uop_vpu_isWritePartVd;
  assign io_out_bits_uop_vpu_isVleff = use_buffer ? dataBuffer_uop_vpu_isVleff : io_in_bits_uop_vpu_isVleff;
  assign io_out_bits_uop_vlsInstr = use_buffer ? dataBuffer_uop_vlsInstr : '0;
  assign io_out_bits_uop_wfflags = use_buffer ? dataBuffer_uop_wfflags : '0;
  assign io_out_bits_uop_isMove = use_buffer ? dataBuffer_uop_isMove : '0;
  assign io_out_bits_uop_isDropAmocasSta = use_buffer ? dataBuffer_uop_isDropAmocasSta : '0;
  assign io_out_bits_uop_uopIdx = use_buffer ? dataBuffer_uop_uopIdx : io_in_bits_uop_uopIdx;
  assign io_out_bits_uop_isVset = use_buffer ? dataBuffer_uop_isVset : '0;
  assign io_out_bits_uop_firstUop = use_buffer ? dataBuffer_uop_firstUop : '0;
  assign io_out_bits_uop_lastUop = use_buffer ? dataBuffer_uop_lastUop : io_in_bits_uop_lastUop;
  assign io_out_bits_uop_numUops = use_buffer ? dataBuffer_uop_numUops : io_in_bits_uop_numUops;
  assign io_out_bits_uop_numWB = use_buffer ? dataBuffer_uop_numWB : '0;
  assign io_out_bits_uop_commitType = use_buffer ? dataBuffer_uop_commitType : '0;
  assign io_out_bits_uop_srcState_0 = use_buffer ? dataBuffer_uop_srcState_0 : '0;
  assign io_out_bits_uop_srcState_1 = use_buffer ? dataBuffer_uop_srcState_1 : '0;
  assign io_out_bits_uop_srcState_2 = use_buffer ? dataBuffer_uop_srcState_2 : '0;
  assign io_out_bits_uop_srcState_3 = use_buffer ? dataBuffer_uop_srcState_3 : '0;
  assign io_out_bits_uop_srcState_4 = use_buffer ? dataBuffer_uop_srcState_4 : '0;
  assign io_out_bits_uop_srcLoadDependency_0_0 = use_buffer ? dataBuffer_uop_srcLoadDependency_0_0 : '0;
  assign io_out_bits_uop_srcLoadDependency_0_1 = use_buffer ? dataBuffer_uop_srcLoadDependency_0_1 : '0;
  assign io_out_bits_uop_srcLoadDependency_0_2 = use_buffer ? dataBuffer_uop_srcLoadDependency_0_2 : '0;
  assign io_out_bits_uop_srcLoadDependency_1_0 = use_buffer ? dataBuffer_uop_srcLoadDependency_1_0 : '0;
  assign io_out_bits_uop_srcLoadDependency_1_1 = use_buffer ? dataBuffer_uop_srcLoadDependency_1_1 : '0;
  assign io_out_bits_uop_srcLoadDependency_1_2 = use_buffer ? dataBuffer_uop_srcLoadDependency_1_2 : '0;
  assign io_out_bits_uop_srcLoadDependency_2_0 = use_buffer ? dataBuffer_uop_srcLoadDependency_2_0 : '0;
  assign io_out_bits_uop_srcLoadDependency_2_1 = use_buffer ? dataBuffer_uop_srcLoadDependency_2_1 : '0;
  assign io_out_bits_uop_srcLoadDependency_2_2 = use_buffer ? dataBuffer_uop_srcLoadDependency_2_2 : '0;
  assign io_out_bits_uop_srcLoadDependency_3_0 = use_buffer ? dataBuffer_uop_srcLoadDependency_3_0 : '0;
  assign io_out_bits_uop_srcLoadDependency_3_1 = use_buffer ? dataBuffer_uop_srcLoadDependency_3_1 : '0;
  assign io_out_bits_uop_srcLoadDependency_3_2 = use_buffer ? dataBuffer_uop_srcLoadDependency_3_2 : '0;
  assign io_out_bits_uop_srcLoadDependency_4_0 = use_buffer ? dataBuffer_uop_srcLoadDependency_4_0 : '0;
  assign io_out_bits_uop_srcLoadDependency_4_1 = use_buffer ? dataBuffer_uop_srcLoadDependency_4_1 : '0;
  assign io_out_bits_uop_srcLoadDependency_4_2 = use_buffer ? dataBuffer_uop_srcLoadDependency_4_2 : '0;
  assign io_out_bits_uop_psrc_0 = use_buffer ? dataBuffer_uop_psrc_0 : '0;
  assign io_out_bits_uop_psrc_1 = use_buffer ? dataBuffer_uop_psrc_1 : '0;
  assign io_out_bits_uop_psrc_2 = use_buffer ? dataBuffer_uop_psrc_2 : '0;
  assign io_out_bits_uop_psrc_3 = use_buffer ? dataBuffer_uop_psrc_3 : '0;
  assign io_out_bits_uop_psrc_4 = use_buffer ? dataBuffer_uop_psrc_4 : '0;
  assign io_out_bits_uop_pdest = use_buffer ? dataBuffer_uop_pdest : io_in_bits_uop_pdest;
  assign io_out_bits_uop_useRegCache_0 = use_buffer ? dataBuffer_uop_useRegCache_0 : '0;
  assign io_out_bits_uop_useRegCache_1 = use_buffer ? dataBuffer_uop_useRegCache_1 : '0;
  assign io_out_bits_uop_regCacheIdx_0 = use_buffer ? dataBuffer_uop_regCacheIdx_0 : '0;
  assign io_out_bits_uop_regCacheIdx_1 = use_buffer ? dataBuffer_uop_regCacheIdx_1 : '0;
  assign io_out_bits_uop_robIdx_flag = use_buffer ? dataBuffer_uop_robIdx_flag : io_in_bits_uop_robIdx_flag;
  assign io_out_bits_uop_robIdx_value = use_buffer ? dataBuffer_uop_robIdx_value : io_in_bits_uop_robIdx_value;
  assign io_out_bits_uop_instrSize = use_buffer ? dataBuffer_uop_instrSize : '0;
  assign io_out_bits_uop_dirtyFs = use_buffer ? dataBuffer_uop_dirtyFs : '0;
  assign io_out_bits_uop_dirtyVs = use_buffer ? dataBuffer_uop_dirtyVs : '0;
  assign io_out_bits_uop_traceBlockInPipe_itype = use_buffer ? dataBuffer_uop_traceBlockInPipe_itype : '0;
  assign io_out_bits_uop_traceBlockInPipe_iretire = use_buffer ? dataBuffer_uop_traceBlockInPipe_iretire : '0;
  assign io_out_bits_uop_traceBlockInPipe_ilastsize = use_buffer ? dataBuffer_uop_traceBlockInPipe_ilastsize : '0;
  assign io_out_bits_uop_eliminatedMove = use_buffer ? dataBuffer_uop_eliminatedMove : '0;
  assign io_out_bits_uop_snapshot = use_buffer ? dataBuffer_uop_snapshot : '0;
  assign io_out_bits_uop_debugInfo_eliminatedMove = use_buffer ? dataBuffer_uop_debugInfo_eliminatedMove : io_in_bits_uop_debugInfo_eliminatedMove;
  assign io_out_bits_uop_debugInfo_renameTime = use_buffer ? dataBuffer_uop_debugInfo_renameTime : io_in_bits_uop_debugInfo_renameTime;
  assign io_out_bits_uop_debugInfo_dispatchTime = use_buffer ? dataBuffer_uop_debugInfo_dispatchTime : io_in_bits_uop_debugInfo_dispatchTime;
  assign io_out_bits_uop_debugInfo_enqRsTime = use_buffer ? dataBuffer_uop_debugInfo_enqRsTime : io_in_bits_uop_debugInfo_enqRsTime;
  assign io_out_bits_uop_debugInfo_selectTime = use_buffer ? dataBuffer_uop_debugInfo_selectTime : io_in_bits_uop_debugInfo_selectTime;
  assign io_out_bits_uop_debugInfo_issueTime = use_buffer ? dataBuffer_uop_debugInfo_issueTime : io_in_bits_uop_debugInfo_issueTime;
  assign io_out_bits_uop_debugInfo_writebackTime = use_buffer ? dataBuffer_uop_debugInfo_writebackTime : io_in_bits_uop_debugInfo_writebackTime;
  assign io_out_bits_uop_debugInfo_runahead_checkpoint_id = use_buffer ? dataBuffer_uop_debugInfo_runahead_checkpoint_id : io_in_bits_uop_debugInfo_runahead_checkpoint_id;
  assign io_out_bits_uop_debugInfo_tlbFirstReqTime = use_buffer ? dataBuffer_uop_debugInfo_tlbFirstReqTime : io_in_bits_uop_debugInfo_tlbFirstReqTime;
  assign io_out_bits_uop_debugInfo_tlbRespTime = use_buffer ? dataBuffer_uop_debugInfo_tlbRespTime : io_in_bits_uop_debugInfo_tlbRespTime;
  assign io_out_bits_uop_debug_seqNum_seqNum = use_buffer ? dataBuffer_uop_debug_seqNum_seqNum : io_in_bits_uop_debug_seqNum_seqNum;
  assign io_out_bits_uop_debug_seqNum_uopIdx = use_buffer ? dataBuffer_uop_debug_seqNum_uopIdx : io_in_bits_uop_debug_seqNum_uopIdx;
  assign io_out_bits_uop_storeSetHit = use_buffer ? dataBuffer_uop_storeSetHit : '0;
  assign io_out_bits_uop_waitForRobIdx_flag = use_buffer ? dataBuffer_uop_waitForRobIdx_flag : '0;
  assign io_out_bits_uop_waitForRobIdx_value = use_buffer ? dataBuffer_uop_waitForRobIdx_value : '0;
  assign io_out_bits_uop_loadWaitBit = use_buffer ? dataBuffer_uop_loadWaitBit : '0;
  assign io_out_bits_uop_loadWaitStrict = use_buffer ? dataBuffer_uop_loadWaitStrict : '0;
  assign io_out_bits_uop_ssid = use_buffer ? dataBuffer_uop_ssid : '0;
  assign io_out_bits_uop_lqIdx_flag = use_buffer ? dataBuffer_uop_lqIdx_flag : io_in_bits_uop_lqIdx_flag;
  assign io_out_bits_uop_lqIdx_value = use_buffer ? dataBuffer_uop_lqIdx_value : io_in_bits_uop_lqIdx_value;
  assign io_out_bits_uop_sqIdx_flag = use_buffer ? dataBuffer_uop_sqIdx_flag : io_in_bits_uop_sqIdx_flag;
  assign io_out_bits_uop_sqIdx_value = use_buffer ? dataBuffer_uop_sqIdx_value : io_in_bits_uop_sqIdx_value;
  assign io_out_bits_uop_singleStep = use_buffer ? dataBuffer_uop_singleStep : '0;
  assign io_out_bits_uop_replayInst = use_buffer ? dataBuffer_uop_replayInst : '0;
  assign io_out_bits_uop_debug_fuType = use_buffer ? dataBuffer_uop_debug_fuType : '0;
  assign io_out_bits_uop_debug_sim_trig = use_buffer ? dataBuffer_uop_debug_sim_trig : '0;
  assign io_out_bits_uop_numLsElem = use_buffer ? dataBuffer_uop_numLsElem : io_in_bits_uop_numLsElem;
  assign io_out_bits_preIsSplit = use_buffer ? dataBuffer_preIsSplit : io_in_bits_preIsSplit;
  assign io_out_bits_mBIndex = use_buffer ? dataBuffer_mBIndex : io_in_bits_mBIndex;
  assign io_out_bits_alignedType = use_buffer ? dataBuffer_alignedType : io_in_bits_alignedType;
  assign io_out_bits_indexVlMaxInVd = use_buffer ? dataBuffer_indexVlMaxInVd : io_in_bits_indexVlMaxInVd;
  assign io_out_bits_usLowBitsAddr = use_buffer ? dataBuffer_usLowBitsAddr : io_in_bits_usLowBitsAddr;
  assign io_out_bits_usAligned128 = use_buffer ? dataBuffer_usAligned128 : io_in_bits_usAligned128;
  assign io_out_bits_usMask = use_buffer ? dataBuffer_usMask : io_in_bits_usMask;
  assign io_out_bits_isVecPartReplay = use_buffer ? dataBuffer_isVecPartReplay : io_in_bits_isVecPartReplay;
  assign io_out_bits_vecReplayFlowMask = use_buffer ? dataBuffer_vecReplayFlowMask : io_in_bits_vecReplayFlowMask;

endmodule
// END GENERATED(wrapper)
