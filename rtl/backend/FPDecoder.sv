// =============================================================================
// xs_FPDecoder_core —— 香山 V2R2(昆明湖) 浮点指令译码核(可读重写)
// -----------------------------------------------------------------------------
// 对应 Scala 源:xiangshan.backend.decode.FPDecoder。纯组合叶子,无时序、无子模块。
//
// 【它在做什么】
//   译码阶段在识别出一条浮点指令后,用本模块从 32 位指令编码里抽出 5 个浮点
//   控制位,交给后续浮点 FU 与浮点->向量适配通道:
//     typeTagOut  结果的浮点类型(S/D/H;FPToInt 类按"整数侧"记为 D)
//     wflags      该指令是否会产生/写浮点异常标志(fflags)
//     typ         FCVT 的整数宽度/符号类型(= inst[21:20])
//     fmt         元素宽度(VSew 编码:FP32->e32, FP16->e16, 否则 e64)
//     rm          静态舍入模式(= inst[14:12])
//
// 【设计意图 / 为何这么写】
//   Scala 用一张 "指令 -> 9 位控制位" 真值表 + DecodeLogic 最小化,但只把其中
//   第 2 位(typeTagOut)和第 4 位(wflags)接到端口。这里**直接按"指令族 ->
//   控制位"的语义**用 casez 重建该真值表(每条 case 即一条 RISC-V 浮点助记符
//   的编码 BitPat),可读性远胜被最小化打散的与/或矩阵。
//
//   三大浮点宽度族(single/double/half)结构完全对称,差异只在:
//     - funct7 的最低位(bit25)选 S(0)/D(1),half 用 funct7[26:25]=10;
//     - 结果类型标记 typeTagOut 取 S/D/H;
//   故用一个 helper 函数 decode_op_fp(funct7,funct3,rs2) 统一处理三族。
//
//   typeTagOut 的语义:
//     - IntToFP(FMV.x.X / FCVT.fp.int):结果是浮点 → tag = 该族浮点类型;
//     - FPToInt(FMV.X.x / FCLASS / FCVT.int.fp / 比较 FEQ/FLT/FLE):结果是
//       整数 → tag = D(Scala 里 i 复用 D=1 的编码);
//     - FPToFP(SGNJ/MIN/MAX/ADD/SUB/MUL/MADD…/DIV/SQRT):结果是浮点(可能跨
//       精度,如 FCVT.S.D 结果是 S)→ tag = 结果精度。
//   wflags 的语义:会产生浮点异常标志的运算(算术/比较/带舍入的 cvt)置 1;
//     纯搬移/符号注入/分类(FMV/FSGNJ/FCLASS)不产生 → 0。
// =============================================================================
import fpdecoder_pkg::*;

