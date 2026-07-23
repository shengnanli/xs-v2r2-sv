#!/usr/bin/env python3
"""Generate L2TlbMissQueue wrapper/variant/UT from the golden flat port list.

golden 的队列子模块 Queue40_L2TlbMQBundle + ram_40x47 作为黑盒：UT 双例化时
两侧顶层分别是 golden L2TlbMissQueue（内含 Queue40）和手写 L2TlbMissQueue_xs
（内含 xs_L2TlbMissQueue_core）。FM 则把手写核心整体与 golden 顶层做等价。
"""

import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
GOLDEN = ROOT / "golden/chisel-rtl/L2TlbMissQueue.sv"
RTL = ROOT / "rtl/memblock"
UT = ROOT / "verif/ut/L2TlbMissQueue"


def parse_ports():
    text = GOLDEN.read_text()
    start = text.index("module L2TlbMissQueue(")
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
        ".flush(io_sfence_valid | io_csr_satp_changed | io_csr_vsatp_changed | io_csr_hgatp_changed)",
        ".enq_ready(io_in_ready)",
        ".enq_valid(io_in_valid)",
        ".enq_bits(enq_bits_bus)",
        ".deq_ready(io_out_ready)",
        ".deq_valid(io_out_valid)",
        ".deq_bits(deq_bits_bus)",
    ]
    core_conn = ",\n    ".join(core_ports)
    return f"""// 自动生成：scripts/gen_l2tlbmissqueue.py —— 仅机械端口适配，核心逻辑在 xs_L2TlbMissQueue_core
module {module_name} import xs_l2tlbmissqueue_pkg::*; (
{decl_ports(ports)}
);

  l2tlb_mq_bundle_t enq_bits_bus;
  l2tlb_mq_bundle_t deq_bits_bus;

  // 入队 payload：isHptwReq / hptwId 入队恒为 0（与 golden 一致）。
  assign enq_bits_bus.vpn         = io_in_bits_req_info_vpn;
  assign enq_bits_bus.s2xlate     = io_in_bits_req_info_s2xlate;
  assign enq_bits_bus.source      = io_in_bits_req_info_source;
  assign enq_bits_bus.is_hptw_req = 1'b0;
  assign enq_bits_bus.is_llptw    = io_in_bits_isLLptw;
  assign enq_bits_bus.hptw_id     = 3'h0;

  xs_L2TlbMissQueue_core u_core (
    {core_conn}
  );

  assign io_out_bits_req_info_vpn     = deq_bits_bus.vpn;
  assign io_out_bits_req_info_s2xlate = deq_bits_bus.s2xlate;
  assign io_out_bits_req_info_source  = deq_bits_bus.source;
  assign io_out_bits_isHptwReq        = deq_bits_bus.is_hptw_req;
  assign io_out_bits_isLLptw          = deq_bits_bus.is_llptw;
  assign io_out_bits_hptwId           = deq_bits_bus.hptw_id;

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
        # deq payload 仅在非空（io_out_valid）时有效：golden 空队列时组合读为 X。
        # io_isunknown 跳过 X，但为稳妥仅在 valid 时比对 payload。
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

  L2TlbMissQueue u_g (
    {con_g_s}
  );
  L2TlbMissQueue_xs u_i (
    {con_i_s}
  );

  initial clock = 1'b0;
  always #5 clock = ~clock;

  task automatic drive_random;
  begin
{drive_s}
    // 偏置入/出 valid，使队列在满/空/中间各状态都被覆盖。
    io_in_valid  = ($urandom_range(0, 1) == 0);
    io_out_ready = ($urandom_range(0, 1) == 0);
    io_sfence_valid      = ($urandom_range(0, 255) == 0);
    io_csr_satp_changed  = ($urandom_range(0, 511) == 0);
    io_csr_vsatp_changed = ($urandom_range(0, 511) == 0);
    io_csr_hgatp_changed = ($urandom_range(0, 511) == 0);
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
      // 内部层次探针：golden Queue40 的环形指针/满标志 vs 手写核心。
      // 用于在 FM 因 golden ram_40x47 的 OOB-index lint 无法 link 时，
      // 直接证明控制状态机逐拍等价。
      if (u_g.io_out_q.enq_ptr_value !== u_i.u_core.enq_ptr) begin
        probe_errors++;
        if (probe_errors < 20) $display("PROBE enq_ptr g=%0h i=%0h cycle=%0d",
          u_g.io_out_q.enq_ptr_value, u_i.u_core.enq_ptr, cycle);
      end
      if (u_g.io_out_q.deq_ptr_value !== u_i.u_core.deq_ptr) begin
        probe_errors++;
        if (probe_errors < 20) $display("PROBE deq_ptr g=%0h i=%0h cycle=%0d",
          u_g.io_out_q.deq_ptr_value, u_i.u_core.deq_ptr, cycle);
      end
      if (u_g.io_out_q.maybe_full !== u_i.u_core.maybe_full) begin
        probe_errors++;
        if (probe_errors < 20) $display("PROBE maybe_full g=%0h i=%0h cycle=%0d",
          u_g.io_out_q.maybe_full, u_i.u_core.maybe_full, cycle);
      end
    end
    $display("L2TlbMissQueue_UT checks=%0d errors=%0d probe_errors=%0d", checks, errors, probe_errors);
    if (errors == 0 && probe_errors == 0 && checks > 1000) $display("TEST PASSED"); else $fatal(1, "L2TlbMissQueue mismatch");
    $finish;
  end
endmodule
"""


