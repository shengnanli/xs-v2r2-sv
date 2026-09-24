// PipeGroupConnect.sv — CtrlBlock 里重命名(Rename)→派遣(Dispatch)之间的 6 lane 成组单拍流水缓冲。
// 例化点（G1 golden，唯一一处）：CtrlBlock.renamePipeDispatch。
// 层次：CtrlBlock 的直接 child，0 子模块；golden 5039 行 / 1626 端口（815 输入 / 811 输出）。
//
// 核心机制（成组握手：6 条 lane 要么一起收、要么一起等）：
//   canAcc     = outAllFire | (validVec == 0)      —— 下游整组取走、或本级全空，才收新一组
//   in_i_ready = canAcc                            —— 6 个 ready 是同一根线
//   fire_i     = in_i_valid & canAcc
//   valid_i'   = ~flush & (fire_i | ~out_i_ready & valid_i)   （异步复位清 0）
//   data_i     = RegEnable(in_i_bits, fire_i)      —— 全部字段打拍，无组合直通
//   outAllFire 由调用方给（CtrlBlock 接的是 dispatch 侧"整组 fire"），与 out_i_ready 不必同步。
//
// ★lane 0 比其它 lane 多一个 snapshot 字段★：下游只用 lane 0 的 snapshot，lane 1~5 的
//   那个寄存器被 firtool 消掉（入口出口一起没了）。所以 lane 0 用 payload_snap_t（134 字段 / 735 位），
//   lane 1~5 用 payload_t（133 字段 / 734 位）。数据寄存器按 lane 各例化一个 slot，宽度各取各的；
//   握手在一个核里做（canAcc 要看全部 6 个 valid）。
//
// 本文件由 scripts/gen_cb_connect.py 从 G1 golden 端口表生成，勿手改；
// golden 对照：G1-canonical/golden-rtl/PipeGroupConnect.sv。
//
// 本文件导航（行号由生成器写入）：
//   L37    package：payload 布局
//   L365   核：成组握手
//   L399   slot：单 lane 数据寄存器
//   L429   wrapper：端口表
//   L2133  wrapper：lane 0 打包/拆包
//   L2407  wrapper：lane 1 打包/拆包
//   L2679  wrapper：lane 2 打包/拆包
//   L2951  wrapper：lane 3 打包/拆包
//   L3223  wrapper：lane 4 打包/拆包
//   L3495  wrapper：lane 5 打包/拆包
//   L3767  wrapper：位宽不变式

// ============================================================================
// package：两种 payload 布局（lane 0 带 snapshot）。成员顺序照 golden 各 lane 端口表。
// ============================================================================
package pipegroupconnect_pkg;
  localparam int unsigned N_LANES = 6;

  // lane 1~5 的 payload
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
    logic           hasException;
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
    logic [31:0]    imm;
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
    logic           isVset;
    logic           firstUop;
    logic           lastUop;
    logic [6:0]     numUops;
    logic [6:0]     numWB;
    logic [2:0]     commitType;
    // psrc/pdest：重命名后的物理寄存器号
    logic [7:0]     psrc_0;
    logic [7:0]     psrc_1;
    logic [7:0]     psrc_2;
    logic [7:0]     psrc_3;
    logic [7:0]     psrc_4;
    logic [7:0]     pdest;
    // robIdx：ROB 表项指针（flag=回绕位）
    logic           robIdx_flag;
    logic [7:0]     robIdx_value;
    // ROB 压缩组大小与 FS/VS 脏位
    logic [2:0]     instrSize;
    logic           dirtyFs;
    logic           dirtyVs;
    // traceBlockInPipe：RISC-V trace 字段
    logic [3:0]     traceBlockInPipe_itype;
    logic [3:0]     traceBlockInPipe_iretire;
    logic           traceBlockInPipe_ilastsize;
    // 重命名阶段属性：move 消除 / 快照点
    logic           eliminatedMove;
    // debugInfo：性能剖析时间戳
    logic [63:0]    debugInfo_renameTime;
    // debug_*：调试用透传字段（fuType 副本 / 序号 / sim 触发）
    logic [55:0]    debug_seqNum_seqNum;
    logic [7:0]     debug_seqNum_uopIdx;
    logic [34:0]    debug_fuType;
    logic           debug_sim_trig;
    // uop 拆分信息与提交类型（续）
    logic [4:0]     numLsElem;
  } payload_t;

  // lane 0 的 payload（多一个 snapshot，位置照 golden）
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
    logic           hasException;
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
    logic [31:0]    imm;
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
    logic           isVset;
    logic           firstUop;
    logic           lastUop;
    logic [6:0]     numUops;
    logic [6:0]     numWB;
    logic [2:0]     commitType;
    // psrc/pdest：重命名后的物理寄存器号
    logic [7:0]     psrc_0;
    logic [7:0]     psrc_1;
    logic [7:0]     psrc_2;
    logic [7:0]     psrc_3;
    logic [7:0]     psrc_4;
    logic [7:0]     pdest;
    // robIdx：ROB 表项指针（flag=回绕位）
    logic           robIdx_flag;
    logic [7:0]     robIdx_value;
    // ROB 压缩组大小与 FS/VS 脏位
    logic [2:0]     instrSize;
    logic           dirtyFs;
    logic           dirtyVs;
    // traceBlockInPipe：RISC-V trace 字段
    logic [3:0]     traceBlockInPipe_itype;
    logic [3:0]     traceBlockInPipe_iretire;
    logic           traceBlockInPipe_ilastsize;
    // 重命名阶段属性：move 消除 / 快照点
    logic           eliminatedMove;
    logic           snapshot;
    // debugInfo：性能剖析时间戳
    logic [63:0]    debugInfo_renameTime;
    // debug_*：调试用透传字段（fuType 副本 / 序号 / sim 触发）
    logic [55:0]    debug_seqNum_seqNum;
    logic [7:0]     debug_seqNum_uopIdx;
    logic [34:0]    debug_fuType;
    logic           debug_sim_trig;
    // uop 拆分信息与提交类型（续）
    logic [4:0]     numLsElem;
  } payload_snap_t;

  // G1 golden 各 lane 入口端口位宽之和，传给 slot 做 elaborate 期防呆。
  localparam int unsigned LANE0_W_G1 = 735;
  localparam int unsigned LANE_W_G1  = 734;
endpackage

// ============================================================================
// 核：成组握手（canAcc / validVec / 各 lane fire）。不碰数据。
// ============================================================================
module xs_PipeGroupConnect_core #(
  parameter int unsigned N = 6
)(
  input  logic         clock,
  input  logic         reset,          // 异步高有效，仅复位 valid_vec
  input  logic [N-1:0] io_in_valid,
  output logic         io_in_ready,    // = canAcc，N 条 lane 共用
  input  logic [N-1:0] io_out_ready,
  output logic [N-1:0] io_out_valid,
  input  logic         io_flush,
  input  logic         io_outAllFire,
  output logic [N-1:0] lane_fire       // 各 lane 的数据寄存器使能
);

  logic [N-1:0] valid_vec;
  logic         can_acc;

  // 整组收新数据的条件：下游本拍整组取走，或本级 6 条 lane 全空。
  assign can_acc   = io_outAllFire | ~(|valid_vec);
  assign lane_fire = io_in_valid & {N{can_acc}};

  always_ff @(posedge clock or posedge reset) begin
    if (reset) valid_vec <= '0;
    else       valid_vec <= {N{~io_flush}} & (lane_fire | (~io_out_ready & valid_vec));
  end

  assign io_in_ready  = can_acc;
  assign io_out_valid = valid_vec;

endmodule

// ============================================================================
// slot：一条 lane 的数据寄存器 = RegEnable(in_bits, fire)。宽度按 lane 各取各的。
// ============================================================================
module xs_PipeGroupConnect_slot #(
  parameter int unsigned W    = 1,
  // G1 锚点（fail-closed）：wrapper 把该 lane 的 G1 位宽和传进来，默认 0 = 没传，直接 $fatal。
  parameter int unsigned W_G1 = 0
)(
  input  logic         clock,
  input  logic         fire,
  input  logic [W-1:0] io_in_bits,
  output logic [W-1:0] io_out_bits
);

  if (W_G1 == 0)
    $fatal(1, "xs_PipeGroupConnect_slot: wrapper must pass W_G1 (sum of G1 golden lane port widths); W=%0d", W);
  if (W != W_G1)
    $fatal(1, "xs_PipeGroupConnect_slot: packed payload is %0d bits != G1 golden sum %0d bits -- struct and G1 port table diverged",
           W, W_G1);

  logic [W-1:0] data;

  always_ff @(posedge clock) begin
    if (fire) data <= io_in_bits;
  end

  assign io_out_bits = data;

endmodule

// ============================================================================
// wrapper：golden 同名同端口。只做打包/拆包 + 位宽不变式 + 例化，不含握手逻辑。
// ============================================================================
module PipeGroupConnect import pipegroupconnect_pkg::*; (
  input  logic clock,
  input  logic reset,
  output logic io_in_0_ready,
  input  logic io_in_0_valid,
  input  logic [31:0] io_in_0_bits_instr,
  input  logic [49:0] io_in_0_bits_pc,
  input  logic [9:0] io_in_0_bits_foldpc,
  input  logic io_in_0_bits_exceptionVec_0,
  input  logic io_in_0_bits_exceptionVec_1,
  input  logic io_in_0_bits_exceptionVec_2,
  input  logic io_in_0_bits_exceptionVec_3,
  input  logic io_in_0_bits_exceptionVec_4,
  input  logic io_in_0_bits_exceptionVec_5,
  input  logic io_in_0_bits_exceptionVec_6,
  input  logic io_in_0_bits_exceptionVec_7,
  input  logic io_in_0_bits_exceptionVec_8,
  input  logic io_in_0_bits_exceptionVec_9,
  input  logic io_in_0_bits_exceptionVec_10,
  input  logic io_in_0_bits_exceptionVec_11,
  input  logic io_in_0_bits_exceptionVec_12,
  input  logic io_in_0_bits_exceptionVec_13,
  input  logic io_in_0_bits_exceptionVec_14,
  input  logic io_in_0_bits_exceptionVec_15,
  input  logic io_in_0_bits_exceptionVec_16,
  input  logic io_in_0_bits_exceptionVec_17,
  input  logic io_in_0_bits_exceptionVec_18,
  input  logic io_in_0_bits_exceptionVec_19,
  input  logic io_in_0_bits_exceptionVec_20,
  input  logic io_in_0_bits_exceptionVec_21,
  input  logic io_in_0_bits_exceptionVec_22,
  input  logic io_in_0_bits_exceptionVec_23,
  input  logic io_in_0_bits_isFetchMalAddr,
  input  logic io_in_0_bits_hasException,
  input  logic [3:0] io_in_0_bits_trigger,
  input  logic io_in_0_bits_preDecodeInfo_valid,
  input  logic io_in_0_bits_preDecodeInfo_isRVC,
  input  logic [1:0] io_in_0_bits_preDecodeInfo_brType,
  input  logic io_in_0_bits_preDecodeInfo_isCall,
  input  logic io_in_0_bits_preDecodeInfo_isRet,
  input  logic io_in_0_bits_pred_taken,
  input  logic io_in_0_bits_crossPageIPFFix,
  input  logic io_in_0_bits_ftqPtr_flag,
  input  logic [5:0] io_in_0_bits_ftqPtr_value,
  input  logic [3:0] io_in_0_bits_ftqOffset,
  input  logic io_in_0_bits_satpFlushFirstFetchFault,
  input  logic [3:0] io_in_0_bits_srcType_0,
  input  logic [3:0] io_in_0_bits_srcType_1,
  input  logic [3:0] io_in_0_bits_srcType_2,
  input  logic [3:0] io_in_0_bits_srcType_3,
  input  logic [3:0] io_in_0_bits_srcType_4,
  input  logic [5:0] io_in_0_bits_ldest,
  input  logic [34:0] io_in_0_bits_fuType,
  input  logic [8:0] io_in_0_bits_fuOpType,
  input  logic io_in_0_bits_rfWen,
  input  logic io_in_0_bits_fpWen,
  input  logic io_in_0_bits_vecWen,
  input  logic io_in_0_bits_v0Wen,
  input  logic io_in_0_bits_vlWen,
  input  logic io_in_0_bits_isXSTrap,
  input  logic io_in_0_bits_waitForward,
  input  logic io_in_0_bits_blockBackward,
  input  logic io_in_0_bits_flushPipe,
  input  logic io_in_0_bits_canRobCompress,
  input  logic [3:0] io_in_0_bits_selImm,
  input  logic [31:0] io_in_0_bits_imm,
  input  logic [1:0] io_in_0_bits_fpu_typeTagOut,
  input  logic io_in_0_bits_fpu_wflags,
  input  logic [1:0] io_in_0_bits_fpu_typ,
  input  logic [1:0] io_in_0_bits_fpu_fmt,
  input  logic [2:0] io_in_0_bits_fpu_rm,
  input  logic io_in_0_bits_vpu_vill,
  input  logic io_in_0_bits_vpu_vma,
  input  logic io_in_0_bits_vpu_vta,
  input  logic [1:0] io_in_0_bits_vpu_vsew,
  input  logic [2:0] io_in_0_bits_vpu_vlmul,
  input  logic io_in_0_bits_vpu_specVill,
  input  logic io_in_0_bits_vpu_specVma,
  input  logic io_in_0_bits_vpu_specVta,
  input  logic [1:0] io_in_0_bits_vpu_specVsew,
  input  logic [2:0] io_in_0_bits_vpu_specVlmul,
  input  logic io_in_0_bits_vpu_vm,
  input  logic [7:0] io_in_0_bits_vpu_vstart,
  input  logic [2:0] io_in_0_bits_vpu_frm,
  input  logic io_in_0_bits_vpu_fpu_isFpToVecInst,
  input  logic io_in_0_bits_vpu_fpu_isFP32Instr,
  input  logic io_in_0_bits_vpu_fpu_isFP64Instr,
  input  logic io_in_0_bits_vpu_fpu_isReduction,
  input  logic io_in_0_bits_vpu_fpu_isFoldTo1_2,
  input  logic io_in_0_bits_vpu_fpu_isFoldTo1_4,
  input  logic io_in_0_bits_vpu_fpu_isFoldTo1_8,
  input  logic [1:0] io_in_0_bits_vpu_vxrm,
  input  logic [6:0] io_in_0_bits_vpu_vuopIdx,
  input  logic io_in_0_bits_vpu_lastUop,
  input  logic [127:0] io_in_0_bits_vpu_vmask,
  input  logic [7:0] io_in_0_bits_vpu_vl,
  input  logic [2:0] io_in_0_bits_vpu_nf,
  input  logic [1:0] io_in_0_bits_vpu_veew,
  input  logic io_in_0_bits_vpu_isReverse,
  input  logic io_in_0_bits_vpu_isExt,
  input  logic io_in_0_bits_vpu_isNarrow,
  input  logic io_in_0_bits_vpu_isDstMask,
  input  logic io_in_0_bits_vpu_isOpMask,
  input  logic io_in_0_bits_vpu_isMove,
  input  logic io_in_0_bits_vpu_isDependOldVd,
  input  logic io_in_0_bits_vpu_isWritePartVd,
  input  logic io_in_0_bits_vpu_isVleff,
  input  logic io_in_0_bits_vlsInstr,
  input  logic io_in_0_bits_wfflags,
  input  logic io_in_0_bits_isMove,
  input  logic [6:0] io_in_0_bits_uopIdx,
  input  logic io_in_0_bits_isVset,
  input  logic io_in_0_bits_firstUop,
  input  logic io_in_0_bits_lastUop,
  input  logic [6:0] io_in_0_bits_numUops,
  input  logic [6:0] io_in_0_bits_numWB,
  input  logic [2:0] io_in_0_bits_commitType,
  input  logic [7:0] io_in_0_bits_psrc_0,
  input  logic [7:0] io_in_0_bits_psrc_1,
  input  logic [7:0] io_in_0_bits_psrc_2,
  input  logic [7:0] io_in_0_bits_psrc_3,
  input  logic [7:0] io_in_0_bits_psrc_4,
  input  logic [7:0] io_in_0_bits_pdest,
  input  logic io_in_0_bits_robIdx_flag,
  input  logic [7:0] io_in_0_bits_robIdx_value,
  input  logic [2:0] io_in_0_bits_instrSize,
  input  logic io_in_0_bits_dirtyFs,
  input  logic io_in_0_bits_dirtyVs,
  input  logic [3:0] io_in_0_bits_traceBlockInPipe_itype,
  input  logic [3:0] io_in_0_bits_traceBlockInPipe_iretire,
  input  logic io_in_0_bits_traceBlockInPipe_ilastsize,
  input  logic io_in_0_bits_eliminatedMove,
  input  logic io_in_0_bits_snapshot,
  input  logic [63:0] io_in_0_bits_debugInfo_renameTime,
  input  logic [55:0] io_in_0_bits_debug_seqNum_seqNum,
  input  logic [7:0] io_in_0_bits_debug_seqNum_uopIdx,
  input  logic [34:0] io_in_0_bits_debug_fuType,
  input  logic io_in_0_bits_debug_sim_trig,
  input  logic [4:0] io_in_0_bits_numLsElem,
  output logic io_in_1_ready,
  input  logic io_in_1_valid,
  input  logic [31:0] io_in_1_bits_instr,
  input  logic [49:0] io_in_1_bits_pc,
  input  logic [9:0] io_in_1_bits_foldpc,
  input  logic io_in_1_bits_exceptionVec_0,
  input  logic io_in_1_bits_exceptionVec_1,
  input  logic io_in_1_bits_exceptionVec_2,
  input  logic io_in_1_bits_exceptionVec_3,
  input  logic io_in_1_bits_exceptionVec_4,
  input  logic io_in_1_bits_exceptionVec_5,
  input  logic io_in_1_bits_exceptionVec_6,
  input  logic io_in_1_bits_exceptionVec_7,
  input  logic io_in_1_bits_exceptionVec_8,
  input  logic io_in_1_bits_exceptionVec_9,
  input  logic io_in_1_bits_exceptionVec_10,
  input  logic io_in_1_bits_exceptionVec_11,
  input  logic io_in_1_bits_exceptionVec_12,
  input  logic io_in_1_bits_exceptionVec_13,
  input  logic io_in_1_bits_exceptionVec_14,
  input  logic io_in_1_bits_exceptionVec_15,
  input  logic io_in_1_bits_exceptionVec_16,
  input  logic io_in_1_bits_exceptionVec_17,
  input  logic io_in_1_bits_exceptionVec_18,
  input  logic io_in_1_bits_exceptionVec_19,
  input  logic io_in_1_bits_exceptionVec_20,
  input  logic io_in_1_bits_exceptionVec_21,
  input  logic io_in_1_bits_exceptionVec_22,
  input  logic io_in_1_bits_exceptionVec_23,
  input  logic io_in_1_bits_isFetchMalAddr,
  input  logic io_in_1_bits_hasException,
  input  logic [3:0] io_in_1_bits_trigger,
  input  logic io_in_1_bits_preDecodeInfo_valid,
  input  logic io_in_1_bits_preDecodeInfo_isRVC,
  input  logic [1:0] io_in_1_bits_preDecodeInfo_brType,
  input  logic io_in_1_bits_preDecodeInfo_isCall,
  input  logic io_in_1_bits_preDecodeInfo_isRet,
  input  logic io_in_1_bits_pred_taken,
  input  logic io_in_1_bits_crossPageIPFFix,
  input  logic io_in_1_bits_ftqPtr_flag,
  input  logic [5:0] io_in_1_bits_ftqPtr_value,
  input  logic [3:0] io_in_1_bits_ftqOffset,
  input  logic io_in_1_bits_satpFlushFirstFetchFault,
  input  logic [3:0] io_in_1_bits_srcType_0,
  input  logic [3:0] io_in_1_bits_srcType_1,
  input  logic [3:0] io_in_1_bits_srcType_2,
  input  logic [3:0] io_in_1_bits_srcType_3,
  input  logic [3:0] io_in_1_bits_srcType_4,
  input  logic [5:0] io_in_1_bits_ldest,
  input  logic [34:0] io_in_1_bits_fuType,
  input  logic [8:0] io_in_1_bits_fuOpType,
  input  logic io_in_1_bits_rfWen,
  input  logic io_in_1_bits_fpWen,
  input  logic io_in_1_bits_vecWen,
  input  logic io_in_1_bits_v0Wen,
  input  logic io_in_1_bits_vlWen,
  input  logic io_in_1_bits_isXSTrap,
  input  logic io_in_1_bits_waitForward,
  input  logic io_in_1_bits_blockBackward,
  input  logic io_in_1_bits_flushPipe,
  input  logic io_in_1_bits_canRobCompress,
  input  logic [3:0] io_in_1_bits_selImm,
  input  logic [31:0] io_in_1_bits_imm,
  input  logic [1:0] io_in_1_bits_fpu_typeTagOut,
  input  logic io_in_1_bits_fpu_wflags,
  input  logic [1:0] io_in_1_bits_fpu_typ,
  input  logic [1:0] io_in_1_bits_fpu_fmt,
  input  logic [2:0] io_in_1_bits_fpu_rm,
  input  logic io_in_1_bits_vpu_vill,
  input  logic io_in_1_bits_vpu_vma,
  input  logic io_in_1_bits_vpu_vta,
  input  logic [1:0] io_in_1_bits_vpu_vsew,
  input  logic [2:0] io_in_1_bits_vpu_vlmul,
  input  logic io_in_1_bits_vpu_specVill,
  input  logic io_in_1_bits_vpu_specVma,
  input  logic io_in_1_bits_vpu_specVta,
  input  logic [1:0] io_in_1_bits_vpu_specVsew,
  input  logic [2:0] io_in_1_bits_vpu_specVlmul,
  input  logic io_in_1_bits_vpu_vm,
  input  logic [7:0] io_in_1_bits_vpu_vstart,
  input  logic [2:0] io_in_1_bits_vpu_frm,
  input  logic io_in_1_bits_vpu_fpu_isFpToVecInst,
  input  logic io_in_1_bits_vpu_fpu_isFP32Instr,
  input  logic io_in_1_bits_vpu_fpu_isFP64Instr,
  input  logic io_in_1_bits_vpu_fpu_isReduction,
  input  logic io_in_1_bits_vpu_fpu_isFoldTo1_2,
  input  logic io_in_1_bits_vpu_fpu_isFoldTo1_4,
  input  logic io_in_1_bits_vpu_fpu_isFoldTo1_8,
  input  logic [1:0] io_in_1_bits_vpu_vxrm,
  input  logic [6:0] io_in_1_bits_vpu_vuopIdx,
  input  logic io_in_1_bits_vpu_lastUop,
  input  logic [127:0] io_in_1_bits_vpu_vmask,
  input  logic [7:0] io_in_1_bits_vpu_vl,
  input  logic [2:0] io_in_1_bits_vpu_nf,
  input  logic [1:0] io_in_1_bits_vpu_veew,
  input  logic io_in_1_bits_vpu_isReverse,
  input  logic io_in_1_bits_vpu_isExt,
  input  logic io_in_1_bits_vpu_isNarrow,
  input  logic io_in_1_bits_vpu_isDstMask,
  input  logic io_in_1_bits_vpu_isOpMask,
  input  logic io_in_1_bits_vpu_isMove,
  input  logic io_in_1_bits_vpu_isDependOldVd,
  input  logic io_in_1_bits_vpu_isWritePartVd,
  input  logic io_in_1_bits_vpu_isVleff,
  input  logic io_in_1_bits_vlsInstr,
  input  logic io_in_1_bits_wfflags,
  input  logic io_in_1_bits_isMove,
  input  logic [6:0] io_in_1_bits_uopIdx,
  input  logic io_in_1_bits_isVset,
  input  logic io_in_1_bits_firstUop,
  input  logic io_in_1_bits_lastUop,
  input  logic [6:0] io_in_1_bits_numUops,
  input  logic [6:0] io_in_1_bits_numWB,
  input  logic [2:0] io_in_1_bits_commitType,
  input  logic [7:0] io_in_1_bits_psrc_0,
  input  logic [7:0] io_in_1_bits_psrc_1,
  input  logic [7:0] io_in_1_bits_psrc_2,
  input  logic [7:0] io_in_1_bits_psrc_3,
  input  logic [7:0] io_in_1_bits_psrc_4,
  input  logic [7:0] io_in_1_bits_pdest,
  input  logic io_in_1_bits_robIdx_flag,
  input  logic [7:0] io_in_1_bits_robIdx_value,
  input  logic [2:0] io_in_1_bits_instrSize,
  input  logic io_in_1_bits_dirtyFs,
  input  logic io_in_1_bits_dirtyVs,
  input  logic [3:0] io_in_1_bits_traceBlockInPipe_itype,
  input  logic [3:0] io_in_1_bits_traceBlockInPipe_iretire,
  input  logic io_in_1_bits_traceBlockInPipe_ilastsize,
  input  logic io_in_1_bits_eliminatedMove,
  input  logic [63:0] io_in_1_bits_debugInfo_renameTime,
  input  logic [55:0] io_in_1_bits_debug_seqNum_seqNum,
  input  logic [7:0] io_in_1_bits_debug_seqNum_uopIdx,
  input  logic [34:0] io_in_1_bits_debug_fuType,
  input  logic io_in_1_bits_debug_sim_trig,
  input  logic [4:0] io_in_1_bits_numLsElem,
  output logic io_in_2_ready,
  input  logic io_in_2_valid,
  input  logic [31:0] io_in_2_bits_instr,
  input  logic [49:0] io_in_2_bits_pc,
  input  logic [9:0] io_in_2_bits_foldpc,
  input  logic io_in_2_bits_exceptionVec_0,
  input  logic io_in_2_bits_exceptionVec_1,
  input  logic io_in_2_bits_exceptionVec_2,
  input  logic io_in_2_bits_exceptionVec_3,
  input  logic io_in_2_bits_exceptionVec_4,
  input  logic io_in_2_bits_exceptionVec_5,
  input  logic io_in_2_bits_exceptionVec_6,
  input  logic io_in_2_bits_exceptionVec_7,
  input  logic io_in_2_bits_exceptionVec_8,
  input  logic io_in_2_bits_exceptionVec_9,
  input  logic io_in_2_bits_exceptionVec_10,
  input  logic io_in_2_bits_exceptionVec_11,
  input  logic io_in_2_bits_exceptionVec_12,
  input  logic io_in_2_bits_exceptionVec_13,
  input  logic io_in_2_bits_exceptionVec_14,
  input  logic io_in_2_bits_exceptionVec_15,
  input  logic io_in_2_bits_exceptionVec_16,
  input  logic io_in_2_bits_exceptionVec_17,
  input  logic io_in_2_bits_exceptionVec_18,
  input  logic io_in_2_bits_exceptionVec_19,
  input  logic io_in_2_bits_exceptionVec_20,
  input  logic io_in_2_bits_exceptionVec_21,
  input  logic io_in_2_bits_exceptionVec_22,
  input  logic io_in_2_bits_exceptionVec_23,
  input  logic io_in_2_bits_isFetchMalAddr,
  input  logic io_in_2_bits_hasException,
  input  logic [3:0] io_in_2_bits_trigger,
  input  logic io_in_2_bits_preDecodeInfo_valid,
  input  logic io_in_2_bits_preDecodeInfo_isRVC,
  input  logic [1:0] io_in_2_bits_preDecodeInfo_brType,
  input  logic io_in_2_bits_preDecodeInfo_isCall,
  input  logic io_in_2_bits_preDecodeInfo_isRet,
  input  logic io_in_2_bits_pred_taken,
  input  logic io_in_2_bits_crossPageIPFFix,
  input  logic io_in_2_bits_ftqPtr_flag,
  input  logic [5:0] io_in_2_bits_ftqPtr_value,
  input  logic [3:0] io_in_2_bits_ftqOffset,
  input  logic io_in_2_bits_satpFlushFirstFetchFault,
  input  logic [3:0] io_in_2_bits_srcType_0,
  input  logic [3:0] io_in_2_bits_srcType_1,
  input  logic [3:0] io_in_2_bits_srcType_2,
  input  logic [3:0] io_in_2_bits_srcType_3,
  input  logic [3:0] io_in_2_bits_srcType_4,
  input  logic [5:0] io_in_2_bits_ldest,
  input  logic [34:0] io_in_2_bits_fuType,
  input  logic [8:0] io_in_2_bits_fuOpType,
  input  logic io_in_2_bits_rfWen,
  input  logic io_in_2_bits_fpWen,
  input  logic io_in_2_bits_vecWen,
  input  logic io_in_2_bits_v0Wen,
  input  logic io_in_2_bits_vlWen,
  input  logic io_in_2_bits_isXSTrap,
  input  logic io_in_2_bits_waitForward,
  input  logic io_in_2_bits_blockBackward,
  input  logic io_in_2_bits_flushPipe,
  input  logic io_in_2_bits_canRobCompress,
  input  logic [3:0] io_in_2_bits_selImm,
  input  logic [31:0] io_in_2_bits_imm,
  input  logic [1:0] io_in_2_bits_fpu_typeTagOut,
  input  logic io_in_2_bits_fpu_wflags,
  input  logic [1:0] io_in_2_bits_fpu_typ,
  input  logic [1:0] io_in_2_bits_fpu_fmt,
  input  logic [2:0] io_in_2_bits_fpu_rm,
  input  logic io_in_2_bits_vpu_vill,
  input  logic io_in_2_bits_vpu_vma,
  input  logic io_in_2_bits_vpu_vta,
  input  logic [1:0] io_in_2_bits_vpu_vsew,
  input  logic [2:0] io_in_2_bits_vpu_vlmul,
  input  logic io_in_2_bits_vpu_specVill,
  input  logic io_in_2_bits_vpu_specVma,
  input  logic io_in_2_bits_vpu_specVta,
  input  logic [1:0] io_in_2_bits_vpu_specVsew,
  input  logic [2:0] io_in_2_bits_vpu_specVlmul,
  input  logic io_in_2_bits_vpu_vm,
  input  logic [7:0] io_in_2_bits_vpu_vstart,
  input  logic [2:0] io_in_2_bits_vpu_frm,
  input  logic io_in_2_bits_vpu_fpu_isFpToVecInst,
  input  logic io_in_2_bits_vpu_fpu_isFP32Instr,
  input  logic io_in_2_bits_vpu_fpu_isFP64Instr,
  input  logic io_in_2_bits_vpu_fpu_isReduction,
  input  logic io_in_2_bits_vpu_fpu_isFoldTo1_2,
  input  logic io_in_2_bits_vpu_fpu_isFoldTo1_4,
  input  logic io_in_2_bits_vpu_fpu_isFoldTo1_8,
  input  logic [1:0] io_in_2_bits_vpu_vxrm,
  input  logic [6:0] io_in_2_bits_vpu_vuopIdx,
  input  logic io_in_2_bits_vpu_lastUop,
  input  logic [127:0] io_in_2_bits_vpu_vmask,
  input  logic [7:0] io_in_2_bits_vpu_vl,
  input  logic [2:0] io_in_2_bits_vpu_nf,
  input  logic [1:0] io_in_2_bits_vpu_veew,
  input  logic io_in_2_bits_vpu_isReverse,
  input  logic io_in_2_bits_vpu_isExt,
  input  logic io_in_2_bits_vpu_isNarrow,
  input  logic io_in_2_bits_vpu_isDstMask,
  input  logic io_in_2_bits_vpu_isOpMask,
  input  logic io_in_2_bits_vpu_isMove,
  input  logic io_in_2_bits_vpu_isDependOldVd,
  input  logic io_in_2_bits_vpu_isWritePartVd,
  input  logic io_in_2_bits_vpu_isVleff,
  input  logic io_in_2_bits_vlsInstr,
  input  logic io_in_2_bits_wfflags,
  input  logic io_in_2_bits_isMove,
  input  logic [6:0] io_in_2_bits_uopIdx,
  input  logic io_in_2_bits_isVset,
  input  logic io_in_2_bits_firstUop,
  input  logic io_in_2_bits_lastUop,
  input  logic [6:0] io_in_2_bits_numUops,
  input  logic [6:0] io_in_2_bits_numWB,
  input  logic [2:0] io_in_2_bits_commitType,
  input  logic [7:0] io_in_2_bits_psrc_0,
  input  logic [7:0] io_in_2_bits_psrc_1,
  input  logic [7:0] io_in_2_bits_psrc_2,
  input  logic [7:0] io_in_2_bits_psrc_3,
  input  logic [7:0] io_in_2_bits_psrc_4,
  input  logic [7:0] io_in_2_bits_pdest,
  input  logic io_in_2_bits_robIdx_flag,
  input  logic [7:0] io_in_2_bits_robIdx_value,
  input  logic [2:0] io_in_2_bits_instrSize,
  input  logic io_in_2_bits_dirtyFs,
  input  logic io_in_2_bits_dirtyVs,
  input  logic [3:0] io_in_2_bits_traceBlockInPipe_itype,
  input  logic [3:0] io_in_2_bits_traceBlockInPipe_iretire,
  input  logic io_in_2_bits_traceBlockInPipe_ilastsize,
  input  logic io_in_2_bits_eliminatedMove,
  input  logic [63:0] io_in_2_bits_debugInfo_renameTime,
  input  logic [55:0] io_in_2_bits_debug_seqNum_seqNum,
  input  logic [7:0] io_in_2_bits_debug_seqNum_uopIdx,
  input  logic [34:0] io_in_2_bits_debug_fuType,
  input  logic io_in_2_bits_debug_sim_trig,
  input  logic [4:0] io_in_2_bits_numLsElem,
  output logic io_in_3_ready,
  input  logic io_in_3_valid,
  input  logic [31:0] io_in_3_bits_instr,
  input  logic [49:0] io_in_3_bits_pc,
  input  logic [9:0] io_in_3_bits_foldpc,
  input  logic io_in_3_bits_exceptionVec_0,
  input  logic io_in_3_bits_exceptionVec_1,
  input  logic io_in_3_bits_exceptionVec_2,
  input  logic io_in_3_bits_exceptionVec_3,
  input  logic io_in_3_bits_exceptionVec_4,
  input  logic io_in_3_bits_exceptionVec_5,
  input  logic io_in_3_bits_exceptionVec_6,
  input  logic io_in_3_bits_exceptionVec_7,
  input  logic io_in_3_bits_exceptionVec_8,
  input  logic io_in_3_bits_exceptionVec_9,
  input  logic io_in_3_bits_exceptionVec_10,
  input  logic io_in_3_bits_exceptionVec_11,
  input  logic io_in_3_bits_exceptionVec_12,
  input  logic io_in_3_bits_exceptionVec_13,
  input  logic io_in_3_bits_exceptionVec_14,
  input  logic io_in_3_bits_exceptionVec_15,
  input  logic io_in_3_bits_exceptionVec_16,
  input  logic io_in_3_bits_exceptionVec_17,
  input  logic io_in_3_bits_exceptionVec_18,
  input  logic io_in_3_bits_exceptionVec_19,
  input  logic io_in_3_bits_exceptionVec_20,
  input  logic io_in_3_bits_exceptionVec_21,
  input  logic io_in_3_bits_exceptionVec_22,
  input  logic io_in_3_bits_exceptionVec_23,
  input  logic io_in_3_bits_isFetchMalAddr,
  input  logic io_in_3_bits_hasException,
  input  logic [3:0] io_in_3_bits_trigger,
  input  logic io_in_3_bits_preDecodeInfo_valid,
  input  logic io_in_3_bits_preDecodeInfo_isRVC,
  input  logic [1:0] io_in_3_bits_preDecodeInfo_brType,
  input  logic io_in_3_bits_preDecodeInfo_isCall,
  input  logic io_in_3_bits_preDecodeInfo_isRet,
  input  logic io_in_3_bits_pred_taken,
  input  logic io_in_3_bits_crossPageIPFFix,
  input  logic io_in_3_bits_ftqPtr_flag,
  input  logic [5:0] io_in_3_bits_ftqPtr_value,
  input  logic [3:0] io_in_3_bits_ftqOffset,
  input  logic io_in_3_bits_satpFlushFirstFetchFault,
  input  logic [3:0] io_in_3_bits_srcType_0,
  input  logic [3:0] io_in_3_bits_srcType_1,
  input  logic [3:0] io_in_3_bits_srcType_2,
  input  logic [3:0] io_in_3_bits_srcType_3,
  input  logic [3:0] io_in_3_bits_srcType_4,
  input  logic [5:0] io_in_3_bits_ldest,
  input  logic [34:0] io_in_3_bits_fuType,
  input  logic [8:0] io_in_3_bits_fuOpType,
  input  logic io_in_3_bits_rfWen,
  input  logic io_in_3_bits_fpWen,
  input  logic io_in_3_bits_vecWen,
  input  logic io_in_3_bits_v0Wen,
  input  logic io_in_3_bits_vlWen,
  input  logic io_in_3_bits_isXSTrap,
  input  logic io_in_3_bits_waitForward,
  input  logic io_in_3_bits_blockBackward,
  input  logic io_in_3_bits_flushPipe,
  input  logic io_in_3_bits_canRobCompress,
  input  logic [3:0] io_in_3_bits_selImm,
  input  logic [31:0] io_in_3_bits_imm,
  input  logic [1:0] io_in_3_bits_fpu_typeTagOut,
  input  logic io_in_3_bits_fpu_wflags,
  input  logic [1:0] io_in_3_bits_fpu_typ,
  input  logic [1:0] io_in_3_bits_fpu_fmt,
  input  logic [2:0] io_in_3_bits_fpu_rm,
  input  logic io_in_3_bits_vpu_vill,
  input  logic io_in_3_bits_vpu_vma,
  input  logic io_in_3_bits_vpu_vta,
  input  logic [1:0] io_in_3_bits_vpu_vsew,
  input  logic [2:0] io_in_3_bits_vpu_vlmul,
  input  logic io_in_3_bits_vpu_specVill,
  input  logic io_in_3_bits_vpu_specVma,
  input  logic io_in_3_bits_vpu_specVta,
  input  logic [1:0] io_in_3_bits_vpu_specVsew,
  input  logic [2:0] io_in_3_bits_vpu_specVlmul,
  input  logic io_in_3_bits_vpu_vm,
  input  logic [7:0] io_in_3_bits_vpu_vstart,
  input  logic [2:0] io_in_3_bits_vpu_frm,
  input  logic io_in_3_bits_vpu_fpu_isFpToVecInst,
  input  logic io_in_3_bits_vpu_fpu_isFP32Instr,
  input  logic io_in_3_bits_vpu_fpu_isFP64Instr,
  input  logic io_in_3_bits_vpu_fpu_isReduction,
  input  logic io_in_3_bits_vpu_fpu_isFoldTo1_2,
  input  logic io_in_3_bits_vpu_fpu_isFoldTo1_4,
  input  logic io_in_3_bits_vpu_fpu_isFoldTo1_8,
  input  logic [1:0] io_in_3_bits_vpu_vxrm,
  input  logic [6:0] io_in_3_bits_vpu_vuopIdx,
  input  logic io_in_3_bits_vpu_lastUop,
  input  logic [127:0] io_in_3_bits_vpu_vmask,
  input  logic [7:0] io_in_3_bits_vpu_vl,
  input  logic [2:0] io_in_3_bits_vpu_nf,
  input  logic [1:0] io_in_3_bits_vpu_veew,
  input  logic io_in_3_bits_vpu_isReverse,
  input  logic io_in_3_bits_vpu_isExt,
  input  logic io_in_3_bits_vpu_isNarrow,
  input  logic io_in_3_bits_vpu_isDstMask,
  input  logic io_in_3_bits_vpu_isOpMask,
  input  logic io_in_3_bits_vpu_isMove,
  input  logic io_in_3_bits_vpu_isDependOldVd,
  input  logic io_in_3_bits_vpu_isWritePartVd,
  input  logic io_in_3_bits_vpu_isVleff,
  input  logic io_in_3_bits_vlsInstr,
  input  logic io_in_3_bits_wfflags,
  input  logic io_in_3_bits_isMove,
  input  logic [6:0] io_in_3_bits_uopIdx,
  input  logic io_in_3_bits_isVset,
  input  logic io_in_3_bits_firstUop,
  input  logic io_in_3_bits_lastUop,
  input  logic [6:0] io_in_3_bits_numUops,
  input  logic [6:0] io_in_3_bits_numWB,
  input  logic [2:0] io_in_3_bits_commitType,
  input  logic [7:0] io_in_3_bits_psrc_0,
  input  logic [7:0] io_in_3_bits_psrc_1,
  input  logic [7:0] io_in_3_bits_psrc_2,
  input  logic [7:0] io_in_3_bits_psrc_3,
  input  logic [7:0] io_in_3_bits_psrc_4,
  input  logic [7:0] io_in_3_bits_pdest,
  input  logic io_in_3_bits_robIdx_flag,
  input  logic [7:0] io_in_3_bits_robIdx_value,
  input  logic [2:0] io_in_3_bits_instrSize,
  input  logic io_in_3_bits_dirtyFs,
  input  logic io_in_3_bits_dirtyVs,
  input  logic [3:0] io_in_3_bits_traceBlockInPipe_itype,
  input  logic [3:0] io_in_3_bits_traceBlockInPipe_iretire,
  input  logic io_in_3_bits_traceBlockInPipe_ilastsize,
  input  logic io_in_3_bits_eliminatedMove,
  input  logic [63:0] io_in_3_bits_debugInfo_renameTime,
  input  logic [55:0] io_in_3_bits_debug_seqNum_seqNum,
  input  logic [7:0] io_in_3_bits_debug_seqNum_uopIdx,
  input  logic [34:0] io_in_3_bits_debug_fuType,
  input  logic io_in_3_bits_debug_sim_trig,
  input  logic [4:0] io_in_3_bits_numLsElem,
  output logic io_in_4_ready,
  input  logic io_in_4_valid,
  input  logic [31:0] io_in_4_bits_instr,
  input  logic [49:0] io_in_4_bits_pc,
  input  logic [9:0] io_in_4_bits_foldpc,
  input  logic io_in_4_bits_exceptionVec_0,
  input  logic io_in_4_bits_exceptionVec_1,
  input  logic io_in_4_bits_exceptionVec_2,
  input  logic io_in_4_bits_exceptionVec_3,
  input  logic io_in_4_bits_exceptionVec_4,
  input  logic io_in_4_bits_exceptionVec_5,
  input  logic io_in_4_bits_exceptionVec_6,
  input  logic io_in_4_bits_exceptionVec_7,
  input  logic io_in_4_bits_exceptionVec_8,
  input  logic io_in_4_bits_exceptionVec_9,
  input  logic io_in_4_bits_exceptionVec_10,
  input  logic io_in_4_bits_exceptionVec_11,
  input  logic io_in_4_bits_exceptionVec_12,
  input  logic io_in_4_bits_exceptionVec_13,
  input  logic io_in_4_bits_exceptionVec_14,
  input  logic io_in_4_bits_exceptionVec_15,
  input  logic io_in_4_bits_exceptionVec_16,
  input  logic io_in_4_bits_exceptionVec_17,
  input  logic io_in_4_bits_exceptionVec_18,
  input  logic io_in_4_bits_exceptionVec_19,
  input  logic io_in_4_bits_exceptionVec_20,
  input  logic io_in_4_bits_exceptionVec_21,
  input  logic io_in_4_bits_exceptionVec_22,
  input  logic io_in_4_bits_exceptionVec_23,
  input  logic io_in_4_bits_isFetchMalAddr,
  input  logic io_in_4_bits_hasException,
  input  logic [3:0] io_in_4_bits_trigger,
  input  logic io_in_4_bits_preDecodeInfo_valid,
  input  logic io_in_4_bits_preDecodeInfo_isRVC,
  input  logic [1:0] io_in_4_bits_preDecodeInfo_brType,
  input  logic io_in_4_bits_preDecodeInfo_isCall,
  input  logic io_in_4_bits_preDecodeInfo_isRet,
  input  logic io_in_4_bits_pred_taken,
  input  logic io_in_4_bits_crossPageIPFFix,
  input  logic io_in_4_bits_ftqPtr_flag,
  input  logic [5:0] io_in_4_bits_ftqPtr_value,
  input  logic [3:0] io_in_4_bits_ftqOffset,
  input  logic io_in_4_bits_satpFlushFirstFetchFault,
  input  logic [3:0] io_in_4_bits_srcType_0,
  input  logic [3:0] io_in_4_bits_srcType_1,
  input  logic [3:0] io_in_4_bits_srcType_2,
  input  logic [3:0] io_in_4_bits_srcType_3,
  input  logic [3:0] io_in_4_bits_srcType_4,
  input  logic [5:0] io_in_4_bits_ldest,
  input  logic [34:0] io_in_4_bits_fuType,
  input  logic [8:0] io_in_4_bits_fuOpType,
  input  logic io_in_4_bits_rfWen,
  input  logic io_in_4_bits_fpWen,
  input  logic io_in_4_bits_vecWen,
  input  logic io_in_4_bits_v0Wen,
  input  logic io_in_4_bits_vlWen,
  input  logic io_in_4_bits_isXSTrap,
  input  logic io_in_4_bits_waitForward,
  input  logic io_in_4_bits_blockBackward,
  input  logic io_in_4_bits_flushPipe,
  input  logic io_in_4_bits_canRobCompress,
  input  logic [3:0] io_in_4_bits_selImm,
  input  logic [31:0] io_in_4_bits_imm,
  input  logic [1:0] io_in_4_bits_fpu_typeTagOut,
  input  logic io_in_4_bits_fpu_wflags,
  input  logic [1:0] io_in_4_bits_fpu_typ,
  input  logic [1:0] io_in_4_bits_fpu_fmt,
  input  logic [2:0] io_in_4_bits_fpu_rm,
  input  logic io_in_4_bits_vpu_vill,
  input  logic io_in_4_bits_vpu_vma,
  input  logic io_in_4_bits_vpu_vta,
  input  logic [1:0] io_in_4_bits_vpu_vsew,
  input  logic [2:0] io_in_4_bits_vpu_vlmul,
  input  logic io_in_4_bits_vpu_specVill,
  input  logic io_in_4_bits_vpu_specVma,
  input  logic io_in_4_bits_vpu_specVta,
  input  logic [1:0] io_in_4_bits_vpu_specVsew,
  input  logic [2:0] io_in_4_bits_vpu_specVlmul,
  input  logic io_in_4_bits_vpu_vm,
  input  logic [7:0] io_in_4_bits_vpu_vstart,
  input  logic [2:0] io_in_4_bits_vpu_frm,
  input  logic io_in_4_bits_vpu_fpu_isFpToVecInst,
  input  logic io_in_4_bits_vpu_fpu_isFP32Instr,
  input  logic io_in_4_bits_vpu_fpu_isFP64Instr,
  input  logic io_in_4_bits_vpu_fpu_isReduction,
  input  logic io_in_4_bits_vpu_fpu_isFoldTo1_2,
  input  logic io_in_4_bits_vpu_fpu_isFoldTo1_4,
  input  logic io_in_4_bits_vpu_fpu_isFoldTo1_8,
  input  logic [1:0] io_in_4_bits_vpu_vxrm,
  input  logic [6:0] io_in_4_bits_vpu_vuopIdx,
  input  logic io_in_4_bits_vpu_lastUop,
  input  logic [127:0] io_in_4_bits_vpu_vmask,
  input  logic [7:0] io_in_4_bits_vpu_vl,
  input  logic [2:0] io_in_4_bits_vpu_nf,
  input  logic [1:0] io_in_4_bits_vpu_veew,
  input  logic io_in_4_bits_vpu_isReverse,
  input  logic io_in_4_bits_vpu_isExt,
  input  logic io_in_4_bits_vpu_isNarrow,
  input  logic io_in_4_bits_vpu_isDstMask,
  input  logic io_in_4_bits_vpu_isOpMask,
  input  logic io_in_4_bits_vpu_isMove,
  input  logic io_in_4_bits_vpu_isDependOldVd,
  input  logic io_in_4_bits_vpu_isWritePartVd,
  input  logic io_in_4_bits_vpu_isVleff,
  input  logic io_in_4_bits_vlsInstr,
  input  logic io_in_4_bits_wfflags,
  input  logic io_in_4_bits_isMove,
  input  logic [6:0] io_in_4_bits_uopIdx,
  input  logic io_in_4_bits_isVset,
  input  logic io_in_4_bits_firstUop,
  input  logic io_in_4_bits_lastUop,
  input  logic [6:0] io_in_4_bits_numUops,
  input  logic [6:0] io_in_4_bits_numWB,
  input  logic [2:0] io_in_4_bits_commitType,
  input  logic [7:0] io_in_4_bits_psrc_0,
  input  logic [7:0] io_in_4_bits_psrc_1,
  input  logic [7:0] io_in_4_bits_psrc_2,
  input  logic [7:0] io_in_4_bits_psrc_3,
  input  logic [7:0] io_in_4_bits_psrc_4,
  input  logic [7:0] io_in_4_bits_pdest,
  input  logic io_in_4_bits_robIdx_flag,
  input  logic [7:0] io_in_4_bits_robIdx_value,
  input  logic [2:0] io_in_4_bits_instrSize,
  input  logic io_in_4_bits_dirtyFs,
  input  logic io_in_4_bits_dirtyVs,
  input  logic [3:0] io_in_4_bits_traceBlockInPipe_itype,
  input  logic [3:0] io_in_4_bits_traceBlockInPipe_iretire,
  input  logic io_in_4_bits_traceBlockInPipe_ilastsize,
  input  logic io_in_4_bits_eliminatedMove,
  input  logic [63:0] io_in_4_bits_debugInfo_renameTime,
  input  logic [55:0] io_in_4_bits_debug_seqNum_seqNum,
  input  logic [7:0] io_in_4_bits_debug_seqNum_uopIdx,
  input  logic [34:0] io_in_4_bits_debug_fuType,
  input  logic io_in_4_bits_debug_sim_trig,
  input  logic [4:0] io_in_4_bits_numLsElem,
  output logic io_in_5_ready,
  input  logic io_in_5_valid,
  input  logic [31:0] io_in_5_bits_instr,
  input  logic [49:0] io_in_5_bits_pc,
  input  logic [9:0] io_in_5_bits_foldpc,
  input  logic io_in_5_bits_exceptionVec_0,
  input  logic io_in_5_bits_exceptionVec_1,
  input  logic io_in_5_bits_exceptionVec_2,
  input  logic io_in_5_bits_exceptionVec_3,
  input  logic io_in_5_bits_exceptionVec_4,
  input  logic io_in_5_bits_exceptionVec_5,
  input  logic io_in_5_bits_exceptionVec_6,
  input  logic io_in_5_bits_exceptionVec_7,
  input  logic io_in_5_bits_exceptionVec_8,
  input  logic io_in_5_bits_exceptionVec_9,
  input  logic io_in_5_bits_exceptionVec_10,
  input  logic io_in_5_bits_exceptionVec_11,
  input  logic io_in_5_bits_exceptionVec_12,
  input  logic io_in_5_bits_exceptionVec_13,
  input  logic io_in_5_bits_exceptionVec_14,
  input  logic io_in_5_bits_exceptionVec_15,
  input  logic io_in_5_bits_exceptionVec_16,
  input  logic io_in_5_bits_exceptionVec_17,
  input  logic io_in_5_bits_exceptionVec_18,
  input  logic io_in_5_bits_exceptionVec_19,
  input  logic io_in_5_bits_exceptionVec_20,
  input  logic io_in_5_bits_exceptionVec_21,
  input  logic io_in_5_bits_exceptionVec_22,
  input  logic io_in_5_bits_exceptionVec_23,
  input  logic io_in_5_bits_isFetchMalAddr,
  input  logic io_in_5_bits_hasException,
  input  logic [3:0] io_in_5_bits_trigger,
  input  logic io_in_5_bits_preDecodeInfo_valid,
  input  logic io_in_5_bits_preDecodeInfo_isRVC,
  input  logic [1:0] io_in_5_bits_preDecodeInfo_brType,
  input  logic io_in_5_bits_preDecodeInfo_isCall,
  input  logic io_in_5_bits_preDecodeInfo_isRet,
  input  logic io_in_5_bits_pred_taken,
  input  logic io_in_5_bits_crossPageIPFFix,
  input  logic io_in_5_bits_ftqPtr_flag,
  input  logic [5:0] io_in_5_bits_ftqPtr_value,
  input  logic [3:0] io_in_5_bits_ftqOffset,
  input  logic io_in_5_bits_satpFlushFirstFetchFault,
  input  logic [3:0] io_in_5_bits_srcType_0,
  input  logic [3:0] io_in_5_bits_srcType_1,
  input  logic [3:0] io_in_5_bits_srcType_2,
  input  logic [3:0] io_in_5_bits_srcType_3,
  input  logic [3:0] io_in_5_bits_srcType_4,
  input  logic [5:0] io_in_5_bits_ldest,
  input  logic [34:0] io_in_5_bits_fuType,
  input  logic [8:0] io_in_5_bits_fuOpType,
  input  logic io_in_5_bits_rfWen,
  input  logic io_in_5_bits_fpWen,
  input  logic io_in_5_bits_vecWen,
  input  logic io_in_5_bits_v0Wen,
  input  logic io_in_5_bits_vlWen,
  input  logic io_in_5_bits_isXSTrap,
  input  logic io_in_5_bits_waitForward,
  input  logic io_in_5_bits_blockBackward,
  input  logic io_in_5_bits_flushPipe,
  input  logic io_in_5_bits_canRobCompress,
  input  logic [3:0] io_in_5_bits_selImm,
  input  logic [31:0] io_in_5_bits_imm,
  input  logic [1:0] io_in_5_bits_fpu_typeTagOut,
  input  logic io_in_5_bits_fpu_wflags,
  input  logic [1:0] io_in_5_bits_fpu_typ,
  input  logic [1:0] io_in_5_bits_fpu_fmt,
  input  logic [2:0] io_in_5_bits_fpu_rm,
  input  logic io_in_5_bits_vpu_vill,
  input  logic io_in_5_bits_vpu_vma,
  input  logic io_in_5_bits_vpu_vta,
  input  logic [1:0] io_in_5_bits_vpu_vsew,
  input  logic [2:0] io_in_5_bits_vpu_vlmul,
  input  logic io_in_5_bits_vpu_specVill,
  input  logic io_in_5_bits_vpu_specVma,
  input  logic io_in_5_bits_vpu_specVta,
  input  logic [1:0] io_in_5_bits_vpu_specVsew,
  input  logic [2:0] io_in_5_bits_vpu_specVlmul,
  input  logic io_in_5_bits_vpu_vm,
  input  logic [7:0] io_in_5_bits_vpu_vstart,
  input  logic [2:0] io_in_5_bits_vpu_frm,
  input  logic io_in_5_bits_vpu_fpu_isFpToVecInst,
  input  logic io_in_5_bits_vpu_fpu_isFP32Instr,
  input  logic io_in_5_bits_vpu_fpu_isFP64Instr,
  input  logic io_in_5_bits_vpu_fpu_isReduction,
  input  logic io_in_5_bits_vpu_fpu_isFoldTo1_2,
  input  logic io_in_5_bits_vpu_fpu_isFoldTo1_4,
  input  logic io_in_5_bits_vpu_fpu_isFoldTo1_8,
  input  logic [1:0] io_in_5_bits_vpu_vxrm,
  input  logic [6:0] io_in_5_bits_vpu_vuopIdx,
  input  logic io_in_5_bits_vpu_lastUop,
  input  logic [127:0] io_in_5_bits_vpu_vmask,
  input  logic [7:0] io_in_5_bits_vpu_vl,
  input  logic [2:0] io_in_5_bits_vpu_nf,
  input  logic [1:0] io_in_5_bits_vpu_veew,
  input  logic io_in_5_bits_vpu_isReverse,
  input  logic io_in_5_bits_vpu_isExt,
  input  logic io_in_5_bits_vpu_isNarrow,
  input  logic io_in_5_bits_vpu_isDstMask,
  input  logic io_in_5_bits_vpu_isOpMask,
  input  logic io_in_5_bits_vpu_isMove,
  input  logic io_in_5_bits_vpu_isDependOldVd,
  input  logic io_in_5_bits_vpu_isWritePartVd,
  input  logic io_in_5_bits_vpu_isVleff,
  input  logic io_in_5_bits_vlsInstr,
  input  logic io_in_5_bits_wfflags,
  input  logic io_in_5_bits_isMove,
  input  logic [6:0] io_in_5_bits_uopIdx,
  input  logic io_in_5_bits_isVset,
  input  logic io_in_5_bits_firstUop,
  input  logic io_in_5_bits_lastUop,
  input  logic [6:0] io_in_5_bits_numUops,
  input  logic [6:0] io_in_5_bits_numWB,
  input  logic [2:0] io_in_5_bits_commitType,
  input  logic [7:0] io_in_5_bits_psrc_0,
  input  logic [7:0] io_in_5_bits_psrc_1,
  input  logic [7:0] io_in_5_bits_psrc_2,
  input  logic [7:0] io_in_5_bits_psrc_3,
  input  logic [7:0] io_in_5_bits_psrc_4,
  input  logic [7:0] io_in_5_bits_pdest,
  input  logic io_in_5_bits_robIdx_flag,
  input  logic [7:0] io_in_5_bits_robIdx_value,
  input  logic [2:0] io_in_5_bits_instrSize,
  input  logic io_in_5_bits_dirtyFs,
  input  logic io_in_5_bits_dirtyVs,
  input  logic [3:0] io_in_5_bits_traceBlockInPipe_itype,
  input  logic [3:0] io_in_5_bits_traceBlockInPipe_iretire,
  input  logic io_in_5_bits_traceBlockInPipe_ilastsize,
  input  logic io_in_5_bits_eliminatedMove,
  input  logic [63:0] io_in_5_bits_debugInfo_renameTime,
  input  logic [55:0] io_in_5_bits_debug_seqNum_seqNum,
  input  logic [7:0] io_in_5_bits_debug_seqNum_uopIdx,
  input  logic [34:0] io_in_5_bits_debug_fuType,
  input  logic io_in_5_bits_debug_sim_trig,
  input  logic [4:0] io_in_5_bits_numLsElem,
  input  logic io_out_0_ready,
  output logic io_out_0_valid,
  output logic [31:0] io_out_0_bits_instr,
  output logic [49:0] io_out_0_bits_pc,
  output logic [9:0] io_out_0_bits_foldpc,
  output logic io_out_0_bits_exceptionVec_0,
  output logic io_out_0_bits_exceptionVec_1,
  output logic io_out_0_bits_exceptionVec_2,
  output logic io_out_0_bits_exceptionVec_3,
  output logic io_out_0_bits_exceptionVec_4,
  output logic io_out_0_bits_exceptionVec_5,
  output logic io_out_0_bits_exceptionVec_6,
  output logic io_out_0_bits_exceptionVec_7,
  output logic io_out_0_bits_exceptionVec_8,
  output logic io_out_0_bits_exceptionVec_9,
  output logic io_out_0_bits_exceptionVec_10,
  output logic io_out_0_bits_exceptionVec_11,
  output logic io_out_0_bits_exceptionVec_12,
  output logic io_out_0_bits_exceptionVec_13,
  output logic io_out_0_bits_exceptionVec_14,
  output logic io_out_0_bits_exceptionVec_15,
  output logic io_out_0_bits_exceptionVec_16,
  output logic io_out_0_bits_exceptionVec_17,
  output logic io_out_0_bits_exceptionVec_18,
  output logic io_out_0_bits_exceptionVec_19,
  output logic io_out_0_bits_exceptionVec_20,
  output logic io_out_0_bits_exceptionVec_21,
  output logic io_out_0_bits_exceptionVec_22,
  output logic io_out_0_bits_exceptionVec_23,
  output logic io_out_0_bits_isFetchMalAddr,
  output logic io_out_0_bits_hasException,
  output logic [3:0] io_out_0_bits_trigger,
  output logic io_out_0_bits_preDecodeInfo_valid,
  output logic io_out_0_bits_preDecodeInfo_isRVC,
  output logic [1:0] io_out_0_bits_preDecodeInfo_brType,
  output logic io_out_0_bits_preDecodeInfo_isCall,
  output logic io_out_0_bits_preDecodeInfo_isRet,
  output logic io_out_0_bits_pred_taken,
  output logic io_out_0_bits_crossPageIPFFix,
  output logic io_out_0_bits_ftqPtr_flag,
  output logic [5:0] io_out_0_bits_ftqPtr_value,
  output logic [3:0] io_out_0_bits_ftqOffset,
  output logic io_out_0_bits_satpFlushFirstFetchFault,
  output logic [3:0] io_out_0_bits_srcType_0,
  output logic [3:0] io_out_0_bits_srcType_1,
  output logic [3:0] io_out_0_bits_srcType_2,
  output logic [3:0] io_out_0_bits_srcType_3,
  output logic [3:0] io_out_0_bits_srcType_4,
  output logic [5:0] io_out_0_bits_ldest,
  output logic [34:0] io_out_0_bits_fuType,
  output logic [8:0] io_out_0_bits_fuOpType,
  output logic io_out_0_bits_rfWen,
  output logic io_out_0_bits_fpWen,
  output logic io_out_0_bits_vecWen,
  output logic io_out_0_bits_v0Wen,
  output logic io_out_0_bits_vlWen,
  output logic io_out_0_bits_isXSTrap,
  output logic io_out_0_bits_waitForward,
  output logic io_out_0_bits_blockBackward,
  output logic io_out_0_bits_flushPipe,
  output logic io_out_0_bits_canRobCompress,
  output logic [3:0] io_out_0_bits_selImm,
  output logic [31:0] io_out_0_bits_imm,
  output logic [1:0] io_out_0_bits_fpu_typeTagOut,
  output logic io_out_0_bits_fpu_wflags,
  output logic [1:0] io_out_0_bits_fpu_typ,
  output logic [1:0] io_out_0_bits_fpu_fmt,
  output logic [2:0] io_out_0_bits_fpu_rm,
  output logic io_out_0_bits_vpu_vill,
  output logic io_out_0_bits_vpu_vma,
  output logic io_out_0_bits_vpu_vta,
  output logic [1:0] io_out_0_bits_vpu_vsew,
  output logic [2:0] io_out_0_bits_vpu_vlmul,
  output logic io_out_0_bits_vpu_specVill,
  output logic io_out_0_bits_vpu_specVma,
  output logic io_out_0_bits_vpu_specVta,
  output logic [1:0] io_out_0_bits_vpu_specVsew,
  output logic [2:0] io_out_0_bits_vpu_specVlmul,
  output logic io_out_0_bits_vpu_vm,
  output logic [7:0] io_out_0_bits_vpu_vstart,
  output logic [2:0] io_out_0_bits_vpu_frm,
  output logic io_out_0_bits_vpu_fpu_isFpToVecInst,
  output logic io_out_0_bits_vpu_fpu_isFP32Instr,
  output logic io_out_0_bits_vpu_fpu_isFP64Instr,
  output logic io_out_0_bits_vpu_fpu_isReduction,
  output logic io_out_0_bits_vpu_fpu_isFoldTo1_2,
  output logic io_out_0_bits_vpu_fpu_isFoldTo1_4,
  output logic io_out_0_bits_vpu_fpu_isFoldTo1_8,
  output logic [1:0] io_out_0_bits_vpu_vxrm,
  output logic [6:0] io_out_0_bits_vpu_vuopIdx,
  output logic io_out_0_bits_vpu_lastUop,
  output logic [127:0] io_out_0_bits_vpu_vmask,
  output logic [7:0] io_out_0_bits_vpu_vl,
  output logic [2:0] io_out_0_bits_vpu_nf,
  output logic [1:0] io_out_0_bits_vpu_veew,
  output logic io_out_0_bits_vpu_isReverse,
  output logic io_out_0_bits_vpu_isExt,
  output logic io_out_0_bits_vpu_isNarrow,
  output logic io_out_0_bits_vpu_isDstMask,
  output logic io_out_0_bits_vpu_isOpMask,
  output logic io_out_0_bits_vpu_isMove,
  output logic io_out_0_bits_vpu_isDependOldVd,
  output logic io_out_0_bits_vpu_isWritePartVd,
  output logic io_out_0_bits_vpu_isVleff,
  output logic io_out_0_bits_vlsInstr,
  output logic io_out_0_bits_wfflags,
  output logic io_out_0_bits_isMove,
  output logic [6:0] io_out_0_bits_uopIdx,
  output logic io_out_0_bits_isVset,
  output logic io_out_0_bits_firstUop,
  output logic io_out_0_bits_lastUop,
  output logic [6:0] io_out_0_bits_numUops,
  output logic [6:0] io_out_0_bits_numWB,
  output logic [2:0] io_out_0_bits_commitType,
  output logic [7:0] io_out_0_bits_psrc_0,
  output logic [7:0] io_out_0_bits_psrc_1,
  output logic [7:0] io_out_0_bits_psrc_2,
  output logic [7:0] io_out_0_bits_psrc_3,
  output logic [7:0] io_out_0_bits_psrc_4,
  output logic [7:0] io_out_0_bits_pdest,
  output logic io_out_0_bits_robIdx_flag,
  output logic [7:0] io_out_0_bits_robIdx_value,
  output logic [2:0] io_out_0_bits_instrSize,
  output logic io_out_0_bits_dirtyFs,
  output logic io_out_0_bits_dirtyVs,
  output logic [3:0] io_out_0_bits_traceBlockInPipe_itype,
  output logic [3:0] io_out_0_bits_traceBlockInPipe_iretire,
  output logic io_out_0_bits_traceBlockInPipe_ilastsize,
  output logic io_out_0_bits_eliminatedMove,
  output logic io_out_0_bits_snapshot,
  output logic [63:0] io_out_0_bits_debugInfo_renameTime,
  output logic [55:0] io_out_0_bits_debug_seqNum_seqNum,
  output logic [7:0] io_out_0_bits_debug_seqNum_uopIdx,
  output logic [34:0] io_out_0_bits_debug_fuType,
  output logic io_out_0_bits_debug_sim_trig,
  output logic [4:0] io_out_0_bits_numLsElem,
  input  logic io_out_1_ready,
  output logic io_out_1_valid,
  output logic [31:0] io_out_1_bits_instr,
  output logic [49:0] io_out_1_bits_pc,
  output logic [9:0] io_out_1_bits_foldpc,
  output logic io_out_1_bits_exceptionVec_0,
  output logic io_out_1_bits_exceptionVec_1,
  output logic io_out_1_bits_exceptionVec_2,
  output logic io_out_1_bits_exceptionVec_3,
  output logic io_out_1_bits_exceptionVec_4,
  output logic io_out_1_bits_exceptionVec_5,
  output logic io_out_1_bits_exceptionVec_6,
  output logic io_out_1_bits_exceptionVec_7,
  output logic io_out_1_bits_exceptionVec_8,
  output logic io_out_1_bits_exceptionVec_9,
  output logic io_out_1_bits_exceptionVec_10,
  output logic io_out_1_bits_exceptionVec_11,
  output logic io_out_1_bits_exceptionVec_12,
  output logic io_out_1_bits_exceptionVec_13,
  output logic io_out_1_bits_exceptionVec_14,
  output logic io_out_1_bits_exceptionVec_15,
  output logic io_out_1_bits_exceptionVec_16,
  output logic io_out_1_bits_exceptionVec_17,
  output logic io_out_1_bits_exceptionVec_18,
  output logic io_out_1_bits_exceptionVec_19,
  output logic io_out_1_bits_exceptionVec_20,
  output logic io_out_1_bits_exceptionVec_21,
  output logic io_out_1_bits_exceptionVec_22,
  output logic io_out_1_bits_exceptionVec_23,
  output logic io_out_1_bits_isFetchMalAddr,
  output logic io_out_1_bits_hasException,
  output logic [3:0] io_out_1_bits_trigger,
  output logic io_out_1_bits_preDecodeInfo_valid,
  output logic io_out_1_bits_preDecodeInfo_isRVC,
  output logic [1:0] io_out_1_bits_preDecodeInfo_brType,
  output logic io_out_1_bits_preDecodeInfo_isCall,
  output logic io_out_1_bits_preDecodeInfo_isRet,
  output logic io_out_1_bits_pred_taken,
  output logic io_out_1_bits_crossPageIPFFix,
  output logic io_out_1_bits_ftqPtr_flag,
  output logic [5:0] io_out_1_bits_ftqPtr_value,
  output logic [3:0] io_out_1_bits_ftqOffset,
  output logic io_out_1_bits_satpFlushFirstFetchFault,
  output logic [3:0] io_out_1_bits_srcType_0,
  output logic [3:0] io_out_1_bits_srcType_1,
  output logic [3:0] io_out_1_bits_srcType_2,
  output logic [3:0] io_out_1_bits_srcType_3,
  output logic [3:0] io_out_1_bits_srcType_4,
  output logic [5:0] io_out_1_bits_ldest,
  output logic [34:0] io_out_1_bits_fuType,
  output logic [8:0] io_out_1_bits_fuOpType,
  output logic io_out_1_bits_rfWen,
  output logic io_out_1_bits_fpWen,
  output logic io_out_1_bits_vecWen,
  output logic io_out_1_bits_v0Wen,
  output logic io_out_1_bits_vlWen,
  output logic io_out_1_bits_isXSTrap,
  output logic io_out_1_bits_waitForward,
  output logic io_out_1_bits_blockBackward,
  output logic io_out_1_bits_flushPipe,
  output logic io_out_1_bits_canRobCompress,
  output logic [3:0] io_out_1_bits_selImm,
  output logic [31:0] io_out_1_bits_imm,
  output logic [1:0] io_out_1_bits_fpu_typeTagOut,
  output logic io_out_1_bits_fpu_wflags,
  output logic [1:0] io_out_1_bits_fpu_typ,
  output logic [1:0] io_out_1_bits_fpu_fmt,
  output logic [2:0] io_out_1_bits_fpu_rm,
  output logic io_out_1_bits_vpu_vill,
  output logic io_out_1_bits_vpu_vma,
  output logic io_out_1_bits_vpu_vta,
  output logic [1:0] io_out_1_bits_vpu_vsew,
  output logic [2:0] io_out_1_bits_vpu_vlmul,
  output logic io_out_1_bits_vpu_specVill,
  output logic io_out_1_bits_vpu_specVma,
  output logic io_out_1_bits_vpu_specVta,
  output logic [1:0] io_out_1_bits_vpu_specVsew,
  output logic [2:0] io_out_1_bits_vpu_specVlmul,
  output logic io_out_1_bits_vpu_vm,
  output logic [7:0] io_out_1_bits_vpu_vstart,
  output logic [2:0] io_out_1_bits_vpu_frm,
  output logic io_out_1_bits_vpu_fpu_isFpToVecInst,
  output logic io_out_1_bits_vpu_fpu_isFP32Instr,
  output logic io_out_1_bits_vpu_fpu_isFP64Instr,
  output logic io_out_1_bits_vpu_fpu_isReduction,
  output logic io_out_1_bits_vpu_fpu_isFoldTo1_2,
  output logic io_out_1_bits_vpu_fpu_isFoldTo1_4,
  output logic io_out_1_bits_vpu_fpu_isFoldTo1_8,
  output logic [1:0] io_out_1_bits_vpu_vxrm,
  output logic [6:0] io_out_1_bits_vpu_vuopIdx,
  output logic io_out_1_bits_vpu_lastUop,
  output logic [127:0] io_out_1_bits_vpu_vmask,
  output logic [7:0] io_out_1_bits_vpu_vl,
  output logic [2:0] io_out_1_bits_vpu_nf,
  output logic [1:0] io_out_1_bits_vpu_veew,
  output logic io_out_1_bits_vpu_isReverse,
  output logic io_out_1_bits_vpu_isExt,
  output logic io_out_1_bits_vpu_isNarrow,
  output logic io_out_1_bits_vpu_isDstMask,
  output logic io_out_1_bits_vpu_isOpMask,
  output logic io_out_1_bits_vpu_isMove,
  output logic io_out_1_bits_vpu_isDependOldVd,
  output logic io_out_1_bits_vpu_isWritePartVd,
  output logic io_out_1_bits_vpu_isVleff,
  output logic io_out_1_bits_vlsInstr,
  output logic io_out_1_bits_wfflags,
  output logic io_out_1_bits_isMove,
  output logic [6:0] io_out_1_bits_uopIdx,
  output logic io_out_1_bits_isVset,
  output logic io_out_1_bits_firstUop,
  output logic io_out_1_bits_lastUop,
  output logic [6:0] io_out_1_bits_numUops,
  output logic [6:0] io_out_1_bits_numWB,
  output logic [2:0] io_out_1_bits_commitType,
  output logic [7:0] io_out_1_bits_psrc_0,
  output logic [7:0] io_out_1_bits_psrc_1,
  output logic [7:0] io_out_1_bits_psrc_2,
  output logic [7:0] io_out_1_bits_psrc_3,
  output logic [7:0] io_out_1_bits_psrc_4,
  output logic [7:0] io_out_1_bits_pdest,
  output logic io_out_1_bits_robIdx_flag,
  output logic [7:0] io_out_1_bits_robIdx_value,
  output logic [2:0] io_out_1_bits_instrSize,
  output logic io_out_1_bits_dirtyFs,
  output logic io_out_1_bits_dirtyVs,
  output logic [3:0] io_out_1_bits_traceBlockInPipe_itype,
  output logic [3:0] io_out_1_bits_traceBlockInPipe_iretire,
  output logic io_out_1_bits_traceBlockInPipe_ilastsize,
  output logic io_out_1_bits_eliminatedMove,
  output logic [63:0] io_out_1_bits_debugInfo_renameTime,
  output logic [55:0] io_out_1_bits_debug_seqNum_seqNum,
  output logic [7:0] io_out_1_bits_debug_seqNum_uopIdx,
  output logic [34:0] io_out_1_bits_debug_fuType,
  output logic io_out_1_bits_debug_sim_trig,
  output logic [4:0] io_out_1_bits_numLsElem,
  input  logic io_out_2_ready,
  output logic io_out_2_valid,
  output logic [31:0] io_out_2_bits_instr,
  output logic [49:0] io_out_2_bits_pc,
  output logic [9:0] io_out_2_bits_foldpc,
  output logic io_out_2_bits_exceptionVec_0,
  output logic io_out_2_bits_exceptionVec_1,
  output logic io_out_2_bits_exceptionVec_2,
  output logic io_out_2_bits_exceptionVec_3,
  output logic io_out_2_bits_exceptionVec_4,
  output logic io_out_2_bits_exceptionVec_5,
  output logic io_out_2_bits_exceptionVec_6,
  output logic io_out_2_bits_exceptionVec_7,
  output logic io_out_2_bits_exceptionVec_8,
  output logic io_out_2_bits_exceptionVec_9,
  output logic io_out_2_bits_exceptionVec_10,
  output logic io_out_2_bits_exceptionVec_11,
  output logic io_out_2_bits_exceptionVec_12,
  output logic io_out_2_bits_exceptionVec_13,
  output logic io_out_2_bits_exceptionVec_14,
  output logic io_out_2_bits_exceptionVec_15,
  output logic io_out_2_bits_exceptionVec_16,
  output logic io_out_2_bits_exceptionVec_17,
  output logic io_out_2_bits_exceptionVec_18,
  output logic io_out_2_bits_exceptionVec_19,
  output logic io_out_2_bits_exceptionVec_20,
  output logic io_out_2_bits_exceptionVec_21,
  output logic io_out_2_bits_exceptionVec_22,
  output logic io_out_2_bits_exceptionVec_23,
  output logic io_out_2_bits_isFetchMalAddr,
  output logic io_out_2_bits_hasException,
  output logic [3:0] io_out_2_bits_trigger,
  output logic io_out_2_bits_preDecodeInfo_valid,
  output logic io_out_2_bits_preDecodeInfo_isRVC,
  output logic [1:0] io_out_2_bits_preDecodeInfo_brType,
  output logic io_out_2_bits_preDecodeInfo_isCall,
  output logic io_out_2_bits_preDecodeInfo_isRet,
  output logic io_out_2_bits_pred_taken,
  output logic io_out_2_bits_crossPageIPFFix,
  output logic io_out_2_bits_ftqPtr_flag,
  output logic [5:0] io_out_2_bits_ftqPtr_value,
  output logic [3:0] io_out_2_bits_ftqOffset,
  output logic io_out_2_bits_satpFlushFirstFetchFault,
  output logic [3:0] io_out_2_bits_srcType_0,
  output logic [3:0] io_out_2_bits_srcType_1,
  output logic [3:0] io_out_2_bits_srcType_2,
  output logic [3:0] io_out_2_bits_srcType_3,
  output logic [3:0] io_out_2_bits_srcType_4,
  output logic [5:0] io_out_2_bits_ldest,
  output logic [34:0] io_out_2_bits_fuType,
  output logic [8:0] io_out_2_bits_fuOpType,
  output logic io_out_2_bits_rfWen,
  output logic io_out_2_bits_fpWen,
  output logic io_out_2_bits_vecWen,
  output logic io_out_2_bits_v0Wen,
  output logic io_out_2_bits_vlWen,
  output logic io_out_2_bits_isXSTrap,
  output logic io_out_2_bits_waitForward,
  output logic io_out_2_bits_blockBackward,
  output logic io_out_2_bits_flushPipe,
  output logic io_out_2_bits_canRobCompress,
  output logic [3:0] io_out_2_bits_selImm,
  output logic [31:0] io_out_2_bits_imm,
  output logic [1:0] io_out_2_bits_fpu_typeTagOut,
  output logic io_out_2_bits_fpu_wflags,
  output logic [1:0] io_out_2_bits_fpu_typ,
  output logic [1:0] io_out_2_bits_fpu_fmt,
  output logic [2:0] io_out_2_bits_fpu_rm,
  output logic io_out_2_bits_vpu_vill,
  output logic io_out_2_bits_vpu_vma,
  output logic io_out_2_bits_vpu_vta,
  output logic [1:0] io_out_2_bits_vpu_vsew,
  output logic [2:0] io_out_2_bits_vpu_vlmul,
  output logic io_out_2_bits_vpu_specVill,
  output logic io_out_2_bits_vpu_specVma,
  output logic io_out_2_bits_vpu_specVta,
  output logic [1:0] io_out_2_bits_vpu_specVsew,
  output logic [2:0] io_out_2_bits_vpu_specVlmul,
  output logic io_out_2_bits_vpu_vm,
  output logic [7:0] io_out_2_bits_vpu_vstart,
  output logic [2:0] io_out_2_bits_vpu_frm,
  output logic io_out_2_bits_vpu_fpu_isFpToVecInst,
  output logic io_out_2_bits_vpu_fpu_isFP32Instr,
  output logic io_out_2_bits_vpu_fpu_isFP64Instr,
  output logic io_out_2_bits_vpu_fpu_isReduction,
  output logic io_out_2_bits_vpu_fpu_isFoldTo1_2,
  output logic io_out_2_bits_vpu_fpu_isFoldTo1_4,
  output logic io_out_2_bits_vpu_fpu_isFoldTo1_8,
  output logic [1:0] io_out_2_bits_vpu_vxrm,
  output logic [6:0] io_out_2_bits_vpu_vuopIdx,
  output logic io_out_2_bits_vpu_lastUop,
  output logic [127:0] io_out_2_bits_vpu_vmask,
  output logic [7:0] io_out_2_bits_vpu_vl,
  output logic [2:0] io_out_2_bits_vpu_nf,
  output logic [1:0] io_out_2_bits_vpu_veew,
  output logic io_out_2_bits_vpu_isReverse,
  output logic io_out_2_bits_vpu_isExt,
  output logic io_out_2_bits_vpu_isNarrow,
  output logic io_out_2_bits_vpu_isDstMask,
  output logic io_out_2_bits_vpu_isOpMask,
  output logic io_out_2_bits_vpu_isMove,
  output logic io_out_2_bits_vpu_isDependOldVd,
  output logic io_out_2_bits_vpu_isWritePartVd,
  output logic io_out_2_bits_vpu_isVleff,
  output logic io_out_2_bits_vlsInstr,
  output logic io_out_2_bits_wfflags,
  output logic io_out_2_bits_isMove,
  output logic [6:0] io_out_2_bits_uopIdx,
  output logic io_out_2_bits_isVset,
  output logic io_out_2_bits_firstUop,
  output logic io_out_2_bits_lastUop,
  output logic [6:0] io_out_2_bits_numUops,
  output logic [6:0] io_out_2_bits_numWB,
  output logic [2:0] io_out_2_bits_commitType,
  output logic [7:0] io_out_2_bits_psrc_0,
  output logic [7:0] io_out_2_bits_psrc_1,
  output logic [7:0] io_out_2_bits_psrc_2,
  output logic [7:0] io_out_2_bits_psrc_3,
  output logic [7:0] io_out_2_bits_psrc_4,
  output logic [7:0] io_out_2_bits_pdest,
  output logic io_out_2_bits_robIdx_flag,
  output logic [7:0] io_out_2_bits_robIdx_value,
  output logic [2:0] io_out_2_bits_instrSize,
  output logic io_out_2_bits_dirtyFs,
  output logic io_out_2_bits_dirtyVs,
  output logic [3:0] io_out_2_bits_traceBlockInPipe_itype,
  output logic [3:0] io_out_2_bits_traceBlockInPipe_iretire,
  output logic io_out_2_bits_traceBlockInPipe_ilastsize,
  output logic io_out_2_bits_eliminatedMove,
  output logic [63:0] io_out_2_bits_debugInfo_renameTime,
  output logic [55:0] io_out_2_bits_debug_seqNum_seqNum,
  output logic [7:0] io_out_2_bits_debug_seqNum_uopIdx,
  output logic [34:0] io_out_2_bits_debug_fuType,
  output logic io_out_2_bits_debug_sim_trig,
  output logic [4:0] io_out_2_bits_numLsElem,
  input  logic io_out_3_ready,
  output logic io_out_3_valid,
  output logic [31:0] io_out_3_bits_instr,
  output logic [49:0] io_out_3_bits_pc,
  output logic [9:0] io_out_3_bits_foldpc,
  output logic io_out_3_bits_exceptionVec_0,
  output logic io_out_3_bits_exceptionVec_1,
  output logic io_out_3_bits_exceptionVec_2,
  output logic io_out_3_bits_exceptionVec_3,
  output logic io_out_3_bits_exceptionVec_4,
  output logic io_out_3_bits_exceptionVec_5,
  output logic io_out_3_bits_exceptionVec_6,
  output logic io_out_3_bits_exceptionVec_7,
  output logic io_out_3_bits_exceptionVec_8,
  output logic io_out_3_bits_exceptionVec_9,
  output logic io_out_3_bits_exceptionVec_10,
  output logic io_out_3_bits_exceptionVec_11,
  output logic io_out_3_bits_exceptionVec_12,
  output logic io_out_3_bits_exceptionVec_13,
  output logic io_out_3_bits_exceptionVec_14,
  output logic io_out_3_bits_exceptionVec_15,
  output logic io_out_3_bits_exceptionVec_16,
  output logic io_out_3_bits_exceptionVec_17,
  output logic io_out_3_bits_exceptionVec_18,
  output logic io_out_3_bits_exceptionVec_19,
  output logic io_out_3_bits_exceptionVec_20,
  output logic io_out_3_bits_exceptionVec_21,
  output logic io_out_3_bits_exceptionVec_22,
  output logic io_out_3_bits_exceptionVec_23,
  output logic io_out_3_bits_isFetchMalAddr,
  output logic io_out_3_bits_hasException,
  output logic [3:0] io_out_3_bits_trigger,
  output logic io_out_3_bits_preDecodeInfo_valid,
  output logic io_out_3_bits_preDecodeInfo_isRVC,
  output logic [1:0] io_out_3_bits_preDecodeInfo_brType,
  output logic io_out_3_bits_preDecodeInfo_isCall,
  output logic io_out_3_bits_preDecodeInfo_isRet,
  output logic io_out_3_bits_pred_taken,
  output logic io_out_3_bits_crossPageIPFFix,
  output logic io_out_3_bits_ftqPtr_flag,
  output logic [5:0] io_out_3_bits_ftqPtr_value,
  output logic [3:0] io_out_3_bits_ftqOffset,
  output logic io_out_3_bits_satpFlushFirstFetchFault,
  output logic [3:0] io_out_3_bits_srcType_0,
  output logic [3:0] io_out_3_bits_srcType_1,
  output logic [3:0] io_out_3_bits_srcType_2,
  output logic [3:0] io_out_3_bits_srcType_3,
  output logic [3:0] io_out_3_bits_srcType_4,
  output logic [5:0] io_out_3_bits_ldest,
  output logic [34:0] io_out_3_bits_fuType,
  output logic [8:0] io_out_3_bits_fuOpType,
  output logic io_out_3_bits_rfWen,
  output logic io_out_3_bits_fpWen,
  output logic io_out_3_bits_vecWen,
  output logic io_out_3_bits_v0Wen,
  output logic io_out_3_bits_vlWen,
  output logic io_out_3_bits_isXSTrap,
  output logic io_out_3_bits_waitForward,
  output logic io_out_3_bits_blockBackward,
  output logic io_out_3_bits_flushPipe,
  output logic io_out_3_bits_canRobCompress,
  output logic [3:0] io_out_3_bits_selImm,
  output logic [31:0] io_out_3_bits_imm,
  output logic [1:0] io_out_3_bits_fpu_typeTagOut,
  output logic io_out_3_bits_fpu_wflags,
  output logic [1:0] io_out_3_bits_fpu_typ,
  output logic [1:0] io_out_3_bits_fpu_fmt,
  output logic [2:0] io_out_3_bits_fpu_rm,
  output logic io_out_3_bits_vpu_vill,
  output logic io_out_3_bits_vpu_vma,
  output logic io_out_3_bits_vpu_vta,
  output logic [1:0] io_out_3_bits_vpu_vsew,
  output logic [2:0] io_out_3_bits_vpu_vlmul,
  output logic io_out_3_bits_vpu_specVill,
  output logic io_out_3_bits_vpu_specVma,
  output logic io_out_3_bits_vpu_specVta,
  output logic [1:0] io_out_3_bits_vpu_specVsew,
  output logic [2:0] io_out_3_bits_vpu_specVlmul,
  output logic io_out_3_bits_vpu_vm,
  output logic [7:0] io_out_3_bits_vpu_vstart,
  output logic [2:0] io_out_3_bits_vpu_frm,
  output logic io_out_3_bits_vpu_fpu_isFpToVecInst,
  output logic io_out_3_bits_vpu_fpu_isFP32Instr,
  output logic io_out_3_bits_vpu_fpu_isFP64Instr,
  output logic io_out_3_bits_vpu_fpu_isReduction,
  output logic io_out_3_bits_vpu_fpu_isFoldTo1_2,
  output logic io_out_3_bits_vpu_fpu_isFoldTo1_4,
  output logic io_out_3_bits_vpu_fpu_isFoldTo1_8,
  output logic [1:0] io_out_3_bits_vpu_vxrm,
  output logic [6:0] io_out_3_bits_vpu_vuopIdx,
  output logic io_out_3_bits_vpu_lastUop,
  output logic [127:0] io_out_3_bits_vpu_vmask,
  output logic [7:0] io_out_3_bits_vpu_vl,
  output logic [2:0] io_out_3_bits_vpu_nf,
  output logic [1:0] io_out_3_bits_vpu_veew,
  output logic io_out_3_bits_vpu_isReverse,
  output logic io_out_3_bits_vpu_isExt,
  output logic io_out_3_bits_vpu_isNarrow,
  output logic io_out_3_bits_vpu_isDstMask,
  output logic io_out_3_bits_vpu_isOpMask,
  output logic io_out_3_bits_vpu_isMove,
  output logic io_out_3_bits_vpu_isDependOldVd,
  output logic io_out_3_bits_vpu_isWritePartVd,
  output logic io_out_3_bits_vpu_isVleff,
  output logic io_out_3_bits_vlsInstr,
  output logic io_out_3_bits_wfflags,
  output logic io_out_3_bits_isMove,
  output logic [6:0] io_out_3_bits_uopIdx,
  output logic io_out_3_bits_isVset,
  output logic io_out_3_bits_firstUop,
  output logic io_out_3_bits_lastUop,
  output logic [6:0] io_out_3_bits_numUops,
  output logic [6:0] io_out_3_bits_numWB,
  output logic [2:0] io_out_3_bits_commitType,
  output logic [7:0] io_out_3_bits_psrc_0,
  output logic [7:0] io_out_3_bits_psrc_1,
  output logic [7:0] io_out_3_bits_psrc_2,
  output logic [7:0] io_out_3_bits_psrc_3,
  output logic [7:0] io_out_3_bits_psrc_4,
  output logic [7:0] io_out_3_bits_pdest,
  output logic io_out_3_bits_robIdx_flag,
  output logic [7:0] io_out_3_bits_robIdx_value,
  output logic [2:0] io_out_3_bits_instrSize,
  output logic io_out_3_bits_dirtyFs,
  output logic io_out_3_bits_dirtyVs,
  output logic [3:0] io_out_3_bits_traceBlockInPipe_itype,
  output logic [3:0] io_out_3_bits_traceBlockInPipe_iretire,
  output logic io_out_3_bits_traceBlockInPipe_ilastsize,
  output logic io_out_3_bits_eliminatedMove,
  output logic [63:0] io_out_3_bits_debugInfo_renameTime,
  output logic [55:0] io_out_3_bits_debug_seqNum_seqNum,
  output logic [7:0] io_out_3_bits_debug_seqNum_uopIdx,
  output logic [34:0] io_out_3_bits_debug_fuType,
  output logic io_out_3_bits_debug_sim_trig,
  output logic [4:0] io_out_3_bits_numLsElem,
  input  logic io_out_4_ready,
  output logic io_out_4_valid,
  output logic [31:0] io_out_4_bits_instr,
  output logic [49:0] io_out_4_bits_pc,
  output logic [9:0] io_out_4_bits_foldpc,
  output logic io_out_4_bits_exceptionVec_0,
  output logic io_out_4_bits_exceptionVec_1,
  output logic io_out_4_bits_exceptionVec_2,
  output logic io_out_4_bits_exceptionVec_3,
  output logic io_out_4_bits_exceptionVec_4,
  output logic io_out_4_bits_exceptionVec_5,
  output logic io_out_4_bits_exceptionVec_6,
  output logic io_out_4_bits_exceptionVec_7,
  output logic io_out_4_bits_exceptionVec_8,
  output logic io_out_4_bits_exceptionVec_9,
  output logic io_out_4_bits_exceptionVec_10,
  output logic io_out_4_bits_exceptionVec_11,
  output logic io_out_4_bits_exceptionVec_12,
  output logic io_out_4_bits_exceptionVec_13,
  output logic io_out_4_bits_exceptionVec_14,
  output logic io_out_4_bits_exceptionVec_15,
  output logic io_out_4_bits_exceptionVec_16,
  output logic io_out_4_bits_exceptionVec_17,
  output logic io_out_4_bits_exceptionVec_18,
  output logic io_out_4_bits_exceptionVec_19,
  output logic io_out_4_bits_exceptionVec_20,
  output logic io_out_4_bits_exceptionVec_21,
  output logic io_out_4_bits_exceptionVec_22,
  output logic io_out_4_bits_exceptionVec_23,
  output logic io_out_4_bits_isFetchMalAddr,
  output logic io_out_4_bits_hasException,
  output logic [3:0] io_out_4_bits_trigger,
  output logic io_out_4_bits_preDecodeInfo_valid,
  output logic io_out_4_bits_preDecodeInfo_isRVC,
  output logic [1:0] io_out_4_bits_preDecodeInfo_brType,
  output logic io_out_4_bits_preDecodeInfo_isCall,
  output logic io_out_4_bits_preDecodeInfo_isRet,
  output logic io_out_4_bits_pred_taken,
  output logic io_out_4_bits_crossPageIPFFix,
  output logic io_out_4_bits_ftqPtr_flag,
  output logic [5:0] io_out_4_bits_ftqPtr_value,
  output logic [3:0] io_out_4_bits_ftqOffset,
  output logic io_out_4_bits_satpFlushFirstFetchFault,
  output logic [3:0] io_out_4_bits_srcType_0,
  output logic [3:0] io_out_4_bits_srcType_1,
  output logic [3:0] io_out_4_bits_srcType_2,
  output logic [3:0] io_out_4_bits_srcType_3,
  output logic [3:0] io_out_4_bits_srcType_4,
  output logic [5:0] io_out_4_bits_ldest,
  output logic [34:0] io_out_4_bits_fuType,
  output logic [8:0] io_out_4_bits_fuOpType,
  output logic io_out_4_bits_rfWen,
  output logic io_out_4_bits_fpWen,
  output logic io_out_4_bits_vecWen,
  output logic io_out_4_bits_v0Wen,
  output logic io_out_4_bits_vlWen,
  output logic io_out_4_bits_isXSTrap,
  output logic io_out_4_bits_waitForward,
  output logic io_out_4_bits_blockBackward,
  output logic io_out_4_bits_flushPipe,
  output logic io_out_4_bits_canRobCompress,
  output logic [3:0] io_out_4_bits_selImm,
  output logic [31:0] io_out_4_bits_imm,
  output logic [1:0] io_out_4_bits_fpu_typeTagOut,
  output logic io_out_4_bits_fpu_wflags,
  output logic [1:0] io_out_4_bits_fpu_typ,
  output logic [1:0] io_out_4_bits_fpu_fmt,
  output logic [2:0] io_out_4_bits_fpu_rm,
  output logic io_out_4_bits_vpu_vill,
  output logic io_out_4_bits_vpu_vma,
  output logic io_out_4_bits_vpu_vta,
  output logic [1:0] io_out_4_bits_vpu_vsew,
  output logic [2:0] io_out_4_bits_vpu_vlmul,
  output logic io_out_4_bits_vpu_specVill,
  output logic io_out_4_bits_vpu_specVma,
  output logic io_out_4_bits_vpu_specVta,
  output logic [1:0] io_out_4_bits_vpu_specVsew,
  output logic [2:0] io_out_4_bits_vpu_specVlmul,
  output logic io_out_4_bits_vpu_vm,
  output logic [7:0] io_out_4_bits_vpu_vstart,
  output logic [2:0] io_out_4_bits_vpu_frm,
  output logic io_out_4_bits_vpu_fpu_isFpToVecInst,
  output logic io_out_4_bits_vpu_fpu_isFP32Instr,
  output logic io_out_4_bits_vpu_fpu_isFP64Instr,
  output logic io_out_4_bits_vpu_fpu_isReduction,
  output logic io_out_4_bits_vpu_fpu_isFoldTo1_2,
  output logic io_out_4_bits_vpu_fpu_isFoldTo1_4,
  output logic io_out_4_bits_vpu_fpu_isFoldTo1_8,
  output logic [1:0] io_out_4_bits_vpu_vxrm,
  output logic [6:0] io_out_4_bits_vpu_vuopIdx,
  output logic io_out_4_bits_vpu_lastUop,
  output logic [127:0] io_out_4_bits_vpu_vmask,
  output logic [7:0] io_out_4_bits_vpu_vl,
  output logic [2:0] io_out_4_bits_vpu_nf,
  output logic [1:0] io_out_4_bits_vpu_veew,
  output logic io_out_4_bits_vpu_isReverse,
  output logic io_out_4_bits_vpu_isExt,
  output logic io_out_4_bits_vpu_isNarrow,
  output logic io_out_4_bits_vpu_isDstMask,
  output logic io_out_4_bits_vpu_isOpMask,
  output logic io_out_4_bits_vpu_isMove,
  output logic io_out_4_bits_vpu_isDependOldVd,
  output logic io_out_4_bits_vpu_isWritePartVd,
  output logic io_out_4_bits_vpu_isVleff,
  output logic io_out_4_bits_vlsInstr,
  output logic io_out_4_bits_wfflags,
  output logic io_out_4_bits_isMove,
  output logic [6:0] io_out_4_bits_uopIdx,
  output logic io_out_4_bits_isVset,
  output logic io_out_4_bits_firstUop,
  output logic io_out_4_bits_lastUop,
  output logic [6:0] io_out_4_bits_numUops,
  output logic [6:0] io_out_4_bits_numWB,
  output logic [2:0] io_out_4_bits_commitType,
  output logic [7:0] io_out_4_bits_psrc_0,
  output logic [7:0] io_out_4_bits_psrc_1,
  output logic [7:0] io_out_4_bits_psrc_2,
  output logic [7:0] io_out_4_bits_psrc_3,
  output logic [7:0] io_out_4_bits_psrc_4,
  output logic [7:0] io_out_4_bits_pdest,
  output logic io_out_4_bits_robIdx_flag,
  output logic [7:0] io_out_4_bits_robIdx_value,
  output logic [2:0] io_out_4_bits_instrSize,
  output logic io_out_4_bits_dirtyFs,
  output logic io_out_4_bits_dirtyVs,
  output logic [3:0] io_out_4_bits_traceBlockInPipe_itype,
  output logic [3:0] io_out_4_bits_traceBlockInPipe_iretire,
  output logic io_out_4_bits_traceBlockInPipe_ilastsize,
  output logic io_out_4_bits_eliminatedMove,
  output logic [63:0] io_out_4_bits_debugInfo_renameTime,
  output logic [55:0] io_out_4_bits_debug_seqNum_seqNum,
  output logic [7:0] io_out_4_bits_debug_seqNum_uopIdx,
  output logic [34:0] io_out_4_bits_debug_fuType,
  output logic io_out_4_bits_debug_sim_trig,
  output logic [4:0] io_out_4_bits_numLsElem,
  input  logic io_out_5_ready,
  output logic io_out_5_valid,
  output logic [31:0] io_out_5_bits_instr,
  output logic [49:0] io_out_5_bits_pc,
  output logic [9:0] io_out_5_bits_foldpc,
  output logic io_out_5_bits_exceptionVec_0,
  output logic io_out_5_bits_exceptionVec_1,
  output logic io_out_5_bits_exceptionVec_2,
  output logic io_out_5_bits_exceptionVec_3,
  output logic io_out_5_bits_exceptionVec_4,
  output logic io_out_5_bits_exceptionVec_5,
  output logic io_out_5_bits_exceptionVec_6,
  output logic io_out_5_bits_exceptionVec_7,
  output logic io_out_5_bits_exceptionVec_8,
  output logic io_out_5_bits_exceptionVec_9,
  output logic io_out_5_bits_exceptionVec_10,
  output logic io_out_5_bits_exceptionVec_11,
  output logic io_out_5_bits_exceptionVec_12,
  output logic io_out_5_bits_exceptionVec_13,
  output logic io_out_5_bits_exceptionVec_14,
  output logic io_out_5_bits_exceptionVec_15,
  output logic io_out_5_bits_exceptionVec_16,
  output logic io_out_5_bits_exceptionVec_17,
  output logic io_out_5_bits_exceptionVec_18,
  output logic io_out_5_bits_exceptionVec_19,
  output logic io_out_5_bits_exceptionVec_20,
  output logic io_out_5_bits_exceptionVec_21,
  output logic io_out_5_bits_exceptionVec_22,
  output logic io_out_5_bits_exceptionVec_23,
  output logic io_out_5_bits_isFetchMalAddr,
  output logic io_out_5_bits_hasException,
  output logic [3:0] io_out_5_bits_trigger,
  output logic io_out_5_bits_preDecodeInfo_valid,
  output logic io_out_5_bits_preDecodeInfo_isRVC,
  output logic [1:0] io_out_5_bits_preDecodeInfo_brType,
  output logic io_out_5_bits_preDecodeInfo_isCall,
  output logic io_out_5_bits_preDecodeInfo_isRet,
  output logic io_out_5_bits_pred_taken,
  output logic io_out_5_bits_crossPageIPFFix,
  output logic io_out_5_bits_ftqPtr_flag,
  output logic [5:0] io_out_5_bits_ftqPtr_value,
  output logic [3:0] io_out_5_bits_ftqOffset,
  output logic io_out_5_bits_satpFlushFirstFetchFault,
  output logic [3:0] io_out_5_bits_srcType_0,
  output logic [3:0] io_out_5_bits_srcType_1,
  output logic [3:0] io_out_5_bits_srcType_2,
  output logic [3:0] io_out_5_bits_srcType_3,
  output logic [3:0] io_out_5_bits_srcType_4,
  output logic [5:0] io_out_5_bits_ldest,
  output logic [34:0] io_out_5_bits_fuType,
  output logic [8:0] io_out_5_bits_fuOpType,
  output logic io_out_5_bits_rfWen,
  output logic io_out_5_bits_fpWen,
  output logic io_out_5_bits_vecWen,
  output logic io_out_5_bits_v0Wen,
  output logic io_out_5_bits_vlWen,
  output logic io_out_5_bits_isXSTrap,
  output logic io_out_5_bits_waitForward,
  output logic io_out_5_bits_blockBackward,
  output logic io_out_5_bits_flushPipe,
  output logic io_out_5_bits_canRobCompress,
  output logic [3:0] io_out_5_bits_selImm,
  output logic [31:0] io_out_5_bits_imm,
  output logic [1:0] io_out_5_bits_fpu_typeTagOut,
  output logic io_out_5_bits_fpu_wflags,
  output logic [1:0] io_out_5_bits_fpu_typ,
  output logic [1:0] io_out_5_bits_fpu_fmt,
  output logic [2:0] io_out_5_bits_fpu_rm,
  output logic io_out_5_bits_vpu_vill,
  output logic io_out_5_bits_vpu_vma,
  output logic io_out_5_bits_vpu_vta,
  output logic [1:0] io_out_5_bits_vpu_vsew,
  output logic [2:0] io_out_5_bits_vpu_vlmul,
  output logic io_out_5_bits_vpu_specVill,
  output logic io_out_5_bits_vpu_specVma,
  output logic io_out_5_bits_vpu_specVta,
  output logic [1:0] io_out_5_bits_vpu_specVsew,
  output logic [2:0] io_out_5_bits_vpu_specVlmul,
  output logic io_out_5_bits_vpu_vm,
  output logic [7:0] io_out_5_bits_vpu_vstart,
  output logic [2:0] io_out_5_bits_vpu_frm,
  output logic io_out_5_bits_vpu_fpu_isFpToVecInst,
  output logic io_out_5_bits_vpu_fpu_isFP32Instr,
  output logic io_out_5_bits_vpu_fpu_isFP64Instr,
  output logic io_out_5_bits_vpu_fpu_isReduction,
  output logic io_out_5_bits_vpu_fpu_isFoldTo1_2,
  output logic io_out_5_bits_vpu_fpu_isFoldTo1_4,
  output logic io_out_5_bits_vpu_fpu_isFoldTo1_8,
  output logic [1:0] io_out_5_bits_vpu_vxrm,
  output logic [6:0] io_out_5_bits_vpu_vuopIdx,
  output logic io_out_5_bits_vpu_lastUop,
  output logic [127:0] io_out_5_bits_vpu_vmask,
  output logic [7:0] io_out_5_bits_vpu_vl,
  output logic [2:0] io_out_5_bits_vpu_nf,
  output logic [1:0] io_out_5_bits_vpu_veew,
  output logic io_out_5_bits_vpu_isReverse,
  output logic io_out_5_bits_vpu_isExt,
  output logic io_out_5_bits_vpu_isNarrow,
  output logic io_out_5_bits_vpu_isDstMask,
  output logic io_out_5_bits_vpu_isOpMask,
  output logic io_out_5_bits_vpu_isMove,
  output logic io_out_5_bits_vpu_isDependOldVd,
  output logic io_out_5_bits_vpu_isWritePartVd,
  output logic io_out_5_bits_vpu_isVleff,
  output logic io_out_5_bits_vlsInstr,
  output logic io_out_5_bits_wfflags,
  output logic io_out_5_bits_isMove,
  output logic [6:0] io_out_5_bits_uopIdx,
  output logic io_out_5_bits_isVset,
  output logic io_out_5_bits_firstUop,
  output logic io_out_5_bits_lastUop,
  output logic [6:0] io_out_5_bits_numUops,
  output logic [6:0] io_out_5_bits_numWB,
  output logic [2:0] io_out_5_bits_commitType,
  output logic [7:0] io_out_5_bits_psrc_0,
  output logic [7:0] io_out_5_bits_psrc_1,
  output logic [7:0] io_out_5_bits_psrc_2,
  output logic [7:0] io_out_5_bits_psrc_3,
  output logic [7:0] io_out_5_bits_psrc_4,
  output logic [7:0] io_out_5_bits_pdest,
  output logic io_out_5_bits_robIdx_flag,
  output logic [7:0] io_out_5_bits_robIdx_value,
  output logic [2:0] io_out_5_bits_instrSize,
  output logic io_out_5_bits_dirtyFs,
  output logic io_out_5_bits_dirtyVs,
  output logic [3:0] io_out_5_bits_traceBlockInPipe_itype,
  output logic [3:0] io_out_5_bits_traceBlockInPipe_iretire,
  output logic io_out_5_bits_traceBlockInPipe_ilastsize,
  output logic io_out_5_bits_eliminatedMove,
  output logic [63:0] io_out_5_bits_debugInfo_renameTime,
  output logic [55:0] io_out_5_bits_debug_seqNum_seqNum,
  output logic [7:0] io_out_5_bits_debug_seqNum_uopIdx,
  output logic [34:0] io_out_5_bits_debug_fuType,
  output logic io_out_5_bits_debug_sim_trig,
  output logic [4:0] io_out_5_bits_numLsElem,
  input  logic io_flush,
  input  logic io_outAllFire
);

  payload_snap_t in_payload_0, out_payload_0;
  payload_t      in_payload_1, out_payload_1;
  payload_t      in_payload_2, out_payload_2;
  payload_t      in_payload_3, out_payload_3;
  payload_t      in_payload_4, out_payload_4;
  payload_t      in_payload_5, out_payload_5;

  logic [N_LANES-1:0] in_valid, out_ready, out_valid, lane_fire;
  logic               in_ready;

  assign in_valid  = {io_in_5_valid, io_in_4_valid, io_in_3_valid, io_in_2_valid, io_in_1_valid, io_in_0_valid};
  assign out_ready = {io_out_5_ready, io_out_4_ready, io_out_3_ready, io_out_2_ready, io_out_1_ready, io_out_0_ready};
  assign io_in_0_ready  = in_ready;
  assign io_in_1_ready  = in_ready;
  assign io_in_2_ready  = in_ready;
  assign io_in_3_ready  = in_ready;
  assign io_in_4_ready  = in_ready;
  assign io_in_5_ready  = in_ready;
  assign io_out_0_valid = out_valid[0];
  assign io_out_1_valid = out_valid[1];
  assign io_out_2_valid = out_valid[2];
  assign io_out_3_valid = out_valid[3];
  assign io_out_4_valid = out_valid[4];
  assign io_out_5_valid = out_valid[5];

  xs_PipeGroupConnect_core #(.N(N_LANES)) u_core (
    .clock         (clock),
    .reset         (reset),
    .io_in_valid   (in_valid),
    .io_in_ready   (in_ready),
    .io_out_ready  (out_ready),
    .io_out_valid  (out_valid),
    .io_flush      (io_flush),
    .io_outAllFire (io_outAllFire),
    .lane_fire     (lane_fire)
  );

  xs_PipeGroupConnect_slot #(.W($bits(payload_snap_t)), .W_G1(LANE0_W_G1)) u_slot_0 (
    .clock       (clock),
    .fire        (lane_fire[0]),
    .io_in_bits  (in_payload_0),
    .io_out_bits (out_payload_0)
  );
  xs_PipeGroupConnect_slot #(.W($bits(payload_t)), .W_G1(LANE_W_G1)) u_slot_1 (
    .clock       (clock),
    .fire        (lane_fire[1]),
    .io_in_bits  (in_payload_1),
    .io_out_bits (out_payload_1)
  );
  xs_PipeGroupConnect_slot #(.W($bits(payload_t)), .W_G1(LANE_W_G1)) u_slot_2 (
    .clock       (clock),
    .fire        (lane_fire[2]),
    .io_in_bits  (in_payload_2),
    .io_out_bits (out_payload_2)
  );
  xs_PipeGroupConnect_slot #(.W($bits(payload_t)), .W_G1(LANE_W_G1)) u_slot_3 (
    .clock       (clock),
    .fire        (lane_fire[3]),
    .io_in_bits  (in_payload_3),
    .io_out_bits (out_payload_3)
  );
  xs_PipeGroupConnect_slot #(.W($bits(payload_t)), .W_G1(LANE_W_G1)) u_slot_4 (
    .clock       (clock),
    .fire        (lane_fire[4]),
    .io_in_bits  (in_payload_4),
    .io_out_bits (out_payload_4)
  );
  xs_PipeGroupConnect_slot #(.W($bits(payload_t)), .W_G1(LANE_W_G1)) u_slot_5 (
    .clock       (clock),
    .fire        (lane_fire[5]),
    .io_in_bits  (in_payload_5),
    .io_out_bits (out_payload_5)
  );

  // ---------------------------------------------------------------------------
  // lane 0：入口打包 / 出口拆包（同名逐项）
  // ---------------------------------------------------------------------------
  always_comb begin
    in_payload_0.instr                      = io_in_0_bits_instr;
    in_payload_0.pc                         = io_in_0_bits_pc;
    in_payload_0.foldpc                     = io_in_0_bits_foldpc;
    in_payload_0.exceptionVec_0             = io_in_0_bits_exceptionVec_0;
    in_payload_0.exceptionVec_1             = io_in_0_bits_exceptionVec_1;
    in_payload_0.exceptionVec_2             = io_in_0_bits_exceptionVec_2;
    in_payload_0.exceptionVec_3             = io_in_0_bits_exceptionVec_3;
    in_payload_0.exceptionVec_4             = io_in_0_bits_exceptionVec_4;
    in_payload_0.exceptionVec_5             = io_in_0_bits_exceptionVec_5;
    in_payload_0.exceptionVec_6             = io_in_0_bits_exceptionVec_6;
    in_payload_0.exceptionVec_7             = io_in_0_bits_exceptionVec_7;
    in_payload_0.exceptionVec_8             = io_in_0_bits_exceptionVec_8;
    in_payload_0.exceptionVec_9             = io_in_0_bits_exceptionVec_9;
    in_payload_0.exceptionVec_10            = io_in_0_bits_exceptionVec_10;
    in_payload_0.exceptionVec_11            = io_in_0_bits_exceptionVec_11;
    in_payload_0.exceptionVec_12            = io_in_0_bits_exceptionVec_12;
    in_payload_0.exceptionVec_13            = io_in_0_bits_exceptionVec_13;
    in_payload_0.exceptionVec_14            = io_in_0_bits_exceptionVec_14;
    in_payload_0.exceptionVec_15            = io_in_0_bits_exceptionVec_15;
    in_payload_0.exceptionVec_16            = io_in_0_bits_exceptionVec_16;
    in_payload_0.exceptionVec_17            = io_in_0_bits_exceptionVec_17;
    in_payload_0.exceptionVec_18            = io_in_0_bits_exceptionVec_18;
    in_payload_0.exceptionVec_19            = io_in_0_bits_exceptionVec_19;
    in_payload_0.exceptionVec_20            = io_in_0_bits_exceptionVec_20;
    in_payload_0.exceptionVec_21            = io_in_0_bits_exceptionVec_21;
    in_payload_0.exceptionVec_22            = io_in_0_bits_exceptionVec_22;
    in_payload_0.exceptionVec_23            = io_in_0_bits_exceptionVec_23;
    in_payload_0.isFetchMalAddr             = io_in_0_bits_isFetchMalAddr;
    in_payload_0.hasException               = io_in_0_bits_hasException;
    in_payload_0.trigger                    = io_in_0_bits_trigger;
    in_payload_0.preDecodeInfo_valid        = io_in_0_bits_preDecodeInfo_valid;
    in_payload_0.preDecodeInfo_isRVC        = io_in_0_bits_preDecodeInfo_isRVC;
    in_payload_0.preDecodeInfo_brType       = io_in_0_bits_preDecodeInfo_brType;
    in_payload_0.preDecodeInfo_isCall       = io_in_0_bits_preDecodeInfo_isCall;
    in_payload_0.preDecodeInfo_isRet        = io_in_0_bits_preDecodeInfo_isRet;
    in_payload_0.pred_taken                 = io_in_0_bits_pred_taken;
    in_payload_0.crossPageIPFFix            = io_in_0_bits_crossPageIPFFix;
    in_payload_0.ftqPtr_flag                = io_in_0_bits_ftqPtr_flag;
    in_payload_0.ftqPtr_value               = io_in_0_bits_ftqPtr_value;
    in_payload_0.ftqOffset                  = io_in_0_bits_ftqOffset;
    in_payload_0.satpFlushFirstFetchFault   = io_in_0_bits_satpFlushFirstFetchFault;
    in_payload_0.srcType_0                  = io_in_0_bits_srcType_0;
    in_payload_0.srcType_1                  = io_in_0_bits_srcType_1;
    in_payload_0.srcType_2                  = io_in_0_bits_srcType_2;
    in_payload_0.srcType_3                  = io_in_0_bits_srcType_3;
    in_payload_0.srcType_4                  = io_in_0_bits_srcType_4;
    in_payload_0.ldest                      = io_in_0_bits_ldest;
    in_payload_0.fuType                     = io_in_0_bits_fuType;
    in_payload_0.fuOpType                   = io_in_0_bits_fuOpType;
    in_payload_0.rfWen                      = io_in_0_bits_rfWen;
    in_payload_0.fpWen                      = io_in_0_bits_fpWen;
    in_payload_0.vecWen                     = io_in_0_bits_vecWen;
    in_payload_0.v0Wen                      = io_in_0_bits_v0Wen;
    in_payload_0.vlWen                      = io_in_0_bits_vlWen;
    in_payload_0.isXSTrap                   = io_in_0_bits_isXSTrap;
    in_payload_0.waitForward                = io_in_0_bits_waitForward;
    in_payload_0.blockBackward              = io_in_0_bits_blockBackward;
    in_payload_0.flushPipe                  = io_in_0_bits_flushPipe;
    in_payload_0.canRobCompress             = io_in_0_bits_canRobCompress;
    in_payload_0.selImm                     = io_in_0_bits_selImm;
    in_payload_0.imm                        = io_in_0_bits_imm;
    in_payload_0.fpu_typeTagOut             = io_in_0_bits_fpu_typeTagOut;
    in_payload_0.fpu_wflags                 = io_in_0_bits_fpu_wflags;
    in_payload_0.fpu_typ                    = io_in_0_bits_fpu_typ;
    in_payload_0.fpu_fmt                    = io_in_0_bits_fpu_fmt;
    in_payload_0.fpu_rm                     = io_in_0_bits_fpu_rm;
    in_payload_0.vpu_vill                   = io_in_0_bits_vpu_vill;
    in_payload_0.vpu_vma                    = io_in_0_bits_vpu_vma;
    in_payload_0.vpu_vta                    = io_in_0_bits_vpu_vta;
    in_payload_0.vpu_vsew                   = io_in_0_bits_vpu_vsew;
    in_payload_0.vpu_vlmul                  = io_in_0_bits_vpu_vlmul;
    in_payload_0.vpu_specVill               = io_in_0_bits_vpu_specVill;
    in_payload_0.vpu_specVma                = io_in_0_bits_vpu_specVma;
    in_payload_0.vpu_specVta                = io_in_0_bits_vpu_specVta;
    in_payload_0.vpu_specVsew               = io_in_0_bits_vpu_specVsew;
    in_payload_0.vpu_specVlmul              = io_in_0_bits_vpu_specVlmul;
    in_payload_0.vpu_vm                     = io_in_0_bits_vpu_vm;
    in_payload_0.vpu_vstart                 = io_in_0_bits_vpu_vstart;
    in_payload_0.vpu_frm                    = io_in_0_bits_vpu_frm;
    in_payload_0.vpu_fpu_isFpToVecInst      = io_in_0_bits_vpu_fpu_isFpToVecInst;
    in_payload_0.vpu_fpu_isFP32Instr        = io_in_0_bits_vpu_fpu_isFP32Instr;
    in_payload_0.vpu_fpu_isFP64Instr        = io_in_0_bits_vpu_fpu_isFP64Instr;
    in_payload_0.vpu_fpu_isReduction        = io_in_0_bits_vpu_fpu_isReduction;
    in_payload_0.vpu_fpu_isFoldTo1_2        = io_in_0_bits_vpu_fpu_isFoldTo1_2;
    in_payload_0.vpu_fpu_isFoldTo1_4        = io_in_0_bits_vpu_fpu_isFoldTo1_4;
    in_payload_0.vpu_fpu_isFoldTo1_8        = io_in_0_bits_vpu_fpu_isFoldTo1_8;
    in_payload_0.vpu_vxrm                   = io_in_0_bits_vpu_vxrm;
    in_payload_0.vpu_vuopIdx                = io_in_0_bits_vpu_vuopIdx;
    in_payload_0.vpu_lastUop                = io_in_0_bits_vpu_lastUop;
    in_payload_0.vpu_vmask                  = io_in_0_bits_vpu_vmask;
    in_payload_0.vpu_vl                     = io_in_0_bits_vpu_vl;
    in_payload_0.vpu_nf                     = io_in_0_bits_vpu_nf;
    in_payload_0.vpu_veew                   = io_in_0_bits_vpu_veew;
    in_payload_0.vpu_isReverse              = io_in_0_bits_vpu_isReverse;
    in_payload_0.vpu_isExt                  = io_in_0_bits_vpu_isExt;
    in_payload_0.vpu_isNarrow               = io_in_0_bits_vpu_isNarrow;
    in_payload_0.vpu_isDstMask              = io_in_0_bits_vpu_isDstMask;
    in_payload_0.vpu_isOpMask               = io_in_0_bits_vpu_isOpMask;
    in_payload_0.vpu_isMove                 = io_in_0_bits_vpu_isMove;
    in_payload_0.vpu_isDependOldVd          = io_in_0_bits_vpu_isDependOldVd;
    in_payload_0.vpu_isWritePartVd          = io_in_0_bits_vpu_isWritePartVd;
    in_payload_0.vpu_isVleff                = io_in_0_bits_vpu_isVleff;
    in_payload_0.vlsInstr                   = io_in_0_bits_vlsInstr;
    in_payload_0.wfflags                    = io_in_0_bits_wfflags;
    in_payload_0.isMove                     = io_in_0_bits_isMove;
    in_payload_0.uopIdx                     = io_in_0_bits_uopIdx;
    in_payload_0.isVset                     = io_in_0_bits_isVset;
    in_payload_0.firstUop                   = io_in_0_bits_firstUop;
    in_payload_0.lastUop                    = io_in_0_bits_lastUop;
    in_payload_0.numUops                    = io_in_0_bits_numUops;
    in_payload_0.numWB                      = io_in_0_bits_numWB;
    in_payload_0.commitType                 = io_in_0_bits_commitType;
    in_payload_0.psrc_0                     = io_in_0_bits_psrc_0;
    in_payload_0.psrc_1                     = io_in_0_bits_psrc_1;
    in_payload_0.psrc_2                     = io_in_0_bits_psrc_2;
    in_payload_0.psrc_3                     = io_in_0_bits_psrc_3;
    in_payload_0.psrc_4                     = io_in_0_bits_psrc_4;
    in_payload_0.pdest                      = io_in_0_bits_pdest;
    in_payload_0.robIdx_flag                = io_in_0_bits_robIdx_flag;
    in_payload_0.robIdx_value               = io_in_0_bits_robIdx_value;
    in_payload_0.instrSize                  = io_in_0_bits_instrSize;
    in_payload_0.dirtyFs                    = io_in_0_bits_dirtyFs;
    in_payload_0.dirtyVs                    = io_in_0_bits_dirtyVs;
    in_payload_0.traceBlockInPipe_itype     = io_in_0_bits_traceBlockInPipe_itype;
    in_payload_0.traceBlockInPipe_iretire   = io_in_0_bits_traceBlockInPipe_iretire;
    in_payload_0.traceBlockInPipe_ilastsize = io_in_0_bits_traceBlockInPipe_ilastsize;
    in_payload_0.eliminatedMove             = io_in_0_bits_eliminatedMove;
    in_payload_0.snapshot                   = io_in_0_bits_snapshot;
    in_payload_0.debugInfo_renameTime       = io_in_0_bits_debugInfo_renameTime;
    in_payload_0.debug_seqNum_seqNum        = io_in_0_bits_debug_seqNum_seqNum;
    in_payload_0.debug_seqNum_uopIdx        = io_in_0_bits_debug_seqNum_uopIdx;
    in_payload_0.debug_fuType               = io_in_0_bits_debug_fuType;
    in_payload_0.debug_sim_trig             = io_in_0_bits_debug_sim_trig;
    in_payload_0.numLsElem                  = io_in_0_bits_numLsElem;
  end
  assign io_out_0_bits_instr                      = out_payload_0.instr;
  assign io_out_0_bits_pc                         = out_payload_0.pc;
  assign io_out_0_bits_foldpc                     = out_payload_0.foldpc;
  assign io_out_0_bits_exceptionVec_0             = out_payload_0.exceptionVec_0;
  assign io_out_0_bits_exceptionVec_1             = out_payload_0.exceptionVec_1;
  assign io_out_0_bits_exceptionVec_2             = out_payload_0.exceptionVec_2;
  assign io_out_0_bits_exceptionVec_3             = out_payload_0.exceptionVec_3;
  assign io_out_0_bits_exceptionVec_4             = out_payload_0.exceptionVec_4;
  assign io_out_0_bits_exceptionVec_5             = out_payload_0.exceptionVec_5;
  assign io_out_0_bits_exceptionVec_6             = out_payload_0.exceptionVec_6;
  assign io_out_0_bits_exceptionVec_7             = out_payload_0.exceptionVec_7;
  assign io_out_0_bits_exceptionVec_8             = out_payload_0.exceptionVec_8;
  assign io_out_0_bits_exceptionVec_9             = out_payload_0.exceptionVec_9;
  assign io_out_0_bits_exceptionVec_10            = out_payload_0.exceptionVec_10;
  assign io_out_0_bits_exceptionVec_11            = out_payload_0.exceptionVec_11;
  assign io_out_0_bits_exceptionVec_12            = out_payload_0.exceptionVec_12;
  assign io_out_0_bits_exceptionVec_13            = out_payload_0.exceptionVec_13;
  assign io_out_0_bits_exceptionVec_14            = out_payload_0.exceptionVec_14;
  assign io_out_0_bits_exceptionVec_15            = out_payload_0.exceptionVec_15;
  assign io_out_0_bits_exceptionVec_16            = out_payload_0.exceptionVec_16;
  assign io_out_0_bits_exceptionVec_17            = out_payload_0.exceptionVec_17;
  assign io_out_0_bits_exceptionVec_18            = out_payload_0.exceptionVec_18;
  assign io_out_0_bits_exceptionVec_19            = out_payload_0.exceptionVec_19;
  assign io_out_0_bits_exceptionVec_20            = out_payload_0.exceptionVec_20;
  assign io_out_0_bits_exceptionVec_21            = out_payload_0.exceptionVec_21;
  assign io_out_0_bits_exceptionVec_22            = out_payload_0.exceptionVec_22;
  assign io_out_0_bits_exceptionVec_23            = out_payload_0.exceptionVec_23;
  assign io_out_0_bits_isFetchMalAddr             = out_payload_0.isFetchMalAddr;
  assign io_out_0_bits_hasException               = out_payload_0.hasException;
  assign io_out_0_bits_trigger                    = out_payload_0.trigger;
  assign io_out_0_bits_preDecodeInfo_valid        = out_payload_0.preDecodeInfo_valid;
  assign io_out_0_bits_preDecodeInfo_isRVC        = out_payload_0.preDecodeInfo_isRVC;
  assign io_out_0_bits_preDecodeInfo_brType       = out_payload_0.preDecodeInfo_brType;
  assign io_out_0_bits_preDecodeInfo_isCall       = out_payload_0.preDecodeInfo_isCall;
  assign io_out_0_bits_preDecodeInfo_isRet        = out_payload_0.preDecodeInfo_isRet;
  assign io_out_0_bits_pred_taken                 = out_payload_0.pred_taken;
  assign io_out_0_bits_crossPageIPFFix            = out_payload_0.crossPageIPFFix;
  assign io_out_0_bits_ftqPtr_flag                = out_payload_0.ftqPtr_flag;
  assign io_out_0_bits_ftqPtr_value               = out_payload_0.ftqPtr_value;
  assign io_out_0_bits_ftqOffset                  = out_payload_0.ftqOffset;
  assign io_out_0_bits_satpFlushFirstFetchFault   = out_payload_0.satpFlushFirstFetchFault;
  assign io_out_0_bits_srcType_0                  = out_payload_0.srcType_0;
  assign io_out_0_bits_srcType_1                  = out_payload_0.srcType_1;
  assign io_out_0_bits_srcType_2                  = out_payload_0.srcType_2;
  assign io_out_0_bits_srcType_3                  = out_payload_0.srcType_3;
  assign io_out_0_bits_srcType_4                  = out_payload_0.srcType_4;
  assign io_out_0_bits_ldest                      = out_payload_0.ldest;
  assign io_out_0_bits_fuType                     = out_payload_0.fuType;
  assign io_out_0_bits_fuOpType                   = out_payload_0.fuOpType;
  assign io_out_0_bits_rfWen                      = out_payload_0.rfWen;
  assign io_out_0_bits_fpWen                      = out_payload_0.fpWen;
  assign io_out_0_bits_vecWen                     = out_payload_0.vecWen;
  assign io_out_0_bits_v0Wen                      = out_payload_0.v0Wen;
  assign io_out_0_bits_vlWen                      = out_payload_0.vlWen;
  assign io_out_0_bits_isXSTrap                   = out_payload_0.isXSTrap;
  assign io_out_0_bits_waitForward                = out_payload_0.waitForward;
  assign io_out_0_bits_blockBackward              = out_payload_0.blockBackward;
  assign io_out_0_bits_flushPipe                  = out_payload_0.flushPipe;
  assign io_out_0_bits_canRobCompress             = out_payload_0.canRobCompress;
  assign io_out_0_bits_selImm                     = out_payload_0.selImm;
  assign io_out_0_bits_imm                        = out_payload_0.imm;
  assign io_out_0_bits_fpu_typeTagOut             = out_payload_0.fpu_typeTagOut;
  assign io_out_0_bits_fpu_wflags                 = out_payload_0.fpu_wflags;
  assign io_out_0_bits_fpu_typ                    = out_payload_0.fpu_typ;
  assign io_out_0_bits_fpu_fmt                    = out_payload_0.fpu_fmt;
  assign io_out_0_bits_fpu_rm                     = out_payload_0.fpu_rm;
  assign io_out_0_bits_vpu_vill                   = out_payload_0.vpu_vill;
  assign io_out_0_bits_vpu_vma                    = out_payload_0.vpu_vma;
  assign io_out_0_bits_vpu_vta                    = out_payload_0.vpu_vta;
  assign io_out_0_bits_vpu_vsew                   = out_payload_0.vpu_vsew;
  assign io_out_0_bits_vpu_vlmul                  = out_payload_0.vpu_vlmul;
  assign io_out_0_bits_vpu_specVill               = out_payload_0.vpu_specVill;
  assign io_out_0_bits_vpu_specVma                = out_payload_0.vpu_specVma;
  assign io_out_0_bits_vpu_specVta                = out_payload_0.vpu_specVta;
  assign io_out_0_bits_vpu_specVsew               = out_payload_0.vpu_specVsew;
  assign io_out_0_bits_vpu_specVlmul              = out_payload_0.vpu_specVlmul;
  assign io_out_0_bits_vpu_vm                     = out_payload_0.vpu_vm;
  assign io_out_0_bits_vpu_vstart                 = out_payload_0.vpu_vstart;
  assign io_out_0_bits_vpu_frm                    = out_payload_0.vpu_frm;
  assign io_out_0_bits_vpu_fpu_isFpToVecInst      = out_payload_0.vpu_fpu_isFpToVecInst;
  assign io_out_0_bits_vpu_fpu_isFP32Instr        = out_payload_0.vpu_fpu_isFP32Instr;
  assign io_out_0_bits_vpu_fpu_isFP64Instr        = out_payload_0.vpu_fpu_isFP64Instr;
  assign io_out_0_bits_vpu_fpu_isReduction        = out_payload_0.vpu_fpu_isReduction;
  assign io_out_0_bits_vpu_fpu_isFoldTo1_2        = out_payload_0.vpu_fpu_isFoldTo1_2;
  assign io_out_0_bits_vpu_fpu_isFoldTo1_4        = out_payload_0.vpu_fpu_isFoldTo1_4;
  assign io_out_0_bits_vpu_fpu_isFoldTo1_8        = out_payload_0.vpu_fpu_isFoldTo1_8;
  assign io_out_0_bits_vpu_vxrm                   = out_payload_0.vpu_vxrm;
  assign io_out_0_bits_vpu_vuopIdx                = out_payload_0.vpu_vuopIdx;
  assign io_out_0_bits_vpu_lastUop                = out_payload_0.vpu_lastUop;
  assign io_out_0_bits_vpu_vmask                  = out_payload_0.vpu_vmask;
  assign io_out_0_bits_vpu_vl                     = out_payload_0.vpu_vl;
  assign io_out_0_bits_vpu_nf                     = out_payload_0.vpu_nf;
  assign io_out_0_bits_vpu_veew                   = out_payload_0.vpu_veew;
  assign io_out_0_bits_vpu_isReverse              = out_payload_0.vpu_isReverse;
  assign io_out_0_bits_vpu_isExt                  = out_payload_0.vpu_isExt;
  assign io_out_0_bits_vpu_isNarrow               = out_payload_0.vpu_isNarrow;
  assign io_out_0_bits_vpu_isDstMask              = out_payload_0.vpu_isDstMask;
  assign io_out_0_bits_vpu_isOpMask               = out_payload_0.vpu_isOpMask;
  assign io_out_0_bits_vpu_isMove                 = out_payload_0.vpu_isMove;
  assign io_out_0_bits_vpu_isDependOldVd          = out_payload_0.vpu_isDependOldVd;
  assign io_out_0_bits_vpu_isWritePartVd          = out_payload_0.vpu_isWritePartVd;
  assign io_out_0_bits_vpu_isVleff                = out_payload_0.vpu_isVleff;
  assign io_out_0_bits_vlsInstr                   = out_payload_0.vlsInstr;
  assign io_out_0_bits_wfflags                    = out_payload_0.wfflags;
  assign io_out_0_bits_isMove                     = out_payload_0.isMove;
  assign io_out_0_bits_uopIdx                     = out_payload_0.uopIdx;
  assign io_out_0_bits_isVset                     = out_payload_0.isVset;
  assign io_out_0_bits_firstUop                   = out_payload_0.firstUop;
  assign io_out_0_bits_lastUop                    = out_payload_0.lastUop;
  assign io_out_0_bits_numUops                    = out_payload_0.numUops;
  assign io_out_0_bits_numWB                      = out_payload_0.numWB;
  assign io_out_0_bits_commitType                 = out_payload_0.commitType;
  assign io_out_0_bits_psrc_0                     = out_payload_0.psrc_0;
  assign io_out_0_bits_psrc_1                     = out_payload_0.psrc_1;
  assign io_out_0_bits_psrc_2                     = out_payload_0.psrc_2;
  assign io_out_0_bits_psrc_3                     = out_payload_0.psrc_3;
  assign io_out_0_bits_psrc_4                     = out_payload_0.psrc_4;
  assign io_out_0_bits_pdest                      = out_payload_0.pdest;
  assign io_out_0_bits_robIdx_flag                = out_payload_0.robIdx_flag;
  assign io_out_0_bits_robIdx_value               = out_payload_0.robIdx_value;
  assign io_out_0_bits_instrSize                  = out_payload_0.instrSize;
  assign io_out_0_bits_dirtyFs                    = out_payload_0.dirtyFs;
  assign io_out_0_bits_dirtyVs                    = out_payload_0.dirtyVs;
  assign io_out_0_bits_traceBlockInPipe_itype     = out_payload_0.traceBlockInPipe_itype;
  assign io_out_0_bits_traceBlockInPipe_iretire   = out_payload_0.traceBlockInPipe_iretire;
  assign io_out_0_bits_traceBlockInPipe_ilastsize = out_payload_0.traceBlockInPipe_ilastsize;
  assign io_out_0_bits_eliminatedMove             = out_payload_0.eliminatedMove;
  assign io_out_0_bits_snapshot                   = out_payload_0.snapshot;
  assign io_out_0_bits_debugInfo_renameTime       = out_payload_0.debugInfo_renameTime;
  assign io_out_0_bits_debug_seqNum_seqNum        = out_payload_0.debug_seqNum_seqNum;
  assign io_out_0_bits_debug_seqNum_uopIdx        = out_payload_0.debug_seqNum_uopIdx;
  assign io_out_0_bits_debug_fuType               = out_payload_0.debug_fuType;
  assign io_out_0_bits_debug_sim_trig             = out_payload_0.debug_sim_trig;
  assign io_out_0_bits_numLsElem                  = out_payload_0.numLsElem;

  // ---------------------------------------------------------------------------
  // lane 1：入口打包 / 出口拆包（同名逐项）
  // ---------------------------------------------------------------------------
  always_comb begin
    in_payload_1.instr                      = io_in_1_bits_instr;
    in_payload_1.pc                         = io_in_1_bits_pc;
    in_payload_1.foldpc                     = io_in_1_bits_foldpc;
    in_payload_1.exceptionVec_0             = io_in_1_bits_exceptionVec_0;
    in_payload_1.exceptionVec_1             = io_in_1_bits_exceptionVec_1;
    in_payload_1.exceptionVec_2             = io_in_1_bits_exceptionVec_2;
    in_payload_1.exceptionVec_3             = io_in_1_bits_exceptionVec_3;
    in_payload_1.exceptionVec_4             = io_in_1_bits_exceptionVec_4;
    in_payload_1.exceptionVec_5             = io_in_1_bits_exceptionVec_5;
    in_payload_1.exceptionVec_6             = io_in_1_bits_exceptionVec_6;
    in_payload_1.exceptionVec_7             = io_in_1_bits_exceptionVec_7;
    in_payload_1.exceptionVec_8             = io_in_1_bits_exceptionVec_8;
    in_payload_1.exceptionVec_9             = io_in_1_bits_exceptionVec_9;
    in_payload_1.exceptionVec_10            = io_in_1_bits_exceptionVec_10;
    in_payload_1.exceptionVec_11            = io_in_1_bits_exceptionVec_11;
    in_payload_1.exceptionVec_12            = io_in_1_bits_exceptionVec_12;
    in_payload_1.exceptionVec_13            = io_in_1_bits_exceptionVec_13;
    in_payload_1.exceptionVec_14            = io_in_1_bits_exceptionVec_14;
    in_payload_1.exceptionVec_15            = io_in_1_bits_exceptionVec_15;
    in_payload_1.exceptionVec_16            = io_in_1_bits_exceptionVec_16;
    in_payload_1.exceptionVec_17            = io_in_1_bits_exceptionVec_17;
    in_payload_1.exceptionVec_18            = io_in_1_bits_exceptionVec_18;
    in_payload_1.exceptionVec_19            = io_in_1_bits_exceptionVec_19;
    in_payload_1.exceptionVec_20            = io_in_1_bits_exceptionVec_20;
    in_payload_1.exceptionVec_21            = io_in_1_bits_exceptionVec_21;
    in_payload_1.exceptionVec_22            = io_in_1_bits_exceptionVec_22;
    in_payload_1.exceptionVec_23            = io_in_1_bits_exceptionVec_23;
    in_payload_1.isFetchMalAddr             = io_in_1_bits_isFetchMalAddr;
    in_payload_1.hasException               = io_in_1_bits_hasException;
    in_payload_1.trigger                    = io_in_1_bits_trigger;
    in_payload_1.preDecodeInfo_valid        = io_in_1_bits_preDecodeInfo_valid;
    in_payload_1.preDecodeInfo_isRVC        = io_in_1_bits_preDecodeInfo_isRVC;
    in_payload_1.preDecodeInfo_brType       = io_in_1_bits_preDecodeInfo_brType;
    in_payload_1.preDecodeInfo_isCall       = io_in_1_bits_preDecodeInfo_isCall;
    in_payload_1.preDecodeInfo_isRet        = io_in_1_bits_preDecodeInfo_isRet;
    in_payload_1.pred_taken                 = io_in_1_bits_pred_taken;
    in_payload_1.crossPageIPFFix            = io_in_1_bits_crossPageIPFFix;
    in_payload_1.ftqPtr_flag                = io_in_1_bits_ftqPtr_flag;
    in_payload_1.ftqPtr_value               = io_in_1_bits_ftqPtr_value;
    in_payload_1.ftqOffset                  = io_in_1_bits_ftqOffset;
    in_payload_1.satpFlushFirstFetchFault   = io_in_1_bits_satpFlushFirstFetchFault;
    in_payload_1.srcType_0                  = io_in_1_bits_srcType_0;
    in_payload_1.srcType_1                  = io_in_1_bits_srcType_1;
    in_payload_1.srcType_2                  = io_in_1_bits_srcType_2;
    in_payload_1.srcType_3                  = io_in_1_bits_srcType_3;
    in_payload_1.srcType_4                  = io_in_1_bits_srcType_4;
    in_payload_1.ldest                      = io_in_1_bits_ldest;
    in_payload_1.fuType                     = io_in_1_bits_fuType;
    in_payload_1.fuOpType                   = io_in_1_bits_fuOpType;
    in_payload_1.rfWen                      = io_in_1_bits_rfWen;
    in_payload_1.fpWen                      = io_in_1_bits_fpWen;
    in_payload_1.vecWen                     = io_in_1_bits_vecWen;
    in_payload_1.v0Wen                      = io_in_1_bits_v0Wen;
    in_payload_1.vlWen                      = io_in_1_bits_vlWen;
    in_payload_1.isXSTrap                   = io_in_1_bits_isXSTrap;
    in_payload_1.waitForward                = io_in_1_bits_waitForward;
    in_payload_1.blockBackward              = io_in_1_bits_blockBackward;
    in_payload_1.flushPipe                  = io_in_1_bits_flushPipe;
    in_payload_1.canRobCompress             = io_in_1_bits_canRobCompress;
    in_payload_1.selImm                     = io_in_1_bits_selImm;
    in_payload_1.imm                        = io_in_1_bits_imm;
    in_payload_1.fpu_typeTagOut             = io_in_1_bits_fpu_typeTagOut;
    in_payload_1.fpu_wflags                 = io_in_1_bits_fpu_wflags;
    in_payload_1.fpu_typ                    = io_in_1_bits_fpu_typ;
    in_payload_1.fpu_fmt                    = io_in_1_bits_fpu_fmt;
    in_payload_1.fpu_rm                     = io_in_1_bits_fpu_rm;
    in_payload_1.vpu_vill                   = io_in_1_bits_vpu_vill;
    in_payload_1.vpu_vma                    = io_in_1_bits_vpu_vma;
    in_payload_1.vpu_vta                    = io_in_1_bits_vpu_vta;
    in_payload_1.vpu_vsew                   = io_in_1_bits_vpu_vsew;
    in_payload_1.vpu_vlmul                  = io_in_1_bits_vpu_vlmul;
    in_payload_1.vpu_specVill               = io_in_1_bits_vpu_specVill;
    in_payload_1.vpu_specVma                = io_in_1_bits_vpu_specVma;
    in_payload_1.vpu_specVta                = io_in_1_bits_vpu_specVta;
    in_payload_1.vpu_specVsew               = io_in_1_bits_vpu_specVsew;
    in_payload_1.vpu_specVlmul              = io_in_1_bits_vpu_specVlmul;
    in_payload_1.vpu_vm                     = io_in_1_bits_vpu_vm;
    in_payload_1.vpu_vstart                 = io_in_1_bits_vpu_vstart;
    in_payload_1.vpu_frm                    = io_in_1_bits_vpu_frm;
    in_payload_1.vpu_fpu_isFpToVecInst      = io_in_1_bits_vpu_fpu_isFpToVecInst;
    in_payload_1.vpu_fpu_isFP32Instr        = io_in_1_bits_vpu_fpu_isFP32Instr;
    in_payload_1.vpu_fpu_isFP64Instr        = io_in_1_bits_vpu_fpu_isFP64Instr;
    in_payload_1.vpu_fpu_isReduction        = io_in_1_bits_vpu_fpu_isReduction;
    in_payload_1.vpu_fpu_isFoldTo1_2        = io_in_1_bits_vpu_fpu_isFoldTo1_2;
    in_payload_1.vpu_fpu_isFoldTo1_4        = io_in_1_bits_vpu_fpu_isFoldTo1_4;
    in_payload_1.vpu_fpu_isFoldTo1_8        = io_in_1_bits_vpu_fpu_isFoldTo1_8;
    in_payload_1.vpu_vxrm                   = io_in_1_bits_vpu_vxrm;
    in_payload_1.vpu_vuopIdx                = io_in_1_bits_vpu_vuopIdx;
    in_payload_1.vpu_lastUop                = io_in_1_bits_vpu_lastUop;
    in_payload_1.vpu_vmask                  = io_in_1_bits_vpu_vmask;
    in_payload_1.vpu_vl                     = io_in_1_bits_vpu_vl;
    in_payload_1.vpu_nf                     = io_in_1_bits_vpu_nf;
    in_payload_1.vpu_veew                   = io_in_1_bits_vpu_veew;
    in_payload_1.vpu_isReverse              = io_in_1_bits_vpu_isReverse;
    in_payload_1.vpu_isExt                  = io_in_1_bits_vpu_isExt;
    in_payload_1.vpu_isNarrow               = io_in_1_bits_vpu_isNarrow;
    in_payload_1.vpu_isDstMask              = io_in_1_bits_vpu_isDstMask;
    in_payload_1.vpu_isOpMask               = io_in_1_bits_vpu_isOpMask;
    in_payload_1.vpu_isMove                 = io_in_1_bits_vpu_isMove;
    in_payload_1.vpu_isDependOldVd          = io_in_1_bits_vpu_isDependOldVd;
    in_payload_1.vpu_isWritePartVd          = io_in_1_bits_vpu_isWritePartVd;
    in_payload_1.vpu_isVleff                = io_in_1_bits_vpu_isVleff;
    in_payload_1.vlsInstr                   = io_in_1_bits_vlsInstr;
    in_payload_1.wfflags                    = io_in_1_bits_wfflags;
    in_payload_1.isMove                     = io_in_1_bits_isMove;
    in_payload_1.uopIdx                     = io_in_1_bits_uopIdx;
    in_payload_1.isVset                     = io_in_1_bits_isVset;
    in_payload_1.firstUop                   = io_in_1_bits_firstUop;
    in_payload_1.lastUop                    = io_in_1_bits_lastUop;
    in_payload_1.numUops                    = io_in_1_bits_numUops;
    in_payload_1.numWB                      = io_in_1_bits_numWB;
    in_payload_1.commitType                 = io_in_1_bits_commitType;
    in_payload_1.psrc_0                     = io_in_1_bits_psrc_0;
    in_payload_1.psrc_1                     = io_in_1_bits_psrc_1;
    in_payload_1.psrc_2                     = io_in_1_bits_psrc_2;
    in_payload_1.psrc_3                     = io_in_1_bits_psrc_3;
    in_payload_1.psrc_4                     = io_in_1_bits_psrc_4;
    in_payload_1.pdest                      = io_in_1_bits_pdest;
    in_payload_1.robIdx_flag                = io_in_1_bits_robIdx_flag;
    in_payload_1.robIdx_value               = io_in_1_bits_robIdx_value;
    in_payload_1.instrSize                  = io_in_1_bits_instrSize;
    in_payload_1.dirtyFs                    = io_in_1_bits_dirtyFs;
    in_payload_1.dirtyVs                    = io_in_1_bits_dirtyVs;
    in_payload_1.traceBlockInPipe_itype     = io_in_1_bits_traceBlockInPipe_itype;
    in_payload_1.traceBlockInPipe_iretire   = io_in_1_bits_traceBlockInPipe_iretire;
    in_payload_1.traceBlockInPipe_ilastsize = io_in_1_bits_traceBlockInPipe_ilastsize;
    in_payload_1.eliminatedMove             = io_in_1_bits_eliminatedMove;
    in_payload_1.debugInfo_renameTime       = io_in_1_bits_debugInfo_renameTime;
    in_payload_1.debug_seqNum_seqNum        = io_in_1_bits_debug_seqNum_seqNum;
    in_payload_1.debug_seqNum_uopIdx        = io_in_1_bits_debug_seqNum_uopIdx;
    in_payload_1.debug_fuType               = io_in_1_bits_debug_fuType;
    in_payload_1.debug_sim_trig             = io_in_1_bits_debug_sim_trig;
    in_payload_1.numLsElem                  = io_in_1_bits_numLsElem;
  end
  assign io_out_1_bits_instr                      = out_payload_1.instr;
  assign io_out_1_bits_pc                         = out_payload_1.pc;
  assign io_out_1_bits_foldpc                     = out_payload_1.foldpc;
  assign io_out_1_bits_exceptionVec_0             = out_payload_1.exceptionVec_0;
  assign io_out_1_bits_exceptionVec_1             = out_payload_1.exceptionVec_1;
  assign io_out_1_bits_exceptionVec_2             = out_payload_1.exceptionVec_2;
  assign io_out_1_bits_exceptionVec_3             = out_payload_1.exceptionVec_3;
  assign io_out_1_bits_exceptionVec_4             = out_payload_1.exceptionVec_4;
  assign io_out_1_bits_exceptionVec_5             = out_payload_1.exceptionVec_5;
  assign io_out_1_bits_exceptionVec_6             = out_payload_1.exceptionVec_6;
  assign io_out_1_bits_exceptionVec_7             = out_payload_1.exceptionVec_7;
  assign io_out_1_bits_exceptionVec_8             = out_payload_1.exceptionVec_8;
  assign io_out_1_bits_exceptionVec_9             = out_payload_1.exceptionVec_9;
  assign io_out_1_bits_exceptionVec_10            = out_payload_1.exceptionVec_10;
  assign io_out_1_bits_exceptionVec_11            = out_payload_1.exceptionVec_11;
  assign io_out_1_bits_exceptionVec_12            = out_payload_1.exceptionVec_12;
  assign io_out_1_bits_exceptionVec_13            = out_payload_1.exceptionVec_13;
  assign io_out_1_bits_exceptionVec_14            = out_payload_1.exceptionVec_14;
  assign io_out_1_bits_exceptionVec_15            = out_payload_1.exceptionVec_15;
  assign io_out_1_bits_exceptionVec_16            = out_payload_1.exceptionVec_16;
  assign io_out_1_bits_exceptionVec_17            = out_payload_1.exceptionVec_17;
  assign io_out_1_bits_exceptionVec_18            = out_payload_1.exceptionVec_18;
  assign io_out_1_bits_exceptionVec_19            = out_payload_1.exceptionVec_19;
  assign io_out_1_bits_exceptionVec_20            = out_payload_1.exceptionVec_20;
  assign io_out_1_bits_exceptionVec_21            = out_payload_1.exceptionVec_21;
  assign io_out_1_bits_exceptionVec_22            = out_payload_1.exceptionVec_22;
  assign io_out_1_bits_exceptionVec_23            = out_payload_1.exceptionVec_23;
  assign io_out_1_bits_isFetchMalAddr             = out_payload_1.isFetchMalAddr;
  assign io_out_1_bits_hasException               = out_payload_1.hasException;
  assign io_out_1_bits_trigger                    = out_payload_1.trigger;
  assign io_out_1_bits_preDecodeInfo_valid        = out_payload_1.preDecodeInfo_valid;
  assign io_out_1_bits_preDecodeInfo_isRVC        = out_payload_1.preDecodeInfo_isRVC;
  assign io_out_1_bits_preDecodeInfo_brType       = out_payload_1.preDecodeInfo_brType;
  assign io_out_1_bits_preDecodeInfo_isCall       = out_payload_1.preDecodeInfo_isCall;
  assign io_out_1_bits_preDecodeInfo_isRet        = out_payload_1.preDecodeInfo_isRet;
  assign io_out_1_bits_pred_taken                 = out_payload_1.pred_taken;
  assign io_out_1_bits_crossPageIPFFix            = out_payload_1.crossPageIPFFix;
  assign io_out_1_bits_ftqPtr_flag                = out_payload_1.ftqPtr_flag;
  assign io_out_1_bits_ftqPtr_value               = out_payload_1.ftqPtr_value;
  assign io_out_1_bits_ftqOffset                  = out_payload_1.ftqOffset;
  assign io_out_1_bits_satpFlushFirstFetchFault   = out_payload_1.satpFlushFirstFetchFault;
  assign io_out_1_bits_srcType_0                  = out_payload_1.srcType_0;
  assign io_out_1_bits_srcType_1                  = out_payload_1.srcType_1;
  assign io_out_1_bits_srcType_2                  = out_payload_1.srcType_2;
  assign io_out_1_bits_srcType_3                  = out_payload_1.srcType_3;
  assign io_out_1_bits_srcType_4                  = out_payload_1.srcType_4;
  assign io_out_1_bits_ldest                      = out_payload_1.ldest;
  assign io_out_1_bits_fuType                     = out_payload_1.fuType;
  assign io_out_1_bits_fuOpType                   = out_payload_1.fuOpType;
  assign io_out_1_bits_rfWen                      = out_payload_1.rfWen;
  assign io_out_1_bits_fpWen                      = out_payload_1.fpWen;
  assign io_out_1_bits_vecWen                     = out_payload_1.vecWen;
  assign io_out_1_bits_v0Wen                      = out_payload_1.v0Wen;
  assign io_out_1_bits_vlWen                      = out_payload_1.vlWen;
  assign io_out_1_bits_isXSTrap                   = out_payload_1.isXSTrap;
  assign io_out_1_bits_waitForward                = out_payload_1.waitForward;
  assign io_out_1_bits_blockBackward              = out_payload_1.blockBackward;
  assign io_out_1_bits_flushPipe                  = out_payload_1.flushPipe;
  assign io_out_1_bits_canRobCompress             = out_payload_1.canRobCompress;
  assign io_out_1_bits_selImm                     = out_payload_1.selImm;
  assign io_out_1_bits_imm                        = out_payload_1.imm;
  assign io_out_1_bits_fpu_typeTagOut             = out_payload_1.fpu_typeTagOut;
  assign io_out_1_bits_fpu_wflags                 = out_payload_1.fpu_wflags;
  assign io_out_1_bits_fpu_typ                    = out_payload_1.fpu_typ;
  assign io_out_1_bits_fpu_fmt                    = out_payload_1.fpu_fmt;
  assign io_out_1_bits_fpu_rm                     = out_payload_1.fpu_rm;
  assign io_out_1_bits_vpu_vill                   = out_payload_1.vpu_vill;
  assign io_out_1_bits_vpu_vma                    = out_payload_1.vpu_vma;
  assign io_out_1_bits_vpu_vta                    = out_payload_1.vpu_vta;
  assign io_out_1_bits_vpu_vsew                   = out_payload_1.vpu_vsew;
  assign io_out_1_bits_vpu_vlmul                  = out_payload_1.vpu_vlmul;
  assign io_out_1_bits_vpu_specVill               = out_payload_1.vpu_specVill;
  assign io_out_1_bits_vpu_specVma                = out_payload_1.vpu_specVma;
  assign io_out_1_bits_vpu_specVta                = out_payload_1.vpu_specVta;
  assign io_out_1_bits_vpu_specVsew               = out_payload_1.vpu_specVsew;
  assign io_out_1_bits_vpu_specVlmul              = out_payload_1.vpu_specVlmul;
  assign io_out_1_bits_vpu_vm                     = out_payload_1.vpu_vm;
  assign io_out_1_bits_vpu_vstart                 = out_payload_1.vpu_vstart;
  assign io_out_1_bits_vpu_frm                    = out_payload_1.vpu_frm;
  assign io_out_1_bits_vpu_fpu_isFpToVecInst      = out_payload_1.vpu_fpu_isFpToVecInst;
  assign io_out_1_bits_vpu_fpu_isFP32Instr        = out_payload_1.vpu_fpu_isFP32Instr;
  assign io_out_1_bits_vpu_fpu_isFP64Instr        = out_payload_1.vpu_fpu_isFP64Instr;
  assign io_out_1_bits_vpu_fpu_isReduction        = out_payload_1.vpu_fpu_isReduction;
  assign io_out_1_bits_vpu_fpu_isFoldTo1_2        = out_payload_1.vpu_fpu_isFoldTo1_2;
  assign io_out_1_bits_vpu_fpu_isFoldTo1_4        = out_payload_1.vpu_fpu_isFoldTo1_4;
  assign io_out_1_bits_vpu_fpu_isFoldTo1_8        = out_payload_1.vpu_fpu_isFoldTo1_8;
  assign io_out_1_bits_vpu_vxrm                   = out_payload_1.vpu_vxrm;
  assign io_out_1_bits_vpu_vuopIdx                = out_payload_1.vpu_vuopIdx;
  assign io_out_1_bits_vpu_lastUop                = out_payload_1.vpu_lastUop;
  assign io_out_1_bits_vpu_vmask                  = out_payload_1.vpu_vmask;
  assign io_out_1_bits_vpu_vl                     = out_payload_1.vpu_vl;
  assign io_out_1_bits_vpu_nf                     = out_payload_1.vpu_nf;
  assign io_out_1_bits_vpu_veew                   = out_payload_1.vpu_veew;
  assign io_out_1_bits_vpu_isReverse              = out_payload_1.vpu_isReverse;
  assign io_out_1_bits_vpu_isExt                  = out_payload_1.vpu_isExt;
  assign io_out_1_bits_vpu_isNarrow               = out_payload_1.vpu_isNarrow;
  assign io_out_1_bits_vpu_isDstMask              = out_payload_1.vpu_isDstMask;
  assign io_out_1_bits_vpu_isOpMask               = out_payload_1.vpu_isOpMask;
  assign io_out_1_bits_vpu_isMove                 = out_payload_1.vpu_isMove;
  assign io_out_1_bits_vpu_isDependOldVd          = out_payload_1.vpu_isDependOldVd;
  assign io_out_1_bits_vpu_isWritePartVd          = out_payload_1.vpu_isWritePartVd;
  assign io_out_1_bits_vpu_isVleff                = out_payload_1.vpu_isVleff;
  assign io_out_1_bits_vlsInstr                   = out_payload_1.vlsInstr;
  assign io_out_1_bits_wfflags                    = out_payload_1.wfflags;
  assign io_out_1_bits_isMove                     = out_payload_1.isMove;
  assign io_out_1_bits_uopIdx                     = out_payload_1.uopIdx;
  assign io_out_1_bits_isVset                     = out_payload_1.isVset;
  assign io_out_1_bits_firstUop                   = out_payload_1.firstUop;
  assign io_out_1_bits_lastUop                    = out_payload_1.lastUop;
  assign io_out_1_bits_numUops                    = out_payload_1.numUops;
  assign io_out_1_bits_numWB                      = out_payload_1.numWB;
  assign io_out_1_bits_commitType                 = out_payload_1.commitType;
  assign io_out_1_bits_psrc_0                     = out_payload_1.psrc_0;
  assign io_out_1_bits_psrc_1                     = out_payload_1.psrc_1;
  assign io_out_1_bits_psrc_2                     = out_payload_1.psrc_2;
  assign io_out_1_bits_psrc_3                     = out_payload_1.psrc_3;
  assign io_out_1_bits_psrc_4                     = out_payload_1.psrc_4;
  assign io_out_1_bits_pdest                      = out_payload_1.pdest;
  assign io_out_1_bits_robIdx_flag                = out_payload_1.robIdx_flag;
  assign io_out_1_bits_robIdx_value               = out_payload_1.robIdx_value;
  assign io_out_1_bits_instrSize                  = out_payload_1.instrSize;
  assign io_out_1_bits_dirtyFs                    = out_payload_1.dirtyFs;
  assign io_out_1_bits_dirtyVs                    = out_payload_1.dirtyVs;
  assign io_out_1_bits_traceBlockInPipe_itype     = out_payload_1.traceBlockInPipe_itype;
  assign io_out_1_bits_traceBlockInPipe_iretire   = out_payload_1.traceBlockInPipe_iretire;
  assign io_out_1_bits_traceBlockInPipe_ilastsize = out_payload_1.traceBlockInPipe_ilastsize;
  assign io_out_1_bits_eliminatedMove             = out_payload_1.eliminatedMove;
  assign io_out_1_bits_debugInfo_renameTime       = out_payload_1.debugInfo_renameTime;
  assign io_out_1_bits_debug_seqNum_seqNum        = out_payload_1.debug_seqNum_seqNum;
  assign io_out_1_bits_debug_seqNum_uopIdx        = out_payload_1.debug_seqNum_uopIdx;
  assign io_out_1_bits_debug_fuType               = out_payload_1.debug_fuType;
  assign io_out_1_bits_debug_sim_trig             = out_payload_1.debug_sim_trig;
  assign io_out_1_bits_numLsElem                  = out_payload_1.numLsElem;

  // ---------------------------------------------------------------------------
  // lane 2：入口打包 / 出口拆包（同名逐项）
  // ---------------------------------------------------------------------------
  always_comb begin
    in_payload_2.instr                      = io_in_2_bits_instr;
    in_payload_2.pc                         = io_in_2_bits_pc;
    in_payload_2.foldpc                     = io_in_2_bits_foldpc;
    in_payload_2.exceptionVec_0             = io_in_2_bits_exceptionVec_0;
    in_payload_2.exceptionVec_1             = io_in_2_bits_exceptionVec_1;
    in_payload_2.exceptionVec_2             = io_in_2_bits_exceptionVec_2;
    in_payload_2.exceptionVec_3             = io_in_2_bits_exceptionVec_3;
    in_payload_2.exceptionVec_4             = io_in_2_bits_exceptionVec_4;
    in_payload_2.exceptionVec_5             = io_in_2_bits_exceptionVec_5;
    in_payload_2.exceptionVec_6             = io_in_2_bits_exceptionVec_6;
    in_payload_2.exceptionVec_7             = io_in_2_bits_exceptionVec_7;
    in_payload_2.exceptionVec_8             = io_in_2_bits_exceptionVec_8;
    in_payload_2.exceptionVec_9             = io_in_2_bits_exceptionVec_9;
    in_payload_2.exceptionVec_10            = io_in_2_bits_exceptionVec_10;
    in_payload_2.exceptionVec_11            = io_in_2_bits_exceptionVec_11;
    in_payload_2.exceptionVec_12            = io_in_2_bits_exceptionVec_12;
    in_payload_2.exceptionVec_13            = io_in_2_bits_exceptionVec_13;
    in_payload_2.exceptionVec_14            = io_in_2_bits_exceptionVec_14;
    in_payload_2.exceptionVec_15            = io_in_2_bits_exceptionVec_15;
    in_payload_2.exceptionVec_16            = io_in_2_bits_exceptionVec_16;
    in_payload_2.exceptionVec_17            = io_in_2_bits_exceptionVec_17;
    in_payload_2.exceptionVec_18            = io_in_2_bits_exceptionVec_18;
    in_payload_2.exceptionVec_19            = io_in_2_bits_exceptionVec_19;
    in_payload_2.exceptionVec_20            = io_in_2_bits_exceptionVec_20;
    in_payload_2.exceptionVec_21            = io_in_2_bits_exceptionVec_21;
    in_payload_2.exceptionVec_22            = io_in_2_bits_exceptionVec_22;
    in_payload_2.exceptionVec_23            = io_in_2_bits_exceptionVec_23;
    in_payload_2.isFetchMalAddr             = io_in_2_bits_isFetchMalAddr;
    in_payload_2.hasException               = io_in_2_bits_hasException;
    in_payload_2.trigger                    = io_in_2_bits_trigger;
    in_payload_2.preDecodeInfo_valid        = io_in_2_bits_preDecodeInfo_valid;
    in_payload_2.preDecodeInfo_isRVC        = io_in_2_bits_preDecodeInfo_isRVC;
    in_payload_2.preDecodeInfo_brType       = io_in_2_bits_preDecodeInfo_brType;
    in_payload_2.preDecodeInfo_isCall       = io_in_2_bits_preDecodeInfo_isCall;
    in_payload_2.preDecodeInfo_isRet        = io_in_2_bits_preDecodeInfo_isRet;
    in_payload_2.pred_taken                 = io_in_2_bits_pred_taken;
    in_payload_2.crossPageIPFFix            = io_in_2_bits_crossPageIPFFix;
    in_payload_2.ftqPtr_flag                = io_in_2_bits_ftqPtr_flag;
    in_payload_2.ftqPtr_value               = io_in_2_bits_ftqPtr_value;
    in_payload_2.ftqOffset                  = io_in_2_bits_ftqOffset;
    in_payload_2.satpFlushFirstFetchFault   = io_in_2_bits_satpFlushFirstFetchFault;
    in_payload_2.srcType_0                  = io_in_2_bits_srcType_0;
    in_payload_2.srcType_1                  = io_in_2_bits_srcType_1;
    in_payload_2.srcType_2                  = io_in_2_bits_srcType_2;
    in_payload_2.srcType_3                  = io_in_2_bits_srcType_3;
    in_payload_2.srcType_4                  = io_in_2_bits_srcType_4;
    in_payload_2.ldest                      = io_in_2_bits_ldest;
    in_payload_2.fuType                     = io_in_2_bits_fuType;
    in_payload_2.fuOpType                   = io_in_2_bits_fuOpType;
    in_payload_2.rfWen                      = io_in_2_bits_rfWen;
    in_payload_2.fpWen                      = io_in_2_bits_fpWen;
    in_payload_2.vecWen                     = io_in_2_bits_vecWen;
    in_payload_2.v0Wen                      = io_in_2_bits_v0Wen;
    in_payload_2.vlWen                      = io_in_2_bits_vlWen;
    in_payload_2.isXSTrap                   = io_in_2_bits_isXSTrap;
    in_payload_2.waitForward                = io_in_2_bits_waitForward;
    in_payload_2.blockBackward              = io_in_2_bits_blockBackward;
    in_payload_2.flushPipe                  = io_in_2_bits_flushPipe;
    in_payload_2.canRobCompress             = io_in_2_bits_canRobCompress;
    in_payload_2.selImm                     = io_in_2_bits_selImm;
    in_payload_2.imm                        = io_in_2_bits_imm;
    in_payload_2.fpu_typeTagOut             = io_in_2_bits_fpu_typeTagOut;
    in_payload_2.fpu_wflags                 = io_in_2_bits_fpu_wflags;
    in_payload_2.fpu_typ                    = io_in_2_bits_fpu_typ;
    in_payload_2.fpu_fmt                    = io_in_2_bits_fpu_fmt;
    in_payload_2.fpu_rm                     = io_in_2_bits_fpu_rm;
    in_payload_2.vpu_vill                   = io_in_2_bits_vpu_vill;
    in_payload_2.vpu_vma                    = io_in_2_bits_vpu_vma;
    in_payload_2.vpu_vta                    = io_in_2_bits_vpu_vta;
    in_payload_2.vpu_vsew                   = io_in_2_bits_vpu_vsew;
    in_payload_2.vpu_vlmul                  = io_in_2_bits_vpu_vlmul;
    in_payload_2.vpu_specVill               = io_in_2_bits_vpu_specVill;
    in_payload_2.vpu_specVma                = io_in_2_bits_vpu_specVma;
    in_payload_2.vpu_specVta                = io_in_2_bits_vpu_specVta;
    in_payload_2.vpu_specVsew               = io_in_2_bits_vpu_specVsew;
    in_payload_2.vpu_specVlmul              = io_in_2_bits_vpu_specVlmul;
    in_payload_2.vpu_vm                     = io_in_2_bits_vpu_vm;
    in_payload_2.vpu_vstart                 = io_in_2_bits_vpu_vstart;
    in_payload_2.vpu_frm                    = io_in_2_bits_vpu_frm;
    in_payload_2.vpu_fpu_isFpToVecInst      = io_in_2_bits_vpu_fpu_isFpToVecInst;
    in_payload_2.vpu_fpu_isFP32Instr        = io_in_2_bits_vpu_fpu_isFP32Instr;
    in_payload_2.vpu_fpu_isFP64Instr        = io_in_2_bits_vpu_fpu_isFP64Instr;
    in_payload_2.vpu_fpu_isReduction        = io_in_2_bits_vpu_fpu_isReduction;
    in_payload_2.vpu_fpu_isFoldTo1_2        = io_in_2_bits_vpu_fpu_isFoldTo1_2;
    in_payload_2.vpu_fpu_isFoldTo1_4        = io_in_2_bits_vpu_fpu_isFoldTo1_4;
    in_payload_2.vpu_fpu_isFoldTo1_8        = io_in_2_bits_vpu_fpu_isFoldTo1_8;
    in_payload_2.vpu_vxrm                   = io_in_2_bits_vpu_vxrm;
    in_payload_2.vpu_vuopIdx                = io_in_2_bits_vpu_vuopIdx;
    in_payload_2.vpu_lastUop                = io_in_2_bits_vpu_lastUop;
    in_payload_2.vpu_vmask                  = io_in_2_bits_vpu_vmask;
    in_payload_2.vpu_vl                     = io_in_2_bits_vpu_vl;
    in_payload_2.vpu_nf                     = io_in_2_bits_vpu_nf;
    in_payload_2.vpu_veew                   = io_in_2_bits_vpu_veew;
    in_payload_2.vpu_isReverse              = io_in_2_bits_vpu_isReverse;
    in_payload_2.vpu_isExt                  = io_in_2_bits_vpu_isExt;
    in_payload_2.vpu_isNarrow               = io_in_2_bits_vpu_isNarrow;
    in_payload_2.vpu_isDstMask              = io_in_2_bits_vpu_isDstMask;
    in_payload_2.vpu_isOpMask               = io_in_2_bits_vpu_isOpMask;
    in_payload_2.vpu_isMove                 = io_in_2_bits_vpu_isMove;
    in_payload_2.vpu_isDependOldVd          = io_in_2_bits_vpu_isDependOldVd;
    in_payload_2.vpu_isWritePartVd          = io_in_2_bits_vpu_isWritePartVd;
    in_payload_2.vpu_isVleff                = io_in_2_bits_vpu_isVleff;
    in_payload_2.vlsInstr                   = io_in_2_bits_vlsInstr;
    in_payload_2.wfflags                    = io_in_2_bits_wfflags;
    in_payload_2.isMove                     = io_in_2_bits_isMove;
    in_payload_2.uopIdx                     = io_in_2_bits_uopIdx;
    in_payload_2.isVset                     = io_in_2_bits_isVset;
    in_payload_2.firstUop                   = io_in_2_bits_firstUop;
    in_payload_2.lastUop                    = io_in_2_bits_lastUop;
    in_payload_2.numUops                    = io_in_2_bits_numUops;
    in_payload_2.numWB                      = io_in_2_bits_numWB;
    in_payload_2.commitType                 = io_in_2_bits_commitType;
    in_payload_2.psrc_0                     = io_in_2_bits_psrc_0;
    in_payload_2.psrc_1                     = io_in_2_bits_psrc_1;
    in_payload_2.psrc_2                     = io_in_2_bits_psrc_2;
    in_payload_2.psrc_3                     = io_in_2_bits_psrc_3;
    in_payload_2.psrc_4                     = io_in_2_bits_psrc_4;
    in_payload_2.pdest                      = io_in_2_bits_pdest;
    in_payload_2.robIdx_flag                = io_in_2_bits_robIdx_flag;
    in_payload_2.robIdx_value               = io_in_2_bits_robIdx_value;
    in_payload_2.instrSize                  = io_in_2_bits_instrSize;
    in_payload_2.dirtyFs                    = io_in_2_bits_dirtyFs;
    in_payload_2.dirtyVs                    = io_in_2_bits_dirtyVs;
    in_payload_2.traceBlockInPipe_itype     = io_in_2_bits_traceBlockInPipe_itype;
    in_payload_2.traceBlockInPipe_iretire   = io_in_2_bits_traceBlockInPipe_iretire;
    in_payload_2.traceBlockInPipe_ilastsize = io_in_2_bits_traceBlockInPipe_ilastsize;
    in_payload_2.eliminatedMove             = io_in_2_bits_eliminatedMove;
    in_payload_2.debugInfo_renameTime       = io_in_2_bits_debugInfo_renameTime;
    in_payload_2.debug_seqNum_seqNum        = io_in_2_bits_debug_seqNum_seqNum;
    in_payload_2.debug_seqNum_uopIdx        = io_in_2_bits_debug_seqNum_uopIdx;
    in_payload_2.debug_fuType               = io_in_2_bits_debug_fuType;
    in_payload_2.debug_sim_trig             = io_in_2_bits_debug_sim_trig;
    in_payload_2.numLsElem                  = io_in_2_bits_numLsElem;
  end
  assign io_out_2_bits_instr                      = out_payload_2.instr;
  assign io_out_2_bits_pc                         = out_payload_2.pc;
  assign io_out_2_bits_foldpc                     = out_payload_2.foldpc;
  assign io_out_2_bits_exceptionVec_0             = out_payload_2.exceptionVec_0;
  assign io_out_2_bits_exceptionVec_1             = out_payload_2.exceptionVec_1;
  assign io_out_2_bits_exceptionVec_2             = out_payload_2.exceptionVec_2;
  assign io_out_2_bits_exceptionVec_3             = out_payload_2.exceptionVec_3;
  assign io_out_2_bits_exceptionVec_4             = out_payload_2.exceptionVec_4;
  assign io_out_2_bits_exceptionVec_5             = out_payload_2.exceptionVec_5;
  assign io_out_2_bits_exceptionVec_6             = out_payload_2.exceptionVec_6;
  assign io_out_2_bits_exceptionVec_7             = out_payload_2.exceptionVec_7;
  assign io_out_2_bits_exceptionVec_8             = out_payload_2.exceptionVec_8;
  assign io_out_2_bits_exceptionVec_9             = out_payload_2.exceptionVec_9;
  assign io_out_2_bits_exceptionVec_10            = out_payload_2.exceptionVec_10;
  assign io_out_2_bits_exceptionVec_11            = out_payload_2.exceptionVec_11;
  assign io_out_2_bits_exceptionVec_12            = out_payload_2.exceptionVec_12;
  assign io_out_2_bits_exceptionVec_13            = out_payload_2.exceptionVec_13;
  assign io_out_2_bits_exceptionVec_14            = out_payload_2.exceptionVec_14;
  assign io_out_2_bits_exceptionVec_15            = out_payload_2.exceptionVec_15;
  assign io_out_2_bits_exceptionVec_16            = out_payload_2.exceptionVec_16;
  assign io_out_2_bits_exceptionVec_17            = out_payload_2.exceptionVec_17;
  assign io_out_2_bits_exceptionVec_18            = out_payload_2.exceptionVec_18;
  assign io_out_2_bits_exceptionVec_19            = out_payload_2.exceptionVec_19;
  assign io_out_2_bits_exceptionVec_20            = out_payload_2.exceptionVec_20;
  assign io_out_2_bits_exceptionVec_21            = out_payload_2.exceptionVec_21;
  assign io_out_2_bits_exceptionVec_22            = out_payload_2.exceptionVec_22;
  assign io_out_2_bits_exceptionVec_23            = out_payload_2.exceptionVec_23;
  assign io_out_2_bits_isFetchMalAddr             = out_payload_2.isFetchMalAddr;
  assign io_out_2_bits_hasException               = out_payload_2.hasException;
  assign io_out_2_bits_trigger                    = out_payload_2.trigger;
  assign io_out_2_bits_preDecodeInfo_valid        = out_payload_2.preDecodeInfo_valid;
  assign io_out_2_bits_preDecodeInfo_isRVC        = out_payload_2.preDecodeInfo_isRVC;
  assign io_out_2_bits_preDecodeInfo_brType       = out_payload_2.preDecodeInfo_brType;
  assign io_out_2_bits_preDecodeInfo_isCall       = out_payload_2.preDecodeInfo_isCall;
  assign io_out_2_bits_preDecodeInfo_isRet        = out_payload_2.preDecodeInfo_isRet;
  assign io_out_2_bits_pred_taken                 = out_payload_2.pred_taken;
  assign io_out_2_bits_crossPageIPFFix            = out_payload_2.crossPageIPFFix;
  assign io_out_2_bits_ftqPtr_flag                = out_payload_2.ftqPtr_flag;
  assign io_out_2_bits_ftqPtr_value               = out_payload_2.ftqPtr_value;
  assign io_out_2_bits_ftqOffset                  = out_payload_2.ftqOffset;
  assign io_out_2_bits_satpFlushFirstFetchFault   = out_payload_2.satpFlushFirstFetchFault;
  assign io_out_2_bits_srcType_0                  = out_payload_2.srcType_0;
  assign io_out_2_bits_srcType_1                  = out_payload_2.srcType_1;
  assign io_out_2_bits_srcType_2                  = out_payload_2.srcType_2;
  assign io_out_2_bits_srcType_3                  = out_payload_2.srcType_3;
  assign io_out_2_bits_srcType_4                  = out_payload_2.srcType_4;
  assign io_out_2_bits_ldest                      = out_payload_2.ldest;
  assign io_out_2_bits_fuType                     = out_payload_2.fuType;
  assign io_out_2_bits_fuOpType                   = out_payload_2.fuOpType;
  assign io_out_2_bits_rfWen                      = out_payload_2.rfWen;
  assign io_out_2_bits_fpWen                      = out_payload_2.fpWen;
  assign io_out_2_bits_vecWen                     = out_payload_2.vecWen;
  assign io_out_2_bits_v0Wen                      = out_payload_2.v0Wen;
  assign io_out_2_bits_vlWen                      = out_payload_2.vlWen;
  assign io_out_2_bits_isXSTrap                   = out_payload_2.isXSTrap;
  assign io_out_2_bits_waitForward                = out_payload_2.waitForward;
  assign io_out_2_bits_blockBackward              = out_payload_2.blockBackward;
  assign io_out_2_bits_flushPipe                  = out_payload_2.flushPipe;
  assign io_out_2_bits_canRobCompress             = out_payload_2.canRobCompress;
  assign io_out_2_bits_selImm                     = out_payload_2.selImm;
  assign io_out_2_bits_imm                        = out_payload_2.imm;
  assign io_out_2_bits_fpu_typeTagOut             = out_payload_2.fpu_typeTagOut;
  assign io_out_2_bits_fpu_wflags                 = out_payload_2.fpu_wflags;
  assign io_out_2_bits_fpu_typ                    = out_payload_2.fpu_typ;
  assign io_out_2_bits_fpu_fmt                    = out_payload_2.fpu_fmt;
  assign io_out_2_bits_fpu_rm                     = out_payload_2.fpu_rm;
  assign io_out_2_bits_vpu_vill                   = out_payload_2.vpu_vill;
  assign io_out_2_bits_vpu_vma                    = out_payload_2.vpu_vma;
  assign io_out_2_bits_vpu_vta                    = out_payload_2.vpu_vta;
  assign io_out_2_bits_vpu_vsew                   = out_payload_2.vpu_vsew;
  assign io_out_2_bits_vpu_vlmul                  = out_payload_2.vpu_vlmul;
  assign io_out_2_bits_vpu_specVill               = out_payload_2.vpu_specVill;
  assign io_out_2_bits_vpu_specVma                = out_payload_2.vpu_specVma;
  assign io_out_2_bits_vpu_specVta                = out_payload_2.vpu_specVta;
  assign io_out_2_bits_vpu_specVsew               = out_payload_2.vpu_specVsew;
  assign io_out_2_bits_vpu_specVlmul              = out_payload_2.vpu_specVlmul;
  assign io_out_2_bits_vpu_vm                     = out_payload_2.vpu_vm;
  assign io_out_2_bits_vpu_vstart                 = out_payload_2.vpu_vstart;
  assign io_out_2_bits_vpu_frm                    = out_payload_2.vpu_frm;
  assign io_out_2_bits_vpu_fpu_isFpToVecInst      = out_payload_2.vpu_fpu_isFpToVecInst;
  assign io_out_2_bits_vpu_fpu_isFP32Instr        = out_payload_2.vpu_fpu_isFP32Instr;
  assign io_out_2_bits_vpu_fpu_isFP64Instr        = out_payload_2.vpu_fpu_isFP64Instr;
  assign io_out_2_bits_vpu_fpu_isReduction        = out_payload_2.vpu_fpu_isReduction;
  assign io_out_2_bits_vpu_fpu_isFoldTo1_2        = out_payload_2.vpu_fpu_isFoldTo1_2;
  assign io_out_2_bits_vpu_fpu_isFoldTo1_4        = out_payload_2.vpu_fpu_isFoldTo1_4;
  assign io_out_2_bits_vpu_fpu_isFoldTo1_8        = out_payload_2.vpu_fpu_isFoldTo1_8;
  assign io_out_2_bits_vpu_vxrm                   = out_payload_2.vpu_vxrm;
  assign io_out_2_bits_vpu_vuopIdx                = out_payload_2.vpu_vuopIdx;
  assign io_out_2_bits_vpu_lastUop                = out_payload_2.vpu_lastUop;
  assign io_out_2_bits_vpu_vmask                  = out_payload_2.vpu_vmask;
  assign io_out_2_bits_vpu_vl                     = out_payload_2.vpu_vl;
  assign io_out_2_bits_vpu_nf                     = out_payload_2.vpu_nf;
  assign io_out_2_bits_vpu_veew                   = out_payload_2.vpu_veew;
  assign io_out_2_bits_vpu_isReverse              = out_payload_2.vpu_isReverse;
  assign io_out_2_bits_vpu_isExt                  = out_payload_2.vpu_isExt;
  assign io_out_2_bits_vpu_isNarrow               = out_payload_2.vpu_isNarrow;
  assign io_out_2_bits_vpu_isDstMask              = out_payload_2.vpu_isDstMask;
  assign io_out_2_bits_vpu_isOpMask               = out_payload_2.vpu_isOpMask;
  assign io_out_2_bits_vpu_isMove                 = out_payload_2.vpu_isMove;
  assign io_out_2_bits_vpu_isDependOldVd          = out_payload_2.vpu_isDependOldVd;
  assign io_out_2_bits_vpu_isWritePartVd          = out_payload_2.vpu_isWritePartVd;
  assign io_out_2_bits_vpu_isVleff                = out_payload_2.vpu_isVleff;
  assign io_out_2_bits_vlsInstr                   = out_payload_2.vlsInstr;
  assign io_out_2_bits_wfflags                    = out_payload_2.wfflags;
  assign io_out_2_bits_isMove                     = out_payload_2.isMove;
  assign io_out_2_bits_uopIdx                     = out_payload_2.uopIdx;
  assign io_out_2_bits_isVset                     = out_payload_2.isVset;
  assign io_out_2_bits_firstUop                   = out_payload_2.firstUop;
  assign io_out_2_bits_lastUop                    = out_payload_2.lastUop;
  assign io_out_2_bits_numUops                    = out_payload_2.numUops;
  assign io_out_2_bits_numWB                      = out_payload_2.numWB;
  assign io_out_2_bits_commitType                 = out_payload_2.commitType;
  assign io_out_2_bits_psrc_0                     = out_payload_2.psrc_0;
  assign io_out_2_bits_psrc_1                     = out_payload_2.psrc_1;
  assign io_out_2_bits_psrc_2                     = out_payload_2.psrc_2;
  assign io_out_2_bits_psrc_3                     = out_payload_2.psrc_3;
  assign io_out_2_bits_psrc_4                     = out_payload_2.psrc_4;
  assign io_out_2_bits_pdest                      = out_payload_2.pdest;
  assign io_out_2_bits_robIdx_flag                = out_payload_2.robIdx_flag;
  assign io_out_2_bits_robIdx_value               = out_payload_2.robIdx_value;
  assign io_out_2_bits_instrSize                  = out_payload_2.instrSize;
  assign io_out_2_bits_dirtyFs                    = out_payload_2.dirtyFs;
  assign io_out_2_bits_dirtyVs                    = out_payload_2.dirtyVs;
  assign io_out_2_bits_traceBlockInPipe_itype     = out_payload_2.traceBlockInPipe_itype;
  assign io_out_2_bits_traceBlockInPipe_iretire   = out_payload_2.traceBlockInPipe_iretire;
  assign io_out_2_bits_traceBlockInPipe_ilastsize = out_payload_2.traceBlockInPipe_ilastsize;
  assign io_out_2_bits_eliminatedMove             = out_payload_2.eliminatedMove;
  assign io_out_2_bits_debugInfo_renameTime       = out_payload_2.debugInfo_renameTime;
  assign io_out_2_bits_debug_seqNum_seqNum        = out_payload_2.debug_seqNum_seqNum;
  assign io_out_2_bits_debug_seqNum_uopIdx        = out_payload_2.debug_seqNum_uopIdx;
  assign io_out_2_bits_debug_fuType               = out_payload_2.debug_fuType;
  assign io_out_2_bits_debug_sim_trig             = out_payload_2.debug_sim_trig;
  assign io_out_2_bits_numLsElem                  = out_payload_2.numLsElem;

  // ---------------------------------------------------------------------------
  // lane 3：入口打包 / 出口拆包（同名逐项）
  // ---------------------------------------------------------------------------
  always_comb begin
    in_payload_3.instr                      = io_in_3_bits_instr;
    in_payload_3.pc                         = io_in_3_bits_pc;
    in_payload_3.foldpc                     = io_in_3_bits_foldpc;
    in_payload_3.exceptionVec_0             = io_in_3_bits_exceptionVec_0;
    in_payload_3.exceptionVec_1             = io_in_3_bits_exceptionVec_1;
    in_payload_3.exceptionVec_2             = io_in_3_bits_exceptionVec_2;
    in_payload_3.exceptionVec_3             = io_in_3_bits_exceptionVec_3;
    in_payload_3.exceptionVec_4             = io_in_3_bits_exceptionVec_4;
    in_payload_3.exceptionVec_5             = io_in_3_bits_exceptionVec_5;
    in_payload_3.exceptionVec_6             = io_in_3_bits_exceptionVec_6;
    in_payload_3.exceptionVec_7             = io_in_3_bits_exceptionVec_7;
    in_payload_3.exceptionVec_8             = io_in_3_bits_exceptionVec_8;
    in_payload_3.exceptionVec_9             = io_in_3_bits_exceptionVec_9;
    in_payload_3.exceptionVec_10            = io_in_3_bits_exceptionVec_10;
    in_payload_3.exceptionVec_11            = io_in_3_bits_exceptionVec_11;
    in_payload_3.exceptionVec_12            = io_in_3_bits_exceptionVec_12;
    in_payload_3.exceptionVec_13            = io_in_3_bits_exceptionVec_13;
    in_payload_3.exceptionVec_14            = io_in_3_bits_exceptionVec_14;
    in_payload_3.exceptionVec_15            = io_in_3_bits_exceptionVec_15;
    in_payload_3.exceptionVec_16            = io_in_3_bits_exceptionVec_16;
    in_payload_3.exceptionVec_17            = io_in_3_bits_exceptionVec_17;
    in_payload_3.exceptionVec_18            = io_in_3_bits_exceptionVec_18;
    in_payload_3.exceptionVec_19            = io_in_3_bits_exceptionVec_19;
    in_payload_3.exceptionVec_20            = io_in_3_bits_exceptionVec_20;
    in_payload_3.exceptionVec_21            = io_in_3_bits_exceptionVec_21;
    in_payload_3.exceptionVec_22            = io_in_3_bits_exceptionVec_22;
    in_payload_3.exceptionVec_23            = io_in_3_bits_exceptionVec_23;
    in_payload_3.isFetchMalAddr             = io_in_3_bits_isFetchMalAddr;
    in_payload_3.hasException               = io_in_3_bits_hasException;
    in_payload_3.trigger                    = io_in_3_bits_trigger;
    in_payload_3.preDecodeInfo_valid        = io_in_3_bits_preDecodeInfo_valid;
    in_payload_3.preDecodeInfo_isRVC        = io_in_3_bits_preDecodeInfo_isRVC;
    in_payload_3.preDecodeInfo_brType       = io_in_3_bits_preDecodeInfo_brType;
    in_payload_3.preDecodeInfo_isCall       = io_in_3_bits_preDecodeInfo_isCall;
    in_payload_3.preDecodeInfo_isRet        = io_in_3_bits_preDecodeInfo_isRet;
    in_payload_3.pred_taken                 = io_in_3_bits_pred_taken;
    in_payload_3.crossPageIPFFix            = io_in_3_bits_crossPageIPFFix;
    in_payload_3.ftqPtr_flag                = io_in_3_bits_ftqPtr_flag;
    in_payload_3.ftqPtr_value               = io_in_3_bits_ftqPtr_value;
    in_payload_3.ftqOffset                  = io_in_3_bits_ftqOffset;
    in_payload_3.satpFlushFirstFetchFault   = io_in_3_bits_satpFlushFirstFetchFault;
    in_payload_3.srcType_0                  = io_in_3_bits_srcType_0;
    in_payload_3.srcType_1                  = io_in_3_bits_srcType_1;
    in_payload_3.srcType_2                  = io_in_3_bits_srcType_2;
    in_payload_3.srcType_3                  = io_in_3_bits_srcType_3;
    in_payload_3.srcType_4                  = io_in_3_bits_srcType_4;
    in_payload_3.ldest                      = io_in_3_bits_ldest;
    in_payload_3.fuType                     = io_in_3_bits_fuType;
    in_payload_3.fuOpType                   = io_in_3_bits_fuOpType;
    in_payload_3.rfWen                      = io_in_3_bits_rfWen;
    in_payload_3.fpWen                      = io_in_3_bits_fpWen;
    in_payload_3.vecWen                     = io_in_3_bits_vecWen;
    in_payload_3.v0Wen                      = io_in_3_bits_v0Wen;
    in_payload_3.vlWen                      = io_in_3_bits_vlWen;
    in_payload_3.isXSTrap                   = io_in_3_bits_isXSTrap;
    in_payload_3.waitForward                = io_in_3_bits_waitForward;
    in_payload_3.blockBackward              = io_in_3_bits_blockBackward;
    in_payload_3.flushPipe                  = io_in_3_bits_flushPipe;
    in_payload_3.canRobCompress             = io_in_3_bits_canRobCompress;
    in_payload_3.selImm                     = io_in_3_bits_selImm;
    in_payload_3.imm                        = io_in_3_bits_imm;
    in_payload_3.fpu_typeTagOut             = io_in_3_bits_fpu_typeTagOut;
    in_payload_3.fpu_wflags                 = io_in_3_bits_fpu_wflags;
    in_payload_3.fpu_typ                    = io_in_3_bits_fpu_typ;
    in_payload_3.fpu_fmt                    = io_in_3_bits_fpu_fmt;
    in_payload_3.fpu_rm                     = io_in_3_bits_fpu_rm;
    in_payload_3.vpu_vill                   = io_in_3_bits_vpu_vill;
    in_payload_3.vpu_vma                    = io_in_3_bits_vpu_vma;
    in_payload_3.vpu_vta                    = io_in_3_bits_vpu_vta;
    in_payload_3.vpu_vsew                   = io_in_3_bits_vpu_vsew;
    in_payload_3.vpu_vlmul                  = io_in_3_bits_vpu_vlmul;
    in_payload_3.vpu_specVill               = io_in_3_bits_vpu_specVill;
    in_payload_3.vpu_specVma                = io_in_3_bits_vpu_specVma;
    in_payload_3.vpu_specVta                = io_in_3_bits_vpu_specVta;
    in_payload_3.vpu_specVsew               = io_in_3_bits_vpu_specVsew;
    in_payload_3.vpu_specVlmul              = io_in_3_bits_vpu_specVlmul;
    in_payload_3.vpu_vm                     = io_in_3_bits_vpu_vm;
    in_payload_3.vpu_vstart                 = io_in_3_bits_vpu_vstart;
    in_payload_3.vpu_frm                    = io_in_3_bits_vpu_frm;
    in_payload_3.vpu_fpu_isFpToVecInst      = io_in_3_bits_vpu_fpu_isFpToVecInst;
    in_payload_3.vpu_fpu_isFP32Instr        = io_in_3_bits_vpu_fpu_isFP32Instr;
    in_payload_3.vpu_fpu_isFP64Instr        = io_in_3_bits_vpu_fpu_isFP64Instr;
    in_payload_3.vpu_fpu_isReduction        = io_in_3_bits_vpu_fpu_isReduction;
    in_payload_3.vpu_fpu_isFoldTo1_2        = io_in_3_bits_vpu_fpu_isFoldTo1_2;
    in_payload_3.vpu_fpu_isFoldTo1_4        = io_in_3_bits_vpu_fpu_isFoldTo1_4;
    in_payload_3.vpu_fpu_isFoldTo1_8        = io_in_3_bits_vpu_fpu_isFoldTo1_8;
    in_payload_3.vpu_vxrm                   = io_in_3_bits_vpu_vxrm;
    in_payload_3.vpu_vuopIdx                = io_in_3_bits_vpu_vuopIdx;
    in_payload_3.vpu_lastUop                = io_in_3_bits_vpu_lastUop;
    in_payload_3.vpu_vmask                  = io_in_3_bits_vpu_vmask;
    in_payload_3.vpu_vl                     = io_in_3_bits_vpu_vl;
    in_payload_3.vpu_nf                     = io_in_3_bits_vpu_nf;
    in_payload_3.vpu_veew                   = io_in_3_bits_vpu_veew;
    in_payload_3.vpu_isReverse              = io_in_3_bits_vpu_isReverse;
    in_payload_3.vpu_isExt                  = io_in_3_bits_vpu_isExt;
    in_payload_3.vpu_isNarrow               = io_in_3_bits_vpu_isNarrow;
    in_payload_3.vpu_isDstMask              = io_in_3_bits_vpu_isDstMask;
    in_payload_3.vpu_isOpMask               = io_in_3_bits_vpu_isOpMask;
    in_payload_3.vpu_isMove                 = io_in_3_bits_vpu_isMove;
    in_payload_3.vpu_isDependOldVd          = io_in_3_bits_vpu_isDependOldVd;
    in_payload_3.vpu_isWritePartVd          = io_in_3_bits_vpu_isWritePartVd;
    in_payload_3.vpu_isVleff                = io_in_3_bits_vpu_isVleff;
    in_payload_3.vlsInstr                   = io_in_3_bits_vlsInstr;
    in_payload_3.wfflags                    = io_in_3_bits_wfflags;
    in_payload_3.isMove                     = io_in_3_bits_isMove;
    in_payload_3.uopIdx                     = io_in_3_bits_uopIdx;
    in_payload_3.isVset                     = io_in_3_bits_isVset;
    in_payload_3.firstUop                   = io_in_3_bits_firstUop;
    in_payload_3.lastUop                    = io_in_3_bits_lastUop;
    in_payload_3.numUops                    = io_in_3_bits_numUops;
    in_payload_3.numWB                      = io_in_3_bits_numWB;
    in_payload_3.commitType                 = io_in_3_bits_commitType;
    in_payload_3.psrc_0                     = io_in_3_bits_psrc_0;
    in_payload_3.psrc_1                     = io_in_3_bits_psrc_1;
    in_payload_3.psrc_2                     = io_in_3_bits_psrc_2;
    in_payload_3.psrc_3                     = io_in_3_bits_psrc_3;
    in_payload_3.psrc_4                     = io_in_3_bits_psrc_4;
    in_payload_3.pdest                      = io_in_3_bits_pdest;
    in_payload_3.robIdx_flag                = io_in_3_bits_robIdx_flag;
    in_payload_3.robIdx_value               = io_in_3_bits_robIdx_value;
    in_payload_3.instrSize                  = io_in_3_bits_instrSize;
    in_payload_3.dirtyFs                    = io_in_3_bits_dirtyFs;
    in_payload_3.dirtyVs                    = io_in_3_bits_dirtyVs;
    in_payload_3.traceBlockInPipe_itype     = io_in_3_bits_traceBlockInPipe_itype;
    in_payload_3.traceBlockInPipe_iretire   = io_in_3_bits_traceBlockInPipe_iretire;
    in_payload_3.traceBlockInPipe_ilastsize = io_in_3_bits_traceBlockInPipe_ilastsize;
    in_payload_3.eliminatedMove             = io_in_3_bits_eliminatedMove;
    in_payload_3.debugInfo_renameTime       = io_in_3_bits_debugInfo_renameTime;
    in_payload_3.debug_seqNum_seqNum        = io_in_3_bits_debug_seqNum_seqNum;
    in_payload_3.debug_seqNum_uopIdx        = io_in_3_bits_debug_seqNum_uopIdx;
    in_payload_3.debug_fuType               = io_in_3_bits_debug_fuType;
    in_payload_3.debug_sim_trig             = io_in_3_bits_debug_sim_trig;
    in_payload_3.numLsElem                  = io_in_3_bits_numLsElem;
  end
  assign io_out_3_bits_instr                      = out_payload_3.instr;
  assign io_out_3_bits_pc                         = out_payload_3.pc;
  assign io_out_3_bits_foldpc                     = out_payload_3.foldpc;
  assign io_out_3_bits_exceptionVec_0             = out_payload_3.exceptionVec_0;
  assign io_out_3_bits_exceptionVec_1             = out_payload_3.exceptionVec_1;
  assign io_out_3_bits_exceptionVec_2             = out_payload_3.exceptionVec_2;
  assign io_out_3_bits_exceptionVec_3             = out_payload_3.exceptionVec_3;
  assign io_out_3_bits_exceptionVec_4             = out_payload_3.exceptionVec_4;
  assign io_out_3_bits_exceptionVec_5             = out_payload_3.exceptionVec_5;
  assign io_out_3_bits_exceptionVec_6             = out_payload_3.exceptionVec_6;
  assign io_out_3_bits_exceptionVec_7             = out_payload_3.exceptionVec_7;
  assign io_out_3_bits_exceptionVec_8             = out_payload_3.exceptionVec_8;
  assign io_out_3_bits_exceptionVec_9             = out_payload_3.exceptionVec_9;
  assign io_out_3_bits_exceptionVec_10            = out_payload_3.exceptionVec_10;
  assign io_out_3_bits_exceptionVec_11            = out_payload_3.exceptionVec_11;
  assign io_out_3_bits_exceptionVec_12            = out_payload_3.exceptionVec_12;
  assign io_out_3_bits_exceptionVec_13            = out_payload_3.exceptionVec_13;
  assign io_out_3_bits_exceptionVec_14            = out_payload_3.exceptionVec_14;
  assign io_out_3_bits_exceptionVec_15            = out_payload_3.exceptionVec_15;
  assign io_out_3_bits_exceptionVec_16            = out_payload_3.exceptionVec_16;
  assign io_out_3_bits_exceptionVec_17            = out_payload_3.exceptionVec_17;
  assign io_out_3_bits_exceptionVec_18            = out_payload_3.exceptionVec_18;
  assign io_out_3_bits_exceptionVec_19            = out_payload_3.exceptionVec_19;
  assign io_out_3_bits_exceptionVec_20            = out_payload_3.exceptionVec_20;
  assign io_out_3_bits_exceptionVec_21            = out_payload_3.exceptionVec_21;
  assign io_out_3_bits_exceptionVec_22            = out_payload_3.exceptionVec_22;
  assign io_out_3_bits_exceptionVec_23            = out_payload_3.exceptionVec_23;
  assign io_out_3_bits_isFetchMalAddr             = out_payload_3.isFetchMalAddr;
  assign io_out_3_bits_hasException               = out_payload_3.hasException;
  assign io_out_3_bits_trigger                    = out_payload_3.trigger;
  assign io_out_3_bits_preDecodeInfo_valid        = out_payload_3.preDecodeInfo_valid;
  assign io_out_3_bits_preDecodeInfo_isRVC        = out_payload_3.preDecodeInfo_isRVC;
  assign io_out_3_bits_preDecodeInfo_brType       = out_payload_3.preDecodeInfo_brType;
  assign io_out_3_bits_preDecodeInfo_isCall       = out_payload_3.preDecodeInfo_isCall;
  assign io_out_3_bits_preDecodeInfo_isRet        = out_payload_3.preDecodeInfo_isRet;
  assign io_out_3_bits_pred_taken                 = out_payload_3.pred_taken;
  assign io_out_3_bits_crossPageIPFFix            = out_payload_3.crossPageIPFFix;
  assign io_out_3_bits_ftqPtr_flag                = out_payload_3.ftqPtr_flag;
  assign io_out_3_bits_ftqPtr_value               = out_payload_3.ftqPtr_value;
  assign io_out_3_bits_ftqOffset                  = out_payload_3.ftqOffset;
  assign io_out_3_bits_satpFlushFirstFetchFault   = out_payload_3.satpFlushFirstFetchFault;
  assign io_out_3_bits_srcType_0                  = out_payload_3.srcType_0;
  assign io_out_3_bits_srcType_1                  = out_payload_3.srcType_1;
  assign io_out_3_bits_srcType_2                  = out_payload_3.srcType_2;
  assign io_out_3_bits_srcType_3                  = out_payload_3.srcType_3;
  assign io_out_3_bits_srcType_4                  = out_payload_3.srcType_4;
  assign io_out_3_bits_ldest                      = out_payload_3.ldest;
  assign io_out_3_bits_fuType                     = out_payload_3.fuType;
  assign io_out_3_bits_fuOpType                   = out_payload_3.fuOpType;
  assign io_out_3_bits_rfWen                      = out_payload_3.rfWen;
  assign io_out_3_bits_fpWen                      = out_payload_3.fpWen;
  assign io_out_3_bits_vecWen                     = out_payload_3.vecWen;
  assign io_out_3_bits_v0Wen                      = out_payload_3.v0Wen;
  assign io_out_3_bits_vlWen                      = out_payload_3.vlWen;
  assign io_out_3_bits_isXSTrap                   = out_payload_3.isXSTrap;
  assign io_out_3_bits_waitForward                = out_payload_3.waitForward;
  assign io_out_3_bits_blockBackward              = out_payload_3.blockBackward;
  assign io_out_3_bits_flushPipe                  = out_payload_3.flushPipe;
  assign io_out_3_bits_canRobCompress             = out_payload_3.canRobCompress;
  assign io_out_3_bits_selImm                     = out_payload_3.selImm;
  assign io_out_3_bits_imm                        = out_payload_3.imm;
  assign io_out_3_bits_fpu_typeTagOut             = out_payload_3.fpu_typeTagOut;
  assign io_out_3_bits_fpu_wflags                 = out_payload_3.fpu_wflags;
  assign io_out_3_bits_fpu_typ                    = out_payload_3.fpu_typ;
  assign io_out_3_bits_fpu_fmt                    = out_payload_3.fpu_fmt;
  assign io_out_3_bits_fpu_rm                     = out_payload_3.fpu_rm;
  assign io_out_3_bits_vpu_vill                   = out_payload_3.vpu_vill;
  assign io_out_3_bits_vpu_vma                    = out_payload_3.vpu_vma;
  assign io_out_3_bits_vpu_vta                    = out_payload_3.vpu_vta;
  assign io_out_3_bits_vpu_vsew                   = out_payload_3.vpu_vsew;
  assign io_out_3_bits_vpu_vlmul                  = out_payload_3.vpu_vlmul;
  assign io_out_3_bits_vpu_specVill               = out_payload_3.vpu_specVill;
  assign io_out_3_bits_vpu_specVma                = out_payload_3.vpu_specVma;
  assign io_out_3_bits_vpu_specVta                = out_payload_3.vpu_specVta;
  assign io_out_3_bits_vpu_specVsew               = out_payload_3.vpu_specVsew;
  assign io_out_3_bits_vpu_specVlmul              = out_payload_3.vpu_specVlmul;
  assign io_out_3_bits_vpu_vm                     = out_payload_3.vpu_vm;
  assign io_out_3_bits_vpu_vstart                 = out_payload_3.vpu_vstart;
  assign io_out_3_bits_vpu_frm                    = out_payload_3.vpu_frm;
  assign io_out_3_bits_vpu_fpu_isFpToVecInst      = out_payload_3.vpu_fpu_isFpToVecInst;
  assign io_out_3_bits_vpu_fpu_isFP32Instr        = out_payload_3.vpu_fpu_isFP32Instr;
  assign io_out_3_bits_vpu_fpu_isFP64Instr        = out_payload_3.vpu_fpu_isFP64Instr;
  assign io_out_3_bits_vpu_fpu_isReduction        = out_payload_3.vpu_fpu_isReduction;
  assign io_out_3_bits_vpu_fpu_isFoldTo1_2        = out_payload_3.vpu_fpu_isFoldTo1_2;
  assign io_out_3_bits_vpu_fpu_isFoldTo1_4        = out_payload_3.vpu_fpu_isFoldTo1_4;
  assign io_out_3_bits_vpu_fpu_isFoldTo1_8        = out_payload_3.vpu_fpu_isFoldTo1_8;
  assign io_out_3_bits_vpu_vxrm                   = out_payload_3.vpu_vxrm;
  assign io_out_3_bits_vpu_vuopIdx                = out_payload_3.vpu_vuopIdx;
  assign io_out_3_bits_vpu_lastUop                = out_payload_3.vpu_lastUop;
  assign io_out_3_bits_vpu_vmask                  = out_payload_3.vpu_vmask;
  assign io_out_3_bits_vpu_vl                     = out_payload_3.vpu_vl;
  assign io_out_3_bits_vpu_nf                     = out_payload_3.vpu_nf;
  assign io_out_3_bits_vpu_veew                   = out_payload_3.vpu_veew;
  assign io_out_3_bits_vpu_isReverse              = out_payload_3.vpu_isReverse;
  assign io_out_3_bits_vpu_isExt                  = out_payload_3.vpu_isExt;
  assign io_out_3_bits_vpu_isNarrow               = out_payload_3.vpu_isNarrow;
  assign io_out_3_bits_vpu_isDstMask              = out_payload_3.vpu_isDstMask;
  assign io_out_3_bits_vpu_isOpMask               = out_payload_3.vpu_isOpMask;
  assign io_out_3_bits_vpu_isMove                 = out_payload_3.vpu_isMove;
  assign io_out_3_bits_vpu_isDependOldVd          = out_payload_3.vpu_isDependOldVd;
  assign io_out_3_bits_vpu_isWritePartVd          = out_payload_3.vpu_isWritePartVd;
  assign io_out_3_bits_vpu_isVleff                = out_payload_3.vpu_isVleff;
  assign io_out_3_bits_vlsInstr                   = out_payload_3.vlsInstr;
  assign io_out_3_bits_wfflags                    = out_payload_3.wfflags;
  assign io_out_3_bits_isMove                     = out_payload_3.isMove;
  assign io_out_3_bits_uopIdx                     = out_payload_3.uopIdx;
  assign io_out_3_bits_isVset                     = out_payload_3.isVset;
  assign io_out_3_bits_firstUop                   = out_payload_3.firstUop;
  assign io_out_3_bits_lastUop                    = out_payload_3.lastUop;
  assign io_out_3_bits_numUops                    = out_payload_3.numUops;
  assign io_out_3_bits_numWB                      = out_payload_3.numWB;
  assign io_out_3_bits_commitType                 = out_payload_3.commitType;
  assign io_out_3_bits_psrc_0                     = out_payload_3.psrc_0;
  assign io_out_3_bits_psrc_1                     = out_payload_3.psrc_1;
  assign io_out_3_bits_psrc_2                     = out_payload_3.psrc_2;
  assign io_out_3_bits_psrc_3                     = out_payload_3.psrc_3;
  assign io_out_3_bits_psrc_4                     = out_payload_3.psrc_4;
  assign io_out_3_bits_pdest                      = out_payload_3.pdest;
  assign io_out_3_bits_robIdx_flag                = out_payload_3.robIdx_flag;
  assign io_out_3_bits_robIdx_value               = out_payload_3.robIdx_value;
  assign io_out_3_bits_instrSize                  = out_payload_3.instrSize;
  assign io_out_3_bits_dirtyFs                    = out_payload_3.dirtyFs;
  assign io_out_3_bits_dirtyVs                    = out_payload_3.dirtyVs;
  assign io_out_3_bits_traceBlockInPipe_itype     = out_payload_3.traceBlockInPipe_itype;
  assign io_out_3_bits_traceBlockInPipe_iretire   = out_payload_3.traceBlockInPipe_iretire;
  assign io_out_3_bits_traceBlockInPipe_ilastsize = out_payload_3.traceBlockInPipe_ilastsize;
  assign io_out_3_bits_eliminatedMove             = out_payload_3.eliminatedMove;
  assign io_out_3_bits_debugInfo_renameTime       = out_payload_3.debugInfo_renameTime;
  assign io_out_3_bits_debug_seqNum_seqNum        = out_payload_3.debug_seqNum_seqNum;
  assign io_out_3_bits_debug_seqNum_uopIdx        = out_payload_3.debug_seqNum_uopIdx;
  assign io_out_3_bits_debug_fuType               = out_payload_3.debug_fuType;
  assign io_out_3_bits_debug_sim_trig             = out_payload_3.debug_sim_trig;
  assign io_out_3_bits_numLsElem                  = out_payload_3.numLsElem;

  // ---------------------------------------------------------------------------
  // lane 4：入口打包 / 出口拆包（同名逐项）
  // ---------------------------------------------------------------------------
  always_comb begin
    in_payload_4.instr                      = io_in_4_bits_instr;
    in_payload_4.pc                         = io_in_4_bits_pc;
    in_payload_4.foldpc                     = io_in_4_bits_foldpc;
    in_payload_4.exceptionVec_0             = io_in_4_bits_exceptionVec_0;
    in_payload_4.exceptionVec_1             = io_in_4_bits_exceptionVec_1;
    in_payload_4.exceptionVec_2             = io_in_4_bits_exceptionVec_2;
    in_payload_4.exceptionVec_3             = io_in_4_bits_exceptionVec_3;
    in_payload_4.exceptionVec_4             = io_in_4_bits_exceptionVec_4;
    in_payload_4.exceptionVec_5             = io_in_4_bits_exceptionVec_5;
    in_payload_4.exceptionVec_6             = io_in_4_bits_exceptionVec_6;
    in_payload_4.exceptionVec_7             = io_in_4_bits_exceptionVec_7;
    in_payload_4.exceptionVec_8             = io_in_4_bits_exceptionVec_8;
    in_payload_4.exceptionVec_9             = io_in_4_bits_exceptionVec_9;
    in_payload_4.exceptionVec_10            = io_in_4_bits_exceptionVec_10;
    in_payload_4.exceptionVec_11            = io_in_4_bits_exceptionVec_11;
    in_payload_4.exceptionVec_12            = io_in_4_bits_exceptionVec_12;
    in_payload_4.exceptionVec_13            = io_in_4_bits_exceptionVec_13;
    in_payload_4.exceptionVec_14            = io_in_4_bits_exceptionVec_14;
    in_payload_4.exceptionVec_15            = io_in_4_bits_exceptionVec_15;
    in_payload_4.exceptionVec_16            = io_in_4_bits_exceptionVec_16;
    in_payload_4.exceptionVec_17            = io_in_4_bits_exceptionVec_17;
    in_payload_4.exceptionVec_18            = io_in_4_bits_exceptionVec_18;
    in_payload_4.exceptionVec_19            = io_in_4_bits_exceptionVec_19;
    in_payload_4.exceptionVec_20            = io_in_4_bits_exceptionVec_20;
    in_payload_4.exceptionVec_21            = io_in_4_bits_exceptionVec_21;
    in_payload_4.exceptionVec_22            = io_in_4_bits_exceptionVec_22;
    in_payload_4.exceptionVec_23            = io_in_4_bits_exceptionVec_23;
    in_payload_4.isFetchMalAddr             = io_in_4_bits_isFetchMalAddr;
    in_payload_4.hasException               = io_in_4_bits_hasException;
    in_payload_4.trigger                    = io_in_4_bits_trigger;
    in_payload_4.preDecodeInfo_valid        = io_in_4_bits_preDecodeInfo_valid;
    in_payload_4.preDecodeInfo_isRVC        = io_in_4_bits_preDecodeInfo_isRVC;
    in_payload_4.preDecodeInfo_brType       = io_in_4_bits_preDecodeInfo_brType;
    in_payload_4.preDecodeInfo_isCall       = io_in_4_bits_preDecodeInfo_isCall;
    in_payload_4.preDecodeInfo_isRet        = io_in_4_bits_preDecodeInfo_isRet;
    in_payload_4.pred_taken                 = io_in_4_bits_pred_taken;
    in_payload_4.crossPageIPFFix            = io_in_4_bits_crossPageIPFFix;
    in_payload_4.ftqPtr_flag                = io_in_4_bits_ftqPtr_flag;
    in_payload_4.ftqPtr_value               = io_in_4_bits_ftqPtr_value;
    in_payload_4.ftqOffset                  = io_in_4_bits_ftqOffset;
    in_payload_4.satpFlushFirstFetchFault   = io_in_4_bits_satpFlushFirstFetchFault;
    in_payload_4.srcType_0                  = io_in_4_bits_srcType_0;
    in_payload_4.srcType_1                  = io_in_4_bits_srcType_1;
    in_payload_4.srcType_2                  = io_in_4_bits_srcType_2;
    in_payload_4.srcType_3                  = io_in_4_bits_srcType_3;
    in_payload_4.srcType_4                  = io_in_4_bits_srcType_4;
    in_payload_4.ldest                      = io_in_4_bits_ldest;
    in_payload_4.fuType                     = io_in_4_bits_fuType;
    in_payload_4.fuOpType                   = io_in_4_bits_fuOpType;
    in_payload_4.rfWen                      = io_in_4_bits_rfWen;
    in_payload_4.fpWen                      = io_in_4_bits_fpWen;
    in_payload_4.vecWen                     = io_in_4_bits_vecWen;
    in_payload_4.v0Wen                      = io_in_4_bits_v0Wen;
    in_payload_4.vlWen                      = io_in_4_bits_vlWen;
    in_payload_4.isXSTrap                   = io_in_4_bits_isXSTrap;
    in_payload_4.waitForward                = io_in_4_bits_waitForward;
    in_payload_4.blockBackward              = io_in_4_bits_blockBackward;
    in_payload_4.flushPipe                  = io_in_4_bits_flushPipe;
    in_payload_4.canRobCompress             = io_in_4_bits_canRobCompress;
    in_payload_4.selImm                     = io_in_4_bits_selImm;
    in_payload_4.imm                        = io_in_4_bits_imm;
    in_payload_4.fpu_typeTagOut             = io_in_4_bits_fpu_typeTagOut;
    in_payload_4.fpu_wflags                 = io_in_4_bits_fpu_wflags;
    in_payload_4.fpu_typ                    = io_in_4_bits_fpu_typ;
    in_payload_4.fpu_fmt                    = io_in_4_bits_fpu_fmt;
    in_payload_4.fpu_rm                     = io_in_4_bits_fpu_rm;
    in_payload_4.vpu_vill                   = io_in_4_bits_vpu_vill;
    in_payload_4.vpu_vma                    = io_in_4_bits_vpu_vma;
    in_payload_4.vpu_vta                    = io_in_4_bits_vpu_vta;
    in_payload_4.vpu_vsew                   = io_in_4_bits_vpu_vsew;
    in_payload_4.vpu_vlmul                  = io_in_4_bits_vpu_vlmul;
    in_payload_4.vpu_specVill               = io_in_4_bits_vpu_specVill;
    in_payload_4.vpu_specVma                = io_in_4_bits_vpu_specVma;
    in_payload_4.vpu_specVta                = io_in_4_bits_vpu_specVta;
    in_payload_4.vpu_specVsew               = io_in_4_bits_vpu_specVsew;
    in_payload_4.vpu_specVlmul              = io_in_4_bits_vpu_specVlmul;
    in_payload_4.vpu_vm                     = io_in_4_bits_vpu_vm;
    in_payload_4.vpu_vstart                 = io_in_4_bits_vpu_vstart;
    in_payload_4.vpu_frm                    = io_in_4_bits_vpu_frm;
    in_payload_4.vpu_fpu_isFpToVecInst      = io_in_4_bits_vpu_fpu_isFpToVecInst;
    in_payload_4.vpu_fpu_isFP32Instr        = io_in_4_bits_vpu_fpu_isFP32Instr;
    in_payload_4.vpu_fpu_isFP64Instr        = io_in_4_bits_vpu_fpu_isFP64Instr;
    in_payload_4.vpu_fpu_isReduction        = io_in_4_bits_vpu_fpu_isReduction;
    in_payload_4.vpu_fpu_isFoldTo1_2        = io_in_4_bits_vpu_fpu_isFoldTo1_2;
    in_payload_4.vpu_fpu_isFoldTo1_4        = io_in_4_bits_vpu_fpu_isFoldTo1_4;
    in_payload_4.vpu_fpu_isFoldTo1_8        = io_in_4_bits_vpu_fpu_isFoldTo1_8;
    in_payload_4.vpu_vxrm                   = io_in_4_bits_vpu_vxrm;
    in_payload_4.vpu_vuopIdx                = io_in_4_bits_vpu_vuopIdx;
    in_payload_4.vpu_lastUop                = io_in_4_bits_vpu_lastUop;
    in_payload_4.vpu_vmask                  = io_in_4_bits_vpu_vmask;
    in_payload_4.vpu_vl                     = io_in_4_bits_vpu_vl;
    in_payload_4.vpu_nf                     = io_in_4_bits_vpu_nf;
    in_payload_4.vpu_veew                   = io_in_4_bits_vpu_veew;
    in_payload_4.vpu_isReverse              = io_in_4_bits_vpu_isReverse;
    in_payload_4.vpu_isExt                  = io_in_4_bits_vpu_isExt;
    in_payload_4.vpu_isNarrow               = io_in_4_bits_vpu_isNarrow;
    in_payload_4.vpu_isDstMask              = io_in_4_bits_vpu_isDstMask;
    in_payload_4.vpu_isOpMask               = io_in_4_bits_vpu_isOpMask;
    in_payload_4.vpu_isMove                 = io_in_4_bits_vpu_isMove;
    in_payload_4.vpu_isDependOldVd          = io_in_4_bits_vpu_isDependOldVd;
    in_payload_4.vpu_isWritePartVd          = io_in_4_bits_vpu_isWritePartVd;
    in_payload_4.vpu_isVleff                = io_in_4_bits_vpu_isVleff;
    in_payload_4.vlsInstr                   = io_in_4_bits_vlsInstr;
    in_payload_4.wfflags                    = io_in_4_bits_wfflags;
    in_payload_4.isMove                     = io_in_4_bits_isMove;
    in_payload_4.uopIdx                     = io_in_4_bits_uopIdx;
    in_payload_4.isVset                     = io_in_4_bits_isVset;
    in_payload_4.firstUop                   = io_in_4_bits_firstUop;
    in_payload_4.lastUop                    = io_in_4_bits_lastUop;
    in_payload_4.numUops                    = io_in_4_bits_numUops;
    in_payload_4.numWB                      = io_in_4_bits_numWB;
    in_payload_4.commitType                 = io_in_4_bits_commitType;
    in_payload_4.psrc_0                     = io_in_4_bits_psrc_0;
    in_payload_4.psrc_1                     = io_in_4_bits_psrc_1;
    in_payload_4.psrc_2                     = io_in_4_bits_psrc_2;
    in_payload_4.psrc_3                     = io_in_4_bits_psrc_3;
    in_payload_4.psrc_4                     = io_in_4_bits_psrc_4;
    in_payload_4.pdest                      = io_in_4_bits_pdest;
    in_payload_4.robIdx_flag                = io_in_4_bits_robIdx_flag;
    in_payload_4.robIdx_value               = io_in_4_bits_robIdx_value;
    in_payload_4.instrSize                  = io_in_4_bits_instrSize;
    in_payload_4.dirtyFs                    = io_in_4_bits_dirtyFs;
    in_payload_4.dirtyVs                    = io_in_4_bits_dirtyVs;
    in_payload_4.traceBlockInPipe_itype     = io_in_4_bits_traceBlockInPipe_itype;
    in_payload_4.traceBlockInPipe_iretire   = io_in_4_bits_traceBlockInPipe_iretire;
    in_payload_4.traceBlockInPipe_ilastsize = io_in_4_bits_traceBlockInPipe_ilastsize;
    in_payload_4.eliminatedMove             = io_in_4_bits_eliminatedMove;
    in_payload_4.debugInfo_renameTime       = io_in_4_bits_debugInfo_renameTime;
    in_payload_4.debug_seqNum_seqNum        = io_in_4_bits_debug_seqNum_seqNum;
    in_payload_4.debug_seqNum_uopIdx        = io_in_4_bits_debug_seqNum_uopIdx;
    in_payload_4.debug_fuType               = io_in_4_bits_debug_fuType;
    in_payload_4.debug_sim_trig             = io_in_4_bits_debug_sim_trig;
    in_payload_4.numLsElem                  = io_in_4_bits_numLsElem;
  end
  assign io_out_4_bits_instr                      = out_payload_4.instr;
  assign io_out_4_bits_pc                         = out_payload_4.pc;
  assign io_out_4_bits_foldpc                     = out_payload_4.foldpc;
  assign io_out_4_bits_exceptionVec_0             = out_payload_4.exceptionVec_0;
  assign io_out_4_bits_exceptionVec_1             = out_payload_4.exceptionVec_1;
  assign io_out_4_bits_exceptionVec_2             = out_payload_4.exceptionVec_2;
  assign io_out_4_bits_exceptionVec_3             = out_payload_4.exceptionVec_3;
  assign io_out_4_bits_exceptionVec_4             = out_payload_4.exceptionVec_4;
  assign io_out_4_bits_exceptionVec_5             = out_payload_4.exceptionVec_5;
  assign io_out_4_bits_exceptionVec_6             = out_payload_4.exceptionVec_6;
  assign io_out_4_bits_exceptionVec_7             = out_payload_4.exceptionVec_7;
  assign io_out_4_bits_exceptionVec_8             = out_payload_4.exceptionVec_8;
  assign io_out_4_bits_exceptionVec_9             = out_payload_4.exceptionVec_9;
  assign io_out_4_bits_exceptionVec_10            = out_payload_4.exceptionVec_10;
  assign io_out_4_bits_exceptionVec_11            = out_payload_4.exceptionVec_11;
  assign io_out_4_bits_exceptionVec_12            = out_payload_4.exceptionVec_12;
  assign io_out_4_bits_exceptionVec_13            = out_payload_4.exceptionVec_13;
  assign io_out_4_bits_exceptionVec_14            = out_payload_4.exceptionVec_14;
  assign io_out_4_bits_exceptionVec_15            = out_payload_4.exceptionVec_15;
  assign io_out_4_bits_exceptionVec_16            = out_payload_4.exceptionVec_16;
  assign io_out_4_bits_exceptionVec_17            = out_payload_4.exceptionVec_17;
  assign io_out_4_bits_exceptionVec_18            = out_payload_4.exceptionVec_18;
  assign io_out_4_bits_exceptionVec_19            = out_payload_4.exceptionVec_19;
  assign io_out_4_bits_exceptionVec_20            = out_payload_4.exceptionVec_20;
  assign io_out_4_bits_exceptionVec_21            = out_payload_4.exceptionVec_21;
  assign io_out_4_bits_exceptionVec_22            = out_payload_4.exceptionVec_22;
  assign io_out_4_bits_exceptionVec_23            = out_payload_4.exceptionVec_23;
  assign io_out_4_bits_isFetchMalAddr             = out_payload_4.isFetchMalAddr;
  assign io_out_4_bits_hasException               = out_payload_4.hasException;
  assign io_out_4_bits_trigger                    = out_payload_4.trigger;
  assign io_out_4_bits_preDecodeInfo_valid        = out_payload_4.preDecodeInfo_valid;
  assign io_out_4_bits_preDecodeInfo_isRVC        = out_payload_4.preDecodeInfo_isRVC;
  assign io_out_4_bits_preDecodeInfo_brType       = out_payload_4.preDecodeInfo_brType;
  assign io_out_4_bits_preDecodeInfo_isCall       = out_payload_4.preDecodeInfo_isCall;
  assign io_out_4_bits_preDecodeInfo_isRet        = out_payload_4.preDecodeInfo_isRet;
  assign io_out_4_bits_pred_taken                 = out_payload_4.pred_taken;
  assign io_out_4_bits_crossPageIPFFix            = out_payload_4.crossPageIPFFix;
  assign io_out_4_bits_ftqPtr_flag                = out_payload_4.ftqPtr_flag;
  assign io_out_4_bits_ftqPtr_value               = out_payload_4.ftqPtr_value;
  assign io_out_4_bits_ftqOffset                  = out_payload_4.ftqOffset;
  assign io_out_4_bits_satpFlushFirstFetchFault   = out_payload_4.satpFlushFirstFetchFault;
  assign io_out_4_bits_srcType_0                  = out_payload_4.srcType_0;
  assign io_out_4_bits_srcType_1                  = out_payload_4.srcType_1;
  assign io_out_4_bits_srcType_2                  = out_payload_4.srcType_2;
  assign io_out_4_bits_srcType_3                  = out_payload_4.srcType_3;
  assign io_out_4_bits_srcType_4                  = out_payload_4.srcType_4;
  assign io_out_4_bits_ldest                      = out_payload_4.ldest;
  assign io_out_4_bits_fuType                     = out_payload_4.fuType;
  assign io_out_4_bits_fuOpType                   = out_payload_4.fuOpType;
  assign io_out_4_bits_rfWen                      = out_payload_4.rfWen;
  assign io_out_4_bits_fpWen                      = out_payload_4.fpWen;
  assign io_out_4_bits_vecWen                     = out_payload_4.vecWen;
  assign io_out_4_bits_v0Wen                      = out_payload_4.v0Wen;
  assign io_out_4_bits_vlWen                      = out_payload_4.vlWen;
  assign io_out_4_bits_isXSTrap                   = out_payload_4.isXSTrap;
  assign io_out_4_bits_waitForward                = out_payload_4.waitForward;
  assign io_out_4_bits_blockBackward              = out_payload_4.blockBackward;
  assign io_out_4_bits_flushPipe                  = out_payload_4.flushPipe;
  assign io_out_4_bits_canRobCompress             = out_payload_4.canRobCompress;
  assign io_out_4_bits_selImm                     = out_payload_4.selImm;
  assign io_out_4_bits_imm                        = out_payload_4.imm;
  assign io_out_4_bits_fpu_typeTagOut             = out_payload_4.fpu_typeTagOut;
  assign io_out_4_bits_fpu_wflags                 = out_payload_4.fpu_wflags;
  assign io_out_4_bits_fpu_typ                    = out_payload_4.fpu_typ;
  assign io_out_4_bits_fpu_fmt                    = out_payload_4.fpu_fmt;
  assign io_out_4_bits_fpu_rm                     = out_payload_4.fpu_rm;
  assign io_out_4_bits_vpu_vill                   = out_payload_4.vpu_vill;
  assign io_out_4_bits_vpu_vma                    = out_payload_4.vpu_vma;
  assign io_out_4_bits_vpu_vta                    = out_payload_4.vpu_vta;
  assign io_out_4_bits_vpu_vsew                   = out_payload_4.vpu_vsew;
  assign io_out_4_bits_vpu_vlmul                  = out_payload_4.vpu_vlmul;
  assign io_out_4_bits_vpu_specVill               = out_payload_4.vpu_specVill;
  assign io_out_4_bits_vpu_specVma                = out_payload_4.vpu_specVma;
  assign io_out_4_bits_vpu_specVta                = out_payload_4.vpu_specVta;
  assign io_out_4_bits_vpu_specVsew               = out_payload_4.vpu_specVsew;
  assign io_out_4_bits_vpu_specVlmul              = out_payload_4.vpu_specVlmul;
  assign io_out_4_bits_vpu_vm                     = out_payload_4.vpu_vm;
  assign io_out_4_bits_vpu_vstart                 = out_payload_4.vpu_vstart;
  assign io_out_4_bits_vpu_frm                    = out_payload_4.vpu_frm;
  assign io_out_4_bits_vpu_fpu_isFpToVecInst      = out_payload_4.vpu_fpu_isFpToVecInst;
  assign io_out_4_bits_vpu_fpu_isFP32Instr        = out_payload_4.vpu_fpu_isFP32Instr;
  assign io_out_4_bits_vpu_fpu_isFP64Instr        = out_payload_4.vpu_fpu_isFP64Instr;
  assign io_out_4_bits_vpu_fpu_isReduction        = out_payload_4.vpu_fpu_isReduction;
  assign io_out_4_bits_vpu_fpu_isFoldTo1_2        = out_payload_4.vpu_fpu_isFoldTo1_2;
  assign io_out_4_bits_vpu_fpu_isFoldTo1_4        = out_payload_4.vpu_fpu_isFoldTo1_4;
  assign io_out_4_bits_vpu_fpu_isFoldTo1_8        = out_payload_4.vpu_fpu_isFoldTo1_8;
  assign io_out_4_bits_vpu_vxrm                   = out_payload_4.vpu_vxrm;
  assign io_out_4_bits_vpu_vuopIdx                = out_payload_4.vpu_vuopIdx;
  assign io_out_4_bits_vpu_lastUop                = out_payload_4.vpu_lastUop;
  assign io_out_4_bits_vpu_vmask                  = out_payload_4.vpu_vmask;
  assign io_out_4_bits_vpu_vl                     = out_payload_4.vpu_vl;
  assign io_out_4_bits_vpu_nf                     = out_payload_4.vpu_nf;
  assign io_out_4_bits_vpu_veew                   = out_payload_4.vpu_veew;
  assign io_out_4_bits_vpu_isReverse              = out_payload_4.vpu_isReverse;
  assign io_out_4_bits_vpu_isExt                  = out_payload_4.vpu_isExt;
  assign io_out_4_bits_vpu_isNarrow               = out_payload_4.vpu_isNarrow;
  assign io_out_4_bits_vpu_isDstMask              = out_payload_4.vpu_isDstMask;
  assign io_out_4_bits_vpu_isOpMask               = out_payload_4.vpu_isOpMask;
  assign io_out_4_bits_vpu_isMove                 = out_payload_4.vpu_isMove;
  assign io_out_4_bits_vpu_isDependOldVd          = out_payload_4.vpu_isDependOldVd;
  assign io_out_4_bits_vpu_isWritePartVd          = out_payload_4.vpu_isWritePartVd;
  assign io_out_4_bits_vpu_isVleff                = out_payload_4.vpu_isVleff;
  assign io_out_4_bits_vlsInstr                   = out_payload_4.vlsInstr;
  assign io_out_4_bits_wfflags                    = out_payload_4.wfflags;
  assign io_out_4_bits_isMove                     = out_payload_4.isMove;
  assign io_out_4_bits_uopIdx                     = out_payload_4.uopIdx;
  assign io_out_4_bits_isVset                     = out_payload_4.isVset;
  assign io_out_4_bits_firstUop                   = out_payload_4.firstUop;
  assign io_out_4_bits_lastUop                    = out_payload_4.lastUop;
  assign io_out_4_bits_numUops                    = out_payload_4.numUops;
  assign io_out_4_bits_numWB                      = out_payload_4.numWB;
  assign io_out_4_bits_commitType                 = out_payload_4.commitType;
  assign io_out_4_bits_psrc_0                     = out_payload_4.psrc_0;
  assign io_out_4_bits_psrc_1                     = out_payload_4.psrc_1;
  assign io_out_4_bits_psrc_2                     = out_payload_4.psrc_2;
  assign io_out_4_bits_psrc_3                     = out_payload_4.psrc_3;
  assign io_out_4_bits_psrc_4                     = out_payload_4.psrc_4;
  assign io_out_4_bits_pdest                      = out_payload_4.pdest;
  assign io_out_4_bits_robIdx_flag                = out_payload_4.robIdx_flag;
  assign io_out_4_bits_robIdx_value               = out_payload_4.robIdx_value;
  assign io_out_4_bits_instrSize                  = out_payload_4.instrSize;
  assign io_out_4_bits_dirtyFs                    = out_payload_4.dirtyFs;
  assign io_out_4_bits_dirtyVs                    = out_payload_4.dirtyVs;
  assign io_out_4_bits_traceBlockInPipe_itype     = out_payload_4.traceBlockInPipe_itype;
  assign io_out_4_bits_traceBlockInPipe_iretire   = out_payload_4.traceBlockInPipe_iretire;
  assign io_out_4_bits_traceBlockInPipe_ilastsize = out_payload_4.traceBlockInPipe_ilastsize;
  assign io_out_4_bits_eliminatedMove             = out_payload_4.eliminatedMove;
  assign io_out_4_bits_debugInfo_renameTime       = out_payload_4.debugInfo_renameTime;
  assign io_out_4_bits_debug_seqNum_seqNum        = out_payload_4.debug_seqNum_seqNum;
  assign io_out_4_bits_debug_seqNum_uopIdx        = out_payload_4.debug_seqNum_uopIdx;
  assign io_out_4_bits_debug_fuType               = out_payload_4.debug_fuType;
  assign io_out_4_bits_debug_sim_trig             = out_payload_4.debug_sim_trig;
  assign io_out_4_bits_numLsElem                  = out_payload_4.numLsElem;

  // ---------------------------------------------------------------------------
  // lane 5：入口打包 / 出口拆包（同名逐项）
  // ---------------------------------------------------------------------------
  always_comb begin
    in_payload_5.instr                      = io_in_5_bits_instr;
    in_payload_5.pc                         = io_in_5_bits_pc;
    in_payload_5.foldpc                     = io_in_5_bits_foldpc;
    in_payload_5.exceptionVec_0             = io_in_5_bits_exceptionVec_0;
    in_payload_5.exceptionVec_1             = io_in_5_bits_exceptionVec_1;
    in_payload_5.exceptionVec_2             = io_in_5_bits_exceptionVec_2;
    in_payload_5.exceptionVec_3             = io_in_5_bits_exceptionVec_3;
    in_payload_5.exceptionVec_4             = io_in_5_bits_exceptionVec_4;
    in_payload_5.exceptionVec_5             = io_in_5_bits_exceptionVec_5;
    in_payload_5.exceptionVec_6             = io_in_5_bits_exceptionVec_6;
    in_payload_5.exceptionVec_7             = io_in_5_bits_exceptionVec_7;
    in_payload_5.exceptionVec_8             = io_in_5_bits_exceptionVec_8;
    in_payload_5.exceptionVec_9             = io_in_5_bits_exceptionVec_9;
    in_payload_5.exceptionVec_10            = io_in_5_bits_exceptionVec_10;
    in_payload_5.exceptionVec_11            = io_in_5_bits_exceptionVec_11;
    in_payload_5.exceptionVec_12            = io_in_5_bits_exceptionVec_12;
    in_payload_5.exceptionVec_13            = io_in_5_bits_exceptionVec_13;
    in_payload_5.exceptionVec_14            = io_in_5_bits_exceptionVec_14;
    in_payload_5.exceptionVec_15            = io_in_5_bits_exceptionVec_15;
    in_payload_5.exceptionVec_16            = io_in_5_bits_exceptionVec_16;
    in_payload_5.exceptionVec_17            = io_in_5_bits_exceptionVec_17;
    in_payload_5.exceptionVec_18            = io_in_5_bits_exceptionVec_18;
    in_payload_5.exceptionVec_19            = io_in_5_bits_exceptionVec_19;
    in_payload_5.exceptionVec_20            = io_in_5_bits_exceptionVec_20;
    in_payload_5.exceptionVec_21            = io_in_5_bits_exceptionVec_21;
    in_payload_5.exceptionVec_22            = io_in_5_bits_exceptionVec_22;
    in_payload_5.exceptionVec_23            = io_in_5_bits_exceptionVec_23;
    in_payload_5.isFetchMalAddr             = io_in_5_bits_isFetchMalAddr;
    in_payload_5.hasException               = io_in_5_bits_hasException;
    in_payload_5.trigger                    = io_in_5_bits_trigger;
    in_payload_5.preDecodeInfo_valid        = io_in_5_bits_preDecodeInfo_valid;
    in_payload_5.preDecodeInfo_isRVC        = io_in_5_bits_preDecodeInfo_isRVC;
    in_payload_5.preDecodeInfo_brType       = io_in_5_bits_preDecodeInfo_brType;
    in_payload_5.preDecodeInfo_isCall       = io_in_5_bits_preDecodeInfo_isCall;
    in_payload_5.preDecodeInfo_isRet        = io_in_5_bits_preDecodeInfo_isRet;
    in_payload_5.pred_taken                 = io_in_5_bits_pred_taken;
    in_payload_5.crossPageIPFFix            = io_in_5_bits_crossPageIPFFix;
    in_payload_5.ftqPtr_flag                = io_in_5_bits_ftqPtr_flag;
    in_payload_5.ftqPtr_value               = io_in_5_bits_ftqPtr_value;
    in_payload_5.ftqOffset                  = io_in_5_bits_ftqOffset;
    in_payload_5.satpFlushFirstFetchFault   = io_in_5_bits_satpFlushFirstFetchFault;
    in_payload_5.srcType_0                  = io_in_5_bits_srcType_0;
    in_payload_5.srcType_1                  = io_in_5_bits_srcType_1;
    in_payload_5.srcType_2                  = io_in_5_bits_srcType_2;
    in_payload_5.srcType_3                  = io_in_5_bits_srcType_3;
    in_payload_5.srcType_4                  = io_in_5_bits_srcType_4;
    in_payload_5.ldest                      = io_in_5_bits_ldest;
    in_payload_5.fuType                     = io_in_5_bits_fuType;
    in_payload_5.fuOpType                   = io_in_5_bits_fuOpType;
    in_payload_5.rfWen                      = io_in_5_bits_rfWen;
    in_payload_5.fpWen                      = io_in_5_bits_fpWen;
    in_payload_5.vecWen                     = io_in_5_bits_vecWen;
    in_payload_5.v0Wen                      = io_in_5_bits_v0Wen;
    in_payload_5.vlWen                      = io_in_5_bits_vlWen;
    in_payload_5.isXSTrap                   = io_in_5_bits_isXSTrap;
    in_payload_5.waitForward                = io_in_5_bits_waitForward;
    in_payload_5.blockBackward              = io_in_5_bits_blockBackward;
    in_payload_5.flushPipe                  = io_in_5_bits_flushPipe;
    in_payload_5.canRobCompress             = io_in_5_bits_canRobCompress;
    in_payload_5.selImm                     = io_in_5_bits_selImm;
    in_payload_5.imm                        = io_in_5_bits_imm;
    in_payload_5.fpu_typeTagOut             = io_in_5_bits_fpu_typeTagOut;
    in_payload_5.fpu_wflags                 = io_in_5_bits_fpu_wflags;
    in_payload_5.fpu_typ                    = io_in_5_bits_fpu_typ;
    in_payload_5.fpu_fmt                    = io_in_5_bits_fpu_fmt;
    in_payload_5.fpu_rm                     = io_in_5_bits_fpu_rm;
    in_payload_5.vpu_vill                   = io_in_5_bits_vpu_vill;
    in_payload_5.vpu_vma                    = io_in_5_bits_vpu_vma;
    in_payload_5.vpu_vta                    = io_in_5_bits_vpu_vta;
    in_payload_5.vpu_vsew                   = io_in_5_bits_vpu_vsew;
    in_payload_5.vpu_vlmul                  = io_in_5_bits_vpu_vlmul;
    in_payload_5.vpu_specVill               = io_in_5_bits_vpu_specVill;
    in_payload_5.vpu_specVma                = io_in_5_bits_vpu_specVma;
    in_payload_5.vpu_specVta                = io_in_5_bits_vpu_specVta;
    in_payload_5.vpu_specVsew               = io_in_5_bits_vpu_specVsew;
    in_payload_5.vpu_specVlmul              = io_in_5_bits_vpu_specVlmul;
    in_payload_5.vpu_vm                     = io_in_5_bits_vpu_vm;
    in_payload_5.vpu_vstart                 = io_in_5_bits_vpu_vstart;
    in_payload_5.vpu_frm                    = io_in_5_bits_vpu_frm;
    in_payload_5.vpu_fpu_isFpToVecInst      = io_in_5_bits_vpu_fpu_isFpToVecInst;
    in_payload_5.vpu_fpu_isFP32Instr        = io_in_5_bits_vpu_fpu_isFP32Instr;
    in_payload_5.vpu_fpu_isFP64Instr        = io_in_5_bits_vpu_fpu_isFP64Instr;
    in_payload_5.vpu_fpu_isReduction        = io_in_5_bits_vpu_fpu_isReduction;
    in_payload_5.vpu_fpu_isFoldTo1_2        = io_in_5_bits_vpu_fpu_isFoldTo1_2;
    in_payload_5.vpu_fpu_isFoldTo1_4        = io_in_5_bits_vpu_fpu_isFoldTo1_4;
    in_payload_5.vpu_fpu_isFoldTo1_8        = io_in_5_bits_vpu_fpu_isFoldTo1_8;
    in_payload_5.vpu_vxrm                   = io_in_5_bits_vpu_vxrm;
    in_payload_5.vpu_vuopIdx                = io_in_5_bits_vpu_vuopIdx;
    in_payload_5.vpu_lastUop                = io_in_5_bits_vpu_lastUop;
    in_payload_5.vpu_vmask                  = io_in_5_bits_vpu_vmask;
    in_payload_5.vpu_vl                     = io_in_5_bits_vpu_vl;
    in_payload_5.vpu_nf                     = io_in_5_bits_vpu_nf;
    in_payload_5.vpu_veew                   = io_in_5_bits_vpu_veew;
    in_payload_5.vpu_isReverse              = io_in_5_bits_vpu_isReverse;
    in_payload_5.vpu_isExt                  = io_in_5_bits_vpu_isExt;
    in_payload_5.vpu_isNarrow               = io_in_5_bits_vpu_isNarrow;
    in_payload_5.vpu_isDstMask              = io_in_5_bits_vpu_isDstMask;
    in_payload_5.vpu_isOpMask               = io_in_5_bits_vpu_isOpMask;
    in_payload_5.vpu_isMove                 = io_in_5_bits_vpu_isMove;
    in_payload_5.vpu_isDependOldVd          = io_in_5_bits_vpu_isDependOldVd;
    in_payload_5.vpu_isWritePartVd          = io_in_5_bits_vpu_isWritePartVd;
    in_payload_5.vpu_isVleff                = io_in_5_bits_vpu_isVleff;
    in_payload_5.vlsInstr                   = io_in_5_bits_vlsInstr;
    in_payload_5.wfflags                    = io_in_5_bits_wfflags;
    in_payload_5.isMove                     = io_in_5_bits_isMove;
    in_payload_5.uopIdx                     = io_in_5_bits_uopIdx;
    in_payload_5.isVset                     = io_in_5_bits_isVset;
    in_payload_5.firstUop                   = io_in_5_bits_firstUop;
    in_payload_5.lastUop                    = io_in_5_bits_lastUop;
    in_payload_5.numUops                    = io_in_5_bits_numUops;
    in_payload_5.numWB                      = io_in_5_bits_numWB;
    in_payload_5.commitType                 = io_in_5_bits_commitType;
    in_payload_5.psrc_0                     = io_in_5_bits_psrc_0;
    in_payload_5.psrc_1                     = io_in_5_bits_psrc_1;
    in_payload_5.psrc_2                     = io_in_5_bits_psrc_2;
    in_payload_5.psrc_3                     = io_in_5_bits_psrc_3;
    in_payload_5.psrc_4                     = io_in_5_bits_psrc_4;
    in_payload_5.pdest                      = io_in_5_bits_pdest;
    in_payload_5.robIdx_flag                = io_in_5_bits_robIdx_flag;
    in_payload_5.robIdx_value               = io_in_5_bits_robIdx_value;
    in_payload_5.instrSize                  = io_in_5_bits_instrSize;
    in_payload_5.dirtyFs                    = io_in_5_bits_dirtyFs;
    in_payload_5.dirtyVs                    = io_in_5_bits_dirtyVs;
    in_payload_5.traceBlockInPipe_itype     = io_in_5_bits_traceBlockInPipe_itype;
    in_payload_5.traceBlockInPipe_iretire   = io_in_5_bits_traceBlockInPipe_iretire;
    in_payload_5.traceBlockInPipe_ilastsize = io_in_5_bits_traceBlockInPipe_ilastsize;
    in_payload_5.eliminatedMove             = io_in_5_bits_eliminatedMove;
    in_payload_5.debugInfo_renameTime       = io_in_5_bits_debugInfo_renameTime;
    in_payload_5.debug_seqNum_seqNum        = io_in_5_bits_debug_seqNum_seqNum;
    in_payload_5.debug_seqNum_uopIdx        = io_in_5_bits_debug_seqNum_uopIdx;
    in_payload_5.debug_fuType               = io_in_5_bits_debug_fuType;
    in_payload_5.debug_sim_trig             = io_in_5_bits_debug_sim_trig;
    in_payload_5.numLsElem                  = io_in_5_bits_numLsElem;
  end
  assign io_out_5_bits_instr                      = out_payload_5.instr;
  assign io_out_5_bits_pc                         = out_payload_5.pc;
  assign io_out_5_bits_foldpc                     = out_payload_5.foldpc;
  assign io_out_5_bits_exceptionVec_0             = out_payload_5.exceptionVec_0;
  assign io_out_5_bits_exceptionVec_1             = out_payload_5.exceptionVec_1;
  assign io_out_5_bits_exceptionVec_2             = out_payload_5.exceptionVec_2;
  assign io_out_5_bits_exceptionVec_3             = out_payload_5.exceptionVec_3;
  assign io_out_5_bits_exceptionVec_4             = out_payload_5.exceptionVec_4;
  assign io_out_5_bits_exceptionVec_5             = out_payload_5.exceptionVec_5;
  assign io_out_5_bits_exceptionVec_6             = out_payload_5.exceptionVec_6;
  assign io_out_5_bits_exceptionVec_7             = out_payload_5.exceptionVec_7;
  assign io_out_5_bits_exceptionVec_8             = out_payload_5.exceptionVec_8;
  assign io_out_5_bits_exceptionVec_9             = out_payload_5.exceptionVec_9;
  assign io_out_5_bits_exceptionVec_10            = out_payload_5.exceptionVec_10;
  assign io_out_5_bits_exceptionVec_11            = out_payload_5.exceptionVec_11;
  assign io_out_5_bits_exceptionVec_12            = out_payload_5.exceptionVec_12;
  assign io_out_5_bits_exceptionVec_13            = out_payload_5.exceptionVec_13;
  assign io_out_5_bits_exceptionVec_14            = out_payload_5.exceptionVec_14;
  assign io_out_5_bits_exceptionVec_15            = out_payload_5.exceptionVec_15;
  assign io_out_5_bits_exceptionVec_16            = out_payload_5.exceptionVec_16;
  assign io_out_5_bits_exceptionVec_17            = out_payload_5.exceptionVec_17;
  assign io_out_5_bits_exceptionVec_18            = out_payload_5.exceptionVec_18;
  assign io_out_5_bits_exceptionVec_19            = out_payload_5.exceptionVec_19;
  assign io_out_5_bits_exceptionVec_20            = out_payload_5.exceptionVec_20;
  assign io_out_5_bits_exceptionVec_21            = out_payload_5.exceptionVec_21;
  assign io_out_5_bits_exceptionVec_22            = out_payload_5.exceptionVec_22;
  assign io_out_5_bits_exceptionVec_23            = out_payload_5.exceptionVec_23;
  assign io_out_5_bits_isFetchMalAddr             = out_payload_5.isFetchMalAddr;
  assign io_out_5_bits_hasException               = out_payload_5.hasException;
  assign io_out_5_bits_trigger                    = out_payload_5.trigger;
  assign io_out_5_bits_preDecodeInfo_valid        = out_payload_5.preDecodeInfo_valid;
  assign io_out_5_bits_preDecodeInfo_isRVC        = out_payload_5.preDecodeInfo_isRVC;
  assign io_out_5_bits_preDecodeInfo_brType       = out_payload_5.preDecodeInfo_brType;
  assign io_out_5_bits_preDecodeInfo_isCall       = out_payload_5.preDecodeInfo_isCall;
  assign io_out_5_bits_preDecodeInfo_isRet        = out_payload_5.preDecodeInfo_isRet;
  assign io_out_5_bits_pred_taken                 = out_payload_5.pred_taken;
  assign io_out_5_bits_crossPageIPFFix            = out_payload_5.crossPageIPFFix;
  assign io_out_5_bits_ftqPtr_flag                = out_payload_5.ftqPtr_flag;
  assign io_out_5_bits_ftqPtr_value               = out_payload_5.ftqPtr_value;
  assign io_out_5_bits_ftqOffset                  = out_payload_5.ftqOffset;
  assign io_out_5_bits_satpFlushFirstFetchFault   = out_payload_5.satpFlushFirstFetchFault;
  assign io_out_5_bits_srcType_0                  = out_payload_5.srcType_0;
  assign io_out_5_bits_srcType_1                  = out_payload_5.srcType_1;
  assign io_out_5_bits_srcType_2                  = out_payload_5.srcType_2;
  assign io_out_5_bits_srcType_3                  = out_payload_5.srcType_3;
  assign io_out_5_bits_srcType_4                  = out_payload_5.srcType_4;
  assign io_out_5_bits_ldest                      = out_payload_5.ldest;
  assign io_out_5_bits_fuType                     = out_payload_5.fuType;
  assign io_out_5_bits_fuOpType                   = out_payload_5.fuOpType;
  assign io_out_5_bits_rfWen                      = out_payload_5.rfWen;
  assign io_out_5_bits_fpWen                      = out_payload_5.fpWen;
  assign io_out_5_bits_vecWen                     = out_payload_5.vecWen;
  assign io_out_5_bits_v0Wen                      = out_payload_5.v0Wen;
  assign io_out_5_bits_vlWen                      = out_payload_5.vlWen;
  assign io_out_5_bits_isXSTrap                   = out_payload_5.isXSTrap;
  assign io_out_5_bits_waitForward                = out_payload_5.waitForward;
  assign io_out_5_bits_blockBackward              = out_payload_5.blockBackward;
  assign io_out_5_bits_flushPipe                  = out_payload_5.flushPipe;
  assign io_out_5_bits_canRobCompress             = out_payload_5.canRobCompress;
  assign io_out_5_bits_selImm                     = out_payload_5.selImm;
  assign io_out_5_bits_imm                        = out_payload_5.imm;
  assign io_out_5_bits_fpu_typeTagOut             = out_payload_5.fpu_typeTagOut;
  assign io_out_5_bits_fpu_wflags                 = out_payload_5.fpu_wflags;
  assign io_out_5_bits_fpu_typ                    = out_payload_5.fpu_typ;
  assign io_out_5_bits_fpu_fmt                    = out_payload_5.fpu_fmt;
  assign io_out_5_bits_fpu_rm                     = out_payload_5.fpu_rm;
  assign io_out_5_bits_vpu_vill                   = out_payload_5.vpu_vill;
  assign io_out_5_bits_vpu_vma                    = out_payload_5.vpu_vma;
  assign io_out_5_bits_vpu_vta                    = out_payload_5.vpu_vta;
  assign io_out_5_bits_vpu_vsew                   = out_payload_5.vpu_vsew;
  assign io_out_5_bits_vpu_vlmul                  = out_payload_5.vpu_vlmul;
  assign io_out_5_bits_vpu_specVill               = out_payload_5.vpu_specVill;
  assign io_out_5_bits_vpu_specVma                = out_payload_5.vpu_specVma;
  assign io_out_5_bits_vpu_specVta                = out_payload_5.vpu_specVta;
  assign io_out_5_bits_vpu_specVsew               = out_payload_5.vpu_specVsew;
  assign io_out_5_bits_vpu_specVlmul              = out_payload_5.vpu_specVlmul;
  assign io_out_5_bits_vpu_vm                     = out_payload_5.vpu_vm;
  assign io_out_5_bits_vpu_vstart                 = out_payload_5.vpu_vstart;
  assign io_out_5_bits_vpu_frm                    = out_payload_5.vpu_frm;
  assign io_out_5_bits_vpu_fpu_isFpToVecInst      = out_payload_5.vpu_fpu_isFpToVecInst;
  assign io_out_5_bits_vpu_fpu_isFP32Instr        = out_payload_5.vpu_fpu_isFP32Instr;
  assign io_out_5_bits_vpu_fpu_isFP64Instr        = out_payload_5.vpu_fpu_isFP64Instr;
  assign io_out_5_bits_vpu_fpu_isReduction        = out_payload_5.vpu_fpu_isReduction;
  assign io_out_5_bits_vpu_fpu_isFoldTo1_2        = out_payload_5.vpu_fpu_isFoldTo1_2;
  assign io_out_5_bits_vpu_fpu_isFoldTo1_4        = out_payload_5.vpu_fpu_isFoldTo1_4;
  assign io_out_5_bits_vpu_fpu_isFoldTo1_8        = out_payload_5.vpu_fpu_isFoldTo1_8;
  assign io_out_5_bits_vpu_vxrm                   = out_payload_5.vpu_vxrm;
  assign io_out_5_bits_vpu_vuopIdx                = out_payload_5.vpu_vuopIdx;
  assign io_out_5_bits_vpu_lastUop                = out_payload_5.vpu_lastUop;
  assign io_out_5_bits_vpu_vmask                  = out_payload_5.vpu_vmask;
  assign io_out_5_bits_vpu_vl                     = out_payload_5.vpu_vl;
  assign io_out_5_bits_vpu_nf                     = out_payload_5.vpu_nf;
  assign io_out_5_bits_vpu_veew                   = out_payload_5.vpu_veew;
  assign io_out_5_bits_vpu_isReverse              = out_payload_5.vpu_isReverse;
  assign io_out_5_bits_vpu_isExt                  = out_payload_5.vpu_isExt;
  assign io_out_5_bits_vpu_isNarrow               = out_payload_5.vpu_isNarrow;
  assign io_out_5_bits_vpu_isDstMask              = out_payload_5.vpu_isDstMask;
  assign io_out_5_bits_vpu_isOpMask               = out_payload_5.vpu_isOpMask;
  assign io_out_5_bits_vpu_isMove                 = out_payload_5.vpu_isMove;
  assign io_out_5_bits_vpu_isDependOldVd          = out_payload_5.vpu_isDependOldVd;
  assign io_out_5_bits_vpu_isWritePartVd          = out_payload_5.vpu_isWritePartVd;
  assign io_out_5_bits_vpu_isVleff                = out_payload_5.vpu_isVleff;
  assign io_out_5_bits_vlsInstr                   = out_payload_5.vlsInstr;
  assign io_out_5_bits_wfflags                    = out_payload_5.wfflags;
  assign io_out_5_bits_isMove                     = out_payload_5.isMove;
  assign io_out_5_bits_uopIdx                     = out_payload_5.uopIdx;
  assign io_out_5_bits_isVset                     = out_payload_5.isVset;
  assign io_out_5_bits_firstUop                   = out_payload_5.firstUop;
  assign io_out_5_bits_lastUop                    = out_payload_5.lastUop;
  assign io_out_5_bits_numUops                    = out_payload_5.numUops;
  assign io_out_5_bits_numWB                      = out_payload_5.numWB;
  assign io_out_5_bits_commitType                 = out_payload_5.commitType;
  assign io_out_5_bits_psrc_0                     = out_payload_5.psrc_0;
  assign io_out_5_bits_psrc_1                     = out_payload_5.psrc_1;
  assign io_out_5_bits_psrc_2                     = out_payload_5.psrc_2;
  assign io_out_5_bits_psrc_3                     = out_payload_5.psrc_3;
  assign io_out_5_bits_psrc_4                     = out_payload_5.psrc_4;
  assign io_out_5_bits_pdest                      = out_payload_5.pdest;
  assign io_out_5_bits_robIdx_flag                = out_payload_5.robIdx_flag;
  assign io_out_5_bits_robIdx_value               = out_payload_5.robIdx_value;
  assign io_out_5_bits_instrSize                  = out_payload_5.instrSize;
  assign io_out_5_bits_dirtyFs                    = out_payload_5.dirtyFs;
  assign io_out_5_bits_dirtyVs                    = out_payload_5.dirtyVs;
  assign io_out_5_bits_traceBlockInPipe_itype     = out_payload_5.traceBlockInPipe_itype;
  assign io_out_5_bits_traceBlockInPipe_iretire   = out_payload_5.traceBlockInPipe_iretire;
  assign io_out_5_bits_traceBlockInPipe_ilastsize = out_payload_5.traceBlockInPipe_ilastsize;
  assign io_out_5_bits_eliminatedMove             = out_payload_5.eliminatedMove;
  assign io_out_5_bits_debugInfo_renameTime       = out_payload_5.debugInfo_renameTime;
  assign io_out_5_bits_debug_seqNum_seqNum        = out_payload_5.debug_seqNum_seqNum;
  assign io_out_5_bits_debug_seqNum_uopIdx        = out_payload_5.debug_seqNum_uopIdx;
  assign io_out_5_bits_debug_fuType               = out_payload_5.debug_fuType;
  assign io_out_5_bits_debug_sim_trig             = out_payload_5.debug_sim_trig;
  assign io_out_5_bits_numLsElem                  = out_payload_5.numLsElem;

  // ---------------------------------------------------------------------------
  // elaborate 期位宽不变式：每 lane 入口端口位宽之和 == 出口端口位宽之和 == 该 lane 的
  // G1 位宽和（== $bits(struct)，最后一个等号由 slot 校验）。
  // ---------------------------------------------------------------------------
  localparam int unsigned IN0_PORT_BITS =
    $bits(io_in_0_bits_instr) + $bits(io_in_0_bits_pc) + $bits(io_in_0_bits_foldpc) + $bits(io_in_0_bits_exceptionVec_0) +
    $bits(io_in_0_bits_exceptionVec_1) + $bits(io_in_0_bits_exceptionVec_2) + $bits(io_in_0_bits_exceptionVec_3) + $bits(io_in_0_bits_exceptionVec_4) +
    $bits(io_in_0_bits_exceptionVec_5) + $bits(io_in_0_bits_exceptionVec_6) + $bits(io_in_0_bits_exceptionVec_7) + $bits(io_in_0_bits_exceptionVec_8) +
    $bits(io_in_0_bits_exceptionVec_9) + $bits(io_in_0_bits_exceptionVec_10) + $bits(io_in_0_bits_exceptionVec_11) + $bits(io_in_0_bits_exceptionVec_12) +
    $bits(io_in_0_bits_exceptionVec_13) + $bits(io_in_0_bits_exceptionVec_14) + $bits(io_in_0_bits_exceptionVec_15) + $bits(io_in_0_bits_exceptionVec_16) +
    $bits(io_in_0_bits_exceptionVec_17) + $bits(io_in_0_bits_exceptionVec_18) + $bits(io_in_0_bits_exceptionVec_19) + $bits(io_in_0_bits_exceptionVec_20) +
    $bits(io_in_0_bits_exceptionVec_21) + $bits(io_in_0_bits_exceptionVec_22) + $bits(io_in_0_bits_exceptionVec_23) + $bits(io_in_0_bits_isFetchMalAddr) +
    $bits(io_in_0_bits_hasException) + $bits(io_in_0_bits_trigger) + $bits(io_in_0_bits_preDecodeInfo_valid) + $bits(io_in_0_bits_preDecodeInfo_isRVC) +
    $bits(io_in_0_bits_preDecodeInfo_brType) + $bits(io_in_0_bits_preDecodeInfo_isCall) + $bits(io_in_0_bits_preDecodeInfo_isRet) + $bits(io_in_0_bits_pred_taken) +
    $bits(io_in_0_bits_crossPageIPFFix) + $bits(io_in_0_bits_ftqPtr_flag) + $bits(io_in_0_bits_ftqPtr_value) + $bits(io_in_0_bits_ftqOffset) +
    $bits(io_in_0_bits_satpFlushFirstFetchFault) + $bits(io_in_0_bits_srcType_0) + $bits(io_in_0_bits_srcType_1) + $bits(io_in_0_bits_srcType_2) +
    $bits(io_in_0_bits_srcType_3) + $bits(io_in_0_bits_srcType_4) + $bits(io_in_0_bits_ldest) + $bits(io_in_0_bits_fuType) +
    $bits(io_in_0_bits_fuOpType) + $bits(io_in_0_bits_rfWen) + $bits(io_in_0_bits_fpWen) + $bits(io_in_0_bits_vecWen) +
    $bits(io_in_0_bits_v0Wen) + $bits(io_in_0_bits_vlWen) + $bits(io_in_0_bits_isXSTrap) + $bits(io_in_0_bits_waitForward) +
    $bits(io_in_0_bits_blockBackward) + $bits(io_in_0_bits_flushPipe) + $bits(io_in_0_bits_canRobCompress) + $bits(io_in_0_bits_selImm) +
    $bits(io_in_0_bits_imm) + $bits(io_in_0_bits_fpu_typeTagOut) + $bits(io_in_0_bits_fpu_wflags) + $bits(io_in_0_bits_fpu_typ) +
    $bits(io_in_0_bits_fpu_fmt) + $bits(io_in_0_bits_fpu_rm) + $bits(io_in_0_bits_vpu_vill) + $bits(io_in_0_bits_vpu_vma) +
    $bits(io_in_0_bits_vpu_vta) + $bits(io_in_0_bits_vpu_vsew) + $bits(io_in_0_bits_vpu_vlmul) + $bits(io_in_0_bits_vpu_specVill) +
    $bits(io_in_0_bits_vpu_specVma) + $bits(io_in_0_bits_vpu_specVta) + $bits(io_in_0_bits_vpu_specVsew) + $bits(io_in_0_bits_vpu_specVlmul) +
    $bits(io_in_0_bits_vpu_vm) + $bits(io_in_0_bits_vpu_vstart) + $bits(io_in_0_bits_vpu_frm) + $bits(io_in_0_bits_vpu_fpu_isFpToVecInst) +
    $bits(io_in_0_bits_vpu_fpu_isFP32Instr) + $bits(io_in_0_bits_vpu_fpu_isFP64Instr) + $bits(io_in_0_bits_vpu_fpu_isReduction) + $bits(io_in_0_bits_vpu_fpu_isFoldTo1_2) +
    $bits(io_in_0_bits_vpu_fpu_isFoldTo1_4) + $bits(io_in_0_bits_vpu_fpu_isFoldTo1_8) + $bits(io_in_0_bits_vpu_vxrm) + $bits(io_in_0_bits_vpu_vuopIdx) +
    $bits(io_in_0_bits_vpu_lastUop) + $bits(io_in_0_bits_vpu_vmask) + $bits(io_in_0_bits_vpu_vl) + $bits(io_in_0_bits_vpu_nf) +
    $bits(io_in_0_bits_vpu_veew) + $bits(io_in_0_bits_vpu_isReverse) + $bits(io_in_0_bits_vpu_isExt) + $bits(io_in_0_bits_vpu_isNarrow) +
    $bits(io_in_0_bits_vpu_isDstMask) + $bits(io_in_0_bits_vpu_isOpMask) + $bits(io_in_0_bits_vpu_isMove) + $bits(io_in_0_bits_vpu_isDependOldVd) +
    $bits(io_in_0_bits_vpu_isWritePartVd) + $bits(io_in_0_bits_vpu_isVleff) + $bits(io_in_0_bits_vlsInstr) + $bits(io_in_0_bits_wfflags) +
    $bits(io_in_0_bits_isMove) + $bits(io_in_0_bits_uopIdx) + $bits(io_in_0_bits_isVset) + $bits(io_in_0_bits_firstUop) +
    $bits(io_in_0_bits_lastUop) + $bits(io_in_0_bits_numUops) + $bits(io_in_0_bits_numWB) + $bits(io_in_0_bits_commitType) +
    $bits(io_in_0_bits_psrc_0) + $bits(io_in_0_bits_psrc_1) + $bits(io_in_0_bits_psrc_2) + $bits(io_in_0_bits_psrc_3) +
    $bits(io_in_0_bits_psrc_4) + $bits(io_in_0_bits_pdest) + $bits(io_in_0_bits_robIdx_flag) + $bits(io_in_0_bits_robIdx_value) +
    $bits(io_in_0_bits_instrSize) + $bits(io_in_0_bits_dirtyFs) + $bits(io_in_0_bits_dirtyVs) + $bits(io_in_0_bits_traceBlockInPipe_itype) +
    $bits(io_in_0_bits_traceBlockInPipe_iretire) + $bits(io_in_0_bits_traceBlockInPipe_ilastsize) + $bits(io_in_0_bits_eliminatedMove) + $bits(io_in_0_bits_snapshot) +
    $bits(io_in_0_bits_debugInfo_renameTime) + $bits(io_in_0_bits_debug_seqNum_seqNum) + $bits(io_in_0_bits_debug_seqNum_uopIdx) + $bits(io_in_0_bits_debug_fuType) +
    $bits(io_in_0_bits_debug_sim_trig) + $bits(io_in_0_bits_numLsElem);
  localparam int unsigned OUT0_PORT_BITS =
    $bits(io_out_0_bits_instr) + $bits(io_out_0_bits_pc) + $bits(io_out_0_bits_foldpc) + $bits(io_out_0_bits_exceptionVec_0) +
    $bits(io_out_0_bits_exceptionVec_1) + $bits(io_out_0_bits_exceptionVec_2) + $bits(io_out_0_bits_exceptionVec_3) + $bits(io_out_0_bits_exceptionVec_4) +
    $bits(io_out_0_bits_exceptionVec_5) + $bits(io_out_0_bits_exceptionVec_6) + $bits(io_out_0_bits_exceptionVec_7) + $bits(io_out_0_bits_exceptionVec_8) +
    $bits(io_out_0_bits_exceptionVec_9) + $bits(io_out_0_bits_exceptionVec_10) + $bits(io_out_0_bits_exceptionVec_11) + $bits(io_out_0_bits_exceptionVec_12) +
    $bits(io_out_0_bits_exceptionVec_13) + $bits(io_out_0_bits_exceptionVec_14) + $bits(io_out_0_bits_exceptionVec_15) + $bits(io_out_0_bits_exceptionVec_16) +
    $bits(io_out_0_bits_exceptionVec_17) + $bits(io_out_0_bits_exceptionVec_18) + $bits(io_out_0_bits_exceptionVec_19) + $bits(io_out_0_bits_exceptionVec_20) +
    $bits(io_out_0_bits_exceptionVec_21) + $bits(io_out_0_bits_exceptionVec_22) + $bits(io_out_0_bits_exceptionVec_23) + $bits(io_out_0_bits_isFetchMalAddr) +
    $bits(io_out_0_bits_hasException) + $bits(io_out_0_bits_trigger) + $bits(io_out_0_bits_preDecodeInfo_valid) + $bits(io_out_0_bits_preDecodeInfo_isRVC) +
    $bits(io_out_0_bits_preDecodeInfo_brType) + $bits(io_out_0_bits_preDecodeInfo_isCall) + $bits(io_out_0_bits_preDecodeInfo_isRet) + $bits(io_out_0_bits_pred_taken) +
    $bits(io_out_0_bits_crossPageIPFFix) + $bits(io_out_0_bits_ftqPtr_flag) + $bits(io_out_0_bits_ftqPtr_value) + $bits(io_out_0_bits_ftqOffset) +
    $bits(io_out_0_bits_satpFlushFirstFetchFault) + $bits(io_out_0_bits_srcType_0) + $bits(io_out_0_bits_srcType_1) + $bits(io_out_0_bits_srcType_2) +
    $bits(io_out_0_bits_srcType_3) + $bits(io_out_0_bits_srcType_4) + $bits(io_out_0_bits_ldest) + $bits(io_out_0_bits_fuType) +
    $bits(io_out_0_bits_fuOpType) + $bits(io_out_0_bits_rfWen) + $bits(io_out_0_bits_fpWen) + $bits(io_out_0_bits_vecWen) +
    $bits(io_out_0_bits_v0Wen) + $bits(io_out_0_bits_vlWen) + $bits(io_out_0_bits_isXSTrap) + $bits(io_out_0_bits_waitForward) +
    $bits(io_out_0_bits_blockBackward) + $bits(io_out_0_bits_flushPipe) + $bits(io_out_0_bits_canRobCompress) + $bits(io_out_0_bits_selImm) +
    $bits(io_out_0_bits_imm) + $bits(io_out_0_bits_fpu_typeTagOut) + $bits(io_out_0_bits_fpu_wflags) + $bits(io_out_0_bits_fpu_typ) +
    $bits(io_out_0_bits_fpu_fmt) + $bits(io_out_0_bits_fpu_rm) + $bits(io_out_0_bits_vpu_vill) + $bits(io_out_0_bits_vpu_vma) +
    $bits(io_out_0_bits_vpu_vta) + $bits(io_out_0_bits_vpu_vsew) + $bits(io_out_0_bits_vpu_vlmul) + $bits(io_out_0_bits_vpu_specVill) +
    $bits(io_out_0_bits_vpu_specVma) + $bits(io_out_0_bits_vpu_specVta) + $bits(io_out_0_bits_vpu_specVsew) + $bits(io_out_0_bits_vpu_specVlmul) +
    $bits(io_out_0_bits_vpu_vm) + $bits(io_out_0_bits_vpu_vstart) + $bits(io_out_0_bits_vpu_frm) + $bits(io_out_0_bits_vpu_fpu_isFpToVecInst) +
    $bits(io_out_0_bits_vpu_fpu_isFP32Instr) + $bits(io_out_0_bits_vpu_fpu_isFP64Instr) + $bits(io_out_0_bits_vpu_fpu_isReduction) + $bits(io_out_0_bits_vpu_fpu_isFoldTo1_2) +
    $bits(io_out_0_bits_vpu_fpu_isFoldTo1_4) + $bits(io_out_0_bits_vpu_fpu_isFoldTo1_8) + $bits(io_out_0_bits_vpu_vxrm) + $bits(io_out_0_bits_vpu_vuopIdx) +
    $bits(io_out_0_bits_vpu_lastUop) + $bits(io_out_0_bits_vpu_vmask) + $bits(io_out_0_bits_vpu_vl) + $bits(io_out_0_bits_vpu_nf) +
    $bits(io_out_0_bits_vpu_veew) + $bits(io_out_0_bits_vpu_isReverse) + $bits(io_out_0_bits_vpu_isExt) + $bits(io_out_0_bits_vpu_isNarrow) +
    $bits(io_out_0_bits_vpu_isDstMask) + $bits(io_out_0_bits_vpu_isOpMask) + $bits(io_out_0_bits_vpu_isMove) + $bits(io_out_0_bits_vpu_isDependOldVd) +
    $bits(io_out_0_bits_vpu_isWritePartVd) + $bits(io_out_0_bits_vpu_isVleff) + $bits(io_out_0_bits_vlsInstr) + $bits(io_out_0_bits_wfflags) +
    $bits(io_out_0_bits_isMove) + $bits(io_out_0_bits_uopIdx) + $bits(io_out_0_bits_isVset) + $bits(io_out_0_bits_firstUop) +
    $bits(io_out_0_bits_lastUop) + $bits(io_out_0_bits_numUops) + $bits(io_out_0_bits_numWB) + $bits(io_out_0_bits_commitType) +
    $bits(io_out_0_bits_psrc_0) + $bits(io_out_0_bits_psrc_1) + $bits(io_out_0_bits_psrc_2) + $bits(io_out_0_bits_psrc_3) +
    $bits(io_out_0_bits_psrc_4) + $bits(io_out_0_bits_pdest) + $bits(io_out_0_bits_robIdx_flag) + $bits(io_out_0_bits_robIdx_value) +
    $bits(io_out_0_bits_instrSize) + $bits(io_out_0_bits_dirtyFs) + $bits(io_out_0_bits_dirtyVs) + $bits(io_out_0_bits_traceBlockInPipe_itype) +
    $bits(io_out_0_bits_traceBlockInPipe_iretire) + $bits(io_out_0_bits_traceBlockInPipe_ilastsize) + $bits(io_out_0_bits_eliminatedMove) + $bits(io_out_0_bits_snapshot) +
    $bits(io_out_0_bits_debugInfo_renameTime) + $bits(io_out_0_bits_debug_seqNum_seqNum) + $bits(io_out_0_bits_debug_seqNum_uopIdx) + $bits(io_out_0_bits_debug_fuType) +
    $bits(io_out_0_bits_debug_sim_trig) + $bits(io_out_0_bits_numLsElem);
  localparam int unsigned IN1_PORT_BITS =
    $bits(io_in_1_bits_instr) + $bits(io_in_1_bits_pc) + $bits(io_in_1_bits_foldpc) + $bits(io_in_1_bits_exceptionVec_0) +
    $bits(io_in_1_bits_exceptionVec_1) + $bits(io_in_1_bits_exceptionVec_2) + $bits(io_in_1_bits_exceptionVec_3) + $bits(io_in_1_bits_exceptionVec_4) +
    $bits(io_in_1_bits_exceptionVec_5) + $bits(io_in_1_bits_exceptionVec_6) + $bits(io_in_1_bits_exceptionVec_7) + $bits(io_in_1_bits_exceptionVec_8) +
    $bits(io_in_1_bits_exceptionVec_9) + $bits(io_in_1_bits_exceptionVec_10) + $bits(io_in_1_bits_exceptionVec_11) + $bits(io_in_1_bits_exceptionVec_12) +
    $bits(io_in_1_bits_exceptionVec_13) + $bits(io_in_1_bits_exceptionVec_14) + $bits(io_in_1_bits_exceptionVec_15) + $bits(io_in_1_bits_exceptionVec_16) +
    $bits(io_in_1_bits_exceptionVec_17) + $bits(io_in_1_bits_exceptionVec_18) + $bits(io_in_1_bits_exceptionVec_19) + $bits(io_in_1_bits_exceptionVec_20) +
    $bits(io_in_1_bits_exceptionVec_21) + $bits(io_in_1_bits_exceptionVec_22) + $bits(io_in_1_bits_exceptionVec_23) + $bits(io_in_1_bits_isFetchMalAddr) +
    $bits(io_in_1_bits_hasException) + $bits(io_in_1_bits_trigger) + $bits(io_in_1_bits_preDecodeInfo_valid) + $bits(io_in_1_bits_preDecodeInfo_isRVC) +
    $bits(io_in_1_bits_preDecodeInfo_brType) + $bits(io_in_1_bits_preDecodeInfo_isCall) + $bits(io_in_1_bits_preDecodeInfo_isRet) + $bits(io_in_1_bits_pred_taken) +
    $bits(io_in_1_bits_crossPageIPFFix) + $bits(io_in_1_bits_ftqPtr_flag) + $bits(io_in_1_bits_ftqPtr_value) + $bits(io_in_1_bits_ftqOffset) +
    $bits(io_in_1_bits_satpFlushFirstFetchFault) + $bits(io_in_1_bits_srcType_0) + $bits(io_in_1_bits_srcType_1) + $bits(io_in_1_bits_srcType_2) +
    $bits(io_in_1_bits_srcType_3) + $bits(io_in_1_bits_srcType_4) + $bits(io_in_1_bits_ldest) + $bits(io_in_1_bits_fuType) +
    $bits(io_in_1_bits_fuOpType) + $bits(io_in_1_bits_rfWen) + $bits(io_in_1_bits_fpWen) + $bits(io_in_1_bits_vecWen) +
    $bits(io_in_1_bits_v0Wen) + $bits(io_in_1_bits_vlWen) + $bits(io_in_1_bits_isXSTrap) + $bits(io_in_1_bits_waitForward) +
    $bits(io_in_1_bits_blockBackward) + $bits(io_in_1_bits_flushPipe) + $bits(io_in_1_bits_canRobCompress) + $bits(io_in_1_bits_selImm) +
    $bits(io_in_1_bits_imm) + $bits(io_in_1_bits_fpu_typeTagOut) + $bits(io_in_1_bits_fpu_wflags) + $bits(io_in_1_bits_fpu_typ) +
    $bits(io_in_1_bits_fpu_fmt) + $bits(io_in_1_bits_fpu_rm) + $bits(io_in_1_bits_vpu_vill) + $bits(io_in_1_bits_vpu_vma) +
    $bits(io_in_1_bits_vpu_vta) + $bits(io_in_1_bits_vpu_vsew) + $bits(io_in_1_bits_vpu_vlmul) + $bits(io_in_1_bits_vpu_specVill) +
    $bits(io_in_1_bits_vpu_specVma) + $bits(io_in_1_bits_vpu_specVta) + $bits(io_in_1_bits_vpu_specVsew) + $bits(io_in_1_bits_vpu_specVlmul) +
    $bits(io_in_1_bits_vpu_vm) + $bits(io_in_1_bits_vpu_vstart) + $bits(io_in_1_bits_vpu_frm) + $bits(io_in_1_bits_vpu_fpu_isFpToVecInst) +
    $bits(io_in_1_bits_vpu_fpu_isFP32Instr) + $bits(io_in_1_bits_vpu_fpu_isFP64Instr) + $bits(io_in_1_bits_vpu_fpu_isReduction) + $bits(io_in_1_bits_vpu_fpu_isFoldTo1_2) +
    $bits(io_in_1_bits_vpu_fpu_isFoldTo1_4) + $bits(io_in_1_bits_vpu_fpu_isFoldTo1_8) + $bits(io_in_1_bits_vpu_vxrm) + $bits(io_in_1_bits_vpu_vuopIdx) +
    $bits(io_in_1_bits_vpu_lastUop) + $bits(io_in_1_bits_vpu_vmask) + $bits(io_in_1_bits_vpu_vl) + $bits(io_in_1_bits_vpu_nf) +
    $bits(io_in_1_bits_vpu_veew) + $bits(io_in_1_bits_vpu_isReverse) + $bits(io_in_1_bits_vpu_isExt) + $bits(io_in_1_bits_vpu_isNarrow) +
    $bits(io_in_1_bits_vpu_isDstMask) + $bits(io_in_1_bits_vpu_isOpMask) + $bits(io_in_1_bits_vpu_isMove) + $bits(io_in_1_bits_vpu_isDependOldVd) +
    $bits(io_in_1_bits_vpu_isWritePartVd) + $bits(io_in_1_bits_vpu_isVleff) + $bits(io_in_1_bits_vlsInstr) + $bits(io_in_1_bits_wfflags) +
    $bits(io_in_1_bits_isMove) + $bits(io_in_1_bits_uopIdx) + $bits(io_in_1_bits_isVset) + $bits(io_in_1_bits_firstUop) +
    $bits(io_in_1_bits_lastUop) + $bits(io_in_1_bits_numUops) + $bits(io_in_1_bits_numWB) + $bits(io_in_1_bits_commitType) +
    $bits(io_in_1_bits_psrc_0) + $bits(io_in_1_bits_psrc_1) + $bits(io_in_1_bits_psrc_2) + $bits(io_in_1_bits_psrc_3) +
    $bits(io_in_1_bits_psrc_4) + $bits(io_in_1_bits_pdest) + $bits(io_in_1_bits_robIdx_flag) + $bits(io_in_1_bits_robIdx_value) +
    $bits(io_in_1_bits_instrSize) + $bits(io_in_1_bits_dirtyFs) + $bits(io_in_1_bits_dirtyVs) + $bits(io_in_1_bits_traceBlockInPipe_itype) +
    $bits(io_in_1_bits_traceBlockInPipe_iretire) + $bits(io_in_1_bits_traceBlockInPipe_ilastsize) + $bits(io_in_1_bits_eliminatedMove) + $bits(io_in_1_bits_debugInfo_renameTime) +
    $bits(io_in_1_bits_debug_seqNum_seqNum) + $bits(io_in_1_bits_debug_seqNum_uopIdx) + $bits(io_in_1_bits_debug_fuType) + $bits(io_in_1_bits_debug_sim_trig) +
    $bits(io_in_1_bits_numLsElem);
  localparam int unsigned OUT1_PORT_BITS =
    $bits(io_out_1_bits_instr) + $bits(io_out_1_bits_pc) + $bits(io_out_1_bits_foldpc) + $bits(io_out_1_bits_exceptionVec_0) +
    $bits(io_out_1_bits_exceptionVec_1) + $bits(io_out_1_bits_exceptionVec_2) + $bits(io_out_1_bits_exceptionVec_3) + $bits(io_out_1_bits_exceptionVec_4) +
    $bits(io_out_1_bits_exceptionVec_5) + $bits(io_out_1_bits_exceptionVec_6) + $bits(io_out_1_bits_exceptionVec_7) + $bits(io_out_1_bits_exceptionVec_8) +
    $bits(io_out_1_bits_exceptionVec_9) + $bits(io_out_1_bits_exceptionVec_10) + $bits(io_out_1_bits_exceptionVec_11) + $bits(io_out_1_bits_exceptionVec_12) +
    $bits(io_out_1_bits_exceptionVec_13) + $bits(io_out_1_bits_exceptionVec_14) + $bits(io_out_1_bits_exceptionVec_15) + $bits(io_out_1_bits_exceptionVec_16) +
    $bits(io_out_1_bits_exceptionVec_17) + $bits(io_out_1_bits_exceptionVec_18) + $bits(io_out_1_bits_exceptionVec_19) + $bits(io_out_1_bits_exceptionVec_20) +
    $bits(io_out_1_bits_exceptionVec_21) + $bits(io_out_1_bits_exceptionVec_22) + $bits(io_out_1_bits_exceptionVec_23) + $bits(io_out_1_bits_isFetchMalAddr) +
    $bits(io_out_1_bits_hasException) + $bits(io_out_1_bits_trigger) + $bits(io_out_1_bits_preDecodeInfo_valid) + $bits(io_out_1_bits_preDecodeInfo_isRVC) +
    $bits(io_out_1_bits_preDecodeInfo_brType) + $bits(io_out_1_bits_preDecodeInfo_isCall) + $bits(io_out_1_bits_preDecodeInfo_isRet) + $bits(io_out_1_bits_pred_taken) +
    $bits(io_out_1_bits_crossPageIPFFix) + $bits(io_out_1_bits_ftqPtr_flag) + $bits(io_out_1_bits_ftqPtr_value) + $bits(io_out_1_bits_ftqOffset) +
    $bits(io_out_1_bits_satpFlushFirstFetchFault) + $bits(io_out_1_bits_srcType_0) + $bits(io_out_1_bits_srcType_1) + $bits(io_out_1_bits_srcType_2) +
    $bits(io_out_1_bits_srcType_3) + $bits(io_out_1_bits_srcType_4) + $bits(io_out_1_bits_ldest) + $bits(io_out_1_bits_fuType) +
    $bits(io_out_1_bits_fuOpType) + $bits(io_out_1_bits_rfWen) + $bits(io_out_1_bits_fpWen) + $bits(io_out_1_bits_vecWen) +
    $bits(io_out_1_bits_v0Wen) + $bits(io_out_1_bits_vlWen) + $bits(io_out_1_bits_isXSTrap) + $bits(io_out_1_bits_waitForward) +
    $bits(io_out_1_bits_blockBackward) + $bits(io_out_1_bits_flushPipe) + $bits(io_out_1_bits_canRobCompress) + $bits(io_out_1_bits_selImm) +
    $bits(io_out_1_bits_imm) + $bits(io_out_1_bits_fpu_typeTagOut) + $bits(io_out_1_bits_fpu_wflags) + $bits(io_out_1_bits_fpu_typ) +
    $bits(io_out_1_bits_fpu_fmt) + $bits(io_out_1_bits_fpu_rm) + $bits(io_out_1_bits_vpu_vill) + $bits(io_out_1_bits_vpu_vma) +
    $bits(io_out_1_bits_vpu_vta) + $bits(io_out_1_bits_vpu_vsew) + $bits(io_out_1_bits_vpu_vlmul) + $bits(io_out_1_bits_vpu_specVill) +
    $bits(io_out_1_bits_vpu_specVma) + $bits(io_out_1_bits_vpu_specVta) + $bits(io_out_1_bits_vpu_specVsew) + $bits(io_out_1_bits_vpu_specVlmul) +
    $bits(io_out_1_bits_vpu_vm) + $bits(io_out_1_bits_vpu_vstart) + $bits(io_out_1_bits_vpu_frm) + $bits(io_out_1_bits_vpu_fpu_isFpToVecInst) +
    $bits(io_out_1_bits_vpu_fpu_isFP32Instr) + $bits(io_out_1_bits_vpu_fpu_isFP64Instr) + $bits(io_out_1_bits_vpu_fpu_isReduction) + $bits(io_out_1_bits_vpu_fpu_isFoldTo1_2) +
    $bits(io_out_1_bits_vpu_fpu_isFoldTo1_4) + $bits(io_out_1_bits_vpu_fpu_isFoldTo1_8) + $bits(io_out_1_bits_vpu_vxrm) + $bits(io_out_1_bits_vpu_vuopIdx) +
    $bits(io_out_1_bits_vpu_lastUop) + $bits(io_out_1_bits_vpu_vmask) + $bits(io_out_1_bits_vpu_vl) + $bits(io_out_1_bits_vpu_nf) +
    $bits(io_out_1_bits_vpu_veew) + $bits(io_out_1_bits_vpu_isReverse) + $bits(io_out_1_bits_vpu_isExt) + $bits(io_out_1_bits_vpu_isNarrow) +
    $bits(io_out_1_bits_vpu_isDstMask) + $bits(io_out_1_bits_vpu_isOpMask) + $bits(io_out_1_bits_vpu_isMove) + $bits(io_out_1_bits_vpu_isDependOldVd) +
    $bits(io_out_1_bits_vpu_isWritePartVd) + $bits(io_out_1_bits_vpu_isVleff) + $bits(io_out_1_bits_vlsInstr) + $bits(io_out_1_bits_wfflags) +
    $bits(io_out_1_bits_isMove) + $bits(io_out_1_bits_uopIdx) + $bits(io_out_1_bits_isVset) + $bits(io_out_1_bits_firstUop) +
    $bits(io_out_1_bits_lastUop) + $bits(io_out_1_bits_numUops) + $bits(io_out_1_bits_numWB) + $bits(io_out_1_bits_commitType) +
    $bits(io_out_1_bits_psrc_0) + $bits(io_out_1_bits_psrc_1) + $bits(io_out_1_bits_psrc_2) + $bits(io_out_1_bits_psrc_3) +
    $bits(io_out_1_bits_psrc_4) + $bits(io_out_1_bits_pdest) + $bits(io_out_1_bits_robIdx_flag) + $bits(io_out_1_bits_robIdx_value) +
    $bits(io_out_1_bits_instrSize) + $bits(io_out_1_bits_dirtyFs) + $bits(io_out_1_bits_dirtyVs) + $bits(io_out_1_bits_traceBlockInPipe_itype) +
    $bits(io_out_1_bits_traceBlockInPipe_iretire) + $bits(io_out_1_bits_traceBlockInPipe_ilastsize) + $bits(io_out_1_bits_eliminatedMove) + $bits(io_out_1_bits_debugInfo_renameTime) +
    $bits(io_out_1_bits_debug_seqNum_seqNum) + $bits(io_out_1_bits_debug_seqNum_uopIdx) + $bits(io_out_1_bits_debug_fuType) + $bits(io_out_1_bits_debug_sim_trig) +
    $bits(io_out_1_bits_numLsElem);
  localparam int unsigned IN2_PORT_BITS =
    $bits(io_in_2_bits_instr) + $bits(io_in_2_bits_pc) + $bits(io_in_2_bits_foldpc) + $bits(io_in_2_bits_exceptionVec_0) +
    $bits(io_in_2_bits_exceptionVec_1) + $bits(io_in_2_bits_exceptionVec_2) + $bits(io_in_2_bits_exceptionVec_3) + $bits(io_in_2_bits_exceptionVec_4) +
    $bits(io_in_2_bits_exceptionVec_5) + $bits(io_in_2_bits_exceptionVec_6) + $bits(io_in_2_bits_exceptionVec_7) + $bits(io_in_2_bits_exceptionVec_8) +
    $bits(io_in_2_bits_exceptionVec_9) + $bits(io_in_2_bits_exceptionVec_10) + $bits(io_in_2_bits_exceptionVec_11) + $bits(io_in_2_bits_exceptionVec_12) +
    $bits(io_in_2_bits_exceptionVec_13) + $bits(io_in_2_bits_exceptionVec_14) + $bits(io_in_2_bits_exceptionVec_15) + $bits(io_in_2_bits_exceptionVec_16) +
    $bits(io_in_2_bits_exceptionVec_17) + $bits(io_in_2_bits_exceptionVec_18) + $bits(io_in_2_bits_exceptionVec_19) + $bits(io_in_2_bits_exceptionVec_20) +
    $bits(io_in_2_bits_exceptionVec_21) + $bits(io_in_2_bits_exceptionVec_22) + $bits(io_in_2_bits_exceptionVec_23) + $bits(io_in_2_bits_isFetchMalAddr) +
    $bits(io_in_2_bits_hasException) + $bits(io_in_2_bits_trigger) + $bits(io_in_2_bits_preDecodeInfo_valid) + $bits(io_in_2_bits_preDecodeInfo_isRVC) +
    $bits(io_in_2_bits_preDecodeInfo_brType) + $bits(io_in_2_bits_preDecodeInfo_isCall) + $bits(io_in_2_bits_preDecodeInfo_isRet) + $bits(io_in_2_bits_pred_taken) +
    $bits(io_in_2_bits_crossPageIPFFix) + $bits(io_in_2_bits_ftqPtr_flag) + $bits(io_in_2_bits_ftqPtr_value) + $bits(io_in_2_bits_ftqOffset) +
    $bits(io_in_2_bits_satpFlushFirstFetchFault) + $bits(io_in_2_bits_srcType_0) + $bits(io_in_2_bits_srcType_1) + $bits(io_in_2_bits_srcType_2) +
    $bits(io_in_2_bits_srcType_3) + $bits(io_in_2_bits_srcType_4) + $bits(io_in_2_bits_ldest) + $bits(io_in_2_bits_fuType) +
    $bits(io_in_2_bits_fuOpType) + $bits(io_in_2_bits_rfWen) + $bits(io_in_2_bits_fpWen) + $bits(io_in_2_bits_vecWen) +
    $bits(io_in_2_bits_v0Wen) + $bits(io_in_2_bits_vlWen) + $bits(io_in_2_bits_isXSTrap) + $bits(io_in_2_bits_waitForward) +
    $bits(io_in_2_bits_blockBackward) + $bits(io_in_2_bits_flushPipe) + $bits(io_in_2_bits_canRobCompress) + $bits(io_in_2_bits_selImm) +
    $bits(io_in_2_bits_imm) + $bits(io_in_2_bits_fpu_typeTagOut) + $bits(io_in_2_bits_fpu_wflags) + $bits(io_in_2_bits_fpu_typ) +
    $bits(io_in_2_bits_fpu_fmt) + $bits(io_in_2_bits_fpu_rm) + $bits(io_in_2_bits_vpu_vill) + $bits(io_in_2_bits_vpu_vma) +
    $bits(io_in_2_bits_vpu_vta) + $bits(io_in_2_bits_vpu_vsew) + $bits(io_in_2_bits_vpu_vlmul) + $bits(io_in_2_bits_vpu_specVill) +
    $bits(io_in_2_bits_vpu_specVma) + $bits(io_in_2_bits_vpu_specVta) + $bits(io_in_2_bits_vpu_specVsew) + $bits(io_in_2_bits_vpu_specVlmul) +
    $bits(io_in_2_bits_vpu_vm) + $bits(io_in_2_bits_vpu_vstart) + $bits(io_in_2_bits_vpu_frm) + $bits(io_in_2_bits_vpu_fpu_isFpToVecInst) +
    $bits(io_in_2_bits_vpu_fpu_isFP32Instr) + $bits(io_in_2_bits_vpu_fpu_isFP64Instr) + $bits(io_in_2_bits_vpu_fpu_isReduction) + $bits(io_in_2_bits_vpu_fpu_isFoldTo1_2) +
    $bits(io_in_2_bits_vpu_fpu_isFoldTo1_4) + $bits(io_in_2_bits_vpu_fpu_isFoldTo1_8) + $bits(io_in_2_bits_vpu_vxrm) + $bits(io_in_2_bits_vpu_vuopIdx) +
    $bits(io_in_2_bits_vpu_lastUop) + $bits(io_in_2_bits_vpu_vmask) + $bits(io_in_2_bits_vpu_vl) + $bits(io_in_2_bits_vpu_nf) +
    $bits(io_in_2_bits_vpu_veew) + $bits(io_in_2_bits_vpu_isReverse) + $bits(io_in_2_bits_vpu_isExt) + $bits(io_in_2_bits_vpu_isNarrow) +
    $bits(io_in_2_bits_vpu_isDstMask) + $bits(io_in_2_bits_vpu_isOpMask) + $bits(io_in_2_bits_vpu_isMove) + $bits(io_in_2_bits_vpu_isDependOldVd) +
    $bits(io_in_2_bits_vpu_isWritePartVd) + $bits(io_in_2_bits_vpu_isVleff) + $bits(io_in_2_bits_vlsInstr) + $bits(io_in_2_bits_wfflags) +
    $bits(io_in_2_bits_isMove) + $bits(io_in_2_bits_uopIdx) + $bits(io_in_2_bits_isVset) + $bits(io_in_2_bits_firstUop) +
    $bits(io_in_2_bits_lastUop) + $bits(io_in_2_bits_numUops) + $bits(io_in_2_bits_numWB) + $bits(io_in_2_bits_commitType) +
    $bits(io_in_2_bits_psrc_0) + $bits(io_in_2_bits_psrc_1) + $bits(io_in_2_bits_psrc_2) + $bits(io_in_2_bits_psrc_3) +
    $bits(io_in_2_bits_psrc_4) + $bits(io_in_2_bits_pdest) + $bits(io_in_2_bits_robIdx_flag) + $bits(io_in_2_bits_robIdx_value) +
    $bits(io_in_2_bits_instrSize) + $bits(io_in_2_bits_dirtyFs) + $bits(io_in_2_bits_dirtyVs) + $bits(io_in_2_bits_traceBlockInPipe_itype) +
    $bits(io_in_2_bits_traceBlockInPipe_iretire) + $bits(io_in_2_bits_traceBlockInPipe_ilastsize) + $bits(io_in_2_bits_eliminatedMove) + $bits(io_in_2_bits_debugInfo_renameTime) +
    $bits(io_in_2_bits_debug_seqNum_seqNum) + $bits(io_in_2_bits_debug_seqNum_uopIdx) + $bits(io_in_2_bits_debug_fuType) + $bits(io_in_2_bits_debug_sim_trig) +
    $bits(io_in_2_bits_numLsElem);
  localparam int unsigned OUT2_PORT_BITS =
    $bits(io_out_2_bits_instr) + $bits(io_out_2_bits_pc) + $bits(io_out_2_bits_foldpc) + $bits(io_out_2_bits_exceptionVec_0) +
    $bits(io_out_2_bits_exceptionVec_1) + $bits(io_out_2_bits_exceptionVec_2) + $bits(io_out_2_bits_exceptionVec_3) + $bits(io_out_2_bits_exceptionVec_4) +
    $bits(io_out_2_bits_exceptionVec_5) + $bits(io_out_2_bits_exceptionVec_6) + $bits(io_out_2_bits_exceptionVec_7) + $bits(io_out_2_bits_exceptionVec_8) +
    $bits(io_out_2_bits_exceptionVec_9) + $bits(io_out_2_bits_exceptionVec_10) + $bits(io_out_2_bits_exceptionVec_11) + $bits(io_out_2_bits_exceptionVec_12) +
    $bits(io_out_2_bits_exceptionVec_13) + $bits(io_out_2_bits_exceptionVec_14) + $bits(io_out_2_bits_exceptionVec_15) + $bits(io_out_2_bits_exceptionVec_16) +
    $bits(io_out_2_bits_exceptionVec_17) + $bits(io_out_2_bits_exceptionVec_18) + $bits(io_out_2_bits_exceptionVec_19) + $bits(io_out_2_bits_exceptionVec_20) +
    $bits(io_out_2_bits_exceptionVec_21) + $bits(io_out_2_bits_exceptionVec_22) + $bits(io_out_2_bits_exceptionVec_23) + $bits(io_out_2_bits_isFetchMalAddr) +
    $bits(io_out_2_bits_hasException) + $bits(io_out_2_bits_trigger) + $bits(io_out_2_bits_preDecodeInfo_valid) + $bits(io_out_2_bits_preDecodeInfo_isRVC) +
    $bits(io_out_2_bits_preDecodeInfo_brType) + $bits(io_out_2_bits_preDecodeInfo_isCall) + $bits(io_out_2_bits_preDecodeInfo_isRet) + $bits(io_out_2_bits_pred_taken) +
    $bits(io_out_2_bits_crossPageIPFFix) + $bits(io_out_2_bits_ftqPtr_flag) + $bits(io_out_2_bits_ftqPtr_value) + $bits(io_out_2_bits_ftqOffset) +
    $bits(io_out_2_bits_satpFlushFirstFetchFault) + $bits(io_out_2_bits_srcType_0) + $bits(io_out_2_bits_srcType_1) + $bits(io_out_2_bits_srcType_2) +
    $bits(io_out_2_bits_srcType_3) + $bits(io_out_2_bits_srcType_4) + $bits(io_out_2_bits_ldest) + $bits(io_out_2_bits_fuType) +
    $bits(io_out_2_bits_fuOpType) + $bits(io_out_2_bits_rfWen) + $bits(io_out_2_bits_fpWen) + $bits(io_out_2_bits_vecWen) +
    $bits(io_out_2_bits_v0Wen) + $bits(io_out_2_bits_vlWen) + $bits(io_out_2_bits_isXSTrap) + $bits(io_out_2_bits_waitForward) +
    $bits(io_out_2_bits_blockBackward) + $bits(io_out_2_bits_flushPipe) + $bits(io_out_2_bits_canRobCompress) + $bits(io_out_2_bits_selImm) +
    $bits(io_out_2_bits_imm) + $bits(io_out_2_bits_fpu_typeTagOut) + $bits(io_out_2_bits_fpu_wflags) + $bits(io_out_2_bits_fpu_typ) +
    $bits(io_out_2_bits_fpu_fmt) + $bits(io_out_2_bits_fpu_rm) + $bits(io_out_2_bits_vpu_vill) + $bits(io_out_2_bits_vpu_vma) +
    $bits(io_out_2_bits_vpu_vta) + $bits(io_out_2_bits_vpu_vsew) + $bits(io_out_2_bits_vpu_vlmul) + $bits(io_out_2_bits_vpu_specVill) +
    $bits(io_out_2_bits_vpu_specVma) + $bits(io_out_2_bits_vpu_specVta) + $bits(io_out_2_bits_vpu_specVsew) + $bits(io_out_2_bits_vpu_specVlmul) +
    $bits(io_out_2_bits_vpu_vm) + $bits(io_out_2_bits_vpu_vstart) + $bits(io_out_2_bits_vpu_frm) + $bits(io_out_2_bits_vpu_fpu_isFpToVecInst) +
    $bits(io_out_2_bits_vpu_fpu_isFP32Instr) + $bits(io_out_2_bits_vpu_fpu_isFP64Instr) + $bits(io_out_2_bits_vpu_fpu_isReduction) + $bits(io_out_2_bits_vpu_fpu_isFoldTo1_2) +
    $bits(io_out_2_bits_vpu_fpu_isFoldTo1_4) + $bits(io_out_2_bits_vpu_fpu_isFoldTo1_8) + $bits(io_out_2_bits_vpu_vxrm) + $bits(io_out_2_bits_vpu_vuopIdx) +
    $bits(io_out_2_bits_vpu_lastUop) + $bits(io_out_2_bits_vpu_vmask) + $bits(io_out_2_bits_vpu_vl) + $bits(io_out_2_bits_vpu_nf) +
    $bits(io_out_2_bits_vpu_veew) + $bits(io_out_2_bits_vpu_isReverse) + $bits(io_out_2_bits_vpu_isExt) + $bits(io_out_2_bits_vpu_isNarrow) +
    $bits(io_out_2_bits_vpu_isDstMask) + $bits(io_out_2_bits_vpu_isOpMask) + $bits(io_out_2_bits_vpu_isMove) + $bits(io_out_2_bits_vpu_isDependOldVd) +
    $bits(io_out_2_bits_vpu_isWritePartVd) + $bits(io_out_2_bits_vpu_isVleff) + $bits(io_out_2_bits_vlsInstr) + $bits(io_out_2_bits_wfflags) +
    $bits(io_out_2_bits_isMove) + $bits(io_out_2_bits_uopIdx) + $bits(io_out_2_bits_isVset) + $bits(io_out_2_bits_firstUop) +
    $bits(io_out_2_bits_lastUop) + $bits(io_out_2_bits_numUops) + $bits(io_out_2_bits_numWB) + $bits(io_out_2_bits_commitType) +
    $bits(io_out_2_bits_psrc_0) + $bits(io_out_2_bits_psrc_1) + $bits(io_out_2_bits_psrc_2) + $bits(io_out_2_bits_psrc_3) +
    $bits(io_out_2_bits_psrc_4) + $bits(io_out_2_bits_pdest) + $bits(io_out_2_bits_robIdx_flag) + $bits(io_out_2_bits_robIdx_value) +
    $bits(io_out_2_bits_instrSize) + $bits(io_out_2_bits_dirtyFs) + $bits(io_out_2_bits_dirtyVs) + $bits(io_out_2_bits_traceBlockInPipe_itype) +
    $bits(io_out_2_bits_traceBlockInPipe_iretire) + $bits(io_out_2_bits_traceBlockInPipe_ilastsize) + $bits(io_out_2_bits_eliminatedMove) + $bits(io_out_2_bits_debugInfo_renameTime) +
    $bits(io_out_2_bits_debug_seqNum_seqNum) + $bits(io_out_2_bits_debug_seqNum_uopIdx) + $bits(io_out_2_bits_debug_fuType) + $bits(io_out_2_bits_debug_sim_trig) +
    $bits(io_out_2_bits_numLsElem);
  localparam int unsigned IN3_PORT_BITS =
    $bits(io_in_3_bits_instr) + $bits(io_in_3_bits_pc) + $bits(io_in_3_bits_foldpc) + $bits(io_in_3_bits_exceptionVec_0) +
    $bits(io_in_3_bits_exceptionVec_1) + $bits(io_in_3_bits_exceptionVec_2) + $bits(io_in_3_bits_exceptionVec_3) + $bits(io_in_3_bits_exceptionVec_4) +
    $bits(io_in_3_bits_exceptionVec_5) + $bits(io_in_3_bits_exceptionVec_6) + $bits(io_in_3_bits_exceptionVec_7) + $bits(io_in_3_bits_exceptionVec_8) +
    $bits(io_in_3_bits_exceptionVec_9) + $bits(io_in_3_bits_exceptionVec_10) + $bits(io_in_3_bits_exceptionVec_11) + $bits(io_in_3_bits_exceptionVec_12) +
    $bits(io_in_3_bits_exceptionVec_13) + $bits(io_in_3_bits_exceptionVec_14) + $bits(io_in_3_bits_exceptionVec_15) + $bits(io_in_3_bits_exceptionVec_16) +
    $bits(io_in_3_bits_exceptionVec_17) + $bits(io_in_3_bits_exceptionVec_18) + $bits(io_in_3_bits_exceptionVec_19) + $bits(io_in_3_bits_exceptionVec_20) +
    $bits(io_in_3_bits_exceptionVec_21) + $bits(io_in_3_bits_exceptionVec_22) + $bits(io_in_3_bits_exceptionVec_23) + $bits(io_in_3_bits_isFetchMalAddr) +
    $bits(io_in_3_bits_hasException) + $bits(io_in_3_bits_trigger) + $bits(io_in_3_bits_preDecodeInfo_valid) + $bits(io_in_3_bits_preDecodeInfo_isRVC) +
    $bits(io_in_3_bits_preDecodeInfo_brType) + $bits(io_in_3_bits_preDecodeInfo_isCall) + $bits(io_in_3_bits_preDecodeInfo_isRet) + $bits(io_in_3_bits_pred_taken) +
    $bits(io_in_3_bits_crossPageIPFFix) + $bits(io_in_3_bits_ftqPtr_flag) + $bits(io_in_3_bits_ftqPtr_value) + $bits(io_in_3_bits_ftqOffset) +
    $bits(io_in_3_bits_satpFlushFirstFetchFault) + $bits(io_in_3_bits_srcType_0) + $bits(io_in_3_bits_srcType_1) + $bits(io_in_3_bits_srcType_2) +
    $bits(io_in_3_bits_srcType_3) + $bits(io_in_3_bits_srcType_4) + $bits(io_in_3_bits_ldest) + $bits(io_in_3_bits_fuType) +
    $bits(io_in_3_bits_fuOpType) + $bits(io_in_3_bits_rfWen) + $bits(io_in_3_bits_fpWen) + $bits(io_in_3_bits_vecWen) +
    $bits(io_in_3_bits_v0Wen) + $bits(io_in_3_bits_vlWen) + $bits(io_in_3_bits_isXSTrap) + $bits(io_in_3_bits_waitForward) +
    $bits(io_in_3_bits_blockBackward) + $bits(io_in_3_bits_flushPipe) + $bits(io_in_3_bits_canRobCompress) + $bits(io_in_3_bits_selImm) +
    $bits(io_in_3_bits_imm) + $bits(io_in_3_bits_fpu_typeTagOut) + $bits(io_in_3_bits_fpu_wflags) + $bits(io_in_3_bits_fpu_typ) +
    $bits(io_in_3_bits_fpu_fmt) + $bits(io_in_3_bits_fpu_rm) + $bits(io_in_3_bits_vpu_vill) + $bits(io_in_3_bits_vpu_vma) +
    $bits(io_in_3_bits_vpu_vta) + $bits(io_in_3_bits_vpu_vsew) + $bits(io_in_3_bits_vpu_vlmul) + $bits(io_in_3_bits_vpu_specVill) +
    $bits(io_in_3_bits_vpu_specVma) + $bits(io_in_3_bits_vpu_specVta) + $bits(io_in_3_bits_vpu_specVsew) + $bits(io_in_3_bits_vpu_specVlmul) +
    $bits(io_in_3_bits_vpu_vm) + $bits(io_in_3_bits_vpu_vstart) + $bits(io_in_3_bits_vpu_frm) + $bits(io_in_3_bits_vpu_fpu_isFpToVecInst) +
    $bits(io_in_3_bits_vpu_fpu_isFP32Instr) + $bits(io_in_3_bits_vpu_fpu_isFP64Instr) + $bits(io_in_3_bits_vpu_fpu_isReduction) + $bits(io_in_3_bits_vpu_fpu_isFoldTo1_2) +
    $bits(io_in_3_bits_vpu_fpu_isFoldTo1_4) + $bits(io_in_3_bits_vpu_fpu_isFoldTo1_8) + $bits(io_in_3_bits_vpu_vxrm) + $bits(io_in_3_bits_vpu_vuopIdx) +
    $bits(io_in_3_bits_vpu_lastUop) + $bits(io_in_3_bits_vpu_vmask) + $bits(io_in_3_bits_vpu_vl) + $bits(io_in_3_bits_vpu_nf) +
    $bits(io_in_3_bits_vpu_veew) + $bits(io_in_3_bits_vpu_isReverse) + $bits(io_in_3_bits_vpu_isExt) + $bits(io_in_3_bits_vpu_isNarrow) +
    $bits(io_in_3_bits_vpu_isDstMask) + $bits(io_in_3_bits_vpu_isOpMask) + $bits(io_in_3_bits_vpu_isMove) + $bits(io_in_3_bits_vpu_isDependOldVd) +
    $bits(io_in_3_bits_vpu_isWritePartVd) + $bits(io_in_3_bits_vpu_isVleff) + $bits(io_in_3_bits_vlsInstr) + $bits(io_in_3_bits_wfflags) +
    $bits(io_in_3_bits_isMove) + $bits(io_in_3_bits_uopIdx) + $bits(io_in_3_bits_isVset) + $bits(io_in_3_bits_firstUop) +
    $bits(io_in_3_bits_lastUop) + $bits(io_in_3_bits_numUops) + $bits(io_in_3_bits_numWB) + $bits(io_in_3_bits_commitType) +
    $bits(io_in_3_bits_psrc_0) + $bits(io_in_3_bits_psrc_1) + $bits(io_in_3_bits_psrc_2) + $bits(io_in_3_bits_psrc_3) +
    $bits(io_in_3_bits_psrc_4) + $bits(io_in_3_bits_pdest) + $bits(io_in_3_bits_robIdx_flag) + $bits(io_in_3_bits_robIdx_value) +
    $bits(io_in_3_bits_instrSize) + $bits(io_in_3_bits_dirtyFs) + $bits(io_in_3_bits_dirtyVs) + $bits(io_in_3_bits_traceBlockInPipe_itype) +
    $bits(io_in_3_bits_traceBlockInPipe_iretire) + $bits(io_in_3_bits_traceBlockInPipe_ilastsize) + $bits(io_in_3_bits_eliminatedMove) + $bits(io_in_3_bits_debugInfo_renameTime) +
    $bits(io_in_3_bits_debug_seqNum_seqNum) + $bits(io_in_3_bits_debug_seqNum_uopIdx) + $bits(io_in_3_bits_debug_fuType) + $bits(io_in_3_bits_debug_sim_trig) +
    $bits(io_in_3_bits_numLsElem);
  localparam int unsigned OUT3_PORT_BITS =
    $bits(io_out_3_bits_instr) + $bits(io_out_3_bits_pc) + $bits(io_out_3_bits_foldpc) + $bits(io_out_3_bits_exceptionVec_0) +
    $bits(io_out_3_bits_exceptionVec_1) + $bits(io_out_3_bits_exceptionVec_2) + $bits(io_out_3_bits_exceptionVec_3) + $bits(io_out_3_bits_exceptionVec_4) +
    $bits(io_out_3_bits_exceptionVec_5) + $bits(io_out_3_bits_exceptionVec_6) + $bits(io_out_3_bits_exceptionVec_7) + $bits(io_out_3_bits_exceptionVec_8) +
    $bits(io_out_3_bits_exceptionVec_9) + $bits(io_out_3_bits_exceptionVec_10) + $bits(io_out_3_bits_exceptionVec_11) + $bits(io_out_3_bits_exceptionVec_12) +
    $bits(io_out_3_bits_exceptionVec_13) + $bits(io_out_3_bits_exceptionVec_14) + $bits(io_out_3_bits_exceptionVec_15) + $bits(io_out_3_bits_exceptionVec_16) +
    $bits(io_out_3_bits_exceptionVec_17) + $bits(io_out_3_bits_exceptionVec_18) + $bits(io_out_3_bits_exceptionVec_19) + $bits(io_out_3_bits_exceptionVec_20) +
    $bits(io_out_3_bits_exceptionVec_21) + $bits(io_out_3_bits_exceptionVec_22) + $bits(io_out_3_bits_exceptionVec_23) + $bits(io_out_3_bits_isFetchMalAddr) +
    $bits(io_out_3_bits_hasException) + $bits(io_out_3_bits_trigger) + $bits(io_out_3_bits_preDecodeInfo_valid) + $bits(io_out_3_bits_preDecodeInfo_isRVC) +
    $bits(io_out_3_bits_preDecodeInfo_brType) + $bits(io_out_3_bits_preDecodeInfo_isCall) + $bits(io_out_3_bits_preDecodeInfo_isRet) + $bits(io_out_3_bits_pred_taken) +
    $bits(io_out_3_bits_crossPageIPFFix) + $bits(io_out_3_bits_ftqPtr_flag) + $bits(io_out_3_bits_ftqPtr_value) + $bits(io_out_3_bits_ftqOffset) +
    $bits(io_out_3_bits_satpFlushFirstFetchFault) + $bits(io_out_3_bits_srcType_0) + $bits(io_out_3_bits_srcType_1) + $bits(io_out_3_bits_srcType_2) +
    $bits(io_out_3_bits_srcType_3) + $bits(io_out_3_bits_srcType_4) + $bits(io_out_3_bits_ldest) + $bits(io_out_3_bits_fuType) +
    $bits(io_out_3_bits_fuOpType) + $bits(io_out_3_bits_rfWen) + $bits(io_out_3_bits_fpWen) + $bits(io_out_3_bits_vecWen) +
    $bits(io_out_3_bits_v0Wen) + $bits(io_out_3_bits_vlWen) + $bits(io_out_3_bits_isXSTrap) + $bits(io_out_3_bits_waitForward) +
    $bits(io_out_3_bits_blockBackward) + $bits(io_out_3_bits_flushPipe) + $bits(io_out_3_bits_canRobCompress) + $bits(io_out_3_bits_selImm) +
    $bits(io_out_3_bits_imm) + $bits(io_out_3_bits_fpu_typeTagOut) + $bits(io_out_3_bits_fpu_wflags) + $bits(io_out_3_bits_fpu_typ) +
    $bits(io_out_3_bits_fpu_fmt) + $bits(io_out_3_bits_fpu_rm) + $bits(io_out_3_bits_vpu_vill) + $bits(io_out_3_bits_vpu_vma) +
    $bits(io_out_3_bits_vpu_vta) + $bits(io_out_3_bits_vpu_vsew) + $bits(io_out_3_bits_vpu_vlmul) + $bits(io_out_3_bits_vpu_specVill) +
    $bits(io_out_3_bits_vpu_specVma) + $bits(io_out_3_bits_vpu_specVta) + $bits(io_out_3_bits_vpu_specVsew) + $bits(io_out_3_bits_vpu_specVlmul) +
    $bits(io_out_3_bits_vpu_vm) + $bits(io_out_3_bits_vpu_vstart) + $bits(io_out_3_bits_vpu_frm) + $bits(io_out_3_bits_vpu_fpu_isFpToVecInst) +
    $bits(io_out_3_bits_vpu_fpu_isFP32Instr) + $bits(io_out_3_bits_vpu_fpu_isFP64Instr) + $bits(io_out_3_bits_vpu_fpu_isReduction) + $bits(io_out_3_bits_vpu_fpu_isFoldTo1_2) +
    $bits(io_out_3_bits_vpu_fpu_isFoldTo1_4) + $bits(io_out_3_bits_vpu_fpu_isFoldTo1_8) + $bits(io_out_3_bits_vpu_vxrm) + $bits(io_out_3_bits_vpu_vuopIdx) +
    $bits(io_out_3_bits_vpu_lastUop) + $bits(io_out_3_bits_vpu_vmask) + $bits(io_out_3_bits_vpu_vl) + $bits(io_out_3_bits_vpu_nf) +
    $bits(io_out_3_bits_vpu_veew) + $bits(io_out_3_bits_vpu_isReverse) + $bits(io_out_3_bits_vpu_isExt) + $bits(io_out_3_bits_vpu_isNarrow) +
    $bits(io_out_3_bits_vpu_isDstMask) + $bits(io_out_3_bits_vpu_isOpMask) + $bits(io_out_3_bits_vpu_isMove) + $bits(io_out_3_bits_vpu_isDependOldVd) +
    $bits(io_out_3_bits_vpu_isWritePartVd) + $bits(io_out_3_bits_vpu_isVleff) + $bits(io_out_3_bits_vlsInstr) + $bits(io_out_3_bits_wfflags) +
    $bits(io_out_3_bits_isMove) + $bits(io_out_3_bits_uopIdx) + $bits(io_out_3_bits_isVset) + $bits(io_out_3_bits_firstUop) +
    $bits(io_out_3_bits_lastUop) + $bits(io_out_3_bits_numUops) + $bits(io_out_3_bits_numWB) + $bits(io_out_3_bits_commitType) +
    $bits(io_out_3_bits_psrc_0) + $bits(io_out_3_bits_psrc_1) + $bits(io_out_3_bits_psrc_2) + $bits(io_out_3_bits_psrc_3) +
    $bits(io_out_3_bits_psrc_4) + $bits(io_out_3_bits_pdest) + $bits(io_out_3_bits_robIdx_flag) + $bits(io_out_3_bits_robIdx_value) +
    $bits(io_out_3_bits_instrSize) + $bits(io_out_3_bits_dirtyFs) + $bits(io_out_3_bits_dirtyVs) + $bits(io_out_3_bits_traceBlockInPipe_itype) +
    $bits(io_out_3_bits_traceBlockInPipe_iretire) + $bits(io_out_3_bits_traceBlockInPipe_ilastsize) + $bits(io_out_3_bits_eliminatedMove) + $bits(io_out_3_bits_debugInfo_renameTime) +
    $bits(io_out_3_bits_debug_seqNum_seqNum) + $bits(io_out_3_bits_debug_seqNum_uopIdx) + $bits(io_out_3_bits_debug_fuType) + $bits(io_out_3_bits_debug_sim_trig) +
    $bits(io_out_3_bits_numLsElem);
  localparam int unsigned IN4_PORT_BITS =
    $bits(io_in_4_bits_instr) + $bits(io_in_4_bits_pc) + $bits(io_in_4_bits_foldpc) + $bits(io_in_4_bits_exceptionVec_0) +
    $bits(io_in_4_bits_exceptionVec_1) + $bits(io_in_4_bits_exceptionVec_2) + $bits(io_in_4_bits_exceptionVec_3) + $bits(io_in_4_bits_exceptionVec_4) +
    $bits(io_in_4_bits_exceptionVec_5) + $bits(io_in_4_bits_exceptionVec_6) + $bits(io_in_4_bits_exceptionVec_7) + $bits(io_in_4_bits_exceptionVec_8) +
    $bits(io_in_4_bits_exceptionVec_9) + $bits(io_in_4_bits_exceptionVec_10) + $bits(io_in_4_bits_exceptionVec_11) + $bits(io_in_4_bits_exceptionVec_12) +
    $bits(io_in_4_bits_exceptionVec_13) + $bits(io_in_4_bits_exceptionVec_14) + $bits(io_in_4_bits_exceptionVec_15) + $bits(io_in_4_bits_exceptionVec_16) +
    $bits(io_in_4_bits_exceptionVec_17) + $bits(io_in_4_bits_exceptionVec_18) + $bits(io_in_4_bits_exceptionVec_19) + $bits(io_in_4_bits_exceptionVec_20) +
    $bits(io_in_4_bits_exceptionVec_21) + $bits(io_in_4_bits_exceptionVec_22) + $bits(io_in_4_bits_exceptionVec_23) + $bits(io_in_4_bits_isFetchMalAddr) +
    $bits(io_in_4_bits_hasException) + $bits(io_in_4_bits_trigger) + $bits(io_in_4_bits_preDecodeInfo_valid) + $bits(io_in_4_bits_preDecodeInfo_isRVC) +
    $bits(io_in_4_bits_preDecodeInfo_brType) + $bits(io_in_4_bits_preDecodeInfo_isCall) + $bits(io_in_4_bits_preDecodeInfo_isRet) + $bits(io_in_4_bits_pred_taken) +
    $bits(io_in_4_bits_crossPageIPFFix) + $bits(io_in_4_bits_ftqPtr_flag) + $bits(io_in_4_bits_ftqPtr_value) + $bits(io_in_4_bits_ftqOffset) +
    $bits(io_in_4_bits_satpFlushFirstFetchFault) + $bits(io_in_4_bits_srcType_0) + $bits(io_in_4_bits_srcType_1) + $bits(io_in_4_bits_srcType_2) +
    $bits(io_in_4_bits_srcType_3) + $bits(io_in_4_bits_srcType_4) + $bits(io_in_4_bits_ldest) + $bits(io_in_4_bits_fuType) +
    $bits(io_in_4_bits_fuOpType) + $bits(io_in_4_bits_rfWen) + $bits(io_in_4_bits_fpWen) + $bits(io_in_4_bits_vecWen) +
    $bits(io_in_4_bits_v0Wen) + $bits(io_in_4_bits_vlWen) + $bits(io_in_4_bits_isXSTrap) + $bits(io_in_4_bits_waitForward) +
    $bits(io_in_4_bits_blockBackward) + $bits(io_in_4_bits_flushPipe) + $bits(io_in_4_bits_canRobCompress) + $bits(io_in_4_bits_selImm) +
    $bits(io_in_4_bits_imm) + $bits(io_in_4_bits_fpu_typeTagOut) + $bits(io_in_4_bits_fpu_wflags) + $bits(io_in_4_bits_fpu_typ) +
    $bits(io_in_4_bits_fpu_fmt) + $bits(io_in_4_bits_fpu_rm) + $bits(io_in_4_bits_vpu_vill) + $bits(io_in_4_bits_vpu_vma) +
    $bits(io_in_4_bits_vpu_vta) + $bits(io_in_4_bits_vpu_vsew) + $bits(io_in_4_bits_vpu_vlmul) + $bits(io_in_4_bits_vpu_specVill) +
    $bits(io_in_4_bits_vpu_specVma) + $bits(io_in_4_bits_vpu_specVta) + $bits(io_in_4_bits_vpu_specVsew) + $bits(io_in_4_bits_vpu_specVlmul) +
    $bits(io_in_4_bits_vpu_vm) + $bits(io_in_4_bits_vpu_vstart) + $bits(io_in_4_bits_vpu_frm) + $bits(io_in_4_bits_vpu_fpu_isFpToVecInst) +
    $bits(io_in_4_bits_vpu_fpu_isFP32Instr) + $bits(io_in_4_bits_vpu_fpu_isFP64Instr) + $bits(io_in_4_bits_vpu_fpu_isReduction) + $bits(io_in_4_bits_vpu_fpu_isFoldTo1_2) +
    $bits(io_in_4_bits_vpu_fpu_isFoldTo1_4) + $bits(io_in_4_bits_vpu_fpu_isFoldTo1_8) + $bits(io_in_4_bits_vpu_vxrm) + $bits(io_in_4_bits_vpu_vuopIdx) +
    $bits(io_in_4_bits_vpu_lastUop) + $bits(io_in_4_bits_vpu_vmask) + $bits(io_in_4_bits_vpu_vl) + $bits(io_in_4_bits_vpu_nf) +
    $bits(io_in_4_bits_vpu_veew) + $bits(io_in_4_bits_vpu_isReverse) + $bits(io_in_4_bits_vpu_isExt) + $bits(io_in_4_bits_vpu_isNarrow) +
    $bits(io_in_4_bits_vpu_isDstMask) + $bits(io_in_4_bits_vpu_isOpMask) + $bits(io_in_4_bits_vpu_isMove) + $bits(io_in_4_bits_vpu_isDependOldVd) +
    $bits(io_in_4_bits_vpu_isWritePartVd) + $bits(io_in_4_bits_vpu_isVleff) + $bits(io_in_4_bits_vlsInstr) + $bits(io_in_4_bits_wfflags) +
    $bits(io_in_4_bits_isMove) + $bits(io_in_4_bits_uopIdx) + $bits(io_in_4_bits_isVset) + $bits(io_in_4_bits_firstUop) +
    $bits(io_in_4_bits_lastUop) + $bits(io_in_4_bits_numUops) + $bits(io_in_4_bits_numWB) + $bits(io_in_4_bits_commitType) +
    $bits(io_in_4_bits_psrc_0) + $bits(io_in_4_bits_psrc_1) + $bits(io_in_4_bits_psrc_2) + $bits(io_in_4_bits_psrc_3) +
    $bits(io_in_4_bits_psrc_4) + $bits(io_in_4_bits_pdest) + $bits(io_in_4_bits_robIdx_flag) + $bits(io_in_4_bits_robIdx_value) +
    $bits(io_in_4_bits_instrSize) + $bits(io_in_4_bits_dirtyFs) + $bits(io_in_4_bits_dirtyVs) + $bits(io_in_4_bits_traceBlockInPipe_itype) +
    $bits(io_in_4_bits_traceBlockInPipe_iretire) + $bits(io_in_4_bits_traceBlockInPipe_ilastsize) + $bits(io_in_4_bits_eliminatedMove) + $bits(io_in_4_bits_debugInfo_renameTime) +
    $bits(io_in_4_bits_debug_seqNum_seqNum) + $bits(io_in_4_bits_debug_seqNum_uopIdx) + $bits(io_in_4_bits_debug_fuType) + $bits(io_in_4_bits_debug_sim_trig) +
    $bits(io_in_4_bits_numLsElem);
  localparam int unsigned OUT4_PORT_BITS =
    $bits(io_out_4_bits_instr) + $bits(io_out_4_bits_pc) + $bits(io_out_4_bits_foldpc) + $bits(io_out_4_bits_exceptionVec_0) +
    $bits(io_out_4_bits_exceptionVec_1) + $bits(io_out_4_bits_exceptionVec_2) + $bits(io_out_4_bits_exceptionVec_3) + $bits(io_out_4_bits_exceptionVec_4) +
    $bits(io_out_4_bits_exceptionVec_5) + $bits(io_out_4_bits_exceptionVec_6) + $bits(io_out_4_bits_exceptionVec_7) + $bits(io_out_4_bits_exceptionVec_8) +
    $bits(io_out_4_bits_exceptionVec_9) + $bits(io_out_4_bits_exceptionVec_10) + $bits(io_out_4_bits_exceptionVec_11) + $bits(io_out_4_bits_exceptionVec_12) +
    $bits(io_out_4_bits_exceptionVec_13) + $bits(io_out_4_bits_exceptionVec_14) + $bits(io_out_4_bits_exceptionVec_15) + $bits(io_out_4_bits_exceptionVec_16) +
    $bits(io_out_4_bits_exceptionVec_17) + $bits(io_out_4_bits_exceptionVec_18) + $bits(io_out_4_bits_exceptionVec_19) + $bits(io_out_4_bits_exceptionVec_20) +
    $bits(io_out_4_bits_exceptionVec_21) + $bits(io_out_4_bits_exceptionVec_22) + $bits(io_out_4_bits_exceptionVec_23) + $bits(io_out_4_bits_isFetchMalAddr) +
    $bits(io_out_4_bits_hasException) + $bits(io_out_4_bits_trigger) + $bits(io_out_4_bits_preDecodeInfo_valid) + $bits(io_out_4_bits_preDecodeInfo_isRVC) +
    $bits(io_out_4_bits_preDecodeInfo_brType) + $bits(io_out_4_bits_preDecodeInfo_isCall) + $bits(io_out_4_bits_preDecodeInfo_isRet) + $bits(io_out_4_bits_pred_taken) +
    $bits(io_out_4_bits_crossPageIPFFix) + $bits(io_out_4_bits_ftqPtr_flag) + $bits(io_out_4_bits_ftqPtr_value) + $bits(io_out_4_bits_ftqOffset) +
    $bits(io_out_4_bits_satpFlushFirstFetchFault) + $bits(io_out_4_bits_srcType_0) + $bits(io_out_4_bits_srcType_1) + $bits(io_out_4_bits_srcType_2) +
    $bits(io_out_4_bits_srcType_3) + $bits(io_out_4_bits_srcType_4) + $bits(io_out_4_bits_ldest) + $bits(io_out_4_bits_fuType) +
    $bits(io_out_4_bits_fuOpType) + $bits(io_out_4_bits_rfWen) + $bits(io_out_4_bits_fpWen) + $bits(io_out_4_bits_vecWen) +
    $bits(io_out_4_bits_v0Wen) + $bits(io_out_4_bits_vlWen) + $bits(io_out_4_bits_isXSTrap) + $bits(io_out_4_bits_waitForward) +
    $bits(io_out_4_bits_blockBackward) + $bits(io_out_4_bits_flushPipe) + $bits(io_out_4_bits_canRobCompress) + $bits(io_out_4_bits_selImm) +
    $bits(io_out_4_bits_imm) + $bits(io_out_4_bits_fpu_typeTagOut) + $bits(io_out_4_bits_fpu_wflags) + $bits(io_out_4_bits_fpu_typ) +
    $bits(io_out_4_bits_fpu_fmt) + $bits(io_out_4_bits_fpu_rm) + $bits(io_out_4_bits_vpu_vill) + $bits(io_out_4_bits_vpu_vma) +
    $bits(io_out_4_bits_vpu_vta) + $bits(io_out_4_bits_vpu_vsew) + $bits(io_out_4_bits_vpu_vlmul) + $bits(io_out_4_bits_vpu_specVill) +
    $bits(io_out_4_bits_vpu_specVma) + $bits(io_out_4_bits_vpu_specVta) + $bits(io_out_4_bits_vpu_specVsew) + $bits(io_out_4_bits_vpu_specVlmul) +
    $bits(io_out_4_bits_vpu_vm) + $bits(io_out_4_bits_vpu_vstart) + $bits(io_out_4_bits_vpu_frm) + $bits(io_out_4_bits_vpu_fpu_isFpToVecInst) +
    $bits(io_out_4_bits_vpu_fpu_isFP32Instr) + $bits(io_out_4_bits_vpu_fpu_isFP64Instr) + $bits(io_out_4_bits_vpu_fpu_isReduction) + $bits(io_out_4_bits_vpu_fpu_isFoldTo1_2) +
    $bits(io_out_4_bits_vpu_fpu_isFoldTo1_4) + $bits(io_out_4_bits_vpu_fpu_isFoldTo1_8) + $bits(io_out_4_bits_vpu_vxrm) + $bits(io_out_4_bits_vpu_vuopIdx) +
    $bits(io_out_4_bits_vpu_lastUop) + $bits(io_out_4_bits_vpu_vmask) + $bits(io_out_4_bits_vpu_vl) + $bits(io_out_4_bits_vpu_nf) +
    $bits(io_out_4_bits_vpu_veew) + $bits(io_out_4_bits_vpu_isReverse) + $bits(io_out_4_bits_vpu_isExt) + $bits(io_out_4_bits_vpu_isNarrow) +
    $bits(io_out_4_bits_vpu_isDstMask) + $bits(io_out_4_bits_vpu_isOpMask) + $bits(io_out_4_bits_vpu_isMove) + $bits(io_out_4_bits_vpu_isDependOldVd) +
    $bits(io_out_4_bits_vpu_isWritePartVd) + $bits(io_out_4_bits_vpu_isVleff) + $bits(io_out_4_bits_vlsInstr) + $bits(io_out_4_bits_wfflags) +
    $bits(io_out_4_bits_isMove) + $bits(io_out_4_bits_uopIdx) + $bits(io_out_4_bits_isVset) + $bits(io_out_4_bits_firstUop) +
    $bits(io_out_4_bits_lastUop) + $bits(io_out_4_bits_numUops) + $bits(io_out_4_bits_numWB) + $bits(io_out_4_bits_commitType) +
    $bits(io_out_4_bits_psrc_0) + $bits(io_out_4_bits_psrc_1) + $bits(io_out_4_bits_psrc_2) + $bits(io_out_4_bits_psrc_3) +
    $bits(io_out_4_bits_psrc_4) + $bits(io_out_4_bits_pdest) + $bits(io_out_4_bits_robIdx_flag) + $bits(io_out_4_bits_robIdx_value) +
    $bits(io_out_4_bits_instrSize) + $bits(io_out_4_bits_dirtyFs) + $bits(io_out_4_bits_dirtyVs) + $bits(io_out_4_bits_traceBlockInPipe_itype) +
    $bits(io_out_4_bits_traceBlockInPipe_iretire) + $bits(io_out_4_bits_traceBlockInPipe_ilastsize) + $bits(io_out_4_bits_eliminatedMove) + $bits(io_out_4_bits_debugInfo_renameTime) +
    $bits(io_out_4_bits_debug_seqNum_seqNum) + $bits(io_out_4_bits_debug_seqNum_uopIdx) + $bits(io_out_4_bits_debug_fuType) + $bits(io_out_4_bits_debug_sim_trig) +
    $bits(io_out_4_bits_numLsElem);
  localparam int unsigned IN5_PORT_BITS =
    $bits(io_in_5_bits_instr) + $bits(io_in_5_bits_pc) + $bits(io_in_5_bits_foldpc) + $bits(io_in_5_bits_exceptionVec_0) +
    $bits(io_in_5_bits_exceptionVec_1) + $bits(io_in_5_bits_exceptionVec_2) + $bits(io_in_5_bits_exceptionVec_3) + $bits(io_in_5_bits_exceptionVec_4) +
    $bits(io_in_5_bits_exceptionVec_5) + $bits(io_in_5_bits_exceptionVec_6) + $bits(io_in_5_bits_exceptionVec_7) + $bits(io_in_5_bits_exceptionVec_8) +
    $bits(io_in_5_bits_exceptionVec_9) + $bits(io_in_5_bits_exceptionVec_10) + $bits(io_in_5_bits_exceptionVec_11) + $bits(io_in_5_bits_exceptionVec_12) +
    $bits(io_in_5_bits_exceptionVec_13) + $bits(io_in_5_bits_exceptionVec_14) + $bits(io_in_5_bits_exceptionVec_15) + $bits(io_in_5_bits_exceptionVec_16) +
    $bits(io_in_5_bits_exceptionVec_17) + $bits(io_in_5_bits_exceptionVec_18) + $bits(io_in_5_bits_exceptionVec_19) + $bits(io_in_5_bits_exceptionVec_20) +
    $bits(io_in_5_bits_exceptionVec_21) + $bits(io_in_5_bits_exceptionVec_22) + $bits(io_in_5_bits_exceptionVec_23) + $bits(io_in_5_bits_isFetchMalAddr) +
    $bits(io_in_5_bits_hasException) + $bits(io_in_5_bits_trigger) + $bits(io_in_5_bits_preDecodeInfo_valid) + $bits(io_in_5_bits_preDecodeInfo_isRVC) +
    $bits(io_in_5_bits_preDecodeInfo_brType) + $bits(io_in_5_bits_preDecodeInfo_isCall) + $bits(io_in_5_bits_preDecodeInfo_isRet) + $bits(io_in_5_bits_pred_taken) +
    $bits(io_in_5_bits_crossPageIPFFix) + $bits(io_in_5_bits_ftqPtr_flag) + $bits(io_in_5_bits_ftqPtr_value) + $bits(io_in_5_bits_ftqOffset) +
    $bits(io_in_5_bits_satpFlushFirstFetchFault) + $bits(io_in_5_bits_srcType_0) + $bits(io_in_5_bits_srcType_1) + $bits(io_in_5_bits_srcType_2) +
    $bits(io_in_5_bits_srcType_3) + $bits(io_in_5_bits_srcType_4) + $bits(io_in_5_bits_ldest) + $bits(io_in_5_bits_fuType) +
    $bits(io_in_5_bits_fuOpType) + $bits(io_in_5_bits_rfWen) + $bits(io_in_5_bits_fpWen) + $bits(io_in_5_bits_vecWen) +
    $bits(io_in_5_bits_v0Wen) + $bits(io_in_5_bits_vlWen) + $bits(io_in_5_bits_isXSTrap) + $bits(io_in_5_bits_waitForward) +
    $bits(io_in_5_bits_blockBackward) + $bits(io_in_5_bits_flushPipe) + $bits(io_in_5_bits_canRobCompress) + $bits(io_in_5_bits_selImm) +
    $bits(io_in_5_bits_imm) + $bits(io_in_5_bits_fpu_typeTagOut) + $bits(io_in_5_bits_fpu_wflags) + $bits(io_in_5_bits_fpu_typ) +
    $bits(io_in_5_bits_fpu_fmt) + $bits(io_in_5_bits_fpu_rm) + $bits(io_in_5_bits_vpu_vill) + $bits(io_in_5_bits_vpu_vma) +
    $bits(io_in_5_bits_vpu_vta) + $bits(io_in_5_bits_vpu_vsew) + $bits(io_in_5_bits_vpu_vlmul) + $bits(io_in_5_bits_vpu_specVill) +
    $bits(io_in_5_bits_vpu_specVma) + $bits(io_in_5_bits_vpu_specVta) + $bits(io_in_5_bits_vpu_specVsew) + $bits(io_in_5_bits_vpu_specVlmul) +
    $bits(io_in_5_bits_vpu_vm) + $bits(io_in_5_bits_vpu_vstart) + $bits(io_in_5_bits_vpu_frm) + $bits(io_in_5_bits_vpu_fpu_isFpToVecInst) +
    $bits(io_in_5_bits_vpu_fpu_isFP32Instr) + $bits(io_in_5_bits_vpu_fpu_isFP64Instr) + $bits(io_in_5_bits_vpu_fpu_isReduction) + $bits(io_in_5_bits_vpu_fpu_isFoldTo1_2) +
    $bits(io_in_5_bits_vpu_fpu_isFoldTo1_4) + $bits(io_in_5_bits_vpu_fpu_isFoldTo1_8) + $bits(io_in_5_bits_vpu_vxrm) + $bits(io_in_5_bits_vpu_vuopIdx) +
    $bits(io_in_5_bits_vpu_lastUop) + $bits(io_in_5_bits_vpu_vmask) + $bits(io_in_5_bits_vpu_vl) + $bits(io_in_5_bits_vpu_nf) +
    $bits(io_in_5_bits_vpu_veew) + $bits(io_in_5_bits_vpu_isReverse) + $bits(io_in_5_bits_vpu_isExt) + $bits(io_in_5_bits_vpu_isNarrow) +
    $bits(io_in_5_bits_vpu_isDstMask) + $bits(io_in_5_bits_vpu_isOpMask) + $bits(io_in_5_bits_vpu_isMove) + $bits(io_in_5_bits_vpu_isDependOldVd) +
    $bits(io_in_5_bits_vpu_isWritePartVd) + $bits(io_in_5_bits_vpu_isVleff) + $bits(io_in_5_bits_vlsInstr) + $bits(io_in_5_bits_wfflags) +
    $bits(io_in_5_bits_isMove) + $bits(io_in_5_bits_uopIdx) + $bits(io_in_5_bits_isVset) + $bits(io_in_5_bits_firstUop) +
    $bits(io_in_5_bits_lastUop) + $bits(io_in_5_bits_numUops) + $bits(io_in_5_bits_numWB) + $bits(io_in_5_bits_commitType) +
    $bits(io_in_5_bits_psrc_0) + $bits(io_in_5_bits_psrc_1) + $bits(io_in_5_bits_psrc_2) + $bits(io_in_5_bits_psrc_3) +
    $bits(io_in_5_bits_psrc_4) + $bits(io_in_5_bits_pdest) + $bits(io_in_5_bits_robIdx_flag) + $bits(io_in_5_bits_robIdx_value) +
    $bits(io_in_5_bits_instrSize) + $bits(io_in_5_bits_dirtyFs) + $bits(io_in_5_bits_dirtyVs) + $bits(io_in_5_bits_traceBlockInPipe_itype) +
    $bits(io_in_5_bits_traceBlockInPipe_iretire) + $bits(io_in_5_bits_traceBlockInPipe_ilastsize) + $bits(io_in_5_bits_eliminatedMove) + $bits(io_in_5_bits_debugInfo_renameTime) +
    $bits(io_in_5_bits_debug_seqNum_seqNum) + $bits(io_in_5_bits_debug_seqNum_uopIdx) + $bits(io_in_5_bits_debug_fuType) + $bits(io_in_5_bits_debug_sim_trig) +
    $bits(io_in_5_bits_numLsElem);
  localparam int unsigned OUT5_PORT_BITS =
    $bits(io_out_5_bits_instr) + $bits(io_out_5_bits_pc) + $bits(io_out_5_bits_foldpc) + $bits(io_out_5_bits_exceptionVec_0) +
    $bits(io_out_5_bits_exceptionVec_1) + $bits(io_out_5_bits_exceptionVec_2) + $bits(io_out_5_bits_exceptionVec_3) + $bits(io_out_5_bits_exceptionVec_4) +
    $bits(io_out_5_bits_exceptionVec_5) + $bits(io_out_5_bits_exceptionVec_6) + $bits(io_out_5_bits_exceptionVec_7) + $bits(io_out_5_bits_exceptionVec_8) +
    $bits(io_out_5_bits_exceptionVec_9) + $bits(io_out_5_bits_exceptionVec_10) + $bits(io_out_5_bits_exceptionVec_11) + $bits(io_out_5_bits_exceptionVec_12) +
    $bits(io_out_5_bits_exceptionVec_13) + $bits(io_out_5_bits_exceptionVec_14) + $bits(io_out_5_bits_exceptionVec_15) + $bits(io_out_5_bits_exceptionVec_16) +
    $bits(io_out_5_bits_exceptionVec_17) + $bits(io_out_5_bits_exceptionVec_18) + $bits(io_out_5_bits_exceptionVec_19) + $bits(io_out_5_bits_exceptionVec_20) +
    $bits(io_out_5_bits_exceptionVec_21) + $bits(io_out_5_bits_exceptionVec_22) + $bits(io_out_5_bits_exceptionVec_23) + $bits(io_out_5_bits_isFetchMalAddr) +
    $bits(io_out_5_bits_hasException) + $bits(io_out_5_bits_trigger) + $bits(io_out_5_bits_preDecodeInfo_valid) + $bits(io_out_5_bits_preDecodeInfo_isRVC) +
    $bits(io_out_5_bits_preDecodeInfo_brType) + $bits(io_out_5_bits_preDecodeInfo_isCall) + $bits(io_out_5_bits_preDecodeInfo_isRet) + $bits(io_out_5_bits_pred_taken) +
    $bits(io_out_5_bits_crossPageIPFFix) + $bits(io_out_5_bits_ftqPtr_flag) + $bits(io_out_5_bits_ftqPtr_value) + $bits(io_out_5_bits_ftqOffset) +
    $bits(io_out_5_bits_satpFlushFirstFetchFault) + $bits(io_out_5_bits_srcType_0) + $bits(io_out_5_bits_srcType_1) + $bits(io_out_5_bits_srcType_2) +
    $bits(io_out_5_bits_srcType_3) + $bits(io_out_5_bits_srcType_4) + $bits(io_out_5_bits_ldest) + $bits(io_out_5_bits_fuType) +
    $bits(io_out_5_bits_fuOpType) + $bits(io_out_5_bits_rfWen) + $bits(io_out_5_bits_fpWen) + $bits(io_out_5_bits_vecWen) +
    $bits(io_out_5_bits_v0Wen) + $bits(io_out_5_bits_vlWen) + $bits(io_out_5_bits_isXSTrap) + $bits(io_out_5_bits_waitForward) +
    $bits(io_out_5_bits_blockBackward) + $bits(io_out_5_bits_flushPipe) + $bits(io_out_5_bits_canRobCompress) + $bits(io_out_5_bits_selImm) +
    $bits(io_out_5_bits_imm) + $bits(io_out_5_bits_fpu_typeTagOut) + $bits(io_out_5_bits_fpu_wflags) + $bits(io_out_5_bits_fpu_typ) +
    $bits(io_out_5_bits_fpu_fmt) + $bits(io_out_5_bits_fpu_rm) + $bits(io_out_5_bits_vpu_vill) + $bits(io_out_5_bits_vpu_vma) +
    $bits(io_out_5_bits_vpu_vta) + $bits(io_out_5_bits_vpu_vsew) + $bits(io_out_5_bits_vpu_vlmul) + $bits(io_out_5_bits_vpu_specVill) +
    $bits(io_out_5_bits_vpu_specVma) + $bits(io_out_5_bits_vpu_specVta) + $bits(io_out_5_bits_vpu_specVsew) + $bits(io_out_5_bits_vpu_specVlmul) +
    $bits(io_out_5_bits_vpu_vm) + $bits(io_out_5_bits_vpu_vstart) + $bits(io_out_5_bits_vpu_frm) + $bits(io_out_5_bits_vpu_fpu_isFpToVecInst) +
    $bits(io_out_5_bits_vpu_fpu_isFP32Instr) + $bits(io_out_5_bits_vpu_fpu_isFP64Instr) + $bits(io_out_5_bits_vpu_fpu_isReduction) + $bits(io_out_5_bits_vpu_fpu_isFoldTo1_2) +
    $bits(io_out_5_bits_vpu_fpu_isFoldTo1_4) + $bits(io_out_5_bits_vpu_fpu_isFoldTo1_8) + $bits(io_out_5_bits_vpu_vxrm) + $bits(io_out_5_bits_vpu_vuopIdx) +
    $bits(io_out_5_bits_vpu_lastUop) + $bits(io_out_5_bits_vpu_vmask) + $bits(io_out_5_bits_vpu_vl) + $bits(io_out_5_bits_vpu_nf) +
    $bits(io_out_5_bits_vpu_veew) + $bits(io_out_5_bits_vpu_isReverse) + $bits(io_out_5_bits_vpu_isExt) + $bits(io_out_5_bits_vpu_isNarrow) +
    $bits(io_out_5_bits_vpu_isDstMask) + $bits(io_out_5_bits_vpu_isOpMask) + $bits(io_out_5_bits_vpu_isMove) + $bits(io_out_5_bits_vpu_isDependOldVd) +
    $bits(io_out_5_bits_vpu_isWritePartVd) + $bits(io_out_5_bits_vpu_isVleff) + $bits(io_out_5_bits_vlsInstr) + $bits(io_out_5_bits_wfflags) +
    $bits(io_out_5_bits_isMove) + $bits(io_out_5_bits_uopIdx) + $bits(io_out_5_bits_isVset) + $bits(io_out_5_bits_firstUop) +
    $bits(io_out_5_bits_lastUop) + $bits(io_out_5_bits_numUops) + $bits(io_out_5_bits_numWB) + $bits(io_out_5_bits_commitType) +
    $bits(io_out_5_bits_psrc_0) + $bits(io_out_5_bits_psrc_1) + $bits(io_out_5_bits_psrc_2) + $bits(io_out_5_bits_psrc_3) +
    $bits(io_out_5_bits_psrc_4) + $bits(io_out_5_bits_pdest) + $bits(io_out_5_bits_robIdx_flag) + $bits(io_out_5_bits_robIdx_value) +
    $bits(io_out_5_bits_instrSize) + $bits(io_out_5_bits_dirtyFs) + $bits(io_out_5_bits_dirtyVs) + $bits(io_out_5_bits_traceBlockInPipe_itype) +
    $bits(io_out_5_bits_traceBlockInPipe_iretire) + $bits(io_out_5_bits_traceBlockInPipe_ilastsize) + $bits(io_out_5_bits_eliminatedMove) + $bits(io_out_5_bits_debugInfo_renameTime) +
    $bits(io_out_5_bits_debug_seqNum_seqNum) + $bits(io_out_5_bits_debug_seqNum_uopIdx) + $bits(io_out_5_bits_debug_fuType) + $bits(io_out_5_bits_debug_sim_trig) +
    $bits(io_out_5_bits_numLsElem);

  if (IN0_PORT_BITS != LANE0_W_G1 || OUT0_PORT_BITS != LANE0_W_G1)
    $fatal(1, "PipeGroupConnect: lane 0 port bits in=%0d out=%0d != G1 golden %0d", IN0_PORT_BITS, OUT0_PORT_BITS, LANE0_W_G1);
  if (IN1_PORT_BITS != LANE_W_G1 || OUT1_PORT_BITS != LANE_W_G1)
    $fatal(1, "PipeGroupConnect: lane 1 port bits in=%0d out=%0d != G1 golden %0d", IN1_PORT_BITS, OUT1_PORT_BITS, LANE_W_G1);
  if (IN2_PORT_BITS != LANE_W_G1 || OUT2_PORT_BITS != LANE_W_G1)
    $fatal(1, "PipeGroupConnect: lane 2 port bits in=%0d out=%0d != G1 golden %0d", IN2_PORT_BITS, OUT2_PORT_BITS, LANE_W_G1);
  if (IN3_PORT_BITS != LANE_W_G1 || OUT3_PORT_BITS != LANE_W_G1)
    $fatal(1, "PipeGroupConnect: lane 3 port bits in=%0d out=%0d != G1 golden %0d", IN3_PORT_BITS, OUT3_PORT_BITS, LANE_W_G1);
  if (IN4_PORT_BITS != LANE_W_G1 || OUT4_PORT_BITS != LANE_W_G1)
    $fatal(1, "PipeGroupConnect: lane 4 port bits in=%0d out=%0d != G1 golden %0d", IN4_PORT_BITS, OUT4_PORT_BITS, LANE_W_G1);
  if (IN5_PORT_BITS != LANE_W_G1 || OUT5_PORT_BITS != LANE_W_G1)
    $fatal(1, "PipeGroupConnect: lane 5 port bits in=%0d out=%0d != G1 golden %0d", IN5_PORT_BITS, OUT5_PORT_BITS, LANE_W_G1);

endmodule
