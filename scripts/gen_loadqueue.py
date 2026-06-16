#!/usr/bin/env python3
"""
LoadQueue 顶层生成器。

LoadQueue 是香山 V2R2 乱序访存（LSU）里 load 侧的**队列层顶层**：它把 6 个子队列
拼装成统一的 load 队列接口，本层只做**路由 / 分发 / 汇聚 / 仲裁的 glue**，不含队列
算法本身。6 个子队列（全部作 golden 黑盒，UT/FM 两侧共用同一份 golden 定义）：

  * VirtualLoadQueue —— load 地址/状态主体，给出 ldWbPtr（已写回指针）
  * LoadQueueRAR     —— load-load(read-after-read) 违例检测
  * LoadQueueRAW     —— store-load(read-after-write / nuke) 违例检测，产生 nuke_rollback
  * LoadQueueReplay  —— 重放调度
  * LoadQueueUncache —— 非缓存 / MMIO load，产生 nack_rollback 与 exception
  * LqExceptionBuffer—— 异常聚合，给出 exceptionAddr

可读核 xs_LoadQueue_core 例化这 6 个子队列，并手写下述 glue（见 LoadQueue.sv）：
  1. enq / nuke_query / sta / std 等向各子队列的**分发**（直通连线）
  2. 子队列之间的**互联**：VLQ.ldWbPtr → RAR/Replay；RAR/RAW.lqFull → Replay
  3. **汇聚**：full_mask = {RAR,RAW,Replay}.lqFull
  4. **异常 req 组装**：LqExceptionBuffer 的 6 路 req（3 路 ldin + 2 路 vecFeedback +
     1 路 uncache exception），含 valid 的与运算
  5. **rollback 广播**：RAW.rollback → nuke_rollback；Uncache.rollback → nack_rollback
  6. **perf**：28 路性能事件各打两拍输出（前 18 路来自子队列，后 10 路为 full_mask /
     rollback 等组合条件）

本脚本：
  1. 解析 golden/chisel-rtl/LoadQueue.sv 的 6 个子模块实例连接表，把“被 glue 接管”
     的连接改接到可读核里手写的 readable 信号，其余直通照搬，生成 LoadQueue_inst.svh。
  2. 生成端口表 svh、perf 接出 svh、golden 同名 wrapper（FM/ST 用）、_xs 镜像、随机 tb。

可读核本体（手写）见 rtl/memblock/LoadQueue.sv，公共类型见 loadqueue_pkg.sv。
"""
import re
from pathlib import Path

XSSV = Path(__file__).resolve().parent.parent
GOLDEN = XSSV / "golden/chisel-rtl"
GSV = (GOLDEN / "LoadQueue.sv").read_text()
LINES = GSV.splitlines()

MEM = XSSV / "rtl/memblock"


# ----------------------------------------------------------------------------
# 顶层端口解析
# ----------------------------------------------------------------------------
def top_ports():
    m = re.search(r"^module LoadQueue\((.*?)\n\);", GSV, re.S | re.M)
    res = []
    for line in m.group(1).splitlines():
        pm = re.match(r"\s*(input|output)\s+(?:\[(\d+):0\])?\s*(\w+),?\s*$", line)
        if pm:
            res.append((pm.group(1), int(pm.group(2)) + 1 if pm.group(2) else 1, pm.group(3)))
    return res


# ----------------------------------------------------------------------------
# 实例连接表解析：返回 [(port, value_expr), ...]
# ----------------------------------------------------------------------------
def inst_conns(head_re):
    start = next(i for i, l in enumerate(LINES) if re.match(head_re, l))
    i = start + 1
    raw = []
    while not re.match(r"^   \);|^  \);", LINES[i]):
        raw.append(LINES[i])
        i += 1
    res, cur = [], None
    for l in raw:
        m = re.match(r"^\s*\.(\w+)\s*(.*)$", l)
        if m and (m.group(2).strip() == "" or m.group(2).strip().startswith("(")):
            if cur:
                res.append(cur)
            cur = [m.group(1), m.group(2).strip()]
        else:
            cur[1] += " " + l.strip()
    if cur:
        res.append(cur)
    return [(p, re.sub(r"\s+", " ", v).strip().rstrip(",")) for p, v in res]


