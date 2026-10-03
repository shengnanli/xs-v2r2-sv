// =============================================================================
// VldMergeUnit.sv —— 向量 load 写回前的「打一拍 + 按字节合并」单元
//
// 在哪一层：写回数据通路 WbDataPath 里，每个向量 load 执行口（本配置 2 个：
//   MemExu_5_0 / MemExu_6_0）各一个。向量 load 单元送来的写回数据 data_0 是
//   「已经把新读回的元素合进旧 vd」之后的 128 位；但 RVV 还要求按 vstart / vl /
//   mask / vta / vma 决定每个字节到底是新值、全 1 还是旧值 —— 这一步放在这里做。
//
// 两件事（与 Scala backend/datapath/VldMergeUnit.scala 逐句对应）：
//   1. 打一拍：整条写回（ExuOutput）在 io.writeback.fire 时锁进 wbReg；valid 另存，
//      且若这条 uop 已被本拍的 redirect 冲刷（robIdx.needFlush），valid 直接落 0。
//      ★本单元没有复位★（golden 只有 clock 端口）：wbReg.valid 也不复位，靠上游保证。
//   2. 合并：VldMgu 以 wbReg 里的数据同时作为新值与旧值（load 单元已合进旧值），按
//      ByteMaskTailGen 的字节使能挑出新值 / 0xFF / 旧值。mask 取 vmask，vm=1（不掩码）
//      时取全 1；尾部策略 ta = isMasked | vta（掩码 load 的结果按 tail-agnostic 处理）。
//      ★vl 被 fault-only-first 改写过的 uop（vlWen=1）直接用原数据，不合并★。
//
// 输出 writebackAfterMerge：除 data_0 换成合并结果外，其余字段就是 wbReg 原样。
// golden 没有 io.writeback.ready 端口（上游恒就绪，fire = valid）。
//
// 子模块：VldMgu（本 lane 重写，同名白盒）。
// 设计源：XiangShan src/main/scala/xiangshan/backend/datapath/VldMergeUnit.scala
// golden 对照：G1-canonical/golden-rtl/VldMergeUnit.sv
// =============================================================================
package vldmergeunit_pkg;
  // 向量 load 口的一条写回（ExuOutput 在本口的字段子集，字段集合取自 golden 端口表）
  typedef struct packed {
    logic isFpToVecInst;
    logic isFP32Instr;
    logic isFP64Instr;
    logic isReduction;
    logic isFoldTo1_2;
    logic isFoldTo1_4;
    logic isFoldTo1_8;
  } fpu_t;

  typedef struct packed {
    logic         vill;
    logic         vma;
    logic         vta;
    logic [1:0]   vsew;
    logic [2:0]   vlmul;
    logic         specVill;
    logic         specVma;
    logic         specVta;
    logic [1:0]   specVsew;
    logic [2:0]   specVlmul;
    logic         vm;
    logic [7:0]   vstart;
    logic [2:0]   frm;
    fpu_t         fpu;
    logic [1:0]   vxrm;
    logic [6:0]   vuopIdx;
    logic         lastUop;
    logic [127:0] vmask;
    logic [7:0]   vl;
    logic [2:0]   nf;
    logic [1:0]   veew;
    logic         isReverse;
    logic         isExt;
    logic         isNarrow;
    logic         isDstMask;
    logic         isOpMask;
    logic         isMove;
    logic         isDependOldVd;
    logic         isWritePartVd;
    logic         isVleff;
  } vpu_t;

  typedef struct packed {
    vpu_t       vpu;
    logic [7:0] oldVdPsrc;
    logic [2:0] vdIdx;
    logic [2:0] vdIdxInField;
    logic       isIndexed;
    logic       isMasked;
    logic       isStrided;
    logic       isWhole;
    logic       isVecLoad;
    logic       isVlm;
  } vls_t;

  typedef struct packed {
    logic [55:0] seqNum;
    logic [7:0]  uopIdx;
  } seqnum_t;

  typedef struct packed {
    logic        isMMIO;
    logic        isNCIO;
    logic        isPerfCnt;
    logic [47:0] paddr;
    logic [49:0] vaddr;
    seqnum_t     seqNum;
  } debug_t;

  typedef struct packed {
    logic        eliminatedMove;
    logic [63:0] renameTime;
    logic [63:0] dispatchTime;
    logic [63:0] enqRsTime;
    logic [63:0] selectTime;
    logic [63:0] issueTime;
    logic [63:0] writebackTime;
    logic [63:0] runahead_checkpoint_id;
    logic [63:0] tlbFirstReqTime;
    logic [63:0] tlbRespTime;
  } debug_info_t;

  typedef struct packed {
    logic flag;
    logic [7:0] value;
  } rob_ptr_t;

  typedef struct packed {
    logic [127:0] data_0;
    logic [6:0]   pdest;
    rob_ptr_t     robIdx;
    logic         vecWen;
    logic         v0Wen;
    logic         vlWen;
    logic [23:0]  exceptionVec;
    logic         flushPipe;
    logic         replay;
    logic [3:0]   trigger;
    vls_t         vls;
    debug_t       debug;
    debug_info_t  debugInfo;
  } vld_wb_t;
endpackage

module xs_VldMergeUnit_core
  import vldmergeunit_pkg::*;
