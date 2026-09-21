#!/usr/bin/env python3
"""
REWRITTEN 判据的**下限**：光有文件不算重写，核得真的驱动自己的输出。

为什么要这道下限
----------------
在这之前，三处覆盖率口径（coverage_three_axis.py 轴一 / rewrite_coverage.py 的
written 列 / perf 归属的 owner_rewritten）判"已重写"用的都是同一条：
**rtl/ 下存在一个 `module <名字>`**。于是只要有人把端口表抄下来、模块体留空，
覆盖率就涨了。实测后果有两条，都不是假想：

  1. 假绿：StoreQueue 的可读核落了地，77145 golden 行被计进 written，
     而那个核当时驱动 0 条 golden 输出、UT VERIFIED=0/399。
  2. 假红：同一次落地把 perf 归属里的 owner_rewritten 由 no 翻成 yes，
     storeQueue/vaddr_match_failed 的 WAIVED 因此失效变 BLOCKING，
     check_perf_tier.py 连挂 3 条判据 —— 红的根因不在被量物，在量具。

参照 check_l2tlb_driven.py 里已经写下的同一条教训：
"闸只覆盖了一个方向，而覆盖率报告长得像全覆盖"。

判据
----
模块 M 在 impl 文件 F 里定义，取 M 的模块体，统计它的 output 端口有多少条
**在体内被驱动**（连续赋值 / 过程赋值 / 例化端口回连 / 位选与域选目标）。

  driven == outs（且 outs > 0） → REWRITTEN   真驱动了自己声明的全部输出
  0 < driven < outs             → PARTIAL_DRIVE 有洞，按 SKELETON 计（不进 written）
  driven == 0（outs > 0）       → SKELETON    只有壳
  outs == 0                     → NO_OUTPUT   纯观测 sink / 全 input，判据不适用，放行

★这道下限只判"驱动没驱动"，不判"驱动得对不对"★。驱动得对不对是 FM 的事。
所以它不会让任何 PROVEN 的模块掉出来 —— 一个 FM SUCCEEDED 的模块必然驱动全部输出，
这一点本身也是可证伪的：见本文件 --selftest 的 C 组。

用法
----
  python3 scripts/rewritten_floor.py                 # 扫全 rtl/，打印分档统计
  python3 scripts/rewritten_floor.py --list SKELETON PARTIAL_DRIVE
  python3 scripts/rewritten_floor.py --module StoreQueue
  python3 scripts/rewritten_floor.py --selftest      # 判据自身的正反测
被 coverage_three_axis.py / rewrite_coverage.py 以 `from rewritten_floor import classify_rtl`
共用，**三处同一把尺子**，改一处就是改三处。
"""
import argparse
import os
import pathlib
import re
import sys

REPO = pathlib.Path(os.environ.get('XSSV_HOME') or
                    pathlib.Path(__file__).resolve().parent.parent)

# 模块体：从 `module <名>` 到配对的 `endmodule`
_MOD = re.compile(r'^module\s+(\w+)\b', re.M)


def _strip_comments(t):
    t = re.sub(r'/\*.*?\*/', ' ', t, flags=re.S)
    t = re.sub(r'//[^\n]*', '', t)
    return t


def module_bodies(text):
    """{模块名: 模块体文本}。按 module/endmodule 配对切，注释已剥掉。"""
    t = _strip_comments(text)
    out = {}
    for m in _MOD.finditer(t):
        end = t.find('\nendmodule', m.end())
        out[m.group(1)] = t[m.start():end if end >= 0 else len(t)]
    return out


def output_ports(body):
    """ANSI 端口表里的 output 名字。`output logic [3:0] foo,` / `output foo`"""
    head = body.split(');', 1)[0] if ');' in body else body
    return set(re.findall(
        r'\boutput\s+(?:wire\s+|reg\s+|logic\s+|var\s+)?'
        r'(?:signed\s+|unsigned\s+)?(?:\[[^\]]*\]\s*)*(\w+)', head))


