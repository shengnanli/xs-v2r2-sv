#!/usr/bin/env python3
"""Generate readable BusErrorUnit and HPerfCounter leaves for the 200c wave.

The G1 files are used only for the wrapper port contract and the event-set
index map.  Behavioral RTL below is deliberately written as named state and
pipeline stages rather than copying firtool output.
"""
import argparse
import re
from pathlib import Path

REPO = Path(__file__).resolve().parents[1]
GOLDEN = Path("/home/eda/xs-env/G1-canonical/golden-rtl")

TARGETS = {
    "BusErrorUnit": "l2",
    "HPerfCounter": "backend",
    "HPerfCounter_13": "backend",
    "HPerfCounter_8": "backend",
}

PORT_RE = re.compile(r"^\s*(input|output)\s+(?:\[(\d+):(\d+)\]\s+)?(\w+)\s*,?\s*$")


def parse_ports(module: str):
    text = (GOLDEN / f"{module}.sv").read_text()
    start = text.index(f"module {module}(")
    end = text.index("\n);", start)
    ports = []
    for line in text[start:end].splitlines()[1:]:
        m = PORT_RE.match(line)
        if not m:
            raise ValueError(f"cannot parse {module} port line: {line!r}")
        direction, msb, lsb, name = m.groups()
        width = 1 if msb is None else abs(int(msb) - int(lsb)) + 1
        ports.append((direction, width, name))
    if not ports:
        raise ValueError(f"empty port list for {module}")
    return ports


def decl(direction: str, width: int, name: str) -> str:
    packed = "" if width == 1 else f"[{width - 1}:0] "
    return f"  {direction:<6} logic {packed}{name}"


def emit_ports(ports) -> str:
    return ",\n".join(decl(*port) for port in ports)


def hperf_map(module: str):
    """Return table width, index width, and event table source for each index."""
    ports = {name: (direction, width) for direction, width, name in parse_ports(module)}
    if module == "HPerfCounter":
        table_size, index_bits = 64, 6
        values = {index: "6'h0" for index in range(table_size)}
        for index in range(1, 58):
            values[index] = "6'h0" if index == 24 else f"io_events_sets_{index}_value"
        return table_size, index_bits, values
    if module == "HPerfCounter_13":
        table_size, index_bits = 128, 7
        values = {index: "6'h0" for index in range(table_size)}
        for index in range(1, 98):
            if index == 43:
                values[index] = "6'h0"
            elif index == 96:
                values[index] = "6'h1"
            else:
                values[index] = f"io_events_sets_{index}_value"
        return table_size, index_bits, values
    if module == "HPerfCounter_8":
        table_size, index_bits = 128, 7
        values = {index: ("io_events_sets_0_value" if index >= 68 else
                          f"io_events_sets_{index}_value")
                  for index in range(table_size)}
        return table_size, index_bits, values
    raise ValueError(module)


def emit_hperf_core() -> str:
    return """// xs_HPerfCounter_core.sv — shared four-stage event reduction pipeline.
// Each wrapper supplies its explicit table, retaining reserved-slot behavior.
// Registered reduction stages preserve one-cycle event accumulation and explicit slot priority.
module xs_HPerfCounter_core #(
  parameter int unsigned EVENT_INDEX_BITS = 6,
  parameter int unsigned TABLE_SIZE = 64
) (
  input  logic                         clock,
  input  logic [63:0]                  hpm_event,
  input  logic [5:0]                   event_values [0:TABLE_SIZE-1],
  output logic [5:0]                   perf_value
);
  logic [5:0] increment_0_q, increment_1_q;
  logic [5:0] increment_2_q, increment_3_q;
  // Only operation bits [2:0] participate in the reduction.  The golden
  // generator emits five-bit registers, but bits [4:3] are cone-dead.
  logic [2:0] operation_0_q, operation_1_q, operation_2_q;
  logic [2:0] operation_2_d_q;
  logic [5:0] step_0_q, step_1_q;
  logic [5:0] result_q, output_q;

  function automatic logic [5:0] reduce_pair(
    input logic [2:0] operation,
    input logic [5:0] left_value,
    input logic [5:0] right_value
  );
    if (operation[0])
      reduce_pair = left_value & right_value;
    else if (operation[1])
      reduce_pair = left_value ^ right_value;
    else if (operation[2])
      reduce_pair = left_value + right_value;
    else
      reduce_pair = left_value | right_value;
  endfunction

  always_ff @(posedge clock) begin
    increment_0_q <= event_values[hpm_event[EVENT_INDEX_BITS-1:0]];
    increment_1_q <= event_values[hpm_event[9+EVENT_INDEX_BITS:10]];
    increment_2_q <= event_values[hpm_event[19+EVENT_INDEX_BITS:20]];
    increment_3_q <= event_values[hpm_event[29+EVENT_INDEX_BITS:30]];
    operation_0_q <= hpm_event[42:40];
    operation_1_q <= hpm_event[47:45];
    operation_2_q <= hpm_event[52:50];
    operation_2_d_q <= operation_2_q;
    step_0_q <= reduce_pair(operation_0_q, increment_0_q, increment_1_q);
    step_1_q <= reduce_pair(operation_1_q, increment_2_q, increment_3_q);
    result_q <= reduce_pair(operation_2_d_q, step_0_q, step_1_q);
    output_q <= result_q;
  end

  assign perf_value = output_q;
endmodule
"""


