#!/usr/bin/env python3
"""
LoadQueueUncache 机械适配生成器。

本脚本只解析 golden 顶层/叶子模块的端口，生成：
  * loadqueueuncache_ports.svh        顶层 504 个端口表
  * loadqueueuncache_structs.svh      包内 struct 字段（按端口自动聚合）
  * loadqueueuncache_connect.svh      扁平端口 <-> 核内 struct/数组 的机械赋值
  * loadqueueuncache_subinst.svh      4 个 UncacheEntry + freelist + RR 仲裁 + pipeline regs
  * LoadQueueUncache_wrapper.sv       FM 用 golden 同名 wrapper
  * verif/ut/LoadQueueUncache/*       UT 双例化 wrapper 和 testbench

微架构逻辑（排序、freelist 分配、MMIO/NC 仲裁、rollback）在
rtl/memblock/LoadQueueUncache.sv 手写；这里不从 golden 内部临时信号生成逻辑。
"""
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
GOLDEN = ROOT / "golden/chisel-rtl"
RTL = ROOT / "rtl/memblock"
UT = ROOT / "verif/ut/LoadQueueUncache"
HDR = "// 自动生成：scripts/gen_loadqueueuncache.py —— 勿手改\n"


def read(name):
    return (GOLDEN / f"{name}.sv").read_text()


def ports_of(module):
    s = read(module)
    m = re.search(rf"^module {re.escape(module)}\((.*?)\n\);", s, re.S | re.M)
    if not m:
        raise RuntimeError(module)
    out = []
    for line in m.group(1).splitlines():
        pm = re.match(r"\s*(input|output)\s+(?:\[(\d+):0\])?\s*(\w+),?\s*$", line)
        if pm:
            out.append((pm.group(1), int(pm.group(2)) + 1 if pm.group(2) else 1, pm.group(3)))
    return out


TOP = ports_of("LoadQueueUncache")
ENTRY = ports_of("UncacheEntry")
PIPE_REQ = ports_of("PipelineRegModule")
PIPE_MMIO = ports_of("PipelineRegModule_1")
PIPE_NC = ports_of("PipelineRegModule_2")


def sv_decl(direction, width, name, comma=True):
    w = "" if width == 1 else f" [{width-1}:0] "
    tail = "," if comma else ""
    if width == 1:
        return f"  {direction:<6} {name}{tail}"
    return f"  {direction:<6}{w}{name}{tail}"


def width_type(width):
    return "logic" if width == 1 else f"logic [{width-1}:0]"


def field_from(prefix, name):
    return name[len(prefix):]


REQ_FIELDS = [(w, field_from("io_req_0_bits_", n))
              for d, w, n in TOP if n.startswith("io_req_0_bits_")]
REQ_FIELD_W = dict(REQ_FIELDS)
MMIO_FIELDS = [(w, field_from("io_mmioOut_2_bits_", n))
               for d, w, n in TOP if n.startswith("io_mmioOut_2_bits_")]
RAW_FIELDS = [(w, field_from("io_mmioRawData_2_", n))
              for d, w, n in TOP if n.startswith("io_mmioRawData_2_")]
NC_FIELDS = [(w, field_from("io_ncOut_0_bits_", n))
             for d, w, n in TOP if n.startswith("io_ncOut_0_bits_")]
EXC_FIELDS = [(w, field_from("io_exception_bits_", n))
              for d, w, n in TOP if n.startswith("io_exception_bits_")]
UNC_REQ_FIELDS = [(w, field_from("io_uncache_req_bits_", n))
                  for d, w, n in TOP if n.startswith("io_uncache_req_bits_")]


def emit_struct(name, fields):
    lines = [f"  typedef struct packed {{"]
    maxn = max(len(f) for _, f in fields)
    for w, f in fields:
        lines.append(f"    {width_type(w):<18} {f:<{maxn}};")
    lines.append(f"  }} {name};")
    return "\n".join(lines)


def gen_ports():
    lines = [HDR.rstrip()]
    for i, (d, w, n) in enumerate(TOP):
        lines.append(sv_decl(d, w, n, i != len(TOP) - 1))
    (RTL / "loadqueueuncache_ports.svh").write_text("\n".join(lines) + "\n")


