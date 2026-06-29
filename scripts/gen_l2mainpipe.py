#!/usr/bin/env python3
"""生成 coupledL2 (tl2chi) MainPipe (L2 slice s2/s3/s4/s5 主流水) 的核 / wrapper / 变体 / UT。

MainPipe 是 L2 slice 的 "命中/缺失数据通路心脏"(5 级流水, golden=MainPipe_1, 509 端口):
  - s2: 收 RequestArb 送来的 task (io.taskFromArb_s2, 组合); 同时按 set/tag 反压 s1 入口(BlockInfo)。
  - s3: 主计算级。读 Directory 结果(dirResp_s3)→ 判命中/一致性(hit/needT/meta/tag)→
        派发: 发 MSHR alloc(toMSHRCtl)、发各通道响应(SourceD/TXREQ/TXRSP/TXDAT)、写 Directory
        (metaWReq/tagWReq)、读写 DataStorage(toDS)、嵌套写回(nestedwb)、预取训练(prefetchTrain)。
  - s4: 锁存 sinkB 响应/数据(为时序把 B 响应推后一拍), 处理 drop/forward。
  - s5: 收 DS 读数据(rdata_s5), 发 releaseBufWrite, 出 error, 收尾各通道。

单态化(firtool, MainPipe_1): clientBits=1, ways=8, sets=512, mshrBits=8, beatSize=2,
  blockBytes=64, **enableL2Flush=false**(无 cmoAllBlock/cmoLineDone 端口), Issue>=Eb(SnpQuery/
  WriteEvictOrEvict 生效)。TaskBundle 见 l2_task_pkg(95 字段)。

子模块边界:
  - **CustomL1Hint**(192 行, 自带 FSM 的 L1 预取 hint 生成器)→ 黑盒(wrapper 例化, 不进 FM_IMPL)。
  - **4 个 Arbiter3_*(toSourceD/TXREQ/TXRSP/TXDAT)**: Chisel 优先 Arbiter(in0=s5 最高 > s4 > s3),
    逻辑平凡, **内联进核**(把 ready 反压回流水的回路保持在核内, 避免黑盒反馈失配)。

样板: scripts/gen_requestarb.py。对照 Scala: coupledL2/.../tl2chi/MainPipe.scala(1107 行真逻辑)。
"""

import re
from pathlib import Path
from gen_grantbuffer import FIELDS, FW, sv, decl
from gen_l2mainpipe_core import gen_core, FSM, MSHR_TASK, DIR, META, HINT_S1

ROOT = Path(__file__).resolve().parents[1]
GOLDEN = ROOT / "golden" / "chisel-rtl"
RTL = ROOT / "rtl" / "uncore"
UT = ROOT / "verif" / "ut" / "L2MainPipe"
GOLD = "MainPipe_1"


def width_bits(w):
    if not w:
        return 1
    mm = re.match(r"\[(\d+):(\d+)\]", w)
    return abs(int(mm.group(1)) - int(mm.group(2))) + 1


def gold_ports():
    text = (GOLDEN / f"{GOLD}.sv").read_text()
    m = re.search(r"module\s+%s\s*\((.*?)\n\);" % GOLD, text, re.S)
    ports = []
    for raw in m.group(1).splitlines():
        line = raw.split("//", 1)[0].strip().rstrip(",")
        if not line:
            continue
        mm = re.match(r"(input|output)\s+(?:(?:wire|logic|reg)\s+)?(\[[^\]]+\])?\s*([A-Za-z_]\w*)$", line)
        d, w, n = mm.groups()
        ports.append((d, w or "", n))
    return ports


