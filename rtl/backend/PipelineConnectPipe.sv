// PipelineConnectPipe.sv — CtrlBlock 里译码(DecodeStage)→重命名(Rename)之间的单拍流水缓冲。
// 例化点（G1 golden）：CtrlBlock.decodePipeRenameModule ~ decodePipeRenameModule_5，
//   6 条译码 lane 各一个，**同一个模块例化 6 次**（一个 FM target）。
// 层次：CtrlBlock 的直接 child，0 子模块；golden 848 行 / 235 端口（113 输入 / 122 输出）。
//
// 核心机制（老式 PipelineConnect，与 NewPipelineConnectPipe 家族**不同**，不能共用
//   rtl/common/PipelineConnect.sv 那个核）：
//   in_ready = out_ready                       —— 直通下游 ready，没有"空即可收"项
//   fire     = in_valid & out_ready
//   valid'   = ~isFlush & (fire | ~rightOutFire & valid)   （异步复位清 0）
//   data     = RegEnable(in_bits, fire)         —— 全部字段打拍，无组合直通
//   rightOutFire 由调用方给（CtrlBlock 接的是 rename 侧的 fire），与 out_ready 不必同步。
//
// ★payload 里 13 个字段只有出口没有入口★（lsrc_3 / lsrc_4 / vpu_frm / vpu_fpu_isFpToVecInst / vpu_fpu_isFP32Instr / vpu_fpu_isFP64Instr / vpu_fpu_isReduction / vpu_vxrm / vpu_vuopIdx / vpu_lastUop / vpu_vmask / vpu_vl / vpu_isMove）：
//   上游 DecodeStage 把它们写成常量 0，firtool 把入口端口折掉了，但寄存器还在——
//   golden 写成 `data_x <= 0`（fire 拍）或 `data_x <= ~leftFire & data_x`，两种写法
//   都是"fire 拍装 0、其余拍保持"。bug-for-bug：这些字段进 payload、入口恒接 0，
//   寄存器与 golden 一一对应（复位前为 X，首个 fire 后恒 0，与 golden 一致）。
//   payload 合计 120 字段 / 617 位 = 入口 451 位 + 恒 0 字段 166 位。
//
// 本文件由 scripts/gen_cb_connect.py 从 G1 golden 端口表生成，勿手改；
// golden 对照：G1-canonical/golden-rtl/PipelineConnectPipe.sv。

// ============================================================================
// package：payload 布局。用 packed struct 而不是手工位切片：入口打包与出口拆包都按
// 同一组成员名访问，字段错位在结构上就不可能发生。成员顺序照 golden 出口端口表。
// ============================================================================
package pipelineconnectpipe_pkg;
  typedef struct packed {
    // 取指结果：指令字 / PC / 折叠 PC
    logic [31:0]    instr;
    logic [49:0]    pc;
    logic [9:0]     foldpc;
    // exceptionVec：24 位异常向量（逐位一个端口）
    logic           exceptionVec_0;
    logic           exceptionVec_1;
    logic           exceptionVec_2;
    logic           exceptionVec_3;
    logic           exceptionVec_4;
    logic           exceptionVec_5;
    logic           exceptionVec_6;
    logic           exceptionVec_7;
    logic           exceptionVec_8;
    logic           exceptionVec_9;
    logic           exceptionVec_10;
    logic           exceptionVec_11;
    logic           exceptionVec_12;
    logic           exceptionVec_13;
    logic           exceptionVec_14;
    logic           exceptionVec_15;
    logic           exceptionVec_16;
    logic           exceptionVec_17;
    logic           exceptionVec_18;
    logic           exceptionVec_19;
    logic           exceptionVec_20;
    logic           exceptionVec_21;
    logic           exceptionVec_22;
    logic           exceptionVec_23;
    // 取指异常汇总与触发器动作
    logic           isFetchMalAddr;
    logic [3:0]     trigger;
    // preDecodeInfo：前端预译码信息（分支类型/call/ret/RVC）
    logic           preDecodeInfo_valid;
    logic           preDecodeInfo_isRVC;
    logic [1:0]     preDecodeInfo_brType;
    logic           preDecodeInfo_isCall;
    logic           preDecodeInfo_isRet;
    // 分支预测结果与跨页取指异常修正
    logic           pred_taken;
    logic           crossPageIPFFix;
    // ftqPtr/ftqOffset：取指队列指针（flag=回绕位）与块内偏移
    logic           ftqPtr_flag;
    logic [5:0]     ftqPtr_value;
    logic [3:0]     ftqOffset;
    // 分支预测结果与跨页取指异常修正（续）
    logic           satpFlushFirstFetchFault;
    // srcType：5 个源操作数的类型编码
    logic [3:0]     srcType_0;
    logic [3:0]     srcType_1;
    logic [3:0]     srcType_2;
    logic [3:0]     srcType_3;
    logic [3:0]     srcType_4;
    // lsrc/ldest：逻辑寄存器号
    logic [5:0]     lsrc_0;
    logic [5:0]     lsrc_1;
    logic [5:0]     lsrc_2;
    logic [5:0]     lsrc_3;
    logic [5:0]     lsrc_4;
    logic [5:0]     ldest;
    // 译码控制位：功能单元类型与操作 / 写使能 / 顺序约束 / 立即数
    logic [34:0]    fuType;
    logic [8:0]     fuOpType;
    logic           rfWen;
    logic           fpWen;
    logic           vecWen;
    logic           v0Wen;
    logic           vlWen;
    logic           isXSTrap;
    logic           waitForward;
    logic           blockBackward;
    logic           flushPipe;
    logic           canRobCompress;
    logic [3:0]     selImm;
    logic [21:0]    imm;
    // fpu：标量浮点控制（typeTag/wflags/typ/fmt/rm）
    logic [1:0]     fpu_typeTagOut;
    logic           fpu_wflags;
    logic [1:0]     fpu_typ;
    logic [1:0]     fpu_fmt;
    logic [2:0]     fpu_rm;
    // vpu：向量控制（vtype 及其 spec 副本 / vstart / vmask / vl / 向量 uop 属性）
    logic           vpu_vill;
    logic           vpu_vma;
    logic           vpu_vta;
    logic [1:0]     vpu_vsew;
    logic [2:0]     vpu_vlmul;
    logic           vpu_specVill;
    logic           vpu_specVma;
    logic           vpu_specVta;
    logic [1:0]     vpu_specVsew;
    logic [2:0]     vpu_specVlmul;
    logic           vpu_vm;
    logic [7:0]     vpu_vstart;
    logic [2:0]     vpu_frm;
    logic           vpu_fpu_isFpToVecInst;
    logic           vpu_fpu_isFP32Instr;
    logic           vpu_fpu_isFP64Instr;
    logic           vpu_fpu_isReduction;
    logic           vpu_fpu_isFoldTo1_2;
    logic           vpu_fpu_isFoldTo1_4;
    logic           vpu_fpu_isFoldTo1_8;
    logic [1:0]     vpu_vxrm;
    logic [6:0]     vpu_vuopIdx;
    logic           vpu_lastUop;
    logic [127:0]   vpu_vmask;
    logic [7:0]     vpu_vl;
    logic [2:0]     vpu_nf;
    logic [1:0]     vpu_veew;
    logic           vpu_isReverse;
    logic           vpu_isExt;
    logic           vpu_isNarrow;
    logic           vpu_isDstMask;
    logic           vpu_isOpMask;
    logic           vpu_isMove;
    logic           vpu_isDependOldVd;
    logic           vpu_isWritePartVd;
    logic           vpu_isVleff;
    // uop 拆分信息与提交类型
    logic           vlsInstr;
    logic           wfflags;
    logic           isMove;
    logic [6:0]     uopIdx;
    logic [5:0]     uopSplitType;
    logic           isVset;
    logic           firstUop;
    logic           lastUop;
    logic [6:0]     numUops;
    logic [6:0]     numWB;
    logic [2:0]     commitType;
    // debug_*：调试用透传字段（fuType 副本 / 序号 / sim 触发）
    logic [34:0]    debug_fuType;
    logic [55:0]    debug_seqNum_seqNum;
    logic [7:0]     debug_seqNum_uopIdx;
  } payload_t;

  // G1 golden 出口端口（= 数据寄存器）位宽之和，传给核做 elaborate 期防呆。
  localparam int unsigned PAYLOAD_W_G1 = 617;