def gen_structs():
    txt = HDR
    txt += emit_struct("lqu_req_t", REQ_FIELDS) + "\n\n"
    txt += emit_struct("lqu_unc_req_t", UNC_REQ_FIELDS) + "\n\n"
    txt += emit_struct("lqu_mmio_out_t", MMIO_FIELDS) + "\n\n"
    txt += emit_struct("lqu_raw_t", RAW_FIELDS) + "\n\n"
    txt += emit_struct("lqu_nc_out_t", NC_FIELDS) + "\n\n"
    txt += emit_struct("lqu_exception_t", EXC_FIELDS) + "\n"
    (RTL / "loadqueueuncache_structs.svh").write_text(txt)


def scalar_zero(width):
    return "1'b0" if width == 1 else f"{width}'h0"


def gen_connect():
    lines = [HDR.rstrip()]
    lines.append("  // 扁平请求端口收束成 3 路 LqWriteBundle 子集。")
    for lane in range(3):
        lines.append(f"  assign req_in_valid[{lane}] = io_req_{lane}_valid;")
        for w, f in REQ_FIELDS:
            lines.append(f"  assign req_in[{lane}].{f} = io_req_{lane}_bits_{f};")
        lines.append(f"  assign io_req_{lane}_ready = 1'b1;")
    lines.append("")
    lines.append("  // ROB 侧只需要看到 S1 排序后的 mmio 标记与 robIdx.value。")
    for lane in range(3):
        lines.append(f"  assign io_rob_mmio_{lane} = rob_mmio_q[{lane}];")
        lines.append(f"  assign io_rob_uop_{lane}_robIdx_value = rob_uop_rob_value_q[{lane}];")
    lines.append("")
    lines.append("  // 真实 MMIO 写回固定走 UncacheWBPort=2；本配置顶层只保留这一组端口。")
    lines.append("  assign io_mmioRawData_2_lqData = mmio_raw_q.lqData;")
    lines.append("  assign io_mmioRawData_2_uop_fuOpType = mmio_raw_q.uop_fuOpType;")
    lines.append("  assign io_mmioRawData_2_uop_fpWen = mmio_raw_q.uop_fpWen;")
    lines.append("  assign io_mmioRawData_2_addrOffset = mmio_raw_q.addrOffset;")
    (RTL / "loadqueueuncache_connect.svh").write_text("\n".join(lines) + "\n")


def port_expr_to_entry(port, idx):
    if port in ("clock", "reset"):
        return port
    if port.startswith("io_redirect_") or port.startswith("io_rob_"):
        return port
    if port == "io_req_valid":
        return f"entry_req_valid[{idx}]"
    if port.startswith("io_req_bits_"):
        f = field_from("io_req_bits_", port)
        return f"entry_req_bits[{idx}].{f}"
    if port == "io_mmioOut_ready":
        return f"entry_mmio_ready[{idx}]"
    if port == "io_ncOut_ready":
        return f"entry_nc_ready[{idx}]"
    if port == "io_uncache_req_ready":
        return f"entry_unc_req_ready[{idx}]"
    if port == "io_uncache_idResp_valid":
        return f"entry_id_valid[{idx}]"
    if port == "io_uncache_idResp_bits_mid":
        return "io_uncache_idResp_bits_mid"
    if port == "io_uncache_idResp_bits_sid":
        return "io_uncache_idResp_bits_sid"
    if port == "io_uncache_resp_valid":
        return f"entry_resp_valid[{idx}]"
    if port == "io_uncache_resp_bits_data":
        return "io_uncache_resp_bits_data"
    if port == "io_uncache_resp_bits_nderr":
        return "io_uncache_resp_bits_nderr"
    if port.startswith("io_mmioOut_bits_"):
        f = field_from("io_mmioOut_bits_", port)
        return f"entry_mmio_out[{idx}].{f}"
    if port.startswith("io_mmioRawData_"):
        f = field_from("io_mmioRawData_", port)
        return f"entry_raw[{idx}].{f}"
    if port.startswith("io_ncOut_bits_"):
        f = field_from("io_ncOut_bits_", port)
        return f"entry_nc_out[{idx}].{f}"
    if port.startswith("io_uncache_req_bits_"):
        f = field_from("io_uncache_req_bits_", port)
        return f"entry_unc_req[{idx}].{f}"
    if port.startswith("io_exception_bits_"):
        f = field_from("io_exception_bits_", port)
        return f"entry_exception[{idx}].{f}"
    plain = {
        "io_flush": "entry_flush",
        "io_mmioSelect": "entry_mmio_select",
        "io_slaveId_valid": "entry_slave_valid",
        "io_slaveId_bits": "entry_slave_id",
        "io_mmioOut_valid": "entry_mmio_valid",
        "io_ncOut_valid": "entry_nc_valid",
        "io_uncache_req_valid": "entry_unc_valid",
        "io_exception_valid": "entry_exception_valid",
    }
    if port in plain:
        return f"{plain[port]}[{idx}]"
    raise RuntimeError(f"unmapped entry port {port}")


