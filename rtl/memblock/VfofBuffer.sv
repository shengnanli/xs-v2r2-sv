// =============================================================================
// VfofBuffer.sv —— 向量 fault-only-first（vleff）load 的 vl 修正缓冲（单条目）
//
// 在哪一层：MemBlock 向量 load 写回通路。vleff 指令遇到异常不报异常，而是把 vl 截到
//   第一个出错元素；同一条 vleff 的各个 uop 从向量 load 合并单元逐个写回（mergeUopWriteback
//   两个口），本件把它们汇成"这条指令最终的 vl / 是否带异常"，等最后一个 uop（lastUop）
//   到位后把 uop 连同新 vl 一次写回（uopWriteback），由后端更新 vl CSR。
// 设计源：Scala mem/vector/VfofBuffer.scala。
//
// 单条目状态：uop 载荷（原样带出的 DynInst 字段，packed struct）+ vl + hasException + valid。
// §1 入队：两个 in 口里 isVleff 的那个（0 口优先）。被 redirect 冲掉的入队不接。
//      条目空 → 收 uop、vl = src_4[7:0]（VConfig 的 vl 字段）、hasException 清 0；
//      条目非空且进来的是本指令的 lastUop → 只刷新 uop（vl 由写回口维护）。
//      Scala 断言"非空时不应来别的 robIdx"，golden 里只是 assert，不进逻辑。
// §2 写回聚合：两个写回口里 robIdx 等于本条目的算命中；两口同时命中时取"更老"的：
//      口 1 的 vl 更大或口 0 带异常（且口 1 不带异常）→ 取口 0，否则取口 1；
//      只一口命中就取那口。命中口的 vl 更小或带异常，且条目有效、未被冲、尚无异常
//      → 更新 vl / hasException（优先于同拍入队）。
// §3 出队与 valid：条目有效且 uop 是 isVleff 的 lastUop 且未被冲 → uopWriteback.valid；
//      fire 或 redirect 命中 → valid 清 0；否则有入队 → 置 1。
// 怪癖：
//   - 异常只看 exceptionVec 的 3/4/5/13/19/21 六位（load 相关异常，其余位被 firtool 消掉）。
//   - 写回 data = {120'b0, vl}；uop.vpu.vl 输出的是本件维护的 vl，不是入队时的 vl。
//   - 全部寄存器异步复位到 0（照 golden）。golden 的 in.ready / mergeUopWriteback.ready 恒 1 被消端口。
// golden 对照：G1-canonical/golden-rtl/VfofBuffer.sv
// =============================================================================
package vfofbuffer_pkg;
  // uop 载荷：入队时整包收下、写回时整包带出，本件不读其中任何字段（robIdx / lastUop / isVleff 除外）。
  // 字段顺序与 golden 寄存器声明顺序一致。
typedef struct packed {
    logic [8:0]    fuOpType;
    logic          vecWen;
    logic          v0Wen;
    logic          vlWen;
    logic          vpu_vill;
    logic          vpu_vma;
    logic          vpu_vta;
    logic [1:0]    vpu_vsew;
    logic [2:0]    vpu_vlmul;
    logic          vpu_specVill;
    logic          vpu_specVma;
    logic          vpu_specVta;
    logic [1:0]    vpu_specVsew;
    logic [2:0]    vpu_specVlmul;
    logic          vpu_vm;
    logic [7:0]    vpu_vstart;
    logic [2:0]    vpu_frm;
    logic          vpu_fpu_isFpToVecInst;
    logic          vpu_fpu_isFP32Instr;
    logic          vpu_fpu_isFP64Instr;
    logic          vpu_fpu_isReduction;
    logic          vpu_fpu_isFoldTo1_2;
    logic          vpu_fpu_isFoldTo1_4;
    logic          vpu_fpu_isFoldTo1_8;
    logic [1:0]    vpu_vxrm;
    logic [6:0]    vpu_vuopIdx;
    logic          vpu_lastUop;
    logic [2:0]    vpu_nf;
    logic [1:0]    vpu_veew;
    logic          vpu_isReverse;
    logic          vpu_isExt;
    logic          vpu_isNarrow;
    logic          vpu_isDstMask;
    logic          vpu_isOpMask;
    logic          vpu_isMove;
    logic          vpu_isDependOldVd;
    logic          vpu_isWritePartVd;
    logic          vpu_isVleff;
    logic [7:0]    pdest;
    logic          robIdx_flag;
    logic [7:0]    robIdx_value;
    logic          debugInfo_eliminatedMove;
    logic [63:0]   debugInfo_renameTime;
    logic [63:0]   debugInfo_dispatchTime;
    logic [63:0]   debugInfo_enqRsTime;
    logic [63:0]   debugInfo_selectTime;
    logic [63:0]   debugInfo_issueTime;
    logic [63:0]   debugInfo_writebackTime;
    logic [63:0]   debugInfo_runahead_checkpoint_id;
    logic [63:0]   debugInfo_tlbFirstReqTime;
    logic [63:0]   debugInfo_tlbRespTime;
    logic [55:0]   debug_seqNum_seqNum;
    logic [7:0]    debug_seqNum_uopIdx;
  } vfof_uop_t;
  // 写回口只带了与本件有关的 6 位 load 异常
  typedef struct packed {
    logic        valid;
    logic        robidx_flag;
    logic [7:0]  robidx_value;
    logic [7:0]  vl;
    logic [5:0]  exception;   // {ev21, ev19, ev13, ev5, ev4, ev3}
  } vfof_wb_t;
endpackage

module xs_VfofBuffer_core
  import vfofbuffer_pkg::*;
