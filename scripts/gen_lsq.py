#!/usr/bin/env python3
"""gen_lsq.py —— LoadQueue / LsqWrapper 两个装配层的机械派生区生成器（lane lsq）。

两个目标都是"几个已签核子队列 + 一点胶水"。胶水核（xs_LoadQueue_core / xs_LsqWrapper_core）
是手写的；本脚本只产出没有微架构的部分：

  rtl/memblock/LoadQueue.sv   GENERATED(loadqueue-ports) / GENERATED(loadqueue-body)
  rtl/memblock/LsqWrapper.sv  GENERATED(lsqwrapper-ports) / GENERATED(lsqwrapper-body)
      端口表：逐字取 G1 golden；
      body：子队列输出线声明 → 胶水核例化 → 子队列例化（实例名、端口顺序同 golden）→ 输出 assign。
  verif/ut/LoadQueue/fm_pins_pre.tcl、verif/ut/LsqWrapper/fm_pins_pre.tcl
      FM「匹配前」钉点 = 本层胶水寄存器（逐位写死）+ 各子队列自己那份已签核钉点（原样收割、
      把 r:/WORK/<子模块>/ 与 i:/WORK/<子模块>/ 换成 <本层>/<实例名>/）。

★连线规则（每个子模块端口恰好命中一条，fail-closed）★
  (a) golden 接的是本层端口名             → 原样接同名端口；
  (b) golden 接的是 _<实例>_io_<端口> 线   → 接 <简称>_<端口去 io_>（该实例的输出线）；
      自己的输出端口必须恰好接自己的线（名字逐字核对）；
  (c) 其余（表达式 / 常数 / golden 的 _GEN_ 线）→ 必须出现在 GLUE_IN 表里，
      表里逐字记着 golden 的表达式（空白归一后比较），改接到胶水核的一个输出上。
  本层输出：golden `assign io_x = _<实例>_io_<y>` → 生成同形 assign；其余必须在 GLUE_OUT 表里
  （同样逐字记 golden 表达式）。
  总核对：每个本层输出恰好被驱动一次、每个本层输入至少被用到一次、GLUE 表每条都被用到。

用法:
  scripts/gen_lsq.py            # 写文件（内容不变不写，幂等）
  scripts/gen_lsq.py --check    # 只比对；有漂移 rc=1
"""
import argparse
import os
import re
import subprocess
import sys
import tempfile

GOLDEN_DIR = os.environ.get("GOLDEN_RTL", "/home/eda/xs-env/G1-canonical/golden-rtl")
HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.normpath(os.path.join(HERE, ".."))
RTL = os.path.join(REPO, "rtl", "memblock")

PORT_RE = re.compile(r"\s*(input|output)\s+(?:\[(\d+):(\d+)\]\s*)?([A-Za-z_]\w*)\s*,?\s*$")
IDENT_RE = re.compile(r"^[A-Za-z_]\w*$")


def die(msg):
    raise SystemExit("gen_lsq: ERROR: " + msg)


def norm(s):
    return re.sub(r"\s+", " ", s).strip()


# ---------------------------------------------------------------------------
#  golden 解析
# ---------------------------------------------------------------------------
_cache = {}


def golden_text(module):
    if module not in _cache:
        t = open(os.path.join(GOLDEN_DIR, module + ".sv")).read()
        i = t.index("\nmodule %s(" % module) + 1
        _cache[module] = t[i:t.index("\nendmodule", i)]
    return _cache[module]


def port_table(module):
    """[(dir, width, name, 原文行去逗号)]，顺序即 golden 顺序。"""
    lines = golden_text(module).split("\n")
    end = next(i for i, l in enumerate(lines) if l.startswith(");"))
    out = []
    for l in lines[1:end]:
        m = PORT_RE.match(l)
        if not m:
            die("%s 端口行解析失败: %r" % (module, l))
        w = int(m.group(2)) - int(m.group(3)) + 1 if m.group(2) else 1
        out.append((m.group(1), w, m.group(4), l.rstrip().rstrip(",")))
    return out


def port_block(module):
    ps = port_table(module)
    return "\n".join(p[3] + ("," if i + 1 < len(ps) else "") for i, p in enumerate(ps))


def instances(module):
    """[(子模块, 实例名, [(端口, golden 表达式)])]，顺序即 golden 顺序。"""
    body = golden_text(module)
    out = []
    for m in re.finditer(r"\n  ([A-Za-z_]\w*) ([A-Za-z_]\w*) \((.*?)\n  \);", body, re.S):
        conns = re.findall(r"\.(\w+)\s*\(([^()]*(?:\([^()]*\)[^()]*)*)\)", m.group(3), re.S)
        out.append((m.group(1), m.group(2), [(p, norm(e)) for p, e in conns]))
    return out


def top_assigns(module):
    """golden 顶层 `assign io_x = ...;` → {io_x: 表达式}（只收本层输出端口）。"""
    outs = {n for d, w, n, _ in port_table(module) if d == "output"}
    res = {}
    for m in re.finditer(r"\n  assign (\w+) =(.*?);", golden_text(module), re.S):
        if m.group(1) in outs:
            if m.group(1) in res:
                die("%s 输出 %s 被 assign 两次" % (module, m.group(1)))
            res[m.group(1)] = norm(m.group(2))
    return res


def struct_fields(path, tname):
    """从重写文件的 package 里读 typedef struct packed {...} tname; 的 [(字段, 位宽)]。"""
    txt = open(os.path.join(REPO, path)).read()
    m = re.search(r"typedef struct packed \{([^{}]*)\} %s;" % tname, txt, re.S)
    if not m:
        die("%s 里找不到 struct %s" % (path, tname))
    out = []
    for a, b, f in re.findall(r"logic\s+(?:\[(\d+):(\d+)\]\s+)?(\w+);", m.group(1)):
        out.append((f, int(a) - int(b) + 1 if a else 1))
    return out


def rng(w):
    return "[%d:0] " % (w - 1) if w > 1 else ""