(
  input  logic     clock,
  // redirect（冲刷）：robIdx 在它之后（或 level=1 时等于它）的 uop 作废
  input  logic     flush_valid,
  input  rob_ptr_t flush_robIdx,
  input  logic     flush_level,
  input  logic     in_valid,
  input  vld_wb_t  in_bits,
  output logic     out_valid,
  output vld_wb_t  out_bits
);
  // ---- 1. 打一拍：本拍被冲刷的 uop 不进 valid；bits 在 fire 时整条锁存 ------------
  // robIdx 是带翻转位的环形指针：flag 相同时比 value，flag 不同时反过来比。
  logic flushed_now;
  assign flushed_now = flush_valid &
                       ( (flush_level & (in_bits.robIdx == flush_robIdx))
                       | ((in_bits.robIdx.flag ^ flush_robIdx.flag)
                          ^ (in_bits.robIdx.value > flush_robIdx.value)) );

  logic    wb_valid;
  vld_wb_t wb_bits;
  always_ff @(posedge clock) begin
    wb_valid <= in_valid & ~flushed_now;
    if (in_valid) wb_bits <= in_bits;
  end

  // ---- 2. 按字节合并 ----------------------------------------------------------
  logic [127:0] merged_vd;
  VldMgu u_mgu (
    .io_in_vd           (wb_bits.data_0),
    .io_in_oldVd        (wb_bits.data_0),   // 旧值已由 load 单元合进 data
    .io_in_mask         (wb_bits.vls.vpu.vm ? '1 : wb_bits.vls.vpu.vmask),
    .io_in_info_ta      (wb_bits.vls.isMasked | wb_bits.vls.vpu.vta),
    .io_in_info_ma      (wb_bits.vls.vpu.vma),
    .io_in_info_vl      (wb_bits.vls.vpu.vl),
    .io_in_info_vstart  (wb_bits.vls.vpu.vstart),
    .io_in_info_eew     (wb_bits.vls.vpu.veew),
    .io_in_info_vsew    (wb_bits.vls.vpu.vsew),
    .io_in_info_vdIdx   (wb_bits.vls.vdIdxInField),
    .io_in_isIndexedVls (wb_bits.vls.isIndexed),
    .io_out_vd          (merged_vd)
  );

  // ---- 3. 输出：只有 data_0 换成合并结果（vlWen 的 uop 例外，用原数据） ------------
  always_comb begin
    out_valid       = wb_valid;
    out_bits        = wb_bits;
    out_bits.data_0 = wb_bits.vlWen ? wb_bits.data_0 : merged_vd;
  end
endmodule

// BEGIN GENERATED(vldmergeunit-wrapper)
module VldMergeUnit (
  input          clock,
  input          io_flush_valid,
  input          io_flush_bits_robIdx_flag,
  input  [7:0]   io_flush_bits_robIdx_value,
  input          io_flush_bits_level,
  input          io_writeback_valid,
  input  [127:0] io_writeback_bits_data_0,
  input  [6:0]   io_writeback_bits_pdest,
  input          io_writeback_bits_robIdx_flag,
  input  [7:0]   io_writeback_bits_robIdx_value,
  input          io_writeback_bits_vecWen,
  input          io_writeback_bits_v0Wen,
  input          io_writeback_bits_vlWen,
  input          io_writeback_bits_exceptionVec_0,
  input          io_writeback_bits_exceptionVec_1,
  input          io_writeback_bits_exceptionVec_2,
  input          io_writeback_bits_exceptionVec_3,
  input          io_writeback_bits_exceptionVec_4,
  input          io_writeback_bits_exceptionVec_5,
  input          io_writeback_bits_exceptionVec_6,
  input          io_writeback_bits_exceptionVec_7,
  input          io_writeback_bits_exceptionVec_8,
  input          io_writeback_bits_exceptionVec_9,
  input          io_writeback_bits_exceptionVec_10,
  input          io_writeback_bits_exceptionVec_11,
  input          io_writeback_bits_exceptionVec_12,
  input          io_writeback_bits_exceptionVec_13,
  input          io_writeback_bits_exceptionVec_14,
  input          io_writeback_bits_exceptionVec_15,
  input          io_writeback_bits_exceptionVec_16,
  input          io_writeback_bits_exceptionVec_17,
  input          io_writeback_bits_exceptionVec_18,
  input          io_writeback_bits_exceptionVec_19,
  input          io_writeback_bits_exceptionVec_20,
  input          io_writeback_bits_exceptionVec_21,
  input          io_writeback_bits_exceptionVec_22,
  input          io_writeback_bits_exceptionVec_23,
  input          io_writeback_bits_flushPipe,
  input          io_writeback_bits_replay,
  input  [3:0]   io_writeback_bits_trigger,
  input          io_writeback_bits_vls_vpu_vill,
  input          io_writeback_bits_vls_vpu_vma,
  input          io_writeback_bits_vls_vpu_vta,
  input  [1:0]   io_writeback_bits_vls_vpu_vsew,
  input  [2:0]   io_writeback_bits_vls_vpu_vlmul,
  input          io_writeback_bits_vls_vpu_specVill,
  input          io_writeback_bits_vls_vpu_specVma,
  input          io_writeback_bits_vls_vpu_specVta,
  input  [1:0]   io_writeback_bits_vls_vpu_specVsew,
  input  [2:0]   io_writeback_bits_vls_vpu_specVlmul,
  input          io_writeback_bits_vls_vpu_vm,
  input  [7:0]   io_writeback_bits_vls_vpu_vstart,
  input  [2:0]   io_writeback_bits_vls_vpu_frm,
  input          io_writeback_bits_vls_vpu_fpu_isFpToVecInst,
  input          io_writeback_bits_vls_vpu_fpu_isFP32Instr,
  input          io_writeback_bits_vls_vpu_fpu_isFP64Instr,
  input          io_writeback_bits_vls_vpu_fpu_isReduction,
  input          io_writeback_bits_vls_vpu_fpu_isFoldTo1_2,
  input          io_writeback_bits_vls_vpu_fpu_isFoldTo1_4,
  input          io_writeback_bits_vls_vpu_fpu_isFoldTo1_8,
  input  [1:0]   io_writeback_bits_vls_vpu_vxrm,
  input  [6:0]   io_writeback_bits_vls_vpu_vuopIdx,
  input          io_writeback_bits_vls_vpu_lastUop,
  input  [127:0] io_writeback_bits_vls_vpu_vmask,
  input  [7:0]   io_writeback_bits_vls_vpu_vl,
  input  [2:0]   io_writeback_bits_vls_vpu_nf,
  input  [1:0]   io_writeback_bits_vls_vpu_veew,
  input          io_writeback_bits_vls_vpu_isReverse,
  input          io_writeback_bits_vls_vpu_isExt,
  input          io_writeback_bits_vls_vpu_isNarrow,
  input          io_writeback_bits_vls_vpu_isDstMask,
  input          io_writeback_bits_vls_vpu_isOpMask,
  input          io_writeback_bits_vls_vpu_isMove,
  input          io_writeback_bits_vls_vpu_isDependOldVd,
  input          io_writeback_bits_vls_vpu_isWritePartVd,
  input          io_writeback_bits_vls_vpu_isVleff,
  input  [7:0]   io_writeback_bits_vls_oldVdPsrc,
  input  [2:0]   io_writeback_bits_vls_vdIdx,
  input  [2:0]   io_writeback_bits_vls_vdIdxInField,
  input          io_writeback_bits_vls_isIndexed,
  input          io_writeback_bits_vls_isMasked,
  input          io_writeback_bits_vls_isStrided,
  input          io_writeback_bits_vls_isWhole,
  input          io_writeback_bits_vls_isVecLoad,
  input          io_writeback_bits_vls_isVlm,
  input          io_writeback_bits_debug_isMMIO,
  input          io_writeback_bits_debug_isNCIO,
  input          io_writeback_bits_debug_isPerfCnt,
  input  [47:0]  io_writeback_bits_debug_paddr,
  input  [49:0]  io_writeback_bits_debug_vaddr,
  input          io_writeback_bits_debugInfo_eliminatedMove,
  input  [63:0]  io_writeback_bits_debugInfo_renameTime,
  input  [63:0]  io_writeback_bits_debugInfo_dispatchTime,
  input  [63:0]  io_writeback_bits_debugInfo_enqRsTime,
  input  [63:0]  io_writeback_bits_debugInfo_selectTime,
  input  [63:0]  io_writeback_bits_debugInfo_issueTime,
  input  [63:0]  io_writeback_bits_debugInfo_writebackTime,
  input  [63:0]  io_writeback_bits_debugInfo_runahead_checkpoint_id,
  input  [63:0]  io_writeback_bits_debugInfo_tlbFirstReqTime,
  input  [63:0]  io_writeback_bits_debugInfo_tlbRespTime,
  input  [55:0]  io_writeback_bits_debug_seqNum_seqNum,
  input  [7:0]   io_writeback_bits_debug_seqNum_uopIdx,
  output         io_writebackAfterMerge_valid,
  output [127:0] io_writebackAfterMerge_bits_data_0,
  output [6:0]   io_writebackAfterMerge_bits_pdest,
  output         io_writebackAfterMerge_bits_robIdx_flag,
  output [7:0]   io_writebackAfterMerge_bits_robIdx_value,
  output         io_writebackAfterMerge_bits_vecWen,
  output         io_writebackAfterMerge_bits_v0Wen,
  output         io_writebackAfterMerge_bits_vlWen,
  output         io_writebackAfterMerge_bits_exceptionVec_0,
  output         io_writebackAfterMerge_bits_exceptionVec_1,
  output         io_writebackAfterMerge_bits_exceptionVec_2,
  output         io_writebackAfterMerge_bits_exceptionVec_3,
  output         io_writebackAfterMerge_bits_exceptionVec_4,
  output         io_writebackAfterMerge_bits_exceptionVec_5,
  output         io_writebackAfterMerge_bits_exceptionVec_6,
  output         io_writebackAfterMerge_bits_exceptionVec_7,
  output         io_writebackAfterMerge_bits_exceptionVec_8,
  output         io_writebackAfterMerge_bits_exceptionVec_9,
  output         io_writebackAfterMerge_bits_exceptionVec_10,
  output         io_writebackAfterMerge_bits_exceptionVec_11,
  output         io_writebackAfterMerge_bits_exceptionVec_12,
  output         io_writebackAfterMerge_bits_exceptionVec_13,
  output         io_writebackAfterMerge_bits_exceptionVec_14,
  output         io_writebackAfterMerge_bits_exceptionVec_15,
  output         io_writebackAfterMerge_bits_exceptionVec_16,
  output         io_writebackAfterMerge_bits_exceptionVec_17,
  output         io_writebackAfterMerge_bits_exceptionVec_18,
  output         io_writebackAfterMerge_bits_exceptionVec_19,
  output         io_writebackAfterMerge_bits_exceptionVec_20,
  output         io_writebackAfterMerge_bits_exceptionVec_21,
  output         io_writebackAfterMerge_bits_exceptionVec_22,
  output         io_writebackAfterMerge_bits_exceptionVec_23,
  output         io_writebackAfterMerge_bits_flushPipe,
  output         io_writebackAfterMerge_bits_replay,
  output [3:0]   io_writebackAfterMerge_bits_trigger,
  output         io_writebackAfterMerge_bits_vls_vpu_vill,
  output         io_writebackAfterMerge_bits_vls_vpu_vma,
  output         io_writebackAfterMerge_bits_vls_vpu_vta,
  output [1:0]   io_writebackAfterMerge_bits_vls_vpu_vsew,
  output [2:0]   io_writebackAfterMerge_bits_vls_vpu_vlmul,
  output         io_writebackAfterMerge_bits_vls_vpu_specVill,
  output         io_writebackAfterMerge_bits_vls_vpu_specVma,
  output         io_writebackAfterMerge_bits_vls_vpu_specVta,
  output [1:0]   io_writebackAfterMerge_bits_vls_vpu_specVsew,
  output [2:0]   io_writebackAfterMerge_bits_vls_vpu_specVlmul,
  output         io_writebackAfterMerge_bits_vls_vpu_vm,
  output [7:0]   io_writebackAfterMerge_bits_vls_vpu_vstart,
  output [2:0]   io_writebackAfterMerge_bits_vls_vpu_frm,
  output         io_writebackAfterMerge_bits_vls_vpu_fpu_isFpToVecInst,
  output         io_writebackAfterMerge_bits_vls_vpu_fpu_isFP32Instr,
  output         io_writebackAfterMerge_bits_vls_vpu_fpu_isFP64Instr,
  output         io_writebackAfterMerge_bits_vls_vpu_fpu_isReduction,
  output         io_writebackAfterMerge_bits_vls_vpu_fpu_isFoldTo1_2,
  output         io_writebackAfterMerge_bits_vls_vpu_fpu_isFoldTo1_4,
  output         io_writebackAfterMerge_bits_vls_vpu_fpu_isFoldTo1_8,
  output [1:0]   io_writebackAfterMerge_bits_vls_vpu_vxrm,
  output [6:0]   io_writebackAfterMerge_bits_vls_vpu_vuopIdx,
  output         io_writebackAfterMerge_bits_vls_vpu_lastUop,
  output [127:0] io_writebackAfterMerge_bits_vls_vpu_vmask,
  output [7:0]   io_writebackAfterMerge_bits_vls_vpu_vl,
  output [2:0]   io_writebackAfterMerge_bits_vls_vpu_nf,
  output [1:0]   io_writebackAfterMerge_bits_vls_vpu_veew,
  output         io_writebackAfterMerge_bits_vls_vpu_isReverse,
  output         io_writebackAfterMerge_bits_vls_vpu_isExt,
  output         io_writebackAfterMerge_bits_vls_vpu_isNarrow,
  output         io_writebackAfterMerge_bits_vls_vpu_isDstMask,
  output         io_writebackAfterMerge_bits_vls_vpu_isOpMask,
  output         io_writebackAfterMerge_bits_vls_vpu_isMove,
  output         io_writebackAfterMerge_bits_vls_vpu_isDependOldVd,
  output         io_writebackAfterMerge_bits_vls_vpu_isWritePartVd,
  output         io_writebackAfterMerge_bits_vls_vpu_isVleff,
  output [7:0]   io_writebackAfterMerge_bits_vls_oldVdPsrc,
  output [2:0]   io_writebackAfterMerge_bits_vls_vdIdx,
  output [2:0]   io_writebackAfterMerge_bits_vls_vdIdxInField,
  output         io_writebackAfterMerge_bits_vls_isIndexed,
  output         io_writebackAfterMerge_bits_vls_isMasked,
  output         io_writebackAfterMerge_bits_vls_isStrided,
  output         io_writebackAfterMerge_bits_vls_isWhole,
  output         io_writebackAfterMerge_bits_vls_isVecLoad,
  output         io_writebackAfterMerge_bits_vls_isVlm,
  output         io_writebackAfterMerge_bits_debug_isMMIO,
  output         io_writebackAfterMerge_bits_debug_isNCIO,
  output         io_writebackAfterMerge_bits_debug_isPerfCnt,
  output [47:0]  io_writebackAfterMerge_bits_debug_paddr,
  output [49:0]  io_writebackAfterMerge_bits_debug_vaddr,
  output         io_writebackAfterMerge_bits_debugInfo_eliminatedMove,
  output [63:0]  io_writebackAfterMerge_bits_debugInfo_renameTime,
  output [63:0]  io_writebackAfterMerge_bits_debugInfo_dispatchTime,
  output [63:0]  io_writebackAfterMerge_bits_debugInfo_enqRsTime,
  output [63:0]  io_writebackAfterMerge_bits_debugInfo_selectTime,
  output [63:0]  io_writebackAfterMerge_bits_debugInfo_issueTime,
  output [63:0]  io_writebackAfterMerge_bits_debugInfo_writebackTime,
  output [63:0]  io_writebackAfterMerge_bits_debugInfo_runahead_checkpoint_id,
  output [63:0]  io_writebackAfterMerge_bits_debugInfo_tlbFirstReqTime,
  output [63:0]  io_writebackAfterMerge_bits_debugInfo_tlbRespTime,
  output [55:0]  io_writebackAfterMerge_bits_debug_seqNum_seqNum,
  output [7:0]   io_writebackAfterMerge_bits_debug_seqNum_uopIdx
);
  import vldmergeunit_pkg::*;

  rob_ptr_t flush_robIdx;
  vld_wb_t  in_bits, out_bits;
  assign flush_robIdx = '{io_flush_bits_robIdx_flag, io_flush_bits_robIdx_value};
  assign in_bits.data_0 = io_writeback_bits_data_0;
  assign in_bits.pdest = io_writeback_bits_pdest;
  assign in_bits.robIdx.flag = io_writeback_bits_robIdx_flag;
  assign in_bits.robIdx.value = io_writeback_bits_robIdx_value;
  assign in_bits.vecWen = io_writeback_bits_vecWen;
  assign in_bits.v0Wen = io_writeback_bits_v0Wen;
  assign in_bits.vlWen = io_writeback_bits_vlWen;
  assign in_bits.exceptionVec[0] = io_writeback_bits_exceptionVec_0;
  assign in_bits.exceptionVec[1] = io_writeback_bits_exceptionVec_1;
  assign in_bits.exceptionVec[2] = io_writeback_bits_exceptionVec_2;
  assign in_bits.exceptionVec[3] = io_writeback_bits_exceptionVec_3;
  assign in_bits.exceptionVec[4] = io_writeback_bits_exceptionVec_4;
  assign in_bits.exceptionVec[5] = io_writeback_bits_exceptionVec_5;
  assign in_bits.exceptionVec[6] = io_writeback_bits_exceptionVec_6;
  assign in_bits.exceptionVec[7] = io_writeback_bits_exceptionVec_7;
  assign in_bits.exceptionVec[8] = io_writeback_bits_exceptionVec_8;
  assign in_bits.exceptionVec[9] = io_writeback_bits_exceptionVec_9;
  assign in_bits.exceptionVec[10] = io_writeback_bits_exceptionVec_10;
  assign in_bits.exceptionVec[11] = io_writeback_bits_exceptionVec_11;
  assign in_bits.exceptionVec[12] = io_writeback_bits_exceptionVec_12;
  assign in_bits.exceptionVec[13] = io_writeback_bits_exceptionVec_13;
  assign in_bits.exceptionVec[14] = io_writeback_bits_exceptionVec_14;
  assign in_bits.exceptionVec[15] = io_writeback_bits_exceptionVec_15;
  assign in_bits.exceptionVec[16] = io_writeback_bits_exceptionVec_16;
  assign in_bits.exceptionVec[17] = io_writeback_bits_exceptionVec_17;
  assign in_bits.exceptionVec[18] = io_writeback_bits_exceptionVec_18;
  assign in_bits.exceptionVec[19] = io_writeback_bits_exceptionVec_19;
  assign in_bits.exceptionVec[20] = io_writeback_bits_exceptionVec_20;
  assign in_bits.exceptionVec[21] = io_writeback_bits_exceptionVec_21;
  assign in_bits.exceptionVec[22] = io_writeback_bits_exceptionVec_22;
  assign in_bits.exceptionVec[23] = io_writeback_bits_exceptionVec_23;
  assign in_bits.flushPipe = io_writeback_bits_flushPipe;
  assign in_bits.replay = io_writeback_bits_replay;
  assign in_bits.trigger = io_writeback_bits_trigger;
  assign in_bits.vls.vpu.vill = io_writeback_bits_vls_vpu_vill;
  assign in_bits.vls.vpu.vma = io_writeback_bits_vls_vpu_vma;
  assign in_bits.vls.vpu.vta = io_writeback_bits_vls_vpu_vta;
  assign in_bits.vls.vpu.vsew = io_writeback_bits_vls_vpu_vsew;
  assign in_bits.vls.vpu.vlmul = io_writeback_bits_vls_vpu_vlmul;
  assign in_bits.vls.vpu.specVill = io_writeback_bits_vls_vpu_specVill;
  assign in_bits.vls.vpu.specVma = io_writeback_bits_vls_vpu_specVma;
  assign in_bits.vls.vpu.specVta = io_writeback_bits_vls_vpu_specVta;
  assign in_bits.vls.vpu.specVsew = io_writeback_bits_vls_vpu_specVsew;
  assign in_bits.vls.vpu.specVlmul = io_writeback_bits_vls_vpu_specVlmul;
  assign in_bits.vls.vpu.vm = io_writeback_bits_vls_vpu_vm;
  assign in_bits.vls.vpu.vstart = io_writeback_bits_vls_vpu_vstart;
  assign in_bits.vls.vpu.frm = io_writeback_bits_vls_vpu_frm;
  assign in_bits.vls.vpu.fpu.isFpToVecInst = io_writeback_bits_vls_vpu_fpu_isFpToVecInst;
  assign in_bits.vls.vpu.fpu.isFP32Instr = io_writeback_bits_vls_vpu_fpu_isFP32Instr;
  assign in_bits.vls.vpu.fpu.isFP64Instr = io_writeback_bits_vls_vpu_fpu_isFP64Instr;
  assign in_bits.vls.vpu.fpu.isReduction = io_writeback_bits_vls_vpu_fpu_isReduction;
  assign in_bits.vls.vpu.fpu.isFoldTo1_2 = io_writeback_bits_vls_vpu_fpu_isFoldTo1_2;
  assign in_bits.vls.vpu.fpu.isFoldTo1_4 = io_writeback_bits_vls_vpu_fpu_isFoldTo1_4;
  assign in_bits.vls.vpu.fpu.isFoldTo1_8 = io_writeback_bits_vls_vpu_fpu_isFoldTo1_8;
  assign in_bits.vls.vpu.vxrm = io_writeback_bits_vls_vpu_vxrm;
  assign in_bits.vls.vpu.vuopIdx = io_writeback_bits_vls_vpu_vuopIdx;
  assign in_bits.vls.vpu.lastUop = io_writeback_bits_vls_vpu_lastUop;
  assign in_bits.vls.vpu.vmask = io_writeback_bits_vls_vpu_vmask;
  assign in_bits.vls.vpu.vl = io_writeback_bits_vls_vpu_vl;
  assign in_bits.vls.vpu.nf = io_writeback_bits_vls_vpu_nf;
  assign in_bits.vls.vpu.veew = io_writeback_bits_vls_vpu_veew;
  assign in_bits.vls.vpu.isReverse = io_writeback_bits_vls_vpu_isReverse;
  assign in_bits.vls.vpu.isExt = io_writeback_bits_vls_vpu_isExt;
  assign in_bits.vls.vpu.isNarrow = io_writeback_bits_vls_vpu_isNarrow;
  assign in_bits.vls.vpu.isDstMask = io_writeback_bits_vls_vpu_isDstMask;
  assign in_bits.vls.vpu.isOpMask = io_writeback_bits_vls_vpu_isOpMask;
  assign in_bits.vls.vpu.isMove = io_writeback_bits_vls_vpu_isMove;
  assign in_bits.vls.vpu.isDependOldVd = io_writeback_bits_vls_vpu_isDependOldVd;
  assign in_bits.vls.vpu.isWritePartVd = io_writeback_bits_vls_vpu_isWritePartVd;
  assign in_bits.vls.vpu.isVleff = io_writeback_bits_vls_vpu_isVleff;
  assign in_bits.vls.oldVdPsrc = io_writeback_bits_vls_oldVdPsrc;
  assign in_bits.vls.vdIdx = io_writeback_bits_vls_vdIdx;
  assign in_bits.vls.vdIdxInField = io_writeback_bits_vls_vdIdxInField;
  assign in_bits.vls.isIndexed = io_writeback_bits_vls_isIndexed;
  assign in_bits.vls.isMasked = io_writeback_bits_vls_isMasked;
  assign in_bits.vls.isStrided = io_writeback_bits_vls_isStrided;
  assign in_bits.vls.isWhole = io_writeback_bits_vls_isWhole;
  assign in_bits.vls.isVecLoad = io_writeback_bits_vls_isVecLoad;
  assign in_bits.vls.isVlm = io_writeback_bits_vls_isVlm;
  assign in_bits.debug.isMMIO = io_writeback_bits_debug_isMMIO;
  assign in_bits.debug.isNCIO = io_writeback_bits_debug_isNCIO;
  assign in_bits.debug.isPerfCnt = io_writeback_bits_debug_isPerfCnt;
  assign in_bits.debug.paddr = io_writeback_bits_debug_paddr;
  assign in_bits.debug.vaddr = io_writeback_bits_debug_vaddr;
  assign in_bits.debugInfo.eliminatedMove = io_writeback_bits_debugInfo_eliminatedMove;
  assign in_bits.debugInfo.renameTime = io_writeback_bits_debugInfo_renameTime;
  assign in_bits.debugInfo.dispatchTime = io_writeback_bits_debugInfo_dispatchTime;
  assign in_bits.debugInfo.enqRsTime = io_writeback_bits_debugInfo_enqRsTime;
  assign in_bits.debugInfo.selectTime = io_writeback_bits_debugInfo_selectTime;
  assign in_bits.debugInfo.issueTime = io_writeback_bits_debugInfo_issueTime;
  assign in_bits.debugInfo.writebackTime = io_writeback_bits_debugInfo_writebackTime;
  assign in_bits.debugInfo.runahead_checkpoint_id = io_writeback_bits_debugInfo_runahead_checkpoint_id;
  assign in_bits.debugInfo.tlbFirstReqTime = io_writeback_bits_debugInfo_tlbFirstReqTime;
  assign in_bits.debugInfo.tlbRespTime = io_writeback_bits_debugInfo_tlbRespTime;
  assign in_bits.debug.seqNum.seqNum = io_writeback_bits_debug_seqNum_seqNum;
  assign in_bits.debug.seqNum.uopIdx = io_writeback_bits_debug_seqNum_uopIdx;

  xs_VldMergeUnit_core u_core (
    .clock        (clock),
    .flush_valid  (io_flush_valid),
    .flush_robIdx (flush_robIdx),
    .flush_level  (io_flush_bits_level),
    .in_valid     (io_writeback_valid),
    .in_bits      (in_bits),
    .out_valid    (io_writebackAfterMerge_valid),
    .out_bits     (out_bits)
  );

  assign io_writebackAfterMerge_bits_data_0 = out_bits.data_0;
  assign io_writebackAfterMerge_bits_pdest = out_bits.pdest;
  assign io_writebackAfterMerge_bits_robIdx_flag = out_bits.robIdx.flag;
  assign io_writebackAfterMerge_bits_robIdx_value = out_bits.robIdx.value;
  assign io_writebackAfterMerge_bits_vecWen = out_bits.vecWen;
  assign io_writebackAfterMerge_bits_v0Wen = out_bits.v0Wen;
  assign io_writebackAfterMerge_bits_vlWen = out_bits.vlWen;
  assign io_writebackAfterMerge_bits_exceptionVec_0 = out_bits.exceptionVec[0];
  assign io_writebackAfterMerge_bits_exceptionVec_1 = out_bits.exceptionVec[1];
  assign io_writebackAfterMerge_bits_exceptionVec_2 = out_bits.exceptionVec[2];
  assign io_writebackAfterMerge_bits_exceptionVec_3 = out_bits.exceptionVec[3];
  assign io_writebackAfterMerge_bits_exceptionVec_4 = out_bits.exceptionVec[4];
  assign io_writebackAfterMerge_bits_exceptionVec_5 = out_bits.exceptionVec[5];
  assign io_writebackAfterMerge_bits_exceptionVec_6 = out_bits.exceptionVec[6];
  assign io_writebackAfterMerge_bits_exceptionVec_7 = out_bits.exceptionVec[7];
  assign io_writebackAfterMerge_bits_exceptionVec_8 = out_bits.exceptionVec[8];
  assign io_writebackAfterMerge_bits_exceptionVec_9 = out_bits.exceptionVec[9];
  assign io_writebackAfterMerge_bits_exceptionVec_10 = out_bits.exceptionVec[10];
  assign io_writebackAfterMerge_bits_exceptionVec_11 = out_bits.exceptionVec[11];
  assign io_writebackAfterMerge_bits_exceptionVec_12 = out_bits.exceptionVec[12];
  assign io_writebackAfterMerge_bits_exceptionVec_13 = out_bits.exceptionVec[13];
  assign io_writebackAfterMerge_bits_exceptionVec_14 = out_bits.exceptionVec[14];
  assign io_writebackAfterMerge_bits_exceptionVec_15 = out_bits.exceptionVec[15];
  assign io_writebackAfterMerge_bits_exceptionVec_16 = out_bits.exceptionVec[16];
  assign io_writebackAfterMerge_bits_exceptionVec_17 = out_bits.exceptionVec[17];
  assign io_writebackAfterMerge_bits_exceptionVec_18 = out_bits.exceptionVec[18];
  assign io_writebackAfterMerge_bits_exceptionVec_19 = out_bits.exceptionVec[19];
  assign io_writebackAfterMerge_bits_exceptionVec_20 = out_bits.exceptionVec[20];
  assign io_writebackAfterMerge_bits_exceptionVec_21 = out_bits.exceptionVec[21];
  assign io_writebackAfterMerge_bits_exceptionVec_22 = out_bits.exceptionVec[22];
  assign io_writebackAfterMerge_bits_exceptionVec_23 = out_bits.exceptionVec[23];
  assign io_writebackAfterMerge_bits_flushPipe = out_bits.flushPipe;
  assign io_writebackAfterMerge_bits_replay = out_bits.replay;
  assign io_writebackAfterMerge_bits_trigger = out_bits.trigger;
  assign io_writebackAfterMerge_bits_vls_vpu_vill = out_bits.vls.vpu.vill;
  assign io_writebackAfterMerge_bits_vls_vpu_vma = out_bits.vls.vpu.vma;
  assign io_writebackAfterMerge_bits_vls_vpu_vta = out_bits.vls.vpu.vta;
  assign io_writebackAfterMerge_bits_vls_vpu_vsew = out_bits.vls.vpu.vsew;
  assign io_writebackAfterMerge_bits_vls_vpu_vlmul = out_bits.vls.vpu.vlmul;
  assign io_writebackAfterMerge_bits_vls_vpu_specVill = out_bits.vls.vpu.specVill;
  assign io_writebackAfterMerge_bits_vls_vpu_specVma = out_bits.vls.vpu.specVma;
  assign io_writebackAfterMerge_bits_vls_vpu_specVta = out_bits.vls.vpu.specVta;
  assign io_writebackAfterMerge_bits_vls_vpu_specVsew = out_bits.vls.vpu.specVsew;
  assign io_writebackAfterMerge_bits_vls_vpu_specVlmul = out_bits.vls.vpu.specVlmul;
  assign io_writebackAfterMerge_bits_vls_vpu_vm = out_bits.vls.vpu.vm;
  assign io_writebackAfterMerge_bits_vls_vpu_vstart = out_bits.vls.vpu.vstart;
  assign io_writebackAfterMerge_bits_vls_vpu_frm = out_bits.vls.vpu.frm;
  assign io_writebackAfterMerge_bits_vls_vpu_fpu_isFpToVecInst = out_bits.vls.vpu.fpu.isFpToVecInst;
  assign io_writebackAfterMerge_bits_vls_vpu_fpu_isFP32Instr = out_bits.vls.vpu.fpu.isFP32Instr;
  assign io_writebackAfterMerge_bits_vls_vpu_fpu_isFP64Instr = out_bits.vls.vpu.fpu.isFP64Instr;
  assign io_writebackAfterMerge_bits_vls_vpu_fpu_isReduction = out_bits.vls.vpu.fpu.isReduction;
  assign io_writebackAfterMerge_bits_vls_vpu_fpu_isFoldTo1_2 = out_bits.vls.vpu.fpu.isFoldTo1_2;
  assign io_writebackAfterMerge_bits_vls_vpu_fpu_isFoldTo1_4 = out_bits.vls.vpu.fpu.isFoldTo1_4;
  assign io_writebackAfterMerge_bits_vls_vpu_fpu_isFoldTo1_8 = out_bits.vls.vpu.fpu.isFoldTo1_8;
  assign io_writebackAfterMerge_bits_vls_vpu_vxrm = out_bits.vls.vpu.vxrm;
  assign io_writebackAfterMerge_bits_vls_vpu_vuopIdx = out_bits.vls.vpu.vuopIdx;
  assign io_writebackAfterMerge_bits_vls_vpu_lastUop = out_bits.vls.vpu.lastUop;
  assign io_writebackAfterMerge_bits_vls_vpu_vmask = out_bits.vls.vpu.vmask;
  assign io_writebackAfterMerge_bits_vls_vpu_vl = out_bits.vls.vpu.vl;
  assign io_writebackAfterMerge_bits_vls_vpu_nf = out_bits.vls.vpu.nf;
  assign io_writebackAfterMerge_bits_vls_vpu_veew = out_bits.vls.vpu.veew;
  assign io_writebackAfterMerge_bits_vls_vpu_isReverse = out_bits.vls.vpu.isReverse;
  assign io_writebackAfterMerge_bits_vls_vpu_isExt = out_bits.vls.vpu.isExt;
  assign io_writebackAfterMerge_bits_vls_vpu_isNarrow = out_bits.vls.vpu.isNarrow;
  assign io_writebackAfterMerge_bits_vls_vpu_isDstMask = out_bits.vls.vpu.isDstMask;
  assign io_writebackAfterMerge_bits_vls_vpu_isOpMask = out_bits.vls.vpu.isOpMask;
  assign io_writebackAfterMerge_bits_vls_vpu_isMove = out_bits.vls.vpu.isMove;
  assign io_writebackAfterMerge_bits_vls_vpu_isDependOldVd = out_bits.vls.vpu.isDependOldVd;
  assign io_writebackAfterMerge_bits_vls_vpu_isWritePartVd = out_bits.vls.vpu.isWritePartVd;
  assign io_writebackAfterMerge_bits_vls_vpu_isVleff = out_bits.vls.vpu.isVleff;
  assign io_writebackAfterMerge_bits_vls_oldVdPsrc = out_bits.vls.oldVdPsrc;
  assign io_writebackAfterMerge_bits_vls_vdIdx = out_bits.vls.vdIdx;
  assign io_writebackAfterMerge_bits_vls_vdIdxInField = out_bits.vls.vdIdxInField;
  assign io_writebackAfterMerge_bits_vls_isIndexed = out_bits.vls.isIndexed;
  assign io_writebackAfterMerge_bits_vls_isMasked = out_bits.vls.isMasked;
  assign io_writebackAfterMerge_bits_vls_isStrided = out_bits.vls.isStrided;
  assign io_writebackAfterMerge_bits_vls_isWhole = out_bits.vls.isWhole;
  assign io_writebackAfterMerge_bits_vls_isVecLoad = out_bits.vls.isVecLoad;
  assign io_writebackAfterMerge_bits_vls_isVlm = out_bits.vls.isVlm;
  assign io_writebackAfterMerge_bits_debug_isMMIO = out_bits.debug.isMMIO;
  assign io_writebackAfterMerge_bits_debug_isNCIO = out_bits.debug.isNCIO;
  assign io_writebackAfterMerge_bits_debug_isPerfCnt = out_bits.debug.isPerfCnt;
  assign io_writebackAfterMerge_bits_debug_paddr = out_bits.debug.paddr;
  assign io_writebackAfterMerge_bits_debug_vaddr = out_bits.debug.vaddr;
  assign io_writebackAfterMerge_bits_debugInfo_eliminatedMove = out_bits.debugInfo.eliminatedMove;
  assign io_writebackAfterMerge_bits_debugInfo_renameTime = out_bits.debugInfo.renameTime;
  assign io_writebackAfterMerge_bits_debugInfo_dispatchTime = out_bits.debugInfo.dispatchTime;
  assign io_writebackAfterMerge_bits_debugInfo_enqRsTime = out_bits.debugInfo.enqRsTime;
  assign io_writebackAfterMerge_bits_debugInfo_selectTime = out_bits.debugInfo.selectTime;
  assign io_writebackAfterMerge_bits_debugInfo_issueTime = out_bits.debugInfo.issueTime;
  assign io_writebackAfterMerge_bits_debugInfo_writebackTime = out_bits.debugInfo.writebackTime;
  assign io_writebackAfterMerge_bits_debugInfo_runahead_checkpoint_id = out_bits.debugInfo.runahead_checkpoint_id;
  assign io_writebackAfterMerge_bits_debugInfo_tlbFirstReqTime = out_bits.debugInfo.tlbFirstReqTime;
  assign io_writebackAfterMerge_bits_debugInfo_tlbRespTime = out_bits.debugInfo.tlbRespTime;
  assign io_writebackAfterMerge_bits_debug_seqNum_seqNum = out_bits.debug.seqNum.seqNum;
  assign io_writebackAfterMerge_bits_debug_seqNum_uopIdx = out_bits.debug.seqNum.uopIdx;
endmodule
// END GENERATED
