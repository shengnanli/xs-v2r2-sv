// =============================================================================
// VectorIdiv.sv —— 向量整数除法单元（128 位向量，SEW = 8/16/32/64，16 个除法器并行）
//
// 在哪一层：后端向量整数除法功能单元的数据通路（yunsuan VectorIdiv）。一条向量除法的
//   128 位被除数/除数向量在握手拍锁进 x_reg/d_reg，16 个标量除法器同时开工，全部出结果后
//   把各自的商/余数按元素位置拼回 128 位，等下游取走。
//
// 16 个除法器的分工（「车道分配表」；元素宽 ew = 8<<sew，元素 e 占 [ew*e +: ew]）：
//                      sew=00(8)   sew=01(16)  sew=10(32)  sew=11(64)
//   I8DivNr4    ×8     元素 0..7   —           —           —
//   SRT16Divint ×4     元素 8..11  元素 0..3   (取自己 16 位，结果不用)
//   SRT16Divint_4 ×2   元素 12..13 元素 4..5   元素 0..1   (取自己 32 位，结果不用)
//   SRT16Divint_6 ×2   元素 14..15 元素 6..7   元素 2..3   元素 0..1
//   规律：窄除法器分不完的高位元素交给更宽的除法器；元素比除法器宽时它照拿「自己那段」
//   （第 lane 个 width 位除法器拿 [width*lane +: width]），其结果在拼接时不被选用。
//   每个 SRT 除法器也收到 sew，自己按 sew 做符号/零扩展。结果按同一张表反过来拼。
//
// 握手：stateReg 独热 3 位（IDLE→DIVIDE→OUTPUT；只有它异步复位；整字相等逐态判断）。
//   DIVIDE 态对 16 个除法器一直拉 in_valid（各自只在自己的 IDLE 态吸收一次），全部 out_valid
//   才进 OUTPUT；OUTPUT 态对它们拉 out_ready，与本模块出口握手同拍放行。结果寄存器在 DIVIDE
//   态每拍更新，所以进入 OUTPUT 时锁住的正是「全部完成那一拍」的结果。flush 透传给全部除法器。
//   golden 没有 d_zero 输出（父级不用，firtool 连同它的寄存器一起删了）。
//
// 子模块（两侧白盒，本仓已签核重写件）：I8DivNr4 ×8、SRT16Divint ×4、SRT16Divint_4 ×2、
//   SRT16Divint_6 ×2；实例名与 golden 逐字相同（_8bit_divide_<i> 等）。
// 设计源：yunsuan/src/main/scala/yunsuan/vector/VectorIdiv/VectorIdiv.scala (class VectorIdiv)
// golden 对照：G1-canonical/golden-rtl/VectorIdiv.sv
// =============================================================================