def emit_hperf(module: str, ports) -> str:
    table_size, index_bits, values = hperf_map(module)
    lines = [
        f"// {module}.sv — readable wrapper for the event reduction leaf.",
        "// The explicit table below preserves reserved holes and variant timing.",
        "// Four registered stages match HardwarePerfMonitor's observable latency.",
        "",
        f"module {module} (",
        emit_ports(ports),
        ");",
        f"  logic [5:0] event_values [0:{table_size - 1}];",
    ]
    for index in range(table_size):
        lines.append(f"  assign event_values[{index}] = {values[index]};")
    lines.extend([
        "  xs_HPerfCounter_core #(",
        f"    .EVENT_INDEX_BITS({index_bits}), .TABLE_SIZE({table_size})",
        "  ) u_core (",
        "    .clock(clock), .hpm_event(io_hpm_event),",
        "    .event_values(event_values), .perf_value(io_perf_0_value)",
        "  );",
        "endmodule",
        "",
    ])
    return "\n".join(lines)


def emit_bus_error(ports) -> str:
    # The core uses semantic names; the wrapper below is the exact generated
    # spelling.  This makes register-map intent easy to review without hiding
    # any port adaptation in an include file.
    core = r'''// BusErrorUnit.sv — ECC error capture, interrupt status, and MMIO view.
// A request is accepted only when the D channel is ready.  Error capture has
// deterministic priority (L2, uncache, D-cache, I-cache), while accrued bits
// remember every raw valid pulse independent of the per-source enable bit.

module xs_BusErrorUnit_core (
  input  logic        clock,
  input  logic        reset,
  output logic        auto_in_a_ready,
  input  logic        auto_in_a_valid,
  input  logic [3:0]  auto_in_a_bits_opcode,
  input  logic [1:0]  auto_in_a_bits_size,
  input  logic [4:0]  auto_in_a_bits_source,
  input  logic [29:0] auto_in_a_bits_address,
  input  logic [7:0]  auto_in_a_bits_mask,
  input  logic [63:0] auto_in_a_bits_data,
  input  logic        auto_in_d_ready,
  output logic        auto_in_d_valid,
  output logic [3:0]  auto_in_d_bits_opcode,
  output logic [1:0]  auto_in_d_bits_size,
  output logic [4:0]  auto_in_d_bits_source,
  output logic [63:0] auto_in_d_bits_data,
  output logic        auto_int_out_0,
  input  logic        io_errors_icache_ecc_error_valid,
  input  logic [47:0] io_errors_icache_ecc_error_bits,
  input  logic        io_errors_dcache_ecc_error_valid,
  input  logic [47:0] io_errors_dcache_ecc_error_bits,
  input  logic        io_errors_uncache_ecc_error_valid,
  input  logic [47:0] io_errors_uncache_ecc_error_bits,
  input  logic        io_errors_l2_ecc_error_valid,
  input  logic [47:0] io_errors_l2_ecc_error_bits,
  output logic        io_interrupt
);
  logic [1:0] cause_q;
  logic [47:0] pad_q;
  logic [3:0] enable_q, global_interrupt_q;
  logic [3:0] accrued_q, local_interrupt_q;

  logic is_read;
  logic write_fire;
  logic [2:0] register_index;
  logic address_page_zero;
  logic write_cause, write_pad, write_enable, write_global;
  logic write_accrued, write_local;
  logic error_icache, error_dcache, error_uncache, error_l2;
  logic enabled_error;
  logic pending_error;
  logic [47:0] selected_error_bits;
  logic [47:0] read_data;

  assign is_read = (auto_in_a_bits_opcode == 4'h4);
  assign write_fire = auto_in_a_valid && auto_in_d_ready && !is_read;
  assign register_index = auto_in_a_bits_address[5:3];
  assign address_page_zero = (auto_in_a_bits_address[11:6] == 6'h0);

  assign write_cause = write_fire && address_page_zero && register_index == 3'd0 && auto_in_a_bits_mask[0];
  assign write_pad = write_fire && address_page_zero && register_index == 3'd1;
  assign write_enable = write_fire && address_page_zero && register_index == 3'd2 && auto_in_a_bits_mask[0];
  assign write_global = write_fire && address_page_zero && register_index == 3'd3 && auto_in_a_bits_mask[0];
  assign write_accrued = write_fire && address_page_zero && register_index == 3'd4 && auto_in_a_bits_mask[0];
  assign write_local = write_fire && address_page_zero && register_index == 3'd5 && auto_in_a_bits_mask[0];

  assign error_icache = io_errors_icache_ecc_error_valid && enable_q[0];
  assign error_dcache = io_errors_dcache_ecc_error_valid && enable_q[1];
  assign error_uncache = io_errors_uncache_ecc_error_valid && enable_q[2];
  assign error_l2 = io_errors_l2_ecc_error_valid && enable_q[3];
  assign enabled_error = error_icache || error_dcache || error_uncache || error_l2;
  assign pending_error = (cause_q == 2'd0) && enabled_error;

  always_comb begin
    if (error_l2)
      selected_error_bits = io_errors_l2_ecc_error_bits;
    else if (error_uncache)
      selected_error_bits = io_errors_uncache_ecc_error_bits;
    else if (error_dcache)
      selected_error_bits = io_errors_dcache_ecc_error_bits;
    else
      selected_error_bits = io_errors_icache_ecc_error_bits;
  end

  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      cause_q <= 2'd0;
      enable_q <= 4'hf;
      global_interrupt_q <= 4'h0;
      accrued_q <= 4'h0;
      local_interrupt_q <= 4'h0;
    end else begin
      if (write_cause)
        cause_q <= auto_in_a_bits_data[1:0];
      else if (pending_error) begin
        if (error_l2)
          cause_q <= 2'd3;
        else if (error_uncache)
          cause_q <= 2'd2;
        else if (error_dcache)
          cause_q <= 2'd1;
        else
          cause_q <= 2'd0;
      end

      if (write_enable)
        enable_q <= auto_in_a_bits_data[3:0];
      if (write_global)
        global_interrupt_q <= auto_in_a_bits_data[3:0];
      if (write_accrued)
        accrued_q <= auto_in_a_bits_data[3:0];
      else
        accrued_q <= accrued_q | {
          io_errors_l2_ecc_error_valid,
          io_errors_uncache_ecc_error_valid,
          io_errors_dcache_ecc_error_valid,
          io_errors_icache_ecc_error_valid
        };
      if (write_local)
        local_interrupt_q <= auto_in_a_bits_data[3:0];
    end
  end

  // The pad register has byte write enables and is intentionally not reset.
  // Until a write or an enabled error arrives, that matches the generated
  // design's uninitialized diagnostic payload behavior.
  always_ff @(posedge clock) begin
    if (write_pad && (|auto_in_a_bits_mask[5:0])) begin
      for (int byte_index = 0; byte_index < 6; byte_index++)
        if (auto_in_a_bits_mask[byte_index])
          pad_q[byte_index * 8 +: 8] <= auto_in_a_bits_data[byte_index * 8 +: 8];
    end else if (pending_error) begin
      pad_q <= selected_error_bits;
    end
  end

  always_comb begin
    // All six implemented registers are visible only in the low address page;
    // the remaining two slots read as zero.
    read_data = 48'h0;
    if (address_page_zero) begin
      case (register_index)
        3'd0: read_data = {{46{1'b0}}, cause_q};
        3'd1: read_data = pad_q;
        3'd2: read_data = {{44{1'b0}}, enable_q};
        3'd3: read_data = {{44{1'b0}}, global_interrupt_q};
        3'd4: read_data = {{44{1'b0}}, accrued_q};
        3'd5: read_data = {{44{1'b0}}, local_interrupt_q};
        default: read_data = 48'h0;
      endcase
    end
  end

  assign auto_in_a_ready = auto_in_d_ready;
  assign auto_in_d_valid = auto_in_a_valid;
  assign auto_in_d_bits_opcode = {3'h0, is_read};
  assign auto_in_d_bits_size = auto_in_a_bits_size;
  assign auto_in_d_bits_source = auto_in_a_bits_source;
  assign auto_in_d_bits_data = {16'h0, read_data};
  assign auto_int_out_0 = |(accrued_q & global_interrupt_q);
  assign io_interrupt = |(accrued_q & local_interrupt_q);
endmodule

'''
    return core + f"module BusErrorUnit (\n{emit_ports(ports)}\n);\n  xs_BusErrorUnit_core u_core (\n" + \
        "\n".join(f"    .{name}({name}){',' if i + 1 < len(ports) else ''}" for i, (_, _, name) in enumerate(ports)) + \
        "\n  );\nendmodule\n"


def render(module: str) -> str:
    ports = parse_ports(module)
    return emit_bus_error(ports) if module == "BusErrorUnit" else emit_hperf(module, ports)


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()
    drift = 0
    core_path = REPO / "rtl" / "backend" / "xs_HPerfCounter_core.sv"
    core_generated = emit_hperf_core()
    if args.check:
        if (core_path.read_text() if core_path.exists() else None) != core_generated:
            print(f"DRIFT: {core_path}")
            drift += 1
    elif (core_path.read_text() if core_path.exists() else None) != core_generated:
        core_path.write_text(core_generated)
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
