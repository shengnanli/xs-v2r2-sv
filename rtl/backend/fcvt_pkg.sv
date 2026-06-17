// =============================================================================
//  fcvt_pkg —— 浮点转换功能单元 FCVT 的类型 / 常量 / 纯函数
// -----------------------------------------------------------------------------
//  设计意图来源：src/main/scala/xiangshan/backend/fu/wrapper/FCVT.scala
//                （class FCVT extends FpPipedFuncUnit, latency=2）
//                + yunsuan.VfcvtType（opType 编码）
//
//  FCVT 是标量浮点转换 FU：f2i / i2f / f2f（变宽）/ fround / fcvtmod / fmv 等。
//  真正转换在黑盒 FPCVT（2 拍流水）；本 wrapper 层做不少「格式 / 宽度 / 圆整 / box」决策：
//    1) 圆整模式 vfcvtRm：按 opType 选 rtz(截断=1) / rod(就近奇=6) / 否则常规 rm；
//    2) 输出宽度 one-hot：由 {widen, sew} 查表得 8/16/32/64bit（widen=opType[4:3]）；
//    3) fround / froundnx / fcvtmod 的特例 opType 识别；
//    4) fmv（FMVXF）：直接把源按 sew 符号扩展为整数（不经 FPCVT），结果旁路；
//    5) 末级按 outIs32/16bits + outIsInt 决定结果是否 NaN-box / 整数符号扩展。
//
//  本包把 golden 里展平的 output1H 译码、box/扩展、rm 选择收敛为 enum + 纯函数。
// =============================================================================
package fcvt_pkg;

  localparam int XLEN = 64;

  // 浮点格式 / 元素宽度（VSew 编码）
  typedef enum logic [1:0] {
    FMT_E8  = 2'b00,
    FMT_E16 = 2'b01,   // f16 / 16bit
    FMT_E32 = 2'b10,   // f32 / 32bit
    FMT_E64 = 2'b11    // f64 / 64bit
  } fp_fmt_e;

  // 特例 opType 编码（VfcvtType / FuOpType）
  localparam logic [8:0] OP_FROUND   = 9'hC0;   // VfcvtType.fround
  localparam logic [8:0] OP_FROUNDNX = 9'hC4;   // VfcvtType.froundnx
  localparam logic [8:0] OP_FCVTMOD  = 9'h191;  // VfcvtType.fcvtmod_w_d
  localparam logic [8:0] OP_FMVXF    = 9'h180;  // FuOpType.FMVXF (fmv_x_d / fmv_x_w)

  function automatic logic [2:0] selRoundMode(input logic [2:0] inst_rm,
                                              input logic [2:0] csr_frm);
    selRoundMode = (inst_rm != 3'b111) ? inst_rm : csr_frm;
  endfunction

  // ---------------------------------------------------------------------------
  //  圆整模式选择（FCVT 专用，区别于其他 FP FU）
  // ---------------------------------------------------------------------------
  //  按 opType 低位决定圆整：
  //    · isRtz = op[2]&op[1] | isFcvtmod  → rtz(截断)，FPCVT 内部码 = 1；
  //    · isRod = op[2]&!op[1]&op[0]       → rod(就近奇)，码 = 6；
  //    · 否则                             → 常规 rm（inst rm / 动态 frm）。
  //  三者互斥，用 OR 合成（与 golden Mux1H 等价）。
  function automatic logic [2:0] cvtRoundMode(input logic [8:0] opcode,
                                              input logic        is_fcvtmod,
                                              input logic [2:0]  inst_rm,
                                              input logic [2:0]  csr_frm);
    logic is_rtz, is_rod;
    logic [2:0] frm;
    is_rtz = (opcode[2] & opcode[1]) | is_fcvtmod;
    is_rod = opcode[2] & ~opcode[1] & opcode[0];
    frm    = selRoundMode(inst_rm, csr_frm);
    // rtz→1, rod→6, 否则→frm（三者互斥，OR 拼合）
    cvtRoundMode = ({2'h0, is_rtz})
                 | (is_rod ? 3'h6 : 3'h0)
                 | ((is_rtz | is_rod) ? 3'h0 : frm);
  endfunction

  // ---------------------------------------------------------------------------
  //  输出宽度 one-hot 译码（output1H）
  // ---------------------------------------------------------------------------
  //  输入 = {widen(2bit=opType[4:3]), sew(2bit)}；输出 4bit one-hot：
  //    bit0=8bit / bit1=16bit / bit2=32bit / bit3=64bit。
  //  widen：0=同宽 single / 1=变宽 widen / 2=变窄 narrow / 3=半精度互转特例。
  //  真值表照搬 Scala 的 decoder TruthTable（未列项 → 全 0）。
  function automatic logic [3:0] decodeOutputWidth(input logic [1:0] widen,
                                                   input logic [1:0] sew);
    case ({widen, sew})
      4'b00_01: decodeOutputWidth = 4'b0010; // single  : *->16
      4'b00_10: decodeOutputWidth = 4'b0100; // single  : *->32
      4'b00_11: decodeOutputWidth = 4'b1000; // single  : *->64
      4'b01_00: decodeOutputWidth = 4'b0010; // widen   : 8->16
      4'b01_01: decodeOutputWidth = 4'b0100; // widen   : 16->32
      4'b01_10: decodeOutputWidth = 4'b1000; // widen   : 32->64
      4'b10_00: decodeOutputWidth = 4'b0001; // narrow  : 16->8
      4'b10_01: decodeOutputWidth = 4'b0010; // narrow  : 32->16
      4'b10_10: decodeOutputWidth = 4'b0100; // narrow  : 64->32
      4'b11_01: decodeOutputWidth = 4'b1000; // f16->f64/i64/ui64
      4'b11_11: decodeOutputWidth = 4'b0010; // f64->f16
      default : decodeOutputWidth = 4'b0000; // 未定义组合
    endcase
  endfunction

  // ---------------------------------------------------------------------------
  //  fmv（FMVXF）的整数化：把源按 sew 符号扩展到 64bit
  // ---------------------------------------------------------------------------
  //  fmv_x_w / fmv_x_d 把浮点位模式当整数读出，按 sew 取低段并符号扩展。
  function automatic logic [XLEN-1:0] fmvSext(input fp_fmt_e fmt,
                                              input logic [XLEN-1:0] src);
    case (fmt)
      FMT_E8  : fmvSext = {{56{src[7]}},  src[7:0]};
      FMT_E16 : fmvSext = {{48{src[15]}}, src[15:0]};
      FMT_E32 : fmvSext = {{32{src[31]}}, src[31:0]};
      FMT_E64 : fmvSext = src;
      default : fmvSext = '0;
    endcase
  endfunction

endpackage
