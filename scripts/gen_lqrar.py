#!/usr/bin/env python3
"""gen_lqrar.py —— LoadQueueRAR 簇（LoadQueueRAR / LqPAddrModule）的机械派生区生成器。

生成对象（都是"没有微架构"的纯机械部分；手写区一个字节都不动）：
  rtl/memblock/LqPAddrModule.sv   GENERATED(lqpaddr-wrapper)：golden 同名 wrapper
                                  （端口表逐字取 golden，展平/改名后例化 xs_LqPAddrModule_core）
  rtl/memblock/LoadQueueRAR.sv    两个 GENERATED 区：
    lqrar-cam-inst  核里 CAM 阵列 LqPAddrModule 的例化（golden 扁平端口 × 数组下标，逐位接线）
    lqrar-wrapper   golden 同名 wrapper：端口表逐字取 golden，按映射表拆/装结构体
  verif/ut/LoadQueueRAR/fm_pins_pre.tcl   FM「匹配前」钉点（见 gen_lqrar_pins 的注释）

fail-closed 核对：
  (1) LqPAddrModule 的 golden 端口集合 == 预期形状（逐项、含顺序与位宽），多一个少一个都报错；
  (2) LoadQueueRAR 每个 golden 端口恰好命中一条映射规则，每条规则至少命中一个端口；
  (3) 钉点：每个 golden 顶层寄存器恰好命中一条规则、映射是单射；
  (4) --check：生成结果与磁盘逐字节比较，有漂移 rc=1。

用法:
  scripts/gen_lqrar.py            # 写文件
  scripts/gen_lqrar.py --check    # 只比对，不写；有漂移 rc=1（gate 用）
"""
import argparse
import os
import re
import sys

GOLDEN_DIR = "/home/eda/xs-env/G1-canonical/golden-rtl"
HERE = os.path.dirname(os.path.abspath(__file__))
RTL = os.path.normpath(os.path.join(HERE, "..", "rtl", "memblock"))

NUM_WRITE = 3
NUM_VIO = 3
NUM_ENTRIES = 72
ADDR_W = 7
DATA_W = 16
RELEASE_PORT = 2   # golden 只剩 releaseMdata/Mmask 的第 2 口（takeRight(1)）


def port_table(module):
    """golden 顶层端口表：[(dir, width, name, 原文行)]，顺序即 golden 顺序。"""
    path = os.path.join(GOLDEN_DIR, module + ".sv")
    lines = open(path).read().split("\n")
    start = next(i for i, l in enumerate(lines) if l.startswith("module %s(" % module))
    end = start
    while not lines[end].startswith(");"):
        end += 1
    out = []
    pat = re.compile(r"\s*(input|output)\s+(?:\[(\d+):(\d+)\]\s*)?([A-Za-z_]\w*)\s*,?\s*$")
    for l in lines[start + 1:end]:
        m = pat.match(l)
        if not m:
            raise SystemExit("gen_lqrar: 端口行解析失败: %r" % l)
        w = int(m.group(2)) - int(m.group(3)) + 1 if m.group(2) else 1
        out.append((m.group(1), w, m.group(4), l.rstrip(",").rstrip()))
    return out


# ---------------------------------------------------------------------------
#  LqPAddrModule wrapper
# ---------------------------------------------------------------------------
LQPADDR = os.path.join(RTL, "LqPAddrModule.sv")


def lqpaddr_expected_ports():
    exp = [("input", 1, "clock"), ("input", 1, "reset")]
    exp += [("input", 1, "io_wen_%d" % w) for w in range(NUM_WRITE)]
    exp += [("input", ADDR_W, "io_waddr_%d" % w) for w in range(NUM_WRITE)]
    exp += [("input", DATA_W, "io_wdata_%d" % w) for w in range(NUM_WRITE)]
    exp += [("input", DATA_W, "io_releaseMdata_%d" % RELEASE_PORT)]
    exp += [("output", 1, "io_releaseMmask_%d_%d" % (RELEASE_PORT, j)) for j in range(NUM_ENTRIES)]
    exp += [("input", DATA_W, "io_releaseViolationMdata_%d" % c) for c in range(NUM_VIO)]
    exp += [("output", 1, "io_releaseViolationMmask_%d_%d" % (c, j))
            for c in range(NUM_VIO) for j in range(NUM_ENTRIES)]
    return exp


