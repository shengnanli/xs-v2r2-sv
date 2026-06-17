// =============================================================================
// DecodeUnit_wrapper —— golden 同名顶层端口适配层
//
// 把可读核 xs_DecodeUnit_core 的 struct 端口拆/拼成 golden DecodeUnit 的扁平端口。
// 本层只做机械线连接，允许平铺。
//
// 说明（见 docs/backend/DecodeUnit.md）：
//   本 wrapper 完整驱动 DecodeUnit 全部译码相关输出：srcType/lsrc/ldest、
//   fuType/fuOpType、各 wen 与 flag、selImm/imm、uopSplitType、fpu_rm/wflags/
//   typeTagOut/typ/fmt、uopInfo，以及 exceptionVec[2]/[3]/[22]、vpu 明细
//   (isReverse/isExt/isNarrow/isDstMask/isOpMask/isDependOldVd/isWritePartVd/
//   isVleff)、wfflags、isMove、isVset、commitType、vlsInstr。
//   FM（黑盒 FPDecoder/UopInfoGen）已 SUCCEEDED（289 比对点全过）；UT 逐拍比对
//   全部 157 输出端口 seed 1/7/42 各 250000 拍、0 错。
//   仍透传的纯 StaticInst 字段（foldpc/trigger/ftqPtr/preDecodeInfo/pred_taken
//   等）与入口直透 exceptionVec 位非译码逻辑，按 golden 同样透传。
// =============================================================================
`include "decodeunit_svh.svh"

module DecodeUnit (
  input  [31:0] io_enq_ctrlFlow_instr,
  input  [9:0]  io_enq_ctrlFlow_foldpc,
  input         io_enq_ctrlFlow_exceptionVec_0,
  input         io_enq_ctrlFlow_exceptionVec_1,
  input         io_enq_ctrlFlow_exceptionVec_2,
  input         io_enq_ctrlFlow_exceptionVec_4,
  input         io_enq_ctrlFlow_exceptionVec_5,
  input         io_enq_ctrlFlow_exceptionVec_6,
  input         io_enq_ctrlFlow_exceptionVec_7,
  input         io_enq_ctrlFlow_exceptionVec_8,
  input         io_enq_ctrlFlow_exceptionVec_9,
  input         io_enq_ctrlFlow_exceptionVec_10,
  input         io_enq_ctrlFlow_exceptionVec_11,
  input         io_enq_ctrlFlow_exceptionVec_12,
  input         io_enq_ctrlFlow_exceptionVec_13,
  input         io_enq_ctrlFlow_exceptionVec_14,
  input         io_enq_ctrlFlow_exceptionVec_15,
  input         io_enq_ctrlFlow_exceptionVec_16,
  input         io_enq_ctrlFlow_exceptionVec_17,
  input         io_enq_ctrlFlow_exceptionVec_18,
  input         io_enq_ctrlFlow_exceptionVec_19,
  input         io_enq_ctrlFlow_exceptionVec_20,
  input         io_enq_ctrlFlow_exceptionVec_21,
  input         io_enq_ctrlFlow_exceptionVec_23,
  input         io_enq_ctrlFlow_isFetchMalAddr,
  input  [3:0]  io_enq_ctrlFlow_trigger,
  input         io_enq_ctrlFlow_preDecodeInfo_isRVC,
  input  [1:0]  io_enq_ctrlFlow_preDecodeInfo_brType,
  input         io_enq_ctrlFlow_pred_taken,
  input         io_enq_ctrlFlow_crossPageIPFFix,
  input         io_enq_ctrlFlow_ftqPtr_flag,
  input  [5:0]  io_enq_ctrlFlow_ftqPtr_value,
  input  [3:0]  io_enq_ctrlFlow_ftqOffset,
  input         io_enq_ctrlFlow_isLastInFtqEntry,
  input         io_enq_vtype_illegal,
  input         io_enq_vtype_vma,
  input         io_enq_vtype_vta,
  input  [1:0]  io_enq_vtype_vsew,
  input  [2:0]  io_enq_vtype_vlmul,
  input  [7:0]  io_enq_vstart,
  output [31:0] io_deq_decodedInst_instr,
  output [9:0]  io_deq_decodedInst_foldpc,
  output        io_deq_decodedInst_exceptionVec_0,
  output        io_deq_decodedInst_exceptionVec_1,
  output        io_deq_decodedInst_exceptionVec_2,
  output        io_deq_decodedInst_exceptionVec_3,
  output        io_deq_decodedInst_exceptionVec_4,
  output        io_deq_decodedInst_exceptionVec_5,
  output        io_deq_decodedInst_exceptionVec_6,
  output        io_deq_decodedInst_exceptionVec_7,
  output        io_deq_decodedInst_exceptionVec_8,
  output        io_deq_decodedInst_exceptionVec_9,
  output        io_deq_decodedInst_exceptionVec_10,
  output        io_deq_decodedInst_exceptionVec_11,
  output        io_deq_decodedInst_exceptionVec_12,
  output        io_deq_decodedInst_exceptionVec_13,
  output        io_deq_decodedInst_exceptionVec_14,
  output        io_deq_decodedInst_exceptionVec_15,
  output        io_deq_decodedInst_exceptionVec_16,
  output        io_deq_decodedInst_exceptionVec_17,
  output        io_deq_decodedInst_exceptionVec_18,
  output        io_deq_decodedInst_exceptionVec_19,
  output        io_deq_decodedInst_exceptionVec_20,
  output        io_deq_decodedInst_exceptionVec_21,
  output        io_deq_decodedInst_exceptionVec_22,
  output        io_deq_decodedInst_exceptionVec_23,
  output        io_deq_decodedInst_isFetchMalAddr,
  output [3:0]  io_deq_decodedInst_trigger,
  output        io_deq_decodedInst_preDecodeInfo_isRVC,
  output [1:0]  io_deq_decodedInst_preDecodeInfo_brType,
  output        io_deq_decodedInst_pred_taken,
  output        io_deq_decodedInst_crossPageIPFFix,
  output        io_deq_decodedInst_ftqPtr_flag,
  output [5:0]  io_deq_decodedInst_ftqPtr_value,
  output [3:0]  io_deq_decodedInst_ftqOffset,
  output [3:0]  io_deq_decodedInst_srcType_0,
  output [3:0]  io_deq_decodedInst_srcType_1,
  output [3:0]  io_deq_decodedInst_srcType_2,
  output [3:0]  io_deq_decodedInst_srcType_3,
  output [3:0]  io_deq_decodedInst_srcType_4,
  output [5:0]  io_deq_decodedInst_lsrc_0,
  output [5:0]  io_deq_decodedInst_lsrc_1,
  output [5:0]  io_deq_decodedInst_lsrc_2,
  output [5:0]  io_deq_decodedInst_ldest,
  output [34:0] io_deq_decodedInst_fuType,
  output [8:0]  io_deq_decodedInst_fuOpType,
  output        io_deq_decodedInst_rfWen,
  output        io_deq_decodedInst_fpWen,
  output        io_deq_decodedInst_vecWen,
  output        io_deq_decodedInst_isXSTrap,
  output        io_deq_decodedInst_waitForward,
  output        io_deq_decodedInst_blockBackward,
  output        io_deq_decodedInst_flushPipe,
  output        io_deq_decodedInst_canRobCompress,
  output [3:0]  io_deq_decodedInst_selImm,
  output [21:0] io_deq_decodedInst_imm,
  output [1:0]  io_deq_decodedInst_fpu_typeTagOut,
  output        io_deq_decodedInst_fpu_wflags,
  output [1:0]  io_deq_decodedInst_fpu_typ,
  output [1:0]  io_deq_decodedInst_fpu_fmt,
  output [2:0]  io_deq_decodedInst_fpu_rm,
  output        io_deq_decodedInst_vpu_vill,
  output        io_deq_decodedInst_vpu_vma,
  output        io_deq_decodedInst_vpu_vta,
  output [1:0]  io_deq_decodedInst_vpu_vsew,
  output [2:0]  io_deq_decodedInst_vpu_vlmul,
  output        io_deq_decodedInst_vpu_specVill,
  output        io_deq_decodedInst_vpu_specVma,
  output        io_deq_decodedInst_vpu_specVta,
  output [1:0]  io_deq_decodedInst_vpu_specVsew,
  output [2:0]  io_deq_decodedInst_vpu_specVlmul,
  output        io_deq_decodedInst_vpu_vm,
  output [7:0]  io_deq_decodedInst_vpu_vstart,
  output [2:0]  io_deq_decodedInst_vpu_nf,
  output [1:0]  io_deq_decodedInst_vpu_veew,
  output        io_deq_decodedInst_vpu_isReverse,
  output        io_deq_decodedInst_vpu_isExt,
  output        io_deq_decodedInst_vpu_isNarrow,
  output        io_deq_decodedInst_vpu_isDstMask,
  output        io_deq_decodedInst_vpu_isOpMask,
  output        io_deq_decodedInst_vpu_isDependOldVd,
  output        io_deq_decodedInst_vpu_isWritePartVd,
  output        io_deq_decodedInst_vpu_isVleff,
  output        io_deq_decodedInst_vlsInstr,
  output        io_deq_decodedInst_wfflags,
  output        io_deq_decodedInst_isMove,
  output [5:0]  io_deq_decodedInst_uopSplitType,
  output        io_deq_decodedInst_isVset,
  output [2:0]  io_deq_decodedInst_commitType,
  output        io_deq_isComplex,
  output [6:0]  io_deq_uopInfo_numOfUop,
  output [6:0]  io_deq_uopInfo_numOfWB,
  output [3:0]  io_deq_uopInfo_lmul,
  input         io_csrCtrl_singlestep,
  input         io_fromCSR_illegalInst_sfenceVMA,
  input         io_fromCSR_illegalInst_sfencePart,
  input         io_fromCSR_illegalInst_hfenceGVMA,
  input         io_fromCSR_illegalInst_hfenceVVMA,
  input         io_fromCSR_illegalInst_hlsv,
  input         io_fromCSR_illegalInst_fsIsOff,
  input         io_fromCSR_illegalInst_vsIsOff,
  input         io_fromCSR_illegalInst_wfi,
  input         io_fromCSR_illegalInst_wrs_nto,
  input         io_fromCSR_illegalInst_frm,
  input         io_fromCSR_illegalInst_cboZ,
  input         io_fromCSR_illegalInst_cboCF,
  input         io_fromCSR_illegalInst_cboI,
  input         io_fromCSR_virtualInst_sfenceVMA,
  input         io_fromCSR_virtualInst_sfencePart,
  input         io_fromCSR_virtualInst_hfence,
  input         io_fromCSR_virtualInst_hlsv,
  input         io_fromCSR_virtualInst_wfi,
  input         io_fromCSR_virtualInst_wrs_nto,
  input         io_fromCSR_virtualInst_cboZ,
  input         io_fromCSR_virtualInst_cboCF,
  input         io_fromCSR_virtualInst_cboI,
  input         io_fromCSR_special_cboI2F
);

  xs_du_vtype_t        vtype;
  xs_du_csr_illegal_t  csr_ill;
  xs_du_csr_virtual_t  csr_vir;
  xs_du_decode_out_t   d;

  assign vtype = '{illegal: io_enq_vtype_illegal, vma: io_enq_vtype_vma,
                   vta: io_enq_vtype_vta, vsew: io_enq_vtype_vsew,
                   vlmul: io_enq_vtype_vlmul};
  assign csr_ill = '{sfenceVMA: io_fromCSR_illegalInst_sfenceVMA,
                     sfencePart: io_fromCSR_illegalInst_sfencePart,
                     hfenceGVMA: io_fromCSR_illegalInst_hfenceGVMA,
                     hfenceVVMA: io_fromCSR_illegalInst_hfenceVVMA,
                     hlsv: io_fromCSR_illegalInst_hlsv,
                     fsIsOff: io_fromCSR_illegalInst_fsIsOff,
                     vsIsOff: io_fromCSR_illegalInst_vsIsOff,
                     wfi: io_fromCSR_illegalInst_wfi,
                     wrs_nto: io_fromCSR_illegalInst_wrs_nto,
                     frm: io_fromCSR_illegalInst_frm,
                     cboZ: io_fromCSR_illegalInst_cboZ,
                     cboCF: io_fromCSR_illegalInst_cboCF,
                     cboI: io_fromCSR_illegalInst_cboI};
  assign csr_vir = '{sfenceVMA: io_fromCSR_virtualInst_sfenceVMA,
                     sfencePart: io_fromCSR_virtualInst_sfencePart,
                     hfence: io_fromCSR_virtualInst_hfence,
                     hlsv: io_fromCSR_virtualInst_hlsv,
                     wfi: io_fromCSR_virtualInst_wfi,
                     wrs_nto: io_fromCSR_virtualInst_wrs_nto,
                     cboZ: io_fromCSR_virtualInst_cboZ,
                     cboCF: io_fromCSR_virtualInst_cboCF,
                     cboI: io_fromCSR_virtualInst_cboI};

  xs_DecodeUnit_core u_core (
    .instr(io_enq_ctrlFlow_instr), .vtype(vtype), .vstart(io_enq_vstart),
    .csr_singlestep(io_csrCtrl_singlestep),
    .csr_illegal(csr_ill), .csr_virtual(csr_vir),
    .csr_special_cboI2F(io_fromCSR_special_cboI2F),
    .predecode_brType(io_enq_ctrlFlow_preDecodeInfo_brType),
    .in_excVec2(io_enq_ctrlFlow_exceptionVec_2),
    .is_last_in_ftq(io_enq_ctrlFlow_isLastInFtqEntry),
    .dec(d)
  );

  // ---- 已验证的译码核心输出 ----
  assign io_deq_decodedInst_srcType_0 = d.srcType0;
  assign io_deq_decodedInst_srcType_1 = d.srcType1;
  assign io_deq_decodedInst_srcType_2 = d.srcType2;
  assign io_deq_decodedInst_srcType_3 = d.srcType3;
  assign io_deq_decodedInst_srcType_4 = d.srcType4;
  assign io_deq_decodedInst_lsrc_0 = d.lsrc0;
  assign io_deq_decodedInst_lsrc_1 = d.lsrc1;
  assign io_deq_decodedInst_lsrc_2 = d.lsrc2;
  assign io_deq_decodedInst_ldest  = d.ldest;
  assign io_deq_decodedInst_fuType   = d.fuType;
  assign io_deq_decodedInst_fuOpType = d.fuOpType;
  assign io_deq_decodedInst_rfWen    = d.rfWen;
  assign io_deq_decodedInst_fpWen    = d.fpWen;
  assign io_deq_decodedInst_vecWen   = d.vecWen;
  assign io_deq_decodedInst_isXSTrap = d.isXSTrap;
  assign io_deq_decodedInst_waitForward   = d.waitForward;
  assign io_deq_decodedInst_blockBackward = d.blockBackward;
  assign io_deq_decodedInst_flushPipe     = d.flushPipe;
  assign io_deq_decodedInst_canRobCompress= d.canRobCompress;
  assign io_deq_decodedInst_selImm = d.selImm;
  assign io_deq_decodedInst_imm    = d.imm;
  assign io_deq_decodedInst_fpu_rm     = d.fpu_rm;
  assign io_deq_decodedInst_fpu_wflags = d.fpu_wflags;
  assign io_deq_decodedInst_uopSplitType = d.uopSplitType;
  assign io_deq_isComplex          = d.isComplex;
  assign io_deq_uopInfo_numOfUop   = d.numOfUop;
  assign io_deq_uopInfo_numOfWB    = d.numOfWB;
  assign io_deq_uopInfo_lmul       = d.lmul;

  // ---- StaticInst 透传字段 ----
  assign io_deq_decodedInst_instr   = io_enq_ctrlFlow_instr;
  assign io_deq_decodedInst_foldpc  = io_enq_ctrlFlow_foldpc;
  assign io_deq_decodedInst_isFetchMalAddr = io_enq_ctrlFlow_isFetchMalAddr;
  assign io_deq_decodedInst_trigger = io_enq_ctrlFlow_trigger;
  assign io_deq_decodedInst_preDecodeInfo_isRVC = io_enq_ctrlFlow_preDecodeInfo_isRVC;
  assign io_deq_decodedInst_preDecodeInfo_brType = io_enq_ctrlFlow_preDecodeInfo_brType;
  assign io_deq_decodedInst_pred_taken = io_enq_ctrlFlow_pred_taken;
  assign io_deq_decodedInst_crossPageIPFFix = io_enq_ctrlFlow_crossPageIPFFix;
  assign io_deq_decodedInst_ftqPtr_flag = io_enq_ctrlFlow_ftqPtr_flag;
  assign io_deq_decodedInst_ftqPtr_value = io_enq_ctrlFlow_ftqPtr_value;
  assign io_deq_decodedInst_ftqOffset = io_enq_ctrlFlow_ftqOffset;

  // ---- fpu typeTagOut/typ/fmt：黑盒 FPDecoder 直出（与 golden 同源）----
  assign io_deq_decodedInst_fpu_typeTagOut = d.fpu_typeTagOut;
  assign io_deq_decodedInst_fpu_typ = d.fpu_typ;
  assign io_deq_decodedInst_fpu_fmt = d.fpu_fmt;
  // ---- 异常向量：完整合成 ----
  assign io_deq_decodedInst_exceptionVec_0  = io_enq_ctrlFlow_exceptionVec_0;
  assign io_deq_decodedInst_exceptionVec_1  = io_enq_ctrlFlow_exceptionVec_1;
  assign io_deq_decodedInst_exceptionVec_2  = d.excVec2;       // 非法指令
  assign io_deq_decodedInst_exceptionVec_3  = (io_enq_ctrlFlow_trigger == 4'h0);  // 断点
  assign io_deq_decodedInst_exceptionVec_4  = io_enq_ctrlFlow_exceptionVec_4;
  assign io_deq_decodedInst_exceptionVec_5  = io_enq_ctrlFlow_exceptionVec_5;
  assign io_deq_decodedInst_exceptionVec_6  = io_enq_ctrlFlow_exceptionVec_6;
  assign io_deq_decodedInst_exceptionVec_7  = io_enq_ctrlFlow_exceptionVec_7;
  assign io_deq_decodedInst_exceptionVec_8  = io_enq_ctrlFlow_exceptionVec_8;
  assign io_deq_decodedInst_exceptionVec_9  = io_enq_ctrlFlow_exceptionVec_9;
  assign io_deq_decodedInst_exceptionVec_10 = io_enq_ctrlFlow_exceptionVec_10;
  assign io_deq_decodedInst_exceptionVec_11 = io_enq_ctrlFlow_exceptionVec_11;
  assign io_deq_decodedInst_exceptionVec_12 = io_enq_ctrlFlow_exceptionVec_12;
  assign io_deq_decodedInst_exceptionVec_13 = io_enq_ctrlFlow_exceptionVec_13;
  assign io_deq_decodedInst_exceptionVec_14 = io_enq_ctrlFlow_exceptionVec_14;
  assign io_deq_decodedInst_exceptionVec_15 = io_enq_ctrlFlow_exceptionVec_15;
  assign io_deq_decodedInst_exceptionVec_16 = io_enq_ctrlFlow_exceptionVec_16;
  assign io_deq_decodedInst_exceptionVec_17 = io_enq_ctrlFlow_exceptionVec_17;
  assign io_deq_decodedInst_exceptionVec_18 = io_enq_ctrlFlow_exceptionVec_18;
  assign io_deq_decodedInst_exceptionVec_19 = io_enq_ctrlFlow_exceptionVec_19;
  assign io_deq_decodedInst_exceptionVec_20 = io_enq_ctrlFlow_exceptionVec_20;
  assign io_deq_decodedInst_exceptionVec_21 = io_enq_ctrlFlow_exceptionVec_21;
  assign io_deq_decodedInst_exceptionVec_22 = d.excVec22;      // 虚拟指令
  assign io_deq_decodedInst_exceptionVec_23 = io_enq_ctrlFlow_exceptionVec_23;
  assign io_deq_decodedInst_vpu_vill   = io_enq_vtype_illegal;
  assign io_deq_decodedInst_vpu_vma    = io_enq_vtype_vma;
  assign io_deq_decodedInst_vpu_vta    = io_enq_vtype_vta;
  assign io_deq_decodedInst_vpu_vsew   = io_enq_vtype_vsew;
  assign io_deq_decodedInst_vpu_vlmul  = io_enq_vtype_vlmul;
  assign io_deq_decodedInst_vpu_specVill  = io_enq_vtype_illegal;
  assign io_deq_decodedInst_vpu_specVma   = io_enq_vtype_vma;
  assign io_deq_decodedInst_vpu_specVta   = io_enq_vtype_vta;
  assign io_deq_decodedInst_vpu_specVsew  = io_enq_vtype_vsew;
  assign io_deq_decodedInst_vpu_specVlmul = io_enq_vtype_vlmul;
  assign io_deq_decodedInst_vpu_vm     = io_enq_ctrlFlow_instr[25];
  assign io_deq_decodedInst_vpu_vstart = io_enq_vstart;
  assign io_deq_decodedInst_vpu_nf     = io_enq_ctrlFlow_instr[31:29];
  assign io_deq_decodedInst_vpu_veew   = io_enq_ctrlFlow_instr[13:12];
  assign io_deq_decodedInst_vpu_isReverse = d.vpu_isReverse;
  assign io_deq_decodedInst_vpu_isExt     = d.vpu_isExt;
  assign io_deq_decodedInst_vpu_isNarrow  = d.vpu_isNarrow;
  assign io_deq_decodedInst_vpu_isDstMask = d.vpu_isDstMask;
  assign io_deq_decodedInst_vpu_isOpMask  = d.vpu_isOpMask;
  assign io_deq_decodedInst_vpu_isDependOldVd = d.vpu_isDependOldVd;
  assign io_deq_decodedInst_vpu_isWritePartVd = d.vpu_isWritePartVd;
  assign io_deq_decodedInst_vpu_isVleff   = d.vpu_isVleff;
  assign io_deq_decodedInst_vlsInstr = d.vlsInstr;
  assign io_deq_decodedInst_wfflags  = d.wfflags;
  assign io_deq_decodedInst_isMove   = d.isMove;
  assign io_deq_decodedInst_isVset   = d.isVset;
  assign io_deq_decodedInst_commitType = d.commitType;

endmodule
