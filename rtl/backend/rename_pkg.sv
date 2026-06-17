// =====================================================================
// rename_pkg —— 重命名流水(Rename)的类型与参数
// ---------------------------------------------------------------------
// Rename 在后端的位置：Decode → 【Rename】 → Dispatch。
// 职责：消除 WAR/WAW 假相关 —— 把指令的「逻辑寄存器号」翻译成「物理寄存器号」。
//   * 源寄存器(lsrc) → psrc：读 RAT 拿当前映射，再叠加【同拍内 RAW 旁路】
//     (本拍前序指令若写了同一逻辑寄存器，要把它新分配的 pdest 直接转发过来，
//      因为 RAT 这拍还没更新)。
//   * 目的寄存器(ldest) → pdest：从对应类别的 FreeList 分配一个新物理寄存器；
//     若是 move 指令(mv rd,rs)，做【move elimination】——直接复用源的物理号，
//      不占新寄存器(pdest = psrc0)。
//
// 本可读核 xs_Rename_core 聚焦【A 批：重命名教学核心】：
//   psrc(同拍 RAW 旁路 + LUI/fusion 特例)、pdest(move-elim)、robIdx 投机分配、
//   RAT 写口(specWen)、5 个 FreeList 互联(doAllocate 五路交叉 AND / canOut)、
//   snapshot/allowSnpt、各类 SpecWen，以及 85 个 DecodedInst→DynInst 纯直通字段。
//
// 【B 批：译码级机器】(numWB-compress / dirtyVs / itype / iretire / ilastsize /
//   numLsElem) 不在本批实现，仅在核里占位并如实标注；详见 docs/backend/Rename.md。
//
// 子模块 CompressUnit / MEFreeList / StdFreeList(×4 变体) / SnapshotGenerator
// 全部当 golden 黑盒例化(不重写)。
// =====================================================================
package rename_pkg;

  // ---------------- 流水宽度参数 ----------------
  localparam int RENAME_WIDTH = 6;   // 每拍重命名指令数 RenameWidth
  localparam int COMMIT_WIDTH = 6;   // 提交/回滚口数 RabCommitWidth
  localparam int NUM_SRC      = 5;   // 每条指令的源寄存器数 numRegSrc(int/fp/vec/v0/vl)

  // ---------------- 字段位宽 ----------------
  localparam int PHYREG_W   = 8;     // 物理寄存器号位宽 PhyRegIdxWidth
  localparam int LREG_W     = 6;     // 逻辑寄存器号位宽(lsrc/ldest)
  localparam int INT_RAT_AW = 5;     // 整数 RAT 写地址位宽 = log2(IntLogicRegs=32)
  localparam int FP_RAT_AW  = 6;     // 浮点/向量 RAT 写地址位宽
  localparam int SRCTYPE_W  = 4;     // srcType 位宽
  localparam int FUTYPE_W   = 35;    // fuType 位宽
  localparam int FUOP_W     = 9;     // fuOpType 位宽
  localparam int SELIMM_W   = 4;     // selImm 位宽
  localparam int IMM_IN_W   = 22;    // DecodedInst.imm 位宽(输入)
  localparam int IMM_OUT_W  = 32;    // DynInst.imm 位宽(输出)
  localparam int ROB_PTR_W  = 8;     // RobPtr.value 位宽
  localparam int ROB_SIZE   = 160;   // ROB 条目数(0xA0)，循环指针的模

  // ---------------- 离散量编码(取自 Scala xiangshan.SrcType / FuType / SelImm) ----------------
  // SrcType 是 one-hot 风格(位0=int,位1=fp,位2=vec,位3=v0)；imm/pc/no = 4'b0000。
  localparam logic [SRCTYPE_W-1:0] SRC_IMM = 4'h0;  // imm / pc / no(读无寄存器)
  localparam logic [SRCTYPE_W-1:0] SRC_XP  = 4'h1;  // 整数寄存器
  localparam logic [SRCTYPE_W-1:0] SRC_FP  = 4'h2;  // 浮点寄存器
  localparam logic [SRCTYPE_W-1:0] SRC_VP  = 4'h4;  // 向量寄存器
  localparam logic [SRCTYPE_W-1:0] SRC_V0  = 4'h8;  // v0 掩码寄存器

  // selImm：U=立即数 LUI；LUI32=lui+addi(w) 融合
  localparam logic [SELIMM_W-1:0] SEL_IMM_U     = 4'h2;
  localparam logic [SELIMM_W-1:0] SEL_IMM_LUI32 = 4'hB;

  // fuType(经 firtool 编码后的具体常量，与 golden 对齐)
  localparam logic [FUTYPE_W-1:0] FU_ALU   = 35'h40;    // ALU(lui32 融合判定用)
  localparam logic [FUTYPE_W-1:0] FU_LDU   = 35'h8000;  // load(fused-lui-load 判定用)
  localparam logic [FUTYPE_W-1:0] FU_FENCE = 35'h200;   // fence(imm 取 {lsrc1,lsrc0})
  // FuType.isJump：fuType[0]==1(jmp 在 bit0)。snapshot CFI 判定用。

  // ---------------- FuType one-hot 位序(取自 Scala FuType.addType 顺序) ----------------
  // 这些位序用于 B 批译码级判定(isVls / isSegment / isXret / dirtyVs 特例)。
  localparam int FUB_CSR     = 5;    // csr：isXret 判定(CSR systemop)
  localparam int FUB_VIPU    = 18;   // vipu：dirtyVs 特例(vcpop.m/vfirst.m/vmv.x.s)
  localparam int FUB_VFALU   = 24;   // vfalu：dirtyVs 特例(vfmv.f.s)
  localparam int FUB_VLDU    = 31;   // 向量 load
  localparam int FUB_VSTU    = 32;   // 向量 store
  localparam int FUB_VSEGLDU = 33;   // 段向量 load(isSegment)
  localparam int FUB_VSEGSTU = 34;   // 段向量 store(isSegment)

  // ---------------- 向量访存流数(numLsElem)用常量 ----------------
  localparam int VEC_US_MAX_FLOW = 2;   // VecMemUnitStrideMaxFlowNum

  // ---------------- UopSplitType / FuOpType 特例编码(dirtyVs 用) ----------------
  // SCA_SIM=0(标量, dirtyVs 不置)；AMO_CAS_{W,D,Q}=0x35/0x36/0x37(原子 CAS, 不算向量脏)
  localparam logic [5:0] USPLIT_AMOCAS_W = 6'h35;
  localparam logic [5:0] USPLIT_AMOCAS_D = 6'h36;
  localparam logic [5:0] USPLIT_AMOCAS_Q = 6'h37;
  // 不改变向量状态的 4 条指令的 fuOpType(配合 vfalu/vipu 判别)
  localparam logic [FUOP_W-1:0] VOP_VFMV_F_S = 9'h11;  // vfmv.f.s  (vfalu)
  localparam logic [FUOP_W-1:0] VOP_VCPOP_M  = 9'h4B;  // vcpop.m   (vipu)
  localparam logic [FUOP_W-1:0] VOP_VFIRST_M = 9'h4C;  // vfirst.m  (vipu)
  localparam logic [FUOP_W-1:0] VOP_VMV_X_S  = 9'h53;  // vmv.x.s   (vipu)

  // ---------------- trace itype 编码(取自 backend.trace.Itype) ----------------
  localparam logic [3:0] ITYPE_NONE                 = 4'h0;
  localparam logic [3:0] ITYPE_EXP_INT_RETURN       = 4'h3;
  localparam logic [3:0] ITYPE_BRANCH               = 4'h4;  // = NonTaken
  localparam logic [3:0] ITYPE_UNINFERABLE_CALL     = 4'h8;
  localparam logic [3:0] ITYPE_INFERABLE_CALL       = 4'h9;
  localparam logic [3:0] ITYPE_UNINFERABLE_TAILCALL = 4'hA;
  localparam logic [3:0] ITYPE_INFERABLE_TAILCALL   = 4'hB;
  localparam logic [3:0] ITYPE_COROUTINE_SWAP       = 4'hC;
  localparam logic [3:0] ITYPE_FUNCTION_RETURN      = 4'hD;
  localparam logic [3:0] ITYPE_OTHER_UNINFER_JUMP   = 4'hE;
  localparam logic [3:0] ITYPE_OTHER_INFER_JUMP     = 4'hF;

  // BrType(取自 frontend.PreDecode.BrType)：notCFI=0 / branch=1 / jal=2 / jalr=3
  localparam logic [1:0] BRTYPE_NOTCFI = 2'h0;
  localparam logic [1:0] BRTYPE_BRANCH = 2'h1;
  localparam logic [1:0] BRTYPE_JAL    = 2'h2;
  localparam logic [1:0] BRTYPE_JALR   = 2'h3;

  // ===================================================================
  // DecodedInst(Rename 的输入 bits)—— 用 struct 聚合 golden 的 98 个扁平字段。
  // 字段顺序与位宽严格对应 io_in_N_bits_*，供 wrapper 机械打平 / 重组。
  // ===================================================================
  typedef struct packed {
    logic [31:0]              instr;
    logic [23:0]              exceptionVec;        // exceptionVec_0..23
    logic                     isFetchMalAddr;
    logic [3:0]               trigger;
    logic                     preDecodeInfo_isRVC;
    logic [1:0]               preDecodeInfo_brType;
    logic                     pred_taken;
    logic                     crossPageIPFFix;
    logic                     ftqPtr_flag;
    logic [5:0]               ftqPtr_value;
    logic [3:0]               ftqOffset;
    logic [NUM_SRC-1:0][SRCTYPE_W-1:0] srcType;    // srcType_0..4(packed)
    logic [NUM_SRC-1:0][LREG_W-1:0]   lsrc;        // lsrc_0..4(packed)；port0 仅 0/1 有效
    logic [LREG_W-1:0]        ldest;
    logic [FUTYPE_W-1:0]      fuType;
    logic [FUOP_W-1:0]        fuOpType;
    logic                     rfWen;
    logic                     fpWen;
    logic                     vecWen;
    logic                     v0Wen;
    logic                     vlWen;
    logic                     isXSTrap;
    logic                     waitForward;
    logic                     blockBackward;
    logic                     flushPipe;
    logic                     canRobCompress;
    logic [SELIMM_W-1:0]      selImm;
    logic [IMM_IN_W-1:0]      imm;
    logic [1:0]               fpu_typeTagOut;
    logic                     fpu_wflags;
    logic [1:0]               fpu_typ;
    logic [1:0]               fpu_fmt;
    logic [2:0]               fpu_rm;
    logic                     vpu_vill;
    logic                     vpu_vma;
    logic                     vpu_vta;
    logic [1:0]               vpu_vsew;
    logic [2:0]               vpu_vlmul;
    logic                     vpu_specVill;
    logic                     vpu_specVma;
    logic                     vpu_specVta;
    logic [1:0]               vpu_specVsew;
    logic [2:0]               vpu_specVlmul;
    logic                     vpu_vm;
    logic [7:0]               vpu_vstart;
    logic                     vpu_fpu_isFoldTo1_2;
    logic                     vpu_fpu_isFoldTo1_4;
    logic                     vpu_fpu_isFoldTo1_8;
    logic [127:0]             vpu_vmask;
    logic [2:0]               vpu_nf;
    logic [1:0]               vpu_veew;
    logic                     vpu_isExt;
    logic                     vpu_isNarrow;
    logic                     vpu_isDstMask;
    logic                     vpu_isOpMask;
    logic                     vpu_isDependOldVd;
    logic                     vpu_isWritePartVd;
    logic                     vpu_isVleff;
    logic                     vlsInstr;
    logic                     wfflags;
    logic                     isMove;
    logic [6:0]               uopIdx;
    logic [5:0]               uopSplitType;
    logic                     isVset;
    logic                     firstUop;
    logic                     lastUop;
    logic [6:0]               numWB;
    logic [2:0]               commitType;
  } decoded_inst_t;

  // ---- RAT 写端口(specRenamePort) ----
  typedef struct packed {
    logic                wen;
    logic [FP_RAT_AW-1:0] addr;   // 整数口只用低 5bit
    logic [PHYREG_W-1:0] data;
  } rat_wport_t;

endpackage