def gen_wrapper(top):
    """golden 同名壳 = xs_MainPipe_core + CustomL1Hint 黑盒。"""
    P = gold_ports()
    def is_hintonly(n):
        return n.startswith("io_taskInfo_s1") or n.startswith("io_l1Hint")
    core_ports = [p for p in P if p[2] not in ("clock", "reset") and not is_hintonly(p[2])]
    L = []
    L.append("// 自动生成 scripts/gen_l2mainpipe.py —— 勿手改")
    L.append(f"// {top}: golden 同名壳 = 可读核 xs_MainPipe_core + CustomL1Hint(黑盒) 装配。")
    L.append("// io_taskInfo_s1_* 直连 CustomL1Hint.io_s1_*; io_l1Hint_* 由 CustomL1Hint 驱动/消费;")
    L.append("// 核额外输出 hint_s3_* / hint_need_mshr 喂 CustomL1Hint.io_s3_*。")
    L.append(f"module {top}(")
    L.append(",\n".join(f"  {d} {w}{' ' if w else ''}{n}" for d, w, n in P))
    L.append(");")
    L.append("")
    L.append("  // ---- 核 → CustomL1Hint 的 s3 喂线 ----")
    L.append("  wire        hint_s3_task_valid;")
    L.append("  wire [2:0]  hint_s3_task_bits_channel;")
    L.append("  wire        hint_s3_task_bits_isKeyword;")
    L.append("  wire [3:0]  hint_s3_task_bits_opcode;")
    L.append("  wire [6:0]  hint_s3_task_bits_sourceId;")
    L.append("  wire        hint_s3_task_bits_mshrTask;")
    L.append("  wire        hint_s3_need_mshr;")
    L.append("")
    L.append("  xs_MainPipe_core u_core (")
    conns = ["    .clock(clock)", "    .reset(reset)"]
    for d, w, n in core_ports:
        conns.append(f"    .{n}({n})")
    for s in ["hint_s3_task_valid", "hint_s3_task_bits_channel", "hint_s3_task_bits_isKeyword",
              "hint_s3_task_bits_opcode", "hint_s3_task_bits_sourceId",
              "hint_s3_task_bits_mshrTask", "hint_s3_need_mshr"]:
        conns.append(f"    .{s}({s})")
    L.append(",\n".join(conns))
    L.append("  );")
    L.append("")
    L.append("  CustomL1Hint customL1Hint (")
    hc = ["    .clock(clock)", "    .reset(reset)"]
    for f in HINT_S1:
        hc.append(f"    .io_s1_bits_{f}(io_taskInfo_s1_bits_{f})")
    hc.append("    .io_s1_valid(io_taskInfo_s1_valid)")
    hc.append("    .io_s3_task_valid(hint_s3_task_valid)")
    hc.append("    .io_s3_task_bits_channel(hint_s3_task_bits_channel)")
    hc.append("    .io_s3_task_bits_isKeyword(hint_s3_task_bits_isKeyword)")
    hc.append("    .io_s3_task_bits_opcode(hint_s3_task_bits_opcode)")
    hc.append("    .io_s3_task_bits_sourceId(hint_s3_task_bits_sourceId)")
    hc.append("    .io_s3_task_bits_mshrTask(hint_s3_task_bits_mshrTask)")
    hc.append("    .io_s3_need_mshr(hint_s3_need_mshr)")
    hc.append("    .io_l1Hint_ready(io_l1Hint_ready)")
    hc.append("    .io_l1Hint_valid(io_l1Hint_valid)")
    hc.append("    .io_l1Hint_bits_sourceId(io_l1Hint_bits_sourceId)")
    hc.append("    .io_l1Hint_bits_isKeyword(io_l1Hint_bits_isKeyword)")
    L.append(",\n".join(hc))
    L.append("  );")
    L.append("endmodule")
    L.append("")
    return "\n".join(L)


