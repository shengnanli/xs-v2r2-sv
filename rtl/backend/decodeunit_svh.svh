// ============================================================================
// decodeunit_svh.svh —— DecodeUnit 可读核的接口 bundle 定义
// 把 golden 展平的一大堆 io_deq_decodedInst_* 聚合成有意义的 struct。
// 顶层 wrapper 再把它拆回 golden 扁平端口供 UT/FM 对接。
// ============================================================================
`ifndef DECODEUNIT_SVH
`define DECODEUNIT_SVH

// 来自前端的 vtype（向量类型）—— 译码时透传进 vpu 字段
typedef struct packed {
  logic       illegal;
  logic       vma;
  logic       vta;
  logic [1:0] vsew;
  logic [2:0] vlmul;
} xs_du_vtype_t;

// CSR 送来的「非法指令」判定位（fs/vs off、fence、hlsv、frm、cbo 等）
typedef struct packed {
  logic sfenceVMA;
  logic sfencePart;
  logic hfenceGVMA;
  logic hfenceVVMA;
  logic hlsv;
  logic fsIsOff;
  logic vsIsOff;
  logic wfi;
  logic wrs_nto;
  logic frm;
  logic cboZ;
  logic cboCF;
  logic cboI;
} xs_du_csr_illegal_t;

// CSR 送来的「虚拟指令」判定位
typedef struct packed {
  logic sfenceVMA;
  logic sfencePart;
  logic hfence;
  logic hlsv;
  logic wfi;
  logic wrs_nto;
  logic cboZ;
  logic cboCF;
  logic cboI;
} xs_du_csr_virtual_t;

// 译码核心输出（聚合 DecodedInst 的译码相关字段）
typedef struct packed {
  logic [3:0]  srcType0, srcType1, srcType2, srcType3, srcType4;
  logic [5:0]  lsrc0, lsrc1, lsrc2, lsrc3, lsrc4, ldest;
  logic [34:0] fuType;
  logic [8:0]  fuOpType;
  logic        rfWen, fpWen, vecWen;
  logic        isXSTrap, waitForward, blockBackward, flushPipe, canRobCompress;
  logic [3:0]  selImm;
  logic [21:0] imm;
  logic [5:0]  uopSplitType;
  logic [2:0]  fpu_rm;
  logic        fpu_wflags;
  logic [1:0]  fpu_typeTagOut, fpu_typ, fpu_fmt;
  logic        exc_illegal, exc_virtual;
  logic        isComplex;
  logic [6:0]  numOfUop, numOfWB;
  logic [3:0]  lmul;
  // ---- 派生明细字段（exceptionVec / vpu / isMove / isVset / commitType / wfflags）----
  logic        excVec2;        // 非法指令异常 (exceptionVec[2])
  logic        excVec22;       // 虚拟指令异常 (exceptionVec[22])
  logic        wfflags;        // 写 fflags
  logic        isMove;         // 可消除搬运
  logic        isVset;         // vset 指令
  logic [2:0]  commitType;     // 提交类型
  logic        vlsInstr;       // 向量访存指令
  logic        vpu_isReverse, vpu_isExt, vpu_isNarrow, vpu_isDstMask, vpu_isOpMask;
  logic        vpu_isDependOldVd, vpu_isWritePartVd, vpu_isVleff;
} xs_du_decode_out_t;

`endif
