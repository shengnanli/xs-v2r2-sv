#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""rob_otherpdest_scope.py —— `debug_otherPdest` 到底影响到哪里：四条可复算的事实。

## 待裁的那个设计选择

`robDeqGroup(i).debug_otherPdest(0..6)` 在 golden 里是 **56 个寄存器 / 448 bit**，
**没有任何 always 块写它们**（只在 `RANDOMIZE_REG_INIT` 里被赋随机值），
却被读进 `io_commits_info_<i>_debug_otherPdest_<j>` 共 **56 个输出端口**。
可读核照抄就是"声明 56 个永不驱动的寄存器"，综合后这 56 个输出未定义。
上一轮把它定位到设计层（connectCommitEntry 逐字段拷贝时**唯独不提**它，
而 RobEntryBundle 根本没有这个成员，所以没得可拷），选择本身送 codex 未决。

## 这个脚本补的是"射程"那一半

先前只知道"它在 Rob 里是悬空的"。**父层怎么接的没查过** —— 而那才决定
这 56 个未定义位会不会流进芯片。四条事实，全部从 golden / Scala 源现算：

  F1  Rob.sv 恰有 56 个 io_commits_info_<0..7>_debug_otherPdest_<0..6> 输出端口
  F2  Rob.sv 恰有 56 个 robDeqGroup_<i>_debug_otherPdest_<j> 寄存器，
      且它们在**任何 always 块里都没有被赋值**（唯一的赋值在 RANDOMIZE 段内）
  F3  ★父层 CtrlBlock.sv 把这 56 个输出**全部**接成 `/* unused */`★
  F4  整棵 Scala 源树里 `debug_otherPdest` 只出现 **1 次**（Bundle 里的声明），
      既没有写者也没有读者

F3 + F4 合起来的含义：这 56 位是**真死的** —— Rob 边界上未定义，而唯一的
消费者一个都不接。没有 X 传播路径进入芯片，整芯片 benchmark 不受影响。
剩下的影响只在 **Rob 这一层的 FM**：两侧各 56 个悬空比较点。

★这不替 codex 做决定★：它只是把"选哪个都不影响芯片行为、只影响 Rob 层证明"
这件事变成可复核的。选择（照抄悬空 / 钉 0 / 别的）仍未裁。

用法
  python3 scripts/rob_otherpdest_scope.py            # 四条事实 + 结论
  python3 scripts/rob_otherpdest_scope.py --check    # 任一条不成立即 rc=1
  python3 scripts/rob_otherpdest_scope.py --selftest # 判据自测（含负例）
