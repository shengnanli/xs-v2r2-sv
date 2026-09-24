// =============================================================================
// DecodeStage.sv —— 译码级：6 个简单译码器 + 1 个复杂译码器 + vtype 跟踪，把 IBuffer
//                    送来的 6 条指令译成最多 6 个 uop 交给 Rename
// -----------------------------------------------------------------------------
// 设计源: XiangShan src/main/scala/xiangshan/backend/decode/DecodeStage.scala
// golden: G1-canonical/golden-rtl/DecodeStage.sv（firtool 展平，10850 行 / 1103 端口 /
//         37 个寄存器 / 8 个子模块实例：DecodeUnit×6 + DecodeUnitComp + VTypeGen）
//
// 【它在 CtrlBlock 里的位置】
//   IBuffer ─(io.in ×6, StaticInst)─▶ DecodeStage ─(io.out ×6, DecodedInst)─▶ Rename
//   同时给 Rename 的 RAT 读口送 lsrc 地址，给 CSR 报非法指令的现场（trapInstInfo），
//   从 Rob 收 vtype 的提交/回滚/恢复信号。FusionDecoder 在 CtrlBlock 里与本模块并列，
//   通过 io.fusion 只回传"第 i 对融合成立"给本模块的 perf 计数。
//
// 【一拍内的三步（全组合，本模块自己几乎没有状态）】
//   1. 6 个 DecodeUnit 各译一条：得到 DecodedInst、isComplex（要不要拆 uop）、uopInfo。
//   2. 挑第一条复杂指令送 DecodeUnitComp（它把这条锁存起来，下一拍开始按 uopSplitType
//      吐 uop，每拍最多 6 个，吐了几个叫 complexNum）。
//   3. 输出排布：复杂译码器吐出的 complexNum 个 uop 排在最前，后面用"前缀全是简单指令"
//      的那几条简单译码结果补满（finalDecodedInst[i] = complexNum > i ? complex[i]
//      : simple[i - complexNum]）。
//   in.ready 的规则（照 Scala 注释）：不在 redirect/isResumeVType 下，且
//     · 前 i+1 条全是简单指令，且第 i 条排布后的位置 < readyCounter（Rename 能收）；或
//     · 第 i 条恰是第一条复杂指令，位置 <= readyCounter，且复杂译码器能收。
//   readyCounter = out[0].ready ? 6 : 0 —— 只看第 0 路 ready，粗粒度。
//
// 【输出修饰（每路一样）】
//   · vpu.isReverse 时交换 lsrc[0]/lsrc[1] 与 srcType[0]/srcType[1]；
//   · vecWen 且 ldest==0 的改成 v0Wen（v0 单独重命名）；
//   · 任一向量源读 v0（srcType 是 vp 且 lsrc==0）时 srcType[3] 强制成 v0 类型；
//   · uopIdx != 0 的 uop 把 debug_seqNum 清零（只有第一个 uop 带序号）。
//   RAT 读口用的是修饰后的 lsrc[0]/lsrc[1]（融合译码前的值，为了时序）。
//
// 【寄存器（37 个，全在 perf/trapInstInfo）】
//   · trapInstInfo：RegNext(有非法指令 && !redirect) 与优先选出的那条的 instr/ftqPtr/ftqOffset
//     （无复位）；
//   · recoveryFlag：redirect 置 1，任一路 in.fire 清 0（异步复位 0）；
//   · perfEvents 8 项两级打拍（io_perf_N_value），其中 fusionValid/inValidNotReady/
//     frontendStall/backendStall 先各自打一拍（GatedValidRegNext，异步复位 0）。
//
// 【照抄 golden 的几处怪癖（bug-for-bug）】
//   * simple[i - complexNum] 的下标是 3 位、表有 8 项：[6]/[7] 两项是 decoders_0
//     （firtool 给 Vec 越界下标补的是第 0 项）。这里照样建 8 项表。
//   * DecodeUnit 没有 firstUop/lastUop/numUops/numWB/uopIdx/vlWen/isFoldTo1 这些端口
//     （简单指令恒为 1/1/1/1/0/0/0），DecodeUnitComp 的第 1..5 路没有 firstUop 端口（恒 0）
//     —— 常量由 verif/ut/DecodeStage/gen.py 对着 golden 断言后补进结构体。
//   * srcType[3] 的 v0 判断把 lsrc(3)==0 折成了恒真（golden 里 lsrc 只有 3 项），
//     所以第四项只看 srcType[3] 是不是 vp。
//   * XSPerfAccumulate("frontend_stall_cycle"/"backend_stall_cycle") 的 GatedValidRegNext
//     各多产生一个与 frontendStall/backendStall 打拍相同的寄存器（golden last_REG /
//     last_REG_1），只喂 _probe 观测线，本配置下无读者（cone-dead）。这里对称保留
//     （frontendStall_probe_q / backendStall_probe_q），FM 用 vmucp 当比对点证。
//   * debug_globalCounter 在 golden 里已被 firtool 整个删掉（无读者），这里也没有。
//   * assert(PopCount(rfWen,fpWen,vecWen,v0Wen,vlWen) < 2) 是 `ifndef SYNTHESIS 断言，不在本重写内。
//
// 【文件结构】package xs_decodestage_pkg（小结构体手写；大结构体由 gen.py 从 golden 端口表生成）
//            → 核 xs_DecodeStage_core（结构体/数组端口；子模块例化连线由 gen.py 生成）
//            → golden 同名 wrapper DecodeStage（端口表与打包/拆包由 gen.py 生成）
//   子模块 DecodeUnit / DecodeUnitComp / VTypeGen 及其闭包在 UT 与 FM 里两侧共用 golden 定义
//   （见 verif/ut/DecodeStage/Makefile 的 RTL_GOLDEN_DEPS）。
// =============================================================================
// 本文件导航（共 3833 行；按"一个 golden 模块一个文件"的规范不拆分，用下面的分节定位）：
//   L23    设计源: XiangShan src/main/scala/xiangshan/backend/decode/DecodeSta
//   L27    它在 CtrlBlock 里的位置
//   L33    一拍内的三步
//   L45    输出修饰
//   L52    寄存器
//   L59    照抄 golden 的几处怪癖
//   L74    文件结构】package xs_decodestage_pkg
//   L311   子模块接口信号
//   L1330  复杂/简单指令的排布与 ready
//   L1384  finalDecodedInst：complexNum 个复杂 uop 排前面，简单指令补后面
//   L1386  simple[i - complexNum] 的下标是 3 位，表有 8 项：[6]/[7] 是 decoders_0
//   L1408  输出修饰 + RAT 读口
//   L1455  stall reason 直通
//   L1465  报给 CSR 的非法指令现场
//   L1490  perf：recoveryFlag + 8 个 perfEvents 两级打拍
//   L1570  wrapper：端口与 golden DecodeStage 逐位同名同序，只做结构体打包/拆包
//
package xs_decodestage_pkg;
  localparam int unsigned DECODE_WIDTH = 6;
  localparam int unsigned RENAME_WIDTH = 6;
  localparam int unsigned V0_IDX = 0;             // v0 的逻辑寄存器号
  localparam int unsigned EX_II  = 2;             // exceptionVec 里的 illegal instruction
  localparam int unsigned EX_VI  = 22;            // exceptionVec 里的 virtual instruction
  localparam logic [3:0]  SRCTYPE_V0 = 4'h8;      // SrcType.v0
  localparam int unsigned CPLX_W = 3;             // complexNum 位宽（0..6）

  typedef struct packed {
    logic       illegal;
    logic       vma;
    logic       vta;
    logic [1:0] vsew;
    logic [2:0] vlmul;
  } vtype_t;

  typedef struct packed {
    logic [6:0] numOfUop;   // 复杂指令一共拆几个 uop
    logic [6:0] numOfWB;    // 其中几个会写回
    logic [3:0] lmul;
  } uop_info_t;

  // Rob 来的 vtype 控制
  typedef struct packed {
    logic   isResumeVType;        // vtype 正在恢复：不收新指令、不出 uop
    logic   walkToArchVType;
    logic   commitVType_valid;
    vtype_t commitVType;
    logic   commitVType_hasVsetvl;
    logic   walkVType_valid;
    vtype_t walkVType;
  } from_rob_t;

  // 报给 CSR 的非法指令现场
  typedef struct packed {
    logic [31:0] instr;
    logic        ftqPtr_flag;
    logic [5:0]  ftqPtr_value;
    logic [3:0]  ftqOffset;
  } trap_inst_info_t;

  // BEGIN GENERATED(csr_struct)
  // csr_to_decode_t —— CSR 告诉译码器哪些指令当前非法/虚拟化非法（io_fromCSR_*，24 位）
  typedef struct packed {
    logic       illegalInst_sfenceVMA;
    logic       illegalInst_sfencePart;
    logic       illegalInst_hfenceGVMA;
    logic       illegalInst_hfenceVVMA;
    logic       illegalInst_hlsv;
    logic       illegalInst_fsIsOff;
    logic       illegalInst_vsIsOff;
    logic       illegalInst_wfi;
    logic       illegalInst_wrs_nto;
    logic       illegalInst_frm;
    logic       illegalInst_cboZ;
    logic       illegalInst_cboCF;
    logic       illegalInst_cboI;
    logic       virtualInst_sfenceVMA;
    logic       virtualInst_sfencePart;
    logic       virtualInst_hfence;
    logic       virtualInst_hlsv;
    logic       virtualInst_wfi;
    logic       virtualInst_wrs_nto;
    logic       virtualInst_cboZ;
    logic       virtualInst_cboCF;
    logic       virtualInst_cboI;
    logic       special_cboI2F;
  } csr_to_decode_t;
  // END GENERATED

  // BEGIN GENERATED(static_inst)
  // static_inst_t —— IBuffer 送来的 StaticInst（41 个字段，名字/位宽取自 golden io_in_0_bits_*）
  typedef struct packed {
    logic [31:0] instr;
    logic [49:0] pc;
    logic [9:0] foldpc;
    logic [23:0] exceptionVec;
    logic       isFetchMalAddr;
    logic [3:0] trigger;
    logic       preDecodeInfo_valid;
    logic       preDecodeInfo_isRVC;
    logic [1:0] preDecodeInfo_brType;
    logic       preDecodeInfo_isCall;
    logic       preDecodeInfo_isRet;
    logic       pred_taken;
    logic       crossPageIPFFix;
    logic       ftqPtr_flag;
    logic [5:0] ftqPtr_value;
    logic [3:0] ftqOffset;
    logic       isLastInFtqEntry;
    logic [55:0] debug_seqNum_seqNum;
    logic [7:0] debug_seqNum_uopIdx;
    logic       satpFlushFirstFetchFault;
  } static_inst_t;
  // END GENERATED

  // BEGIN GENERATED(decoded_inst)
  // decoded_inst_t —— 送 Rename 的 DecodedInst（107 个字段，取自 golden io_out_0_bits_*；
  //   exceptionVec/srcType/lsrc 收成向量，其余成员名与 golden 逐字同名）
  typedef struct packed {
    logic [31:0] instr;
    logic [49:0] pc;
    logic [9:0] foldpc;
    logic [23:0] exceptionVec;
    logic       isFetchMalAddr;
    logic [3:0] trigger;
    logic       preDecodeInfo_valid;
    logic       preDecodeInfo_isRVC;
    logic [1:0] preDecodeInfo_brType;
    logic       preDecodeInfo_isCall;
    logic       preDecodeInfo_isRet;
    logic       pred_taken;
    logic       crossPageIPFFix;
    logic       ftqPtr_flag;
    logic [5:0] ftqPtr_value;
    logic [3:0] ftqOffset;
    logic       satpFlushFirstFetchFault;
    logic [4:0][3:0] srcType;
    logic [2:0][5:0] lsrc;
    logic [5:0] ldest;
    logic [34:0] fuType;
    logic [8:0] fuOpType;
    logic       rfWen;
    logic       fpWen;
    logic       vecWen;
    logic       v0Wen;
    logic       vlWen;
    logic       isXSTrap;
    logic       waitForward;
    logic       blockBackward;
    logic       flushPipe;
    logic       canRobCompress;
    logic [3:0] selImm;
    logic [21:0] imm;
    logic [1:0] fpu_typeTagOut;
    logic       fpu_wflags;
    logic [1:0] fpu_typ;
    logic [1:0] fpu_fmt;
    logic [2:0] fpu_rm;
    logic       vpu_vill;
    logic       vpu_vma;
    logic       vpu_vta;
    logic [1:0] vpu_vsew;
    logic [2:0] vpu_vlmul;
    logic       vpu_specVill;
    logic       vpu_specVma;
    logic       vpu_specVta;
    logic [1:0] vpu_specVsew;
    logic [2:0] vpu_specVlmul;
    logic       vpu_vm;
    logic [7:0] vpu_vstart;
    logic       vpu_fpu_isFoldTo1_2;
    logic       vpu_fpu_isFoldTo1_4;
    logic       vpu_fpu_isFoldTo1_8;
    logic [2:0] vpu_nf;
    logic [1:0] vpu_veew;
    logic       vpu_isReverse;
    logic       vpu_isExt;
    logic       vpu_isNarrow;
    logic       vpu_isDstMask;
    logic       vpu_isOpMask;
    logic       vpu_isDependOldVd;
    logic       vpu_isWritePartVd;
    logic       vpu_isVleff;
    logic       vlsInstr;
    logic       wfflags;
    logic       isMove;
    logic [6:0] uopIdx;
    logic [5:0] uopSplitType;
    logic       isVset;
    logic       firstUop;
    logic       lastUop;
    logic [6:0] numUops;
    logic [6:0] numWB;
    logic [2:0] commitType;
    logic [34:0] debug_fuType;
    logic [55:0] debug_seqNum_seqNum;
    logic [7:0] debug_seqNum_uopIdx;
  } decoded_inst_t;
  // END GENERATED
endpackage

module xs_DecodeStage_core
  import xs_decodestage_pkg::*;