def wrap_list(head, items, tail, width=100):
    """items 用逗号连成一串，超过 width 折行，续行与首项对齐。"""
    lines, cur, pad = [], head, " " * len(head)
    for i, it in enumerate(items):
        piece = it + ("," if i + 1 < len(items) else tail)
        if cur != head and len(cur) + 1 + len(piece) > width:
            lines.append(cur.rstrip())
            cur = pad + piece
        else:
            cur = cur + ("" if cur == head else " ") + piece
    lines.append(cur)
    return lines


def replace_region(text, tag, body):
    begin = "// BEGIN GENERATED(%s)" % tag
    end = "// END GENERATED"
    i = text.index(begin)
    j = text.index(end, i)
    line_start = text.rfind("\n", 0, i) + 1
    indent = text[line_start:i]
    return text[:i] + begin + "\n" + body + "\n" + indent + end + text[j + len(end):]


# ---------------------------------------------------------------------------
#  通用装配生成
# ---------------------------------------------------------------------------
class Assembly:
    """spec 字段：
       top        golden 模块名
       alias      {实例名: 简称}（子模块输出线前缀）
       core       胶水核模块名
       core_conns [(核端口, 连法)]，连法：
                    str                     —— 一个信号（本层端口 / 子模块输出线 / 核输出线）
                    list[str]               —— 打包向量，元素 0 在前（生成时反序拼接）
                    ("out", 声明, 线名)     —— 核输出：在 wrapper 里声明 `logic <声明> 线名;`
                    ("in_struct", 类型, [(字段, 信号)])  —— 先 assign 进 wrapper 里的结构体线
                    ("out_struct", 类型, 线名)          —— 核输出一个结构体线
       glue_in    {(实例, 端口): (golden 表达式, 新接法)}
       glue_out   {输出端口: (golden 表达式, 新接法)}
       unused_in  golden 里有端口、但本层谁都不读的输入（逐个写明；生成时核对 golden 里确实只出现在端口表）
    """

    def __init__(self, spec):
        self.s = spec
        self.top = spec["top"]
        self.ports = port_table(self.top)
        self.pdir = {n: (d, w) for d, w, n, _ in self.ports}
        self.insts = instances(self.top)
        self.child_ports = {inst: {n: (d, w) for d, w, n, _ in port_table(mod)}
                            for mod, inst, _ in self.insts}
        got = {inst for _, inst, _ in self.insts}
        if got != set(spec["alias"]):
            die("%s 实例集合 golden=%s spec=%s" % (self.top, sorted(got), sorted(spec["alias"])))

    def wire_name(self, inst, port):
        rest = port[3:] if port.startswith("io_") else port
        return "%s_%s" % (self.s["alias"][inst], rest)

    def golden_wire(self, expr):
        """_<实例>_io_x -> (实例, io_x)；不是就 None。"""
        m = re.fullmatch(r"_([A-Za-z]\w*?)_(io_\w+)", expr)
        if m and m.group(1) in self.child_ports and m.group(2) in self.child_ports[m.group(1)]:
            return m.group(1), m.group(2)
        return None

    def build(self):
        used_in = set()
        driven = {}
        glue_in_used = set()
        wires = {}           # 线名 -> 宽度（子模块输出线）
        inst_blocks = []
        for mod, inst, conns in self.insts:
            cp = self.child_ports[inst]
            if [p for p, _ in conns] != [n for d, w, n, _ in port_table(mod)]:
                die("%s.%s 连线端口顺序/集合与 %s 端口表不一致" % (self.top, inst, mod))
            lines = []
            for p, e in conns:
                d, w = cp[p]
                key = (inst, p)
                if key in self.s["glue_in"]:
                    ge, new = self.s["glue_in"][key]
                    if norm(ge) != e:
                        die("%s.%s.%s golden 表达式漂了：表=%r golden=%r" % (self.top, inst, p, ge, e))
                    if d != "input":
                        die("GLUE_IN %s.%s 不是输入" % (inst, p))
                    glue_in_used.add(key)
                    sig = new
                elif IDENT_RE.match(e) and e in self.pdir:
                    td, tw = self.pdir[e]
                    if tw != w:
                        die("%s.%s.%s 位宽 %d 与本层端口 %s 位宽 %d 不符" % (self.top, inst, p, w, e, tw))
                    if d == "output":
                        if td != "output":
                            die("%s.%s.%s 输出接到了本层输入 %s" % (self.top, inst, p, e))
                        if e in driven:
                            die("本层输出 %s 被驱动两次" % e)
                        driven[e] = "%s.%s" % (inst, p)
                    else:
                        used_in.add(e)
                    sig = e
                elif self.golden_wire(e):
                    wi, wp = self.golden_wire(e)
                    if d == "output":
                        if (wi, wp) != (inst, p):
                            die("%s.%s.%s 输出接的线 %s 不是它自己的" % (self.top, inst, p, e))
                        wires[self.wire_name(inst, p)] = w
                    else:
                        if self.child_ports[wi][wp] != ("output", w):
                            die("%s.%s.%s 读的 %s 方向/位宽不符" % (self.top, inst, p, e))
                    sig = self.wire_name(wi, wp)
                else:
                    die("%s.%s.%s 的 golden 接法 %r 没有规则（须进 GLUE_IN 表）" % (self.top, inst, p, e))
                lines.append((p, sig))
            width = max(len(p) for p, _ in lines)
            blk = ["  %s %s (" % (mod, inst)]
            for k, (p, sig) in enumerate(lines):
                blk.append("    .%-*s (%s)%s" % (width, p, sig, "," if k + 1 < len(lines) else ""))
            blk.append("  );")
            inst_blocks.append(blk)
        miss = set(self.s["glue_in"]) - glue_in_used
        if miss:
            die("GLUE_IN 有没用到的条目：%s" % sorted(miss))

        # 本层输出
        assigns = []
        ga = top_assigns(self.top)
        glue_out_used = set()
        for d, w, n, _ in self.ports:
            if d != "output" or n in driven:
                if d == "output" and n in ga:
                    die("%s 既由子模块直接驱动又有 golden assign" % n)
                continue
            if n not in ga:
                die("本层输出 %s 在 golden 里既不接子模块也没有 assign" % n)
            if n in self.s["glue_out"]:
                ge, new = self.s["glue_out"][n]
                ms = re.fullmatch(r"(\w+)\.(\w+)", new)
                if ms:
                    tname = next((h[1] for c, h in self.s["core_conns"]
                                  if isinstance(h, tuple) and h[0] == "out_struct" and h[2] == ms.group(1)), None)
                    fw = dict(struct_fields(self.s["pkg_file"], tname))
                    if fw.get(ms.group(2)) != w:
                        die("%s <- %s 位宽不符" % (n, new))
                if norm(ge) != ga[n]:
                    die("GLUE_OUT %s golden 表达式漂了：表=%r golden=%r" % (n, ge, ga[n]))
                glue_out_used.add(n)
                assigns.append("  assign %s = %s;" % (n, new))
            elif self.golden_wire(ga[n]):
                wi, wp = self.golden_wire(ga[n])
                if self.child_ports[wi][wp] != ("output", w):
                    die("%s <- %s 位宽不符" % (n, ga[n]))
                assigns.append("  assign %s = %s;" % (n, self.wire_name(wi, wp)))
            else:
                die("本层输出 %s 的 golden 驱动 %r 没有规则（须进 GLUE_OUT 表）" % (n, ga[n]))
            driven[n] = "assign"
        miss = set(self.s["glue_out"]) - glue_out_used
        if miss:
            die("GLUE_OUT 有没用到的条目：%s" % sorted(miss))

        # 胶水核
        core_decl, core_assign, core_lines = [], [], []
        known = set(wires) | set(self.pdir)
        outs_declared = set()
        for cp, how in self.s["core_conns"]:
            if isinstance(how, tuple) and how[0] in ("out", "out_struct"):
                known.add(how[2])
                outs_declared.add(how[2])

        def chk(sig):
            base = re.match(r"[A-Za-z_]\w*", sig).group(0)
            if base not in known and not re.fullmatch(r"[A-Z_][A-Z0-9_]*", base):
                die("核连线用到未知信号 %s" % sig)
            if base in self.pdir and self.pdir[base][0] == "input":
                used_in.add(base)

        for cp, how in self.s["core_conns"]:
            if isinstance(how, str):
                chk(how)
                core_lines.append((cp, how))
            elif isinstance(how, list):
                for x in how:
                    chk(x)
                core_lines.append((cp, list(reversed(how))))
            elif how[0] == "out":
                core_decl.append("  logic %s %s;" % (how[1], how[2]))
                core_lines.append((cp, how[2]))
            elif how[0] == "out_struct":
                core_decl.append("  %s %s;" % (how[1], how[2]))
                core_lines.append((cp, how[2]))
            elif how[0] == "in_struct":
                sname = "%s_s" % cp
                core_decl.append("  %s %s;" % (how[1], sname))
                fw = struct_fields(self.s["pkg_file"], how[1])
                if [f for f, _ in how[2]] != [f for f, _ in fw]:
                    die("%s 的字段表与包里 %s 的定义不一致" % (cp, how[1]))
                for (f, sig), (_, w) in zip(how[2], fw):
                    chk(sig)
                    sw = wires.get(sig) or (self.pdir[sig][1] if sig in self.pdir else None)
                    if sw is not None and sw != w:
                        die("%s.%s 位宽 %d 与信号 %s 位宽 %d 不符" % (how[1], f, w, sig, sw))
                    core_assign.append("  assign %s.%s = %s;" % (sname, f, sig))
                core_lines.append((cp, sname))
            else:
                die("核连法 %r 不认识" % (how,))
        # GLUE 新接法的基信号（第一个标识符）也必须已知
        for _, new in list(self.s["glue_in"].values()) + list(self.s["glue_out"].values()):
            base = re.match(r"[A-Za-z_]\w*", new).group(0)
            if base not in known:
                die("GLUE 接法 %s 的基信号不是已知信号" % new)

        und = [n for d, w, n, _ in self.ports if d == "output" and n not in driven]
        if und:
            die("本层输出没人驱动：%s" % und[:8])
        unused = [n for d, w, n, _ in self.ports if d == "input" and n not in used_in]
        if set(unused) != set(self.s.get("unused_in", [])):
            die("本层没人用的输入与 spec.unused_in 不一致：实测 %s" % unused)
        # golden 里也确实没人读它们（端口之外不出现）
        for n in unused:
            if len(re.findall(r"\b%s\b" % n, golden_text(self.top))) != 1:
                die("%s 在 golden 里有读者，却被声明为无人使用" % n)

        body = []
        body.append("  // ---- 子模块输出线（<简称>_<端口名去掉 io_>）----")
        for mod, inst, conns in self.insts:
            names = [self.wire_name(inst, p) for p, _ in conns if self.wire_name(inst, p) in wires]
            if not names:
                continue
            body.append("  // %s %s" % (mod, inst))
            for nm in names:
                body.append("  logic %s%s;" % (rng(wires[nm]), nm))
        body.append("")
        body.append("  // ---- 胶水核的输出 / 结构体线 ----")
        body += core_decl
        body += core_assign
        body.append("")
        width = max(len(c) for c, _ in core_lines)
        body.append("  %s u_core (" % self.s["core"])
        for k, (c, sig) in enumerate(core_lines):
            tail = ")" + ("," if k + 1 < len(core_lines) else "")
            head = "    .%-*s (" % (width, c)
            if isinstance(sig, list):   # 打包向量：高位在前拼接，超过 100 列折行
                body += wrap_list(head + "{", sig, "}" + tail)
            else:
                body.append(head + sig + tail)
        body.append("  );")
        for blk in inst_blocks:
            body.append("")
            body += blk
        body.append("")
        body.append("  // ---- 本层输出 ----")
        body += assigns
        return "\n".join(body)


