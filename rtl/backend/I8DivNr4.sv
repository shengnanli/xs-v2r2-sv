// =============================================================================
// I8DivNr4.sv —— 8 位整数除法器（非恢复余数法 non-restoring，每拍 2 位商）
//
// 在哪一层：VectorIdiv 的 8 个 SEW=8 车道各例化一个（_8bit_divide_0..7）；16/32/64
//   位车道走 SRT16Divint{,_4,_6}。8 位用不着 SRT 的查表选择，直接非恢复法：
//   余数为负就加除数、为正就减除数，商位 = 新余数非负；每拍连做两步（radix-4），
//   4 拍出 8 位商。迭代一拍由子模块 IterBlockI8Nr4 完成（本仓已签核，两侧白盒）。
//
// 握手与状态机（独热 stateReg，6 位；golden 第 5 位永远写 0）：
//   IDLE --in_valid--> PRE --early_finish--> POST --> OUTPUT --out_ready--> IDLE
//                       \--否则--> ITER（4 拍，iter_num 4→0）--> POST
//   flush 在任何状态都回 IDLE（优先级最高）。输出在 OUTPUT 态有效。
//   注意：golden 不输出 div_ready / d_zero（父级没用，firtool 删掉了端口）。
//
// 数据通路分三段（下面 §2–§4）：
//   PRE  ：取绝对值（有符号时）、判特殊情况、预存 4 档除数倍数 {-3d, -d, +d, +3d}；
//   ITER ：IterBlockI8Nr4 每拍消耗 2 位被除数，给出 2 位商；
//   POST ：余数为负则 +d 修正；按符号把商/余数取补；结果打一拍出。
// 特殊情况（early_finish）：|x|<|d|（商 0、余数 |x|）、x=0、d=0（商全 1、余数 |x|）——
//   与 RISC-V 除零语义一致：商 = -1，余数 = 被除数。
// ★bug-for-bug 要点★
//   · neg_x_q 是一个共享的取负器：PRE 态取 −x，其余时刻取 −iter_q_reg（POST 用它给商取补）；
//   · 除数倍数寄存器是 10 位（Chisel 里 -d + (-d<<1) 把宽度撑到 10），只用低 9 位；
//     最高位照存（寄存器字段集合逐字照搬 golden）。
//   · 复位：只有 stateReg 异步复位到 IDLE，其余寄存器无复位（与 golden 一致）。
//
// 设计源：yunsuan/src/main/scala/yunsuan/vector/VectorIdiv/I8DivNr4.scala (class I8DivNr4)
// golden 对照：G1-canonical/golden-rtl/I8DivNr4.sv
// =============================================================================