def gen_tb():
    P = gold_ports()
    ins = [p for p in P if p[0] == "input" and p[2] not in ("clock", "reset")]
    outs = [p for p in P if p[0] == "output"]
    L = []
    L.append("// 自动生成 scripts/gen_l2mainpipe.py —— 勿手改")
    L.append("// MainPipe 双例化逐拍比对: golden MainPipe_1 vs 可读重写 MainPipe_1_xs。")
    L.append("// 偏置 channel/txChannel one-hot, opcode/chiOpcode/param/set/tag 偏小。两侧共用 golden CustomL1Hint。")
    L.append("`timescale 1ns/1ps")
    L.append("`define CHK(SIG) begin \\")
    L.append("  if (!$isunknown(g_``SIG)) begin \\")
    L.append("    checks++; \\")
    L.append("    if (g_``SIG !== i_``SIG) begin \\")
    L.append("      errors++; \\")
    L.append("      if (errors <= 40) $display(\"[%0t] MISMATCH %s g=%0h i=%0h\", $time, `\"SIG`\", g_``SIG, i_``SIG); \\")
    L.append("    end \\")
    L.append("  end \\")
    L.append("end")
    L.append("module tb;")
    L.append("  int unsigned NCYCLES = 200000;")
    L.append("  bit clock = 0; bit reset; int errors = 0; int checks = 0;")
    L.append("  always #5 clock = ~clock;")
    for _, w, n in ins:
        L.append(f"  logic {w}{' ' if w else ''}{n};")
    for _, w, n in outs:
        L.append(f"  wire {w}{' ' if w else ''}g_{n};")
        L.append(f"  wire {w}{' ' if w else ''}i_{n};")
    L.append("")
    for instname, pfx in ((GOLD, "g_"), (f"{GOLD}_xs", "i_")):
        L.append(f"  {instname} u_{pfx[0]} (")
        for i, (d, _, n) in enumerate(P):
            c = "," if i + 1 < len(P) else ""
            sig = n if (n in ("clock", "reset") or d == "input") else f"{pfx}{n}"
            L.append(f"    .{n}({sig}){c}")
        L.append("  );")
    L.append("")
    L.append("  function automatic logic [2:0] oh3(); int k; k = $urandom_range(0,2); return (3'h1 << k); endfunction")
    L.append("")
    L.append("  task automatic drive_random();")
    for _, w, n in ins:
        nb = width_bits(w)
        if n.endswith("_bits_channel") and "Info" not in n:
            L.append(f"    {n} = oh3();")
        elif n.endswith("_bits_txChannel"):
            L.append(f"    {n} = oh3();")
        elif n.endswith("_bits_opcode") and "aMergeTask" not in n:
            L.append(f"    {n} = $urandom_range(0,14);")
        elif n.endswith("_bits_chiOpcode"):
            L.append(f"    {n} = $urandom_range(0,32);")
        elif n.endswith("_bits_param") and "aMergeTask" not in n:
            L.append(f"    {n} = $urandom_range(0,5);")
        elif n.endswith("_meta_state") or n.endswith("_bits_state"):
            L.append(f"    {n} = $urandom_range(0,3);")
        elif n.endswith("_bits_set") or re.search(r"_sets_[0-3]$", n):
            L.append(f"    {n} = $urandom_range(0,7);")
        elif n.endswith("_bits_tag") or n.endswith("_tags_1"):
            L.append(f"    {n} = $urandom_range(0,7);")
        elif n.endswith("_bits_way"):
            L.append(f"    {n} = $urandom_range(0,7);")
        elif n.endswith("_valid"):
            L.append(f"    {n} = ($urandom_range(0,1) == 0);")
        elif n in ("io_toTXDAT_ready", "io_l1Hint_ready", "io_prefetchTrain_ready"):
            L.append(f"    {n} = ($urandom_range(0,2) != 0);")
        elif nb <= 32:
            L.append(f"    {n} = $urandom;")
        else:
            words = (nb + 31) // 32
            cat = ", ".join(["$urandom"] * words)
            L.append(f"    {n} = {{{cat}}};")
    L.append("  endtask")
    L.append("")
    L.append("  task automatic check_outputs();")
    for _, _, n in outs:
        L.append(f"    `CHK({n})")
    L.append("  endtask")
    L.append("")
    L.append("  int ierr = 0;")
    L.append("  `define IP(SIG) begin \\")
    L.append("    if (!$isunknown(u_g.SIG)) begin \\")
    L.append("      if (u_g.SIG !== u_i.u_core.SIG) begin \\")
    L.append("        ierr++; \\")
    L.append("        if (ierr <= 60) $display(\"[%0t] IPROBE-DIFF %s g=%0h i=%0h\", $time, `\"SIG`\", u_g.SIG, u_i.u_core.SIG); \\")
    L.append("      end \\")
    L.append("    end \\")
    L.append("  end")
    L.append("  task automatic check_internal();")
    for s in ["resetFinish", "resetIdx", "task_s3_valid", "task_s4_valid", "task_s5_valid",
              "replResp_valid_s4", "task_s3_valid_hold2",
              "isD_s4", "isTXREQ_s4", "isTXRSP_s4", "isTXDAT_s4",
              "isD_s5", "isTXREQ_s5", "isTXRSP_s5", "isTXDAT_s5",
              "tagError_s4", "dataError_s4", "l2Error_s4",
              "tagError_s5", "dataMetaError_s5", "l2TagError_s5",
              "need_write_releaseBuf_s4", "need_write_releaseBuf_s5",
              "chnl_valid_s4_REG", "chnl_valid_s5_REG"]:
        L.append(f"    `IP({s})")
    for n, _ in FIELDS:
        L.append(f"    `IP(task_s3_bits_{n})")
        L.append(f"    `IP(task_s4_bits_{n})")
        L.append(f"    `IP(task_s5_bits_{n})")
    L.append("  endtask")
    L.append("")
    L.append("  initial begin")
    L.append("    if ($value$plusargs(\"NCYCLES=%d\", NCYCLES)) begin end")
    L.append("    reset = 1'b1;")
    for _, _, n in ins:
        L.append(f"    {n} = '0;")
    L.append("    repeat (5) @(posedge clock);")
    L.append("    reset = 1'b0;")
    L.append("    repeat (NCYCLES) begin")
    L.append("      @(negedge clock);")
    L.append("      drive_random();")
    L.append("      #1 check_outputs();")
    L.append("      check_internal();")
    L.append("      @(posedge clock);")
    L.append("    end")
    L.append("    $display(\"MainPipe checks=%0d errors=%0d ierr=%0d\", checks, errors, ierr);")
    L.append("    if (errors == 0 && ierr == 0) begin $display(\"TEST PASSED\"); $finish; end")
    L.append("    $display(\"TEST FAILED\"); $fatal(1);")
    L.append("  end")
    L.append("endmodule")
    L.append("`undef CHK")
    L.append("`undef IP")
    L.append("")
    return "\n".join(L)


