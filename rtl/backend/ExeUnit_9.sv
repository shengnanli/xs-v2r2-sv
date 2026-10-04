// =============================================================================
// ExeUnit_9 —— 执行单元外壳（golden 同名 wrapper；由 scripts/gen_exeunit.py 从 G1 golden 生成，勿手改）
// -----------------------------------------------------------------------------
// FU（按 Dispatcher 出口序）：Fdiv(FDivSqrt, 不定延迟, 门控)
// inPipe：0 级；字段 无；含 busy（不定延迟外壳一次只放一条）
// 机制全部在 xs_ExeUnit_core（发射握手 / inPipe 冲刷流水 / 时钟门控使能 / 写回有效）与
//   xs_ExeUnit_wbsel（写回字段 Mux1H）里；本文件只有例化、连线与字段打包。
// 子模块：Dispatcher 与各 FU、ClockGate 均为已签核件（两侧白盒，实例名与 golden 相同）。
// golden 对照：G1-canonical/golden-rtl/ExeUnit_9.sv
// 本文件导航（一个 golden 模块一个文件，不拆；行号由生成器回填）：
//   L76    子模块输出线（名字 = golden 的 _<实例>_<端口> 去掉前导下划线）
//   L104   外壳控制核
//   L149   Dispatcher：按 fuType 把指令派给一个 FU
//   L200   功能单元
//   L256   时钟门控（E 来自核 §3；TE 来自 DFT 的 cg_bore）
//   L264   写回：io.out.valid 与各字段的 Mux1H
// =============================================================================
module ExeUnit_9(
  input         clock,
  input         reset,
  input         io_flush_valid,
  input         io_flush_bits_robIdx_flag,
  input  [7:0]  io_flush_bits_robIdx_value,
  input         io_flush_bits_level,
  output        io_in_ready,
  input         io_in_valid,
  input  [34:0] io_in_bits_fuType,
  input  [8:0]  io_in_bits_fuOpType,
  input  [63:0] io_in_bits_src_0,
  input  [63:0] io_in_bits_src_1,
  input         io_in_bits_robIdx_flag,
  input  [7:0]  io_in_bits_robIdx_value,
  input  [7:0]  io_in_bits_pdest,
  input         io_in_bits_fpWen,
  input         io_in_bits_fpu_wflags,
  input  [1:0]  io_in_bits_fpu_fmt,
  input  [2:0]  io_in_bits_fpu_rm,
  input         io_in_bits_perfDebugInfo_eliminatedMove,
  input  [63:0] io_in_bits_perfDebugInfo_renameTime,
  input  [63:0] io_in_bits_perfDebugInfo_dispatchTime,
  input  [63:0] io_in_bits_perfDebugInfo_enqRsTime,
  input  [63:0] io_in_bits_perfDebugInfo_selectTime,
  input  [63:0] io_in_bits_perfDebugInfo_issueTime,
  input  [63:0] io_in_bits_perfDebugInfo_writebackTime,
  input  [63:0] io_in_bits_perfDebugInfo_runahead_checkpoint_id,
  input  [63:0] io_in_bits_perfDebugInfo_tlbFirstReqTime,
  input  [63:0] io_in_bits_perfDebugInfo_tlbRespTime,
  input  [55:0] io_in_bits_debug_seqNum_seqNum,
  input  [7:0]  io_in_bits_debug_seqNum_uopIdx,
  input         io_out_ready,
  output        io_out_valid,
  output [63:0] io_out_bits_data_0,
  output [63:0] io_out_bits_data_1,
  output [7:0]  io_out_bits_pdest,
  output        io_out_bits_robIdx_flag,
  output [7:0]  io_out_bits_robIdx_value,
  output        io_out_bits_fpWen,
  output [4:0]  io_out_bits_fflags,
  output        io_out_bits_wflags,
  output        io_out_bits_debugInfo_eliminatedMove,
  output [63:0] io_out_bits_debugInfo_renameTime,
  output [63:0] io_out_bits_debugInfo_dispatchTime,
  output [63:0] io_out_bits_debugInfo_enqRsTime,
  output [63:0] io_out_bits_debugInfo_selectTime,
  output [63:0] io_out_bits_debugInfo_issueTime,
  output [63:0] io_out_bits_debugInfo_writebackTime,
  output [63:0] io_out_bits_debugInfo_runahead_checkpoint_id,
  output [63:0] io_out_bits_debugInfo_tlbFirstReqTime,
  output [63:0] io_out_bits_debugInfo_tlbRespTime,
  output [55:0] io_out_bits_debug_seqNum_seqNum,
  output [7:0]  io_out_bits_debug_seqNum_uopIdx,
  input  [2:0]  io_frm,
  input         cg_bore_cgen
);

  // ---- 子模块输出线（名字 = golden 的 _<实例>_<端口> 去掉前导下划线）----
  wire in1ToN_io_in_ready;
  wire in1ToN_io_out_0_valid;
  wire [8:0] in1ToN_io_out_0_bits_fuOpType;
  wire in1ToN_io_out_0_bits_robIdx_flag;
  wire [7:0] in1ToN_io_out_0_bits_robIdx_value;
  wire [7:0] in1ToN_io_out_0_bits_pdest;
  wire in1ToN_io_out_0_bits_fpWen;
  wire in1ToN_io_out_0_bits_fpu_wflags;
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
  wire ClockGate_Q;
  wire Fdiv_io_in_ready;
  wire Fdiv_io_out_valid;
  wire [63:0] Fdiv_io_out_bits_res_data;

  // ---- 外壳控制核 ----
  localparam int N_FU    = 1;
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
    .FU_LAT       ('{0}),
    .FU_UNCERTAIN ('{1}),
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
    .fu_in_valid     ({in1ToN_io_out_0_valid}),
    .fu_in_ready     ({Fdiv_io_in_ready}),
    .fu_out_valid    ({Fdiv_io_out_valid}),
    .out_ready       (io_out_ready),
    .fu_clk_en       (fu_clk_en),
    .att_in          (5'h0),
    .att_q           (att_q),
    .out_valid       (out_valid)
  );

  // ---- Dispatcher：按 fuType 把指令派给一个 FU ----
  Dispatcher_9 in1ToN (
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
    .io_in_bits_fpu_wflags                              (io_in_bits_fpu_wflags),
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
    .io_out_0_ready                                     (Fdiv_io_in_ready),
    .io_out_0_valid                                     (in1ToN_io_out_0_valid),
    .io_out_0_bits_fuOpType                             (in1ToN_io_out_0_bits_fuOpType),
    .io_out_0_bits_robIdx_flag                          (in1ToN_io_out_0_bits_robIdx_flag),
    .io_out_0_bits_robIdx_value                         (in1ToN_io_out_0_bits_robIdx_value),
    .io_out_0_bits_pdest                                (in1ToN_io_out_0_bits_pdest),
    .io_out_0_bits_fpWen                                (in1ToN_io_out_0_bits_fpWen),
    .io_out_0_bits_fpu_wflags                           (in1ToN_io_out_0_bits_fpu_wflags),
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
    .io_out_0_bits_debug_seqNum_uopIdx                  (in1ToN_io_out_0_bits_debug_seqNum_uopIdx)
  );

  // ---- 功能单元 ----
  FDivSqrt Fdiv (
    .clock                                            (ClockGate_Q),
    .reset                                            (reset),
    .io_flush_valid                                   (io_flush_valid),
    .io_flush_bits_robIdx_flag                        (io_flush_bits_robIdx_flag),
    .io_flush_bits_robIdx_value                       (io_flush_bits_robIdx_value),
    .io_flush_bits_level                              (io_flush_bits_level),
    .io_in_ready                                      (Fdiv_io_in_ready),
    .io_in_valid                                      (in1ToN_io_out_0_valid),
    .io_in_bits_ctrl_fuOpType                         (in1ToN_io_out_0_bits_fuOpType),
    .io_in_bits_ctrl_robIdx_flag                      (in1ToN_io_out_0_bits_robIdx_flag),
    .io_in_bits_ctrl_robIdx_value                     (in1ToN_io_out_0_bits_robIdx_value),
    .io_in_bits_ctrl_pdest                            (in1ToN_io_out_0_bits_pdest),
    .io_in_bits_ctrl_fpWen                            (in1ToN_io_out_0_bits_fpWen),
    .io_in_bits_ctrl_fpu_wflags                       (in1ToN_io_out_0_bits_fpu_wflags),
    .io_in_bits_ctrl_fpu_fmt                          (in1ToN_io_out_0_bits_fpu_fmt),
    .io_in_bits_ctrl_fpu_rm                           (in1ToN_io_out_0_bits_fpu_rm),
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
    .io_out_valid                                     (Fdiv_io_out_valid),
    .io_out_bits_ctrl_robIdx_flag                     (io_out_bits_robIdx_flag),
    .io_out_bits_ctrl_robIdx_value                    (io_out_bits_robIdx_value),
    .io_out_bits_ctrl_pdest                           (io_out_bits_pdest),
    .io_out_bits_ctrl_fpWen                           (io_out_bits_fpWen),
    .io_out_bits_ctrl_fpu_wflags                      (io_out_bits_wflags),
    .io_out_bits_res_data                             (Fdiv_io_out_bits_res_data),
    .io_out_bits_res_fflags                           (io_out_bits_fflags),
    .io_out_bits_perfDebugInfo_eliminatedMove         (io_out_bits_debugInfo_eliminatedMove),
    .io_out_bits_perfDebugInfo_renameTime             (io_out_bits_debugInfo_renameTime),
    .io_out_bits_perfDebugInfo_dispatchTime           (io_out_bits_debugInfo_dispatchTime),
    .io_out_bits_perfDebugInfo_enqRsTime              (io_out_bits_debugInfo_enqRsTime),
    .io_out_bits_perfDebugInfo_selectTime             (io_out_bits_debugInfo_selectTime),
    .io_out_bits_perfDebugInfo_issueTime              (io_out_bits_debugInfo_issueTime),
    .io_out_bits_perfDebugInfo_writebackTime          (io_out_bits_debugInfo_writebackTime),
    .io_out_bits_perfDebugInfo_runahead_checkpoint_id (io_out_bits_debugInfo_runahead_checkpoint_id),
    .io_out_bits_perfDebugInfo_tlbFirstReqTime        (io_out_bits_debugInfo_tlbFirstReqTime),
    .io_out_bits_perfDebugInfo_tlbRespTime            (io_out_bits_debugInfo_tlbRespTime),
    .io_out_bits_debug_seqNum_seqNum                  (io_out_bits_debug_seqNum_seqNum),
    .io_out_bits_debug_seqNum_uopIdx                  (io_out_bits_debug_seqNum_uopIdx),
    .io_frm                                           (io_frm)
  );

  // ---- 时钟门控（E 来自核 §3；TE 来自 DFT 的 cg_bore）----
  ClockGate ClockGate (
    .TE (cg_bore_cgen),
    .E  (fu_clk_en[0]),
    .CK (clock),
    .Q  (ClockGate_Q)
  );

  // ---- 写回：io.out.valid 与各字段的 Mux1H ----
  assign io_out_valid = out_valid;
  assign io_out_bits_data_0 = Fdiv_io_out_bits_res_data;   // 只有 Fdiv 产出：单元素 Mux1H 直通
  assign io_out_bits_data_1 = Fdiv_io_out_bits_res_data;   // 只有 Fdiv 产出：单元素 Mux1H 直通

endmodule
