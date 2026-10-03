// =============================================================================
// SRT16Divint_6.sv —— SRT radix-16 整数除法器，**本变体 BIT_WIDTH=64**
//
// 在哪一层：VectorIdiv 的 64 位车道（_64bit_divide_0..1），sew 可取 00..11。
// 本变体规模：余数 carry-save 宽 W=70（= BIT_WIDTH + 6）、前导零计数 6 位、迭代计数 4 位，
//   最多 16 拍迭代（每拍 4 位商）；子模块 SRT4qdsCons ×1、IterBlock_v4_6 ×1（本仓已签核重写件）。
// 与 SRT16Divint（16 位）只差位宽与 IterBlock 变体；握手状态机、PRE0/PRE1/ITER/POST 各级、
//   寄存器复用与 bug-for-bug 要点都在参数化核 xs_SRT16Divint_core（rtl/backend/SRT16Divint.sv）里，
//   核体不复制。
//
// 本文件由 scripts/gen_srt16divint.py 生成，勿手改。
// 设计源：yunsuan/src/main/scala/yunsuan/vector/VectorIdiv/SRT16Divint.scala (class SRT16Divint)
// golden 对照：G1-canonical/golden-rtl/SRT16Divint_6.sv
// =============================================================================

module SRT16Divint_6(
  input         clock,
  input         reset,
  input         io_sign,
  input  [63:0] io_dividend,
  input  [63:0] io_divisor,
  input         io_flush,
  input  [1:0]  io_sew,
  input         io_div_in_valid,
  input         io_div_out_ready,
  output        io_div_out_valid,
  output [63:0] io_div_out_q,
  output [63:0] io_div_out_rem
);
  xs_SRT16Divint_core #(.BIT_WIDTH(64)) u_core (
    .clock         (clock),
    .reset         (reset),
    .sign          (io_sign),
    .dividend      (io_dividend),
    .divisor       (io_divisor),
    .flush         (io_flush),
    .sew           (io_sew),
    .div_in_valid  (io_div_in_valid),
    .div_out_ready (io_div_out_ready),
    .div_out_valid (io_div_out_valid),
    .div_out_q     (io_div_out_q),
    .div_out_rem   (io_div_out_rem)
  );
endmodule