# 语句前缀：这些东西挡在赋值目标前面，得先剥掉再看谁是被赋值的那个
#   always_ff @(posedge clk) io_b <= 1'b1;   ← 目标不在行首
#   if (x == 1) t = 1;                       ← 同上
# 反过来，`assign y = (a <= b);` 里的 `a <= b` 是比较不是驱动，
# 剥完之后 chunk 仍以 assign 开头、第一个标识符后面不是赋值号，自然不会误判。
_PREFIX = re.compile(
    r"""^\s*(?:
          always_ff\s*@\s*\([^)]*\)
        | always_latch | always_comb
        | always\s*@\s*\([^)]*\)
        | (?:if|for|while|case[xz]?|casez|unique|priority|foreach)\s*\([^()]*\)
        | \bbegin\b | \bend\b | \belse\b | \bdo\b
        | \bdefault\s*: | \b\w+\s*:(?!:)
      )\s*""", re.X)

# 按 `;` 切语句会把 `for (int i = 0; i < N; i++)` 的头劈成三段，第三段长这样：
#     `i++) begin in_ready[i] = ...`
# 前面挂着一个没有配对左括号的 `)`。不剥掉它，for 循环体里的赋值就全看不见 ——
# 实测这一条让 RRArbiterInit 家族 11 个变体、WrBypass 家族 5 个变体被误判成
# PARTIAL_DRIVE，而它们的 FM 全是 SUCCEEDED。
# 只在 `)` 之前既没有 `(` 也没有 `=` 时才剥，免得吃掉真表达式。
_ORPHAN_CLOSE = re.compile(r'^(?=[^(=]*\))[^()]*\)\s*')

_PROC = re.compile(r'^\s*(\w+)\s*(?:\[[^\]]*\]|\.\w+)*\s*(?:<=|=)(?!=)')


def driven_names(body):
    """单模块口径的被驱动网名：体内真逻辑 + 例化端口回连（子模块一律当外部）。

    ★只有一把尺子★：这里不重复实现任何提取规则，全部转调 local_driven /
    instance_conns —— 本文件早先有过两份近似实现，改了一份另一份没跟上，
    自测立刻和全树实测对不上。规则只许有一个出处。

    classify_body（单模块、无上下文）用它；classify_rtl 走传递闭包版
    effective_driven，区别只在子模块算不算数。
    """
    d = local_driven(body)
    for _child, _cport, names in instance_conns(body):
        d |= names
    return d


_DIRECTIVES = {'include', 'define', 'ifdef', 'ifndef', 'endif', 'else',
               'elsif', 'undef', 'timescale', 'line', 'default_nettype',
               'resetall', 'celldefine', 'endcelldefine'}


def has_macro_call(body):
    """体内有没有用户宏调用（编译指令不算）。

    带记号粘接的宏 —— 例如 SplittedSRAMTemplate_2 里的
    `` assign boreChildrenBd_``S``_rdata = bore_rdata[I]; ``
    —— 驱动的是预处理之后才存在的名字。不做预处理就看不见它，
    这种情况下本判据**没有资格下结论**，只能如实说"测不了"。
    实测全树 719 个模块里只有 4 个走这条路。"""
    return any(m not in _DIRECTIVES for m in re.findall(r'`(\w+)', body))


def input_ports(body):
    """ANSI 端口表里的 input/inout 名字。只用来把"全 input 的 sink"和"空壳"分开。"""
    head = body.split(');', 1)[0] if ');' in body else body
    return set(re.findall(
        r'\b(?:input|inout)\s+(?:wire\s+|reg\s+|logic\s+|var\s+)?'
        r'(?:signed\s+|unsigned\s+)?(?:\[[^\]]*\]\s*)*(\w+)', head))


def decide_tier(body, outs, driven):
    """★分档判定的唯一出处★ —— classify_body 与 classify_rtl 都必须走这里。

    2026-09-21 教训（本文件第二次踩）：这条规则一度有**两份实现** ——
    classify_body（自测用，单模块口径）与 classify_rtl 里的内联分支（全树口径）。
    收窄 NO_OUTPUT 那次我只改了前者，于是 `--selftest` 全过、全树实测照错，
    空壳照样抬高 written 79590 行。本文件顶上早就写过「只有一把尺子」，
    ★写了不等于做到了★：规则只许有一个函数，两个入口都转调它。

    参数：body 模块体；outs 该模块的 output 端口集合；driven 已判定为有效驱动的集合。
    """
    if not outs:
        # "没有 output"要分两种：
        #   有 input 没 output = 纯观测 sink，判据不适用，放行（全树实测 3 个）
        #   ★一个端口都没有★  = 空壳，不是 sink
        # 合并成一档一律放行的话，`module X; endmodule` 三行就能凭空抬覆盖率。
        return ('NO_OUTPUT' if input_ports(body) else 'SKELETON'), 0, 0
    d = driven & outs
    if len(d) == len(outs):
        return 'REWRITTEN', len(d), len(outs)
    if has_macro_call(body):
        # 测不了 ≠ 没驱动。放行，但单独列一档，不许混进 REWRITTEN 里看不见。
        return 'MACRO_OPAQUE', len(d), len(outs)
    if d:
        return 'PARTIAL_DRIVE', len(d), len(outs)
    return 'SKELETON', 0, len(outs)


