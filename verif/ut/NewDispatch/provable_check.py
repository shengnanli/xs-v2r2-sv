#!/usr/bin/env python3
"""provable_check.py —— 跑 FM **之前**判「这一轮这个目标可证吗」（NewDispatch lane 本地）。

为什么需要它（本 lane 花 75 分钟 FM + 3 次 RTL 改动买来的教训）：
  impl 侧把一个控制输入钉成常量，会把它门控的**整条次态锥**变成 unread。
  这类点在该输入有真来源之前**不可能**配上 —— 改名、改尺寸、关 merge
  三种互不相干的手段试下来效果全为零，正因为没有一种能动到那个常量。
  实测：一行 `unresolved_toRenameAllFire = 1'b0` 改成活信号，
  unmatched unread(impl) 55 -> 0、unmatched compare(ref) 7173 -> 7118（恰好 -55）。

  ★「多种互不相干的手段效果都为零」本身就是信号★ —— 先怀疑目标不可证，
  别再找第四种手段。这个脚本就是把那个信号变成跑前可机械检出的东西。

  现有 fm_verdict.py 的判据 (a)(b)(c) 都是**跑完之后**判读数可不可信；
  这一条补的是**跑之前**判这一轮值不值得跑。

判法（保守、fail-closed —— 解析不了就说解析不了，不静默放过）：
  1. 收集 `assign X = <字面常量>;` 的 X  —— 常量驱动集
  2. 在 always_ff 里找 `if (C)` 且 C ∈ 常量驱动集 —— 该分支恒不成立，
     分支内的赋值是死的，于是边 `<次态信号> -> <寄存器>` 被切断
  3. 建组合消费图，看每个寄存器还能不能前向到达「输出端口」或「别的活寄存器次态」
  4. 到不了的 -> 本轮不可证，报出来

用法:
    provable_check.py [file.sv]     判定（有不可证寄存器则非零退出）
    provable_check.py --selftest    ★双向负测★：切断样本必须报警、未切断样本必须不报警
"""
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
DEFAULT = os.path.join(HERE, '..', '..', '..', 'rtl', 'backend', 'NewDispatch.sv')
LIT = re.compile(r"^\s*\d*'[hbdo][0-9a-fA-F_xzXZ]+\s*$|^\s*\d+\s*$")
IDENT = re.compile(r'\b([A-Za-z_]\w*)\b')
KW = {'if', 'else', 'begin', 'end', 'for', 'int', 'logic', 'wire', 'assign', 'always_ff',
      'always_comb', 'posedge', 'negedge', 'or', 'and', 'module', 'endmodule', 'input',
      'output', 'parameter', 'localparam', 'genvar', 'automatic', 'unique', 'case',
      'default', 'return', 'function', 'endfunction', 'typedef', 'struct', 'packed'}


def strip_comments(text):
    text = re.sub(r'/\*.*?\*/', ' ', text, flags=re.S)
    return '\n'.join(l.split('//')[0] for l in text.split('\n'))


