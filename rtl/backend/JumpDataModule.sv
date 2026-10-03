// Datapath leaf shared by direct jumps, indirect jumps, and AUIPC.
// It adds a sign-extended immediate to the chosen base, forms the link value,
// and clears target bit zero as required for the control-flow destination.
module xs_JumpDataModule_core (
  input  logic [63:0] source,
  input  logic [63:0] program_counter,
  input  logic [32:0] immediate,
  input  logic [4:0]  next_pc_offset,
  input  logic [8:0]  function_code,
  output logic [63:0] result,
  output logic [63:0] target,
  output logic        is_auipc
);
  logic [63:0] extended_immediate;
  logic [63:0] unaligned_target;

  always_comb begin
    extended_immediate = {{31{immediate[32]}}, immediate};
    if (function_code[0])
      unaligned_target = source + extended_immediate;
    else
      unaligned_target = program_counter + extended_immediate;

    is_auipc = function_code[1];
    result = is_auipc
      ? unaligned_target
      : program_counter + {58'b0, next_pc_offset, 1'b0};
    target = {unaligned_target[63:1], 1'b0};
  end
endmodule

module JumpDataModule (
  input  logic [63:0] io_src,
  input  logic [63:0] io_pc,
  input  logic [32:0] io_imm,
  input  logic [4:0]  io_nextPcOffset,
  input  logic [8:0]  io_func,
  output logic [63:0] io_result,
  output logic [63:0] io_target,
  output logic        io_isAuipc
);
  xs_JumpDataModule_core u_jump (
    .source(io_src),
    .program_counter(io_pc),
    .immediate(io_imm),
    .next_pc_offset(io_nextPcOffset),
    .function_code(io_func),
    .result(io_result),
    .target(io_target),
    .is_auipc(io_isAuipc)
  );
endmodule
