#!/usr/bin/env python3
"""生成 MSHR (coupledL2 tl2chi L2 缓存 miss 处理状态机) 的 wrapper / 变体 / UT / Makefile。

MSHR 是纯逻辑状态机叶子(无子模块、无 SRAM、无黑盒), 故:
  - wrapper (golden 同名 MSHR)    : FM impl 侧顶层, 例化可读核 xs_MSHR_core
  - 变体    (MSHR_xs)             : UT impl 侧顶层, 同样例化 xs_MSHR_core
  - tb.sv   : 双例化 (golden MSHR vs _xs) 逐拍随机激励 + 逐拍比对全部输出
  - Makefile: include ut_common.mk

UT 激励策略: 时序状态机, 每拍随机驱动所有输入(含 ready/alloc/resp 各 valid),
偏向打开 alloc/各 resp 以推进状态机覆盖, 比对全部 153 个输出 (含内部 will_free 等)。
"""

import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
GOLDEN = ROOT / "golden" / "chisel-rtl"
RTL = ROOT / "rtl" / "uncore"
UT = ROOT / "verif" / "ut" / "MSHR"


def parse_ports(path, module):
    text = path.read_text()
    m = re.search(rf"module\s+{module}\s*\((.*?)\n\);", text, re.S)
    if not m:
        raise RuntimeError(f"module {module} not found")
    ports = []
    for raw in m.group(1).splitlines():
        line = raw.split("//", 1)[0].strip().rstrip(",")
        if not line:
            continue
        mm = re.match(r"(input|output)\s+(?:(?:wire|logic|reg)\s+)?(\[[^\]]+\])?\s*([A-Za-z_]\w*)$", line)
        if not mm:
            raise RuntimeError(f"cannot parse port line: {raw}")
        d, w, n = mm.groups()
        ports.append((d, w or "", n))
    return ports


def width_bits(w):
    if not w:
        return 1
    mm = re.match(r"\[(\d+):(\d+)\]", w)
    hi, lo = map(int, mm.groups())
    return abs(hi - lo) + 1


def module_header(name, ports):
    body = ",\n".join(f"  {d} {w}{' ' if w else ''}{n}" for d, w, n in ports)
    return f"module {name}(\n{body}\n);\n"


def inst(module, name, ports):
    lines = [f"  {module} {name} ("]
    for i, (_, _, p) in enumerate(ports):
        c = "," if i + 1 < len(ports) else ""
        lines.append(f"    .{p}({p}){c}")
    lines.append("  );")
    return "\n".join(lines)


def gen_wrapper(top, ports):
    return ("// 自动生成 scripts/gen_mshr.py —— 勿手改\n"
            + module_header(top, ports) + inst("xs_MSHR_core", "u_core", ports) + "\nendmodule\n")


def gen_variant(ports):
    return ("// 自动生成 scripts/gen_mshr.py —— 勿手改\n"
            + module_header("MSHR_xs", ports) + inst("xs_MSHR_core", "u_core", ports) + "\nendmodule\n")


