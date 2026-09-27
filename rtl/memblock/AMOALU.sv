// AMOALU —— DCache 原子读改写操作的组合运算单元。
// lhs 是 Cache 中的旧值，rhs 是 AMO 操作数；cmd 选择 add/xor/or/and/min/max，
// mask 既决定有效写字节，也用 mask[4] 区分 32/64 位比较、mask[3] 截断 32 位加法进位。
// 无时钟、无状态；被 mask 屏蔽的字节保持 lhs 原值。

module xs_AMOALU_core (
  input  logic [7:0]  mask,
  input  logic [4:0]  cmd,
  input  logic [63:0] lhs,
  input  logic [63:0] rhs,
  output logic [63:0] result
);
  localparam logic [4:0] CMD_ADD  = 5'h08;
  localparam logic [4:0] CMD_XOR  = 5'h09;
  localparam logic [4:0] CMD_OR   = 5'h0a;
  localparam logic [4:0] CMD_AND  = 5'h0b;
  localparam logic [4:0] CMD_MIN  = 5'h0c;
  localparam logic [4:0] CMD_MAX  = 5'h0d;
  localparam logic [4:0] CMD_MINU = 5'h0e;
  localparam logic [4:0] CMD_MAXU = 5'h0f;

  logic [63:0] byte_write_mask;
  logic [63:0] add_operand_mask;
  logic [63:0] add_result;
  logic [63:0] logic_result;
  logic [63:0] minmax_result;
  logic [63:0] unmasked_result;
  logic        lhs_less;
  logic        select_lhs;

  // 每个 mask bit 控制一个字节；bit 0 对应最低字节。
  for (genvar byte_idx = 0; byte_idx < 8; byte_idx++) begin : gen_byte_mask
    assign byte_write_mask[byte_idx*8 +: 8] = {8{mask[byte_idx]}};
  end

  // 32 位 AMOADD 时 mask[3]==0，清掉两个加数的 bit31，切断低 32 位
  // 向高 32 位的进位；64 位操作时 mask[3]==1，保持完整进位链。
  assign add_operand_mask = {32'hffff_ffff, mask[3], 31'h7fff_ffff};
  assign add_result = (lhs & add_operand_mask) + (rhs & add_operand_mask);

  always_comb begin
    unique case (cmd)
      CMD_XOR: logic_result = lhs ^ rhs;
      CMD_OR:  logic_result = lhs | rhs;
      CMD_AND: logic_result = lhs & rhs;
      default: logic_result = '0;
    endcase
  end

  // mask[4] 表示比较宽度：1 为 64 位，0 为低 32 位。
  // cmd[1]==0 是有符号 MIN/MAX，cmd[1]==1 是无符号 MINU/MAXU。
  always_comb begin
    if (mask[4]) begin
      if (cmd[1] == 1'b0)
        lhs_less = $signed(lhs) < $signed(rhs);
      else
        lhs_less = lhs < rhs;
    end else begin
      if (cmd[1] == 1'b0)
        lhs_less = $signed(lhs[31:0]) < $signed(rhs[31:0]);
      else
        lhs_less = lhs[31:0] < rhs[31:0];
    end

    // 与 Chisel 的 Mux(Mux(less,min,max), lhs, rhs) 保持相等值时的选择语义：
    // MIN/MINU 在相等时取 rhs，MAX/MAXU 在相等时取 lhs。
    select_lhs = lhs_less
      ? ((cmd == CMD_MIN) || (cmd == CMD_MINU))
      : ((cmd == CMD_MAX) || (cmd == CMD_MAXU));
    minmax_result = select_lhs ? lhs : rhs;
  end

  always_comb begin
    if (cmd == CMD_ADD)
      unmasked_result = add_result;
    else if ((cmd == CMD_XOR) || (cmd == CMD_OR) || (cmd == CMD_AND))
      unmasked_result = logic_result;
    else
      unmasked_result = minmax_result;

    result = (byte_write_mask & unmasked_result)
           | (~byte_write_mask & lhs);
  end
endmodule


// Golden 端口兼容层。单独保留 wrapper，可让上层 MainPipe 不感知可读核命名。
module AMOALU (
  input  logic [7:0]  io_mask,
  input  logic [4:0]  io_cmd,
  input  logic [63:0] io_lhs,
  input  logic [63:0] io_rhs,
  output logic [63:0] io_out
);
  xs_AMOALU_core u_core (
    .mask   (io_mask),
    .cmd    (io_cmd),
    .lhs    (io_lhs),
    .rhs    (io_rhs),
    .result (io_out)
  );
endmodule
