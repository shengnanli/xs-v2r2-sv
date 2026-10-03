// TLLogger_1.sv — combinational TileLink A/D transparency logger.
// It has no storage or side effects: every observable field is wired
// from the corresponding channel on the opposite side of the bridge.

module xs_TLLogger_1_core (
  output logic auto_in_a_ready,
  input  logic auto_in_a_valid,
  input  logic [3:0] auto_in_a_bits_opcode,
  input  logic [2:0] auto_in_a_bits_param,
  input  logic [2:0] auto_in_a_bits_size,
  input  logic [3:0] auto_in_a_bits_source,
  input  logic [47:0] auto_in_a_bits_address,
  input  logic [1:0] auto_in_a_bits_user_alias,
  input  logic [4:0] auto_in_a_bits_user_reqSource,
  input  logic auto_in_a_bits_user_needHint,
  input  logic [31:0] auto_in_a_bits_mask,
  input  logic [255:0] auto_in_a_bits_data,
  input  logic auto_in_a_bits_corrupt,
  input  logic auto_in_d_ready,
  output logic auto_in_d_valid,
  output logic [3:0] auto_in_d_bits_opcode,
  output logic [1:0] auto_in_d_bits_param,
  output logic [2:0] auto_in_d_bits_size,
  output logic [3:0] auto_in_d_bits_source,
  output logic [9:0] auto_in_d_bits_sink,
  output logic auto_in_d_bits_denied,
  output logic [255:0] auto_in_d_bits_data,
  output logic auto_in_d_bits_corrupt,
  input  logic auto_out_a_ready,
  output logic auto_out_a_valid,
  output logic [3:0] auto_out_a_bits_opcode,
  output logic [2:0] auto_out_a_bits_param,
  output logic [2:0] auto_out_a_bits_size,
  output logic [3:0] auto_out_a_bits_source,
  output logic [47:0] auto_out_a_bits_address,
  output logic [1:0] auto_out_a_bits_user_alias,
  output logic [4:0] auto_out_a_bits_user_reqSource,
  output logic auto_out_a_bits_user_needHint,
  output logic [31:0] auto_out_a_bits_mask,
  output logic [255:0] auto_out_a_bits_data,
  output logic auto_out_a_bits_corrupt,
  output logic auto_out_d_ready,
  input  logic auto_out_d_valid,
  input  logic [3:0] auto_out_d_bits_opcode,
  input  logic [1:0] auto_out_d_bits_param,
  input  logic [2:0] auto_out_d_bits_size,
  input  logic [3:0] auto_out_d_bits_source,
  input  logic [9:0] auto_out_d_bits_sink,
  input  logic auto_out_d_bits_denied,
  input  logic [255:0] auto_out_d_bits_data,
  input  logic auto_out_d_bits_corrupt
);
  assign auto_in_a_ready = auto_out_a_ready;
  assign auto_in_d_valid = auto_out_d_valid;
  assign auto_in_d_bits_opcode = auto_out_d_bits_opcode;
  assign auto_in_d_bits_param = auto_out_d_bits_param;
  assign auto_in_d_bits_size = auto_out_d_bits_size;
  assign auto_in_d_bits_source = auto_out_d_bits_source;
  assign auto_in_d_bits_sink = auto_out_d_bits_sink;
  assign auto_in_d_bits_denied = auto_out_d_bits_denied;
  assign auto_in_d_bits_data = auto_out_d_bits_data;
  assign auto_in_d_bits_corrupt = auto_out_d_bits_corrupt;
  assign auto_out_a_valid = auto_in_a_valid;
  assign auto_out_a_bits_opcode = auto_in_a_bits_opcode;
  assign auto_out_a_bits_param = auto_in_a_bits_param;
  assign auto_out_a_bits_size = auto_in_a_bits_size;
  assign auto_out_a_bits_source = auto_in_a_bits_source;
  assign auto_out_a_bits_address = auto_in_a_bits_address;
  assign auto_out_a_bits_user_alias = auto_in_a_bits_user_alias;
  assign auto_out_a_bits_user_reqSource = auto_in_a_bits_user_reqSource;
  assign auto_out_a_bits_user_needHint = auto_in_a_bits_user_needHint;
  assign auto_out_a_bits_mask = auto_in_a_bits_mask;
  assign auto_out_a_bits_data = auto_in_a_bits_data;
  assign auto_out_a_bits_corrupt = auto_in_a_bits_corrupt;
  assign auto_out_d_ready = auto_in_d_ready;
endmodule

