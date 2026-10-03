#!/usr/bin/env python3
"""gen_exceptiongen.py —— ExceptionGen 的 golden 同名 wrapper 生成器（rtl/backend/ExceptionGen.sv 的 GENERATED 区）。

golden ExceptionGen 有 400 多个扁平端口（每个写回口、enq 口按字段展开，且各口只剩自己会用到的字段）。
wrapper 只做机械的"扁平端口 <-> 核的结构体字段"展平 / 改名，所以由本脚本从 golden 端口表生成；
可读核 xs_ExceptionGen_core 与写回组模块是手写的。

规则（fail-closed）：
  * 写回口按组映射：csr = wb0；load = wb8..10；store = wb6、wb7；向量运算 = wb1、wb2；向量访存 = wb11、wb12；
    wb3..5 golden 只剩 robIdx 两个端口且未被使用 —— 在 UNUSED 白名单里显式列出，wrapper 不连。
  * 每个 golden 输入端口必须恰好被一条字段规则或白名单命中；输出端口 io_state_* 同样逐个对上。
  * 口上没有的字段在核的结构体里保持 0（先整体清 0 再逐字段赋值）；例外是写回口的 trigger，
    父模块接的是 TriggerAction.None = 4'hF。

用法:
  scripts/gen_exceptiongen.py            # 改写 rtl/backend/ExceptionGen.sv 的 GENERATED 区
  scripts/gen_exceptiongen.py --check    # 只比对，有漂移 rc=1（gate 用）
"""
import argparse
import os
import re
import sys

G = "/home/eda/xs-env/G1-canonical/golden-rtl/ExceptionGen.sv"
HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.normpath(os.path.join(HERE, ".."))
RTL = os.path.join(REPO, "rtl", "backend", "ExceptionGen.sv")
BEGIN = "// BEGIN GENERATED(exceptiongen_wrapper) —— scripts/gen_exceptiongen.py，勿手改\n"
END = "// END GENERATED\n"

GROUPS = [("csr", [0]), ("load", [8, 9, 10]), ("store", [6, 7]), ("varith", [1, 2]), ("vls", [11, 12])]
UNUSED = {"io_wb_%d_bits_robIdx_%s" % (i, f) for i in (3, 4, 5) for f in ("flag", "value")}
ENQ_EV_IDX = [0, 1, 2, 3, 12, 20, 22]

# golden 字段名 -> 结构体字段（wb / enq / state 共用；exceptionVec_k、vuopIdx 另行处理）
FIELD = {
    "robIdx_flag": "rob_idx.flag", "robIdx_value": "rob_idx.value",
    "ftqPtr_value": "ftq_ptr", "ftqOffset": "ftq_offset",
    "hasException": "has_exception", "isEnqExcp": "is_enq_excp",
    "isFetchMalAddr": "is_fetch_mal_addr", "satpFlushFirstFetchFault": "satp_flush_first_fetch_fault",
    "flushPipe": "flush_pipe", "satpFlushPipe": "satp_flush_pipe", "isVset": "is_vset",
    "replayInst": "replay_inst", "singleStep": "single_step", "crossPageIPFFix": "cross_page_ipf_fix",
    "trigger": "trigger", "vstartEn": "vstart_en", "vstart": "vstart",
    "isVecLoad": "is_vec_load", "isVlm": "is_vlm", "isStrided": "is_strided", "isIndexed": "is_indexed",
    "isWhole": "is_whole", "nf": "nf", "vsew": "vsew", "veew": "veew", "vlmul": "vlmul",
}
PORT = re.compile(r"^\s*(input|output)\s+(?:\[(\d+):0\]\s+)?(\w+),?\s*$")


def golden_ports():
    txt = open(G).read()
    head = txt[txt.index("\nmodule ExceptionGen(") + 1:]
    head = head[:head.index("\n);")]
    out = []
    for ln in head.splitlines()[1:]:
        m = PORT.match(ln)
        if not m:
            raise SystemExit("gen_exceptiongen: 端口行解析失败: %r" % ln)
        out.append((m.group(1), int(m.group(2)) + 1 if m.group(2) else 1, m.group(3)))
    return out


def field_target(f, enq=False):
    m = re.fullmatch(r"exceptionVec_(\d+)", f)
    if m:
        k = int(m.group(1))
        if enq:
            if k not in ENQ_EV_IDX:
                raise SystemExit("gen_exceptiongen: enq 口不该有 exceptionVec_%d" % k)
            return "exception_vec[%d]" % ENQ_EV_IDX.index(k)
        return "exception_vec[%d]" % k
    if f not in FIELD:
        raise SystemExit("gen_exceptiongen: 未知字段 %s" % f)
    return FIELD[f]


