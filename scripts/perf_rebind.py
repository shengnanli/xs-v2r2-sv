#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""perf_rebind.py —— 把 golden SimTop 的 9897 条 perf 观测层次引用(XMR)重新绑到重写层次。

## 这个脚本解决的问题

golden `SimTop.sv` 用 **9897 条绝对层次引用**把各模块内部信号引到 `LogPerfEndpoint`
（9903 端口全 input，纯观测 sink：8822 条喂性能计数器、513 条喂直方图/最大值使能、
453+109 条喂断言条件与其打印负载）。重写件内部命名与 golden 不同，其中 **769 条**
接不上（507 条信号名在重写模块里不存在，262 条中间实例名对不上）。

当前整芯片仿真的做法是把这 9897 条**全部**接 `'0`：功能 smoke 能跑，但 impl 侧
**全部** perf 计数器变成 0 —— 也就是说 perf 一致性验证没有地基。codex 0160 P2 的
要求是：能重绑的重绑，**判不出来的显式归类，不许编零**。

## 五级绑定（每级的证据强度不同，写进表里，不混着报）

  T0_UNCHANGED      路径与信号在 impl 侧原样存在 —— 这条 XMR 一个字都不用改。
                    （9128 条：其中 9126 条落在本轮未重写的 golden 模块里。）
  T1_PATH_REBIND    信号名原样存在，但**承载它的实例路径变了**（重写父模块把子模块
                    收进了 `u_core`，或收成 generate 例化点）。只改路径前缀，
                    观测到的还是同一根线 —— 与 golden **逐位相同**。
  T2_CONE_PORT      信号本身在重写模块里没有了（golden 的 `_GEN_n` 是 firtool 的
                    扁平中间量），但把 golden 那条组合锥一路展开，**叶子全是该模块
                    的端口**。端口是 FM 签核的比较边界：端口逐拍相等 ⇒ 用同一组端口
                    按 golden 原样重算出来的这根线也逐拍相等。做法是把 golden 的
                    锥**原样复制**进适配器（连位宽声明一起抄），只把叶子引用重新指到
                    重写层次 —— 所以它是「换个地方观测」，不是「近似」。
  T2_CONE_PORT_CHILD 同上，但叶子里还有**子实例的端口**（firtool 把子模块输出记成
                    `_<inst>_<port>` 线网）。子实例端口同样是签核边界，同级证据。
                    展锥时还认一条：golden 里 `assign io_x = w;` 就把内部线 `w`
                    当成端口 `io_x`（例 WrBypass 的 `hit`/`io_hit`）。不认这条的话
                    锥会一路展到 `ever_written_*` 这些内部寄存器，WrBypass 家族
                    92 条 bore 会被误判成「判不准」。
  T3_REG_LEAF       组合锥展到了 golden 模块的**内部寄存器**。寄存器不是签核边界，
                    重写件的状态编码可以合法地不同 —— 机器**判不出**对应物。
  T4_OPEN           连 golden 侧的锥都没能闭合（本脚本的 firtool 方言解析没覆盖到的
                    形态）。如实记成「判不准」，不猜。

T3/T4 **不接一个假零就当验过**：它们进 `docs/perf_bore_unbound.tsv`，
`scripts/perf_compare.py` 读这张表，把受影响的计数器标成 EXCLUDED 而不是 0 == 0。

## 证据链

  * golden 侧语义名来自 `LogPerfEndpoint.sv` 自己的 `$fwrite` —— 每个计数器都带
    `<golden 层次路径>: <事件名>`，断言带完整消息。不是猜的名字。
  * 路径重绑复用 `scripts/hier_map.py` 的 `Model.auto()`（与 `docs/hier_rebind_map.tsv`
    同一套判据），逐层走，不做跨层猜测。
  * 组合锥从 `$(GOLDEN)/<模块>.sv` 现场解析，锥里每根中间线的**位宽声明原样保留**
    —— 直接内联表达式会把 firtool 的截位语义弄丢（`wire [2:0] a = b + c;`
    内联进 64 位上下文就不截了），所以是复制声明而不是内联。

用法:
  python3 scripts/perf_rebind.py                      # 重算两张表
  python3 scripts/perf_rebind.py --check              # 幂等闸（表与源码一致？）
  python3 scripts/perf_rebind.py --emit-simtop OUT.sv # 生成重绑后的 SimTop