# ---------------------------------------------------------------------------
#  LoadQueue
# ---------------------------------------------------------------------------
LQ_SPEC = {
    "top": "LoadQueue",
    "core": "xs_LoadQueue_core",
    "alias": {"loadQueueRAR": "rar", "loadQueueRAW": "raw", "loadQueueReplay": "replay",
              "virtualLoadQueue": "vlq", "exceptionBuffer": "excbuf", "uncacheBuffer": "uncache"},
    "core_conns": [
        ("clock", "clock"),
        ("ldin_valid", ["io_ldu_ldin_%d_valid" % k for k in range(3)]),
        ("ldin_isvec", ["io_ldu_ldin_%d_bits_isvec" % k for k in range(3)]),
        ("ldin_nc_with_data", ["io_ldu_ldin_%d_bits_nc_with_data" % k for k in range(3)]),
        ("vecfb_valid", ["io_vecFeedback_%d_valid" % k for k in range(2)]),
        ("vecfb_flush", ["io_vecFeedback_%d_bits_feedback_0" % k for k in range(2)]),
        ("excbuf_req_valid", ("out", "[4:0]", "excbuf_req_valid")),
        ("uncache_req_valid", ("out", "[2:0]", "uncache_req_valid")),
        ("child_perf", ["rar_perf_%d_value" % k for k in range(2)]
                       + ["raw_perf_%d_value" % k for k in range(2)]
                       + ["replay_perf_%d_value" % k for k in range(13)]),
        ("rar_full", "rar_lqFull"),
        ("raw_full", "raw_lqFull"),
        ("replay_full", "replay_lqFull"),
        ("nuke_rollback_valid", ["raw_rollback_%d_valid" % k for k in range(2)]),
        ("nack_rollback_valid", "uncache_rollback_valid"),
        ("perf_value", ("out", "[26:0][5:0]", "perf_value")),
    ],
    # LoadQueueReplay 的 tlbReplayDelayCycleCtrl 在本配置下没有读者（firtool 把它从 Replay 上消掉了），
    # 但 LoadQueue 的端口因 LsqWrapper 里的 dontTouch 被保留下来：端口在、没人读。
    "unused_in": ["io_tlbReplayDelayCycleCtrl_%d" % k for k in range(4)],
    "glue_in": dict(
        [(("exceptionBuffer", "io_req_%d_valid" % k),
          ("io_ldu_ldin_%d_valid & ~io_ldu_ldin_%d_bits_isvec" % (k, k), "excbuf_req_valid[%d]" % k))
         for k in range(3)]
        + [(("exceptionBuffer", "io_req_%d_valid" % (3 + k)),
            ("io_vecFeedback_%d_valid & io_vecFeedback_%d_bits_feedback_0" % (k, k),
             "excbuf_req_valid[%d]" % (3 + k))) for k in range(2)]
        + [(("uncacheBuffer", "io_req_%d_valid" % k),
            ("io_ldu_ldin_%d_valid & ~io_ldu_ldin_%d_bits_nc_with_data" % (k, k),
             "uncache_req_valid[%d]" % k)) for k in range(3)]),
    "glue_out": dict(
        [("io_perf_%d_value" % k, ("io_perf_%d_value_REG_1" % k, "perf_value[%d]" % k)) for k in range(17)]
        + [("io_perf_%d_value" % k, ("{5'h0, io_perf_%d_value_REG_1}" % k, "perf_value[%d]" % k))
           for k in range(17, 27)]),
}

