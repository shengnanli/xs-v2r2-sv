// NewPipelineConnectPipe_29.sv — 向量 merge buffer 写回口的单拍流水缓冲。
// 例化点（G1 golden，共 3 处）：VSMergeBufferImp.VMergebufferPipelineConnect0、
//   VLMergeBufferImp.VMergebufferPipelineConnect0 / …Connect1 —— 向量 store/load 的
//   merge buffer 把一条向量指令的各分片结果拼齐后，经本级送往写回网络。
// 本变体参数与规模：payload = 72 字段 / 1023 位（uop 控制束 + 128 位向量结果 data
//   + vdIdx/vdIdxInField 两个目的向量寄存器索引）；模块端口 152 个（78 输入 / 74 输出），
//   带 io_isFlush；golden 模块体 589 行。
// 家族关系：与全族共用一个核 xs_PipelineConnect（rtl/common/PipelineConnect.sv），
//   本文件只提供本变体的 payload 字段表与打包/拆包，不复制任何核逻辑。
//   核语义：in_ready = out_ready | ~valid；fire = in_valid & in_ready；
//   valid' = ~isFlush & (fire | ~rightOutFire & valid)（异步复位清 0）；
//   data = RegEnable(in_bits, fire)。
// 时序（逐字段从 G1 golden 机械核实，判据见 scripts/gen_npc_missing3.py）：
//   **没有任何组合直通字段**——debugInfo_* 在内的每个 io_in_bits_* 都在 fire 拍
//   写进数据寄存器、下一拍才出现在 io_out_bits_* 上。唯一的组合输出是 io_in_ready。
// ★名字警告★：G0(v2r2) 里叫 NewPipelineConnectPipe_29 的不存在；本变体在 G0 里
//   叫 NewPipelineConnectPipe_27（82 端口），G1 编号平移 +2 且 payload 从 37 字段/535 位
//   扩到 72 字段/1023 位。判据是例化坑位集合相等，见 scripts/check_name_collisions.py。

