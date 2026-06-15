// =============================================================================
// xs_RVCExpander_core —— RVC（16 位压缩指令）→ 32 位标准指令 展开器（纯组合）
//
// 对应 Chisel: rocket-chip freechips.rocketchip.rocket.RVCDecoder（香山前端 IFU/
// 译码前用以把 C 扩展指令展开成 32 位）。本模块无任何寄存器，是一段纯译码逻辑。
//
// 接口（与 golden 扁平端口一致）：
//   io_in[31:0]   ：取指拿到的指令。低 16 位是待展开的 RVC；若它本来就是 32 位
//                   指令（io_in[1:0]==2'b11），高 16 位也有效，直接透传。
//   io_fsIsOff    ：浮点单元状态关闭（mstatus.FS==Off）。此时浮点 load/store 类
//                   RVC（FLD/FSD/FLDSP/FSDSP）视为非法。
//   io_out_bits   ：展开后的 32 位指令。
//   io_ill        ：该 RVC 是否非法（保留编码 / FS 关时的浮点 / hint 退化等）。
//
// 译码组织：用 sel = {op[1:0]=io_in[1:0], funct3=io_in[15:13]} 这 5 位选择子分派
// （见 rvc_expander_pkg 的 rvc_sel_e 注释）。每个象限/funct3 一个 case 分支，分支
// 内用“具名 RVC 字段 + rv_*() 标准格式组装器”重建 32 位指令，意图清晰。
//
// 说明：RVC 的立即数在各指令类里位排布各不相同（为了在 16 位里塞下高频偏移），
// 这里逐类用 {…} 拼出标准格式的立即数，注释给出该立即数的物理含义（字节/字/
// 双字偏移、是否符号扩展）。位序严格对齐 golden（即 RISC-V 规范）。
// =============================================================================
import rvc_expander_pkg::*;