def gen_lqpaddr_wrapper():
    ports = port_table("LqPAddrModule")
    got = [(d, w, n) for d, w, n, _ in ports]
    exp = lqpaddr_expected_ports()
    if got != exp:
        gs, es = set(got), set(exp)
        raise SystemExit("gen_lqrar: LqPAddrModule golden 端口表与预期形状不符\n  多: %s\n  少: %s\n  (或顺序不同)"
                         % (sorted(gs - es)[:8], sorted(es - gs)[:8]))
    o = []
    o.append("module LqPAddrModule(")
    for i, (_, _, _, raw) in enumerate(ports):
        o.append(raw + ("," if i + 1 < len(ports) else ""))
    o.append(");")
    o.append("  // reset 只被 golden `ifndef SYNTHESIS 的写冲突断言用到，综合视图里悬空。")
    o.append("  logic [%d:0] waddr [%d];" % (ADDR_W - 1, NUM_WRITE))
    o.append("  logic [%d:0] wdata [%d];" % (DATA_W - 1, NUM_WRITE))
    o.append("  logic [%d:0] vioMdata [%d];" % (DATA_W - 1, NUM_VIO))
    o.append("  logic [%d:0] releaseMmask;" % (NUM_ENTRIES - 1))
    o.append("  logic [%d:0] vioMmask [%d];" % (NUM_ENTRIES - 1, NUM_VIO))
    o.append("")
    for w in range(NUM_WRITE):
        o.append("  assign waddr[%d] = io_waddr_%d;" % (w, w))
    for w in range(NUM_WRITE):
        o.append("  assign wdata[%d] = io_wdata_%d;" % (w, w))
    for c in range(NUM_VIO):
        o.append("  assign vioMdata[%d] = io_releaseViolationMdata_%d;" % (c, c))
    o.append("")
    o.append("  xs_LqPAddrModule_core #(")
    o.append("    .NUM_ENTRIES (%d)," % NUM_ENTRIES)
    o.append("    .DATA_W      (%d)," % DATA_W)
    o.append("    .NUM_WRITE   (%d)," % NUM_WRITE)
    o.append("    .NUM_WBANK   (8),")
    o.append("    .NUM_VIO_CAM (%d)" % NUM_VIO)
    o.append("  ) u_core (")
    o.append("    .clock                    (clock),")
    o.append("    .io_wen                   ({%s})," % ", ".join("io_wen_%d" % w for w in reversed(range(NUM_WRITE))))
    o.append("    .io_waddr                 (waddr),")
    o.append("    .io_wdata                 (wdata),")
    o.append("    .io_releaseMdata          (io_releaseMdata_%d)," % RELEASE_PORT)
    o.append("    .io_releaseMmask          (releaseMmask),")
    o.append("    .io_releaseViolationMdata (vioMdata),")
    o.append("    .io_releaseViolationMmask (vioMmask)")
    o.append("  );")
    o.append("")
    for j in range(NUM_ENTRIES):
        o.append("  assign io_releaseMmask_%d_%d = releaseMmask[%d];" % (RELEASE_PORT, j, j))
    for c in range(NUM_VIO):
        for j in range(NUM_ENTRIES):
            o.append("  assign io_releaseViolationMmask_%d_%d = vioMmask[%d][%d];" % (c, j, c, j))
    o.append("endmodule")
    return "\n".join(o)


# ---------------------------------------------------------------------------
#  LoadQueueRAR
# ---------------------------------------------------------------------------
LQRAR = os.path.join(RTL, "LoadQueueRAR.sv")
LD_W = 3

