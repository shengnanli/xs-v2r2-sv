#!/usr/bin/env python3
"""
L2TLB（共享 MMU 顶层集成）机械派生区生成器 —— 本轮单文件规范版。

本层是 **仲裁 / 路由 / 分发 / 访存数据通路的 glue**；页表遍历算法在各子模块内。
设计意图来源：src/main/scala/xiangshan/cache/mmu/L2TLB.scala 的 class L2TLBImp。

本脚本只生成 rtl/memblock/L2TLB.sv 里的 **机械派生区**（不含任何逻辑），
用 `// BEGIN GENERATED(<tag>)` / `// END GENERATED` 原地替换，手写区绝不触碰：

  ports   核 xs_L2TLB_core 的扁平端口表（与 golden L2TLB 逐位同名，376 个）
  wires   各子模块输出网声明（可读名 = <可读实例名>_<端口尾巴>）
  driven  核必须手写驱动的 glue 输入网声明
  inst    全部子模块实例的端口连接表
  wrapper module L2TLB 的端口表与到 u_core 的直通连接

用法: python3 scripts/gen_l2tlb.py [--check]
  --check  只校验磁盘内容与重新生成的一致（gate 用），不写文件。
"""
import re, sys
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
GOLDEN = Path("/home/eda/xs-env/G1-canonical/golden-rtl")
TARGET = REPO / "rtl/memblock/L2TLB.sv"
GSV = (GOLDEN / "L2TLB.sv").read_text()
LINES = GSV.splitlines()

# (golden 模块名, golden 实例名, 可读实例名) —— 可读名用领域词汇，便于阅读与层次探针。
INSTANCES = [
    ("DelayN_220",  "sfence_tmp_delay", "u_sfence_delay"),   # sfence 打拍（复制扇出源）
    ("DelayN_221",  "csr_tmp_delay",    "u_csr_delay"),       # CSR 打拍（复制扇出源）
    ("PMP",         "pmp",              "u_pmp"),             # PMP/PMA 表体
    ("PMPChecker",  "PMPChecker",       "u_pmp_chk_ptw"),     # PTW 访存检查
    ("PMPChecker",  "PMPChecker_1",     "u_pmp_chk_llptw0"),  # LLPTW 访存检查（口 0）
    ("PMPChecker",  "PMPChecker_2",     "u_pmp_chk_llptw1"),  # LLPTW 访存检查（口 1，G1 新增）
    ("PMPChecker",  "PMPChecker_3",     "u_pmp_chk_hptw"),    # HPTW 访存检查
    ("PMPChecker",  "PMPChecker_4",     "u_pmp_chk_bitmap"),  # Bitmap 访存检查（G1 新增）
    ("Bitmap",      "bitmap",           "u_bitmap"),          # G1 新增：PTE bitmap 检查引擎
    ("BitmapCache", "bitmapcache",      "u_bitmap_cache"),    # G1 新增：bitmap 行缓存
    ("L2TlbMissQueue", "missQueue",     "u_miss_queue"),
    ("PtwCache",    "cache",            "u_page_cache"),
    ("PTW",         "ptw",              "u_ptw"),
    ("HPTW",        "hptw",             "u_hptw"),
    ("LLPTW",       "llptw",            "u_llptw"),
    ("Arbiter2_PtwReq", "arb1",         "u_arb_tlb"),         # ITLB/DTLB 请求仲裁
    ("Arbiter5_L2TlbWithHptwIdBundle", "arb2", "u_arb_cache_in"),  # page cache 入口仲裁
    ("Arbiter2_L2TLBImp_Anon",   "hptw_req_arb",  "u_arb_hptw_req"),
    ("Arbiter2_L2TLBImp_Anon_1", "hptw_resp_arb", "u_arb_hptw_resp"),
    ("Arbiter1_L2TLBImp_Anon", "Arbiter1_L2TLBImp_Anon",   "u_out_arb_0"),
    ("Arbiter1_L2TLBImp_Anon", "Arbiter1_L2TLBImp_Anon_1", "u_out_arb_1"),
    ("Arbiter3_L2TLBImp_Anon", "Arbiter3_L2TLBImp_Anon",   "u_merge_arb_0"),
    ("Arbiter3_L2TLBImp_Anon", "Arbiter3_L2TLBImp_Anon_1", "u_merge_arb_1"),
    ("L2TlbPrefetch", "prefetch",       "u_prefetch"),
    ("Arbiter2_L2TlbWithHptwIdBundle", "mq_arb", "u_arb_mq"),
    ("DelayN_13",   "wfiReq_delay",         "u_wfi_req_delay"),
    ("DelayN_13",   "io_wfi_wfiSafe_delay", "u_wfi_safe_delay"),
    ("Arbiter4_L2TlbMemReqBundle", "mem_arb", "u_mem_arb"),        # G1: 3→4 路（+bitmap）
    ("Arbiter3_bitmapReqBundle", "bitmap_arb", "u_bitmap_arb"),    # G1 新增
]
GOLD2READ = {g: r for _, g, r in INSTANCES}

PORT_RE = re.compile(r"\s*(input|output)\s+(?:\[(\d+):0\])?\s*(\w+),?\s*$")


def parse_ports(text, mod):
    m = re.search(rf"^module {re.escape(mod)}\((.*?)\n\);", text, re.S | re.M)
    out = []
    for line in m.group(1).splitlines():
        pm = PORT_RE.match(line)
        if pm:
            out.append((pm.group(1), int(pm.group(2)) + 1 if pm.group(2) else 1, pm.group(3)))
    return out


TOP_PORTS = parse_ports(GSV, "L2TLB")
_dirs_cache = {}