def main():
    ports = parse_ports()
    UT.mkdir(parents=True, exist_ok=True)
    (RTL / "L2TlbMissQueue_wrapper.sv").write_text(adapter_body("L2TlbMissQueue", ports))
    (UT / "variants_xs.sv").write_text(adapter_body("L2TlbMissQueue_xs", ports))
    (UT / "tb.sv").write_text(gen_tb(ports))
    (UT / "Makefile").write_text(
        """MODULE = L2TlbMissQueue
RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl
RTL_SRCS = $(RTL_DIR)/memblock/l2tlbmissqueue_pkg.sv $(RTL_DIR)/memblock/L2TlbMissQueue.sv
WRAPPER_SRCS = $(RTL_DIR)/memblock/L2TlbMissQueue_wrapper.sv
GOLDEN_SRCS = $(GOLDEN_RTL)/L2TlbMissQueue.sv $(GOLDEN_RTL)/Queue40_L2TlbMQBundle.sv $(GOLDEN_RTL)/ram_40x47.sv
TB_SRCS = variants_xs.sv tb.sv
FM_VARIANTS = L2TlbMissQueue
# ram_40x47 是 golden 的 40深×47位 厂商 RAM 叶子：其组合读 Memory[R0_addr]（6 位地址
# 寻址 40 深数组，指针可证 ≤39 但 FM 静态无法证明）会抛 FMR_ELAB-147 并在 link 阶段
# 升级为 unsuppressed error，令 golden set_top 失败、整个 SEC 中止。手写核 L2TlbMissQueue.sv
# 现改为实例化同名同端口的 ram_40x47 作存储叶子，故双侧都**不**把 ram_40x47.sv 交给 FM，
# 经 hdlin_unresolved_modules=black_box 成为对称匹配黑盒（RAM 阵列不 elaborate → 无
# ELAB-147；厂商 RAM 叶子方法学，同 array_ext），环形指针/满空/flush 控制逻辑照常比对。
# ram_40x47.sv 仍在 GOLDEN_SRCS 中供 UT 仿真按模块名解析（golden 与 impl 两处例化共用）。
FM_REF_DEPS_L2TlbMissQueue = Queue40_L2TlbMQBundle.sv
FM_MERGE_DUP = false
include ../../../scripts/ut_common.mk

simv: $(RTL_SRCS) $(TB_SRCS) $(GOLDEN_SRCS)
\t$(VCS) +define+SYNTHESIS $(RTL_SRCS) $(GOLDEN_SRCS) $(TB_SRCS) -top tb -o simv
"""
    )
    print(f"generated L2TlbMissQueue adapter and UT with {len(ports)} ports")


if __name__ == "__main__":
    main()
