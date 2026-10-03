// =============================================================================
// tb —— VfofBuffer UT：golden VfofBuffer 与重写件 VfofBuffer_xs 双例化，同激励逐拍比全部
// 56 个输出（uopWriteback.valid / data / uop 各字段）。全部寄存器异步复位，复位撤销后每拍比。
//
// 激励（robIdx 取 4 个值 × 2 个 flag 的小池子，让写回口/redirect 有可观的命中率）：
//   in0/in1  各 1/3 拍有效，其中 isVleff 3/4；lastUop 1/4；robIdx 来自池子；其余字段全随机；
//   写回口   各 1/2 拍有效，robIdx 来自池子，vl 0~40，六位异常各 1/16 置 1；
//   redirect 1/24 拍有效，level 随机，robIdx 来自池子；uopWriteback.ready 3/4。
// 覆盖（写进 PASS 判据，从 golden 内部信号数）：出队 fire / 两口同时命中 / 写回更新 vl /
//   写回带异常 / 条目被 redirect 冲掉 / 非空时 lastUop 刷新 uop，各 >= NCYCLES/400。
// =============================================================================
`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 200000;
  longint errors = 0, checks = 0;
  int cyc;

  // ---- 以下声明/例化/比较由 golden 端口表机械展开（137 输入 / 56 输出）----
  logic clock;
  logic reset;
  logic io_redirect_valid;
  logic io_redirect_bits_robIdx_flag;
  logic [7:0] io_redirect_bits_robIdx_value;
  logic io_redirect_bits_level;
  logic io_in_0_valid;
  logic [8:0] io_in_0_bits_uop_fuOpType;
  logic io_in_0_bits_uop_vecWen;
  logic io_in_0_bits_uop_v0Wen;
  logic io_in_0_bits_uop_vlWen;
  logic io_in_0_bits_uop_vpu_vill;
  logic io_in_0_bits_uop_vpu_vma;
  logic io_in_0_bits_uop_vpu_vta;
  logic [1:0] io_in_0_bits_uop_vpu_vsew;
  logic [2:0] io_in_0_bits_uop_vpu_vlmul;
  logic io_in_0_bits_uop_vpu_specVill;
  logic io_in_0_bits_uop_vpu_specVma;
  logic io_in_0_bits_uop_vpu_specVta;
  logic [1:0] io_in_0_bits_uop_vpu_specVsew;
  logic [2:0] io_in_0_bits_uop_vpu_specVlmul;
  logic io_in_0_bits_uop_vpu_vm;
  logic [7:0] io_in_0_bits_uop_vpu_vstart;
  logic [2:0] io_in_0_bits_uop_vpu_frm;
  logic io_in_0_bits_uop_vpu_fpu_isFpToVecInst;
  logic io_in_0_bits_uop_vpu_fpu_isFP32Instr;
  logic io_in_0_bits_uop_vpu_fpu_isFP64Instr;
  logic io_in_0_bits_uop_vpu_fpu_isReduction;
  logic io_in_0_bits_uop_vpu_fpu_isFoldTo1_2;
  logic io_in_0_bits_uop_vpu_fpu_isFoldTo1_4;
  logic io_in_0_bits_uop_vpu_fpu_isFoldTo1_8;
  logic [1:0] io_in_0_bits_uop_vpu_vxrm;
  logic [6:0] io_in_0_bits_uop_vpu_vuopIdx;
  logic io_in_0_bits_uop_vpu_lastUop;
  logic [2:0] io_in_0_bits_uop_vpu_nf;
  logic [1:0] io_in_0_bits_uop_vpu_veew;
  logic io_in_0_bits_uop_vpu_isReverse;
  logic io_in_0_bits_uop_vpu_isExt;
  logic io_in_0_bits_uop_vpu_isNarrow;
  logic io_in_0_bits_uop_vpu_isDstMask;
  logic io_in_0_bits_uop_vpu_isOpMask;
  logic io_in_0_bits_uop_vpu_isMove;
  logic io_in_0_bits_uop_vpu_isDependOldVd;
  logic io_in_0_bits_uop_vpu_isWritePartVd;
  logic io_in_0_bits_uop_vpu_isVleff;
  logic [7:0] io_in_0_bits_uop_pdest;
  logic io_in_0_bits_uop_robIdx_flag;
  logic [7:0] io_in_0_bits_uop_robIdx_value;
  logic io_in_0_bits_uop_debugInfo_eliminatedMove;
  logic [63:0] io_in_0_bits_uop_debugInfo_renameTime;
  logic [63:0] io_in_0_bits_uop_debugInfo_dispatchTime;
  logic [63:0] io_in_0_bits_uop_debugInfo_enqRsTime;
  logic [63:0] io_in_0_bits_uop_debugInfo_selectTime;
  logic [63:0] io_in_0_bits_uop_debugInfo_issueTime;
  logic [63:0] io_in_0_bits_uop_debugInfo_writebackTime;
  logic [63:0] io_in_0_bits_uop_debugInfo_runahead_checkpoint_id;
  logic [63:0] io_in_0_bits_uop_debugInfo_tlbFirstReqTime;
  logic [63:0] io_in_0_bits_uop_debugInfo_tlbRespTime;
  logic [55:0] io_in_0_bits_uop_debug_seqNum_seqNum;
  logic [7:0] io_in_0_bits_uop_debug_seqNum_uopIdx;
  logic [127:0] io_in_0_bits_src_4;
  logic io_in_1_valid;
  logic [8:0] io_in_1_bits_uop_fuOpType;
  logic io_in_1_bits_uop_vecWen;
  logic io_in_1_bits_uop_v0Wen;
  logic io_in_1_bits_uop_vlWen;
  logic io_in_1_bits_uop_vpu_vill;
  logic io_in_1_bits_uop_vpu_vma;
  logic io_in_1_bits_uop_vpu_vta;
  logic [1:0] io_in_1_bits_uop_vpu_vsew;
  logic [2:0] io_in_1_bits_uop_vpu_vlmul;
  logic io_in_1_bits_uop_vpu_specVill;
  logic io_in_1_bits_uop_vpu_specVma;
  logic io_in_1_bits_uop_vpu_specVta;
  logic [1:0] io_in_1_bits_uop_vpu_specVsew;
  logic [2:0] io_in_1_bits_uop_vpu_specVlmul;
  logic io_in_1_bits_uop_vpu_vm;
  logic [7:0] io_in_1_bits_uop_vpu_vstart;
  logic [2:0] io_in_1_bits_uop_vpu_frm;
  logic io_in_1_bits_uop_vpu_fpu_isFpToVecInst;
  logic io_in_1_bits_uop_vpu_fpu_isFP32Instr;
  logic io_in_1_bits_uop_vpu_fpu_isFP64Instr;
  logic io_in_1_bits_uop_vpu_fpu_isReduction;
  logic io_in_1_bits_uop_vpu_fpu_isFoldTo1_2;
  logic io_in_1_bits_uop_vpu_fpu_isFoldTo1_4;
  logic io_in_1_bits_uop_vpu_fpu_isFoldTo1_8;
  logic [1:0] io_in_1_bits_uop_vpu_vxrm;
  logic [6:0] io_in_1_bits_uop_vpu_vuopIdx;
  logic io_in_1_bits_uop_vpu_lastUop;
  logic [2:0] io_in_1_bits_uop_vpu_nf;
  logic [1:0] io_in_1_bits_uop_vpu_veew;
  logic io_in_1_bits_uop_vpu_isReverse;
  logic io_in_1_bits_uop_vpu_isExt;
  logic io_in_1_bits_uop_vpu_isNarrow;
  logic io_in_1_bits_uop_vpu_isDstMask;
  logic io_in_1_bits_uop_vpu_isOpMask;
  logic io_in_1_bits_uop_vpu_isMove;
  logic io_in_1_bits_uop_vpu_isDependOldVd;
  logic io_in_1_bits_uop_vpu_isWritePartVd;
  logic io_in_1_bits_uop_vpu_isVleff;
  logic [7:0] io_in_1_bits_uop_pdest;
  logic io_in_1_bits_uop_robIdx_flag;
  logic [7:0] io_in_1_bits_uop_robIdx_value;
  logic io_in_1_bits_uop_debugInfo_eliminatedMove;
  logic [63:0] io_in_1_bits_uop_debugInfo_renameTime;
  logic [63:0] io_in_1_bits_uop_debugInfo_dispatchTime;
  logic [63:0] io_in_1_bits_uop_debugInfo_enqRsTime;
  logic [63:0] io_in_1_bits_uop_debugInfo_selectTime;
  logic [63:0] io_in_1_bits_uop_debugInfo_issueTime;
  logic [63:0] io_in_1_bits_uop_debugInfo_writebackTime;
  logic [63:0] io_in_1_bits_uop_debugInfo_runahead_checkpoint_id;
  logic [63:0] io_in_1_bits_uop_debugInfo_tlbFirstReqTime;
  logic [63:0] io_in_1_bits_uop_debugInfo_tlbRespTime;
  logic [55:0] io_in_1_bits_uop_debug_seqNum_seqNum;
  logic [7:0] io_in_1_bits_uop_debug_seqNum_uopIdx;
  logic [127:0] io_in_1_bits_src_4;
  logic io_mergeUopWriteback_0_valid;
  logic io_mergeUopWriteback_0_bits_robidx_flag;
  logic [7:0] io_mergeUopWriteback_0_bits_robidx_value;
  logic [7:0] io_mergeUopWriteback_0_bits_vl;
  logic io_mergeUopWriteback_0_bits_exceptionVec_3;
  logic io_mergeUopWriteback_0_bits_exceptionVec_4;
  logic io_mergeUopWriteback_0_bits_exceptionVec_5;
  logic io_mergeUopWriteback_0_bits_exceptionVec_13;
  logic io_mergeUopWriteback_0_bits_exceptionVec_19;
  logic io_mergeUopWriteback_0_bits_exceptionVec_21;
  logic io_mergeUopWriteback_1_valid;
  logic io_mergeUopWriteback_1_bits_robidx_flag;
  logic [7:0] io_mergeUopWriteback_1_bits_robidx_value;
  logic [7:0] io_mergeUopWriteback_1_bits_vl;
  logic io_mergeUopWriteback_1_bits_exceptionVec_3;
  logic io_mergeUopWriteback_1_bits_exceptionVec_4;
  logic io_mergeUopWriteback_1_bits_exceptionVec_5;
  logic io_mergeUopWriteback_1_bits_exceptionVec_13;
  logic io_mergeUopWriteback_1_bits_exceptionVec_19;
  logic io_mergeUopWriteback_1_bits_exceptionVec_21;
  logic io_uopWriteback_ready;
  logic g_io_uopWriteback_valid, i_io_uopWriteback_valid;
  logic [8:0] g_io_uopWriteback_bits_uop_fuOpType, i_io_uopWriteback_bits_uop_fuOpType;
  logic g_io_uopWriteback_bits_uop_vecWen, i_io_uopWriteback_bits_uop_vecWen;
  logic g_io_uopWriteback_bits_uop_v0Wen, i_io_uopWriteback_bits_uop_v0Wen;
  logic g_io_uopWriteback_bits_uop_vlWen, i_io_uopWriteback_bits_uop_vlWen;
  logic g_io_uopWriteback_bits_uop_vpu_vill, i_io_uopWriteback_bits_uop_vpu_vill;
  logic g_io_uopWriteback_bits_uop_vpu_vma, i_io_uopWriteback_bits_uop_vpu_vma;
  logic g_io_uopWriteback_bits_uop_vpu_vta, i_io_uopWriteback_bits_uop_vpu_vta;
  logic [1:0] g_io_uopWriteback_bits_uop_vpu_vsew, i_io_uopWriteback_bits_uop_vpu_vsew;
  logic [2:0] g_io_uopWriteback_bits_uop_vpu_vlmul, i_io_uopWriteback_bits_uop_vpu_vlmul;
  logic g_io_uopWriteback_bits_uop_vpu_specVill, i_io_uopWriteback_bits_uop_vpu_specVill;
  logic g_io_uopWriteback_bits_uop_vpu_specVma, i_io_uopWriteback_bits_uop_vpu_specVma;
  logic g_io_uopWriteback_bits_uop_vpu_specVta, i_io_uopWriteback_bits_uop_vpu_specVta;
  logic [1:0] g_io_uopWriteback_bits_uop_vpu_specVsew, i_io_uopWriteback_bits_uop_vpu_specVsew;
  logic [2:0] g_io_uopWriteback_bits_uop_vpu_specVlmul, i_io_uopWriteback_bits_uop_vpu_specVlmul;
  logic g_io_uopWriteback_bits_uop_vpu_vm, i_io_uopWriteback_bits_uop_vpu_vm;
  logic [7:0] g_io_uopWriteback_bits_uop_vpu_vstart, i_io_uopWriteback_bits_uop_vpu_vstart;
  logic [2:0] g_io_uopWriteback_bits_uop_vpu_frm, i_io_uopWriteback_bits_uop_vpu_frm;
  logic g_io_uopWriteback_bits_uop_vpu_fpu_isFpToVecInst, i_io_uopWriteback_bits_uop_vpu_fpu_isFpToVecInst;
  logic g_io_uopWriteback_bits_uop_vpu_fpu_isFP32Instr, i_io_uopWriteback_bits_uop_vpu_fpu_isFP32Instr;
  logic g_io_uopWriteback_bits_uop_vpu_fpu_isFP64Instr, i_io_uopWriteback_bits_uop_vpu_fpu_isFP64Instr;
  logic g_io_uopWriteback_bits_uop_vpu_fpu_isReduction, i_io_uopWriteback_bits_uop_vpu_fpu_isReduction;
  logic g_io_uopWriteback_bits_uop_vpu_fpu_isFoldTo1_2, i_io_uopWriteback_bits_uop_vpu_fpu_isFoldTo1_2;
  logic g_io_uopWriteback_bits_uop_vpu_fpu_isFoldTo1_4, i_io_uopWriteback_bits_uop_vpu_fpu_isFoldTo1_4;
  logic g_io_uopWriteback_bits_uop_vpu_fpu_isFoldTo1_8, i_io_uopWriteback_bits_uop_vpu_fpu_isFoldTo1_8;
  logic [1:0] g_io_uopWriteback_bits_uop_vpu_vxrm, i_io_uopWriteback_bits_uop_vpu_vxrm;
  logic [6:0] g_io_uopWriteback_bits_uop_vpu_vuopIdx, i_io_uopWriteback_bits_uop_vpu_vuopIdx;
  logic g_io_uopWriteback_bits_uop_vpu_lastUop, i_io_uopWriteback_bits_uop_vpu_lastUop;
  logic [7:0] g_io_uopWriteback_bits_uop_vpu_vl, i_io_uopWriteback_bits_uop_vpu_vl;
  logic [2:0] g_io_uopWriteback_bits_uop_vpu_nf, i_io_uopWriteback_bits_uop_vpu_nf;
  logic [1:0] g_io_uopWriteback_bits_uop_vpu_veew, i_io_uopWriteback_bits_uop_vpu_veew;
  logic g_io_uopWriteback_bits_uop_vpu_isReverse, i_io_uopWriteback_bits_uop_vpu_isReverse;
  logic g_io_uopWriteback_bits_uop_vpu_isExt, i_io_uopWriteback_bits_uop_vpu_isExt;
  logic g_io_uopWriteback_bits_uop_vpu_isNarrow, i_io_uopWriteback_bits_uop_vpu_isNarrow;
  logic g_io_uopWriteback_bits_uop_vpu_isDstMask, i_io_uopWriteback_bits_uop_vpu_isDstMask;
  logic g_io_uopWriteback_bits_uop_vpu_isOpMask, i_io_uopWriteback_bits_uop_vpu_isOpMask;
  logic g_io_uopWriteback_bits_uop_vpu_isMove, i_io_uopWriteback_bits_uop_vpu_isMove;
  logic g_io_uopWriteback_bits_uop_vpu_isDependOldVd, i_io_uopWriteback_bits_uop_vpu_isDependOldVd;
  logic g_io_uopWriteback_bits_uop_vpu_isWritePartVd, i_io_uopWriteback_bits_uop_vpu_isWritePartVd;
  logic g_io_uopWriteback_bits_uop_vpu_isVleff, i_io_uopWriteback_bits_uop_vpu_isVleff;
  logic [7:0] g_io_uopWriteback_bits_uop_pdest, i_io_uopWriteback_bits_uop_pdest;
  logic g_io_uopWriteback_bits_uop_robIdx_flag, i_io_uopWriteback_bits_uop_robIdx_flag;
  logic [7:0] g_io_uopWriteback_bits_uop_robIdx_value, i_io_uopWriteback_bits_uop_robIdx_value;
  logic g_io_uopWriteback_bits_uop_debugInfo_eliminatedMove, i_io_uopWriteback_bits_uop_debugInfo_eliminatedMove;
  logic [63:0] g_io_uopWriteback_bits_uop_debugInfo_renameTime, i_io_uopWriteback_bits_uop_debugInfo_renameTime;
  logic [63:0] g_io_uopWriteback_bits_uop_debugInfo_dispatchTime, i_io_uopWriteback_bits_uop_debugInfo_dispatchTime;
  logic [63:0] g_io_uopWriteback_bits_uop_debugInfo_enqRsTime, i_io_uopWriteback_bits_uop_debugInfo_enqRsTime;
  logic [63:0] g_io_uopWriteback_bits_uop_debugInfo_selectTime, i_io_uopWriteback_bits_uop_debugInfo_selectTime;
  logic [63:0] g_io_uopWriteback_bits_uop_debugInfo_issueTime, i_io_uopWriteback_bits_uop_debugInfo_issueTime;
  logic [63:0] g_io_uopWriteback_bits_uop_debugInfo_writebackTime, i_io_uopWriteback_bits_uop_debugInfo_writebackTime;
  logic [63:0] g_io_uopWriteback_bits_uop_debugInfo_runahead_checkpoint_id, i_io_uopWriteback_bits_uop_debugInfo_runahead_checkpoint_id;
  logic [63:0] g_io_uopWriteback_bits_uop_debugInfo_tlbFirstReqTime, i_io_uopWriteback_bits_uop_debugInfo_tlbFirstReqTime;
  logic [63:0] g_io_uopWriteback_bits_uop_debugInfo_tlbRespTime, i_io_uopWriteback_bits_uop_debugInfo_tlbRespTime;
  logic [55:0] g_io_uopWriteback_bits_uop_debug_seqNum_seqNum, i_io_uopWriteback_bits_uop_debug_seqNum_seqNum;
  logic [7:0] g_io_uopWriteback_bits_uop_debug_seqNum_uopIdx, i_io_uopWriteback_bits_uop_debug_seqNum_uopIdx;
  logic [127:0] g_io_uopWriteback_bits_data, i_io_uopWriteback_bits_data;
  VfofBuffer u_g (
    .clock(clock),
    .reset(reset),
    .io_redirect_valid(io_redirect_valid),
    .io_redirect_bits_robIdx_flag(io_redirect_bits_robIdx_flag),
    .io_redirect_bits_robIdx_value(io_redirect_bits_robIdx_value),
    .io_redirect_bits_level(io_redirect_bits_level),
    .io_in_0_valid(io_in_0_valid),
    .io_in_0_bits_uop_fuOpType(io_in_0_bits_uop_fuOpType),
    .io_in_0_bits_uop_vecWen(io_in_0_bits_uop_vecWen),
    .io_in_0_bits_uop_v0Wen(io_in_0_bits_uop_v0Wen),
    .io_in_0_bits_uop_vlWen(io_in_0_bits_uop_vlWen),
    .io_in_0_bits_uop_vpu_vill(io_in_0_bits_uop_vpu_vill),
    .io_in_0_bits_uop_vpu_vma(io_in_0_bits_uop_vpu_vma),
    .io_in_0_bits_uop_vpu_vta(io_in_0_bits_uop_vpu_vta),
    .io_in_0_bits_uop_vpu_vsew(io_in_0_bits_uop_vpu_vsew),
    .io_in_0_bits_uop_vpu_vlmul(io_in_0_bits_uop_vpu_vlmul),
    .io_in_0_bits_uop_vpu_specVill(io_in_0_bits_uop_vpu_specVill),
    .io_in_0_bits_uop_vpu_specVma(io_in_0_bits_uop_vpu_specVma),
    .io_in_0_bits_uop_vpu_specVta(io_in_0_bits_uop_vpu_specVta),
    .io_in_0_bits_uop_vpu_specVsew(io_in_0_bits_uop_vpu_specVsew),
    .io_in_0_bits_uop_vpu_specVlmul(io_in_0_bits_uop_vpu_specVlmul),
    .io_in_0_bits_uop_vpu_vm(io_in_0_bits_uop_vpu_vm),
    .io_in_0_bits_uop_vpu_vstart(io_in_0_bits_uop_vpu_vstart),
    .io_in_0_bits_uop_vpu_frm(io_in_0_bits_uop_vpu_frm),
    .io_in_0_bits_uop_vpu_fpu_isFpToVecInst(io_in_0_bits_uop_vpu_fpu_isFpToVecInst),
    .io_in_0_bits_uop_vpu_fpu_isFP32Instr(io_in_0_bits_uop_vpu_fpu_isFP32Instr),
    .io_in_0_bits_uop_vpu_fpu_isFP64Instr(io_in_0_bits_uop_vpu_fpu_isFP64Instr),
    .io_in_0_bits_uop_vpu_fpu_isReduction(io_in_0_bits_uop_vpu_fpu_isReduction),
    .io_in_0_bits_uop_vpu_fpu_isFoldTo1_2(io_in_0_bits_uop_vpu_fpu_isFoldTo1_2),
    .io_in_0_bits_uop_vpu_fpu_isFoldTo1_4(io_in_0_bits_uop_vpu_fpu_isFoldTo1_4),
    .io_in_0_bits_uop_vpu_fpu_isFoldTo1_8(io_in_0_bits_uop_vpu_fpu_isFoldTo1_8),
    .io_in_0_bits_uop_vpu_vxrm(io_in_0_bits_uop_vpu_vxrm),
    .io_in_0_bits_uop_vpu_vuopIdx(io_in_0_bits_uop_vpu_vuopIdx),
    .io_in_0_bits_uop_vpu_lastUop(io_in_0_bits_uop_vpu_lastUop),
    .io_in_0_bits_uop_vpu_nf(io_in_0_bits_uop_vpu_nf),
    .io_in_0_bits_uop_vpu_veew(io_in_0_bits_uop_vpu_veew),
    .io_in_0_bits_uop_vpu_isReverse(io_in_0_bits_uop_vpu_isReverse),
    .io_in_0_bits_uop_vpu_isExt(io_in_0_bits_uop_vpu_isExt),
    .io_in_0_bits_uop_vpu_isNarrow(io_in_0_bits_uop_vpu_isNarrow),
    .io_in_0_bits_uop_vpu_isDstMask(io_in_0_bits_uop_vpu_isDstMask),
    .io_in_0_bits_uop_vpu_isOpMask(io_in_0_bits_uop_vpu_isOpMask),
    .io_in_0_bits_uop_vpu_isMove(io_in_0_bits_uop_vpu_isMove),
    .io_in_0_bits_uop_vpu_isDependOldVd(io_in_0_bits_uop_vpu_isDependOldVd),
    .io_in_0_bits_uop_vpu_isWritePartVd(io_in_0_bits_uop_vpu_isWritePartVd),
    .io_in_0_bits_uop_vpu_isVleff(io_in_0_bits_uop_vpu_isVleff),
    .io_in_0_bits_uop_pdest(io_in_0_bits_uop_pdest),
    .io_in_0_bits_uop_robIdx_flag(io_in_0_bits_uop_robIdx_flag),
    .io_in_0_bits_uop_robIdx_value(io_in_0_bits_uop_robIdx_value),
    .io_in_0_bits_uop_debugInfo_eliminatedMove(io_in_0_bits_uop_debugInfo_eliminatedMove),
    .io_in_0_bits_uop_debugInfo_renameTime(io_in_0_bits_uop_debugInfo_renameTime),
    .io_in_0_bits_uop_debugInfo_dispatchTime(io_in_0_bits_uop_debugInfo_dispatchTime),
    .io_in_0_bits_uop_debugInfo_enqRsTime(io_in_0_bits_uop_debugInfo_enqRsTime),
    .io_in_0_bits_uop_debugInfo_selectTime(io_in_0_bits_uop_debugInfo_selectTime),
    .io_in_0_bits_uop_debugInfo_issueTime(io_in_0_bits_uop_debugInfo_issueTime),
    .io_in_0_bits_uop_debugInfo_writebackTime(io_in_0_bits_uop_debugInfo_writebackTime),
    .io_in_0_bits_uop_debugInfo_runahead_checkpoint_id(io_in_0_bits_uop_debugInfo_runahead_checkpoint_id),
    .io_in_0_bits_uop_debugInfo_tlbFirstReqTime(io_in_0_bits_uop_debugInfo_tlbFirstReqTime),
    .io_in_0_bits_uop_debugInfo_tlbRespTime(io_in_0_bits_uop_debugInfo_tlbRespTime),
    .io_in_0_bits_uop_debug_seqNum_seqNum(io_in_0_bits_uop_debug_seqNum_seqNum),
    .io_in_0_bits_uop_debug_seqNum_uopIdx(io_in_0_bits_uop_debug_seqNum_uopIdx),
    .io_in_0_bits_src_4(io_in_0_bits_src_4),
    .io_in_1_valid(io_in_1_valid),
    .io_in_1_bits_uop_fuOpType(io_in_1_bits_uop_fuOpType),
    .io_in_1_bits_uop_vecWen(io_in_1_bits_uop_vecWen),
    .io_in_1_bits_uop_v0Wen(io_in_1_bits_uop_v0Wen),
    .io_in_1_bits_uop_vlWen(io_in_1_bits_uop_vlWen),
    .io_in_1_bits_uop_vpu_vill(io_in_1_bits_uop_vpu_vill),
    .io_in_1_bits_uop_vpu_vma(io_in_1_bits_uop_vpu_vma),
    .io_in_1_bits_uop_vpu_vta(io_in_1_bits_uop_vpu_vta),
    .io_in_1_bits_uop_vpu_vsew(io_in_1_bits_uop_vpu_vsew),
    .io_in_1_bits_uop_vpu_vlmul(io_in_1_bits_uop_vpu_vlmul),
    .io_in_1_bits_uop_vpu_specVill(io_in_1_bits_uop_vpu_specVill),
    .io_in_1_bits_uop_vpu_specVma(io_in_1_bits_uop_vpu_specVma),
    .io_in_1_bits_uop_vpu_specVta(io_in_1_bits_uop_vpu_specVta),
    .io_in_1_bits_uop_vpu_specVsew(io_in_1_bits_uop_vpu_specVsew),
    .io_in_1_bits_uop_vpu_specVlmul(io_in_1_bits_uop_vpu_specVlmul),
    .io_in_1_bits_uop_vpu_vm(io_in_1_bits_uop_vpu_vm),
    .io_in_1_bits_uop_vpu_vstart(io_in_1_bits_uop_vpu_vstart),
    .io_in_1_bits_uop_vpu_frm(io_in_1_bits_uop_vpu_frm),
    .io_in_1_bits_uop_vpu_fpu_isFpToVecInst(io_in_1_bits_uop_vpu_fpu_isFpToVecInst),
    .io_in_1_bits_uop_vpu_fpu_isFP32Instr(io_in_1_bits_uop_vpu_fpu_isFP32Instr),
    .io_in_1_bits_uop_vpu_fpu_isFP64Instr(io_in_1_bits_uop_vpu_fpu_isFP64Instr),
    .io_in_1_bits_uop_vpu_fpu_isReduction(io_in_1_bits_uop_vpu_fpu_isReduction),
    .io_in_1_bits_uop_vpu_fpu_isFoldTo1_2(io_in_1_bits_uop_vpu_fpu_isFoldTo1_2),
    .io_in_1_bits_uop_vpu_fpu_isFoldTo1_4(io_in_1_bits_uop_vpu_fpu_isFoldTo1_4),
    .io_in_1_bits_uop_vpu_fpu_isFoldTo1_8(io_in_1_bits_uop_vpu_fpu_isFoldTo1_8),
    .io_in_1_bits_uop_vpu_vxrm(io_in_1_bits_uop_vpu_vxrm),
    .io_in_1_bits_uop_vpu_vuopIdx(io_in_1_bits_uop_vpu_vuopIdx),
    .io_in_1_bits_uop_vpu_lastUop(io_in_1_bits_uop_vpu_lastUop),
    .io_in_1_bits_uop_vpu_nf(io_in_1_bits_uop_vpu_nf),
    .io_in_1_bits_uop_vpu_veew(io_in_1_bits_uop_vpu_veew),
    .io_in_1_bits_uop_vpu_isReverse(io_in_1_bits_uop_vpu_isReverse),
    .io_in_1_bits_uop_vpu_isExt(io_in_1_bits_uop_vpu_isExt),
    .io_in_1_bits_uop_vpu_isNarrow(io_in_1_bits_uop_vpu_isNarrow),
    .io_in_1_bits_uop_vpu_isDstMask(io_in_1_bits_uop_vpu_isDstMask),
    .io_in_1_bits_uop_vpu_isOpMask(io_in_1_bits_uop_vpu_isOpMask),
    .io_in_1_bits_uop_vpu_isMove(io_in_1_bits_uop_vpu_isMove),
    .io_in_1_bits_uop_vpu_isDependOldVd(io_in_1_bits_uop_vpu_isDependOldVd),
    .io_in_1_bits_uop_vpu_isWritePartVd(io_in_1_bits_uop_vpu_isWritePartVd),
    .io_in_1_bits_uop_vpu_isVleff(io_in_1_bits_uop_vpu_isVleff),
    .io_in_1_bits_uop_pdest(io_in_1_bits_uop_pdest),
    .io_in_1_bits_uop_robIdx_flag(io_in_1_bits_uop_robIdx_flag),
    .io_in_1_bits_uop_robIdx_value(io_in_1_bits_uop_robIdx_value),
    .io_in_1_bits_uop_debugInfo_eliminatedMove(io_in_1_bits_uop_debugInfo_eliminatedMove),
    .io_in_1_bits_uop_debugInfo_renameTime(io_in_1_bits_uop_debugInfo_renameTime),
    .io_in_1_bits_uop_debugInfo_dispatchTime(io_in_1_bits_uop_debugInfo_dispatchTime),
    .io_in_1_bits_uop_debugInfo_enqRsTime(io_in_1_bits_uop_debugInfo_enqRsTime),
    .io_in_1_bits_uop_debugInfo_selectTime(io_in_1_bits_uop_debugInfo_selectTime),
    .io_in_1_bits_uop_debugInfo_issueTime(io_in_1_bits_uop_debugInfo_issueTime),
    .io_in_1_bits_uop_debugInfo_writebackTime(io_in_1_bits_uop_debugInfo_writebackTime),
    .io_in_1_bits_uop_debugInfo_runahead_checkpoint_id(io_in_1_bits_uop_debugInfo_runahead_checkpoint_id),
    .io_in_1_bits_uop_debugInfo_tlbFirstReqTime(io_in_1_bits_uop_debugInfo_tlbFirstReqTime),
    .io_in_1_bits_uop_debugInfo_tlbRespTime(io_in_1_bits_uop_debugInfo_tlbRespTime),
    .io_in_1_bits_uop_debug_seqNum_seqNum(io_in_1_bits_uop_debug_seqNum_seqNum),
    .io_in_1_bits_uop_debug_seqNum_uopIdx(io_in_1_bits_uop_debug_seqNum_uopIdx),
    .io_in_1_bits_src_4(io_in_1_bits_src_4),
    .io_mergeUopWriteback_0_valid(io_mergeUopWriteback_0_valid),
    .io_mergeUopWriteback_0_bits_robidx_flag(io_mergeUopWriteback_0_bits_robidx_flag),
    .io_mergeUopWriteback_0_bits_robidx_value(io_mergeUopWriteback_0_bits_robidx_value),
    .io_mergeUopWriteback_0_bits_vl(io_mergeUopWriteback_0_bits_vl),
    .io_mergeUopWriteback_0_bits_exceptionVec_3(io_mergeUopWriteback_0_bits_exceptionVec_3),
    .io_mergeUopWriteback_0_bits_exceptionVec_4(io_mergeUopWriteback_0_bits_exceptionVec_4),
    .io_mergeUopWriteback_0_bits_exceptionVec_5(io_mergeUopWriteback_0_bits_exceptionVec_5),
    .io_mergeUopWriteback_0_bits_exceptionVec_13(io_mergeUopWriteback_0_bits_exceptionVec_13),
    .io_mergeUopWriteback_0_bits_exceptionVec_19(io_mergeUopWriteback_0_bits_exceptionVec_19),
    .io_mergeUopWriteback_0_bits_exceptionVec_21(io_mergeUopWriteback_0_bits_exceptionVec_21),
    .io_mergeUopWriteback_1_valid(io_mergeUopWriteback_1_valid),
    .io_mergeUopWriteback_1_bits_robidx_flag(io_mergeUopWriteback_1_bits_robidx_flag),
    .io_mergeUopWriteback_1_bits_robidx_value(io_mergeUopWriteback_1_bits_robidx_value),
    .io_mergeUopWriteback_1_bits_vl(io_mergeUopWriteback_1_bits_vl),
    .io_mergeUopWriteback_1_bits_exceptionVec_3(io_mergeUopWriteback_1_bits_exceptionVec_3),
    .io_mergeUopWriteback_1_bits_exceptionVec_4(io_mergeUopWriteback_1_bits_exceptionVec_4),
    .io_mergeUopWriteback_1_bits_exceptionVec_5(io_mergeUopWriteback_1_bits_exceptionVec_5),
    .io_mergeUopWriteback_1_bits_exceptionVec_13(io_mergeUopWriteback_1_bits_exceptionVec_13),
    .io_mergeUopWriteback_1_bits_exceptionVec_19(io_mergeUopWriteback_1_bits_exceptionVec_19),
    .io_mergeUopWriteback_1_bits_exceptionVec_21(io_mergeUopWriteback_1_bits_exceptionVec_21),
    .io_uopWriteback_ready(io_uopWriteback_ready),
    .io_uopWriteback_valid(g_io_uopWriteback_valid),
    .io_uopWriteback_bits_uop_fuOpType(g_io_uopWriteback_bits_uop_fuOpType),
    .io_uopWriteback_bits_uop_vecWen(g_io_uopWriteback_bits_uop_vecWen),
    .io_uopWriteback_bits_uop_v0Wen(g_io_uopWriteback_bits_uop_v0Wen),
    .io_uopWriteback_bits_uop_vlWen(g_io_uopWriteback_bits_uop_vlWen),
    .io_uopWriteback_bits_uop_vpu_vill(g_io_uopWriteback_bits_uop_vpu_vill),
    .io_uopWriteback_bits_uop_vpu_vma(g_io_uopWriteback_bits_uop_vpu_vma),
    .io_uopWriteback_bits_uop_vpu_vta(g_io_uopWriteback_bits_uop_vpu_vta),
    .io_uopWriteback_bits_uop_vpu_vsew(g_io_uopWriteback_bits_uop_vpu_vsew),
    .io_uopWriteback_bits_uop_vpu_vlmul(g_io_uopWriteback_bits_uop_vpu_vlmul),
    .io_uopWriteback_bits_uop_vpu_specVill(g_io_uopWriteback_bits_uop_vpu_specVill),
    .io_uopWriteback_bits_uop_vpu_specVma(g_io_uopWriteback_bits_uop_vpu_specVma),
    .io_uopWriteback_bits_uop_vpu_specVta(g_io_uopWriteback_bits_uop_vpu_specVta),
    .io_uopWriteback_bits_uop_vpu_specVsew(g_io_uopWriteback_bits_uop_vpu_specVsew),
    .io_uopWriteback_bits_uop_vpu_specVlmul(g_io_uopWriteback_bits_uop_vpu_specVlmul),
    .io_uopWriteback_bits_uop_vpu_vm(g_io_uopWriteback_bits_uop_vpu_vm),
    .io_uopWriteback_bits_uop_vpu_vstart(g_io_uopWriteback_bits_uop_vpu_vstart),
    .io_uopWriteback_bits_uop_vpu_frm(g_io_uopWriteback_bits_uop_vpu_frm),
    .io_uopWriteback_bits_uop_vpu_fpu_isFpToVecInst(g_io_uopWriteback_bits_uop_vpu_fpu_isFpToVecInst),
    .io_uopWriteback_bits_uop_vpu_fpu_isFP32Instr(g_io_uopWriteback_bits_uop_vpu_fpu_isFP32Instr),
    .io_uopWriteback_bits_uop_vpu_fpu_isFP64Instr(g_io_uopWriteback_bits_uop_vpu_fpu_isFP64Instr),
    .io_uopWriteback_bits_uop_vpu_fpu_isReduction(g_io_uopWriteback_bits_uop_vpu_fpu_isReduction),
    .io_uopWriteback_bits_uop_vpu_fpu_isFoldTo1_2(g_io_uopWriteback_bits_uop_vpu_fpu_isFoldTo1_2),
    .io_uopWriteback_bits_uop_vpu_fpu_isFoldTo1_4(g_io_uopWriteback_bits_uop_vpu_fpu_isFoldTo1_4),
    .io_uopWriteback_bits_uop_vpu_fpu_isFoldTo1_8(g_io_uopWriteback_bits_uop_vpu_fpu_isFoldTo1_8),
    .io_uopWriteback_bits_uop_vpu_vxrm(g_io_uopWriteback_bits_uop_vpu_vxrm),
    .io_uopWriteback_bits_uop_vpu_vuopIdx(g_io_uopWriteback_bits_uop_vpu_vuopIdx),
    .io_uopWriteback_bits_uop_vpu_lastUop(g_io_uopWriteback_bits_uop_vpu_lastUop),
    .io_uopWriteback_bits_uop_vpu_vl(g_io_uopWriteback_bits_uop_vpu_vl),
    .io_uopWriteback_bits_uop_vpu_nf(g_io_uopWriteback_bits_uop_vpu_nf),
    .io_uopWriteback_bits_uop_vpu_veew(g_io_uopWriteback_bits_uop_vpu_veew),
    .io_uopWriteback_bits_uop_vpu_isReverse(g_io_uopWriteback_bits_uop_vpu_isReverse),
    .io_uopWriteback_bits_uop_vpu_isExt(g_io_uopWriteback_bits_uop_vpu_isExt),
    .io_uopWriteback_bits_uop_vpu_isNarrow(g_io_uopWriteback_bits_uop_vpu_isNarrow),
    .io_uopWriteback_bits_uop_vpu_isDstMask(g_io_uopWriteback_bits_uop_vpu_isDstMask),
    .io_uopWriteback_bits_uop_vpu_isOpMask(g_io_uopWriteback_bits_uop_vpu_isOpMask),
    .io_uopWriteback_bits_uop_vpu_isMove(g_io_uopWriteback_bits_uop_vpu_isMove),
    .io_uopWriteback_bits_uop_vpu_isDependOldVd(g_io_uopWriteback_bits_uop_vpu_isDependOldVd),
    .io_uopWriteback_bits_uop_vpu_isWritePartVd(g_io_uopWriteback_bits_uop_vpu_isWritePartVd),
    .io_uopWriteback_bits_uop_vpu_isVleff(g_io_uopWriteback_bits_uop_vpu_isVleff),
    .io_uopWriteback_bits_uop_pdest(g_io_uopWriteback_bits_uop_pdest),
    .io_uopWriteback_bits_uop_robIdx_flag(g_io_uopWriteback_bits_uop_robIdx_flag),
    .io_uopWriteback_bits_uop_robIdx_value(g_io_uopWriteback_bits_uop_robIdx_value),
    .io_uopWriteback_bits_uop_debugInfo_eliminatedMove(g_io_uopWriteback_bits_uop_debugInfo_eliminatedMove),
    .io_uopWriteback_bits_uop_debugInfo_renameTime(g_io_uopWriteback_bits_uop_debugInfo_renameTime),
    .io_uopWriteback_bits_uop_debugInfo_dispatchTime(g_io_uopWriteback_bits_uop_debugInfo_dispatchTime),
    .io_uopWriteback_bits_uop_debugInfo_enqRsTime(g_io_uopWriteback_bits_uop_debugInfo_enqRsTime),
    .io_uopWriteback_bits_uop_debugInfo_selectTime(g_io_uopWriteback_bits_uop_debugInfo_selectTime),
    .io_uopWriteback_bits_uop_debugInfo_issueTime(g_io_uopWriteback_bits_uop_debugInfo_issueTime),
    .io_uopWriteback_bits_uop_debugInfo_writebackTime(g_io_uopWriteback_bits_uop_debugInfo_writebackTime),
    .io_uopWriteback_bits_uop_debugInfo_runahead_checkpoint_id(g_io_uopWriteback_bits_uop_debugInfo_runahead_checkpoint_id),
    .io_uopWriteback_bits_uop_debugInfo_tlbFirstReqTime(g_io_uopWriteback_bits_uop_debugInfo_tlbFirstReqTime),
    .io_uopWriteback_bits_uop_debugInfo_tlbRespTime(g_io_uopWriteback_bits_uop_debugInfo_tlbRespTime),
    .io_uopWriteback_bits_uop_debug_seqNum_seqNum(g_io_uopWriteback_bits_uop_debug_seqNum_seqNum),
    .io_uopWriteback_bits_uop_debug_seqNum_uopIdx(g_io_uopWriteback_bits_uop_debug_seqNum_uopIdx),
    .io_uopWriteback_bits_data(g_io_uopWriteback_bits_data)
  );
  VfofBuffer_xs u_i (
    .clock(clock),
    .reset(reset),
    .io_redirect_valid(io_redirect_valid),
    .io_redirect_bits_robIdx_flag(io_redirect_bits_robIdx_flag),
    .io_redirect_bits_robIdx_value(io_redirect_bits_robIdx_value),
    .io_redirect_bits_level(io_redirect_bits_level),
    .io_in_0_valid(io_in_0_valid),
    .io_in_0_bits_uop_fuOpType(io_in_0_bits_uop_fuOpType),
    .io_in_0_bits_uop_vecWen(io_in_0_bits_uop_vecWen),
    .io_in_0_bits_uop_v0Wen(io_in_0_bits_uop_v0Wen),
    .io_in_0_bits_uop_vlWen(io_in_0_bits_uop_vlWen),
    .io_in_0_bits_uop_vpu_vill(io_in_0_bits_uop_vpu_vill),
    .io_in_0_bits_uop_vpu_vma(io_in_0_bits_uop_vpu_vma),
    .io_in_0_bits_uop_vpu_vta(io_in_0_bits_uop_vpu_vta),
    .io_in_0_bits_uop_vpu_vsew(io_in_0_bits_uop_vpu_vsew),
    .io_in_0_bits_uop_vpu_vlmul(io_in_0_bits_uop_vpu_vlmul),
    .io_in_0_bits_uop_vpu_specVill(io_in_0_bits_uop_vpu_specVill),
    .io_in_0_bits_uop_vpu_specVma(io_in_0_bits_uop_vpu_specVma),
    .io_in_0_bits_uop_vpu_specVta(io_in_0_bits_uop_vpu_specVta),
    .io_in_0_bits_uop_vpu_specVsew(io_in_0_bits_uop_vpu_specVsew),
    .io_in_0_bits_uop_vpu_specVlmul(io_in_0_bits_uop_vpu_specVlmul),
    .io_in_0_bits_uop_vpu_vm(io_in_0_bits_uop_vpu_vm),
    .io_in_0_bits_uop_vpu_vstart(io_in_0_bits_uop_vpu_vstart),
    .io_in_0_bits_uop_vpu_frm(io_in_0_bits_uop_vpu_frm),
    .io_in_0_bits_uop_vpu_fpu_isFpToVecInst(io_in_0_bits_uop_vpu_fpu_isFpToVecInst),
    .io_in_0_bits_uop_vpu_fpu_isFP32Instr(io_in_0_bits_uop_vpu_fpu_isFP32Instr),
    .io_in_0_bits_uop_vpu_fpu_isFP64Instr(io_in_0_bits_uop_vpu_fpu_isFP64Instr),
    .io_in_0_bits_uop_vpu_fpu_isReduction(io_in_0_bits_uop_vpu_fpu_isReduction),
    .io_in_0_bits_uop_vpu_fpu_isFoldTo1_2(io_in_0_bits_uop_vpu_fpu_isFoldTo1_2),
    .io_in_0_bits_uop_vpu_fpu_isFoldTo1_4(io_in_0_bits_uop_vpu_fpu_isFoldTo1_4),
    .io_in_0_bits_uop_vpu_fpu_isFoldTo1_8(io_in_0_bits_uop_vpu_fpu_isFoldTo1_8),
    .io_in_0_bits_uop_vpu_vxrm(io_in_0_bits_uop_vpu_vxrm),
    .io_in_0_bits_uop_vpu_vuopIdx(io_in_0_bits_uop_vpu_vuopIdx),
    .io_in_0_bits_uop_vpu_lastUop(io_in_0_bits_uop_vpu_lastUop),
    .io_in_0_bits_uop_vpu_nf(io_in_0_bits_uop_vpu_nf),
    .io_in_0_bits_uop_vpu_veew(io_in_0_bits_uop_vpu_veew),
    .io_in_0_bits_uop_vpu_isReverse(io_in_0_bits_uop_vpu_isReverse),
    .io_in_0_bits_uop_vpu_isExt(io_in_0_bits_uop_vpu_isExt),
    .io_in_0_bits_uop_vpu_isNarrow(io_in_0_bits_uop_vpu_isNarrow),
    .io_in_0_bits_uop_vpu_isDstMask(io_in_0_bits_uop_vpu_isDstMask),
    .io_in_0_bits_uop_vpu_isOpMask(io_in_0_bits_uop_vpu_isOpMask),
    .io_in_0_bits_uop_vpu_isMove(io_in_0_bits_uop_vpu_isMove),
    .io_in_0_bits_uop_vpu_isDependOldVd(io_in_0_bits_uop_vpu_isDependOldVd),
    .io_in_0_bits_uop_vpu_isWritePartVd(io_in_0_bits_uop_vpu_isWritePartVd),
    .io_in_0_bits_uop_vpu_isVleff(io_in_0_bits_uop_vpu_isVleff),
    .io_in_0_bits_uop_pdest(io_in_0_bits_uop_pdest),
    .io_in_0_bits_uop_robIdx_flag(io_in_0_bits_uop_robIdx_flag),
    .io_in_0_bits_uop_robIdx_value(io_in_0_bits_uop_robIdx_value),
    .io_in_0_bits_uop_debugInfo_eliminatedMove(io_in_0_bits_uop_debugInfo_eliminatedMove),
    .io_in_0_bits_uop_debugInfo_renameTime(io_in_0_bits_uop_debugInfo_renameTime),
    .io_in_0_bits_uop_debugInfo_dispatchTime(io_in_0_bits_uop_debugInfo_dispatchTime),
    .io_in_0_bits_uop_debugInfo_enqRsTime(io_in_0_bits_uop_debugInfo_enqRsTime),
    .io_in_0_bits_uop_debugInfo_selectTime(io_in_0_bits_uop_debugInfo_selectTime),
    .io_in_0_bits_uop_debugInfo_issueTime(io_in_0_bits_uop_debugInfo_issueTime),
    .io_in_0_bits_uop_debugInfo_writebackTime(io_in_0_bits_uop_debugInfo_writebackTime),
    .io_in_0_bits_uop_debugInfo_runahead_checkpoint_id(io_in_0_bits_uop_debugInfo_runahead_checkpoint_id),
    .io_in_0_bits_uop_debugInfo_tlbFirstReqTime(io_in_0_bits_uop_debugInfo_tlbFirstReqTime),
    .io_in_0_bits_uop_debugInfo_tlbRespTime(io_in_0_bits_uop_debugInfo_tlbRespTime),
    .io_in_0_bits_uop_debug_seqNum_seqNum(io_in_0_bits_uop_debug_seqNum_seqNum),
    .io_in_0_bits_uop_debug_seqNum_uopIdx(io_in_0_bits_uop_debug_seqNum_uopIdx),
    .io_in_0_bits_src_4(io_in_0_bits_src_4),
    .io_in_1_valid(io_in_1_valid),
    .io_in_1_bits_uop_fuOpType(io_in_1_bits_uop_fuOpType),
    .io_in_1_bits_uop_vecWen(io_in_1_bits_uop_vecWen),
    .io_in_1_bits_uop_v0Wen(io_in_1_bits_uop_v0Wen),
    .io_in_1_bits_uop_vlWen(io_in_1_bits_uop_vlWen),
    .io_in_1_bits_uop_vpu_vill(io_in_1_bits_uop_vpu_vill),
    .io_in_1_bits_uop_vpu_vma(io_in_1_bits_uop_vpu_vma),
    .io_in_1_bits_uop_vpu_vta(io_in_1_bits_uop_vpu_vta),
    .io_in_1_bits_uop_vpu_vsew(io_in_1_bits_uop_vpu_vsew),
    .io_in_1_bits_uop_vpu_vlmul(io_in_1_bits_uop_vpu_vlmul),
    .io_in_1_bits_uop_vpu_specVill(io_in_1_bits_uop_vpu_specVill),
    .io_in_1_bits_uop_vpu_specVma(io_in_1_bits_uop_vpu_specVma),
    .io_in_1_bits_uop_vpu_specVta(io_in_1_bits_uop_vpu_specVta),
    .io_in_1_bits_uop_vpu_specVsew(io_in_1_bits_uop_vpu_specVsew),
    .io_in_1_bits_uop_vpu_specVlmul(io_in_1_bits_uop_vpu_specVlmul),
    .io_in_1_bits_uop_vpu_vm(io_in_1_bits_uop_vpu_vm),
    .io_in_1_bits_uop_vpu_vstart(io_in_1_bits_uop_vpu_vstart),
    .io_in_1_bits_uop_vpu_frm(io_in_1_bits_uop_vpu_frm),
    .io_in_1_bits_uop_vpu_fpu_isFpToVecInst(io_in_1_bits_uop_vpu_fpu_isFpToVecInst),
    .io_in_1_bits_uop_vpu_fpu_isFP32Instr(io_in_1_bits_uop_vpu_fpu_isFP32Instr),
    .io_in_1_bits_uop_vpu_fpu_isFP64Instr(io_in_1_bits_uop_vpu_fpu_isFP64Instr),
    .io_in_1_bits_uop_vpu_fpu_isReduction(io_in_1_bits_uop_vpu_fpu_isReduction),
    .io_in_1_bits_uop_vpu_fpu_isFoldTo1_2(io_in_1_bits_uop_vpu_fpu_isFoldTo1_2),
    .io_in_1_bits_uop_vpu_fpu_isFoldTo1_4(io_in_1_bits_uop_vpu_fpu_isFoldTo1_4),
    .io_in_1_bits_uop_vpu_fpu_isFoldTo1_8(io_in_1_bits_uop_vpu_fpu_isFoldTo1_8),
    .io_in_1_bits_uop_vpu_vxrm(io_in_1_bits_uop_vpu_vxrm),
    .io_in_1_bits_uop_vpu_vuopIdx(io_in_1_bits_uop_vpu_vuopIdx),
    .io_in_1_bits_uop_vpu_lastUop(io_in_1_bits_uop_vpu_lastUop),
    .io_in_1_bits_uop_vpu_nf(io_in_1_bits_uop_vpu_nf),
    .io_in_1_bits_uop_vpu_veew(io_in_1_bits_uop_vpu_veew),
    .io_in_1_bits_uop_vpu_isReverse(io_in_1_bits_uop_vpu_isReverse),
    .io_in_1_bits_uop_vpu_isExt(io_in_1_bits_uop_vpu_isExt),
    .io_in_1_bits_uop_vpu_isNarrow(io_in_1_bits_uop_vpu_isNarrow),
    .io_in_1_bits_uop_vpu_isDstMask(io_in_1_bits_uop_vpu_isDstMask),
    .io_in_1_bits_uop_vpu_isOpMask(io_in_1_bits_uop_vpu_isOpMask),
    .io_in_1_bits_uop_vpu_isMove(io_in_1_bits_uop_vpu_isMove),
    .io_in_1_bits_uop_vpu_isDependOldVd(io_in_1_bits_uop_vpu_isDependOldVd),
    .io_in_1_bits_uop_vpu_isWritePartVd(io_in_1_bits_uop_vpu_isWritePartVd),
    .io_in_1_bits_uop_vpu_isVleff(io_in_1_bits_uop_vpu_isVleff),
    .io_in_1_bits_uop_pdest(io_in_1_bits_uop_pdest),
    .io_in_1_bits_uop_robIdx_flag(io_in_1_bits_uop_robIdx_flag),
    .io_in_1_bits_uop_robIdx_value(io_in_1_bits_uop_robIdx_value),
    .io_in_1_bits_uop_debugInfo_eliminatedMove(io_in_1_bits_uop_debugInfo_eliminatedMove),
    .io_in_1_bits_uop_debugInfo_renameTime(io_in_1_bits_uop_debugInfo_renameTime),
    .io_in_1_bits_uop_debugInfo_dispatchTime(io_in_1_bits_uop_debugInfo_dispatchTime),
    .io_in_1_bits_uop_debugInfo_enqRsTime(io_in_1_bits_uop_debugInfo_enqRsTime),
    .io_in_1_bits_uop_debugInfo_selectTime(io_in_1_bits_uop_debugInfo_selectTime),
    .io_in_1_bits_uop_debugInfo_issueTime(io_in_1_bits_uop_debugInfo_issueTime),
    .io_in_1_bits_uop_debugInfo_writebackTime(io_in_1_bits_uop_debugInfo_writebackTime),
    .io_in_1_bits_uop_debugInfo_runahead_checkpoint_id(io_in_1_bits_uop_debugInfo_runahead_checkpoint_id),
    .io_in_1_bits_uop_debugInfo_tlbFirstReqTime(io_in_1_bits_uop_debugInfo_tlbFirstReqTime),
    .io_in_1_bits_uop_debugInfo_tlbRespTime(io_in_1_bits_uop_debugInfo_tlbRespTime),
    .io_in_1_bits_uop_debug_seqNum_seqNum(io_in_1_bits_uop_debug_seqNum_seqNum),
    .io_in_1_bits_uop_debug_seqNum_uopIdx(io_in_1_bits_uop_debug_seqNum_uopIdx),
    .io_in_1_bits_src_4(io_in_1_bits_src_4),
    .io_mergeUopWriteback_0_valid(io_mergeUopWriteback_0_valid),
    .io_mergeUopWriteback_0_bits_robidx_flag(io_mergeUopWriteback_0_bits_robidx_flag),
    .io_mergeUopWriteback_0_bits_robidx_value(io_mergeUopWriteback_0_bits_robidx_value),
    .io_mergeUopWriteback_0_bits_vl(io_mergeUopWriteback_0_bits_vl),
    .io_mergeUopWriteback_0_bits_exceptionVec_3(io_mergeUopWriteback_0_bits_exceptionVec_3),
    .io_mergeUopWriteback_0_bits_exceptionVec_4(io_mergeUopWriteback_0_bits_exceptionVec_4),
    .io_mergeUopWriteback_0_bits_exceptionVec_5(io_mergeUopWriteback_0_bits_exceptionVec_5),
    .io_mergeUopWriteback_0_bits_exceptionVec_13(io_mergeUopWriteback_0_bits_exceptionVec_13),
    .io_mergeUopWriteback_0_bits_exceptionVec_19(io_mergeUopWriteback_0_bits_exceptionVec_19),
    .io_mergeUopWriteback_0_bits_exceptionVec_21(io_mergeUopWriteback_0_bits_exceptionVec_21),
    .io_mergeUopWriteback_1_valid(io_mergeUopWriteback_1_valid),
    .io_mergeUopWriteback_1_bits_robidx_flag(io_mergeUopWriteback_1_bits_robidx_flag),
    .io_mergeUopWriteback_1_bits_robidx_value(io_mergeUopWriteback_1_bits_robidx_value),
    .io_mergeUopWriteback_1_bits_vl(io_mergeUopWriteback_1_bits_vl),
    .io_mergeUopWriteback_1_bits_exceptionVec_3(io_mergeUopWriteback_1_bits_exceptionVec_3),
    .io_mergeUopWriteback_1_bits_exceptionVec_4(io_mergeUopWriteback_1_bits_exceptionVec_4),
    .io_mergeUopWriteback_1_bits_exceptionVec_5(io_mergeUopWriteback_1_bits_exceptionVec_5),
    .io_mergeUopWriteback_1_bits_exceptionVec_13(io_mergeUopWriteback_1_bits_exceptionVec_13),
    .io_mergeUopWriteback_1_bits_exceptionVec_19(io_mergeUopWriteback_1_bits_exceptionVec_19),
    .io_mergeUopWriteback_1_bits_exceptionVec_21(io_mergeUopWriteback_1_bits_exceptionVec_21),
    .io_uopWriteback_ready(io_uopWriteback_ready),
    .io_uopWriteback_valid(i_io_uopWriteback_valid),
    .io_uopWriteback_bits_uop_fuOpType(i_io_uopWriteback_bits_uop_fuOpType),
    .io_uopWriteback_bits_uop_vecWen(i_io_uopWriteback_bits_uop_vecWen),
    .io_uopWriteback_bits_uop_v0Wen(i_io_uopWriteback_bits_uop_v0Wen),
    .io_uopWriteback_bits_uop_vlWen(i_io_uopWriteback_bits_uop_vlWen),
    .io_uopWriteback_bits_uop_vpu_vill(i_io_uopWriteback_bits_uop_vpu_vill),
    .io_uopWriteback_bits_uop_vpu_vma(i_io_uopWriteback_bits_uop_vpu_vma),
    .io_uopWriteback_bits_uop_vpu_vta(i_io_uopWriteback_bits_uop_vpu_vta),
    .io_uopWriteback_bits_uop_vpu_vsew(i_io_uopWriteback_bits_uop_vpu_vsew),
    .io_uopWriteback_bits_uop_vpu_vlmul(i_io_uopWriteback_bits_uop_vpu_vlmul),
    .io_uopWriteback_bits_uop_vpu_specVill(i_io_uopWriteback_bits_uop_vpu_specVill),
    .io_uopWriteback_bits_uop_vpu_specVma(i_io_uopWriteback_bits_uop_vpu_specVma),
    .io_uopWriteback_bits_uop_vpu_specVta(i_io_uopWriteback_bits_uop_vpu_specVta),
    .io_uopWriteback_bits_uop_vpu_specVsew(i_io_uopWriteback_bits_uop_vpu_specVsew),
    .io_uopWriteback_bits_uop_vpu_specVlmul(i_io_uopWriteback_bits_uop_vpu_specVlmul),
    .io_uopWriteback_bits_uop_vpu_vm(i_io_uopWriteback_bits_uop_vpu_vm),
    .io_uopWriteback_bits_uop_vpu_vstart(i_io_uopWriteback_bits_uop_vpu_vstart),
    .io_uopWriteback_bits_uop_vpu_frm(i_io_uopWriteback_bits_uop_vpu_frm),
    .io_uopWriteback_bits_uop_vpu_fpu_isFpToVecInst(i_io_uopWriteback_bits_uop_vpu_fpu_isFpToVecInst),
    .io_uopWriteback_bits_uop_vpu_fpu_isFP32Instr(i_io_uopWriteback_bits_uop_vpu_fpu_isFP32Instr),
    .io_uopWriteback_bits_uop_vpu_fpu_isFP64Instr(i_io_uopWriteback_bits_uop_vpu_fpu_isFP64Instr),
    .io_uopWriteback_bits_uop_vpu_fpu_isReduction(i_io_uopWriteback_bits_uop_vpu_fpu_isReduction),
    .io_uopWriteback_bits_uop_vpu_fpu_isFoldTo1_2(i_io_uopWriteback_bits_uop_vpu_fpu_isFoldTo1_2),
    .io_uopWriteback_bits_uop_vpu_fpu_isFoldTo1_4(i_io_uopWriteback_bits_uop_vpu_fpu_isFoldTo1_4),
    .io_uopWriteback_bits_uop_vpu_fpu_isFoldTo1_8(i_io_uopWriteback_bits_uop_vpu_fpu_isFoldTo1_8),
    .io_uopWriteback_bits_uop_vpu_vxrm(i_io_uopWriteback_bits_uop_vpu_vxrm),
    .io_uopWriteback_bits_uop_vpu_vuopIdx(i_io_uopWriteback_bits_uop_vpu_vuopIdx),
    .io_uopWriteback_bits_uop_vpu_lastUop(i_io_uopWriteback_bits_uop_vpu_lastUop),
    .io_uopWriteback_bits_uop_vpu_vl(i_io_uopWriteback_bits_uop_vpu_vl),
    .io_uopWriteback_bits_uop_vpu_nf(i_io_uopWriteback_bits_uop_vpu_nf),
    .io_uopWriteback_bits_uop_vpu_veew(i_io_uopWriteback_bits_uop_vpu_veew),
    .io_uopWriteback_bits_uop_vpu_isReverse(i_io_uopWriteback_bits_uop_vpu_isReverse),
    .io_uopWriteback_bits_uop_vpu_isExt(i_io_uopWriteback_bits_uop_vpu_isExt),
    .io_uopWriteback_bits_uop_vpu_isNarrow(i_io_uopWriteback_bits_uop_vpu_isNarrow),
    .io_uopWriteback_bits_uop_vpu_isDstMask(i_io_uopWriteback_bits_uop_vpu_isDstMask),
    .io_uopWriteback_bits_uop_vpu_isOpMask(i_io_uopWriteback_bits_uop_vpu_isOpMask),
    .io_uopWriteback_bits_uop_vpu_isMove(i_io_uopWriteback_bits_uop_vpu_isMove),
    .io_uopWriteback_bits_uop_vpu_isDependOldVd(i_io_uopWriteback_bits_uop_vpu_isDependOldVd),
    .io_uopWriteback_bits_uop_vpu_isWritePartVd(i_io_uopWriteback_bits_uop_vpu_isWritePartVd),
    .io_uopWriteback_bits_uop_vpu_isVleff(i_io_uopWriteback_bits_uop_vpu_isVleff),
    .io_uopWriteback_bits_uop_pdest(i_io_uopWriteback_bits_uop_pdest),
    .io_uopWriteback_bits_uop_robIdx_flag(i_io_uopWriteback_bits_uop_robIdx_flag),
    .io_uopWriteback_bits_uop_robIdx_value(i_io_uopWriteback_bits_uop_robIdx_value),
    .io_uopWriteback_bits_uop_debugInfo_eliminatedMove(i_io_uopWriteback_bits_uop_debugInfo_eliminatedMove),
    .io_uopWriteback_bits_uop_debugInfo_renameTime(i_io_uopWriteback_bits_uop_debugInfo_renameTime),
    .io_uopWriteback_bits_uop_debugInfo_dispatchTime(i_io_uopWriteback_bits_uop_debugInfo_dispatchTime),
    .io_uopWriteback_bits_uop_debugInfo_enqRsTime(i_io_uopWriteback_bits_uop_debugInfo_enqRsTime),
    .io_uopWriteback_bits_uop_debugInfo_selectTime(i_io_uopWriteback_bits_uop_debugInfo_selectTime),
    .io_uopWriteback_bits_uop_debugInfo_issueTime(i_io_uopWriteback_bits_uop_debugInfo_issueTime),
    .io_uopWriteback_bits_uop_debugInfo_writebackTime(i_io_uopWriteback_bits_uop_debugInfo_writebackTime),
    .io_uopWriteback_bits_uop_debugInfo_runahead_checkpoint_id(i_io_uopWriteback_bits_uop_debugInfo_runahead_checkpoint_id),
    .io_uopWriteback_bits_uop_debugInfo_tlbFirstReqTime(i_io_uopWriteback_bits_uop_debugInfo_tlbFirstReqTime),
    .io_uopWriteback_bits_uop_debugInfo_tlbRespTime(i_io_uopWriteback_bits_uop_debugInfo_tlbRespTime),
    .io_uopWriteback_bits_uop_debug_seqNum_seqNum(i_io_uopWriteback_bits_uop_debug_seqNum_seqNum),
    .io_uopWriteback_bits_uop_debug_seqNum_uopIdx(i_io_uopWriteback_bits_uop_debug_seqNum_uopIdx),
    .io_uopWriteback_bits_data(i_io_uopWriteback_bits_data)
  );
  localparam int N_OUT = 56;
  bit seen0 [N_OUT];  // 该输出出现过"某位为 0"
  bit seen1 [N_OUT];  // 该输出出现过"某位为 1"
  `define CMP(k, g, i, nm) \
    begin checks++; if ((g) !== (i)) begin errors++; \
      if (errors <= 30) $display("[%0d] MISMATCH %s golden=%h impl=%h", cyc, nm, (g), (i)); end \
      if (|(g)) seen1[k] = 1; if (!(&(g))) seen0[k] = 1; end
  task automatic compare_all();
    `CMP(0, g_io_uopWriteback_valid, i_io_uopWriteback_valid, "io_uopWriteback_valid")
    `CMP(1, g_io_uopWriteback_bits_uop_fuOpType, i_io_uopWriteback_bits_uop_fuOpType, "io_uopWriteback_bits_uop_fuOpType")
    `CMP(2, g_io_uopWriteback_bits_uop_vecWen, i_io_uopWriteback_bits_uop_vecWen, "io_uopWriteback_bits_uop_vecWen")
    `CMP(3, g_io_uopWriteback_bits_uop_v0Wen, i_io_uopWriteback_bits_uop_v0Wen, "io_uopWriteback_bits_uop_v0Wen")
    `CMP(4, g_io_uopWriteback_bits_uop_vlWen, i_io_uopWriteback_bits_uop_vlWen, "io_uopWriteback_bits_uop_vlWen")
    `CMP(5, g_io_uopWriteback_bits_uop_vpu_vill, i_io_uopWriteback_bits_uop_vpu_vill, "io_uopWriteback_bits_uop_vpu_vill")
    `CMP(6, g_io_uopWriteback_bits_uop_vpu_vma, i_io_uopWriteback_bits_uop_vpu_vma, "io_uopWriteback_bits_uop_vpu_vma")
    `CMP(7, g_io_uopWriteback_bits_uop_vpu_vta, i_io_uopWriteback_bits_uop_vpu_vta, "io_uopWriteback_bits_uop_vpu_vta")
    `CMP(8, g_io_uopWriteback_bits_uop_vpu_vsew, i_io_uopWriteback_bits_uop_vpu_vsew, "io_uopWriteback_bits_uop_vpu_vsew")
    `CMP(9, g_io_uopWriteback_bits_uop_vpu_vlmul, i_io_uopWriteback_bits_uop_vpu_vlmul, "io_uopWriteback_bits_uop_vpu_vlmul")
    `CMP(10, g_io_uopWriteback_bits_uop_vpu_specVill, i_io_uopWriteback_bits_uop_vpu_specVill, "io_uopWriteback_bits_uop_vpu_specVill")
    `CMP(11, g_io_uopWriteback_bits_uop_vpu_specVma, i_io_uopWriteback_bits_uop_vpu_specVma, "io_uopWriteback_bits_uop_vpu_specVma")
    `CMP(12, g_io_uopWriteback_bits_uop_vpu_specVta, i_io_uopWriteback_bits_uop_vpu_specVta, "io_uopWriteback_bits_uop_vpu_specVta")
    `CMP(13, g_io_uopWriteback_bits_uop_vpu_specVsew, i_io_uopWriteback_bits_uop_vpu_specVsew, "io_uopWriteback_bits_uop_vpu_specVsew")
    `CMP(14, g_io_uopWriteback_bits_uop_vpu_specVlmul, i_io_uopWriteback_bits_uop_vpu_specVlmul, "io_uopWriteback_bits_uop_vpu_specVlmul")
    `CMP(15, g_io_uopWriteback_bits_uop_vpu_vm, i_io_uopWriteback_bits_uop_vpu_vm, "io_uopWriteback_bits_uop_vpu_vm")
    `CMP(16, g_io_uopWriteback_bits_uop_vpu_vstart, i_io_uopWriteback_bits_uop_vpu_vstart, "io_uopWriteback_bits_uop_vpu_vstart")
    `CMP(17, g_io_uopWriteback_bits_uop_vpu_frm, i_io_uopWriteback_bits_uop_vpu_frm, "io_uopWriteback_bits_uop_vpu_frm")
    `CMP(18, g_io_uopWriteback_bits_uop_vpu_fpu_isFpToVecInst, i_io_uopWriteback_bits_uop_vpu_fpu_isFpToVecInst, "io_uopWriteback_bits_uop_vpu_fpu_isFpToVecInst")
    `CMP(19, g_io_uopWriteback_bits_uop_vpu_fpu_isFP32Instr, i_io_uopWriteback_bits_uop_vpu_fpu_isFP32Instr, "io_uopWriteback_bits_uop_vpu_fpu_isFP32Instr")
    `CMP(20, g_io_uopWriteback_bits_uop_vpu_fpu_isFP64Instr, i_io_uopWriteback_bits_uop_vpu_fpu_isFP64Instr, "io_uopWriteback_bits_uop_vpu_fpu_isFP64Instr")
    `CMP(21, g_io_uopWriteback_bits_uop_vpu_fpu_isReduction, i_io_uopWriteback_bits_uop_vpu_fpu_isReduction, "io_uopWriteback_bits_uop_vpu_fpu_isReduction")
    `CMP(22, g_io_uopWriteback_bits_uop_vpu_fpu_isFoldTo1_2, i_io_uopWriteback_bits_uop_vpu_fpu_isFoldTo1_2, "io_uopWriteback_bits_uop_vpu_fpu_isFoldTo1_2")
    `CMP(23, g_io_uopWriteback_bits_uop_vpu_fpu_isFoldTo1_4, i_io_uopWriteback_bits_uop_vpu_fpu_isFoldTo1_4, "io_uopWriteback_bits_uop_vpu_fpu_isFoldTo1_4")
    `CMP(24, g_io_uopWriteback_bits_uop_vpu_fpu_isFoldTo1_8, i_io_uopWriteback_bits_uop_vpu_fpu_isFoldTo1_8, "io_uopWriteback_bits_uop_vpu_fpu_isFoldTo1_8")
    `CMP(25, g_io_uopWriteback_bits_uop_vpu_vxrm, i_io_uopWriteback_bits_uop_vpu_vxrm, "io_uopWriteback_bits_uop_vpu_vxrm")
    `CMP(26, g_io_uopWriteback_bits_uop_vpu_vuopIdx, i_io_uopWriteback_bits_uop_vpu_vuopIdx, "io_uopWriteback_bits_uop_vpu_vuopIdx")
    `CMP(27, g_io_uopWriteback_bits_uop_vpu_lastUop, i_io_uopWriteback_bits_uop_vpu_lastUop, "io_uopWriteback_bits_uop_vpu_lastUop")
    `CMP(28, g_io_uopWriteback_bits_uop_vpu_vl, i_io_uopWriteback_bits_uop_vpu_vl, "io_uopWriteback_bits_uop_vpu_vl")
    `CMP(29, g_io_uopWriteback_bits_uop_vpu_nf, i_io_uopWriteback_bits_uop_vpu_nf, "io_uopWriteback_bits_uop_vpu_nf")
    `CMP(30, g_io_uopWriteback_bits_uop_vpu_veew, i_io_uopWriteback_bits_uop_vpu_veew, "io_uopWriteback_bits_uop_vpu_veew")
    `CMP(31, g_io_uopWriteback_bits_uop_vpu_isReverse, i_io_uopWriteback_bits_uop_vpu_isReverse, "io_uopWriteback_bits_uop_vpu_isReverse")
    `CMP(32, g_io_uopWriteback_bits_uop_vpu_isExt, i_io_uopWriteback_bits_uop_vpu_isExt, "io_uopWriteback_bits_uop_vpu_isExt")
    `CMP(33, g_io_uopWriteback_bits_uop_vpu_isNarrow, i_io_uopWriteback_bits_uop_vpu_isNarrow, "io_uopWriteback_bits_uop_vpu_isNarrow")
    `CMP(34, g_io_uopWriteback_bits_uop_vpu_isDstMask, i_io_uopWriteback_bits_uop_vpu_isDstMask, "io_uopWriteback_bits_uop_vpu_isDstMask")
    `CMP(35, g_io_uopWriteback_bits_uop_vpu_isOpMask, i_io_uopWriteback_bits_uop_vpu_isOpMask, "io_uopWriteback_bits_uop_vpu_isOpMask")
    `CMP(36, g_io_uopWriteback_bits_uop_vpu_isMove, i_io_uopWriteback_bits_uop_vpu_isMove, "io_uopWriteback_bits_uop_vpu_isMove")
    `CMP(37, g_io_uopWriteback_bits_uop_vpu_isDependOldVd, i_io_uopWriteback_bits_uop_vpu_isDependOldVd, "io_uopWriteback_bits_uop_vpu_isDependOldVd")
    `CMP(38, g_io_uopWriteback_bits_uop_vpu_isWritePartVd, i_io_uopWriteback_bits_uop_vpu_isWritePartVd, "io_uopWriteback_bits_uop_vpu_isWritePartVd")
    `CMP(39, g_io_uopWriteback_bits_uop_vpu_isVleff, i_io_uopWriteback_bits_uop_vpu_isVleff, "io_uopWriteback_bits_uop_vpu_isVleff")
    `CMP(40, g_io_uopWriteback_bits_uop_pdest, i_io_uopWriteback_bits_uop_pdest, "io_uopWriteback_bits_uop_pdest")
    `CMP(41, g_io_uopWriteback_bits_uop_robIdx_flag, i_io_uopWriteback_bits_uop_robIdx_flag, "io_uopWriteback_bits_uop_robIdx_flag")
    `CMP(42, g_io_uopWriteback_bits_uop_robIdx_value, i_io_uopWriteback_bits_uop_robIdx_value, "io_uopWriteback_bits_uop_robIdx_value")
    `CMP(43, g_io_uopWriteback_bits_uop_debugInfo_eliminatedMove, i_io_uopWriteback_bits_uop_debugInfo_eliminatedMove, "io_uopWriteback_bits_uop_debugInfo_eliminatedMove")
    `CMP(44, g_io_uopWriteback_bits_uop_debugInfo_renameTime, i_io_uopWriteback_bits_uop_debugInfo_renameTime, "io_uopWriteback_bits_uop_debugInfo_renameTime")
    `CMP(45, g_io_uopWriteback_bits_uop_debugInfo_dispatchTime, i_io_uopWriteback_bits_uop_debugInfo_dispatchTime, "io_uopWriteback_bits_uop_debugInfo_dispatchTime")
    `CMP(46, g_io_uopWriteback_bits_uop_debugInfo_enqRsTime, i_io_uopWriteback_bits_uop_debugInfo_enqRsTime, "io_uopWriteback_bits_uop_debugInfo_enqRsTime")
    `CMP(47, g_io_uopWriteback_bits_uop_debugInfo_selectTime, i_io_uopWriteback_bits_uop_debugInfo_selectTime, "io_uopWriteback_bits_uop_debugInfo_selectTime")
    `CMP(48, g_io_uopWriteback_bits_uop_debugInfo_issueTime, i_io_uopWriteback_bits_uop_debugInfo_issueTime, "io_uopWriteback_bits_uop_debugInfo_issueTime")
    `CMP(49, g_io_uopWriteback_bits_uop_debugInfo_writebackTime, i_io_uopWriteback_bits_uop_debugInfo_writebackTime, "io_uopWriteback_bits_uop_debugInfo_writebackTime")
    `CMP(50, g_io_uopWriteback_bits_uop_debugInfo_runahead_checkpoint_id, i_io_uopWriteback_bits_uop_debugInfo_runahead_checkpoint_id, "io_uopWriteback_bits_uop_debugInfo_runahead_checkpoint_id")
    `CMP(51, g_io_uopWriteback_bits_uop_debugInfo_tlbFirstReqTime, i_io_uopWriteback_bits_uop_debugInfo_tlbFirstReqTime, "io_uopWriteback_bits_uop_debugInfo_tlbFirstReqTime")
    `CMP(52, g_io_uopWriteback_bits_uop_debugInfo_tlbRespTime, i_io_uopWriteback_bits_uop_debugInfo_tlbRespTime, "io_uopWriteback_bits_uop_debugInfo_tlbRespTime")
    `CMP(53, g_io_uopWriteback_bits_uop_debug_seqNum_seqNum, i_io_uopWriteback_bits_uop_debug_seqNum_seqNum, "io_uopWriteback_bits_uop_debug_seqNum_seqNum")
    `CMP(54, g_io_uopWriteback_bits_uop_debug_seqNum_uopIdx, i_io_uopWriteback_bits_uop_debug_seqNum_uopIdx, "io_uopWriteback_bits_uop_debug_seqNum_uopIdx")
    `CMP(55, g_io_uopWriteback_bits_data, i_io_uopWriteback_bits_data, "io_uopWriteback_bits_data")
  endtask
  task automatic rand_inputs();
    io_redirect_valid = 1'($urandom);
    io_redirect_bits_robIdx_flag = 1'($urandom);
    io_redirect_bits_robIdx_value = 8'($urandom);
    io_redirect_bits_level = 1'($urandom);
    io_in_0_valid = 1'($urandom);
    io_in_0_bits_uop_fuOpType = 9'($urandom);
    io_in_0_bits_uop_vecWen = 1'($urandom);
    io_in_0_bits_uop_v0Wen = 1'($urandom);
    io_in_0_bits_uop_vlWen = 1'($urandom);
    io_in_0_bits_uop_vpu_vill = 1'($urandom);
    io_in_0_bits_uop_vpu_vma = 1'($urandom);
    io_in_0_bits_uop_vpu_vta = 1'($urandom);
    io_in_0_bits_uop_vpu_vsew = 2'($urandom);
    io_in_0_bits_uop_vpu_vlmul = 3'($urandom);
    io_in_0_bits_uop_vpu_specVill = 1'($urandom);
    io_in_0_bits_uop_vpu_specVma = 1'($urandom);
    io_in_0_bits_uop_vpu_specVta = 1'($urandom);
    io_in_0_bits_uop_vpu_specVsew = 2'($urandom);
    io_in_0_bits_uop_vpu_specVlmul = 3'($urandom);
    io_in_0_bits_uop_vpu_vm = 1'($urandom);
    io_in_0_bits_uop_vpu_vstart = 8'($urandom);
    io_in_0_bits_uop_vpu_frm = 3'($urandom);
    io_in_0_bits_uop_vpu_fpu_isFpToVecInst = 1'($urandom);
    io_in_0_bits_uop_vpu_fpu_isFP32Instr = 1'($urandom);
    io_in_0_bits_uop_vpu_fpu_isFP64Instr = 1'($urandom);
    io_in_0_bits_uop_vpu_fpu_isReduction = 1'($urandom);
    io_in_0_bits_uop_vpu_fpu_isFoldTo1_2 = 1'($urandom);
    io_in_0_bits_uop_vpu_fpu_isFoldTo1_4 = 1'($urandom);
    io_in_0_bits_uop_vpu_fpu_isFoldTo1_8 = 1'($urandom);
    io_in_0_bits_uop_vpu_vxrm = 2'($urandom);
    io_in_0_bits_uop_vpu_vuopIdx = 7'($urandom);
    io_in_0_bits_uop_vpu_lastUop = 1'($urandom);
    io_in_0_bits_uop_vpu_nf = 3'($urandom);
    io_in_0_bits_uop_vpu_veew = 2'($urandom);
    io_in_0_bits_uop_vpu_isReverse = 1'($urandom);
    io_in_0_bits_uop_vpu_isExt = 1'($urandom);
    io_in_0_bits_uop_vpu_isNarrow = 1'($urandom);
    io_in_0_bits_uop_vpu_isDstMask = 1'($urandom);
    io_in_0_bits_uop_vpu_isOpMask = 1'($urandom);
    io_in_0_bits_uop_vpu_isMove = 1'($urandom);
    io_in_0_bits_uop_vpu_isDependOldVd = 1'($urandom);
    io_in_0_bits_uop_vpu_isWritePartVd = 1'($urandom);
    io_in_0_bits_uop_vpu_isVleff = 1'($urandom);
    io_in_0_bits_uop_pdest = 8'($urandom);
    io_in_0_bits_uop_robIdx_flag = 1'($urandom);
    io_in_0_bits_uop_robIdx_value = 8'($urandom);
    io_in_0_bits_uop_debugInfo_eliminatedMove = 1'($urandom);
    io_in_0_bits_uop_debugInfo_renameTime = 64'({$urandom, $urandom});
    io_in_0_bits_uop_debugInfo_dispatchTime = 64'({$urandom, $urandom});
    io_in_0_bits_uop_debugInfo_enqRsTime = 64'({$urandom, $urandom});
    io_in_0_bits_uop_debugInfo_selectTime = 64'({$urandom, $urandom});
    io_in_0_bits_uop_debugInfo_issueTime = 64'({$urandom, $urandom});
    io_in_0_bits_uop_debugInfo_writebackTime = 64'({$urandom, $urandom});
    io_in_0_bits_uop_debugInfo_runahead_checkpoint_id = 64'({$urandom, $urandom});
    io_in_0_bits_uop_debugInfo_tlbFirstReqTime = 64'({$urandom, $urandom});
    io_in_0_bits_uop_debugInfo_tlbRespTime = 64'({$urandom, $urandom});
    io_in_0_bits_uop_debug_seqNum_seqNum = 56'({$urandom, $urandom});
    io_in_0_bits_uop_debug_seqNum_uopIdx = 8'($urandom);
    io_in_0_bits_src_4 = 128'({$urandom, $urandom, $urandom, $urandom});
    io_in_1_valid = 1'($urandom);
    io_in_1_bits_uop_fuOpType = 9'($urandom);
    io_in_1_bits_uop_vecWen = 1'($urandom);
    io_in_1_bits_uop_v0Wen = 1'($urandom);
    io_in_1_bits_uop_vlWen = 1'($urandom);
    io_in_1_bits_uop_vpu_vill = 1'($urandom);
    io_in_1_bits_uop_vpu_vma = 1'($urandom);
    io_in_1_bits_uop_vpu_vta = 1'($urandom);
    io_in_1_bits_uop_vpu_vsew = 2'($urandom);
    io_in_1_bits_uop_vpu_vlmul = 3'($urandom);
    io_in_1_bits_uop_vpu_specVill = 1'($urandom);
    io_in_1_bits_uop_vpu_specVma = 1'($urandom);
    io_in_1_bits_uop_vpu_specVta = 1'($urandom);
    io_in_1_bits_uop_vpu_specVsew = 2'($urandom);
    io_in_1_bits_uop_vpu_specVlmul = 3'($urandom);
    io_in_1_bits_uop_vpu_vm = 1'($urandom);
    io_in_1_bits_uop_vpu_vstart = 8'($urandom);
    io_in_1_bits_uop_vpu_frm = 3'($urandom);
    io_in_1_bits_uop_vpu_fpu_isFpToVecInst = 1'($urandom);
    io_in_1_bits_uop_vpu_fpu_isFP32Instr = 1'($urandom);
    io_in_1_bits_uop_vpu_fpu_isFP64Instr = 1'($urandom);
    io_in_1_bits_uop_vpu_fpu_isReduction = 1'($urandom);
    io_in_1_bits_uop_vpu_fpu_isFoldTo1_2 = 1'($urandom);
    io_in_1_bits_uop_vpu_fpu_isFoldTo1_4 = 1'($urandom);
    io_in_1_bits_uop_vpu_fpu_isFoldTo1_8 = 1'($urandom);
    io_in_1_bits_uop_vpu_vxrm = 2'($urandom);
    io_in_1_bits_uop_vpu_vuopIdx = 7'($urandom);
    io_in_1_bits_uop_vpu_lastUop = 1'($urandom);
    io_in_1_bits_uop_vpu_nf = 3'($urandom);
    io_in_1_bits_uop_vpu_veew = 2'($urandom);
    io_in_1_bits_uop_vpu_isReverse = 1'($urandom);
    io_in_1_bits_uop_vpu_isExt = 1'($urandom);
    io_in_1_bits_uop_vpu_isNarrow = 1'($urandom);
    io_in_1_bits_uop_vpu_isDstMask = 1'($urandom);
    io_in_1_bits_uop_vpu_isOpMask = 1'($urandom);
    io_in_1_bits_uop_vpu_isMove = 1'($urandom);
    io_in_1_bits_uop_vpu_isDependOldVd = 1'($urandom);
    io_in_1_bits_uop_vpu_isWritePartVd = 1'($urandom);
    io_in_1_bits_uop_vpu_isVleff = 1'($urandom);
    io_in_1_bits_uop_pdest = 8'($urandom);
    io_in_1_bits_uop_robIdx_flag = 1'($urandom);
    io_in_1_bits_uop_robIdx_value = 8'($urandom);
    io_in_1_bits_uop_debugInfo_eliminatedMove = 1'($urandom);
    io_in_1_bits_uop_debugInfo_renameTime = 64'({$urandom, $urandom});
    io_in_1_bits_uop_debugInfo_dispatchTime = 64'({$urandom, $urandom});
    io_in_1_bits_uop_debugInfo_enqRsTime = 64'({$urandom, $urandom});
    io_in_1_bits_uop_debugInfo_selectTime = 64'({$urandom, $urandom});
    io_in_1_bits_uop_debugInfo_issueTime = 64'({$urandom, $urandom});
    io_in_1_bits_uop_debugInfo_writebackTime = 64'({$urandom, $urandom});
    io_in_1_bits_uop_debugInfo_runahead_checkpoint_id = 64'({$urandom, $urandom});
    io_in_1_bits_uop_debugInfo_tlbFirstReqTime = 64'({$urandom, $urandom});
    io_in_1_bits_uop_debugInfo_tlbRespTime = 64'({$urandom, $urandom});
    io_in_1_bits_uop_debug_seqNum_seqNum = 56'({$urandom, $urandom});
    io_in_1_bits_uop_debug_seqNum_uopIdx = 8'($urandom);
    io_in_1_bits_src_4 = 128'({$urandom, $urandom, $urandom, $urandom});
    io_mergeUopWriteback_0_valid = 1'($urandom);
    io_mergeUopWriteback_0_bits_robidx_flag = 1'($urandom);
    io_mergeUopWriteback_0_bits_robidx_value = 8'($urandom);
    io_mergeUopWriteback_0_bits_vl = 8'($urandom);
    io_mergeUopWriteback_0_bits_exceptionVec_3 = 1'($urandom);
    io_mergeUopWriteback_0_bits_exceptionVec_4 = 1'($urandom);
    io_mergeUopWriteback_0_bits_exceptionVec_5 = 1'($urandom);
    io_mergeUopWriteback_0_bits_exceptionVec_13 = 1'($urandom);
    io_mergeUopWriteback_0_bits_exceptionVec_19 = 1'($urandom);
    io_mergeUopWriteback_0_bits_exceptionVec_21 = 1'($urandom);
    io_mergeUopWriteback_1_valid = 1'($urandom);
    io_mergeUopWriteback_1_bits_robidx_flag = 1'($urandom);
    io_mergeUopWriteback_1_bits_robidx_value = 8'($urandom);
    io_mergeUopWriteback_1_bits_vl = 8'($urandom);
    io_mergeUopWriteback_1_bits_exceptionVec_3 = 1'($urandom);
    io_mergeUopWriteback_1_bits_exceptionVec_4 = 1'($urandom);
    io_mergeUopWriteback_1_bits_exceptionVec_5 = 1'($urandom);
    io_mergeUopWriteback_1_bits_exceptionVec_13 = 1'($urandom);
    io_mergeUopWriteback_1_bits_exceptionVec_19 = 1'($urandom);
    io_mergeUopWriteback_1_bits_exceptionVec_21 = 1'($urandom);
    io_uopWriteback_ready = 1'($urandom);
  endtask

  int cov_fire, cov_both_hit, cov_wb_update, cov_wb_exc, cov_redirect_kill, cov_refresh, cov_enq_cancel;
  logic [8:0] pool [4];

  always #5 clock = ~clock;

  function automatic logic [8:0] pick_rob();
    return pool[$urandom_range(0, 3)];
  endfunction

  task automatic drive();
    logic [8:0] r;
    rand_inputs();
    // 入队口
    io_in_0_valid = ($urandom_range(0, 2) == 0);
    io_in_1_valid = ($urandom_range(0, 2) == 0);
    io_in_0_bits_uop_vpu_isVleff = ($urandom_range(0, 3) != 0);
    io_in_1_bits_uop_vpu_isVleff = ($urandom_range(0, 3) != 0);
    io_in_0_bits_uop_vpu_lastUop = ($urandom_range(0, 3) == 0);
    io_in_1_bits_uop_vpu_lastUop = ($urandom_range(0, 3) == 0);
    r = pick_rob(); {io_in_0_bits_uop_robIdx_flag, io_in_0_bits_uop_robIdx_value} = r;
    r = pick_rob(); {io_in_1_bits_uop_robIdx_flag, io_in_1_bits_uop_robIdx_value} = r;
    // 写回口
    io_mergeUopWriteback_0_valid = $urandom_range(0, 1);
    io_mergeUopWriteback_1_valid = $urandom_range(0, 1);
    r = pick_rob(); {io_mergeUopWriteback_0_bits_robidx_flag, io_mergeUopWriteback_0_bits_robidx_value} = r;
    r = pick_rob(); {io_mergeUopWriteback_1_bits_robidx_flag, io_mergeUopWriteback_1_bits_robidx_value} = r;
    io_mergeUopWriteback_0_bits_vl = 8'($urandom_range(0, 40));
    io_mergeUopWriteback_1_bits_vl = 8'($urandom_range(0, 40));
    {io_mergeUopWriteback_0_bits_exceptionVec_3, io_mergeUopWriteback_0_bits_exceptionVec_4,
     io_mergeUopWriteback_0_bits_exceptionVec_5, io_mergeUopWriteback_0_bits_exceptionVec_13,
     io_mergeUopWriteback_0_bits_exceptionVec_19, io_mergeUopWriteback_0_bits_exceptionVec_21}
      = 6'($urandom) & 6'($urandom) & 6'($urandom) & 6'($urandom);
    {io_mergeUopWriteback_1_bits_exceptionVec_3, io_mergeUopWriteback_1_bits_exceptionVec_4,
     io_mergeUopWriteback_1_bits_exceptionVec_5, io_mergeUopWriteback_1_bits_exceptionVec_13,
     io_mergeUopWriteback_1_bits_exceptionVec_19, io_mergeUopWriteback_1_bits_exceptionVec_21}
      = 6'($urandom) & 6'($urandom) & 6'($urandom) & 6'($urandom);
    // redirect / 出队握手
    io_redirect_valid = ($urandom_range(0, 23) == 0);
    r = pick_rob(); {io_redirect_bits_robIdx_flag, io_redirect_bits_robIdx_value} = r;
    io_uopWriteback_ready = ($urandom_range(0, 3) != 0);
  endtask

  initial begin
    int bad;
    if (!$value$plusargs("ncycles=%d", NCYCLES)) NCYCLES = 200000;
    clock = 0; reset = 1;
    pool = '{9'h005, 9'h0a3, 9'h105, 9'h1f0};
    cov_fire = 0; cov_both_hit = 0; cov_wb_update = 0; cov_wb_exc = 0;
    cov_redirect_kill = 0; cov_refresh = 0; cov_enq_cancel = 0;
    drive();
    repeat (3) @(posedge clock);
    #1 reset = 0;
    for (cyc = 0; cyc < NCYCLES; cyc++) begin
      // 每 50k 拍换一次池子，让 flag/value 的组合不止一套
      if (cyc % 50000 == 49999)
        pool = '{9'($urandom), 9'($urandom), 9'($urandom), 9'($urandom)};
      @(negedge clock);
      drive();
      #1;
      compare_all();
      if (g_io_uopWriteback_valid & io_uopWriteback_ready) cov_fire++;
      if (u_g.wbIsfof_0 & u_g.wbIsfof_1 & u_g.valid) cov_both_hit++;
      if (u_g.wbValid & (u_g.wbBits_oldest_bits_vpu_vl < u_g.entries_vl | (|u_g._GEN_4))
          & u_g.valid & ~u_g.needRedirect & ~u_g.entries_hasException) begin
        cov_wb_update++;
        if (|u_g._GEN_4) cov_wb_exc++;
      end
      if (u_g.needRedirect & u_g.valid) cov_redirect_kill++;
      if (u_g._GEN_6 & u_g.valid & u_g.enqBits_uop_vpu_isVleff & u_g.enqBits_uop_vpu_lastUop) cov_refresh++;
      if (u_g.enqValid & ~u_g._GEN_6) cov_enq_cancel++;
    end
    bad = 0;
    $display("cov fire=%0d both_hit=%0d wb_update=%0d wb_exc=%0d redirect_kill=%0d refresh=%0d enq_cancel=%0d",
             cov_fire, cov_both_hit, cov_wb_update, cov_wb_exc, cov_redirect_kill, cov_refresh, cov_enq_cancel);
    if (cov_fire < NCYCLES / 400) bad++;
    if (cov_both_hit < NCYCLES / 400) bad++;
    if (cov_wb_update < NCYCLES / 400) bad++;
    if (cov_wb_exc < NCYCLES / 400) bad++;
    if (cov_redirect_kill < NCYCLES / 400) bad++;
    if (cov_refresh < NCYCLES / 400) bad++;
    if (cov_enq_cancel < NCYCLES / 400) bad++;
    for (int o = 0; o < N_OUT; o++) if (!seen0[o] || !seen1[o]) begin bad++; $display("output %0d stuck", o); end
    $display("checks=%0d errors=%0d bad_cov=%0d", checks, errors, bad);
    if (errors == 0 && checks > 1000 && bad == 0) $display("TEST PASSED");
    else $display("TEST FAILED");
    $finish;
  end
endmodule
