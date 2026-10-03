// TrapTvalMod.sv — readable childless CSR/control leaf; wrapper ports match G1 exactly.
// The canonical core contains the state/update equations; the wrapper is only a
// name-preserving shell for chip integration and FM/UT comparison.

module xs_TrapTvalMod_core(
  input         clock,
  input         reset,
  input         io_fromCtrlBlock_flush_valid,
  input         io_fromCtrlBlock_flush_bits_robIdx_flag,
  input  [7:0]  io_fromCtrlBlock_flush_bits_robIdx_value,
  input         io_fromCtrlBlock_flush_bits_cfiUpdate_backendIGPF,
  input         io_fromCtrlBlock_flush_bits_cfiUpdate_backendIPF,
  input         io_fromCtrlBlock_flush_bits_cfiUpdate_backendIAF,
  input  [63:0] io_fromCtrlBlock_flush_bits_fullTarget,
  input         io_fromCtrlBlock_robDeqPtr_flag,
  input  [7:0]  io_fromCtrlBlock_robDeqPtr_value,
  input         io_targetPc_valid,
  input  [63:0] io_targetPc_bits_pc,
  input         io_targetPc_bits_raiseIPF,
  input         io_targetPc_bits_raiseIAF,
  input         io_targetPc_bits_raiseIGPF,
  input         io_clear,
  output logic [63:0] io_tval
);
logic         valid;
  logic  [63:0] tval;
  logic         robIdx_flag;
  logic  [7:0]  robIdx_value;
  logic flush_clears_fault;
  always_comb begin
    flush_clears_fault = io_fromCtrlBlock_flush_bits_cfiUpdate_backendIGPF
    | io_fromCtrlBlock_flush_bits_cfiUpdate_backendIPF;
  end
  logic updateFromFlush;
  always_comb begin
    updateFromFlush = io_fromCtrlBlock_flush_valid
    & (flush_clears_fault | io_fromCtrlBlock_flush_bits_cfiUpdate_backendIAF);
  end
  logic target_pc_fault;
  always_comb begin
    target_pc_fault = io_targetPc_valid
    & (io_targetPc_bits_raiseIPF | io_targetPc_bits_raiseIAF
       | io_targetPc_bits_raiseIGPF);
  end
  logic flush_rob_is_younger;
  always_comb begin
    flush_rob_is_younger = io_fromCtrlBlock_flush_bits_robIdx_flag ^ robIdx_flag
    ^ io_fromCtrlBlock_flush_bits_robIdx_value < robIdx_value;
  end
always @(posedge clock or posedge reset) begin
    if (reset)
      valid <= 1'h0;
    else
      valid <=
        target_pc_fault
        | (valid
             ? updateFromFlush & flush_rob_is_younger
               | ~(io_fromCtrlBlock_flush_valid
                   & ~(flush_clears_fault
                       | io_fromCtrlBlock_flush_bits_cfiUpdate_backendIAF) & flush_rob_is_younger
                   | io_clear) & valid
             : updateFromFlush | valid);
  end // always @(posedge, posedge)
  always @(posedge clock) begin
    if (target_pc_fault) begin
      tval <= io_targetPc_bits_pc;
      robIdx_flag <= io_fromCtrlBlock_robDeqPtr_flag;
      robIdx_value <= io_fromCtrlBlock_robDeqPtr_value;
    end
    else if ((~valid | flush_rob_is_younger) & updateFromFlush) begin
      tval <= io_fromCtrlBlock_flush_bits_fullTarget;
      robIdx_flag <= io_fromCtrlBlock_flush_bits_robIdx_flag;
      robIdx_value <= io_fromCtrlBlock_flush_bits_robIdx_value;
    end
  end // always @(posedge)
always_comb begin
    io_tval = tval;
  end
endmodule

module TrapTvalMod(
  input         clock,
  input         reset,
  input         io_fromCtrlBlock_flush_valid,
  input         io_fromCtrlBlock_flush_bits_robIdx_flag,
  input  [7:0]  io_fromCtrlBlock_flush_bits_robIdx_value,
  input         io_fromCtrlBlock_flush_bits_cfiUpdate_backendIGPF,
  input         io_fromCtrlBlock_flush_bits_cfiUpdate_backendIPF,
  input         io_fromCtrlBlock_flush_bits_cfiUpdate_backendIAF,
  input  [63:0] io_fromCtrlBlock_flush_bits_fullTarget,
  input         io_fromCtrlBlock_robDeqPtr_flag,
  input  [7:0]  io_fromCtrlBlock_robDeqPtr_value,
  input         io_targetPc_valid,
  input  [63:0] io_targetPc_bits_pc,
  input         io_targetPc_bits_raiseIPF,
  input         io_targetPc_bits_raiseIAF,
  input         io_targetPc_bits_raiseIGPF,
  input         io_clear,
  output [63:0] io_tval
);
  xs_TrapTvalMod_core u_core (
    .clock(clock),
    .reset(reset),
    .io_fromCtrlBlock_flush_valid(io_fromCtrlBlock_flush_valid),
    .io_fromCtrlBlock_flush_bits_robIdx_flag(io_fromCtrlBlock_flush_bits_robIdx_flag),
    .io_fromCtrlBlock_flush_bits_robIdx_value(io_fromCtrlBlock_flush_bits_robIdx_value),
    .io_fromCtrlBlock_flush_bits_cfiUpdate_backendIGPF(io_fromCtrlBlock_flush_bits_cfiUpdate_backendIGPF),
    .io_fromCtrlBlock_flush_bits_cfiUpdate_backendIPF(io_fromCtrlBlock_flush_bits_cfiUpdate_backendIPF),
    .io_fromCtrlBlock_flush_bits_cfiUpdate_backendIAF(io_fromCtrlBlock_flush_bits_cfiUpdate_backendIAF),
    .io_fromCtrlBlock_flush_bits_fullTarget(io_fromCtrlBlock_flush_bits_fullTarget),
    .io_fromCtrlBlock_robDeqPtr_flag(io_fromCtrlBlock_robDeqPtr_flag),
    .io_fromCtrlBlock_robDeqPtr_value(io_fromCtrlBlock_robDeqPtr_value),
    .io_targetPc_valid(io_targetPc_valid),
    .io_targetPc_bits_pc(io_targetPc_bits_pc),
    .io_targetPc_bits_raiseIPF(io_targetPc_bits_raiseIPF),
    .io_targetPc_bits_raiseIAF(io_targetPc_bits_raiseIAF),
    .io_targetPc_bits_raiseIGPF(io_targetPc_bits_raiseIGPF),
    .io_clear(io_clear),
    .io_tval(io_tval)
  );
endmodule