module xs_FPDecoder_core (
  input  logic [31:0] instr,
  output fp_ctrl_t    fp_ctrl
);

  // ---------------------------------------------------------------------------
  // 指令字段切片(RV32 编码)。
  // ---------------------------------------------------------------------------
  wire [6:0] opcode = instr[6:0];
  wire [2:0] funct3 = instr[14:12]; // 也是 rm 字段
  wire [6:0] funct7 = instr[31:25];
  wire [4:0] rs2    = instr[24:20]; // OP-FP 里用作子操作选择(cvt 的目标类型等)
  wire [1:0] fmt2   = instr[26:25]; // funct7 低两位:00=S,01=D,10=H

  // RV opcode 常量。
  localparam logic [6:0] OPC_OP_FP = 7'b1010011; // 单源/双源浮点(ADD/MUL/CVT/CMP/MV/SGNJ…)
  localparam logic [6:0] OPC_FMADD = 7'b1000011; // FMADD.{S,D,H}
  localparam logic [6:0] OPC_FMSUB = 7'b1000111; // FMSUB
  localparam logic [6:0] OPC_FNMSUB= 7'b1001011; // FNMSUB
  localparam logic [6:0] OPC_FNMADD= 7'b1001111; // FNMADD

  // ---------------------------------------------------------------------------
  // helper:给定一族(S/D/H)的浮点类型标记 selfTag,译码 OP-FP / FMADD 系列指令,
  // 返回 {typeTagOut, wflags}。仅当指令属于该族时才返回有效值;否则 found=0。
  //   - 入参 selfTag:本族浮点类型(S=0/D=1/H=2);
  //   - typeTagOut 用 D(=TAG_D)代表"整数侧"。
  // 用一个 7 位 key = {funct7[6:2]?, rs2 子码} 还原 Scala 真值表的每一行。
  // 为保持可读,这里直接以"指令助记符"为单位列 case。
  // ---------------------------------------------------------------------------
  typedef struct packed {
    logic       found;
    logic [1:0] tagOut;
    logic       wflags;
  } dec_t;

  // 单族(给定 selfTag)的 OP-FP 译码:funct7 高 5 位(bit31..27)选大类,
  // bit26:25 已由调用方确认为本族;rs2/funct3 选具体指令。
  function automatic dec_t decode_fp_family(input logic [1:0] selfTag,
                                            input logic [6:0] f7,
                                            input logic [2:0] f3,
                                            input logic [4:0] rs2_);
    dec_t r;
    r.found  = 1'b1;
    r.tagOut = selfTag; // 默认:结果为本族浮点
    r.wflags = 1'b0;
    // funct7[31:27] 决定运算大类(bit26:25 是 fmt,已匹配本族)
    casez (f7[6:2])
      // -- 算术(结果浮点,产生 fflags) ------------------------------------
      5'b00000: r.wflags = 1'b1;               // FADD
      5'b00001: r.wflags = 1'b1;               // FSUB
      5'b00010: r.wflags = 1'b1;               // FMUL
      5'b00011: r.wflags = 1'b1;               // FDIV
      5'b01011: r.wflags = 1'b1;               // FSQRT (rs2=0)
      // -- 符号注入 FSGNJ/N/X(结果浮点,无 fflags) -----------------------
      5'b00100: r.wflags = 1'b0;               // FSGNJ.* (f3=000/001/010)
      // -- MIN/MAX(结果浮点,产生 fflags) --------------------------------
      5'b00101: r.wflags = 1'b1;               // FMIN/FMAX (f3=000/001)
      // -- 浮点->浮点跨精度转换 FCVT.fp.fp -------------------------------
      //    注意:typeTagOut/wflags 真值表里**只有 FCVT.S.D 与 FCVT.D.S**两条
      //    (Scala double 表),涉及 H 的 FCVT(H.S/S.H/D.H/H.D)不在此表内,
      //    其 typeTagOut/wflags 为 don't-care(off-set)。故仅这两条置 found。
      //    编码:fmt2=目标族,rs2[1:0]=源族。结果=目标族 → tagOut=selfTag。
      5'b01000: begin                          // FCVT.fp.fp
        if ((selfTag == TAG_S && rs2_ == 5'd1) ||  // FCVT.S.D
            (selfTag == TAG_D && rs2_ == 5'd0)) begin // FCVT.D.S
          r.wflags = 1'b1;
          r.tagOut = selfTag;
        end else begin
          r.found = 1'b0; // 涉及 H 的跨精度 cvt:typeTagOut/wflags 是 don't-care
        end
      end
      // -- 比较 FEQ/FLT/FLE(结果整数,产生 fflags) -----------------------
      5'b10100: begin r.tagOut = TAG_D; r.wflags = 1'b1; end
      // -- FMV.X.fp / FCLASS(结果整数,无 fflags) -------------------------
      5'b11100: begin r.tagOut = TAG_D; r.wflags = 1'b0; end // f3=000:FMV.X / 001:FCLASS
      // -- FMV.fp.X(整数->浮点搬移,结果浮点,无 fflags) -------------------
      5'b11110: begin r.tagOut = selfTag; r.wflags = 1'b0; end
      // -- FCVT.fp.int(浮点->整数,结果整数,产生 fflags) -----------------
      5'b11000: begin r.tagOut = TAG_D; r.wflags = 1'b1; end
      // -- FCVT.int.fp(整数->浮点,结果浮点,产生 fflags) -----------------
      5'b11010: begin r.tagOut = selfTag; r.wflags = 1'b1; end
      default: r.found = 1'b0; // 非本族已知浮点指令
    endcase
    return r;
  endfunction

  // ---------------------------------------------------------------------------
  // typeTagOut / wflags 主译码:按 opcode 分流。
  //   - FMADD 系列(4 个 opcode):必产 fflags,结果浮点,类型由 fmt2 决定。
  //   - OP-FP:按 fmt2 选族,调 decode_fp_family。
  // ---------------------------------------------------------------------------
  logic [1:0] type_tag_out;
  logic       wflags;
  dec_t       fp_dec; // OP-FP 单族译码结果(在 always_comb 内每次求值)

  // fmt2(funct7[1:0]) -> 浮点类型标记
  function automatic logic [1:0] fmt_to_tag(input logic [1:0] f);
    case (f)
      2'b00:   return TAG_S;
      2'b01:   return TAG_D;
      2'b10:   return TAG_H;
      default: return TAG_D; // 11 非法,占位
    endcase
  endfunction

  always_comb begin
    // 默认 typeTagOut:Scala default 为 "??"(don't-care),firtool 最小化后
    // 对未匹配输入恒取 S(0)。这里取 TAG_S 以与 golden off-set 取值一致。
    type_tag_out = TAG_S;
    wflags       = 1'b0;  // 默认(Scala default wflags=N=0)
    fp_dec       = '0;
    if (opcode == OPC_FMADD || opcode == OPC_FMSUB ||
        opcode == OPC_FNMADD || opcode == OPC_FNMSUB) begin
      // 乘加融合:结果浮点(本族),且都产生 fflags
      type_tag_out = fmt_to_tag(fmt2);
      wflags       = 1'b1;
    end else if (opcode == OPC_OP_FP) begin
      fp_dec = decode_fp_family(fmt_to_tag(fmt2), funct7, funct3, rs2);
      if (fp_dec.found) begin
        type_tag_out = fp_dec.tagOut;
        wflags       = fp_dec.wflags;
      end
    end
  end

  // ---------------------------------------------------------------------------
  // fmt 输出:元素宽度(VSew 编码)。
  //   Scala: fmt := Mux(isFP32||isSew2Cvt32, e32, Mux(isFP16||isSew2Cvt16, e16, e64))
  //   即:命中"FP32 族 或 归 e32 的标量 cvt" -> e32;命中"FP16 族 或 归 e16 的
  //       标量 cvt" -> e16;否则(含 FP64 与未归类的 cvt)-> e64(默认)。
  //   注意这两类集合是 Scala 手列的**显式指令清单**,不是规整的位规则
  //   (例如 FCVT.D.S 归 e32、FCVT.L.D 归 e64、FCVT.S.W 归 e64),故这里
  //   忠实地按清单判定。每条 case 用 {funct7[6:2], fmt2, rs2} 的签名识别一条指令。
  // ---------------------------------------------------------------------------
  // (1) "进浮点运算 FU"的算术/比较/sgnj/min/max/class 族(isFP{16,32,64}Instr):
  //     这些指令宽度直接取 fmt2(S->e32, H->e16, D->e64),含 FMADD 系列。
  function automatic logic is_fp_arith_family(input logic [4:0] f7hi, input logic [2:0] f3);
    casez (f7hi)
      5'b00000,5'b00001,5'b00010,5'b00011, // FADD/FSUB/FMUL/FDIV
      5'b01011,                            // FSQRT
      5'b00100,                            // FSGNJ/N/X
      5'b00101,                            // FMIN/FMAX
      5'b10100: return 1'b1;               // FEQ/FLT/FLE
      5'b11100: return (f3 == 3'b001);     // FCLASS 计入;FMV.X.fp(f3=000)不计入
      default:  return 1'b0;
    endcase
  endfunction

  // (2) isSew2Cvt32 清单(归 e32),逐条按 {f7hi, fmt2, rs2} 识别:
  //     FCVT.{W,WU,L,LU}.S | FCVT.{W,WU}.D | FCVT.S.D | FCVT.D.S | FMV.X.W | FCVTMOD.W.D
  function automatic logic in_sew2cvt32(input logic [4:0] f7hi, input logic [1:0] fmt,
                                        input logic [4:0] rs2_, input logic [2:0] f3);
    logic r;
    r = 1'b0;
    if (f7hi == 5'b11000 && fmt == 2'b00) r = 1'b1;                       // FCVT.{W,WU,L,LU}.S (rs2 0..3)
    if (f7hi == 5'b11000 && fmt == 2'b01 && rs2_[4:1] == 4'b0000) r = 1'b1;// FCVT.{W,WU}.D (rs2 0/1)
    if (f7hi == 5'b01000 && fmt == 2'b00 && rs2_ == 5'd1) r = 1'b1;       // FCVT.S.D (src D)
    if (f7hi == 5'b01000 && fmt == 2'b01 && rs2_ == 5'd0) r = 1'b1;       // FCVT.D.S (src S)
    if (f7hi == 5'b11100 && fmt == 2'b00 && f3 == 3'b000) r = 1'b1;       // FMV.X.W
    if (f7hi == 5'b11000 && fmt == 2'b01 && rs2_ == 5'd8 && f3 == 3'b001) r = 1'b1; // FCVTMOD.W.D
    return r;
  endfunction

  // (3) isSew2Cvt16 清单(归 e16):凡涉及 H(fmt2=10 的 cvt/mv,或源/目标为 H):
  //     FCVT.S.H | FCVT.H.S | FCVT.D.H | FMV.X.H | FCVT.{W,L,WU,LU}.H |
  //     FCVT.H.{W,L,WU,LU}
  function automatic logic in_sew2cvt16(input logic [4:0] f7hi, input logic [1:0] fmt,
                                        input logic [4:0] rs2_, input logic [2:0] f3);
    logic r;
    r = 1'b0;
    if (f7hi == 5'b01000 && fmt == 2'b00 && rs2_ == 5'd2) r = 1'b1;       // FCVT.S.H (src H)
    if (f7hi == 5'b01000 && fmt == 2'b10 && rs2_ == 5'd0) r = 1'b1;       // FCVT.H.S (dst H)
    if (f7hi == 5'b01000 && fmt == 2'b01 && rs2_ == 5'd2) r = 1'b1;       // FCVT.D.H (src H)
    if (f7hi == 5'b11100 && fmt == 2'b10 && f3 == 3'b000) r = 1'b1;       // FMV.X.H
    if (f7hi == 5'b11000 && fmt == 2'b10) r = 1'b1;                       // FCVT.{W,WU,L,LU}.H (src H)
    if (f7hi == 5'b11010 && fmt == 2'b10) r = 1'b1;                       // FCVT.H.{W,WU,L,LU} (dst H)
    return r;
  endfunction

  logic is_fp16, is_fp32;
  always_comb begin
    is_fp32 = 1'b0;
    is_fp16 = 1'b0;
    if (opcode == OPC_FMADD || opcode == OPC_FMSUB ||
        opcode == OPC_FNMADD || opcode == OPC_FNMSUB) begin
      // FMADD 系列属 FP{32,16,64}Instr,宽度取 fmt2
      is_fp32 = (fmt2 == 2'b00);
      is_fp16 = (fmt2 == 2'b10);
    end else if (opcode == OPC_OP_FP) begin
      if (is_fp_arith_family(funct7[6:2], funct3)) begin
        is_fp32 = (fmt2 == 2'b00);
        is_fp16 = (fmt2 == 2'b10);
      end else begin
        is_fp32 = in_sew2cvt32(funct7[6:2], fmt2, rs2, funct3);
        is_fp16 = in_sew2cvt16(funct7[6:2], fmt2, rs2, funct3);
      end
    end
  end

  // e32 优先于 e16(与 Scala 的嵌套 Mux 顺序一致)。
  wire [1:0] fmt_out = is_fp32 ? SEW_E32 : (is_fp16 ? SEW_E16 : SEW_E64);

  // ---------------------------------------------------------------------------
  // 端口聚合输出。
  // ---------------------------------------------------------------------------
  assign fp_ctrl.typeTagOut = type_tag_out;
  assign fp_ctrl.wflags     = wflags;
  assign fp_ctrl.typ        = instr[21:20]; // TYP
  assign fp_ctrl.fmt        = fmt_out;
  assign fp_ctrl.rm         = instr[14:12]; // RM

endmodule