endpackage

// ============================================================================
// 核：valid 寄存器 + RegEnable 数据寄存器 + 老式握手。payload 当一坨位搬运。
// ============================================================================
module xs_PipelineConnectPipe_core #(
  parameter int unsigned DATA_WIDTH   = 1,
  // G1 锚点（fail-closed）：wrapper 把 PAYLOAD_W_G1 原样传进来，核校验它 == 实际 payload
  // 位数。默认 0 = 没传，直接 $fatal（不给"不传即不校验"留路）。
  parameter int unsigned PAYLOAD_W_G1 = 0
)(
  input  logic                  clock,
  input  logic                  reset,          // 异步高有效，仅复位 valid
  output logic                  io_in_ready,
  input  logic                  io_in_valid,
  input  logic [DATA_WIDTH-1:0] io_in_bits,
  input  logic                  io_out_ready,
  output logic                  io_out_valid,
  output logic [DATA_WIDTH-1:0] io_out_bits,
  input  logic                  io_rightOutFire,
  input  logic                  io_isFlush
);

  // elaborate 期参数自检（模块体里的 $fatal：VCS 在 elaborate 阶段就拦，Formality 读得进）。
  if (PAYLOAD_W_G1 == 0)
    $fatal(1, "xs_PipelineConnectPipe_core: wrapper must pass PAYLOAD_W_G1 (sum of G1 golden io_out_bits_* widths); DATA_WIDTH=%0d",
           DATA_WIDTH);
  if (DATA_WIDTH != PAYLOAD_W_G1)
    $fatal(1, "xs_PipelineConnectPipe_core: packed payload is %0d bits != G1 golden sum %0d bits -- struct and G1 port table diverged",
           DATA_WIDTH, PAYLOAD_W_G1);

  logic                  valid;
  logic [DATA_WIDTH-1:0] data;
  logic                  fire;

  // 老式握手：ready 直通，不看本级是否为空。
  assign io_in_ready = io_out_ready;
  assign fire        = io_in_valid & io_out_ready;

  always_ff @(posedge clock or posedge reset) begin
    if (reset) valid <= 1'b0;
    else       valid <= ~io_isFlush & (fire | (~io_rightOutFire & valid));
  end

  always_ff @(posedge clock) begin
    if (fire) data <= io_in_bits;
  end

  assign io_out_valid = valid;
  assign io_out_bits  = data;

endmodule

