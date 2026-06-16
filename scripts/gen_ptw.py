#!/usr/bin/env python3
"""Generate PTW wrapper/variant/UT from the golden flat port list.

The readable implementation keeps struct/array ports in xs_PTW_core.  This script
only generates the mechanical adapter layer that has to keep the firtool flat
port spelling for UT/FM.
"""

import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
GOLDEN = ROOT / "golden/chisel-rtl/PTW.sv"
RTL = ROOT / "rtl/memblock"
UT = ROOT / "verif/ut/PTW"


def parse_ports():
    text = GOLDEN.read_text()
    head = text[text.index("module PTW(") : text.index(");", text.index("module PTW(")) + 2]
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


def stage1_entry_assign(prefix: str):
    lines = []
    for i in range(8):
        p = f"io_req_bits_stage1_entry_{i}"
        q = f"{prefix}.entry[{i}]"
        lines += [
            f"  assign {q}.tag = {p}_tag;",
            f"  assign {q}.asid = {p}_asid;",
            f"  assign {q}.vmid = {p}_vmid;",
            f"  assign {q}.n = {p}_n;",
            f"  assign {q}.pbmt = {p}_pbmt;",
            f"  assign {q}.perm.d = {p}_perm_d;",
            f"  assign {q}.perm.a = {p}_perm_a;",
            f"  assign {q}.perm.g = {p}_perm_g;",
            f"  assign {q}.perm.u = {p}_perm_u;",
            f"  assign {q}.perm.x = {p}_perm_x;",
            f"  assign {q}.perm.w = {p}_perm_w;",
            f"  assign {q}.perm.r = {p}_perm_r;",
            f"  assign {q}.level = {p}_level;",
            f"  assign {q}.v = {p}_v;",
            f"  assign {q}.ppn = {p}_ppn;",
            f"  assign {q}.ppn_low = {p}_ppn_low;",
            f"  assign {q}.pf = {p}_pf;",
            f"  assign {q}.af = 1'b0;",
        ]
    for i in range(8):
        lines.append(f"  assign {prefix}.pteidx[{i}] = io_req_bits_stage1_pteidx_{i};")
    lines.append(f"  assign {prefix}.not_super = io_req_bits_stage1_not_super;")
    return "\n".join(lines)


def resp_entry_assign():
    lines = []
    for i in range(8):
        p = f"io_resp_bits_resp_entry_{i}"
        q = f"resp_merge.entry[{i}]"
        for field in ["tag", "asid", "vmid", "n", "pbmt"]:
            lines.append(f"  assign {p}_{field} = {q}.{field};")
        for field in ["d", "a", "g", "u", "x", "w", "r"]:
            lines.append(f"  assign {p}_perm_{field} = {q}.perm.{field};")
        for field in ["level", "v", "ppn", "ppn_low", "af", "pf"]:
            lines.append(f"  assign {p}_{field} = {q}.{field};")
    for i in range(8):
        lines.append(f"  assign io_resp_bits_resp_pteidx_{i} = resp_merge.pteidx[{i}];")
    lines.append("  assign io_resp_bits_resp_not_super = resp_merge.not_super;")
    return "\n".join(lines)


def hptw_in_assign():
    p = "io_hptw_resp_bits_h_resp"
    lines = [
        f"  assign hptw_resp_in.tag = {p}_entry_tag;",
        f"  assign hptw_resp_in.vmid = {p}_entry_vmid;",
        f"  assign hptw_resp_in.n = {p}_entry_n;",
        f"  assign hptw_resp_in.pbmt = {p}_entry_pbmt;",
        f"  assign hptw_resp_in.ppn = {p}_entry_ppn;",
    ]
    for field in ["d", "a", "g", "u", "x", "w", "r"]:
        lines.append(f"  assign hptw_resp_in.perm.{field} = {p}_entry_perm_{field};")
    lines += [
        f"  assign hptw_resp_in.level = {p}_entry_level;",
        f"  assign hptw_resp_in.gpf = {p}_gpf;",
        f"  assign hptw_resp_in.gaf = {p}_gaf;",
    ]
    return "\n".join(lines)


def hptw_out_assign():
    p = "io_resp_bits_h_resp"
    lines = [
        f"  assign {p}_entry_tag = resp_h.tag;",
        f"  assign {p}_entry_vmid = resp_h.vmid;",
        f"  assign {p}_entry_n = resp_h.n;",
        f"  assign {p}_entry_pbmt = resp_h.pbmt;",
        f"  assign {p}_entry_ppn = resp_h.ppn;",
    ]
    for field in ["d", "a", "g", "u", "x", "w", "r"]:
        lines.append(f"  assign {p}_entry_perm_{field} = resp_h.perm.{field};")
    lines += [
        f"  assign {p}_entry_level = resp_h.level;",
        f"  assign {p}_gpf = resp_h.gpf;",
        f"  assign {p}_gaf = resp_h.gaf;",
    ]
    return "\n".join(lines)