def classify_body(body):
    """单模块口径（子模块一律当外部黑盒）。→ (档位, driven 条数, output 条数)"""
    return decide_tier(body, output_ports(body), driven_names(body))



# ---------------------------------------------------------------------------
# 传递闭包：驱动链必须落到真逻辑上
# ---------------------------------------------------------------------------
# ★这是本判据的第三次修法，也是最关键的一次★
# 第二版只看单个模块体：外层壳 `assign`/`.port(io_x)` 把输出接到子核上，
# 壳就算"全驱动"。于是 StoreQueue 这个正要治的病例根本没被抓到 ——
#   StoreQueue（golden 同名壳）      输出全接到 xs_StoreQueue_core   → 判 REWRITTEN
#   xs_StoreQueue_core              驱动 0/241                      → 判 SKELETON
# 壳和核分开看都"说得通"，合起来就是一个空壳。判据只看一层，就正好看不见它。
#
# 现在的规则：输出经由例化端口连到子模块 C 的端口 cp 时，
#   C 不在 rtl/ 里（黑盒 / 厂商宏 / golden 复用）→ 算驱动（不归我们管）
#   C 在 rtl/ 里                                → cp 必须**自己**是有效驱动的
# 递归取不动点，环用"在算中返回空集"挡住。
_INST = re.compile(
    r'^[ \t]*(\w+)[ \t]*(?:#\s*\([^;]*?\)\s*)?(\w+)\s*\(', re.M)
_NOT_MODULE = {'if', 'for', 'while', 'case', 'casex', 'casez', 'always',
               'always_ff', 'always_comb', 'always_latch', 'assign', 'initial',
               'final', 'module', 'endmodule', 'function', 'task', 'generate',
               'endgenerate', 'begin', 'end', 'return', 'assert', 'assume',
               'cover', 'input', 'output', 'inout', 'logic', 'wire', 'reg',
               'localparam', 'parameter', 'typedef', 'import', 'package'}


def _clean_names(expr):
    """端口连接表达式里"干净"的标识符；带运算的返回空集（那是读不是驱动）。"""
    s = expr.strip()
    if s.startswith('{') and s.endswith('}'):
        s = s[1:-1]
    elif not re.fullmatch(r'\w+(?:\s*\[[^\]]*\])?', s):
        return set()
    if not re.fullmatch(r'[\w\s,\[\]{}:\-+]*', s):
        return set()
    return set(re.findall(r'[A-Za-z_]\w*', s))


def instance_conns(body):
    """[(子模块名, 子端口名, 连上去的名字集合)]"""
    out = []
    for m in _INST.finditer(body):
        mod = m.group(1)
        if mod in _NOT_MODULE:
            continue
        # 从 `(` 起括号配平，取出连接块
        i, depth = m.end() - 1, 0
        while i < len(body):
            if body[i] == '(':
                depth += 1
            elif body[i] == ')':
                depth -= 1
                if depth == 0:
                    break
            i += 1
        blk = body[m.end():i]
        for cp, expr in re.findall(r'\.(\w+)\s*\(([^()]*)\)', blk, re.S):
            names = _clean_names(expr)
            if names:
                out.append((mod, cp, names))
    return out


