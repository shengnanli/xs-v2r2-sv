// =============================================================================
// ExeUnit_14 —— 执行单元外壳（golden 同名 wrapper；由 scripts/gen_exeunit.py 从 G1 golden 生成，勿手改）
// -----------------------------------------------------------------------------
// FU（按 Dispatcher 出口序）：Vfalu(VFAlu, 延迟 1, 门控), Vfcvt(VCVT_8, 延迟 2, 门控), Vipu(VIPU, 延迟 2, 门控), VSetRvfWvf(VSetRvfWvf, 延迟 0)
// inPipe：2 级；字段 robIdx[9]×2级, fuOpType[9]×1级, src_2[128]×2级, src_3[128]×2级, src_4[128]×2级, pdest[8]×2级, rfWen[1]×2级, fpWen[1]×1级, vecWen[1]×2级, v0Wen[1]×2级, fpu_wflags[1]×2级, vpu_vma[1]×2级, vpu_vta[1]×2级, vpu_vsew[2]×1级, vpu_vlmul[3]×1级, vpu_vm[1]×2级, vpu_vstart[8]×2级, vpu_fpu_isFoldTo1_2[1]×1级, vpu_fpu_isFoldTo1_4[1]×1级, vpu_fpu_isFoldTo1_8[1]×1级, vpu_vuopIdx[7]×2级, vpu_lastUop[1]×1级, vpu_isNarrow[1]×1级, vpu_isDstMask[1]×2级
// 机制全部在 xs_ExeUnit_core（发射握手 / inPipe 冲刷流水 / 时钟门控使能 / 写回有效）与
//   xs_ExeUnit_wbsel（写回字段 Mux1H）里；本文件只有例化、连线与字段打包。
// 子模块：Dispatcher 与各 FU、ClockGate 均为已签核件（两侧白盒，实例名与 golden 相同）。
// golden 对照：G1-canonical/golden-rtl/ExeUnit_14.sv
// 本文件导航（一个 golden 模块一个文件，不拆；行号由生成器回填）：
//   L114   子模块输出线（名字 = golden 的 _<实例>_<端口> 去掉前导下划线）
//   L286   外壳控制核
//   L331   inPipe 第 s 级字段拆包（只拆有 FU 读的那些）
//   L373   Dispatcher：按 fuType 把指令派给一个 FU
//   L493   功能单元
//   L757   时钟门控（E 来自核 §3；TE 来自 DFT 的 cg_bore）
//   L777   写回：io.out.valid 与各字段的 Mux1H
// =============================================================================
module ExeUnit_14(
  input          clock,
  input          reset,
  input          io_flush_valid,
  input          io_flush_bits_robIdx_flag,
  input  [7:0]   io_flush_bits_robIdx_value,
  input          io_flush_bits_level,
  output         io_in_ready,
  input          io_in_valid,
  input  [34:0]  io_in_bits_fuType,
  input  [8:0]   io_in_bits_fuOpType,
  input  [127:0] io_in_bits_src_0,
  input  [127:0] io_in_bits_src_1,
  input  [127:0] io_in_bits_src_2,
  input  [127:0] io_in_bits_src_3,
  input  [127:0] io_in_bits_src_4,
  input          io_in_bits_robIdx_flag,
  input  [7:0]   io_in_bits_robIdx_value,
  input  [7:0]   io_in_bits_pdest,
  input          io_in_bits_rfWen,
  input          io_in_bits_fpWen,
  input          io_in_bits_vecWen,
  input          io_in_bits_v0Wen,
  input          io_in_bits_vlWen,
  input          io_in_bits_fpu_wflags,
  input          io_in_bits_vpu_vma,
  input          io_in_bits_vpu_vta,
  input  [1:0]   io_in_bits_vpu_vsew,
  input  [2:0]   io_in_bits_vpu_vlmul,
  input          io_in_bits_vpu_vm,
  input  [7:0]   io_in_bits_vpu_vstart,
  input          io_in_bits_vpu_fpu_isFoldTo1_2,
  input          io_in_bits_vpu_fpu_isFoldTo1_4,
  input          io_in_bits_vpu_fpu_isFoldTo1_8,
  input  [6:0]   io_in_bits_vpu_vuopIdx,
  input          io_in_bits_vpu_lastUop,
  input          io_in_bits_vpu_isNarrow,
  input          io_in_bits_vpu_isDstMask,
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
  output [127:0] io_out_bits_data_0,
  output [127:0] io_out_bits_data_1,
  output [127:0] io_out_bits_data_2,
  output [127:0] io_out_bits_data_3,
  output [127:0] io_out_bits_data_4,
  output [127:0] io_out_bits_data_5,
  output [7:0]   io_out_bits_pdest,
  output         io_out_bits_robIdx_flag,
  output [7:0]   io_out_bits_robIdx_value,
  output         io_out_bits_intWen,
  output         io_out_bits_fpWen,
  output         io_out_bits_vecWen,
  output         io_out_bits_v0Wen,
  output         io_out_bits_vlWen,
  output [4:0]   io_out_bits_fflags,
  output         io_out_bits_wflags,
  output         io_out_bits_exceptionVec_2,
  output         io_out_bits_debugInfo_eliminatedMove,
  output [63:0]  io_out_bits_debugInfo_renameTime,
  output [63:0]  io_out_bits_debugInfo_dispatchTime,
  output [63:0]  io_out_bits_debugInfo_enqRsTime,
  output [63:0]  io_out_bits_debugInfo_selectTime,
  output [63:0]  io_out_bits_debugInfo_issueTime,
  output [63:0]  io_out_bits_debugInfo_writebackTime,
  output [63:0]  io_out_bits_debugInfo_runahead_checkpoint_id,
  output [63:0]  io_out_bits_debugInfo_tlbFirstReqTime,
  output [63:0]  io_out_bits_debugInfo_tlbRespTime,
  output [55:0]  io_out_bits_debug_seqNum_seqNum,
  output [7:0]   io_out_bits_debug_seqNum_uopIdx,
  input  [2:0]   io_frm,
  output         io_vtype_valid,
  output         io_vtype_bits_illegal,
  output         io_vtype_bits_vma,
  output         io_vtype_bits_vta,
  output [1:0]   io_vtype_bits_vsew,
  output [2:0]   io_vtype_bits_vlmul,
  output         io_vlIsZero,
  output         io_vlIsVlmax,
  input          cg_bore_cgen,
  input          cg_bore_1_cgen,
  input          cg_bore_2_cgen
);

  // ---- 子模块输出线（名字 = golden 的 _<实例>_<端口> 去掉前导下划线）----
  wire in1ToN_io_out_0_valid;
  wire [8:0] in1ToN_io_out_0_bits_fuOpType;
  wire [1:0] in1ToN_io_out_0_bits_vpu_vsew;
  wire [2:0] in1ToN_io_out_0_bits_vpu_vlmul;
  wire in1ToN_io_out_0_bits_vpu_vm;
  wire in1ToN_io_out_0_bits_vpu_fpu_isFoldTo1_2;
  wire in1ToN_io_out_0_bits_vpu_fpu_isFoldTo1_4;
  wire in1ToN_io_out_0_bits_vpu_fpu_isFoldTo1_8;
  wire [6:0] in1ToN_io_out_0_bits_vpu_vuopIdx;
  wire in1ToN_io_out_0_bits_perfDebugInfo_eliminatedMove;
  wire [63:0] in1ToN_io_out_0_bits_perfDebugInfo_renameTime;
  wire [63:0] in1ToN_io_out_0_bits_perfDebugInfo_dispatchTime;
  wire [63:0] in1ToN_io_out_0_bits_perfDebugInfo_enqRsTime;
  wire [63:0] in1ToN_io_out_0_bits_perfDebugInfo_selectTime;
  wire [63:0] in1ToN_io_out_0_bits_perfDebugInfo_issueTime;
  wire [63:0] in1ToN_io_out_0_bits_perfDebugInfo_writebackTime;
  wire [63:0] in1ToN_io_out_0_bits_perfDebugInfo_runahead_checkpoint_id;
  wire [63:0] in1ToN_io_out_0_bits_perfDebugInfo_tlbFirstReqTime;
  wire [63:0] in1ToN_io_out_0_bits_perfDebugInfo_tlbRespTime;
  wire [55:0] in1ToN_io_out_0_bits_debug_seqNum_seqNum;
  wire [7:0] in1ToN_io_out_0_bits_debug_seqNum_uopIdx;
  wire in1ToN_io_out_1_valid;
  wire [8:0] in1ToN_io_out_1_bits_fuOpType;
  wire [1:0] in1ToN_io_out_1_bits_vpu_vsew;
  wire [2:0] in1ToN_io_out_1_bits_vpu_vlmul;
  wire in1ToN_io_out_1_bits_vpu_vm;
  wire [6:0] in1ToN_io_out_1_bits_vpu_vuopIdx;
  wire in1ToN_io_out_1_bits_perfDebugInfo_eliminatedMove;
  wire [63:0] in1ToN_io_out_1_bits_perfDebugInfo_renameTime;
  wire [63:0] in1ToN_io_out_1_bits_perfDebugInfo_dispatchTime;
  wire [63:0] in1ToN_io_out_1_bits_perfDebugInfo_enqRsTime;
  wire [63:0] in1ToN_io_out_1_bits_perfDebugInfo_selectTime;
  wire [63:0] in1ToN_io_out_1_bits_perfDebugInfo_issueTime;
  wire [63:0] in1ToN_io_out_1_bits_perfDebugInfo_writebackTime;
  wire [63:0] in1ToN_io_out_1_bits_perfDebugInfo_runahead_checkpoint_id;
  wire [63:0] in1ToN_io_out_1_bits_perfDebugInfo_tlbFirstReqTime;
  wire [63:0] in1ToN_io_out_1_bits_perfDebugInfo_tlbRespTime;
  wire [55:0] in1ToN_io_out_1_bits_debug_seqNum_seqNum;
  wire [7:0] in1ToN_io_out_1_bits_debug_seqNum_uopIdx;
  wire in1ToN_io_out_2_valid;
  wire [8:0] in1ToN_io_out_2_bits_fuOpType;
  wire in1ToN_io_out_2_bits_vpu_vma;
  wire in1ToN_io_out_2_bits_vpu_vta;
  wire [1:0] in1ToN_io_out_2_bits_vpu_vsew;
  wire [2:0] in1ToN_io_out_2_bits_vpu_vlmul;
  wire in1ToN_io_out_2_bits_vpu_vm;
  wire [7:0] in1ToN_io_out_2_bits_vpu_vstart;
  wire [6:0] in1ToN_io_out_2_bits_vpu_vuopIdx;
  wire in1ToN_io_out_2_bits_perfDebugInfo_eliminatedMove;
  wire [63:0] in1ToN_io_out_2_bits_perfDebugInfo_renameTime;
  wire [63:0] in1ToN_io_out_2_bits_perfDebugInfo_dispatchTime;
  wire [63:0] in1ToN_io_out_2_bits_perfDebugInfo_enqRsTime;
  wire [63:0] in1ToN_io_out_2_bits_perfDebugInfo_selectTime;
  wire [63:0] in1ToN_io_out_2_bits_perfDebugInfo_issueTime;
  wire [63:0] in1ToN_io_out_2_bits_perfDebugInfo_writebackTime;
  wire [63:0] in1ToN_io_out_2_bits_perfDebugInfo_runahead_checkpoint_id;
  wire [63:0] in1ToN_io_out_2_bits_perfDebugInfo_tlbFirstReqTime;
  wire [63:0] in1ToN_io_out_2_bits_perfDebugInfo_tlbRespTime;
  wire [55:0] in1ToN_io_out_2_bits_debug_seqNum_seqNum;
  wire [7:0] in1ToN_io_out_2_bits_debug_seqNum_uopIdx;
  wire in1ToN_io_out_3_valid;
  wire [8:0] in1ToN_io_out_3_bits_fuOpType;
  wire in1ToN_io_out_3_bits_robIdx_flag;
  wire [7:0] in1ToN_io_out_3_bits_robIdx_value;
  wire [7:0] in1ToN_io_out_3_bits_pdest;
  wire in1ToN_io_out_3_bits_rfWen;
  wire in1ToN_io_out_3_bits_vlWen;
  wire in1ToN_io_out_3_bits_perfDebugInfo_eliminatedMove;
  wire [63:0] in1ToN_io_out_3_bits_perfDebugInfo_renameTime;
  wire [63:0] in1ToN_io_out_3_bits_perfDebugInfo_dispatchTime;
  wire [63:0] in1ToN_io_out_3_bits_perfDebugInfo_enqRsTime;
  wire [63:0] in1ToN_io_out_3_bits_perfDebugInfo_selectTime;
  wire [63:0] in1ToN_io_out_3_bits_perfDebugInfo_issueTime;
  wire [63:0] in1ToN_io_out_3_bits_perfDebugInfo_writebackTime;
  wire [63:0] in1ToN_io_out_3_bits_perfDebugInfo_runahead_checkpoint_id;
  wire [63:0] in1ToN_io_out_3_bits_perfDebugInfo_tlbFirstReqTime;
  wire [63:0] in1ToN_io_out_3_bits_perfDebugInfo_tlbRespTime;
  wire [55:0] in1ToN_io_out_3_bits_debug_seqNum_seqNum;
  wire [7:0] in1ToN_io_out_3_bits_debug_seqNum_uopIdx;
  wire ClockGate_2_Q;
  wire ClockGate_1_Q;
  wire ClockGate_Q;
  wire VSetRvfWvf_io_in_ready;
  wire VSetRvfWvf_io_out_valid;
  wire VSetRvfWvf_io_out_bits_ctrl_robIdx_flag;
  wire [7:0] VSetRvfWvf_io_out_bits_ctrl_robIdx_value;
  wire [7:0] VSetRvfWvf_io_out_bits_ctrl_pdest;
  wire VSetRvfWvf_io_out_bits_ctrl_rfWen;
  wire VSetRvfWvf_io_out_bits_ctrl_vlWen;
  wire [63:0] VSetRvfWvf_io_out_bits_res_data;
  wire VSetRvfWvf_io_out_bits_perfDebugInfo_eliminatedMove;
  wire [63:0] VSetRvfWvf_io_out_bits_perfDebugInfo_renameTime;
  wire [63:0] VSetRvfWvf_io_out_bits_perfDebugInfo_dispatchTime;
  wire [63:0] VSetRvfWvf_io_out_bits_perfDebugInfo_enqRsTime;
  wire [63:0] VSetRvfWvf_io_out_bits_perfDebugInfo_selectTime;
  wire [63:0] VSetRvfWvf_io_out_bits_perfDebugInfo_issueTime;
  wire [63:0] VSetRvfWvf_io_out_bits_perfDebugInfo_writebackTime;
  wire [63:0] VSetRvfWvf_io_out_bits_perfDebugInfo_runahead_checkpoint_id;
  wire [63:0] VSetRvfWvf_io_out_bits_perfDebugInfo_tlbFirstReqTime;
  wire [63:0] VSetRvfWvf_io_out_bits_perfDebugInfo_tlbRespTime;
  wire [55:0] VSetRvfWvf_io_out_bits_debug_seqNum_seqNum;
  wire [7:0] VSetRvfWvf_io_out_bits_debug_seqNum_uopIdx;
  wire Vipu_io_in_ready;
  wire Vipu_io_out_valid;
  wire Vipu_io_out_bits_ctrl_robIdx_flag;
  wire [7:0] Vipu_io_out_bits_ctrl_robIdx_value;
  wire [7:0] Vipu_io_out_bits_ctrl_pdest;
  wire Vipu_io_out_bits_ctrl_rfWen;
  wire Vipu_io_out_bits_ctrl_vecWen;
  wire Vipu_io_out_bits_ctrl_v0Wen;
  wire Vipu_io_out_bits_ctrl_exceptionVec_2;
  wire [127:0] Vipu_io_out_bits_res_data;
  wire Vipu_io_out_bits_perfDebugInfo_eliminatedMove;
  wire [63:0] Vipu_io_out_bits_perfDebugInfo_renameTime;
  wire [63:0] Vipu_io_out_bits_perfDebugInfo_dispatchTime;
  wire [63:0] Vipu_io_out_bits_perfDebugInfo_enqRsTime;
  wire [63:0] Vipu_io_out_bits_perfDebugInfo_selectTime;
  wire [63:0] Vipu_io_out_bits_perfDebugInfo_issueTime;
  wire [63:0] Vipu_io_out_bits_perfDebugInfo_writebackTime;
  wire [63:0] Vipu_io_out_bits_perfDebugInfo_runahead_checkpoint_id;
  wire [63:0] Vipu_io_out_bits_perfDebugInfo_tlbFirstReqTime;
  wire [63:0] Vipu_io_out_bits_perfDebugInfo_tlbRespTime;
  wire [55:0] Vipu_io_out_bits_debug_seqNum_seqNum;
  wire [7:0] Vipu_io_out_bits_debug_seqNum_uopIdx;
  wire Vfcvt_io_in_ready;
  wire Vfcvt_io_out_valid;
  wire Vfcvt_io_out_bits_ctrl_robIdx_flag;
  wire [7:0] Vfcvt_io_out_bits_ctrl_robIdx_value;
  wire [7:0] Vfcvt_io_out_bits_ctrl_pdest;
  wire Vfcvt_io_out_bits_ctrl_vecWen;
  wire Vfcvt_io_out_bits_ctrl_v0Wen;
  wire Vfcvt_io_out_bits_ctrl_fpu_wflags;
  wire [127:0] Vfcvt_io_out_bits_res_data;
  wire [4:0] Vfcvt_io_out_bits_res_fflags;
  wire Vfcvt_io_out_bits_perfDebugInfo_eliminatedMove;
  wire [63:0] Vfcvt_io_out_bits_perfDebugInfo_renameTime;
  wire [63:0] Vfcvt_io_out_bits_perfDebugInfo_dispatchTime;
  wire [63:0] Vfcvt_io_out_bits_perfDebugInfo_enqRsTime;
  wire [63:0] Vfcvt_io_out_bits_perfDebugInfo_selectTime;
  wire [63:0] Vfcvt_io_out_bits_perfDebugInfo_issueTime;
  wire [63:0] Vfcvt_io_out_bits_perfDebugInfo_writebackTime;
  wire [63:0] Vfcvt_io_out_bits_perfDebugInfo_runahead_checkpoint_id;
  wire [63:0] Vfcvt_io_out_bits_perfDebugInfo_tlbFirstReqTime;
  wire [63:0] Vfcvt_io_out_bits_perfDebugInfo_tlbRespTime;
  wire [55:0] Vfcvt_io_out_bits_debug_seqNum_seqNum;
  wire [7:0] Vfcvt_io_out_bits_debug_seqNum_uopIdx;
  wire Vfalu_io_in_ready;
  wire Vfalu_io_out_valid;
  wire Vfalu_io_out_bits_ctrl_robIdx_flag;
  wire [7:0] Vfalu_io_out_bits_ctrl_robIdx_value;
  wire [7:0] Vfalu_io_out_bits_ctrl_pdest;
  wire Vfalu_io_out_bits_ctrl_fpWen;
  wire Vfalu_io_out_bits_ctrl_vecWen;
  wire Vfalu_io_out_bits_ctrl_v0Wen;
  wire Vfalu_io_out_bits_ctrl_fpu_wflags;
  wire [127:0] Vfalu_io_out_bits_res_data;
  wire [4:0] Vfalu_io_out_bits_res_fflags;
  wire Vfalu_io_out_bits_perfDebugInfo_eliminatedMove;
  wire [63:0] Vfalu_io_out_bits_perfDebugInfo_renameTime;
  wire [63:0] Vfalu_io_out_bits_perfDebugInfo_dispatchTime;
  wire [63:0] Vfalu_io_out_bits_perfDebugInfo_enqRsTime;
  wire [63:0] Vfalu_io_out_bits_perfDebugInfo_selectTime;
  wire [63:0] Vfalu_io_out_bits_perfDebugInfo_issueTime;
  wire [63:0] Vfalu_io_out_bits_perfDebugInfo_writebackTime;
  wire [63:0] Vfalu_io_out_bits_perfDebugInfo_runahead_checkpoint_id;
  wire [63:0] Vfalu_io_out_bits_perfDebugInfo_tlbFirstReqTime;
  wire [63:0] Vfalu_io_out_bits_perfDebugInfo_tlbRespTime;
  wire [55:0] Vfalu_io_out_bits_debug_seqNum_seqNum;
  wire [7:0] Vfalu_io_out_bits_debug_seqNum_uopIdx;
  wire in1ToN_io_in_ready;

  // ---- 外壳控制核 ----
  localparam int N_FU    = 4;
  localparam int LAT_MAX = 2;
  localparam int PAY_W   = 444;
  wire                     disp_in_valid;
  wire [LAT_MAX:0]         pipe_valid;
  wire [LAT_MAX:0][PAY_W-1:0] pipe_data;
  wire [N_FU-1:0]          fu_clk_en;
  wire [0:0][4:0]        att_q;
  wire                     out_valid;
  xs_ExeUnit_core #(
    .N_FU         (N_FU),
    .FU_LAT       ('{1, 2, 2, 0}),
    .FU_UNCERTAIN ('{0, 0, 0, 0}),
    .HAS_BUSY     (1'b0),
    .LAT_MAX      (LAT_MAX),
    .NF           (24),
    .FIELD_W      ('{9, 9, 128, 128, 128, 8, 1, 1, 1, 1, 1, 1, 1, 2, 3, 1, 8, 1, 1, 1, 7, 1, 1, 1}),
    .FIELD_DEPTH  ('{2, 1, 2, 2, 2, 2, 2, 1, 2, 2, 2, 2, 2, 1, 1, 2, 2, 1, 1, 1, 2, 1, 1, 2}),
    .PAY_W        (PAY_W),
    .N_ATT        (0)
  ) u_core (
    .clock           (clock),
    .reset           (reset),
    .flush_valid     (io_flush_valid),
    .flush_rob_flag  (io_flush_bits_robIdx_flag),
    .flush_rob_value (io_flush_bits_robIdx_value),
    .flush_level     (io_flush_bits_level),
    .in_valid        (io_in_valid),
    .in_ready        (io_in_ready),
    .in_payload      ({io_in_bits_vpu_isDstMask, io_in_bits_vpu_isNarrow, io_in_bits_vpu_lastUop, io_in_bits_vpu_vuopIdx, io_in_bits_vpu_fpu_isFoldTo1_8, io_in_bits_vpu_fpu_isFoldTo1_4, io_in_bits_vpu_fpu_isFoldTo1_2, io_in_bits_vpu_vstart, io_in_bits_vpu_vm, io_in_bits_vpu_vlmul, io_in_bits_vpu_vsew, io_in_bits_vpu_vta, io_in_bits_vpu_vma, io_in_bits_fpu_wflags, io_in_bits_v0Wen, io_in_bits_vecWen, io_in_bits_fpWen, io_in_bits_rfWen, io_in_bits_pdest, io_in_bits_src_4, io_in_bits_src_3, io_in_bits_src_2, io_in_bits_fuOpType, io_in_bits_robIdx_flag, io_in_bits_robIdx_value}),
    .disp_in_valid   (disp_in_valid),
    .disp_in_ready   (in1ToN_io_in_ready),
    .pipe_valid      (pipe_valid),
    .pipe_data       (pipe_data),
    .fu_in_valid     ({in1ToN_io_out_3_valid, in1ToN_io_out_2_valid, in1ToN_io_out_1_valid, in1ToN_io_out_0_valid}),
    .fu_in_ready     ({VSetRvfWvf_io_in_ready, Vipu_io_in_ready, Vfcvt_io_in_ready, Vfalu_io_in_ready}),
    .fu_out_valid    ({VSetRvfWvf_io_out_valid, Vipu_io_out_valid, Vfcvt_io_out_valid, Vfalu_io_out_valid}),
    .out_ready       (io_out_ready),
    .fu_clk_en       (fu_clk_en),
    .att_in          (5'h0),
    .att_q           (att_q),
    .out_valid       (out_valid)
  );

  // ---- inPipe 第 s 级字段拆包（只拆有 FU 读的那些）----
  wire pipe1_fpWen = pipe_data[1][411];
  wire pipe1_fpu_wflags = pipe_data[1][414];
  wire [8:0] pipe1_fuOpType = pipe_data[1][17:9];
  wire [7:0] pipe1_pdest = pipe_data[1][409:402];
  wire pipe1_robIdx_flag = pipe_data[1][8];
  wire [7:0] pipe1_robIdx_value = pipe_data[1][7:0];
  wire [127:0] pipe1_src_2 = pipe_data[1][145:18];
  wire [127:0] pipe1_src_3 = pipe_data[1][273:146];
  wire [127:0] pipe1_src_4 = pipe_data[1][401:274];
  wire pipe1_v0Wen = pipe_data[1][413];
  wire pipe1_vecWen = pipe_data[1][412];
  wire pipe1_vpu_fpu_isFoldTo1_2 = pipe_data[1][431];
  wire pipe1_vpu_fpu_isFoldTo1_4 = pipe_data[1][432];
  wire pipe1_vpu_fpu_isFoldTo1_8 = pipe_data[1][433];
  wire pipe1_vpu_isDstMask = pipe_data[1][443];
  wire pipe1_vpu_isNarrow = pipe_data[1][442];
  wire pipe1_vpu_lastUop = pipe_data[1][441];
  wire [2:0] pipe1_vpu_vlmul = pipe_data[1][421:419];
  wire pipe1_vpu_vm = pipe_data[1][422];
  wire pipe1_vpu_vma = pipe_data[1][415];
  wire [1:0] pipe1_vpu_vsew = pipe_data[1][418:417];
  wire [7:0] pipe1_vpu_vstart = pipe_data[1][430:423];
  wire pipe1_vpu_vta = pipe_data[1][416];
  wire [6:0] pipe1_vpu_vuopIdx = pipe_data[1][440:434];
  wire pipe2_fpu_wflags = pipe_data[2][414];
  wire [7:0] pipe2_pdest = pipe_data[2][409:402];
  wire pipe2_rfWen = pipe_data[2][410];
  wire pipe2_robIdx_flag = pipe_data[2][8];
  wire [7:0] pipe2_robIdx_value = pipe_data[2][7:0];
  wire [127:0] pipe2_src_2 = pipe_data[2][145:18];
  wire [127:0] pipe2_src_3 = pipe_data[2][273:146];
  wire [127:0] pipe2_src_4 = pipe_data[2][401:274];
  wire pipe2_v0Wen = pipe_data[2][413];
  wire pipe2_vecWen = pipe_data[2][412];
  wire pipe2_vpu_isDstMask = pipe_data[2][443];
  wire pipe2_vpu_vm = pipe_data[2][422];
  wire pipe2_vpu_vma = pipe_data[2][415];
  wire [7:0] pipe2_vpu_vstart = pipe_data[2][430:423];
  wire pipe2_vpu_vta = pipe_data[2][416];
  wire [6:0] pipe2_vpu_vuopIdx = pipe_data[2][440:434];

  // ---- Dispatcher：按 fuType 把指令派给一个 FU ----
  Dispatcher_14 in1ToN (
    .clock                                              (clock),
    .reset                                              (reset),
    .io_in_ready                                        (in1ToN_io_in_ready),
    .io_in_valid                                        (disp_in_valid),
    .io_in_bits_fuType                                  (io_in_bits_fuType),
    .io_in_bits_fuOpType                                (io_in_bits_fuOpType),
    .io_in_bits_robIdx_flag                             (io_in_bits_robIdx_flag),
    .io_in_bits_robIdx_value                            (io_in_bits_robIdx_value),
    .io_in_bits_pdest                                   (io_in_bits_pdest),
    .io_in_bits_rfWen                                   (io_in_bits_rfWen),
    .io_in_bits_vlWen                                   (io_in_bits_vlWen),
    .io_in_bits_vpu_vma                                 (io_in_bits_vpu_vma),
    .io_in_bits_vpu_vta                                 (io_in_bits_vpu_vta),
    .io_in_bits_vpu_vsew                                (io_in_bits_vpu_vsew),
    .io_in_bits_vpu_vlmul                               (io_in_bits_vpu_vlmul),
    .io_in_bits_vpu_vm                                  (io_in_bits_vpu_vm),
    .io_in_bits_vpu_vstart                              (io_in_bits_vpu_vstart),
    .io_in_bits_vpu_fpu_isFoldTo1_2                     (io_in_bits_vpu_fpu_isFoldTo1_2),
    .io_in_bits_vpu_fpu_isFoldTo1_4                     (io_in_bits_vpu_fpu_isFoldTo1_4),
    .io_in_bits_vpu_fpu_isFoldTo1_8                     (io_in_bits_vpu_fpu_isFoldTo1_8),
    .io_in_bits_vpu_vuopIdx                             (io_in_bits_vpu_vuopIdx),
    .io_in_bits_perfDebugInfo_eliminatedMove            (io_in_bits_perfDebugInfo_eliminatedMove),
    .io_in_bits_perfDebugInfo_renameTime                (io_in_bits_perfDebugInfo_renameTime),
    .io_in_bits_perfDebugInfo_dispatchTime              (io_in_bits_perfDebugInfo_dispatchTime),
    .io_in_bits_perfDebugInfo_enqRsTime                 (io_in_bits_perfDebugInfo_enqRsTime),
    .io_in_bits_perfDebugInfo_selectTime                (io_in_bits_perfDebugInfo_selectTime),
    .io_in_bits_perfDebugInfo_issueTime                 (io_in_bits_perfDebugInfo_issueTime),
    .io_in_bits_perfDebugInfo_writebackTime             (io_in_bits_perfDebugInfo_writebackTime),
    .io_in_bits_perfDebugInfo_runahead_checkpoint_id    (io_in_bits_perfDebugInfo_runahead_checkpoint_id),
    .io_in_bits_perfDebugInfo_tlbFirstReqTime           (io_in_bits_perfDebugInfo_tlbFirstReqTime),
    .io_in_bits_perfDebugInfo_tlbRespTime               (io_in_bits_perfDebugInfo_tlbRespTime),
    .io_in_bits_debug_seqNum_seqNum                     (io_in_bits_debug_seqNum_seqNum),
    .io_in_bits_debug_seqNum_uopIdx                     (io_in_bits_debug_seqNum_uopIdx),
    .io_out_0_ready                                     (Vfalu_io_in_ready),
    .io_out_0_valid                                     (in1ToN_io_out_0_valid),
    .io_out_0_bits_fuOpType                             (in1ToN_io_out_0_bits_fuOpType),
    .io_out_0_bits_vpu_vsew                             (in1ToN_io_out_0_bits_vpu_vsew),
    .io_out_0_bits_vpu_vlmul                            (in1ToN_io_out_0_bits_vpu_vlmul),
    .io_out_0_bits_vpu_vm                               (in1ToN_io_out_0_bits_vpu_vm),
    .io_out_0_bits_vpu_fpu_isFoldTo1_2                  (in1ToN_io_out_0_bits_vpu_fpu_isFoldTo1_2),
    .io_out_0_bits_vpu_fpu_isFoldTo1_4                  (in1ToN_io_out_0_bits_vpu_fpu_isFoldTo1_4),
    .io_out_0_bits_vpu_fpu_isFoldTo1_8                  (in1ToN_io_out_0_bits_vpu_fpu_isFoldTo1_8),
    .io_out_0_bits_vpu_vuopIdx                          (in1ToN_io_out_0_bits_vpu_vuopIdx),
    .io_out_0_bits_perfDebugInfo_eliminatedMove         (in1ToN_io_out_0_bits_perfDebugInfo_eliminatedMove),
    .io_out_0_bits_perfDebugInfo_renameTime             (in1ToN_io_out_0_bits_perfDebugInfo_renameTime),
    .io_out_0_bits_perfDebugInfo_dispatchTime           (in1ToN_io_out_0_bits_perfDebugInfo_dispatchTime),
    .io_out_0_bits_perfDebugInfo_enqRsTime              (in1ToN_io_out_0_bits_perfDebugInfo_enqRsTime),
    .io_out_0_bits_perfDebugInfo_selectTime             (in1ToN_io_out_0_bits_perfDebugInfo_selectTime),
    .io_out_0_bits_perfDebugInfo_issueTime              (in1ToN_io_out_0_bits_perfDebugInfo_issueTime),
    .io_out_0_bits_perfDebugInfo_writebackTime          (in1ToN_io_out_0_bits_perfDebugInfo_writebackTime),
    .io_out_0_bits_perfDebugInfo_runahead_checkpoint_id (in1ToN_io_out_0_bits_perfDebugInfo_runahead_checkpoint_id),
    .io_out_0_bits_perfDebugInfo_tlbFirstReqTime        (in1ToN_io_out_0_bits_perfDebugInfo_tlbFirstReqTime),
    .io_out_0_bits_perfDebugInfo_tlbRespTime            (in1ToN_io_out_0_bits_perfDebugInfo_tlbRespTime),
    .io_out_0_bits_debug_seqNum_seqNum                  (in1ToN_io_out_0_bits_debug_seqNum_seqNum),
    .io_out_0_bits_debug_seqNum_uopIdx                  (in1ToN_io_out_0_bits_debug_seqNum_uopIdx),
    .io_out_1_ready                                     (Vfcvt_io_in_ready),
    .io_out_1_valid                                     (in1ToN_io_out_1_valid),
    .io_out_1_bits_fuOpType                             (in1ToN_io_out_1_bits_fuOpType),
    .io_out_1_bits_vpu_vsew                             (in1ToN_io_out_1_bits_vpu_vsew),
    .io_out_1_bits_vpu_vlmul                            (in1ToN_io_out_1_bits_vpu_vlmul),
    .io_out_1_bits_vpu_vm                               (in1ToN_io_out_1_bits_vpu_vm),
    .io_out_1_bits_vpu_vuopIdx                          (in1ToN_io_out_1_bits_vpu_vuopIdx),
    .io_out_1_bits_perfDebugInfo_eliminatedMove         (in1ToN_io_out_1_bits_perfDebugInfo_eliminatedMove),
    .io_out_1_bits_perfDebugInfo_renameTime             (in1ToN_io_out_1_bits_perfDebugInfo_renameTime),
    .io_out_1_bits_perfDebugInfo_dispatchTime           (in1ToN_io_out_1_bits_perfDebugInfo_dispatchTime),
    .io_out_1_bits_perfDebugInfo_enqRsTime              (in1ToN_io_out_1_bits_perfDebugInfo_enqRsTime),
    .io_out_1_bits_perfDebugInfo_selectTime             (in1ToN_io_out_1_bits_perfDebugInfo_selectTime),
    .io_out_1_bits_perfDebugInfo_issueTime              (in1ToN_io_out_1_bits_perfDebugInfo_issueTime),
    .io_out_1_bits_perfDebugInfo_writebackTime          (in1ToN_io_out_1_bits_perfDebugInfo_writebackTime),
    .io_out_1_bits_perfDebugInfo_runahead_checkpoint_id (in1ToN_io_out_1_bits_perfDebugInfo_runahead_checkpoint_id),
    .io_out_1_bits_perfDebugInfo_tlbFirstReqTime        (in1ToN_io_out_1_bits_perfDebugInfo_tlbFirstReqTime),
    .io_out_1_bits_perfDebugInfo_tlbRespTime            (in1ToN_io_out_1_bits_perfDebugInfo_tlbRespTime),
    .io_out_1_bits_debug_seqNum_seqNum                  (in1ToN_io_out_1_bits_debug_seqNum_seqNum),
    .io_out_1_bits_debug_seqNum_uopIdx                  (in1ToN_io_out_1_bits_debug_seqNum_uopIdx),
    .io_out_2_ready                                     (Vipu_io_in_ready),
    .io_out_2_valid                                     (in1ToN_io_out_2_valid),
    .io_out_2_bits_fuOpType                             (in1ToN_io_out_2_bits_fuOpType),
    .io_out_2_bits_vpu_vma                              (in1ToN_io_out_2_bits_vpu_vma),
    .io_out_2_bits_vpu_vta                              (in1ToN_io_out_2_bits_vpu_vta),
    .io_out_2_bits_vpu_vsew                             (in1ToN_io_out_2_bits_vpu_vsew),
    .io_out_2_bits_vpu_vlmul                            (in1ToN_io_out_2_bits_vpu_vlmul),
    .io_out_2_bits_vpu_vm                               (in1ToN_io_out_2_bits_vpu_vm),
    .io_out_2_bits_vpu_vstart                           (in1ToN_io_out_2_bits_vpu_vstart),
    .io_out_2_bits_vpu_vuopIdx                          (in1ToN_io_out_2_bits_vpu_vuopIdx),
    .io_out_2_bits_perfDebugInfo_eliminatedMove         (in1ToN_io_out_2_bits_perfDebugInfo_eliminatedMove),
    .io_out_2_bits_perfDebugInfo_renameTime             (in1ToN_io_out_2_bits_perfDebugInfo_renameTime),
    .io_out_2_bits_perfDebugInfo_dispatchTime           (in1ToN_io_out_2_bits_perfDebugInfo_dispatchTime),
    .io_out_2_bits_perfDebugInfo_enqRsTime              (in1ToN_io_out_2_bits_perfDebugInfo_enqRsTime),
    .io_out_2_bits_perfDebugInfo_selectTime             (in1ToN_io_out_2_bits_perfDebugInfo_selectTime),
    .io_out_2_bits_perfDebugInfo_issueTime              (in1ToN_io_out_2_bits_perfDebugInfo_issueTime),
    .io_out_2_bits_perfDebugInfo_writebackTime          (in1ToN_io_out_2_bits_perfDebugInfo_writebackTime),
    .io_out_2_bits_perfDebugInfo_runahead_checkpoint_id (in1ToN_io_out_2_bits_perfDebugInfo_runahead_checkpoint_id),
    .io_out_2_bits_perfDebugInfo_tlbFirstReqTime        (in1ToN_io_out_2_bits_perfDebugInfo_tlbFirstReqTime),
    .io_out_2_bits_perfDebugInfo_tlbRespTime            (in1ToN_io_out_2_bits_perfDebugInfo_tlbRespTime),
    .io_out_2_bits_debug_seqNum_seqNum                  (in1ToN_io_out_2_bits_debug_seqNum_seqNum),
    .io_out_2_bits_debug_seqNum_uopIdx                  (in1ToN_io_out_2_bits_debug_seqNum_uopIdx),
    .io_out_3_ready                                     (VSetRvfWvf_io_in_ready),
    .io_out_3_valid                                     (in1ToN_io_out_3_valid),
    .io_out_3_bits_fuOpType                             (in1ToN_io_out_3_bits_fuOpType),
    .io_out_3_bits_robIdx_flag                          (in1ToN_io_out_3_bits_robIdx_flag),
    .io_out_3_bits_robIdx_value                         (in1ToN_io_out_3_bits_robIdx_value),
    .io_out_3_bits_pdest                                (in1ToN_io_out_3_bits_pdest),
    .io_out_3_bits_rfWen                                (in1ToN_io_out_3_bits_rfWen),
    .io_out_3_bits_vlWen                                (in1ToN_io_out_3_bits_vlWen),
    .io_out_3_bits_perfDebugInfo_eliminatedMove         (in1ToN_io_out_3_bits_perfDebugInfo_eliminatedMove),
    .io_out_3_bits_perfDebugInfo_renameTime             (in1ToN_io_out_3_bits_perfDebugInfo_renameTime),
    .io_out_3_bits_perfDebugInfo_dispatchTime           (in1ToN_io_out_3_bits_perfDebugInfo_dispatchTime),
    .io_out_3_bits_perfDebugInfo_enqRsTime              (in1ToN_io_out_3_bits_perfDebugInfo_enqRsTime),
    .io_out_3_bits_perfDebugInfo_selectTime             (in1ToN_io_out_3_bits_perfDebugInfo_selectTime),
    .io_out_3_bits_perfDebugInfo_issueTime              (in1ToN_io_out_3_bits_perfDebugInfo_issueTime),
    .io_out_3_bits_perfDebugInfo_writebackTime          (in1ToN_io_out_3_bits_perfDebugInfo_writebackTime),
    .io_out_3_bits_perfDebugInfo_runahead_checkpoint_id (in1ToN_io_out_3_bits_perfDebugInfo_runahead_checkpoint_id),
    .io_out_3_bits_perfDebugInfo_tlbFirstReqTime        (in1ToN_io_out_3_bits_perfDebugInfo_tlbFirstReqTime),
    .io_out_3_bits_perfDebugInfo_tlbRespTime            (in1ToN_io_out_3_bits_perfDebugInfo_tlbRespTime),
    .io_out_3_bits_debug_seqNum_seqNum                  (in1ToN_io_out_3_bits_debug_seqNum_seqNum),
    .io_out_3_bits_debug_seqNum_uopIdx                  (in1ToN_io_out_3_bits_debug_seqNum_uopIdx)
  );

  // ---- 功能单元 ----
  VFAlu Vfalu (
    .clock                                            (ClockGate_Q),
    .reset                                            (reset),
    .io_in_ready                                      (Vfalu_io_in_ready),
    .io_in_valid                                      (in1ToN_io_out_0_valid),
    .io_in_bits_ctrl_fuOpType                         (in1ToN_io_out_0_bits_fuOpType),
    .io_in_bits_ctrl_vpu_vsew                         (in1ToN_io_out_0_bits_vpu_vsew),
    .io_in_bits_ctrl_vpu_vlmul                        (in1ToN_io_out_0_bits_vpu_vlmul),
    .io_in_bits_ctrl_vpu_vm                           (in1ToN_io_out_0_bits_vpu_vm),
    .io_in_bits_ctrl_vpu_fpu_isFoldTo1_2              (in1ToN_io_out_0_bits_vpu_fpu_isFoldTo1_2),
    .io_in_bits_ctrl_vpu_fpu_isFoldTo1_4              (in1ToN_io_out_0_bits_vpu_fpu_isFoldTo1_4),
    .io_in_bits_ctrl_vpu_fpu_isFoldTo1_8              (in1ToN_io_out_0_bits_vpu_fpu_isFoldTo1_8),
    .io_in_bits_ctrl_vpu_vuopIdx                      (in1ToN_io_out_0_bits_vpu_vuopIdx),
    .io_in_bits_ctrlPipe_0_fuOpType                   (io_in_bits_fuOpType),
    .io_in_bits_ctrlPipe_0_vpu_vsew                   (io_in_bits_vpu_vsew),
    .io_in_bits_ctrlPipe_0_vpu_vlmul                  (io_in_bits_vpu_vlmul),
    .io_in_bits_ctrlPipe_0_vpu_vuopIdx                (io_in_bits_vpu_vuopIdx),
    .io_in_bits_ctrlPipe_1_fuOpType                   (pipe1_fuOpType),
    .io_in_bits_ctrlPipe_1_robIdx_flag                (pipe1_robIdx_flag),
    .io_in_bits_ctrlPipe_1_robIdx_value               (pipe1_robIdx_value),
    .io_in_bits_ctrlPipe_1_pdest                      (pipe1_pdest),
    .io_in_bits_ctrlPipe_1_fpWen                      (pipe1_fpWen),
    .io_in_bits_ctrlPipe_1_vecWen                     (pipe1_vecWen),
    .io_in_bits_ctrlPipe_1_v0Wen                      (pipe1_v0Wen),
    .io_in_bits_ctrlPipe_1_fpu_wflags                 (pipe1_fpu_wflags),
    .io_in_bits_ctrlPipe_1_vpu_vma                    (pipe1_vpu_vma),
    .io_in_bits_ctrlPipe_1_vpu_vta                    (pipe1_vpu_vta),
    .io_in_bits_ctrlPipe_1_vpu_vsew                   (pipe1_vpu_vsew),
    .io_in_bits_ctrlPipe_1_vpu_vlmul                  (pipe1_vpu_vlmul),
    .io_in_bits_ctrlPipe_1_vpu_vm                     (pipe1_vpu_vm),
    .io_in_bits_ctrlPipe_1_vpu_vstart                 (pipe1_vpu_vstart),
    .io_in_bits_ctrlPipe_1_vpu_fpu_isFoldTo1_2        (pipe1_vpu_fpu_isFoldTo1_2),
    .io_in_bits_ctrlPipe_1_vpu_fpu_isFoldTo1_4        (pipe1_vpu_fpu_isFoldTo1_4),
    .io_in_bits_ctrlPipe_1_vpu_fpu_isFoldTo1_8        (pipe1_vpu_fpu_isFoldTo1_8),
    .io_in_bits_ctrlPipe_1_vpu_vuopIdx                (pipe1_vpu_vuopIdx),
    .io_in_bits_ctrlPipe_1_vpu_lastUop                (pipe1_vpu_lastUop),
    .io_in_bits_ctrlPipe_1_vpu_isNarrow               (pipe1_vpu_isNarrow),
    .io_in_bits_ctrlPipe_1_vpu_isDstMask              (pipe1_vpu_isDstMask),
    .io_in_bits_validPipe_1                           (pipe_valid[1]),
    .io_in_bits_data_src_4                            (io_in_bits_src_4[7:0]),
    .io_in_bits_data_src_3                            (io_in_bits_src_3),
    .io_in_bits_data_src_1                            (io_in_bits_src_1),
    .io_in_bits_data_src_0                            (io_in_bits_src_0),
    .io_in_bits_dataPipe_0_src_4                      (io_in_bits_src_4[7:0]),
    .io_in_bits_dataPipe_1_src_4                      (pipe1_src_4[7:0]),
    .io_in_bits_dataPipe_1_src_3                      (pipe1_src_3),
    .io_in_bits_dataPipe_1_src_2                      (pipe1_src_2),
    .io_in_bits_perfDebugInfo_eliminatedMove          (in1ToN_io_out_0_bits_perfDebugInfo_eliminatedMove),
    .io_in_bits_perfDebugInfo_renameTime              (in1ToN_io_out_0_bits_perfDebugInfo_renameTime),
    .io_in_bits_perfDebugInfo_dispatchTime            (in1ToN_io_out_0_bits_perfDebugInfo_dispatchTime),
    .io_in_bits_perfDebugInfo_enqRsTime               (in1ToN_io_out_0_bits_perfDebugInfo_enqRsTime),
    .io_in_bits_perfDebugInfo_selectTime              (in1ToN_io_out_0_bits_perfDebugInfo_selectTime),
    .io_in_bits_perfDebugInfo_issueTime               (in1ToN_io_out_0_bits_perfDebugInfo_issueTime),
    .io_in_bits_perfDebugInfo_writebackTime           (in1ToN_io_out_0_bits_perfDebugInfo_writebackTime),
    .io_in_bits_perfDebugInfo_runahead_checkpoint_id  (in1ToN_io_out_0_bits_perfDebugInfo_runahead_checkpoint_id),
    .io_in_bits_perfDebugInfo_tlbFirstReqTime         (in1ToN_io_out_0_bits_perfDebugInfo_tlbFirstReqTime),
    .io_in_bits_perfDebugInfo_tlbRespTime             (in1ToN_io_out_0_bits_perfDebugInfo_tlbRespTime),
    .io_in_bits_debug_seqNum_seqNum                   (in1ToN_io_out_0_bits_debug_seqNum_seqNum),
    .io_in_bits_debug_seqNum_uopIdx                   (in1ToN_io_out_0_bits_debug_seqNum_uopIdx),
    .io_out_ready                                     (io_out_ready),
    .io_out_valid                                     (Vfalu_io_out_valid),
    .io_out_bits_ctrl_robIdx_flag                     (Vfalu_io_out_bits_ctrl_robIdx_flag),
    .io_out_bits_ctrl_robIdx_value                    (Vfalu_io_out_bits_ctrl_robIdx_value),
    .io_out_bits_ctrl_pdest                           (Vfalu_io_out_bits_ctrl_pdest),
    .io_out_bits_ctrl_fpWen                           (Vfalu_io_out_bits_ctrl_fpWen),
    .io_out_bits_ctrl_vecWen                          (Vfalu_io_out_bits_ctrl_vecWen),
    .io_out_bits_ctrl_v0Wen                           (Vfalu_io_out_bits_ctrl_v0Wen),
    .io_out_bits_ctrl_fpu_wflags                      (Vfalu_io_out_bits_ctrl_fpu_wflags),
    .io_out_bits_res_data                             (Vfalu_io_out_bits_res_data),
    .io_out_bits_res_fflags                           (Vfalu_io_out_bits_res_fflags),
    .io_out_bits_perfDebugInfo_eliminatedMove         (Vfalu_io_out_bits_perfDebugInfo_eliminatedMove),
    .io_out_bits_perfDebugInfo_renameTime             (Vfalu_io_out_bits_perfDebugInfo_renameTime),
    .io_out_bits_perfDebugInfo_dispatchTime           (Vfalu_io_out_bits_perfDebugInfo_dispatchTime),
    .io_out_bits_perfDebugInfo_enqRsTime              (Vfalu_io_out_bits_perfDebugInfo_enqRsTime),
    .io_out_bits_perfDebugInfo_selectTime             (Vfalu_io_out_bits_perfDebugInfo_selectTime),
    .io_out_bits_perfDebugInfo_issueTime              (Vfalu_io_out_bits_perfDebugInfo_issueTime),
    .io_out_bits_perfDebugInfo_writebackTime          (Vfalu_io_out_bits_perfDebugInfo_writebackTime),
    .io_out_bits_perfDebugInfo_runahead_checkpoint_id (Vfalu_io_out_bits_perfDebugInfo_runahead_checkpoint_id),
    .io_out_bits_perfDebugInfo_tlbFirstReqTime        (Vfalu_io_out_bits_perfDebugInfo_tlbFirstReqTime),
    .io_out_bits_perfDebugInfo_tlbRespTime            (Vfalu_io_out_bits_perfDebugInfo_tlbRespTime),
    .io_out_bits_debug_seqNum_seqNum                  (Vfalu_io_out_bits_debug_seqNum_seqNum),
    .io_out_bits_debug_seqNum_uopIdx                  (Vfalu_io_out_bits_debug_seqNum_uopIdx),
    .io_frm                                           (io_frm)
  );
  VCVT_8 Vfcvt (
    .clock                                            (ClockGate_1_Q),
    .reset                                            (reset),
    .io_in_ready                                      (Vfcvt_io_in_ready),
    .io_in_valid                                      (in1ToN_io_out_1_valid),
    .io_in_bits_ctrl_fuOpType                         (in1ToN_io_out_1_bits_fuOpType),
    .io_in_bits_ctrl_vpu_vsew                         (in1ToN_io_out_1_bits_vpu_vsew),
    .io_in_bits_ctrl_vpu_vlmul                        (in1ToN_io_out_1_bits_vpu_vlmul),
    .io_in_bits_ctrl_vpu_vm                           (in1ToN_io_out_1_bits_vpu_vm),
    .io_in_bits_ctrl_vpu_vuopIdx                      (in1ToN_io_out_1_bits_vpu_vuopIdx),
    .io_in_bits_ctrlPipe_2_robIdx_flag                (pipe2_robIdx_flag),
    .io_in_bits_ctrlPipe_2_robIdx_value               (pipe2_robIdx_value),
    .io_in_bits_ctrlPipe_2_pdest                      (pipe2_pdest),
    .io_in_bits_ctrlPipe_2_vecWen                     (pipe2_vecWen),
    .io_in_bits_ctrlPipe_2_v0Wen                      (pipe2_v0Wen),
    .io_in_bits_ctrlPipe_2_fpu_wflags                 (pipe2_fpu_wflags),
    .io_in_bits_ctrlPipe_2_vpu_vma                    (pipe2_vpu_vma),
    .io_in_bits_ctrlPipe_2_vpu_vta                    (pipe2_vpu_vta),
    .io_in_bits_ctrlPipe_2_vpu_vm                     (pipe2_vpu_vm),
    .io_in_bits_ctrlPipe_2_vpu_vstart                 (pipe2_vpu_vstart),
    .io_in_bits_ctrlPipe_2_vpu_vuopIdx                (pipe2_vpu_vuopIdx),
    .io_in_bits_ctrlPipe_2_vpu_isDstMask              (pipe2_vpu_isDstMask),
    .io_in_bits_validPipe_2                           (pipe_valid[2]),
    .io_in_bits_data_src_4                            (io_in_bits_src_4[7:0]),
    .io_in_bits_data_src_3                            (io_in_bits_src_3),
    .io_in_bits_data_src_1                            (io_in_bits_src_1),
    .io_in_bits_dataPipe_2_src_4                      (pipe2_src_4[7:0]),
    .io_in_bits_dataPipe_2_src_3                      (pipe2_src_3),
    .io_in_bits_dataPipe_2_src_2                      (pipe2_src_2),
    .io_in_bits_perfDebugInfo_eliminatedMove          (in1ToN_io_out_1_bits_perfDebugInfo_eliminatedMove),
    .io_in_bits_perfDebugInfo_renameTime              (in1ToN_io_out_1_bits_perfDebugInfo_renameTime),
    .io_in_bits_perfDebugInfo_dispatchTime            (in1ToN_io_out_1_bits_perfDebugInfo_dispatchTime),
    .io_in_bits_perfDebugInfo_enqRsTime               (in1ToN_io_out_1_bits_perfDebugInfo_enqRsTime),
    .io_in_bits_perfDebugInfo_selectTime              (in1ToN_io_out_1_bits_perfDebugInfo_selectTime),
    .io_in_bits_perfDebugInfo_issueTime               (in1ToN_io_out_1_bits_perfDebugInfo_issueTime),
    .io_in_bits_perfDebugInfo_writebackTime           (in1ToN_io_out_1_bits_perfDebugInfo_writebackTime),
    .io_in_bits_perfDebugInfo_runahead_checkpoint_id  (in1ToN_io_out_1_bits_perfDebugInfo_runahead_checkpoint_id),
    .io_in_bits_perfDebugInfo_tlbFirstReqTime         (in1ToN_io_out_1_bits_perfDebugInfo_tlbFirstReqTime),
    .io_in_bits_perfDebugInfo_tlbRespTime             (in1ToN_io_out_1_bits_perfDebugInfo_tlbRespTime),
    .io_in_bits_debug_seqNum_seqNum                   (in1ToN_io_out_1_bits_debug_seqNum_seqNum),
    .io_in_bits_debug_seqNum_uopIdx                   (in1ToN_io_out_1_bits_debug_seqNum_uopIdx),
    .io_out_ready                                     (io_out_ready),
    .io_out_valid                                     (Vfcvt_io_out_valid),
    .io_out_bits_ctrl_robIdx_flag                     (Vfcvt_io_out_bits_ctrl_robIdx_flag),
    .io_out_bits_ctrl_robIdx_value                    (Vfcvt_io_out_bits_ctrl_robIdx_value),
    .io_out_bits_ctrl_pdest                           (Vfcvt_io_out_bits_ctrl_pdest),
    .io_out_bits_ctrl_vecWen                          (Vfcvt_io_out_bits_ctrl_vecWen),
    .io_out_bits_ctrl_v0Wen                           (Vfcvt_io_out_bits_ctrl_v0Wen),
    .io_out_bits_ctrl_fpu_wflags                      (Vfcvt_io_out_bits_ctrl_fpu_wflags),
    .io_out_bits_res_data                             (Vfcvt_io_out_bits_res_data),
    .io_out_bits_res_fflags                           (Vfcvt_io_out_bits_res_fflags),
    .io_out_bits_perfDebugInfo_eliminatedMove         (Vfcvt_io_out_bits_perfDebugInfo_eliminatedMove),
    .io_out_bits_perfDebugInfo_renameTime             (Vfcvt_io_out_bits_perfDebugInfo_renameTime),
    .io_out_bits_perfDebugInfo_dispatchTime           (Vfcvt_io_out_bits_perfDebugInfo_dispatchTime),
    .io_out_bits_perfDebugInfo_enqRsTime              (Vfcvt_io_out_bits_perfDebugInfo_enqRsTime),
    .io_out_bits_perfDebugInfo_selectTime             (Vfcvt_io_out_bits_perfDebugInfo_selectTime),
    .io_out_bits_perfDebugInfo_issueTime              (Vfcvt_io_out_bits_perfDebugInfo_issueTime),
    .io_out_bits_perfDebugInfo_writebackTime          (Vfcvt_io_out_bits_perfDebugInfo_writebackTime),
    .io_out_bits_perfDebugInfo_runahead_checkpoint_id (Vfcvt_io_out_bits_perfDebugInfo_runahead_checkpoint_id),
    .io_out_bits_perfDebugInfo_tlbFirstReqTime        (Vfcvt_io_out_bits_perfDebugInfo_tlbFirstReqTime),
    .io_out_bits_perfDebugInfo_tlbRespTime            (Vfcvt_io_out_bits_perfDebugInfo_tlbRespTime),
    .io_out_bits_debug_seqNum_seqNum                  (Vfcvt_io_out_bits_debug_seqNum_seqNum),
    .io_out_bits_debug_seqNum_uopIdx                  (Vfcvt_io_out_bits_debug_seqNum_uopIdx),
    .io_frm                                           (io_frm)
  );
  VIPU Vipu (
    .clock                                            (ClockGate_2_Q),
    .reset                                            (reset),
    .io_in_ready                                      (Vipu_io_in_ready),
    .io_in_valid                                      (in1ToN_io_out_2_valid),
    .io_in_bits_ctrl_fuOpType                         (in1ToN_io_out_2_bits_fuOpType),
    .io_in_bits_ctrl_vpu_vma                          (in1ToN_io_out_2_bits_vpu_vma),
    .io_in_bits_ctrl_vpu_vta                          (in1ToN_io_out_2_bits_vpu_vta),
    .io_in_bits_ctrl_vpu_vsew                         (in1ToN_io_out_2_bits_vpu_vsew),
    .io_in_bits_ctrl_vpu_vlmul                        (in1ToN_io_out_2_bits_vpu_vlmul),
    .io_in_bits_ctrl_vpu_vm                           (in1ToN_io_out_2_bits_vpu_vm),
    .io_in_bits_ctrl_vpu_vstart                       (in1ToN_io_out_2_bits_vpu_vstart),
    .io_in_bits_ctrl_vpu_vuopIdx                      (in1ToN_io_out_2_bits_vpu_vuopIdx),
    .io_in_bits_ctrlPipe_2_robIdx_flag                (pipe2_robIdx_flag),
    .io_in_bits_ctrlPipe_2_robIdx_value               (pipe2_robIdx_value),
    .io_in_bits_ctrlPipe_2_pdest                      (pipe2_pdest),
    .io_in_bits_ctrlPipe_2_rfWen                      (pipe2_rfWen),
    .io_in_bits_ctrlPipe_2_vecWen                     (pipe2_vecWen),
    .io_in_bits_ctrlPipe_2_v0Wen                      (pipe2_v0Wen),
    .io_in_bits_ctrlPipe_2_vpu_vstart                 (pipe2_vpu_vstart),
    .io_in_bits_validPipe_2                           (pipe_valid[2]),
    .io_in_bits_data_src_4                            (io_in_bits_src_4[7:0]),
    .io_in_bits_data_src_3                            (io_in_bits_src_3),
    .io_in_bits_data_src_2                            (io_in_bits_src_2),
    .io_in_bits_data_src_1                            (io_in_bits_src_1),
    .io_in_bits_data_src_0                            (io_in_bits_src_0),
    .io_in_bits_perfDebugInfo_eliminatedMove          (in1ToN_io_out_2_bits_perfDebugInfo_eliminatedMove),
    .io_in_bits_perfDebugInfo_renameTime              (in1ToN_io_out_2_bits_perfDebugInfo_renameTime),
    .io_in_bits_perfDebugInfo_dispatchTime            (in1ToN_io_out_2_bits_perfDebugInfo_dispatchTime),
    .io_in_bits_perfDebugInfo_enqRsTime               (in1ToN_io_out_2_bits_perfDebugInfo_enqRsTime),
    .io_in_bits_perfDebugInfo_selectTime              (in1ToN_io_out_2_bits_perfDebugInfo_selectTime),
    .io_in_bits_perfDebugInfo_issueTime               (in1ToN_io_out_2_bits_perfDebugInfo_issueTime),
    .io_in_bits_perfDebugInfo_writebackTime           (in1ToN_io_out_2_bits_perfDebugInfo_writebackTime),
    .io_in_bits_perfDebugInfo_runahead_checkpoint_id  (in1ToN_io_out_2_bits_perfDebugInfo_runahead_checkpoint_id),
    .io_in_bits_perfDebugInfo_tlbFirstReqTime         (in1ToN_io_out_2_bits_perfDebugInfo_tlbFirstReqTime),
    .io_in_bits_perfDebugInfo_tlbRespTime             (in1ToN_io_out_2_bits_perfDebugInfo_tlbRespTime),
    .io_in_bits_debug_seqNum_seqNum                   (in1ToN_io_out_2_bits_debug_seqNum_seqNum),
    .io_in_bits_debug_seqNum_uopIdx                   (in1ToN_io_out_2_bits_debug_seqNum_uopIdx),
    .io_out_ready                                     (io_out_ready),
    .io_out_valid                                     (Vipu_io_out_valid),
    .io_out_bits_ctrl_robIdx_flag                     (Vipu_io_out_bits_ctrl_robIdx_flag),
    .io_out_bits_ctrl_robIdx_value                    (Vipu_io_out_bits_ctrl_robIdx_value),
    .io_out_bits_ctrl_pdest                           (Vipu_io_out_bits_ctrl_pdest),
    .io_out_bits_ctrl_rfWen                           (Vipu_io_out_bits_ctrl_rfWen),
    .io_out_bits_ctrl_vecWen                          (Vipu_io_out_bits_ctrl_vecWen),
    .io_out_bits_ctrl_v0Wen                           (Vipu_io_out_bits_ctrl_v0Wen),
    .io_out_bits_ctrl_exceptionVec_2                  (Vipu_io_out_bits_ctrl_exceptionVec_2),
    .io_out_bits_res_data                             (Vipu_io_out_bits_res_data),
    .io_out_bits_perfDebugInfo_eliminatedMove         (Vipu_io_out_bits_perfDebugInfo_eliminatedMove),
    .io_out_bits_perfDebugInfo_renameTime             (Vipu_io_out_bits_perfDebugInfo_renameTime),
    .io_out_bits_perfDebugInfo_dispatchTime           (Vipu_io_out_bits_perfDebugInfo_dispatchTime),
    .io_out_bits_perfDebugInfo_enqRsTime              (Vipu_io_out_bits_perfDebugInfo_enqRsTime),
    .io_out_bits_perfDebugInfo_selectTime             (Vipu_io_out_bits_perfDebugInfo_selectTime),
    .io_out_bits_perfDebugInfo_issueTime              (Vipu_io_out_bits_perfDebugInfo_issueTime),
    .io_out_bits_perfDebugInfo_writebackTime          (Vipu_io_out_bits_perfDebugInfo_writebackTime),
    .io_out_bits_perfDebugInfo_runahead_checkpoint_id (Vipu_io_out_bits_perfDebugInfo_runahead_checkpoint_id),
    .io_out_bits_perfDebugInfo_tlbFirstReqTime        (Vipu_io_out_bits_perfDebugInfo_tlbFirstReqTime),
    .io_out_bits_perfDebugInfo_tlbRespTime            (Vipu_io_out_bits_perfDebugInfo_tlbRespTime),
    .io_out_bits_debug_seqNum_seqNum                  (Vipu_io_out_bits_debug_seqNum_seqNum),
    .io_out_bits_debug_seqNum_uopIdx                  (Vipu_io_out_bits_debug_seqNum_uopIdx)
  );
  VSetRvfWvf VSetRvfWvf (
    .io_in_ready                                      (VSetRvfWvf_io_in_ready),
    .io_in_valid                                      (in1ToN_io_out_3_valid),
    .io_in_bits_ctrl_fuOpType                         (in1ToN_io_out_3_bits_fuOpType),
    .io_in_bits_ctrl_robIdx_flag                      (in1ToN_io_out_3_bits_robIdx_flag),
    .io_in_bits_ctrl_robIdx_value                     (in1ToN_io_out_3_bits_robIdx_value),
    .io_in_bits_ctrl_pdest                            (in1ToN_io_out_3_bits_pdest),
    .io_in_bits_ctrl_rfWen                            (in1ToN_io_out_3_bits_rfWen),
    .io_in_bits_ctrl_vlWen                            (in1ToN_io_out_3_bits_vlWen),
    .io_in_bits_data_src_4                            (io_in_bits_src_4[7:0]),
    .io_in_bits_data_src_1                            (io_in_bits_src_1),
    .io_in_bits_perfDebugInfo_eliminatedMove          (in1ToN_io_out_3_bits_perfDebugInfo_eliminatedMove),
    .io_in_bits_perfDebugInfo_renameTime              (in1ToN_io_out_3_bits_perfDebugInfo_renameTime),
    .io_in_bits_perfDebugInfo_dispatchTime            (in1ToN_io_out_3_bits_perfDebugInfo_dispatchTime),
    .io_in_bits_perfDebugInfo_enqRsTime               (in1ToN_io_out_3_bits_perfDebugInfo_enqRsTime),
    .io_in_bits_perfDebugInfo_selectTime              (in1ToN_io_out_3_bits_perfDebugInfo_selectTime),
    .io_in_bits_perfDebugInfo_issueTime               (in1ToN_io_out_3_bits_perfDebugInfo_issueTime),
    .io_in_bits_perfDebugInfo_writebackTime           (in1ToN_io_out_3_bits_perfDebugInfo_writebackTime),
    .io_in_bits_perfDebugInfo_runahead_checkpoint_id  (in1ToN_io_out_3_bits_perfDebugInfo_runahead_checkpoint_id),
    .io_in_bits_perfDebugInfo_tlbFirstReqTime         (in1ToN_io_out_3_bits_perfDebugInfo_tlbFirstReqTime),
    .io_in_bits_perfDebugInfo_tlbRespTime             (in1ToN_io_out_3_bits_perfDebugInfo_tlbRespTime),
    .io_in_bits_debug_seqNum_seqNum                   (in1ToN_io_out_3_bits_debug_seqNum_seqNum),
    .io_in_bits_debug_seqNum_uopIdx                   (in1ToN_io_out_3_bits_debug_seqNum_uopIdx),
    .io_out_ready                                     (io_out_ready),
    .io_out_valid                                     (VSetRvfWvf_io_out_valid),
    .io_out_bits_ctrl_robIdx_flag                     (VSetRvfWvf_io_out_bits_ctrl_robIdx_flag),
    .io_out_bits_ctrl_robIdx_value                    (VSetRvfWvf_io_out_bits_ctrl_robIdx_value),
    .io_out_bits_ctrl_pdest                           (VSetRvfWvf_io_out_bits_ctrl_pdest),
    .io_out_bits_ctrl_rfWen                           (VSetRvfWvf_io_out_bits_ctrl_rfWen),
    .io_out_bits_ctrl_vlWen                           (VSetRvfWvf_io_out_bits_ctrl_vlWen),
    .io_out_bits_res_data                             (VSetRvfWvf_io_out_bits_res_data),
    .io_out_bits_perfDebugInfo_eliminatedMove         (VSetRvfWvf_io_out_bits_perfDebugInfo_eliminatedMove),
    .io_out_bits_perfDebugInfo_renameTime             (VSetRvfWvf_io_out_bits_perfDebugInfo_renameTime),
    .io_out_bits_perfDebugInfo_dispatchTime           (VSetRvfWvf_io_out_bits_perfDebugInfo_dispatchTime),
    .io_out_bits_perfDebugInfo_enqRsTime              (VSetRvfWvf_io_out_bits_perfDebugInfo_enqRsTime),
    .io_out_bits_perfDebugInfo_selectTime             (VSetRvfWvf_io_out_bits_perfDebugInfo_selectTime),
    .io_out_bits_perfDebugInfo_issueTime              (VSetRvfWvf_io_out_bits_perfDebugInfo_issueTime),
    .io_out_bits_perfDebugInfo_writebackTime          (VSetRvfWvf_io_out_bits_perfDebugInfo_writebackTime),
    .io_out_bits_perfDebugInfo_runahead_checkpoint_id (VSetRvfWvf_io_out_bits_perfDebugInfo_runahead_checkpoint_id),
    .io_out_bits_perfDebugInfo_tlbFirstReqTime        (VSetRvfWvf_io_out_bits_perfDebugInfo_tlbFirstReqTime),
    .io_out_bits_perfDebugInfo_tlbRespTime            (VSetRvfWvf_io_out_bits_perfDebugInfo_tlbRespTime),
    .io_out_bits_debug_seqNum_seqNum                  (VSetRvfWvf_io_out_bits_debug_seqNum_seqNum),
    .io_out_bits_debug_seqNum_uopIdx                  (VSetRvfWvf_io_out_bits_debug_seqNum_uopIdx),
    .io_vtype_valid                                   (io_vtype_valid),
    .io_vtype_bits_illegal                            (io_vtype_bits_illegal),
    .io_vtype_bits_vma                                (io_vtype_bits_vma),
    .io_vtype_bits_vta                                (io_vtype_bits_vta),
    .io_vtype_bits_vsew                               (io_vtype_bits_vsew),
    .io_vtype_bits_vlmul                              (io_vtype_bits_vlmul),
    .io_vlIsZero                                      (io_vlIsZero),
    .io_vlIsVlmax                                     (io_vlIsVlmax)
  );

  // ---- 时钟门控（E 来自核 §3；TE 来自 DFT 的 cg_bore）----
  ClockGate ClockGate (
    .TE (cg_bore_cgen),
    .E  (fu_clk_en[0]),
    .CK (clock),
    .Q  (ClockGate_Q)
  );
  ClockGate ClockGate_1 (
    .TE (cg_bore_1_cgen),
    .E  (fu_clk_en[1]),
    .CK (clock),
    .Q  (ClockGate_1_Q)
  );
  ClockGate ClockGate_2 (
    .TE (cg_bore_2_cgen),
    .E  (fu_clk_en[2]),
    .CK (clock),
    .Q  (ClockGate_2_Q)
  );

  // ---- 写回：io.out.valid 与各字段的 Mux1H ----
  assign io_out_valid = out_valid;
  assign io_out_bits_data_2 = Vfalu_io_out_bits_res_data;   // 只有 Vfalu 产出：单元素 Mux1H 直通
  assign io_out_bits_data_5 = {64'h0, VSetRvfWvf_io_out_bits_res_data};   // 只有 VSetRvfWvf 产出：单元素 Mux1H 直通
  // 第 0 组：Vfalu, Vfcvt, Vipu, VSetRvfWvf 共同产出 —— data_0, pdest, robIdx_flag, robIdx_value, debugInfo_eliminatedMove, debugInfo_renameTime, debugInfo_dispatchTime, debugInfo_enqRsTime, debugInfo_selectTime, debugInfo_issueTime, debugInfo_writebackTime, debugInfo_runahead_checkpoint_id, debugInfo_tlbFirstReqTime, debugInfo_tlbRespTime, debug_seqNum_seqNum, debug_seqNum_uopIdx
  wire [785:0] wb0_out;
  xs_ExeUnit_wbsel #(.N(4), .W(786)) wb0 (
    .sel  ({VSetRvfWvf_io_out_valid, Vipu_io_out_valid, Vfcvt_io_out_valid, Vfalu_io_out_valid}),
    .data ({
      {{64'h0, VSetRvfWvf_io_out_bits_res_data},
       VSetRvfWvf_io_out_bits_ctrl_pdest,
       VSetRvfWvf_io_out_bits_ctrl_robIdx_flag,
       VSetRvfWvf_io_out_bits_ctrl_robIdx_value,
       VSetRvfWvf_io_out_bits_perfDebugInfo_eliminatedMove,
       VSetRvfWvf_io_out_bits_perfDebugInfo_renameTime,
       VSetRvfWvf_io_out_bits_perfDebugInfo_dispatchTime,
       VSetRvfWvf_io_out_bits_perfDebugInfo_enqRsTime,
       VSetRvfWvf_io_out_bits_perfDebugInfo_selectTime,
       VSetRvfWvf_io_out_bits_perfDebugInfo_issueTime,
       VSetRvfWvf_io_out_bits_perfDebugInfo_writebackTime,
       VSetRvfWvf_io_out_bits_perfDebugInfo_runahead_checkpoint_id,
       VSetRvfWvf_io_out_bits_perfDebugInfo_tlbFirstReqTime,
       VSetRvfWvf_io_out_bits_perfDebugInfo_tlbRespTime,
       VSetRvfWvf_io_out_bits_debug_seqNum_seqNum,
       VSetRvfWvf_io_out_bits_debug_seqNum_uopIdx},
      {Vipu_io_out_bits_res_data,
       Vipu_io_out_bits_ctrl_pdest,
       Vipu_io_out_bits_ctrl_robIdx_flag,
       Vipu_io_out_bits_ctrl_robIdx_value,
       Vipu_io_out_bits_perfDebugInfo_eliminatedMove,
       Vipu_io_out_bits_perfDebugInfo_renameTime,
       Vipu_io_out_bits_perfDebugInfo_dispatchTime,
       Vipu_io_out_bits_perfDebugInfo_enqRsTime,
       Vipu_io_out_bits_perfDebugInfo_selectTime,
       Vipu_io_out_bits_perfDebugInfo_issueTime,
       Vipu_io_out_bits_perfDebugInfo_writebackTime,
       Vipu_io_out_bits_perfDebugInfo_runahead_checkpoint_id,
       Vipu_io_out_bits_perfDebugInfo_tlbFirstReqTime,
       Vipu_io_out_bits_perfDebugInfo_tlbRespTime,
       Vipu_io_out_bits_debug_seqNum_seqNum,
       Vipu_io_out_bits_debug_seqNum_uopIdx},
      {Vfcvt_io_out_bits_res_data,
       Vfcvt_io_out_bits_ctrl_pdest,
       Vfcvt_io_out_bits_ctrl_robIdx_flag,
       Vfcvt_io_out_bits_ctrl_robIdx_value,
       Vfcvt_io_out_bits_perfDebugInfo_eliminatedMove,
       Vfcvt_io_out_bits_perfDebugInfo_renameTime,
       Vfcvt_io_out_bits_perfDebugInfo_dispatchTime,
       Vfcvt_io_out_bits_perfDebugInfo_enqRsTime,
       Vfcvt_io_out_bits_perfDebugInfo_selectTime,
       Vfcvt_io_out_bits_perfDebugInfo_issueTime,
       Vfcvt_io_out_bits_perfDebugInfo_writebackTime,
       Vfcvt_io_out_bits_perfDebugInfo_runahead_checkpoint_id,
       Vfcvt_io_out_bits_perfDebugInfo_tlbFirstReqTime,
       Vfcvt_io_out_bits_perfDebugInfo_tlbRespTime,
       Vfcvt_io_out_bits_debug_seqNum_seqNum,
       Vfcvt_io_out_bits_debug_seqNum_uopIdx},
      {Vfalu_io_out_bits_res_data,
       Vfalu_io_out_bits_ctrl_pdest,
       Vfalu_io_out_bits_ctrl_robIdx_flag,
       Vfalu_io_out_bits_ctrl_robIdx_value,
       Vfalu_io_out_bits_perfDebugInfo_eliminatedMove,
       Vfalu_io_out_bits_perfDebugInfo_renameTime,
       Vfalu_io_out_bits_perfDebugInfo_dispatchTime,
       Vfalu_io_out_bits_perfDebugInfo_enqRsTime,
       Vfalu_io_out_bits_perfDebugInfo_selectTime,
       Vfalu_io_out_bits_perfDebugInfo_issueTime,
       Vfalu_io_out_bits_perfDebugInfo_writebackTime,
       Vfalu_io_out_bits_perfDebugInfo_runahead_checkpoint_id,
       Vfalu_io_out_bits_perfDebugInfo_tlbFirstReqTime,
       Vfalu_io_out_bits_perfDebugInfo_tlbRespTime,
       Vfalu_io_out_bits_debug_seqNum_seqNum,
       Vfalu_io_out_bits_debug_seqNum_uopIdx}
    }),
    .out  (wb0_out)
  );
  assign {
    io_out_bits_data_0,
    io_out_bits_pdest,
    io_out_bits_robIdx_flag,
    io_out_bits_robIdx_value,
    io_out_bits_debugInfo_eliminatedMove,
    io_out_bits_debugInfo_renameTime,
    io_out_bits_debugInfo_dispatchTime,
    io_out_bits_debugInfo_enqRsTime,
    io_out_bits_debugInfo_selectTime,
    io_out_bits_debugInfo_issueTime,
    io_out_bits_debugInfo_writebackTime,
    io_out_bits_debugInfo_runahead_checkpoint_id,
    io_out_bits_debugInfo_tlbFirstReqTime,
    io_out_bits_debugInfo_tlbRespTime,
    io_out_bits_debug_seqNum_seqNum,
    io_out_bits_debug_seqNum_uopIdx
  } = wb0_out;
  // 第 1 组：Vipu, VSetRvfWvf 共同产出 —— data_1, intWen
  wire [128:0] wb1_out;
  xs_ExeUnit_wbsel #(.N(2), .W(129)) wb1 (
    .sel  ({VSetRvfWvf_io_out_valid, Vipu_io_out_valid}),
    .data ({
      {{64'h0, VSetRvfWvf_io_out_bits_res_data},
       VSetRvfWvf_io_out_bits_ctrl_rfWen},
      {Vipu_io_out_bits_res_data,
       Vipu_io_out_bits_ctrl_rfWen}
    }),
    .out  (wb1_out)
  );
  assign {
    io_out_bits_data_1,
    io_out_bits_intWen
  } = wb1_out;
  // 第 2 组：Vfalu, Vfcvt, Vipu 共同产出 —— data_3, data_4, vecWen, v0Wen
  wire [257:0] wb2_out;
  xs_ExeUnit_wbsel #(.N(3), .W(258)) wb2 (
    .sel  ({Vipu_io_out_valid, Vfcvt_io_out_valid, Vfalu_io_out_valid}),
    .data ({
      {Vipu_io_out_bits_res_data,
       Vipu_io_out_bits_res_data,
       Vipu_io_out_bits_ctrl_vecWen,
       Vipu_io_out_bits_ctrl_v0Wen},
      {Vfcvt_io_out_bits_res_data,
       Vfcvt_io_out_bits_res_data,
       Vfcvt_io_out_bits_ctrl_vecWen,
       Vfcvt_io_out_bits_ctrl_v0Wen},
      {Vfalu_io_out_bits_res_data,
       Vfalu_io_out_bits_res_data,
       Vfalu_io_out_bits_ctrl_vecWen,
       Vfalu_io_out_bits_ctrl_v0Wen}
    }),
    .out  (wb2_out)
  );
  assign {
    io_out_bits_data_3,
    io_out_bits_data_4,
    io_out_bits_vecWen,
    io_out_bits_v0Wen
  } = wb2_out;
  // 第 3 组：Vfalu 共同产出 —— fpWen
  wire [0:0] wb3_out;
  xs_ExeUnit_wbsel #(.N(1), .W(1)) wb3 (
    .sel  ({Vfalu_io_out_valid}),
    .data ({
      Vfalu_io_out_bits_ctrl_fpWen
    }),
    .out  (wb3_out)
  );
  assign io_out_bits_fpWen = wb3_out;
  // 第 4 组：VSetRvfWvf 共同产出 —— vlWen
  wire [0:0] wb4_out;
  xs_ExeUnit_wbsel #(.N(1), .W(1)) wb4 (
    .sel  ({VSetRvfWvf_io_out_valid}),
    .data ({
      VSetRvfWvf_io_out_bits_ctrl_vlWen
    }),
    .out  (wb4_out)
  );
  assign io_out_bits_vlWen = wb4_out;
  // 第 5 组：Vfalu, Vfcvt 共同产出 —— fflags, wflags
  wire [5:0] wb5_out;
  xs_ExeUnit_wbsel #(.N(2), .W(6)) wb5 (
    .sel  ({Vfcvt_io_out_valid, Vfalu_io_out_valid}),
    .data ({
      {Vfcvt_io_out_bits_res_fflags,
       Vfcvt_io_out_bits_ctrl_fpu_wflags},
      {Vfalu_io_out_bits_res_fflags,
       Vfalu_io_out_bits_ctrl_fpu_wflags}
    }),
    .out  (wb5_out)
  );
  assign {
    io_out_bits_fflags,
    io_out_bits_wflags
  } = wb5_out;
  // 第 6 组：Vipu 共同产出 —— exceptionVec_2
  wire [0:0] wb6_out;
  xs_ExeUnit_wbsel #(.N(1), .W(1)) wb6 (
    .sel  ({Vipu_io_out_valid}),
    .data ({
      Vipu_io_out_bits_ctrl_exceptionVec_2
    }),
    .out  (wb6_out)
  );
  assign io_out_bits_exceptionVec_2 = wb6_out;

endmodule
