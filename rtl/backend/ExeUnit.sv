// =============================================================================
// ExeUnit —— 执行单元外壳（golden 同名 wrapper；由 scripts/gen_exeunit.py 从 G1 golden 生成，勿手改）
// -----------------------------------------------------------------------------
// FU（按 Dispatcher 出口序）：Alu(Alu, 延迟 0), Mul(MulUnit, 延迟 2, 门控), Bku(Bku, 延迟 2, 门控)
// inPipe：2 级；字段 robIdx[9]×2级, pdest[8]×2级, rfWen[1]×2级
// 机制全部在 xs_ExeUnit_core（发射握手 / inPipe 冲刷流水 / 时钟门控使能 / 写回有效）与
//   xs_ExeUnit_wbsel（写回字段 Mux1H）里；本文件只有例化、连线与字段打包。
// 子模块：Dispatcher 与各 FU、ClockGate 均为已签核件（两侧白盒，实例名与 golden 相同）。
// golden 对照：G1-canonical/golden-rtl/ExeUnit.sv
// 本文件导航（一个 golden 模块一个文件，不拆；行号由生成器回填）：
//   L72    子模块输出线（名字 = golden 的 _<实例>_<端口> 去掉前导下划线）
//   L176   外壳控制核
//   L221   inPipe 第 s 级字段拆包（只拆有 FU 读的那些）
//   L227   Dispatcher：按 fuType 把指令派给一个 FU
//   L294   功能单元
//   L432   时钟门控（E 来自核 §3；TE 来自 DFT 的 cg_bore）
//   L446   写回：io.out.valid 与各字段的 Mux1H
// =============================================================================
module ExeUnit(
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
  input         io_in_bits_rfWen,
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
  output        io_out_bits_intWen,
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
  input         cg_bore_cgen,
  input         cg_bore_1_cgen
);

  // ---- 子模块输出线（名字 = golden 的 _<实例>_<端口> 去掉前导下划线）----
  wire in1ToN_io_out_0_valid;
  wire [8:0] in1ToN_io_out_0_bits_fuOpType;
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
  wire ClockGate_1_Q;
  wire ClockGate_Q;
  wire Bku_io_in_ready;
  wire Bku_io_out_valid;
  wire Bku_io_out_bits_ctrl_robIdx_flag;
  wire [7:0] Bku_io_out_bits_ctrl_robIdx_value;
  wire [7:0] Bku_io_out_bits_ctrl_pdest;
  wire Bku_io_out_bits_ctrl_rfWen;
  wire [63:0] Bku_io_out_bits_res_data;
  wire Bku_io_out_bits_perfDebugInfo_eliminatedMove;
  wire [63:0] Bku_io_out_bits_perfDebugInfo_renameTime;
  wire [63:0] Bku_io_out_bits_perfDebugInfo_dispatchTime;
  wire [63:0] Bku_io_out_bits_perfDebugInfo_enqRsTime;
  wire [63:0] Bku_io_out_bits_perfDebugInfo_selectTime;
  wire [63:0] Bku_io_out_bits_perfDebugInfo_issueTime;
  wire [63:0] Bku_io_out_bits_perfDebugInfo_writebackTime;
  wire [63:0] Bku_io_out_bits_perfDebugInfo_runahead_checkpoint_id;
  wire [63:0] Bku_io_out_bits_perfDebugInfo_tlbFirstReqTime;
  wire [63:0] Bku_io_out_bits_perfDebugInfo_tlbRespTime;
  wire [55:0] Bku_io_out_bits_debug_seqNum_seqNum;
  wire [7:0] Bku_io_out_bits_debug_seqNum_uopIdx;
  wire Mul_io_in_ready;
  wire Mul_io_out_valid;
  wire Mul_io_out_bits_ctrl_robIdx_flag;
  wire [7:0] Mul_io_out_bits_ctrl_robIdx_value;
  wire [7:0] Mul_io_out_bits_ctrl_pdest;
  wire Mul_io_out_bits_ctrl_rfWen;
  wire [63:0] Mul_io_out_bits_res_data;
  wire Mul_io_out_bits_perfDebugInfo_eliminatedMove;
  wire [63:0] Mul_io_out_bits_perfDebugInfo_renameTime;
  wire [63:0] Mul_io_out_bits_perfDebugInfo_dispatchTime;
  wire [63:0] Mul_io_out_bits_perfDebugInfo_enqRsTime;
  wire [63:0] Mul_io_out_bits_perfDebugInfo_selectTime;
  wire [63:0] Mul_io_out_bits_perfDebugInfo_issueTime;
  wire [63:0] Mul_io_out_bits_perfDebugInfo_writebackTime;
  wire [63:0] Mul_io_out_bits_perfDebugInfo_runahead_checkpoint_id;
  wire [63:0] Mul_io_out_bits_perfDebugInfo_tlbFirstReqTime;
  wire [63:0] Mul_io_out_bits_perfDebugInfo_tlbRespTime;
  wire [55:0] Mul_io_out_bits_debug_seqNum_seqNum;
  wire [7:0] Mul_io_out_bits_debug_seqNum_uopIdx;
  wire Alu_io_in_ready;
  wire Alu_io_out_valid;
  wire Alu_io_out_bits_ctrl_robIdx_flag;
  wire [7:0] Alu_io_out_bits_ctrl_robIdx_value;
  wire [7:0] Alu_io_out_bits_ctrl_pdest;
  wire Alu_io_out_bits_ctrl_rfWen;
  wire [63:0] Alu_io_out_bits_res_data;
  wire Alu_io_out_bits_perfDebugInfo_eliminatedMove;
  wire [63:0] Alu_io_out_bits_perfDebugInfo_renameTime;
  wire [63:0] Alu_io_out_bits_perfDebugInfo_dispatchTime;
  wire [63:0] Alu_io_out_bits_perfDebugInfo_enqRsTime;
  wire [63:0] Alu_io_out_bits_perfDebugInfo_selectTime;
  wire [63:0] Alu_io_out_bits_perfDebugInfo_issueTime;
  wire [63:0] Alu_io_out_bits_perfDebugInfo_writebackTime;
  wire [63:0] Alu_io_out_bits_perfDebugInfo_runahead_checkpoint_id;
  wire [63:0] Alu_io_out_bits_perfDebugInfo_tlbFirstReqTime;
  wire [63:0] Alu_io_out_bits_perfDebugInfo_tlbRespTime;
  wire [55:0] Alu_io_out_bits_debug_seqNum_seqNum;
  wire [7:0] Alu_io_out_bits_debug_seqNum_uopIdx;
  wire in1ToN_io_in_ready;

  // ---- 外壳控制核 ----
  localparam int N_FU    = 3;
  localparam int LAT_MAX = 2;
  localparam int PAY_W   = 18;
  wire                     disp_in_valid;
  wire [LAT_MAX:0]         pipe_valid;
  wire [LAT_MAX:0][PAY_W-1:0] pipe_data;
  wire [N_FU-1:0]          fu_clk_en;
  wire [0:0][4:0]        att_q;
  wire                     out_valid;
  xs_ExeUnit_core #(
    .N_FU         (N_FU),
    .FU_LAT       ('{0, 2, 2}),
    .FU_UNCERTAIN ('{0, 0, 0}),
    .HAS_BUSY     (1'b0),
    .LAT_MAX      (LAT_MAX),
    .NF           (3),
    .FIELD_W      ('{9, 8, 1}),
    .FIELD_DEPTH  ('{2, 2, 2}),
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
    .in_payload      ({io_in_bits_rfWen, io_in_bits_pdest, io_in_bits_robIdx_flag, io_in_bits_robIdx_value}),
    .disp_in_valid   (disp_in_valid),
    .disp_in_ready   (in1ToN_io_in_ready),
    .pipe_valid      (pipe_valid),
    .pipe_data       (pipe_data),
    .fu_in_valid     ({in1ToN_io_out_2_valid, in1ToN_io_out_1_valid, in1ToN_io_out_0_valid}),
    .fu_in_ready     ({Bku_io_in_ready, Mul_io_in_ready, Alu_io_in_ready}),
    .fu_out_valid    ({Bku_io_out_valid, Mul_io_out_valid, Alu_io_out_valid}),
    .out_ready       (io_out_ready),
    .fu_clk_en       (fu_clk_en),
    .att_in          (5'h0),
    .att_q           (att_q),
    .out_valid       (out_valid)
  );

  // ---- inPipe 第 s 级字段拆包（只拆有 FU 读的那些）----
  wire [7:0] pipe2_pdest = pipe_data[2][16:9];
  wire pipe2_rfWen = pipe_data[2][17];
  wire pipe2_robIdx_flag = pipe_data[2][8];
  wire [7:0] pipe2_robIdx_value = pipe_data[2][7:0];

  // ---- Dispatcher：按 fuType 把指令派给一个 FU ----
  Dispatcher in1ToN (
    .clock                                              (clock),
    .reset                                              (reset),
    .io_in_ready                                        (in1ToN_io_in_ready),
    .io_in_valid                                        (disp_in_valid),
    .io_in_bits_fuType                                  (io_in_bits_fuType),
    .io_in_bits_fuOpType                                (io_in_bits_fuOpType),
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
    .io_out_0_ready                                     (Alu_io_in_ready),
    .io_out_0_valid                                     (in1ToN_io_out_0_valid),
    .io_out_0_bits_fuOpType                             (in1ToN_io_out_0_bits_fuOpType),
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
    .io_out_1_ready                                     (Mul_io_in_ready),
    .io_out_1_valid                                     (in1ToN_io_out_1_valid),
    .io_out_1_bits_fuOpType                             (in1ToN_io_out_1_bits_fuOpType),
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
    .io_out_2_ready                                     (Bku_io_in_ready),
    .io_out_2_valid                                     (in1ToN_io_out_2_valid),
    .io_out_2_bits_fuOpType                             (in1ToN_io_out_2_bits_fuOpType),
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
    .io_out_2_bits_debug_seqNum_uopIdx                  (in1ToN_io_out_2_bits_debug_seqNum_uopIdx)
  );

  // ---- 功能单元 ----
  Alu Alu (
    .io_in_ready                                      (Alu_io_in_ready),
    .io_in_valid                                      (in1ToN_io_out_0_valid),
    .io_in_bits_ctrl_fuOpType                         (in1ToN_io_out_0_bits_fuOpType),
    .io_in_bits_ctrlPipe_0_robIdx_flag                (io_in_bits_robIdx_flag),
    .io_in_bits_ctrlPipe_0_robIdx_value               (io_in_bits_robIdx_value),
    .io_in_bits_ctrlPipe_0_pdest                      (io_in_bits_pdest),
    .io_in_bits_ctrlPipe_0_rfWen                      (io_in_bits_rfWen),
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
    .io_out_valid                                     (Alu_io_out_valid),
    .io_out_bits_ctrl_robIdx_flag                     (Alu_io_out_bits_ctrl_robIdx_flag),
    .io_out_bits_ctrl_robIdx_value                    (Alu_io_out_bits_ctrl_robIdx_value),
    .io_out_bits_ctrl_pdest                           (Alu_io_out_bits_ctrl_pdest),
    .io_out_bits_ctrl_rfWen                           (Alu_io_out_bits_ctrl_rfWen),
    .io_out_bits_res_data                             (Alu_io_out_bits_res_data),
    .io_out_bits_perfDebugInfo_eliminatedMove         (Alu_io_out_bits_perfDebugInfo_eliminatedMove),
    .io_out_bits_perfDebugInfo_renameTime             (Alu_io_out_bits_perfDebugInfo_renameTime),
    .io_out_bits_perfDebugInfo_dispatchTime           (Alu_io_out_bits_perfDebugInfo_dispatchTime),
    .io_out_bits_perfDebugInfo_enqRsTime              (Alu_io_out_bits_perfDebugInfo_enqRsTime),
    .io_out_bits_perfDebugInfo_selectTime             (Alu_io_out_bits_perfDebugInfo_selectTime),
    .io_out_bits_perfDebugInfo_issueTime              (Alu_io_out_bits_perfDebugInfo_issueTime),
    .io_out_bits_perfDebugInfo_writebackTime          (Alu_io_out_bits_perfDebugInfo_writebackTime),
    .io_out_bits_perfDebugInfo_runahead_checkpoint_id (Alu_io_out_bits_perfDebugInfo_runahead_checkpoint_id),
    .io_out_bits_perfDebugInfo_tlbFirstReqTime        (Alu_io_out_bits_perfDebugInfo_tlbFirstReqTime),
    .io_out_bits_perfDebugInfo_tlbRespTime            (Alu_io_out_bits_perfDebugInfo_tlbRespTime),
    .io_out_bits_debug_seqNum_seqNum                  (Alu_io_out_bits_debug_seqNum_seqNum),
    .io_out_bits_debug_seqNum_uopIdx                  (Alu_io_out_bits_debug_seqNum_uopIdx)
  );
  MulUnit Mul (
    .clock                                            (ClockGate_Q),
    .reset                                            (reset),
    .io_in_ready                                      (Mul_io_in_ready),
    .io_in_valid                                      (in1ToN_io_out_1_valid),
    .io_in_bits_ctrl_fuOpType                         (in1ToN_io_out_1_bits_fuOpType),
    .io_in_bits_ctrlPipe_2_robIdx_flag                (pipe2_robIdx_flag),
    .io_in_bits_ctrlPipe_2_robIdx_value               (pipe2_robIdx_value),
    .io_in_bits_ctrlPipe_2_pdest                      (pipe2_pdest),
    .io_in_bits_ctrlPipe_2_rfWen                      (pipe2_rfWen),
    .io_in_bits_validPipe_0                           (io_in_valid),
    .io_in_bits_validPipe_1                           (pipe_valid[1]),
    .io_in_bits_validPipe_2                           (pipe_valid[2]),
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
    .io_out_valid                                     (Mul_io_out_valid),
    .io_out_bits_ctrl_robIdx_flag                     (Mul_io_out_bits_ctrl_robIdx_flag),
    .io_out_bits_ctrl_robIdx_value                    (Mul_io_out_bits_ctrl_robIdx_value),
    .io_out_bits_ctrl_pdest                           (Mul_io_out_bits_ctrl_pdest),
    .io_out_bits_ctrl_rfWen                           (Mul_io_out_bits_ctrl_rfWen),
    .io_out_bits_res_data                             (Mul_io_out_bits_res_data),
    .io_out_bits_perfDebugInfo_eliminatedMove         (Mul_io_out_bits_perfDebugInfo_eliminatedMove),
    .io_out_bits_perfDebugInfo_renameTime             (Mul_io_out_bits_perfDebugInfo_renameTime),
    .io_out_bits_perfDebugInfo_dispatchTime           (Mul_io_out_bits_perfDebugInfo_dispatchTime),
    .io_out_bits_perfDebugInfo_enqRsTime              (Mul_io_out_bits_perfDebugInfo_enqRsTime),
    .io_out_bits_perfDebugInfo_selectTime             (Mul_io_out_bits_perfDebugInfo_selectTime),
    .io_out_bits_perfDebugInfo_issueTime              (Mul_io_out_bits_perfDebugInfo_issueTime),
    .io_out_bits_perfDebugInfo_writebackTime          (Mul_io_out_bits_perfDebugInfo_writebackTime),
    .io_out_bits_perfDebugInfo_runahead_checkpoint_id (Mul_io_out_bits_perfDebugInfo_runahead_checkpoint_id),
    .io_out_bits_perfDebugInfo_tlbFirstReqTime        (Mul_io_out_bits_perfDebugInfo_tlbFirstReqTime),
    .io_out_bits_perfDebugInfo_tlbRespTime            (Mul_io_out_bits_perfDebugInfo_tlbRespTime),
    .io_out_bits_debug_seqNum_seqNum                  (Mul_io_out_bits_debug_seqNum_seqNum),
    .io_out_bits_debug_seqNum_uopIdx                  (Mul_io_out_bits_debug_seqNum_uopIdx)
  );
  Bku Bku (
    .clock                                            (ClockGate_1_Q),
    .reset                                            (reset),
    .io_in_ready                                      (Bku_io_in_ready),
    .io_in_valid                                      (in1ToN_io_out_2_valid),
    .io_in_bits_ctrl_fuOpType                         (in1ToN_io_out_2_bits_fuOpType),
    .io_in_bits_ctrlPipe_2_robIdx_flag                (pipe2_robIdx_flag),
    .io_in_bits_ctrlPipe_2_robIdx_value               (pipe2_robIdx_value),
    .io_in_bits_ctrlPipe_2_pdest                      (pipe2_pdest),
    .io_in_bits_ctrlPipe_2_rfWen                      (pipe2_rfWen),
    .io_in_bits_validPipe_0                           (io_in_valid),
    .io_in_bits_validPipe_1                           (pipe_valid[1]),
    .io_in_bits_validPipe_2                           (pipe_valid[2]),
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
    .io_out_valid                                     (Bku_io_out_valid),
    .io_out_bits_ctrl_robIdx_flag                     (Bku_io_out_bits_ctrl_robIdx_flag),
    .io_out_bits_ctrl_robIdx_value                    (Bku_io_out_bits_ctrl_robIdx_value),
    .io_out_bits_ctrl_pdest                           (Bku_io_out_bits_ctrl_pdest),
    .io_out_bits_ctrl_rfWen                           (Bku_io_out_bits_ctrl_rfWen),
    .io_out_bits_res_data                             (Bku_io_out_bits_res_data),
    .io_out_bits_perfDebugInfo_eliminatedMove         (Bku_io_out_bits_perfDebugInfo_eliminatedMove),
    .io_out_bits_perfDebugInfo_renameTime             (Bku_io_out_bits_perfDebugInfo_renameTime),
    .io_out_bits_perfDebugInfo_dispatchTime           (Bku_io_out_bits_perfDebugInfo_dispatchTime),
    .io_out_bits_perfDebugInfo_enqRsTime              (Bku_io_out_bits_perfDebugInfo_enqRsTime),
    .io_out_bits_perfDebugInfo_selectTime             (Bku_io_out_bits_perfDebugInfo_selectTime),
    .io_out_bits_perfDebugInfo_issueTime              (Bku_io_out_bits_perfDebugInfo_issueTime),
    .io_out_bits_perfDebugInfo_writebackTime          (Bku_io_out_bits_perfDebugInfo_writebackTime),
    .io_out_bits_perfDebugInfo_runahead_checkpoint_id (Bku_io_out_bits_perfDebugInfo_runahead_checkpoint_id),
    .io_out_bits_perfDebugInfo_tlbFirstReqTime        (Bku_io_out_bits_perfDebugInfo_tlbFirstReqTime),
    .io_out_bits_perfDebugInfo_tlbRespTime            (Bku_io_out_bits_perfDebugInfo_tlbRespTime),
    .io_out_bits_debug_seqNum_seqNum                  (Bku_io_out_bits_debug_seqNum_seqNum),
    .io_out_bits_debug_seqNum_uopIdx                  (Bku_io_out_bits_debug_seqNum_uopIdx)
  );

  // ---- 时钟门控（E 来自核 §3；TE 来自 DFT 的 cg_bore）----
  ClockGate ClockGate (
    .TE (cg_bore_cgen),
    .E  (fu_clk_en[1]),
    .CK (clock),
    .Q  (ClockGate_Q)
  );
  ClockGate ClockGate_1 (
    .TE (cg_bore_1_cgen),
    .E  (fu_clk_en[2]),
    .CK (clock),
    .Q  (ClockGate_1_Q)
  );

  // ---- 写回：io.out.valid 与各字段的 Mux1H ----
  assign io_out_valid = out_valid;
  // 第 0 组：Alu, Mul, Bku 共同产出 —— data_0, data_1, pdest, robIdx_flag, robIdx_value, intWen, debugInfo_eliminatedMove, debugInfo_renameTime, debugInfo_dispatchTime, debugInfo_enqRsTime, debugInfo_selectTime, debugInfo_issueTime, debugInfo_writebackTime, debugInfo_runahead_checkpoint_id, debugInfo_tlbFirstReqTime, debugInfo_tlbRespTime, debug_seqNum_seqNum, debug_seqNum_uopIdx
  wire [786:0] wb0_out;
  xs_ExeUnit_wbsel #(.N(3), .W(787)) wb0 (
    .sel  ({Bku_io_out_valid, Mul_io_out_valid, Alu_io_out_valid}),
    .data ({
      {Bku_io_out_bits_res_data,
       Bku_io_out_bits_res_data,
       Bku_io_out_bits_ctrl_pdest,
       Bku_io_out_bits_ctrl_robIdx_flag,
       Bku_io_out_bits_ctrl_robIdx_value,
       Bku_io_out_bits_ctrl_rfWen,
       Bku_io_out_bits_perfDebugInfo_eliminatedMove,
       Bku_io_out_bits_perfDebugInfo_renameTime,
       Bku_io_out_bits_perfDebugInfo_dispatchTime,
       Bku_io_out_bits_perfDebugInfo_enqRsTime,
       Bku_io_out_bits_perfDebugInfo_selectTime,
       Bku_io_out_bits_perfDebugInfo_issueTime,
       Bku_io_out_bits_perfDebugInfo_writebackTime,
       Bku_io_out_bits_perfDebugInfo_runahead_checkpoint_id,
       Bku_io_out_bits_perfDebugInfo_tlbFirstReqTime,
       Bku_io_out_bits_perfDebugInfo_tlbRespTime,
       Bku_io_out_bits_debug_seqNum_seqNum,
       Bku_io_out_bits_debug_seqNum_uopIdx},
      {Mul_io_out_bits_res_data,
       Mul_io_out_bits_res_data,
       Mul_io_out_bits_ctrl_pdest,
       Mul_io_out_bits_ctrl_robIdx_flag,
       Mul_io_out_bits_ctrl_robIdx_value,
       Mul_io_out_bits_ctrl_rfWen,
       Mul_io_out_bits_perfDebugInfo_eliminatedMove,
       Mul_io_out_bits_perfDebugInfo_renameTime,
       Mul_io_out_bits_perfDebugInfo_dispatchTime,
       Mul_io_out_bits_perfDebugInfo_enqRsTime,
       Mul_io_out_bits_perfDebugInfo_selectTime,
       Mul_io_out_bits_perfDebugInfo_issueTime,
       Mul_io_out_bits_perfDebugInfo_writebackTime,
       Mul_io_out_bits_perfDebugInfo_runahead_checkpoint_id,
       Mul_io_out_bits_perfDebugInfo_tlbFirstReqTime,
       Mul_io_out_bits_perfDebugInfo_tlbRespTime,
       Mul_io_out_bits_debug_seqNum_seqNum,
       Mul_io_out_bits_debug_seqNum_uopIdx},
      {Alu_io_out_bits_res_data,
       Alu_io_out_bits_res_data,
       Alu_io_out_bits_ctrl_pdest,
       Alu_io_out_bits_ctrl_robIdx_flag,
       Alu_io_out_bits_ctrl_robIdx_value,
       Alu_io_out_bits_ctrl_rfWen,
       Alu_io_out_bits_perfDebugInfo_eliminatedMove,
       Alu_io_out_bits_perfDebugInfo_renameTime,
       Alu_io_out_bits_perfDebugInfo_dispatchTime,
       Alu_io_out_bits_perfDebugInfo_enqRsTime,
       Alu_io_out_bits_perfDebugInfo_selectTime,
       Alu_io_out_bits_perfDebugInfo_issueTime,
       Alu_io_out_bits_perfDebugInfo_writebackTime,
       Alu_io_out_bits_perfDebugInfo_runahead_checkpoint_id,
       Alu_io_out_bits_perfDebugInfo_tlbFirstReqTime,
       Alu_io_out_bits_perfDebugInfo_tlbRespTime,
       Alu_io_out_bits_debug_seqNum_seqNum,
       Alu_io_out_bits_debug_seqNum_uopIdx}
    }),
    .out  (wb0_out)
  );
  assign {
    io_out_bits_data_0,
    io_out_bits_data_1,
    io_out_bits_pdest,
    io_out_bits_robIdx_flag,
    io_out_bits_robIdx_value,
    io_out_bits_intWen,
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

endmodule
