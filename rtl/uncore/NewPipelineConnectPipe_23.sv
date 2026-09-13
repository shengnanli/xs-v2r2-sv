// NewPipelineConnectPipe_23.sv — 后端发射→执行单元之间的单拍流水缓冲（向量访存段（最宽，唯一带 isOlder））
// 家族：NewPipelineConnectPipe 共 19 个 G1 变体，逻辑同一个核，只有 payload 字段表不同。
//       核体（valid 寄存器 + RegEnable 数据寄存器 + 握手/冲刷）在
//       rtl/common/PipelineConnect.sv 的 xs_PipelineConnect，本文件不复制任何核逻辑。
// 本变体参数与规模：
//   payload = 71 个字段 / 合计 1583 位；模块端口 151 个（78 输入 / 73 输出）。
//   用途：71 字段 / src×5 + vpu 35 字段 + sqIdx/lqIdx + 向量访存重放字段 numLsElem/isVecPartReplay/vecReplayMask/vecReplayMbIdx。
//   io_isOlder：本变体独有。golden 的 in_ready = out_ready | ~valid | isOlder，
//   即“本条比下游那条更老”时可无条件纳新。本文件不给核加端口，而是把
//   (out_ready | isOlder) 当作核的 out_ready 传进去——核里 out_ready 只用在
//   in_ready 这一处，或运算可结合，故与 golden 逐位等价。
// 时序说明（逐字段从 golden 核实）：**payload 里没有任何组合直通字段**，
//   包括 perfDebugInfo_*／preDecode_* 在内的每一个 io_in_bits_* 都是在
//   fire 拍写进数据寄存器、下一拍才出现在 io_out_bits_* 上（RegEnable 语义）。
//   唯一的组合输出是握手信号 io_in_ready。
module NewPipelineConnectPipe_23(
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
  input  logic         io_in_bits_vlWen,
  input  logic         io_in_bits_vpu_vill,
  input  logic         io_in_bits_vpu_vma,
  input  logic         io_in_bits_vpu_vta,
  input  logic [1:0]   io_in_bits_vpu_vsew,
  input  logic [2:0]   io_in_bits_vpu_vlmul,
  input  logic         io_in_bits_vpu_specVill,
  input  logic         io_in_bits_vpu_specVma,
  input  logic         io_in_bits_vpu_specVta,
  input  logic [1:0]   io_in_bits_vpu_specVsew,
  input  logic [2:0]   io_in_bits_vpu_specVlmul,
  input  logic         io_in_bits_vpu_vm,
  input  logic [7:0]   io_in_bits_vpu_vstart,
  input  logic [2:0]   io_in_bits_vpu_frm,
  input  logic         io_in_bits_vpu_fpu_isFpToVecInst,
  input  logic         io_in_bits_vpu_fpu_isFP32Instr,
  input  logic         io_in_bits_vpu_fpu_isFP64Instr,
  input  logic         io_in_bits_vpu_fpu_isReduction,
  input  logic         io_in_bits_vpu_fpu_isFoldTo1_2,
  input  logic         io_in_bits_vpu_fpu_isFoldTo1_4,
  input  logic         io_in_bits_vpu_fpu_isFoldTo1_8,
  input  logic [1:0]   io_in_bits_vpu_vxrm,
  input  logic [6:0]   io_in_bits_vpu_vuopIdx,
  input  logic         io_in_bits_vpu_lastUop,
  input  logic [127:0] io_in_bits_vpu_vmask,
  input  logic [2:0]   io_in_bits_vpu_nf,
  input  logic [1:0]   io_in_bits_vpu_veew,
  input  logic         io_in_bits_vpu_isReverse,
  input  logic         io_in_bits_vpu_isExt,
  input  logic         io_in_bits_vpu_isNarrow,
  input  logic         io_in_bits_vpu_isDstMask,
  input  logic         io_in_bits_vpu_isOpMask,
  input  logic         io_in_bits_vpu_isMove,
  input  logic         io_in_bits_vpu_isDependOldVd,
  input  logic         io_in_bits_vpu_isWritePartVd,
  input  logic         io_in_bits_vpu_isVleff,
  input  logic         io_in_bits_ftqIdx_flag,
  input  logic [5:0]   io_in_bits_ftqIdx_value,
  input  logic [3:0]   io_in_bits_ftqOffset,
  input  logic [4:0]   io_in_bits_numLsElem,
  input  logic         io_in_bits_sqIdx_flag,
  input  logic [5:0]   io_in_bits_sqIdx_value,
  input  logic         io_in_bits_lqIdx_flag,
  input  logic [6:0]   io_in_bits_lqIdx_value,
  input  logic         io_in_bits_isVecPartReplay,
  input  logic [15:0]  io_in_bits_vecReplayMask,
  input  logic [3:0]   io_in_bits_vecReplayMbIdx,
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
  output logic         io_out_bits_vlWen,
  output logic         io_out_bits_vpu_vill,
  output logic         io_out_bits_vpu_vma,
  output logic         io_out_bits_vpu_vta,
  output logic [1:0]   io_out_bits_vpu_vsew,
  output logic [2:0]   io_out_bits_vpu_vlmul,
  output logic         io_out_bits_vpu_specVill,
  output logic         io_out_bits_vpu_specVma,
  output logic         io_out_bits_vpu_specVta,
  output logic [1:0]   io_out_bits_vpu_specVsew,
  output logic [2:0]   io_out_bits_vpu_specVlmul,
  output logic         io_out_bits_vpu_vm,
  output logic [7:0]   io_out_bits_vpu_vstart,
  output logic [2:0]   io_out_bits_vpu_frm,
  output logic         io_out_bits_vpu_fpu_isFpToVecInst,
  output logic         io_out_bits_vpu_fpu_isFP32Instr,
  output logic         io_out_bits_vpu_fpu_isFP64Instr,
  output logic         io_out_bits_vpu_fpu_isReduction,
  output logic         io_out_bits_vpu_fpu_isFoldTo1_2,
  output logic         io_out_bits_vpu_fpu_isFoldTo1_4,
  output logic         io_out_bits_vpu_fpu_isFoldTo1_8,
  output logic [1:0]   io_out_bits_vpu_vxrm,
  output logic [6:0]   io_out_bits_vpu_vuopIdx,
  output logic         io_out_bits_vpu_lastUop,
  output logic [127:0] io_out_bits_vpu_vmask,
  output logic [2:0]   io_out_bits_vpu_nf,
  output logic [1:0]   io_out_bits_vpu_veew,
  output logic         io_out_bits_vpu_isReverse,
  output logic         io_out_bits_vpu_isExt,
  output logic         io_out_bits_vpu_isNarrow,
  output logic         io_out_bits_vpu_isDstMask,
  output logic         io_out_bits_vpu_isOpMask,
  output logic         io_out_bits_vpu_isMove,
  output logic         io_out_bits_vpu_isDependOldVd,
  output logic         io_out_bits_vpu_isWritePartVd,
  output logic         io_out_bits_vpu_isVleff,
  output logic         io_out_bits_ftqIdx_flag,
  output logic [5:0]   io_out_bits_ftqIdx_value,
  output logic [3:0]   io_out_bits_ftqOffset,
  output logic [4:0]   io_out_bits_numLsElem,
  output logic         io_out_bits_sqIdx_flag,
  output logic [5:0]   io_out_bits_sqIdx_value,
  output logic         io_out_bits_lqIdx_flag,
  output logic [6:0]   io_out_bits_lqIdx_value,
  output logic         io_out_bits_isVecPartReplay,
  output logic [15:0]  io_out_bits_vecReplayMask,
  output logic [3:0]   io_out_bits_vecReplayMbIdx,
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
  input  logic         io_isFlush,
  input  logic         io_isOlder
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
    logic         vlWen;
    // vpu：向量控制束（vstart/vl/vtype/…）
    logic         vpu_vill;
    logic         vpu_vma;
    logic         vpu_vta;
    logic [1:0]   vpu_vsew;
    logic [2:0]   vpu_vlmul;
    logic         vpu_specVill;
    logic         vpu_specVma;
    logic         vpu_specVta;
    logic [1:0]   vpu_specVsew;
    logic [2:0]   vpu_specVlmul;
    logic         vpu_vm;
    logic [7:0]   vpu_vstart;
    logic [2:0]   vpu_frm;
    logic         vpu_fpu_isFpToVecInst;
    logic         vpu_fpu_isFP32Instr;
    logic         vpu_fpu_isFP64Instr;
    logic         vpu_fpu_isReduction;
    logic         vpu_fpu_isFoldTo1_2;
    logic         vpu_fpu_isFoldTo1_4;
    logic         vpu_fpu_isFoldTo1_8;
    logic [1:0]   vpu_vxrm;
    logic [6:0]   vpu_vuopIdx;
    logic         vpu_lastUop;
    logic [127:0] vpu_vmask;
    logic [2:0]   vpu_nf;
    logic [1:0]   vpu_veew;
    logic         vpu_isReverse;
    logic         vpu_isExt;
    logic         vpu_isNarrow;
    logic         vpu_isDstMask;
    logic         vpu_isOpMask;
    logic         vpu_isMove;
    logic         vpu_isDependOldVd;
    logic         vpu_isWritePartVd;
    logic         vpu_isVleff;
    // ftqIdx：FTQ 表项指针
    logic         ftqIdx_flag;
    logic [5:0]   ftqIdx_value;
    logic [3:0]   ftqOffset;
    logic [4:0]   numLsElem;
    // sqIdx：Store Queue 指针
    logic         sqIdx_flag;
    logic [5:0]   sqIdx_value;
    // lqIdx：Load Queue 指针
    logic         lqIdx_flag;
    logic [6:0]   lqIdx_value;
    logic         isVecPartReplay;
    logic [15:0]  vecReplayMask;
    logic [3:0]   vecReplayMbIdx;
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
  localparam int unsigned PAYLOAD_W_G1 = 1583;

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
    in_payload.vlWen                                = io_in_bits_vlWen;
    in_payload.vpu_vill                             = io_in_bits_vpu_vill;
    in_payload.vpu_vma                              = io_in_bits_vpu_vma;
    in_payload.vpu_vta                              = io_in_bits_vpu_vta;
    in_payload.vpu_vsew                             = io_in_bits_vpu_vsew;
    in_payload.vpu_vlmul                            = io_in_bits_vpu_vlmul;
    in_payload.vpu_specVill                         = io_in_bits_vpu_specVill;
    in_payload.vpu_specVma                          = io_in_bits_vpu_specVma;
    in_payload.vpu_specVta                          = io_in_bits_vpu_specVta;
    in_payload.vpu_specVsew                         = io_in_bits_vpu_specVsew;
    in_payload.vpu_specVlmul                        = io_in_bits_vpu_specVlmul;
    in_payload.vpu_vm                               = io_in_bits_vpu_vm;
    in_payload.vpu_vstart                           = io_in_bits_vpu_vstart;
    in_payload.vpu_frm                              = io_in_bits_vpu_frm;
    in_payload.vpu_fpu_isFpToVecInst                = io_in_bits_vpu_fpu_isFpToVecInst;
    in_payload.vpu_fpu_isFP32Instr                  = io_in_bits_vpu_fpu_isFP32Instr;
    in_payload.vpu_fpu_isFP64Instr                  = io_in_bits_vpu_fpu_isFP64Instr;
    in_payload.vpu_fpu_isReduction                  = io_in_bits_vpu_fpu_isReduction;
    in_payload.vpu_fpu_isFoldTo1_2                  = io_in_bits_vpu_fpu_isFoldTo1_2;
    in_payload.vpu_fpu_isFoldTo1_4                  = io_in_bits_vpu_fpu_isFoldTo1_4;
    in_payload.vpu_fpu_isFoldTo1_8                  = io_in_bits_vpu_fpu_isFoldTo1_8;
    in_payload.vpu_vxrm                             = io_in_bits_vpu_vxrm;
    in_payload.vpu_vuopIdx                          = io_in_bits_vpu_vuopIdx;
    in_payload.vpu_lastUop                          = io_in_bits_vpu_lastUop;
    in_payload.vpu_vmask                            = io_in_bits_vpu_vmask;
    in_payload.vpu_nf                               = io_in_bits_vpu_nf;
    in_payload.vpu_veew                             = io_in_bits_vpu_veew;
    in_payload.vpu_isReverse                        = io_in_bits_vpu_isReverse;
    in_payload.vpu_isExt                            = io_in_bits_vpu_isExt;
    in_payload.vpu_isNarrow                         = io_in_bits_vpu_isNarrow;
    in_payload.vpu_isDstMask                        = io_in_bits_vpu_isDstMask;
    in_payload.vpu_isOpMask                         = io_in_bits_vpu_isOpMask;
    in_payload.vpu_isMove                           = io_in_bits_vpu_isMove;
    in_payload.vpu_isDependOldVd                    = io_in_bits_vpu_isDependOldVd;
    in_payload.vpu_isWritePartVd                    = io_in_bits_vpu_isWritePartVd;
    in_payload.vpu_isVleff                          = io_in_bits_vpu_isVleff;
    in_payload.ftqIdx_flag                          = io_in_bits_ftqIdx_flag;
    in_payload.ftqIdx_value                         = io_in_bits_ftqIdx_value;
    in_payload.ftqOffset                            = io_in_bits_ftqOffset;
    in_payload.numLsElem                            = io_in_bits_numLsElem;
    in_payload.sqIdx_flag                           = io_in_bits_sqIdx_flag;
    in_payload.sqIdx_value                          = io_in_bits_sqIdx_value;
    in_payload.lqIdx_flag                           = io_in_bits_lqIdx_flag;
    in_payload.lqIdx_value                          = io_in_bits_lqIdx_value;
    in_payload.isVecPartReplay                      = io_in_bits_isVecPartReplay;
    in_payload.vecReplayMask                        = io_in_bits_vecReplayMask;
    in_payload.vecReplayMbIdx                       = io_in_bits_vecReplayMbIdx;
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

  // isOlder 折进 out_ready（见文件头）：核内 out_ready 只参与 in_ready 的或运算。
  wire core_out_ready = io_out_ready | io_isOlder;

  xs_PipelineConnect #(
    .DATA_WIDTH   ($bits(payload_t)),
    .PAYLOAD_W_G1 (PAYLOAD_W_G1)
  ) u_core (
    .clock           (clock),
    .reset           (reset),
    .io_in_ready     (io_in_ready),
    .io_in_valid     (io_in_valid),
    .io_in_bits      (in_payload),
    .io_out_ready    (core_out_ready),
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
  assign io_out_bits_vlWen                                = out_payload.vlWen;
  assign io_out_bits_vpu_vill                             = out_payload.vpu_vill;
  assign io_out_bits_vpu_vma                              = out_payload.vpu_vma;
  assign io_out_bits_vpu_vta                              = out_payload.vpu_vta;
  assign io_out_bits_vpu_vsew                             = out_payload.vpu_vsew;
  assign io_out_bits_vpu_vlmul                            = out_payload.vpu_vlmul;
  assign io_out_bits_vpu_specVill                         = out_payload.vpu_specVill;
  assign io_out_bits_vpu_specVma                          = out_payload.vpu_specVma;
  assign io_out_bits_vpu_specVta                          = out_payload.vpu_specVta;
  assign io_out_bits_vpu_specVsew                         = out_payload.vpu_specVsew;
  assign io_out_bits_vpu_specVlmul                        = out_payload.vpu_specVlmul;
  assign io_out_bits_vpu_vm                               = out_payload.vpu_vm;
  assign io_out_bits_vpu_vstart                           = out_payload.vpu_vstart;
  assign io_out_bits_vpu_frm                              = out_payload.vpu_frm;
  assign io_out_bits_vpu_fpu_isFpToVecInst                = out_payload.vpu_fpu_isFpToVecInst;
  assign io_out_bits_vpu_fpu_isFP32Instr                  = out_payload.vpu_fpu_isFP32Instr;
  assign io_out_bits_vpu_fpu_isFP64Instr                  = out_payload.vpu_fpu_isFP64Instr;
  assign io_out_bits_vpu_fpu_isReduction                  = out_payload.vpu_fpu_isReduction;
  assign io_out_bits_vpu_fpu_isFoldTo1_2                  = out_payload.vpu_fpu_isFoldTo1_2;
  assign io_out_bits_vpu_fpu_isFoldTo1_4                  = out_payload.vpu_fpu_isFoldTo1_4;
  assign io_out_bits_vpu_fpu_isFoldTo1_8                  = out_payload.vpu_fpu_isFoldTo1_8;
  assign io_out_bits_vpu_vxrm                             = out_payload.vpu_vxrm;
  assign io_out_bits_vpu_vuopIdx                          = out_payload.vpu_vuopIdx;
  assign io_out_bits_vpu_lastUop                          = out_payload.vpu_lastUop;
  assign io_out_bits_vpu_vmask                            = out_payload.vpu_vmask;
  assign io_out_bits_vpu_nf                               = out_payload.vpu_nf;
  assign io_out_bits_vpu_veew                             = out_payload.vpu_veew;
  assign io_out_bits_vpu_isReverse                        = out_payload.vpu_isReverse;
  assign io_out_bits_vpu_isExt                            = out_payload.vpu_isExt;
  assign io_out_bits_vpu_isNarrow                         = out_payload.vpu_isNarrow;
  assign io_out_bits_vpu_isDstMask                        = out_payload.vpu_isDstMask;
  assign io_out_bits_vpu_isOpMask                         = out_payload.vpu_isOpMask;
  assign io_out_bits_vpu_isMove                           = out_payload.vpu_isMove;
  assign io_out_bits_vpu_isDependOldVd                    = out_payload.vpu_isDependOldVd;
  assign io_out_bits_vpu_isWritePartVd                    = out_payload.vpu_isWritePartVd;
  assign io_out_bits_vpu_isVleff                          = out_payload.vpu_isVleff;
  assign io_out_bits_ftqIdx_flag                          = out_payload.ftqIdx_flag;
  assign io_out_bits_ftqIdx_value                         = out_payload.ftqIdx_value;
  assign io_out_bits_ftqOffset                            = out_payload.ftqOffset;
  assign io_out_bits_numLsElem                            = out_payload.numLsElem;
  assign io_out_bits_sqIdx_flag                           = out_payload.sqIdx_flag;
  assign io_out_bits_sqIdx_value                          = out_payload.sqIdx_value;
  assign io_out_bits_lqIdx_flag                           = out_payload.lqIdx_flag;
  assign io_out_bits_lqIdx_value                          = out_payload.lqIdx_value;
  assign io_out_bits_isVecPartReplay                      = out_payload.isVecPartReplay;
  assign io_out_bits_vecReplayMask                        = out_payload.vecReplayMask;
  assign io_out_bits_vecReplayMbIdx                       = out_payload.vecReplayMbIdx;
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