// -----------------------------------------------------------------------------
// xs_I8DivNr4_core —— 可读核
// -----------------------------------------------------------------------------
module xs_I8DivNr4_core (
  input  logic       clock,
  input  logic       reset,          // 异步、高有效（只复位状态机）
  input  logic       sign,           // 1 = 有符号除法
  input  logic [7:0] dividend,       // x
  input  logic [7:0] divisor,        // d
  input  logic       flush,
  input  logic       div_in_valid,
  input  logic       div_out_ready,
  output logic       div_out_valid,
  output logic [7:0] div_out_q,
  output logic [7:0] div_out_rem
);

  // ---------------------------------------------------------------------------
  // §1 独热状态机。位号即状态号；第 5 位没有状态，golden 也是 6 位寄存器。
  // ---------------------------------------------------------------------------
  localparam int S_IDLE = 0, S_PRE = 1, S_ITER = 2, S_POST = 3, S_OUTPUT = 4;
  localparam logic [5:0] OH_IDLE   = 6'b00_0001;
  localparam logic [5:0] OH_PRE    = 6'b00_0010;
  localparam logic [5:0] OH_ITER   = 6'b00_0100;
  localparam logic [5:0] OH_POST   = 6'b00_1000;
  localparam logic [5:0] OH_OUTPUT = 6'b01_0000;

  logic [5:0] stateReg;
  logic       in_pre, in_iter, in_post;
  assign in_pre        = stateReg[S_PRE];
  assign in_iter       = stateReg[S_ITER];
  assign in_post       = stateReg[S_POST];
  assign div_out_valid = stateReg[S_OUTPUT];

  logic       early_finish;   // §2 产出
  logic       iter_finish;    // §3 产出
  logic       div_ready;      // = IDLE；golden 没有这个输出端口，只在握手里用
  assign div_ready = stateReg[S_IDLE];

  // 优先级与 Chisel when/elsewhen 链逐级一致（多热态下也按此顺序取第一条）。
  always_ff @(posedge clock or posedge reset) begin
    if (reset)                                         stateReg <= OH_IDLE;
    else if (flush)                                    stateReg <= OH_IDLE;
    else if (stateReg[S_IDLE] && div_in_valid && div_ready)
                                                       stateReg <= OH_PRE;
    else if (in_pre)                                   stateReg <= early_finish ? OH_POST : OH_ITER;
    else if (in_iter)                                  stateReg <= iter_finish  ? OH_POST : OH_ITER;
    else if (in_post)                                  stateReg <= OH_OUTPUT;
    else if (stateReg[S_OUTPUT] && div_out_ready)      stateReg <= OH_IDLE;
  end

  // 迭代/后处理用到的寄存器（声明集中在此，写入分散在各节）
  logic [7:0] iter_q_reg;       // 商（迭代中逐 2 位左移拼入）
  logic [8:0] iter_w_reg;       // 部分余数高 9 位（带符号）
  logic [7:0] iter_w_low_reg;   // 尚未移入的被除数低位
  logic [2:0] iter_num_reg;     // 剩余迭代拍数
  logic       x_sign_reg, q_sign_reg, zero_d_reg, early_finish_q;
  logic [9:0] const_d_reg [0:3];   // {-3d, -d, +d, +3d}，10 位宽、只用低 9 位

  // ---------------------------------------------------------------------------
  // §2 PRE：绝对值、特殊情况、除数倍数
  // ---------------------------------------------------------------------------
  logic       x_sign, d_sign;
  logic [7:0] neg_x_q, abs_x, abs_d;
  assign x_sign  = sign & dividend[7];
  assign d_sign  = sign & divisor[7];
  // 共享取负器：PRE 态对被除数取负，其余时刻对商寄存器取负（POST 用来给商取补）
  assign neg_x_q = 8'(8'd0 - (in_pre ? dividend : iter_q_reg));
  assign abs_x   = x_sign ? neg_x_q : dividend;
  assign abs_d   = d_sign ? 8'(8'd0 - divisor) : divisor;

  logic x_small, x_zero, d_zero;
  assign x_small      = abs_x < abs_d;
  assign x_zero       = abs_x == 8'd0;
  assign d_zero       = abs_d == 8'd0;
  assign early_finish = x_small | x_zero | d_zero;

  // 提前结束时的商/余数：|x|<|d| → 商 0；d=0 → 商全 1；余数在这两种情况下取 |x|
  logic [7:0] early_q;
  logic [8:0] early_rem;
  assign early_q   = x_small ? 8'd0 : (d_zero ? 8'hFF : 8'd0);
  assign early_rem = {1'b0, (x_small | d_zero) ? abs_x : 8'd0};

  // 除数倍数：d_ext 补 1 位 0 成 9 位，再按 Chisel 的宽度规则算（-3d 撑到 10 位）
  logic [8:0] d_ext, neg_d_ext;
  logic [9:0] const_d [0:3];
  assign d_ext      = {1'b0, abs_d};
  assign neg_d_ext  = 9'(9'd0 - d_ext);
  assign const_d[0] = 10'({1'b0, neg_d_ext} + {neg_d_ext, 1'b0});   // -3d
  assign const_d[1] = {1'b0, neg_d_ext};                            // -d
  assign const_d[2] = {1'b0, d_ext};                                // +d
  assign const_d[3] = 10'({1'b0, d_ext} + {d_ext, 1'b0});           // +3d

  always_ff @(posedge clock) begin
    if (in_pre) begin
      x_sign_reg     <= x_sign;
      q_sign_reg     <= x_sign ^ d_sign;
      zero_d_reg     <= d_zero;
      early_finish_q <= early_finish;
      for (int i = 0; i < 4; i++) const_d_reg[i] <= const_d[i];
    end
  end

  // ---------------------------------------------------------------------------
  // §3 ITER：IterBlockI8Nr4 一拍两位；PRE 态装初值，ITER 态装迭代结果
  // ---------------------------------------------------------------------------
  logic [8:0] nxt_w;
  logic [7:0] nxt_w_low, nxt_q;
  IterBlockI8Nr4 u_iter (
    .io_d_cons_0  (const_d_reg[0][8:0]),
    .io_d_cons_1  (const_d_reg[1][8:0]),
    .io_d_cons_2  (const_d_reg[2][8:0]),
    .io_d_cons_3  (const_d_reg[3][8:0]),
    .io_pre_w     (iter_w_reg),
    .io_pre_w_low (iter_w_low_reg),
    .io_nxt_w     (nxt_w),
    .io_nxt_w_low (nxt_w_low),
    .io_pre_q     (iter_q_reg),
    .io_nxt_q     (nxt_q)
  );

  logic [2:0] iter_num;
  assign iter_num    = in_pre ? 3'd4 : 3'(iter_num_reg - 3'd1);   // 8 位 / 每拍 2 位 = 4 拍
  assign iter_finish = iter_num == 3'd0;

  always_ff @(posedge clock) begin
    if (in_pre | in_iter) begin
      iter_q_reg     <= in_pre ? (early_finish ? early_q : 8'd0) : nxt_q;
      iter_w_reg     <= in_pre ? (early_finish ? early_rem : 9'd0) : nxt_w;
      iter_w_low_reg <= in_pre ? abs_x : nxt_w_low;
      iter_num_reg   <= iter_num;
    end
  end

  // ---------------------------------------------------------------------------
  // §4 POST：余数修正与符号恢复，结果寄存一拍后在 OUTPUT 态输出
  //   非恢复法最后一步余数可能为负（iter_w_reg[8]=1），要 +d 拉回；提前结束的不修。
  //   有符号且被除数为负时，余数取补（−w + d 等价于 −(w − d)，与 golden 同式）。
  // ---------------------------------------------------------------------------
  logic       rem_adjust;
  logic [7:0] rem_plain, rem_plus_d, out_q_final, out_rem_final;
  assign rem_adjust    = iter_w_reg[8] & ~early_finish_q;
  assign rem_plain     = x_sign_reg ? 8'(8'd0 - iter_w_reg[7:0]) : iter_w_reg[7:0];
  assign rem_plus_d    = x_sign_reg ? 8'(rem_plain + const_d_reg[1][7:0])
                                    : 8'(rem_plain + const_d_reg[2][7:0]);
  assign out_rem_final = rem_adjust ? rem_plus_d : rem_plain;
  // 商取补：商符号为负且不是除零（除零时商保持全 1）
  assign out_q_final   = (q_sign_reg & ~zero_d_reg) ? neg_x_q : iter_q_reg;

  logic [7:0] out_q_final_reg, out_rem_final_reg;
  always_ff @(posedge clock) begin
    if (in_post) begin
      out_q_final_reg   <= out_q_final;
      out_rem_final_reg <= out_rem_final;
    end
  end

  assign div_out_q   = out_q_final_reg;
  assign div_out_rem = out_rem_final_reg;
endmodule

// -----------------------------------------------------------------------------
// I8DivNr4 —— golden 同名 wrapper：端口逐位同名，直接例化核
// -----------------------------------------------------------------------------
module I8DivNr4(
  input        clock,
  input        reset,
  input        io_sign,
  input  [7:0] io_dividend,
  input  [7:0] io_divisor,
  input        io_flush,
  input        io_div_in_valid,
  input        io_div_out_ready,
  output       io_div_out_valid,
  output [7:0] io_div_out_q,
  output [7:0] io_div_out_rem
);
  xs_I8DivNr4_core u_core (
    .clock         (clock),
    .reset         (reset),
    .sign          (io_sign),
    .dividend      (io_dividend),
    .divisor       (io_divisor),
    .flush         (io_flush),
    .div_in_valid  (io_div_in_valid),
    .div_out_ready (io_div_out_ready),
    .div_out_valid (io_div_out_valid),
    .div_out_q     (io_div_out_q),
    .div_out_rem   (io_div_out_rem)
  );
endmodule
