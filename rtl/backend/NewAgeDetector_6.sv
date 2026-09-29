// NewAgeDetector_6.sv —— 发射队列入队条目区的最老可发射选择器：2 条目 / 1 发射口
// -----------------------------------------------------------------------------
// 核体见 xs_NewAgeDetector_core.sv（家族共享参数化核）。本文件只把 golden 的扁平
// 端口拢成核的数组接口并设参数。
//
// 本变体规模（G1 golden NewAgeDetector_6.sv）：条目 2、发射口 1、age 寄存器 1 个
//   （age_0_1，异步复位清 0）；无子模块。
// 被这些发射队列例化（各 1 个）：IssueQueueFaluFmac、IssueQueueLdu、IssueQueueStaMou、
//   IssueQueueStdMoud、IssueQueueVfdivVidiv、IssueQueueVlduVstu、
//   IssueQueueVlduVstuVseglduVsegstu
// =============================================================================
module NewAgeDetector_6(
  input        clock,
  input        reset,
  input        io_enq_0,
  input        io_enq_1,
  input  [1:0] io_canIssue_0,
  output [1:0] io_out_0
);
  logic [1:0] canIssue [1];
  logic [1:0] out      [1];

  assign canIssue[0] = io_canIssue_0;
  assign io_out_0 = out[0];

  xs_NewAgeDetector_core #(
    .NUM_ENTRIES(2),
    .NUM_DEQ    (1)
  ) u_core (
    .clock      (clock),
    .reset      (reset),
    .io_enq     ({io_enq_1, io_enq_0}),
    .io_canIssue(canIssue),
    .io_out     (out)
  );
endmodule