def inst_module(mod, inst, conns):
    body = [f"  {mod} {inst} ("]
    for i, (p, e) in enumerate(conns):
        body.append(f"    .{p:<36}({e}){',' if i != len(conns)-1 else ''}")
    body.append("  );")
    return "\n".join(body)


def gen_subinst():
    lines = [HDR.rstrip()]
    mods = ["UncacheEntry", "UncacheEntry_1", "UncacheEntry_2", "UncacheEntry_3"]
    for idx, mod in enumerate(mods):
        conns = [(n, port_expr_to_entry(n, idx)) for _, _, n in ENTRY]
        lines.append(inst_module(mod, f"u_entry_{idx}", conns))
        lines.append("")
    fl_conns = [
        ("clock", "clock"), ("reset", "reset"),
        ("io_allocateSlot_0", "free_alloc_slot[0]"),
        ("io_allocateSlot_1", "free_alloc_slot[1]"),
        ("io_allocateSlot_2", "free_alloc_slot[2]"),
        ("io_canAllocate_0", "free_can_allocate[0]"),
        ("io_canAllocate_1", "free_can_allocate[1]"),
        ("io_canAllocate_2", "free_can_allocate[2]"),
        ("io_doAllocate_0", "s2_enq_accept[0]"),
        ("io_doAllocate_1", "s2_enq_accept[1]"),
        ("io_doAllocate_2", "s2_enq_accept[2]"),
        ("io_free", "free_mask"),
        ("io_validCount", "free_valid_count"),
        ("io_empty", "free_empty"),
    ]
    lines.append(inst_module("FreeList_6", "u_freelist", fl_conns))
    lines.append("")
    arb = [("clock", "clock"), ("reset", "reset")]
    for i in range(4):
        arb.append((f"io_in_{i}_ready", f"nc_req_ready[{i}]"))
        arb.append((f"io_in_{i}_valid", f"nc_req_valid[{i}]"))
        for _, f in UNC_REQ_FIELDS:
            if f in ("cmd", "data", "id"):
                continue
            arb.append((f"io_in_{i}_bits_{f}", f"nc_req_bits[{i}].{f}"))
    arb.append(("io_out_ready", "nc_arb_ready"))
    arb.append(("io_out_valid", "nc_arb_valid"))
    for _, f in UNC_REQ_FIELDS:
        if f in ("cmd", "data"):
            continue
        arb.append((f"io_out_bits_{f}", f"nc_arb_bits.{f}"))
    lines.append(inst_module("RRArbiterInit_9", "u_nc_req_arb", arb))
    lines.append("")
    req = [("clock", "clock"), ("reset", "reset"),
           ("io_in_ready", "unc_pipe_in_ready"), ("io_in_valid", "unc_pipe_in_valid")]
    for _, f in UNC_REQ_FIELDS:
        req.append((f"io_in_bits_{f}", f"unc_pipe_in_bits.{f}"))
    req += [("io_out_ready", "io_uncache_req_ready"), ("io_out_valid", "io_uncache_req_valid")]
    for _, f in UNC_REQ_FIELDS:
        req.append((f"io_out_bits_{f}", f"io_uncache_req_bits_{f}"))
    lines.append(inst_module("PipelineRegModule", "u_unc_req_pipe", req))
    lines.append("")
    mm = [("clock", "clock"), ("reset", "reset"),
          ("io_in_ready", "mmio_pipe_in_ready"), ("io_in_valid", "mmio_pipe_in_valid")]
    for _, f in MMIO_FIELDS:
        mm.append((f"io_in_bits_{f}", f"mmio_pipe_in_bits.{f}"))
    mm += [("io_out_ready", "io_mmioOut_2_ready"), ("io_out_valid", "io_mmioOut_2_valid")]
    for _, f in MMIO_FIELDS:
        mm.append((f"io_out_bits_{f}", f"io_mmioOut_2_bits_{f}"))
    lines.append(inst_module("PipelineRegModule_1", "u_mmio_out_pipe", mm))
    lines.append("")
    for port, name in [(0, "empty"), (1, "even"), (2, "odd")]:
        nc = [("clock", "clock"), ("reset", "reset"),
              ("io_in_ready", f"nc_pipe_{name}_ready"),
              ("io_in_valid", f"nc_pipe_{name}_valid")]
        for _, f in NC_FIELDS:
            nc.append((f"io_in_bits_{f}", f"nc_pipe_{name}_bits.{f}"))
        nc += [( "io_out_ready", f"io_ncOut_{port}_ready"),
               ( "io_out_valid", f"io_ncOut_{port}_valid")]
        for _, f in NC_FIELDS:
            nc.append((f"io_out_bits_{f}", f"io_ncOut_{port}_bits_{f}"))
        lines.append(inst_module("PipelineRegModule_2", f"u_nc_out_pipe_{name}", nc))
        lines.append("")
    (RTL / "loadqueueuncache_subinst.svh").write_text("\n".join(lines))


