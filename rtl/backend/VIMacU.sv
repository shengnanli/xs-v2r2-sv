// =============================================================================
// VIMacU.sv — 向量整数乘加功能单元外壳。
//
// 本模块接收向量整数乘法、乘加、乘减及定点乘法 uop，使用两个 VIMac64b
// 并行处理 128-bit 向量，再由 Mgu 按 mask、tail、vl 和 vstart 合并结果。
// 输入 valid 经过两级流水；性能/调试信息与流水 valid 同步搬运。
//
// 结构：
//   §1 私有调试信息类型
//   §2 xs_VIMacU_core：输入解码、两级 valid/调试流水、MAC 阵列及 Mgu
//   §3 VIMacU：golden 同名薄 wrapper
// =============================================================================
package vimacu_pkg;
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
    logic [55:0] seqNum;
    logic [7:0]  seqNum_uopIdx;
  } debug_info_t;
endpackage

// -----------------------------------------------------------------------------
// xs_VIMacU_core — VIMacU 可读实现核
// -----------------------------------------------------------------------------
module xs_VIMacU_core
  import vimacu_pkg::*;
(
  input  logic         clock,
  input  logic         reset,

  output logic         in_ready,
  input  logic         in_valid,
  input  logic [8:0]   in_fuOpType,
  input  logic [1:0]   in_vsew,
  input  logic [6:0]   in_vuopIdx,

  input  logic [8:0]   pipe_fuOpType,
  input  logic         pipe_robIdx_flag,
  input  logic [7:0]   pipe_robIdx_value,
  input  logic [7:0]   pipe_pdest,
  input  logic         pipe_vecWen,
  input  logic         pipe_v0Wen,
  input  logic         pipe_vma,
  input  logic         pipe_vta,
  input  logic [1:0]   pipe_vsew,
  input  logic         pipe_vm,
  input  logic [7:0]   pipe_vstart,
  input  logic [6:0]   pipe_vuopIdx,
  input  logic         pipe_valid,

  input  logic [127:0] src_2,
  input  logic [127:0] src_1,
  input  logic [127:0] src_0,
  input  logic [7:0]   pipe_src_4,
  input  logic [127:0] pipe_src_3,
  input  logic [127:0] pipe_src_2,

  input  logic         in_eliminatedMove,
  input  logic [63:0]  in_renameTime,
  input  logic [63:0]  in_dispatchTime,
  input  logic [63:0]  in_enqRsTime,
  input  logic [63:0]  in_selectTime,
  input  logic [63:0]  in_issueTime,
  input  logic [63:0]  in_writebackTime,
  input  logic [63:0]  in_runahead_checkpoint_id,
  input  logic [63:0]  in_tlbFirstReqTime,
  input  logic [63:0]  in_tlbRespTime,
  input  logic [55:0]  in_seqNum,
  input  logic [7:0]   in_seqNum_uopIdx,

  input  logic         out_ready,
  output logic         out_valid,
  output logic         out_robIdx_flag,
  output logic [7:0]   out_robIdx_value,
  output logic [7:0]   out_pdest,
  output logic         out_vecWen,
  output logic         out_v0Wen,
  output logic [127:0] out_res_data,
  output logic         out_res_vxsat,
  output debug_info_t  out_debug,

  input  logic [1:0]   vxrm
);

  logic valid_stage1;
  logic valid_stage2;
  logic ready_stage1;

  assign ready_stage1 = ~valid_stage2 | out_ready;
  assign in_ready     = ~valid_stage1 | ready_stage1;

  debug_info_t debug_stage1;
  debug_info_t debug_stage2;

  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      valid_stage1 <= 1'b0;
      valid_stage2 <= 1'b0;
    end else begin
      valid_stage1 <= in_valid;
      valid_stage2 <= valid_stage1;
    end
  end

  always_ff @(posedge clock) begin
    if (in_ready && in_valid) begin
      debug_stage1.eliminatedMove         <= in_eliminatedMove;
      debug_stage1.renameTime             <= in_renameTime;
      debug_stage1.dispatchTime           <= in_dispatchTime;
      debug_stage1.enqRsTime              <= in_enqRsTime;
      debug_stage1.selectTime             <= in_selectTime;
      debug_stage1.issueTime              <= in_issueTime;
      debug_stage1.writebackTime          <= in_writebackTime;
      debug_stage1.runahead_checkpoint_id <= in_runahead_checkpoint_id;
      debug_stage1.tlbFirstReqTime        <= in_tlbFirstReqTime;
      debug_stage1.tlbRespTime            <= in_tlbRespTime;
      debug_stage1.seqNum                 <= in_seqNum;
      debug_stage1.seqNum_uopIdx          <= in_seqNum_uopIdx;
    end

    if (ready_stage1 && valid_stage1) begin
      debug_stage2 <= debug_stage1;
    end
  end

  logic [3:0]  vs1_type;
  logic [3:0]  vs2_type;
  logic [31:0] vs1_32_0, vs1_32_1, vs1_32_2, vs1_32_3;
  logic [63:0] vs1_64_0, vs1_64_1;
  logic [31:0] vs2_32_0, vs2_32_1, vs2_32_2, vs2_32_3;
  logic [63:0] vs2_64_0, vs2_64_1;
  logic [63:0] old_vd_64_0, old_vd_64_1;

  VIMacSrcTypeModule typeMod (
    .io_in_fuOpType (in_fuOpType),
    .io_in_vsew     (in_vsew),
    .io_out_vs1Type (vs1_type),
    .io_out_vs2Type (vs2_type)
  );

  VecDataSplitModule vs2Split (
    .io_inVecData  (src_1),
    .io_outVec32b_0(vs2_32_0),
    .io_outVec32b_1(vs2_32_1),
    .io_outVec32b_2(vs2_32_2),
    .io_outVec32b_3(vs2_32_3),
    .io_outVec64b_0(vs2_64_0),
    .io_outVec64b_1(vs2_64_1)
  );

  VecDataSplitModule vs1Split (
    .io_inVecData  (src_0),
    .io_outVec32b_0(vs1_32_0),
    .io_outVec32b_1(vs1_32_1),
    .io_outVec32b_2(vs1_32_2),
    .io_outVec32b_3(vs1_32_3),
    .io_outVec64b_0(vs1_64_0),
    .io_outVec64b_1(vs1_64_1)
  );

  VecDataSplitModule oldVdSplit (
    .io_inVecData  (src_2),
    .io_outVec64b_0(old_vd_64_0),
    .io_outVec64b_1(old_vd_64_1)
  );

  logic is_vmacc;
  logic is_vnmsac;
  logic is_vmadd;
  logic is_vnmsub;
  logic addend_is_vs2;
  logic is_vmulh;
  logic is_macc;
  logic is_sub;
  logic is_widen;
  logic is_vsmul;

  logic [63:0] vs1_used_0, vs1_used_1;
  logic [63:0] vs2_used_0, vs2_used_1;
  logic [63:0] old_used_0, old_used_1;

  // fuOpType[2:0] 编码（RVV 整数乘加）：0 vmul / 1 vmulh / 2 vmacc / 3 vnmsac / 4 vmadd / 5 vnmsub / 6 vsmul；
  // fuOpType[3] = 加宽（vwmul*/vwmacc*）。vmacc/vnmsac 是 vd = ±(vs1*vs2) + vd；vmadd/vnmsub 是 vd = ±(vs1*vd) + vs2，
  // 所以后两者把 vs2 与旧 vd 对调送进乘加器（addend_is_vs2）。
  assign is_vmulh      = in_fuOpType[2:0] == 3'h1;
  assign is_vmacc      = in_fuOpType[2:0] == 3'h2;
  assign is_vnmsac     = in_fuOpType[2:0] == 3'h3;
  assign is_vmadd      = in_fuOpType[2:0] == 3'h4;
  assign is_vnmsub     = in_fuOpType[2:0] == 3'h5;
  assign is_vsmul      = in_fuOpType[2:0] == 3'h6;
  assign is_widen      = in_fuOpType[3];
  assign is_macc       = is_vmacc | is_vnmsac | is_vmadd | is_vnmsub;
  assign is_sub        = is_vnmsac | is_vnmsub;
  assign addend_is_vs2 = is_vmadd | is_vnmsub;

  assign vs1_used_0 = is_widen ? {vs1_32_2, vs1_32_0} : vs1_64_0;
  assign vs1_used_1 = is_widen ? {vs1_32_3, vs1_32_1} : vs1_64_1;

  assign vs2_used_0 = addend_is_vs2 ? old_vd_64_0 :
                      (is_widen ? {vs2_32_2, vs2_32_0} : vs2_64_0);
  assign vs2_used_1 = addend_is_vs2 ? old_vd_64_1 :
                      (is_widen ? {vs2_32_3, vs2_32_1} : vs2_64_1);

  assign old_used_0 = addend_is_vs2 ?
                      (is_widen ? {vs2_32_2, vs2_32_0} : vs2_64_0) :
                      old_vd_64_0;
  assign old_used_1 = addend_is_vs2 ?
                      (is_widen ? {vs2_32_3, vs2_32_1} : vs2_64_1) :
                      old_vd_64_1;

  logic [63:0] mac_vd_0;
  logic [63:0] mac_vd_1;
  logic [7:0]  mac_sat_0;
  logic [7:0]  mac_sat_1;
  logic [15:0] mgu_active;

  VIMac64b vimacs_0 (
    .clock          (clock),
    .reset          (reset),
    .io_fire        (in_valid),
    .io_info_uopIdx (in_vuopIdx[5:0]),
    .io_info_vxrm   (vxrm),
    .io_srcType_0   (vs2_type),
    .io_srcType_1   (vs1_type),
    .io_vs1         (vs1_used_0),
    .io_vs2         (vs2_used_0),
    .io_oldVd       (old_used_0),
    .io_highHalf    (is_vmulh),
    .io_isMacc      (is_macc),
    .io_isSub       (is_sub),
    .io_widen       (is_widen),
    .io_isFixP       (is_vsmul),
    .io_vd           (mac_vd_0),
    .io_vxsat        (mac_sat_0)
  );

  VIMac64b vimacs_1 (
    .clock          (clock),
    .reset          (reset),
    .io_fire        (in_valid),
    .io_info_uopIdx (in_vuopIdx[5:0]),
    .io_info_vxrm   (vxrm),
    .io_srcType_0   (vs2_type),
    .io_srcType_1   (vs1_type),
    .io_vs1         (vs1_used_1),
    .io_vs2         (vs2_used_1),
    .io_oldVd       (old_used_1),
    .io_highHalf    (is_vmulh),
    .io_isMacc      (is_macc),
    .io_isSub       (is_sub),
    .io_widen       (is_widen),
    .io_isFixP       (is_vsmul),
    .io_vd           (mac_vd_1),
    .io_vxsat        (mac_sat_1)
  );

  Mgu mgu (
    .io_in_vd          ({mac_vd_1, mac_vd_0}),
    .io_in_oldVd       (pipe_src_2),
    .io_in_mask        (pipe_vm
                        ? 128'hFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
                        : pipe_src_3),
    .io_in_info_ta     (pipe_vta),
    .io_in_info_ma     (pipe_vma),
    .io_in_info_vl     (pipe_src_4),
    .io_in_info_vstart (pipe_vstart),
    .io_in_info_eew    (pipe_fuOpType[3]
                        ? 2'(pipe_vsew + 2'h1)
                        : pipe_vsew),
    .io_in_info_vdIdx  (pipe_vuopIdx[2:0]),
    .io_in_info_narrow (1'b0),
    .io_in_info_dstMask(1'b0),
    .io_out_vd         (out_res_data),
    .io_out_active     (mgu_active)
  );

  assign out_valid       = pipe_valid & valid_stage2;
  assign out_robIdx_flag = pipe_robIdx_flag;
  assign out_robIdx_value = pipe_robIdx_value;
  assign out_pdest       = pipe_pdest;
  assign out_vecWen      = pipe_vecWen;
  assign out_v0Wen       = pipe_v0Wen;
  assign out_res_vxsat   = |({mac_sat_1, mac_sat_0} & mgu_active);
  assign out_debug       = debug_stage2;

endmodule

// -----------------------------------------------------------------------------
// VIMacU — golden 同名薄 wrapper
// -----------------------------------------------------------------------------
module VIMacU (
  input          clock,
  input          reset,
  output         io_in_ready,
  input          io_in_valid,
  input  [8:0]   io_in_bits_ctrl_fuOpType,
  input  [1:0]   io_in_bits_ctrl_vpu_vsew,
  input  [6:0]   io_in_bits_ctrl_vpu_vuopIdx,
  input  [8:0]   io_in_bits_ctrlPipe_2_fuOpType,
  input          io_in_bits_ctrlPipe_2_robIdx_flag,
  input  [7:0]   io_in_bits_ctrlPipe_2_robIdx_value,
  input  [7:0]   io_in_bits_ctrlPipe_2_pdest,
  input          io_in_bits_ctrlPipe_2_vecWen,
  input          io_in_bits_ctrlPipe_2_v0Wen,
  input          io_in_bits_ctrlPipe_2_vpu_vma,
  input          io_in_bits_ctrlPipe_2_vpu_vta,
  input  [1:0]   io_in_bits_ctrlPipe_2_vpu_vsew,
  input          io_in_bits_ctrlPipe_2_vpu_vm,
  input  [7:0]   io_in_bits_ctrlPipe_2_vpu_vstart,
  input  [6:0]   io_in_bits_ctrlPipe_2_vpu_vuopIdx,
  input          io_in_bits_validPipe_2,
  input  [127:0] io_in_bits_data_src_2,
  input  [127:0] io_in_bits_data_src_1,
  input  [127:0] io_in_bits_data_src_0,
  input  [7:0]   io_in_bits_dataPipe_2_src_4,
  input  [127:0] io_in_bits_dataPipe_2_src_3,
  input  [127:0] io_in_bits_dataPipe_2_src_2,
  input          io_in_bits_perfDebugInfo_eliminatedMove,
  input  [63:0]  io_in_bits_perfDebugInfo_renameTime,
  input  [63:0]  io_in_bits_perfDebugInfo_dispatchTime,
  input  [63:0]  io_in_bits_perfDebugInfo_enqRsTime,
  input  [63:0]  io_in_bits_perfDebugInfo_selectTime,
  input  [63:0]  io_in_bits_perfDebugInfo_issueTime,
  input  [63:0]  io_in_bits_perfDebugInfo_writebackTime,
  input  [63:0]  io_in_bits_perfDebugInfo_runahead_checkpoint_id,
  input  [63:0]  io_in_bits_perfDebugInfo_tlbFirstReqTime,
  input  [63:0]  io_in_bits_perfDebugInfo_tlbRespTime,
  input  [55:0]  io_in_bits_debug_seqNum_seqNum,
  input  [7:0]   io_in_bits_debug_seqNum_uopIdx,
  input          io_out_ready,
  output         io_out_valid,
  output         io_out_bits_ctrl_robIdx_flag,
  output [7:0]   io_out_bits_ctrl_robIdx_value,
  output [7:0]   io_out_bits_ctrl_pdest,
  output         io_out_bits_ctrl_vecWen,
  output         io_out_bits_ctrl_v0Wen,
  output [127:0] io_out_bits_res_data,
  output         io_out_bits_res_vxsat,
  output         io_out_bits_perfDebugInfo_eliminatedMove,
  output [63:0]  io_out_bits_perfDebugInfo_renameTime,
  output [63:0]  io_out_bits_perfDebugInfo_dispatchTime,
  output [63:0]  io_out_bits_perfDebugInfo_enqRsTime,
  output [63:0]  io_out_bits_perfDebugInfo_selectTime,
  output [63:0]  io_out_bits_perfDebugInfo_issueTime,
  output [63:0]  io_out_bits_perfDebugInfo_writebackTime,
  output [63:0]  io_out_bits_perfDebugInfo_runahead_checkpoint_id,
  output [63:0]  io_out_bits_perfDebugInfo_tlbFirstReqTime,
  output [63:0]  io_out_bits_perfDebugInfo_tlbRespTime,
  output [55:0]  io_out_bits_debug_seqNum_seqNum,
  output [7:0]   io_out_bits_debug_seqNum_uopIdx,
  input  [1:0]   io_vxrm
);

  vimacu_pkg::debug_info_t debug_out;

  xs_VIMacU_core u_core (
    .clock              (clock),
    .reset              (reset),
    .in_ready           (io_in_ready),
    .in_valid           (io_in_valid),
    .in_fuOpType        (io_in_bits_ctrl_fuOpType),
    .in_vsew            (io_in_bits_ctrl_vpu_vsew),
    .in_vuopIdx          (io_in_bits_ctrl_vpu_vuopIdx),
    .pipe_fuOpType      (io_in_bits_ctrlPipe_2_fuOpType),
    .pipe_robIdx_flag   (io_in_bits_ctrlPipe_2_robIdx_flag),
    .pipe_robIdx_value  (io_in_bits_ctrlPipe_2_robIdx_value),
    .pipe_pdest         (io_in_bits_ctrlPipe_2_pdest),
    .pipe_vecWen        (io_in_bits_ctrlPipe_2_vecWen),
    .pipe_v0Wen         (io_in_bits_ctrlPipe_2_v0Wen),
    .pipe_vma           (io_in_bits_ctrlPipe_2_vpu_vma),
    .pipe_vta           (io_in_bits_ctrlPipe_2_vpu_vta),
    .pipe_vsew          (io_in_bits_ctrlPipe_2_vpu_vsew),
    .pipe_vm            (io_in_bits_ctrlPipe_2_vpu_vm),
    .pipe_vstart        (io_in_bits_ctrlPipe_2_vpu_vstart),
    .pipe_vuopIdx       (io_in_bits_ctrlPipe_2_vpu_vuopIdx),
    .pipe_valid         (io_in_bits_validPipe_2),
    .src_2              (io_in_bits_data_src_2),
    .src_1              (io_in_bits_data_src_1),
    .src_0              (io_in_bits_data_src_0),
    .pipe_src_4         (io_in_bits_dataPipe_2_src_4),
    .pipe_src_3         (io_in_bits_dataPipe_2_src_3),
    .pipe_src_2         (io_in_bits_dataPipe_2_src_2),
    .in_eliminatedMove  (io_in_bits_perfDebugInfo_eliminatedMove),
    .in_renameTime      (io_in_bits_perfDebugInfo_renameTime),
    .in_dispatchTime    (io_in_bits_perfDebugInfo_dispatchTime),
    .in_enqRsTime       (io_in_bits_perfDebugInfo_enqRsTime),
    .in_selectTime      (io_in_bits_perfDebugInfo_selectTime),
    .in_issueTime       (io_in_bits_perfDebugInfo_issueTime),
    .in_writebackTime   (io_in_bits_perfDebugInfo_writebackTime),
    .in_runahead_checkpoint_id
                        (io_in_bits_perfDebugInfo_runahead_checkpoint_id),
    .in_tlbFirstReqTime (io_in_bits_perfDebugInfo_tlbFirstReqTime),
    .in_tlbRespTime     (io_in_bits_perfDebugInfo_tlbRespTime),
    .in_seqNum          (io_in_bits_debug_seqNum_seqNum),
    .in_seqNum_uopIdx   (io_in_bits_debug_seqNum_uopIdx),
    .out_ready          (io_out_ready),
    .out_valid          (io_out_valid),
    .out_robIdx_flag    (io_out_bits_ctrl_robIdx_flag),
    .out_robIdx_value   (io_out_bits_ctrl_robIdx_value),
    .out_pdest          (io_out_bits_ctrl_pdest),
    .out_vecWen         (io_out_bits_ctrl_vecWen),
    .out_v0Wen          (io_out_bits_ctrl_v0Wen),
    .out_res_data       (io_out_bits_res_data),
    .out_res_vxsat      (io_out_bits_res_vxsat),
    .out_debug          (debug_out),
    .vxrm               (io_vxrm)
  );

  assign io_out_bits_perfDebugInfo_eliminatedMove         = debug_out.eliminatedMove;
  assign io_out_bits_perfDebugInfo_renameTime             = debug_out.renameTime;
  assign io_out_bits_perfDebugInfo_dispatchTime           = debug_out.dispatchTime;
  assign io_out_bits_perfDebugInfo_enqRsTime              = debug_out.enqRsTime;
  assign io_out_bits_perfDebugInfo_selectTime             = debug_out.selectTime;
  assign io_out_bits_perfDebugInfo_issueTime              = debug_out.issueTime;
  assign io_out_bits_perfDebugInfo_writebackTime          = debug_out.writebackTime;
  assign io_out_bits_perfDebugInfo_runahead_checkpoint_id = debug_out.runahead_checkpoint_id;
  assign io_out_bits_perfDebugInfo_tlbFirstReqTime        = debug_out.tlbFirstReqTime;
  assign io_out_bits_perfDebugInfo_tlbRespTime            = debug_out.tlbRespTime;
  assign io_out_bits_debug_seqNum_seqNum                  = debug_out.seqNum;
  assign io_out_bits_debug_seqNum_uopIdx                  = debug_out.seqNum_uopIdx;

endmodule
