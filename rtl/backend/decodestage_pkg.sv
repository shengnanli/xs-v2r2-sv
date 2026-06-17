// ============================================================================
// decodestage_pkg.sv —— 香山 V2R2（昆明湖）后端译码级 DecodeStage 公共类型 / 参数
// ----------------------------------------------------------------------------
// 设计意图来源：src/main/scala/xiangshan/backend/decode/DecodeStage.scala
//
// 本包把 DecodeStage 在 golden 里被 firtool 展平成上百根 io_*_bits_* 标量的几个
// 关键 bundle，重新聚合成有意义的 SystemVerilog struct，供可读核
// xs_DecodeStage_core 以「按指令/按通道」的结构化方式处理 6 路并行译码、复杂指令
// 路由、流水握手。顶层 wrapper 再把这些 struct 拆回 golden 扁平端口。
//
// 主要类型：
//   * decoded_inst_t —— 一条已译码微操作 (uop) 的完整控制信息（DecodedInst）。
//       这是译码级在整条流水里流动的核心载荷：fuType/fuOpType/源宿寄存器/立即数/
//       各写回使能/向量(vpu)与浮点(fpu)控制位/异常向量 等。简单译码器
//       (DecodeUnit) 产出其中绝大部分；uopIdx/firstUop/lastUop/numWB/v0Wen/vlWen/
//       vpu_fpu_isFoldTo1 这几项对简单指令由本级补常量，对复杂指令由
//       DecodeUnitComp 给出。
//   * uop_info_t    —— 复杂指令拆分所需的 uop 数量信息（numOfUop/numOfWB/lmul）。
//   * vtype_t       —— 向量类型 vtype（VTypeGen 旁路给各译码器与复杂译码器）。
// ============================================================================
package decodestage_pkg;

  // --------------------------------------------------------------------------
  // 结构参数（取自 backendParams / XSCore 配置，KunmingHu V2R2）
  // --------------------------------------------------------------------------
  localparam int DECODE_WIDTH = 6;  // 前端每拍最多送 6 条指令并行译码
  localparam int RENAME_WIDTH = 6;  // 下游 Rename 每拍最多接收 6 条 uop
  // RAT 读口数（每通道）：整数 2 源、浮点 3 源、向量 3 源（vs1/vs2/old_vd）
  localparam int NUM_INT_RAT  = 2;
  localparam int NUM_FP_RAT   = 3;
  localparam int NUM_VEC_RAT  = 3;

  // RatReadPort.addr 的物理位宽（firtool 按各自逻辑寄存器编号空间定宽，实际只用低
  // 6 位 = lsrc）。保持与 golden 端口位宽一致，便于 wrapper 直连。
  localparam int INT_RAT_ADDR_W = 32;
  localparam int FP_RAT_ADDR_W  = 34;
  localparam int VEC_RAT_ADDR_W = 47;

  localparam int FU_TYPE_W      = 35; // FuType one-hot 宽度
  localparam int FU_OP_TYPE_W   = 9;
  localparam int IMM_W          = 22;
  localparam int STALL_REASON_W = 3; // StallReason 枚举宽度

  // --------------------------------------------------------------------------
  // vtype_t —— 向量类型（VTypeGen 输出，旁路到各译码器 / 复杂译码器）
  // --------------------------------------------------------------------------
  typedef struct packed {
    logic       illegal;
    logic       vma;
    logic       vta;
    logic [1:0] vsew;
    logic [2:0] vlmul;
  } vtype_t;

  // --------------------------------------------------------------------------
  // uop_info_t —— 复杂指令拆分信息（简单译码器顺带给出，本级择一送复杂译码器）
  // --------------------------------------------------------------------------
  typedef struct packed {
    logic [6:0] numOfUop;
    logic [6:0] numOfWB;
    logic [3:0] lmul;
  } uop_info_t;

  // --------------------------------------------------------------------------
  // decoded_inst_t —— 一条已译码微操作的完整控制信息（DecodedInst）
  // ----------------------------------------------------------------------------
  // 字段顺序贴近 golden io_out_*_bits_* 的出现次序，便于交叉核对；但聚合成结构体
  // 后，glue 逻辑可以按「整条指令」搬运（finalDecodedInst = 复杂/简单择一）。
  // 注意 exceptionVec 在 golden 里以离散标量出现且 index 22/3 不连续，这里用数组
  // 表达 0..23（共 24 位），缺失位（如前端入口没有的 exceptionVec_22）由译码器补。
  // --------------------------------------------------------------------------
  typedef struct packed {
    // -- 透传自前端 ctrlFlow 的字段 --
    logic [31:0] instr;
    logic [9:0]  foldpc;
    logic [23:0] exceptionVec;       // EX_* 异常向量（index 0..23）
    logic        isFetchMalAddr;
    logic [3:0]  trigger;
    logic        preDecodeInfo_isRVC;
    logic [1:0]  preDecodeInfo_brType;
    logic        pred_taken;
    logic        crossPageIPFFix;
    logic        ftqPtr_flag;
    logic [5:0]  ftqPtr_value;
    logic [3:0]  ftqOffset;

    // -- 源/宿寄存器与类型（packed struct 内用 packed 数组维度）--
    logic [4:0][3:0] srcType;        // srcType[0..4]（4 位 SrcType 编码）
    logic [2:0][5:0] lsrc;           // lsrc[0..2]（逻辑源寄存器号）
    logic [5:0]      ldest;

    // -- 功能单元与立即数 --
    logic [FU_TYPE_W-1:0]    fuType;
    logic [FU_OP_TYPE_W-1:0] fuOpType;
    logic [3:0]              selImm;
    logic [IMM_W-1:0]        imm;

    // -- 写回使能 / 控制 flag --
    logic        rfWen;
    logic        fpWen;
    logic        vecWen;
    logic        v0Wen;
    logic        vlWen;
    logic        isXSTrap;
    logic        waitForward;
    logic        blockBackward;
    logic        flushPipe;
    logic        canRobCompress;
    logic        vlsInstr;
    logic        wfflags;
    logic        isMove;
    logic        isVset;

    // -- 浮点控制位 (fpu) --
    logic [1:0]  fpu_typeTagOut;
    logic        fpu_wflags;
    logic [1:0]  fpu_typ;
    logic [1:0]  fpu_fmt;
    logic [2:0]  fpu_rm;

    // -- 向量控制位 (vpu) --
    logic        vpu_vill;
    logic        vpu_vma;
    logic        vpu_vta;
    logic [1:0]  vpu_vsew;
    logic [2:0]  vpu_vlmul;
    logic        vpu_specVill;
    logic        vpu_specVma;
    logic        vpu_specVta;
    logic [1:0]  vpu_specVsew;
    logic [2:0]  vpu_specVlmul;
    logic        vpu_vm;
    logic [7:0]  vpu_vstart;
    logic        vpu_fpu_isFoldTo1_2;
    logic        vpu_fpu_isFoldTo1_4;
    logic        vpu_fpu_isFoldTo1_8;
    logic [2:0]  vpu_nf;
    logic [1:0]  vpu_veew;
    logic        vpu_isExt;
    logic        vpu_isNarrow;
    logic        vpu_isDstMask;
    logic        vpu_isOpMask;
    logic        vpu_isDependOldVd;
    logic        vpu_isWritePartVd;
    logic        vpu_isVleff;
    logic        vpu_isReverse;       // 源操作数反序（lsrc/srcType0<->1 互换），仅内部用

    // -- uop 拆分信息（简单指令补常量，复杂指令由 DecodeUnitComp 给出）--
    logic [6:0]  uopIdx;
    logic [5:0]  uopSplitType;
    logic        firstUop;
    logic        lastUop;
    logic [6:0]  numWB;
    logic [2:0]  commitType;
  } decoded_inst_t;

endpackage : decodestage_pkg