// ============================================================================
// wrapper：golden 同名同端口。只做打包/拆包 + 位宽不变式，不含任何握手逻辑。
// ============================================================================
module PipelineConnectPipe import pipelineconnectpipe_pkg::*; (
  input  logic clock,
  input  logic reset,
  output logic io_in_ready,
  input  logic io_in_valid,
  input  logic [31:0] io_in_bits_instr,
  input  logic [49:0] io_in_bits_pc,
  input  logic [9:0] io_in_bits_foldpc,
  input  logic io_in_bits_exceptionVec_0,
  input  logic io_in_bits_exceptionVec_1,
  input  logic io_in_bits_exceptionVec_2,
  input  logic io_in_bits_exceptionVec_3,
  input  logic io_in_bits_exceptionVec_4,
  input  logic io_in_bits_exceptionVec_5,
  input  logic io_in_bits_exceptionVec_6,
  input  logic io_in_bits_exceptionVec_7,
  input  logic io_in_bits_exceptionVec_8,
  input  logic io_in_bits_exceptionVec_9,
  input  logic io_in_bits_exceptionVec_10,
  input  logic io_in_bits_exceptionVec_11,
  input  logic io_in_bits_exceptionVec_12,
  input  logic io_in_bits_exceptionVec_13,
  input  logic io_in_bits_exceptionVec_14,
  input  logic io_in_bits_exceptionVec_15,
  input  logic io_in_bits_exceptionVec_16,
  input  logic io_in_bits_exceptionVec_17,
  input  logic io_in_bits_exceptionVec_18,
  input  logic io_in_bits_exceptionVec_19,
  input  logic io_in_bits_exceptionVec_20,
  input  logic io_in_bits_exceptionVec_21,
  input  logic io_in_bits_exceptionVec_22,
  input  logic io_in_bits_exceptionVec_23,
  input  logic io_in_bits_isFetchMalAddr,
  input  logic [3:0] io_in_bits_trigger,
  input  logic io_in_bits_preDecodeInfo_valid,
  input  logic io_in_bits_preDecodeInfo_isRVC,
  input  logic [1:0] io_in_bits_preDecodeInfo_brType,
  input  logic io_in_bits_preDecodeInfo_isCall,
  input  logic io_in_bits_preDecodeInfo_isRet,
  input  logic io_in_bits_pred_taken,
  input  logic io_in_bits_crossPageIPFFix,
  input  logic io_in_bits_ftqPtr_flag,
  input  logic [5:0] io_in_bits_ftqPtr_value,
  input  logic [3:0] io_in_bits_ftqOffset,
  input  logic io_in_bits_satpFlushFirstFetchFault,
  input  logic [3:0] io_in_bits_srcType_0,
  input  logic [3:0] io_in_bits_srcType_1,
  input  logic [3:0] io_in_bits_srcType_2,
  input  logic [3:0] io_in_bits_srcType_3,
  input  logic [3:0] io_in_bits_srcType_4,
  input  logic [5:0] io_in_bits_lsrc_0,
  input  logic [5:0] io_in_bits_lsrc_1,
  input  logic [5:0] io_in_bits_lsrc_2,
  input  logic [5:0] io_in_bits_ldest,
  input  logic [34:0] io_in_bits_fuType,
  input  logic [8:0] io_in_bits_fuOpType,
  input  logic io_in_bits_rfWen,
  input  logic io_in_bits_fpWen,
  input  logic io_in_bits_vecWen,
  input  logic io_in_bits_v0Wen,
  input  logic io_in_bits_vlWen,
  input  logic io_in_bits_isXSTrap,
  input  logic io_in_bits_waitForward,
  input  logic io_in_bits_blockBackward,
  input  logic io_in_bits_flushPipe,
  input  logic io_in_bits_canRobCompress,
  input  logic [3:0] io_in_bits_selImm,
  input  logic [21:0] io_in_bits_imm,
  input  logic [1:0] io_in_bits_fpu_typeTagOut,
  input  logic io_in_bits_fpu_wflags,
  input  logic [1:0] io_in_bits_fpu_typ,
  input  logic [1:0] io_in_bits_fpu_fmt,
  input  logic [2:0] io_in_bits_fpu_rm,
  input  logic io_in_bits_vpu_vill,
  input  logic io_in_bits_vpu_vma,
  input  logic io_in_bits_vpu_vta,
  input  logic [1:0] io_in_bits_vpu_vsew,
  input  logic [2:0] io_in_bits_vpu_vlmul,
  input  logic io_in_bits_vpu_specVill,
  input  logic io_in_bits_vpu_specVma,
  input  logic io_in_bits_vpu_specVta,
  input  logic [1:0] io_in_bits_vpu_specVsew,
  input  logic [2:0] io_in_bits_vpu_specVlmul,
  input  logic io_in_bits_vpu_vm,
  input  logic [7:0] io_in_bits_vpu_vstart,
  input  logic io_in_bits_vpu_fpu_isFoldTo1_2,
  input  logic io_in_bits_vpu_fpu_isFoldTo1_4,
  input  logic io_in_bits_vpu_fpu_isFoldTo1_8,
  input  logic [2:0] io_in_bits_vpu_nf,
  input  logic [1:0] io_in_bits_vpu_veew,
  input  logic io_in_bits_vpu_isReverse,
  input  logic io_in_bits_vpu_isExt,
  input  logic io_in_bits_vpu_isNarrow,
  input  logic io_in_bits_vpu_isDstMask,
  input  logic io_in_bits_vpu_isOpMask,
  input  logic io_in_bits_vpu_isDependOldVd,
  input  logic io_in_bits_vpu_isWritePartVd,
  input  logic io_in_bits_vpu_isVleff,
  input  logic io_in_bits_vlsInstr,
  input  logic io_in_bits_wfflags,
  input  logic io_in_bits_isMove,
  input  logic [6:0] io_in_bits_uopIdx,
  input  logic [5:0] io_in_bits_uopSplitType,
  input  logic io_in_bits_isVset,
  input  logic io_in_bits_firstUop,
  input  logic io_in_bits_lastUop,
  input  logic [6:0] io_in_bits_numUops,
  input  logic [6:0] io_in_bits_numWB,
  input  logic [2:0] io_in_bits_commitType,
  input  logic [34:0] io_in_bits_debug_fuType,
  input  logic [55:0] io_in_bits_debug_seqNum_seqNum,
  input  logic [7:0] io_in_bits_debug_seqNum_uopIdx,
  input  logic io_out_ready,
  output logic io_out_valid,
  output logic [31:0] io_out_bits_instr,
  output logic [49:0] io_out_bits_pc,
  output logic [9:0] io_out_bits_foldpc,
  output logic io_out_bits_exceptionVec_0,
  output logic io_out_bits_exceptionVec_1,
  output logic io_out_bits_exceptionVec_2,
  output logic io_out_bits_exceptionVec_3,
  output logic io_out_bits_exceptionVec_4,
  output logic io_out_bits_exceptionVec_5,
  output logic io_out_bits_exceptionVec_6,
  output logic io_out_bits_exceptionVec_7,
  output logic io_out_bits_exceptionVec_8,
  output logic io_out_bits_exceptionVec_9,
  output logic io_out_bits_exceptionVec_10,
  output logic io_out_bits_exceptionVec_11,
  output logic io_out_bits_exceptionVec_12,
  output logic io_out_bits_exceptionVec_13,
  output logic io_out_bits_exceptionVec_14,
  output logic io_out_bits_exceptionVec_15,
  output logic io_out_bits_exceptionVec_16,
  output logic io_out_bits_exceptionVec_17,
  output logic io_out_bits_exceptionVec_18,
  output logic io_out_bits_exceptionVec_19,
  output logic io_out_bits_exceptionVec_20,
  output logic io_out_bits_exceptionVec_21,
  output logic io_out_bits_exceptionVec_22,
  output logic io_out_bits_exceptionVec_23,
  output logic io_out_bits_isFetchMalAddr,
  output logic [3:0] io_out_bits_trigger,
  output logic io_out_bits_preDecodeInfo_valid,
  output logic io_out_bits_preDecodeInfo_isRVC,
  output logic [1:0] io_out_bits_preDecodeInfo_brType,
  output logic io_out_bits_preDecodeInfo_isCall,
  output logic io_out_bits_preDecodeInfo_isRet,
  output logic io_out_bits_pred_taken,
  output logic io_out_bits_crossPageIPFFix,
  output logic io_out_bits_ftqPtr_flag,
  output logic [5:0] io_out_bits_ftqPtr_value,
  output logic [3:0] io_out_bits_ftqOffset,
  output logic io_out_bits_satpFlushFirstFetchFault,
  output logic [3:0] io_out_bits_srcType_0,
  output logic [3:0] io_out_bits_srcType_1,
  output logic [3:0] io_out_bits_srcType_2,
  output logic [3:0] io_out_bits_srcType_3,
  output logic [3:0] io_out_bits_srcType_4,
  output logic [5:0] io_out_bits_lsrc_0,
  output logic [5:0] io_out_bits_lsrc_1,
  output logic [5:0] io_out_bits_lsrc_2,
  output logic [5:0] io_out_bits_lsrc_3,
  output logic [5:0] io_out_bits_lsrc_4,
  output logic [5:0] io_out_bits_ldest,
  output logic [34:0] io_out_bits_fuType,
  output logic [8:0] io_out_bits_fuOpType,
  output logic io_out_bits_rfWen,
  output logic io_out_bits_fpWen,
  output logic io_out_bits_vecWen,
  output logic io_out_bits_v0Wen,
  output logic io_out_bits_vlWen,
  output logic io_out_bits_isXSTrap,
  output logic io_out_bits_waitForward,
  output logic io_out_bits_blockBackward,
  output logic io_out_bits_flushPipe,
  output logic io_out_bits_canRobCompress,
  output logic [3:0] io_out_bits_selImm,
  output logic [21:0] io_out_bits_imm,
  output logic [1:0] io_out_bits_fpu_typeTagOut,
  output logic io_out_bits_fpu_wflags,
  output logic [1:0] io_out_bits_fpu_typ,
  output logic [1:0] io_out_bits_fpu_fmt,
  output logic [2:0] io_out_bits_fpu_rm,
  output logic io_out_bits_vpu_vill,
  output logic io_out_bits_vpu_vma,
  output logic io_out_bits_vpu_vta,
  output logic [1:0] io_out_bits_vpu_vsew,
  output logic [2:0] io_out_bits_vpu_vlmul,
  output logic io_out_bits_vpu_specVill,
  output logic io_out_bits_vpu_specVma,
  output logic io_out_bits_vpu_specVta,
  output logic [1:0] io_out_bits_vpu_specVsew,
  output logic [2:0] io_out_bits_vpu_specVlmul,
  output logic io_out_bits_vpu_vm,
  output logic [7:0] io_out_bits_vpu_vstart,
  output logic [2:0] io_out_bits_vpu_frm,
  output logic io_out_bits_vpu_fpu_isFpToVecInst,
  output logic io_out_bits_vpu_fpu_isFP32Instr,
  output logic io_out_bits_vpu_fpu_isFP64Instr,
  output logic io_out_bits_vpu_fpu_isReduction,
  output logic io_out_bits_vpu_fpu_isFoldTo1_2,
  output logic io_out_bits_vpu_fpu_isFoldTo1_4,
  output logic io_out_bits_vpu_fpu_isFoldTo1_8,
  output logic [1:0] io_out_bits_vpu_vxrm,
  output logic [6:0] io_out_bits_vpu_vuopIdx,
  output logic io_out_bits_vpu_lastUop,
  output logic [127:0] io_out_bits_vpu_vmask,
  output logic [7:0] io_out_bits_vpu_vl,
  output logic [2:0] io_out_bits_vpu_nf,
  output logic [1:0] io_out_bits_vpu_veew,
  output logic io_out_bits_vpu_isReverse,
  output logic io_out_bits_vpu_isExt,
  output logic io_out_bits_vpu_isNarrow,
  output logic io_out_bits_vpu_isDstMask,
  output logic io_out_bits_vpu_isOpMask,
  output logic io_out_bits_vpu_isMove,
  output logic io_out_bits_vpu_isDependOldVd,
  output logic io_out_bits_vpu_isWritePartVd,
  output logic io_out_bits_vpu_isVleff,
  output logic io_out_bits_vlsInstr,
  output logic io_out_bits_wfflags,
  output logic io_out_bits_isMove,
  output logic [6:0] io_out_bits_uopIdx,
  output logic [5:0] io_out_bits_uopSplitType,
  output logic io_out_bits_isVset,
  output logic io_out_bits_firstUop,
  output logic io_out_bits_lastUop,
  output logic [6:0] io_out_bits_numUops,
  output logic [6:0] io_out_bits_numWB,
  output logic [2:0] io_out_bits_commitType,
  output logic [34:0] io_out_bits_debug_fuType,
  output logic [55:0] io_out_bits_debug_seqNum_seqNum,
  output logic [7:0] io_out_bits_debug_seqNum_uopIdx,
  input  logic io_rightOutFire,
  input  logic io_isFlush
);

  payload_t in_payload, out_payload;

  // 入口打包：端口 -> struct 成员（同名逐项）
  always_comb begin
    in_payload.instr                    = io_in_bits_instr;
    in_payload.pc                       = io_in_bits_pc;
    in_payload.foldpc                   = io_in_bits_foldpc;
    in_payload.exceptionVec_0           = io_in_bits_exceptionVec_0;
    in_payload.exceptionVec_1           = io_in_bits_exceptionVec_1;
    in_payload.exceptionVec_2           = io_in_bits_exceptionVec_2;
    in_payload.exceptionVec_3           = io_in_bits_exceptionVec_3;
    in_payload.exceptionVec_4           = io_in_bits_exceptionVec_4;
    in_payload.exceptionVec_5           = io_in_bits_exceptionVec_5;
    in_payload.exceptionVec_6           = io_in_bits_exceptionVec_6;
    in_payload.exceptionVec_7           = io_in_bits_exceptionVec_7;
    in_payload.exceptionVec_8           = io_in_bits_exceptionVec_8;
    in_payload.exceptionVec_9           = io_in_bits_exceptionVec_9;
    in_payload.exceptionVec_10          = io_in_bits_exceptionVec_10;
    in_payload.exceptionVec_11          = io_in_bits_exceptionVec_11;
    in_payload.exceptionVec_12          = io_in_bits_exceptionVec_12;
    in_payload.exceptionVec_13          = io_in_bits_exceptionVec_13;
    in_payload.exceptionVec_14          = io_in_bits_exceptionVec_14;
    in_payload.exceptionVec_15          = io_in_bits_exceptionVec_15;
    in_payload.exceptionVec_16          = io_in_bits_exceptionVec_16;
    in_payload.exceptionVec_17          = io_in_bits_exceptionVec_17;
    in_payload.exceptionVec_18          = io_in_bits_exceptionVec_18;
    in_payload.exceptionVec_19          = io_in_bits_exceptionVec_19;
    in_payload.exceptionVec_20          = io_in_bits_exceptionVec_20;
    in_payload.exceptionVec_21          = io_in_bits_exceptionVec_21;
    in_payload.exceptionVec_22          = io_in_bits_exceptionVec_22;
    in_payload.exceptionVec_23          = io_in_bits_exceptionVec_23;
    in_payload.isFetchMalAddr           = io_in_bits_isFetchMalAddr;
    in_payload.trigger                  = io_in_bits_trigger;
    in_payload.preDecodeInfo_valid      = io_in_bits_preDecodeInfo_valid;
    in_payload.preDecodeInfo_isRVC      = io_in_bits_preDecodeInfo_isRVC;
    in_payload.preDecodeInfo_brType     = io_in_bits_preDecodeInfo_brType;
    in_payload.preDecodeInfo_isCall     = io_in_bits_preDecodeInfo_isCall;
    in_payload.preDecodeInfo_isRet      = io_in_bits_preDecodeInfo_isRet;
    in_payload.pred_taken               = io_in_bits_pred_taken;
    in_payload.crossPageIPFFix          = io_in_bits_crossPageIPFFix;
    in_payload.ftqPtr_flag              = io_in_bits_ftqPtr_flag;
    in_payload.ftqPtr_value             = io_in_bits_ftqPtr_value;
    in_payload.ftqOffset                = io_in_bits_ftqOffset;
    in_payload.satpFlushFirstFetchFault = io_in_bits_satpFlushFirstFetchFault;
    in_payload.srcType_0                = io_in_bits_srcType_0;
    in_payload.srcType_1                = io_in_bits_srcType_1;
    in_payload.srcType_2                = io_in_bits_srcType_2;
    in_payload.srcType_3                = io_in_bits_srcType_3;
    in_payload.srcType_4                = io_in_bits_srcType_4;
    in_payload.lsrc_0                   = io_in_bits_lsrc_0;
    in_payload.lsrc_1                   = io_in_bits_lsrc_1;
    in_payload.lsrc_2                   = io_in_bits_lsrc_2;
    in_payload.ldest                    = io_in_bits_ldest;
    in_payload.fuType                   = io_in_bits_fuType;
    in_payload.fuOpType                 = io_in_bits_fuOpType;
    in_payload.rfWen                    = io_in_bits_rfWen;
    in_payload.fpWen                    = io_in_bits_fpWen;
    in_payload.vecWen                   = io_in_bits_vecWen;
    in_payload.v0Wen                    = io_in_bits_v0Wen;
    in_payload.vlWen                    = io_in_bits_vlWen;
    in_payload.isXSTrap                 = io_in_bits_isXSTrap;
    in_payload.waitForward              = io_in_bits_waitForward;
    in_payload.blockBackward            = io_in_bits_blockBackward;
    in_payload.flushPipe                = io_in_bits_flushPipe;
    in_payload.canRobCompress           = io_in_bits_canRobCompress;
    in_payload.selImm                   = io_in_bits_selImm;
    in_payload.imm                      = io_in_bits_imm;
    in_payload.fpu_typeTagOut           = io_in_bits_fpu_typeTagOut;
    in_payload.fpu_wflags               = io_in_bits_fpu_wflags;
    in_payload.fpu_typ                  = io_in_bits_fpu_typ;
    in_payload.fpu_fmt                  = io_in_bits_fpu_fmt;
    in_payload.fpu_rm                   = io_in_bits_fpu_rm;
    in_payload.vpu_vill                 = io_in_bits_vpu_vill;
    in_payload.vpu_vma                  = io_in_bits_vpu_vma;
    in_payload.vpu_vta                  = io_in_bits_vpu_vta;
    in_payload.vpu_vsew                 = io_in_bits_vpu_vsew;
    in_payload.vpu_vlmul                = io_in_bits_vpu_vlmul;
    in_payload.vpu_specVill             = io_in_bits_vpu_specVill;
    in_payload.vpu_specVma              = io_in_bits_vpu_specVma;
    in_payload.vpu_specVta              = io_in_bits_vpu_specVta;
    in_payload.vpu_specVsew             = io_in_bits_vpu_specVsew;
    in_payload.vpu_specVlmul            = io_in_bits_vpu_specVlmul;
    in_payload.vpu_vm                   = io_in_bits_vpu_vm;
    in_payload.vpu_vstart               = io_in_bits_vpu_vstart;
    in_payload.vpu_fpu_isFoldTo1_2      = io_in_bits_vpu_fpu_isFoldTo1_2;
    in_payload.vpu_fpu_isFoldTo1_4      = io_in_bits_vpu_fpu_isFoldTo1_4;
    in_payload.vpu_fpu_isFoldTo1_8      = io_in_bits_vpu_fpu_isFoldTo1_8;
    in_payload.vpu_nf                   = io_in_bits_vpu_nf;
    in_payload.vpu_veew                 = io_in_bits_vpu_veew;
    in_payload.vpu_isReverse            = io_in_bits_vpu_isReverse;
    in_payload.vpu_isExt                = io_in_bits_vpu_isExt;
    in_payload.vpu_isNarrow             = io_in_bits_vpu_isNarrow;
    in_payload.vpu_isDstMask            = io_in_bits_vpu_isDstMask;
    in_payload.vpu_isOpMask             = io_in_bits_vpu_isOpMask;
    in_payload.vpu_isDependOldVd        = io_in_bits_vpu_isDependOldVd;
    in_payload.vpu_isWritePartVd        = io_in_bits_vpu_isWritePartVd;
    in_payload.vpu_isVleff              = io_in_bits_vpu_isVleff;
    in_payload.vlsInstr                 = io_in_bits_vlsInstr;
    in_payload.wfflags                  = io_in_bits_wfflags;
    in_payload.isMove                   = io_in_bits_isMove;
    in_payload.uopIdx                   = io_in_bits_uopIdx;
    in_payload.uopSplitType             = io_in_bits_uopSplitType;
    in_payload.isVset                   = io_in_bits_isVset;
    in_payload.firstUop                 = io_in_bits_firstUop;
    in_payload.lastUop                  = io_in_bits_lastUop;
    in_payload.numUops                  = io_in_bits_numUops;
    in_payload.numWB                    = io_in_bits_numWB;
    in_payload.commitType               = io_in_bits_commitType;
    in_payload.debug_fuType             = io_in_bits_debug_fuType;
    in_payload.debug_seqNum_seqNum      = io_in_bits_debug_seqNum_seqNum;
    in_payload.debug_seqNum_uopIdx      = io_in_bits_debug_seqNum_uopIdx;
    // 只有出口没有入口的字段：golden 里入口已被常量 0 折叠（见文件头），恒接 0
    in_payload.lsrc_3                   = '0;
    in_payload.lsrc_4                   = '0;
    in_payload.vpu_frm                  = '0;
    in_payload.vpu_fpu_isFpToVecInst    = '0;
    in_payload.vpu_fpu_isFP32Instr      = '0;
    in_payload.vpu_fpu_isFP64Instr      = '0;
    in_payload.vpu_fpu_isReduction      = '0;
    in_payload.vpu_vxrm                 = '0;
    in_payload.vpu_vuopIdx              = '0;
    in_payload.vpu_lastUop              = '0;
    in_payload.vpu_vmask                = '0;
    in_payload.vpu_vl                   = '0;
    in_payload.vpu_isMove               = '0;
  end

  // 出口拆包：struct 成员 -> 端口（同名逐项）
  assign io_out_bits_instr                    = out_payload.instr;
  assign io_out_bits_pc                       = out_payload.pc;
  assign io_out_bits_foldpc                   = out_payload.foldpc;
  assign io_out_bits_exceptionVec_0           = out_payload.exceptionVec_0;
  assign io_out_bits_exceptionVec_1           = out_payload.exceptionVec_1;
  assign io_out_bits_exceptionVec_2           = out_payload.exceptionVec_2;
  assign io_out_bits_exceptionVec_3           = out_payload.exceptionVec_3;
  assign io_out_bits_exceptionVec_4           = out_payload.exceptionVec_4;
  assign io_out_bits_exceptionVec_5           = out_payload.exceptionVec_5;
  assign io_out_bits_exceptionVec_6           = out_payload.exceptionVec_6;
  assign io_out_bits_exceptionVec_7           = out_payload.exceptionVec_7;
  assign io_out_bits_exceptionVec_8           = out_payload.exceptionVec_8;
  assign io_out_bits_exceptionVec_9           = out_payload.exceptionVec_9;
  assign io_out_bits_exceptionVec_10          = out_payload.exceptionVec_10;
  assign io_out_bits_exceptionVec_11          = out_payload.exceptionVec_11;
  assign io_out_bits_exceptionVec_12          = out_payload.exceptionVec_12;
  assign io_out_bits_exceptionVec_13          = out_payload.exceptionVec_13;
  assign io_out_bits_exceptionVec_14          = out_payload.exceptionVec_14;
  assign io_out_bits_exceptionVec_15          = out_payload.exceptionVec_15;
  assign io_out_bits_exceptionVec_16          = out_payload.exceptionVec_16;
  assign io_out_bits_exceptionVec_17          = out_payload.exceptionVec_17;
  assign io_out_bits_exceptionVec_18          = out_payload.exceptionVec_18;
  assign io_out_bits_exceptionVec_19          = out_payload.exceptionVec_19;
  assign io_out_bits_exceptionVec_20          = out_payload.exceptionVec_20;
  assign io_out_bits_exceptionVec_21          = out_payload.exceptionVec_21;
  assign io_out_bits_exceptionVec_22          = out_payload.exceptionVec_22;
  assign io_out_bits_exceptionVec_23          = out_payload.exceptionVec_23;
  assign io_out_bits_isFetchMalAddr           = out_payload.isFetchMalAddr;
  assign io_out_bits_trigger                  = out_payload.trigger;
  assign io_out_bits_preDecodeInfo_valid      = out_payload.preDecodeInfo_valid;
  assign io_out_bits_preDecodeInfo_isRVC      = out_payload.preDecodeInfo_isRVC;
  assign io_out_bits_preDecodeInfo_brType     = out_payload.preDecodeInfo_brType;
  assign io_out_bits_preDecodeInfo_isCall     = out_payload.preDecodeInfo_isCall;
  assign io_out_bits_preDecodeInfo_isRet      = out_payload.preDecodeInfo_isRet;
  assign io_out_bits_pred_taken               = out_payload.pred_taken;
  assign io_out_bits_crossPageIPFFix          = out_payload.crossPageIPFFix;
  assign io_out_bits_ftqPtr_flag              = out_payload.ftqPtr_flag;
  assign io_out_bits_ftqPtr_value             = out_payload.ftqPtr_value;
  assign io_out_bits_ftqOffset                = out_payload.ftqOffset;
  assign io_out_bits_satpFlushFirstFetchFault = out_payload.satpFlushFirstFetchFault;
  assign io_out_bits_srcType_0                = out_payload.srcType_0;
  assign io_out_bits_srcType_1                = out_payload.srcType_1;
  assign io_out_bits_srcType_2                = out_payload.srcType_2;
  assign io_out_bits_srcType_3                = out_payload.srcType_3;
  assign io_out_bits_srcType_4                = out_payload.srcType_4;
  assign io_out_bits_lsrc_0                   = out_payload.lsrc_0;
  assign io_out_bits_lsrc_1                   = out_payload.lsrc_1;
  assign io_out_bits_lsrc_2                   = out_payload.lsrc_2;
  assign io_out_bits_lsrc_3                   = out_payload.lsrc_3;
  assign io_out_bits_lsrc_4                   = out_payload.lsrc_4;
  assign io_out_bits_ldest                    = out_payload.ldest;
  assign io_out_bits_fuType                   = out_payload.fuType;
  assign io_out_bits_fuOpType                 = out_payload.fuOpType;
  assign io_out_bits_rfWen                    = out_payload.rfWen;
  assign io_out_bits_fpWen                    = out_payload.fpWen;
  assign io_out_bits_vecWen                   = out_payload.vecWen;
  assign io_out_bits_v0Wen                    = out_payload.v0Wen;
  assign io_out_bits_vlWen                    = out_payload.vlWen;
  assign io_out_bits_isXSTrap                 = out_payload.isXSTrap;
  assign io_out_bits_waitForward              = out_payload.waitForward;
  assign io_out_bits_blockBackward            = out_payload.blockBackward;
  assign io_out_bits_flushPipe                = out_payload.flushPipe;
  assign io_out_bits_canRobCompress           = out_payload.canRobCompress;
  assign io_out_bits_selImm                   = out_payload.selImm;
  assign io_out_bits_imm                      = out_payload.imm;
  assign io_out_bits_fpu_typeTagOut           = out_payload.fpu_typeTagOut;
  assign io_out_bits_fpu_wflags               = out_payload.fpu_wflags;
  assign io_out_bits_fpu_typ                  = out_payload.fpu_typ;
  assign io_out_bits_fpu_fmt                  = out_payload.fpu_fmt;
  assign io_out_bits_fpu_rm                   = out_payload.fpu_rm;
  assign io_out_bits_vpu_vill                 = out_payload.vpu_vill;
  assign io_out_bits_vpu_vma                  = out_payload.vpu_vma;
  assign io_out_bits_vpu_vta                  = out_payload.vpu_vta;
  assign io_out_bits_vpu_vsew                 = out_payload.vpu_vsew;
  assign io_out_bits_vpu_vlmul                = out_payload.vpu_vlmul;
  assign io_out_bits_vpu_specVill             = out_payload.vpu_specVill;
  assign io_out_bits_vpu_specVma              = out_payload.vpu_specVma;
  assign io_out_bits_vpu_specVta              = out_payload.vpu_specVta;
  assign io_out_bits_vpu_specVsew             = out_payload.vpu_specVsew;
  assign io_out_bits_vpu_specVlmul            = out_payload.vpu_specVlmul;
  assign io_out_bits_vpu_vm                   = out_payload.vpu_vm;
  assign io_out_bits_vpu_vstart               = out_payload.vpu_vstart;
  assign io_out_bits_vpu_frm                  = out_payload.vpu_frm;
  assign io_out_bits_vpu_fpu_isFpToVecInst    = out_payload.vpu_fpu_isFpToVecInst;
  assign io_out_bits_vpu_fpu_isFP32Instr      = out_payload.vpu_fpu_isFP32Instr;
  assign io_out_bits_vpu_fpu_isFP64Instr      = out_payload.vpu_fpu_isFP64Instr;
  assign io_out_bits_vpu_fpu_isReduction      = out_payload.vpu_fpu_isReduction;
  assign io_out_bits_vpu_fpu_isFoldTo1_2      = out_payload.vpu_fpu_isFoldTo1_2;
  assign io_out_bits_vpu_fpu_isFoldTo1_4      = out_payload.vpu_fpu_isFoldTo1_4;
  assign io_out_bits_vpu_fpu_isFoldTo1_8      = out_payload.vpu_fpu_isFoldTo1_8;
  assign io_out_bits_vpu_vxrm                 = out_payload.vpu_vxrm;
  assign io_out_bits_vpu_vuopIdx              = out_payload.vpu_vuopIdx;
  assign io_out_bits_vpu_lastUop              = out_payload.vpu_lastUop;
  assign io_out_bits_vpu_vmask                = out_payload.vpu_vmask;
  assign io_out_bits_vpu_vl                   = out_payload.vpu_vl;
  assign io_out_bits_vpu_nf                   = out_payload.vpu_nf;
  assign io_out_bits_vpu_veew                 = out_payload.vpu_veew;
  assign io_out_bits_vpu_isReverse            = out_payload.vpu_isReverse;
  assign io_out_bits_vpu_isExt                = out_payload.vpu_isExt;
  assign io_out_bits_vpu_isNarrow             = out_payload.vpu_isNarrow;
  assign io_out_bits_vpu_isDstMask            = out_payload.vpu_isDstMask;
  assign io_out_bits_vpu_isOpMask             = out_payload.vpu_isOpMask;
  assign io_out_bits_vpu_isMove               = out_payload.vpu_isMove;
  assign io_out_bits_vpu_isDependOldVd        = out_payload.vpu_isDependOldVd;
  assign io_out_bits_vpu_isWritePartVd        = out_payload.vpu_isWritePartVd;
  assign io_out_bits_vpu_isVleff              = out_payload.vpu_isVleff;
  assign io_out_bits_vlsInstr                 = out_payload.vlsInstr;
  assign io_out_bits_wfflags                  = out_payload.wfflags;
  assign io_out_bits_isMove                   = out_payload.isMove;
  assign io_out_bits_uopIdx                   = out_payload.uopIdx;
  assign io_out_bits_uopSplitType             = out_payload.uopSplitType;
  assign io_out_bits_isVset                   = out_payload.isVset;
  assign io_out_bits_firstUop                 = out_payload.firstUop;
  assign io_out_bits_lastUop                  = out_payload.lastUop;
  assign io_out_bits_numUops                  = out_payload.numUops;
  assign io_out_bits_numWB                    = out_payload.numWB;
  assign io_out_bits_commitType               = out_payload.commitType;
  assign io_out_bits_debug_fuType             = out_payload.debug_fuType;
  assign io_out_bits_debug_seqNum_seqNum      = out_payload.debug_seqNum_seqNum;
  assign io_out_bits_debug_seqNum_uopIdx      = out_payload.debug_seqNum_uopIdx;

  // ---------------------------------------------------------------------------
  // elaborate 期位宽不变式：入口端口位宽之和 + 恒 0 字段位宽 == 出口端口位宽之和
  // == PAYLOAD_W_G1 == $bits(payload_t)（后一个等号由核校验）。任何一个端口或 struct
  // 成员的位宽被改动，这几个数就不再相等。逐端口对 G1 golden 的权威闸仍是
  // scripts/port_contract_lint.py，这里只是把同类错误提前到 elaborate。
  // ---------------------------------------------------------------------------
  localparam int unsigned IN_PORT_BITS =
    $bits(io_in_bits_instr) + $bits(io_in_bits_pc) + $bits(io_in_bits_foldpc) + $bits(io_in_bits_exceptionVec_0) +
    $bits(io_in_bits_exceptionVec_1) + $bits(io_in_bits_exceptionVec_2) + $bits(io_in_bits_exceptionVec_3) + $bits(io_in_bits_exceptionVec_4) +
    $bits(io_in_bits_exceptionVec_5) + $bits(io_in_bits_exceptionVec_6) + $bits(io_in_bits_exceptionVec_7) + $bits(io_in_bits_exceptionVec_8) +
    $bits(io_in_bits_exceptionVec_9) + $bits(io_in_bits_exceptionVec_10) + $bits(io_in_bits_exceptionVec_11) + $bits(io_in_bits_exceptionVec_12) +
    $bits(io_in_bits_exceptionVec_13) + $bits(io_in_bits_exceptionVec_14) + $bits(io_in_bits_exceptionVec_15) + $bits(io_in_bits_exceptionVec_16) +
    $bits(io_in_bits_exceptionVec_17) + $bits(io_in_bits_exceptionVec_18) + $bits(io_in_bits_exceptionVec_19) + $bits(io_in_bits_exceptionVec_20) +
    $bits(io_in_bits_exceptionVec_21) + $bits(io_in_bits_exceptionVec_22) + $bits(io_in_bits_exceptionVec_23) + $bits(io_in_bits_isFetchMalAddr) +
    $bits(io_in_bits_trigger) + $bits(io_in_bits_preDecodeInfo_valid) + $bits(io_in_bits_preDecodeInfo_isRVC) + $bits(io_in_bits_preDecodeInfo_brType) +
    $bits(io_in_bits_preDecodeInfo_isCall) + $bits(io_in_bits_preDecodeInfo_isRet) + $bits(io_in_bits_pred_taken) + $bits(io_in_bits_crossPageIPFFix) +
    $bits(io_in_bits_ftqPtr_flag) + $bits(io_in_bits_ftqPtr_value) + $bits(io_in_bits_ftqOffset) + $bits(io_in_bits_satpFlushFirstFetchFault) +
    $bits(io_in_bits_srcType_0) + $bits(io_in_bits_srcType_1) + $bits(io_in_bits_srcType_2) + $bits(io_in_bits_srcType_3) +
    $bits(io_in_bits_srcType_4) + $bits(io_in_bits_lsrc_0) + $bits(io_in_bits_lsrc_1) + $bits(io_in_bits_lsrc_2) +
    $bits(io_in_bits_ldest) + $bits(io_in_bits_fuType) + $bits(io_in_bits_fuOpType) + $bits(io_in_bits_rfWen) +
    $bits(io_in_bits_fpWen) + $bits(io_in_bits_vecWen) + $bits(io_in_bits_v0Wen) + $bits(io_in_bits_vlWen) +
    $bits(io_in_bits_isXSTrap) + $bits(io_in_bits_waitForward) + $bits(io_in_bits_blockBackward) + $bits(io_in_bits_flushPipe) +
    $bits(io_in_bits_canRobCompress) + $bits(io_in_bits_selImm) + $bits(io_in_bits_imm) + $bits(io_in_bits_fpu_typeTagOut) +
    $bits(io_in_bits_fpu_wflags) + $bits(io_in_bits_fpu_typ) + $bits(io_in_bits_fpu_fmt) + $bits(io_in_bits_fpu_rm) +
    $bits(io_in_bits_vpu_vill) + $bits(io_in_bits_vpu_vma) + $bits(io_in_bits_vpu_vta) + $bits(io_in_bits_vpu_vsew) +
    $bits(io_in_bits_vpu_vlmul) + $bits(io_in_bits_vpu_specVill) + $bits(io_in_bits_vpu_specVma) + $bits(io_in_bits_vpu_specVta) +
    $bits(io_in_bits_vpu_specVsew) + $bits(io_in_bits_vpu_specVlmul) + $bits(io_in_bits_vpu_vm) + $bits(io_in_bits_vpu_vstart) +
    $bits(io_in_bits_vpu_fpu_isFoldTo1_2) + $bits(io_in_bits_vpu_fpu_isFoldTo1_4) + $bits(io_in_bits_vpu_fpu_isFoldTo1_8) + $bits(io_in_bits_vpu_nf) +
    $bits(io_in_bits_vpu_veew) + $bits(io_in_bits_vpu_isReverse) + $bits(io_in_bits_vpu_isExt) + $bits(io_in_bits_vpu_isNarrow) +
    $bits(io_in_bits_vpu_isDstMask) + $bits(io_in_bits_vpu_isOpMask) + $bits(io_in_bits_vpu_isDependOldVd) + $bits(io_in_bits_vpu_isWritePartVd) +
    $bits(io_in_bits_vpu_isVleff) + $bits(io_in_bits_vlsInstr) + $bits(io_in_bits_wfflags) + $bits(io_in_bits_isMove) +
    $bits(io_in_bits_uopIdx) + $bits(io_in_bits_uopSplitType) + $bits(io_in_bits_isVset) + $bits(io_in_bits_firstUop) +
    $bits(io_in_bits_lastUop) + $bits(io_in_bits_numUops) + $bits(io_in_bits_numWB) + $bits(io_in_bits_commitType) +
    $bits(io_in_bits_debug_fuType) + $bits(io_in_bits_debug_seqNum_seqNum) + $bits(io_in_bits_debug_seqNum_uopIdx);
  localparam int unsigned OUT_PORT_BITS =
    $bits(io_out_bits_instr) + $bits(io_out_bits_pc) + $bits(io_out_bits_foldpc) + $bits(io_out_bits_exceptionVec_0) +
    $bits(io_out_bits_exceptionVec_1) + $bits(io_out_bits_exceptionVec_2) + $bits(io_out_bits_exceptionVec_3) + $bits(io_out_bits_exceptionVec_4) +
    $bits(io_out_bits_exceptionVec_5) + $bits(io_out_bits_exceptionVec_6) + $bits(io_out_bits_exceptionVec_7) + $bits(io_out_bits_exceptionVec_8) +
    $bits(io_out_bits_exceptionVec_9) + $bits(io_out_bits_exceptionVec_10) + $bits(io_out_bits_exceptionVec_11) + $bits(io_out_bits_exceptionVec_12) +
    $bits(io_out_bits_exceptionVec_13) + $bits(io_out_bits_exceptionVec_14) + $bits(io_out_bits_exceptionVec_15) + $bits(io_out_bits_exceptionVec_16) +
    $bits(io_out_bits_exceptionVec_17) + $bits(io_out_bits_exceptionVec_18) + $bits(io_out_bits_exceptionVec_19) + $bits(io_out_bits_exceptionVec_20) +
    $bits(io_out_bits_exceptionVec_21) + $bits(io_out_bits_exceptionVec_22) + $bits(io_out_bits_exceptionVec_23) + $bits(io_out_bits_isFetchMalAddr) +
    $bits(io_out_bits_trigger) + $bits(io_out_bits_preDecodeInfo_valid) + $bits(io_out_bits_preDecodeInfo_isRVC) + $bits(io_out_bits_preDecodeInfo_brType) +
    $bits(io_out_bits_preDecodeInfo_isCall) + $bits(io_out_bits_preDecodeInfo_isRet) + $bits(io_out_bits_pred_taken) + $bits(io_out_bits_crossPageIPFFix) +
    $bits(io_out_bits_ftqPtr_flag) + $bits(io_out_bits_ftqPtr_value) + $bits(io_out_bits_ftqOffset) + $bits(io_out_bits_satpFlushFirstFetchFault) +
    $bits(io_out_bits_srcType_0) + $bits(io_out_bits_srcType_1) + $bits(io_out_bits_srcType_2) + $bits(io_out_bits_srcType_3) +
    $bits(io_out_bits_srcType_4) + $bits(io_out_bits_lsrc_0) + $bits(io_out_bits_lsrc_1) + $bits(io_out_bits_lsrc_2) +
    $bits(io_out_bits_lsrc_3) + $bits(io_out_bits_lsrc_4) + $bits(io_out_bits_ldest) + $bits(io_out_bits_fuType) +
    $bits(io_out_bits_fuOpType) + $bits(io_out_bits_rfWen) + $bits(io_out_bits_fpWen) + $bits(io_out_bits_vecWen) +
    $bits(io_out_bits_v0Wen) + $bits(io_out_bits_vlWen) + $bits(io_out_bits_isXSTrap) + $bits(io_out_bits_waitForward) +
    $bits(io_out_bits_blockBackward) + $bits(io_out_bits_flushPipe) + $bits(io_out_bits_canRobCompress) + $bits(io_out_bits_selImm) +
    $bits(io_out_bits_imm) + $bits(io_out_bits_fpu_typeTagOut) + $bits(io_out_bits_fpu_wflags) + $bits(io_out_bits_fpu_typ) +
    $bits(io_out_bits_fpu_fmt) + $bits(io_out_bits_fpu_rm) + $bits(io_out_bits_vpu_vill) + $bits(io_out_bits_vpu_vma) +
    $bits(io_out_bits_vpu_vta) + $bits(io_out_bits_vpu_vsew) + $bits(io_out_bits_vpu_vlmul) + $bits(io_out_bits_vpu_specVill) +
    $bits(io_out_bits_vpu_specVma) + $bits(io_out_bits_vpu_specVta) + $bits(io_out_bits_vpu_specVsew) + $bits(io_out_bits_vpu_specVlmul) +
    $bits(io_out_bits_vpu_vm) + $bits(io_out_bits_vpu_vstart) + $bits(io_out_bits_vpu_frm) + $bits(io_out_bits_vpu_fpu_isFpToVecInst) +
    $bits(io_out_bits_vpu_fpu_isFP32Instr) + $bits(io_out_bits_vpu_fpu_isFP64Instr) + $bits(io_out_bits_vpu_fpu_isReduction) + $bits(io_out_bits_vpu_fpu_isFoldTo1_2) +
    $bits(io_out_bits_vpu_fpu_isFoldTo1_4) + $bits(io_out_bits_vpu_fpu_isFoldTo1_8) + $bits(io_out_bits_vpu_vxrm) + $bits(io_out_bits_vpu_vuopIdx) +
    $bits(io_out_bits_vpu_lastUop) + $bits(io_out_bits_vpu_vmask) + $bits(io_out_bits_vpu_vl) + $bits(io_out_bits_vpu_nf) +
    $bits(io_out_bits_vpu_veew) + $bits(io_out_bits_vpu_isReverse) + $bits(io_out_bits_vpu_isExt) + $bits(io_out_bits_vpu_isNarrow) +
    $bits(io_out_bits_vpu_isDstMask) + $bits(io_out_bits_vpu_isOpMask) + $bits(io_out_bits_vpu_isMove) + $bits(io_out_bits_vpu_isDependOldVd) +
    $bits(io_out_bits_vpu_isWritePartVd) + $bits(io_out_bits_vpu_isVleff) + $bits(io_out_bits_vlsInstr) + $bits(io_out_bits_wfflags) +
    $bits(io_out_bits_isMove) + $bits(io_out_bits_uopIdx) + $bits(io_out_bits_uopSplitType) + $bits(io_out_bits_isVset) +
    $bits(io_out_bits_firstUop) + $bits(io_out_bits_lastUop) + $bits(io_out_bits_numUops) + $bits(io_out_bits_numWB) +
    $bits(io_out_bits_commitType) + $bits(io_out_bits_debug_fuType) + $bits(io_out_bits_debug_seqNum_seqNum) + $bits(io_out_bits_debug_seqNum_uopIdx);
  localparam int unsigned ZERO_FIELD_BITS = 166;

  if (IN_PORT_BITS + ZERO_FIELD_BITS != PAYLOAD_W_G1)
    $fatal(1, "PipelineConnectPipe: input port bits %0d + zero fields %0d != G1 golden %0d",
           IN_PORT_BITS, ZERO_FIELD_BITS, PAYLOAD_W_G1);
  if (OUT_PORT_BITS != PAYLOAD_W_G1)
    $fatal(1, "PipelineConnectPipe: output port bits %0d != G1 golden %0d", OUT_PORT_BITS, PAYLOAD_W_G1);

  xs_PipelineConnectPipe_core #(
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
