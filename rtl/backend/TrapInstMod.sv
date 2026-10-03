// TrapInstMod.sv — readable childless CSR/control leaf; wrapper ports match G1 exactly.
// The canonical core contains the state/update equations; the wrapper is only a
// name-preserving shell for chip integration and FM/UT comparison.

module xs_TrapInstMod_core(
  input         clock,
  input         reset,
  input         io_fromDecode_trapInstInfo_valid,
  input  [31:0] io_fromDecode_trapInstInfo_bits_instr,
  input         io_fromDecode_trapInstInfo_bits_ftqPtr_flag,
  input  [5:0]  io_fromDecode_trapInstInfo_bits_ftqPtr_value,
  input  [3:0]  io_fromDecode_trapInstInfo_bits_ftqOffset,
  input         io_fromRob_flush_valid,
  input         io_fromRob_flush_bits_ftqPtr_flag,
  input  [5:0]  io_fromRob_flush_bits_ftqPtr_value,
  input  [3:0]  io_fromRob_flush_bits_ftqOffset,
  input         io_fromRob_isInterrupt_valid,
  input         io_fromRob_isInterrupt_bits,
  input         io_faultCsrUop_valid,
  input  [8:0]  io_faultCsrUop_bits_fuOpType,
  input  [21:0] io_faultCsrUop_bits_imm,
  input         io_faultCsrUop_bits_ftqInfo_ftqPtr_flag,
  input  [5:0]  io_faultCsrUop_bits_ftqInfo_ftqPtr_value,
  input  [3:0]  io_faultCsrUop_bits_ftqInfo_ftqOffset,
  input         io_readClear,
  output logic io_currentTrapInst_valid,
  output logic [31:0] io_currentTrapInst_bits
);
logic         flush_valid_q;
  logic         flush_ptr_wrap_q;
  logic  [5:0]  flush_ptr_index_q;
  logic  [3:0]  flush_offset_q;
  logic         entry_valid_q;
  logic  [31:0] trap_instruction_q;
  logic         trap_ptr_wrap_q;
  logic  [5:0]  trap_ptr_index_q;
  logic  [3:0]  trap_offset_q;
  logic [6:0]  fault_position;
  always_comb begin
    fault_position = {io_faultCsrUop_bits_ftqInfo_ftqPtr_flag, io_faultCsrUop_bits_ftqInfo_ftqPtr_value};
  end
  logic [6:0]  trap_position;
  always_comb begin
    trap_position = {trap_ptr_wrap_q, trap_ptr_index_q};
  end
  logic flush_and_valid;
  always_comb begin
    flush_and_valid = flush_valid_q & entry_valid_q;
  end
  logic [6:0]  flush_position;
  always_comb begin
    flush_position = {flush_ptr_wrap_q, flush_ptr_index_q};
  end
  logic trap_is_younger;
  always_comb begin
    trap_is_younger = trap_position == flush_position & trap_offset_q > flush_offset_q
    | trap_ptr_wrap_q ^ flush_ptr_wrap_q
    ^ trap_ptr_index_q > flush_ptr_index_q;
  end
  logic fault_survives_flush;
  always_comb begin
    fault_survives_flush = io_faultCsrUop_valid
    & ~(fault_position == flush_position
        & io_faultCsrUop_bits_ftqInfo_ftqOffset > flush_offset_q
        | io_faultCsrUop_bits_ftqInfo_ftqPtr_flag ^ flush_ptr_wrap_q
        ^ io_faultCsrUop_bits_ftqInfo_ftqPtr_value > flush_ptr_index_q);
  end
  logic interrupt_clears_trap;
  always_comb begin
    interrupt_clears_trap = io_readClear | trap_position == flush_position
    & trap_offset_q == flush_offset_q & io_fromRob_isInterrupt_valid
    & io_fromRob_isInterrupt_bits;
  end
  logic decode_trap_available;
  always_comb begin
    decode_trap_available = io_fromDecode_trapInstInfo_valid & ~entry_valid_q;
  end
  logic [31:0] csr_instruction;
  always_comb begin
    csr_instruction = {io_faultCsrUop_bits_imm[11:0],
     io_faultCsrUop_bits_imm[16:12],
     io_faultCsrUop_bits_fuOpType[2:0],
     io_faultCsrUop_bits_imm[21:17],
     7'h73};
  end
  logic csr_instruction_older;
  always_comb begin
    csr_instruction_older = fault_position == trap_position
    & io_faultCsrUop_bits_ftqInfo_ftqOffset < trap_offset_q
    | io_faultCsrUop_bits_ftqInfo_ftqPtr_flag ^ trap_ptr_wrap_q
    ^ io_faultCsrUop_bits_ftqInfo_ftqPtr_value < trap_ptr_index_q;
  end
  always @(posedge clock) begin
    flush_valid_q <= io_fromRob_flush_valid;
    flush_ptr_wrap_q <= io_fromRob_flush_bits_ftqPtr_flag;
    flush_ptr_index_q <= io_fromRob_flush_bits_ftqPtr_value;
    flush_offset_q <= io_fromRob_flush_bits_ftqOffset;
    if (flush_and_valid) begin
      if (trap_is_younger) begin
        if (fault_survives_flush) begin
          trap_instruction_q <= csr_instruction;
          trap_ptr_wrap_q <= io_faultCsrUop_bits_ftqInfo_ftqPtr_flag;
          trap_ptr_index_q <= io_faultCsrUop_bits_ftqInfo_ftqPtr_value;
          trap_offset_q <= io_faultCsrUop_bits_ftqInfo_ftqOffset;
        end
      end
      else if (interrupt_clears_trap
               | ~(io_faultCsrUop_valid
                   & ~(fault_position == flush_position
                       & io_faultCsrUop_bits_ftqInfo_ftqOffset > flush_offset_q
                       | io_faultCsrUop_bits_ftqInfo_ftqPtr_flag ^ flush_ptr_wrap_q
                       ^ io_faultCsrUop_bits_ftqInfo_ftqPtr_value > flush_ptr_index_q)
                   & csr_instruction_older)) begin
      end
      else begin
        trap_instruction_q <= csr_instruction;
        trap_ptr_wrap_q <= io_faultCsrUop_bits_ftqInfo_ftqPtr_flag;
        trap_ptr_index_q <= io_faultCsrUop_bits_ftqInfo_ftqPtr_value;
        trap_offset_q <= io_faultCsrUop_bits_ftqInfo_ftqOffset;
      end
    end
    else if (io_faultCsrUop_valid) begin
      if (~entry_valid_q | entry_valid_q & csr_instruction_older) begin
        trap_instruction_q <= csr_instruction;
        trap_ptr_wrap_q <= io_faultCsrUop_bits_ftqInfo_ftqPtr_flag;
        trap_ptr_index_q <= io_faultCsrUop_bits_ftqInfo_ftqPtr_value;
        trap_offset_q <= io_faultCsrUop_bits_ftqInfo_ftqOffset;
      end
    end
    else if (decode_trap_available) begin
      trap_instruction_q <=
        (&(io_fromDecode_trapInstInfo_bits_instr[1:0]))
          ? io_fromDecode_trapInstInfo_bits_instr
          : {16'h0, io_fromDecode_trapInstInfo_bits_instr[15:0]};
      trap_ptr_wrap_q <= io_fromDecode_trapInstInfo_bits_ftqPtr_flag;
      trap_ptr_index_q <= io_fromDecode_trapInstInfo_bits_ftqPtr_value;
      trap_offset_q <= io_fromDecode_trapInstInfo_bits_ftqOffset;
    end
  end // always @(posedge)
  always @(posedge clock or posedge reset) begin
    if (reset)
      entry_valid_q <= 1'h0;
    else if (flush_and_valid) begin
      if (trap_is_younger)
        entry_valid_q <= fault_survives_flush & entry_valid_q;
      else
        entry_valid_q <= ~interrupt_clears_trap & entry_valid_q;
    end
    else
      entry_valid_q <= io_faultCsrUop_valid | decode_trap_available | entry_valid_q;
  end // always @(posedge, posedge)
always_comb begin
    io_currentTrapInst_valid = entry_valid_q;
  end
  always_comb begin
    io_currentTrapInst_bits = trap_instruction_q;
  end
endmodule

module TrapInstMod(
  input         clock,
  input         reset,
  input         io_fromDecode_trapInstInfo_valid,
  input  [31:0] io_fromDecode_trapInstInfo_bits_instr,
  input         io_fromDecode_trapInstInfo_bits_ftqPtr_flag,
  input  [5:0]  io_fromDecode_trapInstInfo_bits_ftqPtr_value,
  input  [3:0]  io_fromDecode_trapInstInfo_bits_ftqOffset,
  input         io_fromRob_flush_valid,
  input         io_fromRob_flush_bits_ftqPtr_flag,
  input  [5:0]  io_fromRob_flush_bits_ftqPtr_value,
  input  [3:0]  io_fromRob_flush_bits_ftqOffset,
  input         io_fromRob_isInterrupt_valid,
  input         io_fromRob_isInterrupt_bits,
  input         io_faultCsrUop_valid,
  input  [8:0]  io_faultCsrUop_bits_fuOpType,
  input  [21:0] io_faultCsrUop_bits_imm,
  input         io_faultCsrUop_bits_ftqInfo_ftqPtr_flag,
  input  [5:0]  io_faultCsrUop_bits_ftqInfo_ftqPtr_value,
  input  [3:0]  io_faultCsrUop_bits_ftqInfo_ftqOffset,
  input         io_readClear,
  output        io_currentTrapInst_valid,
  output [31:0] io_currentTrapInst_bits
);
  xs_TrapInstMod_core u_core (
    .clock(clock),
    .reset(reset),
    .io_fromDecode_trapInstInfo_valid(io_fromDecode_trapInstInfo_valid),
    .io_fromDecode_trapInstInfo_bits_instr(io_fromDecode_trapInstInfo_bits_instr),
    .io_fromDecode_trapInstInfo_bits_ftqPtr_flag(io_fromDecode_trapInstInfo_bits_ftqPtr_flag),
    .io_fromDecode_trapInstInfo_bits_ftqPtr_value(io_fromDecode_trapInstInfo_bits_ftqPtr_value),
    .io_fromDecode_trapInstInfo_bits_ftqOffset(io_fromDecode_trapInstInfo_bits_ftqOffset),
    .io_fromRob_flush_valid(io_fromRob_flush_valid),
    .io_fromRob_flush_bits_ftqPtr_flag(io_fromRob_flush_bits_ftqPtr_flag),
    .io_fromRob_flush_bits_ftqPtr_value(io_fromRob_flush_bits_ftqPtr_value),
    .io_fromRob_flush_bits_ftqOffset(io_fromRob_flush_bits_ftqOffset),
    .io_fromRob_isInterrupt_valid(io_fromRob_isInterrupt_valid),
    .io_fromRob_isInterrupt_bits(io_fromRob_isInterrupt_bits),
    .io_faultCsrUop_valid(io_faultCsrUop_valid),
    .io_faultCsrUop_bits_fuOpType(io_faultCsrUop_bits_fuOpType),
    .io_faultCsrUop_bits_imm(io_faultCsrUop_bits_imm),
    .io_faultCsrUop_bits_ftqInfo_ftqPtr_flag(io_faultCsrUop_bits_ftqInfo_ftqPtr_flag),
    .io_faultCsrUop_bits_ftqInfo_ftqPtr_value(io_faultCsrUop_bits_ftqInfo_ftqPtr_value),
    .io_faultCsrUop_bits_ftqInfo_ftqOffset(io_faultCsrUop_bits_ftqInfo_ftqOffset),
    .io_readClear(io_readClear),
    .io_currentTrapInst_valid(io_currentTrapInst_valid),
    .io_currentTrapInst_bits(io_currentTrapInst_bits)
  );
endmodule
