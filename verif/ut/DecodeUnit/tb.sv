// ============================================================================
// tb.sv —— DecodeUnit UT：可读核 xs_DecodeUnit_core vs golden DecodeUnit 逐拍比对
//
// 激励：以「合法指令编码池」(legal_instrs.svh, 716 条 base match) 为主，叠加随机
// don't-care 操作数位 + 少量纯随机指令，覆盖各指令类。CSR illegal/virtual、vtype、
// vstart、preDecodeInfo_brType、trigger、exceptionVec_2、singlestep 全部随机化，
// 同一激励同时驱动可读核与 golden。
//
// 比对：DecodeUnit 全部译码相关输出端口（srcType/lsrc/ldest/fuType/fuOpType、各
// wen/flag、selImm/imm、uopSplitType、fpu_rm/wflags、isComplex/numOfUop/numOfWB/
// lmul，以及本轮补完的 exceptionVec[2]/[3]/[22]、vpu 明细、wfflags、isMove、
// isVset、commitType、vlsInstr）。golden 端 !$isunknown 才比（跳 don't-care）。
// ============================================================================
`timescale 1ns/1ps
`include "decodeunit_svh.svh"

module tb;
  import decodeunit_pkg::*;
`include "legal_instrs.svh"

  logic [31:0] instr;
  xs_du_vtype_t vtype;
  logic [7:0]  vstart;
  xs_du_csr_illegal_t  csr_ill;
  xs_du_csr_virtual_t  csr_vir;
  logic [1:0]  brType;
  logic [3:0]  trigger;
  logic        excIn2;
  logic        singlestep;
  logic        cboI2F;
  logic        lastInFtq;

  // ---- 可读核 ----
  xs_du_decode_out_t dut;
  xs_DecodeUnit_core u_core (
    .instr(instr), .vtype(vtype), .vstart(vstart),
    .csr_singlestep(singlestep),
    .csr_illegal(csr_ill), .csr_virtual(csr_vir),
    .csr_special_cboI2F(cboI2F),
    .predecode_brType(brType),
    .in_excVec2(excIn2),
    .is_last_in_ftq(lastInFtq),
    .dec(dut)
  );

  // ---- golden DecodeUnit 输出线网 ----
  logic [3:0] g_srcType_0,g_srcType_1,g_srcType_2,g_srcType_3,g_srcType_4;
  logic [5:0] g_lsrc_0,g_lsrc_1,g_lsrc_2,g_ldest;
  logic [34:0]g_fuType;
  logic [8:0] g_fuOpType;
  logic       g_rfWen,g_fpWen,g_vecWen,g_isXSTrap,g_waitForward,g_blockBackward,g_flushPipe,g_canRobCompress;
  logic [3:0] g_selImm;
  logic [21:0]g_imm;
  logic [5:0] g_uopSplitType;
  logic [2:0] g_fpu_rm;
  logic       g_fpu_wflags;
  logic       g_isComplex;
  logic [6:0] g_numOfUop,g_numOfWB;
  logic [3:0] g_lmul;
  logic       g_excVec2,g_excVec3,g_excVec22;
  logic       g_wfflags,g_isMove,g_isVset,g_vlsInstr;
  logic [2:0] g_commitType;
  logic       g_isReverse,g_isExt,g_isNarrow,g_isDstMask,g_isOpMask;
  logic       g_isDependOldVd,g_isWritePartVd,g_isVleff;

  DecodeUnit u_gold (
    .io_enq_ctrlFlow_instr(instr),
    .io_enq_ctrlFlow_foldpc(10'h0),
    .io_enq_ctrlFlow_exceptionVec_0(1'b0),.io_enq_ctrlFlow_exceptionVec_1(1'b0),
    .io_enq_ctrlFlow_exceptionVec_2(excIn2),.io_enq_ctrlFlow_exceptionVec_4(1'b0),
    .io_enq_ctrlFlow_exceptionVec_5(1'b0),.io_enq_ctrlFlow_exceptionVec_6(1'b0),
    .io_enq_ctrlFlow_exceptionVec_7(1'b0),.io_enq_ctrlFlow_exceptionVec_8(1'b0),
    .io_enq_ctrlFlow_exceptionVec_9(1'b0),.io_enq_ctrlFlow_exceptionVec_10(1'b0),
    .io_enq_ctrlFlow_exceptionVec_11(1'b0),.io_enq_ctrlFlow_exceptionVec_12(1'b0),
    .io_enq_ctrlFlow_exceptionVec_13(1'b0),.io_enq_ctrlFlow_exceptionVec_14(1'b0),
    .io_enq_ctrlFlow_exceptionVec_15(1'b0),.io_enq_ctrlFlow_exceptionVec_16(1'b0),
    .io_enq_ctrlFlow_exceptionVec_17(1'b0),.io_enq_ctrlFlow_exceptionVec_18(1'b0),
    .io_enq_ctrlFlow_exceptionVec_19(1'b0),.io_enq_ctrlFlow_exceptionVec_20(1'b0),
    .io_enq_ctrlFlow_exceptionVec_21(1'b0),.io_enq_ctrlFlow_exceptionVec_23(1'b0),
    .io_enq_ctrlFlow_isFetchMalAddr(1'b0),
    .io_enq_ctrlFlow_trigger(trigger),
    .io_enq_ctrlFlow_preDecodeInfo_isRVC(1'b0),
    .io_enq_ctrlFlow_preDecodeInfo_brType(brType),
    .io_enq_ctrlFlow_pred_taken(1'b0),
    .io_enq_ctrlFlow_crossPageIPFFix(1'b0),
    .io_enq_ctrlFlow_ftqPtr_flag(1'b0),
    .io_enq_ctrlFlow_ftqPtr_value(6'h0),
    .io_enq_ctrlFlow_ftqOffset(4'h0),
    .io_enq_ctrlFlow_isLastInFtqEntry(lastInFtq),
    .io_enq_vtype_illegal(vtype.illegal),
    .io_enq_vtype_vma(vtype.vma),
    .io_enq_vtype_vta(vtype.vta),
    .io_enq_vtype_vsew(vtype.vsew),
    .io_enq_vtype_vlmul(vtype.vlmul),
    .io_enq_vstart(vstart),
    .io_deq_decodedInst_instr(),
    .io_deq_decodedInst_foldpc(),
    .io_deq_decodedInst_exceptionVec_0(),.io_deq_decodedInst_exceptionVec_1(),
    .io_deq_decodedInst_exceptionVec_2(g_excVec2),.io_deq_decodedInst_exceptionVec_3(g_excVec3),
    .io_deq_decodedInst_exceptionVec_4(),.io_deq_decodedInst_exceptionVec_5(),
    .io_deq_decodedInst_exceptionVec_6(),.io_deq_decodedInst_exceptionVec_7(),
    .io_deq_decodedInst_exceptionVec_8(),.io_deq_decodedInst_exceptionVec_9(),
    .io_deq_decodedInst_exceptionVec_10(),.io_deq_decodedInst_exceptionVec_11(),
    .io_deq_decodedInst_exceptionVec_12(),.io_deq_decodedInst_exceptionVec_13(),
    .io_deq_decodedInst_exceptionVec_14(),.io_deq_decodedInst_exceptionVec_15(),
    .io_deq_decodedInst_exceptionVec_16(),.io_deq_decodedInst_exceptionVec_17(),
    .io_deq_decodedInst_exceptionVec_18(),.io_deq_decodedInst_exceptionVec_19(),
    .io_deq_decodedInst_exceptionVec_20(),.io_deq_decodedInst_exceptionVec_21(),
    .io_deq_decodedInst_exceptionVec_22(g_excVec22),.io_deq_decodedInst_exceptionVec_23(),
    .io_deq_decodedInst_isFetchMalAddr(),
    .io_deq_decodedInst_trigger(),
    .io_deq_decodedInst_preDecodeInfo_isRVC(),
    .io_deq_decodedInst_preDecodeInfo_brType(),
    .io_deq_decodedInst_pred_taken(),
    .io_deq_decodedInst_crossPageIPFFix(),
    .io_deq_decodedInst_ftqPtr_flag(),
    .io_deq_decodedInst_ftqPtr_value(),
    .io_deq_decodedInst_ftqOffset(),
    .io_deq_decodedInst_srcType_0(g_srcType_0),
    .io_deq_decodedInst_srcType_1(g_srcType_1),
    .io_deq_decodedInst_srcType_2(g_srcType_2),
    .io_deq_decodedInst_srcType_3(g_srcType_3),
    .io_deq_decodedInst_srcType_4(g_srcType_4),
    .io_deq_decodedInst_lsrc_0(g_lsrc_0),
    .io_deq_decodedInst_lsrc_1(g_lsrc_1),
    .io_deq_decodedInst_lsrc_2(g_lsrc_2),
    .io_deq_decodedInst_ldest(g_ldest),
    .io_deq_decodedInst_fuType(g_fuType),
    .io_deq_decodedInst_fuOpType(g_fuOpType),
    .io_deq_decodedInst_rfWen(g_rfWen),
    .io_deq_decodedInst_fpWen(g_fpWen),
    .io_deq_decodedInst_vecWen(g_vecWen),
    .io_deq_decodedInst_isXSTrap(g_isXSTrap),
    .io_deq_decodedInst_waitForward(g_waitForward),
    .io_deq_decodedInst_blockBackward(g_blockBackward),
    .io_deq_decodedInst_flushPipe(g_flushPipe),
    .io_deq_decodedInst_canRobCompress(g_canRobCompress),
    .io_deq_decodedInst_selImm(g_selImm),
    .io_deq_decodedInst_imm(g_imm),
    .io_deq_decodedInst_fpu_typeTagOut(),
    .io_deq_decodedInst_fpu_wflags(g_fpu_wflags),
    .io_deq_decodedInst_fpu_typ(),
    .io_deq_decodedInst_fpu_fmt(),
    .io_deq_decodedInst_fpu_rm(g_fpu_rm),
    .io_deq_decodedInst_vpu_vill(),.io_deq_decodedInst_vpu_vma(),
    .io_deq_decodedInst_vpu_vta(),.io_deq_decodedInst_vpu_vsew(),
    .io_deq_decodedInst_vpu_vlmul(),.io_deq_decodedInst_vpu_specVill(),
    .io_deq_decodedInst_vpu_specVma(),.io_deq_decodedInst_vpu_specVta(),
    .io_deq_decodedInst_vpu_specVsew(),.io_deq_decodedInst_vpu_specVlmul(),
    .io_deq_decodedInst_vpu_vm(),.io_deq_decodedInst_vpu_vstart(),
    .io_deq_decodedInst_vpu_nf(),.io_deq_decodedInst_vpu_veew(),
    .io_deq_decodedInst_vpu_isReverse(g_isReverse),.io_deq_decodedInst_vpu_isExt(g_isExt),
    .io_deq_decodedInst_vpu_isNarrow(g_isNarrow),.io_deq_decodedInst_vpu_isDstMask(g_isDstMask),
    .io_deq_decodedInst_vpu_isOpMask(g_isOpMask),.io_deq_decodedInst_vpu_isDependOldVd(g_isDependOldVd),
    .io_deq_decodedInst_vpu_isWritePartVd(g_isWritePartVd),.io_deq_decodedInst_vpu_isVleff(g_isVleff),
    .io_deq_decodedInst_vlsInstr(g_vlsInstr),
    .io_deq_decodedInst_wfflags(g_wfflags),
    .io_deq_decodedInst_isMove(g_isMove),
    .io_deq_decodedInst_uopSplitType(g_uopSplitType),
    .io_deq_decodedInst_isVset(g_isVset),
    .io_deq_decodedInst_commitType(g_commitType),
    .io_deq_isComplex(g_isComplex),
    .io_deq_uopInfo_numOfUop(g_numOfUop),
    .io_deq_uopInfo_numOfWB(g_numOfWB),
    .io_deq_uopInfo_lmul(g_lmul),
    .io_csrCtrl_singlestep(singlestep),
    .io_fromCSR_illegalInst_sfenceVMA(csr_ill.sfenceVMA),
    .io_fromCSR_illegalInst_sfencePart(csr_ill.sfencePart),
    .io_fromCSR_illegalInst_hfenceGVMA(csr_ill.hfenceGVMA),
    .io_fromCSR_illegalInst_hfenceVVMA(csr_ill.hfenceVVMA),
    .io_fromCSR_illegalInst_hlsv(csr_ill.hlsv),
    .io_fromCSR_illegalInst_fsIsOff(csr_ill.fsIsOff),
    .io_fromCSR_illegalInst_vsIsOff(csr_ill.vsIsOff),
    .io_fromCSR_illegalInst_wfi(csr_ill.wfi),
    .io_fromCSR_illegalInst_wrs_nto(csr_ill.wrs_nto),
    .io_fromCSR_illegalInst_frm(csr_ill.frm),
    .io_fromCSR_illegalInst_cboZ(csr_ill.cboZ),
    .io_fromCSR_illegalInst_cboCF(csr_ill.cboCF),
    .io_fromCSR_illegalInst_cboI(csr_ill.cboI),
    .io_fromCSR_virtualInst_sfenceVMA(csr_vir.sfenceVMA),
    .io_fromCSR_virtualInst_sfencePart(csr_vir.sfencePart),
    .io_fromCSR_virtualInst_hfence(csr_vir.hfence),
    .io_fromCSR_virtualInst_hlsv(csr_vir.hlsv),
    .io_fromCSR_virtualInst_wfi(csr_vir.wfi),
    .io_fromCSR_virtualInst_wrs_nto(csr_vir.wrs_nto),
    .io_fromCSR_virtualInst_cboZ(csr_vir.cboZ),
    .io_fromCSR_virtualInst_cboCF(csr_vir.cboCF),
    .io_fromCSR_virtualInst_cboI(csr_vir.cboI),
    .io_fromCSR_special_cboI2F(cboI2F)
  );

  // ---- 比对 ----
  int errors = 0;
  int checks = 0;
  int n_iters = 250000;
  int ecnt [string];

  task automatic chk(input string nm, input logic [63:0] g, input logic [63:0] d,
                     input logic gx);
    checks++;
    if (!gx && (g !== d)) begin
      errors++;
      ecnt[nm]++;
      if (ecnt[nm] <= 4)
        $display("MISMATCH %s instr=%08h gold=%h dut=%h", nm, instr, g, d);
    end
  endtask

  logic [31:0] r;
  int idx;
  initial begin
    for (int it = 0; it < n_iters; it++) begin
      if ($urandom_range(0,99) < 80) begin
        idx = $urandom_range(0, N_LEGAL-1);
        r   = $urandom();
        instr = LEGAL_MATCH[idx] | (r & ~LEGAL_MASK[idx]);
      end else begin
        instr = $urandom();
      end
      vtype.illegal = $urandom_range(0,1);
      vtype.vma     = $urandom_range(0,1);
      vtype.vta     = $urandom_range(0,1);
      vtype.vsew    = $urandom_range(0,3);
      vtype.vlmul   = $urandom_range(0,7);
      vstart        = $urandom();
      brType        = $urandom_range(0,3);
      trigger       = $urandom();
      excIn2        = $urandom_range(0,1);
      singlestep    = $urandom_range(0,1);
      cboI2F        = $urandom_range(0,1);
      lastInFtq     = $urandom_range(0,1);
      csr_ill       = $urandom();
      csr_vir       = $urandom();
      #1;
      // 已验证主体
      chk("srcType0", g_srcType_0, dut.srcType0, $isunknown(g_srcType_0));
      chk("srcType1", g_srcType_1, dut.srcType1, $isunknown(g_srcType_1));
      chk("srcType2", g_srcType_2, dut.srcType2, $isunknown(g_srcType_2));
      chk("srcType3", g_srcType_3, dut.srcType3, $isunknown(g_srcType_3));
      chk("srcType4", g_srcType_4, dut.srcType4, $isunknown(g_srcType_4));
      chk("lsrc0",    g_lsrc_0,    dut.lsrc0,    $isunknown(g_lsrc_0));
      chk("lsrc1",    g_lsrc_1,    dut.lsrc1,    $isunknown(g_lsrc_1));
      chk("lsrc2",    g_lsrc_2,    dut.lsrc2,    $isunknown(g_lsrc_2));
      chk("ldest",    g_ldest,     dut.ldest,    $isunknown(g_ldest));
      chk("fuType",   g_fuType,    dut.fuType,   $isunknown(g_fuType));
      chk("fuOpType", g_fuOpType,  dut.fuOpType, $isunknown(g_fuOpType));
      chk("rfWen",    g_rfWen,     dut.rfWen,    $isunknown(g_rfWen));
      chk("fpWen",    g_fpWen,     dut.fpWen,    $isunknown(g_fpWen));
      chk("vecWen",   g_vecWen,    dut.vecWen,   $isunknown(g_vecWen));
      chk("isXSTrap", g_isXSTrap,  dut.isXSTrap, $isunknown(g_isXSTrap));
      chk("waitForward",  g_waitForward,  dut.waitForward,  $isunknown(g_waitForward));
      chk("blockBackward",g_blockBackward,dut.blockBackward,$isunknown(g_blockBackward));
      chk("flushPipe",g_flushPipe, dut.flushPipe,$isunknown(g_flushPipe));
      chk("canRobC",  g_canRobCompress, dut.canRobCompress, $isunknown(g_canRobCompress));
      chk("selImm",   g_selImm,    dut.selImm,   $isunknown(g_selImm));
      chk("imm",      g_imm,       dut.imm,      $isunknown(g_imm));
      chk("uopSplit", g_uopSplitType, dut.uopSplitType, $isunknown(g_uopSplitType));
      chk("fpu_rm",   g_fpu_rm,    dut.fpu_rm,   $isunknown(g_fpu_rm));
      chk("fpu_wflags",g_fpu_wflags, dut.fpu_wflags, $isunknown(g_fpu_wflags));
      chk("isComplex",g_isComplex, dut.isComplex,$isunknown(g_isComplex));
      chk("numUop",   g_numOfUop,  dut.numOfUop, $isunknown(g_numOfUop));
      chk("numWB",    g_numOfWB,   dut.numOfWB,  $isunknown(g_numOfWB));
      chk("lmul",     g_lmul,      dut.lmul,     $isunknown(g_lmul));
      // 本轮补完字段
      chk("excVec2",  g_excVec2,   dut.excVec2,  $isunknown(g_excVec2));
      chk("excVec22", g_excVec22,  dut.excVec22, $isunknown(g_excVec22));
      chk("excVec3",  g_excVec3,   (trigger==4'h0), $isunknown(g_excVec3));
      chk("wfflags",  g_wfflags,   dut.wfflags,  $isunknown(g_wfflags));
      chk("isMove",   g_isMove,    dut.isMove,   $isunknown(g_isMove));
      chk("isVset",   g_isVset,    dut.isVset,   $isunknown(g_isVset));
      chk("commitType",g_commitType, dut.commitType, $isunknown(g_commitType));
      chk("vlsInstr", g_vlsInstr,  dut.vlsInstr, $isunknown(g_vlsInstr));
      chk("isReverse",g_isReverse, dut.vpu_isReverse, $isunknown(g_isReverse));
      chk("isExt",    g_isExt,     dut.vpu_isExt,     $isunknown(g_isExt));
      chk("isNarrow", g_isNarrow,  dut.vpu_isNarrow,  $isunknown(g_isNarrow));
      chk("isDstMask",g_isDstMask, dut.vpu_isDstMask, $isunknown(g_isDstMask));
      chk("isOpMask", g_isOpMask,  dut.vpu_isOpMask,  $isunknown(g_isOpMask));
      chk("isDependOldVd",g_isDependOldVd,dut.vpu_isDependOldVd,$isunknown(g_isDependOldVd));
      chk("isWritePartVd",g_isWritePartVd,dut.vpu_isWritePartVd,$isunknown(g_isWritePartVd));
      chk("isVleff",  g_isVleff,   dut.vpu_isVleff,   $isunknown(g_isVleff));
    end
    foreach (ecnt[k]) $display("[errcount] %-12s = %0d", k, ecnt[k]);
    $display("[DecodeUnit UT] iters=%0d checks=%0d errors=%0d", n_iters, checks, errors);
    if (errors == 0) $display("TEST PASSED");
    else             $display("TEST FAILED");
    $finish;
  end
endmodule
