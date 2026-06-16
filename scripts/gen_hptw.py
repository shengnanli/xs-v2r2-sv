#!/usr/bin/env python3
"""Generate HPTW wrapper/variant/UT from the golden flat port list.

The readable implementation keeps struct/array ports in xs_HPTW_core.  This
script only generates the mechanical adapter layer that keeps the firtool flat
port spelling for UT/FM.
"""

import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
GOLDEN = ROOT / "golden/chisel-rtl/HPTW.sv"
RTL = ROOT / "rtl/memblock"
UT = ROOT / "verif/ut/HPTW"


def parse_ports():
    text = GOLDEN.read_text()
    start = text.index("module HPTW(")
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


def resp_out_assign():
    p = "io_resp_bits_resp"
    lines = [
        f"  assign {p}_entry_tag = resp_bus.tag;",
        f"  assign {p}_entry_vmid = resp_bus.vmid;",
        f"  assign {p}_entry_n = resp_bus.n;",
        f"  assign {p}_entry_pbmt = resp_bus.pbmt;",
        f"  assign {p}_entry_ppn = resp_bus.ppn;",
    ]
    for field in ["d", "a", "g", "u", "x", "w", "r"]:
        lines.append(f"  assign {p}_entry_perm_{field} = resp_bus.perm.{field};")
    lines += [
        f"  assign {p}_entry_level = resp_bus.level;",
        f"  assign {p}_gpf = resp_bus.gpf;",
        f"  assign {p}_gaf = resp_bus.gaf;",
    ]
    return "\n".join(lines)


def adapter_body(module_name: str, ports):
    core_ports = [
        ".clock(clock)",
        ".reset(reset)",
        ".sfence_valid(io_sfence_valid)",
        ".csr(csr_bus)",
        ".req_ready(io_req_ready)",
        ".req_valid(io_req_valid)",
        ".req(req_bus)",
        ".resp_ready(io_resp_ready)",
        ".resp_valid(io_resp_valid)",
        ".resp_source(resp_source_unused)",
        ".resp(resp_bus)",
        ".resp_id(io_resp_bits_id)",
        ".mem_req_ready(io_mem_req_ready)",
        ".mem_req_valid(io_mem_req_valid)",
        ".mem_req_addr(io_mem_req_bits_addr)",
        ".mem_req_hptw_bypassed(io_mem_req_bits_hptw_bypassed)",
        ".mem_resp_valid(io_mem_resp_valid)",
        ".mem_resp_bits(io_mem_resp_bits)",
        ".mem_mask(io_mem_mask)",
        ".refill_vpn(io_refill_req_info_vpn)",
        ".refill_source(io_refill_req_info_source)",
        ".refill_level(io_refill_level)",
        ".pmp_addr(io_pmp_req_bits_addr)",
        ".pmp_resp_ld(io_pmp_resp_ld)",
        ".pmp_resp_mmio(io_pmp_resp_mmio)",
    ]
    core_conn = ",\n    ".join(core_ports)
    # io_resp_bits_resp source 端口在 golden HPTW 没有引出（被裁剪），用内部线接住。
    return f"""// 自动生成：scripts/gen_hptw.py —— 仅机械端口适配，核心逻辑在 xs_HPTW_core
module {module_name} import xs_hptw_pkg::*; (
{decl_ports(ports)}
);

  hptw_csr_t  csr_bus;
  hptw_req_t  req_bus;
  hptw_resp_t resp_bus;
  logic [1:0] resp_source_unused;

  assign csr_bus.hgatp_mode     = io_csr_hgatp_mode;
  assign csr_bus.hgatp_vmid_raw = io_csr_hgatp_vmid;
  assign csr_bus.hgatp_ppn      = io_csr_hgatp_ppn;
  assign csr_bus.hgatp_changed  = io_csr_hgatp_changed;
  assign csr_bus.satp_changed   = io_csr_satp_changed;
  assign csr_bus.vsatp_changed  = io_csr_vsatp_changed;
  assign csr_bus.m_pbmt_enable  = io_csr_mPBMTE;

  assign req_bus.source   = io_req_bits_source;
  assign req_bus.id       = io_req_bits_id;
  assign req_bus.gvpn     = io_req_bits_gvpn;
  assign req_bus.ppn      = io_req_bits_ppn;
  assign req_bus.l3_hit   = io_req_bits_l3Hit;
  assign req_bus.l2_hit   = io_req_bits_l2Hit;
  assign req_bus.l1_hit   = io_req_bits_l1Hit;
  assign req_bus.bypassed = io_req_bits_bypassed;

  xs_HPTW_core u_core (
    {core_conn}
  );

{resp_out_assign()}

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

  HPTW u_g (
    {con_g_s}
  );
  HPTW_xs u_i (
    {con_i_s}
  );

  initial clock = 1'b0;
  always #5 clock = ~clock;

  task automatic drive_random;
  begin
{drive_s}
    // 约束握手环境，避免无界 backpressure 干扰随机 UT 收敛。
    io_resp_ready    = ($urandom_range(0, 7) != 0);
    io_mem_req_ready = ($urandom_range(0, 3) != 0);
    io_mem_mask      = ($urandom_range(0, 31) == 0);
    // hgatp 至少要是 Sv39x4/Sv48x4 才会真正走表（Bare 不会发请求）。
    io_csr_hgatp_mode = ($urandom_range(0, 3) == 0) ? 4'h0 : (($urandom_range(0, 1) == 0) ? 4'h8 : 4'h9);
    io_req_valid       = ($urandom_range(0, 3) == 0);
    io_req_bits_l1Hit  = ($urandom_range(0, 7) == 0);
    io_req_bits_l2Hit  = ($urandom_range(0, 7) == 0);
    io_req_bits_l3Hit  = ($urandom_range(0, 7) == 0);
    io_req_bits_bypassed = ($urandom_range(0, 1) == 0);
    io_mem_resp_valid  = ($urandom_range(0, 3) == 0);
    io_sfence_valid    = ($urandom_range(0, 127) == 0);
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
    $display("HPTW_UT checks=%0d errors=%0d", checks, errors);
    if (errors == 0 && checks > 1000) $display("TEST PASSED"); else $fatal(1, "HPTW mismatch");
    $finish;
  end
endmodule
"""


def main():
    ports = parse_ports()
    UT.mkdir(parents=True, exist_ok=True)
    (RTL / "HPTW_wrapper.sv").write_text(adapter_body("HPTW", ports))
    (UT / "variants_xs.sv").write_text(adapter_body("HPTW_xs", ports))
    (UT / "tb.sv").write_text(gen_tb(ports))
    (UT / "Makefile").write_text(
        """MODULE = HPTW
RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl
RTL_SRCS = $(RTL_DIR)/memblock/hptw_pkg.sv $(RTL_DIR)/memblock/HPTW.sv
WRAPPER_SRCS = $(RTL_DIR)/memblock/HPTW_wrapper.sv
GOLDEN_SRCS = $(GOLDEN_RTL)/HPTW.sv
TB_SRCS = variants_xs.sv tb.sv
FM_VARIANTS = HPTW
FM_MERGE_DUP = false
include ../../../scripts/ut_common.mk

simv: $(RTL_SRCS) $(TB_SRCS) $(GOLDEN_SRCS)
\t$(VCS) +define+SYNTHESIS $(RTL_SRCS) $(GOLDEN_RTL)/HPTW.sv $(TB_SRCS) -top tb -o simv
"""
    )
    print(f"generated HPTW adapter and UT with {len(ports)} ports")


if __name__ == "__main__":
    main()