def local_driven(body):
    """只算模块体内的**真逻辑**驱动：连续赋值 + 过程赋值。不含例化回连。"""
    d = set()
    for lhs in re.findall(r'\bassign\s+([^=;]*?)=(?!=)', body, re.S):
        d |= set(re.findall(r'\w+', lhs))
    for chunk in body.split(';'):
        prev = None
        while chunk != prev:
            prev = chunk
            chunk = _PREFIX.sub('', chunk, count=1)
            chunk = _ORPHAN_CLOSE.sub('', chunk, count=1)
        m = _PROC.match(chunk)
        if m:
            d.add(m.group(1))
            continue
        m = re.match(r'^\s*(\{[^{}]*\})\s*(?:<=|=)(?!=)', chunk)
        if m:
            d |= set(re.findall(r'\w+', m.group(1)))
    return d


def effective_driven(name, bodies, memo=None, stack=None):
    """→ (有效驱动的网名集合, 其中"靠不透明子模块才成立"的子集)

    第二个返回值是**不确定性的传播**：子模块里有记号粘接宏、判据看不清它到底
    驱动了哪些端口时，不能因此说父模块漏驱动（那是把"我测不了"写成"它有病"）。
    于是这些端口照算驱动，但打上不透明标记一路往上带，父模块因此落进
    MACRO_OPAQUE 而不是 REWRITTEN —— 放行，但一直看得见。

    实测触发点只有一处：xs_iq_entries_core 用 `IQE_MUX1H 宏，
    o_is_first_issue / o_deq_rob_flag 两个端口的驱动藏在宏后面，
    于是 Entries 家族 9 个变体一度被判成漏驱动 —— 而它们的 FM 全是 SUCCEEDED。
    """
    memo = {} if memo is None else memo
    stack = set() if stack is None else stack
    if name in memo:
        return memo[name]
    if name in stack:          # 环：这一轮当它没驱动，不动点会补回来
        return set(), set()
    body = bodies.get(name)
    if body is None:
        return None            # 不在 rtl/ 里 = 外部，调用方按"算驱动"处理
    stack.add(name)
    d = local_driven(body)
    opaque = set()
    self_opaque = has_macro_call(body)
    for child, cport, names in instance_conns(body):
        sub = effective_driven(child, bodies, memo, stack)
        if sub is None:                       # 外部黑盒：算驱动，不算不透明
            d |= names
        else:
            sub_d, sub_op = sub
            if cport in sub_d:
                d |= names
                if cport in sub_op:
                    opaque |= names
            elif has_macro_call(bodies[child]):
                # 子模块自己就不透明：这个端口测不出来，照算并标记
                d |= names
                opaque |= names
    if self_opaque:
        opaque |= d - local_driven(body)
    stack.discard(name)
    memo[name] = (d, opaque)
    return memo[name]


_CACHE = None


def classify_rtl(repo=None):
    """{模块名: (档位, driven, outs, 相对路径)}，扫 rtl/ 下全部 .sv。

    ★按**传递闭包**判★：先把全树的模块体收成一张表，再逐个求 effective_driven，
    所以"壳接空核"这种两层合起来才成立的空壳会被抓出来（见上面的修法说明）。

    同名模块出现在多个文件里时取**档位最好**的那一份（和 rtl_modules() 的
    "后扫到的覆盖先扫到的"不同 —— 那条是任意的，这条至少是确定的）。
    """
    global _CACHE
    root = pathlib.Path(repo) if repo else REPO
    # ★缓存必须带会自动失效的指纹★（2026-09-21，被 test_coverage_no_shell_inflation
    #   的探针 B 抓到）：第一版是"算过一次就永远返回那一份"的进程级缓存。
    #   单跑一次脚本没问题，但**同一进程内先量一次、往 rtl/ 放个文件、再量一次**
    #   就会拿到陈旧结果 —— 台账于是对新文件视而不见。
    #   那道闸的探针正是这么用的（它 importlib.reload 了 rewrite_coverage，
    #   却reload 不到这里），于是"真驱动件也没让 written 涨"，判别力那一刀落空。
    #   指纹取 rtl/ 下全部 .sv 的 (路径, 大小, mtime_ns) —— 只 stat 不读内容，
    #   比重扫便宜两个数量级，而增删改任一文件都会让它变。
    fp = None
    try:
        fp = tuple(sorted(
            (str(q), q.stat().st_size, q.stat().st_mtime_ns)
            for q in (root / 'rtl').rglob('*.sv')))
    except OSError:
        fp = None
    if _CACHE is not None and repo is None and fp is not None and _CACHE[0] == fp:
        return _CACHE[1]
    bodies, where = {}, {}
    for p in sorted((root / 'rtl').rglob('*.sv')):
        try:
            txt = p.read_text(errors='replace')
        except OSError:
            continue
        rel = str(p.relative_to(root))
        for name, body in module_bodies(txt).items():
            # 同名重复定义：留端口最多的那份（生成变体里偶有同名薄壳）
            if name not in bodies or len(body) > len(bodies[name]):
                bodies[name], where[name] = body, rel
    memo = {}
    idx = {}
    for name, body in bodies.items():
        outs = output_ports(body)
        eff, opq = effective_driven(name, bodies, memo)
        tier, dn, on = decide_tier(body, outs, eff)
        # 全驱动但有一条是靠不透明子模块才成立的，如实降档（传递闭包特有，
        # decide_tier 看不到 opq，所以在这里补这一刀）
        if tier == 'REWRITTEN' and (opq & outs):
            tier = 'MACRO_OPAQUE'
        idx[name] = (tier, dn, on, where[name])
    if repo is None and fp is not None:
        _CACHE = (fp, idx)
    return idx


