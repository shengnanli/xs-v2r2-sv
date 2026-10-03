#!/usr/bin/env python3
"""Generate seven readable ALU result/control leaf modules.

The generated files intentionally keep the golden module names and port
contracts.  Small ``xs_*_core`` modules expose the semantic operation to the
unit test; the wrappers are the integration boundary used by formal proof.
"""

import argparse
from pathlib import Path


RTL_DIR = Path(__file__).resolve().parents[1] / "rtl/backend"


OUTPUTS = {
    "AluResSel": r'''// Final result multiplexer at the output of the integer ALU datapath.
// The function code chooses among six already-computed result channels.
// Its encoding is sparse: the three middle values all select miscellaneous.
module xs_AluResSel_core (
  input  logic [2:0]  function_code,
  input  logic [63:0] add_result,
  input  logic [63:0] shift_result,
  input  logic [63:0] misc_result,
  input  logic [63:0] compare_result,
  input  logic [63:0] word_result,
  input  logic [63:0] conditional_result,
  output logic [63:0] selected_result
);
  always_comb begin
    case (function_code)
      3'd0: selected_result = shift_result;
      3'd1: selected_result = word_result;
      3'd2: selected_result = add_result;
      3'd3: selected_result = compare_result;
      3'd7: selected_result = conditional_result;
      default: selected_result = misc_result;
    endcase
  end
endmodule

module AluResSel (
  input  logic [2:0]  io_func,
  input  logic [63:0] io_addRes,
  input  logic [63:0] io_shiftRes,
  input  logic [63:0] io_miscRes,
  input  logic [63:0] io_compareRes,
  input  logic [63:0] io_wordRes,
  input  logic [63:0] io_condRes,
  output logic [63:0] io_aluRes
);
  xs_AluResSel_core u_select (
    .function_code(io_func),
    .add_result(io_addRes),
    .shift_result(io_shiftRes),
    .misc_result(io_miscRes),
    .compare_result(io_compareRes),
    .word_result(io_wordRes),
    .conditional_result(io_condRes),
    .selected_result(io_aluRes)
  );
endmodule
''',
    "ShiftResultSelect": r'''// Result multiplexer for 64-bit shifts, rotates, and single-bit operations.
// Inputs are already-computed datapath values; this leaf only decodes control.
// Rotate encodings deliberately ignore function_code[2] and [0].
module xs_ShiftResultSelect_core (
  input  logic [3:0]  function_code,
  input  logic [63:0] shift_left,
  input  logic [63:0] shift_right_logical,
  input  logic [63:0] shift_right_arithmetic,
  input  logic [63:0] rotate_left,
  input  logic [63:0] rotate_right,
  input  logic [63:0] bit_clear,
  input  logic [63:0] bit_set,
  input  logic [63:0] bit_invert,
  input  logic [63:0] bit_extract,
  output logic [63:0] selected_result
);
  always_comb begin
    if (function_code[3]) begin
      selected_result = function_code[1] ? rotate_right : rotate_left;
    end else begin
      case (function_code[2:0])
        3'd0, 3'd1: selected_result = shift_left;
        3'd2:       selected_result = bit_clear;
        3'd3:       selected_result = bit_set;
        3'd4:       selected_result = bit_invert;
        3'd5:       selected_result = shift_right_logical;
        3'd6:       selected_result = bit_extract;
        default:    selected_result = shift_right_arithmetic;
      endcase
    end
  end
endmodule

module ShiftResultSelect (
  input  logic [3:0]  io_func,
  input  logic [63:0] io_sll,
  input  logic [63:0] io_srl,
  input  logic [63:0] io_sra,
  input  logic [63:0] io_rol,
  input  logic [63:0] io_ror,
  input  logic [63:0] io_bclr,
  input  logic [63:0] io_bset,
  input  logic [63:0] io_binv,
  input  logic [63:0] io_bext,
  output logic [63:0] io_shiftRes
);
  xs_ShiftResultSelect_core u_select (
    .function_code(io_func),
    .shift_left(io_sll),
    .shift_right_logical(io_srl),
    .shift_right_arithmetic(io_sra),
    .rotate_left(io_rol),
    .rotate_right(io_ror),
    .bit_clear(io_bclr),
    .bit_set(io_bset),
    .bit_invert(io_binv),
    .bit_extract(io_bext),
    .selected_result(io_shiftRes)
  );
endmodule
''',
    "WordResultSelect": r'''// Result multiplexer for 32-bit integer word operations.
// It selects one precomputed value, then sign-extends that word to 64 bits.
// Only function_code[3:0] participates in this leaf's selection.
module xs_WordResultSelect_core (
  input  logic [8:0]  function_code,
  input  logic [31:0] shift_left_word,
  input  logic [31:0] shift_right_logical_word,
  input  logic [31:0] shift_right_arithmetic_word,
  input  logic [31:0] rotate_left_word,
  input  logic [31:0] rotate_right_word,
  input  logic [31:0] add_word,
  input  logic [31:0] subtract_word,
  output logic [63:0] selected_result
);
  logic [31:0] selected_word;

  always_comb begin
    if (function_code[3]) begin
      if (function_code[2])
        selected_word = function_code[0] ? rotate_right_word : rotate_left_word;
      else if (function_code[1])
        selected_word = shift_right_arithmetic_word;
      else
        selected_word = function_code[0] ? shift_right_logical_word : shift_left_word;
    end else begin
      selected_word = (function_code[2:0] == 3'b010) ? subtract_word : add_word;
    end
    selected_result = {{32{selected_word[31]}}, selected_word};
  end
endmodule

module WordResultSelect (
  input  logic [8:0]  io_func,
  input  logic [31:0] io_sllw,
  input  logic [31:0] io_srlw,
  input  logic [31:0] io_sraw,
  input  logic [31:0] io_rolw,
  input  logic [31:0] io_rorw,
  input  logic [31:0] io_addw,
  input  logic [31:0] io_subw,
  output logic [63:0] io_wordRes
);
  xs_WordResultSelect_core u_select (
    .function_code(io_func),
    .shift_left_word(io_sllw),
    .shift_right_logical_word(io_srlw),
    .shift_right_arithmetic_word(io_sraw),
    .rotate_left_word(io_rolw),
    .rotate_right_word(io_rorw),
    .add_word(io_addw),
    .subtract_word(io_subw),
    .selected_result(io_wordRes)
  );
endmodule
''',
    "MiscResultSelect": r'''// Select and format the ALU miscellaneous channel.  The hierarchy of
// function bits is significant: bit 5 overrides every lower family, then bit
// 4 chooses byte/pack or shift-add operations, and bit 3 selects subfamilies.
module xs_MiscResultSelect_core (
  input  logic [5:0]  function_code,
  input  logic [63:0] and_result,
  input  logic [63:0] or_result,
  input  logic [63:0] xor_result,
  input  logic [63:0] or_combine_bytes,
  input  logic [63:0] or_high_48,
  input  logic [63:0] sign_extend_byte,
  input  logic [63:0] pack_high,
  input  logic [63:0] sign_extend_half,
  input  logic [63:0] pack_word,
  input  logic [63:0] reverse_bits_in_bytes,
  input  logic [63:0] reverse_bytes,
  input  logic [63:0] pack,
  input  logic [63:0] source,
  output logic [63:0] selected_result
);
  logic [63:0] logic_result;

  always_comb begin
    case (function_code[2:1])
      2'd0:    logic_result = and_result;
      2'd1:    logic_result = or_result;
      2'd2:    logic_result = xor_result;
      default: logic_result = or_combine_bytes;
    endcase

    if (function_code[5]) begin
      selected_result = {48'b0,
                         logic_result[15:1] & {15{function_code[0]}},
                         logic_result[0]};
    end else if (function_code[4]) begin
      if (function_code[3]) begin
        case (function_code[1:0])
          2'd0:    selected_result = {31'b0, source[31:0], 1'b0};
          2'd1:    selected_result = {30'b0, source[31:0], 2'b0};
          2'd2:    selected_result = {29'b0, source[31:0], 3'b0};
          default: selected_result = {56'b0, source[15:8]};
        endcase
      end else begin
        case (function_code[1:0])
          2'd0:    selected_result = reverse_bits_in_bytes;
          2'd1:    selected_result = reverse_bytes;
          2'd2:    selected_result = pack;
          default: selected_result = or_high_48;
        endcase
      end
    end else if (function_code[3]) begin
      case (function_code[1:0])
        2'd0:    selected_result = sign_extend_byte;
        2'd1:    selected_result = pack_high;
        2'd2:    selected_result = sign_extend_half;
        default: selected_result = pack_word;
      endcase
    end else begin
      selected_result = logic_result;
    end
  end
endmodule

module MiscResultSelect (
  input  logic [5:0]  io_func,
  input  logic [63:0] io_and,
  input  logic [63:0] io_or,
  input  logic [63:0] io_xor,
  input  logic [63:0] io_orcb,
  input  logic [63:0] io_orh48,
  input  logic [63:0] io_sextb,
  input  logic [63:0] io_packh,
  input  logic [63:0] io_sexth,
  input  logic [63:0] io_packw,
  input  logic [63:0] io_revb,
  input  logic [63:0] io_rev8,
  input  logic [63:0] io_pack,
  input  logic [63:0] io_src,
  output logic [63:0] io_miscRes
);
  xs_MiscResultSelect_core u_select (
    .function_code(io_func),
    .and_result(io_and),
    .or_result(io_or),
    .xor_result(io_xor),
    .or_combine_bytes(io_orcb),
    .or_high_48(io_orh48),
    .sign_extend_byte(io_sextb),
    .pack_high(io_packh),
    .sign_extend_half(io_sexth),
    .pack_word(io_packw),
    .reverse_bits_in_bytes(io_revb),
    .reverse_bytes(io_rev8),
    .pack(io_pack),
    .source(io_src),
    .selected_result(io_miscRes)
  );
endmodule
''',
    "JumpDataModule": r'''// Datapath leaf shared by direct jumps, indirect jumps, and AUIPC.
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
''',
    "BranchModule": r'''// Resolve integer branches.  function_code[3:1] selects EQ, signed LT,
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
''',
    "CommitIDModule": r'''// Commit provenance presented to the simulation-only printer.  Keeping
// these values explicit makes the otherwise output-less module independently
// testable without changing its integration port contract.
module xs_CommitIDModule_core (
  input  logic [5:0]  hart_id,
  output logic [5:0]  printer_hart_id,
  output logic [39:0] commit_id,
  output logic        dirty
);
  assign printer_hart_id = hart_id;
  assign commit_id = 40'hB36A1A2A57;
  assign dirty = 1'b1;
endmodule

module CommitIDModule (
  input logic [5:0] io_hartId
);
  logic [5:0]  printer_hart_id;
  logic [39:0] commit_id;
  logic        dirty;

  xs_CommitIDModule_core u_commit_id (
    .hart_id(io_hartId),
    .printer_hart_id(printer_hart_id),
    .commit_id(commit_id),
    .dirty(dirty)
  );

  PrintCommitIDModule printCommitIDMod (
    .hartID(printer_hart_id),
    .commitID(commit_id),
    .dirty(dirty)
  );
endmodule
''',
}


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--check", action="store_true",
                        help="fail if generated files differ from the templates")
    args = parser.parse_args()

    drift = []
    for module, contents in OUTPUTS.items():
        path = RTL_DIR / f"{module}.sv"
        if args.check:
            if not path.exists() or path.read_text() != contents:
                drift.append(str(path))
        else:
            path.write_text(contents)

    if drift:
        print("gen_result_control7 --check: DRIFT: " + " ".join(drift))
        raise SystemExit(1)
    if args.check:
        print(f"gen_result_control7 --check: OK ({len(OUTPUTS)} files)")


if __name__ == "__main__":
    main()