def port_dirs(mod):
    if mod not in _dirs_cache:
        t = (GOLDEN / f"{mod}.sv").read_text()
        _dirs_cache[mod] = {n: (d, w) for d, w, n in parse_ports(t, mod)}
    return _dirs_cache[mod]


def inst_conns(inst_name):
    """解析实例端口连接，RHS 可跨多行。返回 [(port, rhs_单行化), ...]"""
    start = next(i for i, l in enumerate(LINES)
                 if re.match(rf"^  [A-Za-z_]\w* {re.escape(inst_name)} \($", l))
    i, raw = start + 1, []
    while not re.match(r"^  \);", LINES[i]):
        raw.append(LINES[i]); i += 1
    res, cur = [], None
    for l in raw:
        m = re.match(r"^\s*\.(\w+)\s*(.*)$", l)
        if m and (m.group(2).strip() == "" or m.group(2).strip().startswith("(")):
            if cur: res.append(cur)
            cur = [m.group(1), m.group(2).strip()]
        elif cur is not None:
            cur[1] += " " + l.strip()
    if cur: res.append(cur)
    out = []
    for p, v in res:
        v = re.sub(r"\s+", " ", v).strip().rstrip(",")
        if v.startswith("(") and v.endswith(")"):
            v = v[1:-1].strip()
        out.append((p, v))
    return out


def rename_net(expr):
    """_<goldinst>_io_X -> <可读实例名>_X；其余（顶层端口/常量/表达式）原样。"""
    def repl(m):
        gold, rest = m.group(1), m.group(2)
        return f"{GOLD2READ[gold]}_{rest}" if gold in GOLD2READ else m.group(0)
    return re.sub(r"_([A-Za-z]\w*)_io_(\w+)", repl, expr)


def out_net_name(read, port):
    return f"{read}_{port[3:]}" if port.startswith("io_") else f"{read}_{port}"


TOPSET = {n for _, _, n in TOP_PORTS} | {"clock", "reset"}
OUTNETS = {}   # 可读输出网名 -> 位宽
for _m, _g, _r in INSTANCES:
    for p, (d, w) in port_dirs(_m).items():
        if d == "output":
            OUTNETS[out_net_name(_r, p)] = w

DRIVEN = {}
CONST_RE = re.compile(r"^(\d+'[hbodHBOD][0-9a-fA-FxzXZ_]+|\d+)$")


def emit_inst(mod, gold, read):
    body = []
    dirs = port_dirs(mod)
    for port, rhs in inst_conns(gold):
        if port in ("clock", "reset"):
            body.append(f"    .{port:<32}({port})"); continue
        d, w = dirs.get(port, ("input", 1))
        if d == "output":
            body.append(f"    .{port:<32}({rename_net(rhs)})"); continue
        if re.fullmatch(r"\w+", rhs) and rhs in TOPSET:
            body.append(f"    .{port:<32}({rhs})"); continue
        if CONST_RE.match(rhs):
            body.append(f"    .{port:<32}({rhs})"); continue
        rn = rename_net(rhs)
        if re.fullmatch(r"\w+", rn) and rn in OUTNETS:
            body.append(f"    .{port:<32}({rn})"); continue
        tail = port[3:] if port.startswith("io_") else port
        sig = f"{read}__{tail}"
        DRIVEN[sig] = w
        body.append(f"    .{port:<32}({sig})")
    return f"  {mod} {read} (\n" + ",\n".join(body) + "\n  );"


def decl(kw, w, name):
    return f"  {kw} {'[%d:0] ' % (w - 1) if w > 1 else ''}{name};"


def build():
    insts = [emit_inst(m, g, r) for m, g, r in INSTANCES]   # 先跑，填充 DRIVEN
    secs = {}

    secs["ports"] = "\n".join(
        f"  {d} {'[%d:0] ' % (w - 1) if w > 1 else ''}{n}," for d, w, n in TOP_PORTS).rstrip(",")

    secs["wires"] = "\n".join(decl("wire", OUTNETS[n], n) for n in sorted(OUTNETS))

    secs["driven"] = "\n".join(decl("logic", DRIVEN[n], n) for n in sorted(DRIVEN))

    secs["inst"] = "\n\n".join(insts)

    wp = "\n".join(f"  {d} {'[%d:0] ' % (w - 1) if w > 1 else ''}{n}," for d, w, n in TOP_PORTS).rstrip(",")
    conn = ",\n".join(f"    .{n:<40}({n})" for _, _, n in TOP_PORTS)
    secs["wrapper"] = wp + "\n);\n\n  xs_L2TLB_core u_core (\n" + conn + "\n  );"
    return secs


BEGIN = "// BEGIN GENERATED({})"
END = "// END GENERATED"


def splice(text, secs):
    for tag, body in secs.items():
        pat = re.compile(re.escape(BEGIN.format(tag)) + r".*?" + re.escape(END), re.S)
        if not pat.search(text):
            sys.exit(f"ERROR: 找不到生成区标记 {BEGIN.format(tag)} ... {END}")
        text = pat.sub(lambda _m: BEGIN.format(tag) + "\n" + body + "\n  " + END, text, count=1)
    return text


if __name__ == "__main__":
    secs = build()
    check = "--check" in sys.argv
    if not TARGET.exists():
        if check: sys.exit(f"ERROR: {TARGET} 不存在")
        sys.exit(f"ERROR: {TARGET} 不存在；先写手写骨架（含 5 个生成区标记）再跑本脚本")
    cur = TARGET.read_text()
    new = splice(cur, secs)
    if check:
        sys.exit(0 if new == cur else "ERROR: L2TLB.sv 生成区与 gen_l2tlb.py 输出不一致，请重跑生成器")
    TARGET.write_text(new)
    print(f"ports={len(TOP_PORTS)} instances={len(INSTANCES)} "
          f"out_nets={len(OUTNETS)} driven={len(DRIVEN)}")
