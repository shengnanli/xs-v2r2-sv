// =============================================================================
// ExeUnit_16 —— 执行单元外壳（golden 同名 wrapper；由 scripts/gen_exeunit.py 从 G1 golden 生成，勿手改）
// -----------------------------------------------------------------------------
// FU（按 Dispatcher 出口序）：Vfalu(VFAlu, 延迟 1, 门控)
// inPipe：1 级；字段 robIdx[9]×1级, fuOpType[9]×1级, src_2[128]×1级, src_3[128]×1级, src_4[128]×1级, pdest[8]×1级, fpWen[1]×1级, vecWen[1]×1级, v0Wen[1]×1级, fpu_wflags[1]×1级, vpu_vma[1]×1级, vpu_vta[1]×1级, vpu_vsew[2]×1级, vpu_vlmul[3]×1级, vpu_vm[1]×1级, vpu_vstart[8]×1级, vpu_fpu_isFoldTo1_2[1]×1级, vpu_fpu_isFoldTo1_4[1]×1级, vpu_fpu_isFoldTo1_8[1]×1级, vpu_vuopIdx[7]×1级, vpu_lastUop[1]×1级, vpu_isNarrow[1]×1级, vpu_isDstMask[1]×1级
// 机制全部在 xs_ExeUnit_core（发射握手 / inPipe 冲刷流水 / 时钟门控使能 / 写回有效）与
//   xs_ExeUnit_wbsel（写回字段 Mux1H）里；本文件只有例化、连线与字段打包。
// 子模块：Dispatcher 与各 FU、ClockGate 均为已签核件（两侧白盒，实例名与 golden 相同）。
// golden 对照：G1-canonical/golden-rtl/ExeUnit_16.sv
// 本文件导航（一个 golden 模块一个文件，不拆；行号由生成器回填）：
//   L97    子模块输出线（名字 = golden 的 _<实例>_<端口> 去掉前导下划线）
//   L125   外壳控制核
//   L170   inPipe 第 s 级字段拆包（只拆有 FU 读的那些）
//   L196   Dispatcher：按 fuType 把指令派给一个 FU
//   L247   功能单元
//   L333   时钟门控（E 来自核 §3；TE 来自 DFT 的 cg_bore）
//   L341   写回：io.out.valid 与各字段的 Mux1H
// =============================================================================
module ExeUnit_16(
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
  input          io_in_bits_fpWen,
  input          io_in_bits_vecWen,
  input          io_in_bits_v0Wen,
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
  output [7:0]   io_out_bits_pdest,
  output         io_out_bits_robIdx_flag,
  output [7:0]   io_out_bits_robIdx_value,
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
  input          cg_bore_cgen
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
  wire ClockGate_Q;
  wire Vfalu_io_in_ready;
  wire Vfalu_io_out_valid;
  wire [127:0] Vfalu_io_out_bits_res_data;
  wire in1ToN_io_in_ready;

  // ---- 外壳控制核 ----
  localparam int N_FU    = 1;
  localparam int LAT_MAX = 1;
  localparam int PAY_W   = 443;
  wire                     disp_in_valid;
  wire [LAT_MAX:0]         pipe_valid;
  wire [LAT_MAX:0][PAY_W-1:0] pipe_data;
  wire [N_FU-1:0]          fu_clk_en;
  wire [0:0][4:0]        att_q;
  wire                     out_valid;
  xs_ExeUnit_core #(
    .N_FU         (N_FU),
    .FU_LAT       ('{1}),
    .FU_UNCERTAIN ('{0}),
    .HAS_BUSY     (1'b0),
    .LAT_MAX      (LAT_MAX),
    .NF           (23),
    .FIELD_W      ('{9, 9, 128, 128, 128, 8, 1, 1, 1, 1, 1, 1, 2, 3, 1, 8, 1, 1, 1, 7, 1, 1, 1}),
    .FIELD_DEPTH  ('{1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1}),
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
    .in_payload      ({io_in_bits_vpu_isDstMask, io_in_bits_vpu_isNarrow, io_in_bits_vpu_lastUop, io_in_bits_vpu_vuopIdx, io_in_bits_vpu_fpu_isFoldTo1_8, io_in_bits_vpu_fpu_isFoldTo1_4, io_in_bits_vpu_fpu_isFoldTo1_2, io_in_bits_vpu_vstart, io_in_bits_vpu_vm, io_in_bits_vpu_vlmul, io_in_bits_vpu_vsew, io_in_bits_vpu_vta, io_in_bits_vpu_vma, io_in_bits_fpu_wflags, io_in_bits_v0Wen, io_in_bits_vecWen, io_in_bits_fpWen, io_in_bits_pdest, io_in_bits_src_4, io_in_bits_src_3, io_in_bits_src_2, io_in_bits_fuOpType, io_in_bits_robIdx_flag, io_in_bits_robIdx_value}),
    .disp_in_valid   (disp_in_valid),
    .disp_in_ready   (in1ToN_io_in_ready),
    .pipe_valid      (pipe_valid),
    .pipe_data       (pipe_data),
    .fu_in_valid     ({in1ToN_io_out_0_valid}),
    .fu_in_ready     ({Vfalu_io_in_ready}),
    .fu_out_valid    ({Vfalu_io_out_valid}),
    .out_ready       (io_out_ready),
    .fu_clk_en       (fu_clk_en),
    .att_in          (5'h0),
    .att_q           (att_q),
    .out_valid       (out_valid)
  );

  // ---- inPipe 第 s 级字段拆包（只拆有 FU 读的那些）----
  wire pipe1_fpWen = pipe_data[1][410];
  wire pipe1_fpu_wflags = pipe_data[1][413];
  wire [8:0] pipe1_fuOpType = pipe_data[1][17:9];
  wire [7:0] pipe1_pdest = pipe_data[1][409:402];
  wire pipe1_robIdx_flag = pipe_data[1][8];
  wire [7:0] pipe1_robIdx_value = pipe_data[1][7:0];
  wire [127:0] pipe1_src_2 = pipe_data[1][145:18];
  wire [127:0] pipe1_src_3 = pipe_data[1][273:146];
  wire [127:0] pipe1_src_4 = pipe_data[1][401:274];
  wire pipe1_v0Wen = pipe_data[1][412];
  wire pipe1_vecWen = pipe_data[1][411];
  wire pipe1_vpu_fpu_isFoldTo1_2 = pipe_data[1][430];
  wire pipe1_vpu_fpu_isFoldTo1_4 = pipe_data[1][431];
  wire pipe1_vpu_fpu_isFoldTo1_8 = pipe_data[1][432];
  wire pipe1_vpu_isDstMask = pipe_data[1][442];
  wire pipe1_vpu_isNarrow = pipe_data[1][441];
  wire pipe1_vpu_lastUop = pipe_data[1][440];
  wire [2:0] pipe1_vpu_vlmul = pipe_data[1][420:418];
  wire pipe1_vpu_vm = pipe_data[1][421];
  wire pipe1_vpu_vma = pipe_data[1][414];
  wire [1:0] pipe1_vpu_vsew = pipe_data[1][417:416];
  wire [7:0] pipe1_vpu_vstart = pipe_data[1][429:422];
  wire pipe1_vpu_vta = pipe_data[1][415];
  wire [6:0] pipe1_vpu_vuopIdx = pipe_data[1][439:433];

  // ---- Dispatcher：按 fuType 把指令派给一个 FU ----
  Dispatcher_16 in1ToN (
    .clock                                              (clock),
    .reset                                              (reset),
    .io_in_ready                                        (in1ToN_io_in_ready),
    .io_in_valid                                        (disp_in_valid),
    .io_in_bits_fuType                                  (io_in_bits_fuType),
    .io_in_bits_fuOpType                                (io_in_bits_fuOpType),
    .io_in_bits_vpu_vsew                                (io_in_bits_vpu_vsew),
    .io_in_bits_vpu_vlmul                               (io_in_bits_vpu_vlmul),
    .io_in_bits_vpu_vm                                  (io_in_bits_vpu_vm),
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
    .io_out_0_bits_debug_seqNum_uopIdx                  (in1ToN_io_out_0_bits_debug_seqNum_uopIdx)
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
    .io_out_bits_ctrl_robIdx_flag                     (io_out_bits_robIdx_flag),
    .io_out_bits_ctrl_robIdx_value                    (io_out_bits_robIdx_value),
    .io_out_bits_ctrl_pdest                           (io_out_bits_pdest),
    .io_out_bits_ctrl_fpWen                           (io_out_bits_fpWen),
    .io_out_bits_ctrl_vecWen                          (io_out_bits_vecWen),
    .io_out_bits_ctrl_v0Wen                           (io_out_bits_v0Wen),
    .io_out_bits_ctrl_fpu_wflags                      (io_out_bits_wflags),
    .io_out_bits_res_data                             (Vfalu_io_out_bits_res_data),
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
  assign io_out_bits_data_0 = Vfalu_io_out_bits_res_data;   // 只有 Vfalu 产出：单元素 Mux1H 直通
  assign io_out_bits_data_1 = Vfalu_io_out_bits_res_data;   // 只有 Vfalu 产出：单元素 Mux1H 直通
  assign io_out_bits_data_2 = Vfalu_io_out_bits_res_data;   // 只有 Vfalu 产出：单元素 Mux1H 直通
  assign io_out_bits_data_3 = Vfalu_io_out_bits_res_data;   // 只有 Vfalu 产出：单元素 Mux1H 直通

endmodule
