// AgeDetector.sv —— 发射队列「最老可发射条目」选择器：6 条目 / 2 入队口 / 4 发射口
// -----------------------------------------------------------------------------
// 核体见 xs_AgeDetector_core.sv（家族共享参数化核，年龄矩阵的全部逻辑都在那里）。
// 本文件只做端口打包：把 golden 的扁平端口拢成核的数组接口，并设本变体的参数。
//
// 本变体规模（全部从 G1 golden AgeDetector.sv 机械量得，见 verif/ut/AgeDetector/gen.py）：
//   条目数 6（io_enq_0 的位宽）；入队口 2；发射口 4（canIssue/out 各 4 份）
//   age 寄存器 15 个 = 6*(6-1)/2 的严格上三角，复位臂 15 条
//     —— 寄存器数与复位臂数相等 ⇒ 本变体没有不复位寄存器。
//   golden 里例化的子模块：无（自包含叶子）
//
// 被这些发射队列例化：
//     IssueQueueAluBrhJmpI2fVsetriwiVsetriwvfI2v
//     IssueQueueAluCsrFenceDiv
//     IssueQueueAluMulBkuBrhJmp
//
// 自动生成：verif/ut/AgeDetector/gen.py —— 勿手改
// =============================================================================
module AgeDetector(
  input        clock,
  input        reset,
  input  [5:0] io_enq_0,
  input  [5:0] io_enq_1,
  input  [5:0] io_canIssue_0,
  input  [5:0] io_canIssue_1,
  input  [5:0] io_canIssue_2,
  input  [5:0] io_canIssue_3,
  output [5:0] io_out_0,
  output [5:0] io_out_1,
  output [5:0] io_out_2,
  output [5:0] io_out_3
);
  logic [5:0] enq      [2];
  logic [5:0] canIssue [4];
  logic [5:0] out      [4];

  assign enq[0] = io_enq_0;
  assign enq[1] = io_enq_1;
  assign canIssue[0] = io_canIssue_0;
  assign canIssue[1] = io_canIssue_1;
  assign canIssue[2] = io_canIssue_2;
  assign canIssue[3] = io_canIssue_3;

  assign io_out_0 = out[0];
  assign io_out_1 = out[1];
  assign io_out_2 = out[2];
  assign io_out_3 = out[3];

  xs_AgeDetector_core #(
    .NUM_ENTRIES(6),
    .NUM_ENQ    (2),
    .NUM_DEQ    (4)
  ) u_core (
    .clock       (clock),
    .reset       (reset),
    .io_enq      (enq),
    .io_canIssue (canIssue),
    .io_out      (out)
  );
endmodule