// -----------------------------------------------------------------------------
// xs_VectorIdiv_core —— 可读核
// -----------------------------------------------------------------------------
module xs_VectorIdiv_core (
  input  logic         clock,
  input  logic         reset,
  input  logic [1:0]   sew,
  input  logic         sign,
  input  logic [127:0] dividend_v,
  input  logic [127:0] divisor_v,
  input  logic         flush,
  input  logic         div_in_valid,
  output logic         div_in_ready,
  input  logic         div_out_ready,
  output logic         div_out_valid,
  output logic [127:0] div_out_q_v,
  output logic [127:0] div_out_rem_v
);

  // ---------------------------------------------------------------------------
  // §1 状态机：IDLE → DIVIDE（等 16 个除法器全部出结果）→ OUTPUT（等下游取走）
  // ---------------------------------------------------------------------------
  localparam int S_IDLE = 0, S_DIVIDE = 1, S_OUTPUT = 2;
  localparam logic [2:0] OH_IDLE = 3'h1, OH_DIVIDE = 3'h2, OH_OUTPUT = 3'h4;

  logic [2:0] stateReg;
  logic       in_handshake, out_handshake, finish;
  assign div_in_ready  = stateReg[S_IDLE];
  assign div_out_valid = stateReg[S_OUTPUT];
  assign in_handshake  = div_in_valid & div_in_ready;
  assign out_handshake = div_out_valid & div_out_ready;

  always_ff @(posedge clock or posedge reset) begin
    if (reset)      stateReg <= OH_IDLE;
    else if (flush) stateReg <= OH_IDLE;
    else begin
      case (stateReg)
        OH_IDLE:   if (in_handshake)  stateReg <= OH_DIVIDE;
        OH_DIVIDE: stateReg <= finish ? OH_OUTPUT : OH_DIVIDE;
        OH_OUTPUT: if (out_handshake) stateReg <= OH_IDLE;
        default:   ;
      endcase
    end
  end

  // 握手拍锁存整条向量与控制（无复位）
  logic [127:0] x_reg, d_reg;
  logic         sign_reg;
  logic [1:0]   sew_reg;
  always_ff @(posedge clock) begin
    if (in_handshake) begin
      x_reg    <= dividend_v;
      d_reg    <= divisor_v;
      sign_reg <= sign;
      sew_reg  <= sew;
    end
  end

  // ---------------------------------------------------------------------------
  // §2 按车道分配表给每个除法器取操作数（窄元素零扩展到除法器位宽）
  // ---------------------------------------------------------------------------
  logic [7:0]  x8  [0:7], d8  [0:7];
  logic [15:0] x16 [0:3], d16 [0:3];
  logic [31:0] x32 [0:1], d32 [0:1];
  logic [63:0] x64 [0:1], d64 [0:1];
  always_comb begin
    for (int i = 0; i < 8; i++) begin
      x8[i] = x_reg[8*i +: 8];
      d8[i] = d_reg[8*i +: 8];
    end
    for (int i = 0; i < 4; i++) begin
      if (sew_reg == 2'd0) begin                      // 8 位元素 8..11
        x16[i] = {8'd0, x_reg[64 + 8*i +: 8]};
        d16[i] = {8'd0, d_reg[64 + 8*i +: 8]};
      end else begin                                  // 16 位元素 0..3（或自己那段）
        x16[i] = x_reg[16*i +: 16];
        d16[i] = d_reg[16*i +: 16];
      end
    end
    for (int i = 0; i < 2; i++) begin
      case (sew_reg)
        2'd0: begin                                   // 8 位元素 12..13
          x32[i] = {24'd0, x_reg[96 + 8*i +: 8]};
          d32[i] = {24'd0, d_reg[96 + 8*i +: 8]};
        end
        2'd1: begin                                   // 16 位元素 4..5
          x32[i] = {16'd0, x_reg[64 + 16*i +: 16]};
          d32[i] = {16'd0, d_reg[64 + 16*i +: 16]};
        end
        default: begin                                // 32 位元素 0..1（或自己那段）
          x32[i] = x_reg[32*i +: 32];
          d32[i] = d_reg[32*i +: 32];
        end
      endcase
      case (sew_reg)
        2'd0: begin                                   // 8 位元素 14..15
          x64[i] = {56'd0, x_reg[112 + 8*i +: 8]};
          d64[i] = {56'd0, d_reg[112 + 8*i +: 8]};
        end
        2'd1: begin                                   // 16 位元素 6..7
          x64[i] = {48'd0, x_reg[96 + 16*i +: 16]};
          d64[i] = {48'd0, d_reg[96 + 16*i +: 16]};
        end
        2'd2: begin                                   // 32 位元素 2..3
          x64[i] = {32'd0, x_reg[64 + 32*i +: 32]};
          d64[i] = {32'd0, d_reg[64 + 32*i +: 32]};
        end
        default: begin                                // 64 位元素 0..1
          x64[i] = x_reg[64*i +: 64];
          d64[i] = d_reg[64*i +: 64];
        end
      endcase
    end
  end

  // ---------------------------------------------------------------------------
  // §3 16 个除法器（实例名同 golden）。DIVIDE 态拉 in_valid，OUTPUT 态拉 out_ready。
  // ---------------------------------------------------------------------------
  logic       go, drain;
  assign go    = stateReg[S_DIVIDE];
  assign drain = stateReg[S_OUTPUT];

  logic        v8  [0:7], v16 [0:3], v32 [0:1], v64 [0:1];
  logic [7:0]  q8  [0:7], r8  [0:7];
  logic [15:0] q16 [0:3], r16 [0:3];
  logic [31:0] q32 [0:1], r32 [0:1];
  logic [63:0] q64 [0:1], r64 [0:1];

  I8DivNr4 _8bit_divide_0 (.clock(clock), .reset(reset), .io_sign(sign_reg), .io_dividend(x8[0]), .io_divisor(d8[0]),
    .io_flush(flush), .io_div_in_valid(go), .io_div_out_ready(drain),
    .io_div_out_valid(v8[0]), .io_div_out_q(q8[0]), .io_div_out_rem(r8[0]));
  I8DivNr4 _8bit_divide_1 (.clock(clock), .reset(reset), .io_sign(sign_reg), .io_dividend(x8[1]), .io_divisor(d8[1]),
    .io_flush(flush), .io_div_in_valid(go), .io_div_out_ready(drain),
    .io_div_out_valid(v8[1]), .io_div_out_q(q8[1]), .io_div_out_rem(r8[1]));
  I8DivNr4 _8bit_divide_2 (.clock(clock), .reset(reset), .io_sign(sign_reg), .io_dividend(x8[2]), .io_divisor(d8[2]),
    .io_flush(flush), .io_div_in_valid(go), .io_div_out_ready(drain),
    .io_div_out_valid(v8[2]), .io_div_out_q(q8[2]), .io_div_out_rem(r8[2]));
  I8DivNr4 _8bit_divide_3 (.clock(clock), .reset(reset), .io_sign(sign_reg), .io_dividend(x8[3]), .io_divisor(d8[3]),
    .io_flush(flush), .io_div_in_valid(go), .io_div_out_ready(drain),
    .io_div_out_valid(v8[3]), .io_div_out_q(q8[3]), .io_div_out_rem(r8[3]));
  I8DivNr4 _8bit_divide_4 (.clock(clock), .reset(reset), .io_sign(sign_reg), .io_dividend(x8[4]), .io_divisor(d8[4]),
    .io_flush(flush), .io_div_in_valid(go), .io_div_out_ready(drain),
    .io_div_out_valid(v8[4]), .io_div_out_q(q8[4]), .io_div_out_rem(r8[4]));
  I8DivNr4 _8bit_divide_5 (.clock(clock), .reset(reset), .io_sign(sign_reg), .io_dividend(x8[5]), .io_divisor(d8[5]),
    .io_flush(flush), .io_div_in_valid(go), .io_div_out_ready(drain),
    .io_div_out_valid(v8[5]), .io_div_out_q(q8[5]), .io_div_out_rem(r8[5]));
  I8DivNr4 _8bit_divide_6 (.clock(clock), .reset(reset), .io_sign(sign_reg), .io_dividend(x8[6]), .io_divisor(d8[6]),
    .io_flush(flush), .io_div_in_valid(go), .io_div_out_ready(drain),
    .io_div_out_valid(v8[6]), .io_div_out_q(q8[6]), .io_div_out_rem(r8[6]));
  I8DivNr4 _8bit_divide_7 (.clock(clock), .reset(reset), .io_sign(sign_reg), .io_dividend(x8[7]), .io_divisor(d8[7]),
    .io_flush(flush), .io_div_in_valid(go), .io_div_out_ready(drain),
    .io_div_out_valid(v8[7]), .io_div_out_q(q8[7]), .io_div_out_rem(r8[7]));

  SRT16Divint _16bit_divide_0 (.clock(clock), .reset(reset), .io_sign(sign_reg), .io_dividend(x16[0]), .io_divisor(d16[0]),
    .io_flush(flush), .io_sew(sew_reg), .io_div_in_valid(go), .io_div_out_ready(drain),
    .io_div_out_valid(v16[0]), .io_div_out_q(q16[0]), .io_div_out_rem(r16[0]));
  SRT16Divint _16bit_divide_1 (.clock(clock), .reset(reset), .io_sign(sign_reg), .io_dividend(x16[1]), .io_divisor(d16[1]),
    .io_flush(flush), .io_sew(sew_reg), .io_div_in_valid(go), .io_div_out_ready(drain),
    .io_div_out_valid(v16[1]), .io_div_out_q(q16[1]), .io_div_out_rem(r16[1]));
  SRT16Divint _16bit_divide_2 (.clock(clock), .reset(reset), .io_sign(sign_reg), .io_dividend(x16[2]), .io_divisor(d16[2]),
    .io_flush(flush), .io_sew(sew_reg), .io_div_in_valid(go), .io_div_out_ready(drain),
    .io_div_out_valid(v16[2]), .io_div_out_q(q16[2]), .io_div_out_rem(r16[2]));
  SRT16Divint _16bit_divide_3 (.clock(clock), .reset(reset), .io_sign(sign_reg), .io_dividend(x16[3]), .io_divisor(d16[3]),
    .io_flush(flush), .io_sew(sew_reg), .io_div_in_valid(go), .io_div_out_ready(drain),
    .io_div_out_valid(v16[3]), .io_div_out_q(q16[3]), .io_div_out_rem(r16[3]));

  SRT16Divint_4 _32bit_divide_0 (.clock(clock), .reset(reset), .io_sign(sign_reg), .io_dividend(x32[0]), .io_divisor(d32[0]),
    .io_flush(flush), .io_sew(sew_reg), .io_div_in_valid(go), .io_div_out_ready(drain),
    .io_div_out_valid(v32[0]), .io_div_out_q(q32[0]), .io_div_out_rem(r32[0]));
  SRT16Divint_4 _32bit_divide_1 (.clock(clock), .reset(reset), .io_sign(sign_reg), .io_dividend(x32[1]), .io_divisor(d32[1]),
    .io_flush(flush), .io_sew(sew_reg), .io_div_in_valid(go), .io_div_out_ready(drain),
    .io_div_out_valid(v32[1]), .io_div_out_q(q32[1]), .io_div_out_rem(r32[1]));

  SRT16Divint_6 _64bit_divide_0 (.clock(clock), .reset(reset), .io_sign(sign_reg), .io_dividend(x64[0]), .io_divisor(d64[0]),
    .io_flush(flush), .io_sew(sew_reg), .io_div_in_valid(go), .io_div_out_ready(drain),
    .io_div_out_valid(v64[0]), .io_div_out_q(q64[0]), .io_div_out_rem(r64[0]));
  SRT16Divint_6 _64bit_divide_1 (.clock(clock), .reset(reset), .io_sign(sign_reg), .io_dividend(x64[1]), .io_divisor(d64[1]),
    .io_flush(flush), .io_sew(sew_reg), .io_div_in_valid(go), .io_div_out_ready(drain),
    .io_div_out_valid(v64[1]), .io_div_out_q(q64[1]), .io_div_out_rem(r64[1]));

  // 全部完成：16 个 out_valid 相与
  always_comb begin
    finish = 1'b1;
    for (int i = 0; i < 8; i++) finish = finish & v8[i];
    for (int i = 0; i < 4; i++) finish = finish & v16[i];
    for (int i = 0; i < 2; i++) finish = finish & v32[i] & v64[i];
  end

  // ---------------------------------------------------------------------------
  // §4 结果拼接（按车道分配表反取，元素取各除法器结果的低 ew 位），DIVIDE 态每拍锁存
  // ---------------------------------------------------------------------------
  logic [127:0] q_result, rem_result;
  always_comb begin
    q_result   = '0;
    rem_result = '0;
    case (sew_reg)
      2'd0: begin
        for (int i = 0; i < 8; i++) begin
          q_result[8*i +: 8]   = q8[i];
          rem_result[8*i +: 8] = r8[i];
        end
        for (int i = 0; i < 4; i++) begin
          q_result[64 + 8*i +: 8]   = q16[i][7:0];
          rem_result[64 + 8*i +: 8] = r16[i][7:0];
        end
        for (int i = 0; i < 2; i++) begin
          q_result[96 + 8*i +: 8]    = q32[i][7:0];
          rem_result[96 + 8*i +: 8]  = r32[i][7:0];
          q_result[112 + 8*i +: 8]   = q64[i][7:0];
          rem_result[112 + 8*i +: 8] = r64[i][7:0];
        end
      end
      2'd1: begin
        for (int i = 0; i < 4; i++) begin
          q_result[16*i +: 16]   = q16[i];
          rem_result[16*i +: 16] = r16[i];
        end
        for (int i = 0; i < 2; i++) begin
          q_result[64 + 16*i +: 16]   = q32[i][15:0];
          rem_result[64 + 16*i +: 16] = r32[i][15:0];
          q_result[96 + 16*i +: 16]   = q64[i][15:0];
          rem_result[96 + 16*i +: 16] = r64[i][15:0];
        end
      end
      2'd2: begin
        for (int i = 0; i < 2; i++) begin
          q_result[32*i +: 32]        = q32[i];
          rem_result[32*i +: 32]      = r32[i];
          q_result[64 + 32*i +: 32]   = q64[i][31:0];
          rem_result[64 + 32*i +: 32] = r64[i][31:0];
        end
      end
      default: begin
        for (int i = 0; i < 2; i++) begin
          q_result[64*i +: 64]   = q64[i];
          rem_result[64*i +: 64] = r64[i];
        end
      end
    endcase
  end

  logic [127:0] div_out_q_result_reg, div_out_rem_result_reg;
  always_ff @(posedge clock) begin
    if (stateReg[S_DIVIDE]) begin
      div_out_q_result_reg   <= q_result;
      div_out_rem_result_reg <= rem_result;
    end
  end
  assign div_out_q_v   = div_out_q_result_reg;
  assign div_out_rem_v = div_out_rem_result_reg;
endmodule

// -----------------------------------------------------------------------------
// VectorIdiv —— golden 同名 wrapper：端口逐位同名，直接例化核
// -----------------------------------------------------------------------------
module VectorIdiv(
  input          clock,
  input          reset,
  input  [1:0]   io_sew,
  input          io_sign,
  input  [127:0] io_dividend_v,
  input  [127:0] io_divisor_v,
  input          io_flush,
  input          io_div_in_valid,
  output         io_div_in_ready,
  input          io_div_out_ready,
  output         io_div_out_valid,
  output [127:0] io_div_out_q_v,
  output [127:0] io_div_out_rem_v
);
  xs_VectorIdiv_core u_core (
    .clock         (clock),
    .reset         (reset),
    .sew           (io_sew),
    .sign          (io_sign),
    .dividend_v    (io_dividend_v),
    .divisor_v     (io_divisor_v),
    .flush         (io_flush),
    .div_in_valid  (io_div_in_valid),
    .div_in_ready  (io_div_in_ready),
    .div_out_ready (io_div_out_ready),
    .div_out_valid (io_div_out_valid),
    .div_out_q_v   (io_div_out_q_v),
    .div_out_rem_v (io_div_out_rem_v)
  );
endmodule