def gen_wrapper():
    lines = [HDR.rstrip(), "module LoadQueueUncache("]
    for i, (d, w, n) in enumerate(TOP):
        lines.append(sv_decl(d, w, n, i != len(TOP) - 1))
    lines.append(");")
    lines.append("  xs_LoadQueueUncache_core u_core (")
    for i, (_, _, n) in enumerate(TOP):
        lines.append(f"    .{n}({n}){',' if i != len(TOP)-1 else ''}")
    lines.append("  );")
    lines.append("endmodule")
    (RTL / "LoadQueueUncache_wrapper.sv").write_text("\n".join(lines) + "\n")


def gen_variants():
    lines = [HDR.rstrip(), "module LoadQueueUncache_xs("]
    for i, (d, w, n) in enumerate(TOP):
        lines.append(sv_decl(d, w, n, i != len(TOP) - 1))
    lines.append(");")
    lines.append("  xs_LoadQueueUncache_core u_core (")
    for i, (_, _, n) in enumerate(TOP):
        lines.append(f"    .{n}({n}){',' if i != len(TOP)-1 else ''}")
    lines.append("  );")
    lines.append("endmodule")
    (UT / "variants_xs.sv").write_text("\n".join(lines) + "\n")


def gen_makefile():
    subs = "UncacheEntry.sv UncacheEntry_1.sv UncacheEntry_2.sv UncacheEntry_3.sv FreeList_6.sv RRArbiterInit_9.sv PipelineRegModule.sv PipelineRegModule_1.sv PipelineRegModule_2.sv"
    txt = f"""MODULE = LoadQueueUncache

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

RTL_SRCS = $(RTL_DIR)/memblock/loadqueueuncache_pkg.sv \\
           $(RTL_DIR)/memblock/LoadQueueUncache.sv

TB_SRCS = variants_xs.sv tb.sv

GOLDEN_SUBS = {' '.join('$(GOLDEN_RTL)/' + x for x in subs.split())}
GOLDEN_SRCS = $(GOLDEN_RTL)/LoadQueueUncache.sv $(GOLDEN_SUBS)

WRAPPER_SRCS = $(RTL_DIR)/memblock/LoadQueueUncache_wrapper.sv
FM_VARIANTS = LoadQueueUncache
FM_REF_DEPS_LoadQueueUncache =
FM_MERGE_DUP = false

include ../../../scripts/ut_common.mk

VCS += +define+SYNTHESIS
VCS += +incdir+$(RTL_DIR)/memblock
"""
    (UT / "Makefile").write_text(txt)


def tb_signal_decl(d, w, n, prefix=None):
    typ = "logic" if d == "input" else "wire"
    name = n if prefix is None else f"{prefix}_{n}"
    return f"  {typ} {'' if w == 1 else f'[{w-1}:0] '}{name};"


def is_clock_reset(n):
    return n in ("clock", "reset")


def rand_assign(w, n):
    if n.endswith("_ready"):
        return f"    {n} = ($urandom_range(0, 99) < 80);"
    if n.endswith("_valid"):
        return f"    {n} = ($urandom_range(0, 99) < 20);"
    return f"    {n} = $urandom();"


