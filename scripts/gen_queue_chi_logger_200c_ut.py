#!/usr/bin/env python3
"""Generate the focused differential testbench for the remaining 200c leaves."""
import argparse
from pathlib import Path
import re

REPO = Path(__file__).resolve().parents[1]
GOLDEN = Path("/home/eda/xs-env/G1-canonical/golden-rtl")
TARGETS = ["Queue1_CHIDAT", "Queue1_CHIRSP", "SpillRegister_7", "TLLogger_1", "TLLogger_2"]
PORT_RE = re.compile(r"^\s*(input|output)\s+(?:\[(\d+):0\]\s+)?(\w+)\s*,?\s*$")


def parse_ports(module):
    text = (GOLDEN / (module + ".sv")).read_text()
    i = text.index("module " + module + "(")
    j = text.index("\n);", i)
    result = []
    for line in text[i:j].splitlines()[1:]:
        m = PORT_RE.match(line)
        if not m:
            raise ValueError("cannot parse %s line %r" % (module, line))
        result.append((m.group(1), 1 if m.group(2) is None else int(m.group(2)) + 1, m.group(3)))
    return result


def decl(width, name):
    return "logic %s%s;" % ("[%d:0] " % (width - 1) if width != 1 else "", name)


def signal_name(module, prefix, name):
    if name in ("clock", "reset"):
        return name
    return "%s_%s_%s" % (prefix, module, name)


def emit_instance(module, suffix, ports):
    prefix = "g" if suffix == "" else "i"
    lines = ["  %s %s (" % (module + suffix, prefix + "_" + module)]
    output_names = {n for d, _, n in ports if d == "output"}
    for idx, (_, _, name) in enumerate(ports):
        target = signal_name(module, prefix, name)
        lines.append("    .%s(%s)%s" % (name, target, "," if idx + 1 < len(ports) else ""))
    lines.extend(["  );", ""])
    return lines


def render():
    all_ports = {m: parse_ports(m) for m in TARGETS}
    lines = [
        "// Focused G1 differential regression for the five remaining 200c leaves.",
        "// Inputs are driven on falling edges; every known observable output is",
        "// compared after the following rising edge against the untouched golden.",
        "`timescale 1ns/1ps",
        "module tb;",
        "  bit clock = 1'b0;",
        "  logic reset = 1'b0;",
        "  integer errors = 0, checks = 0;",
        "  integer cycles = 0;",
        "  always #5 clock = ~clock;",
        "",
    ]
    for module, ports in all_ports.items():
        lines.append("  // %s" % module)
        for direction, width, name in ports:
            if name in ("clock", "reset"):
                continue
            if direction == "input":
                lines.append("  %s" % decl(width, signal_name(module, "g", name)))
                lines.append("  %s" % decl(width, signal_name(module, "i", name)))
            else:
                lines.append("  %s" % decl(width, signal_name(module, "g", name)))
                lines.append("  %s" % decl(width, signal_name(module, "i", name)))
        lines.append("")
        lines.extend(emit_instance(module, "", ports))
        lines.extend(emit_instance(module, "_xs", ports))

    lines.extend([
        "  task automatic check_outputs;",
        "    begin",
    ])
    for module, ports in all_ports.items():
        for direction, _, name in ports:
            if direction != "output":
                continue
            # Payload pins are unspecified while their valid pin is low: the
            # golden and implementation intentionally leave those registers
            # unreset, so random init may differ without observable behavior.
            if module in ("Queue1_CHIDAT", "Queue1_CHIRSP") and name.startswith("io_deq_bits_"):
                valid_guard = "(%s === 1'b0 || %s === 1'b0)" % (signal_name(module, "g", "io_deq_valid"), signal_name(module, "i", "io_deq_valid"))
            elif module == "SpillRegister_7" and name.startswith("io_out_bits_"):
                valid_guard = "(%s === 1'b0 || %s === 1'b0)" % (signal_name(module, "g", "io_out_valid"), signal_name(module, "i", "io_out_valid"))
            else:
                valid_guard = "1'b0"
            lines.extend([
                "      if (!%s && !$isunknown(%s) && !$isunknown(%s)) begin" % (valid_guard, signal_name(module, "g", name), signal_name(module, "i", name)),
                "        checks = checks + 1;",
                "        if (%s !== %s) begin" % (signal_name(module, "g", name), signal_name(module, "i", name)),
                "          errors = errors + 1;",
                "          if (errors <= 20) $display(\"MISMATCH %s.%s g=%%h i=%%h\", %s, %s);" % (module, name, signal_name(module, "g", name), signal_name(module, "i", name)),
                "        end",
                "      end",
            ])
    lines.extend([
        "    end",
        "  endtask",
        "",
        "  initial begin",
        "    // Delay the reset edge until VCS has applied +vcs+initreg+random.",
        "    #1 reset = 1'b1;",
        "    repeat (3) @(negedge clock);",
        "    reset = 1'b0;",
        "    repeat (200000) begin",
        "      @(negedge clock);",
        "      cycles = cycles + 1;",
    ])
    # Drive each unique input exactly once. Inputs shared by modules are
    # intentionally assigned repeatedly to keep each generated block obvious.
    for module, ports in all_ports.items():
        for direction, _, name in ports:
            if direction != "input" or name in ("clock", "reset"):
                continue
            lines.append("      %s = $urandom;" % signal_name(module, "g", name))
            lines.append("      %s = %s;" % (signal_name(module, "i", name), signal_name(module, "g", name)))
    lines.extend([
        "      @(posedge clock);",
        "      #1 check_outputs();",
        "    end",
        "    $display(\"cycles=%0d checks=%0d errors=%0d\", cycles, checks, errors);",
        "    if (errors != 0 || checks == 0) $fatal(1, \"differential test failed\");",
        "    $display(\"TEST PASSED\");",
        "    $finish;",
        "  end",
        "endmodule",
        "",
    ])
    return "\n".join(lines)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--check", action="store_true")
    ap.add_argument("--out", default=str(REPO / "verif/ut/QueueChiSpillLogger200c/tb.sv"))
    args = ap.parse_args()
    path = Path(args.out)
    generated = render()
    if args.check:
        if not path.exists() or path.read_text() != generated:
            print("DRIFT: %s" % path)
            return 1
    elif not path.exists() or path.read_text() != generated:
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(generated)
    print("generated %s" % path)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
