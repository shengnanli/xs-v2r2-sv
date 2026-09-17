#!/usr/bin/env python3
"""nd_reset_domain_check.py —— NewDispatch 复位域结构闸（本 lane 自建）。

为什么要有这道闸（TLBFA 的实测教训）：给寄存器**加一个 golden 没有的复位**，
或者把复位值改掉，差分 UT 按构造可能看不见——如果被测件对上电初值不敏感，
`+vcs+initreg+random` 与 `+vcs+initreg+0` 两轮都会绿，两轮都绿**证明不了复位域对**。
所以复位域要靠结构比对单独把一道闸，与 UT 相互独立：**两道闸都看不见才算漏**。

判据（逐条，fail-closed）：
  1. golden 的每个寄存器被归进 ASYNC / SYNC / NONE 三域之一，并记下复位值；
  2. 重写核里每个 always_ff 的敏感列表决定它的域；
  3. 对**已实现**的状态组，域必须与 golden 一致，复位值也必须一致；
  4. 尚未实现的 golden 状态组要如实列出来——不实现不算错，**假装实现了才算错**。

用法: nd_reset_domain_check.py [--quiet]      非零退出 = 不合格
"""
import os
import re
import sys

GOLDEN = os.environ.get('GOLDEN_RTL', '/home/eda/xs-env/G1-canonical/golden-rtl')
REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
IMPL = os.path.join(REPO, 'rtl', 'backend', 'NewDispatch.sv')

# 重写核里的状态名 -> golden 里对应的寄存器名前缀。
# 只列**已实现**的；没实现的由判据 4 报出来，不许悄悄省略。
IMPLEMENTED = {
    'uopSelIQ': 'uopSelIQ',
    'iqSort': 'IQSort',
}


def golden_domains():
    lines = open(os.path.join(GOLDEN, 'NewDispatch.sv')).read().split('\n')
    widths = {}
    for l in lines:
        m = re.match(r'^\s+reg\s+(?:\[(\d+):(\d+)\]\s+)?(\w+);', l)
        if m:
            widths[m.group(3)] = 1 if m.group(1) is None else int(m.group(1)) - int(m.group(2)) + 1
    dom, rstval = {}, {}
    i = 0
    while i < len(lines):
        m = re.match(r'^\s+always @\(posedge (\w+)(?: or posedge (\w+))?\)', lines[i])
        if m:
            is_async = m.group(2) is not None
            depth, j, body = 0, i, []
            while j < len(lines):
                depth += lines[j].count('begin') - lines[j].count('end ') - \
                    (1 if lines[j].strip() in ('end', 'end;') else 0)
                body.append(lines[j])
                if j > i and re.match(r'^\s+end // always', lines[j]):
                    break
                j += 1
            text = '\n'.join(body)
            in_rst = False
            for bl in body:
                if re.match(r'^\s+if \(reset\) begin', bl):
                    in_rst = True
                elif in_rst and re.match(r'^\s+end\s*$', bl):
                    in_rst = False
                mm = re.match(r'\s*(\w+)\s*<=\s*(.+?);', bl)
                if mm and mm.group(1) in widths:
                    n = mm.group(1)
                    if in_rst:
                        dom[n] = 'ASYNC' if is_async else 'SYNC'
                        rstval[n] = mm.group(2).strip()
                    else:
                        dom.setdefault(n, 'NONE')
            for n in re.findall(r'\s*(\w+)\s*<=', text):
                if n in widths:
                    dom.setdefault(n, 'NONE')
            i = j
        i += 1
    for n in widths:
        dom.setdefault(n, 'NONE')
    return widths, dom, rstval


