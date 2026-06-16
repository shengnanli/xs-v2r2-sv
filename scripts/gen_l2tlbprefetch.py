#!/usr/bin/env python3
"""Generate L2TlbPrefetch wrapper/variant/UT from the golden flat port list."""

import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
GOLDEN = ROOT / "golden/chisel-rtl/L2TlbPrefetch.sv"
RTL = ROOT / "rtl/memblock"
UT = ROOT / "verif/ut/L2TlbPrefetch"


def parse_ports():
    text = GOLDEN.read_text()
    start = text.index("module L2TlbPrefetch(")
    head = text[start : text.index(");", start) + 2]
    ports = []
    for line in head.splitlines()[1:]:
        line = line.strip().rstrip(",")
        if not line or line == ");":
            continue
        m = re.match(r"(input|output)\s+(\[[^]]+\]\s+)?(\S+)$", line)
        if not m:
            raise RuntimeError(f"cannot parse port line: {line}")
        direction, width, name = m.groups()
        ports.append((direction, (width or "").strip(), name))
    return ports


def decl_ports(ports):
    out = []
    for i, (direction, width, name) in enumerate(ports):
        comma = "," if i != len(ports) - 1 else ""
        gap = " " if width else ""
        out.append(f"  {direction:<6} {width}{gap}{name}{comma}")
    return "\n".join(out)


def adapter_body(module_name: str, ports):
    core_ports = [
        ".clock(clock)",
        ".reset(reset)",
        ".sfence_valid(io_sfence_valid)",
        ".satp_changed(io_csr_satp_changed)",
        ".vsatp_mode(io_csr_vsatp_mode)",
        ".vsatp_changed(io_csr_vsatp_changed)",
        ".hgatp_mode(io_csr_hgatp_mode)",
        ".hgatp_changed(io_csr_hgatp_changed)",
        ".priv_virt(io_csr_priv_virt)",
        ".in_valid(io_in_valid)",
        ".in_vpn(io_in_bits_vpn)",
        ".out_ready(io_out_ready)",
        ".out_valid(io_out_valid)",
        ".out_req_info(out_req_info_bus)",
    ]
    core_conn = ",\n    ".join(core_ports)
    # golden 未引出 source 端口（常量 prefetchID），仅在内部 struct 中保留。
    return f"""// 自动生成：scripts/gen_l2tlbprefetch.py —— 仅机械端口适配，核心逻辑在 xs_L2TlbPrefetch_core
module {module_name} import xs_l2tlbprefetch_pkg::*; (
{decl_ports(ports)}
);

  l2tlb_req_info_t out_req_info_bus;

  xs_L2TlbPrefetch_core u_core (
    {core_conn}
  );

  assign io_out_bits_req_info_vpn     = out_req_info_bus.vpn;
  assign io_out_bits_req_info_s2xlate = out_req_info_bus.s2xlate;

endmodule
"""


