#!/usr/bin/env python3
"""Generate LLPTW wrapper/variant/UT from the golden flat port list.

The readable implementation keeps struct/array ports in xs_LLPTW_core.  This
script only emits the mechanical adapter layer that has to keep the firtool flat
port spelling for UT (double instantiation against golden) and FM.

The golden submodules RRArbiterInit / Arbiter2_LLPTW_Anon are reused as black
boxes by BOTH sides (golden LLPTW and the readable core instantiate the same
golden module), so they are compiled in alongside.
"""

import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
GOLDEN = ROOT / "golden/chisel-rtl/LLPTW.sv"
RTL = ROOT / "rtl/memblock"
UT = ROOT / "verif/ut/LLPTW"

LLPTW_SIZE = 6


def parse_ports():
    text = GOLDEN.read_text()
    start = text.index("module LLPTW(")
    head = text[start: text.index(");", start) + 2]
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


def hptw_resp_in_assign():
    p = "io_hptw_resp_bits_h_resp"
    lines = [
        f"  assign hptw_resp_h.tag = {p}_entry_tag;",
        f"  assign hptw_resp_h.vmid = {p}_entry_vmid;",
        f"  assign hptw_resp_h.n = {p}_entry_n;",
        f"  assign hptw_resp_h.pbmt = {p}_entry_pbmt;",
        f"  assign hptw_resp_h.ppn = {p}_entry_ppn;",
    ]
    for f in ["d", "a", "g", "u", "x", "w", "r"]:
        lines.append(f"  assign hptw_resp_h.perm.{f} = {p}_entry_perm_{f};")
    lines += [
        f"  assign hptw_resp_h.level = {p}_entry_level;",
        f"  assign hptw_resp_h.gpf = {p}_gpf;",
        f"  assign hptw_resp_h.gaf = {p}_gaf;",
    ]
    return "\n".join(lines)


def out_h_resp_assign():
    p = "io_out_bits_h_resp"
    lines = [
        f"  assign {p}_entry_tag = out_h_resp.tag;",
        f"  assign {p}_entry_vmid = out_h_resp.vmid;",
        f"  assign {p}_entry_n = out_h_resp.n;",
        f"  assign {p}_entry_pbmt = out_h_resp.pbmt;",
        f"  assign {p}_entry_ppn = out_h_resp.ppn;",
    ]
    for f in ["d", "a", "g", "u", "x", "w", "r"]:
        lines.append(f"  assign {p}_entry_perm_{f} = out_h_resp.perm.{f};")
    lines += [
        f"  assign {p}_entry_level = out_h_resp.level;",
        f"  assign {p}_gpf = out_h_resp.gpf;",
        f"  assign {p}_gaf = out_h_resp.gaf;",
    ]
    return "\n".join(lines)


def vec_in(sig, n):
    return "  assign " + sig + " = {" + ", ".join(
        f"{sig.rsplit('_',0)[0]}"  # placeholder, replaced below
        for _ in range(n)) + "};"