def unwrap(v):
    v = v.strip()
    if v.startswith("(") and v.endswith(")"):
        # 仅去掉最外层成对括号
        depth = 0
        for i, ch in enumerate(v):
            if ch == "(":
                depth += 1
            elif ch == ")":
                depth -= 1
                if depth == 0 and i != len(v) - 1:
                    return v  # 内层括号未配平到末尾，保留原样
        return v[1:-1].strip()
    return v


# ----------------------------------------------------------------------------
# golden 内部网（_submodule_io_xxx）→ 可读核内部网名。
#   VLQ.ldWbPtr / RAR.lqFull / RAW.lqFull / Replay.lqFull /
#   RAW.rollback_{0,1}_valid / Uncache.rollback_valid / Uncache.exception_*
# 是子队列之间或子队列→顶层 glue 的内部联络线，用领域命名。
# ----------------------------------------------------------------------------
def golden_net_to_readable(g):
    g = g.strip()
    table = {
        "_virtualLoadQueue_io_ldWbPtr_flag":  "vlq_ldWbPtr.flag",
        "_virtualLoadQueue_io_ldWbPtr_value": "vlq_ldWbPtr.value",
        "_loadQueueRAR_io_lqFull":            "rar_full",
        "_loadQueueRAW_io_lqFull":            "raw_full",
        "_loadQueueReplay_io_lqFull":         "replay_full",
        "_loadQueueRAW_io_rollback_0_valid":  "raw_rollback_valid[0]",
        "_loadQueueRAW_io_rollback_1_valid":  "raw_rollback_valid[1]",
        "_uncacheBuffer_io_rollback_valid":   "unc_rollback_valid",
    }
    if g in table:
        return table[g]
    m = re.match(r"^_uncacheBuffer_io_exception_(\w+)$", g)
    if m:
        return "unc_exc_" + m.group(1)
    m = re.match(r"^_(\w+?)_io_perf_(\d+)_value$", g)
    if m:
        return None  # perf 单独处理
    return None


# 把含内部网的整段 value 表达式里出现的 golden 内部网名替换为可读网名
def subst_internal(val):
    def repl(mo):
        r = golden_net_to_readable(mo.group(0))
        return r if r is not None else mo.group(0)
    return re.sub(r"_[A-Za-z]\w*_io_\w+", repl, val)


# ----------------------------------------------------------------------------
# perf：每个子队列 perf 输出接到可读核的 perf 源网 perf_src[n]
#   映射顺序（与 golden io_perf_0..17 一致）：
#     0      ← VLQ.perf_0
#     1,2    ← RAR.perf_0,1
#     3,4    ← RAW.perf_0,1
#     5..17  ← Replay.perf_0..12
# ----------------------------------------------------------------------------
PERF_SRC_MAP = {
    ("virtualLoadQueue", 0): 0,
    ("loadQueueRAR", 0): 1, ("loadQueueRAR", 1): 2,
    ("loadQueueRAW", 0): 3, ("loadQueueRAW", 1): 4,
}
for k in range(13):
    PERF_SRC_MAP[("loadQueueReplay", k)] = 5 + k


def perf_net(submod, idx):
    return f"perf_src[{PERF_SRC_MAP[(submod, idx)]}]"


# ----------------------------------------------------------------------------
# 把一条子模块连接重写为可读核内部信号；返回 None 表示按 golden 原样直通。
# inst：golden 实例名（loadQueueRAR / virtualLoadQueue / ...）
# ----------------------------------------------------------------------------
def rewrite(inst, port, val):
    v = unwrap(val)

    # --- 子队列 perf 输出：接到 perf 源网，供两级打拍 ---
    m = re.match(r"^io_perf_(\d+)_value$", port)
    if m and (inst, int(m.group(1))) in PERF_SRC_MAP:
        return perf_net(inst, int(m.group(1)))

    # --- 值里含内部网（子队列互联 / 汇聚 glue）：整段做名字替换 ---
    if "_io_" in v and re.search(r"_[A-Za-z]\w*_io_\w+", v):
        return subst_internal(v)

    return None  # 纯顶层端口直通