module xs_RVCExpander_core (
  input  logic [31:0] io_in,
  input  logic        io_fsIsOff,
  output logic [31:0] io_out_bits,
  output logic        io_ill
);

  // ---- 选择子与常用具名字段（x8 受限寄存器：3 位域 + 隐含高位 2'b01 → x8..x15）----
  wire [4:0] sel = {io_in[1:0], io_in[15:13]};

  // C0/C1 的受限寄存器域（inst[9:7]=rs1'/rd', inst[4:2]=rs2'/rd'），扩成 5 位 x8+n
  wire [4:0] rs1p = {2'b01, io_in[9:7]};
  wire [4:0] rdp  = {2'b01, io_in[4:2]};
  // C2 的全 5 位寄存器域
  wire [4:0] rd_full  = io_in[11:7];   // rd / rs1（同域）
  wire [4:0] rs2_full = io_in[6:2];    // rs2

  // 符号位：很多 C1 立即数以 inst[12] 作为符号位
  wire sign = io_in[12];

  // ---- 各指令类的立即数（按 RVC 规范的位排布拼出标准格式立即数）----
  // C.ADDI4SPN: 无符号字节偏移，加到 sp(x2)，写 rdp。imm 落 I 型 imm[11:0]
  wire [11:0] imm_addi4spn = {2'b0, io_in[10:7], io_in[12:11], io_in[5], io_in[6], 2'b0};
  // C.LW / C.SW: 4 字节对齐偏移
  wire [11:0] imm_lw = {5'b0, io_in[5], io_in[12:10], io_in[6], 2'b0};
  // C.LD / C.FLD / C.SD / C.FSD: 8 字节对齐偏移
  wire [11:0] imm_ld = {4'b0, io_in[6:5], io_in[12:10], 3'b0};
  // C.ADDI / C.LI / C.ANDI 等：6 位符号扩展立即数 {inst[12], inst[6:2]}
  wire [11:0] imm6 = {{7{sign}}, io_in[6:2]};
  // C.LUI: 18 位高位立即数（符号扩展进 U 型 imm[19:0]，落在 bit12 以上）
  wire [19:0] imm_lui = {{15{sign}}, io_in[6:2]};
  // C.ADDI16SP: sp 的 16 字节对齐符号立即数
  wire [11:0] imm_addi16sp = {{3{sign}}, io_in[4:3], io_in[5], io_in[2], io_in[6], 4'b0};
  // C.J / C.JAL：11 位符号偏移（×2 字节）→ J 型 21 位
  wire [20:0] imm_cj = {{10{sign}}, io_in[8], io_in[10:9], io_in[6], io_in[7],
                        io_in[2], io_in[11], io_in[5:3], 1'b0};
  // C.BEQZ / C.BNEZ：8 位符号偏移（×2）→ B 型 13 位
  wire [12:0] imm_cb = {{5{sign}}, io_in[6:5], io_in[2], io_in[11:10], io_in[4:3], 1'b0};
  // C2 栈相对偏移（×4 / ×8）。注意 load 与 store 的偏移取自指令里不同的位域：
  //   - LWSP/LDSP（I 型）：偏移在 rd 之外的 inst[12]/[6:2] 里
  //   - SWSP/SDSP（S 型）：偏移在 inst[12]/[11:7] 里（rs2 才用 inst[6:2]）
  wire [11:0] imm_lwsp = {4'b0, io_in[3:2], io_in[12], io_in[6:4], 2'b0};      // C.LWSP
  wire [11:0] imm_ldsp = {3'b0, io_in[4:2], io_in[12], io_in[6:5], 3'b0};      // C.LDSP/FLDSP
  wire [11:0] imm_swsp = {4'b0, io_in[8:7], io_in[12], io_in[11:9], 2'b0};     // C.SWSP
  wire [11:0] imm_sdsp = {3'b0, io_in[9:7], io_in[12], io_in[11:10], 3'b0};    // C.SDSP/FSDSP

  // C.SLLI（C2 funct3=000）的移位量 shamt 直接来自 {inst[12], inst[6:2]}
  wire [5:0] shamt = {io_in[12], io_in[6:2]};

  // ---------------------------------------------------------------------------
  // 主译码：按 sel 分派。io_out_bits 在 op=11 时透传，否则按象限/funct3 组装。
  // ---------------------------------------------------------------------------
  logic [31:0] out;
  always_comb begin
    unique case (rvc_sel_e'(sel))
      // ===================== Quadrant 0 (op=00) =============================
      // C.ADDI4SPN：立即数全 0（io_in[12:5]==0）是保留编码，golden 把 opcode 退化为
      // OP_ILLEGAL，使展开结果注定触发非法指令异常。
      Q0_ADDI4SPN: out = rv_i(imm_addi4spn, 5'd2, 3'b000, rdp,
                              (|io_in[12:5]) ? OP_OP_IMM : OP_ILLEGAL);       // addi rdp, sp, imm
      Q0_FLD:      out = rv_i(imm_ld, rs1p, 3'b011, rdp, OP_LOAD_FP);        // fld
      Q0_LW:       out = rv_i(imm_lw, rs1p, 3'b010, rdp, OP_LOAD);           // lw
      Q0_LD:       out = rv_i(imm_ld, rs1p, 3'b011, rdp, OP_LOAD);           // ld
      Q0_ZCB_LS:   out = zcb_load_store(io_in);                              // Zcb load/store
      Q0_FSD:      out = rv_s(imm_ld, rdp, rs1p, 3'b011, OP_STORE_FP);       // fsd
      Q0_SW:       out = rv_s(imm_lw, rdp, rs1p, 3'b010, OP_STORE);          // sw
      Q0_SD:       out = rv_s(imm_ld, rdp, rs1p, 3'b011, OP_STORE);          // sd

      // ===================== Quadrant 1 (op=01) =============================
      // C.ADDI：rd==0 即 C.NOP / hint，golden 直接给出标准 nop=addi x0,x0,0(=0x13)，
      // 不带立即数（避免把 hint 立即数写进 x0 之外）。
      Q1_ADDI:     out = (|rd_full) ? rv_i(imm6, rd_full, 3'b000, rd_full, OP_OP_IMM)
                                    : 32'h00000013;                          // addi / nop
      // C.ADDIW：rd==0 为保留编码 → opcode 退化为 OP_ILLEGAL
      Q1_ADDIW:    out = rv_i(imm6, rd_full, 3'b000, rd_full,
                              (|rd_full) ? OP_OP_IMM32 : OP_ILLEGAL);        // addiw
      Q1_LI:       out = rv_i(imm6, 5'd0,    3'b000, rd_full, OP_OP_IMM);    // li = addi rd,x0,imm
      Q1_LUI_A16:  out = lui_or_addi16sp(io_in);                             // C.LUI / C.ADDI16SP
      Q1_MISC_ALU: out = misc_alu(io_in);                                    // 立即移位/逻辑 + R 型
      Q1_J:        out = rv_j(imm_cj, 5'd0, OP_JAL);                         // j = jal x0,off
      Q1_BEQZ:     out = rv_b(imm_cb, 5'd0, rs1p, 3'b000, OP_BRANCH);        // beqz = beq rs1p,x0
      Q1_BNEZ:     out = rv_b(imm_cb, 5'd0, rs1p, 3'b001, OP_BRANCH);        // bnez = bne rs1p,x0

      // ===================== Quadrant 2 (op=10) =============================
      Q2_SLLI:     out = rv_i({6'b0, shamt}, rd_full, 3'b001, rd_full, OP_OP_IMM);  // slli
      Q2_FLDSP:    out = rv_i(imm_ldsp, 5'd2, 3'b011, rd_full, OP_LOAD_FP);  // fld rd,off(sp)
      // C.LWSP：rd==0 为保留 → opcode 退化为 OP_ILLEGAL
      Q2_LWSP:     out = rv_i(imm_lwsp, 5'd2, 3'b010, rd_full,
                              (|rd_full) ? OP_LOAD : OP_ILLEGAL);            // lw rd,off(sp)
      Q2_LDSP:     out = rv_i(imm_ldsp, 5'd2, 3'b011, rd_full,
                              (|rd_full) ? OP_LOAD : OP_ILLEGAL);            // ld rd,off(sp)
      Q2_JALR_MV:  out = jalr_mv_add(io_in);                                 // jr/jalr/mv/add/ebreak
      Q2_FSDSP:    out = rv_s(imm_sdsp, rs2_full, 5'd2, 3'b011, OP_STORE_FP);// fsd rs2,off(sp)
      Q2_SWSP:     out = rv_s(imm_swsp, rs2_full, 5'd2, 3'b010, OP_STORE);   // sw rs2,off(sp)
      Q2_SDSP:     out = rv_s(imm_sdsp, rs2_full, 5'd2, 3'b011, OP_STORE);   // sd rs2,off(sp)

      default:     out = io_in;  // op=11：本就是 32 位指令，原样透传
    endcase
  end
  assign io_out_bits = out;

  // ===========================================================================
  // 子译码纯函数（仅依赖入参 inst，不读非局部信号——满足 Formality 的纯函数要求
  // FMR_VLOG-091）。各函数内部按需从 inst 派生具名字段，保持与上方主译码一致语义。
  // ===========================================================================

  // ---- C.LUI / C.ADDI16SP（C1 funct3=011，靠 rd 域区分）----
  // rd==2 → C.ADDI16SP（addi sp,sp,imm16）；否则 → C.LUI（lui rd,imm）。
  // 6 位立即数 {inst[12],inst[6:2]} 全 0 是保留编码：ADDI16SP 退化为 OP_ILLEGAL，
  // C.LUI 退化为 opcode 7'h3F（均注定触发非法指令异常）。另有 rd==1&imm==0 的特例。
  function automatic logic [31:0] lui_or_addi16sp(input logic [31:0] inst);
    logic [11:0] imm_a16;
    logic [19:0] imm_u;
    logic        imm_zero;
    imm_a16  = {{3{inst[12]}}, inst[4:3], inst[5], inst[2], inst[6], 4'b0};
    imm_u    = {{15{inst[12]}}, inst[6:2]};
    imm_zero = ~(|{inst[12], inst[6:2]});
    if (inst[7] && (inst[6:2] == 5'd0) && (inst[12:11] == 2'd0))
      return 32'h00000013;  // 特例：golden 直接给 nop
    if (inst[11:7] == 5'd2)
      return rv_i(imm_a16, 5'd2, 3'b000, 5'd2, imm_zero ? OP_ILLEGAL : OP_OP_IMM);
    else
      return rv_u(imm_u, inst[11:7], imm_zero ? 7'h3F : 7'h37);
  endfunction

  // ---- C1 funct3=100 的 MISC-ALU（rocket 含 Zcb 扩展）----
  // inst[11:10]：00=C.SRLI 01=C.SRAI 10=C.ANDI 11=R 型/单操作数 Zbb 组
  //
  // R 型组（inst[11:10]==11）由 idx = {inst[12], inst[6:5]} 选具体指令：
  //   idx 0 SUB / 1 XOR / 2 OR / 3 AND / 4 SUBW / 5 ADDW
  //   idx 6 保留（R 型形态，照常组装由 io_ill 判非法）
  //   idx 7（即 inst[12]&inst[6:5]全 1）→ 单操作数 Zbb 组，由 inst[4:2] 再选：
  //        0 C.ZEXT.B / 1 C.SEXT.B / 2 C.ZEXT.H / 3 C.SEXT.H / 4 C.ZEXT.W /
  //        5 C.NOT / 6,7 保留(展开成 0，注定非法)
  // R 型的寄存器：rd=rs1=rs1p(=x8+inst[9:7])，rs2=rdp(=x8+inst[4:2])。
  function automatic logic [31:0] misc_alu(input logic [31:0] inst);
    logic [4:0] rs1q, rdq;     // x8 受限寄存器
    logic [1:0] kind;
    logic [2:0] ridx;
    logic [5:0] sh;
    logic [11:0] imm_s;        // 6 位符号立即数（ANDI 用）
    logic [6:0] funct7;
    logic [2:0] funct3;
    logic [6:0] opc;
    rs1q = {2'b01, inst[9:7]};
    rdq  = {2'b01, inst[4:2]};
    kind = inst[11:10];
    ridx = {inst[12], inst[6:5]};
    sh   = {inst[12], inst[6:2]};
    imm_s = {{7{inst[12]}}, inst[6:2]};
    if (kind == 2'b11 && ridx == 3'b111) begin
      // 单操作数 Zbb 组（C.ZEXT.B/SEXT.B/ZEXT.H/SEXT.H/ZEXT.W/NOT）
      unique case (inst[4:2])
        3'b000: return rv_i(12'hFF,  rs1q, 3'b111, rs1q, OP_OP_IMM);              // zext.b: andi rd,rs,0xFF
        3'b001: return rv_r(7'h30, 5'h04, rs1q, 3'b001, rs1q, OP_OP_IMM);         // sext.b
        3'b010: return rv_r(7'h04, 5'h00, rs1q, 3'b100, rs1q, OP_OP32);           // zext.h (RV64)
        3'b011: return rv_r(7'h30, 5'h05, rs1q, 3'b001, rs1q, OP_OP_IMM);         // sext.h
        3'b100: return rv_r(7'h04, 5'h00, rs1q, 3'b000, rs1q, OP_OP32);           // zext.w (add.uw rd,rs,x0)
        3'b101: return rv_i(12'hFFF, rs1q, 3'b100, rs1q, OP_OP_IMM);              // not: xori rd,rs,-1
        default: return 32'h0;                                                    // 保留 → 注定非法
      endcase
    end else if (kind == 2'b11) begin
      // R 型 SUB/XOR/OR/AND/SUBW/ADDW（及保留 idx=6）。
      // opcode：inst[12]=0 → OP(0x33)；inst[12]=1 → 由 ~inst[6] 选 OP32(*W) 或 OP。
      opc = inst[12] ? (inst[6] ? OP_OP : OP_OP32) : OP_OP;
      unique case (ridx)
        3'b000: begin funct3 = 3'b000; funct7 = 7'h20; end // sub
        3'b001: begin funct3 = 3'b100; funct7 = 7'h00; end // xor
        3'b010: begin funct3 = 3'b110; funct7 = 7'h00; end // or
        3'b011: begin funct3 = 3'b111; funct7 = 7'h00; end // and
        3'b100: begin funct3 = 3'b000; funct7 = 7'h20; end // subw
        3'b101: begin funct3 = 3'b000; funct7 = 7'h00; end // addw
        default:begin funct3 = 3'b000; funct7 = 7'h01; end // idx=6 保留（golden funct7=7'h01）
      endcase
      return rv_r(funct7, rdq, rs1q, funct3, rs1q, opc);
    end else if (kind == 2'b10) begin
      // C.ANDI rs1q, rs1q, imm6
      return rv_i(imm_s, rs1q, 3'b111, rs1q, OP_OP_IMM);
    end else begin
      // C.SRLI(00)/C.SRAI(01)：6 位移位量 sh；SRAI 用 imm[10]=1 标记算术右移（落到 funct7
      // 的 bit30）。组装成标准 I 型移位指令。
      return rv_i({1'b0, (kind == 2'b01), 4'b0, sh}, rs1q, 3'b101, rs1q, OP_OP_IMM);
    end
  endfunction

  // ---- Q0 funct3=100：Zcb 的窄 load/store（C.LBU/C.LHU/C.LH/C.SB/C.SH）----
  // 由 inst[11:10] 区分：00 C.LBU / 01 C.LH/C.LHU / 10 C.SB / 11 C.SH
  // inst[6] 区分有/无符号半字：in6=0 → C.LHU(funct3=101)，in6=1 → C.LH(funct3=001)
  function automatic logic [31:0] zcb_load_store(input logic [31:0] inst);
    logic [4:0]  rs1q, rdq;
    logic [11:0] imm_b;  // 1 字节偏移
    logic [11:0] imm_h;  // 2 字节偏移
    rs1q  = {2'b01, inst[9:7]};
    rdq   = {2'b01, inst[4:2]};
    imm_b = {10'b0, inst[5], inst[6]};
    imm_h = {10'b0, inst[5], 1'b0};
    unique case (inst[11:10])
      2'b00: return rv_i(imm_b, rs1q, 3'b100, rdq, OP_LOAD);   // lbu rdq, off(rs1q)
      2'b01: return rv_i(imm_h, rs1q, inst[6] ? 3'b001 : 3'b101, rdq, OP_LOAD); // lh/lhu
      2'b10: return rv_s(imm_b, rdq, rs1q, 3'b000, OP_STORE);  // sb rdq, off(rs1q)
      default: return rv_s(imm_h, rdq, rs1q, 3'b001, OP_STORE);// sh rdq, off(rs1q)
    endcase
  endfunction

  // ---- C2 funct3=100：C.JR / C.JALR / C.MV / C.ADD / C.EBREAK ----
  // inst[12]=0：rs2(==inst[6:2])==0 → C.JR (jalr x0,0(rd))；否则 C.MV (addi rd,rs2,0)
  // inst[12]=1：rs2==0 且 rd==0 → C.EBREAK；rs2==0 且 rd!=0 → C.JALR (jalr ra,0(rd))；
  //             rs2!=0 → C.ADD (add rd,rd,rs2)
  function automatic logic [31:0] jalr_mv_add(input logic [31:0] inst);
    logic [4:0] rd, rs2;
    rd  = inst[11:7];
    rs2 = inst[6:2];
    if (!inst[12]) begin
      if (|rs2)
        // C.MV：golden 用 addi rd, rs2, 0（I 型）而非 add rd,x0,rs2，位序须一致
        return rv_i(12'b0, rs2, 3'b000, rd, OP_OP_IMM);            // mv: addi rd,rs2,0
      else
        // jr: jalr x0, 0(rd)；rd==0 为保留 → golden 用 OP_ILLEGAL
        return rv_i(12'b0, rd, 3'b000, 5'd0, (|rd) ? 7'h67 : OP_ILLEGAL);
    end else begin
      if (|rs2)
        return rv_r(7'h00, rs2, rd, 3'b000, rd, OP_OP);           // add rd,rd,rs2
      else if (|rd)
        return rv_i(12'b0, rd, 3'b000, 5'd1, 7'h67);              // jalr ra,0(rd)
      else
        return 32'h00100073;  // ebreak
    end
  endfunction

  // ===========================================================================
  // 非法判定 io_ill —— 与 golden 的取反结构等价：
  //   - op=11 与 op=10 的 SDSP/SWSP/FSDSP（idx 0x16/0x17 以及 0x18..0x1F）恒合法。
  //   - 浮点类（FLD/FSD/FLDSP/FSDSP，idx 1/5/0x11/0x15）：FS 关时非法。
  //   - 带寄存器约束的类：rd/rs 取保留值时非法（如 *SP load rd==0、ADDI4SPN 全 0 等）。
  // 这里按 sel 逐类给出“是否非法”，与 golden 一致。
  // ===========================================================================
  logic ill;
  always_comb begin
    unique case (rvc_sel_e'(sel))
      // C.ADDI4SPN：立即数（含寄存器约束）全 0 即保留编码 → 非法
      Q0_ADDI4SPN: ill = (io_in[12:5] == 8'b0);
      Q0_FLD:      ill = io_fsIsOff;                 // 浮点：FS 关非法
      Q0_LW:       ill = 1'b0;
      Q0_LD:       ill = 1'b0;
      // Zcb（Q0 funct3=4）：保留判定为 inst[12] 置位，或 inst[11]&inst[10]&inst[6]
      // （即 store 半字且 inst[6] 置位的保留组合）。
      Q0_ZCB_LS:   ill = io_in[12] | (io_in[11] & io_in[10] & io_in[6]);
      Q0_FSD:      ill = io_fsIsOff;
      Q0_SW:       ill = 1'b0;
      Q0_SD:       ill = 1'b0;

      Q1_ADDI:     ill = 1'b0;
      Q1_ADDIW:    ill = ~(|io_in[11:7]);            // ADDIW rd==0 非法
      Q1_LI:       ill = 1'b0;
      // C.LUI/ADDI16SP：imm 全 0 为保留；ADDI16SP(rd==2) 仅看 imm；C.LUI 看 imm
      Q1_LUI_A16:  ill = ~(io_in[12] | (|io_in[6:2])) & ~(~io_in[11] & io_in[7]);
      // MISC-ALU：仅单操作数 Zbb 组的保留项非法——inst[12:10] 全 1（R 型 + idx 高位）
      // 且 inst[6:3] 全 1（选到 Zbb 组的 r42=6/7 保留项）。
      Q1_MISC_ALU: ill = (&io_in[12:10]) & (&io_in[6:3]);
      Q1_J:        ill = 1'b0;
      Q1_BEQZ:     ill = 1'b0;
      Q1_BNEZ:     ill = 1'b0;

      Q2_SLLI:     ill = 1'b0;
      Q2_FLDSP:    ill = io_fsIsOff;                 // 浮点：FS 关非法
      Q2_LWSP:     ill = ~(|io_in[11:7]);            // LWSP rd==0 非法
      Q2_LDSP:     ill = ~(|io_in[11:7]);            // LDSP rd==0 非法
      // C.JR/JALR/MV/ADD/EBREAK：保留编码是 inst[12:2]==0（即 c.jr x0，rd 与偏移皆 0）
      Q2_JALR_MV:  ill = (io_in[12:2] == 11'b0);
      Q2_FSDSP:    ill = io_fsIsOff;
      Q2_SWSP:     ill = 1'b0;
      Q2_SDSP:     ill = 1'b0;

      default:     ill = 1'b0;  // op=11：合法（非压缩，透传）
    endcase
  end
  assign io_ill = ill;

endmodule : xs_RVCExpander_core
