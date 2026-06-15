// =============================================================================
// rvc_expander_pkg —— RVC（RISC-V 压缩指令）展开器的公共类型与立即数/字段工具
//
// 对应 Chisel: xiangshan.frontend / rocket-chip 的 RVCExpander。
//
// 背景：RISC-V 的 C 扩展把高频指令压缩成 16 位编码，以提高代码密度。取指级拿到
// 16 位 RVC 指令后，需要在送入后端译码前先“展开”成等价的 32 位标准指令——这样
// 后端译码器只需面对一种 32 位格式。RVCExpander 就是这个纯组合的展开器。
//
// RVC 用最低 2 位 inst[1:0]（称 op / quadrant）区分三个压缩象限，inst[1:0]==2'b11
// 表示这不是压缩指令（本来就是 32 位）：
//   - op=00  Quadrant 0 (C0)：以 x8..x15 受限寄存器为主的 load/store + ADDI4SPN
//   - op=01  Quadrant 1 (C1)：立即数运算、控制流（J/BEQZ/BNEZ）、LUI/ADDI16SP
//   - op=10  Quadrant 2 (C2)：栈相对 load/store、SLLI、JR/JALR/MV/ADD 等
//   - op=11           ：非压缩指令，原样透传
//
// 在每个象限内再用 funct3 = inst[15:13] 细分具体指令。因此 RVCExpander 用
// {op, funct3} 这 5 位作为一级选择子（共 32 项），正好覆盖 4 象限 × 8 funct3。
// =============================================================================
package rvc_expander_pkg;

  // ---------------------------------------------------------------------------
  // 一级选择子 idx = {op[1:0], funct3[2:0]} 的枚举
  // 命名规则 Q<象限>_<funct3>，注释标该项对应的 RVC 指令类。
  // 注意：op=11（idx 0x18..0x1F）是“非压缩/透传”，不在象限译码内单列。
  // ---------------------------------------------------------------------------
  typedef enum logic [4:0] {
    // Quadrant 0 (op=00)
    Q0_ADDI4SPN = 5'h00,  // C.ADDI4SPN
    Q0_FLD      = 5'h01,  // C.FLD
    Q0_LW       = 5'h02,  // C.LW
    Q0_LD       = 5'h03,  // C.LD
    Q0_ZCB_LS   = 5'h04,  // Zcb: C.LBU/C.LHU/C.LH/C.SB/C.SH（由 inst[11:10] 细分）
    Q0_FSD      = 5'h05,  // C.FSD
    Q0_SW       = 5'h06,  // C.SW
    Q0_SD       = 5'h07,  // C.SD
    // Quadrant 1 (op=01)
    Q1_ADDI     = 5'h08,  // C.ADDI / C.NOP
    Q1_ADDIW    = 5'h09,  // C.ADDIW（RV64）
    Q1_LI       = 5'h0A,  // C.LI
    Q1_LUI_A16  = 5'h0B,  // C.LUI / C.ADDI16SP
    Q1_MISC_ALU = 5'h0C,  // C.SRLI/SRAI/ANDI/SUB/XOR/OR/AND/SUBW/ADDW
    Q1_J        = 5'h0D,  // C.J
    Q1_BEQZ     = 5'h0E,  // C.BEQZ
    Q1_BNEZ     = 5'h0F,  // C.BNEZ
    // Quadrant 2 (op=10)
    Q2_SLLI     = 5'h10,  // C.SLLI
    Q2_FLDSP    = 5'h11,  // C.FLDSP
    Q2_LWSP     = 5'h12,  // C.LWSP
    Q2_LDSP     = 5'h13,  // C.LDSP
    Q2_JALR_MV  = 5'h14,  // C.JR/C.MV/C.EBREAK/C.JALR/C.ADD（由 inst[12]、寄存器域细分）
    Q2_FSDSP    = 5'h15,  // C.FSDSP
    Q2_SWSP     = 5'h16,  // C.SWSP
    Q2_SDSP     = 5'h17   // C.SDSP
    // 5'h18..5'h1F：op=11，非压缩指令，原样透传（不在此枚举内）
  } rvc_sel_e;

  // ---------------------------------------------------------------------------
  // 32 位标准指令的 7 位主 opcode（RISC-V base opcode[6:0]）。
  // 展开后的指令都落到这几类标准编码上。
  // ---------------------------------------------------------------------------
  localparam logic [6:0] OP_LOAD     = 7'h03;  // I 型 load (LB/LH/LW/LD/LBU/LHU/LWU)
  localparam logic [6:0] OP_LOAD_FP  = 7'h07;  // FLD/FLW
  localparam logic [6:0] OP_OP_IMM   = 7'h13;  // I 型算术 (ADDI/SLLI/...)
  localparam logic [6:0] OP_STORE    = 7'h23;  // S 型 store
  localparam logic [6:0] OP_STORE_FP = 7'h27;  // FSD/FSW
  localparam logic [6:0] OP_OP       = 7'h33;  // R 型算术 (ADD/SUB/...)
  localparam logic [6:0] OP_OP_IMM32 = 7'h1B;  // ADDIW/SLLIW（RV64 *W 立即数）
  localparam logic [6:0] OP_OP32     = 7'h3B;  // ADDW/SUBW（RV64 *W R 型）
  localparam logic [6:0] OP_BRANCH   = 7'h63;  // 条件分支
  localparam logic [6:0] OP_JAL      = 7'h6F;  // JAL
  localparam logic [6:0] OP_SYSTEM   = 7'h73;  // ECALL/EBREAK
  // 非法 RVC 在 rocket 习惯里展开成一个“注定异常”的占位编码：opcode=7'h1F。
  localparam logic [6:0] OP_ILLEGAL  = 7'h1F;

  // 32 位指令组装器（R/I/S/B/U/J 型），各域名表达 RISC-V 标准格式语义。
  // 用这些函数代替 golden 的裸位拼接，意图更清晰；展开后的位序与标准一致。
  function automatic logic [31:0] rv_r(input logic [6:0] funct7, input logic [4:0] rs2,
                                       input logic [4:0] rs1, input logic [2:0] funct3,
                                       input logic [4:0] rd, input logic [6:0] opc);
    return {funct7, rs2, rs1, funct3, rd, opc};
  endfunction

  function automatic logic [31:0] rv_i(input logic [11:0] imm, input logic [4:0] rs1,
                                       input logic [2:0] funct3, input logic [4:0] rd,
                                       input logic [6:0] opc);
    return {imm, rs1, funct3, rd, opc};
  endfunction

  function automatic logic [31:0] rv_s(input logic [11:0] imm, input logic [4:0] rs2,
                                       input logic [4:0] rs1, input logic [2:0] funct3,
                                       input logic [6:0] opc);
    return {imm[11:5], rs2, rs1, funct3, imm[4:0], opc};
  endfunction

  function automatic logic [31:0] rv_b(input logic [12:0] imm, input logic [4:0] rs2,
                                       input logic [4:0] rs1, input logic [2:0] funct3,
                                       input logic [6:0] opc);
    return {imm[12], imm[10:5], rs2, rs1, funct3, imm[4:1], imm[11], opc};
  endfunction

  function automatic logic [31:0] rv_u(input logic [19:0] imm, input logic [4:0] rd,
                                       input logic [6:0] opc);
    return {imm, rd, opc};
  endfunction

  function automatic logic [31:0] rv_j(input logic [20:0] imm, input logic [4:0] rd,
                                       input logic [6:0] opc);
    return {imm[20], imm[10:1], imm[11], imm[19:12], rd, opc};
  endfunction

endpackage : rvc_expander_pkg