def emit_inst(modname, instname, head_re, inst_goldname):
    conns = inst_conns(head_re)
    out = [f"  {modname} {instname} ("]
    body = []
    for port, val in conns:
        if port in ("clock", "reset"):
            body.append(f"    .{port}({port})")
            continue
        rw = rewrite(inst_goldname, port, val)
        body.append(f"    .{port}({rw if rw is not None else unwrap(val)})")
    out.append(",\n".join(body))
    out.append("  );")
    return "\n".join(out)


# ----------------------------------------------------------------------------
# 生成可读核 include 文件（6 个子队列实例的连接表）
# ----------------------------------------------------------------------------
INSTS = [
    ("LoadQueueRAR",     "u_lq_rar",     r"^  LoadQueueRAR loadQueueRAR \(",        "loadQueueRAR"),
    ("LoadQueueRAW",     "u_lq_raw",     r"^  LoadQueueRAW loadQueueRAW \(",        "loadQueueRAW"),
    ("LoadQueueReplay",  "u_lq_replay",  r"^  LoadQueueReplay loadQueueReplay \(",  "loadQueueReplay"),
    ("VirtualLoadQueue", "u_vlq",        r"^  VirtualLoadQueue virtualLoadQueue \(","virtualLoadQueue"),
    ("LqExceptionBuffer","u_exc_buf",    r"^  LqExceptionBuffer exceptionBuffer \(","exceptionBuffer"),
    ("LoadQueueUncache", "u_unc_buf",    r"^  LoadQueueUncache uncacheBuffer \(",   "uncacheBuffer"),
]


def gen_inst_svh():
    blocks = [emit_inst(m, i, h, g) for (m, i, h, g) in INSTS]
    hdr = ("// 自动生成：scripts/gen_loadqueue.py —— 勿手改\n"
           "// 由 xs_LoadQueue_core 通过 `include 引入：6 个子队列实例的端口连接表。\n"
           "// 直通端口连顶层同名口；子队列互联 / 汇聚 glue 连核内 readable 网。\n\n")
    (MEM / "LoadQueue_inst.svh").write_text(hdr + "\n\n".join(blocks) + "\n")


# ----------------------------------------------------------------------------
# wrapper / _xs / tb / ports / perf_out
# ----------------------------------------------------------------------------
def emit_flat_wrapper(modname, ps):
    decls = []
    for d, w, n in ps:
        ws = f"[{w-1}:0] " if w > 1 else ""
        decls.append(f"  {d:6s} {ws}{n}")
    L = [f"module {modname}(", ",\n".join(decls) + "\n);"]
    conns = [f"    .{n}({n})" for _, _, n in ps]
    L.append("  xs_LoadQueue_core u_core (")
    L.append(",\n".join(conns))
    L.append("  );")
    L.append("endmodule\n")
    return "\n".join(L)


def gen_ports_svh(ps):
    decls = []
    for d, w, n in ps:
        ws = f"[{w-1}:0] " if w > 1 else ""
        decls.append(f"  {d:6s} {ws}{n}")
    hdr = ("// 自动生成：scripts/gen_loadqueue.py —— 勿手改\n"
           "// 可读核 xs_LoadQueue_core 的端口列表（与 golden LoadQueue 同名扁平端口）。\n")
    (MEM / "LoadQueue_ports.svh").write_text(hdr + ",\n".join(decls) + "\n")


def gen_perf_out_svh():
    # io_perf_0..17 为 6 bit 直接接；18..27 为 1 bit 条件，零扩展到 6 bit
    L = ["// 自动生成：scripts/gen_loadqueue.py —— 勿手改",
         "// 28 路性能计数器打两拍后接出顶层端口。",
         "// 前 18 路（0..17）为子队列给出的 6-bit 计数；后 10 路（18..27）为 full_mask /",
         "// rollback 等 1-bit 组合条件，零扩展到 6 bit。"]
    for i in range(28):
        if i < 18:
            L.append(f"  assign io_perf_{i}_value = perf_stage2[{i}];")
        else:
            L.append(f"  assign io_perf_{i}_value = {{5'h0, perf_stage2[{i}][0]}};")
    (MEM / "LoadQueue_perf_out.svh").write_text("\n".join(L) + "\n")


