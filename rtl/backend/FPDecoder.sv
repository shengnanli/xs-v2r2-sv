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
    // funct7[31:27] 决定运算大类(bit26:25 是 fmt,已匹配本族)。
    //
    // 【关键:必须用 funct3/rs2 守卫只命中"合法子码"】
    //   Scala 真值表只列了每条助记符的合法 BitPat;DecodeLogic 最小化后,对
    //   每个大类里**保留/非法的子码**(off-set)统一落到 default = {tagOut=??,
    //   wflags=0},firtool 进一步把 ?? 固定成 0。即:这些保留子码 golden 恒
    //   取 typeTagOut=0(=TAG_S)、wflags=0。
    //   早先实现只看 funct7[6:2]、不看 funct3/rs2,对保留子码也按本大类输出
    //   (tagOut=selfTag/D、wflags=1),与 golden 不符 —— 随机指令下被 IT 抓出。
    //   现按各助记符 BitPat 精确加守卫:不合法子码 found=0 → 主译码回落默认
    //   (tagOut=TAG_S、wflags=0),逐位对齐 golden。
    casez (f7[6:2])
      // -- 算术(结果浮点,产生 fflags;f3=rm、rs2=源2,均不约束) -----------
      5'b00000: r.wflags = 1'b1;               // FADD
      5'b00001: r.wflags = 1'b1;               // FSUB
      5'b00010: r.wflags = 1'b1;               // FMUL
      5'b00011: r.wflags = 1'b1;               // FDIV
      // -- FSQRT(rs2 必须为 0,否则保留编码) ------------------------------
      5'b01011: begin
        if (rs2_ == 5'd0) r.wflags = 1'b1;     // FSQRT
        else              r.found  = 1'b0;
      end
      // -- 符号注入 FSGNJ/N/X(f3∈{0,1,2},结果浮点,无 fflags) ------------
      5'b00100: begin
        if (f3 inside {3'b000, 3'b001, 3'b010}) r.wflags = 1'b0;
        else                                    r.found  = 1'b0;
      end
      // -- MIN/MAX(f3∈{0,1},结果浮点,产生 fflags) -----------------------
      5'b00101: begin
        if (f3 inside {3'b000, 3'b001}) r.wflags = 1'b1; // FMIN/FMAX
        else                            r.found  = 1'b0; // f3∈{2..7} 保留
      end
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
      // -- 比较 FEQ/FLT/FLE(f3∈{0,1,2},结果整数,产生 fflags) ------------
      5'b10100: begin
        if (f3 inside {3'b000, 3'b001, 3'b010}) begin
          r.tagOut = TAG_D; r.wflags = 1'b1;
        end else r.found = 1'b0;               // f3∈{3..7} 保留
      end
      // -- FMV.X.fp / FCLASS(f3∈{0,1} 且 rs2=0,结果整数,无 fflags) ------
      5'b11100: begin
        if ((f3 inside {3'b000, 3'b001}) && rs2_ == 5'd0) begin
          r.tagOut = TAG_D; r.wflags = 1'b0;   // f3=000:FMV.X / 001:FCLASS
        end else r.found = 1'b0;
      end
      // -- FMV.fp.X(f3=000 且 rs2=0,整数->浮点搬移,结果浮点,无 fflags) --
      5'b11110: begin
        if (f3 == 3'b000 && rs2_ == 5'd0) begin
          r.tagOut = selfTag; r.wflags = 1'b0;
        end else r.found = 1'b0;
      end
      // -- FCVT.fp.int(rs2∈{0..3}=W/WU/L/LU,结果整数,产生 fflags) -------
      5'b11000: begin
        if (rs2_[4:2] == 3'b000) begin         // rs2 ∈ {0,1,2,3}
          r.tagOut = TAG_D; r.wflags = 1'b1;
        end else r.found = 1'b0;
      end
      // -- FCVT.int.fp(rs2∈{0..3}=W/WU/L/LU,结果浮点,产生 fflags) -------
      5'b11010: begin
        if (rs2_[4:2] == 3'b000) begin         // rs2 ∈ {0,1,2,3}
          r.tagOut = selfTag; r.wflags = 1'b1;
        end else r.found = 1'b0;
      end
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
      // 乘加融合:fmt2∈{S,D,H} 时结果浮点(本族)且产生 fflags。
      // fmt2=11 是非法浮点宽度(off-set);DecodeLogic 最小化后 golden 在此处
      // 恒取 typeTagOut=H(2)、wflags=0(don't-care 取值,非语义)。逐位对齐。
      if (fmt2 == 2'b11) begin
        type_tag_out = TAG_H;
        wflags       = 1'b0;
      end else begin
        type_tag_out = fmt_to_tag(fmt2);
        wflags       = 1'b1;
      end
    end else if (opcode == OPC_OP_FP && fmt2 != 2'b11) begin
      // fmt2=11 非法浮点宽度:golden 在 OP-FP 全空间恒取 typeTagOut=S(0)、
      // wflags=0(off-set 最小化值),故直接走默认,不进单族译码。
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
  //     【守卫与 typeTagOut 路径相同的考量】golden 的 fmt(vsew)真值表同样经过
  //     DecodeLogic 最小化:对各大类的保留 funct3 子码,fmt 落回默认 e64,故须按
  //     golden 实测的"会命中 vsew 表"的 funct3 集合加守卫,逐位对齐:
  //       FSGNJ/N/X (00100) : f3∈{0,1,2}
  //       FMIN/FMAX (00101) : f3∈{0,1,2,3}   (比 typeTagOut 路径多 f3=3)
  //       FEQ/FLT/FLE(10100): f3∈{0,1,2,4,5} (最小化产生的不规则集合)
  //       FADD/SUB/MUL/DIV  : f3 不约束(f3=rm)
  //       FSQRT (01011)     : rs2=0
  //       FCLASS (11100)    : f3=001 且 rs2=0(FMV.X 的 f3=000 走 sew2cvt 清单)
  function automatic logic is_fp_arith_family(input logic [4:0] f7hi, input logic [2:0] f3,
                                              input logic [4:0] rs2_);
    casez (f7hi)
      5'b00000,5'b00001,5'b00010,5'b00011: return 1'b1;            // FADD/FSUB/FMUL/FDIV
      5'b01011: return (rs2_ == 5'd0);                             // FSQRT
      5'b00100: return (f3 inside {3'b000,3'b001,3'b010});         // FSGNJ/N/X
      5'b00101: return (f3 inside {3'b000,3'b001,3'b010,3'b011});  // FMIN/FMAX
      5'b10100: return (f3 inside {3'b000,3'b001,3'b010,3'b100,3'b101}); // FEQ/FLT/FLE
      5'b11100: return (f3 == 3'b001) && (rs2_ == 5'd0);           // FCLASS(FMV.X 见 cvt 清单)
      default:  return 1'b0;
    endcase
  endfunction

  // (2) isSew2Cvt32 清单(归 e32),逐条按 {f7hi, fmt2, rs2} 识别。
  //     真值表 = 真实指令 + DecodeLogic 给保留 rs2 子码填的 don't-care(golden
  //     实测亦命中,须逐位对齐):
  //       FCVT.{W,WU,L,LU}.S (11000/S, rs2 0..3)
  //       FCVT.{W,WU}.D + FCVTMOD.W.D (11000/D, rs2∈{0,1}任意f3, 或 rs2=8&f3=1)
  //       FCVT.S.D (01000/S rs2=1) + 最小化 don't-care rs2∈{4,5}
  //       FCVT.D.S (01000/D rs2=0)
  //       FMV.X.W  (11100/S f3=0 rs2=0)
  function automatic logic in_sew2cvt32(input logic [4:0] f7hi, input logic [1:0] fmt,
                                        input logic [4:0] rs2_, input logic [2:0] f3);
    logic r;
    r = 1'b0;
    if (f7hi == 5'b11000 && fmt == 2'b00 && rs2_[4:2] == 3'b000) r = 1'b1; // FCVT.{W,WU,L,LU}.S
    if (f7hi == 5'b11000 && fmt == 2'b01 && rs2_[4:1] == 4'b0000) r = 1'b1;// FCVT.{W,WU}.D (rs2 0/1)
    if (f7hi == 5'b11000 && fmt == 2'b01 && rs2_ == 5'd8 && f3 == 3'b001) r = 1'b1; // FCVTMOD.W.D
    if (f7hi == 5'b01000 && fmt == 2'b00 && rs2_ inside {5'd1,5'd4,5'd5}) r = 1'b1; // FCVT.S.D(+dc)
    if (f7hi == 5'b01000 && fmt == 2'b01 && rs2_ == 5'd0) r = 1'b1;       // FCVT.D.S (src S)
    if (f7hi == 5'b11100 && fmt == 2'b00 && f3 == 3'b000 && rs2_ == 5'd0) r = 1'b1; // FMV.X.W
    return r;
  endfunction

  // (3) isSew2Cvt16 清单(归 e16):凡涉及 H 的 cvt/mv,含最小化 don't-care:
  //     FCVT.S.H (01000/S rs2=2) | FCVT.D.H (01000/D rs2=2) |
  //     FCVT.H.S (01000/H rs2=0) + don't-care rs2∈{4,5} |
  //     FMV.X.H (11100/H f3=0 rs2=0) |
  //     FCVT.{W,WU,L,LU}.H (11000/H rs2 0..3) | FCVT.H.{W,WU,L,LU} (11010/H rs2 0..3)
  function automatic logic in_sew2cvt16(input logic [4:0] f7hi, input logic [1:0] fmt,
                                        input logic [4:0] rs2_, input logic [2:0] f3);
    logic r;
    r = 1'b0;
    if (f7hi == 5'b01000 && fmt == 2'b00 && rs2_ == 5'd2) r = 1'b1;       // FCVT.S.H (src H)
    if (f7hi == 5'b01000 && fmt == 2'b01 && rs2_ == 5'd2) r = 1'b1;       // FCVT.D.H (src H)
    if (f7hi == 5'b01000 && fmt == 2'b10 && rs2_ inside {5'd0,5'd4,5'd5}) r = 1'b1; // FCVT.H.S(+dc)
    if (f7hi == 5'b11100 && fmt == 2'b10 && f3 == 3'b000 && rs2_ == 5'd0) r = 1'b1; // FMV.X.H
    if (f7hi == 5'b11000 && fmt == 2'b10 && rs2_[4:2] == 3'b000) r = 1'b1; // FCVT.{W,WU,L,LU}.H
    if (f7hi == 5'b11010 && fmt == 2'b10 && rs2_[4:2] == 3'b000) r = 1'b1; // FCVT.H.{W,WU,L,LU}
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
      if (is_fp_arith_family(funct7[6:2], funct3, rs2)) begin
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
