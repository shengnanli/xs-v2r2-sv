// ============================================================================
// NewRobDeqPtrWrapper 包装层 —— golden 同名扁平端口 ↔ xs_NewRobDeqPtr_core
// (数组/struct 端口)。仅做机械的端口打包/拆包, 供 FM 对比与 ST 替换。
// 端口逐字对齐 golden NewRobDeqPtrWrapper.sv。
// ============================================================================
module NewRobDeqPtrWrapper
  import newrobdeqptr_pkg::*;
(
  input        clock,
  input        reset,
  input  [1:0] io_state,
  input        io_deq_v_0,
  input        io_deq_v_1,
  input        io_deq_v_2,
  input        io_deq_v_3,
  input        io_deq_v_4,
  input        io_deq_v_5,
  input        io_deq_v_6,
  input        io_deq_v_7,
  input        io_deq_w_0,
  input        io_deq_w_1,
  input        io_deq_w_2,
  input        io_deq_w_3,
  input        io_deq_w_4,
  input        io_deq_w_5,
  input        io_deq_w_6,
  input        io_deq_w_7,
  input        io_hasCommitted_0,
  input        io_hasCommitted_1,
  input        io_hasCommitted_2,
  input        io_hasCommitted_3,
  input        io_hasCommitted_4,
  input        io_hasCommitted_5,
  input        io_hasCommitted_6,
  input        io_hasCommitted_7,
  input        io_exception_state_valid,
  input        io_exception_state_bits_robIdx_flag,
  input  [7:0] io_exception_state_bits_robIdx_value,
  input        io_exception_state_bits_hasException,
  input        io_exception_state_bits_replayInst,
  input        io_exception_state_bits_singleStep,
  input  [3:0] io_exception_state_bits_trigger,
  input        io_intrBitSetReg,
  input        io_allowOnlyOneCommit,
  input        io_hasNoSpecExec,
  input        io_interrupt_safe,
  input        io_blockCommit,
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
  output [7:0] io_out_5_value,
  output       io_out_6_flag,
  output [7:0] io_out_6_value,
  output       io_out_7_flag,
  output [7:0] io_out_7_value,
  output       io_next_out_0_flag,
  output [7:0] io_next_out_0_value
);

  // ---- flat -> 打包 ----
  logic [COMMIT_W-1:0] deq_v, deq_w, has_committed;
  assign deq_v = {io_deq_v_7, io_deq_v_6, io_deq_v_5, io_deq_v_4,
                  io_deq_v_3, io_deq_v_2, io_deq_v_1, io_deq_v_0};
  assign deq_w = {io_deq_w_7, io_deq_w_6, io_deq_w_5, io_deq_w_4,
                  io_deq_w_3, io_deq_w_2, io_deq_w_1, io_deq_w_0};
  assign has_committed = {io_hasCommitted_7, io_hasCommitted_6, io_hasCommitted_5,
                          io_hasCommitted_4, io_hasCommitted_3, io_hasCommitted_2,
                          io_hasCommitted_1, io_hasCommitted_0};

  rob_ptr_t exc_robidx;
  assign exc_robidx = '{flag:  io_exception_state_bits_robIdx_flag,
                        value: io_exception_state_bits_robIdx_value};

  rob_ptr_t out [COMMIT_W];
  rob_ptr_t next_out_0;

  xs_NewRobDeqPtr_core u_core (
    .clock                                (clock),
    .reset                                (reset),
    .io_state                             (io_state),
    .io_deq_v                             (deq_v),
    .io_deq_w                             (deq_w),
    .io_hasCommitted                      (has_committed),
    .io_exception_state_valid             (io_exception_state_valid),
    .io_exception_state_bits_robIdx       (exc_robidx),
    .io_exception_state_bits_hasException (io_exception_state_bits_hasException),
    .io_exception_state_bits_replayInst   (io_exception_state_bits_replayInst),
    .io_exception_state_bits_singleStep   (io_exception_state_bits_singleStep),
    .io_exception_state_bits_trigger      (io_exception_state_bits_trigger),
    .io_intrBitSetReg                     (io_intrBitSetReg),
    .io_allowOnlyOneCommit                (io_allowOnlyOneCommit),
    .io_hasNoSpecExec                     (io_hasNoSpecExec),
    .io_interrupt_safe                    (io_interrupt_safe),
    .io_blockCommit                       (io_blockCommit),
    .io_out                               (out),
    .io_next_out_0                        (next_out_0)
  );

  // ---- 打包 -> flat ----
  assign io_out_0_flag  = out[0].flag;   assign io_out_0_value = out[0].value;
  assign io_out_1_flag  = out[1].flag;   assign io_out_1_value = out[1].value;
  assign io_out_2_flag  = out[2].flag;   assign io_out_2_value = out[2].value;
  assign io_out_3_flag  = out[3].flag;   assign io_out_3_value = out[3].value;
  assign io_out_4_flag  = out[4].flag;   assign io_out_4_value = out[4].value;
  assign io_out_5_flag  = out[5].flag;   assign io_out_5_value = out[5].value;
  assign io_out_6_flag  = out[6].flag;   assign io_out_6_value = out[6].value;
  assign io_out_7_flag  = out[7].flag;   assign io_out_7_value = out[7].value;
  assign io_next_out_0_flag  = next_out_0.flag;
  assign io_next_out_0_value = next_out_0.value;

endmodule