def gen_tb(ports):
    ins = [p for p in ports if p[0] == "input" and p[2] not in ("clock", "reset")]
    outs = [p for p in ports if p[0] == "output"]
    L = []
    L.append("// 自动生成 scripts/gen_mshr.py —— 勿手改")
    L.append("// MSHR 双例化逐拍比对: golden MSHR vs 可读重写 MSHR_xs。")
    L.append("// 时序一致性状态机: 每拍随机驱动所有输入, 偏向开 alloc/resp 推进 FSM, 逐拍比全部输出。")
    L.append("`timescale 1ns/1ps")
    L.append("`define CHK(SIG) begin \\")
    L.append("  if (!$isunknown(g_``SIG)) begin \\")
    L.append("    checks++; \\")
    L.append("    if (g_``SIG !== i_``SIG) begin \\")
    L.append("      errors++; \\")
    L.append("      if (errors <= 30) $display(\"[%0t] MISMATCH %s g=%0h i=%0h\", $time, `\"SIG`\", g_``SIG, i_``SIG); \\")
    L.append("    end \\")
    L.append("  end \\")
    L.append("end")
    L.append("module tb;")
    L.append("  int unsigned NCYCLES = 200000;")
    L.append("  bit clock = 0; bit reset; int errors = 0; int checks = 0;")
    L.append("  always #5 clock = ~clock;")
    # 输入信号 (io_id 也在 ins 里, 统一声明)
    for _, w, n in ins:
        L.append(f"  logic {w}{' ' if w else ''}{n};")
    # 输出 g_/i_
    for _, w, n in outs:
        L.append(f"  wire {w}{' ' if w else ''}g_{n};")
        L.append(f"  wire {w}{' ' if w else ''}i_{n};")
    L.append("")
    # golden 例化
    L.append("  MSHR u_g (")
    for i, (d, _, n) in enumerate(ports):
        c = "," if i + 1 < len(ports) else ""
        if n in ("clock", "reset"):
            sig = n
        elif d == "input":
            sig = n
        else:
            sig = f"g_{n}"
        L.append(f"    .{n}({sig}){c}")
    L.append("  );")
    L.append("  MSHR_xs u_i (")
    for i, (d, _, n) in enumerate(ports):
        c = "," if i + 1 < len(ports) else ""
        if n in ("clock", "reset"):
            sig = n
        elif d == "input":
            sig = n
        else:
            sig = f"i_{n}"
        L.append(f"    .{n}({sig}){c}")
    L.append("  );")
    L.append("")
    # 随机驱动 task
    L.append("  task automatic drive_random();")
    for _, w, n in ins:
        nb = width_bits(w)
        if n == "io_id":
            continue  # io_id 当作常量 MSHR id, 在 initial 一次性赋值
        if n == "io_alloc_valid":
            # 适度打开 alloc (~1/8)
            L.append(f"    {n} = ($urandom_range(0,7) == 0);")
        elif n in ("io_resps_sinkC_valid", "io_resps_rxrsp_valid", "io_resps_rxdat_valid",
                   "io_replResp_valid", "io_aMergeTask_valid", "io_pCrd_grant",
                   "io_nestedwb_c_set_dirty", "io_nestedwb_c_set_tip", "io_nestedwb_b_inv_dirty",
                   "io_nestedwb_b_toB", "io_nestedwb_b_toN", "io_nestedwb_b_toClean"):
            # 响应/嵌套类输入: ~1/4 打开
            L.append(f"    {n} = ($urandom_range(0,3) == 0);")
        elif n.endswith("_ready"):
            # 各 ready ~3/4 打开, 促成 fire
            L.append(f"    {n} = ($urandom_range(0,3) != 0);")
        elif nb <= 32:
            L.append(f"    {n} = $urandom;")
        else:
            words = (nb + 31) // 32
            cat = ", ".join(["$urandom"] * words)
            L.append(f"    {n} = {{{cat}}};")
    L.append("  endtask")
    L.append("")
    # 比对 task
    L.append("  task automatic check_outputs();")
    for _, _, n in outs:
        L.append(f"    `CHK({n})")
    L.append("  endtask")
    L.append("")
    # 内部 FSM 状态层次探针: 逐拍比 golden vs xs 的核心一致性状态寄存器
    L.append("  // 内部状态层次探针: 逐拍比 golden(u_g) vs 可读核(u_i.u_core) 的 FSM 寄存器,")
    L.append("  // 防止仅比端口漏掉内部状态分叉(s_*/w_* 标志、dirResult.meta、错误标志等)。")
    L.append("  int ierr = 0;")
    L.append("  `define IPROBE(PATH) begin \\")
    L.append("    if (!$isunknown(u_g.``PATH)) begin \\")
    L.append("      if (u_g.``PATH !== u_i.u_core.``PATH) begin \\")
    L.append("        ierr++; \\")
    L.append("        if (ierr <= 30) $display(\"[%0t] IPROBE-DIFF %s g=%0h i=%0h\", $time, `\"PATH`\", u_g.``PATH, u_i.u_core.``PATH); \\")
    L.append("      end \\")
    L.append("    end \\")
    L.append("  end")
    iregs = [
        "state_s_acquire","state_s_rprobe","state_s_pprobe","state_s_release","state_s_probeack",
        "state_s_refill","state_s_retry","state_s_cmoresp","state_s_cmometaw","state_w_rprobeackfirst",
        "state_w_rprobeacklast","state_w_pprobeackfirst","state_w_pprobeacklast","state_w_grantfirst",
        "state_w_grantlast","state_w_grant","state_w_releaseack","state_w_replResp","state_s_rcompack",
        "state_s_wcompack","state_s_cbwrdata","state_s_reissue","state_s_dct",
        "req_valid","dirResult_hit","dirResult_tag","dirResult_way","dirResult_meta_dirty",
        "dirResult_meta_state","dirResult_meta_clients","gotT","gotDirty","gotGrantData","probeDirty",
        "releaseDirty","tagErr","denied","corrupt","dataCheckErr","gotRetryAck","gotPCrdGrant",
        "pcrdtype","retryTimes","backoffTimer","req_released_chiOpcode","tgtid_rcompack","txnid_rcompack",
        "tgtid_wcompack","txnid_wcompack","srcid_retryack","mergeA","req_traceTag","req_aliasTask",
    ]
    L.append("  task automatic check_internal();")
    for r in iregs:
        L.append(f"    `IPROBE({r})")
    L.append("  endtask")
    L.append("")
    L.append("  initial begin")
    L.append("    if ($value$plusargs(\"NCYCLES=%d\", NCYCLES)) begin end")
    L.append("    reset = 1'b1;")
    for _, _, n in ins:
        L.append(f"    {n} = '0;")
    L.append("    io_id = $urandom;  // io_id 固定: 当作常量 MSHR id")
    L.append("    repeat (5) @(posedge clock);")
    L.append("    reset = 1'b0;")
    L.append("    repeat (NCYCLES) begin")
    L.append("      @(negedge clock);")
    L.append("      drive_random();")
    L.append("      #1 check_outputs();")  # 同拍比组合输出(在 posedge 之前 settle)
    L.append("      check_internal();")    # 同拍比内部 FSM 寄存器
    L.append("      @(posedge clock);")
    L.append("    end")
    L.append("    $display(\"MSHR checks=%0d errors=%0d ierr=%0d\", checks, errors, ierr);")
    L.append("    if (errors == 0 && ierr == 0) begin $display(\"TEST PASSED\"); $finish; end")
    L.append("    $display(\"TEST FAILED\"); $fatal(1);")
    L.append("  end")
    L.append("endmodule")
    L.append("`undef CHK")
    L.append("")
    return "\n".join(L)


