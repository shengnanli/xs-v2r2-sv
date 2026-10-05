// =============================================================================
// ExeUnit_17 —— 执行单元外壳（golden 同名 wrapper；由 scripts/gen_exeunit.py 从 G1 golden 生成，勿手改）
// -----------------------------------------------------------------------------
// FU（按 Dispatcher 出口序）：Vfdiv(VFDivSqrt, 不定延迟, 门控), Vidiv(VIDiv, 不定延迟, 门控)
// inPipe：0 级；字段 无；含 busy（不定延迟外壳一次只放一条）
// 机制全部在 xs_ExeUnit_core（发射握手 / inPipe 冲刷流水 / 时钟门控使能 / 写回有效）与
//   xs_ExeUnit_wbsel（写回字段 Mux1H）里；本文件只有例化、连线与字段打包。
// 子模块：Dispatcher 与各 FU、ClockGate 均为已签核件（两侧白盒，实例名与 golden 相同）。
// golden 对照：G1-canonical/golden-rtl/ExeUnit_17.sv
// 本文件导航（一个 golden 模块一个文件，不拆；行号由生成器回填）：
//   L90    子模块输出线（名字 = golden 的 _<实例>_<端口> 去掉前导下划线）
//   L193   外壳控制核
//   L238   Dispatcher：按 fuType 把指令派给一个 FU
//   L333   功能单元
//   L462   时钟门控（E 来自核 §3；TE 来自 DFT 的 cg_bore）
//   L476   写回：io.out.valid 与各字段的 Mux1H
// =============================================================================
module ExeUnit_17(
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
  output [6:0]   io_out_bits_pdest,
  output         io_out_bits_robIdx_flag,
  output [7:0]   io_out_bits_robIdx_value,
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
  input          cg_bore_1_cgen
);

  // ---- 子模块输出线（名字 = golden 的 _<实例>_<端口> 去掉前导下划线）----
  wire in1ToN_io_in_ready;
  wire in1ToN_io_out_0_valid;
  wire [8:0] in1ToN_io_out_0_bits_fuOpType;
  wire in1ToN_io_out_0_bits_robIdx_flag;
  wire [7:0] in1ToN_io_out_0_bits_robIdx_value;
  wire [6:0] in1ToN_io_out_0_bits_pdest;
  wire in1ToN_io_out_0_bits_vecWen;
  wire in1ToN_io_out_0_bits_v0Wen;
  wire in1ToN_io_out_0_bits_fpu_wflags;
  wire in1ToN_io_out_0_bits_vpu_vma;
  wire in1ToN_io_out_0_bits_vpu_vta;
  wire [1:0] in1ToN_io_out_0_bits_vpu_vsew;
  wire [2:0] in1ToN_io_out_0_bits_vpu_vlmul;
  wire in1ToN_io_out_0_bits_vpu_vm;
  wire [7:0] in1ToN_io_out_0_bits_vpu_vstart;
  wire [6:0] in1ToN_io_out_0_bits_vpu_vuopIdx;
  wire in1ToN_io_out_0_bits_vpu_isNarrow;
  wire in1ToN_io_out_0_bits_vpu_isDstMask;
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
  wire in1ToN_io_out_1_bits_robIdx_flag;
  wire [7:0] in1ToN_io_out_1_bits_robIdx_value;
  wire [6:0] in1ToN_io_out_1_bits_pdest;
  wire in1ToN_io_out_1_bits_vecWen;
  wire in1ToN_io_out_1_bits_v0Wen;
  wire in1ToN_io_out_1_bits_vpu_vma;
  wire in1ToN_io_out_1_bits_vpu_vta;
  wire [1:0] in1ToN_io_out_1_bits_vpu_vsew;
  wire in1ToN_io_out_1_bits_vpu_vm;
  wire [7:0] in1ToN_io_out_1_bits_vpu_vstart;
  wire [6:0] in1ToN_io_out_1_bits_vpu_vuopIdx;
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
  wire ClockGate_1_Q;
  wire ClockGate_Q;
  wire Vidiv_io_in_ready;
  wire Vidiv_io_out_valid;
  wire Vidiv_io_out_bits_ctrl_robIdx_flag;
  wire [7:0] Vidiv_io_out_bits_ctrl_robIdx_value;
  wire [7:0] Vidiv_io_out_bits_ctrl_pdest;
  wire Vidiv_io_out_bits_ctrl_vecWen;
  wire Vidiv_io_out_bits_ctrl_v0Wen;
  wire [127:0] Vidiv_io_out_bits_res_data;
  wire Vidiv_io_out_bits_perfDebugInfo_eliminatedMove;
  wire [63:0] Vidiv_io_out_bits_perfDebugInfo_renameTime;
  wire [63:0] Vidiv_io_out_bits_perfDebugInfo_dispatchTime;
  wire [63:0] Vidiv_io_out_bits_perfDebugInfo_enqRsTime;
  wire [63:0] Vidiv_io_out_bits_perfDebugInfo_selectTime;
  wire [63:0] Vidiv_io_out_bits_perfDebugInfo_issueTime;
  wire [63:0] Vidiv_io_out_bits_perfDebugInfo_writebackTime;
  wire [63:0] Vidiv_io_out_bits_perfDebugInfo_runahead_checkpoint_id;
  wire [63:0] Vidiv_io_out_bits_perfDebugInfo_tlbFirstReqTime;
  wire [63:0] Vidiv_io_out_bits_perfDebugInfo_tlbRespTime;
  wire [55:0] Vidiv_io_out_bits_debug_seqNum_seqNum;
  wire [7:0] Vidiv_io_out_bits_debug_seqNum_uopIdx;
  wire Vfdiv_io_in_ready;
  wire Vfdiv_io_out_valid;
  wire Vfdiv_io_out_bits_ctrl_robIdx_flag;
  wire [7:0] Vfdiv_io_out_bits_ctrl_robIdx_value;
  wire [7:0] Vfdiv_io_out_bits_ctrl_pdest;
  wire Vfdiv_io_out_bits_ctrl_vecWen;
  wire Vfdiv_io_out_bits_ctrl_v0Wen;
  wire Vfdiv_io_out_bits_ctrl_fpu_wflags;
  wire [127:0] Vfdiv_io_out_bits_res_data;
  wire [4:0] Vfdiv_io_out_bits_res_fflags;
  wire Vfdiv_io_out_bits_perfDebugInfo_eliminatedMove;
  wire [63:0] Vfdiv_io_out_bits_perfDebugInfo_renameTime;
  wire [63:0] Vfdiv_io_out_bits_perfDebugInfo_dispatchTime;
  wire [63:0] Vfdiv_io_out_bits_perfDebugInfo_enqRsTime;
  wire [63:0] Vfdiv_io_out_bits_perfDebugInfo_selectTime;
  wire [63:0] Vfdiv_io_out_bits_perfDebugInfo_issueTime;
  wire [63:0] Vfdiv_io_out_bits_perfDebugInfo_writebackTime;
  wire [63:0] Vfdiv_io_out_bits_perfDebugInfo_runahead_checkpoint_id;
  wire [63:0] Vfdiv_io_out_bits_perfDebugInfo_tlbFirstReqTime;
  wire [63:0] Vfdiv_io_out_bits_perfDebugInfo_tlbRespTime;
  wire [55:0] Vfdiv_io_out_bits_debug_seqNum_seqNum;
  wire [7:0] Vfdiv_io_out_bits_debug_seqNum_uopIdx;

  // ---- 外壳控制核 ----
  localparam int N_FU    = 2;
  localparam int LAT_MAX = 0;
  localparam int PAY_W   = 9;
  wire                     disp_in_valid;
  wire [LAT_MAX:0]         pipe_valid;
  wire [LAT_MAX:0][PAY_W-1:0] pipe_data;
  wire [N_FU-1:0]          fu_clk_en;
  wire [0:0][4:0]        att_q;
  wire                     out_valid;
  xs_ExeUnit_core #(
    .N_FU         (N_FU),
    .FU_LAT       ('{0, 0}),
    .FU_UNCERTAIN ('{1, 1}),
    .HAS_BUSY     (1'b1),
    .LAT_MAX      (LAT_MAX),
    .NF           (1),
    .FIELD_W      ('{9}),
    .FIELD_DEPTH  ('{0}),
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
    .in_payload      ({io_in_bits_robIdx_flag, io_in_bits_robIdx_value}),
    .disp_in_valid   (disp_in_valid),
    .disp_in_ready   (in1ToN_io_in_ready),
    .pipe_valid      (pipe_valid),
    .pipe_data       (pipe_data),
    .fu_in_valid     ({in1ToN_io_out_1_valid, in1ToN_io_out_0_valid}),
    .fu_in_ready     ({Vidiv_io_in_ready, Vfdiv_io_in_ready}),
    .fu_out_valid    ({Vidiv_io_out_valid, Vfdiv_io_out_valid}),
    .out_ready       (io_out_ready),
    .fu_clk_en       (fu_clk_en),
    .att_in          (5'h0),
    .att_q           (att_q),
    .out_valid       (out_valid)
  );

  // ---- Dispatcher：按 fuType 把指令派给一个 FU ----
  Dispatcher_17 in1ToN (
    .clock                                              (clock),
    .reset                                              (reset),
    .io_in_ready                                        (in1ToN_io_in_ready),
    .io_in_valid                                        (disp_in_valid),
    .io_in_bits_fuType                                  (io_in_bits_fuType),
    .io_in_bits_fuOpType                                (io_in_bits_fuOpType),
    .io_in_bits_robIdx_flag                             (io_in_bits_robIdx_flag),
    .io_in_bits_robIdx_value                            (io_in_bits_robIdx_value),
    .io_in_bits_pdest                                   (io_in_bits_pdest),
    .io_in_bits_vecWen                                  (io_in_bits_vecWen),
    .io_in_bits_v0Wen                                   (io_in_bits_v0Wen),
    .io_in_bits_fpu_wflags                              (io_in_bits_fpu_wflags),
    .io_in_bits_vpu_vma                                 (io_in_bits_vpu_vma),
    .io_in_bits_vpu_vta                                 (io_in_bits_vpu_vta),
    .io_in_bits_vpu_vsew                                (io_in_bits_vpu_vsew),
    .io_in_bits_vpu_vlmul                               (io_in_bits_vpu_vlmul),
    .io_in_bits_vpu_vm                                  (io_in_bits_vpu_vm),
    .io_in_bits_vpu_vstart                              (io_in_bits_vpu_vstart),
    .io_in_bits_vpu_vuopIdx                             (io_in_bits_vpu_vuopIdx),
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
    .io_out_0_ready                                     (Vfdiv_io_in_ready),
    .io_out_0_valid                                     (in1ToN_io_out_0_valid),
    .io_out_0_bits_fuOpType                             (in1ToN_io_out_0_bits_fuOpType),
    .io_out_0_bits_robIdx_flag                          (in1ToN_io_out_0_bits_robIdx_flag),
    .io_out_0_bits_robIdx_value                         (in1ToN_io_out_0_bits_robIdx_value),
    .io_out_0_bits_pdest                                (in1ToN_io_out_0_bits_pdest),
    .io_out_0_bits_vecWen                               (in1ToN_io_out_0_bits_vecWen),
    .io_out_0_bits_v0Wen                                (in1ToN_io_out_0_bits_v0Wen),
    .io_out_0_bits_fpu_wflags                           (in1ToN_io_out_0_bits_fpu_wflags),
    .io_out_0_bits_vpu_vma                              (in1ToN_io_out_0_bits_vpu_vma),
    .io_out_0_bits_vpu_vta                              (in1ToN_io_out_0_bits_vpu_vta),
    .io_out_0_bits_vpu_vsew                             (in1ToN_io_out_0_bits_vpu_vsew),
    .io_out_0_bits_vpu_vlmul                            (in1ToN_io_out_0_bits_vpu_vlmul),
    .io_out_0_bits_vpu_vm                               (in1ToN_io_out_0_bits_vpu_vm),
    .io_out_0_bits_vpu_vstart                           (in1ToN_io_out_0_bits_vpu_vstart),
    .io_out_0_bits_vpu_vuopIdx                          (in1ToN_io_out_0_bits_vpu_vuopIdx),
    .io_out_0_bits_vpu_isNarrow                         (in1ToN_io_out_0_bits_vpu_isNarrow),
    .io_out_0_bits_vpu_isDstMask                        (in1ToN_io_out_0_bits_vpu_isDstMask),
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
    .io_out_1_ready                                     (Vidiv_io_in_ready),
    .io_out_1_valid                                     (in1ToN_io_out_1_valid),
    .io_out_1_bits_fuOpType                             (in1ToN_io_out_1_bits_fuOpType),
    .io_out_1_bits_robIdx_flag                          (in1ToN_io_out_1_bits_robIdx_flag),
    .io_out_1_bits_robIdx_value                         (in1ToN_io_out_1_bits_robIdx_value),
    .io_out_1_bits_pdest                                (in1ToN_io_out_1_bits_pdest),
    .io_out_1_bits_vecWen                               (in1ToN_io_out_1_bits_vecWen),
    .io_out_1_bits_v0Wen                                (in1ToN_io_out_1_bits_v0Wen),
    .io_out_1_bits_vpu_vma                              (in1ToN_io_out_1_bits_vpu_vma),
    .io_out_1_bits_vpu_vta                              (in1ToN_io_out_1_bits_vpu_vta),
    .io_out_1_bits_vpu_vsew                             (in1ToN_io_out_1_bits_vpu_vsew),
    .io_out_1_bits_vpu_vm                               (in1ToN_io_out_1_bits_vpu_vm),
    .io_out_1_bits_vpu_vstart                           (in1ToN_io_out_1_bits_vpu_vstart),
    .io_out_1_bits_vpu_vuopIdx                          (in1ToN_io_out_1_bits_vpu_vuopIdx),
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
    .io_out_1_bits_debug_seqNum_uopIdx                  (in1ToN_io_out_1_bits_debug_seqNum_uopIdx)
  );

  // ---- 功能单元 ----
  VFDivSqrt Vfdiv (
    .clock                                            (ClockGate_Q),
    .reset                                            (reset),
    .io_flush_valid                                   (io_flush_valid),
    .io_flush_bits_robIdx_flag                        (io_flush_bits_robIdx_flag),
    .io_flush_bits_robIdx_value                       (io_flush_bits_robIdx_value),
    .io_flush_bits_level                              (io_flush_bits_level),
    .io_in_ready                                      (Vfdiv_io_in_ready),
    .io_in_valid                                      (in1ToN_io_out_0_valid),
    .io_in_bits_ctrl_fuOpType                         (in1ToN_io_out_0_bits_fuOpType),
    .io_in_bits_ctrl_robIdx_flag                      (in1ToN_io_out_0_bits_robIdx_flag),
    .io_in_bits_ctrl_robIdx_value                     (in1ToN_io_out_0_bits_robIdx_value),
    .io_in_bits_ctrl_pdest                            ({1'h0, in1ToN_io_out_0_bits_pdest}),
    .io_in_bits_ctrl_vecWen                           (in1ToN_io_out_0_bits_vecWen),
    .io_in_bits_ctrl_v0Wen                            (in1ToN_io_out_0_bits_v0Wen),
    .io_in_bits_ctrl_fpu_wflags                       (in1ToN_io_out_0_bits_fpu_wflags),
    .io_in_bits_ctrl_vpu_vma                          (in1ToN_io_out_0_bits_vpu_vma),
    .io_in_bits_ctrl_vpu_vta                          (in1ToN_io_out_0_bits_vpu_vta),
    .io_in_bits_ctrl_vpu_vsew                         (in1ToN_io_out_0_bits_vpu_vsew),
    .io_in_bits_ctrl_vpu_vlmul                        (in1ToN_io_out_0_bits_vpu_vlmul),
    .io_in_bits_ctrl_vpu_vm                           (in1ToN_io_out_0_bits_vpu_vm),
    .io_in_bits_ctrl_vpu_vstart                       (in1ToN_io_out_0_bits_vpu_vstart),
    .io_in_bits_ctrl_vpu_vuopIdx                      (in1ToN_io_out_0_bits_vpu_vuopIdx),
    .io_in_bits_ctrl_vpu_isNarrow                     (in1ToN_io_out_0_bits_vpu_isNarrow),
    .io_in_bits_ctrl_vpu_isDstMask                    (in1ToN_io_out_0_bits_vpu_isDstMask),
    .io_in_bits_data_src_4                            (io_in_bits_src_4[7:0]),
    .io_in_bits_data_src_3                            (io_in_bits_src_3),
    .io_in_bits_data_src_2                            (io_in_bits_src_2),
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
    .io_out_valid                                     (Vfdiv_io_out_valid),
    .io_out_bits_ctrl_robIdx_flag                     (Vfdiv_io_out_bits_ctrl_robIdx_flag),
    .io_out_bits_ctrl_robIdx_value                    (Vfdiv_io_out_bits_ctrl_robIdx_value),
    .io_out_bits_ctrl_pdest                           (Vfdiv_io_out_bits_ctrl_pdest),
    .io_out_bits_ctrl_vecWen                          (Vfdiv_io_out_bits_ctrl_vecWen),
    .io_out_bits_ctrl_v0Wen                           (Vfdiv_io_out_bits_ctrl_v0Wen),
    .io_out_bits_ctrl_fpu_wflags                      (Vfdiv_io_out_bits_ctrl_fpu_wflags),
    .io_out_bits_res_data                             (Vfdiv_io_out_bits_res_data),
    .io_out_bits_res_fflags                           (Vfdiv_io_out_bits_res_fflags),
    .io_out_bits_perfDebugInfo_eliminatedMove         (Vfdiv_io_out_bits_perfDebugInfo_eliminatedMove),
    .io_out_bits_perfDebugInfo_renameTime             (Vfdiv_io_out_bits_perfDebugInfo_renameTime),
    .io_out_bits_perfDebugInfo_dispatchTime           (Vfdiv_io_out_bits_perfDebugInfo_dispatchTime),
    .io_out_bits_perfDebugInfo_enqRsTime              (Vfdiv_io_out_bits_perfDebugInfo_enqRsTime),
    .io_out_bits_perfDebugInfo_selectTime             (Vfdiv_io_out_bits_perfDebugInfo_selectTime),
    .io_out_bits_perfDebugInfo_issueTime              (Vfdiv_io_out_bits_perfDebugInfo_issueTime),
    .io_out_bits_perfDebugInfo_writebackTime          (Vfdiv_io_out_bits_perfDebugInfo_writebackTime),
    .io_out_bits_perfDebugInfo_runahead_checkpoint_id (Vfdiv_io_out_bits_perfDebugInfo_runahead_checkpoint_id),
    .io_out_bits_perfDebugInfo_tlbFirstReqTime        (Vfdiv_io_out_bits_perfDebugInfo_tlbFirstReqTime),
    .io_out_bits_perfDebugInfo_tlbRespTime            (Vfdiv_io_out_bits_perfDebugInfo_tlbRespTime),
    .io_out_bits_debug_seqNum_seqNum                  (Vfdiv_io_out_bits_debug_seqNum_seqNum),
    .io_out_bits_debug_seqNum_uopIdx                  (Vfdiv_io_out_bits_debug_seqNum_uopIdx),
    .io_frm                                           (io_frm)
  );
  VIDiv Vidiv (
    .clock                                            (ClockGate_1_Q),
    .reset                                            (reset),
    .io_flush_valid                                   (io_flush_valid),
    .io_flush_bits_robIdx_flag                        (io_flush_bits_robIdx_flag),
    .io_flush_bits_robIdx_value                       (io_flush_bits_robIdx_value),
    .io_flush_bits_level                              (io_flush_bits_level),
    .io_in_ready                                      (Vidiv_io_in_ready),
    .io_in_valid                                      (in1ToN_io_out_1_valid),
    .io_in_bits_ctrl_fuOpType                         (in1ToN_io_out_1_bits_fuOpType),
    .io_in_bits_ctrl_robIdx_flag                      (in1ToN_io_out_1_bits_robIdx_flag),
    .io_in_bits_ctrl_robIdx_value                     (in1ToN_io_out_1_bits_robIdx_value),
    .io_in_bits_ctrl_pdest                            ({1'h0, in1ToN_io_out_1_bits_pdest}),
    .io_in_bits_ctrl_vecWen                           (in1ToN_io_out_1_bits_vecWen),
    .io_in_bits_ctrl_v0Wen                            (in1ToN_io_out_1_bits_v0Wen),
    .io_in_bits_ctrl_vpu_vma                          (in1ToN_io_out_1_bits_vpu_vma),
    .io_in_bits_ctrl_vpu_vta                          (in1ToN_io_out_1_bits_vpu_vta),
    .io_in_bits_ctrl_vpu_vsew                         (in1ToN_io_out_1_bits_vpu_vsew),
    .io_in_bits_ctrl_vpu_vm                           (in1ToN_io_out_1_bits_vpu_vm),
    .io_in_bits_ctrl_vpu_vstart                       (in1ToN_io_out_1_bits_vpu_vstart),
    .io_in_bits_ctrl_vpu_vuopIdx                      (in1ToN_io_out_1_bits_vpu_vuopIdx),
    .io_in_bits_ctrl_vpu_isNarrow                     (in1ToN_io_out_1_bits_vpu_isNarrow),
    .io_in_bits_ctrl_vpu_isDstMask                    (in1ToN_io_out_1_bits_vpu_isDstMask),
    .io_in_bits_data_src_4                            (io_in_bits_src_4[7:0]),
    .io_in_bits_data_src_3                            (io_in_bits_src_3),
    .io_in_bits_data_src_2                            (io_in_bits_src_2),
    .io_in_bits_data_src_1                            (io_in_bits_src_1),
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
    .io_out_valid                                     (Vidiv_io_out_valid),
    .io_out_bits_ctrl_robIdx_flag                     (Vidiv_io_out_bits_ctrl_robIdx_flag),
    .io_out_bits_ctrl_robIdx_value                    (Vidiv_io_out_bits_ctrl_robIdx_value),
    .io_out_bits_ctrl_pdest                           (Vidiv_io_out_bits_ctrl_pdest),
    .io_out_bits_ctrl_vecWen                          (Vidiv_io_out_bits_ctrl_vecWen),
    .io_out_bits_ctrl_v0Wen                           (Vidiv_io_out_bits_ctrl_v0Wen),
    .io_out_bits_res_data                             (Vidiv_io_out_bits_res_data),
    .io_out_bits_perfDebugInfo_eliminatedMove         (Vidiv_io_out_bits_perfDebugInfo_eliminatedMove),
    .io_out_bits_perfDebugInfo_renameTime             (Vidiv_io_out_bits_perfDebugInfo_renameTime),
    .io_out_bits_perfDebugInfo_dispatchTime           (Vidiv_io_out_bits_perfDebugInfo_dispatchTime),
    .io_out_bits_perfDebugInfo_enqRsTime              (Vidiv_io_out_bits_perfDebugInfo_enqRsTime),
    .io_out_bits_perfDebugInfo_selectTime             (Vidiv_io_out_bits_perfDebugInfo_selectTime),
    .io_out_bits_perfDebugInfo_issueTime              (Vidiv_io_out_bits_perfDebugInfo_issueTime),
    .io_out_bits_perfDebugInfo_writebackTime          (Vidiv_io_out_bits_perfDebugInfo_writebackTime),
    .io_out_bits_perfDebugInfo_runahead_checkpoint_id (Vidiv_io_out_bits_perfDebugInfo_runahead_checkpoint_id),
    .io_out_bits_perfDebugInfo_tlbFirstReqTime        (Vidiv_io_out_bits_perfDebugInfo_tlbFirstReqTime),
    .io_out_bits_perfDebugInfo_tlbRespTime            (Vidiv_io_out_bits_perfDebugInfo_tlbRespTime),
    .io_out_bits_debug_seqNum_seqNum                  (Vidiv_io_out_bits_debug_seqNum_seqNum),
    .io_out_bits_debug_seqNum_uopIdx                  (Vidiv_io_out_bits_debug_seqNum_uopIdx)
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

  // ---- 写回：io.out.valid 与各字段的 Mux1H ----
  assign io_out_valid = out_valid;
  // 第 0 组：Vfdiv, Vidiv 共同产出 —— data_0, data_1, data_2, pdest, robIdx_flag, robIdx_value, vecWen, v0Wen, debugInfo_eliminatedMove, debugInfo_renameTime, debugInfo_dispatchTime, debugInfo_enqRsTime, debugInfo_selectTime, debugInfo_issueTime, debugInfo_writebackTime, debugInfo_runahead_checkpoint_id, debugInfo_tlbFirstReqTime, debugInfo_tlbRespTime, debug_seqNum_seqNum, debug_seqNum_uopIdx
  wire [1042:0] wb0_out;
  xs_ExeUnit_wbsel #(.N(2), .W(1043)) wb0 (
    .sel  ({Vidiv_io_out_valid, Vfdiv_io_out_valid}),
    .data ({
      {Vidiv_io_out_bits_res_data,
       Vidiv_io_out_bits_res_data,
       Vidiv_io_out_bits_res_data,
       Vidiv_io_out_bits_ctrl_pdest[6:0],
       Vidiv_io_out_bits_ctrl_robIdx_flag,
       Vidiv_io_out_bits_ctrl_robIdx_value,
       Vidiv_io_out_bits_ctrl_vecWen,
       Vidiv_io_out_bits_ctrl_v0Wen,
       Vidiv_io_out_bits_perfDebugInfo_eliminatedMove,
       Vidiv_io_out_bits_perfDebugInfo_renameTime,
       Vidiv_io_out_bits_perfDebugInfo_dispatchTime,
       Vidiv_io_out_bits_perfDebugInfo_enqRsTime,
       Vidiv_io_out_bits_perfDebugInfo_selectTime,
       Vidiv_io_out_bits_perfDebugInfo_issueTime,
       Vidiv_io_out_bits_perfDebugInfo_writebackTime,
       Vidiv_io_out_bits_perfDebugInfo_runahead_checkpoint_id,
       Vidiv_io_out_bits_perfDebugInfo_tlbFirstReqTime,
       Vidiv_io_out_bits_perfDebugInfo_tlbRespTime,
       Vidiv_io_out_bits_debug_seqNum_seqNum,
       Vidiv_io_out_bits_debug_seqNum_uopIdx},
      {Vfdiv_io_out_bits_res_data,
       Vfdiv_io_out_bits_res_data,
       Vfdiv_io_out_bits_res_data,
       Vfdiv_io_out_bits_ctrl_pdest[6:0],
       Vfdiv_io_out_bits_ctrl_robIdx_flag,
       Vfdiv_io_out_bits_ctrl_robIdx_value,
       Vfdiv_io_out_bits_ctrl_vecWen,
       Vfdiv_io_out_bits_ctrl_v0Wen,
       Vfdiv_io_out_bits_perfDebugInfo_eliminatedMove,
       Vfdiv_io_out_bits_perfDebugInfo_renameTime,
       Vfdiv_io_out_bits_perfDebugInfo_dispatchTime,
       Vfdiv_io_out_bits_perfDebugInfo_enqRsTime,
       Vfdiv_io_out_bits_perfDebugInfo_selectTime,
       Vfdiv_io_out_bits_perfDebugInfo_issueTime,
       Vfdiv_io_out_bits_perfDebugInfo_writebackTime,
       Vfdiv_io_out_bits_perfDebugInfo_runahead_checkpoint_id,
       Vfdiv_io_out_bits_perfDebugInfo_tlbFirstReqTime,
       Vfdiv_io_out_bits_perfDebugInfo_tlbRespTime,
       Vfdiv_io_out_bits_debug_seqNum_seqNum,
       Vfdiv_io_out_bits_debug_seqNum_uopIdx}
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
  // 第 1 组：Vfdiv 共同产出 —— fflags, wflags
  wire [5:0] wb1_out;
  xs_ExeUnit_wbsel #(.N(1), .W(6)) wb1 (
    .sel  ({Vfdiv_io_out_valid}),
    .data ({
      {Vfdiv_io_out_bits_res_fflags,
       Vfdiv_io_out_bits_ctrl_fpu_wflags}
    }),
    .out  (wb1_out)
  );
  assign {
    io_out_bits_fflags,
    io_out_bits_wflags
  } = wb1_out;

endmodule
