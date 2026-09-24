// =============================================================================
// FusionDecoder.sv —— 宏指令融合译码器（把相邻两条简单指令识别成一条内部融合指令）
// -----------------------------------------------------------------------------
// 设计源: XiangShan src/main/scala/xiangshan/backend/decode/FusionDecoder.scala
// golden: G1-canonical/golden-rtl/FusionDecoder.sv（firtool 展平，2539 行 / 87 端口）
//
// 【它在 CtrlBlock 里的位置】
//   DecodeStage 每拍从 IBuffer 收 6 条指令(io_in)。本模块同拍看**相邻两条**
//   (pair i = in[i], in[i+1]，i = 0..4)的 32 位原始指令，判断它们是否属于 28 种
//   已知融合模式（slli+srli → zext.w、slli+add → shNadd、lui+addi → lui32 …）。
//   判断结果**打一拍**（与 DecodeUnit 译码同步），T1 拍给 DecodeStage 的 io.out：
//     · out[i]  ：第 i 条指令的控制信号要改成什么（fuType/fuOpType/lsrc2/src2Type/selImm）
//     · info[i] ：第 i 条的 src2 从哪来（rs1/rs2/zero，供 Rename 改读口）
//     · clear[i+1]：第 i+1 条被吞掉，要作废
//
// 【每对一套流水寄存器（golden 里 5 套展平，这里 generate 5 份）】
//   fire[i]          = in[i].valid & inReady[i]
//   instrPairValid[i]: RegEnable(in[i].valid & in[i+1].valid, inReady[i])，异步复位 0
//   fusionVec[i]     : RegEnable(28 路匹配位, fire[i])，无复位
//   notHint[i]       : 两条 rd 都不为 0（rd=0 的是 HINT，不融合），无复位
//   enabled[i]       : RegEnable(~disableFusion, fire[i])
//   destToRs1_q[i]   : 第一条的 rd 是不是第二条的 rs1（决定 lsrc2 选 rs2 还是 rs1）
//   lsrc2Mux_q[i]    : 融合后的 lsrc2 = destToRs1 ? rs2(b) : rs1(b)
//
// 【输出规则（照 Chisel 的 connectByInt/connectByUInt/connectByUIntFunc）】
//   · fuOpType：26 种模式给常量 op（Mux1H = 掩码或），Logiclsb/LogicZexth 两种由第一条
//     指令的 fuOpType 现算：{3'b110, fuOpType[3:1], 0/1}，它们优先。
//   · fuType 只有 Mulw7 会改（ALU→MDU），src2Type 15 种模式会改，selImm 只 Lui32/Lui32w。
//     这三个 bits 端口在 golden 里被 firtool 折成常量后删掉了，wrapper 端口表照 golden。
//   · clear 链：clear[i+1] = pairValid & ~clear[i] & |fusionVec & notHint & enabled，
//     即上一对已经把 in[i] 吞掉时，这一对不再成立。clear[0] 恒 0。
//
// 【照抄 golden 的几处怪癖（bug-for-bug）】
//   * destToRs1 被 RegEnable 了两份（io_info_rs2FromRs1 与 rs2FromRs2 各一份），
//     golden 里是两个内容相同的寄存器，这里也保留两份（rs2FromRs1_q / rs2FromRs2_q）。
//   * lastFire[i] = RegNext(fire[i]) 与 fireDelayed_perf[i] = RegNext(fire[i]) 是
//     XSPerfAccumulate 的打拍寄存器，本配置下 perf 段无任何读者（cone-dead），
//     golden 照样保留，这里对称保留，FM 用 vmucp 把它们当比对点证（见
//     verif/fm_target_config/FusionDecoder.tcl 与 verif/ut/FusionDecoder/fm_pins.tcl）。
//   * XSError(PopCount(fusionVec) > 1) 是 `ifndef SYNTHESIS 断言，不在本重写内。
//
// 【文件结构】package xs_fusiondecoder_pkg（模式编号/常量/匹配函数）
//            → 核 xs_FusionDecoder_core（数组端口）→ golden 同名 wrapper FusionDecoder
// =============================================================================
package xs_fusiondecoder_pkg;
  localparam int unsigned DECODE_WIDTH = 6;
  localparam int unsigned N_PAIR       = DECODE_WIDTH - 1;   // 5 对相邻指令
  localparam int unsigned N_CASE       = 28;                 // 28 种融合模式

  // ---- 28 种模式的编号（顺序 = Chisel fusionList 的顺序，也是 golden fusionVec_k 的 k）----
  localparam int F_ADDUW      = 0;   // slli 32 + srli 32      -> add.uw  (zext.w)
  localparam int F_ZEXTH      = 1;   // slli 48 + srli 48      -> packw   (zext.h)
  localparam int F_ZEXTH1     = 2;   // slliw 16 + srliw 16    -> packw   (zext.h)
  localparam int F_SEXTH      = 3;   // slliw 16 + sraiw 16    -> sext.h
  localparam int F_SH1ADD     = 4;   // slli 1 + add           -> sh1add
  localparam int F_SH2ADD     = 5;   // slli 2 + add           -> sh2add
  localparam int F_SH3ADD     = 6;   // slli 3 + add           -> sh3add
  localparam int F_SZEWL1     = 7;   // slli 32 + srli 31      -> szewl1
  localparam int F_SZEWL2     = 8;   // slli 32 + srli 30      -> szewl2
  localparam int F_SZEWL3     = 9;   // slli 32 + srli 29      -> szewl3
  localparam int F_BYTE2      = 10;  // srli 8 + andi 255      -> byte2
  localparam int F_SH4ADD     = 11;  // slli 4 + add           -> sh4add
  localparam int F_SR29ADD    = 12;  // srli 29 + add          -> sr29add
  localparam int F_SR30ADD    = 13;  // srli 30 + add          -> sr30add
  localparam int F_SR31ADD    = 14;  // srli 31 + add          -> sr31add
  localparam int F_SR32ADD    = 15;  // srli 32 + add          -> sr32add
  localparam int F_ODDADD     = 16;  // andi 1 + add           -> oddadd
  localparam int F_ODDADDW    = 17;  // andi 1 + addw          -> oddaddw
  localparam int F_ORH48      = 18;  // andi -256 + or         -> orh48
  localparam int F_MULW7      = 19;  // andi 127 + mulw        -> mulw7 (fuType 改成 MDU)
  localparam int F_ADDWBYTE   = 20;  // addw/addiw + andi 255  -> addwbyte
  localparam int F_ADDWBIT    = 21;  // addw/addiw + andi 1    -> addwbit
  localparam int F_ADDWZEXTH  = 22;  // addw/addiw + zext.h    -> addwzexth
  localparam int F_ADDWSEXTH  = 23;  // addw/addiw + sext.h    -> addwsexth
  localparam int F_LOGICLSB   = 24;  // and/or/xor(i)/orc.b + andi 1  -> logicToLsb(op)
  localparam int F_LOGICZEXTH = 25;  // and/or/xor(i)/orc.b + zext.h  -> logicToZexth(op)
  localparam int F_LUI32      = 26;  // lui + addi             -> lui32add  (selImm=IMM_LUI32)
  localparam int F_LUI32W     = 27;  // lui + addiw            -> lui32addw (selImm=IMM_LUI32)

  // ---- 融合后的 ALU/MDU fuOpType 低 7 位（xiangshan/package.scala 的 ALUOpType/MDUOpType）----
  localparam logic [6:0] OP_ADDUW     = 7'h20;
  localparam logic [6:0] OP_PACKW     = 7'h4B;   // zext.h
  localparam logic [6:0] OP_SEXTH     = 7'h4A;
  localparam logic [6:0] OP_SH1ADD    = 7'h29;
  localparam logic [6:0] OP_SH2ADD    = 7'h2B;
  localparam logic [6:0] OP_SH3ADD    = 7'h2D;
  localparam logic [6:0] OP_SZEWL1    = 7'h58;
  localparam logic [6:0] OP_SZEWL2    = 7'h59;
  localparam logic [6:0] OP_SZEWL3    = 7'h5A;
  localparam logic [6:0] OP_BYTE2     = 7'h5B;
  localparam logic [6:0] OP_SH4ADD    = 7'h2F;
  localparam logic [6:0] OP_SR29ADD   = 7'h24;
  localparam logic [6:0] OP_SR30ADD   = 7'h25;
  localparam logic [6:0] OP_SR31ADD   = 7'h26;
  localparam logic [6:0] OP_SR32ADD   = 7'h27;
  localparam logic [6:0] OP_ODDADD    = 7'h22;
  localparam logic [6:0] OP_ODDADDW   = 7'h11;
  localparam logic [6:0] OP_ORH48     = 7'h53;
  localparam logic [6:0] OP_MULW7     = 7'h0C;   // MDUOpType.mulw7
  localparam logic [6:0] OP_ADDWBYTE  = 7'h15;
  localparam logic [6:0] OP_ADDWBIT   = 7'h14;
  localparam logic [6:0] OP_ADDWZEXTH = 7'h16;
  localparam logic [6:0] OP_ADDWSEXTH = 7'h17;
  localparam logic [6:0] OP_LUI32ADD  = 7'h23;
  localparam logic [6:0] OP_LUI32ADDW = 7'h13;
  localparam logic [3:0] IMM_LUI32    = 4'hB;    // SelImm.IMM_LUI32

  // 哪些模式改 src2Type（thisInstr/fusedInstr 的 src2 类型不同：I 型 -> R 型 或反过来）
  localparam logic [N_CASE-1:0] SRC2TYPE_CHANGE_MASK =
      (28'h1 << F_ADDUW)   | (28'h1 << F_ZEXTH)   | (28'h1 << F_ZEXTH1)
    | (28'h1 << F_SH1ADD)  | (28'h1 << F_SH2ADD)  | (28'h1 << F_SH3ADD)
    | (28'h1 << F_SH4ADD)  | (28'h1 << F_SR29ADD) | (28'h1 << F_SR30ADD)
    | (28'h1 << F_SR31ADD) | (28'h1 << F_SR32ADD) | (28'h1 << F_ODDADD)
    | (28'h1 << F_ODDADDW) | (28'h1 << F_ORH48)   | (28'h1 << F_MULW7);
  // 哪些模式的 lsrc2 要清零（第二条是移位立即数，融合后 src2 = zero）
  localparam logic [N_CASE-1:0] LSRC2_ZERO_MASK =
      (28'h1 << F_ADDUW) | (28'h1 << F_ZEXTH) | (28'h1 << F_ZEXTH1) | (28'h1 << F_SEXTH);
  // 哪些模式的 lsrc2 要从第二条的 rs1/rs2 里选（第二条是 R 型）
  localparam logic [N_CASE-1:0] LSRC2_MUX_MASK =
      (28'h1 << F_SH1ADD)  | (28'h1 << F_SH2ADD)  | (28'h1 << F_SH3ADD)
    | (28'h1 << F_SH4ADD)  | (28'h1 << F_SR29ADD) | (28'h1 << F_SR30ADD)
    | (28'h1 << F_SR31ADD) | (28'h1 << F_SR32ADD) | (28'h1 << F_ODDADD)
    | (28'h1 << F_ODDADDW) | (28'h1 << F_ORH48)   | (28'h1 << F_MULW7);

  // ---- 给 DecodeStage 的替换包（Chisel FusionDecodeReplace；bits 全是常量的
  //      fuType / src2Type 在 golden 里没有端口，只剩 valid）----
  typedef struct packed {
    logic       valid;             // 本对成立且未被上一对吞掉
    logic       fuType_valid;      // 只有 mulw7：ALU -> MDU
    logic       fuOpType_valid;    // 28 种模式都改 fuOpType
    logic [8:0] fuOpType;
    logic       lsrc2_valid;
    logic [5:0] lsrc2;
    logic       src2Type_valid;
    logic       selImm_valid;
    logic [3:0] selImm;
  } fusion_replace_t;

  typedef struct packed {
    logic rs2FromRs1;
    logic rs2FromRs2;
    logic rs2FromZero;
  } fusion_info_t;

  // ---- RV64 指令字段 ----
  function automatic logic [4:0]  rd_of  (input logic [31:0] i); return i[11:7];  endfunction
  function automatic logic [4:0]  rs1_of (input logic [31:0] i); return i[19:15]; endfunction
  function automatic logic [4:0]  rs2_of (input logic [31:0] i); return i[24:20]; endfunction
  function automatic logic [5:0]  shamt6 (input logic [31:0] i); return i[25:20]; endfunction
  function automatic logic [4:0]  shamt5 (input logic [31:0] i); return i[24:20]; endfunction
  function automatic logic [11:0] imm12  (input logic [31:0] i); return i[31:20]; endfunction

  // ---- 指令模式（BitPat 按 golden 的取位方式比较）----
  // I 型移位（RV64 shamt 6 位）：{funct6, funct3, opcode}
  function automatic logic is_slli (input logic [31:0] i); return {i[31:26], i[14:12], i[6:0]} == {6'b000000, 3'b001, 7'h13}; endfunction
  function automatic logic is_srli (input logic [31:0] i); return {i[31:26], i[14:12], i[6:0]} == {6'b000000, 3'b101, 7'h13}; endfunction
  // 字移位（shamt 5 位）/ R 型：{funct7, funct3, opcode}
  function automatic logic is_slliw(input logic [31:0] i); return {i[31:25], i[14:12], i[6:0]} == {7'b0000000, 3'b001, 7'h1B}; endfunction
  function automatic logic is_srliw(input logic [31:0] i); return {i[31:25], i[14:12], i[6:0]} == {7'b0000000, 3'b101, 7'h1B}; endfunction
  function automatic logic is_sraiw(input logic [31:0] i); return {i[31:25], i[14:12], i[6:0]} == {7'b0100000, 3'b101, 7'h1B}; endfunction
  function automatic logic is_add  (input logic [31:0] i); return {i[31:25], i[14:12], i[6:0]} == {7'b0000000, 3'b000, 7'h33}; endfunction
  function automatic logic is_addw (input logic [31:0] i); return {i[31:25], i[14:12], i[6:0]} == {7'b0000000, 3'b000, 7'h3B}; endfunction
  function automatic logic is_mulw (input logic [31:0] i); return {i[31:25], i[14:12], i[6:0]} == {7'b0000001, 3'b000, 7'h3B}; endfunction
  function automatic logic is_or   (input logic [31:0] i); return {i[31:25], i[14:12], i[6:0]} == {7'b0000000, 3'b110, 7'h33}; endfunction
  function automatic logic is_xor  (input logic [31:0] i); return {i[31:25], i[14:12], i[6:0]} == {7'b0000000, 3'b100, 7'h33}; endfunction
  function automatic logic is_and  (input logic [31:0] i); return {i[31:25], i[14:12], i[6:0]} == {7'b0000000, 3'b111, 7'h33}; endfunction
  // I 型算术：{funct3, opcode}
  function automatic logic is_andi (input logic [31:0] i); return {i[14:12], i[6:0]} == {3'b111, 7'h13}; endfunction
  function automatic logic is_ori  (input logic [31:0] i); return {i[14:12], i[6:0]} == {3'b110, 7'h13}; endfunction
  function automatic logic is_xori (input logic [31:0] i); return {i[14:12], i[6:0]} == {3'b100, 7'h13}; endfunction
  function automatic logic is_addi (input logic [31:0] i); return {i[14:12], i[6:0]} == {3'b000, 7'h13}; endfunction
  function automatic logic is_addiw(input logic [31:0] i); return {i[14:12], i[6:0]} == {3'b000, 7'h1B}; endfunction
  // 整个高 12 位固定的：{imm12, funct3, opcode}
  function automatic logic is_zexth(input logic [31:0] i); return {i[31:20], i[14:12], i[6:0]} == {12'h080, 3'b100, 7'h3B}; endfunction
  function automatic logic is_sexth(input logic [31:0] i); return {i[31:20], i[14:12], i[6:0]} == {12'h605, 3'b001, 7'h13}; endfunction
  function automatic logic is_orcb (input logic [31:0] i); return {i[31:20], i[14:12], i[6:0]} == {12'h287, 3'b101, 7'h13}; endfunction
  function automatic logic is_lui  (input logic [31:0] i); return i[6:0] == 7'h37; endfunction
  // Logiclsb/LogicZexth 的第一条：and/andi/or/ori/xor/xori/orc.b 之一
  function automatic logic is_logic(input logic [31:0] i);
    return is_orcb(i) | is_xor(i) | is_xori(i) | is_or(i) | is_ori(i) | is_and(i) | is_andi(i);
  endfunction

  // ---- 28 路匹配：a = 第一条, b = 第二条 ----
  function automatic logic [N_CASE-1:0] fusion_detect(input logic [31:0] a, input logic [31:0] b);
    logic [N_CASE-1:0] v;
    logic same_dest, dest_to_rs1, dest_to_rs2, rs1_ne_rs2;
    logic base_rs1;     // 「同 rd 且 rd == rs1(b)」：第二条是 I 型时的公共条件
    logic base_mux;     // 「同 rd 且 rd 是 rs1(b) 或 rs2(b) 且两者不同」：第二条是 R 型时
    same_dest   = rd_of(a) == rd_of(b);
    dest_to_rs1 = rd_of(a) == rs1_of(b);
    dest_to_rs2 = rd_of(a) == rs2_of(b);
    rs1_ne_rs2  = rs1_of(b) != rs2_of(b);
    base_rs1    = same_dest & dest_to_rs1;
    base_mux    = rs1_ne_rs2 & same_dest & (dest_to_rs1 | dest_to_rs2);
    v[F_ADDUW]      = is_slli(a)  & shamt6(a) == 6'd32 & is_srli(b)  & shamt6(b) == 6'd32 & base_rs1;
    v[F_ZEXTH]      = is_slli(a)  & shamt6(a) == 6'd48 & is_srli(b)  & shamt6(b) == 6'd48 & base_rs1;
    v[F_ZEXTH1]     = is_slliw(a) & shamt5(a) == 5'd16 & is_srliw(b) & shamt5(b) == 5'd16 & base_rs1;
    v[F_SEXTH]      = is_slliw(a) & shamt5(a) == 5'd16 & is_sraiw(b) & shamt5(b) == 5'd16 & base_rs1;
    v[F_SH1ADD]     = is_slli(a)  & shamt6(a) == 6'd1  & is_add(b)  & base_mux;
    v[F_SH2ADD]     = is_slli(a)  & shamt6(a) == 6'd2  & is_add(b)  & base_mux;
    v[F_SH3ADD]     = is_slli(a)  & shamt6(a) == 6'd3  & is_add(b)  & base_mux;
    v[F_SZEWL1]     = is_slli(a)  & shamt6(a) == 6'd32 & is_srli(b)  & shamt6(b) == 6'd31 & base_rs1;
    v[F_SZEWL2]     = is_slli(a)  & shamt6(a) == 6'd32 & is_srli(b)  & shamt6(b) == 6'd30 & base_rs1;
    v[F_SZEWL3]     = is_slli(a)  & shamt6(a) == 6'd32 & is_srli(b)  & shamt6(b) == 6'd29 & base_rs1;
    v[F_BYTE2]      = is_srli(a)  & shamt6(a) == 6'd8  & is_andi(b)  & imm12(b) == 12'd255 & base_rs1;
    v[F_SH4ADD]     = is_slli(a)  & shamt6(a) == 6'd4  & is_add(b)  & base_mux;
    v[F_SR29ADD]    = is_srli(a)  & shamt6(a) == 6'd29 & is_add(b)  & base_mux;
    v[F_SR30ADD]    = is_srli(a)  & shamt6(a) == 6'd30 & is_add(b)  & base_mux;
    v[F_SR31ADD]    = is_srli(a)  & shamt6(a) == 6'd31 & is_add(b)  & base_mux;
    v[F_SR32ADD]    = is_srli(a)  & shamt6(a) == 6'd32 & is_add(b)  & base_mux;
    v[F_ODDADD]     = is_andi(a)  & imm12(a) == 12'd1  & is_add(b)  & base_mux;
    v[F_ODDADDW]    = is_andi(a)  & imm12(a) == 12'd1  & is_addw(b) & base_mux;
    v[F_ORH48]      = is_andi(a)  & imm12(a) == 12'hF00 & is_or(b)  & base_mux;
    v[F_MULW7]      = is_andi(a)  & imm12(a) == 12'd127 & is_mulw(b) & base_mux;
    v[F_ADDWBYTE]   = (is_addiw(a) | is_addw(a)) & is_andi(b) & imm12(b) == 12'd255 & base_rs1;
    v[F_ADDWBIT]    = (is_addiw(a) | is_addw(a)) & is_andi(b) & imm12(b) == 12'd1   & base_rs1;
    v[F_ADDWZEXTH]  = (is_addiw(a) | is_addw(a)) & is_zexth(b) & base_rs1;
    v[F_ADDWSEXTH]  = (is_addiw(a) | is_addw(a)) & is_sexth(b) & base_rs1;
    v[F_LOGICLSB]   = is_logic(a) & is_andi(b) & imm12(b) == 12'd1 & base_rs1;
    v[F_LOGICZEXTH] = is_logic(a) & is_zexth(b) & base_rs1;
    v[F_LUI32]      = is_lui(a) & is_addi(b)  & base_rs1;
    v[F_LUI32W]     = is_lui(a) & is_addiw(b) & base_rs1;
    return v;
  endfunction
endpackage

module xs_FusionDecoder_core
  import xs_fusiondecoder_pkg::*;
(
  input  logic                              clock,
  input  logic                              reset,
  input  logic                              disableFusion,
  input  logic [DECODE_WIDTH-1:0]           in_valid,
  input  logic [DECODE_WIDTH-1:0][31:0]     in_instr,
  input  logic [N_PAIR-1:0]                 in_ready,      // DecodeStage 给 in[i] 的 ready
  input  logic [N_PAIR-1:0][8:0]            dec_fuOpType,  // T1: DecodeUnit 译出的第 i 条 fuOpType
  output fusion_replace_t [N_PAIR-1:0]      out,
  output fusion_info_t    [N_PAIR-1:0]      info,
  output logic [DECODE_WIDTH-1:0]           clear          // clear[0] 恒 0
);

  // ---- T0 -> T1 流水寄存器（每对一套）----
  logic [N_PAIR-1:0]              fire;
  logic [N_PAIR-1:0]              instrPairValid;    // 异步复位 0，使能 in_ready[i]
  logic [N_PAIR-1:0][N_CASE-1:0]  fusionVec;         // 以下无复位，使能 fire[i]
  logic [N_PAIR-1:0]              notHint;
  logic [N_PAIR-1:0]              enabled;
  logic [N_PAIR-1:0]              rs2FromRs1_q;      // = destToRs1（两份，见文件头怪癖）
  logic [N_PAIR-1:0]              rs2FromRs2_q;      // = destToRs1
  logic [N_PAIR-1:0][4:0]         lsrc2Mux_q;        // destToRs1 ? rs2(b) : rs1(b)
  logic [N_PAIR-1:0]              lastFire;          // RegNext(fire)，perf 打拍，无读者
  logic [N_PAIR-1:0]              fireDelayed_perf;  // RegNext(fire)，perf "fused_instr" 打拍，无读者

  assign clear[0] = 1'b0;

  for (genvar i = 0; i < N_PAIR; i++) begin : g_pair
    logic [31:0] instr_a, instr_b;
    assign instr_a = in_instr[i];
    assign instr_b = in_instr[i+1];
    assign fire[i] = in_valid[i] & in_ready[i];

    always_ff @(posedge clock or posedge reset) begin
      if (reset)            instrPairValid[i] <= 1'b0;
      else if (in_ready[i]) instrPairValid[i] <= in_valid[i] & in_valid[i+1];
    end

    always_ff @(posedge clock) begin
      if (fire[i]) begin
        fusionVec[i]    <= fusion_detect(instr_a, instr_b);
        notHint[i]      <= (|rd_of(instr_b)) & (|rd_of(instr_a));
        enabled[i]      <= ~disableFusion;
        rs2FromRs1_q[i] <= rd_of(instr_a) == rs1_of(instr_b);
        rs2FromRs2_q[i] <= rd_of(instr_a) == rs1_of(instr_b);
        lsrc2Mux_q[i]   <= (rd_of(instr_a) == rs1_of(instr_b)) ? rs2_of(instr_b) : rs1_of(instr_b);
      end
      lastFire[i]         <= fire[i];
      fireDelayed_perf[i] <= fire[i];
    end

    // ---- T1 输出 ----
    logic [N_CASE-1:0] v;
    logic              src2WithZero, src2WithMux;
    logic [6:0]        constRepl;       // Mux1H(常量 op)：掩码或
    logic [6:0]        logicRepl;       // Logiclsb / LogicZexth：由第一条的 fuOpType 现算
    assign v = fusionVec[i];
    assign src2WithZero = |(v & LSRC2_ZERO_MASK);
    assign src2WithMux  = |(v & LSRC2_MUX_MASK);

    assign clear[i+1] = instrPairValid[i] & ~clear[i] & (|v) & notHint[i] & enabled[i];

    assign constRepl =
        ({7{v[F_ADDUW]}}                    & OP_ADDUW)
      | ({7{v[F_ZEXTH] | v[F_ZEXTH1]}}      & OP_PACKW)
      | ({7{v[F_SEXTH]}}                    & OP_SEXTH)
      | ({7{v[F_SH1ADD]}}                   & OP_SH1ADD)
      | ({7{v[F_SH2ADD]}}                   & OP_SH2ADD)
      | ({7{v[F_SH3ADD]}}                   & OP_SH3ADD)
      | ({7{v[F_SZEWL1]}}                   & OP_SZEWL1)
      | ({7{v[F_SZEWL2]}}                   & OP_SZEWL2)
      | ({7{v[F_SZEWL3]}}                   & OP_SZEWL3)
      | ({7{v[F_BYTE2]}}                    & OP_BYTE2)
      | ({7{v[F_SH4ADD]}}                   & OP_SH4ADD)
      | ({7{v[F_SR29ADD]}}                  & OP_SR29ADD)
      | ({7{v[F_SR30ADD]}}                  & OP_SR30ADD)
      | ({7{v[F_SR31ADD]}}                  & OP_SR31ADD)
      | ({7{v[F_SR32ADD]}}                  & OP_SR32ADD)
      | ({7{v[F_ODDADD]}}                   & OP_ODDADD)
      | ({7{v[F_ODDADDW]}}                  & OP_ODDADDW)
      | ({7{v[F_ORH48]}}                    & OP_ORH48)
      | ({7{v[F_MULW7]}}                    & OP_MULW7)
      | ({7{v[F_ADDWBYTE]}}                 & OP_ADDWBYTE)
      | ({7{v[F_ADDWBIT]}}                  & OP_ADDWBIT)
      | ({7{v[F_ADDWZEXTH]}}                & OP_ADDWZEXTH)
      | ({7{v[F_ADDWSEXTH]}}                & OP_ADDWSEXTH)
      | ({7{v[F_LUI32]}}                    & OP_LUI32ADD)
      | ({7{v[F_LUI32W]}}                   & OP_LUI32ADDW);
    assign logicRepl =
        ({7{v[F_LOGICLSB]}}   & {3'b110, dec_fuOpType[i][3:1], 1'b0})
      | ({7{v[F_LOGICZEXTH]}} & {3'b110, dec_fuOpType[i][3:1], 1'b1});

    assign out[i].valid          = clear[i+1];
    assign out[i].fuType_valid   = v[F_MULW7];
    assign out[i].fuOpType_valid = |v;
    assign out[i].fuOpType       = {2'b00, (v[F_LOGICLSB] | v[F_LOGICZEXTH]) ? logicRepl : constRepl};
    assign out[i].lsrc2_valid    = enabled[i] & (src2WithMux | src2WithZero);
    assign out[i].lsrc2          = src2WithMux ? {1'b0, lsrc2Mux_q[i]} : 6'h0;
    assign out[i].src2Type_valid = |(v & SRC2TYPE_CHANGE_MASK);
    assign out[i].selImm_valid   = v[F_LUI32] | v[F_LUI32W];
    assign out[i].selImm         = (v[F_LUI32] | v[F_LUI32W]) ? IMM_LUI32 : 4'h0;

    assign info[i].rs2FromRs1  = enabled[i] & src2WithMux & ~rs2FromRs1_q[i];
    assign info[i].rs2FromRs2  = enabled[i] & src2WithMux &  rs2FromRs2_q[i];
    assign info[i].rs2FromZero = enabled[i] & src2WithZero;
  end

endmodule

// -----------------------------------------------------------------------------
// wrapper：端口与 golden FusionDecoder 逐位同名同序，只做数组打包/拆包
// -----------------------------------------------------------------------------
module FusionDecoder
  import xs_fusiondecoder_pkg::*;
(
  input         clock,
  input         reset,
  input         io_disableFusion,
  input         io_in_0_valid,
  input  [31:0] io_in_0_bits,
  input         io_in_1_valid,
  input  [31:0] io_in_1_bits,
  input         io_in_2_valid,
  input  [31:0] io_in_2_bits,
  input         io_in_3_valid,
  input  [31:0] io_in_3_bits,
  input         io_in_4_valid,
  input  [31:0] io_in_4_bits,
  input         io_in_5_valid,
  input  [31:0] io_in_5_bits,
  input         io_inReady_0,
  input         io_inReady_1,
  input         io_inReady_2,
  input         io_inReady_3,
  input         io_inReady_4,
  input  [8:0]  io_dec_0_fuOpType,
  input  [8:0]  io_dec_1_fuOpType,
  input  [8:0]  io_dec_2_fuOpType,
  input  [8:0]  io_dec_3_fuOpType,
  input  [8:0]  io_dec_4_fuOpType,
  output        io_out_0_valid,
  output        io_out_0_bits_fuType_valid,
  output        io_out_0_bits_fuOpType_valid,
  output [8:0]  io_out_0_bits_fuOpType_bits,
  output        io_out_0_bits_lsrc2_valid,
  output [5:0]  io_out_0_bits_lsrc2_bits,
  output        io_out_0_bits_src2Type_valid,
  output        io_out_0_bits_selImm_valid,
  output [3:0]  io_out_0_bits_selImm_bits,
  output        io_out_1_valid,
  output        io_out_1_bits_fuType_valid,
  output        io_out_1_bits_fuOpType_valid,
  output [8:0]  io_out_1_bits_fuOpType_bits,
  output        io_out_1_bits_lsrc2_valid,
  output [5:0]  io_out_1_bits_lsrc2_bits,
  output        io_out_1_bits_src2Type_valid,
  output        io_out_1_bits_selImm_valid,
  output [3:0]  io_out_1_bits_selImm_bits,
  output        io_out_2_valid,
  output        io_out_2_bits_fuType_valid,
  output        io_out_2_bits_fuOpType_valid,
  output [8:0]  io_out_2_bits_fuOpType_bits,
  output        io_out_2_bits_lsrc2_valid,
  output [5:0]  io_out_2_bits_lsrc2_bits,
  output        io_out_2_bits_src2Type_valid,
  output        io_out_2_bits_selImm_valid,
  output [3:0]  io_out_2_bits_selImm_bits,
  output        io_out_3_valid,
  output        io_out_3_bits_fuType_valid,
  output        io_out_3_bits_fuOpType_valid,
  output [8:0]  io_out_3_bits_fuOpType_bits,
  output        io_out_3_bits_lsrc2_valid,
  output [5:0]  io_out_3_bits_lsrc2_bits,
  output        io_out_3_bits_src2Type_valid,
  output        io_out_3_bits_selImm_valid,
  output [3:0]  io_out_3_bits_selImm_bits,
  output        io_out_4_valid,
  output        io_out_4_bits_fuType_valid,
  output        io_out_4_bits_fuOpType_valid,
  output [8:0]  io_out_4_bits_fuOpType_bits,
  output        io_out_4_bits_lsrc2_valid,
  output [5:0]  io_out_4_bits_lsrc2_bits,
  output        io_out_4_bits_src2Type_valid,
  output        io_out_4_bits_selImm_valid,
  output [3:0]  io_out_4_bits_selImm_bits,
  output        io_info_0_rs2FromRs1,
  output        io_info_0_rs2FromRs2,
  output        io_info_0_rs2FromZero,
  output        io_info_1_rs2FromRs1,
  output        io_info_1_rs2FromRs2,
  output        io_info_1_rs2FromZero,
  output        io_info_2_rs2FromRs1,
  output        io_info_2_rs2FromRs2,
  output        io_info_2_rs2FromZero,
  output        io_info_3_rs2FromRs1,
  output        io_info_3_rs2FromRs2,
  output        io_info_3_rs2FromZero,
  output        io_info_4_rs2FromRs1,
  output        io_info_4_rs2FromRs2,
  output        io_info_4_rs2FromZero,
  output        io_clear_1,
  output        io_clear_2,
  output        io_clear_3,
  output        io_clear_4,
  output        io_clear_5
);

  fusion_replace_t [N_PAIR-1:0] out;
  fusion_info_t    [N_PAIR-1:0] info;
  logic [DECODE_WIDTH-1:0]      clear;

  xs_FusionDecoder_core u_core (
    .clock        (clock),
    .reset        (reset),
    .disableFusion(io_disableFusion),
    .in_valid     ({io_in_5_valid, io_in_4_valid, io_in_3_valid, io_in_2_valid, io_in_1_valid, io_in_0_valid}),
    .in_instr     ({io_in_5_bits, io_in_4_bits, io_in_3_bits, io_in_2_bits, io_in_1_bits, io_in_0_bits}),
    .in_ready     ({io_inReady_4, io_inReady_3, io_inReady_2, io_inReady_1, io_inReady_0}),
    .dec_fuOpType ({io_dec_4_fuOpType, io_dec_3_fuOpType, io_dec_2_fuOpType, io_dec_1_fuOpType, io_dec_0_fuOpType}),
    .out          (out),
    .info         (info),
    .clear        (clear)
  );

  assign io_out_0_valid               = out[0].valid;
  assign io_out_0_bits_fuType_valid   = out[0].fuType_valid;
  assign io_out_0_bits_fuOpType_valid = out[0].fuOpType_valid;
  assign io_out_0_bits_fuOpType_bits  = out[0].fuOpType;
  assign io_out_0_bits_lsrc2_valid    = out[0].lsrc2_valid;
  assign io_out_0_bits_lsrc2_bits     = out[0].lsrc2;
  assign io_out_0_bits_src2Type_valid = out[0].src2Type_valid;
  assign io_out_0_bits_selImm_valid   = out[0].selImm_valid;
  assign io_out_0_bits_selImm_bits    = out[0].selImm;
  assign io_out_1_valid               = out[1].valid;
  assign io_out_1_bits_fuType_valid   = out[1].fuType_valid;
  assign io_out_1_bits_fuOpType_valid = out[1].fuOpType_valid;
  assign io_out_1_bits_fuOpType_bits  = out[1].fuOpType;
  assign io_out_1_bits_lsrc2_valid    = out[1].lsrc2_valid;
  assign io_out_1_bits_lsrc2_bits     = out[1].lsrc2;
  assign io_out_1_bits_src2Type_valid = out[1].src2Type_valid;
  assign io_out_1_bits_selImm_valid   = out[1].selImm_valid;
  assign io_out_1_bits_selImm_bits    = out[1].selImm;
  assign io_out_2_valid               = out[2].valid;
  assign io_out_2_bits_fuType_valid   = out[2].fuType_valid;
  assign io_out_2_bits_fuOpType_valid = out[2].fuOpType_valid;
  assign io_out_2_bits_fuOpType_bits  = out[2].fuOpType;
  assign io_out_2_bits_lsrc2_valid    = out[2].lsrc2_valid;
  assign io_out_2_bits_lsrc2_bits     = out[2].lsrc2;
  assign io_out_2_bits_src2Type_valid = out[2].src2Type_valid;
  assign io_out_2_bits_selImm_valid   = out[2].selImm_valid;
  assign io_out_2_bits_selImm_bits    = out[2].selImm;
  assign io_out_3_valid               = out[3].valid;
  assign io_out_3_bits_fuType_valid   = out[3].fuType_valid;
  assign io_out_3_bits_fuOpType_valid = out[3].fuOpType_valid;
  assign io_out_3_bits_fuOpType_bits  = out[3].fuOpType;
  assign io_out_3_bits_lsrc2_valid    = out[3].lsrc2_valid;
  assign io_out_3_bits_lsrc2_bits     = out[3].lsrc2;
  assign io_out_3_bits_src2Type_valid = out[3].src2Type_valid;
  assign io_out_3_bits_selImm_valid   = out[3].selImm_valid;
  assign io_out_3_bits_selImm_bits    = out[3].selImm;
  assign io_out_4_valid               = out[4].valid;
  assign io_out_4_bits_fuType_valid   = out[4].fuType_valid;
  assign io_out_4_bits_fuOpType_valid = out[4].fuOpType_valid;
  assign io_out_4_bits_fuOpType_bits  = out[4].fuOpType;
  assign io_out_4_bits_lsrc2_valid    = out[4].lsrc2_valid;
  assign io_out_4_bits_lsrc2_bits     = out[4].lsrc2;
  assign io_out_4_bits_src2Type_valid = out[4].src2Type_valid;
  assign io_out_4_bits_selImm_valid   = out[4].selImm_valid;
  assign io_out_4_bits_selImm_bits    = out[4].selImm;
  assign io_info_0_rs2FromRs1  = info[0].rs2FromRs1;
  assign io_info_0_rs2FromRs2  = info[0].rs2FromRs2;
  assign io_info_0_rs2FromZero = info[0].rs2FromZero;
  assign io_info_1_rs2FromRs1  = info[1].rs2FromRs1;
  assign io_info_1_rs2FromRs2  = info[1].rs2FromRs2;
  assign io_info_1_rs2FromZero = info[1].rs2FromZero;
  assign io_info_2_rs2FromRs1  = info[2].rs2FromRs1;
  assign io_info_2_rs2FromRs2  = info[2].rs2FromRs2;
  assign io_info_2_rs2FromZero = info[2].rs2FromZero;
  assign io_info_3_rs2FromRs1  = info[3].rs2FromRs1;
  assign io_info_3_rs2FromRs2  = info[3].rs2FromRs2;
  assign io_info_3_rs2FromZero = info[3].rs2FromZero;
  assign io_info_4_rs2FromRs1  = info[4].rs2FromRs1;
  assign io_info_4_rs2FromRs2  = info[4].rs2FromRs2;
  assign io_info_4_rs2FromZero = info[4].rs2FromZero;
  assign io_clear_1 = clear[1];
  assign io_clear_2 = clear[2];
  assign io_clear_3 = clear[3];
  assign io_clear_4 = clear[4];
  assign io_clear_5 = clear[5];

endmodule