def main():
    UT.mkdir(parents=True, exist_ok=True)
    ports = parse_ports(GOLDEN / "MSHR.sv", "MSHR")
    (RTL / "MSHR_wrapper.sv").write_text(gen_wrapper("MSHR", ports))
    (UT / "variants_xs.sv").write_text(gen_variant(ports))
    (UT / "tb.sv").write_text(gen_tb(ports))
    (UT / "Makefile").write_text(
        """MODULE = MSHR

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

RTL_SRCS = $(RTL_DIR)/uncore/mshr_pkg.sv \\
           $(RTL_DIR)/uncore/MSHR.sv

# MSHR.sv `include 以下 .svh(不直接编译, 仅作为 simv 重编依赖)
RTL_INC = $(RTL_DIR)/uncore/mshr_core.svh $(RTL_DIR)/uncore/mshr_mainpipe.svh \\
          $(RTL_DIR)/uncore/mshr_seq.svh $(RTL_DIR)/uncore/mshr_outputs.svh
simv: $(RTL_INC)

TB_SRCS = variants_xs.sv tb.sv

GOLDEN_SRCS = $(GOLDEN_RTL)/MSHR.sv

WRAPPER_SRCS = $(RTL_DIR)/uncore/MSHR_wrapper.sv
FM_VARIANTS = MSHR

include ../../../scripts/ut_common.mk

VCS += +define+SYNTHESIS +vcs+initreg+random +incdir+$(RTL_DIR)/uncore
SIM_ARGS += +vcs+initreg+0
""")
    print("generated MSHR wrapper / variant / tb / Makefile;", len(ports), "ports")


if __name__ == "__main__":
    main()