"""
from __future__ import print_function

import argparse
import collections
import os
import pathlib
import re
import sys

HERE = pathlib.Path(__file__).resolve().parent
REPO = HERE.parent
sys.path.insert(0, str(HERE))
import hier_map as HM                                               # noqa: E402

GOLDEN_DEFAULT = '/home/eda/xs-env/G1-canonical/golden-rtl'
MAP = REPO / 'docs' / 'perf_bore_map.tsv'
UNBOUND = REPO / 'docs' / 'perf_bore_unbound.tsv'

MAP_COLS = ['port', 'family', 'tier', 'golden_xmr', 'golden_holder', 'golden_signal',
            'impl_holder', 'impl_bind', 'perf_kind', 'perf_scope', 'perf_name', 'evidence']
UNBOUND_COLS = ['perf_kind', 'perf_scope', 'perf_name', 'tier', 'gap_class', 'ports',
                'next_step', 'reason']

# codex 0160 P2 要的「显式归类」。三类互斥，判据写在这里，不靠读的人自己揣摩。
GAP = {
    'ABSORBED_RENAMED': (
        '语义还在，名字变了：可读核里确实有对应的那条线/端口，只是不再叫 golden 的名字',
        '人工确认可读核里的对应信号，按 docs/hier_rebind_decl.tsv 的形式补一条端口别名声明'),
    'NO_SIGNOFF_BOUNDARY': (
        'golden 的这条 perf 中间量是从**内部寄存器**算出来的；寄存器不是 FM 的比较边界，'
        '重写件的状态编码可以合法地不一样，机器判不出对应物',
        '要么人工在可读核里找出等价表达式并给出证据，要么如实承认这条 perf 语义在重写后不可复现'),
    'PARSER_GAP': (
        '本脚本的 firtool 方言解析没把 golden 侧这条锥闭合 —— 是工具的洞，不是设计的洞',
        '补 perf_rebind.py 的 golden 解析（缺哪种写法，evidence 里点名了）'),
}

BOUND_TIERS = ('T0_UNCHANGED', 'T1_PATH_REBIND', 'T2_CONE_PORT', 'T2_CONE_PORT_CHILD')

MAP_HDR = [
    '# perf_bore_map.tsv —— golden SimTop 的 9897 条 perf 观测 XMR → 重写层次绑定',
    '#（scripts/perf_rebind.py 生成；禁止手改）',
    '# tier: T0_UNCHANGED 路径信号都没变 / T1_PATH_REBIND 只有路径变了（逐位同线）/',
    '#       T2_CONE_PORT 组合锥叶子全是本模块端口（复制锥，换叶子）/',
    '#       T2_CONE_PORT_CHILD 叶子含子实例端口（同级证据）/',
    '#       T3_REG_LEAF 锥展到 golden 内部寄存器 —— 不是签核边界，机器判不出对应物 /',
    '#       T4_OPEN golden 侧锥没闭合 —— 判不准，如实留白',
    '# impl_bind: T0/T1 = 完整 impl XMR；T2* = 该锥的输出线名（锥体见生成的 SimTop）；',
    '#            T3/T4 = 空（★不接零冒充已验★，见 docs/perf_bore_unbound.tsv）',
    '# perf_kind: PERF = 性能计数器（perf_scope/perf_name 取自 LogPerfEndpoint 自己的',
    '#            $fwrite 打印串）/ ASSERT = 断言条件或其打印负载',
]
UNBOUND_HDR = [
    '# perf_bore_unbound.tsv —— **没能重绑**的 perf 计数器/断言（scripts/perf_rebind.py 生成）',
    '# 这张表的存在意义：重绑不了的 XMR 在生成的 SimTop 里仍然接 `\'0`（不接它编不过），',
    '# 于是那个计数器会**打印出一个 0**。0 不是测量值。scripts/perf_compare.py 必须读',
    '# 这张表，把这里列出的计数器标成 EXCLUDED，而不是拿 0 去和 golden 比「相等」。',
    '# ports = 该计数器里落在 T3/T4 的 bore 端口（一个计数器可能由多条 bore 累加）',
    '# gap_class（codex 0160 P2 要的显式归类，三类互斥）：',
] + ['#   %-20s %s' % (k, v[0]) for k, v in sorted(GAP.items())]


# ---------------------------------------------------------------- golden 侧解析

class Golden(object):
    """按需解析 golden 单模块：端口 / 组合定义 / 寄存器 / 子实例。"""

    _INST = re.compile(r'^[ \t]{2,}([A-Za-z_]\w*)[ \t]+([A-Za-z_]\w*)[ \t]*\([ \t]*$', re.M)
    _LIT = re.compile(r"\b\d+'[sS]?[hHdDbBoO][0-9a-fA-FxXzZ_]+")
    _ID = re.compile(r'\b[A-Za-z_]\w*\b')
    _KW = set('''wire reg logic assign input output inout module endmodule begin end if else
case endcase always always_ff always_comb posedge negedge initial parameter localparam signed
unsigned for while function endfunction task endtask return default'''.split())

    def __init__(self, root):
        self.root = pathlib.Path(root)
        self._c = {}

    def mod(self, name):
        if name in self._c:
            return self._c[name]
        f = self.root / (name + '.sv')
        if not f.exists():
            self._c[name] = None
            return None
        t = f.read_text(errors='replace')
        cut = t.index(');\n') if ');\n' in t else min(len(t), 4000)
        ports = set(re.findall(r'^\s*(?:input|output|inout)\s+(?:\[[^\]]*\]\s*)?(\w+)',
                               t[:cut], re.M))
        insts = {m.group(2): m.group(1) for m in self._INST.finditer(t)}
        # ★位宽字面量必须原样留在 RHS 里★：`{1'h0, x}` 被替换成 `{ 0 , x}` 就不再是
        # 同一个表达式（拼接宽度全变）。所以 body 保留字面量，只在**扫标识符**时
        # 临时把 `3'h1` 这种去掉（否则 `h1` 会被当成一个信号名）。
        body = re.sub(r'\s+', ' ', re.sub(r'//[^\n]*', '', t))
        defs, decl = {}, {}
        # 多维打包声明要全吃下：firtool 会写 `wire [511:0][2:0] _GEN_9 = …`
        # （Chisel Vec 展平）。只认一维的话这些名字会变成「解析不出来」，
        # 于是一条本该归到 NO_SIGNOFF_BOUNDARY 的缺口被误报成工具的洞。
        for m in re.finditer(r'\bwire\s+((?:\[[^\]]*\]\s*)*)(\w+)\s*=\s*([^;]*);', body):
            if m.group(2) not in defs:
                defs[m.group(2)] = m.group(3).strip()
                decl[m.group(2)] = (m.group(1) or '').strip()
        for m in re.finditer(r'\bassign\s+(\w+)\s*=\s*([^;]*);', body):
            if m.group(1) not in defs:
                defs[m.group(1)] = m.group(2).strip()
                decl[m.group(1)] = ''
        regs = set(re.findall(r'\breg\s+(?:\[[^\]]*\]\s*)*(\w+)\s*[;=]', body))
        # ★内部线若被原样赋给某个输出端口，就当它是那个端口★。
        # 例：golden WrBypass 的 `wire hit = …;  assign io_hit = hit;` —— `hit` 的锥
        # 会一路展到 ever_written_* 这些内部寄存器（非签核边界，判不出对应物），
        # 但 `hit` 本身**就是** io_hit，而端口是 FM 的比较边界。少了这一步，
        # WrBypass 家族 92 条 bore 会全被误判成「判不准」。
        alias = {}
        for m in re.finditer(r'\bassign\s+(\w+)\s*=\s*([A-Za-z_]\w*)\s*;', body):
            if m.group(1) in ports and m.group(2) not in ports:
                alias.setdefault(m.group(2), m.group(1))
        self._c[name] = dict(ports=ports, insts=insts, defs=defs, decl=decl, regs=regs,
                             alias=alias)
        return self._c[name]

    def ids(self, expr):
        """表达式里的标识符。先剥掉 `3'h1` 这类带位宽的字面量，否则 `h1` 会冒充信号名。"""
        return [i for i in self._ID.findall(self._LIT.sub(' ', expr)) if i not in self._KW]

    def child_of(self, m, s):
        """firtool 把子模块输出记成 `_<inst>_<port>` 线网；还原成 (inst, port)。"""
        if not s.startswith('_'):
            return None
        b, best = s[1:], None
        for i in m['insts']:
            if b.startswith(i + '_') and (best is None or len(i) > len(best[0])):
                best = (i, b[len(i) + 1:])
        return best

    def cone(self, name, sig, limit=600):
        """返回 (判定, 叶子集合, 拓扑序的中间线列表)。"""
        m = self.mod(name)
        if m is None:
            return ('T4_OPEN', [], [], 'golden 侧找不到 %s.sv' % name)
        if sig in m['ports']:
            return ('PORT', ['PORT:' + sig], [], '')
        seen, leaves, order, stack = set(), set(), [], [sig]
        while stack:
            s = stack.pop()
            if s in seen:
                continue
            seen.add(s)
            if len(seen) > limit:
                return ('T4_OPEN', [], [], '组合锥超过 %d 个节点，未展开' % limit)
            if s in m['ports']:
                leaves.add('PORT:' + s)
                continue
            if s in m['alias']:
                leaves.add('ALIAS:%s=%s' % (s, m['alias'][s]))
                continue
            if s in m['defs']:
                order.append(s)
                for i in set(self.ids(m['defs'][s])):
                    stack.append(i)
                continue
            cp = self.child_of(m, s)
            if cp:
                leaves.add('CHILD:%s.%s' % cp)
                continue
            if s in m['regs']:
                leaves.add('REG:' + s)
                continue
            leaves.add('OPEN:' + s)
        kinds = set(('PORT' if x.startswith('ALIAS:') else x.split(':', 1)[0])
                    for x in leaves)
        if 'OPEN' in kinds:
            bad = sorted(x.split(':', 1)[1] for x in leaves if x.startswith('OPEN:'))
            return ('T4_OPEN', sorted(leaves), order,
                    'golden 锥里这些名字解析不出来: ' + ' '.join(bad[:4]))
        if 'REG' in kinds:
            bad = sorted(x.split(':', 1)[1] for x in leaves if x.startswith('REG:'))
            return ('T3_REG_LEAF', sorted(leaves), order,
                    'golden 内部寄存器叶子（非签核边界）: ' + ' '.join(bad[:4]))
        if 'CHILD' in kinds:
            return ('T2_CONE_PORT_CHILD', sorted(leaves), order, '')
        return ('T2_CONE_PORT', sorted(leaves), order, '')

    @staticmethod
    def leaf_is_portclass(k):
        return k in ('PORT', 'ALIAS')


# ---------------------------------------------------------------- LogPerfEndpoint 语义

def endpoint_semantics(golden_root):
    """从 LogPerfEndpoint.sv 自己的 $fwrite 里取出每个 bore 端口的语义名。

    ★不靠猜★：`[PERF ][time=%d] <路径>: <事件名>, %d` 的格式串与参数表逐项对齐，
    参数里出现哪个 bore 端口，那个端口就属于那个计数器；`[ERROR]` 块同理给断言。
    """
    raw = (pathlib.Path(golden_root) / 'LogPerfEndpoint.sv').read_text(errors='replace')
    body = raw[raw.index(');\n'):]
    flat = re.sub(r'\s+', ' ', body)
    ident = re.compile(r'\b[A-Za-z_]\w*\b')
    bore = re.compile(r'\b((?:perfCnt|enable|x1|x2)_bore(?:_\d+)?)\b')

    port2stmt = {}
    for s in flat.split(';'):
        for b in set(bore.findall(s)):
            port2stmt.setdefault(b, s.strip())

    writes = re.findall(
        r'\$fwrite\(32\'h80000002, ("(?:[^"\\]|\\.)*"(?:\s*,\s*"(?:[^"\\]|\\.)*")*)\s*,?\s*([^;]*)\)',
        flat)
    id2perf = collections.defaultdict(list)
    port2assert = {}
    for fmtq, args in writes:
        fmt = ''.join(re.findall(r'"((?:[^"\\]|\\.)*)"', fmtq))
        if '[PERF ]' in fmt:
            ents = re.findall(r'\[PERF \]\[time=%d\] ([^:]+): ([^,]+), %d', fmt)
            data = [a.strip() for a in args.split(',') if a.strip() and a.strip() != 'io_timer']
            if len(ents) != len(data):
                continue
            for (scope, name), d in zip(ents, data):
                for i in ident.findall(d):
                    id2perf[i].append((scope.strip(), name.strip()))
        elif '[ERROR]' in fmt:
            mm = re.match(r'\[ERROR\]\[time=%d\] ([^:]+): (.*)', fmt)
            scope, msg = (mm.group(1), mm.group(2)) if mm else ('', fmt)
            for a in args.split(','):
                for i in ident.findall(a):
                    if i.startswith(('x1_bore', 'x2_bore')):
                        port2assert.setdefault(i, (scope.strip(), msg.strip()[:160]))

    sem = {}
    for port, stmt in port2stmt.items():
        if port.startswith(('x1_bore', 'x2_bore')):
            scope, msg = port2assert.get(port, ('', '(只用作条件，未单独打印)'))
            sem[port] = ('ASSERT', scope, msg)
            continue
        hit = None
        for i in dict.fromkeys(ident.findall(stmt)):
            if i in id2perf:
                hit = id2perf[i][0]
                break
        sem[port] = ('PERF', hit[0], hit[1]) if hit else ('PERF', '', '(未能从打印串定位)')
    return sem


def simtop_bores(golden_root):
    """SimTop 里 logEndpoint 的端口 → golden XMR。"""
    st = (pathlib.Path(golden_root) / 'SimTop.sv').read_text(errors='replace')
    i = st.index('LogPerfEndpoint logEndpoint (')
    j = st.index('\n  );', i)
    out = []
    for port, val in re.findall(r'\.(\w+)\s*\n?\s*\(\s*([^()]*?)\s*\)', st[i:j]):
        if val.startswith('SimTop.'):
            out.append((port, val))
    return out


# ---------------------------------------------------------------- 层次翻译

class Rebinder(object):
    def __init__(self, golden_root, filelist):
        self.M = HM.Model(golden_root, filelist, top='SimTop')
        self.G = Golden(golden_root)
        # ★声明优先，与 hier_map.build_rows 同序★：机器判定只能判到「唯一 generate
        # 例化点」，两层下标（TageTable 的 bank_wrbypasses_A_B → g_wb_bank[A].g_wb_br[B]）
        # 它明确拒绝猜，那一步正是 docs/hier_rebind_decl.tsv 在补。这里若只用
        # auto()，那些槽位会退化成带 genvar 的非法路径，凭空多出两百多条「判不准」。
        self.decl = collections.defaultdict(list)
        for d in HM.load_decl():
            self.decl[(d['owner'], d['golden_child'])].append(d)
        rtl = str((REPO / 'rtl').resolve())
        self.rewritten = set(self.M.rewritten)
        self.impl_words = {}
        self.impl_ports = {}
        for line in pathlib.Path(filelist).read_text().splitlines():
            s = line.strip()
            if not s:
                continue
            self._scan_words(s)
        self._scan_words(str(pathlib.Path(golden_root) / 'SimTop.sv'))
        self.rtl = rtl

    _DIR = re.compile(r'^[ \t]*(input|output|inout)\b(.*)$')
    _PTYPE = set('input output inout wire reg logic signed unsigned bit var'.split())

    def _scan_ports(self, text, name):
        """模块头里的端口名。★必须真解析★：`xs_*` 可读核的端口名与 golden **不一样**
        （golden `io_commonOut_entryInValid` ↔ 可读核 `enq_valid`），拿 golden 的名字
        去 XMR 只会 Error-[XMRE]。所以每片叶子都要先在 impl 端口表里查得到。"""
        out = set()
        for ln in text.splitlines():
            m = self._DIR.match(ln)
            if not m:
                continue
            rest = re.sub(r'\[[^\]]*\]', ' ', m.group(2))
            rest = rest.split('//')[0].replace(',', ' ').replace(')', ' ').replace(';', ' ')
            for w in re.findall(r'[A-Za-z_]\w*', rest):
                if w not in self._PTYPE:
                    out.add(w)
        self.impl_ports[name] = out

    def _scan_words(self, path):
        try:
            t = pathlib.Path(path).read_text(errors='replace')
        except Exception:
            return
        cur, buf = None, []
        for ln in t.splitlines():
            if cur is None:
                m = re.match(r'^[ \t]*module[ \t]+([A-Za-z_]\w*)', ln)
                if m:
                    cur, buf = m.group(1), []
            elif re.match(r'^[ \t]*endmodule\b', ln):
                body = '\n'.join(buf)
                # ★要的是「声明过这个名字」，不是「文本里出现过这个名字」★：
                # 注释里的 `_GEN_5`、别的表达式里的子串都不算数，拿去做 XMR 会 XMRE。
                self.impl_words[cur] = set(re.findall(
                    r'\b(?:wire|reg|logic|bit|integer|genvar)\b[^;=\n]*?'
                    r'\b([A-Za-z_]\w*)\s*(?:[;=,\[]|$)', body, re.M))
                self.impl_words[cur] |= set(re.findall(
                    r'^[ \t]*(?:wire|reg|logic)\b[^;\n]*', body, re.M) and [])
                hdr = body.split(');', 1)[0]
                self._scan_ports(hdr, cur)
                self.impl_words[cur] |= self.impl_ports[cur]
                cur = None
            else:
                buf.append(ln)

    @staticmethod
    def resolvable(path):
        """impl 路径里还留着 genvar（`g_wb_bank[gb]`）就不是一条能用的层次引用。

        `hier_map.py` 的 GEN_SITE_UNINDEXED 明说「找到了 generate 例化点但拆不出
        下标」。那种路径**不能**当成绑定成功 —— 它连语法上都不是合法 XMR。
        """
        return all(x.isdigit() for x in re.findall(r'\[([^\]]*)\]', path))

    def step(self, gmod, imod, inst):
        """一层：golden (gmod, inst) → impl 相对路径 + 两侧子模块名。"""
        gchild = self.M.g1.slot.get((gmod, inst))
        if gchild is None:
            return None
        for d in self.decl.get((gmod, gchild), ()):
            m = re.fullmatch(d['golden_inst_re'], inst)
            if not m:
                continue
            if d['kind'] != 'INSTANCE':      # INLINE*：不再是一条实例路径
                return None
            idx = tuple(int(g) if g else 0 for g in m.groups()) or (0,)
            return (HM.subst_index(d['impl_path'], *idx), gchild, d['impl_module'],
                    'DECLARED')
        fam = [i for t, i in self.M.g1.kids.get(gmod, ()) if t == gchild]
        r = self.M.auto(imod, inst, gchild, fam)
        if r is None:
            return None
        cls, hp, ty, _how = r
        return (hp, gchild, ty, cls)

    def walk(self, xmr):
        """SimTop.a.b.c.sig → (impl 路径段, golden 持有模块, impl 持有模块, 信号)。"""
        segs = xmr.split('.')[1:]
        gmod, imod, ip = 'SimTop', 'SimTop', []
        for seg in segs[:-1]:
            r = self.step(gmod, imod, seg)
            if r is None:
                return None, gmod, imod, segs[-1], seg
            hp, gchild, ity, _ = r
            if not self.resolvable(hp):
                return None, gmod, imod, segs[-1], '%s（generate 下标未确立: %s）' % (seg, hp)
            ip += hp.split('.')
            gmod, imod = gchild, ity
        return ip, gmod, imod, segs[-1], None


# ---------------------------------------------------------------- 主流程

def classify(rb, sem, bores):
    rows, cones = [], {}
    for port, xmr in bores:
        fam = re.sub(r'_\d+$', '', port)
        kind, scope, name = sem.get(port, ('PERF', '', '(未知)'))
        ip, gmod, imod, sig, stuck = rb.walk(xmr)
        if ip is None:
            rows.append(dict(port=port, family=fam, tier='T4_OPEN', golden_xmr=xmr,
                             golden_holder=gmod, golden_signal=sig, impl_holder='',
                             impl_bind='', perf_kind=kind, perf_scope=scope,
                             perf_name=name,
                             evidence='层次翻译卡在段 `%s`（%s 下找不到对应例化点）'
                                      % (stuck, imod)))
            continue
        implpath = 'SimTop.' + '.'.join(ip + [sig])
        has = sig in rb.impl_words.get(imod, ())
        if has:
            tier = 'T0_UNCHANGED' if implpath == xmr else 'T1_PATH_REBIND'
            ev = '' if tier == 'T0_UNCHANGED' else \
                'impl 侧同名信号仍在 %s 里，只是实例路径变了' % imod
            rows.append(dict(port=port, family=fam, tier=tier, golden_xmr=xmr,
                             golden_holder=gmod, golden_signal=sig, impl_holder=imod,
                             impl_bind=implpath, perf_kind=kind, perf_scope=scope,
                             perf_name=name, evidence=ev))
            continue
        verdict, leaves, order, why = rb.G.cone(gmod, sig)
        if verdict == 'PORT':                    # 端口名本身在 impl 侧丢了：不该发生
            verdict, why = 'T4_OPEN', 'golden 端口 %s 在 impl 模块 %s 里找不到' % (sig, imod)
        if verdict.startswith('T2'):
            # ★叶子必须在这里就解出来★：只要有一片叶子在 impl 侧指不到，这条锥就
            # 生成不出来。若留到生成 SimTop 时才发现并跳过，表里会写着「已绑定」
            # 而 SimTop 里那根线根本没声明 —— 表说谎，编译报 undefined。
            base = 'SimTop.' + '.'.join(ip)
            sub, bad = {}, []
            for lf in leaves:
                k, v = lf.split(':', 1)
                if k in ('PORT', 'ALIAS'):
                    # ALIAS:<golden 内部线>=<它驱动的输出端口>
                    w, prt = v.split('=', 1) if k == 'ALIAS' else (v, v)
                    if prt in rb.impl_ports.get(imod, ()):
                        sub[w] = base + '.' + prt
                    else:
                        bad.append('%s.%s(端口不存在)' % (imod, prt))
                    continue
                ci, cp = v.split('.', 1)
                r = rb.step(gmod, imod, ci)
                if r is None or not rb.resolvable(r[0]):
                    bad.append(ci + '(实例定位不到)')
                elif cp not in rb.impl_ports.get(r[2], ()):
                    bad.append('%s:%s.%s(端口名在可读核里变了)' % (ci, r[2], cp))
                else:
                    sub['_%s_%s' % (ci, cp)] = base + '.' + r[0] + '.' + cp
            if bad:
                rows.append(dict(port=port, family=fam, tier='T4_OPEN', golden_xmr=xmr,
                                 golden_holder=gmod, golden_signal=sig, impl_holder=imod,
                                 impl_bind='', perf_kind=kind, perf_scope=scope,
                                 perf_name=name,
                                 evidence='组合锥的叶子在 impl 侧接不上: '
                                          + ' '.join(sorted(set(bad))[:4])))
                continue
            wire = 'xs_pb_%s' % port
            cones[port] = dict(golden_holder=gmod, sig=sig, order=order, sub=sub,
                               ippath=ip, imod=imod, wire=wire)
            rows.append(dict(port=port, family=fam, tier=verdict, golden_xmr=xmr,
                             golden_holder=gmod, golden_signal=sig, impl_holder=imod,
                             impl_bind=wire, perf_kind=kind, perf_scope=scope,
                             perf_name=name,
                             evidence='复制 golden %s 的 %d 行组合锥，叶子重指到 %s'
                                      % (gmod, len(order), base)))
            continue
        rows.append(dict(port=port, family=fam, tier=verdict, golden_xmr=xmr,
                         golden_holder=gmod, golden_signal=sig, impl_holder=imod,
                         impl_bind='', perf_kind=kind, perf_scope=scope, perf_name=name,
                         evidence=why))
    return rows, cones


def hint(rb, imod, perf_name, leafnames):
    """给未绑的那条 perf 一个**线索**：可读核里有没有名字对得上的信号。

    只是线索，不是结论 —— 不写进 impl_bind，也不参与绑定率。之所以要它：
    「判不准」如果只给一句「判不准」，下一个人还得从头查一遍；而实测这些缺口里
    有相当一部分是「语义还在、名字变了」（例：golden Ftq 的 BpRight 锥落在
    commit_mispredict_r_*，而 impl Ftq 里有 `perf_rights = perf_cfiCommit &
    ~commit_mispredict` —— 一眼就是它）。把线索写进表里，省下一次重新考古。
    """
    pool = set(rb.impl_words.get(imod, ())) | set(rb.impl_words.get('xs_%s_core' % imod, ()))
    if not pool:
        return ''
    def norm(s):
        return re.sub(r'[^a-z0-9]', '', s.lower())
    want = [norm(perf_name)] + [norm(re.sub(r'(_r)?_\d+$', '', x)) for x in leafnames]
    want = [w for w in dict.fromkeys(want) if len(w) >= 5]
    out = []
    for c in sorted(pool):
        nc = norm(c)
        if any(w in nc or nc in w for w in want):
            out.append(c)
    return ' '.join(out[:6])


def unbound_rows(rows, rb=None):
    ctr = collections.defaultdict(lambda: dict(tiers=set(), ports=[], why=set()))
    for r in rows:
        key = (r['perf_kind'], r['perf_scope'], r['perf_name'])
        c = ctr[key]
        c['tiers'].add(r['tier'])
        if r['tier'] not in BOUND_TIERS:
            c['ports'].append(r['port'])
            c['why'].add(r['evidence'])
            c.setdefault('where', set()).add((r['impl_holder'], r['golden_signal'],
                                              r['evidence']))
    out = []
    for (kind, scope, name), c in sorted(ctr.items()):
        if not c['ports']:
            continue
        tier = 'T3_REG_LEAF' if 'T3_REG_LEAF' in c['tiers'] else 'T4_OPEN'
        if 'T3_REG_LEAF' in c['tiers'] and 'T4_OPEN' in c['tiers']:
            tier = 'T3_REG_LEAF+T4_OPEN'
        why = ' | '.join(sorted(c['why']))
        if '端口名在可读核里变了' in why or '端口不存在' in why:
            gc = 'ABSORBED_RENAMED'
        elif '解析不出来' in why or '超过' in why:
            gc = 'PARSER_GAP'
        else:
            gc = 'NO_SIGNOFF_BOUNDARY'
        step = GAP[gc][1]
        if rb is not None:
            cands = set()
            for imod, _sig, ev in c.get('where', ()):
                lf = re.findall(r'[A-Za-z_]\w*', ev.split(':', 1)[-1])
                h = hint(rb, imod, name, lf)
                if h:
                    cands.add('%s 里疑似: %s' % (imod, h))
            if cands:
                step += '  ←线索 ' + ' / '.join(sorted(cands))[:220]
        out.append(dict(perf_kind=kind, perf_scope=scope, perf_name=name, tier=tier,
                        gap_class=gc, ports=' '.join(sorted(c['ports'])),
                        next_step=step, reason=why[:300]))
    return out


def render(hdr, cols, rows):
    buf = list(hdr)
    buf.append('# ' + '\t'.join(cols))
    for r in rows:
        buf.append('\t'.join(str(r.get(c, '')).replace('\t', ' ') for c in cols))
    return '\n'.join(buf) + '\n'


# ---------------------------------------------------------------- SimTop 生成

def emit_simtop(golden_root, rows, cones, rb, out):
    src = (pathlib.Path(golden_root) / 'SimTop.sv').read_text(errors='replace')
    i = src.index('LogPerfEndpoint logEndpoint (')
    j = src.index('\n  );', i)
    head, inst, tail = src[:i], src[i:j], src[j:]

    bind = {r['port']: r for r in rows}
    decls, emitted = [], set()
    for port, c in sorted(cones.items()):
        gm = rb.G.mod(c['golden_holder'])
        base = 'SimTop.' + '.'.join(c['ippath'])
        sub = c['sub']
        decls.append('  // ---- %s : golden %s.%s（组合锥原样复制，叶子重指到 %s）'
                     % (port, c['golden_holder'], c['sig'], base))
        pfx = 'xs_pb_%s__' % port
        # ★必须拓扑序★：`wire x = y;` 里 y 要是还没声明，SystemVerilog 会按隐式网线
        # 当成 1 位新网（`default_nettype wire`），值直接错掉而且不一定报错。
        # DFS 的先序反过来**不是**拓扑序（同一个节点可以有多条入边），所以这里真做一次。
        inset = set(c['order'])
        deps = {w: [i for i in rb.G.ids(gm['defs'][w]) if i in inset] for w in c['order']}
        topo, mark = [], {}
        def visit(w):
            if mark.get(w) == 2:
                return
            mark[w] = 1
            for d in deps[w]:
                if mark.get(d) != 1:
                    visit(d)
            mark[w] = 2
            topo.append(w)
        for w in c['order']:
            visit(w)
        for w in topo:
            nm = pfx + w
            if nm in emitted:
                continue
            emitted.add(nm)
            expr = gm['defs'][w]
            def rep(m):
                t = m.group(0)
                if t in sub:
                    return sub[t]
                if t in gm['defs']:
                    return pfx + t
                return t
            expr = re.sub(r'\b[A-Za-z_]\w*\b', rep, expr)
            width = gm['decl'].get(w, '')
            decls.append('  wire %s%s = %s;' % ((width + ' ') if width else '', nm, expr))
        # ★位宽跟 golden 的原声明走★：`perfCnt_bore_1438` 是 4 位端口，golden 那根
        # `_GEN_18` 是 [2:0]；别名线写成 1 位就把高位截没了。
        w = gm['decl'].get(c['sig'], '')
        # 被 bore 的那根线**本身**可能就是一片叶子（它直接就是某个输出端口，或
        # `assign io_x = 它`），这时锥里一行中间线都没有，不能再引 `pfx+sig`
        # ——那个名字根本没声明过。实测两条（enable_bore_2 / x2_bore_22）就死在这里。
        rhs = sub[c['sig']] if c['sig'] in sub else (pfx + c['sig'])
        decls.append('  wire %s%s = %s;' % ((w + ' ') if w else '', c['wire'], rhs))

    def fix(m):
        port, val = m.group(1), m.group(2)
        r = bind.get(port)
        if r is None or not val.startswith('SimTop.'):
            return m.group(0)
        if r['tier'] == 'T0_UNCHANGED':
            return m.group(0)
        if r['impl_bind']:
            return m.group(0).replace(val, r['impl_bind'])
        return m.group(0).replace(val, "'0 /* UNBOUND %s: %s */" % (r['tier'], r['perf_name']))

    inst2 = re.sub(r'\.(\w+)\s*\n?\s*\(\s*(SimTop\.[A-Za-z0-9_.]+)\s*\)', fix, inst)
    n = collections.Counter(r['tier'] for r in rows)
    banner = ['// ===========================================================================',
              '// PATCHED-FOR-PERF-REBIND —— scripts/perf_rebind.py 生成，禁止手改。',
              '// golden SimTop 的 %d 条 perf 观测 XMR 按 docs/perf_bore_map.tsv 重绑：'
              % sum(n.values())]
    for k in ('T0_UNCHANGED', 'T1_PATH_REBIND', 'T2_CONE_PORT', 'T2_CONE_PORT_CHILD',
              'T3_REG_LEAF', 'T4_OPEN'):
        if n.get(k):
            banner.append('//   %-20s %5d' % (k, n[k]))
    banner += ['// ★ T3/T4 仍接 `\'0`（不接编不过），但那个 0 **不是测量值**：受影响的',
               '//   计数器全部列在 docs/perf_bore_unbound.tsv，perf 比对必须把它们排除。',
               '// ===========================================================================', '']
    body = head + '\n'.join(decls) + ('\n' if decls else '') + inst2 + tail
    pathlib.Path(out).write_text('\n'.join(banner) + body)
    return n


def _skel(s):
    """表达式的**骨架**：抹掉名字与下标，只留运算符与带位宽的字面量。"""
    s = re.sub(r'\[[^\]]*\]', '', s)
    s = re.sub(r"\b\d+'[sS]?[hHdDbBoO][0-9a-fA-FxXzZ_]+", 'K', s)
    s = re.sub(r'\bSimTop(?:\.\w+)+', 'X', s)
    s = re.sub(r'\b[A-Za-z_]\w*\b', 'X', s)
    s = re.sub(r'\bX(\.X)+\b', 'X', s)
    return re.sub(r'\s+', '', s)


def verify_simtop(rb, path, rows=None):
    """独立复核：把生成的 SimTop 里**每一条** XMR 拿回 impl 例化图里走一遍。

    生成器自己算出来的绑定和生成器自己写出来的文件，是两件事 —— 中间任何一步
    （拓扑序、名字前缀、叶子替换）写错都会变成 Error-[XMRE]，而 VCS 默认只报
    10 条就停。这里在编译之前把全部错的一次找齐。
    """
    kids = rb.M.kids
    text = pathlib.Path(path).read_text()
    # ★只复核本脚本负责的那些 XMR★：golden SimTop 自己还有别的层次引用（黑盒钩子、
    # 断言），它们不归重绑管，混进来只会刷出一堆假告警。范围 = 生成的锥声明行
    # + logEndpoint 的端口连接段。
    scope = [ln for ln in text.splitlines() if ln.lstrip().startswith('wire xs_pb_')]
    i = text.index('LogPerfEndpoint logEndpoint (')
    scope.append(text[i:text.index('\n  );', i)])
    xmrs = sorted(set(re.findall(r'\bSimTop\.[A-Za-z0-9_.\[\]:]+', '\n'.join(scope))))
    bad = []
    # ★「先声明后使用」也要查★：VCS 对没声明的名字按隐式网线处理（`Error-[IND]` 或
    # 更坏：静默变成 1 位新网）。实测漏过两条 —— 复核只查 XMR 是不够的。
    seen = set()
    for ln in text.splitlines():
        m = re.match(r'\s*wire\s+(?:\[[^\]]*\]\s*)?(xs_pb_\w+)\s*=\s*(.*);\s*$', ln)
        if not m:
            continue
        for u in re.findall(r'\bxs_pb_\w+\b', m.group(2)):
            if u not in seen:
                bad.append((m.group(1), '引用了还没声明的 `%s`' % u))
        seen.add(m.group(1))
    for x in xmrs:
        # 位选/位段不是层次的一部分：`io_update_pc[1]` / `io_req_bits_pc[8:3]`
        x = re.sub(r'\[[^\]]*(?:\]|$)$', '', x).rstrip('.')
        segs = x.split('.')[1:]
        if len(segs) < 2:
            continue
        mod, k = 'SimTop', 0
        while k < len(segs) - 1:
            hit = None
            for ty, _i, hp in kids.get(mod, ()):
                n = hp.count('.') + 1
                # 下标内容抹掉后比对：例化图里存的是 generate 模板（`g_wb_bank[gb]`），
                # 绑定里填的是具体下标（`g_wb_bank[0]`）。与 hier_map.check_decl_at_use
                # 同一口径。**下标是否越界这里判不了**（例化图不带范围），交给 VCS。
                if HM.norm_path('.'.join(segs[k:k + n])) == HM.norm_path(hp):
                    hit = (ty, n)
                    break
            if hit is None:
                bad.append((x, '段 `%s` 在模块 %s 下不存在' % (segs[k], mod)))
                break
            mod, k = hit[0], k + hit[1]
        else:
            if segs[-1] not in rb.impl_words.get(mod, ()):
                bad.append((x, '末段 `%s` 在模块 %s 里没有声明' % (segs[-1], mod)))
    # ★复制出来的锥必须与 golden 结构逐行相同★：位宽字面量被改、少一项、多一层括号，
    # 都不会报编译错，只会让计数器悄悄算出另一个数。名字和下标抹掉后比骨架，
    # 与「叶子重指到哪」无关，所以它检的正是复制这一步本身。
    if rows:
        holder = {r['port']: r['golden_holder'] for r in rows}
        for ln in text.splitlines():
            m = re.match(r'\s*wire\s+(?:\[[^\]]*\]\s*)?xs_pb_([A-Za-z0-9_]*?bore(?:_\d+)?)'
                         r'__([A-Za-z0-9_]+)\s*=\s*(.*);\s*$', ln)
            if not m:
                continue
            port, w, rhs = m.groups()
            gm = rb.G.mod(holder.get(port, ''))
            if gm is None or w not in gm['defs']:
                continue
            if _skel(rhs) != _skel(gm['defs'][w]):
                bad.append(('xs_pb_%s__%s' % (port, w),
                            '复制出来的表达式结构与 golden %s.%s 不同'
                            % (holder[port], w)))
    return len(xmrs), bad


def build(golden, filelist):
    rb = Rebinder(golden, filelist)
    sem = endpoint_semantics(golden)
    rows, cones = classify(rb, sem, simtop_bores(golden))
    return rb, rows, cones


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--golden', default=GOLDEN_DEFAULT)
    ap.add_argument('--filelist', default='')
    ap.add_argument('--check', action='store_true')
    ap.add_argument('--emit-simtop', default='')
    ap.add_argument('--verify-simtop', default='',
                    help='把这个 SimTop 里的每条 XMR 拿回 impl 例化图复核一遍')
    a = ap.parse_args()

    fl = a.filelist
    if not fl:
        import tempfile
        import full_elab_filelist as FEF
        fd, fl = tempfile.mkstemp(suffix='.f', prefix='perf_rebind_')
        os.close(fd)
        sys.argv = ['full_elab_filelist.py', '--with-difftest', '--golden', a.golden,
                    '--out', fl]
        devnull = open(os.devnull, 'w')
        so = sys.stdout
        sys.stdout = devnull
        try:
            FEF.main()
        finally:
            sys.stdout = so

    rb, rows, cones = build(a.golden, fl)
    m = render(MAP_HDR, MAP_COLS, rows)
    u = render(UNBOUND_HDR, UNBOUND_COLS, unbound_rows(rows, rb))

    if a.check:
        bad = 0
        for p, new in ((MAP, m), (UNBOUND, u)):
            old = p.read_text() if p.exists() else ''
            if old != new:
                print('perf_rebind --check: %s 与源码不一致（重跑 scripts/perf_rebind.py）'
                      % p.relative_to(REPO))
                bad = 1
        return bad

    MAP.write_text(m)
    UNBOUND.write_text(u)
    n = collections.Counter(r['tier'] for r in rows)
    print('perf bore XMR 总数 : %d' % len(rows))
    for k in ('T0_UNCHANGED', 'T1_PATH_REBIND', 'T2_CONE_PORT', 'T2_CONE_PORT_CHILD',
              'T3_REG_LEAF', 'T4_OPEN'):
        print('  %-22s %5d' % (k, n.get(k, 0)))
    bound = sum(n.get(k, 0) for k in BOUND_TIERS)
    print('  绑定率 %d/%d = %.2f%%' % (bound, len(rows), 100.0 * bound / len(rows)))
    ub = unbound_rows(rows, rb)
    ctr = set((r['perf_kind'], r['perf_scope'], r['perf_name']) for r in rows)
    print('计数器/断言 %d 个，其中 %d 个含未绑 bore（进 unbound 表）' % (len(ctr), len(ub)))
    for k, v in sorted(collections.Counter(r['gap_class'] for r in ub).items()):
        print('    %-22s %4d' % (k, v))
    print('写出 %s / %s' % (MAP.relative_to(REPO), UNBOUND.relative_to(REPO)))
    rc = 0
    if a.emit_simtop:
        emit_simtop(a.golden, rows, cones, rb, a.emit_simtop)
        print('写出重绑 SimTop: %s' % a.emit_simtop)
    tgt = a.verify_simtop or a.emit_simtop
    if tgt:
        n, bad = verify_simtop(rb, tgt, rows)
        print('复核 %s：%d 条 XMR 全走得通、锥体与 golden 结构逐行相同'
              % (tgt, n) if not bad else '复核 %s：★%d 条不过' % (tgt, len(bad)))
        for x, why in bad[:20]:
            print('   %s  ← %s' % (x, why))
        rc = 1 if bad else 0
    return rc


if __name__ == '__main__':
    sys.exit(main())
