// =============================================================================
// ExeUnit_8 —— 执行单元外壳（golden 同名 wrapper；由 scripts/gen_exeunit.py 从 G1 golden 生成，勿手改）
// -----------------------------------------------------------------------------
// FU（按 Dispatcher 出口序）：Falu(FAlu, 延迟 1, 门控), Fcvt(FCVT, 延迟 2, 门控), f2v(IntFPToVec, 延迟 0), Fmac(FMA, 延迟 3, 门控)
// inPipe：3 级；字段 robIdx[9]×3级, fuOpType[9]×2级, pdest[8]×3级, rfWen[1]×2级, fpWen[1]×3级, fpu_wflags[1]×3级
// 机制全部在 xs_ExeUnit_core（发射握手 / inPipe 冲刷流水 / 时钟门控使能 / 写回有效）与
//   xs_ExeUnit_wbsel（写回字段 Mux1H）里；本文件只有例化、连线与字段打包。
// 子模块：Dispatcher 与各 FU、ClockGate 均为已签核件（两侧白盒，实例名与 golden 相同）。
// golden 对照：G1-canonical/golden-rtl/ExeUnit_8.sv
// 本文件导航（一个 golden 模块一个文件，不拆；行号由生成器回填）：
//   L89    子模块输出线（名字 = golden 的 _<实例>_<端口> 去掉前导下划线）
//   L249   外壳控制核
//   L294   inPipe 第 s 级字段拆包（只拆有 FU 读的那些）
//   L314   Dispatcher：按 fuType 把指令派给一个 FU
//   L416   功能单元
//   L623   时钟门控（E 来自核 §3；TE 来自 DFT 的 cg_bore）
//   L643   写回：io.out.valid 与各字段的 Mux1H
// =============================================================================
module ExeUnit_8(
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
  input  [63:0]  io_in_bits_src_0,
  input  [63:0]  io_in_bits_src_1,
  input  [63:0]  io_in_bits_src_2,
  input          io_in_bits_robIdx_flag,
  input  [7:0]   io_in_bits_robIdx_value,
  input  [7:0]   io_in_bits_pdest,
  input          io_in_bits_rfWen,
  input          io_in_bits_fpWen,
  input          io_in_bits_vecWen,
  input          io_in_bits_v0Wen,
  input          io_in_bits_fpu_wflags,
  input  [1:0]   io_in_bits_fpu_fmt,
  input  [2:0]   io_in_bits_fpu_rm,
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
  output [7:0]   io_out_bits_pdest,
  output         io_out_bits_robIdx_flag,
  output [7:0]   io_out_bits_robIdx_value,
  output         io_out_bits_intWen,
  output         io_out_bits_fpWen,
  output         io_out_bits_vecWen,
  output         io_out_bits_v0Wen,
  output [4:0]   io_out_bits_fflags,
  output         io_out_bits_wflags,
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
  input          cg_bore_cgen,
  input          cg_bore_1_cgen,
  input          cg_bore_2_cgen
);

  // ---- 子模块输出线（名字 = golden 的 _<实例>_<端口> 去掉前导下划线）----
  wire in1ToN_io_out_0_valid;
  wire [8:0] in1ToN_io_out_0_bits_fuOpType;
  wire [1:0] in1ToN_io_out_0_bits_fpu_fmt;
  wire [2:0] in1ToN_io_out_0_bits_fpu_rm;
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
  wire [1:0] in1ToN_io_out_1_bits_fpu_fmt;
  wire [2:0] in1ToN_io_out_1_bits_fpu_rm;
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
  wire in1ToN_io_out_2_bits_robIdx_flag;
  wire [7:0] in1ToN_io_out_2_bits_robIdx_value;
  wire [7:0] in1ToN_io_out_2_bits_pdest;
  wire in1ToN_io_out_2_bits_fpWen;
  wire in1ToN_io_out_2_bits_vecWen;
  wire in1ToN_io_out_2_bits_v0Wen;
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
  wire [1:0] in1ToN_io_out_3_bits_fpu_fmt;
  wire [2:0] in1ToN_io_out_3_bits_fpu_rm;
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
  wire Fmac_io_in_ready;
  wire Fmac_io_out_valid;
  wire Fmac_io_out_bits_ctrl_robIdx_flag;
  wire [7:0] Fmac_io_out_bits_ctrl_robIdx_value;
  wire [7:0] Fmac_io_out_bits_ctrl_pdest;
  wire Fmac_io_out_bits_ctrl_fpWen;
  wire Fmac_io_out_bits_ctrl_fpu_wflags;
  wire [63:0] Fmac_io_out_bits_res_data;
  wire [4:0] Fmac_io_out_bits_res_fflags;
  wire Fmac_io_out_bits_perfDebugInfo_eliminatedMove;
  wire [63:0] Fmac_io_out_bits_perfDebugInfo_renameTime;
  wire [63:0] Fmac_io_out_bits_perfDebugInfo_dispatchTime;
  wire [63:0] Fmac_io_out_bits_perfDebugInfo_enqRsTime;
  wire [63:0] Fmac_io_out_bits_perfDebugInfo_selectTime;
  wire [63:0] Fmac_io_out_bits_perfDebugInfo_issueTime;
  wire [63:0] Fmac_io_out_bits_perfDebugInfo_writebackTime;
  wire [63:0] Fmac_io_out_bits_perfDebugInfo_runahead_checkpoint_id;
  wire [63:0] Fmac_io_out_bits_perfDebugInfo_tlbFirstReqTime;
  wire [63:0] Fmac_io_out_bits_perfDebugInfo_tlbRespTime;
  wire [55:0] Fmac_io_out_bits_debug_seqNum_seqNum;
  wire [7:0] Fmac_io_out_bits_debug_seqNum_uopIdx;
  wire f2v_io_in_ready;
  wire f2v_io_out_valid;
  wire f2v_io_out_bits_ctrl_robIdx_flag;
  wire [7:0] f2v_io_out_bits_ctrl_robIdx_value;
  wire [7:0] f2v_io_out_bits_ctrl_pdest;
  wire f2v_io_out_bits_ctrl_fpWen;
  wire f2v_io_out_bits_ctrl_vecWen;
  wire f2v_io_out_bits_ctrl_v0Wen;
  wire [127:0] f2v_io_out_bits_res_data;
  wire f2v_io_out_bits_perfDebugInfo_eliminatedMove;
  wire [63:0] f2v_io_out_bits_perfDebugInfo_renameTime;
  wire [63:0] f2v_io_out_bits_perfDebugInfo_dispatchTime;
  wire [63:0] f2v_io_out_bits_perfDebugInfo_enqRsTime;
  wire [63:0] f2v_io_out_bits_perfDebugInfo_selectTime;
  wire [63:0] f2v_io_out_bits_perfDebugInfo_issueTime;
  wire [63:0] f2v_io_out_bits_perfDebugInfo_writebackTime;
  wire [63:0] f2v_io_out_bits_perfDebugInfo_runahead_checkpoint_id;
  wire [63:0] f2v_io_out_bits_perfDebugInfo_tlbFirstReqTime;
  wire [63:0] f2v_io_out_bits_perfDebugInfo_tlbRespTime;
  wire [55:0] f2v_io_out_bits_debug_seqNum_seqNum;
  wire [7:0] f2v_io_out_bits_debug_seqNum_uopIdx;
  wire Fcvt_io_in_ready;
  wire Fcvt_io_out_valid;
  wire Fcvt_io_out_bits_ctrl_robIdx_flag;
  wire [7:0] Fcvt_io_out_bits_ctrl_robIdx_value;
  wire [7:0] Fcvt_io_out_bits_ctrl_pdest;
  wire Fcvt_io_out_bits_ctrl_rfWen;
  wire Fcvt_io_out_bits_ctrl_fpWen;
  wire Fcvt_io_out_bits_ctrl_fpu_wflags;
  wire [63:0] Fcvt_io_out_bits_res_data;
  wire [4:0] Fcvt_io_out_bits_res_fflags;
  wire Fcvt_io_out_bits_perfDebugInfo_eliminatedMove;
  wire [63:0] Fcvt_io_out_bits_perfDebugInfo_renameTime;
  wire [63:0] Fcvt_io_out_bits_perfDebugInfo_dispatchTime;
  wire [63:0] Fcvt_io_out_bits_perfDebugInfo_enqRsTime;
  wire [63:0] Fcvt_io_out_bits_perfDebugInfo_selectTime;
  wire [63:0] Fcvt_io_out_bits_perfDebugInfo_issueTime;
  wire [63:0] Fcvt_io_out_bits_perfDebugInfo_writebackTime;
  wire [63:0] Fcvt_io_out_bits_perfDebugInfo_runahead_checkpoint_id;
  wire [63:0] Fcvt_io_out_bits_perfDebugInfo_tlbFirstReqTime;
  wire [63:0] Fcvt_io_out_bits_perfDebugInfo_tlbRespTime;
  wire [55:0] Fcvt_io_out_bits_debug_seqNum_seqNum;
  wire [7:0] Fcvt_io_out_bits_debug_seqNum_uopIdx;
  wire Falu_io_in_ready;
  wire Falu_io_out_valid;
  wire Falu_io_out_bits_ctrl_robIdx_flag;
  wire [7:0] Falu_io_out_bits_ctrl_robIdx_value;
  wire [7:0] Falu_io_out_bits_ctrl_pdest;
  wire Falu_io_out_bits_ctrl_rfWen;
  wire Falu_io_out_bits_ctrl_fpWen;
  wire Falu_io_out_bits_ctrl_fpu_wflags;
  wire [63:0] Falu_io_out_bits_res_data;
  wire [4:0] Falu_io_out_bits_res_fflags;
  wire Falu_io_out_bits_perfDebugInfo_eliminatedMove;
  wire [63:0] Falu_io_out_bits_perfDebugInfo_renameTime;
  wire [63:0] Falu_io_out_bits_perfDebugInfo_dispatchTime;
  wire [63:0] Falu_io_out_bits_perfDebugInfo_enqRsTime;
  wire [63:0] Falu_io_out_bits_perfDebugInfo_selectTime;
  wire [63:0] Falu_io_out_bits_perfDebugInfo_issueTime;
  wire [63:0] Falu_io_out_bits_perfDebugInfo_writebackTime;
  wire [63:0] Falu_io_out_bits_perfDebugInfo_runahead_checkpoint_id;
  wire [63:0] Falu_io_out_bits_perfDebugInfo_tlbFirstReqTime;
  wire [63:0] Falu_io_out_bits_perfDebugInfo_tlbRespTime;
  wire [55:0] Falu_io_out_bits_debug_seqNum_seqNum;
  wire [7:0] Falu_io_out_bits_debug_seqNum_uopIdx;
  wire in1ToN_io_in_ready;

  // ---- 外壳控制核 ----
  localparam int N_FU    = 4;
  localparam int LAT_MAX = 3;
  localparam int PAY_W   = 29;
  wire                     disp_in_valid;
  wire [LAT_MAX:0]         pipe_valid;
  wire [LAT_MAX:0][PAY_W-1:0] pipe_data;
  wire [N_FU-1:0]          fu_clk_en;
  wire [0:0][4:0]        att_q;
  wire                     out_valid;
  xs_ExeUnit_core #(
    .N_FU         (N_FU),
    .FU_LAT       ('{1, 2, 0, 3}),
    .FU_UNCERTAIN ('{0, 0, 0, 0}),
    .HAS_BUSY     (1'b0),
    .LAT_MAX      (LAT_MAX),
    .NF           (6),
    .FIELD_W      ('{9, 9, 8, 1, 1, 1}),
    .FIELD_DEPTH  ('{3, 2, 3, 2, 3, 3}),
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
    .in_payload      ({io_in_bits_fpu_wflags, io_in_bits_fpWen, io_in_bits_rfWen, io_in_bits_pdest, io_in_bits_fuOpType, io_in_bits_robIdx_flag, io_in_bits_robIdx_value}),
    .disp_in_valid   (disp_in_valid),
    .disp_in_ready   (in1ToN_io_in_ready),
    .pipe_valid      (pipe_valid),
    .pipe_data       (pipe_data),
    .fu_in_valid     ({in1ToN_io_out_3_valid, in1ToN_io_out_2_valid, in1ToN_io_out_1_valid, in1ToN_io_out_0_valid}),
    .fu_in_ready     ({Fmac_io_in_ready, f2v_io_in_ready, Fcvt_io_in_ready, Falu_io_in_ready}),
    .fu_out_valid    ({Fmac_io_out_valid, f2v_io_out_valid, Fcvt_io_out_valid, Falu_io_out_valid}),
    .out_ready       (io_out_ready),
    .fu_clk_en       (fu_clk_en),
    .att_in          (5'h0),
    .att_q           (att_q),
    .out_valid       (out_valid)
  );

  // ---- inPipe 第 s 级字段拆包（只拆有 FU 读的那些）----
  wire pipe1_fpWen = pipe_data[1][27];
  wire pipe1_fpu_wflags = pipe_data[1][28];
  wire [7:0] pipe1_pdest = pipe_data[1][25:18];
  wire pipe1_rfWen = pipe_data[1][26];
  wire pipe1_robIdx_flag = pipe_data[1][8];
  wire [7:0] pipe1_robIdx_value = pipe_data[1][7:0];
  wire pipe2_fpWen = pipe_data[2][27];
  wire pipe2_fpu_wflags = pipe_data[2][28];
  wire [8:0] pipe2_fuOpType = pipe_data[2][17:9];
  wire [7:0] pipe2_pdest = pipe_data[2][25:18];
  wire pipe2_rfWen = pipe_data[2][26];
  wire pipe2_robIdx_flag = pipe_data[2][8];
  wire [7:0] pipe2_robIdx_value = pipe_data[2][7:0];
  wire pipe3_fpWen = pipe_data[3][27];
  wire pipe3_fpu_wflags = pipe_data[3][28];
  wire [7:0] pipe3_pdest = pipe_data[3][25:18];
  wire pipe3_robIdx_flag = pipe_data[3][8];
  wire [7:0] pipe3_robIdx_value = pipe_data[3][7:0];

  // ---- Dispatcher：按 fuType 把指令派给一个 FU ----
  Dispatcher_8 in1ToN (
    .clock                                              (clock),
    .reset                                              (reset),
    .io_in_ready                                        (in1ToN_io_in_ready),
    .io_in_valid                                        (disp_in_valid),
    .io_in_bits_fuType                                  (io_in_bits_fuType),
    .io_in_bits_fuOpType                                (io_in_bits_fuOpType),
    .io_in_bits_robIdx_flag                             (io_in_bits_robIdx_flag),
    .io_in_bits_robIdx_value                            (io_in_bits_robIdx_value),
    .io_in_bits_pdest                                   (io_in_bits_pdest),
    .io_in_bits_fpWen                                   (io_in_bits_fpWen),
    .io_in_bits_vecWen                                  (io_in_bits_vecWen),
    .io_in_bits_v0Wen                                   (io_in_bits_v0Wen),
    .io_in_bits_fpu_fmt                                 (io_in_bits_fpu_fmt),
    .io_in_bits_fpu_rm                                  (io_in_bits_fpu_rm),
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
    .io_out_0_ready                                     (Falu_io_in_ready),
    .io_out_0_valid                                     (in1ToN_io_out_0_valid),
    .io_out_0_bits_fuOpType                             (in1ToN_io_out_0_bits_fuOpType),
    .io_out_0_bits_fpu_fmt                              (in1ToN_io_out_0_bits_fpu_fmt),
    .io_out_0_bits_fpu_rm                               (in1ToN_io_out_0_bits_fpu_rm),
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
    .io_out_1_ready                                     (Fcvt_io_in_ready),
    .io_out_1_valid                                     (in1ToN_io_out_1_valid),
    .io_out_1_bits_fuOpType                             (in1ToN_io_out_1_bits_fuOpType),
    .io_out_1_bits_fpu_fmt                              (in1ToN_io_out_1_bits_fpu_fmt),
    .io_out_1_bits_fpu_rm                               (in1ToN_io_out_1_bits_fpu_rm),
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
    .io_out_2_ready                                     (f2v_io_in_ready),
    .io_out_2_valid                                     (in1ToN_io_out_2_valid),
    .io_out_2_bits_fuOpType                             (in1ToN_io_out_2_bits_fuOpType),
    .io_out_2_bits_robIdx_flag                          (in1ToN_io_out_2_bits_robIdx_flag),
    .io_out_2_bits_robIdx_value                         (in1ToN_io_out_2_bits_robIdx_value),
    .io_out_2_bits_pdest                                (in1ToN_io_out_2_bits_pdest),
    .io_out_2_bits_fpWen                                (in1ToN_io_out_2_bits_fpWen),
    .io_out_2_bits_vecWen                               (in1ToN_io_out_2_bits_vecWen),
    .io_out_2_bits_v0Wen                                (in1ToN_io_out_2_bits_v0Wen),
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
    .io_out_3_ready                                     (Fmac_io_in_ready),
    .io_out_3_valid                                     (in1ToN_io_out_3_valid),
    .io_out_3_bits_fuOpType                             (in1ToN_io_out_3_bits_fuOpType),
    .io_out_3_bits_fpu_fmt                              (in1ToN_io_out_3_bits_fpu_fmt),
    .io_out_3_bits_fpu_rm                               (in1ToN_io_out_3_bits_fpu_rm),
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
  FAlu Falu (
    .clock                                            (ClockGate_Q),
    .reset                                            (reset),
    .io_in_ready                                      (Falu_io_in_ready),
    .io_in_valid                                      (in1ToN_io_out_0_valid),
    .io_in_bits_ctrl_fuOpType                         (in1ToN_io_out_0_bits_fuOpType),
    .io_in_bits_ctrl_fpu_fmt                          (in1ToN_io_out_0_bits_fpu_fmt),
    .io_in_bits_ctrl_fpu_rm                           (in1ToN_io_out_0_bits_fpu_rm),
    .io_in_bits_ctrlPipe_1_robIdx_flag                (pipe1_robIdx_flag),
    .io_in_bits_ctrlPipe_1_robIdx_value               (pipe1_robIdx_value),
    .io_in_bits_ctrlPipe_1_pdest                      (pipe1_pdest),
    .io_in_bits_ctrlPipe_1_rfWen                      (pipe1_rfWen),
    .io_in_bits_ctrlPipe_1_fpWen                      (pipe1_fpWen),
    .io_in_bits_ctrlPipe_1_fpu_wflags                 (pipe1_fpu_wflags),
    .io_in_bits_validPipe_1                           (pipe_valid[1]),
    .io_in_bits_data_src_1                            (io_in_bits_src_1),
    .io_in_bits_data_src_0                            (io_in_bits_src_0),
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
    .io_out_valid                                     (Falu_io_out_valid),
    .io_out_bits_ctrl_robIdx_flag                     (Falu_io_out_bits_ctrl_robIdx_flag),
    .io_out_bits_ctrl_robIdx_value                    (Falu_io_out_bits_ctrl_robIdx_value),
    .io_out_bits_ctrl_pdest                           (Falu_io_out_bits_ctrl_pdest),
    .io_out_bits_ctrl_rfWen                           (Falu_io_out_bits_ctrl_rfWen),
    .io_out_bits_ctrl_fpWen                           (Falu_io_out_bits_ctrl_fpWen),
    .io_out_bits_ctrl_fpu_wflags                      (Falu_io_out_bits_ctrl_fpu_wflags),
    .io_out_bits_res_data                             (Falu_io_out_bits_res_data),
    .io_out_bits_res_fflags                           (Falu_io_out_bits_res_fflags),
    .io_out_bits_perfDebugInfo_eliminatedMove         (Falu_io_out_bits_perfDebugInfo_eliminatedMove),
    .io_out_bits_perfDebugInfo_renameTime             (Falu_io_out_bits_perfDebugInfo_renameTime),
    .io_out_bits_perfDebugInfo_dispatchTime           (Falu_io_out_bits_perfDebugInfo_dispatchTime),
    .io_out_bits_perfDebugInfo_enqRsTime              (Falu_io_out_bits_perfDebugInfo_enqRsTime),
    .io_out_bits_perfDebugInfo_selectTime             (Falu_io_out_bits_perfDebugInfo_selectTime),
    .io_out_bits_perfDebugInfo_issueTime              (Falu_io_out_bits_perfDebugInfo_issueTime),
    .io_out_bits_perfDebugInfo_writebackTime          (Falu_io_out_bits_perfDebugInfo_writebackTime),
    .io_out_bits_perfDebugInfo_runahead_checkpoint_id (Falu_io_out_bits_perfDebugInfo_runahead_checkpoint_id),
    .io_out_bits_perfDebugInfo_tlbFirstReqTime        (Falu_io_out_bits_perfDebugInfo_tlbFirstReqTime),
    .io_out_bits_perfDebugInfo_tlbRespTime            (Falu_io_out_bits_perfDebugInfo_tlbRespTime),
    .io_out_bits_debug_seqNum_seqNum                  (Falu_io_out_bits_debug_seqNum_seqNum),
    .io_out_bits_debug_seqNum_uopIdx                  (Falu_io_out_bits_debug_seqNum_uopIdx),
    .io_frm                                           (io_frm)
  );
  FCVT Fcvt (
    .clock                                            (ClockGate_1_Q),
    .reset                                            (reset),
    .io_in_ready                                      (Fcvt_io_in_ready),
    .io_in_valid                                      (in1ToN_io_out_1_valid),
    .io_in_bits_ctrl_fuOpType                         (in1ToN_io_out_1_bits_fuOpType),
    .io_in_bits_ctrl_fpu_fmt                          (in1ToN_io_out_1_bits_fpu_fmt),
    .io_in_bits_ctrl_fpu_rm                           (in1ToN_io_out_1_bits_fpu_rm),
    .io_in_bits_ctrlPipe_2_fuOpType                   (pipe2_fuOpType),
    .io_in_bits_ctrlPipe_2_robIdx_flag                (pipe2_robIdx_flag),
    .io_in_bits_ctrlPipe_2_robIdx_value               (pipe2_robIdx_value),
    .io_in_bits_ctrlPipe_2_pdest                      (pipe2_pdest),
    .io_in_bits_ctrlPipe_2_rfWen                      (pipe2_rfWen),
    .io_in_bits_ctrlPipe_2_fpWen                      (pipe2_fpWen),
    .io_in_bits_ctrlPipe_2_fpu_wflags                 (pipe2_fpu_wflags),
    .io_in_bits_validPipe_2                           (pipe_valid[2]),
    .io_in_bits_data_src_0                            (io_in_bits_src_0),
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
    .io_out_valid                                     (Fcvt_io_out_valid),
    .io_out_bits_ctrl_robIdx_flag                     (Fcvt_io_out_bits_ctrl_robIdx_flag),
    .io_out_bits_ctrl_robIdx_value                    (Fcvt_io_out_bits_ctrl_robIdx_value),
    .io_out_bits_ctrl_pdest                           (Fcvt_io_out_bits_ctrl_pdest),
    .io_out_bits_ctrl_rfWen                           (Fcvt_io_out_bits_ctrl_rfWen),
    .io_out_bits_ctrl_fpWen                           (Fcvt_io_out_bits_ctrl_fpWen),
    .io_out_bits_ctrl_fpu_wflags                      (Fcvt_io_out_bits_ctrl_fpu_wflags),
    .io_out_bits_res_data                             (Fcvt_io_out_bits_res_data),
    .io_out_bits_res_fflags                           (Fcvt_io_out_bits_res_fflags),
    .io_out_bits_perfDebugInfo_eliminatedMove         (Fcvt_io_out_bits_perfDebugInfo_eliminatedMove),
    .io_out_bits_perfDebugInfo_renameTime             (Fcvt_io_out_bits_perfDebugInfo_renameTime),
    .io_out_bits_perfDebugInfo_dispatchTime           (Fcvt_io_out_bits_perfDebugInfo_dispatchTime),
    .io_out_bits_perfDebugInfo_enqRsTime              (Fcvt_io_out_bits_perfDebugInfo_enqRsTime),
    .io_out_bits_perfDebugInfo_selectTime             (Fcvt_io_out_bits_perfDebugInfo_selectTime),
    .io_out_bits_perfDebugInfo_issueTime              (Fcvt_io_out_bits_perfDebugInfo_issueTime),
    .io_out_bits_perfDebugInfo_writebackTime          (Fcvt_io_out_bits_perfDebugInfo_writebackTime),
    .io_out_bits_perfDebugInfo_runahead_checkpoint_id (Fcvt_io_out_bits_perfDebugInfo_runahead_checkpoint_id),
    .io_out_bits_perfDebugInfo_tlbFirstReqTime        (Fcvt_io_out_bits_perfDebugInfo_tlbFirstReqTime),
    .io_out_bits_perfDebugInfo_tlbRespTime            (Fcvt_io_out_bits_perfDebugInfo_tlbRespTime),
    .io_out_bits_debug_seqNum_seqNum                  (Fcvt_io_out_bits_debug_seqNum_seqNum),
    .io_out_bits_debug_seqNum_uopIdx                  (Fcvt_io_out_bits_debug_seqNum_uopIdx),
    .io_frm                                           (io_frm)
  );
  IntFPToVec f2v (
    .io_in_ready                                      (f2v_io_in_ready),
    .io_in_valid                                      (in1ToN_io_out_2_valid),
    .io_in_bits_ctrl_fuOpType                         (in1ToN_io_out_2_bits_fuOpType),
    .io_in_bits_ctrl_robIdx_flag                      (in1ToN_io_out_2_bits_robIdx_flag),
    .io_in_bits_ctrl_robIdx_value                     (in1ToN_io_out_2_bits_robIdx_value),
    .io_in_bits_ctrl_pdest                            (in1ToN_io_out_2_bits_pdest),
    .io_in_bits_ctrl_fpWen                            (in1ToN_io_out_2_bits_fpWen),
    .io_in_bits_ctrl_vecWen                           (in1ToN_io_out_2_bits_vecWen),
    .io_in_bits_ctrl_v0Wen                            (in1ToN_io_out_2_bits_v0Wen),
    .io_in_bits_validPipe_0                           (io_in_valid),
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
    .io_out_valid                                     (f2v_io_out_valid),
    .io_out_bits_ctrl_robIdx_flag                     (f2v_io_out_bits_ctrl_robIdx_flag),
    .io_out_bits_ctrl_robIdx_value                    (f2v_io_out_bits_ctrl_robIdx_value),
    .io_out_bits_ctrl_pdest                           (f2v_io_out_bits_ctrl_pdest),
    .io_out_bits_ctrl_fpWen                           (f2v_io_out_bits_ctrl_fpWen),
    .io_out_bits_ctrl_vecWen                          (f2v_io_out_bits_ctrl_vecWen),
    .io_out_bits_ctrl_v0Wen                           (f2v_io_out_bits_ctrl_v0Wen),
    .io_out_bits_res_data                             (f2v_io_out_bits_res_data),
    .io_out_bits_perfDebugInfo_eliminatedMove         (f2v_io_out_bits_perfDebugInfo_eliminatedMove),
    .io_out_bits_perfDebugInfo_renameTime             (f2v_io_out_bits_perfDebugInfo_renameTime),
    .io_out_bits_perfDebugInfo_dispatchTime           (f2v_io_out_bits_perfDebugInfo_dispatchTime),
    .io_out_bits_perfDebugInfo_enqRsTime              (f2v_io_out_bits_perfDebugInfo_enqRsTime),
    .io_out_bits_perfDebugInfo_selectTime             (f2v_io_out_bits_perfDebugInfo_selectTime),
    .io_out_bits_perfDebugInfo_issueTime              (f2v_io_out_bits_perfDebugInfo_issueTime),
    .io_out_bits_perfDebugInfo_writebackTime          (f2v_io_out_bits_perfDebugInfo_writebackTime),
    .io_out_bits_perfDebugInfo_runahead_checkpoint_id (f2v_io_out_bits_perfDebugInfo_runahead_checkpoint_id),
    .io_out_bits_perfDebugInfo_tlbFirstReqTime        (f2v_io_out_bits_perfDebugInfo_tlbFirstReqTime),
    .io_out_bits_perfDebugInfo_tlbRespTime            (f2v_io_out_bits_perfDebugInfo_tlbRespTime),
    .io_out_bits_debug_seqNum_seqNum                  (f2v_io_out_bits_debug_seqNum_seqNum),
    .io_out_bits_debug_seqNum_uopIdx                  (f2v_io_out_bits_debug_seqNum_uopIdx)
  );
  FMA Fmac (
    .clock                                            (ClockGate_2_Q),
    .reset                                            (reset),
    .io_in_ready                                      (Fmac_io_in_ready),
    .io_in_valid                                      (in1ToN_io_out_3_valid),
    .io_in_bits_ctrl_fuOpType                         (in1ToN_io_out_3_bits_fuOpType),
    .io_in_bits_ctrl_fpu_fmt                          (in1ToN_io_out_3_bits_fpu_fmt),
    .io_in_bits_ctrl_fpu_rm                           (in1ToN_io_out_3_bits_fpu_rm),
    .io_in_bits_ctrlPipe_3_robIdx_flag                (pipe3_robIdx_flag),
    .io_in_bits_ctrlPipe_3_robIdx_value               (pipe3_robIdx_value),
    .io_in_bits_ctrlPipe_3_pdest                      (pipe3_pdest),
    .io_in_bits_ctrlPipe_3_fpWen                      (pipe3_fpWen),
    .io_in_bits_ctrlPipe_3_fpu_wflags                 (pipe3_fpu_wflags),
    .io_in_bits_validPipe_3                           (pipe_valid[3]),
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
    .io_out_valid                                     (Fmac_io_out_valid),
    .io_out_bits_ctrl_robIdx_flag                     (Fmac_io_out_bits_ctrl_robIdx_flag),
    .io_out_bits_ctrl_robIdx_value                    (Fmac_io_out_bits_ctrl_robIdx_value),
    .io_out_bits_ctrl_pdest                           (Fmac_io_out_bits_ctrl_pdest),
    .io_out_bits_ctrl_fpWen                           (Fmac_io_out_bits_ctrl_fpWen),
    .io_out_bits_ctrl_fpu_wflags                      (Fmac_io_out_bits_ctrl_fpu_wflags),
    .io_out_bits_res_data                             (Fmac_io_out_bits_res_data),
    .io_out_bits_res_fflags                           (Fmac_io_out_bits_res_fflags),
    .io_out_bits_perfDebugInfo_eliminatedMove         (Fmac_io_out_bits_perfDebugInfo_eliminatedMove),
    .io_out_bits_perfDebugInfo_renameTime             (Fmac_io_out_bits_perfDebugInfo_renameTime),
    .io_out_bits_perfDebugInfo_dispatchTime           (Fmac_io_out_bits_perfDebugInfo_dispatchTime),
    .io_out_bits_perfDebugInfo_enqRsTime              (Fmac_io_out_bits_perfDebugInfo_enqRsTime),
    .io_out_bits_perfDebugInfo_selectTime             (Fmac_io_out_bits_perfDebugInfo_selectTime),
    .io_out_bits_perfDebugInfo_issueTime              (Fmac_io_out_bits_perfDebugInfo_issueTime),
    .io_out_bits_perfDebugInfo_writebackTime          (Fmac_io_out_bits_perfDebugInfo_writebackTime),
    .io_out_bits_perfDebugInfo_runahead_checkpoint_id (Fmac_io_out_bits_perfDebugInfo_runahead_checkpoint_id),
    .io_out_bits_perfDebugInfo_tlbFirstReqTime        (Fmac_io_out_bits_perfDebugInfo_tlbFirstReqTime),
    .io_out_bits_perfDebugInfo_tlbRespTime            (Fmac_io_out_bits_perfDebugInfo_tlbRespTime),
    .io_out_bits_debug_seqNum_seqNum                  (Fmac_io_out_bits_debug_seqNum_seqNum),
    .io_out_bits_debug_seqNum_uopIdx                  (Fmac_io_out_bits_debug_seqNum_uopIdx),
    .io_frm                                           (io_frm)
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
    .E  (fu_clk_en[3]),
    .CK (clock),
    .Q  (ClockGate_2_Q)
  );

  // ---- 写回：io.out.valid 与各字段的 Mux1H ----
  assign io_out_valid = out_valid;
  assign io_out_bits_data_3 = f2v_io_out_bits_res_data;   // 只有 f2v 产出：单元素 Mux1H 直通
  assign io_out_bits_data_4 = f2v_io_out_bits_res_data;   // 只有 f2v 产出：单元素 Mux1H 直通
  // 第 0 组：Falu, Fcvt, f2v, Fmac 共同产出 —— data_0, data_2, pdest, robIdx_flag, robIdx_value, fpWen, debugInfo_eliminatedMove, debugInfo_renameTime, debugInfo_dispatchTime, debugInfo_enqRsTime, debugInfo_selectTime, debugInfo_issueTime, debugInfo_writebackTime, debugInfo_runahead_checkpoint_id, debugInfo_tlbFirstReqTime, debugInfo_tlbRespTime, debug_seqNum_seqNum, debug_seqNum_uopIdx
  wire [914:0] wb0_out;
  xs_ExeUnit_wbsel #(.N(4), .W(915)) wb0 (
    .sel  ({Fmac_io_out_valid, f2v_io_out_valid, Fcvt_io_out_valid, Falu_io_out_valid}),
    .data ({
      {{64'h0, Fmac_io_out_bits_res_data},
       {64'h0, Fmac_io_out_bits_res_data},
       Fmac_io_out_bits_ctrl_pdest,
       Fmac_io_out_bits_ctrl_robIdx_flag,
       Fmac_io_out_bits_ctrl_robIdx_value,
       Fmac_io_out_bits_ctrl_fpWen,
       Fmac_io_out_bits_perfDebugInfo_eliminatedMove,
       Fmac_io_out_bits_perfDebugInfo_renameTime,
       Fmac_io_out_bits_perfDebugInfo_dispatchTime,
       Fmac_io_out_bits_perfDebugInfo_enqRsTime,
       Fmac_io_out_bits_perfDebugInfo_selectTime,
       Fmac_io_out_bits_perfDebugInfo_issueTime,
       Fmac_io_out_bits_perfDebugInfo_writebackTime,
       Fmac_io_out_bits_perfDebugInfo_runahead_checkpoint_id,
       Fmac_io_out_bits_perfDebugInfo_tlbFirstReqTime,
       Fmac_io_out_bits_perfDebugInfo_tlbRespTime,
       Fmac_io_out_bits_debug_seqNum_seqNum,
       Fmac_io_out_bits_debug_seqNum_uopIdx},
      {f2v_io_out_bits_res_data,
       f2v_io_out_bits_res_data,
       f2v_io_out_bits_ctrl_pdest,
       f2v_io_out_bits_ctrl_robIdx_flag,
       f2v_io_out_bits_ctrl_robIdx_value,
       f2v_io_out_bits_ctrl_fpWen,
       f2v_io_out_bits_perfDebugInfo_eliminatedMove,
       f2v_io_out_bits_perfDebugInfo_renameTime,
       f2v_io_out_bits_perfDebugInfo_dispatchTime,
       f2v_io_out_bits_perfDebugInfo_enqRsTime,
       f2v_io_out_bits_perfDebugInfo_selectTime,
       f2v_io_out_bits_perfDebugInfo_issueTime,
       f2v_io_out_bits_perfDebugInfo_writebackTime,
       f2v_io_out_bits_perfDebugInfo_runahead_checkpoint_id,
       f2v_io_out_bits_perfDebugInfo_tlbFirstReqTime,
       f2v_io_out_bits_perfDebugInfo_tlbRespTime,
       f2v_io_out_bits_debug_seqNum_seqNum,
       f2v_io_out_bits_debug_seqNum_uopIdx},
      {{64'h0, Fcvt_io_out_bits_res_data},
       {64'h0, Fcvt_io_out_bits_res_data},
       Fcvt_io_out_bits_ctrl_pdest,
       Fcvt_io_out_bits_ctrl_robIdx_flag,
       Fcvt_io_out_bits_ctrl_robIdx_value,
       Fcvt_io_out_bits_ctrl_fpWen,
       Fcvt_io_out_bits_perfDebugInfo_eliminatedMove,
       Fcvt_io_out_bits_perfDebugInfo_renameTime,
       Fcvt_io_out_bits_perfDebugInfo_dispatchTime,
       Fcvt_io_out_bits_perfDebugInfo_enqRsTime,
       Fcvt_io_out_bits_perfDebugInfo_selectTime,
       Fcvt_io_out_bits_perfDebugInfo_issueTime,
       Fcvt_io_out_bits_perfDebugInfo_writebackTime,
       Fcvt_io_out_bits_perfDebugInfo_runahead_checkpoint_id,
       Fcvt_io_out_bits_perfDebugInfo_tlbFirstReqTime,
       Fcvt_io_out_bits_perfDebugInfo_tlbRespTime,
       Fcvt_io_out_bits_debug_seqNum_seqNum,
       Fcvt_io_out_bits_debug_seqNum_uopIdx},
      {{64'h0, Falu_io_out_bits_res_data},
       {64'h0, Falu_io_out_bits_res_data},
       Falu_io_out_bits_ctrl_pdest,
       Falu_io_out_bits_ctrl_robIdx_flag,
       Falu_io_out_bits_ctrl_robIdx_value,
       Falu_io_out_bits_ctrl_fpWen,
       Falu_io_out_bits_perfDebugInfo_eliminatedMove,
       Falu_io_out_bits_perfDebugInfo_renameTime,
       Falu_io_out_bits_perfDebugInfo_dispatchTime,
       Falu_io_out_bits_perfDebugInfo_enqRsTime,
       Falu_io_out_bits_perfDebugInfo_selectTime,
       Falu_io_out_bits_perfDebugInfo_issueTime,
       Falu_io_out_bits_perfDebugInfo_writebackTime,
       Falu_io_out_bits_perfDebugInfo_runahead_checkpoint_id,
       Falu_io_out_bits_perfDebugInfo_tlbFirstReqTime,
       Falu_io_out_bits_perfDebugInfo_tlbRespTime,
       Falu_io_out_bits_debug_seqNum_seqNum,
       Falu_io_out_bits_debug_seqNum_uopIdx}
    }),
    .out  (wb0_out)
  );
  assign {
    io_out_bits_data_0,
    io_out_bits_data_2,
    io_out_bits_pdest,
    io_out_bits_robIdx_flag,
    io_out_bits_robIdx_value,
    io_out_bits_fpWen,
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
  // 第 1 组：Falu, Fcvt 共同产出 —— data_1, intWen
  wire [128:0] wb1_out;
  xs_ExeUnit_wbsel #(.N(2), .W(129)) wb1 (
    .sel  ({Fcvt_io_out_valid, Falu_io_out_valid}),
    .data ({
      {{64'h0, Fcvt_io_out_bits_res_data},
       Fcvt_io_out_bits_ctrl_rfWen},
      {{64'h0, Falu_io_out_bits_res_data},
       Falu_io_out_bits_ctrl_rfWen}
    }),
    .out  (wb1_out)
  );
  assign {
    io_out_bits_data_1,
    io_out_bits_intWen
  } = wb1_out;
  // 第 2 组：f2v 共同产出 —— vecWen, v0Wen
  wire [1:0] wb2_out;
  xs_ExeUnit_wbsel #(.N(1), .W(2)) wb2 (
    .sel  ({f2v_io_out_valid}),
    .data ({
      {f2v_io_out_bits_ctrl_vecWen,
       f2v_io_out_bits_ctrl_v0Wen}
    }),
    .out  (wb2_out)
  );
  assign {
    io_out_bits_vecWen,
    io_out_bits_v0Wen
  } = wb2_out;
  // 第 3 组：Falu, Fcvt, Fmac 共同产出 —— fflags, wflags
  wire [5:0] wb3_out;
  xs_ExeUnit_wbsel #(.N(3), .W(6)) wb3 (
    .sel  ({Fmac_io_out_valid, Fcvt_io_out_valid, Falu_io_out_valid}),
    .data ({
      {Fmac_io_out_bits_res_fflags,
       Fmac_io_out_bits_ctrl_fpu_wflags},
      {Fcvt_io_out_bits_res_fflags,
       Fcvt_io_out_bits_ctrl_fpu_wflags},
      {Falu_io_out_bits_res_fflags,
       Falu_io_out_bits_ctrl_fpu_wflags}
    }),
    .out  (wb3_out)
  );
  assign {
    io_out_bits_fflags,
    io_out_bits_wflags
  } = wb3_out;

endmodule
