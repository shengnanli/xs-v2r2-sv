// VectorCvt.sv —— 64 位向量浮点转换器：把 64 位源拆成 4 条元素通道并拼回结果（yunsuan VectorCvt）
// -----------------------------------------------------------------------------
// 在哪一层：VectorCvtTop 例化两份（128 位向量的高/低 64 位各一份），上面是 VCVT_8 功能单元。
// 机制（Scala: yunsuan/vector/VectorConvert/Convert.scala class VectorCvt）：
//   1. 宽度译码：由 {widen = opType[4:3], sew} 查两张真值表，得源元素宽度 input1H 与
//      结果元素宽度 output1H（独热：[0]=8 [1]=16 [2]=32 [3]=64 位；表外组合为 0）。
//        widen=00（同宽）  ：源 = 目的 = SEW
//        widen=01（变宽）  ：源 = SEW，目的 = 2*SEW
//        widen=10（变窄）  ：源 = 2*SEW，目的 = SEW
//   2. 拆通道：64 位源按源元素宽度切开，第 i 个元素送第 i 条通道 ——
//        通道 0：VCVT(64)，拿整个 64 位（元素在低位）；
//        通道 1：VCVT(32)，拿第 1 个元素（8/16/32 位源时），64 位源时给 0；
//        通道 2/3：VCVT(16)，拿第 2/3 个元素（只有 8/16 位源时才有），否则给 0。
//      通道 0 的 CVT64 用 input1H/output1H 选宽度；通道 1~3 的 CVT32/CVT16 自己按 sew 译码。
//   3. 拼结果：output1H 打两拍（与通道流水对齐）后，按结果元素宽度把各通道低位拼起来；
//      fflags 每通道 5 位，按同样的宽度拼成 20 位（8/16 位目的时 4 个通道都有效）。
// 怪癖（照 golden）：拼结果/fflags 都是 Mux1H（与门后按位或）；output1H 的第一级寄存器不复位，
//   第二级用 GatedValidRegNext(fire) 使能（outputWidth1H_last_r = fire 打一拍）。
// 子模块：VCVT / VCVT_1 / VCVT_2×2（本 lane 重写的通道壳）。
// golden 对照：G1-canonical/golden-rtl/VectorCvt.sv
// =============================================================================