# 胶水寄存器钉点：(golden 寄存器, 位宽, 核里的寄存器元素)
LQ_GLUE_PINS = (
    [("io_perf_%d_value_REG" % k, 6, "child_perf_d1[%d]" % k) for k in range(17)]
    + [("io_perf_%d_value_REG_1" % k, 6, "child_perf_d2[%d]" % k) for k in range(17)]
    + [("io_perf_%d_value_REG" % k, 1, "event_d1[%d]" % (k - 17)) for k in range(17, 27)]
    + [("io_perf_%d_value_REG_1" % k, 1, "event_d2[%d]" % (k - 17)) for k in range(17, 27)])

# 各子队列已签核的钉点文件（相对仓根）；没有列出的子队列当年是 FM 自动配对，没有钉点文件。
LQ_CHILD_PINS = {
    "loadQueueRAR": ("LoadQueueRAR", "verif/ut/LoadQueueRAR/fm_pins_pre.tcl"),
    "loadQueueRAW": ("LoadQueueRAW", "verif/ut/LoadQueueRAW/fm_pins_pre.tcl"),
    "loadQueueReplay": ("LoadQueueReplay", "verif/ut/LoadQueueReplay/fm_pins_pre.tcl"),
    "exceptionBuffer": ("LqExceptionBuffer", "verif/ut/LqExceptionBuffer/fm_pins_pre.tcl"),
    "uncacheBuffer": ("LoadQueueUncache", "verif/ut/LoadQueueUncache/fm_pins_pre.tcl"),
}
LQ_NO_PINS = {"virtualLoadQueue"}


# ---------------------------------------------------------------------------
#  LsqWrapper
# ---------------------------------------------------------------------------
UNC_FIELDS = [("robIdx_flag", 1), ("robIdx_value", 8), ("cmd", 5), ("addr", 48), ("vaddr", 50),
              ("data", 64), ("mask", 8), ("id", 7), ("nc", 1), ("memBackTypeMM", 1)]
EXC_FIELDS = [("vaddr", 64), ("vaNeedExt", 1), ("isHyper", 1), ("gpaddr", 64), ("isForVSnonLeafPTE", 1)]