def gen_tb(ps):
    ins = [(w, n) for d, w, n in ps if d == "input" and n not in ("clock", "reset")]
    outs = [(w, n) for d, w, n in ps if d == "output"]

    T = ["""// 自动生成：scripts/gen_loadqueue.py —— 勿手改
`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 200000;
  bit clk = 0, rst;
  int errors = 0, checks = 0;
  always #5 clk = ~clk;
"""]
    for w, n in ins:
        ws = f"[{w-1}:0] " if w > 1 else ""
        T.append(f"  logic {ws}{n};")
    for w, n in outs:
        ws = f"[{w-1}:0] " if w > 1 else ""
        T.append(f"  wire {ws}g_{n};")
        T.append(f"  wire {ws}i_{n};")

    gc = [".clock(clk)", ".reset(rst)"] + [f".{n}({n})" for _, n in ins]
    gg = gc + [f".{n}(g_{n})" for _, n in outs]
    ig = gc + [f".{n}(i_{n})" for _, n in outs]
    T.append(f"  LoadQueue    u_g ({', '.join(gg)});")
    T.append(f"  LoadQueue_xs u_i ({', '.join(ig)});")

    # 随机激励：redirect 低频；各 valid/ready 中频以覆盖握手；needAlloc 等地址/数据全随机；
    # isvec / nc_with_data / feedback 随机以覆盖异常 req 组装与 uncache req 的分流。
    valid_rate = {
        "io_redirect_valid": "($urandom_range(0,15)==0)",
    }

    def rnd(w, n):
        if n in valid_rate:
            return valid_rate[n]
        if n.endswith("_valid") or n.endswith("_ready"):
            return "$urandom_range(0,1)"
        if w == 1:
            return "$urandom_range(0,1)"
        if w <= 32:
            return f"{w}'($urandom)"
        rep = (w + 31) // 32
        return f"{w}'({{{', '.join(['$urandom()']*rep)}}})"

    reset_valids = [n for _, n in ins if n.endswith("_valid")]

    T.append("  always @(negedge clk) begin")
    T.append("    if (rst) begin")
    for n in reset_valids:
        T.append(f"      {n} <= 1'b0;")
    T.append("    end else begin")
    for w, n in ins:
        T.append(f"      {n} <= {rnd(w, n)};")
    T.append("    end")
    T.append("  end")

    # 逐拍比对所有输出（跳过 golden 为 X 的不可达态——子队列大量无复位寄存器）
    T.append("  always @(negedge clk) if (!rst) begin")
    T.append("    #4; checks++;")
    for w, n in outs:
        T.append(f"    if (!$isunknown(g_{n}) && g_{n} !== i_{n}) begin errors++;")
        T.append(f"      if(errors<=80) $display(\"[%0t] {n} g=%h i=%h\", $time, g_{n}, i_{n}); end")
    T.append("  end")
    T.append("""  initial begin
    rst = 1; repeat (16) @(posedge clk); rst = 0;
    repeat (NCYCLES) @(posedge clk);
    $display("checks=%0d errors=%0d", checks, errors);
    if (errors == 0 && checks > 1000) $display("TEST PASSED"); else $display("TEST FAILED");
    $finish;
  end
endmodule
""")
    return "\n".join(T)


def main():
    ps = top_ports()
    hdr = "// 自动生成：scripts/gen_loadqueue.py —— 勿手改\n"
    gen_inst_svh()
    gen_ports_svh(ps)
    gen_perf_out_svh()
    (MEM / "LoadQueue_wrapper.sv").write_text(hdr + emit_flat_wrapper("LoadQueue", ps))
    ut = XSSV / "verif/ut/LoadQueue"
    ut.mkdir(parents=True, exist_ok=True)
    (ut / "variants_xs.sv").write_text(hdr + emit_flat_wrapper("LoadQueue_xs", ps))
    (ut / "tb.sv").write_text(gen_tb(ps))
    ins = sum(1 for d, _, _ in ps if d == "input")
    outs = sum(1 for d, _, _ in ps if d == "output")
    print(f"LoadQueue: {len(ps)} ports ({ins} in / {outs} out)")


if __name__ == "__main__":
    main()
