// =============================================================================
// DecodeUnit.sv —— 简单译码器：把一条 32 位 RISC-V 指令译成 DecodedInst（纯组合）
// -----------------------------------------------------------------------------
// 设计源:XiangShan src/main/scala/xiangshan/backend/decode/DecodeUnit.scala
//        （译码表还散在 VecDecoder.scala / rocket-chip Instructions.scala /
//          xiangshan/package.scala 与 yunsuan/package.scala 的 OpType 常量里）
// golden 对照:G1-canonical/golden-rtl/DecodeUnit.sv（6,252 行 / 172 端口 / 0 个寄存器 /
//             2 个子模块实例 FPDecoder + UopInfoGen）
//
// ★ 它在流水线里的位置 ★
// DecodeStage 每拍从 IBuffer 收 6 条 StaticInst，例化 6 份本模块（decoders_0..5）各译一条；
// 译出的 DecodedInst 直接送 Rename，isComplex/uopInfo 则告诉 DecodeStage 这条指令要不要
// 交给 DecodeUnitComp 去拆成多个 uop。本模块**没有任何寄存器**，输入到输出全是组合逻辑。
//
// ★ 核心机制：一张按表序优先查的译码表 + 一小段"表外修正" ★
//   1. 译码表（§3）：Chisel 里 12 个 DecodeConstants 对象拼成的
//      Array[(BitPat, XSDecode)]，由 ListLookup 查——**第一条命中的行胜出**。本文件把它
//      写成一个 `casez (instr)`（casez 同样是第一条命中胜出），每行一条指令、列顺序与
//      Scala 的 XSDecode(src1, src2, src3, fu, fuOp, selImm, uopSplitType, 标志…) 一致，
//      可以逐行对着 Scala 读。整张表由 verif/ut/DecodeUnit/gen.py 从 Scala 源码机械
//      生成，并与 golden 的 717 条匹配项按表序逐条对过账。
//   2. 表外修正（§5）：Chisel 的 when 链——csrr vl 改成 vsetvl、csrr vlenb 改成 addi、
//      prefetch.{i,r,w} 改成 load、zimop 改成 x0 加立即数；再由 §9 的 Mux1H/MuxCase 决定
//      最终 fuType / fuOpType / imm（向量分段访存改成 vsegldu/vsegstu、fli 的 fuOpType 带
//      rs1、cbo.inval 可按 CSR 要求降级成 cbo.flush）。
//   3. 非法/虚拟指令判据（§6）：CSR 给 24 个"当前特权态下这类指令非法"的标志，本模块
//      按 fuType/fuOpType 把它们落到具体指令上，与 IBuffer 送来的 exceptionVec 合并。
//   4. 向量属性（§8）：vtype/vstart 透传成 vpu.*，再按指令集合判出 isNarrow/isDstMask/
//      isDependOldVd/isWritePartVd 等，交给 UopInfoGen 算 uop 数与 isComplex。
//
// ★ golden 与 Chisel 字面不一致处（一律以 golden 为准）★
//   (a) DecodedInst 的 lsrc 是 Vec(5)，golden 只剩 lsrc_0..2：lsrc(3)=V0_IDX、lsrc(4)=Vl_IDX
//       是常数，父模块不读，firtool 删了端口；本核不造这两根。
//   (b) 输入 exceptionVec 没有第 3/22 位（本模块整段改写 breakPoint / virtualInstr，
//       入口无读者被删）；uopIdx/firstUop/lastUop/numUops/numWB/v0Wen/vlWen 这些常数
//       赋值也都没有端口。
//   (c) HasCMO 在本配置下为 true，cbo 的非法判据只看 fromCSR。
//   (d) 译码表里 PAUSE 那一行被它前面的 FENCE 整个遮住（FENCE 的模式覆盖 PAUSE 的编码），
//       表序优先下永远轮不到——golden 里同样如此，本核照抄，不"修"。
//   (e) yunsuan 里 LiteralCat 行尾的 "b…" 注释有陈旧的（vadd_vv 注释写 000000000，
//       按 SINT=1 拼出来是 001000000）；fuOpType 常量一律按源码求值，不按注释。
//
// ★ 复位域 ★ 本模块无寄存器，无复位；两轮 initreg 对它没有区分度（UT 仍按规矩跑两轮）。
//
// ★ 子模块（golden 2 个实例，本核原样例化，不黑盒）★
//   · FPDecoder  fpDecoder  —— 浮点控制字段 typeTagOut/wflags/typ/fmt/rm（rtl/backend/FPDecoder.sv）
//   · UopInfoGen uopInfoGen —— numOfUop/numOfWB/lmul/isComplex（rtl/backend/UopInfoGen.sv）
// =============================================================================
// 本文件导航（共 3343 行；按"一个 golden 模块一个文件"的规范不拆分，用下面的分节定位）：
//   L20    设计源:XiangShan src/main/scala/xiangshan/backend/decode/DecodeUnit
//   L67    §1 decodeunit_pkg —— 本模块私有的类型与编码常量
//   L1700  §2 xs_DecodeUnit_core —— 可读核
//   L1716  §2.1 指令字段
//   L1740  §3 译码表 —— 表序优先
//   L2601  §4 指令形状判据
//   L2651  §5 表外修正
//   L2699  §6 非法指令 / 虚拟指令判据
//   L2766  §7 立即数：按 selImm 从指令里抽最少位
//   L2787  §8 向量属性
//   L2802  §9 子模块
//   L2834  §10 出口
//   L2836  fuType：Mux1H
//   L2967  §11 DecodeUnit —— golden 同名 wrapper
//

// -----------------------------------------------------------------------------
// §1 decodeunit_pkg —— 本模块私有的类型与编码常量
// -----------------------------------------------------------------------------
package decodeunit_pkg;

  // ---- SrcType（4 位；xiangshan/package.scala）----
  // imm / pc / no / DC / X 在 Scala 里都是 0，这里保留各自的名字：表里写的是**意图**
  // （pc 型指令的 src1 是 pc、DC 是"不关心"），值相同不等于含义相同。
  localparam logic [3:0] SRC_IMM = 4'b0000;
  localparam logic [3:0] SRC_PC  = 4'b0000;
  localparam logic [3:0] SRC_NO  = 4'b0000;   // 不读寄存器，但也不许是任意值
  localparam logic [3:0] SRC_DC  = 4'b0000;   // Don't Care
  localparam logic [3:0] SRC_X   = 4'b0000;   // BitPat 通配（bitPatToUInt 后为 0）
  localparam logic [3:0] SRC_XP  = 4'b0001;   // 整数寄存器
  localparam logic [3:0] SRC_REG = 4'b0001;   // = xp 的别名（Scala: def reg = this.xp）
  localparam logic [3:0] SRC_FP  = 4'b0010;   // 浮点寄存器
  localparam logic [3:0] SRC_VP  = 4'b0100;   // 向量寄存器
  localparam logic [3:0] SRC_V0  = 4'b1000;   // v0 掩码

  // ---- FuType（35 位 one-hot；位号 = backend/fu/FuType.scala 的 addType 顺序）----
  localparam int FUI_JMP = 0,  FUI_BRH = 1,  FUI_I2F = 2,  FUI_I2V = 3,  FUI_F2V = 4,  FUI_CSR = 5,
                 FUI_ALU = 6,  FUI_MUL = 7,  FUI_DIV = 8,  FUI_FENCE = 9, FUI_BKU = 10,
                 FUI_FALU = 11, FUI_FMAC = 12, FUI_FCVT = 13, FUI_FDIVSQRT = 14,
                 FUI_LDU = 15, FUI_STU = 16, FUI_MOU = 17,
                 FUI_VIPU = 18, FUI_VIALUF = 19, FUI_VPPU = 20, FUI_VIMAC = 21, FUI_VIDIV = 22,
                 FUI_VFPU = 23, FUI_VFALU = 24, FUI_VFMA = 25, FUI_VFDIV = 26, FUI_VFCVT = 27,
                 FUI_VSETIWI = 28, FUI_VSETIWF = 29, FUI_VSETFWF = 30,
                 FUI_VLDU = 31, FUI_VSTU = 32, FUI_VSEGLDU = 33, FUI_VSEGSTU = 34;
  localparam int FU_W = 35;
  localparam logic [FU_W-1:0] FU_X        = '0;
  localparam logic [FU_W-1:0] FU_JMP      = FU_W'(1) << FUI_JMP;
  localparam logic [FU_W-1:0] FU_BRH      = FU_W'(1) << FUI_BRH;
  localparam logic [FU_W-1:0] FU_I2F      = FU_W'(1) << FUI_I2F;
  localparam logic [FU_W-1:0] FU_I2V      = FU_W'(1) << FUI_I2V;
  localparam logic [FU_W-1:0] FU_F2V      = FU_W'(1) << FUI_F2V;
  localparam logic [FU_W-1:0] FU_CSR      = FU_W'(1) << FUI_CSR;
  localparam logic [FU_W-1:0] FU_ALU      = FU_W'(1) << FUI_ALU;
  localparam logic [FU_W-1:0] FU_MUL      = FU_W'(1) << FUI_MUL;
  localparam logic [FU_W-1:0] FU_DIV      = FU_W'(1) << FUI_DIV;
  localparam logic [FU_W-1:0] FU_FENCE    = FU_W'(1) << FUI_FENCE;
  localparam logic [FU_W-1:0] FU_BKU      = FU_W'(1) << FUI_BKU;
  localparam logic [FU_W-1:0] FU_FALU     = FU_W'(1) << FUI_FALU;
  localparam logic [FU_W-1:0] FU_FMAC     = FU_W'(1) << FUI_FMAC;
  localparam logic [FU_W-1:0] FU_FCVT     = FU_W'(1) << FUI_FCVT;
  localparam logic [FU_W-1:0] FU_FDIVSQRT = FU_W'(1) << FUI_FDIVSQRT;
  localparam logic [FU_W-1:0] FU_LDU      = FU_W'(1) << FUI_LDU;
  localparam logic [FU_W-1:0] FU_STU      = FU_W'(1) << FUI_STU;
  localparam logic [FU_W-1:0] FU_MOU      = FU_W'(1) << FUI_MOU;
  localparam logic [FU_W-1:0] FU_VIPU     = FU_W'(1) << FUI_VIPU;
  localparam logic [FU_W-1:0] FU_VIALUF   = FU_W'(1) << FUI_VIALUF;
  localparam logic [FU_W-1:0] FU_VPPU     = FU_W'(1) << FUI_VPPU;
  localparam logic [FU_W-1:0] FU_VIMAC    = FU_W'(1) << FUI_VIMAC;
  localparam logic [FU_W-1:0] FU_VIDIV    = FU_W'(1) << FUI_VIDIV;
  localparam logic [FU_W-1:0] FU_VFPU     = FU_W'(1) << FUI_VFPU;
  localparam logic [FU_W-1:0] FU_VFALU    = FU_W'(1) << FUI_VFALU;
  localparam logic [FU_W-1:0] FU_VFMA     = FU_W'(1) << FUI_VFMA;
  localparam logic [FU_W-1:0] FU_VFDIV    = FU_W'(1) << FUI_VFDIV;
  localparam logic [FU_W-1:0] FU_VFCVT    = FU_W'(1) << FUI_VFCVT;
  localparam logic [FU_W-1:0] FU_VSETIWI  = FU_W'(1) << FUI_VSETIWI;
  localparam logic [FU_W-1:0] FU_VSETIWF  = FU_W'(1) << FUI_VSETIWF;
  localparam logic [FU_W-1:0] FU_VSETFWF  = FU_W'(1) << FUI_VSETFWF;
  localparam logic [FU_W-1:0] FU_VLDU     = FU_W'(1) << FUI_VLDU;
  localparam logic [FU_W-1:0] FU_VSTU     = FU_W'(1) << FUI_VSTU;
  localparam logic [FU_W-1:0] FU_VSEGLDU  = FU_W'(1) << FUI_VSEGLDU;
  localparam logic [FU_W-1:0] FU_VSEGSTU  = FU_W'(1) << FUI_VSEGSTU;

  // ---- SelImm（4 位；立即数格式选择，也用 INVALID_INSTR 标记"表里没有这条指令"）----
  localparam logic [3:0] SELIMM_X      = 4'b0000;   // BitPat 通配（表里 SelImm.X）
  localparam logic [3:0] IMM_SB        = 4'b0001;
  localparam logic [3:0] IMM_U         = 4'b0010;
  localparam logic [3:0] IMM_UJ        = 4'b0011;
  localparam logic [3:0] IMM_I         = 4'b0100;
  localparam logic [3:0] IMM_Z         = 4'b0101;   // csr：{rd, rs1/uimm, csr 地址}
  localparam logic [3:0] INVALID_INSTR = 4'b0110;   // 译码表查无此指令 -> 非法指令
  localparam logic [3:0] IMM_X         = 4'b0111;
  localparam logic [3:0] IMM_B6        = 4'b1000;
  localparam logic [3:0] IMM_OPIVIS    = 4'b1001;   // 向量 5 位有符号立即数
  localparam logic [3:0] IMM_OPIVIU    = 4'b1010;   // 向量 5 位无符号立即数
  localparam logic [3:0] IMM_LUI32     = 4'b1011;
  localparam logic [3:0] IMM_VSETVLI   = 4'b1100;
  localparam logic [3:0] IMM_VSETIVLI  = 4'b1101;
  localparam logic [3:0] IMM_S         = 4'b1110;
  localparam logic [3:0] IMM_VRORVI    = 4'b1111;

  // ---- UopSplitType（6 位；复杂指令怎么拆，交给 UopInfoGen / DecodeUnitComp）----
  localparam logic [5:0] SPLIT_X                = 6'b000000;   // BitPat 通配
  localparam logic [5:0] SPLIT_SCA_SIM          = 6'b000000;
  localparam logic [5:0] SPLIT_VEC_MVNR         = 6'b000100;   // vmv<nr>r.v
  localparam logic [5:0] SPLIT_VSET             = 6'b010001;
  localparam logic [5:0] SPLIT_VEC_VVV          = 6'b010010;
  localparam logic [5:0] SPLIT_VEC_VXV          = 6'b010011;
  localparam logic [5:0] SPLIT_VEC_0XV          = 6'b010100;
  localparam logic [5:0] SPLIT_VEC_VVW          = 6'b010101;
  localparam logic [5:0] SPLIT_VEC_WVW          = 6'b010110;
  localparam logic [5:0] SPLIT_VEC_VXW          = 6'b010111;
  localparam logic [5:0] SPLIT_VEC_WXW          = 6'b011000;
  localparam logic [5:0] SPLIT_VEC_WVV          = 6'b011001;
  localparam logic [5:0] SPLIT_VEC_WXV          = 6'b011010;
  localparam logic [5:0] SPLIT_VEC_EXT2         = 6'b011011;
  localparam logic [5:0] SPLIT_VEC_EXT4         = 6'b011100;
  localparam logic [5:0] SPLIT_VEC_EXT8         = 6'b011101;
  localparam logic [5:0] SPLIT_VEC_VVM          = 6'b011110;
  localparam logic [5:0] SPLIT_VEC_VXM          = 6'b011111;
  localparam logic [5:0] SPLIT_VEC_SLIDE1UP     = 6'b100000;
  localparam logic [5:0] SPLIT_VEC_FSLIDE1UP    = 6'b100001;
  localparam logic [5:0] SPLIT_VEC_SLIDE1DOWN   = 6'b100010;
  localparam logic [5:0] SPLIT_VEC_FSLIDE1DOWN  = 6'b100011;
  localparam logic [5:0] SPLIT_VEC_VRED         = 6'b100100;
  localparam logic [5:0] SPLIT_VEC_SLIDEUP      = 6'b100101;
  localparam logic [5:0] SPLIT_VEC_SLIDEDOWN    = 6'b100111;
  localparam logic [5:0] SPLIT_VEC_M0X          = 6'b101001;
  localparam logic [5:0] SPLIT_VEC_MVV          = 6'b101010;
  localparam logic [5:0] SPLIT_VEC_VWW          = 6'b101100;
  localparam logic [5:0] SPLIT_VEC_RGATHER      = 6'b101101;
  localparam logic [5:0] SPLIT_VEC_RGATHER_VX   = 6'b101110;
  localparam logic [5:0] SPLIT_VEC_RGATHEREI16  = 6'b101111;
  localparam logic [5:0] SPLIT_VEC_COMPRESS     = 6'b110000;
  localparam logic [5:0] SPLIT_VEC_US_LDST      = 6'b110001;
  localparam logic [5:0] SPLIT_VEC_S_LDST       = 6'b110010;
  localparam logic [5:0] SPLIT_VEC_I_LDST       = 6'b110011;
  localparam logic [5:0] SPLIT_VEC_US_FF_LD     = 6'b110100;
  localparam logic [5:0] SPLIT_AMO_CAS_W        = 6'b110101;
  localparam logic [5:0] SPLIT_AMO_CAS_D        = 6'b110110;
  localparam logic [5:0] SPLIT_AMO_CAS_Q        = 6'b110111;
  localparam logic [5:0] SPLIT_VEC_VFV          = 6'b111000;
  localparam logic [5:0] SPLIT_VEC_VFW          = 6'b111001;
  localparam logic [5:0] SPLIT_VEC_WFW          = 6'b111010;
  localparam logic [5:0] SPLIT_VEC_VFM          = 6'b111011;
  localparam logic [5:0] SPLIT_VEC_VFRED        = 6'b111100;
  localparam logic [5:0] SPLIT_VEC_VFREDOSUM    = 6'b111101;
  localparam logic [5:0] SPLIT_DUMMY            = 6'b111111;

  // ---- fuOpType（9 位）：表里用到的助记常量，由 gen.py 从源码求值 ----
  localparam logic [8:0] OP_X = 9'h000;   // FuOpType.X（BitPat 全通配 -> 0）
  // BEGIN GENERATED(fuop_constants)
  // ---- FuOpType（xiangshan/package.scala 或 yunsuan/package.scala）----
  localparam logic [8:0] FUOP_FMVXF             = 9'h180;
  // ---- ALUOpType（xiangshan/package.scala 或 yunsuan/package.scala）----
  localparam logic [8:0] ALU_slliuw             = 9'h000;
  localparam logic [8:0] ALU_sll                = 9'h001;
  localparam logic [8:0] ALU_bclr               = 9'h002;
  localparam logic [8:0] ALU_bset               = 9'h003;
  localparam logic [8:0] ALU_binv               = 9'h004;
  localparam logic [8:0] ALU_srl                = 9'h005;
  localparam logic [8:0] ALU_bext               = 9'h006;
  localparam logic [8:0] ALU_sra                = 9'h007;
  localparam logic [8:0] ALU_rol                = 9'h009;
  localparam logic [8:0] ALU_ror                = 9'h00B;
  localparam logic [8:0] ALU_addw               = 9'h010;
  localparam logic [8:0] ALU_subw               = 9'h012;
  localparam logic [8:0] ALU_sllw               = 9'h018;
  localparam logic [8:0] ALU_srlw               = 9'h019;
  localparam logic [8:0] ALU_sraw               = 9'h01A;
  localparam logic [8:0] ALU_rolw               = 9'h01C;
  localparam logic [8:0] ALU_rorw               = 9'h01D;
  localparam logic [8:0] ALU_adduw              = 9'h020;
  localparam logic [8:0] ALU_add                = 9'h021;
  localparam logic [8:0] ALU_sh1adduw           = 9'h028;
  localparam logic [8:0] ALU_sh1add             = 9'h029;
  localparam logic [8:0] ALU_sh2adduw           = 9'h02A;
  localparam logic [8:0] ALU_sh2add             = 9'h02B;
  localparam logic [8:0] ALU_sh3adduw           = 9'h02C;
  localparam logic [8:0] ALU_sh3add             = 9'h02D;
  localparam logic [8:0] ALU_sub                = 9'h030;
  localparam logic [8:0] ALU_sltu               = 9'h031;
  localparam logic [8:0] ALU_slt                = 9'h032;
  localparam logic [8:0] ALU_maxu               = 9'h034;
  localparam logic [8:0] ALU_minu               = 9'h035;
  localparam logic [8:0] ALU_max                = 9'h036;
  localparam logic [8:0] ALU_min                = 9'h037;
  localparam logic [8:0] ALU_and                = 9'h040;
  localparam logic [8:0] ALU_andn               = 9'h041;
  localparam logic [8:0] ALU_or                 = 9'h042;
  localparam logic [8:0] ALU_orn                = 9'h043;
  localparam logic [8:0] ALU_xor                = 9'h044;
  localparam logic [8:0] ALU_xnor               = 9'h045;
  localparam logic [8:0] ALU_orcb               = 9'h046;
  localparam logic [8:0] ALU_sextb              = 9'h048;
  localparam logic [8:0] ALU_packh              = 9'h049;
  localparam logic [8:0] ALU_sexth              = 9'h04A;
  localparam logic [8:0] ALU_packw              = 9'h04B;
  localparam logic [8:0] ALU_revb               = 9'h050;
  localparam logic [8:0] ALU_rev8               = 9'h051;
  localparam logic [8:0] ALU_pack               = 9'h052;
  localparam logic [8:0] ALU_czero_eqz          = 9'h074;
  localparam logic [8:0] ALU_czero_nez          = 9'h076;
  // ---- BKUOpType（xiangshan/package.scala 或 yunsuan/package.scala）----
  localparam logic [8:0] BKU_clmul              = 9'h000;
  localparam logic [8:0] BKU_clmulh             = 9'h001;
  localparam logic [8:0] BKU_clmulr             = 9'h002;
  localparam logic [8:0] BKU_xpermn             = 9'h004;
  localparam logic [8:0] BKU_xpermb             = 9'h005;
  localparam logic [8:0] BKU_clz                = 9'h008;
  localparam logic [8:0] BKU_clzw               = 9'h009;
  localparam logic [8:0] BKU_ctz                = 9'h00A;
  localparam logic [8:0] BKU_ctzw               = 9'h00B;
  localparam logic [8:0] BKU_cpop               = 9'h00C;
  localparam logic [8:0] BKU_cpopw              = 9'h00D;
  localparam logic [8:0] BKU_aes64es            = 9'h020;
  localparam logic [8:0] BKU_aes64esm           = 9'h021;
  localparam logic [8:0] BKU_aes64ds            = 9'h022;
  localparam logic [8:0] BKU_aes64dsm           = 9'h023;
  localparam logic [8:0] BKU_aes64im            = 9'h024;
  localparam logic [8:0] BKU_aes64ks1i          = 9'h025;
  localparam logic [8:0] BKU_aes64ks2           = 9'h026;
  localparam logic [8:0] BKU_sm4ed0             = 9'h028;
  localparam logic [8:0] BKU_sm4ed1             = 9'h029;
  localparam logic [8:0] BKU_sm4ed2             = 9'h02A;
  localparam logic [8:0] BKU_sm4ed3             = 9'h02B;
  localparam logic [8:0] BKU_sm4ks0             = 9'h02C;
  localparam logic [8:0] BKU_sm4ks1             = 9'h02D;
  localparam logic [8:0] BKU_sm4ks2             = 9'h02E;
  localparam logic [8:0] BKU_sm4ks3             = 9'h02F;
  localparam logic [8:0] BKU_sha256sum0         = 9'h030;
  localparam logic [8:0] BKU_sha256sum1         = 9'h031;
  localparam logic [8:0] BKU_sha256sig0         = 9'h032;
  localparam logic [8:0] BKU_sha256sig1         = 9'h033;
  localparam logic [8:0] BKU_sha512sum0         = 9'h034;
  localparam logic [8:0] BKU_sha512sum1         = 9'h035;
  localparam logic [8:0] BKU_sha512sig0         = 9'h036;
  localparam logic [8:0] BKU_sha512sig1         = 9'h037;
  localparam logic [8:0] BKU_sm3p0              = 9'h038;
  localparam logic [8:0] BKU_sm3p1              = 9'h039;
  // ---- MDUOpType（xiangshan/package.scala 或 yunsuan/package.scala）----
  localparam logic [8:0] MDU_mul                = 9'h000;
  localparam logic [8:0] MDU_mulh               = 9'h001;
  localparam logic [8:0] MDU_mulhsu             = 9'h002;
  localparam logic [8:0] MDU_mulhu              = 9'h003;
  localparam logic [8:0] MDU_mulw               = 9'h004;
  localparam logic [8:0] MDU_div                = 9'h010;
  localparam logic [8:0] MDU_rem                = 9'h011;
  localparam logic [8:0] MDU_divu               = 9'h012;
  localparam logic [8:0] MDU_remu               = 9'h013;
  localparam logic [8:0] MDU_divw               = 9'h014;
  localparam logic [8:0] MDU_remw               = 9'h015;
  localparam logic [8:0] MDU_divuw              = 9'h016;
  localparam logic [8:0] MDU_remuw              = 9'h017;
  // ---- JumpOpType（xiangshan/package.scala 或 yunsuan/package.scala）----
  localparam logic [8:0] JMP_jal                = 9'h000;
  localparam logic [8:0] JMP_jalr               = 9'h001;
  localparam logic [8:0] JMP_auipc              = 9'h002;
  // ---- BRUOpType（xiangshan/package.scala 或 yunsuan/package.scala）----
  localparam logic [8:0] BRU_beq                = 9'h000;
  localparam logic [8:0] BRU_bne                = 9'h001;
  localparam logic [8:0] BRU_blt                = 9'h004;
  localparam logic [8:0] BRU_bge                = 9'h005;
  localparam logic [8:0] BRU_bltu               = 9'h008;
  localparam logic [8:0] BRU_bgeu               = 9'h009;
  // ---- CSROpType（xiangshan/package.scala 或 yunsuan/package.scala）----
  localparam logic [8:0] CSR_wrt                = 9'h009;
  localparam logic [8:0] CSR_set                = 9'h00A;
  localparam logic [8:0] CSR_clr                = 9'h00B;
  localparam logic [8:0] CSR_wrti               = 9'h00D;
  localparam logic [8:0] CSR_seti               = 9'h00E;
  localparam logic [8:0] CSR_clri               = 9'h00F;
  localparam logic [8:0] CSR_jmp                = 9'h010;
  localparam logic [8:0] CSR_wfi                = 9'h020;
  localparam logic [8:0] CSR_wrs_nto            = 9'h022;
  localparam logic [8:0] CSR_wrs_sto            = 9'h023;
  // ---- FenceOpType（xiangshan/package.scala 或 yunsuan/package.scala）----
  localparam logic [8:0] FENCE_nofence          = 9'h000;
  localparam logic [8:0] FENCE_fence            = 9'h010;
  localparam logic [8:0] FENCE_sfence           = 9'h011;
  localparam logic [8:0] FENCE_fencei           = 9'h012;
  localparam logic [8:0] FENCE_hfence_v         = 9'h013;
  localparam logic [8:0] FENCE_hfence_g         = 9'h014;
  // ---- LSUOpType（xiangshan/package.scala 或 yunsuan/package.scala）----
  localparam logic [8:0] LSU_lb                 = 9'h000;
  localparam logic [8:0] LSU_sb                 = 9'h000;
  localparam logic [8:0] LSU_lh                 = 9'h001;
  localparam logic [8:0] LSU_sh                 = 9'h001;
  localparam logic [8:0] LSU_lr_w               = 9'h002;
  localparam logic [8:0] LSU_lw                 = 9'h002;
  localparam logic [8:0] LSU_sw                 = 9'h002;
  localparam logic [8:0] LSU_ld                 = 9'h003;
  localparam logic [8:0] LSU_lr_d               = 9'h003;
  localparam logic [8:0] LSU_sd                 = 9'h003;
  localparam logic [8:0] LSU_lbu                = 9'h004;
  localparam logic [8:0] LSU_lhu                = 9'h005;
  localparam logic [8:0] LSU_lwu                = 9'h006;
  localparam logic [8:0] LSU_sc_w               = 9'h006;
  localparam logic [8:0] LSU_cbo_zero           = 9'h007;
  localparam logic [8:0] LSU_sc_d               = 9'h007;
  localparam logic [8:0] LSU_amoswap_w          = 9'h00A;
  localparam logic [8:0] LSU_amoswap_d          = 9'h00B;
  localparam logic [8:0] LSU_cbo_clean          = 9'h00C;
  localparam logic [8:0] LSU_cbo_flush          = 9'h00D;
  localparam logic [8:0] LSU_amoadd_w           = 9'h00E;
  localparam logic [8:0] LSU_cbo_inval          = 9'h00E;
  localparam logic [8:0] LSU_amoadd_d           = 9'h00F;
  localparam logic [8:0] LSU_hlvb               = 9'h010;
  localparam logic [8:0] LSU_hsvb               = 9'h010;
  localparam logic [8:0] LSU_hlvh               = 9'h011;
  localparam logic [8:0] LSU_hsvh               = 9'h011;
  localparam logic [8:0] LSU_amoxor_w           = 9'h012;
  localparam logic [8:0] LSU_hlvw               = 9'h012;
  localparam logic [8:0] LSU_hsvw               = 9'h012;
  localparam logic [8:0] LSU_amoxor_d           = 9'h013;
  localparam logic [8:0] LSU_hlvd               = 9'h013;
  localparam logic [8:0] LSU_hsvd               = 9'h013;
  localparam logic [8:0] LSU_hlvbu              = 9'h014;
  localparam logic [8:0] LSU_hlvhu              = 9'h015;
  localparam logic [8:0] LSU_amoand_w           = 9'h016;
  localparam logic [8:0] LSU_hlvwu              = 9'h016;
  localparam logic [8:0] LSU_amoand_d           = 9'h017;
  localparam logic [8:0] LSU_amoor_w            = 9'h01A;
  localparam logic [8:0] LSU_amoor_d            = 9'h01B;
  localparam logic [8:0] LSU_hlvxhu             = 9'h01D;
  localparam logic [8:0] LSU_amomin_w           = 9'h01E;
  localparam logic [8:0] LSU_hlvxwu             = 9'h01E;
  localparam logic [8:0] LSU_amomin_d           = 9'h01F;
  localparam logic [8:0] LSU_amomax_w           = 9'h022;
  localparam logic [8:0] LSU_amomax_d           = 9'h023;
  localparam logic [8:0] LSU_amominu_w          = 9'h026;
  localparam logic [8:0] LSU_amominu_d          = 9'h027;
  localparam logic [8:0] LSU_amomaxu_w          = 9'h02A;
  localparam logic [8:0] LSU_amomaxu_d          = 9'h02B;
  localparam logic [8:0] LSU_amocas_q           = 9'h02C;
  localparam logic [8:0] LSU_amocas_w           = 9'h02E;
  localparam logic [8:0] LSU_amocas_d           = 9'h02F;
  // ---- VlduType（xiangshan/package.scala 或 yunsuan/package.scala）----
  localparam logic [8:0] VLDU_vle               = 9'h080;
  localparam logic [8:0] VLDU_vlr               = 9'h088;
  localparam logic [8:0] VLDU_vlm               = 9'h08B;
  localparam logic [8:0] VLDU_vleff             = 9'h090;
  localparam logic [8:0] VLDU_vluxe             = 9'h0A0;
  localparam logic [8:0] VLDU_vlse              = 9'h0C0;
  localparam logic [8:0] VLDU_vloxe             = 9'h0E0;
  // ---- VstuType（xiangshan/package.scala 或 yunsuan/package.scala）----
  localparam logic [8:0] VSTU_vse               = 9'h100;
  localparam logic [8:0] VSTU_vsr               = 9'h108;
  localparam logic [8:0] VSTU_vsm               = 9'h10B;
  localparam logic [8:0] VSTU_vsuxe             = 9'h120;
  localparam logic [8:0] VSTU_vsse              = 9'h140;
  localparam logic [8:0] VSTU_vsoxe             = 9'h160;
  // ---- VSETOpType（xiangshan/package.scala 或 yunsuan/package.scala）----
  localparam logic [8:0] VSET_uvsetvcfg_ii      = 9'h020;
  localparam logic [8:0] VSET_uvsetvcfg_xx      = 9'h060;
  localparam logic [8:0] VSET_uvsetvcfg_xi      = 9'h0A0;
  // ---- IF2VectorType（xiangshan/package.scala 或 yunsuan/package.scala）----
  localparam logic [8:0] I2V_FMX_H_X            = 9'h005;
  localparam logic [8:0] I2V_FMX_W_X            = 9'h006;
  localparam logic [8:0] I2V_FMX_D_X            = 9'h007;
  // ---- VialuFixType（xiangshan/package.scala 或 yunsuan/package.scala）----
  localparam logic [8:0] VIALU_vzext_vf2        = 9'h002;
  localparam logic [8:0] VIALU_vadc_vvm         = 9'h003;
  localparam logic [8:0] VIALU_vsbc_vvm         = 9'h005;
  localparam logic [8:0] VIALU_vand_vv          = 9'h007;
  localparam logic [8:0] VIALU_vandn_vv         = 9'h009;
  localparam logic [8:0] VIALU_vxor_vv          = 9'h00A;
  localparam logic [8:0] VIALU_vor_vv           = 9'h00B;
  localparam logic [8:0] VIALU_vsll_vv          = 9'h00F;
  localparam logic [8:0] VIALU_vsrl_vv          = 9'h010;
  localparam logic [8:0] VIALU_vminu_vv         = 9'h017;
  localparam logic [8:0] VIALU_vmaxu_vv         = 9'h018;
  localparam logic [8:0] VIALU_vmerge_vvm       = 9'h019;
  localparam logic [8:0] VIALU_vmv_v_v          = 9'h01A;
  localparam logic [8:0] VIALU_vsaddu_vv        = 9'h01B;
  localparam logic [8:0] VIALU_vssubu_vv        = 9'h01C;
  localparam logic [8:0] VIALU_vaaddu_vv        = 9'h01D;
  localparam logic [8:0] VIALU_vasubu_vv        = 9'h01E;
  localparam logic [8:0] VIALU_vssrl_vv         = 9'h01F;
  localparam logic [8:0] VIALU_vcpop_v          = 9'h027;
  localparam logic [8:0] VIALU_vbrev_v          = 9'h030;
  localparam logic [8:0] VIALU_vbrev8_v         = 9'h031;
  localparam logic [8:0] VIALU_vrev8_v          = 9'h032;
  localparam logic [8:0] VIALU_vclz_v           = 9'h033;
  localparam logic [8:0] VIALU_vctz_v           = 9'h034;
  localparam logic [8:0] VIALU_vrol_vv          = 9'h035;
  localparam logic [8:0] VIALU_vror_vv          = 9'h036;
  localparam logic [8:0] VIALU_vadd_vv          = 9'h040;
  localparam logic [8:0] VIALU_vrsub_vv         = 9'h041;
  localparam logic [8:0] VIALU_vsub_vv          = 9'h041;
  localparam logic [8:0] VIALU_vsext_vf2        = 9'h042;
  localparam logic [8:0] VIALU_vsra_vv          = 9'h051;
  localparam logic [8:0] VIALU_vmin_vv          = 9'h057;
  localparam logic [8:0] VIALU_vmax_vv          = 9'h058;
  localparam logic [8:0] VIALU_vsadd_vv         = 9'h05B;
  localparam logic [8:0] VIALU_vssub_vv         = 9'h05C;
  localparam logic [8:0] VIALU_vaadd_vv         = 9'h05D;
  localparam logic [8:0] VIALU_vasub_vv         = 9'h05E;
  localparam logic [8:0] VIALU_vssra_vv         = 9'h060;
  localparam logic [8:0] VIALU_vmv_s_x          = 9'h06E;
  localparam logic [8:0] VIALU_vwaddu_vv        = 9'h080;
  localparam logic [8:0] VIALU_vwsubu_vv        = 9'h081;
  localparam logic [8:0] VIALU_vzext_vf4        = 9'h082;
  localparam logic [8:0] VIALU_vmadc_vv         = 9'h084;
  localparam logic [8:0] VIALU_vmsbc_vv         = 9'h086;
  localparam logic [8:0] VIALU_vmseq_vv         = 9'h092;
  localparam logic [8:0] VIALU_vmsne_vv         = 9'h093;
  localparam logic [8:0] VIALU_vmsltu_vv        = 9'h094;
  localparam logic [8:0] VIALU_vmsleu_vv        = 9'h095;
  localparam logic [8:0] VIALU_vmsgtu_vv        = 9'h096;
  localparam logic [8:0] VIALU_vwadd_vv         = 9'h0C0;
  localparam logic [8:0] VIALU_vwsub_vv         = 9'h0C1;
  localparam logic [8:0] VIALU_vsext_vf4        = 9'h0C2;
  localparam logic [8:0] VIALU_vmslt_vv         = 9'h0D4;
  localparam logic [8:0] VIALU_vmsle_vv         = 9'h0D5;
  localparam logic [8:0] VIALU_vmsgt_vv         = 9'h0D6;
  localparam logic [8:0] VIALU_vwaddu_wv        = 9'h100;
  localparam logic [8:0] VIALU_vwsubu_wv        = 9'h101;
  localparam logic [8:0] VIALU_vzext_vf8        = 9'h102;
  localparam logic [8:0] VIALU_vmadc_vvm        = 9'h104;
  localparam logic [8:0] VIALU_vmsbc_vvm        = 9'h106;
  localparam logic [8:0] VIALU_vwsll_vv         = 9'h137;
  localparam logic [8:0] VIALU_vwadd_wv         = 9'h140;
  localparam logic [8:0] VIALU_vwsub_wv         = 9'h141;
  localparam logic [8:0] VIALU_vsext_vf8        = 9'h142;
  localparam logic [8:0] VIALU_vmand_mm         = 9'h187;
  localparam logic [8:0] VIALU_vmnand_mm        = 9'h188;
  localparam logic [8:0] VIALU_vmandn_mm        = 9'h189;
  localparam logic [8:0] VIALU_vmxor_mm         = 9'h18A;
  localparam logic [8:0] VIALU_vmor_mm          = 9'h18B;
  localparam logic [8:0] VIALU_vmnor_mm         = 9'h18C;
  localparam logic [8:0] VIALU_vmorn_mm         = 9'h18D;
  localparam logic [8:0] VIALU_vmxnor_mm        = 9'h18E;
  localparam logic [8:0] VIALU_vnsrl_wv         = 9'h190;
  localparam logic [8:0] VIALU_vnclipu_wv       = 9'h19F;
  localparam logic [8:0] VIALU_vnsra_wv         = 9'h1D1;
  localparam logic [8:0] VIALU_vnclip_wv        = 9'h1E0;
  // ---- VimacType（xiangshan/package.scala 或 yunsuan/package.scala）----
  localparam logic [8:0] VIMAC_vmulhu           = 9'h001;
  localparam logic [8:0] VIMAC_vwmulu           = 9'h008;
  localparam logic [8:0] VIMAC_vwmaccu          = 9'h00A;
  localparam logic [8:0] VIMAC_vwmaccsu         = 9'h03A;
  localparam logic [8:0] VIMAC_vmulhsu          = 9'h041;
  localparam logic [8:0] VIMAC_vwmulsu          = 9'h048;
  localparam logic [8:0] VIMAC_vwmaccus         = 9'h05A;
  localparam logic [8:0] VIMAC_vmul             = 9'h060;
  localparam logic [8:0] VIMAC_vmulh            = 9'h061;
  localparam logic [8:0] VIMAC_vsmul            = 9'h066;
  localparam logic [8:0] VIMAC_vwmul            = 9'h068;
  localparam logic [8:0] VIMAC_vmacc            = 9'h072;
  localparam logic [8:0] VIMAC_vnmsac           = 9'h073;
  localparam logic [8:0] VIMAC_vmadd            = 9'h074;
  localparam logic [8:0] VIMAC_vnmsub           = 9'h075;
  localparam logic [8:0] VIMAC_vwmacc           = 9'h07A;
  // ---- VipuType（xiangshan/package.scala 或 yunsuan/package.scala）----
  localparam logic [8:0] VIPU_vredsum_vs        = 9'h039;
  localparam logic [8:0] VIPU_vredmaxu_vs       = 9'h03A;
  localparam logic [8:0] VIPU_vredmax_vs        = 9'h03B;
  localparam logic [8:0] VIPU_vredminu_vs       = 9'h03C;
  localparam logic [8:0] VIPU_vredmin_vs        = 9'h03D;
  localparam logic [8:0] VIPU_vredand_vs        = 9'h03E;
  localparam logic [8:0] VIPU_vredor_vs         = 9'h03F;
  localparam logic [8:0] VIPU_vredxor_vs        = 9'h040;
  localparam logic [8:0] VIPU_vwredsumu_vs      = 9'h041;
  localparam logic [8:0] VIPU_vwredsum_vs       = 9'h042;
  localparam logic [8:0] VIPU_vcpop_m           = 9'h04B;
  localparam logic [8:0] VIPU_vfirst_m          = 9'h04C;
  localparam logic [8:0] VIPU_vmsbf_m           = 9'h04D;
  localparam logic [8:0] VIPU_vmsif_m           = 9'h04E;
  localparam logic [8:0] VIPU_vmsof_m           = 9'h04F;
  localparam logic [8:0] VIPU_viota_m           = 9'h050;
  localparam logic [8:0] VIPU_vid_v             = 9'h051;
  localparam logic [8:0] VIPU_vmv_x_s           = 9'h053;
  // ---- VidivType（xiangshan/package.scala 或 yunsuan/package.scala）----
  localparam logic [8:0] VIDIV_vremu            = 9'h000;
  localparam logic [8:0] VIDIV_vrem             = 9'h001;
  localparam logic [8:0] VIDIV_vdivu            = 9'h002;
  localparam logic [8:0] VIDIV_vdiv             = 9'h003;
  // ---- VpermType（xiangshan/package.scala 或 yunsuan/package.scala）----
  localparam logic [8:0] VPERM_vslide1up        = 9'h002;
  localparam logic [8:0] VPERM_vslide1down      = 9'h003;
  localparam logic [8:0] VPERM_vrgather         = 9'h004;
  localparam logic [8:0] VPERM_vmv1r            = 9'h007;
  localparam logic [8:0] VPERM_vmv2r            = 9'h00F;
  localparam logic [8:0] VPERM_vmv4r            = 9'h017;
  localparam logic [8:0] VPERM_vmv8r            = 9'h01F;
  localparam logic [8:0] VPERM_vrgatherei16     = 9'h024;
  localparam logic [8:0] VPERM_vcompress        = 9'h026;
  localparam logic [8:0] VPERM_vfslide1up       = 9'h042;
  localparam logic [8:0] VPERM_vfslide1down     = 9'h043;
  localparam logic [8:0] VPERM_vslideup         = 9'h080;
  localparam logic [8:0] VPERM_vslidedown       = 9'h081;
  localparam logic [8:0] VPERM_vrgather_vx      = 9'h085;
  // ---- VfaluType（xiangshan/package.scala 或 yunsuan/package.scala）----
  localparam logic [8:0] VFALU_vfadd            = 9'h000;
  localparam logic [8:0] VFALU_vfsub            = 9'h001;
  localparam logic [8:0] VFALU_vfmin            = 9'h002;
  localparam logic [8:0] VFALU_vfmax            = 9'h003;
  localparam logic [8:0] VFALU_vfmerge          = 9'h004;
  localparam logic [8:0] VFALU_vfmv             = 9'h005;
  localparam logic [8:0] VFALU_vfsgnj           = 9'h006;
  localparam logic [8:0] VFALU_vfsgnjn          = 9'h007;
  localparam logic [8:0] VFALU_vfsgnjx          = 9'h008;
  localparam logic [8:0] VFALU_vfeq             = 9'h009;
  localparam logic [8:0] VFALU_vfne             = 9'h00A;
  localparam logic [8:0] VFALU_vflt             = 9'h00B;
  localparam logic [8:0] VFALU_vfle             = 9'h00C;
  localparam logic [8:0] VFALU_vfgt             = 9'h00D;
  localparam logic [8:0] VFALU_vfge             = 9'h00E;
  localparam logic [8:0] VFALU_vfclass          = 9'h00F;
  localparam logic [8:0] VFALU_vfmv_f_s         = 9'h011;
  localparam logic [8:0] VFALU_vfmv_s_f         = 9'h012;
  localparam logic [8:0] VFALU_fmaxm            = 9'h013;
  localparam logic [8:0] VFALU_vfredmin         = 9'h014;
  localparam logic [8:0] VFALU_vfredmax         = 9'h015;
  localparam logic [8:0] VFALU_vfredosum        = 9'h016;
  localparam logic [8:0] VFALU_vfredusum        = 9'h01A;
  localparam logic [8:0] VFALU_fltq             = 9'h01B;
  localparam logic [8:0] VFALU_fleq             = 9'h01C;
  localparam logic [8:0] VFALU_fminm            = 9'h01E;
  localparam logic [8:0] VFALU_vfwadd           = 9'h020;
  localparam logic [8:0] VFALU_vfwsub           = 9'h021;
  localparam logic [8:0] VFALU_vfwredosum       = 9'h036;
  localparam logic [8:0] VFALU_vfwadd_w         = 9'h060;
  localparam logic [8:0] VFALU_vfwsub_w         = 9'h061;
  // ---- VfmaType（xiangshan/package.scala 或 yunsuan/package.scala）----
  localparam logic [8:0] VFMA_vfmul             = 9'h000;
  localparam logic [8:0] VFMA_vfmacc            = 9'h001;
  localparam logic [8:0] VFMA_vfnmacc           = 9'h002;
  localparam logic [8:0] VFMA_vfmsac            = 9'h003;
  localparam logic [8:0] VFMA_vfnmsac           = 9'h004;
  localparam logic [8:0] VFMA_vfmadd            = 9'h005;
  localparam logic [8:0] VFMA_vfnmadd           = 9'h006;
  localparam logic [8:0] VFMA_vfmsub            = 9'h007;
  localparam logic [8:0] VFMA_vfnmsub           = 9'h008;
  localparam logic [8:0] VFMA_vfmul_w           = 9'h010;
  localparam logic [8:0] VFMA_vfmacc_w          = 9'h011;
  localparam logic [8:0] VFMA_vfnmacc_w         = 9'h012;
  localparam logic [8:0] VFMA_vfmsac_w          = 9'h013;
  localparam logic [8:0] VFMA_vfnmsac_w         = 9'h014;
  // ---- VfdivType（xiangshan/package.scala 或 yunsuan/package.scala）----
  localparam logic [8:0] VFDIV_vfdiv            = 9'h000;
  localparam logic [8:0] VFDIV_vfsqrt           = 9'h001;
  // ---- VfcvtType（xiangshan/package.scala 或 yunsuan/package.scala）----
  localparam logic [8:0] VFCVT_vfcvt_fxuv       = 9'h042;
  localparam logic [8:0] VFCVT_vfcvt_fxv        = 9'h043;
  localparam logic [8:0] VFCVT_vfwcvt_fxuv      = 9'h04A;
  localparam logic [8:0] VFCVT_vfwcvt_fxv       = 9'h04B;
  localparam logic [8:0] VFCVT_vfncvt_fxuw      = 9'h052;
  localparam logic [8:0] VFCVT_vfncvt_fxw       = 9'h053;
  localparam logic [8:0] VFCVT_vfcvt_xufv       = 9'h080;
  localparam logic [8:0] VFCVT_vfcvt_xfv        = 9'h081;
  localparam logic [8:0] VFCVT_vfcvt_rtz_xufv   = 9'h086;
  localparam logic [8:0] VFCVT_vfcvt_rtz_xfv    = 9'h087;
  localparam logic [8:0] VFCVT_fcvt_wu_h        = 9'h088;
  localparam logic [8:0] VFCVT_vfwcvt_xufv      = 9'h088;
  localparam logic [8:0] VFCVT_fcvt_w_h         = 9'h089;
  localparam logic [8:0] VFCVT_vfwcvt_xfv       = 9'h089;
  localparam logic [8:0] VFCVT_vfwcvt_rtz_xufv  = 9'h08E;
  localparam logic [8:0] VFCVT_vfwcvt_rtz_xfv   = 9'h08F;
  localparam logic [8:0] VFCVT_vfncvt_xufw      = 9'h090;
  localparam logic [8:0] VFCVT_vfncvt_xfw       = 9'h091;
  localparam logic [8:0] VFCVT_vfncvt_rtz_xufw  = 9'h096;
  localparam logic [8:0] VFCVT_vfncvt_rtz_xfw   = 9'h097;
  localparam logic [8:0] VFCVT_fcvt_lu_h        = 9'h098;
  localparam logic [8:0] VFCVT_fcvt_l_h         = 9'h099;
  localparam logic [8:0] VFCVT_fround           = 9'h0C0;
  localparam logic [8:0] VFCVT_froundnx         = 9'h0C4;
  localparam logic [8:0] VFCVT_fcvt_s_h         = 9'h0C8;
  localparam logic [8:0] VFCVT_vfwcvt_ffv       = 9'h0CC;
  localparam logic [8:0] VFCVT_fcvt_h_s         = 9'h0D0;
  localparam logic [8:0] VFCVT_vfncvt_ffw       = 9'h0D4;
  localparam logic [8:0] VFCVT_vfncvt_rod_ffw   = 9'h0D5;
  localparam logic [8:0] VFCVT_fcvt_d_h         = 9'h0D8;
  localparam logic [8:0] VFCVT_fcvt_h_d         = 9'h0D8;
  localparam logic [8:0] VFCVT_vfrsqrt7         = 9'h0E0;
  localparam logic [8:0] VFCVT_vfrec7           = 9'h0E1;
  localparam logic [8:0] VFCVT_fcvtmod_w_d      = 9'h191;
  // ---- VfpuType（xiangshan/package.scala 或 yunsuan/package.scala）----
  localparam logic [8:0] VFPU_vfsub             = 9'h001;
  localparam logic [8:0] VFPU_vfsgnj            = 9'h006;
  localparam logic [8:0] VFPU_vfsgnjn           = 9'h007;
  localparam logic [8:0] VFPU_vfsgnjx           = 9'h008;
  // END GENERATED(fuop_constants)
  // 表外修正用到的几个（不在表里，手写；值见 xiangshan/package.scala）
  localparam logic [8:0] LSU_prefetch_i = 9'h008;
  localparam logic [8:0] LSU_prefetch_r = 9'h009;
  localparam logic [8:0] LSU_prefetch_w = 9'h00A;
  localparam logic [8:0] VSET_csrrvl    = 9'h016;   // csrr vl 转成的 vset 操作

  // ---- 表行的 8 个布尔列，做成可 | 起来的标志位（读起来像 Scala 的 xWen = T）----
  localparam logic [7:0] NOFLAG    = 8'h00;
  localparam logic [7:0] XWEN      = 8'h01;   // 写整数寄存器堆（rfWen）
  localparam logic [7:0] FWEN      = 8'h02;   // 写浮点寄存器堆（fpWen）
  localparam logic [7:0] VWEN      = 8'h04;   // 写向量寄存器堆（vecWen = vWen || mWen）
  localparam logic [7:0] XSTRAP    = 8'h08;   // 仿真陷阱指令
  localparam logic [7:0] NOSPEC    = 8'h10;   // waitForward：等前面全部完成才发射
  localparam logic [7:0] BLOCKBACK = 8'h20;   // blockBackward：挡住后面的指令
  localparam logic [7:0] FLUSHPIPE = 8'h40;   // 提交时冲刷流水
  localparam logic [7:0] ROBCOMP   = 8'h80;   // canRobCompress：可与相邻指令合并成一个 Rob 项

  // 一行译码结果：Chisel XSDecode.generate() 的 15 列（vecWen 已把 vWen||mWen 合并）
  typedef struct packed {
    logic [3:0]      srcType0, srcType1, srcType2;
    logic [FU_W-1:0] fuType;
    logic [8:0]      fuOpType;
    logic [3:0]      selImm;
    logic [5:0]      uopSplitType;
    logic            rfWen, fpWen, vecWen, isXSTrap;
    logic            waitForward, blockBackward, flushPipe, canRobCompress;
  } decode_row_t;

  // 表里没有这条指令时的默认行（DecodeConstants.decodeDefault）：全 0，selImm=INVALID_INSTR
  localparam decode_row_t ROW_INVALID = '{
    srcType0: SRC_X, srcType1: SRC_X, srcType2: SRC_X, fuType: FU_X, fuOpType: OP_X,
    selImm: INVALID_INSTR, uopSplitType: SPLIT_X,
    rfWen: 1'b0, fpWen: 1'b0, vecWen: 1'b0, isXSTrap: 1'b0,
    waitForward: 1'b0, blockBackward: 1'b0, flushPipe: 1'b0, canRobCompress: 1'b0};

  // 表行构造：参数顺序 = Scala XSDecode(src1, src2, src3, fu, fuOp, selImm, uopSplitType, 标志)
  function automatic decode_row_t R(input logic [3:0] src1, input logic [3:0] src2, input logic [3:0] src3,
                                    input logic [FU_W-1:0] fu, input logic [8:0] fuOp,
                                    input logic [3:0] selImm, input logic [5:0] split,
                                    input logic [7:0] flags);
    decode_row_t r;
    r.srcType0 = src1; r.srcType1 = src2; r.srcType2 = src3;
    r.fuType = fu; r.fuOpType = fuOp; r.selImm = selImm; r.uopSplitType = split;
    r.rfWen          = flags[0];
    r.fpWen          = flags[1];
    r.vecWen         = flags[2];
    r.isXSTrap       = flags[3];
    r.waitForward    = flags[4];
    r.blockBackward  = flags[5];
    r.flushPipe      = flags[6];
    r.canRobCompress = flags[7];
    return r;
  endfunction

  // ---- 指令模式：助记符 = rocket-chip Instructions.scala / XiangShan 自有定义；? 位写成 z，casez 通配 ----
  // BEGIN GENERATED(insn_patterns)
  localparam logic [31:0] LW               = 32'bzzzzzzzzzzzzzzzzz010zzzzz0000011;
  localparam logic [31:0] LH               = 32'bzzzzzzzzzzzzzzzzz001zzzzz0000011;
  localparam logic [31:0] LHU              = 32'bzzzzzzzzzzzzzzzzz101zzzzz0000011;
  localparam logic [31:0] LB               = 32'bzzzzzzzzzzzzzzzzz000zzzzz0000011;
  localparam logic [31:0] LBU              = 32'bzzzzzzzzzzzzzzzzz100zzzzz0000011;
  localparam logic [31:0] SW               = 32'bzzzzzzzzzzzzzzzzz010zzzzz0100011;
  localparam logic [31:0] SH               = 32'bzzzzzzzzzzzzzzzzz001zzzzz0100011;
  localparam logic [31:0] SB               = 32'bzzzzzzzzzzzzzzzzz000zzzzz0100011;
  localparam logic [31:0] LUI              = 32'bzzzzzzzzzzzzzzzzzzzzzzzzz0110111;
  localparam logic [31:0] ADDI             = 32'bzzzzzzzzzzzzzzzzz000zzzzz0010011;
  localparam logic [31:0] ANDI             = 32'bzzzzzzzzzzzzzzzzz111zzzzz0010011;
  localparam logic [31:0] ORI              = 32'bzzzzzzzzzzzzzzzzz110zzzzz0010011;
  localparam logic [31:0] XORI             = 32'bzzzzzzzzzzzzzzzzz100zzzzz0010011;
  localparam logic [31:0] SLTI             = 32'bzzzzzzzzzzzzzzzzz010zzzzz0010011;
  localparam logic [31:0] SLTIU            = 32'bzzzzzzzzzzzzzzzzz011zzzzz0010011;
  localparam logic [31:0] SLL              = 32'b0000000zzzzzzzzzz001zzzzz0110011;
  localparam logic [31:0] ADD              = 32'b0000000zzzzzzzzzz000zzzzz0110011;
  localparam logic [31:0] SUB              = 32'b0100000zzzzzzzzzz000zzzzz0110011;
  localparam logic [31:0] SLT              = 32'b0000000zzzzzzzzzz010zzzzz0110011;
  localparam logic [31:0] SLTU             = 32'b0000000zzzzzzzzzz011zzzzz0110011;
  localparam logic [31:0] AND              = 32'b0000000zzzzzzzzzz111zzzzz0110011;
  localparam logic [31:0] OR               = 32'b0000000zzzzzzzzzz110zzzzz0110011;
  localparam logic [31:0] XOR              = 32'b0000000zzzzzzzzzz100zzzzz0110011;
  localparam logic [31:0] SRA              = 32'b0100000zzzzzzzzzz101zzzzz0110011;
  localparam logic [31:0] SRL              = 32'b0000000zzzzzzzzzz101zzzzz0110011;
  localparam logic [31:0] LD               = 32'bzzzzzzzzzzzzzzzzz011zzzzz0000011;
  localparam logic [31:0] LWU              = 32'bzzzzzzzzzzzzzzzzz110zzzzz0000011;
  localparam logic [31:0] SD               = 32'bzzzzzzzzzzzzzzzzz011zzzzz0100011;
  localparam logic [31:0] SLLI             = 32'b000000zzzzzzzzzzz001zzzzz0010011;
  localparam logic [31:0] SRLI             = 32'b000000zzzzzzzzzzz101zzzzz0010011;
  localparam logic [31:0] SRAI             = 32'b010000zzzzzzzzzzz101zzzzz0010011;
  localparam logic [31:0] ADDIW            = 32'bzzzzzzzzzzzzzzzzz000zzzzz0011011;
  localparam logic [31:0] SLLIW            = 32'b0000000zzzzzzzzzz001zzzzz0011011;
  localparam logic [31:0] SRAIW            = 32'b0100000zzzzzzzzzz101zzzzz0011011;
  localparam logic [31:0] SRLIW            = 32'b0000000zzzzzzzzzz101zzzzz0011011;
  localparam logic [31:0] ADDW             = 32'b0000000zzzzzzzzzz000zzzzz0111011;
  localparam logic [31:0] SUBW             = 32'b0100000zzzzzzzzzz000zzzzz0111011;
  localparam logic [31:0] SLLW             = 32'b0000000zzzzzzzzzz001zzzzz0111011;
  localparam logic [31:0] SRAW             = 32'b0100000zzzzzzzzzz101zzzzz0111011;
  localparam logic [31:0] SRLW             = 32'b0000000zzzzzzzzzz101zzzzz0111011;
  localparam logic [31:0] MUL              = 32'b0000001zzzzzzzzzz000zzzzz0110011;
  localparam logic [31:0] MULH             = 32'b0000001zzzzzzzzzz001zzzzz0110011;
  localparam logic [31:0] MULHU            = 32'b0000001zzzzzzzzzz011zzzzz0110011;
  localparam logic [31:0] MULHSU           = 32'b0000001zzzzzzzzzz010zzzzz0110011;
  localparam logic [31:0] MULW             = 32'b0000001zzzzzzzzzz000zzzzz0111011;
  localparam logic [31:0] DIV              = 32'b0000001zzzzzzzzzz100zzzzz0110011;
  localparam logic [31:0] DIVU             = 32'b0000001zzzzzzzzzz101zzzzz0110011;
  localparam logic [31:0] REM              = 32'b0000001zzzzzzzzzz110zzzzz0110011;
  localparam logic [31:0] REMU             = 32'b0000001zzzzzzzzzz111zzzzz0110011;
  localparam logic [31:0] DIVW             = 32'b0000001zzzzzzzzzz100zzzzz0111011;
  localparam logic [31:0] DIVUW            = 32'b0000001zzzzzzzzzz101zzzzz0111011;
  localparam logic [31:0] REMW             = 32'b0000001zzzzzzzzzz110zzzzz0111011;
  localparam logic [31:0] REMUW            = 32'b0000001zzzzzzzzzz111zzzzz0111011;
  localparam logic [31:0] AUIPC            = 32'bzzzzzzzzzzzzzzzzzzzzzzzzz0010111;
  localparam logic [31:0] JAL              = 32'bzzzzzzzzzzzzzzzzzzzzzzzzz1101111;
  localparam logic [31:0] JALR             = 32'bzzzzzzzzzzzzzzzzz000zzzzz1100111;
  localparam logic [31:0] BEQ              = 32'bzzzzzzzzzzzzzzzzz000zzzzz1100011;
  localparam logic [31:0] BNE              = 32'bzzzzzzzzzzzzzzzzz001zzzzz1100011;
  localparam logic [31:0] BGE              = 32'bzzzzzzzzzzzzzzzzz101zzzzz1100011;
  localparam logic [31:0] BGEU             = 32'bzzzzzzzzzzzzzzzzz111zzzzz1100011;
  localparam logic [31:0] BLT              = 32'bzzzzzzzzzzzzzzzzz100zzzzz1100011;
  localparam logic [31:0] BLTU             = 32'bzzzzzzzzzzzzzzzzz110zzzzz1100011;
  localparam logic [31:0] CSRRW            = 32'bzzzzzzzzzzzzzzzzz001zzzzz1110011;
  localparam logic [31:0] CSRRS            = 32'bzzzzzzzzzzzzzzzzz010zzzzz1110011;
  localparam logic [31:0] CSRRC            = 32'bzzzzzzzzzzzzzzzzz011zzzzz1110011;
  localparam logic [31:0] CSRRWI           = 32'bzzzzzzzzzzzzzzzzz101zzzzz1110011;
  localparam logic [31:0] CSRRSI           = 32'bzzzzzzzzzzzzzzzzz110zzzzz1110011;
  localparam logic [31:0] CSRRCI           = 32'bzzzzzzzzzzzzzzzzz111zzzzz1110011;
  localparam logic [31:0] EBREAK           = 32'b00000000000100000000000001110011;
  localparam logic [31:0] ECALL            = 32'b00000000000000000000000001110011;
  localparam logic [31:0] SRET             = 32'b00010000001000000000000001110011;
  localparam logic [31:0] MRET             = 32'b00110000001000000000000001110011;
  localparam logic [31:0] MNRET            = 32'b01110000001000000000000001110011;
  localparam logic [31:0] DRET             = 32'b01111011001000000000000001110011;
  localparam logic [31:0] WFI              = 32'b00010000010100000000000001110011;
  localparam logic [31:0] SFENCE_VMA       = 32'b0001001zzzzzzzzzz000000001110011;
  localparam logic [31:0] FENCE_I          = 32'bzzzzzzzzzzzzzzzzz001zzzzz0001111;
  localparam logic [31:0] FENCE            = 32'bzzzzzzzzzzzzzzzzz000zzzzz0001111;
  localparam logic [31:0] PAUSE            = 32'b00000001000000000000000000001111;
  localparam logic [31:0] WRS_NTO          = 32'b00000000110100000000000001110011;
  localparam logic [31:0] WRS_STO          = 32'b00000001110100000000000001110011;
  localparam logic [31:0] AMOADD_W         = 32'b00000zzzzzzzzzzzz010zzzzz0101111;
  localparam logic [31:0] AMOXOR_W         = 32'b00100zzzzzzzzzzzz010zzzzz0101111;
  localparam logic [31:0] AMOSWAP_W        = 32'b00001zzzzzzzzzzzz010zzzzz0101111;
  localparam logic [31:0] AMOAND_W         = 32'b01100zzzzzzzzzzzz010zzzzz0101111;
  localparam logic [31:0] AMOOR_W          = 32'b01000zzzzzzzzzzzz010zzzzz0101111;
  localparam logic [31:0] AMOMIN_W         = 32'b10000zzzzzzzzzzzz010zzzzz0101111;
  localparam logic [31:0] AMOMINU_W        = 32'b11000zzzzzzzzzzzz010zzzzz0101111;
  localparam logic [31:0] AMOMAX_W         = 32'b10100zzzzzzzzzzzz010zzzzz0101111;
  localparam logic [31:0] AMOMAXU_W        = 32'b11100zzzzzzzzzzzz010zzzzz0101111;
  localparam logic [31:0] AMOCAS_W         = 32'b00101zzzzzzzzzzzz010zzzzz0101111;
  localparam logic [31:0] AMOADD_D         = 32'b00000zzzzzzzzzzzz011zzzzz0101111;
  localparam logic [31:0] AMOXOR_D         = 32'b00100zzzzzzzzzzzz011zzzzz0101111;
  localparam logic [31:0] AMOSWAP_D        = 32'b00001zzzzzzzzzzzz011zzzzz0101111;
  localparam logic [31:0] AMOAND_D         = 32'b01100zzzzzzzzzzzz011zzzzz0101111;
  localparam logic [31:0] AMOOR_D          = 32'b01000zzzzzzzzzzzz011zzzzz0101111;
  localparam logic [31:0] AMOMIN_D         = 32'b10000zzzzzzzzzzzz011zzzzz0101111;
  localparam logic [31:0] AMOMINU_D        = 32'b11000zzzzzzzzzzzz011zzzzz0101111;
  localparam logic [31:0] AMOMAX_D         = 32'b10100zzzzzzzzzzzz011zzzzz0101111;
  localparam logic [31:0] AMOMAXU_D        = 32'b11100zzzzzzzzzzzz011zzzzz0101111;
  localparam logic [31:0] AMOCAS_D         = 32'b00101zzzzzzzzzzzz011zzzzz0101111;
  localparam logic [31:0] AMOCAS_Q         = 32'b00101zzzzzzzzzzzz100zzzzz0101111;
  localparam logic [31:0] LR_W             = 32'b00010zz00000zzzzz010zzzzz0101111;
  localparam logic [31:0] LR_D             = 32'b00010zz00000zzzzz011zzzzz0101111;
  localparam logic [31:0] SC_W             = 32'b00011zzzzzzzzzzzz010zzzzz0101111;
  localparam logic [31:0] SC_D             = 32'b00011zzzzzzzzzzzz011zzzzz0101111;
  localparam logic [31:0] FLH              = 32'bzzzzzzzzzzzzzzzzz001zzzzz0000111;
  localparam logic [31:0] FLW              = 32'bzzzzzzzzzzzzzzzzz010zzzzz0000111;
  localparam logic [31:0] FLD              = 32'bzzzzzzzzzzzzzzzzz011zzzzz0000111;
  localparam logic [31:0] FSH              = 32'bzzzzzzzzzzzzzzzzz001zzzzz0100111;
  localparam logic [31:0] FSW              = 32'bzzzzzzzzzzzzzzzzz010zzzzz0100111;
  localparam logic [31:0] FSD              = 32'bzzzzzzzzzzzzzzzzz011zzzzz0100111;
  localparam logic [31:0] FMV_D_X          = 32'b111100100000zzzzz000zzzzz1010011;
  localparam logic [31:0] FMV_W_X          = 32'b111100000000zzzzz000zzzzz1010011;
  localparam logic [31:0] FMV_H_X          = 32'b111101000000zzzzz000zzzzz1010011;
  localparam logic [31:0] FCVT_S_W         = 32'b110100000000zzzzzzzzzzzzz1010011;
  localparam logic [31:0] FCVT_S_WU        = 32'b110100000001zzzzzzzzzzzzz1010011;
  localparam logic [31:0] FCVT_S_L         = 32'b110100000010zzzzzzzzzzzzz1010011;
  localparam logic [31:0] FCVT_S_LU        = 32'b110100000011zzzzzzzzzzzzz1010011;
  localparam logic [31:0] FCVT_D_W         = 32'b110100100000zzzzzzzzzzzzz1010011;
  localparam logic [31:0] FCVT_D_WU        = 32'b110100100001zzzzzzzzzzzzz1010011;
  localparam logic [31:0] FCVT_D_L         = 32'b110100100010zzzzzzzzzzzzz1010011;
  localparam logic [31:0] FCVT_D_LU        = 32'b110100100011zzzzzzzzzzzzz1010011;
  localparam logic [31:0] FCVT_H_W         = 32'b110101000000zzzzzzzzzzzzz1010011;
  localparam logic [31:0] FCVT_H_WU        = 32'b110101000001zzzzzzzzzzzzz1010011;
  localparam logic [31:0] FCVT_H_L         = 32'b110101000010zzzzzzzzzzzzz1010011;
  localparam logic [31:0] FCVT_H_LU        = 32'b110101000011zzzzzzzzzzzzz1010011;
  localparam logic [31:0] ADD_UW           = 32'b0000100zzzzzzzzzz000zzzzz0111011;
  localparam logic [31:0] SH1ADD           = 32'b0010000zzzzzzzzzz010zzzzz0110011;
  localparam logic [31:0] SH1ADD_UW        = 32'b0010000zzzzzzzzzz010zzzzz0111011;
  localparam logic [31:0] SH2ADD           = 32'b0010000zzzzzzzzzz100zzzzz0110011;
  localparam logic [31:0] SH2ADD_UW        = 32'b0010000zzzzzzzzzz100zzzzz0111011;
  localparam logic [31:0] SH3ADD           = 32'b0010000zzzzzzzzzz110zzzzz0110011;
  localparam logic [31:0] SH3ADD_UW        = 32'b0010000zzzzzzzzzz110zzzzz0111011;
  localparam logic [31:0] SLLI_UW          = 32'b000010zzzzzzzzzzz001zzzzz0011011;
  localparam logic [31:0] ANDN             = 32'b0100000zzzzzzzzzz111zzzzz0110011;
  localparam logic [31:0] ORN              = 32'b0100000zzzzzzzzzz110zzzzz0110011;
  localparam logic [31:0] XNOR             = 32'b0100000zzzzzzzzzz100zzzzz0110011;
  localparam logic [31:0] CLZ              = 32'b011000000000zzzzz001zzzzz0010011;
  localparam logic [31:0] CLZW             = 32'b011000000000zzzzz001zzzzz0011011;
  localparam logic [31:0] CTZ              = 32'b011000000001zzzzz001zzzzz0010011;
  localparam logic [31:0] CTZW             = 32'b011000000001zzzzz001zzzzz0011011;
  localparam logic [31:0] CPOP             = 32'b011000000010zzzzz001zzzzz0010011;
  localparam logic [31:0] CPOPW            = 32'b011000000010zzzzz001zzzzz0011011;
  localparam logic [31:0] MAX              = 32'b0000101zzzzzzzzzz110zzzzz0110011;
  localparam logic [31:0] MAXU             = 32'b0000101zzzzzzzzzz111zzzzz0110011;
  localparam logic [31:0] MIN              = 32'b0000101zzzzzzzzzz100zzzzz0110011;
  localparam logic [31:0] MINU             = 32'b0000101zzzzzzzzzz101zzzzz0110011;
  localparam logic [31:0] SEXT_B           = 32'b011000000100zzzzz001zzzzz0010011;
  localparam logic [31:0] SEXT_H           = 32'b011000000101zzzzz001zzzzz0010011;
  localparam logic [31:0] ROL              = 32'b0110000zzzzzzzzzz001zzzzz0110011;
  localparam logic [31:0] ROLW             = 32'b0110000zzzzzzzzzz001zzzzz0111011;
  localparam logic [31:0] ROR              = 32'b0110000zzzzzzzzzz101zzzzz0110011;
  localparam logic [31:0] RORI             = 32'b011000zzzzzzzzzzz101zzzzz0010011;
  localparam logic [31:0] RORIW            = 32'b0110000zzzzzzzzzz101zzzzz0011011;
  localparam logic [31:0] RORW             = 32'b0110000zzzzzzzzzz101zzzzz0111011;
  localparam logic [31:0] ORC_B            = 32'b001010000111zzzzz101zzzzz0010011;
  localparam logic [31:0] REV8             = 32'b011010111000zzzzz101zzzzz0010011;
  localparam logic [31:0] CLMUL            = 32'b0000101zzzzzzzzzz001zzzzz0110011;
  localparam logic [31:0] CLMULH           = 32'b0000101zzzzzzzzzz011zzzzz0110011;
  localparam logic [31:0] CLMULR           = 32'b0000101zzzzzzzzzz010zzzzz0110011;
  localparam logic [31:0] BCLR             = 32'b0100100zzzzzzzzzz001zzzzz0110011;
  localparam logic [31:0] BCLRI            = 32'b010010zzzzzzzzzzz001zzzzz0010011;
  localparam logic [31:0] BEXT             = 32'b0100100zzzzzzzzzz101zzzzz0110011;
  localparam logic [31:0] BEXTI            = 32'b010010zzzzzzzzzzz101zzzzz0010011;
  localparam logic [31:0] BINV             = 32'b0110100zzzzzzzzzz001zzzzz0110011;
  localparam logic [31:0] BINVI            = 32'b011010zzzzzzzzzzz001zzzzz0010011;
  localparam logic [31:0] BSET             = 32'b0010100zzzzzzzzzz001zzzzz0110011;
  localparam logic [31:0] BSETI            = 32'b001010zzzzzzzzzzz001zzzzz0010011;
  localparam logic [31:0] PACK             = 32'b0000100zzzzzzzzzz100zzzzz0110011;
  localparam logic [31:0] PACKH            = 32'b0000100zzzzzzzzzz111zzzzz0110011;
  localparam logic [31:0] PACKW            = 32'b0000100zzzzzzzzzz100zzzzz0111011;
  localparam logic [31:0] BREV8            = 32'b011010000111zzzzz101zzzzz0010011;
  localparam logic [31:0] XPERM4           = 32'b0010100zzzzzzzzzz010zzzzz0110011;
  localparam logic [31:0] XPERM8           = 32'b0010100zzzzzzzzzz100zzzzz0110011;
  localparam logic [31:0] AES64DS          = 32'b0011101zzzzzzzzzz000zzzzz0110011;
  localparam logic [31:0] AES64DSM         = 32'b0011111zzzzzzzzzz000zzzzz0110011;
  localparam logic [31:0] AES64IM          = 32'b001100000000zzzzz001zzzzz0010011;
  localparam logic [31:0] AES64KS1I        = 32'b00110001zzzzzzzzz001zzzzz0010011;
  localparam logic [31:0] AES64KS2         = 32'b0111111zzzzzzzzzz000zzzzz0110011;
  localparam logic [31:0] AES64ES          = 32'b0011001zzzzzzzzzz000zzzzz0110011;
  localparam logic [31:0] AES64ESM         = 32'b0011011zzzzzzzzzz000zzzzz0110011;
  localparam logic [31:0] SHA256SIG0       = 32'b000100000010zzzzz001zzzzz0010011;
  localparam logic [31:0] SHA256SIG1       = 32'b000100000011zzzzz001zzzzz0010011;
  localparam logic [31:0] SHA256SUM0       = 32'b000100000000zzzzz001zzzzz0010011;
  localparam logic [31:0] SHA256SUM1       = 32'b000100000001zzzzz001zzzzz0010011;
  localparam logic [31:0] SHA512SIG0       = 32'b000100000110zzzzz001zzzzz0010011;
  localparam logic [31:0] SHA512SIG1       = 32'b000100000111zzzzz001zzzzz0010011;
  localparam logic [31:0] SHA512SUM0       = 32'b000100000100zzzzz001zzzzz0010011;
  localparam logic [31:0] SHA512SUM1       = 32'b000100000101zzzzz001zzzzz0010011;
  localparam logic [31:0] SM4ED0           = 32'b0011000zzzzzzzzzz000zzzzz0110011;
  localparam logic [31:0] SM4ED1           = 32'b0111000zzzzzzzzzz000zzzzz0110011;
  localparam logic [31:0] SM4ED2           = 32'b1011000zzzzzzzzzz000zzzzz0110011;
  localparam logic [31:0] SM4ED3           = 32'b1111000zzzzzzzzzz000zzzzz0110011;
  localparam logic [31:0] SM4KS0           = 32'b0011010zzzzzzzzzz000zzzzz0110011;
  localparam logic [31:0] SM4KS1           = 32'b0111010zzzzzzzzzz000zzzzz0110011;
  localparam logic [31:0] SM4KS2           = 32'b1011010zzzzzzzzzz000zzzzz0110011;
  localparam logic [31:0] SM4KS3           = 32'b1111010zzzzzzzzzz000zzzzz0110011;
  localparam logic [31:0] SM3P0            = 32'b000100001000zzzzz001zzzzz0010011;
  localparam logic [31:0] SM3P1            = 32'b000100001001zzzzz001zzzzz0010011;
  localparam logic [31:0] TRAP             = 32'b000000000000zzzzz000000001101011;
  localparam logic [31:0] CBO_ZERO         = 32'b000000000100zzzzz010000000001111;
  localparam logic [31:0] CBO_CLEAN        = 32'b000000000001zzzzz010000000001111;
  localparam logic [31:0] CBO_FLUSH        = 32'b000000000010zzzzz010000000001111;
  localparam logic [31:0] CBO_INVAL        = 32'b000000000000zzzzz010000000001111;
  localparam logic [31:0] SINVAL_VMA       = 32'b0001011zzzzzzzzzz000000001110011;
  localparam logic [31:0] SFENCE_W_INVAL   = 32'b00011000000000000000000001110011;
  localparam logic [31:0] SFENCE_INVAL_IR  = 32'b00011000000100000000000001110011;
  localparam logic [31:0] HFENCE_GVMA      = 32'b0110001zzzzzzzzzz000000001110011;
  localparam logic [31:0] HFENCE_VVMA      = 32'b0010001zzzzzzzzzz000000001110011;
  localparam logic [31:0] HINVAL_GVMA      = 32'b0110011zzzzzzzzzz000000001110011;
  localparam logic [31:0] HINVAL_VVMA      = 32'b0010011zzzzzzzzzz000000001110011;
  localparam logic [31:0] HLV_B            = 32'b011000000000zzzzz100zzzzz1110011;
  localparam logic [31:0] HLV_BU           = 32'b011000000001zzzzz100zzzzz1110011;
  localparam logic [31:0] HLV_D            = 32'b011011000000zzzzz100zzzzz1110011;
  localparam logic [31:0] HLV_H            = 32'b011001000000zzzzz100zzzzz1110011;
  localparam logic [31:0] HLV_HU           = 32'b011001000001zzzzz100zzzzz1110011;
  localparam logic [31:0] HLV_W            = 32'b011010000000zzzzz100zzzzz1110011;
  localparam logic [31:0] HLV_WU           = 32'b011010000001zzzzz100zzzzz1110011;
  localparam logic [31:0] HLVX_HU          = 32'b011001000011zzzzz100zzzzz1110011;
  localparam logic [31:0] HLVX_WU          = 32'b011010000011zzzzz100zzzzz1110011;
  localparam logic [31:0] HSV_B            = 32'b0110001zzzzzzzzzz100000001110011;
  localparam logic [31:0] HSV_D            = 32'b0110111zzzzzzzzzz100000001110011;
  localparam logic [31:0] HSV_H            = 32'b0110011zzzzzzzzzz100000001110011;
  localparam logic [31:0] HSV_W            = 32'b0110101zzzzzzzzzz100000001110011;
  localparam logic [31:0] VSETVLI          = 32'b0zzzzzzzzzzzzzzzz111zzzzz1010111;
  localparam logic [31:0] VSETIVLI         = 32'b11zzzzzzzzzzzzzzz111zzzzz1010111;
  localparam logic [31:0] VSETVL           = 32'b1000000zzzzzzzzzz111zzzzz1010111;
  localparam logic [31:0] VADD_VV          = 32'b000000zzzzzzzzzzz000zzzzz1010111;
  localparam logic [31:0] VSUB_VV          = 32'b000010zzzzzzzzzzz000zzzzz1010111;
  localparam logic [31:0] VMINU_VV         = 32'b000100zzzzzzzzzzz000zzzzz1010111;
  localparam logic [31:0] VMIN_VV          = 32'b000101zzzzzzzzzzz000zzzzz1010111;
  localparam logic [31:0] VMAXU_VV         = 32'b000110zzzzzzzzzzz000zzzzz1010111;
  localparam logic [31:0] VMAX_VV          = 32'b000111zzzzzzzzzzz000zzzzz1010111;
  localparam logic [31:0] VAND_VV          = 32'b001001zzzzzzzzzzz000zzzzz1010111;
  localparam logic [31:0] VOR_VV           = 32'b001010zzzzzzzzzzz000zzzzz1010111;
  localparam logic [31:0] VXOR_VV          = 32'b001011zzzzzzzzzzz000zzzzz1010111;
  localparam logic [31:0] VRGATHER_VV      = 32'b001100zzzzzzzzzzz000zzzzz1010111;
  localparam logic [31:0] VRGATHEREI16_VV  = 32'b001110zzzzzzzzzzz000zzzzz1010111;
  localparam logic [31:0] VADC_VVM         = 32'b0100000zzzzzzzzzz000zzzzz1010111;
  localparam logic [31:0] VMADC_VVM        = 32'b0100010zzzzzzzzzz000zzzzz1010111;
  localparam logic [31:0] VMADC_VV         = 32'b0100011zzzzzzzzzz000zzzzz1010111;
  localparam logic [31:0] VSBC_VVM         = 32'b0100100zzzzzzzzzz000zzzzz1010111;
  localparam logic [31:0] VMSBC_VV         = 32'b0100111zzzzzzzzzz000zzzzz1010111;
  localparam logic [31:0] VMSBC_VVM        = 32'b0100110zzzzzzzzzz000zzzzz1010111;
  localparam logic [31:0] VMERGE_VVM       = 32'b0101110zzzzzzzzzz000zzzzz1010111;
  localparam logic [31:0] VMV_V_V          = 32'b010111100000zzzzz000zzzzz1010111;
  localparam logic [31:0] VMSEQ_VV         = 32'b011000zzzzzzzzzzz000zzzzz1010111;
  localparam logic [31:0] VMSNE_VV         = 32'b011001zzzzzzzzzzz000zzzzz1010111;
  localparam logic [31:0] VMSLTU_VV        = 32'b011010zzzzzzzzzzz000zzzzz1010111;
  localparam logic [31:0] VMSLT_VV         = 32'b011011zzzzzzzzzzz000zzzzz1010111;
  localparam logic [31:0] VMSLEU_VV        = 32'b011100zzzzzzzzzzz000zzzzz1010111;
  localparam logic [31:0] VMSLE_VV         = 32'b011101zzzzzzzzzzz000zzzzz1010111;
  localparam logic [31:0] VSLL_VV          = 32'b100101zzzzzzzzzzz000zzzzz1010111;
  localparam logic [31:0] VSRL_VV          = 32'b101000zzzzzzzzzzz000zzzzz1010111;
  localparam logic [31:0] VSRA_VV          = 32'b101001zzzzzzzzzzz000zzzzz1010111;
  localparam logic [31:0] VNSRL_WV         = 32'b101100zzzzzzzzzzz000zzzzz1010111;
  localparam logic [31:0] VNSRA_WV         = 32'b101101zzzzzzzzzzz000zzzzz1010111;
  localparam logic [31:0] VSADDU_VV        = 32'b100000zzzzzzzzzzz000zzzzz1010111;
  localparam logic [31:0] VSADD_VV         = 32'b100001zzzzzzzzzzz000zzzzz1010111;
  localparam logic [31:0] VSSUBU_VV        = 32'b100010zzzzzzzzzzz000zzzzz1010111;
  localparam logic [31:0] VSSUB_VV         = 32'b100011zzzzzzzzzzz000zzzzz1010111;
  localparam logic [31:0] VSMUL_VV         = 32'b100111zzzzzzzzzzz000zzzzz1010111;
  localparam logic [31:0] VSSRL_VV         = 32'b101010zzzzzzzzzzz000zzzzz1010111;
  localparam logic [31:0] VSSRA_VV         = 32'b101011zzzzzzzzzzz000zzzzz1010111;
  localparam logic [31:0] VNCLIPU_WV       = 32'b101110zzzzzzzzzzz000zzzzz1010111;
  localparam logic [31:0] VNCLIP_WV        = 32'b101111zzzzzzzzzzz000zzzzz1010111;
  localparam logic [31:0] VWREDSUMU_VS     = 32'b110000zzzzzzzzzzz000zzzzz1010111;
  localparam logic [31:0] VWREDSUM_VS      = 32'b110001zzzzzzzzzzz000zzzzz1010111;
  localparam logic [31:0] VANDN_VV         = 32'b000001zzzzzzzzzzz000zzzzz1010111;
  localparam logic [31:0] VROL_VV          = 32'b010101zzzzzzzzzzz000zzzzz1010111;
  localparam logic [31:0] VROR_VV          = 32'b010100zzzzzzzzzzz000zzzzz1010111;
  localparam logic [31:0] VWSLL_VV         = 32'b110101zzzzzzzzzzz000zzzzz1010111;
  localparam logic [31:0] VADD_VX          = 32'b000000zzzzzzzzzzz100zzzzz1010111;
  localparam logic [31:0] VSUB_VX          = 32'b000010zzzzzzzzzzz100zzzzz1010111;
  localparam logic [31:0] VRSUB_VX         = 32'b000011zzzzzzzzzzz100zzzzz1010111;
  localparam logic [31:0] VMINU_VX         = 32'b000100zzzzzzzzzzz100zzzzz1010111;
  localparam logic [31:0] VMIN_VX          = 32'b000101zzzzzzzzzzz100zzzzz1010111;
  localparam logic [31:0] VMAXU_VX         = 32'b000110zzzzzzzzzzz100zzzzz1010111;
  localparam logic [31:0] VMAX_VX          = 32'b000111zzzzzzzzzzz100zzzzz1010111;
  localparam logic [31:0] VAND_VX          = 32'b001001zzzzzzzzzzz100zzzzz1010111;
  localparam logic [31:0] VOR_VX           = 32'b001010zzzzzzzzzzz100zzzzz1010111;
  localparam logic [31:0] VXOR_VX          = 32'b001011zzzzzzzzzzz100zzzzz1010111;
  localparam logic [31:0] VRGATHER_VX      = 32'b001100zzzzzzzzzzz100zzzzz1010111;
  localparam logic [31:0] VSLIDEUP_VX      = 32'b001110zzzzzzzzzzz100zzzzz1010111;
  localparam logic [31:0] VSLIDEDOWN_VX    = 32'b001111zzzzzzzzzzz100zzzzz1010111;
  localparam logic [31:0] VADC_VXM         = 32'b0100000zzzzzzzzzz100zzzzz1010111;
  localparam logic [31:0] VMADC_VXM        = 32'b0100010zzzzzzzzzz100zzzzz1010111;
  localparam logic [31:0] VMADC_VX         = 32'b0100011zzzzzzzzzz100zzzzz1010111;
  localparam logic [31:0] VSBC_VXM         = 32'b0100100zzzzzzzzzz100zzzzz1010111;
  localparam logic [31:0] VMSBC_VX         = 32'b0100111zzzzzzzzzz100zzzzz1010111;
  localparam logic [31:0] VMSBC_VXM        = 32'b0100110zzzzzzzzzz100zzzzz1010111;
  localparam logic [31:0] VMERGE_VXM       = 32'b0101110zzzzzzzzzz100zzzzz1010111;
  localparam logic [31:0] VMV_V_X          = 32'b010111100000zzzzz100zzzzz1010111;
  localparam logic [31:0] VMSEQ_VX         = 32'b011000zzzzzzzzzzz100zzzzz1010111;
  localparam logic [31:0] VMSNE_VX         = 32'b011001zzzzzzzzzzz100zzzzz1010111;
  localparam logic [31:0] VMSLTU_VX        = 32'b011010zzzzzzzzzzz100zzzzz1010111;
  localparam logic [31:0] VMSLT_VX         = 32'b011011zzzzzzzzzzz100zzzzz1010111;
  localparam logic [31:0] VMSLEU_VX        = 32'b011100zzzzzzzzzzz100zzzzz1010111;
  localparam logic [31:0] VMSLE_VX         = 32'b011101zzzzzzzzzzz100zzzzz1010111;
  localparam logic [31:0] VMSGTU_VX        = 32'b011110zzzzzzzzzzz100zzzzz1010111;
  localparam logic [31:0] VMSGT_VX         = 32'b011111zzzzzzzzzzz100zzzzz1010111;
  localparam logic [31:0] VSLL_VX          = 32'b100101zzzzzzzzzzz100zzzzz1010111;
  localparam logic [31:0] VSRL_VX          = 32'b101000zzzzzzzzzzz100zzzzz1010111;
  localparam logic [31:0] VSRA_VX          = 32'b101001zzzzzzzzzzz100zzzzz1010111;
  localparam logic [31:0] VNSRL_WX         = 32'b101100zzzzzzzzzzz100zzzzz1010111;
  localparam logic [31:0] VNSRA_WX         = 32'b101101zzzzzzzzzzz100zzzzz1010111;
  localparam logic [31:0] VSADDU_VX        = 32'b100000zzzzzzzzzzz100zzzzz1010111;
  localparam logic [31:0] VSADD_VX         = 32'b100001zzzzzzzzzzz100zzzzz1010111;
  localparam logic [31:0] VSSUBU_VX        = 32'b100010zzzzzzzzzzz100zzzzz1010111;
  localparam logic [31:0] VSSUB_VX         = 32'b100011zzzzzzzzzzz100zzzzz1010111;
  localparam logic [31:0] VSMUL_VX         = 32'b100111zzzzzzzzzzz100zzzzz1010111;
  localparam logic [31:0] VSSRL_VX         = 32'b101010zzzzzzzzzzz100zzzzz1010111;
  localparam logic [31:0] VSSRA_VX         = 32'b101011zzzzzzzzzzz100zzzzz1010111;
  localparam logic [31:0] VNCLIPU_WX       = 32'b101110zzzzzzzzzzz100zzzzz1010111;
  localparam logic [31:0] VNCLIP_WX        = 32'b101111zzzzzzzzzzz100zzzzz1010111;
  localparam logic [31:0] VANDN_VX         = 32'b000001zzzzzzzzzzz100zzzzz1010111;
  localparam logic [31:0] VROL_VX          = 32'b010101zzzzzzzzzzz100zzzzz1010111;
  localparam logic [31:0] VROR_VX          = 32'b010100zzzzzzzzzzz100zzzzz1010111;
  localparam logic [31:0] VWSLL_VX         = 32'b110101zzzzzzzzzzz100zzzzz1010111;
  localparam logic [31:0] VADD_VI          = 32'b000000zzzzzzzzzzz011zzzzz1010111;
  localparam logic [31:0] VRSUB_VI         = 32'b000011zzzzzzzzzzz011zzzzz1010111;
  localparam logic [31:0] VAND_VI          = 32'b001001zzzzzzzzzzz011zzzzz1010111;
  localparam logic [31:0] VOR_VI           = 32'b001010zzzzzzzzzzz011zzzzz1010111;
  localparam logic [31:0] VXOR_VI          = 32'b001011zzzzzzzzzzz011zzzzz1010111;
  localparam logic [31:0] VRGATHER_VI      = 32'b001100zzzzzzzzzzz011zzzzz1010111;
  localparam logic [31:0] VSLIDEUP_VI      = 32'b001110zzzzzzzzzzz011zzzzz1010111;
  localparam logic [31:0] VSLIDEDOWN_VI    = 32'b001111zzzzzzzzzzz011zzzzz1010111;
  localparam logic [31:0] VADC_VIM         = 32'b0100000zzzzzzzzzz011zzzzz1010111;
  localparam logic [31:0] VMADC_VIM        = 32'b0100010zzzzzzzzzz011zzzzz1010111;
  localparam logic [31:0] VMADC_VI         = 32'b0100011zzzzzzzzzz011zzzzz1010111;
  localparam logic [31:0] VMERGE_VIM       = 32'b0101110zzzzzzzzzz011zzzzz1010111;
  localparam logic [31:0] VMV_V_I          = 32'b010111100000zzzzz011zzzzz1010111;
  localparam logic [31:0] VMSEQ_VI         = 32'b011000zzzzzzzzzzz011zzzzz1010111;
  localparam logic [31:0] VMSNE_VI         = 32'b011001zzzzzzzzzzz011zzzzz1010111;
  localparam logic [31:0] VMSLEU_VI        = 32'b011100zzzzzzzzzzz011zzzzz1010111;
  localparam logic [31:0] VMSLE_VI         = 32'b011101zzzzzzzzzzz011zzzzz1010111;
  localparam logic [31:0] VMSGTU_VI        = 32'b011110zzzzzzzzzzz011zzzzz1010111;
  localparam logic [31:0] VMSGT_VI         = 32'b011111zzzzzzzzzzz011zzzzz1010111;
  localparam logic [31:0] VSLL_VI          = 32'b100101zzzzzzzzzzz011zzzzz1010111;
  localparam logic [31:0] VSRL_VI          = 32'b101000zzzzzzzzzzz011zzzzz1010111;
  localparam logic [31:0] VSRA_VI          = 32'b101001zzzzzzzzzzz011zzzzz1010111;
  localparam logic [31:0] VNSRL_WI         = 32'b101100zzzzzzzzzzz011zzzzz1010111;
  localparam logic [31:0] VNSRA_WI         = 32'b101101zzzzzzzzzzz011zzzzz1010111;
  localparam logic [31:0] VSADDU_VI        = 32'b100000zzzzzzzzzzz011zzzzz1010111;
  localparam logic [31:0] VSADD_VI         = 32'b100001zzzzzzzzzzz011zzzzz1010111;
  localparam logic [31:0] VSSRL_VI         = 32'b101010zzzzzzzzzzz011zzzzz1010111;
  localparam logic [31:0] VSSRA_VI         = 32'b101011zzzzzzzzzzz011zzzzz1010111;
  localparam logic [31:0] VNCLIPU_WI       = 32'b101110zzzzzzzzzzz011zzzzz1010111;
  localparam logic [31:0] VNCLIP_WI        = 32'b101111zzzzzzzzzzz011zzzzz1010111;
  localparam logic [31:0] VMV1R_V          = 32'b1001111zzzzz00000011zzzzz1010111;
  localparam logic [31:0] VMV2R_V          = 32'b1001111zzzzz00001011zzzzz1010111;
  localparam logic [31:0] VMV4R_V          = 32'b1001111zzzzz00011011zzzzz1010111;
  localparam logic [31:0] VMV8R_V          = 32'b1001111zzzzz00111011zzzzz1010111;
  localparam logic [31:0] VROR_VI          = 32'b01010zzzzzzzzzzzz011zzzzz1010111;
  localparam logic [31:0] VWSLL_VI         = 32'b110101zzzzzzzzzzz011zzzzz1010111;
  localparam logic [31:0] VAADD_VV         = 32'b001001zzzzzzzzzzz010zzzzz1010111;
  localparam logic [31:0] VAADDU_VV        = 32'b001000zzzzzzzzzzz010zzzzz1010111;
  localparam logic [31:0] VASUB_VV         = 32'b001011zzzzzzzzzzz010zzzzz1010111;
  localparam logic [31:0] VASUBU_VV        = 32'b001010zzzzzzzzzzz010zzzzz1010111;
  localparam logic [31:0] VCOMPRESS_VM     = 32'b0101111zzzzzzzzzz010zzzzz1010111;
  localparam logic [31:0] VCPOP_M          = 32'b010000zzzzzz10000010zzzzz1010111;
  localparam logic [31:0] VDIV_VV          = 32'b100001zzzzzzzzzzz010zzzzz1010111;
  localparam logic [31:0] VDIVU_VV         = 32'b100000zzzzzzzzzzz010zzzzz1010111;
  localparam logic [31:0] VFIRST_M         = 32'b010000zzzzzz10001010zzzzz1010111;
  localparam logic [31:0] VID_V            = 32'b010100z0000010001010zzzzz1010111;
  localparam logic [31:0] VIOTA_M          = 32'b010100zzzzzz10000010zzzzz1010111;
  localparam logic [31:0] VMACC_VV         = 32'b101101zzzzzzzzzzz010zzzzz1010111;
  localparam logic [31:0] VMADD_VV         = 32'b101001zzzzzzzzzzz010zzzzz1010111;
  localparam logic [31:0] VMAND_MM         = 32'b0110011zzzzzzzzzz010zzzzz1010111;
  localparam logic [31:0] VMANDN_MM        = 32'b0110001zzzzzzzzzz010zzzzz1010111;
  localparam logic [31:0] VMNAND_MM        = 32'b0111011zzzzzzzzzz010zzzzz1010111;
  localparam logic [31:0] VMNOR_MM         = 32'b0111101zzzzzzzzzz010zzzzz1010111;
  localparam logic [31:0] VMOR_MM          = 32'b0110101zzzzzzzzzz010zzzzz1010111;
  localparam logic [31:0] VMORN_MM         = 32'b0111001zzzzzzzzzz010zzzzz1010111;
  localparam logic [31:0] VMXNOR_MM        = 32'b0111111zzzzzzzzzz010zzzzz1010111;
  localparam logic [31:0] VMXOR_MM         = 32'b0110111zzzzzzzzzz010zzzzz1010111;
  localparam logic [31:0] VMSBF_M          = 32'b010100zzzzzz00001010zzzzz1010111;
  localparam logic [31:0] VMSIF_M          = 32'b010100zzzzzz00011010zzzzz1010111;
  localparam logic [31:0] VMSOF_M          = 32'b010100zzzzzz00010010zzzzz1010111;
  localparam logic [31:0] VMUL_VV          = 32'b100101zzzzzzzzzzz010zzzzz1010111;
  localparam logic [31:0] VMULH_VV         = 32'b100111zzzzzzzzzzz010zzzzz1010111;
  localparam logic [31:0] VMULHSU_VV       = 32'b100110zzzzzzzzzzz010zzzzz1010111;
  localparam logic [31:0] VMULHU_VV        = 32'b100100zzzzzzzzzzz010zzzzz1010111;
  localparam logic [31:0] VMV_X_S          = 32'b0100001zzzzz00000010zzzzz1010111;
  localparam logic [31:0] VNMSAC_VV        = 32'b101111zzzzzzzzzzz010zzzzz1010111;
  localparam logic [31:0] VNMSUB_VV        = 32'b101011zzzzzzzzzzz010zzzzz1010111;
  localparam logic [31:0] VREDAND_VS       = 32'b000001zzzzzzzzzzz010zzzzz1010111;
  localparam logic [31:0] VREDMAX_VS       = 32'b000111zzzzzzzzzzz010zzzzz1010111;
  localparam logic [31:0] VREDMAXU_VS      = 32'b000110zzzzzzzzzzz010zzzzz1010111;
  localparam logic [31:0] VREDMIN_VS       = 32'b000101zzzzzzzzzzz010zzzzz1010111;
  localparam logic [31:0] VREDMINU_VS      = 32'b000100zzzzzzzzzzz010zzzzz1010111;
  localparam logic [31:0] VREDOR_VS        = 32'b000010zzzzzzzzzzz010zzzzz1010111;
  localparam logic [31:0] VREDSUM_VS       = 32'b000000zzzzzzzzzzz010zzzzz1010111;
  localparam logic [31:0] VREDXOR_VS       = 32'b000011zzzzzzzzzzz010zzzzz1010111;
  localparam logic [31:0] VREM_VV          = 32'b100011zzzzzzzzzzz010zzzzz1010111;
  localparam logic [31:0] VREMU_VV         = 32'b100010zzzzzzzzzzz010zzzzz1010111;
  localparam logic [31:0] VSEXT_VF2        = 32'b010010zzzzzz00111010zzzzz1010111;
  localparam logic [31:0] VSEXT_VF4        = 32'b010010zzzzzz00101010zzzzz1010111;
  localparam logic [31:0] VSEXT_VF8        = 32'b010010zzzzzz00011010zzzzz1010111;
  localparam logic [31:0] VZEXT_VF2        = 32'b010010zzzzzz00110010zzzzz1010111;
  localparam logic [31:0] VZEXT_VF4        = 32'b010010zzzzzz00100010zzzzz1010111;
  localparam logic [31:0] VZEXT_VF8        = 32'b010010zzzzzz00010010zzzzz1010111;
  localparam logic [31:0] VWADD_VV         = 32'b110001zzzzzzzzzzz010zzzzz1010111;
  localparam logic [31:0] VWADD_WV         = 32'b110101zzzzzzzzzzz010zzzzz1010111;
  localparam logic [31:0] VWADDU_VV        = 32'b110000zzzzzzzzzzz010zzzzz1010111;
  localparam logic [31:0] VWADDU_WV        = 32'b110100zzzzzzzzzzz010zzzzz1010111;
  localparam logic [31:0] VWMACC_VV        = 32'b111101zzzzzzzzzzz010zzzzz1010111;
  localparam logic [31:0] VWMACCSU_VV      = 32'b111111zzzzzzzzzzz010zzzzz1010111;
  localparam logic [31:0] VWMACCU_VV       = 32'b111100zzzzzzzzzzz010zzzzz1010111;
  localparam logic [31:0] VWMUL_VV         = 32'b111011zzzzzzzzzzz010zzzzz1010111;
  localparam logic [31:0] VWMULSU_VV       = 32'b111010zzzzzzzzzzz010zzzzz1010111;
  localparam logic [31:0] VWMULU_VV        = 32'b111000zzzzzzzzzzz010zzzzz1010111;
  localparam logic [31:0] VWSUB_VV         = 32'b110011zzzzzzzzzzz010zzzzz1010111;
  localparam logic [31:0] VWSUB_WV         = 32'b110111zzzzzzzzzzz010zzzzz1010111;
  localparam logic [31:0] VWSUBU_VV        = 32'b110010zzzzzzzzzzz010zzzzz1010111;
  localparam logic [31:0] VWSUBU_WV        = 32'b110110zzzzzzzzzzz010zzzzz1010111;
  localparam logic [31:0] VBREV_V          = 32'b010010zzzzzz01010010zzzzz1010111;
  localparam logic [31:0] VBREV8_V         = 32'b010010zzzzzz01000010zzzzz1010111;
  localparam logic [31:0] VREV8_V          = 32'b010010zzzzzz01001010zzzzz1010111;
  localparam logic [31:0] VCLZ_V           = 32'b010010zzzzzz01100010zzzzz1010111;
  localparam logic [31:0] VCTZ_V           = 32'b010010zzzzzz01101010zzzzz1010111;
  localparam logic [31:0] VCPOP_V          = 32'b010010zzzzzz01110010zzzzz1010111;
  localparam logic [31:0] VAADD_VX         = 32'b001001zzzzzzzzzzz110zzzzz1010111;
  localparam logic [31:0] VAADDU_VX        = 32'b001000zzzzzzzzzzz110zzzzz1010111;
  localparam logic [31:0] VASUB_VX         = 32'b001011zzzzzzzzzzz110zzzzz1010111;
  localparam logic [31:0] VASUBU_VX        = 32'b001010zzzzzzzzzzz110zzzzz1010111;
  localparam logic [31:0] VDIV_VX          = 32'b100001zzzzzzzzzzz110zzzzz1010111;
  localparam logic [31:0] VDIVU_VX         = 32'b100000zzzzzzzzzzz110zzzzz1010111;
  localparam logic [31:0] VMACC_VX         = 32'b101101zzzzzzzzzzz110zzzzz1010111;
  localparam logic [31:0] VMADD_VX         = 32'b101001zzzzzzzzzzz110zzzzz1010111;
  localparam logic [31:0] VMUL_VX          = 32'b100101zzzzzzzzzzz110zzzzz1010111;
  localparam logic [31:0] VMULH_VX         = 32'b100111zzzzzzzzzzz110zzzzz1010111;
  localparam logic [31:0] VMULHSU_VX       = 32'b100110zzzzzzzzzzz110zzzzz1010111;
  localparam logic [31:0] VMULHU_VX        = 32'b100100zzzzzzzzzzz110zzzzz1010111;
  localparam logic [31:0] VMV_S_X          = 32'b010000100000zzzzz110zzzzz1010111;
  localparam logic [31:0] VNMSAC_VX        = 32'b101111zzzzzzzzzzz110zzzzz1010111;
  localparam logic [31:0] VNMSUB_VX        = 32'b101011zzzzzzzzzzz110zzzzz1010111;
  localparam logic [31:0] VREM_VX          = 32'b100011zzzzzzzzzzz110zzzzz1010111;
  localparam logic [31:0] VREMU_VX         = 32'b100010zzzzzzzzzzz110zzzzz1010111;
  localparam logic [31:0] VSLIDE1DOWN_VX   = 32'b001111zzzzzzzzzzz110zzzzz1010111;
  localparam logic [31:0] VSLIDE1UP_VX     = 32'b001110zzzzzzzzzzz110zzzzz1010111;
  localparam logic [31:0] VWADD_VX         = 32'b110001zzzzzzzzzzz110zzzzz1010111;
  localparam logic [31:0] VWADD_WX         = 32'b110101zzzzzzzzzzz110zzzzz1010111;
  localparam logic [31:0] VWADDU_VX        = 32'b110000zzzzzzzzzzz110zzzzz1010111;
  localparam logic [31:0] VWADDU_WX        = 32'b110100zzzzzzzzzzz110zzzzz1010111;
  localparam logic [31:0] VWMACC_VX        = 32'b111101zzzzzzzzzzz110zzzzz1010111;
  localparam logic [31:0] VWMACCSU_VX      = 32'b111111zzzzzzzzzzz110zzzzz1010111;
  localparam logic [31:0] VWMACCU_VX       = 32'b111100zzzzzzzzzzz110zzzzz1010111;
  localparam logic [31:0] VWMACCUS_VX      = 32'b111110zzzzzzzzzzz110zzzzz1010111;
  localparam logic [31:0] VWMUL_VX         = 32'b111011zzzzzzzzzzz110zzzzz1010111;
  localparam logic [31:0] VWMULSU_VX       = 32'b111010zzzzzzzzzzz110zzzzz1010111;
  localparam logic [31:0] VWMULU_VX        = 32'b111000zzzzzzzzzzz110zzzzz1010111;
  localparam logic [31:0] VWSUB_VX         = 32'b110011zzzzzzzzzzz110zzzzz1010111;
  localparam logic [31:0] VWSUB_WX         = 32'b110111zzzzzzzzzzz110zzzzz1010111;
  localparam logic [31:0] VWSUBU_VX        = 32'b110010zzzzzzzzzzz110zzzzz1010111;
  localparam logic [31:0] VWSUBU_WX        = 32'b110110zzzzzzzzzzz110zzzzz1010111;
  localparam logic [31:0] VFADD_VV         = 32'b000000zzzzzzzzzzz001zzzzz1010111;
  localparam logic [31:0] VFSUB_VV         = 32'b000010zzzzzzzzzzz001zzzzz1010111;
  localparam logic [31:0] VFWADD_VV        = 32'b110000zzzzzzzzzzz001zzzzz1010111;
  localparam logic [31:0] VFWSUB_VV        = 32'b110010zzzzzzzzzzz001zzzzz1010111;
  localparam logic [31:0] VFWADD_WV        = 32'b110100zzzzzzzzzzz001zzzzz1010111;
  localparam logic [31:0] VFWSUB_WV        = 32'b110110zzzzzzzzzzz001zzzzz1010111;
  localparam logic [31:0] VFMUL_VV         = 32'b100100zzzzzzzzzzz001zzzzz1010111;
  localparam logic [31:0] VFDIV_VV         = 32'b100000zzzzzzzzzzz001zzzzz1010111;
  localparam logic [31:0] VFWMUL_VV        = 32'b111000zzzzzzzzzzz001zzzzz1010111;
  localparam logic [31:0] VFMACC_VV        = 32'b101100zzzzzzzzzzz001zzzzz1010111;
  localparam logic [31:0] VFNMACC_VV       = 32'b101101zzzzzzzzzzz001zzzzz1010111;
  localparam logic [31:0] VFMSAC_VV        = 32'b101110zzzzzzzzzzz001zzzzz1010111;
  localparam logic [31:0] VFNMSAC_VV       = 32'b101111zzzzzzzzzzz001zzzzz1010111;
  localparam logic [31:0] VFMADD_VV        = 32'b101000zzzzzzzzzzz001zzzzz1010111;
  localparam logic [31:0] VFNMADD_VV       = 32'b101001zzzzzzzzzzz001zzzzz1010111;
  localparam logic [31:0] VFMSUB_VV        = 32'b101010zzzzzzzzzzz001zzzzz1010111;
  localparam logic [31:0] VFNMSUB_VV       = 32'b101011zzzzzzzzzzz001zzzzz1010111;
  localparam logic [31:0] VFWMACC_VV       = 32'b111100zzzzzzzzzzz001zzzzz1010111;
  localparam logic [31:0] VFWNMACC_VV      = 32'b111101zzzzzzzzzzz001zzzzz1010111;
  localparam logic [31:0] VFWMSAC_VV       = 32'b111110zzzzzzzzzzz001zzzzz1010111;
  localparam logic [31:0] VFWNMSAC_VV      = 32'b111111zzzzzzzzzzz001zzzzz1010111;
  localparam logic [31:0] VFSQRT_V         = 32'b010011zzzzzz00000001zzzzz1010111;
  localparam logic [31:0] VFRSQRT7_V       = 32'b010011zzzzzz00100001zzzzz1010111;
  localparam logic [31:0] VFREC7_V         = 32'b010011zzzzzz00101001zzzzz1010111;
  localparam logic [31:0] VFMIN_VV         = 32'b000100zzzzzzzzzzz001zzzzz1010111;
  localparam logic [31:0] VFMAX_VV         = 32'b000110zzzzzzzzzzz001zzzzz1010111;
  localparam logic [31:0] VFSGNJ_VV        = 32'b001000zzzzzzzzzzz001zzzzz1010111;
  localparam logic [31:0] VFSGNJN_VV       = 32'b001001zzzzzzzzzzz001zzzzz1010111;
  localparam logic [31:0] VFSGNJX_VV       = 32'b001010zzzzzzzzzzz001zzzzz1010111;
  localparam logic [31:0] VMFEQ_VV         = 32'b011000zzzzzzzzzzz001zzzzz1010111;
  localparam logic [31:0] VMFNE_VV         = 32'b011100zzzzzzzzzzz001zzzzz1010111;
  localparam logic [31:0] VMFLT_VV         = 32'b011011zzzzzzzzzzz001zzzzz1010111;
  localparam logic [31:0] VMFLE_VV         = 32'b011001zzzzzzzzzzz001zzzzz1010111;
  localparam logic [31:0] VFCLASS_V        = 32'b010011zzzzzz10000001zzzzz1010111;
  localparam logic [31:0] VFCVT_XU_F_V     = 32'b010010zzzzzz00000001zzzzz1010111;
  localparam logic [31:0] VFCVT_X_F_V      = 32'b010010zzzzzz00001001zzzzz1010111;
  localparam logic [31:0] VFCVT_RTZ_XU_F_V = 32'b010010zzzzzz00110001zzzzz1010111;
  localparam logic [31:0] VFCVT_RTZ_X_F_V  = 32'b010010zzzzzz00111001zzzzz1010111;
  localparam logic [31:0] VFCVT_F_XU_V     = 32'b010010zzzzzz00010001zzzzz1010111;
  localparam logic [31:0] VFCVT_F_X_V      = 32'b010010zzzzzz00011001zzzzz1010111;
  localparam logic [31:0] VFWCVT_XU_F_V    = 32'b010010zzzzzz01000001zzzzz1010111;
  localparam logic [31:0] VFWCVT_X_F_V     = 32'b010010zzzzzz01001001zzzzz1010111;
  localparam logic [31:0] VFWCVT_RTZ_XU_F_V = 32'b010010zzzzzz01110001zzzzz1010111;
  localparam logic [31:0] VFWCVT_RTZ_X_F_V = 32'b010010zzzzzz01111001zzzzz1010111;
  localparam logic [31:0] VFWCVT_F_XU_V    = 32'b010010zzzzzz01010001zzzzz1010111;
  localparam logic [31:0] VFWCVT_F_X_V     = 32'b010010zzzzzz01011001zzzzz1010111;
  localparam logic [31:0] VFWCVT_F_F_V     = 32'b010010zzzzzz01100001zzzzz1010111;
  localparam logic [31:0] VFNCVT_XU_F_W    = 32'b010010zzzzzz10000001zzzzz1010111;
  localparam logic [31:0] VFNCVT_X_F_W     = 32'b010010zzzzzz10001001zzzzz1010111;
  localparam logic [31:0] VFNCVT_RTZ_XU_F_W = 32'b010010zzzzzz10110001zzzzz1010111;
  localparam logic [31:0] VFNCVT_RTZ_X_F_W = 32'b010010zzzzzz10111001zzzzz1010111;
  localparam logic [31:0] VFNCVT_F_XU_W    = 32'b010010zzzzzz10010001zzzzz1010111;
  localparam logic [31:0] VFNCVT_F_X_W     = 32'b010010zzzzzz10011001zzzzz1010111;
  localparam logic [31:0] VFNCVT_F_F_W     = 32'b010010zzzzzz10100001zzzzz1010111;
  localparam logic [31:0] VFNCVT_ROD_F_F_W = 32'b010010zzzzzz10101001zzzzz1010111;
  localparam logic [31:0] VFREDOSUM_VS     = 32'b000011zzzzzzzzzzz001zzzzz1010111;
  localparam logic [31:0] VFREDUSUM_VS     = 32'b000001zzzzzzzzzzz001zzzzz1010111;
  localparam logic [31:0] VFREDMAX_VS      = 32'b000111zzzzzzzzzzz001zzzzz1010111;
  localparam logic [31:0] VFREDMIN_VS      = 32'b000101zzzzzzzzzzz001zzzzz1010111;
  localparam logic [31:0] VFWREDOSUM_VS    = 32'b110011zzzzzzzzzzz001zzzzz1010111;
  localparam logic [31:0] VFWREDUSUM_VS    = 32'b110001zzzzzzzzzzz001zzzzz1010111;
  localparam logic [31:0] VFADD_VF         = 32'b000000zzzzzzzzzzz101zzzzz1010111;
  localparam logic [31:0] VFSUB_VF         = 32'b000010zzzzzzzzzzz101zzzzz1010111;
  localparam logic [31:0] VFRSUB_VF        = 32'b100111zzzzzzzzzzz101zzzzz1010111;
  localparam logic [31:0] VFWADD_VF        = 32'b110000zzzzzzzzzzz101zzzzz1010111;
  localparam logic [31:0] VFWSUB_VF        = 32'b110010zzzzzzzzzzz101zzzzz1010111;
  localparam logic [31:0] VFWADD_WF        = 32'b110100zzzzzzzzzzz101zzzzz1010111;
  localparam logic [31:0] VFWSUB_WF        = 32'b110110zzzzzzzzzzz101zzzzz1010111;
  localparam logic [31:0] VFMUL_VF         = 32'b100100zzzzzzzzzzz101zzzzz1010111;
  localparam logic [31:0] VFDIV_VF         = 32'b100000zzzzzzzzzzz101zzzzz1010111;
  localparam logic [31:0] VFRDIV_VF        = 32'b100001zzzzzzzzzzz101zzzzz1010111;
  localparam logic [31:0] VFWMUL_VF        = 32'b111000zzzzzzzzzzz101zzzzz1010111;
  localparam logic [31:0] VFMACC_VF        = 32'b101100zzzzzzzzzzz101zzzzz1010111;
  localparam logic [31:0] VFNMACC_VF       = 32'b101101zzzzzzzzzzz101zzzzz1010111;
  localparam logic [31:0] VFMSAC_VF        = 32'b101110zzzzzzzzzzz101zzzzz1010111;
  localparam logic [31:0] VFNMSAC_VF       = 32'b101111zzzzzzzzzzz101zzzzz1010111;
  localparam logic [31:0] VFMADD_VF        = 32'b101000zzzzzzzzzzz101zzzzz1010111;
  localparam logic [31:0] VFNMADD_VF       = 32'b101001zzzzzzzzzzz101zzzzz1010111;
  localparam logic [31:0] VFMSUB_VF        = 32'b101010zzzzzzzzzzz101zzzzz1010111;
  localparam logic [31:0] VFNMSUB_VF       = 32'b101011zzzzzzzzzzz101zzzzz1010111;
  localparam logic [31:0] VFWMACC_VF       = 32'b111100zzzzzzzzzzz101zzzzz1010111;
  localparam logic [31:0] VFWNMACC_VF      = 32'b111101zzzzzzzzzzz101zzzzz1010111;
  localparam logic [31:0] VFWMSAC_VF       = 32'b111110zzzzzzzzzzz101zzzzz1010111;
  localparam logic [31:0] VFWNMSAC_VF      = 32'b111111zzzzzzzzzzz101zzzzz1010111;
  localparam logic [31:0] VFMIN_VF         = 32'b000100zzzzzzzzzzz101zzzzz1010111;
  localparam logic [31:0] VFMAX_VF         = 32'b000110zzzzzzzzzzz101zzzzz1010111;
  localparam logic [31:0] VFSGNJ_VF        = 32'b001000zzzzzzzzzzz101zzzzz1010111;
  localparam logic [31:0] VFSGNJN_VF       = 32'b001001zzzzzzzzzzz101zzzzz1010111;
  localparam logic [31:0] VFSGNJX_VF       = 32'b001010zzzzzzzzzzz101zzzzz1010111;
  localparam logic [31:0] VMFEQ_VF         = 32'b011000zzzzzzzzzzz101zzzzz1010111;
  localparam logic [31:0] VMFNE_VF         = 32'b011100zzzzzzzzzzz101zzzzz1010111;
  localparam logic [31:0] VMFLT_VF         = 32'b011011zzzzzzzzzzz101zzzzz1010111;
  localparam logic [31:0] VMFLE_VF         = 32'b011001zzzzzzzzzzz101zzzzz1010111;
  localparam logic [31:0] VMFGT_VF         = 32'b011101zzzzzzzzzzz101zzzzz1010111;
  localparam logic [31:0] VMFGE_VF         = 32'b011111zzzzzzzzzzz101zzzzz1010111;
  localparam logic [31:0] VFMERGE_VFM      = 32'b0101110zzzzzzzzzz101zzzzz1010111;
  localparam logic [31:0] VFMV_V_F         = 32'b010111100000zzzzz101zzzzz1010111;
  localparam logic [31:0] VFMV_F_S         = 32'b0100001zzzzz00000001zzzzz1010111;
  localparam logic [31:0] VFMV_S_F         = 32'b010000100000zzzzz101zzzzz1010111;
  localparam logic [31:0] VFSLIDE1UP_VF    = 32'b001110zzzzzzzzzzz101zzzzz1010111;
  localparam logic [31:0] VFSLIDE1DOWN_VF  = 32'b001111zzzzzzzzzzz101zzzzz1010111;
  localparam logic [31:0] FADD_S           = 32'b0000000zzzzzzzzzzzzzzzzzz1010011;
  localparam logic [31:0] FADD_D           = 32'b0000001zzzzzzzzzzzzzzzzzz1010011;
  localparam logic [31:0] FADD_H           = 32'b0000010zzzzzzzzzzzzzzzzzz1010011;
  localparam logic [31:0] FSUB_S           = 32'b0000100zzzzzzzzzzzzzzzzzz1010011;
  localparam logic [31:0] FSUB_D           = 32'b0000101zzzzzzzzzzzzzzzzzz1010011;
  localparam logic [31:0] FSUB_H           = 32'b0000110zzzzzzzzzzzzzzzzzz1010011;
  localparam logic [31:0] FEQ_S            = 32'b1010000zzzzzzzzzz010zzzzz1010011;
  localparam logic [31:0] FLT_S            = 32'b1010000zzzzzzzzzz001zzzzz1010011;
  localparam logic [31:0] FLE_S            = 32'b1010000zzzzzzzzzz000zzzzz1010011;
  localparam logic [31:0] FEQ_D            = 32'b1010001zzzzzzzzzz010zzzzz1010011;
  localparam logic [31:0] FLT_D            = 32'b1010001zzzzzzzzzz001zzzzz1010011;
  localparam logic [31:0] FLE_D            = 32'b1010001zzzzzzzzzz000zzzzz1010011;
  localparam logic [31:0] FEQ_H            = 32'b1010010zzzzzzzzzz010zzzzz1010011;
  localparam logic [31:0] FLT_H            = 32'b1010010zzzzzzzzzz001zzzzz1010011;
  localparam logic [31:0] FLE_H            = 32'b1010010zzzzzzzzzz000zzzzz1010011;
  localparam logic [31:0] FMIN_S           = 32'b0010100zzzzzzzzzz000zzzzz1010011;
  localparam logic [31:0] FMIN_D           = 32'b0010101zzzzzzzzzz000zzzzz1010011;
  localparam logic [31:0] FMAX_S           = 32'b0010100zzzzzzzzzz001zzzzz1010011;
  localparam logic [31:0] FMAX_D           = 32'b0010101zzzzzzzzzz001zzzzz1010011;
  localparam logic [31:0] FMIN_H           = 32'b0010110zzzzzzzzzz000zzzzz1010011;
  localparam logic [31:0] FMAX_H           = 32'b0010110zzzzzzzzzz001zzzzz1010011;
  localparam logic [31:0] FCVT_W_S         = 32'b110000000000zzzzzzzzzzzzz1010011;
  localparam logic [31:0] FCVT_WU_S        = 32'b110000000001zzzzzzzzzzzzz1010011;
  localparam logic [31:0] FCVT_L_S         = 32'b110000000010zzzzzzzzzzzzz1010011;
  localparam logic [31:0] FCVT_LU_S        = 32'b110000000011zzzzzzzzzzzzz1010011;
  localparam logic [31:0] FCVT_W_D         = 32'b110000100000zzzzzzzzzzzzz1010011;
  localparam logic [31:0] FCVT_WU_D        = 32'b110000100001zzzzzzzzzzzzz1010011;
  localparam logic [31:0] FCVT_L_D         = 32'b110000100010zzzzzzzzzzzzz1010011;
  localparam logic [31:0] FCVT_LU_D        = 32'b110000100011zzzzzzzzzzzzz1010011;
  localparam logic [31:0] FCVT_S_D         = 32'b010000000001zzzzzzzzzzzzz1010011;
  localparam logic [31:0] FCVT_D_S         = 32'b010000100000zzzzzzzzzzzzz1010011;
  localparam logic [31:0] FCVT_H_S         = 32'b010001000000zzzzzzzzzzzzz1010011;
  localparam logic [31:0] FCVT_S_H         = 32'b010000000010zzzzzzzzzzzzz1010011;
  localparam logic [31:0] FCVT_H_D         = 32'b010001000001zzzzzzzzzzzzz1010011;
  localparam logic [31:0] FCVT_D_H         = 32'b010000100010zzzzzzzzzzzzz1010011;
  localparam logic [31:0] FCVT_W_H         = 32'b110001000000zzzzzzzzzzzzz1010011;
  localparam logic [31:0] FCVT_WU_H        = 32'b110001000001zzzzzzzzzzzzz1010011;
  localparam logic [31:0] FCVT_L_H         = 32'b110001000010zzzzzzzzzzzzz1010011;
  localparam logic [31:0] FCVT_LU_H        = 32'b110001000011zzzzzzzzzzzzz1010011;
  localparam logic [31:0] FMV_X_D          = 32'b111000100000zzzzz000zzzzz1010011;
  localparam logic [31:0] FMV_X_W          = 32'b111000000000zzzzz000zzzzz1010011;
  localparam logic [31:0] FMV_X_H          = 32'b111001000000zzzzz000zzzzz1010011;
  localparam logic [31:0] FCLASS_S         = 32'b111000000000zzzzz001zzzzz1010011;
  localparam logic [31:0] FCLASS_D         = 32'b111000100000zzzzz001zzzzz1010011;
  localparam logic [31:0] FCLASS_H         = 32'b111001000000zzzzz001zzzzz1010011;
  localparam logic [31:0] FSGNJ_S          = 32'b0010000zzzzzzzzzz000zzzzz1010011;
  localparam logic [31:0] FSGNJ_D          = 32'b0010001zzzzzzzzzz000zzzzz1010011;
  localparam logic [31:0] FSGNJ_H          = 32'b0010010zzzzzzzzzz000zzzzz1010011;
  localparam logic [31:0] FSGNJX_S         = 32'b0010000zzzzzzzzzz010zzzzz1010011;
  localparam logic [31:0] FSGNJX_D         = 32'b0010001zzzzzzzzzz010zzzzz1010011;
  localparam logic [31:0] FSGNJX_H         = 32'b0010010zzzzzzzzzz010zzzzz1010011;
  localparam logic [31:0] FSGNJN_S         = 32'b0010000zzzzzzzzzz001zzzzz1010011;
  localparam logic [31:0] FSGNJN_D         = 32'b0010001zzzzzzzzzz001zzzzz1010011;
  localparam logic [31:0] FSGNJN_H         = 32'b0010010zzzzzzzzzz001zzzzz1010011;
  localparam logic [31:0] FMUL_S           = 32'b0001000zzzzzzzzzzzzzzzzzz1010011;
  localparam logic [31:0] FMUL_D           = 32'b0001001zzzzzzzzzzzzzzzzzz1010011;
  localparam logic [31:0] FMUL_H           = 32'b0001010zzzzzzzzzzzzzzzzzz1010011;
  localparam logic [31:0] FDIV_S           = 32'b0001100zzzzzzzzzzzzzzzzzz1010011;
  localparam logic [31:0] FDIV_D           = 32'b0001101zzzzzzzzzzzzzzzzzz1010011;
  localparam logic [31:0] FDIV_H           = 32'b0001110zzzzzzzzzzzzzzzzzz1010011;
  localparam logic [31:0] FSQRT_S          = 32'b010110000000zzzzzzzzzzzzz1010011;
  localparam logic [31:0] FSQRT_D          = 32'b010110100000zzzzzzzzzzzzz1010011;
  localparam logic [31:0] FSQRT_H          = 32'b010111000000zzzzzzzzzzzzz1010011;
  localparam logic [31:0] FMADD_S          = 32'bzzzzz00zzzzzzzzzzzzzzzzzz1000011;
  localparam logic [31:0] FMSUB_S          = 32'bzzzzz00zzzzzzzzzzzzzzzzzz1000111;
  localparam logic [31:0] FNMADD_S         = 32'bzzzzz00zzzzzzzzzzzzzzzzzz1001111;
  localparam logic [31:0] FNMSUB_S         = 32'bzzzzz00zzzzzzzzzzzzzzzzzz1001011;
  localparam logic [31:0] FMADD_D          = 32'bzzzzz01zzzzzzzzzzzzzzzzzz1000011;
  localparam logic [31:0] FMSUB_D          = 32'bzzzzz01zzzzzzzzzzzzzzzzzz1000111;
  localparam logic [31:0] FNMADD_D         = 32'bzzzzz01zzzzzzzzzzzzzzzzzz1001111;
  localparam logic [31:0] FNMSUB_D         = 32'bzzzzz01zzzzzzzzzzzzzzzzzz1001011;
  localparam logic [31:0] FMADD_H          = 32'bzzzzz10zzzzzzzzzzzzzzzzzz1000011;
  localparam logic [31:0] FMSUB_H          = 32'bzzzzz10zzzzzzzzzzzzzzzzzz1000111;
  localparam logic [31:0] FNMADD_H         = 32'bzzzzz10zzzzzzzzzzzzzzzzzz1001111;
  localparam logic [31:0] FNMSUB_H         = 32'bzzzzz10zzzzzzzzzzzzzzzzzz1001011;
  localparam logic [31:0] VLE8_V           = 32'bzzz000z00000zzzzz000zzzzz0000111;
  localparam logic [31:0] VLE16_V          = 32'bzzz000z00000zzzzz101zzzzz0000111;
  localparam logic [31:0] VLE32_V          = 32'bzzz000z00000zzzzz110zzzzz0000111;
  localparam logic [31:0] VLE64_V          = 32'bzzz000z00000zzzzz111zzzzz0000111;
  localparam logic [31:0] VSE8_V           = 32'bzzz000z00000zzzzz000zzzzz0100111;
  localparam logic [31:0] VSE16_V          = 32'bzzz000z00000zzzzz101zzzzz0100111;
  localparam logic [31:0] VSE32_V          = 32'bzzz000z00000zzzzz110zzzzz0100111;
  localparam logic [31:0] VSE64_V          = 32'bzzz000z00000zzzzz111zzzzz0100111;
  localparam logic [31:0] VLM_V            = 32'b000000101011zzzzz000zzzzz0000111;
  localparam logic [31:0] VSM_V            = 32'b000000101011zzzzz000zzzzz0100111;
  localparam logic [31:0] VLSE8_V          = 32'bzzz010zzzzzzzzzzz000zzzzz0000111;
  localparam logic [31:0] VLSE16_V         = 32'bzzz010zzzzzzzzzzz101zzzzz0000111;
  localparam logic [31:0] VLSE32_V         = 32'bzzz010zzzzzzzzzzz110zzzzz0000111;
  localparam logic [31:0] VLSE64_V         = 32'bzzz010zzzzzzzzzzz111zzzzz0000111;
  localparam logic [31:0] VSSE8_V          = 32'bzzz010zzzzzzzzzzz000zzzzz0100111;
  localparam logic [31:0] VSSE16_V         = 32'bzzz010zzzzzzzzzzz101zzzzz0100111;
  localparam logic [31:0] VSSE32_V         = 32'bzzz010zzzzzzzzzzz110zzzzz0100111;
  localparam logic [31:0] VSSE64_V         = 32'bzzz010zzzzzzzzzzz111zzzzz0100111;
  localparam logic [31:0] VLUXEI8_V        = 32'bzzz001zzzzzzzzzzz000zzzzz0000111;
  localparam logic [31:0] VLUXEI16_V       = 32'bzzz001zzzzzzzzzzz101zzzzz0000111;
  localparam logic [31:0] VLUXEI32_V       = 32'bzzz001zzzzzzzzzzz110zzzzz0000111;
  localparam logic [31:0] VLUXEI64_V       = 32'bzzz001zzzzzzzzzzz111zzzzz0000111;
  localparam logic [31:0] VLOXEI8_V        = 32'bzzz011zzzzzzzzzzz000zzzzz0000111;
  localparam logic [31:0] VLOXEI16_V       = 32'bzzz011zzzzzzzzzzz101zzzzz0000111;
  localparam logic [31:0] VLOXEI32_V       = 32'bzzz011zzzzzzzzzzz110zzzzz0000111;
  localparam logic [31:0] VLOXEI64_V       = 32'bzzz011zzzzzzzzzzz111zzzzz0000111;
  localparam logic [31:0] VSUXEI8_V        = 32'bzzz001zzzzzzzzzzz000zzzzz0100111;
  localparam logic [31:0] VSUXEI16_V       = 32'bzzz001zzzzzzzzzzz101zzzzz0100111;
  localparam logic [31:0] VSUXEI32_V       = 32'bzzz001zzzzzzzzzzz110zzzzz0100111;
  localparam logic [31:0] VSUXEI64_V       = 32'bzzz001zzzzzzzzzzz111zzzzz0100111;
  localparam logic [31:0] VSOXEI8_V        = 32'bzzz011zzzzzzzzzzz000zzzzz0100111;
  localparam logic [31:0] VSOXEI16_V       = 32'bzzz011zzzzzzzzzzz101zzzzz0100111;
  localparam logic [31:0] VSOXEI32_V       = 32'bzzz011zzzzzzzzzzz110zzzzz0100111;
  localparam logic [31:0] VSOXEI64_V       = 32'bzzz011zzzzzzzzzzz111zzzzz0100111;
  localparam logic [31:0] VLE8FF_V         = 32'bzzz000z10000zzzzz000zzzzz0000111;
  localparam logic [31:0] VLE16FF_V        = 32'bzzz000z10000zzzzz101zzzzz0000111;
  localparam logic [31:0] VLE32FF_V        = 32'bzzz000z10000zzzzz110zzzzz0000111;
  localparam logic [31:0] VLE64FF_V        = 32'bzzz000z10000zzzzz111zzzzz0000111;
  localparam logic [31:0] VL1RE8_V         = 32'b000000101000zzzzz000zzzzz0000111;
  localparam logic [31:0] VL1RE16_V        = 32'b000000101000zzzzz101zzzzz0000111;
  localparam logic [31:0] VL1RE32_V        = 32'b000000101000zzzzz110zzzzz0000111;
  localparam logic [31:0] VL1RE64_V        = 32'b000000101000zzzzz111zzzzz0000111;
  localparam logic [31:0] VL2RE8_V         = 32'b001000101000zzzzz000zzzzz0000111;
  localparam logic [31:0] VL2RE16_V        = 32'b001000101000zzzzz101zzzzz0000111;
  localparam logic [31:0] VL2RE32_V        = 32'b001000101000zzzzz110zzzzz0000111;
  localparam logic [31:0] VL2RE64_V        = 32'b001000101000zzzzz111zzzzz0000111;
  localparam logic [31:0] VL4RE8_V         = 32'b011000101000zzzzz000zzzzz0000111;
  localparam logic [31:0] VL4RE16_V        = 32'b011000101000zzzzz101zzzzz0000111;
  localparam logic [31:0] VL4RE32_V        = 32'b011000101000zzzzz110zzzzz0000111;
  localparam logic [31:0] VL4RE64_V        = 32'b011000101000zzzzz111zzzzz0000111;
  localparam logic [31:0] VL8RE8_V         = 32'b111000101000zzzzz000zzzzz0000111;
  localparam logic [31:0] VL8RE16_V        = 32'b111000101000zzzzz101zzzzz0000111;
  localparam logic [31:0] VL8RE32_V        = 32'b111000101000zzzzz110zzzzz0000111;
  localparam logic [31:0] VL8RE64_V        = 32'b111000101000zzzzz111zzzzz0000111;
  localparam logic [31:0] VS1R_V           = 32'b000000101000zzzzz000zzzzz0100111;
  localparam logic [31:0] VS2R_V           = 32'b001000101000zzzzz000zzzzz0100111;
  localparam logic [31:0] VS4R_V           = 32'b011000101000zzzzz000zzzzz0100111;
  localparam logic [31:0] VS8R_V           = 32'b111000101000zzzzz000zzzzz0100111;
  localparam logic [31:0] CZERO_EQZ        = 32'b0000111zzzzzzzzzz101zzzzz0110011;
  localparam logic [31:0] CZERO_NEZ        = 32'b0000111zzzzzzzzzz111zzzzz0110011;
  localparam logic [31:0] MOP_R            = 32'b1z00zz0111zzzzzzz100zzzzz1110011;
  localparam logic [31:0] MOP_RR           = 32'b1z00zz1zzzzzzzzzz100zzzzz1110011;
  localparam logic [31:0] FLI_H            = 32'b111101000001zzzzz000zzzzz1010011;
  localparam logic [31:0] FLI_S            = 32'b111100000001zzzzz000zzzzz1010011;
  localparam logic [31:0] FLI_D            = 32'b111100100001zzzzz000zzzzz1010011;
  localparam logic [31:0] FMINM_H          = 32'b0010110zzzzzzzzzz010zzzzz1010011;
  localparam logic [31:0] FMINM_S          = 32'b0010100zzzzzzzzzz010zzzzz1010011;
  localparam logic [31:0] FMINM_D          = 32'b0010101zzzzzzzzzz010zzzzz1010011;
  localparam logic [31:0] FMAXM_H          = 32'b0010110zzzzzzzzzz011zzzzz1010011;
  localparam logic [31:0] FMAXM_S          = 32'b0010100zzzzzzzzzz011zzzzz1010011;
  localparam logic [31:0] FMAXM_D          = 32'b0010101zzzzzzzzzz011zzzzz1010011;
  localparam logic [31:0] FROUND_H         = 32'b010001000100zzzzzzzzzzzzz1010011;
  localparam logic [31:0] FROUND_S         = 32'b010000000100zzzzzzzzzzzzz1010011;
  localparam logic [31:0] FROUND_D         = 32'b010000100100zzzzzzzzzzzzz1010011;
  localparam logic [31:0] FROUNDNX_H       = 32'b010001000101zzzzzzzzzzzzz1010011;
  localparam logic [31:0] FROUNDNX_S       = 32'b010000000101zzzzzzzzzzzzz1010011;
  localparam logic [31:0] FROUNDNX_D       = 32'b010000100101zzzzzzzzzzzzz1010011;
  localparam logic [31:0] FCVTMOD_W_D      = 32'b110000101000zzzzz001zzzzz1010011;
  localparam logic [31:0] FLEQ_H           = 32'b1010010zzzzzzzzzz100zzzzz1010011;
  localparam logic [31:0] FLEQ_S           = 32'b1010000zzzzzzzzzz100zzzzz1010011;
  localparam logic [31:0] FLEQ_D           = 32'b1010001zzzzzzzzzz100zzzzz1010011;
  localparam logic [31:0] FLTQ_H           = 32'b1010010zzzzzzzzzz101zzzzz1010011;
  localparam logic [31:0] FLTQ_S           = 32'b1010000zzzzzzzzzz101zzzzz1010011;
  localparam logic [31:0] FLTQ_D           = 32'b1010001zzzzzzzzzz101zzzzz1010011;
  // END GENERATED(insn_patterns)

  // 表外的三个模式（DecodeUnit.scala 里直接写 BitPat 的）
  localparam logic [31:0] ISMOVE_ADDI0 = 32'b000000000000zzzzz000zzzzz0010011;   // addi rd, rs1, 0
  // Zimop 的 MOP_R / MOP_RR 已在上面的表模式里（isZimop 就是这两条）

  // ---- 指令集合判据 ----
  // BEGIN GENERATED(insn_sets)
  // 由 verif/ut/DecodeUnit/gen.py 从 DecodeUnit.scala 的 `private val xxxInsts = Seq(…)` 机械生成；
  // Chisel 写法 `insts.map(_ === inst.ALL).reduce(_ || _)` 翻成 casez（z 位=通配）。

  // vpu.isReverse：源操作数要换位的指令（vrsub / vfrdiv / vfrsub / vfmv.f.s）（Scala: needReverseInsts，5 条）
  function automatic logic is_reverse_insn(input logic [31:0] i);
    casez (i)
      VRSUB_VI, VRSUB_VX, VFRDIV_VF, VFRSUB_VF, VFMV_F_S:
        return 1'b1;
      default: return 1'b0;
    endcase
  endfunction

  // vpu.isExt：整数扩展 vzext/vsext（Scala: vextInsts，6 条）
  function automatic logic is_vext_insn(input logic [31:0] i);
    casez (i)
      VZEXT_VF2, VZEXT_VF4, VZEXT_VF8, VSEXT_VF2, VSEXT_VF4, VSEXT_VF8:
        return 1'b1;
      default: return 1'b0;
    endcase
  endfunction

  // vpu.isNarrow：窄化指令 vnsra/vnsrl/vnclip(u)（Scala: narrowInsts，12 条）
  function automatic logic is_narrow_insn(input logic [31:0] i);
    casez (i)
      VNSRA_WV, VNSRA_WX, VNSRA_WI, VNSRL_WV, VNSRL_WX, VNSRL_WI,
      VNCLIP_WV, VNCLIP_WX, VNCLIP_WI, VNCLIPU_WV, VNCLIPU_WX, VNCLIPU_WI:
        return 1'b1;
      default: return 1'b0;
    endcase
  endfunction

  // vpu.isDstMask：结果写掩码寄存器的指令（Scala: maskDstInsts，48 条）
  function automatic logic is_mask_dst_insn(input logic [31:0] i);
    casez (i)
      VMADC_VV, VMADC_VX, VMADC_VI, VMADC_VVM, VMADC_VXM, VMADC_VIM,
      VMSBC_VV, VMSBC_VX, VMSBC_VVM, VMSBC_VXM, VMAND_MM, VMNAND_MM,
      VMANDN_MM, VMXOR_MM, VMOR_MM, VMNOR_MM, VMORN_MM, VMXNOR_MM,
      VMSEQ_VV, VMSEQ_VX, VMSEQ_VI, VMSNE_VV, VMSNE_VX, VMSNE_VI,
      VMSLE_VV, VMSLE_VX, VMSLE_VI, VMSLEU_VV, VMSLEU_VX, VMSLEU_VI,
      VMSLT_VV, VMSLT_VX, VMSLTU_VV, VMSLTU_VX, VMSGT_VX, VMSGT_VI,
      VMSGTU_VX, VMSGTU_VI, VMFEQ_VV, VMFEQ_VF, VMFNE_VV, VMFNE_VF,
      VMFLT_VV, VMFLT_VF, VMFLE_VV, VMFLE_VF, VMFGT_VF, VMFGE_VF:
        return 1'b1;
      default: return 1'b0;
    endcase
  endfunction

  // vpu.isOpMask：掩码逻辑指令 vm{and,nand,andn,xor,or,nor,orn,xnor}.mm（Scala: maskOpInsts，8 条）
  function automatic logic is_mask_op_insn(input logic [31:0] i);
    casez (i)
      VMAND_MM, VMNAND_MM, VMANDN_MM, VMXOR_MM, VMOR_MM, VMNOR_MM,
      VMORN_MM, VMXNOR_MM:
        return 1'b1;
      default: return 1'b0;
    endcase
  endfunction

  // 乘加类（依赖旧 vd）：vmacc/vnmsac/vmadd/vnmsub/vwmacc*（Scala: vmaInsts，15 条）
  function automatic logic is_vma_insn(input logic [31:0] i);
    casez (i)
      VMACC_VV, VMACC_VX, VNMSAC_VV, VNMSAC_VX, VMADD_VV, VMADD_VX,
      VNMSUB_VV, VNMSUB_VX, VWMACCU_VV, VWMACCU_VX, VWMACC_VV, VWMACC_VX,
      VWMACCSU_VV, VWMACCSU_VX, VWMACCUS_VX:
        return 1'b1;
      default: return 1'b0;
    endcase
  endfunction

  // decodedInst.wfflags：会写 fflags 的标量/向量浮点指令（Scala: wfflagsInsts，191 条）
  function automatic logic is_wfflags_insn(input logic [31:0] i);
    casez (i)
      FADD_S, FSUB_S, FADD_D, FSUB_D, FADD_H, FSUB_H,
      FEQ_S, FLT_S, FLE_S, FEQ_D, FLT_D, FLE_D,
      FEQ_H, FLT_H, FLE_H, FMIN_S, FMAX_S, FMIN_D,
      FMAX_D, FMIN_H, FMAX_H, FMUL_S, FMUL_D, FMUL_H,
      FDIV_S, FDIV_D, FSQRT_S, FSQRT_D, FDIV_H, FSQRT_H,
      FMADD_S, FMSUB_S, FNMADD_S, FNMSUB_S, FMADD_D, FMSUB_D,
      FNMADD_D, FNMSUB_D, FMADD_H, FMSUB_H, FNMADD_H, FNMSUB_H,
      FSGNJ_S, FSGNJN_S, FSGNJX_S, FSGNJ_H, FSGNJN_H, FSGNJX_H,
      VFADD_VV, VFSUB_VV, VFWADD_VV, VFWSUB_VV, VFWADD_WV, VFWSUB_WV,
      VFMUL_VV, VFDIV_VV, VFWMUL_VV, VFMACC_VV, VFNMACC_VV, VFMSAC_VV,
      VFNMSAC_VV, VFMADD_VV, VFNMADD_VV, VFMSUB_VV, VFNMSUB_VV, VFWMACC_VV,
      VFWNMACC_VV, VFWMSAC_VV, VFWNMSAC_VV, VFSQRT_V, VFMIN_VV, VFMAX_VV,
      VMFEQ_VV, VMFNE_VV, VMFLT_VV, VMFLE_VV, VFSGNJ_VV, VFSGNJN_VV,
      VFSGNJX_VV, VFADD_VF, VFSUB_VF, VFRSUB_VF, VFWADD_VF, VFWSUB_VF,
      VFWADD_WF, VFWSUB_WF, VFMUL_VF, VFDIV_VF, VFRDIV_VF, VFWMUL_VF,
      VFMACC_VF, VFNMACC_VF, VFMSAC_VF, VFNMSAC_VF, VFMADD_VF, VFNMADD_VF,
      VFMSUB_VF, VFNMSUB_VF, VFWMACC_VF, VFWNMACC_VF, VFWMSAC_VF, VFWNMSAC_VF,
      VFMIN_VF, VFMAX_VF, VMFEQ_VF, VMFNE_VF, VMFLT_VF, VMFLE_VF,
      VMFGT_VF, VMFGE_VF, VFSGNJ_VF, VFSGNJN_VF, VFSGNJX_VF, VFREDOSUM_VS,
      VFREDUSUM_VS, VFREDMAX_VS, VFREDMIN_VS, VFWREDOSUM_VS, VFWREDUSUM_VS, FCVT_S_W,
      FCVT_S_WU, FCVT_S_L, FCVT_S_LU, FCVT_W_S, FCVT_WU_S, FCVT_L_S,
      FCVT_LU_S, FCVT_D_W, FCVT_D_WU, FCVT_D_L, FCVT_D_LU, FCVT_W_D,
      FCVT_WU_D, FCVT_L_D, FCVT_LU_D, FCVT_S_D, FCVT_D_S, FCVT_S_H,
      FCVT_H_S, FCVT_H_D, FCVT_D_H, FCVT_H_W, FCVT_H_WU, FCVT_H_L,
      FCVT_H_LU, FCVT_W_H, FCVT_WU_H, FCVT_L_H, FCVT_LU_H, VFCVT_XU_F_V,
      VFCVT_X_F_V, VFCVT_RTZ_XU_F_V, VFCVT_RTZ_X_F_V, VFCVT_F_XU_V, VFCVT_F_X_V, VFWCVT_XU_F_V,
      VFWCVT_X_F_V, VFWCVT_RTZ_XU_F_V, VFWCVT_RTZ_X_F_V, VFWCVT_F_XU_V, VFWCVT_F_X_V, VFWCVT_F_F_V,
      VFNCVT_XU_F_W, VFNCVT_X_F_W, VFNCVT_RTZ_XU_F_W, VFNCVT_RTZ_X_F_W, VFNCVT_F_XU_W, VFNCVT_F_X_W,
      VFNCVT_F_F_W, VFNCVT_ROD_F_F_W, VFRSQRT7_V, VFREC7_V, FLEQ_H, FLEQ_S,
      FLEQ_D, FLTQ_H, FLTQ_S, FLTQ_D, FMINM_H, FMINM_S,
      FMINM_D, FMAXM_H, FMAXM_S, FMAXM_D, FROUND_H, FROUND_S,
      FROUND_D, FROUNDNX_H, FROUNDNX_S, FROUNDNX_D, FCVTMOD_W_D:
        return 1'b1;
      default: return 1'b0;
    endcase
  endfunction

  // needFrm.scalaNeedFrm：标量浮点里要读 frm 的指令（Scala: scalaNeedFrmInsts，30 条）
  function automatic logic is_scalar_need_frm_insn(input logic [31:0] i);
    casez (i)
      FADD_S, FSUB_S, FADD_D, FSUB_D, FADD_H, FSUB_H,
      FCVT_W_S, FCVT_WU_S, FCVT_L_S, FCVT_LU_S, FCVT_W_D, FCVT_WU_D,
      FCVT_L_D, FCVT_LU_D, FCVT_S_D, FCVT_D_S, FCVT_W_H, FCVT_WU_H,
      FCVT_L_H, FCVT_LU_H, FCVT_S_H, FCVT_H_S, FCVT_H_D, FCVT_D_H,
      FROUND_H, FROUND_S, FROUND_D, FROUNDNX_H, FROUNDNX_S, FROUNDNX_D:
        return 1'b1;
      default: return 1'b0;
    endcase
  endfunction

  // needFrm.vectorNeedFrm：vfslide1up/down.vf（Scala: vectorNeedFrmInsts，2 条）
  function automatic logic is_vector_need_frm_insn(input logic [31:0] i);
    casez (i)
      VFSLIDE1UP_VF, VFSLIDE1DOWN_VF:
        return 1'b1;
      default: return 1'b0;
    endcase
  endfunction
  // END GENERATED(insn_sets)

  // ---- vtype / uopInfo ----
  typedef struct packed {
    logic       illegal;
    logic       vma;
    logic       vta;
    logic [1:0] vsew;
    logic [2:0] vlmul;
  } vtype_t;

  typedef struct packed {
    logic [6:0] numOfUop;
    logic [6:0] numOfWB;
    logic [3:0] lmul;
  } uop_info_t;

  // ---- 与 golden 端口逐字同名的三个 struct ----
  // BEGIN GENERATED(structs)
  // IBuffer 送来的一条静态指令（StaticInst）。golden 输入端口没有 exceptionVec_3/_22（本模块整段改写它们，firtool 删了入口），wrapper 给这两位喂 0。
  // 成员名与位宽由 verif/ut/DecodeUnit/gen.py 从 golden 的 io_enq_ctrlFlow_* 端口机械生成，与 golden 逐字同名。
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

  // CSR 给译码的"当前特权态下哪些指令非法/虚拟非法"标志（CSRToDecode）。
  // 成员名与位宽由 verif/ut/DecodeUnit/gen.py 从 golden 的 io_fromCSR_* 端口机械生成，与 golden 逐字同名。
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

  // 译码结果（DecodedInst，送 DecodeStage 再往 Rename）。
  // 成员名与位宽由 verif/ut/DecodeUnit/gen.py 从 golden 的 io_deq_decodedInst_* 端口机械生成，与 golden 逐字同名。
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
    logic [5:0] uopSplitType;
    logic       isVset;
    logic [2:0] commitType;
    logic [34:0] debug_fuType;
    logic [55:0] debug_seqNum_seqNum;
    logic [7:0] debug_seqNum_uopIdx;
  } decoded_inst_t;

  // END GENERATED(structs)

  // ---- CSR 地址 / 其它常数 ----
  localparam logic [11:0] CSR_VL    = 12'hC20;
  localparam logic [11:0] CSR_VLENB = 12'hC22;
  localparam int          VLEN      = 128;
  localparam logic [21:0] IMM_VLENB = 22'(VLEN / 8);   // csrr vlenb 转成 addi rd, x0, 16
  localparam logic [3:0]  TRIGGER_BREAKPOINT_EXP = 4'h0;   // TriggerAction.BreakpointExp

endpackage

// -----------------------------------------------------------------------------
// §2 xs_DecodeUnit_core —— 可读核
// -----------------------------------------------------------------------------
module xs_DecodeUnit_core
  import decodeunit_pkg::*;
(
  input  static_inst_t   enq,             // IBuffer 送来的静态指令（含 32 位指令字）
  input  vtype_t         enq_vtype,       // 当前推测 vtype（VTypeGen）
  input  logic [7:0]     enq_vstart,
  input  logic           csr_singlestep,  // 单步调试中：isMove 关掉（move 消除会跳过执行）
  input  csr_to_decode_t from_csr,        // 当前特权态下的非法/虚拟非法标志
  output decoded_inst_t  deq,
  output logic           deq_is_complex,  // 要交给 DecodeUnitComp 拆分
  output uop_info_t      deq_uop_info
);

  // ---------------------------------------------------------------------------
  // §2.1 指令字段（XSInstBitFields）
  // ---------------------------------------------------------------------------
  logic [31:0] instr;
  assign instr = enq.instr;
  logic [6:0] opcode;   logic [4:0] opcode5;  logic [4:0] rd;    logic [2:0] funct3;
  logic [4:0] rs1;      logic [4:0] rs2;      logic [4:0] fs3;   logic [11:0] csridx;
  logic [2:0] nf;       logic [1:0] mop;      logic       vm;    logic [4:0] lumop;   // lumop == sumop
  logic [1:0] fmt;      logic [3:0] rnum;
  assign opcode  = instr[6:0];
  assign opcode5 = instr[6:2];
  assign rd      = instr[11:7];
  assign funct3  = instr[14:12];
  assign rs1     = instr[19:15];
  assign rs2     = instr[24:20];
  assign fs3     = instr[31:27];
  assign csridx  = instr[31:20];
  assign nf      = instr[31:29];
  assign mop     = instr[27:26];
  assign vm      = instr[25];
  assign lumop   = instr[24:20];
  assign fmt     = instr[26:25];
  assign rnum    = instr[23:20];

  // ---------------------------------------------------------------------------
  // §3 译码表 —— 表序优先（casez 第一条命中胜出 = Chisel ListLookup）
  // ---------------------------------------------------------------------------
  decode_row_t tbl;
  always_comb begin
    decode_row_t d;
    d = ROW_INVALID;
    casez (instr)
  // BEGIN GENERATED(decode_table)

      // ======== XDecode ========
      // RV32I
      LW             : d = R(SRC_REG, SRC_IMM, SRC_X  , FU_LDU      , LSU_lw              , IMM_I       , SPLIT_X             , XWEN);
      LH             : d = R(SRC_REG, SRC_IMM, SRC_X  , FU_LDU      , LSU_lh              , IMM_I       , SPLIT_X             , XWEN);
      LHU            : d = R(SRC_REG, SRC_IMM, SRC_X  , FU_LDU      , LSU_lhu             , IMM_I       , SPLIT_X             , XWEN);
      LB             : d = R(SRC_REG, SRC_IMM, SRC_X  , FU_LDU      , LSU_lb              , IMM_I       , SPLIT_X             , XWEN);
      LBU            : d = R(SRC_REG, SRC_IMM, SRC_X  , FU_LDU      , LSU_lbu             , IMM_I       , SPLIT_X             , XWEN);
      SW             : d = R(SRC_REG, SRC_REG, SRC_X  , FU_STU      , LSU_sw              , IMM_S       , SPLIT_X             , NOFLAG);
      SH             : d = R(SRC_REG, SRC_REG, SRC_X  , FU_STU      , LSU_sh              , IMM_S       , SPLIT_X             , NOFLAG);
      SB             : d = R(SRC_REG, SRC_REG, SRC_X  , FU_STU      , LSU_sb              , IMM_S       , SPLIT_X             , NOFLAG);
      LUI            : d = R(SRC_REG, SRC_IMM, SRC_X  , FU_ALU      , ALU_add             , IMM_U       , SPLIT_X             , XWEN | ROBCOMP);
      ADDI           : d = R(SRC_REG, SRC_IMM, SRC_X  , FU_ALU      , ALU_add             , IMM_I       , SPLIT_X             , XWEN | ROBCOMP);
      ANDI           : d = R(SRC_REG, SRC_IMM, SRC_X  , FU_ALU      , ALU_and             , IMM_I       , SPLIT_X             , XWEN | ROBCOMP);
      ORI            : d = R(SRC_REG, SRC_IMM, SRC_X  , FU_ALU      , ALU_or              , IMM_I       , SPLIT_X             , XWEN | ROBCOMP);
      XORI           : d = R(SRC_REG, SRC_IMM, SRC_X  , FU_ALU      , ALU_xor             , IMM_I       , SPLIT_X             , XWEN | ROBCOMP);
      SLTI           : d = R(SRC_REG, SRC_IMM, SRC_X  , FU_ALU      , ALU_slt             , IMM_I       , SPLIT_X             , XWEN | ROBCOMP);
      SLTIU          : d = R(SRC_REG, SRC_IMM, SRC_X  , FU_ALU      , ALU_sltu            , IMM_I       , SPLIT_X             , XWEN | ROBCOMP);
      SLL            : d = R(SRC_REG, SRC_REG, SRC_X  , FU_ALU      , ALU_sll             , SELIMM_X    , SPLIT_X             , XWEN | ROBCOMP);
      ADD            : d = R(SRC_REG, SRC_REG, SRC_X  , FU_ALU      , ALU_add             , SELIMM_X    , SPLIT_X             , XWEN | ROBCOMP);
      SUB            : d = R(SRC_REG, SRC_REG, SRC_X  , FU_ALU      , ALU_sub             , SELIMM_X    , SPLIT_X             , XWEN | ROBCOMP);
      SLT            : d = R(SRC_REG, SRC_REG, SRC_X  , FU_ALU      , ALU_slt             , SELIMM_X    , SPLIT_X             , XWEN | ROBCOMP);
      SLTU           : d = R(SRC_REG, SRC_REG, SRC_X  , FU_ALU      , ALU_sltu            , SELIMM_X    , SPLIT_X             , XWEN | ROBCOMP);
      AND            : d = R(SRC_REG, SRC_REG, SRC_X  , FU_ALU      , ALU_and             , SELIMM_X    , SPLIT_X             , XWEN | ROBCOMP);
      OR             : d = R(SRC_REG, SRC_REG, SRC_X  , FU_ALU      , ALU_or              , SELIMM_X    , SPLIT_X             , XWEN | ROBCOMP);
      XOR            : d = R(SRC_REG, SRC_REG, SRC_X  , FU_ALU      , ALU_xor             , SELIMM_X    , SPLIT_X             , XWEN | ROBCOMP);
      SRA            : d = R(SRC_REG, SRC_REG, SRC_X  , FU_ALU      , ALU_sra             , SELIMM_X    , SPLIT_X             , XWEN | ROBCOMP);
      SRL            : d = R(SRC_REG, SRC_REG, SRC_X  , FU_ALU      , ALU_srl             , SELIMM_X    , SPLIT_X             , XWEN | ROBCOMP);
      // RV64I （extend from RV32I)
      LD             : d = R(SRC_REG, SRC_IMM, SRC_X  , FU_LDU      , LSU_ld              , IMM_I       , SPLIT_X             , XWEN);
      LWU            : d = R(SRC_REG, SRC_IMM, SRC_X  , FU_LDU      , LSU_lwu             , IMM_I       , SPLIT_X             , XWEN);
      SD             : d = R(SRC_REG, SRC_REG, SRC_X  , FU_STU      , LSU_sd              , IMM_S       , SPLIT_X             , NOFLAG);
      SLLI           : d = R(SRC_REG, SRC_IMM, SRC_X  , FU_ALU      , ALU_sll             , IMM_I       , SPLIT_X             , XWEN | ROBCOMP);
      SRLI           : d = R(SRC_REG, SRC_IMM, SRC_X  , FU_ALU      , ALU_srl             , IMM_I       , SPLIT_X             , XWEN | ROBCOMP);
      SRAI           : d = R(SRC_REG, SRC_IMM, SRC_X  , FU_ALU      , ALU_sra             , IMM_I       , SPLIT_X             , XWEN | ROBCOMP);
      ADDIW          : d = R(SRC_REG, SRC_IMM, SRC_X  , FU_ALU      , ALU_addw            , IMM_I       , SPLIT_X             , XWEN | ROBCOMP);
      SLLIW          : d = R(SRC_REG, SRC_IMM, SRC_X  , FU_ALU      , ALU_sllw            , IMM_I       , SPLIT_X             , XWEN | ROBCOMP);
      SRAIW          : d = R(SRC_REG, SRC_IMM, SRC_X  , FU_ALU      , ALU_sraw            , IMM_I       , SPLIT_X             , XWEN | ROBCOMP);
      SRLIW          : d = R(SRC_REG, SRC_IMM, SRC_X  , FU_ALU      , ALU_srlw            , IMM_I       , SPLIT_X             , XWEN | ROBCOMP);
      ADDW           : d = R(SRC_REG, SRC_REG, SRC_X  , FU_ALU      , ALU_addw            , SELIMM_X    , SPLIT_X             , XWEN | ROBCOMP);
      SUBW           : d = R(SRC_REG, SRC_REG, SRC_X  , FU_ALU      , ALU_subw            , SELIMM_X    , SPLIT_X             , XWEN | ROBCOMP);
      SLLW           : d = R(SRC_REG, SRC_REG, SRC_X  , FU_ALU      , ALU_sllw            , SELIMM_X    , SPLIT_X             , XWEN | ROBCOMP);
      SRAW           : d = R(SRC_REG, SRC_REG, SRC_X  , FU_ALU      , ALU_sraw            , SELIMM_X    , SPLIT_X             , XWEN | ROBCOMP);
      SRLW           : d = R(SRC_REG, SRC_REG, SRC_X  , FU_ALU      , ALU_srlw            , SELIMM_X    , SPLIT_X             , XWEN | ROBCOMP);
      // RV64M
      MUL            : d = R(SRC_REG, SRC_REG, SRC_X  , FU_MUL      , MDU_mul             , SELIMM_X    , SPLIT_X             , XWEN | ROBCOMP);
      MULH           : d = R(SRC_REG, SRC_REG, SRC_X  , FU_MUL      , MDU_mulh            , SELIMM_X    , SPLIT_X             , XWEN | ROBCOMP);
      MULHU          : d = R(SRC_REG, SRC_REG, SRC_X  , FU_MUL      , MDU_mulhu           , SELIMM_X    , SPLIT_X             , XWEN | ROBCOMP);
      MULHSU         : d = R(SRC_REG, SRC_REG, SRC_X  , FU_MUL      , MDU_mulhsu          , SELIMM_X    , SPLIT_X             , XWEN | ROBCOMP);
      MULW           : d = R(SRC_REG, SRC_REG, SRC_X  , FU_MUL      , MDU_mulw            , SELIMM_X    , SPLIT_X             , XWEN | ROBCOMP);
      DIV            : d = R(SRC_REG, SRC_REG, SRC_X  , FU_DIV      , MDU_div             , SELIMM_X    , SPLIT_X             , XWEN | ROBCOMP);
      DIVU           : d = R(SRC_REG, SRC_REG, SRC_X  , FU_DIV      , MDU_divu            , SELIMM_X    , SPLIT_X             , XWEN | ROBCOMP);
      REM            : d = R(SRC_REG, SRC_REG, SRC_X  , FU_DIV      , MDU_rem             , SELIMM_X    , SPLIT_X             , XWEN | ROBCOMP);
      REMU           : d = R(SRC_REG, SRC_REG, SRC_X  , FU_DIV      , MDU_remu            , SELIMM_X    , SPLIT_X             , XWEN | ROBCOMP);
      DIVW           : d = R(SRC_REG, SRC_REG, SRC_X  , FU_DIV      , MDU_divw            , SELIMM_X    , SPLIT_X             , XWEN | ROBCOMP);
      DIVUW          : d = R(SRC_REG, SRC_REG, SRC_X  , FU_DIV      , MDU_divuw           , SELIMM_X    , SPLIT_X             , XWEN | ROBCOMP);
      REMW           : d = R(SRC_REG, SRC_REG, SRC_X  , FU_DIV      , MDU_remw            , SELIMM_X    , SPLIT_X             , XWEN | ROBCOMP);
      REMUW          : d = R(SRC_REG, SRC_REG, SRC_X  , FU_DIV      , MDU_remuw           , SELIMM_X    , SPLIT_X             , XWEN | ROBCOMP);
      AUIPC          : d = R(SRC_PC , SRC_IMM, SRC_X  , FU_JMP      , JMP_auipc           , IMM_U       , SPLIT_X             , XWEN);
      JAL            : d = R(SRC_PC , SRC_IMM, SRC_X  , FU_JMP      , JMP_jal             , IMM_UJ      , SPLIT_X             , XWEN);
      JALR           : d = R(SRC_REG, SRC_IMM, SRC_X  , FU_JMP      , JMP_jalr            , IMM_I       , SPLIT_X             , XWEN);
      BEQ            : d = R(SRC_REG, SRC_REG, SRC_X  , FU_BRH      , BRU_beq             , IMM_SB      , SPLIT_X             , NOFLAG);
      BNE            : d = R(SRC_REG, SRC_REG, SRC_X  , FU_BRH      , BRU_bne             , IMM_SB      , SPLIT_X             , NOFLAG);
      BGE            : d = R(SRC_REG, SRC_REG, SRC_X  , FU_BRH      , BRU_bge             , IMM_SB      , SPLIT_X             , NOFLAG);
      BGEU           : d = R(SRC_REG, SRC_REG, SRC_X  , FU_BRH      , BRU_bgeu            , IMM_SB      , SPLIT_X             , NOFLAG);
      BLT            : d = R(SRC_REG, SRC_REG, SRC_X  , FU_BRH      , BRU_blt             , IMM_SB      , SPLIT_X             , NOFLAG);
      BLTU           : d = R(SRC_REG, SRC_REG, SRC_X  , FU_BRH      , BRU_bltu            , IMM_SB      , SPLIT_X             , NOFLAG);
      // System, the immediate12 holds the CSR register.

      CSRRW          : d = R(SRC_REG, SRC_IMM, SRC_X  , FU_CSR      , CSR_wrt             , IMM_Z       , SPLIT_X             , XWEN | NOSPEC | BLOCKBACK);
      CSRRS          : d = R(SRC_REG, SRC_IMM, SRC_X  , FU_CSR      , CSR_set             , IMM_Z       , SPLIT_X             , XWEN | NOSPEC | BLOCKBACK);
      CSRRC          : d = R(SRC_REG, SRC_IMM, SRC_X  , FU_CSR      , CSR_clr             , IMM_Z       , SPLIT_X             , XWEN | NOSPEC | BLOCKBACK);
      CSRRWI         : d = R(SRC_REG, SRC_IMM, SRC_X  , FU_CSR      , CSR_wrti            , IMM_Z       , SPLIT_X             , XWEN | NOSPEC | BLOCKBACK);
      CSRRSI         : d = R(SRC_REG, SRC_IMM, SRC_X  , FU_CSR      , CSR_seti            , IMM_Z       , SPLIT_X             , XWEN | NOSPEC | BLOCKBACK);
      CSRRCI         : d = R(SRC_REG, SRC_IMM, SRC_X  , FU_CSR      , CSR_clri            , IMM_Z       , SPLIT_X             , XWEN | NOSPEC | BLOCKBACK);
      EBREAK         : d = R(SRC_REG, SRC_IMM, SRC_X  , FU_CSR      , CSR_jmp             , IMM_I       , SPLIT_X             , XWEN | NOSPEC | BLOCKBACK);
      ECALL          : d = R(SRC_REG, SRC_IMM, SRC_X  , FU_CSR      , CSR_jmp             , IMM_I       , SPLIT_X             , XWEN | NOSPEC | BLOCKBACK);
      SRET           : d = R(SRC_REG, SRC_IMM, SRC_X  , FU_CSR      , CSR_jmp             , IMM_I       , SPLIT_X             , XWEN | NOSPEC | BLOCKBACK);
      MRET           : d = R(SRC_REG, SRC_IMM, SRC_X  , FU_CSR      , CSR_jmp             , IMM_I       , SPLIT_X             , XWEN | NOSPEC | BLOCKBACK);
      MNRET          : d = R(SRC_REG, SRC_IMM, SRC_X  , FU_CSR      , CSR_jmp             , IMM_I       , SPLIT_X             , XWEN | NOSPEC | BLOCKBACK);
      DRET           : d = R(SRC_REG, SRC_IMM, SRC_X  , FU_CSR      , CSR_jmp             , IMM_I       , SPLIT_X             , XWEN | NOSPEC | BLOCKBACK);
      WFI            : d = R(SRC_PC , SRC_IMM, SRC_X  , FU_CSR      , CSR_wfi             , SELIMM_X    , SPLIT_X             , XWEN | NOSPEC | BLOCKBACK);
      SFENCE_VMA     : d = R(SRC_REG, SRC_REG, SRC_X  , FU_FENCE    , FENCE_sfence        , SELIMM_X    , SPLIT_X             , NOSPEC | BLOCKBACK | FLUSHPIPE);
      FENCE_I        : d = R(SRC_PC , SRC_IMM, SRC_X  , FU_FENCE    , FENCE_fencei        , SELIMM_X    , SPLIT_X             , NOSPEC | BLOCKBACK | FLUSHPIPE);
      FENCE          : d = R(SRC_PC , SRC_IMM, SRC_X  , FU_FENCE    , FENCE_fence         , SELIMM_X    , SPLIT_X             , NOSPEC | BLOCKBACK | FLUSHPIPE);
      PAUSE          : d = R(SRC_PC , SRC_IMM, SRC_X  , FU_FENCE    , FENCE_fence         , SELIMM_X    , SPLIT_X             , NOSPEC | BLOCKBACK | FLUSHPIPE);
      // Zawrs
      WRS_NTO        : d = R(SRC_PC , SRC_IMM, SRC_X  , FU_CSR      , CSR_wrs_nto         , SELIMM_X    , SPLIT_X             , NOSPEC | BLOCKBACK);
      WRS_STO        : d = R(SRC_PC , SRC_IMM, SRC_X  , FU_CSR      , CSR_wrs_sto         , SELIMM_X    , SPLIT_X             , NOSPEC | BLOCKBACK);
      // RV64A
      AMOADD_W       : d = R(SRC_REG, SRC_REG, SRC_X  , FU_MOU      , LSU_amoadd_w        , SELIMM_X    , SPLIT_X             , XWEN | NOSPEC | BLOCKBACK);
      AMOXOR_W       : d = R(SRC_REG, SRC_REG, SRC_X  , FU_MOU      , LSU_amoxor_w        , SELIMM_X    , SPLIT_X             , XWEN | NOSPEC | BLOCKBACK);
      AMOSWAP_W      : d = R(SRC_REG, SRC_REG, SRC_X  , FU_MOU      , LSU_amoswap_w       , SELIMM_X    , SPLIT_X             , XWEN | NOSPEC | BLOCKBACK);
      AMOAND_W       : d = R(SRC_REG, SRC_REG, SRC_X  , FU_MOU      , LSU_amoand_w        , SELIMM_X    , SPLIT_X             , XWEN | NOSPEC | BLOCKBACK);
      AMOOR_W        : d = R(SRC_REG, SRC_REG, SRC_X  , FU_MOU      , LSU_amoor_w         , SELIMM_X    , SPLIT_X             , XWEN | NOSPEC | BLOCKBACK);
      AMOMIN_W       : d = R(SRC_REG, SRC_REG, SRC_X  , FU_MOU      , LSU_amomin_w        , SELIMM_X    , SPLIT_X             , XWEN | NOSPEC | BLOCKBACK);
      AMOMINU_W      : d = R(SRC_REG, SRC_REG, SRC_X  , FU_MOU      , LSU_amominu_w       , SELIMM_X    , SPLIT_X             , XWEN | NOSPEC | BLOCKBACK);
      AMOMAX_W       : d = R(SRC_REG, SRC_REG, SRC_X  , FU_MOU      , LSU_amomax_w        , SELIMM_X    , SPLIT_X             , XWEN | NOSPEC | BLOCKBACK);
      AMOMAXU_W      : d = R(SRC_REG, SRC_REG, SRC_X  , FU_MOU      , LSU_amomaxu_w       , SELIMM_X    , SPLIT_X             , XWEN | NOSPEC | BLOCKBACK);
      AMOCAS_W       : d = R(SRC_REG, SRC_REG, SRC_X  , FU_MOU      , LSU_amocas_w        , SELIMM_X    , SPLIT_AMO_CAS_W     , XWEN | NOSPEC | BLOCKBACK);
      AMOADD_D       : d = R(SRC_REG, SRC_REG, SRC_X  , FU_MOU      , LSU_amoadd_d        , SELIMM_X    , SPLIT_X             , XWEN | NOSPEC | BLOCKBACK);
      AMOXOR_D       : d = R(SRC_REG, SRC_REG, SRC_X  , FU_MOU      , LSU_amoxor_d        , SELIMM_X    , SPLIT_X             , XWEN | NOSPEC | BLOCKBACK);
      AMOSWAP_D      : d = R(SRC_REG, SRC_REG, SRC_X  , FU_MOU      , LSU_amoswap_d       , SELIMM_X    , SPLIT_X             , XWEN | NOSPEC | BLOCKBACK);
      AMOAND_D       : d = R(SRC_REG, SRC_REG, SRC_X  , FU_MOU      , LSU_amoand_d        , SELIMM_X    , SPLIT_X             , XWEN | NOSPEC | BLOCKBACK);
      AMOOR_D        : d = R(SRC_REG, SRC_REG, SRC_X  , FU_MOU      , LSU_amoor_d         , SELIMM_X    , SPLIT_X             , XWEN | NOSPEC | BLOCKBACK);
      AMOMIN_D       : d = R(SRC_REG, SRC_REG, SRC_X  , FU_MOU      , LSU_amomin_d        , SELIMM_X    , SPLIT_X             , XWEN | NOSPEC | BLOCKBACK);
      AMOMINU_D      : d = R(SRC_REG, SRC_REG, SRC_X  , FU_MOU      , LSU_amominu_d       , SELIMM_X    , SPLIT_X             , XWEN | NOSPEC | BLOCKBACK);
      AMOMAX_D       : d = R(SRC_REG, SRC_REG, SRC_X  , FU_MOU      , LSU_amomax_d        , SELIMM_X    , SPLIT_X             , XWEN | NOSPEC | BLOCKBACK);
      AMOMAXU_D      : d = R(SRC_REG, SRC_REG, SRC_X  , FU_MOU      , LSU_amomaxu_d       , SELIMM_X    , SPLIT_X             , XWEN | NOSPEC | BLOCKBACK);
      AMOCAS_D       : d = R(SRC_REG, SRC_REG, SRC_X  , FU_MOU      , LSU_amocas_d        , SELIMM_X    , SPLIT_AMO_CAS_D     , XWEN | NOSPEC | BLOCKBACK);
      AMOCAS_Q       : d = R(SRC_REG, SRC_REG, SRC_X  , FU_MOU      , LSU_amocas_q        , SELIMM_X    , SPLIT_AMO_CAS_Q     , XWEN | NOSPEC | BLOCKBACK);
      LR_W           : d = R(SRC_REG, SRC_IMM, SRC_X  , FU_MOU      , LSU_lr_w            , SELIMM_X    , SPLIT_X             , XWEN | NOSPEC | BLOCKBACK);
      LR_D           : d = R(SRC_REG, SRC_IMM, SRC_X  , FU_MOU      , LSU_lr_d            , SELIMM_X    , SPLIT_X             , XWEN | NOSPEC | BLOCKBACK);
      SC_W           : d = R(SRC_REG, SRC_REG, SRC_X  , FU_MOU      , LSU_sc_w            , SELIMM_X    , SPLIT_X             , XWEN | NOSPEC | BLOCKBACK);
      SC_D           : d = R(SRC_REG, SRC_REG, SRC_X  , FU_MOU      , LSU_sc_d            , SELIMM_X    , SPLIT_X             , XWEN | NOSPEC | BLOCKBACK);

      // ======== FpDecode ========
      FLH            : d = R(SRC_REG, SRC_IMM, SRC_X  , FU_LDU      , LSU_lh              , IMM_I       , SPLIT_X             , FWEN);
      FLW            : d = R(SRC_REG, SRC_IMM, SRC_X  , FU_LDU      , LSU_lw              , IMM_I       , SPLIT_X             , FWEN);
      FLD            : d = R(SRC_REG, SRC_IMM, SRC_X  , FU_LDU      , LSU_ld              , IMM_I       , SPLIT_X             , FWEN);
      FSH            : d = R(SRC_REG, SRC_FP , SRC_X  , FU_STU      , LSU_sh              , IMM_S       , SPLIT_X             , NOFLAG);
      FSW            : d = R(SRC_REG, SRC_FP , SRC_X  , FU_STU      , LSU_sw              , IMM_S       , SPLIT_X             , NOFLAG);
      FSD            : d = R(SRC_REG, SRC_FP , SRC_X  , FU_STU      , LSU_sd              , IMM_S       , SPLIT_X             , NOFLAG);
      FMV_D_X        : d = R(SRC_REG, SRC_IMM, SRC_X  , FU_I2V      , I2V_FMX_D_X         , SELIMM_X    , SPLIT_X             , FWEN | ROBCOMP);
      FMV_W_X        : d = R(SRC_REG, SRC_IMM, SRC_X  , FU_I2V      , I2V_FMX_W_X         , SELIMM_X    , SPLIT_X             , FWEN | ROBCOMP);
      FMV_H_X        : d = R(SRC_REG, SRC_IMM, SRC_X  , FU_I2V      , I2V_FMX_H_X         , SELIMM_X    , SPLIT_X             , FWEN | ROBCOMP);
      // Int to FP
      FCVT_S_W       : d = R(SRC_REG, SRC_IMM, SRC_X  , FU_I2F      , OP_X                , SELIMM_X    , SPLIT_X             , FWEN | ROBCOMP);
      FCVT_S_WU      : d = R(SRC_REG, SRC_IMM, SRC_X  , FU_I2F      , OP_X                , SELIMM_X    , SPLIT_X             , FWEN | ROBCOMP);
      FCVT_S_L       : d = R(SRC_REG, SRC_IMM, SRC_X  , FU_I2F      , OP_X                , SELIMM_X    , SPLIT_X             , FWEN | ROBCOMP);
      FCVT_S_LU      : d = R(SRC_REG, SRC_IMM, SRC_X  , FU_I2F      , OP_X                , SELIMM_X    , SPLIT_X             , FWEN | ROBCOMP);
      FCVT_D_W       : d = R(SRC_REG, SRC_IMM, SRC_X  , FU_I2F      , OP_X                , SELIMM_X    , SPLIT_X             , FWEN | ROBCOMP);
      FCVT_D_WU      : d = R(SRC_REG, SRC_IMM, SRC_X  , FU_I2F      , OP_X                , SELIMM_X    , SPLIT_X             , FWEN | ROBCOMP);
      FCVT_D_L       : d = R(SRC_REG, SRC_IMM, SRC_X  , FU_I2F      , OP_X                , SELIMM_X    , SPLIT_X             , FWEN | ROBCOMP);
      FCVT_D_LU      : d = R(SRC_REG, SRC_IMM, SRC_X  , FU_I2F      , OP_X                , SELIMM_X    , SPLIT_X             , FWEN | ROBCOMP);
      FCVT_H_W       : d = R(SRC_REG, SRC_IMM, SRC_X  , FU_I2F      , OP_X                , SELIMM_X    , SPLIT_X             , FWEN | ROBCOMP);
      FCVT_H_WU      : d = R(SRC_REG, SRC_IMM, SRC_X  , FU_I2F      , OP_X                , SELIMM_X    , SPLIT_X             , FWEN | ROBCOMP);
      FCVT_H_L       : d = R(SRC_REG, SRC_IMM, SRC_X  , FU_I2F      , OP_X                , SELIMM_X    , SPLIT_X             , FWEN | ROBCOMP);
      FCVT_H_LU      : d = R(SRC_REG, SRC_IMM, SRC_X  , FU_I2F      , OP_X                , SELIMM_X    , SPLIT_X             , FWEN | ROBCOMP);

      // ======== BitmanipDecode ========
      // Zba
      ADD_UW         : d = R(SRC_REG, SRC_REG, SRC_X  , FU_ALU      , ALU_adduw           , SELIMM_X    , SPLIT_X             , XWEN | ROBCOMP);
      SH1ADD         : d = R(SRC_REG, SRC_REG, SRC_X  , FU_ALU      , ALU_sh1add          , SELIMM_X    , SPLIT_X             , XWEN | ROBCOMP);
      SH1ADD_UW      : d = R(SRC_REG, SRC_REG, SRC_X  , FU_ALU      , ALU_sh1adduw        , SELIMM_X    , SPLIT_X             , XWEN | ROBCOMP);
      SH2ADD         : d = R(SRC_REG, SRC_REG, SRC_X  , FU_ALU      , ALU_sh2add          , SELIMM_X    , SPLIT_X             , XWEN | ROBCOMP);
      SH2ADD_UW      : d = R(SRC_REG, SRC_REG, SRC_X  , FU_ALU      , ALU_sh2adduw        , SELIMM_X    , SPLIT_X             , XWEN | ROBCOMP);
      SH3ADD         : d = R(SRC_REG, SRC_REG, SRC_X  , FU_ALU      , ALU_sh3add          , SELIMM_X    , SPLIT_X             , XWEN | ROBCOMP);
      SH3ADD_UW      : d = R(SRC_REG, SRC_REG, SRC_X  , FU_ALU      , ALU_sh3adduw        , SELIMM_X    , SPLIT_X             , XWEN | ROBCOMP);
      SLLI_UW        : d = R(SRC_REG, SRC_IMM, SRC_X  , FU_ALU      , ALU_slliuw          , IMM_I       , SPLIT_X             , XWEN | ROBCOMP);
      // Zbb
      ANDN           : d = R(SRC_REG, SRC_REG, SRC_X  , FU_ALU      , ALU_andn            , SELIMM_X    , SPLIT_X             , XWEN | ROBCOMP);
      ORN            : d = R(SRC_REG, SRC_REG, SRC_X  , FU_ALU      , ALU_orn             , SELIMM_X    , SPLIT_X             , XWEN | ROBCOMP);
      XNOR           : d = R(SRC_REG, SRC_REG, SRC_X  , FU_ALU      , ALU_xnor            , SELIMM_X    , SPLIT_X             , XWEN | ROBCOMP);
      CLZ            : d = R(SRC_REG, SRC_DC , SRC_X  , FU_BKU      , BKU_clz             , SELIMM_X    , SPLIT_X             , XWEN | ROBCOMP);
      CLZW           : d = R(SRC_REG, SRC_DC , SRC_X  , FU_BKU      , BKU_clzw            , SELIMM_X    , SPLIT_X             , XWEN | ROBCOMP);
      CTZ            : d = R(SRC_REG, SRC_DC , SRC_X  , FU_BKU      , BKU_ctz             , SELIMM_X    , SPLIT_X             , XWEN | ROBCOMP);
      CTZW           : d = R(SRC_REG, SRC_DC , SRC_X  , FU_BKU      , BKU_ctzw            , SELIMM_X    , SPLIT_X             , XWEN | ROBCOMP);
      CPOP           : d = R(SRC_REG, SRC_DC , SRC_X  , FU_BKU      , BKU_cpop            , SELIMM_X    , SPLIT_X             , XWEN | ROBCOMP);
      CPOPW          : d = R(SRC_REG, SRC_DC , SRC_X  , FU_BKU      , BKU_cpopw           , SELIMM_X    , SPLIT_X             , XWEN | ROBCOMP);
      MAX            : d = R(SRC_REG, SRC_REG, SRC_X  , FU_ALU      , ALU_max             , SELIMM_X    , SPLIT_X             , XWEN | ROBCOMP);
      MAXU           : d = R(SRC_REG, SRC_REG, SRC_X  , FU_ALU      , ALU_maxu            , SELIMM_X    , SPLIT_X             , XWEN | ROBCOMP);
      MIN            : d = R(SRC_REG, SRC_REG, SRC_X  , FU_ALU      , ALU_min             , SELIMM_X    , SPLIT_X             , XWEN | ROBCOMP);
      MINU           : d = R(SRC_REG, SRC_REG, SRC_X  , FU_ALU      , ALU_minu            , SELIMM_X    , SPLIT_X             , XWEN | ROBCOMP);
      SEXT_B         : d = R(SRC_REG, SRC_DC , SRC_X  , FU_ALU      , ALU_sextb           , SELIMM_X    , SPLIT_X             , XWEN | ROBCOMP);
      SEXT_H         : d = R(SRC_REG, SRC_DC , SRC_X  , FU_ALU      , ALU_sexth           , SELIMM_X    , SPLIT_X             , XWEN | ROBCOMP);
      // zext.h in rv64 is shared with packw in Zbkb with rs2 = $0.
      // If we configured to have no Zbkb, we should add zext.h here.

      ROL            : d = R(SRC_REG, SRC_REG, SRC_X  , FU_ALU      , ALU_rol             , SELIMM_X    , SPLIT_X             , XWEN | ROBCOMP);
      ROLW           : d = R(SRC_REG, SRC_REG, SRC_X  , FU_ALU      , ALU_rolw            , SELIMM_X    , SPLIT_X             , XWEN | ROBCOMP);
      ROR            : d = R(SRC_REG, SRC_REG, SRC_X  , FU_ALU      , ALU_ror             , SELIMM_X    , SPLIT_X             , XWEN | ROBCOMP);
      RORI           : d = R(SRC_REG, SRC_IMM, SRC_X  , FU_ALU      , ALU_ror             , IMM_I       , SPLIT_X             , XWEN | ROBCOMP);
      RORIW          : d = R(SRC_REG, SRC_IMM, SRC_X  , FU_ALU      , ALU_rorw            , IMM_I       , SPLIT_X             , XWEN | ROBCOMP);
      RORW           : d = R(SRC_REG, SRC_REG, SRC_X  , FU_ALU      , ALU_rorw            , SELIMM_X    , SPLIT_X             , XWEN | ROBCOMP);
      ORC_B          : d = R(SRC_REG, SRC_DC , SRC_X  , FU_ALU      , ALU_orcb            , SELIMM_X    , SPLIT_X             , XWEN | ROBCOMP);
      REV8           : d = R(SRC_REG, SRC_DC , SRC_X  , FU_ALU      , ALU_rev8            , SELIMM_X    , SPLIT_X             , XWEN | ROBCOMP);
      // Zbc
      CLMUL          : d = R(SRC_REG, SRC_REG, SRC_X  , FU_BKU      , BKU_clmul           , SELIMM_X    , SPLIT_X             , XWEN | ROBCOMP);
      CLMULH         : d = R(SRC_REG, SRC_REG, SRC_X  , FU_BKU      , BKU_clmulh          , SELIMM_X    , SPLIT_X             , XWEN | ROBCOMP);
      CLMULR         : d = R(SRC_REG, SRC_REG, SRC_X  , FU_BKU      , BKU_clmulr          , SELIMM_X    , SPLIT_X             , XWEN | ROBCOMP);
      // Zbs
      BCLR           : d = R(SRC_REG, SRC_REG, SRC_X  , FU_ALU      , ALU_bclr            , SELIMM_X    , SPLIT_X             , XWEN | ROBCOMP);
      BCLRI          : d = R(SRC_REG, SRC_IMM, SRC_X  , FU_ALU      , ALU_bclr            , IMM_I       , SPLIT_X             , XWEN | ROBCOMP);
      BEXT           : d = R(SRC_REG, SRC_REG, SRC_X  , FU_ALU      , ALU_bext            , SELIMM_X    , SPLIT_X             , XWEN | ROBCOMP);
      BEXTI          : d = R(SRC_REG, SRC_IMM, SRC_X  , FU_ALU      , ALU_bext            , IMM_I       , SPLIT_X             , XWEN | ROBCOMP);
      BINV           : d = R(SRC_REG, SRC_REG, SRC_X  , FU_ALU      , ALU_binv            , SELIMM_X    , SPLIT_X             , XWEN | ROBCOMP);
      BINVI          : d = R(SRC_REG, SRC_IMM, SRC_X  , FU_ALU      , ALU_binv            , IMM_I       , SPLIT_X             , XWEN | ROBCOMP);
      BSET           : d = R(SRC_REG, SRC_REG, SRC_X  , FU_ALU      , ALU_bset            , SELIMM_X    , SPLIT_X             , XWEN | ROBCOMP);
      BSETI          : d = R(SRC_REG, SRC_IMM, SRC_X  , FU_ALU      , ALU_bset            , IMM_I       , SPLIT_X             , XWEN | ROBCOMP);
      // Zbkb
      // rol, rolw, ror,rori, roriw, rorw, andn, orn, xnor, rev8 is in Zbb
      PACK           : d = R(SRC_REG, SRC_REG, SRC_X  , FU_ALU      , ALU_pack            , SELIMM_X    , SPLIT_X             , XWEN | ROBCOMP);
      PACKH          : d = R(SRC_REG, SRC_REG, SRC_X  , FU_ALU      , ALU_packh           , SELIMM_X    , SPLIT_X             , XWEN | ROBCOMP);
      PACKW          : d = R(SRC_REG, SRC_REG, SRC_X  , FU_ALU      , ALU_packw           , SELIMM_X    , SPLIT_X             , XWEN | ROBCOMP);
      BREV8          : d = R(SRC_REG, SRC_DC , SRC_X  , FU_ALU      , ALU_revb            , SELIMM_X    , SPLIT_X             , XWEN | ROBCOMP);
      // If configured to RV32, we should add zip and unzip.

      // Zbkc
      // clmul, clmulh is in Zbc

      // Zbkx
      XPERM4         : d = R(SRC_REG, SRC_REG, SRC_X  , FU_BKU      , BKU_xpermn          , SELIMM_X    , SPLIT_X             , XWEN | ROBCOMP);
      XPERM8         : d = R(SRC_REG, SRC_REG, SRC_X  , FU_BKU      , BKU_xpermb          , SELIMM_X    , SPLIT_X             , XWEN | ROBCOMP);

      // ======== ScalarCryptoDecode ========
      // Zknd: NIST Suite: AES Decryption
      AES64DS        : d = R(SRC_REG, SRC_REG, SRC_X  , FU_BKU      , BKU_aes64ds         , SELIMM_X    , SPLIT_X             , XWEN | ROBCOMP);
      AES64DSM       : d = R(SRC_REG, SRC_REG, SRC_X  , FU_BKU      , BKU_aes64dsm        , SELIMM_X    , SPLIT_X             , XWEN | ROBCOMP);
      AES64IM        : d = R(SRC_REG, SRC_DC , SRC_X  , FU_BKU      , BKU_aes64im         , SELIMM_X    , SPLIT_X             , XWEN | ROBCOMP);
      AES64KS1I      : d = R(SRC_REG, SRC_IMM, SRC_X  , FU_BKU      , BKU_aes64ks1i       , IMM_I       , SPLIT_X             , XWEN | ROBCOMP);
      AES64KS2       : d = R(SRC_REG, SRC_REG, SRC_X  , FU_BKU      , BKU_aes64ks2        , SELIMM_X    , SPLIT_X             , XWEN | ROBCOMP);
      // Zkne: NIST Suite: AES Encryption
      // aes64ks1i, aes64ks2 is in Zknd
      AES64ES        : d = R(SRC_REG, SRC_REG, SRC_X  , FU_BKU      , BKU_aes64es         , SELIMM_X    , SPLIT_X             , XWEN | ROBCOMP);
      AES64ESM       : d = R(SRC_REG, SRC_REG, SRC_X  , FU_BKU      , BKU_aes64esm        , SELIMM_X    , SPLIT_X             , XWEN | ROBCOMP);
      // Zknh: NIST Suite: Hash Function Instructions
      SHA256SIG0     : d = R(SRC_REG, SRC_DC , SRC_X  , FU_BKU      , BKU_sha256sig0      , SELIMM_X    , SPLIT_X             , XWEN | ROBCOMP);
      SHA256SIG1     : d = R(SRC_REG, SRC_DC , SRC_X  , FU_BKU      , BKU_sha256sig1      , SELIMM_X    , SPLIT_X             , XWEN | ROBCOMP);
      SHA256SUM0     : d = R(SRC_REG, SRC_DC , SRC_X  , FU_BKU      , BKU_sha256sum0      , SELIMM_X    , SPLIT_X             , XWEN | ROBCOMP);
      SHA256SUM1     : d = R(SRC_REG, SRC_DC , SRC_X  , FU_BKU      , BKU_sha256sum1      , SELIMM_X    , SPLIT_X             , XWEN | ROBCOMP);
      SHA512SIG0     : d = R(SRC_REG, SRC_DC , SRC_X  , FU_BKU      , BKU_sha512sig0      , SELIMM_X    , SPLIT_X             , XWEN | ROBCOMP);
      SHA512SIG1     : d = R(SRC_REG, SRC_DC , SRC_X  , FU_BKU      , BKU_sha512sig1      , SELIMM_X    , SPLIT_X             , XWEN | ROBCOMP);
      SHA512SUM0     : d = R(SRC_REG, SRC_DC , SRC_X  , FU_BKU      , BKU_sha512sum0      , SELIMM_X    , SPLIT_X             , XWEN | ROBCOMP);
      SHA512SUM1     : d = R(SRC_REG, SRC_DC , SRC_X  , FU_BKU      , BKU_sha512sum1      , SELIMM_X    , SPLIT_X             , XWEN | ROBCOMP);
      // Zksed: ShangMi Suite: SM4 Block Cipher Instructions
      SM4ED0         : d = R(SRC_REG, SRC_REG, SRC_X  , FU_BKU      , BKU_sm4ed0          , SELIMM_X    , SPLIT_X             , XWEN | ROBCOMP);
      SM4ED1         : d = R(SRC_REG, SRC_REG, SRC_X  , FU_BKU      , BKU_sm4ed1          , SELIMM_X    , SPLIT_X             , XWEN | ROBCOMP);
      SM4ED2         : d = R(SRC_REG, SRC_REG, SRC_X  , FU_BKU      , BKU_sm4ed2          , SELIMM_X    , SPLIT_X             , XWEN | ROBCOMP);
      SM4ED3         : d = R(SRC_REG, SRC_REG, SRC_X  , FU_BKU      , BKU_sm4ed3          , SELIMM_X    , SPLIT_X             , XWEN | ROBCOMP);
      SM4KS0         : d = R(SRC_REG, SRC_REG, SRC_X  , FU_BKU      , BKU_sm4ks0          , SELIMM_X    , SPLIT_X             , XWEN | ROBCOMP);
      SM4KS1         : d = R(SRC_REG, SRC_REG, SRC_X  , FU_BKU      , BKU_sm4ks1          , SELIMM_X    , SPLIT_X             , XWEN | ROBCOMP);
      SM4KS2         : d = R(SRC_REG, SRC_REG, SRC_X  , FU_BKU      , BKU_sm4ks2          , SELIMM_X    , SPLIT_X             , XWEN | ROBCOMP);
      SM4KS3         : d = R(SRC_REG, SRC_REG, SRC_X  , FU_BKU      , BKU_sm4ks3          , SELIMM_X    , SPLIT_X             , XWEN | ROBCOMP);
      // Zksh: ShangMi Suite: SM3 Hash Function Instructions
      SM3P0          : d = R(SRC_REG, SRC_DC , SRC_X  , FU_BKU      , BKU_sm3p0           , SELIMM_X    , SPLIT_X             , XWEN | ROBCOMP);
      SM3P1          : d = R(SRC_REG, SRC_DC , SRC_X  , FU_BKU      , BKU_sm3p1           , SELIMM_X    , SPLIT_X             , XWEN | ROBCOMP);

      // ======== XSDebugDecode ========
      TRAP           : d = R(SRC_REG, SRC_IMM, SRC_X  , FU_ALU      , ALU_add             , IMM_I       , SPLIT_X             , XWEN | XSTRAP | NOSPEC | BLOCKBACK);

      // ======== CBODecode ========
      CBO_ZERO       : d = R(SRC_REG, SRC_DC , SRC_X  , FU_STU      , LSU_cbo_zero        , IMM_S       , SPLIT_X             , NOFLAG);
      CBO_CLEAN      : d = R(SRC_REG, SRC_DC , SRC_X  , FU_STU      , LSU_cbo_clean       , IMM_S       , SPLIT_X             , NOFLAG);
      CBO_FLUSH      : d = R(SRC_REG, SRC_DC , SRC_X  , FU_STU      , LSU_cbo_flush       , IMM_S       , SPLIT_X             , NOFLAG);
      CBO_INVAL      : d = R(SRC_REG, SRC_DC , SRC_X  , FU_STU      , LSU_cbo_inval       , IMM_S       , SPLIT_X             , NOFLAG);

      // ======== SvinvalDecode ========
      SINVAL_VMA     : d = R(SRC_REG, SRC_REG, SRC_X  , FU_FENCE    , FENCE_sfence        , SELIMM_X    , SPLIT_X             , NOSPEC | BLOCKBACK);
      SFENCE_W_INVAL : d = R(SRC_DC , SRC_DC , SRC_X  , FU_FENCE    , FENCE_nofence       , SELIMM_X    , SPLIT_X             , NOSPEC | BLOCKBACK);
      SFENCE_INVAL_IR: d = R(SRC_DC , SRC_DC , SRC_X  , FU_FENCE    , FENCE_nofence       , SELIMM_X    , SPLIT_X             , NOSPEC | BLOCKBACK | FLUSHPIPE);

      // ======== HypervisorDecode ========
      HFENCE_GVMA    : d = R(SRC_REG, SRC_REG, SRC_X  , FU_FENCE    , FENCE_hfence_g      , SELIMM_X    , SPLIT_X             , NOSPEC | BLOCKBACK | FLUSHPIPE);
      HFENCE_VVMA    : d = R(SRC_REG, SRC_REG, SRC_X  , FU_FENCE    , FENCE_hfence_v      , SELIMM_X    , SPLIT_X             , NOSPEC | BLOCKBACK | FLUSHPIPE);
      HINVAL_GVMA    : d = R(SRC_REG, SRC_REG, SRC_X  , FU_FENCE    , FENCE_hfence_g      , SELIMM_X    , SPLIT_X             , NOSPEC | BLOCKBACK);
      HINVAL_VVMA    : d = R(SRC_REG, SRC_REG, SRC_X  , FU_FENCE    , FENCE_hfence_v      , SELIMM_X    , SPLIT_X             , NOSPEC | BLOCKBACK);
      HLV_B          : d = R(SRC_REG, SRC_X  , SRC_X  , FU_LDU      , LSU_hlvb            , SELIMM_X    , SPLIT_X             , XWEN);
      HLV_BU         : d = R(SRC_REG, SRC_X  , SRC_X  , FU_LDU      , LSU_hlvbu           , SELIMM_X    , SPLIT_X             , XWEN);
      HLV_D          : d = R(SRC_REG, SRC_X  , SRC_X  , FU_LDU      , LSU_hlvd            , SELIMM_X    , SPLIT_X             , XWEN);
      HLV_H          : d = R(SRC_REG, SRC_X  , SRC_X  , FU_LDU      , LSU_hlvh            , SELIMM_X    , SPLIT_X             , XWEN);
      HLV_HU         : d = R(SRC_REG, SRC_X  , SRC_X  , FU_LDU      , LSU_hlvhu           , SELIMM_X    , SPLIT_X             , XWEN);
      HLV_W          : d = R(SRC_REG, SRC_X  , SRC_X  , FU_LDU      , LSU_hlvw            , SELIMM_X    , SPLIT_X             , XWEN);
      HLV_WU         : d = R(SRC_REG, SRC_X  , SRC_X  , FU_LDU      , LSU_hlvwu           , SELIMM_X    , SPLIT_X             , XWEN);
      HLVX_HU        : d = R(SRC_REG, SRC_X  , SRC_X  , FU_LDU      , LSU_hlvxhu          , SELIMM_X    , SPLIT_X             , XWEN);
      HLVX_WU        : d = R(SRC_REG, SRC_X  , SRC_X  , FU_LDU      , LSU_hlvxwu          , SELIMM_X    , SPLIT_X             , XWEN);
      HSV_B          : d = R(SRC_REG, SRC_REG, SRC_X  , FU_STU      , LSU_hsvb            , SELIMM_X    , SPLIT_X             , NOFLAG);
      HSV_D          : d = R(SRC_REG, SRC_REG, SRC_X  , FU_STU      , LSU_hsvd            , SELIMM_X    , SPLIT_X             , NOFLAG);
      HSV_H          : d = R(SRC_REG, SRC_REG, SRC_X  , FU_STU      , LSU_hsvh            , SELIMM_X    , SPLIT_X             , NOFLAG);
      HSV_W          : d = R(SRC_REG, SRC_REG, SRC_X  , FU_STU      , LSU_hsvw            , SELIMM_X    , SPLIT_X             , NOFLAG);

      // ======== VecDecoder.vset ========
      VSETVLI        : d = R(SRC_XP , SRC_IMM, SRC_X  , FU_VSETIWF  , VSET_uvsetvcfg_xi   , IMM_VSETVLI , SPLIT_VSET          , NOFLAG);
      VSETIVLI       : d = R(SRC_IMM, SRC_IMM, SRC_X  , FU_VSETIWF  , VSET_uvsetvcfg_ii   , IMM_VSETIVLI, SPLIT_VSET          , NOFLAG);
      VSETVL         : d = R(SRC_XP , SRC_XP , SRC_X  , FU_VSETIWF  , VSET_uvsetvcfg_xx   , SELIMM_X    , SPLIT_VSET          , BLOCKBACK | FLUSHPIPE);  // flush pipe

      // ======== VecDecoder.opivv ========
      VADD_VV        : d = R(SRC_VP , SRC_VP , SRC_VP , FU_VIALUF   , VIALU_vadd_vv       , SELIMM_X    , SPLIT_VEC_VVV       , VWEN);
      VSUB_VV        : d = R(SRC_VP , SRC_VP , SRC_VP , FU_VIALUF   , VIALU_vsub_vv       , SELIMM_X    , SPLIT_VEC_VVV       , VWEN);
      VMINU_VV       : d = R(SRC_VP , SRC_VP , SRC_VP , FU_VIALUF   , VIALU_vminu_vv      , SELIMM_X    , SPLIT_VEC_VVV       , VWEN);
      VMIN_VV        : d = R(SRC_VP , SRC_VP , SRC_VP , FU_VIALUF   , VIALU_vmin_vv       , SELIMM_X    , SPLIT_VEC_VVV       , VWEN);
      VMAXU_VV       : d = R(SRC_VP , SRC_VP , SRC_VP , FU_VIALUF   , VIALU_vmaxu_vv      , SELIMM_X    , SPLIT_VEC_VVV       , VWEN);
      VMAX_VV        : d = R(SRC_VP , SRC_VP , SRC_VP , FU_VIALUF   , VIALU_vmax_vv       , SELIMM_X    , SPLIT_VEC_VVV       , VWEN);
      VAND_VV        : d = R(SRC_VP , SRC_VP , SRC_VP , FU_VIALUF   , VIALU_vand_vv       , SELIMM_X    , SPLIT_VEC_VVV       , VWEN);
      VOR_VV         : d = R(SRC_VP , SRC_VP , SRC_VP , FU_VIALUF   , VIALU_vor_vv        , SELIMM_X    , SPLIT_VEC_VVV       , VWEN);
      VXOR_VV        : d = R(SRC_VP , SRC_VP , SRC_VP , FU_VIALUF   , VIALU_vxor_vv       , SELIMM_X    , SPLIT_VEC_VVV       , VWEN);
      VRGATHER_VV    : d = R(SRC_VP , SRC_VP , SRC_VP , FU_VPPU     , VPERM_vrgather      , SELIMM_X    , SPLIT_VEC_RGATHER   , VWEN);
      VRGATHEREI16_VV: d = R(SRC_VP , SRC_VP , SRC_VP , FU_VPPU     , VPERM_vrgatherei16  , SELIMM_X    , SPLIT_VEC_RGATHEREI16, VWEN);
      VADC_VVM       : d = R(SRC_VP , SRC_VP , SRC_VP , FU_VIALUF   , VIALU_vadc_vvm      , SELIMM_X    , SPLIT_VEC_VVV       , VWEN);
      VMADC_VVM      : d = R(SRC_VP , SRC_VP , SRC_VP , FU_VIALUF   , VIALU_vmadc_vvm     , SELIMM_X    , SPLIT_VEC_VVM       , VWEN);
      VMADC_VV       : d = R(SRC_VP , SRC_VP , SRC_VP , FU_VIALUF   , VIALU_vmadc_vv      , SELIMM_X    , SPLIT_VEC_VVM       , VWEN);
      VSBC_VVM       : d = R(SRC_VP , SRC_VP , SRC_VP , FU_VIALUF   , VIALU_vsbc_vvm      , SELIMM_X    , SPLIT_VEC_VVV       , VWEN);
      VMSBC_VV       : d = R(SRC_VP , SRC_VP , SRC_VP , FU_VIALUF   , VIALU_vmsbc_vv      , SELIMM_X    , SPLIT_VEC_VVM       , VWEN);
      VMSBC_VVM      : d = R(SRC_VP , SRC_VP , SRC_VP , FU_VIALUF   , VIALU_vmsbc_vvm     , SELIMM_X    , SPLIT_VEC_VVM       , VWEN);
      VMERGE_VVM     : d = R(SRC_VP , SRC_VP , SRC_VP , FU_VIALUF   , VIALU_vmerge_vvm    , SELIMM_X    , SPLIT_VEC_VVV       , VWEN);
      VMV_V_V        : d = R(SRC_VP , SRC_NO , SRC_VP , FU_VIALUF   , VIALU_vmv_v_v       , SELIMM_X    , SPLIT_VEC_VVV       , VWEN);  // vd[i] = vs1[i], vs2=v0
      VMSEQ_VV       : d = R(SRC_VP , SRC_VP , SRC_VP , FU_VIALUF   , VIALU_vmseq_vv      , SELIMM_X    , SPLIT_VEC_VVM       , VWEN);
      VMSNE_VV       : d = R(SRC_VP , SRC_VP , SRC_VP , FU_VIALUF   , VIALU_vmsne_vv      , SELIMM_X    , SPLIT_VEC_VVM       , VWEN);
      VMSLTU_VV      : d = R(SRC_VP , SRC_VP , SRC_VP , FU_VIALUF   , VIALU_vmsltu_vv     , SELIMM_X    , SPLIT_VEC_VVM       , VWEN);
      VMSLT_VV       : d = R(SRC_VP , SRC_VP , SRC_VP , FU_VIALUF   , VIALU_vmslt_vv      , SELIMM_X    , SPLIT_VEC_VVM       , VWEN);
      VMSLEU_VV      : d = R(SRC_VP , SRC_VP , SRC_VP , FU_VIALUF   , VIALU_vmsleu_vv     , SELIMM_X    , SPLIT_VEC_VVM       , VWEN);
      VMSLE_VV       : d = R(SRC_VP , SRC_VP , SRC_VP , FU_VIALUF   , VIALU_vmsle_vv      , SELIMM_X    , SPLIT_VEC_VVM       , VWEN);
      VSLL_VV        : d = R(SRC_VP , SRC_VP , SRC_VP , FU_VIALUF   , VIALU_vsll_vv       , SELIMM_X    , SPLIT_VEC_VVV       , VWEN);
      VSRL_VV        : d = R(SRC_VP , SRC_VP , SRC_VP , FU_VIALUF   , VIALU_vsrl_vv       , SELIMM_X    , SPLIT_VEC_VVV       , VWEN);
      VSRA_VV        : d = R(SRC_VP , SRC_VP , SRC_VP , FU_VIALUF   , VIALU_vsra_vv       , SELIMM_X    , SPLIT_VEC_VVV       , VWEN);
      VNSRL_WV       : d = R(SRC_VP , SRC_VP , SRC_VP , FU_VIALUF   , VIALU_vnsrl_wv      , SELIMM_X    , SPLIT_VEC_WVV       , VWEN);
      VNSRA_WV       : d = R(SRC_VP , SRC_VP , SRC_VP , FU_VIALUF   , VIALU_vnsra_wv      , SELIMM_X    , SPLIT_VEC_WVV       , VWEN);
      VSADDU_VV      : d = R(SRC_VP , SRC_VP , SRC_VP , FU_VIALUF   , VIALU_vsaddu_vv     , SELIMM_X    , SPLIT_VEC_VVV       , VWEN);
      VSADD_VV       : d = R(SRC_VP , SRC_VP , SRC_VP , FU_VIALUF   , VIALU_vsadd_vv      , SELIMM_X    , SPLIT_VEC_VVV       , VWEN);
      VSSUBU_VV      : d = R(SRC_VP , SRC_VP , SRC_VP , FU_VIALUF   , VIALU_vssubu_vv     , SELIMM_X    , SPLIT_VEC_VVV       , VWEN);
      VSSUB_VV       : d = R(SRC_VP , SRC_VP , SRC_VP , FU_VIALUF   , VIALU_vssub_vv      , SELIMM_X    , SPLIT_VEC_VVV       , VWEN);
      VSMUL_VV       : d = R(SRC_VP , SRC_VP , SRC_VP , FU_VIMAC    , VIMAC_vsmul         , SELIMM_X    , SPLIT_VEC_VVV       , VWEN);
      VSSRL_VV       : d = R(SRC_VP , SRC_VP , SRC_VP , FU_VIALUF   , VIALU_vssrl_vv      , SELIMM_X    , SPLIT_VEC_VVV       , VWEN);
      VSSRA_VV       : d = R(SRC_VP , SRC_VP , SRC_VP , FU_VIALUF   , VIALU_vssra_vv      , SELIMM_X    , SPLIT_VEC_VVV       , VWEN);
      VNCLIPU_WV     : d = R(SRC_VP , SRC_VP , SRC_VP , FU_VIALUF   , VIALU_vnclipu_wv    , SELIMM_X    , SPLIT_VEC_WVV       , VWEN);
      VNCLIP_WV      : d = R(SRC_VP , SRC_VP , SRC_VP , FU_VIALUF   , VIALU_vnclip_wv     , SELIMM_X    , SPLIT_VEC_WVV       , VWEN);
      VWREDSUMU_VS   : d = R(SRC_VP , SRC_VP , SRC_VP , FU_VIPU     , VIPU_vwredsumu_vs   , SELIMM_X    , SPLIT_VEC_VWW       , VWEN);
      VWREDSUM_VS    : d = R(SRC_VP , SRC_VP , SRC_VP , FU_VIPU     , VIPU_vwredsum_vs    , SELIMM_X    , SPLIT_VEC_VWW       , VWEN);
      // Zvbb
      VANDN_VV       : d = R(SRC_VP , SRC_VP , SRC_VP , FU_VIALUF   , VIALU_vandn_vv      , SELIMM_X    , SPLIT_VEC_VVV       , VWEN);
      VROL_VV        : d = R(SRC_VP , SRC_VP , SRC_VP , FU_VIALUF   , VIALU_vrol_vv       , SELIMM_X    , SPLIT_VEC_VVV       , VWEN);
      VROR_VV        : d = R(SRC_VP , SRC_VP , SRC_VP , FU_VIALUF   , VIALU_vror_vv       , SELIMM_X    , SPLIT_VEC_VVV       , VWEN);
      VWSLL_VV       : d = R(SRC_VP , SRC_VP , SRC_VP , FU_VIALUF   , VIALU_vwsll_vv      , SELIMM_X    , SPLIT_VEC_VVW       , VWEN);

      // ======== VecDecoder.opivx ========
      VADD_VX        : d = R(SRC_XP , SRC_VP , SRC_VP , FU_VIALUF   , VIALU_vadd_vv       , SELIMM_X    , SPLIT_VEC_VXV       , VWEN);
      VSUB_VX        : d = R(SRC_XP , SRC_VP , SRC_VP , FU_VIALUF   , VIALU_vsub_vv       , SELIMM_X    , SPLIT_VEC_VXV       , VWEN);
      VRSUB_VX       : d = R(SRC_XP , SRC_VP , SRC_VP , FU_VIALUF   , VIALU_vrsub_vv      , SELIMM_X    , SPLIT_VEC_VXV       , VWEN);
      VMINU_VX       : d = R(SRC_XP , SRC_VP , SRC_VP , FU_VIALUF   , VIALU_vminu_vv      , SELIMM_X    , SPLIT_VEC_VXV       , VWEN);
      VMIN_VX        : d = R(SRC_XP , SRC_VP , SRC_VP , FU_VIALUF   , VIALU_vmin_vv       , SELIMM_X    , SPLIT_VEC_VXV       , VWEN);
      VMAXU_VX       : d = R(SRC_XP , SRC_VP , SRC_VP , FU_VIALUF   , VIALU_vmaxu_vv      , SELIMM_X    , SPLIT_VEC_VXV       , VWEN);
      VMAX_VX        : d = R(SRC_XP , SRC_VP , SRC_VP , FU_VIALUF   , VIALU_vmax_vv       , SELIMM_X    , SPLIT_VEC_VXV       , VWEN);
      VAND_VX        : d = R(SRC_XP , SRC_VP , SRC_VP , FU_VIALUF   , VIALU_vand_vv       , SELIMM_X    , SPLIT_VEC_VXV       , VWEN);
      VOR_VX         : d = R(SRC_XP , SRC_VP , SRC_VP , FU_VIALUF   , VIALU_vor_vv        , SELIMM_X    , SPLIT_VEC_VXV       , VWEN);
      VXOR_VX        : d = R(SRC_XP , SRC_VP , SRC_VP , FU_VIALUF   , VIALU_vxor_vv       , SELIMM_X    , SPLIT_VEC_VXV       , VWEN);
      VRGATHER_VX    : d = R(SRC_XP , SRC_VP , SRC_VP , FU_VPPU     , VPERM_vrgather_vx   , SELIMM_X    , SPLIT_VEC_RGATHER_VX, VWEN);
      VSLIDEUP_VX    : d = R(SRC_XP , SRC_VP , SRC_VP , FU_VPPU     , VPERM_vslideup      , SELIMM_X    , SPLIT_VEC_SLIDEUP   , VWEN);
      VSLIDEDOWN_VX  : d = R(SRC_XP , SRC_VP , SRC_VP , FU_VPPU     , VPERM_vslidedown    , SELIMM_X    , SPLIT_VEC_SLIDEDOWN , VWEN);
      VADC_VXM       : d = R(SRC_XP , SRC_VP , SRC_VP , FU_VIALUF   , VIALU_vadc_vvm      , SELIMM_X    , SPLIT_VEC_VXV       , VWEN);
      VMADC_VXM      : d = R(SRC_XP , SRC_VP , SRC_VP , FU_VIALUF   , VIALU_vmadc_vvm     , SELIMM_X    , SPLIT_VEC_VXM       , VWEN);
      VMADC_VX       : d = R(SRC_XP , SRC_VP , SRC_VP , FU_VIALUF   , VIALU_vmadc_vv      , SELIMM_X    , SPLIT_VEC_VXM       , VWEN);
      VSBC_VXM       : d = R(SRC_XP , SRC_VP , SRC_VP , FU_VIALUF   , VIALU_vsbc_vvm      , SELIMM_X    , SPLIT_VEC_VXV       , VWEN);
      VMSBC_VX       : d = R(SRC_XP , SRC_VP , SRC_VP , FU_VIALUF   , VIALU_vmsbc_vv      , SELIMM_X    , SPLIT_VEC_VXM       , VWEN);
      VMSBC_VXM      : d = R(SRC_XP , SRC_VP , SRC_VP , FU_VIALUF   , VIALU_vmsbc_vvm     , SELIMM_X    , SPLIT_VEC_VXM       , VWEN);
      VMERGE_VXM     : d = R(SRC_XP , SRC_VP , SRC_VP , FU_VIALUF   , VIALU_vmerge_vvm    , SELIMM_X    , SPLIT_VEC_VXV       , VWEN);
      VMV_V_X        : d = R(SRC_XP , SRC_NO , SRC_VP , FU_VIALUF   , VIALU_vmv_v_v       , SELIMM_X    , SPLIT_VEC_VXV       , VWEN);  // vd[i] = x[rs1], vs2 = v0
      VMSEQ_VX       : d = R(SRC_XP , SRC_VP , SRC_VP , FU_VIALUF   , VIALU_vmseq_vv      , SELIMM_X    , SPLIT_VEC_VXM       , VWEN);
      VMSNE_VX       : d = R(SRC_XP , SRC_VP , SRC_VP , FU_VIALUF   , VIALU_vmsne_vv      , SELIMM_X    , SPLIT_VEC_VXM       , VWEN);
      VMSLTU_VX      : d = R(SRC_XP , SRC_VP , SRC_VP , FU_VIALUF   , VIALU_vmsltu_vv     , SELIMM_X    , SPLIT_VEC_VXM       , VWEN);
      VMSLT_VX       : d = R(SRC_XP , SRC_VP , SRC_VP , FU_VIALUF   , VIALU_vmslt_vv      , SELIMM_X    , SPLIT_VEC_VXM       , VWEN);
      VMSLEU_VX      : d = R(SRC_XP , SRC_VP , SRC_VP , FU_VIALUF   , VIALU_vmsleu_vv     , SELIMM_X    , SPLIT_VEC_VXM       , VWEN);
      VMSLE_VX       : d = R(SRC_XP , SRC_VP , SRC_VP , FU_VIALUF   , VIALU_vmsle_vv      , SELIMM_X    , SPLIT_VEC_VXM       , VWEN);
      VMSGTU_VX      : d = R(SRC_XP , SRC_VP , SRC_VP , FU_VIALUF   , VIALU_vmsgtu_vv     , SELIMM_X    , SPLIT_VEC_VXM       , VWEN);
      VMSGT_VX       : d = R(SRC_XP , SRC_VP , SRC_VP , FU_VIALUF   , VIALU_vmsgt_vv      , SELIMM_X    , SPLIT_VEC_VXM       , VWEN);
      VSLL_VX        : d = R(SRC_XP , SRC_VP , SRC_VP , FU_VIALUF   , VIALU_vsll_vv       , SELIMM_X    , SPLIT_VEC_VXV       , VWEN);
      VSRL_VX        : d = R(SRC_XP , SRC_VP , SRC_VP , FU_VIALUF   , VIALU_vsrl_vv       , SELIMM_X    , SPLIT_VEC_VXV       , VWEN);
      VSRA_VX        : d = R(SRC_XP , SRC_VP , SRC_VP , FU_VIALUF   , VIALU_vsra_vv       , SELIMM_X    , SPLIT_VEC_VXV       , VWEN);
      VNSRL_WX       : d = R(SRC_XP , SRC_VP , SRC_VP , FU_VIALUF   , VIALU_vnsrl_wv      , SELIMM_X    , SPLIT_VEC_WXV       , VWEN);
      VNSRA_WX       : d = R(SRC_XP , SRC_VP , SRC_VP , FU_VIALUF   , VIALU_vnsra_wv      , SELIMM_X    , SPLIT_VEC_WXV       , VWEN);
      VSADDU_VX      : d = R(SRC_XP , SRC_VP , SRC_VP , FU_VIALUF   , VIALU_vsaddu_vv     , SELIMM_X    , SPLIT_VEC_VXV       , VWEN);
      VSADD_VX       : d = R(SRC_XP , SRC_VP , SRC_VP , FU_VIALUF   , VIALU_vsadd_vv      , SELIMM_X    , SPLIT_VEC_VXV       , VWEN);
      VSSUBU_VX      : d = R(SRC_XP , SRC_VP , SRC_VP , FU_VIALUF   , VIALU_vssubu_vv     , SELIMM_X    , SPLIT_VEC_VXV       , VWEN);
      VSSUB_VX       : d = R(SRC_XP , SRC_VP , SRC_VP , FU_VIALUF   , VIALU_vssub_vv      , SELIMM_X    , SPLIT_VEC_VXV       , VWEN);
      VSMUL_VX       : d = R(SRC_XP , SRC_VP , SRC_VP , FU_VIMAC    , VIMAC_vsmul         , SELIMM_X    , SPLIT_VEC_VXV       , VWEN);
      VSSRL_VX       : d = R(SRC_XP , SRC_VP , SRC_VP , FU_VIALUF   , VIALU_vssrl_vv      , SELIMM_X    , SPLIT_VEC_VXV       , VWEN);
      VSSRA_VX       : d = R(SRC_XP , SRC_VP , SRC_VP , FU_VIALUF   , VIALU_vssra_vv      , SELIMM_X    , SPLIT_VEC_VXV       , VWEN);
      VNCLIPU_WX     : d = R(SRC_XP , SRC_VP , SRC_VP , FU_VIALUF   , VIALU_vnclipu_wv    , SELIMM_X    , SPLIT_VEC_WXV       , VWEN);
      VNCLIP_WX      : d = R(SRC_XP , SRC_VP , SRC_VP , FU_VIALUF   , VIALU_vnclip_wv     , SELIMM_X    , SPLIT_VEC_WXV       , VWEN);
      // Zvbb
      VANDN_VX       : d = R(SRC_XP , SRC_VP , SRC_VP , FU_VIALUF   , VIALU_vandn_vv      , SELIMM_X    , SPLIT_VEC_VXV       , VWEN);
      VROL_VX        : d = R(SRC_XP , SRC_VP , SRC_VP , FU_VIALUF   , VIALU_vrol_vv       , SELIMM_X    , SPLIT_VEC_VXV       , VWEN);
      VROR_VX        : d = R(SRC_XP , SRC_VP , SRC_VP , FU_VIALUF   , VIALU_vror_vv       , SELIMM_X    , SPLIT_VEC_VXV       , VWEN);
      VWSLL_VX       : d = R(SRC_XP , SRC_VP , SRC_VP , FU_VIALUF   , VIALU_vwsll_vv      , SELIMM_X    , SPLIT_VEC_VXW       , VWEN);

      // ======== VecDecoder.opivi ========
      VADD_VI        : d = R(SRC_IMM, SRC_VP , SRC_VP , FU_VIALUF   , VIALU_vadd_vv       , IMM_OPIVIS  , SPLIT_VEC_VXV       , VWEN);
      VRSUB_VI       : d = R(SRC_IMM, SRC_VP , SRC_VP , FU_VIALUF   , VIALU_vrsub_vv      , IMM_OPIVIS  , SPLIT_VEC_VXV       , VWEN);
      VAND_VI        : d = R(SRC_IMM, SRC_VP , SRC_VP , FU_VIALUF   , VIALU_vand_vv       , IMM_OPIVIS  , SPLIT_VEC_VXV       , VWEN);
      VOR_VI         : d = R(SRC_IMM, SRC_VP , SRC_VP , FU_VIALUF   , VIALU_vor_vv        , IMM_OPIVIS  , SPLIT_VEC_VXV       , VWEN);
      VXOR_VI        : d = R(SRC_IMM, SRC_VP , SRC_VP , FU_VIALUF   , VIALU_vxor_vv       , IMM_OPIVIS  , SPLIT_VEC_VXV       , VWEN);
      VRGATHER_VI    : d = R(SRC_IMM, SRC_VP , SRC_VP , FU_VPPU     , VPERM_vrgather_vx   , IMM_OPIVIU  , SPLIT_VEC_RGATHER_VX, VWEN);
      VSLIDEUP_VI    : d = R(SRC_IMM, SRC_VP , SRC_VP , FU_VPPU     , VPERM_vslideup      , IMM_OPIVIU  , SPLIT_VEC_SLIDEUP   , VWEN);
      VSLIDEDOWN_VI  : d = R(SRC_IMM, SRC_VP , SRC_VP , FU_VPPU     , VPERM_vslidedown    , IMM_OPIVIU  , SPLIT_VEC_SLIDEDOWN , VWEN);
      VADC_VIM       : d = R(SRC_IMM, SRC_VP , SRC_VP , FU_VIALUF   , VIALU_vadc_vvm      , IMM_OPIVIS  , SPLIT_VEC_VXV       , VWEN);
      VMADC_VIM      : d = R(SRC_IMM, SRC_VP , SRC_VP , FU_VIALUF   , VIALU_vmadc_vvm     , IMM_OPIVIS  , SPLIT_VEC_VXM       , VWEN);
      VMADC_VI       : d = R(SRC_IMM, SRC_VP , SRC_VP , FU_VIALUF   , VIALU_vmadc_vv      , IMM_OPIVIS  , SPLIT_VEC_VXM       , VWEN);
      VMERGE_VIM     : d = R(SRC_IMM, SRC_VP , SRC_VP , FU_VIALUF   , VIALU_vmerge_vvm    , IMM_OPIVIS  , SPLIT_VEC_VXV       , VWEN);
      VMV_V_I        : d = R(SRC_IMM, SRC_NO , SRC_VP , FU_VIALUF   , VIALU_vmv_v_v       , IMM_OPIVIS  , SPLIT_VEC_VXV       , VWEN);  // vd[i] = imm, vs2 = v0
      VMSEQ_VI       : d = R(SRC_IMM, SRC_VP , SRC_VP , FU_VIALUF   , VIALU_vmseq_vv      , IMM_OPIVIS  , SPLIT_VEC_VXM       , VWEN);
      VMSNE_VI       : d = R(SRC_IMM, SRC_VP , SRC_VP , FU_VIALUF   , VIALU_vmsne_vv      , IMM_OPIVIS  , SPLIT_VEC_VXM       , VWEN);
      VMSLEU_VI      : d = R(SRC_IMM, SRC_VP , SRC_VP , FU_VIALUF   , VIALU_vmsleu_vv     , IMM_OPIVIS  , SPLIT_VEC_VXM       , VWEN);
      VMSLE_VI       : d = R(SRC_IMM, SRC_VP , SRC_VP , FU_VIALUF   , VIALU_vmsle_vv      , IMM_OPIVIS  , SPLIT_VEC_VXM       , VWEN);
      VMSGTU_VI      : d = R(SRC_IMM, SRC_VP , SRC_VP , FU_VIALUF   , VIALU_vmsgtu_vv     , IMM_OPIVIS  , SPLIT_VEC_VXM       , VWEN);
      VMSGT_VI       : d = R(SRC_IMM, SRC_VP , SRC_VP , FU_VIALUF   , VIALU_vmsgt_vv      , IMM_OPIVIS  , SPLIT_VEC_VXM       , VWEN);
      VSLL_VI        : d = R(SRC_IMM, SRC_VP , SRC_VP , FU_VIALUF   , VIALU_vsll_vv       , IMM_OPIVIU  , SPLIT_VEC_VXV       , VWEN);
      VSRL_VI        : d = R(SRC_IMM, SRC_VP , SRC_VP , FU_VIALUF   , VIALU_vsrl_vv       , IMM_OPIVIU  , SPLIT_VEC_VXV       , VWEN);
      VSRA_VI        : d = R(SRC_IMM, SRC_VP , SRC_VP , FU_VIALUF   , VIALU_vsra_vv       , IMM_OPIVIU  , SPLIT_VEC_VXV       , VWEN);
      VNSRL_WI       : d = R(SRC_IMM, SRC_VP , SRC_VP , FU_VIALUF   , VIALU_vnsrl_wv      , IMM_OPIVIU  , SPLIT_VEC_WXV       , VWEN);
      VNSRA_WI       : d = R(SRC_IMM, SRC_VP , SRC_VP , FU_VIALUF   , VIALU_vnsra_wv      , IMM_OPIVIU  , SPLIT_VEC_WXV       , VWEN);
      VSADDU_VI      : d = R(SRC_IMM, SRC_VP , SRC_VP , FU_VIALUF   , VIALU_vsaddu_vv     , IMM_OPIVIS  , SPLIT_VEC_VXV       , VWEN);
      VSADD_VI       : d = R(SRC_IMM, SRC_VP , SRC_VP , FU_VIALUF   , VIALU_vsadd_vv      , IMM_OPIVIS  , SPLIT_VEC_VXV       , VWEN);
      VSSRL_VI       : d = R(SRC_IMM, SRC_VP , SRC_VP , FU_VIALUF   , VIALU_vssrl_vv      , IMM_OPIVIU  , SPLIT_VEC_VXV       , VWEN);
      VSSRA_VI       : d = R(SRC_IMM, SRC_VP , SRC_VP , FU_VIALUF   , VIALU_vssra_vv      , IMM_OPIVIU  , SPLIT_VEC_VXV       , VWEN);
      VNCLIPU_WI     : d = R(SRC_IMM, SRC_VP , SRC_VP , FU_VIALUF   , VIALU_vnclipu_wv    , IMM_OPIVIU  , SPLIT_VEC_WXV       , VWEN);
      VNCLIP_WI      : d = R(SRC_IMM, SRC_VP , SRC_VP , FU_VIALUF   , VIALU_vnclip_wv     , IMM_OPIVIU  , SPLIT_VEC_WXV       , VWEN);
      VMV1R_V        : d = R(SRC_NO , SRC_VP , SRC_VP , FU_VPPU     , VPERM_vmv1r         , IMM_OPIVIS  , SPLIT_VEC_MVNR      , VWEN);  // vmv1r.v vd, vs2
      VMV2R_V        : d = R(SRC_NO , SRC_VP , SRC_VP , FU_VPPU     , VPERM_vmv2r         , IMM_OPIVIS  , SPLIT_VEC_MVNR      , VWEN);  // vmv2r.v vd, vs2
      VMV4R_V        : d = R(SRC_NO , SRC_VP , SRC_VP , FU_VPPU     , VPERM_vmv4r         , IMM_OPIVIS  , SPLIT_VEC_MVNR      , VWEN);  // vmv4r.v vd, vs2
      VMV8R_V        : d = R(SRC_NO , SRC_VP , SRC_VP , FU_VPPU     , VPERM_vmv8r         , IMM_OPIVIS  , SPLIT_VEC_MVNR      , VWEN);  // vmv8r.v vd, vs2
      // Zvbb
      VROR_VI        : d = R(SRC_IMM, SRC_VP , SRC_VP , FU_VIALUF   , VIALU_vror_vv       , IMM_VRORVI  , SPLIT_VEC_VXV       , VWEN);
      VWSLL_VI       : d = R(SRC_IMM, SRC_VP , SRC_VP , FU_VIALUF   , VIALU_vwsll_vv      , IMM_OPIVIU  , SPLIT_VEC_VXW       , VWEN);

      // ======== VecDecoder.opmvv ========
      VAADD_VV       : d = R(SRC_VP , SRC_VP , SRC_VP , FU_VIALUF   , VIALU_vaadd_vv      , SELIMM_X    , SPLIT_VEC_VVV       , VWEN);
      VAADDU_VV      : d = R(SRC_VP , SRC_VP , SRC_VP , FU_VIALUF   , VIALU_vaaddu_vv     , SELIMM_X    , SPLIT_VEC_VVV       , VWEN);
      VASUB_VV       : d = R(SRC_VP , SRC_VP , SRC_VP , FU_VIALUF   , VIALU_vasub_vv      , SELIMM_X    , SPLIT_VEC_VVV       , VWEN);
      VASUBU_VV      : d = R(SRC_VP , SRC_VP , SRC_VP , FU_VIALUF   , VIALU_vasubu_vv     , SELIMM_X    , SPLIT_VEC_VVV       , VWEN);
      VCOMPRESS_VM   : d = R(SRC_VP , SRC_VP , SRC_VP , FU_VPPU     , VPERM_vcompress     , SELIMM_X    , SPLIT_VEC_COMPRESS  , VWEN);
      VCPOP_M        : d = R(SRC_NO , SRC_VP , SRC_VP , FU_VIPU     , VIPU_vcpop_m        , SELIMM_X    , SPLIT_VEC_M0X       , XWEN);  // vcpop.m rd, vs2, vm
      VDIV_VV        : d = R(SRC_VP , SRC_VP , SRC_VP , FU_VIDIV    , VIDIV_vdiv          , SELIMM_X    , SPLIT_VEC_VVV       , VWEN);
      VDIVU_VV       : d = R(SRC_VP , SRC_VP , SRC_VP , FU_VIDIV    , VIDIV_vdivu         , SELIMM_X    , SPLIT_VEC_VVV       , VWEN);
      VFIRST_M       : d = R(SRC_NO , SRC_VP , SRC_VP , FU_VIPU     , VIPU_vfirst_m       , SELIMM_X    , SPLIT_DUMMY         , XWEN);  // vfirst.m rd, vs2, vm
      VID_V          : d = R(SRC_NO , SRC_NO , SRC_VP , FU_VIPU     , VIPU_vid_v          , SELIMM_X    , SPLIT_VEC_MVV       , VWEN);  // vid.v vd, vm
      VIOTA_M        : d = R(SRC_NO , SRC_VP , SRC_VP , FU_VIPU     , VIPU_viota_m        , SELIMM_X    , SPLIT_VEC_MVV       , VWEN);  // viota.m vd, vs2, vm
      VMACC_VV       : d = R(SRC_VP , SRC_VP , SRC_VP , FU_VIMAC    , VIMAC_vmacc         , SELIMM_X    , SPLIT_VEC_VVV       , VWEN);
      VMADD_VV       : d = R(SRC_VP , SRC_VP , SRC_VP , FU_VIMAC    , VIMAC_vmadd         , SELIMM_X    , SPLIT_VEC_VVV       , VWEN);
      VMAND_MM       : d = R(SRC_VP , SRC_VP , SRC_VP , FU_VIALUF   , VIALU_vmand_mm      , SELIMM_X    , SPLIT_DUMMY         , VWEN);
      VMANDN_MM      : d = R(SRC_VP , SRC_VP , SRC_VP , FU_VIALUF   , VIALU_vmandn_mm     , SELIMM_X    , SPLIT_DUMMY         , VWEN);
      VMNAND_MM      : d = R(SRC_VP , SRC_VP , SRC_VP , FU_VIALUF   , VIALU_vmnand_mm     , SELIMM_X    , SPLIT_DUMMY         , VWEN);
      VMNOR_MM       : d = R(SRC_VP , SRC_VP , SRC_VP , FU_VIALUF   , VIALU_vmnor_mm      , SELIMM_X    , SPLIT_DUMMY         , VWEN);
      VMOR_MM        : d = R(SRC_VP , SRC_VP , SRC_VP , FU_VIALUF   , VIALU_vmor_mm       , SELIMM_X    , SPLIT_DUMMY         , VWEN);
      VMORN_MM       : d = R(SRC_VP , SRC_VP , SRC_VP , FU_VIALUF   , VIALU_vmorn_mm      , SELIMM_X    , SPLIT_DUMMY         , VWEN);
      VMXNOR_MM      : d = R(SRC_VP , SRC_VP , SRC_VP , FU_VIALUF   , VIALU_vmxnor_mm     , SELIMM_X    , SPLIT_DUMMY         , VWEN);
      VMXOR_MM       : d = R(SRC_VP , SRC_VP , SRC_VP , FU_VIALUF   , VIALU_vmxor_mm      , SELIMM_X    , SPLIT_DUMMY         , VWEN);
      VMSBF_M        : d = R(SRC_NO , SRC_VP , SRC_VP , FU_VIPU     , VIPU_vmsbf_m        , SELIMM_X    , SPLIT_DUMMY         , VWEN);  // vmsbf.m vd, vs2, vm
      VMSIF_M        : d = R(SRC_NO , SRC_VP , SRC_VP , FU_VIPU     , VIPU_vmsif_m        , SELIMM_X    , SPLIT_DUMMY         , VWEN);  // vmsif.m vd, vs2, vm
      VMSOF_M        : d = R(SRC_NO , SRC_VP , SRC_VP , FU_VIPU     , VIPU_vmsof_m        , SELIMM_X    , SPLIT_DUMMY         , VWEN);  // vmsof.m vd, vs2, vm
      VMUL_VV        : d = R(SRC_VP , SRC_VP , SRC_VP , FU_VIMAC    , VIMAC_vmul          , SELIMM_X    , SPLIT_VEC_VVV       , VWEN);
      VMULH_VV       : d = R(SRC_VP , SRC_VP , SRC_VP , FU_VIMAC    , VIMAC_vmulh         , SELIMM_X    , SPLIT_VEC_VVV       , VWEN);
      VMULHSU_VV     : d = R(SRC_VP , SRC_VP , SRC_VP , FU_VIMAC    , VIMAC_vmulhsu       , SELIMM_X    , SPLIT_VEC_VVV       , VWEN);
      VMULHU_VV      : d = R(SRC_VP , SRC_VP , SRC_VP , FU_VIMAC    , VIMAC_vmulhu        , SELIMM_X    , SPLIT_VEC_VVV       , VWEN);
      VMV_X_S        : d = R(SRC_NO , SRC_VP , SRC_VP , FU_VIPU     , VIPU_vmv_x_s        , SELIMM_X    , SPLIT_DUMMY         , XWEN);  // vmv.x.s rd, vs2 # x[rd] = vs2[0]
      VNMSAC_VV      : d = R(SRC_VP , SRC_VP , SRC_VP , FU_VIMAC    , VIMAC_vnmsac        , SELIMM_X    , SPLIT_VEC_VVV       , VWEN);
      VNMSUB_VV      : d = R(SRC_VP , SRC_VP , SRC_VP , FU_VIMAC    , VIMAC_vnmsub        , SELIMM_X    , SPLIT_VEC_VVV       , VWEN);
      VREDAND_VS     : d = R(SRC_VP , SRC_VP , SRC_VP , FU_VIPU     , VIPU_vredand_vs     , SELIMM_X    , SPLIT_VEC_VRED      , VWEN);
      VREDMAX_VS     : d = R(SRC_VP , SRC_VP , SRC_VP , FU_VIPU     , VIPU_vredmax_vs     , SELIMM_X    , SPLIT_VEC_VRED      , VWEN);
      VREDMAXU_VS    : d = R(SRC_VP , SRC_VP , SRC_VP , FU_VIPU     , VIPU_vredmaxu_vs    , SELIMM_X    , SPLIT_VEC_VRED      , VWEN);
      VREDMIN_VS     : d = R(SRC_VP , SRC_VP , SRC_VP , FU_VIPU     , VIPU_vredmin_vs     , SELIMM_X    , SPLIT_VEC_VRED      , VWEN);
      VREDMINU_VS    : d = R(SRC_VP , SRC_VP , SRC_VP , FU_VIPU     , VIPU_vredminu_vs    , SELIMM_X    , SPLIT_VEC_VRED      , VWEN);
      VREDOR_VS      : d = R(SRC_VP , SRC_VP , SRC_VP , FU_VIPU     , VIPU_vredor_vs      , SELIMM_X    , SPLIT_VEC_VRED      , VWEN);
      VREDSUM_VS     : d = R(SRC_VP , SRC_VP , SRC_VP , FU_VIPU     , VIPU_vredsum_vs     , SELIMM_X    , SPLIT_VEC_VRED      , VWEN);
      VREDXOR_VS     : d = R(SRC_VP , SRC_VP , SRC_VP , FU_VIPU     , VIPU_vredxor_vs     , SELIMM_X    , SPLIT_VEC_VRED      , VWEN);
      VREM_VV        : d = R(SRC_VP , SRC_VP , SRC_VP , FU_VIDIV    , VIDIV_vrem          , SELIMM_X    , SPLIT_VEC_VVV       , VWEN);
      VREMU_VV       : d = R(SRC_VP , SRC_VP , SRC_VP , FU_VIDIV    , VIDIV_vremu         , SELIMM_X    , SPLIT_VEC_VVV       , VWEN);
      VSEXT_VF2      : d = R(SRC_NO , SRC_VP , SRC_VP , FU_VIALUF   , VIALU_vsext_vf2     , SELIMM_X    , SPLIT_VEC_EXT2      , VWEN);  // vsext.vf2 vd, vs2, vm
      VSEXT_VF4      : d = R(SRC_NO , SRC_VP , SRC_VP , FU_VIALUF   , VIALU_vsext_vf4     , SELIMM_X    , SPLIT_VEC_EXT4      , VWEN);  // vsext.vf4 vd, vs2, vm
      VSEXT_VF8      : d = R(SRC_NO , SRC_VP , SRC_VP , FU_VIALUF   , VIALU_vsext_vf8     , SELIMM_X    , SPLIT_VEC_EXT8      , VWEN);  // vsext.vf8 vd, vs2, vm
      VZEXT_VF2      : d = R(SRC_NO , SRC_VP , SRC_VP , FU_VIALUF   , VIALU_vzext_vf2     , SELIMM_X    , SPLIT_VEC_EXT2      , VWEN);  // vzext.vf2 vd, vs2, vm
      VZEXT_VF4      : d = R(SRC_NO , SRC_VP , SRC_VP , FU_VIALUF   , VIALU_vzext_vf4     , SELIMM_X    , SPLIT_VEC_EXT4      , VWEN);  // vzext.vf4 vd, vs2, vm
      VZEXT_VF8      : d = R(SRC_NO , SRC_VP , SRC_VP , FU_VIALUF   , VIALU_vzext_vf8     , SELIMM_X    , SPLIT_VEC_EXT8      , VWEN);  // vzext.vf8 vd, vs2, vm
      VWADD_VV       : d = R(SRC_VP , SRC_VP , SRC_VP , FU_VIALUF   , VIALU_vwadd_vv      , SELIMM_X    , SPLIT_VEC_VVW       , VWEN);
      VWADD_WV       : d = R(SRC_VP , SRC_VP , SRC_VP , FU_VIALUF   , VIALU_vwadd_wv      , SELIMM_X    , SPLIT_VEC_WVW       , VWEN);
      VWADDU_VV      : d = R(SRC_VP , SRC_VP , SRC_VP , FU_VIALUF   , VIALU_vwaddu_vv     , SELIMM_X    , SPLIT_VEC_VVW       , VWEN);
      VWADDU_WV      : d = R(SRC_VP , SRC_VP , SRC_VP , FU_VIALUF   , VIALU_vwaddu_wv     , SELIMM_X    , SPLIT_VEC_WVW       , VWEN);
      VWMACC_VV      : d = R(SRC_VP , SRC_VP , SRC_VP , FU_VIMAC    , VIMAC_vwmacc        , SELIMM_X    , SPLIT_VEC_VVW       , VWEN);
      VWMACCSU_VV    : d = R(SRC_VP , SRC_VP , SRC_VP , FU_VIMAC    , VIMAC_vwmaccsu      , SELIMM_X    , SPLIT_VEC_VVW       , VWEN);
      VWMACCU_VV     : d = R(SRC_VP , SRC_VP , SRC_VP , FU_VIMAC    , VIMAC_vwmaccu       , SELIMM_X    , SPLIT_VEC_VVW       , VWEN);
      VWMUL_VV       : d = R(SRC_VP , SRC_VP , SRC_VP , FU_VIMAC    , VIMAC_vwmul         , SELIMM_X    , SPLIT_VEC_VVW       , VWEN);
      VWMULSU_VV     : d = R(SRC_VP , SRC_VP , SRC_VP , FU_VIMAC    , VIMAC_vwmulsu       , SELIMM_X    , SPLIT_VEC_VVW       , VWEN);
      VWMULU_VV      : d = R(SRC_VP , SRC_VP , SRC_VP , FU_VIMAC    , VIMAC_vwmulu        , SELIMM_X    , SPLIT_VEC_VVW       , VWEN);
      VWSUB_VV       : d = R(SRC_VP , SRC_VP , SRC_VP , FU_VIALUF   , VIALU_vwsub_vv      , SELIMM_X    , SPLIT_VEC_VVW       , VWEN);
      VWSUB_WV       : d = R(SRC_VP , SRC_VP , SRC_VP , FU_VIALUF   , VIALU_vwsub_wv      , SELIMM_X    , SPLIT_VEC_WVW       , VWEN);
      VWSUBU_VV      : d = R(SRC_VP , SRC_VP , SRC_VP , FU_VIALUF   , VIALU_vwsubu_vv     , SELIMM_X    , SPLIT_VEC_VVW       , VWEN);
      VWSUBU_WV      : d = R(SRC_VP , SRC_VP , SRC_VP , FU_VIALUF   , VIALU_vwsubu_wv     , SELIMM_X    , SPLIT_VEC_WVW       , VWEN);
      // Zvbb
      VBREV_V        : d = R(SRC_NO , SRC_VP , SRC_VP , FU_VIALUF   , VIALU_vbrev_v       , SELIMM_X    , SPLIT_VEC_VVV       , VWEN);
      VBREV8_V       : d = R(SRC_NO , SRC_VP , SRC_VP , FU_VIALUF   , VIALU_vbrev8_v      , SELIMM_X    , SPLIT_VEC_VVV       , VWEN);
      VREV8_V        : d = R(SRC_NO , SRC_VP , SRC_VP , FU_VIALUF   , VIALU_vrev8_v       , SELIMM_X    , SPLIT_VEC_VVV       , VWEN);
      VCLZ_V         : d = R(SRC_NO , SRC_VP , SRC_VP , FU_VIALUF   , VIALU_vclz_v        , SELIMM_X    , SPLIT_VEC_VVV       , VWEN);
      VCTZ_V         : d = R(SRC_NO , SRC_VP , SRC_VP , FU_VIALUF   , VIALU_vctz_v        , SELIMM_X    , SPLIT_VEC_VVV       , VWEN);
      VCPOP_V        : d = R(SRC_NO , SRC_VP , SRC_VP , FU_VIALUF   , VIALU_vcpop_v       , SELIMM_X    , SPLIT_VEC_VVV       , VWEN);

      // ======== VecDecoder.opmvx ========
      VAADD_VX       : d = R(SRC_XP , SRC_VP , SRC_VP , FU_VIALUF   , VIALU_vaadd_vv      , SELIMM_X    , SPLIT_VEC_VXV       , VWEN);
      VAADDU_VX      : d = R(SRC_XP , SRC_VP , SRC_VP , FU_VIALUF   , VIALU_vaaddu_vv     , SELIMM_X    , SPLIT_VEC_VXV       , VWEN);
      VASUB_VX       : d = R(SRC_XP , SRC_VP , SRC_VP , FU_VIALUF   , VIALU_vasub_vv      , SELIMM_X    , SPLIT_VEC_VXV       , VWEN);
      VASUBU_VX      : d = R(SRC_XP , SRC_VP , SRC_VP , FU_VIALUF   , VIALU_vasubu_vv     , SELIMM_X    , SPLIT_VEC_VXV       , VWEN);
      VDIV_VX        : d = R(SRC_XP , SRC_VP , SRC_VP , FU_VIDIV    , VIDIV_vdiv          , SELIMM_X    , SPLIT_VEC_VXV       , VWEN);
      VDIVU_VX       : d = R(SRC_XP , SRC_VP , SRC_VP , FU_VIDIV    , VIDIV_vdivu         , SELIMM_X    , SPLIT_VEC_VXV       , VWEN);
      VMACC_VX       : d = R(SRC_XP , SRC_VP , SRC_VP , FU_VIMAC    , VIMAC_vmacc         , SELIMM_X    , SPLIT_VEC_VXV       , VWEN);
      VMADD_VX       : d = R(SRC_XP , SRC_VP , SRC_VP , FU_VIMAC    , VIMAC_vmadd         , SELIMM_X    , SPLIT_VEC_VXV       , VWEN);
      VMUL_VX        : d = R(SRC_XP , SRC_VP , SRC_VP , FU_VIMAC    , VIMAC_vmul          , SELIMM_X    , SPLIT_VEC_VXV       , VWEN);
      VMULH_VX       : d = R(SRC_XP , SRC_VP , SRC_VP , FU_VIMAC    , VIMAC_vmulh         , SELIMM_X    , SPLIT_VEC_VXV       , VWEN);
      VMULHSU_VX     : d = R(SRC_XP , SRC_VP , SRC_VP , FU_VIMAC    , VIMAC_vmulhsu       , SELIMM_X    , SPLIT_VEC_VXV       , VWEN);
      VMULHU_VX      : d = R(SRC_XP , SRC_VP , SRC_VP , FU_VIMAC    , VIMAC_vmulhu        , SELIMM_X    , SPLIT_VEC_VXV       , VWEN);
      VMV_S_X        : d = R(SRC_XP , SRC_NO , SRC_VP , FU_VIALUF   , VIALU_vmv_s_x       , SELIMM_X    , SPLIT_VEC_0XV       , VWEN);  // vmv.s.x vd, rs1 # vd[0] = x[rs1] (vs2=0)
      VNMSAC_VX      : d = R(SRC_XP , SRC_VP , SRC_VP , FU_VIMAC    , VIMAC_vnmsac        , SELIMM_X    , SPLIT_VEC_VXV       , VWEN);
      VNMSUB_VX      : d = R(SRC_XP , SRC_VP , SRC_VP , FU_VIMAC    , VIMAC_vnmsub        , SELIMM_X    , SPLIT_VEC_VXV       , VWEN);
      VREM_VX        : d = R(SRC_XP , SRC_VP , SRC_VP , FU_VIDIV    , VIDIV_vrem          , SELIMM_X    , SPLIT_VEC_VXV       , VWEN);
      VREMU_VX       : d = R(SRC_XP , SRC_VP , SRC_VP , FU_VIDIV    , VIDIV_vremu         , SELIMM_X    , SPLIT_VEC_VXV       , VWEN);
      VSLIDE1DOWN_VX : d = R(SRC_XP , SRC_VP , SRC_VP , FU_VPPU     , VPERM_vslide1down   , SELIMM_X    , SPLIT_VEC_SLIDE1DOWN, VWEN);
      VSLIDE1UP_VX   : d = R(SRC_XP , SRC_VP , SRC_VP , FU_VPPU     , VPERM_vslide1up     , SELIMM_X    , SPLIT_VEC_SLIDE1UP  , VWEN);
      VWADD_VX       : d = R(SRC_XP , SRC_VP , SRC_VP , FU_VIALUF   , VIALU_vwadd_vv      , SELIMM_X    , SPLIT_VEC_VXW       , VWEN);
      VWADD_WX       : d = R(SRC_XP , SRC_VP , SRC_VP , FU_VIALUF   , VIALU_vwadd_wv      , SELIMM_X    , SPLIT_VEC_WXW       , VWEN);
      VWADDU_VX      : d = R(SRC_XP , SRC_VP , SRC_VP , FU_VIALUF   , VIALU_vwaddu_vv     , SELIMM_X    , SPLIT_VEC_VXW       , VWEN);
      VWADDU_WX      : d = R(SRC_XP , SRC_VP , SRC_VP , FU_VIALUF   , VIALU_vwaddu_wv     , SELIMM_X    , SPLIT_VEC_WXW       , VWEN);
      // OutOfMemoryError
      VWMACC_VX      : d = R(SRC_XP , SRC_VP , SRC_VP , FU_VIMAC    , VIMAC_vwmacc        , SELIMM_X    , SPLIT_VEC_VXW       , VWEN);
      VWMACCSU_VX    : d = R(SRC_XP , SRC_VP , SRC_VP , FU_VIMAC    , VIMAC_vwmaccsu      , SELIMM_X    , SPLIT_VEC_VXW       , VWEN);
      VWMACCU_VX     : d = R(SRC_XP , SRC_VP , SRC_VP , FU_VIMAC    , VIMAC_vwmaccu       , SELIMM_X    , SPLIT_VEC_VXW       , VWEN);
      VWMACCUS_VX    : d = R(SRC_XP , SRC_VP , SRC_VP , FU_VIMAC    , VIMAC_vwmaccus      , SELIMM_X    , SPLIT_VEC_VXW       , VWEN);
      VWMUL_VX       : d = R(SRC_XP , SRC_VP , SRC_VP , FU_VIMAC    , VIMAC_vwmul         , SELIMM_X    , SPLIT_VEC_VXW       , VWEN);
      VWMULSU_VX     : d = R(SRC_XP , SRC_VP , SRC_VP , FU_VIMAC    , VIMAC_vwmulsu       , SELIMM_X    , SPLIT_VEC_VXW       , VWEN);
      // Ok
      VWMULU_VX      : d = R(SRC_XP , SRC_VP , SRC_VP , FU_VIMAC    , VIMAC_vwmulu        , SELIMM_X    , SPLIT_VEC_VXW       , VWEN);
      VWSUB_VX       : d = R(SRC_XP , SRC_VP , SRC_VP , FU_VIALUF   , VIALU_vwsub_vv      , SELIMM_X    , SPLIT_VEC_VXW       , VWEN);
      VWSUB_WX       : d = R(SRC_XP , SRC_VP , SRC_VP , FU_VIALUF   , VIALU_vwsub_wv      , SELIMM_X    , SPLIT_VEC_WXW       , VWEN);
      VWSUBU_VX      : d = R(SRC_XP , SRC_VP , SRC_VP , FU_VIALUF   , VIALU_vwsubu_vv     , SELIMM_X    , SPLIT_VEC_VXW       , VWEN);
      VWSUBU_WX      : d = R(SRC_XP , SRC_VP , SRC_VP , FU_VIALUF   , VIALU_vwsubu_wv     , SELIMM_X    , SPLIT_VEC_WXW       , VWEN);

      // ======== VecDecoder.opfvv ========
      // 13.2. Vector Single-Width Floating-Point Add/Subtract Instructions
      VFADD_VV       : d = R(SRC_VP , SRC_VP , SRC_VP , FU_VFALU    , VFALU_vfadd         , SELIMM_X    , SPLIT_VEC_VVV       , VWEN);
      VFSUB_VV       : d = R(SRC_VP , SRC_VP , SRC_VP , FU_VFALU    , VFALU_vfsub         , SELIMM_X    , SPLIT_VEC_VVV       , VWEN);
      // 13.3. Vector Widening Floating-Point Add/Subtract Instructions
      VFWADD_VV      : d = R(SRC_VP , SRC_VP , SRC_VP , FU_VFALU    , VFALU_vfwadd        , SELIMM_X    , SPLIT_VEC_VVW       , VWEN);
      VFWSUB_VV      : d = R(SRC_VP , SRC_VP , SRC_VP , FU_VFALU    , VFALU_vfwsub        , SELIMM_X    , SPLIT_VEC_VVW       , VWEN);
      VFWADD_WV      : d = R(SRC_VP , SRC_VP , SRC_VP , FU_VFALU    , VFALU_vfwadd_w      , SELIMM_X    , SPLIT_VEC_WVW       , VWEN);
      VFWSUB_WV      : d = R(SRC_VP , SRC_VP , SRC_VP , FU_VFALU    , VFALU_vfwsub_w      , SELIMM_X    , SPLIT_VEC_WVW       , VWEN);
      // 13.4. Vector Single-Width Floating-Point Multiply/Divide Instructions
      VFMUL_VV       : d = R(SRC_VP , SRC_VP , SRC_VP , FU_VFMA     , VFMA_vfmul          , SELIMM_X    , SPLIT_VEC_VVV       , VWEN);
      VFDIV_VV       : d = R(SRC_VP , SRC_VP , SRC_VP , FU_VFDIV    , VFDIV_vfdiv         , SELIMM_X    , SPLIT_VEC_VVV       , VWEN);
      // 13.5. Vector Widening Floating-Point Multiply
      VFWMUL_VV      : d = R(SRC_VP , SRC_VP , SRC_VP , FU_VFMA     , VFMA_vfmul_w        , SELIMM_X    , SPLIT_VEC_VVW       , VWEN);
      // 13.6. Vector Single-Width Floating-Point Fused Multiply-Add Instructions
      VFMACC_VV      : d = R(SRC_VP , SRC_VP , SRC_VP , FU_VFMA     , VFMA_vfmacc         , SELIMM_X    , SPLIT_VEC_VVV       , VWEN);
      VFNMACC_VV     : d = R(SRC_VP , SRC_VP , SRC_VP , FU_VFMA     , VFMA_vfnmacc        , SELIMM_X    , SPLIT_VEC_VVV       , VWEN);
      VFMSAC_VV      : d = R(SRC_VP , SRC_VP , SRC_VP , FU_VFMA     , VFMA_vfmsac         , SELIMM_X    , SPLIT_VEC_VVV       , VWEN);
      VFNMSAC_VV     : d = R(SRC_VP , SRC_VP , SRC_VP , FU_VFMA     , VFMA_vfnmsac        , SELIMM_X    , SPLIT_VEC_VVV       , VWEN);
      VFMADD_VV      : d = R(SRC_VP , SRC_VP , SRC_VP , FU_VFMA     , VFMA_vfmadd         , SELIMM_X    , SPLIT_VEC_VVV       , VWEN);
      VFNMADD_VV     : d = R(SRC_VP , SRC_VP , SRC_VP , FU_VFMA     , VFMA_vfnmadd        , SELIMM_X    , SPLIT_VEC_VVV       , VWEN);
      VFMSUB_VV      : d = R(SRC_VP , SRC_VP , SRC_VP , FU_VFMA     , VFMA_vfmsub         , SELIMM_X    , SPLIT_VEC_VVV       , VWEN);
      VFNMSUB_VV     : d = R(SRC_VP , SRC_VP , SRC_VP , FU_VFMA     , VFMA_vfnmsub        , SELIMM_X    , SPLIT_VEC_VVV       , VWEN);
      // 13.7. Vector Widening Floating-Point Fused Multiply-Add Instructions
      VFWMACC_VV     : d = R(SRC_VP , SRC_VP , SRC_VP , FU_VFMA     , VFMA_vfmacc_w       , SELIMM_X    , SPLIT_VEC_VVW       , VWEN);
      VFWNMACC_VV    : d = R(SRC_VP , SRC_VP , SRC_VP , FU_VFMA     , VFMA_vfnmacc_w      , SELIMM_X    , SPLIT_VEC_VVW       , VWEN);
      VFWMSAC_VV     : d = R(SRC_VP , SRC_VP , SRC_VP , FU_VFMA     , VFMA_vfmsac_w       , SELIMM_X    , SPLIT_VEC_VVW       , VWEN);
      VFWNMSAC_VV    : d = R(SRC_VP , SRC_VP , SRC_VP , FU_VFMA     , VFMA_vfnmsac_w      , SELIMM_X    , SPLIT_VEC_VVW       , VWEN);
      // 13.8. Vector Floating-Point Square-Root Instruction
      VFSQRT_V       : d = R(SRC_X  , SRC_VP , SRC_VP , FU_VFDIV    , VFDIV_vfsqrt        , SELIMM_X    , SPLIT_VEC_VVV       , VWEN);  // vfsqrt.v vd, vs2, vm
      // 13.9. Vector Floating-Point Reciprocal Square-Root Estimate Instruction
      VFRSQRT7_V     : d = R(SRC_X  , SRC_VP , SRC_VP , FU_VFCVT    , VFCVT_vfrsqrt7      , SELIMM_X    , SPLIT_VEC_VVV       , VWEN);  // vfrsqrt7.v vd, vs2, vm
      // 13.10. Vector Floating-Point Reciprocal Estimate Instruction
      VFREC7_V       : d = R(SRC_X  , SRC_VP , SRC_VP , FU_VFCVT    , VFCVT_vfrec7        , SELIMM_X    , SPLIT_VEC_VVV       , VWEN);  // vfrec7.v vd, vs2, vm
      // 13.11. Vector Floating-Point MIN/MAX Instructions
      VFMIN_VV       : d = R(SRC_VP , SRC_VP , SRC_VP , FU_VFALU    , VFALU_vfmin         , SELIMM_X    , SPLIT_VEC_VVV       , VWEN);
      VFMAX_VV       : d = R(SRC_VP , SRC_VP , SRC_VP , FU_VFALU    , VFALU_vfmax         , SELIMM_X    , SPLIT_VEC_VVV       , VWEN);
      // 13.12. Vector Floating-Point Sign-Injection Instructions
      VFSGNJ_VV      : d = R(SRC_VP , SRC_VP , SRC_VP , FU_VFALU    , VFALU_vfsgnj        , SELIMM_X    , SPLIT_VEC_VVV       , VWEN);
      VFSGNJN_VV     : d = R(SRC_VP , SRC_VP , SRC_VP , FU_VFALU    , VFALU_vfsgnjn       , SELIMM_X    , SPLIT_VEC_VVV       , VWEN);
      VFSGNJX_VV     : d = R(SRC_VP , SRC_VP , SRC_VP , FU_VFALU    , VFALU_vfsgnjx       , SELIMM_X    , SPLIT_VEC_VVV       , VWEN);
      // 13.13. Vector Floating-Point Compare Instructions
      VMFEQ_VV       : d = R(SRC_VP , SRC_VP , SRC_VP , FU_VFALU    , VFALU_vfeq          , SELIMM_X    , SPLIT_VEC_VVM       , VWEN);
      VMFNE_VV       : d = R(SRC_VP , SRC_VP , SRC_VP , FU_VFALU    , VFALU_vfne          , SELIMM_X    , SPLIT_VEC_VVM       , VWEN);
      VMFLT_VV       : d = R(SRC_VP , SRC_VP , SRC_VP , FU_VFALU    , VFALU_vflt          , SELIMM_X    , SPLIT_VEC_VVM       , VWEN);
      VMFLE_VV       : d = R(SRC_VP , SRC_VP , SRC_VP , FU_VFALU    , VFALU_vfle          , SELIMM_X    , SPLIT_VEC_VVM       , VWEN);
      // 13.14. Vector Floating-Point Classify Instruction
      VFCLASS_V      : d = R(SRC_X  , SRC_VP , SRC_VP , FU_VFALU    , VFALU_vfclass       , SELIMM_X    , SPLIT_VEC_VVV       , VWEN);
      // 13.17. Single-Width Floating-Point/Integer Type-Convert Instructions
      VFCVT_XU_F_V   : d = R(SRC_X  , SRC_VP , SRC_VP , FU_VFCVT    , VFCVT_vfcvt_xufv    , SELIMM_X    , SPLIT_VEC_VVV       , VWEN);
      VFCVT_X_F_V    : d = R(SRC_X  , SRC_VP , SRC_VP , FU_VFCVT    , VFCVT_vfcvt_xfv     , SELIMM_X    , SPLIT_VEC_VVV       , VWEN);
      VFCVT_RTZ_XU_F_V: d = R(SRC_X  , SRC_VP , SRC_VP , FU_VFCVT    , VFCVT_vfcvt_rtz_xufv, SELIMM_X    , SPLIT_VEC_VVV       , VWEN);
      VFCVT_RTZ_X_F_V: d = R(SRC_X  , SRC_VP , SRC_VP , FU_VFCVT    , VFCVT_vfcvt_rtz_xfv , SELIMM_X    , SPLIT_VEC_VVV       , VWEN);
      VFCVT_F_XU_V   : d = R(SRC_X  , SRC_VP , SRC_VP , FU_VFCVT    , VFCVT_vfcvt_fxuv    , SELIMM_X    , SPLIT_VEC_VVV       , VWEN);
      VFCVT_F_X_V    : d = R(SRC_X  , SRC_VP , SRC_VP , FU_VFCVT    , VFCVT_vfcvt_fxv     , SELIMM_X    , SPLIT_VEC_VVV       , VWEN);
      // 13.18. Widening Floating-Point/Integer Type-Convert Instructions
      VFWCVT_XU_F_V  : d = R(SRC_X  , SRC_VP , SRC_VP , FU_VFCVT    , VFCVT_vfwcvt_xufv   , SELIMM_X    , SPLIT_VEC_VVW       , VWEN);
      VFWCVT_X_F_V   : d = R(SRC_X  , SRC_VP , SRC_VP , FU_VFCVT    , VFCVT_vfwcvt_xfv    , SELIMM_X    , SPLIT_VEC_VVW       , VWEN);
      VFWCVT_RTZ_XU_F_V: d = R(SRC_X  , SRC_VP , SRC_VP , FU_VFCVT    , VFCVT_vfwcvt_rtz_xufv, SELIMM_X    , SPLIT_VEC_VVW       , VWEN);
      VFWCVT_RTZ_X_F_V: d = R(SRC_X  , SRC_VP , SRC_VP , FU_VFCVT    , VFCVT_vfwcvt_rtz_xfv, SELIMM_X    , SPLIT_VEC_VVW       , VWEN);
      VFWCVT_F_XU_V  : d = R(SRC_X  , SRC_VP , SRC_VP , FU_VFCVT    , VFCVT_vfwcvt_fxuv   , SELIMM_X    , SPLIT_VEC_VVW       , VWEN);
      VFWCVT_F_X_V   : d = R(SRC_X  , SRC_VP , SRC_VP , FU_VFCVT    , VFCVT_vfwcvt_fxv    , SELIMM_X    , SPLIT_VEC_VVW       , VWEN);
      VFWCVT_F_F_V   : d = R(SRC_X  , SRC_VP , SRC_VP , FU_VFCVT    , VFCVT_vfwcvt_ffv    , SELIMM_X    , SPLIT_VEC_VVW       , VWEN);
      // !
      // 13.19. Narrowing Floating-Point/Integer Type-Convert Instructions
      VFNCVT_XU_F_W  : d = R(SRC_X  , SRC_VP , SRC_VP , FU_VFCVT    , VFCVT_vfncvt_xufw   , SELIMM_X    , SPLIT_VEC_WVV       , VWEN);
      VFNCVT_X_F_W   : d = R(SRC_X  , SRC_VP , SRC_VP , FU_VFCVT    , VFCVT_vfncvt_xfw    , SELIMM_X    , SPLIT_VEC_WVV       , VWEN);
      VFNCVT_RTZ_XU_F_W: d = R(SRC_X  , SRC_VP , SRC_VP , FU_VFCVT    , VFCVT_vfncvt_rtz_xufw, SELIMM_X    , SPLIT_VEC_WVV       , VWEN);
      VFNCVT_RTZ_X_F_W: d = R(SRC_X  , SRC_VP , SRC_VP , FU_VFCVT    , VFCVT_vfncvt_rtz_xfw, SELIMM_X    , SPLIT_VEC_WVV       , VWEN);
      VFNCVT_F_XU_W  : d = R(SRC_X  , SRC_VP , SRC_VP , FU_VFCVT    , VFCVT_vfncvt_fxuw   , SELIMM_X    , SPLIT_VEC_WVV       , VWEN);
      VFNCVT_F_X_W   : d = R(SRC_X  , SRC_VP , SRC_VP , FU_VFCVT    , VFCVT_vfncvt_fxw    , SELIMM_X    , SPLIT_VEC_WVV       , VWEN);
      VFNCVT_F_F_W   : d = R(SRC_X  , SRC_VP , SRC_VP , FU_VFCVT    , VFCVT_vfncvt_ffw    , SELIMM_X    , SPLIT_VEC_WVV       , VWEN);
      VFNCVT_ROD_F_F_W: d = R(SRC_X  , SRC_VP , SRC_VP , FU_VFCVT    , VFCVT_vfncvt_rod_ffw, SELIMM_X    , SPLIT_VEC_WVV       , VWEN);
      // 14.3. Vector Single-Width Floating-Point Reduction Instructions
      VFREDOSUM_VS   : d = R(SRC_VP , SRC_VP , SRC_VP , FU_VFALU    , VFALU_vfredosum     , SELIMM_X    , SPLIT_VEC_VFREDOSUM , VWEN);
      VFREDUSUM_VS   : d = R(SRC_VP , SRC_VP , SRC_VP , FU_VFALU    , VFALU_vfredusum     , SELIMM_X    , SPLIT_VEC_VFRED     , VWEN);
      VFREDMAX_VS    : d = R(SRC_VP , SRC_VP , SRC_VP , FU_VFALU    , VFALU_vfredmax      , SELIMM_X    , SPLIT_VEC_VFRED     , VWEN);
      VFREDMIN_VS    : d = R(SRC_VP , SRC_VP , SRC_VP , FU_VFALU    , VFALU_vfredmin      , SELIMM_X    , SPLIT_VEC_VFRED     , VWEN);
      // 14.4. Vector Widening Floating-Point Reduction Instructions
      VFWREDOSUM_VS  : d = R(SRC_VP , SRC_VP , SRC_VP , FU_VFALU    , VFALU_vfwredosum    , SELIMM_X    , SPLIT_VEC_VFREDOSUM , VWEN);
      VFWREDUSUM_VS  : d = R(SRC_VP , SRC_VP , SRC_VP , FU_VFALU    , VFALU_vfwredosum    , SELIMM_X    , SPLIT_VEC_VFREDOSUM , VWEN);

      // ======== VecDecoder.opfvf ========
      // 13.2. Vector Single-Width Floating-Point Add/Subtract Instructions
      VFADD_VF       : d = R(SRC_FP , SRC_VP , SRC_VP , FU_VFALU    , VFALU_vfadd         , SELIMM_X    , SPLIT_VEC_VFV       , VWEN);
      VFSUB_VF       : d = R(SRC_FP , SRC_VP , SRC_VP , FU_VFALU    , VFPU_vfsub          , SELIMM_X    , SPLIT_VEC_VFV       , VWEN);
      VFRSUB_VF      : d = R(SRC_FP , SRC_VP , SRC_VP , FU_VFALU    , VFPU_vfsub          , SELIMM_X    , SPLIT_VEC_VFV       , VWEN);
      // 13.3. Vector Widening Floating-Point Add/Subtract Instructions
      VFWADD_VF      : d = R(SRC_FP , SRC_VP , SRC_VP , FU_VFALU    , VFALU_vfwadd        , SELIMM_X    , SPLIT_VEC_VFW       , VWEN);
      VFWSUB_VF      : d = R(SRC_FP , SRC_VP , SRC_VP , FU_VFALU    , VFALU_vfwsub        , SELIMM_X    , SPLIT_VEC_VFW       , VWEN);
      VFWADD_WF      : d = R(SRC_FP , SRC_VP , SRC_VP , FU_VFALU    , VFALU_vfwadd_w      , SELIMM_X    , SPLIT_VEC_WFW       , VWEN);
      VFWSUB_WF      : d = R(SRC_FP , SRC_VP , SRC_VP , FU_VFALU    , VFALU_vfwsub_w      , SELIMM_X    , SPLIT_VEC_WFW       , VWEN);
      // 13.4. Vector Single-Width Floating-Point Multiply/Divide Instructions
      VFMUL_VF       : d = R(SRC_FP , SRC_VP , SRC_VP , FU_VFMA     , VFMA_vfmul          , SELIMM_X    , SPLIT_VEC_VFV       , VWEN);
      VFDIV_VF       : d = R(SRC_FP , SRC_VP , SRC_VP , FU_VFDIV    , VFDIV_vfdiv         , SELIMM_X    , SPLIT_VEC_VFV       , VWEN);
      VFRDIV_VF      : d = R(SRC_FP , SRC_VP , SRC_VP , FU_VFDIV    , VFDIV_vfdiv         , SELIMM_X    , SPLIT_VEC_VFV       , VWEN);
      // 13.5. Vector Widening Floating-Point Multiply
      VFWMUL_VF      : d = R(SRC_FP , SRC_VP , SRC_VP , FU_VFMA     , VFMA_vfmul_w        , SELIMM_X    , SPLIT_VEC_VFW       , VWEN);
      // 13.6. Vector Single-Width Floating-Point Fused Multiply-Add Instructions
      VFMACC_VF      : d = R(SRC_FP , SRC_VP , SRC_VP , FU_VFMA     , VFMA_vfmacc         , SELIMM_X    , SPLIT_VEC_VFV       , VWEN);
      VFNMACC_VF     : d = R(SRC_FP , SRC_VP , SRC_VP , FU_VFMA     , VFMA_vfnmacc        , SELIMM_X    , SPLIT_VEC_VFV       , VWEN);
      VFMSAC_VF      : d = R(SRC_FP , SRC_VP , SRC_VP , FU_VFMA     , VFMA_vfmsac         , SELIMM_X    , SPLIT_VEC_VFV       , VWEN);
      VFNMSAC_VF     : d = R(SRC_FP , SRC_VP , SRC_VP , FU_VFMA     , VFMA_vfnmsac        , SELIMM_X    , SPLIT_VEC_VFV       , VWEN);
      VFMADD_VF      : d = R(SRC_FP , SRC_VP , SRC_VP , FU_VFMA     , VFMA_vfmadd         , SELIMM_X    , SPLIT_VEC_VFV       , VWEN);
      VFNMADD_VF     : d = R(SRC_FP , SRC_VP , SRC_VP , FU_VFMA     , VFMA_vfnmadd        , SELIMM_X    , SPLIT_VEC_VFV       , VWEN);
      VFMSUB_VF      : d = R(SRC_FP , SRC_VP , SRC_VP , FU_VFMA     , VFMA_vfmsub         , SELIMM_X    , SPLIT_VEC_VFV       , VWEN);
      VFNMSUB_VF     : d = R(SRC_FP , SRC_VP , SRC_VP , FU_VFMA     , VFMA_vfnmsub        , SELIMM_X    , SPLIT_VEC_VFV       , VWEN);
      // 13.7. Vector Widening Floating-Point Fused Multiply-Add Instructions
      VFWMACC_VF     : d = R(SRC_FP , SRC_VP , SRC_VP , FU_VFMA     , VFMA_vfmacc_w       , SELIMM_X    , SPLIT_VEC_VFW       , VWEN);
      VFWNMACC_VF    : d = R(SRC_FP , SRC_VP , SRC_VP , FU_VFMA     , VFMA_vfnmacc_w      , SELIMM_X    , SPLIT_VEC_VFW       , VWEN);
      VFWMSAC_VF     : d = R(SRC_FP , SRC_VP , SRC_VP , FU_VFMA     , VFMA_vfmsac_w       , SELIMM_X    , SPLIT_VEC_VFW       , VWEN);
      VFWNMSAC_VF    : d = R(SRC_FP , SRC_VP , SRC_VP , FU_VFMA     , VFMA_vfnmsac_w      , SELIMM_X    , SPLIT_VEC_VFW       , VWEN);
      // 13.11. Vector Floating-Point MIN/MAX Instructions
      VFMIN_VF       : d = R(SRC_FP , SRC_VP , SRC_VP , FU_VFALU    , VFALU_vfmin         , SELIMM_X    , SPLIT_VEC_VFV       , VWEN);
      VFMAX_VF       : d = R(SRC_FP , SRC_VP , SRC_VP , FU_VFALU    , VFALU_vfmax         , SELIMM_X    , SPLIT_VEC_VFV       , VWEN);
      // 13.12. Vector Floating-Point Sign-Injection Instructions
      VFSGNJ_VF      : d = R(SRC_FP , SRC_VP , SRC_VP , FU_VFALU    , VFPU_vfsgnj         , SELIMM_X    , SPLIT_VEC_VFV       , VWEN);
      VFSGNJN_VF     : d = R(SRC_FP , SRC_VP , SRC_VP , FU_VFALU    , VFPU_vfsgnjn        , SELIMM_X    , SPLIT_VEC_VFV       , VWEN);
      VFSGNJX_VF     : d = R(SRC_FP , SRC_VP , SRC_VP , FU_VFALU    , VFPU_vfsgnjx        , SELIMM_X    , SPLIT_VEC_VFV       , VWEN);
      // 13.13. Vector Floating-Point Compare Instructions
      VMFEQ_VF       : d = R(SRC_FP , SRC_VP , SRC_VP , FU_VFALU    , VFALU_vfeq          , SELIMM_X    , SPLIT_VEC_VFM       , VWEN);
      VMFNE_VF       : d = R(SRC_FP , SRC_VP , SRC_VP , FU_VFALU    , VFALU_vfne          , SELIMM_X    , SPLIT_VEC_VFM       , VWEN);
      VMFLT_VF       : d = R(SRC_FP , SRC_VP , SRC_VP , FU_VFALU    , VFALU_vflt          , SELIMM_X    , SPLIT_VEC_VFM       , VWEN);
      VMFLE_VF       : d = R(SRC_FP , SRC_VP , SRC_VP , FU_VFALU    , VFALU_vfle          , SELIMM_X    , SPLIT_VEC_VFM       , VWEN);
      VMFGT_VF       : d = R(SRC_FP , SRC_VP , SRC_VP , FU_VFALU    , VFALU_vfgt          , SELIMM_X    , SPLIT_VEC_VFM       , VWEN);
      VMFGE_VF       : d = R(SRC_FP , SRC_VP , SRC_VP , FU_VFALU    , VFALU_vfge          , SELIMM_X    , SPLIT_VEC_VFM       , VWEN);
      // 13.15. Vector Floating-Point Merge Instruction
      VFMERGE_VFM    : d = R(SRC_FP , SRC_VP , SRC_VP , FU_VFALU    , VFALU_vfmerge       , SELIMM_X    , SPLIT_VEC_VFV       , VWEN);
      // 13.16. Vector Floating-Point Move Instruction
      VFMV_V_F       : d = R(SRC_FP , SRC_X  , SRC_VP , FU_VFALU    , VFALU_vfmv          , SELIMM_X    , SPLIT_VEC_VFV       , VWEN);  // vfmv.v.f vd, rs1 # vd[i] = f[rs1]
      // 16.2. Floating-Point Scalar Move Instructions
      VFMV_F_S       : d = R(SRC_X  , SRC_VP , SRC_X  , FU_VFALU    , VFALU_vfmv_f_s      , SELIMM_X    , SPLIT_DUMMY         , FWEN);  // f[rd] = vs2[0] (rs1=0)
      VFMV_S_F       : d = R(SRC_FP , SRC_X  , SRC_X  , FU_VFALU    , VFALU_vfmv_s_f      , SELIMM_X    , SPLIT_VEC_0XV       , VWEN);  // vd[0] = f[rs1] (vs2=0)
      // 16.3.3. Vector Slide1up
      VFSLIDE1UP_VF  : d = R(SRC_FP , SRC_VP , SRC_VP , FU_VPPU     , VPERM_vfslide1up    , SELIMM_X    , SPLIT_VEC_FSLIDE1UP , VWEN);  // vd[0]=f[rs1], vd[i+1] = vs2[i]
      // 16.3.4. Vector Slide1down Instruction
      // vslide1down.vx vd, vs2, rs1, vm # vd[i] = vs2[i+1], vd[vl-1]=x[rs1]
      VFSLIDE1DOWN_VF: d = R(SRC_FP , SRC_VP , SRC_VP , FU_VPPU     , VPERM_vfslide1down  , SELIMM_X    , SPLIT_VEC_FSLIDE1DOWN, VWEN);  // vd[i] = vs2[i+1], vd[vl-1]=f[rs1]

      // ======== VecDecoder.opfff ========
      // Scalar Float Point
      FADD_S         : d = R(SRC_FP , SRC_FP , SRC_X  , FU_FALU     , VFALU_vfadd         , SELIMM_X    , SPLIT_SCA_SIM       , FWEN | ROBCOMP);
      FADD_D         : d = R(SRC_FP , SRC_FP , SRC_X  , FU_FALU     , VFALU_vfadd         , SELIMM_X    , SPLIT_SCA_SIM       , FWEN | ROBCOMP);
      FADD_H         : d = R(SRC_FP , SRC_FP , SRC_X  , FU_FALU     , VFALU_vfadd         , SELIMM_X    , SPLIT_SCA_SIM       , FWEN | ROBCOMP);
      FSUB_S         : d = R(SRC_FP , SRC_FP , SRC_X  , FU_FALU     , VFALU_vfsub         , SELIMM_X    , SPLIT_SCA_SIM       , FWEN | ROBCOMP);
      FSUB_D         : d = R(SRC_FP , SRC_FP , SRC_X  , FU_FALU     , VFALU_vfsub         , SELIMM_X    , SPLIT_SCA_SIM       , FWEN | ROBCOMP);
      FSUB_H         : d = R(SRC_FP , SRC_FP , SRC_X  , FU_FALU     , VFALU_vfsub         , SELIMM_X    , SPLIT_SCA_SIM       , FWEN | ROBCOMP);
      FEQ_S          : d = R(SRC_FP , SRC_FP , SRC_X  , FU_FALU     , VFALU_vfeq          , SELIMM_X    , SPLIT_SCA_SIM       , XWEN | ROBCOMP);
      FLT_S          : d = R(SRC_FP , SRC_FP , SRC_X  , FU_FALU     , VFALU_vflt          , SELIMM_X    , SPLIT_SCA_SIM       , XWEN | ROBCOMP);
      FLE_S          : d = R(SRC_FP , SRC_FP , SRC_X  , FU_FALU     , VFALU_vfle          , SELIMM_X    , SPLIT_SCA_SIM       , XWEN | ROBCOMP);
      FEQ_D          : d = R(SRC_FP , SRC_FP , SRC_X  , FU_FALU     , VFALU_vfeq          , SELIMM_X    , SPLIT_SCA_SIM       , XWEN | ROBCOMP);
      FLT_D          : d = R(SRC_FP , SRC_FP , SRC_X  , FU_FALU     , VFALU_vflt          , SELIMM_X    , SPLIT_SCA_SIM       , XWEN | ROBCOMP);
      FLE_D          : d = R(SRC_FP , SRC_FP , SRC_X  , FU_FALU     , VFALU_vfle          , SELIMM_X    , SPLIT_SCA_SIM       , XWEN | ROBCOMP);
      FEQ_H          : d = R(SRC_FP , SRC_FP , SRC_X  , FU_FALU     , VFALU_vfeq          , SELIMM_X    , SPLIT_SCA_SIM       , XWEN | ROBCOMP);
      FLT_H          : d = R(SRC_FP , SRC_FP , SRC_X  , FU_FALU     , VFALU_vflt          , SELIMM_X    , SPLIT_SCA_SIM       , XWEN | ROBCOMP);
      FLE_H          : d = R(SRC_FP , SRC_FP , SRC_X  , FU_FALU     , VFALU_vfle          , SELIMM_X    , SPLIT_SCA_SIM       , XWEN | ROBCOMP);
      FMIN_S         : d = R(SRC_FP , SRC_FP , SRC_X  , FU_FALU     , VFALU_vfmin         , SELIMM_X    , SPLIT_SCA_SIM       , FWEN | ROBCOMP);
      FMIN_D         : d = R(SRC_FP , SRC_FP , SRC_X  , FU_FALU     , VFALU_vfmin         , SELIMM_X    , SPLIT_SCA_SIM       , FWEN | ROBCOMP);
      FMAX_S         : d = R(SRC_FP , SRC_FP , SRC_X  , FU_FALU     , VFALU_vfmax         , SELIMM_X    , SPLIT_SCA_SIM       , FWEN | ROBCOMP);
      FMAX_D         : d = R(SRC_FP , SRC_FP , SRC_X  , FU_FALU     , VFALU_vfmax         , SELIMM_X    , SPLIT_SCA_SIM       , FWEN | ROBCOMP);
      FMIN_H         : d = R(SRC_FP , SRC_FP , SRC_X  , FU_FALU     , VFALU_vfmin         , SELIMM_X    , SPLIT_SCA_SIM       , FWEN | ROBCOMP);
      FMAX_H         : d = R(SRC_FP , SRC_FP , SRC_X  , FU_FALU     , VFALU_vfmax         , SELIMM_X    , SPLIT_SCA_SIM       , FWEN | ROBCOMP);
      // Scalar Float Point Convert Inst.
      FCVT_W_S       : d = R(SRC_FP , SRC_X  , SRC_X  , FU_FCVT     , VFCVT_vfcvt_xfv     , SELIMM_X    , SPLIT_SCA_SIM       , XWEN | ROBCOMP);
      FCVT_WU_S      : d = R(SRC_FP , SRC_X  , SRC_X  , FU_FCVT     , VFCVT_vfcvt_xufv    , SELIMM_X    , SPLIT_SCA_SIM       , XWEN | ROBCOMP);
      FCVT_L_S       : d = R(SRC_FP , SRC_X  , SRC_X  , FU_FCVT     , VFCVT_vfwcvt_xfv    , SELIMM_X    , SPLIT_SCA_SIM       , XWEN | ROBCOMP);
      FCVT_LU_S      : d = R(SRC_FP , SRC_X  , SRC_X  , FU_FCVT     , VFCVT_vfwcvt_xufv   , SELIMM_X    , SPLIT_SCA_SIM       , XWEN | ROBCOMP);
      FCVT_W_D       : d = R(SRC_FP , SRC_X  , SRC_X  , FU_FCVT     , VFCVT_vfncvt_xfw    , SELIMM_X    , SPLIT_SCA_SIM       , XWEN | ROBCOMP);
      FCVT_WU_D      : d = R(SRC_FP , SRC_X  , SRC_X  , FU_FCVT     , VFCVT_vfncvt_xufw   , SELIMM_X    , SPLIT_SCA_SIM       , XWEN | ROBCOMP);
      FCVT_L_D       : d = R(SRC_FP , SRC_X  , SRC_X  , FU_FCVT     , VFCVT_vfcvt_xfv     , SELIMM_X    , SPLIT_SCA_SIM       , XWEN | ROBCOMP);
      FCVT_LU_D      : d = R(SRC_FP , SRC_X  , SRC_X  , FU_FCVT     , VFCVT_vfcvt_xufv    , SELIMM_X    , SPLIT_SCA_SIM       , XWEN | ROBCOMP);
      FCVT_S_D       : d = R(SRC_FP , SRC_X  , SRC_X  , FU_FCVT     , VFCVT_vfncvt_ffw    , SELIMM_X    , SPLIT_SCA_SIM       , FWEN | ROBCOMP);
      FCVT_D_S       : d = R(SRC_FP , SRC_X  , SRC_X  , FU_FCVT     , VFCVT_vfwcvt_ffv    , SELIMM_X    , SPLIT_SCA_SIM       , FWEN | ROBCOMP);
      // Scala Half-Precision Float Convert Inst.
      FCVT_H_S       : d = R(SRC_FP , SRC_X  , SRC_X  , FU_FCVT     , VFCVT_fcvt_h_s      , SELIMM_X    , SPLIT_SCA_SIM       , FWEN | ROBCOMP);
      FCVT_S_H       : d = R(SRC_FP , SRC_X  , SRC_X  , FU_FCVT     , VFCVT_fcvt_s_h      , SELIMM_X    , SPLIT_SCA_SIM       , FWEN | ROBCOMP);
      FCVT_H_D       : d = R(SRC_FP , SRC_X  , SRC_X  , FU_FCVT     , VFCVT_fcvt_h_d      , SELIMM_X    , SPLIT_SCA_SIM       , FWEN | ROBCOMP);
      FCVT_D_H       : d = R(SRC_FP , SRC_X  , SRC_X  , FU_FCVT     , VFCVT_fcvt_d_h      , SELIMM_X    , SPLIT_SCA_SIM       , FWEN | ROBCOMP);
      FCVT_W_H       : d = R(SRC_FP , SRC_X  , SRC_X  , FU_FCVT     , VFCVT_fcvt_w_h      , SELIMM_X    , SPLIT_SCA_SIM       , XWEN | ROBCOMP);
      FCVT_WU_H      : d = R(SRC_FP , SRC_X  , SRC_X  , FU_FCVT     , VFCVT_fcvt_wu_h     , SELIMM_X    , SPLIT_SCA_SIM       , XWEN | ROBCOMP);
      FCVT_L_H       : d = R(SRC_FP , SRC_X  , SRC_X  , FU_FCVT     , VFCVT_fcvt_l_h      , SELIMM_X    , SPLIT_SCA_SIM       , XWEN | ROBCOMP);
      FCVT_LU_H      : d = R(SRC_FP , SRC_X  , SRC_X  , FU_FCVT     , VFCVT_fcvt_lu_h     , SELIMM_X    , SPLIT_SCA_SIM       , XWEN | ROBCOMP);
      // Scalar Float Point f2i MV Inst.
      FMV_X_D        : d = R(SRC_FP , SRC_X  , SRC_X  , FU_FCVT     , FUOP_FMVXF          , SELIMM_X    , SPLIT_SCA_SIM       , XWEN | ROBCOMP);
      FMV_X_W        : d = R(SRC_FP , SRC_X  , SRC_X  , FU_FCVT     , FUOP_FMVXF          , SELIMM_X    , SPLIT_SCA_SIM       , XWEN | ROBCOMP);
      FMV_X_H        : d = R(SRC_FP , SRC_X  , SRC_X  , FU_FCVT     , FUOP_FMVXF          , SELIMM_X    , SPLIT_SCA_SIM       , XWEN | ROBCOMP);
      // donot wflags
      FCLASS_S       : d = R(SRC_FP , SRC_X  , SRC_X  , FU_FALU     , VFALU_vfclass       , SELIMM_X    , SPLIT_SCA_SIM       , XWEN | ROBCOMP);
      FCLASS_D       : d = R(SRC_FP , SRC_X  , SRC_X  , FU_FALU     , VFALU_vfclass       , SELIMM_X    , SPLIT_SCA_SIM       , XWEN | ROBCOMP);
      FCLASS_H       : d = R(SRC_FP , SRC_X  , SRC_X  , FU_FALU     , VFALU_vfclass       , SELIMM_X    , SPLIT_SCA_SIM       , XWEN | ROBCOMP);
      FSGNJ_S        : d = R(SRC_FP , SRC_FP , SRC_X  , FU_FALU     , VFALU_vfsgnj        , SELIMM_X    , SPLIT_SCA_SIM       , FWEN | ROBCOMP);
      FSGNJ_D        : d = R(SRC_FP , SRC_FP , SRC_X  , FU_FALU     , VFALU_vfsgnj        , SELIMM_X    , SPLIT_SCA_SIM       , FWEN | ROBCOMP);
      FSGNJ_H        : d = R(SRC_FP , SRC_FP , SRC_X  , FU_FALU     , VFALU_vfsgnj        , SELIMM_X    , SPLIT_SCA_SIM       , FWEN | ROBCOMP);
      FSGNJX_S       : d = R(SRC_FP , SRC_FP , SRC_X  , FU_FALU     , VFALU_vfsgnjx       , SELIMM_X    , SPLIT_SCA_SIM       , FWEN | ROBCOMP);
      FSGNJX_D       : d = R(SRC_FP , SRC_FP , SRC_X  , FU_FALU     , VFALU_vfsgnjx       , SELIMM_X    , SPLIT_SCA_SIM       , FWEN | ROBCOMP);
      FSGNJX_H       : d = R(SRC_FP , SRC_FP , SRC_X  , FU_FALU     , VFALU_vfsgnjx       , SELIMM_X    , SPLIT_SCA_SIM       , FWEN | ROBCOMP);
      FSGNJN_S       : d = R(SRC_FP , SRC_FP , SRC_X  , FU_FALU     , VFALU_vfsgnjn       , SELIMM_X    , SPLIT_SCA_SIM       , FWEN | ROBCOMP);
      FSGNJN_D       : d = R(SRC_FP , SRC_FP , SRC_X  , FU_FALU     , VFALU_vfsgnjn       , SELIMM_X    , SPLIT_SCA_SIM       , FWEN | ROBCOMP);
      FSGNJN_H       : d = R(SRC_FP , SRC_FP , SRC_X  , FU_FALU     , VFALU_vfsgnjn       , SELIMM_X    , SPLIT_SCA_SIM       , FWEN | ROBCOMP);
      FMUL_S         : d = R(SRC_FP , SRC_FP , SRC_X  , FU_FMAC     , VFMA_vfmul          , SELIMM_X    , SPLIT_SCA_SIM       , FWEN | ROBCOMP);
      FMUL_D         : d = R(SRC_FP , SRC_FP , SRC_X  , FU_FMAC     , VFMA_vfmul          , SELIMM_X    , SPLIT_SCA_SIM       , FWEN | ROBCOMP);
      FMUL_H         : d = R(SRC_FP , SRC_FP , SRC_X  , FU_FMAC     , VFMA_vfmul          , SELIMM_X    , SPLIT_SCA_SIM       , FWEN | ROBCOMP);
      FDIV_S         : d = R(SRC_FP , SRC_FP , SRC_X  , FU_FDIVSQRT , VFDIV_vfdiv         , SELIMM_X    , SPLIT_SCA_SIM       , FWEN | ROBCOMP);
      FDIV_D         : d = R(SRC_FP , SRC_FP , SRC_X  , FU_FDIVSQRT , VFDIV_vfdiv         , SELIMM_X    , SPLIT_SCA_SIM       , FWEN | ROBCOMP);
      FDIV_H         : d = R(SRC_FP , SRC_FP , SRC_X  , FU_FDIVSQRT , VFDIV_vfdiv         , SELIMM_X    , SPLIT_SCA_SIM       , FWEN | ROBCOMP);
      FSQRT_S        : d = R(SRC_FP , SRC_FP , SRC_X  , FU_FDIVSQRT , VFDIV_vfsqrt        , SELIMM_X    , SPLIT_SCA_SIM       , FWEN | ROBCOMP);
      FSQRT_D        : d = R(SRC_FP , SRC_FP , SRC_X  , FU_FDIVSQRT , VFDIV_vfsqrt        , SELIMM_X    , SPLIT_SCA_SIM       , FWEN | ROBCOMP);
      FSQRT_H        : d = R(SRC_FP , SRC_FP , SRC_X  , FU_FDIVSQRT , VFDIV_vfsqrt        , SELIMM_X    , SPLIT_SCA_SIM       , FWEN | ROBCOMP);
      FMADD_S        : d = R(SRC_FP , SRC_FP , SRC_FP , FU_FMAC     , VFMA_vfmacc         , SELIMM_X    , SPLIT_SCA_SIM       , FWEN | ROBCOMP);
      FMSUB_S        : d = R(SRC_FP , SRC_FP , SRC_FP , FU_FMAC     , VFMA_vfmsac         , SELIMM_X    , SPLIT_SCA_SIM       , FWEN | ROBCOMP);
      FNMADD_S       : d = R(SRC_FP , SRC_FP , SRC_FP , FU_FMAC     , VFMA_vfnmacc        , SELIMM_X    , SPLIT_SCA_SIM       , FWEN | ROBCOMP);
      FNMSUB_S       : d = R(SRC_FP , SRC_FP , SRC_FP , FU_FMAC     , VFMA_vfnmsac        , SELIMM_X    , SPLIT_SCA_SIM       , FWEN | ROBCOMP);
      FMADD_D        : d = R(SRC_FP , SRC_FP , SRC_FP , FU_FMAC     , VFMA_vfmacc         , SELIMM_X    , SPLIT_SCA_SIM       , FWEN | ROBCOMP);
      FMSUB_D        : d = R(SRC_FP , SRC_FP , SRC_FP , FU_FMAC     , VFMA_vfmsac         , SELIMM_X    , SPLIT_SCA_SIM       , FWEN | ROBCOMP);
      FNMADD_D       : d = R(SRC_FP , SRC_FP , SRC_FP , FU_FMAC     , VFMA_vfnmacc        , SELIMM_X    , SPLIT_SCA_SIM       , FWEN | ROBCOMP);
      FNMSUB_D       : d = R(SRC_FP , SRC_FP , SRC_FP , FU_FMAC     , VFMA_vfnmsac        , SELIMM_X    , SPLIT_SCA_SIM       , FWEN | ROBCOMP);
      FMADD_H        : d = R(SRC_FP , SRC_FP , SRC_FP , FU_FMAC     , VFMA_vfmacc         , SELIMM_X    , SPLIT_SCA_SIM       , FWEN | ROBCOMP);
      FMSUB_H        : d = R(SRC_FP , SRC_FP , SRC_FP , FU_FMAC     , VFMA_vfmsac         , SELIMM_X    , SPLIT_SCA_SIM       , FWEN | ROBCOMP);
      FNMADD_H       : d = R(SRC_FP , SRC_FP , SRC_FP , FU_FMAC     , VFMA_vfnmacc        , SELIMM_X    , SPLIT_SCA_SIM       , FWEN | ROBCOMP);
      FNMSUB_H       : d = R(SRC_FP , SRC_FP , SRC_FP , FU_FMAC     , VFMA_vfnmsac        , SELIMM_X    , SPLIT_SCA_SIM       , FWEN | ROBCOMP);

      // ======== VecDecoder.vls ========
      // 7.4. Vector Unit-Stride Instructions
      VLE8_V         : d = R(SRC_XP , SRC_X  , SRC_VP , FU_VLDU     , VLDU_vle            , SELIMM_X    , SPLIT_VEC_US_LDST   , VWEN);
      VLE16_V        : d = R(SRC_XP , SRC_X  , SRC_VP , FU_VLDU     , VLDU_vle            , SELIMM_X    , SPLIT_VEC_US_LDST   , VWEN);
      VLE32_V        : d = R(SRC_XP , SRC_X  , SRC_VP , FU_VLDU     , VLDU_vle            , SELIMM_X    , SPLIT_VEC_US_LDST   , VWEN);
      VLE64_V        : d = R(SRC_XP , SRC_X  , SRC_VP , FU_VLDU     , VLDU_vle            , SELIMM_X    , SPLIT_VEC_US_LDST   , VWEN);
      VSE8_V         : d = R(SRC_XP , SRC_X  , SRC_VP , FU_VSTU     , VSTU_vse            , SELIMM_X    , SPLIT_VEC_US_LDST   , NOFLAG);
      VSE16_V        : d = R(SRC_XP , SRC_X  , SRC_VP , FU_VSTU     , VSTU_vse            , SELIMM_X    , SPLIT_VEC_US_LDST   , NOFLAG);
      VSE32_V        : d = R(SRC_XP , SRC_X  , SRC_VP , FU_VSTU     , VSTU_vse            , SELIMM_X    , SPLIT_VEC_US_LDST   , NOFLAG);
      VSE64_V        : d = R(SRC_XP , SRC_X  , SRC_VP , FU_VSTU     , VSTU_vse            , SELIMM_X    , SPLIT_VEC_US_LDST   , NOFLAG);
      VLM_V          : d = R(SRC_XP , SRC_X  , SRC_VP , FU_VLDU     , VLDU_vlm            , SELIMM_X    , SPLIT_VEC_US_LDST   , VWEN);
      VSM_V          : d = R(SRC_XP , SRC_X  , SRC_VP , FU_VSTU     , VSTU_vsm            , SELIMM_X    , SPLIT_VEC_US_LDST   , NOFLAG);
      // 7.5. Vector Strided Instructions
      VLSE8_V        : d = R(SRC_XP , SRC_XP , SRC_VP , FU_VLDU     , VLDU_vlse           , SELIMM_X    , SPLIT_VEC_S_LDST    , VWEN);
      VLSE16_V       : d = R(SRC_XP , SRC_XP , SRC_VP , FU_VLDU     , VLDU_vlse           , SELIMM_X    , SPLIT_VEC_S_LDST    , VWEN);
      VLSE32_V       : d = R(SRC_XP , SRC_XP , SRC_VP , FU_VLDU     , VLDU_vlse           , SELIMM_X    , SPLIT_VEC_S_LDST    , VWEN);
      VLSE64_V       : d = R(SRC_XP , SRC_XP , SRC_VP , FU_VLDU     , VLDU_vlse           , SELIMM_X    , SPLIT_VEC_S_LDST    , VWEN);
      VSSE8_V        : d = R(SRC_XP , SRC_XP , SRC_VP , FU_VSTU     , VSTU_vsse           , SELIMM_X    , SPLIT_VEC_S_LDST    , NOFLAG);
      VSSE16_V       : d = R(SRC_XP , SRC_XP , SRC_VP , FU_VSTU     , VSTU_vsse           , SELIMM_X    , SPLIT_VEC_S_LDST    , NOFLAG);
      VSSE32_V       : d = R(SRC_XP , SRC_XP , SRC_VP , FU_VSTU     , VSTU_vsse           , SELIMM_X    , SPLIT_VEC_S_LDST    , NOFLAG);
      VSSE64_V       : d = R(SRC_XP , SRC_XP , SRC_VP , FU_VSTU     , VSTU_vsse           , SELIMM_X    , SPLIT_VEC_S_LDST    , NOFLAG);
      // 7.6. Vector Indexed Instructions
      VLUXEI8_V      : d = R(SRC_XP , SRC_VP , SRC_VP , FU_VLDU     , VLDU_vluxe          , SELIMM_X    , SPLIT_VEC_I_LDST    , VWEN);
      VLUXEI16_V     : d = R(SRC_XP , SRC_VP , SRC_VP , FU_VLDU     , VLDU_vluxe          , SELIMM_X    , SPLIT_VEC_I_LDST    , VWEN);
      VLUXEI32_V     : d = R(SRC_XP , SRC_VP , SRC_VP , FU_VLDU     , VLDU_vluxe          , SELIMM_X    , SPLIT_VEC_I_LDST    , VWEN);
      VLUXEI64_V     : d = R(SRC_XP , SRC_VP , SRC_VP , FU_VLDU     , VLDU_vluxe          , SELIMM_X    , SPLIT_VEC_I_LDST    , VWEN);
      VLOXEI8_V      : d = R(SRC_XP , SRC_VP , SRC_VP , FU_VLDU     , VLDU_vloxe          , SELIMM_X    , SPLIT_VEC_I_LDST    , VWEN);
      VLOXEI16_V     : d = R(SRC_XP , SRC_VP , SRC_VP , FU_VLDU     , VLDU_vloxe          , SELIMM_X    , SPLIT_VEC_I_LDST    , VWEN);
      VLOXEI32_V     : d = R(SRC_XP , SRC_VP , SRC_VP , FU_VLDU     , VLDU_vloxe          , SELIMM_X    , SPLIT_VEC_I_LDST    , VWEN);
      VLOXEI64_V     : d = R(SRC_XP , SRC_VP , SRC_VP , FU_VLDU     , VLDU_vloxe          , SELIMM_X    , SPLIT_VEC_I_LDST    , VWEN);
      VSUXEI8_V      : d = R(SRC_XP , SRC_VP , SRC_VP , FU_VSTU     , VSTU_vsuxe          , SELIMM_X    , SPLIT_VEC_I_LDST    , NOFLAG);
      VSUXEI16_V     : d = R(SRC_XP , SRC_VP , SRC_VP , FU_VSTU     , VSTU_vsuxe          , SELIMM_X    , SPLIT_VEC_I_LDST    , NOFLAG);
      VSUXEI32_V     : d = R(SRC_XP , SRC_VP , SRC_VP , FU_VSTU     , VSTU_vsuxe          , SELIMM_X    , SPLIT_VEC_I_LDST    , NOFLAG);
      VSUXEI64_V     : d = R(SRC_XP , SRC_VP , SRC_VP , FU_VSTU     , VSTU_vsuxe          , SELIMM_X    , SPLIT_VEC_I_LDST    , NOFLAG);
      VSOXEI8_V      : d = R(SRC_XP , SRC_VP , SRC_VP , FU_VSTU     , VSTU_vsoxe          , SELIMM_X    , SPLIT_VEC_I_LDST    , NOFLAG);
      VSOXEI16_V     : d = R(SRC_XP , SRC_VP , SRC_VP , FU_VSTU     , VSTU_vsoxe          , SELIMM_X    , SPLIT_VEC_I_LDST    , NOFLAG);
      VSOXEI32_V     : d = R(SRC_XP , SRC_VP , SRC_VP , FU_VSTU     , VSTU_vsoxe          , SELIMM_X    , SPLIT_VEC_I_LDST    , NOFLAG);
      VSOXEI64_V     : d = R(SRC_XP , SRC_VP , SRC_VP , FU_VSTU     , VSTU_vsoxe          , SELIMM_X    , SPLIT_VEC_I_LDST    , NOFLAG);
      // 7.7. Unit-stride Fault-Only-First Loads
      VLE8FF_V       : d = R(SRC_XP , SRC_X  , SRC_VP , FU_VLDU     , VLDU_vleff          , SELIMM_X    , SPLIT_VEC_US_FF_LD  , VWEN);
      VLE16FF_V      : d = R(SRC_XP , SRC_X  , SRC_VP , FU_VLDU     , VLDU_vleff          , SELIMM_X    , SPLIT_VEC_US_FF_LD  , VWEN);
      VLE32FF_V      : d = R(SRC_XP , SRC_X  , SRC_VP , FU_VLDU     , VLDU_vleff          , SELIMM_X    , SPLIT_VEC_US_FF_LD  , VWEN);
      VLE64FF_V      : d = R(SRC_XP , SRC_X  , SRC_VP , FU_VLDU     , VLDU_vleff          , SELIMM_X    , SPLIT_VEC_US_FF_LD  , VWEN);
      // 7.8. Vector Load/Store Segment Instructions
      // 7.8.1. Vector Unit-Stride Segment Loads and Stores
      // TODO
      // 7.8.2. Vector Strided Segment Loads and Stores
      // TODO
      // 7.8.3. Vector Indexed Segment Loads and Stores
      // TODO
      // 7.9. Vector Load/Store Whole Register Instructions
      VL1RE8_V       : d = R(SRC_XP , SRC_X  , SRC_VP , FU_VLDU     , VLDU_vlr            , SELIMM_X    , SPLIT_VEC_US_LDST   , VWEN);
      VL1RE16_V      : d = R(SRC_XP , SRC_X  , SRC_VP , FU_VLDU     , VLDU_vlr            , SELIMM_X    , SPLIT_VEC_US_LDST   , VWEN);
      VL1RE32_V      : d = R(SRC_XP , SRC_X  , SRC_VP , FU_VLDU     , VLDU_vlr            , SELIMM_X    , SPLIT_VEC_US_LDST   , VWEN);
      VL1RE64_V      : d = R(SRC_XP , SRC_X  , SRC_VP , FU_VLDU     , VLDU_vlr            , SELIMM_X    , SPLIT_VEC_US_LDST   , VWEN);
      VL2RE8_V       : d = R(SRC_XP , SRC_X  , SRC_VP , FU_VLDU     , VLDU_vlr            , SELIMM_X    , SPLIT_VEC_US_LDST   , VWEN);
      VL2RE16_V      : d = R(SRC_XP , SRC_X  , SRC_VP , FU_VLDU     , VLDU_vlr            , SELIMM_X    , SPLIT_VEC_US_LDST   , VWEN);
      VL2RE32_V      : d = R(SRC_XP , SRC_X  , SRC_VP , FU_VLDU     , VLDU_vlr            , SELIMM_X    , SPLIT_VEC_US_LDST   , VWEN);
      VL2RE64_V      : d = R(SRC_XP , SRC_X  , SRC_VP , FU_VLDU     , VLDU_vlr            , SELIMM_X    , SPLIT_VEC_US_LDST   , VWEN);
      VL4RE8_V       : d = R(SRC_XP , SRC_X  , SRC_VP , FU_VLDU     , VLDU_vlr            , SELIMM_X    , SPLIT_VEC_US_LDST   , VWEN);
      VL4RE16_V      : d = R(SRC_XP , SRC_X  , SRC_VP , FU_VLDU     , VLDU_vlr            , SELIMM_X    , SPLIT_VEC_US_LDST   , VWEN);
      VL4RE32_V      : d = R(SRC_XP , SRC_X  , SRC_VP , FU_VLDU     , VLDU_vlr            , SELIMM_X    , SPLIT_VEC_US_LDST   , VWEN);
      VL4RE64_V      : d = R(SRC_XP , SRC_X  , SRC_VP , FU_VLDU     , VLDU_vlr            , SELIMM_X    , SPLIT_VEC_US_LDST   , VWEN);
      VL8RE8_V       : d = R(SRC_XP , SRC_X  , SRC_VP , FU_VLDU     , VLDU_vlr            , SELIMM_X    , SPLIT_VEC_US_LDST   , VWEN);
      VL8RE16_V      : d = R(SRC_XP , SRC_X  , SRC_VP , FU_VLDU     , VLDU_vlr            , SELIMM_X    , SPLIT_VEC_US_LDST   , VWEN);
      VL8RE32_V      : d = R(SRC_XP , SRC_X  , SRC_VP , FU_VLDU     , VLDU_vlr            , SELIMM_X    , SPLIT_VEC_US_LDST   , VWEN);
      VL8RE64_V      : d = R(SRC_XP , SRC_X  , SRC_VP , FU_VLDU     , VLDU_vlr            , SELIMM_X    , SPLIT_VEC_US_LDST   , VWEN);
      VS1R_V         : d = R(SRC_XP , SRC_X  , SRC_VP , FU_VSTU     , VSTU_vsr            , SELIMM_X    , SPLIT_VEC_US_LDST   , NOFLAG);
      VS2R_V         : d = R(SRC_XP , SRC_X  , SRC_VP , FU_VSTU     , VSTU_vsr            , SELIMM_X    , SPLIT_VEC_US_LDST   , NOFLAG);
      VS4R_V         : d = R(SRC_XP , SRC_X  , SRC_VP , FU_VSTU     , VSTU_vsr            , SELIMM_X    , SPLIT_VEC_US_LDST   , NOFLAG);
      VS8R_V         : d = R(SRC_XP , SRC_X  , SRC_VP , FU_VSTU     , VSTU_vsr            , SELIMM_X    , SPLIT_VEC_US_LDST   , NOFLAG);

      // ======== ZicondDecode ========
      CZERO_EQZ      : d = R(SRC_REG, SRC_REG, SRC_X  , FU_ALU      , ALU_czero_eqz       , SELIMM_X    , SPLIT_X             , XWEN | ROBCOMP);
      CZERO_NEZ      : d = R(SRC_REG, SRC_REG, SRC_X  , FU_ALU      , ALU_czero_nez       , SELIMM_X    , SPLIT_X             , XWEN | ROBCOMP);

      // ======== ZimopDecode ========
      // temp use addi to decode MOP_R and MOP_RR
      MOP_R          : d = R(SRC_REG, SRC_IMM, SRC_X  , FU_ALU      , ALU_add             , IMM_I       , SPLIT_X             , XWEN | ROBCOMP);
      MOP_RR         : d = R(SRC_REG, SRC_REG, SRC_X  , FU_ALU      , ALU_add             , IMM_I       , SPLIT_X             , XWEN | ROBCOMP);

      // ======== ZfaDecode ========
      FLI_H          : d = R(SRC_NO , SRC_X  , SRC_X  , FU_F2V      , OP_X                , SELIMM_X    , SPLIT_X             , FWEN | ROBCOMP);
      FLI_S          : d = R(SRC_NO , SRC_X  , SRC_X  , FU_F2V      , OP_X                , SELIMM_X    , SPLIT_X             , FWEN | ROBCOMP);
      FLI_D          : d = R(SRC_NO , SRC_X  , SRC_X  , FU_F2V      , OP_X                , SELIMM_X    , SPLIT_X             , FWEN | ROBCOMP);
      FMINM_H        : d = R(SRC_FP , SRC_FP , SRC_X  , FU_FALU     , VFALU_fminm         , SELIMM_X    , SPLIT_X             , FWEN | ROBCOMP);
      FMINM_S        : d = R(SRC_FP , SRC_FP , SRC_X  , FU_FALU     , VFALU_fminm         , SELIMM_X    , SPLIT_X             , FWEN | ROBCOMP);
      FMINM_D        : d = R(SRC_FP , SRC_FP , SRC_X  , FU_FALU     , VFALU_fminm         , SELIMM_X    , SPLIT_X             , FWEN | ROBCOMP);
      FMAXM_H        : d = R(SRC_FP , SRC_FP , SRC_X  , FU_FALU     , VFALU_fmaxm         , SELIMM_X    , SPLIT_X             , FWEN | ROBCOMP);
      FMAXM_S        : d = R(SRC_FP , SRC_FP , SRC_X  , FU_FALU     , VFALU_fmaxm         , SELIMM_X    , SPLIT_X             , FWEN | ROBCOMP);
      FMAXM_D        : d = R(SRC_FP , SRC_FP , SRC_X  , FU_FALU     , VFALU_fmaxm         , SELIMM_X    , SPLIT_X             , FWEN | ROBCOMP);
      FROUND_H       : d = R(SRC_FP , SRC_X  , SRC_X  , FU_FCVT     , VFCVT_fround        , SELIMM_X    , SPLIT_X             , FWEN | ROBCOMP);
      FROUND_S       : d = R(SRC_FP , SRC_X  , SRC_X  , FU_FCVT     , VFCVT_fround        , SELIMM_X    , SPLIT_X             , FWEN | ROBCOMP);
      FROUND_D       : d = R(SRC_FP , SRC_X  , SRC_X  , FU_FCVT     , VFCVT_fround        , SELIMM_X    , SPLIT_X             , FWEN | ROBCOMP);
      FROUNDNX_H     : d = R(SRC_FP , SRC_X  , SRC_X  , FU_FCVT     , VFCVT_froundnx      , SELIMM_X    , SPLIT_X             , FWEN | ROBCOMP);
      FROUNDNX_S     : d = R(SRC_FP , SRC_X  , SRC_X  , FU_FCVT     , VFCVT_froundnx      , SELIMM_X    , SPLIT_X             , FWEN | ROBCOMP);
      FROUNDNX_D     : d = R(SRC_FP , SRC_X  , SRC_X  , FU_FCVT     , VFCVT_froundnx      , SELIMM_X    , SPLIT_X             , FWEN | ROBCOMP);
      FCVTMOD_W_D    : d = R(SRC_FP , SRC_X  , SRC_X  , FU_FCVT     , VFCVT_fcvtmod_w_d   , SELIMM_X    , SPLIT_X             , XWEN | ROBCOMP);
      FLEQ_H         : d = R(SRC_FP , SRC_FP , SRC_X  , FU_FALU     , VFALU_fleq          , SELIMM_X    , SPLIT_X             , XWEN | ROBCOMP);
      FLEQ_S         : d = R(SRC_FP , SRC_FP , SRC_X  , FU_FALU     , VFALU_fleq          , SELIMM_X    , SPLIT_X             , XWEN | ROBCOMP);
      FLEQ_D         : d = R(SRC_FP , SRC_FP , SRC_X  , FU_FALU     , VFALU_fleq          , SELIMM_X    , SPLIT_X             , XWEN | ROBCOMP);
      FLTQ_H         : d = R(SRC_FP , SRC_FP , SRC_X  , FU_FALU     , VFALU_fltq          , SELIMM_X    , SPLIT_X             , XWEN | ROBCOMP);
      FLTQ_S         : d = R(SRC_FP , SRC_FP , SRC_X  , FU_FALU     , VFALU_fltq          , SELIMM_X    , SPLIT_X             , XWEN | ROBCOMP);
      FLTQ_D         : d = R(SRC_FP , SRC_FP , SRC_X  , FU_FALU     , VFALU_fltq          , SELIMM_X    , SPLIT_X             , XWEN | ROBCOMP);
  // END GENERATED(decode_table)
      default: d = ROW_INVALID;
    endcase
    tbl = d;
  end

  // ---------------------------------------------------------------------------
  // §4 指令形状判据（表之外，直接看指令字段）
  // ---------------------------------------------------------------------------
  logic isCsr, isCsrr, isCsrw, isCsrrVl, isCsrrVlenb;
  logic isZimop, isMove, isFMA;
  logic isCboClean, isCboFlush, isCboInval, isCboZero;
  logic isSoftPrefetch, isPreW, isPreR, isPreI, isPre;
  logic isFLI, isVls, isVecArith, isAmoCAS, isOPFVF, isOPFVV;

  // csrr rd, vl / csrr rd, vlenb：这两条 CSR 读在本核里被改写成 vsetvl / addi
  assign isCsr       = opcode5 == 5'b11100 && funct3[1:0] != 2'b00;   // SYSTEM 且不是 ecall/ebreak 类
  assign isCsrr      = isCsr && funct3[1] && rs1 == 5'd0;             // csrrs/csrrc(i) 且 rs1==x0 = 纯读
  assign isCsrw      = isCsr && funct3[1:0] == 2'b01 && rd == 5'd0;   // csrrw(i) 且 rd==x0 = 纯写（golden 未用）
  assign isCsrrVlenb = isCsrr && csridx == CSR_VLENB;
  assign isCsrrVl    = isCsrr && csridx == CSR_VL;

  always_comb begin
    isZimop = 1'b0; isMove = 1'b0;
    isCboClean = 1'b0; isCboFlush = 1'b0; isCboInval = 1'b0; isCboZero = 1'b0;
    casez (instr) MOP_R, MOP_RR: isZimop = 1'b1; default: ; endcase
    casez (instr) ISMOVE_ADDI0:  isMove  = 1'b1; default: ; endcase
    casez (instr)
      CBO_CLEAN: isCboClean = 1'b1;
      CBO_FLUSH: isCboFlush = 1'b1;
      CBO_INVAL: isCboInval = 1'b1;
      CBO_ZERO:  isCboZero  = 1'b1;
      default: ;
    endcase
  end

  // fmadd/fmsub/fnmsub/fnmadd：opcode = 100??11，第三个源是 fs3（否则是向量的旧 vd）
  assign isFMA = opcode[6:4] == 3'b100 && opcode[1:0] == 2'b11;

  // prefetch.{i,r,w} 是 ori x0, rs1, imm 的编码：rs2 字段 0/1/3 区分
  assign isSoftPrefetch = opcode == 7'b0010011 && funct3 == 3'b110 && rd == 5'd0;
  assign isPreW = isSoftPrefetch && rs2 == 5'd3;
  assign isPreR = isSoftPrefetch && rs2 == 5'd1;
  assign isPreI = isSoftPrefetch && rs2 == 5'd0;
  assign isPre  = isPreW || isPreR || isPreI;

  // fli.{h,s,d}：funct7 = 11110??，rs2 = 1，rm = 0，OP-FP
  assign isFLI = instr[31:27] == 5'b11110 && rs2 == 5'd1 && funct3 == 3'b000 && opcode5 == 5'b10100;

  // 向量访存 / 向量算术 / amocas（送 UopInfoGen 的 preInfo）
  assign isVls      = (opcode5 == 5'b01001 || opcode5 == 5'b00001) && (funct3 == 3'b000 || funct3[2]);  // STORE_FP/LOAD_FP 且 width 是向量宽度
  assign isVecArith = opcode5 == 5'b10101;                                // OP_V
  assign isAmoCAS   = opcode5 == 5'b01011 && instr[31:27] == 5'b00101;    // AMO 且 funct7 = 00101??
  assign isOPFVF    = opcode == 7'b1010111 && funct3 == 3'b101;
  assign isOPFVV    = opcode == 7'b1010111 && funct3 == 3'b001;

  // ---------------------------------------------------------------------------
  // §5 表外修正（Chisel 的 when 链，后面的分支只在前面都不成立时生效）
  //   csrr vl    -> 当成 vsetvl 处理：不读任何寄存器，只读 vconfig（src4 = vp）
  //   csrr vlenb -> 当成 addi rd, x0, VLEN/8：常数立即数，可 Rob 压缩
  //   prefetch   -> 走 load 单元，S 型立即数，不可 Rob 压缩
  //   zimop      -> 当成 addi rd, x0, 0（src1 = x0）
  // ---------------------------------------------------------------------------
  decode_row_t dec;            // 修正后的表行（Chisel 里就是 decodedInst 那根线的最终值）
  logic [3:0]  srcType3, srcType4;
  logic [5:0]  lsrc0;
  always_comb begin
    dec      = tbl;
    srcType3 = (vm == 1'b0) ? SRC_VP : SRC_DC;   // 掩码源 v0：vm=0 时才读
    srcType4 = SRC_VP;                            // vconfig 永远按向量寄存器读
    lsrc0    = {1'b0, rs1};
    if (isCsrrVl) begin
      dec.srcType0 = SRC_NO; dec.srcType1 = SRC_NO; dec.srcType2 = SRC_NO;
      srcType3 = SRC_NO; srcType4 = SRC_VP;
      dec.waitForward = 1'b0; dec.blockBackward = 1'b0;
    end else if (isCsrrVlenb) begin
      dec.srcType0 = SRC_REG; dec.srcType1 = SRC_IMM; dec.srcType2 = SRC_NO;
      srcType3 = SRC_NO; srcType4 = SRC_NO;
      dec.selImm = IMM_I;
      dec.waitForward = 1'b0; dec.blockBackward = 1'b0;
      dec.canRobCompress = 1'b1;
    end else if (isPre) begin
      dec.selImm = IMM_S;
      dec.fuType = FU_LDU;
      dec.canRobCompress = 1'b0;
    end else if (isZimop) begin
      dec.srcType0 = SRC_REG; dec.srcType1 = SRC_IMM;
      lsrc0 = 6'd0;                                 // 用 x0 做 src1
    end
  end

  // 常用的 fuType 谓词（都看修正后的 dec.fuType）
  logic isLs, isStore, isAMO, isVload, isVStore, isVlx, isVle, isVlm, isFof, isBranch;
  assign isLs     = dec.fuType[FUI_LDU] | dec.fuType[FUI_STU];
  assign isStore  = dec.fuType[FUI_STU];
  assign isAMO    = dec.fuType[FUI_MOU];
  assign isVload  = dec.fuType[FUI_VLDU] | dec.fuType[FUI_VSEGLDU];
  assign isVStore = dec.fuType[FUI_VSTU] | dec.fuType[FUI_VSEGSTU];
  assign isVlx    = isVload && (dec.fuOpType == VLDU_vloxe || dec.fuOpType == VLDU_vluxe);   // 索引 load
  assign isVle    = isVload && (dec.fuOpType == VLDU_vle || dec.fuOpType == VLDU_vleff || dec.fuOpType == VLDU_vlse);
  assign isVlm    = isVload && dec.fuOpType == VLDU_vlm;
  assign isFof    = isVload && dec.fuOpType == VLDU_vleff;                                   // fault-only-first
  assign isBranch = (enq.preDecodeInfo_brType != 2'b00) | dec.fuType[FUI_JMP];               // !notCFI || isJump

  // ---------------------------------------------------------------------------
  // §6 非法指令 / 虚拟指令判据（CSRToDecode 的标志按指令落地）
  // ---------------------------------------------------------------------------
  logic isHlv, isHlvx, isHsv;
  assign isHlv  = dec.fuOpType[4] && !dec.fuOpType[5] && dec.fuOpType[8:7] == 2'b00;
  assign isHlvx = isHlv && dec.fuOpType[3];
  assign isHsv  = isHlv;   // LSUOpType.isHsv 与 isHlv 是同一个位判据

  logic fuIsFence, fuIsLdu, fuIsStu, fuIsCsr, fuIsFpOP, fuIsVecAll, scalarLdStHalfToDouble;
  assign fuIsFence = dec.fuType[FUI_FENCE];
  assign fuIsLdu   = dec.fuType[FUI_LDU];
  assign fuIsStu   = dec.fuType[FUI_STU];
  assign fuIsCsr   = dec.fuType[FUI_CSR];
  // FuType.fpOP ++ Seq(f2v) = falu fmac fcvt fDivSqrt f2v i2f i2v
  assign fuIsFpOP  = dec.fuType[FUI_FALU] | dec.fuType[FUI_FMAC] | dec.fuType[FUI_FCVT] | dec.fuType[FUI_FDIVSQRT]
                   | dec.fuType[FUI_F2V]  | dec.fuType[FUI_I2F]  | dec.fuType[FUI_I2V];
  // FuType.vecAll = vset 三种 + 向量算术 10 种 + 向量访存 4 种
  assign fuIsVecAll = |dec.fuType[FUI_VSEGSTU:FUI_VIPU];
  // 浮点 load/store：flh/flw/fld/fsh/fsw/fsd（fuOpType 与整数版相同，靠 opcode 第 2 位区分）
  assign scalarLdStHalfToDouble =
      (fuIsLdu && (dec.fuOpType == LSU_lh || dec.fuOpType == LSU_lw || dec.fuOpType == LSU_ld))
   || (fuIsStu && (dec.fuOpType == LSU_sh || dec.fuOpType == LSU_sw || dec.fuOpType == LSU_sd));

  logic scalarNeedFrm, vectorNeedFrm;
  logic [2:0] fp_rm;                // FPDecoder 给的舍入模式（instr[14:12]，fli 等另说）
  assign scalarNeedFrm = is_scalar_need_frm_insn(instr)
                       | dec.fuType[FUI_I2F] | dec.fuType[FUI_FMAC] | dec.fuType[FUI_FDIVSQRT];
  assign vectorNeedFrm = is_vector_need_frm_insn(instr)
                       | dec.fuType[FUI_VFALU] | dec.fuType[FUI_VFMA] | dec.fuType[FUI_VFDIV] | dec.fuType[FUI_VFCVT];

  logic isAes64ks1iIllegal, isAmocasQIllegal;
  assign isAes64ks1iIllegal = dec.fuType[FUI_BKU] && dec.fuOpType == BKU_aes64ks1i && rnum > 4'hA;   // rnum 0xB..0xF 保留
  assign isAmocasQIllegal   = dec.fuType[FUI_MOU] && dec.fuOpType == LSU_amocas_q && (rd[0] || rs2[0]); // 寄存器对须偶数号

  logic exceptionII, exceptionVI;
  assign exceptionII =
      dec.selImm == INVALID_INSTR
   || from_csr.illegalInst_sfenceVMA  && fuIsFence && dec.fuOpType == FENCE_sfence
   || from_csr.illegalInst_sfencePart && fuIsFence && dec.fuOpType == FENCE_nofence
   || from_csr.illegalInst_hfenceGVMA && fuIsFence && dec.fuOpType == FENCE_hfence_g
   || from_csr.illegalInst_hfenceVVMA && fuIsFence && dec.fuOpType == FENCE_hfence_v
   || from_csr.illegalInst_hlsv       && fuIsLdu   && (isHlv || isHlvx)
   || from_csr.illegalInst_hlsv       && fuIsStu   && isHsv
   || from_csr.illegalInst_fsIsOff    && (fuIsFpOP || scalarLdStHalfToDouble && instr[2] || isOPFVF || isOPFVV)
   || from_csr.illegalInst_vsIsOff    && (fuIsVecAll || isCsrrVl || isCsrrVlenb)
   || from_csr.illegalInst_wfi        && fuIsCsr && dec.fuOpType[5] && !dec.fuOpType[1]               // CSROpType.isWfi
   || from_csr.illegalInst_wrs_nto    && fuIsCsr && dec.fuOpType[5] && dec.fuOpType[1:0] == 2'b10     // CSROpType.isWrsNto
   || scalarNeedFrm && (fp_rm == 3'd5 || fp_rm == 3'd6 || fp_rm == 3'd7 && from_csr.illegalInst_frm)  // rm 5/6 保留；rm=7(dyn) 看 frm
   || vectorNeedFrm && from_csr.illegalInst_frm
   || from_csr.illegalInst_cboZ  && isCboZero
   || from_csr.illegalInst_cboCF && (isCboClean || isCboFlush)
   || from_csr.illegalInst_cboI  && isCboInval
   || isAes64ks1iIllegal
   || isAmocasQIllegal;

  assign exceptionVI =
      from_csr.virtualInst_sfenceVMA  && fuIsFence && dec.fuOpType == FENCE_sfence
   || from_csr.virtualInst_sfencePart && fuIsFence && dec.fuOpType == FENCE_nofence
   || from_csr.virtualInst_hfence     && fuIsFence && (dec.fuOpType == FENCE_hfence_g || dec.fuOpType == FENCE_hfence_v)
   || from_csr.virtualInst_hlsv       && fuIsLdu   && (isHlv || isHlvx)
   || from_csr.virtualInst_hlsv       && fuIsStu   && isHsv
   || from_csr.virtualInst_wfi        && fuIsCsr && dec.fuOpType[5] && !dec.fuOpType[1]
   || from_csr.virtualInst_wrs_nto    && fuIsCsr && dec.fuOpType[5] && dec.fuOpType[1:0] == 2'b10
   || from_csr.virtualInst_cboZ  && isCboZero
   || from_csr.virtualInst_cboCF && (isCboClean || isCboFlush)
   || from_csr.virtualInst_cboI  && isCboInval;

  // ---------------------------------------------------------------------------
  // §7 立即数：按 selImm 从指令里抽最少位（ImmUnion.immSelMap），22 位 = 最长的 IMM_Z
  //   LookupTree 是 Mux1H：各格式零扩展后按 sel 相等条件 OR 起来
  // ---------------------------------------------------------------------------
  logic [21:0] imm_min;
  always_comb begin
    imm_min = '0;
    if (dec.selImm == IMM_I)        imm_min = imm_min | 22'(instr[31:20]);
    if (dec.selImm == IMM_S)        imm_min = imm_min | 22'({instr[31:25], instr[11:7]});
    if (dec.selImm == IMM_SB)       imm_min = imm_min | 22'({instr[31], instr[7], instr[30:25], instr[11:8]});
    if (dec.selImm == IMM_U)        imm_min = imm_min | 22'(instr[31:12]);
    if (dec.selImm == IMM_UJ)       imm_min = imm_min | 22'({instr[31], instr[19:12], instr[20], instr[30:21]});
    if (dec.selImm == IMM_Z)        imm_min = imm_min | 22'({instr[11:7], instr[19:15], instr[31:20]});
    if (dec.selImm == IMM_B6)       imm_min = imm_min | 22'(instr[25:20]);
    if (dec.selImm == IMM_OPIVIS)   imm_min = imm_min | 22'(instr[19:15]);
    if (dec.selImm == IMM_OPIVIU)   imm_min = imm_min | 22'(instr[19:15]);
    if (dec.selImm == IMM_VSETVLI)  imm_min = imm_min | 22'(instr[30:20]);
    if (dec.selImm == IMM_VSETIVLI) imm_min = imm_min | 22'({instr[19:15], instr[29:20]});
    if (dec.selImm == IMM_VRORVI)   imm_min = imm_min | 22'({instr[26], instr[19:15]});
  end

  // ---------------------------------------------------------------------------
  // §8 向量属性
  // ---------------------------------------------------------------------------
  logic isNarrow, isDstMask, isOpMask, isVma, isWritePartVdSplit, emulIsFrac, vstartIsNotZero;
  assign isNarrow  = is_narrow_insn(instr);
  assign isDstMask = is_mask_dst_insn(instr);
  assign isOpMask  = is_mask_op_insn(instr);
  assign isVma     = is_vma_insn(instr);
  assign isWritePartVdSplit = dec.uopSplitType == SPLIT_VEC_VRED || dec.uopSplitType == SPLIT_VEC_0XV
                           || dec.uopSplitType == SPLIT_VEC_VWW;
  // emul 是分数：{~vlmul[2], vlmul[1:0]} + veew < 4 + vsew（4 位无进位丢失的比较）
  assign emulIsFrac = (4'({1'b0, ~enq_vtype.vlmul[2], enq_vtype.vlmul[1:0]}) + 4'(instr[13:12]))
                    < (4'(enq_vtype.vsew) + 4'd4);
  assign vstartIsNotZero = enq_vstart != 8'd0;

  // ---------------------------------------------------------------------------
  // §9 子模块
  // ---------------------------------------------------------------------------
  logic [1:0] fp_typeTagOut, fp_typ, fp_fmt;
  logic       fp_wflags;
  FPDecoder fpDecoder (
    .io_instr             (instr),
    .io_fpCtrl_typeTagOut (fp_typeTagOut),
    .io_fpCtrl_wflags     (fp_wflags),
    .io_fpCtrl_typ        (fp_typ),
    .io_fpCtrl_fmt        (fp_fmt),
    .io_fpCtrl_rm         (fp_rm)
  );

  UopInfoGen uopInfoGen (
    .io_in_preInfo_isVecArith  (isVecArith),
    .io_in_preInfo_isVecMem    (isVls),
    .io_in_preInfo_isAmoCAS    (isAmoCAS),
    .io_in_preInfo_typeOfSplit (dec.uopSplitType),
    .io_in_preInfo_vsew        (enq_vtype.vsew),
    .io_in_preInfo_vlmul       (enq_vtype.vlmul),
    .io_in_preInfo_vwidth      (instr[14:12]),                  // inst.RM
    .io_in_preInfo_nf          (nf),
    .io_in_preInfo_vmvn        (instr[17:15]),                  // IMM5_OPIVI[2:0]：vmv<nr>r 的组数-1
    .io_in_preInfo_isVlsr      (dec.fuOpType == VLDU_vlr || dec.fuOpType == VSTU_vsr),
    .io_in_preInfo_isVlsm      (dec.fuOpType == VLDU_vlm || dec.fuOpType == VSTU_vsm),
    .io_out_isComplex          (deq_is_complex),
    .io_out_uopInfo_numOfUop   (deq_uop_info.numOfUop),
    .io_out_uopInfo_numOfWB    (deq_uop_info.numOfWB),
    .io_out_uopInfo_lmul       (deq_uop_info.lmul)
  );

  // ---------------------------------------------------------------------------
  // §10 出口（io.deq.decodedInst）
  // ---------------------------------------------------------------------------
  // fuType：Mux1H（各条件互斥时等价于 OR）
  //   · 非向量访存且不是 csrr vl/vlenb -> 表值
  //   · csrr vl -> vsetfwf；csrr vlenb -> alu
  //   · 向量访存：NF==0，或 NF!=0 但是整寄存器 load/store（mop=00 且 lumop=01000）-> 表值
  //               NF!=0 且非整寄存器 -> 分段访存单元 vsegldu / vsegstu
  logic fuIsVls, vlsKeep, toVsegStu, toVsegLdu;
  assign fuIsVls   = dec.fuType[FUI_VLDU] | dec.fuType[FUI_VSTU];
  assign vlsKeep   = fuIsVls && nf == 3'd0 || (nf != 3'd0 && mop == 2'b00 && lumop == 5'b01000);
  assign toVsegStu = dec.fuType[FUI_VSTU] && nf != 3'd0 && (mop == 2'b00 && lumop != 5'b01000 || mop != 2'b00);
  assign toVsegLdu = dec.fuType[FUI_VLDU] && nf != 3'd0 && (mop == 2'b00 && lumop != 5'b01000 || mop != 2'b00);

  logic [FU_W-1:0] fuType_out;
  assign fuType_out = ({FU_W{!fuIsVls && !isCsrrVl && !isCsrrVlenb}} & dec.fuType)
                    | ({FU_W{isCsrrVl}}    & FU_VSETFWF)
                    | ({FU_W{isCsrrVlenb}} & FU_ALU)
                    | ({FU_W{vlsKeep}}     & dec.fuType)
                    | ({FU_W{toVsegStu}}   & FU_VSEGSTU)
                    | ({FU_W{toVsegLdu}}   & FU_VSEGLDU);

  // fuOpType：MuxCase（先到先得）
  logic [8:0] fuOpType_out;
  always_comb begin
    if      (isCsrrVl)                              fuOpType_out = VSET_csrrvl;
    else if (isCsrrVlenb)                           fuOpType_out = ALU_add;
    else if (isFLI)                                 fuOpType_out = {2'b01, fmt, rs1};   // Cat(1, FMT, RS1)：fli 的立即数索引带在 fuOpType 里
    else if (isPre)                                 fuOpType_out = ({9{isPreW}} & LSU_prefetch_w)
                                                                 | ({9{isPreR}} & LSU_prefetch_r)
                                                                 | ({9{isPreI}} & LSU_prefetch_i);
    else if (isCboInval && from_csr.special_cboI2F) fuOpType_out = LSU_cbo_flush;   // cbo.inval 降级成 cbo.flush
    else                                            fuOpType_out = dec.fuOpType;
  end

  // imm：MuxCase
  logic [21:0] imm_out;
  assign imm_out = isCsrrVlenb ? IMM_VLENB : isZimop ? 22'd0 : imm_min;

  always_comb begin
    // 静态信息直通（connectStaticInst）
    deq.instr                     = enq.instr;
    deq.pc                        = enq.pc;
    deq.foldpc                    = enq.foldpc;
    deq.exceptionVec              = enq.exceptionVec;
    deq.exceptionVec[2]           = exceptionII | enq.exceptionVec[2];              // illegalInstr
    deq.exceptionVec[3]           = enq.trigger == TRIGGER_BREAKPOINT_EXP;          // breakPoint：前端 trigger 命中
    deq.exceptionVec[22]          = exceptionVI;                                    // virtualInstr
    deq.isFetchMalAddr            = enq.isFetchMalAddr;
    deq.trigger                   = enq.trigger;
    deq.preDecodeInfo_valid       = enq.preDecodeInfo_valid;
    deq.preDecodeInfo_isRVC       = enq.preDecodeInfo_isRVC;
    deq.preDecodeInfo_brType      = enq.preDecodeInfo_brType;
    deq.preDecodeInfo_isCall      = enq.preDecodeInfo_isCall;
    deq.preDecodeInfo_isRet       = enq.preDecodeInfo_isRet;
    deq.pred_taken                = enq.pred_taken;
    deq.crossPageIPFFix           = enq.crossPageIPFFix;
    deq.ftqPtr_flag               = enq.ftqPtr_flag;
    deq.ftqPtr_value              = enq.ftqPtr_value;
    deq.ftqOffset                 = enq.ftqOffset;
    deq.satpFlushFirstFetchFault  = enq.satpFlushFirstFetchFault;
    deq.debug_seqNum_seqNum       = enq.debug_seqNum_seqNum;
    deq.debug_seqNum_uopIdx       = enq.debug_seqNum_uopIdx;

    // 源/目的
    deq.srcType[0] = dec.srcType0;
    deq.srcType[1] = dec.srcType1;
    deq.srcType[2] = dec.srcType2;
    deq.srcType[3] = srcType3;
    deq.srcType[4] = srcType4;
    deq.lsrc[0]    = lsrc0;
    deq.lsrc[1]    = {1'b0, rs2};
    deq.lsrc[2]    = {1'b0, isFMA ? fs3 : rd};   // fma 的 src3 是 fs3，向量指令的 src3 是旧 vd
    deq.ldest      = {1'b0, rd};

    // 功能单元与控制
    deq.fuType         = fuType_out;
    deq.fuOpType       = fuOpType_out;
    deq.rfWen          = rd != 5'd0 && dec.rfWen;   // 写 x0 等于不写
    deq.fpWen          = dec.fpWen;
    deq.vecWen         = dec.vecWen;
    deq.isXSTrap       = dec.isXSTrap;
    deq.waitForward    = dec.waitForward;
    deq.blockBackward  = dec.blockBackward;
    deq.flushPipe      = dec.flushPipe;
    deq.canRobCompress = dec.canRobCompress && !enq.isLastInFtqEntry;   // 跨 Ftq 项不合并
    deq.selImm         = dec.selImm;
    deq.imm            = imm_out;

    // 浮点控制
    deq.fpu_typeTagOut = fp_typeTagOut;
    deq.fpu_wflags     = fp_wflags | is_wfflags_insn(instr);
    deq.fpu_typ        = fp_typ;
    deq.fpu_fmt        = fp_fmt;
    deq.fpu_rm         = fp_rm;

    // 向量控制（vtype 透传两份：当前值与推测值，本级二者相同）
    deq.vpu_vill          = enq_vtype.illegal;
    deq.vpu_vma           = enq_vtype.vma;
    deq.vpu_vta           = enq_vtype.vta;
    deq.vpu_vsew          = enq_vtype.vsew;
    deq.vpu_vlmul         = enq_vtype.vlmul;
    deq.vpu_specVill      = enq_vtype.illegal;
    deq.vpu_specVma       = enq_vtype.vma;
    deq.vpu_specVta       = enq_vtype.vta;
    deq.vpu_specVsew      = enq_vtype.vsew;
    deq.vpu_specVlmul     = enq_vtype.vlmul;
    deq.vpu_vm            = vm;
    deq.vpu_vstart        = enq_vstart;
    deq.vpu_nf            = nf;
    deq.vpu_veew          = instr[13:12];          // inst.WIDTH 的低两位
    deq.vpu_isReverse     = is_reverse_insn(instr);
    deq.vpu_isExt         = is_vext_insn(instr);
    deq.vpu_isNarrow      = isNarrow;
    deq.vpu_isDstMask     = isDstMask;
    deq.vpu_isOpMask      = isOpMask;
    deq.vpu_isDependOldVd = dec.fuType[FUI_VPPU]
                          | dec.fuType[FUI_VFPU] | dec.fuType[FUI_VFALU] | dec.fuType[FUI_VFMA] | dec.fuType[FUI_VFDIV] | dec.fuType[FUI_VFCVT]
                          | isVStore | (isDstMask && !isOpMask) | isNarrow | isVlx | isVma | isFof | vstartIsNotZero;
    deq.vpu_isWritePartVd = isWritePartVdSplit | isVlm | (isVle && emulIsFrac);
    deq.vpu_isVleff       = isFof && nf == 3'd0;
    deq.vlsInstr          = isVls;
    deq.wfflags           = is_wfflags_insn(instr);
    deq.isMove            = (isMove || isZimop) && rd != 5'd0 && !csr_singlestep;
    deq.uopSplitType      = dec.uopSplitType;
    deq.isVset            = dec.fuType[FUI_VSETIWI] | dec.fuType[FUI_VSETIWF] | dec.fuType[FUI_VSETFWF];
    // commitType = {isLs|isVls, (store && !amo) | vstore | branch}
    deq.commitType        = {1'b0, isLs | isVls, (isStore && !isAMO) | isVStore | isBranch};
    deq.debug_fuType      = dec.fuType;   // 修正后、但未经 Mux1H 改成 vseg*/vsetfwf/alu 的那份
  end

endmodule

// -----------------------------------------------------------------------------
// §11 DecodeUnit —— golden 同名 wrapper
// -----------------------------------------------------------------------------
module DecodeUnit
  import decodeunit_pkg::*;
(
  // BEGIN GENERATED(ports)
  // 端口表由 verif/ut/DecodeUnit/gen.py 逐字取自 golden DecodeUnit.sv（顺序/位宽/名字一致，port_contract_lint --order fail）。
  input  [31:0]  io_enq_ctrlFlow_instr,
  input  [49:0]  io_enq_ctrlFlow_pc,
  input  [9:0]   io_enq_ctrlFlow_foldpc,
  input          io_enq_ctrlFlow_exceptionVec_0,
  input          io_enq_ctrlFlow_exceptionVec_1,
  input          io_enq_ctrlFlow_exceptionVec_2,
  input          io_enq_ctrlFlow_exceptionVec_4,
  input          io_enq_ctrlFlow_exceptionVec_5,
  input          io_enq_ctrlFlow_exceptionVec_6,
  input          io_enq_ctrlFlow_exceptionVec_7,
  input          io_enq_ctrlFlow_exceptionVec_8,
  input          io_enq_ctrlFlow_exceptionVec_9,
  input          io_enq_ctrlFlow_exceptionVec_10,
  input          io_enq_ctrlFlow_exceptionVec_11,
  input          io_enq_ctrlFlow_exceptionVec_12,
  input          io_enq_ctrlFlow_exceptionVec_13,
  input          io_enq_ctrlFlow_exceptionVec_14,
  input          io_enq_ctrlFlow_exceptionVec_15,
  input          io_enq_ctrlFlow_exceptionVec_16,
  input          io_enq_ctrlFlow_exceptionVec_17,
  input          io_enq_ctrlFlow_exceptionVec_18,
  input          io_enq_ctrlFlow_exceptionVec_19,
  input          io_enq_ctrlFlow_exceptionVec_20,
  input          io_enq_ctrlFlow_exceptionVec_21,
  input          io_enq_ctrlFlow_exceptionVec_23,
  input          io_enq_ctrlFlow_isFetchMalAddr,
  input  [3:0]   io_enq_ctrlFlow_trigger,
  input          io_enq_ctrlFlow_preDecodeInfo_valid,
  input          io_enq_ctrlFlow_preDecodeInfo_isRVC,
  input  [1:0]   io_enq_ctrlFlow_preDecodeInfo_brType,
  input          io_enq_ctrlFlow_preDecodeInfo_isCall,
  input          io_enq_ctrlFlow_preDecodeInfo_isRet,
  input          io_enq_ctrlFlow_pred_taken,
  input          io_enq_ctrlFlow_crossPageIPFFix,
  input          io_enq_ctrlFlow_ftqPtr_flag,
  input  [5:0]   io_enq_ctrlFlow_ftqPtr_value,
  input  [3:0]   io_enq_ctrlFlow_ftqOffset,
  input          io_enq_ctrlFlow_isLastInFtqEntry,
  input  [55:0]  io_enq_ctrlFlow_debug_seqNum_seqNum,
  input  [7:0]   io_enq_ctrlFlow_debug_seqNum_uopIdx,
  input          io_enq_ctrlFlow_satpFlushFirstFetchFault,
  input          io_enq_vtype_illegal,
  input          io_enq_vtype_vma,
  input          io_enq_vtype_vta,
  input  [1:0]   io_enq_vtype_vsew,
  input  [2:0]   io_enq_vtype_vlmul,
  input  [7:0]   io_enq_vstart,
  output [31:0]  io_deq_decodedInst_instr,
  output [49:0]  io_deq_decodedInst_pc,
  output [9:0]   io_deq_decodedInst_foldpc,
  output         io_deq_decodedInst_exceptionVec_0,
  output         io_deq_decodedInst_exceptionVec_1,
  output         io_deq_decodedInst_exceptionVec_2,
  output         io_deq_decodedInst_exceptionVec_3,
  output         io_deq_decodedInst_exceptionVec_4,
  output         io_deq_decodedInst_exceptionVec_5,
  output         io_deq_decodedInst_exceptionVec_6,
  output         io_deq_decodedInst_exceptionVec_7,
  output         io_deq_decodedInst_exceptionVec_8,
  output         io_deq_decodedInst_exceptionVec_9,
  output         io_deq_decodedInst_exceptionVec_10,
  output         io_deq_decodedInst_exceptionVec_11,
  output         io_deq_decodedInst_exceptionVec_12,
  output         io_deq_decodedInst_exceptionVec_13,
  output         io_deq_decodedInst_exceptionVec_14,
  output         io_deq_decodedInst_exceptionVec_15,
  output         io_deq_decodedInst_exceptionVec_16,
  output         io_deq_decodedInst_exceptionVec_17,
  output         io_deq_decodedInst_exceptionVec_18,
  output         io_deq_decodedInst_exceptionVec_19,
  output         io_deq_decodedInst_exceptionVec_20,
  output         io_deq_decodedInst_exceptionVec_21,
  output         io_deq_decodedInst_exceptionVec_22,
  output         io_deq_decodedInst_exceptionVec_23,
  output         io_deq_decodedInst_isFetchMalAddr,
  output [3:0]   io_deq_decodedInst_trigger,
  output         io_deq_decodedInst_preDecodeInfo_valid,
  output         io_deq_decodedInst_preDecodeInfo_isRVC,
  output [1:0]   io_deq_decodedInst_preDecodeInfo_brType,
  output         io_deq_decodedInst_preDecodeInfo_isCall,
  output         io_deq_decodedInst_preDecodeInfo_isRet,
  output         io_deq_decodedInst_pred_taken,
  output         io_deq_decodedInst_crossPageIPFFix,
  output         io_deq_decodedInst_ftqPtr_flag,
  output [5:0]   io_deq_decodedInst_ftqPtr_value,
  output [3:0]   io_deq_decodedInst_ftqOffset,
  output         io_deq_decodedInst_satpFlushFirstFetchFault,
  output [3:0]   io_deq_decodedInst_srcType_0,
  output [3:0]   io_deq_decodedInst_srcType_1,
  output [3:0]   io_deq_decodedInst_srcType_2,
  output [3:0]   io_deq_decodedInst_srcType_3,
  output [3:0]   io_deq_decodedInst_srcType_4,
  output [5:0]   io_deq_decodedInst_lsrc_0,
  output [5:0]   io_deq_decodedInst_lsrc_1,
  output [5:0]   io_deq_decodedInst_lsrc_2,
  output [5:0]   io_deq_decodedInst_ldest,
  output [34:0]  io_deq_decodedInst_fuType,
  output [8:0]   io_deq_decodedInst_fuOpType,
  output         io_deq_decodedInst_rfWen,
  output         io_deq_decodedInst_fpWen,
  output         io_deq_decodedInst_vecWen,
  output         io_deq_decodedInst_isXSTrap,
  output         io_deq_decodedInst_waitForward,
  output         io_deq_decodedInst_blockBackward,
  output         io_deq_decodedInst_flushPipe,
  output         io_deq_decodedInst_canRobCompress,
  output [3:0]   io_deq_decodedInst_selImm,
  output [21:0]  io_deq_decodedInst_imm,
  output [1:0]   io_deq_decodedInst_fpu_typeTagOut,
  output         io_deq_decodedInst_fpu_wflags,
  output [1:0]   io_deq_decodedInst_fpu_typ,
  output [1:0]   io_deq_decodedInst_fpu_fmt,
  output [2:0]   io_deq_decodedInst_fpu_rm,
  output         io_deq_decodedInst_vpu_vill,
  output         io_deq_decodedInst_vpu_vma,
  output         io_deq_decodedInst_vpu_vta,
  output [1:0]   io_deq_decodedInst_vpu_vsew,
  output [2:0]   io_deq_decodedInst_vpu_vlmul,
  output         io_deq_decodedInst_vpu_specVill,
  output         io_deq_decodedInst_vpu_specVma,
  output         io_deq_decodedInst_vpu_specVta,
  output [1:0]   io_deq_decodedInst_vpu_specVsew,
  output [2:0]   io_deq_decodedInst_vpu_specVlmul,
  output         io_deq_decodedInst_vpu_vm,
  output [7:0]   io_deq_decodedInst_vpu_vstart,
  output [2:0]   io_deq_decodedInst_vpu_nf,
  output [1:0]   io_deq_decodedInst_vpu_veew,
  output         io_deq_decodedInst_vpu_isReverse,
  output         io_deq_decodedInst_vpu_isExt,
  output         io_deq_decodedInst_vpu_isNarrow,
  output         io_deq_decodedInst_vpu_isDstMask,
  output         io_deq_decodedInst_vpu_isOpMask,
  output         io_deq_decodedInst_vpu_isDependOldVd,
  output         io_deq_decodedInst_vpu_isWritePartVd,
  output         io_deq_decodedInst_vpu_isVleff,
  output         io_deq_decodedInst_vlsInstr,
  output         io_deq_decodedInst_wfflags,
  output         io_deq_decodedInst_isMove,
  output [5:0]   io_deq_decodedInst_uopSplitType,
  output         io_deq_decodedInst_isVset,
  output [2:0]   io_deq_decodedInst_commitType,
  output [34:0]  io_deq_decodedInst_debug_fuType,
  output [55:0]  io_deq_decodedInst_debug_seqNum_seqNum,
  output [7:0]   io_deq_decodedInst_debug_seqNum_uopIdx,
  output         io_deq_isComplex,
  output [6:0]   io_deq_uopInfo_numOfUop,
  output [6:0]   io_deq_uopInfo_numOfWB,
  output [3:0]   io_deq_uopInfo_lmul,
  input          io_csrCtrl_singlestep,
  input          io_fromCSR_illegalInst_sfenceVMA,
  input          io_fromCSR_illegalInst_sfencePart,
  input          io_fromCSR_illegalInst_hfenceGVMA,
  input          io_fromCSR_illegalInst_hfenceVVMA,
  input          io_fromCSR_illegalInst_hlsv,
  input          io_fromCSR_illegalInst_fsIsOff,
  input          io_fromCSR_illegalInst_vsIsOff,
  input          io_fromCSR_illegalInst_wfi,
  input          io_fromCSR_illegalInst_wrs_nto,
  input          io_fromCSR_illegalInst_frm,
  input          io_fromCSR_illegalInst_cboZ,
  input          io_fromCSR_illegalInst_cboCF,
  input          io_fromCSR_illegalInst_cboI,
  input          io_fromCSR_virtualInst_sfenceVMA,
  input          io_fromCSR_virtualInst_sfencePart,
  input          io_fromCSR_virtualInst_hfence,
  input          io_fromCSR_virtualInst_hlsv,
  input          io_fromCSR_virtualInst_wfi,
  input          io_fromCSR_virtualInst_wrs_nto,
  input          io_fromCSR_virtualInst_cboZ,
  input          io_fromCSR_virtualInst_cboCF,
  input          io_fromCSR_virtualInst_cboI,
  input          io_fromCSR_special_cboI2F
  // END GENERATED(ports)
);

  // BEGIN GENERATED(wrapper)
  // 接线由 verif/ut/DecodeUnit/gen.py 机械生成：输入打包成 struct 喂给可读核，核的输出摊回 golden 端口。
  static_inst_t   enq;
  vtype_t         enq_vtype;
  csr_to_decode_t from_csr;
  decoded_inst_t  deq;
  uop_info_t      deq_uop_info;

  assign enq.instr = io_enq_ctrlFlow_instr;
  assign enq.pc = io_enq_ctrlFlow_pc;
  assign enq.foldpc = io_enq_ctrlFlow_foldpc;
  assign enq.exceptionVec[0] = io_enq_ctrlFlow_exceptionVec_0;
  assign enq.exceptionVec[1] = io_enq_ctrlFlow_exceptionVec_1;
  assign enq.exceptionVec[2] = io_enq_ctrlFlow_exceptionVec_2;
  assign enq.exceptionVec[4] = io_enq_ctrlFlow_exceptionVec_4;
  assign enq.exceptionVec[5] = io_enq_ctrlFlow_exceptionVec_5;
  assign enq.exceptionVec[6] = io_enq_ctrlFlow_exceptionVec_6;
  assign enq.exceptionVec[7] = io_enq_ctrlFlow_exceptionVec_7;
  assign enq.exceptionVec[8] = io_enq_ctrlFlow_exceptionVec_8;
  assign enq.exceptionVec[9] = io_enq_ctrlFlow_exceptionVec_9;
  assign enq.exceptionVec[10] = io_enq_ctrlFlow_exceptionVec_10;
  assign enq.exceptionVec[11] = io_enq_ctrlFlow_exceptionVec_11;
  assign enq.exceptionVec[12] = io_enq_ctrlFlow_exceptionVec_12;
  assign enq.exceptionVec[13] = io_enq_ctrlFlow_exceptionVec_13;
  assign enq.exceptionVec[14] = io_enq_ctrlFlow_exceptionVec_14;
  assign enq.exceptionVec[15] = io_enq_ctrlFlow_exceptionVec_15;
  assign enq.exceptionVec[16] = io_enq_ctrlFlow_exceptionVec_16;
  assign enq.exceptionVec[17] = io_enq_ctrlFlow_exceptionVec_17;
  assign enq.exceptionVec[18] = io_enq_ctrlFlow_exceptionVec_18;
  assign enq.exceptionVec[19] = io_enq_ctrlFlow_exceptionVec_19;
  assign enq.exceptionVec[20] = io_enq_ctrlFlow_exceptionVec_20;
  assign enq.exceptionVec[21] = io_enq_ctrlFlow_exceptionVec_21;
  assign enq.exceptionVec[23] = io_enq_ctrlFlow_exceptionVec_23;
  assign enq.isFetchMalAddr = io_enq_ctrlFlow_isFetchMalAddr;
  assign enq.trigger = io_enq_ctrlFlow_trigger;
  assign enq.preDecodeInfo_valid = io_enq_ctrlFlow_preDecodeInfo_valid;
  assign enq.preDecodeInfo_isRVC = io_enq_ctrlFlow_preDecodeInfo_isRVC;
  assign enq.preDecodeInfo_brType = io_enq_ctrlFlow_preDecodeInfo_brType;
  assign enq.preDecodeInfo_isCall = io_enq_ctrlFlow_preDecodeInfo_isCall;
  assign enq.preDecodeInfo_isRet = io_enq_ctrlFlow_preDecodeInfo_isRet;
  assign enq.pred_taken = io_enq_ctrlFlow_pred_taken;
  assign enq.crossPageIPFFix = io_enq_ctrlFlow_crossPageIPFFix;
  assign enq.ftqPtr_flag = io_enq_ctrlFlow_ftqPtr_flag;
  assign enq.ftqPtr_value = io_enq_ctrlFlow_ftqPtr_value;
  assign enq.ftqOffset = io_enq_ctrlFlow_ftqOffset;
  assign enq.isLastInFtqEntry = io_enq_ctrlFlow_isLastInFtqEntry;
  assign enq.debug_seqNum_seqNum = io_enq_ctrlFlow_debug_seqNum_seqNum;
  assign enq.debug_seqNum_uopIdx = io_enq_ctrlFlow_debug_seqNum_uopIdx;
  assign enq.satpFlushFirstFetchFault = io_enq_ctrlFlow_satpFlushFirstFetchFault;
  // golden 输入端口没有的两位（本模块整段改写它们）
  assign enq.exceptionVec[3]  = 1'b0;
  assign enq.exceptionVec[22] = 1'b0;
  assign enq_vtype.illegal = io_enq_vtype_illegal;
  assign enq_vtype.vma = io_enq_vtype_vma;
  assign enq_vtype.vta = io_enq_vtype_vta;
  assign enq_vtype.vsew = io_enq_vtype_vsew;
  assign enq_vtype.vlmul = io_enq_vtype_vlmul;
  assign from_csr.illegalInst_sfenceVMA = io_fromCSR_illegalInst_sfenceVMA;
  assign from_csr.illegalInst_sfencePart = io_fromCSR_illegalInst_sfencePart;
  assign from_csr.illegalInst_hfenceGVMA = io_fromCSR_illegalInst_hfenceGVMA;
  assign from_csr.illegalInst_hfenceVVMA = io_fromCSR_illegalInst_hfenceVVMA;
  assign from_csr.illegalInst_hlsv = io_fromCSR_illegalInst_hlsv;
  assign from_csr.illegalInst_fsIsOff = io_fromCSR_illegalInst_fsIsOff;
  assign from_csr.illegalInst_vsIsOff = io_fromCSR_illegalInst_vsIsOff;
  assign from_csr.illegalInst_wfi = io_fromCSR_illegalInst_wfi;
  assign from_csr.illegalInst_wrs_nto = io_fromCSR_illegalInst_wrs_nto;
  assign from_csr.illegalInst_frm = io_fromCSR_illegalInst_frm;
  assign from_csr.illegalInst_cboZ = io_fromCSR_illegalInst_cboZ;
  assign from_csr.illegalInst_cboCF = io_fromCSR_illegalInst_cboCF;
  assign from_csr.illegalInst_cboI = io_fromCSR_illegalInst_cboI;
  assign from_csr.virtualInst_sfenceVMA = io_fromCSR_virtualInst_sfenceVMA;
  assign from_csr.virtualInst_sfencePart = io_fromCSR_virtualInst_sfencePart;
  assign from_csr.virtualInst_hfence = io_fromCSR_virtualInst_hfence;
  assign from_csr.virtualInst_hlsv = io_fromCSR_virtualInst_hlsv;
  assign from_csr.virtualInst_wfi = io_fromCSR_virtualInst_wfi;
  assign from_csr.virtualInst_wrs_nto = io_fromCSR_virtualInst_wrs_nto;
  assign from_csr.virtualInst_cboZ = io_fromCSR_virtualInst_cboZ;
  assign from_csr.virtualInst_cboCF = io_fromCSR_virtualInst_cboCF;
  assign from_csr.virtualInst_cboI = io_fromCSR_virtualInst_cboI;
  assign from_csr.special_cboI2F = io_fromCSR_special_cboI2F;

  xs_DecodeUnit_core u_core (
    .enq            (enq),
    .enq_vtype      (enq_vtype),
    .enq_vstart     (io_enq_vstart),
    .csr_singlestep (io_csrCtrl_singlestep),
    .from_csr       (from_csr),
    .deq            (deq),
    .deq_is_complex (io_deq_isComplex),
    .deq_uop_info   (deq_uop_info)
  );

  assign io_deq_decodedInst_instr = deq.instr;
  assign io_deq_decodedInst_pc = deq.pc;
  assign io_deq_decodedInst_foldpc = deq.foldpc;
  assign io_deq_decodedInst_exceptionVec_0 = deq.exceptionVec[0];
  assign io_deq_decodedInst_exceptionVec_1 = deq.exceptionVec[1];
  assign io_deq_decodedInst_exceptionVec_2 = deq.exceptionVec[2];
  assign io_deq_decodedInst_exceptionVec_3 = deq.exceptionVec[3];
  assign io_deq_decodedInst_exceptionVec_4 = deq.exceptionVec[4];
  assign io_deq_decodedInst_exceptionVec_5 = deq.exceptionVec[5];
  assign io_deq_decodedInst_exceptionVec_6 = deq.exceptionVec[6];
  assign io_deq_decodedInst_exceptionVec_7 = deq.exceptionVec[7];
  assign io_deq_decodedInst_exceptionVec_8 = deq.exceptionVec[8];
  assign io_deq_decodedInst_exceptionVec_9 = deq.exceptionVec[9];
  assign io_deq_decodedInst_exceptionVec_10 = deq.exceptionVec[10];
  assign io_deq_decodedInst_exceptionVec_11 = deq.exceptionVec[11];
  assign io_deq_decodedInst_exceptionVec_12 = deq.exceptionVec[12];
  assign io_deq_decodedInst_exceptionVec_13 = deq.exceptionVec[13];
  assign io_deq_decodedInst_exceptionVec_14 = deq.exceptionVec[14];
  assign io_deq_decodedInst_exceptionVec_15 = deq.exceptionVec[15];
  assign io_deq_decodedInst_exceptionVec_16 = deq.exceptionVec[16];
  assign io_deq_decodedInst_exceptionVec_17 = deq.exceptionVec[17];
  assign io_deq_decodedInst_exceptionVec_18 = deq.exceptionVec[18];
  assign io_deq_decodedInst_exceptionVec_19 = deq.exceptionVec[19];
  assign io_deq_decodedInst_exceptionVec_20 = deq.exceptionVec[20];
  assign io_deq_decodedInst_exceptionVec_21 = deq.exceptionVec[21];
  assign io_deq_decodedInst_exceptionVec_22 = deq.exceptionVec[22];
  assign io_deq_decodedInst_exceptionVec_23 = deq.exceptionVec[23];
  assign io_deq_decodedInst_isFetchMalAddr = deq.isFetchMalAddr;
  assign io_deq_decodedInst_trigger = deq.trigger;
  assign io_deq_decodedInst_preDecodeInfo_valid = deq.preDecodeInfo_valid;
  assign io_deq_decodedInst_preDecodeInfo_isRVC = deq.preDecodeInfo_isRVC;
  assign io_deq_decodedInst_preDecodeInfo_brType = deq.preDecodeInfo_brType;
  assign io_deq_decodedInst_preDecodeInfo_isCall = deq.preDecodeInfo_isCall;
  assign io_deq_decodedInst_preDecodeInfo_isRet = deq.preDecodeInfo_isRet;
  assign io_deq_decodedInst_pred_taken = deq.pred_taken;
  assign io_deq_decodedInst_crossPageIPFFix = deq.crossPageIPFFix;
  assign io_deq_decodedInst_ftqPtr_flag = deq.ftqPtr_flag;
  assign io_deq_decodedInst_ftqPtr_value = deq.ftqPtr_value;
  assign io_deq_decodedInst_ftqOffset = deq.ftqOffset;
  assign io_deq_decodedInst_satpFlushFirstFetchFault = deq.satpFlushFirstFetchFault;
  assign io_deq_decodedInst_srcType_0 = deq.srcType[0];
  assign io_deq_decodedInst_srcType_1 = deq.srcType[1];
  assign io_deq_decodedInst_srcType_2 = deq.srcType[2];
  assign io_deq_decodedInst_srcType_3 = deq.srcType[3];
  assign io_deq_decodedInst_srcType_4 = deq.srcType[4];
  assign io_deq_decodedInst_lsrc_0 = deq.lsrc[0];
  assign io_deq_decodedInst_lsrc_1 = deq.lsrc[1];
  assign io_deq_decodedInst_lsrc_2 = deq.lsrc[2];
  assign io_deq_decodedInst_ldest = deq.ldest;
  assign io_deq_decodedInst_fuType = deq.fuType;
  assign io_deq_decodedInst_fuOpType = deq.fuOpType;
  assign io_deq_decodedInst_rfWen = deq.rfWen;
  assign io_deq_decodedInst_fpWen = deq.fpWen;
  assign io_deq_decodedInst_vecWen = deq.vecWen;
  assign io_deq_decodedInst_isXSTrap = deq.isXSTrap;
  assign io_deq_decodedInst_waitForward = deq.waitForward;
  assign io_deq_decodedInst_blockBackward = deq.blockBackward;
  assign io_deq_decodedInst_flushPipe = deq.flushPipe;
  assign io_deq_decodedInst_canRobCompress = deq.canRobCompress;
  assign io_deq_decodedInst_selImm = deq.selImm;
  assign io_deq_decodedInst_imm = deq.imm;
  assign io_deq_decodedInst_fpu_typeTagOut = deq.fpu_typeTagOut;
  assign io_deq_decodedInst_fpu_wflags = deq.fpu_wflags;
  assign io_deq_decodedInst_fpu_typ = deq.fpu_typ;
  assign io_deq_decodedInst_fpu_fmt = deq.fpu_fmt;
  assign io_deq_decodedInst_fpu_rm = deq.fpu_rm;
  assign io_deq_decodedInst_vpu_vill = deq.vpu_vill;
  assign io_deq_decodedInst_vpu_vma = deq.vpu_vma;
  assign io_deq_decodedInst_vpu_vta = deq.vpu_vta;
  assign io_deq_decodedInst_vpu_vsew = deq.vpu_vsew;
  assign io_deq_decodedInst_vpu_vlmul = deq.vpu_vlmul;
  assign io_deq_decodedInst_vpu_specVill = deq.vpu_specVill;
  assign io_deq_decodedInst_vpu_specVma = deq.vpu_specVma;
  assign io_deq_decodedInst_vpu_specVta = deq.vpu_specVta;
  assign io_deq_decodedInst_vpu_specVsew = deq.vpu_specVsew;
  assign io_deq_decodedInst_vpu_specVlmul = deq.vpu_specVlmul;
  assign io_deq_decodedInst_vpu_vm = deq.vpu_vm;
  assign io_deq_decodedInst_vpu_vstart = deq.vpu_vstart;
  assign io_deq_decodedInst_vpu_nf = deq.vpu_nf;
  assign io_deq_decodedInst_vpu_veew = deq.vpu_veew;
  assign io_deq_decodedInst_vpu_isReverse = deq.vpu_isReverse;
  assign io_deq_decodedInst_vpu_isExt = deq.vpu_isExt;
  assign io_deq_decodedInst_vpu_isNarrow = deq.vpu_isNarrow;
  assign io_deq_decodedInst_vpu_isDstMask = deq.vpu_isDstMask;
  assign io_deq_decodedInst_vpu_isOpMask = deq.vpu_isOpMask;
  assign io_deq_decodedInst_vpu_isDependOldVd = deq.vpu_isDependOldVd;
  assign io_deq_decodedInst_vpu_isWritePartVd = deq.vpu_isWritePartVd;
  assign io_deq_decodedInst_vpu_isVleff = deq.vpu_isVleff;
  assign io_deq_decodedInst_vlsInstr = deq.vlsInstr;
  assign io_deq_decodedInst_wfflags = deq.wfflags;
  assign io_deq_decodedInst_isMove = deq.isMove;
  assign io_deq_decodedInst_uopSplitType = deq.uopSplitType;
  assign io_deq_decodedInst_isVset = deq.isVset;
  assign io_deq_decodedInst_commitType = deq.commitType;
  assign io_deq_decodedInst_debug_fuType = deq.debug_fuType;
  assign io_deq_decodedInst_debug_seqNum_seqNum = deq.debug_seqNum_seqNum;
  assign io_deq_decodedInst_debug_seqNum_uopIdx = deq.debug_seqNum_uopIdx;
  assign io_deq_uopInfo_numOfUop = deq_uop_info.numOfUop;
  assign io_deq_uopInfo_numOfWB = deq_uop_info.numOfWB;
  assign io_deq_uopInfo_lmul = deq_uop_info.lmul;
  // END GENERATED(wrapper)

endmodule