def _lsq_glue_out():
    g = {"io_enq_canAccept": ("_loadQueue_io_enq_canAccept & _storeQueue_io_enq_canAccept", "enq_can_accept"),
         "io_uncache_req_valid": ("io_uncache_req_valid_0", "unc_req_valid"),
         "io_uncache_req_bits_nc": ("io_uncache_req_bits_nc_0", "unc_req.nc"),
         "io_uncache_req_bits_cmd": ("selectLq ? _loadQueue_io_uncache_req_bits_cmd : 5'h1", "unc_req.cmd")}
    for f, _ in UNC_FIELDS:
        if f in ("cmd", "nc"):
            continue
        g["io_uncache_req_bits_" + f] = (
            "selectLq ? _loadQueue_io_uncache_req_bits_%s : _storeQueue_io_uncache_req_bits_%s" % (f, f),
            "unc_req.%s" % f)
    for f, _ in EXC_FIELDS:
        g["io_exceptionAddr_" + f] = (
            "io_exceptionAddr_%s_REG ? _storeQueue_io_exceptionAddr_%s : _loadQueue_io_exceptionAddr_%s"
            % (f, f, f), "exc_addr.%s" % f)
    for k in range(35):
        g["io_perf_%d_value" % k] = ("io_perf_%d_value_REG_1" % k, "perf_value[%d]" % k)
    return g


LSQ_SPEC = {
    "top": "LsqWrapper",
    "core": "xs_LsqWrapper_core",
    "pkg_file": "rtl/memblock/LsqWrapper.sv",
    "alias": {"loadQueue": "lq", "storeQueue": "sq"},
    "core_conns": [
        ("clock", "clock"),
        ("reset", "reset"),
        ("enq_need_alloc", ["io_enq_needAlloc_%d" % k for k in range(6)]),
        ("enq_req_valid", ["io_enq_req_%d_valid" % k for k in range(6)]),
        ("lq_enq_need_alloc", ("out", "[4:0]", "lq_enq_need_alloc")),
        ("lq_enq_req_valid", ("out", "[5:0]", "lq_enq_req_valid")),
        ("sq_enq_need_alloc", ("out", "[4:0]", "sq_enq_need_alloc")),
        ("sq_enq_req_valid", ("out", "[5:0]", "sq_enq_req_valid")),
        ("lq_can_accept", "lq_enq_canAccept"),
        ("sq_can_accept", "sq_enq_canAccept"),
        ("enq_can_accept", ("out", "", "enq_can_accept")),
        ("tlb_replay_delay_ctrl", ("out", "[3:0][6:0]", "tlb_replay_delay_ctrl")),
        ("uncache_outstanding", "io_uncacheOutstanding"),
        ("lq_unc_req_valid", "lq_uncache_req_valid"),
        ("lq_unc_req", ("in_struct", "uncache_req_t",
                        [(f, "lq_uncache_req_bits_" + f) for f, _ in UNC_FIELDS])),
        ("sq_unc_req_valid", "sq_uncache_req_valid"),
        ("sq_unc_req", ("in_struct", "uncache_req_t",
                        [(f, "M_XWR" if f == "cmd" else "sq_uncache_req_bits_" + f) for f, _ in UNC_FIELDS])),
        ("unc_req_ready", "io_uncache_req_ready"),
        ("lq_unc_req_ready", ("out", "", "lq_unc_req_ready")),
        ("sq_unc_req_ready", ("out", "", "sq_unc_req_ready")),
        ("unc_req_valid", ("out", "", "unc_req_valid")),
        ("unc_req", ("out_struct", "uncache_req_t", "unc_req")),
        ("unc_resp_valid", "io_uncache_resp_valid"),
        ("unc_resp_is2lq", "io_uncache_resp_bits_is2lq"),
        ("unc_idresp_valid", "io_uncache_idResp_valid"),
        ("unc_idresp_is2lq", "io_uncache_idResp_bits_is2lq"),
        ("lq_unc_resp_valid", ("out", "", "lq_unc_resp_valid")),
        ("sq_unc_resp_valid", ("out", "", "sq_unc_resp_valid")),
        ("lq_unc_idresp_valid", ("out", "", "lq_unc_idresp_valid")),
        ("sq_unc_idresp_valid", ("out", "", "sq_unc_idresp_valid")),
        ("exc_is_store", "io_exceptionAddr_isStore"),
        ("lq_exc_addr", ("in_struct", "exc_addr_t", [(f, "lq_exceptionAddr_" + f) for f, _ in EXC_FIELDS])),
        ("sq_exc_addr", ("in_struct", "exc_addr_t", [(f, "sq_exceptionAddr_" + f) for f, _ in EXC_FIELDS])),
        ("exc_addr", ("out_struct", "exc_addr_t", "exc_addr")),
        ("lq_perf", ["lq_perf_%d_value" % k for k in range(27)]),
        ("sq_perf", ["sq_perf_%d_value" % k for k in range(8)]),
        ("perf_value", ("out", "[34:0][5:0]", "perf_value")),
    ],
    "glue_in": dict(
        [(("loadQueue", "io_enq_needAlloc_%d" % k), ("io_enq_needAlloc_%d[0]" % k, "lq_enq_need_alloc[%d]" % k))
         for k in range(5)]
        + [(("storeQueue", "io_enq_needAlloc_%d" % k), ("io_enq_needAlloc_%d[1]" % k, "sq_enq_need_alloc[%d]" % k))
           for k in range(5)]
        + [(("loadQueue", "io_enq_req_%d_valid" % k),
            ("io_enq_needAlloc_%d[0] & io_enq_req_%d_valid" % (k, k), "lq_enq_req_valid[%d]" % k)) for k in range(6)]
        + [(("storeQueue", "io_enq_req_%d_valid" % k),
            ("io_enq_needAlloc_%d[1] & io_enq_req_%d_valid" % (k, k), "sq_enq_req_valid[%d]" % k)) for k in range(6)]
        + [(("loadQueue", "io_tlbReplayDelayCycleCtrl_%d" % k), (c, "tlb_replay_delay_ctrl[%d]" % k))
           for k, c in enumerate(["7'hE", "7'h0", "7'h7D", "7'h0"])]
        + [(("loadQueue", "io_uncache_req_ready"), ("_GEN & selectLq & io_uncache_req_ready", "lq_unc_req_ready")),
           (("storeQueue", "io_uncache_req_ready"), ("_GEN & ~selectLq & io_uncache_req_ready", "sq_unc_req_ready")),
           (("loadQueue", "io_uncache_resp_valid"), ("_GEN_0", "lq_unc_resp_valid")),
           (("storeQueue", "io_uncache_resp_valid"), ("_GEN_1", "sq_unc_resp_valid")),
           (("loadQueue", "io_uncache_idResp_valid"), ("_GEN_2", "lq_unc_idresp_valid")),
           (("storeQueue", "io_uncache_idResp_valid"), ("_GEN_3", "sq_unc_idresp_valid"))]),
    "glue_out": _lsq_glue_out(),
}

