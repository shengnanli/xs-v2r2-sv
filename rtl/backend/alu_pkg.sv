// =============================================================================
// alu_pkg —— 香山 V2R2(昆明湖) 整数 ALU 的类型与运算编码定义
// -----------------------------------------------------------------------------
// 本包对应 Scala 源 `xiangshan.ALUOpType`(package.scala)与 `fu/Alu.scala`。
// ALU 是后端整数执行单元里最核心的叶子功能单元:单周期、纯组合,覆盖
//   RV64GC 的加减/比较/移位/逻辑 + Zb*(位操作) + Zicond(条件置零)。
//
// 关键设计点:fuOpType 的 7 位编码 **不是随意分配**,而是把"结果走哪条通道"
// 直接编进高 3 位 func[6:4],把"通道内部选哪种运算/变体"编进低 4 位 func[3:0]。
// 于是顶层只需用 func[6:4] 做 6 选 1 的通道选择(见 AluResSel),各通道内部
// 再用低位做小范围 mux。这样译码器无需查找表,选择树天然分层,利于时序。
//
//   func[6:4]  通道
//   ---------  -------------------------------------------------------------
//   000        移位通道 shiftRes (sll/srl/sra/rol/ror + bclr/bset/binv/bext)
//   001        字(32bit)通道 wordRes (addw/subw/sllw/.../rolw, 结果 SEXT 到 64)
//   010        加法通道 addRes   (add/adduw/oddadd/lui32add/srNadd/shNadd)
//   011        比较通道 compareRes(sub/sltu/slt/max/min/maxu/minu)
//   100/101/110 杂项通道 miscRes (逻辑 and/or/xor/orcb + Zbb 字节/半字操作)
//   111        Zicond 通道 condRes (czero.eqz / czero.nez)
// =============================================================================
package alu_pkg;

  localparam int unsigned XLEN = 64;

  // fuOpType 物理位宽:顶层端口给到 9 位(FuOpTypeWidth),ALU 只解释低 7 位。
  localparam int unsigned ALU_OP_W = 7;

  // ---------------------------------------------------------------------------
  // ALUOpType 枚举:与 Scala object ALUOpType 的 7 位编码逐位一致。
  // 命名 = RISC-V 指令/Zb* 扩展助记符。注释给出语义(src1=rs1, src2=rs2)。
  // ---------------------------------------------------------------------------
  typedef enum logic [ALU_OP_W-1:0] {
    // -- 000xxxx 移位通道 -----------------------------------------------------
    OP_SLLIUW   = 7'b000_0000, // ZEXT(src1[31:0]) << shamt
    OP_SLL      = 7'b000_0001, // src1 << src2[5:0]
    OP_BCLR     = 7'b000_0010, // src1 & ~(1<<src2[5:0])
    OP_BSET     = 7'b000_0011, // src1 |  (1<<src2[5:0])
    OP_BINV     = 7'b000_0100, // src1 ^  (1<<src2[5:0])
    OP_SRL      = 7'b000_0101, // src1 >> src2[5:0] (逻辑)
    OP_BEXT     = 7'b000_0110, // (src1 >> src2[5:0])[0]
    OP_SRA      = 7'b000_0111, // src1 >> src2[5:0] (算术)
    OP_ROL      = 7'b000_1001, // 循环左移
    OP_ROR      = 7'b000_1011, // 循环右移
    // -- 001xxxx 字(32bit)通道,结果 SEXT 到 64 ------------------------------
    OP_ADDW     = 7'b001_0000, // SEXT((src1+src2)[31:0])
    OP_ODDADDW  = 7'b001_0001, // SEXT((src1[0]+src2)[31:0])
    OP_SUBW     = 7'b001_0010, // SEXT((src1-src2)[31:0])
    OP_LUI32ADDW= 7'b001_0011, // SEXT(SEXT(src2[11:0]) + {src2[31:12],12'b0})
    OP_ADDWBIT  = 7'b001_0100, // (src1+src2)[0]
    OP_ADDWBYTE = 7'b001_0101, // ZEXT((src1+src2)[7:0])
    OP_ADDWZEXTH= 7'b001_0110, // ZEXT((src1+src2)[15:0])
    OP_ADDWSEXTH= 7'b001_0111, // SEXT((src1+src2)[15:0])
    OP_SLLW     = 7'b001_1000, // SEXT((src1<<src2)[31:0])
    OP_SRLW     = 7'b001_1001, // SEXT((src1[31:0]>>src2)[31:0])
    OP_SRAW     = 7'b001_1010, // SEXT 算术右移字
    OP_ROLW     = 7'b001_1100, // 字循环左移
    OP_RORW     = 7'b001_1101, // 字循环右移
    // -- 010xxxx 加法通道 -----------------------------------------------------
    OP_ADDUW    = 7'b010_0000, // src1[31:0] + src2
    OP_ADD      = 7'b010_0001, // src1 + src2
    OP_ODDADD   = 7'b010_0010, // src1[0] + src2
    OP_LUI32ADD = 7'b010_0011, // SEXT(src2[11:0]) + {src2[63:12],12'b0}
    OP_SR29ADD  = 7'b010_0100, // src1[63:29] + src2
    OP_SR30ADD  = 7'b010_0101, // src1[63:30] + src2
    OP_SR31ADD  = 7'b010_0110, // src1[63:31] + src2
    OP_SR32ADD  = 7'b010_0111, // src1[63:32] + src2
    OP_SH1ADDUW = 7'b010_1000, // {src1[31:0],1'b0} + src2
    OP_SH1ADD   = 7'b010_1001, // {src1[62:0],1'b0} + src2
    OP_SH2ADDUW = 7'b010_1010,
    OP_SH2ADD   = 7'b010_1011,
    OP_SH3ADDUW = 7'b010_1100,
    OP_SH3ADD   = 7'b010_1101,
    OP_SH4ADD   = 7'b010_1111, // {src1[59:0],4'b0} + src2
    // -- 011xxxx 比较通道 -----------------------------------------------------
    OP_SUB      = 7'b011_0000,
    OP_SLTU     = 7'b011_0001,
    OP_SLT      = 7'b011_0010,
    OP_MAXU     = 7'b011_0100,
    OP_MINU     = 7'b011_0101,
    OP_MAX      = 7'b011_0110,
    OP_MIN      = 7'b011_0111,
    // -- 111xxxx Zicond 通道 --------------------------------------------------
    OP_CZERO_EQZ= 7'b111_0100, // src2==0 ? 0 : src1
    OP_CZERO_NEZ= 7'b111_0110, // src2!=0 ? 0 : src1
    // -- 100xxxx/101xxxx/110xxxx 杂项通道 ------------------------------------
    OP_AND      = 7'b100_0000,
    OP_ANDN     = 7'b100_0001,
    OP_OR       = 7'b100_0010,
    OP_ORN      = 7'b100_0011,
    OP_XOR      = 7'b100_0100,
    OP_XNOR     = 7'b100_0101,
    OP_ORCB     = 7'b100_0110, // 按字节 OR-combine
    OP_SEXTB    = 7'b100_1000,
    OP_PACKH    = 7'b100_1001,
    OP_SEXTH    = 7'b100_1010,
    OP_PACKW    = 7'b100_1011,
    OP_REVB     = 7'b101_0000, // 每字节内 bit 翻转
    OP_REV8     = 7'b101_0001, // 字节序翻转
    OP_PACK     = 7'b101_0010, // {src2[31:0],src1[31:0]}
    OP_ORH48    = 7'b101_0011, // {src1[63:8],8'b0} | src2
    OP_SZEWL1   = 7'b101_1000, // {0, src1[31:0], 1'b0}  (移位加用)
    OP_SZEWL2   = 7'b101_1001,
    OP_SZEWL3   = 7'b101_1010,
    OP_BYTE2    = 7'b101_1011, // ZEXT(src1[15:8])
    OP_ANDLSB   = 7'b110_0000, // (src1 & src2)[0]   —— 逻辑结果取最低位
    OP_ANDZEXTH = 7'b110_0001, // ZEXT((src1 & src2)[15:0])
    OP_ORLSB    = 7'b110_0010,
    OP_ORZEXTH  = 7'b110_0011,
    OP_XORLSB   = 7'b110_0100,
    OP_XORZEXTH = 7'b110_0101,
    OP_ORCBLSB  = 7'b110_0110,
    OP_ORCBZEXTH= 7'b110_0111
  } alu_op_e;

  // 顶层 6 选 1 的"结果通道"枚举,对应 func[6:4]。
  typedef enum logic [2:0] {
    CH_SHIFT   = 3'b000, // func[4]=0 走移位 (func[4]=1 时走 word)
    CH_WORD    = 3'b001,
    CH_ADD     = 3'b010,
    CH_COMPARE = 3'b011,
    CH_MISC_L  = 3'b100, // 100/101/110 都进 misc 通道
    CH_MISC_H  = 3'b101,
    CH_MISC_X  = 3'b110,
    CH_COND    = 3'b111  // Zicond
  } alu_chan_e;

endpackage : alu_pkg
