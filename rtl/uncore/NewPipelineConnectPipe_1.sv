// NewPipelineConnectPipe_1.sv — 后端发射→执行单元之间的单拍流水缓冲（分支/跳转段）
// 家族：NewPipelineConnectPipe 共 19 个 G1 变体，逻辑同一个核，只有 payload 字段表不同。
//       核体（valid 寄存器 + RegEnable 数据寄存器 + 握手/冲刷）在
//       rtl/common/PipelineConnect.sv 的 xs_PipelineConnect，本文件不复制任何核逻辑。
// 本变体参数与规模：
//   payload = 33 个字段 / 合计 1018 位；模块端口 74 个（39 输入 / 35 输出）。
//   用途：base 的超集，另加前端分支信息 imm/nextPcOffset/pc/ftqIdx/ftqOffset/preDecode/predictInfo；src×2，只写整数（rfWen）。
// 时序说明（逐字段从 golden 核实）：**payload 里没有任何组合直通字段**，
//   包括 perfDebugInfo_*／preDecode_* 在内的每一个 io_in_bits_* 都是在
//   fire 拍写进数据寄存器、下一拍才出现在 io_out_bits_* 上（RegEnable 语义）。
//   唯一的组合输出是握手信号 io_in_ready。
module NewPipelineConnectPipe_1(
  input  logic        clock,
  input  logic        reset,
  output logic        io_in_ready,
  input  logic        io_in_valid,
  input  logic [34:0] io_in_bits_fuType,
  input  logic [8:0]  io_in_bits_fuOpType,
  input  logic [63:0] io_in_bits_src_0,
  input  logic [63:0] io_in_bits_src_1,
  input  logic [63:0] io_in_bits_imm,
  input  logic [4:0]  io_in_bits_nextPcOffset,
  input  logic        io_in_bits_robIdx_flag,
  input  logic [7:0]  io_in_bits_robIdx_value,
  input  logic [7:0]  io_in_bits_pdest,
  input  logic        io_in_bits_rfWen,
  input  logic [49:0] io_in_bits_pc,
  input  logic        io_in_bits_preDecode_valid,
  input  logic        io_in_bits_preDecode_isRVC,
  input  logic [1:0]  io_in_bits_preDecode_brType,
  input  logic        io_in_bits_preDecode_isCall,
  input  logic        io_in_bits_preDecode_isRet,
  input  logic        io_in_bits_ftqIdx_flag,
  input  logic [5:0]  io_in_bits_ftqIdx_value,
  input  logic [3:0]  io_in_bits_ftqOffset,
  input  logic [49:0] io_in_bits_predictInfo_target,
  input  logic        io_in_bits_predictInfo_taken,
  input  logic        io_in_bits_perfDebugInfo_eliminatedMove,
  input  logic [63:0] io_in_bits_perfDebugInfo_renameTime,
  input  logic [63:0] io_in_bits_perfDebugInfo_dispatchTime,
  input  logic [63:0] io_in_bits_perfDebugInfo_enqRsTime,
  input  logic [63:0] io_in_bits_perfDebugInfo_selectTime,
  input  logic [63:0] io_in_bits_perfDebugInfo_issueTime,
  input  logic [63:0] io_in_bits_perfDebugInfo_writebackTime,
  input  logic [63:0] io_in_bits_perfDebugInfo_runahead_checkpoint_id,
  input  logic [63:0] io_in_bits_perfDebugInfo_tlbFirstReqTime,
  input  logic [63:0] io_in_bits_perfDebugInfo_tlbRespTime,
  input  logic [55:0] io_in_bits_debug_seqNum_seqNum,
  input  logic [7:0]  io_in_bits_debug_seqNum_uopIdx,
  input  logic        io_out_ready,
  output logic        io_out_valid,
  output logic [34:0] io_out_bits_fuType,
  output logic [8:0]  io_out_bits_fuOpType,
  output logic [63:0] io_out_bits_src_0,
  output logic [63:0] io_out_bits_src_1,
  output logic [63:0] io_out_bits_imm,
  output logic [4:0]  io_out_bits_nextPcOffset,
  output logic        io_out_bits_robIdx_flag,
  output logic [7:0]  io_out_bits_robIdx_value,
  output logic [7:0]  io_out_bits_pdest,
  output logic        io_out_bits_rfWen,
  output logic [49:0] io_out_bits_pc,
  output logic        io_out_bits_preDecode_valid,
  output logic        io_out_bits_preDecode_isRVC,
  output logic [1:0]  io_out_bits_preDecode_brType,
  output logic        io_out_bits_preDecode_isCall,
  output logic        io_out_bits_preDecode_isRet,
  output logic        io_out_bits_ftqIdx_flag,
  output logic [5:0]  io_out_bits_ftqIdx_value,
  output logic [3:0]  io_out_bits_ftqOffset,
  output logic [49:0] io_out_bits_predictInfo_target,
  output logic        io_out_bits_predictInfo_taken,
  output logic        io_out_bits_perfDebugInfo_eliminatedMove,
  output logic [63:0] io_out_bits_perfDebugInfo_renameTime,
  output logic [63:0] io_out_bits_perfDebugInfo_dispatchTime,
  output logic [63:0] io_out_bits_perfDebugInfo_enqRsTime,
  output logic [63:0] io_out_bits_perfDebugInfo_selectTime,
  output logic [63:0] io_out_bits_perfDebugInfo_issueTime,
  output logic [63:0] io_out_bits_perfDebugInfo_writebackTime,
  output logic [63:0] io_out_bits_perfDebugInfo_runahead_checkpoint_id,
  output logic [63:0] io_out_bits_perfDebugInfo_tlbFirstReqTime,
  output logic [63:0] io_out_bits_perfDebugInfo_tlbRespTime,
  output logic [55:0] io_out_bits_debug_seqNum_seqNum,
  output logic [7:0]  io_out_bits_debug_seqNum_uopIdx,
  input  logic        io_rightOutFire,
  input  logic        io_isFlush
);

  // ---------------------------------------------------------------------------
  // 本变体的 payload 布局。用 packed struct 而不是手工位切片：入/出两侧都按
  // 同一个成员名访问，字段错位在结构上就不可能发生（这一族历史上正是因为
  // 手工切片 + 端口表用错基线而集体配错）。打包顺序照 golden 端口表，
  // 顺序本身不影响功能（核只把它当一坨位搬运）。
  // ---------------------------------------------------------------------------
  typedef struct packed {
    logic [34:0] fuType;
    logic [8:0]  fuOpType;
    // src：源操作数
    logic [63:0] src_0;
    logic [63:0] src_1;
    logic [63:0] imm;
    logic [4:0]  nextPcOffset;
    // robIdx：ROB 表项指针（flag=回绕位）
    logic        robIdx_flag;
    logic [7:0]  robIdx_value;
    logic [7:0]  pdest;
    logic        rfWen;
    logic [49:0] pc;
    // preDecode：前端预译码结果
    logic        preDecode_valid;
    logic        preDecode_isRVC;
    logic [1:0]  preDecode_brType;
    logic        preDecode_isCall;
    logic        preDecode_isRet;
    // ftqIdx：FTQ 表项指针
    logic        ftqIdx_flag;
    logic [5:0]  ftqIdx_value;
    logic [3:0]  ftqOffset;
    // predictInfo：分支预测结果
    logic [49:0] predictInfo_target;
    logic        predictInfo_taken;
    // perfDebugInfo：性能剖析时间戳（纯随流水打拍的透传束，非组合直通——见文件头）
    logic        perfDebugInfo_eliminatedMove;
    logic [63:0] perfDebugInfo_renameTime;
    logic [63:0] perfDebugInfo_dispatchTime;
    logic [63:0] perfDebugInfo_enqRsTime;
    logic [63:0] perfDebugInfo_selectTime;
    logic [63:0] perfDebugInfo_issueTime;
    logic [63:0] perfDebugInfo_writebackTime;
    logic [63:0] perfDebugInfo_runahead_checkpoint_id;
    logic [63:0] perfDebugInfo_tlbFirstReqTime;
    logic [63:0] perfDebugInfo_tlbRespTime;
    // debug：调试序号
    logic [55:0] debug_seqNum_seqNum;
    logic [7:0]  debug_seqNum_uopIdx;
  } payload_t;

  // G1 golden 该变体 io_in_bits_* 位宽之和；传给核做防呆（见核里的 initial 自检）。
  localparam int unsigned PAYLOAD_W_G1 = 1018;

  payload_t in_payload, out_payload;

  always_comb begin
    in_payload.fuType                               = io_in_bits_fuType;
    in_payload.fuOpType                             = io_in_bits_fuOpType;
    in_payload.src_0                                = io_in_bits_src_0;
    in_payload.src_1                                = io_in_bits_src_1;
    in_payload.imm                                  = io_in_bits_imm;
    in_payload.nextPcOffset                         = io_in_bits_nextPcOffset;
    in_payload.robIdx_flag                          = io_in_bits_robIdx_flag;
    in_payload.robIdx_value                         = io_in_bits_robIdx_value;
    in_payload.pdest                                = io_in_bits_pdest;
    in_payload.rfWen                                = io_in_bits_rfWen;
    in_payload.pc                                   = io_in_bits_pc;
    in_payload.preDecode_valid                      = io_in_bits_preDecode_valid;
    in_payload.preDecode_isRVC                      = io_in_bits_preDecode_isRVC;
    in_payload.preDecode_brType                     = io_in_bits_preDecode_brType;
    in_payload.preDecode_isCall                     = io_in_bits_preDecode_isCall;
    in_payload.preDecode_isRet                      = io_in_bits_preDecode_isRet;
    in_payload.ftqIdx_flag                          = io_in_bits_ftqIdx_flag;
    in_payload.ftqIdx_value                         = io_in_bits_ftqIdx_value;
    in_payload.ftqOffset                            = io_in_bits_ftqOffset;
    in_payload.predictInfo_target                   = io_in_bits_predictInfo_target;
    in_payload.predictInfo_taken                    = io_in_bits_predictInfo_taken;
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
  assign io_out_bits_imm                                  = out_payload.imm;
  assign io_out_bits_nextPcOffset                         = out_payload.nextPcOffset;
  assign io_out_bits_robIdx_flag                          = out_payload.robIdx_flag;
  assign io_out_bits_robIdx_value                         = out_payload.robIdx_value;
  assign io_out_bits_pdest                                = out_payload.pdest;
  assign io_out_bits_rfWen                                = out_payload.rfWen;
  assign io_out_bits_pc                                   = out_payload.pc;
  assign io_out_bits_preDecode_valid                      = out_payload.preDecode_valid;
  assign io_out_bits_preDecode_isRVC                      = out_payload.preDecode_isRVC;
  assign io_out_bits_preDecode_brType                     = out_payload.preDecode_brType;
  assign io_out_bits_preDecode_isCall                     = out_payload.preDecode_isCall;
  assign io_out_bits_preDecode_isRet                      = out_payload.preDecode_isRet;
  assign io_out_bits_ftqIdx_flag                          = out_payload.ftqIdx_flag;
  assign io_out_bits_ftqIdx_value                         = out_payload.ftqIdx_value;
  assign io_out_bits_ftqOffset                            = out_payload.ftqOffset;
  assign io_out_bits_predictInfo_target                   = out_payload.predictInfo_target;
  assign io_out_bits_predictInfo_taken                    = out_payload.predictInfo_taken;
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