LSQ_GLUE_PINS = (
    [("io_perf_%d_value_REG" % k, 6, "perf_d1[%d]" % k) for k in range(35)]
    + [("io_perf_%d_value_REG_1" % k, 6, "perf_d2[%d]" % k) for k in range(35)]
    + [("pendingstate", 2, "pending_q")]
    + [("io_exceptionAddr_%s_REG" % f, 1, "sel_store_q[%d]" % i) for i, (f, _) in enumerate(EXC_FIELDS)])

LSQ_CHILD_PINS = {
    "storeQueue": ("StoreQueue", "verif/ut/StoreQueue/fm_pins_pre.tcl"),
}


# ---------------------------------------------------------------------------
#  钉点
# ---------------------------------------------------------------------------
HARVEST_TCL = r"""
set top [lindex $argv 0]
set ::__out [open [lindex $argv 2] w]
proc set_user_match {r i} { puts $::__out "$r\t$i"; return 1 }
source [lindex $argv 1]
close $::__out
"""


def harvest(child_top, pin_file):
    """在 tclsh 里用桩 set_user_match（恒返回 1、记下两侧名字）执行子队列自己的钉点文件，
    收回它实际发出的每一对名字。子文件自己的计数闸照常执行：任何一处 error 都让收割失败。"""
    with tempfile.TemporaryDirectory() as td:
        drv = os.path.join(td, "h.tcl")
        out = os.path.join(td, "pairs.tsv")
        open(drv, "w").write(HARVEST_TCL)
        r = subprocess.run(["tclsh", drv, child_top, os.path.join(REPO, pin_file), out],
                           stdout=subprocess.PIPE, stderr=subprocess.STDOUT, universal_newlines=True)
        if r.returncode != 0:
            die("收割 %s 失败：\n%s" % (pin_file, r.stdout[-2000:]))
        pairs = [tuple(l.split("\t")) for l in open(out).read().splitlines()]
    rp, ip = "r:/WORK/%s/" % child_top, "i:/WORK/%s/" % child_top
    for a, b in pairs:
        if not a.startswith(rp) or not b.startswith(ip):
            die("%s 的钉点 %s <-> %s 不在 %s 之下" % (pin_file, a, b, child_top))
    return [(a[len(rp):], b[len(ip):]) for a, b in pairs]


def golden_regs(module):
    out = {}
    for a, b, n in re.findall(r"^\s*reg\s+(?:\[(\d+):(\d+)\]\s+)?(\w+);", golden_text(module), re.M):
        out[n] = int(a) - int(b) + 1 if a else 1
    return out


def glue_pairs(top, pins):
    """本层胶水寄存器：(golden 寄存器, 位宽, 核里的寄存器元素) → 相对路径钉点对。"""
    regs = golden_regs(top)
    pinned = set(g for g, _, _ in pins)
    if pinned != set(regs):
        die("%s 胶水钉点表与 golden 本层寄存器不一致：多 %s 少 %s"
            % (top, sorted(pinned - set(regs)), sorted(set(regs) - pinned)))
    out = []
    for g, w, core in pins:
        if regs[g] != w:
            die("%s 钉点 %s 位宽 golden=%d 表=%d" % (top, g, regs[g], w))
        m = re.fullmatch(r"(\w+)((?:\[\d+\])*)", core)
        for b in range(w):
            rb = "%s_reg" % g + ("[%d]" % b if w > 1 else "")
            ib = "u_core/%s_reg%s" % (m.group(1), m.group(2)) + ("[%d]" % b if w > 1 else "")
            out.append((rb, ib))
    return out


def lq_pairs():
    out = glue_pairs("LoadQueue", LQ_GLUE_PINS)
    counts = [("glue", len(out))]
    for inst, (ctop, f) in LQ_CHILD_PINS.items():
        ps = [(inst + "/" + a, inst + "/" + b) for a, b in harvest(ctop, f)]
        counts.append((inst, len(ps)))
        out += ps
    return out, counts


def lsq_pairs():
    out = glue_pairs("LsqWrapper", LSQ_GLUE_PINS)
    counts = [("glue", len(out))]
    lq, _ = lq_pairs()
    out += [("loadQueue/" + a, "loadQueue/" + b) for a, b in lq]
    counts.append(("loadQueue", len(lq)))
    for inst, (ctop, f) in LSQ_CHILD_PINS.items():
        ps = [(inst + "/" + a, inst + "/" + b) for a, b in harvest(ctop, f)]
        counts.append((inst, len(ps)))
        out += ps
    return out, counts


