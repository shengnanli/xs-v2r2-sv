// =============================================================================
// CSA_Nto2With3to2MainPipeline.sv —— 浮点乘加的部分积压缩树：27 个 107 位加数 -> 和 / 进位两个数
//
// 位置：FloatFMA / VectorFloatFMA 第 0~1 拍之间，接在 Booth 编码器（27 个加数）之后。输出的
//   out_sum + out_car 就是乘积（再加上父模块里对齐后的加数 c，最后用一个真正的加法器加起来）。
//   Scala：yunsuan/src/main/scala/yunsuan/fpu/FloatFMA.scala 的 CSA_Nto2With3to2MainPipeline
//   （n=27, width=107, pipeLevel=5）。向量版用的是同一个 golden 模块（同参数）。
//
// 机制：进位保留加法（carry-save）逐层把"个数"压下去，各层之间不做进位传播：
//   * 3:2 压缩器（CSA3to2）：3 个数 -> 和、进位两个数；4:2 压缩器（CSA4to2）：4 个数 -> 2 个数。
//   * 每层把上一层的结果按 {和0, 进位0, 和1, 进位1, ...} 排成一列，再按 3 个（或 4 个）一组送下一层。
//     Scala 的选法：个数正好是 8 或 4 时用 4:2，否则用 3:2（27 / 18 / 12 都能被 3 整除，没有落单的）。
//         第 1 层  27 -> 18   9 个 3:2
//         第 2 层  18 -> 12   6 个 3:2
//         第 3 层  12 ->  8   4 个 3:2
//         第 4 层   8 ->  4   2 个 4:2
//         第 5 层   4 ->  2   1 个 4:2   ★它的 4 个输入先打一拍（pipeLevel=5：第 5 层之前是流水线寄存器）★
//   * 寄存器只有这 4 个 107 位，fire 使能、不复位；树里其余全部组合。
//
// 子模块：CSA3to2（本仓重写件）、CSA4to2（本仓无重写件：UT / FM 两侧都用 golden 原件）。
// =============================================================================

module xs_CSA_Nto2With3to2MainPipeline_core (
  input  logic                clock,
  input  logic                fire,
  input  logic [26:0][106:0]  addend,     // 27 个加数（Booth 部分积）
  output logic [106:0]        out_sum,
  output logic [106:0]        out_car
);
  localparam int unsigned W = 107;

  // 每层输出的数，排列顺序 = {和0, 进位0, 和1, 进位1, ...}
  logic [17:0][W-1:0] level1;   // 27 -> 18
  logic [11:0][W-1:0] level2;   // 18 -> 12
  logic [7:0][W-1:0]  level3;   // 12 -> 8
  logic [3:0][W-1:0]  level4;   //  8 -> 4（这 4 个数进流水线寄存器）

  // ---------------------------------------------------------------------------
  // §1 第 1~3 层：3:2 压缩（组合）
  // ---------------------------------------------------------------------------
  for (genvar g = 0; g < 9; g++) begin : g_level1
    CSA3to2 u_csa (
      .io_in_a    (addend[3*g]),
      .io_in_b    (addend[3*g+1]),
      .io_in_c    (addend[3*g+2]),
      .io_out_sum (level1[2*g]),
      .io_out_car (level1[2*g+1])
    );
  end

  for (genvar g = 0; g < 6; g++) begin : g_level2
    CSA3to2 u_csa (
      .io_in_a    (level1[3*g]),
      .io_in_b    (level1[3*g+1]),
      .io_in_c    (level1[3*g+2]),
      .io_out_sum (level2[2*g]),
      .io_out_car (level2[2*g+1])
    );
  end

  for (genvar g = 0; g < 4; g++) begin : g_level3
    CSA3to2 u_csa (
      .io_in_a    (level2[3*g]),
      .io_in_b    (level2[3*g+1]),
      .io_in_c    (level2[3*g+2]),
      .io_out_sum (level3[2*g]),
      .io_out_car (level3[2*g+1])
    );
  end

  // ---------------------------------------------------------------------------
  // §2 第 4 层：4:2 压缩（组合）
  // ---------------------------------------------------------------------------
  for (genvar g = 0; g < 2; g++) begin : g_level4
    CSA4to2 u_csa (
      .io_in_a    (level3[4*g]),
      .io_in_b    (level3[4*g+1]),
      .io_in_c    (level3[4*g+2]),
      .io_in_d    (level3[4*g+3]),
      .io_out_sum (level4[2*g]),
      .io_out_car (level4[2*g+1])
    );
  end

  // ---------------------------------------------------------------------------
  // §3 流水线寄存器（第 5 层之前），fire 使能、不复位
  // ---------------------------------------------------------------------------
  logic [3:0][W-1:0] level4_q;
  always_ff @(posedge clock) begin
    if (fire) begin
      level4_q <= level4;
    end
  end

  // ---------------------------------------------------------------------------
  // §4 第 5 层：最后一个 4:2，得到和 / 进位
  // ---------------------------------------------------------------------------
  CSA4to2 u_csa_last (
    .io_in_a    (level4_q[0]),
    .io_in_b    (level4_q[1]),
    .io_in_c    (level4_q[2]),
    .io_in_d    (level4_q[3]),
    .io_out_sum (out_sum),
    .io_out_car (out_car)
  );
endmodule

module CSA_Nto2With3to2MainPipeline (
  input          clock,
  input          io_fire,
  input  [106:0] io_in_0,
  input  [106:0] io_in_1,
  input  [106:0] io_in_2,
  input  [106:0] io_in_3,
  input  [106:0] io_in_4,
  input  [106:0] io_in_5,
  input  [106:0] io_in_6,
  input  [106:0] io_in_7,
  input  [106:0] io_in_8,
  input  [106:0] io_in_9,
  input  [106:0] io_in_10,
  input  [106:0] io_in_11,
  input  [106:0] io_in_12,
  input  [106:0] io_in_13,
  input  [106:0] io_in_14,
  input  [106:0] io_in_15,
  input  [106:0] io_in_16,
  input  [106:0] io_in_17,
  input  [106:0] io_in_18,
  input  [106:0] io_in_19,
  input  [106:0] io_in_20,
  input  [106:0] io_in_21,
  input  [106:0] io_in_22,
  input  [106:0] io_in_23,
  input  [106:0] io_in_24,
  input  [106:0] io_in_25,
  input  [106:0] io_in_26,
  output [106:0] io_out_sum,
  output [106:0] io_out_car
);
  xs_CSA_Nto2With3to2MainPipeline_core u_core (
    .clock   (clock),
    .fire    (io_fire),
    .addend  ({io_in_26, io_in_25, io_in_24, io_in_23, io_in_22, io_in_21, io_in_20,
               io_in_19, io_in_18, io_in_17, io_in_16, io_in_15, io_in_14, io_in_13,
               io_in_12, io_in_11, io_in_10, io_in_9,  io_in_8,  io_in_7,  io_in_6,
               io_in_5,  io_in_4,  io_in_3,  io_in_2,  io_in_1,  io_in_0}),
    .out_sum (io_out_sum),
    .out_car (io_out_car)
  );
endmodule
