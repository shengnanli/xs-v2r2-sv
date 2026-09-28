#!/usr/bin/env python3
"""Generate fifteen tiny readable arithmetic/bit-map leaves and their UT harness."""
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
RTL = ROOT / "rtl/backend"
# --check：内存里重生成，与仓内现文件逐字比对，不写盘；有差异非零退出（进 gate_all 幂等闸）
CHECK = "--check" in sys.argv[1:]
_DRIFT = []
_COUNT = [0]

def _put(path: Path, text: str) -> None:
    _COUNT[0] += 1
    if CHECK:
        if not path.exists() or path.read_text() != text:
            _DRIFT.append(str(path.relative_to(ROOT)))
    else:
        path.write_text(text)

def emit(name: str, text: str) -> None:
    _put(RTL / f"{name}.sv", text)

def modular_sub(name: str, width: int) -> None:
    emit(name, f"""// {width}-bit modular subtractor used by compact datapath/index arithmetic.
// Borrow and overflow intentionally wrap at the public interface width.
// A semantic core and exact-name wrapper separate behavior from integration.
module xs_{name}_core (
  input logic [{width-1}:0] minuend, subtrahend,
  output logic [{width-1}:0] difference
);
  assign difference = minuend - subtrahend;
endmodule
module {name} (
  input logic [{width-1}:0] io_a,
  input logic [{width-1}:0] io_b,
  output logic [{width-1}:0] io_c
);
  xs_{name}_core u_core (.minuend(io_a), .subtrahend(io_b), .difference(io_c));
endmodule
""")

def close_sub(name: str, width: int, shift_lhs: bool) -> None:
    lhs = "{io_adder_op0, 1'b0}" if shift_lhs else "{1'b0, io_adder_op0}"
    mode = "left-shifted first operand" if shift_lhs else "zero-extended operands"
    emit(name, f"""// Close-path floating-point subtractor with {mode}.
// The {width+1}-bit result preserves the borrow/sign information required downstream.
// Explicit extension documents sizing and avoids implicit-expression ambiguity.
module xs_{name}_core (
  input logic [{width-1}:0] lhs, rhs,
  output logic [{width}:0] difference
);
  assign difference = {("{lhs, 1'b0}" if shift_lhs else "{1'b0, lhs}")} - {{1'b0, rhs}};
endmodule
module {name} (
  input logic [{width-1}:0] io_adder_op0,
  input logic [{width-1}:0] io_adder_op1,
  output logic [{width}:0] io_result
);
  xs_{name}_core u_core (.lhs(io_adder_op0), .rhs(io_adder_op1), .difference(io_result));
endmodule
""")

modular_sub("Adder", 11)
modular_sub("Adder_2", 8)

emit("SubModule", """// Unsigned 64-bit subtraction with an explicit 65-bit extended result.
// The upper bit retains the modular borrow/carry convention used by the ALU.
// Two's-complement addition is widened before the operation so bit 64 is carry-out.
module xs_SubModule_core(input logic [63:0] lhs, rhs, output logic [64:0] difference);
  assign difference = {1'b0, lhs} + {1'b0, ~rhs} + 65'd1;
endmodule
module SubModule(input logic [63:0] io_src_0, input logic [63:0] io_src_1,
                 output logic [64:0] io_sub);
  xs_SubModule_core u_core(.lhs(io_src_0), .rhs(io_src_1), .difference(io_sub));
endmodule
""")

emit("AddModule", """// Integer adder providing independent XLEN and word-width results.
// The word path uses its dedicated first operand and the low half of source one.
// Both paths intentionally discard carry beyond their public widths.
module xs_AddModule_core(input logic [63:0] lhs, rhs, input logic [31:0] word_lhs,
                         output logic [63:0] full_sum, output logic [31:0] word_sum);
  assign full_sum = lhs + rhs;
  assign word_sum = word_lhs + rhs[31:0];
endmodule
module AddModule(input logic [63:0] io_src_0, input logic [63:0] io_src_1,
                 input logic [31:0] io_srcw, output logic [63:0] io_add,
                 output logic [31:0] io_addw);
  xs_AddModule_core u_core(.lhs(io_src_0), .rhs(io_src_1), .word_lhs(io_srcw),
                           .full_sum(io_add), .word_sum(io_addw));
endmodule
""")

emit("ConditionalZeroModule", """// Conditional-zero operation shared by czero.eqz and czero.nez.
// is_nez selects which condition sense suppresses the input value.
// Reduction OR performs the architectural zero comparison across all 64 bits.
module xs_ConditionalZeroModule_core(input logic [63:0] condition, value,
                                     input logic is_nez, output logic [63:0] result);
  logic condition_is_zero;
  assign condition_is_zero = ~(|condition);
  assign result = (condition_is_zero ^ is_nez) ? 64'b0 : value;
endmodule
module ConditionalZeroModule(input logic [63:0] io_condition,
  input logic [63:0] io_value, input logic io_isNez, output logic [63:0] io_condRes);
  xs_ConditionalZeroModule_core u_core(.condition(io_condition), .value(io_value),
    .is_nez(io_isNez), .result(io_condRes));
endmodule
""")

maps = {
 "000000000000001010100000000": [12,10,8],
 "000011100000000000001010101": [22,21,20,6,4,2,0],
}
for suffix, bits in maps.items():
    cname=f"UIntCompressor_27_{suffix}"; ename=f"UIntExtractor_27_{suffix}"
    packed=", ".join(f"io_in[{b}]" for b in bits)
    emit(cname, f"""// Sparse 27-bit field compressor for mask {suffix}.
// Selected source bits are packed from highest listed position to output MSB.
// Unselected bits are deliberately discarded; no arithmetic is performed.
module {cname}(input logic [26:0] io_in, output logic [{len(bits)-1}:0] io_out);
  assign io_out = {{{packed}}};
endmodule
""")
    assignments="\n".join(f"  assign io_out[{b}] = io_in[{len(bits)-1-i}];" for i,b in enumerate(bits))
    emit(ename, f"""// Sparse 27-bit field extractor for mask {suffix}.
// Packed input bits return to their architectural positions; all others are zero.
// Explicit per-position assignments make the inverse mapping directly auditable.
module {ename}(input logic [{len(bits)-1}:0] io_in, output logic [26:0] io_out);
  always_comb begin
    io_out = 27'b0;
""" + "\n".join(f"    io_out[{b}] = io_in[{len(bits)-1-i}];" for i,b in enumerate(bits)) + """
  end
endmodule
""")

close_sub("ClosePathAdder", 53, False)
close_sub("ClosePathAdder_2", 53, True)
close_sub("ClosePathAdderF16Pipeline", 11, False)
close_sub("ClosePathAdderF16Pipeline_2", 11, True)
close_sub("ClosePathF32WidenF16MixedPipelineAdder", 24, False)
close_sub("ClosePathF32WidenF16MixedPipelineAdder_2", 24, True)

if CHECK:
    if _DRIFT:
        print("gen_readable_leaves15 --check: DRIFT " + " ".join(_DRIFT))
        sys.exit(1)
    print(f"gen_readable_leaves15 --check: OK ({_COUNT[0]} files)")