def pin_tcl(top, tag, pairs, counts, why):
    seen_r, seen_i = set(), set()
    for a, b in pairs:
        if a in seen_r or b in seen_i:
            die("%s 钉点不是一一对应：%s / %s" % (top, a, b))
        seen_r.add(a)
        seen_i.add(b)
        if "{" in a + b or "}" in a + b or a.endswith("\\") or b.endswith("\\"):
            die("%s 钉点名字含花括号/结尾反斜杠，不能用 {} 引用：%s" % (top, a))
    n = len(pairs)
    o = ["# %s FM「匹配前」钉点 —— 自动生成：scripts/gen_lsq.py（勿手改）" % top, "#"]
    o += ["# " + l for l in why]
    o += ["#",
          "# 组成（条数）：" + "，".join("%s %d" % c for c in counts) + "，合计 %d。" % n,
          "# set_user_match 只声明两点对应，比较照比：不约束 ref、不改 appvar、不加黑盒、不 dont_verify。",
          "# fail-closed：逐条数返回值，拒一条或总数不等于字面整数就 error。进 fm.log 的输出一律 ASCII。",
          "proc _%s_pre_pin { } {" % tag,
          "    set _expect %d" % n,
          "    set r \"r:/WORK/%s\"" % top,
          "    set i \"i:/WORK/%s\"" % top,
          "    set pairs {"]
    for a, b in pairs:
        o.append("        {%s} {%s}" % (a, b))
    o += ["    }",
          "    puts \"%s_PREPIN_BEGIN %s expect=$_expect\"" % (tag.upper(), top),
          "    set n 0",
          "    foreach {rp ip} $pairs {",
          "        if {![set_user_match \"$r/$rp\" \"$i/$ip\"]} {",
          "            puts \"%s_PREPIN_FAIL: set_user_match returned 0 for $r/$rp <-> $i/$ip\"" % tag.upper(),
          "            error \"%s_PREPIN_MISS=$rp\"" % tag.upper(),
          "        }",
          "        incr n",
          "    }",
          "    puts \"%s_PREPIN_END %s n=$n expect=$_expect\"" % (tag.upper(), top),
          "    if {$n != $_expect} {",
          "        puts \"%s_PREPIN_ERROR: pinned $n but expected $_expect\"" % tag.upper(),
          "        error \"%s_PREPIN_COUNT=$n\"" % tag.upper(),
          "    }",
          "}",
          "_%s_pre_pin" % tag]
    return "\n".join(o) + "\n"


PIN_WHY_COMMON = [
    "两侧都是整棵子树白盒：ref 读 golden 各子队列，impl 读本仓重写件。名字差有两层：",
    "  (1) 本层胶水寄存器：golden 平铺名 io_perf_<k>_value_REG 等 <-> 核里的数组元素 u_core/...；",
    "  (2) 各子队列内部：直接收割该子队列签核时用的那份 fm_pins_pre.tcl（tclsh 里用桩执行、",
    "      逐对记下），把 <子模块>/ 前缀换成 <实例名>/ —— 与子队列单独签核时是同一批点对。",
    "没有钉点文件的子队列（当年 FM 自动配对）这里也不钉。",
]


def gen_lq_pins():
    pairs, counts = lq_pairs()
    return (os.path.join(REPO, "verif/ut/LoadQueue/fm_pins_pre.tcl"),
            pin_tcl("LoadQueue", "lq", pairs, counts, PIN_WHY_COMMON))


def gen_lsq_pins():
    pairs, counts = lsq_pairs()
    return (os.path.join(REPO, "verif/ut/LsqWrapper/fm_pins_pre.tcl"),
            pin_tcl("LsqWrapper", "lsq", pairs, counts,
                    PIN_WHY_COMMON + ["loadQueue 子树 = LoadQueue 那份钉点（同一生成器）整体加 loadQueue/ 前缀。"]))


# ---------------------------------------------------------------------------
#  UT testbench 的生成区（verif/ut/<T>/tb.sv；手写区不动）
# ---------------------------------------------------------------------------
def qualifier(outs, n):
    """输出 n 的"有效位"限定：最长前缀 P 使 n 以 P_bits_ 开头且 P_valid 也是输出。无则 None。"""
    best = None
    for m in re.finditer(r"_bits_", n):
        v = n[:m.start()] + "_valid"
        if v in outs:
            best = v
    return best


def tb_ports(module):
    ps = port_table(module)
    L = ["  // ---- 输入（两侧共用；clock/reset 由手写区驱动）----"]
    for d, w, n, _ in ps:
        if d == "input" and n not in ("clock", "reset"):
            L.append("  logic %s%s;" % (rng(w), n))
    L.append("  // ---- 输出（g_ = golden，i_ = 重写）----")
    for d, w, n, _ in ps:
        if d == "output":
            L.append("  wire  %sg_%s, i_%s;" % (rng(w), n, n))
    for inst, pre, mod in (("u_gold", "g_", module), ("u_impl", "i_", module + "_xs")):
        L.append("  %s %s (" % (mod, inst))
        conns = ["    .%s(%s)" % (n, n if d == "input" else pre + n) for d, w, n, _ in ps]
        L.append(",\n".join(conns))
        L.append("  );")
    return L


def tb_stim(module, redirect_valid):
    """每拍给全部输入随机值：*_valid 按 p_valid、*_ready 按 p_ready（百分比，手写区按相位调），
    redirect 按 p_redirect；其余均匀随机（宽端口用多个 $urandom 拼接后截位）。"""
    L = ["  task automatic drive_inputs();"]
    for d, w, n, _ in port_table(module):
        if d != "input" or n in ("clock", "reset"):
            continue
        if n == redirect_valid:
            L.append("    %s = ($urandom_range(99) < p_redirect);" % n)
        elif w == 1 and re.search(r"_exceptionVec_\d+$", n):
            # 异常位 / 重放原因位：各自稀有（全随机时 17 个位全 0 的概率只有 1/131072，uncache 缓冲永远不入队）
            L.append("    %s = ($urandom_range(99) < 3);" % n)
        elif w == 1 and re.search(r"_rep_info_cause_\d+$", n):
            L.append("    %s = ($urandom_range(99) < 5);" % n)
        elif w == 1 and n.endswith("_valid"):
            L.append("    %s = ($urandom_range(99) < p_valid);" % n)
        elif w == 1 and n.endswith("_ready"):
            L.append("    %s = ($urandom_range(99) < p_ready);" % n)
        elif re.search(r"(?i)(robidx|lqidx|sqidx|ptr\w*)_value$|_(mid|sid|id)$", n):
            # 指针/编号类：70% 落在 0..7 的小窗口，让"比较相等 / 谁更老"的分支常被踩到
            L.append("    %s = ($urandom_range(99) < 70) ? %d'($urandom_range(7)) : %d'($urandom());" % (n, w, w))
        elif re.search(r"(?i)(robidx|lqidx|sqidx|ptr\w*)_flag$", n):
            L.append("    %s = ($urandom_range(99) < 15);" % n)
        elif re.search(r"(?i)(paddr|vaddr|_addr|fullva|gpaddr)$", n):
            # 地址类：60% 取自 4 个固定地址的小池（手写区 addr_pool），让 CAM / 地址比较常命中
            L.append("    %s = ($urandom_range(99) < 60) ? %d'(addr_pool[$urandom_range(3)]) : %d'({$urandom(), $urandom()});"
                     % (n, w, w))
        elif w <= 32:
            L.append("    %s = %d'($urandom());" % (n, w))
        else:
            k = (w + 31) // 32
            L.append("    %s = %d'({%s});" % (n, w, ", ".join(["$urandom()"] * k)))
    L.append("  endtask")
    return L


