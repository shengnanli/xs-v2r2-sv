// =============================================================================
// Og2ForVector.sv —— 向量/向量访存发射通路的 OG2 级流水寄存器
//
// 位置：香山后端 DataPath 之后、向量 EXU 之前。浮点/向量运算三个 IQ（5 个 EXU 口）和向量访存
//   两个 IQ（2 个口）的 uop 在 OG1 读完寄存器堆后，在这里再打一拍（OG2）才送进 EXU。
//   每个口（本文件叫"通道" ch）做三件事：
//     (1) 打拍：OG1 来的 uop 若没被冲刷，就整包（payload，~1400~1600 位）锁进 s2 寄存器，
//         下一拍从 toExu 口原样送出；valid 单独一拍。
//     (2) 冲刷：uop 的 robIdx 若比本拍的 redirect 或上一拍的 redirect 更"年轻"（或就是被
//         flushItself 的那条），本拍就不进 OG2。上一拍的 redirect 每个通道各自打一份拍
//         （Scala 在通道循环里调用 RegNextWithEnable，golden 里就是 7 份独立寄存器）。
//     (3) 回应 IQ（og2Resp）：OG2 有效但 EXU 没 ready ⇒ block（让 IQ 重发）；否则运算口报
//         success、访存口报 uncertain（访存最终结果另有回应）。访存口的回应还带 robIdx /
//         fuType / uopIdx。
//   另外有一路立即数信息（ImmInfo）随通道 1 的 valid 打拍送 BypassNetwork（golden 里其他通道的
//   ImmInfo 下游没人用，已被 firtool 删掉，只剩通道 1）。
// 打包约定：wrapper 把每个通道的 bits 字段按固定顺序拼成 payload：
//   [8:0] = {robIdx.flag, robIdx.value}，[43:9] = fuType，[50:44] = vpu.vuopIdx，其后是其余字段
//   （golden 端口顺序）。核只认识前三个字段，其余字段对核是透明的"货"。
// 怪癖（照 golden）：s2 valid/payload 与 ImmInfo 寄存器都不复位；上一拍 redirect 的 valid
//   异步复位，bits 只在 redirect 有效时采样；OG1 的 ready 恒为 1（Scala s1_ready := true，端口已删）；
//   KunminghuV2Config 下这些通道没有 loadDependency，LoadShouldCancel 恒假（ldCancel 口已删）。
// Chisel 源：src/main/scala/xiangshan/backend/datapath/Og2ForVector.scala。
// golden 对照：G1-canonical/golden-rtl/Og2ForVector.sv（无子模块）。
// 机械区（package 里的通道宽度表、wrapper、FM 钉点、UT tb）由 scripts/gen_og2forvector.py 生成。
// =============================================================================
package og2forvector_pkg;
  // payload 里核要用到的三个字段的位置（所有通道相同）
  localparam int ROB_LSB    = 0;    // {flag, value[7:0]}，9 位
  localparam int FUTYPE_LSB = 9;    // 35 位
  localparam int UOPIDX_LSB = 44;   // 7 位
  // BEGIN GENERATED(og2-params)
  // 通道 k 的顺序 = Scala fromOg1VfArith ++ fromOg1VecMem 展平：
  //   0: fromOg1VfArith_0_0     -> toVfArithExu_0_0     payload 1391 位
  //   1: fromOg1VfArith_0_1     -> toVfArithExu_0_1     payload 1397 位
  //   2: fromOg1VfArith_1_0     -> toVfArithExu_1_0     payload 1391 位
  //   3: fromOg1VfArith_1_1     -> toVfArithExu_1_1     payload 1395 位
  //   4: fromOg1VfArith_2_0     -> toVfArithExu_2_0     payload 1391 位
  //   5: fromOg1VecMem_0_0      -> toVecMemExu_0_0      payload 1603 位（访存）
  //   6: fromOg1VecMem_1_0      -> toVecMemExu_1_0      payload 1603 位（访存）
  localparam int NCH      = 7;
  localparam int PW [NCH] = '{1391, 1397, 1391, 1395, 1391, 1603, 1603};
  localparam int PO [NCH] = '{0, 1391, 2788, 4179, 5574, 6965, 8568};
  localparam int PW_TOTAL = 10171;
  localparam bit IS_MEM [NCH] = '{1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b1, 1'b1};
  localparam int IMM_CH   = 1;
  // END GENERATED
endpackage

module xs_Og2ForVector_core
  import og2forvector_pkg::*;
(
  input  logic                clock,
  input  logic                reset,
  // 本拍 redirect
  input  logic                flush_valid,
  input  logic [8:0]          flush_rob_idx,     // {flag, value}
  input  logic                flush_level,       // 1 = flushItself（连 robIdx 那条自己也冲掉）
  // OG1 -> OG2
  input  logic [NCH-1:0]      in_valid,
  input  logic [PW_TOTAL-1:0] in_payload,        // 各通道 payload 首尾相接，通道 k 在 [PO[k] +: PW[k]]
  // OG2 -> EXU
  input  logic [NCH-1:0]      exu_ready,
  output logic [NCH-1:0]      out_valid,
  output logic [PW_TOTAL-1:0] out_payload,
  // OG2 -> IQ 回应
  output logic [NCH-1:0][1:0] resp,
  // ImmInfo（只剩通道 IMM_CH 一路）
  input  logic [31:0]         imm_in,
  input  logic [3:0]          imm_type_in,
  output logic [31:0]         imm_out,
  output logic [3:0]          imm_type_out
);

  // RespType（xiangshan.backend.issue.EntryBundles）
  localparam logic [1:0] RESP_BLOCK     = 2'd0;
  localparam logic [1:0] RESP_UNCERTAIN = 2'd1;
  localparam logic [1:0] RESP_SUCCESS   = 2'd3;

  // RobPtr.needFlush：redirect 有效，且 (flushItself 且正是那条) 或 uop 比 redirect 年轻（isAfter）
  // isAfter(a, b) = (a.flag ^ b.flag) ^ (a.value > b.value)
  function automatic logic need_flush(input logic       r_valid,
                                      input logic [8:0] r_rob,
                                      input logic       r_level,
                                      input logic [8:0] rob);
    logic is_after;
    is_after   = (rob[8] ^ r_rob[8]) ^ (rob[7:0] > r_rob[7:0]);
    need_flush = r_valid & ((r_level & (rob == r_rob)) | is_after);
  endfunction

  for (genvar k = 0; k < NCH; k++) begin : g_ch
    // ---- 上一拍的 redirect（每个通道一份） ----
    logic       flush_d_valid_q;
    logic [8:0] flush_d_rob_q;
    logic       flush_d_level_q;
    always_ff @(posedge clock or posedge reset) begin
      if (reset) flush_d_valid_q <= 1'b0;
      else       flush_d_valid_q <= flush_valid;
    end
    always_ff @(posedge clock) begin
      if (flush_valid) begin
        flush_d_rob_q   <= flush_rob_idx;
        flush_d_level_q <= flush_level;
      end
    end

    // ---- OG1 -> OG2：没被这拍或上拍的 redirect 冲掉就锁进来 ----
    logic [8:0]     in_rob;
    logic           enter;
    assign in_rob = in_payload[PO[k] + ROB_LSB +: 9];
    assign enter  = in_valid[k]
                  & ~need_flush(flush_d_valid_q, flush_d_rob_q, flush_d_level_q, in_rob)
                  & ~need_flush(flush_valid, flush_rob_idx, flush_level, in_rob);

    logic           valid_q;
    logic [PW[k]-1:0] payload_q;
    always_ff @(posedge clock) begin
      valid_q <= enter;
      if (enter) payload_q <= in_payload[PO[k] +: PW[k]];
    end

    // ---- OG2 -> EXU 与 IQ 回应 ----
    assign out_valid[k]               = valid_q;
    assign out_payload[PO[k] +: PW[k]] = payload_q;
    assign resp[k] = (valid_q & ~exu_ready[k]) ? RESP_BLOCK
                   : IS_MEM[k]                 ? RESP_UNCERTAIN
                   :                             RESP_SUCCESS;
  end

  // ---- ImmInfo：随通道 IMM_CH 的 OG1 valid 打拍（不看冲刷） ----
  logic [31:0] imm_q;
  logic [3:0]  imm_type_q;
  always_ff @(posedge clock) begin
    if (in_valid[IMM_CH]) begin
      imm_q      <= imm_in;
      imm_type_q <= imm_type_in;
    end
  end
  assign imm_out      = imm_q;
  assign imm_type_out = imm_type_q;

endmodule