def counts_as_written(tier):
    """written / REWRITTEN 认这三档。PARTIAL_DRIVE 和 SKELETON 一律不算。

    MACRO_OPAQUE 放行是因为**判据测不了**，不是因为它合格；
    它单独成一档就是为了这条放行始终看得见、数得清。"""
    return tier in ('REWRITTEN', 'NO_OUTPUT', 'MACRO_OPAQUE')


# ---------------------------------------------------------------------------
# 判据自身的正反测：一道新判据先得证明它会响，也得证明它不会乱响
# ---------------------------------------------------------------------------
_SELF = [
    # (名字, 源码, 期望档位, 期望 driven/outs)
    ('A 只有壳', '''
module Shell(input logic clk, output logic [3:0] io_a, output logic io_b);
endmodule
''', 'SKELETON', (0, 2)),
    ('B 驱动一半', '''
module Half(input logic clk, output logic [3:0] io_a, output logic io_b);
  assign io_a = 4'd0;
endmodule
''', 'PARTIAL_DRIVE', (1, 2)),
    ('C 全驱动（连续+过程）', '''
module Full(input logic clk, output logic [3:0] io_a, output logic io_b);
  assign io_a = 4'd0;
  always_ff @(posedge clk) io_b <= 1'b1;
endmodule
''', 'REWRITTEN', (2, 2)),
    ('D 壳靠例化回连驱动', '''
module Wrap(input logic clk, output logic [3:0] io_a, output logic io_b);
  xs_Wrap_core u(.clk(clk), .io_a(io_a), .io_b(io_b));
endmodule
''', 'REWRITTEN', (2, 2)),
    ('E 位选目标算驱动', '''
module Sel(input logic clk, output logic [3:0] io_a);
  always_comb begin
    io_a[1:0] = 2'b0;
    io_a[3:2] = 2'b1;
  end
endmodule
''', 'REWRITTEN', (1, 1)),
    ('F 纯观测 sink 判据不适用', '''
module Sink(input logic clk, input logic [3:0] io_a);
endmodule
''', 'NO_OUTPUT', (0, 0)),
    ('I 拆包拼接 LHS 算驱动', '''
module Unpack(input logic clk, input logic [1:0] p, output logic io_a, output logic io_b);
  assign
    {io_a, io_b} = p;
endmodule
''', 'REWRITTEN', (2, 2)),
    ('J 拼接过程赋值算驱动', '''
module UnpackProc(input logic clk, input logic [1:0] p, output logic io_a, output logic io_b);
  always_comb {io_a, io_b} = p;
endmodule
''', 'REWRITTEN', (2, 2)),
    ('K 例化拼接回连算驱动', '''
module WrapCat(input logic clk, output logic io_a, output logic io_b);
  xs_core u(.clk(clk), .o_pair({io_b,
                                io_a}));
endmodule
''', 'REWRITTEN', (2, 2)),
    ('K2 嵌套拼接回连算驱动', '''
module WrapNest(input logic clk, output logic io_a, output logic io_b,
                output logic io_c, output logic io_d);
  xs_core u(.clk(clk), .o_vec({{io_d, io_c}, {io_b, io_a}}));
endmodule
''', 'REWRITTEN', (4, 4)),
    ('N for 循环体里的赋值算驱动', '''
module Loop(input logic clk, input logic [3:0] x, output logic [3:0] io_a);
  always_comb begin
    for (int i = 0; i < 4; i++) begin
      io_a[i] = x[i];
    end
  end
endmodule
''', 'REWRITTEN', (1, 1)),
    ('M 宏粘接名字测不了，放行但单列', '''
module Mac(input logic clk, output logic io_a, output logic io_b);
  `DRIVE_ONE(io_a)
  assign io_b = 1'b0;
endmodule
''', 'MACRO_OPAQUE', (1, 2)),
    ('L 带运算的端口内容不算驱动', '''
module WrapExpr(input logic clk, input logic x, input logic y, output logic io_a);
  xs_core u(.clk(clk), .i_d(io_a & x));
endmodule
''', 'SKELETON', (0, 1)),
    # 反测：不许把比较当赋值
    ('F2 一个端口都没有 = 空壳，不是 sink', '''
module Empty;
endmodule
''', 'SKELETON', (0, 0)),
    ('G 比较不是驱动', '''
module Cmp(input logic clk, input logic [3:0] x, output logic io_b);
  logic t;
  always_comb begin
    t = 1'b0;
    if (x == 4'd1) t = 1'b1;
  end
endmodule
''', 'SKELETON', (0, 1)),
    # 反测：注释里写了 assign 不算
    ('H 注释里的 assign 不算', '''
module Cmt(input logic clk, output logic io_b);
  // assign io_b = 1'b1;
endmodule
''', 'SKELETON', (0, 1)),
]


