// NewPipelineConnectPipe_13.sv — 后端发射→执行单元之间的单拍流水缓冲（向量段（基本））
// 家族：NewPipelineConnectPipe 共 19 个 G1 变体，逻辑同一个核，只有 payload 字段表不同。
//       核体（valid 寄存器 + RegEnable 数据寄存器 + 握手/冲刷）在
//       rtl/common/PipelineConnect.sv 的 xs_PipelineConnect，本文件不复制任何核逻辑。
// 本变体参数与规模：
//   payload = 36 个字段 / 合计 1371 位；模块端口 80 个（42 输入 / 38 输出）。
//   用途：src×5 + vpu 控制束 11 个字段 + fpu.wflags，写使能 vecWen/v0Wen。
// 时序说明（逐字段从 golden 核实）：**payload 里没有任何组合直通字段**，
//   包括 perfDebugInfo_*／preDecode_* 在内的每一个 io_in_bits_* 都是在
//   fire 拍写进数据寄存器、下一拍才出现在 io_out_bits_* 上（RegEnable 语义）。
//   唯一的组合输出是握手信号 io_in_ready。
module NewPipelineConnectPipe_13(
  input  logic         clock,
  input  logic         reset,
  output logic         io_in_ready,
  input  logic         io_in_valid,
  input  logic [34:0]  io_in_bits_fuType,
  input  logic [8:0]   io_in_bits_fuOpType,
  input  logic [127:0] io_in_bits_src_0,
  input  logic [127:0] io_in_bits_src_1,
  input  logic [127:0] io_in_bits_src_2,
  input  logic [127:0] io_in_bits_src_3,
  input  logic [127:0] io_in_bits_src_4,
  input  logic         io_in_bits_robIdx_flag,
  input  logic [7:0]   io_in_bits_robIdx_value,
  input  logic [6:0]   io_in_bits_pdest,
  input  logic         io_in_bits_vecWen,
  input  logic         io_in_bits_v0Wen,
  input  logic         io_in_bits_fpu_wflags,
  input  logic         io_in_bits_vpu_vma,
  input  logic         io_in_bits_vpu_vta,
  input  logic [1:0]   io_in_bits_vpu_vsew,
  input  logic [2:0]   io_in_bits_vpu_vlmul,
  input  logic         io_in_bits_vpu_vm,
  input  logic [7:0]   io_in_bits_vpu_vstart,
  input  logic [6:0]   io_in_bits_vpu_vuopIdx,
  input  logic         io_in_bits_vpu_isExt,
  input  logic         io_in_bits_vpu_isNarrow,
  input  logic         io_in_bits_vpu_isDstMask,
  input  logic         io_in_bits_vpu_isOpMask,
  input  logic         io_in_bits_perfDebugInfo_eliminatedMove,
  input  logic [63:0]  io_in_bits_perfDebugInfo_renameTime,
  input  logic [63:0]  io_in_bits_perfDebugInfo_dispatchTime,
  input  logic [63:0]  io_in_bits_perfDebugInfo_enqRsTime,
  input  logic [63:0]  io_in_bits_perfDebugInfo_selectTime,
  input  logic [63:0]  io_in_bits_perfDebugInfo_issueTime,
  input  logic [63:0]  io_in_bits_perfDebugInfo_writebackTime,
  input  logic [63:0]  io_in_bits_perfDebugInfo_runahead_checkpoint_id,
  input  logic [63:0]  io_in_bits_perfDebugInfo_tlbFirstReqTime,
  input  logic [63:0]  io_in_bits_perfDebugInfo_tlbRespTime,
  input  logic [55:0]  io_in_bits_debug_seqNum_seqNum,
  input  logic [7:0]   io_in_bits_debug_seqNum_uopIdx,
  input  logic         io_out_ready,
  output logic         io_out_valid,
  output logic [34:0]  io_out_bits_fuType,
  output logic [8:0]   io_out_bits_fuOpType,
  output logic [127:0] io_out_bits_src_0,
  output logic [127:0] io_out_bits_src_1,
  output logic [127:0] io_out_bits_src_2,
  output logic [127:0] io_out_bits_src_3,
  output logic [127:0] io_out_bits_src_4,
  output logic         io_out_bits_robIdx_flag,
  output logic [7:0]   io_out_bits_robIdx_value,
  output logic [6:0]   io_out_bits_pdest,
  output logic         io_out_bits_vecWen,
  output logic         io_out_bits_v0Wen,
  output logic         io_out_bits_fpu_wflags,
  output logic         io_out_bits_vpu_vma,
  output logic         io_out_bits_vpu_vta,
  output logic [1:0]   io_out_bits_vpu_vsew,
  output logic [2:0]   io_out_bits_vpu_vlmul,
  output logic         io_out_bits_vpu_vm,
  output logic [7:0]   io_out_bits_vpu_vstart,
  output logic [6:0]   io_out_bits_vpu_vuopIdx,
  output logic         io_out_bits_vpu_isExt,
  output logic         io_out_bits_vpu_isNarrow,
  output logic         io_out_bits_vpu_isDstMask,
  output logic         io_out_bits_vpu_isOpMask,
  output logic         io_out_bits_perfDebugInfo_eliminatedMove,
  output logic [63:0]  io_out_bits_perfDebugInfo_renameTime,
  output logic [63:0]  io_out_bits_perfDebugInfo_dispatchTime,
  output logic [63:0]  io_out_bits_perfDebugInfo_enqRsTime,
  output logic [63:0]  io_out_bits_perfDebugInfo_selectTime,
  output logic [63:0]  io_out_bits_perfDebugInfo_issueTime,
  output logic [63:0]  io_out_bits_perfDebugInfo_writebackTime,
  output logic [63:0]  io_out_bits_perfDebugInfo_runahead_checkpoint_id,
  output logic [63:0]  io_out_bits_perfDebugInfo_tlbFirstReqTime,
  output logic [63:0]  io_out_bits_perfDebugInfo_tlbRespTime,
  output logic [55:0]  io_out_bits_debug_seqNum_seqNum,
  output logic [7:0]   io_out_bits_debug_seqNum_uopIdx,
  input  logic         io_rightOutFire,
  input  logic         io_isFlush
);

  // ---------------------------------------------------------------------------
  // 本变体的 payload 布局。用 packed struct 而不是手工位切片：入/出两侧都按
  // 同一个成员名访问，字段错位在结构上就不可能发生（这一族历史上正是因为
  // 手工切片 + 端口表用错基线而集体配错）。打包顺序照 golden 端口表，
  // 顺序本身不影响功能（核只把它当一坨位搬运）。
  // ---------------------------------------------------------------------------
  typedef struct packed {
    logic [34:0]  fuType;
    logic [8:0]   fuOpType;
    // src：源操作数
    logic [127:0] src_0;
    logic [127:0] src_1;
    logic [127:0] src_2;
    logic [127:0] src_3;
    logic [127:0] src_4;
    // robIdx：ROB 表项指针（flag=回绕位）
    logic         robIdx_flag;
    logic [7:0]   robIdx_value;
    logic [6:0]   pdest;
    logic         vecWen;
    logic         v0Wen;
    // fpu：浮点控制束（fmt/rm/wflags）
    logic         fpu_wflags;
    // vpu：向量控制束（vstart/vl/vtype/…）
    logic         vpu_vma;
    logic         vpu_vta;
    logic [1:0]   vpu_vsew;
    logic [2:0]   vpu_vlmul;
    logic         vpu_vm;
    logic [7:0]   vpu_vstart;
    logic [6:0]   vpu_vuopIdx;
    logic         vpu_isExt;
    logic         vpu_isNarrow;
    logic         vpu_isDstMask;
    logic         vpu_isOpMask;
    // perfDebugInfo：性能剖析时间戳（纯随流水打拍的透传束，非组合直通——见文件头）
    logic         perfDebugInfo_eliminatedMove;
    logic [63:0]  perfDebugInfo_renameTime;
    logic [63:0]  perfDebugInfo_dispatchTime;
    logic [63:0]  perfDebugInfo_enqRsTime;
    logic [63:0]  perfDebugInfo_selectTime;
    logic [63:0]  perfDebugInfo_issueTime;
    logic [63:0]  perfDebugInfo_writebackTime;
    logic [63:0]  perfDebugInfo_runahead_checkpoint_id;
    logic [63:0]  perfDebugInfo_tlbFirstReqTime;
    logic [63:0]  perfDebugInfo_tlbRespTime;
    // debug：调试序号
    logic [55:0]  debug_seqNum_seqNum;
    logic [7:0]   debug_seqNum_uopIdx;
  } payload_t;

  // G1 golden 该变体 io_in_bits_* 位宽之和；传给核做防呆（见核里的 initial 自检）。
  localparam int unsigned PAYLOAD_W_G1 = 1371;

  payload_t in_payload, out_payload;

  always_comb begin
    in_payload.fuType                               = io_in_bits_fuType;
    in_payload.fuOpType                             = io_in_bits_fuOpType;
    in_payload.src_0                                = io_in_bits_src_0;
    in_payload.src_1                                = io_in_bits_src_1;
    in_payload.src_2                                = io_in_bits_src_2;
    in_payload.src_3                                = io_in_bits_src_3;
    in_payload.src_4                                = io_in_bits_src_4;
    in_payload.robIdx_flag                          = io_in_bits_robIdx_flag;
    in_payload.robIdx_value                         = io_in_bits_robIdx_value;
    in_payload.pdest                                = io_in_bits_pdest;
    in_payload.vecWen                               = io_in_bits_vecWen;
    in_payload.v0Wen                                = io_in_bits_v0Wen;
    in_payload.fpu_wflags                           = io_in_bits_fpu_wflags;
    in_payload.vpu_vma                              = io_in_bits_vpu_vma;
    in_payload.vpu_vta                              = io_in_bits_vpu_vta;
    in_payload.vpu_vsew                             = io_in_bits_vpu_vsew;
    in_payload.vpu_vlmul                            = io_in_bits_vpu_vlmul;
    in_payload.vpu_vm                               = io_in_bits_vpu_vm;
    in_payload.vpu_vstart                           = io_in_bits_vpu_vstart;
    in_payload.vpu_vuopIdx                          = io_in_bits_vpu_vuopIdx;
    in_payload.vpu_isExt                            = io_in_bits_vpu_isExt;
    in_payload.vpu_isNarrow                         = io_in_bits_vpu_isNarrow;
    in_payload.vpu_isDstMask                        = io_in_bits_vpu_isDstMask;
    in_payload.vpu_isOpMask                         = io_in_bits_vpu_isOpMask;
    in_payload.perfDebugInfo_eliminatedMove         = io_in_bits_perfDebugInfo_eliminatedMove;
    in_payload.perfDebugInfo_renameTime             = io_in_bits_perfDebugInfo_renameTime;
    in_payload.perfDebugInfo_dispatchTime           = io_in_bits_perfDebugInfo_dispatchTime;
    in_payload.perfDebugInfo_enqRsTime              = io_in_bits_perfDebugInfo_enqRsTime;
    in_payload.perfDebugInfo_selectTime             = io_in_bits_perfDebugInfo_selectTime;
    in_payload.perfDebugInfo_issueTime              = io_in_bits_perfDebugInfo_issueTime;
    in_payload.perfDebugInfo_writebackTime          = io_in_bits_perfDebugInfo_writebackTime;
    in_payload.perfDebugInfo_runahead_checkpoint_id = io_in_bits_perfDebugInfo_runahead_checkpoint_id;
    in_payload.perfDebugInfo_tlbFirstReqTime        = io_in_bits_perfDebugInfo_tlbFirstReqTime;
    in_payload.perfDebugInfo_tlbRespTime            = io_in_bits_perfDebugInfo_tlbRespTime;
    in_payload.debug_seqNum_seqNum                  = io_in_bits_debug_seqNum_seqNum;
    in_payload.debug_seqNum_uopIdx                  = io_in_bits_debug_seqNum_uopIdx;
  end

  xs_PipelineConnect #(
    .DATA_WIDTH   ($bits(payload_t)),
    .PAYLOAD_W_G1 (PAYLOAD_W_G1)
  ) u_core (
    .clock           (clock),
    .reset           (reset),
    .io_in_ready     (io_in_ready),
    .io_in_valid     (io_in_valid),
    .io_in_bits      (in_payload),
    .io_out_ready    (io_out_ready),
    .io_out_valid    (io_out_valid),
    .io_out_bits     (out_payload),
    .io_rightOutFire (io_rightOutFire),
    .io_isFlush      (io_isFlush)
  );

  assign io_out_bits_fuType                               = out_payload.fuType;
  assign io_out_bits_fuOpType                             = out_payload.fuOpType;
  assign io_out_bits_src_0                                = out_payload.src_0;
  assign io_out_bits_src_1                                = out_payload.src_1;
  assign io_out_bits_src_2                                = out_payload.src_2;
  assign io_out_bits_src_3                                = out_payload.src_3;
  assign io_out_bits_src_4                                = out_payload.src_4;
  assign io_out_bits_robIdx_flag                          = out_payload.robIdx_flag;
  assign io_out_bits_robIdx_value                         = out_payload.robIdx_value;
  assign io_out_bits_pdest                                = out_payload.pdest;
  assign io_out_bits_vecWen                               = out_payload.vecWen;
  assign io_out_bits_v0Wen                                = out_payload.v0Wen;
  assign io_out_bits_fpu_wflags                           = out_payload.fpu_wflags;
  assign io_out_bits_vpu_vma                              = out_payload.vpu_vma;
  assign io_out_bits_vpu_vta                              = out_payload.vpu_vta;
  assign io_out_bits_vpu_vsew                             = out_payload.vpu_vsew;
  assign io_out_bits_vpu_vlmul                            = out_payload.vpu_vlmul;
  assign io_out_bits_vpu_vm                               = out_payload.vpu_vm;
  assign io_out_bits_vpu_vstart                           = out_payload.vpu_vstart;
  assign io_out_bits_vpu_vuopIdx                          = out_payload.vpu_vuopIdx;
  assign io_out_bits_vpu_isExt                            = out_payload.vpu_isExt;
  assign io_out_bits_vpu_isNarrow                         = out_payload.vpu_isNarrow;
  assign io_out_bits_vpu_isDstMask                        = out_payload.vpu_isDstMask;
  assign io_out_bits_vpu_isOpMask                         = out_payload.vpu_isOpMask;
  assign io_out_bits_perfDebugInfo_eliminatedMove         = out_payload.perfDebugInfo_eliminatedMove;
  assign io_out_bits_perfDebugInfo_renameTime             = out_payload.perfDebugInfo_renameTime;
  assign io_out_bits_perfDebugInfo_dispatchTime           = out_payload.perfDebugInfo_dispatchTime;
  assign io_out_bits_perfDebugInfo_enqRsTime              = out_payload.perfDebugInfo_enqRsTime;
  assign io_out_bits_perfDebugInfo_selectTime             = out_payload.perfDebugInfo_selectTime;
  assign io_out_bits_perfDebugInfo_issueTime              = out_payload.perfDebugInfo_issueTime;
  assign io_out_bits_perfDebugInfo_writebackTime          = out_payload.perfDebugInfo_writebackTime;
  assign io_out_bits_perfDebugInfo_runahead_checkpoint_id = out_payload.perfDebugInfo_runahead_checkpoint_id;
  assign io_out_bits_perfDebugInfo_tlbFirstReqTime        = out_payload.perfDebugInfo_tlbFirstReqTime;
  assign io_out_bits_perfDebugInfo_tlbRespTime            = out_payload.perfDebugInfo_tlbRespTime;
  assign io_out_bits_debug_seqNum_seqNum                  = out_payload.debug_seqNum_seqNum;
  assign io_out_bits_debug_seqNum_uopIdx                  = out_payload.debug_seqNum_uopIdx;

endmodule