module NewPipelineConnectPipe_29 (
  input  logic clock,
  input  logic reset,
  output logic io_in_ready,
  input  logic io_in_valid,
  input  logic io_in_bits_uop_exceptionVec_3,
  input  logic io_in_bits_uop_exceptionVec_4,
  input  logic io_in_bits_uop_exceptionVec_5,
  input  logic io_in_bits_uop_exceptionVec_6,
  input  logic io_in_bits_uop_exceptionVec_7,
  input  logic io_in_bits_uop_exceptionVec_13,
  input  logic io_in_bits_uop_exceptionVec_15,
  input  logic io_in_bits_uop_exceptionVec_19,
  input  logic io_in_bits_uop_exceptionVec_21,
  input  logic io_in_bits_uop_exceptionVec_23,
  input  logic [3:0] io_in_bits_uop_trigger,
  input  logic [8:0] io_in_bits_uop_fuOpType,
  input  logic io_in_bits_uop_vecWen,
  input  logic io_in_bits_uop_v0Wen,
  input  logic io_in_bits_uop_vlWen,
  input  logic io_in_bits_uop_flushPipe,
  input  logic io_in_bits_uop_vpu_vill,
  input  logic io_in_bits_uop_vpu_vma,
  input  logic io_in_bits_uop_vpu_vta,
  input  logic [1:0] io_in_bits_uop_vpu_vsew,
  input  logic [2:0] io_in_bits_uop_vpu_vlmul,
  input  logic io_in_bits_uop_vpu_specVill,
  input  logic io_in_bits_uop_vpu_specVma,
  input  logic io_in_bits_uop_vpu_specVta,
  input  logic [1:0] io_in_bits_uop_vpu_specVsew,
  input  logic [2:0] io_in_bits_uop_vpu_specVlmul,
  input  logic io_in_bits_uop_vpu_vm,
  input  logic [7:0] io_in_bits_uop_vpu_vstart,
  input  logic [2:0] io_in_bits_uop_vpu_frm,
  input  logic io_in_bits_uop_vpu_fpu_isFpToVecInst,
  input  logic io_in_bits_uop_vpu_fpu_isFP32Instr,
  input  logic io_in_bits_uop_vpu_fpu_isFP64Instr,
  input  logic io_in_bits_uop_vpu_fpu_isReduction,
  input  logic io_in_bits_uop_vpu_fpu_isFoldTo1_2,
  input  logic io_in_bits_uop_vpu_fpu_isFoldTo1_4,
  input  logic io_in_bits_uop_vpu_fpu_isFoldTo1_8,
  input  logic [1:0] io_in_bits_uop_vpu_vxrm,
  input  logic [6:0] io_in_bits_uop_vpu_vuopIdx,
  input  logic io_in_bits_uop_vpu_lastUop,
  input  logic [127:0] io_in_bits_uop_vpu_vmask,
  input  logic [7:0] io_in_bits_uop_vpu_vl,
  input  logic [2:0] io_in_bits_uop_vpu_nf,
  input  logic [1:0] io_in_bits_uop_vpu_veew,
  input  logic io_in_bits_uop_vpu_isReverse,
  input  logic io_in_bits_uop_vpu_isExt,
  input  logic io_in_bits_uop_vpu_isNarrow,
  input  logic io_in_bits_uop_vpu_isDstMask,
  input  logic io_in_bits_uop_vpu_isOpMask,
  input  logic io_in_bits_uop_vpu_isMove,
  input  logic io_in_bits_uop_vpu_isDependOldVd,
  input  logic io_in_bits_uop_vpu_isWritePartVd,
  input  logic io_in_bits_uop_vpu_isVleff,
  input  logic [7:0] io_in_bits_uop_psrc_2,
  input  logic [7:0] io_in_bits_uop_pdest,
  input  logic io_in_bits_uop_robIdx_flag,
  input  logic [7:0] io_in_bits_uop_robIdx_value,
  input  logic io_in_bits_uop_debugInfo_eliminatedMove,
  input  logic [63:0] io_in_bits_uop_debugInfo_renameTime,
  input  logic [63:0] io_in_bits_uop_debugInfo_dispatchTime,
  input  logic [63:0] io_in_bits_uop_debugInfo_enqRsTime,
  input  logic [63:0] io_in_bits_uop_debugInfo_selectTime,
  input  logic [63:0] io_in_bits_uop_debugInfo_issueTime,
  input  logic [63:0] io_in_bits_uop_debugInfo_writebackTime,
  input  logic [63:0] io_in_bits_uop_debugInfo_runahead_checkpoint_id,
  input  logic [63:0] io_in_bits_uop_debugInfo_tlbFirstReqTime,
  input  logic [63:0] io_in_bits_uop_debugInfo_tlbRespTime,
  input  logic [55:0] io_in_bits_uop_debug_seqNum_seqNum,
  input  logic [7:0] io_in_bits_uop_debug_seqNum_uopIdx,
  input  logic io_in_bits_uop_replayInst,
  input  logic [127:0] io_in_bits_data,
  input  logic [2:0] io_in_bits_vdIdx,
  input  logic [2:0] io_in_bits_vdIdxInField,
  input  logic io_out_ready,
  output logic io_out_valid,
  output logic io_out_bits_uop_exceptionVec_3,
  output logic io_out_bits_uop_exceptionVec_4,
  output logic io_out_bits_uop_exceptionVec_5,
  output logic io_out_bits_uop_exceptionVec_6,
  output logic io_out_bits_uop_exceptionVec_7,
  output logic io_out_bits_uop_exceptionVec_13,
  output logic io_out_bits_uop_exceptionVec_15,
  output logic io_out_bits_uop_exceptionVec_19,
  output logic io_out_bits_uop_exceptionVec_21,
  output logic io_out_bits_uop_exceptionVec_23,
  output logic [3:0] io_out_bits_uop_trigger,
  output logic [8:0] io_out_bits_uop_fuOpType,
  output logic io_out_bits_uop_vecWen,
  output logic io_out_bits_uop_v0Wen,
  output logic io_out_bits_uop_vlWen,
  output logic io_out_bits_uop_flushPipe,
  output logic io_out_bits_uop_vpu_vill,
  output logic io_out_bits_uop_vpu_vma,
  output logic io_out_bits_uop_vpu_vta,
  output logic [1:0] io_out_bits_uop_vpu_vsew,
  output logic [2:0] io_out_bits_uop_vpu_vlmul,
  output logic io_out_bits_uop_vpu_specVill,
  output logic io_out_bits_uop_vpu_specVma,
  output logic io_out_bits_uop_vpu_specVta,
  output logic [1:0] io_out_bits_uop_vpu_specVsew,
  output logic [2:0] io_out_bits_uop_vpu_specVlmul,
  output logic io_out_bits_uop_vpu_vm,
  output logic [7:0] io_out_bits_uop_vpu_vstart,
  output logic [2:0] io_out_bits_uop_vpu_frm,
  output logic io_out_bits_uop_vpu_fpu_isFpToVecInst,
  output logic io_out_bits_uop_vpu_fpu_isFP32Instr,
  output logic io_out_bits_uop_vpu_fpu_isFP64Instr,
  output logic io_out_bits_uop_vpu_fpu_isReduction,
  output logic io_out_bits_uop_vpu_fpu_isFoldTo1_2,
  output logic io_out_bits_uop_vpu_fpu_isFoldTo1_4,
  output logic io_out_bits_uop_vpu_fpu_isFoldTo1_8,
  output logic [1:0] io_out_bits_uop_vpu_vxrm,
  output logic [6:0] io_out_bits_uop_vpu_vuopIdx,
  output logic io_out_bits_uop_vpu_lastUop,
  output logic [127:0] io_out_bits_uop_vpu_vmask,
  output logic [7:0] io_out_bits_uop_vpu_vl,
  output logic [2:0] io_out_bits_uop_vpu_nf,
  output logic [1:0] io_out_bits_uop_vpu_veew,
  output logic io_out_bits_uop_vpu_isReverse,
  output logic io_out_bits_uop_vpu_isExt,
  output logic io_out_bits_uop_vpu_isNarrow,
  output logic io_out_bits_uop_vpu_isDstMask,
  output logic io_out_bits_uop_vpu_isOpMask,
  output logic io_out_bits_uop_vpu_isMove,
  output logic io_out_bits_uop_vpu_isDependOldVd,
  output logic io_out_bits_uop_vpu_isWritePartVd,
  output logic io_out_bits_uop_vpu_isVleff,
  output logic [7:0] io_out_bits_uop_psrc_2,
  output logic [7:0] io_out_bits_uop_pdest,
  output logic io_out_bits_uop_robIdx_flag,
  output logic [7:0] io_out_bits_uop_robIdx_value,
  output logic io_out_bits_uop_debugInfo_eliminatedMove,
  output logic [63:0] io_out_bits_uop_debugInfo_renameTime,
  output logic [63:0] io_out_bits_uop_debugInfo_dispatchTime,
  output logic [63:0] io_out_bits_uop_debugInfo_enqRsTime,
  output logic [63:0] io_out_bits_uop_debugInfo_selectTime,
  output logic [63:0] io_out_bits_uop_debugInfo_issueTime,
  output logic [63:0] io_out_bits_uop_debugInfo_writebackTime,
  output logic [63:0] io_out_bits_uop_debugInfo_runahead_checkpoint_id,
  output logic [63:0] io_out_bits_uop_debugInfo_tlbFirstReqTime,
  output logic [63:0] io_out_bits_uop_debugInfo_tlbRespTime,
  output logic [55:0] io_out_bits_uop_debug_seqNum_seqNum,
  output logic [7:0] io_out_bits_uop_debug_seqNum_uopIdx,
  output logic io_out_bits_uop_replayInst,
  output logic [127:0] io_out_bits_data,
  output logic [2:0] io_out_bits_vdIdx,
  output logic [2:0] io_out_bits_vdIdxInField,
  input  logic io_rightOutFire,
  input  logic io_isFlush
);

  // ---------------------------------------------------------------------------
  // 本变体的 payload 布局。用 packed struct 而不是手工位切片：入口打包与出口拆包
  // 都按同一组成员名访问，"字段错位"在结构上就不可能发生（这一族历史上正是
  // 手工切片 + 照抄错基线的端口表而集体配错）。成员顺序照 G1 golden 端口表，
  // 顺序本身不影响功能——核只把 payload 当一坨位搬运。
  // ---------------------------------------------------------------------------
  typedef struct packed {
    // uop.exceptionVec：异常向量，本变体只导出用得到的 10 号位 —— 3/4/5/6/7/13/15/19/21/23（编号不连续）
    logic           uop_exceptionVec_3;
    logic           uop_exceptionVec_4;
    logic           uop_exceptionVec_5;
    logic           uop_exceptionVec_6;
    logic           uop_exceptionVec_7;
    logic           uop_exceptionVec_13;
    logic           uop_exceptionVec_15;
    logic           uop_exceptionVec_19;
    logic           uop_exceptionVec_21;
    logic           uop_exceptionVec_23;
    // uop：微操作本身的控制位
    logic [3:0]     uop_trigger;
    logic [8:0]     uop_fuOpType;
    logic           uop_vecWen;
    logic           uop_v0Wen;
    logic           uop_vlWen;
    logic           uop_flushPipe;
    // uop.vpu：向量控制束（vtype 现态与推测态、vl/vstart/vmask、各类形态标志）
    logic           uop_vpu_vill;
    logic           uop_vpu_vma;
    logic           uop_vpu_vta;
    logic [1:0]     uop_vpu_vsew;
    logic [2:0]     uop_vpu_vlmul;
    logic           uop_vpu_specVill;
    logic           uop_vpu_specVma;
    logic           uop_vpu_specVta;
    logic [1:0]     uop_vpu_specVsew;
    logic [2:0]     uop_vpu_specVlmul;
    logic           uop_vpu_vm;
    logic [7:0]     uop_vpu_vstart;
    logic [2:0]     uop_vpu_frm;
    // uop.vpu.fpu：向量指令里的浮点子束（folding / reduction / 精度标志）
    logic           uop_vpu_fpu_isFpToVecInst;
    logic           uop_vpu_fpu_isFP32Instr;
    logic           uop_vpu_fpu_isFP64Instr;
    logic           uop_vpu_fpu_isReduction;
    logic           uop_vpu_fpu_isFoldTo1_2;
    logic           uop_vpu_fpu_isFoldTo1_4;
    logic           uop_vpu_fpu_isFoldTo1_8;
    // uop.vpu（续）
    logic [1:0]     uop_vpu_vxrm;
    logic [6:0]     uop_vpu_vuopIdx;
    logic           uop_vpu_lastUop;
    logic [127:0]   uop_vpu_vmask;
    logic [7:0]     uop_vpu_vl;
    logic [2:0]     uop_vpu_nf;
    logic [1:0]     uop_vpu_veew;
    logic           uop_vpu_isReverse;
    logic           uop_vpu_isExt;
    logic           uop_vpu_isNarrow;
    logic           uop_vpu_isDstMask;
    logic           uop_vpu_isOpMask;
    logic           uop_vpu_isMove;
    logic           uop_vpu_isDependOldVd;
    logic           uop_vpu_isWritePartVd;
    logic           uop_vpu_isVleff;
    // uop.psrc：物理源寄存器号
    logic [7:0]     uop_psrc_2;
    // uop（续）
    logic [7:0]     uop_pdest;
    // uop.robIdx：ROB 表项指针（flag = 回绕位）
    logic           uop_robIdx_flag;
    logic [7:0]     uop_robIdx_value;
    // uop.debugInfo：性能剖析时间戳。**随流水打拍透传，不是组合直通**
    logic           uop_debugInfo_eliminatedMove;
    logic [63:0]    uop_debugInfo_renameTime;
    logic [63:0]    uop_debugInfo_dispatchTime;
    logic [63:0]    uop_debugInfo_enqRsTime;
    logic [63:0]    uop_debugInfo_selectTime;
    logic [63:0]    uop_debugInfo_issueTime;
    logic [63:0]    uop_debugInfo_writebackTime;
    logic [63:0]    uop_debugInfo_runahead_checkpoint_id;
    logic [63:0]    uop_debugInfo_tlbFirstReqTime;
    logic [63:0]    uop_debugInfo_tlbRespTime;
    // uop.debug.seqNum：调试用指令序号
    logic [55:0]    uop_debug_seqNum_seqNum;
    logic [7:0]     uop_debug_seqNum_uopIdx;
    // uop（续）
    logic           uop_replayInst;
    // 本级自己的数据字段（不属于 uop 束）
    logic [127:0]   data;
    logic [2:0]     vdIdx;
    logic [2:0]     vdIdxInField;
  } payload_t;

  // G1 golden 该变体所有 io_in_bits_* 的位宽之和。传给共享核做防呆：
  // 核里的 initial 会校验 DATA_WIDTH（= $bits(payload_t)）与它相等。
  // ★这个参数必须显式传★——核给了默认值 PAYLOAD_W_G1 = DATA_WIDTH，省略即等于不校验。
  localparam int unsigned PAYLOAD_W_G1 = 1023;

  payload_t in_payload, out_payload;

  // 入口打包：端口 -> struct 成员（同名逐项）
  always_comb begin
    in_payload.uop_exceptionVec_3                   = io_in_bits_uop_exceptionVec_3;
    in_payload.uop_exceptionVec_4                   = io_in_bits_uop_exceptionVec_4;
    in_payload.uop_exceptionVec_5                   = io_in_bits_uop_exceptionVec_5;
    in_payload.uop_exceptionVec_6                   = io_in_bits_uop_exceptionVec_6;
    in_payload.uop_exceptionVec_7                   = io_in_bits_uop_exceptionVec_7;
    in_payload.uop_exceptionVec_13                  = io_in_bits_uop_exceptionVec_13;
    in_payload.uop_exceptionVec_15                  = io_in_bits_uop_exceptionVec_15;
    in_payload.uop_exceptionVec_19                  = io_in_bits_uop_exceptionVec_19;
    in_payload.uop_exceptionVec_21                  = io_in_bits_uop_exceptionVec_21;
    in_payload.uop_exceptionVec_23                  = io_in_bits_uop_exceptionVec_23;
    in_payload.uop_trigger                          = io_in_bits_uop_trigger;
    in_payload.uop_fuOpType                         = io_in_bits_uop_fuOpType;
    in_payload.uop_vecWen                           = io_in_bits_uop_vecWen;
    in_payload.uop_v0Wen                            = io_in_bits_uop_v0Wen;
    in_payload.uop_vlWen                            = io_in_bits_uop_vlWen;
    in_payload.uop_flushPipe                        = io_in_bits_uop_flushPipe;
    in_payload.uop_vpu_vill                         = io_in_bits_uop_vpu_vill;
    in_payload.uop_vpu_vma                          = io_in_bits_uop_vpu_vma;
    in_payload.uop_vpu_vta                          = io_in_bits_uop_vpu_vta;
    in_payload.uop_vpu_vsew                         = io_in_bits_uop_vpu_vsew;
    in_payload.uop_vpu_vlmul                        = io_in_bits_uop_vpu_vlmul;
    in_payload.uop_vpu_specVill                     = io_in_bits_uop_vpu_specVill;
    in_payload.uop_vpu_specVma                      = io_in_bits_uop_vpu_specVma;
    in_payload.uop_vpu_specVta                      = io_in_bits_uop_vpu_specVta;
    in_payload.uop_vpu_specVsew                     = io_in_bits_uop_vpu_specVsew;
    in_payload.uop_vpu_specVlmul                    = io_in_bits_uop_vpu_specVlmul;
    in_payload.uop_vpu_vm                           = io_in_bits_uop_vpu_vm;
    in_payload.uop_vpu_vstart                       = io_in_bits_uop_vpu_vstart;
    in_payload.uop_vpu_frm                          = io_in_bits_uop_vpu_frm;
    in_payload.uop_vpu_fpu_isFpToVecInst            = io_in_bits_uop_vpu_fpu_isFpToVecInst;
    in_payload.uop_vpu_fpu_isFP32Instr              = io_in_bits_uop_vpu_fpu_isFP32Instr;
    in_payload.uop_vpu_fpu_isFP64Instr              = io_in_bits_uop_vpu_fpu_isFP64Instr;
    in_payload.uop_vpu_fpu_isReduction              = io_in_bits_uop_vpu_fpu_isReduction;
    in_payload.uop_vpu_fpu_isFoldTo1_2              = io_in_bits_uop_vpu_fpu_isFoldTo1_2;
    in_payload.uop_vpu_fpu_isFoldTo1_4              = io_in_bits_uop_vpu_fpu_isFoldTo1_4;
    in_payload.uop_vpu_fpu_isFoldTo1_8              = io_in_bits_uop_vpu_fpu_isFoldTo1_8;
    in_payload.uop_vpu_vxrm                         = io_in_bits_uop_vpu_vxrm;
    in_payload.uop_vpu_vuopIdx                      = io_in_bits_uop_vpu_vuopIdx;
    in_payload.uop_vpu_lastUop                      = io_in_bits_uop_vpu_lastUop;
    in_payload.uop_vpu_vmask                        = io_in_bits_uop_vpu_vmask;
    in_payload.uop_vpu_vl                           = io_in_bits_uop_vpu_vl;
    in_payload.uop_vpu_nf                           = io_in_bits_uop_vpu_nf;
    in_payload.uop_vpu_veew                         = io_in_bits_uop_vpu_veew;
    in_payload.uop_vpu_isReverse                    = io_in_bits_uop_vpu_isReverse;
    in_payload.uop_vpu_isExt                        = io_in_bits_uop_vpu_isExt;
    in_payload.uop_vpu_isNarrow                     = io_in_bits_uop_vpu_isNarrow;
    in_payload.uop_vpu_isDstMask                    = io_in_bits_uop_vpu_isDstMask;
    in_payload.uop_vpu_isOpMask                     = io_in_bits_uop_vpu_isOpMask;
    in_payload.uop_vpu_isMove                       = io_in_bits_uop_vpu_isMove;
    in_payload.uop_vpu_isDependOldVd                = io_in_bits_uop_vpu_isDependOldVd;
    in_payload.uop_vpu_isWritePartVd                = io_in_bits_uop_vpu_isWritePartVd;
    in_payload.uop_vpu_isVleff                      = io_in_bits_uop_vpu_isVleff;
    in_payload.uop_psrc_2                           = io_in_bits_uop_psrc_2;
    in_payload.uop_pdest                            = io_in_bits_uop_pdest;
    in_payload.uop_robIdx_flag                      = io_in_bits_uop_robIdx_flag;
    in_payload.uop_robIdx_value                     = io_in_bits_uop_robIdx_value;
    in_payload.uop_debugInfo_eliminatedMove         = io_in_bits_uop_debugInfo_eliminatedMove;
    in_payload.uop_debugInfo_renameTime             = io_in_bits_uop_debugInfo_renameTime;
    in_payload.uop_debugInfo_dispatchTime           = io_in_bits_uop_debugInfo_dispatchTime;
    in_payload.uop_debugInfo_enqRsTime              = io_in_bits_uop_debugInfo_enqRsTime;
    in_payload.uop_debugInfo_selectTime             = io_in_bits_uop_debugInfo_selectTime;
    in_payload.uop_debugInfo_issueTime              = io_in_bits_uop_debugInfo_issueTime;
    in_payload.uop_debugInfo_writebackTime          = io_in_bits_uop_debugInfo_writebackTime;
    in_payload.uop_debugInfo_runahead_checkpoint_id = io_in_bits_uop_debugInfo_runahead_checkpoint_id;
    in_payload.uop_debugInfo_tlbFirstReqTime        = io_in_bits_uop_debugInfo_tlbFirstReqTime;
    in_payload.uop_debugInfo_tlbRespTime            = io_in_bits_uop_debugInfo_tlbRespTime;
    in_payload.uop_debug_seqNum_seqNum              = io_in_bits_uop_debug_seqNum_seqNum;
    in_payload.uop_debug_seqNum_uopIdx              = io_in_bits_uop_debug_seqNum_uopIdx;
    in_payload.uop_replayInst                       = io_in_bits_uop_replayInst;
    in_payload.data                                 = io_in_bits_data;
    in_payload.vdIdx                                = io_in_bits_vdIdx;
    in_payload.vdIdxInField                         = io_in_bits_vdIdxInField;
  end

  // 出口拆包：struct 成员 -> 端口（同名逐项）
  assign io_out_bits_uop_exceptionVec_3                   = out_payload.uop_exceptionVec_3;
  assign io_out_bits_uop_exceptionVec_4                   = out_payload.uop_exceptionVec_4;
  assign io_out_bits_uop_exceptionVec_5                   = out_payload.uop_exceptionVec_5;
  assign io_out_bits_uop_exceptionVec_6                   = out_payload.uop_exceptionVec_6;
  assign io_out_bits_uop_exceptionVec_7                   = out_payload.uop_exceptionVec_7;
  assign io_out_bits_uop_exceptionVec_13                  = out_payload.uop_exceptionVec_13;
  assign io_out_bits_uop_exceptionVec_15                  = out_payload.uop_exceptionVec_15;
  assign io_out_bits_uop_exceptionVec_19                  = out_payload.uop_exceptionVec_19;
  assign io_out_bits_uop_exceptionVec_21                  = out_payload.uop_exceptionVec_21;
  assign io_out_bits_uop_exceptionVec_23                  = out_payload.uop_exceptionVec_23;
  assign io_out_bits_uop_trigger                          = out_payload.uop_trigger;
  assign io_out_bits_uop_fuOpType                         = out_payload.uop_fuOpType;
  assign io_out_bits_uop_vecWen                           = out_payload.uop_vecWen;
  assign io_out_bits_uop_v0Wen                            = out_payload.uop_v0Wen;
  assign io_out_bits_uop_vlWen                            = out_payload.uop_vlWen;
  assign io_out_bits_uop_flushPipe                        = out_payload.uop_flushPipe;
  assign io_out_bits_uop_vpu_vill                         = out_payload.uop_vpu_vill;
  assign io_out_bits_uop_vpu_vma                          = out_payload.uop_vpu_vma;
  assign io_out_bits_uop_vpu_vta                          = out_payload.uop_vpu_vta;
  assign io_out_bits_uop_vpu_vsew                         = out_payload.uop_vpu_vsew;
  assign io_out_bits_uop_vpu_vlmul                        = out_payload.uop_vpu_vlmul;
  assign io_out_bits_uop_vpu_specVill                     = out_payload.uop_vpu_specVill;
  assign io_out_bits_uop_vpu_specVma                      = out_payload.uop_vpu_specVma;
  assign io_out_bits_uop_vpu_specVta                      = out_payload.uop_vpu_specVta;
  assign io_out_bits_uop_vpu_specVsew                     = out_payload.uop_vpu_specVsew;
  assign io_out_bits_uop_vpu_specVlmul                    = out_payload.uop_vpu_specVlmul;
  assign io_out_bits_uop_vpu_vm                           = out_payload.uop_vpu_vm;
  assign io_out_bits_uop_vpu_vstart                       = out_payload.uop_vpu_vstart;
  assign io_out_bits_uop_vpu_frm                          = out_payload.uop_vpu_frm;
  assign io_out_bits_uop_vpu_fpu_isFpToVecInst            = out_payload.uop_vpu_fpu_isFpToVecInst;
  assign io_out_bits_uop_vpu_fpu_isFP32Instr              = out_payload.uop_vpu_fpu_isFP32Instr;
  assign io_out_bits_uop_vpu_fpu_isFP64Instr              = out_payload.uop_vpu_fpu_isFP64Instr;
  assign io_out_bits_uop_vpu_fpu_isReduction              = out_payload.uop_vpu_fpu_isReduction;
  assign io_out_bits_uop_vpu_fpu_isFoldTo1_2              = out_payload.uop_vpu_fpu_isFoldTo1_2;
  assign io_out_bits_uop_vpu_fpu_isFoldTo1_4              = out_payload.uop_vpu_fpu_isFoldTo1_4;
  assign io_out_bits_uop_vpu_fpu_isFoldTo1_8              = out_payload.uop_vpu_fpu_isFoldTo1_8;
  assign io_out_bits_uop_vpu_vxrm                         = out_payload.uop_vpu_vxrm;
  assign io_out_bits_uop_vpu_vuopIdx                      = out_payload.uop_vpu_vuopIdx;
  assign io_out_bits_uop_vpu_lastUop                      = out_payload.uop_vpu_lastUop;
  assign io_out_bits_uop_vpu_vmask                        = out_payload.uop_vpu_vmask;
  assign io_out_bits_uop_vpu_vl                           = out_payload.uop_vpu_vl;
  assign io_out_bits_uop_vpu_nf                           = out_payload.uop_vpu_nf;
  assign io_out_bits_uop_vpu_veew                         = out_payload.uop_vpu_veew;
  assign io_out_bits_uop_vpu_isReverse                    = out_payload.uop_vpu_isReverse;
  assign io_out_bits_uop_vpu_isExt                        = out_payload.uop_vpu_isExt;
  assign io_out_bits_uop_vpu_isNarrow                     = out_payload.uop_vpu_isNarrow;
  assign io_out_bits_uop_vpu_isDstMask                    = out_payload.uop_vpu_isDstMask;
  assign io_out_bits_uop_vpu_isOpMask                     = out_payload.uop_vpu_isOpMask;
  assign io_out_bits_uop_vpu_isMove                       = out_payload.uop_vpu_isMove;
  assign io_out_bits_uop_vpu_isDependOldVd                = out_payload.uop_vpu_isDependOldVd;
  assign io_out_bits_uop_vpu_isWritePartVd                = out_payload.uop_vpu_isWritePartVd;
  assign io_out_bits_uop_vpu_isVleff                      = out_payload.uop_vpu_isVleff;
  assign io_out_bits_uop_psrc_2                           = out_payload.uop_psrc_2;
  assign io_out_bits_uop_pdest                            = out_payload.uop_pdest;
  assign io_out_bits_uop_robIdx_flag                      = out_payload.uop_robIdx_flag;
  assign io_out_bits_uop_robIdx_value                     = out_payload.uop_robIdx_value;
  assign io_out_bits_uop_debugInfo_eliminatedMove         = out_payload.uop_debugInfo_eliminatedMove;
  assign io_out_bits_uop_debugInfo_renameTime             = out_payload.uop_debugInfo_renameTime;
  assign io_out_bits_uop_debugInfo_dispatchTime           = out_payload.uop_debugInfo_dispatchTime;
  assign io_out_bits_uop_debugInfo_enqRsTime              = out_payload.uop_debugInfo_enqRsTime;
  assign io_out_bits_uop_debugInfo_selectTime             = out_payload.uop_debugInfo_selectTime;
  assign io_out_bits_uop_debugInfo_issueTime              = out_payload.uop_debugInfo_issueTime;
  assign io_out_bits_uop_debugInfo_writebackTime          = out_payload.uop_debugInfo_writebackTime;
  assign io_out_bits_uop_debugInfo_runahead_checkpoint_id = out_payload.uop_debugInfo_runahead_checkpoint_id;
  assign io_out_bits_uop_debugInfo_tlbFirstReqTime        = out_payload.uop_debugInfo_tlbFirstReqTime;
  assign io_out_bits_uop_debugInfo_tlbRespTime            = out_payload.uop_debugInfo_tlbRespTime;
  assign io_out_bits_uop_debug_seqNum_seqNum              = out_payload.uop_debug_seqNum_seqNum;
  assign io_out_bits_uop_debug_seqNum_uopIdx              = out_payload.uop_debug_seqNum_uopIdx;
  assign io_out_bits_uop_replayInst                       = out_payload.uop_replayInst;
  assign io_out_bits_data                                 = out_payload.data;
  assign io_out_bits_vdIdx                                = out_payload.vdIdx;
  assign io_out_bits_vdIdxInField                         = out_payload.vdIdxInField;

  // ---------------------------------------------------------------------------
  // elaborate 期位宽不变式。
  //
  // 本轮反复出事的形态是「逻辑全对、只有某个字段位宽停在旧基线」：随机激励未必
  // 打到高位，UT 照样 errors=0，要等 FM 才炸。这里把它提前到 time 0。
  // 判据：入口端口位宽之和 == 出口端口位宽之和 == PAYLOAD_W_G1 == $bits(payload_t)。
  // 任何一个端口或 struct 成员的位宽被改动，这四个数就不再相等（后两项由共享核
  // 里的 initial 负责）。「两处互相抵消的改动」逃得过位宽和，但逃不过
  // scripts/port_contract_lint.py（逐端口比 G1 golden）与 UT 的逐拍输出比对。
  // ---------------------------------------------------------------------------
  localparam int unsigned IN_PORT_BITS =
   $bits(io_in_bits_uop_exceptionVec_3) + $bits(io_in_bits_uop_exceptionVec_4) + $bits(io_in_bits_uop_exceptionVec_5) + $bits(io_in_bits_uop_exceptionVec_6) +
   $bits(io_in_bits_uop_exceptionVec_7) + $bits(io_in_bits_uop_exceptionVec_13) + $bits(io_in_bits_uop_exceptionVec_15) + $bits(io_in_bits_uop_exceptionVec_19) +
   $bits(io_in_bits_uop_exceptionVec_21) + $bits(io_in_bits_uop_exceptionVec_23) + $bits(io_in_bits_uop_trigger) + $bits(io_in_bits_uop_fuOpType) +
   $bits(io_in_bits_uop_vecWen) + $bits(io_in_bits_uop_v0Wen) + $bits(io_in_bits_uop_vlWen) + $bits(io_in_bits_uop_flushPipe) +
   $bits(io_in_bits_uop_vpu_vill) + $bits(io_in_bits_uop_vpu_vma) + $bits(io_in_bits_uop_vpu_vta) + $bits(io_in_bits_uop_vpu_vsew) +
   $bits(io_in_bits_uop_vpu_vlmul) + $bits(io_in_bits_uop_vpu_specVill) + $bits(io_in_bits_uop_vpu_specVma) + $bits(io_in_bits_uop_vpu_specVta) +
   $bits(io_in_bits_uop_vpu_specVsew) + $bits(io_in_bits_uop_vpu_specVlmul) + $bits(io_in_bits_uop_vpu_vm) + $bits(io_in_bits_uop_vpu_vstart) +
   $bits(io_in_bits_uop_vpu_frm) + $bits(io_in_bits_uop_vpu_fpu_isFpToVecInst) + $bits(io_in_bits_uop_vpu_fpu_isFP32Instr) + $bits(io_in_bits_uop_vpu_fpu_isFP64Instr) +
   $bits(io_in_bits_uop_vpu_fpu_isReduction) + $bits(io_in_bits_uop_vpu_fpu_isFoldTo1_2) + $bits(io_in_bits_uop_vpu_fpu_isFoldTo1_4) + $bits(io_in_bits_uop_vpu_fpu_isFoldTo1_8) +
   $bits(io_in_bits_uop_vpu_vxrm) + $bits(io_in_bits_uop_vpu_vuopIdx) + $bits(io_in_bits_uop_vpu_lastUop) + $bits(io_in_bits_uop_vpu_vmask) +
   $bits(io_in_bits_uop_vpu_vl) + $bits(io_in_bits_uop_vpu_nf) + $bits(io_in_bits_uop_vpu_veew) + $bits(io_in_bits_uop_vpu_isReverse) +
   $bits(io_in_bits_uop_vpu_isExt) + $bits(io_in_bits_uop_vpu_isNarrow) + $bits(io_in_bits_uop_vpu_isDstMask) + $bits(io_in_bits_uop_vpu_isOpMask) +
   $bits(io_in_bits_uop_vpu_isMove) + $bits(io_in_bits_uop_vpu_isDependOldVd) + $bits(io_in_bits_uop_vpu_isWritePartVd) + $bits(io_in_bits_uop_vpu_isVleff) +
   $bits(io_in_bits_uop_psrc_2) + $bits(io_in_bits_uop_pdest) + $bits(io_in_bits_uop_robIdx_flag) + $bits(io_in_bits_uop_robIdx_value) +
   $bits(io_in_bits_uop_debugInfo_eliminatedMove) + $bits(io_in_bits_uop_debugInfo_renameTime) + $bits(io_in_bits_uop_debugInfo_dispatchTime) + $bits(io_in_bits_uop_debugInfo_enqRsTime) +
   $bits(io_in_bits_uop_debugInfo_selectTime) + $bits(io_in_bits_uop_debugInfo_issueTime) + $bits(io_in_bits_uop_debugInfo_writebackTime) + $bits(io_in_bits_uop_debugInfo_runahead_checkpoint_id) +
   $bits(io_in_bits_uop_debugInfo_tlbFirstReqTime) + $bits(io_in_bits_uop_debugInfo_tlbRespTime) + $bits(io_in_bits_uop_debug_seqNum_seqNum) + $bits(io_in_bits_uop_debug_seqNum_uopIdx) +
   $bits(io_in_bits_uop_replayInst) + $bits(io_in_bits_data) + $bits(io_in_bits_vdIdx) + $bits(io_in_bits_vdIdxInField);
  localparam int unsigned OUT_PORT_BITS =
   $bits(io_out_bits_uop_exceptionVec_3) + $bits(io_out_bits_uop_exceptionVec_4) + $bits(io_out_bits_uop_exceptionVec_5) + $bits(io_out_bits_uop_exceptionVec_6) +
   $bits(io_out_bits_uop_exceptionVec_7) + $bits(io_out_bits_uop_exceptionVec_13) + $bits(io_out_bits_uop_exceptionVec_15) + $bits(io_out_bits_uop_exceptionVec_19) +
   $bits(io_out_bits_uop_exceptionVec_21) + $bits(io_out_bits_uop_exceptionVec_23) + $bits(io_out_bits_uop_trigger) + $bits(io_out_bits_uop_fuOpType) +
   $bits(io_out_bits_uop_vecWen) + $bits(io_out_bits_uop_v0Wen) + $bits(io_out_bits_uop_vlWen) + $bits(io_out_bits_uop_flushPipe) +
   $bits(io_out_bits_uop_vpu_vill) + $bits(io_out_bits_uop_vpu_vma) + $bits(io_out_bits_uop_vpu_vta) + $bits(io_out_bits_uop_vpu_vsew) +
   $bits(io_out_bits_uop_vpu_vlmul) + $bits(io_out_bits_uop_vpu_specVill) + $bits(io_out_bits_uop_vpu_specVma) + $bits(io_out_bits_uop_vpu_specVta) +
   $bits(io_out_bits_uop_vpu_specVsew) + $bits(io_out_bits_uop_vpu_specVlmul) + $bits(io_out_bits_uop_vpu_vm) + $bits(io_out_bits_uop_vpu_vstart) +
   $bits(io_out_bits_uop_vpu_frm) + $bits(io_out_bits_uop_vpu_fpu_isFpToVecInst) + $bits(io_out_bits_uop_vpu_fpu_isFP32Instr) + $bits(io_out_bits_uop_vpu_fpu_isFP64Instr) +
   $bits(io_out_bits_uop_vpu_fpu_isReduction) + $bits(io_out_bits_uop_vpu_fpu_isFoldTo1_2) + $bits(io_out_bits_uop_vpu_fpu_isFoldTo1_4) + $bits(io_out_bits_uop_vpu_fpu_isFoldTo1_8) +
   $bits(io_out_bits_uop_vpu_vxrm) + $bits(io_out_bits_uop_vpu_vuopIdx) + $bits(io_out_bits_uop_vpu_lastUop) + $bits(io_out_bits_uop_vpu_vmask) +
   $bits(io_out_bits_uop_vpu_vl) + $bits(io_out_bits_uop_vpu_nf) + $bits(io_out_bits_uop_vpu_veew) + $bits(io_out_bits_uop_vpu_isReverse) +
   $bits(io_out_bits_uop_vpu_isExt) + $bits(io_out_bits_uop_vpu_isNarrow) + $bits(io_out_bits_uop_vpu_isDstMask) + $bits(io_out_bits_uop_vpu_isOpMask) +
   $bits(io_out_bits_uop_vpu_isMove) + $bits(io_out_bits_uop_vpu_isDependOldVd) + $bits(io_out_bits_uop_vpu_isWritePartVd) + $bits(io_out_bits_uop_vpu_isVleff) +
   $bits(io_out_bits_uop_psrc_2) + $bits(io_out_bits_uop_pdest) + $bits(io_out_bits_uop_robIdx_flag) + $bits(io_out_bits_uop_robIdx_value) +
   $bits(io_out_bits_uop_debugInfo_eliminatedMove) + $bits(io_out_bits_uop_debugInfo_renameTime) + $bits(io_out_bits_uop_debugInfo_dispatchTime) + $bits(io_out_bits_uop_debugInfo_enqRsTime) +
   $bits(io_out_bits_uop_debugInfo_selectTime) + $bits(io_out_bits_uop_debugInfo_issueTime) + $bits(io_out_bits_uop_debugInfo_writebackTime) + $bits(io_out_bits_uop_debugInfo_runahead_checkpoint_id) +
   $bits(io_out_bits_uop_debugInfo_tlbFirstReqTime) + $bits(io_out_bits_uop_debugInfo_tlbRespTime) + $bits(io_out_bits_uop_debug_seqNum_seqNum) + $bits(io_out_bits_uop_debug_seqNum_uopIdx) +
   $bits(io_out_bits_uop_replayInst) + $bits(io_out_bits_data) + $bits(io_out_bits_vdIdx) + $bits(io_out_bits_vdIdxInField);

  initial begin
    if (IN_PORT_BITS != PAYLOAD_W_G1)
      $fatal(1, "NewPipelineConnectPipe_29: 入口端口位宽之和 %0d != G1 golden 的 %0d 位",
             IN_PORT_BITS, PAYLOAD_W_G1);
    if (OUT_PORT_BITS != PAYLOAD_W_G1)
      $fatal(1, "NewPipelineConnectPipe_29: 出口端口位宽之和 %0d != G1 golden 的 %0d 位",
             OUT_PORT_BITS, PAYLOAD_W_G1);
  end

  // 共享核：本文件不含任何流水/握手逻辑，全部在 xs_PipelineConnect 里。
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

endmodule