def selftest():
    bad = 0
    for name, src, want_tier, want_n in _SELF:
        bodies = module_bodies(src)
        assert len(bodies) == 1, name
        body = list(bodies.values())[0]
        tier, dn, on = classify_body(body)
        ok = (tier == want_tier and (dn, on) == want_n)
        print('  %-28s %-14s %d/%d   %s' %
              (name, tier, dn, on, 'ok' if ok else
               '★FAIL 期望 %s %d/%d' % (want_tier, want_n[0], want_n[1])))
        bad += (not ok)
    # 判别力自检：判据必须能把 A 和 C 分开，否则它是一条恒真判据
    ta = classify_body(list(module_bodies(_SELF[0][1]).values())[0])[0]
    tc = classify_body(list(module_bodies(_SELF[2][1]).values())[0])[0]
    if ta == tc:
        print('  ★FAIL 判别力自检：壳和全驱动被判成同一档，这条判据是恒真的')
        bad += 1
    else:
        print('  %-28s %s != %s   ok' % ('判别力自检', ta, tc))
    print('rewritten_floor --selftest: %s' %
          ('全过' if not bad else '★%d 条未过★' % bad))
    return 1 if bad else 0


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--selftest', action='store_true')
    ap.add_argument('--module', help='只看一个模块')
    ap.add_argument('--list', nargs='*', help='列出这些档位的模块')
    a = ap.parse_args()
    if a.selftest:
        return selftest()
    idx = classify_rtl()
    if a.module:
        v = idx.get(a.module)
        if not v:
            print('%s: rtl/ 下没有这个模块' % a.module)
            return 1
        print('%s\t%s\tdriven=%d/%d\t%s' % (a.module, v[0], v[1], v[2], v[3]))
        return 0
    from collections import Counter
    c = Counter(v[0] for v in idx.values())
    for k in ('REWRITTEN', 'NO_OUTPUT', 'MACRO_OPAQUE',
              'PARTIAL_DRIVE', 'SKELETON'):
        print('%-14s %5d' % (k, c[k]))
    print('%-14s %5d  （其中算 written 的 %d）' %
          ('合计', sum(c.values()),
           c['REWRITTEN'] + c['NO_OUTPUT'] + c['MACRO_OPAQUE']))
    if a.list is not None:
        want = set(a.list) or {'SKELETON', 'PARTIAL_DRIVE'}
        for n, v in sorted(idx.items()):
            if v[0] in want:
                print('  %-44s %-14s %4d/%-4d %s' % (n, v[0], v[1], v[2], v[3]))
    return 0


if __name__ == '__main__':
    sys.exit(main())