MAKEFILE = """MODULE = MainPipe_1

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

RTL_SRCS = $(RTL_DIR)/uncore/l2_task_pkg.sv $(RTL_DIR)/uncore/MainPipe_1.sv
WRAPPER_SRCS = $(RTL_DIR)/uncore/MainPipe_1_wrapper.sv
GOLDEN_SRCS = $(GOLDEN_RTL)/MainPipe_1.sv \\
              $(GOLDEN_RTL)/CustomL1Hint.sv \\
              $(GOLDEN_RTL)/Queue16_HintQueueEntry.sv \\
              $(GOLDEN_RTL)/Queue4_HintQueueEntry.sv \\
              $(GOLDEN_RTL)/ram_16x11.sv \\
              $(GOLDEN_RTL)/ram_4x11.sv \\
              $(GOLDEN_RTL)/Arbiter3_TaskWithData.sv \\
              $(GOLDEN_RTL)/Arbiter3_CHIREQ.sv \\
              $(GOLDEN_RTL)/Arbiter3_TaskBundle.sv
TB_SRCS = variants_xs.sv tb.sv

# FM: ref = golden MainPipe_1; CustomL1Hint 两侧黑盒(不进 deps/impl);
#     Arbiter3_* 内联进核 → 必须进 ref deps 让 FM 展平 golden 端的仲裁器。
FM_VARIANTS = MainPipe_1
FM_REF_DEPS_MainPipe_1 = Arbiter3_TaskWithData.sv Arbiter3_CHIREQ.sv Arbiter3_TaskBundle.sv

include ../../../scripts/ut_common.mk

VCS += +define+SYNTHESIS +vcs+initreg+random
SIM_ARGS += +vcs+initreg+0
"""


def main():
    UT.mkdir(parents=True, exist_ok=True)
    (RTL / f"{GOLD}.sv").write_text(gen_core())
    (RTL / f"{GOLD}_wrapper.sv").write_text(gen_wrapper(GOLD))
    (UT / "variants_xs.sv").write_text(gen_wrapper(f"{GOLD}_xs"))
    (UT / "tb.sv").write_text(gen_tb())
    (UT / "Makefile").write_text(MAKEFILE)
    print(f"generated {GOLD}: core/wrapper/variant/tb/Makefile")


if __name__ == "__main__":
    main()