# golden 端口名（下标位置换成 N）-> 核侧表达式模板（{n} = 下标）。
LQRAR_PORT_MAP = [
    ("io_redirect_valid",                        "redirect.valid"),
    ("io_redirect_bits_robIdx_flag",             "redirect.robIdx.flag"),
    ("io_redirect_bits_robIdx_value",            "redirect.robIdx.value"),
    ("io_redirect_bits_level",                   "redirect.level"),
    ("io_query_N_req_ready",                     "query_ready[{n}]"),
    ("io_query_N_req_valid",                     "query_req[{n}].valid"),
    ("io_query_N_req_bits_uop_robIdx_flag",      "query_req[{n}].robIdx.flag"),
    ("io_query_N_req_bits_uop_robIdx_value",     "query_req[{n}].robIdx.value"),
    ("io_query_N_req_bits_uop_lqIdx_flag",       "query_req[{n}].lqIdx.flag"),
    ("io_query_N_req_bits_uop_lqIdx_value",      "query_req[{n}].lqIdx.value"),
    ("io_query_N_req_bits_paddr",                "query_req[{n}].paddr"),
    ("io_query_N_req_bits_data_valid",           "query_req[{n}].data_valid"),
    ("io_query_N_req_bits_is_nc",                "query_req[{n}].is_nc"),
    ("io_query_N_resp_valid",                    "query_resp_valid[{n}]"),
    ("io_query_N_resp_bits_rep_frm_fetch",       "query_resp_rep_frm_fetch[{n}]"),
    ("io_query_N_revoke",                        "query_revoke[{n}]"),
    ("io_release_valid",                         "releaseIn.valid"),
    ("io_release_bits_paddr",                    "releaseIn.paddr"),
    ("io_ldWbPtr_flag",                          "ldWbPtr.flag"),
    ("io_ldWbPtr_value",                         "ldWbPtr.value"),
]
# 这几个端口直接接到核的同名端口，不经结构体
LQRAR_DIRECT = {"clock", "reset", "io_lqFull", "io_perf_0_value", "io_perf_1_value"}


def lqrar_map_ports(ports):
    """[(dir, 端口名, 核侧表达式)]；逐条 fail-closed 核对。"""
    rules = [(re.compile("^" + pat.replace("_N_", r"_(\d+)_") + "$"), tmpl, pat)
             for pat, tmpl in LQRAR_PORT_MAP]
    used = set()
    out = []
    for d, _, name, _ in ports:
        if name in LQRAR_DIRECT:
            out.append((d, name, None))
            continue
        hits = [(r, t, p) for r, t, p in rules if r.match(name)]
        if len(hits) != 1:
            raise SystemExit("gen_lqrar: LoadQueueRAR 端口 %s 命中 %d 条规则（必须恰好 1 条）"
                             % (name, len(hits)))
        r, t, p = hits[0]
        m = r.match(name)
        n = m.group(1) if m.groups() else None
        used.add(p)
        out.append((d, name, t.format(n=n)))
    unused = [p for p, _ in LQRAR_PORT_MAP if p not in used]
    if unused:
        raise SystemExit("gen_lqrar: 映射规则没有命中任何 golden 端口（写错了？）: %s" % unused)
    return out