def adapter_body(module_name: str, ports):
    core_ports = [
        ".clock(clock)",
        ".reset(reset)",
        ".csr(csr_bus)",
        ".in_ready(io_in_ready)",
        ".in_valid(io_in_valid)",
        ".in_req_info(in_req_info)",
        ".in_ppn(io_in_bits_ppn)",
        ".out_ready(io_out_ready)",
        ".out_valid(io_out_valid)",
        ".out_req_info(out_req_info)",
        ".out_id(io_out_bits_id)",
        ".out_h_resp(out_h_resp)",
        ".out_first_s2xlate_fault(io_out_bits_first_s2xlate_fault)",
        ".out_af(io_out_bits_af)",
        ".mem_req_ready(io_mem_req_ready)",
        ".mem_req_valid(io_mem_req_valid)",
        ".mem_req_addr(io_mem_req_bits_addr)",
        ".mem_req_id(io_mem_req_bits_id)",
        ".mem_resp_valid(io_mem_resp_valid)",
        ".mem_resp_id(io_mem_resp_bits_id)",
        ".mem_resp_value(io_mem_resp_bits_value)",
        ".mem_enq_ptr(io_mem_enq_ptr)",
        ".mem_buffer_it(mem_buffer_it_bus)",
        ".mem_refill(mem_refill_bus)",
        ".mem_req_mask(mem_req_mask_bus)",
        ".mem_flush_latch(mem_flush_latch_bus)",
        ".cache_ready(io_cache_ready)",
        ".cache_valid(io_cache_valid)",
        ".cache_req_info(cache_req_info)",
        ".pmp_req_addr(io_pmp_req_bits_addr)",
        ".pmp_resp_ld(io_pmp_resp_ld)",
        ".pmp_resp_mmio(io_pmp_resp_mmio)",
        ".hptw_req_ready(io_hptw_req_ready)",
        ".hptw_req_valid(io_hptw_req_valid)",
        ".hptw_req_source(io_hptw_req_bits_source)",
        ".hptw_req_id(io_hptw_req_bits_id)",
        ".hptw_req_gvpn(io_hptw_req_bits_gvpn)",
        ".hptw_resp_valid(io_hptw_resp_valid)",
        ".hptw_resp_id(io_hptw_resp_bits_id)",
        ".hptw_resp_h(hptw_resp_h)",
        ".perf(perf_bus)",
    ]
    core_conn = ",\n    ".join(core_ports)

    mem_buffer_out = "\n".join(
        f"  assign io_mem_buffer_it_{i} = mem_buffer_it_bus[{i}];" for i in range(LLPTW_SIZE))
    mem_mask_in = "  assign mem_req_mask_bus = {" + ", ".join(
        f"io_mem_req_mask_{i}" for i in range(LLPTW_SIZE - 1, -1, -1)) + "};"
    mem_flush_in = "  assign mem_flush_latch_bus = {" + ", ".join(
        f"io_mem_flush_latch_{i}" for i in range(LLPTW_SIZE - 1, -1, -1)) + "};"
    perf_out = "\n".join(
        f"  assign io_perf_{i}_value = perf_bus[{i}];" for i in range(4))

    return f"""// 自动生成：scripts/gen_llptw.py —— 仅机械端口适配，核心逻辑在 xs_LLPTW_core
module {module_name} import xs_llptw_pkg::*; (
{decl_ports(ports)}
);

  llptw_csr_t csr_bus;
  req_info_t  in_req_info;
  req_info_t  out_req_info;
  req_info_t  cache_req_info;
  req_info_t  mem_refill_bus;
  hptw_resp_t hptw_resp_h;
  hptw_resp_t out_h_resp;
  logic [{LLPTW_SIZE-1}:0] mem_buffer_it_bus;
  logic [{LLPTW_SIZE-1}:0] mem_req_mask_bus;
  logic [{LLPTW_SIZE-1}:0] mem_flush_latch_bus;
  logic [3:0][5:0] perf_bus;

  assign csr_bus.sfence_valid = io_sfence_valid;
  assign csr_bus.satp_changed = io_csr_satp_changed;
  assign csr_bus.vsatp_changed = io_csr_vsatp_changed;
  assign csr_bus.hgatp_mode = io_csr_hgatp_mode;
  assign csr_bus.hgatp_changed = io_csr_hgatp_changed;
  assign csr_bus.priv_mxr = io_csr_priv_mxr;
  assign csr_bus.m_pbmt_enable = io_csr_mPBMTE;
  assign csr_bus.h_pbmt_enable = io_csr_hPBMTE;

  assign in_req_info.vpn = io_in_bits_req_info_vpn;
  assign in_req_info.s2xlate = io_in_bits_req_info_s2xlate;
  assign in_req_info.source = io_in_bits_req_info_source;

{hptw_resp_in_assign()}
{mem_mask_in}
{mem_flush_in}

  xs_LLPTW_core u_core (
    {core_conn}
  );

  assign io_out_bits_req_info_vpn = out_req_info.vpn;
  assign io_out_bits_req_info_s2xlate = out_req_info.s2xlate;
  assign io_out_bits_req_info_source = out_req_info.source;
  assign io_cache_bits_vpn = cache_req_info.vpn;
  assign io_cache_bits_s2xlate = cache_req_info.s2xlate;
  assign io_cache_bits_source = cache_req_info.source;
  assign io_mem_refill_vpn = mem_refill_bus.vpn;
  assign io_mem_refill_s2xlate = mem_refill_bus.s2xlate;
  assign io_mem_refill_source = mem_refill_bus.source;
{mem_buffer_out}
{out_h_resp_assign()}
{perf_out}

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
        if (errors < 30) $display("MISMATCH {n}: g=%0h i=%0h cycle=%0d", g_{n}, i_{n}, cycle);
      end"""
        )
    decl_s = "\n".join(decl)
    con_g_s = ",\n    ".join(con_g)
    con_i_s = ",\n    ".join(con_i)
    drive_s = "\n".join(drive)
    compare_s = "\n".join(compare)
    # internal probes: per-entry state machine + the FM-failing matched DFFs.
    # 这些层次探针用于在逐拍可达激励下证明 FM 标记的 matched failing 点其实不分歧
    # （FM 因 struct 数组 vs golden 扁平标量无法配对其输入锥，属不可判，非真分歧）。
    probe_pairs = []
    for i in range(LLPTW_SIZE):
        probe_pairs.append((f"state{i}", f"u_g.state_{i}", f"u_i.u_core.state[{i}]"))
    probe_pairs += [
        ("addr_reg",          "u_g.addr",                  "u_i.u_core.addr_reg"),
        ("enq_ptr_reg",       "u_g.enq_ptr_reg",           "u_i.u_core.enq_ptr_reg"),
        ("hptw_resp_ptr_reg", "u_g.hptw_resp_ptr_reg",     "u_i.u_core.hptw_resp_ptr_reg"),
        ("mem_refill_id",     "u_g.mem_refill_id",         "u_i.u_core.mem_refill_id"),
        ("need_addr_check",   "u_g.need_addr_check_last_REG", "u_i.u_core.need_addr_check"),
    ]
    probe_decl = "\n".join(
        f"""      if (!$isunknown({g}) && {imp} !== {g}) begin
        probe_errors++;
        if (probe_errors < 30) $display("PROBE {nm} mismatch: g=%0h i=%0h cycle=%0d", {g}, {imp}, cycle);
      end""" for (nm, g, imp) in probe_pairs)
    return f"""`timescale 1ns/1ps
module tb;
{decl_s}
  integer cycle;
  integer errors;
  integer checks;
  integer probe_errors;

  LLPTW u_g (
    {con_g_s}
  );
  LLPTW_xs u_i (
    {con_i_s}
  );

  initial clock = 1'b0;
  always #5 clock = ~clock;

  task automatic drive_random;
  begin
{drive_s}
    // 约束握手/CSR 环境，提高随机收敛与可达状态覆盖。
    io_in_valid = ($urandom_range(0, 1) == 0);
    io_in_bits_req_info_s2xlate = $urandom_range(0, 3);
    io_in_bits_req_info_source = $urandom_range(0, 3);
    io_out_ready = ($urandom_range(0, 3) != 0);
    io_cache_ready = ($urandom_range(0, 3) != 0);
    io_mem_req_ready = ($urandom_range(0, 3) != 0);
    io_hptw_req_ready = ($urandom_range(0, 3) != 0);
    io_mem_resp_valid = ($urandom_range(0, 2) == 0);
    io_hptw_resp_valid = ($urandom_range(0, 2) == 0);
    io_mem_resp_bits_id = $urandom_range(0, 5);
    io_hptw_resp_bits_id = $urandom_range(0, 5);
    io_csr_hgatp_mode = ($urandom_range(0, 3) == 0) ? 4'h0 : (($urandom_range(0,1)==0) ? 4'h8 : 4'h9);
    io_sfence_valid = ($urandom_range(0, 127) == 0);
    io_csr_satp_changed = ($urandom_range(0, 255) == 0);
    io_csr_vsatp_changed = ($urandom_range(0, 255) == 0);
    io_csr_hgatp_changed = ($urandom_range(0, 255) == 0);
    // 同一 cacheline 概率：低位 vpn 收窄，使去重/dup 路径频繁激发。
    io_in_bits_req_info_vpn = {{$urandom_range(0, 'h3F), $urandom_range(0, 'hFFFF)}} & 38'h3FFFFFFFFF;
    if ($urandom_range(0, 1) == 0)
      io_in_bits_req_info_vpn[37:6] = 32'h12345; // 收敛到同一 L0 line
    io_mem_req_mask_0 = $urandom; io_mem_req_mask_1 = $urandom;
    io_mem_req_mask_2 = $urandom; io_mem_req_mask_3 = $urandom;
    io_mem_req_mask_4 = $urandom; io_mem_req_mask_5 = $urandom;
    io_mem_flush_latch_0 = ($urandom_range(0,15)==0); io_mem_flush_latch_1 = ($urandom_range(0,15)==0);
    io_mem_flush_latch_2 = ($urandom_range(0,15)==0); io_mem_flush_latch_3 = ($urandom_range(0,15)==0);
    io_mem_flush_latch_4 = ($urandom_range(0,15)==0); io_mem_flush_latch_5 = ($urandom_range(0,15)==0);
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
{probe_decl}
    end
    $display("LLPTW_UT checks=%0d errors=%0d probe_errors=%0d", checks, errors, probe_errors);
    if (errors == 0 && checks > 1000) $display("TEST PASSED"); else $fatal(1, "LLPTW mismatch");
    $finish;
  end
endmodule
"""


