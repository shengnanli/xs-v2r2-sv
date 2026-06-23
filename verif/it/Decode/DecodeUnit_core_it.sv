// ============================================================================
// DecodeUnit.sv —— 香山 V2R2（昆明湖）后端单指令译码器（可读重写，可读核）
//
// 在后端的位置：前端 IBuffer/RVCExpander 送来一条已展开的 32 位指令，DecodeUnit
// 把它译码成一条微操作 (uop) 的控制信息，交给重命名 Rename。
//
// 译码核心是一张 ISA 真值表（Chisel ListLookup）：指令编码 → (fuType/fuOpType/
// srcType/selImm/各控制 flag/uopSplitType)。这张表是纯 ISA 数据，由
// scripts/gen_decodeunit.py 从 golden 真值表可靠提取，存于 decodeunit_pkg.sv 的
// 具名结构 DECODE_BITS/DECODE_MASK/DECODE_MATCH（712 条 pattern）。
//
// 本核做：查表 → 立即数抽取 → 确定性覆盖逻辑（csrrVl/Vlenb/prefetch/zimop/fli/
// cbo）→ srcType/lsrc 组装 → 黑盒 FPDecoder_it 取浮点控制位 → 异常合成。
// 覆盖逻辑的常量值（如 prefetch fuOpType=0xA/0x9/0x8）直接取自 golden 的最终
// io_deq 赋值表达式，保证与 golden 等价。
//
// 子模块 FPDecoder_it / UopInfoGen_it 作为 golden 黑盒例化。
// ============================================================================
`include "decodeunit_svh.svh"

module xs_DecodeUnit_core_it
  import decodeunit_pkg::*;
(
  input  logic [31:0]            instr,
  input  xs_du_vtype_t           vtype,
  input  logic [7:0]             vstart,
  input  logic                   csr_singlestep,
  input  xs_du_csr_illegal_t     csr_illegal,
  input  xs_du_csr_virtual_t     csr_virtual,
  input  logic                   csr_special_cboI2F,
  input  logic [1:0]             predecode_brType,  // 前端预译码分支类型（commitType 用）
  input  logic                   in_excVec2,        // 入口已有 exceptionVec[2]（透传 OR）
  input  logic                   is_last_in_ftq,    // FTQ entry 末条（禁止 ROB 压缩）
  output xs_du_decode_out_t      dec
);

  localparam int VLEN = 128;

  // --------------------------------------------------------------------------
  // 0. 指令字段抽取
  // --------------------------------------------------------------------------
  wire [6:0]  opcode = instr[6:0];
  wire [4:0]  opcode5= instr[6:2];
  wire [4:0]  rd     = instr[11:7];
  wire [2:0]  funct3 = instr[14:12];
  wire [4:0]  rs1    = instr[19:15];
  wire [4:0]  rs2    = instr[24:20];
  wire [6:0]  funct7 = instr[31:25];
  wire [11:0] csridx = instr[31:20];
  wire [4:0]  fs3    = instr[31:27];
  wire [4:0]  vd     = instr[11:7];
  wire        vm     = instr[25];
  wire [2:0]  nf     = instr[31:29];
  wire [2:0]  width3 = instr[14:12];
  wire [1:0]  mop    = instr[27:26];
  wire [4:0]  sumop  = instr[24:20];
  wire [1:0]  fmt    = instr[26:25];

  // --------------------------------------------------------------------------
  // 1. 译码表查表（priority match）
  //    表内 pattern 按 ISA 表序排列；用倒序遍历 + 后命中覆盖实现「表序优先」，
  //    未命中明确落 DECODE_DEFAULT（selImm=INVALID → 非法指令），避免 X。
  // --------------------------------------------------------------------------
  decode_bits_t db;
  always_comb begin
    db = DECODE_DEFAULT;
    for (int i = DECODE_TABLE_SIZE - 1; i >= 0; i--) begin
      if ((instr & DECODE_MASK[i]) == DECODE_MATCH[i])
        db = DECODE_BITS[i];
    end
  end

  wire [34:0] fu_raw  = db.fu_type;
  wire [8:0]  op_raw  = db.fu_op_type;
  wire [3:0]  sel_raw = db.sel_imm;

  // --------------------------------------------------------------------------
  // 2. 立即数抽取（按 selImm，对应 Scala ImmUnion + LookupTree）
  // --------------------------------------------------------------------------
  function automatic logic [21:0] extract_imm(input logic [3:0] sel,
                                              input logic [31:0] in);
    unique case (sel)
      SEL_I:        return {10'h0, in[31:20]};
      SEL_S:        return {10'h0, in[31:25], in[11:7]};
      SEL_SB:       return {10'h0, in[31], in[7], in[30:25], in[11:8]};
      SEL_U:        return {2'h0, in[31:12]};
      SEL_UJ:       return {2'h0, in[31], in[19:12], in[20], in[30:21]};
      SEL_Z:        return {in[11:7], in[19:15], in[31:20]};
      SEL_B6:       return {16'h0, in[25:20]};
      SEL_OPIVIS:   return {17'h0, in[19:15]};
      SEL_OPIVIU:   return {17'h0, in[19:15]};
      SEL_VSETVLI:  return {11'h0, in[30:20]};
      SEL_VSETIVLI: return {7'h0, in[19:15], in[29:20]};
      SEL_VRORVI:   return {15'h0, in[26], in[19:15]};
      default:      return 22'h0;
    endcase
  endfunction

  // --------------------------------------------------------------------------
  // 3. 确定性覆盖识别（与 Scala when 链对应；常量取自 golden 最终 io_deq 表达式）
  // --------------------------------------------------------------------------
  wire is_csr   = (opcode5 == 5'h1C) && (funct3[1:0] != 2'b00);
  // golden isCsrr = isCsr & instr[13] & rs1==0：只要 funct3[1] 置位（CSRRS/CSRRC
  // 系，含 imm 变体），不限定具体 funct3（原写法漏了 funct3==111 等 → c20073f2 等
  // 编码的 csrrVl/Vlenb 识别失败，FM 暴露）。
  wire is_csrr  = is_csr && funct3[1] && (rs1 == 5'h0);
  wire is_csrr_vlenb = is_csrr && (csridx == 12'hC22);  // CSRs.vlenb
  wire is_csrr_vl    = is_csrr && (csridx == 12'hC20);  // CSRs.vl
  wire is_csrr_ov    = is_csrr_vl || is_csrr_vlenb;

  wire is_softpref = (opcode == 7'b0010011) && (funct3 == 3'b110) && (rd == 5'h0);
  wire is_pre_w = is_softpref && (rs2 == 5'd3);
  wire is_pre_r = is_softpref && (rs2 == 5'd1);
  wire is_pre_i = is_softpref && (rs2 == 5'd0);
  wire is_pre   = is_pre_w || is_pre_r || is_pre_i;

  // zimop（两段 BitPat，见 Scala DecodeUnit.isZimop）
  //   b1?00??0111??_?????_100_?????_1110011
  //   b1?00??1?????_?????_100_?????_1110011
  wire is_zimop = (((instr & 32'hB3C0707F) == 32'h81C04073)) ||
                  (((instr & 32'hB200707F) == 32'h82004073));
  // golden isZimop 还需 rd!=0 & !singlestep 才作 move；此处仅用于 src/imm/lsrc 覆盖
  // （与 golden srcType/lsrc 的 isZimop 用法一致）

  wire is_fli = (funct7[6:2] == 5'b11110) && (rs2 == 5'h1) && (width3 == 3'h0)
                && (opcode5 == 5'h14);

  // cbo.inval = {instr[31:20],instr[14:0]} == 27'h200F（编码切片比较，见 golden）
  wire [26:0] cbo_slice = {instr[31:20], instr[14:0]};
  wire is_cbo_inval = (cbo_slice == 27'h200F);

  // --------------------------------------------------------------------------
  // 4. fuType 覆盖（csrr 改写 + vlsu→vseglsu 分段）
  //    vseglsu：NF≠0 的分段访存（whole-register 整寄存器搬运除外）。
  //    判定与 golden 一致：MOP≠00，或 MOP==00 且 LUMOP/SUMOP≠01000。
  // --------------------------------------------------------------------------
  wire is_vldu_raw = fu_raw[FU_VLDU];
  wire is_vstu_raw = fu_raw[FU_VSTU];
  wire nf_nz       = (nf != 3'h0);
  wire is_whole    = (mop == 2'b00) && (sumop == 5'b01000);  // 整寄存器搬运

  // fu_mid：golden 的 decodedInst_fuType（介于纯表 fu_raw 与最终 fu_ov 之间）——
  // 仅含「软件预取(非 csrr)→ldu」这一前置覆盖，不含 csrrVl/Vlenb/vseglsu 覆盖。
  // 派生字段（commitType/isDependOldVd/isVload/isVStore 等）按 golden 用此中间值；
  // 已用 5000 随机指令逐一核对 fu_mid == golden decodedInst_fuType（0 差异）。
  wire [34:0] fu_mid = (is_pre && !is_csrr_ov) ? (35'h1 << FU_LDU) : fu_raw;

  logic [34:0] fu_ov;
  always_comb begin
    if (is_csrr_vl)         fu_ov = (35'h1 << FU_VSETFWF);
    else if (is_csrr_vlenb) fu_ov = (35'h1 << FU_ALU);
    else if (is_pre)        fu_ov = (35'h1 << FU_LDU);
    else if (is_vstu_raw && nf_nz && !is_whole)
                            fu_ov = (35'h1 << FU_VSEGSTU);
    else if (is_vldu_raw && nf_nz && !is_whole)
                            fu_ov = (35'h1 << FU_VSEGLDU);
    else                    fu_ov = fu_raw;
  end

  // --------------------------------------------------------------------------
  // 5. fuOpType 覆盖（常量取自 golden io_deq_decodedInst_fuOpType）
  //    csrrVl→0x16  csrrVlenb→0x21  fli→{2'h1,fmt,rs1}
  //    preW→0xA  preR→0x9  preI→0x8  cboInval(cboI2F)→0xD
  // --------------------------------------------------------------------------
  logic [8:0] op_ov;
  always_comb begin
    if (is_csrr_vl)         op_ov = 9'h16;
    else if (is_csrr_vlenb) op_ov = 9'h21;
    else if (is_fli)        op_ov = {2'h1, fmt, rs1};
    else if (is_pre_w)      op_ov = 9'hA;
    else if (is_pre_r)      op_ov = 9'h9;
    else if (is_pre_i)      op_ov = 9'h8;
    else if (is_cbo_inval && csr_special_cboI2F) op_ov = 9'hD;
    else                    op_ov = op_raw;
  end

  // --------------------------------------------------------------------------
  // 6. selImm / imm 覆盖
  //    golden: selImm = csrrVl?decoder_14 : csrrVlenb?I : pre?S : decoder_14
  //    imm    = csrrVlenb?VLEN/8 : zimop?0 : extract(selImm)
  // --------------------------------------------------------------------------
  logic [3:0] sel_ov;
  always_comb begin
    if (is_csrr_vlenb)      sel_ov = SEL_I;
    else if (is_pre)        sel_ov = SEL_S;
    else                    sel_ov = sel_raw;
  end

  logic [21:0] imm_ov;
  always_comb begin
    if (is_csrr_vlenb)      imm_ov = 22'(VLEN/8);
    else if (is_zimop)      imm_ov = 22'h0;
    else                    imm_ov = extract_imm(sel_ov, instr);
  end

  // --------------------------------------------------------------------------
  // 7. srcType / lsrc（含 csrrVl/Vlenb/zimop 覆盖）
  //    golden: csrrVl  → src0/1/2=no(0)
  //            csrrVlenb→ src0=reg(1) src1=imm(0) src2=no(0)
  //            zimop   → src0=reg src1=imm, lsrc0=x0
  // --------------------------------------------------------------------------
  wire is_fma = (opcode5 == 5'b10000) || (opcode5 == 5'b10001)
             || (opcode5 == 5'b10010) || (opcode5 == 5'b10011);

  logic [3:0] st0, st1, st2;
  always_comb begin
    st0 = db.src_type0; st1 = db.src_type1; st2 = db.src_type2;
    if (is_csrr_vl) begin
      st0 = SRC_IMM_OR_PC; st1 = SRC_IMM_OR_PC; st2 = SRC_IMM_OR_PC;
    end else if (is_csrr_vlenb) begin
      st0 = SRC_XP; st1 = SRC_IMM_OR_PC; st2 = SRC_IMM_OR_PC;
    end else if (is_zimop) begin
      st0 = SRC_XP; st1 = SRC_IMM_OR_PC;
    end
  end
  // src3=掩码源：csrr 覆盖为 0，否则 {0,~instr[25],0}（vm==0→vp）
  wire [3:0] st3 = is_csrr_ov ? SRC_IMM_OR_PC : {1'b0, ~instr[25], 2'b0};
  // src4=vconfig：csrrVl→vp, csrrVlenb→0, 否则 vp
  wire [3:0] st4 = is_csrr_vl    ? SRC_VP
                 : is_csrr_vlenb ? SRC_IMM_OR_PC
                 : SRC_VP;

  // lsrc0：csrrVl/Vlenb/prefetch/非zimop → rs1，zimop → x0
  wire [5:0] lsrc0 = (is_csrr_ov || is_pre || !is_zimop) ? {1'b0, rs1} : 6'h0;
  wire [5:0] lsrc1 = {1'b0, rs2};
  // lsrc2：当 {instr[6:4],instr[1:0]}==5'h13（FMA 类）取 fs3，否则取 vd/rd 位域
  wire [4:0] sel2  = {instr[6:4], instr[1:0]};
  wire [5:0] lsrc2 = {1'b0, (sel2 == 5'h13) ? fs3 : instr[11:7]};
  localparam [5:0] V0_IDX = 6'd0;
  localparam [5:0] VL_IDX = 6'd32;
  wire [5:0] lsrc3 = V0_IDX;
  wire [5:0] lsrc4 = VL_IDX;
  wire [5:0] ldest = {1'b0, rd};

  // --------------------------------------------------------------------------
  // 8. 控制 flag（含覆盖）
  // --------------------------------------------------------------------------
  wire rf_wen   = (ldest != 6'h0) && db.rf_wen;
  wire fp_wen   = db.fp_wen;
  wire vec_wen  = db.vec_wen;
  wire is_xs_trap   = db.is_xs_trap;
  wire wait_forward = is_csrr_ov ? 1'b0 : db.wait_forward;
  wire block_back   = is_csrr_ov ? 1'b0 : db.block_backward;
  wire flush_pipe   = db.flush_pipe;
  // golden: canRobCompress = (csrrVl?... : csrrVlenb|表值) & ~isLastInFtqEntry
  wire can_rob_comp = (is_csrr_vlenb ? 1'b1
                    : is_pre        ? 1'b0
                    : db.can_rob_compress) && !is_last_in_ftq;
  wire [5:0] uop_split = db.uop_split_type;

  // --------------------------------------------------------------------------
  // 9. 异常合成（II/VI 中与 CSR 输入相关的主要项；selImm==INVALID 即基础非法）
  //    完整 frm/fs-off/hlsv 细分见 docs（向量/浮点细项为分阶段项）。
  // --------------------------------------------------------------------------
  localparam [34:0] VEC_ALL_MASK =
      (35'h1<<FU_VIPU)|(35'h1<<FU_VIALUF)|(35'h1<<FU_VPPU)|(35'h1<<FU_VIMAC)
    | (35'h1<<FU_VIDIV)|(35'h1<<FU_VFPU)|(35'h1<<FU_VFALU)|(35'h1<<FU_VFMA)
    | (35'h1<<FU_VFDIV)|(35'h1<<FU_VFCVT)|(35'h1<<FU_VSETIWI)|(35'h1<<FU_VSETIWF)
    | (35'h1<<FU_VSETFWF)|(35'h1<<FU_VLDU)|(35'h1<<FU_VSTU)
    | (35'h1<<FU_VSEGLDU)|(35'h1<<FU_VSEGSTU);

  wire is_fence = fu_ov[FU_FENCE];
  wire op_is_sfence  = is_fence && (op_ov == 9'h06);
  wire op_is_nofence = is_fence && (op_ov == 9'h00);
  wire op_is_hfence_g= is_fence && (op_ov == 9'h13);
  wire op_is_hfence_v= is_fence && (op_ov == 9'h12);

  wire exc_invalid = (sel_raw == SEL_INVALID);
  wire exc_ii =
       exc_invalid
    || (csr_illegal.sfenceVMA  && op_is_sfence)
    || (csr_illegal.sfencePart && op_is_nofence)
    || (csr_illegal.hfenceGVMA && op_is_hfence_g)
    || (csr_illegal.hfenceVVMA && op_is_hfence_v)
    || (csr_illegal.vsIsOff    && (|(fu_ov & VEC_ALL_MASK)));
  wire exc_vi =
       (csr_virtual.sfenceVMA  && op_is_sfence)
    || (csr_virtual.sfencePart && op_is_nofence)
    || (csr_virtual.hfence     && (op_is_hfence_g || op_is_hfence_v));

  // --------------------------------------------------------------------------
  // 10. 黑盒 FPDecoder_it（浮点控制位 rm/wflags）
  // --------------------------------------------------------------------------
  logic [1:0] fp_typeTagOut, fp_typ, fp_fmt;
  logic       fp_wflags;
  logic [2:0] fp_rm;
  FPDecoder_it u_fpdec (
    .io_instr            (instr),
    .io_fpCtrl_typeTagOut(fp_typeTagOut),
    .io_fpCtrl_wflags    (fp_wflags),
    .io_fpCtrl_typ       (fp_typ),
    .io_fpCtrl_fmt       (fp_fmt),
    .io_fpCtrl_rm        (fp_rm)
  );
  // golden 把 FPDecoder_it 的 typeTagOut/typ/fmt 直接接到输出端口（见 golden 5560 行）


  // --------------------------------------------------------------------------
  // 11. 黑盒 UopInfoGen_it（向量/AMOCAS 拆分 uop 数）
  //     输入预解析信息全部由指令编码 + vtype 决定。
  // --------------------------------------------------------------------------
  // 与 golden UopInfoGen_it 例化一致：纯由指令编码 / raw fuOpType 决定
  wire        is_vec_arith = (opcode5 == 5'h15);
  wire        is_vec_mem   = (opcode5 == 5'h9 && (~(|funct3) || instr[14]))
                          || (opcode5 == 5'h1 && (~(|funct3) || instr[14]));
  wire        is_amocas    = (opcode5 == 5'hB) && (instr[31:27] == 5'h5);
  wire        op_is_vlsr   = (op_raw == 9'h88) || (op_raw == 9'h108);
  wire        op_is_vlsm   = (op_raw == 9'h8B) || (op_raw == 9'h10B);

  logic       uig_isComplex;
  logic [6:0] uig_numUop, uig_numWB;
  logic [3:0] uig_lmul;
  UopInfoGen_it u_uig (
    .io_in_preInfo_isVecArith (is_vec_arith),
    .io_in_preInfo_isVecMem   (is_vec_mem),
    .io_in_preInfo_isAmoCAS   (is_amocas),
    .io_in_preInfo_typeOfSplit(uop_split),
    .io_in_preInfo_vsew       (vtype.vsew),
    .io_in_preInfo_vlmul      (vtype.vlmul),
    .io_in_preInfo_vwidth     (width3),
    .io_in_preInfo_nf         (nf),
    .io_in_preInfo_vmvn       (instr[17:15]),
    .io_in_preInfo_isVlsr     (op_is_vlsr),
    .io_in_preInfo_isVlsm     (op_is_vlsm),
    .io_out_isComplex         (uig_isComplex),
    .io_out_uopInfo_numOfUop  (uig_numUop),
    .io_out_uopInfo_numOfWB   (uig_numWB),
    .io_out_uopInfo_lmul      (uig_lmul)
  );

  // --------------------------------------------------------------------------
  // 11b. 派生明细字段（机器生成，引用上面已建立的 fu_ov/op_ov/uop_split/sel_ov/
  //      fp_rm/vtype/vstart/csr_* 边界信号）。覆盖 exceptionVec 非法/虚拟、vpu 明细、
  //      wfflags、isMove、isVset、commitType。生成方式见 scripts/gen_decodeunit.py。
  // --------------------------------------------------------------------------
  `include "decodeunit_derived.svh"

  // --------------------------------------------------------------------------
  // 12. 组装输出
  // --------------------------------------------------------------------------
  always_comb begin
    dec = '0;
    dec.srcType0 = st0; dec.srcType1 = st1; dec.srcType2 = st2;
    dec.srcType3 = st3; dec.srcType4 = st4;
    dec.lsrc0 = lsrc0; dec.lsrc1 = lsrc1; dec.lsrc2 = lsrc2;
    dec.lsrc3 = lsrc3; dec.lsrc4 = lsrc4; dec.ldest = ldest;
    dec.fuType = fu_ov; dec.fuOpType = op_ov;
    dec.rfWen = rf_wen; dec.fpWen = fp_wen; dec.vecWen = vec_wen;
    dec.isXSTrap = is_xs_trap;
    dec.waitForward = wait_forward; dec.blockBackward = block_back;
    dec.flushPipe = flush_pipe; dec.canRobCompress = can_rob_comp;
    dec.selImm = sel_ov; dec.imm = imm_ov;
    dec.uopSplitType = uop_split;
    // fpu_wflags = 黑盒 FPDecoder_it.wflags | 译码表 wfflags（golden 同式）
    dec.fpu_rm = fp_rm; dec.fpu_wflags = fp_wflags | d_wfflags;
    dec.fpu_typeTagOut = fp_typeTagOut; dec.fpu_typ = fp_typ; dec.fpu_fmt = fp_fmt;
    // 异常：完整的非法/虚拟指令合成（派生 d_excVec2/d_excVec22，覆盖 frm/fs-off/
    // vs-off/fence/hlsv/cbo/wfi/wrs 等全部细分；旧 exc_ii/exc_vi 为其子集，已并入）
    dec.exc_illegal = exc_ii; dec.exc_virtual = exc_vi;
    dec.excVec2 = d_excVec2; dec.excVec22 = d_excVec22;
    dec.isComplex = uig_isComplex;
    dec.numOfUop = uig_numUop; dec.numOfWB = uig_numWB; dec.lmul = uig_lmul;
    // 派生明细字段
    dec.wfflags = d_wfflags;
    dec.isMove  = d_isMove;
    dec.isVset  = d_isVset;
    dec.commitType = d_commitType;
    dec.vlsInstr   = d_vlsInstr;
    dec.vpu_isReverse     = d_isReverse;
    dec.vpu_isExt         = d_isExt;
    dec.vpu_isNarrow      = d_isNarrow;
    dec.vpu_isDstMask     = d_isDstMask;
    dec.vpu_isOpMask      = d_isOpMask;
    dec.vpu_isDependOldVd = d_isDependOldVd;
    dec.vpu_isWritePartVd = d_isWritePartVd;
    dec.vpu_isVleff       = d_isVleff;
  end

endmodule