"""
import argparse
import os
import re
import sys

GOLDEN_DIR = os.environ.get('ROB_GOLDEN_DIR',
                            '/home/eda/xs-env/G1-canonical/golden-rtl')
SCALA_TREE = os.environ.get('XS_SCALA_TREE',
                            '/home/eda/xs-env/XiangShan/src/main/scala')

PORT_RE = re.compile(r'^\s*output\s+(?:wire\s+)?(?:\[[^\]]*\])?\s*'
                     r'(io_commits_info_(\d+)_debug_otherPdest_(\d+))\s*[,)]')
REG_RE = re.compile(r'^\s*reg\s*(?:\[[^\]]*\])?\s*'
                    r'(robDeqGroup_(\d+)_debug_otherPdest_(\d+))\s*;')
ASSIGN_RE = re.compile(r'^\s*(robDeqGroup_\d+_debug_otherPdest_\d+)\s*(?:<=|=)')


def randomize_lines(lines):
    """RANDOMIZE 段的行号集合。

    ★按 `ifdef/`endif 嵌套配对切★，不靠"这一行看起来像随机值"：
    切多切少都会让 F2 的结论反过来，而两种结果都"看着合理"。
    """
    inside, depth, out = False, 0, set()
    for i, l in enumerate(lines):
        s = l.strip()
        if s.startswith('`ifdef') or s.startswith('`ifndef'):
            depth += 1
            if not inside and ('RANDOMIZE' in s or 'FIRRTL_BEFORE_INITIAL' in s):
                inside, start_depth = True, depth
        elif s.startswith('`endif'):
            if inside and depth == start_depth:
                inside = False
            depth -= 1
        if inside:
            out.add(i)
    return out


def facts():
    rob = os.path.join(GOLDEN_DIR, 'Rob.sv')
    ctrl = os.path.join(GOLDEN_DIR, 'CtrlBlock.sv')
    with open(rob) as f:
        rlines = f.read().split('\n')

    # F1 输出端口
    ports = sorted(m.group(1) for m in
                   (PORT_RE.match(l) for l in rlines) if m)
    want = {'io_commits_info_%d_debug_otherPdest_%d' % (i, j)
            for i in range(8) for j in range(7)}
    f1 = (set(ports) == want, '%d 个输出端口（期望 56，下标 0..7 x 0..6 全覆盖）'
          % len(ports))

    # F2 寄存器 + 是否在 always 块里被赋值
    regs = sorted(m.group(1) for m in (REG_RE.match(l) for l in rlines) if m)
    wantr = {'robDeqGroup_%d_debug_otherPdest_%d' % (i, j)
             for i in range(8) for j in range(7)}
    rnd = randomize_lines(rlines)
    real_assigns = []
    for i, l in enumerate(rlines):
        m = ASSIGN_RE.match(l)
        if m and i not in rnd:
            real_assigns.append((i + 1, m.group(1)))
    f2 = (set(regs) == wantr and not real_assigns,
          '%d 个寄存器；RANDOMIZE 段外的赋值 %d 处%s'
          % (len(regs), len(real_assigns),
             (' -> ' + str(real_assigns[:3])) if real_assigns else ''))

    # F3 父层怎么接
    with open(ctrl) as f:
        clines = f.read().split('\n')
    hits, unused = 0, 0
    for i, l in enumerate(clines):
        if 'debug_otherPdest' not in l:
            continue
        hits += 1
        tail = (l.split('debug_otherPdest', 1)[1] +
                (clines[i + 1] if i + 1 < len(clines) else ''))
        if '/* unused */' in tail:
            unused += 1
    f3 = (hits == 56 and unused == 56,
          'CtrlBlock 里出现 %d 处，其中接 `/* unused */` 的 %d 处' % (hits, unused))

    # F4 Scala 源树
    if os.path.isdir(SCALA_TREE):
        occ = []
        for root, _, names in os.walk(SCALA_TREE):
            for n in names:
                if not n.endswith('.scala'):
                    continue
                p = os.path.join(root, n)
                with open(p, errors='replace') as fh:
                    for k, l in enumerate(fh, 1):
                        if 'debug_otherPdest' in l:
                            occ.append('%s:%d' % (os.path.relpath(p, SCALA_TREE), k))
        f4 = (len(occ) == 1 and occ[0].endswith('RobBundles.scala:132'),
              'Scala 源树里出现 %d 次：%s' % (len(occ), occ[:3]))
    else:
        # ★不 fail-open★：源树不在就明确报"这条判不了"，不算通过。
        f4 = (False, 'Scala 源树 %s 不存在 —— 这条判据不可用（不是通过）' % SCALA_TREE)

    return [('F1 Rob 有 56 个 debug_otherPdest 输出', ) + f1,
            ('F2 56 个寄存器，且 always 块里从不被赋值', ) + f2,
            ('F3 父层 CtrlBlock 把 56 个全接成 /* unused */', ) + f3,
            ('F4 Scala 源树里只有 1 处（声明），无写者无读者', ) + f4]


def report(rows):
    for name, good, why in rows:
        print('  %-44s %-5s %s' % (name, 'ok' if good else '★FAIL', why))
    if all(g for _, g, _ in rows):
        print()
        print('结论（可复算）：这 56 位在 Rob 边界上未定义，而唯一的消费者一个都不接。')
        print('  -> 对整芯片行为没有影响（没有 X 传播路径）；')
        print('  -> 影响只在 Rob 这一层的 FM：两侧各 56 个悬空比较点。')
        print('  -> 选择本身（照抄悬空 / 钉 0 / 其它）仍待 codex 裁定。')
    return 0 if all(g for _, g, _ in rows) else 1


def selftest():
    """负例：每条判据都要能被种病打红，否则上面的 ok 是空转。"""
    ok = True

    def say(tag, good, why):
        nonlocal ok
        ok = ok and good
        print('  %-30s %-5s %s' % (tag, 'ok' if good else 'FAIL', why))

    say('positive', all(g for _, g, _ in facts()), '四条事实现在都成立')

    # 负例 1：RANDOMIZE 段识别失效（当成"什么都不在随机段里"）-> F2 必须翻红
    real = globals()['randomize_lines']
    try:
        globals()['randomize_lines'] = lambda lines: set()
        rows = facts()
        say('rnd_blind', not rows[1][1],
            'RANDOMIZE 段识别失效后 F2 转红（说明 F2 真的在看赋值，不是恒真）')
    finally:
        globals()['randomize_lines'] = real

    # 负例 2：父层路径指到 Rob 自己 -> F3 必须翻红（Rob 里 56 处不是 /* unused */）
    global GOLDEN_DIR
    saved = GOLDEN_DIR
    try:
        import shutil
        import tempfile
        d = tempfile.mkdtemp(prefix='otherpdest-neg-')
        shutil.copy(os.path.join(saved, 'Rob.sv'), os.path.join(d, 'Rob.sv'))
        shutil.copy(os.path.join(saved, 'Rob.sv'), os.path.join(d, 'CtrlBlock.sv'))
        GOLDEN_DIR = d
        rows = facts()
        say('parent_swapped', not rows[2][1],
            '把"父层"换成 Rob 自己之后 F3 转红（说明 F3 真的在看父层怎么接）')
        shutil.rmtree(d, ignore_errors=True)
    finally:
        GOLDEN_DIR = saved

    # 负例 3：Scala 源树不存在 -> F4 必须红（不许 fail-open）
    global SCALA_TREE
    s2 = SCALA_TREE
    try:
        SCALA_TREE = '/nonexistent-scala-tree'
        rows = facts()
        say('scala_absent_fails_closed', not rows[3][1],
            '源树不在时 F4 判红而不是静默放行')
    finally:
        SCALA_TREE = s2
    return 0 if ok else 1


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--check', action='store_true')
    ap.add_argument('--selftest', action='store_true')
    a = ap.parse_args()
    if a.selftest:
        print('rob_otherpdest_scope --selftest:')
        return selftest()
    print('=== debug_otherPdest 射程：四条可复算的事实 ===')
    rc = report(facts())
    return rc if a.check else 0


if __name__ == '__main__':
    sys.exit(main())