// BEGIN GENERATED(og2-wrapper)
module Og2ForVector (
  input          clock,
  input          reset,
  input          io_flush_valid,
  input          io_flush_bits_robIdx_flag,
  input  [7:0]   io_flush_bits_robIdx_value,
  input          io_flush_bits_level,
  input          io_fromOg1VfArith_2_0_valid,
  input  [34:0]  io_fromOg1VfArith_2_0_bits_fuType,
  input  [8:0]   io_fromOg1VfArith_2_0_bits_fuOpType,
  input  [127:0] io_fromOg1VfArith_2_0_bits_src_0,
  input  [127:0] io_fromOg1VfArith_2_0_bits_src_1,
  input  [127:0] io_fromOg1VfArith_2_0_bits_src_2,
  input  [127:0] io_fromOg1VfArith_2_0_bits_src_3,
  input  [127:0] io_fromOg1VfArith_2_0_bits_src_4,
  input          io_fromOg1VfArith_2_0_bits_robIdx_flag,
  input  [7:0]   io_fromOg1VfArith_2_0_bits_robIdx_value,
  input  [6:0]   io_fromOg1VfArith_2_0_bits_pdest,
  input          io_fromOg1VfArith_2_0_bits_vecWen,
  input          io_fromOg1VfArith_2_0_bits_v0Wen,
  input          io_fromOg1VfArith_2_0_bits_fpu_wflags,
  input          io_fromOg1VfArith_2_0_bits_vpu_vma,
  input          io_fromOg1VfArith_2_0_bits_vpu_vta,
  input  [1:0]   io_fromOg1VfArith_2_0_bits_vpu_vsew,
  input  [2:0]   io_fromOg1VfArith_2_0_bits_vpu_vlmul,
  input          io_fromOg1VfArith_2_0_bits_vpu_vm,
  input  [7:0]   io_fromOg1VfArith_2_0_bits_vpu_vstart,
  input  [6:0]   io_fromOg1VfArith_2_0_bits_vpu_vuopIdx,
  input          io_fromOg1VfArith_2_0_bits_vpu_isExt,
  input          io_fromOg1VfArith_2_0_bits_vpu_isNarrow,
  input          io_fromOg1VfArith_2_0_bits_vpu_isDstMask,
  input          io_fromOg1VfArith_2_0_bits_vpu_isOpMask,
  input  [3:0]   io_fromOg1VfArith_2_0_bits_dataSources_0_value,
  input  [3:0]   io_fromOg1VfArith_2_0_bits_dataSources_1_value,
  input  [3:0]   io_fromOg1VfArith_2_0_bits_dataSources_2_value,
  input  [3:0]   io_fromOg1VfArith_2_0_bits_dataSources_3_value,
  input  [3:0]   io_fromOg1VfArith_2_0_bits_dataSources_4_value,
  input          io_fromOg1VfArith_2_0_bits_perfDebugInfo_eliminatedMove,
  input  [63:0]  io_fromOg1VfArith_2_0_bits_perfDebugInfo_renameTime,
  input  [63:0]  io_fromOg1VfArith_2_0_bits_perfDebugInfo_dispatchTime,
  input  [63:0]  io_fromOg1VfArith_2_0_bits_perfDebugInfo_enqRsTime,
  input  [63:0]  io_fromOg1VfArith_2_0_bits_perfDebugInfo_selectTime,
  input  [63:0]  io_fromOg1VfArith_2_0_bits_perfDebugInfo_issueTime,
  input  [63:0]  io_fromOg1VfArith_2_0_bits_perfDebugInfo_writebackTime,
  input  [63:0]  io_fromOg1VfArith_2_0_bits_perfDebugInfo_runahead_checkpoint_id,
  input  [63:0]  io_fromOg1VfArith_2_0_bits_perfDebugInfo_tlbFirstReqTime,
  input  [63:0]  io_fromOg1VfArith_2_0_bits_perfDebugInfo_tlbRespTime,
  input  [55:0]  io_fromOg1VfArith_2_0_bits_debug_seqNum_seqNum,
  input  [7:0]   io_fromOg1VfArith_2_0_bits_debug_seqNum_uopIdx,
  input          io_fromOg1VfArith_1_1_valid,
  input  [34:0]  io_fromOg1VfArith_1_1_bits_fuType,
  input  [8:0]   io_fromOg1VfArith_1_1_bits_fuOpType,
  input  [127:0] io_fromOg1VfArith_1_1_bits_src_0,
  input  [127:0] io_fromOg1VfArith_1_1_bits_src_1,
  input  [127:0] io_fromOg1VfArith_1_1_bits_src_2,
  input  [127:0] io_fromOg1VfArith_1_1_bits_src_3,
  input  [127:0] io_fromOg1VfArith_1_1_bits_src_4,
  input          io_fromOg1VfArith_1_1_bits_robIdx_flag,
  input  [7:0]   io_fromOg1VfArith_1_1_bits_robIdx_value,
  input  [7:0]   io_fromOg1VfArith_1_1_bits_pdest,
  input          io_fromOg1VfArith_1_1_bits_fpWen,
  input          io_fromOg1VfArith_1_1_bits_vecWen,
  input          io_fromOg1VfArith_1_1_bits_v0Wen,
  input          io_fromOg1VfArith_1_1_bits_fpu_wflags,
  input          io_fromOg1VfArith_1_1_bits_vpu_vma,
  input          io_fromOg1VfArith_1_1_bits_vpu_vta,
  input  [1:0]   io_fromOg1VfArith_1_1_bits_vpu_vsew,
  input  [2:0]   io_fromOg1VfArith_1_1_bits_vpu_vlmul,
  input          io_fromOg1VfArith_1_1_bits_vpu_vm,
  input  [7:0]   io_fromOg1VfArith_1_1_bits_vpu_vstart,
  input          io_fromOg1VfArith_1_1_bits_vpu_fpu_isFoldTo1_2,
  input          io_fromOg1VfArith_1_1_bits_vpu_fpu_isFoldTo1_4,
  input          io_fromOg1VfArith_1_1_bits_vpu_fpu_isFoldTo1_8,
  input  [6:0]   io_fromOg1VfArith_1_1_bits_vpu_vuopIdx,
  input          io_fromOg1VfArith_1_1_bits_vpu_lastUop,
  input          io_fromOg1VfArith_1_1_bits_vpu_isNarrow,
  input          io_fromOg1VfArith_1_1_bits_vpu_isDstMask,
  input  [3:0]   io_fromOg1VfArith_1_1_bits_dataSources_0_value,
  input  [3:0]   io_fromOg1VfArith_1_1_bits_dataSources_1_value,
  input  [3:0]   io_fromOg1VfArith_1_1_bits_dataSources_2_value,
  input  [3:0]   io_fromOg1VfArith_1_1_bits_dataSources_3_value,
  input  [3:0]   io_fromOg1VfArith_1_1_bits_dataSources_4_value,
  input          io_fromOg1VfArith_1_1_bits_perfDebugInfo_eliminatedMove,
  input  [63:0]  io_fromOg1VfArith_1_1_bits_perfDebugInfo_renameTime,
  input  [63:0]  io_fromOg1VfArith_1_1_bits_perfDebugInfo_dispatchTime,
  input  [63:0]  io_fromOg1VfArith_1_1_bits_perfDebugInfo_enqRsTime,
  input  [63:0]  io_fromOg1VfArith_1_1_bits_perfDebugInfo_selectTime,
  input  [63:0]  io_fromOg1VfArith_1_1_bits_perfDebugInfo_issueTime,
  input  [63:0]  io_fromOg1VfArith_1_1_bits_perfDebugInfo_writebackTime,
  input  [63:0]  io_fromOg1VfArith_1_1_bits_perfDebugInfo_runahead_checkpoint_id,
  input  [63:0]  io_fromOg1VfArith_1_1_bits_perfDebugInfo_tlbFirstReqTime,
  input  [63:0]  io_fromOg1VfArith_1_1_bits_perfDebugInfo_tlbRespTime,
  input  [55:0]  io_fromOg1VfArith_1_1_bits_debug_seqNum_seqNum,
  input  [7:0]   io_fromOg1VfArith_1_1_bits_debug_seqNum_uopIdx,
  input          io_fromOg1VfArith_1_0_valid,
  input  [34:0]  io_fromOg1VfArith_1_0_bits_fuType,
  input  [8:0]   io_fromOg1VfArith_1_0_bits_fuOpType,
  input  [127:0] io_fromOg1VfArith_1_0_bits_src_0,
  input  [127:0] io_fromOg1VfArith_1_0_bits_src_1,
  input  [127:0] io_fromOg1VfArith_1_0_bits_src_2,
  input  [127:0] io_fromOg1VfArith_1_0_bits_src_3,
  input  [127:0] io_fromOg1VfArith_1_0_bits_src_4,
  input          io_fromOg1VfArith_1_0_bits_robIdx_flag,
  input  [7:0]   io_fromOg1VfArith_1_0_bits_robIdx_value,
  input  [6:0]   io_fromOg1VfArith_1_0_bits_pdest,
  input          io_fromOg1VfArith_1_0_bits_vecWen,
  input          io_fromOg1VfArith_1_0_bits_v0Wen,
  input          io_fromOg1VfArith_1_0_bits_fpu_wflags,
  input          io_fromOg1VfArith_1_0_bits_vpu_vma,
  input          io_fromOg1VfArith_1_0_bits_vpu_vta,
  input  [1:0]   io_fromOg1VfArith_1_0_bits_vpu_vsew,
  input  [2:0]   io_fromOg1VfArith_1_0_bits_vpu_vlmul,
  input          io_fromOg1VfArith_1_0_bits_vpu_vm,
  input  [7:0]   io_fromOg1VfArith_1_0_bits_vpu_vstart,
  input  [6:0]   io_fromOg1VfArith_1_0_bits_vpu_vuopIdx,
  input          io_fromOg1VfArith_1_0_bits_vpu_isExt,
  input          io_fromOg1VfArith_1_0_bits_vpu_isNarrow,
  input          io_fromOg1VfArith_1_0_bits_vpu_isDstMask,
  input          io_fromOg1VfArith_1_0_bits_vpu_isOpMask,
  input  [3:0]   io_fromOg1VfArith_1_0_bits_dataSources_0_value,
  input  [3:0]   io_fromOg1VfArith_1_0_bits_dataSources_1_value,
  input  [3:0]   io_fromOg1VfArith_1_0_bits_dataSources_2_value,
  input  [3:0]   io_fromOg1VfArith_1_0_bits_dataSources_3_value,
  input  [3:0]   io_fromOg1VfArith_1_0_bits_dataSources_4_value,
  input          io_fromOg1VfArith_1_0_bits_perfDebugInfo_eliminatedMove,
  input  [63:0]  io_fromOg1VfArith_1_0_bits_perfDebugInfo_renameTime,
  input  [63:0]  io_fromOg1VfArith_1_0_bits_perfDebugInfo_dispatchTime,
  input  [63:0]  io_fromOg1VfArith_1_0_bits_perfDebugInfo_enqRsTime,
  input  [63:0]  io_fromOg1VfArith_1_0_bits_perfDebugInfo_selectTime,
  input  [63:0]  io_fromOg1VfArith_1_0_bits_perfDebugInfo_issueTime,
  input  [63:0]  io_fromOg1VfArith_1_0_bits_perfDebugInfo_writebackTime,
  input  [63:0]  io_fromOg1VfArith_1_0_bits_perfDebugInfo_runahead_checkpoint_id,
  input  [63:0]  io_fromOg1VfArith_1_0_bits_perfDebugInfo_tlbFirstReqTime,
  input  [63:0]  io_fromOg1VfArith_1_0_bits_perfDebugInfo_tlbRespTime,
  input  [55:0]  io_fromOg1VfArith_1_0_bits_debug_seqNum_seqNum,
  input  [7:0]   io_fromOg1VfArith_1_0_bits_debug_seqNum_uopIdx,
  input          io_fromOg1VfArith_0_1_valid,
  input  [34:0]  io_fromOg1VfArith_0_1_bits_fuType,
  input  [8:0]   io_fromOg1VfArith_0_1_bits_fuOpType,
  input  [127:0] io_fromOg1VfArith_0_1_bits_src_0,
  input  [127:0] io_fromOg1VfArith_0_1_bits_src_1,
  input  [127:0] io_fromOg1VfArith_0_1_bits_src_2,
  input  [127:0] io_fromOg1VfArith_0_1_bits_src_3,
  input  [127:0] io_fromOg1VfArith_0_1_bits_src_4,
  input          io_fromOg1VfArith_0_1_bits_robIdx_flag,
  input  [7:0]   io_fromOg1VfArith_0_1_bits_robIdx_value,
  input  [7:0]   io_fromOg1VfArith_0_1_bits_pdest,
  input          io_fromOg1VfArith_0_1_bits_rfWen,
  input          io_fromOg1VfArith_0_1_bits_fpWen,
  input          io_fromOg1VfArith_0_1_bits_vecWen,
  input          io_fromOg1VfArith_0_1_bits_v0Wen,
  input          io_fromOg1VfArith_0_1_bits_vlWen,
  input          io_fromOg1VfArith_0_1_bits_fpu_wflags,
  input          io_fromOg1VfArith_0_1_bits_vpu_vma,
  input          io_fromOg1VfArith_0_1_bits_vpu_vta,
  input  [1:0]   io_fromOg1VfArith_0_1_bits_vpu_vsew,
  input  [2:0]   io_fromOg1VfArith_0_1_bits_vpu_vlmul,
  input          io_fromOg1VfArith_0_1_bits_vpu_vm,
  input  [7:0]   io_fromOg1VfArith_0_1_bits_vpu_vstart,
  input          io_fromOg1VfArith_0_1_bits_vpu_fpu_isFoldTo1_2,
  input          io_fromOg1VfArith_0_1_bits_vpu_fpu_isFoldTo1_4,
  input          io_fromOg1VfArith_0_1_bits_vpu_fpu_isFoldTo1_8,
  input  [6:0]   io_fromOg1VfArith_0_1_bits_vpu_vuopIdx,
  input          io_fromOg1VfArith_0_1_bits_vpu_lastUop,
  input          io_fromOg1VfArith_0_1_bits_vpu_isNarrow,
  input          io_fromOg1VfArith_0_1_bits_vpu_isDstMask,
  input  [3:0]   io_fromOg1VfArith_0_1_bits_dataSources_0_value,
  input  [3:0]   io_fromOg1VfArith_0_1_bits_dataSources_1_value,
  input  [3:0]   io_fromOg1VfArith_0_1_bits_dataSources_2_value,
  input  [3:0]   io_fromOg1VfArith_0_1_bits_dataSources_3_value,
  input  [3:0]   io_fromOg1VfArith_0_1_bits_dataSources_4_value,
  input          io_fromOg1VfArith_0_1_bits_perfDebugInfo_eliminatedMove,
  input  [63:0]  io_fromOg1VfArith_0_1_bits_perfDebugInfo_renameTime,
  input  [63:0]  io_fromOg1VfArith_0_1_bits_perfDebugInfo_dispatchTime,
  input  [63:0]  io_fromOg1VfArith_0_1_bits_perfDebugInfo_enqRsTime,
  input  [63:0]  io_fromOg1VfArith_0_1_bits_perfDebugInfo_selectTime,
  input  [63:0]  io_fromOg1VfArith_0_1_bits_perfDebugInfo_issueTime,
  input  [63:0]  io_fromOg1VfArith_0_1_bits_perfDebugInfo_writebackTime,
  input  [63:0]  io_fromOg1VfArith_0_1_bits_perfDebugInfo_runahead_checkpoint_id,
  input  [63:0]  io_fromOg1VfArith_0_1_bits_perfDebugInfo_tlbFirstReqTime,
  input  [63:0]  io_fromOg1VfArith_0_1_bits_perfDebugInfo_tlbRespTime,
  input  [55:0]  io_fromOg1VfArith_0_1_bits_debug_seqNum_seqNum,
  input  [7:0]   io_fromOg1VfArith_0_1_bits_debug_seqNum_uopIdx,
  input          io_fromOg1VfArith_0_0_valid,
  input  [34:0]  io_fromOg1VfArith_0_0_bits_fuType,
  input  [8:0]   io_fromOg1VfArith_0_0_bits_fuOpType,
  input  [127:0] io_fromOg1VfArith_0_0_bits_src_0,
  input  [127:0] io_fromOg1VfArith_0_0_bits_src_1,
  input  [127:0] io_fromOg1VfArith_0_0_bits_src_2,
  input  [127:0] io_fromOg1VfArith_0_0_bits_src_3,
  input  [127:0] io_fromOg1VfArith_0_0_bits_src_4,
  input          io_fromOg1VfArith_0_0_bits_robIdx_flag,
  input  [7:0]   io_fromOg1VfArith_0_0_bits_robIdx_value,
  input  [6:0]   io_fromOg1VfArith_0_0_bits_pdest,
  input          io_fromOg1VfArith_0_0_bits_vecWen,
  input          io_fromOg1VfArith_0_0_bits_v0Wen,
  input          io_fromOg1VfArith_0_0_bits_fpu_wflags,
  input          io_fromOg1VfArith_0_0_bits_vpu_vma,
  input          io_fromOg1VfArith_0_0_bits_vpu_vta,
  input  [1:0]   io_fromOg1VfArith_0_0_bits_vpu_vsew,
  input  [2:0]   io_fromOg1VfArith_0_0_bits_vpu_vlmul,
  input          io_fromOg1VfArith_0_0_bits_vpu_vm,
  input  [7:0]   io_fromOg1VfArith_0_0_bits_vpu_vstart,
  input  [6:0]   io_fromOg1VfArith_0_0_bits_vpu_vuopIdx,
  input          io_fromOg1VfArith_0_0_bits_vpu_isExt,
  input          io_fromOg1VfArith_0_0_bits_vpu_isNarrow,
  input          io_fromOg1VfArith_0_0_bits_vpu_isDstMask,
  input          io_fromOg1VfArith_0_0_bits_vpu_isOpMask,
  input  [3:0]   io_fromOg1VfArith_0_0_bits_dataSources_0_value,
  input  [3:0]   io_fromOg1VfArith_0_0_bits_dataSources_1_value,
  input  [3:0]   io_fromOg1VfArith_0_0_bits_dataSources_2_value,
  input  [3:0]   io_fromOg1VfArith_0_0_bits_dataSources_3_value,
  input  [3:0]   io_fromOg1VfArith_0_0_bits_dataSources_4_value,
  input          io_fromOg1VfArith_0_0_bits_perfDebugInfo_eliminatedMove,
  input  [63:0]  io_fromOg1VfArith_0_0_bits_perfDebugInfo_renameTime,
  input  [63:0]  io_fromOg1VfArith_0_0_bits_perfDebugInfo_dispatchTime,
  input  [63:0]  io_fromOg1VfArith_0_0_bits_perfDebugInfo_enqRsTime,
  input  [63:0]  io_fromOg1VfArith_0_0_bits_perfDebugInfo_selectTime,
  input  [63:0]  io_fromOg1VfArith_0_0_bits_perfDebugInfo_issueTime,
  input  [63:0]  io_fromOg1VfArith_0_0_bits_perfDebugInfo_writebackTime,
  input  [63:0]  io_fromOg1VfArith_0_0_bits_perfDebugInfo_runahead_checkpoint_id,
  input  [63:0]  io_fromOg1VfArith_0_0_bits_perfDebugInfo_tlbFirstReqTime,
  input  [63:0]  io_fromOg1VfArith_0_0_bits_perfDebugInfo_tlbRespTime,
  input  [55:0]  io_fromOg1VfArith_0_0_bits_debug_seqNum_seqNum,
  input  [7:0]   io_fromOg1VfArith_0_0_bits_debug_seqNum_uopIdx,
  input          io_fromOg1VecMem_1_0_valid,
  input  [34:0]  io_fromOg1VecMem_1_0_bits_fuType,
  input  [8:0]   io_fromOg1VecMem_1_0_bits_fuOpType,
  input  [127:0] io_fromOg1VecMem_1_0_bits_src_0,
  input  [127:0] io_fromOg1VecMem_1_0_bits_src_1,
  input  [127:0] io_fromOg1VecMem_1_0_bits_src_2,
  input  [127:0] io_fromOg1VecMem_1_0_bits_src_3,
  input  [127:0] io_fromOg1VecMem_1_0_bits_src_4,
  input          io_fromOg1VecMem_1_0_bits_robIdx_flag,
  input  [7:0]   io_fromOg1VecMem_1_0_bits_robIdx_value,
  input  [6:0]   io_fromOg1VecMem_1_0_bits_pdest,
  input          io_fromOg1VecMem_1_0_bits_vecWen,
  input          io_fromOg1VecMem_1_0_bits_v0Wen,
  input          io_fromOg1VecMem_1_0_bits_vlWen,
  input          io_fromOg1VecMem_1_0_bits_vpu_vill,
  input          io_fromOg1VecMem_1_0_bits_vpu_vma,
  input          io_fromOg1VecMem_1_0_bits_vpu_vta,
  input  [1:0]   io_fromOg1VecMem_1_0_bits_vpu_vsew,
  input  [2:0]   io_fromOg1VecMem_1_0_bits_vpu_vlmul,
  input          io_fromOg1VecMem_1_0_bits_vpu_specVill,
  input          io_fromOg1VecMem_1_0_bits_vpu_specVma,
  input          io_fromOg1VecMem_1_0_bits_vpu_specVta,
  input  [1:0]   io_fromOg1VecMem_1_0_bits_vpu_specVsew,
  input  [2:0]   io_fromOg1VecMem_1_0_bits_vpu_specVlmul,
  input          io_fromOg1VecMem_1_0_bits_vpu_vm,
  input  [7:0]   io_fromOg1VecMem_1_0_bits_vpu_vstart,
  input  [2:0]   io_fromOg1VecMem_1_0_bits_vpu_frm,
  input          io_fromOg1VecMem_1_0_bits_vpu_fpu_isFpToVecInst,
  input          io_fromOg1VecMem_1_0_bits_vpu_fpu_isFP32Instr,
  input          io_fromOg1VecMem_1_0_bits_vpu_fpu_isFP64Instr,
  input          io_fromOg1VecMem_1_0_bits_vpu_fpu_isReduction,
  input          io_fromOg1VecMem_1_0_bits_vpu_fpu_isFoldTo1_2,
  input          io_fromOg1VecMem_1_0_bits_vpu_fpu_isFoldTo1_4,
  input          io_fromOg1VecMem_1_0_bits_vpu_fpu_isFoldTo1_8,
  input  [1:0]   io_fromOg1VecMem_1_0_bits_vpu_vxrm,
  input  [6:0]   io_fromOg1VecMem_1_0_bits_vpu_vuopIdx,
  input          io_fromOg1VecMem_1_0_bits_vpu_lastUop,
  input  [127:0] io_fromOg1VecMem_1_0_bits_vpu_vmask,
  input  [2:0]   io_fromOg1VecMem_1_0_bits_vpu_nf,
  input  [1:0]   io_fromOg1VecMem_1_0_bits_vpu_veew,
  input          io_fromOg1VecMem_1_0_bits_vpu_isReverse,
  input          io_fromOg1VecMem_1_0_bits_vpu_isExt,
  input          io_fromOg1VecMem_1_0_bits_vpu_isNarrow,
  input          io_fromOg1VecMem_1_0_bits_vpu_isDstMask,
  input          io_fromOg1VecMem_1_0_bits_vpu_isOpMask,
  input          io_fromOg1VecMem_1_0_bits_vpu_isMove,
  input          io_fromOg1VecMem_1_0_bits_vpu_isDependOldVd,
  input          io_fromOg1VecMem_1_0_bits_vpu_isWritePartVd,
  input          io_fromOg1VecMem_1_0_bits_vpu_isVleff,
  input          io_fromOg1VecMem_1_0_bits_ftqIdx_flag,
  input  [5:0]   io_fromOg1VecMem_1_0_bits_ftqIdx_value,
  input  [3:0]   io_fromOg1VecMem_1_0_bits_ftqOffset,
  input  [4:0]   io_fromOg1VecMem_1_0_bits_numLsElem,
  input          io_fromOg1VecMem_1_0_bits_sqIdx_flag,
  input  [5:0]   io_fromOg1VecMem_1_0_bits_sqIdx_value,
  input          io_fromOg1VecMem_1_0_bits_lqIdx_flag,
  input  [6:0]   io_fromOg1VecMem_1_0_bits_lqIdx_value,
  input  [3:0]   io_fromOg1VecMem_1_0_bits_dataSources_0_value,
  input  [3:0]   io_fromOg1VecMem_1_0_bits_dataSources_1_value,
  input  [3:0]   io_fromOg1VecMem_1_0_bits_dataSources_2_value,
  input  [3:0]   io_fromOg1VecMem_1_0_bits_dataSources_3_value,
  input  [3:0]   io_fromOg1VecMem_1_0_bits_dataSources_4_value,
  input          io_fromOg1VecMem_1_0_bits_isVecPartReplay,
  input  [15:0]  io_fromOg1VecMem_1_0_bits_vecReplayMask,
  input  [3:0]   io_fromOg1VecMem_1_0_bits_vecReplayMbIdx,
  input          io_fromOg1VecMem_1_0_bits_perfDebugInfo_eliminatedMove,
  input  [63:0]  io_fromOg1VecMem_1_0_bits_perfDebugInfo_renameTime,
  input  [63:0]  io_fromOg1VecMem_1_0_bits_perfDebugInfo_dispatchTime,
  input  [63:0]  io_fromOg1VecMem_1_0_bits_perfDebugInfo_enqRsTime,
  input  [63:0]  io_fromOg1VecMem_1_0_bits_perfDebugInfo_selectTime,
  input  [63:0]  io_fromOg1VecMem_1_0_bits_perfDebugInfo_issueTime,
  input  [63:0]  io_fromOg1VecMem_1_0_bits_perfDebugInfo_writebackTime,
  input  [63:0]  io_fromOg1VecMem_1_0_bits_perfDebugInfo_runahead_checkpoint_id,
  input  [63:0]  io_fromOg1VecMem_1_0_bits_perfDebugInfo_tlbFirstReqTime,
  input  [63:0]  io_fromOg1VecMem_1_0_bits_perfDebugInfo_tlbRespTime,
  input  [55:0]  io_fromOg1VecMem_1_0_bits_debug_seqNum_seqNum,
  input  [7:0]   io_fromOg1VecMem_1_0_bits_debug_seqNum_uopIdx,
  input          io_fromOg1VecMem_0_0_valid,
  input  [34:0]  io_fromOg1VecMem_0_0_bits_fuType,
  input  [8:0]   io_fromOg1VecMem_0_0_bits_fuOpType,
  input  [127:0] io_fromOg1VecMem_0_0_bits_src_0,
  input  [127:0] io_fromOg1VecMem_0_0_bits_src_1,
  input  [127:0] io_fromOg1VecMem_0_0_bits_src_2,
  input  [127:0] io_fromOg1VecMem_0_0_bits_src_3,
  input  [127:0] io_fromOg1VecMem_0_0_bits_src_4,
  input          io_fromOg1VecMem_0_0_bits_robIdx_flag,
  input  [7:0]   io_fromOg1VecMem_0_0_bits_robIdx_value,
  input  [6:0]   io_fromOg1VecMem_0_0_bits_pdest,
  input          io_fromOg1VecMem_0_0_bits_vecWen,
  input          io_fromOg1VecMem_0_0_bits_v0Wen,
  input          io_fromOg1VecMem_0_0_bits_vlWen,
  input          io_fromOg1VecMem_0_0_bits_vpu_vill,
  input          io_fromOg1VecMem_0_0_bits_vpu_vma,
  input          io_fromOg1VecMem_0_0_bits_vpu_vta,
  input  [1:0]   io_fromOg1VecMem_0_0_bits_vpu_vsew,
  input  [2:0]   io_fromOg1VecMem_0_0_bits_vpu_vlmul,
  input          io_fromOg1VecMem_0_0_bits_vpu_specVill,
  input          io_fromOg1VecMem_0_0_bits_vpu_specVma,
  input          io_fromOg1VecMem_0_0_bits_vpu_specVta,
  input  [1:0]   io_fromOg1VecMem_0_0_bits_vpu_specVsew,
  input  [2:0]   io_fromOg1VecMem_0_0_bits_vpu_specVlmul,
  input          io_fromOg1VecMem_0_0_bits_vpu_vm,
  input  [7:0]   io_fromOg1VecMem_0_0_bits_vpu_vstart,
  input  [2:0]   io_fromOg1VecMem_0_0_bits_vpu_frm,
  input          io_fromOg1VecMem_0_0_bits_vpu_fpu_isFpToVecInst,
  input          io_fromOg1VecMem_0_0_bits_vpu_fpu_isFP32Instr,
  input          io_fromOg1VecMem_0_0_bits_vpu_fpu_isFP64Instr,
  input          io_fromOg1VecMem_0_0_bits_vpu_fpu_isReduction,
  input          io_fromOg1VecMem_0_0_bits_vpu_fpu_isFoldTo1_2,
  input          io_fromOg1VecMem_0_0_bits_vpu_fpu_isFoldTo1_4,
  input          io_fromOg1VecMem_0_0_bits_vpu_fpu_isFoldTo1_8,
  input  [1:0]   io_fromOg1VecMem_0_0_bits_vpu_vxrm,
  input  [6:0]   io_fromOg1VecMem_0_0_bits_vpu_vuopIdx,
  input          io_fromOg1VecMem_0_0_bits_vpu_lastUop,
  input  [127:0] io_fromOg1VecMem_0_0_bits_vpu_vmask,
  input  [2:0]   io_fromOg1VecMem_0_0_bits_vpu_nf,
  input  [1:0]   io_fromOg1VecMem_0_0_bits_vpu_veew,
  input          io_fromOg1VecMem_0_0_bits_vpu_isReverse,
  input          io_fromOg1VecMem_0_0_bits_vpu_isExt,
  input          io_fromOg1VecMem_0_0_bits_vpu_isNarrow,
  input          io_fromOg1VecMem_0_0_bits_vpu_isDstMask,
  input          io_fromOg1VecMem_0_0_bits_vpu_isOpMask,
  input          io_fromOg1VecMem_0_0_bits_vpu_isMove,
  input          io_fromOg1VecMem_0_0_bits_vpu_isDependOldVd,
  input          io_fromOg1VecMem_0_0_bits_vpu_isWritePartVd,
  input          io_fromOg1VecMem_0_0_bits_vpu_isVleff,
  input          io_fromOg1VecMem_0_0_bits_ftqIdx_flag,
  input  [5:0]   io_fromOg1VecMem_0_0_bits_ftqIdx_value,
  input  [3:0]   io_fromOg1VecMem_0_0_bits_ftqOffset,
  input  [4:0]   io_fromOg1VecMem_0_0_bits_numLsElem,
  input          io_fromOg1VecMem_0_0_bits_sqIdx_flag,
  input  [5:0]   io_fromOg1VecMem_0_0_bits_sqIdx_value,
  input          io_fromOg1VecMem_0_0_bits_lqIdx_flag,
  input  [6:0]   io_fromOg1VecMem_0_0_bits_lqIdx_value,
  input  [3:0]   io_fromOg1VecMem_0_0_bits_dataSources_0_value,
  input  [3:0]   io_fromOg1VecMem_0_0_bits_dataSources_1_value,
  input  [3:0]   io_fromOg1VecMem_0_0_bits_dataSources_2_value,
  input  [3:0]   io_fromOg1VecMem_0_0_bits_dataSources_3_value,
  input  [3:0]   io_fromOg1VecMem_0_0_bits_dataSources_4_value,
  input          io_fromOg1VecMem_0_0_bits_isVecPartReplay,
  input  [15:0]  io_fromOg1VecMem_0_0_bits_vecReplayMask,
  input  [3:0]   io_fromOg1VecMem_0_0_bits_vecReplayMbIdx,
  input          io_fromOg1VecMem_0_0_bits_perfDebugInfo_eliminatedMove,
  input  [63:0]  io_fromOg1VecMem_0_0_bits_perfDebugInfo_renameTime,
  input  [63:0]  io_fromOg1VecMem_0_0_bits_perfDebugInfo_dispatchTime,
  input  [63:0]  io_fromOg1VecMem_0_0_bits_perfDebugInfo_enqRsTime,
  input  [63:0]  io_fromOg1VecMem_0_0_bits_perfDebugInfo_selectTime,
  input  [63:0]  io_fromOg1VecMem_0_0_bits_perfDebugInfo_issueTime,
  input  [63:0]  io_fromOg1VecMem_0_0_bits_perfDebugInfo_writebackTime,
  input  [63:0]  io_fromOg1VecMem_0_0_bits_perfDebugInfo_runahead_checkpoint_id,
  input  [63:0]  io_fromOg1VecMem_0_0_bits_perfDebugInfo_tlbFirstReqTime,
  input  [63:0]  io_fromOg1VecMem_0_0_bits_perfDebugInfo_tlbRespTime,
  input  [55:0]  io_fromOg1VecMem_0_0_bits_debug_seqNum_seqNum,
  input  [7:0]   io_fromOg1VecMem_0_0_bits_debug_seqNum_uopIdx,
  input  [31:0]  io_fromOg1ImmInfo_1_imm,
  input  [3:0]   io_fromOg1ImmInfo_1_immType,
  input          io_toVfArithExu_2_0_ready,
  output         io_toVfArithExu_2_0_valid,
  output [34:0]  io_toVfArithExu_2_0_bits_fuType,
  output [8:0]   io_toVfArithExu_2_0_bits_fuOpType,
  output [127:0] io_toVfArithExu_2_0_bits_src_0,
  output [127:0] io_toVfArithExu_2_0_bits_src_1,
  output [127:0] io_toVfArithExu_2_0_bits_src_2,
  output [127:0] io_toVfArithExu_2_0_bits_src_3,
  output [127:0] io_toVfArithExu_2_0_bits_src_4,
  output         io_toVfArithExu_2_0_bits_robIdx_flag,
  output [7:0]   io_toVfArithExu_2_0_bits_robIdx_value,
  output [6:0]   io_toVfArithExu_2_0_bits_pdest,
  output         io_toVfArithExu_2_0_bits_vecWen,
  output         io_toVfArithExu_2_0_bits_v0Wen,
  output         io_toVfArithExu_2_0_bits_fpu_wflags,
  output         io_toVfArithExu_2_0_bits_vpu_vma,
  output         io_toVfArithExu_2_0_bits_vpu_vta,
  output [1:0]   io_toVfArithExu_2_0_bits_vpu_vsew,
  output [2:0]   io_toVfArithExu_2_0_bits_vpu_vlmul,
  output         io_toVfArithExu_2_0_bits_vpu_vm,
  output [7:0]   io_toVfArithExu_2_0_bits_vpu_vstart,
  output [6:0]   io_toVfArithExu_2_0_bits_vpu_vuopIdx,
  output         io_toVfArithExu_2_0_bits_vpu_isExt,
  output         io_toVfArithExu_2_0_bits_vpu_isNarrow,
  output         io_toVfArithExu_2_0_bits_vpu_isDstMask,
  output         io_toVfArithExu_2_0_bits_vpu_isOpMask,
  output [3:0]   io_toVfArithExu_2_0_bits_dataSources_0_value,
  output [3:0]   io_toVfArithExu_2_0_bits_dataSources_1_value,
  output [3:0]   io_toVfArithExu_2_0_bits_dataSources_2_value,
  output [3:0]   io_toVfArithExu_2_0_bits_dataSources_3_value,
  output [3:0]   io_toVfArithExu_2_0_bits_dataSources_4_value,
  output         io_toVfArithExu_2_0_bits_perfDebugInfo_eliminatedMove,
  output [63:0]  io_toVfArithExu_2_0_bits_perfDebugInfo_renameTime,
  output [63:0]  io_toVfArithExu_2_0_bits_perfDebugInfo_dispatchTime,
  output [63:0]  io_toVfArithExu_2_0_bits_perfDebugInfo_enqRsTime,
  output [63:0]  io_toVfArithExu_2_0_bits_perfDebugInfo_selectTime,
  output [63:0]  io_toVfArithExu_2_0_bits_perfDebugInfo_issueTime,
  output [63:0]  io_toVfArithExu_2_0_bits_perfDebugInfo_writebackTime,
  output [63:0]  io_toVfArithExu_2_0_bits_perfDebugInfo_runahead_checkpoint_id,
  output [63:0]  io_toVfArithExu_2_0_bits_perfDebugInfo_tlbFirstReqTime,
  output [63:0]  io_toVfArithExu_2_0_bits_perfDebugInfo_tlbRespTime,
  output [55:0]  io_toVfArithExu_2_0_bits_debug_seqNum_seqNum,
  output [7:0]   io_toVfArithExu_2_0_bits_debug_seqNum_uopIdx,
  input          io_toVfArithExu_1_1_ready,
  output         io_toVfArithExu_1_1_valid,
  output [34:0]  io_toVfArithExu_1_1_bits_fuType,
  output [8:0]   io_toVfArithExu_1_1_bits_fuOpType,
  output [127:0] io_toVfArithExu_1_1_bits_src_0,
  output [127:0] io_toVfArithExu_1_1_bits_src_1,
  output [127:0] io_toVfArithExu_1_1_bits_src_2,
  output [127:0] io_toVfArithExu_1_1_bits_src_3,
  output [127:0] io_toVfArithExu_1_1_bits_src_4,
  output         io_toVfArithExu_1_1_bits_robIdx_flag,
  output [7:0]   io_toVfArithExu_1_1_bits_robIdx_value,
  output [7:0]   io_toVfArithExu_1_1_bits_pdest,
  output         io_toVfArithExu_1_1_bits_fpWen,
  output         io_toVfArithExu_1_1_bits_vecWen,
  output         io_toVfArithExu_1_1_bits_v0Wen,
  output         io_toVfArithExu_1_1_bits_fpu_wflags,
  output         io_toVfArithExu_1_1_bits_vpu_vma,
  output         io_toVfArithExu_1_1_bits_vpu_vta,
  output [1:0]   io_toVfArithExu_1_1_bits_vpu_vsew,
  output [2:0]   io_toVfArithExu_1_1_bits_vpu_vlmul,
  output         io_toVfArithExu_1_1_bits_vpu_vm,
  output [7:0]   io_toVfArithExu_1_1_bits_vpu_vstart,
  output         io_toVfArithExu_1_1_bits_vpu_fpu_isFoldTo1_2,
  output         io_toVfArithExu_1_1_bits_vpu_fpu_isFoldTo1_4,
  output         io_toVfArithExu_1_1_bits_vpu_fpu_isFoldTo1_8,
  output [6:0]   io_toVfArithExu_1_1_bits_vpu_vuopIdx,
  output         io_toVfArithExu_1_1_bits_vpu_lastUop,
  output         io_toVfArithExu_1_1_bits_vpu_isNarrow,
  output         io_toVfArithExu_1_1_bits_vpu_isDstMask,
  output [3:0]   io_toVfArithExu_1_1_bits_dataSources_0_value,
  output [3:0]   io_toVfArithExu_1_1_bits_dataSources_1_value,
  output [3:0]   io_toVfArithExu_1_1_bits_dataSources_2_value,
  output [3:0]   io_toVfArithExu_1_1_bits_dataSources_3_value,
  output [3:0]   io_toVfArithExu_1_1_bits_dataSources_4_value,
  output         io_toVfArithExu_1_1_bits_perfDebugInfo_eliminatedMove,
  output [63:0]  io_toVfArithExu_1_1_bits_perfDebugInfo_renameTime,
  output [63:0]  io_toVfArithExu_1_1_bits_perfDebugInfo_dispatchTime,
  output [63:0]  io_toVfArithExu_1_1_bits_perfDebugInfo_enqRsTime,
  output [63:0]  io_toVfArithExu_1_1_bits_perfDebugInfo_selectTime,
  output [63:0]  io_toVfArithExu_1_1_bits_perfDebugInfo_issueTime,
  output [63:0]  io_toVfArithExu_1_1_bits_perfDebugInfo_writebackTime,
  output [63:0]  io_toVfArithExu_1_1_bits_perfDebugInfo_runahead_checkpoint_id,
  output [63:0]  io_toVfArithExu_1_1_bits_perfDebugInfo_tlbFirstReqTime,
  output [63:0]  io_toVfArithExu_1_1_bits_perfDebugInfo_tlbRespTime,
  output [55:0]  io_toVfArithExu_1_1_bits_debug_seqNum_seqNum,
  output [7:0]   io_toVfArithExu_1_1_bits_debug_seqNum_uopIdx,
  input          io_toVfArithExu_1_0_ready,
  output         io_toVfArithExu_1_0_valid,
  output [34:0]  io_toVfArithExu_1_0_bits_fuType,
  output [8:0]   io_toVfArithExu_1_0_bits_fuOpType,
  output [127:0] io_toVfArithExu_1_0_bits_src_0,
  output [127:0] io_toVfArithExu_1_0_bits_src_1,
  output [127:0] io_toVfArithExu_1_0_bits_src_2,
  output [127:0] io_toVfArithExu_1_0_bits_src_3,
  output [127:0] io_toVfArithExu_1_0_bits_src_4,
  output         io_toVfArithExu_1_0_bits_robIdx_flag,
  output [7:0]   io_toVfArithExu_1_0_bits_robIdx_value,
  output [6:0]   io_toVfArithExu_1_0_bits_pdest,
  output         io_toVfArithExu_1_0_bits_vecWen,
  output         io_toVfArithExu_1_0_bits_v0Wen,
  output         io_toVfArithExu_1_0_bits_fpu_wflags,
  output         io_toVfArithExu_1_0_bits_vpu_vma,
  output         io_toVfArithExu_1_0_bits_vpu_vta,
  output [1:0]   io_toVfArithExu_1_0_bits_vpu_vsew,
  output [2:0]   io_toVfArithExu_1_0_bits_vpu_vlmul,
  output         io_toVfArithExu_1_0_bits_vpu_vm,
  output [7:0]   io_toVfArithExu_1_0_bits_vpu_vstart,
  output [6:0]   io_toVfArithExu_1_0_bits_vpu_vuopIdx,
  output         io_toVfArithExu_1_0_bits_vpu_isExt,
  output         io_toVfArithExu_1_0_bits_vpu_isNarrow,
  output         io_toVfArithExu_1_0_bits_vpu_isDstMask,
  output         io_toVfArithExu_1_0_bits_vpu_isOpMask,
  output [3:0]   io_toVfArithExu_1_0_bits_dataSources_0_value,
  output [3:0]   io_toVfArithExu_1_0_bits_dataSources_1_value,
  output [3:0]   io_toVfArithExu_1_0_bits_dataSources_2_value,
  output [3:0]   io_toVfArithExu_1_0_bits_dataSources_3_value,
  output [3:0]   io_toVfArithExu_1_0_bits_dataSources_4_value,
  output         io_toVfArithExu_1_0_bits_perfDebugInfo_eliminatedMove,
  output [63:0]  io_toVfArithExu_1_0_bits_perfDebugInfo_renameTime,
  output [63:0]  io_toVfArithExu_1_0_bits_perfDebugInfo_dispatchTime,
  output [63:0]  io_toVfArithExu_1_0_bits_perfDebugInfo_enqRsTime,
  output [63:0]  io_toVfArithExu_1_0_bits_perfDebugInfo_selectTime,
  output [63:0]  io_toVfArithExu_1_0_bits_perfDebugInfo_issueTime,
  output [63:0]  io_toVfArithExu_1_0_bits_perfDebugInfo_writebackTime,
  output [63:0]  io_toVfArithExu_1_0_bits_perfDebugInfo_runahead_checkpoint_id,
  output [63:0]  io_toVfArithExu_1_0_bits_perfDebugInfo_tlbFirstReqTime,
  output [63:0]  io_toVfArithExu_1_0_bits_perfDebugInfo_tlbRespTime,
  output [55:0]  io_toVfArithExu_1_0_bits_debug_seqNum_seqNum,
  output [7:0]   io_toVfArithExu_1_0_bits_debug_seqNum_uopIdx,
  input          io_toVfArithExu_0_1_ready,
  output         io_toVfArithExu_0_1_valid,
  output [34:0]  io_toVfArithExu_0_1_bits_fuType,
  output [8:0]   io_toVfArithExu_0_1_bits_fuOpType,
  output [127:0] io_toVfArithExu_0_1_bits_src_0,
  output [127:0] io_toVfArithExu_0_1_bits_src_1,
  output [127:0] io_toVfArithExu_0_1_bits_src_2,
  output [127:0] io_toVfArithExu_0_1_bits_src_3,
  output [127:0] io_toVfArithExu_0_1_bits_src_4,
  output         io_toVfArithExu_0_1_bits_robIdx_flag,
  output [7:0]   io_toVfArithExu_0_1_bits_robIdx_value,
  output [7:0]   io_toVfArithExu_0_1_bits_pdest,
  output         io_toVfArithExu_0_1_bits_rfWen,
  output         io_toVfArithExu_0_1_bits_fpWen,
  output         io_toVfArithExu_0_1_bits_vecWen,
  output         io_toVfArithExu_0_1_bits_v0Wen,
  output         io_toVfArithExu_0_1_bits_vlWen,
  output         io_toVfArithExu_0_1_bits_fpu_wflags,
  output         io_toVfArithExu_0_1_bits_vpu_vma,
  output         io_toVfArithExu_0_1_bits_vpu_vta,
  output [1:0]   io_toVfArithExu_0_1_bits_vpu_vsew,
  output [2:0]   io_toVfArithExu_0_1_bits_vpu_vlmul,
  output         io_toVfArithExu_0_1_bits_vpu_vm,
  output [7:0]   io_toVfArithExu_0_1_bits_vpu_vstart,
  output         io_toVfArithExu_0_1_bits_vpu_fpu_isFoldTo1_2,
  output         io_toVfArithExu_0_1_bits_vpu_fpu_isFoldTo1_4,
  output         io_toVfArithExu_0_1_bits_vpu_fpu_isFoldTo1_8,
  output [6:0]   io_toVfArithExu_0_1_bits_vpu_vuopIdx,
  output         io_toVfArithExu_0_1_bits_vpu_lastUop,
  output         io_toVfArithExu_0_1_bits_vpu_isNarrow,
  output         io_toVfArithExu_0_1_bits_vpu_isDstMask,
  output [3:0]   io_toVfArithExu_0_1_bits_dataSources_0_value,
  output [3:0]   io_toVfArithExu_0_1_bits_dataSources_1_value,
  output [3:0]   io_toVfArithExu_0_1_bits_dataSources_2_value,
  output [3:0]   io_toVfArithExu_0_1_bits_dataSources_3_value,
  output [3:0]   io_toVfArithExu_0_1_bits_dataSources_4_value,
  output         io_toVfArithExu_0_1_bits_perfDebugInfo_eliminatedMove,
  output [63:0]  io_toVfArithExu_0_1_bits_perfDebugInfo_renameTime,
  output [63:0]  io_toVfArithExu_0_1_bits_perfDebugInfo_dispatchTime,
  output [63:0]  io_toVfArithExu_0_1_bits_perfDebugInfo_enqRsTime,
  output [63:0]  io_toVfArithExu_0_1_bits_perfDebugInfo_selectTime,
  output [63:0]  io_toVfArithExu_0_1_bits_perfDebugInfo_issueTime,
  output [63:0]  io_toVfArithExu_0_1_bits_perfDebugInfo_writebackTime,
  output [63:0]  io_toVfArithExu_0_1_bits_perfDebugInfo_runahead_checkpoint_id,
  output [63:0]  io_toVfArithExu_0_1_bits_perfDebugInfo_tlbFirstReqTime,
  output [63:0]  io_toVfArithExu_0_1_bits_perfDebugInfo_tlbRespTime,
  output [55:0]  io_toVfArithExu_0_1_bits_debug_seqNum_seqNum,
  output [7:0]   io_toVfArithExu_0_1_bits_debug_seqNum_uopIdx,
  input          io_toVfArithExu_0_0_ready,
  output         io_toVfArithExu_0_0_valid,
  output [34:0]  io_toVfArithExu_0_0_bits_fuType,
  output [8:0]   io_toVfArithExu_0_0_bits_fuOpType,
  output [127:0] io_toVfArithExu_0_0_bits_src_0,
  output [127:0] io_toVfArithExu_0_0_bits_src_1,
  output [127:0] io_toVfArithExu_0_0_bits_src_2,
  output [127:0] io_toVfArithExu_0_0_bits_src_3,
  output [127:0] io_toVfArithExu_0_0_bits_src_4,
  output         io_toVfArithExu_0_0_bits_robIdx_flag,
  output [7:0]   io_toVfArithExu_0_0_bits_robIdx_value,
  output [6:0]   io_toVfArithExu_0_0_bits_pdest,
  output         io_toVfArithExu_0_0_bits_vecWen,
  output         io_toVfArithExu_0_0_bits_v0Wen,
  output         io_toVfArithExu_0_0_bits_fpu_wflags,
  output         io_toVfArithExu_0_0_bits_vpu_vma,
  output         io_toVfArithExu_0_0_bits_vpu_vta,
  output [1:0]   io_toVfArithExu_0_0_bits_vpu_vsew,
  output [2:0]   io_toVfArithExu_0_0_bits_vpu_vlmul,
  output         io_toVfArithExu_0_0_bits_vpu_vm,
  output [7:0]   io_toVfArithExu_0_0_bits_vpu_vstart,
  output [6:0]   io_toVfArithExu_0_0_bits_vpu_vuopIdx,
  output         io_toVfArithExu_0_0_bits_vpu_isExt,
  output         io_toVfArithExu_0_0_bits_vpu_isNarrow,
  output         io_toVfArithExu_0_0_bits_vpu_isDstMask,
  output         io_toVfArithExu_0_0_bits_vpu_isOpMask,
  output [3:0]   io_toVfArithExu_0_0_bits_dataSources_0_value,
  output [3:0]   io_toVfArithExu_0_0_bits_dataSources_1_value,
  output [3:0]   io_toVfArithExu_0_0_bits_dataSources_2_value,
  output [3:0]   io_toVfArithExu_0_0_bits_dataSources_3_value,
  output [3:0]   io_toVfArithExu_0_0_bits_dataSources_4_value,
  output         io_toVfArithExu_0_0_bits_perfDebugInfo_eliminatedMove,
  output [63:0]  io_toVfArithExu_0_0_bits_perfDebugInfo_renameTime,
  output [63:0]  io_toVfArithExu_0_0_bits_perfDebugInfo_dispatchTime,
  output [63:0]  io_toVfArithExu_0_0_bits_perfDebugInfo_enqRsTime,
  output [63:0]  io_toVfArithExu_0_0_bits_perfDebugInfo_selectTime,
  output [63:0]  io_toVfArithExu_0_0_bits_perfDebugInfo_issueTime,
  output [63:0]  io_toVfArithExu_0_0_bits_perfDebugInfo_writebackTime,
  output [63:0]  io_toVfArithExu_0_0_bits_perfDebugInfo_runahead_checkpoint_id,
  output [63:0]  io_toVfArithExu_0_0_bits_perfDebugInfo_tlbFirstReqTime,
  output [63:0]  io_toVfArithExu_0_0_bits_perfDebugInfo_tlbRespTime,
  output [55:0]  io_toVfArithExu_0_0_bits_debug_seqNum_seqNum,
  output [7:0]   io_toVfArithExu_0_0_bits_debug_seqNum_uopIdx,
  input          io_toVecMemExu_1_0_ready,
  output         io_toVecMemExu_1_0_valid,
  output [34:0]  io_toVecMemExu_1_0_bits_fuType,
  output [8:0]   io_toVecMemExu_1_0_bits_fuOpType,
  output [127:0] io_toVecMemExu_1_0_bits_src_0,
  output [127:0] io_toVecMemExu_1_0_bits_src_1,
  output [127:0] io_toVecMemExu_1_0_bits_src_2,
  output [127:0] io_toVecMemExu_1_0_bits_src_3,
  output [127:0] io_toVecMemExu_1_0_bits_src_4,
  output         io_toVecMemExu_1_0_bits_robIdx_flag,
  output [7:0]   io_toVecMemExu_1_0_bits_robIdx_value,
  output [6:0]   io_toVecMemExu_1_0_bits_pdest,
  output         io_toVecMemExu_1_0_bits_vecWen,
  output         io_toVecMemExu_1_0_bits_v0Wen,
  output         io_toVecMemExu_1_0_bits_vlWen,
  output         io_toVecMemExu_1_0_bits_vpu_vill,
  output         io_toVecMemExu_1_0_bits_vpu_vma,
  output         io_toVecMemExu_1_0_bits_vpu_vta,
  output [1:0]   io_toVecMemExu_1_0_bits_vpu_vsew,
  output [2:0]   io_toVecMemExu_1_0_bits_vpu_vlmul,
  output         io_toVecMemExu_1_0_bits_vpu_specVill,
  output         io_toVecMemExu_1_0_bits_vpu_specVma,
  output         io_toVecMemExu_1_0_bits_vpu_specVta,
  output [1:0]   io_toVecMemExu_1_0_bits_vpu_specVsew,
  output [2:0]   io_toVecMemExu_1_0_bits_vpu_specVlmul,
  output         io_toVecMemExu_1_0_bits_vpu_vm,
  output [7:0]   io_toVecMemExu_1_0_bits_vpu_vstart,
  output [2:0]   io_toVecMemExu_1_0_bits_vpu_frm,
  output         io_toVecMemExu_1_0_bits_vpu_fpu_isFpToVecInst,
  output         io_toVecMemExu_1_0_bits_vpu_fpu_isFP32Instr,
  output         io_toVecMemExu_1_0_bits_vpu_fpu_isFP64Instr,
  output         io_toVecMemExu_1_0_bits_vpu_fpu_isReduction,
  output         io_toVecMemExu_1_0_bits_vpu_fpu_isFoldTo1_2,
  output         io_toVecMemExu_1_0_bits_vpu_fpu_isFoldTo1_4,
  output         io_toVecMemExu_1_0_bits_vpu_fpu_isFoldTo1_8,
  output [1:0]   io_toVecMemExu_1_0_bits_vpu_vxrm,
  output [6:0]   io_toVecMemExu_1_0_bits_vpu_vuopIdx,
  output         io_toVecMemExu_1_0_bits_vpu_lastUop,
  output [127:0] io_toVecMemExu_1_0_bits_vpu_vmask,
  output [2:0]   io_toVecMemExu_1_0_bits_vpu_nf,
  output [1:0]   io_toVecMemExu_1_0_bits_vpu_veew,
  output         io_toVecMemExu_1_0_bits_vpu_isReverse,
  output         io_toVecMemExu_1_0_bits_vpu_isExt,
  output         io_toVecMemExu_1_0_bits_vpu_isNarrow,
  output         io_toVecMemExu_1_0_bits_vpu_isDstMask,
  output         io_toVecMemExu_1_0_bits_vpu_isOpMask,
  output         io_toVecMemExu_1_0_bits_vpu_isMove,
  output         io_toVecMemExu_1_0_bits_vpu_isDependOldVd,
  output         io_toVecMemExu_1_0_bits_vpu_isWritePartVd,
  output         io_toVecMemExu_1_0_bits_vpu_isVleff,
  output         io_toVecMemExu_1_0_bits_ftqIdx_flag,
  output [5:0]   io_toVecMemExu_1_0_bits_ftqIdx_value,
  output [3:0]   io_toVecMemExu_1_0_bits_ftqOffset,
  output [4:0]   io_toVecMemExu_1_0_bits_numLsElem,
  output         io_toVecMemExu_1_0_bits_sqIdx_flag,
  output [5:0]   io_toVecMemExu_1_0_bits_sqIdx_value,
  output         io_toVecMemExu_1_0_bits_lqIdx_flag,
  output [6:0]   io_toVecMemExu_1_0_bits_lqIdx_value,
  output [3:0]   io_toVecMemExu_1_0_bits_dataSources_0_value,
  output [3:0]   io_toVecMemExu_1_0_bits_dataSources_1_value,
  output [3:0]   io_toVecMemExu_1_0_bits_dataSources_2_value,
  output [3:0]   io_toVecMemExu_1_0_bits_dataSources_3_value,
  output [3:0]   io_toVecMemExu_1_0_bits_dataSources_4_value,
  output         io_toVecMemExu_1_0_bits_isVecPartReplay,
  output [15:0]  io_toVecMemExu_1_0_bits_vecReplayMask,
  output [3:0]   io_toVecMemExu_1_0_bits_vecReplayMbIdx,
  output         io_toVecMemExu_1_0_bits_perfDebugInfo_eliminatedMove,
  output [63:0]  io_toVecMemExu_1_0_bits_perfDebugInfo_renameTime,
  output [63:0]  io_toVecMemExu_1_0_bits_perfDebugInfo_dispatchTime,
  output [63:0]  io_toVecMemExu_1_0_bits_perfDebugInfo_enqRsTime,
  output [63:0]  io_toVecMemExu_1_0_bits_perfDebugInfo_selectTime,
  output [63:0]  io_toVecMemExu_1_0_bits_perfDebugInfo_issueTime,
  output [63:0]  io_toVecMemExu_1_0_bits_perfDebugInfo_writebackTime,
  output [63:0]  io_toVecMemExu_1_0_bits_perfDebugInfo_runahead_checkpoint_id,
  output [63:0]  io_toVecMemExu_1_0_bits_perfDebugInfo_tlbFirstReqTime,
  output [63:0]  io_toVecMemExu_1_0_bits_perfDebugInfo_tlbRespTime,
  output [55:0]  io_toVecMemExu_1_0_bits_debug_seqNum_seqNum,
  output [7:0]   io_toVecMemExu_1_0_bits_debug_seqNum_uopIdx,
  input          io_toVecMemExu_0_0_ready,
  output         io_toVecMemExu_0_0_valid,
  output [34:0]  io_toVecMemExu_0_0_bits_fuType,
  output [8:0]   io_toVecMemExu_0_0_bits_fuOpType,
  output [127:0] io_toVecMemExu_0_0_bits_src_0,
  output [127:0] io_toVecMemExu_0_0_bits_src_1,
  output [127:0] io_toVecMemExu_0_0_bits_src_2,
  output [127:0] io_toVecMemExu_0_0_bits_src_3,
  output [127:0] io_toVecMemExu_0_0_bits_src_4,
  output         io_toVecMemExu_0_0_bits_robIdx_flag,
  output [7:0]   io_toVecMemExu_0_0_bits_robIdx_value,
  output [6:0]   io_toVecMemExu_0_0_bits_pdest,
  output         io_toVecMemExu_0_0_bits_vecWen,
  output         io_toVecMemExu_0_0_bits_v0Wen,
  output         io_toVecMemExu_0_0_bits_vlWen,
  output         io_toVecMemExu_0_0_bits_vpu_vill,
  output         io_toVecMemExu_0_0_bits_vpu_vma,
  output         io_toVecMemExu_0_0_bits_vpu_vta,
  output [1:0]   io_toVecMemExu_0_0_bits_vpu_vsew,
  output [2:0]   io_toVecMemExu_0_0_bits_vpu_vlmul,
  output         io_toVecMemExu_0_0_bits_vpu_specVill,
  output         io_toVecMemExu_0_0_bits_vpu_specVma,
  output         io_toVecMemExu_0_0_bits_vpu_specVta,
  output [1:0]   io_toVecMemExu_0_0_bits_vpu_specVsew,
  output [2:0]   io_toVecMemExu_0_0_bits_vpu_specVlmul,
  output         io_toVecMemExu_0_0_bits_vpu_vm,
  output [7:0]   io_toVecMemExu_0_0_bits_vpu_vstart,
  output [2:0]   io_toVecMemExu_0_0_bits_vpu_frm,
  output         io_toVecMemExu_0_0_bits_vpu_fpu_isFpToVecInst,
  output         io_toVecMemExu_0_0_bits_vpu_fpu_isFP32Instr,
  output         io_toVecMemExu_0_0_bits_vpu_fpu_isFP64Instr,
  output         io_toVecMemExu_0_0_bits_vpu_fpu_isReduction,
  output         io_toVecMemExu_0_0_bits_vpu_fpu_isFoldTo1_2,
  output         io_toVecMemExu_0_0_bits_vpu_fpu_isFoldTo1_4,
  output         io_toVecMemExu_0_0_bits_vpu_fpu_isFoldTo1_8,
  output [1:0]   io_toVecMemExu_0_0_bits_vpu_vxrm,
  output [6:0]   io_toVecMemExu_0_0_bits_vpu_vuopIdx,
  output         io_toVecMemExu_0_0_bits_vpu_lastUop,
  output [127:0] io_toVecMemExu_0_0_bits_vpu_vmask,
  output [2:0]   io_toVecMemExu_0_0_bits_vpu_nf,
  output [1:0]   io_toVecMemExu_0_0_bits_vpu_veew,
  output         io_toVecMemExu_0_0_bits_vpu_isReverse,
  output         io_toVecMemExu_0_0_bits_vpu_isExt,
  output         io_toVecMemExu_0_0_bits_vpu_isNarrow,
  output         io_toVecMemExu_0_0_bits_vpu_isDstMask,
  output         io_toVecMemExu_0_0_bits_vpu_isOpMask,
  output         io_toVecMemExu_0_0_bits_vpu_isMove,
  output         io_toVecMemExu_0_0_bits_vpu_isDependOldVd,
  output         io_toVecMemExu_0_0_bits_vpu_isWritePartVd,
  output         io_toVecMemExu_0_0_bits_vpu_isVleff,
  output         io_toVecMemExu_0_0_bits_ftqIdx_flag,
  output [5:0]   io_toVecMemExu_0_0_bits_ftqIdx_value,
  output [3:0]   io_toVecMemExu_0_0_bits_ftqOffset,
  output [4:0]   io_toVecMemExu_0_0_bits_numLsElem,
  output         io_toVecMemExu_0_0_bits_sqIdx_flag,
  output [5:0]   io_toVecMemExu_0_0_bits_sqIdx_value,
  output         io_toVecMemExu_0_0_bits_lqIdx_flag,
  output [6:0]   io_toVecMemExu_0_0_bits_lqIdx_value,
  output [3:0]   io_toVecMemExu_0_0_bits_dataSources_0_value,
  output [3:0]   io_toVecMemExu_0_0_bits_dataSources_1_value,
  output [3:0]   io_toVecMemExu_0_0_bits_dataSources_2_value,
  output [3:0]   io_toVecMemExu_0_0_bits_dataSources_3_value,
  output [3:0]   io_toVecMemExu_0_0_bits_dataSources_4_value,
  output         io_toVecMemExu_0_0_bits_isVecPartReplay,
  output [15:0]  io_toVecMemExu_0_0_bits_vecReplayMask,
  output [3:0]   io_toVecMemExu_0_0_bits_vecReplayMbIdx,
  output         io_toVecMemExu_0_0_bits_perfDebugInfo_eliminatedMove,
  output [63:0]  io_toVecMemExu_0_0_bits_perfDebugInfo_renameTime,
  output [63:0]  io_toVecMemExu_0_0_bits_perfDebugInfo_dispatchTime,
  output [63:0]  io_toVecMemExu_0_0_bits_perfDebugInfo_enqRsTime,
  output [63:0]  io_toVecMemExu_0_0_bits_perfDebugInfo_selectTime,
  output [63:0]  io_toVecMemExu_0_0_bits_perfDebugInfo_issueTime,
  output [63:0]  io_toVecMemExu_0_0_bits_perfDebugInfo_writebackTime,
  output [63:0]  io_toVecMemExu_0_0_bits_perfDebugInfo_runahead_checkpoint_id,
  output [63:0]  io_toVecMemExu_0_0_bits_perfDebugInfo_tlbFirstReqTime,
  output [63:0]  io_toVecMemExu_0_0_bits_perfDebugInfo_tlbRespTime,
  output [55:0]  io_toVecMemExu_0_0_bits_debug_seqNum_seqNum,
  output [7:0]   io_toVecMemExu_0_0_bits_debug_seqNum_uopIdx,
  output         io_toVfIQOg2Resp_2_0_valid,
  output [1:0]   io_toVfIQOg2Resp_2_0_bits_resp,
  output         io_toVfIQOg2Resp_1_1_valid,
  output [1:0]   io_toVfIQOg2Resp_1_1_bits_resp,
  output         io_toVfIQOg2Resp_1_0_valid,
  output [1:0]   io_toVfIQOg2Resp_1_0_bits_resp,
  output         io_toVfIQOg2Resp_0_1_valid,
  output [1:0]   io_toVfIQOg2Resp_0_1_bits_resp,
  output         io_toVfIQOg2Resp_0_0_valid,
  output [1:0]   io_toVfIQOg2Resp_0_0_bits_resp,
  output         io_toMemIQOg2Resp_1_0_valid,
  output         io_toMemIQOg2Resp_1_0_bits_robIdx_flag,
  output [7:0]   io_toMemIQOg2Resp_1_0_bits_robIdx_value,
  output [1:0]   io_toMemIQOg2Resp_1_0_bits_resp,
  output [34:0]  io_toMemIQOg2Resp_1_0_bits_fuType,
  output [6:0]   io_toMemIQOg2Resp_1_0_bits_uopIdx,
  output         io_toMemIQOg2Resp_0_0_valid,
  output         io_toMemIQOg2Resp_0_0_bits_robIdx_flag,
  output [7:0]   io_toMemIQOg2Resp_0_0_bits_robIdx_value,
  output [1:0]   io_toMemIQOg2Resp_0_0_bits_resp,
  output [34:0]  io_toMemIQOg2Resp_0_0_bits_fuType,
  output [6:0]   io_toMemIQOg2Resp_0_0_bits_uopIdx,
  output [31:0]  io_toBypassNetworkImmInfo_1_imm,
  output [3:0]   io_toBypassNetworkImmInfo_1_immType
);
  import og2forvector_pkg::*;

  logic [NCH-1:0]      in_valid, exu_ready, out_valid;
  logic [PW_TOTAL-1:0] in_payload, out_payload;
  logic [NCH-1:0][1:0] resp;

  xs_Og2ForVector_core u_core (
    .clock         (clock),
    .reset         (reset),
    .flush_valid   (io_flush_valid),
    .flush_rob_idx ({io_flush_bits_robIdx_flag, io_flush_bits_robIdx_value}),
    .flush_level   (io_flush_bits_level),
    .in_valid      (in_valid),
    .in_payload    (in_payload),
    .exu_ready     (exu_ready),
    .out_valid     (out_valid),
    .out_payload   (out_payload),
    .resp          (resp),
    .imm_in        (io_fromOg1ImmInfo_1_imm),
    .imm_type_in   (io_fromOg1ImmInfo_1_immType),
    .imm_out       (io_toBypassNetworkImmInfo_1_imm),
    .imm_type_out  (io_toBypassNetworkImmInfo_1_immType)
  );

  // ---- 通道 0：fromOg1VfArith_0_0 -> toVfArithExu_0_0 ----
  assign in_valid[0]  = io_fromOg1VfArith_0_0_valid;
  assign exu_ready[0] = io_toVfArithExu_0_0_ready;
  assign io_toVfArithExu_0_0_valid = out_valid[0];
  assign in_payload[0 +: 8] = io_fromOg1VfArith_0_0_bits_robIdx_value;
  assign in_payload[8] = io_fromOg1VfArith_0_0_bits_robIdx_flag;
  assign in_payload[9 +: 35] = io_fromOg1VfArith_0_0_bits_fuType;
  assign in_payload[44 +: 7] = io_fromOg1VfArith_0_0_bits_vpu_vuopIdx;
  assign in_payload[51 +: 9] = io_fromOg1VfArith_0_0_bits_fuOpType;
  assign in_payload[60 +: 128] = io_fromOg1VfArith_0_0_bits_src_0;
  assign in_payload[188 +: 128] = io_fromOg1VfArith_0_0_bits_src_1;
  assign in_payload[316 +: 128] = io_fromOg1VfArith_0_0_bits_src_2;
  assign in_payload[444 +: 128] = io_fromOg1VfArith_0_0_bits_src_3;
  assign in_payload[572 +: 128] = io_fromOg1VfArith_0_0_bits_src_4;
  assign in_payload[700 +: 7] = io_fromOg1VfArith_0_0_bits_pdest;
  assign in_payload[707] = io_fromOg1VfArith_0_0_bits_vecWen;
  assign in_payload[708] = io_fromOg1VfArith_0_0_bits_v0Wen;
  assign in_payload[709] = io_fromOg1VfArith_0_0_bits_fpu_wflags;
  assign in_payload[710] = io_fromOg1VfArith_0_0_bits_vpu_vma;
  assign in_payload[711] = io_fromOg1VfArith_0_0_bits_vpu_vta;
  assign in_payload[712 +: 2] = io_fromOg1VfArith_0_0_bits_vpu_vsew;
  assign in_payload[714 +: 3] = io_fromOg1VfArith_0_0_bits_vpu_vlmul;
  assign in_payload[717] = io_fromOg1VfArith_0_0_bits_vpu_vm;
  assign in_payload[718 +: 8] = io_fromOg1VfArith_0_0_bits_vpu_vstart;
  assign in_payload[726] = io_fromOg1VfArith_0_0_bits_vpu_isExt;
  assign in_payload[727] = io_fromOg1VfArith_0_0_bits_vpu_isNarrow;
  assign in_payload[728] = io_fromOg1VfArith_0_0_bits_vpu_isDstMask;
  assign in_payload[729] = io_fromOg1VfArith_0_0_bits_vpu_isOpMask;
  assign in_payload[730 +: 4] = io_fromOg1VfArith_0_0_bits_dataSources_0_value;
  assign in_payload[734 +: 4] = io_fromOg1VfArith_0_0_bits_dataSources_1_value;
  assign in_payload[738 +: 4] = io_fromOg1VfArith_0_0_bits_dataSources_2_value;
  assign in_payload[742 +: 4] = io_fromOg1VfArith_0_0_bits_dataSources_3_value;
  assign in_payload[746 +: 4] = io_fromOg1VfArith_0_0_bits_dataSources_4_value;
  assign in_payload[750] = io_fromOg1VfArith_0_0_bits_perfDebugInfo_eliminatedMove;
  assign in_payload[751 +: 64] = io_fromOg1VfArith_0_0_bits_perfDebugInfo_renameTime;
  assign in_payload[815 +: 64] = io_fromOg1VfArith_0_0_bits_perfDebugInfo_dispatchTime;
  assign in_payload[879 +: 64] = io_fromOg1VfArith_0_0_bits_perfDebugInfo_enqRsTime;
  assign in_payload[943 +: 64] = io_fromOg1VfArith_0_0_bits_perfDebugInfo_selectTime;
  assign in_payload[1007 +: 64] = io_fromOg1VfArith_0_0_bits_perfDebugInfo_issueTime;
  assign in_payload[1071 +: 64] = io_fromOg1VfArith_0_0_bits_perfDebugInfo_writebackTime;
  assign in_payload[1135 +: 64] = io_fromOg1VfArith_0_0_bits_perfDebugInfo_runahead_checkpoint_id;
  assign in_payload[1199 +: 64] = io_fromOg1VfArith_0_0_bits_perfDebugInfo_tlbFirstReqTime;
  assign in_payload[1263 +: 64] = io_fromOg1VfArith_0_0_bits_perfDebugInfo_tlbRespTime;
  assign in_payload[1327 +: 56] = io_fromOg1VfArith_0_0_bits_debug_seqNum_seqNum;
  assign in_payload[1383 +: 8] = io_fromOg1VfArith_0_0_bits_debug_seqNum_uopIdx;
  assign io_toVfArithExu_0_0_bits_robIdx_value = out_payload[0 +: 8];
  assign io_toVfArithExu_0_0_bits_robIdx_flag = out_payload[8];
  assign io_toVfArithExu_0_0_bits_fuType = out_payload[9 +: 35];
  assign io_toVfArithExu_0_0_bits_vpu_vuopIdx = out_payload[44 +: 7];
  assign io_toVfArithExu_0_0_bits_fuOpType = out_payload[51 +: 9];
  assign io_toVfArithExu_0_0_bits_src_0 = out_payload[60 +: 128];
  assign io_toVfArithExu_0_0_bits_src_1 = out_payload[188 +: 128];
  assign io_toVfArithExu_0_0_bits_src_2 = out_payload[316 +: 128];
  assign io_toVfArithExu_0_0_bits_src_3 = out_payload[444 +: 128];
  assign io_toVfArithExu_0_0_bits_src_4 = out_payload[572 +: 128];
  assign io_toVfArithExu_0_0_bits_pdest = out_payload[700 +: 7];
  assign io_toVfArithExu_0_0_bits_vecWen = out_payload[707];
  assign io_toVfArithExu_0_0_bits_v0Wen = out_payload[708];
  assign io_toVfArithExu_0_0_bits_fpu_wflags = out_payload[709];
  assign io_toVfArithExu_0_0_bits_vpu_vma = out_payload[710];
  assign io_toVfArithExu_0_0_bits_vpu_vta = out_payload[711];
  assign io_toVfArithExu_0_0_bits_vpu_vsew = out_payload[712 +: 2];
  assign io_toVfArithExu_0_0_bits_vpu_vlmul = out_payload[714 +: 3];
  assign io_toVfArithExu_0_0_bits_vpu_vm = out_payload[717];
  assign io_toVfArithExu_0_0_bits_vpu_vstart = out_payload[718 +: 8];
  assign io_toVfArithExu_0_0_bits_vpu_isExt = out_payload[726];
  assign io_toVfArithExu_0_0_bits_vpu_isNarrow = out_payload[727];
  assign io_toVfArithExu_0_0_bits_vpu_isDstMask = out_payload[728];
  assign io_toVfArithExu_0_0_bits_vpu_isOpMask = out_payload[729];
  assign io_toVfArithExu_0_0_bits_dataSources_0_value = out_payload[730 +: 4];
  assign io_toVfArithExu_0_0_bits_dataSources_1_value = out_payload[734 +: 4];
  assign io_toVfArithExu_0_0_bits_dataSources_2_value = out_payload[738 +: 4];
  assign io_toVfArithExu_0_0_bits_dataSources_3_value = out_payload[742 +: 4];
  assign io_toVfArithExu_0_0_bits_dataSources_4_value = out_payload[746 +: 4];
  assign io_toVfArithExu_0_0_bits_perfDebugInfo_eliminatedMove = out_payload[750];
  assign io_toVfArithExu_0_0_bits_perfDebugInfo_renameTime = out_payload[751 +: 64];
  assign io_toVfArithExu_0_0_bits_perfDebugInfo_dispatchTime = out_payload[815 +: 64];
  assign io_toVfArithExu_0_0_bits_perfDebugInfo_enqRsTime = out_payload[879 +: 64];
  assign io_toVfArithExu_0_0_bits_perfDebugInfo_selectTime = out_payload[943 +: 64];
  assign io_toVfArithExu_0_0_bits_perfDebugInfo_issueTime = out_payload[1007 +: 64];
  assign io_toVfArithExu_0_0_bits_perfDebugInfo_writebackTime = out_payload[1071 +: 64];
  assign io_toVfArithExu_0_0_bits_perfDebugInfo_runahead_checkpoint_id = out_payload[1135 +: 64];
  assign io_toVfArithExu_0_0_bits_perfDebugInfo_tlbFirstReqTime = out_payload[1199 +: 64];
  assign io_toVfArithExu_0_0_bits_perfDebugInfo_tlbRespTime = out_payload[1263 +: 64];
  assign io_toVfArithExu_0_0_bits_debug_seqNum_seqNum = out_payload[1327 +: 56];
  assign io_toVfArithExu_0_0_bits_debug_seqNum_uopIdx = out_payload[1383 +: 8];
  assign io_toVfIQOg2Resp_0_0_valid = out_valid[0];
  assign io_toVfIQOg2Resp_0_0_bits_resp = resp[0];

  // ---- 通道 1：fromOg1VfArith_0_1 -> toVfArithExu_0_1 ----
  assign in_valid[1]  = io_fromOg1VfArith_0_1_valid;
  assign exu_ready[1] = io_toVfArithExu_0_1_ready;
  assign io_toVfArithExu_0_1_valid = out_valid[1];
  assign in_payload[1391 +: 8] = io_fromOg1VfArith_0_1_bits_robIdx_value;
  assign in_payload[1399] = io_fromOg1VfArith_0_1_bits_robIdx_flag;
  assign in_payload[1400 +: 35] = io_fromOg1VfArith_0_1_bits_fuType;
  assign in_payload[1435 +: 7] = io_fromOg1VfArith_0_1_bits_vpu_vuopIdx;
  assign in_payload[1442 +: 9] = io_fromOg1VfArith_0_1_bits_fuOpType;
  assign in_payload[1451 +: 128] = io_fromOg1VfArith_0_1_bits_src_0;
  assign in_payload[1579 +: 128] = io_fromOg1VfArith_0_1_bits_src_1;
  assign in_payload[1707 +: 128] = io_fromOg1VfArith_0_1_bits_src_2;
  assign in_payload[1835 +: 128] = io_fromOg1VfArith_0_1_bits_src_3;
  assign in_payload[1963 +: 128] = io_fromOg1VfArith_0_1_bits_src_4;
  assign in_payload[2091 +: 8] = io_fromOg1VfArith_0_1_bits_pdest;
  assign in_payload[2099] = io_fromOg1VfArith_0_1_bits_rfWen;
  assign in_payload[2100] = io_fromOg1VfArith_0_1_bits_fpWen;
  assign in_payload[2101] = io_fromOg1VfArith_0_1_bits_vecWen;
  assign in_payload[2102] = io_fromOg1VfArith_0_1_bits_v0Wen;
  assign in_payload[2103] = io_fromOg1VfArith_0_1_bits_vlWen;
  assign in_payload[2104] = io_fromOg1VfArith_0_1_bits_fpu_wflags;
  assign in_payload[2105] = io_fromOg1VfArith_0_1_bits_vpu_vma;
  assign in_payload[2106] = io_fromOg1VfArith_0_1_bits_vpu_vta;
  assign in_payload[2107 +: 2] = io_fromOg1VfArith_0_1_bits_vpu_vsew;
  assign in_payload[2109 +: 3] = io_fromOg1VfArith_0_1_bits_vpu_vlmul;
  assign in_payload[2112] = io_fromOg1VfArith_0_1_bits_vpu_vm;
  assign in_payload[2113 +: 8] = io_fromOg1VfArith_0_1_bits_vpu_vstart;
  assign in_payload[2121] = io_fromOg1VfArith_0_1_bits_vpu_fpu_isFoldTo1_2;
  assign in_payload[2122] = io_fromOg1VfArith_0_1_bits_vpu_fpu_isFoldTo1_4;
  assign in_payload[2123] = io_fromOg1VfArith_0_1_bits_vpu_fpu_isFoldTo1_8;
  assign in_payload[2124] = io_fromOg1VfArith_0_1_bits_vpu_lastUop;
  assign in_payload[2125] = io_fromOg1VfArith_0_1_bits_vpu_isNarrow;
  assign in_payload[2126] = io_fromOg1VfArith_0_1_bits_vpu_isDstMask;
  assign in_payload[2127 +: 4] = io_fromOg1VfArith_0_1_bits_dataSources_0_value;
  assign in_payload[2131 +: 4] = io_fromOg1VfArith_0_1_bits_dataSources_1_value;
  assign in_payload[2135 +: 4] = io_fromOg1VfArith_0_1_bits_dataSources_2_value;
  assign in_payload[2139 +: 4] = io_fromOg1VfArith_0_1_bits_dataSources_3_value;
  assign in_payload[2143 +: 4] = io_fromOg1VfArith_0_1_bits_dataSources_4_value;
  assign in_payload[2147] = io_fromOg1VfArith_0_1_bits_perfDebugInfo_eliminatedMove;
  assign in_payload[2148 +: 64] = io_fromOg1VfArith_0_1_bits_perfDebugInfo_renameTime;
  assign in_payload[2212 +: 64] = io_fromOg1VfArith_0_1_bits_perfDebugInfo_dispatchTime;
  assign in_payload[2276 +: 64] = io_fromOg1VfArith_0_1_bits_perfDebugInfo_enqRsTime;
  assign in_payload[2340 +: 64] = io_fromOg1VfArith_0_1_bits_perfDebugInfo_selectTime;
  assign in_payload[2404 +: 64] = io_fromOg1VfArith_0_1_bits_perfDebugInfo_issueTime;
  assign in_payload[2468 +: 64] = io_fromOg1VfArith_0_1_bits_perfDebugInfo_writebackTime;
  assign in_payload[2532 +: 64] = io_fromOg1VfArith_0_1_bits_perfDebugInfo_runahead_checkpoint_id;
  assign in_payload[2596 +: 64] = io_fromOg1VfArith_0_1_bits_perfDebugInfo_tlbFirstReqTime;
  assign in_payload[2660 +: 64] = io_fromOg1VfArith_0_1_bits_perfDebugInfo_tlbRespTime;
  assign in_payload[2724 +: 56] = io_fromOg1VfArith_0_1_bits_debug_seqNum_seqNum;
  assign in_payload[2780 +: 8] = io_fromOg1VfArith_0_1_bits_debug_seqNum_uopIdx;
  assign io_toVfArithExu_0_1_bits_robIdx_value = out_payload[1391 +: 8];
  assign io_toVfArithExu_0_1_bits_robIdx_flag = out_payload[1399];
  assign io_toVfArithExu_0_1_bits_fuType = out_payload[1400 +: 35];
  assign io_toVfArithExu_0_1_bits_vpu_vuopIdx = out_payload[1435 +: 7];
  assign io_toVfArithExu_0_1_bits_fuOpType = out_payload[1442 +: 9];
  assign io_toVfArithExu_0_1_bits_src_0 = out_payload[1451 +: 128];
  assign io_toVfArithExu_0_1_bits_src_1 = out_payload[1579 +: 128];
  assign io_toVfArithExu_0_1_bits_src_2 = out_payload[1707 +: 128];
  assign io_toVfArithExu_0_1_bits_src_3 = out_payload[1835 +: 128];
  assign io_toVfArithExu_0_1_bits_src_4 = out_payload[1963 +: 128];
  assign io_toVfArithExu_0_1_bits_pdest = out_payload[2091 +: 8];
  assign io_toVfArithExu_0_1_bits_rfWen = out_payload[2099];
  assign io_toVfArithExu_0_1_bits_fpWen = out_payload[2100];
  assign io_toVfArithExu_0_1_bits_vecWen = out_payload[2101];
  assign io_toVfArithExu_0_1_bits_v0Wen = out_payload[2102];
  assign io_toVfArithExu_0_1_bits_vlWen = out_payload[2103];
  assign io_toVfArithExu_0_1_bits_fpu_wflags = out_payload[2104];
  assign io_toVfArithExu_0_1_bits_vpu_vma = out_payload[2105];
  assign io_toVfArithExu_0_1_bits_vpu_vta = out_payload[2106];
  assign io_toVfArithExu_0_1_bits_vpu_vsew = out_payload[2107 +: 2];
  assign io_toVfArithExu_0_1_bits_vpu_vlmul = out_payload[2109 +: 3];
  assign io_toVfArithExu_0_1_bits_vpu_vm = out_payload[2112];
  assign io_toVfArithExu_0_1_bits_vpu_vstart = out_payload[2113 +: 8];
  assign io_toVfArithExu_0_1_bits_vpu_fpu_isFoldTo1_2 = out_payload[2121];
  assign io_toVfArithExu_0_1_bits_vpu_fpu_isFoldTo1_4 = out_payload[2122];
  assign io_toVfArithExu_0_1_bits_vpu_fpu_isFoldTo1_8 = out_payload[2123];
  assign io_toVfArithExu_0_1_bits_vpu_lastUop = out_payload[2124];
  assign io_toVfArithExu_0_1_bits_vpu_isNarrow = out_payload[2125];
  assign io_toVfArithExu_0_1_bits_vpu_isDstMask = out_payload[2126];
  assign io_toVfArithExu_0_1_bits_dataSources_0_value = out_payload[2127 +: 4];
  assign io_toVfArithExu_0_1_bits_dataSources_1_value = out_payload[2131 +: 4];
  assign io_toVfArithExu_0_1_bits_dataSources_2_value = out_payload[2135 +: 4];
  assign io_toVfArithExu_0_1_bits_dataSources_3_value = out_payload[2139 +: 4];
  assign io_toVfArithExu_0_1_bits_dataSources_4_value = out_payload[2143 +: 4];
  assign io_toVfArithExu_0_1_bits_perfDebugInfo_eliminatedMove = out_payload[2147];
  assign io_toVfArithExu_0_1_bits_perfDebugInfo_renameTime = out_payload[2148 +: 64];
  assign io_toVfArithExu_0_1_bits_perfDebugInfo_dispatchTime = out_payload[2212 +: 64];
  assign io_toVfArithExu_0_1_bits_perfDebugInfo_enqRsTime = out_payload[2276 +: 64];
  assign io_toVfArithExu_0_1_bits_perfDebugInfo_selectTime = out_payload[2340 +: 64];
  assign io_toVfArithExu_0_1_bits_perfDebugInfo_issueTime = out_payload[2404 +: 64];
  assign io_toVfArithExu_0_1_bits_perfDebugInfo_writebackTime = out_payload[2468 +: 64];
  assign io_toVfArithExu_0_1_bits_perfDebugInfo_runahead_checkpoint_id = out_payload[2532 +: 64];
  assign io_toVfArithExu_0_1_bits_perfDebugInfo_tlbFirstReqTime = out_payload[2596 +: 64];
  assign io_toVfArithExu_0_1_bits_perfDebugInfo_tlbRespTime = out_payload[2660 +: 64];
  assign io_toVfArithExu_0_1_bits_debug_seqNum_seqNum = out_payload[2724 +: 56];
  assign io_toVfArithExu_0_1_bits_debug_seqNum_uopIdx = out_payload[2780 +: 8];
  assign io_toVfIQOg2Resp_0_1_valid = out_valid[1];
  assign io_toVfIQOg2Resp_0_1_bits_resp = resp[1];

  // ---- 通道 2：fromOg1VfArith_1_0 -> toVfArithExu_1_0 ----
  assign in_valid[2]  = io_fromOg1VfArith_1_0_valid;
  assign exu_ready[2] = io_toVfArithExu_1_0_ready;
  assign io_toVfArithExu_1_0_valid = out_valid[2];
  assign in_payload[2788 +: 8] = io_fromOg1VfArith_1_0_bits_robIdx_value;
  assign in_payload[2796] = io_fromOg1VfArith_1_0_bits_robIdx_flag;
  assign in_payload[2797 +: 35] = io_fromOg1VfArith_1_0_bits_fuType;
  assign in_payload[2832 +: 7] = io_fromOg1VfArith_1_0_bits_vpu_vuopIdx;
  assign in_payload[2839 +: 9] = io_fromOg1VfArith_1_0_bits_fuOpType;
  assign in_payload[2848 +: 128] = io_fromOg1VfArith_1_0_bits_src_0;
  assign in_payload[2976 +: 128] = io_fromOg1VfArith_1_0_bits_src_1;
  assign in_payload[3104 +: 128] = io_fromOg1VfArith_1_0_bits_src_2;
  assign in_payload[3232 +: 128] = io_fromOg1VfArith_1_0_bits_src_3;
  assign in_payload[3360 +: 128] = io_fromOg1VfArith_1_0_bits_src_4;
  assign in_payload[3488 +: 7] = io_fromOg1VfArith_1_0_bits_pdest;
  assign in_payload[3495] = io_fromOg1VfArith_1_0_bits_vecWen;
  assign in_payload[3496] = io_fromOg1VfArith_1_0_bits_v0Wen;
  assign in_payload[3497] = io_fromOg1VfArith_1_0_bits_fpu_wflags;
  assign in_payload[3498] = io_fromOg1VfArith_1_0_bits_vpu_vma;
  assign in_payload[3499] = io_fromOg1VfArith_1_0_bits_vpu_vta;
  assign in_payload[3500 +: 2] = io_fromOg1VfArith_1_0_bits_vpu_vsew;
  assign in_payload[3502 +: 3] = io_fromOg1VfArith_1_0_bits_vpu_vlmul;
  assign in_payload[3505] = io_fromOg1VfArith_1_0_bits_vpu_vm;
  assign in_payload[3506 +: 8] = io_fromOg1VfArith_1_0_bits_vpu_vstart;
  assign in_payload[3514] = io_fromOg1VfArith_1_0_bits_vpu_isExt;
  assign in_payload[3515] = io_fromOg1VfArith_1_0_bits_vpu_isNarrow;
  assign in_payload[3516] = io_fromOg1VfArith_1_0_bits_vpu_isDstMask;
  assign in_payload[3517] = io_fromOg1VfArith_1_0_bits_vpu_isOpMask;
  assign in_payload[3518 +: 4] = io_fromOg1VfArith_1_0_bits_dataSources_0_value;
  assign in_payload[3522 +: 4] = io_fromOg1VfArith_1_0_bits_dataSources_1_value;
  assign in_payload[3526 +: 4] = io_fromOg1VfArith_1_0_bits_dataSources_2_value;
  assign in_payload[3530 +: 4] = io_fromOg1VfArith_1_0_bits_dataSources_3_value;
  assign in_payload[3534 +: 4] = io_fromOg1VfArith_1_0_bits_dataSources_4_value;
  assign in_payload[3538] = io_fromOg1VfArith_1_0_bits_perfDebugInfo_eliminatedMove;
  assign in_payload[3539 +: 64] = io_fromOg1VfArith_1_0_bits_perfDebugInfo_renameTime;
  assign in_payload[3603 +: 64] = io_fromOg1VfArith_1_0_bits_perfDebugInfo_dispatchTime;
  assign in_payload[3667 +: 64] = io_fromOg1VfArith_1_0_bits_perfDebugInfo_enqRsTime;
  assign in_payload[3731 +: 64] = io_fromOg1VfArith_1_0_bits_perfDebugInfo_selectTime;
  assign in_payload[3795 +: 64] = io_fromOg1VfArith_1_0_bits_perfDebugInfo_issueTime;
  assign in_payload[3859 +: 64] = io_fromOg1VfArith_1_0_bits_perfDebugInfo_writebackTime;
  assign in_payload[3923 +: 64] = io_fromOg1VfArith_1_0_bits_perfDebugInfo_runahead_checkpoint_id;
  assign in_payload[3987 +: 64] = io_fromOg1VfArith_1_0_bits_perfDebugInfo_tlbFirstReqTime;
  assign in_payload[4051 +: 64] = io_fromOg1VfArith_1_0_bits_perfDebugInfo_tlbRespTime;
  assign in_payload[4115 +: 56] = io_fromOg1VfArith_1_0_bits_debug_seqNum_seqNum;
  assign in_payload[4171 +: 8] = io_fromOg1VfArith_1_0_bits_debug_seqNum_uopIdx;
  assign io_toVfArithExu_1_0_bits_robIdx_value = out_payload[2788 +: 8];
  assign io_toVfArithExu_1_0_bits_robIdx_flag = out_payload[2796];
  assign io_toVfArithExu_1_0_bits_fuType = out_payload[2797 +: 35];
  assign io_toVfArithExu_1_0_bits_vpu_vuopIdx = out_payload[2832 +: 7];
  assign io_toVfArithExu_1_0_bits_fuOpType = out_payload[2839 +: 9];
  assign io_toVfArithExu_1_0_bits_src_0 = out_payload[2848 +: 128];
  assign io_toVfArithExu_1_0_bits_src_1 = out_payload[2976 +: 128];
  assign io_toVfArithExu_1_0_bits_src_2 = out_payload[3104 +: 128];
  assign io_toVfArithExu_1_0_bits_src_3 = out_payload[3232 +: 128];
  assign io_toVfArithExu_1_0_bits_src_4 = out_payload[3360 +: 128];
  assign io_toVfArithExu_1_0_bits_pdest = out_payload[3488 +: 7];
  assign io_toVfArithExu_1_0_bits_vecWen = out_payload[3495];
  assign io_toVfArithExu_1_0_bits_v0Wen = out_payload[3496];
  assign io_toVfArithExu_1_0_bits_fpu_wflags = out_payload[3497];
  assign io_toVfArithExu_1_0_bits_vpu_vma = out_payload[3498];
  assign io_toVfArithExu_1_0_bits_vpu_vta = out_payload[3499];
  assign io_toVfArithExu_1_0_bits_vpu_vsew = out_payload[3500 +: 2];
  assign io_toVfArithExu_1_0_bits_vpu_vlmul = out_payload[3502 +: 3];
  assign io_toVfArithExu_1_0_bits_vpu_vm = out_payload[3505];
  assign io_toVfArithExu_1_0_bits_vpu_vstart = out_payload[3506 +: 8];
  assign io_toVfArithExu_1_0_bits_vpu_isExt = out_payload[3514];
  assign io_toVfArithExu_1_0_bits_vpu_isNarrow = out_payload[3515];
  assign io_toVfArithExu_1_0_bits_vpu_isDstMask = out_payload[3516];
  assign io_toVfArithExu_1_0_bits_vpu_isOpMask = out_payload[3517];
  assign io_toVfArithExu_1_0_bits_dataSources_0_value = out_payload[3518 +: 4];
  assign io_toVfArithExu_1_0_bits_dataSources_1_value = out_payload[3522 +: 4];
  assign io_toVfArithExu_1_0_bits_dataSources_2_value = out_payload[3526 +: 4];
  assign io_toVfArithExu_1_0_bits_dataSources_3_value = out_payload[3530 +: 4];
  assign io_toVfArithExu_1_0_bits_dataSources_4_value = out_payload[3534 +: 4];
  assign io_toVfArithExu_1_0_bits_perfDebugInfo_eliminatedMove = out_payload[3538];
  assign io_toVfArithExu_1_0_bits_perfDebugInfo_renameTime = out_payload[3539 +: 64];
  assign io_toVfArithExu_1_0_bits_perfDebugInfo_dispatchTime = out_payload[3603 +: 64];
  assign io_toVfArithExu_1_0_bits_perfDebugInfo_enqRsTime = out_payload[3667 +: 64];
  assign io_toVfArithExu_1_0_bits_perfDebugInfo_selectTime = out_payload[3731 +: 64];
  assign io_toVfArithExu_1_0_bits_perfDebugInfo_issueTime = out_payload[3795 +: 64];
  assign io_toVfArithExu_1_0_bits_perfDebugInfo_writebackTime = out_payload[3859 +: 64];
  assign io_toVfArithExu_1_0_bits_perfDebugInfo_runahead_checkpoint_id = out_payload[3923 +: 64];
  assign io_toVfArithExu_1_0_bits_perfDebugInfo_tlbFirstReqTime = out_payload[3987 +: 64];
  assign io_toVfArithExu_1_0_bits_perfDebugInfo_tlbRespTime = out_payload[4051 +: 64];
  assign io_toVfArithExu_1_0_bits_debug_seqNum_seqNum = out_payload[4115 +: 56];
  assign io_toVfArithExu_1_0_bits_debug_seqNum_uopIdx = out_payload[4171 +: 8];
  assign io_toVfIQOg2Resp_1_0_valid = out_valid[2];
  assign io_toVfIQOg2Resp_1_0_bits_resp = resp[2];

  // ---- 通道 3：fromOg1VfArith_1_1 -> toVfArithExu_1_1 ----
  assign in_valid[3]  = io_fromOg1VfArith_1_1_valid;
  assign exu_ready[3] = io_toVfArithExu_1_1_ready;
  assign io_toVfArithExu_1_1_valid = out_valid[3];
  assign in_payload[4179 +: 8] = io_fromOg1VfArith_1_1_bits_robIdx_value;
  assign in_payload[4187] = io_fromOg1VfArith_1_1_bits_robIdx_flag;
  assign in_payload[4188 +: 35] = io_fromOg1VfArith_1_1_bits_fuType;
  assign in_payload[4223 +: 7] = io_fromOg1VfArith_1_1_bits_vpu_vuopIdx;
  assign in_payload[4230 +: 9] = io_fromOg1VfArith_1_1_bits_fuOpType;
  assign in_payload[4239 +: 128] = io_fromOg1VfArith_1_1_bits_src_0;
  assign in_payload[4367 +: 128] = io_fromOg1VfArith_1_1_bits_src_1;
  assign in_payload[4495 +: 128] = io_fromOg1VfArith_1_1_bits_src_2;
  assign in_payload[4623 +: 128] = io_fromOg1VfArith_1_1_bits_src_3;
  assign in_payload[4751 +: 128] = io_fromOg1VfArith_1_1_bits_src_4;
  assign in_payload[4879 +: 8] = io_fromOg1VfArith_1_1_bits_pdest;
  assign in_payload[4887] = io_fromOg1VfArith_1_1_bits_fpWen;
  assign in_payload[4888] = io_fromOg1VfArith_1_1_bits_vecWen;
  assign in_payload[4889] = io_fromOg1VfArith_1_1_bits_v0Wen;
  assign in_payload[4890] = io_fromOg1VfArith_1_1_bits_fpu_wflags;
  assign in_payload[4891] = io_fromOg1VfArith_1_1_bits_vpu_vma;
  assign in_payload[4892] = io_fromOg1VfArith_1_1_bits_vpu_vta;
  assign in_payload[4893 +: 2] = io_fromOg1VfArith_1_1_bits_vpu_vsew;
  assign in_payload[4895 +: 3] = io_fromOg1VfArith_1_1_bits_vpu_vlmul;
  assign in_payload[4898] = io_fromOg1VfArith_1_1_bits_vpu_vm;
  assign in_payload[4899 +: 8] = io_fromOg1VfArith_1_1_bits_vpu_vstart;
  assign in_payload[4907] = io_fromOg1VfArith_1_1_bits_vpu_fpu_isFoldTo1_2;
  assign in_payload[4908] = io_fromOg1VfArith_1_1_bits_vpu_fpu_isFoldTo1_4;
  assign in_payload[4909] = io_fromOg1VfArith_1_1_bits_vpu_fpu_isFoldTo1_8;
  assign in_payload[4910] = io_fromOg1VfArith_1_1_bits_vpu_lastUop;
  assign in_payload[4911] = io_fromOg1VfArith_1_1_bits_vpu_isNarrow;
  assign in_payload[4912] = io_fromOg1VfArith_1_1_bits_vpu_isDstMask;
  assign in_payload[4913 +: 4] = io_fromOg1VfArith_1_1_bits_dataSources_0_value;
  assign in_payload[4917 +: 4] = io_fromOg1VfArith_1_1_bits_dataSources_1_value;
  assign in_payload[4921 +: 4] = io_fromOg1VfArith_1_1_bits_dataSources_2_value;
  assign in_payload[4925 +: 4] = io_fromOg1VfArith_1_1_bits_dataSources_3_value;
  assign in_payload[4929 +: 4] = io_fromOg1VfArith_1_1_bits_dataSources_4_value;
  assign in_payload[4933] = io_fromOg1VfArith_1_1_bits_perfDebugInfo_eliminatedMove;
  assign in_payload[4934 +: 64] = io_fromOg1VfArith_1_1_bits_perfDebugInfo_renameTime;
  assign in_payload[4998 +: 64] = io_fromOg1VfArith_1_1_bits_perfDebugInfo_dispatchTime;
  assign in_payload[5062 +: 64] = io_fromOg1VfArith_1_1_bits_perfDebugInfo_enqRsTime;
  assign in_payload[5126 +: 64] = io_fromOg1VfArith_1_1_bits_perfDebugInfo_selectTime;
  assign in_payload[5190 +: 64] = io_fromOg1VfArith_1_1_bits_perfDebugInfo_issueTime;
  assign in_payload[5254 +: 64] = io_fromOg1VfArith_1_1_bits_perfDebugInfo_writebackTime;
  assign in_payload[5318 +: 64] = io_fromOg1VfArith_1_1_bits_perfDebugInfo_runahead_checkpoint_id;
  assign in_payload[5382 +: 64] = io_fromOg1VfArith_1_1_bits_perfDebugInfo_tlbFirstReqTime;
  assign in_payload[5446 +: 64] = io_fromOg1VfArith_1_1_bits_perfDebugInfo_tlbRespTime;
  assign in_payload[5510 +: 56] = io_fromOg1VfArith_1_1_bits_debug_seqNum_seqNum;
  assign in_payload[5566 +: 8] = io_fromOg1VfArith_1_1_bits_debug_seqNum_uopIdx;
  assign io_toVfArithExu_1_1_bits_robIdx_value = out_payload[4179 +: 8];
  assign io_toVfArithExu_1_1_bits_robIdx_flag = out_payload[4187];
  assign io_toVfArithExu_1_1_bits_fuType = out_payload[4188 +: 35];
  assign io_toVfArithExu_1_1_bits_vpu_vuopIdx = out_payload[4223 +: 7];
  assign io_toVfArithExu_1_1_bits_fuOpType = out_payload[4230 +: 9];
  assign io_toVfArithExu_1_1_bits_src_0 = out_payload[4239 +: 128];
  assign io_toVfArithExu_1_1_bits_src_1 = out_payload[4367 +: 128];
  assign io_toVfArithExu_1_1_bits_src_2 = out_payload[4495 +: 128];
  assign io_toVfArithExu_1_1_bits_src_3 = out_payload[4623 +: 128];
  assign io_toVfArithExu_1_1_bits_src_4 = out_payload[4751 +: 128];
  assign io_toVfArithExu_1_1_bits_pdest = out_payload[4879 +: 8];
  assign io_toVfArithExu_1_1_bits_fpWen = out_payload[4887];
  assign io_toVfArithExu_1_1_bits_vecWen = out_payload[4888];
  assign io_toVfArithExu_1_1_bits_v0Wen = out_payload[4889];
  assign io_toVfArithExu_1_1_bits_fpu_wflags = out_payload[4890];
  assign io_toVfArithExu_1_1_bits_vpu_vma = out_payload[4891];
  assign io_toVfArithExu_1_1_bits_vpu_vta = out_payload[4892];
  assign io_toVfArithExu_1_1_bits_vpu_vsew = out_payload[4893 +: 2];
  assign io_toVfArithExu_1_1_bits_vpu_vlmul = out_payload[4895 +: 3];
  assign io_toVfArithExu_1_1_bits_vpu_vm = out_payload[4898];
  assign io_toVfArithExu_1_1_bits_vpu_vstart = out_payload[4899 +: 8];
  assign io_toVfArithExu_1_1_bits_vpu_fpu_isFoldTo1_2 = out_payload[4907];
  assign io_toVfArithExu_1_1_bits_vpu_fpu_isFoldTo1_4 = out_payload[4908];
  assign io_toVfArithExu_1_1_bits_vpu_fpu_isFoldTo1_8 = out_payload[4909];
  assign io_toVfArithExu_1_1_bits_vpu_lastUop = out_payload[4910];
  assign io_toVfArithExu_1_1_bits_vpu_isNarrow = out_payload[4911];
  assign io_toVfArithExu_1_1_bits_vpu_isDstMask = out_payload[4912];
  assign io_toVfArithExu_1_1_bits_dataSources_0_value = out_payload[4913 +: 4];
  assign io_toVfArithExu_1_1_bits_dataSources_1_value = out_payload[4917 +: 4];
  assign io_toVfArithExu_1_1_bits_dataSources_2_value = out_payload[4921 +: 4];
  assign io_toVfArithExu_1_1_bits_dataSources_3_value = out_payload[4925 +: 4];
  assign io_toVfArithExu_1_1_bits_dataSources_4_value = out_payload[4929 +: 4];
  assign io_toVfArithExu_1_1_bits_perfDebugInfo_eliminatedMove = out_payload[4933];
  assign io_toVfArithExu_1_1_bits_perfDebugInfo_renameTime = out_payload[4934 +: 64];
  assign io_toVfArithExu_1_1_bits_perfDebugInfo_dispatchTime = out_payload[4998 +: 64];
  assign io_toVfArithExu_1_1_bits_perfDebugInfo_enqRsTime = out_payload[5062 +: 64];
  assign io_toVfArithExu_1_1_bits_perfDebugInfo_selectTime = out_payload[5126 +: 64];
  assign io_toVfArithExu_1_1_bits_perfDebugInfo_issueTime = out_payload[5190 +: 64];
  assign io_toVfArithExu_1_1_bits_perfDebugInfo_writebackTime = out_payload[5254 +: 64];
  assign io_toVfArithExu_1_1_bits_perfDebugInfo_runahead_checkpoint_id = out_payload[5318 +: 64];
  assign io_toVfArithExu_1_1_bits_perfDebugInfo_tlbFirstReqTime = out_payload[5382 +: 64];
  assign io_toVfArithExu_1_1_bits_perfDebugInfo_tlbRespTime = out_payload[5446 +: 64];
  assign io_toVfArithExu_1_1_bits_debug_seqNum_seqNum = out_payload[5510 +: 56];
  assign io_toVfArithExu_1_1_bits_debug_seqNum_uopIdx = out_payload[5566 +: 8];
  assign io_toVfIQOg2Resp_1_1_valid = out_valid[3];
  assign io_toVfIQOg2Resp_1_1_bits_resp = resp[3];

  // ---- 通道 4：fromOg1VfArith_2_0 -> toVfArithExu_2_0 ----
  assign in_valid[4]  = io_fromOg1VfArith_2_0_valid;
  assign exu_ready[4] = io_toVfArithExu_2_0_ready;
  assign io_toVfArithExu_2_0_valid = out_valid[4];
  assign in_payload[5574 +: 8] = io_fromOg1VfArith_2_0_bits_robIdx_value;
  assign in_payload[5582] = io_fromOg1VfArith_2_0_bits_robIdx_flag;
  assign in_payload[5583 +: 35] = io_fromOg1VfArith_2_0_bits_fuType;
  assign in_payload[5618 +: 7] = io_fromOg1VfArith_2_0_bits_vpu_vuopIdx;
  assign in_payload[5625 +: 9] = io_fromOg1VfArith_2_0_bits_fuOpType;
  assign in_payload[5634 +: 128] = io_fromOg1VfArith_2_0_bits_src_0;
  assign in_payload[5762 +: 128] = io_fromOg1VfArith_2_0_bits_src_1;
  assign in_payload[5890 +: 128] = io_fromOg1VfArith_2_0_bits_src_2;
  assign in_payload[6018 +: 128] = io_fromOg1VfArith_2_0_bits_src_3;
  assign in_payload[6146 +: 128] = io_fromOg1VfArith_2_0_bits_src_4;
  assign in_payload[6274 +: 7] = io_fromOg1VfArith_2_0_bits_pdest;
  assign in_payload[6281] = io_fromOg1VfArith_2_0_bits_vecWen;
  assign in_payload[6282] = io_fromOg1VfArith_2_0_bits_v0Wen;
  assign in_payload[6283] = io_fromOg1VfArith_2_0_bits_fpu_wflags;
  assign in_payload[6284] = io_fromOg1VfArith_2_0_bits_vpu_vma;
  assign in_payload[6285] = io_fromOg1VfArith_2_0_bits_vpu_vta;
  assign in_payload[6286 +: 2] = io_fromOg1VfArith_2_0_bits_vpu_vsew;
  assign in_payload[6288 +: 3] = io_fromOg1VfArith_2_0_bits_vpu_vlmul;
  assign in_payload[6291] = io_fromOg1VfArith_2_0_bits_vpu_vm;
  assign in_payload[6292 +: 8] = io_fromOg1VfArith_2_0_bits_vpu_vstart;
  assign in_payload[6300] = io_fromOg1VfArith_2_0_bits_vpu_isExt;
  assign in_payload[6301] = io_fromOg1VfArith_2_0_bits_vpu_isNarrow;
  assign in_payload[6302] = io_fromOg1VfArith_2_0_bits_vpu_isDstMask;
  assign in_payload[6303] = io_fromOg1VfArith_2_0_bits_vpu_isOpMask;
  assign in_payload[6304 +: 4] = io_fromOg1VfArith_2_0_bits_dataSources_0_value;
  assign in_payload[6308 +: 4] = io_fromOg1VfArith_2_0_bits_dataSources_1_value;
  assign in_payload[6312 +: 4] = io_fromOg1VfArith_2_0_bits_dataSources_2_value;
  assign in_payload[6316 +: 4] = io_fromOg1VfArith_2_0_bits_dataSources_3_value;
  assign in_payload[6320 +: 4] = io_fromOg1VfArith_2_0_bits_dataSources_4_value;
  assign in_payload[6324] = io_fromOg1VfArith_2_0_bits_perfDebugInfo_eliminatedMove;
  assign in_payload[6325 +: 64] = io_fromOg1VfArith_2_0_bits_perfDebugInfo_renameTime;
  assign in_payload[6389 +: 64] = io_fromOg1VfArith_2_0_bits_perfDebugInfo_dispatchTime;
  assign in_payload[6453 +: 64] = io_fromOg1VfArith_2_0_bits_perfDebugInfo_enqRsTime;
  assign in_payload[6517 +: 64] = io_fromOg1VfArith_2_0_bits_perfDebugInfo_selectTime;
  assign in_payload[6581 +: 64] = io_fromOg1VfArith_2_0_bits_perfDebugInfo_issueTime;
  assign in_payload[6645 +: 64] = io_fromOg1VfArith_2_0_bits_perfDebugInfo_writebackTime;
  assign in_payload[6709 +: 64] = io_fromOg1VfArith_2_0_bits_perfDebugInfo_runahead_checkpoint_id;
  assign in_payload[6773 +: 64] = io_fromOg1VfArith_2_0_bits_perfDebugInfo_tlbFirstReqTime;
  assign in_payload[6837 +: 64] = io_fromOg1VfArith_2_0_bits_perfDebugInfo_tlbRespTime;
  assign in_payload[6901 +: 56] = io_fromOg1VfArith_2_0_bits_debug_seqNum_seqNum;
  assign in_payload[6957 +: 8] = io_fromOg1VfArith_2_0_bits_debug_seqNum_uopIdx;
  assign io_toVfArithExu_2_0_bits_robIdx_value = out_payload[5574 +: 8];
  assign io_toVfArithExu_2_0_bits_robIdx_flag = out_payload[5582];
  assign io_toVfArithExu_2_0_bits_fuType = out_payload[5583 +: 35];
  assign io_toVfArithExu_2_0_bits_vpu_vuopIdx = out_payload[5618 +: 7];
  assign io_toVfArithExu_2_0_bits_fuOpType = out_payload[5625 +: 9];
  assign io_toVfArithExu_2_0_bits_src_0 = out_payload[5634 +: 128];
  assign io_toVfArithExu_2_0_bits_src_1 = out_payload[5762 +: 128];
  assign io_toVfArithExu_2_0_bits_src_2 = out_payload[5890 +: 128];
  assign io_toVfArithExu_2_0_bits_src_3 = out_payload[6018 +: 128];
  assign io_toVfArithExu_2_0_bits_src_4 = out_payload[6146 +: 128];
  assign io_toVfArithExu_2_0_bits_pdest = out_payload[6274 +: 7];
  assign io_toVfArithExu_2_0_bits_vecWen = out_payload[6281];
  assign io_toVfArithExu_2_0_bits_v0Wen = out_payload[6282];
  assign io_toVfArithExu_2_0_bits_fpu_wflags = out_payload[6283];
  assign io_toVfArithExu_2_0_bits_vpu_vma = out_payload[6284];
  assign io_toVfArithExu_2_0_bits_vpu_vta = out_payload[6285];
  assign io_toVfArithExu_2_0_bits_vpu_vsew = out_payload[6286 +: 2];
  assign io_toVfArithExu_2_0_bits_vpu_vlmul = out_payload[6288 +: 3];
  assign io_toVfArithExu_2_0_bits_vpu_vm = out_payload[6291];
  assign io_toVfArithExu_2_0_bits_vpu_vstart = out_payload[6292 +: 8];
  assign io_toVfArithExu_2_0_bits_vpu_isExt = out_payload[6300];
  assign io_toVfArithExu_2_0_bits_vpu_isNarrow = out_payload[6301];
  assign io_toVfArithExu_2_0_bits_vpu_isDstMask = out_payload[6302];
  assign io_toVfArithExu_2_0_bits_vpu_isOpMask = out_payload[6303];
  assign io_toVfArithExu_2_0_bits_dataSources_0_value = out_payload[6304 +: 4];
  assign io_toVfArithExu_2_0_bits_dataSources_1_value = out_payload[6308 +: 4];
  assign io_toVfArithExu_2_0_bits_dataSources_2_value = out_payload[6312 +: 4];
  assign io_toVfArithExu_2_0_bits_dataSources_3_value = out_payload[6316 +: 4];
  assign io_toVfArithExu_2_0_bits_dataSources_4_value = out_payload[6320 +: 4];
  assign io_toVfArithExu_2_0_bits_perfDebugInfo_eliminatedMove = out_payload[6324];
  assign io_toVfArithExu_2_0_bits_perfDebugInfo_renameTime = out_payload[6325 +: 64];
  assign io_toVfArithExu_2_0_bits_perfDebugInfo_dispatchTime = out_payload[6389 +: 64];
  assign io_toVfArithExu_2_0_bits_perfDebugInfo_enqRsTime = out_payload[6453 +: 64];
  assign io_toVfArithExu_2_0_bits_perfDebugInfo_selectTime = out_payload[6517 +: 64];
  assign io_toVfArithExu_2_0_bits_perfDebugInfo_issueTime = out_payload[6581 +: 64];
  assign io_toVfArithExu_2_0_bits_perfDebugInfo_writebackTime = out_payload[6645 +: 64];
  assign io_toVfArithExu_2_0_bits_perfDebugInfo_runahead_checkpoint_id = out_payload[6709 +: 64];
  assign io_toVfArithExu_2_0_bits_perfDebugInfo_tlbFirstReqTime = out_payload[6773 +: 64];
  assign io_toVfArithExu_2_0_bits_perfDebugInfo_tlbRespTime = out_payload[6837 +: 64];
  assign io_toVfArithExu_2_0_bits_debug_seqNum_seqNum = out_payload[6901 +: 56];
  assign io_toVfArithExu_2_0_bits_debug_seqNum_uopIdx = out_payload[6957 +: 8];
  assign io_toVfIQOg2Resp_2_0_valid = out_valid[4];
  assign io_toVfIQOg2Resp_2_0_bits_resp = resp[4];

  // ---- 通道 5：fromOg1VecMem_0_0 -> toVecMemExu_0_0 ----
  assign in_valid[5]  = io_fromOg1VecMem_0_0_valid;
  assign exu_ready[5] = io_toVecMemExu_0_0_ready;
  assign io_toVecMemExu_0_0_valid = out_valid[5];
  assign in_payload[6965 +: 8] = io_fromOg1VecMem_0_0_bits_robIdx_value;
  assign in_payload[6973] = io_fromOg1VecMem_0_0_bits_robIdx_flag;
  assign in_payload[6974 +: 35] = io_fromOg1VecMem_0_0_bits_fuType;
  assign in_payload[7009 +: 7] = io_fromOg1VecMem_0_0_bits_vpu_vuopIdx;
  assign in_payload[7016 +: 9] = io_fromOg1VecMem_0_0_bits_fuOpType;
  assign in_payload[7025 +: 128] = io_fromOg1VecMem_0_0_bits_src_0;
  assign in_payload[7153 +: 128] = io_fromOg1VecMem_0_0_bits_src_1;
  assign in_payload[7281 +: 128] = io_fromOg1VecMem_0_0_bits_src_2;
  assign in_payload[7409 +: 128] = io_fromOg1VecMem_0_0_bits_src_3;
  assign in_payload[7537 +: 128] = io_fromOg1VecMem_0_0_bits_src_4;
  assign in_payload[7665 +: 7] = io_fromOg1VecMem_0_0_bits_pdest;
  assign in_payload[7672] = io_fromOg1VecMem_0_0_bits_vecWen;
  assign in_payload[7673] = io_fromOg1VecMem_0_0_bits_v0Wen;
  assign in_payload[7674] = io_fromOg1VecMem_0_0_bits_vlWen;
  assign in_payload[7675] = io_fromOg1VecMem_0_0_bits_vpu_vill;
  assign in_payload[7676] = io_fromOg1VecMem_0_0_bits_vpu_vma;
  assign in_payload[7677] = io_fromOg1VecMem_0_0_bits_vpu_vta;
  assign in_payload[7678 +: 2] = io_fromOg1VecMem_0_0_bits_vpu_vsew;
  assign in_payload[7680 +: 3] = io_fromOg1VecMem_0_0_bits_vpu_vlmul;
  assign in_payload[7683] = io_fromOg1VecMem_0_0_bits_vpu_specVill;
  assign in_payload[7684] = io_fromOg1VecMem_0_0_bits_vpu_specVma;
  assign in_payload[7685] = io_fromOg1VecMem_0_0_bits_vpu_specVta;
  assign in_payload[7686 +: 2] = io_fromOg1VecMem_0_0_bits_vpu_specVsew;
  assign in_payload[7688 +: 3] = io_fromOg1VecMem_0_0_bits_vpu_specVlmul;
  assign in_payload[7691] = io_fromOg1VecMem_0_0_bits_vpu_vm;
  assign in_payload[7692 +: 8] = io_fromOg1VecMem_0_0_bits_vpu_vstart;
  assign in_payload[7700 +: 3] = io_fromOg1VecMem_0_0_bits_vpu_frm;
  assign in_payload[7703] = io_fromOg1VecMem_0_0_bits_vpu_fpu_isFpToVecInst;
  assign in_payload[7704] = io_fromOg1VecMem_0_0_bits_vpu_fpu_isFP32Instr;
  assign in_payload[7705] = io_fromOg1VecMem_0_0_bits_vpu_fpu_isFP64Instr;
  assign in_payload[7706] = io_fromOg1VecMem_0_0_bits_vpu_fpu_isReduction;
  assign in_payload[7707] = io_fromOg1VecMem_0_0_bits_vpu_fpu_isFoldTo1_2;
  assign in_payload[7708] = io_fromOg1VecMem_0_0_bits_vpu_fpu_isFoldTo1_4;
  assign in_payload[7709] = io_fromOg1VecMem_0_0_bits_vpu_fpu_isFoldTo1_8;
  assign in_payload[7710 +: 2] = io_fromOg1VecMem_0_0_bits_vpu_vxrm;
  assign in_payload[7712] = io_fromOg1VecMem_0_0_bits_vpu_lastUop;
  assign in_payload[7713 +: 128] = io_fromOg1VecMem_0_0_bits_vpu_vmask;
  assign in_payload[7841 +: 3] = io_fromOg1VecMem_0_0_bits_vpu_nf;
  assign in_payload[7844 +: 2] = io_fromOg1VecMem_0_0_bits_vpu_veew;
  assign in_payload[7846] = io_fromOg1VecMem_0_0_bits_vpu_isReverse;
  assign in_payload[7847] = io_fromOg1VecMem_0_0_bits_vpu_isExt;
  assign in_payload[7848] = io_fromOg1VecMem_0_0_bits_vpu_isNarrow;
  assign in_payload[7849] = io_fromOg1VecMem_0_0_bits_vpu_isDstMask;
  assign in_payload[7850] = io_fromOg1VecMem_0_0_bits_vpu_isOpMask;
  assign in_payload[7851] = io_fromOg1VecMem_0_0_bits_vpu_isMove;
  assign in_payload[7852] = io_fromOg1VecMem_0_0_bits_vpu_isDependOldVd;
  assign in_payload[7853] = io_fromOg1VecMem_0_0_bits_vpu_isWritePartVd;
  assign in_payload[7854] = io_fromOg1VecMem_0_0_bits_vpu_isVleff;
  assign in_payload[7855] = io_fromOg1VecMem_0_0_bits_ftqIdx_flag;
  assign in_payload[7856 +: 6] = io_fromOg1VecMem_0_0_bits_ftqIdx_value;
  assign in_payload[7862 +: 4] = io_fromOg1VecMem_0_0_bits_ftqOffset;
  assign in_payload[7866 +: 5] = io_fromOg1VecMem_0_0_bits_numLsElem;
  assign in_payload[7871] = io_fromOg1VecMem_0_0_bits_sqIdx_flag;
  assign in_payload[7872 +: 6] = io_fromOg1VecMem_0_0_bits_sqIdx_value;
  assign in_payload[7878] = io_fromOg1VecMem_0_0_bits_lqIdx_flag;
  assign in_payload[7879 +: 7] = io_fromOg1VecMem_0_0_bits_lqIdx_value;
  assign in_payload[7886 +: 4] = io_fromOg1VecMem_0_0_bits_dataSources_0_value;
  assign in_payload[7890 +: 4] = io_fromOg1VecMem_0_0_bits_dataSources_1_value;
  assign in_payload[7894 +: 4] = io_fromOg1VecMem_0_0_bits_dataSources_2_value;
  assign in_payload[7898 +: 4] = io_fromOg1VecMem_0_0_bits_dataSources_3_value;
  assign in_payload[7902 +: 4] = io_fromOg1VecMem_0_0_bits_dataSources_4_value;
  assign in_payload[7906] = io_fromOg1VecMem_0_0_bits_isVecPartReplay;
  assign in_payload[7907 +: 16] = io_fromOg1VecMem_0_0_bits_vecReplayMask;
  assign in_payload[7923 +: 4] = io_fromOg1VecMem_0_0_bits_vecReplayMbIdx;
  assign in_payload[7927] = io_fromOg1VecMem_0_0_bits_perfDebugInfo_eliminatedMove;
  assign in_payload[7928 +: 64] = io_fromOg1VecMem_0_0_bits_perfDebugInfo_renameTime;
  assign in_payload[7992 +: 64] = io_fromOg1VecMem_0_0_bits_perfDebugInfo_dispatchTime;
  assign in_payload[8056 +: 64] = io_fromOg1VecMem_0_0_bits_perfDebugInfo_enqRsTime;
  assign in_payload[8120 +: 64] = io_fromOg1VecMem_0_0_bits_perfDebugInfo_selectTime;
  assign in_payload[8184 +: 64] = io_fromOg1VecMem_0_0_bits_perfDebugInfo_issueTime;
  assign in_payload[8248 +: 64] = io_fromOg1VecMem_0_0_bits_perfDebugInfo_writebackTime;
  assign in_payload[8312 +: 64] = io_fromOg1VecMem_0_0_bits_perfDebugInfo_runahead_checkpoint_id;
  assign in_payload[8376 +: 64] = io_fromOg1VecMem_0_0_bits_perfDebugInfo_tlbFirstReqTime;
  assign in_payload[8440 +: 64] = io_fromOg1VecMem_0_0_bits_perfDebugInfo_tlbRespTime;
  assign in_payload[8504 +: 56] = io_fromOg1VecMem_0_0_bits_debug_seqNum_seqNum;
  assign in_payload[8560 +: 8] = io_fromOg1VecMem_0_0_bits_debug_seqNum_uopIdx;
  assign io_toVecMemExu_0_0_bits_robIdx_value = out_payload[6965 +: 8];
  assign io_toVecMemExu_0_0_bits_robIdx_flag = out_payload[6973];
  assign io_toVecMemExu_0_0_bits_fuType = out_payload[6974 +: 35];
  assign io_toVecMemExu_0_0_bits_vpu_vuopIdx = out_payload[7009 +: 7];
  assign io_toVecMemExu_0_0_bits_fuOpType = out_payload[7016 +: 9];
  assign io_toVecMemExu_0_0_bits_src_0 = out_payload[7025 +: 128];
  assign io_toVecMemExu_0_0_bits_src_1 = out_payload[7153 +: 128];
  assign io_toVecMemExu_0_0_bits_src_2 = out_payload[7281 +: 128];
  assign io_toVecMemExu_0_0_bits_src_3 = out_payload[7409 +: 128];
  assign io_toVecMemExu_0_0_bits_src_4 = out_payload[7537 +: 128];
  assign io_toVecMemExu_0_0_bits_pdest = out_payload[7665 +: 7];
  assign io_toVecMemExu_0_0_bits_vecWen = out_payload[7672];
  assign io_toVecMemExu_0_0_bits_v0Wen = out_payload[7673];
  assign io_toVecMemExu_0_0_bits_vlWen = out_payload[7674];
  assign io_toVecMemExu_0_0_bits_vpu_vill = out_payload[7675];
  assign io_toVecMemExu_0_0_bits_vpu_vma = out_payload[7676];
  assign io_toVecMemExu_0_0_bits_vpu_vta = out_payload[7677];
  assign io_toVecMemExu_0_0_bits_vpu_vsew = out_payload[7678 +: 2];
  assign io_toVecMemExu_0_0_bits_vpu_vlmul = out_payload[7680 +: 3];
  assign io_toVecMemExu_0_0_bits_vpu_specVill = out_payload[7683];
  assign io_toVecMemExu_0_0_bits_vpu_specVma = out_payload[7684];
  assign io_toVecMemExu_0_0_bits_vpu_specVta = out_payload[7685];
  assign io_toVecMemExu_0_0_bits_vpu_specVsew = out_payload[7686 +: 2];
  assign io_toVecMemExu_0_0_bits_vpu_specVlmul = out_payload[7688 +: 3];
  assign io_toVecMemExu_0_0_bits_vpu_vm = out_payload[7691];
  assign io_toVecMemExu_0_0_bits_vpu_vstart = out_payload[7692 +: 8];
  assign io_toVecMemExu_0_0_bits_vpu_frm = out_payload[7700 +: 3];
  assign io_toVecMemExu_0_0_bits_vpu_fpu_isFpToVecInst = out_payload[7703];
  assign io_toVecMemExu_0_0_bits_vpu_fpu_isFP32Instr = out_payload[7704];
  assign io_toVecMemExu_0_0_bits_vpu_fpu_isFP64Instr = out_payload[7705];
  assign io_toVecMemExu_0_0_bits_vpu_fpu_isReduction = out_payload[7706];
  assign io_toVecMemExu_0_0_bits_vpu_fpu_isFoldTo1_2 = out_payload[7707];
  assign io_toVecMemExu_0_0_bits_vpu_fpu_isFoldTo1_4 = out_payload[7708];
  assign io_toVecMemExu_0_0_bits_vpu_fpu_isFoldTo1_8 = out_payload[7709];
  assign io_toVecMemExu_0_0_bits_vpu_vxrm = out_payload[7710 +: 2];
  assign io_toVecMemExu_0_0_bits_vpu_lastUop = out_payload[7712];
  assign io_toVecMemExu_0_0_bits_vpu_vmask = out_payload[7713 +: 128];
  assign io_toVecMemExu_0_0_bits_vpu_nf = out_payload[7841 +: 3];
  assign io_toVecMemExu_0_0_bits_vpu_veew = out_payload[7844 +: 2];
  assign io_toVecMemExu_0_0_bits_vpu_isReverse = out_payload[7846];
  assign io_toVecMemExu_0_0_bits_vpu_isExt = out_payload[7847];
  assign io_toVecMemExu_0_0_bits_vpu_isNarrow = out_payload[7848];
  assign io_toVecMemExu_0_0_bits_vpu_isDstMask = out_payload[7849];
  assign io_toVecMemExu_0_0_bits_vpu_isOpMask = out_payload[7850];
  assign io_toVecMemExu_0_0_bits_vpu_isMove = out_payload[7851];
  assign io_toVecMemExu_0_0_bits_vpu_isDependOldVd = out_payload[7852];
  assign io_toVecMemExu_0_0_bits_vpu_isWritePartVd = out_payload[7853];
  assign io_toVecMemExu_0_0_bits_vpu_isVleff = out_payload[7854];
  assign io_toVecMemExu_0_0_bits_ftqIdx_flag = out_payload[7855];
  assign io_toVecMemExu_0_0_bits_ftqIdx_value = out_payload[7856 +: 6];
  assign io_toVecMemExu_0_0_bits_ftqOffset = out_payload[7862 +: 4];
  assign io_toVecMemExu_0_0_bits_numLsElem = out_payload[7866 +: 5];
  assign io_toVecMemExu_0_0_bits_sqIdx_flag = out_payload[7871];
  assign io_toVecMemExu_0_0_bits_sqIdx_value = out_payload[7872 +: 6];
  assign io_toVecMemExu_0_0_bits_lqIdx_flag = out_payload[7878];
  assign io_toVecMemExu_0_0_bits_lqIdx_value = out_payload[7879 +: 7];
  assign io_toVecMemExu_0_0_bits_dataSources_0_value = out_payload[7886 +: 4];
  assign io_toVecMemExu_0_0_bits_dataSources_1_value = out_payload[7890 +: 4];
  assign io_toVecMemExu_0_0_bits_dataSources_2_value = out_payload[7894 +: 4];
  assign io_toVecMemExu_0_0_bits_dataSources_3_value = out_payload[7898 +: 4];
  assign io_toVecMemExu_0_0_bits_dataSources_4_value = out_payload[7902 +: 4];
  assign io_toVecMemExu_0_0_bits_isVecPartReplay = out_payload[7906];
  assign io_toVecMemExu_0_0_bits_vecReplayMask = out_payload[7907 +: 16];
  assign io_toVecMemExu_0_0_bits_vecReplayMbIdx = out_payload[7923 +: 4];
  assign io_toVecMemExu_0_0_bits_perfDebugInfo_eliminatedMove = out_payload[7927];
  assign io_toVecMemExu_0_0_bits_perfDebugInfo_renameTime = out_payload[7928 +: 64];
  assign io_toVecMemExu_0_0_bits_perfDebugInfo_dispatchTime = out_payload[7992 +: 64];
  assign io_toVecMemExu_0_0_bits_perfDebugInfo_enqRsTime = out_payload[8056 +: 64];
  assign io_toVecMemExu_0_0_bits_perfDebugInfo_selectTime = out_payload[8120 +: 64];
  assign io_toVecMemExu_0_0_bits_perfDebugInfo_issueTime = out_payload[8184 +: 64];
  assign io_toVecMemExu_0_0_bits_perfDebugInfo_writebackTime = out_payload[8248 +: 64];
  assign io_toVecMemExu_0_0_bits_perfDebugInfo_runahead_checkpoint_id = out_payload[8312 +: 64];
  assign io_toVecMemExu_0_0_bits_perfDebugInfo_tlbFirstReqTime = out_payload[8376 +: 64];
  assign io_toVecMemExu_0_0_bits_perfDebugInfo_tlbRespTime = out_payload[8440 +: 64];
  assign io_toVecMemExu_0_0_bits_debug_seqNum_seqNum = out_payload[8504 +: 56];
  assign io_toVecMemExu_0_0_bits_debug_seqNum_uopIdx = out_payload[8560 +: 8];
  assign io_toMemIQOg2Resp_0_0_valid = out_valid[5];
  assign io_toMemIQOg2Resp_0_0_bits_resp = resp[5];
  assign io_toMemIQOg2Resp_0_0_bits_robIdx_flag = out_payload[6973];
  assign io_toMemIQOg2Resp_0_0_bits_robIdx_value = out_payload[6965 +: 8];
  assign io_toMemIQOg2Resp_0_0_bits_fuType = out_payload[6974 +: 35];
  assign io_toMemIQOg2Resp_0_0_bits_uopIdx = out_payload[7009 +: 7];

  // ---- 通道 6：fromOg1VecMem_1_0 -> toVecMemExu_1_0 ----
  assign in_valid[6]  = io_fromOg1VecMem_1_0_valid;
  assign exu_ready[6] = io_toVecMemExu_1_0_ready;
  assign io_toVecMemExu_1_0_valid = out_valid[6];
  assign in_payload[8568 +: 8] = io_fromOg1VecMem_1_0_bits_robIdx_value;
  assign in_payload[8576] = io_fromOg1VecMem_1_0_bits_robIdx_flag;
  assign in_payload[8577 +: 35] = io_fromOg1VecMem_1_0_bits_fuType;
  assign in_payload[8612 +: 7] = io_fromOg1VecMem_1_0_bits_vpu_vuopIdx;
  assign in_payload[8619 +: 9] = io_fromOg1VecMem_1_0_bits_fuOpType;
  assign in_payload[8628 +: 128] = io_fromOg1VecMem_1_0_bits_src_0;
  assign in_payload[8756 +: 128] = io_fromOg1VecMem_1_0_bits_src_1;
  assign in_payload[8884 +: 128] = io_fromOg1VecMem_1_0_bits_src_2;
  assign in_payload[9012 +: 128] = io_fromOg1VecMem_1_0_bits_src_3;
  assign in_payload[9140 +: 128] = io_fromOg1VecMem_1_0_bits_src_4;
  assign in_payload[9268 +: 7] = io_fromOg1VecMem_1_0_bits_pdest;
  assign in_payload[9275] = io_fromOg1VecMem_1_0_bits_vecWen;
  assign in_payload[9276] = io_fromOg1VecMem_1_0_bits_v0Wen;
  assign in_payload[9277] = io_fromOg1VecMem_1_0_bits_vlWen;
  assign in_payload[9278] = io_fromOg1VecMem_1_0_bits_vpu_vill;
  assign in_payload[9279] = io_fromOg1VecMem_1_0_bits_vpu_vma;
  assign in_payload[9280] = io_fromOg1VecMem_1_0_bits_vpu_vta;
  assign in_payload[9281 +: 2] = io_fromOg1VecMem_1_0_bits_vpu_vsew;
  assign in_payload[9283 +: 3] = io_fromOg1VecMem_1_0_bits_vpu_vlmul;
  assign in_payload[9286] = io_fromOg1VecMem_1_0_bits_vpu_specVill;
  assign in_payload[9287] = io_fromOg1VecMem_1_0_bits_vpu_specVma;
  assign in_payload[9288] = io_fromOg1VecMem_1_0_bits_vpu_specVta;
  assign in_payload[9289 +: 2] = io_fromOg1VecMem_1_0_bits_vpu_specVsew;
  assign in_payload[9291 +: 3] = io_fromOg1VecMem_1_0_bits_vpu_specVlmul;
  assign in_payload[9294] = io_fromOg1VecMem_1_0_bits_vpu_vm;
  assign in_payload[9295 +: 8] = io_fromOg1VecMem_1_0_bits_vpu_vstart;
  assign in_payload[9303 +: 3] = io_fromOg1VecMem_1_0_bits_vpu_frm;
  assign in_payload[9306] = io_fromOg1VecMem_1_0_bits_vpu_fpu_isFpToVecInst;
  assign in_payload[9307] = io_fromOg1VecMem_1_0_bits_vpu_fpu_isFP32Instr;
  assign in_payload[9308] = io_fromOg1VecMem_1_0_bits_vpu_fpu_isFP64Instr;
  assign in_payload[9309] = io_fromOg1VecMem_1_0_bits_vpu_fpu_isReduction;
  assign in_payload[9310] = io_fromOg1VecMem_1_0_bits_vpu_fpu_isFoldTo1_2;
  assign in_payload[9311] = io_fromOg1VecMem_1_0_bits_vpu_fpu_isFoldTo1_4;
  assign in_payload[9312] = io_fromOg1VecMem_1_0_bits_vpu_fpu_isFoldTo1_8;
  assign in_payload[9313 +: 2] = io_fromOg1VecMem_1_0_bits_vpu_vxrm;
  assign in_payload[9315] = io_fromOg1VecMem_1_0_bits_vpu_lastUop;
  assign in_payload[9316 +: 128] = io_fromOg1VecMem_1_0_bits_vpu_vmask;
  assign in_payload[9444 +: 3] = io_fromOg1VecMem_1_0_bits_vpu_nf;
  assign in_payload[9447 +: 2] = io_fromOg1VecMem_1_0_bits_vpu_veew;
  assign in_payload[9449] = io_fromOg1VecMem_1_0_bits_vpu_isReverse;
  assign in_payload[9450] = io_fromOg1VecMem_1_0_bits_vpu_isExt;
  assign in_payload[9451] = io_fromOg1VecMem_1_0_bits_vpu_isNarrow;
  assign in_payload[9452] = io_fromOg1VecMem_1_0_bits_vpu_isDstMask;
  assign in_payload[9453] = io_fromOg1VecMem_1_0_bits_vpu_isOpMask;
  assign in_payload[9454] = io_fromOg1VecMem_1_0_bits_vpu_isMove;
  assign in_payload[9455] = io_fromOg1VecMem_1_0_bits_vpu_isDependOldVd;
  assign in_payload[9456] = io_fromOg1VecMem_1_0_bits_vpu_isWritePartVd;
  assign in_payload[9457] = io_fromOg1VecMem_1_0_bits_vpu_isVleff;
  assign in_payload[9458] = io_fromOg1VecMem_1_0_bits_ftqIdx_flag;
  assign in_payload[9459 +: 6] = io_fromOg1VecMem_1_0_bits_ftqIdx_value;
  assign in_payload[9465 +: 4] = io_fromOg1VecMem_1_0_bits_ftqOffset;
  assign in_payload[9469 +: 5] = io_fromOg1VecMem_1_0_bits_numLsElem;
  assign in_payload[9474] = io_fromOg1VecMem_1_0_bits_sqIdx_flag;
  assign in_payload[9475 +: 6] = io_fromOg1VecMem_1_0_bits_sqIdx_value;
  assign in_payload[9481] = io_fromOg1VecMem_1_0_bits_lqIdx_flag;
  assign in_payload[9482 +: 7] = io_fromOg1VecMem_1_0_bits_lqIdx_value;
  assign in_payload[9489 +: 4] = io_fromOg1VecMem_1_0_bits_dataSources_0_value;
  assign in_payload[9493 +: 4] = io_fromOg1VecMem_1_0_bits_dataSources_1_value;
  assign in_payload[9497 +: 4] = io_fromOg1VecMem_1_0_bits_dataSources_2_value;
  assign in_payload[9501 +: 4] = io_fromOg1VecMem_1_0_bits_dataSources_3_value;
  assign in_payload[9505 +: 4] = io_fromOg1VecMem_1_0_bits_dataSources_4_value;
  assign in_payload[9509] = io_fromOg1VecMem_1_0_bits_isVecPartReplay;
  assign in_payload[9510 +: 16] = io_fromOg1VecMem_1_0_bits_vecReplayMask;
  assign in_payload[9526 +: 4] = io_fromOg1VecMem_1_0_bits_vecReplayMbIdx;
  assign in_payload[9530] = io_fromOg1VecMem_1_0_bits_perfDebugInfo_eliminatedMove;
  assign in_payload[9531 +: 64] = io_fromOg1VecMem_1_0_bits_perfDebugInfo_renameTime;
  assign in_payload[9595 +: 64] = io_fromOg1VecMem_1_0_bits_perfDebugInfo_dispatchTime;
  assign in_payload[9659 +: 64] = io_fromOg1VecMem_1_0_bits_perfDebugInfo_enqRsTime;
  assign in_payload[9723 +: 64] = io_fromOg1VecMem_1_0_bits_perfDebugInfo_selectTime;
  assign in_payload[9787 +: 64] = io_fromOg1VecMem_1_0_bits_perfDebugInfo_issueTime;
  assign in_payload[9851 +: 64] = io_fromOg1VecMem_1_0_bits_perfDebugInfo_writebackTime;
  assign in_payload[9915 +: 64] = io_fromOg1VecMem_1_0_bits_perfDebugInfo_runahead_checkpoint_id;
  assign in_payload[9979 +: 64] = io_fromOg1VecMem_1_0_bits_perfDebugInfo_tlbFirstReqTime;
  assign in_payload[10043 +: 64] = io_fromOg1VecMem_1_0_bits_perfDebugInfo_tlbRespTime;
  assign in_payload[10107 +: 56] = io_fromOg1VecMem_1_0_bits_debug_seqNum_seqNum;
  assign in_payload[10163 +: 8] = io_fromOg1VecMem_1_0_bits_debug_seqNum_uopIdx;
  assign io_toVecMemExu_1_0_bits_robIdx_value = out_payload[8568 +: 8];
  assign io_toVecMemExu_1_0_bits_robIdx_flag = out_payload[8576];
  assign io_toVecMemExu_1_0_bits_fuType = out_payload[8577 +: 35];
  assign io_toVecMemExu_1_0_bits_vpu_vuopIdx = out_payload[8612 +: 7];
  assign io_toVecMemExu_1_0_bits_fuOpType = out_payload[8619 +: 9];
  assign io_toVecMemExu_1_0_bits_src_0 = out_payload[8628 +: 128];
  assign io_toVecMemExu_1_0_bits_src_1 = out_payload[8756 +: 128];
  assign io_toVecMemExu_1_0_bits_src_2 = out_payload[8884 +: 128];
  assign io_toVecMemExu_1_0_bits_src_3 = out_payload[9012 +: 128];
  assign io_toVecMemExu_1_0_bits_src_4 = out_payload[9140 +: 128];
  assign io_toVecMemExu_1_0_bits_pdest = out_payload[9268 +: 7];
  assign io_toVecMemExu_1_0_bits_vecWen = out_payload[9275];
  assign io_toVecMemExu_1_0_bits_v0Wen = out_payload[9276];
  assign io_toVecMemExu_1_0_bits_vlWen = out_payload[9277];
  assign io_toVecMemExu_1_0_bits_vpu_vill = out_payload[9278];
  assign io_toVecMemExu_1_0_bits_vpu_vma = out_payload[9279];
  assign io_toVecMemExu_1_0_bits_vpu_vta = out_payload[9280];
  assign io_toVecMemExu_1_0_bits_vpu_vsew = out_payload[9281 +: 2];
  assign io_toVecMemExu_1_0_bits_vpu_vlmul = out_payload[9283 +: 3];
  assign io_toVecMemExu_1_0_bits_vpu_specVill = out_payload[9286];
  assign io_toVecMemExu_1_0_bits_vpu_specVma = out_payload[9287];
  assign io_toVecMemExu_1_0_bits_vpu_specVta = out_payload[9288];
  assign io_toVecMemExu_1_0_bits_vpu_specVsew = out_payload[9289 +: 2];
  assign io_toVecMemExu_1_0_bits_vpu_specVlmul = out_payload[9291 +: 3];
  assign io_toVecMemExu_1_0_bits_vpu_vm = out_payload[9294];
  assign io_toVecMemExu_1_0_bits_vpu_vstart = out_payload[9295 +: 8];
  assign io_toVecMemExu_1_0_bits_vpu_frm = out_payload[9303 +: 3];
  assign io_toVecMemExu_1_0_bits_vpu_fpu_isFpToVecInst = out_payload[9306];
  assign io_toVecMemExu_1_0_bits_vpu_fpu_isFP32Instr = out_payload[9307];
  assign io_toVecMemExu_1_0_bits_vpu_fpu_isFP64Instr = out_payload[9308];
  assign io_toVecMemExu_1_0_bits_vpu_fpu_isReduction = out_payload[9309];
  assign io_toVecMemExu_1_0_bits_vpu_fpu_isFoldTo1_2 = out_payload[9310];
  assign io_toVecMemExu_1_0_bits_vpu_fpu_isFoldTo1_4 = out_payload[9311];
  assign io_toVecMemExu_1_0_bits_vpu_fpu_isFoldTo1_8 = out_payload[9312];
  assign io_toVecMemExu_1_0_bits_vpu_vxrm = out_payload[9313 +: 2];
  assign io_toVecMemExu_1_0_bits_vpu_lastUop = out_payload[9315];
  assign io_toVecMemExu_1_0_bits_vpu_vmask = out_payload[9316 +: 128];
  assign io_toVecMemExu_1_0_bits_vpu_nf = out_payload[9444 +: 3];
  assign io_toVecMemExu_1_0_bits_vpu_veew = out_payload[9447 +: 2];
  assign io_toVecMemExu_1_0_bits_vpu_isReverse = out_payload[9449];
  assign io_toVecMemExu_1_0_bits_vpu_isExt = out_payload[9450];
  assign io_toVecMemExu_1_0_bits_vpu_isNarrow = out_payload[9451];
  assign io_toVecMemExu_1_0_bits_vpu_isDstMask = out_payload[9452];
  assign io_toVecMemExu_1_0_bits_vpu_isOpMask = out_payload[9453];
  assign io_toVecMemExu_1_0_bits_vpu_isMove = out_payload[9454];
  assign io_toVecMemExu_1_0_bits_vpu_isDependOldVd = out_payload[9455];
  assign io_toVecMemExu_1_0_bits_vpu_isWritePartVd = out_payload[9456];
  assign io_toVecMemExu_1_0_bits_vpu_isVleff = out_payload[9457];
  assign io_toVecMemExu_1_0_bits_ftqIdx_flag = out_payload[9458];
  assign io_toVecMemExu_1_0_bits_ftqIdx_value = out_payload[9459 +: 6];
  assign io_toVecMemExu_1_0_bits_ftqOffset = out_payload[9465 +: 4];
  assign io_toVecMemExu_1_0_bits_numLsElem = out_payload[9469 +: 5];
  assign io_toVecMemExu_1_0_bits_sqIdx_flag = out_payload[9474];
  assign io_toVecMemExu_1_0_bits_sqIdx_value = out_payload[9475 +: 6];
  assign io_toVecMemExu_1_0_bits_lqIdx_flag = out_payload[9481];
  assign io_toVecMemExu_1_0_bits_lqIdx_value = out_payload[9482 +: 7];
  assign io_toVecMemExu_1_0_bits_dataSources_0_value = out_payload[9489 +: 4];
  assign io_toVecMemExu_1_0_bits_dataSources_1_value = out_payload[9493 +: 4];
  assign io_toVecMemExu_1_0_bits_dataSources_2_value = out_payload[9497 +: 4];
  assign io_toVecMemExu_1_0_bits_dataSources_3_value = out_payload[9501 +: 4];
  assign io_toVecMemExu_1_0_bits_dataSources_4_value = out_payload[9505 +: 4];
  assign io_toVecMemExu_1_0_bits_isVecPartReplay = out_payload[9509];
  assign io_toVecMemExu_1_0_bits_vecReplayMask = out_payload[9510 +: 16];
  assign io_toVecMemExu_1_0_bits_vecReplayMbIdx = out_payload[9526 +: 4];
  assign io_toVecMemExu_1_0_bits_perfDebugInfo_eliminatedMove = out_payload[9530];
  assign io_toVecMemExu_1_0_bits_perfDebugInfo_renameTime = out_payload[9531 +: 64];
  assign io_toVecMemExu_1_0_bits_perfDebugInfo_dispatchTime = out_payload[9595 +: 64];
  assign io_toVecMemExu_1_0_bits_perfDebugInfo_enqRsTime = out_payload[9659 +: 64];
  assign io_toVecMemExu_1_0_bits_perfDebugInfo_selectTime = out_payload[9723 +: 64];
  assign io_toVecMemExu_1_0_bits_perfDebugInfo_issueTime = out_payload[9787 +: 64];
  assign io_toVecMemExu_1_0_bits_perfDebugInfo_writebackTime = out_payload[9851 +: 64];
  assign io_toVecMemExu_1_0_bits_perfDebugInfo_runahead_checkpoint_id = out_payload[9915 +: 64];
  assign io_toVecMemExu_1_0_bits_perfDebugInfo_tlbFirstReqTime = out_payload[9979 +: 64];
  assign io_toVecMemExu_1_0_bits_perfDebugInfo_tlbRespTime = out_payload[10043 +: 64];
  assign io_toVecMemExu_1_0_bits_debug_seqNum_seqNum = out_payload[10107 +: 56];
  assign io_toVecMemExu_1_0_bits_debug_seqNum_uopIdx = out_payload[10163 +: 8];
  assign io_toMemIQOg2Resp_1_0_valid = out_valid[6];
  assign io_toMemIQOg2Resp_1_0_bits_resp = resp[6];
  assign io_toMemIQOg2Resp_1_0_bits_robIdx_flag = out_payload[8576];
  assign io_toMemIQOg2Resp_1_0_bits_robIdx_value = out_payload[8568 +: 8];
  assign io_toMemIQOg2Resp_1_0_bits_fuType = out_payload[8577 +: 35];
  assign io_toMemIQOg2Resp_1_0_bits_uopIdx = out_payload[8612 +: 7];
endmodule
// END GENERATED
