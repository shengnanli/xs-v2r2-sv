#!/usr/bin/env python3
"""Generate the remaining 200c queue, spill, and TileLink logger leaves.

The G1 golden module declarations are the source of port order and widths.  The
emitted files contain a readable core followed by a same-port wrapper; no
firtool implementation text is copied into the generated RTL.
"""
import argparse
import re
from pathlib import Path

REPO = Path(__file__).resolve().parents[1]
GOLDEN = Path("/home/eda/xs-env/G1-canonical/golden-rtl")

TARGETS = {
    "Queue1_CHIDAT": "uncore",
    "Queue1_CHIRSP": "uncore",
    "SpillRegister_7": "uncore",
    "TLLogger_1": "uncore",
    "TLLogger_2": "uncore",
}

PORT_RE = re.compile(r"^\s*(input|output)\s+(?:\[(\d+):0\]\s+)?(\w+)\s*,?\s*$")


def parse_ports(module: str):
    text = (GOLDEN / f"{module}.sv").read_text()
    start = text.index(f"module {module}(")
    end = text.index("\n);", start)
    result = []
    for line in text[start:end].splitlines()[1:]:
        match = PORT_RE.match(line)
        if not match:
            raise ValueError(f"cannot parse {module} port line: {line!r}")
        direction, msb, name = match.groups()
        result.append((direction, 1 if msb is None else int(msb) + 1, name))
    if not result:
        raise ValueError(f"empty port list for {module}")
    return result


def sv_decl(direction: str, width: int, name: str) -> str:
    packed = "" if width == 1 else f"[{width - 1}:0] "
    return f"  {direction:<6} logic {packed}{name}"


def emit_ports(ports) -> str:
    return ",\n".join(sv_decl(*port) for port in ports)


def queue_fields(ports, prefix: str):
    return [(name[len(prefix):], width, name)
            for direction, width, name in ports
            if direction == "input" and name.startswith(prefix)]


def emit_queue(module: str, ports) -> str:
    fields = queue_fields(ports, "io_enq_bits_")
    width = sum(item[1] for item in fields)
    # Port order is the lsb-first Bundle order in G1.  The packed assignment
    # therefore emits the fields in reverse order (last field at the MSB).
    slices = []
    lo = 0
    for field, field_width, _ in fields:
        slices.append((field, lo + field_width - 1, lo))
        lo += field_width
    assert lo == width

    lines = [
        f"// {module}.sv — one-entry CHI DAT queue with ready/valid flow-through.",
        "// The payload order and widths are derived from the read-only G1 golden.",
        "// Queue state is shared with xs_ChiselQueue1_core; payload remains unreset.",
        "",
        f"module xs_{module}_core #(",
        f"  parameter int unsigned W = {width}",
        ")(",
        "  input  logic clock,",
        "  input  logic reset,",
        "  input  logic enq_valid,",
        "  output logic enq_ready,",
        "  input  logic [W-1:0] enq_word,",
        "  input  logic deq_ready,",
        "  output logic deq_valid,",
        "  output logic [W-1:0] deq_word",
        ");",
        "  xs_ChiselQueue1_core #(.W(W), .PIPE(1'b1)) queue (",
        "    .clock(clock), .reset(reset),",
        "    .enq_valid(enq_valid), .enq_ready(enq_ready), .enq_word(enq_word),",
        "    .deq_valid(deq_valid), .deq_ready(deq_ready), .deq_word(deq_word) );",
        "endmodule",
        "",
        f"module {module} (",
        emit_ports(ports),
        ");",
        f"  logic [{width - 1}:0] enq_word, deq_word;",
        "  assign enq_word = {",
    ]
    lines.extend(f"    {name}{',' if idx + 1 < len(fields) else ''}"
                 for idx, (_, _, name) in enumerate(reversed(fields)))
    lines.extend([
        "  };",
        f"  xs_{module}_core #(.W({width})) u_core (",
        "    .clock(clock), .reset(reset),",
        "    .enq_valid(io_enq_valid), .enq_ready(io_enq_ready),",
        "    .enq_word(enq_word), .deq_ready(io_deq_ready),",
        "    .deq_valid(io_deq_valid), .deq_word(deq_word) );",
    ])
    for field, hi_bit, lo_bit in slices:
        output_name = f"io_deq_bits_{field}"
        rhs = f"deq_word[{hi_bit}]" if hi_bit == lo_bit else f"deq_word[{hi_bit}:{lo_bit}]"
        lines.append(f"  assign {output_name} = {rhs};")
    lines.extend(["endmodule", ""])
    return "\n".join(lines)