def build():
    ports = golden_ports()
    used = set()
    wb_group = {}
    for g, idxs in GROUPS:
        for j, i in enumerate(idxs):
            wb_group[i] = (g, j)
    L = []
    L.append(BEGIN)
    L.append("module ExceptionGen (\n")
    L.append(",\n".join("  %-6s %s%s" % (d, ("[%d:0] " % (w - 1)) if w > 1 else "", n) for d, w, n in ports) + "\n")
    L.append(");\n")
    L.append("  import exceptiongen_pkg::*;\n\n")
    L.append("  logic [5:0]      enq_valid;\n  enq_excp_t [5:0] enq_bits;\n")
    for g, idxs in GROUPS:
        n = len(idxs)
        L.append("  logic [%d:0]      %s_valid;\n  wb_excp_t [%d:0]  %s_bits;\n" % (n - 1, g, n - 1, g))
    L.append("  logic [1:0][6:0] vls_vuop;\n  logic            state_valid;\n  excp_state_t     state;\n\n")
    body = []   # always_comb 里的逐字段赋值
    body.append("    enq_bits    = '0;\n")
    for g, _ in GROUPS:
        body.append("    %s_bits = '0;\n" % g)
    body.append("    vls_vuop    = '0;\n")
    # 没有 trigger 端口的写回口：父模块接的是 TriggerAction.None（4'hF），不是 0
    trig_ports = {n for _, _, n in ports}
    for g, idxs in GROUPS:
        for j, i in enumerate(idxs):
            if "io_wb_%d_bits_trigger" % i not in trig_ports:
                body.append("    %s_bits[%d].trigger = TRIGGER_NONE;\n" % (g, j))
    outs = []
    for d, w, n in ports:
        if n in ("clock", "reset"):
            used.add(n)
            continue
        if n in UNUSED:
            used.add(n)
            continue
        m = re.fullmatch(r"io_enq_(\d)_(valid|bits_(\w+))", n)
        if m:
            i = int(m.group(1))
            body.append("    enq_valid[%d] = %s;\n" % (i, n) if m.group(2) == "valid"
                        else "    enq_bits[%d].%s = %s;\n" % (i, field_target(m.group(3), enq=True), n))
            used.add(n)
            continue
        m = re.fullmatch(r"io_wb_(\d+)_(valid|bits_(\w+))", n)
        if m:
            i = int(m.group(1))
            if i not in wb_group:
                raise SystemExit("gen_exceptiongen: io_wb_%d 不属于任何组: %s" % (i, n))
            g, j = wb_group[i]
            if m.group(2) == "valid":
                body.append("    %s_valid[%d] = %s;\n" % (g, j, n))
            elif m.group(3) == "vuopIdx":
                if g != "vls":
                    raise SystemExit("gen_exceptiongen: 只有向量访存组带 vuopIdx: %s" % n)
                body.append("    vls_vuop[%d] = %s;\n" % (j, n))
            else:
                body.append("    %s_bits[%d].%s = %s;\n" % (g, j, field_target(m.group(3)), n))
            used.add(n)
            continue
        m = re.fullmatch(r"io_redirect_(valid|bits_robIdx_flag|bits_robIdx_value|bits_level)|io_flush", n)
        if m:
            used.add(n)
            continue
        m = re.fullmatch(r"io_state_(valid|bits_(\w+))", n)
        if m and d == "output":
            if m.group(1) == "valid":
                outs.append("  assign %s = state_valid;\n" % n)
            else:
                outs.append("  assign %s = state.%s;\n" % (n, field_target(m.group(2))))
            used.add(n)
            continue
        raise SystemExit("gen_exceptiongen: 端口没有规则: %s" % n)
    missing = {n for _, _, n in ports} - used
    if missing:
        raise SystemExit("gen_exceptiongen: 端口未处理: %s" % sorted(missing))
    L.append("  // 扁平端口 -> 核的结构体（口上没有的字段保持 0）\n")
    L.append("  always_comb begin\n")
    L += body
    L.append("  end\n\n")
    L.append("  xs_ExceptionGen_core u_core (\n")
    conns = [("clock", "clock"), ("reset", "reset"), ("redirect_valid", "io_redirect_valid"),
             ("redirect_ptr", "{io_redirect_bits_robIdx_flag, io_redirect_bits_robIdx_value}"),
             ("redirect_level", "io_redirect_bits_level"), ("flush", "io_flush"),
             ("enq_valid", "enq_valid"), ("enq_bits", "enq_bits")]
    for g, _ in GROUPS:
        conns += [("%s_valid" % g, "%s_valid" % g), ("%s_bits" % g, "%s_bits" % g)]
    conns += [("vls_vuop", "vls_vuop"), ("state_valid", "state_valid"), ("state", "state")]
    L.append(",\n".join("    .%-14s (%s)" % (a, b) for a, b in conns) + "\n")
    L.append("  );\n\n")
    L += outs
    L.append("endmodule\n")
    L.append(END)
    return "".join(L)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--check", action="store_true")
    args = ap.parse_args()
    gen = build()
    src = open(RTL).read()
    if BEGIN in src:
        a = src.index(BEGIN)
        b = src.index(END, a) + len(END)
        new = src[:a] + gen + src[b:]
    else:
        new = src.rstrip("\n") + "\n\n" + gen
    rel = os.path.relpath(RTL, REPO)
    if args.check:
        if new != src:
            print("gen_exceptiongen: DRIFT %s（请跑 scripts/gen_exceptiongen.py 刷新）" % rel)
            return 1
        print("gen_exceptiongen: OK %s" % rel)
        return 0
    if new != src:
        open(RTL, "w").write(new)
        print("gen_exceptiongen: wrote %s" % rel)
    else:
        print("gen_exceptiongen: unchanged %s" % rel)
    return 0


if __name__ == "__main__":
    sys.exit(main())