def adapter_body(module_name: str, ports):
    port_names = [p[2] for p in ports]
    core_ports = [
        ".clock(clock)",
        ".reset(reset)",
        ".sfence_valid(io_sfence_valid)",
        ".csr(csr_bus)",
        ".req_ready(io_req_ready)",
        ".req_valid(io_req_valid)",
        ".req_info(req_info_bus)",
        ".req_l3_hit(io_req_bits_l3Hit)",
        ".req_l2_hit(io_req_bits_l2Hit)",
        ".req_ppn(io_req_bits_ppn)",
        ".req_stage1_hit(io_req_bits_stage1Hit)",
        ".req_stage1(stage1_bus)",
        ".resp_ready(io_resp_ready)",
        ".resp_valid(io_resp_valid)",
        ".resp_source(io_resp_bits_source)",
        ".resp_s2xlate(io_resp_bits_s2xlate)",
        ".resp_merge(resp_merge)",
        ".resp_h(resp_h)",
        ".llptw_ready(io_llptw_ready)",
        ".llptw_valid(io_llptw_valid)",
        ".llptw_req_info(llptw_req_info)",
        ".hptw_req_ready(io_hptw_req_ready)",
        ".hptw_req_valid(io_hptw_req_valid)",
        ".hptw_req_source(io_hptw_req_bits_source)",
        ".hptw_req_gvpn(io_hptw_req_bits_gvpn)",
        ".hptw_resp_valid(io_hptw_resp_valid)",
        ".hptw_resp_in(hptw_resp_in)",
        ".mem_req_ready(io_mem_req_ready)",
        ".mem_req_valid(io_mem_req_valid)",
        ".mem_req_addr(io_mem_req_bits_addr)",
        ".mem_resp_valid(io_mem_resp_valid)",
        ".mem_resp_bits(io_mem_resp_bits)",
        ".mem_mask(io_mem_mask)",
        ".pmp_addr(io_pmp_req_bits_addr)",
        ".pmp_resp_ld(io_pmp_resp_ld)",
        ".pmp_resp_mmio(io_pmp_resp_mmio)",
        ".refill_req_info(refill_req_info)",
        ".refill_level(io_refill_level)",
        ".perf(perf_bus)",
    ]
    perf_assign = "\n".join([f"  assign io_perf_{i}_value = perf_bus[{i}];" for i in range(7)])
    core_conn = ",\n    ".join(core_ports)
    return f"""// 自动生成：scripts/gen_ptw.py —— 仅机械端口适配，核心逻辑在 xs_PTW_core
module {module_name} import xs_ptw_pkg::*; (
{decl_ports(ports)}
);

  ptw_csr_t csr_bus;
  ptw_req_info_t req_info_bus;
  ptw_merge_resp_t stage1_bus;
  ptw_merge_resp_t resp_merge;
  hptw_resp_t hptw_resp_in;
  hptw_resp_t resp_h;
  ptw_req_info_t llptw_req_info;
  ptw_req_info_t refill_req_info;
  logic [6:0][5:0] perf_bus;

  assign csr_bus.satp_mode = io_csr_satp_mode;
  assign csr_bus.satp_asid = io_csr_satp_asid;
  assign csr_bus.satp_ppn = io_csr_satp_ppn;
  assign csr_bus.satp_changed = io_csr_satp_changed;
  assign csr_bus.vsatp_mode = io_csr_vsatp_mode;
  assign csr_bus.vsatp_asid = io_csr_vsatp_asid;
  assign csr_bus.vsatp_ppn = io_csr_vsatp_ppn;
  assign csr_bus.vsatp_changed = io_csr_vsatp_changed;
  assign csr_bus.hgatp_mode = io_csr_hgatp_mode;
  assign csr_bus.hgatp_vmid_raw = io_csr_hgatp_vmid;
  assign csr_bus.hgatp_changed = io_csr_hgatp_changed;
  assign csr_bus.priv_mxr = io_csr_priv_mxr;
  assign csr_bus.m_pbmt_enable = io_csr_mPBMTE;
  assign csr_bus.h_pbmt_enable = io_csr_hPBMTE;

  assign req_info_bus.vpn = io_req_bits_req_info_vpn;
  assign req_info_bus.s2xlate = io_req_bits_req_info_s2xlate;
  assign req_info_bus.source = io_req_bits_req_info_source;
{stage1_entry_assign("stage1_bus")}
{hptw_in_assign()}

  xs_PTW_core u_core (
    {core_conn}
  );

  assign io_llptw_bits_req_info_vpn = llptw_req_info.vpn;
  assign io_llptw_bits_req_info_s2xlate = llptw_req_info.s2xlate;
  assign io_llptw_bits_req_info_source = llptw_req_info.source;
  assign io_refill_req_info_vpn = refill_req_info.vpn;
  assign io_refill_req_info_s2xlate = refill_req_info.s2xlate;
  assign io_refill_req_info_source = refill_req_info.source;
{resp_entry_assign()}
{hptw_out_assign()}
{perf_assign}

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
        if n in ("clock", "reset"):
            con_g.append(f".{n}({n})")
            con_i.append(f".{n}({n})")
        elif d == "input":
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
  integer probe_errors;

  PTW u_g (
    {con_g_s}
  );
  PTW_xs u_i (
    {con_i_s}
  );

  initial clock = 1'b0;
  always #5 clock = ~clock;

  task automatic drive_random;
  begin
{drive_s}
    // 约束握手环境，避免无界 backpressure 干扰随机 UT 收敛。
    io_resp_ready = ($urandom_range(0, 7) != 0);
    io_llptw_ready = ($urandom_range(0, 3) != 0);
    io_hptw_req_ready = ($urandom_range(0, 3) != 0);
    io_mem_req_ready = ($urandom_range(0, 3) != 0);
    io_mem_mask = ($urandom_range(0, 31) == 0);
    io_csr_satp_mode = ($urandom_range(0, 3) == 0) ? 4'h8 : 4'h9;
    io_csr_vsatp_mode = ($urandom_range(0, 3) == 0) ? 4'h0 : (($urandom_range(0, 1) == 0) ? 4'h8 : 4'h9);
    io_csr_hgatp_mode = ($urandom_range(0, 3) == 0) ? 4'h0 : (($urandom_range(0, 1) == 0) ? 4'h8 : 4'h9);
    io_req_valid = ($urandom_range(0, 3) == 0);
    io_req_bits_req_info_s2xlate = $urandom_range(0, 3);
    io_req_bits_req_info_source = $urandom_range(0, 2);
    io_req_bits_stage1Hit = ($urandom_range(0, 31) == 0);
    io_req_bits_l2Hit = ($urandom_range(0, 7) == 0);
    io_req_bits_l3Hit = ($urandom_range(0, 7) == 0);
    io_mem_resp_valid = ($urandom_range(0, 3) == 0);
    io_hptw_resp_valid = ($urandom_range(0, 3) == 0);
    io_sfence_valid = ($urandom_range(0, 127) == 0);
    io_csr_satp_changed = ($urandom_range(0, 255) == 0);
    io_csr_vsatp_changed = ($urandom_range(0, 255) == 0);
    io_csr_hgatp_changed = ($urandom_range(0, 255) == 0);
    {{io_req_bits_stage1_pteidx_7, io_req_bits_stage1_pteidx_6,
     io_req_bits_stage1_pteidx_5, io_req_bits_stage1_pteidx_4,
     io_req_bits_stage1_pteidx_3, io_req_bits_stage1_pteidx_2,
     io_req_bits_stage1_pteidx_1, io_req_bits_stage1_pteidx_0}} = 8'b0000_0001 << io_req_bits_req_info_vpn[2:0];
  end
  endtask

  initial begin
    errors = 0;
    checks = 0;
    probe_errors = 0;
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
      if (!$isunknown(u_g.full_gvpn_reg) && u_i.u_core.full_gvpn_r !== u_g.full_gvpn_reg) begin
        probe_errors++;
        if (probe_errors < 20) $display("PROBE full_gvpn mismatch: g=%0h i=%0h cycle=%0d",
          u_g.full_gvpn_reg, u_i.u_core.full_gvpn_r, cycle);
      end
    end
    $display("PTW_UT checks=%0d errors=%0d probe_full_gvpn=%0d", checks, errors, probe_errors);
    if (errors == 0 && probe_errors == 0 && checks > 1000) $display("TEST PASSED"); else $fatal(1, "PTW mismatch");
    $finish;
  end
endmodule
"""


