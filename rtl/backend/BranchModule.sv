// Resolve integer branches.  function_code[3:1] selects EQ, signed LT,
// or unsigned LT; function_code[0] complements that condition for NE/GE/GEU.
// Unsupported base encodings deliberately resolve false before complementation.
module xs_BranchModule_core (
  input  logic [63:0] lhs,
  input  logic [63:0] rhs,
  input  logic [8:0]  function_code,
  input  logic        predicted_taken,
  output logic        taken,
  output logic        mispredict
);
  logic base_condition;

  always_comb begin
    case (function_code[3:1])
      3'd0:    base_condition = (lhs == rhs);
      3'd2:    base_condition = ($signed(lhs) < $signed(rhs));
      3'd4:    base_condition = (lhs < rhs);
      default: base_condition = 1'b0;
    endcase
    taken = base_condition ^ function_code[0];
    mispredict = predicted_taken ^ taken;
  end
endmodule

module BranchModule (
  input  logic [63:0] io_src_0,
  input  logic [63:0] io_src_1,
  input  logic [8:0]  io_func,
  input  logic        io_pred_taken,
  output logic        io_taken,
  output logic        io_mispredict
);
  xs_BranchModule_core u_branch (
    .lhs(io_src_0),
    .rhs(io_src_1),
    .function_code(io_func),
    .predicted_taken(io_pred_taken),
    .taken(io_taken),
    .mispredict(io_mispredict)
  );
endmodule