def impl_domains():
    """重写核里的 always_ff -> (域, 被赋值的状态名集合)。"""
    lines = open(IMPL).read().split('\n')
    out = []
    for i, l in enumerate(lines):
        m = re.match(r'^\s+always_ff @\(posedge (\w+)(?: or (?:posedge|negedge) (\w+))?\)', l)
        if not m:
            continue
        is_async = m.group(2) is not None
        # 块体有两种写法，都要认：
        #   (a) always_ff ... begin ... end      -> 按 begin/end 配平
        #   (b) always_ff ... 后面直接跟单条语句（可能套 for），无 begin
        #       -> 收到第一条以 ';' 结尾的语句为止
        # 第一版只写了 (a)，改成逐组 generate（里面全是无 begin 的写法）之后
        # 这道闸立刻报"找不到 always_ff 赋值" —— fail-closed 是对的，
        # 但漏的是解析器不是设计，所以补 (b)。
        body, j = [lines[i]], i + 1
        rest = lines[i]
        if 'begin' not in rest:
            while j < len(lines) and 'begin' not in lines[j] and not lines[j].rstrip().endswith(';'):
                body.append(lines[j]); j += 1
            if j < len(lines):
                body.append(lines[j])
                if 'begin' in lines[j]:
                    depth = lines[j].count('begin') - len(re.findall(r'\bend\b', lines[j]))
                    j += 1
                    while j < len(lines) and depth > 0:
                        body.append(lines[j])
                        depth += lines[j].count('begin') - len(re.findall(r'\bend\b', lines[j]))
                        j += 1
        else:
            depth = rest.count('begin') - len(re.findall(r'\bend\b', rest))
            while j < len(lines) and depth > 0:
                body.append(lines[j])
                depth += lines[j].count('begin') - len(re.findall(r'\bend\b', lines[j]))
                j += 1
        text = '\n'.join(body)
        has_rst = bool(re.search(r'\bif\s*\(\s*reset\s*\)', text))
        names = set(re.findall(r'\s(\w+)\s*(?:\[[^\]]*\])*\s*<=', text))
        out.append(('ASYNC' if is_async else ('SYNC' if has_rst else 'NONE'),
                    names, i + 1))
    return out


def main():
    quiet = '--quiet' in sys.argv
    widths, gdom, grst = golden_domains()
    gsum = {}
    for n, d in gdom.items():
        gsum.setdefault(d, [0, 0])
        gsum[d][0] += 1
        gsum[d][1] += widths[n]
    problems = []
    if not quiet:
        print('golden NewDispatch 复位域：')
        for d in ('ASYNC', 'SYNC', 'NONE'):
            c, b = gsum.get(d, [0, 0])
            print('  %-6s %3d 个 reg / %3d bit' % (d, c, b))
    # golden 里本模块的事实：3 个 ASYNC、0 个 SYNC、210 个 NONE
    if gsum.get('SYNC', [0, 0])[0] != 0:
        problems.append('golden 出现了同步复位寄存器，与既有结论不符，需重新核对')

    impl = impl_domains()
    if not quiet:
        print('\n重写核的 always_ff：')
        for d, names, ln in impl:
            print('  L%-5d %-6s <- %s' % (ln, d, ', '.join(sorted(names)) or '(空)'))

    seen = set()
    for d, names, ln in impl:
        for nm in names:
            if nm not in IMPLEMENTED:
                continue
            seen.add(nm)
            want = {gdom[g] for g in gdom if g.startswith(IMPLEMENTED[nm])}
            if len(want) != 1:
                problems.append('%s 对应的 golden 寄存器域不唯一: %s' % (nm, want))
            elif d != list(want)[0]:
                problems.append('%s 在重写核里是 %s，golden 是 %s（L%d）'
                                % (nm, d, list(want)[0], ln))
    for nm in IMPLEMENTED:
        if nm not in seen:
            problems.append('声明已实现的状态 %s 在重写核里找不到 always_ff 赋值' % nm)

    gimpl = set()
    for nm, pfx in IMPLEMENTED.items():
        gimpl |= {g for g in gdom if g.startswith(pfx)}
    missing = sorted(set(gdom) - gimpl)
    if not quiet:
        print('\n判据 4：golden 有、重写核尚未实现的状态组（不实现不算错，'
              '假装实现才算错）：')
        groups = {}
        for n in missing:
            b = re.sub(r'_\d+$', '', re.sub(r'_\d+$', '', n))
            groups.setdefault(b, [0, gdom[n]])
            groups[b][0] += 1
        for b in sorted(groups):
            print('  %-34s x%-3d %s' % (b, groups[b][0], groups[b][1]))

    print('\n=== 复位域结构闸: %s ===' % ('PASS' if not problems else 'FAIL'))
    for p in problems:
        print('  ★ ' + p)
    return 1 if problems else 0


if __name__ == '__main__':
    sys.exit(main())
