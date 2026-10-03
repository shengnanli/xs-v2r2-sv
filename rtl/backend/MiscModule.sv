// =============================================================================
// MiscModule.sv —— Bku 的杂项位操作子块：xperm.n / xperm.b（Zbkx 查表置换）
//
// 位置：Bku（rtl/backend/Bku.sv）里四个并联子块之一，吃 rs1 / rs2。
//   Chisel 源 src/main/scala/xiangshan/backend/fu/Bku.scala `class MiscModule`。
//   Bku 给它的 io_regEnable 是 regEnable(1)：结果算完直接打一拍输出。
//
// 语义：rs1 当作一张查找表，rs2 的每个元素是下标，结果的同位置元素 = 表[下标]，
//   下标越界给 0。
//   xperm.n（func[0]=0）：元素 = 4 位半字节，表有 16 项，4 位下标永不越界；
//   xperm.b（func[0]=1）：元素 = 字节，表有 8 项，下标是整个字节，
//                         高 5 位非 0 即越界 → 0，否则用低 3 位查表。
//   func 只看 bit0（BKUOpType xpermn=000100 / xpermb=000101）。
//
// 唯一的寄存器是输出寄存器（RegEnable，不复位）；没有中间流水。
// =============================================================================

module xs_MiscModule_core (
  input  logic        clock,
  input  logic [63:0] table_src,     // rs1：查找表
  input  logic [63:0] index_src,     // rs2：每个元素是一个下标
  input  logic [8:0]  func,
  input  logic        reg_enable,
  output logic [63:0] out
);

  // ---- xperm.n：16 个半字节查 16 项半字节表 ----
  logic [3:0]  table_nibble [16];
  logic [63:0] xpermn;
  always_comb begin
    for (int i = 0; i < 16; i++) table_nibble[i] = table_src[4*i +: 4];
    for (int i = 0; i < 16; i++) xpermn[4*i +: 4] = table_nibble[index_src[4*i +: 4]];
  end

  // ---- xperm.b：8 个字节查 8 项字节表，下标 >= 8 给 0 ----
  logic [7:0]  table_byte [8];
  logic [7:0]  index_byte;
  logic [63:0] xpermb;
  always_comb begin
    for (int i = 0; i < 8; i++) table_byte[i] = table_src[8*i +: 8];
    for (int i = 0; i < 8; i++) begin
      index_byte      = index_src[8*i +: 8];
      xpermb[8*i +: 8] = (|index_byte[7:3]) ? 8'h00 : table_byte[index_byte[2:0]];
    end
  end

  // ---- 输出寄存器 ----
  logic [63:0] out_r;
  always_ff @(posedge clock) begin
    if (reg_enable) out_r <= func[0] ? xpermb : xpermn;
  end
  assign out = out_r;

endmodule


// =============================================================================
// MiscModule —— golden 同名 wrapper（端口逐位同 golden）
// =============================================================================
module MiscModule (
  input         clock,
  input  [63:0] io_src_0,
  input  [63:0] io_src_1,
  input  [8:0]  io_func,
  input         io_regEnable,
  output [63:0] io_out
);

  xs_MiscModule_core u_core (
    .clock      (clock),
    .table_src  (io_src_0),
    .index_src  (io_src_1),
    .func       (io_func),
    .reg_enable (io_regEnable),
    .out        (io_out)
  );

endmodule