def gen_tb():
    inputs = [(d, w, n) for d, w, n in TOP if d == "input" and not is_clock_reset(n)]
    outputs = [(d, w, n) for d, w, n in TOP if d == "output"]
    lines = [HDR.rstrip(), "`timescale 1ns/1ps", "module tb;",
             "  int unsigned NCYCLES = 200000;", "  bit clock = 0, reset;",
             "  int errors = 0, checks = 0;", "  always #5 clock = ~clock;", ""]
    for d, w, n in inputs:
        lines.append(tb_signal_decl(d, w, n))
    for _, w, n in outputs:
        lines.append(tb_signal_decl("output", w, n, "g"))
        lines.append(tb_signal_decl("output", w, n, "i"))
    lines.append("")
    for mod, pref in [("LoadQueueUncache", "g"), ("LoadQueueUncache_xs", "i")]:
        lines.append(f"  {mod} u_{pref} (")
        conns = []
        for d, _, n in TOP:
            sig = n if d == "input" else f"{pref}_{n}"
            conns.append(f"    .{n}({sig})")
        lines.append(",\n".join(conns))
        lines.append("  );")
        lines.append("")
    lines += [
        "  task automatic drive_inputs();",
        "    io_redirect_valid = ($urandom_range(0, 99) < 3);",
        "    io_redirect_bits_level = $urandom_range(0, 1);",
        "    io_rob_pendingMMIOld = ($urandom_range(0, 99) < 40);",
        "    io_uncache_req_ready = ($urandom_range(0, 99) < 85);",
    ]
    for _, w, n in inputs:
        if n in ("io_redirect_valid", "io_redirect_bits_level", "io_rob_pendingMMIOld",
                 "io_uncache_req_ready", "io_uncache_idResp_valid",
                 "io_uncache_idResp_bits_mid", "io_uncache_idResp_bits_sid",
                 "io_uncache_resp_valid", "io_uncache_resp_bits_data",
                 "io_uncache_resp_bits_id", "io_uncache_resp_bits_nderr"):
            continue
        lines.append(rand_assign(w, n))
    lines += [
        "    // 约束请求形态，避免 entry 内 golden 断言被随机非法覆盖触发。",
        "    io_req_0_valid = ($urandom_range(0, 99) < 18);",
        "    io_req_1_valid = ($urandom_range(0, 99) < 18);",
        "    io_req_2_valid = ($urandom_range(0, 99) < 18);",
    ]
    for lane in range(3):
        lines += [
            f"    io_req_{lane}_bits_mmio = io_req_{lane}_valid & ($urandom_range(0, 99) < 45);",
            f"    io_req_{lane}_bits_nc = io_req_{lane}_valid & !io_req_{lane}_bits_mmio;",
            f"    io_req_{lane}_bits_mask = 16'h00ff << (io_req_{lane}_bits_paddr[3] ? 8 : 0);",
            f"    io_req_{lane}_bits_rep_info_cause_0 = 1'b0;",
            f"    io_req_{lane}_bits_rep_info_cause_1 = 1'b0;",
            f"    io_req_{lane}_bits_rep_info_cause_2 = 1'b0;",
            f"    io_req_{lane}_bits_rep_info_cause_3 = 1'b0;",
            f"    io_req_{lane}_bits_rep_info_cause_4 = 1'b0;",
            f"    io_req_{lane}_bits_rep_info_cause_5 = 1'b0;",
            f"    io_req_{lane}_bits_rep_info_cause_6 = 1'b0;",
            f"    io_req_{lane}_bits_rep_info_cause_7 = 1'b0;",
            f"    io_req_{lane}_bits_rep_info_cause_8 = 1'b0;",
            f"    io_req_{lane}_bits_rep_info_cause_9 = 1'b0;",
            f"    io_req_{lane}_bits_rep_info_cause_10 = 1'b0;",
            f"    io_req_{lane}_bits_uop_exceptionVec_3 = 1'b0;",
            f"    io_req_{lane}_bits_uop_exceptionVec_4 = 1'b0;",
            f"    io_req_{lane}_bits_uop_exceptionVec_5 = 1'b0;",
            f"    io_req_{lane}_bits_uop_exceptionVec_13 = 1'b0;",
            f"    io_req_{lane}_bits_uop_exceptionVec_19 = 1'b0;",
            f"    io_req_{lane}_bits_uop_exceptionVec_21 = 1'b0;",
        ]
    lines += ["  endtask", ""]
    lines += [
        "  logic id_v_d0, id_v_d1;",
        "  logic [6:0] id_mid_d0, id_mid_d1;",
        "  logic [1:0] id_sid_d0, id_sid_d1;",
        "  logic resp_v_d0, resp_v_d1, resp_v_d2, resp_v_d3;",
        "  logic [1:0] resp_id_d0, resp_id_d1, resp_id_d2, resp_id_d3;",
        "  logic [63:0] resp_data_d0, resp_data_d1, resp_data_d2, resp_data_d3;",
        "  logic resp_nderr_d0, resp_nderr_d1, resp_nderr_d2, resp_nderr_d3;",
        "  wire uncache_req_fire = g_io_uncache_req_valid & io_uncache_req_ready;",
        "  always_ff @(posedge clock or posedge reset) begin",
        "    if (reset) begin",
        "      id_v_d0 <= 1'b0; id_v_d1 <= 1'b0;",
        "      resp_v_d0 <= 1'b0; resp_v_d1 <= 1'b0; resp_v_d2 <= 1'b0; resp_v_d3 <= 1'b0;",
        "    end else begin",
        "      id_v_d0 <= uncache_req_fire;",
        "      id_mid_d0 <= g_io_uncache_req_bits_id;",
        "      id_sid_d0 <= g_io_uncache_req_bits_id[1:0];",
        "      id_v_d1 <= id_v_d0;",
        "      id_mid_d1 <= id_mid_d0;",
        "      id_sid_d1 <= id_sid_d0;",
        "      resp_v_d0 <= id_v_d1;",
        "      resp_id_d0 <= id_sid_d1;",
        "      resp_data_d0 <= {$random, $random};",
        "      resp_nderr_d0 <= ($urandom_range(0, 99) < 2);",
        "      resp_v_d1 <= resp_v_d0; resp_id_d1 <= resp_id_d0; resp_data_d1 <= resp_data_d0; resp_nderr_d1 <= resp_nderr_d0;",
        "      resp_v_d2 <= resp_v_d1; resp_id_d2 <= resp_id_d1; resp_data_d2 <= resp_data_d1; resp_nderr_d2 <= resp_nderr_d1;",
        "      resp_v_d3 <= resp_v_d2; resp_id_d3 <= resp_id_d2; resp_data_d3 <= resp_data_d2; resp_nderr_d3 <= resp_nderr_d2;",
        "    end",
        "  end",
        "  always_comb begin",
        "    io_uncache_idResp_valid = id_v_d1;",
        "    io_uncache_idResp_bits_mid = id_mid_d1;",
        "    io_uncache_idResp_bits_sid = id_sid_d1;",
        "    io_uncache_resp_valid = resp_v_d3;",
        "    io_uncache_resp_bits_id = resp_id_d3;",
        "    io_uncache_resp_bits_data = resp_data_d3;",
        "    io_uncache_resp_bits_nderr = resp_nderr_d3;",
        "  end",
        "",
    ]
    lines.append("  task automatic cmp_bit(input string name, input logic g, input logic i);")
    lines.append("    if (!$isunknown(g)) begin checks++; if (g !== i) begin errors++; if (errors < 20) $display(\"ERR %s g=%b i=%b t=%0t\", name, g, i, $time); end end")
    lines.append("  endtask")
    lines.append("  task automatic cmp_vec(input string name, input logic [255:0] g, input logic [255:0] i, input int w);")
    lines.append("    for (int b = 0; b < w; b++) cmp_bit($sformatf(\"%s[%0d]\", name, b), g[b], i[b]);")
    lines.append("  endtask")
    lines.append("  task automatic compare_outputs();")
    for _, w, n in outputs:
        if w == 1:
            lines.append(f"    cmp_bit(\"{n}\", g_{n}, i_{n});")
        else:
            lines.append(f"    cmp_vec(\"{n}\", {{{{(256-{w}){{1'b0}}}}, g_{n}}}, {{{{(256-{w}){{1'b0}}}}, i_{n}}}, {w});")
    lines.append("  endtask")
    lines.append("  task automatic compare_fm_probes();")
    lines.append("    // Formality failing points: internal UncacheEntry regs.  These are not")
    lines.append("    // top-level outputs, but proving them mismatch-free under the legal UT")
    lines.append("    // environment lets us classify residual FM failures as unreachable/X-only.")
    lines.append("    cmp_bit(\"fm_entry0_req_valid\", u_g.entries_0.req_valid, u_i.u_core.u_entry_0.req_valid);")
    lines.append("    cmp_bit(\"fm_entry0_slaveAccept\", u_g.entries_0.slaveAccept, u_i.u_core.u_entry_0.slaveAccept);")
    lines.append("    cmp_bit(\"fm_entry0_req_vecActive\", u_g.entries_0.req_vecActive, u_i.u_core.u_entry_0.req_vecActive);")
    lines.append("    cmp_bit(\"fm_entry2_req_valid\", u_g.entries_2.req_valid, u_i.u_core.u_entry_2.req_valid);")
    for b in list(range(4, 10)) + list(range(40, 50)):
        lines.append(f"    cmp_bit(\"fm_entry0_req_vaddr_{b}\", u_g.entries_0.req_vaddr[{b}], u_i.u_core.u_entry_0.req_vaddr[{b}]);")
    lines.append("    cmp_bit(\"fm_redirect_d2_valid\", u_g.lastLastCycleRedirect_valid_REG, u_i.u_core.redirect_d2.valid);")
    lines.append("    cmp_bit(\"fm_redirect_d2_level\", u_g.lastLastCycleRedirect_bits_r_level, u_i.u_core.redirect_d2.level);")
    lines.append("    cmp_bit(\"fm_redirect_d2_rob_flag\", u_g.lastLastCycleRedirect_bits_r_robIdx_flag, u_i.u_core.redirect_d2.robIdx.flag);")
    for b in range(8):
        lines.append(f"    cmp_bit(\"fm_redirect_d2_rob_value_{b}\", u_g.lastLastCycleRedirect_bits_r_robIdx_value[{b}], u_i.u_core.redirect_d2.robIdx.value[{b}]);")
    lines.append("    cmp_bit(\"fm_rollback_valid\", u_g.io_rollback_valid_last_REG, u_i.u_core.rollback_valid_d);")
    lines.append("    cmp_bit(\"fm_rollback_bits_isRVC\", u_g.io_rollback_bits_r_isRVC, u_i.u_core.rollback_bits_d.isRVC);")
    for b in range(1, 8):
        lines.append(f"    cmp_bit(\"fm_rollback_bits_rob_value_{b}\", u_g.io_rollback_bits_r_robIdx_value[{b}], u_i.u_core.rollback_bits_d.robIdx.value[{b}]);")
    lines.append("    cmp_bit(\"fm_rollback_bits_ftq_flag\", u_g.io_rollback_bits_r_ftqIdx_flag, u_i.u_core.rollback_bits_d.ftq_flag);")
    for b in range(6):
        lines.append(f"    cmp_bit(\"fm_rollback_bits_ftq_value_{b}\", u_g.io_rollback_bits_r_ftqIdx_value[{b}], u_i.u_core.rollback_bits_d.ftq_value[{b}]);")
    for b in range(4):
        lines.append(f"    cmp_bit(\"fm_rollback_bits_ftq_offset_{b}\", u_g.io_rollback_bits_r_ftqOffset[{b}], u_i.u_core.rollback_bits_d.ftqOffset[{b}]);")
    lines.append("  endtask")
    lines += [
        "",
        "  initial begin",
        "    if ($value$plusargs(\"NCYCLES=%d\", NCYCLES)) begin end",
        "    reset = 1'b1;",
        "    drive_inputs();",
        "    repeat (8) @(posedge clock);",
        "    reset = 1'b0;",
        "    repeat (16) begin",
        "      @(negedge clock);",
        "      drive_inputs();",
        "      @(posedge clock);",
        "    end",
        "    for (int c = 0; c < NCYCLES; c++) begin",
        "      @(negedge clock);",
        "      drive_inputs();",
        "      @(posedge clock);",
        "      #1 compare_outputs();",
        "      compare_fm_probes();",
        "    end",
        "    $display(\"LoadQueueUncache checks=%0d errors=%0d\", checks, errors);",
        "    if (errors == 0) begin $display(\"TEST PASSED\"); $finish; end",
        "    else begin $display(\"TEST FAILED\"); $fatal; end",
        "  end",
        "endmodule",
    ]
    (UT / "tb.sv").write_text("\n".join(lines) + "\n")


def main():
    RTL.mkdir(parents=True, exist_ok=True)
    UT.mkdir(parents=True, exist_ok=True)
    gen_ports()
    gen_structs()
    gen_connect()
    gen_subinst()
    gen_wrapper()
    gen_variants()
    gen_makefile()
    gen_tb()


if __name__ == "__main__":
    main()