(
  input  logic        clock,
  input  logic        reset,
  // redirect（后端冲刷）
  input  logic        redirect_valid,
  input  logic        redirect_robIdx_flag,
  input  logic [7:0]  redirect_robIdx_value,
  input  logic        redirect_level,          // 1 = flushItself：robIdx 相等也冲
  // 入队两个口
  input  logic        in0_valid,
  input  vfof_uop_t   in0_uop,
  input  logic [7:0]  in0_vl,                  // src_4[7:0]：VConfig 的 vl
  input  logic        in1_valid,
  input  vfof_uop_t   in1_uop,
  input  logic [7:0]  in1_vl,
  // 向量 load 合并单元的 uop 写回两个口
  input  vfof_wb_t    wb0,
  input  vfof_wb_t    wb1,
  // 出队
  input  logic        out_ready,
  output logic        out_valid,
  output vfof_uop_t   out_uop,
  output logic [7:0]  out_vl
);
  // ---- 单条目状态 ----
  vfof_uop_t   entries_uop;
  logic [7:0]  entries_vl;
  logic        entries_hasException;
  logic        valid;

  // robIdx 是否被这次 redirect 冲掉：level=1 时相等也冲；否则比 redirect 更年轻才冲
  function automatic logic need_flush(input logic r_valid, input logic r_flag, input logic [7:0] r_value,
                                      input logic r_level, input logic flag, input logic [7:0] value);
    logic is_after;
    is_after   = flag ^ r_flag ^ (value > r_value);
    need_flush = r_valid & ((r_level & ({flag, value} == {r_flag, r_value})) | is_after);
  endfunction

  // ---- §1 入队选择 ----
  logic        enq_isfof0, enq_isfof1, enq_valid, enq_cancel, enq_accept;
  vfof_uop_t   enq_uop;
  logic [7:0]  enq_vl;
  logic        enq_is_fix_vl;   // 进来的是本指令的最后一个 uop（它带着最终要写回的 uop 信息）
  assign enq_isfof0 = in0_valid & in0_uop.vpu_isVleff;
  assign enq_isfof1 = in1_valid & in1_uop.vpu_isVleff;
  assign enq_valid  = enq_isfof0 | enq_isfof1;
  assign enq_uop    = enq_isfof0 ? in0_uop : in1_uop;
  assign enq_vl     = enq_isfof0 ? in0_vl  : in1_vl;
  assign enq_cancel = need_flush(redirect_valid, redirect_robIdx_flag, redirect_robIdx_value, redirect_level,
                                 enq_uop.robIdx_flag, enq_uop.robIdx_value);
  assign enq_accept = enq_valid & ~enq_cancel;
  assign enq_is_fix_vl = enq_uop.vpu_isVleff & enq_uop.vpu_lastUop;

  // ---- §2 写回聚合 ----
  logic        need_redirect;
  logic        wb_hit0, wb_hit1, wb_valid, take0;
  logic        wb_exc0, wb_exc1;
  logic [7:0]  wb_oldest_vl;
  logic        wb_oldest_exc;
  logic        wb_update;
  assign need_redirect = need_flush(redirect_valid, redirect_robIdx_flag, redirect_robIdx_value, redirect_level,
                                    entries_uop.robIdx_flag, entries_uop.robIdx_value);
  assign wb_hit0  = wb0.valid & ({wb0.robidx_flag, wb0.robidx_value} == {entries_uop.robIdx_flag, entries_uop.robIdx_value});
  assign wb_hit1  = wb1.valid & ({wb1.robidx_flag, wb1.robidx_value} == {entries_uop.robIdx_flag, entries_uop.robIdx_value});
  assign wb_exc0  = |wb0.exception;
  assign wb_exc1  = |wb1.exception;
  assign wb_valid = wb_hit0 | wb_hit1;
  // 两口都命中：口 1 的 vl 更大或口 0 带异常，且口 1 不带异常 → 口 0 更老；否则口 1
  assign take0 = (wb_hit0 & wb_hit1) ? (((wb1.vl > wb0.vl) | wb_exc0) & ~wb_exc1)
                                     : (wb_hit0 & ~wb_hit1);
  assign wb_oldest_vl  = take0 ? wb0.vl : wb1.vl;
  assign wb_oldest_exc = take0 ? wb_exc0 : wb_exc1;
  assign wb_update = wb_valid & ((wb_oldest_vl < entries_vl) | wb_oldest_exc)
                   & valid & ~need_redirect & ~entries_hasException;

  // ---- §3 出队 ----
  assign out_valid = valid & entries_uop.vpu_lastUop & entries_uop.vpu_isVleff & ~need_redirect;
  assign out_uop   = entries_uop;
  assign out_vl    = entries_vl;

  // ---- 状态更新 ----
  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      entries_uop          <= '0;
      entries_vl           <= '0;
      entries_hasException <= 1'b0;
      valid                <= 1'b0;
    end else begin
      // uop：条目空时收下；非空时只有本指令的 lastUop 能刷新
      if (enq_accept & (~valid | (valid & enq_is_fix_vl)))
        entries_uop <= enq_uop;
      // vl / hasException：写回更新优先；否则入队到空条目时初始化
      if (wb_update) begin
        entries_vl           <= wb_oldest_vl;
        entries_hasException <= wb_oldest_exc;
      end else if (enq_accept & ~valid) begin
        entries_vl           <= enq_vl;
        entries_hasException <= 1'b0;
      end
      // valid：出队 / 被冲 → 0；否则入队 → 1
      if ((out_ready & out_valid) | need_redirect)
        valid <= 1'b0;
      else if (enq_accept)
        valid <= 1'b1;
    end
  end