def analyze(path):
    """返回 (常量驱动集, 被切断的次态边, 不可证寄存器)。保守 + fail-closed。"""
    src = strip_comments(open(path).read())

    # 1) wrapper 里的常量驱动
    const = set()
    for m in re.finditer(r'^\s*assign\s+([A-Za-z_]\w*)\s*=\s*([^;]+);', src, re.M):
        if LIT.match(m.group(2)):
            const.add(m.group(1))

    # 2) ★跨实例端口传播★ —— 第一版漏了这一步，于是切断边检出 0 条、
    #    判定压根没用到那个常量，双向负测里"未切断样本"照样报警（恒报警的闸）。
    #    常量在 wrapper 叫 unresolved_toRenameAllFire，门控条件在核里叫 toRenameAllFire。
    for m in re.finditer(r'\.(\w+)\s*\(\s*([A-Za-z_]\w*)(?:\[[^\]]*\])*\s*\)', src):
        if m.group(2) in const:
            const.add(m.group(1))

    # 3) always_ff 里被常量条件门掉的分支 -> 切断 <次态信号> -> <寄存器> 这条边
    cut = set()
    for m in re.finditer(r'always_ff\s*@\([^)]*\)', src):
        body = src[m.end():m.end() + 4000]
        for mm in re.finditer(r'\bif\s*\(\s*([A-Za-z_]\w*)\s*\)([^;]*;)', body):
            if mm.group(1) not in const:
                continue
            for a in re.finditer(r'([A-Za-z_]\w*)\s*(?:\[(?:[^\[\]]|\[[^\[\]]*\])*\])*\s*<=\s*([^;]+);', mm.group(2)):
                for nxt in IDENT.findall(a.group(2)):
                    if nxt not in KW:
                        cut.add((nxt, a.group(1)))

    # 4) 循环变量不是信号（第一版把 for(int p..) 的 p 当成寄存器报了出来）
    loopvars = set(re.findall(r'for\s*\(\s*int\s+(\w+)', src))
    cut = {(a, b) for a, b in cut if a not in loopvars and b not in loopvars}

    # 5) 消费图 s -> t（s 参与算出 t），含组合与时序；被切断的边不建
    uses = {}
    def add(s, t):
        if s not in KW and s not in loopvars and (s, t) not in cut:
            uses.setdefault(s, set()).add(t)
    # 下标要允许一层嵌套：minIQSel[l][IQ_OF[k]] 用 \[[^\]]*\] 匹配不到，
    # IQSort -> rank_q -> minIQSel 这条边就是这么丢的（第四版的断点）。
    # ★不要按行首锚定★：`for (...) cnt += ...;` 这种一行里既有 for 又有赋值的写法，
    # 行首捕到的是 `for`，整条赋值边就丢了 —— 第三版 uopSelIQ->cnt->uopSelIQMatrix
    # 这条链正是这么断的，于是切断/未切断两样本又都判死。
    for m in re.finditer(r'([A-Za-z_]\w*)\s*(?:\[(?:[^\[\]]|\[[^\[\]]*\])*\])*\s*(?:=|\+=|\|=|&=)\s*([^;=][^;]*);', src):
        for s in set(IDENT.findall(m.group(2))):
            add(s, m.group(1))
    # ★控制依赖也是边★：第二版只连了右值，于是 oh 这种"只出现在 if 条件里"的信号
    # 到不了它门控的赋值，整条 uopSelIQ -> uopSelIQMatrix -> oh -> iq_uop 链断掉，
    # 结果切断/未切断两个样本都判 dead —— 又是恒报警。
    # 这里把 always_comb 块里所有 if/case 条件信号，连到该块内所有被赋值的 LHS。
    # 方向是**保守的**：多连边只会让"判死"更难，符合 fail-closed。
    for m in re.finditer(r'always_comb\b', src):
        blk = src[m.end():m.end() + 6000]
        nxt = re.search(r'\n\s*(?:always|assign|endmodule|module)\b', blk)
        if nxt:
            blk = blk[:nxt.start()]
        conds = set()
        for c in re.finditer(r'\b(?:if|case|unique case)\s*\(([^)]*)\)', blk):
            conds |= set(IDENT.findall(c.group(1)))
        for c in re.finditer(r'\?', blk):
            pass
        lhs = {a.group(1) for a in re.finditer(r'([A-Za-z_]\w*)\s*(?:\[(?:[^\[\]]|\[[^\[\]]*\])*\])*\s*(?:=|\+=|\|=|&=)\s*[^;=]', blk)}
        for s in conds:
            for t in lhs:
                add(s, t)
    for m in re.finditer(r'([A-Za-z_]\w*)\s*(?:\[(?:[^\[\]]|\[[^\[\]]*\])*\])*\s*<=\s*([^;]+);', src):
        for s in set(IDENT.findall(m.group(2))):
            add(s, m.group(1))
    # 端口连接也是一条边（核内信号 <-> wrapper 信号）
    # 实参允许带下标：.minIQSel(minIQSelAll[1]) 这种若只认裸标识符就会丢边，
    # IQSort -> rank_q -> minIQSel -> minIQSelAll 正是在这里断的。
    for m in re.finditer(r'\.(\w+)\s*\(\s*([A-Za-z_]\w*)(?:\[[^\]]*\])*\s*\)', src):
        add(m.group(2), m.group(1)); add(m.group(1), m.group(2))

    # 6) 输出端口（golden 同名 wrapper 的 output）= 观测点。
    #    第一版的正则不认 `input logic [X] name,` 这种带类型的写法，漏掉大半端口。
    outs = set(re.findall(r'^\s*output\s+(?:logic\s+|wire\s+|reg\s+)?(?:\[[^\]]*\]\s*)?([A-Za-z_]\w*)\s*[,)]',
                          src, re.M))
    if not outs:
        print('FAIL-CLOSED: 没解析到任何 output 端口，拒绝给结论'); sys.exit(2)

    # 7) 从输出端口沿边**反向**闭包，标出"能影响输出"的信号；标不到的就是死的
    rev = {}
    for s, ts in uses.items():
        for t in ts:
            rev.setdefault(t, set()).add(s)
    alive, stack = set(outs), list(outs)
    while stack:
        n = stack.pop()
        for s in rev.get(n, ()):
            if s not in alive:
                alive.add(s); stack.append(s)

    regs = {m.group(1) for m in re.finditer(r'([A-Za-z_]\w*)\s*(?:\[(?:[^\[\]]|\[[^\[\]]*\])*\])*\s*<=', src)} - KW - loopvars
    dead = sorted(r for r in regs if r not in alive)
    return const, cut, dead


