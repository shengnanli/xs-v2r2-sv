// =============================================================================
// RobEnqPtrWrapper —— ROB 入队指针组（Rob 的子模块）
//
// 设计源：src/main/scala/xiangshan/backend/rob/RobEnqPtrWrapper.scala。
//
// 机制：ROB 是 160 项的环形队列（RobSize=160，不是 2 的幂），指针 RobPtr = {flag, value}，
//   value ∈ [0,160)，每绕一圈 flag 翻转一次。Rename 每拍最多送 6 条（RenameWidth=6），
//   本模块保存 6 个连续的入队指针 enqPtrVec[i] = enqPtr + i，供 6 个入队口直接取用。
//   每拍二选一：
//     * redirect 有效（冲刷）：从被冲刷指令 robIdx 重新起头——
//         flushItself（level=1，连它自己一起冲）  ⇒ enqPtrVec[i] = robIdx + i
//         否则（level=0，只冲它后面的）          ⇒ enqPtrVec[i] = robIdx + i + 1
//     * 否则：canAccept = allowEnqueue && !hasBlockBackward 时，6 个指针一起前移
//       PopCount(enq) 格；不能接收时前移 0 格（保持）。
// 复位：enqPtrVec[i] 异步复位为 {flag=0, value=i}。
//
// 怪癖（照 golden）：
//   * 非 2 的幂环形加法：sum = value + k（9 位），sum >= 160 则 value = sum-160、flag 取反。
//     这个判法对 value ≥ 160 的非法输入也给出确定结果（golden 同式），本文件逐式照抄，
//     不假设输入合法。
//   * 入队计数是 6 个 enq 位直接 PopCount，不看 enq 是否连续。
// =============================================================================
module xs_RobEnqPtrWrapper_core #(
  parameter int NUM_PTR   = 6,    // RenameWidth
  parameter int ROB_SIZE  = 160   // RobSize
) (
  input  logic                clock,
  input  logic                reset,
  input  logic                redirect_valid,
  input  logic                redirect_flag,
  input  logic [7:0]          redirect_value,
  input  logic                redirect_level,     // 1 = flushItself
  input  logic                allow_enqueue,
  input  logic                has_block_backward,
  input  logic [NUM_PTR-1:0]  enq,
  output logic [NUM_PTR-1:0]  out_flag,
  output logic [7:0]          out_value [NUM_PTR]
);

  // ---------------------------------------------------------------------------
  // 环形指针加法（CircularQueuePtr.+，非 2 的幂分支）
  //   sum  = value + inc（不截断）；wrap = sum >= ROB_SIZE；
  //   wrap 时 value = sum - ROB_SIZE 且 flag 取反。
  // ---------------------------------------------------------------------------
  function automatic logic [8:0] rob_ptr_add(input logic       flag,
                                             input logic [7:0] value,
                                             input logic [8:0] inc);
    logic [8:0] sum;
    logic       wrap;
    sum  = {1'b0, value} + inc;
    wrap = (sum >= 9'(ROB_SIZE));
    return wrap ? {~flag, 8'(sum - 9'(ROB_SIZE))} : {flag, sum[7:0]};
  endfunction

  // ---------------------------------------------------------------------------
  // §1 本拍入队条数：能接收时 = enq 里 1 的个数，否则 0
  // ---------------------------------------------------------------------------
  logic       can_accept;
  logic [2:0] dispatch_num;
  assign can_accept   = allow_enqueue & ~has_block_backward;
  assign dispatch_num = can_accept ? 3'($countones(enq)) : 3'd0;

  // ---------------------------------------------------------------------------
  // §2 指针寄存器：冲刷时从 robIdx 重新起头，否则一起前移 dispatch_num 格
  // ---------------------------------------------------------------------------
  logic       enqPtrVec_flag  [NUM_PTR];
  logic [7:0] enqPtrVec_value [NUM_PTR];

  for (genvar i = 0; i < NUM_PTR; i++) begin : g_ptr
    logic [8:0] redirect_next;   // {flag, value}：冲刷后的新指针
    logic [8:0] advance_next;    // {flag, value}：正常前移后的新指针
    assign redirect_next = rob_ptr_add(redirect_flag, redirect_value,
                                       9'(i) + (redirect_level ? 9'd0 : 9'd1));
    assign advance_next  = rob_ptr_add(enqPtrVec_flag[i], enqPtrVec_value[i],
                                       {6'd0, dispatch_num});

    always_ff @(posedge clock or posedge reset) begin
      if (reset) begin
        enqPtrVec_flag[i]  <= 1'b0;
        enqPtrVec_value[i] <= 8'(i);
      end else if (redirect_valid) begin
        {enqPtrVec_flag[i], enqPtrVec_value[i]} <= redirect_next;
      end else begin
        {enqPtrVec_flag[i], enqPtrVec_value[i]} <= advance_next;
      end
    end

    assign out_flag[i]  = enqPtrVec_flag[i];
    assign out_value[i] = enqPtrVec_value[i];
  end

endmodule

// ---------------------------------------------------------------------------
// golden 同名 wrapper：端口与 G1 golden RobEnqPtrWrapper.sv 逐位一致
// ---------------------------------------------------------------------------
module RobEnqPtrWrapper (
  input        clock,
  input        reset,
  input        io_redirect_valid,
  input        io_redirect_bits_robIdx_flag,
  input  [7:0] io_redirect_bits_robIdx_value,
  input        io_redirect_bits_level,
  input        io_allowEnqueue,
  input        io_hasBlockBackward,
  input        io_enq_0,
  input        io_enq_1,
  input        io_enq_2,
  input        io_enq_3,
  input        io_enq_4,
  input        io_enq_5,
  output       io_out_0_flag,
  output [7:0] io_out_0_value,
  output       io_out_1_flag,
  output [7:0] io_out_1_value,
  output       io_out_2_flag,
  output [7:0] io_out_2_value,
  output       io_out_3_flag,
  output [7:0] io_out_3_value,
  output       io_out_4_flag,
  output [7:0] io_out_4_value,
  output       io_out_5_flag,
  output [7:0] io_out_5_value
);

  logic [5:0] out_flag;
  logic [7:0] out_value [6];

  xs_RobEnqPtrWrapper_core #(
    .NUM_PTR  (6),
    .ROB_SIZE (160)
  ) u_core (
    .clock              (clock),
    .reset              (reset),
    .redirect_valid     (io_redirect_valid),
    .redirect_flag      (io_redirect_bits_robIdx_flag),
    .redirect_value     (io_redirect_bits_robIdx_value),
    .redirect_level     (io_redirect_bits_level),
    .allow_enqueue      (io_allowEnqueue),
    .has_block_backward (io_hasBlockBackward),
    .enq                ({io_enq_5, io_enq_4, io_enq_3, io_enq_2, io_enq_1, io_enq_0}),
    .out_flag           (out_flag),
    .out_value          (out_value)
  );

  assign io_out_0_flag  = out_flag[0];
  assign io_out_0_value = out_value[0];
  assign io_out_1_flag  = out_flag[1];
  assign io_out_1_value = out_value[1];
  assign io_out_2_flag  = out_flag[2];
  assign io_out_2_value = out_value[2];
  assign io_out_3_flag  = out_flag[3];
  assign io_out_3_value = out_value[3];
  assign io_out_4_flag  = out_flag[4];
  assign io_out_4_value = out_value[4];
  assign io_out_5_flag  = out_flag[5];
  assign io_out_5_value = out_value[5];

endmodule