(
  input  logic                               clock,
  input  logic                               reset,
  input  logic                               redirect,
  output logic                               canAccept,
  // from IBuffer
  input  logic          [DECODE_WIDTH-1:0]   in_valid,
  input  static_inst_t  [DECODE_WIDTH-1:0]   in_bits,
  output logic          [DECODE_WIDTH-1:0]   in_ready,
  // to Rename
  output logic          [DECODE_WIDTH-1:0]   out_valid,
  output decoded_inst_t [DECODE_WIDTH-1:0]   out_bits,
  input  logic          [DECODE_WIDTH-1:0]   out_ready,
  // RAT 读口（addr 位宽照 golden：int 32 / fp 34 / vec 47）
  output logic [RENAME_WIDTH-1:0][1:0][31:0] intRat_addr,
  output logic [RENAME_WIDTH-1:0][1:0]       intRat_hold,
  output logic [RENAME_WIDTH-1:0][2:0][33:0] fpRat_addr,
  output logic [RENAME_WIDTH-1:0][2:0]       fpRat_hold,
  output logic [RENAME_WIDTH-1:0][2:0][46:0] vecRat_addr,
  output logic [RENAME_WIDTH-1:0][2:0]       vecRat_hold,
  output logic [RENAME_WIDTH-1:0]            v0Rat_hold,
  output logic [RENAME_WIDTH-1:0]            vlRat_hold,
  // CSR 控制
  input  logic                               csrCtrl_singlestep,
  input  csr_to_decode_t                     fromCSR,
  // FusionDecoder 回传"第 i 对融合成立"（只进 perf）
  input  logic          [DECODE_WIDTH-2:0]   fusion,
  input  logic                               backendCanAccept,
  input  from_rob_t                          fromRob,
  // stall reason 直通
  input  logic [DECODE_WIDTH-1:0][5:0]       stallReason_in_reason,
  input  logic                               stallReason_out_backReason_valid,
  input  logic [5:0]                         stallReason_out_backReason_bits,
  output logic                               stallReason_in_backReason_valid,
  output logic [5:0]                         stallReason_in_backReason_bits,
  output logic [DECODE_WIDTH-1:0][5:0]       stallReason_out_reason,
  input  vtype_t                             vsetvlVType,
  input  logic [7:0]                         vstart,
  // to CSR
  output logic                               trapInstInfo_valid,
  output trap_inst_info_t                    trapInstInfo,
  // perf events（8 项，两级打拍）
  output logic [7:0][5:0]                    perf_value
);

  // ===========================================================================
  // 子模块接口信号
  // ===========================================================================
  decoded_inst_t [DECODE_WIDTH-1:0] simple_inst;        // 6 个简单译码器的结果
  logic          [DECODE_WIDTH-1:0] simple_is_complex;
  uop_info_t     [DECODE_WIDTH-1:0] simple_uop_info;
  decoded_inst_t                    complex_in_inst;    // 送复杂译码器的那条
  uop_info_t                        complex_in_uop_info;
  logic                             complex_in_valid, complex_in_ready;
  decoded_inst_t [DECODE_WIDTH-1:0] complex_inst;       // 复杂译码器吐出的 uop
  logic          [DECODE_WIDTH-1:0] complex_valid;
  logic          [CPLX_W-1:0]       complexNum;         // 本拍复杂译码器吐了几个 uop
  vtype_t                           vtype;              // 当前推测 vtype
  logic                             vtype_can_update;

  // BEGIN GENERATED(simple_decoders)
  // 6 个简单译码器：每路一个 DecodeUnit（纯组合，无 clock/reset），
  // 输入 = 本路 StaticInst + 当前推测 vtype/vstart + CSR 标志，输出 = DecodedInst + isComplex + uopInfo。
  for (genvar i = 0; i < DECODE_WIDTH; i++) begin : g_simple
    DecodeUnit u_decoder (
      .io_enq_ctrlFlow_instr                        (in_bits[i].instr),
      .io_enq_ctrlFlow_pc                           (in_bits[i].pc),
      .io_enq_ctrlFlow_foldpc                       (in_bits[i].foldpc),
      .io_enq_ctrlFlow_exceptionVec_0               (in_bits[i].exceptionVec[0]),
      .io_enq_ctrlFlow_exceptionVec_1               (in_bits[i].exceptionVec[1]),
      .io_enq_ctrlFlow_exceptionVec_2               (in_bits[i].exceptionVec[2]),
      .io_enq_ctrlFlow_exceptionVec_4               (in_bits[i].exceptionVec[4]),
      .io_enq_ctrlFlow_exceptionVec_5               (in_bits[i].exceptionVec[5]),
      .io_enq_ctrlFlow_exceptionVec_6               (in_bits[i].exceptionVec[6]),
      .io_enq_ctrlFlow_exceptionVec_7               (in_bits[i].exceptionVec[7]),
      .io_enq_ctrlFlow_exceptionVec_8               (in_bits[i].exceptionVec[8]),
      .io_enq_ctrlFlow_exceptionVec_9               (in_bits[i].exceptionVec[9]),
      .io_enq_ctrlFlow_exceptionVec_10              (in_bits[i].exceptionVec[10]),
      .io_enq_ctrlFlow_exceptionVec_11              (in_bits[i].exceptionVec[11]),
      .io_enq_ctrlFlow_exceptionVec_12              (in_bits[i].exceptionVec[12]),
      .io_enq_ctrlFlow_exceptionVec_13              (in_bits[i].exceptionVec[13]),
      .io_enq_ctrlFlow_exceptionVec_14              (in_bits[i].exceptionVec[14]),
      .io_enq_ctrlFlow_exceptionVec_15              (in_bits[i].exceptionVec[15]),
      .io_enq_ctrlFlow_exceptionVec_16              (in_bits[i].exceptionVec[16]),
      .io_enq_ctrlFlow_exceptionVec_17              (in_bits[i].exceptionVec[17]),
      .io_enq_ctrlFlow_exceptionVec_18              (in_bits[i].exceptionVec[18]),
      .io_enq_ctrlFlow_exceptionVec_19              (in_bits[i].exceptionVec[19]),
      .io_enq_ctrlFlow_exceptionVec_20              (in_bits[i].exceptionVec[20]),
      .io_enq_ctrlFlow_exceptionVec_21              (in_bits[i].exceptionVec[21]),
      .io_enq_ctrlFlow_exceptionVec_23              (in_bits[i].exceptionVec[23]),
      .io_enq_ctrlFlow_isFetchMalAddr               (in_bits[i].isFetchMalAddr),
      .io_enq_ctrlFlow_trigger                      (in_bits[i].trigger),
      .io_enq_ctrlFlow_preDecodeInfo_valid          (in_bits[i].preDecodeInfo_valid),
      .io_enq_ctrlFlow_preDecodeInfo_isRVC          (in_bits[i].preDecodeInfo_isRVC),
      .io_enq_ctrlFlow_preDecodeInfo_brType         (in_bits[i].preDecodeInfo_brType),
      .io_enq_ctrlFlow_preDecodeInfo_isCall         (in_bits[i].preDecodeInfo_isCall),
      .io_enq_ctrlFlow_preDecodeInfo_isRet          (in_bits[i].preDecodeInfo_isRet),
      .io_enq_ctrlFlow_pred_taken                   (in_bits[i].pred_taken),
      .io_enq_ctrlFlow_crossPageIPFFix              (in_bits[i].crossPageIPFFix),
      .io_enq_ctrlFlow_ftqPtr_flag                  (in_bits[i].ftqPtr_flag),
      .io_enq_ctrlFlow_ftqPtr_value                 (in_bits[i].ftqPtr_value),
      .io_enq_ctrlFlow_ftqOffset                    (in_bits[i].ftqOffset),
      .io_enq_ctrlFlow_isLastInFtqEntry             (in_bits[i].isLastInFtqEntry),
      .io_enq_ctrlFlow_debug_seqNum_seqNum          (in_bits[i].debug_seqNum_seqNum),
      .io_enq_ctrlFlow_debug_seqNum_uopIdx          (in_bits[i].debug_seqNum_uopIdx),
      .io_enq_ctrlFlow_satpFlushFirstFetchFault     (in_bits[i].satpFlushFirstFetchFault),
      .io_enq_vtype_illegal                         (vtype.illegal),
      .io_enq_vtype_vma                             (vtype.vma),
      .io_enq_vtype_vta                             (vtype.vta),
      .io_enq_vtype_vsew                            (vtype.vsew),
      .io_enq_vtype_vlmul                           (vtype.vlmul),
      .io_enq_vstart                                (vstart),
      .io_deq_decodedInst_instr                     (simple_inst[i].instr),
      .io_deq_decodedInst_pc                        (simple_inst[i].pc),
      .io_deq_decodedInst_foldpc                    (simple_inst[i].foldpc),
      .io_deq_decodedInst_exceptionVec_0            (simple_inst[i].exceptionVec[0]),
      .io_deq_decodedInst_exceptionVec_1            (simple_inst[i].exceptionVec[1]),
      .io_deq_decodedInst_exceptionVec_2            (simple_inst[i].exceptionVec[2]),
      .io_deq_decodedInst_exceptionVec_3            (simple_inst[i].exceptionVec[3]),
      .io_deq_decodedInst_exceptionVec_4            (simple_inst[i].exceptionVec[4]),
      .io_deq_decodedInst_exceptionVec_5            (simple_inst[i].exceptionVec[5]),
      .io_deq_decodedInst_exceptionVec_6            (simple_inst[i].exceptionVec[6]),
      .io_deq_decodedInst_exceptionVec_7            (simple_inst[i].exceptionVec[7]),
      .io_deq_decodedInst_exceptionVec_8            (simple_inst[i].exceptionVec[8]),
      .io_deq_decodedInst_exceptionVec_9            (simple_inst[i].exceptionVec[9]),
      .io_deq_decodedInst_exceptionVec_10           (simple_inst[i].exceptionVec[10]),
      .io_deq_decodedInst_exceptionVec_11           (simple_inst[i].exceptionVec[11]),
      .io_deq_decodedInst_exceptionVec_12           (simple_inst[i].exceptionVec[12]),
      .io_deq_decodedInst_exceptionVec_13           (simple_inst[i].exceptionVec[13]),
      .io_deq_decodedInst_exceptionVec_14           (simple_inst[i].exceptionVec[14]),
      .io_deq_decodedInst_exceptionVec_15           (simple_inst[i].exceptionVec[15]),
      .io_deq_decodedInst_exceptionVec_16           (simple_inst[i].exceptionVec[16]),
      .io_deq_decodedInst_exceptionVec_17           (simple_inst[i].exceptionVec[17]),
      .io_deq_decodedInst_exceptionVec_18           (simple_inst[i].exceptionVec[18]),
      .io_deq_decodedInst_exceptionVec_19           (simple_inst[i].exceptionVec[19]),
      .io_deq_decodedInst_exceptionVec_20           (simple_inst[i].exceptionVec[20]),
      .io_deq_decodedInst_exceptionVec_21           (simple_inst[i].exceptionVec[21]),
      .io_deq_decodedInst_exceptionVec_22           (simple_inst[i].exceptionVec[22]),
      .io_deq_decodedInst_exceptionVec_23           (simple_inst[i].exceptionVec[23]),
      .io_deq_decodedInst_isFetchMalAddr            (simple_inst[i].isFetchMalAddr),
      .io_deq_decodedInst_trigger                   (simple_inst[i].trigger),
      .io_deq_decodedInst_preDecodeInfo_valid       (simple_inst[i].preDecodeInfo_valid),
      .io_deq_decodedInst_preDecodeInfo_isRVC       (simple_inst[i].preDecodeInfo_isRVC),
      .io_deq_decodedInst_preDecodeInfo_brType      (simple_inst[i].preDecodeInfo_brType),
      .io_deq_decodedInst_preDecodeInfo_isCall      (simple_inst[i].preDecodeInfo_isCall),
      .io_deq_decodedInst_preDecodeInfo_isRet       (simple_inst[i].preDecodeInfo_isRet),
      .io_deq_decodedInst_pred_taken                (simple_inst[i].pred_taken),
      .io_deq_decodedInst_crossPageIPFFix           (simple_inst[i].crossPageIPFFix),
      .io_deq_decodedInst_ftqPtr_flag               (simple_inst[i].ftqPtr_flag),
      .io_deq_decodedInst_ftqPtr_value              (simple_inst[i].ftqPtr_value),
      .io_deq_decodedInst_ftqOffset                 (simple_inst[i].ftqOffset),
      .io_deq_decodedInst_satpFlushFirstFetchFault  (simple_inst[i].satpFlushFirstFetchFault),
      .io_deq_decodedInst_srcType_0                 (simple_inst[i].srcType[0]),
      .io_deq_decodedInst_srcType_1                 (simple_inst[i].srcType[1]),
      .io_deq_decodedInst_srcType_2                 (simple_inst[i].srcType[2]),
      .io_deq_decodedInst_srcType_3                 (simple_inst[i].srcType[3]),
      .io_deq_decodedInst_srcType_4                 (simple_inst[i].srcType[4]),
      .io_deq_decodedInst_lsrc_0                    (simple_inst[i].lsrc[0]),
      .io_deq_decodedInst_lsrc_1                    (simple_inst[i].lsrc[1]),
      .io_deq_decodedInst_lsrc_2                    (simple_inst[i].lsrc[2]),
      .io_deq_decodedInst_ldest                     (simple_inst[i].ldest),
      .io_deq_decodedInst_fuType                    (simple_inst[i].fuType),
      .io_deq_decodedInst_fuOpType                  (simple_inst[i].fuOpType),
      .io_deq_decodedInst_rfWen                     (simple_inst[i].rfWen),
      .io_deq_decodedInst_fpWen                     (simple_inst[i].fpWen),
      .io_deq_decodedInst_vecWen                    (simple_inst[i].vecWen),
      .io_deq_decodedInst_isXSTrap                  (simple_inst[i].isXSTrap),
      .io_deq_decodedInst_waitForward               (simple_inst[i].waitForward),
      .io_deq_decodedInst_blockBackward             (simple_inst[i].blockBackward),
      .io_deq_decodedInst_flushPipe                 (simple_inst[i].flushPipe),
      .io_deq_decodedInst_canRobCompress            (simple_inst[i].canRobCompress),
      .io_deq_decodedInst_selImm                    (simple_inst[i].selImm),
      .io_deq_decodedInst_imm                       (simple_inst[i].imm),
      .io_deq_decodedInst_fpu_typeTagOut            (simple_inst[i].fpu_typeTagOut),
      .io_deq_decodedInst_fpu_wflags                (simple_inst[i].fpu_wflags),
      .io_deq_decodedInst_fpu_typ                   (simple_inst[i].fpu_typ),
      .io_deq_decodedInst_fpu_fmt                   (simple_inst[i].fpu_fmt),
      .io_deq_decodedInst_fpu_rm                    (simple_inst[i].fpu_rm),
      .io_deq_decodedInst_vpu_vill                  (simple_inst[i].vpu_vill),
      .io_deq_decodedInst_vpu_vma                   (simple_inst[i].vpu_vma),
      .io_deq_decodedInst_vpu_vta                   (simple_inst[i].vpu_vta),
      .io_deq_decodedInst_vpu_vsew                  (simple_inst[i].vpu_vsew),
      .io_deq_decodedInst_vpu_vlmul                 (simple_inst[i].vpu_vlmul),
      .io_deq_decodedInst_vpu_specVill              (simple_inst[i].vpu_specVill),
      .io_deq_decodedInst_vpu_specVma               (simple_inst[i].vpu_specVma),
      .io_deq_decodedInst_vpu_specVta               (simple_inst[i].vpu_specVta),
      .io_deq_decodedInst_vpu_specVsew              (simple_inst[i].vpu_specVsew),
      .io_deq_decodedInst_vpu_specVlmul             (simple_inst[i].vpu_specVlmul),
      .io_deq_decodedInst_vpu_vm                    (simple_inst[i].vpu_vm),
      .io_deq_decodedInst_vpu_vstart                (simple_inst[i].vpu_vstart),
      .io_deq_decodedInst_vpu_nf                    (simple_inst[i].vpu_nf),
      .io_deq_decodedInst_vpu_veew                  (simple_inst[i].vpu_veew),
      .io_deq_decodedInst_vpu_isReverse             (simple_inst[i].vpu_isReverse),
      .io_deq_decodedInst_vpu_isExt                 (simple_inst[i].vpu_isExt),
      .io_deq_decodedInst_vpu_isNarrow              (simple_inst[i].vpu_isNarrow),
      .io_deq_decodedInst_vpu_isDstMask             (simple_inst[i].vpu_isDstMask),
      .io_deq_decodedInst_vpu_isOpMask              (simple_inst[i].vpu_isOpMask),
      .io_deq_decodedInst_vpu_isDependOldVd         (simple_inst[i].vpu_isDependOldVd),
      .io_deq_decodedInst_vpu_isWritePartVd         (simple_inst[i].vpu_isWritePartVd),
      .io_deq_decodedInst_vpu_isVleff               (simple_inst[i].vpu_isVleff),
      .io_deq_decodedInst_vlsInstr                  (simple_inst[i].vlsInstr),
      .io_deq_decodedInst_wfflags                   (simple_inst[i].wfflags),
      .io_deq_decodedInst_isMove                    (simple_inst[i].isMove),
      .io_deq_decodedInst_uopSplitType              (simple_inst[i].uopSplitType),
      .io_deq_decodedInst_isVset                    (simple_inst[i].isVset),
      .io_deq_decodedInst_commitType                (simple_inst[i].commitType),
      .io_deq_decodedInst_debug_fuType              (simple_inst[i].debug_fuType),
      .io_deq_decodedInst_debug_seqNum_seqNum       (simple_inst[i].debug_seqNum_seqNum),
      .io_deq_decodedInst_debug_seqNum_uopIdx       (simple_inst[i].debug_seqNum_uopIdx),
      .io_deq_isComplex                             (simple_is_complex[i]),
      .io_deq_uopInfo_numOfUop                      (simple_uop_info[i].numOfUop),
      .io_deq_uopInfo_numOfWB                       (simple_uop_info[i].numOfWB),
      .io_deq_uopInfo_lmul                          (simple_uop_info[i].lmul),
      .io_csrCtrl_singlestep                        (csrCtrl_singlestep),
      .io_fromCSR_illegalInst_sfenceVMA             (fromCSR.illegalInst_sfenceVMA),
      .io_fromCSR_illegalInst_sfencePart            (fromCSR.illegalInst_sfencePart),
      .io_fromCSR_illegalInst_hfenceGVMA            (fromCSR.illegalInst_hfenceGVMA),
      .io_fromCSR_illegalInst_hfenceVVMA            (fromCSR.illegalInst_hfenceVVMA),
      .io_fromCSR_illegalInst_hlsv                  (fromCSR.illegalInst_hlsv),
      .io_fromCSR_illegalInst_fsIsOff               (fromCSR.illegalInst_fsIsOff),
      .io_fromCSR_illegalInst_vsIsOff               (fromCSR.illegalInst_vsIsOff),
      .io_fromCSR_illegalInst_wfi                   (fromCSR.illegalInst_wfi),
      .io_fromCSR_illegalInst_wrs_nto               (fromCSR.illegalInst_wrs_nto),
      .io_fromCSR_illegalInst_frm                   (fromCSR.illegalInst_frm),
      .io_fromCSR_illegalInst_cboZ                  (fromCSR.illegalInst_cboZ),
      .io_fromCSR_illegalInst_cboCF                 (fromCSR.illegalInst_cboCF),
      .io_fromCSR_illegalInst_cboI                  (fromCSR.illegalInst_cboI),
      .io_fromCSR_virtualInst_sfenceVMA             (fromCSR.virtualInst_sfenceVMA),
      .io_fromCSR_virtualInst_sfencePart            (fromCSR.virtualInst_sfencePart),
      .io_fromCSR_virtualInst_hfence                (fromCSR.virtualInst_hfence),
      .io_fromCSR_virtualInst_hlsv                  (fromCSR.virtualInst_hlsv),
      .io_fromCSR_virtualInst_wfi                   (fromCSR.virtualInst_wfi),
      .io_fromCSR_virtualInst_wrs_nto               (fromCSR.virtualInst_wrs_nto),
      .io_fromCSR_virtualInst_cboZ                  (fromCSR.virtualInst_cboZ),
      .io_fromCSR_virtualInst_cboCF                 (fromCSR.virtualInst_cboCF),
      .io_fromCSR_virtualInst_cboI                  (fromCSR.virtualInst_cboI),
      .io_fromCSR_special_cboI2F                    (fromCSR.special_cboI2F)
    );
    // DecodeUnit 没有这 10 个 DecodedInst 字段（firtool 在 golden 里把它们折成了常量），
    // 常量取自 golden DecodeStage 简单译码那一支的 assign。
    assign simple_inst[i].v0Wen = 1'b0;
    assign simple_inst[i].vlWen = 1'b0;
    assign simple_inst[i].vpu_fpu_isFoldTo1_2 = 1'b0;
    assign simple_inst[i].vpu_fpu_isFoldTo1_4 = 1'b0;
    assign simple_inst[i].vpu_fpu_isFoldTo1_8 = 1'b0;
    assign simple_inst[i].uopIdx = 7'd0;
    assign simple_inst[i].firstUop = 1'b1;
    assign simple_inst[i].lastUop = 1'b1;
    assign simple_inst[i].numUops = 7'd1;
    assign simple_inst[i].numWB = 7'd1;
  end
  // END GENERATED

  // BEGIN GENERATED(complex_decoder)
  // 复杂译码器：一次锁存一条复杂指令，按 uopSplitType 拆成最多 65 个 uop，每拍最多吐 6 个。
  DecodeUnitComp u_complex (
    .clock                                          (clock),
    .reset                                          (reset),
    .io_redirect                                    (redirect),
    .io_vtypeBypass_illegal                         (vtype.illegal),
    .io_vtypeBypass_vma                             (vtype.vma),
    .io_vtypeBypass_vta                             (vtype.vta),
    .io_vtypeBypass_vsew                            (vtype.vsew),
    .io_vtypeBypass_vlmul                           (vtype.vlmul),
    .io_in_ready                                    (complex_in_ready),
    .io_in_valid                                    (complex_in_valid),
    .io_in_bits_simpleDecodedInst_instr             (complex_in_inst.instr),
    .io_in_bits_simpleDecodedInst_pc                (complex_in_inst.pc),
    .io_in_bits_simpleDecodedInst_foldpc            (complex_in_inst.foldpc),
    .io_in_bits_simpleDecodedInst_exceptionVec_0    (complex_in_inst.exceptionVec[0]),
    .io_in_bits_simpleDecodedInst_exceptionVec_1    (complex_in_inst.exceptionVec[1]),
    .io_in_bits_simpleDecodedInst_exceptionVec_2    (complex_in_inst.exceptionVec[2]),
    .io_in_bits_simpleDecodedInst_exceptionVec_3    (complex_in_inst.exceptionVec[3]),
    .io_in_bits_simpleDecodedInst_exceptionVec_4    (complex_in_inst.exceptionVec[4]),
    .io_in_bits_simpleDecodedInst_exceptionVec_5    (complex_in_inst.exceptionVec[5]),
    .io_in_bits_simpleDecodedInst_exceptionVec_6    (complex_in_inst.exceptionVec[6]),
    .io_in_bits_simpleDecodedInst_exceptionVec_7    (complex_in_inst.exceptionVec[7]),
    .io_in_bits_simpleDecodedInst_exceptionVec_8    (complex_in_inst.exceptionVec[8]),
    .io_in_bits_simpleDecodedInst_exceptionVec_9    (complex_in_inst.exceptionVec[9]),
    .io_in_bits_simpleDecodedInst_exceptionVec_10   (complex_in_inst.exceptionVec[10]),
    .io_in_bits_simpleDecodedInst_exceptionVec_11   (complex_in_inst.exceptionVec[11]),
    .io_in_bits_simpleDecodedInst_exceptionVec_12   (complex_in_inst.exceptionVec[12]),
    .io_in_bits_simpleDecodedInst_exceptionVec_13   (complex_in_inst.exceptionVec[13]),
    .io_in_bits_simpleDecodedInst_exceptionVec_14   (complex_in_inst.exceptionVec[14]),
    .io_in_bits_simpleDecodedInst_exceptionVec_15   (complex_in_inst.exceptionVec[15]),
    .io_in_bits_simpleDecodedInst_exceptionVec_16   (complex_in_inst.exceptionVec[16]),
    .io_in_bits_simpleDecodedInst_exceptionVec_17   (complex_in_inst.exceptionVec[17]),
    .io_in_bits_simpleDecodedInst_exceptionVec_18   (complex_in_inst.exceptionVec[18]),
    .io_in_bits_simpleDecodedInst_exceptionVec_19   (complex_in_inst.exceptionVec[19]),
    .io_in_bits_simpleDecodedInst_exceptionVec_20   (complex_in_inst.exceptionVec[20]),
    .io_in_bits_simpleDecodedInst_exceptionVec_21   (complex_in_inst.exceptionVec[21]),
    .io_in_bits_simpleDecodedInst_exceptionVec_22   (complex_in_inst.exceptionVec[22]),
    .io_in_bits_simpleDecodedInst_exceptionVec_23   (complex_in_inst.exceptionVec[23]),
    .io_in_bits_simpleDecodedInst_isFetchMalAddr    (complex_in_inst.isFetchMalAddr),
    .io_in_bits_simpleDecodedInst_trigger           (complex_in_inst.trigger),
    .io_in_bits_simpleDecodedInst_preDecodeInfo_valid (complex_in_inst.preDecodeInfo_valid),
    .io_in_bits_simpleDecodedInst_preDecodeInfo_isRVC (complex_in_inst.preDecodeInfo_isRVC),
    .io_in_bits_simpleDecodedInst_preDecodeInfo_brType (complex_in_inst.preDecodeInfo_brType),
    .io_in_bits_simpleDecodedInst_preDecodeInfo_isCall (complex_in_inst.preDecodeInfo_isCall),
    .io_in_bits_simpleDecodedInst_preDecodeInfo_isRet (complex_in_inst.preDecodeInfo_isRet),
    .io_in_bits_simpleDecodedInst_pred_taken        (complex_in_inst.pred_taken),
    .io_in_bits_simpleDecodedInst_crossPageIPFFix   (complex_in_inst.crossPageIPFFix),
    .io_in_bits_simpleDecodedInst_ftqPtr_flag       (complex_in_inst.ftqPtr_flag),
    .io_in_bits_simpleDecodedInst_ftqPtr_value      (complex_in_inst.ftqPtr_value),
    .io_in_bits_simpleDecodedInst_ftqOffset         (complex_in_inst.ftqOffset),
    .io_in_bits_simpleDecodedInst_satpFlushFirstFetchFault (complex_in_inst.satpFlushFirstFetchFault),
    .io_in_bits_simpleDecodedInst_srcType_0         (complex_in_inst.srcType[0]),
    .io_in_bits_simpleDecodedInst_srcType_1         (complex_in_inst.srcType[1]),
    .io_in_bits_simpleDecodedInst_srcType_2         (complex_in_inst.srcType[2]),
    .io_in_bits_simpleDecodedInst_srcType_3         (complex_in_inst.srcType[3]),
    .io_in_bits_simpleDecodedInst_srcType_4         (complex_in_inst.srcType[4]),
    .io_in_bits_simpleDecodedInst_lsrc_0            (complex_in_inst.lsrc[0]),
    .io_in_bits_simpleDecodedInst_lsrc_1            (complex_in_inst.lsrc[1]),
    .io_in_bits_simpleDecodedInst_lsrc_2            (complex_in_inst.lsrc[2]),
    .io_in_bits_simpleDecodedInst_ldest             (complex_in_inst.ldest),
    .io_in_bits_simpleDecodedInst_fuType            (complex_in_inst.fuType),
    .io_in_bits_simpleDecodedInst_fuOpType          (complex_in_inst.fuOpType),
    .io_in_bits_simpleDecodedInst_rfWen             (complex_in_inst.rfWen),
    .io_in_bits_simpleDecodedInst_fpWen             (complex_in_inst.fpWen),
    .io_in_bits_simpleDecodedInst_vecWen            (complex_in_inst.vecWen),
    .io_in_bits_simpleDecodedInst_isXSTrap          (complex_in_inst.isXSTrap),
    .io_in_bits_simpleDecodedInst_waitForward       (complex_in_inst.waitForward),
    .io_in_bits_simpleDecodedInst_blockBackward     (complex_in_inst.blockBackward),
    .io_in_bits_simpleDecodedInst_flushPipe         (complex_in_inst.flushPipe),
    .io_in_bits_simpleDecodedInst_canRobCompress    (complex_in_inst.canRobCompress),
    .io_in_bits_simpleDecodedInst_selImm            (complex_in_inst.selImm),
    .io_in_bits_simpleDecodedInst_imm               (complex_in_inst.imm),
    .io_in_bits_simpleDecodedInst_fpu_typeTagOut    (complex_in_inst.fpu_typeTagOut),
    .io_in_bits_simpleDecodedInst_fpu_wflags        (complex_in_inst.fpu_wflags),
    .io_in_bits_simpleDecodedInst_fpu_typ           (complex_in_inst.fpu_typ),
    .io_in_bits_simpleDecodedInst_fpu_fmt           (complex_in_inst.fpu_fmt),
    .io_in_bits_simpleDecodedInst_fpu_rm            (complex_in_inst.fpu_rm),
    .io_in_bits_simpleDecodedInst_vpu_vill          (complex_in_inst.vpu_vill),
    .io_in_bits_simpleDecodedInst_vpu_vma           (complex_in_inst.vpu_vma),
    .io_in_bits_simpleDecodedInst_vpu_vta           (complex_in_inst.vpu_vta),
    .io_in_bits_simpleDecodedInst_vpu_vsew          (complex_in_inst.vpu_vsew),
    .io_in_bits_simpleDecodedInst_vpu_vlmul         (complex_in_inst.vpu_vlmul),
    .io_in_bits_simpleDecodedInst_vpu_specVill      (complex_in_inst.vpu_specVill),
    .io_in_bits_simpleDecodedInst_vpu_specVma       (complex_in_inst.vpu_specVma),
    .io_in_bits_simpleDecodedInst_vpu_specVta       (complex_in_inst.vpu_specVta),
    .io_in_bits_simpleDecodedInst_vpu_specVsew      (complex_in_inst.vpu_specVsew),
    .io_in_bits_simpleDecodedInst_vpu_specVlmul     (complex_in_inst.vpu_specVlmul),
    .io_in_bits_simpleDecodedInst_vpu_vm            (complex_in_inst.vpu_vm),
    .io_in_bits_simpleDecodedInst_vpu_vstart        (complex_in_inst.vpu_vstart),
    .io_in_bits_simpleDecodedInst_vpu_nf            (complex_in_inst.vpu_nf),
    .io_in_bits_simpleDecodedInst_vpu_veew          (complex_in_inst.vpu_veew),
    .io_in_bits_simpleDecodedInst_vpu_isReverse     (complex_in_inst.vpu_isReverse),
    .io_in_bits_simpleDecodedInst_vpu_isExt         (complex_in_inst.vpu_isExt),
    .io_in_bits_simpleDecodedInst_vpu_isNarrow      (complex_in_inst.vpu_isNarrow),
    .io_in_bits_simpleDecodedInst_vpu_isDstMask     (complex_in_inst.vpu_isDstMask),
    .io_in_bits_simpleDecodedInst_vpu_isOpMask      (complex_in_inst.vpu_isOpMask),
    .io_in_bits_simpleDecodedInst_vpu_isDependOldVd (complex_in_inst.vpu_isDependOldVd),
    .io_in_bits_simpleDecodedInst_vpu_isWritePartVd (complex_in_inst.vpu_isWritePartVd),
    .io_in_bits_simpleDecodedInst_vpu_isVleff       (complex_in_inst.vpu_isVleff),
    .io_in_bits_simpleDecodedInst_wfflags           (complex_in_inst.wfflags),
    .io_in_bits_simpleDecodedInst_isMove            (complex_in_inst.isMove),
    .io_in_bits_simpleDecodedInst_uopSplitType      (complex_in_inst.uopSplitType),
    .io_in_bits_simpleDecodedInst_isVset            (complex_in_inst.isVset),
    .io_in_bits_simpleDecodedInst_commitType        (complex_in_inst.commitType),
    .io_in_bits_simpleDecodedInst_debug_fuType      (complex_in_inst.debug_fuType),
    .io_in_bits_simpleDecodedInst_debug_seqNum_seqNum (complex_in_inst.debug_seqNum_seqNum),
    .io_in_bits_simpleDecodedInst_debug_seqNum_uopIdx (complex_in_inst.debug_seqNum_uopIdx),
    .io_in_bits_uopInfo_numOfUop                    (complex_in_uop_info.numOfUop),
    .io_in_bits_uopInfo_numOfWB                     (complex_in_uop_info.numOfWB),
    .io_in_bits_uopInfo_lmul                        (complex_in_uop_info.lmul),
    .io_out_complexDecodedInsts_0_ready             (out_ready[0]),
    .io_out_complexDecodedInsts_0_valid             (complex_valid[0]),
    .io_out_complexDecodedInsts_0_bits_instr        (complex_inst[0].instr),
    .io_out_complexDecodedInsts_0_bits_pc           (complex_inst[0].pc),
    .io_out_complexDecodedInsts_0_bits_foldpc       (complex_inst[0].foldpc),
    .io_out_complexDecodedInsts_0_bits_exceptionVec_0 (complex_inst[0].exceptionVec[0]),
    .io_out_complexDecodedInsts_0_bits_exceptionVec_1 (complex_inst[0].exceptionVec[1]),
    .io_out_complexDecodedInsts_0_bits_exceptionVec_2 (complex_inst[0].exceptionVec[2]),
    .io_out_complexDecodedInsts_0_bits_exceptionVec_3 (complex_inst[0].exceptionVec[3]),
    .io_out_complexDecodedInsts_0_bits_exceptionVec_4 (complex_inst[0].exceptionVec[4]),
    .io_out_complexDecodedInsts_0_bits_exceptionVec_5 (complex_inst[0].exceptionVec[5]),
    .io_out_complexDecodedInsts_0_bits_exceptionVec_6 (complex_inst[0].exceptionVec[6]),
    .io_out_complexDecodedInsts_0_bits_exceptionVec_7 (complex_inst[0].exceptionVec[7]),
    .io_out_complexDecodedInsts_0_bits_exceptionVec_8 (complex_inst[0].exceptionVec[8]),
    .io_out_complexDecodedInsts_0_bits_exceptionVec_9 (complex_inst[0].exceptionVec[9]),
    .io_out_complexDecodedInsts_0_bits_exceptionVec_10 (complex_inst[0].exceptionVec[10]),
    .io_out_complexDecodedInsts_0_bits_exceptionVec_11 (complex_inst[0].exceptionVec[11]),
    .io_out_complexDecodedInsts_0_bits_exceptionVec_12 (complex_inst[0].exceptionVec[12]),
    .io_out_complexDecodedInsts_0_bits_exceptionVec_13 (complex_inst[0].exceptionVec[13]),
    .io_out_complexDecodedInsts_0_bits_exceptionVec_14 (complex_inst[0].exceptionVec[14]),
    .io_out_complexDecodedInsts_0_bits_exceptionVec_15 (complex_inst[0].exceptionVec[15]),
    .io_out_complexDecodedInsts_0_bits_exceptionVec_16 (complex_inst[0].exceptionVec[16]),
    .io_out_complexDecodedInsts_0_bits_exceptionVec_17 (complex_inst[0].exceptionVec[17]),
    .io_out_complexDecodedInsts_0_bits_exceptionVec_18 (complex_inst[0].exceptionVec[18]),
    .io_out_complexDecodedInsts_0_bits_exceptionVec_19 (complex_inst[0].exceptionVec[19]),
    .io_out_complexDecodedInsts_0_bits_exceptionVec_20 (complex_inst[0].exceptionVec[20]),
    .io_out_complexDecodedInsts_0_bits_exceptionVec_21 (complex_inst[0].exceptionVec[21]),
    .io_out_complexDecodedInsts_0_bits_exceptionVec_22 (complex_inst[0].exceptionVec[22]),
    .io_out_complexDecodedInsts_0_bits_exceptionVec_23 (complex_inst[0].exceptionVec[23]),
    .io_out_complexDecodedInsts_0_bits_isFetchMalAddr (complex_inst[0].isFetchMalAddr),
    .io_out_complexDecodedInsts_0_bits_trigger      (complex_inst[0].trigger),
    .io_out_complexDecodedInsts_0_bits_preDecodeInfo_valid (complex_inst[0].preDecodeInfo_valid),
    .io_out_complexDecodedInsts_0_bits_preDecodeInfo_isRVC (complex_inst[0].preDecodeInfo_isRVC),
    .io_out_complexDecodedInsts_0_bits_preDecodeInfo_brType (complex_inst[0].preDecodeInfo_brType),
    .io_out_complexDecodedInsts_0_bits_preDecodeInfo_isCall (complex_inst[0].preDecodeInfo_isCall),
    .io_out_complexDecodedInsts_0_bits_preDecodeInfo_isRet (complex_inst[0].preDecodeInfo_isRet),
    .io_out_complexDecodedInsts_0_bits_pred_taken   (complex_inst[0].pred_taken),
    .io_out_complexDecodedInsts_0_bits_crossPageIPFFix (complex_inst[0].crossPageIPFFix),
    .io_out_complexDecodedInsts_0_bits_ftqPtr_flag  (complex_inst[0].ftqPtr_flag),
    .io_out_complexDecodedInsts_0_bits_ftqPtr_value (complex_inst[0].ftqPtr_value),
    .io_out_complexDecodedInsts_0_bits_ftqOffset    (complex_inst[0].ftqOffset),
    .io_out_complexDecodedInsts_0_bits_satpFlushFirstFetchFault (complex_inst[0].satpFlushFirstFetchFault),
    .io_out_complexDecodedInsts_0_bits_srcType_0    (complex_inst[0].srcType[0]),
    .io_out_complexDecodedInsts_0_bits_srcType_1    (complex_inst[0].srcType[1]),
    .io_out_complexDecodedInsts_0_bits_srcType_2    (complex_inst[0].srcType[2]),
    .io_out_complexDecodedInsts_0_bits_srcType_3    (complex_inst[0].srcType[3]),
    .io_out_complexDecodedInsts_0_bits_srcType_4    (complex_inst[0].srcType[4]),
    .io_out_complexDecodedInsts_0_bits_lsrc_0       (complex_inst[0].lsrc[0]),
    .io_out_complexDecodedInsts_0_bits_lsrc_1       (complex_inst[0].lsrc[1]),
    .io_out_complexDecodedInsts_0_bits_lsrc_2       (complex_inst[0].lsrc[2]),
    .io_out_complexDecodedInsts_0_bits_ldest        (complex_inst[0].ldest),
    .io_out_complexDecodedInsts_0_bits_fuType       (complex_inst[0].fuType),
    .io_out_complexDecodedInsts_0_bits_fuOpType     (complex_inst[0].fuOpType),
    .io_out_complexDecodedInsts_0_bits_rfWen        (complex_inst[0].rfWen),
    .io_out_complexDecodedInsts_0_bits_fpWen        (complex_inst[0].fpWen),
    .io_out_complexDecodedInsts_0_bits_vecWen       (complex_inst[0].vecWen),
    .io_out_complexDecodedInsts_0_bits_vlWen        (complex_inst[0].vlWen),
    .io_out_complexDecodedInsts_0_bits_isXSTrap     (complex_inst[0].isXSTrap),
    .io_out_complexDecodedInsts_0_bits_waitForward  (complex_inst[0].waitForward),
    .io_out_complexDecodedInsts_0_bits_blockBackward (complex_inst[0].blockBackward),
    .io_out_complexDecodedInsts_0_bits_flushPipe    (complex_inst[0].flushPipe),
    .io_out_complexDecodedInsts_0_bits_canRobCompress (complex_inst[0].canRobCompress),
    .io_out_complexDecodedInsts_0_bits_selImm       (complex_inst[0].selImm),
    .io_out_complexDecodedInsts_0_bits_imm          (complex_inst[0].imm),
    .io_out_complexDecodedInsts_0_bits_fpu_typeTagOut (complex_inst[0].fpu_typeTagOut),
    .io_out_complexDecodedInsts_0_bits_fpu_wflags   (complex_inst[0].fpu_wflags),
    .io_out_complexDecodedInsts_0_bits_fpu_typ      (complex_inst[0].fpu_typ),
    .io_out_complexDecodedInsts_0_bits_fpu_fmt      (complex_inst[0].fpu_fmt),
    .io_out_complexDecodedInsts_0_bits_fpu_rm       (complex_inst[0].fpu_rm),
    .io_out_complexDecodedInsts_0_bits_vpu_vill     (complex_inst[0].vpu_vill),
    .io_out_complexDecodedInsts_0_bits_vpu_vma      (complex_inst[0].vpu_vma),
    .io_out_complexDecodedInsts_0_bits_vpu_vta      (complex_inst[0].vpu_vta),
    .io_out_complexDecodedInsts_0_bits_vpu_vsew     (complex_inst[0].vpu_vsew),
    .io_out_complexDecodedInsts_0_bits_vpu_vlmul    (complex_inst[0].vpu_vlmul),
    .io_out_complexDecodedInsts_0_bits_vpu_specVill (complex_inst[0].vpu_specVill),
    .io_out_complexDecodedInsts_0_bits_vpu_specVma  (complex_inst[0].vpu_specVma),
    .io_out_complexDecodedInsts_0_bits_vpu_specVta  (complex_inst[0].vpu_specVta),
    .io_out_complexDecodedInsts_0_bits_vpu_specVsew (complex_inst[0].vpu_specVsew),
    .io_out_complexDecodedInsts_0_bits_vpu_specVlmul (complex_inst[0].vpu_specVlmul),
    .io_out_complexDecodedInsts_0_bits_vpu_vm       (complex_inst[0].vpu_vm),
    .io_out_complexDecodedInsts_0_bits_vpu_vstart   (complex_inst[0].vpu_vstart),
    .io_out_complexDecodedInsts_0_bits_vpu_fpu_isFoldTo1_2 (complex_inst[0].vpu_fpu_isFoldTo1_2),
    .io_out_complexDecodedInsts_0_bits_vpu_fpu_isFoldTo1_4 (complex_inst[0].vpu_fpu_isFoldTo1_4),
    .io_out_complexDecodedInsts_0_bits_vpu_fpu_isFoldTo1_8 (complex_inst[0].vpu_fpu_isFoldTo1_8),
    .io_out_complexDecodedInsts_0_bits_vpu_nf       (complex_inst[0].vpu_nf),
    .io_out_complexDecodedInsts_0_bits_vpu_veew     (complex_inst[0].vpu_veew),
    .io_out_complexDecodedInsts_0_bits_vpu_isReverse (complex_inst[0].vpu_isReverse),
    .io_out_complexDecodedInsts_0_bits_vpu_isExt    (complex_inst[0].vpu_isExt),
    .io_out_complexDecodedInsts_0_bits_vpu_isNarrow (complex_inst[0].vpu_isNarrow),
    .io_out_complexDecodedInsts_0_bits_vpu_isDstMask (complex_inst[0].vpu_isDstMask),
    .io_out_complexDecodedInsts_0_bits_vpu_isOpMask (complex_inst[0].vpu_isOpMask),
    .io_out_complexDecodedInsts_0_bits_vpu_isDependOldVd (complex_inst[0].vpu_isDependOldVd),
    .io_out_complexDecodedInsts_0_bits_vpu_isWritePartVd (complex_inst[0].vpu_isWritePartVd),
    .io_out_complexDecodedInsts_0_bits_vpu_isVleff  (complex_inst[0].vpu_isVleff),
    .io_out_complexDecodedInsts_0_bits_vlsInstr     (complex_inst[0].vlsInstr),
    .io_out_complexDecodedInsts_0_bits_wfflags      (complex_inst[0].wfflags),
    .io_out_complexDecodedInsts_0_bits_isMove       (complex_inst[0].isMove),
    .io_out_complexDecodedInsts_0_bits_uopIdx       (complex_inst[0].uopIdx),
    .io_out_complexDecodedInsts_0_bits_uopSplitType (complex_inst[0].uopSplitType),
    .io_out_complexDecodedInsts_0_bits_isVset       (complex_inst[0].isVset),
    .io_out_complexDecodedInsts_0_bits_firstUop     (complex_inst[0].firstUop),
    .io_out_complexDecodedInsts_0_bits_lastUop      (complex_inst[0].lastUop),
    .io_out_complexDecodedInsts_0_bits_numUops      (complex_inst[0].numUops),
    .io_out_complexDecodedInsts_0_bits_numWB        (complex_inst[0].numWB),
    .io_out_complexDecodedInsts_0_bits_commitType   (complex_inst[0].commitType),
    .io_out_complexDecodedInsts_0_bits_debug_fuType (complex_inst[0].debug_fuType),
    .io_out_complexDecodedInsts_0_bits_debug_seqNum_seqNum (complex_inst[0].debug_seqNum_seqNum),
    .io_out_complexDecodedInsts_0_bits_debug_seqNum_uopIdx (complex_inst[0].debug_seqNum_uopIdx),
    .io_out_complexDecodedInsts_1_valid             (complex_valid[1]),
    .io_out_complexDecodedInsts_1_bits_instr        (complex_inst[1].instr),
    .io_out_complexDecodedInsts_1_bits_pc           (complex_inst[1].pc),
    .io_out_complexDecodedInsts_1_bits_foldpc       (complex_inst[1].foldpc),
    .io_out_complexDecodedInsts_1_bits_exceptionVec_0 (complex_inst[1].exceptionVec[0]),
    .io_out_complexDecodedInsts_1_bits_exceptionVec_1 (complex_inst[1].exceptionVec[1]),
    .io_out_complexDecodedInsts_1_bits_exceptionVec_2 (complex_inst[1].exceptionVec[2]),
    .io_out_complexDecodedInsts_1_bits_exceptionVec_3 (complex_inst[1].exceptionVec[3]),
    .io_out_complexDecodedInsts_1_bits_exceptionVec_4 (complex_inst[1].exceptionVec[4]),
    .io_out_complexDecodedInsts_1_bits_exceptionVec_5 (complex_inst[1].exceptionVec[5]),
    .io_out_complexDecodedInsts_1_bits_exceptionVec_6 (complex_inst[1].exceptionVec[6]),
    .io_out_complexDecodedInsts_1_bits_exceptionVec_7 (complex_inst[1].exceptionVec[7]),
    .io_out_complexDecodedInsts_1_bits_exceptionVec_8 (complex_inst[1].exceptionVec[8]),
    .io_out_complexDecodedInsts_1_bits_exceptionVec_9 (complex_inst[1].exceptionVec[9]),
    .io_out_complexDecodedInsts_1_bits_exceptionVec_10 (complex_inst[1].exceptionVec[10]),
    .io_out_complexDecodedInsts_1_bits_exceptionVec_11 (complex_inst[1].exceptionVec[11]),
    .io_out_complexDecodedInsts_1_bits_exceptionVec_12 (complex_inst[1].exceptionVec[12]),
    .io_out_complexDecodedInsts_1_bits_exceptionVec_13 (complex_inst[1].exceptionVec[13]),
    .io_out_complexDecodedInsts_1_bits_exceptionVec_14 (complex_inst[1].exceptionVec[14]),
    .io_out_complexDecodedInsts_1_bits_exceptionVec_15 (complex_inst[1].exceptionVec[15]),
    .io_out_complexDecodedInsts_1_bits_exceptionVec_16 (complex_inst[1].exceptionVec[16]),
    .io_out_complexDecodedInsts_1_bits_exceptionVec_17 (complex_inst[1].exceptionVec[17]),
    .io_out_complexDecodedInsts_1_bits_exceptionVec_18 (complex_inst[1].exceptionVec[18]),
    .io_out_complexDecodedInsts_1_bits_exceptionVec_19 (complex_inst[1].exceptionVec[19]),
    .io_out_complexDecodedInsts_1_bits_exceptionVec_20 (complex_inst[1].exceptionVec[20]),
    .io_out_complexDecodedInsts_1_bits_exceptionVec_21 (complex_inst[1].exceptionVec[21]),
    .io_out_complexDecodedInsts_1_bits_exceptionVec_22 (complex_inst[1].exceptionVec[22]),
    .io_out_complexDecodedInsts_1_bits_exceptionVec_23 (complex_inst[1].exceptionVec[23]),
    .io_out_complexDecodedInsts_1_bits_isFetchMalAddr (complex_inst[1].isFetchMalAddr),
    .io_out_complexDecodedInsts_1_bits_trigger      (complex_inst[1].trigger),
    .io_out_complexDecodedInsts_1_bits_preDecodeInfo_valid (complex_inst[1].preDecodeInfo_valid),
    .io_out_complexDecodedInsts_1_bits_preDecodeInfo_isRVC (complex_inst[1].preDecodeInfo_isRVC),
    .io_out_complexDecodedInsts_1_bits_preDecodeInfo_brType (complex_inst[1].preDecodeInfo_brType),
    .io_out_complexDecodedInsts_1_bits_preDecodeInfo_isCall (complex_inst[1].preDecodeInfo_isCall),
    .io_out_complexDecodedInsts_1_bits_preDecodeInfo_isRet (complex_inst[1].preDecodeInfo_isRet),
    .io_out_complexDecodedInsts_1_bits_pred_taken   (complex_inst[1].pred_taken),
    .io_out_complexDecodedInsts_1_bits_crossPageIPFFix (complex_inst[1].crossPageIPFFix),
    .io_out_complexDecodedInsts_1_bits_ftqPtr_flag  (complex_inst[1].ftqPtr_flag),
    .io_out_complexDecodedInsts_1_bits_ftqPtr_value (complex_inst[1].ftqPtr_value),
    .io_out_complexDecodedInsts_1_bits_ftqOffset    (complex_inst[1].ftqOffset),
    .io_out_complexDecodedInsts_1_bits_satpFlushFirstFetchFault (complex_inst[1].satpFlushFirstFetchFault),
    .io_out_complexDecodedInsts_1_bits_srcType_0    (complex_inst[1].srcType[0]),
    .io_out_complexDecodedInsts_1_bits_srcType_1    (complex_inst[1].srcType[1]),
    .io_out_complexDecodedInsts_1_bits_srcType_2    (complex_inst[1].srcType[2]),
    .io_out_complexDecodedInsts_1_bits_srcType_3    (complex_inst[1].srcType[3]),
    .io_out_complexDecodedInsts_1_bits_srcType_4    (complex_inst[1].srcType[4]),
    .io_out_complexDecodedInsts_1_bits_lsrc_0       (complex_inst[1].lsrc[0]),
    .io_out_complexDecodedInsts_1_bits_lsrc_1       (complex_inst[1].lsrc[1]),
    .io_out_complexDecodedInsts_1_bits_lsrc_2       (complex_inst[1].lsrc[2]),
    .io_out_complexDecodedInsts_1_bits_ldest        (complex_inst[1].ldest),
    .io_out_complexDecodedInsts_1_bits_fuType       (complex_inst[1].fuType),
    .io_out_complexDecodedInsts_1_bits_fuOpType     (complex_inst[1].fuOpType),
    .io_out_complexDecodedInsts_1_bits_rfWen        (complex_inst[1].rfWen),
    .io_out_complexDecodedInsts_1_bits_fpWen        (complex_inst[1].fpWen),
    .io_out_complexDecodedInsts_1_bits_vecWen       (complex_inst[1].vecWen),
    .io_out_complexDecodedInsts_1_bits_vlWen        (complex_inst[1].vlWen),
    .io_out_complexDecodedInsts_1_bits_isXSTrap     (complex_inst[1].isXSTrap),
    .io_out_complexDecodedInsts_1_bits_waitForward  (complex_inst[1].waitForward),
    .io_out_complexDecodedInsts_1_bits_blockBackward (complex_inst[1].blockBackward),
    .io_out_complexDecodedInsts_1_bits_flushPipe    (complex_inst[1].flushPipe),
    .io_out_complexDecodedInsts_1_bits_canRobCompress (complex_inst[1].canRobCompress),
    .io_out_complexDecodedInsts_1_bits_selImm       (complex_inst[1].selImm),
    .io_out_complexDecodedInsts_1_bits_imm          (complex_inst[1].imm),
    .io_out_complexDecodedInsts_1_bits_fpu_typeTagOut (complex_inst[1].fpu_typeTagOut),
    .io_out_complexDecodedInsts_1_bits_fpu_wflags   (complex_inst[1].fpu_wflags),
    .io_out_complexDecodedInsts_1_bits_fpu_typ      (complex_inst[1].fpu_typ),
    .io_out_complexDecodedInsts_1_bits_fpu_fmt      (complex_inst[1].fpu_fmt),
    .io_out_complexDecodedInsts_1_bits_fpu_rm       (complex_inst[1].fpu_rm),
    .io_out_complexDecodedInsts_1_bits_vpu_vill     (complex_inst[1].vpu_vill),
    .io_out_complexDecodedInsts_1_bits_vpu_vma      (complex_inst[1].vpu_vma),
    .io_out_complexDecodedInsts_1_bits_vpu_vta      (complex_inst[1].vpu_vta),
    .io_out_complexDecodedInsts_1_bits_vpu_vsew     (complex_inst[1].vpu_vsew),
    .io_out_complexDecodedInsts_1_bits_vpu_vlmul    (complex_inst[1].vpu_vlmul),
    .io_out_complexDecodedInsts_1_bits_vpu_specVill (complex_inst[1].vpu_specVill),
    .io_out_complexDecodedInsts_1_bits_vpu_specVma  (complex_inst[1].vpu_specVma),
    .io_out_complexDecodedInsts_1_bits_vpu_specVta  (complex_inst[1].vpu_specVta),
    .io_out_complexDecodedInsts_1_bits_vpu_specVsew (complex_inst[1].vpu_specVsew),
    .io_out_complexDecodedInsts_1_bits_vpu_specVlmul (complex_inst[1].vpu_specVlmul),
    .io_out_complexDecodedInsts_1_bits_vpu_vm       (complex_inst[1].vpu_vm),
    .io_out_complexDecodedInsts_1_bits_vpu_vstart   (complex_inst[1].vpu_vstart),
    .io_out_complexDecodedInsts_1_bits_vpu_fpu_isFoldTo1_2 (complex_inst[1].vpu_fpu_isFoldTo1_2),
    .io_out_complexDecodedInsts_1_bits_vpu_fpu_isFoldTo1_4 (complex_inst[1].vpu_fpu_isFoldTo1_4),
    .io_out_complexDecodedInsts_1_bits_vpu_fpu_isFoldTo1_8 (complex_inst[1].vpu_fpu_isFoldTo1_8),
    .io_out_complexDecodedInsts_1_bits_vpu_nf       (complex_inst[1].vpu_nf),
    .io_out_complexDecodedInsts_1_bits_vpu_veew     (complex_inst[1].vpu_veew),
    .io_out_complexDecodedInsts_1_bits_vpu_isReverse (complex_inst[1].vpu_isReverse),
    .io_out_complexDecodedInsts_1_bits_vpu_isExt    (complex_inst[1].vpu_isExt),
    .io_out_complexDecodedInsts_1_bits_vpu_isNarrow (complex_inst[1].vpu_isNarrow),
    .io_out_complexDecodedInsts_1_bits_vpu_isDstMask (complex_inst[1].vpu_isDstMask),
    .io_out_complexDecodedInsts_1_bits_vpu_isOpMask (complex_inst[1].vpu_isOpMask),
    .io_out_complexDecodedInsts_1_bits_vpu_isDependOldVd (complex_inst[1].vpu_isDependOldVd),
    .io_out_complexDecodedInsts_1_bits_vpu_isWritePartVd (complex_inst[1].vpu_isWritePartVd),
    .io_out_complexDecodedInsts_1_bits_vpu_isVleff  (complex_inst[1].vpu_isVleff),
    .io_out_complexDecodedInsts_1_bits_vlsInstr     (complex_inst[1].vlsInstr),
    .io_out_complexDecodedInsts_1_bits_wfflags      (complex_inst[1].wfflags),
    .io_out_complexDecodedInsts_1_bits_isMove       (complex_inst[1].isMove),
    .io_out_complexDecodedInsts_1_bits_uopIdx       (complex_inst[1].uopIdx),
    .io_out_complexDecodedInsts_1_bits_uopSplitType (complex_inst[1].uopSplitType),
    .io_out_complexDecodedInsts_1_bits_isVset       (complex_inst[1].isVset),
    .io_out_complexDecodedInsts_1_bits_lastUop      (complex_inst[1].lastUop),
    .io_out_complexDecodedInsts_1_bits_numUops      (complex_inst[1].numUops),
    .io_out_complexDecodedInsts_1_bits_numWB        (complex_inst[1].numWB),
    .io_out_complexDecodedInsts_1_bits_commitType   (complex_inst[1].commitType),
    .io_out_complexDecodedInsts_1_bits_debug_fuType (complex_inst[1].debug_fuType),
    .io_out_complexDecodedInsts_1_bits_debug_seqNum_seqNum (complex_inst[1].debug_seqNum_seqNum),
    .io_out_complexDecodedInsts_1_bits_debug_seqNum_uopIdx (complex_inst[1].debug_seqNum_uopIdx),
    .io_out_complexDecodedInsts_2_valid             (complex_valid[2]),
    .io_out_complexDecodedInsts_2_bits_instr        (complex_inst[2].instr),
    .io_out_complexDecodedInsts_2_bits_pc           (complex_inst[2].pc),
    .io_out_complexDecodedInsts_2_bits_foldpc       (complex_inst[2].foldpc),
    .io_out_complexDecodedInsts_2_bits_exceptionVec_0 (complex_inst[2].exceptionVec[0]),
    .io_out_complexDecodedInsts_2_bits_exceptionVec_1 (complex_inst[2].exceptionVec[1]),
    .io_out_complexDecodedInsts_2_bits_exceptionVec_2 (complex_inst[2].exceptionVec[2]),
    .io_out_complexDecodedInsts_2_bits_exceptionVec_3 (complex_inst[2].exceptionVec[3]),
    .io_out_complexDecodedInsts_2_bits_exceptionVec_4 (complex_inst[2].exceptionVec[4]),
    .io_out_complexDecodedInsts_2_bits_exceptionVec_5 (complex_inst[2].exceptionVec[5]),
    .io_out_complexDecodedInsts_2_bits_exceptionVec_6 (complex_inst[2].exceptionVec[6]),
    .io_out_complexDecodedInsts_2_bits_exceptionVec_7 (complex_inst[2].exceptionVec[7]),
    .io_out_complexDecodedInsts_2_bits_exceptionVec_8 (complex_inst[2].exceptionVec[8]),
    .io_out_complexDecodedInsts_2_bits_exceptionVec_9 (complex_inst[2].exceptionVec[9]),
    .io_out_complexDecodedInsts_2_bits_exceptionVec_10 (complex_inst[2].exceptionVec[10]),
    .io_out_complexDecodedInsts_2_bits_exceptionVec_11 (complex_inst[2].exceptionVec[11]),
    .io_out_complexDecodedInsts_2_bits_exceptionVec_12 (complex_inst[2].exceptionVec[12]),
    .io_out_complexDecodedInsts_2_bits_exceptionVec_13 (complex_inst[2].exceptionVec[13]),
    .io_out_complexDecodedInsts_2_bits_exceptionVec_14 (complex_inst[2].exceptionVec[14]),
    .io_out_complexDecodedInsts_2_bits_exceptionVec_15 (complex_inst[2].exceptionVec[15]),
    .io_out_complexDecodedInsts_2_bits_exceptionVec_16 (complex_inst[2].exceptionVec[16]),
    .io_out_complexDecodedInsts_2_bits_exceptionVec_17 (complex_inst[2].exceptionVec[17]),
    .io_out_complexDecodedInsts_2_bits_exceptionVec_18 (complex_inst[2].exceptionVec[18]),
    .io_out_complexDecodedInsts_2_bits_exceptionVec_19 (complex_inst[2].exceptionVec[19]),
    .io_out_complexDecodedInsts_2_bits_exceptionVec_20 (complex_inst[2].exceptionVec[20]),
    .io_out_complexDecodedInsts_2_bits_exceptionVec_21 (complex_inst[2].exceptionVec[21]),
    .io_out_complexDecodedInsts_2_bits_exceptionVec_22 (complex_inst[2].exceptionVec[22]),
    .io_out_complexDecodedInsts_2_bits_exceptionVec_23 (complex_inst[2].exceptionVec[23]),
    .io_out_complexDecodedInsts_2_bits_isFetchMalAddr (complex_inst[2].isFetchMalAddr),
    .io_out_complexDecodedInsts_2_bits_trigger      (complex_inst[2].trigger),
    .io_out_complexDecodedInsts_2_bits_preDecodeInfo_valid (complex_inst[2].preDecodeInfo_valid),
    .io_out_complexDecodedInsts_2_bits_preDecodeInfo_isRVC (complex_inst[2].preDecodeInfo_isRVC),
    .io_out_complexDecodedInsts_2_bits_preDecodeInfo_brType (complex_inst[2].preDecodeInfo_brType),
    .io_out_complexDecodedInsts_2_bits_preDecodeInfo_isCall (complex_inst[2].preDecodeInfo_isCall),
    .io_out_complexDecodedInsts_2_bits_preDecodeInfo_isRet (complex_inst[2].preDecodeInfo_isRet),
    .io_out_complexDecodedInsts_2_bits_pred_taken   (complex_inst[2].pred_taken),
    .io_out_complexDecodedInsts_2_bits_crossPageIPFFix (complex_inst[2].crossPageIPFFix),
    .io_out_complexDecodedInsts_2_bits_ftqPtr_flag  (complex_inst[2].ftqPtr_flag),
    .io_out_complexDecodedInsts_2_bits_ftqPtr_value (complex_inst[2].ftqPtr_value),
    .io_out_complexDecodedInsts_2_bits_ftqOffset    (complex_inst[2].ftqOffset),
    .io_out_complexDecodedInsts_2_bits_satpFlushFirstFetchFault (complex_inst[2].satpFlushFirstFetchFault),
    .io_out_complexDecodedInsts_2_bits_srcType_0    (complex_inst[2].srcType[0]),
    .io_out_complexDecodedInsts_2_bits_srcType_1    (complex_inst[2].srcType[1]),
    .io_out_complexDecodedInsts_2_bits_srcType_2    (complex_inst[2].srcType[2]),
    .io_out_complexDecodedInsts_2_bits_srcType_3    (complex_inst[2].srcType[3]),
    .io_out_complexDecodedInsts_2_bits_srcType_4    (complex_inst[2].srcType[4]),
    .io_out_complexDecodedInsts_2_bits_lsrc_0       (complex_inst[2].lsrc[0]),
    .io_out_complexDecodedInsts_2_bits_lsrc_1       (complex_inst[2].lsrc[1]),
    .io_out_complexDecodedInsts_2_bits_lsrc_2       (complex_inst[2].lsrc[2]),
    .io_out_complexDecodedInsts_2_bits_ldest        (complex_inst[2].ldest),
    .io_out_complexDecodedInsts_2_bits_fuType       (complex_inst[2].fuType),
    .io_out_complexDecodedInsts_2_bits_fuOpType     (complex_inst[2].fuOpType),
    .io_out_complexDecodedInsts_2_bits_rfWen        (complex_inst[2].rfWen),
    .io_out_complexDecodedInsts_2_bits_fpWen        (complex_inst[2].fpWen),
    .io_out_complexDecodedInsts_2_bits_vecWen       (complex_inst[2].vecWen),
    .io_out_complexDecodedInsts_2_bits_vlWen        (complex_inst[2].vlWen),
    .io_out_complexDecodedInsts_2_bits_isXSTrap     (complex_inst[2].isXSTrap),
    .io_out_complexDecodedInsts_2_bits_waitForward  (complex_inst[2].waitForward),
    .io_out_complexDecodedInsts_2_bits_blockBackward (complex_inst[2].blockBackward),
    .io_out_complexDecodedInsts_2_bits_flushPipe    (complex_inst[2].flushPipe),
    .io_out_complexDecodedInsts_2_bits_canRobCompress (complex_inst[2].canRobCompress),
    .io_out_complexDecodedInsts_2_bits_selImm       (complex_inst[2].selImm),
    .io_out_complexDecodedInsts_2_bits_imm          (complex_inst[2].imm),
    .io_out_complexDecodedInsts_2_bits_fpu_typeTagOut (complex_inst[2].fpu_typeTagOut),
    .io_out_complexDecodedInsts_2_bits_fpu_wflags   (complex_inst[2].fpu_wflags),
    .io_out_complexDecodedInsts_2_bits_fpu_typ      (complex_inst[2].fpu_typ),
    .io_out_complexDecodedInsts_2_bits_fpu_fmt      (complex_inst[2].fpu_fmt),
    .io_out_complexDecodedInsts_2_bits_fpu_rm       (complex_inst[2].fpu_rm),
    .io_out_complexDecodedInsts_2_bits_vpu_vill     (complex_inst[2].vpu_vill),
    .io_out_complexDecodedInsts_2_bits_vpu_vma      (complex_inst[2].vpu_vma),
    .io_out_complexDecodedInsts_2_bits_vpu_vta      (complex_inst[2].vpu_vta),
    .io_out_complexDecodedInsts_2_bits_vpu_vsew     (complex_inst[2].vpu_vsew),
    .io_out_complexDecodedInsts_2_bits_vpu_vlmul    (complex_inst[2].vpu_vlmul),
    .io_out_complexDecodedInsts_2_bits_vpu_specVill (complex_inst[2].vpu_specVill),
    .io_out_complexDecodedInsts_2_bits_vpu_specVma  (complex_inst[2].vpu_specVma),
    .io_out_complexDecodedInsts_2_bits_vpu_specVta  (complex_inst[2].vpu_specVta),
    .io_out_complexDecodedInsts_2_bits_vpu_specVsew (complex_inst[2].vpu_specVsew),
    .io_out_complexDecodedInsts_2_bits_vpu_specVlmul (complex_inst[2].vpu_specVlmul),
    .io_out_complexDecodedInsts_2_bits_vpu_vm       (complex_inst[2].vpu_vm),
    .io_out_complexDecodedInsts_2_bits_vpu_vstart   (complex_inst[2].vpu_vstart),
    .io_out_complexDecodedInsts_2_bits_vpu_fpu_isFoldTo1_2 (complex_inst[2].vpu_fpu_isFoldTo1_2),
    .io_out_complexDecodedInsts_2_bits_vpu_fpu_isFoldTo1_4 (complex_inst[2].vpu_fpu_isFoldTo1_4),
    .io_out_complexDecodedInsts_2_bits_vpu_fpu_isFoldTo1_8 (complex_inst[2].vpu_fpu_isFoldTo1_8),
    .io_out_complexDecodedInsts_2_bits_vpu_nf       (complex_inst[2].vpu_nf),
    .io_out_complexDecodedInsts_2_bits_vpu_veew     (complex_inst[2].vpu_veew),
    .io_out_complexDecodedInsts_2_bits_vpu_isReverse (complex_inst[2].vpu_isReverse),
    .io_out_complexDecodedInsts_2_bits_vpu_isExt    (complex_inst[2].vpu_isExt),
    .io_out_complexDecodedInsts_2_bits_vpu_isNarrow (complex_inst[2].vpu_isNarrow),
    .io_out_complexDecodedInsts_2_bits_vpu_isDstMask (complex_inst[2].vpu_isDstMask),
    .io_out_complexDecodedInsts_2_bits_vpu_isOpMask (complex_inst[2].vpu_isOpMask),
    .io_out_complexDecodedInsts_2_bits_vpu_isDependOldVd (complex_inst[2].vpu_isDependOldVd),
    .io_out_complexDecodedInsts_2_bits_vpu_isWritePartVd (complex_inst[2].vpu_isWritePartVd),
    .io_out_complexDecodedInsts_2_bits_vpu_isVleff  (complex_inst[2].vpu_isVleff),
    .io_out_complexDecodedInsts_2_bits_vlsInstr     (complex_inst[2].vlsInstr),
    .io_out_complexDecodedInsts_2_bits_wfflags      (complex_inst[2].wfflags),
    .io_out_complexDecodedInsts_2_bits_isMove       (complex_inst[2].isMove),
    .io_out_complexDecodedInsts_2_bits_uopIdx       (complex_inst[2].uopIdx),
    .io_out_complexDecodedInsts_2_bits_uopSplitType (complex_inst[2].uopSplitType),
    .io_out_complexDecodedInsts_2_bits_isVset       (complex_inst[2].isVset),
    .io_out_complexDecodedInsts_2_bits_lastUop      (complex_inst[2].lastUop),
    .io_out_complexDecodedInsts_2_bits_numUops      (complex_inst[2].numUops),
    .io_out_complexDecodedInsts_2_bits_numWB        (complex_inst[2].numWB),
    .io_out_complexDecodedInsts_2_bits_commitType   (complex_inst[2].commitType),
    .io_out_complexDecodedInsts_2_bits_debug_fuType (complex_inst[2].debug_fuType),
    .io_out_complexDecodedInsts_2_bits_debug_seqNum_seqNum (complex_inst[2].debug_seqNum_seqNum),
    .io_out_complexDecodedInsts_2_bits_debug_seqNum_uopIdx (complex_inst[2].debug_seqNum_uopIdx),
    .io_out_complexDecodedInsts_3_valid             (complex_valid[3]),
    .io_out_complexDecodedInsts_3_bits_instr        (complex_inst[3].instr),
    .io_out_complexDecodedInsts_3_bits_pc           (complex_inst[3].pc),
    .io_out_complexDecodedInsts_3_bits_foldpc       (complex_inst[3].foldpc),
    .io_out_complexDecodedInsts_3_bits_exceptionVec_0 (complex_inst[3].exceptionVec[0]),
    .io_out_complexDecodedInsts_3_bits_exceptionVec_1 (complex_inst[3].exceptionVec[1]),
    .io_out_complexDecodedInsts_3_bits_exceptionVec_2 (complex_inst[3].exceptionVec[2]),
    .io_out_complexDecodedInsts_3_bits_exceptionVec_3 (complex_inst[3].exceptionVec[3]),
    .io_out_complexDecodedInsts_3_bits_exceptionVec_4 (complex_inst[3].exceptionVec[4]),
    .io_out_complexDecodedInsts_3_bits_exceptionVec_5 (complex_inst[3].exceptionVec[5]),
    .io_out_complexDecodedInsts_3_bits_exceptionVec_6 (complex_inst[3].exceptionVec[6]),
    .io_out_complexDecodedInsts_3_bits_exceptionVec_7 (complex_inst[3].exceptionVec[7]),
    .io_out_complexDecodedInsts_3_bits_exceptionVec_8 (complex_inst[3].exceptionVec[8]),
    .io_out_complexDecodedInsts_3_bits_exceptionVec_9 (complex_inst[3].exceptionVec[9]),
    .io_out_complexDecodedInsts_3_bits_exceptionVec_10 (complex_inst[3].exceptionVec[10]),
    .io_out_complexDecodedInsts_3_bits_exceptionVec_11 (complex_inst[3].exceptionVec[11]),
    .io_out_complexDecodedInsts_3_bits_exceptionVec_12 (complex_inst[3].exceptionVec[12]),
    .io_out_complexDecodedInsts_3_bits_exceptionVec_13 (complex_inst[3].exceptionVec[13]),
    .io_out_complexDecodedInsts_3_bits_exceptionVec_14 (complex_inst[3].exceptionVec[14]),
    .io_out_complexDecodedInsts_3_bits_exceptionVec_15 (complex_inst[3].exceptionVec[15]),
    .io_out_complexDecodedInsts_3_bits_exceptionVec_16 (complex_inst[3].exceptionVec[16]),
    .io_out_complexDecodedInsts_3_bits_exceptionVec_17 (complex_inst[3].exceptionVec[17]),
    .io_out_complexDecodedInsts_3_bits_exceptionVec_18 (complex_inst[3].exceptionVec[18]),
    .io_out_complexDecodedInsts_3_bits_exceptionVec_19 (complex_inst[3].exceptionVec[19]),
    .io_out_complexDecodedInsts_3_bits_exceptionVec_20 (complex_inst[3].exceptionVec[20]),
    .io_out_complexDecodedInsts_3_bits_exceptionVec_21 (complex_inst[3].exceptionVec[21]),
    .io_out_complexDecodedInsts_3_bits_exceptionVec_22 (complex_inst[3].exceptionVec[22]),
    .io_out_complexDecodedInsts_3_bits_exceptionVec_23 (complex_inst[3].exceptionVec[23]),
    .io_out_complexDecodedInsts_3_bits_isFetchMalAddr (complex_inst[3].isFetchMalAddr),
    .io_out_complexDecodedInsts_3_bits_trigger      (complex_inst[3].trigger),
    .io_out_complexDecodedInsts_3_bits_preDecodeInfo_valid (complex_inst[3].preDecodeInfo_valid),
    .io_out_complexDecodedInsts_3_bits_preDecodeInfo_isRVC (complex_inst[3].preDecodeInfo_isRVC),
    .io_out_complexDecodedInsts_3_bits_preDecodeInfo_brType (complex_inst[3].preDecodeInfo_brType),
    .io_out_complexDecodedInsts_3_bits_preDecodeInfo_isCall (complex_inst[3].preDecodeInfo_isCall),
    .io_out_complexDecodedInsts_3_bits_preDecodeInfo_isRet (complex_inst[3].preDecodeInfo_isRet),
    .io_out_complexDecodedInsts_3_bits_pred_taken   (complex_inst[3].pred_taken),
    .io_out_complexDecodedInsts_3_bits_crossPageIPFFix (complex_inst[3].crossPageIPFFix),
    .io_out_complexDecodedInsts_3_bits_ftqPtr_flag  (complex_inst[3].ftqPtr_flag),
    .io_out_complexDecodedInsts_3_bits_ftqPtr_value (complex_inst[3].ftqPtr_value),
    .io_out_complexDecodedInsts_3_bits_ftqOffset    (complex_inst[3].ftqOffset),
    .io_out_complexDecodedInsts_3_bits_satpFlushFirstFetchFault (complex_inst[3].satpFlushFirstFetchFault),
    .io_out_complexDecodedInsts_3_bits_srcType_0    (complex_inst[3].srcType[0]),
    .io_out_complexDecodedInsts_3_bits_srcType_1    (complex_inst[3].srcType[1]),
    .io_out_complexDecodedInsts_3_bits_srcType_2    (complex_inst[3].srcType[2]),
    .io_out_complexDecodedInsts_3_bits_srcType_3    (complex_inst[3].srcType[3]),
    .io_out_complexDecodedInsts_3_bits_srcType_4    (complex_inst[3].srcType[4]),
    .io_out_complexDecodedInsts_3_bits_lsrc_0       (complex_inst[3].lsrc[0]),
    .io_out_complexDecodedInsts_3_bits_lsrc_1       (complex_inst[3].lsrc[1]),
    .io_out_complexDecodedInsts_3_bits_lsrc_2       (complex_inst[3].lsrc[2]),
    .io_out_complexDecodedInsts_3_bits_ldest        (complex_inst[3].ldest),
    .io_out_complexDecodedInsts_3_bits_fuType       (complex_inst[3].fuType),
    .io_out_complexDecodedInsts_3_bits_fuOpType     (complex_inst[3].fuOpType),
    .io_out_complexDecodedInsts_3_bits_rfWen        (complex_inst[3].rfWen),
    .io_out_complexDecodedInsts_3_bits_fpWen        (complex_inst[3].fpWen),
    .io_out_complexDecodedInsts_3_bits_vecWen       (complex_inst[3].vecWen),
    .io_out_complexDecodedInsts_3_bits_vlWen        (complex_inst[3].vlWen),
    .io_out_complexDecodedInsts_3_bits_isXSTrap     (complex_inst[3].isXSTrap),
    .io_out_complexDecodedInsts_3_bits_waitForward  (complex_inst[3].waitForward),
    .io_out_complexDecodedInsts_3_bits_blockBackward (complex_inst[3].blockBackward),
    .io_out_complexDecodedInsts_3_bits_flushPipe    (complex_inst[3].flushPipe),
    .io_out_complexDecodedInsts_3_bits_canRobCompress (complex_inst[3].canRobCompress),
    .io_out_complexDecodedInsts_3_bits_selImm       (complex_inst[3].selImm),
    .io_out_complexDecodedInsts_3_bits_imm          (complex_inst[3].imm),
    .io_out_complexDecodedInsts_3_bits_fpu_typeTagOut (complex_inst[3].fpu_typeTagOut),
    .io_out_complexDecodedInsts_3_bits_fpu_wflags   (complex_inst[3].fpu_wflags),
    .io_out_complexDecodedInsts_3_bits_fpu_typ      (complex_inst[3].fpu_typ),
    .io_out_complexDecodedInsts_3_bits_fpu_fmt      (complex_inst[3].fpu_fmt),
    .io_out_complexDecodedInsts_3_bits_fpu_rm       (complex_inst[3].fpu_rm),
    .io_out_complexDecodedInsts_3_bits_vpu_vill     (complex_inst[3].vpu_vill),
    .io_out_complexDecodedInsts_3_bits_vpu_vma      (complex_inst[3].vpu_vma),
    .io_out_complexDecodedInsts_3_bits_vpu_vta      (complex_inst[3].vpu_vta),
    .io_out_complexDecodedInsts_3_bits_vpu_vsew     (complex_inst[3].vpu_vsew),
    .io_out_complexDecodedInsts_3_bits_vpu_vlmul    (complex_inst[3].vpu_vlmul),
    .io_out_complexDecodedInsts_3_bits_vpu_specVill (complex_inst[3].vpu_specVill),
    .io_out_complexDecodedInsts_3_bits_vpu_specVma  (complex_inst[3].vpu_specVma),
    .io_out_complexDecodedInsts_3_bits_vpu_specVta  (complex_inst[3].vpu_specVta),
    .io_out_complexDecodedInsts_3_bits_vpu_specVsew (complex_inst[3].vpu_specVsew),
    .io_out_complexDecodedInsts_3_bits_vpu_specVlmul (complex_inst[3].vpu_specVlmul),
    .io_out_complexDecodedInsts_3_bits_vpu_vm       (complex_inst[3].vpu_vm),
    .io_out_complexDecodedInsts_3_bits_vpu_vstart   (complex_inst[3].vpu_vstart),
    .io_out_complexDecodedInsts_3_bits_vpu_fpu_isFoldTo1_2 (complex_inst[3].vpu_fpu_isFoldTo1_2),
    .io_out_complexDecodedInsts_3_bits_vpu_fpu_isFoldTo1_4 (complex_inst[3].vpu_fpu_isFoldTo1_4),
    .io_out_complexDecodedInsts_3_bits_vpu_fpu_isFoldTo1_8 (complex_inst[3].vpu_fpu_isFoldTo1_8),
    .io_out_complexDecodedInsts_3_bits_vpu_nf       (complex_inst[3].vpu_nf),
    .io_out_complexDecodedInsts_3_bits_vpu_veew     (complex_inst[3].vpu_veew),
    .io_out_complexDecodedInsts_3_bits_vpu_isReverse (complex_inst[3].vpu_isReverse),
    .io_out_complexDecodedInsts_3_bits_vpu_isExt    (complex_inst[3].vpu_isExt),
    .io_out_complexDecodedInsts_3_bits_vpu_isNarrow (complex_inst[3].vpu_isNarrow),
    .io_out_complexDecodedInsts_3_bits_vpu_isDstMask (complex_inst[3].vpu_isDstMask),
    .io_out_complexDecodedInsts_3_bits_vpu_isOpMask (complex_inst[3].vpu_isOpMask),
    .io_out_complexDecodedInsts_3_bits_vpu_isDependOldVd (complex_inst[3].vpu_isDependOldVd),
    .io_out_complexDecodedInsts_3_bits_vpu_isWritePartVd (complex_inst[3].vpu_isWritePartVd),
    .io_out_complexDecodedInsts_3_bits_vpu_isVleff  (complex_inst[3].vpu_isVleff),
    .io_out_complexDecodedInsts_3_bits_vlsInstr     (complex_inst[3].vlsInstr),
    .io_out_complexDecodedInsts_3_bits_wfflags      (complex_inst[3].wfflags),
    .io_out_complexDecodedInsts_3_bits_isMove       (complex_inst[3].isMove),
    .io_out_complexDecodedInsts_3_bits_uopIdx       (complex_inst[3].uopIdx),
    .io_out_complexDecodedInsts_3_bits_uopSplitType (complex_inst[3].uopSplitType),
    .io_out_complexDecodedInsts_3_bits_isVset       (complex_inst[3].isVset),
    .io_out_complexDecodedInsts_3_bits_lastUop      (complex_inst[3].lastUop),
    .io_out_complexDecodedInsts_3_bits_numUops      (complex_inst[3].numUops),
    .io_out_complexDecodedInsts_3_bits_numWB        (complex_inst[3].numWB),
    .io_out_complexDecodedInsts_3_bits_commitType   (complex_inst[3].commitType),
    .io_out_complexDecodedInsts_3_bits_debug_fuType (complex_inst[3].debug_fuType),
    .io_out_complexDecodedInsts_3_bits_debug_seqNum_seqNum (complex_inst[3].debug_seqNum_seqNum),
    .io_out_complexDecodedInsts_3_bits_debug_seqNum_uopIdx (complex_inst[3].debug_seqNum_uopIdx),
    .io_out_complexDecodedInsts_4_valid             (complex_valid[4]),
    .io_out_complexDecodedInsts_4_bits_instr        (complex_inst[4].instr),
    .io_out_complexDecodedInsts_4_bits_pc           (complex_inst[4].pc),
    .io_out_complexDecodedInsts_4_bits_foldpc       (complex_inst[4].foldpc),
    .io_out_complexDecodedInsts_4_bits_exceptionVec_0 (complex_inst[4].exceptionVec[0]),
    .io_out_complexDecodedInsts_4_bits_exceptionVec_1 (complex_inst[4].exceptionVec[1]),
    .io_out_complexDecodedInsts_4_bits_exceptionVec_2 (complex_inst[4].exceptionVec[2]),
    .io_out_complexDecodedInsts_4_bits_exceptionVec_3 (complex_inst[4].exceptionVec[3]),
    .io_out_complexDecodedInsts_4_bits_exceptionVec_4 (complex_inst[4].exceptionVec[4]),
    .io_out_complexDecodedInsts_4_bits_exceptionVec_5 (complex_inst[4].exceptionVec[5]),
    .io_out_complexDecodedInsts_4_bits_exceptionVec_6 (complex_inst[4].exceptionVec[6]),
    .io_out_complexDecodedInsts_4_bits_exceptionVec_7 (complex_inst[4].exceptionVec[7]),
    .io_out_complexDecodedInsts_4_bits_exceptionVec_8 (complex_inst[4].exceptionVec[8]),
    .io_out_complexDecodedInsts_4_bits_exceptionVec_9 (complex_inst[4].exceptionVec[9]),
    .io_out_complexDecodedInsts_4_bits_exceptionVec_10 (complex_inst[4].exceptionVec[10]),
    .io_out_complexDecodedInsts_4_bits_exceptionVec_11 (complex_inst[4].exceptionVec[11]),
    .io_out_complexDecodedInsts_4_bits_exceptionVec_12 (complex_inst[4].exceptionVec[12]),
    .io_out_complexDecodedInsts_4_bits_exceptionVec_13 (complex_inst[4].exceptionVec[13]),
    .io_out_complexDecodedInsts_4_bits_exceptionVec_14 (complex_inst[4].exceptionVec[14]),
    .io_out_complexDecodedInsts_4_bits_exceptionVec_15 (complex_inst[4].exceptionVec[15]),
    .io_out_complexDecodedInsts_4_bits_exceptionVec_16 (complex_inst[4].exceptionVec[16]),
    .io_out_complexDecodedInsts_4_bits_exceptionVec_17 (complex_inst[4].exceptionVec[17]),
    .io_out_complexDecodedInsts_4_bits_exceptionVec_18 (complex_inst[4].exceptionVec[18]),
    .io_out_complexDecodedInsts_4_bits_exceptionVec_19 (complex_inst[4].exceptionVec[19]),
    .io_out_complexDecodedInsts_4_bits_exceptionVec_20 (complex_inst[4].exceptionVec[20]),
    .io_out_complexDecodedInsts_4_bits_exceptionVec_21 (complex_inst[4].exceptionVec[21]),
    .io_out_complexDecodedInsts_4_bits_exceptionVec_22 (complex_inst[4].exceptionVec[22]),
    .io_out_complexDecodedInsts_4_bits_exceptionVec_23 (complex_inst[4].exceptionVec[23]),
    .io_out_complexDecodedInsts_4_bits_isFetchMalAddr (complex_inst[4].isFetchMalAddr),
    .io_out_complexDecodedInsts_4_bits_trigger      (complex_inst[4].trigger),
    .io_out_complexDecodedInsts_4_bits_preDecodeInfo_valid (complex_inst[4].preDecodeInfo_valid),
    .io_out_complexDecodedInsts_4_bits_preDecodeInfo_isRVC (complex_inst[4].preDecodeInfo_isRVC),
    .io_out_complexDecodedInsts_4_bits_preDecodeInfo_brType (complex_inst[4].preDecodeInfo_brType),
    .io_out_complexDecodedInsts_4_bits_preDecodeInfo_isCall (complex_inst[4].preDecodeInfo_isCall),
    .io_out_complexDecodedInsts_4_bits_preDecodeInfo_isRet (complex_inst[4].preDecodeInfo_isRet),
    .io_out_complexDecodedInsts_4_bits_pred_taken   (complex_inst[4].pred_taken),
    .io_out_complexDecodedInsts_4_bits_crossPageIPFFix (complex_inst[4].crossPageIPFFix),
    .io_out_complexDecodedInsts_4_bits_ftqPtr_flag  (complex_inst[4].ftqPtr_flag),
    .io_out_complexDecodedInsts_4_bits_ftqPtr_value (complex_inst[4].ftqPtr_value),
    .io_out_complexDecodedInsts_4_bits_ftqOffset    (complex_inst[4].ftqOffset),
    .io_out_complexDecodedInsts_4_bits_satpFlushFirstFetchFault (complex_inst[4].satpFlushFirstFetchFault),
    .io_out_complexDecodedInsts_4_bits_srcType_0    (complex_inst[4].srcType[0]),
    .io_out_complexDecodedInsts_4_bits_srcType_1    (complex_inst[4].srcType[1]),
    .io_out_complexDecodedInsts_4_bits_srcType_2    (complex_inst[4].srcType[2]),
    .io_out_complexDecodedInsts_4_bits_srcType_3    (complex_inst[4].srcType[3]),
    .io_out_complexDecodedInsts_4_bits_srcType_4    (complex_inst[4].srcType[4]),
    .io_out_complexDecodedInsts_4_bits_lsrc_0       (complex_inst[4].lsrc[0]),
    .io_out_complexDecodedInsts_4_bits_lsrc_1       (complex_inst[4].lsrc[1]),
    .io_out_complexDecodedInsts_4_bits_lsrc_2       (complex_inst[4].lsrc[2]),
    .io_out_complexDecodedInsts_4_bits_ldest        (complex_inst[4].ldest),
    .io_out_complexDecodedInsts_4_bits_fuType       (complex_inst[4].fuType),
    .io_out_complexDecodedInsts_4_bits_fuOpType     (complex_inst[4].fuOpType),
    .io_out_complexDecodedInsts_4_bits_rfWen        (complex_inst[4].rfWen),
    .io_out_complexDecodedInsts_4_bits_fpWen        (complex_inst[4].fpWen),
    .io_out_complexDecodedInsts_4_bits_vecWen       (complex_inst[4].vecWen),
    .io_out_complexDecodedInsts_4_bits_vlWen        (complex_inst[4].vlWen),
    .io_out_complexDecodedInsts_4_bits_isXSTrap     (complex_inst[4].isXSTrap),
    .io_out_complexDecodedInsts_4_bits_waitForward  (complex_inst[4].waitForward),
    .io_out_complexDecodedInsts_4_bits_blockBackward (complex_inst[4].blockBackward),
    .io_out_complexDecodedInsts_4_bits_flushPipe    (complex_inst[4].flushPipe),
    .io_out_complexDecodedInsts_4_bits_canRobCompress (complex_inst[4].canRobCompress),
    .io_out_complexDecodedInsts_4_bits_selImm       (complex_inst[4].selImm),
    .io_out_complexDecodedInsts_4_bits_imm          (complex_inst[4].imm),
    .io_out_complexDecodedInsts_4_bits_fpu_typeTagOut (complex_inst[4].fpu_typeTagOut),
    .io_out_complexDecodedInsts_4_bits_fpu_wflags   (complex_inst[4].fpu_wflags),
    .io_out_complexDecodedInsts_4_bits_fpu_typ      (complex_inst[4].fpu_typ),
    .io_out_complexDecodedInsts_4_bits_fpu_fmt      (complex_inst[4].fpu_fmt),
    .io_out_complexDecodedInsts_4_bits_fpu_rm       (complex_inst[4].fpu_rm),
    .io_out_complexDecodedInsts_4_bits_vpu_vill     (complex_inst[4].vpu_vill),
    .io_out_complexDecodedInsts_4_bits_vpu_vma      (complex_inst[4].vpu_vma),
    .io_out_complexDecodedInsts_4_bits_vpu_vta      (complex_inst[4].vpu_vta),
    .io_out_complexDecodedInsts_4_bits_vpu_vsew     (complex_inst[4].vpu_vsew),
    .io_out_complexDecodedInsts_4_bits_vpu_vlmul    (complex_inst[4].vpu_vlmul),
    .io_out_complexDecodedInsts_4_bits_vpu_specVill (complex_inst[4].vpu_specVill),
    .io_out_complexDecodedInsts_4_bits_vpu_specVma  (complex_inst[4].vpu_specVma),
    .io_out_complexDecodedInsts_4_bits_vpu_specVta  (complex_inst[4].vpu_specVta),
    .io_out_complexDecodedInsts_4_bits_vpu_specVsew (complex_inst[4].vpu_specVsew),
    .io_out_complexDecodedInsts_4_bits_vpu_specVlmul (complex_inst[4].vpu_specVlmul),
    .io_out_complexDecodedInsts_4_bits_vpu_vm       (complex_inst[4].vpu_vm),
    .io_out_complexDecodedInsts_4_bits_vpu_vstart   (complex_inst[4].vpu_vstart),
    .io_out_complexDecodedInsts_4_bits_vpu_fpu_isFoldTo1_2 (complex_inst[4].vpu_fpu_isFoldTo1_2),
    .io_out_complexDecodedInsts_4_bits_vpu_fpu_isFoldTo1_4 (complex_inst[4].vpu_fpu_isFoldTo1_4),
    .io_out_complexDecodedInsts_4_bits_vpu_fpu_isFoldTo1_8 (complex_inst[4].vpu_fpu_isFoldTo1_8),
    .io_out_complexDecodedInsts_4_bits_vpu_nf       (complex_inst[4].vpu_nf),
    .io_out_complexDecodedInsts_4_bits_vpu_veew     (complex_inst[4].vpu_veew),
    .io_out_complexDecodedInsts_4_bits_vpu_isReverse (complex_inst[4].vpu_isReverse),
    .io_out_complexDecodedInsts_4_bits_vpu_isExt    (complex_inst[4].vpu_isExt),
    .io_out_complexDecodedInsts_4_bits_vpu_isNarrow (complex_inst[4].vpu_isNarrow),
    .io_out_complexDecodedInsts_4_bits_vpu_isDstMask (complex_inst[4].vpu_isDstMask),
    .io_out_complexDecodedInsts_4_bits_vpu_isOpMask (complex_inst[4].vpu_isOpMask),
    .io_out_complexDecodedInsts_4_bits_vpu_isDependOldVd (complex_inst[4].vpu_isDependOldVd),
    .io_out_complexDecodedInsts_4_bits_vpu_isWritePartVd (complex_inst[4].vpu_isWritePartVd),
    .io_out_complexDecodedInsts_4_bits_vpu_isVleff  (complex_inst[4].vpu_isVleff),
    .io_out_complexDecodedInsts_4_bits_vlsInstr     (complex_inst[4].vlsInstr),
    .io_out_complexDecodedInsts_4_bits_wfflags      (complex_inst[4].wfflags),
    .io_out_complexDecodedInsts_4_bits_isMove       (complex_inst[4].isMove),
    .io_out_complexDecodedInsts_4_bits_uopIdx       (complex_inst[4].uopIdx),
    .io_out_complexDecodedInsts_4_bits_uopSplitType (complex_inst[4].uopSplitType),
    .io_out_complexDecodedInsts_4_bits_isVset       (complex_inst[4].isVset),
    .io_out_complexDecodedInsts_4_bits_lastUop      (complex_inst[4].lastUop),
    .io_out_complexDecodedInsts_4_bits_numUops      (complex_inst[4].numUops),
    .io_out_complexDecodedInsts_4_bits_numWB        (complex_inst[4].numWB),
    .io_out_complexDecodedInsts_4_bits_commitType   (complex_inst[4].commitType),
    .io_out_complexDecodedInsts_4_bits_debug_fuType (complex_inst[4].debug_fuType),
    .io_out_complexDecodedInsts_4_bits_debug_seqNum_seqNum (complex_inst[4].debug_seqNum_seqNum),
    .io_out_complexDecodedInsts_4_bits_debug_seqNum_uopIdx (complex_inst[4].debug_seqNum_uopIdx),
    .io_out_complexDecodedInsts_5_valid             (complex_valid[5]),
    .io_out_complexDecodedInsts_5_bits_instr        (complex_inst[5].instr),
    .io_out_complexDecodedInsts_5_bits_pc           (complex_inst[5].pc),
    .io_out_complexDecodedInsts_5_bits_foldpc       (complex_inst[5].foldpc),
    .io_out_complexDecodedInsts_5_bits_exceptionVec_0 (complex_inst[5].exceptionVec[0]),
    .io_out_complexDecodedInsts_5_bits_exceptionVec_1 (complex_inst[5].exceptionVec[1]),
    .io_out_complexDecodedInsts_5_bits_exceptionVec_2 (complex_inst[5].exceptionVec[2]),
    .io_out_complexDecodedInsts_5_bits_exceptionVec_3 (complex_inst[5].exceptionVec[3]),
    .io_out_complexDecodedInsts_5_bits_exceptionVec_4 (complex_inst[5].exceptionVec[4]),
    .io_out_complexDecodedInsts_5_bits_exceptionVec_5 (complex_inst[5].exceptionVec[5]),
    .io_out_complexDecodedInsts_5_bits_exceptionVec_6 (complex_inst[5].exceptionVec[6]),
    .io_out_complexDecodedInsts_5_bits_exceptionVec_7 (complex_inst[5].exceptionVec[7]),
    .io_out_complexDecodedInsts_5_bits_exceptionVec_8 (complex_inst[5].exceptionVec[8]),
    .io_out_complexDecodedInsts_5_bits_exceptionVec_9 (complex_inst[5].exceptionVec[9]),
    .io_out_complexDecodedInsts_5_bits_exceptionVec_10 (complex_inst[5].exceptionVec[10]),
    .io_out_complexDecodedInsts_5_bits_exceptionVec_11 (complex_inst[5].exceptionVec[11]),
    .io_out_complexDecodedInsts_5_bits_exceptionVec_12 (complex_inst[5].exceptionVec[12]),
    .io_out_complexDecodedInsts_5_bits_exceptionVec_13 (complex_inst[5].exceptionVec[13]),
    .io_out_complexDecodedInsts_5_bits_exceptionVec_14 (complex_inst[5].exceptionVec[14]),
    .io_out_complexDecodedInsts_5_bits_exceptionVec_15 (complex_inst[5].exceptionVec[15]),
    .io_out_complexDecodedInsts_5_bits_exceptionVec_16 (complex_inst[5].exceptionVec[16]),
    .io_out_complexDecodedInsts_5_bits_exceptionVec_17 (complex_inst[5].exceptionVec[17]),
    .io_out_complexDecodedInsts_5_bits_exceptionVec_18 (complex_inst[5].exceptionVec[18]),
    .io_out_complexDecodedInsts_5_bits_exceptionVec_19 (complex_inst[5].exceptionVec[19]),
    .io_out_complexDecodedInsts_5_bits_exceptionVec_20 (complex_inst[5].exceptionVec[20]),
    .io_out_complexDecodedInsts_5_bits_exceptionVec_21 (complex_inst[5].exceptionVec[21]),
    .io_out_complexDecodedInsts_5_bits_exceptionVec_22 (complex_inst[5].exceptionVec[22]),
    .io_out_complexDecodedInsts_5_bits_exceptionVec_23 (complex_inst[5].exceptionVec[23]),
    .io_out_complexDecodedInsts_5_bits_isFetchMalAddr (complex_inst[5].isFetchMalAddr),
    .io_out_complexDecodedInsts_5_bits_trigger      (complex_inst[5].trigger),
    .io_out_complexDecodedInsts_5_bits_preDecodeInfo_valid (complex_inst[5].preDecodeInfo_valid),
    .io_out_complexDecodedInsts_5_bits_preDecodeInfo_isRVC (complex_inst[5].preDecodeInfo_isRVC),
    .io_out_complexDecodedInsts_5_bits_preDecodeInfo_brType (complex_inst[5].preDecodeInfo_brType),
    .io_out_complexDecodedInsts_5_bits_preDecodeInfo_isCall (complex_inst[5].preDecodeInfo_isCall),
    .io_out_complexDecodedInsts_5_bits_preDecodeInfo_isRet (complex_inst[5].preDecodeInfo_isRet),
    .io_out_complexDecodedInsts_5_bits_pred_taken   (complex_inst[5].pred_taken),
    .io_out_complexDecodedInsts_5_bits_crossPageIPFFix (complex_inst[5].crossPageIPFFix),
    .io_out_complexDecodedInsts_5_bits_ftqPtr_flag  (complex_inst[5].ftqPtr_flag),
    .io_out_complexDecodedInsts_5_bits_ftqPtr_value (complex_inst[5].ftqPtr_value),
    .io_out_complexDecodedInsts_5_bits_ftqOffset    (complex_inst[5].ftqOffset),
    .io_out_complexDecodedInsts_5_bits_satpFlushFirstFetchFault (complex_inst[5].satpFlushFirstFetchFault),
    .io_out_complexDecodedInsts_5_bits_srcType_0    (complex_inst[5].srcType[0]),
    .io_out_complexDecodedInsts_5_bits_srcType_1    (complex_inst[5].srcType[1]),
    .io_out_complexDecodedInsts_5_bits_srcType_2    (complex_inst[5].srcType[2]),
    .io_out_complexDecodedInsts_5_bits_srcType_3    (complex_inst[5].srcType[3]),
    .io_out_complexDecodedInsts_5_bits_srcType_4    (complex_inst[5].srcType[4]),
    .io_out_complexDecodedInsts_5_bits_lsrc_0       (complex_inst[5].lsrc[0]),
    .io_out_complexDecodedInsts_5_bits_lsrc_1       (complex_inst[5].lsrc[1]),
    .io_out_complexDecodedInsts_5_bits_lsrc_2       (complex_inst[5].lsrc[2]),
    .io_out_complexDecodedInsts_5_bits_ldest        (complex_inst[5].ldest),
    .io_out_complexDecodedInsts_5_bits_fuType       (complex_inst[5].fuType),
    .io_out_complexDecodedInsts_5_bits_fuOpType     (complex_inst[5].fuOpType),
    .io_out_complexDecodedInsts_5_bits_rfWen        (complex_inst[5].rfWen),
    .io_out_complexDecodedInsts_5_bits_fpWen        (complex_inst[5].fpWen),
    .io_out_complexDecodedInsts_5_bits_vecWen       (complex_inst[5].vecWen),
    .io_out_complexDecodedInsts_5_bits_vlWen        (complex_inst[5].vlWen),
    .io_out_complexDecodedInsts_5_bits_isXSTrap     (complex_inst[5].isXSTrap),
    .io_out_complexDecodedInsts_5_bits_waitForward  (complex_inst[5].waitForward),
    .io_out_complexDecodedInsts_5_bits_blockBackward (complex_inst[5].blockBackward),
    .io_out_complexDecodedInsts_5_bits_flushPipe    (complex_inst[5].flushPipe),
    .io_out_complexDecodedInsts_5_bits_canRobCompress (complex_inst[5].canRobCompress),
    .io_out_complexDecodedInsts_5_bits_selImm       (complex_inst[5].selImm),
    .io_out_complexDecodedInsts_5_bits_imm          (complex_inst[5].imm),
    .io_out_complexDecodedInsts_5_bits_fpu_typeTagOut (complex_inst[5].fpu_typeTagOut),
    .io_out_complexDecodedInsts_5_bits_fpu_wflags   (complex_inst[5].fpu_wflags),
    .io_out_complexDecodedInsts_5_bits_fpu_typ      (complex_inst[5].fpu_typ),
    .io_out_complexDecodedInsts_5_bits_fpu_fmt      (complex_inst[5].fpu_fmt),
    .io_out_complexDecodedInsts_5_bits_fpu_rm       (complex_inst[5].fpu_rm),
    .io_out_complexDecodedInsts_5_bits_vpu_vill     (complex_inst[5].vpu_vill),
    .io_out_complexDecodedInsts_5_bits_vpu_vma      (complex_inst[5].vpu_vma),
    .io_out_complexDecodedInsts_5_bits_vpu_vta      (complex_inst[5].vpu_vta),
    .io_out_complexDecodedInsts_5_bits_vpu_vsew     (complex_inst[5].vpu_vsew),
    .io_out_complexDecodedInsts_5_bits_vpu_vlmul    (complex_inst[5].vpu_vlmul),
    .io_out_complexDecodedInsts_5_bits_vpu_specVill (complex_inst[5].vpu_specVill),
    .io_out_complexDecodedInsts_5_bits_vpu_specVma  (complex_inst[5].vpu_specVma),
    .io_out_complexDecodedInsts_5_bits_vpu_specVta  (complex_inst[5].vpu_specVta),
    .io_out_complexDecodedInsts_5_bits_vpu_specVsew (complex_inst[5].vpu_specVsew),
    .io_out_complexDecodedInsts_5_bits_vpu_specVlmul (complex_inst[5].vpu_specVlmul),
    .io_out_complexDecodedInsts_5_bits_vpu_vm       (complex_inst[5].vpu_vm),
    .io_out_complexDecodedInsts_5_bits_vpu_vstart   (complex_inst[5].vpu_vstart),
    .io_out_complexDecodedInsts_5_bits_vpu_fpu_isFoldTo1_2 (complex_inst[5].vpu_fpu_isFoldTo1_2),
    .io_out_complexDecodedInsts_5_bits_vpu_fpu_isFoldTo1_4 (complex_inst[5].vpu_fpu_isFoldTo1_4),
    .io_out_complexDecodedInsts_5_bits_vpu_fpu_isFoldTo1_8 (complex_inst[5].vpu_fpu_isFoldTo1_8),
    .io_out_complexDecodedInsts_5_bits_vpu_nf       (complex_inst[5].vpu_nf),
    .io_out_complexDecodedInsts_5_bits_vpu_veew     (complex_inst[5].vpu_veew),
    .io_out_complexDecodedInsts_5_bits_vpu_isReverse (complex_inst[5].vpu_isReverse),
    .io_out_complexDecodedInsts_5_bits_vpu_isExt    (complex_inst[5].vpu_isExt),
    .io_out_complexDecodedInsts_5_bits_vpu_isNarrow (complex_inst[5].vpu_isNarrow),
    .io_out_complexDecodedInsts_5_bits_vpu_isDstMask (complex_inst[5].vpu_isDstMask),
    .io_out_complexDecodedInsts_5_bits_vpu_isOpMask (complex_inst[5].vpu_isOpMask),
    .io_out_complexDecodedInsts_5_bits_vpu_isDependOldVd (complex_inst[5].vpu_isDependOldVd),
    .io_out_complexDecodedInsts_5_bits_vpu_isWritePartVd (complex_inst[5].vpu_isWritePartVd),
    .io_out_complexDecodedInsts_5_bits_vpu_isVleff  (complex_inst[5].vpu_isVleff),
    .io_out_complexDecodedInsts_5_bits_vlsInstr     (complex_inst[5].vlsInstr),
    .io_out_complexDecodedInsts_5_bits_wfflags      (complex_inst[5].wfflags),
    .io_out_complexDecodedInsts_5_bits_isMove       (complex_inst[5].isMove),
    .io_out_complexDecodedInsts_5_bits_uopIdx       (complex_inst[5].uopIdx),
    .io_out_complexDecodedInsts_5_bits_uopSplitType (complex_inst[5].uopSplitType),
    .io_out_complexDecodedInsts_5_bits_isVset       (complex_inst[5].isVset),
    .io_out_complexDecodedInsts_5_bits_lastUop      (complex_inst[5].lastUop),
    .io_out_complexDecodedInsts_5_bits_numUops      (complex_inst[5].numUops),
    .io_out_complexDecodedInsts_5_bits_numWB        (complex_inst[5].numWB),
    .io_out_complexDecodedInsts_5_bits_commitType   (complex_inst[5].commitType),
    .io_out_complexDecodedInsts_5_bits_debug_fuType (complex_inst[5].debug_fuType),
    .io_out_complexDecodedInsts_5_bits_debug_seqNum_seqNum (complex_inst[5].debug_seqNum_seqNum),
    .io_out_complexDecodedInsts_5_bits_debug_seqNum_uopIdx (complex_inst[5].debug_seqNum_uopIdx),
    .io_complexNum                                  (complexNum)
  );
  // golden 里第 1..5 路没有 firstUop 端口（恒 0 被删）；v0Wen 两支都不用（输出侧现算）。
  assign complex_inst[0].v0Wen = 1'b0;
  assign complex_inst[1].firstUop = 1'b0;
  assign complex_inst[1].v0Wen = 1'b0;
  assign complex_inst[2].firstUop = 1'b0;
  assign complex_inst[2].v0Wen = 1'b0;
  assign complex_inst[3].firstUop = 1'b0;
  assign complex_inst[3].v0Wen = 1'b0;
  assign complex_inst[4].firstUop = 1'b0;
  assign complex_inst[4].v0Wen = 1'b0;
  assign complex_inst[5].firstUop = 1'b0;
  assign complex_inst[5].v0Wen = 1'b0;
  // END GENERATED

  // BEGIN GENERATED(vtype_gen)
  // vtype 生成：跟踪推测 vtype（vset 指令一进复杂译码器就更新），供 6 个 DecodeUnit 与 DecodeUnitComp 用。
  VTypeGen u_vtype_gen (
    .clock                              (clock),
    .reset                              (reset),
    .io_insts_0_valid                   (in_valid[0]),
    .io_insts_0_bits                    (in_bits[0].instr),
    .io_insts_1_valid                   (in_valid[1]),
    .io_insts_1_bits                    (in_bits[1].instr),
    .io_insts_2_valid                   (in_valid[2]),
    .io_insts_2_bits                    (in_bits[2].instr),
    .io_insts_3_valid                   (in_valid[3]),
    .io_insts_3_bits                    (in_bits[3].instr),
    .io_insts_4_valid                   (in_valid[4]),
    .io_insts_4_bits                    (in_bits[4].instr),
    .io_insts_5_valid                   (in_valid[5]),
    .io_insts_5_bits                    (in_bits[5].instr),
    .io_walkToArchVType                 (fromRob.walkToArchVType),
    .io_walkVType_valid                 (fromRob.walkVType_valid),
    .io_walkVType_bits_illegal          (fromRob.walkVType.illegal),
    .io_walkVType_bits_vma              (fromRob.walkVType.vma),
    .io_walkVType_bits_vta              (fromRob.walkVType.vta),
    .io_walkVType_bits_vsew             (fromRob.walkVType.vsew),
    .io_walkVType_bits_vlmul            (fromRob.walkVType.vlmul),
    .io_canUpdateVType                  (vtype_can_update),
    .io_vtype_illegal                   (vtype.illegal),
    .io_vtype_vma                       (vtype.vma),
    .io_vtype_vta                       (vtype.vta),
    .io_vtype_vsew                      (vtype.vsew),
    .io_vtype_vlmul                     (vtype.vlmul),
    .io_vsetvlVType_illegal             (vsetvlVType.illegal),
    .io_vsetvlVType_vma                 (vsetvlVType.vma),
    .io_vsetvlVType_vta                 (vsetvlVType.vta),
    .io_vsetvlVType_vsew                (vsetvlVType.vsew),
    .io_vsetvlVType_vlmul               (vsetvlVType.vlmul),
    .io_commitVType_vtype_valid         (fromRob.commitVType_valid),
    .io_commitVType_vtype_bits_illegal  (fromRob.commitVType.illegal),
    .io_commitVType_vtype_bits_vma      (fromRob.commitVType.vma),
    .io_commitVType_vtype_bits_vta      (fromRob.commitVType.vta),
    .io_commitVType_vtype_bits_vsew     (fromRob.commitVType.vsew),
    .io_commitVType_vtype_bits_vlmul    (fromRob.commitVType.vlmul),
    .io_commitVType_hasVsetvl           (fromRob.commitVType_hasVsetvl)
  );
  // END GENERATED

  // ===========================================================================
  // 复杂/简单指令的排布与 ready
  // ===========================================================================
  logic [DECODE_WIDTH-1:0]      is_complex, is_simple;
  logic [DECODE_WIDTH-1:0]      simple_prefix;       // 前 i+1 条全是简单指令
  logic [DECODE_WIDTH-1:0]      first_complex_oh;    // 第一条复杂指令的 one-hot
  logic [CPLX_W-1:0]            ready_counter;       // Rename 本拍能收几个：out[0].ready ? 6 : 0
  logic [DECODE_WIDTH-1:0][3:0] loc;                 // 第 i 条简单指令排布后的位置 = i + complexNum
  logic                         complex_valid_any;   // 有复杂指令且它排得进 Rename

  assign ready_counter = out_ready[0] ? CPLX_W'(RENAME_WIDTH) : CPLX_W'(0);

  for (genvar i = 0; i < DECODE_WIDTH; i++) begin : g_arrange
    assign is_complex[i]    = in_valid[i] &  simple_is_complex[i];
    assign is_simple[i]     = in_valid[i] & ~simple_is_complex[i];
    assign simple_prefix[i] = &is_simple[i:0];
    assign loc[i]           = 4'({1'b0, complexNum}) + 4'(i);
    // in.ready：前缀全简单且位置 < readyCounter，或本条是第一条复杂指令、位置 <= readyCounter 且复杂译码器能收
    assign in_ready[i] = ~redirect
                       & (simple_prefix[i] & (loc[i] < 4'({1'b0, ready_counter}))
                          | first_complex_oh[i] & (loc[i] <= 4'({1'b0, ready_counter})) & complex_in_ready)
                       & ~fromRob.isResumeVType;
  end

  // 第一条复杂指令：优先编码
  assign first_complex_oh = is_complex[0] ? 6'h01 :
                            is_complex[1] ? 6'h02 :
                            is_complex[2] ? 6'h04 :
                            is_complex[3] ? 6'h08 :
                            is_complex[4] ? 6'h10 : {is_complex[5], 5'h0};

  always_comb begin
    complex_valid_any = 1'b0;
    for (int i = 0; i < DECODE_WIDTH; i++)
      complex_valid_any |= is_complex[i] & (loc[i] <= 4'({1'b0, ready_counter}));
  end

  // 送复杂译码器的那条 = 第一条复杂指令（PriorityMuxDefault，默认 0）
  always_comb begin
    complex_in_inst     = '0;
    complex_in_uop_info = '0;
    for (int i = DECODE_WIDTH - 1; i >= 0; i--) begin
      if (is_complex[i]) begin
        complex_in_inst     = simple_inst[i];
        complex_in_uop_info = simple_uop_info[i];
      end
    end
  end
  assign complex_in_valid = complex_valid_any & ~fromRob.isResumeVType;
  // vset 一进复杂译码器就更新推测 vtype（redirect 时永不更新）
  assign vtype_can_update = complex_in_ready & complex_in_valid & complex_in_inst.isVset & ~redirect;

  assign canAccept = ~redirect & (out_ready[0] | complex_in_ready) & ~fromRob.isResumeVType;

  // ===========================================================================
  // finalDecodedInst：complexNum 个复杂 uop 排前面，简单指令补后面
  // ===========================================================================
  // simple[i - complexNum] 的下标是 3 位，表有 8 项：[6]/[7] 是 decoders_0（golden 越界补第 0 项）
  decoded_inst_t [7:0]              simple_tbl;
  logic          [7:0]              simple_valid_tbl;
  decoded_inst_t [DECODE_WIDTH-1:0] final_inst;
  logic          [DECODE_WIDTH-1:0] final_valid;
  logic          [DECODE_WIDTH-1:0] sel_complex;      // complexNum > i

  for (genvar k = 0; k < 8; k++) begin : g_tbl
    localparam int unsigned SRC = (k < DECODE_WIDTH) ? k : 0;
    assign simple_tbl[k]       = simple_inst[SRC];
    assign simple_valid_tbl[k] = simple_prefix[SRC];
  end

  for (genvar i = 0; i < DECODE_WIDTH; i++) begin : g_final
    logic [CPLX_W-1:0] simple_idx;
    assign simple_idx     = CPLX_W'(i) - complexNum;
    assign sel_complex[i] = complexNum > CPLX_W'(i);
    assign final_inst[i]  = sel_complex[i] ? complex_inst[i]  : simple_tbl[simple_idx];
    assign final_valid[i] = sel_complex[i] ? complex_valid[i] : simple_valid_tbl[simple_idx];
  end

  // ===========================================================================
  // 输出修饰 + RAT 读口
  // ===========================================================================
  for (genvar i = 0; i < DECODE_WIDTH; i++) begin : g_out
    decoded_inst_t f;
    logic          src_reads_v0;    // 任一向量源读 v0
    logic [5:0]    lsrc0_o, lsrc1_o;
    assign f = final_inst[i];
    assign lsrc0_o = f.vpu_isReverse ? f.lsrc[1] : f.lsrc[0];
    assign lsrc1_o = f.vpu_isReverse ? f.lsrc[0] : f.lsrc[1];
    // golden 里 lsrc(3)==0 被折成恒真，所以第四项只看 srcType[3] 是不是 vp
    assign src_reads_v0 = f.srcType[0][2] & (f.lsrc[0] == 6'(V0_IDX))
                        | f.srcType[1][2] & (f.lsrc[1] == 6'(V0_IDX))
                        | f.srcType[2][2] & (f.lsrc[2] == 6'(V0_IDX))
                        | f.srcType[3][2];

    always_comb begin
      out_bits[i]            = f;
      out_bits[i].lsrc[0]    = lsrc0_o;
      out_bits[i].lsrc[1]    = lsrc1_o;
      out_bits[i].srcType[0] = f.vpu_isReverse ? f.srcType[1] : f.srcType[0];
      out_bits[i].srcType[1] = f.vpu_isReverse ? f.srcType[0] : f.srcType[1];
      out_bits[i].srcType[3] = src_reads_v0 ? SRCTYPE_V0 : f.srcType[3];
      out_bits[i].v0Wen      = f.vecWen & (f.ldest == 6'(V0_IDX));
      out_bits[i].vecWen     = f.vecWen & (|f.ldest);
      // 只有第一个 uop 带序号
      out_bits[i].debug_seqNum_seqNum = (|f.uopIdx) ? 56'h0 : f.debug_seqNum_seqNum;
      out_bits[i].debug_seqNum_uopIdx = (|f.uopIdx) ? 8'h0  : f.debug_seqNum_uopIdx;
    end
    assign out_valid[i] = final_valid[i] & ~fromRob.isResumeVType;

    // RAT 读口：用修饰后的 lsrc[0]/lsrc[1]（融合译码之前的值），第三个口读 lsrc[2]
    assign intRat_addr[i][0] = 32'(lsrc0_o);
    assign intRat_addr[i][1] = 32'(lsrc1_o);
    assign intRat_hold[i]    = {2{~out_ready[i]}};
    assign fpRat_addr[i][0]  = 34'(lsrc0_o);
    assign fpRat_addr[i][1]  = 34'(lsrc1_o);
    assign fpRat_addr[i][2]  = 34'(f.lsrc[2]);
    assign fpRat_hold[i]     = {3{~out_ready[i]}};
    assign vecRat_addr[i][0] = 47'(lsrc0_o);
    assign vecRat_addr[i][1] = 47'(lsrc1_o);
    assign vecRat_addr[i][2] = 47'(f.lsrc[2]);
    assign vecRat_hold[i]    = {3{~out_ready[i]}};
    assign v0Rat_hold[i]     = ~out_ready[i];
    assign vlRat_hold[i]     = ~out_ready[i];
  end

  // ===========================================================================
  // stall reason 直通
  // ===========================================================================
  assign stallReason_in_backReason_valid = stallReason_out_backReason_valid;
  assign stallReason_in_backReason_bits  = stallReason_out_backReason_bits;
  for (genvar i = 0; i < DECODE_WIDTH; i++) begin : g_stall
    assign stallReason_out_reason[i] = stallReason_out_backReason_valid ? stallReason_out_backReason_bits
                                                                        : stallReason_in_reason[i];
  end

  // ===========================================================================
  // 报给 CSR 的非法指令现场（RegNext，无复位）
  // ===========================================================================
  logic [DECODE_WIDTH-1:0] is_illegal;      // 本拍发出的、带 EX_II/EX_VI 的 uop
  trap_inst_info_t         illegal_pick;    // 优先选第一条（PriorityMuxDefault，默认 0）
  for (genvar i = 0; i < DECODE_WIDTH; i++) begin : g_ill
    assign is_illegal[i] = out_valid[i] & out_ready[i]
                         & (final_inst[i].exceptionVec[EX_II] | final_inst[i].exceptionVec[EX_VI]);
  end
  always_comb begin
    illegal_pick = '0;
    for (int i = DECODE_WIDTH - 1; i >= 0; i--) begin
      if (is_illegal[i]) begin
        illegal_pick.instr        = final_inst[i].instr;
        illegal_pick.ftqPtr_flag  = final_inst[i].ftqPtr_flag;
        illegal_pick.ftqPtr_value = final_inst[i].ftqPtr_value;
        illegal_pick.ftqOffset    = final_inst[i].ftqOffset;
      end
    end
  end
  always_ff @(posedge clock) begin
    trapInstInfo_valid <= (|is_illegal) & ~redirect;
    trapInstInfo       <= illegal_pick;
  end

  // ===========================================================================
  // perf：recoveryFlag + 8 个 perfEvents 两级打拍
  // ===========================================================================
  logic [DECODE_WIDTH-1:0] in_fire;
  logic                    recoveryFlag;           // redirect 置 1，任一路 fire 清 0
  logic [DECODE_WIDTH-2:0] fusionValid_q;          // GatedValidRegNext(io.fusion)
  logic [DECODE_WIDTH-1:0] inValidNotReady_q;      // GatedValidRegNext(valid && !ready)
  logic                    frontendStall_q;        // GatedValidRegNext(!in[0].valid && backendCanAccept)
  logic                    backendStall_q;         // GatedValidRegNext(in[0].valid && !in[0].ready)
  logic                    frontendStall_probe_q;  // 同上，XSPerfAccumulate 多出的一份，只喂 _probe（cone-dead）
  logic                    backendStall_probe_q;   // 同上
  logic [2:0] perf_fused_s1,     perf_fused_s2;      // decoder_fused_instr
  logic [2:0] perf_wait_s1,      perf_wait_s2;       // decoder_waitInstr
  logic       perf_stall_s1,     perf_stall_s2;      // decoder_stall_cycle
  logic [2:0] perf_util_s1,      perf_util_s2;       // decoder_utilization
  logic       perf_festall_s1,   perf_festall_s2;    // frontend_stall_cycle
  logic       perf_bestall_s1,   perf_bestall_s2;    // backend_stall_cycle
  logic [2:0] perf_instspec_s1,  perf_instspec_s2;   // INST_SPEC
  logic       perf_recovery_s1,  perf_recovery_s2;   // RECOVERY_BUBBLE

  assign in_fire = in_valid & in_ready;

  function automatic logic [2:0] popcount6(input logic [5:0] v);
    return 3'({1'b0, 2'({1'b0, v[0]} + 2'({1'b0, v[1]} + {1'b0, v[2]}))}
              + {1'b0, 2'({1'b0, v[3]} + 2'({1'b0, v[4]} + {1'b0, v[5]}))});
  endfunction
  function automatic logic [2:0] popcount5(input logic [4:0] v);
    return 3'({1'b0, 2'({1'b0, v[0]} + {1'b0, v[1]})}
              + {1'b0, 2'({1'b0, v[2]} + 2'({1'b0, v[3]} + {1'b0, v[4]}))});
  endfunction

  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      recoveryFlag          <= 1'b0;
      frontendStall_probe_q <= 1'b0;
      backendStall_probe_q  <= 1'b0;
      fusionValid_q         <= '0;
      inValidNotReady_q     <= '0;
      frontendStall_q       <= 1'b0;
      backendStall_q        <= 1'b0;
    end else begin
      recoveryFlag          <= redirect | ~(|in_fire) & recoveryFlag;
      frontendStall_probe_q <= ~in_valid[0] & backendCanAccept;
      backendStall_probe_q  <= in_valid[0] & ~in_ready[0];
      fusionValid_q         <= fusion;
      inValidNotReady_q     <= in_valid & ~in_ready;
      frontendStall_q       <= ~in_valid[0] & backendCanAccept;
      backendStall_q        <= in_valid[0] & ~in_ready[0];
    end
  end

  always_ff @(posedge clock) begin
    perf_fused_s1    <= popcount5(fusionValid_q);
    perf_wait_s1     <= popcount6(inValidNotReady_q);
    perf_stall_s1    <= (|in_valid) & ~out_ready[0];
    perf_util_s1     <= popcount6(in_valid);
    perf_festall_s1  <= frontendStall_q;
    perf_bestall_s1  <= backendStall_q;
    perf_instspec_s1 <= popcount6(in_fire);
    perf_recovery_s1 <= recoveryFlag;
    perf_fused_s2    <= perf_fused_s1;
    perf_wait_s2     <= perf_wait_s1;
    perf_stall_s2    <= perf_stall_s1;
    perf_util_s2     <= perf_util_s1;
    perf_festall_s2  <= perf_festall_s1;
    perf_bestall_s2  <= perf_bestall_s1;
    perf_instspec_s2 <= perf_instspec_s1;
    perf_recovery_s2 <= perf_recovery_s1;
  end
  assign perf_value[0] = 6'(perf_fused_s2);
  assign perf_value[1] = 6'(perf_wait_s2);
  assign perf_value[2] = 6'(perf_stall_s2);
  assign perf_value[3] = 6'(perf_util_s2);
  assign perf_value[4] = 6'(perf_festall_s2);
  assign perf_value[5] = 6'(perf_bestall_s2);
  assign perf_value[6] = 6'(perf_instspec_s2);
  assign perf_value[7] = 6'(perf_recovery_s2);

endmodule

// -----------------------------------------------------------------------------
// wrapper：端口与 golden DecodeStage 逐位同名同序，只做结构体打包/拆包
// -----------------------------------------------------------------------------
module DecodeStage
  import xs_decodestage_pkg::*;
(
  // BEGIN GENERATED(ports)
  input           clock,
  input           reset,
  input           io_redirect,
  output          io_in_0_ready,
  input           io_in_0_valid,
  input  [31:0]   io_in_0_bits_instr,
  input  [49:0]   io_in_0_bits_pc,
  input  [9:0]    io_in_0_bits_foldpc,
  input           io_in_0_bits_exceptionVec_0,
  input           io_in_0_bits_exceptionVec_1,
  input           io_in_0_bits_exceptionVec_2,
  input           io_in_0_bits_exceptionVec_4,
  input           io_in_0_bits_exceptionVec_5,
  input           io_in_0_bits_exceptionVec_6,
  input           io_in_0_bits_exceptionVec_7,
  input           io_in_0_bits_exceptionVec_8,
  input           io_in_0_bits_exceptionVec_9,
  input           io_in_0_bits_exceptionVec_10,
  input           io_in_0_bits_exceptionVec_11,
  input           io_in_0_bits_exceptionVec_12,
  input           io_in_0_bits_exceptionVec_13,
  input           io_in_0_bits_exceptionVec_14,
  input           io_in_0_bits_exceptionVec_15,
  input           io_in_0_bits_exceptionVec_16,
  input           io_in_0_bits_exceptionVec_17,
  input           io_in_0_bits_exceptionVec_18,
  input           io_in_0_bits_exceptionVec_19,
  input           io_in_0_bits_exceptionVec_20,
  input           io_in_0_bits_exceptionVec_21,
  input           io_in_0_bits_exceptionVec_23,
  input           io_in_0_bits_isFetchMalAddr,
  input  [3:0]    io_in_0_bits_trigger,
  input           io_in_0_bits_preDecodeInfo_valid,
  input           io_in_0_bits_preDecodeInfo_isRVC,
  input  [1:0]    io_in_0_bits_preDecodeInfo_brType,
  input           io_in_0_bits_preDecodeInfo_isCall,
  input           io_in_0_bits_preDecodeInfo_isRet,
  input           io_in_0_bits_pred_taken,
  input           io_in_0_bits_crossPageIPFFix,
  input           io_in_0_bits_ftqPtr_flag,
  input  [5:0]    io_in_0_bits_ftqPtr_value,
  input  [3:0]    io_in_0_bits_ftqOffset,
  input           io_in_0_bits_isLastInFtqEntry,
  input  [55:0]   io_in_0_bits_debug_seqNum_seqNum,
  input  [7:0]    io_in_0_bits_debug_seqNum_uopIdx,
  input           io_in_0_bits_satpFlushFirstFetchFault,
  output          io_in_1_ready,
  input           io_in_1_valid,
  input  [31:0]   io_in_1_bits_instr,
  input  [49:0]   io_in_1_bits_pc,
  input  [9:0]    io_in_1_bits_foldpc,
  input           io_in_1_bits_exceptionVec_0,
  input           io_in_1_bits_exceptionVec_1,
  input           io_in_1_bits_exceptionVec_2,
  input           io_in_1_bits_exceptionVec_4,
  input           io_in_1_bits_exceptionVec_5,
  input           io_in_1_bits_exceptionVec_6,
  input           io_in_1_bits_exceptionVec_7,
  input           io_in_1_bits_exceptionVec_8,
  input           io_in_1_bits_exceptionVec_9,
  input           io_in_1_bits_exceptionVec_10,
  input           io_in_1_bits_exceptionVec_11,
  input           io_in_1_bits_exceptionVec_12,
  input           io_in_1_bits_exceptionVec_13,
  input           io_in_1_bits_exceptionVec_14,
  input           io_in_1_bits_exceptionVec_15,
  input           io_in_1_bits_exceptionVec_16,
  input           io_in_1_bits_exceptionVec_17,
  input           io_in_1_bits_exceptionVec_18,
  input           io_in_1_bits_exceptionVec_19,
  input           io_in_1_bits_exceptionVec_20,
  input           io_in_1_bits_exceptionVec_21,
  input           io_in_1_bits_exceptionVec_23,
  input           io_in_1_bits_isFetchMalAddr,
  input  [3:0]    io_in_1_bits_trigger,
  input           io_in_1_bits_preDecodeInfo_valid,
  input           io_in_1_bits_preDecodeInfo_isRVC,
  input  [1:0]    io_in_1_bits_preDecodeInfo_brType,
  input           io_in_1_bits_preDecodeInfo_isCall,
  input           io_in_1_bits_preDecodeInfo_isRet,
  input           io_in_1_bits_pred_taken,
  input           io_in_1_bits_crossPageIPFFix,
  input           io_in_1_bits_ftqPtr_flag,
  input  [5:0]    io_in_1_bits_ftqPtr_value,
  input  [3:0]    io_in_1_bits_ftqOffset,
  input           io_in_1_bits_isLastInFtqEntry,
  input  [55:0]   io_in_1_bits_debug_seqNum_seqNum,
  input  [7:0]    io_in_1_bits_debug_seqNum_uopIdx,
  input           io_in_1_bits_satpFlushFirstFetchFault,
  output          io_in_2_ready,
  input           io_in_2_valid,
  input  [31:0]   io_in_2_bits_instr,
  input  [49:0]   io_in_2_bits_pc,
  input  [9:0]    io_in_2_bits_foldpc,
  input           io_in_2_bits_exceptionVec_0,
  input           io_in_2_bits_exceptionVec_1,
  input           io_in_2_bits_exceptionVec_2,
  input           io_in_2_bits_exceptionVec_4,
  input           io_in_2_bits_exceptionVec_5,
  input           io_in_2_bits_exceptionVec_6,
  input           io_in_2_bits_exceptionVec_7,
  input           io_in_2_bits_exceptionVec_8,
  input           io_in_2_bits_exceptionVec_9,
  input           io_in_2_bits_exceptionVec_10,
  input           io_in_2_bits_exceptionVec_11,
  input           io_in_2_bits_exceptionVec_12,
  input           io_in_2_bits_exceptionVec_13,
  input           io_in_2_bits_exceptionVec_14,
  input           io_in_2_bits_exceptionVec_15,
  input           io_in_2_bits_exceptionVec_16,
  input           io_in_2_bits_exceptionVec_17,
  input           io_in_2_bits_exceptionVec_18,
  input           io_in_2_bits_exceptionVec_19,
  input           io_in_2_bits_exceptionVec_20,
  input           io_in_2_bits_exceptionVec_21,
  input           io_in_2_bits_exceptionVec_23,
  input           io_in_2_bits_isFetchMalAddr,
  input  [3:0]    io_in_2_bits_trigger,
  input           io_in_2_bits_preDecodeInfo_valid,
  input           io_in_2_bits_preDecodeInfo_isRVC,
  input  [1:0]    io_in_2_bits_preDecodeInfo_brType,
  input           io_in_2_bits_preDecodeInfo_isCall,
  input           io_in_2_bits_preDecodeInfo_isRet,
  input           io_in_2_bits_pred_taken,
  input           io_in_2_bits_crossPageIPFFix,
  input           io_in_2_bits_ftqPtr_flag,
  input  [5:0]    io_in_2_bits_ftqPtr_value,
  input  [3:0]    io_in_2_bits_ftqOffset,
  input           io_in_2_bits_isLastInFtqEntry,
  input  [55:0]   io_in_2_bits_debug_seqNum_seqNum,
  input  [7:0]    io_in_2_bits_debug_seqNum_uopIdx,
  input           io_in_2_bits_satpFlushFirstFetchFault,
  output          io_in_3_ready,
  input           io_in_3_valid,
  input  [31:0]   io_in_3_bits_instr,
  input  [49:0]   io_in_3_bits_pc,
  input  [9:0]    io_in_3_bits_foldpc,
  input           io_in_3_bits_exceptionVec_0,
  input           io_in_3_bits_exceptionVec_1,
  input           io_in_3_bits_exceptionVec_2,
  input           io_in_3_bits_exceptionVec_4,
  input           io_in_3_bits_exceptionVec_5,
  input           io_in_3_bits_exceptionVec_6,
  input           io_in_3_bits_exceptionVec_7,
  input           io_in_3_bits_exceptionVec_8,
  input           io_in_3_bits_exceptionVec_9,
  input           io_in_3_bits_exceptionVec_10,
  input           io_in_3_bits_exceptionVec_11,
  input           io_in_3_bits_exceptionVec_12,
  input           io_in_3_bits_exceptionVec_13,
  input           io_in_3_bits_exceptionVec_14,
  input           io_in_3_bits_exceptionVec_15,
  input           io_in_3_bits_exceptionVec_16,
  input           io_in_3_bits_exceptionVec_17,
  input           io_in_3_bits_exceptionVec_18,
  input           io_in_3_bits_exceptionVec_19,
  input           io_in_3_bits_exceptionVec_20,
  input           io_in_3_bits_exceptionVec_21,
  input           io_in_3_bits_exceptionVec_23,
  input           io_in_3_bits_isFetchMalAddr,
  input  [3:0]    io_in_3_bits_trigger,
  input           io_in_3_bits_preDecodeInfo_valid,
  input           io_in_3_bits_preDecodeInfo_isRVC,
  input  [1:0]    io_in_3_bits_preDecodeInfo_brType,
  input           io_in_3_bits_preDecodeInfo_isCall,
  input           io_in_3_bits_preDecodeInfo_isRet,
  input           io_in_3_bits_pred_taken,
  input           io_in_3_bits_crossPageIPFFix,
  input           io_in_3_bits_ftqPtr_flag,
  input  [5:0]    io_in_3_bits_ftqPtr_value,
  input  [3:0]    io_in_3_bits_ftqOffset,
  input           io_in_3_bits_isLastInFtqEntry,
  input  [55:0]   io_in_3_bits_debug_seqNum_seqNum,
  input  [7:0]    io_in_3_bits_debug_seqNum_uopIdx,
  input           io_in_3_bits_satpFlushFirstFetchFault,
  output          io_in_4_ready,
  input           io_in_4_valid,
  input  [31:0]   io_in_4_bits_instr,
  input  [49:0]   io_in_4_bits_pc,
  input  [9:0]    io_in_4_bits_foldpc,
  input           io_in_4_bits_exceptionVec_0,
  input           io_in_4_bits_exceptionVec_1,
  input           io_in_4_bits_exceptionVec_2,
  input           io_in_4_bits_exceptionVec_4,
  input           io_in_4_bits_exceptionVec_5,
  input           io_in_4_bits_exceptionVec_6,
  input           io_in_4_bits_exceptionVec_7,
  input           io_in_4_bits_exceptionVec_8,
  input           io_in_4_bits_exceptionVec_9,
  input           io_in_4_bits_exceptionVec_10,
  input           io_in_4_bits_exceptionVec_11,
  input           io_in_4_bits_exceptionVec_12,
  input           io_in_4_bits_exceptionVec_13,
  input           io_in_4_bits_exceptionVec_14,
  input           io_in_4_bits_exceptionVec_15,
  input           io_in_4_bits_exceptionVec_16,
  input           io_in_4_bits_exceptionVec_17,
  input           io_in_4_bits_exceptionVec_18,
  input           io_in_4_bits_exceptionVec_19,
  input           io_in_4_bits_exceptionVec_20,
  input           io_in_4_bits_exceptionVec_21,
  input           io_in_4_bits_exceptionVec_23,
  input           io_in_4_bits_isFetchMalAddr,
  input  [3:0]    io_in_4_bits_trigger,
  input           io_in_4_bits_preDecodeInfo_valid,
  input           io_in_4_bits_preDecodeInfo_isRVC,
  input  [1:0]    io_in_4_bits_preDecodeInfo_brType,
  input           io_in_4_bits_preDecodeInfo_isCall,
  input           io_in_4_bits_preDecodeInfo_isRet,
  input           io_in_4_bits_pred_taken,
  input           io_in_4_bits_crossPageIPFFix,
  input           io_in_4_bits_ftqPtr_flag,
  input  [5:0]    io_in_4_bits_ftqPtr_value,
  input  [3:0]    io_in_4_bits_ftqOffset,
  input           io_in_4_bits_isLastInFtqEntry,
  input  [55:0]   io_in_4_bits_debug_seqNum_seqNum,
  input  [7:0]    io_in_4_bits_debug_seqNum_uopIdx,
  input           io_in_4_bits_satpFlushFirstFetchFault,
  output          io_in_5_ready,
  input           io_in_5_valid,
  input  [31:0]   io_in_5_bits_instr,
  input  [49:0]   io_in_5_bits_pc,
  input  [9:0]    io_in_5_bits_foldpc,
  input           io_in_5_bits_exceptionVec_0,
  input           io_in_5_bits_exceptionVec_1,
  input           io_in_5_bits_exceptionVec_2,
  input           io_in_5_bits_exceptionVec_4,
  input           io_in_5_bits_exceptionVec_5,
  input           io_in_5_bits_exceptionVec_6,
  input           io_in_5_bits_exceptionVec_7,
  input           io_in_5_bits_exceptionVec_8,
  input           io_in_5_bits_exceptionVec_9,
  input           io_in_5_bits_exceptionVec_10,
  input           io_in_5_bits_exceptionVec_11,
  input           io_in_5_bits_exceptionVec_12,
  input           io_in_5_bits_exceptionVec_13,
  input           io_in_5_bits_exceptionVec_14,
  input           io_in_5_bits_exceptionVec_15,
  input           io_in_5_bits_exceptionVec_16,
  input           io_in_5_bits_exceptionVec_17,
  input           io_in_5_bits_exceptionVec_18,
  input           io_in_5_bits_exceptionVec_19,
  input           io_in_5_bits_exceptionVec_20,
  input           io_in_5_bits_exceptionVec_21,
  input           io_in_5_bits_exceptionVec_23,
  input           io_in_5_bits_isFetchMalAddr,
  input  [3:0]    io_in_5_bits_trigger,
  input           io_in_5_bits_preDecodeInfo_valid,
  input           io_in_5_bits_preDecodeInfo_isRVC,
  input  [1:0]    io_in_5_bits_preDecodeInfo_brType,
  input           io_in_5_bits_preDecodeInfo_isCall,
  input           io_in_5_bits_preDecodeInfo_isRet,
  input           io_in_5_bits_pred_taken,
  input           io_in_5_bits_crossPageIPFFix,
  input           io_in_5_bits_ftqPtr_flag,
  input  [5:0]    io_in_5_bits_ftqPtr_value,
  input  [3:0]    io_in_5_bits_ftqOffset,
  input           io_in_5_bits_isLastInFtqEntry,
  input  [55:0]   io_in_5_bits_debug_seqNum_seqNum,
  input  [7:0]    io_in_5_bits_debug_seqNum_uopIdx,
  input           io_in_5_bits_satpFlushFirstFetchFault,
  input           io_out_0_ready,
  output          io_out_0_valid,
  output [31:0]   io_out_0_bits_instr,
  output [49:0]   io_out_0_bits_pc,
  output [9:0]    io_out_0_bits_foldpc,
  output          io_out_0_bits_exceptionVec_0,
  output          io_out_0_bits_exceptionVec_1,
  output          io_out_0_bits_exceptionVec_2,
  output          io_out_0_bits_exceptionVec_3,
  output          io_out_0_bits_exceptionVec_4,
  output          io_out_0_bits_exceptionVec_5,
  output          io_out_0_bits_exceptionVec_6,
  output          io_out_0_bits_exceptionVec_7,
  output          io_out_0_bits_exceptionVec_8,
  output          io_out_0_bits_exceptionVec_9,
  output          io_out_0_bits_exceptionVec_10,
  output          io_out_0_bits_exceptionVec_11,
  output          io_out_0_bits_exceptionVec_12,
  output          io_out_0_bits_exceptionVec_13,
  output          io_out_0_bits_exceptionVec_14,
  output          io_out_0_bits_exceptionVec_15,
  output          io_out_0_bits_exceptionVec_16,
  output          io_out_0_bits_exceptionVec_17,
  output          io_out_0_bits_exceptionVec_18,
  output          io_out_0_bits_exceptionVec_19,
  output          io_out_0_bits_exceptionVec_20,
  output          io_out_0_bits_exceptionVec_21,
  output          io_out_0_bits_exceptionVec_22,
  output          io_out_0_bits_exceptionVec_23,
  output          io_out_0_bits_isFetchMalAddr,
  output [3:0]    io_out_0_bits_trigger,
  output          io_out_0_bits_preDecodeInfo_valid,
  output          io_out_0_bits_preDecodeInfo_isRVC,
  output [1:0]    io_out_0_bits_preDecodeInfo_brType,
  output          io_out_0_bits_preDecodeInfo_isCall,
  output          io_out_0_bits_preDecodeInfo_isRet,
  output          io_out_0_bits_pred_taken,
  output          io_out_0_bits_crossPageIPFFix,
  output          io_out_0_bits_ftqPtr_flag,
  output [5:0]    io_out_0_bits_ftqPtr_value,
  output [3:0]    io_out_0_bits_ftqOffset,
  output          io_out_0_bits_satpFlushFirstFetchFault,
  output [3:0]    io_out_0_bits_srcType_0,
  output [3:0]    io_out_0_bits_srcType_1,
  output [3:0]    io_out_0_bits_srcType_2,
  output [3:0]    io_out_0_bits_srcType_3,
  output [3:0]    io_out_0_bits_srcType_4,
  output [5:0]    io_out_0_bits_lsrc_0,
  output [5:0]    io_out_0_bits_lsrc_1,
  output [5:0]    io_out_0_bits_lsrc_2,
  output [5:0]    io_out_0_bits_ldest,
  output [34:0]   io_out_0_bits_fuType,
  output [8:0]    io_out_0_bits_fuOpType,
  output          io_out_0_bits_rfWen,
  output          io_out_0_bits_fpWen,
  output          io_out_0_bits_vecWen,
  output          io_out_0_bits_v0Wen,
  output          io_out_0_bits_vlWen,
  output          io_out_0_bits_isXSTrap,
  output          io_out_0_bits_waitForward,
  output          io_out_0_bits_blockBackward,
  output          io_out_0_bits_flushPipe,
  output          io_out_0_bits_canRobCompress,
  output [3:0]    io_out_0_bits_selImm,
  output [21:0]   io_out_0_bits_imm,
  output [1:0]    io_out_0_bits_fpu_typeTagOut,
  output          io_out_0_bits_fpu_wflags,
  output [1:0]    io_out_0_bits_fpu_typ,
  output [1:0]    io_out_0_bits_fpu_fmt,
  output [2:0]    io_out_0_bits_fpu_rm,
  output          io_out_0_bits_vpu_vill,
  output          io_out_0_bits_vpu_vma,
  output          io_out_0_bits_vpu_vta,
  output [1:0]    io_out_0_bits_vpu_vsew,
  output [2:0]    io_out_0_bits_vpu_vlmul,
  output          io_out_0_bits_vpu_specVill,
  output          io_out_0_bits_vpu_specVma,
  output          io_out_0_bits_vpu_specVta,
  output [1:0]    io_out_0_bits_vpu_specVsew,
  output [2:0]    io_out_0_bits_vpu_specVlmul,
  output          io_out_0_bits_vpu_vm,
  output [7:0]    io_out_0_bits_vpu_vstart,
  output          io_out_0_bits_vpu_fpu_isFoldTo1_2,
  output          io_out_0_bits_vpu_fpu_isFoldTo1_4,
  output          io_out_0_bits_vpu_fpu_isFoldTo1_8,
  output [2:0]    io_out_0_bits_vpu_nf,
  output [1:0]    io_out_0_bits_vpu_veew,
  output          io_out_0_bits_vpu_isReverse,
  output          io_out_0_bits_vpu_isExt,
  output          io_out_0_bits_vpu_isNarrow,
  output          io_out_0_bits_vpu_isDstMask,
  output          io_out_0_bits_vpu_isOpMask,
  output          io_out_0_bits_vpu_isDependOldVd,
  output          io_out_0_bits_vpu_isWritePartVd,
  output          io_out_0_bits_vpu_isVleff,
  output          io_out_0_bits_vlsInstr,
  output          io_out_0_bits_wfflags,
  output          io_out_0_bits_isMove,
  output [6:0]    io_out_0_bits_uopIdx,
  output [5:0]    io_out_0_bits_uopSplitType,
  output          io_out_0_bits_isVset,
  output          io_out_0_bits_firstUop,
  output          io_out_0_bits_lastUop,
  output [6:0]    io_out_0_bits_numUops,
  output [6:0]    io_out_0_bits_numWB,
  output [2:0]    io_out_0_bits_commitType,
  output [34:0]   io_out_0_bits_debug_fuType,
  output [55:0]   io_out_0_bits_debug_seqNum_seqNum,
  output [7:0]    io_out_0_bits_debug_seqNum_uopIdx,
  input           io_out_1_ready,
  output          io_out_1_valid,
  output [31:0]   io_out_1_bits_instr,
  output [49:0]   io_out_1_bits_pc,
  output [9:0]    io_out_1_bits_foldpc,
  output          io_out_1_bits_exceptionVec_0,
  output          io_out_1_bits_exceptionVec_1,
  output          io_out_1_bits_exceptionVec_2,
  output          io_out_1_bits_exceptionVec_3,
  output          io_out_1_bits_exceptionVec_4,
  output          io_out_1_bits_exceptionVec_5,
  output          io_out_1_bits_exceptionVec_6,
  output          io_out_1_bits_exceptionVec_7,
  output          io_out_1_bits_exceptionVec_8,
  output          io_out_1_bits_exceptionVec_9,
  output          io_out_1_bits_exceptionVec_10,
  output          io_out_1_bits_exceptionVec_11,
  output          io_out_1_bits_exceptionVec_12,
  output          io_out_1_bits_exceptionVec_13,
  output          io_out_1_bits_exceptionVec_14,
  output          io_out_1_bits_exceptionVec_15,
  output          io_out_1_bits_exceptionVec_16,
  output          io_out_1_bits_exceptionVec_17,
  output          io_out_1_bits_exceptionVec_18,
  output          io_out_1_bits_exceptionVec_19,
  output          io_out_1_bits_exceptionVec_20,
  output          io_out_1_bits_exceptionVec_21,
  output          io_out_1_bits_exceptionVec_22,
  output          io_out_1_bits_exceptionVec_23,
  output          io_out_1_bits_isFetchMalAddr,
  output [3:0]    io_out_1_bits_trigger,
  output          io_out_1_bits_preDecodeInfo_valid,
  output          io_out_1_bits_preDecodeInfo_isRVC,
  output [1:0]    io_out_1_bits_preDecodeInfo_brType,
  output          io_out_1_bits_preDecodeInfo_isCall,
  output          io_out_1_bits_preDecodeInfo_isRet,
  output          io_out_1_bits_pred_taken,
  output          io_out_1_bits_crossPageIPFFix,
  output          io_out_1_bits_ftqPtr_flag,
  output [5:0]    io_out_1_bits_ftqPtr_value,
  output [3:0]    io_out_1_bits_ftqOffset,
  output          io_out_1_bits_satpFlushFirstFetchFault,
  output [3:0]    io_out_1_bits_srcType_0,
  output [3:0]    io_out_1_bits_srcType_1,
  output [3:0]    io_out_1_bits_srcType_2,
  output [3:0]    io_out_1_bits_srcType_3,
  output [3:0]    io_out_1_bits_srcType_4,
  output [5:0]    io_out_1_bits_lsrc_0,
  output [5:0]    io_out_1_bits_lsrc_1,
  output [5:0]    io_out_1_bits_lsrc_2,
  output [5:0]    io_out_1_bits_ldest,
  output [34:0]   io_out_1_bits_fuType,
  output [8:0]    io_out_1_bits_fuOpType,
  output          io_out_1_bits_rfWen,
  output          io_out_1_bits_fpWen,
  output          io_out_1_bits_vecWen,
  output          io_out_1_bits_v0Wen,
  output          io_out_1_bits_vlWen,
  output          io_out_1_bits_isXSTrap,
  output          io_out_1_bits_waitForward,
  output          io_out_1_bits_blockBackward,
  output          io_out_1_bits_flushPipe,
  output          io_out_1_bits_canRobCompress,
  output [3:0]    io_out_1_bits_selImm,
  output [21:0]   io_out_1_bits_imm,
  output [1:0]    io_out_1_bits_fpu_typeTagOut,
  output          io_out_1_bits_fpu_wflags,
  output [1:0]    io_out_1_bits_fpu_typ,
  output [1:0]    io_out_1_bits_fpu_fmt,
  output [2:0]    io_out_1_bits_fpu_rm,
  output          io_out_1_bits_vpu_vill,
  output          io_out_1_bits_vpu_vma,
  output          io_out_1_bits_vpu_vta,
  output [1:0]    io_out_1_bits_vpu_vsew,
  output [2:0]    io_out_1_bits_vpu_vlmul,
  output          io_out_1_bits_vpu_specVill,
  output          io_out_1_bits_vpu_specVma,
  output          io_out_1_bits_vpu_specVta,
  output [1:0]    io_out_1_bits_vpu_specVsew,
  output [2:0]    io_out_1_bits_vpu_specVlmul,
  output          io_out_1_bits_vpu_vm,
  output [7:0]    io_out_1_bits_vpu_vstart,
  output          io_out_1_bits_vpu_fpu_isFoldTo1_2,
  output          io_out_1_bits_vpu_fpu_isFoldTo1_4,
  output          io_out_1_bits_vpu_fpu_isFoldTo1_8,
  output [2:0]    io_out_1_bits_vpu_nf,
  output [1:0]    io_out_1_bits_vpu_veew,
  output          io_out_1_bits_vpu_isReverse,
  output          io_out_1_bits_vpu_isExt,
  output          io_out_1_bits_vpu_isNarrow,
  output          io_out_1_bits_vpu_isDstMask,
  output          io_out_1_bits_vpu_isOpMask,
  output          io_out_1_bits_vpu_isDependOldVd,
  output          io_out_1_bits_vpu_isWritePartVd,
  output          io_out_1_bits_vpu_isVleff,
  output          io_out_1_bits_vlsInstr,
  output          io_out_1_bits_wfflags,
  output          io_out_1_bits_isMove,
  output [6:0]    io_out_1_bits_uopIdx,
  output [5:0]    io_out_1_bits_uopSplitType,
  output          io_out_1_bits_isVset,
  output          io_out_1_bits_firstUop,
  output          io_out_1_bits_lastUop,
  output [6:0]    io_out_1_bits_numUops,
  output [6:0]    io_out_1_bits_numWB,
  output [2:0]    io_out_1_bits_commitType,
  output [34:0]   io_out_1_bits_debug_fuType,
  output [55:0]   io_out_1_bits_debug_seqNum_seqNum,
  output [7:0]    io_out_1_bits_debug_seqNum_uopIdx,
  input           io_out_2_ready,
  output          io_out_2_valid,
  output [31:0]   io_out_2_bits_instr,
  output [49:0]   io_out_2_bits_pc,
  output [9:0]    io_out_2_bits_foldpc,
  output          io_out_2_bits_exceptionVec_0,
  output          io_out_2_bits_exceptionVec_1,
  output          io_out_2_bits_exceptionVec_2,
  output          io_out_2_bits_exceptionVec_3,
  output          io_out_2_bits_exceptionVec_4,
  output          io_out_2_bits_exceptionVec_5,
  output          io_out_2_bits_exceptionVec_6,
  output          io_out_2_bits_exceptionVec_7,
  output          io_out_2_bits_exceptionVec_8,
  output          io_out_2_bits_exceptionVec_9,
  output          io_out_2_bits_exceptionVec_10,
  output          io_out_2_bits_exceptionVec_11,
  output          io_out_2_bits_exceptionVec_12,
  output          io_out_2_bits_exceptionVec_13,
  output          io_out_2_bits_exceptionVec_14,
  output          io_out_2_bits_exceptionVec_15,
  output          io_out_2_bits_exceptionVec_16,
  output          io_out_2_bits_exceptionVec_17,
  output          io_out_2_bits_exceptionVec_18,
  output          io_out_2_bits_exceptionVec_19,
  output          io_out_2_bits_exceptionVec_20,
  output          io_out_2_bits_exceptionVec_21,
  output          io_out_2_bits_exceptionVec_22,
  output          io_out_2_bits_exceptionVec_23,
  output          io_out_2_bits_isFetchMalAddr,
  output [3:0]    io_out_2_bits_trigger,
  output          io_out_2_bits_preDecodeInfo_valid,
  output          io_out_2_bits_preDecodeInfo_isRVC,
  output [1:0]    io_out_2_bits_preDecodeInfo_brType,
  output          io_out_2_bits_preDecodeInfo_isCall,
  output          io_out_2_bits_preDecodeInfo_isRet,
  output          io_out_2_bits_pred_taken,
  output          io_out_2_bits_crossPageIPFFix,
  output          io_out_2_bits_ftqPtr_flag,
  output [5:0]    io_out_2_bits_ftqPtr_value,
  output [3:0]    io_out_2_bits_ftqOffset,
  output          io_out_2_bits_satpFlushFirstFetchFault,
  output [3:0]    io_out_2_bits_srcType_0,
  output [3:0]    io_out_2_bits_srcType_1,
  output [3:0]    io_out_2_bits_srcType_2,
  output [3:0]    io_out_2_bits_srcType_3,
  output [3:0]    io_out_2_bits_srcType_4,
  output [5:0]    io_out_2_bits_lsrc_0,
  output [5:0]    io_out_2_bits_lsrc_1,
  output [5:0]    io_out_2_bits_lsrc_2,
  output [5:0]    io_out_2_bits_ldest,
  output [34:0]   io_out_2_bits_fuType,
  output [8:0]    io_out_2_bits_fuOpType,
  output          io_out_2_bits_rfWen,
  output          io_out_2_bits_fpWen,
  output          io_out_2_bits_vecWen,
  output          io_out_2_bits_v0Wen,
  output          io_out_2_bits_vlWen,
  output          io_out_2_bits_isXSTrap,
  output          io_out_2_bits_waitForward,
  output          io_out_2_bits_blockBackward,
  output          io_out_2_bits_flushPipe,
  output          io_out_2_bits_canRobCompress,
  output [3:0]    io_out_2_bits_selImm,
  output [21:0]   io_out_2_bits_imm,
  output [1:0]    io_out_2_bits_fpu_typeTagOut,
  output          io_out_2_bits_fpu_wflags,
  output [1:0]    io_out_2_bits_fpu_typ,
  output [1:0]    io_out_2_bits_fpu_fmt,
  output [2:0]    io_out_2_bits_fpu_rm,
  output          io_out_2_bits_vpu_vill,
  output          io_out_2_bits_vpu_vma,
  output          io_out_2_bits_vpu_vta,
  output [1:0]    io_out_2_bits_vpu_vsew,
  output [2:0]    io_out_2_bits_vpu_vlmul,
  output          io_out_2_bits_vpu_specVill,
  output          io_out_2_bits_vpu_specVma,
  output          io_out_2_bits_vpu_specVta,
  output [1:0]    io_out_2_bits_vpu_specVsew,
  output [2:0]    io_out_2_bits_vpu_specVlmul,
  output          io_out_2_bits_vpu_vm,
  output [7:0]    io_out_2_bits_vpu_vstart,
  output          io_out_2_bits_vpu_fpu_isFoldTo1_2,
  output          io_out_2_bits_vpu_fpu_isFoldTo1_4,
  output          io_out_2_bits_vpu_fpu_isFoldTo1_8,
  output [2:0]    io_out_2_bits_vpu_nf,
  output [1:0]    io_out_2_bits_vpu_veew,
  output          io_out_2_bits_vpu_isReverse,
  output          io_out_2_bits_vpu_isExt,
  output          io_out_2_bits_vpu_isNarrow,
  output          io_out_2_bits_vpu_isDstMask,
  output          io_out_2_bits_vpu_isOpMask,
  output          io_out_2_bits_vpu_isDependOldVd,
  output          io_out_2_bits_vpu_isWritePartVd,
  output          io_out_2_bits_vpu_isVleff,
  output          io_out_2_bits_vlsInstr,
  output          io_out_2_bits_wfflags,
  output          io_out_2_bits_isMove,
  output [6:0]    io_out_2_bits_uopIdx,
  output [5:0]    io_out_2_bits_uopSplitType,
  output          io_out_2_bits_isVset,
  output          io_out_2_bits_firstUop,
  output          io_out_2_bits_lastUop,
  output [6:0]    io_out_2_bits_numUops,
  output [6:0]    io_out_2_bits_numWB,
  output [2:0]    io_out_2_bits_commitType,
  output [34:0]   io_out_2_bits_debug_fuType,
  output [55:0]   io_out_2_bits_debug_seqNum_seqNum,
  output [7:0]    io_out_2_bits_debug_seqNum_uopIdx,
  input           io_out_3_ready,
  output          io_out_3_valid,
  output [31:0]   io_out_3_bits_instr,
  output [49:0]   io_out_3_bits_pc,
  output [9:0]    io_out_3_bits_foldpc,
  output          io_out_3_bits_exceptionVec_0,
  output          io_out_3_bits_exceptionVec_1,
  output          io_out_3_bits_exceptionVec_2,
  output          io_out_3_bits_exceptionVec_3,
  output          io_out_3_bits_exceptionVec_4,
  output          io_out_3_bits_exceptionVec_5,
  output          io_out_3_bits_exceptionVec_6,
  output          io_out_3_bits_exceptionVec_7,
  output          io_out_3_bits_exceptionVec_8,
  output          io_out_3_bits_exceptionVec_9,
  output          io_out_3_bits_exceptionVec_10,
  output          io_out_3_bits_exceptionVec_11,
  output          io_out_3_bits_exceptionVec_12,
  output          io_out_3_bits_exceptionVec_13,
  output          io_out_3_bits_exceptionVec_14,
  output          io_out_3_bits_exceptionVec_15,
  output          io_out_3_bits_exceptionVec_16,
  output          io_out_3_bits_exceptionVec_17,
  output          io_out_3_bits_exceptionVec_18,
  output          io_out_3_bits_exceptionVec_19,
  output          io_out_3_bits_exceptionVec_20,
  output          io_out_3_bits_exceptionVec_21,
  output          io_out_3_bits_exceptionVec_22,
  output          io_out_3_bits_exceptionVec_23,
  output          io_out_3_bits_isFetchMalAddr,
  output [3:0]    io_out_3_bits_trigger,
  output          io_out_3_bits_preDecodeInfo_valid,
  output          io_out_3_bits_preDecodeInfo_isRVC,
  output [1:0]    io_out_3_bits_preDecodeInfo_brType,
  output          io_out_3_bits_preDecodeInfo_isCall,
  output          io_out_3_bits_preDecodeInfo_isRet,
  output          io_out_3_bits_pred_taken,
  output          io_out_3_bits_crossPageIPFFix,
  output          io_out_3_bits_ftqPtr_flag,
  output [5:0]    io_out_3_bits_ftqPtr_value,
  output [3:0]    io_out_3_bits_ftqOffset,
  output          io_out_3_bits_satpFlushFirstFetchFault,
  output [3:0]    io_out_3_bits_srcType_0,
  output [3:0]    io_out_3_bits_srcType_1,
  output [3:0]    io_out_3_bits_srcType_2,
  output [3:0]    io_out_3_bits_srcType_3,
  output [3:0]    io_out_3_bits_srcType_4,
  output [5:0]    io_out_3_bits_lsrc_0,
  output [5:0]    io_out_3_bits_lsrc_1,
  output [5:0]    io_out_3_bits_lsrc_2,
  output [5:0]    io_out_3_bits_ldest,
  output [34:0]   io_out_3_bits_fuType,
  output [8:0]    io_out_3_bits_fuOpType,
  output          io_out_3_bits_rfWen,
  output          io_out_3_bits_fpWen,
  output          io_out_3_bits_vecWen,
  output          io_out_3_bits_v0Wen,
  output          io_out_3_bits_vlWen,
  output          io_out_3_bits_isXSTrap,
  output          io_out_3_bits_waitForward,
  output          io_out_3_bits_blockBackward,
  output          io_out_3_bits_flushPipe,
  output          io_out_3_bits_canRobCompress,
  output [3:0]    io_out_3_bits_selImm,
  output [21:0]   io_out_3_bits_imm,
  output [1:0]    io_out_3_bits_fpu_typeTagOut,
  output          io_out_3_bits_fpu_wflags,
  output [1:0]    io_out_3_bits_fpu_typ,
  output [1:0]    io_out_3_bits_fpu_fmt,
  output [2:0]    io_out_3_bits_fpu_rm,
  output          io_out_3_bits_vpu_vill,
  output          io_out_3_bits_vpu_vma,
  output          io_out_3_bits_vpu_vta,
  output [1:0]    io_out_3_bits_vpu_vsew,
  output [2:0]    io_out_3_bits_vpu_vlmul,
  output          io_out_3_bits_vpu_specVill,
  output          io_out_3_bits_vpu_specVma,
  output          io_out_3_bits_vpu_specVta,
  output [1:0]    io_out_3_bits_vpu_specVsew,
  output [2:0]    io_out_3_bits_vpu_specVlmul,
  output          io_out_3_bits_vpu_vm,
  output [7:0]    io_out_3_bits_vpu_vstart,
  output          io_out_3_bits_vpu_fpu_isFoldTo1_2,
  output          io_out_3_bits_vpu_fpu_isFoldTo1_4,
  output          io_out_3_bits_vpu_fpu_isFoldTo1_8,
  output [2:0]    io_out_3_bits_vpu_nf,
  output [1:0]    io_out_3_bits_vpu_veew,
  output          io_out_3_bits_vpu_isReverse,
  output          io_out_3_bits_vpu_isExt,
  output          io_out_3_bits_vpu_isNarrow,
  output          io_out_3_bits_vpu_isDstMask,
  output          io_out_3_bits_vpu_isOpMask,
  output          io_out_3_bits_vpu_isDependOldVd,
  output          io_out_3_bits_vpu_isWritePartVd,
  output          io_out_3_bits_vpu_isVleff,
  output          io_out_3_bits_vlsInstr,
  output          io_out_3_bits_wfflags,
  output          io_out_3_bits_isMove,
  output [6:0]    io_out_3_bits_uopIdx,
  output [5:0]    io_out_3_bits_uopSplitType,
  output          io_out_3_bits_isVset,
  output          io_out_3_bits_firstUop,
  output          io_out_3_bits_lastUop,
  output [6:0]    io_out_3_bits_numUops,
  output [6:0]    io_out_3_bits_numWB,
  output [2:0]    io_out_3_bits_commitType,
  output [34:0]   io_out_3_bits_debug_fuType,
  output [55:0]   io_out_3_bits_debug_seqNum_seqNum,
  output [7:0]    io_out_3_bits_debug_seqNum_uopIdx,
  input           io_out_4_ready,
  output          io_out_4_valid,
  output [31:0]   io_out_4_bits_instr,
  output [49:0]   io_out_4_bits_pc,
  output [9:0]    io_out_4_bits_foldpc,
  output          io_out_4_bits_exceptionVec_0,
  output          io_out_4_bits_exceptionVec_1,
  output          io_out_4_bits_exceptionVec_2,
  output          io_out_4_bits_exceptionVec_3,
  output          io_out_4_bits_exceptionVec_4,
  output          io_out_4_bits_exceptionVec_5,
  output          io_out_4_bits_exceptionVec_6,
  output          io_out_4_bits_exceptionVec_7,
  output          io_out_4_bits_exceptionVec_8,
  output          io_out_4_bits_exceptionVec_9,
  output          io_out_4_bits_exceptionVec_10,
  output          io_out_4_bits_exceptionVec_11,
  output          io_out_4_bits_exceptionVec_12,
  output          io_out_4_bits_exceptionVec_13,
  output          io_out_4_bits_exceptionVec_14,
  output          io_out_4_bits_exceptionVec_15,
  output          io_out_4_bits_exceptionVec_16,
  output          io_out_4_bits_exceptionVec_17,
  output          io_out_4_bits_exceptionVec_18,
  output          io_out_4_bits_exceptionVec_19,
  output          io_out_4_bits_exceptionVec_20,
  output          io_out_4_bits_exceptionVec_21,
  output          io_out_4_bits_exceptionVec_22,
  output          io_out_4_bits_exceptionVec_23,
  output          io_out_4_bits_isFetchMalAddr,
  output [3:0]    io_out_4_bits_trigger,
  output          io_out_4_bits_preDecodeInfo_valid,
  output          io_out_4_bits_preDecodeInfo_isRVC,
  output [1:0]    io_out_4_bits_preDecodeInfo_brType,
  output          io_out_4_bits_preDecodeInfo_isCall,
  output          io_out_4_bits_preDecodeInfo_isRet,
  output          io_out_4_bits_pred_taken,
  output          io_out_4_bits_crossPageIPFFix,
  output          io_out_4_bits_ftqPtr_flag,
  output [5:0]    io_out_4_bits_ftqPtr_value,
  output [3:0]    io_out_4_bits_ftqOffset,
  output          io_out_4_bits_satpFlushFirstFetchFault,
  output [3:0]    io_out_4_bits_srcType_0,
  output [3:0]    io_out_4_bits_srcType_1,
  output [3:0]    io_out_4_bits_srcType_2,
  output [3:0]    io_out_4_bits_srcType_3,
  output [3:0]    io_out_4_bits_srcType_4,
  output [5:0]    io_out_4_bits_lsrc_0,
  output [5:0]    io_out_4_bits_lsrc_1,
  output [5:0]    io_out_4_bits_lsrc_2,
  output [5:0]    io_out_4_bits_ldest,
  output [34:0]   io_out_4_bits_fuType,
  output [8:0]    io_out_4_bits_fuOpType,
  output          io_out_4_bits_rfWen,
  output          io_out_4_bits_fpWen,
  output          io_out_4_bits_vecWen,
  output          io_out_4_bits_v0Wen,
  output          io_out_4_bits_vlWen,
  output          io_out_4_bits_isXSTrap,
  output          io_out_4_bits_waitForward,
  output          io_out_4_bits_blockBackward,
  output          io_out_4_bits_flushPipe,
  output          io_out_4_bits_canRobCompress,
  output [3:0]    io_out_4_bits_selImm,
  output [21:0]   io_out_4_bits_imm,
  output [1:0]    io_out_4_bits_fpu_typeTagOut,
  output          io_out_4_bits_fpu_wflags,
  output [1:0]    io_out_4_bits_fpu_typ,
  output [1:0]    io_out_4_bits_fpu_fmt,
  output [2:0]    io_out_4_bits_fpu_rm,
  output          io_out_4_bits_vpu_vill,
  output          io_out_4_bits_vpu_vma,
  output          io_out_4_bits_vpu_vta,
  output [1:0]    io_out_4_bits_vpu_vsew,
  output [2:0]    io_out_4_bits_vpu_vlmul,
  output          io_out_4_bits_vpu_specVill,
  output          io_out_4_bits_vpu_specVma,
  output          io_out_4_bits_vpu_specVta,
  output [1:0]    io_out_4_bits_vpu_specVsew,
  output [2:0]    io_out_4_bits_vpu_specVlmul,
  output          io_out_4_bits_vpu_vm,
  output [7:0]    io_out_4_bits_vpu_vstart,
  output          io_out_4_bits_vpu_fpu_isFoldTo1_2,
  output          io_out_4_bits_vpu_fpu_isFoldTo1_4,
  output          io_out_4_bits_vpu_fpu_isFoldTo1_8,
  output [2:0]    io_out_4_bits_vpu_nf,
  output [1:0]    io_out_4_bits_vpu_veew,
  output          io_out_4_bits_vpu_isReverse,
  output          io_out_4_bits_vpu_isExt,
  output          io_out_4_bits_vpu_isNarrow,
  output          io_out_4_bits_vpu_isDstMask,
  output          io_out_4_bits_vpu_isOpMask,
  output          io_out_4_bits_vpu_isDependOldVd,
  output          io_out_4_bits_vpu_isWritePartVd,
  output          io_out_4_bits_vpu_isVleff,
  output          io_out_4_bits_vlsInstr,
  output          io_out_4_bits_wfflags,
  output          io_out_4_bits_isMove,
  output [6:0]    io_out_4_bits_uopIdx,
  output [5:0]    io_out_4_bits_uopSplitType,
  output          io_out_4_bits_isVset,
  output          io_out_4_bits_firstUop,
  output          io_out_4_bits_lastUop,
  output [6:0]    io_out_4_bits_numUops,
  output [6:0]    io_out_4_bits_numWB,
  output [2:0]    io_out_4_bits_commitType,
  output [34:0]   io_out_4_bits_debug_fuType,
  output [55:0]   io_out_4_bits_debug_seqNum_seqNum,
  output [7:0]    io_out_4_bits_debug_seqNum_uopIdx,
  input           io_out_5_ready,
  output          io_out_5_valid,
  output [31:0]   io_out_5_bits_instr,
  output [49:0]   io_out_5_bits_pc,
  output [9:0]    io_out_5_bits_foldpc,
  output          io_out_5_bits_exceptionVec_0,
  output          io_out_5_bits_exceptionVec_1,
  output          io_out_5_bits_exceptionVec_2,
  output          io_out_5_bits_exceptionVec_3,
  output          io_out_5_bits_exceptionVec_4,
  output          io_out_5_bits_exceptionVec_5,
  output          io_out_5_bits_exceptionVec_6,
  output          io_out_5_bits_exceptionVec_7,
  output          io_out_5_bits_exceptionVec_8,
  output          io_out_5_bits_exceptionVec_9,
  output          io_out_5_bits_exceptionVec_10,
  output          io_out_5_bits_exceptionVec_11,
  output          io_out_5_bits_exceptionVec_12,
  output          io_out_5_bits_exceptionVec_13,
  output          io_out_5_bits_exceptionVec_14,
  output          io_out_5_bits_exceptionVec_15,
  output          io_out_5_bits_exceptionVec_16,
  output          io_out_5_bits_exceptionVec_17,
  output          io_out_5_bits_exceptionVec_18,
  output          io_out_5_bits_exceptionVec_19,
  output          io_out_5_bits_exceptionVec_20,
  output          io_out_5_bits_exceptionVec_21,
  output          io_out_5_bits_exceptionVec_22,
  output          io_out_5_bits_exceptionVec_23,
  output          io_out_5_bits_isFetchMalAddr,
  output [3:0]    io_out_5_bits_trigger,
  output          io_out_5_bits_preDecodeInfo_valid,
  output          io_out_5_bits_preDecodeInfo_isRVC,
  output [1:0]    io_out_5_bits_preDecodeInfo_brType,
  output          io_out_5_bits_preDecodeInfo_isCall,
  output          io_out_5_bits_preDecodeInfo_isRet,
  output          io_out_5_bits_pred_taken,
  output          io_out_5_bits_crossPageIPFFix,
  output          io_out_5_bits_ftqPtr_flag,
  output [5:0]    io_out_5_bits_ftqPtr_value,
  output [3:0]    io_out_5_bits_ftqOffset,
  output          io_out_5_bits_satpFlushFirstFetchFault,
  output [3:0]    io_out_5_bits_srcType_0,
  output [3:0]    io_out_5_bits_srcType_1,
  output [3:0]    io_out_5_bits_srcType_2,
  output [3:0]    io_out_5_bits_srcType_3,
  output [3:0]    io_out_5_bits_srcType_4,
  output [5:0]    io_out_5_bits_lsrc_0,
  output [5:0]    io_out_5_bits_lsrc_1,
  output [5:0]    io_out_5_bits_lsrc_2,
  output [5:0]    io_out_5_bits_ldest,
  output [34:0]   io_out_5_bits_fuType,
  output [8:0]    io_out_5_bits_fuOpType,
  output          io_out_5_bits_rfWen,
  output          io_out_5_bits_fpWen,
  output          io_out_5_bits_vecWen,
  output          io_out_5_bits_v0Wen,
  output          io_out_5_bits_vlWen,
  output          io_out_5_bits_isXSTrap,
  output          io_out_5_bits_waitForward,
  output          io_out_5_bits_blockBackward,
  output          io_out_5_bits_flushPipe,
  output          io_out_5_bits_canRobCompress,
  output [3:0]    io_out_5_bits_selImm,
  output [21:0]   io_out_5_bits_imm,
  output [1:0]    io_out_5_bits_fpu_typeTagOut,
  output          io_out_5_bits_fpu_wflags,
  output [1:0]    io_out_5_bits_fpu_typ,
  output [1:0]    io_out_5_bits_fpu_fmt,
  output [2:0]    io_out_5_bits_fpu_rm,
  output          io_out_5_bits_vpu_vill,
  output          io_out_5_bits_vpu_vma,
  output          io_out_5_bits_vpu_vta,
  output [1:0]    io_out_5_bits_vpu_vsew,
  output [2:0]    io_out_5_bits_vpu_vlmul,
  output          io_out_5_bits_vpu_specVill,
  output          io_out_5_bits_vpu_specVma,
  output          io_out_5_bits_vpu_specVta,
  output [1:0]    io_out_5_bits_vpu_specVsew,
  output [2:0]    io_out_5_bits_vpu_specVlmul,
  output          io_out_5_bits_vpu_vm,
  output [7:0]    io_out_5_bits_vpu_vstart,
  output          io_out_5_bits_vpu_fpu_isFoldTo1_2,
  output          io_out_5_bits_vpu_fpu_isFoldTo1_4,
  output          io_out_5_bits_vpu_fpu_isFoldTo1_8,
  output [2:0]    io_out_5_bits_vpu_nf,
  output [1:0]    io_out_5_bits_vpu_veew,
  output          io_out_5_bits_vpu_isReverse,
  output          io_out_5_bits_vpu_isExt,
  output          io_out_5_bits_vpu_isNarrow,
  output          io_out_5_bits_vpu_isDstMask,
  output          io_out_5_bits_vpu_isOpMask,
  output          io_out_5_bits_vpu_isDependOldVd,
  output          io_out_5_bits_vpu_isWritePartVd,
  output          io_out_5_bits_vpu_isVleff,
  output          io_out_5_bits_vlsInstr,
  output          io_out_5_bits_wfflags,
  output          io_out_5_bits_isMove,
  output [6:0]    io_out_5_bits_uopIdx,
  output [5:0]    io_out_5_bits_uopSplitType,
  output          io_out_5_bits_isVset,
  output          io_out_5_bits_firstUop,
  output          io_out_5_bits_lastUop,
  output [6:0]    io_out_5_bits_numUops,
  output [6:0]    io_out_5_bits_numWB,
  output [2:0]    io_out_5_bits_commitType,
  output [34:0]   io_out_5_bits_debug_fuType,
  output [55:0]   io_out_5_bits_debug_seqNum_seqNum,
  output [7:0]    io_out_5_bits_debug_seqNum_uopIdx,
  output          io_intRat_0_0_hold,
  output [31:0]   io_intRat_0_0_addr,
  output          io_intRat_0_1_hold,
  output [31:0]   io_intRat_0_1_addr,
  output          io_intRat_1_0_hold,
  output [31:0]   io_intRat_1_0_addr,
  output          io_intRat_1_1_hold,
  output [31:0]   io_intRat_1_1_addr,
  output          io_intRat_2_0_hold,
  output [31:0]   io_intRat_2_0_addr,
  output          io_intRat_2_1_hold,
  output [31:0]   io_intRat_2_1_addr,
  output          io_intRat_3_0_hold,
  output [31:0]   io_intRat_3_0_addr,
  output          io_intRat_3_1_hold,
  output [31:0]   io_intRat_3_1_addr,
  output          io_intRat_4_0_hold,
  output [31:0]   io_intRat_4_0_addr,
  output          io_intRat_4_1_hold,
  output [31:0]   io_intRat_4_1_addr,
  output          io_intRat_5_0_hold,
  output [31:0]   io_intRat_5_0_addr,
  output          io_intRat_5_1_hold,
  output [31:0]   io_intRat_5_1_addr,
  output          io_fpRat_0_0_hold,
  output [33:0]   io_fpRat_0_0_addr,
  output          io_fpRat_0_1_hold,
  output [33:0]   io_fpRat_0_1_addr,
  output          io_fpRat_0_2_hold,
  output [33:0]   io_fpRat_0_2_addr,
  output          io_fpRat_1_0_hold,
  output [33:0]   io_fpRat_1_0_addr,
  output          io_fpRat_1_1_hold,
  output [33:0]   io_fpRat_1_1_addr,
  output          io_fpRat_1_2_hold,
  output [33:0]   io_fpRat_1_2_addr,
  output          io_fpRat_2_0_hold,
  output [33:0]   io_fpRat_2_0_addr,
  output          io_fpRat_2_1_hold,
  output [33:0]   io_fpRat_2_1_addr,
  output          io_fpRat_2_2_hold,
  output [33:0]   io_fpRat_2_2_addr,
  output          io_fpRat_3_0_hold,
  output [33:0]   io_fpRat_3_0_addr,
  output          io_fpRat_3_1_hold,
  output [33:0]   io_fpRat_3_1_addr,
  output          io_fpRat_3_2_hold,
  output [33:0]   io_fpRat_3_2_addr,
  output          io_fpRat_4_0_hold,
  output [33:0]   io_fpRat_4_0_addr,
  output          io_fpRat_4_1_hold,
  output [33:0]   io_fpRat_4_1_addr,
  output          io_fpRat_4_2_hold,
  output [33:0]   io_fpRat_4_2_addr,
  output          io_fpRat_5_0_hold,
  output [33:0]   io_fpRat_5_0_addr,
  output          io_fpRat_5_1_hold,
  output [33:0]   io_fpRat_5_1_addr,
  output          io_fpRat_5_2_hold,
  output [33:0]   io_fpRat_5_2_addr,
  output          io_vecRat_0_0_hold,
  output [46:0]   io_vecRat_0_0_addr,
  output          io_vecRat_0_1_hold,
  output [46:0]   io_vecRat_0_1_addr,
  output          io_vecRat_0_2_hold,
  output [46:0]   io_vecRat_0_2_addr,
  output          io_vecRat_1_0_hold,
  output [46:0]   io_vecRat_1_0_addr,
  output          io_vecRat_1_1_hold,
  output [46:0]   io_vecRat_1_1_addr,
  output          io_vecRat_1_2_hold,
  output [46:0]   io_vecRat_1_2_addr,
  output          io_vecRat_2_0_hold,
  output [46:0]   io_vecRat_2_0_addr,
  output          io_vecRat_2_1_hold,
  output [46:0]   io_vecRat_2_1_addr,
  output          io_vecRat_2_2_hold,
  output [46:0]   io_vecRat_2_2_addr,
  output          io_vecRat_3_0_hold,
  output [46:0]   io_vecRat_3_0_addr,
  output          io_vecRat_3_1_hold,
  output [46:0]   io_vecRat_3_1_addr,
  output          io_vecRat_3_2_hold,
  output [46:0]   io_vecRat_3_2_addr,
  output          io_vecRat_4_0_hold,
  output [46:0]   io_vecRat_4_0_addr,
  output          io_vecRat_4_1_hold,
  output [46:0]   io_vecRat_4_1_addr,
  output          io_vecRat_4_2_hold,
  output [46:0]   io_vecRat_4_2_addr,
  output          io_vecRat_5_0_hold,
  output [46:0]   io_vecRat_5_0_addr,
  output          io_vecRat_5_1_hold,
  output [46:0]   io_vecRat_5_1_addr,
  output          io_vecRat_5_2_hold,
  output [46:0]   io_vecRat_5_2_addr,
  output          io_v0Rat_0_hold,
  output          io_v0Rat_1_hold,
  output          io_v0Rat_2_hold,
  output          io_v0Rat_3_hold,
  output          io_v0Rat_4_hold,
  output          io_v0Rat_5_hold,
  output          io_vlRat_0_hold,
  output          io_vlRat_1_hold,
  output          io_vlRat_2_hold,
  output          io_vlRat_3_hold,
  output          io_vlRat_4_hold,
  output          io_vlRat_5_hold,
  input           io_csrCtrl_singlestep,
  input           io_fromCSR_illegalInst_sfenceVMA,
  input           io_fromCSR_illegalInst_sfencePart,
  input           io_fromCSR_illegalInst_hfenceGVMA,
  input           io_fromCSR_illegalInst_hfenceVVMA,
  input           io_fromCSR_illegalInst_hlsv,
  input           io_fromCSR_illegalInst_fsIsOff,
  input           io_fromCSR_illegalInst_vsIsOff,
  input           io_fromCSR_illegalInst_wfi,
  input           io_fromCSR_illegalInst_wrs_nto,
  input           io_fromCSR_illegalInst_frm,
  input           io_fromCSR_illegalInst_cboZ,
  input           io_fromCSR_illegalInst_cboCF,
  input           io_fromCSR_illegalInst_cboI,
  input           io_fromCSR_virtualInst_sfenceVMA,
  input           io_fromCSR_virtualInst_sfencePart,
  input           io_fromCSR_virtualInst_hfence,
  input           io_fromCSR_virtualInst_hlsv,
  input           io_fromCSR_virtualInst_wfi,
  input           io_fromCSR_virtualInst_wrs_nto,
  input           io_fromCSR_virtualInst_cboZ,
  input           io_fromCSR_virtualInst_cboCF,
  input           io_fromCSR_virtualInst_cboI,
  input           io_fromCSR_special_cboI2F,
  input           io_fusion_0,
  input           io_fusion_1,
  input           io_fusion_2,
  input           io_fusion_3,
  input           io_fusion_4,
  input           io_backendCanAccept,
  input           io_fromRob_isResumeVType,
  input           io_fromRob_walkToArchVType,
  input           io_fromRob_commitVType_vtype_valid,
  input           io_fromRob_commitVType_vtype_bits_illegal,
  input           io_fromRob_commitVType_vtype_bits_vma,
  input           io_fromRob_commitVType_vtype_bits_vta,
  input  [1:0]    io_fromRob_commitVType_vtype_bits_vsew,
  input  [2:0]    io_fromRob_commitVType_vtype_bits_vlmul,
  input           io_fromRob_commitVType_hasVsetvl,
  input           io_fromRob_walkVType_valid,
  input           io_fromRob_walkVType_bits_illegal,
  input           io_fromRob_walkVType_bits_vma,
  input           io_fromRob_walkVType_bits_vta,
  input  [1:0]    io_fromRob_walkVType_bits_vsew,
  input  [2:0]    io_fromRob_walkVType_bits_vlmul,
  input  [5:0]    io_stallReason_in_reason_0,
  input  [5:0]    io_stallReason_in_reason_1,
  input  [5:0]    io_stallReason_in_reason_2,
  input  [5:0]    io_stallReason_in_reason_3,
  input  [5:0]    io_stallReason_in_reason_4,
  input  [5:0]    io_stallReason_in_reason_5,
  output          io_stallReason_in_backReason_valid,
  output [5:0]    io_stallReason_in_backReason_bits,
  output [5:0]    io_stallReason_out_reason_0,
  output [5:0]    io_stallReason_out_reason_1,
  output [5:0]    io_stallReason_out_reason_2,
  output [5:0]    io_stallReason_out_reason_3,
  output [5:0]    io_stallReason_out_reason_4,
  output [5:0]    io_stallReason_out_reason_5,
  input           io_stallReason_out_backReason_valid,
  input  [5:0]    io_stallReason_out_backReason_bits,
  input           io_vsetvlVType_illegal,
  input           io_vsetvlVType_vma,
  input           io_vsetvlVType_vta,
  input  [1:0]    io_vsetvlVType_vsew,
  input  [2:0]    io_vsetvlVType_vlmul,
  input  [7:0]    io_vstart,
  output          io_toCSR_trapInstInfo_valid,
  output [31:0]   io_toCSR_trapInstInfo_bits_instr,
  output          io_toCSR_trapInstInfo_bits_ftqPtr_flag,
  output [5:0]    io_toCSR_trapInstInfo_bits_ftqPtr_value,
  output [3:0]    io_toCSR_trapInstInfo_bits_ftqOffset,
  output [5:0]    io_perf_0_value,
  output [5:0]    io_perf_1_value,
  output [5:0]    io_perf_2_value,
  output [5:0]    io_perf_3_value,
  output [5:0]    io_perf_4_value,
  output [5:0]    io_perf_5_value,
  output [5:0]    io_perf_6_value,
  output [5:0]    io_perf_7_value
  // END GENERATED
);

  // BEGIN GENERATED(wrapper)
  // 核的结构体/数组端口 <-> golden 扁平端口（每根线一行，按 golden 端口顺序）
  logic [DECODE_WIDTH-1:0]            in_valid, in_ready, out_valid, out_ready;
  static_inst_t  [DECODE_WIDTH-1:0]   in_bits;
  decoded_inst_t [DECODE_WIDTH-1:0]   out_bits;
  logic [DECODE_WIDTH-1:0][1:0][31:0] intRat_addr;
  logic [DECODE_WIDTH-1:0][1:0]       intRat_hold;
  logic [DECODE_WIDTH-1:0][2:0][33:0] fpRat_addr;
  logic [DECODE_WIDTH-1:0][2:0]       fpRat_hold;
  logic [DECODE_WIDTH-1:0][2:0][46:0] vecRat_addr;
  logic [DECODE_WIDTH-1:0][2:0]       vecRat_hold;
  logic [DECODE_WIDTH-1:0]            v0Rat_hold, vlRat_hold;
  logic [DECODE_WIDTH-2:0]            fusion;
  logic [7:0][5:0]                    perf_value;
  logic [DECODE_WIDTH-1:0][5:0]       stallReason_in_reason, stallReason_out_reason;
  logic                               stallReason_out_backReason_valid, stallReason_in_backReason_valid;
  logic [5:0]                         stallReason_out_backReason_bits, stallReason_in_backReason_bits;
  csr_to_decode_t                     fromCSR;
  from_rob_t                          fromRob;
  vtype_t                             vsetvlVType;
  logic                               trapInstInfo_valid;
  trap_inst_info_t                    trapInstInfo;

  // ---- 输入打包 ----
  assign redirect = io_redirect;
  assign in_valid[0] = io_in_0_valid;
  assign in_bits[0].instr = io_in_0_bits_instr;
  assign in_bits[0].pc = io_in_0_bits_pc;
  assign in_bits[0].foldpc = io_in_0_bits_foldpc;
  assign in_bits[0].exceptionVec[0] = io_in_0_bits_exceptionVec_0;
  assign in_bits[0].exceptionVec[1] = io_in_0_bits_exceptionVec_1;
  assign in_bits[0].exceptionVec[2] = io_in_0_bits_exceptionVec_2;
  assign in_bits[0].exceptionVec[4] = io_in_0_bits_exceptionVec_4;
  assign in_bits[0].exceptionVec[5] = io_in_0_bits_exceptionVec_5;
  assign in_bits[0].exceptionVec[6] = io_in_0_bits_exceptionVec_6;
  assign in_bits[0].exceptionVec[7] = io_in_0_bits_exceptionVec_7;
  assign in_bits[0].exceptionVec[8] = io_in_0_bits_exceptionVec_8;
  assign in_bits[0].exceptionVec[9] = io_in_0_bits_exceptionVec_9;
  assign in_bits[0].exceptionVec[10] = io_in_0_bits_exceptionVec_10;
  assign in_bits[0].exceptionVec[11] = io_in_0_bits_exceptionVec_11;
  assign in_bits[0].exceptionVec[12] = io_in_0_bits_exceptionVec_12;
  assign in_bits[0].exceptionVec[13] = io_in_0_bits_exceptionVec_13;
  assign in_bits[0].exceptionVec[14] = io_in_0_bits_exceptionVec_14;
  assign in_bits[0].exceptionVec[15] = io_in_0_bits_exceptionVec_15;
  assign in_bits[0].exceptionVec[16] = io_in_0_bits_exceptionVec_16;
  assign in_bits[0].exceptionVec[17] = io_in_0_bits_exceptionVec_17;
  assign in_bits[0].exceptionVec[18] = io_in_0_bits_exceptionVec_18;
  assign in_bits[0].exceptionVec[19] = io_in_0_bits_exceptionVec_19;
  assign in_bits[0].exceptionVec[20] = io_in_0_bits_exceptionVec_20;
  assign in_bits[0].exceptionVec[21] = io_in_0_bits_exceptionVec_21;
  assign in_bits[0].exceptionVec[23] = io_in_0_bits_exceptionVec_23;
  assign in_bits[0].isFetchMalAddr = io_in_0_bits_isFetchMalAddr;
  assign in_bits[0].trigger = io_in_0_bits_trigger;
  assign in_bits[0].preDecodeInfo_valid = io_in_0_bits_preDecodeInfo_valid;
  assign in_bits[0].preDecodeInfo_isRVC = io_in_0_bits_preDecodeInfo_isRVC;
  assign in_bits[0].preDecodeInfo_brType = io_in_0_bits_preDecodeInfo_brType;
  assign in_bits[0].preDecodeInfo_isCall = io_in_0_bits_preDecodeInfo_isCall;
  assign in_bits[0].preDecodeInfo_isRet = io_in_0_bits_preDecodeInfo_isRet;
  assign in_bits[0].pred_taken = io_in_0_bits_pred_taken;
  assign in_bits[0].crossPageIPFFix = io_in_0_bits_crossPageIPFFix;
  assign in_bits[0].ftqPtr_flag = io_in_0_bits_ftqPtr_flag;
  assign in_bits[0].ftqPtr_value = io_in_0_bits_ftqPtr_value;
  assign in_bits[0].ftqOffset = io_in_0_bits_ftqOffset;
  assign in_bits[0].isLastInFtqEntry = io_in_0_bits_isLastInFtqEntry;
  assign in_bits[0].debug_seqNum_seqNum = io_in_0_bits_debug_seqNum_seqNum;
  assign in_bits[0].debug_seqNum_uopIdx = io_in_0_bits_debug_seqNum_uopIdx;
  assign in_bits[0].satpFlushFirstFetchFault = io_in_0_bits_satpFlushFirstFetchFault;
  assign in_valid[1] = io_in_1_valid;
  assign in_bits[1].instr = io_in_1_bits_instr;
  assign in_bits[1].pc = io_in_1_bits_pc;
  assign in_bits[1].foldpc = io_in_1_bits_foldpc;
  assign in_bits[1].exceptionVec[0] = io_in_1_bits_exceptionVec_0;
  assign in_bits[1].exceptionVec[1] = io_in_1_bits_exceptionVec_1;
  assign in_bits[1].exceptionVec[2] = io_in_1_bits_exceptionVec_2;
  assign in_bits[1].exceptionVec[4] = io_in_1_bits_exceptionVec_4;
  assign in_bits[1].exceptionVec[5] = io_in_1_bits_exceptionVec_5;
  assign in_bits[1].exceptionVec[6] = io_in_1_bits_exceptionVec_6;
  assign in_bits[1].exceptionVec[7] = io_in_1_bits_exceptionVec_7;
  assign in_bits[1].exceptionVec[8] = io_in_1_bits_exceptionVec_8;
  assign in_bits[1].exceptionVec[9] = io_in_1_bits_exceptionVec_9;
  assign in_bits[1].exceptionVec[10] = io_in_1_bits_exceptionVec_10;
  assign in_bits[1].exceptionVec[11] = io_in_1_bits_exceptionVec_11;
  assign in_bits[1].exceptionVec[12] = io_in_1_bits_exceptionVec_12;
  assign in_bits[1].exceptionVec[13] = io_in_1_bits_exceptionVec_13;
  assign in_bits[1].exceptionVec[14] = io_in_1_bits_exceptionVec_14;
  assign in_bits[1].exceptionVec[15] = io_in_1_bits_exceptionVec_15;
  assign in_bits[1].exceptionVec[16] = io_in_1_bits_exceptionVec_16;
  assign in_bits[1].exceptionVec[17] = io_in_1_bits_exceptionVec_17;
  assign in_bits[1].exceptionVec[18] = io_in_1_bits_exceptionVec_18;
  assign in_bits[1].exceptionVec[19] = io_in_1_bits_exceptionVec_19;
  assign in_bits[1].exceptionVec[20] = io_in_1_bits_exceptionVec_20;
  assign in_bits[1].exceptionVec[21] = io_in_1_bits_exceptionVec_21;
  assign in_bits[1].exceptionVec[23] = io_in_1_bits_exceptionVec_23;
  assign in_bits[1].isFetchMalAddr = io_in_1_bits_isFetchMalAddr;
  assign in_bits[1].trigger = io_in_1_bits_trigger;
  assign in_bits[1].preDecodeInfo_valid = io_in_1_bits_preDecodeInfo_valid;
  assign in_bits[1].preDecodeInfo_isRVC = io_in_1_bits_preDecodeInfo_isRVC;
  assign in_bits[1].preDecodeInfo_brType = io_in_1_bits_preDecodeInfo_brType;
  assign in_bits[1].preDecodeInfo_isCall = io_in_1_bits_preDecodeInfo_isCall;
  assign in_bits[1].preDecodeInfo_isRet = io_in_1_bits_preDecodeInfo_isRet;
  assign in_bits[1].pred_taken = io_in_1_bits_pred_taken;
  assign in_bits[1].crossPageIPFFix = io_in_1_bits_crossPageIPFFix;
  assign in_bits[1].ftqPtr_flag = io_in_1_bits_ftqPtr_flag;
  assign in_bits[1].ftqPtr_value = io_in_1_bits_ftqPtr_value;
  assign in_bits[1].ftqOffset = io_in_1_bits_ftqOffset;
  assign in_bits[1].isLastInFtqEntry = io_in_1_bits_isLastInFtqEntry;
  assign in_bits[1].debug_seqNum_seqNum = io_in_1_bits_debug_seqNum_seqNum;
  assign in_bits[1].debug_seqNum_uopIdx = io_in_1_bits_debug_seqNum_uopIdx;
  assign in_bits[1].satpFlushFirstFetchFault = io_in_1_bits_satpFlushFirstFetchFault;
  assign in_valid[2] = io_in_2_valid;
  assign in_bits[2].instr = io_in_2_bits_instr;
  assign in_bits[2].pc = io_in_2_bits_pc;
  assign in_bits[2].foldpc = io_in_2_bits_foldpc;
  assign in_bits[2].exceptionVec[0] = io_in_2_bits_exceptionVec_0;
  assign in_bits[2].exceptionVec[1] = io_in_2_bits_exceptionVec_1;
  assign in_bits[2].exceptionVec[2] = io_in_2_bits_exceptionVec_2;
  assign in_bits[2].exceptionVec[4] = io_in_2_bits_exceptionVec_4;
  assign in_bits[2].exceptionVec[5] = io_in_2_bits_exceptionVec_5;
  assign in_bits[2].exceptionVec[6] = io_in_2_bits_exceptionVec_6;
  assign in_bits[2].exceptionVec[7] = io_in_2_bits_exceptionVec_7;
  assign in_bits[2].exceptionVec[8] = io_in_2_bits_exceptionVec_8;
  assign in_bits[2].exceptionVec[9] = io_in_2_bits_exceptionVec_9;
  assign in_bits[2].exceptionVec[10] = io_in_2_bits_exceptionVec_10;
  assign in_bits[2].exceptionVec[11] = io_in_2_bits_exceptionVec_11;
  assign in_bits[2].exceptionVec[12] = io_in_2_bits_exceptionVec_12;
  assign in_bits[2].exceptionVec[13] = io_in_2_bits_exceptionVec_13;
  assign in_bits[2].exceptionVec[14] = io_in_2_bits_exceptionVec_14;
  assign in_bits[2].exceptionVec[15] = io_in_2_bits_exceptionVec_15;
  assign in_bits[2].exceptionVec[16] = io_in_2_bits_exceptionVec_16;
  assign in_bits[2].exceptionVec[17] = io_in_2_bits_exceptionVec_17;
  assign in_bits[2].exceptionVec[18] = io_in_2_bits_exceptionVec_18;
  assign in_bits[2].exceptionVec[19] = io_in_2_bits_exceptionVec_19;
  assign in_bits[2].exceptionVec[20] = io_in_2_bits_exceptionVec_20;
  assign in_bits[2].exceptionVec[21] = io_in_2_bits_exceptionVec_21;
  assign in_bits[2].exceptionVec[23] = io_in_2_bits_exceptionVec_23;
  assign in_bits[2].isFetchMalAddr = io_in_2_bits_isFetchMalAddr;
  assign in_bits[2].trigger = io_in_2_bits_trigger;
  assign in_bits[2].preDecodeInfo_valid = io_in_2_bits_preDecodeInfo_valid;
  assign in_bits[2].preDecodeInfo_isRVC = io_in_2_bits_preDecodeInfo_isRVC;
  assign in_bits[2].preDecodeInfo_brType = io_in_2_bits_preDecodeInfo_brType;
  assign in_bits[2].preDecodeInfo_isCall = io_in_2_bits_preDecodeInfo_isCall;
  assign in_bits[2].preDecodeInfo_isRet = io_in_2_bits_preDecodeInfo_isRet;
  assign in_bits[2].pred_taken = io_in_2_bits_pred_taken;
  assign in_bits[2].crossPageIPFFix = io_in_2_bits_crossPageIPFFix;
  assign in_bits[2].ftqPtr_flag = io_in_2_bits_ftqPtr_flag;
  assign in_bits[2].ftqPtr_value = io_in_2_bits_ftqPtr_value;
  assign in_bits[2].ftqOffset = io_in_2_bits_ftqOffset;
  assign in_bits[2].isLastInFtqEntry = io_in_2_bits_isLastInFtqEntry;
  assign in_bits[2].debug_seqNum_seqNum = io_in_2_bits_debug_seqNum_seqNum;
  assign in_bits[2].debug_seqNum_uopIdx = io_in_2_bits_debug_seqNum_uopIdx;
  assign in_bits[2].satpFlushFirstFetchFault = io_in_2_bits_satpFlushFirstFetchFault;
  assign in_valid[3] = io_in_3_valid;
  assign in_bits[3].instr = io_in_3_bits_instr;
  assign in_bits[3].pc = io_in_3_bits_pc;
  assign in_bits[3].foldpc = io_in_3_bits_foldpc;
  assign in_bits[3].exceptionVec[0] = io_in_3_bits_exceptionVec_0;
  assign in_bits[3].exceptionVec[1] = io_in_3_bits_exceptionVec_1;
  assign in_bits[3].exceptionVec[2] = io_in_3_bits_exceptionVec_2;
  assign in_bits[3].exceptionVec[4] = io_in_3_bits_exceptionVec_4;
  assign in_bits[3].exceptionVec[5] = io_in_3_bits_exceptionVec_5;
  assign in_bits[3].exceptionVec[6] = io_in_3_bits_exceptionVec_6;
  assign in_bits[3].exceptionVec[7] = io_in_3_bits_exceptionVec_7;
  assign in_bits[3].exceptionVec[8] = io_in_3_bits_exceptionVec_8;
  assign in_bits[3].exceptionVec[9] = io_in_3_bits_exceptionVec_9;
  assign in_bits[3].exceptionVec[10] = io_in_3_bits_exceptionVec_10;
  assign in_bits[3].exceptionVec[11] = io_in_3_bits_exceptionVec_11;
  assign in_bits[3].exceptionVec[12] = io_in_3_bits_exceptionVec_12;
  assign in_bits[3].exceptionVec[13] = io_in_3_bits_exceptionVec_13;
  assign in_bits[3].exceptionVec[14] = io_in_3_bits_exceptionVec_14;
  assign in_bits[3].exceptionVec[15] = io_in_3_bits_exceptionVec_15;
  assign in_bits[3].exceptionVec[16] = io_in_3_bits_exceptionVec_16;
  assign in_bits[3].exceptionVec[17] = io_in_3_bits_exceptionVec_17;
  assign in_bits[3].exceptionVec[18] = io_in_3_bits_exceptionVec_18;
  assign in_bits[3].exceptionVec[19] = io_in_3_bits_exceptionVec_19;
  assign in_bits[3].exceptionVec[20] = io_in_3_bits_exceptionVec_20;
  assign in_bits[3].exceptionVec[21] = io_in_3_bits_exceptionVec_21;
  assign in_bits[3].exceptionVec[23] = io_in_3_bits_exceptionVec_23;
  assign in_bits[3].isFetchMalAddr = io_in_3_bits_isFetchMalAddr;
  assign in_bits[3].trigger = io_in_3_bits_trigger;
  assign in_bits[3].preDecodeInfo_valid = io_in_3_bits_preDecodeInfo_valid;
  assign in_bits[3].preDecodeInfo_isRVC = io_in_3_bits_preDecodeInfo_isRVC;
  assign in_bits[3].preDecodeInfo_brType = io_in_3_bits_preDecodeInfo_brType;
  assign in_bits[3].preDecodeInfo_isCall = io_in_3_bits_preDecodeInfo_isCall;
  assign in_bits[3].preDecodeInfo_isRet = io_in_3_bits_preDecodeInfo_isRet;
  assign in_bits[3].pred_taken = io_in_3_bits_pred_taken;
  assign in_bits[3].crossPageIPFFix = io_in_3_bits_crossPageIPFFix;
  assign in_bits[3].ftqPtr_flag = io_in_3_bits_ftqPtr_flag;
  assign in_bits[3].ftqPtr_value = io_in_3_bits_ftqPtr_value;
  assign in_bits[3].ftqOffset = io_in_3_bits_ftqOffset;
  assign in_bits[3].isLastInFtqEntry = io_in_3_bits_isLastInFtqEntry;
  assign in_bits[3].debug_seqNum_seqNum = io_in_3_bits_debug_seqNum_seqNum;
  assign in_bits[3].debug_seqNum_uopIdx = io_in_3_bits_debug_seqNum_uopIdx;
  assign in_bits[3].satpFlushFirstFetchFault = io_in_3_bits_satpFlushFirstFetchFault;
  assign in_valid[4] = io_in_4_valid;
  assign in_bits[4].instr = io_in_4_bits_instr;
  assign in_bits[4].pc = io_in_4_bits_pc;
  assign in_bits[4].foldpc = io_in_4_bits_foldpc;
  assign in_bits[4].exceptionVec[0] = io_in_4_bits_exceptionVec_0;
  assign in_bits[4].exceptionVec[1] = io_in_4_bits_exceptionVec_1;
  assign in_bits[4].exceptionVec[2] = io_in_4_bits_exceptionVec_2;
  assign in_bits[4].exceptionVec[4] = io_in_4_bits_exceptionVec_4;
  assign in_bits[4].exceptionVec[5] = io_in_4_bits_exceptionVec_5;
  assign in_bits[4].exceptionVec[6] = io_in_4_bits_exceptionVec_6;
  assign in_bits[4].exceptionVec[7] = io_in_4_bits_exceptionVec_7;
  assign in_bits[4].exceptionVec[8] = io_in_4_bits_exceptionVec_8;
  assign in_bits[4].exceptionVec[9] = io_in_4_bits_exceptionVec_9;
  assign in_bits[4].exceptionVec[10] = io_in_4_bits_exceptionVec_10;
  assign in_bits[4].exceptionVec[11] = io_in_4_bits_exceptionVec_11;
  assign in_bits[4].exceptionVec[12] = io_in_4_bits_exceptionVec_12;
  assign in_bits[4].exceptionVec[13] = io_in_4_bits_exceptionVec_13;
  assign in_bits[4].exceptionVec[14] = io_in_4_bits_exceptionVec_14;
  assign in_bits[4].exceptionVec[15] = io_in_4_bits_exceptionVec_15;
  assign in_bits[4].exceptionVec[16] = io_in_4_bits_exceptionVec_16;
  assign in_bits[4].exceptionVec[17] = io_in_4_bits_exceptionVec_17;
  assign in_bits[4].exceptionVec[18] = io_in_4_bits_exceptionVec_18;
  assign in_bits[4].exceptionVec[19] = io_in_4_bits_exceptionVec_19;
  assign in_bits[4].exceptionVec[20] = io_in_4_bits_exceptionVec_20;
  assign in_bits[4].exceptionVec[21] = io_in_4_bits_exceptionVec_21;
  assign in_bits[4].exceptionVec[23] = io_in_4_bits_exceptionVec_23;
  assign in_bits[4].isFetchMalAddr = io_in_4_bits_isFetchMalAddr;
  assign in_bits[4].trigger = io_in_4_bits_trigger;
  assign in_bits[4].preDecodeInfo_valid = io_in_4_bits_preDecodeInfo_valid;
  assign in_bits[4].preDecodeInfo_isRVC = io_in_4_bits_preDecodeInfo_isRVC;
  assign in_bits[4].preDecodeInfo_brType = io_in_4_bits_preDecodeInfo_brType;
  assign in_bits[4].preDecodeInfo_isCall = io_in_4_bits_preDecodeInfo_isCall;
  assign in_bits[4].preDecodeInfo_isRet = io_in_4_bits_preDecodeInfo_isRet;
  assign in_bits[4].pred_taken = io_in_4_bits_pred_taken;
  assign in_bits[4].crossPageIPFFix = io_in_4_bits_crossPageIPFFix;
  assign in_bits[4].ftqPtr_flag = io_in_4_bits_ftqPtr_flag;
  assign in_bits[4].ftqPtr_value = io_in_4_bits_ftqPtr_value;
  assign in_bits[4].ftqOffset = io_in_4_bits_ftqOffset;
  assign in_bits[4].isLastInFtqEntry = io_in_4_bits_isLastInFtqEntry;
  assign in_bits[4].debug_seqNum_seqNum = io_in_4_bits_debug_seqNum_seqNum;
  assign in_bits[4].debug_seqNum_uopIdx = io_in_4_bits_debug_seqNum_uopIdx;
  assign in_bits[4].satpFlushFirstFetchFault = io_in_4_bits_satpFlushFirstFetchFault;
  assign in_valid[5] = io_in_5_valid;
  assign in_bits[5].instr = io_in_5_bits_instr;
  assign in_bits[5].pc = io_in_5_bits_pc;
  assign in_bits[5].foldpc = io_in_5_bits_foldpc;
  assign in_bits[5].exceptionVec[0] = io_in_5_bits_exceptionVec_0;
  assign in_bits[5].exceptionVec[1] = io_in_5_bits_exceptionVec_1;
  assign in_bits[5].exceptionVec[2] = io_in_5_bits_exceptionVec_2;
  assign in_bits[5].exceptionVec[4] = io_in_5_bits_exceptionVec_4;
  assign in_bits[5].exceptionVec[5] = io_in_5_bits_exceptionVec_5;
  assign in_bits[5].exceptionVec[6] = io_in_5_bits_exceptionVec_6;
  assign in_bits[5].exceptionVec[7] = io_in_5_bits_exceptionVec_7;
  assign in_bits[5].exceptionVec[8] = io_in_5_bits_exceptionVec_8;
  assign in_bits[5].exceptionVec[9] = io_in_5_bits_exceptionVec_9;
  assign in_bits[5].exceptionVec[10] = io_in_5_bits_exceptionVec_10;
  assign in_bits[5].exceptionVec[11] = io_in_5_bits_exceptionVec_11;
  assign in_bits[5].exceptionVec[12] = io_in_5_bits_exceptionVec_12;
  assign in_bits[5].exceptionVec[13] = io_in_5_bits_exceptionVec_13;
  assign in_bits[5].exceptionVec[14] = io_in_5_bits_exceptionVec_14;
  assign in_bits[5].exceptionVec[15] = io_in_5_bits_exceptionVec_15;
  assign in_bits[5].exceptionVec[16] = io_in_5_bits_exceptionVec_16;
  assign in_bits[5].exceptionVec[17] = io_in_5_bits_exceptionVec_17;
  assign in_bits[5].exceptionVec[18] = io_in_5_bits_exceptionVec_18;
  assign in_bits[5].exceptionVec[19] = io_in_5_bits_exceptionVec_19;
  assign in_bits[5].exceptionVec[20] = io_in_5_bits_exceptionVec_20;
  assign in_bits[5].exceptionVec[21] = io_in_5_bits_exceptionVec_21;
  assign in_bits[5].exceptionVec[23] = io_in_5_bits_exceptionVec_23;
  assign in_bits[5].isFetchMalAddr = io_in_5_bits_isFetchMalAddr;
  assign in_bits[5].trigger = io_in_5_bits_trigger;
  assign in_bits[5].preDecodeInfo_valid = io_in_5_bits_preDecodeInfo_valid;
  assign in_bits[5].preDecodeInfo_isRVC = io_in_5_bits_preDecodeInfo_isRVC;
  assign in_bits[5].preDecodeInfo_brType = io_in_5_bits_preDecodeInfo_brType;
  assign in_bits[5].preDecodeInfo_isCall = io_in_5_bits_preDecodeInfo_isCall;
  assign in_bits[5].preDecodeInfo_isRet = io_in_5_bits_preDecodeInfo_isRet;
  assign in_bits[5].pred_taken = io_in_5_bits_pred_taken;
  assign in_bits[5].crossPageIPFFix = io_in_5_bits_crossPageIPFFix;
  assign in_bits[5].ftqPtr_flag = io_in_5_bits_ftqPtr_flag;
  assign in_bits[5].ftqPtr_value = io_in_5_bits_ftqPtr_value;
  assign in_bits[5].ftqOffset = io_in_5_bits_ftqOffset;
  assign in_bits[5].isLastInFtqEntry = io_in_5_bits_isLastInFtqEntry;
  assign in_bits[5].debug_seqNum_seqNum = io_in_5_bits_debug_seqNum_seqNum;
  assign in_bits[5].debug_seqNum_uopIdx = io_in_5_bits_debug_seqNum_uopIdx;
  assign in_bits[5].satpFlushFirstFetchFault = io_in_5_bits_satpFlushFirstFetchFault;
  assign out_ready[0] = io_out_0_ready;
  assign out_ready[1] = io_out_1_ready;
  assign out_ready[2] = io_out_2_ready;
  assign out_ready[3] = io_out_3_ready;
  assign out_ready[4] = io_out_4_ready;
  assign out_ready[5] = io_out_5_ready;
  assign csrCtrl_singlestep = io_csrCtrl_singlestep;
  assign fromCSR.illegalInst_sfenceVMA = io_fromCSR_illegalInst_sfenceVMA;
  assign fromCSR.illegalInst_sfencePart = io_fromCSR_illegalInst_sfencePart;
  assign fromCSR.illegalInst_hfenceGVMA = io_fromCSR_illegalInst_hfenceGVMA;
  assign fromCSR.illegalInst_hfenceVVMA = io_fromCSR_illegalInst_hfenceVVMA;
  assign fromCSR.illegalInst_hlsv = io_fromCSR_illegalInst_hlsv;
  assign fromCSR.illegalInst_fsIsOff = io_fromCSR_illegalInst_fsIsOff;
  assign fromCSR.illegalInst_vsIsOff = io_fromCSR_illegalInst_vsIsOff;
  assign fromCSR.illegalInst_wfi = io_fromCSR_illegalInst_wfi;
  assign fromCSR.illegalInst_wrs_nto = io_fromCSR_illegalInst_wrs_nto;
  assign fromCSR.illegalInst_frm = io_fromCSR_illegalInst_frm;
  assign fromCSR.illegalInst_cboZ = io_fromCSR_illegalInst_cboZ;
  assign fromCSR.illegalInst_cboCF = io_fromCSR_illegalInst_cboCF;
  assign fromCSR.illegalInst_cboI = io_fromCSR_illegalInst_cboI;
  assign fromCSR.virtualInst_sfenceVMA = io_fromCSR_virtualInst_sfenceVMA;
  assign fromCSR.virtualInst_sfencePart = io_fromCSR_virtualInst_sfencePart;
  assign fromCSR.virtualInst_hfence = io_fromCSR_virtualInst_hfence;
  assign fromCSR.virtualInst_hlsv = io_fromCSR_virtualInst_hlsv;
  assign fromCSR.virtualInst_wfi = io_fromCSR_virtualInst_wfi;
  assign fromCSR.virtualInst_wrs_nto = io_fromCSR_virtualInst_wrs_nto;
  assign fromCSR.virtualInst_cboZ = io_fromCSR_virtualInst_cboZ;
  assign fromCSR.virtualInst_cboCF = io_fromCSR_virtualInst_cboCF;
  assign fromCSR.virtualInst_cboI = io_fromCSR_virtualInst_cboI;
  assign fromCSR.special_cboI2F = io_fromCSR_special_cboI2F;
  assign fusion[0] = io_fusion_0;
  assign fusion[1] = io_fusion_1;
  assign fusion[2] = io_fusion_2;
  assign fusion[3] = io_fusion_3;
  assign fusion[4] = io_fusion_4;
  assign backendCanAccept = io_backendCanAccept;
  assign fromRob.isResumeVType = io_fromRob_isResumeVType;
  assign fromRob.walkToArchVType = io_fromRob_walkToArchVType;
  assign fromRob.commitVType_valid = io_fromRob_commitVType_vtype_valid;
  assign fromRob.commitVType.illegal = io_fromRob_commitVType_vtype_bits_illegal;
  assign fromRob.commitVType.vma = io_fromRob_commitVType_vtype_bits_vma;
  assign fromRob.commitVType.vta = io_fromRob_commitVType_vtype_bits_vta;
  assign fromRob.commitVType.vsew = io_fromRob_commitVType_vtype_bits_vsew;
  assign fromRob.commitVType.vlmul = io_fromRob_commitVType_vtype_bits_vlmul;
  assign fromRob.commitVType_hasVsetvl = io_fromRob_commitVType_hasVsetvl;
  assign fromRob.walkVType_valid = io_fromRob_walkVType_valid;
  assign fromRob.walkVType.illegal = io_fromRob_walkVType_bits_illegal;
  assign fromRob.walkVType.vma = io_fromRob_walkVType_bits_vma;
  assign fromRob.walkVType.vta = io_fromRob_walkVType_bits_vta;
  assign fromRob.walkVType.vsew = io_fromRob_walkVType_bits_vsew;
  assign fromRob.walkVType.vlmul = io_fromRob_walkVType_bits_vlmul;
  assign stallReason_in_reason[0] = io_stallReason_in_reason_0;
  assign stallReason_in_reason[1] = io_stallReason_in_reason_1;
  assign stallReason_in_reason[2] = io_stallReason_in_reason_2;
  assign stallReason_in_reason[3] = io_stallReason_in_reason_3;
  assign stallReason_in_reason[4] = io_stallReason_in_reason_4;
  assign stallReason_in_reason[5] = io_stallReason_in_reason_5;
  assign stallReason_out_backReason_valid = io_stallReason_out_backReason_valid;
  assign stallReason_out_backReason_bits = io_stallReason_out_backReason_bits;
  assign vsetvlVType.illegal = io_vsetvlVType_illegal;
  assign vsetvlVType.vma = io_vsetvlVType_vma;
  assign vsetvlVType.vta = io_vsetvlVType_vta;
  assign vsetvlVType.vsew = io_vsetvlVType_vsew;
  assign vsetvlVType.vlmul = io_vsetvlVType_vlmul;
  assign vstart = io_vstart;

  xs_DecodeStage_core u_core (
    // golden 没有 io_canAccept 端口（CtrlBlock 不读，firtool 删掉了），核的 canAccept 悬空
    .clock(clock), .reset(reset), .redirect(io_redirect), .canAccept(),
    .in_valid(in_valid), .in_bits(in_bits), .in_ready(in_ready),
    .out_valid(out_valid), .out_bits(out_bits), .out_ready(out_ready),
    .intRat_addr(intRat_addr), .intRat_hold(intRat_hold),
    .fpRat_addr(fpRat_addr), .fpRat_hold(fpRat_hold),
    .vecRat_addr(vecRat_addr), .vecRat_hold(vecRat_hold),
    .v0Rat_hold(v0Rat_hold), .vlRat_hold(vlRat_hold),
    .csrCtrl_singlestep(io_csrCtrl_singlestep), .fromCSR(fromCSR),
    .fusion(fusion), .backendCanAccept(io_backendCanAccept), .fromRob(fromRob),
    .stallReason_in_reason(stallReason_in_reason),
    .stallReason_out_backReason_valid(stallReason_out_backReason_valid),
    .stallReason_out_backReason_bits(stallReason_out_backReason_bits),
    .stallReason_in_backReason_valid(stallReason_in_backReason_valid),
    .stallReason_in_backReason_bits(stallReason_in_backReason_bits),
    .stallReason_out_reason(stallReason_out_reason),
    .vsetvlVType(vsetvlVType), .vstart(io_vstart),
    .trapInstInfo_valid(trapInstInfo_valid), .trapInstInfo(trapInstInfo),
    .perf_value(perf_value)
  );

  // ---- 输出拆包 ----
  assign io_in_0_ready = in_ready[0];
  assign io_in_1_ready = in_ready[1];
  assign io_in_2_ready = in_ready[2];
  assign io_in_3_ready = in_ready[3];
  assign io_in_4_ready = in_ready[4];
  assign io_in_5_ready = in_ready[5];
  assign io_out_0_valid = out_valid[0];
  assign io_out_0_bits_instr = out_bits[0].instr;
  assign io_out_0_bits_pc = out_bits[0].pc;
  assign io_out_0_bits_foldpc = out_bits[0].foldpc;
  assign io_out_0_bits_exceptionVec_0 = out_bits[0].exceptionVec[0];
  assign io_out_0_bits_exceptionVec_1 = out_bits[0].exceptionVec[1];
  assign io_out_0_bits_exceptionVec_2 = out_bits[0].exceptionVec[2];
  assign io_out_0_bits_exceptionVec_3 = out_bits[0].exceptionVec[3];
  assign io_out_0_bits_exceptionVec_4 = out_bits[0].exceptionVec[4];
  assign io_out_0_bits_exceptionVec_5 = out_bits[0].exceptionVec[5];
  assign io_out_0_bits_exceptionVec_6 = out_bits[0].exceptionVec[6];
  assign io_out_0_bits_exceptionVec_7 = out_bits[0].exceptionVec[7];
  assign io_out_0_bits_exceptionVec_8 = out_bits[0].exceptionVec[8];
  assign io_out_0_bits_exceptionVec_9 = out_bits[0].exceptionVec[9];
  assign io_out_0_bits_exceptionVec_10 = out_bits[0].exceptionVec[10];
  assign io_out_0_bits_exceptionVec_11 = out_bits[0].exceptionVec[11];
  assign io_out_0_bits_exceptionVec_12 = out_bits[0].exceptionVec[12];
  assign io_out_0_bits_exceptionVec_13 = out_bits[0].exceptionVec[13];
  assign io_out_0_bits_exceptionVec_14 = out_bits[0].exceptionVec[14];
  assign io_out_0_bits_exceptionVec_15 = out_bits[0].exceptionVec[15];
  assign io_out_0_bits_exceptionVec_16 = out_bits[0].exceptionVec[16];
  assign io_out_0_bits_exceptionVec_17 = out_bits[0].exceptionVec[17];
  assign io_out_0_bits_exceptionVec_18 = out_bits[0].exceptionVec[18];
  assign io_out_0_bits_exceptionVec_19 = out_bits[0].exceptionVec[19];
  assign io_out_0_bits_exceptionVec_20 = out_bits[0].exceptionVec[20];
  assign io_out_0_bits_exceptionVec_21 = out_bits[0].exceptionVec[21];
  assign io_out_0_bits_exceptionVec_22 = out_bits[0].exceptionVec[22];
  assign io_out_0_bits_exceptionVec_23 = out_bits[0].exceptionVec[23];
  assign io_out_0_bits_isFetchMalAddr = out_bits[0].isFetchMalAddr;
  assign io_out_0_bits_trigger = out_bits[0].trigger;
  assign io_out_0_bits_preDecodeInfo_valid = out_bits[0].preDecodeInfo_valid;
  assign io_out_0_bits_preDecodeInfo_isRVC = out_bits[0].preDecodeInfo_isRVC;
  assign io_out_0_bits_preDecodeInfo_brType = out_bits[0].preDecodeInfo_brType;
  assign io_out_0_bits_preDecodeInfo_isCall = out_bits[0].preDecodeInfo_isCall;
  assign io_out_0_bits_preDecodeInfo_isRet = out_bits[0].preDecodeInfo_isRet;
  assign io_out_0_bits_pred_taken = out_bits[0].pred_taken;
  assign io_out_0_bits_crossPageIPFFix = out_bits[0].crossPageIPFFix;
  assign io_out_0_bits_ftqPtr_flag = out_bits[0].ftqPtr_flag;
  assign io_out_0_bits_ftqPtr_value = out_bits[0].ftqPtr_value;
  assign io_out_0_bits_ftqOffset = out_bits[0].ftqOffset;
  assign io_out_0_bits_satpFlushFirstFetchFault = out_bits[0].satpFlushFirstFetchFault;
  assign io_out_0_bits_srcType_0 = out_bits[0].srcType[0];
  assign io_out_0_bits_srcType_1 = out_bits[0].srcType[1];
  assign io_out_0_bits_srcType_2 = out_bits[0].srcType[2];
  assign io_out_0_bits_srcType_3 = out_bits[0].srcType[3];
  assign io_out_0_bits_srcType_4 = out_bits[0].srcType[4];
  assign io_out_0_bits_lsrc_0 = out_bits[0].lsrc[0];
  assign io_out_0_bits_lsrc_1 = out_bits[0].lsrc[1];
  assign io_out_0_bits_lsrc_2 = out_bits[0].lsrc[2];
  assign io_out_0_bits_ldest = out_bits[0].ldest;
  assign io_out_0_bits_fuType = out_bits[0].fuType;
  assign io_out_0_bits_fuOpType = out_bits[0].fuOpType;
  assign io_out_0_bits_rfWen = out_bits[0].rfWen;
  assign io_out_0_bits_fpWen = out_bits[0].fpWen;
  assign io_out_0_bits_vecWen = out_bits[0].vecWen;
  assign io_out_0_bits_v0Wen = out_bits[0].v0Wen;
  assign io_out_0_bits_vlWen = out_bits[0].vlWen;
  assign io_out_0_bits_isXSTrap = out_bits[0].isXSTrap;
  assign io_out_0_bits_waitForward = out_bits[0].waitForward;
  assign io_out_0_bits_blockBackward = out_bits[0].blockBackward;
  assign io_out_0_bits_flushPipe = out_bits[0].flushPipe;
  assign io_out_0_bits_canRobCompress = out_bits[0].canRobCompress;
  assign io_out_0_bits_selImm = out_bits[0].selImm;
  assign io_out_0_bits_imm = out_bits[0].imm;
  assign io_out_0_bits_fpu_typeTagOut = out_bits[0].fpu_typeTagOut;
  assign io_out_0_bits_fpu_wflags = out_bits[0].fpu_wflags;
  assign io_out_0_bits_fpu_typ = out_bits[0].fpu_typ;
  assign io_out_0_bits_fpu_fmt = out_bits[0].fpu_fmt;
  assign io_out_0_bits_fpu_rm = out_bits[0].fpu_rm;
  assign io_out_0_bits_vpu_vill = out_bits[0].vpu_vill;
  assign io_out_0_bits_vpu_vma = out_bits[0].vpu_vma;
  assign io_out_0_bits_vpu_vta = out_bits[0].vpu_vta;
  assign io_out_0_bits_vpu_vsew = out_bits[0].vpu_vsew;
  assign io_out_0_bits_vpu_vlmul = out_bits[0].vpu_vlmul;
  assign io_out_0_bits_vpu_specVill = out_bits[0].vpu_specVill;
  assign io_out_0_bits_vpu_specVma = out_bits[0].vpu_specVma;
  assign io_out_0_bits_vpu_specVta = out_bits[0].vpu_specVta;
  assign io_out_0_bits_vpu_specVsew = out_bits[0].vpu_specVsew;
  assign io_out_0_bits_vpu_specVlmul = out_bits[0].vpu_specVlmul;
  assign io_out_0_bits_vpu_vm = out_bits[0].vpu_vm;
  assign io_out_0_bits_vpu_vstart = out_bits[0].vpu_vstart;
  assign io_out_0_bits_vpu_fpu_isFoldTo1_2 = out_bits[0].vpu_fpu_isFoldTo1_2;
  assign io_out_0_bits_vpu_fpu_isFoldTo1_4 = out_bits[0].vpu_fpu_isFoldTo1_4;
  assign io_out_0_bits_vpu_fpu_isFoldTo1_8 = out_bits[0].vpu_fpu_isFoldTo1_8;
  assign io_out_0_bits_vpu_nf = out_bits[0].vpu_nf;
  assign io_out_0_bits_vpu_veew = out_bits[0].vpu_veew;
  assign io_out_0_bits_vpu_isReverse = out_bits[0].vpu_isReverse;
  assign io_out_0_bits_vpu_isExt = out_bits[0].vpu_isExt;
  assign io_out_0_bits_vpu_isNarrow = out_bits[0].vpu_isNarrow;
  assign io_out_0_bits_vpu_isDstMask = out_bits[0].vpu_isDstMask;
  assign io_out_0_bits_vpu_isOpMask = out_bits[0].vpu_isOpMask;
  assign io_out_0_bits_vpu_isDependOldVd = out_bits[0].vpu_isDependOldVd;
  assign io_out_0_bits_vpu_isWritePartVd = out_bits[0].vpu_isWritePartVd;
  assign io_out_0_bits_vpu_isVleff = out_bits[0].vpu_isVleff;
  assign io_out_0_bits_vlsInstr = out_bits[0].vlsInstr;
  assign io_out_0_bits_wfflags = out_bits[0].wfflags;
  assign io_out_0_bits_isMove = out_bits[0].isMove;
  assign io_out_0_bits_uopIdx = out_bits[0].uopIdx;
  assign io_out_0_bits_uopSplitType = out_bits[0].uopSplitType;
  assign io_out_0_bits_isVset = out_bits[0].isVset;
  assign io_out_0_bits_firstUop = out_bits[0].firstUop;
  assign io_out_0_bits_lastUop = out_bits[0].lastUop;
  assign io_out_0_bits_numUops = out_bits[0].numUops;
  assign io_out_0_bits_numWB = out_bits[0].numWB;
  assign io_out_0_bits_commitType = out_bits[0].commitType;
  assign io_out_0_bits_debug_fuType = out_bits[0].debug_fuType;
  assign io_out_0_bits_debug_seqNum_seqNum = out_bits[0].debug_seqNum_seqNum;
  assign io_out_0_bits_debug_seqNum_uopIdx = out_bits[0].debug_seqNum_uopIdx;
  assign io_out_1_valid = out_valid[1];
  assign io_out_1_bits_instr = out_bits[1].instr;
  assign io_out_1_bits_pc = out_bits[1].pc;
  assign io_out_1_bits_foldpc = out_bits[1].foldpc;
  assign io_out_1_bits_exceptionVec_0 = out_bits[1].exceptionVec[0];
  assign io_out_1_bits_exceptionVec_1 = out_bits[1].exceptionVec[1];
  assign io_out_1_bits_exceptionVec_2 = out_bits[1].exceptionVec[2];
  assign io_out_1_bits_exceptionVec_3 = out_bits[1].exceptionVec[3];
  assign io_out_1_bits_exceptionVec_4 = out_bits[1].exceptionVec[4];
  assign io_out_1_bits_exceptionVec_5 = out_bits[1].exceptionVec[5];
  assign io_out_1_bits_exceptionVec_6 = out_bits[1].exceptionVec[6];
  assign io_out_1_bits_exceptionVec_7 = out_bits[1].exceptionVec[7];
  assign io_out_1_bits_exceptionVec_8 = out_bits[1].exceptionVec[8];
  assign io_out_1_bits_exceptionVec_9 = out_bits[1].exceptionVec[9];
  assign io_out_1_bits_exceptionVec_10 = out_bits[1].exceptionVec[10];
  assign io_out_1_bits_exceptionVec_11 = out_bits[1].exceptionVec[11];
  assign io_out_1_bits_exceptionVec_12 = out_bits[1].exceptionVec[12];
  assign io_out_1_bits_exceptionVec_13 = out_bits[1].exceptionVec[13];
  assign io_out_1_bits_exceptionVec_14 = out_bits[1].exceptionVec[14];
  assign io_out_1_bits_exceptionVec_15 = out_bits[1].exceptionVec[15];
  assign io_out_1_bits_exceptionVec_16 = out_bits[1].exceptionVec[16];
  assign io_out_1_bits_exceptionVec_17 = out_bits[1].exceptionVec[17];
  assign io_out_1_bits_exceptionVec_18 = out_bits[1].exceptionVec[18];
  assign io_out_1_bits_exceptionVec_19 = out_bits[1].exceptionVec[19];
  assign io_out_1_bits_exceptionVec_20 = out_bits[1].exceptionVec[20];
  assign io_out_1_bits_exceptionVec_21 = out_bits[1].exceptionVec[21];
  assign io_out_1_bits_exceptionVec_22 = out_bits[1].exceptionVec[22];
  assign io_out_1_bits_exceptionVec_23 = out_bits[1].exceptionVec[23];
  assign io_out_1_bits_isFetchMalAddr = out_bits[1].isFetchMalAddr;
  assign io_out_1_bits_trigger = out_bits[1].trigger;
  assign io_out_1_bits_preDecodeInfo_valid = out_bits[1].preDecodeInfo_valid;
  assign io_out_1_bits_preDecodeInfo_isRVC = out_bits[1].preDecodeInfo_isRVC;
  assign io_out_1_bits_preDecodeInfo_brType = out_bits[1].preDecodeInfo_brType;
  assign io_out_1_bits_preDecodeInfo_isCall = out_bits[1].preDecodeInfo_isCall;
  assign io_out_1_bits_preDecodeInfo_isRet = out_bits[1].preDecodeInfo_isRet;
  assign io_out_1_bits_pred_taken = out_bits[1].pred_taken;
  assign io_out_1_bits_crossPageIPFFix = out_bits[1].crossPageIPFFix;
  assign io_out_1_bits_ftqPtr_flag = out_bits[1].ftqPtr_flag;
  assign io_out_1_bits_ftqPtr_value = out_bits[1].ftqPtr_value;
  assign io_out_1_bits_ftqOffset = out_bits[1].ftqOffset;
  assign io_out_1_bits_satpFlushFirstFetchFault = out_bits[1].satpFlushFirstFetchFault;
  assign io_out_1_bits_srcType_0 = out_bits[1].srcType[0];
  assign io_out_1_bits_srcType_1 = out_bits[1].srcType[1];
  assign io_out_1_bits_srcType_2 = out_bits[1].srcType[2];
  assign io_out_1_bits_srcType_3 = out_bits[1].srcType[3];
  assign io_out_1_bits_srcType_4 = out_bits[1].srcType[4];
  assign io_out_1_bits_lsrc_0 = out_bits[1].lsrc[0];
  assign io_out_1_bits_lsrc_1 = out_bits[1].lsrc[1];
  assign io_out_1_bits_lsrc_2 = out_bits[1].lsrc[2];
  assign io_out_1_bits_ldest = out_bits[1].ldest;
  assign io_out_1_bits_fuType = out_bits[1].fuType;
  assign io_out_1_bits_fuOpType = out_bits[1].fuOpType;
  assign io_out_1_bits_rfWen = out_bits[1].rfWen;
  assign io_out_1_bits_fpWen = out_bits[1].fpWen;
  assign io_out_1_bits_vecWen = out_bits[1].vecWen;
  assign io_out_1_bits_v0Wen = out_bits[1].v0Wen;
  assign io_out_1_bits_vlWen = out_bits[1].vlWen;
  assign io_out_1_bits_isXSTrap = out_bits[1].isXSTrap;
  assign io_out_1_bits_waitForward = out_bits[1].waitForward;
  assign io_out_1_bits_blockBackward = out_bits[1].blockBackward;
  assign io_out_1_bits_flushPipe = out_bits[1].flushPipe;
  assign io_out_1_bits_canRobCompress = out_bits[1].canRobCompress;
  assign io_out_1_bits_selImm = out_bits[1].selImm;
  assign io_out_1_bits_imm = out_bits[1].imm;
  assign io_out_1_bits_fpu_typeTagOut = out_bits[1].fpu_typeTagOut;
  assign io_out_1_bits_fpu_wflags = out_bits[1].fpu_wflags;
  assign io_out_1_bits_fpu_typ = out_bits[1].fpu_typ;
  assign io_out_1_bits_fpu_fmt = out_bits[1].fpu_fmt;
  assign io_out_1_bits_fpu_rm = out_bits[1].fpu_rm;
  assign io_out_1_bits_vpu_vill = out_bits[1].vpu_vill;
  assign io_out_1_bits_vpu_vma = out_bits[1].vpu_vma;
  assign io_out_1_bits_vpu_vta = out_bits[1].vpu_vta;
  assign io_out_1_bits_vpu_vsew = out_bits[1].vpu_vsew;
  assign io_out_1_bits_vpu_vlmul = out_bits[1].vpu_vlmul;
  assign io_out_1_bits_vpu_specVill = out_bits[1].vpu_specVill;
  assign io_out_1_bits_vpu_specVma = out_bits[1].vpu_specVma;
  assign io_out_1_bits_vpu_specVta = out_bits[1].vpu_specVta;
  assign io_out_1_bits_vpu_specVsew = out_bits[1].vpu_specVsew;
  assign io_out_1_bits_vpu_specVlmul = out_bits[1].vpu_specVlmul;
  assign io_out_1_bits_vpu_vm = out_bits[1].vpu_vm;
  assign io_out_1_bits_vpu_vstart = out_bits[1].vpu_vstart;
  assign io_out_1_bits_vpu_fpu_isFoldTo1_2 = out_bits[1].vpu_fpu_isFoldTo1_2;
  assign io_out_1_bits_vpu_fpu_isFoldTo1_4 = out_bits[1].vpu_fpu_isFoldTo1_4;
  assign io_out_1_bits_vpu_fpu_isFoldTo1_8 = out_bits[1].vpu_fpu_isFoldTo1_8;
  assign io_out_1_bits_vpu_nf = out_bits[1].vpu_nf;
  assign io_out_1_bits_vpu_veew = out_bits[1].vpu_veew;
  assign io_out_1_bits_vpu_isReverse = out_bits[1].vpu_isReverse;
  assign io_out_1_bits_vpu_isExt = out_bits[1].vpu_isExt;
  assign io_out_1_bits_vpu_isNarrow = out_bits[1].vpu_isNarrow;
  assign io_out_1_bits_vpu_isDstMask = out_bits[1].vpu_isDstMask;
  assign io_out_1_bits_vpu_isOpMask = out_bits[1].vpu_isOpMask;
  assign io_out_1_bits_vpu_isDependOldVd = out_bits[1].vpu_isDependOldVd;
  assign io_out_1_bits_vpu_isWritePartVd = out_bits[1].vpu_isWritePartVd;
  assign io_out_1_bits_vpu_isVleff = out_bits[1].vpu_isVleff;
  assign io_out_1_bits_vlsInstr = out_bits[1].vlsInstr;
  assign io_out_1_bits_wfflags = out_bits[1].wfflags;
  assign io_out_1_bits_isMove = out_bits[1].isMove;
  assign io_out_1_bits_uopIdx = out_bits[1].uopIdx;
  assign io_out_1_bits_uopSplitType = out_bits[1].uopSplitType;
  assign io_out_1_bits_isVset = out_bits[1].isVset;
  assign io_out_1_bits_firstUop = out_bits[1].firstUop;
  assign io_out_1_bits_lastUop = out_bits[1].lastUop;
  assign io_out_1_bits_numUops = out_bits[1].numUops;
  assign io_out_1_bits_numWB = out_bits[1].numWB;
  assign io_out_1_bits_commitType = out_bits[1].commitType;
  assign io_out_1_bits_debug_fuType = out_bits[1].debug_fuType;
  assign io_out_1_bits_debug_seqNum_seqNum = out_bits[1].debug_seqNum_seqNum;
  assign io_out_1_bits_debug_seqNum_uopIdx = out_bits[1].debug_seqNum_uopIdx;
  assign io_out_2_valid = out_valid[2];
  assign io_out_2_bits_instr = out_bits[2].instr;
  assign io_out_2_bits_pc = out_bits[2].pc;
  assign io_out_2_bits_foldpc = out_bits[2].foldpc;
  assign io_out_2_bits_exceptionVec_0 = out_bits[2].exceptionVec[0];
  assign io_out_2_bits_exceptionVec_1 = out_bits[2].exceptionVec[1];
  assign io_out_2_bits_exceptionVec_2 = out_bits[2].exceptionVec[2];
  assign io_out_2_bits_exceptionVec_3 = out_bits[2].exceptionVec[3];
  assign io_out_2_bits_exceptionVec_4 = out_bits[2].exceptionVec[4];
  assign io_out_2_bits_exceptionVec_5 = out_bits[2].exceptionVec[5];
  assign io_out_2_bits_exceptionVec_6 = out_bits[2].exceptionVec[6];
  assign io_out_2_bits_exceptionVec_7 = out_bits[2].exceptionVec[7];
  assign io_out_2_bits_exceptionVec_8 = out_bits[2].exceptionVec[8];
  assign io_out_2_bits_exceptionVec_9 = out_bits[2].exceptionVec[9];
  assign io_out_2_bits_exceptionVec_10 = out_bits[2].exceptionVec[10];
  assign io_out_2_bits_exceptionVec_11 = out_bits[2].exceptionVec[11];
  assign io_out_2_bits_exceptionVec_12 = out_bits[2].exceptionVec[12];
  assign io_out_2_bits_exceptionVec_13 = out_bits[2].exceptionVec[13];
  assign io_out_2_bits_exceptionVec_14 = out_bits[2].exceptionVec[14];
  assign io_out_2_bits_exceptionVec_15 = out_bits[2].exceptionVec[15];
  assign io_out_2_bits_exceptionVec_16 = out_bits[2].exceptionVec[16];
  assign io_out_2_bits_exceptionVec_17 = out_bits[2].exceptionVec[17];
  assign io_out_2_bits_exceptionVec_18 = out_bits[2].exceptionVec[18];
  assign io_out_2_bits_exceptionVec_19 = out_bits[2].exceptionVec[19];
  assign io_out_2_bits_exceptionVec_20 = out_bits[2].exceptionVec[20];
  assign io_out_2_bits_exceptionVec_21 = out_bits[2].exceptionVec[21];
  assign io_out_2_bits_exceptionVec_22 = out_bits[2].exceptionVec[22];
  assign io_out_2_bits_exceptionVec_23 = out_bits[2].exceptionVec[23];
  assign io_out_2_bits_isFetchMalAddr = out_bits[2].isFetchMalAddr;
  assign io_out_2_bits_trigger = out_bits[2].trigger;
  assign io_out_2_bits_preDecodeInfo_valid = out_bits[2].preDecodeInfo_valid;
  assign io_out_2_bits_preDecodeInfo_isRVC = out_bits[2].preDecodeInfo_isRVC;
  assign io_out_2_bits_preDecodeInfo_brType = out_bits[2].preDecodeInfo_brType;
  assign io_out_2_bits_preDecodeInfo_isCall = out_bits[2].preDecodeInfo_isCall;
  assign io_out_2_bits_preDecodeInfo_isRet = out_bits[2].preDecodeInfo_isRet;
  assign io_out_2_bits_pred_taken = out_bits[2].pred_taken;
  assign io_out_2_bits_crossPageIPFFix = out_bits[2].crossPageIPFFix;
  assign io_out_2_bits_ftqPtr_flag = out_bits[2].ftqPtr_flag;
  assign io_out_2_bits_ftqPtr_value = out_bits[2].ftqPtr_value;
  assign io_out_2_bits_ftqOffset = out_bits[2].ftqOffset;
  assign io_out_2_bits_satpFlushFirstFetchFault = out_bits[2].satpFlushFirstFetchFault;
  assign io_out_2_bits_srcType_0 = out_bits[2].srcType[0];
  assign io_out_2_bits_srcType_1 = out_bits[2].srcType[1];
  assign io_out_2_bits_srcType_2 = out_bits[2].srcType[2];
  assign io_out_2_bits_srcType_3 = out_bits[2].srcType[3];
  assign io_out_2_bits_srcType_4 = out_bits[2].srcType[4];
  assign io_out_2_bits_lsrc_0 = out_bits[2].lsrc[0];
  assign io_out_2_bits_lsrc_1 = out_bits[2].lsrc[1];
  assign io_out_2_bits_lsrc_2 = out_bits[2].lsrc[2];
  assign io_out_2_bits_ldest = out_bits[2].ldest;
  assign io_out_2_bits_fuType = out_bits[2].fuType;
  assign io_out_2_bits_fuOpType = out_bits[2].fuOpType;
  assign io_out_2_bits_rfWen = out_bits[2].rfWen;
  assign io_out_2_bits_fpWen = out_bits[2].fpWen;
  assign io_out_2_bits_vecWen = out_bits[2].vecWen;
  assign io_out_2_bits_v0Wen = out_bits[2].v0Wen;
  assign io_out_2_bits_vlWen = out_bits[2].vlWen;
  assign io_out_2_bits_isXSTrap = out_bits[2].isXSTrap;
  assign io_out_2_bits_waitForward = out_bits[2].waitForward;
  assign io_out_2_bits_blockBackward = out_bits[2].blockBackward;
  assign io_out_2_bits_flushPipe = out_bits[2].flushPipe;
  assign io_out_2_bits_canRobCompress = out_bits[2].canRobCompress;
  assign io_out_2_bits_selImm = out_bits[2].selImm;
  assign io_out_2_bits_imm = out_bits[2].imm;
  assign io_out_2_bits_fpu_typeTagOut = out_bits[2].fpu_typeTagOut;
  assign io_out_2_bits_fpu_wflags = out_bits[2].fpu_wflags;
  assign io_out_2_bits_fpu_typ = out_bits[2].fpu_typ;
  assign io_out_2_bits_fpu_fmt = out_bits[2].fpu_fmt;
  assign io_out_2_bits_fpu_rm = out_bits[2].fpu_rm;
  assign io_out_2_bits_vpu_vill = out_bits[2].vpu_vill;
  assign io_out_2_bits_vpu_vma = out_bits[2].vpu_vma;
  assign io_out_2_bits_vpu_vta = out_bits[2].vpu_vta;
  assign io_out_2_bits_vpu_vsew = out_bits[2].vpu_vsew;
  assign io_out_2_bits_vpu_vlmul = out_bits[2].vpu_vlmul;
  assign io_out_2_bits_vpu_specVill = out_bits[2].vpu_specVill;
  assign io_out_2_bits_vpu_specVma = out_bits[2].vpu_specVma;
  assign io_out_2_bits_vpu_specVta = out_bits[2].vpu_specVta;
  assign io_out_2_bits_vpu_specVsew = out_bits[2].vpu_specVsew;
  assign io_out_2_bits_vpu_specVlmul = out_bits[2].vpu_specVlmul;
  assign io_out_2_bits_vpu_vm = out_bits[2].vpu_vm;
  assign io_out_2_bits_vpu_vstart = out_bits[2].vpu_vstart;
  assign io_out_2_bits_vpu_fpu_isFoldTo1_2 = out_bits[2].vpu_fpu_isFoldTo1_2;
  assign io_out_2_bits_vpu_fpu_isFoldTo1_4 = out_bits[2].vpu_fpu_isFoldTo1_4;
  assign io_out_2_bits_vpu_fpu_isFoldTo1_8 = out_bits[2].vpu_fpu_isFoldTo1_8;
  assign io_out_2_bits_vpu_nf = out_bits[2].vpu_nf;
  assign io_out_2_bits_vpu_veew = out_bits[2].vpu_veew;
  assign io_out_2_bits_vpu_isReverse = out_bits[2].vpu_isReverse;
  assign io_out_2_bits_vpu_isExt = out_bits[2].vpu_isExt;
  assign io_out_2_bits_vpu_isNarrow = out_bits[2].vpu_isNarrow;
  assign io_out_2_bits_vpu_isDstMask = out_bits[2].vpu_isDstMask;
  assign io_out_2_bits_vpu_isOpMask = out_bits[2].vpu_isOpMask;
  assign io_out_2_bits_vpu_isDependOldVd = out_bits[2].vpu_isDependOldVd;
  assign io_out_2_bits_vpu_isWritePartVd = out_bits[2].vpu_isWritePartVd;
  assign io_out_2_bits_vpu_isVleff = out_bits[2].vpu_isVleff;
  assign io_out_2_bits_vlsInstr = out_bits[2].vlsInstr;
  assign io_out_2_bits_wfflags = out_bits[2].wfflags;
  assign io_out_2_bits_isMove = out_bits[2].isMove;
  assign io_out_2_bits_uopIdx = out_bits[2].uopIdx;
  assign io_out_2_bits_uopSplitType = out_bits[2].uopSplitType;
  assign io_out_2_bits_isVset = out_bits[2].isVset;
  assign io_out_2_bits_firstUop = out_bits[2].firstUop;
  assign io_out_2_bits_lastUop = out_bits[2].lastUop;
  assign io_out_2_bits_numUops = out_bits[2].numUops;
  assign io_out_2_bits_numWB = out_bits[2].numWB;
  assign io_out_2_bits_commitType = out_bits[2].commitType;
  assign io_out_2_bits_debug_fuType = out_bits[2].debug_fuType;
  assign io_out_2_bits_debug_seqNum_seqNum = out_bits[2].debug_seqNum_seqNum;
  assign io_out_2_bits_debug_seqNum_uopIdx = out_bits[2].debug_seqNum_uopIdx;
  assign io_out_3_valid = out_valid[3];
  assign io_out_3_bits_instr = out_bits[3].instr;
  assign io_out_3_bits_pc = out_bits[3].pc;
  assign io_out_3_bits_foldpc = out_bits[3].foldpc;
  assign io_out_3_bits_exceptionVec_0 = out_bits[3].exceptionVec[0];
  assign io_out_3_bits_exceptionVec_1 = out_bits[3].exceptionVec[1];
  assign io_out_3_bits_exceptionVec_2 = out_bits[3].exceptionVec[2];
  assign io_out_3_bits_exceptionVec_3 = out_bits[3].exceptionVec[3];
  assign io_out_3_bits_exceptionVec_4 = out_bits[3].exceptionVec[4];
  assign io_out_3_bits_exceptionVec_5 = out_bits[3].exceptionVec[5];
  assign io_out_3_bits_exceptionVec_6 = out_bits[3].exceptionVec[6];
  assign io_out_3_bits_exceptionVec_7 = out_bits[3].exceptionVec[7];
  assign io_out_3_bits_exceptionVec_8 = out_bits[3].exceptionVec[8];
  assign io_out_3_bits_exceptionVec_9 = out_bits[3].exceptionVec[9];
  assign io_out_3_bits_exceptionVec_10 = out_bits[3].exceptionVec[10];
  assign io_out_3_bits_exceptionVec_11 = out_bits[3].exceptionVec[11];
  assign io_out_3_bits_exceptionVec_12 = out_bits[3].exceptionVec[12];
  assign io_out_3_bits_exceptionVec_13 = out_bits[3].exceptionVec[13];
  assign io_out_3_bits_exceptionVec_14 = out_bits[3].exceptionVec[14];
  assign io_out_3_bits_exceptionVec_15 = out_bits[3].exceptionVec[15];
  assign io_out_3_bits_exceptionVec_16 = out_bits[3].exceptionVec[16];
  assign io_out_3_bits_exceptionVec_17 = out_bits[3].exceptionVec[17];
  assign io_out_3_bits_exceptionVec_18 = out_bits[3].exceptionVec[18];
  assign io_out_3_bits_exceptionVec_19 = out_bits[3].exceptionVec[19];
  assign io_out_3_bits_exceptionVec_20 = out_bits[3].exceptionVec[20];
  assign io_out_3_bits_exceptionVec_21 = out_bits[3].exceptionVec[21];
  assign io_out_3_bits_exceptionVec_22 = out_bits[3].exceptionVec[22];
  assign io_out_3_bits_exceptionVec_23 = out_bits[3].exceptionVec[23];
  assign io_out_3_bits_isFetchMalAddr = out_bits[3].isFetchMalAddr;
  assign io_out_3_bits_trigger = out_bits[3].trigger;
  assign io_out_3_bits_preDecodeInfo_valid = out_bits[3].preDecodeInfo_valid;
  assign io_out_3_bits_preDecodeInfo_isRVC = out_bits[3].preDecodeInfo_isRVC;
  assign io_out_3_bits_preDecodeInfo_brType = out_bits[3].preDecodeInfo_brType;
  assign io_out_3_bits_preDecodeInfo_isCall = out_bits[3].preDecodeInfo_isCall;
  assign io_out_3_bits_preDecodeInfo_isRet = out_bits[3].preDecodeInfo_isRet;
  assign io_out_3_bits_pred_taken = out_bits[3].pred_taken;
  assign io_out_3_bits_crossPageIPFFix = out_bits[3].crossPageIPFFix;
  assign io_out_3_bits_ftqPtr_flag = out_bits[3].ftqPtr_flag;
  assign io_out_3_bits_ftqPtr_value = out_bits[3].ftqPtr_value;
  assign io_out_3_bits_ftqOffset = out_bits[3].ftqOffset;
  assign io_out_3_bits_satpFlushFirstFetchFault = out_bits[3].satpFlushFirstFetchFault;
  assign io_out_3_bits_srcType_0 = out_bits[3].srcType[0];
  assign io_out_3_bits_srcType_1 = out_bits[3].srcType[1];
  assign io_out_3_bits_srcType_2 = out_bits[3].srcType[2];
  assign io_out_3_bits_srcType_3 = out_bits[3].srcType[3];
  assign io_out_3_bits_srcType_4 = out_bits[3].srcType[4];
  assign io_out_3_bits_lsrc_0 = out_bits[3].lsrc[0];
  assign io_out_3_bits_lsrc_1 = out_bits[3].lsrc[1];
  assign io_out_3_bits_lsrc_2 = out_bits[3].lsrc[2];
  assign io_out_3_bits_ldest = out_bits[3].ldest;
  assign io_out_3_bits_fuType = out_bits[3].fuType;
  assign io_out_3_bits_fuOpType = out_bits[3].fuOpType;
  assign io_out_3_bits_rfWen = out_bits[3].rfWen;
  assign io_out_3_bits_fpWen = out_bits[3].fpWen;
  assign io_out_3_bits_vecWen = out_bits[3].vecWen;
  assign io_out_3_bits_v0Wen = out_bits[3].v0Wen;
  assign io_out_3_bits_vlWen = out_bits[3].vlWen;
  assign io_out_3_bits_isXSTrap = out_bits[3].isXSTrap;
  assign io_out_3_bits_waitForward = out_bits[3].waitForward;
  assign io_out_3_bits_blockBackward = out_bits[3].blockBackward;
  assign io_out_3_bits_flushPipe = out_bits[3].flushPipe;
  assign io_out_3_bits_canRobCompress = out_bits[3].canRobCompress;
  assign io_out_3_bits_selImm = out_bits[3].selImm;
  assign io_out_3_bits_imm = out_bits[3].imm;
  assign io_out_3_bits_fpu_typeTagOut = out_bits[3].fpu_typeTagOut;
  assign io_out_3_bits_fpu_wflags = out_bits[3].fpu_wflags;
  assign io_out_3_bits_fpu_typ = out_bits[3].fpu_typ;
  assign io_out_3_bits_fpu_fmt = out_bits[3].fpu_fmt;
  assign io_out_3_bits_fpu_rm = out_bits[3].fpu_rm;
  assign io_out_3_bits_vpu_vill = out_bits[3].vpu_vill;
  assign io_out_3_bits_vpu_vma = out_bits[3].vpu_vma;
  assign io_out_3_bits_vpu_vta = out_bits[3].vpu_vta;
  assign io_out_3_bits_vpu_vsew = out_bits[3].vpu_vsew;
  assign io_out_3_bits_vpu_vlmul = out_bits[3].vpu_vlmul;
  assign io_out_3_bits_vpu_specVill = out_bits[3].vpu_specVill;
  assign io_out_3_bits_vpu_specVma = out_bits[3].vpu_specVma;
  assign io_out_3_bits_vpu_specVta = out_bits[3].vpu_specVta;
  assign io_out_3_bits_vpu_specVsew = out_bits[3].vpu_specVsew;
  assign io_out_3_bits_vpu_specVlmul = out_bits[3].vpu_specVlmul;
  assign io_out_3_bits_vpu_vm = out_bits[3].vpu_vm;
  assign io_out_3_bits_vpu_vstart = out_bits[3].vpu_vstart;
  assign io_out_3_bits_vpu_fpu_isFoldTo1_2 = out_bits[3].vpu_fpu_isFoldTo1_2;
  assign io_out_3_bits_vpu_fpu_isFoldTo1_4 = out_bits[3].vpu_fpu_isFoldTo1_4;
  assign io_out_3_bits_vpu_fpu_isFoldTo1_8 = out_bits[3].vpu_fpu_isFoldTo1_8;
  assign io_out_3_bits_vpu_nf = out_bits[3].vpu_nf;
  assign io_out_3_bits_vpu_veew = out_bits[3].vpu_veew;
  assign io_out_3_bits_vpu_isReverse = out_bits[3].vpu_isReverse;
  assign io_out_3_bits_vpu_isExt = out_bits[3].vpu_isExt;
  assign io_out_3_bits_vpu_isNarrow = out_bits[3].vpu_isNarrow;
  assign io_out_3_bits_vpu_isDstMask = out_bits[3].vpu_isDstMask;
  assign io_out_3_bits_vpu_isOpMask = out_bits[3].vpu_isOpMask;
  assign io_out_3_bits_vpu_isDependOldVd = out_bits[3].vpu_isDependOldVd;
  assign io_out_3_bits_vpu_isWritePartVd = out_bits[3].vpu_isWritePartVd;
  assign io_out_3_bits_vpu_isVleff = out_bits[3].vpu_isVleff;
  assign io_out_3_bits_vlsInstr = out_bits[3].vlsInstr;
  assign io_out_3_bits_wfflags = out_bits[3].wfflags;
  assign io_out_3_bits_isMove = out_bits[3].isMove;
  assign io_out_3_bits_uopIdx = out_bits[3].uopIdx;
  assign io_out_3_bits_uopSplitType = out_bits[3].uopSplitType;
  assign io_out_3_bits_isVset = out_bits[3].isVset;
  assign io_out_3_bits_firstUop = out_bits[3].firstUop;
  assign io_out_3_bits_lastUop = out_bits[3].lastUop;
  assign io_out_3_bits_numUops = out_bits[3].numUops;
  assign io_out_3_bits_numWB = out_bits[3].numWB;
  assign io_out_3_bits_commitType = out_bits[3].commitType;
  assign io_out_3_bits_debug_fuType = out_bits[3].debug_fuType;
  assign io_out_3_bits_debug_seqNum_seqNum = out_bits[3].debug_seqNum_seqNum;
  assign io_out_3_bits_debug_seqNum_uopIdx = out_bits[3].debug_seqNum_uopIdx;
  assign io_out_4_valid = out_valid[4];
  assign io_out_4_bits_instr = out_bits[4].instr;
  assign io_out_4_bits_pc = out_bits[4].pc;
  assign io_out_4_bits_foldpc = out_bits[4].foldpc;
  assign io_out_4_bits_exceptionVec_0 = out_bits[4].exceptionVec[0];
  assign io_out_4_bits_exceptionVec_1 = out_bits[4].exceptionVec[1];
  assign io_out_4_bits_exceptionVec_2 = out_bits[4].exceptionVec[2];
  assign io_out_4_bits_exceptionVec_3 = out_bits[4].exceptionVec[3];
  assign io_out_4_bits_exceptionVec_4 = out_bits[4].exceptionVec[4];
  assign io_out_4_bits_exceptionVec_5 = out_bits[4].exceptionVec[5];
  assign io_out_4_bits_exceptionVec_6 = out_bits[4].exceptionVec[6];
  assign io_out_4_bits_exceptionVec_7 = out_bits[4].exceptionVec[7];
  assign io_out_4_bits_exceptionVec_8 = out_bits[4].exceptionVec[8];
  assign io_out_4_bits_exceptionVec_9 = out_bits[4].exceptionVec[9];
  assign io_out_4_bits_exceptionVec_10 = out_bits[4].exceptionVec[10];
  assign io_out_4_bits_exceptionVec_11 = out_bits[4].exceptionVec[11];
  assign io_out_4_bits_exceptionVec_12 = out_bits[4].exceptionVec[12];
  assign io_out_4_bits_exceptionVec_13 = out_bits[4].exceptionVec[13];
  assign io_out_4_bits_exceptionVec_14 = out_bits[4].exceptionVec[14];
  assign io_out_4_bits_exceptionVec_15 = out_bits[4].exceptionVec[15];
  assign io_out_4_bits_exceptionVec_16 = out_bits[4].exceptionVec[16];
  assign io_out_4_bits_exceptionVec_17 = out_bits[4].exceptionVec[17];
  assign io_out_4_bits_exceptionVec_18 = out_bits[4].exceptionVec[18];
  assign io_out_4_bits_exceptionVec_19 = out_bits[4].exceptionVec[19];
  assign io_out_4_bits_exceptionVec_20 = out_bits[4].exceptionVec[20];
  assign io_out_4_bits_exceptionVec_21 = out_bits[4].exceptionVec[21];
  assign io_out_4_bits_exceptionVec_22 = out_bits[4].exceptionVec[22];
  assign io_out_4_bits_exceptionVec_23 = out_bits[4].exceptionVec[23];
  assign io_out_4_bits_isFetchMalAddr = out_bits[4].isFetchMalAddr;
  assign io_out_4_bits_trigger = out_bits[4].trigger;
  assign io_out_4_bits_preDecodeInfo_valid = out_bits[4].preDecodeInfo_valid;
  assign io_out_4_bits_preDecodeInfo_isRVC = out_bits[4].preDecodeInfo_isRVC;
  assign io_out_4_bits_preDecodeInfo_brType = out_bits[4].preDecodeInfo_brType;
  assign io_out_4_bits_preDecodeInfo_isCall = out_bits[4].preDecodeInfo_isCall;
  assign io_out_4_bits_preDecodeInfo_isRet = out_bits[4].preDecodeInfo_isRet;
  assign io_out_4_bits_pred_taken = out_bits[4].pred_taken;
  assign io_out_4_bits_crossPageIPFFix = out_bits[4].crossPageIPFFix;
  assign io_out_4_bits_ftqPtr_flag = out_bits[4].ftqPtr_flag;
  assign io_out_4_bits_ftqPtr_value = out_bits[4].ftqPtr_value;
  assign io_out_4_bits_ftqOffset = out_bits[4].ftqOffset;
  assign io_out_4_bits_satpFlushFirstFetchFault = out_bits[4].satpFlushFirstFetchFault;
  assign io_out_4_bits_srcType_0 = out_bits[4].srcType[0];
  assign io_out_4_bits_srcType_1 = out_bits[4].srcType[1];
  assign io_out_4_bits_srcType_2 = out_bits[4].srcType[2];
  assign io_out_4_bits_srcType_3 = out_bits[4].srcType[3];
  assign io_out_4_bits_srcType_4 = out_bits[4].srcType[4];
  assign io_out_4_bits_lsrc_0 = out_bits[4].lsrc[0];
  assign io_out_4_bits_lsrc_1 = out_bits[4].lsrc[1];
  assign io_out_4_bits_lsrc_2 = out_bits[4].lsrc[2];
  assign io_out_4_bits_ldest = out_bits[4].ldest;
  assign io_out_4_bits_fuType = out_bits[4].fuType;
  assign io_out_4_bits_fuOpType = out_bits[4].fuOpType;
  assign io_out_4_bits_rfWen = out_bits[4].rfWen;
  assign io_out_4_bits_fpWen = out_bits[4].fpWen;
  assign io_out_4_bits_vecWen = out_bits[4].vecWen;
  assign io_out_4_bits_v0Wen = out_bits[4].v0Wen;
  assign io_out_4_bits_vlWen = out_bits[4].vlWen;
  assign io_out_4_bits_isXSTrap = out_bits[4].isXSTrap;
  assign io_out_4_bits_waitForward = out_bits[4].waitForward;
  assign io_out_4_bits_blockBackward = out_bits[4].blockBackward;
  assign io_out_4_bits_flushPipe = out_bits[4].flushPipe;
  assign io_out_4_bits_canRobCompress = out_bits[4].canRobCompress;
  assign io_out_4_bits_selImm = out_bits[4].selImm;
  assign io_out_4_bits_imm = out_bits[4].imm;
  assign io_out_4_bits_fpu_typeTagOut = out_bits[4].fpu_typeTagOut;
  assign io_out_4_bits_fpu_wflags = out_bits[4].fpu_wflags;
  assign io_out_4_bits_fpu_typ = out_bits[4].fpu_typ;
  assign io_out_4_bits_fpu_fmt = out_bits[4].fpu_fmt;
  assign io_out_4_bits_fpu_rm = out_bits[4].fpu_rm;
  assign io_out_4_bits_vpu_vill = out_bits[4].vpu_vill;
  assign io_out_4_bits_vpu_vma = out_bits[4].vpu_vma;
  assign io_out_4_bits_vpu_vta = out_bits[4].vpu_vta;
  assign io_out_4_bits_vpu_vsew = out_bits[4].vpu_vsew;
  assign io_out_4_bits_vpu_vlmul = out_bits[4].vpu_vlmul;
  assign io_out_4_bits_vpu_specVill = out_bits[4].vpu_specVill;
  assign io_out_4_bits_vpu_specVma = out_bits[4].vpu_specVma;
  assign io_out_4_bits_vpu_specVta = out_bits[4].vpu_specVta;
  assign io_out_4_bits_vpu_specVsew = out_bits[4].vpu_specVsew;
  assign io_out_4_bits_vpu_specVlmul = out_bits[4].vpu_specVlmul;
  assign io_out_4_bits_vpu_vm = out_bits[4].vpu_vm;
  assign io_out_4_bits_vpu_vstart = out_bits[4].vpu_vstart;
  assign io_out_4_bits_vpu_fpu_isFoldTo1_2 = out_bits[4].vpu_fpu_isFoldTo1_2;
  assign io_out_4_bits_vpu_fpu_isFoldTo1_4 = out_bits[4].vpu_fpu_isFoldTo1_4;
  assign io_out_4_bits_vpu_fpu_isFoldTo1_8 = out_bits[4].vpu_fpu_isFoldTo1_8;
  assign io_out_4_bits_vpu_nf = out_bits[4].vpu_nf;
  assign io_out_4_bits_vpu_veew = out_bits[4].vpu_veew;
  assign io_out_4_bits_vpu_isReverse = out_bits[4].vpu_isReverse;
  assign io_out_4_bits_vpu_isExt = out_bits[4].vpu_isExt;
  assign io_out_4_bits_vpu_isNarrow = out_bits[4].vpu_isNarrow;
  assign io_out_4_bits_vpu_isDstMask = out_bits[4].vpu_isDstMask;
  assign io_out_4_bits_vpu_isOpMask = out_bits[4].vpu_isOpMask;
  assign io_out_4_bits_vpu_isDependOldVd = out_bits[4].vpu_isDependOldVd;
  assign io_out_4_bits_vpu_isWritePartVd = out_bits[4].vpu_isWritePartVd;
  assign io_out_4_bits_vpu_isVleff = out_bits[4].vpu_isVleff;
  assign io_out_4_bits_vlsInstr = out_bits[4].vlsInstr;
  assign io_out_4_bits_wfflags = out_bits[4].wfflags;
  assign io_out_4_bits_isMove = out_bits[4].isMove;
  assign io_out_4_bits_uopIdx = out_bits[4].uopIdx;
  assign io_out_4_bits_uopSplitType = out_bits[4].uopSplitType;
  assign io_out_4_bits_isVset = out_bits[4].isVset;
  assign io_out_4_bits_firstUop = out_bits[4].firstUop;
  assign io_out_4_bits_lastUop = out_bits[4].lastUop;
  assign io_out_4_bits_numUops = out_bits[4].numUops;
  assign io_out_4_bits_numWB = out_bits[4].numWB;
  assign io_out_4_bits_commitType = out_bits[4].commitType;
  assign io_out_4_bits_debug_fuType = out_bits[4].debug_fuType;
  assign io_out_4_bits_debug_seqNum_seqNum = out_bits[4].debug_seqNum_seqNum;
  assign io_out_4_bits_debug_seqNum_uopIdx = out_bits[4].debug_seqNum_uopIdx;
  assign io_out_5_valid = out_valid[5];
  assign io_out_5_bits_instr = out_bits[5].instr;
  assign io_out_5_bits_pc = out_bits[5].pc;
  assign io_out_5_bits_foldpc = out_bits[5].foldpc;
  assign io_out_5_bits_exceptionVec_0 = out_bits[5].exceptionVec[0];
  assign io_out_5_bits_exceptionVec_1 = out_bits[5].exceptionVec[1];
  assign io_out_5_bits_exceptionVec_2 = out_bits[5].exceptionVec[2];
  assign io_out_5_bits_exceptionVec_3 = out_bits[5].exceptionVec[3];
  assign io_out_5_bits_exceptionVec_4 = out_bits[5].exceptionVec[4];
  assign io_out_5_bits_exceptionVec_5 = out_bits[5].exceptionVec[5];
  assign io_out_5_bits_exceptionVec_6 = out_bits[5].exceptionVec[6];
  assign io_out_5_bits_exceptionVec_7 = out_bits[5].exceptionVec[7];
  assign io_out_5_bits_exceptionVec_8 = out_bits[5].exceptionVec[8];
  assign io_out_5_bits_exceptionVec_9 = out_bits[5].exceptionVec[9];
  assign io_out_5_bits_exceptionVec_10 = out_bits[5].exceptionVec[10];
  assign io_out_5_bits_exceptionVec_11 = out_bits[5].exceptionVec[11];
  assign io_out_5_bits_exceptionVec_12 = out_bits[5].exceptionVec[12];
  assign io_out_5_bits_exceptionVec_13 = out_bits[5].exceptionVec[13];
  assign io_out_5_bits_exceptionVec_14 = out_bits[5].exceptionVec[14];
  assign io_out_5_bits_exceptionVec_15 = out_bits[5].exceptionVec[15];
  assign io_out_5_bits_exceptionVec_16 = out_bits[5].exceptionVec[16];
  assign io_out_5_bits_exceptionVec_17 = out_bits[5].exceptionVec[17];
  assign io_out_5_bits_exceptionVec_18 = out_bits[5].exceptionVec[18];
  assign io_out_5_bits_exceptionVec_19 = out_bits[5].exceptionVec[19];
  assign io_out_5_bits_exceptionVec_20 = out_bits[5].exceptionVec[20];
  assign io_out_5_bits_exceptionVec_21 = out_bits[5].exceptionVec[21];
  assign io_out_5_bits_exceptionVec_22 = out_bits[5].exceptionVec[22];
  assign io_out_5_bits_exceptionVec_23 = out_bits[5].exceptionVec[23];
  assign io_out_5_bits_isFetchMalAddr = out_bits[5].isFetchMalAddr;
  assign io_out_5_bits_trigger = out_bits[5].trigger;
  assign io_out_5_bits_preDecodeInfo_valid = out_bits[5].preDecodeInfo_valid;
  assign io_out_5_bits_preDecodeInfo_isRVC = out_bits[5].preDecodeInfo_isRVC;
  assign io_out_5_bits_preDecodeInfo_brType = out_bits[5].preDecodeInfo_brType;
  assign io_out_5_bits_preDecodeInfo_isCall = out_bits[5].preDecodeInfo_isCall;
  assign io_out_5_bits_preDecodeInfo_isRet = out_bits[5].preDecodeInfo_isRet;
  assign io_out_5_bits_pred_taken = out_bits[5].pred_taken;
  assign io_out_5_bits_crossPageIPFFix = out_bits[5].crossPageIPFFix;
  assign io_out_5_bits_ftqPtr_flag = out_bits[5].ftqPtr_flag;
  assign io_out_5_bits_ftqPtr_value = out_bits[5].ftqPtr_value;
  assign io_out_5_bits_ftqOffset = out_bits[5].ftqOffset;
  assign io_out_5_bits_satpFlushFirstFetchFault = out_bits[5].satpFlushFirstFetchFault;
  assign io_out_5_bits_srcType_0 = out_bits[5].srcType[0];
  assign io_out_5_bits_srcType_1 = out_bits[5].srcType[1];
  assign io_out_5_bits_srcType_2 = out_bits[5].srcType[2];
  assign io_out_5_bits_srcType_3 = out_bits[5].srcType[3];
  assign io_out_5_bits_srcType_4 = out_bits[5].srcType[4];
  assign io_out_5_bits_lsrc_0 = out_bits[5].lsrc[0];
  assign io_out_5_bits_lsrc_1 = out_bits[5].lsrc[1];
  assign io_out_5_bits_lsrc_2 = out_bits[5].lsrc[2];
  assign io_out_5_bits_ldest = out_bits[5].ldest;
  assign io_out_5_bits_fuType = out_bits[5].fuType;
  assign io_out_5_bits_fuOpType = out_bits[5].fuOpType;
  assign io_out_5_bits_rfWen = out_bits[5].rfWen;
  assign io_out_5_bits_fpWen = out_bits[5].fpWen;
  assign io_out_5_bits_vecWen = out_bits[5].vecWen;
  assign io_out_5_bits_v0Wen = out_bits[5].v0Wen;
  assign io_out_5_bits_vlWen = out_bits[5].vlWen;
  assign io_out_5_bits_isXSTrap = out_bits[5].isXSTrap;
  assign io_out_5_bits_waitForward = out_bits[5].waitForward;
  assign io_out_5_bits_blockBackward = out_bits[5].blockBackward;
  assign io_out_5_bits_flushPipe = out_bits[5].flushPipe;
  assign io_out_5_bits_canRobCompress = out_bits[5].canRobCompress;
  assign io_out_5_bits_selImm = out_bits[5].selImm;
  assign io_out_5_bits_imm = out_bits[5].imm;
  assign io_out_5_bits_fpu_typeTagOut = out_bits[5].fpu_typeTagOut;
  assign io_out_5_bits_fpu_wflags = out_bits[5].fpu_wflags;
  assign io_out_5_bits_fpu_typ = out_bits[5].fpu_typ;
  assign io_out_5_bits_fpu_fmt = out_bits[5].fpu_fmt;
  assign io_out_5_bits_fpu_rm = out_bits[5].fpu_rm;
  assign io_out_5_bits_vpu_vill = out_bits[5].vpu_vill;
  assign io_out_5_bits_vpu_vma = out_bits[5].vpu_vma;
  assign io_out_5_bits_vpu_vta = out_bits[5].vpu_vta;
  assign io_out_5_bits_vpu_vsew = out_bits[5].vpu_vsew;
  assign io_out_5_bits_vpu_vlmul = out_bits[5].vpu_vlmul;
  assign io_out_5_bits_vpu_specVill = out_bits[5].vpu_specVill;
  assign io_out_5_bits_vpu_specVma = out_bits[5].vpu_specVma;
  assign io_out_5_bits_vpu_specVta = out_bits[5].vpu_specVta;
  assign io_out_5_bits_vpu_specVsew = out_bits[5].vpu_specVsew;
  assign io_out_5_bits_vpu_specVlmul = out_bits[5].vpu_specVlmul;
  assign io_out_5_bits_vpu_vm = out_bits[5].vpu_vm;
  assign io_out_5_bits_vpu_vstart = out_bits[5].vpu_vstart;
  assign io_out_5_bits_vpu_fpu_isFoldTo1_2 = out_bits[5].vpu_fpu_isFoldTo1_2;
  assign io_out_5_bits_vpu_fpu_isFoldTo1_4 = out_bits[5].vpu_fpu_isFoldTo1_4;
  assign io_out_5_bits_vpu_fpu_isFoldTo1_8 = out_bits[5].vpu_fpu_isFoldTo1_8;
  assign io_out_5_bits_vpu_nf = out_bits[5].vpu_nf;
  assign io_out_5_bits_vpu_veew = out_bits[5].vpu_veew;
  assign io_out_5_bits_vpu_isReverse = out_bits[5].vpu_isReverse;
  assign io_out_5_bits_vpu_isExt = out_bits[5].vpu_isExt;
  assign io_out_5_bits_vpu_isNarrow = out_bits[5].vpu_isNarrow;
  assign io_out_5_bits_vpu_isDstMask = out_bits[5].vpu_isDstMask;
  assign io_out_5_bits_vpu_isOpMask = out_bits[5].vpu_isOpMask;
  assign io_out_5_bits_vpu_isDependOldVd = out_bits[5].vpu_isDependOldVd;
  assign io_out_5_bits_vpu_isWritePartVd = out_bits[5].vpu_isWritePartVd;
  assign io_out_5_bits_vpu_isVleff = out_bits[5].vpu_isVleff;
  assign io_out_5_bits_vlsInstr = out_bits[5].vlsInstr;
  assign io_out_5_bits_wfflags = out_bits[5].wfflags;
  assign io_out_5_bits_isMove = out_bits[5].isMove;
  assign io_out_5_bits_uopIdx = out_bits[5].uopIdx;
  assign io_out_5_bits_uopSplitType = out_bits[5].uopSplitType;
  assign io_out_5_bits_isVset = out_bits[5].isVset;
  assign io_out_5_bits_firstUop = out_bits[5].firstUop;
  assign io_out_5_bits_lastUop = out_bits[5].lastUop;
  assign io_out_5_bits_numUops = out_bits[5].numUops;
  assign io_out_5_bits_numWB = out_bits[5].numWB;
  assign io_out_5_bits_commitType = out_bits[5].commitType;
  assign io_out_5_bits_debug_fuType = out_bits[5].debug_fuType;
  assign io_out_5_bits_debug_seqNum_seqNum = out_bits[5].debug_seqNum_seqNum;
  assign io_out_5_bits_debug_seqNum_uopIdx = out_bits[5].debug_seqNum_uopIdx;
  assign io_intRat_0_0_hold = intRat_hold[0][0];
  assign io_intRat_0_0_addr = intRat_addr[0][0];
  assign io_intRat_0_1_hold = intRat_hold[0][1];
  assign io_intRat_0_1_addr = intRat_addr[0][1];
  assign io_intRat_1_0_hold = intRat_hold[1][0];
  assign io_intRat_1_0_addr = intRat_addr[1][0];
  assign io_intRat_1_1_hold = intRat_hold[1][1];
  assign io_intRat_1_1_addr = intRat_addr[1][1];
  assign io_intRat_2_0_hold = intRat_hold[2][0];
  assign io_intRat_2_0_addr = intRat_addr[2][0];
  assign io_intRat_2_1_hold = intRat_hold[2][1];
  assign io_intRat_2_1_addr = intRat_addr[2][1];
  assign io_intRat_3_0_hold = intRat_hold[3][0];
  assign io_intRat_3_0_addr = intRat_addr[3][0];
  assign io_intRat_3_1_hold = intRat_hold[3][1];
  assign io_intRat_3_1_addr = intRat_addr[3][1];
  assign io_intRat_4_0_hold = intRat_hold[4][0];
  assign io_intRat_4_0_addr = intRat_addr[4][0];
  assign io_intRat_4_1_hold = intRat_hold[4][1];
  assign io_intRat_4_1_addr = intRat_addr[4][1];
  assign io_intRat_5_0_hold = intRat_hold[5][0];
  assign io_intRat_5_0_addr = intRat_addr[5][0];
  assign io_intRat_5_1_hold = intRat_hold[5][1];
  assign io_intRat_5_1_addr = intRat_addr[5][1];
  assign io_fpRat_0_0_hold = fpRat_hold[0][0];
  assign io_fpRat_0_0_addr = fpRat_addr[0][0];
  assign io_fpRat_0_1_hold = fpRat_hold[0][1];
  assign io_fpRat_0_1_addr = fpRat_addr[0][1];
  assign io_fpRat_0_2_hold = fpRat_hold[0][2];
  assign io_fpRat_0_2_addr = fpRat_addr[0][2];
  assign io_fpRat_1_0_hold = fpRat_hold[1][0];
  assign io_fpRat_1_0_addr = fpRat_addr[1][0];
  assign io_fpRat_1_1_hold = fpRat_hold[1][1];
  assign io_fpRat_1_1_addr = fpRat_addr[1][1];
  assign io_fpRat_1_2_hold = fpRat_hold[1][2];
  assign io_fpRat_1_2_addr = fpRat_addr[1][2];
  assign io_fpRat_2_0_hold = fpRat_hold[2][0];
  assign io_fpRat_2_0_addr = fpRat_addr[2][0];
  assign io_fpRat_2_1_hold = fpRat_hold[2][1];
  assign io_fpRat_2_1_addr = fpRat_addr[2][1];
  assign io_fpRat_2_2_hold = fpRat_hold[2][2];
  assign io_fpRat_2_2_addr = fpRat_addr[2][2];
  assign io_fpRat_3_0_hold = fpRat_hold[3][0];
  assign io_fpRat_3_0_addr = fpRat_addr[3][0];
  assign io_fpRat_3_1_hold = fpRat_hold[3][1];
  assign io_fpRat_3_1_addr = fpRat_addr[3][1];
  assign io_fpRat_3_2_hold = fpRat_hold[3][2];
  assign io_fpRat_3_2_addr = fpRat_addr[3][2];
  assign io_fpRat_4_0_hold = fpRat_hold[4][0];
  assign io_fpRat_4_0_addr = fpRat_addr[4][0];
  assign io_fpRat_4_1_hold = fpRat_hold[4][1];
  assign io_fpRat_4_1_addr = fpRat_addr[4][1];
  assign io_fpRat_4_2_hold = fpRat_hold[4][2];
  assign io_fpRat_4_2_addr = fpRat_addr[4][2];
  assign io_fpRat_5_0_hold = fpRat_hold[5][0];
  assign io_fpRat_5_0_addr = fpRat_addr[5][0];
  assign io_fpRat_5_1_hold = fpRat_hold[5][1];
  assign io_fpRat_5_1_addr = fpRat_addr[5][1];
  assign io_fpRat_5_2_hold = fpRat_hold[5][2];
  assign io_fpRat_5_2_addr = fpRat_addr[5][2];
  assign io_vecRat_0_0_hold = vecRat_hold[0][0];
  assign io_vecRat_0_0_addr = vecRat_addr[0][0];
  assign io_vecRat_0_1_hold = vecRat_hold[0][1];
  assign io_vecRat_0_1_addr = vecRat_addr[0][1];
  assign io_vecRat_0_2_hold = vecRat_hold[0][2];
  assign io_vecRat_0_2_addr = vecRat_addr[0][2];
  assign io_vecRat_1_0_hold = vecRat_hold[1][0];
  assign io_vecRat_1_0_addr = vecRat_addr[1][0];
  assign io_vecRat_1_1_hold = vecRat_hold[1][1];
  assign io_vecRat_1_1_addr = vecRat_addr[1][1];
  assign io_vecRat_1_2_hold = vecRat_hold[1][2];
  assign io_vecRat_1_2_addr = vecRat_addr[1][2];
  assign io_vecRat_2_0_hold = vecRat_hold[2][0];
  assign io_vecRat_2_0_addr = vecRat_addr[2][0];
  assign io_vecRat_2_1_hold = vecRat_hold[2][1];
  assign io_vecRat_2_1_addr = vecRat_addr[2][1];
  assign io_vecRat_2_2_hold = vecRat_hold[2][2];
  assign io_vecRat_2_2_addr = vecRat_addr[2][2];
  assign io_vecRat_3_0_hold = vecRat_hold[3][0];
  assign io_vecRat_3_0_addr = vecRat_addr[3][0];
  assign io_vecRat_3_1_hold = vecRat_hold[3][1];
  assign io_vecRat_3_1_addr = vecRat_addr[3][1];
  assign io_vecRat_3_2_hold = vecRat_hold[3][2];
  assign io_vecRat_3_2_addr = vecRat_addr[3][2];
  assign io_vecRat_4_0_hold = vecRat_hold[4][0];
  assign io_vecRat_4_0_addr = vecRat_addr[4][0];
  assign io_vecRat_4_1_hold = vecRat_hold[4][1];
  assign io_vecRat_4_1_addr = vecRat_addr[4][1];
  assign io_vecRat_4_2_hold = vecRat_hold[4][2];
  assign io_vecRat_4_2_addr = vecRat_addr[4][2];
  assign io_vecRat_5_0_hold = vecRat_hold[5][0];
  assign io_vecRat_5_0_addr = vecRat_addr[5][0];
  assign io_vecRat_5_1_hold = vecRat_hold[5][1];
  assign io_vecRat_5_1_addr = vecRat_addr[5][1];
  assign io_vecRat_5_2_hold = vecRat_hold[5][2];
  assign io_vecRat_5_2_addr = vecRat_addr[5][2];
  assign io_v0Rat_0_hold = v0Rat_hold[0];
  assign io_v0Rat_1_hold = v0Rat_hold[1];
  assign io_v0Rat_2_hold = v0Rat_hold[2];
  assign io_v0Rat_3_hold = v0Rat_hold[3];
  assign io_v0Rat_4_hold = v0Rat_hold[4];
  assign io_v0Rat_5_hold = v0Rat_hold[5];
  assign io_vlRat_0_hold = vlRat_hold[0];
  assign io_vlRat_1_hold = vlRat_hold[1];
  assign io_vlRat_2_hold = vlRat_hold[2];
  assign io_vlRat_3_hold = vlRat_hold[3];
  assign io_vlRat_4_hold = vlRat_hold[4];
  assign io_vlRat_5_hold = vlRat_hold[5];
  assign io_stallReason_in_backReason_valid = stallReason_in_backReason_valid;
  assign io_stallReason_in_backReason_bits = stallReason_in_backReason_bits;
  assign io_stallReason_out_reason_0 = stallReason_out_reason[0];
  assign io_stallReason_out_reason_1 = stallReason_out_reason[1];
  assign io_stallReason_out_reason_2 = stallReason_out_reason[2];
  assign io_stallReason_out_reason_3 = stallReason_out_reason[3];
  assign io_stallReason_out_reason_4 = stallReason_out_reason[4];
  assign io_stallReason_out_reason_5 = stallReason_out_reason[5];
  assign io_toCSR_trapInstInfo_valid = trapInstInfo_valid;
  assign io_toCSR_trapInstInfo_bits_instr = trapInstInfo.instr;
  assign io_toCSR_trapInstInfo_bits_ftqPtr_flag = trapInstInfo.ftqPtr_flag;
  assign io_toCSR_trapInstInfo_bits_ftqPtr_value = trapInstInfo.ftqPtr_value;
  assign io_toCSR_trapInstInfo_bits_ftqOffset = trapInstInfo.ftqOffset;
  assign io_perf_0_value = perf_value[0];
  assign io_perf_1_value = perf_value[1];
  assign io_perf_2_value = perf_value[2];
  assign io_perf_3_value = perf_value[3];
  assign io_perf_4_value = perf_value[4];
  assign io_perf_5_value = perf_value[5];
  assign io_perf_6_value = perf_value[6];
  assign io_perf_7_value = perf_value[7];
  // END GENERATED

endmodule