def gen_lqrar_wrapper():
    ports = port_table("LoadQueueRAR")
    mapped = lqrar_map_ports(ports)
    o = []
    o.append("module LoadQueueRAR")
    o.append("  import loadqueuerar_pkg::*;")
    o.append("(")
    for i, (_, _, _, raw) in enumerate(ports):
        o.append(raw + ("," if i + 1 < len(ports) else ""))
    o.append(");")
    o.append("  // golden 的端口是 firtool 完全展平的标量；这里按语义重新装成结构体交给可读核。")
    o.append("  redirect_t              redirect;")
    o.append("  query_req_t [LD_W-1:0]  query_req;")
    o.append("  logic       [LD_W-1:0]  query_ready;")
    o.append("  logic       [LD_W-1:0]  query_resp_valid;")
    o.append("  logic       [LD_W-1:0]  query_resp_rep_frm_fetch;")
    o.append("  logic       [LD_W-1:0]  query_revoke;")
    o.append("  release_t               releaseIn;  // `release` 是 SV 关键字")
    o.append("  lq_ptr_t                ldWbPtr;")
    o.append("")
    for d, name, expr in mapped:
        if expr is None:
            continue
        if d == "input":
            o.append("  assign %s = %s;" % (expr, name))
        else:
            o.append("  assign %s = %s;" % (name, expr))
    o.append("")
    o.append("  xs_LoadQueueRAR_core u_core (")
    conns = [("clock", "clock"), ("reset", "reset"),
             ("io_redirect", "redirect"),
             ("io_query_req", "query_req"),
             ("io_query_req_ready", "query_ready"),
             ("io_query_resp_valid", "query_resp_valid"),
             ("io_query_resp_rep_frm_fetch", "query_resp_rep_frm_fetch"),
             ("io_query_revoke", "query_revoke"),
             ("io_release", "releaseIn"),
             ("io_ldWbPtr", "ldWbPtr"),
             ("io_lqFull", "io_lqFull"),
             ("io_perf_0_value", "io_perf_0_value"),
             ("io_perf_1_value", "io_perf_1_value")]
    for i, (f, a) in enumerate(conns):
        o.append("    .%-27s (%s)%s" % (f, a, "," if i + 1 < len(conns) else ""))
    o.append("  );")
    o.append("endmodule")
    return "\n".join(o)


def gen_lqrar_cam_inst():
    """核内 CAM 阵列 LqPAddrModule 的例化：端口名逐个取 golden 子模块端口表。"""
    ports = port_table("LqPAddrModule")
    conns = []
    for d, _, name, _ in ports:
        m = re.match(r"^io_(wen|waddr|wdata|releaseViolationMdata)_(\d+)$", name)
        mr = re.match(r"^io_releaseMdata_(\d+)$", name)
        mm = re.match(r"^io_releaseMmask_(\d+)_(\d+)$", name)
        mv = re.match(r"^io_releaseViolationMmask_(\d+)_(\d+)$", name)
        if name in ("clock", "reset"):
            conns.append((name, name))
        elif m:
            k, i = m.group(1), m.group(2)
            expr = {"wen": "acceptedVec[{i}]", "waddr": "enqIndexVec[{i}]",
                    "wdata": "reqPartialPAddr[{i}]",
                    "releaseViolationMdata": "reqPartialPAddr[{i}]"}[k]
            conns.append((name, expr.format(i=i)))
        elif mr:
            conns.append((name, "releasePartialPAddr"))
        elif mm:
            conns.append((name, "releaseMatch[%s]" % mm.group(2)))
        elif mv:
            conns.append((name, "releaseViolationMatch[%s][%s]" % (mv.group(1), mv.group(2))))
        else:
            raise SystemExit("gen_lqrar: LqPAddrModule 端口 %s 无接线规则" % name)
    o = ["  LqPAddrModule paddrModule ("]
    for i, (n, e) in enumerate(conns):
        o.append("    .%-32s (%s)%s" % (n, e, "," if i + 1 < len(conns) else ""))
    o.append("  );")
    return "\n".join(o)


def replace_region(text, tag, body):
    begin = "// BEGIN GENERATED(%s)" % tag
    end = "// END GENERATED"
    i = text.index(begin)
    j = text.index(end, i)
    line_start = text.rfind("\n", 0, i) + 1
    indent = text[line_start:i]
    return text[:i] + begin + "\n" + body + "\n" + indent + end + text[j + len(end):]


