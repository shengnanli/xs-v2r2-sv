#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""perf_tier.py —— 把 codex 0162 D3 的**分档判据**变成机器可判的台账。

## 为什么要有这个脚本

`scripts/perf_compare.py` 只会说 MATCH / MISMATCH / EXCLUDED / MISSING。
可 codex 0162 D3 要的不是"相等吗"，是**分档**：

    - Architectural state, memory effects, exceptions, trap PC, benchmark output,
      and cycle-visible functional behavior must match.
    - Any performance signal that feeds control, software-visible PMU behavior,
      or an advertised performance contract must match.
    - Internal diagnostic/provider counters that do not feed control may differ
      only after explicit classification.
    - Do not claim full performance-observation equivalence while counters remain
      EXCLUDED. Keep those as a visible follow-up ledger, not zeros counted as matches.

"哪些信号馈入控制"这句是全部难点。它**不能靠名字猜**（名字是 firtool 产物，
`_GEN_17` 看不出任何语义），所以下面给一条**从 golden RTL 现场算**的判据。

## 判据 FC（feeds-control）——本脚本的核心，写全了给人复核

一条 bore 在 golden 里长这样：`SimTop.….<持有模块>.<信号>`。问题是：
**如果这个计数器两侧不同，是否意味着机器的行为不同？**

  FC-1 拆掉 firtool 的探针拷贝。
       firtool 为每条 bore **另造一根网线**（`wire io_fencei_probe = io_fencei;`），
       好让"被观测"这件事不改变网表。所以先沿**纯拷贝**（`wire X = Y;` /
       `assign X = Y;`，右边只有一个标识符）一路解析到真正被观测的那根线。
       不做这一步，`io_fencei_probe` 会被判成"没人读"，而它其实就是 `io_fencei`。

  FC-2 问解析后的那根线：**模块自己的可综合逻辑里有没有人读它？**
       判读的位置 = 它出现在自己赋值目标之外的任何地方：别人的表达式、
       `if` 条件；或者它本身就是本模块的端口（端口 = 逃出模块，也是 FM 的比较边界）。
       扫之前先剥掉 `` `ifndef SYNTHESIS `` 段 —— 那里面是断言和 printf，
       不是控制逻辑。不剥的话 FTB 的 `_GEN_0` 会因为出现在一条断言里被误判成
       "馈入控制"（实测踩过）。

  FC-3 子实例端口连线要**查方向**。
       firtool 把"喂给子实例"和"子实例驱动本模块网线"写成同一个样子：
       `.io_x (net)`。只有查 `<子模块>.sv` 的端口方向才分得开 ——
         input/inout  → net 被子实例读 ⇒ 馈入控制；
         output       → net 是**被子实例驱动**的，不是有人读它。
       ★这条是实测补上的★：CtrlBlock 里 `_probe` 全模块只出现两次 —— 一次裸声明，
       一次 `.io_commits_info_0_debug_pc (_probe)`（Rob 的 debug 输出，CtrlBlock 里
       无人读）。不查方向，`rob: robHeadPC` 会被判成 B_CONTROL 并当场挡住里程碑。

  有人读 → **B_CONTROL**：设计里有状态/端口/子模块依赖这个值，
           它不同 ⇒ 机器的行为不同 ⇒ 必须相等。
  没人读 → **C_DIAG**：这根线是 firtool 专为导出这条 bore 造的派生事件，
           全设计没有任何寄存器、端口、子实例依赖它 —— 把这个计数器整条拿掉，
           网表逐位不变。这正是 codex 说的 "does not feed control"。
           （抽查 12 条：它们在自己的 golden 模块里**只出现 1 次**，就是那行
           `wire _GEN_n = …;` 本身。）

★软件可见的 PMU 自动落在 B_CONTROL★：hpm 事件在 golden 里是 `io_perf_*` 输出端口，
观测到它的 bore 在 FC-2 里必然"被读"（它要往端口上走）。实测 `FTB.perfEvents_0_2_probe`
就是这么被判进 B_CONTROL 的（证据列里能看到 `io_perf_0_value_REG <= …`）。
所以不需要另写一条名字判据，也就不会漏。

## 一个计数器由哪些 bore 组成 —— LogPerfEndpoint 内部数据流

`perf_compare` 比的是 `[PERF ] <scope>: <name>, <值>` 这一行，而一行的值是
LogPerfEndpoint 内部某根线/寄存器。要知道它由哪些 bore 决定，就得在
`LogPerfEndpoint.sv` 里做一次**反向数据流闭包**：

  * 连续赋值 `wire X = e;` / `assign X = e;` → X 依赖 e 里的标识符；
  * 时序赋值 `X <= e;` → X 依赖 e **以及所有包住这条语句的 `if` 条件**。
    ★这一条是关键★：直方图的桶长这样 —— `if (perfCnt_bore_8094 > 8'h9D)
    utilOverflow_5 <= utilOverflow_5 + 1;` 那条 bore 只出现在**条件**里。
    只看右边表达式的话，整族直方图桶会被算成"不依赖任何 bore"。

计数更新的那个 `always @(posedge clock)` 块里只有 `if/else` 和 `<=` 两种语句
（实测：全块 98995 行里 `case`/`for`/`$…`/`` ` ``指令各 0 次），所以一个几十行的
递归下降解析器就够，不需要真的 Verilog 前端。

## 四档 + 两个"不由 DUT 决定"的类

  A_FUNC_ASSERT  golden 的断言（`[ERROR]` 打印）。断言响不响是 cycle-visible 的
                 功能行为 → 必须相等。
  B_CONTROL      至少有一条 bore 满足判据 FC → 必须相等（含 PMU 可见）。
  C_DIAG         全部 bore 都不馈入控制 → 显式归类后**允许**不同。
  D_CONST        打印的实参是 golden 里的**字面量**（例如 `util_underflow` 印的就是
                 `64'h0`）。两侧例化的是同一份 golden LogPerfEndpoint，所以恒等。
  D_INVARIANT    反向闭包里**一条 bore 都没有**：值只由 LogPerfEndpoint 自己的
                 计数状态与 difftest 给的 `io_timer/io_clean/io_dump/reset` 决定
                 （例如 `util_sampled` = 采样拍数，每拍加一）。与 DUT 无关，
                 **前提是两侧 dump 时刻相同** —— 这个前提由 perf_compare 现场校验。
  X_UNRESOLVED   上面都判不出来 → ★闸红★。这个状态存在的唯一目的就是：
                 golden 换一版、出现本脚本没见过的写法时，闸必须响，
                 而不是悄悄多出一批"未分类"。

## 另一根正交的轴：status（能不能测）

档位说的是"要求"，status 说的是"这一轮能不能验"：

  MEASURED        这个计数器的每一条 bore 都重绑上了（tier ∈ T0/T1/T2*）
                  → perf_compare 可以判对错。
  GAP             有 bore 落在 T3_REG_LEAF / T4_OPEN → 生成的 SimTop 给它接的是 `'0`，
                  impl 侧印出来的 0 **不是测量值**。
                  ★永远不许当 MATCH 计★，逐条见 docs/perf_gap_ledger.tsv。
  BY_CONSTRUCTION D_CONST / D_INVARIANT：不经过 bore，无所谓绑不绑。

把两根轴分开的理由很直接：一个 **B_CONTROL 且 GAP** 的计数器
（必须相等、但这一轮测不了）和一个 **C_DIAG 且 GAP** 的完全不是一回事，
混成一个 "EXCLUDED 592" 就把这个区别抹平了。实测这 599 条里 427 条是 B_CONTROL。

## 与 docs/perf_bore_unbound.tsv 的关系

那张表按"同族"（`also_feeds`）整片排除，会**多排**：`ftq` 的三条
`*_latency_sampled` 是 NSamples 计数器，由另一条已绑上的 bore 驱动，实测两侧
382/382、2732/2732、284/284，是真测到的相等。本脚本改用 endpoint 内部的反向数据流
闭包，只排该排的 —— 新排除集合是旧集合的**真子集**（589 ⊂ 592，0 条新增），
所以没有把任何假零放回 MATCH。perf_compare 现在以 gap 台账为准。

## 复跑

    python3 scripts/perf_tier.py            # 重算 docs/perf_tier_ledger.tsv + gap 台账
    python3 scripts/perf_tier.py --check    # 幂等闸（台账必须与重算逐字节一致）
    python3 scripts/check_perf_tier.py      # 全套 fail-closed 闸（含豁免现算）

输入：/home/eda/xs-env/G1-canonical/golden-rtl（只读）、docs/perf_bore_map.tsv、
      rtl/**/*.sv（算 owner_rewritten）。
"""
from __future__ import print_function

import argparse
import collections
import hashlib
import pathlib
import re
import sys

HERE = pathlib.Path(__file__).resolve().parent
REPO = HERE.parent
GOLDEN_DEFAULT = '/home/eda/xs-env/G1-canonical/golden-rtl'

MAP = REPO / 'docs' / 'perf_bore_map.tsv'
UNBOUND = REPO / 'docs' / 'perf_bore_unbound.tsv'
LEDGER = REPO / 'docs' / 'perf_tier_ledger.tsv'
GAPLEDGER = REPO / 'docs' / 'perf_gap_ledger.tsv'

# ---------------------------------------------------------------- 小工具

LIT = re.compile(r"\b\d+'[sS]?[hHdDbBoO][0-9a-fA-FxXzZ_]+")
IDENT = re.compile(r'^[A-Za-z_]\w*$')
BORE = re.compile(r'^(?:perfCnt|enable|x1|x2)_bore(?:_\d+)?$')
# 词法：位宽字面量整体成一个 token（否则 `8'hD8` 里的 `hD8` 会冒充信号名）
TOK = re.compile(r"\d+'[sS]?[hHdDbBoO][0-9a-fA-FxXzZ_]+|[A-Za-z_]\w*|<=|[()\[\];,]|\S")
KW = set('''begin end if else assign wire reg logic posedge negedge always initial
module endmodule input output inout parameter localparam signed unsigned'''.split())

MODULE_RE = re.compile(r'^module\s+([A-Za-z_]\w*)', re.M)


def ids(text):
    """表达式里的标识符（先剥位宽字面量，再去关键字）。"""
    return [x for x in re.findall(r'[A-Za-z_]\w*', LIT.sub(' ', text)) if x not in KW]


def clip(s, n):
    """确定性截断 —— 台账要能逐字节复算，所以截断规则也必须是纯函数。"""
    s = ' '.join(s.split())
    return s if len(s) <= n else s[:n - 1] + '…'


# ---------------------------------------------------------------- LogPerfEndpoint 解析

class Endpoint(object):
    """LogPerfEndpoint.sv：打印串 + 内部数据流。"""

    FWRITE = re.compile(
        r'\$fwrite\(32\'h80000002, ("(?:[^"\\]|\\.)*"(?:\s*,\s*"(?:[^"\\]|\\.)*")*)\s*,?\s*([^;]*)\)')

    def __init__(self, golden_root):
        raw = re.sub(r'//[^\n]*', '',
                     (pathlib.Path(golden_root) / 'LogPerfEndpoint.sv').read_text(errors='replace'))
        self.body = raw[raw.index(');\n'):]
        self.drv = collections.defaultdict(set)
        self._memo = {}
        self._continuous()
        self._sequential()

    # -- 连续赋值
    def _continuous(self):
        flat = re.sub(r'\s+', ' ', self.body)
        for m in re.finditer(r'\bwire\s+(?:\[[^\]]*\]\s*)*(\w+)\s*=\s*([^;]*);', flat):
            self.drv[m.group(1)].update(ids(m.group(2)))
        for m in re.finditer(r'\bassign\s+(\w+)\s*=\s*([^;]*);', flat):
            self.drv[m.group(1)].update(ids(m.group(2)))

    # -- 时序赋值：`X <= e;` 依赖 e ∪ 所有包住它的 if 条件
    def _sequential(self):
        sys.setrecursionlimit(200000)
        for am in re.finditer(r'always @\(posedge clock\) begin', self.body):
            toks = TOK.findall(self.body[am.end():])
            depth, stop = 1, None
            for i, t in enumerate(toks):
                if t == 'begin':
                    depth += 1
                elif t == 'end':
                    depth -= 1
                    if depth == 0:
                        stop = i
                        break
            toks = toks[:stop]
            # 带 `$fwrite` 的那个 always 是**打印块**（在 `ifndef SYNTHESIS` 里），
            # 不是计数更新逻辑；断言的 bore 归属另走 asserts()。
            if any(t.startswith('$') for t in toks):
                continue
            self._parse_block(toks)

    def _parse_block(self, toks):
        pos = [0]
        drv = self.drv

        def names(seq):
            return set(x for x in seq if IDENT.match(x) and x not in KW)

        def stmt(guards):
            i = pos[0]
            if i >= len(toks):
                return
            t = toks[i]
            if t == 'begin':
                pos[0] = i + 1
                while pos[0] < len(toks) and toks[pos[0]] != 'end':
                    stmt(guards)
                pos[0] += 1
                return
            if t == 'if':
                j = i + 1
                d, k = 0, j
                while k < len(toks):
                    if toks[k] == '(':
                        d += 1
                    elif toks[k] == ')':
                        d -= 1
                        if d == 0:
                            break
                    k += 1
                g2 = guards + [names(toks[j + 1:k])]
                pos[0] = k + 1
                stmt(g2)
                if pos[0] < len(toks) and toks[pos[0]] == 'else':
                    pos[0] += 1
                    stmt(g2)
                return
            k = i
            while k < len(toks) and toks[k] != ';':
                k += 1
            st = toks[i:k]
            pos[0] = k + 1
            if '<=' in st:
                src = names(st[st.index('<=') + 1:])
                for g in guards:
                    src |= g
                drv[st[0]].update(src)

        while pos[0] < len(toks):
            stmt([])

    # -- 反向闭包：一根线由哪些 bore 决定
    def bores_of(self, net):
        if net in self._memo:
            return self._memo[net]
        out, seen, stack = set(), set(), [net]
        while stack:
            s = stack.pop()
            if s in seen:
                continue
            seen.add(s)
            if BORE.match(s):
                out.add(s)
                continue
            if s in self._memo:
                out |= self._memo[s]
                continue
            for x in self.drv.get(s, ()):
                if x not in seen:
                    stack.append(x)
        self._memo[net] = out
        return out

    # -- `[PERF ]` 打印：(scope, name) -> 实参表达式
    def perf_counters(self):
        out = []
        for fmtq, args in self.FWRITE.findall(re.sub(r'\s+', ' ', self.body)):
            fmt = ''.join(re.findall(r'"((?:[^"\\]|\\.)*)"', fmtq))
            if '[PERF ]' not in fmt:
                continue
            ents = re.findall(r'\[PERF \]\[time=%d\] ([^:]+): ([^,]+), %d', fmt)
            data = [a.strip() for a in args.split(',') if a.strip() and a.strip() != 'io_timer']
            if len(ents) != len(data):
                # 格式串与参数表对不齐 —— 不猜，交给 X_UNRESOLVED 让闸响。
                for s, n in ents:
                    out.append((s.strip(), n.strip(), None))
                continue
            for (s, n), d in zip(ents, data):
                out.append((s.strip(), n.strip(), d))
        return out

    # -- `[ERROR]` 打印：(scope, msg) -> 断言条件与打印负载里的 bore
    def asserts(self):
        """★条件里的 bore 常常隔了一层 endpoint 内部线★

        golden 里两种写法都有：
            if ((`PRINTF_COND_) & x1_bore_260 & ~reset) $fwrite(…);   ← 直接是 bore
            if (_GEN_15)                                $fwrite(…);   ← 隔了一根线
        只认字面上的 `*_bore*` 的话，后一种会被算成"这条断言不依赖任何 bore"
        —— 实测有 15 条是这样（itlb/dtlb 的 non-block、LoadUnit 的 merge buffer、
        l2tlb cache 的 ecc）。所以条件与参数表里的标识符都要过一遍反向闭包。
        """
        flat = re.sub(r'\s+', ' ', self.body)
        chunks = flat.split("$fwrite(32'h80000002,")
        out = collections.OrderedDict()
        for k in range(1, len(chunks)):
            m = re.match(r'\s*("(?:[^"\\]|\\.)*"(?:\s*,\s*"(?:[^"\\]|\\.)*")*)', chunks[k])
            if not m:
                continue
            fmt = ''.join(re.findall(r'"((?:[^"\\]|\\.)*)"', m.group(1)))
            if '[ERROR]' not in fmt:
                continue
            mm = re.match(r'\[ERROR\]\[time=%d\] ([^:]+): (.*)', fmt)
            scope, msg = (mm.group(1).strip(), mm.group(2).strip()[:160]) if mm else ('', fmt[:160])
            # 断言的**条件**不在 $fwrite 的参数表里，在它前面那个 if 里。
            cond = chunks[k - 1][-300:]
            cond = cond[cond.rfind('if (') if 'if (' in cond else 0:]
            # 参数表 = 格式串之后到 `)` 为止。★不能拿整段 chunk★：格式串里的英文词
            # （`entries_2` `dcache` …）会和 endpoint 的网线重名，凭空多出 bore。
            rest = chunks[k][m.end():]
            args = rest[:rest.find(')')] if ')' in rest else rest
            b = set()
            for x in ids(cond) + ids(args):
                b |= {x} if BORE.match(x) else self.bores_of(x)
            out.setdefault((scope, msg), set()).update(b)
        return out


# ---------------------------------------------------------------- 判据 FC

class FeedsControl(object):
    """判据 FC：golden 持有模块里，被观测的那根线（解析掉探针拷贝之后）有没有读者。"""

    DECL = re.compile(r'\b(?:wire|reg|logic)\s+(?:signed\s+)?(?:\[[^\]]*\]\s*)*$')
    PORTD = re.compile(
        r'\b(?:input|output|inout)\s+(?:wire\s+|reg\s+|logic\s+)?(?:signed\s+)?(?:\[[^\]]*\]\s*)*$')
    COPY = re.compile(r'\b(?:wire\s+(?:\[[^\]]*\]\s*)*|assign\s+)(\w+)\s*=\s*([A-Za-z_]\w*)\s*;')

    # 实例头：`  ChildModule instName (` 单独占一行（firtool 固定这么排）
    INSTHEAD = re.compile(r'^[ \t]{2,}([A-Za-z_]\w*)[ \t]+([A-Za-z_]\w*)[ \t]*\([ \t]*$')
    # 一条端口连线：`.port (actual)`，actual 里允许一层括号
    CONN = re.compile(r'\.(\w+)\s*\(([^()]*(?:\([^()]*\)[^()]*)*)\)')

    def __init__(self, golden_root):
        self.root = pathlib.Path(golden_root)
        self._dir = {}

    def port_dirs(self, module):
        """{port: 'input'|'output'|'inout'}；只读到端口表结束，不读整份文件。

        为什么需要方向：firtool 把**子实例的输出**也写成 `.io_x (net)` —— 长得和
        "把 net 喂给子实例"一模一样，但那是子实例**驱动** net，不是有人读 net。
        CtrlBlock 的 `_probe` 就是这种：全模块只有两次出现，一次是裸声明，一次是
        `.io_commits_info_0_debug_pc (_probe)`（Rob 的 debug 输出）。不查方向就会
        把它判成"馈入控制"，于是 rob:robHeadPC 被误判成 B_CONTROL 而挡住里程碑。
        """
        if module in self._dir:
            return self._dir[module]
        f = self.root / (module + '.sv')
        if not f.exists():
            self._dir[module] = {}
            return {}
        head = f.read_text(errors='replace')
        head = head[:head.index(');\n') + 3] if ');\n' in head else head[:200000]
        d = {}
        for m in re.finditer(r'^\s*(input|output|inout)\s+(?:wire\s+|reg\s+|logic\s+)?'
                             r'(?:signed\s+)?(?:\[[^\]]*\]\s*)*(\w+)', head, re.M):
            d[m.group(2)] = m.group(1)
        self._dir[module] = d
        return d

    def _instance_conns(self, text):
        """{signal: set((childModule, port, direction))}，只收实例端口连线里的实参。"""
        lines = text.splitlines()
        conns = collections.defaultdict(set)
        i = 0
        while i < len(lines):
            m = self.INSTHEAD.match(lines[i])
            if not m:
                i += 1
                continue
            child = m.group(1)
            j = i + 1
            buf = []
            while j < len(lines) and not re.match(r'^[ \t]{2,}\);\s*$', lines[j]):
                buf.append(lines[j])
                j += 1
                if j - i > 20000:              # 不是实例，别失控
                    break
            seg = ' '.join(buf)
            dirs = self.port_dirs(child)
            for c in self.CONN.finditer(seg):
                port, actual = c.group(1), c.group(2)
                if '/* unused */' in actual:
                    continue
                for x in ids(actual):
                    conns[x].add((child, port, dirs.get(port, '?')))
            i = j + 1
        return conns

    @staticmethod
    def _strip_nonsynth(text):
        """剥掉 `ifndef SYNTHESIS` / `ifdef FIRRTL_BEFORE_INITIAL` 段。

        那里面是断言与 printf。不剥的话，一根只在断言里出现过的线会被判成
        "馈入控制"（实测 FTB 的 `_GEN_0` 就是这么被误判的）。
        """
        out, depth = [], 0
        for ln in text.splitlines():
            s = ln.lstrip()
            if depth:
                if s.startswith('`ifdef') or s.startswith('`ifndef'):
                    depth += 1
                elif s.startswith('`endif'):
                    depth -= 1
                continue
            if s.startswith('`ifndef SYNTHESIS') or s.startswith('`ifdef FIRRTL_BEFORE_INITIAL'):
                depth = 1
                continue
            out.append(ln)
        return '\n'.join(out)

    def analyze(self, module, signals):
        """{signal: (verdict, resolved_net, criterion, evidence)}

        verdict ∈ FEEDS_CONTROL / OBSERVE_ONLY / NO_FILE
        """
        f = self.root / (module + '.sv')
        if not f.exists():
            return dict((s, ('NO_FILE', s, 'golden_module_missing', '')) for s in signals)
        raw = re.sub(r'//[^\n]*', '', f.read_text(errors='replace'))
        synth = self._strip_nonsynth(raw)
        conns = self._instance_conns(synth)
        b = re.sub(r'\s+', ' ', synth)
        cut = b.index(');') if ');' in b else 4000
        ports = set(re.findall(
            r'\b(?:input|output|inout)\s+(?:wire\s+|reg\s+|logic\s+)?(?:signed\s+)?'
            r'(?:\[[^\]]*\]\s*)*(\w+)', b[:cut]))
        copy = {}
        for m in self.COPY.finditer(b):
            copy.setdefault(m.group(1), m.group(2))
        resolved, want = {}, set()
        for s in signals:
            cur, seen = s, {s}
            while cur in copy and copy[cur] not in seen:
                cur = copy[cur]
                seen.add(cur)
            resolved[s] = cur
            want.add(cur)
        pat = re.compile(r'\b(' + '|'.join(re.escape(x) for x in
                                           sorted(want, key=len, reverse=True)) + r')\b')
        hit = dict((x, None) for x in want)
        for m in pat.finditer(b):
            s = m.group(1)
            if hit.get(s):
                continue
            after, before = b[m.end():m.end() + 6], b[max(0, m.start() - 80):m.start()]
            if re.match(r'\s*<=', after):          # 自己是非阻塞赋值的目标
                continue
            if re.match(r'\s*=(?!=)', after):      # 自己是连续赋值/声明赋值的目标
                continue
            if self.PORTD.search(before):          # 端口声明本身
                continue
            if self.DECL.search(before) and re.match(r'\s*[;,]', after):
                continue                           # 光声明不赋值
            if re.search(r'\.\w+\s*\(\s*$', before):
                continue     # 实例端口连线 —— 方向未知，交给 conns 按子模块端口方向判
            hit[s] = b[max(0, m.start() - 55):m.end() + 55]
        out = {}
        for s in signals:
            r = resolved[s]
            drives_child = sorted(c for c in conns.get(r, ()) if c[2] in ('input', 'inout'))
            fed_by_child = sorted(c for c in conns.get(r, ()) if c[2] == 'output')
            if r in ports:
                out[s] = ('FEEDS_CONTROL', r, 'own_port',
                          '是本模块端口（逃出模块 = FM 比较边界）')
            elif hit[r]:
                out[s] = ('FEEDS_CONTROL', r, 'read_by_logic', clip(hit[r], 110))
            elif drives_child:
                c = drives_child[0]
                out[s] = ('FEEDS_CONTROL', r, 'drives_child_input',
                          '喂给子实例 %s 的 %s 端口（%s）' % (c[0], c[1], c[2]))
            elif fed_by_child:
                c = fed_by_child[0]
                out[s] = ('OBSERVE_ONLY', r, 'child_output_unread',
                          '只由子实例 %s 的输出 %s 驱动，本模块无人读' % (c[0], c[1]))
            else:
                out[s] = ('OBSERVE_ONLY', r, 'no_reader', '')
        return out


# ---------------------------------------------------------------- 输入表

def read_map():
    """docs/perf_bore_map.tsv -> {port: dict}"""
    rows = {}
    for ln in MAP.read_text(errors='replace').splitlines():
        if not ln or ln.startswith('#'):
            continue
        f = ln.split('\t')
        rows[f[0]] = dict(tier=f[2], holder=f[4], signal=f[5])
    return rows


def rewritten_modules():
    """可读侧声明的模块名集合（与 scripts/rewrite_coverage.py 同一判据）。"""
    out = set()
    for p in sorted((REPO / 'rtl').glob('**/*.sv')):
        out |= set(MODULE_RE.findall(p.read_text(errors='replace')))
    return out


BOUND_TIERS = ('T0_UNCHANGED', 'T1_PATH_REBIND', 'T2_CONE_PORT', 'T2_CONE_PORT_CHILD')

LEDGER_COLS = ['kind', 'scope', 'name', 'tier', 'status', 'n_bores', 'n_ctrl', 'n_gap',
               'owner_modules', 'owner_rewritten', 'criterion', 'evidence']
GAP_COLS = ['tier', 'scope', 'name', 'gap_bores', 'gap_bore_tiers', 'owner_modules',
            'owner_rewritten', 'why_excluded', 'lift_condition']

# 解除排除的条件 —— 按 bore 的 tier 分。写在这里，台账里逐条引用。
LIFT = {
    'T3_REG_LEAF': '该 bore 的 golden 组合锥展到了内部寄存器（非 FM 比较边界）。'
                   '解除条件：持有模块被重写后，在可读核里指认出等价表达式并按 '
                   'docs/hier_rebind_decl.tsv 的形式声明端口别名，使 perf_rebind.py '
                   '把它判成 T1/T2 —— 或如实裁定该 perf 语义在重写后不可复现并归档。',
    'T4_OPEN': 'perf_rebind.py 的 firtool 方言解析没把 golden 侧这条锥闭合。'
               '解除条件：补 perf_rebind.py 的解析（evidence 里点名了缺哪种写法），'
               '重跑后该 bore 落进 T1/T2/T3。',
}


def build(golden):
    ep = Endpoint(golden)
    bmap = read_map()
    fc_engine = FeedsControl(golden)

    # -- 判据 FC：按模块批量算（一次读一份 golden 文件，别按 bore 反复读）
    bymod = collections.defaultdict(set)
    for p, r in bmap.items():
        bymod[r['holder']].add(r['signal'])
    fc = {}
    for mod in sorted(bymod):
        fc[mod] = fc_engine.analyze(mod, bymod[mod])

    done = rewritten_modules()

    def bore_fact(port):
        r = bmap.get(port)
        if r is None:
            return None
        v, _res, crit, ev = fc[r['holder']][r['signal']]
        return dict(port=port, tier=r['tier'], holder=r['holder'], signal=r['signal'],
                    fc=v, fc_crit=crit, ev=ev, bound=r['tier'] in BOUND_TIERS)

    rows, gap_rows = [], []
    st = collections.Counter()

    def emit(kind, scope, name, bores, tier_hint=None, const=False, unresolved=''):
        facts = [f for f in (bore_fact(b) for b in sorted(bores)) if f]
        unknown = sorted(b for b in bores if b not in bmap)
        ctrl = [f for f in facts if f['fc'] == 'FEEDS_CONTROL']
        nofile = [f for f in facts if f['fc'] == 'NO_FILE']
        gaps = [f for f in facts if not f['bound']]
        mods = sorted(set(f['holder'] for f in facts))
        if unresolved:
            tier, crit, ev = 'X_UNRESOLVED', unresolved, ''
        elif const:
            tier, crit, ev = 'D_CONST', 'print_arg_is_literal', clip(str(const), 60)
        elif unknown:
            tier, crit, ev = ('X_UNRESOLVED', 'bore_not_in_perf_bore_map:' + unknown[0], '')
        elif nofile:
            tier, crit, ev = ('X_UNRESOLVED',
                              'golden_module_missing:' + nofile[0]['holder'], '')
        elif tier_hint:
            tier = tier_hint
            if facts:
                crit = 'assert_is_cycle_visible_behavior'
                ev = clip(ctrl[0]['ev'], 110) if ctrl else ''
            else:
                # 实测 15 条：条件是 `wire _GEN_15 = (`PRINTF_COND_) & 1'h0;`
                # —— golden 里就恒 0，两侧同样不会响。不是"漏掉了 bore"。
                crit = 'assert_cond_no_bore'
                ev = 'golden 里这条断言的条件不依赖任何 bore（如恒 0），两侧同样不会响'
        elif not facts:
            tier = 'D_INVARIANT'
            crit = 'no_bore_in_backward_cone'
            ev = '值只由 endpoint 自身计数状态与 io_timer/io_clean/io_dump/reset 决定'
        elif ctrl:
            tier = 'B_CONTROL'
            crit = 'FC/%s:%s.%s' % (ctrl[0]['fc_crit'], ctrl[0]['holder'], ctrl[0]['signal'])
            ev = clip(ctrl[0]['ev'], 110)
        else:
            tier = 'C_DIAG'
            crit = 'FC/%s:全部 %d 条 bore 都不馈入控制' % (
                '+'.join(sorted(set(f['fc_crit'] for f in facts))), len(facts))
            ev = clip('%s.%s %s' % (facts[0]['holder'], facts[0]['signal'],
                                    facts[0]['ev']), 110)

        if tier in ('D_CONST', 'D_INVARIANT'):
            status = 'BY_CONSTRUCTION'
        elif gaps:
            status = 'GAP'
        else:
            status = 'MEASURED'

        rw = '-'
        if mods:
            k = sum(1 for m in mods if m in done)
            rw = 'yes' if k == len(mods) else ('no' if k == 0 else 'partial')
        rows.append([kind, scope, name, tier, status, str(len(facts)), str(len(ctrl)),
                     str(len(gaps)),
                     clip(' '.join(mods[:4]) + ('' if len(mods) <= 4 else ' +%d' % (len(mods) - 4)), 90),
                     rw, clip(crit, 120), ev])
        st[tier] += 1
        st['status:' + status] += 1
        if status == 'GAP':
            gt = sorted(set(f['tier'] for f in gaps))
            gap_rows.append([tier, scope, name,
                             clip(' '.join(f['port'] for f in gaps[:6]) +
                                  ('' if len(gaps) <= 6 else ' +%d' % (len(gaps) - 6)), 110),
                             ' '.join(gt),
                             clip(' '.join(sorted(set(f['holder'] for f in gaps))[:4]), 80), rw,
                             '这条计数器有 %d/%d 条 bore 没能重绑；生成的 SimTop 给它们接 `\'0`，'
                             'impl 侧印出来的数不是测量值。★不许当 MATCH 计★'
                             % (len(gaps), len(facts)),
                             clip(' / '.join(LIFT[t] for t in gt), 400)])

    # -- PERF 计数器
    # ★同一个 (scope, name) 可能被 $fwrite **打印多次**（实测 27921 条打印项只对应
    #   25519 个计数器）。perf_compare 按 (scope, name) 取最后一次，所以台账也必须
    #   按这个键合并 —— 合并时取 bore 的**并集**（保守方向：多一条未绑 bore 就算 GAP）。
    agg = collections.OrderedDict()
    for scope, name, arg in ep.perf_counters():
        e = agg.setdefault((scope, name),
                           dict(bores=set(), const=None, bad=None, allconst=True))
        if arg is None:
            e['bad'] = 'fwrite_fmt_args_misaligned'
            e['allconst'] = False
            continue
        a = arg.strip()
        names = ids(a)
        if not names:                      # 实参是字面量（例如 `64'h0`）
            if e['const'] is None:
                e['const'] = a
            continue
        e['allconst'] = False
        for x in names:
            if BORE.match(x):
                e['bores'].add(x)
            else:
                e['bores'] |= ep.bores_of(x)
        # 实参里的名字一个都不在 endpoint 的数据流里 —— 没见过的写法，让闸响。
        if not any(x in ep.drv or BORE.match(x) for x in names) and e['bad'] is None:
            e['bad'] = 'print_arg_net_unknown:' + names[0]
    for (scope, name), e in agg.items():
        if e['bad']:
            emit('PERF', scope, name, set(), unresolved=e['bad'])
        elif e['allconst']:
            emit('PERF', scope, name, set(), const=e['const'])
        else:
            emit('PERF', scope, name, e['bores'])

    # -- 断言
    for (scope, msg), bores in ep.asserts().items():
        emit('ASSERT', scope, msg, bores, tier_hint='A_FUNC_ASSERT')

    rows.sort(key=lambda r: (r[0], r[1], r[2]))
    gap_rows.sort(key=lambda r: (r[1], r[2]))

    hdr = [
        '# perf_tier_ledger.tsv —— perf 观测**分档**台账（codex 0162 D3）。',
        '#（scripts/perf_tier.py 生成；禁止手改。复算: python3 scripts/perf_tier.py）',
        '# 判据写在 scripts/perf_tier.py 头部，这里只复述结论口径：',
        '#   A_FUNC_ASSERT  golden 断言（cycle-visible 功能行为）          → 必须相等',
        '#   B_CONTROL      至少一条 bore 馈入控制（判据 FC，含 PMU 可见）→ 必须相等',
        '#   C_DIAG         全部 bore 都不馈入控制（纯观测探针）          → 显式归类后允许不同',
        '#   D_CONST        打印的实参是 golden 字面量                    → 恒等',
        '#   D_INVARIANT    反向闭包里没有 bore（只由 endpoint 自身状态定）→ 同 dump 时刻下恒等',
        '#   X_UNRESOLVED   判不出来 → ★闸红★（不许有"未分类"悄悄存在）',
        '# status: MEASURED 全部 bore 都绑上了 / GAP 有 bore 未绑（impl 侧是假零，',
        '#         ★不许当 MATCH 计★，逐条见 docs/perf_gap_ledger.tsv）/',
        '#         BY_CONSTRUCTION 不经过 bore',
        '# owner_rewritten: 持有模块本轮是否已重写（yes/no/partial）—— codex 0162 D3 的豁免',
        '#         "They do not block the current rewritten slice when the owning modules',
        '#         are unchanged" 就是靠这一列判的。',
        '#',
    ]
    for t in ('A_FUNC_ASSERT', 'B_CONTROL', 'C_DIAG', 'D_CONST', 'D_INVARIANT', 'X_UNRESOLVED'):
        hdr.append('# tier %-14s %6d' % (t, st[t]))
    for t in ('MEASURED', 'GAP', 'BY_CONSTRUCTION'):
        hdr.append('# status %-13s %6d' % (t, st['status:' + t]))
    hdr.append('# total %20d' % len(rows))
    hdr.append('\t'.join(LEDGER_COLS))
    led = '\n'.join(hdr + ['\t'.join(r) for r in rows]) + '\n'

    ghdr = [
        '# perf_gap_ledger.tsv —— **测不了**的 perf 观测台账（scripts/perf_tier.py 生成）。',
        '# codex 0162 D3: "Do not claim full performance-observation equivalence while',
        '#   counters remain EXCLUDED. Keep those as a visible follow-up ledger, not zeros',
        '#   counted as matches."',
        '#',
        '# 本工程的教训（写在这里，因为它正是这张表存在的理由）：',
        '#   最早整芯片仿真把 9897 条 XMR **全部**接 `\'0`，功能 smoke 能跑，代价是 impl 侧',
        '#   perf 计数器全灭。0 是个合法的数字，`diff` 分不出"没发生"和"没接上"。',
        '#   接零不是等价，是把问题藏起来。这张表把每一条藏起来的都摆出来。',
        '#',
        '# tier          该计数器**本来的**要求档（B_CONTROL 的 GAP 比 C_DIAG 的 GAP 严重得多）',
        '# gap_bores     这条计数器里没能重绑的 bore 端口（超过 6 条只列前 6 条 + 余数）',
        '# lift_condition 什么条件下这条能从"排除"里出来 —— 按 bore 的 tier 给，不是空话',
        '#',
    ]
    gst = collections.Counter(r[0] for r in gap_rows)
    for t in sorted(gst):
        ghdr.append('# gap tier %-14s %6d' % (t, gst[t]))
    ghdr.append('# gap total %17d' % len(gap_rows))
    ghdr.append('\t'.join(GAP_COLS))
    gl = '\n'.join(ghdr + ['\t'.join(r) for r in gap_rows]) + '\n'
    return led, gl, st, len(rows), len(gap_rows)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--golden', default=GOLDEN_DEFAULT)
    ap.add_argument('--check', action='store_true', help='只校验台账与重算结果逐字节一致')
    a = ap.parse_args()
    led, gl, st, n, ng = build(a.golden)
    if a.check:
        bad = 0
        for path, text in ((LEDGER, led), (GAPLEDGER, gl)):
            if not path.exists():
                print('FAIL: %s 不存在' % path)
                bad = 1
            elif path.read_text() != text:
                print('FAIL: %s 与重算结果不一致（DRIFT）' % path)
                bad = 1
        if st['X_UNRESOLVED']:
            print('FAIL: %d 个计数器 X_UNRESOLVED —— 未分类不许存在'
                  % st['X_UNRESOLVED'])
            bad = 1
        if bad:
            return 1
        print('perf_tier --check: %d 条台账逐字节一致，X_UNRESOLVED=0' % n)
        return 0
    LEDGER.write_text(led)
    GAPLEDGER.write_text(gl)
    for t in ('A_FUNC_ASSERT', 'B_CONTROL', 'C_DIAG', 'D_CONST', 'D_INVARIANT', 'X_UNRESOLVED'):
        print('  %-14s %6d' % (t, st[t]))
    print('  ---- status')
    for t in ('MEASURED', 'GAP', 'BY_CONSTRUCTION'):
        print('  %-14s %6d' % (t, st['status:' + t]))
    print('  已写 %s (%d 行) 与 %s (%d 行)' % (LEDGER, n, GAPLEDGER, ng))
    print('  sha256 %s  %s' % (hashlib.sha256(led.encode()).hexdigest(), LEDGER.name))
    print('  sha256 %s  %s' % (hashlib.sha256(gl.encode()).hexdigest(), GAPLEDGER.name))
    return 0


if __name__ == '__main__':
    sys.exit(main())