def report(path):
    const_driven, cut_edges, dead = analyze(path)
    print('常量驱动的信号 (%d): %s' % (len(const_driven), ', '.join(sorted(const_driven)) or '无'))
    print('被常量条件切断的次态边 (%d): %s'
          % (len(cut_edges), ', '.join(sorted({'%s->%s' % e for e in cut_edges})) or '无'))
    if dead:
        print('★本轮不可证的寄存器 (%d)★ —— 它们的前向锥被切断，FM 会判成 unread：' % len(dead))
        for r in dead:
            print('   ' + r)
        print('  => 在上面那些常量输入拿到真来源之前，'
              '针对这些点做配对/改名/改尺寸都是无效功。')
    else:
        print('未发现被常量切断的寄存器锥 —— 本轮不因这条理由而不可证。')
    return 1 if dead else 0


def selftest():
    """★双向负测★：只验"切断会报警"是空的（恒报警的闸也能过），必须两个方向都验。"""
    base = os.path.abspath(os.path.join(HERE, '..', '..', '..', 'rtl', 'backend', 'NewDispatch.sv'))
    src = open(base).read()
    CUT = "assign unresolved_toRenameAllFire = 1'b0;"
    UNCUT = "assign unresolved_toRenameAllFire = io_redirect_valid;"
    ok = True
    import tempfile
    for name, text, expect_alarm in (
            ('切断样本(常量 0，= 当前入库状态)', src, True),
            ('未切断样本(驱成活信号，= 诊断跑用的那一行)', src.replace(CUT, UNCUT), False)):
        if CUT not in src:
            print('SELFTEST 无法进行：在 %s 里找不到锚点 %r' % (base, CUT))
            return 2
        with tempfile.NamedTemporaryFile('w', suffix='.sv', delete=False) as f:
            f.write(text)
            tmp = f.name
        _, _, dead = analyze(tmp)
        os.unlink(tmp)
        got = bool(dead)
        verdict = 'OK' if got == expect_alarm else '★FAIL★'
        if got != expect_alarm:
            ok = False
        print('%-46s 期望报警=%-5s 实际报警=%-5s (%d 个)  %s'
              % (name, expect_alarm, got, len(dead), verdict))
    print('=== provable_check 负测: %s ===' % ('PASS' if ok else 'FAIL'))
    return 0 if ok else 1


if __name__ == '__main__':
    if '--selftest' in sys.argv:
        sys.exit(selftest())
    sys.exit(report(sys.argv[1] if len(sys.argv) > 1 else DEFAULT))
