// =============================================================================
// uopinfogen_pkg —— 香山 V2R2(昆明湖) UopInfoGen 的类型/常量定义
// -----------------------------------------------------------------------------
// 对应 Scala 源:xiangshan.backend.decode.UopInfoGen(含两张 QMC 真值表
//   strdiedLSNumOfUopTable / indexedLSNumOfUopTable)。
//
// 【UopInfoGen 在做什么】
//   译码阶段对一条**向量/特殊指令**算出它要拆成多少个微操作(uop):
//     numOfUop : 该指令展开的 uop 总数(向量按 LMUL/EMUL/NF 等展开,可达数十)。
//     numOfWB  : 写回(writeback)次数。除 AMOCAS 是 numOfUop>>1 外都等于 numOfUop。
//     lmul     : 译出的 LMUL 整数倍数(1/2/4/8),供下游展开使用。
//     isComplex: 该指令是否"复杂"(向量算术/向量访存/AMOCAS),需走拆分通道。
//   它只看一个 PreInfo(由前级译码给出的预解析信息),不看完整指令。
//
// 【为什么 numOfUop 这么多分支】
//   RVV 指令的 uop 数取决于 split 类型(vvv/vfv/load/store/slide/gather/...)与
//   LMUL/EMUL/NF/SEW 的组合。Scala 用一个大 MuxLookup(typeOfSplit -> 表达式)
//   罗列了每种 split 的 uop 数公式。这里按同一组公式重写(每个 split 一条 case)。
//
// 【两张 LS 表】
//   strided/indexed 向量访存的 uop 数是 (emul,nf)/(emul,lmul,nf) 的函数,Scala 用
//   QMCMinimizer 把生成规则压成真值表。这里**不抄真值表**,而是按 Scala 生成这些
//   表项的算法(见 strided_ls_uops / indexed_ls_uops 函数)直接计算,语义等价且可读。
// =============================================================================
package uopinfogen_pkg;

  localparam int unsigned MAX_UOP_SIZE = 65;
  localparam int unsigned UOP_W = $clog2(MAX_UOP_SIZE + 1); // 7

  // ---------------------------------------------------------------------------
  // UopSplitType(6 位):指令的微操作拆分类型。与 Scala object UopSplitType 同码。
  // (仅列出 numOfUop 表里用到/会出现的取值;命名沿用 Scala。)
  // ---------------------------------------------------------------------------
  typedef enum logic [5:0] {
    SPLIT_SCA_SIM        = 6'b000000, // 标量/简单(numOfUop=1)
    SPLIT_VEC_MVNR       = 6'b000100, // vmvnr (= 6'h04)
    SPLIT_VSET           = 6'b010001, // vset  (= 6'h11)
    SPLIT_VEC_VVV        = 6'b010010, // 6'h12
    SPLIT_VEC_VXV        = 6'b010011, // 6'h13
    SPLIT_VEC_0XV        = 6'b010100, // 6'h14
    SPLIT_VEC_VVW        = 6'b010101, // 6'h15
    SPLIT_VEC_WVW        = 6'b010110, // 6'h16
    SPLIT_VEC_VXW        = 6'b010111, // 6'h17
    SPLIT_VEC_WXW        = 6'b011000, // 6'h18
    SPLIT_VEC_WVV        = 6'b011001, // 6'h19
    SPLIT_VEC_WXV        = 6'b011010, // 6'h1A
    SPLIT_VEC_EXT2       = 6'b011011, // 6'h1B
    SPLIT_VEC_EXT4       = 6'b011100, // 6'h1C
    SPLIT_VEC_EXT8       = 6'b011101, // 6'h1D
    SPLIT_VEC_VVM        = 6'b011110, // 6'h1E
    SPLIT_VEC_VXM        = 6'b011111, // 6'h1F
    SPLIT_VEC_SLIDE1UP   = 6'b100000, // 6'h20
    SPLIT_VEC_FSLIDE1UP  = 6'b100001, // 6'h21
    SPLIT_VEC_SLIDE1DOWN = 6'b100010, // 6'h22
    SPLIT_VEC_FSLIDE1DOWN= 6'b100011, // 6'h23
    SPLIT_VEC_VRED       = 6'b100100, // 6'h24
    SPLIT_VEC_SLIDEUP    = 6'b100101, // 6'h25
    SPLIT_VEC_SLIDEDOWN  = 6'b100111, // 6'h27
    SPLIT_VEC_M0X        = 6'b101001, // 6'h29
    SPLIT_VEC_MVV        = 6'b101010, // 6'h2A
    SPLIT_VEC_VWW        = 6'b101100, // 6'h2C
    SPLIT_VEC_RGATHER    = 6'b101101, // 6'h2D
    SPLIT_VEC_RGATHER_VX = 6'b101110, // 6'h2E
    SPLIT_VEC_RGATHEREI16= 6'b101111, // 6'h2F
    SPLIT_VEC_COMPRESS   = 6'b110000, // 6'h30
    SPLIT_VEC_US_LDST    = 6'b110001, // 6'h31
    SPLIT_VEC_S_LDST     = 6'b110010, // 6'h32
    SPLIT_VEC_I_LDST     = 6'b110011, // 6'h33
    SPLIT_VEC_US_FF_LD   = 6'b110100, // 6'h34
    SPLIT_AMO_CAS_W      = 6'b110101, // 6'h35
    SPLIT_AMO_CAS_D      = 6'b110110, // 6'h36
    SPLIT_AMO_CAS_Q      = 6'b110111, // 6'h37
    SPLIT_VEC_VFV        = 6'b111000, // 6'h38
    SPLIT_VEC_VFW        = 6'b111001, // 6'h39
    SPLIT_VEC_WFW        = 6'b111010, // 6'h3A
    SPLIT_VEC_VFM        = 6'b111011, // 6'h3B
    SPLIT_VEC_VFRED      = 6'b111100, // 6'h3C
    SPLIT_VEC_VFREDOSUM  = 6'b111101  // 6'h3D
  } uop_split_e;

  // VLmul(3 位)编码。
  localparam logic [2:0] LMUL_M1 = 3'b000, LMUL_M2 = 3'b001, LMUL_M4 = 3'b010, LMUL_M8 = 3'b011;
  // VSew(2 位)编码。
  localparam logic [1:0] SEW_E8 = 2'b00, SEW_E16 = 2'b01, SEW_E32 = 2'b10, SEW_E64 = 2'b11;

  // 输入预解析信息(聚合 golden 扁平端口)。
  typedef struct packed {
    logic        isVecArith;
    logic        isVecMem;
    logic        isAmoCAS;
    logic [5:0]  typeOfSplit;
    logic [1:0]  vsew;
    logic [2:0]  vlmul;
    logic [2:0]  vwidth;   // eew
    logic [2:0]  nf;
    logic [2:0]  vmvn;     // vmvnr 的寄存器组数-1
    logic        isVlsr;   // 整寄存器 load/store
    logic        isVlsm;   // 掩码 load/store
  } preinfo_t;

  // 输出 uop 信息。
  typedef struct packed {
    logic [UOP_W-1:0] numOfUop;
    logic [UOP_W-1:0] numOfWB;
    logic [3:0]       lmul;
  } uopinfo_t;

endpackage
