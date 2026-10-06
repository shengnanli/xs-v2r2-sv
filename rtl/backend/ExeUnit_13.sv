// =============================================================================
// ExeUnit_13 —— 执行单元外壳（golden 同名 wrapper；由 scripts/gen_exeunit.py 从 G1 golden 生成，勿手改）
// -----------------------------------------------------------------------------
// FU（按 Dispatcher 出口序）：Vfma(VFMA, 延迟 3, 门控), VialuFix(VIAluFix, 延迟 1, 门控), Vimac(VIMacU, 延迟 2, 门控), Vppu(VPPU, 延迟 2, 门控)
// inPipe：3 级；字段 robIdx[9]×3级, fuOpType[9]×3级, src_2[128]×3级, src_3[128]×3级, src_4[128]×3级, pdest[7]×3级, vecWen[1]×3级, v0Wen[1]×3级, fpu_wflags[1]×3级, vpu_vma[1]×3级, vpu_vta[1]×3级, vpu_vsew[2]×3级, vpu_vlmul[3]×3级, vpu_vm[1]×3级, vpu_vstart[8]×3级, vpu_vuopIdx[7]×3级, vpu_isExt[1]×1级, vpu_isNarrow[1]×3级, vpu_isDstMask[1]×3级, vpu_isOpMask[1]×1级
// 机制全部在 xs_ExeUnit_core（发射握手 / inPipe 冲刷流水 / 时钟门控使能 / 写回有效）与
//   xs_ExeUnit_wbsel（写回字段 Mux1H）里；本文件只有例化、连线与字段打包。
// 子模块：Dispatcher 与各 FU、ClockGate 均为已签核件（两侧白盒，实例名与 golden 相同）。
// golden 对照：G1-canonical/golden-rtl/ExeUnit_13.sv
// 本文件导航（一个 golden 模块一个文件，不拆；行号由生成器回填）：
//   L98    子模块输出线（名字 = golden 的 _<实例>_<端口> 去掉前导下划线）
//   L264   外壳控制核
//   L309   inPipe 第 s 级字段拆包（只拆有 FU 读的那些）
//   L364   Dispatcher：按 fuType 把指令派给一个 FU
//   L474   功能单元
//   L737   时钟门控（E 来自核 §3；TE 来自 DFT 的 cg_bore）
//   L763   写回：io.out.valid 与各字段的 Mux1H
// =============================================================================
module ExeUnit_13(
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
  input  [6:0]   io_in_bits_pdest,
  input          io_in_bits_vecWen,
  input          io_in_bits_v0Wen,
  input          io_in_bits_fpu_wflags,
  input          io_in_bits_vpu_vma,
  input          io_in_bits_vpu_vta,
  input  [1:0]   io_in_bits_vpu_vsew,
  input  [2:0]   io_in_bits_vpu_vlmul,
  input          io_in_bits_vpu_vm,
  input  [7:0]   io_in_bits_vpu_vstart,
  input  [6:0]   io_in_bits_vpu_vuopIdx,
  input          io_in_bits_vpu_isExt,
  input          io_in_bits_vpu_isNarrow,
  input          io_in_bits_vpu_isDstMask,
  input          io_in_bits_vpu_isOpMask,
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
  output [6:0]   io_out_bits_pdest,
  output         io_out_bits_robIdx_flag,
  output [7:0]   io_out_bits_robIdx_value,
  output         io_out_bits_vecWen,
  output         io_out_bits_v0Wen,
  output [4:0]   io_out_bits_fflags,
  output         io_out_bits_wflags,
  output         io_out_bits_vxsat,
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
  input  [1:0]   io_vxrm,
  input          cg_bore_cgen,
  input          cg_bore_1_cgen,
  input          cg_bore_2_cgen,
  input          cg_bore_3_cgen
);

  // ---- 子模块输出线（名字 = golden 的 _<实例>_<端口> 去掉前导下划线）----
  wire in1ToN_io_out_0_valid;
  wire [8:0] in1ToN_io_out_0_bits_fuOpType;
  wire [1:0] in1ToN_io_out_0_bits_vpu_vsew;
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
  wire in1ToN_io_out_1_bits_vpu_vma;
  wire [1:0] in1ToN_io_out_1_bits_vpu_vsew;
  wire in1ToN_io_out_1_bits_vpu_vm;
  wire [6:0] in1ToN_io_out_1_bits_vpu_vuopIdx;
  wire in1ToN_io_out_1_bits_vpu_isExt;
  wire in1ToN_io_out_1_bits_vpu_isNarrow;
  wire in1ToN_io_out_1_bits_vpu_isDstMask;
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
  wire [1:0] in1ToN_io_out_2_bits_vpu_vsew;
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
  wire in1ToN_io_out_3_bits_vpu_vma;
  wire in1ToN_io_out_3_bits_vpu_vta;
  wire [1:0] in1ToN_io_out_3_bits_vpu_vsew;
  wire [2:0] in1ToN_io_out_3_bits_vpu_vlmul;
  wire in1ToN_io_out_3_bits_vpu_vm;
  wire [7:0] in1ToN_io_out_3_bits_vpu_vstart;
  wire [6:0] in1ToN_io_out_3_bits_vpu_vuopIdx;
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
  wire ClockGate_3_Q;
  wire ClockGate_2_Q;
  wire ClockGate_1_Q;
  wire ClockGate_Q;
  wire Vppu_io_in_ready;
  wire Vppu_io_out_valid;
  wire Vppu_io_out_bits_ctrl_robIdx_flag;
  wire [7:0] Vppu_io_out_bits_ctrl_robIdx_value;
  wire [7:0] Vppu_io_out_bits_ctrl_pdest;
  wire Vppu_io_out_bits_ctrl_vecWen;
  wire Vppu_io_out_bits_ctrl_v0Wen;
  wire Vppu_io_out_bits_ctrl_exceptionVec_2;
  wire [127:0] Vppu_io_out_bits_res_data;
  wire Vppu_io_out_bits_perfDebugInfo_eliminatedMove;
  wire [63:0] Vppu_io_out_bits_perfDebugInfo_renameTime;
  wire [63:0] Vppu_io_out_bits_perfDebugInfo_dispatchTime;
  wire [63:0] Vppu_io_out_bits_perfDebugInfo_enqRsTime;
  wire [63:0] Vppu_io_out_bits_perfDebugInfo_selectTime;
  wire [63:0] Vppu_io_out_bits_perfDebugInfo_issueTime;
  wire [63:0] Vppu_io_out_bits_perfDebugInfo_writebackTime;
  wire [63:0] Vppu_io_out_bits_perfDebugInfo_runahead_checkpoint_id;
  wire [63:0] Vppu_io_out_bits_perfDebugInfo_tlbFirstReqTime;
  wire [63:0] Vppu_io_out_bits_perfDebugInfo_tlbRespTime;
  wire [55:0] Vppu_io_out_bits_debug_seqNum_seqNum;
  wire [7:0] Vppu_io_out_bits_debug_seqNum_uopIdx;
  wire Vimac_io_in_ready;
  wire Vimac_io_out_valid;
  wire Vimac_io_out_bits_ctrl_robIdx_flag;
  wire [7:0] Vimac_io_out_bits_ctrl_robIdx_value;
  wire [7:0] Vimac_io_out_bits_ctrl_pdest;
  wire Vimac_io_out_bits_ctrl_vecWen;
  wire Vimac_io_out_bits_ctrl_v0Wen;
  wire [127:0] Vimac_io_out_bits_res_data;
  wire Vimac_io_out_bits_res_vxsat;
  wire Vimac_io_out_bits_perfDebugInfo_eliminatedMove;
  wire [63:0] Vimac_io_out_bits_perfDebugInfo_renameTime;
  wire [63:0] Vimac_io_out_bits_perfDebugInfo_dispatchTime;
  wire [63:0] Vimac_io_out_bits_perfDebugInfo_enqRsTime;
  wire [63:0] Vimac_io_out_bits_perfDebugInfo_selectTime;
  wire [63:0] Vimac_io_out_bits_perfDebugInfo_issueTime;
  wire [63:0] Vimac_io_out_bits_perfDebugInfo_writebackTime;
  wire [63:0] Vimac_io_out_bits_perfDebugInfo_runahead_checkpoint_id;
  wire [63:0] Vimac_io_out_bits_perfDebugInfo_tlbFirstReqTime;
  wire [63:0] Vimac_io_out_bits_perfDebugInfo_tlbRespTime;
  wire [55:0] Vimac_io_out_bits_debug_seqNum_seqNum;
  wire [7:0] Vimac_io_out_bits_debug_seqNum_uopIdx;
  wire VialuFix_io_in_ready;
  wire VialuFix_io_out_valid;
  wire VialuFix_io_out_bits_ctrl_robIdx_flag;
  wire [7:0] VialuFix_io_out_bits_ctrl_robIdx_value;
  wire [7:0] VialuFix_io_out_bits_ctrl_pdest;
  wire VialuFix_io_out_bits_ctrl_vecWen;
  wire VialuFix_io_out_bits_ctrl_v0Wen;
  wire [127:0] VialuFix_io_out_bits_res_data;
  wire VialuFix_io_out_bits_res_vxsat;
  wire VialuFix_io_out_bits_perfDebugInfo_eliminatedMove;
  wire [63:0] VialuFix_io_out_bits_perfDebugInfo_renameTime;
  wire [63:0] VialuFix_io_out_bits_perfDebugInfo_dispatchTime;
  wire [63:0] VialuFix_io_out_bits_perfDebugInfo_enqRsTime;
  wire [63:0] VialuFix_io_out_bits_perfDebugInfo_selectTime;
  wire [63:0] VialuFix_io_out_bits_perfDebugInfo_issueTime;
  wire [63:0] VialuFix_io_out_bits_perfDebugInfo_writebackTime;
  wire [63:0] VialuFix_io_out_bits_perfDebugInfo_runahead_checkpoint_id;
  wire [63:0] VialuFix_io_out_bits_perfDebugInfo_tlbFirstReqTime;
  wire [63:0] VialuFix_io_out_bits_perfDebugInfo_tlbRespTime;
  wire [55:0] VialuFix_io_out_bits_debug_seqNum_seqNum;
  wire [7:0] VialuFix_io_out_bits_debug_seqNum_uopIdx;
  wire Vfma_io_in_ready;
  wire Vfma_io_out_valid;
  wire Vfma_io_out_bits_ctrl_robIdx_flag;
  wire [7:0] Vfma_io_out_bits_ctrl_robIdx_value;
  wire [7:0] Vfma_io_out_bits_ctrl_pdest;
  wire Vfma_io_out_bits_ctrl_vecWen;
  wire Vfma_io_out_bits_ctrl_v0Wen;
  wire Vfma_io_out_bits_ctrl_fpu_wflags;
  wire [127:0] Vfma_io_out_bits_res_data;
  wire [4:0] Vfma_io_out_bits_res_fflags;
  wire Vfma_io_out_bits_perfDebugInfo_eliminatedMove;
  wire [63:0] Vfma_io_out_bits_perfDebugInfo_renameTime;
  wire [63:0] Vfma_io_out_bits_perfDebugInfo_dispatchTime;
  wire [63:0] Vfma_io_out_bits_perfDebugInfo_enqRsTime;
  wire [63:0] Vfma_io_out_bits_perfDebugInfo_selectTime;
  wire [63:0] Vfma_io_out_bits_perfDebugInfo_issueTime;
  wire [63:0] Vfma_io_out_bits_perfDebugInfo_writebackTime;
  wire [63:0] Vfma_io_out_bits_perfDebugInfo_runahead_checkpoint_id;
  wire [63:0] Vfma_io_out_bits_perfDebugInfo_tlbFirstReqTime;
  wire [63:0] Vfma_io_out_bits_perfDebugInfo_tlbRespTime;
  wire [55:0] Vfma_io_out_bits_debug_seqNum_seqNum;
  wire [7:0] Vfma_io_out_bits_debug_seqNum_uopIdx;
  wire in1ToN_io_in_ready;

  // ---- 外壳控制核 ----
  localparam int N_FU    = 4;
  localparam int LAT_MAX = 3;
  localparam int PAY_W   = 439;
  wire                     disp_in_valid;
  wire [LAT_MAX:0]         pipe_valid;
  wire [LAT_MAX:0][PAY_W-1:0] pipe_data;
  wire [N_FU-1:0]          fu_clk_en;
  wire [0:0][4:0]        att_q;
  wire                     out_valid;
  xs_ExeUnit_core #(
    .N_FU         (N_FU),
    .FU_LAT       ('{3, 1, 2, 2}),
    .FU_UNCERTAIN ('{0, 0, 0, 0}),
    .HAS_BUSY     (1'b0),
    .LAT_MAX      (LAT_MAX),
    .NF           (20),
    .FIELD_W      ('{9, 9, 128, 128, 128, 7, 1, 1, 1, 1, 1, 2, 3, 1, 8, 7, 1, 1, 1, 1}),
    .FIELD_DEPTH  ('{3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 1, 3, 3, 1}),
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
    .in_payload      ({io_in_bits_vpu_isOpMask, io_in_bits_vpu_isDstMask, io_in_bits_vpu_isNarrow, io_in_bits_vpu_isExt, io_in_bits_vpu_vuopIdx, io_in_bits_vpu_vstart, io_in_bits_vpu_vm, io_in_bits_vpu_vlmul, io_in_bits_vpu_vsew, io_in_bits_vpu_vta, io_in_bits_vpu_vma, io_in_bits_fpu_wflags, io_in_bits_v0Wen, io_in_bits_vecWen, io_in_bits_pdest, io_in_bits_src_4, io_in_bits_src_3, io_in_bits_src_2, io_in_bits_fuOpType, io_in_bits_robIdx_flag, io_in_bits_robIdx_value}),
    .disp_in_valid   (disp_in_valid),
    .disp_in_ready   (in1ToN_io_in_ready),
    .pipe_valid      (pipe_valid),
    .pipe_data       (pipe_data),
    .fu_in_valid     ({in1ToN_io_out_3_valid, in1ToN_io_out_2_valid, in1ToN_io_out_1_valid, in1ToN_io_out_0_valid}),
    .fu_in_ready     ({Vppu_io_in_ready, Vimac_io_in_ready, VialuFix_io_in_ready, Vfma_io_in_ready}),
    .fu_out_valid    ({Vppu_io_out_valid, Vimac_io_out_valid, VialuFix_io_out_valid, Vfma_io_out_valid}),
    .out_ready       (io_out_ready),
    .fu_clk_en       (fu_clk_en),
    .att_in          (5'h0),
    .att_q           (att_q),
    .out_valid       (out_valid)
  );

  // ---- inPipe 第 s 级字段拆包（只拆有 FU 读的那些）----
  wire [8:0] pipe1_fuOpType = pipe_data[1][17:9];
  wire [6:0] pipe1_pdest = pipe_data[1][408:402];
  wire pipe1_robIdx_flag = pipe_data[1][8];
  wire [7:0] pipe1_robIdx_value = pipe_data[1][7:0];
  wire [127:0] pipe1_src_2 = pipe_data[1][145:18];
  wire [127:0] pipe1_src_3 = pipe_data[1][273:146];
  wire [127:0] pipe1_src_4 = pipe_data[1][401:274];
  wire pipe1_v0Wen = pipe_data[1][410];
  wire pipe1_vecWen = pipe_data[1][409];
  wire pipe1_vpu_isDstMask = pipe_data[1][437];
  wire pipe1_vpu_isExt = pipe_data[1][435];
  wire pipe1_vpu_isNarrow = pipe_data[1][436];
  wire pipe1_vpu_isOpMask = pipe_data[1][438];
  wire pipe1_vpu_vm = pipe_data[1][419];
  wire pipe1_vpu_vma = pipe_data[1][412];
  wire [1:0] pipe1_vpu_vsew = pipe_data[1][415:414];
  wire [7:0] pipe1_vpu_vstart = pipe_data[1][427:420];
  wire pipe1_vpu_vta = pipe_data[1][413];
  wire [6:0] pipe1_vpu_vuopIdx = pipe_data[1][434:428];
  wire [8:0] pipe2_fuOpType = pipe_data[2][17:9];
  wire [6:0] pipe2_pdest = pipe_data[2][408:402];
  wire pipe2_robIdx_flag = pipe_data[2][8];
  wire [7:0] pipe2_robIdx_value = pipe_data[2][7:0];
  wire [127:0] pipe2_src_2 = pipe_data[2][145:18];
  wire [127:0] pipe2_src_3 = pipe_data[2][273:146];
  wire [127:0] pipe2_src_4 = pipe_data[2][401:274];
  wire pipe2_v0Wen = pipe_data[2][410];
  wire pipe2_vecWen = pipe_data[2][409];
  wire pipe2_vpu_vm = pipe_data[2][419];
  wire pipe2_vpu_vma = pipe_data[2][412];
  wire [1:0] pipe2_vpu_vsew = pipe_data[2][415:414];
  wire [7:0] pipe2_vpu_vstart = pipe_data[2][427:420];
  wire pipe2_vpu_vta = pipe_data[2][413];
  wire [6:0] pipe2_vpu_vuopIdx = pipe_data[2][434:428];
  wire pipe3_fpu_wflags = pipe_data[3][411];
  wire [8:0] pipe3_fuOpType = pipe_data[3][17:9];
  wire [6:0] pipe3_pdest = pipe_data[3][408:402];
  wire pipe3_robIdx_flag = pipe_data[3][8];
  wire [7:0] pipe3_robIdx_value = pipe_data[3][7:0];
  wire [127:0] pipe3_src_2 = pipe_data[3][145:18];
  wire [127:0] pipe3_src_3 = pipe_data[3][273:146];
  wire [127:0] pipe3_src_4 = pipe_data[3][401:274];
  wire pipe3_v0Wen = pipe_data[3][410];
  wire pipe3_vecWen = pipe_data[3][409];
  wire pipe3_vpu_isDstMask = pipe_data[3][437];
  wire pipe3_vpu_isNarrow = pipe_data[3][436];
  wire [2:0] pipe3_vpu_vlmul = pipe_data[3][418:416];
  wire pipe3_vpu_vm = pipe_data[3][419];
  wire pipe3_vpu_vma = pipe_data[3][412];
  wire [1:0] pipe3_vpu_vsew = pipe_data[3][415:414];
  wire [7:0] pipe3_vpu_vstart = pipe_data[3][427:420];
  wire pipe3_vpu_vta = pipe_data[3][413];
  wire [6:0] pipe3_vpu_vuopIdx = pipe_data[3][434:428];

  // ---- Dispatcher：按 fuType 把指令派给一个 FU ----
  Dispatcher_13 in1ToN (
    .clock                                              (clock),
    .reset                                              (reset),
    .io_in_ready                                        (in1ToN_io_in_ready),
    .io_in_valid                                        (disp_in_valid),
    .io_in_bits_fuType                                  (io_in_bits_fuType),
    .io_in_bits_fuOpType                                (io_in_bits_fuOpType),
    .io_in_bits_vpu_vma                                 (io_in_bits_vpu_vma),
    .io_in_bits_vpu_vta                                 (io_in_bits_vpu_vta),
    .io_in_bits_vpu_vsew                                (io_in_bits_vpu_vsew),
    .io_in_bits_vpu_vlmul                               (io_in_bits_vpu_vlmul),
    .io_in_bits_vpu_vm                                  (io_in_bits_vpu_vm),
    .io_in_bits_vpu_vstart                              (io_in_bits_vpu_vstart),
    .io_in_bits_vpu_vuopIdx                             (io_in_bits_vpu_vuopIdx),
    .io_in_bits_vpu_isExt                               (io_in_bits_vpu_isExt),
    .io_in_bits_vpu_isNarrow                            (io_in_bits_vpu_isNarrow),
    .io_in_bits_vpu_isDstMask                           (io_in_bits_vpu_isDstMask),
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
    .io_out_0_ready                                     (Vfma_io_in_ready),
    .io_out_0_valid                                     (in1ToN_io_out_0_valid),
    .io_out_0_bits_fuOpType                             (in1ToN_io_out_0_bits_fuOpType),
    .io_out_0_bits_vpu_vsew                             (in1ToN_io_out_0_bits_vpu_vsew),
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
    .io_out_1_ready                                     (VialuFix_io_in_ready),
    .io_out_1_valid                                     (in1ToN_io_out_1_valid),
    .io_out_1_bits_fuOpType                             (in1ToN_io_out_1_bits_fuOpType),
    .io_out_1_bits_vpu_vma                              (in1ToN_io_out_1_bits_vpu_vma),
    .io_out_1_bits_vpu_vsew                             (in1ToN_io_out_1_bits_vpu_vsew),
    .io_out_1_bits_vpu_vm                               (in1ToN_io_out_1_bits_vpu_vm),
    .io_out_1_bits_vpu_vuopIdx                          (in1ToN_io_out_1_bits_vpu_vuopIdx),
    .io_out_1_bits_vpu_isExt                            (in1ToN_io_out_1_bits_vpu_isExt),
    .io_out_1_bits_vpu_isNarrow                         (in1ToN_io_out_1_bits_vpu_isNarrow),
    .io_out_1_bits_vpu_isDstMask                        (in1ToN_io_out_1_bits_vpu_isDstMask),
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
    .io_out_2_ready                                     (Vimac_io_in_ready),
    .io_out_2_valid                                     (in1ToN_io_out_2_valid),
    .io_out_2_bits_fuOpType                             (in1ToN_io_out_2_bits_fuOpType),
    .io_out_2_bits_vpu_vsew                             (in1ToN_io_out_2_bits_vpu_vsew),
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
    .io_out_3_ready                                     (Vppu_io_in_ready),
    .io_out_3_valid                                     (in1ToN_io_out_3_valid),
    .io_out_3_bits_fuOpType                             (in1ToN_io_out_3_bits_fuOpType),
    .io_out_3_bits_vpu_vma                              (in1ToN_io_out_3_bits_vpu_vma),
    .io_out_3_bits_vpu_vta                              (in1ToN_io_out_3_bits_vpu_vta),
    .io_out_3_bits_vpu_vsew                             (in1ToN_io_out_3_bits_vpu_vsew),
    .io_out_3_bits_vpu_vlmul                            (in1ToN_io_out_3_bits_vpu_vlmul),
    .io_out_3_bits_vpu_vm                               (in1ToN_io_out_3_bits_vpu_vm),
    .io_out_3_bits_vpu_vstart                           (in1ToN_io_out_3_bits_vpu_vstart),
    .io_out_3_bits_vpu_vuopIdx                          (in1ToN_io_out_3_bits_vpu_vuopIdx),
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
  VFMA Vfma (
    .clock                                            (ClockGate_Q),
    .reset                                            (reset),
    .io_in_ready                                      (Vfma_io_in_ready),
    .io_in_valid                                      (in1ToN_io_out_0_valid),
    .io_in_bits_ctrl_fuOpType                         (in1ToN_io_out_0_bits_fuOpType),
    .io_in_bits_ctrl_vpu_vsew                         (in1ToN_io_out_0_bits_vpu_vsew),
    .io_in_bits_ctrl_vpu_vuopIdx                      (in1ToN_io_out_0_bits_vpu_vuopIdx),
    .io_in_bits_ctrlPipe_3_fuOpType                   (pipe3_fuOpType),
    .io_in_bits_ctrlPipe_3_robIdx_flag                (pipe3_robIdx_flag),
    .io_in_bits_ctrlPipe_3_robIdx_value               (pipe3_robIdx_value),
    .io_in_bits_ctrlPipe_3_pdest                      ({1'h0, pipe3_pdest}),
    .io_in_bits_ctrlPipe_3_vecWen                     (pipe3_vecWen),
    .io_in_bits_ctrlPipe_3_v0Wen                      (pipe3_v0Wen),
    .io_in_bits_ctrlPipe_3_fpu_wflags                 (pipe3_fpu_wflags),
    .io_in_bits_ctrlPipe_3_vpu_vma                    (pipe3_vpu_vma),
    .io_in_bits_ctrlPipe_3_vpu_vta                    (pipe3_vpu_vta),
    .io_in_bits_ctrlPipe_3_vpu_vsew                   (pipe3_vpu_vsew),
    .io_in_bits_ctrlPipe_3_vpu_vlmul                  (pipe3_vpu_vlmul),
    .io_in_bits_ctrlPipe_3_vpu_vm                     (pipe3_vpu_vm),
    .io_in_bits_ctrlPipe_3_vpu_vstart                 (pipe3_vpu_vstart),
    .io_in_bits_ctrlPipe_3_vpu_vuopIdx                (pipe3_vpu_vuopIdx),
    .io_in_bits_ctrlPipe_3_vpu_isNarrow               (pipe3_vpu_isNarrow),
    .io_in_bits_ctrlPipe_3_vpu_isDstMask              (pipe3_vpu_isDstMask),
    .io_in_bits_validPipe_3                           (pipe_valid[3]),
    .io_in_bits_data_src_2                            (io_in_bits_src_2),
    .io_in_bits_data_src_1                            (io_in_bits_src_1),
    .io_in_bits_data_src_0                            (io_in_bits_src_0),
    .io_in_bits_dataPipe_3_src_4                      (pipe3_src_4[7:0]),
    .io_in_bits_dataPipe_3_src_3                      (pipe3_src_3),
    .io_in_bits_dataPipe_3_src_2                      (pipe3_src_2),
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
    .io_out_valid                                     (Vfma_io_out_valid),
    .io_out_bits_ctrl_robIdx_flag                     (Vfma_io_out_bits_ctrl_robIdx_flag),
    .io_out_bits_ctrl_robIdx_value                    (Vfma_io_out_bits_ctrl_robIdx_value),
    .io_out_bits_ctrl_pdest                           (Vfma_io_out_bits_ctrl_pdest),
    .io_out_bits_ctrl_vecWen                          (Vfma_io_out_bits_ctrl_vecWen),
    .io_out_bits_ctrl_v0Wen                           (Vfma_io_out_bits_ctrl_v0Wen),
    .io_out_bits_ctrl_fpu_wflags                      (Vfma_io_out_bits_ctrl_fpu_wflags),
    .io_out_bits_res_data                             (Vfma_io_out_bits_res_data),
    .io_out_bits_res_fflags                           (Vfma_io_out_bits_res_fflags),
    .io_out_bits_perfDebugInfo_eliminatedMove         (Vfma_io_out_bits_perfDebugInfo_eliminatedMove),
    .io_out_bits_perfDebugInfo_renameTime             (Vfma_io_out_bits_perfDebugInfo_renameTime),
    .io_out_bits_perfDebugInfo_dispatchTime           (Vfma_io_out_bits_perfDebugInfo_dispatchTime),
    .io_out_bits_perfDebugInfo_enqRsTime              (Vfma_io_out_bits_perfDebugInfo_enqRsTime),
    .io_out_bits_perfDebugInfo_selectTime             (Vfma_io_out_bits_perfDebugInfo_selectTime),
    .io_out_bits_perfDebugInfo_issueTime              (Vfma_io_out_bits_perfDebugInfo_issueTime),
    .io_out_bits_perfDebugInfo_writebackTime          (Vfma_io_out_bits_perfDebugInfo_writebackTime),
    .io_out_bits_perfDebugInfo_runahead_checkpoint_id (Vfma_io_out_bits_perfDebugInfo_runahead_checkpoint_id),
    .io_out_bits_perfDebugInfo_tlbFirstReqTime        (Vfma_io_out_bits_perfDebugInfo_tlbFirstReqTime),
    .io_out_bits_perfDebugInfo_tlbRespTime            (Vfma_io_out_bits_perfDebugInfo_tlbRespTime),
    .io_out_bits_debug_seqNum_seqNum                  (Vfma_io_out_bits_debug_seqNum_seqNum),
    .io_out_bits_debug_seqNum_uopIdx                  (Vfma_io_out_bits_debug_seqNum_uopIdx),
    .io_frm                                           (io_frm)
  );
  VIAluFix VialuFix (
    .clock                                            (ClockGate_1_Q),
    .reset                                            (reset),
    .io_in_ready                                      (VialuFix_io_in_ready),
    .io_in_valid                                      (in1ToN_io_out_1_valid),
    .io_in_bits_ctrl_fuOpType                         (in1ToN_io_out_1_bits_fuOpType),
    .io_in_bits_ctrl_vpu_vma                          (in1ToN_io_out_1_bits_vpu_vma),
    .io_in_bits_ctrl_vpu_vsew                         (in1ToN_io_out_1_bits_vpu_vsew),
    .io_in_bits_ctrl_vpu_vm                           (in1ToN_io_out_1_bits_vpu_vm),
    .io_in_bits_ctrl_vpu_vuopIdx                      (in1ToN_io_out_1_bits_vpu_vuopIdx),
    .io_in_bits_ctrl_vpu_isExt                        (in1ToN_io_out_1_bits_vpu_isExt),
    .io_in_bits_ctrl_vpu_isNarrow                     (in1ToN_io_out_1_bits_vpu_isNarrow),
    .io_in_bits_ctrl_vpu_isDstMask                    (in1ToN_io_out_1_bits_vpu_isDstMask),
    .io_in_bits_ctrlPipe_1_fuOpType                   (pipe1_fuOpType),
    .io_in_bits_ctrlPipe_1_robIdx_flag                (pipe1_robIdx_flag),
    .io_in_bits_ctrlPipe_1_robIdx_value               (pipe1_robIdx_value),
    .io_in_bits_ctrlPipe_1_pdest                      ({1'h0, pipe1_pdest}),
    .io_in_bits_ctrlPipe_1_vecWen                     (pipe1_vecWen),
    .io_in_bits_ctrlPipe_1_v0Wen                      (pipe1_v0Wen),
    .io_in_bits_ctrlPipe_1_vpu_vma                    (pipe1_vpu_vma),
    .io_in_bits_ctrlPipe_1_vpu_vta                    (pipe1_vpu_vta),
    .io_in_bits_ctrlPipe_1_vpu_vsew                   (pipe1_vpu_vsew),
    .io_in_bits_ctrlPipe_1_vpu_vm                     (pipe1_vpu_vm),
    .io_in_bits_ctrlPipe_1_vpu_vstart                 (pipe1_vpu_vstart),
    .io_in_bits_ctrlPipe_1_vpu_vuopIdx                (pipe1_vpu_vuopIdx),
    .io_in_bits_ctrlPipe_1_vpu_isExt                  (pipe1_vpu_isExt),
    .io_in_bits_ctrlPipe_1_vpu_isNarrow               (pipe1_vpu_isNarrow),
    .io_in_bits_ctrlPipe_1_vpu_isDstMask              (pipe1_vpu_isDstMask),
    .io_in_bits_ctrlPipe_1_vpu_isOpMask               (pipe1_vpu_isOpMask),
    .io_in_bits_validPipe_0                           (io_in_valid),
    .io_in_bits_validPipe_1                           (pipe_valid[1]),
    .io_in_bits_data_src_3                            (io_in_bits_src_3),
    .io_in_bits_data_src_2                            (io_in_bits_src_2),
    .io_in_bits_data_src_1                            (io_in_bits_src_1),
    .io_in_bits_data_src_0                            (io_in_bits_src_0),
    .io_in_bits_dataPipe_1_src_4                      (pipe1_src_4[7:0]),
    .io_in_bits_dataPipe_1_src_3                      (pipe1_src_3),
    .io_in_bits_dataPipe_1_src_2                      (pipe1_src_2),
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
    .io_out_valid                                     (VialuFix_io_out_valid),
    .io_out_bits_ctrl_robIdx_flag                     (VialuFix_io_out_bits_ctrl_robIdx_flag),
    .io_out_bits_ctrl_robIdx_value                    (VialuFix_io_out_bits_ctrl_robIdx_value),
    .io_out_bits_ctrl_pdest                           (VialuFix_io_out_bits_ctrl_pdest),
    .io_out_bits_ctrl_vecWen                          (VialuFix_io_out_bits_ctrl_vecWen),
    .io_out_bits_ctrl_v0Wen                           (VialuFix_io_out_bits_ctrl_v0Wen),
    .io_out_bits_res_data                             (VialuFix_io_out_bits_res_data),
    .io_out_bits_res_vxsat                            (VialuFix_io_out_bits_res_vxsat),
    .io_out_bits_perfDebugInfo_eliminatedMove         (VialuFix_io_out_bits_perfDebugInfo_eliminatedMove),
    .io_out_bits_perfDebugInfo_renameTime             (VialuFix_io_out_bits_perfDebugInfo_renameTime),
    .io_out_bits_perfDebugInfo_dispatchTime           (VialuFix_io_out_bits_perfDebugInfo_dispatchTime),
    .io_out_bits_perfDebugInfo_enqRsTime              (VialuFix_io_out_bits_perfDebugInfo_enqRsTime),
    .io_out_bits_perfDebugInfo_selectTime             (VialuFix_io_out_bits_perfDebugInfo_selectTime),
    .io_out_bits_perfDebugInfo_issueTime              (VialuFix_io_out_bits_perfDebugInfo_issueTime),
    .io_out_bits_perfDebugInfo_writebackTime          (VialuFix_io_out_bits_perfDebugInfo_writebackTime),
    .io_out_bits_perfDebugInfo_runahead_checkpoint_id (VialuFix_io_out_bits_perfDebugInfo_runahead_checkpoint_id),
    .io_out_bits_perfDebugInfo_tlbFirstReqTime        (VialuFix_io_out_bits_perfDebugInfo_tlbFirstReqTime),
    .io_out_bits_perfDebugInfo_tlbRespTime            (VialuFix_io_out_bits_perfDebugInfo_tlbRespTime),
    .io_out_bits_debug_seqNum_seqNum                  (VialuFix_io_out_bits_debug_seqNum_seqNum),
    .io_out_bits_debug_seqNum_uopIdx                  (VialuFix_io_out_bits_debug_seqNum_uopIdx),
    .io_vxrm                                          (io_vxrm)
  );
  VIMacU Vimac (
    .clock                                            (ClockGate_2_Q),
    .reset                                            (reset),
    .io_in_ready                                      (Vimac_io_in_ready),
    .io_in_valid                                      (in1ToN_io_out_2_valid),
    .io_in_bits_ctrl_fuOpType                         (in1ToN_io_out_2_bits_fuOpType),
    .io_in_bits_ctrl_vpu_vsew                         (in1ToN_io_out_2_bits_vpu_vsew),
    .io_in_bits_ctrl_vpu_vuopIdx                      (in1ToN_io_out_2_bits_vpu_vuopIdx),
    .io_in_bits_ctrlPipe_2_fuOpType                   (pipe2_fuOpType),
    .io_in_bits_ctrlPipe_2_robIdx_flag                (pipe2_robIdx_flag),
    .io_in_bits_ctrlPipe_2_robIdx_value               (pipe2_robIdx_value),
    .io_in_bits_ctrlPipe_2_pdest                      ({1'h0, pipe2_pdest}),
    .io_in_bits_ctrlPipe_2_vecWen                     (pipe2_vecWen),
    .io_in_bits_ctrlPipe_2_v0Wen                      (pipe2_v0Wen),
    .io_in_bits_ctrlPipe_2_vpu_vma                    (pipe2_vpu_vma),
    .io_in_bits_ctrlPipe_2_vpu_vta                    (pipe2_vpu_vta),
    .io_in_bits_ctrlPipe_2_vpu_vsew                   (pipe2_vpu_vsew),
    .io_in_bits_ctrlPipe_2_vpu_vm                     (pipe2_vpu_vm),
    .io_in_bits_ctrlPipe_2_vpu_vstart                 (pipe2_vpu_vstart),
    .io_in_bits_ctrlPipe_2_vpu_vuopIdx                (pipe2_vpu_vuopIdx),
    .io_in_bits_validPipe_2                           (pipe_valid[2]),
    .io_in_bits_data_src_2                            (io_in_bits_src_2),
    .io_in_bits_data_src_1                            (io_in_bits_src_1),
    .io_in_bits_data_src_0                            (io_in_bits_src_0),
    .io_in_bits_dataPipe_2_src_4                      (pipe2_src_4[7:0]),
    .io_in_bits_dataPipe_2_src_3                      (pipe2_src_3),
    .io_in_bits_dataPipe_2_src_2                      (pipe2_src_2),
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
    .io_out_valid                                     (Vimac_io_out_valid),
    .io_out_bits_ctrl_robIdx_flag                     (Vimac_io_out_bits_ctrl_robIdx_flag),
    .io_out_bits_ctrl_robIdx_value                    (Vimac_io_out_bits_ctrl_robIdx_value),
    .io_out_bits_ctrl_pdest                           (Vimac_io_out_bits_ctrl_pdest),
    .io_out_bits_ctrl_vecWen                          (Vimac_io_out_bits_ctrl_vecWen),
    .io_out_bits_ctrl_v0Wen                           (Vimac_io_out_bits_ctrl_v0Wen),
    .io_out_bits_res_data                             (Vimac_io_out_bits_res_data),
    .io_out_bits_res_vxsat                            (Vimac_io_out_bits_res_vxsat),
    .io_out_bits_perfDebugInfo_eliminatedMove         (Vimac_io_out_bits_perfDebugInfo_eliminatedMove),
    .io_out_bits_perfDebugInfo_renameTime             (Vimac_io_out_bits_perfDebugInfo_renameTime),
    .io_out_bits_perfDebugInfo_dispatchTime           (Vimac_io_out_bits_perfDebugInfo_dispatchTime),
    .io_out_bits_perfDebugInfo_enqRsTime              (Vimac_io_out_bits_perfDebugInfo_enqRsTime),
    .io_out_bits_perfDebugInfo_selectTime             (Vimac_io_out_bits_perfDebugInfo_selectTime),
    .io_out_bits_perfDebugInfo_issueTime              (Vimac_io_out_bits_perfDebugInfo_issueTime),
    .io_out_bits_perfDebugInfo_writebackTime          (Vimac_io_out_bits_perfDebugInfo_writebackTime),
    .io_out_bits_perfDebugInfo_runahead_checkpoint_id (Vimac_io_out_bits_perfDebugInfo_runahead_checkpoint_id),
    .io_out_bits_perfDebugInfo_tlbFirstReqTime        (Vimac_io_out_bits_perfDebugInfo_tlbFirstReqTime),
    .io_out_bits_perfDebugInfo_tlbRespTime            (Vimac_io_out_bits_perfDebugInfo_tlbRespTime),
    .io_out_bits_debug_seqNum_seqNum                  (Vimac_io_out_bits_debug_seqNum_seqNum),
    .io_out_bits_debug_seqNum_uopIdx                  (Vimac_io_out_bits_debug_seqNum_uopIdx),
    .io_vxrm                                          (io_vxrm)
  );
  VPPU Vppu (
    .clock                                            (ClockGate_3_Q),
    .reset                                            (reset),
    .io_in_ready                                      (Vppu_io_in_ready),
    .io_in_valid                                      (in1ToN_io_out_3_valid),
    .io_in_bits_ctrl_fuOpType                         (in1ToN_io_out_3_bits_fuOpType),
    .io_in_bits_ctrl_vpu_vma                          (in1ToN_io_out_3_bits_vpu_vma),
    .io_in_bits_ctrl_vpu_vta                          (in1ToN_io_out_3_bits_vpu_vta),
    .io_in_bits_ctrl_vpu_vsew                         (in1ToN_io_out_3_bits_vpu_vsew),
    .io_in_bits_ctrl_vpu_vlmul                        (in1ToN_io_out_3_bits_vpu_vlmul),
    .io_in_bits_ctrl_vpu_vm                           (in1ToN_io_out_3_bits_vpu_vm),
    .io_in_bits_ctrl_vpu_vstart                       (in1ToN_io_out_3_bits_vpu_vstart),
    .io_in_bits_ctrl_vpu_vuopIdx                      (in1ToN_io_out_3_bits_vpu_vuopIdx),
    .io_in_bits_ctrlPipe_2_robIdx_flag                (pipe2_robIdx_flag),
    .io_in_bits_ctrlPipe_2_robIdx_value               (pipe2_robIdx_value),
    .io_in_bits_ctrlPipe_2_pdest                      ({1'h0, pipe2_pdest}),
    .io_in_bits_ctrlPipe_2_vecWen                     (pipe2_vecWen),
    .io_in_bits_ctrlPipe_2_v0Wen                      (pipe2_v0Wen),
    .io_in_bits_ctrlPipe_2_vpu_vstart                 (pipe2_vpu_vstart),
    .io_in_bits_validPipe_2                           (pipe_valid[2]),
    .io_in_bits_data_src_4                            (io_in_bits_src_4[7:0]),
    .io_in_bits_data_src_3                            (io_in_bits_src_3),
    .io_in_bits_data_src_2                            (io_in_bits_src_2),
    .io_in_bits_data_src_1                            (io_in_bits_src_1),
    .io_in_bits_data_src_0                            (io_in_bits_src_0),
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
    .io_out_valid                                     (Vppu_io_out_valid),
    .io_out_bits_ctrl_robIdx_flag                     (Vppu_io_out_bits_ctrl_robIdx_flag),
    .io_out_bits_ctrl_robIdx_value                    (Vppu_io_out_bits_ctrl_robIdx_value),
    .io_out_bits_ctrl_pdest                           (Vppu_io_out_bits_ctrl_pdest),
    .io_out_bits_ctrl_vecWen                          (Vppu_io_out_bits_ctrl_vecWen),
    .io_out_bits_ctrl_v0Wen                           (Vppu_io_out_bits_ctrl_v0Wen),
    .io_out_bits_ctrl_exceptionVec_2                  (Vppu_io_out_bits_ctrl_exceptionVec_2),
    .io_out_bits_res_data                             (Vppu_io_out_bits_res_data),
    .io_out_bits_perfDebugInfo_eliminatedMove         (Vppu_io_out_bits_perfDebugInfo_eliminatedMove),
    .io_out_bits_perfDebugInfo_renameTime             (Vppu_io_out_bits_perfDebugInfo_renameTime),
    .io_out_bits_perfDebugInfo_dispatchTime           (Vppu_io_out_bits_perfDebugInfo_dispatchTime),
    .io_out_bits_perfDebugInfo_enqRsTime              (Vppu_io_out_bits_perfDebugInfo_enqRsTime),
    .io_out_bits_perfDebugInfo_selectTime             (Vppu_io_out_bits_perfDebugInfo_selectTime),
    .io_out_bits_perfDebugInfo_issueTime              (Vppu_io_out_bits_perfDebugInfo_issueTime),
    .io_out_bits_perfDebugInfo_writebackTime          (Vppu_io_out_bits_perfDebugInfo_writebackTime),
    .io_out_bits_perfDebugInfo_runahead_checkpoint_id (Vppu_io_out_bits_perfDebugInfo_runahead_checkpoint_id),
    .io_out_bits_perfDebugInfo_tlbFirstReqTime        (Vppu_io_out_bits_perfDebugInfo_tlbFirstReqTime),
    .io_out_bits_perfDebugInfo_tlbRespTime            (Vppu_io_out_bits_perfDebugInfo_tlbRespTime),
    .io_out_bits_debug_seqNum_seqNum                  (Vppu_io_out_bits_debug_seqNum_seqNum),
    .io_out_bits_debug_seqNum_uopIdx                  (Vppu_io_out_bits_debug_seqNum_uopIdx)
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
  ClockGate ClockGate_3 (
    .TE (cg_bore_3_cgen),
    .E  (fu_clk_en[3]),
    .CK (clock),
    .Q  (ClockGate_3_Q)
  );

  // ---- 写回：io.out.valid 与各字段的 Mux1H ----
  assign io_out_valid = out_valid;
  // 第 0 组：Vfma, VialuFix, Vimac, Vppu 共同产出 —— data_0, data_1, data_2, pdest, robIdx_flag, robIdx_value, vecWen, v0Wen, debugInfo_eliminatedMove, debugInfo_renameTime, debugInfo_dispatchTime, debugInfo_enqRsTime, debugInfo_selectTime, debugInfo_issueTime, debugInfo_writebackTime, debugInfo_runahead_checkpoint_id, debugInfo_tlbFirstReqTime, debugInfo_tlbRespTime, debug_seqNum_seqNum, debug_seqNum_uopIdx
  wire [1042:0] wb0_out;
  xs_ExeUnit_wbsel #(.N(4), .W(1043)) wb0 (
    .sel  ({Vppu_io_out_valid, Vimac_io_out_valid, VialuFix_io_out_valid, Vfma_io_out_valid}),
    .data ({
      {Vppu_io_out_bits_res_data,
       Vppu_io_out_bits_res_data,
       Vppu_io_out_bits_res_data,
       Vppu_io_out_bits_ctrl_pdest[6:0],
       Vppu_io_out_bits_ctrl_robIdx_flag,
       Vppu_io_out_bits_ctrl_robIdx_value,
       Vppu_io_out_bits_ctrl_vecWen,
       Vppu_io_out_bits_ctrl_v0Wen,
       Vppu_io_out_bits_perfDebugInfo_eliminatedMove,
       Vppu_io_out_bits_perfDebugInfo_renameTime,
       Vppu_io_out_bits_perfDebugInfo_dispatchTime,
       Vppu_io_out_bits_perfDebugInfo_enqRsTime,
       Vppu_io_out_bits_perfDebugInfo_selectTime,
       Vppu_io_out_bits_perfDebugInfo_issueTime,
       Vppu_io_out_bits_perfDebugInfo_writebackTime,
       Vppu_io_out_bits_perfDebugInfo_runahead_checkpoint_id,
       Vppu_io_out_bits_perfDebugInfo_tlbFirstReqTime,
       Vppu_io_out_bits_perfDebugInfo_tlbRespTime,
       Vppu_io_out_bits_debug_seqNum_seqNum,
       Vppu_io_out_bits_debug_seqNum_uopIdx},
      {Vimac_io_out_bits_res_data,
       Vimac_io_out_bits_res_data,
       Vimac_io_out_bits_res_data,
       Vimac_io_out_bits_ctrl_pdest[6:0],
       Vimac_io_out_bits_ctrl_robIdx_flag,
       Vimac_io_out_bits_ctrl_robIdx_value,
       Vimac_io_out_bits_ctrl_vecWen,
       Vimac_io_out_bits_ctrl_v0Wen,
       Vimac_io_out_bits_perfDebugInfo_eliminatedMove,
       Vimac_io_out_bits_perfDebugInfo_renameTime,
       Vimac_io_out_bits_perfDebugInfo_dispatchTime,
       Vimac_io_out_bits_perfDebugInfo_enqRsTime,
       Vimac_io_out_bits_perfDebugInfo_selectTime,
       Vimac_io_out_bits_perfDebugInfo_issueTime,
       Vimac_io_out_bits_perfDebugInfo_writebackTime,
       Vimac_io_out_bits_perfDebugInfo_runahead_checkpoint_id,
       Vimac_io_out_bits_perfDebugInfo_tlbFirstReqTime,
       Vimac_io_out_bits_perfDebugInfo_tlbRespTime,
       Vimac_io_out_bits_debug_seqNum_seqNum,
       Vimac_io_out_bits_debug_seqNum_uopIdx},
      {VialuFix_io_out_bits_res_data,
       VialuFix_io_out_bits_res_data,
       VialuFix_io_out_bits_res_data,
       VialuFix_io_out_bits_ctrl_pdest[6:0],
       VialuFix_io_out_bits_ctrl_robIdx_flag,
       VialuFix_io_out_bits_ctrl_robIdx_value,
       VialuFix_io_out_bits_ctrl_vecWen,
       VialuFix_io_out_bits_ctrl_v0Wen,
       VialuFix_io_out_bits_perfDebugInfo_eliminatedMove,
       VialuFix_io_out_bits_perfDebugInfo_renameTime,
       VialuFix_io_out_bits_perfDebugInfo_dispatchTime,
       VialuFix_io_out_bits_perfDebugInfo_enqRsTime,
       VialuFix_io_out_bits_perfDebugInfo_selectTime,
       VialuFix_io_out_bits_perfDebugInfo_issueTime,
       VialuFix_io_out_bits_perfDebugInfo_writebackTime,
       VialuFix_io_out_bits_perfDebugInfo_runahead_checkpoint_id,
       VialuFix_io_out_bits_perfDebugInfo_tlbFirstReqTime,
       VialuFix_io_out_bits_perfDebugInfo_tlbRespTime,
       VialuFix_io_out_bits_debug_seqNum_seqNum,
       VialuFix_io_out_bits_debug_seqNum_uopIdx},
      {Vfma_io_out_bits_res_data,
       Vfma_io_out_bits_res_data,
       Vfma_io_out_bits_res_data,
       Vfma_io_out_bits_ctrl_pdest[6:0],
       Vfma_io_out_bits_ctrl_robIdx_flag,
       Vfma_io_out_bits_ctrl_robIdx_value,
       Vfma_io_out_bits_ctrl_vecWen,
       Vfma_io_out_bits_ctrl_v0Wen,
       Vfma_io_out_bits_perfDebugInfo_eliminatedMove,
       Vfma_io_out_bits_perfDebugInfo_renameTime,
       Vfma_io_out_bits_perfDebugInfo_dispatchTime,
       Vfma_io_out_bits_perfDebugInfo_enqRsTime,
       Vfma_io_out_bits_perfDebugInfo_selectTime,
       Vfma_io_out_bits_perfDebugInfo_issueTime,
       Vfma_io_out_bits_perfDebugInfo_writebackTime,
       Vfma_io_out_bits_perfDebugInfo_runahead_checkpoint_id,
       Vfma_io_out_bits_perfDebugInfo_tlbFirstReqTime,
       Vfma_io_out_bits_perfDebugInfo_tlbRespTime,
       Vfma_io_out_bits_debug_seqNum_seqNum,
       Vfma_io_out_bits_debug_seqNum_uopIdx}
    }),
    .out  (wb0_out)
  );
  assign {
    io_out_bits_data_0,
    io_out_bits_data_1,
    io_out_bits_data_2,
    io_out_bits_pdest,
    io_out_bits_robIdx_flag,
    io_out_bits_robIdx_value,
    io_out_bits_vecWen,
    io_out_bits_v0Wen,
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
  // 第 1 组：Vfma 共同产出 —— fflags, wflags
  wire [5:0] wb1_out;
  xs_ExeUnit_wbsel #(.N(1), .W(6)) wb1 (
    .sel  ({Vfma_io_out_valid}),
    .data ({
      {Vfma_io_out_bits_res_fflags,
       Vfma_io_out_bits_ctrl_fpu_wflags}
    }),
    .out  (wb1_out)
  );
  assign {
    io_out_bits_fflags,
    io_out_bits_wflags
  } = wb1_out;
  // 第 2 组：VialuFix, Vimac 共同产出 —— vxsat
  wire [0:0] wb2_out;
  xs_ExeUnit_wbsel #(.N(2), .W(1)) wb2 (
    .sel  ({Vimac_io_out_valid, VialuFix_io_out_valid}),
    .data ({
      Vimac_io_out_bits_res_vxsat,
      VialuFix_io_out_bits_res_vxsat
    }),
    .out  (wb2_out)
  );
  assign io_out_bits_vxsat = wb2_out;
  // 第 3 组：Vppu 共同产出 —— exceptionVec_2
  wire [0:0] wb3_out;
  xs_ExeUnit_wbsel #(.N(1), .W(1)) wb3 (
    .sel  ({Vppu_io_out_valid}),
    .data ({
      Vppu_io_out_bits_ctrl_exceptionVec_2
    }),
    .out  (wb3_out)
  );
  assign io_out_bits_exceptionVec_2 = wb3_out;

endmodule