def tb_compare(module):
    """逐位比全部输出。cmp_all=1（常量 initreg 档）时从第一拍起全比；随机档下 *_bits_* 只在
    golden 的对应 *_valid 为 1 时比（不复位的 payload 两侧初值不同，valid 起来之前没有意义）。
    另记每个输出位见过 0/1（toggle 覆盖）。"""
    outs = [(w, n) for d, w, n, _ in port_table(module) if d == "output"]
    names = {n for _, n in outs}
    L = []
    for w, n in outs:
        L.append("  logic %sseen1_%s = '0, seen0_%s = '0;" % (rng(w), n, n))
    for w, n in outs:
        L.append("  bit armed_%s = 0;" % n)
    L.append("  task automatic compare_outputs();")
    for w, n in outs:
        q = qualifier(names, n)
        cond = "g_%s !== i_%s" % (n, n)
        if q:
            cond = "(cmp_all | g_%s) && (%s)" % (q, cond)
        # 随机初值档：该端口两侧第一次相等（且已过 arm_start）之后才开始比
        L.append("    if (!cmp_all && !armed_%s && cyc >= arm_start && g_%s === i_%s) armed_%s = 1;" % (n, n, n, n))
        L.append("    if ((cmp_all | armed_%s) && %s) begin" % (n, cond))
        L.append("      errors++;")
        L.append("      if (errors <= 30) $display(\"MISMATCH cyc=%%0d %s: g=%%h i=%%h\", cyc, g_%s, i_%s);" % (n, n, n))
        L.append("    end")
        L.append("    seen1_%s |= g_%s;" % (n, n))
        L.append("    seen0_%s |= ~g_%s;" % (n, n))
    L.append("    checks++;")
    L.append("  endtask")
    L.append("  // 从未翻转过的输出位个数（逐端口打印前 40 个）")
    L.append("  function automatic int report_toggle();")
    L.append("    int bad = 0;")
    L.append("    int ports = 0;")
    for w, n in outs:
        L.append("    if ((~seen1_%s | ~seen0_%s) != '0) begin ports++; bad += $countones(~seen1_%s | ~seen0_%s);"
                 " if (ports <= 40) $display(\"TOGGLE MISS %s 1=%%h 0=%%h\", seen1_%s, seen0_%s); end"
                 % (n, n, n, n, n, n, n))
    L.append("    begin int na = 0;")
    for w, n in outs:
        L.append("      if (!cmp_all && !armed_%s) begin na++; if (na <= 40) $display(\"NEVER ARMED %s\"); end" % (n, n))
    L.append("      $display(\"ARMED: %0d ports never armed (random-init mode only)\", na);")
    L.append("    end")
    L.append("    $display(\"TOGGLE: %%0d output bits never toggled, in %%0d ports (of %d ports / %d bits)\", bad, ports);"
             % (len(outs), sum(w for w, _ in outs)))
    L.append("    return bad;")
    L.append("  endfunction")
    return L


def gen_tb(module, redirect_valid):
    path = os.path.join(REPO, "verif/ut/%s/tb.sv" % module)
    text = open(path).read()
    text = replace_region(text, "tb-ports", "\n".join(tb_ports(module)))
    text = replace_region(text, "tb-stim", "\n".join(tb_stim(module, redirect_valid)))
    text = replace_region(text, "tb-compare", "\n".join(tb_compare(module)))
    return path, text


def gen_lq_tb():
    return gen_tb("LoadQueue", "io_redirect_valid")


def gen_lsq_tb():
    return gen_tb("LsqWrapper", "io_brqRedirect_valid")


def gen_rtl(spec, fname, tag):
    path = os.path.join(RTL, fname)
    text = open(path).read()
    text = replace_region(text, tag + "-ports", port_block(spec["top"]))
    text = replace_region(text, tag + "-body", Assembly(spec).build())
    return path, text


def gen_lq_rtl():
    return gen_rtl(LQ_SPEC, "LoadQueue.sv", "loadqueue")


def gen_lsq_rtl():
    return gen_rtl(LSQ_SPEC, "LsqWrapper.sv", "lsqwrapper")


GENERATORS = [gen_lq_rtl, gen_lsq_rtl, gen_lq_pins, gen_lsq_pins, gen_lq_tb, gen_lsq_tb]


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--check", action="store_true")
    ap.add_argument("--only", default="", help="逗号分隔：lq_rtl,lsq_rtl,lq_pins,lsq_pins,lq_tb,lsq_tb")
    a = ap.parse_args()
    only = set(x for x in a.only.split(",") if x)
    drift = 0
    for g in GENERATORS:
        if only and g.__name__[4:] not in only:
            continue
        path, text = g()
        old = open(path).read() if os.path.exists(path) else None
        rel = os.path.relpath(path, REPO)
        if old == text:
            continue
        if a.check:
            print("DRIFT: %s" % rel)
            drift += 1
        else:
            os.makedirs(os.path.dirname(path), exist_ok=True)
            open(path, "w").write(text)
            print("wrote %s" % rel)
    if a.check:
        print("gen_lsq --check: %s" % ("DRIFT" if drift else "OK"))
        return 1 if drift else 0
    return 0


if __name__ == "__main__":
    sys.exit(main())