endmodule

module VfofBuffer
  import vfofbuffer_pkg::*;
(
  input  logic          clock,
  input  logic          reset,
  input  logic          io_redirect_valid,
  input  logic          io_redirect_bits_robIdx_flag,
  input  logic [7:0]    io_redirect_bits_robIdx_value,
  input  logic          io_redirect_bits_level,
  input  logic          io_in_0_valid,
  input  logic [8:0]    io_in_0_bits_uop_fuOpType,
  input  logic          io_in_0_bits_uop_vecWen,
  input  logic          io_in_0_bits_uop_v0Wen,
  input  logic          io_in_0_bits_uop_vlWen,
  input  logic          io_in_0_bits_uop_vpu_vill,
  input  logic          io_in_0_bits_uop_vpu_vma,
  input  logic          io_in_0_bits_uop_vpu_vta,
  input  logic [1:0]    io_in_0_bits_uop_vpu_vsew,
  input  logic [2:0]    io_in_0_bits_uop_vpu_vlmul,
  input  logic          io_in_0_bits_uop_vpu_specVill,
  input  logic          io_in_0_bits_uop_vpu_specVma,
  input  logic          io_in_0_bits_uop_vpu_specVta,
  input  logic [1:0]    io_in_0_bits_uop_vpu_specVsew,
  input  logic [2:0]    io_in_0_bits_uop_vpu_specVlmul,
  input  logic          io_in_0_bits_uop_vpu_vm,
  input  logic [7:0]    io_in_0_bits_uop_vpu_vstart,
  input  logic [2:0]    io_in_0_bits_uop_vpu_frm,
  input  logic          io_in_0_bits_uop_vpu_fpu_isFpToVecInst,
  input  logic          io_in_0_bits_uop_vpu_fpu_isFP32Instr,
  input  logic          io_in_0_bits_uop_vpu_fpu_isFP64Instr,
  input  logic          io_in_0_bits_uop_vpu_fpu_isReduction,
  input  logic          io_in_0_bits_uop_vpu_fpu_isFoldTo1_2,
  input  logic          io_in_0_bits_uop_vpu_fpu_isFoldTo1_4,
  input  logic          io_in_0_bits_uop_vpu_fpu_isFoldTo1_8,
  input  logic [1:0]    io_in_0_bits_uop_vpu_vxrm,
  input  logic [6:0]    io_in_0_bits_uop_vpu_vuopIdx,
  input  logic          io_in_0_bits_uop_vpu_lastUop,
  input  logic [2:0]    io_in_0_bits_uop_vpu_nf,
  input  logic [1:0]    io_in_0_bits_uop_vpu_veew,
  input  logic          io_in_0_bits_uop_vpu_isReverse,
  input  logic          io_in_0_bits_uop_vpu_isExt,
  input  logic          io_in_0_bits_uop_vpu_isNarrow,
  input  logic          io_in_0_bits_uop_vpu_isDstMask,
  input  logic          io_in_0_bits_uop_vpu_isOpMask,
  input  logic          io_in_0_bits_uop_vpu_isMove,
  input  logic          io_in_0_bits_uop_vpu_isDependOldVd,
  input  logic          io_in_0_bits_uop_vpu_isWritePartVd,
  input  logic          io_in_0_bits_uop_vpu_isVleff,
  input  logic [7:0]    io_in_0_bits_uop_pdest,
  input  logic          io_in_0_bits_uop_robIdx_flag,
  input  logic [7:0]    io_in_0_bits_uop_robIdx_value,
  input  logic          io_in_0_bits_uop_debugInfo_eliminatedMove,
  input  logic [63:0]   io_in_0_bits_uop_debugInfo_renameTime,
  input  logic [63:0]   io_in_0_bits_uop_debugInfo_dispatchTime,
  input  logic [63:0]   io_in_0_bits_uop_debugInfo_enqRsTime,
  input  logic [63:0]   io_in_0_bits_uop_debugInfo_selectTime,
  input  logic [63:0]   io_in_0_bits_uop_debugInfo_issueTime,
  input  logic [63:0]   io_in_0_bits_uop_debugInfo_writebackTime,
  input  logic [63:0]   io_in_0_bits_uop_debugInfo_runahead_checkpoint_id,
  input  logic [63:0]   io_in_0_bits_uop_debugInfo_tlbFirstReqTime,
  input  logic [63:0]   io_in_0_bits_uop_debugInfo_tlbRespTime,
  input  logic [55:0]   io_in_0_bits_uop_debug_seqNum_seqNum,
  input  logic [7:0]    io_in_0_bits_uop_debug_seqNum_uopIdx,
  input  logic [127:0]  io_in_0_bits_src_4,
  input  logic          io_in_1_valid,
  input  logic [8:0]    io_in_1_bits_uop_fuOpType,
  input  logic          io_in_1_bits_uop_vecWen,
  input  logic          io_in_1_bits_uop_v0Wen,
  input  logic          io_in_1_bits_uop_vlWen,
  input  logic          io_in_1_bits_uop_vpu_vill,
  input  logic          io_in_1_bits_uop_vpu_vma,
  input  logic          io_in_1_bits_uop_vpu_vta,
  input  logic [1:0]    io_in_1_bits_uop_vpu_vsew,
  input  logic [2:0]    io_in_1_bits_uop_vpu_vlmul,
  input  logic          io_in_1_bits_uop_vpu_specVill,
  input  logic          io_in_1_bits_uop_vpu_specVma,
  input  logic          io_in_1_bits_uop_vpu_specVta,
  input  logic [1:0]    io_in_1_bits_uop_vpu_specVsew,
  input  logic [2:0]    io_in_1_bits_uop_vpu_specVlmul,
  input  logic          io_in_1_bits_uop_vpu_vm,
  input  logic [7:0]    io_in_1_bits_uop_vpu_vstart,
  input  logic [2:0]    io_in_1_bits_uop_vpu_frm,
  input  logic          io_in_1_bits_uop_vpu_fpu_isFpToVecInst,
  input  logic          io_in_1_bits_uop_vpu_fpu_isFP32Instr,
  input  logic          io_in_1_bits_uop_vpu_fpu_isFP64Instr,
  input  logic          io_in_1_bits_uop_vpu_fpu_isReduction,
  input  logic          io_in_1_bits_uop_vpu_fpu_isFoldTo1_2,
  input  logic          io_in_1_bits_uop_vpu_fpu_isFoldTo1_4,
  input  logic          io_in_1_bits_uop_vpu_fpu_isFoldTo1_8,
  input  logic [1:0]    io_in_1_bits_uop_vpu_vxrm,
  input  logic [6:0]    io_in_1_bits_uop_vpu_vuopIdx,
  input  logic          io_in_1_bits_uop_vpu_lastUop,
  input  logic [2:0]    io_in_1_bits_uop_vpu_nf,
  input  logic [1:0]    io_in_1_bits_uop_vpu_veew,
  input  logic          io_in_1_bits_uop_vpu_isReverse,
  input  logic          io_in_1_bits_uop_vpu_isExt,
  input  logic          io_in_1_bits_uop_vpu_isNarrow,
  input  logic          io_in_1_bits_uop_vpu_isDstMask,
  input  logic          io_in_1_bits_uop_vpu_isOpMask,
  input  logic          io_in_1_bits_uop_vpu_isMove,
  input  logic          io_in_1_bits_uop_vpu_isDependOldVd,
  input  logic          io_in_1_bits_uop_vpu_isWritePartVd,
  input  logic          io_in_1_bits_uop_vpu_isVleff,
  input  logic [7:0]    io_in_1_bits_uop_pdest,
  input  logic          io_in_1_bits_uop_robIdx_flag,
  input  logic [7:0]    io_in_1_bits_uop_robIdx_value,
  input  logic          io_in_1_bits_uop_debugInfo_eliminatedMove,
  input  logic [63:0]   io_in_1_bits_uop_debugInfo_renameTime,
  input  logic [63:0]   io_in_1_bits_uop_debugInfo_dispatchTime,
  input  logic [63:0]   io_in_1_bits_uop_debugInfo_enqRsTime,
  input  logic [63:0]   io_in_1_bits_uop_debugInfo_selectTime,
  input  logic [63:0]   io_in_1_bits_uop_debugInfo_issueTime,
  input  logic [63:0]   io_in_1_bits_uop_debugInfo_writebackTime,
  input  logic [63:0]   io_in_1_bits_uop_debugInfo_runahead_checkpoint_id,
  input  logic [63:0]   io_in_1_bits_uop_debugInfo_tlbFirstReqTime,
  input  logic [63:0]   io_in_1_bits_uop_debugInfo_tlbRespTime,
  input  logic [55:0]   io_in_1_bits_uop_debug_seqNum_seqNum,
  input  logic [7:0]    io_in_1_bits_uop_debug_seqNum_uopIdx,
  input  logic [127:0]  io_in_1_bits_src_4,
  input  logic          io_mergeUopWriteback_0_valid,
  input  logic          io_mergeUopWriteback_0_bits_robidx_flag,
  input  logic [7:0]    io_mergeUopWriteback_0_bits_robidx_value,
  input  logic [7:0]    io_mergeUopWriteback_0_bits_vl,
  input  logic          io_mergeUopWriteback_0_bits_exceptionVec_3,
  input  logic          io_mergeUopWriteback_0_bits_exceptionVec_4,
  input  logic          io_mergeUopWriteback_0_bits_exceptionVec_5,
  input  logic          io_mergeUopWriteback_0_bits_exceptionVec_13,
  input  logic          io_mergeUopWriteback_0_bits_exceptionVec_19,
  input  logic          io_mergeUopWriteback_0_bits_exceptionVec_21,
  input  logic          io_mergeUopWriteback_1_valid,
  input  logic          io_mergeUopWriteback_1_bits_robidx_flag,
  input  logic [7:0]    io_mergeUopWriteback_1_bits_robidx_value,
  input  logic [7:0]    io_mergeUopWriteback_1_bits_vl,
  input  logic          io_mergeUopWriteback_1_bits_exceptionVec_3,
  input  logic          io_mergeUopWriteback_1_bits_exceptionVec_4,
  input  logic          io_mergeUopWriteback_1_bits_exceptionVec_5,
  input  logic          io_mergeUopWriteback_1_bits_exceptionVec_13,
  input  logic          io_mergeUopWriteback_1_bits_exceptionVec_19,
  input  logic          io_mergeUopWriteback_1_bits_exceptionVec_21,
  input  logic          io_uopWriteback_ready,
  output logic          io_uopWriteback_valid,
  output logic [8:0]    io_uopWriteback_bits_uop_fuOpType,
  output logic          io_uopWriteback_bits_uop_vecWen,
  output logic          io_uopWriteback_bits_uop_v0Wen,
  output logic          io_uopWriteback_bits_uop_vlWen,
  output logic          io_uopWriteback_bits_uop_vpu_vill,
  output logic          io_uopWriteback_bits_uop_vpu_vma,
  output logic          io_uopWriteback_bits_uop_vpu_vta,
  output logic [1:0]    io_uopWriteback_bits_uop_vpu_vsew,
  output logic [2:0]    io_uopWriteback_bits_uop_vpu_vlmul,
  output logic          io_uopWriteback_bits_uop_vpu_specVill,
  output logic          io_uopWriteback_bits_uop_vpu_specVma,
  output logic          io_uopWriteback_bits_uop_vpu_specVta,
  output logic [1:0]    io_uopWriteback_bits_uop_vpu_specVsew,
  output logic [2:0]    io_uopWriteback_bits_uop_vpu_specVlmul,
  output logic          io_uopWriteback_bits_uop_vpu_vm,
  output logic [7:0]    io_uopWriteback_bits_uop_vpu_vstart,
  output logic [2:0]    io_uopWriteback_bits_uop_vpu_frm,
  output logic          io_uopWriteback_bits_uop_vpu_fpu_isFpToVecInst,
  output logic          io_uopWriteback_bits_uop_vpu_fpu_isFP32Instr,
  output logic          io_uopWriteback_bits_uop_vpu_fpu_isFP64Instr,
  output logic          io_uopWriteback_bits_uop_vpu_fpu_isReduction,
  output logic          io_uopWriteback_bits_uop_vpu_fpu_isFoldTo1_2,
  output logic          io_uopWriteback_bits_uop_vpu_fpu_isFoldTo1_4,
  output logic          io_uopWriteback_bits_uop_vpu_fpu_isFoldTo1_8,
  output logic [1:0]    io_uopWriteback_bits_uop_vpu_vxrm,
  output logic [6:0]    io_uopWriteback_bits_uop_vpu_vuopIdx,
  output logic          io_uopWriteback_bits_uop_vpu_lastUop,
  output logic [7:0]    io_uopWriteback_bits_uop_vpu_vl,
  output logic [2:0]    io_uopWriteback_bits_uop_vpu_nf,
  output logic [1:0]    io_uopWriteback_bits_uop_vpu_veew,
  output logic          io_uopWriteback_bits_uop_vpu_isReverse,
  output logic          io_uopWriteback_bits_uop_vpu_isExt,
  output logic          io_uopWriteback_bits_uop_vpu_isNarrow,
  output logic          io_uopWriteback_bits_uop_vpu_isDstMask,
  output logic          io_uopWriteback_bits_uop_vpu_isOpMask,
  output logic          io_uopWriteback_bits_uop_vpu_isMove,
  output logic          io_uopWriteback_bits_uop_vpu_isDependOldVd,
  output logic          io_uopWriteback_bits_uop_vpu_isWritePartVd,
  output logic          io_uopWriteback_bits_uop_vpu_isVleff,
  output logic [7:0]    io_uopWriteback_bits_uop_pdest,
  output logic          io_uopWriteback_bits_uop_robIdx_flag,
  output logic [7:0]    io_uopWriteback_bits_uop_robIdx_value,
  output logic          io_uopWriteback_bits_uop_debugInfo_eliminatedMove,
  output logic [63:0]   io_uopWriteback_bits_uop_debugInfo_renameTime,
  output logic [63:0]   io_uopWriteback_bits_uop_debugInfo_dispatchTime,
  output logic [63:0]   io_uopWriteback_bits_uop_debugInfo_enqRsTime,
  output logic [63:0]   io_uopWriteback_bits_uop_debugInfo_selectTime,
  output logic [63:0]   io_uopWriteback_bits_uop_debugInfo_issueTime,
  output logic [63:0]   io_uopWriteback_bits_uop_debugInfo_writebackTime,
  output logic [63:0]   io_uopWriteback_bits_uop_debugInfo_runahead_checkpoint_id,
  output logic [63:0]   io_uopWriteback_bits_uop_debugInfo_tlbFirstReqTime,
  output logic [63:0]   io_uopWriteback_bits_uop_debugInfo_tlbRespTime,
  output logic [55:0]   io_uopWriteback_bits_uop_debug_seqNum_seqNum,
  output logic [7:0]    io_uopWriteback_bits_uop_debug_seqNum_uopIdx,
  output logic [127:0]  io_uopWriteback_bits_data
);
  vfof_uop_t in0_uop, in1_uop, wb_uop;
  vfof_wb_t  wb0, wb1;
  logic [7:0] wb_vl;

  assign in0_uop = '{
    fuOpType: io_in_0_bits_uop_fuOpType,
    vecWen: io_in_0_bits_uop_vecWen,
    v0Wen: io_in_0_bits_uop_v0Wen,
    vlWen: io_in_0_bits_uop_vlWen,
    vpu_vill: io_in_0_bits_uop_vpu_vill,
    vpu_vma: io_in_0_bits_uop_vpu_vma,
    vpu_vta: io_in_0_bits_uop_vpu_vta,
    vpu_vsew: io_in_0_bits_uop_vpu_vsew,
    vpu_vlmul: io_in_0_bits_uop_vpu_vlmul,
    vpu_specVill: io_in_0_bits_uop_vpu_specVill,
    vpu_specVma: io_in_0_bits_uop_vpu_specVma,
    vpu_specVta: io_in_0_bits_uop_vpu_specVta,
    vpu_specVsew: io_in_0_bits_uop_vpu_specVsew,
    vpu_specVlmul: io_in_0_bits_uop_vpu_specVlmul,
    vpu_vm: io_in_0_bits_uop_vpu_vm,
    vpu_vstart: io_in_0_bits_uop_vpu_vstart,
    vpu_frm: io_in_0_bits_uop_vpu_frm,
    vpu_fpu_isFpToVecInst: io_in_0_bits_uop_vpu_fpu_isFpToVecInst,
    vpu_fpu_isFP32Instr: io_in_0_bits_uop_vpu_fpu_isFP32Instr,
    vpu_fpu_isFP64Instr: io_in_0_bits_uop_vpu_fpu_isFP64Instr,
    vpu_fpu_isReduction: io_in_0_bits_uop_vpu_fpu_isReduction,
    vpu_fpu_isFoldTo1_2: io_in_0_bits_uop_vpu_fpu_isFoldTo1_2,
    vpu_fpu_isFoldTo1_4: io_in_0_bits_uop_vpu_fpu_isFoldTo1_4,
    vpu_fpu_isFoldTo1_8: io_in_0_bits_uop_vpu_fpu_isFoldTo1_8,
    vpu_vxrm: io_in_0_bits_uop_vpu_vxrm,
    vpu_vuopIdx: io_in_0_bits_uop_vpu_vuopIdx,
    vpu_lastUop: io_in_0_bits_uop_vpu_lastUop,
    vpu_nf: io_in_0_bits_uop_vpu_nf,
    vpu_veew: io_in_0_bits_uop_vpu_veew,
    vpu_isReverse: io_in_0_bits_uop_vpu_isReverse,
    vpu_isExt: io_in_0_bits_uop_vpu_isExt,
    vpu_isNarrow: io_in_0_bits_uop_vpu_isNarrow,
    vpu_isDstMask: io_in_0_bits_uop_vpu_isDstMask,
    vpu_isOpMask: io_in_0_bits_uop_vpu_isOpMask,
    vpu_isMove: io_in_0_bits_uop_vpu_isMove,
    vpu_isDependOldVd: io_in_0_bits_uop_vpu_isDependOldVd,
    vpu_isWritePartVd: io_in_0_bits_uop_vpu_isWritePartVd,
    vpu_isVleff: io_in_0_bits_uop_vpu_isVleff,
    pdest: io_in_0_bits_uop_pdest,
    robIdx_flag: io_in_0_bits_uop_robIdx_flag,
    robIdx_value: io_in_0_bits_uop_robIdx_value,
    debugInfo_eliminatedMove: io_in_0_bits_uop_debugInfo_eliminatedMove,
    debugInfo_renameTime: io_in_0_bits_uop_debugInfo_renameTime,
    debugInfo_dispatchTime: io_in_0_bits_uop_debugInfo_dispatchTime,
    debugInfo_enqRsTime: io_in_0_bits_uop_debugInfo_enqRsTime,
    debugInfo_selectTime: io_in_0_bits_uop_debugInfo_selectTime,
    debugInfo_issueTime: io_in_0_bits_uop_debugInfo_issueTime,
    debugInfo_writebackTime: io_in_0_bits_uop_debugInfo_writebackTime,
    debugInfo_runahead_checkpoint_id: io_in_0_bits_uop_debugInfo_runahead_checkpoint_id,
    debugInfo_tlbFirstReqTime: io_in_0_bits_uop_debugInfo_tlbFirstReqTime,
    debugInfo_tlbRespTime: io_in_0_bits_uop_debugInfo_tlbRespTime,
    debug_seqNum_seqNum: io_in_0_bits_uop_debug_seqNum_seqNum,
    debug_seqNum_uopIdx: io_in_0_bits_uop_debug_seqNum_uopIdx
  };
  assign in1_uop = '{
    fuOpType: io_in_1_bits_uop_fuOpType,
    vecWen: io_in_1_bits_uop_vecWen,
    v0Wen: io_in_1_bits_uop_v0Wen,
    vlWen: io_in_1_bits_uop_vlWen,
    vpu_vill: io_in_1_bits_uop_vpu_vill,
    vpu_vma: io_in_1_bits_uop_vpu_vma,
    vpu_vta: io_in_1_bits_uop_vpu_vta,
    vpu_vsew: io_in_1_bits_uop_vpu_vsew,
    vpu_vlmul: io_in_1_bits_uop_vpu_vlmul,
    vpu_specVill: io_in_1_bits_uop_vpu_specVill,
    vpu_specVma: io_in_1_bits_uop_vpu_specVma,
    vpu_specVta: io_in_1_bits_uop_vpu_specVta,
    vpu_specVsew: io_in_1_bits_uop_vpu_specVsew,
    vpu_specVlmul: io_in_1_bits_uop_vpu_specVlmul,
    vpu_vm: io_in_1_bits_uop_vpu_vm,
    vpu_vstart: io_in_1_bits_uop_vpu_vstart,
    vpu_frm: io_in_1_bits_uop_vpu_frm,
    vpu_fpu_isFpToVecInst: io_in_1_bits_uop_vpu_fpu_isFpToVecInst,
    vpu_fpu_isFP32Instr: io_in_1_bits_uop_vpu_fpu_isFP32Instr,
    vpu_fpu_isFP64Instr: io_in_1_bits_uop_vpu_fpu_isFP64Instr,
    vpu_fpu_isReduction: io_in_1_bits_uop_vpu_fpu_isReduction,
    vpu_fpu_isFoldTo1_2: io_in_1_bits_uop_vpu_fpu_isFoldTo1_2,
    vpu_fpu_isFoldTo1_4: io_in_1_bits_uop_vpu_fpu_isFoldTo1_4,
    vpu_fpu_isFoldTo1_8: io_in_1_bits_uop_vpu_fpu_isFoldTo1_8,
    vpu_vxrm: io_in_1_bits_uop_vpu_vxrm,
    vpu_vuopIdx: io_in_1_bits_uop_vpu_vuopIdx,
    vpu_lastUop: io_in_1_bits_uop_vpu_lastUop,
    vpu_nf: io_in_1_bits_uop_vpu_nf,
    vpu_veew: io_in_1_bits_uop_vpu_veew,
    vpu_isReverse: io_in_1_bits_uop_vpu_isReverse,
    vpu_isExt: io_in_1_bits_uop_vpu_isExt,
    vpu_isNarrow: io_in_1_bits_uop_vpu_isNarrow,
    vpu_isDstMask: io_in_1_bits_uop_vpu_isDstMask,
    vpu_isOpMask: io_in_1_bits_uop_vpu_isOpMask,
    vpu_isMove: io_in_1_bits_uop_vpu_isMove,
    vpu_isDependOldVd: io_in_1_bits_uop_vpu_isDependOldVd,
    vpu_isWritePartVd: io_in_1_bits_uop_vpu_isWritePartVd,
    vpu_isVleff: io_in_1_bits_uop_vpu_isVleff,
    pdest: io_in_1_bits_uop_pdest,
    robIdx_flag: io_in_1_bits_uop_robIdx_flag,
    robIdx_value: io_in_1_bits_uop_robIdx_value,
    debugInfo_eliminatedMove: io_in_1_bits_uop_debugInfo_eliminatedMove,
    debugInfo_renameTime: io_in_1_bits_uop_debugInfo_renameTime,
    debugInfo_dispatchTime: io_in_1_bits_uop_debugInfo_dispatchTime,
    debugInfo_enqRsTime: io_in_1_bits_uop_debugInfo_enqRsTime,
    debugInfo_selectTime: io_in_1_bits_uop_debugInfo_selectTime,
    debugInfo_issueTime: io_in_1_bits_uop_debugInfo_issueTime,
    debugInfo_writebackTime: io_in_1_bits_uop_debugInfo_writebackTime,
    debugInfo_runahead_checkpoint_id: io_in_1_bits_uop_debugInfo_runahead_checkpoint_id,
    debugInfo_tlbFirstReqTime: io_in_1_bits_uop_debugInfo_tlbFirstReqTime,
    debugInfo_tlbRespTime: io_in_1_bits_uop_debugInfo_tlbRespTime,
    debug_seqNum_seqNum: io_in_1_bits_uop_debug_seqNum_seqNum,
    debug_seqNum_uopIdx: io_in_1_bits_uop_debug_seqNum_uopIdx
  };
  assign wb0 = '{valid: io_mergeUopWriteback_0_valid, robidx_flag: io_mergeUopWriteback_0_bits_robidx_flag,
                 robidx_value: io_mergeUopWriteback_0_bits_robidx_value, vl: io_mergeUopWriteback_0_bits_vl,
                 exception: {io_mergeUopWriteback_0_bits_exceptionVec_21, io_mergeUopWriteback_0_bits_exceptionVec_19,
                             io_mergeUopWriteback_0_bits_exceptionVec_13, io_mergeUopWriteback_0_bits_exceptionVec_5,
                             io_mergeUopWriteback_0_bits_exceptionVec_4,  io_mergeUopWriteback_0_bits_exceptionVec_3}};
  assign wb1 = '{valid: io_mergeUopWriteback_1_valid, robidx_flag: io_mergeUopWriteback_1_bits_robidx_flag,
                 robidx_value: io_mergeUopWriteback_1_bits_robidx_value, vl: io_mergeUopWriteback_1_bits_vl,
                 exception: {io_mergeUopWriteback_1_bits_exceptionVec_21, io_mergeUopWriteback_1_bits_exceptionVec_19,
                             io_mergeUopWriteback_1_bits_exceptionVec_13, io_mergeUopWriteback_1_bits_exceptionVec_5,
                             io_mergeUopWriteback_1_bits_exceptionVec_4,  io_mergeUopWriteback_1_bits_exceptionVec_3}};

  xs_VfofBuffer_core u_core (
    .clock                 (clock),
    .reset                 (reset),
    .redirect_valid        (io_redirect_valid),
    .redirect_robIdx_flag  (io_redirect_bits_robIdx_flag),
    .redirect_robIdx_value (io_redirect_bits_robIdx_value),
    .redirect_level        (io_redirect_bits_level),
    .in0_valid             (io_in_0_valid),
    .in0_uop               (in0_uop),
    .in0_vl                (io_in_0_bits_src_4[7:0]),
    .in1_valid             (io_in_1_valid),
    .in1_uop               (in1_uop),
    .in1_vl                (io_in_1_bits_src_4[7:0]),
    .wb0                   (wb0),
    .wb1                   (wb1),
    .out_ready             (io_uopWriteback_ready),
    .out_valid             (io_uopWriteback_valid),
    .out_uop               (wb_uop),
    .out_vl                (wb_vl)
  );

  assign io_uopWriteback_bits_uop_fuOpType = wb_uop.fuOpType;
  assign io_uopWriteback_bits_uop_vecWen = wb_uop.vecWen;
  assign io_uopWriteback_bits_uop_v0Wen = wb_uop.v0Wen;
  assign io_uopWriteback_bits_uop_vlWen = wb_uop.vlWen;
  assign io_uopWriteback_bits_uop_vpu_vill = wb_uop.vpu_vill;
  assign io_uopWriteback_bits_uop_vpu_vma = wb_uop.vpu_vma;
  assign io_uopWriteback_bits_uop_vpu_vta = wb_uop.vpu_vta;
  assign io_uopWriteback_bits_uop_vpu_vsew = wb_uop.vpu_vsew;
  assign io_uopWriteback_bits_uop_vpu_vlmul = wb_uop.vpu_vlmul;
  assign io_uopWriteback_bits_uop_vpu_specVill = wb_uop.vpu_specVill;
  assign io_uopWriteback_bits_uop_vpu_specVma = wb_uop.vpu_specVma;
  assign io_uopWriteback_bits_uop_vpu_specVta = wb_uop.vpu_specVta;
  assign io_uopWriteback_bits_uop_vpu_specVsew = wb_uop.vpu_specVsew;
  assign io_uopWriteback_bits_uop_vpu_specVlmul = wb_uop.vpu_specVlmul;
  assign io_uopWriteback_bits_uop_vpu_vm = wb_uop.vpu_vm;
  assign io_uopWriteback_bits_uop_vpu_vstart = wb_uop.vpu_vstart;
  assign io_uopWriteback_bits_uop_vpu_frm = wb_uop.vpu_frm;
  assign io_uopWriteback_bits_uop_vpu_fpu_isFpToVecInst = wb_uop.vpu_fpu_isFpToVecInst;
  assign io_uopWriteback_bits_uop_vpu_fpu_isFP32Instr = wb_uop.vpu_fpu_isFP32Instr;
  assign io_uopWriteback_bits_uop_vpu_fpu_isFP64Instr = wb_uop.vpu_fpu_isFP64Instr;
  assign io_uopWriteback_bits_uop_vpu_fpu_isReduction = wb_uop.vpu_fpu_isReduction;
  assign io_uopWriteback_bits_uop_vpu_fpu_isFoldTo1_2 = wb_uop.vpu_fpu_isFoldTo1_2;
  assign io_uopWriteback_bits_uop_vpu_fpu_isFoldTo1_4 = wb_uop.vpu_fpu_isFoldTo1_4;
  assign io_uopWriteback_bits_uop_vpu_fpu_isFoldTo1_8 = wb_uop.vpu_fpu_isFoldTo1_8;
  assign io_uopWriteback_bits_uop_vpu_vxrm = wb_uop.vpu_vxrm;
  assign io_uopWriteback_bits_uop_vpu_vuopIdx = wb_uop.vpu_vuopIdx;
  assign io_uopWriteback_bits_uop_vpu_lastUop = wb_uop.vpu_lastUop;
  assign io_uopWriteback_bits_uop_vpu_vl = wb_vl;
  assign io_uopWriteback_bits_uop_vpu_nf = wb_uop.vpu_nf;
  assign io_uopWriteback_bits_uop_vpu_veew = wb_uop.vpu_veew;
  assign io_uopWriteback_bits_uop_vpu_isReverse = wb_uop.vpu_isReverse;
  assign io_uopWriteback_bits_uop_vpu_isExt = wb_uop.vpu_isExt;
  assign io_uopWriteback_bits_uop_vpu_isNarrow = wb_uop.vpu_isNarrow;
  assign io_uopWriteback_bits_uop_vpu_isDstMask = wb_uop.vpu_isDstMask;
  assign io_uopWriteback_bits_uop_vpu_isOpMask = wb_uop.vpu_isOpMask;
  assign io_uopWriteback_bits_uop_vpu_isMove = wb_uop.vpu_isMove;
  assign io_uopWriteback_bits_uop_vpu_isDependOldVd = wb_uop.vpu_isDependOldVd;
  assign io_uopWriteback_bits_uop_vpu_isWritePartVd = wb_uop.vpu_isWritePartVd;
  assign io_uopWriteback_bits_uop_vpu_isVleff = wb_uop.vpu_isVleff;
  assign io_uopWriteback_bits_uop_pdest = wb_uop.pdest;
  assign io_uopWriteback_bits_uop_robIdx_flag = wb_uop.robIdx_flag;
  assign io_uopWriteback_bits_uop_robIdx_value = wb_uop.robIdx_value;
  assign io_uopWriteback_bits_uop_debugInfo_eliminatedMove = wb_uop.debugInfo_eliminatedMove;
  assign io_uopWriteback_bits_uop_debugInfo_renameTime = wb_uop.debugInfo_renameTime;
  assign io_uopWriteback_bits_uop_debugInfo_dispatchTime = wb_uop.debugInfo_dispatchTime;
  assign io_uopWriteback_bits_uop_debugInfo_enqRsTime = wb_uop.debugInfo_enqRsTime;
  assign io_uopWriteback_bits_uop_debugInfo_selectTime = wb_uop.debugInfo_selectTime;
  assign io_uopWriteback_bits_uop_debugInfo_issueTime = wb_uop.debugInfo_issueTime;
  assign io_uopWriteback_bits_uop_debugInfo_writebackTime = wb_uop.debugInfo_writebackTime;
  assign io_uopWriteback_bits_uop_debugInfo_runahead_checkpoint_id = wb_uop.debugInfo_runahead_checkpoint_id;
  assign io_uopWriteback_bits_uop_debugInfo_tlbFirstReqTime = wb_uop.debugInfo_tlbFirstReqTime;
  assign io_uopWriteback_bits_uop_debugInfo_tlbRespTime = wb_uop.debugInfo_tlbRespTime;
  assign io_uopWriteback_bits_uop_debug_seqNum_seqNum = wb_uop.debug_seqNum_seqNum;
  assign io_uopWriteback_bits_uop_debug_seqNum_uopIdx = wb_uop.debug_seqNum_uopIdx;
  assign io_uopWriteback_bits_data = {120'b0, wb_vl};
endmodule