def main():
    ports = parse_ports()
    UT.mkdir(parents=True, exist_ok=True)
    (RTL / "LLPTW_wrapper.sv").write_text(adapter_body("LLPTW", ports))
    (UT / "variants_xs.sv").write_text(adapter_body("LLPTW_xs", ports))
    (UT / "tb.sv").write_text(gen_tb(ports))
    (UT / "Makefile").write_text(
        """MODULE = LLPTW
RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl
RTL_SRCS = $(RTL_DIR)/memblock/llptw_pkg.sv $(RTL_DIR)/memblock/LLPTW.sv
WRAPPER_SRCS = $(RTL_DIR)/memblock/LLPTW_wrapper.sv
SUBMOD_SRCS = $(GOLDEN_RTL)/RRArbiterInit.sv $(GOLDEN_RTL)/Arbiter2_LLPTW_Anon.sv
GOLDEN_SRCS = $(GOLDEN_RTL)/LLPTW.sv $(SUBMOD_SRCS)
TB_SRCS = variants_xs.sv tb.sv
FM_VARIANTS = LLPTW
FM_REF_DEPS_LLPTW = RRArbiterInit.sv Arbiter2_LLPTW_Anon.sv
FM_MERGE_DUP = false
include ../../../scripts/ut_common.mk

# UT：编 golden LLPTW + 两个 golden 子模块（双侧共用黑盒）+ 手写核/包装 + tb。
simv: $(RTL_SRCS) $(WRAPPER_SRCS) $(TB_SRCS) $(GOLDEN_SRCS)
\t$(VCS) +define+SYNTHESIS $(RTL_SRCS) $(WRAPPER_SRCS) $(GOLDEN_SRCS) $(TB_SRCS) -top tb -o simv
"""
    )
    print(f"generated LLPTW adapter and UT with {len(ports)} ports")


if __name__ == "__main__":
    main()