def main():
    ports = parse_ports()
    UT.mkdir(parents=True, exist_ok=True)
    (RTL / "PTW_wrapper.sv").write_text(adapter_body("PTW", ports))
    (UT / "variants_xs.sv").write_text(adapter_body("PTW_xs", ports))
    (UT / "tb.sv").write_text(gen_tb(ports))
    (UT / "Makefile").write_text(
        """MODULE = PTW
RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl
RTL_SRCS = $(RTL_DIR)/memblock/ptw_pkg.sv $(RTL_DIR)/memblock/PTW.sv
WRAPPER_SRCS = $(RTL_DIR)/memblock/PTW_wrapper.sv
GOLDEN_SRCS = $(GOLDEN_RTL)/PTW.sv
TB_SRCS = variants_xs.sv tb.sv
FM_VARIANTS = PTW
FM_MERGE_DUP = false
include ../../../scripts/ut_common.mk

simv: $(RTL_SRCS) $(TB_SRCS) $(GOLDEN_SRCS)
\t$(VCS) +define+SYNTHESIS $(RTL_SRCS) $(GOLDEN_RTL)/PTW.sv $(TB_SRCS) -top tb -o simv
"""
    )
    print(f"generated PTW adapter and UT with {len(ports)} ports")


if __name__ == "__main__":
    main()