def emit_chirsp(ports) -> str:
    text = emit_queue("Queue1_CHIRSP", ports)
    return text.replace(
        "// Queue1_CHIRSP.sv — one-entry CHI DAT queue with ready/valid flow-through.\n",
        "// Queue1_CHIRSP.sv — one-entry CHI response queue with ready/valid flow-through.\n",
    )


def emit_spill(ports) -> str:
    bits_in = [name for direction, _, name in ports
               if direction == "input" and name.startswith("io_in_bits_")]
    bits_out = [name for direction, _, name in ports
                if direction == "output" and name.startswith("io_out_bits_")]
    assert len(bits_in) == len(bits_out) == 32
    lines = [
        "// SpillRegister_7.sv — two-stage spill buffer for a 32-bit scalar bus.",
        "// The shared core preserves ordering under backpressure: the older item",
        "// moves to the spill stage before a newer item enters the first stage.",
        "// Valid bits reset asynchronously; payload bits intentionally do not reset.",
        "",
        "module SpillRegister_7 (",
        emit_ports(ports),
        ");",
        "  logic [31:0] in_payload, out_payload;",
        "  assign in_payload = {",
    ]
    lines.extend(f"    {name}{',' if idx + 1 < len(bits_in) else ''}"
                 for idx, name in enumerate(bits_in))
    lines.extend([
        "  };",
        "  xs_SpillRegister_core #(.W(32)) u_core (",
        "    .clock(clock), .reset(reset),",
        "    .in_ready(), .in_valid(io_in_valid), .in_payload(in_payload),",
        "    .out_ready(io_out_ready), .out_valid(io_out_valid),",
        "    .out_payload(out_payload) );",
    ])
    for idx, name in enumerate(bits_out):
        lines.append(f"  assign {name} = out_payload[{31 - idx}];")
    lines.extend(["endmodule", ""])
    return "\n".join(lines)


def emit_logger(module: str, ports) -> str:
    lines = [
        f"// {module}.sv — combinational TileLink A/D transparency logger.",
        "// It has no storage or side effects: every observable field is wired",
        "// from the corresponding channel on the opposite side of the bridge.",
        "",
        f"module xs_{module}_core (",
        emit_ports(ports),
        ");",
    ]
    for direction, _, name in ports:
        if direction != "output":
            continue
        if name == "auto_in_a_ready":
            source = "auto_out_a_ready"
        elif name.startswith("auto_in_d_"):
            source = name.replace("auto_in_d_", "auto_out_d_", 1)
        elif name.startswith("auto_out_a_"):
            source = name.replace("auto_out_a_", "auto_in_a_", 1)
        elif name == "auto_out_d_ready":
            source = "auto_in_d_ready"
        else:
            raise ValueError(f"unmapped logger output {module}.{name}")
        lines.append(f"  assign {name} = {source};")
    lines.extend(["endmodule", "", f"module {module} (", emit_ports(ports), ");"])
    lines.append(f"  xs_{module}_core u_core (")
    lines.extend(f"    .{name}({name}){',' if idx + 1 < len(ports) else ''}"
                 for idx, (_, _, name) in enumerate(ports))
    lines.extend(["  );", "endmodule", ""])
    return "\n".join(lines)


def render(module: str) -> str:
    ports = parse_ports(module)
    if module == "Queue1_CHIDAT":
        return emit_queue(module, ports)
    if module == "Queue1_CHIRSP":
        return emit_chirsp(ports)
    if module == "SpillRegister_7":
        return emit_spill(ports)
    return emit_logger(module, ports)


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()
    drift = 0
    for module, subdir in TARGETS.items():
        path = REPO / "rtl" / subdir / f"{module}.sv"
        generated = render(module)
        current = path.read_text() if path.exists() else None
        if args.check:
            if current != generated:
                print(f"DRIFT: {path}")
                drift += 1
        elif current != generated:
            path.write_text(generated)
        print(f"{module}: {len(parse_ports(module))} ports")
    return drift


if __name__ == "__main__":
    raise SystemExit(main())
