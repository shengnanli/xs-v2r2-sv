// =============================================================================
// FPCVT.sv —— 标量浮点转换单元外壳：按 opType / sew 定出源、目的位宽，交给 CVT64 去转
//
// 在哪一层：标量浮点转换 FU（FCVT，ExeUnit_9 等）的运算核。fcvt.* / fround / fcvtmod 都走这里。
// 设计源：yunsuan/scalar/Convert.scala class FPCVT（xlen=64）。
//
// 机制：
//   opType[4:3] 是「宽度关系」：0 = 同宽、1 = 加宽（结果是源的 2 倍宽）、2 = 变窄（结果是源的一半宽）、
//   3 = 两档跨度（f16 ↔ f64 / i64 / ui64）；sew 是源元素宽度编码（0=8 / 1=16 / 2=32 / 3=64 位）。
//   两张译码表把 {宽度关系, sew} 翻成独热的源宽度 input1H 与结果宽度 output1H（bit0..3 = 8/16/32/64 位），
//   表里没列的组合两者都给 0（Chisel decoder 的 default）。真正的转换在 CVT64 里，本层只做这两张表。
// 子模块：CVT64 fcvt（实例名与 golden 一致；它在本仓尚无已入 main 的重写件 —— 两侧同读 golden CVT64，
//   其内部 FP_INCVT 及以下在 impl 侧解析到本仓已签核重写件）。本层纯组合、无寄存器。
// golden 对照：G1-canonical/golden-rtl/FPCVT.sv
// =============================================================================
module xs_FPCVT_core (
  input  logic [1:0] width_rel,   // opType[4:3]：0 同宽 / 1 加宽 / 2 变窄 / 3 两档跨度
  input  logic [1:0] sew,         // 源元素宽度：0=8 1=16 2=32 3=64 位
  output logic [3:0] input1H,     // 源宽度独热：bit0..3 = 8/16/32/64 位
  output logic [3:0] output1H     // 结果宽度独热
);
  localparam logic [3:0] W8 = 4'b0001, W16 = 4'b0010, W32 = 4'b0100, W64 = 4'b1000, NONE = 4'b0000;

  always_comb begin
    case ({width_rel, sew})
      // 同宽：源 = 结果
      4'b00_01: begin input1H = W16; output1H = W16; end
      4'b00_10: begin input1H = W32; output1H = W32; end
      4'b00_11: begin input1H = W64; output1H = W64; end
      // 加宽：结果是源的 2 倍
      4'b01_00: begin input1H = W8;  output1H = W16; end
      4'b01_01: begin input1H = W16; output1H = W32; end
      4'b01_10: begin input1H = W32; output1H = W64; end
      // 变窄：sew 编码的是**结果**宽度，源是它的 2 倍
      4'b10_00: begin input1H = W16; output1H = W8;  end
      4'b10_01: begin input1H = W32; output1H = W16; end
      4'b10_10: begin input1H = W64; output1H = W32; end
      // 两档跨度
      4'b11_01: begin input1H = W16; output1H = W64; end   // f16 → f64 / i64 / ui64
      4'b11_11: begin input1H = W64; output1H = W16; end   // f64 → f16
      default:  begin input1H = NONE; output1H = NONE; end
    endcase
  end
endmodule

module FPCVT (
  input  logic        clock,
  input  logic        reset,
  input  logic        io_fire,
  input  logic [63:0] io_src,
  input  logic [7:0]  io_opType,
  input  logic [1:0]  io_sew,
  input  logic [2:0]  io_rm,
  input  logic [1:0]  io_isFround,
  input  logic        io_isFcvtmod,
  output logic [63:0] io_result,
  output logic [4:0]  io_fflags
);
  logic [3:0] input1H, output1H;

  xs_FPCVT_core u_core (
    .width_rel (io_opType[4:3]),
    .sew       (io_sew),
    .input1H   (input1H),
    .output1H  (output1H)
  );

  CVT64 fcvt (
    .clock        (clock),
    .reset        (reset),
    .io_fire      (io_fire),
    .io_src       (io_src),
    .io_opType    (io_opType),
    .io_rm        (io_rm),
    .io_input1H   (input1H),
    .io_output1H  (output1H),
    .io_isFround  (io_isFround),
    .io_isFcvtmod (io_isFcvtmod),
    .io_result    (io_result),
    .io_fflags    (io_fflags)
  );
endmodule
