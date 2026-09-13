// NewPipelineConnectPipe_29 / _34 / _35 UT —— golden vs 派生 _xs 双例化，一个 tb 三个变体。
//
// 为什么另开目录而不是并进 verif/ut/NewPipelineConnectPipe/：那个 tb 是家族 owner 的
// 14 变体聚合件，其 Makefile 头上明写"_29/_34/_35 在 rtl/ 里还没有实现，不在本 UT 范围"。
// 主树同时有多位 owner 在动，改别人的 tb 会撞车；三者又恰好是同一批"G1 新增/重编号"
// 变体，合成一个 tb 一次编译即可。
//
// 被测语义（三者共用核 xs_PipelineConnect，见 rtl/common/PipelineConnect.sv）：
//   in_ready = out_ready | ~valid
//   fire     = in_valid & in_ready
//   valid'   = ~isFlush & (fire | ~rightOutFire & valid)     （_34 无 isFlush 项）
//   data     = RegEnable(in_bits, fire)   —— 全部字段打拍，无组合直通
//
// 覆盖闸（流水连接件极易假绿：握手永远畅通、flush 永不触发也能 errors=0）：
//   fire / 反压(in_valid & ~in_ready) / hold(valid & ~rightOutFire) /
//   deq(valid & rightOutFire) / 占用中被改写(valid & out_ready & in_valid) /
//   flush 命中占用中的表项 / flush 与 fire 同拍（冲刷优先级） /
//   payload 每一位都取到过 1、也取到过 0（位宽写窄或字段漏掉不会假绿）。
//   _34 golden 没有 io_isFlush 端口，两条 flush 闸对它不适用，明确跳过而不是记 0 放过。
//
// 采样时机：覆盖必须在**时钟沿之前**采。沿后再采就永远看不到 flush（flush 恰恰把
// valid 清成 0 了），fire/反压同理会串到下一拍——家族 owner 第一版就是沿后采、
// 14 个变体 flush 全 0 却全绿，是覆盖闸救回来的。
`timescale 1ns/1ps

`define CHECK(TAG,SIG) begin \
  if (!$isunknown(g_``TAG``_``SIG)) begin \
    checks++; nchk_``TAG``++; \
    if (g_``TAG``_``SIG !== i_``TAG``_``SIG) begin \
      errors++; nerr_``TAG``++; \
      if (errors <= 40) $display("[%0t] MISMATCH %s.%s g=%0h i=%0h", $time, `"TAG`", `"SIG`", \
                                 g_``TAG``_``SIG, i_``TAG``_``SIG); \
    end \
  end \
end

module tb;
  int unsigned NCYCLES = 200000;
  bit clock = 0;
  bit reset;
  int errors = 0;
  longint checks = 0;
  always #5 clock = ~clock;

  // ==========================================================================
  // NewPipelineConnectPipe_29 —— 72 字段 / 1023 位 payload
  // ==========================================================================
  logic v29_io_in_valid;
  logic v29_io_in_bits_uop_exceptionVec_3;
  logic v29_io_in_bits_uop_exceptionVec_4;
  logic v29_io_in_bits_uop_exceptionVec_5;
  logic v29_io_in_bits_uop_exceptionVec_6;
  logic v29_io_in_bits_uop_exceptionVec_7;
  logic v29_io_in_bits_uop_exceptionVec_13;
  logic v29_io_in_bits_uop_exceptionVec_15;
  logic v29_io_in_bits_uop_exceptionVec_19;
  logic v29_io_in_bits_uop_exceptionVec_21;
  logic v29_io_in_bits_uop_exceptionVec_23;
  logic [3:0] v29_io_in_bits_uop_trigger;
  logic [8:0] v29_io_in_bits_uop_fuOpType;
  logic v29_io_in_bits_uop_vecWen;
  logic v29_io_in_bits_uop_v0Wen;
  logic v29_io_in_bits_uop_vlWen;
  logic v29_io_in_bits_uop_flushPipe;
  logic v29_io_in_bits_uop_vpu_vill;
  logic v29_io_in_bits_uop_vpu_vma;
  logic v29_io_in_bits_uop_vpu_vta;
  logic [1:0] v29_io_in_bits_uop_vpu_vsew;
  logic [2:0] v29_io_in_bits_uop_vpu_vlmul;
  logic v29_io_in_bits_uop_vpu_specVill;
  logic v29_io_in_bits_uop_vpu_specVma;
  logic v29_io_in_bits_uop_vpu_specVta;
  logic [1:0] v29_io_in_bits_uop_vpu_specVsew;
  logic [2:0] v29_io_in_bits_uop_vpu_specVlmul;
  logic v29_io_in_bits_uop_vpu_vm;
  logic [7:0] v29_io_in_bits_uop_vpu_vstart;
  logic [2:0] v29_io_in_bits_uop_vpu_frm;
  logic v29_io_in_bits_uop_vpu_fpu_isFpToVecInst;
  logic v29_io_in_bits_uop_vpu_fpu_isFP32Instr;
  logic v29_io_in_bits_uop_vpu_fpu_isFP64Instr;
  logic v29_io_in_bits_uop_vpu_fpu_isReduction;
  logic v29_io_in_bits_uop_vpu_fpu_isFoldTo1_2;
  logic v29_io_in_bits_uop_vpu_fpu_isFoldTo1_4;
  logic v29_io_in_bits_uop_vpu_fpu_isFoldTo1_8;
  logic [1:0] v29_io_in_bits_uop_vpu_vxrm;
  logic [6:0] v29_io_in_bits_uop_vpu_vuopIdx;
  logic v29_io_in_bits_uop_vpu_lastUop;
  logic [127:0] v29_io_in_bits_uop_vpu_vmask;
  logic [7:0] v29_io_in_bits_uop_vpu_vl;
  logic [2:0] v29_io_in_bits_uop_vpu_nf;
  logic [1:0] v29_io_in_bits_uop_vpu_veew;
  logic v29_io_in_bits_uop_vpu_isReverse;
  logic v29_io_in_bits_uop_vpu_isExt;
  logic v29_io_in_bits_uop_vpu_isNarrow;
  logic v29_io_in_bits_uop_vpu_isDstMask;
  logic v29_io_in_bits_uop_vpu_isOpMask;
  logic v29_io_in_bits_uop_vpu_isMove;
  logic v29_io_in_bits_uop_vpu_isDependOldVd;
  logic v29_io_in_bits_uop_vpu_isWritePartVd;
  logic v29_io_in_bits_uop_vpu_isVleff;
  logic [7:0] v29_io_in_bits_uop_psrc_2;
  logic [7:0] v29_io_in_bits_uop_pdest;
  logic v29_io_in_bits_uop_robIdx_flag;
  logic [7:0] v29_io_in_bits_uop_robIdx_value;
  logic v29_io_in_bits_uop_debugInfo_eliminatedMove;
  logic [63:0] v29_io_in_bits_uop_debugInfo_renameTime;
  logic [63:0] v29_io_in_bits_uop_debugInfo_dispatchTime;
  logic [63:0] v29_io_in_bits_uop_debugInfo_enqRsTime;
  logic [63:0] v29_io_in_bits_uop_debugInfo_selectTime;
  logic [63:0] v29_io_in_bits_uop_debugInfo_issueTime;
  logic [63:0] v29_io_in_bits_uop_debugInfo_writebackTime;
  logic [63:0] v29_io_in_bits_uop_debugInfo_runahead_checkpoint_id;
  logic [63:0] v29_io_in_bits_uop_debugInfo_tlbFirstReqTime;
  logic [63:0] v29_io_in_bits_uop_debugInfo_tlbRespTime;
  logic [55:0] v29_io_in_bits_uop_debug_seqNum_seqNum;
  logic [7:0] v29_io_in_bits_uop_debug_seqNum_uopIdx;
  logic v29_io_in_bits_uop_replayInst;
  logic [127:0] v29_io_in_bits_data;
  logic [2:0] v29_io_in_bits_vdIdx;
  logic [2:0] v29_io_in_bits_vdIdxInField;
  logic v29_io_out_ready;
  logic v29_io_rightOutFire;
  logic v29_io_isFlush;
  wire  g_v29_io_in_ready, i_v29_io_in_ready;
  wire  g_v29_io_out_valid, i_v29_io_out_valid;
  wire  g_v29_io_out_bits_uop_exceptionVec_3, i_v29_io_out_bits_uop_exceptionVec_3;
  wire  g_v29_io_out_bits_uop_exceptionVec_4, i_v29_io_out_bits_uop_exceptionVec_4;
  wire  g_v29_io_out_bits_uop_exceptionVec_5, i_v29_io_out_bits_uop_exceptionVec_5;
  wire  g_v29_io_out_bits_uop_exceptionVec_6, i_v29_io_out_bits_uop_exceptionVec_6;
  wire  g_v29_io_out_bits_uop_exceptionVec_7, i_v29_io_out_bits_uop_exceptionVec_7;
  wire  g_v29_io_out_bits_uop_exceptionVec_13, i_v29_io_out_bits_uop_exceptionVec_13;
  wire  g_v29_io_out_bits_uop_exceptionVec_15, i_v29_io_out_bits_uop_exceptionVec_15;
  wire  g_v29_io_out_bits_uop_exceptionVec_19, i_v29_io_out_bits_uop_exceptionVec_19;
  wire  g_v29_io_out_bits_uop_exceptionVec_21, i_v29_io_out_bits_uop_exceptionVec_21;
  wire  g_v29_io_out_bits_uop_exceptionVec_23, i_v29_io_out_bits_uop_exceptionVec_23;
  wire  [3:0] g_v29_io_out_bits_uop_trigger, i_v29_io_out_bits_uop_trigger;
  wire  [8:0] g_v29_io_out_bits_uop_fuOpType, i_v29_io_out_bits_uop_fuOpType;
  wire  g_v29_io_out_bits_uop_vecWen, i_v29_io_out_bits_uop_vecWen;
  wire  g_v29_io_out_bits_uop_v0Wen, i_v29_io_out_bits_uop_v0Wen;
  wire  g_v29_io_out_bits_uop_vlWen, i_v29_io_out_bits_uop_vlWen;
  wire  g_v29_io_out_bits_uop_flushPipe, i_v29_io_out_bits_uop_flushPipe;
  wire  g_v29_io_out_bits_uop_vpu_vill, i_v29_io_out_bits_uop_vpu_vill;
  wire  g_v29_io_out_bits_uop_vpu_vma, i_v29_io_out_bits_uop_vpu_vma;
  wire  g_v29_io_out_bits_uop_vpu_vta, i_v29_io_out_bits_uop_vpu_vta;
  wire  [1:0] g_v29_io_out_bits_uop_vpu_vsew, i_v29_io_out_bits_uop_vpu_vsew;
  wire  [2:0] g_v29_io_out_bits_uop_vpu_vlmul, i_v29_io_out_bits_uop_vpu_vlmul;
  wire  g_v29_io_out_bits_uop_vpu_specVill, i_v29_io_out_bits_uop_vpu_specVill;
  wire  g_v29_io_out_bits_uop_vpu_specVma, i_v29_io_out_bits_uop_vpu_specVma;
  wire  g_v29_io_out_bits_uop_vpu_specVta, i_v29_io_out_bits_uop_vpu_specVta;
  wire  [1:0] g_v29_io_out_bits_uop_vpu_specVsew, i_v29_io_out_bits_uop_vpu_specVsew;
  wire  [2:0] g_v29_io_out_bits_uop_vpu_specVlmul, i_v29_io_out_bits_uop_vpu_specVlmul;
  wire  g_v29_io_out_bits_uop_vpu_vm, i_v29_io_out_bits_uop_vpu_vm;
  wire  [7:0] g_v29_io_out_bits_uop_vpu_vstart, i_v29_io_out_bits_uop_vpu_vstart;
  wire  [2:0] g_v29_io_out_bits_uop_vpu_frm, i_v29_io_out_bits_uop_vpu_frm;
  wire  g_v29_io_out_bits_uop_vpu_fpu_isFpToVecInst, i_v29_io_out_bits_uop_vpu_fpu_isFpToVecInst;
  wire  g_v29_io_out_bits_uop_vpu_fpu_isFP32Instr, i_v29_io_out_bits_uop_vpu_fpu_isFP32Instr;
  wire  g_v29_io_out_bits_uop_vpu_fpu_isFP64Instr, i_v29_io_out_bits_uop_vpu_fpu_isFP64Instr;
  wire  g_v29_io_out_bits_uop_vpu_fpu_isReduction, i_v29_io_out_bits_uop_vpu_fpu_isReduction;
  wire  g_v29_io_out_bits_uop_vpu_fpu_isFoldTo1_2, i_v29_io_out_bits_uop_vpu_fpu_isFoldTo1_2;
  wire  g_v29_io_out_bits_uop_vpu_fpu_isFoldTo1_4, i_v29_io_out_bits_uop_vpu_fpu_isFoldTo1_4;
  wire  g_v29_io_out_bits_uop_vpu_fpu_isFoldTo1_8, i_v29_io_out_bits_uop_vpu_fpu_isFoldTo1_8;
  wire  [1:0] g_v29_io_out_bits_uop_vpu_vxrm, i_v29_io_out_bits_uop_vpu_vxrm;
  wire  [6:0] g_v29_io_out_bits_uop_vpu_vuopIdx, i_v29_io_out_bits_uop_vpu_vuopIdx;
  wire  g_v29_io_out_bits_uop_vpu_lastUop, i_v29_io_out_bits_uop_vpu_lastUop;
  wire  [127:0] g_v29_io_out_bits_uop_vpu_vmask, i_v29_io_out_bits_uop_vpu_vmask;
  wire  [7:0] g_v29_io_out_bits_uop_vpu_vl, i_v29_io_out_bits_uop_vpu_vl;
  wire  [2:0] g_v29_io_out_bits_uop_vpu_nf, i_v29_io_out_bits_uop_vpu_nf;
  wire  [1:0] g_v29_io_out_bits_uop_vpu_veew, i_v29_io_out_bits_uop_vpu_veew;
  wire  g_v29_io_out_bits_uop_vpu_isReverse, i_v29_io_out_bits_uop_vpu_isReverse;
  wire  g_v29_io_out_bits_uop_vpu_isExt, i_v29_io_out_bits_uop_vpu_isExt;
  wire  g_v29_io_out_bits_uop_vpu_isNarrow, i_v29_io_out_bits_uop_vpu_isNarrow;
  wire  g_v29_io_out_bits_uop_vpu_isDstMask, i_v29_io_out_bits_uop_vpu_isDstMask;
  wire  g_v29_io_out_bits_uop_vpu_isOpMask, i_v29_io_out_bits_uop_vpu_isOpMask;
  wire  g_v29_io_out_bits_uop_vpu_isMove, i_v29_io_out_bits_uop_vpu_isMove;
  wire  g_v29_io_out_bits_uop_vpu_isDependOldVd, i_v29_io_out_bits_uop_vpu_isDependOldVd;
  wire  g_v29_io_out_bits_uop_vpu_isWritePartVd, i_v29_io_out_bits_uop_vpu_isWritePartVd;
  wire  g_v29_io_out_bits_uop_vpu_isVleff, i_v29_io_out_bits_uop_vpu_isVleff;
  wire  [7:0] g_v29_io_out_bits_uop_psrc_2, i_v29_io_out_bits_uop_psrc_2;
  wire  [7:0] g_v29_io_out_bits_uop_pdest, i_v29_io_out_bits_uop_pdest;
  wire  g_v29_io_out_bits_uop_robIdx_flag, i_v29_io_out_bits_uop_robIdx_flag;
  wire  [7:0] g_v29_io_out_bits_uop_robIdx_value, i_v29_io_out_bits_uop_robIdx_value;
  wire  g_v29_io_out_bits_uop_debugInfo_eliminatedMove, i_v29_io_out_bits_uop_debugInfo_eliminatedMove;
  wire  [63:0] g_v29_io_out_bits_uop_debugInfo_renameTime, i_v29_io_out_bits_uop_debugInfo_renameTime;
  wire  [63:0] g_v29_io_out_bits_uop_debugInfo_dispatchTime, i_v29_io_out_bits_uop_debugInfo_dispatchTime;
  wire  [63:0] g_v29_io_out_bits_uop_debugInfo_enqRsTime, i_v29_io_out_bits_uop_debugInfo_enqRsTime;
  wire  [63:0] g_v29_io_out_bits_uop_debugInfo_selectTime, i_v29_io_out_bits_uop_debugInfo_selectTime;
  wire  [63:0] g_v29_io_out_bits_uop_debugInfo_issueTime, i_v29_io_out_bits_uop_debugInfo_issueTime;
  wire  [63:0] g_v29_io_out_bits_uop_debugInfo_writebackTime, i_v29_io_out_bits_uop_debugInfo_writebackTime;
  wire  [63:0] g_v29_io_out_bits_uop_debugInfo_runahead_checkpoint_id, i_v29_io_out_bits_uop_debugInfo_runahead_checkpoint_id;
  wire  [63:0] g_v29_io_out_bits_uop_debugInfo_tlbFirstReqTime, i_v29_io_out_bits_uop_debugInfo_tlbFirstReqTime;
  wire  [63:0] g_v29_io_out_bits_uop_debugInfo_tlbRespTime, i_v29_io_out_bits_uop_debugInfo_tlbRespTime;
  wire  [55:0] g_v29_io_out_bits_uop_debug_seqNum_seqNum, i_v29_io_out_bits_uop_debug_seqNum_seqNum;
  wire  [7:0] g_v29_io_out_bits_uop_debug_seqNum_uopIdx, i_v29_io_out_bits_uop_debug_seqNum_uopIdx;
  wire  g_v29_io_out_bits_uop_replayInst, i_v29_io_out_bits_uop_replayInst;
  wire  [127:0] g_v29_io_out_bits_data, i_v29_io_out_bits_data;
  wire  [2:0] g_v29_io_out_bits_vdIdx, i_v29_io_out_bits_vdIdx;
  wire  [2:0] g_v29_io_out_bits_vdIdxInField, i_v29_io_out_bits_vdIdxInField;
  longint nchk_v29 = 0; int nerr_v29 = 0;
  longint fire_v29 = 0, bp_v29 = 0, hold_v29 = 0, deq_v29 = 0, owr_v29 = 0;
  longint flush_v29 = 0, flfire_v29 = 0;
  logic [1022:0] por_v29 = '0, pand_v29 = '1;   // payload 逐位或 / 逐位与
  wire  [1022:0] pcat_v29 = {v29_io_in_bits_uop_exceptionVec_3, v29_io_in_bits_uop_exceptionVec_4, v29_io_in_bits_uop_exceptionVec_5, v29_io_in_bits_uop_exceptionVec_6, v29_io_in_bits_uop_exceptionVec_7, v29_io_in_bits_uop_exceptionVec_13, v29_io_in_bits_uop_exceptionVec_15, v29_io_in_bits_uop_exceptionVec_19, v29_io_in_bits_uop_exceptionVec_21, v29_io_in_bits_uop_exceptionVec_23, v29_io_in_bits_uop_trigger, v29_io_in_bits_uop_fuOpType, v29_io_in_bits_uop_vecWen, v29_io_in_bits_uop_v0Wen, v29_io_in_bits_uop_vlWen, v29_io_in_bits_uop_flushPipe, v29_io_in_bits_uop_vpu_vill, v29_io_in_bits_uop_vpu_vma, v29_io_in_bits_uop_vpu_vta, v29_io_in_bits_uop_vpu_vsew, v29_io_in_bits_uop_vpu_vlmul, v29_io_in_bits_uop_vpu_specVill, v29_io_in_bits_uop_vpu_specVma, v29_io_in_bits_uop_vpu_specVta, v29_io_in_bits_uop_vpu_specVsew, v29_io_in_bits_uop_vpu_specVlmul, v29_io_in_bits_uop_vpu_vm, v29_io_in_bits_uop_vpu_vstart, v29_io_in_bits_uop_vpu_frm, v29_io_in_bits_uop_vpu_fpu_isFpToVecInst, v29_io_in_bits_uop_vpu_fpu_isFP32Instr, v29_io_in_bits_uop_vpu_fpu_isFP64Instr, v29_io_in_bits_uop_vpu_fpu_isReduction, v29_io_in_bits_uop_vpu_fpu_isFoldTo1_2, v29_io_in_bits_uop_vpu_fpu_isFoldTo1_4, v29_io_in_bits_uop_vpu_fpu_isFoldTo1_8, v29_io_in_bits_uop_vpu_vxrm, v29_io_in_bits_uop_vpu_vuopIdx, v29_io_in_bits_uop_vpu_lastUop, v29_io_in_bits_uop_vpu_vmask, v29_io_in_bits_uop_vpu_vl, v29_io_in_bits_uop_vpu_nf, v29_io_in_bits_uop_vpu_veew, v29_io_in_bits_uop_vpu_isReverse, v29_io_in_bits_uop_vpu_isExt, v29_io_in_bits_uop_vpu_isNarrow, v29_io_in_bits_uop_vpu_isDstMask, v29_io_in_bits_uop_vpu_isOpMask, v29_io_in_bits_uop_vpu_isMove, v29_io_in_bits_uop_vpu_isDependOldVd, v29_io_in_bits_uop_vpu_isWritePartVd, v29_io_in_bits_uop_vpu_isVleff, v29_io_in_bits_uop_psrc_2, v29_io_in_bits_uop_pdest, v29_io_in_bits_uop_robIdx_flag, v29_io_in_bits_uop_robIdx_value, v29_io_in_bits_uop_debugInfo_eliminatedMove, v29_io_in_bits_uop_debugInfo_renameTime, v29_io_in_bits_uop_debugInfo_dispatchTime, v29_io_in_bits_uop_debugInfo_enqRsTime, v29_io_in_bits_uop_debugInfo_selectTime, v29_io_in_bits_uop_debugInfo_issueTime, v29_io_in_bits_uop_debugInfo_writebackTime, v29_io_in_bits_uop_debugInfo_runahead_checkpoint_id, v29_io_in_bits_uop_debugInfo_tlbFirstReqTime, v29_io_in_bits_uop_debugInfo_tlbRespTime, v29_io_in_bits_uop_debug_seqNum_seqNum, v29_io_in_bits_uop_debug_seqNum_uopIdx, v29_io_in_bits_uop_replayInst, v29_io_in_bits_data, v29_io_in_bits_vdIdx, v29_io_in_bits_vdIdxInField};
  NewPipelineConnectPipe_29 u_g_v29 (
    .clock(clock), .reset(reset),
    .io_in_valid(v29_io_in_valid),
    .io_in_bits_uop_exceptionVec_3(v29_io_in_bits_uop_exceptionVec_3),
    .io_in_bits_uop_exceptionVec_4(v29_io_in_bits_uop_exceptionVec_4),
    .io_in_bits_uop_exceptionVec_5(v29_io_in_bits_uop_exceptionVec_5),
    .io_in_bits_uop_exceptionVec_6(v29_io_in_bits_uop_exceptionVec_6),
    .io_in_bits_uop_exceptionVec_7(v29_io_in_bits_uop_exceptionVec_7),
    .io_in_bits_uop_exceptionVec_13(v29_io_in_bits_uop_exceptionVec_13),
    .io_in_bits_uop_exceptionVec_15(v29_io_in_bits_uop_exceptionVec_15),
    .io_in_bits_uop_exceptionVec_19(v29_io_in_bits_uop_exceptionVec_19),
    .io_in_bits_uop_exceptionVec_21(v29_io_in_bits_uop_exceptionVec_21),
    .io_in_bits_uop_exceptionVec_23(v29_io_in_bits_uop_exceptionVec_23),
    .io_in_bits_uop_trigger(v29_io_in_bits_uop_trigger),
    .io_in_bits_uop_fuOpType(v29_io_in_bits_uop_fuOpType),
    .io_in_bits_uop_vecWen(v29_io_in_bits_uop_vecWen),
    .io_in_bits_uop_v0Wen(v29_io_in_bits_uop_v0Wen),
    .io_in_bits_uop_vlWen(v29_io_in_bits_uop_vlWen),
    .io_in_bits_uop_flushPipe(v29_io_in_bits_uop_flushPipe),
    .io_in_bits_uop_vpu_vill(v29_io_in_bits_uop_vpu_vill),
    .io_in_bits_uop_vpu_vma(v29_io_in_bits_uop_vpu_vma),
    .io_in_bits_uop_vpu_vta(v29_io_in_bits_uop_vpu_vta),
    .io_in_bits_uop_vpu_vsew(v29_io_in_bits_uop_vpu_vsew),
    .io_in_bits_uop_vpu_vlmul(v29_io_in_bits_uop_vpu_vlmul),
    .io_in_bits_uop_vpu_specVill(v29_io_in_bits_uop_vpu_specVill),
    .io_in_bits_uop_vpu_specVma(v29_io_in_bits_uop_vpu_specVma),
    .io_in_bits_uop_vpu_specVta(v29_io_in_bits_uop_vpu_specVta),
    .io_in_bits_uop_vpu_specVsew(v29_io_in_bits_uop_vpu_specVsew),
    .io_in_bits_uop_vpu_specVlmul(v29_io_in_bits_uop_vpu_specVlmul),
    .io_in_bits_uop_vpu_vm(v29_io_in_bits_uop_vpu_vm),
    .io_in_bits_uop_vpu_vstart(v29_io_in_bits_uop_vpu_vstart),
    .io_in_bits_uop_vpu_frm(v29_io_in_bits_uop_vpu_frm),
    .io_in_bits_uop_vpu_fpu_isFpToVecInst(v29_io_in_bits_uop_vpu_fpu_isFpToVecInst),
    .io_in_bits_uop_vpu_fpu_isFP32Instr(v29_io_in_bits_uop_vpu_fpu_isFP32Instr),
    .io_in_bits_uop_vpu_fpu_isFP64Instr(v29_io_in_bits_uop_vpu_fpu_isFP64Instr),
    .io_in_bits_uop_vpu_fpu_isReduction(v29_io_in_bits_uop_vpu_fpu_isReduction),
    .io_in_bits_uop_vpu_fpu_isFoldTo1_2(v29_io_in_bits_uop_vpu_fpu_isFoldTo1_2),
    .io_in_bits_uop_vpu_fpu_isFoldTo1_4(v29_io_in_bits_uop_vpu_fpu_isFoldTo1_4),
    .io_in_bits_uop_vpu_fpu_isFoldTo1_8(v29_io_in_bits_uop_vpu_fpu_isFoldTo1_8),
    .io_in_bits_uop_vpu_vxrm(v29_io_in_bits_uop_vpu_vxrm),
    .io_in_bits_uop_vpu_vuopIdx(v29_io_in_bits_uop_vpu_vuopIdx),
    .io_in_bits_uop_vpu_lastUop(v29_io_in_bits_uop_vpu_lastUop),
    .io_in_bits_uop_vpu_vmask(v29_io_in_bits_uop_vpu_vmask),
    .io_in_bits_uop_vpu_vl(v29_io_in_bits_uop_vpu_vl),
    .io_in_bits_uop_vpu_nf(v29_io_in_bits_uop_vpu_nf),
    .io_in_bits_uop_vpu_veew(v29_io_in_bits_uop_vpu_veew),
    .io_in_bits_uop_vpu_isReverse(v29_io_in_bits_uop_vpu_isReverse),
    .io_in_bits_uop_vpu_isExt(v29_io_in_bits_uop_vpu_isExt),
    .io_in_bits_uop_vpu_isNarrow(v29_io_in_bits_uop_vpu_isNarrow),
    .io_in_bits_uop_vpu_isDstMask(v29_io_in_bits_uop_vpu_isDstMask),
    .io_in_bits_uop_vpu_isOpMask(v29_io_in_bits_uop_vpu_isOpMask),
    .io_in_bits_uop_vpu_isMove(v29_io_in_bits_uop_vpu_isMove),
    .io_in_bits_uop_vpu_isDependOldVd(v29_io_in_bits_uop_vpu_isDependOldVd),
    .io_in_bits_uop_vpu_isWritePartVd(v29_io_in_bits_uop_vpu_isWritePartVd),
    .io_in_bits_uop_vpu_isVleff(v29_io_in_bits_uop_vpu_isVleff),
    .io_in_bits_uop_psrc_2(v29_io_in_bits_uop_psrc_2),
    .io_in_bits_uop_pdest(v29_io_in_bits_uop_pdest),
    .io_in_bits_uop_robIdx_flag(v29_io_in_bits_uop_robIdx_flag),
    .io_in_bits_uop_robIdx_value(v29_io_in_bits_uop_robIdx_value),
    .io_in_bits_uop_debugInfo_eliminatedMove(v29_io_in_bits_uop_debugInfo_eliminatedMove),
    .io_in_bits_uop_debugInfo_renameTime(v29_io_in_bits_uop_debugInfo_renameTime),
    .io_in_bits_uop_debugInfo_dispatchTime(v29_io_in_bits_uop_debugInfo_dispatchTime),
    .io_in_bits_uop_debugInfo_enqRsTime(v29_io_in_bits_uop_debugInfo_enqRsTime),
    .io_in_bits_uop_debugInfo_selectTime(v29_io_in_bits_uop_debugInfo_selectTime),
    .io_in_bits_uop_debugInfo_issueTime(v29_io_in_bits_uop_debugInfo_issueTime),
    .io_in_bits_uop_debugInfo_writebackTime(v29_io_in_bits_uop_debugInfo_writebackTime),
    .io_in_bits_uop_debugInfo_runahead_checkpoint_id(v29_io_in_bits_uop_debugInfo_runahead_checkpoint_id),
    .io_in_bits_uop_debugInfo_tlbFirstReqTime(v29_io_in_bits_uop_debugInfo_tlbFirstReqTime),
    .io_in_bits_uop_debugInfo_tlbRespTime(v29_io_in_bits_uop_debugInfo_tlbRespTime),
    .io_in_bits_uop_debug_seqNum_seqNum(v29_io_in_bits_uop_debug_seqNum_seqNum),
    .io_in_bits_uop_debug_seqNum_uopIdx(v29_io_in_bits_uop_debug_seqNum_uopIdx),
    .io_in_bits_uop_replayInst(v29_io_in_bits_uop_replayInst),
    .io_in_bits_data(v29_io_in_bits_data),
    .io_in_bits_vdIdx(v29_io_in_bits_vdIdx),
    .io_in_bits_vdIdxInField(v29_io_in_bits_vdIdxInField),
    .io_out_ready(v29_io_out_ready),
    .io_rightOutFire(v29_io_rightOutFire),
    .io_isFlush(v29_io_isFlush),
    .io_in_ready(g_v29_io_in_ready),
    .io_out_valid(g_v29_io_out_valid),
    .io_out_bits_uop_exceptionVec_3(g_v29_io_out_bits_uop_exceptionVec_3),
    .io_out_bits_uop_exceptionVec_4(g_v29_io_out_bits_uop_exceptionVec_4),
    .io_out_bits_uop_exceptionVec_5(g_v29_io_out_bits_uop_exceptionVec_5),
    .io_out_bits_uop_exceptionVec_6(g_v29_io_out_bits_uop_exceptionVec_6),
    .io_out_bits_uop_exceptionVec_7(g_v29_io_out_bits_uop_exceptionVec_7),
    .io_out_bits_uop_exceptionVec_13(g_v29_io_out_bits_uop_exceptionVec_13),
    .io_out_bits_uop_exceptionVec_15(g_v29_io_out_bits_uop_exceptionVec_15),
    .io_out_bits_uop_exceptionVec_19(g_v29_io_out_bits_uop_exceptionVec_19),
    .io_out_bits_uop_exceptionVec_21(g_v29_io_out_bits_uop_exceptionVec_21),
    .io_out_bits_uop_exceptionVec_23(g_v29_io_out_bits_uop_exceptionVec_23),
    .io_out_bits_uop_trigger(g_v29_io_out_bits_uop_trigger),
    .io_out_bits_uop_fuOpType(g_v29_io_out_bits_uop_fuOpType),
    .io_out_bits_uop_vecWen(g_v29_io_out_bits_uop_vecWen),
    .io_out_bits_uop_v0Wen(g_v29_io_out_bits_uop_v0Wen),
    .io_out_bits_uop_vlWen(g_v29_io_out_bits_uop_vlWen),
    .io_out_bits_uop_flushPipe(g_v29_io_out_bits_uop_flushPipe),
    .io_out_bits_uop_vpu_vill(g_v29_io_out_bits_uop_vpu_vill),
    .io_out_bits_uop_vpu_vma(g_v29_io_out_bits_uop_vpu_vma),
    .io_out_bits_uop_vpu_vta(g_v29_io_out_bits_uop_vpu_vta),
    .io_out_bits_uop_vpu_vsew(g_v29_io_out_bits_uop_vpu_vsew),
    .io_out_bits_uop_vpu_vlmul(g_v29_io_out_bits_uop_vpu_vlmul),
    .io_out_bits_uop_vpu_specVill(g_v29_io_out_bits_uop_vpu_specVill),
    .io_out_bits_uop_vpu_specVma(g_v29_io_out_bits_uop_vpu_specVma),
    .io_out_bits_uop_vpu_specVta(g_v29_io_out_bits_uop_vpu_specVta),
    .io_out_bits_uop_vpu_specVsew(g_v29_io_out_bits_uop_vpu_specVsew),
    .io_out_bits_uop_vpu_specVlmul(g_v29_io_out_bits_uop_vpu_specVlmul),
    .io_out_bits_uop_vpu_vm(g_v29_io_out_bits_uop_vpu_vm),
    .io_out_bits_uop_vpu_vstart(g_v29_io_out_bits_uop_vpu_vstart),
    .io_out_bits_uop_vpu_frm(g_v29_io_out_bits_uop_vpu_frm),
    .io_out_bits_uop_vpu_fpu_isFpToVecInst(g_v29_io_out_bits_uop_vpu_fpu_isFpToVecInst),
    .io_out_bits_uop_vpu_fpu_isFP32Instr(g_v29_io_out_bits_uop_vpu_fpu_isFP32Instr),
    .io_out_bits_uop_vpu_fpu_isFP64Instr(g_v29_io_out_bits_uop_vpu_fpu_isFP64Instr),
    .io_out_bits_uop_vpu_fpu_isReduction(g_v29_io_out_bits_uop_vpu_fpu_isReduction),
    .io_out_bits_uop_vpu_fpu_isFoldTo1_2(g_v29_io_out_bits_uop_vpu_fpu_isFoldTo1_2),
    .io_out_bits_uop_vpu_fpu_isFoldTo1_4(g_v29_io_out_bits_uop_vpu_fpu_isFoldTo1_4),
    .io_out_bits_uop_vpu_fpu_isFoldTo1_8(g_v29_io_out_bits_uop_vpu_fpu_isFoldTo1_8),
    .io_out_bits_uop_vpu_vxrm(g_v29_io_out_bits_uop_vpu_vxrm),
    .io_out_bits_uop_vpu_vuopIdx(g_v29_io_out_bits_uop_vpu_vuopIdx),
    .io_out_bits_uop_vpu_lastUop(g_v29_io_out_bits_uop_vpu_lastUop),
    .io_out_bits_uop_vpu_vmask(g_v29_io_out_bits_uop_vpu_vmask),
    .io_out_bits_uop_vpu_vl(g_v29_io_out_bits_uop_vpu_vl),
    .io_out_bits_uop_vpu_nf(g_v29_io_out_bits_uop_vpu_nf),
    .io_out_bits_uop_vpu_veew(g_v29_io_out_bits_uop_vpu_veew),
    .io_out_bits_uop_vpu_isReverse(g_v29_io_out_bits_uop_vpu_isReverse),
    .io_out_bits_uop_vpu_isExt(g_v29_io_out_bits_uop_vpu_isExt),
    .io_out_bits_uop_vpu_isNarrow(g_v29_io_out_bits_uop_vpu_isNarrow),
    .io_out_bits_uop_vpu_isDstMask(g_v29_io_out_bits_uop_vpu_isDstMask),
    .io_out_bits_uop_vpu_isOpMask(g_v29_io_out_bits_uop_vpu_isOpMask),
    .io_out_bits_uop_vpu_isMove(g_v29_io_out_bits_uop_vpu_isMove),
    .io_out_bits_uop_vpu_isDependOldVd(g_v29_io_out_bits_uop_vpu_isDependOldVd),
    .io_out_bits_uop_vpu_isWritePartVd(g_v29_io_out_bits_uop_vpu_isWritePartVd),
    .io_out_bits_uop_vpu_isVleff(g_v29_io_out_bits_uop_vpu_isVleff),
    .io_out_bits_uop_psrc_2(g_v29_io_out_bits_uop_psrc_2),
    .io_out_bits_uop_pdest(g_v29_io_out_bits_uop_pdest),
    .io_out_bits_uop_robIdx_flag(g_v29_io_out_bits_uop_robIdx_flag),
    .io_out_bits_uop_robIdx_value(g_v29_io_out_bits_uop_robIdx_value),
    .io_out_bits_uop_debugInfo_eliminatedMove(g_v29_io_out_bits_uop_debugInfo_eliminatedMove),
    .io_out_bits_uop_debugInfo_renameTime(g_v29_io_out_bits_uop_debugInfo_renameTime),
    .io_out_bits_uop_debugInfo_dispatchTime(g_v29_io_out_bits_uop_debugInfo_dispatchTime),
    .io_out_bits_uop_debugInfo_enqRsTime(g_v29_io_out_bits_uop_debugInfo_enqRsTime),
    .io_out_bits_uop_debugInfo_selectTime(g_v29_io_out_bits_uop_debugInfo_selectTime),
    .io_out_bits_uop_debugInfo_issueTime(g_v29_io_out_bits_uop_debugInfo_issueTime),
    .io_out_bits_uop_debugInfo_writebackTime(g_v29_io_out_bits_uop_debugInfo_writebackTime),
    .io_out_bits_uop_debugInfo_runahead_checkpoint_id(g_v29_io_out_bits_uop_debugInfo_runahead_checkpoint_id),
    .io_out_bits_uop_debugInfo_tlbFirstReqTime(g_v29_io_out_bits_uop_debugInfo_tlbFirstReqTime),
    .io_out_bits_uop_debugInfo_tlbRespTime(g_v29_io_out_bits_uop_debugInfo_tlbRespTime),
    .io_out_bits_uop_debug_seqNum_seqNum(g_v29_io_out_bits_uop_debug_seqNum_seqNum),
    .io_out_bits_uop_debug_seqNum_uopIdx(g_v29_io_out_bits_uop_debug_seqNum_uopIdx),
    .io_out_bits_uop_replayInst(g_v29_io_out_bits_uop_replayInst),
    .io_out_bits_data(g_v29_io_out_bits_data),
    .io_out_bits_vdIdx(g_v29_io_out_bits_vdIdx),
    .io_out_bits_vdIdxInField(g_v29_io_out_bits_vdIdxInField)
  );
  NewPipelineConnectPipe_29_xs u_i_v29 (
    .clock(clock), .reset(reset),
    .io_in_valid(v29_io_in_valid),
    .io_in_bits_uop_exceptionVec_3(v29_io_in_bits_uop_exceptionVec_3),
    .io_in_bits_uop_exceptionVec_4(v29_io_in_bits_uop_exceptionVec_4),
    .io_in_bits_uop_exceptionVec_5(v29_io_in_bits_uop_exceptionVec_5),
    .io_in_bits_uop_exceptionVec_6(v29_io_in_bits_uop_exceptionVec_6),
    .io_in_bits_uop_exceptionVec_7(v29_io_in_bits_uop_exceptionVec_7),
    .io_in_bits_uop_exceptionVec_13(v29_io_in_bits_uop_exceptionVec_13),
    .io_in_bits_uop_exceptionVec_15(v29_io_in_bits_uop_exceptionVec_15),
    .io_in_bits_uop_exceptionVec_19(v29_io_in_bits_uop_exceptionVec_19),
    .io_in_bits_uop_exceptionVec_21(v29_io_in_bits_uop_exceptionVec_21),
    .io_in_bits_uop_exceptionVec_23(v29_io_in_bits_uop_exceptionVec_23),
    .io_in_bits_uop_trigger(v29_io_in_bits_uop_trigger),
    .io_in_bits_uop_fuOpType(v29_io_in_bits_uop_fuOpType),
    .io_in_bits_uop_vecWen(v29_io_in_bits_uop_vecWen),
    .io_in_bits_uop_v0Wen(v29_io_in_bits_uop_v0Wen),
    .io_in_bits_uop_vlWen(v29_io_in_bits_uop_vlWen),
    .io_in_bits_uop_flushPipe(v29_io_in_bits_uop_flushPipe),
    .io_in_bits_uop_vpu_vill(v29_io_in_bits_uop_vpu_vill),
    .io_in_bits_uop_vpu_vma(v29_io_in_bits_uop_vpu_vma),
    .io_in_bits_uop_vpu_vta(v29_io_in_bits_uop_vpu_vta),
    .io_in_bits_uop_vpu_vsew(v29_io_in_bits_uop_vpu_vsew),
    .io_in_bits_uop_vpu_vlmul(v29_io_in_bits_uop_vpu_vlmul),
    .io_in_bits_uop_vpu_specVill(v29_io_in_bits_uop_vpu_specVill),
    .io_in_bits_uop_vpu_specVma(v29_io_in_bits_uop_vpu_specVma),
    .io_in_bits_uop_vpu_specVta(v29_io_in_bits_uop_vpu_specVta),
    .io_in_bits_uop_vpu_specVsew(v29_io_in_bits_uop_vpu_specVsew),
    .io_in_bits_uop_vpu_specVlmul(v29_io_in_bits_uop_vpu_specVlmul),
    .io_in_bits_uop_vpu_vm(v29_io_in_bits_uop_vpu_vm),
    .io_in_bits_uop_vpu_vstart(v29_io_in_bits_uop_vpu_vstart),
    .io_in_bits_uop_vpu_frm(v29_io_in_bits_uop_vpu_frm),
    .io_in_bits_uop_vpu_fpu_isFpToVecInst(v29_io_in_bits_uop_vpu_fpu_isFpToVecInst),
    .io_in_bits_uop_vpu_fpu_isFP32Instr(v29_io_in_bits_uop_vpu_fpu_isFP32Instr),
    .io_in_bits_uop_vpu_fpu_isFP64Instr(v29_io_in_bits_uop_vpu_fpu_isFP64Instr),
    .io_in_bits_uop_vpu_fpu_isReduction(v29_io_in_bits_uop_vpu_fpu_isReduction),
    .io_in_bits_uop_vpu_fpu_isFoldTo1_2(v29_io_in_bits_uop_vpu_fpu_isFoldTo1_2),
    .io_in_bits_uop_vpu_fpu_isFoldTo1_4(v29_io_in_bits_uop_vpu_fpu_isFoldTo1_4),
    .io_in_bits_uop_vpu_fpu_isFoldTo1_8(v29_io_in_bits_uop_vpu_fpu_isFoldTo1_8),
    .io_in_bits_uop_vpu_vxrm(v29_io_in_bits_uop_vpu_vxrm),
    .io_in_bits_uop_vpu_vuopIdx(v29_io_in_bits_uop_vpu_vuopIdx),
    .io_in_bits_uop_vpu_lastUop(v29_io_in_bits_uop_vpu_lastUop),
    .io_in_bits_uop_vpu_vmask(v29_io_in_bits_uop_vpu_vmask),
    .io_in_bits_uop_vpu_vl(v29_io_in_bits_uop_vpu_vl),
    .io_in_bits_uop_vpu_nf(v29_io_in_bits_uop_vpu_nf),
    .io_in_bits_uop_vpu_veew(v29_io_in_bits_uop_vpu_veew),
    .io_in_bits_uop_vpu_isReverse(v29_io_in_bits_uop_vpu_isReverse),
    .io_in_bits_uop_vpu_isExt(v29_io_in_bits_uop_vpu_isExt),
    .io_in_bits_uop_vpu_isNarrow(v29_io_in_bits_uop_vpu_isNarrow),
    .io_in_bits_uop_vpu_isDstMask(v29_io_in_bits_uop_vpu_isDstMask),
    .io_in_bits_uop_vpu_isOpMask(v29_io_in_bits_uop_vpu_isOpMask),
    .io_in_bits_uop_vpu_isMove(v29_io_in_bits_uop_vpu_isMove),
    .io_in_bits_uop_vpu_isDependOldVd(v29_io_in_bits_uop_vpu_isDependOldVd),
    .io_in_bits_uop_vpu_isWritePartVd(v29_io_in_bits_uop_vpu_isWritePartVd),
    .io_in_bits_uop_vpu_isVleff(v29_io_in_bits_uop_vpu_isVleff),
    .io_in_bits_uop_psrc_2(v29_io_in_bits_uop_psrc_2),
    .io_in_bits_uop_pdest(v29_io_in_bits_uop_pdest),
    .io_in_bits_uop_robIdx_flag(v29_io_in_bits_uop_robIdx_flag),
    .io_in_bits_uop_robIdx_value(v29_io_in_bits_uop_robIdx_value),
    .io_in_bits_uop_debugInfo_eliminatedMove(v29_io_in_bits_uop_debugInfo_eliminatedMove),
    .io_in_bits_uop_debugInfo_renameTime(v29_io_in_bits_uop_debugInfo_renameTime),
    .io_in_bits_uop_debugInfo_dispatchTime(v29_io_in_bits_uop_debugInfo_dispatchTime),
    .io_in_bits_uop_debugInfo_enqRsTime(v29_io_in_bits_uop_debugInfo_enqRsTime),
    .io_in_bits_uop_debugInfo_selectTime(v29_io_in_bits_uop_debugInfo_selectTime),
    .io_in_bits_uop_debugInfo_issueTime(v29_io_in_bits_uop_debugInfo_issueTime),
    .io_in_bits_uop_debugInfo_writebackTime(v29_io_in_bits_uop_debugInfo_writebackTime),
    .io_in_bits_uop_debugInfo_runahead_checkpoint_id(v29_io_in_bits_uop_debugInfo_runahead_checkpoint_id),
    .io_in_bits_uop_debugInfo_tlbFirstReqTime(v29_io_in_bits_uop_debugInfo_tlbFirstReqTime),
    .io_in_bits_uop_debugInfo_tlbRespTime(v29_io_in_bits_uop_debugInfo_tlbRespTime),
    .io_in_bits_uop_debug_seqNum_seqNum(v29_io_in_bits_uop_debug_seqNum_seqNum),
    .io_in_bits_uop_debug_seqNum_uopIdx(v29_io_in_bits_uop_debug_seqNum_uopIdx),
    .io_in_bits_uop_replayInst(v29_io_in_bits_uop_replayInst),
    .io_in_bits_data(v29_io_in_bits_data),
    .io_in_bits_vdIdx(v29_io_in_bits_vdIdx),
    .io_in_bits_vdIdxInField(v29_io_in_bits_vdIdxInField),
    .io_out_ready(v29_io_out_ready),
    .io_rightOutFire(v29_io_rightOutFire),
    .io_isFlush(v29_io_isFlush),
    .io_in_ready(i_v29_io_in_ready),
    .io_out_valid(i_v29_io_out_valid),
    .io_out_bits_uop_exceptionVec_3(i_v29_io_out_bits_uop_exceptionVec_3),
    .io_out_bits_uop_exceptionVec_4(i_v29_io_out_bits_uop_exceptionVec_4),
    .io_out_bits_uop_exceptionVec_5(i_v29_io_out_bits_uop_exceptionVec_5),
    .io_out_bits_uop_exceptionVec_6(i_v29_io_out_bits_uop_exceptionVec_6),
    .io_out_bits_uop_exceptionVec_7(i_v29_io_out_bits_uop_exceptionVec_7),
    .io_out_bits_uop_exceptionVec_13(i_v29_io_out_bits_uop_exceptionVec_13),
    .io_out_bits_uop_exceptionVec_15(i_v29_io_out_bits_uop_exceptionVec_15),
    .io_out_bits_uop_exceptionVec_19(i_v29_io_out_bits_uop_exceptionVec_19),
    .io_out_bits_uop_exceptionVec_21(i_v29_io_out_bits_uop_exceptionVec_21),
    .io_out_bits_uop_exceptionVec_23(i_v29_io_out_bits_uop_exceptionVec_23),
    .io_out_bits_uop_trigger(i_v29_io_out_bits_uop_trigger),
    .io_out_bits_uop_fuOpType(i_v29_io_out_bits_uop_fuOpType),
    .io_out_bits_uop_vecWen(i_v29_io_out_bits_uop_vecWen),
    .io_out_bits_uop_v0Wen(i_v29_io_out_bits_uop_v0Wen),
    .io_out_bits_uop_vlWen(i_v29_io_out_bits_uop_vlWen),
    .io_out_bits_uop_flushPipe(i_v29_io_out_bits_uop_flushPipe),
    .io_out_bits_uop_vpu_vill(i_v29_io_out_bits_uop_vpu_vill),
    .io_out_bits_uop_vpu_vma(i_v29_io_out_bits_uop_vpu_vma),
    .io_out_bits_uop_vpu_vta(i_v29_io_out_bits_uop_vpu_vta),
    .io_out_bits_uop_vpu_vsew(i_v29_io_out_bits_uop_vpu_vsew),
    .io_out_bits_uop_vpu_vlmul(i_v29_io_out_bits_uop_vpu_vlmul),
    .io_out_bits_uop_vpu_specVill(i_v29_io_out_bits_uop_vpu_specVill),
    .io_out_bits_uop_vpu_specVma(i_v29_io_out_bits_uop_vpu_specVma),
    .io_out_bits_uop_vpu_specVta(i_v29_io_out_bits_uop_vpu_specVta),
    .io_out_bits_uop_vpu_specVsew(i_v29_io_out_bits_uop_vpu_specVsew),
    .io_out_bits_uop_vpu_specVlmul(i_v29_io_out_bits_uop_vpu_specVlmul),
    .io_out_bits_uop_vpu_vm(i_v29_io_out_bits_uop_vpu_vm),
    .io_out_bits_uop_vpu_vstart(i_v29_io_out_bits_uop_vpu_vstart),
    .io_out_bits_uop_vpu_frm(i_v29_io_out_bits_uop_vpu_frm),
    .io_out_bits_uop_vpu_fpu_isFpToVecInst(i_v29_io_out_bits_uop_vpu_fpu_isFpToVecInst),
    .io_out_bits_uop_vpu_fpu_isFP32Instr(i_v29_io_out_bits_uop_vpu_fpu_isFP32Instr),
    .io_out_bits_uop_vpu_fpu_isFP64Instr(i_v29_io_out_bits_uop_vpu_fpu_isFP64Instr),
    .io_out_bits_uop_vpu_fpu_isReduction(i_v29_io_out_bits_uop_vpu_fpu_isReduction),
    .io_out_bits_uop_vpu_fpu_isFoldTo1_2(i_v29_io_out_bits_uop_vpu_fpu_isFoldTo1_2),
    .io_out_bits_uop_vpu_fpu_isFoldTo1_4(i_v29_io_out_bits_uop_vpu_fpu_isFoldTo1_4),
    .io_out_bits_uop_vpu_fpu_isFoldTo1_8(i_v29_io_out_bits_uop_vpu_fpu_isFoldTo1_8),
    .io_out_bits_uop_vpu_vxrm(i_v29_io_out_bits_uop_vpu_vxrm),
    .io_out_bits_uop_vpu_vuopIdx(i_v29_io_out_bits_uop_vpu_vuopIdx),
    .io_out_bits_uop_vpu_lastUop(i_v29_io_out_bits_uop_vpu_lastUop),
    .io_out_bits_uop_vpu_vmask(i_v29_io_out_bits_uop_vpu_vmask),
    .io_out_bits_uop_vpu_vl(i_v29_io_out_bits_uop_vpu_vl),
    .io_out_bits_uop_vpu_nf(i_v29_io_out_bits_uop_vpu_nf),
    .io_out_bits_uop_vpu_veew(i_v29_io_out_bits_uop_vpu_veew),
    .io_out_bits_uop_vpu_isReverse(i_v29_io_out_bits_uop_vpu_isReverse),
    .io_out_bits_uop_vpu_isExt(i_v29_io_out_bits_uop_vpu_isExt),
    .io_out_bits_uop_vpu_isNarrow(i_v29_io_out_bits_uop_vpu_isNarrow),
    .io_out_bits_uop_vpu_isDstMask(i_v29_io_out_bits_uop_vpu_isDstMask),
    .io_out_bits_uop_vpu_isOpMask(i_v29_io_out_bits_uop_vpu_isOpMask),
    .io_out_bits_uop_vpu_isMove(i_v29_io_out_bits_uop_vpu_isMove),
    .io_out_bits_uop_vpu_isDependOldVd(i_v29_io_out_bits_uop_vpu_isDependOldVd),
    .io_out_bits_uop_vpu_isWritePartVd(i_v29_io_out_bits_uop_vpu_isWritePartVd),
    .io_out_bits_uop_vpu_isVleff(i_v29_io_out_bits_uop_vpu_isVleff),
    .io_out_bits_uop_psrc_2(i_v29_io_out_bits_uop_psrc_2),
    .io_out_bits_uop_pdest(i_v29_io_out_bits_uop_pdest),
    .io_out_bits_uop_robIdx_flag(i_v29_io_out_bits_uop_robIdx_flag),
    .io_out_bits_uop_robIdx_value(i_v29_io_out_bits_uop_robIdx_value),
    .io_out_bits_uop_debugInfo_eliminatedMove(i_v29_io_out_bits_uop_debugInfo_eliminatedMove),
    .io_out_bits_uop_debugInfo_renameTime(i_v29_io_out_bits_uop_debugInfo_renameTime),
    .io_out_bits_uop_debugInfo_dispatchTime(i_v29_io_out_bits_uop_debugInfo_dispatchTime),
    .io_out_bits_uop_debugInfo_enqRsTime(i_v29_io_out_bits_uop_debugInfo_enqRsTime),
    .io_out_bits_uop_debugInfo_selectTime(i_v29_io_out_bits_uop_debugInfo_selectTime),
    .io_out_bits_uop_debugInfo_issueTime(i_v29_io_out_bits_uop_debugInfo_issueTime),
    .io_out_bits_uop_debugInfo_writebackTime(i_v29_io_out_bits_uop_debugInfo_writebackTime),
    .io_out_bits_uop_debugInfo_runahead_checkpoint_id(i_v29_io_out_bits_uop_debugInfo_runahead_checkpoint_id),
    .io_out_bits_uop_debugInfo_tlbFirstReqTime(i_v29_io_out_bits_uop_debugInfo_tlbFirstReqTime),
    .io_out_bits_uop_debugInfo_tlbRespTime(i_v29_io_out_bits_uop_debugInfo_tlbRespTime),
    .io_out_bits_uop_debug_seqNum_seqNum(i_v29_io_out_bits_uop_debug_seqNum_seqNum),
    .io_out_bits_uop_debug_seqNum_uopIdx(i_v29_io_out_bits_uop_debug_seqNum_uopIdx),
    .io_out_bits_uop_replayInst(i_v29_io_out_bits_uop_replayInst),
    .io_out_bits_data(i_v29_io_out_bits_data),
    .io_out_bits_vdIdx(i_v29_io_out_bits_vdIdx),
    .io_out_bits_vdIdxInField(i_v29_io_out_bits_vdIdxInField)
  );

  // ==========================================================================
  // NewPipelineConnectPipe_34 —— 46 字段 / 760 位 payload（golden 无 io_isFlush）
  // ==========================================================================
  logic v34_io_in_valid;
  logic v34_io_in_bits_uop_exceptionVec_0;
  logic v34_io_in_bits_uop_exceptionVec_1;
  logic v34_io_in_bits_uop_exceptionVec_2;
  logic v34_io_in_bits_uop_exceptionVec_3;
  logic v34_io_in_bits_uop_exceptionVec_4;
  logic v34_io_in_bits_uop_exceptionVec_5;
  logic v34_io_in_bits_uop_exceptionVec_6;
  logic v34_io_in_bits_uop_exceptionVec_7;
  logic v34_io_in_bits_uop_exceptionVec_8;
  logic v34_io_in_bits_uop_exceptionVec_9;
  logic v34_io_in_bits_uop_exceptionVec_10;
  logic v34_io_in_bits_uop_exceptionVec_11;
  logic v34_io_in_bits_uop_exceptionVec_12;
  logic v34_io_in_bits_uop_exceptionVec_13;
  logic v34_io_in_bits_uop_exceptionVec_14;
  logic v34_io_in_bits_uop_exceptionVec_15;
  logic v34_io_in_bits_uop_exceptionVec_16;
  logic v34_io_in_bits_uop_exceptionVec_17;
  logic v34_io_in_bits_uop_exceptionVec_18;
  logic v34_io_in_bits_uop_exceptionVec_19;
  logic v34_io_in_bits_uop_exceptionVec_20;
  logic v34_io_in_bits_uop_exceptionVec_21;
  logic v34_io_in_bits_uop_exceptionVec_22;
  logic v34_io_in_bits_uop_exceptionVec_23;
  logic [3:0] v34_io_in_bits_uop_trigger;
  logic v34_io_in_bits_uop_rfWen;
  logic v34_io_in_bits_uop_flushPipe;
  logic [7:0] v34_io_in_bits_uop_pdest;
  logic v34_io_in_bits_uop_robIdx_flag;
  logic [7:0] v34_io_in_bits_uop_robIdx_value;
  logic v34_io_in_bits_uop_debugInfo_eliminatedMove;
  logic [63:0] v34_io_in_bits_uop_debugInfo_renameTime;
  logic [63:0] v34_io_in_bits_uop_debugInfo_dispatchTime;
  logic [63:0] v34_io_in_bits_uop_debugInfo_enqRsTime;
  logic [63:0] v34_io_in_bits_uop_debugInfo_selectTime;
  logic [63:0] v34_io_in_bits_uop_debugInfo_issueTime;
  logic [63:0] v34_io_in_bits_uop_debugInfo_writebackTime;
  logic [63:0] v34_io_in_bits_uop_debugInfo_runahead_checkpoint_id;
  logic [63:0] v34_io_in_bits_uop_debugInfo_tlbFirstReqTime;
  logic [63:0] v34_io_in_bits_uop_debugInfo_tlbRespTime;
  logic [55:0] v34_io_in_bits_uop_debug_seqNum_seqNum;
  logic [7:0] v34_io_in_bits_uop_debug_seqNum_uopIdx;
  logic v34_io_in_bits_uop_sqIdx_flag;
  logic [5:0] v34_io_in_bits_uop_sqIdx_value;
  logic [63:0] v34_io_in_bits_data;
  logic v34_io_in_bits_debug_isMMIO;
  logic v34_io_out_ready;
  logic v34_io_rightOutFire;
  wire  g_v34_io_in_ready, i_v34_io_in_ready;
  wire  g_v34_io_out_valid, i_v34_io_out_valid;
  wire  g_v34_io_out_bits_uop_exceptionVec_0, i_v34_io_out_bits_uop_exceptionVec_0;
  wire  g_v34_io_out_bits_uop_exceptionVec_1, i_v34_io_out_bits_uop_exceptionVec_1;
  wire  g_v34_io_out_bits_uop_exceptionVec_2, i_v34_io_out_bits_uop_exceptionVec_2;
  wire  g_v34_io_out_bits_uop_exceptionVec_3, i_v34_io_out_bits_uop_exceptionVec_3;
  wire  g_v34_io_out_bits_uop_exceptionVec_4, i_v34_io_out_bits_uop_exceptionVec_4;
  wire  g_v34_io_out_bits_uop_exceptionVec_5, i_v34_io_out_bits_uop_exceptionVec_5;
  wire  g_v34_io_out_bits_uop_exceptionVec_6, i_v34_io_out_bits_uop_exceptionVec_6;
  wire  g_v34_io_out_bits_uop_exceptionVec_7, i_v34_io_out_bits_uop_exceptionVec_7;
  wire  g_v34_io_out_bits_uop_exceptionVec_8, i_v34_io_out_bits_uop_exceptionVec_8;
  wire  g_v34_io_out_bits_uop_exceptionVec_9, i_v34_io_out_bits_uop_exceptionVec_9;
  wire  g_v34_io_out_bits_uop_exceptionVec_10, i_v34_io_out_bits_uop_exceptionVec_10;
  wire  g_v34_io_out_bits_uop_exceptionVec_11, i_v34_io_out_bits_uop_exceptionVec_11;
  wire  g_v34_io_out_bits_uop_exceptionVec_12, i_v34_io_out_bits_uop_exceptionVec_12;
  wire  g_v34_io_out_bits_uop_exceptionVec_13, i_v34_io_out_bits_uop_exceptionVec_13;
  wire  g_v34_io_out_bits_uop_exceptionVec_14, i_v34_io_out_bits_uop_exceptionVec_14;
  wire  g_v34_io_out_bits_uop_exceptionVec_15, i_v34_io_out_bits_uop_exceptionVec_15;
  wire  g_v34_io_out_bits_uop_exceptionVec_16, i_v34_io_out_bits_uop_exceptionVec_16;
  wire  g_v34_io_out_bits_uop_exceptionVec_17, i_v34_io_out_bits_uop_exceptionVec_17;
  wire  g_v34_io_out_bits_uop_exceptionVec_18, i_v34_io_out_bits_uop_exceptionVec_18;
  wire  g_v34_io_out_bits_uop_exceptionVec_19, i_v34_io_out_bits_uop_exceptionVec_19;
  wire  g_v34_io_out_bits_uop_exceptionVec_20, i_v34_io_out_bits_uop_exceptionVec_20;
  wire  g_v34_io_out_bits_uop_exceptionVec_21, i_v34_io_out_bits_uop_exceptionVec_21;
  wire  g_v34_io_out_bits_uop_exceptionVec_22, i_v34_io_out_bits_uop_exceptionVec_22;
  wire  g_v34_io_out_bits_uop_exceptionVec_23, i_v34_io_out_bits_uop_exceptionVec_23;
  wire  [3:0] g_v34_io_out_bits_uop_trigger, i_v34_io_out_bits_uop_trigger;
  wire  g_v34_io_out_bits_uop_rfWen, i_v34_io_out_bits_uop_rfWen;
  wire  g_v34_io_out_bits_uop_flushPipe, i_v34_io_out_bits_uop_flushPipe;
  wire  [7:0] g_v34_io_out_bits_uop_pdest, i_v34_io_out_bits_uop_pdest;
  wire  g_v34_io_out_bits_uop_robIdx_flag, i_v34_io_out_bits_uop_robIdx_flag;
  wire  [7:0] g_v34_io_out_bits_uop_robIdx_value, i_v34_io_out_bits_uop_robIdx_value;
  wire  g_v34_io_out_bits_uop_debugInfo_eliminatedMove, i_v34_io_out_bits_uop_debugInfo_eliminatedMove;
  wire  [63:0] g_v34_io_out_bits_uop_debugInfo_renameTime, i_v34_io_out_bits_uop_debugInfo_renameTime;
  wire  [63:0] g_v34_io_out_bits_uop_debugInfo_dispatchTime, i_v34_io_out_bits_uop_debugInfo_dispatchTime;
  wire  [63:0] g_v34_io_out_bits_uop_debugInfo_enqRsTime, i_v34_io_out_bits_uop_debugInfo_enqRsTime;
  wire  [63:0] g_v34_io_out_bits_uop_debugInfo_selectTime, i_v34_io_out_bits_uop_debugInfo_selectTime;
  wire  [63:0] g_v34_io_out_bits_uop_debugInfo_issueTime, i_v34_io_out_bits_uop_debugInfo_issueTime;
  wire  [63:0] g_v34_io_out_bits_uop_debugInfo_writebackTime, i_v34_io_out_bits_uop_debugInfo_writebackTime;
  wire  [63:0] g_v34_io_out_bits_uop_debugInfo_runahead_checkpoint_id, i_v34_io_out_bits_uop_debugInfo_runahead_checkpoint_id;
  wire  [63:0] g_v34_io_out_bits_uop_debugInfo_tlbFirstReqTime, i_v34_io_out_bits_uop_debugInfo_tlbFirstReqTime;
  wire  [63:0] g_v34_io_out_bits_uop_debugInfo_tlbRespTime, i_v34_io_out_bits_uop_debugInfo_tlbRespTime;
  wire  [55:0] g_v34_io_out_bits_uop_debug_seqNum_seqNum, i_v34_io_out_bits_uop_debug_seqNum_seqNum;
  wire  [7:0] g_v34_io_out_bits_uop_debug_seqNum_uopIdx, i_v34_io_out_bits_uop_debug_seqNum_uopIdx;
  wire  g_v34_io_out_bits_uop_sqIdx_flag, i_v34_io_out_bits_uop_sqIdx_flag;
  wire  [5:0] g_v34_io_out_bits_uop_sqIdx_value, i_v34_io_out_bits_uop_sqIdx_value;
  wire  [63:0] g_v34_io_out_bits_data, i_v34_io_out_bits_data;
  wire  g_v34_io_out_bits_debug_isMMIO, i_v34_io_out_bits_debug_isMMIO;
  longint nchk_v34 = 0; int nerr_v34 = 0;
  longint fire_v34 = 0, bp_v34 = 0, hold_v34 = 0, deq_v34 = 0, owr_v34 = 0;
  logic [759:0] por_v34 = '0, pand_v34 = '1;   // payload 逐位或 / 逐位与
  wire  [759:0] pcat_v34 = {v34_io_in_bits_uop_exceptionVec_0, v34_io_in_bits_uop_exceptionVec_1, v34_io_in_bits_uop_exceptionVec_2, v34_io_in_bits_uop_exceptionVec_3, v34_io_in_bits_uop_exceptionVec_4, v34_io_in_bits_uop_exceptionVec_5, v34_io_in_bits_uop_exceptionVec_6, v34_io_in_bits_uop_exceptionVec_7, v34_io_in_bits_uop_exceptionVec_8, v34_io_in_bits_uop_exceptionVec_9, v34_io_in_bits_uop_exceptionVec_10, v34_io_in_bits_uop_exceptionVec_11, v34_io_in_bits_uop_exceptionVec_12, v34_io_in_bits_uop_exceptionVec_13, v34_io_in_bits_uop_exceptionVec_14, v34_io_in_bits_uop_exceptionVec_15, v34_io_in_bits_uop_exceptionVec_16, v34_io_in_bits_uop_exceptionVec_17, v34_io_in_bits_uop_exceptionVec_18, v34_io_in_bits_uop_exceptionVec_19, v34_io_in_bits_uop_exceptionVec_20, v34_io_in_bits_uop_exceptionVec_21, v34_io_in_bits_uop_exceptionVec_22, v34_io_in_bits_uop_exceptionVec_23, v34_io_in_bits_uop_trigger, v34_io_in_bits_uop_rfWen, v34_io_in_bits_uop_flushPipe, v34_io_in_bits_uop_pdest, v34_io_in_bits_uop_robIdx_flag, v34_io_in_bits_uop_robIdx_value, v34_io_in_bits_uop_debugInfo_eliminatedMove, v34_io_in_bits_uop_debugInfo_renameTime, v34_io_in_bits_uop_debugInfo_dispatchTime, v34_io_in_bits_uop_debugInfo_enqRsTime, v34_io_in_bits_uop_debugInfo_selectTime, v34_io_in_bits_uop_debugInfo_issueTime, v34_io_in_bits_uop_debugInfo_writebackTime, v34_io_in_bits_uop_debugInfo_runahead_checkpoint_id, v34_io_in_bits_uop_debugInfo_tlbFirstReqTime, v34_io_in_bits_uop_debugInfo_tlbRespTime, v34_io_in_bits_uop_debug_seqNum_seqNum, v34_io_in_bits_uop_debug_seqNum_uopIdx, v34_io_in_bits_uop_sqIdx_flag, v34_io_in_bits_uop_sqIdx_value, v34_io_in_bits_data, v34_io_in_bits_debug_isMMIO};
  NewPipelineConnectPipe_34 u_g_v34 (
    .clock(clock), .reset(reset),
    .io_in_valid(v34_io_in_valid),
    .io_in_bits_uop_exceptionVec_0(v34_io_in_bits_uop_exceptionVec_0),
    .io_in_bits_uop_exceptionVec_1(v34_io_in_bits_uop_exceptionVec_1),
    .io_in_bits_uop_exceptionVec_2(v34_io_in_bits_uop_exceptionVec_2),
    .io_in_bits_uop_exceptionVec_3(v34_io_in_bits_uop_exceptionVec_3),
    .io_in_bits_uop_exceptionVec_4(v34_io_in_bits_uop_exceptionVec_4),
    .io_in_bits_uop_exceptionVec_5(v34_io_in_bits_uop_exceptionVec_5),
    .io_in_bits_uop_exceptionVec_6(v34_io_in_bits_uop_exceptionVec_6),
    .io_in_bits_uop_exceptionVec_7(v34_io_in_bits_uop_exceptionVec_7),
    .io_in_bits_uop_exceptionVec_8(v34_io_in_bits_uop_exceptionVec_8),
    .io_in_bits_uop_exceptionVec_9(v34_io_in_bits_uop_exceptionVec_9),
    .io_in_bits_uop_exceptionVec_10(v34_io_in_bits_uop_exceptionVec_10),
    .io_in_bits_uop_exceptionVec_11(v34_io_in_bits_uop_exceptionVec_11),
    .io_in_bits_uop_exceptionVec_12(v34_io_in_bits_uop_exceptionVec_12),
    .io_in_bits_uop_exceptionVec_13(v34_io_in_bits_uop_exceptionVec_13),
    .io_in_bits_uop_exceptionVec_14(v34_io_in_bits_uop_exceptionVec_14),
    .io_in_bits_uop_exceptionVec_15(v34_io_in_bits_uop_exceptionVec_15),
    .io_in_bits_uop_exceptionVec_16(v34_io_in_bits_uop_exceptionVec_16),
    .io_in_bits_uop_exceptionVec_17(v34_io_in_bits_uop_exceptionVec_17),
    .io_in_bits_uop_exceptionVec_18(v34_io_in_bits_uop_exceptionVec_18),
    .io_in_bits_uop_exceptionVec_19(v34_io_in_bits_uop_exceptionVec_19),
    .io_in_bits_uop_exceptionVec_20(v34_io_in_bits_uop_exceptionVec_20),
    .io_in_bits_uop_exceptionVec_21(v34_io_in_bits_uop_exceptionVec_21),
    .io_in_bits_uop_exceptionVec_22(v34_io_in_bits_uop_exceptionVec_22),
    .io_in_bits_uop_exceptionVec_23(v34_io_in_bits_uop_exceptionVec_23),
    .io_in_bits_uop_trigger(v34_io_in_bits_uop_trigger),
    .io_in_bits_uop_rfWen(v34_io_in_bits_uop_rfWen),
    .io_in_bits_uop_flushPipe(v34_io_in_bits_uop_flushPipe),
    .io_in_bits_uop_pdest(v34_io_in_bits_uop_pdest),
    .io_in_bits_uop_robIdx_flag(v34_io_in_bits_uop_robIdx_flag),
    .io_in_bits_uop_robIdx_value(v34_io_in_bits_uop_robIdx_value),
    .io_in_bits_uop_debugInfo_eliminatedMove(v34_io_in_bits_uop_debugInfo_eliminatedMove),
    .io_in_bits_uop_debugInfo_renameTime(v34_io_in_bits_uop_debugInfo_renameTime),
    .io_in_bits_uop_debugInfo_dispatchTime(v34_io_in_bits_uop_debugInfo_dispatchTime),
    .io_in_bits_uop_debugInfo_enqRsTime(v34_io_in_bits_uop_debugInfo_enqRsTime),
    .io_in_bits_uop_debugInfo_selectTime(v34_io_in_bits_uop_debugInfo_selectTime),
    .io_in_bits_uop_debugInfo_issueTime(v34_io_in_bits_uop_debugInfo_issueTime),
    .io_in_bits_uop_debugInfo_writebackTime(v34_io_in_bits_uop_debugInfo_writebackTime),
    .io_in_bits_uop_debugInfo_runahead_checkpoint_id(v34_io_in_bits_uop_debugInfo_runahead_checkpoint_id),
    .io_in_bits_uop_debugInfo_tlbFirstReqTime(v34_io_in_bits_uop_debugInfo_tlbFirstReqTime),
    .io_in_bits_uop_debugInfo_tlbRespTime(v34_io_in_bits_uop_debugInfo_tlbRespTime),
    .io_in_bits_uop_debug_seqNum_seqNum(v34_io_in_bits_uop_debug_seqNum_seqNum),
    .io_in_bits_uop_debug_seqNum_uopIdx(v34_io_in_bits_uop_debug_seqNum_uopIdx),
    .io_in_bits_uop_sqIdx_flag(v34_io_in_bits_uop_sqIdx_flag),
    .io_in_bits_uop_sqIdx_value(v34_io_in_bits_uop_sqIdx_value),
    .io_in_bits_data(v34_io_in_bits_data),
    .io_in_bits_debug_isMMIO(v34_io_in_bits_debug_isMMIO),
    .io_out_ready(v34_io_out_ready),
    .io_rightOutFire(v34_io_rightOutFire),
    .io_in_ready(g_v34_io_in_ready),
    .io_out_valid(g_v34_io_out_valid),
    .io_out_bits_uop_exceptionVec_0(g_v34_io_out_bits_uop_exceptionVec_0),
    .io_out_bits_uop_exceptionVec_1(g_v34_io_out_bits_uop_exceptionVec_1),
    .io_out_bits_uop_exceptionVec_2(g_v34_io_out_bits_uop_exceptionVec_2),
    .io_out_bits_uop_exceptionVec_3(g_v34_io_out_bits_uop_exceptionVec_3),
    .io_out_bits_uop_exceptionVec_4(g_v34_io_out_bits_uop_exceptionVec_4),
    .io_out_bits_uop_exceptionVec_5(g_v34_io_out_bits_uop_exceptionVec_5),
    .io_out_bits_uop_exceptionVec_6(g_v34_io_out_bits_uop_exceptionVec_6),
    .io_out_bits_uop_exceptionVec_7(g_v34_io_out_bits_uop_exceptionVec_7),
    .io_out_bits_uop_exceptionVec_8(g_v34_io_out_bits_uop_exceptionVec_8),
    .io_out_bits_uop_exceptionVec_9(g_v34_io_out_bits_uop_exceptionVec_9),
    .io_out_bits_uop_exceptionVec_10(g_v34_io_out_bits_uop_exceptionVec_10),
    .io_out_bits_uop_exceptionVec_11(g_v34_io_out_bits_uop_exceptionVec_11),
    .io_out_bits_uop_exceptionVec_12(g_v34_io_out_bits_uop_exceptionVec_12),
    .io_out_bits_uop_exceptionVec_13(g_v34_io_out_bits_uop_exceptionVec_13),
    .io_out_bits_uop_exceptionVec_14(g_v34_io_out_bits_uop_exceptionVec_14),
    .io_out_bits_uop_exceptionVec_15(g_v34_io_out_bits_uop_exceptionVec_15),
    .io_out_bits_uop_exceptionVec_16(g_v34_io_out_bits_uop_exceptionVec_16),
    .io_out_bits_uop_exceptionVec_17(g_v34_io_out_bits_uop_exceptionVec_17),
    .io_out_bits_uop_exceptionVec_18(g_v34_io_out_bits_uop_exceptionVec_18),
    .io_out_bits_uop_exceptionVec_19(g_v34_io_out_bits_uop_exceptionVec_19),
    .io_out_bits_uop_exceptionVec_20(g_v34_io_out_bits_uop_exceptionVec_20),
    .io_out_bits_uop_exceptionVec_21(g_v34_io_out_bits_uop_exceptionVec_21),
    .io_out_bits_uop_exceptionVec_22(g_v34_io_out_bits_uop_exceptionVec_22),
    .io_out_bits_uop_exceptionVec_23(g_v34_io_out_bits_uop_exceptionVec_23),
    .io_out_bits_uop_trigger(g_v34_io_out_bits_uop_trigger),
    .io_out_bits_uop_rfWen(g_v34_io_out_bits_uop_rfWen),
    .io_out_bits_uop_flushPipe(g_v34_io_out_bits_uop_flushPipe),
    .io_out_bits_uop_pdest(g_v34_io_out_bits_uop_pdest),
    .io_out_bits_uop_robIdx_flag(g_v34_io_out_bits_uop_robIdx_flag),
    .io_out_bits_uop_robIdx_value(g_v34_io_out_bits_uop_robIdx_value),
    .io_out_bits_uop_debugInfo_eliminatedMove(g_v34_io_out_bits_uop_debugInfo_eliminatedMove),
    .io_out_bits_uop_debugInfo_renameTime(g_v34_io_out_bits_uop_debugInfo_renameTime),
    .io_out_bits_uop_debugInfo_dispatchTime(g_v34_io_out_bits_uop_debugInfo_dispatchTime),
    .io_out_bits_uop_debugInfo_enqRsTime(g_v34_io_out_bits_uop_debugInfo_enqRsTime),
    .io_out_bits_uop_debugInfo_selectTime(g_v34_io_out_bits_uop_debugInfo_selectTime),
    .io_out_bits_uop_debugInfo_issueTime(g_v34_io_out_bits_uop_debugInfo_issueTime),
    .io_out_bits_uop_debugInfo_writebackTime(g_v34_io_out_bits_uop_debugInfo_writebackTime),
    .io_out_bits_uop_debugInfo_runahead_checkpoint_id(g_v34_io_out_bits_uop_debugInfo_runahead_checkpoint_id),
    .io_out_bits_uop_debugInfo_tlbFirstReqTime(g_v34_io_out_bits_uop_debugInfo_tlbFirstReqTime),
    .io_out_bits_uop_debugInfo_tlbRespTime(g_v34_io_out_bits_uop_debugInfo_tlbRespTime),
    .io_out_bits_uop_debug_seqNum_seqNum(g_v34_io_out_bits_uop_debug_seqNum_seqNum),
    .io_out_bits_uop_debug_seqNum_uopIdx(g_v34_io_out_bits_uop_debug_seqNum_uopIdx),
    .io_out_bits_uop_sqIdx_flag(g_v34_io_out_bits_uop_sqIdx_flag),
    .io_out_bits_uop_sqIdx_value(g_v34_io_out_bits_uop_sqIdx_value),
    .io_out_bits_data(g_v34_io_out_bits_data),
    .io_out_bits_debug_isMMIO(g_v34_io_out_bits_debug_isMMIO)
  );
  NewPipelineConnectPipe_34_xs u_i_v34 (
    .clock(clock), .reset(reset),
    .io_in_valid(v34_io_in_valid),
    .io_in_bits_uop_exceptionVec_0(v34_io_in_bits_uop_exceptionVec_0),
    .io_in_bits_uop_exceptionVec_1(v34_io_in_bits_uop_exceptionVec_1),
    .io_in_bits_uop_exceptionVec_2(v34_io_in_bits_uop_exceptionVec_2),
    .io_in_bits_uop_exceptionVec_3(v34_io_in_bits_uop_exceptionVec_3),
    .io_in_bits_uop_exceptionVec_4(v34_io_in_bits_uop_exceptionVec_4),
    .io_in_bits_uop_exceptionVec_5(v34_io_in_bits_uop_exceptionVec_5),
    .io_in_bits_uop_exceptionVec_6(v34_io_in_bits_uop_exceptionVec_6),
    .io_in_bits_uop_exceptionVec_7(v34_io_in_bits_uop_exceptionVec_7),
    .io_in_bits_uop_exceptionVec_8(v34_io_in_bits_uop_exceptionVec_8),
    .io_in_bits_uop_exceptionVec_9(v34_io_in_bits_uop_exceptionVec_9),
    .io_in_bits_uop_exceptionVec_10(v34_io_in_bits_uop_exceptionVec_10),
    .io_in_bits_uop_exceptionVec_11(v34_io_in_bits_uop_exceptionVec_11),
    .io_in_bits_uop_exceptionVec_12(v34_io_in_bits_uop_exceptionVec_12),
    .io_in_bits_uop_exceptionVec_13(v34_io_in_bits_uop_exceptionVec_13),
    .io_in_bits_uop_exceptionVec_14(v34_io_in_bits_uop_exceptionVec_14),
    .io_in_bits_uop_exceptionVec_15(v34_io_in_bits_uop_exceptionVec_15),
    .io_in_bits_uop_exceptionVec_16(v34_io_in_bits_uop_exceptionVec_16),
    .io_in_bits_uop_exceptionVec_17(v34_io_in_bits_uop_exceptionVec_17),
    .io_in_bits_uop_exceptionVec_18(v34_io_in_bits_uop_exceptionVec_18),
    .io_in_bits_uop_exceptionVec_19(v34_io_in_bits_uop_exceptionVec_19),
    .io_in_bits_uop_exceptionVec_20(v34_io_in_bits_uop_exceptionVec_20),
    .io_in_bits_uop_exceptionVec_21(v34_io_in_bits_uop_exceptionVec_21),
    .io_in_bits_uop_exceptionVec_22(v34_io_in_bits_uop_exceptionVec_22),
    .io_in_bits_uop_exceptionVec_23(v34_io_in_bits_uop_exceptionVec_23),
    .io_in_bits_uop_trigger(v34_io_in_bits_uop_trigger),
    .io_in_bits_uop_rfWen(v34_io_in_bits_uop_rfWen),
    .io_in_bits_uop_flushPipe(v34_io_in_bits_uop_flushPipe),
    .io_in_bits_uop_pdest(v34_io_in_bits_uop_pdest),
    .io_in_bits_uop_robIdx_flag(v34_io_in_bits_uop_robIdx_flag),
    .io_in_bits_uop_robIdx_value(v34_io_in_bits_uop_robIdx_value),
    .io_in_bits_uop_debugInfo_eliminatedMove(v34_io_in_bits_uop_debugInfo_eliminatedMove),
    .io_in_bits_uop_debugInfo_renameTime(v34_io_in_bits_uop_debugInfo_renameTime),
    .io_in_bits_uop_debugInfo_dispatchTime(v34_io_in_bits_uop_debugInfo_dispatchTime),
    .io_in_bits_uop_debugInfo_enqRsTime(v34_io_in_bits_uop_debugInfo_enqRsTime),
    .io_in_bits_uop_debugInfo_selectTime(v34_io_in_bits_uop_debugInfo_selectTime),
    .io_in_bits_uop_debugInfo_issueTime(v34_io_in_bits_uop_debugInfo_issueTime),
    .io_in_bits_uop_debugInfo_writebackTime(v34_io_in_bits_uop_debugInfo_writebackTime),
    .io_in_bits_uop_debugInfo_runahead_checkpoint_id(v34_io_in_bits_uop_debugInfo_runahead_checkpoint_id),
    .io_in_bits_uop_debugInfo_tlbFirstReqTime(v34_io_in_bits_uop_debugInfo_tlbFirstReqTime),
    .io_in_bits_uop_debugInfo_tlbRespTime(v34_io_in_bits_uop_debugInfo_tlbRespTime),
    .io_in_bits_uop_debug_seqNum_seqNum(v34_io_in_bits_uop_debug_seqNum_seqNum),
    .io_in_bits_uop_debug_seqNum_uopIdx(v34_io_in_bits_uop_debug_seqNum_uopIdx),
    .io_in_bits_uop_sqIdx_flag(v34_io_in_bits_uop_sqIdx_flag),
    .io_in_bits_uop_sqIdx_value(v34_io_in_bits_uop_sqIdx_value),
    .io_in_bits_data(v34_io_in_bits_data),
    .io_in_bits_debug_isMMIO(v34_io_in_bits_debug_isMMIO),
    .io_out_ready(v34_io_out_ready),
    .io_rightOutFire(v34_io_rightOutFire),
    .io_in_ready(i_v34_io_in_ready),
    .io_out_valid(i_v34_io_out_valid),
    .io_out_bits_uop_exceptionVec_0(i_v34_io_out_bits_uop_exceptionVec_0),
    .io_out_bits_uop_exceptionVec_1(i_v34_io_out_bits_uop_exceptionVec_1),
    .io_out_bits_uop_exceptionVec_2(i_v34_io_out_bits_uop_exceptionVec_2),
    .io_out_bits_uop_exceptionVec_3(i_v34_io_out_bits_uop_exceptionVec_3),
    .io_out_bits_uop_exceptionVec_4(i_v34_io_out_bits_uop_exceptionVec_4),
    .io_out_bits_uop_exceptionVec_5(i_v34_io_out_bits_uop_exceptionVec_5),
    .io_out_bits_uop_exceptionVec_6(i_v34_io_out_bits_uop_exceptionVec_6),
    .io_out_bits_uop_exceptionVec_7(i_v34_io_out_bits_uop_exceptionVec_7),
    .io_out_bits_uop_exceptionVec_8(i_v34_io_out_bits_uop_exceptionVec_8),
    .io_out_bits_uop_exceptionVec_9(i_v34_io_out_bits_uop_exceptionVec_9),
    .io_out_bits_uop_exceptionVec_10(i_v34_io_out_bits_uop_exceptionVec_10),
    .io_out_bits_uop_exceptionVec_11(i_v34_io_out_bits_uop_exceptionVec_11),
    .io_out_bits_uop_exceptionVec_12(i_v34_io_out_bits_uop_exceptionVec_12),
    .io_out_bits_uop_exceptionVec_13(i_v34_io_out_bits_uop_exceptionVec_13),
    .io_out_bits_uop_exceptionVec_14(i_v34_io_out_bits_uop_exceptionVec_14),
    .io_out_bits_uop_exceptionVec_15(i_v34_io_out_bits_uop_exceptionVec_15),
    .io_out_bits_uop_exceptionVec_16(i_v34_io_out_bits_uop_exceptionVec_16),
    .io_out_bits_uop_exceptionVec_17(i_v34_io_out_bits_uop_exceptionVec_17),
    .io_out_bits_uop_exceptionVec_18(i_v34_io_out_bits_uop_exceptionVec_18),
    .io_out_bits_uop_exceptionVec_19(i_v34_io_out_bits_uop_exceptionVec_19),
    .io_out_bits_uop_exceptionVec_20(i_v34_io_out_bits_uop_exceptionVec_20),
    .io_out_bits_uop_exceptionVec_21(i_v34_io_out_bits_uop_exceptionVec_21),
    .io_out_bits_uop_exceptionVec_22(i_v34_io_out_bits_uop_exceptionVec_22),
    .io_out_bits_uop_exceptionVec_23(i_v34_io_out_bits_uop_exceptionVec_23),
    .io_out_bits_uop_trigger(i_v34_io_out_bits_uop_trigger),
    .io_out_bits_uop_rfWen(i_v34_io_out_bits_uop_rfWen),
    .io_out_bits_uop_flushPipe(i_v34_io_out_bits_uop_flushPipe),
    .io_out_bits_uop_pdest(i_v34_io_out_bits_uop_pdest),
    .io_out_bits_uop_robIdx_flag(i_v34_io_out_bits_uop_robIdx_flag),
    .io_out_bits_uop_robIdx_value(i_v34_io_out_bits_uop_robIdx_value),
    .io_out_bits_uop_debugInfo_eliminatedMove(i_v34_io_out_bits_uop_debugInfo_eliminatedMove),
    .io_out_bits_uop_debugInfo_renameTime(i_v34_io_out_bits_uop_debugInfo_renameTime),
    .io_out_bits_uop_debugInfo_dispatchTime(i_v34_io_out_bits_uop_debugInfo_dispatchTime),
    .io_out_bits_uop_debugInfo_enqRsTime(i_v34_io_out_bits_uop_debugInfo_enqRsTime),
    .io_out_bits_uop_debugInfo_selectTime(i_v34_io_out_bits_uop_debugInfo_selectTime),
    .io_out_bits_uop_debugInfo_issueTime(i_v34_io_out_bits_uop_debugInfo_issueTime),
    .io_out_bits_uop_debugInfo_writebackTime(i_v34_io_out_bits_uop_debugInfo_writebackTime),
    .io_out_bits_uop_debugInfo_runahead_checkpoint_id(i_v34_io_out_bits_uop_debugInfo_runahead_checkpoint_id),
    .io_out_bits_uop_debugInfo_tlbFirstReqTime(i_v34_io_out_bits_uop_debugInfo_tlbFirstReqTime),
    .io_out_bits_uop_debugInfo_tlbRespTime(i_v34_io_out_bits_uop_debugInfo_tlbRespTime),
    .io_out_bits_uop_debug_seqNum_seqNum(i_v34_io_out_bits_uop_debug_seqNum_seqNum),
    .io_out_bits_uop_debug_seqNum_uopIdx(i_v34_io_out_bits_uop_debug_seqNum_uopIdx),
    .io_out_bits_uop_sqIdx_flag(i_v34_io_out_bits_uop_sqIdx_flag),
    .io_out_bits_uop_sqIdx_value(i_v34_io_out_bits_uop_sqIdx_value),
    .io_out_bits_data(i_v34_io_out_bits_data),
    .io_out_bits_debug_isMMIO(i_v34_io_out_bits_debug_isMMIO)
  );

  // ==========================================================================
  // NewPipelineConnectPipe_35 —— 174 字段 / 1446 位 payload
  // ==========================================================================
  logic v35_io_in_valid;
  logic [63:0] v35_io_in_bits_vaddr;
  logic [49:0] v35_io_in_bits_basevaddr;
  logic [15:0] v35_io_in_bits_mask;
  logic [3:0] v35_io_in_bits_reg_offset;
  logic [2:0] v35_io_in_bits_alignedType;
  logic v35_io_in_bits_vecActive;
  logic v35_io_in_bits_vecIsFirstActiveElement;
  logic [31:0] v35_io_in_bits_uop_instr;
  logic [49:0] v35_io_in_bits_uop_pc;
  logic [9:0] v35_io_in_bits_uop_foldpc;
  logic v35_io_in_bits_uop_exceptionVec_4;
  logic v35_io_in_bits_uop_exceptionVec_5;
  logic v35_io_in_bits_uop_exceptionVec_6;
  logic v35_io_in_bits_uop_exceptionVec_7;
  logic v35_io_in_bits_uop_exceptionVec_13;
  logic v35_io_in_bits_uop_exceptionVec_15;
  logic v35_io_in_bits_uop_exceptionVec_19;
  logic v35_io_in_bits_uop_exceptionVec_21;
  logic v35_io_in_bits_uop_exceptionVec_23;
  logic v35_io_in_bits_uop_isFetchMalAddr;
  logic v35_io_in_bits_uop_hasException;
  logic [3:0] v35_io_in_bits_uop_trigger;
  logic v35_io_in_bits_uop_preDecodeInfo_valid;
  logic v35_io_in_bits_uop_preDecodeInfo_isRVC;
  logic [1:0] v35_io_in_bits_uop_preDecodeInfo_brType;
  logic v35_io_in_bits_uop_preDecodeInfo_isCall;
  logic v35_io_in_bits_uop_preDecodeInfo_isRet;
  logic v35_io_in_bits_uop_pred_taken;
  logic v35_io_in_bits_uop_crossPageIPFFix;
  logic v35_io_in_bits_uop_ftqPtr_flag;
  logic [5:0] v35_io_in_bits_uop_ftqPtr_value;
  logic [3:0] v35_io_in_bits_uop_ftqOffset;
  logic v35_io_in_bits_uop_satpFlushFirstFetchFault;
  logic [3:0] v35_io_in_bits_uop_srcType_0;
  logic [3:0] v35_io_in_bits_uop_srcType_1;
  logic [3:0] v35_io_in_bits_uop_srcType_2;
  logic [3:0] v35_io_in_bits_uop_srcType_3;
  logic [3:0] v35_io_in_bits_uop_srcType_4;
  logic [5:0] v35_io_in_bits_uop_ldest;
  logic [34:0] v35_io_in_bits_uop_fuType;
  logic [8:0] v35_io_in_bits_uop_fuOpType;
  logic v35_io_in_bits_uop_rfWen;
  logic v35_io_in_bits_uop_fpWen;
  logic v35_io_in_bits_uop_vecWen;
  logic v35_io_in_bits_uop_v0Wen;
  logic v35_io_in_bits_uop_vlWen;
  logic v35_io_in_bits_uop_isXSTrap;
  logic v35_io_in_bits_uop_waitForward;
  logic v35_io_in_bits_uop_blockBackward;
  logic v35_io_in_bits_uop_canRobCompress;
  logic [3:0] v35_io_in_bits_uop_selImm;
  logic [1:0] v35_io_in_bits_uop_fpu_typeTagOut;
  logic v35_io_in_bits_uop_fpu_wflags;
  logic [1:0] v35_io_in_bits_uop_fpu_typ;
  logic [1:0] v35_io_in_bits_uop_fpu_fmt;
  logic [2:0] v35_io_in_bits_uop_fpu_rm;
  logic v35_io_in_bits_uop_vpu_vill;
  logic v35_io_in_bits_uop_vpu_vma;
  logic v35_io_in_bits_uop_vpu_vta;
  logic [1:0] v35_io_in_bits_uop_vpu_vsew;
  logic [2:0] v35_io_in_bits_uop_vpu_vlmul;
  logic v35_io_in_bits_uop_vpu_specVill;
  logic v35_io_in_bits_uop_vpu_specVma;
  logic v35_io_in_bits_uop_vpu_specVta;
  logic [1:0] v35_io_in_bits_uop_vpu_specVsew;
  logic [2:0] v35_io_in_bits_uop_vpu_specVlmul;
  logic v35_io_in_bits_uop_vpu_vm;
  logic [7:0] v35_io_in_bits_uop_vpu_vstart;
  logic [2:0] v35_io_in_bits_uop_vpu_frm;
  logic v35_io_in_bits_uop_vpu_fpu_isFpToVecInst;
  logic v35_io_in_bits_uop_vpu_fpu_isFP32Instr;
  logic v35_io_in_bits_uop_vpu_fpu_isFP64Instr;
  logic v35_io_in_bits_uop_vpu_fpu_isReduction;
  logic v35_io_in_bits_uop_vpu_fpu_isFoldTo1_2;
  logic v35_io_in_bits_uop_vpu_fpu_isFoldTo1_4;
  logic v35_io_in_bits_uop_vpu_fpu_isFoldTo1_8;
  logic [1:0] v35_io_in_bits_uop_vpu_vxrm;
  logic [6:0] v35_io_in_bits_uop_vpu_vuopIdx;
  logic v35_io_in_bits_uop_vpu_lastUop;
  logic [127:0] v35_io_in_bits_uop_vpu_vmask;
  logic [7:0] v35_io_in_bits_uop_vpu_vl;
  logic [2:0] v35_io_in_bits_uop_vpu_nf;
  logic [1:0] v35_io_in_bits_uop_vpu_veew;
  logic v35_io_in_bits_uop_vpu_isReverse;
  logic v35_io_in_bits_uop_vpu_isExt;
  logic v35_io_in_bits_uop_vpu_isNarrow;
  logic v35_io_in_bits_uop_vpu_isDstMask;
  logic v35_io_in_bits_uop_vpu_isOpMask;
  logic v35_io_in_bits_uop_vpu_isMove;
  logic v35_io_in_bits_uop_vpu_isDependOldVd;
  logic v35_io_in_bits_uop_vpu_isWritePartVd;
  logic v35_io_in_bits_uop_vpu_isVleff;
  logic v35_io_in_bits_uop_vlsInstr;
  logic v35_io_in_bits_uop_wfflags;
  logic v35_io_in_bits_uop_isMove;
  logic v35_io_in_bits_uop_isDropAmocasSta;
  logic [6:0] v35_io_in_bits_uop_uopIdx;
  logic v35_io_in_bits_uop_isVset;
  logic v35_io_in_bits_uop_firstUop;
  logic v35_io_in_bits_uop_lastUop;
  logic [6:0] v35_io_in_bits_uop_numUops;
  logic [6:0] v35_io_in_bits_uop_numWB;
  logic [2:0] v35_io_in_bits_uop_commitType;
  logic v35_io_in_bits_uop_srcState_0;
  logic v35_io_in_bits_uop_srcState_1;
  logic v35_io_in_bits_uop_srcState_2;
  logic v35_io_in_bits_uop_srcState_3;
  logic v35_io_in_bits_uop_srcState_4;
  logic [1:0] v35_io_in_bits_uop_srcLoadDependency_0_0;
  logic [1:0] v35_io_in_bits_uop_srcLoadDependency_0_1;
  logic [1:0] v35_io_in_bits_uop_srcLoadDependency_0_2;
  logic [1:0] v35_io_in_bits_uop_srcLoadDependency_1_0;
  logic [1:0] v35_io_in_bits_uop_srcLoadDependency_1_1;
  logic [1:0] v35_io_in_bits_uop_srcLoadDependency_1_2;
  logic [1:0] v35_io_in_bits_uop_srcLoadDependency_2_0;
  logic [1:0] v35_io_in_bits_uop_srcLoadDependency_2_1;
  logic [1:0] v35_io_in_bits_uop_srcLoadDependency_2_2;
  logic [1:0] v35_io_in_bits_uop_srcLoadDependency_3_0;
  logic [1:0] v35_io_in_bits_uop_srcLoadDependency_3_1;
  logic [1:0] v35_io_in_bits_uop_srcLoadDependency_3_2;
  logic [1:0] v35_io_in_bits_uop_srcLoadDependency_4_0;
  logic [1:0] v35_io_in_bits_uop_srcLoadDependency_4_1;
  logic [1:0] v35_io_in_bits_uop_srcLoadDependency_4_2;
  logic [7:0] v35_io_in_bits_uop_psrc_0;
  logic [7:0] v35_io_in_bits_uop_psrc_1;
  logic [7:0] v35_io_in_bits_uop_psrc_2;
  logic [7:0] v35_io_in_bits_uop_psrc_3;
  logic [7:0] v35_io_in_bits_uop_psrc_4;
  logic [7:0] v35_io_in_bits_uop_pdest;
  logic v35_io_in_bits_uop_useRegCache_0;
  logic v35_io_in_bits_uop_useRegCache_1;
  logic [4:0] v35_io_in_bits_uop_regCacheIdx_0;
  logic [4:0] v35_io_in_bits_uop_regCacheIdx_1;
  logic v35_io_in_bits_uop_robIdx_flag;
  logic [7:0] v35_io_in_bits_uop_robIdx_value;
  logic [2:0] v35_io_in_bits_uop_instrSize;
  logic v35_io_in_bits_uop_dirtyFs;
  logic v35_io_in_bits_uop_dirtyVs;
  logic [3:0] v35_io_in_bits_uop_traceBlockInPipe_itype;
  logic [3:0] v35_io_in_bits_uop_traceBlockInPipe_iretire;
  logic v35_io_in_bits_uop_traceBlockInPipe_ilastsize;
  logic v35_io_in_bits_uop_eliminatedMove;
  logic v35_io_in_bits_uop_snapshot;
  logic v35_io_in_bits_uop_debugInfo_eliminatedMove;
  logic [63:0] v35_io_in_bits_uop_debugInfo_renameTime;
  logic [63:0] v35_io_in_bits_uop_debugInfo_dispatchTime;
  logic [63:0] v35_io_in_bits_uop_debugInfo_enqRsTime;
  logic [63:0] v35_io_in_bits_uop_debugInfo_selectTime;
  logic [63:0] v35_io_in_bits_uop_debugInfo_issueTime;
  logic [63:0] v35_io_in_bits_uop_debugInfo_writebackTime;
  logic [63:0] v35_io_in_bits_uop_debugInfo_runahead_checkpoint_id;
  logic [63:0] v35_io_in_bits_uop_debugInfo_tlbFirstReqTime;
  logic [63:0] v35_io_in_bits_uop_debugInfo_tlbRespTime;
  logic [55:0] v35_io_in_bits_uop_debug_seqNum_seqNum;
  logic [7:0] v35_io_in_bits_uop_debug_seqNum_uopIdx;
  logic v35_io_in_bits_uop_storeSetHit;
  logic v35_io_in_bits_uop_waitForRobIdx_flag;
  logic [7:0] v35_io_in_bits_uop_waitForRobIdx_value;
  logic v35_io_in_bits_uop_loadWaitBit;
  logic v35_io_in_bits_uop_loadWaitStrict;
  logic [4:0] v35_io_in_bits_uop_ssid;
  logic v35_io_in_bits_uop_lqIdx_flag;
  logic [6:0] v35_io_in_bits_uop_lqIdx_value;
  logic v35_io_in_bits_uop_sqIdx_flag;
  logic [5:0] v35_io_in_bits_uop_sqIdx_value;
  logic v35_io_in_bits_uop_singleStep;
  logic v35_io_in_bits_uop_replayInst;
  logic [34:0] v35_io_in_bits_uop_debug_fuType;
  logic v35_io_in_bits_uop_debug_sim_trig;
  logic [4:0] v35_io_in_bits_uop_numLsElem;
  logic [3:0] v35_io_in_bits_mBIndex;
  logic [7:0] v35_io_in_bits_elemIdx;
  logic [7:0] v35_io_in_bits_elemIdxInsideVd;
  logic [4:0] v35_io_in_bits_splitIndex;
  logic v35_io_out_ready;
  logic v35_io_rightOutFire;
  logic v35_io_isFlush;
  wire  g_v35_io_in_ready, i_v35_io_in_ready;
  wire  g_v35_io_out_valid, i_v35_io_out_valid;
  wire  [63:0] g_v35_io_out_bits_vaddr, i_v35_io_out_bits_vaddr;
  wire  [49:0] g_v35_io_out_bits_basevaddr, i_v35_io_out_bits_basevaddr;
  wire  [15:0] g_v35_io_out_bits_mask, i_v35_io_out_bits_mask;
  wire  [3:0] g_v35_io_out_bits_reg_offset, i_v35_io_out_bits_reg_offset;
  wire  [2:0] g_v35_io_out_bits_alignedType, i_v35_io_out_bits_alignedType;
  wire  g_v35_io_out_bits_vecActive, i_v35_io_out_bits_vecActive;
  wire  g_v35_io_out_bits_vecIsFirstActiveElement, i_v35_io_out_bits_vecIsFirstActiveElement;
  wire  [31:0] g_v35_io_out_bits_uop_instr, i_v35_io_out_bits_uop_instr;
  wire  [49:0] g_v35_io_out_bits_uop_pc, i_v35_io_out_bits_uop_pc;
  wire  [9:0] g_v35_io_out_bits_uop_foldpc, i_v35_io_out_bits_uop_foldpc;
  wire  g_v35_io_out_bits_uop_exceptionVec_4, i_v35_io_out_bits_uop_exceptionVec_4;
  wire  g_v35_io_out_bits_uop_exceptionVec_5, i_v35_io_out_bits_uop_exceptionVec_5;
  wire  g_v35_io_out_bits_uop_exceptionVec_6, i_v35_io_out_bits_uop_exceptionVec_6;
  wire  g_v35_io_out_bits_uop_exceptionVec_7, i_v35_io_out_bits_uop_exceptionVec_7;
  wire  g_v35_io_out_bits_uop_exceptionVec_13, i_v35_io_out_bits_uop_exceptionVec_13;
  wire  g_v35_io_out_bits_uop_exceptionVec_15, i_v35_io_out_bits_uop_exceptionVec_15;
  wire  g_v35_io_out_bits_uop_exceptionVec_19, i_v35_io_out_bits_uop_exceptionVec_19;
  wire  g_v35_io_out_bits_uop_exceptionVec_21, i_v35_io_out_bits_uop_exceptionVec_21;
  wire  g_v35_io_out_bits_uop_exceptionVec_23, i_v35_io_out_bits_uop_exceptionVec_23;
  wire  g_v35_io_out_bits_uop_isFetchMalAddr, i_v35_io_out_bits_uop_isFetchMalAddr;
  wire  g_v35_io_out_bits_uop_hasException, i_v35_io_out_bits_uop_hasException;
  wire  [3:0] g_v35_io_out_bits_uop_trigger, i_v35_io_out_bits_uop_trigger;
  wire  g_v35_io_out_bits_uop_preDecodeInfo_valid, i_v35_io_out_bits_uop_preDecodeInfo_valid;
  wire  g_v35_io_out_bits_uop_preDecodeInfo_isRVC, i_v35_io_out_bits_uop_preDecodeInfo_isRVC;
  wire  [1:0] g_v35_io_out_bits_uop_preDecodeInfo_brType, i_v35_io_out_bits_uop_preDecodeInfo_brType;
  wire  g_v35_io_out_bits_uop_preDecodeInfo_isCall, i_v35_io_out_bits_uop_preDecodeInfo_isCall;
  wire  g_v35_io_out_bits_uop_preDecodeInfo_isRet, i_v35_io_out_bits_uop_preDecodeInfo_isRet;
  wire  g_v35_io_out_bits_uop_pred_taken, i_v35_io_out_bits_uop_pred_taken;
  wire  g_v35_io_out_bits_uop_crossPageIPFFix, i_v35_io_out_bits_uop_crossPageIPFFix;
  wire  g_v35_io_out_bits_uop_ftqPtr_flag, i_v35_io_out_bits_uop_ftqPtr_flag;
  wire  [5:0] g_v35_io_out_bits_uop_ftqPtr_value, i_v35_io_out_bits_uop_ftqPtr_value;
  wire  [3:0] g_v35_io_out_bits_uop_ftqOffset, i_v35_io_out_bits_uop_ftqOffset;
  wire  g_v35_io_out_bits_uop_satpFlushFirstFetchFault, i_v35_io_out_bits_uop_satpFlushFirstFetchFault;
  wire  [3:0] g_v35_io_out_bits_uop_srcType_0, i_v35_io_out_bits_uop_srcType_0;
  wire  [3:0] g_v35_io_out_bits_uop_srcType_1, i_v35_io_out_bits_uop_srcType_1;
  wire  [3:0] g_v35_io_out_bits_uop_srcType_2, i_v35_io_out_bits_uop_srcType_2;
  wire  [3:0] g_v35_io_out_bits_uop_srcType_3, i_v35_io_out_bits_uop_srcType_3;
  wire  [3:0] g_v35_io_out_bits_uop_srcType_4, i_v35_io_out_bits_uop_srcType_4;
  wire  [5:0] g_v35_io_out_bits_uop_ldest, i_v35_io_out_bits_uop_ldest;
  wire  [34:0] g_v35_io_out_bits_uop_fuType, i_v35_io_out_bits_uop_fuType;
  wire  [8:0] g_v35_io_out_bits_uop_fuOpType, i_v35_io_out_bits_uop_fuOpType;
  wire  g_v35_io_out_bits_uop_rfWen, i_v35_io_out_bits_uop_rfWen;
  wire  g_v35_io_out_bits_uop_fpWen, i_v35_io_out_bits_uop_fpWen;
  wire  g_v35_io_out_bits_uop_vecWen, i_v35_io_out_bits_uop_vecWen;
  wire  g_v35_io_out_bits_uop_v0Wen, i_v35_io_out_bits_uop_v0Wen;
  wire  g_v35_io_out_bits_uop_vlWen, i_v35_io_out_bits_uop_vlWen;
  wire  g_v35_io_out_bits_uop_isXSTrap, i_v35_io_out_bits_uop_isXSTrap;
  wire  g_v35_io_out_bits_uop_waitForward, i_v35_io_out_bits_uop_waitForward;
  wire  g_v35_io_out_bits_uop_blockBackward, i_v35_io_out_bits_uop_blockBackward;
  wire  g_v35_io_out_bits_uop_canRobCompress, i_v35_io_out_bits_uop_canRobCompress;
  wire  [3:0] g_v35_io_out_bits_uop_selImm, i_v35_io_out_bits_uop_selImm;
  wire  [1:0] g_v35_io_out_bits_uop_fpu_typeTagOut, i_v35_io_out_bits_uop_fpu_typeTagOut;
  wire  g_v35_io_out_bits_uop_fpu_wflags, i_v35_io_out_bits_uop_fpu_wflags;
  wire  [1:0] g_v35_io_out_bits_uop_fpu_typ, i_v35_io_out_bits_uop_fpu_typ;
  wire  [1:0] g_v35_io_out_bits_uop_fpu_fmt, i_v35_io_out_bits_uop_fpu_fmt;
  wire  [2:0] g_v35_io_out_bits_uop_fpu_rm, i_v35_io_out_bits_uop_fpu_rm;
  wire  g_v35_io_out_bits_uop_vpu_vill, i_v35_io_out_bits_uop_vpu_vill;
  wire  g_v35_io_out_bits_uop_vpu_vma, i_v35_io_out_bits_uop_vpu_vma;
  wire  g_v35_io_out_bits_uop_vpu_vta, i_v35_io_out_bits_uop_vpu_vta;
  wire  [1:0] g_v35_io_out_bits_uop_vpu_vsew, i_v35_io_out_bits_uop_vpu_vsew;
  wire  [2:0] g_v35_io_out_bits_uop_vpu_vlmul, i_v35_io_out_bits_uop_vpu_vlmul;
  wire  g_v35_io_out_bits_uop_vpu_specVill, i_v35_io_out_bits_uop_vpu_specVill;
  wire  g_v35_io_out_bits_uop_vpu_specVma, i_v35_io_out_bits_uop_vpu_specVma;
  wire  g_v35_io_out_bits_uop_vpu_specVta, i_v35_io_out_bits_uop_vpu_specVta;
  wire  [1:0] g_v35_io_out_bits_uop_vpu_specVsew, i_v35_io_out_bits_uop_vpu_specVsew;
  wire  [2:0] g_v35_io_out_bits_uop_vpu_specVlmul, i_v35_io_out_bits_uop_vpu_specVlmul;
  wire  g_v35_io_out_bits_uop_vpu_vm, i_v35_io_out_bits_uop_vpu_vm;
  wire  [7:0] g_v35_io_out_bits_uop_vpu_vstart, i_v35_io_out_bits_uop_vpu_vstart;
  wire  [2:0] g_v35_io_out_bits_uop_vpu_frm, i_v35_io_out_bits_uop_vpu_frm;
  wire  g_v35_io_out_bits_uop_vpu_fpu_isFpToVecInst, i_v35_io_out_bits_uop_vpu_fpu_isFpToVecInst;
  wire  g_v35_io_out_bits_uop_vpu_fpu_isFP32Instr, i_v35_io_out_bits_uop_vpu_fpu_isFP32Instr;
  wire  g_v35_io_out_bits_uop_vpu_fpu_isFP64Instr, i_v35_io_out_bits_uop_vpu_fpu_isFP64Instr;
  wire  g_v35_io_out_bits_uop_vpu_fpu_isReduction, i_v35_io_out_bits_uop_vpu_fpu_isReduction;
  wire  g_v35_io_out_bits_uop_vpu_fpu_isFoldTo1_2, i_v35_io_out_bits_uop_vpu_fpu_isFoldTo1_2;
  wire  g_v35_io_out_bits_uop_vpu_fpu_isFoldTo1_4, i_v35_io_out_bits_uop_vpu_fpu_isFoldTo1_4;
  wire  g_v35_io_out_bits_uop_vpu_fpu_isFoldTo1_8, i_v35_io_out_bits_uop_vpu_fpu_isFoldTo1_8;
  wire  [1:0] g_v35_io_out_bits_uop_vpu_vxrm, i_v35_io_out_bits_uop_vpu_vxrm;
  wire  [6:0] g_v35_io_out_bits_uop_vpu_vuopIdx, i_v35_io_out_bits_uop_vpu_vuopIdx;
  wire  g_v35_io_out_bits_uop_vpu_lastUop, i_v35_io_out_bits_uop_vpu_lastUop;
  wire  [127:0] g_v35_io_out_bits_uop_vpu_vmask, i_v35_io_out_bits_uop_vpu_vmask;
  wire  [7:0] g_v35_io_out_bits_uop_vpu_vl, i_v35_io_out_bits_uop_vpu_vl;
  wire  [2:0] g_v35_io_out_bits_uop_vpu_nf, i_v35_io_out_bits_uop_vpu_nf;
  wire  [1:0] g_v35_io_out_bits_uop_vpu_veew, i_v35_io_out_bits_uop_vpu_veew;
  wire  g_v35_io_out_bits_uop_vpu_isReverse, i_v35_io_out_bits_uop_vpu_isReverse;
  wire  g_v35_io_out_bits_uop_vpu_isExt, i_v35_io_out_bits_uop_vpu_isExt;
  wire  g_v35_io_out_bits_uop_vpu_isNarrow, i_v35_io_out_bits_uop_vpu_isNarrow;
  wire  g_v35_io_out_bits_uop_vpu_isDstMask, i_v35_io_out_bits_uop_vpu_isDstMask;
  wire  g_v35_io_out_bits_uop_vpu_isOpMask, i_v35_io_out_bits_uop_vpu_isOpMask;
  wire  g_v35_io_out_bits_uop_vpu_isMove, i_v35_io_out_bits_uop_vpu_isMove;
  wire  g_v35_io_out_bits_uop_vpu_isDependOldVd, i_v35_io_out_bits_uop_vpu_isDependOldVd;
  wire  g_v35_io_out_bits_uop_vpu_isWritePartVd, i_v35_io_out_bits_uop_vpu_isWritePartVd;
  wire  g_v35_io_out_bits_uop_vpu_isVleff, i_v35_io_out_bits_uop_vpu_isVleff;
  wire  g_v35_io_out_bits_uop_vlsInstr, i_v35_io_out_bits_uop_vlsInstr;
  wire  g_v35_io_out_bits_uop_wfflags, i_v35_io_out_bits_uop_wfflags;
  wire  g_v35_io_out_bits_uop_isMove, i_v35_io_out_bits_uop_isMove;
  wire  g_v35_io_out_bits_uop_isDropAmocasSta, i_v35_io_out_bits_uop_isDropAmocasSta;
  wire  [6:0] g_v35_io_out_bits_uop_uopIdx, i_v35_io_out_bits_uop_uopIdx;
  wire  g_v35_io_out_bits_uop_isVset, i_v35_io_out_bits_uop_isVset;
  wire  g_v35_io_out_bits_uop_firstUop, i_v35_io_out_bits_uop_firstUop;
  wire  g_v35_io_out_bits_uop_lastUop, i_v35_io_out_bits_uop_lastUop;
  wire  [6:0] g_v35_io_out_bits_uop_numUops, i_v35_io_out_bits_uop_numUops;
  wire  [6:0] g_v35_io_out_bits_uop_numWB, i_v35_io_out_bits_uop_numWB;
  wire  [2:0] g_v35_io_out_bits_uop_commitType, i_v35_io_out_bits_uop_commitType;
  wire  g_v35_io_out_bits_uop_srcState_0, i_v35_io_out_bits_uop_srcState_0;
  wire  g_v35_io_out_bits_uop_srcState_1, i_v35_io_out_bits_uop_srcState_1;
  wire  g_v35_io_out_bits_uop_srcState_2, i_v35_io_out_bits_uop_srcState_2;
  wire  g_v35_io_out_bits_uop_srcState_3, i_v35_io_out_bits_uop_srcState_3;
  wire  g_v35_io_out_bits_uop_srcState_4, i_v35_io_out_bits_uop_srcState_4;
  wire  [1:0] g_v35_io_out_bits_uop_srcLoadDependency_0_0, i_v35_io_out_bits_uop_srcLoadDependency_0_0;
  wire  [1:0] g_v35_io_out_bits_uop_srcLoadDependency_0_1, i_v35_io_out_bits_uop_srcLoadDependency_0_1;
  wire  [1:0] g_v35_io_out_bits_uop_srcLoadDependency_0_2, i_v35_io_out_bits_uop_srcLoadDependency_0_2;
  wire  [1:0] g_v35_io_out_bits_uop_srcLoadDependency_1_0, i_v35_io_out_bits_uop_srcLoadDependency_1_0;
  wire  [1:0] g_v35_io_out_bits_uop_srcLoadDependency_1_1, i_v35_io_out_bits_uop_srcLoadDependency_1_1;
  wire  [1:0] g_v35_io_out_bits_uop_srcLoadDependency_1_2, i_v35_io_out_bits_uop_srcLoadDependency_1_2;
  wire  [1:0] g_v35_io_out_bits_uop_srcLoadDependency_2_0, i_v35_io_out_bits_uop_srcLoadDependency_2_0;
  wire  [1:0] g_v35_io_out_bits_uop_srcLoadDependency_2_1, i_v35_io_out_bits_uop_srcLoadDependency_2_1;
  wire  [1:0] g_v35_io_out_bits_uop_srcLoadDependency_2_2, i_v35_io_out_bits_uop_srcLoadDependency_2_2;
  wire  [1:0] g_v35_io_out_bits_uop_srcLoadDependency_3_0, i_v35_io_out_bits_uop_srcLoadDependency_3_0;
  wire  [1:0] g_v35_io_out_bits_uop_srcLoadDependency_3_1, i_v35_io_out_bits_uop_srcLoadDependency_3_1;
  wire  [1:0] g_v35_io_out_bits_uop_srcLoadDependency_3_2, i_v35_io_out_bits_uop_srcLoadDependency_3_2;
  wire  [1:0] g_v35_io_out_bits_uop_srcLoadDependency_4_0, i_v35_io_out_bits_uop_srcLoadDependency_4_0;
  wire  [1:0] g_v35_io_out_bits_uop_srcLoadDependency_4_1, i_v35_io_out_bits_uop_srcLoadDependency_4_1;
  wire  [1:0] g_v35_io_out_bits_uop_srcLoadDependency_4_2, i_v35_io_out_bits_uop_srcLoadDependency_4_2;
  wire  [7:0] g_v35_io_out_bits_uop_psrc_0, i_v35_io_out_bits_uop_psrc_0;
  wire  [7:0] g_v35_io_out_bits_uop_psrc_1, i_v35_io_out_bits_uop_psrc_1;
  wire  [7:0] g_v35_io_out_bits_uop_psrc_2, i_v35_io_out_bits_uop_psrc_2;
  wire  [7:0] g_v35_io_out_bits_uop_psrc_3, i_v35_io_out_bits_uop_psrc_3;
  wire  [7:0] g_v35_io_out_bits_uop_psrc_4, i_v35_io_out_bits_uop_psrc_4;
  wire  [7:0] g_v35_io_out_bits_uop_pdest, i_v35_io_out_bits_uop_pdest;
  wire  g_v35_io_out_bits_uop_useRegCache_0, i_v35_io_out_bits_uop_useRegCache_0;
  wire  g_v35_io_out_bits_uop_useRegCache_1, i_v35_io_out_bits_uop_useRegCache_1;
  wire  [4:0] g_v35_io_out_bits_uop_regCacheIdx_0, i_v35_io_out_bits_uop_regCacheIdx_0;
  wire  [4:0] g_v35_io_out_bits_uop_regCacheIdx_1, i_v35_io_out_bits_uop_regCacheIdx_1;
  wire  g_v35_io_out_bits_uop_robIdx_flag, i_v35_io_out_bits_uop_robIdx_flag;
  wire  [7:0] g_v35_io_out_bits_uop_robIdx_value, i_v35_io_out_bits_uop_robIdx_value;
  wire  [2:0] g_v35_io_out_bits_uop_instrSize, i_v35_io_out_bits_uop_instrSize;
  wire  g_v35_io_out_bits_uop_dirtyFs, i_v35_io_out_bits_uop_dirtyFs;
  wire  g_v35_io_out_bits_uop_dirtyVs, i_v35_io_out_bits_uop_dirtyVs;
  wire  [3:0] g_v35_io_out_bits_uop_traceBlockInPipe_itype, i_v35_io_out_bits_uop_traceBlockInPipe_itype;
  wire  [3:0] g_v35_io_out_bits_uop_traceBlockInPipe_iretire, i_v35_io_out_bits_uop_traceBlockInPipe_iretire;
  wire  g_v35_io_out_bits_uop_traceBlockInPipe_ilastsize, i_v35_io_out_bits_uop_traceBlockInPipe_ilastsize;
  wire  g_v35_io_out_bits_uop_eliminatedMove, i_v35_io_out_bits_uop_eliminatedMove;
  wire  g_v35_io_out_bits_uop_snapshot, i_v35_io_out_bits_uop_snapshot;
  wire  g_v35_io_out_bits_uop_debugInfo_eliminatedMove, i_v35_io_out_bits_uop_debugInfo_eliminatedMove;
  wire  [63:0] g_v35_io_out_bits_uop_debugInfo_renameTime, i_v35_io_out_bits_uop_debugInfo_renameTime;
  wire  [63:0] g_v35_io_out_bits_uop_debugInfo_dispatchTime, i_v35_io_out_bits_uop_debugInfo_dispatchTime;
  wire  [63:0] g_v35_io_out_bits_uop_debugInfo_enqRsTime, i_v35_io_out_bits_uop_debugInfo_enqRsTime;
  wire  [63:0] g_v35_io_out_bits_uop_debugInfo_selectTime, i_v35_io_out_bits_uop_debugInfo_selectTime;
  wire  [63:0] g_v35_io_out_bits_uop_debugInfo_issueTime, i_v35_io_out_bits_uop_debugInfo_issueTime;
  wire  [63:0] g_v35_io_out_bits_uop_debugInfo_writebackTime, i_v35_io_out_bits_uop_debugInfo_writebackTime;
  wire  [63:0] g_v35_io_out_bits_uop_debugInfo_runahead_checkpoint_id, i_v35_io_out_bits_uop_debugInfo_runahead_checkpoint_id;
  wire  [63:0] g_v35_io_out_bits_uop_debugInfo_tlbFirstReqTime, i_v35_io_out_bits_uop_debugInfo_tlbFirstReqTime;
  wire  [63:0] g_v35_io_out_bits_uop_debugInfo_tlbRespTime, i_v35_io_out_bits_uop_debugInfo_tlbRespTime;
  wire  [55:0] g_v35_io_out_bits_uop_debug_seqNum_seqNum, i_v35_io_out_bits_uop_debug_seqNum_seqNum;
  wire  [7:0] g_v35_io_out_bits_uop_debug_seqNum_uopIdx, i_v35_io_out_bits_uop_debug_seqNum_uopIdx;
  wire  g_v35_io_out_bits_uop_storeSetHit, i_v35_io_out_bits_uop_storeSetHit;
  wire  g_v35_io_out_bits_uop_waitForRobIdx_flag, i_v35_io_out_bits_uop_waitForRobIdx_flag;
  wire  [7:0] g_v35_io_out_bits_uop_waitForRobIdx_value, i_v35_io_out_bits_uop_waitForRobIdx_value;
  wire  g_v35_io_out_bits_uop_loadWaitBit, i_v35_io_out_bits_uop_loadWaitBit;
  wire  g_v35_io_out_bits_uop_loadWaitStrict, i_v35_io_out_bits_uop_loadWaitStrict;
  wire  [4:0] g_v35_io_out_bits_uop_ssid, i_v35_io_out_bits_uop_ssid;
  wire  g_v35_io_out_bits_uop_lqIdx_flag, i_v35_io_out_bits_uop_lqIdx_flag;
  wire  [6:0] g_v35_io_out_bits_uop_lqIdx_value, i_v35_io_out_bits_uop_lqIdx_value;
  wire  g_v35_io_out_bits_uop_sqIdx_flag, i_v35_io_out_bits_uop_sqIdx_flag;
  wire  [5:0] g_v35_io_out_bits_uop_sqIdx_value, i_v35_io_out_bits_uop_sqIdx_value;
  wire  g_v35_io_out_bits_uop_singleStep, i_v35_io_out_bits_uop_singleStep;
  wire  g_v35_io_out_bits_uop_replayInst, i_v35_io_out_bits_uop_replayInst;
  wire  [34:0] g_v35_io_out_bits_uop_debug_fuType, i_v35_io_out_bits_uop_debug_fuType;
  wire  g_v35_io_out_bits_uop_debug_sim_trig, i_v35_io_out_bits_uop_debug_sim_trig;
  wire  [4:0] g_v35_io_out_bits_uop_numLsElem, i_v35_io_out_bits_uop_numLsElem;
  wire  [3:0] g_v35_io_out_bits_mBIndex, i_v35_io_out_bits_mBIndex;
  wire  [7:0] g_v35_io_out_bits_elemIdx, i_v35_io_out_bits_elemIdx;
  wire  [7:0] g_v35_io_out_bits_elemIdxInsideVd, i_v35_io_out_bits_elemIdxInsideVd;
  wire  [4:0] g_v35_io_out_bits_splitIndex, i_v35_io_out_bits_splitIndex;
  longint nchk_v35 = 0; int nerr_v35 = 0;
  longint fire_v35 = 0, bp_v35 = 0, hold_v35 = 0, deq_v35 = 0, owr_v35 = 0;
  longint flush_v35 = 0, flfire_v35 = 0;
  logic [1445:0] por_v35 = '0, pand_v35 = '1;   // payload 逐位或 / 逐位与
  wire  [1445:0] pcat_v35 = {v35_io_in_bits_vaddr, v35_io_in_bits_basevaddr, v35_io_in_bits_mask, v35_io_in_bits_reg_offset, v35_io_in_bits_alignedType, v35_io_in_bits_vecActive, v35_io_in_bits_vecIsFirstActiveElement, v35_io_in_bits_uop_instr, v35_io_in_bits_uop_pc, v35_io_in_bits_uop_foldpc, v35_io_in_bits_uop_exceptionVec_4, v35_io_in_bits_uop_exceptionVec_5, v35_io_in_bits_uop_exceptionVec_6, v35_io_in_bits_uop_exceptionVec_7, v35_io_in_bits_uop_exceptionVec_13, v35_io_in_bits_uop_exceptionVec_15, v35_io_in_bits_uop_exceptionVec_19, v35_io_in_bits_uop_exceptionVec_21, v35_io_in_bits_uop_exceptionVec_23, v35_io_in_bits_uop_isFetchMalAddr, v35_io_in_bits_uop_hasException, v35_io_in_bits_uop_trigger, v35_io_in_bits_uop_preDecodeInfo_valid, v35_io_in_bits_uop_preDecodeInfo_isRVC, v35_io_in_bits_uop_preDecodeInfo_brType, v35_io_in_bits_uop_preDecodeInfo_isCall, v35_io_in_bits_uop_preDecodeInfo_isRet, v35_io_in_bits_uop_pred_taken, v35_io_in_bits_uop_crossPageIPFFix, v35_io_in_bits_uop_ftqPtr_flag, v35_io_in_bits_uop_ftqPtr_value, v35_io_in_bits_uop_ftqOffset, v35_io_in_bits_uop_satpFlushFirstFetchFault, v35_io_in_bits_uop_srcType_0, v35_io_in_bits_uop_srcType_1, v35_io_in_bits_uop_srcType_2, v35_io_in_bits_uop_srcType_3, v35_io_in_bits_uop_srcType_4, v35_io_in_bits_uop_ldest, v35_io_in_bits_uop_fuType, v35_io_in_bits_uop_fuOpType, v35_io_in_bits_uop_rfWen, v35_io_in_bits_uop_fpWen, v35_io_in_bits_uop_vecWen, v35_io_in_bits_uop_v0Wen, v35_io_in_bits_uop_vlWen, v35_io_in_bits_uop_isXSTrap, v35_io_in_bits_uop_waitForward, v35_io_in_bits_uop_blockBackward, v35_io_in_bits_uop_canRobCompress, v35_io_in_bits_uop_selImm, v35_io_in_bits_uop_fpu_typeTagOut, v35_io_in_bits_uop_fpu_wflags, v35_io_in_bits_uop_fpu_typ, v35_io_in_bits_uop_fpu_fmt, v35_io_in_bits_uop_fpu_rm, v35_io_in_bits_uop_vpu_vill, v35_io_in_bits_uop_vpu_vma, v35_io_in_bits_uop_vpu_vta, v35_io_in_bits_uop_vpu_vsew, v35_io_in_bits_uop_vpu_vlmul, v35_io_in_bits_uop_vpu_specVill, v35_io_in_bits_uop_vpu_specVma, v35_io_in_bits_uop_vpu_specVta, v35_io_in_bits_uop_vpu_specVsew, v35_io_in_bits_uop_vpu_specVlmul, v35_io_in_bits_uop_vpu_vm, v35_io_in_bits_uop_vpu_vstart, v35_io_in_bits_uop_vpu_frm, v35_io_in_bits_uop_vpu_fpu_isFpToVecInst, v35_io_in_bits_uop_vpu_fpu_isFP32Instr, v35_io_in_bits_uop_vpu_fpu_isFP64Instr, v35_io_in_bits_uop_vpu_fpu_isReduction, v35_io_in_bits_uop_vpu_fpu_isFoldTo1_2, v35_io_in_bits_uop_vpu_fpu_isFoldTo1_4, v35_io_in_bits_uop_vpu_fpu_isFoldTo1_8, v35_io_in_bits_uop_vpu_vxrm, v35_io_in_bits_uop_vpu_vuopIdx, v35_io_in_bits_uop_vpu_lastUop, v35_io_in_bits_uop_vpu_vmask, v35_io_in_bits_uop_vpu_vl, v35_io_in_bits_uop_vpu_nf, v35_io_in_bits_uop_vpu_veew, v35_io_in_bits_uop_vpu_isReverse, v35_io_in_bits_uop_vpu_isExt, v35_io_in_bits_uop_vpu_isNarrow, v35_io_in_bits_uop_vpu_isDstMask, v35_io_in_bits_uop_vpu_isOpMask, v35_io_in_bits_uop_vpu_isMove, v35_io_in_bits_uop_vpu_isDependOldVd, v35_io_in_bits_uop_vpu_isWritePartVd, v35_io_in_bits_uop_vpu_isVleff, v35_io_in_bits_uop_vlsInstr, v35_io_in_bits_uop_wfflags, v35_io_in_bits_uop_isMove, v35_io_in_bits_uop_isDropAmocasSta, v35_io_in_bits_uop_uopIdx, v35_io_in_bits_uop_isVset, v35_io_in_bits_uop_firstUop, v35_io_in_bits_uop_lastUop, v35_io_in_bits_uop_numUops, v35_io_in_bits_uop_numWB, v35_io_in_bits_uop_commitType, v35_io_in_bits_uop_srcState_0, v35_io_in_bits_uop_srcState_1, v35_io_in_bits_uop_srcState_2, v35_io_in_bits_uop_srcState_3, v35_io_in_bits_uop_srcState_4, v35_io_in_bits_uop_srcLoadDependency_0_0, v35_io_in_bits_uop_srcLoadDependency_0_1, v35_io_in_bits_uop_srcLoadDependency_0_2, v35_io_in_bits_uop_srcLoadDependency_1_0, v35_io_in_bits_uop_srcLoadDependency_1_1, v35_io_in_bits_uop_srcLoadDependency_1_2, v35_io_in_bits_uop_srcLoadDependency_2_0, v35_io_in_bits_uop_srcLoadDependency_2_1, v35_io_in_bits_uop_srcLoadDependency_2_2, v35_io_in_bits_uop_srcLoadDependency_3_0, v35_io_in_bits_uop_srcLoadDependency_3_1, v35_io_in_bits_uop_srcLoadDependency_3_2, v35_io_in_bits_uop_srcLoadDependency_4_0, v35_io_in_bits_uop_srcLoadDependency_4_1, v35_io_in_bits_uop_srcLoadDependency_4_2, v35_io_in_bits_uop_psrc_0, v35_io_in_bits_uop_psrc_1, v35_io_in_bits_uop_psrc_2, v35_io_in_bits_uop_psrc_3, v35_io_in_bits_uop_psrc_4, v35_io_in_bits_uop_pdest, v35_io_in_bits_uop_useRegCache_0, v35_io_in_bits_uop_useRegCache_1, v35_io_in_bits_uop_regCacheIdx_0, v35_io_in_bits_uop_regCacheIdx_1, v35_io_in_bits_uop_robIdx_flag, v35_io_in_bits_uop_robIdx_value, v35_io_in_bits_uop_instrSize, v35_io_in_bits_uop_dirtyFs, v35_io_in_bits_uop_dirtyVs, v35_io_in_bits_uop_traceBlockInPipe_itype, v35_io_in_bits_uop_traceBlockInPipe_iretire, v35_io_in_bits_uop_traceBlockInPipe_ilastsize, v35_io_in_bits_uop_eliminatedMove, v35_io_in_bits_uop_snapshot, v35_io_in_bits_uop_debugInfo_eliminatedMove, v35_io_in_bits_uop_debugInfo_renameTime, v35_io_in_bits_uop_debugInfo_dispatchTime, v35_io_in_bits_uop_debugInfo_enqRsTime, v35_io_in_bits_uop_debugInfo_selectTime, v35_io_in_bits_uop_debugInfo_issueTime, v35_io_in_bits_uop_debugInfo_writebackTime, v35_io_in_bits_uop_debugInfo_runahead_checkpoint_id, v35_io_in_bits_uop_debugInfo_tlbFirstReqTime, v35_io_in_bits_uop_debugInfo_tlbRespTime, v35_io_in_bits_uop_debug_seqNum_seqNum, v35_io_in_bits_uop_debug_seqNum_uopIdx, v35_io_in_bits_uop_storeSetHit, v35_io_in_bits_uop_waitForRobIdx_flag, v35_io_in_bits_uop_waitForRobIdx_value, v35_io_in_bits_uop_loadWaitBit, v35_io_in_bits_uop_loadWaitStrict, v35_io_in_bits_uop_ssid, v35_io_in_bits_uop_lqIdx_flag, v35_io_in_bits_uop_lqIdx_value, v35_io_in_bits_uop_sqIdx_flag, v35_io_in_bits_uop_sqIdx_value, v35_io_in_bits_uop_singleStep, v35_io_in_bits_uop_replayInst, v35_io_in_bits_uop_debug_fuType, v35_io_in_bits_uop_debug_sim_trig, v35_io_in_bits_uop_numLsElem, v35_io_in_bits_mBIndex, v35_io_in_bits_elemIdx, v35_io_in_bits_elemIdxInsideVd, v35_io_in_bits_splitIndex};
  NewPipelineConnectPipe_35 u_g_v35 (
    .clock(clock), .reset(reset),
    .io_in_valid(v35_io_in_valid),
    .io_in_bits_vaddr(v35_io_in_bits_vaddr),
    .io_in_bits_basevaddr(v35_io_in_bits_basevaddr),
    .io_in_bits_mask(v35_io_in_bits_mask),
    .io_in_bits_reg_offset(v35_io_in_bits_reg_offset),
    .io_in_bits_alignedType(v35_io_in_bits_alignedType),
    .io_in_bits_vecActive(v35_io_in_bits_vecActive),
    .io_in_bits_vecIsFirstActiveElement(v35_io_in_bits_vecIsFirstActiveElement),
    .io_in_bits_uop_instr(v35_io_in_bits_uop_instr),
    .io_in_bits_uop_pc(v35_io_in_bits_uop_pc),
    .io_in_bits_uop_foldpc(v35_io_in_bits_uop_foldpc),
    .io_in_bits_uop_exceptionVec_4(v35_io_in_bits_uop_exceptionVec_4),
    .io_in_bits_uop_exceptionVec_5(v35_io_in_bits_uop_exceptionVec_5),
    .io_in_bits_uop_exceptionVec_6(v35_io_in_bits_uop_exceptionVec_6),
    .io_in_bits_uop_exceptionVec_7(v35_io_in_bits_uop_exceptionVec_7),
    .io_in_bits_uop_exceptionVec_13(v35_io_in_bits_uop_exceptionVec_13),
    .io_in_bits_uop_exceptionVec_15(v35_io_in_bits_uop_exceptionVec_15),
    .io_in_bits_uop_exceptionVec_19(v35_io_in_bits_uop_exceptionVec_19),
    .io_in_bits_uop_exceptionVec_21(v35_io_in_bits_uop_exceptionVec_21),
    .io_in_bits_uop_exceptionVec_23(v35_io_in_bits_uop_exceptionVec_23),
    .io_in_bits_uop_isFetchMalAddr(v35_io_in_bits_uop_isFetchMalAddr),
    .io_in_bits_uop_hasException(v35_io_in_bits_uop_hasException),
    .io_in_bits_uop_trigger(v35_io_in_bits_uop_trigger),
    .io_in_bits_uop_preDecodeInfo_valid(v35_io_in_bits_uop_preDecodeInfo_valid),
    .io_in_bits_uop_preDecodeInfo_isRVC(v35_io_in_bits_uop_preDecodeInfo_isRVC),
    .io_in_bits_uop_preDecodeInfo_brType(v35_io_in_bits_uop_preDecodeInfo_brType),
    .io_in_bits_uop_preDecodeInfo_isCall(v35_io_in_bits_uop_preDecodeInfo_isCall),
    .io_in_bits_uop_preDecodeInfo_isRet(v35_io_in_bits_uop_preDecodeInfo_isRet),
    .io_in_bits_uop_pred_taken(v35_io_in_bits_uop_pred_taken),
    .io_in_bits_uop_crossPageIPFFix(v35_io_in_bits_uop_crossPageIPFFix),
    .io_in_bits_uop_ftqPtr_flag(v35_io_in_bits_uop_ftqPtr_flag),
    .io_in_bits_uop_ftqPtr_value(v35_io_in_bits_uop_ftqPtr_value),
    .io_in_bits_uop_ftqOffset(v35_io_in_bits_uop_ftqOffset),
    .io_in_bits_uop_satpFlushFirstFetchFault(v35_io_in_bits_uop_satpFlushFirstFetchFault),
    .io_in_bits_uop_srcType_0(v35_io_in_bits_uop_srcType_0),
    .io_in_bits_uop_srcType_1(v35_io_in_bits_uop_srcType_1),
    .io_in_bits_uop_srcType_2(v35_io_in_bits_uop_srcType_2),
    .io_in_bits_uop_srcType_3(v35_io_in_bits_uop_srcType_3),
    .io_in_bits_uop_srcType_4(v35_io_in_bits_uop_srcType_4),
    .io_in_bits_uop_ldest(v35_io_in_bits_uop_ldest),
    .io_in_bits_uop_fuType(v35_io_in_bits_uop_fuType),
    .io_in_bits_uop_fuOpType(v35_io_in_bits_uop_fuOpType),
    .io_in_bits_uop_rfWen(v35_io_in_bits_uop_rfWen),
    .io_in_bits_uop_fpWen(v35_io_in_bits_uop_fpWen),
    .io_in_bits_uop_vecWen(v35_io_in_bits_uop_vecWen),
    .io_in_bits_uop_v0Wen(v35_io_in_bits_uop_v0Wen),
    .io_in_bits_uop_vlWen(v35_io_in_bits_uop_vlWen),
    .io_in_bits_uop_isXSTrap(v35_io_in_bits_uop_isXSTrap),
    .io_in_bits_uop_waitForward(v35_io_in_bits_uop_waitForward),
    .io_in_bits_uop_blockBackward(v35_io_in_bits_uop_blockBackward),
    .io_in_bits_uop_canRobCompress(v35_io_in_bits_uop_canRobCompress),
    .io_in_bits_uop_selImm(v35_io_in_bits_uop_selImm),
    .io_in_bits_uop_fpu_typeTagOut(v35_io_in_bits_uop_fpu_typeTagOut),
    .io_in_bits_uop_fpu_wflags(v35_io_in_bits_uop_fpu_wflags),
    .io_in_bits_uop_fpu_typ(v35_io_in_bits_uop_fpu_typ),
    .io_in_bits_uop_fpu_fmt(v35_io_in_bits_uop_fpu_fmt),
    .io_in_bits_uop_fpu_rm(v35_io_in_bits_uop_fpu_rm),
    .io_in_bits_uop_vpu_vill(v35_io_in_bits_uop_vpu_vill),
    .io_in_bits_uop_vpu_vma(v35_io_in_bits_uop_vpu_vma),
    .io_in_bits_uop_vpu_vta(v35_io_in_bits_uop_vpu_vta),
    .io_in_bits_uop_vpu_vsew(v35_io_in_bits_uop_vpu_vsew),
    .io_in_bits_uop_vpu_vlmul(v35_io_in_bits_uop_vpu_vlmul),
    .io_in_bits_uop_vpu_specVill(v35_io_in_bits_uop_vpu_specVill),
    .io_in_bits_uop_vpu_specVma(v35_io_in_bits_uop_vpu_specVma),
    .io_in_bits_uop_vpu_specVta(v35_io_in_bits_uop_vpu_specVta),
    .io_in_bits_uop_vpu_specVsew(v35_io_in_bits_uop_vpu_specVsew),
    .io_in_bits_uop_vpu_specVlmul(v35_io_in_bits_uop_vpu_specVlmul),
    .io_in_bits_uop_vpu_vm(v35_io_in_bits_uop_vpu_vm),
    .io_in_bits_uop_vpu_vstart(v35_io_in_bits_uop_vpu_vstart),
    .io_in_bits_uop_vpu_frm(v35_io_in_bits_uop_vpu_frm),
    .io_in_bits_uop_vpu_fpu_isFpToVecInst(v35_io_in_bits_uop_vpu_fpu_isFpToVecInst),
    .io_in_bits_uop_vpu_fpu_isFP32Instr(v35_io_in_bits_uop_vpu_fpu_isFP32Instr),
    .io_in_bits_uop_vpu_fpu_isFP64Instr(v35_io_in_bits_uop_vpu_fpu_isFP64Instr),
    .io_in_bits_uop_vpu_fpu_isReduction(v35_io_in_bits_uop_vpu_fpu_isReduction),
    .io_in_bits_uop_vpu_fpu_isFoldTo1_2(v35_io_in_bits_uop_vpu_fpu_isFoldTo1_2),
    .io_in_bits_uop_vpu_fpu_isFoldTo1_4(v35_io_in_bits_uop_vpu_fpu_isFoldTo1_4),
    .io_in_bits_uop_vpu_fpu_isFoldTo1_8(v35_io_in_bits_uop_vpu_fpu_isFoldTo1_8),
    .io_in_bits_uop_vpu_vxrm(v35_io_in_bits_uop_vpu_vxrm),
    .io_in_bits_uop_vpu_vuopIdx(v35_io_in_bits_uop_vpu_vuopIdx),
    .io_in_bits_uop_vpu_lastUop(v35_io_in_bits_uop_vpu_lastUop),
    .io_in_bits_uop_vpu_vmask(v35_io_in_bits_uop_vpu_vmask),
    .io_in_bits_uop_vpu_vl(v35_io_in_bits_uop_vpu_vl),
    .io_in_bits_uop_vpu_nf(v35_io_in_bits_uop_vpu_nf),
    .io_in_bits_uop_vpu_veew(v35_io_in_bits_uop_vpu_veew),
    .io_in_bits_uop_vpu_isReverse(v35_io_in_bits_uop_vpu_isReverse),
    .io_in_bits_uop_vpu_isExt(v35_io_in_bits_uop_vpu_isExt),
    .io_in_bits_uop_vpu_isNarrow(v35_io_in_bits_uop_vpu_isNarrow),
    .io_in_bits_uop_vpu_isDstMask(v35_io_in_bits_uop_vpu_isDstMask),
    .io_in_bits_uop_vpu_isOpMask(v35_io_in_bits_uop_vpu_isOpMask),
    .io_in_bits_uop_vpu_isMove(v35_io_in_bits_uop_vpu_isMove),
    .io_in_bits_uop_vpu_isDependOldVd(v35_io_in_bits_uop_vpu_isDependOldVd),
    .io_in_bits_uop_vpu_isWritePartVd(v35_io_in_bits_uop_vpu_isWritePartVd),
    .io_in_bits_uop_vpu_isVleff(v35_io_in_bits_uop_vpu_isVleff),
    .io_in_bits_uop_vlsInstr(v35_io_in_bits_uop_vlsInstr),
    .io_in_bits_uop_wfflags(v35_io_in_bits_uop_wfflags),
    .io_in_bits_uop_isMove(v35_io_in_bits_uop_isMove),
    .io_in_bits_uop_isDropAmocasSta(v35_io_in_bits_uop_isDropAmocasSta),
    .io_in_bits_uop_uopIdx(v35_io_in_bits_uop_uopIdx),
    .io_in_bits_uop_isVset(v35_io_in_bits_uop_isVset),
    .io_in_bits_uop_firstUop(v35_io_in_bits_uop_firstUop),
    .io_in_bits_uop_lastUop(v35_io_in_bits_uop_lastUop),
    .io_in_bits_uop_numUops(v35_io_in_bits_uop_numUops),
    .io_in_bits_uop_numWB(v35_io_in_bits_uop_numWB),
    .io_in_bits_uop_commitType(v35_io_in_bits_uop_commitType),
    .io_in_bits_uop_srcState_0(v35_io_in_bits_uop_srcState_0),
    .io_in_bits_uop_srcState_1(v35_io_in_bits_uop_srcState_1),
    .io_in_bits_uop_srcState_2(v35_io_in_bits_uop_srcState_2),
    .io_in_bits_uop_srcState_3(v35_io_in_bits_uop_srcState_3),
    .io_in_bits_uop_srcState_4(v35_io_in_bits_uop_srcState_4),
    .io_in_bits_uop_srcLoadDependency_0_0(v35_io_in_bits_uop_srcLoadDependency_0_0),
    .io_in_bits_uop_srcLoadDependency_0_1(v35_io_in_bits_uop_srcLoadDependency_0_1),
    .io_in_bits_uop_srcLoadDependency_0_2(v35_io_in_bits_uop_srcLoadDependency_0_2),
    .io_in_bits_uop_srcLoadDependency_1_0(v35_io_in_bits_uop_srcLoadDependency_1_0),
    .io_in_bits_uop_srcLoadDependency_1_1(v35_io_in_bits_uop_srcLoadDependency_1_1),
    .io_in_bits_uop_srcLoadDependency_1_2(v35_io_in_bits_uop_srcLoadDependency_1_2),
    .io_in_bits_uop_srcLoadDependency_2_0(v35_io_in_bits_uop_srcLoadDependency_2_0),
    .io_in_bits_uop_srcLoadDependency_2_1(v35_io_in_bits_uop_srcLoadDependency_2_1),
    .io_in_bits_uop_srcLoadDependency_2_2(v35_io_in_bits_uop_srcLoadDependency_2_2),
    .io_in_bits_uop_srcLoadDependency_3_0(v35_io_in_bits_uop_srcLoadDependency_3_0),
    .io_in_bits_uop_srcLoadDependency_3_1(v35_io_in_bits_uop_srcLoadDependency_3_1),
    .io_in_bits_uop_srcLoadDependency_3_2(v35_io_in_bits_uop_srcLoadDependency_3_2),
    .io_in_bits_uop_srcLoadDependency_4_0(v35_io_in_bits_uop_srcLoadDependency_4_0),
    .io_in_bits_uop_srcLoadDependency_4_1(v35_io_in_bits_uop_srcLoadDependency_4_1),
    .io_in_bits_uop_srcLoadDependency_4_2(v35_io_in_bits_uop_srcLoadDependency_4_2),
    .io_in_bits_uop_psrc_0(v35_io_in_bits_uop_psrc_0),
    .io_in_bits_uop_psrc_1(v35_io_in_bits_uop_psrc_1),
    .io_in_bits_uop_psrc_2(v35_io_in_bits_uop_psrc_2),
    .io_in_bits_uop_psrc_3(v35_io_in_bits_uop_psrc_3),
    .io_in_bits_uop_psrc_4(v35_io_in_bits_uop_psrc_4),
    .io_in_bits_uop_pdest(v35_io_in_bits_uop_pdest),
    .io_in_bits_uop_useRegCache_0(v35_io_in_bits_uop_useRegCache_0),
    .io_in_bits_uop_useRegCache_1(v35_io_in_bits_uop_useRegCache_1),
    .io_in_bits_uop_regCacheIdx_0(v35_io_in_bits_uop_regCacheIdx_0),
    .io_in_bits_uop_regCacheIdx_1(v35_io_in_bits_uop_regCacheIdx_1),
    .io_in_bits_uop_robIdx_flag(v35_io_in_bits_uop_robIdx_flag),
    .io_in_bits_uop_robIdx_value(v35_io_in_bits_uop_robIdx_value),
    .io_in_bits_uop_instrSize(v35_io_in_bits_uop_instrSize),
    .io_in_bits_uop_dirtyFs(v35_io_in_bits_uop_dirtyFs),
    .io_in_bits_uop_dirtyVs(v35_io_in_bits_uop_dirtyVs),
    .io_in_bits_uop_traceBlockInPipe_itype(v35_io_in_bits_uop_traceBlockInPipe_itype),
    .io_in_bits_uop_traceBlockInPipe_iretire(v35_io_in_bits_uop_traceBlockInPipe_iretire),
    .io_in_bits_uop_traceBlockInPipe_ilastsize(v35_io_in_bits_uop_traceBlockInPipe_ilastsize),
    .io_in_bits_uop_eliminatedMove(v35_io_in_bits_uop_eliminatedMove),
    .io_in_bits_uop_snapshot(v35_io_in_bits_uop_snapshot),
    .io_in_bits_uop_debugInfo_eliminatedMove(v35_io_in_bits_uop_debugInfo_eliminatedMove),
    .io_in_bits_uop_debugInfo_renameTime(v35_io_in_bits_uop_debugInfo_renameTime),
    .io_in_bits_uop_debugInfo_dispatchTime(v35_io_in_bits_uop_debugInfo_dispatchTime),
    .io_in_bits_uop_debugInfo_enqRsTime(v35_io_in_bits_uop_debugInfo_enqRsTime),
    .io_in_bits_uop_debugInfo_selectTime(v35_io_in_bits_uop_debugInfo_selectTime),
    .io_in_bits_uop_debugInfo_issueTime(v35_io_in_bits_uop_debugInfo_issueTime),
    .io_in_bits_uop_debugInfo_writebackTime(v35_io_in_bits_uop_debugInfo_writebackTime),
    .io_in_bits_uop_debugInfo_runahead_checkpoint_id(v35_io_in_bits_uop_debugInfo_runahead_checkpoint_id),
    .io_in_bits_uop_debugInfo_tlbFirstReqTime(v35_io_in_bits_uop_debugInfo_tlbFirstReqTime),
    .io_in_bits_uop_debugInfo_tlbRespTime(v35_io_in_bits_uop_debugInfo_tlbRespTime),
    .io_in_bits_uop_debug_seqNum_seqNum(v35_io_in_bits_uop_debug_seqNum_seqNum),
    .io_in_bits_uop_debug_seqNum_uopIdx(v35_io_in_bits_uop_debug_seqNum_uopIdx),
    .io_in_bits_uop_storeSetHit(v35_io_in_bits_uop_storeSetHit),
    .io_in_bits_uop_waitForRobIdx_flag(v35_io_in_bits_uop_waitForRobIdx_flag),
    .io_in_bits_uop_waitForRobIdx_value(v35_io_in_bits_uop_waitForRobIdx_value),
    .io_in_bits_uop_loadWaitBit(v35_io_in_bits_uop_loadWaitBit),
    .io_in_bits_uop_loadWaitStrict(v35_io_in_bits_uop_loadWaitStrict),
    .io_in_bits_uop_ssid(v35_io_in_bits_uop_ssid),
    .io_in_bits_uop_lqIdx_flag(v35_io_in_bits_uop_lqIdx_flag),
    .io_in_bits_uop_lqIdx_value(v35_io_in_bits_uop_lqIdx_value),
    .io_in_bits_uop_sqIdx_flag(v35_io_in_bits_uop_sqIdx_flag),
    .io_in_bits_uop_sqIdx_value(v35_io_in_bits_uop_sqIdx_value),
    .io_in_bits_uop_singleStep(v35_io_in_bits_uop_singleStep),
    .io_in_bits_uop_replayInst(v35_io_in_bits_uop_replayInst),
    .io_in_bits_uop_debug_fuType(v35_io_in_bits_uop_debug_fuType),
    .io_in_bits_uop_debug_sim_trig(v35_io_in_bits_uop_debug_sim_trig),
    .io_in_bits_uop_numLsElem(v35_io_in_bits_uop_numLsElem),
    .io_in_bits_mBIndex(v35_io_in_bits_mBIndex),
    .io_in_bits_elemIdx(v35_io_in_bits_elemIdx),
    .io_in_bits_elemIdxInsideVd(v35_io_in_bits_elemIdxInsideVd),
    .io_in_bits_splitIndex(v35_io_in_bits_splitIndex),
    .io_out_ready(v35_io_out_ready),
    .io_rightOutFire(v35_io_rightOutFire),
    .io_isFlush(v35_io_isFlush),
    .io_in_ready(g_v35_io_in_ready),
    .io_out_valid(g_v35_io_out_valid),
    .io_out_bits_vaddr(g_v35_io_out_bits_vaddr),
    .io_out_bits_basevaddr(g_v35_io_out_bits_basevaddr),
    .io_out_bits_mask(g_v35_io_out_bits_mask),
    .io_out_bits_reg_offset(g_v35_io_out_bits_reg_offset),
    .io_out_bits_alignedType(g_v35_io_out_bits_alignedType),
    .io_out_bits_vecActive(g_v35_io_out_bits_vecActive),
    .io_out_bits_vecIsFirstActiveElement(g_v35_io_out_bits_vecIsFirstActiveElement),
    .io_out_bits_uop_instr(g_v35_io_out_bits_uop_instr),
    .io_out_bits_uop_pc(g_v35_io_out_bits_uop_pc),
    .io_out_bits_uop_foldpc(g_v35_io_out_bits_uop_foldpc),
    .io_out_bits_uop_exceptionVec_4(g_v35_io_out_bits_uop_exceptionVec_4),
    .io_out_bits_uop_exceptionVec_5(g_v35_io_out_bits_uop_exceptionVec_5),
    .io_out_bits_uop_exceptionVec_6(g_v35_io_out_bits_uop_exceptionVec_6),
    .io_out_bits_uop_exceptionVec_7(g_v35_io_out_bits_uop_exceptionVec_7),
    .io_out_bits_uop_exceptionVec_13(g_v35_io_out_bits_uop_exceptionVec_13),
    .io_out_bits_uop_exceptionVec_15(g_v35_io_out_bits_uop_exceptionVec_15),
    .io_out_bits_uop_exceptionVec_19(g_v35_io_out_bits_uop_exceptionVec_19),
    .io_out_bits_uop_exceptionVec_21(g_v35_io_out_bits_uop_exceptionVec_21),
    .io_out_bits_uop_exceptionVec_23(g_v35_io_out_bits_uop_exceptionVec_23),
    .io_out_bits_uop_isFetchMalAddr(g_v35_io_out_bits_uop_isFetchMalAddr),
    .io_out_bits_uop_hasException(g_v35_io_out_bits_uop_hasException),
    .io_out_bits_uop_trigger(g_v35_io_out_bits_uop_trigger),
    .io_out_bits_uop_preDecodeInfo_valid(g_v35_io_out_bits_uop_preDecodeInfo_valid),
    .io_out_bits_uop_preDecodeInfo_isRVC(g_v35_io_out_bits_uop_preDecodeInfo_isRVC),
    .io_out_bits_uop_preDecodeInfo_brType(g_v35_io_out_bits_uop_preDecodeInfo_brType),
    .io_out_bits_uop_preDecodeInfo_isCall(g_v35_io_out_bits_uop_preDecodeInfo_isCall),
    .io_out_bits_uop_preDecodeInfo_isRet(g_v35_io_out_bits_uop_preDecodeInfo_isRet),
    .io_out_bits_uop_pred_taken(g_v35_io_out_bits_uop_pred_taken),
    .io_out_bits_uop_crossPageIPFFix(g_v35_io_out_bits_uop_crossPageIPFFix),
    .io_out_bits_uop_ftqPtr_flag(g_v35_io_out_bits_uop_ftqPtr_flag),
    .io_out_bits_uop_ftqPtr_value(g_v35_io_out_bits_uop_ftqPtr_value),
    .io_out_bits_uop_ftqOffset(g_v35_io_out_bits_uop_ftqOffset),
    .io_out_bits_uop_satpFlushFirstFetchFault(g_v35_io_out_bits_uop_satpFlushFirstFetchFault),
    .io_out_bits_uop_srcType_0(g_v35_io_out_bits_uop_srcType_0),
    .io_out_bits_uop_srcType_1(g_v35_io_out_bits_uop_srcType_1),
    .io_out_bits_uop_srcType_2(g_v35_io_out_bits_uop_srcType_2),
    .io_out_bits_uop_srcType_3(g_v35_io_out_bits_uop_srcType_3),
    .io_out_bits_uop_srcType_4(g_v35_io_out_bits_uop_srcType_4),
    .io_out_bits_uop_ldest(g_v35_io_out_bits_uop_ldest),
    .io_out_bits_uop_fuType(g_v35_io_out_bits_uop_fuType),
    .io_out_bits_uop_fuOpType(g_v35_io_out_bits_uop_fuOpType),
    .io_out_bits_uop_rfWen(g_v35_io_out_bits_uop_rfWen),
    .io_out_bits_uop_fpWen(g_v35_io_out_bits_uop_fpWen),
    .io_out_bits_uop_vecWen(g_v35_io_out_bits_uop_vecWen),
    .io_out_bits_uop_v0Wen(g_v35_io_out_bits_uop_v0Wen),
    .io_out_bits_uop_vlWen(g_v35_io_out_bits_uop_vlWen),
    .io_out_bits_uop_isXSTrap(g_v35_io_out_bits_uop_isXSTrap),
    .io_out_bits_uop_waitForward(g_v35_io_out_bits_uop_waitForward),
    .io_out_bits_uop_blockBackward(g_v35_io_out_bits_uop_blockBackward),
    .io_out_bits_uop_canRobCompress(g_v35_io_out_bits_uop_canRobCompress),
    .io_out_bits_uop_selImm(g_v35_io_out_bits_uop_selImm),
    .io_out_bits_uop_fpu_typeTagOut(g_v35_io_out_bits_uop_fpu_typeTagOut),
    .io_out_bits_uop_fpu_wflags(g_v35_io_out_bits_uop_fpu_wflags),
    .io_out_bits_uop_fpu_typ(g_v35_io_out_bits_uop_fpu_typ),
    .io_out_bits_uop_fpu_fmt(g_v35_io_out_bits_uop_fpu_fmt),
    .io_out_bits_uop_fpu_rm(g_v35_io_out_bits_uop_fpu_rm),
    .io_out_bits_uop_vpu_vill(g_v35_io_out_bits_uop_vpu_vill),
    .io_out_bits_uop_vpu_vma(g_v35_io_out_bits_uop_vpu_vma),
    .io_out_bits_uop_vpu_vta(g_v35_io_out_bits_uop_vpu_vta),
    .io_out_bits_uop_vpu_vsew(g_v35_io_out_bits_uop_vpu_vsew),
    .io_out_bits_uop_vpu_vlmul(g_v35_io_out_bits_uop_vpu_vlmul),
    .io_out_bits_uop_vpu_specVill(g_v35_io_out_bits_uop_vpu_specVill),
    .io_out_bits_uop_vpu_specVma(g_v35_io_out_bits_uop_vpu_specVma),
    .io_out_bits_uop_vpu_specVta(g_v35_io_out_bits_uop_vpu_specVta),
    .io_out_bits_uop_vpu_specVsew(g_v35_io_out_bits_uop_vpu_specVsew),
    .io_out_bits_uop_vpu_specVlmul(g_v35_io_out_bits_uop_vpu_specVlmul),
    .io_out_bits_uop_vpu_vm(g_v35_io_out_bits_uop_vpu_vm),
    .io_out_bits_uop_vpu_vstart(g_v35_io_out_bits_uop_vpu_vstart),
    .io_out_bits_uop_vpu_frm(g_v35_io_out_bits_uop_vpu_frm),
    .io_out_bits_uop_vpu_fpu_isFpToVecInst(g_v35_io_out_bits_uop_vpu_fpu_isFpToVecInst),
    .io_out_bits_uop_vpu_fpu_isFP32Instr(g_v35_io_out_bits_uop_vpu_fpu_isFP32Instr),
    .io_out_bits_uop_vpu_fpu_isFP64Instr(g_v35_io_out_bits_uop_vpu_fpu_isFP64Instr),
    .io_out_bits_uop_vpu_fpu_isReduction(g_v35_io_out_bits_uop_vpu_fpu_isReduction),
    .io_out_bits_uop_vpu_fpu_isFoldTo1_2(g_v35_io_out_bits_uop_vpu_fpu_isFoldTo1_2),
    .io_out_bits_uop_vpu_fpu_isFoldTo1_4(g_v35_io_out_bits_uop_vpu_fpu_isFoldTo1_4),
    .io_out_bits_uop_vpu_fpu_isFoldTo1_8(g_v35_io_out_bits_uop_vpu_fpu_isFoldTo1_8),
    .io_out_bits_uop_vpu_vxrm(g_v35_io_out_bits_uop_vpu_vxrm),
    .io_out_bits_uop_vpu_vuopIdx(g_v35_io_out_bits_uop_vpu_vuopIdx),
    .io_out_bits_uop_vpu_lastUop(g_v35_io_out_bits_uop_vpu_lastUop),
    .io_out_bits_uop_vpu_vmask(g_v35_io_out_bits_uop_vpu_vmask),
    .io_out_bits_uop_vpu_vl(g_v35_io_out_bits_uop_vpu_vl),
    .io_out_bits_uop_vpu_nf(g_v35_io_out_bits_uop_vpu_nf),
    .io_out_bits_uop_vpu_veew(g_v35_io_out_bits_uop_vpu_veew),
    .io_out_bits_uop_vpu_isReverse(g_v35_io_out_bits_uop_vpu_isReverse),
    .io_out_bits_uop_vpu_isExt(g_v35_io_out_bits_uop_vpu_isExt),
    .io_out_bits_uop_vpu_isNarrow(g_v35_io_out_bits_uop_vpu_isNarrow),
    .io_out_bits_uop_vpu_isDstMask(g_v35_io_out_bits_uop_vpu_isDstMask),
    .io_out_bits_uop_vpu_isOpMask(g_v35_io_out_bits_uop_vpu_isOpMask),
    .io_out_bits_uop_vpu_isMove(g_v35_io_out_bits_uop_vpu_isMove),
    .io_out_bits_uop_vpu_isDependOldVd(g_v35_io_out_bits_uop_vpu_isDependOldVd),
    .io_out_bits_uop_vpu_isWritePartVd(g_v35_io_out_bits_uop_vpu_isWritePartVd),
    .io_out_bits_uop_vpu_isVleff(g_v35_io_out_bits_uop_vpu_isVleff),
    .io_out_bits_uop_vlsInstr(g_v35_io_out_bits_uop_vlsInstr),
    .io_out_bits_uop_wfflags(g_v35_io_out_bits_uop_wfflags),
    .io_out_bits_uop_isMove(g_v35_io_out_bits_uop_isMove),
    .io_out_bits_uop_isDropAmocasSta(g_v35_io_out_bits_uop_isDropAmocasSta),
    .io_out_bits_uop_uopIdx(g_v35_io_out_bits_uop_uopIdx),
    .io_out_bits_uop_isVset(g_v35_io_out_bits_uop_isVset),
    .io_out_bits_uop_firstUop(g_v35_io_out_bits_uop_firstUop),
    .io_out_bits_uop_lastUop(g_v35_io_out_bits_uop_lastUop),
    .io_out_bits_uop_numUops(g_v35_io_out_bits_uop_numUops),
    .io_out_bits_uop_numWB(g_v35_io_out_bits_uop_numWB),
    .io_out_bits_uop_commitType(g_v35_io_out_bits_uop_commitType),
    .io_out_bits_uop_srcState_0(g_v35_io_out_bits_uop_srcState_0),
    .io_out_bits_uop_srcState_1(g_v35_io_out_bits_uop_srcState_1),
    .io_out_bits_uop_srcState_2(g_v35_io_out_bits_uop_srcState_2),
    .io_out_bits_uop_srcState_3(g_v35_io_out_bits_uop_srcState_3),
    .io_out_bits_uop_srcState_4(g_v35_io_out_bits_uop_srcState_4),
    .io_out_bits_uop_srcLoadDependency_0_0(g_v35_io_out_bits_uop_srcLoadDependency_0_0),
    .io_out_bits_uop_srcLoadDependency_0_1(g_v35_io_out_bits_uop_srcLoadDependency_0_1),
    .io_out_bits_uop_srcLoadDependency_0_2(g_v35_io_out_bits_uop_srcLoadDependency_0_2),
    .io_out_bits_uop_srcLoadDependency_1_0(g_v35_io_out_bits_uop_srcLoadDependency_1_0),
    .io_out_bits_uop_srcLoadDependency_1_1(g_v35_io_out_bits_uop_srcLoadDependency_1_1),
    .io_out_bits_uop_srcLoadDependency_1_2(g_v35_io_out_bits_uop_srcLoadDependency_1_2),
    .io_out_bits_uop_srcLoadDependency_2_0(g_v35_io_out_bits_uop_srcLoadDependency_2_0),
    .io_out_bits_uop_srcLoadDependency_2_1(g_v35_io_out_bits_uop_srcLoadDependency_2_1),
    .io_out_bits_uop_srcLoadDependency_2_2(g_v35_io_out_bits_uop_srcLoadDependency_2_2),
    .io_out_bits_uop_srcLoadDependency_3_0(g_v35_io_out_bits_uop_srcLoadDependency_3_0),
    .io_out_bits_uop_srcLoadDependency_3_1(g_v35_io_out_bits_uop_srcLoadDependency_3_1),
    .io_out_bits_uop_srcLoadDependency_3_2(g_v35_io_out_bits_uop_srcLoadDependency_3_2),
    .io_out_bits_uop_srcLoadDependency_4_0(g_v35_io_out_bits_uop_srcLoadDependency_4_0),
    .io_out_bits_uop_srcLoadDependency_4_1(g_v35_io_out_bits_uop_srcLoadDependency_4_1),
    .io_out_bits_uop_srcLoadDependency_4_2(g_v35_io_out_bits_uop_srcLoadDependency_4_2),
    .io_out_bits_uop_psrc_0(g_v35_io_out_bits_uop_psrc_0),
    .io_out_bits_uop_psrc_1(g_v35_io_out_bits_uop_psrc_1),
    .io_out_bits_uop_psrc_2(g_v35_io_out_bits_uop_psrc_2),
    .io_out_bits_uop_psrc_3(g_v35_io_out_bits_uop_psrc_3),
    .io_out_bits_uop_psrc_4(g_v35_io_out_bits_uop_psrc_4),
    .io_out_bits_uop_pdest(g_v35_io_out_bits_uop_pdest),
    .io_out_bits_uop_useRegCache_0(g_v35_io_out_bits_uop_useRegCache_0),
    .io_out_bits_uop_useRegCache_1(g_v35_io_out_bits_uop_useRegCache_1),
    .io_out_bits_uop_regCacheIdx_0(g_v35_io_out_bits_uop_regCacheIdx_0),
    .io_out_bits_uop_regCacheIdx_1(g_v35_io_out_bits_uop_regCacheIdx_1),
    .io_out_bits_uop_robIdx_flag(g_v35_io_out_bits_uop_robIdx_flag),
    .io_out_bits_uop_robIdx_value(g_v35_io_out_bits_uop_robIdx_value),
    .io_out_bits_uop_instrSize(g_v35_io_out_bits_uop_instrSize),
    .io_out_bits_uop_dirtyFs(g_v35_io_out_bits_uop_dirtyFs),
    .io_out_bits_uop_dirtyVs(g_v35_io_out_bits_uop_dirtyVs),
    .io_out_bits_uop_traceBlockInPipe_itype(g_v35_io_out_bits_uop_traceBlockInPipe_itype),
    .io_out_bits_uop_traceBlockInPipe_iretire(g_v35_io_out_bits_uop_traceBlockInPipe_iretire),
    .io_out_bits_uop_traceBlockInPipe_ilastsize(g_v35_io_out_bits_uop_traceBlockInPipe_ilastsize),
    .io_out_bits_uop_eliminatedMove(g_v35_io_out_bits_uop_eliminatedMove),
    .io_out_bits_uop_snapshot(g_v35_io_out_bits_uop_snapshot),
    .io_out_bits_uop_debugInfo_eliminatedMove(g_v35_io_out_bits_uop_debugInfo_eliminatedMove),
    .io_out_bits_uop_debugInfo_renameTime(g_v35_io_out_bits_uop_debugInfo_renameTime),
    .io_out_bits_uop_debugInfo_dispatchTime(g_v35_io_out_bits_uop_debugInfo_dispatchTime),
    .io_out_bits_uop_debugInfo_enqRsTime(g_v35_io_out_bits_uop_debugInfo_enqRsTime),
    .io_out_bits_uop_debugInfo_selectTime(g_v35_io_out_bits_uop_debugInfo_selectTime),
    .io_out_bits_uop_debugInfo_issueTime(g_v35_io_out_bits_uop_debugInfo_issueTime),
    .io_out_bits_uop_debugInfo_writebackTime(g_v35_io_out_bits_uop_debugInfo_writebackTime),
    .io_out_bits_uop_debugInfo_runahead_checkpoint_id(g_v35_io_out_bits_uop_debugInfo_runahead_checkpoint_id),
    .io_out_bits_uop_debugInfo_tlbFirstReqTime(g_v35_io_out_bits_uop_debugInfo_tlbFirstReqTime),
    .io_out_bits_uop_debugInfo_tlbRespTime(g_v35_io_out_bits_uop_debugInfo_tlbRespTime),
    .io_out_bits_uop_debug_seqNum_seqNum(g_v35_io_out_bits_uop_debug_seqNum_seqNum),
    .io_out_bits_uop_debug_seqNum_uopIdx(g_v35_io_out_bits_uop_debug_seqNum_uopIdx),
    .io_out_bits_uop_storeSetHit(g_v35_io_out_bits_uop_storeSetHit),
    .io_out_bits_uop_waitForRobIdx_flag(g_v35_io_out_bits_uop_waitForRobIdx_flag),
    .io_out_bits_uop_waitForRobIdx_value(g_v35_io_out_bits_uop_waitForRobIdx_value),
    .io_out_bits_uop_loadWaitBit(g_v35_io_out_bits_uop_loadWaitBit),
    .io_out_bits_uop_loadWaitStrict(g_v35_io_out_bits_uop_loadWaitStrict),
    .io_out_bits_uop_ssid(g_v35_io_out_bits_uop_ssid),
    .io_out_bits_uop_lqIdx_flag(g_v35_io_out_bits_uop_lqIdx_flag),
    .io_out_bits_uop_lqIdx_value(g_v35_io_out_bits_uop_lqIdx_value),
    .io_out_bits_uop_sqIdx_flag(g_v35_io_out_bits_uop_sqIdx_flag),
    .io_out_bits_uop_sqIdx_value(g_v35_io_out_bits_uop_sqIdx_value),
    .io_out_bits_uop_singleStep(g_v35_io_out_bits_uop_singleStep),
    .io_out_bits_uop_replayInst(g_v35_io_out_bits_uop_replayInst),
    .io_out_bits_uop_debug_fuType(g_v35_io_out_bits_uop_debug_fuType),
    .io_out_bits_uop_debug_sim_trig(g_v35_io_out_bits_uop_debug_sim_trig),
    .io_out_bits_uop_numLsElem(g_v35_io_out_bits_uop_numLsElem),
    .io_out_bits_mBIndex(g_v35_io_out_bits_mBIndex),
    .io_out_bits_elemIdx(g_v35_io_out_bits_elemIdx),
    .io_out_bits_elemIdxInsideVd(g_v35_io_out_bits_elemIdxInsideVd),
    .io_out_bits_splitIndex(g_v35_io_out_bits_splitIndex)
  );
  NewPipelineConnectPipe_35_xs u_i_v35 (
    .clock(clock), .reset(reset),
    .io_in_valid(v35_io_in_valid),
    .io_in_bits_vaddr(v35_io_in_bits_vaddr),
    .io_in_bits_basevaddr(v35_io_in_bits_basevaddr),
    .io_in_bits_mask(v35_io_in_bits_mask),
    .io_in_bits_reg_offset(v35_io_in_bits_reg_offset),
    .io_in_bits_alignedType(v35_io_in_bits_alignedType),
    .io_in_bits_vecActive(v35_io_in_bits_vecActive),
    .io_in_bits_vecIsFirstActiveElement(v35_io_in_bits_vecIsFirstActiveElement),
    .io_in_bits_uop_instr(v35_io_in_bits_uop_instr),
    .io_in_bits_uop_pc(v35_io_in_bits_uop_pc),
    .io_in_bits_uop_foldpc(v35_io_in_bits_uop_foldpc),
    .io_in_bits_uop_exceptionVec_4(v35_io_in_bits_uop_exceptionVec_4),
    .io_in_bits_uop_exceptionVec_5(v35_io_in_bits_uop_exceptionVec_5),
    .io_in_bits_uop_exceptionVec_6(v35_io_in_bits_uop_exceptionVec_6),
    .io_in_bits_uop_exceptionVec_7(v35_io_in_bits_uop_exceptionVec_7),
    .io_in_bits_uop_exceptionVec_13(v35_io_in_bits_uop_exceptionVec_13),
    .io_in_bits_uop_exceptionVec_15(v35_io_in_bits_uop_exceptionVec_15),
    .io_in_bits_uop_exceptionVec_19(v35_io_in_bits_uop_exceptionVec_19),
    .io_in_bits_uop_exceptionVec_21(v35_io_in_bits_uop_exceptionVec_21),
    .io_in_bits_uop_exceptionVec_23(v35_io_in_bits_uop_exceptionVec_23),
    .io_in_bits_uop_isFetchMalAddr(v35_io_in_bits_uop_isFetchMalAddr),
    .io_in_bits_uop_hasException(v35_io_in_bits_uop_hasException),
    .io_in_bits_uop_trigger(v35_io_in_bits_uop_trigger),
    .io_in_bits_uop_preDecodeInfo_valid(v35_io_in_bits_uop_preDecodeInfo_valid),
    .io_in_bits_uop_preDecodeInfo_isRVC(v35_io_in_bits_uop_preDecodeInfo_isRVC),
    .io_in_bits_uop_preDecodeInfo_brType(v35_io_in_bits_uop_preDecodeInfo_brType),
    .io_in_bits_uop_preDecodeInfo_isCall(v35_io_in_bits_uop_preDecodeInfo_isCall),
    .io_in_bits_uop_preDecodeInfo_isRet(v35_io_in_bits_uop_preDecodeInfo_isRet),
    .io_in_bits_uop_pred_taken(v35_io_in_bits_uop_pred_taken),
    .io_in_bits_uop_crossPageIPFFix(v35_io_in_bits_uop_crossPageIPFFix),
    .io_in_bits_uop_ftqPtr_flag(v35_io_in_bits_uop_ftqPtr_flag),
    .io_in_bits_uop_ftqPtr_value(v35_io_in_bits_uop_ftqPtr_value),
    .io_in_bits_uop_ftqOffset(v35_io_in_bits_uop_ftqOffset),
    .io_in_bits_uop_satpFlushFirstFetchFault(v35_io_in_bits_uop_satpFlushFirstFetchFault),
    .io_in_bits_uop_srcType_0(v35_io_in_bits_uop_srcType_0),
    .io_in_bits_uop_srcType_1(v35_io_in_bits_uop_srcType_1),
    .io_in_bits_uop_srcType_2(v35_io_in_bits_uop_srcType_2),
    .io_in_bits_uop_srcType_3(v35_io_in_bits_uop_srcType_3),
    .io_in_bits_uop_srcType_4(v35_io_in_bits_uop_srcType_4),
    .io_in_bits_uop_ldest(v35_io_in_bits_uop_ldest),
    .io_in_bits_uop_fuType(v35_io_in_bits_uop_fuType),
    .io_in_bits_uop_fuOpType(v35_io_in_bits_uop_fuOpType),
    .io_in_bits_uop_rfWen(v35_io_in_bits_uop_rfWen),
    .io_in_bits_uop_fpWen(v35_io_in_bits_uop_fpWen),
    .io_in_bits_uop_vecWen(v35_io_in_bits_uop_vecWen),
    .io_in_bits_uop_v0Wen(v35_io_in_bits_uop_v0Wen),
    .io_in_bits_uop_vlWen(v35_io_in_bits_uop_vlWen),
    .io_in_bits_uop_isXSTrap(v35_io_in_bits_uop_isXSTrap),
    .io_in_bits_uop_waitForward(v35_io_in_bits_uop_waitForward),
    .io_in_bits_uop_blockBackward(v35_io_in_bits_uop_blockBackward),
    .io_in_bits_uop_canRobCompress(v35_io_in_bits_uop_canRobCompress),
    .io_in_bits_uop_selImm(v35_io_in_bits_uop_selImm),
    .io_in_bits_uop_fpu_typeTagOut(v35_io_in_bits_uop_fpu_typeTagOut),
    .io_in_bits_uop_fpu_wflags(v35_io_in_bits_uop_fpu_wflags),
    .io_in_bits_uop_fpu_typ(v35_io_in_bits_uop_fpu_typ),
    .io_in_bits_uop_fpu_fmt(v35_io_in_bits_uop_fpu_fmt),
    .io_in_bits_uop_fpu_rm(v35_io_in_bits_uop_fpu_rm),
    .io_in_bits_uop_vpu_vill(v35_io_in_bits_uop_vpu_vill),
    .io_in_bits_uop_vpu_vma(v35_io_in_bits_uop_vpu_vma),
    .io_in_bits_uop_vpu_vta(v35_io_in_bits_uop_vpu_vta),
    .io_in_bits_uop_vpu_vsew(v35_io_in_bits_uop_vpu_vsew),
    .io_in_bits_uop_vpu_vlmul(v35_io_in_bits_uop_vpu_vlmul),
    .io_in_bits_uop_vpu_specVill(v35_io_in_bits_uop_vpu_specVill),
    .io_in_bits_uop_vpu_specVma(v35_io_in_bits_uop_vpu_specVma),
    .io_in_bits_uop_vpu_specVta(v35_io_in_bits_uop_vpu_specVta),
    .io_in_bits_uop_vpu_specVsew(v35_io_in_bits_uop_vpu_specVsew),
    .io_in_bits_uop_vpu_specVlmul(v35_io_in_bits_uop_vpu_specVlmul),
    .io_in_bits_uop_vpu_vm(v35_io_in_bits_uop_vpu_vm),
    .io_in_bits_uop_vpu_vstart(v35_io_in_bits_uop_vpu_vstart),
    .io_in_bits_uop_vpu_frm(v35_io_in_bits_uop_vpu_frm),
    .io_in_bits_uop_vpu_fpu_isFpToVecInst(v35_io_in_bits_uop_vpu_fpu_isFpToVecInst),
    .io_in_bits_uop_vpu_fpu_isFP32Instr(v35_io_in_bits_uop_vpu_fpu_isFP32Instr),
    .io_in_bits_uop_vpu_fpu_isFP64Instr(v35_io_in_bits_uop_vpu_fpu_isFP64Instr),
    .io_in_bits_uop_vpu_fpu_isReduction(v35_io_in_bits_uop_vpu_fpu_isReduction),
    .io_in_bits_uop_vpu_fpu_isFoldTo1_2(v35_io_in_bits_uop_vpu_fpu_isFoldTo1_2),
    .io_in_bits_uop_vpu_fpu_isFoldTo1_4(v35_io_in_bits_uop_vpu_fpu_isFoldTo1_4),
    .io_in_bits_uop_vpu_fpu_isFoldTo1_8(v35_io_in_bits_uop_vpu_fpu_isFoldTo1_8),
    .io_in_bits_uop_vpu_vxrm(v35_io_in_bits_uop_vpu_vxrm),
    .io_in_bits_uop_vpu_vuopIdx(v35_io_in_bits_uop_vpu_vuopIdx),
    .io_in_bits_uop_vpu_lastUop(v35_io_in_bits_uop_vpu_lastUop),
    .io_in_bits_uop_vpu_vmask(v35_io_in_bits_uop_vpu_vmask),
    .io_in_bits_uop_vpu_vl(v35_io_in_bits_uop_vpu_vl),
    .io_in_bits_uop_vpu_nf(v35_io_in_bits_uop_vpu_nf),
    .io_in_bits_uop_vpu_veew(v35_io_in_bits_uop_vpu_veew),
    .io_in_bits_uop_vpu_isReverse(v35_io_in_bits_uop_vpu_isReverse),
    .io_in_bits_uop_vpu_isExt(v35_io_in_bits_uop_vpu_isExt),
    .io_in_bits_uop_vpu_isNarrow(v35_io_in_bits_uop_vpu_isNarrow),
    .io_in_bits_uop_vpu_isDstMask(v35_io_in_bits_uop_vpu_isDstMask),
    .io_in_bits_uop_vpu_isOpMask(v35_io_in_bits_uop_vpu_isOpMask),
    .io_in_bits_uop_vpu_isMove(v35_io_in_bits_uop_vpu_isMove),
    .io_in_bits_uop_vpu_isDependOldVd(v35_io_in_bits_uop_vpu_isDependOldVd),
    .io_in_bits_uop_vpu_isWritePartVd(v35_io_in_bits_uop_vpu_isWritePartVd),
    .io_in_bits_uop_vpu_isVleff(v35_io_in_bits_uop_vpu_isVleff),
    .io_in_bits_uop_vlsInstr(v35_io_in_bits_uop_vlsInstr),
    .io_in_bits_uop_wfflags(v35_io_in_bits_uop_wfflags),
    .io_in_bits_uop_isMove(v35_io_in_bits_uop_isMove),
    .io_in_bits_uop_isDropAmocasSta(v35_io_in_bits_uop_isDropAmocasSta),
    .io_in_bits_uop_uopIdx(v35_io_in_bits_uop_uopIdx),
    .io_in_bits_uop_isVset(v35_io_in_bits_uop_isVset),
    .io_in_bits_uop_firstUop(v35_io_in_bits_uop_firstUop),
    .io_in_bits_uop_lastUop(v35_io_in_bits_uop_lastUop),
    .io_in_bits_uop_numUops(v35_io_in_bits_uop_numUops),
    .io_in_bits_uop_numWB(v35_io_in_bits_uop_numWB),
    .io_in_bits_uop_commitType(v35_io_in_bits_uop_commitType),
    .io_in_bits_uop_srcState_0(v35_io_in_bits_uop_srcState_0),
    .io_in_bits_uop_srcState_1(v35_io_in_bits_uop_srcState_1),
    .io_in_bits_uop_srcState_2(v35_io_in_bits_uop_srcState_2),
    .io_in_bits_uop_srcState_3(v35_io_in_bits_uop_srcState_3),
    .io_in_bits_uop_srcState_4(v35_io_in_bits_uop_srcState_4),
    .io_in_bits_uop_srcLoadDependency_0_0(v35_io_in_bits_uop_srcLoadDependency_0_0),
    .io_in_bits_uop_srcLoadDependency_0_1(v35_io_in_bits_uop_srcLoadDependency_0_1),
    .io_in_bits_uop_srcLoadDependency_0_2(v35_io_in_bits_uop_srcLoadDependency_0_2),
    .io_in_bits_uop_srcLoadDependency_1_0(v35_io_in_bits_uop_srcLoadDependency_1_0),
    .io_in_bits_uop_srcLoadDependency_1_1(v35_io_in_bits_uop_srcLoadDependency_1_1),
    .io_in_bits_uop_srcLoadDependency_1_2(v35_io_in_bits_uop_srcLoadDependency_1_2),
    .io_in_bits_uop_srcLoadDependency_2_0(v35_io_in_bits_uop_srcLoadDependency_2_0),
    .io_in_bits_uop_srcLoadDependency_2_1(v35_io_in_bits_uop_srcLoadDependency_2_1),
    .io_in_bits_uop_srcLoadDependency_2_2(v35_io_in_bits_uop_srcLoadDependency_2_2),
    .io_in_bits_uop_srcLoadDependency_3_0(v35_io_in_bits_uop_srcLoadDependency_3_0),
    .io_in_bits_uop_srcLoadDependency_3_1(v35_io_in_bits_uop_srcLoadDependency_3_1),
    .io_in_bits_uop_srcLoadDependency_3_2(v35_io_in_bits_uop_srcLoadDependency_3_2),
    .io_in_bits_uop_srcLoadDependency_4_0(v35_io_in_bits_uop_srcLoadDependency_4_0),
    .io_in_bits_uop_srcLoadDependency_4_1(v35_io_in_bits_uop_srcLoadDependency_4_1),
    .io_in_bits_uop_srcLoadDependency_4_2(v35_io_in_bits_uop_srcLoadDependency_4_2),
    .io_in_bits_uop_psrc_0(v35_io_in_bits_uop_psrc_0),
    .io_in_bits_uop_psrc_1(v35_io_in_bits_uop_psrc_1),
    .io_in_bits_uop_psrc_2(v35_io_in_bits_uop_psrc_2),
    .io_in_bits_uop_psrc_3(v35_io_in_bits_uop_psrc_3),
    .io_in_bits_uop_psrc_4(v35_io_in_bits_uop_psrc_4),
    .io_in_bits_uop_pdest(v35_io_in_bits_uop_pdest),
    .io_in_bits_uop_useRegCache_0(v35_io_in_bits_uop_useRegCache_0),
    .io_in_bits_uop_useRegCache_1(v35_io_in_bits_uop_useRegCache_1),
    .io_in_bits_uop_regCacheIdx_0(v35_io_in_bits_uop_regCacheIdx_0),
    .io_in_bits_uop_regCacheIdx_1(v35_io_in_bits_uop_regCacheIdx_1),
    .io_in_bits_uop_robIdx_flag(v35_io_in_bits_uop_robIdx_flag),
    .io_in_bits_uop_robIdx_value(v35_io_in_bits_uop_robIdx_value),
    .io_in_bits_uop_instrSize(v35_io_in_bits_uop_instrSize),
    .io_in_bits_uop_dirtyFs(v35_io_in_bits_uop_dirtyFs),
    .io_in_bits_uop_dirtyVs(v35_io_in_bits_uop_dirtyVs),
    .io_in_bits_uop_traceBlockInPipe_itype(v35_io_in_bits_uop_traceBlockInPipe_itype),
    .io_in_bits_uop_traceBlockInPipe_iretire(v35_io_in_bits_uop_traceBlockInPipe_iretire),
    .io_in_bits_uop_traceBlockInPipe_ilastsize(v35_io_in_bits_uop_traceBlockInPipe_ilastsize),
    .io_in_bits_uop_eliminatedMove(v35_io_in_bits_uop_eliminatedMove),
    .io_in_bits_uop_snapshot(v35_io_in_bits_uop_snapshot),
    .io_in_bits_uop_debugInfo_eliminatedMove(v35_io_in_bits_uop_debugInfo_eliminatedMove),
    .io_in_bits_uop_debugInfo_renameTime(v35_io_in_bits_uop_debugInfo_renameTime),
    .io_in_bits_uop_debugInfo_dispatchTime(v35_io_in_bits_uop_debugInfo_dispatchTime),
    .io_in_bits_uop_debugInfo_enqRsTime(v35_io_in_bits_uop_debugInfo_enqRsTime),
    .io_in_bits_uop_debugInfo_selectTime(v35_io_in_bits_uop_debugInfo_selectTime),
    .io_in_bits_uop_debugInfo_issueTime(v35_io_in_bits_uop_debugInfo_issueTime),
    .io_in_bits_uop_debugInfo_writebackTime(v35_io_in_bits_uop_debugInfo_writebackTime),
    .io_in_bits_uop_debugInfo_runahead_checkpoint_id(v35_io_in_bits_uop_debugInfo_runahead_checkpoint_id),
    .io_in_bits_uop_debugInfo_tlbFirstReqTime(v35_io_in_bits_uop_debugInfo_tlbFirstReqTime),
    .io_in_bits_uop_debugInfo_tlbRespTime(v35_io_in_bits_uop_debugInfo_tlbRespTime),
    .io_in_bits_uop_debug_seqNum_seqNum(v35_io_in_bits_uop_debug_seqNum_seqNum),
    .io_in_bits_uop_debug_seqNum_uopIdx(v35_io_in_bits_uop_debug_seqNum_uopIdx),
    .io_in_bits_uop_storeSetHit(v35_io_in_bits_uop_storeSetHit),
    .io_in_bits_uop_waitForRobIdx_flag(v35_io_in_bits_uop_waitForRobIdx_flag),
    .io_in_bits_uop_waitForRobIdx_value(v35_io_in_bits_uop_waitForRobIdx_value),
    .io_in_bits_uop_loadWaitBit(v35_io_in_bits_uop_loadWaitBit),
    .io_in_bits_uop_loadWaitStrict(v35_io_in_bits_uop_loadWaitStrict),
    .io_in_bits_uop_ssid(v35_io_in_bits_uop_ssid),
    .io_in_bits_uop_lqIdx_flag(v35_io_in_bits_uop_lqIdx_flag),
    .io_in_bits_uop_lqIdx_value(v35_io_in_bits_uop_lqIdx_value),
    .io_in_bits_uop_sqIdx_flag(v35_io_in_bits_uop_sqIdx_flag),
    .io_in_bits_uop_sqIdx_value(v35_io_in_bits_uop_sqIdx_value),
    .io_in_bits_uop_singleStep(v35_io_in_bits_uop_singleStep),
    .io_in_bits_uop_replayInst(v35_io_in_bits_uop_replayInst),
    .io_in_bits_uop_debug_fuType(v35_io_in_bits_uop_debug_fuType),
    .io_in_bits_uop_debug_sim_trig(v35_io_in_bits_uop_debug_sim_trig),
    .io_in_bits_uop_numLsElem(v35_io_in_bits_uop_numLsElem),
    .io_in_bits_mBIndex(v35_io_in_bits_mBIndex),
    .io_in_bits_elemIdx(v35_io_in_bits_elemIdx),
    .io_in_bits_elemIdxInsideVd(v35_io_in_bits_elemIdxInsideVd),
    .io_in_bits_splitIndex(v35_io_in_bits_splitIndex),
    .io_out_ready(v35_io_out_ready),
    .io_rightOutFire(v35_io_rightOutFire),
    .io_isFlush(v35_io_isFlush),
    .io_in_ready(i_v35_io_in_ready),
    .io_out_valid(i_v35_io_out_valid),
    .io_out_bits_vaddr(i_v35_io_out_bits_vaddr),
    .io_out_bits_basevaddr(i_v35_io_out_bits_basevaddr),
    .io_out_bits_mask(i_v35_io_out_bits_mask),
    .io_out_bits_reg_offset(i_v35_io_out_bits_reg_offset),
    .io_out_bits_alignedType(i_v35_io_out_bits_alignedType),
    .io_out_bits_vecActive(i_v35_io_out_bits_vecActive),
    .io_out_bits_vecIsFirstActiveElement(i_v35_io_out_bits_vecIsFirstActiveElement),
    .io_out_bits_uop_instr(i_v35_io_out_bits_uop_instr),
    .io_out_bits_uop_pc(i_v35_io_out_bits_uop_pc),
    .io_out_bits_uop_foldpc(i_v35_io_out_bits_uop_foldpc),
    .io_out_bits_uop_exceptionVec_4(i_v35_io_out_bits_uop_exceptionVec_4),
    .io_out_bits_uop_exceptionVec_5(i_v35_io_out_bits_uop_exceptionVec_5),
    .io_out_bits_uop_exceptionVec_6(i_v35_io_out_bits_uop_exceptionVec_6),
    .io_out_bits_uop_exceptionVec_7(i_v35_io_out_bits_uop_exceptionVec_7),
    .io_out_bits_uop_exceptionVec_13(i_v35_io_out_bits_uop_exceptionVec_13),
    .io_out_bits_uop_exceptionVec_15(i_v35_io_out_bits_uop_exceptionVec_15),
    .io_out_bits_uop_exceptionVec_19(i_v35_io_out_bits_uop_exceptionVec_19),
    .io_out_bits_uop_exceptionVec_21(i_v35_io_out_bits_uop_exceptionVec_21),
    .io_out_bits_uop_exceptionVec_23(i_v35_io_out_bits_uop_exceptionVec_23),
    .io_out_bits_uop_isFetchMalAddr(i_v35_io_out_bits_uop_isFetchMalAddr),
    .io_out_bits_uop_hasException(i_v35_io_out_bits_uop_hasException),
    .io_out_bits_uop_trigger(i_v35_io_out_bits_uop_trigger),
    .io_out_bits_uop_preDecodeInfo_valid(i_v35_io_out_bits_uop_preDecodeInfo_valid),
    .io_out_bits_uop_preDecodeInfo_isRVC(i_v35_io_out_bits_uop_preDecodeInfo_isRVC),
    .io_out_bits_uop_preDecodeInfo_brType(i_v35_io_out_bits_uop_preDecodeInfo_brType),
    .io_out_bits_uop_preDecodeInfo_isCall(i_v35_io_out_bits_uop_preDecodeInfo_isCall),
    .io_out_bits_uop_preDecodeInfo_isRet(i_v35_io_out_bits_uop_preDecodeInfo_isRet),
    .io_out_bits_uop_pred_taken(i_v35_io_out_bits_uop_pred_taken),
    .io_out_bits_uop_crossPageIPFFix(i_v35_io_out_bits_uop_crossPageIPFFix),
    .io_out_bits_uop_ftqPtr_flag(i_v35_io_out_bits_uop_ftqPtr_flag),
    .io_out_bits_uop_ftqPtr_value(i_v35_io_out_bits_uop_ftqPtr_value),
    .io_out_bits_uop_ftqOffset(i_v35_io_out_bits_uop_ftqOffset),
    .io_out_bits_uop_satpFlushFirstFetchFault(i_v35_io_out_bits_uop_satpFlushFirstFetchFault),
    .io_out_bits_uop_srcType_0(i_v35_io_out_bits_uop_srcType_0),
    .io_out_bits_uop_srcType_1(i_v35_io_out_bits_uop_srcType_1),
    .io_out_bits_uop_srcType_2(i_v35_io_out_bits_uop_srcType_2),
    .io_out_bits_uop_srcType_3(i_v35_io_out_bits_uop_srcType_3),
    .io_out_bits_uop_srcType_4(i_v35_io_out_bits_uop_srcType_4),
    .io_out_bits_uop_ldest(i_v35_io_out_bits_uop_ldest),
    .io_out_bits_uop_fuType(i_v35_io_out_bits_uop_fuType),
    .io_out_bits_uop_fuOpType(i_v35_io_out_bits_uop_fuOpType),
    .io_out_bits_uop_rfWen(i_v35_io_out_bits_uop_rfWen),
    .io_out_bits_uop_fpWen(i_v35_io_out_bits_uop_fpWen),
    .io_out_bits_uop_vecWen(i_v35_io_out_bits_uop_vecWen),
    .io_out_bits_uop_v0Wen(i_v35_io_out_bits_uop_v0Wen),
    .io_out_bits_uop_vlWen(i_v35_io_out_bits_uop_vlWen),
    .io_out_bits_uop_isXSTrap(i_v35_io_out_bits_uop_isXSTrap),
    .io_out_bits_uop_waitForward(i_v35_io_out_bits_uop_waitForward),
    .io_out_bits_uop_blockBackward(i_v35_io_out_bits_uop_blockBackward),
    .io_out_bits_uop_canRobCompress(i_v35_io_out_bits_uop_canRobCompress),
    .io_out_bits_uop_selImm(i_v35_io_out_bits_uop_selImm),
    .io_out_bits_uop_fpu_typeTagOut(i_v35_io_out_bits_uop_fpu_typeTagOut),
    .io_out_bits_uop_fpu_wflags(i_v35_io_out_bits_uop_fpu_wflags),
    .io_out_bits_uop_fpu_typ(i_v35_io_out_bits_uop_fpu_typ),
    .io_out_bits_uop_fpu_fmt(i_v35_io_out_bits_uop_fpu_fmt),
    .io_out_bits_uop_fpu_rm(i_v35_io_out_bits_uop_fpu_rm),
    .io_out_bits_uop_vpu_vill(i_v35_io_out_bits_uop_vpu_vill),
    .io_out_bits_uop_vpu_vma(i_v35_io_out_bits_uop_vpu_vma),
    .io_out_bits_uop_vpu_vta(i_v35_io_out_bits_uop_vpu_vta),
    .io_out_bits_uop_vpu_vsew(i_v35_io_out_bits_uop_vpu_vsew),
    .io_out_bits_uop_vpu_vlmul(i_v35_io_out_bits_uop_vpu_vlmul),
    .io_out_bits_uop_vpu_specVill(i_v35_io_out_bits_uop_vpu_specVill),
    .io_out_bits_uop_vpu_specVma(i_v35_io_out_bits_uop_vpu_specVma),
    .io_out_bits_uop_vpu_specVta(i_v35_io_out_bits_uop_vpu_specVta),
    .io_out_bits_uop_vpu_specVsew(i_v35_io_out_bits_uop_vpu_specVsew),
    .io_out_bits_uop_vpu_specVlmul(i_v35_io_out_bits_uop_vpu_specVlmul),
    .io_out_bits_uop_vpu_vm(i_v35_io_out_bits_uop_vpu_vm),
    .io_out_bits_uop_vpu_vstart(i_v35_io_out_bits_uop_vpu_vstart),
    .io_out_bits_uop_vpu_frm(i_v35_io_out_bits_uop_vpu_frm),
    .io_out_bits_uop_vpu_fpu_isFpToVecInst(i_v35_io_out_bits_uop_vpu_fpu_isFpToVecInst),
    .io_out_bits_uop_vpu_fpu_isFP32Instr(i_v35_io_out_bits_uop_vpu_fpu_isFP32Instr),
    .io_out_bits_uop_vpu_fpu_isFP64Instr(i_v35_io_out_bits_uop_vpu_fpu_isFP64Instr),
    .io_out_bits_uop_vpu_fpu_isReduction(i_v35_io_out_bits_uop_vpu_fpu_isReduction),
    .io_out_bits_uop_vpu_fpu_isFoldTo1_2(i_v35_io_out_bits_uop_vpu_fpu_isFoldTo1_2),
    .io_out_bits_uop_vpu_fpu_isFoldTo1_4(i_v35_io_out_bits_uop_vpu_fpu_isFoldTo1_4),
    .io_out_bits_uop_vpu_fpu_isFoldTo1_8(i_v35_io_out_bits_uop_vpu_fpu_isFoldTo1_8),
    .io_out_bits_uop_vpu_vxrm(i_v35_io_out_bits_uop_vpu_vxrm),
    .io_out_bits_uop_vpu_vuopIdx(i_v35_io_out_bits_uop_vpu_vuopIdx),
    .io_out_bits_uop_vpu_lastUop(i_v35_io_out_bits_uop_vpu_lastUop),
    .io_out_bits_uop_vpu_vmask(i_v35_io_out_bits_uop_vpu_vmask),
    .io_out_bits_uop_vpu_vl(i_v35_io_out_bits_uop_vpu_vl),
    .io_out_bits_uop_vpu_nf(i_v35_io_out_bits_uop_vpu_nf),
    .io_out_bits_uop_vpu_veew(i_v35_io_out_bits_uop_vpu_veew),
    .io_out_bits_uop_vpu_isReverse(i_v35_io_out_bits_uop_vpu_isReverse),
    .io_out_bits_uop_vpu_isExt(i_v35_io_out_bits_uop_vpu_isExt),
    .io_out_bits_uop_vpu_isNarrow(i_v35_io_out_bits_uop_vpu_isNarrow),
    .io_out_bits_uop_vpu_isDstMask(i_v35_io_out_bits_uop_vpu_isDstMask),
    .io_out_bits_uop_vpu_isOpMask(i_v35_io_out_bits_uop_vpu_isOpMask),
    .io_out_bits_uop_vpu_isMove(i_v35_io_out_bits_uop_vpu_isMove),
    .io_out_bits_uop_vpu_isDependOldVd(i_v35_io_out_bits_uop_vpu_isDependOldVd),
    .io_out_bits_uop_vpu_isWritePartVd(i_v35_io_out_bits_uop_vpu_isWritePartVd),
    .io_out_bits_uop_vpu_isVleff(i_v35_io_out_bits_uop_vpu_isVleff),
    .io_out_bits_uop_vlsInstr(i_v35_io_out_bits_uop_vlsInstr),
    .io_out_bits_uop_wfflags(i_v35_io_out_bits_uop_wfflags),
    .io_out_bits_uop_isMove(i_v35_io_out_bits_uop_isMove),
    .io_out_bits_uop_isDropAmocasSta(i_v35_io_out_bits_uop_isDropAmocasSta),
    .io_out_bits_uop_uopIdx(i_v35_io_out_bits_uop_uopIdx),
    .io_out_bits_uop_isVset(i_v35_io_out_bits_uop_isVset),
    .io_out_bits_uop_firstUop(i_v35_io_out_bits_uop_firstUop),
    .io_out_bits_uop_lastUop(i_v35_io_out_bits_uop_lastUop),
    .io_out_bits_uop_numUops(i_v35_io_out_bits_uop_numUops),
    .io_out_bits_uop_numWB(i_v35_io_out_bits_uop_numWB),
    .io_out_bits_uop_commitType(i_v35_io_out_bits_uop_commitType),
    .io_out_bits_uop_srcState_0(i_v35_io_out_bits_uop_srcState_0),
    .io_out_bits_uop_srcState_1(i_v35_io_out_bits_uop_srcState_1),
    .io_out_bits_uop_srcState_2(i_v35_io_out_bits_uop_srcState_2),
    .io_out_bits_uop_srcState_3(i_v35_io_out_bits_uop_srcState_3),
    .io_out_bits_uop_srcState_4(i_v35_io_out_bits_uop_srcState_4),
    .io_out_bits_uop_srcLoadDependency_0_0(i_v35_io_out_bits_uop_srcLoadDependency_0_0),
    .io_out_bits_uop_srcLoadDependency_0_1(i_v35_io_out_bits_uop_srcLoadDependency_0_1),
    .io_out_bits_uop_srcLoadDependency_0_2(i_v35_io_out_bits_uop_srcLoadDependency_0_2),
    .io_out_bits_uop_srcLoadDependency_1_0(i_v35_io_out_bits_uop_srcLoadDependency_1_0),
    .io_out_bits_uop_srcLoadDependency_1_1(i_v35_io_out_bits_uop_srcLoadDependency_1_1),
    .io_out_bits_uop_srcLoadDependency_1_2(i_v35_io_out_bits_uop_srcLoadDependency_1_2),
    .io_out_bits_uop_srcLoadDependency_2_0(i_v35_io_out_bits_uop_srcLoadDependency_2_0),
    .io_out_bits_uop_srcLoadDependency_2_1(i_v35_io_out_bits_uop_srcLoadDependency_2_1),
    .io_out_bits_uop_srcLoadDependency_2_2(i_v35_io_out_bits_uop_srcLoadDependency_2_2),
    .io_out_bits_uop_srcLoadDependency_3_0(i_v35_io_out_bits_uop_srcLoadDependency_3_0),
    .io_out_bits_uop_srcLoadDependency_3_1(i_v35_io_out_bits_uop_srcLoadDependency_3_1),
    .io_out_bits_uop_srcLoadDependency_3_2(i_v35_io_out_bits_uop_srcLoadDependency_3_2),
    .io_out_bits_uop_srcLoadDependency_4_0(i_v35_io_out_bits_uop_srcLoadDependency_4_0),
    .io_out_bits_uop_srcLoadDependency_4_1(i_v35_io_out_bits_uop_srcLoadDependency_4_1),
    .io_out_bits_uop_srcLoadDependency_4_2(i_v35_io_out_bits_uop_srcLoadDependency_4_2),
    .io_out_bits_uop_psrc_0(i_v35_io_out_bits_uop_psrc_0),
    .io_out_bits_uop_psrc_1(i_v35_io_out_bits_uop_psrc_1),
    .io_out_bits_uop_psrc_2(i_v35_io_out_bits_uop_psrc_2),
    .io_out_bits_uop_psrc_3(i_v35_io_out_bits_uop_psrc_3),
    .io_out_bits_uop_psrc_4(i_v35_io_out_bits_uop_psrc_4),
    .io_out_bits_uop_pdest(i_v35_io_out_bits_uop_pdest),
    .io_out_bits_uop_useRegCache_0(i_v35_io_out_bits_uop_useRegCache_0),
    .io_out_bits_uop_useRegCache_1(i_v35_io_out_bits_uop_useRegCache_1),
    .io_out_bits_uop_regCacheIdx_0(i_v35_io_out_bits_uop_regCacheIdx_0),
    .io_out_bits_uop_regCacheIdx_1(i_v35_io_out_bits_uop_regCacheIdx_1),
    .io_out_bits_uop_robIdx_flag(i_v35_io_out_bits_uop_robIdx_flag),
    .io_out_bits_uop_robIdx_value(i_v35_io_out_bits_uop_robIdx_value),
    .io_out_bits_uop_instrSize(i_v35_io_out_bits_uop_instrSize),
    .io_out_bits_uop_dirtyFs(i_v35_io_out_bits_uop_dirtyFs),
    .io_out_bits_uop_dirtyVs(i_v35_io_out_bits_uop_dirtyVs),
    .io_out_bits_uop_traceBlockInPipe_itype(i_v35_io_out_bits_uop_traceBlockInPipe_itype),
    .io_out_bits_uop_traceBlockInPipe_iretire(i_v35_io_out_bits_uop_traceBlockInPipe_iretire),
    .io_out_bits_uop_traceBlockInPipe_ilastsize(i_v35_io_out_bits_uop_traceBlockInPipe_ilastsize),
    .io_out_bits_uop_eliminatedMove(i_v35_io_out_bits_uop_eliminatedMove),
    .io_out_bits_uop_snapshot(i_v35_io_out_bits_uop_snapshot),
    .io_out_bits_uop_debugInfo_eliminatedMove(i_v35_io_out_bits_uop_debugInfo_eliminatedMove),
    .io_out_bits_uop_debugInfo_renameTime(i_v35_io_out_bits_uop_debugInfo_renameTime),
    .io_out_bits_uop_debugInfo_dispatchTime(i_v35_io_out_bits_uop_debugInfo_dispatchTime),
    .io_out_bits_uop_debugInfo_enqRsTime(i_v35_io_out_bits_uop_debugInfo_enqRsTime),
    .io_out_bits_uop_debugInfo_selectTime(i_v35_io_out_bits_uop_debugInfo_selectTime),
    .io_out_bits_uop_debugInfo_issueTime(i_v35_io_out_bits_uop_debugInfo_issueTime),
    .io_out_bits_uop_debugInfo_writebackTime(i_v35_io_out_bits_uop_debugInfo_writebackTime),
    .io_out_bits_uop_debugInfo_runahead_checkpoint_id(i_v35_io_out_bits_uop_debugInfo_runahead_checkpoint_id),
    .io_out_bits_uop_debugInfo_tlbFirstReqTime(i_v35_io_out_bits_uop_debugInfo_tlbFirstReqTime),
    .io_out_bits_uop_debugInfo_tlbRespTime(i_v35_io_out_bits_uop_debugInfo_tlbRespTime),
    .io_out_bits_uop_debug_seqNum_seqNum(i_v35_io_out_bits_uop_debug_seqNum_seqNum),
    .io_out_bits_uop_debug_seqNum_uopIdx(i_v35_io_out_bits_uop_debug_seqNum_uopIdx),
    .io_out_bits_uop_storeSetHit(i_v35_io_out_bits_uop_storeSetHit),
    .io_out_bits_uop_waitForRobIdx_flag(i_v35_io_out_bits_uop_waitForRobIdx_flag),
    .io_out_bits_uop_waitForRobIdx_value(i_v35_io_out_bits_uop_waitForRobIdx_value),
    .io_out_bits_uop_loadWaitBit(i_v35_io_out_bits_uop_loadWaitBit),
    .io_out_bits_uop_loadWaitStrict(i_v35_io_out_bits_uop_loadWaitStrict),
    .io_out_bits_uop_ssid(i_v35_io_out_bits_uop_ssid),
    .io_out_bits_uop_lqIdx_flag(i_v35_io_out_bits_uop_lqIdx_flag),
    .io_out_bits_uop_lqIdx_value(i_v35_io_out_bits_uop_lqIdx_value),
    .io_out_bits_uop_sqIdx_flag(i_v35_io_out_bits_uop_sqIdx_flag),
    .io_out_bits_uop_sqIdx_value(i_v35_io_out_bits_uop_sqIdx_value),
    .io_out_bits_uop_singleStep(i_v35_io_out_bits_uop_singleStep),
    .io_out_bits_uop_replayInst(i_v35_io_out_bits_uop_replayInst),
    .io_out_bits_uop_debug_fuType(i_v35_io_out_bits_uop_debug_fuType),
    .io_out_bits_uop_debug_sim_trig(i_v35_io_out_bits_uop_debug_sim_trig),
    .io_out_bits_uop_numLsElem(i_v35_io_out_bits_uop_numLsElem),
    .io_out_bits_mBIndex(i_v35_io_out_bits_mBIndex),
    .io_out_bits_elemIdx(i_v35_io_out_bits_elemIdx),
    .io_out_bits_elemIdxInsideVd(i_v35_io_out_bits_elemIdxInsideVd),
    .io_out_bits_splitIndex(i_v35_io_out_bits_splitIndex)
  );

  task automatic drive_all();
    v29_io_in_valid     = ($urandom % 100) < 75;
    v29_io_out_ready    = ($urandom % 100) < 55;
    v29_io_rightOutFire = ($urandom % 100) < 50;
    v29_io_isFlush      = ($urandom % 512) == 0;
    v29_io_in_bits_uop_exceptionVec_3 = 1'($urandom);
    v29_io_in_bits_uop_exceptionVec_4 = 1'($urandom);
    v29_io_in_bits_uop_exceptionVec_5 = 1'($urandom);
    v29_io_in_bits_uop_exceptionVec_6 = 1'($urandom);
    v29_io_in_bits_uop_exceptionVec_7 = 1'($urandom);
    v29_io_in_bits_uop_exceptionVec_13 = 1'($urandom);
    v29_io_in_bits_uop_exceptionVec_15 = 1'($urandom);
    v29_io_in_bits_uop_exceptionVec_19 = 1'($urandom);
    v29_io_in_bits_uop_exceptionVec_21 = 1'($urandom);
    v29_io_in_bits_uop_exceptionVec_23 = 1'($urandom);
    v29_io_in_bits_uop_trigger = 4'($urandom);
    v29_io_in_bits_uop_fuOpType = 9'($urandom);
    v29_io_in_bits_uop_vecWen = 1'($urandom);
    v29_io_in_bits_uop_v0Wen = 1'($urandom);
    v29_io_in_bits_uop_vlWen = 1'($urandom);
    v29_io_in_bits_uop_flushPipe = 1'($urandom);
    v29_io_in_bits_uop_vpu_vill = 1'($urandom);
    v29_io_in_bits_uop_vpu_vma = 1'($urandom);
    v29_io_in_bits_uop_vpu_vta = 1'($urandom);
    v29_io_in_bits_uop_vpu_vsew = 2'($urandom);
    v29_io_in_bits_uop_vpu_vlmul = 3'($urandom);
    v29_io_in_bits_uop_vpu_specVill = 1'($urandom);
    v29_io_in_bits_uop_vpu_specVma = 1'($urandom);
    v29_io_in_bits_uop_vpu_specVta = 1'($urandom);
    v29_io_in_bits_uop_vpu_specVsew = 2'($urandom);
    v29_io_in_bits_uop_vpu_specVlmul = 3'($urandom);
    v29_io_in_bits_uop_vpu_vm = 1'($urandom);
    v29_io_in_bits_uop_vpu_vstart = 8'($urandom);
    v29_io_in_bits_uop_vpu_frm = 3'($urandom);
    v29_io_in_bits_uop_vpu_fpu_isFpToVecInst = 1'($urandom);
    v29_io_in_bits_uop_vpu_fpu_isFP32Instr = 1'($urandom);
    v29_io_in_bits_uop_vpu_fpu_isFP64Instr = 1'($urandom);
    v29_io_in_bits_uop_vpu_fpu_isReduction = 1'($urandom);
    v29_io_in_bits_uop_vpu_fpu_isFoldTo1_2 = 1'($urandom);
    v29_io_in_bits_uop_vpu_fpu_isFoldTo1_4 = 1'($urandom);
    v29_io_in_bits_uop_vpu_fpu_isFoldTo1_8 = 1'($urandom);
    v29_io_in_bits_uop_vpu_vxrm = 2'($urandom);
    v29_io_in_bits_uop_vpu_vuopIdx = 7'($urandom);
    v29_io_in_bits_uop_vpu_lastUop = 1'($urandom);
    v29_io_in_bits_uop_vpu_vmask = 128'({$urandom, $urandom, $urandom, $urandom});
    v29_io_in_bits_uop_vpu_vl = 8'($urandom);
    v29_io_in_bits_uop_vpu_nf = 3'($urandom);
    v29_io_in_bits_uop_vpu_veew = 2'($urandom);
    v29_io_in_bits_uop_vpu_isReverse = 1'($urandom);
    v29_io_in_bits_uop_vpu_isExt = 1'($urandom);
    v29_io_in_bits_uop_vpu_isNarrow = 1'($urandom);
    v29_io_in_bits_uop_vpu_isDstMask = 1'($urandom);
    v29_io_in_bits_uop_vpu_isOpMask = 1'($urandom);
    v29_io_in_bits_uop_vpu_isMove = 1'($urandom);
    v29_io_in_bits_uop_vpu_isDependOldVd = 1'($urandom);
    v29_io_in_bits_uop_vpu_isWritePartVd = 1'($urandom);
    v29_io_in_bits_uop_vpu_isVleff = 1'($urandom);
    v29_io_in_bits_uop_psrc_2 = 8'($urandom);
    v29_io_in_bits_uop_pdest = 8'($urandom);
    v29_io_in_bits_uop_robIdx_flag = 1'($urandom);
    v29_io_in_bits_uop_robIdx_value = 8'($urandom);
    v29_io_in_bits_uop_debugInfo_eliminatedMove = 1'($urandom);
    v29_io_in_bits_uop_debugInfo_renameTime = 64'({$urandom, $urandom});
    v29_io_in_bits_uop_debugInfo_dispatchTime = 64'({$urandom, $urandom});
    v29_io_in_bits_uop_debugInfo_enqRsTime = 64'({$urandom, $urandom});
    v29_io_in_bits_uop_debugInfo_selectTime = 64'({$urandom, $urandom});
    v29_io_in_bits_uop_debugInfo_issueTime = 64'({$urandom, $urandom});
    v29_io_in_bits_uop_debugInfo_writebackTime = 64'({$urandom, $urandom});
    v29_io_in_bits_uop_debugInfo_runahead_checkpoint_id = 64'({$urandom, $urandom});
    v29_io_in_bits_uop_debugInfo_tlbFirstReqTime = 64'({$urandom, $urandom});
    v29_io_in_bits_uop_debugInfo_tlbRespTime = 64'({$urandom, $urandom});
    v29_io_in_bits_uop_debug_seqNum_seqNum = 56'({$urandom, $urandom});
    v29_io_in_bits_uop_debug_seqNum_uopIdx = 8'($urandom);
    v29_io_in_bits_uop_replayInst = 1'($urandom);
    v29_io_in_bits_data = 128'({$urandom, $urandom, $urandom, $urandom});
    v29_io_in_bits_vdIdx = 3'($urandom);
    v29_io_in_bits_vdIdxInField = 3'($urandom);
    v34_io_in_valid     = ($urandom % 100) < 75;
    v34_io_out_ready    = ($urandom % 100) < 55;
    v34_io_rightOutFire = ($urandom % 100) < 50;
    v34_io_in_bits_uop_exceptionVec_0 = 1'($urandom);
    v34_io_in_bits_uop_exceptionVec_1 = 1'($urandom);
    v34_io_in_bits_uop_exceptionVec_2 = 1'($urandom);
    v34_io_in_bits_uop_exceptionVec_3 = 1'($urandom);
    v34_io_in_bits_uop_exceptionVec_4 = 1'($urandom);
    v34_io_in_bits_uop_exceptionVec_5 = 1'($urandom);
    v34_io_in_bits_uop_exceptionVec_6 = 1'($urandom);
    v34_io_in_bits_uop_exceptionVec_7 = 1'($urandom);
    v34_io_in_bits_uop_exceptionVec_8 = 1'($urandom);
    v34_io_in_bits_uop_exceptionVec_9 = 1'($urandom);
    v34_io_in_bits_uop_exceptionVec_10 = 1'($urandom);
    v34_io_in_bits_uop_exceptionVec_11 = 1'($urandom);
    v34_io_in_bits_uop_exceptionVec_12 = 1'($urandom);
    v34_io_in_bits_uop_exceptionVec_13 = 1'($urandom);
    v34_io_in_bits_uop_exceptionVec_14 = 1'($urandom);
    v34_io_in_bits_uop_exceptionVec_15 = 1'($urandom);
    v34_io_in_bits_uop_exceptionVec_16 = 1'($urandom);
    v34_io_in_bits_uop_exceptionVec_17 = 1'($urandom);
    v34_io_in_bits_uop_exceptionVec_18 = 1'($urandom);
    v34_io_in_bits_uop_exceptionVec_19 = 1'($urandom);
    v34_io_in_bits_uop_exceptionVec_20 = 1'($urandom);
    v34_io_in_bits_uop_exceptionVec_21 = 1'($urandom);
    v34_io_in_bits_uop_exceptionVec_22 = 1'($urandom);
    v34_io_in_bits_uop_exceptionVec_23 = 1'($urandom);
    v34_io_in_bits_uop_trigger = 4'($urandom);
    v34_io_in_bits_uop_rfWen = 1'($urandom);
    v34_io_in_bits_uop_flushPipe = 1'($urandom);
    v34_io_in_bits_uop_pdest = 8'($urandom);
    v34_io_in_bits_uop_robIdx_flag = 1'($urandom);
    v34_io_in_bits_uop_robIdx_value = 8'($urandom);
    v34_io_in_bits_uop_debugInfo_eliminatedMove = 1'($urandom);
    v34_io_in_bits_uop_debugInfo_renameTime = 64'({$urandom, $urandom});
    v34_io_in_bits_uop_debugInfo_dispatchTime = 64'({$urandom, $urandom});
    v34_io_in_bits_uop_debugInfo_enqRsTime = 64'({$urandom, $urandom});
    v34_io_in_bits_uop_debugInfo_selectTime = 64'({$urandom, $urandom});
    v34_io_in_bits_uop_debugInfo_issueTime = 64'({$urandom, $urandom});
    v34_io_in_bits_uop_debugInfo_writebackTime = 64'({$urandom, $urandom});
    v34_io_in_bits_uop_debugInfo_runahead_checkpoint_id = 64'({$urandom, $urandom});
    v34_io_in_bits_uop_debugInfo_tlbFirstReqTime = 64'({$urandom, $urandom});
    v34_io_in_bits_uop_debugInfo_tlbRespTime = 64'({$urandom, $urandom});
    v34_io_in_bits_uop_debug_seqNum_seqNum = 56'({$urandom, $urandom});
    v34_io_in_bits_uop_debug_seqNum_uopIdx = 8'($urandom);
    v34_io_in_bits_uop_sqIdx_flag = 1'($urandom);
    v34_io_in_bits_uop_sqIdx_value = 6'($urandom);
    v34_io_in_bits_data = 64'({$urandom, $urandom});
    v34_io_in_bits_debug_isMMIO = 1'($urandom);
    v35_io_in_valid     = ($urandom % 100) < 75;
    v35_io_out_ready    = ($urandom % 100) < 55;
    v35_io_rightOutFire = ($urandom % 100) < 50;
    v35_io_isFlush      = ($urandom % 512) == 0;
    v35_io_in_bits_vaddr = 64'({$urandom, $urandom});
    v35_io_in_bits_basevaddr = 50'({$urandom, $urandom});
    v35_io_in_bits_mask = 16'($urandom);
    v35_io_in_bits_reg_offset = 4'($urandom);
    v35_io_in_bits_alignedType = 3'($urandom);
    v35_io_in_bits_vecActive = 1'($urandom);
    v35_io_in_bits_vecIsFirstActiveElement = 1'($urandom);
    v35_io_in_bits_uop_instr = 32'($urandom);
    v35_io_in_bits_uop_pc = 50'({$urandom, $urandom});
    v35_io_in_bits_uop_foldpc = 10'($urandom);
    v35_io_in_bits_uop_exceptionVec_4 = 1'($urandom);
    v35_io_in_bits_uop_exceptionVec_5 = 1'($urandom);
    v35_io_in_bits_uop_exceptionVec_6 = 1'($urandom);
    v35_io_in_bits_uop_exceptionVec_7 = 1'($urandom);
    v35_io_in_bits_uop_exceptionVec_13 = 1'($urandom);
    v35_io_in_bits_uop_exceptionVec_15 = 1'($urandom);
    v35_io_in_bits_uop_exceptionVec_19 = 1'($urandom);
    v35_io_in_bits_uop_exceptionVec_21 = 1'($urandom);
    v35_io_in_bits_uop_exceptionVec_23 = 1'($urandom);
    v35_io_in_bits_uop_isFetchMalAddr = 1'($urandom);
    v35_io_in_bits_uop_hasException = 1'($urandom);
    v35_io_in_bits_uop_trigger = 4'($urandom);
    v35_io_in_bits_uop_preDecodeInfo_valid = 1'($urandom);
    v35_io_in_bits_uop_preDecodeInfo_isRVC = 1'($urandom);
    v35_io_in_bits_uop_preDecodeInfo_brType = 2'($urandom);
    v35_io_in_bits_uop_preDecodeInfo_isCall = 1'($urandom);
    v35_io_in_bits_uop_preDecodeInfo_isRet = 1'($urandom);
    v35_io_in_bits_uop_pred_taken = 1'($urandom);
    v35_io_in_bits_uop_crossPageIPFFix = 1'($urandom);
    v35_io_in_bits_uop_ftqPtr_flag = 1'($urandom);
    v35_io_in_bits_uop_ftqPtr_value = 6'($urandom);
    v35_io_in_bits_uop_ftqOffset = 4'($urandom);
    v35_io_in_bits_uop_satpFlushFirstFetchFault = 1'($urandom);
    v35_io_in_bits_uop_srcType_0 = 4'($urandom);
    v35_io_in_bits_uop_srcType_1 = 4'($urandom);
    v35_io_in_bits_uop_srcType_2 = 4'($urandom);
    v35_io_in_bits_uop_srcType_3 = 4'($urandom);
    v35_io_in_bits_uop_srcType_4 = 4'($urandom);
    v35_io_in_bits_uop_ldest = 6'($urandom);
    v35_io_in_bits_uop_fuType = 35'({$urandom, $urandom});
    v35_io_in_bits_uop_fuOpType = 9'($urandom);
    v35_io_in_bits_uop_rfWen = 1'($urandom);
    v35_io_in_bits_uop_fpWen = 1'($urandom);
    v35_io_in_bits_uop_vecWen = 1'($urandom);
    v35_io_in_bits_uop_v0Wen = 1'($urandom);
    v35_io_in_bits_uop_vlWen = 1'($urandom);
    v35_io_in_bits_uop_isXSTrap = 1'($urandom);
    v35_io_in_bits_uop_waitForward = 1'($urandom);
    v35_io_in_bits_uop_blockBackward = 1'($urandom);
    v35_io_in_bits_uop_canRobCompress = 1'($urandom);
    v35_io_in_bits_uop_selImm = 4'($urandom);
    v35_io_in_bits_uop_fpu_typeTagOut = 2'($urandom);
    v35_io_in_bits_uop_fpu_wflags = 1'($urandom);
    v35_io_in_bits_uop_fpu_typ = 2'($urandom);
    v35_io_in_bits_uop_fpu_fmt = 2'($urandom);
    v35_io_in_bits_uop_fpu_rm = 3'($urandom);
    v35_io_in_bits_uop_vpu_vill = 1'($urandom);
    v35_io_in_bits_uop_vpu_vma = 1'($urandom);
    v35_io_in_bits_uop_vpu_vta = 1'($urandom);
    v35_io_in_bits_uop_vpu_vsew = 2'($urandom);
    v35_io_in_bits_uop_vpu_vlmul = 3'($urandom);
    v35_io_in_bits_uop_vpu_specVill = 1'($urandom);
    v35_io_in_bits_uop_vpu_specVma = 1'($urandom);
    v35_io_in_bits_uop_vpu_specVta = 1'($urandom);
    v35_io_in_bits_uop_vpu_specVsew = 2'($urandom);
    v35_io_in_bits_uop_vpu_specVlmul = 3'($urandom);
    v35_io_in_bits_uop_vpu_vm = 1'($urandom);
    v35_io_in_bits_uop_vpu_vstart = 8'($urandom);
    v35_io_in_bits_uop_vpu_frm = 3'($urandom);
    v35_io_in_bits_uop_vpu_fpu_isFpToVecInst = 1'($urandom);
    v35_io_in_bits_uop_vpu_fpu_isFP32Instr = 1'($urandom);
    v35_io_in_bits_uop_vpu_fpu_isFP64Instr = 1'($urandom);
    v35_io_in_bits_uop_vpu_fpu_isReduction = 1'($urandom);
    v35_io_in_bits_uop_vpu_fpu_isFoldTo1_2 = 1'($urandom);
    v35_io_in_bits_uop_vpu_fpu_isFoldTo1_4 = 1'($urandom);
    v35_io_in_bits_uop_vpu_fpu_isFoldTo1_8 = 1'($urandom);
    v35_io_in_bits_uop_vpu_vxrm = 2'($urandom);
    v35_io_in_bits_uop_vpu_vuopIdx = 7'($urandom);
    v35_io_in_bits_uop_vpu_lastUop = 1'($urandom);
    v35_io_in_bits_uop_vpu_vmask = 128'({$urandom, $urandom, $urandom, $urandom});
    v35_io_in_bits_uop_vpu_vl = 8'($urandom);
    v35_io_in_bits_uop_vpu_nf = 3'($urandom);
    v35_io_in_bits_uop_vpu_veew = 2'($urandom);
    v35_io_in_bits_uop_vpu_isReverse = 1'($urandom);
    v35_io_in_bits_uop_vpu_isExt = 1'($urandom);
    v35_io_in_bits_uop_vpu_isNarrow = 1'($urandom);
    v35_io_in_bits_uop_vpu_isDstMask = 1'($urandom);
    v35_io_in_bits_uop_vpu_isOpMask = 1'($urandom);
    v35_io_in_bits_uop_vpu_isMove = 1'($urandom);
    v35_io_in_bits_uop_vpu_isDependOldVd = 1'($urandom);
    v35_io_in_bits_uop_vpu_isWritePartVd = 1'($urandom);
    v35_io_in_bits_uop_vpu_isVleff = 1'($urandom);
    v35_io_in_bits_uop_vlsInstr = 1'($urandom);
    v35_io_in_bits_uop_wfflags = 1'($urandom);
    v35_io_in_bits_uop_isMove = 1'($urandom);
    v35_io_in_bits_uop_isDropAmocasSta = 1'($urandom);
    v35_io_in_bits_uop_uopIdx = 7'($urandom);
    v35_io_in_bits_uop_isVset = 1'($urandom);
    v35_io_in_bits_uop_firstUop = 1'($urandom);
    v35_io_in_bits_uop_lastUop = 1'($urandom);
    v35_io_in_bits_uop_numUops = 7'($urandom);
    v35_io_in_bits_uop_numWB = 7'($urandom);
    v35_io_in_bits_uop_commitType = 3'($urandom);
    v35_io_in_bits_uop_srcState_0 = 1'($urandom);
    v35_io_in_bits_uop_srcState_1 = 1'($urandom);
    v35_io_in_bits_uop_srcState_2 = 1'($urandom);
    v35_io_in_bits_uop_srcState_3 = 1'($urandom);
    v35_io_in_bits_uop_srcState_4 = 1'($urandom);
    v35_io_in_bits_uop_srcLoadDependency_0_0 = 2'($urandom);
    v35_io_in_bits_uop_srcLoadDependency_0_1 = 2'($urandom);
    v35_io_in_bits_uop_srcLoadDependency_0_2 = 2'($urandom);
    v35_io_in_bits_uop_srcLoadDependency_1_0 = 2'($urandom);
    v35_io_in_bits_uop_srcLoadDependency_1_1 = 2'($urandom);
    v35_io_in_bits_uop_srcLoadDependency_1_2 = 2'($urandom);
    v35_io_in_bits_uop_srcLoadDependency_2_0 = 2'($urandom);
    v35_io_in_bits_uop_srcLoadDependency_2_1 = 2'($urandom);
    v35_io_in_bits_uop_srcLoadDependency_2_2 = 2'($urandom);
    v35_io_in_bits_uop_srcLoadDependency_3_0 = 2'($urandom);
    v35_io_in_bits_uop_srcLoadDependency_3_1 = 2'($urandom);
    v35_io_in_bits_uop_srcLoadDependency_3_2 = 2'($urandom);
    v35_io_in_bits_uop_srcLoadDependency_4_0 = 2'($urandom);
    v35_io_in_bits_uop_srcLoadDependency_4_1 = 2'($urandom);
    v35_io_in_bits_uop_srcLoadDependency_4_2 = 2'($urandom);
    v35_io_in_bits_uop_psrc_0 = 8'($urandom);
    v35_io_in_bits_uop_psrc_1 = 8'($urandom);
    v35_io_in_bits_uop_psrc_2 = 8'($urandom);
    v35_io_in_bits_uop_psrc_3 = 8'($urandom);
    v35_io_in_bits_uop_psrc_4 = 8'($urandom);
    v35_io_in_bits_uop_pdest = 8'($urandom);
    v35_io_in_bits_uop_useRegCache_0 = 1'($urandom);
    v35_io_in_bits_uop_useRegCache_1 = 1'($urandom);
    v35_io_in_bits_uop_regCacheIdx_0 = 5'($urandom);
    v35_io_in_bits_uop_regCacheIdx_1 = 5'($urandom);
    v35_io_in_bits_uop_robIdx_flag = 1'($urandom);
    v35_io_in_bits_uop_robIdx_value = 8'($urandom);
    v35_io_in_bits_uop_instrSize = 3'($urandom);
    v35_io_in_bits_uop_dirtyFs = 1'($urandom);
    v35_io_in_bits_uop_dirtyVs = 1'($urandom);
    v35_io_in_bits_uop_traceBlockInPipe_itype = 4'($urandom);
    v35_io_in_bits_uop_traceBlockInPipe_iretire = 4'($urandom);
    v35_io_in_bits_uop_traceBlockInPipe_ilastsize = 1'($urandom);
    v35_io_in_bits_uop_eliminatedMove = 1'($urandom);
    v35_io_in_bits_uop_snapshot = 1'($urandom);
    v35_io_in_bits_uop_debugInfo_eliminatedMove = 1'($urandom);
    v35_io_in_bits_uop_debugInfo_renameTime = 64'({$urandom, $urandom});
    v35_io_in_bits_uop_debugInfo_dispatchTime = 64'({$urandom, $urandom});
    v35_io_in_bits_uop_debugInfo_enqRsTime = 64'({$urandom, $urandom});
    v35_io_in_bits_uop_debugInfo_selectTime = 64'({$urandom, $urandom});
    v35_io_in_bits_uop_debugInfo_issueTime = 64'({$urandom, $urandom});
    v35_io_in_bits_uop_debugInfo_writebackTime = 64'({$urandom, $urandom});
    v35_io_in_bits_uop_debugInfo_runahead_checkpoint_id = 64'({$urandom, $urandom});
    v35_io_in_bits_uop_debugInfo_tlbFirstReqTime = 64'({$urandom, $urandom});
    v35_io_in_bits_uop_debugInfo_tlbRespTime = 64'({$urandom, $urandom});
    v35_io_in_bits_uop_debug_seqNum_seqNum = 56'({$urandom, $urandom});
    v35_io_in_bits_uop_debug_seqNum_uopIdx = 8'($urandom);
    v35_io_in_bits_uop_storeSetHit = 1'($urandom);
    v35_io_in_bits_uop_waitForRobIdx_flag = 1'($urandom);
    v35_io_in_bits_uop_waitForRobIdx_value = 8'($urandom);
    v35_io_in_bits_uop_loadWaitBit = 1'($urandom);
    v35_io_in_bits_uop_loadWaitStrict = 1'($urandom);
    v35_io_in_bits_uop_ssid = 5'($urandom);
    v35_io_in_bits_uop_lqIdx_flag = 1'($urandom);
    v35_io_in_bits_uop_lqIdx_value = 7'($urandom);
    v35_io_in_bits_uop_sqIdx_flag = 1'($urandom);
    v35_io_in_bits_uop_sqIdx_value = 6'($urandom);
    v35_io_in_bits_uop_singleStep = 1'($urandom);
    v35_io_in_bits_uop_replayInst = 1'($urandom);
    v35_io_in_bits_uop_debug_fuType = 35'({$urandom, $urandom});
    v35_io_in_bits_uop_debug_sim_trig = 1'($urandom);
    v35_io_in_bits_uop_numLsElem = 5'($urandom);
    v35_io_in_bits_mBIndex = 4'($urandom);
    v35_io_in_bits_elemIdx = 8'($urandom);
    v35_io_in_bits_elemIdxInsideVd = 8'($urandom);
    v35_io_in_bits_splitIndex = 5'($urandom);
  endtask

  task automatic check_all();
    `CHECK(v29,io_in_ready)
    `CHECK(v29,io_out_valid)
    `CHECK(v29,io_out_bits_uop_exceptionVec_3)
    `CHECK(v29,io_out_bits_uop_exceptionVec_4)
    `CHECK(v29,io_out_bits_uop_exceptionVec_5)
    `CHECK(v29,io_out_bits_uop_exceptionVec_6)
    `CHECK(v29,io_out_bits_uop_exceptionVec_7)
    `CHECK(v29,io_out_bits_uop_exceptionVec_13)
    `CHECK(v29,io_out_bits_uop_exceptionVec_15)
    `CHECK(v29,io_out_bits_uop_exceptionVec_19)
    `CHECK(v29,io_out_bits_uop_exceptionVec_21)
    `CHECK(v29,io_out_bits_uop_exceptionVec_23)
    `CHECK(v29,io_out_bits_uop_trigger)
    `CHECK(v29,io_out_bits_uop_fuOpType)
    `CHECK(v29,io_out_bits_uop_vecWen)
    `CHECK(v29,io_out_bits_uop_v0Wen)
    `CHECK(v29,io_out_bits_uop_vlWen)
    `CHECK(v29,io_out_bits_uop_flushPipe)
    `CHECK(v29,io_out_bits_uop_vpu_vill)
    `CHECK(v29,io_out_bits_uop_vpu_vma)
    `CHECK(v29,io_out_bits_uop_vpu_vta)
    `CHECK(v29,io_out_bits_uop_vpu_vsew)
    `CHECK(v29,io_out_bits_uop_vpu_vlmul)
    `CHECK(v29,io_out_bits_uop_vpu_specVill)
    `CHECK(v29,io_out_bits_uop_vpu_specVma)
    `CHECK(v29,io_out_bits_uop_vpu_specVta)
    `CHECK(v29,io_out_bits_uop_vpu_specVsew)
    `CHECK(v29,io_out_bits_uop_vpu_specVlmul)
    `CHECK(v29,io_out_bits_uop_vpu_vm)
    `CHECK(v29,io_out_bits_uop_vpu_vstart)
    `CHECK(v29,io_out_bits_uop_vpu_frm)
    `CHECK(v29,io_out_bits_uop_vpu_fpu_isFpToVecInst)
    `CHECK(v29,io_out_bits_uop_vpu_fpu_isFP32Instr)
    `CHECK(v29,io_out_bits_uop_vpu_fpu_isFP64Instr)
    `CHECK(v29,io_out_bits_uop_vpu_fpu_isReduction)
    `CHECK(v29,io_out_bits_uop_vpu_fpu_isFoldTo1_2)
    `CHECK(v29,io_out_bits_uop_vpu_fpu_isFoldTo1_4)
    `CHECK(v29,io_out_bits_uop_vpu_fpu_isFoldTo1_8)
    `CHECK(v29,io_out_bits_uop_vpu_vxrm)
    `CHECK(v29,io_out_bits_uop_vpu_vuopIdx)
    `CHECK(v29,io_out_bits_uop_vpu_lastUop)
    `CHECK(v29,io_out_bits_uop_vpu_vmask)
    `CHECK(v29,io_out_bits_uop_vpu_vl)
    `CHECK(v29,io_out_bits_uop_vpu_nf)
    `CHECK(v29,io_out_bits_uop_vpu_veew)
    `CHECK(v29,io_out_bits_uop_vpu_isReverse)
    `CHECK(v29,io_out_bits_uop_vpu_isExt)
    `CHECK(v29,io_out_bits_uop_vpu_isNarrow)
    `CHECK(v29,io_out_bits_uop_vpu_isDstMask)
    `CHECK(v29,io_out_bits_uop_vpu_isOpMask)
    `CHECK(v29,io_out_bits_uop_vpu_isMove)
    `CHECK(v29,io_out_bits_uop_vpu_isDependOldVd)
    `CHECK(v29,io_out_bits_uop_vpu_isWritePartVd)
    `CHECK(v29,io_out_bits_uop_vpu_isVleff)
    `CHECK(v29,io_out_bits_uop_psrc_2)
    `CHECK(v29,io_out_bits_uop_pdest)
    `CHECK(v29,io_out_bits_uop_robIdx_flag)
    `CHECK(v29,io_out_bits_uop_robIdx_value)
    `CHECK(v29,io_out_bits_uop_debugInfo_eliminatedMove)
    `CHECK(v29,io_out_bits_uop_debugInfo_renameTime)
    `CHECK(v29,io_out_bits_uop_debugInfo_dispatchTime)
    `CHECK(v29,io_out_bits_uop_debugInfo_enqRsTime)
    `CHECK(v29,io_out_bits_uop_debugInfo_selectTime)
    `CHECK(v29,io_out_bits_uop_debugInfo_issueTime)
    `CHECK(v29,io_out_bits_uop_debugInfo_writebackTime)
    `CHECK(v29,io_out_bits_uop_debugInfo_runahead_checkpoint_id)
    `CHECK(v29,io_out_bits_uop_debugInfo_tlbFirstReqTime)
    `CHECK(v29,io_out_bits_uop_debugInfo_tlbRespTime)
    `CHECK(v29,io_out_bits_uop_debug_seqNum_seqNum)
    `CHECK(v29,io_out_bits_uop_debug_seqNum_uopIdx)
    `CHECK(v29,io_out_bits_uop_replayInst)
    `CHECK(v29,io_out_bits_data)
    `CHECK(v29,io_out_bits_vdIdx)
    `CHECK(v29,io_out_bits_vdIdxInField)
    `CHECK(v34,io_in_ready)
    `CHECK(v34,io_out_valid)
    `CHECK(v34,io_out_bits_uop_exceptionVec_0)
    `CHECK(v34,io_out_bits_uop_exceptionVec_1)
    `CHECK(v34,io_out_bits_uop_exceptionVec_2)
    `CHECK(v34,io_out_bits_uop_exceptionVec_3)
    `CHECK(v34,io_out_bits_uop_exceptionVec_4)
    `CHECK(v34,io_out_bits_uop_exceptionVec_5)
    `CHECK(v34,io_out_bits_uop_exceptionVec_6)
    `CHECK(v34,io_out_bits_uop_exceptionVec_7)
    `CHECK(v34,io_out_bits_uop_exceptionVec_8)
    `CHECK(v34,io_out_bits_uop_exceptionVec_9)
    `CHECK(v34,io_out_bits_uop_exceptionVec_10)
    `CHECK(v34,io_out_bits_uop_exceptionVec_11)
    `CHECK(v34,io_out_bits_uop_exceptionVec_12)
    `CHECK(v34,io_out_bits_uop_exceptionVec_13)
    `CHECK(v34,io_out_bits_uop_exceptionVec_14)
    `CHECK(v34,io_out_bits_uop_exceptionVec_15)
    `CHECK(v34,io_out_bits_uop_exceptionVec_16)
    `CHECK(v34,io_out_bits_uop_exceptionVec_17)
    `CHECK(v34,io_out_bits_uop_exceptionVec_18)
    `CHECK(v34,io_out_bits_uop_exceptionVec_19)
    `CHECK(v34,io_out_bits_uop_exceptionVec_20)
    `CHECK(v34,io_out_bits_uop_exceptionVec_21)
    `CHECK(v34,io_out_bits_uop_exceptionVec_22)
    `CHECK(v34,io_out_bits_uop_exceptionVec_23)
    `CHECK(v34,io_out_bits_uop_trigger)
    `CHECK(v34,io_out_bits_uop_rfWen)
    `CHECK(v34,io_out_bits_uop_flushPipe)
    `CHECK(v34,io_out_bits_uop_pdest)
    `CHECK(v34,io_out_bits_uop_robIdx_flag)
    `CHECK(v34,io_out_bits_uop_robIdx_value)
    `CHECK(v34,io_out_bits_uop_debugInfo_eliminatedMove)
    `CHECK(v34,io_out_bits_uop_debugInfo_renameTime)
    `CHECK(v34,io_out_bits_uop_debugInfo_dispatchTime)
    `CHECK(v34,io_out_bits_uop_debugInfo_enqRsTime)
    `CHECK(v34,io_out_bits_uop_debugInfo_selectTime)
    `CHECK(v34,io_out_bits_uop_debugInfo_issueTime)
    `CHECK(v34,io_out_bits_uop_debugInfo_writebackTime)
    `CHECK(v34,io_out_bits_uop_debugInfo_runahead_checkpoint_id)
    `CHECK(v34,io_out_bits_uop_debugInfo_tlbFirstReqTime)
    `CHECK(v34,io_out_bits_uop_debugInfo_tlbRespTime)
    `CHECK(v34,io_out_bits_uop_debug_seqNum_seqNum)
    `CHECK(v34,io_out_bits_uop_debug_seqNum_uopIdx)
    `CHECK(v34,io_out_bits_uop_sqIdx_flag)
    `CHECK(v34,io_out_bits_uop_sqIdx_value)
    `CHECK(v34,io_out_bits_data)
    `CHECK(v34,io_out_bits_debug_isMMIO)
    `CHECK(v35,io_in_ready)
    `CHECK(v35,io_out_valid)
    `CHECK(v35,io_out_bits_vaddr)
    `CHECK(v35,io_out_bits_basevaddr)
    `CHECK(v35,io_out_bits_mask)
    `CHECK(v35,io_out_bits_reg_offset)
    `CHECK(v35,io_out_bits_alignedType)
    `CHECK(v35,io_out_bits_vecActive)
    `CHECK(v35,io_out_bits_vecIsFirstActiveElement)
    `CHECK(v35,io_out_bits_uop_instr)
    `CHECK(v35,io_out_bits_uop_pc)
    `CHECK(v35,io_out_bits_uop_foldpc)
    `CHECK(v35,io_out_bits_uop_exceptionVec_4)
    `CHECK(v35,io_out_bits_uop_exceptionVec_5)
    `CHECK(v35,io_out_bits_uop_exceptionVec_6)
    `CHECK(v35,io_out_bits_uop_exceptionVec_7)
    `CHECK(v35,io_out_bits_uop_exceptionVec_13)
    `CHECK(v35,io_out_bits_uop_exceptionVec_15)
    `CHECK(v35,io_out_bits_uop_exceptionVec_19)
    `CHECK(v35,io_out_bits_uop_exceptionVec_21)
    `CHECK(v35,io_out_bits_uop_exceptionVec_23)
    `CHECK(v35,io_out_bits_uop_isFetchMalAddr)
    `CHECK(v35,io_out_bits_uop_hasException)
    `CHECK(v35,io_out_bits_uop_trigger)
    `CHECK(v35,io_out_bits_uop_preDecodeInfo_valid)
    `CHECK(v35,io_out_bits_uop_preDecodeInfo_isRVC)
    `CHECK(v35,io_out_bits_uop_preDecodeInfo_brType)
    `CHECK(v35,io_out_bits_uop_preDecodeInfo_isCall)
    `CHECK(v35,io_out_bits_uop_preDecodeInfo_isRet)
    `CHECK(v35,io_out_bits_uop_pred_taken)
    `CHECK(v35,io_out_bits_uop_crossPageIPFFix)
    `CHECK(v35,io_out_bits_uop_ftqPtr_flag)
    `CHECK(v35,io_out_bits_uop_ftqPtr_value)
    `CHECK(v35,io_out_bits_uop_ftqOffset)
    `CHECK(v35,io_out_bits_uop_satpFlushFirstFetchFault)
    `CHECK(v35,io_out_bits_uop_srcType_0)
    `CHECK(v35,io_out_bits_uop_srcType_1)
    `CHECK(v35,io_out_bits_uop_srcType_2)
    `CHECK(v35,io_out_bits_uop_srcType_3)
    `CHECK(v35,io_out_bits_uop_srcType_4)
    `CHECK(v35,io_out_bits_uop_ldest)
    `CHECK(v35,io_out_bits_uop_fuType)
    `CHECK(v35,io_out_bits_uop_fuOpType)
    `CHECK(v35,io_out_bits_uop_rfWen)
    `CHECK(v35,io_out_bits_uop_fpWen)
    `CHECK(v35,io_out_bits_uop_vecWen)
    `CHECK(v35,io_out_bits_uop_v0Wen)
    `CHECK(v35,io_out_bits_uop_vlWen)
    `CHECK(v35,io_out_bits_uop_isXSTrap)
    `CHECK(v35,io_out_bits_uop_waitForward)
    `CHECK(v35,io_out_bits_uop_blockBackward)
    `CHECK(v35,io_out_bits_uop_canRobCompress)
    `CHECK(v35,io_out_bits_uop_selImm)
    `CHECK(v35,io_out_bits_uop_fpu_typeTagOut)
    `CHECK(v35,io_out_bits_uop_fpu_wflags)
    `CHECK(v35,io_out_bits_uop_fpu_typ)
    `CHECK(v35,io_out_bits_uop_fpu_fmt)
    `CHECK(v35,io_out_bits_uop_fpu_rm)
    `CHECK(v35,io_out_bits_uop_vpu_vill)
    `CHECK(v35,io_out_bits_uop_vpu_vma)
    `CHECK(v35,io_out_bits_uop_vpu_vta)
    `CHECK(v35,io_out_bits_uop_vpu_vsew)
    `CHECK(v35,io_out_bits_uop_vpu_vlmul)
    `CHECK(v35,io_out_bits_uop_vpu_specVill)
    `CHECK(v35,io_out_bits_uop_vpu_specVma)
    `CHECK(v35,io_out_bits_uop_vpu_specVta)
    `CHECK(v35,io_out_bits_uop_vpu_specVsew)
    `CHECK(v35,io_out_bits_uop_vpu_specVlmul)
    `CHECK(v35,io_out_bits_uop_vpu_vm)
    `CHECK(v35,io_out_bits_uop_vpu_vstart)
    `CHECK(v35,io_out_bits_uop_vpu_frm)
    `CHECK(v35,io_out_bits_uop_vpu_fpu_isFpToVecInst)
    `CHECK(v35,io_out_bits_uop_vpu_fpu_isFP32Instr)
    `CHECK(v35,io_out_bits_uop_vpu_fpu_isFP64Instr)
    `CHECK(v35,io_out_bits_uop_vpu_fpu_isReduction)
    `CHECK(v35,io_out_bits_uop_vpu_fpu_isFoldTo1_2)
    `CHECK(v35,io_out_bits_uop_vpu_fpu_isFoldTo1_4)
    `CHECK(v35,io_out_bits_uop_vpu_fpu_isFoldTo1_8)
    `CHECK(v35,io_out_bits_uop_vpu_vxrm)
    `CHECK(v35,io_out_bits_uop_vpu_vuopIdx)
    `CHECK(v35,io_out_bits_uop_vpu_lastUop)
    `CHECK(v35,io_out_bits_uop_vpu_vmask)
    `CHECK(v35,io_out_bits_uop_vpu_vl)
    `CHECK(v35,io_out_bits_uop_vpu_nf)
    `CHECK(v35,io_out_bits_uop_vpu_veew)
    `CHECK(v35,io_out_bits_uop_vpu_isReverse)
    `CHECK(v35,io_out_bits_uop_vpu_isExt)
    `CHECK(v35,io_out_bits_uop_vpu_isNarrow)
    `CHECK(v35,io_out_bits_uop_vpu_isDstMask)
    `CHECK(v35,io_out_bits_uop_vpu_isOpMask)
    `CHECK(v35,io_out_bits_uop_vpu_isMove)
    `CHECK(v35,io_out_bits_uop_vpu_isDependOldVd)
    `CHECK(v35,io_out_bits_uop_vpu_isWritePartVd)
    `CHECK(v35,io_out_bits_uop_vpu_isVleff)
    `CHECK(v35,io_out_bits_uop_vlsInstr)
    `CHECK(v35,io_out_bits_uop_wfflags)
    `CHECK(v35,io_out_bits_uop_isMove)
    `CHECK(v35,io_out_bits_uop_isDropAmocasSta)
    `CHECK(v35,io_out_bits_uop_uopIdx)
    `CHECK(v35,io_out_bits_uop_isVset)
    `CHECK(v35,io_out_bits_uop_firstUop)
    `CHECK(v35,io_out_bits_uop_lastUop)
    `CHECK(v35,io_out_bits_uop_numUops)
    `CHECK(v35,io_out_bits_uop_numWB)
    `CHECK(v35,io_out_bits_uop_commitType)
    `CHECK(v35,io_out_bits_uop_srcState_0)
    `CHECK(v35,io_out_bits_uop_srcState_1)
    `CHECK(v35,io_out_bits_uop_srcState_2)
    `CHECK(v35,io_out_bits_uop_srcState_3)
    `CHECK(v35,io_out_bits_uop_srcState_4)
    `CHECK(v35,io_out_bits_uop_srcLoadDependency_0_0)
    `CHECK(v35,io_out_bits_uop_srcLoadDependency_0_1)
    `CHECK(v35,io_out_bits_uop_srcLoadDependency_0_2)
    `CHECK(v35,io_out_bits_uop_srcLoadDependency_1_0)
    `CHECK(v35,io_out_bits_uop_srcLoadDependency_1_1)
    `CHECK(v35,io_out_bits_uop_srcLoadDependency_1_2)
    `CHECK(v35,io_out_bits_uop_srcLoadDependency_2_0)
    `CHECK(v35,io_out_bits_uop_srcLoadDependency_2_1)
    `CHECK(v35,io_out_bits_uop_srcLoadDependency_2_2)
    `CHECK(v35,io_out_bits_uop_srcLoadDependency_3_0)
    `CHECK(v35,io_out_bits_uop_srcLoadDependency_3_1)
    `CHECK(v35,io_out_bits_uop_srcLoadDependency_3_2)
    `CHECK(v35,io_out_bits_uop_srcLoadDependency_4_0)
    `CHECK(v35,io_out_bits_uop_srcLoadDependency_4_1)
    `CHECK(v35,io_out_bits_uop_srcLoadDependency_4_2)
    `CHECK(v35,io_out_bits_uop_psrc_0)
    `CHECK(v35,io_out_bits_uop_psrc_1)
    `CHECK(v35,io_out_bits_uop_psrc_2)
    `CHECK(v35,io_out_bits_uop_psrc_3)
    `CHECK(v35,io_out_bits_uop_psrc_4)
    `CHECK(v35,io_out_bits_uop_pdest)
    `CHECK(v35,io_out_bits_uop_useRegCache_0)
    `CHECK(v35,io_out_bits_uop_useRegCache_1)
    `CHECK(v35,io_out_bits_uop_regCacheIdx_0)
    `CHECK(v35,io_out_bits_uop_regCacheIdx_1)
    `CHECK(v35,io_out_bits_uop_robIdx_flag)
    `CHECK(v35,io_out_bits_uop_robIdx_value)
    `CHECK(v35,io_out_bits_uop_instrSize)
    `CHECK(v35,io_out_bits_uop_dirtyFs)
    `CHECK(v35,io_out_bits_uop_dirtyVs)
    `CHECK(v35,io_out_bits_uop_traceBlockInPipe_itype)
    `CHECK(v35,io_out_bits_uop_traceBlockInPipe_iretire)
    `CHECK(v35,io_out_bits_uop_traceBlockInPipe_ilastsize)
    `CHECK(v35,io_out_bits_uop_eliminatedMove)
    `CHECK(v35,io_out_bits_uop_snapshot)
    `CHECK(v35,io_out_bits_uop_debugInfo_eliminatedMove)
    `CHECK(v35,io_out_bits_uop_debugInfo_renameTime)
    `CHECK(v35,io_out_bits_uop_debugInfo_dispatchTime)
    `CHECK(v35,io_out_bits_uop_debugInfo_enqRsTime)
    `CHECK(v35,io_out_bits_uop_debugInfo_selectTime)
    `CHECK(v35,io_out_bits_uop_debugInfo_issueTime)
    `CHECK(v35,io_out_bits_uop_debugInfo_writebackTime)
    `CHECK(v35,io_out_bits_uop_debugInfo_runahead_checkpoint_id)
    `CHECK(v35,io_out_bits_uop_debugInfo_tlbFirstReqTime)
    `CHECK(v35,io_out_bits_uop_debugInfo_tlbRespTime)
    `CHECK(v35,io_out_bits_uop_debug_seqNum_seqNum)
    `CHECK(v35,io_out_bits_uop_debug_seqNum_uopIdx)
    `CHECK(v35,io_out_bits_uop_storeSetHit)
    `CHECK(v35,io_out_bits_uop_waitForRobIdx_flag)
    `CHECK(v35,io_out_bits_uop_waitForRobIdx_value)
    `CHECK(v35,io_out_bits_uop_loadWaitBit)
    `CHECK(v35,io_out_bits_uop_loadWaitStrict)
    `CHECK(v35,io_out_bits_uop_ssid)
    `CHECK(v35,io_out_bits_uop_lqIdx_flag)
    `CHECK(v35,io_out_bits_uop_lqIdx_value)
    `CHECK(v35,io_out_bits_uop_sqIdx_flag)
    `CHECK(v35,io_out_bits_uop_sqIdx_value)
    `CHECK(v35,io_out_bits_uop_singleStep)
    `CHECK(v35,io_out_bits_uop_replayInst)
    `CHECK(v35,io_out_bits_uop_debug_fuType)
    `CHECK(v35,io_out_bits_uop_debug_sim_trig)
    `CHECK(v35,io_out_bits_uop_numLsElem)
    `CHECK(v35,io_out_bits_mBIndex)
    `CHECK(v35,io_out_bits_elemIdx)
    `CHECK(v35,io_out_bits_elemIdxInsideVd)
    `CHECK(v35,io_out_bits_splitIndex)
  endtask

  task automatic sample_cov();
    if (v29_io_in_valid && g_v29_io_in_ready === 1'b1) begin
      fire_v29++; por_v29 |= pcat_v29; pand_v29 &= pcat_v29;
      if (v29_io_isFlush) flfire_v29++;
    end
    if (v29_io_in_valid && g_v29_io_in_ready === 1'b0) bp_v29++;
    if (g_v29_io_out_valid === 1'b1) begin
      if (v29_io_isFlush) flush_v29++;
      if (v29_io_rightOutFire) deq_v29++; else hold_v29++;
      if (v29_io_out_ready && v29_io_in_valid) owr_v29++;
    end
    if (v34_io_in_valid && g_v34_io_in_ready === 1'b1) begin
      fire_v34++; por_v34 |= pcat_v34; pand_v34 &= pcat_v34;
    end
    if (v34_io_in_valid && g_v34_io_in_ready === 1'b0) bp_v34++;
    if (g_v34_io_out_valid === 1'b1) begin
      if (v34_io_rightOutFire) deq_v34++; else hold_v34++;
      if (v34_io_out_ready && v34_io_in_valid) owr_v34++;
    end
    if (v35_io_in_valid && g_v35_io_in_ready === 1'b1) begin
      fire_v35++; por_v35 |= pcat_v35; pand_v35 &= pcat_v35;
      if (v35_io_isFlush) flfire_v35++;
    end
    if (v35_io_in_valid && g_v35_io_in_ready === 1'b0) bp_v35++;
    if (g_v35_io_out_valid === 1'b1) begin
      if (v35_io_isFlush) flush_v35++;
      if (v35_io_rightOutFire) deq_v35++; else hold_v35++;
      if (v35_io_out_ready && v35_io_in_valid) owr_v35++;
    end
  endtask

  int cov_fail = 0;
  task automatic gate(string nm, longint got, longint need, string why);
    if (got < need) begin
      $display("COVERAGE HOLE: %s = %0d < %0d —— %s", nm, got, need, why);
      cov_fail++;
    end
  endtask

  initial begin
    if ($value$plusargs("ncycles=%d", NCYCLES)) begin end
    reset = 1'b1;
    drive_all();
    repeat (8) @(posedge clock);
    reset = 1'b0;
    repeat (NCYCLES) begin
      @(negedge clock);
      drive_all();
      #1 sample_cov();          // 沿前采：见文件头「采样时机」
      @(posedge clock);
      #1 check_all();
    end

    $display("\n==== NewPipelineConnectPipe_29/_34/_35: checks=%0d errors=%0d (ncycles=%0d) ====", checks, errors, NCYCLES);
    $display("%-28s %10s %7s %9s %8s %8s %8s %8s %7s %7s %6s",
             "variant", "checks", "errors", "fire", "backpr", "hold", "deq", "owrite",
             "flush", "fl&fire", "payld");
    $display("%-28s %10d %7d %9d %8d %8d %8d %8d %7d %7d %6s", "NewPipelineConnectPipe_29",
             nchk_v29, nerr_v29, fire_v29, bp_v29, hold_v29, deq_v29, owr_v29, flush_v29, flfire_v29,
             ((&por_v29) && (pand_v29 == '0)) ? "ok" : "HOLE");
    $display("%-28s %10d %7d %9d %8d %8d %8d %8d %7d %7d %6s", "NewPipelineConnectPipe_34",
             nchk_v34, nerr_v34, fire_v34, bp_v34, hold_v34, deq_v34, owr_v34, -1, -1,
             ((&por_v34) && (pand_v34 == '0)) ? "ok" : "HOLE");
    $display("%-28s %10d %7d %9d %8d %8d %8d %8d %7d %7d %6s", "NewPipelineConnectPipe_35",
             nchk_v35, nerr_v35, fire_v35, bp_v35, hold_v35, deq_v35, owr_v35, flush_v35, flfire_v35,
             ((&por_v35) && (pand_v35 == '0)) ? "ok" : "HOLE");
    $display("（flush 列 -1 = 该变体 golden 无 io_isFlush 端口，两条 flush 闸不适用）");

    gate("NewPipelineConnectPipe_29.fire",   fire_v29, 1000, "从没锁进过数据");
    gate("NewPipelineConnectPipe_29.backpr", bp_v29,    100, "上游从没被挡过（握手永远畅通=假绿）");
    gate("NewPipelineConnectPipe_29.hold",   hold_v29,  100, "表项从没被压住过");
    gate("NewPipelineConnectPipe_29.deq",    deq_v29,   100, "表项从没被下游取走过");
    gate("NewPipelineConnectPipe_29.owr",    owr_v29,   100, "从没在占用中被新数据改写过");
    gate("NewPipelineConnectPipe_29.flush",  flush_v29,  10, "flush 从没命中占用中的表项");
    gate("NewPipelineConnectPipe_29.flush&fire", flfire_v29, 10, "flush 与 fire 从没同拍过（冲刷优先级没测到）");
    if (!(&por_v29)) begin $display("COVERAGE HOLE: NewPipelineConnectPipe_29 payload 有位从未取到 1"); cov_fail++; end
    if (pand_v29 != '0) begin $display("COVERAGE HOLE: NewPipelineConnectPipe_29 payload 有位从未取到 0"); cov_fail++; end
    gate("NewPipelineConnectPipe_34.fire",   fire_v34, 1000, "从没锁进过数据");
    gate("NewPipelineConnectPipe_34.backpr", bp_v34,    100, "上游从没被挡过（握手永远畅通=假绿）");
    gate("NewPipelineConnectPipe_34.hold",   hold_v34,  100, "表项从没被压住过");
    gate("NewPipelineConnectPipe_34.deq",    deq_v34,   100, "表项从没被下游取走过");
    gate("NewPipelineConnectPipe_34.owr",    owr_v34,   100, "从没在占用中被新数据改写过");
    if (!(&por_v34)) begin $display("COVERAGE HOLE: NewPipelineConnectPipe_34 payload 有位从未取到 1"); cov_fail++; end
    if (pand_v34 != '0) begin $display("COVERAGE HOLE: NewPipelineConnectPipe_34 payload 有位从未取到 0"); cov_fail++; end
    gate("NewPipelineConnectPipe_35.fire",   fire_v35, 1000, "从没锁进过数据");
    gate("NewPipelineConnectPipe_35.backpr", bp_v35,    100, "上游从没被挡过（握手永远畅通=假绿）");
    gate("NewPipelineConnectPipe_35.hold",   hold_v35,  100, "表项从没被压住过");
    gate("NewPipelineConnectPipe_35.deq",    deq_v35,   100, "表项从没被下游取走过");
    gate("NewPipelineConnectPipe_35.owr",    owr_v35,   100, "从没在占用中被新数据改写过");
    gate("NewPipelineConnectPipe_35.flush",  flush_v35,  10, "flush 从没命中占用中的表项");
    gate("NewPipelineConnectPipe_35.flush&fire", flfire_v35, 10, "flush 与 fire 从没同拍过（冲刷优先级没测到）");
    if (!(&por_v35)) begin $display("COVERAGE HOLE: NewPipelineConnectPipe_35 payload 有位从未取到 1"); cov_fail++; end
    if (pand_v35 != '0) begin $display("COVERAGE HOLE: NewPipelineConnectPipe_35 payload 有位从未取到 0"); cov_fail++; end

    if (cov_fail != 0) begin
      $display("TEST FAILED (%0d 个覆盖闸没过)", cov_fail);
      $fatal(1);
    end
    if (errors == 0 && checks > 100000) begin
      $display("TEST PASSED");
      $finish;
    end
    $display("TEST FAILED");
    $fatal(1);
  end
endmodule