# ---------------------------------------------------------------------------
#  LoadQueueRAR 的 FM「匹配前」钉点（verif/ut/LoadQueueRAR/fm_pins_pre.tcl）
# ---------------------------------------------------------------------------
# golden 顶层寄存器是 firtool 的扁平名（uop_17_robIdx_value、ldLdViolationMask_2_40、
# REG_33 …），重写核是按字段的数组（u_core/uop_robIdx_value_reg[17]、
# u_core/ldLdViolationMask_reg[2][40]、u_core/releaseHit_q_reg[33] …）。
# 同簇 LoadQueueRAW 实测：不钉时 FM Matching 45 分钟不出来。钉点只消名差：告诉 FM
# "这两个点是同一个点"，比较照比，不约束 ref、不放宽任何判据。
# 映射由下表机械给出，每个 golden 寄存器必须恰好命中一条规则（fail-closed）。
def lqrar_pin_target(name):
    """golden 顶层寄存器名 -> 重写核里的寄存器（数组表达式或标量名，不含 _reg 后缀）。"""
    rules = [
        (r"allocated_(\d+)", lambda m: "allocated[%s]" % m[1]),
        (r"released_(\d+)", lambda m: "released[%s]" % m[1]),
        (r"uop_(\d+)_(robIdx_flag|robIdx_value|lqIdx_flag|lqIdx_value)",
         lambda m: "uop_%s[%s]" % (m[2], m[1])),
        (r"lastCanAccept_next_nextVec_(\d)_r", lambda m: "lastCanAccept[%s]" % m[1]),
        (r"lastAllocIndex_next_nextVec_(\d)_r", lambda m: "lastAllocIndex[%s]" % m[1]),
        (r"ldLdViolationMask_(\d)_(\d+)", lambda m: "ldLdViolationMask[%s][%s]" % (m[1], m[2])),
        # REG / REG_<i>：RegNext(releaseMmask(i) && allocated(i) && release.valid)，i=0 无后缀
        (r"REG(?:_(\d+))?", lambda m: "releaseHit_q[%d]" % int(m[1] or 0)),
        (r"release2Cycle_valid", lambda m: "release2Cycle_valid"),
        (r"release2Cycle_valid_REG", lambda m: "release2Cycle_valid_REG"),
        (r"release2Cycle_bits_paddr", lambda m: "release2Cycle_bits_paddr"),
        (r"io_query_(\d)_resp_valid_REG", lambda m: "respValid_q[%s]" % m[1]),
        (r"io_perf_0_value_REG(?:_(1))?", lambda m: "perfEnq_q[%d]" % int(m[1] or 0)),
        (r"io_perf_1_value_REG(?:_(1))?", lambda m: "perfVio_q[%d]" % int(m[1] or 0)),
    ]
    hits = []
    for pat, fn in rules:
        m = re.fullmatch(pat, name)
        if m:
            hits.append(fn(m))
    if len(hits) != 1:
        raise SystemExit("gen_lqrar: 钉点规则对 golden 寄存器 %s 命中 %d 条（必须恰好 1）" % (name, len(hits)))
    return hits[0]


def golden_top_regs(module):
    t = open(os.path.join(GOLDEN_DIR, module + ".sv")).read()
    body = t[t.index("module %s(" % module):]
    body = body[:body.index("\nendmodule")]
    body = re.sub(r"reg\s+(\[\d+:\d+\])\s*\n\s*", r"reg \1 ", body)  # 折行的声明
    out = []
    for a, b, n in re.findall(r"^\s*reg\s+(?:\[(\d+):(\d+)\]\s+)?(\w+);", body, re.M):
        out.append((n, int(a) - int(b) + 1 if a else 1))
    return out


def impl_path(tgt):
    """'arr[1][2]' -> 'arr_reg\\[1\\]\\[2\\]'；标量 'x' -> 'x_reg'（tcl 转义方括号）。"""
    if "[" not in tgt:
        return tgt + "_reg"
    arr, idx = tgt.split("[", 1)
    return arr + "_reg\\[" + idx.replace("][", "\\]\\[")[:-1] + "\\]"