def gen_tb(ports):
    inputs = [(w, n) for d, w, n in ports if d == "input"]
    outputs = [(w, n) for d, w, n in ports if d == "output"]
    decl = ["  logic clock;", "  logic reset;"]
    for w, n in inputs:
        if n in ("clock", "reset"):
            continue
        decl.append(f"  logic {w + ' ' if w else ''}{n};")
    for w, n in outputs:
        decl.append(f"  wire {w + ' ' if w else ''}g_{n};")
        decl.append(f"  wire {w + ' ' if w else ''}i_{n};")
    con_g, con_i = [], []
    for d, w, n in ports:
        if d == "input" or n in ("clock", "reset"):
            con_g.append(f".{n}({n})")
            con_i.append(f".{n}({n})")
        else:
            con_g.append(f".{n}(g_{n})")
            con_i.append(f".{n}(i_{n})")
    drive = []
    for w, n in inputs:
        if n in ("clock", "reset"):
            continue
        drive.append(f"    {n} = $urandom;")
    compare = []
    for w, n in outputs:
        compare.append(
            f"""      if (!$isunknown(g_{n}) && i_{n} !== g_{n}) begin
        errors++;
        if (errors < 20) $display("MISMATCH {n}: g=%0h i=%0h cycle=%0d", g_{n}, i_{n}, cycle);
      end"""
        )
    decl_s = "\n".join(decl)
    con_g_s = ",\n    ".join(con_g)
    con_i_s = ",\n    ".join(con_i)
    drive_s = "\n".join(drive)
    compare_s = "\n".join(compare)
    return f"""`timescale 1ns/1ps
module tb;
{decl_s}
  integer cycle;
  integer errors;
  integer checks;

  L2TlbPrefetch u_g (
    {con_g_s}
  );
  L2TlbPrefetch_xs u_i (
    {con_i_s}
  );

  initial clock = 1'b0;
  always #5 clock = ~clock;

  task automatic drive_random;
  begin
{drive_s}
    // 偏置使去重窗口与 out.fire 路径都被频繁激发。
    io_in_valid   = ($urandom_range(0, 1) == 0);
    io_out_ready  = ($urandom_range(0, 3) != 0);
    io_csr_priv_virt = ($urandom_range(0, 1) == 0);
    io_csr_vsatp_mode = ($urandom_range(0, 2) == 0) ? 4'h0 : 4'h8;
    io_csr_hgatp_mode = ($urandom_range(0, 2) == 0) ? 4'h0 : 4'h8;
    // 把 in_vpn 限制在小范围，使 next_line 经常命中去重窗口。
    io_in_bits_vpn = $urandom_range(0, 255);
    io_sfence_valid    = ($urandom_range(0, 63) == 0);
    io_csr_satp_changed  = ($urandom_range(0, 255) == 0);
    io_csr_vsatp_changed = ($urandom_range(0, 255) == 0);
    io_csr_hgatp_changed = ($urandom_range(0, 255) == 0);
  end
  endtask

  initial begin
    errors = 0;
    checks = 0;
    reset = 1'b1;
    drive_random();
    repeat (5) @(posedge clock);
    reset = 1'b0;
    for (cycle = 0; cycle < 200000; cycle++) begin
      @(negedge clock);
      drive_random();
      @(posedge clock);
      #1;
      checks++;
{compare_s}
    end
    $display("L2TlbPrefetch_UT checks=%0d errors=%0d", checks, errors);
    if (errors == 0 && checks > 1000) $display("TEST PASSED"); else $fatal(1, "L2TlbPrefetch mismatch");
    $finish;
  end
endmodule
"""


def main():
    ports = parse_ports()
    UT.mkdir(parents=True, exist_ok=True)
    (RTL / "L2TlbPrefetch_wrapper.sv").write_text(adapter_body("L2TlbPrefetch", ports))
    (UT / "variants_xs.sv").write_text(adapter_body("L2TlbPrefetch_xs", ports))
    (UT / "tb.sv").write_text(gen_tb(ports))
    (UT / "Makefile").write_text(
        """MODULE = L2TlbPrefetch
RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl
RTL_SRCS = $(RTL_DIR)/memblock/l2tlbprefetch_pkg.sv $(RTL_DIR)/memblock/L2TlbPrefetch.sv
WRAPPER_SRCS = $(RTL_DIR)/memblock/L2TlbPrefetch_wrapper.sv
GOLDEN_SRCS = $(GOLDEN_RTL)/L2TlbPrefetch.sv
TB_SRCS = variants_xs.sv tb.sv
FM_VARIANTS = L2TlbPrefetch
FM_MERGE_DUP = false
include ../../../scripts/ut_common.mk

simv: $(RTL_SRCS) $(TB_SRCS) $(GOLDEN_SRCS)
\t$(VCS) +define+SYNTHESIS $(RTL_SRCS) $(GOLDEN_RTL)/L2TlbPrefetch.sv $(TB_SRCS) -top tb -o simv
"""
    )
    print(f"generated L2TlbPrefetch adapter and UT with {len(ports)} ports")


if __name__ == "__main__":
    main()