module TLLogger_1 (
  output logic auto_in_a_ready,
  input  logic auto_in_a_valid,
  input  logic [3:0] auto_in_a_bits_opcode,
  input  logic [2:0] auto_in_a_bits_param,
  input  logic [2:0] auto_in_a_bits_size,
  input  logic [3:0] auto_in_a_bits_source,
  input  logic [47:0] auto_in_a_bits_address,
  input  logic [1:0] auto_in_a_bits_user_alias,
  input  logic [4:0] auto_in_a_bits_user_reqSource,
  input  logic auto_in_a_bits_user_needHint,
  input  logic [31:0] auto_in_a_bits_mask,
  input  logic [255:0] auto_in_a_bits_data,
  input  logic auto_in_a_bits_corrupt,
  input  logic auto_in_d_ready,
  output logic auto_in_d_valid,
  output logic [3:0] auto_in_d_bits_opcode,
  output logic [1:0] auto_in_d_bits_param,
  output logic [2:0] auto_in_d_bits_size,
  output logic [3:0] auto_in_d_bits_source,
  output logic [9:0] auto_in_d_bits_sink,
  output logic auto_in_d_bits_denied,
  output logic [255:0] auto_in_d_bits_data,
  output logic auto_in_d_bits_corrupt,
  input  logic auto_out_a_ready,
  output logic auto_out_a_valid,
  output logic [3:0] auto_out_a_bits_opcode,
  output logic [2:0] auto_out_a_bits_param,
  output logic [2:0] auto_out_a_bits_size,
  output logic [3:0] auto_out_a_bits_source,
  output logic [47:0] auto_out_a_bits_address,
  output logic [1:0] auto_out_a_bits_user_alias,
  output logic [4:0] auto_out_a_bits_user_reqSource,
  output logic auto_out_a_bits_user_needHint,
  output logic [31:0] auto_out_a_bits_mask,
  output logic [255:0] auto_out_a_bits_data,
  output logic auto_out_a_bits_corrupt,
  output logic auto_out_d_ready,
  input  logic auto_out_d_valid,
  input  logic [3:0] auto_out_d_bits_opcode,
  input  logic [1:0] auto_out_d_bits_param,
  input  logic [2:0] auto_out_d_bits_size,
  input  logic [3:0] auto_out_d_bits_source,
  input  logic [9:0] auto_out_d_bits_sink,
  input  logic auto_out_d_bits_denied,
  input  logic [255:0] auto_out_d_bits_data,
  input  logic auto_out_d_bits_corrupt
);
  xs_TLLogger_1_core u_core (
    .auto_in_a_ready(auto_in_a_ready),
    .auto_in_a_valid(auto_in_a_valid),
    .auto_in_a_bits_opcode(auto_in_a_bits_opcode),
    .auto_in_a_bits_param(auto_in_a_bits_param),
    .auto_in_a_bits_size(auto_in_a_bits_size),
    .auto_in_a_bits_source(auto_in_a_bits_source),
    .auto_in_a_bits_address(auto_in_a_bits_address),
    .auto_in_a_bits_user_alias(auto_in_a_bits_user_alias),
    .auto_in_a_bits_user_reqSource(auto_in_a_bits_user_reqSource),
    .auto_in_a_bits_user_needHint(auto_in_a_bits_user_needHint),
    .auto_in_a_bits_mask(auto_in_a_bits_mask),
    .auto_in_a_bits_data(auto_in_a_bits_data),
    .auto_in_a_bits_corrupt(auto_in_a_bits_corrupt),
    .auto_in_d_ready(auto_in_d_ready),
    .auto_in_d_valid(auto_in_d_valid),
    .auto_in_d_bits_opcode(auto_in_d_bits_opcode),
    .auto_in_d_bits_param(auto_in_d_bits_param),
    .auto_in_d_bits_size(auto_in_d_bits_size),
    .auto_in_d_bits_source(auto_in_d_bits_source),
    .auto_in_d_bits_sink(auto_in_d_bits_sink),
    .auto_in_d_bits_denied(auto_in_d_bits_denied),
    .auto_in_d_bits_data(auto_in_d_bits_data),
    .auto_in_d_bits_corrupt(auto_in_d_bits_corrupt),
    .auto_out_a_ready(auto_out_a_ready),
    .auto_out_a_valid(auto_out_a_valid),
    .auto_out_a_bits_opcode(auto_out_a_bits_opcode),
    .auto_out_a_bits_param(auto_out_a_bits_param),
    .auto_out_a_bits_size(auto_out_a_bits_size),
    .auto_out_a_bits_source(auto_out_a_bits_source),
    .auto_out_a_bits_address(auto_out_a_bits_address),
    .auto_out_a_bits_user_alias(auto_out_a_bits_user_alias),
    .auto_out_a_bits_user_reqSource(auto_out_a_bits_user_reqSource),
    .auto_out_a_bits_user_needHint(auto_out_a_bits_user_needHint),
    .auto_out_a_bits_mask(auto_out_a_bits_mask),
    .auto_out_a_bits_data(auto_out_a_bits_data),
    .auto_out_a_bits_corrupt(auto_out_a_bits_corrupt),
    .auto_out_d_ready(auto_out_d_ready),
    .auto_out_d_valid(auto_out_d_valid),
    .auto_out_d_bits_opcode(auto_out_d_bits_opcode),
    .auto_out_d_bits_param(auto_out_d_bits_param),
    .auto_out_d_bits_size(auto_out_d_bits_size),
    .auto_out_d_bits_source(auto_out_d_bits_source),
    .auto_out_d_bits_sink(auto_out_d_bits_sink),
    .auto_out_d_bits_denied(auto_out_d_bits_denied),
    .auto_out_d_bits_data(auto_out_d_bits_data),
    .auto_out_d_bits_corrupt(auto_out_d_bits_corrupt)
  );
endmodule