module xs_VectorCvt_core (
  input  logic        clock,
  input  logic        reset,
  input  logic        fire,
  input  logic [63:0] src,
  input  logic [7:0]  op_type,
  input  logic [1:0]  sew,
  input  logic [2:0]  rm,
  output logic [63:0] result,
  output logic [19:0] fflags        // 每通道 5 位：[4:0]=通道 0 ... [19:15]=通道 3
);

  // ===========================================================================
  // §0 宽度译码（Scala 两张 TruthTable）
  // ===========================================================================
  logic [3:0] input1H;     // 源元素宽度
  logic [3:0] output1H;    // 结果元素宽度

  always_comb begin
    case ({op_type[4:3], sew})
      4'b00_01: begin input1H = 4'b0010; output1H = 4'b0010; end   // 同宽 16
      4'b00_10: begin input1H = 4'b0100; output1H = 4'b0100; end   // 同宽 32
      4'b00_11: begin input1H = 4'b1000; output1H = 4'b1000; end   // 同宽 64
      4'b01_00: begin input1H = 4'b0001; output1H = 4'b0010; end   // 变宽 8  -> 16
      4'b01_01: begin input1H = 4'b0010; output1H = 4'b0100; end   // 变宽 16 -> 32
      4'b01_10: begin input1H = 4'b0100; output1H = 4'b1000; end   // 变宽 32 -> 64
      4'b10_00: begin input1H = 4'b0010; output1H = 4'b0001; end   // 变窄 16 -> 8
      4'b10_01: begin input1H = 4'b0100; output1H = 4'b0010; end   // 变窄 32 -> 16
      4'b10_10: begin input1H = 4'b1000; output1H = 4'b0100; end   // 变窄 64 -> 32
      default:  begin input1H = 4'b0000; output1H = 4'b0000; end
    endcase
  end

  // ===========================================================================
  // §1 output1H 打两拍，与通道的 2 拍流水对齐
  // ===========================================================================
  logic [3:0] outputWidth1H_r;        // 第 1 级：fire 使能，不复位
  logic       outputWidth1H_last_r;   // fire 打一拍（GatedValidRegNext）
  logic [3:0] outputWidth1H;          // 第 2 级：outputWidth1H_last_r 使能，不复位

  always_ff @(posedge clock) begin
    if (fire)
      outputWidth1H_r <= output1H;
    if (outputWidth1H_last_r)
      outputWidth1H <= outputWidth1H_r;
  end

  always_ff @(posedge clock or posedge reset) begin
    if (reset)
      outputWidth1H_last_r <= 1'b0;
    else if (fire | outputWidth1H_last_r)
      outputWidth1H_last_r <= fire;
  end

  // ===========================================================================
  // §2 拆通道：第 i 个源元素送第 i 条通道（按源元素宽度 Mux1H）
  // ===========================================================================
  logic [31:0] lane1_src;
  logic [15:0] lane2_src, lane3_src;
  assign lane1_src = (input1H[0] ? 32'(src[15:8])  : 32'h0)
                   | (input1H[1] ? 32'(src[31:16]) : 32'h0)
                   | (input1H[2] ? src[63:32]      : 32'h0);
  assign lane2_src = (input1H[0] ? 16'(src[23:16]) : 16'h0)
                   | (input1H[1] ? src[47:32]      : 16'h0);
  assign lane3_src = (input1H[0] ? 16'(src[31:24]) : 16'h0)
                   | (input1H[1] ? src[63:48]      : 16'h0);

  logic [63:0] res0;
  logic [31:0] res1;
  logic [15:0] res2, res3;
  logic [4:0]  ff0, ff1, ff2, ff3;

  VCVT vcvtWraper (
    .clock       (clock),
    .reset       (reset),
    .io_fire     (fire),
    .io_src      (src),
    .io_opType   (op_type),
    .io_rm       (rm),
    .io_input1H  (input1H),
    .io_output1H (output1H),
    .io_result   (res0),
    .io_fflags   (ff0)
  );

  VCVT_1 vcvtWraper_1 (
    .clock     (clock),
    .reset     (reset),
    .io_fire   (fire),
    .io_src    (lane1_src),
    .io_opType (op_type),
    .io_sew    (sew),
    .io_rm     (rm),
    .io_result (res1),
    .io_fflags (ff1)
  );

  VCVT_2 vcvtWraper_2 (
    .clock     (clock),
    .reset     (reset),
    .io_fire   (fire),
    .io_src    (lane2_src),
    .io_opType (op_type),
    .io_sew    (sew),
    .io_rm     (rm),
    .io_result (res2),
    .io_fflags (ff2)
  );

  VCVT_2 vcvtWraper_3 (
    .clock     (clock),
    .reset     (reset),
    .io_fire   (fire),
    .io_src    (lane3_src),
    .io_opType (op_type),
    .io_sew    (sew),
    .io_rm     (rm),
    .io_result (res3),
    .io_fflags (ff3)
  );

  // ===========================================================================
  // §3 拼结果（按结果元素宽度 Mux1H）
  // ===========================================================================
  assign result = (outputWidth1H[0] ? 64'({res3[7:0], res2[7:0], res1[7:0], res0[7:0]}) : 64'h0)
                | (outputWidth1H[1] ? {res3[15:0], res2[15:0], res1[15:0], res0[15:0]}  : 64'h0)
                | (outputWidth1H[2] ? {res1[31:0], res0[31:0]}                          : 64'h0)
                | (outputWidth1H[3] ? res0                                              : 64'h0);
  assign fflags = (outputWidth1H[0] ? {ff3, ff2, ff1, ff0} : 20'h0)
                | (outputWidth1H[1] ? {ff3, ff2, ff1, ff0} : 20'h0)
                | (outputWidth1H[2] ? 20'({ff1, ff0})      : 20'h0)
                | (outputWidth1H[3] ? 20'(ff0)             : 20'h0);

endmodule

module VectorCvt(
  input         clock,
  input         reset,
  input         io_fire,
  input  [63:0] io_src,
  input  [7:0]  io_opType,
  input  [1:0]  io_sew,
  input  [2:0]  io_rm,
  output [63:0] io_result,
  output [19:0] io_fflags
);

  xs_VectorCvt_core u_core (
    .clock   (clock),
    .reset   (reset),
    .fire    (io_fire),
    .src     (io_src),
    .op_type (io_opType),
    .sew     (io_sew),
    .rm      (io_rm),
    .result  (io_result),
    .fflags  (io_fflags)
  );

endmodule
