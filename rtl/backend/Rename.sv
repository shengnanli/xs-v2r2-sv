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
// 可读核 xs_Rename_core 覆盖 golden 的全部功能：
//   A. 重命名主体：psrc(同拍 RAW 旁路 + LUI/fusion 特例)、pdest(move-elim)、robIdx
//      投机分配、RAT 写口(specWen)、5 个 FreeList 互联(doAllocate 五路交叉 AND /
//      canOut)、snapshot/allowSnpt、hasException、只读 CSR 读的屏障豁免；
//   B. 译码级压缩机器(依赖 CompressUnit)：numUops/numWB/instrSize/lastUop/firstUop/
//      ftq 折叠、wfflags/dirtyFs/dirtyVs/debug_sim_trig 聚合、trace 的 itype/iretire/
//      ilastsize、向量访存流数 numLsElem；
//   C. 观测：stallReason(topdown 反压归因)、30 路两级打拍的 perf 事件、renameTime。
// 其余 DecodedInst→DynInst 字段纯直通(由 wrapper 机械接线)。
//
// 子模块(全部已独立重写并签核，白盒例化)：CompressUnit / MEFreeList(intFreeList) /
//   StdFreeList(fp) / StdFreeList_1(vec) / StdFreeList_2(v0) / StdFreeList_3(vl)。
//
// 文件结构：本包 → xs_Rename_core(手写) → golden 同名 wrapper(由
//   verif/ut/Rename/gen_rename.py 从 G1 golden 端口表生成，附在文件末尾)。
// =====================================================================
// 本文件导航（共 5313 行；按"一个 golden 模块一个文件"的规范不拆分，用下面的分节定位）：
//   L33    Rename 在后端的位置：Decode → 【Rename】 → Dispatch
//   L157   DecodedInst(Rename 的输入 bits)—— 用 struct 聚合 golden 的扁平字段
//   L263   xs_Rename_core —— 重命名流水(Rename)可读重写
//   L265   位置：Decode → 【Rename】 → Dispatch
//   L284   关键设计点 1：同拍 RAW 旁路(psrc)
//   L291   关键设计点 2：move elimination(pdest)
//   L296   关键设计点 3：robIdx 投机分配 + 回退
//   L302   关键设计点 4：ROB 压缩(CompressUnit)
//   L428   小工具：把 srcType 译成各类目的需求位
//   L430   needXDest[i] = in 有效 && 该指令写 X 类寄存器
//   L445   1. CompressUnit：把可压缩的连续指令归并到一个 ROB 槽
//   L499   2. 五个 FreeList 的互联：doAllocate / canAllocate / canOut
//   L664   3. robIdx 投机分配
//   L745   4. psrc：RAT 读 + 同拍 RAW 旁路 + LUI/fusion 特例
//   L747   4a. RAT 读出的"基础" psrc(未旁路)
//   L854   5. pdest：move elimination
//   L874   6. snapshot / allowSnpt
//   L923   7. in_ready / out_valid / 各类 SpecWen(RAT 写口)
//   L956   8. 输出：直通字段 + 改写字段 + hasException
//   L958   hasException：前端异常(selectFrontend = idx 0,1,2,3,12,20,22) | illeg
//   L1084  9. 译码级压缩机器(依赖 CompressUnit 的 masks/instrSizes/needRobFlags/canCo
//   L1261  10. numLsElem(向量访存元素流数)
//   L1274  MulDataSize 查表(返回 5bit, 足够容纳 16)：mul∈{0,1,2,3}→16; 7→8; 6→4; 5→2
//   L1349  11. stallReason(topdown 反压归因)：严格复刻 golden
//   L1360  golden: 仅在 io_redirect_valid 拍锁存(带使能, 无 reset), walk 期用上次 redire
//   L1407  12. perf 事件流水线(严格复刻 golden)：30 个 io_perf.value，每个都经两级寄存器
//   L1475  golden 同名 wrapper —— 由 verif/ut/Rename/gen_rename.py 生成，改请改生成器
//
package rename_pkg;

  // ---------------- 流水宽度参数 ----------------
  localparam int RENAME_WIDTH = 6;   // 每拍重命名指令数 RenameWidth
  localparam int COMMIT_WIDTH = 6;   // 提交/回滚口数 RabCommitWidth
  localparam int NUM_SRC      = 5;   // 每条指令的源寄存器数 numRegSrc(int/fp/vec/v0/vl)
  localparam int NUM_PERF     = 30;  // perf 事件数：Rename 自身 10 + 5 个 FreeList × 4

  // ---------------- 字段位宽 ----------------
  localparam int PHYREG_W   = 8;     // 物理寄存器号位宽 PhyRegIdxWidth
  localparam int LREG_W     = 6;     // 逻辑寄存器号位宽(lsrc/ldest)
  localparam int INT_RAT_AW = 5;     // 整数 RAT 写地址位宽 = log2(IntLogicRegs=32)
  localparam int FP_RAT_AW  = 6;     // 浮点/向量 RAT 写地址位宽
  localparam int INT_LREGS  = 32;    // 整数逻辑寄存器数(debug_int_rat 的项数)
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

  // 仿真调试触发 HINT 指令(XSDebugDecode.SIM_TRIG = slti x0, x18, -518)
  localparam logic [31:0] SIM_TRIG_INSTR = 32'hDFA92013;

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

  // ---------------- topdown 反压归因编码(TopDownCounters) ----------------
  localparam logic [5:0] TD_INT_FL_STALL      = 6'h12;
  localparam logic [5:0] TD_FP_FL_STALL       = 6'h13;
  localparam logic [5:0] TD_VEC_FL_STALL      = 6'h14;
  localparam logic [5:0] TD_V0_FL_STALL       = 6'h15;
  localparam logic [5:0] TD_VL_FL_STALL       = 6'h16;
  localparam logic [5:0] TD_MULTI_FL_STALL    = 6'h17;
  localparam logic [5:0] TD_CTRL_RECOVERY     = 6'h21;
  localparam logic [5:0] TD_MEMVIO_RECOVERY   = 6'h22;
  localparam logic [5:0] TD_OTHER_RECOVERY    = 6'h23;
  localparam logic [5:0] TD_OTHER_CORE_STALL  = 6'h25;

  // ===================================================================
  // DecodedInst(Rename 的输入 bits)—— 用 struct 聚合 golden 的扁平字段。
  // 字段与位宽严格对应 io_in_N_bits_*(gen_rename.py 生成 wrapper 时逐项核对)。
  // 口 0 的 lsrc_2..4 在 golden 里被 firtool 消掉了(口 0 没人读它们)，wrapper 补 0。
  // ===================================================================
  typedef struct packed {
    logic [31:0]              instr;
    logic [23:0]              exceptionVec;        // exceptionVec_0..23
    logic                     isFetchMalAddr;
    logic [3:0]               trigger;
    logic                     preDecodeInfo_valid;
    logic                     preDecodeInfo_isRVC;
    logic [1:0]               preDecodeInfo_brType;
    logic                     preDecodeInfo_isCall;
    logic                     preDecodeInfo_isRet;
    logic                     pred_taken;
    logic                     crossPageIPFFix;
    logic                     ftqPtr_flag;
    logic [5:0]               ftqPtr_value;
    logic [3:0]               ftqOffset;
    logic [NUM_SRC-1:0][SRCTYPE_W-1:0] srcType;    // srcType_0..4(packed)
    logic [NUM_SRC-1:0][LREG_W-1:0]   lsrc;        // lsrc_0..4(packed)
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
    logic [1:0]               vpu_vxrm;
    logic [2:0]               vpu_frm;
    logic                     vpu_fpu_isFoldTo1_2;
    logic                     vpu_fpu_isFoldTo1_4;
    logic                     vpu_fpu_isFoldTo1_8;
    logic                     vpu_fpu_isFP32Instr;
    logic                     vpu_fpu_isFP64Instr;
    logic                     vpu_fpu_isFpToVecInst;
    logic                     vpu_fpu_isReduction;
    logic [127:0]             vpu_vmask;
    logic [7:0]               vpu_vl;
    logic [6:0]               vpu_vuopIdx;
    logic                     vpu_lastUop;
    logic [2:0]               vpu_nf;
    logic [1:0]               vpu_veew;
    logic                     vpu_isReverse;
    logic                     vpu_isExt;
    logic                     vpu_isNarrow;
    logic                     vpu_isDstMask;
    logic                     vpu_isOpMask;
    logic                     vpu_isMove;
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
    logic [6:0]               numUops;
    logic [6:0]               numWB;
    logic [2:0]               commitType;
    logic [FUTYPE_W-1:0]      debug_fuType;
    logic [49:0]              pc;
    logic [9:0]               foldpc;
    logic [55:0]              debug_seqNum_seqNum;
    logic [7:0]               debug_seqNum_uopIdx;
    logic                     satpFlushFirstFetchFault;
  } decoded_inst_t;

  // ---- RAT 写端口(specRenamePort) ----
  typedef struct packed {
    logic                wen;
    logic [FP_RAT_AW-1:0] addr;   // 整数口只用低 5bit
    logic [PHYREG_W-1:0] data;
  } rat_wport_t;

endpackage

// =====================================================================
// xs_Rename_core —— 重命名流水(Rename)可读重写
// ---------------------------------------------------------------------
// 位置：Decode → 【Rename】 → Dispatch。把逻辑寄存器号翻译成物理寄存器号，
// 消除 WAR/WAW 假相关。本核从 Scala (class Rename) 的设计意图重写。
//
// 数据流(一拍组合 + 少量打拍状态)：
//   io_in[6](DecodedInst)  ──┐
//                            ├─ CompressUnit → needRobFlags/instrSizes/masks/canCompress
//   RAT 读出 intReadPorts 等 ─┤
//                            ├─ 5×FreeList → allocatePhyReg / canAllocate
//   rabCommits / redirect ───┘
//                            ▼
//   ┌── psrc：RAT 读 + 同拍 RAW 旁路(前序口 pdest 折叠覆盖) + LUI/fusion 特例
//   ├── pdest：Mux(isMove, psrc0, freelist_out)  ← move elimination
//   ├── robIdx：robIdxHead + PopCount(本口之前的 lastUop&needRob)
//   ├── RAT 写口(specWen/addr/data)、FreeList 互联(doAllocate/canOut)
//   ├── snapshot/allowSnpt、hasException、CSR 只读豁免
//   └── 压缩机器：numUops/numWB/instrSize/lastUop/ftq 折叠、脏标志聚合、trace、numLsElem
//                            ▼
//   io_out[6](DynInst)：直通字段 + 上述计算字段
//
// 【关键设计点 1：同拍 RAW 旁路(psrc)】
//   RAT 这拍读出的是「上拍提交后」的映射，但本拍前序指令(0..i-1)可能也写了
//   同一逻辑寄存器。它们的新 pdest 这拍才算出、RAT 还没更新，所以必须在本级
//   把前序 pdest 直接转发给后序 psrc。bypassHit[i][s][k]=1 表示「第 i 口的第 s 个
//   源命中第 k 口的目的」。按【低位优先级折叠】(foldLeft：从 RAT 默认值出发，
//   逐口若命中就覆盖，最终最高命中口生效)。
//
// 【关键设计点 2：move elimination(pdest)】
//   mv rd, rs 不真正搬数据，只要让 rd 也指向 rs 的物理寄存器即可。
//   故 isMove 时 pdest = psrc0(已含旁路)，不向 FreeList 要新寄存器。
//   这正是 rename 关键路径所在：pdest 依赖 psrc，psrc 又依赖前序 pdest。
//
// 【关键设计点 3：robIdx 投机分配 + 回退】
//   robIdxHead 是 ROB 的循环写指针(flag+value, 模 160)。每条「lastUop 且需进
//   ROB」的指令占一个槽。第 i 口的 robIdx = head + (它之前这种指令的个数)。
//   redirect 拍把 head 直接拉到 redirect.robIdx；误预测(不冲刷自身)拍 head+1；
//   正常 canOut 拍 head += validCount。
//
// 【关键设计点 4：ROB 压缩(CompressUnit)】
//   连续的可压缩指令共享一个 ROB 槽：组头(needRobFlags=1 的口)代表整组，组内
//   其它口(needRobFlags=0)继承组头的 ftqPtr/ftqOffset、firstUop 置 0、
//   numUops/numWB 改成"组内指令数 - 被消除的 move 数"。
// =====================================================================
module xs_Rename_core
  import rename_pkg::*;
(
  input  logic clock,
  input  logic reset,

  // -------- redirect(分支预测错误/异常重定向) --------
  input  logic                  io_redirect_valid,
  input  logic                  io_redirect_bits_robIdx_flag,
  input  logic [ROB_PTR_W-1:0]  io_redirect_bits_robIdx_value,
  input  logic                  io_redirect_bits_level,         // flushItself: 1=冲刷自身
  input  logic                  io_redirect_bits_debugIsCtrl,   // stallReason: 控制相关重定向
  input  logic                  io_redirect_bits_debugIsMemVio, // stallReason: 访存违例重定向

  // -------- RAB 提交/回滚 --------
  input  logic                  io_rabCommits_isCommit,
  input  logic                  io_rabCommits_isWalk,
  input  logic [COMMIT_WIDTH-1:0] io_rabCommits_commitValid,
  input  logic [COMMIT_WIDTH-1:0] io_rabCommits_walkValid,
  input  logic [COMMIT_WIDTH-1:0] io_rabCommits_info_rfWen,
  input  logic [COMMIT_WIDTH-1:0] io_rabCommits_info_fpWen,
  input  logic [COMMIT_WIDTH-1:0] io_rabCommits_info_vecWen,
  input  logic [COMMIT_WIDTH-1:0] io_rabCommits_info_v0Wen,
  input  logic [COMMIT_WIDTH-1:0] io_rabCommits_info_vlWen,
  input  logic [COMMIT_WIDTH-1:0] io_rabCommits_info_isMove,

  input  logic                  io_singleStep,

  // -------- 来自 decode 的指令包 --------
  input  decoded_inst_t         io_in_bits  [RENAME_WIDTH],
  input  logic [RENAME_WIDTH-1:0] io_in_valid,
  output logic [RENAME_WIDTH-1:0] io_in_ready,

  // -------- 融合译码信息(指导 psrc1 来源) --------
  input  logic [RENAME_WIDTH-1:0] io_fusionInfo_rs2FromRs1,  // 仅 0..4 有效
  input  logic [RENAME_WIDTH-1:0] io_fusionInfo_rs2FromRs2,
  input  logic [RENAME_WIDTH-1:0] io_fusionInfo_rs2FromZero,

  // -------- RAT 读出(物理寄存器号) --------
  input  logic [PHYREG_W-1:0]   io_intReadPorts [RENAME_WIDTH][2],
  input  logic [PHYREG_W-1:0]   io_fpReadPorts  [RENAME_WIDTH][3],
  input  logic [PHYREG_W-1:0]   io_vecReadPorts [RENAME_WIDTH][3],
  input  logic [PHYREG_W-1:0]   io_v0ReadPorts  [RENAME_WIDTH],
  input  logic [PHYREG_W-1:0]   io_vlReadPorts  [RENAME_WIDTH],

  // -------- RAT 投机写口(specRenamePorts) --------
  output rat_wport_t            io_intRenamePorts [COMMIT_WIDTH],
  output rat_wport_t            io_fpRenamePorts  [COMMIT_WIDTH],
  output rat_wport_t            io_vecRenamePorts [COMMIT_WIDTH],
  output logic                  io_v0RenamePorts_wen  [COMMIT_WIDTH],
  output logic [PHYREG_W-1:0]   io_v0RenamePorts_data [COMMIT_WIDTH],
  output logic                  io_vlRenamePorts_wen  [COMMIT_WIDTH],
  output logic [PHYREG_W-1:0]   io_vlRenamePorts_data [COMMIT_WIDTH],

  // -------- 从 RAT 来的旧 pdest(回收用) --------
  input  logic [PHYREG_W-1:0]   io_int_old_pdest [COMMIT_WIDTH],
  input  logic [PHYREG_W-1:0]   io_fp_old_pdest  [COMMIT_WIDTH],
  input  logic [PHYREG_W-1:0]   io_vec_old_pdest [COMMIT_WIDTH],
  input  logic [PHYREG_W-1:0]   io_v0_old_pdest  [COMMIT_WIDTH],
  input  logic [PHYREG_W-1:0]   io_vl_old_pdest  [COMMIT_WIDTH],
  input  logic [COMMIT_WIDTH-1:0] io_int_need_free,

  // -------- 到 dispatch 的输出(DynInst) --------
  // 直通 + 计算字段分组输出(wrapper 再机械拼回 golden 扁平端口)
  output logic [RENAME_WIDTH-1:0] io_out_valid,
  input  logic [RENAME_WIDTH-1:0] io_out_ready,
  output decoded_inst_t           io_out_passthru [RENAME_WIDTH], // 直通字段载体
  output logic [PHYREG_W-1:0]     io_out_psrc  [RENAME_WIDTH][NUM_SRC],
  output logic [PHYREG_W-1:0]     io_out_pdest [RENAME_WIDTH],
  output logic                    io_out_robIdx_flag  [RENAME_WIDTH],
  output logic [ROB_PTR_W-1:0]    io_out_robIdx_value [RENAME_WIDTH],
  output logic                    io_out_isMove_o [RENAME_WIDTH],     // 异常门控后的 isMove(= eliminatedMove)
  output logic                    io_out_snapshot [RENAME_WIDTH],
  output logic                    io_out_hasException [RENAME_WIDTH],
  output logic [SRCTYPE_W-1:0]    io_out_srcType0 [RENAME_WIDTH],  // 可能被 fused-lui-load 改写
  output logic [IMM_OUT_W-1:0]    io_out_imm [RENAME_WIDTH],       // fence/lui32 融合改写
  output logic [63:0]             io_out_debugInfo_renameTime [RENAME_WIDTH],
  output logic [2:0]              io_out_instrSize [RENAME_WIDTH],
  output logic                    io_out_dirtyFs [RENAME_WIDTH],
  output logic                    io_out_dirtyVs [RENAME_WIDTH],
  output logic                    io_out_debug_sim_trig [RENAME_WIDTH],
  output logic [3:0]              io_out_itype [RENAME_WIDTH],
  output logic [3:0]              io_out_iretire [RENAME_WIDTH],
  output logic                    io_out_ilastsize [RENAME_WIDTH],
  output logic                    io_out_lastUop_o [RENAME_WIDTH],
  output logic [6:0]              io_out_numUops_o [RENAME_WIDTH],
  output logic [6:0]              io_out_numWB_o [RENAME_WIDTH],
  output logic                    io_out_wfflags_o [RENAME_WIDTH],
  output logic [4:0]              io_out_numLsElem [RENAME_WIDTH],
  // 压缩 ROB-slot 折叠字段(非纯直通)：ftqPtr/ftqOffset 继承压缩组头, firstUop 门控,
  //   waitForward/blockBackward 对合法只读 CSR 读清零。
  output logic                    io_out_ftqPtr_flag_o [RENAME_WIDTH],
  output logic [5:0]              io_out_ftqPtr_value_o [RENAME_WIDTH],
  output logic [3:0]              io_out_ftqOffset_o [RENAME_WIDTH],
  output logic                    io_out_firstUop_o [RENAME_WIDTH],
  output logic                    io_out_waitForward_o [RENAME_WIDTH],
  output logic                    io_out_blockBackward_o [RENAME_WIDTH],

  // -------- 快照端口 --------
  input  logic                  io_snpt_snptDeq,
  input  logic                  io_snpt_useSnpt,
  input  logic [1:0]            io_snpt_snptSelect,
  input  logic [3:0]            io_snpt_flushVec,
  input  logic                  io_snptLastEnq_valid,
  input  logic                  io_snptLastEnq_bits_flag,
  input  logic [ROB_PTR_W-1:0]  io_snptLastEnq_bits_value,
  input  logic                  io_snptIsFull,

  // -------- debug：体系结构态整数 RAT(只喂 intFreeList 的 debug 断言影子寄存器) --------
  input  logic [PHYREG_W-1:0]   io_debug_int_rat [INT_LREGS],

  // -------- stallReason / perf --------
  input  logic [5:0]            io_stallReason_in_reason [RENAME_WIDTH],
  input  logic                  io_stallReason_out_backReason_valid,
  output logic                  io_stallReason_in_backReason_valid,
  output logic [5:0]            io_stallReason_in_backReason_bits,
  output logic [5:0]            io_stallReason_out_reason [RENAME_WIDTH],
  output logic [5:0]            io_perf_value [NUM_PERF]
);

  // ===================================================================
  // 小工具：把 srcType 译成各类目的需求位
  // ===================================================================
  // needXDest[i] = in 有效 && 该指令写 X 类寄存器
  logic [RENAME_WIDTH-1:0] needIntDest, needFpDest, needVecDest, needV0Dest, needVlDest;
  logic [RENAME_WIDTH-1:0] isMove;
  always_comb
    for (int i = 0; i < RENAME_WIDTH; i++) begin
      needIntDest[i] = io_in_valid[i] & io_in_bits[i].rfWen;
      needFpDest [i] = io_in_valid[i] & io_in_bits[i].fpWen;
      needVecDest[i] = io_in_valid[i] & io_in_bits[i].vecWen;
      needV0Dest [i] = io_in_valid[i] & io_in_bits[i].v0Wen;
      needVlDest [i] = io_in_valid[i] & io_in_bits[i].vlWen;
      // 有异常的 move 不做消除(异常要走完整流程)
      isMove[i]      = io_in_bits[i].isMove & ~(|io_in_bits[i].exceptionVec);
    end

  // ===================================================================
  // 1. CompressUnit：把可压缩的连续指令归并到一个 ROB 槽
  //    输出 needRobFlags(该口是否独占一个 ROB 槽)/instrSizes/masks/canCompressVec。
  // ===================================================================
  logic [RENAME_WIDTH-1:0] needRobFlags;
  logic [2:0]              instrSizes [RENAME_WIDTH];
  logic [5:0]              cmpMasks   [RENAME_WIDTH];
  logic [RENAME_WIDTH-1:0] canCompressVec;

  // CompressUnit 入口：valid 经 singleStep 门控(单步时不压缩)
  logic [RENAME_WIDTH-1:0] cmpInValid;
  always_comb for (int i = 0; i < RENAME_WIDTH; i++) cmpInValid[i] = io_in_valid[i] & ~io_singleStep;

  // 每口送进 CompressUnit 的字段：exceptionVec[24] / trigger / canRobCompress / lastUop / commitType
  `define CMP_IN(P) \
      .io_in_``P``_valid               (cmpInValid[P]),                 \
      .io_in_``P``_bits_exceptionVec_0 (io_in_bits[P].exceptionVec[0]),  \
      .io_in_``P``_bits_exceptionVec_1 (io_in_bits[P].exceptionVec[1]),  \
      .io_in_``P``_bits_exceptionVec_2 (io_in_bits[P].exceptionVec[2]),  \
      .io_in_``P``_bits_exceptionVec_3 (io_in_bits[P].exceptionVec[3]),  \
      .io_in_``P``_bits_exceptionVec_4 (io_in_bits[P].exceptionVec[4]),  \
      .io_in_``P``_bits_exceptionVec_5 (io_in_bits[P].exceptionVec[5]),  \
      .io_in_``P``_bits_exceptionVec_6 (io_in_bits[P].exceptionVec[6]),  \
      .io_in_``P``_bits_exceptionVec_7 (io_in_bits[P].exceptionVec[7]),  \
      .io_in_``P``_bits_exceptionVec_8 (io_in_bits[P].exceptionVec[8]),  \
      .io_in_``P``_bits_exceptionVec_9 (io_in_bits[P].exceptionVec[9]),  \
      .io_in_``P``_bits_exceptionVec_10(io_in_bits[P].exceptionVec[10]), \
      .io_in_``P``_bits_exceptionVec_11(io_in_bits[P].exceptionVec[11]), \
      .io_in_``P``_bits_exceptionVec_12(io_in_bits[P].exceptionVec[12]), \
      .io_in_``P``_bits_exceptionVec_13(io_in_bits[P].exceptionVec[13]), \
      .io_in_``P``_bits_exceptionVec_14(io_in_bits[P].exceptionVec[14]), \
      .io_in_``P``_bits_exceptionVec_15(io_in_bits[P].exceptionVec[15]), \
      .io_in_``P``_bits_exceptionVec_16(io_in_bits[P].exceptionVec[16]), \
      .io_in_``P``_bits_exceptionVec_17(io_in_bits[P].exceptionVec[17]), \
      .io_in_``P``_bits_exceptionVec_18(io_in_bits[P].exceptionVec[18]), \
      .io_in_``P``_bits_exceptionVec_19(io_in_bits[P].exceptionVec[19]), \
      .io_in_``P``_bits_exceptionVec_20(io_in_bits[P].exceptionVec[20]), \
      .io_in_``P``_bits_exceptionVec_21(io_in_bits[P].exceptionVec[21]), \
      .io_in_``P``_bits_exceptionVec_22(io_in_bits[P].exceptionVec[22]), \
      .io_in_``P``_bits_exceptionVec_23(io_in_bits[P].exceptionVec[23]), \
      .io_in_``P``_bits_trigger        (io_in_bits[P].trigger),          \
      .io_in_``P``_bits_canRobCompress (io_in_bits[P].canRobCompress),   \
      .io_in_``P``_bits_lastUop        (io_in_bits[P].lastUop),          \
      .io_in_``P``_bits_commitType     (io_in_bits[P].commitType),       \
      .io_out_needRobFlags_``P         (needRobFlags[P]),                \
      .io_out_instrSizes_``P           (instrSizes[P]),                  \
      .io_out_masks_``P                (cmpMasks[P]),                    \
      .io_out_canCompressVec_``P       (canCompressVec[P])

  CompressUnit compressUnit (
    `CMP_IN(0), `CMP_IN(1), `CMP_IN(2), `CMP_IN(3), `CMP_IN(4), `CMP_IN(5)
  );
  `undef CMP_IN

  // ===================================================================
  // 2. 五个 FreeList 的互联：doAllocate / canAllocate / canOut
  //    设计意图(Scala)：只有【所有 5 个 FreeList 都 canAllocate 且 dispatch
  //    能收】才真正分配；isWalk(回滚重放)时一定能分配(回收的寄存器够用)。
  //    每个 FreeList 的 doAllocate = 【其余 4 个 canAllocate】& dispatchReady | isWalk
  //    —— 五路交叉 AND，故任一 FreeList 没空间会卡住整条流水。
  // ===================================================================
  logic [PHYREG_W-1:0] intAlloc [RENAME_WIDTH], fpAlloc [RENAME_WIDTH],
                       vecAlloc [RENAME_WIDTH], v0Alloc [RENAME_WIDTH], vlAlloc [RENAME_WIDTH];
  logic intCanAlloc, fpCanAlloc, vecCanAlloc, v0CanAlloc, vlCanAlloc;

  wire dispatchReady = io_out_ready[0];          // dispatch1 能否接收(看 head ready)
  wire isWalk        = io_rabCommits_isWalk;

  // 第 X 个 FreeList 的 doAllocate：其余四个 canAllocate 与 dispatchReady，或 isWalk
  wire intDoAlloc = (fpCanAlloc & vecCanAlloc & v0CanAlloc & vlCanAlloc & dispatchReady) | isWalk;
  wire fpDoAlloc  = (intCanAlloc & vecCanAlloc & v0CanAlloc & vlCanAlloc & dispatchReady) | isWalk;
  wire vecDoAlloc = (intCanAlloc & fpCanAlloc  & v0CanAlloc & vlCanAlloc & dispatchReady) | isWalk;
  wire v0DoAlloc  = (intCanAlloc & fpCanAlloc  & vecCanAlloc & vlCanAlloc & dispatchReady) | isWalk;
  wire vlDoAlloc  = (intCanAlloc & fpCanAlloc  & vecCanAlloc & v0CanAlloc & dispatchReady) | isWalk;

  // canOut：所有 FreeList 就绪 + dispatch 就绪 + 非回滚 → 本拍可放行到下一级
  wire canOut = dispatchReady & intCanAlloc & fpCanAlloc & vecCanAlloc
              & v0CanAlloc & vlCanAlloc & ~isWalk;

  // ---- 分配请求(整数口要排除 move) / 回滚重放请求 ----
  logic [RENAME_WIDTH-1:0] intAllocReq, fpAllocReq, vecAllocReq, v0AllocReq, vlAllocReq;
  logic [COMMIT_WIDTH-1:0] intWalkReq, fpWalkReq, vecWalkReq, v0WalkReq, vlWalkReq;
  always_comb
    for (int i = 0; i < RENAME_WIDTH; i++) begin
      intAllocReq[i] = needIntDest[i] & ~isMove[i];
      fpAllocReq [i] = needFpDest[i];
      vecAllocReq[i] = needVecDest[i];
      v0AllocReq [i] = needV0Dest[i];
      vlAllocReq [i] = needVlDest[i];
      // walk(回滚)：用提交信息里的 Wen，且整数排除 move
      intWalkReq[i] = io_rabCommits_walkValid[i] & io_rabCommits_info_rfWen[i] & ~io_rabCommits_info_isMove[i];
      fpWalkReq [i] = io_rabCommits_walkValid[i] & io_rabCommits_info_fpWen[i];
      vecWalkReq[i] = io_rabCommits_walkValid[i] & io_rabCommits_info_vecWen[i];
      v0WalkReq [i] = io_rabCommits_walkValid[i] & io_rabCommits_info_v0Wen[i];
      vlWalkReq [i] = io_rabCommits_walkValid[i] & io_rabCommits_info_vlWen[i];
    end

  // ---- snapshot 互联：snptEnq = genSnapshot(本拍有需要打快照的指令放行) ----
  logic genSnapshot;   // 见第 6 节

  // ---- 整数 FreeList 的回收数据要打一拍(golden: RegNext(int_old_pdest)) ----
  logic [PHYREG_W-1:0] intFreePhyReg_REG [COMMIT_WIDTH];
  always_ff @(posedge clock)
    for (int i = 0; i < COMMIT_WIDTH; i++) intFreePhyReg_REG[i] <= io_int_old_pdest[i];

  // ---- fp/vec/v0/vl FreeList 的 freeReq 要打一拍(golden: GatedValidRegNext，复位 0) ----
  // commitVec[i]=本口有效提交(组合网, 不放 always_ff 内声明——否则 FM 前端把 always_ff
  //  内的 blocking 临时量每迭代推成死寄存器伪影)。
  logic [COMMIT_WIDTH-1:0] commitVec;
  always_comb
    for (int i = 0; i < COMMIT_WIDTH; i++)
      commitVec[i] = io_rabCommits_isCommit & io_rabCommits_commitValid[i];
  logic [COMMIT_WIDTH-1:0] fpFreeReq_REG, vecFreeReq_REG, v0FreeReq_REG, vlFreeReq_REG;
  always_ff @(posedge clock or posedge reset)
    if (reset) begin
      fpFreeReq_REG <= '0; vecFreeReq_REG <= '0; v0FreeReq_REG <= '0; vlFreeReq_REG <= '0;
    end else
      for (int i = 0; i < COMMIT_WIDTH; i++) begin
        fpFreeReq_REG [i] <= commitVec[i] & io_rabCommits_info_fpWen[i];
        vecFreeReq_REG[i] <= commitVec[i] & io_rabCommits_info_vecWen[i];
        v0FreeReq_REG [i] <= commitVec[i] & io_rabCommits_info_v0Wen[i];
        vlFreeReq_REG [i] <= commitVec[i] & io_rabCommits_info_vlWen[i];
      end

  // FreeList perf 输出先接命名中间线, 之后经 golden 的两级寄存器流水线映射到 io_perf_value。
  logic [5:0] intFlPerf [4], fpFlPerf [4], vecFlPerf [4], v0FlPerf [4], vlFlPerf [4];

  // ---- 整数 FreeList(MEFreeList)：move elimination 版本 ----
  MEFreeList intFreeList (
    .clock(clock), .reset(reset),
    .io_redirect(io_redirect_valid), .io_walk(isWalk),
    .io_allocateReq_0(intAllocReq[0]), .io_allocateReq_1(intAllocReq[1]),
    .io_allocateReq_2(intAllocReq[2]), .io_allocateReq_3(intAllocReq[3]),
    .io_allocateReq_4(intAllocReq[4]), .io_allocateReq_5(intAllocReq[5]),
    .io_walkReq_0(intWalkReq[0]), .io_walkReq_1(intWalkReq[1]),
    .io_walkReq_2(intWalkReq[2]), .io_walkReq_3(intWalkReq[3]),
    .io_walkReq_4(intWalkReq[4]), .io_walkReq_5(intWalkReq[5]),
    .io_allocatePhyReg_0(intAlloc[0]), .io_allocatePhyReg_1(intAlloc[1]),
    .io_allocatePhyReg_2(intAlloc[2]), .io_allocatePhyReg_3(intAlloc[3]),
    .io_allocatePhyReg_4(intAlloc[4]), .io_allocatePhyReg_5(intAlloc[5]),
    .io_canAllocate(intCanAlloc), .io_doAllocate(intDoAlloc),
    .io_freeReq_0(io_int_need_free[0]), .io_freeReq_1(io_int_need_free[1]),
    .io_freeReq_2(io_int_need_free[2]), .io_freeReq_3(io_int_need_free[3]),
    .io_freeReq_4(io_int_need_free[4]), .io_freeReq_5(io_int_need_free[5]),
    .io_freePhyReg_0(intFreePhyReg_REG[0]), .io_freePhyReg_1(intFreePhyReg_REG[1]),
    .io_freePhyReg_2(intFreePhyReg_REG[2]), .io_freePhyReg_3(intFreePhyReg_REG[3]),
    .io_freePhyReg_4(intFreePhyReg_REG[4]), .io_freePhyReg_5(intFreePhyReg_REG[5]),
    .io_commit_isCommit(io_rabCommits_isCommit),
    .io_commit_commitValid_0(io_rabCommits_commitValid[0]), .io_commit_commitValid_1(io_rabCommits_commitValid[1]),
    .io_commit_commitValid_2(io_rabCommits_commitValid[2]), .io_commit_commitValid_3(io_rabCommits_commitValid[3]),
    .io_commit_commitValid_4(io_rabCommits_commitValid[4]), .io_commit_commitValid_5(io_rabCommits_commitValid[5]),
    .io_commit_info_0_rfWen(io_rabCommits_info_rfWen[0]), .io_commit_info_0_isMove(io_rabCommits_info_isMove[0]),
    .io_commit_info_1_rfWen(io_rabCommits_info_rfWen[1]), .io_commit_info_1_isMove(io_rabCommits_info_isMove[1]),
    .io_commit_info_2_rfWen(io_rabCommits_info_rfWen[2]), .io_commit_info_2_isMove(io_rabCommits_info_isMove[2]),
    .io_commit_info_3_rfWen(io_rabCommits_info_rfWen[3]), .io_commit_info_3_isMove(io_rabCommits_info_isMove[3]),
    .io_commit_info_4_rfWen(io_rabCommits_info_rfWen[4]), .io_commit_info_4_isMove(io_rabCommits_info_isMove[4]),
    .io_commit_info_5_rfWen(io_rabCommits_info_rfWen[5]), .io_commit_info_5_isMove(io_rabCommits_info_isMove[5]),
    .io_snpt_snptEnq(genSnapshot), .io_snpt_snptDeq(io_snpt_snptDeq),
    .io_snpt_useSnpt(io_snpt_useSnpt), .io_snpt_snptSelect(io_snpt_snptSelect),
    .io_snpt_flushVec_0(io_snpt_flushVec[0]), .io_snpt_flushVec_1(io_snpt_flushVec[1]),
    .io_snpt_flushVec_2(io_snpt_flushVec[2]), .io_snpt_flushVec_3(io_snpt_flushVec[3]),
    .io_debug_rat_0 (io_debug_int_rat[0]),  .io_debug_rat_1 (io_debug_int_rat[1]),
    .io_debug_rat_2 (io_debug_int_rat[2]),  .io_debug_rat_3 (io_debug_int_rat[3]),
    .io_debug_rat_4 (io_debug_int_rat[4]),  .io_debug_rat_5 (io_debug_int_rat[5]),
    .io_debug_rat_6 (io_debug_int_rat[6]),  .io_debug_rat_7 (io_debug_int_rat[7]),
    .io_debug_rat_8 (io_debug_int_rat[8]),  .io_debug_rat_9 (io_debug_int_rat[9]),
    .io_debug_rat_10(io_debug_int_rat[10]), .io_debug_rat_11(io_debug_int_rat[11]),
    .io_debug_rat_12(io_debug_int_rat[12]), .io_debug_rat_13(io_debug_int_rat[13]),
    .io_debug_rat_14(io_debug_int_rat[14]), .io_debug_rat_15(io_debug_int_rat[15]),
    .io_debug_rat_16(io_debug_int_rat[16]), .io_debug_rat_17(io_debug_int_rat[17]),
    .io_debug_rat_18(io_debug_int_rat[18]), .io_debug_rat_19(io_debug_int_rat[19]),
    .io_debug_rat_20(io_debug_int_rat[20]), .io_debug_rat_21(io_debug_int_rat[21]),
    .io_debug_rat_22(io_debug_int_rat[22]), .io_debug_rat_23(io_debug_int_rat[23]),
    .io_debug_rat_24(io_debug_int_rat[24]), .io_debug_rat_25(io_debug_int_rat[25]),
    .io_debug_rat_26(io_debug_int_rat[26]), .io_debug_rat_27(io_debug_int_rat[27]),
    .io_debug_rat_28(io_debug_int_rat[28]), .io_debug_rat_29(io_debug_int_rat[29]),
    .io_debug_rat_30(io_debug_int_rat[30]), .io_debug_rat_31(io_debug_int_rat[31]),
    .io_perf_0_value(intFlPerf[0]), .io_perf_1_value(intFlPerf[1]),
    .io_perf_2_value(intFlPerf[2]), .io_perf_3_value(intFlPerf[3])
  );

  // ---- fp/vec/v0/vl FreeList(StdFreeList 变体)，公共绑定用宏减少机械重复 ----
  `define STD_FL(MOD, INST, REQ, WREQ, ALLOC, CAN, DOALLOC, FREEREQ, FREEPD, WENNAME, PERF) \
    MOD INST ( \
      .clock(clock), .reset(reset), .io_redirect(io_redirect_valid), .io_walk(isWalk), \
      .io_allocateReq_0(REQ[0]), .io_allocateReq_1(REQ[1]), .io_allocateReq_2(REQ[2]), \
      .io_allocateReq_3(REQ[3]), .io_allocateReq_4(REQ[4]), .io_allocateReq_5(REQ[5]), \
      .io_walkReq_0(WREQ[0]), .io_walkReq_1(WREQ[1]), .io_walkReq_2(WREQ[2]), \
      .io_walkReq_3(WREQ[3]), .io_walkReq_4(WREQ[4]), .io_walkReq_5(WREQ[5]), \
      .io_allocatePhyReg_0(ALLOC[0]), .io_allocatePhyReg_1(ALLOC[1]), .io_allocatePhyReg_2(ALLOC[2]), \
      .io_allocatePhyReg_3(ALLOC[3]), .io_allocatePhyReg_4(ALLOC[4]), .io_allocatePhyReg_5(ALLOC[5]), \
      .io_canAllocate(CAN), .io_doAllocate(DOALLOC), \
      .io_freeReq_0(FREEREQ[0]), .io_freeReq_1(FREEREQ[1]), .io_freeReq_2(FREEREQ[2]), \
      .io_freeReq_3(FREEREQ[3]), .io_freeReq_4(FREEREQ[4]), .io_freeReq_5(FREEREQ[5]), \
      .io_freePhyReg_0(FREEPD[0]), .io_freePhyReg_1(FREEPD[1]), .io_freePhyReg_2(FREEPD[2]), \
      .io_freePhyReg_3(FREEPD[3]), .io_freePhyReg_4(FREEPD[4]), .io_freePhyReg_5(FREEPD[5]), \
      .io_commit_isCommit(io_rabCommits_isCommit), \
      .io_commit_commitValid_0(io_rabCommits_commitValid[0]), .io_commit_commitValid_1(io_rabCommits_commitValid[1]), \
      .io_commit_commitValid_2(io_rabCommits_commitValid[2]), .io_commit_commitValid_3(io_rabCommits_commitValid[3]), \
      .io_commit_commitValid_4(io_rabCommits_commitValid[4]), .io_commit_commitValid_5(io_rabCommits_commitValid[5]), \
      .io_commit_info_0_``WENNAME(io_rabCommits_info_``WENNAME``[0]), \
      .io_commit_info_1_``WENNAME(io_rabCommits_info_``WENNAME``[1]), \
      .io_commit_info_2_``WENNAME(io_rabCommits_info_``WENNAME``[2]), \
      .io_commit_info_3_``WENNAME(io_rabCommits_info_``WENNAME``[3]), \
      .io_commit_info_4_``WENNAME(io_rabCommits_info_``WENNAME``[4]), \
      .io_commit_info_5_``WENNAME(io_rabCommits_info_``WENNAME``[5]), \
      .io_snpt_snptEnq(genSnapshot), .io_snpt_snptDeq(io_snpt_snptDeq), \
      .io_snpt_useSnpt(io_snpt_useSnpt), .io_snpt_snptSelect(io_snpt_snptSelect), \
      .io_snpt_flushVec_0(io_snpt_flushVec[0]), .io_snpt_flushVec_1(io_snpt_flushVec[1]), \
      .io_snpt_flushVec_2(io_snpt_flushVec[2]), .io_snpt_flushVec_3(io_snpt_flushVec[3]), \
      .io_perf_0_value(PERF[0]), .io_perf_1_value(PERF[1]), \
      .io_perf_2_value(PERF[2]), .io_perf_3_value(PERF[3]) )

  `STD_FL(StdFreeList,   fpFreeList,  fpAllocReq,  fpWalkReq,  fpAlloc,  fpCanAlloc,  fpDoAlloc,  fpFreeReq_REG,  io_fp_old_pdest,  fpWen,  fpFlPerf);
  `STD_FL(StdFreeList_1, vecFreeList, vecAllocReq, vecWalkReq, vecAlloc, vecCanAlloc, vecDoAlloc, vecFreeReq_REG, io_vec_old_pdest, vecWen, vecFlPerf);
  `STD_FL(StdFreeList_2, v0FreeList,  v0AllocReq,  v0WalkReq,  v0Alloc,  v0CanAlloc,  v0DoAlloc,  v0FreeReq_REG,  io_v0_old_pdest,  v0Wen,  v0FlPerf);
  `STD_FL(StdFreeList_3, vlFreeList,  vlAllocReq,  vlWalkReq,  vlAlloc,  vlCanAlloc,  vlDoAlloc,  vlFreeReq_REG,  io_vl_old_pdest,  vlWen,  vlFlPerf);
  `undef STD_FL

  // ===================================================================
  // 3. robIdx 投机分配
  //    每条「io_in valid && lastUop && needRobFlag」的指令占一个 ROB 槽。
  //    第 i 口 robIdx = robIdxHead + (它之前同类指令的个数)。
  //    robIdxHead 循环指针：value 模 ROB_SIZE(160)，跨界翻转 flag。
  // ===================================================================
  logic                 robIdxHead_flag;
  logic [ROB_PTR_W-1:0] robIdxHead_value;
  // 误预测打一拍(redirect 且非冲刷自身 → 下拍 head+1，跳过被冲掉的那条)
  logic lastCycleMisprediction;

  // 各口「占 ROB 槽」标志
  logic [RENAME_WIDTH-1:0] takeRobSlot;
  always_comb
    for (int i = 0; i < RENAME_WIDTH; i++)
      takeRobSlot[i] = io_in_valid[i] & io_in_bits[i].lastUop & needRobFlags[i];

  // 前 i 口占槽数(本口 robIdx 相对 head 的偏移)
  function automatic logic [2:0] slots_below(input logic [RENAME_WIDTH-1:0] v, input int i);
    logic [2:0] s; begin s = '0; for (int k = 0; k < RENAME_WIDTH; k++) if (k < i && v[k]) s += 3'b1; return s; end
  endfunction
  // 本拍总占槽数 validCount
  function automatic logic [2:0] slots_all(input logic [RENAME_WIDTH-1:0] v);
    logic [2:0] s; begin s = '0; for (int k = 0; k < RENAME_WIDTH; k++) if (v[k]) s += 3'b1; return s; end
  endfunction
  wire [2:0] validCount = slots_all(takeRobSlot);

  // 循环指针加法：value + delta，超过 ROB_SIZE 则减去并翻转 flag。
  function automatic void rob_add
      (input logic f, input logic [ROB_PTR_W-1:0] v, input logic [3:0] delta,
       output logic nf, output logic [ROB_PTR_W-1:0] nv);
    logic [9:0] sum;     // 足够容纳 v+delta
    begin
      sum = {2'h0, v} + {6'h0, delta};
      if (sum >= ROB_SIZE) begin nv = ROB_PTR_W'(sum - ROB_SIZE); nf = ~f; end
      else                  begin nv = sum[ROB_PTR_W-1:0]; nf = f; end
    end
  endfunction

  // 每口 robIdx = head + slots_below(i)
  always_comb
    for (int i = 0; i < RENAME_WIDTH; i++) begin
      logic nf; logic [ROB_PTR_W-1:0] nv;
      rob_add(robIdxHead_flag, robIdxHead_value, {1'b0, slots_below(takeRobSlot, i)}, nf, nv);
      io_out_robIdx_flag [i] = nf;
      io_out_robIdx_value[i] = nv;
    end

  // robIdxHead 下一值
  logic                 robIdxHeadNext_flag;
  logic [ROB_PTR_W-1:0] robIdxHeadNext_value;
  always_comb begin
    logic mf; logic [ROB_PTR_W-1:0] mv;  // 误预测 +1
    logic cf; logic [ROB_PTR_W-1:0] cv;  // 正常 +validCount
    rob_add(robIdxHead_flag, robIdxHead_value, 4'd1, mf, mv);
    rob_add(robIdxHead_flag, robIdxHead_value, {1'b0, validCount}, cf, cv);
    if (io_redirect_valid) begin
      robIdxHeadNext_flag  = io_redirect_bits_robIdx_flag;
      robIdxHeadNext_value = io_redirect_bits_robIdx_value;
    end else if (lastCycleMisprediction) begin
      robIdxHeadNext_flag  = mf;
      robIdxHeadNext_value = mv;
    end else if (canOut) begin
      robIdxHeadNext_flag  = cf;
      robIdxHeadNext_value = cv;
    end else begin
      robIdxHeadNext_flag  = robIdxHead_flag;
      robIdxHeadNext_value = robIdxHead_value;
    end
  end

  always_ff @(posedge clock or posedge reset)
    if (reset) begin
      robIdxHead_flag <= 1'b0; robIdxHead_value <= '0;
      lastCycleMisprediction <= 1'b0;
    end else begin
      robIdxHead_flag  <= robIdxHeadNext_flag;
      robIdxHead_value <= robIdxHeadNext_value;
      lastCycleMisprediction <= io_redirect_valid & ~io_redirect_bits_level;
    end

  // ===================================================================
  // 4. psrc：RAT 读 + 同拍 RAW 旁路 + LUI/fusion 特例
  // ===================================================================
  // 4a. RAT 读出的"基础" psrc(未旁路)。Mux1H by srcType。
  //     psrc0/1: int|fp|vec；psrc2: fp|vec；psrc3=v0ReadPort；psrc4=vlReadPort。
  function automatic logic [PHYREG_W-1:0] mux3
      (input logic [SRCTYPE_W-1:0] st,
       input logic [PHYREG_W-1:0] a, input logic [PHYREG_W-1:0] b, input logic [PHYREG_W-1:0] c);
    return (st[0] ? a : '0) | (st[1] ? b : '0) | (st[2] ? c : '0);
  endfunction

  logic [PHYREG_W-1:0] psrcRat [RENAME_WIDTH][NUM_SRC];  // 未旁路的基础读出
  always_comb
    for (int i = 0; i < RENAME_WIDTH; i++) begin
      psrcRat[i][0] = mux3(io_in_bits[i].srcType[0], io_intReadPorts[i][0], io_fpReadPorts[i][0], io_vecReadPorts[i][0]);
      psrcRat[i][1] = mux3(io_in_bits[i].srcType[1], io_intReadPorts[i][1], io_fpReadPorts[i][1], io_vecReadPorts[i][1]);
      // psrc2 只有 fp/vec(无 int 口)
      psrcRat[i][2] = (io_in_bits[i].srcType[2][1] ? io_fpReadPorts[i][2] : '0)
                    | (io_in_bits[i].srcType[2][2] ? io_vecReadPorts[i][2] : '0);
      psrcRat[i][3] = io_v0ReadPorts[i];
      psrcRat[i][4] = io_vlReadPorts[i];
    end

  // 4b. psrc1 的 fusion 特例(口 0..4)：若融合信息要求 rs2 来自下一条的 rs1/rs2/零，
  //     直接取下一条的 intReadPort(注意：是融合前下一条的 RAT 读，不走旁路)。
  logic [PHYREG_W-1:0] psrc1Base [RENAME_WIDTH];
  always_comb
    for (int i = 0; i < RENAME_WIDTH; i++) begin
      psrc1Base[i] = psrcRat[i][1];
      if (i < RENAME_WIDTH-1) begin
        if (io_fusionInfo_rs2FromRs2[i] | io_fusionInfo_rs2FromRs1[i])
          psrc1Base[i] = io_fusionInfo_rs2FromRs2[i] ? io_intReadPorts[i+1][1] : io_intReadPorts[i+1][0];
        else if (io_fusionInfo_rs2FromZero[i])
          psrc1Base[i] = '0;
      end
    end

  // 4c. 同拍 RAW 旁路命中位 bypassHit[i][s][k]：第 i 口的 src 源命中第 k 口(k<i)目的。
  //     与 golden bypassCond 完全一致：对第 i 口的第 s 源(用 lsrc[s] 作 target)，
  //       普通命中 = (prev.ldest==this.lsrc[s]) && writeMatch
  //       writeMatch = srcType[s]∈{xp,fp,vp} 且 prev 写对应类别
  //       v0/vl 命中(不比 ldest)：s==3 且 (vp|v0) 且 prev 写 v0；s==4 且 vp 且 prev 写 vl
  logic bypassHit [RENAME_WIDTH][NUM_SRC][RENAME_WIDTH];
  always_comb
    for (int i = 0; i < RENAME_WIDTH; i++)
      for (int s = 0; s < NUM_SRC; s++)
        for (int k = 0; k < RENAME_WIDTH; k++) begin
          logic idxMatch, wrMatch, v0vlMatch;
          logic [SRCTYPE_W-1:0] st;
          st = io_in_bits[i].srcType[s];
          idxMatch  = (io_in_bits[k].ldest == io_in_bits[i].lsrc[s]);
          wrMatch   = ((st == SRC_XP) & needIntDest[k])
                    | ((st == SRC_FP) & needFpDest [k])
                    | ((st == SRC_VP) & needVecDest[k]);
          v0vlMatch = ( (s == 3) & ((st == SRC_VP) | (st == SRC_V0)) & needV0Dest[k] )
                    | ( (s == 4) &  (st == SRC_VP)                    & needVlDest[k] );
          bypassHit[i][s][k] = ((k < i) && ((idxMatch & wrMatch) | v0vlMatch));
        end

  // 旁路目标 pdest(各 k 口输出 pdest，含其自身旁路结果)。pdest 见第 5 节，这里前向声明。
  logic [PHYREG_W-1:0] pdest [RENAME_WIDTH];

  // 4d. 折叠选择：基础值 base[i][s] 出发，按 k=0..i-1 顺序若命中则覆盖(低位起、高位最终生效)。
  //     就地写进 always_comb 而不用 function：function 内读模块级信号(bypassHit/pdest)
  //     会被 FM 判 RTL 解释错误。
  // base[i][s]：psrc1 用含 fusion 的 psrc1Base，其余用 psrcRat。
  logic [PHYREG_W-1:0] psrcBase [RENAME_WIDTH][NUM_SRC];
  always_comb
    for (int i = 0; i < RENAME_WIDTH; i++) begin
      psrcBase[i][0] = psrcRat[i][0];
      psrcBase[i][1] = psrc1Base[i];
      psrcBase[i][2] = psrcRat[i][2];
      psrcBase[i][3] = psrcRat[i][3];
      psrcBase[i][4] = psrcRat[i][4];
    end

  // 折叠后(未 LUI 清零)的各源 psrc
  logic [PHYREG_W-1:0] psrcBypassed [RENAME_WIDTH][NUM_SRC];
  always_comb
    for (int i = 0; i < RENAME_WIDTH; i++)
      for (int s = 0; s < NUM_SRC; s++) begin
        logic [PHYREG_W-1:0] z;
        z = psrcBase[i][s];
        for (int k = 0; k < RENAME_WIDTH; k++)
          if (k < i && bypassHit[i][s][k]) z = pdest[k];
        psrcBypassed[i][s] = z;
      end

  // 4e. 最终 psrc 输出(含 LUI/fusion 特例)
  // isLUI 条件(psrc0 置 0，因 LUI 的 rs 恒为零寄存器)：fuType==alu & selImm∈{U,LUI32}。
  logic [RENAME_WIDTH-1:0] isLUIzero;
  always_comb
    for (int i = 0; i < RENAME_WIDTH; i++)
      isLUIzero[i] = (io_in_bits[i].fuType == FU_ALU)
                   & ((io_in_bits[i].selImm == SEL_IMM_U) | (io_in_bits[i].selImm == SEL_IMM_LUI32));

  // psrc0Raw：旁路后、未被 isLUI 清零的 psrc0。口 0 的 move-elim pdest 用它(对应 Scala 的
  // uops(0).psrc.head，而非 io.out(0).bits.psrc(0))；LUI 清零只作用于对外 psrc0 输出。
  logic [PHYREG_W-1:0] psrc0Raw [RENAME_WIDTH];
  always_comb
    for (int i = 0; i < RENAME_WIDTH; i++) begin
      psrc0Raw[i]       = psrcBypassed[i][0];
      io_out_psrc[i][0] = isLUIzero[i] ? '0 : psrcBypassed[i][0];
      io_out_psrc[i][1] = psrcBypassed[i][1];
      io_out_psrc[i][2] = psrcBypassed[i][2];
      io_out_psrc[i][3] = psrcBypassed[i][3];
      io_out_psrc[i][4] = psrcBypassed[i][4];
    end

  // ===================================================================
  // 5. pdest：move elimination
  //    isMove → pdest = psrc0(含旁路)；否则按需求类别选对应 FreeList 的分配结果。
  // ===================================================================
  always_comb
    for (int i = 0; i < RENAME_WIDTH; i++) begin
      logic [PHYREG_W-1:0] flAlloc;
      // 五选一(MuxCase，按 int>fp>vec>v0>vl 优先)
      flAlloc = needIntDest[i] ? intAlloc[i]
              : needFpDest [i] ? fpAlloc [i]
              : needVecDest[i] ? vecAlloc[i]
              : needV0Dest [i] ? v0Alloc [i]
              : needVlDest [i] ? vlAlloc [i] : '0;
      // move-elim 源：口 0 用未清零的 raw psrc0(Scala uops(0).psrc.head)；
      // 口 i>0 用对外 psrc0(已含旁路与 LUI 清零，Scala io.out(i).bits.psrc(0))。
      pdest[i] = isMove[i] ? ((i == 0) ? psrc0Raw[0] : io_out_psrc[i][0]) : flAlloc;
      io_out_pdest[i]    = pdest[i];
      io_out_isMove_o[i] = isMove[i];   // eliminatedMove 与 isMove 输出都是它
    end

  // ===================================================================
  // 6. snapshot / allowSnpt
  //    允许打快照(allowSnpt)：① 与上个快照距离够远(notInSameSnpt，打一拍)
  //    ② 上拍没刚建快照 ③ 当前 head 是 firstUop。
  //    某口真正打快照：allowSnpt && 它是 CFI(有 brType 或 isJump) && fire。
  //    genSnapshot：本拍只要有任一口要打快照(且能 fire)就触发 FreeList 入快照。
  // ===================================================================
  logic lastCycleCreateSnpt;
  logic notInSameSnpt;          // 打一拍后的值
  wire allowSnpt = notInSameSnpt & ~lastCycleCreateSnpt & io_in_bits[0].firstUop;

  // 各口是否 fire(in ready & valid)。in_ready 见第 7 节。
  logic [RENAME_WIDTH-1:0] inFire;
  always_comb for (int i = 0; i < RENAME_WIDTH; i++) inFire[i] = io_in_ready[i] & io_in_valid[i];

  logic [RENAME_WIDTH-1:0] snapshotVec;
  always_comb
    for (int i = 0; i < RENAME_WIDTH; i++)
      snapshotVec[i] = allowSnpt
                     & ((|io_in_bits[i].preDecodeInfo_brType) | io_in_bits[i].fuType[0])
                     & inFire[i];
  always_comb for (int i = 0; i < RENAME_WIDTH; i++) io_out_snapshot[i] = snapshotVec[i];

  // genSnapshot = OR over (out.fire && snapshot)。注意：out.fire 与 snapshot 自身的
  // in.fire 不同，需额外要求该口 out 也 fire(out_ready & out_valid)，与 Scala 一致。
  logic [RENAME_WIDTH-1:0] outFire;
  always_comb for (int i = 0; i < RENAME_WIDTH; i++) outFire[i] = io_out_ready[i] & io_out_valid[i];
  assign genSnapshot = |(outFire & snapshotVec);

  // notInSameSnpt = RegNext( distanceBetween(robIdxHeadNext, snptLastEnq) >= dist
  //                          || !snptLastEnq.valid )
  // distanceBetween(循环指针距离)：同 flag 时 = headNext - lastEnq；异 flag 时还要
  // 减去半圈偏移(0x60)。阈值 sameSnptDistance=RobCommitWidth*4=24，golden 用"距离的
  // 高 3bit [7:5] 非零"近似判断 >=32(>=0x20)，本核逐位复刻该表达式以严格对齐 golden。
  localparam logic [ROB_PTR_W-1:0] ROB_HALF_WRAP = ROB_PTR_W'(256 - ROB_SIZE);  // 8'h60
  wire [ROB_PTR_W-1:0] snptDistSame = robIdxHeadNext_value - io_snptLastEnq_bits_value;                 // 同 flag
  wire [ROB_PTR_W-1:0] snptDistDiff = robIdxHeadNext_value - ROB_HALF_WRAP - io_snptLastEnq_bits_value; // 异 flag
  wire [2:0] snptDistHi = (robIdxHeadNext_flag == io_snptLastEnq_bits_flag) ? snptDistSame[7:5] : snptDistDiff[7:5];
  wire notInSameSnptNext = (|snptDistHi) | ~io_snptLastEnq_valid;

  always_ff @(posedge clock or posedge reset)
    if (reset) begin
      lastCycleCreateSnpt <= 1'b0;
      notInSameSnpt       <= 1'b0;
    end else begin
      lastCycleCreateSnpt <= genSnapshot & ~io_snptIsFull;
      notInSameSnpt       <= notInSameSnptNext;
    end

  // ===================================================================
  // 7. in_ready / out_valid / 各类 SpecWen(RAT 写口)
  // ===================================================================
  always_comb
    for (int i = 0; i < RENAME_WIDTH; i++) begin
      io_in_ready[i]  = ~io_in_valid[0] | canOut;
      io_out_valid[i] = io_in_valid[i] & intCanAlloc & fpCanAlloc & vecCanAlloc
                      & v0CanAlloc & vlCanAlloc & ~isWalk;
    end

  // SpecWen[i] = needXDest & X.canAlloc & X.doAlloc & !walk & !redirect
  wire notWalkRedir = ~isWalk & ~io_redirect_valid;
  always_comb
    for (int i = 0; i < COMMIT_WIDTH; i++) begin
      io_intRenamePorts[i].wen  = needIntDest[i] & intCanAlloc & intDoAlloc & notWalkRedir;
      io_intRenamePorts[i].addr = {1'b0, io_in_bits[i].ldest[INT_RAT_AW-1:0]};
      io_intRenamePorts[i].data = pdest[i];   // = out.pdest(含 move-elim)

      io_fpRenamePorts[i].wen   = needFpDest[i] & fpCanAlloc & fpDoAlloc & notWalkRedir;
      io_fpRenamePorts[i].addr  = io_in_bits[i].ldest;
      io_fpRenamePorts[i].data  = fpAlloc[i];

      io_vecRenamePorts[i].wen  = needVecDest[i] & vecCanAlloc & vecDoAlloc & notWalkRedir;
      io_vecRenamePorts[i].addr = io_in_bits[i].ldest;
      io_vecRenamePorts[i].data = vecAlloc[i];

      io_v0RenamePorts_wen [i]  = needV0Dest[i] & v0CanAlloc & v0DoAlloc & notWalkRedir;
      io_v0RenamePorts_data[i]  = v0Alloc[i];

      io_vlRenamePorts_wen [i]  = needVlDest[i] & vlCanAlloc & vlDoAlloc & notWalkRedir;
      io_vlRenamePorts_data[i]  = vlAlloc[i];
    end

  // ===================================================================
  // 8. 输出：直通字段 + 改写字段 + hasException
  // ===================================================================
  // hasException：前端异常(selectFrontend = idx 0,1,2,3,12,20,22) | illegalInstr(2) |
  //   virtualInstr(22) | Dmode 触发(trigger == 4'h1)。
  always_comb
    for (int i = 0; i < RENAME_WIDTH; i++) begin
      logic exc;
      exc = io_in_bits[i].exceptionVec[0]  | io_in_bits[i].exceptionVec[1]
          | io_in_bits[i].exceptionVec[2]  | io_in_bits[i].exceptionVec[3]
          | io_in_bits[i].exceptionVec[12] | io_in_bits[i].exceptionVec[20]
          | io_in_bits[i].exceptionVec[22];
      io_out_hasException[i] = exc | (io_in_bits[i].trigger == 4'h1);
    end

  // fused-lui-load(口 i>0)：上一条是 LUI(selImm==U & srcType0!=pc) 且本条是 load
  // 且上一条写整数 ldest == 本条 lsrc0 → 本条 srcType0 置 imm(0)，imm 改成
  // {prev.imm[19:0], imm[11:0]}(load 的基址被 LUI 立即数顶替)。
  logic [RENAME_WIDTH-1:0] fusedLuiLoad;
  always_comb
    for (int i = 0; i < RENAME_WIDTH; i++) begin
      fusedLuiLoad[i] = 1'b0;
      if (i > 0)
        fusedLuiLoad[i] = (io_in_bits[i-1].selImm == SEL_IMM_U) & (|io_in_bits[i-1].srcType[0])
                        & (io_in_bits[i].fuType == FU_LDU) & needIntDest[i-1]
                        & (io_in_bits[i-1].ldest == io_in_bits[i].lsrc[0]);
    end
  always_comb
    for (int i = 0; i < RENAME_WIDTH; i++)
      io_out_srcType0[i] = fusedLuiLoad[i] ? SRC_IMM : io_in_bits[i].srcType[0];

  // imm 改写(fence / lui32 融合 / fused-lui-load)：
  //   selImm==LUI32 & fuType==alu → {imm[19:0], next.imm[11:0]}  (lui+addi(w) 融合)
  //   fused-lui-load(i>0) → {prev.imm[19:0], imm[11:0]}
  //   fuType==fence → {0, lsrc1, lsrc0}
  //   否则 → 零扩展 imm
  always_comb
    for (int i = 0; i < RENAME_WIDTH; i++) begin
      logic lui32, fence;
      lui32   = (io_in_bits[i].selImm == SEL_IMM_LUI32) & (io_in_bits[i].fuType == FU_ALU);
      fence   = (io_in_bits[i].fuType == FU_FENCE);
      if (fusedLuiLoad[i])
        io_out_imm[i] = {io_in_bits[(i == 0) ? 0 : i-1].imm[19:0], io_in_bits[i].imm[11:0]};
      else if (lui32 && i < RENAME_WIDTH-1)
        io_out_imm[i] = {io_in_bits[i].imm[19:0], io_in_bits[(i == RENAME_WIDTH-1) ? i : i+1].imm[11:0]};
      else if (fence)
        io_out_imm[i] = {20'h0, io_in_bits[i].lsrc[1], io_in_bits[i].lsrc[0]};
      else
        io_out_imm[i] = {10'h0, io_in_bits[i].imm};
    end

  // renameTime：debug 观测计数器。golden 每口一个独立 64bit 计数器
  //   uops_i_debugInfo_renameTime_c，均复位 0、每拍无条件 +1。逐口独立复刻以与 golden
  //   结构 1:1 对应(单一全局计数器会让 FM 的寄存器配对缺口)。
  logic [63:0] renameTime_c [RENAME_WIDTH];
  always_ff @(posedge clock or posedge reset)
    if (reset)
      for (int i = 0; i < RENAME_WIDTH; i++) renameTime_c[i] <= 64'h0;
    else
      for (int i = 0; i < RENAME_WIDTH; i++) renameTime_c[i] <= renameTime_c[i] + 64'h1;
  always_comb for (int i = 0; i < RENAME_WIDTH; i++) io_out_debugInfo_renameTime[i] = renameTime_c[i];

  // 直通字段：直接把输入 struct 透传(wrapper 只取 DynInst 里存在的字段)
  always_comb for (int i = 0; i < RENAME_WIDTH; i++) io_out_passthru[i] = io_in_bits[i];

  // ---- 压缩 ROB-slot 折叠字段(严格复刻 golden uops_i_*)----
  // ftqPtr/ftqOffset：口 i 若前序口(i-1)不独占 ROB 槽(~needRobFlags[i-1]),则继承已折叠
  //   的 uops_{i-1} 值(压缩组内共享组头 ftq);否则取本口 in。口 0 直通。递归 fold。
  // firstUop：口 0 直通;口 i>0 = needRobFlags[i-1] & in_i.firstUop。
  logic       fldFtqFlag  [RENAME_WIDTH];
  logic [5:0] fldFtqValue [RENAME_WIDTH];
  logic [3:0] fldFtqOff   [RENAME_WIDTH];
  always_comb begin
    fldFtqFlag [0] = io_in_bits[0].ftqPtr_flag;
    fldFtqValue[0] = io_in_bits[0].ftqPtr_value;
    fldFtqOff  [0] = io_in_bits[0].ftqOffset;
    for (int i = 1; i < RENAME_WIDTH; i++) begin
      fldFtqFlag [i] = needRobFlags[i-1] ? io_in_bits[i].ftqPtr_flag  : fldFtqFlag [i-1];
      fldFtqValue[i] = needRobFlags[i-1] ? io_in_bits[i].ftqPtr_value : fldFtqValue[i-1];
      fldFtqOff  [i] = needRobFlags[i-1] ? io_in_bits[i].ftqOffset    : fldFtqOff  [i-1];
    end
  end
  always_comb
    for (int i = 0; i < RENAME_WIDTH; i++) begin
      io_out_ftqPtr_flag_o [i] = fldFtqFlag [i];
      io_out_ftqPtr_value_o[i] = fldFtqValue[i];
      io_out_ftqOffset_o   [i] = fldFtqOff  [i];
      io_out_firstUop_o    [i] = (i == 0) ? io_in_bits[0].firstUop
                                          : (needRobFlags[(i == 0) ? 0 : i-1] & io_in_bits[i].firstUop);
    end

  // ---- waitForward/blockBackward：合法只读 CSR 读免屏障 ----
  //   isCsrr = SYSTEM(opcode[6:2]=0x1C) & funct3 有效(|instr[13:12]) & instr[13]
  //            & rs1(instr[19:15])==0 —— 即 csrr rd,csr,x0 形式的 CSR 读。
  //   golden 两字段用【不同白名单】(CSROoORead.scala)：
  //     waitForwardInOrderCsrReadList(27 个)：fflags/fcsr/vxsat/vcsr/vstart/sstatus/vsstatus/
  //       mstatus/hstatus/mnstatus/dcsr/vtype/mireg/sireg/vsireg/mtopi/stopi/vstopi/mtopei/
  //       stopei/vstopei/mip/sip/vsip/hip/hvip/mvip；
  //     blockBackwardInOrderCsrReadList(15 个)：mireg…mvip 那一段(AIA 间接寄存器与中断挂起位)。
  //   这些 CSR 的读**必须**保序，所以只有【不在】名单里的 csrr 才免屏障：
  //   out.X = in.X & ~(isCsrr & ~inList_X)。
  function automatic logic csr_in_block_list(input logic [11:0] csr);
    return (csr == 12'h351) | (csr == 12'h151) | (csr == 12'h251)    // mireg / sireg / vsireg
         | (csr == 12'hFB0) | (csr == 12'hDB0) | (csr == 12'hEB0)    // mtopi / stopi / vstopi
         | (csr == 12'h35C) | (csr == 12'h15C) | (csr == 12'h25C)    // mtopei / stopei / vstopei
         | (csr == 12'h344) | (csr == 12'h144) | (csr == 12'h244)    // mip / sip / vsip
         | (csr == 12'h644) | (csr == 12'h645) | (csr == 12'h309);   // hip / hvip / mvip
  endfunction
  function automatic logic csr_in_wait_list(input logic [11:0] csr);
    return csr_in_block_list(csr)
         | (csr == 12'h001) | (csr == 12'h003) | (csr == 12'h009)    // fflags / fcsr / vxsat
         | (csr == 12'h00F) | (csr == 12'h008)                       // vcsr / vstart
         | (csr == 12'h100) | (csr == 12'h200) | (csr == 12'h300)    // sstatus / vsstatus / mstatus
         | (csr == 12'h600) | (csr == 12'h744) | (csr == 12'h7B0)    // hstatus / mnstatus / dcsr
         | (csr == 12'hC21);                                         // vtype
  endfunction

  logic [RENAME_WIDTH-1:0] isCsrr;
  always_comb
    for (int i = 0; i < RENAME_WIDTH; i++)
      isCsrr[i] = (io_in_bits[i].instr[6:2] == 5'h1C) & (|io_in_bits[i].instr[13:12])
                & io_in_bits[i].instr[13] & (io_in_bits[i].instr[19:15] == 5'h0);
  always_comb
    for (int i = 0; i < RENAME_WIDTH; i++) begin
      io_out_waitForward_o  [i] = io_in_bits[i].waitForward   & ~(isCsrr[i] & ~csr_in_wait_list (io_in_bits[i].instr[31:20]));
      io_out_blockBackward_o[i] = io_in_bits[i].blockBackward & ~(isCsrr[i] & ~csr_in_block_list(io_in_bits[i].instr[31:20]));
    end

  // ===================================================================
  // 9. 译码级压缩机器(依赖 CompressUnit 的 masks/instrSizes/needRobFlags/canCompressVec)
  //   numLsElem / dirtyVs / dirtyFs / wfflags / debug_sim_trig / instrSize / numUops / numWB /
  //   traceBlockInPipe.{itype,iretire,ilastsize} / lastUop(压缩精确化)。
  // ===================================================================

  // ---- 公共：压缩窗口聚合(mask 为 6 位，位 j=1 表示口 j 属于本口的压缩组) ----
  // wfflags/dirtyFs/dirtyVs/debug_sim_trig 均为「mask & 各口某属性位向量」的 OR 归并。
  function automatic logic mask_any(input logic [5:0] mask, input logic [RENAME_WIDTH-1:0] attr);
    return |(mask & attr);
  endfunction

  logic [RENAME_WIDTH-1:0] attrWfflags, attrFpWen, attrDirtyVs, attrSimTrig;
  always_comb
    for (int j = 0; j < RENAME_WIDTH; j++) begin
      logic isVecUop, isAmoCas, isVfmvFs, isVcpopM, isVfirstM, isVmvXs;
      attrWfflags[j] = io_in_bits[j].wfflags;
      attrFpWen  [j] = io_in_bits[j].fpWen;
      // dirtyVs 单口判定：① uopSplitType != SCA_SIM(=0)，即确为向量 uop；
      //   ② 排除原子 CAS(走 mou，不改向量状态)；
      //   ③ 排除 4 条「读向量但不改向量状态」的指令：vfmv.f.s / vcpop.m / vfirst.m / vmv.x.s。
      isVecUop  = |io_in_bits[j].uopSplitType;
      isAmoCas  = (io_in_bits[j].uopSplitType == USPLIT_AMOCAS_W)
                | (io_in_bits[j].uopSplitType == USPLIT_AMOCAS_D)
                | (io_in_bits[j].uopSplitType == USPLIT_AMOCAS_Q);
      isVfmvFs  = io_in_bits[j].fuType[FUB_VFALU] & (io_in_bits[j].fuOpType == VOP_VFMV_F_S);
      isVcpopM  = io_in_bits[j].fuType[FUB_VIPU]  & (io_in_bits[j].fuOpType == VOP_VCPOP_M);
      isVfirstM = io_in_bits[j].fuType[FUB_VIPU]  & (io_in_bits[j].fuOpType == VOP_VFIRST_M);
      isVmvXs   = io_in_bits[j].fuType[FUB_VIPU]  & (io_in_bits[j].fuOpType == VOP_VMV_X_S);
      attrDirtyVs[j] = isVecUop & ~isAmoCas & ~(isVfmvFs | isVcpopM | isVfirstM | isVmvXs);
      // 仿真调试触发 HINT
      attrSimTrig[j] = (io_in_bits[j].instr == SIM_TRIG_INSTR);
    end
  always_comb
    for (int i = 0; i < RENAME_WIDTH; i++) begin
      io_out_wfflags_o     [i] = mask_any(cmpMasks[i], attrWfflags);
      io_out_dirtyFs       [i] = mask_any(cmpMasks[i], attrFpWen);
      io_out_dirtyVs       [i] = mask_any(cmpMasks[i], attrDirtyVs);
      io_out_debug_sim_trig[i] = mask_any(cmpMasks[i], attrSimTrig);
    end

  // instrSize：直接取 CompressUnit 的 instrSizes(压缩后本组指令数)。
  always_comb for (int i = 0; i < RENAME_WIDTH; i++) io_out_instrSize[i] = instrSizes[i];

  // lastUop(压缩精确化)：仅当本口需独占 ROB 槽(needRobFlags)且原本就是 lastUop 时为真。
  always_comb
    for (int i = 0; i < RENAME_WIDTH; i++)
      io_out_lastUop_o[i] = needRobFlags[i] & io_in_bits[i].lastUop;

  // numUops / numWB(压缩后)：
  //   压缩值 compressedCnt = instrSizes(i) - PopCount(masks(i) & isMove)
  //     —— 压缩组里被 move 消除的 uop 不占 uop 也不写回。
  //   优先级(高→低，对应 Scala 后置 when 覆盖前置)：
  //     ① !needRobFlags(i)                → compressedCnt
  //     ② i>0 且 !needRobFlags(i-1)       → compressedCnt
  //     ③ isMove(i) | hasException(i)     → 0
  //     ④ 否则                            → in.numUops / in.numWB
  logic [2:0] compressedCnt [RENAME_WIDTH];
  always_comb
    for (int i = 0; i < RENAME_WIDTH; i++) begin
      logic [2:0] moveCnt; moveCnt = '0;
      for (int j = 0; j < RENAME_WIDTH; j++)
        if (cmpMasks[i][j] & isMove[j]) moveCnt += 3'b1;
      compressedCnt[i] = instrSizes[i] - moveCnt;
    end
  always_comb
    for (int i = 0; i < RENAME_WIDTH; i++) begin
      logic prevNoRob, zeroIt;
      prevNoRob = (i > 0) ? ~needRobFlags[(i == 0) ? 0 : i-1] : 1'b0;   // 口 0 视作前序需 ROB
      zeroIt    = isMove[i] | io_out_hasException[i];
      if (!needRobFlags[i] || prevNoRob) begin
        io_out_numUops_o[i] = {4'h0, compressedCnt[i]};
        io_out_numWB_o  [i] = {4'h0, compressedCnt[i]};
      end else begin
        io_out_numUops_o[i] = zeroIt ? 7'h0 : io_in_bits[i].numUops;
        io_out_numWB_o  [i] = zeroIt ? 7'h0 : io_in_bits[i].numWB;
      end
    end

  // ---- trace 用 halfWordNum / iLastSize(单口) ----
  // RVC(16bit)算 1 个半字、非 RVC(32bit)算 2 个半字；ilastsize：RVC→HalfWord(0)、否则 Word(1)。
  logic [1:0] halfWordNum [RENAME_WIDTH];
  always_comb
    for (int j = 0; j < RENAME_WIDTH; j++)
      halfWordNum[j] = io_in_bits[j].preDecodeInfo_isRVC ? 2'h1 : 2'h2;

  // isFusion：commitType[2]=1 表示该口是融合指令(吞掉下一条)。
  logic [RENAME_WIDTH-1:0] isFusion;
  always_comb for (int j = 0; j < RENAME_WIDTH; j++) isFusion[j] = io_in_bits[j].commitType[2];

  // traceBlockInPipe.iretire：本块退休的「半字数」。
  //   可压缩(canCompressVec)：累加压缩组里各口 halfWordNum；
  //   否则：本口 halfWordNum + (若本口是融合指令则再加下一口 halfWordNum)。
  always_comb
    for (int i = 0; i < RENAME_WIDTH; i++) begin
      logic [3:0] sum;
      if (canCompressVec[i]) begin
        sum = '0;
        for (int j = 0; j < RENAME_WIDTH; j++)
          if (cmpMasks[i][j]) sum += {2'h0, halfWordNum[j]};
      end else begin
        sum = {2'h0, halfWordNum[i]};
        if ((i < RENAME_WIDTH-1) && isFusion[i]) sum += {2'h0, halfWordNum[(i == RENAME_WIDTH-1) ? i : i+1]};
      end
      io_out_iretire[i] = sum;
    end

  // traceBlockInPipe.ilastsize：本块最后一条指令的尺寸(0=HalfWord/RVC, 1=Word)。
  //   可压缩：取压缩组里【最高被置位口】的 isRVC(取反得 ilastsize)；
  //   否则：本口(融合时取下一口)的 isRVC 取反。
  always_comb
    for (int i = 0; i < RENAME_WIDTH; i++) begin
      logic lastIsRVC;
      if (canCompressVec[i]) begin
        lastIsRVC = 1'b0;
        // foldLeft 等价：从低到高遍历，命中口覆盖 → 最终最高命中口生效
        for (int j = 0; j < RENAME_WIDTH; j++)
          if (cmpMasks[i][j]) lastIsRVC = io_in_bits[j].preDecodeInfo_isRVC;
      end else begin
        if ((i < RENAME_WIDTH-1) && isFusion[i]) lastIsRVC = io_in_bits[(i == RENAME_WIDTH-1) ? i : i+1].preDecodeInfo_isRVC;
        else                                      lastIsRVC = io_in_bits[i].preDecodeInfo_isRVC;
      end
      io_out_ilastsize[i] = ~lastIsRVC;  // RVC→0(HalfWord)，非 RVC→1(Word)
    end

  // traceBlockInPipe.itype：跳转/分支类型(供 trace 推断控制流)。
  //   isXret：CSR systemop(fuType[csr] & fuOpType[4] & csrAddr[11:1]非零) → ExpIntReturn(3)。
  //   否则用 jumpTypeGen(brType, rd=ldest, rs=lsrc0)：
  //     依 brType(jal/jalr/branch) 与 rd/rs 是否链接寄存器(x1/x5)/x0 分类(8..15)。
  //     非分支非跳转 → None(0)。
  function automatic logic [3:0] jump_type_gen
      (input logic [1:0] brType, input logic [LREG_W-1:0] rd, input logic [LREG_W-1:0] rs);
    logic isEqualRdRs, isJal, isJalr, isBranch;
    logic rdLink, rsLink, rdX0;
    logic isUninferCall, isInferCall, isUninferTail, isInferTail;
    logic isCoSwap, isFuncRet, isOtherUninfer, isOtherInfer;
    begin
      isEqualRdRs = (rd == rs);
      isJal       = (brType == BRTYPE_JAL);
      isJalr      = (brType == BRTYPE_JALR);
      isBranch    = (brType == BRTYPE_BRANCH);
      rdLink = (rd == 6'h1) | (rd == 6'h5);    // x1/x5 为链接寄存器
      rsLink = (rs == 6'h1) | (rs == 6'h5);
      rdX0   = (rd == 6'h0);
      isUninferCall  = isJalr & rdLink & (~rsLink | (rsLink & isEqualRdRs));   // 8
      isInferCall    = isJal  & rdLink;                                        // 9
      isUninferTail  = isJalr & rdX0 & ~rsLink;                                // 10
      isInferTail    = isJal  & rdX0;                                          // 11
      isCoSwap       = isJalr & rdLink & rsLink & ~isEqualRdRs;                // 12
      isFuncRet      = isJalr & ~rdLink & rsLink;                              // 13
      isOtherUninfer = isJalr & ~rdLink & ~rdX0 & ~rsLink;                     // 14
      isOtherInfer   = isJal  & ~rdLink & ~rdX0;                               // 15
      // Mux1H(各互斥条件 → 对应编码)；非分支/非跳转 → None
      if      (isBranch)        jump_type_gen = ITYPE_BRANCH;
      else if (isUninferCall)   jump_type_gen = ITYPE_UNINFERABLE_CALL;
      else if (isInferCall)     jump_type_gen = ITYPE_INFERABLE_CALL;
      else if (isUninferTail)   jump_type_gen = ITYPE_UNINFERABLE_TAILCALL;
      else if (isInferTail)     jump_type_gen = ITYPE_INFERABLE_TAILCALL;
      else if (isCoSwap)        jump_type_gen = ITYPE_COROUTINE_SWAP;
      else if (isFuncRet)       jump_type_gen = ITYPE_FUNCTION_RETURN;
      else if (isOtherUninfer)  jump_type_gen = ITYPE_OTHER_UNINFER_JUMP;
      else if (isOtherInfer)    jump_type_gen = ITYPE_OTHER_INFER_JUMP;
      else                      jump_type_gen = ITYPE_NONE;
    end
  endfunction

  always_comb
    for (int i = 0; i < RENAME_WIDTH; i++) begin
      logic isXret;
      // CSR systemop 且 csrAddr[11:1] 非零(排除 ebreak/ecall)；csrAddr 取自 imm[11:0]。
      isXret = io_in_bits[i].fuType[FUB_CSR] & io_in_bits[i].fuOpType[4]
             & (|io_in_bits[i].imm[11:1]);
      io_out_itype[i] = isXret ? ITYPE_EXP_INT_RETURN
                              : jump_type_gen(io_in_bits[i].preDecodeInfo_brType,
                                              io_in_bits[i].ldest, io_in_bits[i].lsrc[0]);
    end

  // ===================================================================
  // 10. numLsElem(向量访存元素流数)
  //   仅对向量访存(isVlsType)、非 vleff-末uop 的有效指令计算，否则为 0。
  //   instType = {isSegment(fuType[vseg*]), mop(fuOpType[6:5])}；
  //   emul：isWhole → GenUSWholeEmul(nf)；isMasked → 0；否则 veew - vsew + vlmul。
  //   numLsElem：
  //     unit-stride(isAllUS)        → VEC_US_MAX_FLOW(=2)
  //     else 按 instType 选流数(GenRealFlowNum)：
  //       000/010/100/110(US/strided/segUS/segStrided) → MulDataSize(emul) >> veew
  //       001/011(indexed)         → emul>lmul ? (MulDataSize(emul)>>veew) : (MulDataSize(lmul)>>vsew)
  //       101/111(seg indexed)     → 同上(段)
  //   MulDataSize(mul) 把 emul/lmul 译成「整寄存器需写字节数」(2/4/8/16)，
  //   再 >> eew(每次写字节数 log2)得到元素流数。本核用 mul_data_size 函数复刻该查表。
  // ===================================================================
  // MulDataSize 查表(返回 5bit, 足够容纳 16)：mul∈{0,1,2,3}→16; 7→8; 6→4; 5→2(其余→0)
  function automatic logic [4:0] mul_data_size(input logic [2:0] mul);
    begin
      priority case (mul)
        3'h0, 3'h1, 3'h2, 3'h3: mul_data_size = 5'd16;
        3'h7:                   mul_data_size = 5'd8;
        3'h6:                   mul_data_size = 5'd4;
        3'h5:                   mul_data_size = 5'd2;
        default:                mul_data_size = 5'd0;
      endcase
    end
  endfunction

  logic [2:0] vlsNf   [RENAME_WIDTH];   // 整寄存器 whole-load 的 nf 修正
  logic [2:0] vlsEmul [RENAME_WIDTH];
  logic [2:0] vlsInstType [RENAME_WIDTH];
  logic [RENAME_WIDTH-1:0] vlsIsVls, vlsIsAllUS;
  always_comb
    for (int i = 0; i < RENAME_WIDTH; i++) begin
      logic [8:0] op; logic isWhole, isMasked, usSel, segBit;
      logic [2:0] eewSubSew;
      op = io_in_bits[i].fuOpType;
      // isWhole/isMasked/isAllUS：均要求 mop(op[6:5])==0 且 (op[8]^op[7])
      usSel    = (op[8] ^ op[7]) & ~(|op[6:5]);
      isWhole  = usSel & (op[4:0] == 5'h08);
      isMasked = usSel & (op[4:0] == 5'h0B);
      vlsIsAllUS[i] = usSel;
      // nf：whole-load 强制 0(整寄存器搬运不分 field)，否则取 vpu.nf
      vlsNf[i] = isWhole ? 3'h0 : io_in_bits[i].vpu_nf;
      // emul 选择：isWhole→GenUSWholeEmul(nf)(000→0,001→1,011→2,111→3,其余 0)；
      //   isMasked→0；否则 veew - vsew + vlmul
      eewSubSew = {1'b0, io_in_bits[i].vpu_veew} - {1'b0, io_in_bits[i].vpu_vsew}
                + io_in_bits[i].vpu_vlmul;
      if (isWhole) begin
        vlsEmul[i] = ((vlsNf[i] == 3'h1) ? 3'h1 : 3'h0)
                   | ((vlsNf[i] == 3'h3) ? 3'h2 : 3'h0)
                   | ((vlsNf[i] == 3'h7) ? 3'h3 : 3'h0);
      end else if (isMasked) begin
        vlsEmul[i] = 3'h0;
      end else begin
        vlsEmul[i] = eewSubSew;
      end
      // instType = {isSegment, mop}
      segBit = io_in_bits[i].fuType[FUB_VSEGLDU] | io_in_bits[i].fuType[FUB_VSEGSTU];
      vlsInstType[i] = {segBit, op[6:5]};
      // isVlsType = 任一向量访存 fuType
      vlsIsVls[i] = io_in_bits[i].fuType[FUB_VLDU] | io_in_bits[i].fuType[FUB_VSTU]
                  | io_in_bits[i].fuType[FUB_VSEGLDU] | io_in_bits[i].fuType[FUB_VSEGSTU];
    end

  always_comb
    for (int i = 0; i < RENAME_WIDTH; i++) begin
      logic [4:0] flowNum, eewFlow, sewFlow, idxFlow;
      logic       emulGtLmul, gateOK;
      // emul/lmul 有符号比较(3bit, 5/6/7 表示 1/8..1/2 即负数, 0..3 表示 1..8)
      emulGtLmul = ($signed(vlsEmul[i]) > $signed(io_in_bits[i].vpu_vlmul));
      eewFlow = mul_data_size(vlsEmul[i])              >> io_in_bits[i].vpu_veew;
      sewFlow = mul_data_size(io_in_bits[i].vpu_vlmul) >> io_in_bits[i].vpu_vsew;
      idxFlow = emulGtLmul ? eewFlow : sewFlow;        // indexed / seg-indexed
      // GenRealFlowNum 按 instType 选择(priority 互斥)
      priority case (vlsInstType[i])
        3'b000, 3'b010, 3'b100, 3'b110: flowNum = eewFlow;  // US / strided / segUS / segStrided
        3'b001, 3'b011:                 flowNum = idxFlow;  // indexed un/ordered
        3'b101, 3'b111:                 flowNum = idxFlow;  // seg indexed un/ordered
        default:                        flowNum = 5'h0;
      endcase
      // unit-stride 走固定上限 VEC_US_MAX_FLOW
      flowNum = vlsIsAllUS[i] ? 5'(VEC_US_MAX_FLOW) : flowNum;
      // 门控：有效 & 向量访存 & 非(vleff 且压缩后末 uop)
      gateOK = io_in_valid[i] & vlsIsVls[i]
             & ~(io_in_bits[i].vpu_isVleff & io_out_lastUop_o[i]);
      io_out_numLsElem[i] = gateOK ? flowNum : 5'h0;
    end

  // ===================================================================
  // 11. stallReason(topdown 反压归因)：严格复刻 golden。
  //   backReason_valid = out.backReason.valid | ~in0.ready
  //   backReason_bits  = 优先级级联(golden priority chain):
  //     out.backReason.valid                     → OtherCoreStall(后端反压)
  //     ctrlRecStall / mvioRecStall / otherRecStall → 三种 recovery
  //     multiFlStall 且仅 int/fp/vec/v0/vl 之一无法分配 → 对应 FlStall
  //     multiFlStall 且 (≥2 个 FreeList 不足)     → MultiFlStall
  //     否则                                     → OtherCoreStall
  //   out.reason[i] = backReason_valid ? backReason_bits : in.reason[i]
  //   debugRedirect_debugIsCtrl/MemVio: 锁存 redirect 的 debug 标志(walk 期回放用)。
  // ===================================================================
  // golden: 仅在 io_redirect_valid 拍锁存(带使能, 无 reset), walk 期用上次 redirect 值。
  logic debugRedirect_debugIsCtrl, debugRedirect_debugIsMemVio;
  always_ff @(posedge clock)
    if (io_redirect_valid) begin
      debugRedirect_debugIsCtrl   <= io_redirect_bits_debugIsCtrl;
      debugRedirect_debugIsMemVio <= io_redirect_bits_debugIsMemVio;
    end

  wire recStall     = io_redirect_valid | isWalk;
  wire ctrlRecStall = io_redirect_valid ? io_redirect_bits_debugIsCtrl
                                        : (isWalk & debugRedirect_debugIsCtrl);
  wire mvioRecStall = io_redirect_valid ? io_redirect_bits_debugIsMemVio
                                        : (isWalk & debugRedirect_debugIsMemVio);
  wire otherRecStall = recStall & ~(ctrlRecStall | mvioRecStall);
  // notRecStall & inHeadValid: out0 未有效 & 非重定向/walk 反压 & in0 有效
  wire flStallBase = ~io_out_valid[0] & ~recStall & io_in_valid[0];
  // 不足的 FreeList 个数(0..5)
  logic [2:0] flShortCnt;
  always_comb
    flShortCnt = 3'({1'b0, ~intCanAlloc}) + 3'({1'b0, ~fpCanAlloc})
               + 3'({1'b0, ~vecCanAlloc}) + 3'({1'b0, ~v0CanAlloc})
               + 3'({1'b0, ~vlCanAlloc});

  logic [5:0] backReasonBits;
  always_comb begin
    if (io_stallReason_out_backReason_valid)                                  backReasonBits = TD_OTHER_CORE_STALL;
    else if (ctrlRecStall)                                                    backReasonBits = TD_CTRL_RECOVERY;
    else if (mvioRecStall)                                                    backReasonBits = TD_MEMVIO_RECOVERY;
    else if (otherRecStall)                                                   backReasonBits = TD_OTHER_RECOVERY;
    else if (flStallBase & fpCanAlloc & vecCanAlloc & v0CanAlloc & vlCanAlloc & ~intCanAlloc)  backReasonBits = TD_INT_FL_STALL;
    else if (flStallBase & intCanAlloc & vecCanAlloc & v0CanAlloc & vlCanAlloc & ~fpCanAlloc)  backReasonBits = TD_FP_FL_STALL;
    else if (flStallBase & intCanAlloc & fpCanAlloc & v0CanAlloc & vlCanAlloc & ~vecCanAlloc)  backReasonBits = TD_VEC_FL_STALL;
    else if (flStallBase & intCanAlloc & fpCanAlloc & vecCanAlloc & vlCanAlloc & ~v0CanAlloc)  backReasonBits = TD_V0_FL_STALL;
    else if (flStallBase & intCanAlloc & fpCanAlloc & vecCanAlloc & v0CanAlloc & ~vlCanAlloc)  backReasonBits = TD_VL_FL_STALL;
    else if (flStallBase & (|flShortCnt[2:1]))                                backReasonBits = TD_MULTI_FL_STALL;
    else                                                                      backReasonBits = TD_OTHER_CORE_STALL;
  end

  always_comb begin
    io_stallReason_in_backReason_valid = io_stallReason_out_backReason_valid | ~io_in_ready[0];
    io_stallReason_in_backReason_bits  = backReasonBits;
    for (int i = 0; i < RENAME_WIDTH; i++)
      io_stallReason_out_reason[i] = io_stallReason_in_backReason_valid
                                   ? backReasonBits : io_stallReason_in_reason[i];
  end

  // ===================================================================
  // 12. perf 事件流水线(严格复刻 golden)：30 个 io_perf.value，每个都经两级寄存器
  //   (io_perf_N_value_REG → io_perf_N_value_REG_1)后输出，两级都不复位。
  //   src 映射：
  //     0  = Σ(in_i.valid & in_ready[0])            —— 本拍派发条数(3bit)
  //     1  = Σ(in_i.valid & ~in_ready[0])           —— 本拍阻塞条数(3bit)
  //     2  = in0.valid & ~in_ready[0]               —— rename_stall
  //     3  = in0.valid & isWalk                     —— stall_cycle_walk
  //     4  = in0.valid & ~isWalk & ~out0.ready      —— stall_cycle_dispatch
  //     5..9 = 仅某一 FreeList 无法分配(其余四个可)时的阻塞事件(int/fp/vec/v0/vl)
  //     10..13 = intFreeList.perf0..3   14..17 = fpFreeList
  //     18..21 = vecFreeList            22..25 = v0FreeList   26..29 = vlFreeList
  //   ★寄存器宽度严格按 golden 分组★：0,1 是 3bit；2..9 是 1bit；10..29 是 6bit
  //   (FreeList 的 6 位 perf 输出整个打拍，其高 5 位恒 0 —— 与 golden 同构，
  //    FM 两侧对这些常量位做同样的处理)。
  // ---------------------------------------------------------------------
  logic [2:0] perfDispCnt, perfStallCnt;
  always_comb begin
    perfDispCnt  = '0;
    perfStallCnt = '0;
    for (int i = 0; i < RENAME_WIDTH; i++) begin
      perfDispCnt  += 3'({io_in_valid[i] &  io_in_ready[0]});
      perfStallCnt += 3'({io_in_valid[i] & ~io_in_ready[0]});
    end
  end
  // 仅某一 FreeList 阻塞：五者互斥模式(base & ~该 canAlloc & 其余全 canAlloc)
  wire perfBase = io_in_valid[0] & ~isWalk & io_out_ready[0];
  logic perfEvt [8];
  always_comb begin
    perfEvt[0] = io_in_valid[0] & ~io_in_ready[0];                                            // 2
    perfEvt[1] = io_in_valid[0] & isWalk;                                                     // 3
    perfEvt[2] = io_in_valid[0] & ~isWalk & ~io_out_ready[0];                                 // 4
    perfEvt[3] = perfBase & fpCanAlloc  & vecCanAlloc & v0CanAlloc & vlCanAlloc & ~intCanAlloc; // 5
    perfEvt[4] = perfBase & intCanAlloc & vecCanAlloc & v0CanAlloc & vlCanAlloc & ~fpCanAlloc;  // 6
    perfEvt[5] = perfBase & intCanAlloc & fpCanAlloc  & v0CanAlloc & vlCanAlloc & ~vecCanAlloc; // 7
    perfEvt[6] = perfBase & intCanAlloc & fpCanAlloc  & vecCanAlloc & vlCanAlloc & ~v0CanAlloc; // 8
    perfEvt[7] = perfBase & intCanAlloc & fpCanAlloc  & vecCanAlloc & v0CanAlloc & ~vlCanAlloc; // 9
  end
  logic [5:0] perfFl [20];
  always_comb
    for (int k = 0; k < 4; k++) begin
      perfFl[0+k]  = intFlPerf[k];   // 10..13
      perfFl[4+k]  = fpFlPerf [k];   // 14..17
      perfFl[8+k]  = vecFlPerf[k];   // 18..21
      perfFl[12+k] = v0FlPerf [k];   // 22..25
      perfFl[16+k] = vlFlPerf [k];   // 26..29
    end

  // 两级寄存器流水线(golden: _REG → _REG_1)，不复位。
  logic [2:0] perfCnt_REG [2],  perfCnt_REG_1 [2];    // idx 0,1
  logic       perfEvt_REG [8],  perfEvt_REG_1 [8];    // idx 2..9
  logic [5:0] perfFl_REG  [20], perfFl_REG_1  [20];   // idx 10..29
  always_ff @(posedge clock) begin
    perfCnt_REG[0] <= perfDispCnt;  perfCnt_REG_1[0] <= perfCnt_REG[0];
    perfCnt_REG[1] <= perfStallCnt; perfCnt_REG_1[1] <= perfCnt_REG[1];
    for (int i = 0; i < 8;  i++) begin perfEvt_REG[i] <= perfEvt[i]; perfEvt_REG_1[i] <= perfEvt_REG[i]; end
    for (int i = 0; i < 20; i++) begin perfFl_REG [i] <= perfFl [i]; perfFl_REG_1 [i] <= perfFl_REG [i]; end
  end

  always_comb begin
    io_perf_value[0] = {3'h0, perfCnt_REG_1[0]};
    io_perf_value[1] = {3'h0, perfCnt_REG_1[1]};
    for (int i = 0; i < 8;  i++) io_perf_value[2+i]  = {5'h0, perfEvt_REG_1[i]};
    for (int i = 0; i < 20; i++) io_perf_value[10+i] = perfFl_REG_1[i];
  end

endmodule

// =====================================================================
// golden 同名 wrapper —— 由 verif/ut/Rename/gen_rename.py 生成，改请改生成器
// (本行以下由生成器整段覆写；golden 扁平 1881 端口 ↔ 核 struct/数组 的机械拆装)
// =====================================================================
module Rename
  import rename_pkg::*;
(
  input         clock,
  input         reset,
  input         io_redirect_valid,
  input         io_redirect_bits_robIdx_flag,
  input  [7:0] io_redirect_bits_robIdx_value,
  input         io_redirect_bits_level,
  input         io_redirect_bits_debugIsCtrl,
  input         io_redirect_bits_debugIsMemVio,
  input         io_rabCommits_isCommit,
  input         io_rabCommits_commitValid_0,
  input         io_rabCommits_commitValid_1,
  input         io_rabCommits_commitValid_2,
  input         io_rabCommits_commitValid_3,
  input         io_rabCommits_commitValid_4,
  input         io_rabCommits_commitValid_5,
  input         io_rabCommits_isWalk,
  input         io_rabCommits_walkValid_0,
  input         io_rabCommits_walkValid_1,
  input         io_rabCommits_walkValid_2,
  input         io_rabCommits_walkValid_3,
  input         io_rabCommits_walkValid_4,
  input         io_rabCommits_walkValid_5,
  input         io_rabCommits_info_0_rfWen,
  input         io_rabCommits_info_0_fpWen,
  input         io_rabCommits_info_0_vecWen,
  input         io_rabCommits_info_0_v0Wen,
  input         io_rabCommits_info_0_vlWen,
  input         io_rabCommits_info_0_isMove,
  input         io_rabCommits_info_1_rfWen,
  input         io_rabCommits_info_1_fpWen,
  input         io_rabCommits_info_1_vecWen,
  input         io_rabCommits_info_1_v0Wen,
  input         io_rabCommits_info_1_vlWen,
  input         io_rabCommits_info_1_isMove,
  input         io_rabCommits_info_2_rfWen,
  input         io_rabCommits_info_2_fpWen,
  input         io_rabCommits_info_2_vecWen,
  input         io_rabCommits_info_2_v0Wen,
  input         io_rabCommits_info_2_vlWen,
  input         io_rabCommits_info_2_isMove,
  input         io_rabCommits_info_3_rfWen,
  input         io_rabCommits_info_3_fpWen,
  input         io_rabCommits_info_3_vecWen,
  input         io_rabCommits_info_3_v0Wen,
  input         io_rabCommits_info_3_vlWen,
  input         io_rabCommits_info_3_isMove,
  input         io_rabCommits_info_4_rfWen,
  input         io_rabCommits_info_4_fpWen,
  input         io_rabCommits_info_4_vecWen,
  input         io_rabCommits_info_4_v0Wen,
  input         io_rabCommits_info_4_vlWen,
  input         io_rabCommits_info_4_isMove,
  input         io_rabCommits_info_5_rfWen,
  input         io_rabCommits_info_5_fpWen,
  input         io_rabCommits_info_5_vecWen,
  input         io_rabCommits_info_5_v0Wen,
  input         io_rabCommits_info_5_vlWen,
  input         io_rabCommits_info_5_isMove,
  input         io_singleStep,
  output        io_in_0_ready,
  input         io_in_0_valid,
  input  [31:0] io_in_0_bits_instr,
  input  [49:0] io_in_0_bits_pc,
  input  [9:0] io_in_0_bits_foldpc,
  input         io_in_0_bits_exceptionVec_0,
  input         io_in_0_bits_exceptionVec_1,
  input         io_in_0_bits_exceptionVec_2,
  input         io_in_0_bits_exceptionVec_3,
  input         io_in_0_bits_exceptionVec_4,
  input         io_in_0_bits_exceptionVec_5,
  input         io_in_0_bits_exceptionVec_6,
  input         io_in_0_bits_exceptionVec_7,
  input         io_in_0_bits_exceptionVec_8,
  input         io_in_0_bits_exceptionVec_9,
  input         io_in_0_bits_exceptionVec_10,
  input         io_in_0_bits_exceptionVec_11,
  input         io_in_0_bits_exceptionVec_12,
  input         io_in_0_bits_exceptionVec_13,
  input         io_in_0_bits_exceptionVec_14,
  input         io_in_0_bits_exceptionVec_15,
  input         io_in_0_bits_exceptionVec_16,
  input         io_in_0_bits_exceptionVec_17,
  input         io_in_0_bits_exceptionVec_18,
  input         io_in_0_bits_exceptionVec_19,
  input         io_in_0_bits_exceptionVec_20,
  input         io_in_0_bits_exceptionVec_21,
  input         io_in_0_bits_exceptionVec_22,
  input         io_in_0_bits_exceptionVec_23,
  input         io_in_0_bits_isFetchMalAddr,
  input  [3:0] io_in_0_bits_trigger,
  input         io_in_0_bits_preDecodeInfo_valid,
  input         io_in_0_bits_preDecodeInfo_isRVC,
  input  [1:0] io_in_0_bits_preDecodeInfo_brType,
  input         io_in_0_bits_preDecodeInfo_isCall,
  input         io_in_0_bits_preDecodeInfo_isRet,
  input         io_in_0_bits_pred_taken,
  input         io_in_0_bits_crossPageIPFFix,
  input         io_in_0_bits_ftqPtr_flag,
  input  [5:0] io_in_0_bits_ftqPtr_value,
  input  [3:0] io_in_0_bits_ftqOffset,
  input         io_in_0_bits_satpFlushFirstFetchFault,
  input  [3:0] io_in_0_bits_srcType_0,
  input  [3:0] io_in_0_bits_srcType_1,
  input  [3:0] io_in_0_bits_srcType_2,
  input  [3:0] io_in_0_bits_srcType_3,
  input  [3:0] io_in_0_bits_srcType_4,
  input  [5:0] io_in_0_bits_lsrc_0,
  input  [5:0] io_in_0_bits_lsrc_1,
  input  [5:0] io_in_0_bits_ldest,
  input  [34:0] io_in_0_bits_fuType,
  input  [8:0] io_in_0_bits_fuOpType,
  input         io_in_0_bits_rfWen,
  input         io_in_0_bits_fpWen,
  input         io_in_0_bits_vecWen,
  input         io_in_0_bits_v0Wen,
  input         io_in_0_bits_vlWen,
  input         io_in_0_bits_isXSTrap,
  input         io_in_0_bits_waitForward,
  input         io_in_0_bits_blockBackward,
  input         io_in_0_bits_flushPipe,
  input         io_in_0_bits_canRobCompress,
  input  [3:0] io_in_0_bits_selImm,
  input  [21:0] io_in_0_bits_imm,
  input  [1:0] io_in_0_bits_fpu_typeTagOut,
  input         io_in_0_bits_fpu_wflags,
  input  [1:0] io_in_0_bits_fpu_typ,
  input  [1:0] io_in_0_bits_fpu_fmt,
  input  [2:0] io_in_0_bits_fpu_rm,
  input         io_in_0_bits_vpu_vill,
  input         io_in_0_bits_vpu_vma,
  input         io_in_0_bits_vpu_vta,
  input  [1:0] io_in_0_bits_vpu_vsew,
  input  [2:0] io_in_0_bits_vpu_vlmul,
  input         io_in_0_bits_vpu_specVill,
  input         io_in_0_bits_vpu_specVma,
  input         io_in_0_bits_vpu_specVta,
  input  [1:0] io_in_0_bits_vpu_specVsew,
  input  [2:0] io_in_0_bits_vpu_specVlmul,
  input         io_in_0_bits_vpu_vm,
  input  [7:0] io_in_0_bits_vpu_vstart,
  input  [2:0] io_in_0_bits_vpu_frm,
  input         io_in_0_bits_vpu_fpu_isFpToVecInst,
  input         io_in_0_bits_vpu_fpu_isFP32Instr,
  input         io_in_0_bits_vpu_fpu_isFP64Instr,
  input         io_in_0_bits_vpu_fpu_isReduction,
  input         io_in_0_bits_vpu_fpu_isFoldTo1_2,
  input         io_in_0_bits_vpu_fpu_isFoldTo1_4,
  input         io_in_0_bits_vpu_fpu_isFoldTo1_8,
  input  [1:0] io_in_0_bits_vpu_vxrm,
  input  [6:0] io_in_0_bits_vpu_vuopIdx,
  input         io_in_0_bits_vpu_lastUop,
  input  [127:0] io_in_0_bits_vpu_vmask,
  input  [7:0] io_in_0_bits_vpu_vl,
  input  [2:0] io_in_0_bits_vpu_nf,
  input  [1:0] io_in_0_bits_vpu_veew,
  input         io_in_0_bits_vpu_isReverse,
  input         io_in_0_bits_vpu_isExt,
  input         io_in_0_bits_vpu_isNarrow,
  input         io_in_0_bits_vpu_isDstMask,
  input         io_in_0_bits_vpu_isOpMask,
  input         io_in_0_bits_vpu_isMove,
  input         io_in_0_bits_vpu_isDependOldVd,
  input         io_in_0_bits_vpu_isWritePartVd,
  input         io_in_0_bits_vpu_isVleff,
  input         io_in_0_bits_vlsInstr,
  input         io_in_0_bits_wfflags,
  input         io_in_0_bits_isMove,
  input  [6:0] io_in_0_bits_uopIdx,
  input  [5:0] io_in_0_bits_uopSplitType,
  input         io_in_0_bits_isVset,
  input         io_in_0_bits_firstUop,
  input         io_in_0_bits_lastUop,
  input  [6:0] io_in_0_bits_numUops,
  input  [6:0] io_in_0_bits_numWB,
  input  [2:0] io_in_0_bits_commitType,
  input  [34:0] io_in_0_bits_debug_fuType,
  input  [55:0] io_in_0_bits_debug_seqNum_seqNum,
  input  [7:0] io_in_0_bits_debug_seqNum_uopIdx,
  output        io_in_1_ready,
  input         io_in_1_valid,
  input  [31:0] io_in_1_bits_instr,
  input  [49:0] io_in_1_bits_pc,
  input  [9:0] io_in_1_bits_foldpc,
  input         io_in_1_bits_exceptionVec_0,
  input         io_in_1_bits_exceptionVec_1,
  input         io_in_1_bits_exceptionVec_2,
  input         io_in_1_bits_exceptionVec_3,
  input         io_in_1_bits_exceptionVec_4,
  input         io_in_1_bits_exceptionVec_5,
  input         io_in_1_bits_exceptionVec_6,
  input         io_in_1_bits_exceptionVec_7,
  input         io_in_1_bits_exceptionVec_8,
  input         io_in_1_bits_exceptionVec_9,
  input         io_in_1_bits_exceptionVec_10,
  input         io_in_1_bits_exceptionVec_11,
  input         io_in_1_bits_exceptionVec_12,
  input         io_in_1_bits_exceptionVec_13,
  input         io_in_1_bits_exceptionVec_14,
  input         io_in_1_bits_exceptionVec_15,
  input         io_in_1_bits_exceptionVec_16,
  input         io_in_1_bits_exceptionVec_17,
  input         io_in_1_bits_exceptionVec_18,
  input         io_in_1_bits_exceptionVec_19,
  input         io_in_1_bits_exceptionVec_20,
  input         io_in_1_bits_exceptionVec_21,
  input         io_in_1_bits_exceptionVec_22,
  input         io_in_1_bits_exceptionVec_23,
  input         io_in_1_bits_isFetchMalAddr,
  input  [3:0] io_in_1_bits_trigger,
  input         io_in_1_bits_preDecodeInfo_valid,
  input         io_in_1_bits_preDecodeInfo_isRVC,
  input  [1:0] io_in_1_bits_preDecodeInfo_brType,
  input         io_in_1_bits_preDecodeInfo_isCall,
  input         io_in_1_bits_preDecodeInfo_isRet,
  input         io_in_1_bits_pred_taken,
  input         io_in_1_bits_crossPageIPFFix,
  input         io_in_1_bits_ftqPtr_flag,
  input  [5:0] io_in_1_bits_ftqPtr_value,
  input  [3:0] io_in_1_bits_ftqOffset,
  input         io_in_1_bits_satpFlushFirstFetchFault,
  input  [3:0] io_in_1_bits_srcType_0,
  input  [3:0] io_in_1_bits_srcType_1,
  input  [3:0] io_in_1_bits_srcType_2,
  input  [3:0] io_in_1_bits_srcType_3,
  input  [3:0] io_in_1_bits_srcType_4,
  input  [5:0] io_in_1_bits_lsrc_0,
  input  [5:0] io_in_1_bits_lsrc_1,
  input  [5:0] io_in_1_bits_lsrc_2,
  input  [5:0] io_in_1_bits_lsrc_3,
  input  [5:0] io_in_1_bits_lsrc_4,
  input  [5:0] io_in_1_bits_ldest,
  input  [34:0] io_in_1_bits_fuType,
  input  [8:0] io_in_1_bits_fuOpType,
  input         io_in_1_bits_rfWen,
  input         io_in_1_bits_fpWen,
  input         io_in_1_bits_vecWen,
  input         io_in_1_bits_v0Wen,
  input         io_in_1_bits_vlWen,
  input         io_in_1_bits_isXSTrap,
  input         io_in_1_bits_waitForward,
  input         io_in_1_bits_blockBackward,
  input         io_in_1_bits_flushPipe,
  input         io_in_1_bits_canRobCompress,
  input  [3:0] io_in_1_bits_selImm,
  input  [21:0] io_in_1_bits_imm,
  input  [1:0] io_in_1_bits_fpu_typeTagOut,
  input         io_in_1_bits_fpu_wflags,
  input  [1:0] io_in_1_bits_fpu_typ,
  input  [1:0] io_in_1_bits_fpu_fmt,
  input  [2:0] io_in_1_bits_fpu_rm,
  input         io_in_1_bits_vpu_vill,
  input         io_in_1_bits_vpu_vma,
  input         io_in_1_bits_vpu_vta,
  input  [1:0] io_in_1_bits_vpu_vsew,
  input  [2:0] io_in_1_bits_vpu_vlmul,
  input         io_in_1_bits_vpu_specVill,
  input         io_in_1_bits_vpu_specVma,
  input         io_in_1_bits_vpu_specVta,
  input  [1:0] io_in_1_bits_vpu_specVsew,
  input  [2:0] io_in_1_bits_vpu_specVlmul,
  input         io_in_1_bits_vpu_vm,
  input  [7:0] io_in_1_bits_vpu_vstart,
  input  [2:0] io_in_1_bits_vpu_frm,
  input         io_in_1_bits_vpu_fpu_isFpToVecInst,
  input         io_in_1_bits_vpu_fpu_isFP32Instr,
  input         io_in_1_bits_vpu_fpu_isFP64Instr,
  input         io_in_1_bits_vpu_fpu_isReduction,
  input         io_in_1_bits_vpu_fpu_isFoldTo1_2,
  input         io_in_1_bits_vpu_fpu_isFoldTo1_4,
  input         io_in_1_bits_vpu_fpu_isFoldTo1_8,
  input  [1:0] io_in_1_bits_vpu_vxrm,
  input  [6:0] io_in_1_bits_vpu_vuopIdx,
  input         io_in_1_bits_vpu_lastUop,
  input  [127:0] io_in_1_bits_vpu_vmask,
  input  [7:0] io_in_1_bits_vpu_vl,
  input  [2:0] io_in_1_bits_vpu_nf,
  input  [1:0] io_in_1_bits_vpu_veew,
  input         io_in_1_bits_vpu_isReverse,
  input         io_in_1_bits_vpu_isExt,
  input         io_in_1_bits_vpu_isNarrow,
  input         io_in_1_bits_vpu_isDstMask,
  input         io_in_1_bits_vpu_isOpMask,
  input         io_in_1_bits_vpu_isMove,
  input         io_in_1_bits_vpu_isDependOldVd,
  input         io_in_1_bits_vpu_isWritePartVd,
  input         io_in_1_bits_vpu_isVleff,
  input         io_in_1_bits_vlsInstr,
  input         io_in_1_bits_wfflags,
  input         io_in_1_bits_isMove,
  input  [6:0] io_in_1_bits_uopIdx,
  input  [5:0] io_in_1_bits_uopSplitType,
  input         io_in_1_bits_isVset,
  input         io_in_1_bits_firstUop,
  input         io_in_1_bits_lastUop,
  input  [6:0] io_in_1_bits_numUops,
  input  [6:0] io_in_1_bits_numWB,
  input  [2:0] io_in_1_bits_commitType,
  input  [34:0] io_in_1_bits_debug_fuType,
  input  [55:0] io_in_1_bits_debug_seqNum_seqNum,
  input  [7:0] io_in_1_bits_debug_seqNum_uopIdx,
  output        io_in_2_ready,
  input         io_in_2_valid,
  input  [31:0] io_in_2_bits_instr,
  input  [49:0] io_in_2_bits_pc,
  input  [9:0] io_in_2_bits_foldpc,
  input         io_in_2_bits_exceptionVec_0,
  input         io_in_2_bits_exceptionVec_1,
  input         io_in_2_bits_exceptionVec_2,
  input         io_in_2_bits_exceptionVec_3,
  input         io_in_2_bits_exceptionVec_4,
  input         io_in_2_bits_exceptionVec_5,
  input         io_in_2_bits_exceptionVec_6,
  input         io_in_2_bits_exceptionVec_7,
  input         io_in_2_bits_exceptionVec_8,
  input         io_in_2_bits_exceptionVec_9,
  input         io_in_2_bits_exceptionVec_10,
  input         io_in_2_bits_exceptionVec_11,
  input         io_in_2_bits_exceptionVec_12,
  input         io_in_2_bits_exceptionVec_13,
  input         io_in_2_bits_exceptionVec_14,
  input         io_in_2_bits_exceptionVec_15,
  input         io_in_2_bits_exceptionVec_16,
  input         io_in_2_bits_exceptionVec_17,
  input         io_in_2_bits_exceptionVec_18,
  input         io_in_2_bits_exceptionVec_19,
  input         io_in_2_bits_exceptionVec_20,
  input         io_in_2_bits_exceptionVec_21,
  input         io_in_2_bits_exceptionVec_22,
  input         io_in_2_bits_exceptionVec_23,
  input         io_in_2_bits_isFetchMalAddr,
  input  [3:0] io_in_2_bits_trigger,
  input         io_in_2_bits_preDecodeInfo_valid,
  input         io_in_2_bits_preDecodeInfo_isRVC,
  input  [1:0] io_in_2_bits_preDecodeInfo_brType,
  input         io_in_2_bits_preDecodeInfo_isCall,
  input         io_in_2_bits_preDecodeInfo_isRet,
  input         io_in_2_bits_pred_taken,
  input         io_in_2_bits_crossPageIPFFix,
  input         io_in_2_bits_ftqPtr_flag,
  input  [5:0] io_in_2_bits_ftqPtr_value,
  input  [3:0] io_in_2_bits_ftqOffset,
  input         io_in_2_bits_satpFlushFirstFetchFault,
  input  [3:0] io_in_2_bits_srcType_0,
  input  [3:0] io_in_2_bits_srcType_1,
  input  [3:0] io_in_2_bits_srcType_2,
  input  [3:0] io_in_2_bits_srcType_3,
  input  [3:0] io_in_2_bits_srcType_4,
  input  [5:0] io_in_2_bits_lsrc_0,
  input  [5:0] io_in_2_bits_lsrc_1,
  input  [5:0] io_in_2_bits_lsrc_2,
  input  [5:0] io_in_2_bits_lsrc_3,
  input  [5:0] io_in_2_bits_lsrc_4,
  input  [5:0] io_in_2_bits_ldest,
  input  [34:0] io_in_2_bits_fuType,
  input  [8:0] io_in_2_bits_fuOpType,
  input         io_in_2_bits_rfWen,
  input         io_in_2_bits_fpWen,
  input         io_in_2_bits_vecWen,
  input         io_in_2_bits_v0Wen,
  input         io_in_2_bits_vlWen,
  input         io_in_2_bits_isXSTrap,
  input         io_in_2_bits_waitForward,
  input         io_in_2_bits_blockBackward,
  input         io_in_2_bits_flushPipe,
  input         io_in_2_bits_canRobCompress,
  input  [3:0] io_in_2_bits_selImm,
  input  [21:0] io_in_2_bits_imm,
  input  [1:0] io_in_2_bits_fpu_typeTagOut,
  input         io_in_2_bits_fpu_wflags,
  input  [1:0] io_in_2_bits_fpu_typ,
  input  [1:0] io_in_2_bits_fpu_fmt,
  input  [2:0] io_in_2_bits_fpu_rm,
  input         io_in_2_bits_vpu_vill,
  input         io_in_2_bits_vpu_vma,
  input         io_in_2_bits_vpu_vta,
  input  [1:0] io_in_2_bits_vpu_vsew,
  input  [2:0] io_in_2_bits_vpu_vlmul,
  input         io_in_2_bits_vpu_specVill,
  input         io_in_2_bits_vpu_specVma,
  input         io_in_2_bits_vpu_specVta,
  input  [1:0] io_in_2_bits_vpu_specVsew,
  input  [2:0] io_in_2_bits_vpu_specVlmul,
  input         io_in_2_bits_vpu_vm,
  input  [7:0] io_in_2_bits_vpu_vstart,
  input  [2:0] io_in_2_bits_vpu_frm,
  input         io_in_2_bits_vpu_fpu_isFpToVecInst,
  input         io_in_2_bits_vpu_fpu_isFP32Instr,
  input         io_in_2_bits_vpu_fpu_isFP64Instr,
  input         io_in_2_bits_vpu_fpu_isReduction,
  input         io_in_2_bits_vpu_fpu_isFoldTo1_2,
  input         io_in_2_bits_vpu_fpu_isFoldTo1_4,
  input         io_in_2_bits_vpu_fpu_isFoldTo1_8,
  input  [1:0] io_in_2_bits_vpu_vxrm,
  input  [6:0] io_in_2_bits_vpu_vuopIdx,
  input         io_in_2_bits_vpu_lastUop,
  input  [127:0] io_in_2_bits_vpu_vmask,
  input  [7:0] io_in_2_bits_vpu_vl,
  input  [2:0] io_in_2_bits_vpu_nf,
  input  [1:0] io_in_2_bits_vpu_veew,
  input         io_in_2_bits_vpu_isReverse,
  input         io_in_2_bits_vpu_isExt,
  input         io_in_2_bits_vpu_isNarrow,
  input         io_in_2_bits_vpu_isDstMask,
  input         io_in_2_bits_vpu_isOpMask,
  input         io_in_2_bits_vpu_isMove,
  input         io_in_2_bits_vpu_isDependOldVd,
  input         io_in_2_bits_vpu_isWritePartVd,
  input         io_in_2_bits_vpu_isVleff,
  input         io_in_2_bits_vlsInstr,
  input         io_in_2_bits_wfflags,
  input         io_in_2_bits_isMove,
  input  [6:0] io_in_2_bits_uopIdx,
  input  [5:0] io_in_2_bits_uopSplitType,
  input         io_in_2_bits_isVset,
  input         io_in_2_bits_firstUop,
  input         io_in_2_bits_lastUop,
  input  [6:0] io_in_2_bits_numUops,
  input  [6:0] io_in_2_bits_numWB,
  input  [2:0] io_in_2_bits_commitType,
  input  [34:0] io_in_2_bits_debug_fuType,
  input  [55:0] io_in_2_bits_debug_seqNum_seqNum,
  input  [7:0] io_in_2_bits_debug_seqNum_uopIdx,
  output        io_in_3_ready,
  input         io_in_3_valid,
  input  [31:0] io_in_3_bits_instr,
  input  [49:0] io_in_3_bits_pc,
  input  [9:0] io_in_3_bits_foldpc,
  input         io_in_3_bits_exceptionVec_0,
  input         io_in_3_bits_exceptionVec_1,
  input         io_in_3_bits_exceptionVec_2,
  input         io_in_3_bits_exceptionVec_3,
  input         io_in_3_bits_exceptionVec_4,
  input         io_in_3_bits_exceptionVec_5,
  input         io_in_3_bits_exceptionVec_6,
  input         io_in_3_bits_exceptionVec_7,
  input         io_in_3_bits_exceptionVec_8,
  input         io_in_3_bits_exceptionVec_9,
  input         io_in_3_bits_exceptionVec_10,
  input         io_in_3_bits_exceptionVec_11,
  input         io_in_3_bits_exceptionVec_12,
  input         io_in_3_bits_exceptionVec_13,
  input         io_in_3_bits_exceptionVec_14,
  input         io_in_3_bits_exceptionVec_15,
  input         io_in_3_bits_exceptionVec_16,
  input         io_in_3_bits_exceptionVec_17,
  input         io_in_3_bits_exceptionVec_18,
  input         io_in_3_bits_exceptionVec_19,
  input         io_in_3_bits_exceptionVec_20,
  input         io_in_3_bits_exceptionVec_21,
  input         io_in_3_bits_exceptionVec_22,
  input         io_in_3_bits_exceptionVec_23,
  input         io_in_3_bits_isFetchMalAddr,
  input  [3:0] io_in_3_bits_trigger,
  input         io_in_3_bits_preDecodeInfo_valid,
  input         io_in_3_bits_preDecodeInfo_isRVC,
  input  [1:0] io_in_3_bits_preDecodeInfo_brType,
  input         io_in_3_bits_preDecodeInfo_isCall,
  input         io_in_3_bits_preDecodeInfo_isRet,
  input         io_in_3_bits_pred_taken,
  input         io_in_3_bits_crossPageIPFFix,
  input         io_in_3_bits_ftqPtr_flag,
  input  [5:0] io_in_3_bits_ftqPtr_value,
  input  [3:0] io_in_3_bits_ftqOffset,
  input         io_in_3_bits_satpFlushFirstFetchFault,
  input  [3:0] io_in_3_bits_srcType_0,
  input  [3:0] io_in_3_bits_srcType_1,
  input  [3:0] io_in_3_bits_srcType_2,
  input  [3:0] io_in_3_bits_srcType_3,
  input  [3:0] io_in_3_bits_srcType_4,
  input  [5:0] io_in_3_bits_lsrc_0,
  input  [5:0] io_in_3_bits_lsrc_1,
  input  [5:0] io_in_3_bits_lsrc_2,
  input  [5:0] io_in_3_bits_lsrc_3,
  input  [5:0] io_in_3_bits_lsrc_4,
  input  [5:0] io_in_3_bits_ldest,
  input  [34:0] io_in_3_bits_fuType,
  input  [8:0] io_in_3_bits_fuOpType,
  input         io_in_3_bits_rfWen,
  input         io_in_3_bits_fpWen,
  input         io_in_3_bits_vecWen,
  input         io_in_3_bits_v0Wen,
  input         io_in_3_bits_vlWen,
  input         io_in_3_bits_isXSTrap,
  input         io_in_3_bits_waitForward,
  input         io_in_3_bits_blockBackward,
  input         io_in_3_bits_flushPipe,
  input         io_in_3_bits_canRobCompress,
  input  [3:0] io_in_3_bits_selImm,
  input  [21:0] io_in_3_bits_imm,
  input  [1:0] io_in_3_bits_fpu_typeTagOut,
  input         io_in_3_bits_fpu_wflags,
  input  [1:0] io_in_3_bits_fpu_typ,
  input  [1:0] io_in_3_bits_fpu_fmt,
  input  [2:0] io_in_3_bits_fpu_rm,
  input         io_in_3_bits_vpu_vill,
  input         io_in_3_bits_vpu_vma,
  input         io_in_3_bits_vpu_vta,
  input  [1:0] io_in_3_bits_vpu_vsew,
  input  [2:0] io_in_3_bits_vpu_vlmul,
  input         io_in_3_bits_vpu_specVill,
  input         io_in_3_bits_vpu_specVma,
  input         io_in_3_bits_vpu_specVta,
  input  [1:0] io_in_3_bits_vpu_specVsew,
  input  [2:0] io_in_3_bits_vpu_specVlmul,
  input         io_in_3_bits_vpu_vm,
  input  [7:0] io_in_3_bits_vpu_vstart,
  input  [2:0] io_in_3_bits_vpu_frm,
  input         io_in_3_bits_vpu_fpu_isFpToVecInst,
  input         io_in_3_bits_vpu_fpu_isFP32Instr,
  input         io_in_3_bits_vpu_fpu_isFP64Instr,
  input         io_in_3_bits_vpu_fpu_isReduction,
  input         io_in_3_bits_vpu_fpu_isFoldTo1_2,
  input         io_in_3_bits_vpu_fpu_isFoldTo1_4,
  input         io_in_3_bits_vpu_fpu_isFoldTo1_8,
  input  [1:0] io_in_3_bits_vpu_vxrm,
  input  [6:0] io_in_3_bits_vpu_vuopIdx,
  input         io_in_3_bits_vpu_lastUop,
  input  [127:0] io_in_3_bits_vpu_vmask,
  input  [7:0] io_in_3_bits_vpu_vl,
  input  [2:0] io_in_3_bits_vpu_nf,
  input  [1:0] io_in_3_bits_vpu_veew,
  input         io_in_3_bits_vpu_isReverse,
  input         io_in_3_bits_vpu_isExt,
  input         io_in_3_bits_vpu_isNarrow,
  input         io_in_3_bits_vpu_isDstMask,
  input         io_in_3_bits_vpu_isOpMask,
  input         io_in_3_bits_vpu_isMove,
  input         io_in_3_bits_vpu_isDependOldVd,
  input         io_in_3_bits_vpu_isWritePartVd,
  input         io_in_3_bits_vpu_isVleff,
  input         io_in_3_bits_vlsInstr,
  input         io_in_3_bits_wfflags,
  input         io_in_3_bits_isMove,
  input  [6:0] io_in_3_bits_uopIdx,
  input  [5:0] io_in_3_bits_uopSplitType,
  input         io_in_3_bits_isVset,
  input         io_in_3_bits_firstUop,
  input         io_in_3_bits_lastUop,
  input  [6:0] io_in_3_bits_numUops,
  input  [6:0] io_in_3_bits_numWB,
  input  [2:0] io_in_3_bits_commitType,
  input  [34:0] io_in_3_bits_debug_fuType,
  input  [55:0] io_in_3_bits_debug_seqNum_seqNum,
  input  [7:0] io_in_3_bits_debug_seqNum_uopIdx,
  output        io_in_4_ready,
  input         io_in_4_valid,
  input  [31:0] io_in_4_bits_instr,
  input  [49:0] io_in_4_bits_pc,
  input  [9:0] io_in_4_bits_foldpc,
  input         io_in_4_bits_exceptionVec_0,
  input         io_in_4_bits_exceptionVec_1,
  input         io_in_4_bits_exceptionVec_2,
  input         io_in_4_bits_exceptionVec_3,
  input         io_in_4_bits_exceptionVec_4,
  input         io_in_4_bits_exceptionVec_5,
  input         io_in_4_bits_exceptionVec_6,
  input         io_in_4_bits_exceptionVec_7,
  input         io_in_4_bits_exceptionVec_8,
  input         io_in_4_bits_exceptionVec_9,
  input         io_in_4_bits_exceptionVec_10,
  input         io_in_4_bits_exceptionVec_11,
  input         io_in_4_bits_exceptionVec_12,
  input         io_in_4_bits_exceptionVec_13,
  input         io_in_4_bits_exceptionVec_14,
  input         io_in_4_bits_exceptionVec_15,
  input         io_in_4_bits_exceptionVec_16,
  input         io_in_4_bits_exceptionVec_17,
  input         io_in_4_bits_exceptionVec_18,
  input         io_in_4_bits_exceptionVec_19,
  input         io_in_4_bits_exceptionVec_20,
  input         io_in_4_bits_exceptionVec_21,
  input         io_in_4_bits_exceptionVec_22,
  input         io_in_4_bits_exceptionVec_23,
  input         io_in_4_bits_isFetchMalAddr,
  input  [3:0] io_in_4_bits_trigger,
  input         io_in_4_bits_preDecodeInfo_valid,
  input         io_in_4_bits_preDecodeInfo_isRVC,
  input  [1:0] io_in_4_bits_preDecodeInfo_brType,
  input         io_in_4_bits_preDecodeInfo_isCall,
  input         io_in_4_bits_preDecodeInfo_isRet,
  input         io_in_4_bits_pred_taken,
  input         io_in_4_bits_crossPageIPFFix,
  input         io_in_4_bits_ftqPtr_flag,
  input  [5:0] io_in_4_bits_ftqPtr_value,
  input  [3:0] io_in_4_bits_ftqOffset,
  input         io_in_4_bits_satpFlushFirstFetchFault,
  input  [3:0] io_in_4_bits_srcType_0,
  input  [3:0] io_in_4_bits_srcType_1,
  input  [3:0] io_in_4_bits_srcType_2,
  input  [3:0] io_in_4_bits_srcType_3,
  input  [3:0] io_in_4_bits_srcType_4,
  input  [5:0] io_in_4_bits_lsrc_0,
  input  [5:0] io_in_4_bits_lsrc_1,
  input  [5:0] io_in_4_bits_lsrc_2,
  input  [5:0] io_in_4_bits_lsrc_3,
  input  [5:0] io_in_4_bits_lsrc_4,
  input  [5:0] io_in_4_bits_ldest,
  input  [34:0] io_in_4_bits_fuType,
  input  [8:0] io_in_4_bits_fuOpType,
  input         io_in_4_bits_rfWen,
  input         io_in_4_bits_fpWen,
  input         io_in_4_bits_vecWen,
  input         io_in_4_bits_v0Wen,
  input         io_in_4_bits_vlWen,
  input         io_in_4_bits_isXSTrap,
  input         io_in_4_bits_waitForward,
  input         io_in_4_bits_blockBackward,
  input         io_in_4_bits_flushPipe,
  input         io_in_4_bits_canRobCompress,
  input  [3:0] io_in_4_bits_selImm,
  input  [21:0] io_in_4_bits_imm,
  input  [1:0] io_in_4_bits_fpu_typeTagOut,
  input         io_in_4_bits_fpu_wflags,
  input  [1:0] io_in_4_bits_fpu_typ,
  input  [1:0] io_in_4_bits_fpu_fmt,
  input  [2:0] io_in_4_bits_fpu_rm,
  input         io_in_4_bits_vpu_vill,
  input         io_in_4_bits_vpu_vma,
  input         io_in_4_bits_vpu_vta,
  input  [1:0] io_in_4_bits_vpu_vsew,
  input  [2:0] io_in_4_bits_vpu_vlmul,
  input         io_in_4_bits_vpu_specVill,
  input         io_in_4_bits_vpu_specVma,
  input         io_in_4_bits_vpu_specVta,
  input  [1:0] io_in_4_bits_vpu_specVsew,
  input  [2:0] io_in_4_bits_vpu_specVlmul,
  input         io_in_4_bits_vpu_vm,
  input  [7:0] io_in_4_bits_vpu_vstart,
  input  [2:0] io_in_4_bits_vpu_frm,
  input         io_in_4_bits_vpu_fpu_isFpToVecInst,
  input         io_in_4_bits_vpu_fpu_isFP32Instr,
  input         io_in_4_bits_vpu_fpu_isFP64Instr,
  input         io_in_4_bits_vpu_fpu_isReduction,
  input         io_in_4_bits_vpu_fpu_isFoldTo1_2,
  input         io_in_4_bits_vpu_fpu_isFoldTo1_4,
  input         io_in_4_bits_vpu_fpu_isFoldTo1_8,
  input  [1:0] io_in_4_bits_vpu_vxrm,
  input  [6:0] io_in_4_bits_vpu_vuopIdx,
  input         io_in_4_bits_vpu_lastUop,
  input  [127:0] io_in_4_bits_vpu_vmask,
  input  [7:0] io_in_4_bits_vpu_vl,
  input  [2:0] io_in_4_bits_vpu_nf,
  input  [1:0] io_in_4_bits_vpu_veew,
  input         io_in_4_bits_vpu_isReverse,
  input         io_in_4_bits_vpu_isExt,
  input         io_in_4_bits_vpu_isNarrow,
  input         io_in_4_bits_vpu_isDstMask,
  input         io_in_4_bits_vpu_isOpMask,
  input         io_in_4_bits_vpu_isMove,
  input         io_in_4_bits_vpu_isDependOldVd,
  input         io_in_4_bits_vpu_isWritePartVd,
  input         io_in_4_bits_vpu_isVleff,
  input         io_in_4_bits_vlsInstr,
  input         io_in_4_bits_wfflags,
  input         io_in_4_bits_isMove,
  input  [6:0] io_in_4_bits_uopIdx,
  input  [5:0] io_in_4_bits_uopSplitType,
  input         io_in_4_bits_isVset,
  input         io_in_4_bits_firstUop,
  input         io_in_4_bits_lastUop,
  input  [6:0] io_in_4_bits_numUops,
  input  [6:0] io_in_4_bits_numWB,
  input  [2:0] io_in_4_bits_commitType,
  input  [34:0] io_in_4_bits_debug_fuType,
  input  [55:0] io_in_4_bits_debug_seqNum_seqNum,
  input  [7:0] io_in_4_bits_debug_seqNum_uopIdx,
  output        io_in_5_ready,
  input         io_in_5_valid,
  input  [31:0] io_in_5_bits_instr,
  input  [49:0] io_in_5_bits_pc,
  input  [9:0] io_in_5_bits_foldpc,
  input         io_in_5_bits_exceptionVec_0,
  input         io_in_5_bits_exceptionVec_1,
  input         io_in_5_bits_exceptionVec_2,
  input         io_in_5_bits_exceptionVec_3,
  input         io_in_5_bits_exceptionVec_4,
  input         io_in_5_bits_exceptionVec_5,
  input         io_in_5_bits_exceptionVec_6,
  input         io_in_5_bits_exceptionVec_7,
  input         io_in_5_bits_exceptionVec_8,
  input         io_in_5_bits_exceptionVec_9,
  input         io_in_5_bits_exceptionVec_10,
  input         io_in_5_bits_exceptionVec_11,
  input         io_in_5_bits_exceptionVec_12,
  input         io_in_5_bits_exceptionVec_13,
  input         io_in_5_bits_exceptionVec_14,
  input         io_in_5_bits_exceptionVec_15,
  input         io_in_5_bits_exceptionVec_16,
  input         io_in_5_bits_exceptionVec_17,
  input         io_in_5_bits_exceptionVec_18,
  input         io_in_5_bits_exceptionVec_19,
  input         io_in_5_bits_exceptionVec_20,
  input         io_in_5_bits_exceptionVec_21,
  input         io_in_5_bits_exceptionVec_22,
  input         io_in_5_bits_exceptionVec_23,
  input         io_in_5_bits_isFetchMalAddr,
  input  [3:0] io_in_5_bits_trigger,
  input         io_in_5_bits_preDecodeInfo_valid,
  input         io_in_5_bits_preDecodeInfo_isRVC,
  input  [1:0] io_in_5_bits_preDecodeInfo_brType,
  input         io_in_5_bits_preDecodeInfo_isCall,
  input         io_in_5_bits_preDecodeInfo_isRet,
  input         io_in_5_bits_pred_taken,
  input         io_in_5_bits_crossPageIPFFix,
  input         io_in_5_bits_ftqPtr_flag,
  input  [5:0] io_in_5_bits_ftqPtr_value,
  input  [3:0] io_in_5_bits_ftqOffset,
  input         io_in_5_bits_satpFlushFirstFetchFault,
  input  [3:0] io_in_5_bits_srcType_0,
  input  [3:0] io_in_5_bits_srcType_1,
  input  [3:0] io_in_5_bits_srcType_2,
  input  [3:0] io_in_5_bits_srcType_3,
  input  [3:0] io_in_5_bits_srcType_4,
  input  [5:0] io_in_5_bits_lsrc_0,
  input  [5:0] io_in_5_bits_lsrc_1,
  input  [5:0] io_in_5_bits_lsrc_2,
  input  [5:0] io_in_5_bits_lsrc_3,
  input  [5:0] io_in_5_bits_lsrc_4,
  input  [5:0] io_in_5_bits_ldest,
  input  [34:0] io_in_5_bits_fuType,
  input  [8:0] io_in_5_bits_fuOpType,
  input         io_in_5_bits_rfWen,
  input         io_in_5_bits_fpWen,
  input         io_in_5_bits_vecWen,
  input         io_in_5_bits_v0Wen,
  input         io_in_5_bits_vlWen,
  input         io_in_5_bits_isXSTrap,
  input         io_in_5_bits_waitForward,
  input         io_in_5_bits_blockBackward,
  input         io_in_5_bits_flushPipe,
  input         io_in_5_bits_canRobCompress,
  input  [3:0] io_in_5_bits_selImm,
  input  [21:0] io_in_5_bits_imm,
  input  [1:0] io_in_5_bits_fpu_typeTagOut,
  input         io_in_5_bits_fpu_wflags,
  input  [1:0] io_in_5_bits_fpu_typ,
  input  [1:0] io_in_5_bits_fpu_fmt,
  input  [2:0] io_in_5_bits_fpu_rm,
  input         io_in_5_bits_vpu_vill,
  input         io_in_5_bits_vpu_vma,
  input         io_in_5_bits_vpu_vta,
  input  [1:0] io_in_5_bits_vpu_vsew,
  input  [2:0] io_in_5_bits_vpu_vlmul,
  input         io_in_5_bits_vpu_specVill,
  input         io_in_5_bits_vpu_specVma,
  input         io_in_5_bits_vpu_specVta,
  input  [1:0] io_in_5_bits_vpu_specVsew,
  input  [2:0] io_in_5_bits_vpu_specVlmul,
  input         io_in_5_bits_vpu_vm,
  input  [7:0] io_in_5_bits_vpu_vstart,
  input  [2:0] io_in_5_bits_vpu_frm,
  input         io_in_5_bits_vpu_fpu_isFpToVecInst,
  input         io_in_5_bits_vpu_fpu_isFP32Instr,
  input         io_in_5_bits_vpu_fpu_isFP64Instr,
  input         io_in_5_bits_vpu_fpu_isReduction,
  input         io_in_5_bits_vpu_fpu_isFoldTo1_2,
  input         io_in_5_bits_vpu_fpu_isFoldTo1_4,
  input         io_in_5_bits_vpu_fpu_isFoldTo1_8,
  input  [1:0] io_in_5_bits_vpu_vxrm,
  input  [6:0] io_in_5_bits_vpu_vuopIdx,
  input         io_in_5_bits_vpu_lastUop,
  input  [127:0] io_in_5_bits_vpu_vmask,
  input  [7:0] io_in_5_bits_vpu_vl,
  input  [2:0] io_in_5_bits_vpu_nf,
  input  [1:0] io_in_5_bits_vpu_veew,
  input         io_in_5_bits_vpu_isReverse,
  input         io_in_5_bits_vpu_isExt,
  input         io_in_5_bits_vpu_isNarrow,
  input         io_in_5_bits_vpu_isDstMask,
  input         io_in_5_bits_vpu_isOpMask,
  input         io_in_5_bits_vpu_isMove,
  input         io_in_5_bits_vpu_isDependOldVd,
  input         io_in_5_bits_vpu_isWritePartVd,
  input         io_in_5_bits_vpu_isVleff,
  input         io_in_5_bits_vlsInstr,
  input         io_in_5_bits_wfflags,
  input         io_in_5_bits_isMove,
  input  [6:0] io_in_5_bits_uopIdx,
  input  [5:0] io_in_5_bits_uopSplitType,
  input         io_in_5_bits_isVset,
  input         io_in_5_bits_firstUop,
  input         io_in_5_bits_lastUop,
  input  [6:0] io_in_5_bits_numUops,
  input  [6:0] io_in_5_bits_numWB,
  input  [2:0] io_in_5_bits_commitType,
  input  [34:0] io_in_5_bits_debug_fuType,
  input  [55:0] io_in_5_bits_debug_seqNum_seqNum,
  input  [7:0] io_in_5_bits_debug_seqNum_uopIdx,
  input         io_fusionInfo_0_rs2FromRs1,
  input         io_fusionInfo_0_rs2FromRs2,
  input         io_fusionInfo_0_rs2FromZero,
  input         io_fusionInfo_1_rs2FromRs1,
  input         io_fusionInfo_1_rs2FromRs2,
  input         io_fusionInfo_1_rs2FromZero,
  input         io_fusionInfo_2_rs2FromRs1,
  input         io_fusionInfo_2_rs2FromRs2,
  input         io_fusionInfo_2_rs2FromZero,
  input         io_fusionInfo_3_rs2FromRs1,
  input         io_fusionInfo_3_rs2FromRs2,
  input         io_fusionInfo_3_rs2FromZero,
  input         io_fusionInfo_4_rs2FromRs1,
  input         io_fusionInfo_4_rs2FromRs2,
  input         io_fusionInfo_4_rs2FromZero,
  input  [7:0] io_intReadPorts_0_0,
  input  [7:0] io_intReadPorts_0_1,
  input  [7:0] io_intReadPorts_1_0,
  input  [7:0] io_intReadPorts_1_1,
  input  [7:0] io_intReadPorts_2_0,
  input  [7:0] io_intReadPorts_2_1,
  input  [7:0] io_intReadPorts_3_0,
  input  [7:0] io_intReadPorts_3_1,
  input  [7:0] io_intReadPorts_4_0,
  input  [7:0] io_intReadPorts_4_1,
  input  [7:0] io_intReadPorts_5_0,
  input  [7:0] io_intReadPorts_5_1,
  input  [7:0] io_fpReadPorts_0_0,
  input  [7:0] io_fpReadPorts_0_1,
  input  [7:0] io_fpReadPorts_0_2,
  input  [7:0] io_fpReadPorts_1_0,
  input  [7:0] io_fpReadPorts_1_1,
  input  [7:0] io_fpReadPorts_1_2,
  input  [7:0] io_fpReadPorts_2_0,
  input  [7:0] io_fpReadPorts_2_1,
  input  [7:0] io_fpReadPorts_2_2,
  input  [7:0] io_fpReadPorts_3_0,
  input  [7:0] io_fpReadPorts_3_1,
  input  [7:0] io_fpReadPorts_3_2,
  input  [7:0] io_fpReadPorts_4_0,
  input  [7:0] io_fpReadPorts_4_1,
  input  [7:0] io_fpReadPorts_4_2,
  input  [7:0] io_fpReadPorts_5_0,
  input  [7:0] io_fpReadPorts_5_1,
  input  [7:0] io_fpReadPorts_5_2,
  input  [7:0] io_vecReadPorts_0_0,
  input  [7:0] io_vecReadPorts_0_1,
  input  [7:0] io_vecReadPorts_0_2,
  input  [7:0] io_vecReadPorts_1_0,
  input  [7:0] io_vecReadPorts_1_1,
  input  [7:0] io_vecReadPorts_1_2,
  input  [7:0] io_vecReadPorts_2_0,
  input  [7:0] io_vecReadPorts_2_1,
  input  [7:0] io_vecReadPorts_2_2,
  input  [7:0] io_vecReadPorts_3_0,
  input  [7:0] io_vecReadPorts_3_1,
  input  [7:0] io_vecReadPorts_3_2,
  input  [7:0] io_vecReadPorts_4_0,
  input  [7:0] io_vecReadPorts_4_1,
  input  [7:0] io_vecReadPorts_4_2,
  input  [7:0] io_vecReadPorts_5_0,
  input  [7:0] io_vecReadPorts_5_1,
  input  [7:0] io_vecReadPorts_5_2,
  input  [7:0] io_v0ReadPorts_0_0,
  input  [7:0] io_v0ReadPorts_1_0,
  input  [7:0] io_v0ReadPorts_2_0,
  input  [7:0] io_v0ReadPorts_3_0,
  input  [7:0] io_v0ReadPorts_4_0,
  input  [7:0] io_v0ReadPorts_5_0,
  input  [7:0] io_vlReadPorts_0_0,
  input  [7:0] io_vlReadPorts_1_0,
  input  [7:0] io_vlReadPorts_2_0,
  input  [7:0] io_vlReadPorts_3_0,
  input  [7:0] io_vlReadPorts_4_0,
  input  [7:0] io_vlReadPorts_5_0,
  output        io_intRenamePorts_0_wen,
  output [4:0] io_intRenamePorts_0_addr,
  output [7:0] io_intRenamePorts_0_data,
  output        io_intRenamePorts_1_wen,
  output [4:0] io_intRenamePorts_1_addr,
  output [7:0] io_intRenamePorts_1_data,
  output        io_intRenamePorts_2_wen,
  output [4:0] io_intRenamePorts_2_addr,
  output [7:0] io_intRenamePorts_2_data,
  output        io_intRenamePorts_3_wen,
  output [4:0] io_intRenamePorts_3_addr,
  output [7:0] io_intRenamePorts_3_data,
  output        io_intRenamePorts_4_wen,
  output [4:0] io_intRenamePorts_4_addr,
  output [7:0] io_intRenamePorts_4_data,
  output        io_intRenamePorts_5_wen,
  output [4:0] io_intRenamePorts_5_addr,
  output [7:0] io_intRenamePorts_5_data,
  output        io_fpRenamePorts_0_wen,
  output [5:0] io_fpRenamePorts_0_addr,
  output [7:0] io_fpRenamePorts_0_data,
  output        io_fpRenamePorts_1_wen,
  output [5:0] io_fpRenamePorts_1_addr,
  output [7:0] io_fpRenamePorts_1_data,
  output        io_fpRenamePorts_2_wen,
  output [5:0] io_fpRenamePorts_2_addr,
  output [7:0] io_fpRenamePorts_2_data,
  output        io_fpRenamePorts_3_wen,
  output [5:0] io_fpRenamePorts_3_addr,
  output [7:0] io_fpRenamePorts_3_data,
  output        io_fpRenamePorts_4_wen,
  output [5:0] io_fpRenamePorts_4_addr,
  output [7:0] io_fpRenamePorts_4_data,
  output        io_fpRenamePorts_5_wen,
  output [5:0] io_fpRenamePorts_5_addr,
  output [7:0] io_fpRenamePorts_5_data,
  output        io_vecRenamePorts_0_wen,
  output [5:0] io_vecRenamePorts_0_addr,
  output [7:0] io_vecRenamePorts_0_data,
  output        io_vecRenamePorts_1_wen,
  output [5:0] io_vecRenamePorts_1_addr,
  output [7:0] io_vecRenamePorts_1_data,
  output        io_vecRenamePorts_2_wen,
  output [5:0] io_vecRenamePorts_2_addr,
  output [7:0] io_vecRenamePorts_2_data,
  output        io_vecRenamePorts_3_wen,
  output [5:0] io_vecRenamePorts_3_addr,
  output [7:0] io_vecRenamePorts_3_data,
  output        io_vecRenamePorts_4_wen,
  output [5:0] io_vecRenamePorts_4_addr,
  output [7:0] io_vecRenamePorts_4_data,
  output        io_vecRenamePorts_5_wen,
  output [5:0] io_vecRenamePorts_5_addr,
  output [7:0] io_vecRenamePorts_5_data,
  output        io_v0RenamePorts_0_wen,
  output [7:0] io_v0RenamePorts_0_data,
  output        io_v0RenamePorts_1_wen,
  output [7:0] io_v0RenamePorts_1_data,
  output        io_v0RenamePorts_2_wen,
  output [7:0] io_v0RenamePorts_2_data,
  output        io_v0RenamePorts_3_wen,
  output [7:0] io_v0RenamePorts_3_data,
  output        io_v0RenamePorts_4_wen,
  output [7:0] io_v0RenamePorts_4_data,
  output        io_v0RenamePorts_5_wen,
  output [7:0] io_v0RenamePorts_5_data,
  output        io_vlRenamePorts_0_wen,
  output [7:0] io_vlRenamePorts_0_data,
  output        io_vlRenamePorts_1_wen,
  output [7:0] io_vlRenamePorts_1_data,
  output        io_vlRenamePorts_2_wen,
  output [7:0] io_vlRenamePorts_2_data,
  output        io_vlRenamePorts_3_wen,
  output [7:0] io_vlRenamePorts_3_data,
  output        io_vlRenamePorts_4_wen,
  output [7:0] io_vlRenamePorts_4_data,
  output        io_vlRenamePorts_5_wen,
  output [7:0] io_vlRenamePorts_5_data,
  input  [7:0] io_int_old_pdest_0,
  input  [7:0] io_int_old_pdest_1,
  input  [7:0] io_int_old_pdest_2,
  input  [7:0] io_int_old_pdest_3,
  input  [7:0] io_int_old_pdest_4,
  input  [7:0] io_int_old_pdest_5,
  input  [7:0] io_fp_old_pdest_0,
  input  [7:0] io_fp_old_pdest_1,
  input  [7:0] io_fp_old_pdest_2,
  input  [7:0] io_fp_old_pdest_3,
  input  [7:0] io_fp_old_pdest_4,
  input  [7:0] io_fp_old_pdest_5,
  input  [7:0] io_vec_old_pdest_0,
  input  [7:0] io_vec_old_pdest_1,
  input  [7:0] io_vec_old_pdest_2,
  input  [7:0] io_vec_old_pdest_3,
  input  [7:0] io_vec_old_pdest_4,
  input  [7:0] io_vec_old_pdest_5,
  input  [7:0] io_v0_old_pdest_0,
  input  [7:0] io_v0_old_pdest_1,
  input  [7:0] io_v0_old_pdest_2,
  input  [7:0] io_v0_old_pdest_3,
  input  [7:0] io_v0_old_pdest_4,
  input  [7:0] io_v0_old_pdest_5,
  input  [7:0] io_vl_old_pdest_0,
  input  [7:0] io_vl_old_pdest_1,
  input  [7:0] io_vl_old_pdest_2,
  input  [7:0] io_vl_old_pdest_3,
  input  [7:0] io_vl_old_pdest_4,
  input  [7:0] io_vl_old_pdest_5,
  input         io_int_need_free_0,
  input         io_int_need_free_1,
  input         io_int_need_free_2,
  input         io_int_need_free_3,
  input         io_int_need_free_4,
  input         io_int_need_free_5,
  input         io_out_0_ready,
  output        io_out_0_valid,
  output [31:0] io_out_0_bits_instr,
  output [49:0] io_out_0_bits_pc,
  output [9:0] io_out_0_bits_foldpc,
  output        io_out_0_bits_exceptionVec_0,
  output        io_out_0_bits_exceptionVec_1,
  output        io_out_0_bits_exceptionVec_2,
  output        io_out_0_bits_exceptionVec_3,
  output        io_out_0_bits_exceptionVec_4,
  output        io_out_0_bits_exceptionVec_5,
  output        io_out_0_bits_exceptionVec_6,
  output        io_out_0_bits_exceptionVec_7,
  output        io_out_0_bits_exceptionVec_8,
  output        io_out_0_bits_exceptionVec_9,
  output        io_out_0_bits_exceptionVec_10,
  output        io_out_0_bits_exceptionVec_11,
  output        io_out_0_bits_exceptionVec_12,
  output        io_out_0_bits_exceptionVec_13,
  output        io_out_0_bits_exceptionVec_14,
  output        io_out_0_bits_exceptionVec_15,
  output        io_out_0_bits_exceptionVec_16,
  output        io_out_0_bits_exceptionVec_17,
  output        io_out_0_bits_exceptionVec_18,
  output        io_out_0_bits_exceptionVec_19,
  output        io_out_0_bits_exceptionVec_20,
  output        io_out_0_bits_exceptionVec_21,
  output        io_out_0_bits_exceptionVec_22,
  output        io_out_0_bits_exceptionVec_23,
  output        io_out_0_bits_isFetchMalAddr,
  output        io_out_0_bits_hasException,
  output [3:0] io_out_0_bits_trigger,
  output        io_out_0_bits_preDecodeInfo_valid,
  output        io_out_0_bits_preDecodeInfo_isRVC,
  output [1:0] io_out_0_bits_preDecodeInfo_brType,
  output        io_out_0_bits_preDecodeInfo_isCall,
  output        io_out_0_bits_preDecodeInfo_isRet,
  output        io_out_0_bits_pred_taken,
  output        io_out_0_bits_crossPageIPFFix,
  output        io_out_0_bits_ftqPtr_flag,
  output [5:0] io_out_0_bits_ftqPtr_value,
  output [3:0] io_out_0_bits_ftqOffset,
  output        io_out_0_bits_satpFlushFirstFetchFault,
  output [3:0] io_out_0_bits_srcType_0,
  output [3:0] io_out_0_bits_srcType_1,
  output [3:0] io_out_0_bits_srcType_2,
  output [3:0] io_out_0_bits_srcType_3,
  output [3:0] io_out_0_bits_srcType_4,
  output [5:0] io_out_0_bits_ldest,
  output [34:0] io_out_0_bits_fuType,
  output [8:0] io_out_0_bits_fuOpType,
  output        io_out_0_bits_rfWen,
  output        io_out_0_bits_fpWen,
  output        io_out_0_bits_vecWen,
  output        io_out_0_bits_v0Wen,
  output        io_out_0_bits_vlWen,
  output        io_out_0_bits_isXSTrap,
  output        io_out_0_bits_waitForward,
  output        io_out_0_bits_blockBackward,
  output        io_out_0_bits_flushPipe,
  output        io_out_0_bits_canRobCompress,
  output [3:0] io_out_0_bits_selImm,
  output [31:0] io_out_0_bits_imm,
  output [1:0] io_out_0_bits_fpu_typeTagOut,
  output        io_out_0_bits_fpu_wflags,
  output [1:0] io_out_0_bits_fpu_typ,
  output [1:0] io_out_0_bits_fpu_fmt,
  output [2:0] io_out_0_bits_fpu_rm,
  output        io_out_0_bits_vpu_vill,
  output        io_out_0_bits_vpu_vma,
  output        io_out_0_bits_vpu_vta,
  output [1:0] io_out_0_bits_vpu_vsew,
  output [2:0] io_out_0_bits_vpu_vlmul,
  output        io_out_0_bits_vpu_specVill,
  output        io_out_0_bits_vpu_specVma,
  output        io_out_0_bits_vpu_specVta,
  output [1:0] io_out_0_bits_vpu_specVsew,
  output [2:0] io_out_0_bits_vpu_specVlmul,
  output        io_out_0_bits_vpu_vm,
  output [7:0] io_out_0_bits_vpu_vstart,
  output [2:0] io_out_0_bits_vpu_frm,
  output        io_out_0_bits_vpu_fpu_isFpToVecInst,
  output        io_out_0_bits_vpu_fpu_isFP32Instr,
  output        io_out_0_bits_vpu_fpu_isFP64Instr,
  output        io_out_0_bits_vpu_fpu_isReduction,
  output        io_out_0_bits_vpu_fpu_isFoldTo1_2,
  output        io_out_0_bits_vpu_fpu_isFoldTo1_4,
  output        io_out_0_bits_vpu_fpu_isFoldTo1_8,
  output [1:0] io_out_0_bits_vpu_vxrm,
  output [6:0] io_out_0_bits_vpu_vuopIdx,
  output        io_out_0_bits_vpu_lastUop,
  output [127:0] io_out_0_bits_vpu_vmask,
  output [7:0] io_out_0_bits_vpu_vl,
  output [2:0] io_out_0_bits_vpu_nf,
  output [1:0] io_out_0_bits_vpu_veew,
  output        io_out_0_bits_vpu_isReverse,
  output        io_out_0_bits_vpu_isExt,
  output        io_out_0_bits_vpu_isNarrow,
  output        io_out_0_bits_vpu_isDstMask,
  output        io_out_0_bits_vpu_isOpMask,
  output        io_out_0_bits_vpu_isMove,
  output        io_out_0_bits_vpu_isDependOldVd,
  output        io_out_0_bits_vpu_isWritePartVd,
  output        io_out_0_bits_vpu_isVleff,
  output        io_out_0_bits_vlsInstr,
  output        io_out_0_bits_wfflags,
  output        io_out_0_bits_isMove,
  output [6:0] io_out_0_bits_uopIdx,
  output        io_out_0_bits_isVset,
  output        io_out_0_bits_firstUop,
  output        io_out_0_bits_lastUop,
  output [6:0] io_out_0_bits_numUops,
  output [6:0] io_out_0_bits_numWB,
  output [2:0] io_out_0_bits_commitType,
  output [7:0] io_out_0_bits_psrc_0,
  output [7:0] io_out_0_bits_psrc_1,
  output [7:0] io_out_0_bits_psrc_2,
  output [7:0] io_out_0_bits_psrc_3,
  output [7:0] io_out_0_bits_psrc_4,
  output [7:0] io_out_0_bits_pdest,
  output        io_out_0_bits_robIdx_flag,
  output [7:0] io_out_0_bits_robIdx_value,
  output [2:0] io_out_0_bits_instrSize,
  output        io_out_0_bits_dirtyFs,
  output        io_out_0_bits_dirtyVs,
  output [3:0] io_out_0_bits_traceBlockInPipe_itype,
  output [3:0] io_out_0_bits_traceBlockInPipe_iretire,
  output        io_out_0_bits_traceBlockInPipe_ilastsize,
  output        io_out_0_bits_eliminatedMove,
  output        io_out_0_bits_snapshot,
  output [63:0] io_out_0_bits_debugInfo_renameTime,
  output [55:0] io_out_0_bits_debug_seqNum_seqNum,
  output [7:0] io_out_0_bits_debug_seqNum_uopIdx,
  output [34:0] io_out_0_bits_debug_fuType,
  output        io_out_0_bits_debug_sim_trig,
  output [4:0] io_out_0_bits_numLsElem,
  input         io_out_1_ready,
  output        io_out_1_valid,
  output [31:0] io_out_1_bits_instr,
  output [49:0] io_out_1_bits_pc,
  output [9:0] io_out_1_bits_foldpc,
  output        io_out_1_bits_exceptionVec_0,
  output        io_out_1_bits_exceptionVec_1,
  output        io_out_1_bits_exceptionVec_2,
  output        io_out_1_bits_exceptionVec_3,
  output        io_out_1_bits_exceptionVec_4,
  output        io_out_1_bits_exceptionVec_5,
  output        io_out_1_bits_exceptionVec_6,
  output        io_out_1_bits_exceptionVec_7,
  output        io_out_1_bits_exceptionVec_8,
  output        io_out_1_bits_exceptionVec_9,
  output        io_out_1_bits_exceptionVec_10,
  output        io_out_1_bits_exceptionVec_11,
  output        io_out_1_bits_exceptionVec_12,
  output        io_out_1_bits_exceptionVec_13,
  output        io_out_1_bits_exceptionVec_14,
  output        io_out_1_bits_exceptionVec_15,
  output        io_out_1_bits_exceptionVec_16,
  output        io_out_1_bits_exceptionVec_17,
  output        io_out_1_bits_exceptionVec_18,
  output        io_out_1_bits_exceptionVec_19,
  output        io_out_1_bits_exceptionVec_20,
  output        io_out_1_bits_exceptionVec_21,
  output        io_out_1_bits_exceptionVec_22,
  output        io_out_1_bits_exceptionVec_23,
  output        io_out_1_bits_isFetchMalAddr,
  output        io_out_1_bits_hasException,
  output [3:0] io_out_1_bits_trigger,
  output        io_out_1_bits_preDecodeInfo_valid,
  output        io_out_1_bits_preDecodeInfo_isRVC,
  output [1:0] io_out_1_bits_preDecodeInfo_brType,
  output        io_out_1_bits_preDecodeInfo_isCall,
  output        io_out_1_bits_preDecodeInfo_isRet,
  output        io_out_1_bits_pred_taken,
  output        io_out_1_bits_crossPageIPFFix,
  output        io_out_1_bits_ftqPtr_flag,
  output [5:0] io_out_1_bits_ftqPtr_value,
  output [3:0] io_out_1_bits_ftqOffset,
  output        io_out_1_bits_satpFlushFirstFetchFault,
  output [3:0] io_out_1_bits_srcType_0,
  output [3:0] io_out_1_bits_srcType_1,
  output [3:0] io_out_1_bits_srcType_2,
  output [3:0] io_out_1_bits_srcType_3,
  output [3:0] io_out_1_bits_srcType_4,
  output [5:0] io_out_1_bits_ldest,
  output [34:0] io_out_1_bits_fuType,
  output [8:0] io_out_1_bits_fuOpType,
  output        io_out_1_bits_rfWen,
  output        io_out_1_bits_fpWen,
  output        io_out_1_bits_vecWen,
  output        io_out_1_bits_v0Wen,
  output        io_out_1_bits_vlWen,
  output        io_out_1_bits_isXSTrap,
  output        io_out_1_bits_waitForward,
  output        io_out_1_bits_blockBackward,
  output        io_out_1_bits_flushPipe,
  output        io_out_1_bits_canRobCompress,
  output [3:0] io_out_1_bits_selImm,
  output [31:0] io_out_1_bits_imm,
  output [1:0] io_out_1_bits_fpu_typeTagOut,
  output        io_out_1_bits_fpu_wflags,
  output [1:0] io_out_1_bits_fpu_typ,
  output [1:0] io_out_1_bits_fpu_fmt,
  output [2:0] io_out_1_bits_fpu_rm,
  output        io_out_1_bits_vpu_vill,
  output        io_out_1_bits_vpu_vma,
  output        io_out_1_bits_vpu_vta,
  output [1:0] io_out_1_bits_vpu_vsew,
  output [2:0] io_out_1_bits_vpu_vlmul,
  output        io_out_1_bits_vpu_specVill,
  output        io_out_1_bits_vpu_specVma,
  output        io_out_1_bits_vpu_specVta,
  output [1:0] io_out_1_bits_vpu_specVsew,
  output [2:0] io_out_1_bits_vpu_specVlmul,
  output        io_out_1_bits_vpu_vm,
  output [7:0] io_out_1_bits_vpu_vstart,
  output [2:0] io_out_1_bits_vpu_frm,
  output        io_out_1_bits_vpu_fpu_isFpToVecInst,
  output        io_out_1_bits_vpu_fpu_isFP32Instr,
  output        io_out_1_bits_vpu_fpu_isFP64Instr,
  output        io_out_1_bits_vpu_fpu_isReduction,
  output        io_out_1_bits_vpu_fpu_isFoldTo1_2,
  output        io_out_1_bits_vpu_fpu_isFoldTo1_4,
  output        io_out_1_bits_vpu_fpu_isFoldTo1_8,
  output [1:0] io_out_1_bits_vpu_vxrm,
  output [6:0] io_out_1_bits_vpu_vuopIdx,
  output        io_out_1_bits_vpu_lastUop,
  output [127:0] io_out_1_bits_vpu_vmask,
  output [7:0] io_out_1_bits_vpu_vl,
  output [2:0] io_out_1_bits_vpu_nf,
  output [1:0] io_out_1_bits_vpu_veew,
  output        io_out_1_bits_vpu_isReverse,
  output        io_out_1_bits_vpu_isExt,
  output        io_out_1_bits_vpu_isNarrow,
  output        io_out_1_bits_vpu_isDstMask,
  output        io_out_1_bits_vpu_isOpMask,
  output        io_out_1_bits_vpu_isMove,
  output        io_out_1_bits_vpu_isDependOldVd,
  output        io_out_1_bits_vpu_isWritePartVd,
  output        io_out_1_bits_vpu_isVleff,
  output        io_out_1_bits_vlsInstr,
  output        io_out_1_bits_wfflags,
  output        io_out_1_bits_isMove,
  output [6:0] io_out_1_bits_uopIdx,
  output        io_out_1_bits_isVset,
  output        io_out_1_bits_firstUop,
  output        io_out_1_bits_lastUop,
  output [6:0] io_out_1_bits_numUops,
  output [6:0] io_out_1_bits_numWB,
  output [2:0] io_out_1_bits_commitType,
  output [7:0] io_out_1_bits_psrc_0,
  output [7:0] io_out_1_bits_psrc_1,
  output [7:0] io_out_1_bits_psrc_2,
  output [7:0] io_out_1_bits_psrc_3,
  output [7:0] io_out_1_bits_psrc_4,
  output [7:0] io_out_1_bits_pdest,
  output        io_out_1_bits_robIdx_flag,
  output [7:0] io_out_1_bits_robIdx_value,
  output [2:0] io_out_1_bits_instrSize,
  output        io_out_1_bits_dirtyFs,
  output        io_out_1_bits_dirtyVs,
  output [3:0] io_out_1_bits_traceBlockInPipe_itype,
  output [3:0] io_out_1_bits_traceBlockInPipe_iretire,
  output        io_out_1_bits_traceBlockInPipe_ilastsize,
  output        io_out_1_bits_eliminatedMove,
  output        io_out_1_bits_snapshot,
  output [63:0] io_out_1_bits_debugInfo_renameTime,
  output [55:0] io_out_1_bits_debug_seqNum_seqNum,
  output [7:0] io_out_1_bits_debug_seqNum_uopIdx,
  output [34:0] io_out_1_bits_debug_fuType,
  output        io_out_1_bits_debug_sim_trig,
  output [4:0] io_out_1_bits_numLsElem,
  input         io_out_2_ready,
  output        io_out_2_valid,
  output [31:0] io_out_2_bits_instr,
  output [49:0] io_out_2_bits_pc,
  output [9:0] io_out_2_bits_foldpc,
  output        io_out_2_bits_exceptionVec_0,
  output        io_out_2_bits_exceptionVec_1,
  output        io_out_2_bits_exceptionVec_2,
  output        io_out_2_bits_exceptionVec_3,
  output        io_out_2_bits_exceptionVec_4,
  output        io_out_2_bits_exceptionVec_5,
  output        io_out_2_bits_exceptionVec_6,
  output        io_out_2_bits_exceptionVec_7,
  output        io_out_2_bits_exceptionVec_8,
  output        io_out_2_bits_exceptionVec_9,
  output        io_out_2_bits_exceptionVec_10,
  output        io_out_2_bits_exceptionVec_11,
  output        io_out_2_bits_exceptionVec_12,
  output        io_out_2_bits_exceptionVec_13,
  output        io_out_2_bits_exceptionVec_14,
  output        io_out_2_bits_exceptionVec_15,
  output        io_out_2_bits_exceptionVec_16,
  output        io_out_2_bits_exceptionVec_17,
  output        io_out_2_bits_exceptionVec_18,
  output        io_out_2_bits_exceptionVec_19,
  output        io_out_2_bits_exceptionVec_20,
  output        io_out_2_bits_exceptionVec_21,
  output        io_out_2_bits_exceptionVec_22,
  output        io_out_2_bits_exceptionVec_23,
  output        io_out_2_bits_isFetchMalAddr,
  output        io_out_2_bits_hasException,
  output [3:0] io_out_2_bits_trigger,
  output        io_out_2_bits_preDecodeInfo_valid,
  output        io_out_2_bits_preDecodeInfo_isRVC,
  output [1:0] io_out_2_bits_preDecodeInfo_brType,
  output        io_out_2_bits_preDecodeInfo_isCall,
  output        io_out_2_bits_preDecodeInfo_isRet,
  output        io_out_2_bits_pred_taken,
  output        io_out_2_bits_crossPageIPFFix,
  output        io_out_2_bits_ftqPtr_flag,
  output [5:0] io_out_2_bits_ftqPtr_value,
  output [3:0] io_out_2_bits_ftqOffset,
  output        io_out_2_bits_satpFlushFirstFetchFault,
  output [3:0] io_out_2_bits_srcType_0,
  output [3:0] io_out_2_bits_srcType_1,
  output [3:0] io_out_2_bits_srcType_2,
  output [3:0] io_out_2_bits_srcType_3,
  output [3:0] io_out_2_bits_srcType_4,
  output [5:0] io_out_2_bits_ldest,
  output [34:0] io_out_2_bits_fuType,
  output [8:0] io_out_2_bits_fuOpType,
  output        io_out_2_bits_rfWen,
  output        io_out_2_bits_fpWen,
  output        io_out_2_bits_vecWen,
  output        io_out_2_bits_v0Wen,
  output        io_out_2_bits_vlWen,
  output        io_out_2_bits_isXSTrap,
  output        io_out_2_bits_waitForward,
  output        io_out_2_bits_blockBackward,
  output        io_out_2_bits_flushPipe,
  output        io_out_2_bits_canRobCompress,
  output [3:0] io_out_2_bits_selImm,
  output [31:0] io_out_2_bits_imm,
  output [1:0] io_out_2_bits_fpu_typeTagOut,
  output        io_out_2_bits_fpu_wflags,
  output [1:0] io_out_2_bits_fpu_typ,
  output [1:0] io_out_2_bits_fpu_fmt,
  output [2:0] io_out_2_bits_fpu_rm,
  output        io_out_2_bits_vpu_vill,
  output        io_out_2_bits_vpu_vma,
  output        io_out_2_bits_vpu_vta,
  output [1:0] io_out_2_bits_vpu_vsew,
  output [2:0] io_out_2_bits_vpu_vlmul,
  output        io_out_2_bits_vpu_specVill,
  output        io_out_2_bits_vpu_specVma,
  output        io_out_2_bits_vpu_specVta,
  output [1:0] io_out_2_bits_vpu_specVsew,
  output [2:0] io_out_2_bits_vpu_specVlmul,
  output        io_out_2_bits_vpu_vm,
  output [7:0] io_out_2_bits_vpu_vstart,
  output [2:0] io_out_2_bits_vpu_frm,
  output        io_out_2_bits_vpu_fpu_isFpToVecInst,
  output        io_out_2_bits_vpu_fpu_isFP32Instr,
  output        io_out_2_bits_vpu_fpu_isFP64Instr,
  output        io_out_2_bits_vpu_fpu_isReduction,
  output        io_out_2_bits_vpu_fpu_isFoldTo1_2,
  output        io_out_2_bits_vpu_fpu_isFoldTo1_4,
  output        io_out_2_bits_vpu_fpu_isFoldTo1_8,
  output [1:0] io_out_2_bits_vpu_vxrm,
  output [6:0] io_out_2_bits_vpu_vuopIdx,
  output        io_out_2_bits_vpu_lastUop,
  output [127:0] io_out_2_bits_vpu_vmask,
  output [7:0] io_out_2_bits_vpu_vl,
  output [2:0] io_out_2_bits_vpu_nf,
  output [1:0] io_out_2_bits_vpu_veew,
  output        io_out_2_bits_vpu_isReverse,
  output        io_out_2_bits_vpu_isExt,
  output        io_out_2_bits_vpu_isNarrow,
  output        io_out_2_bits_vpu_isDstMask,
  output        io_out_2_bits_vpu_isOpMask,
  output        io_out_2_bits_vpu_isMove,
  output        io_out_2_bits_vpu_isDependOldVd,
  output        io_out_2_bits_vpu_isWritePartVd,
  output        io_out_2_bits_vpu_isVleff,
  output        io_out_2_bits_vlsInstr,
  output        io_out_2_bits_wfflags,
  output        io_out_2_bits_isMove,
  output [6:0] io_out_2_bits_uopIdx,
  output        io_out_2_bits_isVset,
  output        io_out_2_bits_firstUop,
  output        io_out_2_bits_lastUop,
  output [6:0] io_out_2_bits_numUops,
  output [6:0] io_out_2_bits_numWB,
  output [2:0] io_out_2_bits_commitType,
  output [7:0] io_out_2_bits_psrc_0,
  output [7:0] io_out_2_bits_psrc_1,
  output [7:0] io_out_2_bits_psrc_2,
  output [7:0] io_out_2_bits_psrc_3,
  output [7:0] io_out_2_bits_psrc_4,
  output [7:0] io_out_2_bits_pdest,
  output        io_out_2_bits_robIdx_flag,
  output [7:0] io_out_2_bits_robIdx_value,
  output [2:0] io_out_2_bits_instrSize,
  output        io_out_2_bits_dirtyFs,
  output        io_out_2_bits_dirtyVs,
  output [3:0] io_out_2_bits_traceBlockInPipe_itype,
  output [3:0] io_out_2_bits_traceBlockInPipe_iretire,
  output        io_out_2_bits_traceBlockInPipe_ilastsize,
  output        io_out_2_bits_eliminatedMove,
  output        io_out_2_bits_snapshot,
  output [63:0] io_out_2_bits_debugInfo_renameTime,
  output [55:0] io_out_2_bits_debug_seqNum_seqNum,
  output [7:0] io_out_2_bits_debug_seqNum_uopIdx,
  output [34:0] io_out_2_bits_debug_fuType,
  output        io_out_2_bits_debug_sim_trig,
  output [4:0] io_out_2_bits_numLsElem,
  input         io_out_3_ready,
  output        io_out_3_valid,
  output [31:0] io_out_3_bits_instr,
  output [49:0] io_out_3_bits_pc,
  output [9:0] io_out_3_bits_foldpc,
  output        io_out_3_bits_exceptionVec_0,
  output        io_out_3_bits_exceptionVec_1,
  output        io_out_3_bits_exceptionVec_2,
  output        io_out_3_bits_exceptionVec_3,
  output        io_out_3_bits_exceptionVec_4,
  output        io_out_3_bits_exceptionVec_5,
  output        io_out_3_bits_exceptionVec_6,
  output        io_out_3_bits_exceptionVec_7,
  output        io_out_3_bits_exceptionVec_8,
  output        io_out_3_bits_exceptionVec_9,
  output        io_out_3_bits_exceptionVec_10,
  output        io_out_3_bits_exceptionVec_11,
  output        io_out_3_bits_exceptionVec_12,
  output        io_out_3_bits_exceptionVec_13,
  output        io_out_3_bits_exceptionVec_14,
  output        io_out_3_bits_exceptionVec_15,
  output        io_out_3_bits_exceptionVec_16,
  output        io_out_3_bits_exceptionVec_17,
  output        io_out_3_bits_exceptionVec_18,
  output        io_out_3_bits_exceptionVec_19,
  output        io_out_3_bits_exceptionVec_20,
  output        io_out_3_bits_exceptionVec_21,
  output        io_out_3_bits_exceptionVec_22,
  output        io_out_3_bits_exceptionVec_23,
  output        io_out_3_bits_isFetchMalAddr,
  output        io_out_3_bits_hasException,
  output [3:0] io_out_3_bits_trigger,
  output        io_out_3_bits_preDecodeInfo_valid,
  output        io_out_3_bits_preDecodeInfo_isRVC,
  output [1:0] io_out_3_bits_preDecodeInfo_brType,
  output        io_out_3_bits_preDecodeInfo_isCall,
  output        io_out_3_bits_preDecodeInfo_isRet,
  output        io_out_3_bits_pred_taken,
  output        io_out_3_bits_crossPageIPFFix,
  output        io_out_3_bits_ftqPtr_flag,
  output [5:0] io_out_3_bits_ftqPtr_value,
  output [3:0] io_out_3_bits_ftqOffset,
  output        io_out_3_bits_satpFlushFirstFetchFault,
  output [3:0] io_out_3_bits_srcType_0,
  output [3:0] io_out_3_bits_srcType_1,
  output [3:0] io_out_3_bits_srcType_2,
  output [3:0] io_out_3_bits_srcType_3,
  output [3:0] io_out_3_bits_srcType_4,
  output [5:0] io_out_3_bits_ldest,
  output [34:0] io_out_3_bits_fuType,
  output [8:0] io_out_3_bits_fuOpType,
  output        io_out_3_bits_rfWen,
  output        io_out_3_bits_fpWen,
  output        io_out_3_bits_vecWen,
  output        io_out_3_bits_v0Wen,
  output        io_out_3_bits_vlWen,
  output        io_out_3_bits_isXSTrap,
  output        io_out_3_bits_waitForward,
  output        io_out_3_bits_blockBackward,
  output        io_out_3_bits_flushPipe,
  output        io_out_3_bits_canRobCompress,
  output [3:0] io_out_3_bits_selImm,
  output [31:0] io_out_3_bits_imm,
  output [1:0] io_out_3_bits_fpu_typeTagOut,
  output        io_out_3_bits_fpu_wflags,
  output [1:0] io_out_3_bits_fpu_typ,
  output [1:0] io_out_3_bits_fpu_fmt,
  output [2:0] io_out_3_bits_fpu_rm,
  output        io_out_3_bits_vpu_vill,
  output        io_out_3_bits_vpu_vma,
  output        io_out_3_bits_vpu_vta,
  output [1:0] io_out_3_bits_vpu_vsew,
  output [2:0] io_out_3_bits_vpu_vlmul,
  output        io_out_3_bits_vpu_specVill,
  output        io_out_3_bits_vpu_specVma,
  output        io_out_3_bits_vpu_specVta,
  output [1:0] io_out_3_bits_vpu_specVsew,
  output [2:0] io_out_3_bits_vpu_specVlmul,
  output        io_out_3_bits_vpu_vm,
  output [7:0] io_out_3_bits_vpu_vstart,
  output [2:0] io_out_3_bits_vpu_frm,
  output        io_out_3_bits_vpu_fpu_isFpToVecInst,
  output        io_out_3_bits_vpu_fpu_isFP32Instr,
  output        io_out_3_bits_vpu_fpu_isFP64Instr,
  output        io_out_3_bits_vpu_fpu_isReduction,
  output        io_out_3_bits_vpu_fpu_isFoldTo1_2,
  output        io_out_3_bits_vpu_fpu_isFoldTo1_4,
  output        io_out_3_bits_vpu_fpu_isFoldTo1_8,
  output [1:0] io_out_3_bits_vpu_vxrm,
  output [6:0] io_out_3_bits_vpu_vuopIdx,
  output        io_out_3_bits_vpu_lastUop,
  output [127:0] io_out_3_bits_vpu_vmask,
  output [7:0] io_out_3_bits_vpu_vl,
  output [2:0] io_out_3_bits_vpu_nf,
  output [1:0] io_out_3_bits_vpu_veew,
  output        io_out_3_bits_vpu_isReverse,
  output        io_out_3_bits_vpu_isExt,
  output        io_out_3_bits_vpu_isNarrow,
  output        io_out_3_bits_vpu_isDstMask,
  output        io_out_3_bits_vpu_isOpMask,
  output        io_out_3_bits_vpu_isMove,
  output        io_out_3_bits_vpu_isDependOldVd,
  output        io_out_3_bits_vpu_isWritePartVd,
  output        io_out_3_bits_vpu_isVleff,
  output        io_out_3_bits_vlsInstr,
  output        io_out_3_bits_wfflags,
  output        io_out_3_bits_isMove,
  output [6:0] io_out_3_bits_uopIdx,
  output        io_out_3_bits_isVset,
  output        io_out_3_bits_firstUop,
  output        io_out_3_bits_lastUop,
  output [6:0] io_out_3_bits_numUops,
  output [6:0] io_out_3_bits_numWB,
  output [2:0] io_out_3_bits_commitType,
  output [7:0] io_out_3_bits_psrc_0,
  output [7:0] io_out_3_bits_psrc_1,
  output [7:0] io_out_3_bits_psrc_2,
  output [7:0] io_out_3_bits_psrc_3,
  output [7:0] io_out_3_bits_psrc_4,
  output [7:0] io_out_3_bits_pdest,
  output        io_out_3_bits_robIdx_flag,
  output [7:0] io_out_3_bits_robIdx_value,
  output [2:0] io_out_3_bits_instrSize,
  output        io_out_3_bits_dirtyFs,
  output        io_out_3_bits_dirtyVs,
  output [3:0] io_out_3_bits_traceBlockInPipe_itype,
  output [3:0] io_out_3_bits_traceBlockInPipe_iretire,
  output        io_out_3_bits_traceBlockInPipe_ilastsize,
  output        io_out_3_bits_eliminatedMove,
  output        io_out_3_bits_snapshot,
  output [63:0] io_out_3_bits_debugInfo_renameTime,
  output [55:0] io_out_3_bits_debug_seqNum_seqNum,
  output [7:0] io_out_3_bits_debug_seqNum_uopIdx,
  output [34:0] io_out_3_bits_debug_fuType,
  output        io_out_3_bits_debug_sim_trig,
  output [4:0] io_out_3_bits_numLsElem,
  input         io_out_4_ready,
  output        io_out_4_valid,
  output [31:0] io_out_4_bits_instr,
  output [49:0] io_out_4_bits_pc,
  output [9:0] io_out_4_bits_foldpc,
  output        io_out_4_bits_exceptionVec_0,
  output        io_out_4_bits_exceptionVec_1,
  output        io_out_4_bits_exceptionVec_2,
  output        io_out_4_bits_exceptionVec_3,
  output        io_out_4_bits_exceptionVec_4,
  output        io_out_4_bits_exceptionVec_5,
  output        io_out_4_bits_exceptionVec_6,
  output        io_out_4_bits_exceptionVec_7,
  output        io_out_4_bits_exceptionVec_8,
  output        io_out_4_bits_exceptionVec_9,
  output        io_out_4_bits_exceptionVec_10,
  output        io_out_4_bits_exceptionVec_11,
  output        io_out_4_bits_exceptionVec_12,
  output        io_out_4_bits_exceptionVec_13,
  output        io_out_4_bits_exceptionVec_14,
  output        io_out_4_bits_exceptionVec_15,
  output        io_out_4_bits_exceptionVec_16,
  output        io_out_4_bits_exceptionVec_17,
  output        io_out_4_bits_exceptionVec_18,
  output        io_out_4_bits_exceptionVec_19,
  output        io_out_4_bits_exceptionVec_20,
  output        io_out_4_bits_exceptionVec_21,
  output        io_out_4_bits_exceptionVec_22,
  output        io_out_4_bits_exceptionVec_23,
  output        io_out_4_bits_isFetchMalAddr,
  output        io_out_4_bits_hasException,
  output [3:0] io_out_4_bits_trigger,
  output        io_out_4_bits_preDecodeInfo_valid,
  output        io_out_4_bits_preDecodeInfo_isRVC,
  output [1:0] io_out_4_bits_preDecodeInfo_brType,
  output        io_out_4_bits_preDecodeInfo_isCall,
  output        io_out_4_bits_preDecodeInfo_isRet,
  output        io_out_4_bits_pred_taken,
  output        io_out_4_bits_crossPageIPFFix,
  output        io_out_4_bits_ftqPtr_flag,
  output [5:0] io_out_4_bits_ftqPtr_value,
  output [3:0] io_out_4_bits_ftqOffset,
  output        io_out_4_bits_satpFlushFirstFetchFault,
  output [3:0] io_out_4_bits_srcType_0,
  output [3:0] io_out_4_bits_srcType_1,
  output [3:0] io_out_4_bits_srcType_2,
  output [3:0] io_out_4_bits_srcType_3,
  output [3:0] io_out_4_bits_srcType_4,
  output [5:0] io_out_4_bits_ldest,
  output [34:0] io_out_4_bits_fuType,
  output [8:0] io_out_4_bits_fuOpType,
  output        io_out_4_bits_rfWen,
  output        io_out_4_bits_fpWen,
  output        io_out_4_bits_vecWen,
  output        io_out_4_bits_v0Wen,
  output        io_out_4_bits_vlWen,
  output        io_out_4_bits_isXSTrap,
  output        io_out_4_bits_waitForward,
  output        io_out_4_bits_blockBackward,
  output        io_out_4_bits_flushPipe,
  output        io_out_4_bits_canRobCompress,
  output [3:0] io_out_4_bits_selImm,
  output [31:0] io_out_4_bits_imm,
  output [1:0] io_out_4_bits_fpu_typeTagOut,
  output        io_out_4_bits_fpu_wflags,
  output [1:0] io_out_4_bits_fpu_typ,
  output [1:0] io_out_4_bits_fpu_fmt,
  output [2:0] io_out_4_bits_fpu_rm,
  output        io_out_4_bits_vpu_vill,
  output        io_out_4_bits_vpu_vma,
  output        io_out_4_bits_vpu_vta,
  output [1:0] io_out_4_bits_vpu_vsew,
  output [2:0] io_out_4_bits_vpu_vlmul,
  output        io_out_4_bits_vpu_specVill,
  output        io_out_4_bits_vpu_specVma,
  output        io_out_4_bits_vpu_specVta,
  output [1:0] io_out_4_bits_vpu_specVsew,
  output [2:0] io_out_4_bits_vpu_specVlmul,
  output        io_out_4_bits_vpu_vm,
  output [7:0] io_out_4_bits_vpu_vstart,
  output [2:0] io_out_4_bits_vpu_frm,
  output        io_out_4_bits_vpu_fpu_isFpToVecInst,
  output        io_out_4_bits_vpu_fpu_isFP32Instr,
  output        io_out_4_bits_vpu_fpu_isFP64Instr,
  output        io_out_4_bits_vpu_fpu_isReduction,
  output        io_out_4_bits_vpu_fpu_isFoldTo1_2,
  output        io_out_4_bits_vpu_fpu_isFoldTo1_4,
  output        io_out_4_bits_vpu_fpu_isFoldTo1_8,
  output [1:0] io_out_4_bits_vpu_vxrm,
  output [6:0] io_out_4_bits_vpu_vuopIdx,
  output        io_out_4_bits_vpu_lastUop,
  output [127:0] io_out_4_bits_vpu_vmask,
  output [7:0] io_out_4_bits_vpu_vl,
  output [2:0] io_out_4_bits_vpu_nf,
  output [1:0] io_out_4_bits_vpu_veew,
  output        io_out_4_bits_vpu_isReverse,
  output        io_out_4_bits_vpu_isExt,
  output        io_out_4_bits_vpu_isNarrow,
  output        io_out_4_bits_vpu_isDstMask,
  output        io_out_4_bits_vpu_isOpMask,
  output        io_out_4_bits_vpu_isMove,
  output        io_out_4_bits_vpu_isDependOldVd,
  output        io_out_4_bits_vpu_isWritePartVd,
  output        io_out_4_bits_vpu_isVleff,
  output        io_out_4_bits_vlsInstr,
  output        io_out_4_bits_wfflags,
  output        io_out_4_bits_isMove,
  output [6:0] io_out_4_bits_uopIdx,
  output        io_out_4_bits_isVset,
  output        io_out_4_bits_firstUop,
  output        io_out_4_bits_lastUop,
  output [6:0] io_out_4_bits_numUops,
  output [6:0] io_out_4_bits_numWB,
  output [2:0] io_out_4_bits_commitType,
  output [7:0] io_out_4_bits_psrc_0,
  output [7:0] io_out_4_bits_psrc_1,
  output [7:0] io_out_4_bits_psrc_2,
  output [7:0] io_out_4_bits_psrc_3,
  output [7:0] io_out_4_bits_psrc_4,
  output [7:0] io_out_4_bits_pdest,
  output        io_out_4_bits_robIdx_flag,
  output [7:0] io_out_4_bits_robIdx_value,
  output [2:0] io_out_4_bits_instrSize,
  output        io_out_4_bits_dirtyFs,
  output        io_out_4_bits_dirtyVs,
  output [3:0] io_out_4_bits_traceBlockInPipe_itype,
  output [3:0] io_out_4_bits_traceBlockInPipe_iretire,
  output        io_out_4_bits_traceBlockInPipe_ilastsize,
  output        io_out_4_bits_eliminatedMove,
  output        io_out_4_bits_snapshot,
  output [63:0] io_out_4_bits_debugInfo_renameTime,
  output [55:0] io_out_4_bits_debug_seqNum_seqNum,
  output [7:0] io_out_4_bits_debug_seqNum_uopIdx,
  output [34:0] io_out_4_bits_debug_fuType,
  output        io_out_4_bits_debug_sim_trig,
  output [4:0] io_out_4_bits_numLsElem,
  input         io_out_5_ready,
  output        io_out_5_valid,
  output [31:0] io_out_5_bits_instr,
  output [49:0] io_out_5_bits_pc,
  output [9:0] io_out_5_bits_foldpc,
  output        io_out_5_bits_exceptionVec_0,
  output        io_out_5_bits_exceptionVec_1,
  output        io_out_5_bits_exceptionVec_2,
  output        io_out_5_bits_exceptionVec_3,
  output        io_out_5_bits_exceptionVec_4,
  output        io_out_5_bits_exceptionVec_5,
  output        io_out_5_bits_exceptionVec_6,
  output        io_out_5_bits_exceptionVec_7,
  output        io_out_5_bits_exceptionVec_8,
  output        io_out_5_bits_exceptionVec_9,
  output        io_out_5_bits_exceptionVec_10,
  output        io_out_5_bits_exceptionVec_11,
  output        io_out_5_bits_exceptionVec_12,
  output        io_out_5_bits_exceptionVec_13,
  output        io_out_5_bits_exceptionVec_14,
  output        io_out_5_bits_exceptionVec_15,
  output        io_out_5_bits_exceptionVec_16,
  output        io_out_5_bits_exceptionVec_17,
  output        io_out_5_bits_exceptionVec_18,
  output        io_out_5_bits_exceptionVec_19,
  output        io_out_5_bits_exceptionVec_20,
  output        io_out_5_bits_exceptionVec_21,
  output        io_out_5_bits_exceptionVec_22,
  output        io_out_5_bits_exceptionVec_23,
  output        io_out_5_bits_isFetchMalAddr,
  output        io_out_5_bits_hasException,
  output [3:0] io_out_5_bits_trigger,
  output        io_out_5_bits_preDecodeInfo_valid,
  output        io_out_5_bits_preDecodeInfo_isRVC,
  output [1:0] io_out_5_bits_preDecodeInfo_brType,
  output        io_out_5_bits_preDecodeInfo_isCall,
  output        io_out_5_bits_preDecodeInfo_isRet,
  output        io_out_5_bits_pred_taken,
  output        io_out_5_bits_crossPageIPFFix,
  output        io_out_5_bits_ftqPtr_flag,
  output [5:0] io_out_5_bits_ftqPtr_value,
  output [3:0] io_out_5_bits_ftqOffset,
  output        io_out_5_bits_satpFlushFirstFetchFault,
  output [3:0] io_out_5_bits_srcType_0,
  output [3:0] io_out_5_bits_srcType_1,
  output [3:0] io_out_5_bits_srcType_2,
  output [3:0] io_out_5_bits_srcType_3,
  output [3:0] io_out_5_bits_srcType_4,
  output [5:0] io_out_5_bits_ldest,
  output [34:0] io_out_5_bits_fuType,
  output [8:0] io_out_5_bits_fuOpType,
  output        io_out_5_bits_rfWen,
  output        io_out_5_bits_fpWen,
  output        io_out_5_bits_vecWen,
  output        io_out_5_bits_v0Wen,
  output        io_out_5_bits_vlWen,
  output        io_out_5_bits_isXSTrap,
  output        io_out_5_bits_waitForward,
  output        io_out_5_bits_blockBackward,
  output        io_out_5_bits_flushPipe,
  output        io_out_5_bits_canRobCompress,
  output [3:0] io_out_5_bits_selImm,
  output [31:0] io_out_5_bits_imm,
  output [1:0] io_out_5_bits_fpu_typeTagOut,
  output        io_out_5_bits_fpu_wflags,
  output [1:0] io_out_5_bits_fpu_typ,
  output [1:0] io_out_5_bits_fpu_fmt,
  output [2:0] io_out_5_bits_fpu_rm,
  output        io_out_5_bits_vpu_vill,
  output        io_out_5_bits_vpu_vma,
  output        io_out_5_bits_vpu_vta,
  output [1:0] io_out_5_bits_vpu_vsew,
  output [2:0] io_out_5_bits_vpu_vlmul,
  output        io_out_5_bits_vpu_specVill,
  output        io_out_5_bits_vpu_specVma,
  output        io_out_5_bits_vpu_specVta,
  output [1:0] io_out_5_bits_vpu_specVsew,
  output [2:0] io_out_5_bits_vpu_specVlmul,
  output        io_out_5_bits_vpu_vm,
  output [7:0] io_out_5_bits_vpu_vstart,
  output [2:0] io_out_5_bits_vpu_frm,
  output        io_out_5_bits_vpu_fpu_isFpToVecInst,
  output        io_out_5_bits_vpu_fpu_isFP32Instr,
  output        io_out_5_bits_vpu_fpu_isFP64Instr,
  output        io_out_5_bits_vpu_fpu_isReduction,
  output        io_out_5_bits_vpu_fpu_isFoldTo1_2,
  output        io_out_5_bits_vpu_fpu_isFoldTo1_4,
  output        io_out_5_bits_vpu_fpu_isFoldTo1_8,
  output [1:0] io_out_5_bits_vpu_vxrm,
  output [6:0] io_out_5_bits_vpu_vuopIdx,
  output        io_out_5_bits_vpu_lastUop,
  output [127:0] io_out_5_bits_vpu_vmask,
  output [7:0] io_out_5_bits_vpu_vl,
  output [2:0] io_out_5_bits_vpu_nf,
  output [1:0] io_out_5_bits_vpu_veew,
  output        io_out_5_bits_vpu_isReverse,
  output        io_out_5_bits_vpu_isExt,
  output        io_out_5_bits_vpu_isNarrow,
  output        io_out_5_bits_vpu_isDstMask,
  output        io_out_5_bits_vpu_isOpMask,
  output        io_out_5_bits_vpu_isMove,
  output        io_out_5_bits_vpu_isDependOldVd,
  output        io_out_5_bits_vpu_isWritePartVd,
  output        io_out_5_bits_vpu_isVleff,
  output        io_out_5_bits_vlsInstr,
  output        io_out_5_bits_wfflags,
  output        io_out_5_bits_isMove,
  output [6:0] io_out_5_bits_uopIdx,
  output        io_out_5_bits_isVset,
  output        io_out_5_bits_firstUop,
  output        io_out_5_bits_lastUop,
  output [6:0] io_out_5_bits_numUops,
  output [6:0] io_out_5_bits_numWB,
  output [2:0] io_out_5_bits_commitType,
  output [7:0] io_out_5_bits_psrc_0,
  output [7:0] io_out_5_bits_psrc_1,
  output [7:0] io_out_5_bits_psrc_2,
  output [7:0] io_out_5_bits_psrc_3,
  output [7:0] io_out_5_bits_psrc_4,
  output [7:0] io_out_5_bits_pdest,
  output        io_out_5_bits_robIdx_flag,
  output [7:0] io_out_5_bits_robIdx_value,
  output [2:0] io_out_5_bits_instrSize,
  output        io_out_5_bits_dirtyFs,
  output        io_out_5_bits_dirtyVs,
  output [3:0] io_out_5_bits_traceBlockInPipe_itype,
  output [3:0] io_out_5_bits_traceBlockInPipe_iretire,
  output        io_out_5_bits_traceBlockInPipe_ilastsize,
  output        io_out_5_bits_eliminatedMove,
  output        io_out_5_bits_snapshot,
  output [63:0] io_out_5_bits_debugInfo_renameTime,
  output [55:0] io_out_5_bits_debug_seqNum_seqNum,
  output [7:0] io_out_5_bits_debug_seqNum_uopIdx,
  output [34:0] io_out_5_bits_debug_fuType,
  output        io_out_5_bits_debug_sim_trig,
  output [4:0] io_out_5_bits_numLsElem,
  input         io_snpt_snptDeq,
  input         io_snpt_useSnpt,
  input  [1:0] io_snpt_snptSelect,
  input         io_snpt_flushVec_0,
  input         io_snpt_flushVec_1,
  input         io_snpt_flushVec_2,
  input         io_snpt_flushVec_3,
  input         io_snptLastEnq_valid,
  input         io_snptLastEnq_bits_flag,
  input  [7:0] io_snptLastEnq_bits_value,
  input         io_snptIsFull,
  input  [7:0] io_debug_int_rat_0,
  input  [7:0] io_debug_int_rat_1,
  input  [7:0] io_debug_int_rat_2,
  input  [7:0] io_debug_int_rat_3,
  input  [7:0] io_debug_int_rat_4,
  input  [7:0] io_debug_int_rat_5,
  input  [7:0] io_debug_int_rat_6,
  input  [7:0] io_debug_int_rat_7,
  input  [7:0] io_debug_int_rat_8,
  input  [7:0] io_debug_int_rat_9,
  input  [7:0] io_debug_int_rat_10,
  input  [7:0] io_debug_int_rat_11,
  input  [7:0] io_debug_int_rat_12,
  input  [7:0] io_debug_int_rat_13,
  input  [7:0] io_debug_int_rat_14,
  input  [7:0] io_debug_int_rat_15,
  input  [7:0] io_debug_int_rat_16,
  input  [7:0] io_debug_int_rat_17,
  input  [7:0] io_debug_int_rat_18,
  input  [7:0] io_debug_int_rat_19,
  input  [7:0] io_debug_int_rat_20,
  input  [7:0] io_debug_int_rat_21,
  input  [7:0] io_debug_int_rat_22,
  input  [7:0] io_debug_int_rat_23,
  input  [7:0] io_debug_int_rat_24,
  input  [7:0] io_debug_int_rat_25,
  input  [7:0] io_debug_int_rat_26,
  input  [7:0] io_debug_int_rat_27,
  input  [7:0] io_debug_int_rat_28,
  input  [7:0] io_debug_int_rat_29,
  input  [7:0] io_debug_int_rat_30,
  input  [7:0] io_debug_int_rat_31,
  input  [5:0] io_stallReason_in_reason_0,
  input  [5:0] io_stallReason_in_reason_1,
  input  [5:0] io_stallReason_in_reason_2,
  input  [5:0] io_stallReason_in_reason_3,
  input  [5:0] io_stallReason_in_reason_4,
  input  [5:0] io_stallReason_in_reason_5,
  output        io_stallReason_in_backReason_valid,
  output [5:0] io_stallReason_in_backReason_bits,
  output [5:0] io_stallReason_out_reason_0,
  output [5:0] io_stallReason_out_reason_1,
  output [5:0] io_stallReason_out_reason_2,
  output [5:0] io_stallReason_out_reason_3,
  output [5:0] io_stallReason_out_reason_4,
  output [5:0] io_stallReason_out_reason_5,
  input         io_stallReason_out_backReason_valid,
  output [5:0] io_perf_0_value,
  output [5:0] io_perf_1_value,
  output [5:0] io_perf_2_value,
  output [5:0] io_perf_3_value,
  output [5:0] io_perf_4_value,
  output [5:0] io_perf_5_value,
  output [5:0] io_perf_6_value,
  output [5:0] io_perf_7_value,
  output [5:0] io_perf_8_value,
  output [5:0] io_perf_9_value,
  output [5:0] io_perf_10_value,
  output [5:0] io_perf_11_value,
  output [5:0] io_perf_12_value,
  output [5:0] io_perf_13_value,
  output [5:0] io_perf_14_value,
  output [5:0] io_perf_15_value,
  output [5:0] io_perf_16_value,
  output [5:0] io_perf_17_value,
  output [5:0] io_perf_18_value,
  output [5:0] io_perf_19_value,
  output [5:0] io_perf_20_value,
  output [5:0] io_perf_21_value,
  output [5:0] io_perf_22_value,
  output [5:0] io_perf_23_value,
  output [5:0] io_perf_24_value,
  output [5:0] io_perf_25_value,
  output [5:0] io_perf_26_value,
  output [5:0] io_perf_27_value,
  output [5:0] io_perf_28_value,
  output [5:0] io_perf_29_value
);

  // ---- 中间载体 ----
  decoded_inst_t in_b [RENAME_WIDTH];
  decoded_inst_t out_pt [RENAME_WIDTH];
  logic [RENAME_WIDTH-1:0] in_v, in_r, out_v, out_r;
  logic [PHYREG_W-1:0] o_psrc [RENAME_WIDTH][NUM_SRC];
  logic [PHYREG_W-1:0] o_pdest [RENAME_WIDTH];
  logic o_robIdx_flag [RENAME_WIDTH];
  logic [ROB_PTR_W-1:0] o_robIdx_value [RENAME_WIDTH];
  logic o_isMove [RENAME_WIDTH], o_snapshot [RENAME_WIDTH], o_hasException [RENAME_WIDTH];
  logic [SRCTYPE_W-1:0] o_srcType0 [RENAME_WIDTH];
  logic [IMM_OUT_W-1:0] o_imm [RENAME_WIDTH];
  logic [63:0] o_renameTime [RENAME_WIDTH];
  logic [2:0] o_instrSize [RENAME_WIDTH];
  logic o_dirtyFs [RENAME_WIDTH], o_dirtyVs [RENAME_WIDTH], o_simTrig [RENAME_WIDTH], o_ilastsize [RENAME_WIDTH];
  logic [3:0] o_itype [RENAME_WIDTH], o_iretire [RENAME_WIDTH];
  logic o_lastUop [RENAME_WIDTH], o_wfflags [RENAME_WIDTH], o_firstUop [RENAME_WIDTH];
  logic o_waitForward [RENAME_WIDTH], o_blockBackward [RENAME_WIDTH];
  logic [6:0] o_numUops [RENAME_WIDTH], o_numWB [RENAME_WIDTH];
  logic [4:0] o_numLsElem [RENAME_WIDTH];
  logic o_ftqFlag [RENAME_WIDTH];
  logic [5:0] o_ftqValue [RENAME_WIDTH];
  logic [3:0] o_ftqOff [RENAME_WIDTH];
  rat_wport_t intRP [COMMIT_WIDTH], fpRP [COMMIT_WIDTH], vecRP [COMMIT_WIDTH];
  logic v0RP_wen [COMMIT_WIDTH], vlRP_wen [COMMIT_WIDTH];
  logic [PHYREG_W-1:0] v0RP_data [COMMIT_WIDTH], vlRP_data [COMMIT_WIDTH];
  logic [PHYREG_W-1:0] intRd [RENAME_WIDTH][2], fpRd [RENAME_WIDTH][3], vecRd [RENAME_WIDTH][3];
  logic [PHYREG_W-1:0] v0Rd [RENAME_WIDTH], vlRd [RENAME_WIDTH];
  logic [PHYREG_W-1:0] int_oldpd [COMMIT_WIDTH], fp_oldpd [COMMIT_WIDTH], vec_oldpd [COMMIT_WIDTH], v0_oldpd [COMMIT_WIDTH], vl_oldpd [COMMIT_WIDTH];
  logic [PHYREG_W-1:0] dbg_int_rat [INT_LREGS];
  logic [5:0] sr_in [RENAME_WIDTH], sr_out [RENAME_WIDTH];
  logic [5:0] perf_v [NUM_PERF];
  logic [3:0] flushv;
  logic [COMMIT_WIDTH-1:0] rab_cv, rab_wv, rab_rf, rab_fp, rab_vec, rab_v0, rab_vl, rab_mv, int_nf;
  logic [RENAME_WIDTH-1:0] fi_rs2FromRs1, fi_rs2FromRs2, fi_rs2FromZero;

  // ---- 输入打平 → struct / 数组 ----
  assign rab_cv[0] = io_rabCommits_commitValid_0;
  assign rab_cv[1] = io_rabCommits_commitValid_1;
  assign rab_cv[2] = io_rabCommits_commitValid_2;
  assign rab_cv[3] = io_rabCommits_commitValid_3;
  assign rab_cv[4] = io_rabCommits_commitValid_4;
  assign rab_cv[5] = io_rabCommits_commitValid_5;
  assign rab_wv[0] = io_rabCommits_walkValid_0;
  assign rab_wv[1] = io_rabCommits_walkValid_1;
  assign rab_wv[2] = io_rabCommits_walkValid_2;
  assign rab_wv[3] = io_rabCommits_walkValid_3;
  assign rab_wv[4] = io_rabCommits_walkValid_4;
  assign rab_wv[5] = io_rabCommits_walkValid_5;
  assign rab_rf[0] = io_rabCommits_info_0_rfWen;
  assign rab_fp[0] = io_rabCommits_info_0_fpWen;
  assign rab_vec[0] = io_rabCommits_info_0_vecWen;
  assign rab_v0[0] = io_rabCommits_info_0_v0Wen;
  assign rab_vl[0] = io_rabCommits_info_0_vlWen;
  assign rab_mv[0] = io_rabCommits_info_0_isMove;
  assign rab_rf[1] = io_rabCommits_info_1_rfWen;
  assign rab_fp[1] = io_rabCommits_info_1_fpWen;
  assign rab_vec[1] = io_rabCommits_info_1_vecWen;
  assign rab_v0[1] = io_rabCommits_info_1_v0Wen;
  assign rab_vl[1] = io_rabCommits_info_1_vlWen;
  assign rab_mv[1] = io_rabCommits_info_1_isMove;
  assign rab_rf[2] = io_rabCommits_info_2_rfWen;
  assign rab_fp[2] = io_rabCommits_info_2_fpWen;
  assign rab_vec[2] = io_rabCommits_info_2_vecWen;
  assign rab_v0[2] = io_rabCommits_info_2_v0Wen;
  assign rab_vl[2] = io_rabCommits_info_2_vlWen;
  assign rab_mv[2] = io_rabCommits_info_2_isMove;
  assign rab_rf[3] = io_rabCommits_info_3_rfWen;
  assign rab_fp[3] = io_rabCommits_info_3_fpWen;
  assign rab_vec[3] = io_rabCommits_info_3_vecWen;
  assign rab_v0[3] = io_rabCommits_info_3_v0Wen;
  assign rab_vl[3] = io_rabCommits_info_3_vlWen;
  assign rab_mv[3] = io_rabCommits_info_3_isMove;
  assign rab_rf[4] = io_rabCommits_info_4_rfWen;
  assign rab_fp[4] = io_rabCommits_info_4_fpWen;
  assign rab_vec[4] = io_rabCommits_info_4_vecWen;
  assign rab_v0[4] = io_rabCommits_info_4_v0Wen;
  assign rab_vl[4] = io_rabCommits_info_4_vlWen;
  assign rab_mv[4] = io_rabCommits_info_4_isMove;
  assign rab_rf[5] = io_rabCommits_info_5_rfWen;
  assign rab_fp[5] = io_rabCommits_info_5_fpWen;
  assign rab_vec[5] = io_rabCommits_info_5_vecWen;
  assign rab_v0[5] = io_rabCommits_info_5_v0Wen;
  assign rab_vl[5] = io_rabCommits_info_5_vlWen;
  assign rab_mv[5] = io_rabCommits_info_5_isMove;
  assign in_v[0] = io_in_0_valid;
  assign in_b[0].instr = io_in_0_bits_instr;
  assign in_b[0].pc = io_in_0_bits_pc;
  assign in_b[0].foldpc = io_in_0_bits_foldpc;
  assign in_b[0].exceptionVec[0] = io_in_0_bits_exceptionVec_0;
  assign in_b[0].exceptionVec[1] = io_in_0_bits_exceptionVec_1;
  assign in_b[0].exceptionVec[2] = io_in_0_bits_exceptionVec_2;
  assign in_b[0].exceptionVec[3] = io_in_0_bits_exceptionVec_3;
  assign in_b[0].exceptionVec[4] = io_in_0_bits_exceptionVec_4;
  assign in_b[0].exceptionVec[5] = io_in_0_bits_exceptionVec_5;
  assign in_b[0].exceptionVec[6] = io_in_0_bits_exceptionVec_6;
  assign in_b[0].exceptionVec[7] = io_in_0_bits_exceptionVec_7;
  assign in_b[0].exceptionVec[8] = io_in_0_bits_exceptionVec_8;
  assign in_b[0].exceptionVec[9] = io_in_0_bits_exceptionVec_9;
  assign in_b[0].exceptionVec[10] = io_in_0_bits_exceptionVec_10;
  assign in_b[0].exceptionVec[11] = io_in_0_bits_exceptionVec_11;
  assign in_b[0].exceptionVec[12] = io_in_0_bits_exceptionVec_12;
  assign in_b[0].exceptionVec[13] = io_in_0_bits_exceptionVec_13;
  assign in_b[0].exceptionVec[14] = io_in_0_bits_exceptionVec_14;
  assign in_b[0].exceptionVec[15] = io_in_0_bits_exceptionVec_15;
  assign in_b[0].exceptionVec[16] = io_in_0_bits_exceptionVec_16;
  assign in_b[0].exceptionVec[17] = io_in_0_bits_exceptionVec_17;
  assign in_b[0].exceptionVec[18] = io_in_0_bits_exceptionVec_18;
  assign in_b[0].exceptionVec[19] = io_in_0_bits_exceptionVec_19;
  assign in_b[0].exceptionVec[20] = io_in_0_bits_exceptionVec_20;
  assign in_b[0].exceptionVec[21] = io_in_0_bits_exceptionVec_21;
  assign in_b[0].exceptionVec[22] = io_in_0_bits_exceptionVec_22;
  assign in_b[0].exceptionVec[23] = io_in_0_bits_exceptionVec_23;
  assign in_b[0].isFetchMalAddr = io_in_0_bits_isFetchMalAddr;
  assign in_b[0].trigger = io_in_0_bits_trigger;
  assign in_b[0].preDecodeInfo_valid = io_in_0_bits_preDecodeInfo_valid;
  assign in_b[0].preDecodeInfo_isRVC = io_in_0_bits_preDecodeInfo_isRVC;
  assign in_b[0].preDecodeInfo_brType = io_in_0_bits_preDecodeInfo_brType;
  assign in_b[0].preDecodeInfo_isCall = io_in_0_bits_preDecodeInfo_isCall;
  assign in_b[0].preDecodeInfo_isRet = io_in_0_bits_preDecodeInfo_isRet;
  assign in_b[0].pred_taken = io_in_0_bits_pred_taken;
  assign in_b[0].crossPageIPFFix = io_in_0_bits_crossPageIPFFix;
  assign in_b[0].ftqPtr_flag = io_in_0_bits_ftqPtr_flag;
  assign in_b[0].ftqPtr_value = io_in_0_bits_ftqPtr_value;
  assign in_b[0].ftqOffset = io_in_0_bits_ftqOffset;
  assign in_b[0].satpFlushFirstFetchFault = io_in_0_bits_satpFlushFirstFetchFault;
  assign in_b[0].srcType[0] = io_in_0_bits_srcType_0;
  assign in_b[0].srcType[1] = io_in_0_bits_srcType_1;
  assign in_b[0].srcType[2] = io_in_0_bits_srcType_2;
  assign in_b[0].srcType[3] = io_in_0_bits_srcType_3;
  assign in_b[0].srcType[4] = io_in_0_bits_srcType_4;
  assign in_b[0].lsrc[0] = io_in_0_bits_lsrc_0;
  assign in_b[0].lsrc[1] = io_in_0_bits_lsrc_1;
  assign in_b[0].ldest = io_in_0_bits_ldest;
  assign in_b[0].fuType = io_in_0_bits_fuType;
  assign in_b[0].fuOpType = io_in_0_bits_fuOpType;
  assign in_b[0].rfWen = io_in_0_bits_rfWen;
  assign in_b[0].fpWen = io_in_0_bits_fpWen;
  assign in_b[0].vecWen = io_in_0_bits_vecWen;
  assign in_b[0].v0Wen = io_in_0_bits_v0Wen;
  assign in_b[0].vlWen = io_in_0_bits_vlWen;
  assign in_b[0].isXSTrap = io_in_0_bits_isXSTrap;
  assign in_b[0].waitForward = io_in_0_bits_waitForward;
  assign in_b[0].blockBackward = io_in_0_bits_blockBackward;
  assign in_b[0].flushPipe = io_in_0_bits_flushPipe;
  assign in_b[0].canRobCompress = io_in_0_bits_canRobCompress;
  assign in_b[0].selImm = io_in_0_bits_selImm;
  assign in_b[0].imm = io_in_0_bits_imm;
  assign in_b[0].fpu_typeTagOut = io_in_0_bits_fpu_typeTagOut;
  assign in_b[0].fpu_wflags = io_in_0_bits_fpu_wflags;
  assign in_b[0].fpu_typ = io_in_0_bits_fpu_typ;
  assign in_b[0].fpu_fmt = io_in_0_bits_fpu_fmt;
  assign in_b[0].fpu_rm = io_in_0_bits_fpu_rm;
  assign in_b[0].vpu_vill = io_in_0_bits_vpu_vill;
  assign in_b[0].vpu_vma = io_in_0_bits_vpu_vma;
  assign in_b[0].vpu_vta = io_in_0_bits_vpu_vta;
  assign in_b[0].vpu_vsew = io_in_0_bits_vpu_vsew;
  assign in_b[0].vpu_vlmul = io_in_0_bits_vpu_vlmul;
  assign in_b[0].vpu_specVill = io_in_0_bits_vpu_specVill;
  assign in_b[0].vpu_specVma = io_in_0_bits_vpu_specVma;
  assign in_b[0].vpu_specVta = io_in_0_bits_vpu_specVta;
  assign in_b[0].vpu_specVsew = io_in_0_bits_vpu_specVsew;
  assign in_b[0].vpu_specVlmul = io_in_0_bits_vpu_specVlmul;
  assign in_b[0].vpu_vm = io_in_0_bits_vpu_vm;
  assign in_b[0].vpu_vstart = io_in_0_bits_vpu_vstart;
  assign in_b[0].vpu_frm = io_in_0_bits_vpu_frm;
  assign in_b[0].vpu_fpu_isFpToVecInst = io_in_0_bits_vpu_fpu_isFpToVecInst;
  assign in_b[0].vpu_fpu_isFP32Instr = io_in_0_bits_vpu_fpu_isFP32Instr;
  assign in_b[0].vpu_fpu_isFP64Instr = io_in_0_bits_vpu_fpu_isFP64Instr;
  assign in_b[0].vpu_fpu_isReduction = io_in_0_bits_vpu_fpu_isReduction;
  assign in_b[0].vpu_fpu_isFoldTo1_2 = io_in_0_bits_vpu_fpu_isFoldTo1_2;
  assign in_b[0].vpu_fpu_isFoldTo1_4 = io_in_0_bits_vpu_fpu_isFoldTo1_4;
  assign in_b[0].vpu_fpu_isFoldTo1_8 = io_in_0_bits_vpu_fpu_isFoldTo1_8;
  assign in_b[0].vpu_vxrm = io_in_0_bits_vpu_vxrm;
  assign in_b[0].vpu_vuopIdx = io_in_0_bits_vpu_vuopIdx;
  assign in_b[0].vpu_lastUop = io_in_0_bits_vpu_lastUop;
  assign in_b[0].vpu_vmask = io_in_0_bits_vpu_vmask;
  assign in_b[0].vpu_vl = io_in_0_bits_vpu_vl;
  assign in_b[0].vpu_nf = io_in_0_bits_vpu_nf;
  assign in_b[0].vpu_veew = io_in_0_bits_vpu_veew;
  assign in_b[0].vpu_isReverse = io_in_0_bits_vpu_isReverse;
  assign in_b[0].vpu_isExt = io_in_0_bits_vpu_isExt;
  assign in_b[0].vpu_isNarrow = io_in_0_bits_vpu_isNarrow;
  assign in_b[0].vpu_isDstMask = io_in_0_bits_vpu_isDstMask;
  assign in_b[0].vpu_isOpMask = io_in_0_bits_vpu_isOpMask;
  assign in_b[0].vpu_isMove = io_in_0_bits_vpu_isMove;
  assign in_b[0].vpu_isDependOldVd = io_in_0_bits_vpu_isDependOldVd;
  assign in_b[0].vpu_isWritePartVd = io_in_0_bits_vpu_isWritePartVd;
  assign in_b[0].vpu_isVleff = io_in_0_bits_vpu_isVleff;
  assign in_b[0].vlsInstr = io_in_0_bits_vlsInstr;
  assign in_b[0].wfflags = io_in_0_bits_wfflags;
  assign in_b[0].isMove = io_in_0_bits_isMove;
  assign in_b[0].uopIdx = io_in_0_bits_uopIdx;
  assign in_b[0].uopSplitType = io_in_0_bits_uopSplitType;
  assign in_b[0].isVset = io_in_0_bits_isVset;
  assign in_b[0].firstUop = io_in_0_bits_firstUop;
  assign in_b[0].lastUop = io_in_0_bits_lastUop;
  assign in_b[0].numUops = io_in_0_bits_numUops;
  assign in_b[0].numWB = io_in_0_bits_numWB;
  assign in_b[0].commitType = io_in_0_bits_commitType;
  assign in_b[0].debug_fuType = io_in_0_bits_debug_fuType;
  assign in_b[0].debug_seqNum_seqNum = io_in_0_bits_debug_seqNum_seqNum;
  assign in_b[0].debug_seqNum_uopIdx = io_in_0_bits_debug_seqNum_uopIdx;
  assign in_v[1] = io_in_1_valid;
  assign in_b[1].instr = io_in_1_bits_instr;
  assign in_b[1].pc = io_in_1_bits_pc;
  assign in_b[1].foldpc = io_in_1_bits_foldpc;
  assign in_b[1].exceptionVec[0] = io_in_1_bits_exceptionVec_0;
  assign in_b[1].exceptionVec[1] = io_in_1_bits_exceptionVec_1;
  assign in_b[1].exceptionVec[2] = io_in_1_bits_exceptionVec_2;
  assign in_b[1].exceptionVec[3] = io_in_1_bits_exceptionVec_3;
  assign in_b[1].exceptionVec[4] = io_in_1_bits_exceptionVec_4;
  assign in_b[1].exceptionVec[5] = io_in_1_bits_exceptionVec_5;
  assign in_b[1].exceptionVec[6] = io_in_1_bits_exceptionVec_6;
  assign in_b[1].exceptionVec[7] = io_in_1_bits_exceptionVec_7;
  assign in_b[1].exceptionVec[8] = io_in_1_bits_exceptionVec_8;
  assign in_b[1].exceptionVec[9] = io_in_1_bits_exceptionVec_9;
  assign in_b[1].exceptionVec[10] = io_in_1_bits_exceptionVec_10;
  assign in_b[1].exceptionVec[11] = io_in_1_bits_exceptionVec_11;
  assign in_b[1].exceptionVec[12] = io_in_1_bits_exceptionVec_12;
  assign in_b[1].exceptionVec[13] = io_in_1_bits_exceptionVec_13;
  assign in_b[1].exceptionVec[14] = io_in_1_bits_exceptionVec_14;
  assign in_b[1].exceptionVec[15] = io_in_1_bits_exceptionVec_15;
  assign in_b[1].exceptionVec[16] = io_in_1_bits_exceptionVec_16;
  assign in_b[1].exceptionVec[17] = io_in_1_bits_exceptionVec_17;
  assign in_b[1].exceptionVec[18] = io_in_1_bits_exceptionVec_18;
  assign in_b[1].exceptionVec[19] = io_in_1_bits_exceptionVec_19;
  assign in_b[1].exceptionVec[20] = io_in_1_bits_exceptionVec_20;
  assign in_b[1].exceptionVec[21] = io_in_1_bits_exceptionVec_21;
  assign in_b[1].exceptionVec[22] = io_in_1_bits_exceptionVec_22;
  assign in_b[1].exceptionVec[23] = io_in_1_bits_exceptionVec_23;
  assign in_b[1].isFetchMalAddr = io_in_1_bits_isFetchMalAddr;
  assign in_b[1].trigger = io_in_1_bits_trigger;
  assign in_b[1].preDecodeInfo_valid = io_in_1_bits_preDecodeInfo_valid;
  assign in_b[1].preDecodeInfo_isRVC = io_in_1_bits_preDecodeInfo_isRVC;
  assign in_b[1].preDecodeInfo_brType = io_in_1_bits_preDecodeInfo_brType;
  assign in_b[1].preDecodeInfo_isCall = io_in_1_bits_preDecodeInfo_isCall;
  assign in_b[1].preDecodeInfo_isRet = io_in_1_bits_preDecodeInfo_isRet;
  assign in_b[1].pred_taken = io_in_1_bits_pred_taken;
  assign in_b[1].crossPageIPFFix = io_in_1_bits_crossPageIPFFix;
  assign in_b[1].ftqPtr_flag = io_in_1_bits_ftqPtr_flag;
  assign in_b[1].ftqPtr_value = io_in_1_bits_ftqPtr_value;
  assign in_b[1].ftqOffset = io_in_1_bits_ftqOffset;
  assign in_b[1].satpFlushFirstFetchFault = io_in_1_bits_satpFlushFirstFetchFault;
  assign in_b[1].srcType[0] = io_in_1_bits_srcType_0;
  assign in_b[1].srcType[1] = io_in_1_bits_srcType_1;
  assign in_b[1].srcType[2] = io_in_1_bits_srcType_2;
  assign in_b[1].srcType[3] = io_in_1_bits_srcType_3;
  assign in_b[1].srcType[4] = io_in_1_bits_srcType_4;
  assign in_b[1].lsrc[0] = io_in_1_bits_lsrc_0;
  assign in_b[1].lsrc[1] = io_in_1_bits_lsrc_1;
  assign in_b[1].lsrc[2] = io_in_1_bits_lsrc_2;
  assign in_b[1].lsrc[3] = io_in_1_bits_lsrc_3;
  assign in_b[1].lsrc[4] = io_in_1_bits_lsrc_4;
  assign in_b[1].ldest = io_in_1_bits_ldest;
  assign in_b[1].fuType = io_in_1_bits_fuType;
  assign in_b[1].fuOpType = io_in_1_bits_fuOpType;
  assign in_b[1].rfWen = io_in_1_bits_rfWen;
  assign in_b[1].fpWen = io_in_1_bits_fpWen;
  assign in_b[1].vecWen = io_in_1_bits_vecWen;
  assign in_b[1].v0Wen = io_in_1_bits_v0Wen;
  assign in_b[1].vlWen = io_in_1_bits_vlWen;
  assign in_b[1].isXSTrap = io_in_1_bits_isXSTrap;
  assign in_b[1].waitForward = io_in_1_bits_waitForward;
  assign in_b[1].blockBackward = io_in_1_bits_blockBackward;
  assign in_b[1].flushPipe = io_in_1_bits_flushPipe;
  assign in_b[1].canRobCompress = io_in_1_bits_canRobCompress;
  assign in_b[1].selImm = io_in_1_bits_selImm;
  assign in_b[1].imm = io_in_1_bits_imm;
  assign in_b[1].fpu_typeTagOut = io_in_1_bits_fpu_typeTagOut;
  assign in_b[1].fpu_wflags = io_in_1_bits_fpu_wflags;
  assign in_b[1].fpu_typ = io_in_1_bits_fpu_typ;
  assign in_b[1].fpu_fmt = io_in_1_bits_fpu_fmt;
  assign in_b[1].fpu_rm = io_in_1_bits_fpu_rm;
  assign in_b[1].vpu_vill = io_in_1_bits_vpu_vill;
  assign in_b[1].vpu_vma = io_in_1_bits_vpu_vma;
  assign in_b[1].vpu_vta = io_in_1_bits_vpu_vta;
  assign in_b[1].vpu_vsew = io_in_1_bits_vpu_vsew;
  assign in_b[1].vpu_vlmul = io_in_1_bits_vpu_vlmul;
  assign in_b[1].vpu_specVill = io_in_1_bits_vpu_specVill;
  assign in_b[1].vpu_specVma = io_in_1_bits_vpu_specVma;
  assign in_b[1].vpu_specVta = io_in_1_bits_vpu_specVta;
  assign in_b[1].vpu_specVsew = io_in_1_bits_vpu_specVsew;
  assign in_b[1].vpu_specVlmul = io_in_1_bits_vpu_specVlmul;
  assign in_b[1].vpu_vm = io_in_1_bits_vpu_vm;
  assign in_b[1].vpu_vstart = io_in_1_bits_vpu_vstart;
  assign in_b[1].vpu_frm = io_in_1_bits_vpu_frm;
  assign in_b[1].vpu_fpu_isFpToVecInst = io_in_1_bits_vpu_fpu_isFpToVecInst;
  assign in_b[1].vpu_fpu_isFP32Instr = io_in_1_bits_vpu_fpu_isFP32Instr;
  assign in_b[1].vpu_fpu_isFP64Instr = io_in_1_bits_vpu_fpu_isFP64Instr;
  assign in_b[1].vpu_fpu_isReduction = io_in_1_bits_vpu_fpu_isReduction;
  assign in_b[1].vpu_fpu_isFoldTo1_2 = io_in_1_bits_vpu_fpu_isFoldTo1_2;
  assign in_b[1].vpu_fpu_isFoldTo1_4 = io_in_1_bits_vpu_fpu_isFoldTo1_4;
  assign in_b[1].vpu_fpu_isFoldTo1_8 = io_in_1_bits_vpu_fpu_isFoldTo1_8;
  assign in_b[1].vpu_vxrm = io_in_1_bits_vpu_vxrm;
  assign in_b[1].vpu_vuopIdx = io_in_1_bits_vpu_vuopIdx;
  assign in_b[1].vpu_lastUop = io_in_1_bits_vpu_lastUop;
  assign in_b[1].vpu_vmask = io_in_1_bits_vpu_vmask;
  assign in_b[1].vpu_vl = io_in_1_bits_vpu_vl;
  assign in_b[1].vpu_nf = io_in_1_bits_vpu_nf;
  assign in_b[1].vpu_veew = io_in_1_bits_vpu_veew;
  assign in_b[1].vpu_isReverse = io_in_1_bits_vpu_isReverse;
  assign in_b[1].vpu_isExt = io_in_1_bits_vpu_isExt;
  assign in_b[1].vpu_isNarrow = io_in_1_bits_vpu_isNarrow;
  assign in_b[1].vpu_isDstMask = io_in_1_bits_vpu_isDstMask;
  assign in_b[1].vpu_isOpMask = io_in_1_bits_vpu_isOpMask;
  assign in_b[1].vpu_isMove = io_in_1_bits_vpu_isMove;
  assign in_b[1].vpu_isDependOldVd = io_in_1_bits_vpu_isDependOldVd;
  assign in_b[1].vpu_isWritePartVd = io_in_1_bits_vpu_isWritePartVd;
  assign in_b[1].vpu_isVleff = io_in_1_bits_vpu_isVleff;
  assign in_b[1].vlsInstr = io_in_1_bits_vlsInstr;
  assign in_b[1].wfflags = io_in_1_bits_wfflags;
  assign in_b[1].isMove = io_in_1_bits_isMove;
  assign in_b[1].uopIdx = io_in_1_bits_uopIdx;
  assign in_b[1].uopSplitType = io_in_1_bits_uopSplitType;
  assign in_b[1].isVset = io_in_1_bits_isVset;
  assign in_b[1].firstUop = io_in_1_bits_firstUop;
  assign in_b[1].lastUop = io_in_1_bits_lastUop;
  assign in_b[1].numUops = io_in_1_bits_numUops;
  assign in_b[1].numWB = io_in_1_bits_numWB;
  assign in_b[1].commitType = io_in_1_bits_commitType;
  assign in_b[1].debug_fuType = io_in_1_bits_debug_fuType;
  assign in_b[1].debug_seqNum_seqNum = io_in_1_bits_debug_seqNum_seqNum;
  assign in_b[1].debug_seqNum_uopIdx = io_in_1_bits_debug_seqNum_uopIdx;
  assign in_v[2] = io_in_2_valid;
  assign in_b[2].instr = io_in_2_bits_instr;
  assign in_b[2].pc = io_in_2_bits_pc;
  assign in_b[2].foldpc = io_in_2_bits_foldpc;
  assign in_b[2].exceptionVec[0] = io_in_2_bits_exceptionVec_0;
  assign in_b[2].exceptionVec[1] = io_in_2_bits_exceptionVec_1;
  assign in_b[2].exceptionVec[2] = io_in_2_bits_exceptionVec_2;
  assign in_b[2].exceptionVec[3] = io_in_2_bits_exceptionVec_3;
  assign in_b[2].exceptionVec[4] = io_in_2_bits_exceptionVec_4;
  assign in_b[2].exceptionVec[5] = io_in_2_bits_exceptionVec_5;
  assign in_b[2].exceptionVec[6] = io_in_2_bits_exceptionVec_6;
  assign in_b[2].exceptionVec[7] = io_in_2_bits_exceptionVec_7;
  assign in_b[2].exceptionVec[8] = io_in_2_bits_exceptionVec_8;
  assign in_b[2].exceptionVec[9] = io_in_2_bits_exceptionVec_9;
  assign in_b[2].exceptionVec[10] = io_in_2_bits_exceptionVec_10;
  assign in_b[2].exceptionVec[11] = io_in_2_bits_exceptionVec_11;
  assign in_b[2].exceptionVec[12] = io_in_2_bits_exceptionVec_12;
  assign in_b[2].exceptionVec[13] = io_in_2_bits_exceptionVec_13;
  assign in_b[2].exceptionVec[14] = io_in_2_bits_exceptionVec_14;
  assign in_b[2].exceptionVec[15] = io_in_2_bits_exceptionVec_15;
  assign in_b[2].exceptionVec[16] = io_in_2_bits_exceptionVec_16;
  assign in_b[2].exceptionVec[17] = io_in_2_bits_exceptionVec_17;
  assign in_b[2].exceptionVec[18] = io_in_2_bits_exceptionVec_18;
  assign in_b[2].exceptionVec[19] = io_in_2_bits_exceptionVec_19;
  assign in_b[2].exceptionVec[20] = io_in_2_bits_exceptionVec_20;
  assign in_b[2].exceptionVec[21] = io_in_2_bits_exceptionVec_21;
  assign in_b[2].exceptionVec[22] = io_in_2_bits_exceptionVec_22;
  assign in_b[2].exceptionVec[23] = io_in_2_bits_exceptionVec_23;
  assign in_b[2].isFetchMalAddr = io_in_2_bits_isFetchMalAddr;
  assign in_b[2].trigger = io_in_2_bits_trigger;
  assign in_b[2].preDecodeInfo_valid = io_in_2_bits_preDecodeInfo_valid;
  assign in_b[2].preDecodeInfo_isRVC = io_in_2_bits_preDecodeInfo_isRVC;
  assign in_b[2].preDecodeInfo_brType = io_in_2_bits_preDecodeInfo_brType;
  assign in_b[2].preDecodeInfo_isCall = io_in_2_bits_preDecodeInfo_isCall;
  assign in_b[2].preDecodeInfo_isRet = io_in_2_bits_preDecodeInfo_isRet;
  assign in_b[2].pred_taken = io_in_2_bits_pred_taken;
  assign in_b[2].crossPageIPFFix = io_in_2_bits_crossPageIPFFix;
  assign in_b[2].ftqPtr_flag = io_in_2_bits_ftqPtr_flag;
  assign in_b[2].ftqPtr_value = io_in_2_bits_ftqPtr_value;
  assign in_b[2].ftqOffset = io_in_2_bits_ftqOffset;
  assign in_b[2].satpFlushFirstFetchFault = io_in_2_bits_satpFlushFirstFetchFault;
  assign in_b[2].srcType[0] = io_in_2_bits_srcType_0;
  assign in_b[2].srcType[1] = io_in_2_bits_srcType_1;
  assign in_b[2].srcType[2] = io_in_2_bits_srcType_2;
  assign in_b[2].srcType[3] = io_in_2_bits_srcType_3;
  assign in_b[2].srcType[4] = io_in_2_bits_srcType_4;
  assign in_b[2].lsrc[0] = io_in_2_bits_lsrc_0;
  assign in_b[2].lsrc[1] = io_in_2_bits_lsrc_1;
  assign in_b[2].lsrc[2] = io_in_2_bits_lsrc_2;
  assign in_b[2].lsrc[3] = io_in_2_bits_lsrc_3;
  assign in_b[2].lsrc[4] = io_in_2_bits_lsrc_4;
  assign in_b[2].ldest = io_in_2_bits_ldest;
  assign in_b[2].fuType = io_in_2_bits_fuType;
  assign in_b[2].fuOpType = io_in_2_bits_fuOpType;
  assign in_b[2].rfWen = io_in_2_bits_rfWen;
  assign in_b[2].fpWen = io_in_2_bits_fpWen;
  assign in_b[2].vecWen = io_in_2_bits_vecWen;
  assign in_b[2].v0Wen = io_in_2_bits_v0Wen;
  assign in_b[2].vlWen = io_in_2_bits_vlWen;
  assign in_b[2].isXSTrap = io_in_2_bits_isXSTrap;
  assign in_b[2].waitForward = io_in_2_bits_waitForward;
  assign in_b[2].blockBackward = io_in_2_bits_blockBackward;
  assign in_b[2].flushPipe = io_in_2_bits_flushPipe;
  assign in_b[2].canRobCompress = io_in_2_bits_canRobCompress;
  assign in_b[2].selImm = io_in_2_bits_selImm;
  assign in_b[2].imm = io_in_2_bits_imm;
  assign in_b[2].fpu_typeTagOut = io_in_2_bits_fpu_typeTagOut;
  assign in_b[2].fpu_wflags = io_in_2_bits_fpu_wflags;
  assign in_b[2].fpu_typ = io_in_2_bits_fpu_typ;
  assign in_b[2].fpu_fmt = io_in_2_bits_fpu_fmt;
  assign in_b[2].fpu_rm = io_in_2_bits_fpu_rm;
  assign in_b[2].vpu_vill = io_in_2_bits_vpu_vill;
  assign in_b[2].vpu_vma = io_in_2_bits_vpu_vma;
  assign in_b[2].vpu_vta = io_in_2_bits_vpu_vta;
  assign in_b[2].vpu_vsew = io_in_2_bits_vpu_vsew;
  assign in_b[2].vpu_vlmul = io_in_2_bits_vpu_vlmul;
  assign in_b[2].vpu_specVill = io_in_2_bits_vpu_specVill;
  assign in_b[2].vpu_specVma = io_in_2_bits_vpu_specVma;
  assign in_b[2].vpu_specVta = io_in_2_bits_vpu_specVta;
  assign in_b[2].vpu_specVsew = io_in_2_bits_vpu_specVsew;
  assign in_b[2].vpu_specVlmul = io_in_2_bits_vpu_specVlmul;
  assign in_b[2].vpu_vm = io_in_2_bits_vpu_vm;
  assign in_b[2].vpu_vstart = io_in_2_bits_vpu_vstart;
  assign in_b[2].vpu_frm = io_in_2_bits_vpu_frm;
  assign in_b[2].vpu_fpu_isFpToVecInst = io_in_2_bits_vpu_fpu_isFpToVecInst;
  assign in_b[2].vpu_fpu_isFP32Instr = io_in_2_bits_vpu_fpu_isFP32Instr;
  assign in_b[2].vpu_fpu_isFP64Instr = io_in_2_bits_vpu_fpu_isFP64Instr;
  assign in_b[2].vpu_fpu_isReduction = io_in_2_bits_vpu_fpu_isReduction;
  assign in_b[2].vpu_fpu_isFoldTo1_2 = io_in_2_bits_vpu_fpu_isFoldTo1_2;
  assign in_b[2].vpu_fpu_isFoldTo1_4 = io_in_2_bits_vpu_fpu_isFoldTo1_4;
  assign in_b[2].vpu_fpu_isFoldTo1_8 = io_in_2_bits_vpu_fpu_isFoldTo1_8;
  assign in_b[2].vpu_vxrm = io_in_2_bits_vpu_vxrm;
  assign in_b[2].vpu_vuopIdx = io_in_2_bits_vpu_vuopIdx;
  assign in_b[2].vpu_lastUop = io_in_2_bits_vpu_lastUop;
  assign in_b[2].vpu_vmask = io_in_2_bits_vpu_vmask;
  assign in_b[2].vpu_vl = io_in_2_bits_vpu_vl;
  assign in_b[2].vpu_nf = io_in_2_bits_vpu_nf;
  assign in_b[2].vpu_veew = io_in_2_bits_vpu_veew;
  assign in_b[2].vpu_isReverse = io_in_2_bits_vpu_isReverse;
  assign in_b[2].vpu_isExt = io_in_2_bits_vpu_isExt;
  assign in_b[2].vpu_isNarrow = io_in_2_bits_vpu_isNarrow;
  assign in_b[2].vpu_isDstMask = io_in_2_bits_vpu_isDstMask;
  assign in_b[2].vpu_isOpMask = io_in_2_bits_vpu_isOpMask;
  assign in_b[2].vpu_isMove = io_in_2_bits_vpu_isMove;
  assign in_b[2].vpu_isDependOldVd = io_in_2_bits_vpu_isDependOldVd;
  assign in_b[2].vpu_isWritePartVd = io_in_2_bits_vpu_isWritePartVd;
  assign in_b[2].vpu_isVleff = io_in_2_bits_vpu_isVleff;
  assign in_b[2].vlsInstr = io_in_2_bits_vlsInstr;
  assign in_b[2].wfflags = io_in_2_bits_wfflags;
  assign in_b[2].isMove = io_in_2_bits_isMove;
  assign in_b[2].uopIdx = io_in_2_bits_uopIdx;
  assign in_b[2].uopSplitType = io_in_2_bits_uopSplitType;
  assign in_b[2].isVset = io_in_2_bits_isVset;
  assign in_b[2].firstUop = io_in_2_bits_firstUop;
  assign in_b[2].lastUop = io_in_2_bits_lastUop;
  assign in_b[2].numUops = io_in_2_bits_numUops;
  assign in_b[2].numWB = io_in_2_bits_numWB;
  assign in_b[2].commitType = io_in_2_bits_commitType;
  assign in_b[2].debug_fuType = io_in_2_bits_debug_fuType;
  assign in_b[2].debug_seqNum_seqNum = io_in_2_bits_debug_seqNum_seqNum;
  assign in_b[2].debug_seqNum_uopIdx = io_in_2_bits_debug_seqNum_uopIdx;
  assign in_v[3] = io_in_3_valid;
  assign in_b[3].instr = io_in_3_bits_instr;
  assign in_b[3].pc = io_in_3_bits_pc;
  assign in_b[3].foldpc = io_in_3_bits_foldpc;
  assign in_b[3].exceptionVec[0] = io_in_3_bits_exceptionVec_0;
  assign in_b[3].exceptionVec[1] = io_in_3_bits_exceptionVec_1;
  assign in_b[3].exceptionVec[2] = io_in_3_bits_exceptionVec_2;
  assign in_b[3].exceptionVec[3] = io_in_3_bits_exceptionVec_3;
  assign in_b[3].exceptionVec[4] = io_in_3_bits_exceptionVec_4;
  assign in_b[3].exceptionVec[5] = io_in_3_bits_exceptionVec_5;
  assign in_b[3].exceptionVec[6] = io_in_3_bits_exceptionVec_6;
  assign in_b[3].exceptionVec[7] = io_in_3_bits_exceptionVec_7;
  assign in_b[3].exceptionVec[8] = io_in_3_bits_exceptionVec_8;
  assign in_b[3].exceptionVec[9] = io_in_3_bits_exceptionVec_9;
  assign in_b[3].exceptionVec[10] = io_in_3_bits_exceptionVec_10;
  assign in_b[3].exceptionVec[11] = io_in_3_bits_exceptionVec_11;
  assign in_b[3].exceptionVec[12] = io_in_3_bits_exceptionVec_12;
  assign in_b[3].exceptionVec[13] = io_in_3_bits_exceptionVec_13;
  assign in_b[3].exceptionVec[14] = io_in_3_bits_exceptionVec_14;
  assign in_b[3].exceptionVec[15] = io_in_3_bits_exceptionVec_15;
  assign in_b[3].exceptionVec[16] = io_in_3_bits_exceptionVec_16;
  assign in_b[3].exceptionVec[17] = io_in_3_bits_exceptionVec_17;
  assign in_b[3].exceptionVec[18] = io_in_3_bits_exceptionVec_18;
  assign in_b[3].exceptionVec[19] = io_in_3_bits_exceptionVec_19;
  assign in_b[3].exceptionVec[20] = io_in_3_bits_exceptionVec_20;
  assign in_b[3].exceptionVec[21] = io_in_3_bits_exceptionVec_21;
  assign in_b[3].exceptionVec[22] = io_in_3_bits_exceptionVec_22;
  assign in_b[3].exceptionVec[23] = io_in_3_bits_exceptionVec_23;
  assign in_b[3].isFetchMalAddr = io_in_3_bits_isFetchMalAddr;
  assign in_b[3].trigger = io_in_3_bits_trigger;
  assign in_b[3].preDecodeInfo_valid = io_in_3_bits_preDecodeInfo_valid;
  assign in_b[3].preDecodeInfo_isRVC = io_in_3_bits_preDecodeInfo_isRVC;
  assign in_b[3].preDecodeInfo_brType = io_in_3_bits_preDecodeInfo_brType;
  assign in_b[3].preDecodeInfo_isCall = io_in_3_bits_preDecodeInfo_isCall;
  assign in_b[3].preDecodeInfo_isRet = io_in_3_bits_preDecodeInfo_isRet;
  assign in_b[3].pred_taken = io_in_3_bits_pred_taken;
  assign in_b[3].crossPageIPFFix = io_in_3_bits_crossPageIPFFix;
  assign in_b[3].ftqPtr_flag = io_in_3_bits_ftqPtr_flag;
  assign in_b[3].ftqPtr_value = io_in_3_bits_ftqPtr_value;
  assign in_b[3].ftqOffset = io_in_3_bits_ftqOffset;
  assign in_b[3].satpFlushFirstFetchFault = io_in_3_bits_satpFlushFirstFetchFault;
  assign in_b[3].srcType[0] = io_in_3_bits_srcType_0;
  assign in_b[3].srcType[1] = io_in_3_bits_srcType_1;
  assign in_b[3].srcType[2] = io_in_3_bits_srcType_2;
  assign in_b[3].srcType[3] = io_in_3_bits_srcType_3;
  assign in_b[3].srcType[4] = io_in_3_bits_srcType_4;
  assign in_b[3].lsrc[0] = io_in_3_bits_lsrc_0;
  assign in_b[3].lsrc[1] = io_in_3_bits_lsrc_1;
  assign in_b[3].lsrc[2] = io_in_3_bits_lsrc_2;
  assign in_b[3].lsrc[3] = io_in_3_bits_lsrc_3;
  assign in_b[3].lsrc[4] = io_in_3_bits_lsrc_4;
  assign in_b[3].ldest = io_in_3_bits_ldest;
  assign in_b[3].fuType = io_in_3_bits_fuType;
  assign in_b[3].fuOpType = io_in_3_bits_fuOpType;
  assign in_b[3].rfWen = io_in_3_bits_rfWen;
  assign in_b[3].fpWen = io_in_3_bits_fpWen;
  assign in_b[3].vecWen = io_in_3_bits_vecWen;
  assign in_b[3].v0Wen = io_in_3_bits_v0Wen;
  assign in_b[3].vlWen = io_in_3_bits_vlWen;
  assign in_b[3].isXSTrap = io_in_3_bits_isXSTrap;
  assign in_b[3].waitForward = io_in_3_bits_waitForward;
  assign in_b[3].blockBackward = io_in_3_bits_blockBackward;
  assign in_b[3].flushPipe = io_in_3_bits_flushPipe;
  assign in_b[3].canRobCompress = io_in_3_bits_canRobCompress;
  assign in_b[3].selImm = io_in_3_bits_selImm;
  assign in_b[3].imm = io_in_3_bits_imm;
  assign in_b[3].fpu_typeTagOut = io_in_3_bits_fpu_typeTagOut;
  assign in_b[3].fpu_wflags = io_in_3_bits_fpu_wflags;
  assign in_b[3].fpu_typ = io_in_3_bits_fpu_typ;
  assign in_b[3].fpu_fmt = io_in_3_bits_fpu_fmt;
  assign in_b[3].fpu_rm = io_in_3_bits_fpu_rm;
  assign in_b[3].vpu_vill = io_in_3_bits_vpu_vill;
  assign in_b[3].vpu_vma = io_in_3_bits_vpu_vma;
  assign in_b[3].vpu_vta = io_in_3_bits_vpu_vta;
  assign in_b[3].vpu_vsew = io_in_3_bits_vpu_vsew;
  assign in_b[3].vpu_vlmul = io_in_3_bits_vpu_vlmul;
  assign in_b[3].vpu_specVill = io_in_3_bits_vpu_specVill;
  assign in_b[3].vpu_specVma = io_in_3_bits_vpu_specVma;
  assign in_b[3].vpu_specVta = io_in_3_bits_vpu_specVta;
  assign in_b[3].vpu_specVsew = io_in_3_bits_vpu_specVsew;
  assign in_b[3].vpu_specVlmul = io_in_3_bits_vpu_specVlmul;
  assign in_b[3].vpu_vm = io_in_3_bits_vpu_vm;
  assign in_b[3].vpu_vstart = io_in_3_bits_vpu_vstart;
  assign in_b[3].vpu_frm = io_in_3_bits_vpu_frm;
  assign in_b[3].vpu_fpu_isFpToVecInst = io_in_3_bits_vpu_fpu_isFpToVecInst;
  assign in_b[3].vpu_fpu_isFP32Instr = io_in_3_bits_vpu_fpu_isFP32Instr;
  assign in_b[3].vpu_fpu_isFP64Instr = io_in_3_bits_vpu_fpu_isFP64Instr;
  assign in_b[3].vpu_fpu_isReduction = io_in_3_bits_vpu_fpu_isReduction;
  assign in_b[3].vpu_fpu_isFoldTo1_2 = io_in_3_bits_vpu_fpu_isFoldTo1_2;
  assign in_b[3].vpu_fpu_isFoldTo1_4 = io_in_3_bits_vpu_fpu_isFoldTo1_4;
  assign in_b[3].vpu_fpu_isFoldTo1_8 = io_in_3_bits_vpu_fpu_isFoldTo1_8;
  assign in_b[3].vpu_vxrm = io_in_3_bits_vpu_vxrm;
  assign in_b[3].vpu_vuopIdx = io_in_3_bits_vpu_vuopIdx;
  assign in_b[3].vpu_lastUop = io_in_3_bits_vpu_lastUop;
  assign in_b[3].vpu_vmask = io_in_3_bits_vpu_vmask;
  assign in_b[3].vpu_vl = io_in_3_bits_vpu_vl;
  assign in_b[3].vpu_nf = io_in_3_bits_vpu_nf;
  assign in_b[3].vpu_veew = io_in_3_bits_vpu_veew;
  assign in_b[3].vpu_isReverse = io_in_3_bits_vpu_isReverse;
  assign in_b[3].vpu_isExt = io_in_3_bits_vpu_isExt;
  assign in_b[3].vpu_isNarrow = io_in_3_bits_vpu_isNarrow;
  assign in_b[3].vpu_isDstMask = io_in_3_bits_vpu_isDstMask;
  assign in_b[3].vpu_isOpMask = io_in_3_bits_vpu_isOpMask;
  assign in_b[3].vpu_isMove = io_in_3_bits_vpu_isMove;
  assign in_b[3].vpu_isDependOldVd = io_in_3_bits_vpu_isDependOldVd;
  assign in_b[3].vpu_isWritePartVd = io_in_3_bits_vpu_isWritePartVd;
  assign in_b[3].vpu_isVleff = io_in_3_bits_vpu_isVleff;
  assign in_b[3].vlsInstr = io_in_3_bits_vlsInstr;
  assign in_b[3].wfflags = io_in_3_bits_wfflags;
  assign in_b[3].isMove = io_in_3_bits_isMove;
  assign in_b[3].uopIdx = io_in_3_bits_uopIdx;
  assign in_b[3].uopSplitType = io_in_3_bits_uopSplitType;
  assign in_b[3].isVset = io_in_3_bits_isVset;
  assign in_b[3].firstUop = io_in_3_bits_firstUop;
  assign in_b[3].lastUop = io_in_3_bits_lastUop;
  assign in_b[3].numUops = io_in_3_bits_numUops;
  assign in_b[3].numWB = io_in_3_bits_numWB;
  assign in_b[3].commitType = io_in_3_bits_commitType;
  assign in_b[3].debug_fuType = io_in_3_bits_debug_fuType;
  assign in_b[3].debug_seqNum_seqNum = io_in_3_bits_debug_seqNum_seqNum;
  assign in_b[3].debug_seqNum_uopIdx = io_in_3_bits_debug_seqNum_uopIdx;
  assign in_v[4] = io_in_4_valid;
  assign in_b[4].instr = io_in_4_bits_instr;
  assign in_b[4].pc = io_in_4_bits_pc;
  assign in_b[4].foldpc = io_in_4_bits_foldpc;
  assign in_b[4].exceptionVec[0] = io_in_4_bits_exceptionVec_0;
  assign in_b[4].exceptionVec[1] = io_in_4_bits_exceptionVec_1;
  assign in_b[4].exceptionVec[2] = io_in_4_bits_exceptionVec_2;
  assign in_b[4].exceptionVec[3] = io_in_4_bits_exceptionVec_3;
  assign in_b[4].exceptionVec[4] = io_in_4_bits_exceptionVec_4;
  assign in_b[4].exceptionVec[5] = io_in_4_bits_exceptionVec_5;
  assign in_b[4].exceptionVec[6] = io_in_4_bits_exceptionVec_6;
  assign in_b[4].exceptionVec[7] = io_in_4_bits_exceptionVec_7;
  assign in_b[4].exceptionVec[8] = io_in_4_bits_exceptionVec_8;
  assign in_b[4].exceptionVec[9] = io_in_4_bits_exceptionVec_9;
  assign in_b[4].exceptionVec[10] = io_in_4_bits_exceptionVec_10;
  assign in_b[4].exceptionVec[11] = io_in_4_bits_exceptionVec_11;
  assign in_b[4].exceptionVec[12] = io_in_4_bits_exceptionVec_12;
  assign in_b[4].exceptionVec[13] = io_in_4_bits_exceptionVec_13;
  assign in_b[4].exceptionVec[14] = io_in_4_bits_exceptionVec_14;
  assign in_b[4].exceptionVec[15] = io_in_4_bits_exceptionVec_15;
  assign in_b[4].exceptionVec[16] = io_in_4_bits_exceptionVec_16;
  assign in_b[4].exceptionVec[17] = io_in_4_bits_exceptionVec_17;
  assign in_b[4].exceptionVec[18] = io_in_4_bits_exceptionVec_18;
  assign in_b[4].exceptionVec[19] = io_in_4_bits_exceptionVec_19;
  assign in_b[4].exceptionVec[20] = io_in_4_bits_exceptionVec_20;
  assign in_b[4].exceptionVec[21] = io_in_4_bits_exceptionVec_21;
  assign in_b[4].exceptionVec[22] = io_in_4_bits_exceptionVec_22;
  assign in_b[4].exceptionVec[23] = io_in_4_bits_exceptionVec_23;
  assign in_b[4].isFetchMalAddr = io_in_4_bits_isFetchMalAddr;
  assign in_b[4].trigger = io_in_4_bits_trigger;
  assign in_b[4].preDecodeInfo_valid = io_in_4_bits_preDecodeInfo_valid;
  assign in_b[4].preDecodeInfo_isRVC = io_in_4_bits_preDecodeInfo_isRVC;
  assign in_b[4].preDecodeInfo_brType = io_in_4_bits_preDecodeInfo_brType;
  assign in_b[4].preDecodeInfo_isCall = io_in_4_bits_preDecodeInfo_isCall;
  assign in_b[4].preDecodeInfo_isRet = io_in_4_bits_preDecodeInfo_isRet;
  assign in_b[4].pred_taken = io_in_4_bits_pred_taken;
  assign in_b[4].crossPageIPFFix = io_in_4_bits_crossPageIPFFix;
  assign in_b[4].ftqPtr_flag = io_in_4_bits_ftqPtr_flag;
  assign in_b[4].ftqPtr_value = io_in_4_bits_ftqPtr_value;
  assign in_b[4].ftqOffset = io_in_4_bits_ftqOffset;
  assign in_b[4].satpFlushFirstFetchFault = io_in_4_bits_satpFlushFirstFetchFault;
  assign in_b[4].srcType[0] = io_in_4_bits_srcType_0;
  assign in_b[4].srcType[1] = io_in_4_bits_srcType_1;
  assign in_b[4].srcType[2] = io_in_4_bits_srcType_2;
  assign in_b[4].srcType[3] = io_in_4_bits_srcType_3;
  assign in_b[4].srcType[4] = io_in_4_bits_srcType_4;
  assign in_b[4].lsrc[0] = io_in_4_bits_lsrc_0;
  assign in_b[4].lsrc[1] = io_in_4_bits_lsrc_1;
  assign in_b[4].lsrc[2] = io_in_4_bits_lsrc_2;
  assign in_b[4].lsrc[3] = io_in_4_bits_lsrc_3;
  assign in_b[4].lsrc[4] = io_in_4_bits_lsrc_4;
  assign in_b[4].ldest = io_in_4_bits_ldest;
  assign in_b[4].fuType = io_in_4_bits_fuType;
  assign in_b[4].fuOpType = io_in_4_bits_fuOpType;
  assign in_b[4].rfWen = io_in_4_bits_rfWen;
  assign in_b[4].fpWen = io_in_4_bits_fpWen;
  assign in_b[4].vecWen = io_in_4_bits_vecWen;
  assign in_b[4].v0Wen = io_in_4_bits_v0Wen;
  assign in_b[4].vlWen = io_in_4_bits_vlWen;
  assign in_b[4].isXSTrap = io_in_4_bits_isXSTrap;
  assign in_b[4].waitForward = io_in_4_bits_waitForward;
  assign in_b[4].blockBackward = io_in_4_bits_blockBackward;
  assign in_b[4].flushPipe = io_in_4_bits_flushPipe;
  assign in_b[4].canRobCompress = io_in_4_bits_canRobCompress;
  assign in_b[4].selImm = io_in_4_bits_selImm;
  assign in_b[4].imm = io_in_4_bits_imm;
  assign in_b[4].fpu_typeTagOut = io_in_4_bits_fpu_typeTagOut;
  assign in_b[4].fpu_wflags = io_in_4_bits_fpu_wflags;
  assign in_b[4].fpu_typ = io_in_4_bits_fpu_typ;
  assign in_b[4].fpu_fmt = io_in_4_bits_fpu_fmt;
  assign in_b[4].fpu_rm = io_in_4_bits_fpu_rm;
  assign in_b[4].vpu_vill = io_in_4_bits_vpu_vill;
  assign in_b[4].vpu_vma = io_in_4_bits_vpu_vma;
  assign in_b[4].vpu_vta = io_in_4_bits_vpu_vta;
  assign in_b[4].vpu_vsew = io_in_4_bits_vpu_vsew;
  assign in_b[4].vpu_vlmul = io_in_4_bits_vpu_vlmul;
  assign in_b[4].vpu_specVill = io_in_4_bits_vpu_specVill;
  assign in_b[4].vpu_specVma = io_in_4_bits_vpu_specVma;
  assign in_b[4].vpu_specVta = io_in_4_bits_vpu_specVta;
  assign in_b[4].vpu_specVsew = io_in_4_bits_vpu_specVsew;
  assign in_b[4].vpu_specVlmul = io_in_4_bits_vpu_specVlmul;
  assign in_b[4].vpu_vm = io_in_4_bits_vpu_vm;
  assign in_b[4].vpu_vstart = io_in_4_bits_vpu_vstart;
  assign in_b[4].vpu_frm = io_in_4_bits_vpu_frm;
  assign in_b[4].vpu_fpu_isFpToVecInst = io_in_4_bits_vpu_fpu_isFpToVecInst;
  assign in_b[4].vpu_fpu_isFP32Instr = io_in_4_bits_vpu_fpu_isFP32Instr;
  assign in_b[4].vpu_fpu_isFP64Instr = io_in_4_bits_vpu_fpu_isFP64Instr;
  assign in_b[4].vpu_fpu_isReduction = io_in_4_bits_vpu_fpu_isReduction;
  assign in_b[4].vpu_fpu_isFoldTo1_2 = io_in_4_bits_vpu_fpu_isFoldTo1_2;
  assign in_b[4].vpu_fpu_isFoldTo1_4 = io_in_4_bits_vpu_fpu_isFoldTo1_4;
  assign in_b[4].vpu_fpu_isFoldTo1_8 = io_in_4_bits_vpu_fpu_isFoldTo1_8;
  assign in_b[4].vpu_vxrm = io_in_4_bits_vpu_vxrm;
  assign in_b[4].vpu_vuopIdx = io_in_4_bits_vpu_vuopIdx;
  assign in_b[4].vpu_lastUop = io_in_4_bits_vpu_lastUop;
  assign in_b[4].vpu_vmask = io_in_4_bits_vpu_vmask;
  assign in_b[4].vpu_vl = io_in_4_bits_vpu_vl;
  assign in_b[4].vpu_nf = io_in_4_bits_vpu_nf;
  assign in_b[4].vpu_veew = io_in_4_bits_vpu_veew;
  assign in_b[4].vpu_isReverse = io_in_4_bits_vpu_isReverse;
  assign in_b[4].vpu_isExt = io_in_4_bits_vpu_isExt;
  assign in_b[4].vpu_isNarrow = io_in_4_bits_vpu_isNarrow;
  assign in_b[4].vpu_isDstMask = io_in_4_bits_vpu_isDstMask;
  assign in_b[4].vpu_isOpMask = io_in_4_bits_vpu_isOpMask;
  assign in_b[4].vpu_isMove = io_in_4_bits_vpu_isMove;
  assign in_b[4].vpu_isDependOldVd = io_in_4_bits_vpu_isDependOldVd;
  assign in_b[4].vpu_isWritePartVd = io_in_4_bits_vpu_isWritePartVd;
  assign in_b[4].vpu_isVleff = io_in_4_bits_vpu_isVleff;
  assign in_b[4].vlsInstr = io_in_4_bits_vlsInstr;
  assign in_b[4].wfflags = io_in_4_bits_wfflags;
  assign in_b[4].isMove = io_in_4_bits_isMove;
  assign in_b[4].uopIdx = io_in_4_bits_uopIdx;
  assign in_b[4].uopSplitType = io_in_4_bits_uopSplitType;
  assign in_b[4].isVset = io_in_4_bits_isVset;
  assign in_b[4].firstUop = io_in_4_bits_firstUop;
  assign in_b[4].lastUop = io_in_4_bits_lastUop;
  assign in_b[4].numUops = io_in_4_bits_numUops;
  assign in_b[4].numWB = io_in_4_bits_numWB;
  assign in_b[4].commitType = io_in_4_bits_commitType;
  assign in_b[4].debug_fuType = io_in_4_bits_debug_fuType;
  assign in_b[4].debug_seqNum_seqNum = io_in_4_bits_debug_seqNum_seqNum;
  assign in_b[4].debug_seqNum_uopIdx = io_in_4_bits_debug_seqNum_uopIdx;
  assign in_v[5] = io_in_5_valid;
  assign in_b[5].instr = io_in_5_bits_instr;
  assign in_b[5].pc = io_in_5_bits_pc;
  assign in_b[5].foldpc = io_in_5_bits_foldpc;
  assign in_b[5].exceptionVec[0] = io_in_5_bits_exceptionVec_0;
  assign in_b[5].exceptionVec[1] = io_in_5_bits_exceptionVec_1;
  assign in_b[5].exceptionVec[2] = io_in_5_bits_exceptionVec_2;
  assign in_b[5].exceptionVec[3] = io_in_5_bits_exceptionVec_3;
  assign in_b[5].exceptionVec[4] = io_in_5_bits_exceptionVec_4;
  assign in_b[5].exceptionVec[5] = io_in_5_bits_exceptionVec_5;
  assign in_b[5].exceptionVec[6] = io_in_5_bits_exceptionVec_6;
  assign in_b[5].exceptionVec[7] = io_in_5_bits_exceptionVec_7;
  assign in_b[5].exceptionVec[8] = io_in_5_bits_exceptionVec_8;
  assign in_b[5].exceptionVec[9] = io_in_5_bits_exceptionVec_9;
  assign in_b[5].exceptionVec[10] = io_in_5_bits_exceptionVec_10;
  assign in_b[5].exceptionVec[11] = io_in_5_bits_exceptionVec_11;
  assign in_b[5].exceptionVec[12] = io_in_5_bits_exceptionVec_12;
  assign in_b[5].exceptionVec[13] = io_in_5_bits_exceptionVec_13;
  assign in_b[5].exceptionVec[14] = io_in_5_bits_exceptionVec_14;
  assign in_b[5].exceptionVec[15] = io_in_5_bits_exceptionVec_15;
  assign in_b[5].exceptionVec[16] = io_in_5_bits_exceptionVec_16;
  assign in_b[5].exceptionVec[17] = io_in_5_bits_exceptionVec_17;
  assign in_b[5].exceptionVec[18] = io_in_5_bits_exceptionVec_18;
  assign in_b[5].exceptionVec[19] = io_in_5_bits_exceptionVec_19;
  assign in_b[5].exceptionVec[20] = io_in_5_bits_exceptionVec_20;
  assign in_b[5].exceptionVec[21] = io_in_5_bits_exceptionVec_21;
  assign in_b[5].exceptionVec[22] = io_in_5_bits_exceptionVec_22;
  assign in_b[5].exceptionVec[23] = io_in_5_bits_exceptionVec_23;
  assign in_b[5].isFetchMalAddr = io_in_5_bits_isFetchMalAddr;
  assign in_b[5].trigger = io_in_5_bits_trigger;
  assign in_b[5].preDecodeInfo_valid = io_in_5_bits_preDecodeInfo_valid;
  assign in_b[5].preDecodeInfo_isRVC = io_in_5_bits_preDecodeInfo_isRVC;
  assign in_b[5].preDecodeInfo_brType = io_in_5_bits_preDecodeInfo_brType;
  assign in_b[5].preDecodeInfo_isCall = io_in_5_bits_preDecodeInfo_isCall;
  assign in_b[5].preDecodeInfo_isRet = io_in_5_bits_preDecodeInfo_isRet;
  assign in_b[5].pred_taken = io_in_5_bits_pred_taken;
  assign in_b[5].crossPageIPFFix = io_in_5_bits_crossPageIPFFix;
  assign in_b[5].ftqPtr_flag = io_in_5_bits_ftqPtr_flag;
  assign in_b[5].ftqPtr_value = io_in_5_bits_ftqPtr_value;
  assign in_b[5].ftqOffset = io_in_5_bits_ftqOffset;
  assign in_b[5].satpFlushFirstFetchFault = io_in_5_bits_satpFlushFirstFetchFault;
  assign in_b[5].srcType[0] = io_in_5_bits_srcType_0;
  assign in_b[5].srcType[1] = io_in_5_bits_srcType_1;
  assign in_b[5].srcType[2] = io_in_5_bits_srcType_2;
  assign in_b[5].srcType[3] = io_in_5_bits_srcType_3;
  assign in_b[5].srcType[4] = io_in_5_bits_srcType_4;
  assign in_b[5].lsrc[0] = io_in_5_bits_lsrc_0;
  assign in_b[5].lsrc[1] = io_in_5_bits_lsrc_1;
  assign in_b[5].lsrc[2] = io_in_5_bits_lsrc_2;
  assign in_b[5].lsrc[3] = io_in_5_bits_lsrc_3;
  assign in_b[5].lsrc[4] = io_in_5_bits_lsrc_4;
  assign in_b[5].ldest = io_in_5_bits_ldest;
  assign in_b[5].fuType = io_in_5_bits_fuType;
  assign in_b[5].fuOpType = io_in_5_bits_fuOpType;
  assign in_b[5].rfWen = io_in_5_bits_rfWen;
  assign in_b[5].fpWen = io_in_5_bits_fpWen;
  assign in_b[5].vecWen = io_in_5_bits_vecWen;
  assign in_b[5].v0Wen = io_in_5_bits_v0Wen;
  assign in_b[5].vlWen = io_in_5_bits_vlWen;
  assign in_b[5].isXSTrap = io_in_5_bits_isXSTrap;
  assign in_b[5].waitForward = io_in_5_bits_waitForward;
  assign in_b[5].blockBackward = io_in_5_bits_blockBackward;
  assign in_b[5].flushPipe = io_in_5_bits_flushPipe;
  assign in_b[5].canRobCompress = io_in_5_bits_canRobCompress;
  assign in_b[5].selImm = io_in_5_bits_selImm;
  assign in_b[5].imm = io_in_5_bits_imm;
  assign in_b[5].fpu_typeTagOut = io_in_5_bits_fpu_typeTagOut;
  assign in_b[5].fpu_wflags = io_in_5_bits_fpu_wflags;
  assign in_b[5].fpu_typ = io_in_5_bits_fpu_typ;
  assign in_b[5].fpu_fmt = io_in_5_bits_fpu_fmt;
  assign in_b[5].fpu_rm = io_in_5_bits_fpu_rm;
  assign in_b[5].vpu_vill = io_in_5_bits_vpu_vill;
  assign in_b[5].vpu_vma = io_in_5_bits_vpu_vma;
  assign in_b[5].vpu_vta = io_in_5_bits_vpu_vta;
  assign in_b[5].vpu_vsew = io_in_5_bits_vpu_vsew;
  assign in_b[5].vpu_vlmul = io_in_5_bits_vpu_vlmul;
  assign in_b[5].vpu_specVill = io_in_5_bits_vpu_specVill;
  assign in_b[5].vpu_specVma = io_in_5_bits_vpu_specVma;
  assign in_b[5].vpu_specVta = io_in_5_bits_vpu_specVta;
  assign in_b[5].vpu_specVsew = io_in_5_bits_vpu_specVsew;
  assign in_b[5].vpu_specVlmul = io_in_5_bits_vpu_specVlmul;
  assign in_b[5].vpu_vm = io_in_5_bits_vpu_vm;
  assign in_b[5].vpu_vstart = io_in_5_bits_vpu_vstart;
  assign in_b[5].vpu_frm = io_in_5_bits_vpu_frm;
  assign in_b[5].vpu_fpu_isFpToVecInst = io_in_5_bits_vpu_fpu_isFpToVecInst;
  assign in_b[5].vpu_fpu_isFP32Instr = io_in_5_bits_vpu_fpu_isFP32Instr;
  assign in_b[5].vpu_fpu_isFP64Instr = io_in_5_bits_vpu_fpu_isFP64Instr;
  assign in_b[5].vpu_fpu_isReduction = io_in_5_bits_vpu_fpu_isReduction;
  assign in_b[5].vpu_fpu_isFoldTo1_2 = io_in_5_bits_vpu_fpu_isFoldTo1_2;
  assign in_b[5].vpu_fpu_isFoldTo1_4 = io_in_5_bits_vpu_fpu_isFoldTo1_4;
  assign in_b[5].vpu_fpu_isFoldTo1_8 = io_in_5_bits_vpu_fpu_isFoldTo1_8;
  assign in_b[5].vpu_vxrm = io_in_5_bits_vpu_vxrm;
  assign in_b[5].vpu_vuopIdx = io_in_5_bits_vpu_vuopIdx;
  assign in_b[5].vpu_lastUop = io_in_5_bits_vpu_lastUop;
  assign in_b[5].vpu_vmask = io_in_5_bits_vpu_vmask;
  assign in_b[5].vpu_vl = io_in_5_bits_vpu_vl;
  assign in_b[5].vpu_nf = io_in_5_bits_vpu_nf;
  assign in_b[5].vpu_veew = io_in_5_bits_vpu_veew;
  assign in_b[5].vpu_isReverse = io_in_5_bits_vpu_isReverse;
  assign in_b[5].vpu_isExt = io_in_5_bits_vpu_isExt;
  assign in_b[5].vpu_isNarrow = io_in_5_bits_vpu_isNarrow;
  assign in_b[5].vpu_isDstMask = io_in_5_bits_vpu_isDstMask;
  assign in_b[5].vpu_isOpMask = io_in_5_bits_vpu_isOpMask;
  assign in_b[5].vpu_isMove = io_in_5_bits_vpu_isMove;
  assign in_b[5].vpu_isDependOldVd = io_in_5_bits_vpu_isDependOldVd;
  assign in_b[5].vpu_isWritePartVd = io_in_5_bits_vpu_isWritePartVd;
  assign in_b[5].vpu_isVleff = io_in_5_bits_vpu_isVleff;
  assign in_b[5].vlsInstr = io_in_5_bits_vlsInstr;
  assign in_b[5].wfflags = io_in_5_bits_wfflags;
  assign in_b[5].isMove = io_in_5_bits_isMove;
  assign in_b[5].uopIdx = io_in_5_bits_uopIdx;
  assign in_b[5].uopSplitType = io_in_5_bits_uopSplitType;
  assign in_b[5].isVset = io_in_5_bits_isVset;
  assign in_b[5].firstUop = io_in_5_bits_firstUop;
  assign in_b[5].lastUop = io_in_5_bits_lastUop;
  assign in_b[5].numUops = io_in_5_bits_numUops;
  assign in_b[5].numWB = io_in_5_bits_numWB;
  assign in_b[5].commitType = io_in_5_bits_commitType;
  assign in_b[5].debug_fuType = io_in_5_bits_debug_fuType;
  assign in_b[5].debug_seqNum_seqNum = io_in_5_bits_debug_seqNum_seqNum;
  assign in_b[5].debug_seqNum_uopIdx = io_in_5_bits_debug_seqNum_uopIdx;
  assign fi_rs2FromRs1[0] = io_fusionInfo_0_rs2FromRs1;
  assign fi_rs2FromRs2[0] = io_fusionInfo_0_rs2FromRs2;
  assign fi_rs2FromZero[0] = io_fusionInfo_0_rs2FromZero;
  assign fi_rs2FromRs1[1] = io_fusionInfo_1_rs2FromRs1;
  assign fi_rs2FromRs2[1] = io_fusionInfo_1_rs2FromRs2;
  assign fi_rs2FromZero[1] = io_fusionInfo_1_rs2FromZero;
  assign fi_rs2FromRs1[2] = io_fusionInfo_2_rs2FromRs1;
  assign fi_rs2FromRs2[2] = io_fusionInfo_2_rs2FromRs2;
  assign fi_rs2FromZero[2] = io_fusionInfo_2_rs2FromZero;
  assign fi_rs2FromRs1[3] = io_fusionInfo_3_rs2FromRs1;
  assign fi_rs2FromRs2[3] = io_fusionInfo_3_rs2FromRs2;
  assign fi_rs2FromZero[3] = io_fusionInfo_3_rs2FromZero;
  assign fi_rs2FromRs1[4] = io_fusionInfo_4_rs2FromRs1;
  assign fi_rs2FromRs2[4] = io_fusionInfo_4_rs2FromRs2;
  assign fi_rs2FromZero[4] = io_fusionInfo_4_rs2FromZero;
  assign intRd[0][0] = io_intReadPorts_0_0;
  assign intRd[0][1] = io_intReadPorts_0_1;
  assign intRd[1][0] = io_intReadPorts_1_0;
  assign intRd[1][1] = io_intReadPorts_1_1;
  assign intRd[2][0] = io_intReadPorts_2_0;
  assign intRd[2][1] = io_intReadPorts_2_1;
  assign intRd[3][0] = io_intReadPorts_3_0;
  assign intRd[3][1] = io_intReadPorts_3_1;
  assign intRd[4][0] = io_intReadPorts_4_0;
  assign intRd[4][1] = io_intReadPorts_4_1;
  assign intRd[5][0] = io_intReadPorts_5_0;
  assign intRd[5][1] = io_intReadPorts_5_1;
  assign fpRd[0][0] = io_fpReadPorts_0_0;
  assign fpRd[0][1] = io_fpReadPorts_0_1;
  assign fpRd[0][2] = io_fpReadPorts_0_2;
  assign fpRd[1][0] = io_fpReadPorts_1_0;
  assign fpRd[1][1] = io_fpReadPorts_1_1;
  assign fpRd[1][2] = io_fpReadPorts_1_2;
  assign fpRd[2][0] = io_fpReadPorts_2_0;
  assign fpRd[2][1] = io_fpReadPorts_2_1;
  assign fpRd[2][2] = io_fpReadPorts_2_2;
  assign fpRd[3][0] = io_fpReadPorts_3_0;
  assign fpRd[3][1] = io_fpReadPorts_3_1;
  assign fpRd[3][2] = io_fpReadPorts_3_2;
  assign fpRd[4][0] = io_fpReadPorts_4_0;
  assign fpRd[4][1] = io_fpReadPorts_4_1;
  assign fpRd[4][2] = io_fpReadPorts_4_2;
  assign fpRd[5][0] = io_fpReadPorts_5_0;
  assign fpRd[5][1] = io_fpReadPorts_5_1;
  assign fpRd[5][2] = io_fpReadPorts_5_2;
  assign vecRd[0][0] = io_vecReadPorts_0_0;
  assign vecRd[0][1] = io_vecReadPorts_0_1;
  assign vecRd[0][2] = io_vecReadPorts_0_2;
  assign vecRd[1][0] = io_vecReadPorts_1_0;
  assign vecRd[1][1] = io_vecReadPorts_1_1;
  assign vecRd[1][2] = io_vecReadPorts_1_2;
  assign vecRd[2][0] = io_vecReadPorts_2_0;
  assign vecRd[2][1] = io_vecReadPorts_2_1;
  assign vecRd[2][2] = io_vecReadPorts_2_2;
  assign vecRd[3][0] = io_vecReadPorts_3_0;
  assign vecRd[3][1] = io_vecReadPorts_3_1;
  assign vecRd[3][2] = io_vecReadPorts_3_2;
  assign vecRd[4][0] = io_vecReadPorts_4_0;
  assign vecRd[4][1] = io_vecReadPorts_4_1;
  assign vecRd[4][2] = io_vecReadPorts_4_2;
  assign vecRd[5][0] = io_vecReadPorts_5_0;
  assign vecRd[5][1] = io_vecReadPorts_5_1;
  assign vecRd[5][2] = io_vecReadPorts_5_2;
  assign v0Rd[0] = io_v0ReadPorts_0_0;
  assign v0Rd[1] = io_v0ReadPorts_1_0;
  assign v0Rd[2] = io_v0ReadPorts_2_0;
  assign v0Rd[3] = io_v0ReadPorts_3_0;
  assign v0Rd[4] = io_v0ReadPorts_4_0;
  assign v0Rd[5] = io_v0ReadPorts_5_0;
  assign vlRd[0] = io_vlReadPorts_0_0;
  assign vlRd[1] = io_vlReadPorts_1_0;
  assign vlRd[2] = io_vlReadPorts_2_0;
  assign vlRd[3] = io_vlReadPorts_3_0;
  assign vlRd[4] = io_vlReadPorts_4_0;
  assign vlRd[5] = io_vlReadPorts_5_0;
  assign int_oldpd[0] = io_int_old_pdest_0;
  assign int_oldpd[1] = io_int_old_pdest_1;
  assign int_oldpd[2] = io_int_old_pdest_2;
  assign int_oldpd[3] = io_int_old_pdest_3;
  assign int_oldpd[4] = io_int_old_pdest_4;
  assign int_oldpd[5] = io_int_old_pdest_5;
  assign fp_oldpd[0] = io_fp_old_pdest_0;
  assign fp_oldpd[1] = io_fp_old_pdest_1;
  assign fp_oldpd[2] = io_fp_old_pdest_2;
  assign fp_oldpd[3] = io_fp_old_pdest_3;
  assign fp_oldpd[4] = io_fp_old_pdest_4;
  assign fp_oldpd[5] = io_fp_old_pdest_5;
  assign vec_oldpd[0] = io_vec_old_pdest_0;
  assign vec_oldpd[1] = io_vec_old_pdest_1;
  assign vec_oldpd[2] = io_vec_old_pdest_2;
  assign vec_oldpd[3] = io_vec_old_pdest_3;
  assign vec_oldpd[4] = io_vec_old_pdest_4;
  assign vec_oldpd[5] = io_vec_old_pdest_5;
  assign v0_oldpd[0] = io_v0_old_pdest_0;
  assign v0_oldpd[1] = io_v0_old_pdest_1;
  assign v0_oldpd[2] = io_v0_old_pdest_2;
  assign v0_oldpd[3] = io_v0_old_pdest_3;
  assign v0_oldpd[4] = io_v0_old_pdest_4;
  assign v0_oldpd[5] = io_v0_old_pdest_5;
  assign vl_oldpd[0] = io_vl_old_pdest_0;
  assign vl_oldpd[1] = io_vl_old_pdest_1;
  assign vl_oldpd[2] = io_vl_old_pdest_2;
  assign vl_oldpd[3] = io_vl_old_pdest_3;
  assign vl_oldpd[4] = io_vl_old_pdest_4;
  assign vl_oldpd[5] = io_vl_old_pdest_5;
  assign int_nf[0] = io_int_need_free_0;
  assign int_nf[1] = io_int_need_free_1;
  assign int_nf[2] = io_int_need_free_2;
  assign int_nf[3] = io_int_need_free_3;
  assign int_nf[4] = io_int_need_free_4;
  assign int_nf[5] = io_int_need_free_5;
  assign out_r[0] = io_out_0_ready;
  assign out_r[1] = io_out_1_ready;
  assign out_r[2] = io_out_2_ready;
  assign out_r[3] = io_out_3_ready;
  assign out_r[4] = io_out_4_ready;
  assign out_r[5] = io_out_5_ready;
  assign flushv[0] = io_snpt_flushVec_0;
  assign flushv[1] = io_snpt_flushVec_1;
  assign flushv[2] = io_snpt_flushVec_2;
  assign flushv[3] = io_snpt_flushVec_3;
  assign dbg_int_rat[0] = io_debug_int_rat_0;
  assign dbg_int_rat[1] = io_debug_int_rat_1;
  assign dbg_int_rat[2] = io_debug_int_rat_2;
  assign dbg_int_rat[3] = io_debug_int_rat_3;
  assign dbg_int_rat[4] = io_debug_int_rat_4;
  assign dbg_int_rat[5] = io_debug_int_rat_5;
  assign dbg_int_rat[6] = io_debug_int_rat_6;
  assign dbg_int_rat[7] = io_debug_int_rat_7;
  assign dbg_int_rat[8] = io_debug_int_rat_8;
  assign dbg_int_rat[9] = io_debug_int_rat_9;
  assign dbg_int_rat[10] = io_debug_int_rat_10;
  assign dbg_int_rat[11] = io_debug_int_rat_11;
  assign dbg_int_rat[12] = io_debug_int_rat_12;
  assign dbg_int_rat[13] = io_debug_int_rat_13;
  assign dbg_int_rat[14] = io_debug_int_rat_14;
  assign dbg_int_rat[15] = io_debug_int_rat_15;
  assign dbg_int_rat[16] = io_debug_int_rat_16;
  assign dbg_int_rat[17] = io_debug_int_rat_17;
  assign dbg_int_rat[18] = io_debug_int_rat_18;
  assign dbg_int_rat[19] = io_debug_int_rat_19;
  assign dbg_int_rat[20] = io_debug_int_rat_20;
  assign dbg_int_rat[21] = io_debug_int_rat_21;
  assign dbg_int_rat[22] = io_debug_int_rat_22;
  assign dbg_int_rat[23] = io_debug_int_rat_23;
  assign dbg_int_rat[24] = io_debug_int_rat_24;
  assign dbg_int_rat[25] = io_debug_int_rat_25;
  assign dbg_int_rat[26] = io_debug_int_rat_26;
  assign dbg_int_rat[27] = io_debug_int_rat_27;
  assign dbg_int_rat[28] = io_debug_int_rat_28;
  assign dbg_int_rat[29] = io_debug_int_rat_29;
  assign dbg_int_rat[30] = io_debug_int_rat_30;
  assign dbg_int_rat[31] = io_debug_int_rat_31;
  assign sr_in[0] = io_stallReason_in_reason_0;
  assign sr_in[1] = io_stallReason_in_reason_1;
  assign sr_in[2] = io_stallReason_in_reason_2;
  assign sr_in[3] = io_stallReason_in_reason_3;
  assign sr_in[4] = io_stallReason_in_reason_4;
  assign sr_in[5] = io_stallReason_in_reason_5;
  assign in_b[0].lsrc[2] = '0;   // golden 口 0 没有 lsrc_2(firtool 消掉)，补 0
  assign in_b[0].lsrc[3] = '0;   // golden 口 0 没有 lsrc_3(firtool 消掉)，补 0
  assign in_b[0].lsrc[4] = '0;   // golden 口 0 没有 lsrc_4(firtool 消掉)，补 0
  assign fi_rs2FromRs1[5] = 1'b0; assign fi_rs2FromRs2[5] = 1'b0; assign fi_rs2FromZero[5] = 1'b0;

  // ---- 输出重组：直通字段来自 out_pt，计算字段来自核显式输出 ----
  assign io_in_0_ready = in_r[0];
  assign io_in_1_ready = in_r[1];
  assign io_in_2_ready = in_r[2];
  assign io_in_3_ready = in_r[3];
  assign io_in_4_ready = in_r[4];
  assign io_in_5_ready = in_r[5];
  assign io_intRenamePorts_0_wen = intRP[0].wen;
  assign io_intRenamePorts_0_addr = intRP[0].addr[4:0];
  assign io_intRenamePorts_0_data = intRP[0].data;
  assign io_intRenamePorts_1_wen = intRP[1].wen;
  assign io_intRenamePorts_1_addr = intRP[1].addr[4:0];
  assign io_intRenamePorts_1_data = intRP[1].data;
  assign io_intRenamePorts_2_wen = intRP[2].wen;
  assign io_intRenamePorts_2_addr = intRP[2].addr[4:0];
  assign io_intRenamePorts_2_data = intRP[2].data;
  assign io_intRenamePorts_3_wen = intRP[3].wen;
  assign io_intRenamePorts_3_addr = intRP[3].addr[4:0];
  assign io_intRenamePorts_3_data = intRP[3].data;
  assign io_intRenamePorts_4_wen = intRP[4].wen;
  assign io_intRenamePorts_4_addr = intRP[4].addr[4:0];
  assign io_intRenamePorts_4_data = intRP[4].data;
  assign io_intRenamePorts_5_wen = intRP[5].wen;
  assign io_intRenamePorts_5_addr = intRP[5].addr[4:0];
  assign io_intRenamePorts_5_data = intRP[5].data;
  assign io_fpRenamePorts_0_wen = fpRP[0].wen;
  assign io_fpRenamePorts_0_addr = fpRP[0].addr;
  assign io_fpRenamePorts_0_data = fpRP[0].data;
  assign io_fpRenamePorts_1_wen = fpRP[1].wen;
  assign io_fpRenamePorts_1_addr = fpRP[1].addr;
  assign io_fpRenamePorts_1_data = fpRP[1].data;
  assign io_fpRenamePorts_2_wen = fpRP[2].wen;
  assign io_fpRenamePorts_2_addr = fpRP[2].addr;
  assign io_fpRenamePorts_2_data = fpRP[2].data;
  assign io_fpRenamePorts_3_wen = fpRP[3].wen;
  assign io_fpRenamePorts_3_addr = fpRP[3].addr;
  assign io_fpRenamePorts_3_data = fpRP[3].data;
  assign io_fpRenamePorts_4_wen = fpRP[4].wen;
  assign io_fpRenamePorts_4_addr = fpRP[4].addr;
  assign io_fpRenamePorts_4_data = fpRP[4].data;
  assign io_fpRenamePorts_5_wen = fpRP[5].wen;
  assign io_fpRenamePorts_5_addr = fpRP[5].addr;
  assign io_fpRenamePorts_5_data = fpRP[5].data;
  assign io_vecRenamePorts_0_wen = vecRP[0].wen;
  assign io_vecRenamePorts_0_addr = vecRP[0].addr;
  assign io_vecRenamePorts_0_data = vecRP[0].data;
  assign io_vecRenamePorts_1_wen = vecRP[1].wen;
  assign io_vecRenamePorts_1_addr = vecRP[1].addr;
  assign io_vecRenamePorts_1_data = vecRP[1].data;
  assign io_vecRenamePorts_2_wen = vecRP[2].wen;
  assign io_vecRenamePorts_2_addr = vecRP[2].addr;
  assign io_vecRenamePorts_2_data = vecRP[2].data;
  assign io_vecRenamePorts_3_wen = vecRP[3].wen;
  assign io_vecRenamePorts_3_addr = vecRP[3].addr;
  assign io_vecRenamePorts_3_data = vecRP[3].data;
  assign io_vecRenamePorts_4_wen = vecRP[4].wen;
  assign io_vecRenamePorts_4_addr = vecRP[4].addr;
  assign io_vecRenamePorts_4_data = vecRP[4].data;
  assign io_vecRenamePorts_5_wen = vecRP[5].wen;
  assign io_vecRenamePorts_5_addr = vecRP[5].addr;
  assign io_vecRenamePorts_5_data = vecRP[5].data;
  assign io_v0RenamePorts_0_wen = v0RP_wen[0];
  assign io_v0RenamePorts_0_data = v0RP_data[0];
  assign io_v0RenamePorts_1_wen = v0RP_wen[1];
  assign io_v0RenamePorts_1_data = v0RP_data[1];
  assign io_v0RenamePorts_2_wen = v0RP_wen[2];
  assign io_v0RenamePorts_2_data = v0RP_data[2];
  assign io_v0RenamePorts_3_wen = v0RP_wen[3];
  assign io_v0RenamePorts_3_data = v0RP_data[3];
  assign io_v0RenamePorts_4_wen = v0RP_wen[4];
  assign io_v0RenamePorts_4_data = v0RP_data[4];
  assign io_v0RenamePorts_5_wen = v0RP_wen[5];
  assign io_v0RenamePorts_5_data = v0RP_data[5];
  assign io_vlRenamePorts_0_wen = vlRP_wen[0];
  assign io_vlRenamePorts_0_data = vlRP_data[0];
  assign io_vlRenamePorts_1_wen = vlRP_wen[1];
  assign io_vlRenamePorts_1_data = vlRP_data[1];
  assign io_vlRenamePorts_2_wen = vlRP_wen[2];
  assign io_vlRenamePorts_2_data = vlRP_data[2];
  assign io_vlRenamePorts_3_wen = vlRP_wen[3];
  assign io_vlRenamePorts_3_data = vlRP_data[3];
  assign io_vlRenamePorts_4_wen = vlRP_wen[4];
  assign io_vlRenamePorts_4_data = vlRP_data[4];
  assign io_vlRenamePorts_5_wen = vlRP_wen[5];
  assign io_vlRenamePorts_5_data = vlRP_data[5];
  assign io_out_0_valid = out_v[0];
  assign io_out_0_bits_instr = out_pt[0].instr;
  assign io_out_0_bits_pc = out_pt[0].pc;
  assign io_out_0_bits_foldpc = out_pt[0].foldpc;
  assign io_out_0_bits_exceptionVec_0 = out_pt[0].exceptionVec[0];
  assign io_out_0_bits_exceptionVec_1 = out_pt[0].exceptionVec[1];
  assign io_out_0_bits_exceptionVec_2 = out_pt[0].exceptionVec[2];
  assign io_out_0_bits_exceptionVec_3 = out_pt[0].exceptionVec[3];
  assign io_out_0_bits_exceptionVec_4 = out_pt[0].exceptionVec[4];
  assign io_out_0_bits_exceptionVec_5 = out_pt[0].exceptionVec[5];
  assign io_out_0_bits_exceptionVec_6 = out_pt[0].exceptionVec[6];
  assign io_out_0_bits_exceptionVec_7 = out_pt[0].exceptionVec[7];
  assign io_out_0_bits_exceptionVec_8 = out_pt[0].exceptionVec[8];
  assign io_out_0_bits_exceptionVec_9 = out_pt[0].exceptionVec[9];
  assign io_out_0_bits_exceptionVec_10 = out_pt[0].exceptionVec[10];
  assign io_out_0_bits_exceptionVec_11 = out_pt[0].exceptionVec[11];
  assign io_out_0_bits_exceptionVec_12 = out_pt[0].exceptionVec[12];
  assign io_out_0_bits_exceptionVec_13 = out_pt[0].exceptionVec[13];
  assign io_out_0_bits_exceptionVec_14 = out_pt[0].exceptionVec[14];
  assign io_out_0_bits_exceptionVec_15 = out_pt[0].exceptionVec[15];
  assign io_out_0_bits_exceptionVec_16 = out_pt[0].exceptionVec[16];
  assign io_out_0_bits_exceptionVec_17 = out_pt[0].exceptionVec[17];
  assign io_out_0_bits_exceptionVec_18 = out_pt[0].exceptionVec[18];
  assign io_out_0_bits_exceptionVec_19 = out_pt[0].exceptionVec[19];
  assign io_out_0_bits_exceptionVec_20 = out_pt[0].exceptionVec[20];
  assign io_out_0_bits_exceptionVec_21 = out_pt[0].exceptionVec[21];
  assign io_out_0_bits_exceptionVec_22 = out_pt[0].exceptionVec[22];
  assign io_out_0_bits_exceptionVec_23 = out_pt[0].exceptionVec[23];
  assign io_out_0_bits_isFetchMalAddr = out_pt[0].isFetchMalAddr;
  assign io_out_0_bits_hasException = o_hasException[0];
  assign io_out_0_bits_trigger = out_pt[0].trigger;
  assign io_out_0_bits_preDecodeInfo_valid = out_pt[0].preDecodeInfo_valid;
  assign io_out_0_bits_preDecodeInfo_isRVC = out_pt[0].preDecodeInfo_isRVC;
  assign io_out_0_bits_preDecodeInfo_brType = out_pt[0].preDecodeInfo_brType;
  assign io_out_0_bits_preDecodeInfo_isCall = out_pt[0].preDecodeInfo_isCall;
  assign io_out_0_bits_preDecodeInfo_isRet = out_pt[0].preDecodeInfo_isRet;
  assign io_out_0_bits_pred_taken = out_pt[0].pred_taken;
  assign io_out_0_bits_crossPageIPFFix = out_pt[0].crossPageIPFFix;
  assign io_out_0_bits_ftqPtr_flag = o_ftqFlag[0];
  assign io_out_0_bits_ftqPtr_value = o_ftqValue[0];
  assign io_out_0_bits_ftqOffset = o_ftqOff[0];
  assign io_out_0_bits_satpFlushFirstFetchFault = out_pt[0].satpFlushFirstFetchFault;
  assign io_out_0_bits_srcType_0 = o_srcType0[0];
  assign io_out_0_bits_srcType_1 = out_pt[0].srcType[1];
  assign io_out_0_bits_srcType_2 = out_pt[0].srcType[2];
  assign io_out_0_bits_srcType_3 = out_pt[0].srcType[3];
  assign io_out_0_bits_srcType_4 = out_pt[0].srcType[4];
  assign io_out_0_bits_ldest = out_pt[0].ldest;
  assign io_out_0_bits_fuType = out_pt[0].fuType;
  assign io_out_0_bits_fuOpType = out_pt[0].fuOpType;
  assign io_out_0_bits_rfWen = out_pt[0].rfWen;
  assign io_out_0_bits_fpWen = out_pt[0].fpWen;
  assign io_out_0_bits_vecWen = out_pt[0].vecWen;
  assign io_out_0_bits_v0Wen = out_pt[0].v0Wen;
  assign io_out_0_bits_vlWen = out_pt[0].vlWen;
  assign io_out_0_bits_isXSTrap = out_pt[0].isXSTrap;
  assign io_out_0_bits_waitForward = o_waitForward[0];
  assign io_out_0_bits_blockBackward = o_blockBackward[0];
  assign io_out_0_bits_flushPipe = out_pt[0].flushPipe;
  assign io_out_0_bits_canRobCompress = out_pt[0].canRobCompress;
  assign io_out_0_bits_selImm = out_pt[0].selImm;
  assign io_out_0_bits_imm = o_imm[0];
  assign io_out_0_bits_fpu_typeTagOut = out_pt[0].fpu_typeTagOut;
  assign io_out_0_bits_fpu_wflags = out_pt[0].fpu_wflags;
  assign io_out_0_bits_fpu_typ = out_pt[0].fpu_typ;
  assign io_out_0_bits_fpu_fmt = out_pt[0].fpu_fmt;
  assign io_out_0_bits_fpu_rm = out_pt[0].fpu_rm;
  assign io_out_0_bits_vpu_vill = out_pt[0].vpu_vill;
  assign io_out_0_bits_vpu_vma = out_pt[0].vpu_vma;
  assign io_out_0_bits_vpu_vta = out_pt[0].vpu_vta;
  assign io_out_0_bits_vpu_vsew = out_pt[0].vpu_vsew;
  assign io_out_0_bits_vpu_vlmul = out_pt[0].vpu_vlmul;
  assign io_out_0_bits_vpu_specVill = out_pt[0].vpu_specVill;
  assign io_out_0_bits_vpu_specVma = out_pt[0].vpu_specVma;
  assign io_out_0_bits_vpu_specVta = out_pt[0].vpu_specVta;
  assign io_out_0_bits_vpu_specVsew = out_pt[0].vpu_specVsew;
  assign io_out_0_bits_vpu_specVlmul = out_pt[0].vpu_specVlmul;
  assign io_out_0_bits_vpu_vm = out_pt[0].vpu_vm;
  assign io_out_0_bits_vpu_vstart = out_pt[0].vpu_vstart;
  assign io_out_0_bits_vpu_frm = out_pt[0].vpu_frm;
  assign io_out_0_bits_vpu_fpu_isFpToVecInst = out_pt[0].vpu_fpu_isFpToVecInst;
  assign io_out_0_bits_vpu_fpu_isFP32Instr = out_pt[0].vpu_fpu_isFP32Instr;
  assign io_out_0_bits_vpu_fpu_isFP64Instr = out_pt[0].vpu_fpu_isFP64Instr;
  assign io_out_0_bits_vpu_fpu_isReduction = out_pt[0].vpu_fpu_isReduction;
  assign io_out_0_bits_vpu_fpu_isFoldTo1_2 = out_pt[0].vpu_fpu_isFoldTo1_2;
  assign io_out_0_bits_vpu_fpu_isFoldTo1_4 = out_pt[0].vpu_fpu_isFoldTo1_4;
  assign io_out_0_bits_vpu_fpu_isFoldTo1_8 = out_pt[0].vpu_fpu_isFoldTo1_8;
  assign io_out_0_bits_vpu_vxrm = out_pt[0].vpu_vxrm;
  assign io_out_0_bits_vpu_vuopIdx = out_pt[0].vpu_vuopIdx;
  assign io_out_0_bits_vpu_lastUop = out_pt[0].vpu_lastUop;
  assign io_out_0_bits_vpu_vmask = out_pt[0].vpu_vmask;
  assign io_out_0_bits_vpu_vl = out_pt[0].vpu_vl;
  assign io_out_0_bits_vpu_nf = out_pt[0].vpu_nf;
  assign io_out_0_bits_vpu_veew = out_pt[0].vpu_veew;
  assign io_out_0_bits_vpu_isReverse = out_pt[0].vpu_isReverse;
  assign io_out_0_bits_vpu_isExt = out_pt[0].vpu_isExt;
  assign io_out_0_bits_vpu_isNarrow = out_pt[0].vpu_isNarrow;
  assign io_out_0_bits_vpu_isDstMask = out_pt[0].vpu_isDstMask;
  assign io_out_0_bits_vpu_isOpMask = out_pt[0].vpu_isOpMask;
  assign io_out_0_bits_vpu_isMove = out_pt[0].vpu_isMove;
  assign io_out_0_bits_vpu_isDependOldVd = out_pt[0].vpu_isDependOldVd;
  assign io_out_0_bits_vpu_isWritePartVd = out_pt[0].vpu_isWritePartVd;
  assign io_out_0_bits_vpu_isVleff = out_pt[0].vpu_isVleff;
  assign io_out_0_bits_vlsInstr = out_pt[0].vlsInstr;
  assign io_out_0_bits_wfflags = o_wfflags[0];
  assign io_out_0_bits_isMove = o_isMove[0];
  assign io_out_0_bits_uopIdx = out_pt[0].uopIdx;
  assign io_out_0_bits_isVset = out_pt[0].isVset;
  assign io_out_0_bits_firstUop = o_firstUop[0];
  assign io_out_0_bits_lastUop = o_lastUop[0];
  assign io_out_0_bits_numUops = o_numUops[0];
  assign io_out_0_bits_numWB = o_numWB[0];
  assign io_out_0_bits_commitType = out_pt[0].commitType;
  assign io_out_0_bits_psrc_0 = o_psrc[0][0];
  assign io_out_0_bits_psrc_1 = o_psrc[0][1];
  assign io_out_0_bits_psrc_2 = o_psrc[0][2];
  assign io_out_0_bits_psrc_3 = o_psrc[0][3];
  assign io_out_0_bits_psrc_4 = o_psrc[0][4];
  assign io_out_0_bits_pdest = o_pdest[0];
  assign io_out_0_bits_robIdx_flag = o_robIdx_flag[0];
  assign io_out_0_bits_robIdx_value = o_robIdx_value[0];
  assign io_out_0_bits_instrSize = o_instrSize[0];
  assign io_out_0_bits_dirtyFs = o_dirtyFs[0];
  assign io_out_0_bits_dirtyVs = o_dirtyVs[0];
  assign io_out_0_bits_traceBlockInPipe_itype = o_itype[0];
  assign io_out_0_bits_traceBlockInPipe_iretire = o_iretire[0];
  assign io_out_0_bits_traceBlockInPipe_ilastsize = o_ilastsize[0];
  assign io_out_0_bits_eliminatedMove = o_isMove[0];
  assign io_out_0_bits_snapshot = o_snapshot[0];
  assign io_out_0_bits_debugInfo_renameTime = o_renameTime[0];
  assign io_out_0_bits_debug_seqNum_seqNum = out_pt[0].debug_seqNum_seqNum;
  assign io_out_0_bits_debug_seqNum_uopIdx = out_pt[0].debug_seqNum_uopIdx;
  assign io_out_0_bits_debug_fuType = out_pt[0].debug_fuType;
  assign io_out_0_bits_debug_sim_trig = o_simTrig[0];
  assign io_out_0_bits_numLsElem = o_numLsElem[0];
  assign io_out_1_valid = out_v[1];
  assign io_out_1_bits_instr = out_pt[1].instr;
  assign io_out_1_bits_pc = out_pt[1].pc;
  assign io_out_1_bits_foldpc = out_pt[1].foldpc;
  assign io_out_1_bits_exceptionVec_0 = out_pt[1].exceptionVec[0];
  assign io_out_1_bits_exceptionVec_1 = out_pt[1].exceptionVec[1];
  assign io_out_1_bits_exceptionVec_2 = out_pt[1].exceptionVec[2];
  assign io_out_1_bits_exceptionVec_3 = out_pt[1].exceptionVec[3];
  assign io_out_1_bits_exceptionVec_4 = out_pt[1].exceptionVec[4];
  assign io_out_1_bits_exceptionVec_5 = out_pt[1].exceptionVec[5];
  assign io_out_1_bits_exceptionVec_6 = out_pt[1].exceptionVec[6];
  assign io_out_1_bits_exceptionVec_7 = out_pt[1].exceptionVec[7];
  assign io_out_1_bits_exceptionVec_8 = out_pt[1].exceptionVec[8];
  assign io_out_1_bits_exceptionVec_9 = out_pt[1].exceptionVec[9];
  assign io_out_1_bits_exceptionVec_10 = out_pt[1].exceptionVec[10];
  assign io_out_1_bits_exceptionVec_11 = out_pt[1].exceptionVec[11];
  assign io_out_1_bits_exceptionVec_12 = out_pt[1].exceptionVec[12];
  assign io_out_1_bits_exceptionVec_13 = out_pt[1].exceptionVec[13];
  assign io_out_1_bits_exceptionVec_14 = out_pt[1].exceptionVec[14];
  assign io_out_1_bits_exceptionVec_15 = out_pt[1].exceptionVec[15];
  assign io_out_1_bits_exceptionVec_16 = out_pt[1].exceptionVec[16];
  assign io_out_1_bits_exceptionVec_17 = out_pt[1].exceptionVec[17];
  assign io_out_1_bits_exceptionVec_18 = out_pt[1].exceptionVec[18];
  assign io_out_1_bits_exceptionVec_19 = out_pt[1].exceptionVec[19];
  assign io_out_1_bits_exceptionVec_20 = out_pt[1].exceptionVec[20];
  assign io_out_1_bits_exceptionVec_21 = out_pt[1].exceptionVec[21];
  assign io_out_1_bits_exceptionVec_22 = out_pt[1].exceptionVec[22];
  assign io_out_1_bits_exceptionVec_23 = out_pt[1].exceptionVec[23];
  assign io_out_1_bits_isFetchMalAddr = out_pt[1].isFetchMalAddr;
  assign io_out_1_bits_hasException = o_hasException[1];
  assign io_out_1_bits_trigger = out_pt[1].trigger;
  assign io_out_1_bits_preDecodeInfo_valid = out_pt[1].preDecodeInfo_valid;
  assign io_out_1_bits_preDecodeInfo_isRVC = out_pt[1].preDecodeInfo_isRVC;
  assign io_out_1_bits_preDecodeInfo_brType = out_pt[1].preDecodeInfo_brType;
  assign io_out_1_bits_preDecodeInfo_isCall = out_pt[1].preDecodeInfo_isCall;
  assign io_out_1_bits_preDecodeInfo_isRet = out_pt[1].preDecodeInfo_isRet;
  assign io_out_1_bits_pred_taken = out_pt[1].pred_taken;
  assign io_out_1_bits_crossPageIPFFix = out_pt[1].crossPageIPFFix;
  assign io_out_1_bits_ftqPtr_flag = o_ftqFlag[1];
  assign io_out_1_bits_ftqPtr_value = o_ftqValue[1];
  assign io_out_1_bits_ftqOffset = o_ftqOff[1];
  assign io_out_1_bits_satpFlushFirstFetchFault = out_pt[1].satpFlushFirstFetchFault;
  assign io_out_1_bits_srcType_0 = o_srcType0[1];
  assign io_out_1_bits_srcType_1 = out_pt[1].srcType[1];
  assign io_out_1_bits_srcType_2 = out_pt[1].srcType[2];
  assign io_out_1_bits_srcType_3 = out_pt[1].srcType[3];
  assign io_out_1_bits_srcType_4 = out_pt[1].srcType[4];
  assign io_out_1_bits_ldest = out_pt[1].ldest;
  assign io_out_1_bits_fuType = out_pt[1].fuType;
  assign io_out_1_bits_fuOpType = out_pt[1].fuOpType;
  assign io_out_1_bits_rfWen = out_pt[1].rfWen;
  assign io_out_1_bits_fpWen = out_pt[1].fpWen;
  assign io_out_1_bits_vecWen = out_pt[1].vecWen;
  assign io_out_1_bits_v0Wen = out_pt[1].v0Wen;
  assign io_out_1_bits_vlWen = out_pt[1].vlWen;
  assign io_out_1_bits_isXSTrap = out_pt[1].isXSTrap;
  assign io_out_1_bits_waitForward = o_waitForward[1];
  assign io_out_1_bits_blockBackward = o_blockBackward[1];
  assign io_out_1_bits_flushPipe = out_pt[1].flushPipe;
  assign io_out_1_bits_canRobCompress = out_pt[1].canRobCompress;
  assign io_out_1_bits_selImm = out_pt[1].selImm;
  assign io_out_1_bits_imm = o_imm[1];
  assign io_out_1_bits_fpu_typeTagOut = out_pt[1].fpu_typeTagOut;
  assign io_out_1_bits_fpu_wflags = out_pt[1].fpu_wflags;
  assign io_out_1_bits_fpu_typ = out_pt[1].fpu_typ;
  assign io_out_1_bits_fpu_fmt = out_pt[1].fpu_fmt;
  assign io_out_1_bits_fpu_rm = out_pt[1].fpu_rm;
  assign io_out_1_bits_vpu_vill = out_pt[1].vpu_vill;
  assign io_out_1_bits_vpu_vma = out_pt[1].vpu_vma;
  assign io_out_1_bits_vpu_vta = out_pt[1].vpu_vta;
  assign io_out_1_bits_vpu_vsew = out_pt[1].vpu_vsew;
  assign io_out_1_bits_vpu_vlmul = out_pt[1].vpu_vlmul;
  assign io_out_1_bits_vpu_specVill = out_pt[1].vpu_specVill;
  assign io_out_1_bits_vpu_specVma = out_pt[1].vpu_specVma;
  assign io_out_1_bits_vpu_specVta = out_pt[1].vpu_specVta;
  assign io_out_1_bits_vpu_specVsew = out_pt[1].vpu_specVsew;
  assign io_out_1_bits_vpu_specVlmul = out_pt[1].vpu_specVlmul;
  assign io_out_1_bits_vpu_vm = out_pt[1].vpu_vm;
  assign io_out_1_bits_vpu_vstart = out_pt[1].vpu_vstart;
  assign io_out_1_bits_vpu_frm = out_pt[1].vpu_frm;
  assign io_out_1_bits_vpu_fpu_isFpToVecInst = out_pt[1].vpu_fpu_isFpToVecInst;
  assign io_out_1_bits_vpu_fpu_isFP32Instr = out_pt[1].vpu_fpu_isFP32Instr;
  assign io_out_1_bits_vpu_fpu_isFP64Instr = out_pt[1].vpu_fpu_isFP64Instr;
  assign io_out_1_bits_vpu_fpu_isReduction = out_pt[1].vpu_fpu_isReduction;
  assign io_out_1_bits_vpu_fpu_isFoldTo1_2 = out_pt[1].vpu_fpu_isFoldTo1_2;
  assign io_out_1_bits_vpu_fpu_isFoldTo1_4 = out_pt[1].vpu_fpu_isFoldTo1_4;
  assign io_out_1_bits_vpu_fpu_isFoldTo1_8 = out_pt[1].vpu_fpu_isFoldTo1_8;
  assign io_out_1_bits_vpu_vxrm = out_pt[1].vpu_vxrm;
  assign io_out_1_bits_vpu_vuopIdx = out_pt[1].vpu_vuopIdx;
  assign io_out_1_bits_vpu_lastUop = out_pt[1].vpu_lastUop;
  assign io_out_1_bits_vpu_vmask = out_pt[1].vpu_vmask;
  assign io_out_1_bits_vpu_vl = out_pt[1].vpu_vl;
  assign io_out_1_bits_vpu_nf = out_pt[1].vpu_nf;
  assign io_out_1_bits_vpu_veew = out_pt[1].vpu_veew;
  assign io_out_1_bits_vpu_isReverse = out_pt[1].vpu_isReverse;
  assign io_out_1_bits_vpu_isExt = out_pt[1].vpu_isExt;
  assign io_out_1_bits_vpu_isNarrow = out_pt[1].vpu_isNarrow;
  assign io_out_1_bits_vpu_isDstMask = out_pt[1].vpu_isDstMask;
  assign io_out_1_bits_vpu_isOpMask = out_pt[1].vpu_isOpMask;
  assign io_out_1_bits_vpu_isMove = out_pt[1].vpu_isMove;
  assign io_out_1_bits_vpu_isDependOldVd = out_pt[1].vpu_isDependOldVd;
  assign io_out_1_bits_vpu_isWritePartVd = out_pt[1].vpu_isWritePartVd;
  assign io_out_1_bits_vpu_isVleff = out_pt[1].vpu_isVleff;
  assign io_out_1_bits_vlsInstr = out_pt[1].vlsInstr;
  assign io_out_1_bits_wfflags = o_wfflags[1];
  assign io_out_1_bits_isMove = o_isMove[1];
  assign io_out_1_bits_uopIdx = out_pt[1].uopIdx;
  assign io_out_1_bits_isVset = out_pt[1].isVset;
  assign io_out_1_bits_firstUop = o_firstUop[1];
  assign io_out_1_bits_lastUop = o_lastUop[1];
  assign io_out_1_bits_numUops = o_numUops[1];
  assign io_out_1_bits_numWB = o_numWB[1];
  assign io_out_1_bits_commitType = out_pt[1].commitType;
  assign io_out_1_bits_psrc_0 = o_psrc[1][0];
  assign io_out_1_bits_psrc_1 = o_psrc[1][1];
  assign io_out_1_bits_psrc_2 = o_psrc[1][2];
  assign io_out_1_bits_psrc_3 = o_psrc[1][3];
  assign io_out_1_bits_psrc_4 = o_psrc[1][4];
  assign io_out_1_bits_pdest = o_pdest[1];
  assign io_out_1_bits_robIdx_flag = o_robIdx_flag[1];
  assign io_out_1_bits_robIdx_value = o_robIdx_value[1];
  assign io_out_1_bits_instrSize = o_instrSize[1];
  assign io_out_1_bits_dirtyFs = o_dirtyFs[1];
  assign io_out_1_bits_dirtyVs = o_dirtyVs[1];
  assign io_out_1_bits_traceBlockInPipe_itype = o_itype[1];
  assign io_out_1_bits_traceBlockInPipe_iretire = o_iretire[1];
  assign io_out_1_bits_traceBlockInPipe_ilastsize = o_ilastsize[1];
  assign io_out_1_bits_eliminatedMove = o_isMove[1];
  assign io_out_1_bits_snapshot = o_snapshot[1];
  assign io_out_1_bits_debugInfo_renameTime = o_renameTime[1];
  assign io_out_1_bits_debug_seqNum_seqNum = out_pt[1].debug_seqNum_seqNum;
  assign io_out_1_bits_debug_seqNum_uopIdx = out_pt[1].debug_seqNum_uopIdx;
  assign io_out_1_bits_debug_fuType = out_pt[1].debug_fuType;
  assign io_out_1_bits_debug_sim_trig = o_simTrig[1];
  assign io_out_1_bits_numLsElem = o_numLsElem[1];
  assign io_out_2_valid = out_v[2];
  assign io_out_2_bits_instr = out_pt[2].instr;
  assign io_out_2_bits_pc = out_pt[2].pc;
  assign io_out_2_bits_foldpc = out_pt[2].foldpc;
  assign io_out_2_bits_exceptionVec_0 = out_pt[2].exceptionVec[0];
  assign io_out_2_bits_exceptionVec_1 = out_pt[2].exceptionVec[1];
  assign io_out_2_bits_exceptionVec_2 = out_pt[2].exceptionVec[2];
  assign io_out_2_bits_exceptionVec_3 = out_pt[2].exceptionVec[3];
  assign io_out_2_bits_exceptionVec_4 = out_pt[2].exceptionVec[4];
  assign io_out_2_bits_exceptionVec_5 = out_pt[2].exceptionVec[5];
  assign io_out_2_bits_exceptionVec_6 = out_pt[2].exceptionVec[6];
  assign io_out_2_bits_exceptionVec_7 = out_pt[2].exceptionVec[7];
  assign io_out_2_bits_exceptionVec_8 = out_pt[2].exceptionVec[8];
  assign io_out_2_bits_exceptionVec_9 = out_pt[2].exceptionVec[9];
  assign io_out_2_bits_exceptionVec_10 = out_pt[2].exceptionVec[10];
  assign io_out_2_bits_exceptionVec_11 = out_pt[2].exceptionVec[11];
  assign io_out_2_bits_exceptionVec_12 = out_pt[2].exceptionVec[12];
  assign io_out_2_bits_exceptionVec_13 = out_pt[2].exceptionVec[13];
  assign io_out_2_bits_exceptionVec_14 = out_pt[2].exceptionVec[14];
  assign io_out_2_bits_exceptionVec_15 = out_pt[2].exceptionVec[15];
  assign io_out_2_bits_exceptionVec_16 = out_pt[2].exceptionVec[16];
  assign io_out_2_bits_exceptionVec_17 = out_pt[2].exceptionVec[17];
  assign io_out_2_bits_exceptionVec_18 = out_pt[2].exceptionVec[18];
  assign io_out_2_bits_exceptionVec_19 = out_pt[2].exceptionVec[19];
  assign io_out_2_bits_exceptionVec_20 = out_pt[2].exceptionVec[20];
  assign io_out_2_bits_exceptionVec_21 = out_pt[2].exceptionVec[21];
  assign io_out_2_bits_exceptionVec_22 = out_pt[2].exceptionVec[22];
  assign io_out_2_bits_exceptionVec_23 = out_pt[2].exceptionVec[23];
  assign io_out_2_bits_isFetchMalAddr = out_pt[2].isFetchMalAddr;
  assign io_out_2_bits_hasException = o_hasException[2];
  assign io_out_2_bits_trigger = out_pt[2].trigger;
  assign io_out_2_bits_preDecodeInfo_valid = out_pt[2].preDecodeInfo_valid;
  assign io_out_2_bits_preDecodeInfo_isRVC = out_pt[2].preDecodeInfo_isRVC;
  assign io_out_2_bits_preDecodeInfo_brType = out_pt[2].preDecodeInfo_brType;
  assign io_out_2_bits_preDecodeInfo_isCall = out_pt[2].preDecodeInfo_isCall;
  assign io_out_2_bits_preDecodeInfo_isRet = out_pt[2].preDecodeInfo_isRet;
  assign io_out_2_bits_pred_taken = out_pt[2].pred_taken;
  assign io_out_2_bits_crossPageIPFFix = out_pt[2].crossPageIPFFix;
  assign io_out_2_bits_ftqPtr_flag = o_ftqFlag[2];
  assign io_out_2_bits_ftqPtr_value = o_ftqValue[2];
  assign io_out_2_bits_ftqOffset = o_ftqOff[2];
  assign io_out_2_bits_satpFlushFirstFetchFault = out_pt[2].satpFlushFirstFetchFault;
  assign io_out_2_bits_srcType_0 = o_srcType0[2];
  assign io_out_2_bits_srcType_1 = out_pt[2].srcType[1];
  assign io_out_2_bits_srcType_2 = out_pt[2].srcType[2];
  assign io_out_2_bits_srcType_3 = out_pt[2].srcType[3];
  assign io_out_2_bits_srcType_4 = out_pt[2].srcType[4];
  assign io_out_2_bits_ldest = out_pt[2].ldest;
  assign io_out_2_bits_fuType = out_pt[2].fuType;
  assign io_out_2_bits_fuOpType = out_pt[2].fuOpType;
  assign io_out_2_bits_rfWen = out_pt[2].rfWen;
  assign io_out_2_bits_fpWen = out_pt[2].fpWen;
  assign io_out_2_bits_vecWen = out_pt[2].vecWen;
  assign io_out_2_bits_v0Wen = out_pt[2].v0Wen;
  assign io_out_2_bits_vlWen = out_pt[2].vlWen;
  assign io_out_2_bits_isXSTrap = out_pt[2].isXSTrap;
  assign io_out_2_bits_waitForward = o_waitForward[2];
  assign io_out_2_bits_blockBackward = o_blockBackward[2];
  assign io_out_2_bits_flushPipe = out_pt[2].flushPipe;
  assign io_out_2_bits_canRobCompress = out_pt[2].canRobCompress;
  assign io_out_2_bits_selImm = out_pt[2].selImm;
  assign io_out_2_bits_imm = o_imm[2];
  assign io_out_2_bits_fpu_typeTagOut = out_pt[2].fpu_typeTagOut;
  assign io_out_2_bits_fpu_wflags = out_pt[2].fpu_wflags;
  assign io_out_2_bits_fpu_typ = out_pt[2].fpu_typ;
  assign io_out_2_bits_fpu_fmt = out_pt[2].fpu_fmt;
  assign io_out_2_bits_fpu_rm = out_pt[2].fpu_rm;
  assign io_out_2_bits_vpu_vill = out_pt[2].vpu_vill;
  assign io_out_2_bits_vpu_vma = out_pt[2].vpu_vma;
  assign io_out_2_bits_vpu_vta = out_pt[2].vpu_vta;
  assign io_out_2_bits_vpu_vsew = out_pt[2].vpu_vsew;
  assign io_out_2_bits_vpu_vlmul = out_pt[2].vpu_vlmul;
  assign io_out_2_bits_vpu_specVill = out_pt[2].vpu_specVill;
  assign io_out_2_bits_vpu_specVma = out_pt[2].vpu_specVma;
  assign io_out_2_bits_vpu_specVta = out_pt[2].vpu_specVta;
  assign io_out_2_bits_vpu_specVsew = out_pt[2].vpu_specVsew;
  assign io_out_2_bits_vpu_specVlmul = out_pt[2].vpu_specVlmul;
  assign io_out_2_bits_vpu_vm = out_pt[2].vpu_vm;
  assign io_out_2_bits_vpu_vstart = out_pt[2].vpu_vstart;
  assign io_out_2_bits_vpu_frm = out_pt[2].vpu_frm;
  assign io_out_2_bits_vpu_fpu_isFpToVecInst = out_pt[2].vpu_fpu_isFpToVecInst;
  assign io_out_2_bits_vpu_fpu_isFP32Instr = out_pt[2].vpu_fpu_isFP32Instr;
  assign io_out_2_bits_vpu_fpu_isFP64Instr = out_pt[2].vpu_fpu_isFP64Instr;
  assign io_out_2_bits_vpu_fpu_isReduction = out_pt[2].vpu_fpu_isReduction;
  assign io_out_2_bits_vpu_fpu_isFoldTo1_2 = out_pt[2].vpu_fpu_isFoldTo1_2;
  assign io_out_2_bits_vpu_fpu_isFoldTo1_4 = out_pt[2].vpu_fpu_isFoldTo1_4;
  assign io_out_2_bits_vpu_fpu_isFoldTo1_8 = out_pt[2].vpu_fpu_isFoldTo1_8;
  assign io_out_2_bits_vpu_vxrm = out_pt[2].vpu_vxrm;
  assign io_out_2_bits_vpu_vuopIdx = out_pt[2].vpu_vuopIdx;
  assign io_out_2_bits_vpu_lastUop = out_pt[2].vpu_lastUop;
  assign io_out_2_bits_vpu_vmask = out_pt[2].vpu_vmask;
  assign io_out_2_bits_vpu_vl = out_pt[2].vpu_vl;
  assign io_out_2_bits_vpu_nf = out_pt[2].vpu_nf;
  assign io_out_2_bits_vpu_veew = out_pt[2].vpu_veew;
  assign io_out_2_bits_vpu_isReverse = out_pt[2].vpu_isReverse;
  assign io_out_2_bits_vpu_isExt = out_pt[2].vpu_isExt;
  assign io_out_2_bits_vpu_isNarrow = out_pt[2].vpu_isNarrow;
  assign io_out_2_bits_vpu_isDstMask = out_pt[2].vpu_isDstMask;
  assign io_out_2_bits_vpu_isOpMask = out_pt[2].vpu_isOpMask;
  assign io_out_2_bits_vpu_isMove = out_pt[2].vpu_isMove;
  assign io_out_2_bits_vpu_isDependOldVd = out_pt[2].vpu_isDependOldVd;
  assign io_out_2_bits_vpu_isWritePartVd = out_pt[2].vpu_isWritePartVd;
  assign io_out_2_bits_vpu_isVleff = out_pt[2].vpu_isVleff;
  assign io_out_2_bits_vlsInstr = out_pt[2].vlsInstr;
  assign io_out_2_bits_wfflags = o_wfflags[2];
  assign io_out_2_bits_isMove = o_isMove[2];
  assign io_out_2_bits_uopIdx = out_pt[2].uopIdx;
  assign io_out_2_bits_isVset = out_pt[2].isVset;
  assign io_out_2_bits_firstUop = o_firstUop[2];
  assign io_out_2_bits_lastUop = o_lastUop[2];
  assign io_out_2_bits_numUops = o_numUops[2];
  assign io_out_2_bits_numWB = o_numWB[2];
  assign io_out_2_bits_commitType = out_pt[2].commitType;
  assign io_out_2_bits_psrc_0 = o_psrc[2][0];
  assign io_out_2_bits_psrc_1 = o_psrc[2][1];
  assign io_out_2_bits_psrc_2 = o_psrc[2][2];
  assign io_out_2_bits_psrc_3 = o_psrc[2][3];
  assign io_out_2_bits_psrc_4 = o_psrc[2][4];
  assign io_out_2_bits_pdest = o_pdest[2];
  assign io_out_2_bits_robIdx_flag = o_robIdx_flag[2];
  assign io_out_2_bits_robIdx_value = o_robIdx_value[2];
  assign io_out_2_bits_instrSize = o_instrSize[2];
  assign io_out_2_bits_dirtyFs = o_dirtyFs[2];
  assign io_out_2_bits_dirtyVs = o_dirtyVs[2];
  assign io_out_2_bits_traceBlockInPipe_itype = o_itype[2];
  assign io_out_2_bits_traceBlockInPipe_iretire = o_iretire[2];
  assign io_out_2_bits_traceBlockInPipe_ilastsize = o_ilastsize[2];
  assign io_out_2_bits_eliminatedMove = o_isMove[2];
  assign io_out_2_bits_snapshot = o_snapshot[2];
  assign io_out_2_bits_debugInfo_renameTime = o_renameTime[2];
  assign io_out_2_bits_debug_seqNum_seqNum = out_pt[2].debug_seqNum_seqNum;
  assign io_out_2_bits_debug_seqNum_uopIdx = out_pt[2].debug_seqNum_uopIdx;
  assign io_out_2_bits_debug_fuType = out_pt[2].debug_fuType;
  assign io_out_2_bits_debug_sim_trig = o_simTrig[2];
  assign io_out_2_bits_numLsElem = o_numLsElem[2];
  assign io_out_3_valid = out_v[3];
  assign io_out_3_bits_instr = out_pt[3].instr;
  assign io_out_3_bits_pc = out_pt[3].pc;
  assign io_out_3_bits_foldpc = out_pt[3].foldpc;
  assign io_out_3_bits_exceptionVec_0 = out_pt[3].exceptionVec[0];
  assign io_out_3_bits_exceptionVec_1 = out_pt[3].exceptionVec[1];
  assign io_out_3_bits_exceptionVec_2 = out_pt[3].exceptionVec[2];
  assign io_out_3_bits_exceptionVec_3 = out_pt[3].exceptionVec[3];
  assign io_out_3_bits_exceptionVec_4 = out_pt[3].exceptionVec[4];
  assign io_out_3_bits_exceptionVec_5 = out_pt[3].exceptionVec[5];
  assign io_out_3_bits_exceptionVec_6 = out_pt[3].exceptionVec[6];
  assign io_out_3_bits_exceptionVec_7 = out_pt[3].exceptionVec[7];
  assign io_out_3_bits_exceptionVec_8 = out_pt[3].exceptionVec[8];
  assign io_out_3_bits_exceptionVec_9 = out_pt[3].exceptionVec[9];
  assign io_out_3_bits_exceptionVec_10 = out_pt[3].exceptionVec[10];
  assign io_out_3_bits_exceptionVec_11 = out_pt[3].exceptionVec[11];
  assign io_out_3_bits_exceptionVec_12 = out_pt[3].exceptionVec[12];
  assign io_out_3_bits_exceptionVec_13 = out_pt[3].exceptionVec[13];
  assign io_out_3_bits_exceptionVec_14 = out_pt[3].exceptionVec[14];
  assign io_out_3_bits_exceptionVec_15 = out_pt[3].exceptionVec[15];
  assign io_out_3_bits_exceptionVec_16 = out_pt[3].exceptionVec[16];
  assign io_out_3_bits_exceptionVec_17 = out_pt[3].exceptionVec[17];
  assign io_out_3_bits_exceptionVec_18 = out_pt[3].exceptionVec[18];
  assign io_out_3_bits_exceptionVec_19 = out_pt[3].exceptionVec[19];
  assign io_out_3_bits_exceptionVec_20 = out_pt[3].exceptionVec[20];
  assign io_out_3_bits_exceptionVec_21 = out_pt[3].exceptionVec[21];
  assign io_out_3_bits_exceptionVec_22 = out_pt[3].exceptionVec[22];
  assign io_out_3_bits_exceptionVec_23 = out_pt[3].exceptionVec[23];
  assign io_out_3_bits_isFetchMalAddr = out_pt[3].isFetchMalAddr;
  assign io_out_3_bits_hasException = o_hasException[3];
  assign io_out_3_bits_trigger = out_pt[3].trigger;
  assign io_out_3_bits_preDecodeInfo_valid = out_pt[3].preDecodeInfo_valid;
  assign io_out_3_bits_preDecodeInfo_isRVC = out_pt[3].preDecodeInfo_isRVC;
  assign io_out_3_bits_preDecodeInfo_brType = out_pt[3].preDecodeInfo_brType;
  assign io_out_3_bits_preDecodeInfo_isCall = out_pt[3].preDecodeInfo_isCall;
  assign io_out_3_bits_preDecodeInfo_isRet = out_pt[3].preDecodeInfo_isRet;
  assign io_out_3_bits_pred_taken = out_pt[3].pred_taken;
  assign io_out_3_bits_crossPageIPFFix = out_pt[3].crossPageIPFFix;
  assign io_out_3_bits_ftqPtr_flag = o_ftqFlag[3];
  assign io_out_3_bits_ftqPtr_value = o_ftqValue[3];
  assign io_out_3_bits_ftqOffset = o_ftqOff[3];
  assign io_out_3_bits_satpFlushFirstFetchFault = out_pt[3].satpFlushFirstFetchFault;
  assign io_out_3_bits_srcType_0 = o_srcType0[3];
  assign io_out_3_bits_srcType_1 = out_pt[3].srcType[1];
  assign io_out_3_bits_srcType_2 = out_pt[3].srcType[2];
  assign io_out_3_bits_srcType_3 = out_pt[3].srcType[3];
  assign io_out_3_bits_srcType_4 = out_pt[3].srcType[4];
  assign io_out_3_bits_ldest = out_pt[3].ldest;
  assign io_out_3_bits_fuType = out_pt[3].fuType;
  assign io_out_3_bits_fuOpType = out_pt[3].fuOpType;
  assign io_out_3_bits_rfWen = out_pt[3].rfWen;
  assign io_out_3_bits_fpWen = out_pt[3].fpWen;
  assign io_out_3_bits_vecWen = out_pt[3].vecWen;
  assign io_out_3_bits_v0Wen = out_pt[3].v0Wen;
  assign io_out_3_bits_vlWen = out_pt[3].vlWen;
  assign io_out_3_bits_isXSTrap = out_pt[3].isXSTrap;
  assign io_out_3_bits_waitForward = o_waitForward[3];
  assign io_out_3_bits_blockBackward = o_blockBackward[3];
  assign io_out_3_bits_flushPipe = out_pt[3].flushPipe;
  assign io_out_3_bits_canRobCompress = out_pt[3].canRobCompress;
  assign io_out_3_bits_selImm = out_pt[3].selImm;
  assign io_out_3_bits_imm = o_imm[3];
  assign io_out_3_bits_fpu_typeTagOut = out_pt[3].fpu_typeTagOut;
  assign io_out_3_bits_fpu_wflags = out_pt[3].fpu_wflags;
  assign io_out_3_bits_fpu_typ = out_pt[3].fpu_typ;
  assign io_out_3_bits_fpu_fmt = out_pt[3].fpu_fmt;
  assign io_out_3_bits_fpu_rm = out_pt[3].fpu_rm;
  assign io_out_3_bits_vpu_vill = out_pt[3].vpu_vill;
  assign io_out_3_bits_vpu_vma = out_pt[3].vpu_vma;
  assign io_out_3_bits_vpu_vta = out_pt[3].vpu_vta;
  assign io_out_3_bits_vpu_vsew = out_pt[3].vpu_vsew;
  assign io_out_3_bits_vpu_vlmul = out_pt[3].vpu_vlmul;
  assign io_out_3_bits_vpu_specVill = out_pt[3].vpu_specVill;
  assign io_out_3_bits_vpu_specVma = out_pt[3].vpu_specVma;
  assign io_out_3_bits_vpu_specVta = out_pt[3].vpu_specVta;
  assign io_out_3_bits_vpu_specVsew = out_pt[3].vpu_specVsew;
  assign io_out_3_bits_vpu_specVlmul = out_pt[3].vpu_specVlmul;
  assign io_out_3_bits_vpu_vm = out_pt[3].vpu_vm;
  assign io_out_3_bits_vpu_vstart = out_pt[3].vpu_vstart;
  assign io_out_3_bits_vpu_frm = out_pt[3].vpu_frm;
  assign io_out_3_bits_vpu_fpu_isFpToVecInst = out_pt[3].vpu_fpu_isFpToVecInst;
  assign io_out_3_bits_vpu_fpu_isFP32Instr = out_pt[3].vpu_fpu_isFP32Instr;
  assign io_out_3_bits_vpu_fpu_isFP64Instr = out_pt[3].vpu_fpu_isFP64Instr;
  assign io_out_3_bits_vpu_fpu_isReduction = out_pt[3].vpu_fpu_isReduction;
  assign io_out_3_bits_vpu_fpu_isFoldTo1_2 = out_pt[3].vpu_fpu_isFoldTo1_2;
  assign io_out_3_bits_vpu_fpu_isFoldTo1_4 = out_pt[3].vpu_fpu_isFoldTo1_4;
  assign io_out_3_bits_vpu_fpu_isFoldTo1_8 = out_pt[3].vpu_fpu_isFoldTo1_8;
  assign io_out_3_bits_vpu_vxrm = out_pt[3].vpu_vxrm;
  assign io_out_3_bits_vpu_vuopIdx = out_pt[3].vpu_vuopIdx;
  assign io_out_3_bits_vpu_lastUop = out_pt[3].vpu_lastUop;
  assign io_out_3_bits_vpu_vmask = out_pt[3].vpu_vmask;
  assign io_out_3_bits_vpu_vl = out_pt[3].vpu_vl;
  assign io_out_3_bits_vpu_nf = out_pt[3].vpu_nf;
  assign io_out_3_bits_vpu_veew = out_pt[3].vpu_veew;
  assign io_out_3_bits_vpu_isReverse = out_pt[3].vpu_isReverse;
  assign io_out_3_bits_vpu_isExt = out_pt[3].vpu_isExt;
  assign io_out_3_bits_vpu_isNarrow = out_pt[3].vpu_isNarrow;
  assign io_out_3_bits_vpu_isDstMask = out_pt[3].vpu_isDstMask;
  assign io_out_3_bits_vpu_isOpMask = out_pt[3].vpu_isOpMask;
  assign io_out_3_bits_vpu_isMove = out_pt[3].vpu_isMove;
  assign io_out_3_bits_vpu_isDependOldVd = out_pt[3].vpu_isDependOldVd;
  assign io_out_3_bits_vpu_isWritePartVd = out_pt[3].vpu_isWritePartVd;
  assign io_out_3_bits_vpu_isVleff = out_pt[3].vpu_isVleff;
  assign io_out_3_bits_vlsInstr = out_pt[3].vlsInstr;
  assign io_out_3_bits_wfflags = o_wfflags[3];
  assign io_out_3_bits_isMove = o_isMove[3];
  assign io_out_3_bits_uopIdx = out_pt[3].uopIdx;
  assign io_out_3_bits_isVset = out_pt[3].isVset;
  assign io_out_3_bits_firstUop = o_firstUop[3];
  assign io_out_3_bits_lastUop = o_lastUop[3];
  assign io_out_3_bits_numUops = o_numUops[3];
  assign io_out_3_bits_numWB = o_numWB[3];
  assign io_out_3_bits_commitType = out_pt[3].commitType;
  assign io_out_3_bits_psrc_0 = o_psrc[3][0];
  assign io_out_3_bits_psrc_1 = o_psrc[3][1];
  assign io_out_3_bits_psrc_2 = o_psrc[3][2];
  assign io_out_3_bits_psrc_3 = o_psrc[3][3];
  assign io_out_3_bits_psrc_4 = o_psrc[3][4];
  assign io_out_3_bits_pdest = o_pdest[3];
  assign io_out_3_bits_robIdx_flag = o_robIdx_flag[3];
  assign io_out_3_bits_robIdx_value = o_robIdx_value[3];
  assign io_out_3_bits_instrSize = o_instrSize[3];
  assign io_out_3_bits_dirtyFs = o_dirtyFs[3];
  assign io_out_3_bits_dirtyVs = o_dirtyVs[3];
  assign io_out_3_bits_traceBlockInPipe_itype = o_itype[3];
  assign io_out_3_bits_traceBlockInPipe_iretire = o_iretire[3];
  assign io_out_3_bits_traceBlockInPipe_ilastsize = o_ilastsize[3];
  assign io_out_3_bits_eliminatedMove = o_isMove[3];
  assign io_out_3_bits_snapshot = o_snapshot[3];
  assign io_out_3_bits_debugInfo_renameTime = o_renameTime[3];
  assign io_out_3_bits_debug_seqNum_seqNum = out_pt[3].debug_seqNum_seqNum;
  assign io_out_3_bits_debug_seqNum_uopIdx = out_pt[3].debug_seqNum_uopIdx;
  assign io_out_3_bits_debug_fuType = out_pt[3].debug_fuType;
  assign io_out_3_bits_debug_sim_trig = o_simTrig[3];
  assign io_out_3_bits_numLsElem = o_numLsElem[3];
  assign io_out_4_valid = out_v[4];
  assign io_out_4_bits_instr = out_pt[4].instr;
  assign io_out_4_bits_pc = out_pt[4].pc;
  assign io_out_4_bits_foldpc = out_pt[4].foldpc;
  assign io_out_4_bits_exceptionVec_0 = out_pt[4].exceptionVec[0];
  assign io_out_4_bits_exceptionVec_1 = out_pt[4].exceptionVec[1];
  assign io_out_4_bits_exceptionVec_2 = out_pt[4].exceptionVec[2];
  assign io_out_4_bits_exceptionVec_3 = out_pt[4].exceptionVec[3];
  assign io_out_4_bits_exceptionVec_4 = out_pt[4].exceptionVec[4];
  assign io_out_4_bits_exceptionVec_5 = out_pt[4].exceptionVec[5];
  assign io_out_4_bits_exceptionVec_6 = out_pt[4].exceptionVec[6];
  assign io_out_4_bits_exceptionVec_7 = out_pt[4].exceptionVec[7];
  assign io_out_4_bits_exceptionVec_8 = out_pt[4].exceptionVec[8];
  assign io_out_4_bits_exceptionVec_9 = out_pt[4].exceptionVec[9];
  assign io_out_4_bits_exceptionVec_10 = out_pt[4].exceptionVec[10];
  assign io_out_4_bits_exceptionVec_11 = out_pt[4].exceptionVec[11];
  assign io_out_4_bits_exceptionVec_12 = out_pt[4].exceptionVec[12];
  assign io_out_4_bits_exceptionVec_13 = out_pt[4].exceptionVec[13];
  assign io_out_4_bits_exceptionVec_14 = out_pt[4].exceptionVec[14];
  assign io_out_4_bits_exceptionVec_15 = out_pt[4].exceptionVec[15];
  assign io_out_4_bits_exceptionVec_16 = out_pt[4].exceptionVec[16];
  assign io_out_4_bits_exceptionVec_17 = out_pt[4].exceptionVec[17];
  assign io_out_4_bits_exceptionVec_18 = out_pt[4].exceptionVec[18];
  assign io_out_4_bits_exceptionVec_19 = out_pt[4].exceptionVec[19];
  assign io_out_4_bits_exceptionVec_20 = out_pt[4].exceptionVec[20];
  assign io_out_4_bits_exceptionVec_21 = out_pt[4].exceptionVec[21];
  assign io_out_4_bits_exceptionVec_22 = out_pt[4].exceptionVec[22];
  assign io_out_4_bits_exceptionVec_23 = out_pt[4].exceptionVec[23];
  assign io_out_4_bits_isFetchMalAddr = out_pt[4].isFetchMalAddr;
  assign io_out_4_bits_hasException = o_hasException[4];
  assign io_out_4_bits_trigger = out_pt[4].trigger;
  assign io_out_4_bits_preDecodeInfo_valid = out_pt[4].preDecodeInfo_valid;
  assign io_out_4_bits_preDecodeInfo_isRVC = out_pt[4].preDecodeInfo_isRVC;
  assign io_out_4_bits_preDecodeInfo_brType = out_pt[4].preDecodeInfo_brType;
  assign io_out_4_bits_preDecodeInfo_isCall = out_pt[4].preDecodeInfo_isCall;
  assign io_out_4_bits_preDecodeInfo_isRet = out_pt[4].preDecodeInfo_isRet;
  assign io_out_4_bits_pred_taken = out_pt[4].pred_taken;
  assign io_out_4_bits_crossPageIPFFix = out_pt[4].crossPageIPFFix;
  assign io_out_4_bits_ftqPtr_flag = o_ftqFlag[4];
  assign io_out_4_bits_ftqPtr_value = o_ftqValue[4];
  assign io_out_4_bits_ftqOffset = o_ftqOff[4];
  assign io_out_4_bits_satpFlushFirstFetchFault = out_pt[4].satpFlushFirstFetchFault;
  assign io_out_4_bits_srcType_0 = o_srcType0[4];
  assign io_out_4_bits_srcType_1 = out_pt[4].srcType[1];
  assign io_out_4_bits_srcType_2 = out_pt[4].srcType[2];
  assign io_out_4_bits_srcType_3 = out_pt[4].srcType[3];
  assign io_out_4_bits_srcType_4 = out_pt[4].srcType[4];
  assign io_out_4_bits_ldest = out_pt[4].ldest;
  assign io_out_4_bits_fuType = out_pt[4].fuType;
  assign io_out_4_bits_fuOpType = out_pt[4].fuOpType;
  assign io_out_4_bits_rfWen = out_pt[4].rfWen;
  assign io_out_4_bits_fpWen = out_pt[4].fpWen;
  assign io_out_4_bits_vecWen = out_pt[4].vecWen;
  assign io_out_4_bits_v0Wen = out_pt[4].v0Wen;
  assign io_out_4_bits_vlWen = out_pt[4].vlWen;
  assign io_out_4_bits_isXSTrap = out_pt[4].isXSTrap;
  assign io_out_4_bits_waitForward = o_waitForward[4];
  assign io_out_4_bits_blockBackward = o_blockBackward[4];
  assign io_out_4_bits_flushPipe = out_pt[4].flushPipe;
  assign io_out_4_bits_canRobCompress = out_pt[4].canRobCompress;
  assign io_out_4_bits_selImm = out_pt[4].selImm;
  assign io_out_4_bits_imm = o_imm[4];
  assign io_out_4_bits_fpu_typeTagOut = out_pt[4].fpu_typeTagOut;
  assign io_out_4_bits_fpu_wflags = out_pt[4].fpu_wflags;
  assign io_out_4_bits_fpu_typ = out_pt[4].fpu_typ;
  assign io_out_4_bits_fpu_fmt = out_pt[4].fpu_fmt;
  assign io_out_4_bits_fpu_rm = out_pt[4].fpu_rm;
  assign io_out_4_bits_vpu_vill = out_pt[4].vpu_vill;
  assign io_out_4_bits_vpu_vma = out_pt[4].vpu_vma;
  assign io_out_4_bits_vpu_vta = out_pt[4].vpu_vta;
  assign io_out_4_bits_vpu_vsew = out_pt[4].vpu_vsew;
  assign io_out_4_bits_vpu_vlmul = out_pt[4].vpu_vlmul;
  assign io_out_4_bits_vpu_specVill = out_pt[4].vpu_specVill;
  assign io_out_4_bits_vpu_specVma = out_pt[4].vpu_specVma;
  assign io_out_4_bits_vpu_specVta = out_pt[4].vpu_specVta;
  assign io_out_4_bits_vpu_specVsew = out_pt[4].vpu_specVsew;
  assign io_out_4_bits_vpu_specVlmul = out_pt[4].vpu_specVlmul;
  assign io_out_4_bits_vpu_vm = out_pt[4].vpu_vm;
  assign io_out_4_bits_vpu_vstart = out_pt[4].vpu_vstart;
  assign io_out_4_bits_vpu_frm = out_pt[4].vpu_frm;
  assign io_out_4_bits_vpu_fpu_isFpToVecInst = out_pt[4].vpu_fpu_isFpToVecInst;
  assign io_out_4_bits_vpu_fpu_isFP32Instr = out_pt[4].vpu_fpu_isFP32Instr;
  assign io_out_4_bits_vpu_fpu_isFP64Instr = out_pt[4].vpu_fpu_isFP64Instr;
  assign io_out_4_bits_vpu_fpu_isReduction = out_pt[4].vpu_fpu_isReduction;
  assign io_out_4_bits_vpu_fpu_isFoldTo1_2 = out_pt[4].vpu_fpu_isFoldTo1_2;
  assign io_out_4_bits_vpu_fpu_isFoldTo1_4 = out_pt[4].vpu_fpu_isFoldTo1_4;
  assign io_out_4_bits_vpu_fpu_isFoldTo1_8 = out_pt[4].vpu_fpu_isFoldTo1_8;
  assign io_out_4_bits_vpu_vxrm = out_pt[4].vpu_vxrm;
  assign io_out_4_bits_vpu_vuopIdx = out_pt[4].vpu_vuopIdx;
  assign io_out_4_bits_vpu_lastUop = out_pt[4].vpu_lastUop;
  assign io_out_4_bits_vpu_vmask = out_pt[4].vpu_vmask;
  assign io_out_4_bits_vpu_vl = out_pt[4].vpu_vl;
  assign io_out_4_bits_vpu_nf = out_pt[4].vpu_nf;
  assign io_out_4_bits_vpu_veew = out_pt[4].vpu_veew;
  assign io_out_4_bits_vpu_isReverse = out_pt[4].vpu_isReverse;
  assign io_out_4_bits_vpu_isExt = out_pt[4].vpu_isExt;
  assign io_out_4_bits_vpu_isNarrow = out_pt[4].vpu_isNarrow;
  assign io_out_4_bits_vpu_isDstMask = out_pt[4].vpu_isDstMask;
  assign io_out_4_bits_vpu_isOpMask = out_pt[4].vpu_isOpMask;
  assign io_out_4_bits_vpu_isMove = out_pt[4].vpu_isMove;
  assign io_out_4_bits_vpu_isDependOldVd = out_pt[4].vpu_isDependOldVd;
  assign io_out_4_bits_vpu_isWritePartVd = out_pt[4].vpu_isWritePartVd;
  assign io_out_4_bits_vpu_isVleff = out_pt[4].vpu_isVleff;
  assign io_out_4_bits_vlsInstr = out_pt[4].vlsInstr;
  assign io_out_4_bits_wfflags = o_wfflags[4];
  assign io_out_4_bits_isMove = o_isMove[4];
  assign io_out_4_bits_uopIdx = out_pt[4].uopIdx;
  assign io_out_4_bits_isVset = out_pt[4].isVset;
  assign io_out_4_bits_firstUop = o_firstUop[4];
  assign io_out_4_bits_lastUop = o_lastUop[4];
  assign io_out_4_bits_numUops = o_numUops[4];
  assign io_out_4_bits_numWB = o_numWB[4];
  assign io_out_4_bits_commitType = out_pt[4].commitType;
  assign io_out_4_bits_psrc_0 = o_psrc[4][0];
  assign io_out_4_bits_psrc_1 = o_psrc[4][1];
  assign io_out_4_bits_psrc_2 = o_psrc[4][2];
  assign io_out_4_bits_psrc_3 = o_psrc[4][3];
  assign io_out_4_bits_psrc_4 = o_psrc[4][4];
  assign io_out_4_bits_pdest = o_pdest[4];
  assign io_out_4_bits_robIdx_flag = o_robIdx_flag[4];
  assign io_out_4_bits_robIdx_value = o_robIdx_value[4];
  assign io_out_4_bits_instrSize = o_instrSize[4];
  assign io_out_4_bits_dirtyFs = o_dirtyFs[4];
  assign io_out_4_bits_dirtyVs = o_dirtyVs[4];
  assign io_out_4_bits_traceBlockInPipe_itype = o_itype[4];
  assign io_out_4_bits_traceBlockInPipe_iretire = o_iretire[4];
  assign io_out_4_bits_traceBlockInPipe_ilastsize = o_ilastsize[4];
  assign io_out_4_bits_eliminatedMove = o_isMove[4];
  assign io_out_4_bits_snapshot = o_snapshot[4];
  assign io_out_4_bits_debugInfo_renameTime = o_renameTime[4];
  assign io_out_4_bits_debug_seqNum_seqNum = out_pt[4].debug_seqNum_seqNum;
  assign io_out_4_bits_debug_seqNum_uopIdx = out_pt[4].debug_seqNum_uopIdx;
  assign io_out_4_bits_debug_fuType = out_pt[4].debug_fuType;
  assign io_out_4_bits_debug_sim_trig = o_simTrig[4];
  assign io_out_4_bits_numLsElem = o_numLsElem[4];
  assign io_out_5_valid = out_v[5];
  assign io_out_5_bits_instr = out_pt[5].instr;
  assign io_out_5_bits_pc = out_pt[5].pc;
  assign io_out_5_bits_foldpc = out_pt[5].foldpc;
  assign io_out_5_bits_exceptionVec_0 = out_pt[5].exceptionVec[0];
  assign io_out_5_bits_exceptionVec_1 = out_pt[5].exceptionVec[1];
  assign io_out_5_bits_exceptionVec_2 = out_pt[5].exceptionVec[2];
  assign io_out_5_bits_exceptionVec_3 = out_pt[5].exceptionVec[3];
  assign io_out_5_bits_exceptionVec_4 = out_pt[5].exceptionVec[4];
  assign io_out_5_bits_exceptionVec_5 = out_pt[5].exceptionVec[5];
  assign io_out_5_bits_exceptionVec_6 = out_pt[5].exceptionVec[6];
  assign io_out_5_bits_exceptionVec_7 = out_pt[5].exceptionVec[7];
  assign io_out_5_bits_exceptionVec_8 = out_pt[5].exceptionVec[8];
  assign io_out_5_bits_exceptionVec_9 = out_pt[5].exceptionVec[9];
  assign io_out_5_bits_exceptionVec_10 = out_pt[5].exceptionVec[10];
  assign io_out_5_bits_exceptionVec_11 = out_pt[5].exceptionVec[11];
  assign io_out_5_bits_exceptionVec_12 = out_pt[5].exceptionVec[12];
  assign io_out_5_bits_exceptionVec_13 = out_pt[5].exceptionVec[13];
  assign io_out_5_bits_exceptionVec_14 = out_pt[5].exceptionVec[14];
  assign io_out_5_bits_exceptionVec_15 = out_pt[5].exceptionVec[15];
  assign io_out_5_bits_exceptionVec_16 = out_pt[5].exceptionVec[16];
  assign io_out_5_bits_exceptionVec_17 = out_pt[5].exceptionVec[17];
  assign io_out_5_bits_exceptionVec_18 = out_pt[5].exceptionVec[18];
  assign io_out_5_bits_exceptionVec_19 = out_pt[5].exceptionVec[19];
  assign io_out_5_bits_exceptionVec_20 = out_pt[5].exceptionVec[20];
  assign io_out_5_bits_exceptionVec_21 = out_pt[5].exceptionVec[21];
  assign io_out_5_bits_exceptionVec_22 = out_pt[5].exceptionVec[22];
  assign io_out_5_bits_exceptionVec_23 = out_pt[5].exceptionVec[23];
  assign io_out_5_bits_isFetchMalAddr = out_pt[5].isFetchMalAddr;
  assign io_out_5_bits_hasException = o_hasException[5];
  assign io_out_5_bits_trigger = out_pt[5].trigger;
  assign io_out_5_bits_preDecodeInfo_valid = out_pt[5].preDecodeInfo_valid;
  assign io_out_5_bits_preDecodeInfo_isRVC = out_pt[5].preDecodeInfo_isRVC;
  assign io_out_5_bits_preDecodeInfo_brType = out_pt[5].preDecodeInfo_brType;
  assign io_out_5_bits_preDecodeInfo_isCall = out_pt[5].preDecodeInfo_isCall;
  assign io_out_5_bits_preDecodeInfo_isRet = out_pt[5].preDecodeInfo_isRet;
  assign io_out_5_bits_pred_taken = out_pt[5].pred_taken;
  assign io_out_5_bits_crossPageIPFFix = out_pt[5].crossPageIPFFix;
  assign io_out_5_bits_ftqPtr_flag = o_ftqFlag[5];
  assign io_out_5_bits_ftqPtr_value = o_ftqValue[5];
  assign io_out_5_bits_ftqOffset = o_ftqOff[5];
  assign io_out_5_bits_satpFlushFirstFetchFault = out_pt[5].satpFlushFirstFetchFault;
  assign io_out_5_bits_srcType_0 = o_srcType0[5];
  assign io_out_5_bits_srcType_1 = out_pt[5].srcType[1];
  assign io_out_5_bits_srcType_2 = out_pt[5].srcType[2];
  assign io_out_5_bits_srcType_3 = out_pt[5].srcType[3];
  assign io_out_5_bits_srcType_4 = out_pt[5].srcType[4];
  assign io_out_5_bits_ldest = out_pt[5].ldest;
  assign io_out_5_bits_fuType = out_pt[5].fuType;
  assign io_out_5_bits_fuOpType = out_pt[5].fuOpType;
  assign io_out_5_bits_rfWen = out_pt[5].rfWen;
  assign io_out_5_bits_fpWen = out_pt[5].fpWen;
  assign io_out_5_bits_vecWen = out_pt[5].vecWen;
  assign io_out_5_bits_v0Wen = out_pt[5].v0Wen;
  assign io_out_5_bits_vlWen = out_pt[5].vlWen;
  assign io_out_5_bits_isXSTrap = out_pt[5].isXSTrap;
  assign io_out_5_bits_waitForward = o_waitForward[5];
  assign io_out_5_bits_blockBackward = o_blockBackward[5];
  assign io_out_5_bits_flushPipe = out_pt[5].flushPipe;
  assign io_out_5_bits_canRobCompress = out_pt[5].canRobCompress;
  assign io_out_5_bits_selImm = out_pt[5].selImm;
  assign io_out_5_bits_imm = o_imm[5];
  assign io_out_5_bits_fpu_typeTagOut = out_pt[5].fpu_typeTagOut;
  assign io_out_5_bits_fpu_wflags = out_pt[5].fpu_wflags;
  assign io_out_5_bits_fpu_typ = out_pt[5].fpu_typ;
  assign io_out_5_bits_fpu_fmt = out_pt[5].fpu_fmt;
  assign io_out_5_bits_fpu_rm = out_pt[5].fpu_rm;
  assign io_out_5_bits_vpu_vill = out_pt[5].vpu_vill;
  assign io_out_5_bits_vpu_vma = out_pt[5].vpu_vma;
  assign io_out_5_bits_vpu_vta = out_pt[5].vpu_vta;
  assign io_out_5_bits_vpu_vsew = out_pt[5].vpu_vsew;
  assign io_out_5_bits_vpu_vlmul = out_pt[5].vpu_vlmul;
  assign io_out_5_bits_vpu_specVill = out_pt[5].vpu_specVill;
  assign io_out_5_bits_vpu_specVma = out_pt[5].vpu_specVma;
  assign io_out_5_bits_vpu_specVta = out_pt[5].vpu_specVta;
  assign io_out_5_bits_vpu_specVsew = out_pt[5].vpu_specVsew;
  assign io_out_5_bits_vpu_specVlmul = out_pt[5].vpu_specVlmul;
  assign io_out_5_bits_vpu_vm = out_pt[5].vpu_vm;
  assign io_out_5_bits_vpu_vstart = out_pt[5].vpu_vstart;
  assign io_out_5_bits_vpu_frm = out_pt[5].vpu_frm;
  assign io_out_5_bits_vpu_fpu_isFpToVecInst = out_pt[5].vpu_fpu_isFpToVecInst;
  assign io_out_5_bits_vpu_fpu_isFP32Instr = out_pt[5].vpu_fpu_isFP32Instr;
  assign io_out_5_bits_vpu_fpu_isFP64Instr = out_pt[5].vpu_fpu_isFP64Instr;
  assign io_out_5_bits_vpu_fpu_isReduction = out_pt[5].vpu_fpu_isReduction;
  assign io_out_5_bits_vpu_fpu_isFoldTo1_2 = out_pt[5].vpu_fpu_isFoldTo1_2;
  assign io_out_5_bits_vpu_fpu_isFoldTo1_4 = out_pt[5].vpu_fpu_isFoldTo1_4;
  assign io_out_5_bits_vpu_fpu_isFoldTo1_8 = out_pt[5].vpu_fpu_isFoldTo1_8;
  assign io_out_5_bits_vpu_vxrm = out_pt[5].vpu_vxrm;
  assign io_out_5_bits_vpu_vuopIdx = out_pt[5].vpu_vuopIdx;
  assign io_out_5_bits_vpu_lastUop = out_pt[5].vpu_lastUop;
  assign io_out_5_bits_vpu_vmask = out_pt[5].vpu_vmask;
  assign io_out_5_bits_vpu_vl = out_pt[5].vpu_vl;
  assign io_out_5_bits_vpu_nf = out_pt[5].vpu_nf;
  assign io_out_5_bits_vpu_veew = out_pt[5].vpu_veew;
  assign io_out_5_bits_vpu_isReverse = out_pt[5].vpu_isReverse;
  assign io_out_5_bits_vpu_isExt = out_pt[5].vpu_isExt;
  assign io_out_5_bits_vpu_isNarrow = out_pt[5].vpu_isNarrow;
  assign io_out_5_bits_vpu_isDstMask = out_pt[5].vpu_isDstMask;
  assign io_out_5_bits_vpu_isOpMask = out_pt[5].vpu_isOpMask;
  assign io_out_5_bits_vpu_isMove = out_pt[5].vpu_isMove;
  assign io_out_5_bits_vpu_isDependOldVd = out_pt[5].vpu_isDependOldVd;
  assign io_out_5_bits_vpu_isWritePartVd = out_pt[5].vpu_isWritePartVd;
  assign io_out_5_bits_vpu_isVleff = out_pt[5].vpu_isVleff;
  assign io_out_5_bits_vlsInstr = out_pt[5].vlsInstr;
  assign io_out_5_bits_wfflags = o_wfflags[5];
  assign io_out_5_bits_isMove = o_isMove[5];
  assign io_out_5_bits_uopIdx = out_pt[5].uopIdx;
  assign io_out_5_bits_isVset = out_pt[5].isVset;
  assign io_out_5_bits_firstUop = o_firstUop[5];
  assign io_out_5_bits_lastUop = o_lastUop[5];
  assign io_out_5_bits_numUops = o_numUops[5];
  assign io_out_5_bits_numWB = o_numWB[5];
  assign io_out_5_bits_commitType = out_pt[5].commitType;
  assign io_out_5_bits_psrc_0 = o_psrc[5][0];
  assign io_out_5_bits_psrc_1 = o_psrc[5][1];
  assign io_out_5_bits_psrc_2 = o_psrc[5][2];
  assign io_out_5_bits_psrc_3 = o_psrc[5][3];
  assign io_out_5_bits_psrc_4 = o_psrc[5][4];
  assign io_out_5_bits_pdest = o_pdest[5];
  assign io_out_5_bits_robIdx_flag = o_robIdx_flag[5];
  assign io_out_5_bits_robIdx_value = o_robIdx_value[5];
  assign io_out_5_bits_instrSize = o_instrSize[5];
  assign io_out_5_bits_dirtyFs = o_dirtyFs[5];
  assign io_out_5_bits_dirtyVs = o_dirtyVs[5];
  assign io_out_5_bits_traceBlockInPipe_itype = o_itype[5];
  assign io_out_5_bits_traceBlockInPipe_iretire = o_iretire[5];
  assign io_out_5_bits_traceBlockInPipe_ilastsize = o_ilastsize[5];
  assign io_out_5_bits_eliminatedMove = o_isMove[5];
  assign io_out_5_bits_snapshot = o_snapshot[5];
  assign io_out_5_bits_debugInfo_renameTime = o_renameTime[5];
  assign io_out_5_bits_debug_seqNum_seqNum = out_pt[5].debug_seqNum_seqNum;
  assign io_out_5_bits_debug_seqNum_uopIdx = out_pt[5].debug_seqNum_uopIdx;
  assign io_out_5_bits_debug_fuType = out_pt[5].debug_fuType;
  assign io_out_5_bits_debug_sim_trig = o_simTrig[5];
  assign io_out_5_bits_numLsElem = o_numLsElem[5];
  assign io_stallReason_out_reason_0 = sr_out[0];
  assign io_stallReason_out_reason_1 = sr_out[1];
  assign io_stallReason_out_reason_2 = sr_out[2];
  assign io_stallReason_out_reason_3 = sr_out[3];
  assign io_stallReason_out_reason_4 = sr_out[4];
  assign io_stallReason_out_reason_5 = sr_out[5];
  assign io_perf_0_value = perf_v[0];
  assign io_perf_1_value = perf_v[1];
  assign io_perf_2_value = perf_v[2];
  assign io_perf_3_value = perf_v[3];
  assign io_perf_4_value = perf_v[4];
  assign io_perf_5_value = perf_v[5];
  assign io_perf_6_value = perf_v[6];
  assign io_perf_7_value = perf_v[7];
  assign io_perf_8_value = perf_v[8];
  assign io_perf_9_value = perf_v[9];
  assign io_perf_10_value = perf_v[10];
  assign io_perf_11_value = perf_v[11];
  assign io_perf_12_value = perf_v[12];
  assign io_perf_13_value = perf_v[13];
  assign io_perf_14_value = perf_v[14];
  assign io_perf_15_value = perf_v[15];
  assign io_perf_16_value = perf_v[16];
  assign io_perf_17_value = perf_v[17];
  assign io_perf_18_value = perf_v[18];
  assign io_perf_19_value = perf_v[19];
  assign io_perf_20_value = perf_v[20];
  assign io_perf_21_value = perf_v[21];
  assign io_perf_22_value = perf_v[22];
  assign io_perf_23_value = perf_v[23];
  assign io_perf_24_value = perf_v[24];
  assign io_perf_25_value = perf_v[25];
  assign io_perf_26_value = perf_v[26];
  assign io_perf_27_value = perf_v[27];
  assign io_perf_28_value = perf_v[28];
  assign io_perf_29_value = perf_v[29];

  xs_Rename_core u_core (
    .clock(clock), .reset(reset),
    .io_redirect_valid(io_redirect_valid),
    .io_redirect_bits_robIdx_flag(io_redirect_bits_robIdx_flag),
    .io_redirect_bits_robIdx_value(io_redirect_bits_robIdx_value),
    .io_redirect_bits_level(io_redirect_bits_level),
    .io_redirect_bits_debugIsCtrl(io_redirect_bits_debugIsCtrl),
    .io_redirect_bits_debugIsMemVio(io_redirect_bits_debugIsMemVio),
    .io_rabCommits_isCommit(io_rabCommits_isCommit), .io_rabCommits_isWalk(io_rabCommits_isWalk),
    .io_rabCommits_commitValid(rab_cv), .io_rabCommits_walkValid(rab_wv),
    .io_rabCommits_info_rfWen(rab_rf), .io_rabCommits_info_fpWen(rab_fp),
    .io_rabCommits_info_vecWen(rab_vec), .io_rabCommits_info_v0Wen(rab_v0),
    .io_rabCommits_info_vlWen(rab_vl), .io_rabCommits_info_isMove(rab_mv),
    .io_singleStep(io_singleStep),
    .io_in_bits(in_b), .io_in_valid(in_v), .io_in_ready(in_r),
    .io_fusionInfo_rs2FromRs1(fi_rs2FromRs1), .io_fusionInfo_rs2FromRs2(fi_rs2FromRs2), .io_fusionInfo_rs2FromZero(fi_rs2FromZero),
    .io_intReadPorts(intRd), .io_fpReadPorts(fpRd), .io_vecReadPorts(vecRd),
    .io_v0ReadPorts(v0Rd), .io_vlReadPorts(vlRd),
    .io_intRenamePorts(intRP), .io_fpRenamePorts(fpRP), .io_vecRenamePorts(vecRP),
    .io_v0RenamePorts_wen(v0RP_wen), .io_v0RenamePorts_data(v0RP_data),
    .io_vlRenamePorts_wen(vlRP_wen), .io_vlRenamePorts_data(vlRP_data),
    .io_int_old_pdest(int_oldpd), .io_fp_old_pdest(fp_oldpd), .io_vec_old_pdest(vec_oldpd),
    .io_v0_old_pdest(v0_oldpd), .io_vl_old_pdest(vl_oldpd), .io_int_need_free(int_nf),
    .io_out_valid(out_v), .io_out_ready(out_r), .io_out_passthru(out_pt),
    .io_out_psrc(o_psrc), .io_out_pdest(o_pdest),
    .io_out_robIdx_flag(o_robIdx_flag), .io_out_robIdx_value(o_robIdx_value),
    .io_out_isMove_o(o_isMove), .io_out_snapshot(o_snapshot),
    .io_out_hasException(o_hasException), .io_out_srcType0(o_srcType0),
    .io_out_imm(o_imm), .io_out_debugInfo_renameTime(o_renameTime),
    .io_out_instrSize(o_instrSize), .io_out_dirtyFs(o_dirtyFs), .io_out_dirtyVs(o_dirtyVs),
    .io_out_debug_sim_trig(o_simTrig),
    .io_out_itype(o_itype), .io_out_iretire(o_iretire), .io_out_ilastsize(o_ilastsize),
    .io_out_lastUop_o(o_lastUop), .io_out_numUops_o(o_numUops), .io_out_numWB_o(o_numWB),
    .io_out_wfflags_o(o_wfflags), .io_out_numLsElem(o_numLsElem),
    .io_out_ftqPtr_flag_o(o_ftqFlag), .io_out_ftqPtr_value_o(o_ftqValue), .io_out_ftqOffset_o(o_ftqOff),
    .io_out_firstUop_o(o_firstUop), .io_out_waitForward_o(o_waitForward), .io_out_blockBackward_o(o_blockBackward),
    .io_snpt_snptDeq(io_snpt_snptDeq), .io_snpt_useSnpt(io_snpt_useSnpt),
    .io_snpt_snptSelect(io_snpt_snptSelect), .io_snpt_flushVec(flushv),
    .io_snptLastEnq_valid(io_snptLastEnq_valid), .io_snptLastEnq_bits_flag(io_snptLastEnq_bits_flag),
    .io_snptLastEnq_bits_value(io_snptLastEnq_bits_value), .io_snptIsFull(io_snptIsFull),
    .io_debug_int_rat(dbg_int_rat),
    .io_stallReason_in_reason(sr_in), .io_stallReason_out_backReason_valid(io_stallReason_out_backReason_valid),
    .io_stallReason_in_backReason_valid(io_stallReason_in_backReason_valid),
    .io_stallReason_in_backReason_bits(io_stallReason_in_backReason_bits),
    .io_stallReason_out_reason(sr_out), .io_perf_value(perf_v)
  );
endmodule
