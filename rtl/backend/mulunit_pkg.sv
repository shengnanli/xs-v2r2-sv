// =============================================================================
//  mulunit_pkg —— 整数乘法功能单元 MulUnit 的类型 / 常量 / 纯函数
// -----------------------------------------------------------------------------
//  设计意图来源：src/main/scala/xiangshan/backend/fu/wrapper/MulUnit.scala
//                + src/main/scala/xiangshan/package.scala (object MULOpType)
//
//  MulUnit 是一个 2 拍流水的整数乘法 FU 包装层（HasPipelineReg, latency=2）。
//  它本身不做乘法阵列，只负责：
//    1) 从 fuOpType 译出乘法子操作（mul/mulh/mulhsu/mulhu/mulw7）；
//    2) 按子操作对两个 65bit 源操作数做符号/零扩展（符号处理）；
//    3) 维护一条 2 级的 “是否取高半 / 是否字操作” 控制流水（mdCtrl pipe）；
//    4) 从乘法阵列 130bit 结果中按 isHi 选高/低半，按 isW 做 32→64 符号扩展。
//  真正的乘法阵列 ArrayMulDataModule 当作 golden 黑盒例化（见 MulUnit.sv）。
//
//  本包把 golden 里散落的位选择、LookupTree、Mux 收敛成有意义的 enum + 纯函数，
//  以便阅读者直接对照 MULOpType 的编码理解“符号扩展为什么这么做”。
// =============================================================================
package mulunit_pkg;

  // ---- 数据宽度参数 ----
  // xlen：目的数据位宽（RV64 → 64）；乘法阵列的操作数/结果加 1 位用于带符号扩展，
  // 故 a/b 为 xlen+1=65 位，结果为 2*(xlen+1)=130 位。
  localparam int XLEN    = 64;
  localparam int MUL_LEN = XLEN + 1;        // 65：阵列输入位宽
  localparam int RES_LEN = 2 * MUL_LEN;     // 130：阵列结果位宽

  // ---------------------------------------------------------------------------
  //  乘法子操作（MULOpType.getOp 后的 3bit 编码）
  // ---------------------------------------------------------------------------
  //  fuOpType 编码：| type(2) | isWord(1)=bit2 | opcode(2)=bit1:0 |
  //  getOp(func) = {func[3], func[1:0]}，把 mulw7 的 type 高位与 opcode 拼成 3bit：
  //    mul    = 00000 → op = 000
  //    mulh   = 00001 → op = 001
  //    mulhsu = 00010 → op = 010
  //    mulhu  = 00011 → op = 011
  //    mulw7  = 01100 → op = 100   (mulw7 取 src0 低 7bit，专用于压缩乘法路径)
  //  注：普通 mulw(00100) 走 isW 字处理，其 op 仍为 000（与 mul 共用阵列输入扩展）。
  typedef enum logic [2:0] {
    MUL_MUL    = 3'b000,   // 低 64 位乘积，源零扩展
    MUL_MULH   = 3'b001,   // 高 64 位乘积，源均带符号扩展（signed × signed）
    MUL_MULHSU = 3'b010,   // 高 64 位乘积，src0 带符号、src1 无符号
    MUL_MULHU  = 3'b011,   // 高 64 位乘积，源均零扩展（unsigned × unsigned）
    MUL_MULW7  = 3'b100    // src0 仅取低 7bit（无符号），src1 零扩展
  } mul_op_e;

  // op 提取：与 MULOpType.getOp 一致
  function automatic mul_op_e getMulOp(input logic [8:0] func);
    return mul_op_e'({func[3], func[1:0]});
  endfunction

  // ---------------------------------------------------------------------------
  //  源操作数扩展（符号处理）
  // ---------------------------------------------------------------------------
  //  把 64bit 源扩展到 65bit。是否带符号由乘法子操作决定（见 mulInputCvtTable）：
  //    a 端：mul/mulhu 零扩展；mulh/mulhsu 符号扩展；mulw7 取低 7bit 零扩展。
  //    b 端：除 mulh 外一律零扩展；mulh 符号扩展。
  //  之所以两端规则不同：mulhsu 的被乘数(src0)带符号、乘数(src1)无符号。
  function automatic logic [MUL_LEN-1:0] sext65(input logic [XLEN-1:0] x);
    return {x[XLEN-1], x};                  // 符号位复制 1 份到第 65 位
  endfunction

  function automatic logic [MUL_LEN-1:0] zext65(input logic [XLEN-1:0] x);
    return {1'b0, x};
  endfunction

  // a 端扩展：依子操作选择符号/零/低 7bit。
  //  注意 default = 0：这是 Chisel 端 LookupTree 的语义——op 不在表中（非法编码）时
  //  输出 0，而非透传 src0。务必用 case 而非 priority/if 链，且 default 给 0，
  //  以与 golden 的 one-hot OR-mux 严格等价（FM 会检查所有 op 取值）。
  function automatic logic [MUL_LEN-1:0] cvtMulA(input mul_op_e op,
                                                 input logic [XLEN-1:0] src0);
    case (op)
      MUL_MUL, MUL_MULHU   : cvtMulA = zext65(src0);            // 无符号
      MUL_MULH, MUL_MULHSU : cvtMulA = sext65(src0);            // 带符号
      MUL_MULW7            : cvtMulA = {{(MUL_LEN-7){1'b0}}, src0[6:0]}; // 低 7bit
      default              : cvtMulA = '0;                      // 非法编码 → 0
    endcase
  endfunction

  // b 端扩展：mulh 带符号，mul/mulhsu/mulhu/mulw7 零扩展；非法编码 → 0（同上）。
  function automatic logic [MUL_LEN-1:0] cvtMulB(input mul_op_e op,
                                                 input logic [XLEN-1:0] src1);
    case (op)
      MUL_MULH                                    : cvtMulB = sext65(src1); // 带符号
      MUL_MUL, MUL_MULHSU, MUL_MULHU, MUL_MULW7   : cvtMulB = zext65(src1); // 无符号
      default                                     : cvtMulB = '0;          // 非法编码 → 0
    endcase
  endfunction

  // ---------------------------------------------------------------------------
  //  乘法控制流水 payload（MulDivCtrl 的精简：本 FU 仅用 isHi / isW）
  // ---------------------------------------------------------------------------
  //  isHi：结果取高半（mulh/mulhsu/mulhu）；由 fuOpType[1:0] 非零判定。
  //  isW ：字（W）操作，结果按 32→64 符号扩展；由 fuOpType[2] 判定。
  //  该 payload 随阵列时延（2 拍）一同打拍，使最后一级用对应指令的控制位选结果。
  typedef struct packed {
    logic isW;
    logic isHi;
  } mul_ctrl_t;

  function automatic mul_ctrl_t decodeMulCtrl(input logic [8:0] func);
    mul_ctrl_t c;
    c.isW  = func[2];                       // MULOpType.isW
    c.isHi = |func[1:0];                    // MULOpType.isH
    return c;
  endfunction

  // ---------------------------------------------------------------------------
  //  结果选择
  // ---------------------------------------------------------------------------
  //  从阵列 130bit 结果按 isHi 选 [127:64]（高半）或 [63:0]（低半），
  //  再按 isW 决定是否把低 32bit 符号扩展回 64bit（W 类指令结果是 32bit 量）。
  function automatic logic [XLEN-1:0] selMulHiLo(input logic         isHi,
                                                 input logic [RES_LEN-1:0] result);
    selMulHiLo = isHi ? result[2*XLEN-1 : XLEN] : result[XLEN-1 : 0];
  endfunction

  function automatic logic [XLEN-1:0] finalMulRes(input logic         isW,
                                                  input logic [XLEN-1:0] res);
    finalMulRes = isW ? {{(XLEN-32){res[31]}}, res[31:0]} : res;
  endfunction

endpackage