def gen_lqrar_pins():
    regs = golden_top_regs("LoadQueueRAR")
    total = sum(w for _, w in regs)
    seen = set()
    o = []
    o.append("# LoadQueueRAR FM「匹配前」钉点 —— 自动生成：scripts/gen_lqrar.py（勿手改）")
    o.append("#")
    o.append("# 只消 golden 扁平寄存器名与重写核按字段数组名之间的命名鸿沟（依据见生成器注释）。")
    o.append("# set_user_match 只是声明两点对应，比较照比：不约束 ref、不改 appvar、不加黑盒。")
    o.append("# fail-closed：set_user_match 从不抛异常（返回 0 = 没配上），所以逐条数返回值；")
    o.append("# 拒一条或总数不等于字面整数（= golden 顶层寄存器位数）就 error（safe interp 里不用 exit）。")
    o.append("# 子模块（paddrModule / freeList 及其延迟件）内部不钉，交给 FM 自动配对。")
    o.append("# 进 fm.log 的输出一律 ASCII。")
    o.append("set ::LQRAR_PIN_EXPECT %d" % total)
    o.append("set ::LQRAR_PIN_OK 0")
    o.append("set ::LQRAR_PIN_BAD 0")
    o.append("proc lqrar_pin {g i w} {")
    o.append("  if {$w == 1} {")
    o.append("    set pairs [list \"r:/WORK/LoadQueueRAR/${g}_reg\" \"i:/WORK/LoadQueueRAR/u_core/${i}\"]")
    o.append("  } else {")
    o.append("    set pairs {}")
    o.append("    for {set b 0} {$b < $w} {incr b} {")
    o.append("      lappend pairs \"r:/WORK/LoadQueueRAR/${g}_reg\\[$b\\]\" \"i:/WORK/LoadQueueRAR/u_core/${i}\\[$b\\]\"")
    o.append("    }")
    o.append("  }")
    o.append("  foreach {r m} $pairs {")
    o.append("    if {[set_user_match $r $m]} { incr ::LQRAR_PIN_OK } else {")
    o.append("      incr ::LQRAR_PIN_BAD")
    o.append("      if {$::LQRAR_PIN_BAD <= 10} { puts \"LQRAR_PIN_FAIL: $r <-> $m\" }")
    o.append("    }")
    o.append("  }")
    o.append("}")
    o.append("puts \"LQRAR_PIN_BEGIN LoadQueueRAR expect=$::LQRAR_PIN_EXPECT\"")
    for n, w in regs:
        tgt = lqrar_pin_target(n)
        if tgt in seen:
            raise SystemExit("gen_lqrar: 两个 golden 寄存器映射到同一个重写寄存器 %s（不是双射）" % tgt)
        seen.add(tgt)
        o.append("lqrar_pin %s %s %d" % (n, impl_path(tgt), w))
    o.append("puts \"LQRAR_PIN_END LoadQueueRAR ok=$::LQRAR_PIN_OK bad=$::LQRAR_PIN_BAD\"")
    o.append("if {$::LQRAR_PIN_BAD != 0} { error \"LQRAR_PIN_MISS=$::LQRAR_PIN_BAD\" }")
    o.append("if {$::LQRAR_PIN_OK != %d} { error \"LQRAR_PIN_COUNT=$::LQRAR_PIN_OK expect=%d\" }"
             % (total, total))
    return "\n".join(o) + "\n"


LQRAR_PINS = os.path.normpath(os.path.join(HERE, "..", "verif", "ut", "LoadQueueRAR", "fm_pins_pre.tcl"))


def targets():
    out = {}
    text = open(LQPADDR).read()
    out[LQPADDR] = replace_region(text, "lqpaddr-wrapper", gen_lqpaddr_wrapper())
    text = open(LQRAR).read()
    text = replace_region(text, "lqrar-cam-inst", gen_lqrar_cam_inst())
    text = replace_region(text, "lqrar-wrapper", gen_lqrar_wrapper())
    out[LQRAR] = text
    out[LQRAR_PINS] = gen_lqrar_pins()
    return out


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--check", action="store_true", help="只比对不写，有漂移 rc=1")
    args = ap.parse_args()
    drift = 0
    for path, text in targets().items():
        cur = open(path).read() if os.path.exists(path) else None
        if cur == text:
            print("gen_lqrar: OK     %s" % os.path.relpath(path))
            continue
        if args.check:
            print("gen_lqrar: DRIFT  %s" % os.path.relpath(path))
            drift += 1
        else:
            os.makedirs(os.path.dirname(path), exist_ok=True)
            with open(path, "w") as f:
                f.write(text)
            print("gen_lqrar: WROTE  %s" % os.path.relpath(path))
    return 1 if drift else 0


if __name__ == "__main__":
    sys.exit(main())
