#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""pin_call_equiv.py —— 钉点文件「调用序列等价」闸。

## 它回答的问题

`fm_pins*.tcl` **在证明闭包里**（receipt 的 `proof_config.pin_scripts` 记它的 sha256）。
所以每次有人动钉点文件 —— 改守卫、改期望值、加一条结构规则、换个错误消息 ——
都要回答同一个问题：**既有 receipt 还算不算数？**

判据只有一条：**发射出去的 `set_user_match` 调用序列有没有变。**
没变 ⇒「钉了哪些点」这一维度上闭包没变，receipt 继续有效（守卫专属改动）。
变了 ⇒ 那是新前提，按 `CONVENTIONS.md`「别把不同前提下产出的结果并列成一张表」，
必须在一个 commit 上重出 receipt。

## ★为什么不是"逐字节比对两版的 set_user_match 行"★

那条判据假定钉点文件把 N 个调用写成 N 行字面量。本仓的钉点文件多数不是：
调用写在循环里，**那一行恰恰就是被改的守卫本身**
（`catch {set_user_match ...}` -> `[set_user_match ...]`），照字面比必然不同，
比了等于自问自答。★判据的输入必须独立于被判断的对象★。

这里改成：把 `set_user_match` 换成**记参数的桩**，用 tclsh 真跑，
逐字节比对**实际发生的调用序列**（含顺序与重复）。捕获的是行为不是文本。

## 两类钉点文件

* **静态**：钉点表写死在 `foreach`/`for` 里，只依赖 `$top`。
  跑它只要把 `$top` 设成文件里 `if {$top eq "..."}` 声明的那些变体，**不需要夹具**。
* **动态**：现场调 `report_unmatched_points` / `find_cells` 发现点名再按结构配对。
  调用序列是那些查询输出的函数，所以**必须先用夹具把输入固定住**。
  夹具放在 `verif/ut/<目标>/fm_pins_fixture.tcl`（本文件自动发现），
  里面按该钉点文件自己声明的结构造出两侧点名。

没有夹具的动态文件进 `NO_FIXTURE` 棘轮（只许缩不许长，逐条写明原因）——
不是"没夹具就算过"，是把缺口显式记账并保证它不会再长。

## 用法

    python3 scripts/pin_call_equiv.py               # 闸：对着基线表核对（gate_all 用）
    python3 scripts/pin_call_equiv.py --list        # 覆盖情况
    python3 scripts/pin_call_equiv.py --update      # 重建基线表（★只在重出 receipt 之后★）
    python3 scripts/pin_call_equiv.py --compare-rev <git-rev> [--tsv out.tsv]
                                                    # 工作树 vs 某个版本，回答"要不要重跑"
    python3 scripts/pin_call_equiv.py --selftest    # ★双向负测★

基线表：`docs/pin_call_seq.tsv`（逐变体记调用数与调用序列 sha256）。
"""
from __future__ import print_function

import argparse
import hashlib
import os
import pathlib
import re
import subprocess
import sys
import tempfile

HERE = pathlib.Path(__file__).resolve().parent
REPO = HERE.parent
BASELINE = REPO / 'docs' / 'pin_call_seq.tsv'

# 动态动词：用到任何一个，调用序列就不再只由 $top 决定，必须配夹具。
DYNAMIC_VERBS = re.compile(
    r'\b(report_unmatched_points|report_matched_points|find_cells)\b')

# ---------------------------------------------------------------------------
# ★NO_FIXTURE 棘轮★（只许缩不许长）：动态钉点文件而**暂时没有夹具**的，逐条记原因。
# 一个文件从表里删除的条件只有一个：`verif/ut/<目标>/fm_pins_fixture.tcl` 落地，
# 于是它自动进入覆盖集。新增动态钉点文件**不许**进这张表（闸会判红）。
# ---------------------------------------------------------------------------
NO_FIXTURE = {
    'verif/ut/Predictor/fm_pins_pre.tcl':
        '用 find_cells 对**整个设计命名空间**做 discover（i:/WORK/xs_*_core/ghv_q_reg[*] '
        '等），夹具要模拟的不是一张点名表而是一棵 cell 树；1113 对钉点的推导链也最长。'
        '暂缺，不是"不该有"。',
}

# 这张表是闸的**覆盖面棘轮**：已经被夹具覆盖过的动态文件，不许悄悄退回 NO_FIXTURE。
# （与 NO_FIXTURE 一起构成双向约束：缺口只能缩，覆盖只能涨。）
COVERED_DYNAMIC = {
    'verif/ut/IBuffer/fm_pins.tcl',
    'verif/ut/InstrUncache/fm_pins_pre.tcl',
    'verif/ut/NCBTransactionQueue/fm_pins.tcl',
    'verif/ut/RenameBuffer/fm_pins.tcl',
    'verif/ut/SSIT/fm_pins.tcl',
    'verif/ut/TLBFA/fm_pins.tcl',
    'verif/ut/TLBNonBlock/fm_pins.tcl',
    'verif/ut/TlbStorageWrapper/fm_pins.tcl',
}

HARNESS = '''
set ::calls 0
set ::INJECT {inject}
proc set_user_match {{a b}} {{
    incr ::calls
    puts "CALL $a $b"
    if {{$::calls == $::INJECT}} {{ return 0 }}
    return 1
}}
# 证明语义无关的动词桩：钉点文件里出现过的，跑起来即可，不影响调用序列。
proc match {{args}} {{ }}
{fixture}
set top {top}
set ::rc [catch {{source {pinfile}}} ::m]
puts "RC $::rc"
'''


def strip_comments(text):
    out = []
    for line in text.splitlines():
        if line.lstrip().startswith('#'):
            out.append('')
        else:
            out.append(re.sub(r';\s*#.*$', '', line))
    return '\n'.join(out)


def discover():
    """返回 [(rel, is_dynamic, [变体...], 夹具文本 or None), ...]。"""
    files = sorted(REPO.glob('verif/ut/*/fm_pins_pre.tcl')) + \
        sorted(REPO.glob('verif/ut/*/fm_pins.tcl'))
    out = []
    for f in files:
        rel = str(f.relative_to(REPO))
        code = strip_comments(f.read_text(errors='replace'))
        dyn = bool(DYNAMIC_VERBS.search(code))
        tops = sorted(set(re.findall(r'\$top\s+eq\s+"([A-Za-z0-9_]+)"', code)))
        if not tops:
            # 不按 $top 分支的文件（无条件执行）：用 UT 目录名当 $top，
            # 与 fm_eq.tcl 传进来的那个值同源。
            tops = [f.parent.name]
        fx = f.parent / 'fm_pins_fixture.tcl'
        out.append((rel, dyn, tops, fx.read_text() if fx.is_file() else None))
    return out


def variants_of(rel, dyn, tops, fixture):
    """夹具可以自己声明它覆盖哪些变体：`# VARIANTS: A B C`。否则用 $top 表。"""
    if fixture:
        m = re.search(r'^#\s*VARIANTS:\s*(.+)$', fixture, re.M)
        if m:
            return m.group(1).split()
    return tops


def run_one(pinfile, fixture, top, inject=-1):
    src = HARNESS.format(inject=inject, fixture=fixture or '',
                         top=top, pinfile=str(pinfile))
    fd, path = tempfile.mkstemp(suffix='.tcl')
    os.close(fd)
    try:
        with open(path, 'w') as fh:
            fh.write(src)
        pr = subprocess.Popen(['tclsh', path], stdout=subprocess.PIPE,
                              stderr=subprocess.STDOUT, universal_newlines=True)
        out, _ = pr.communicate()
        calls = [l for l in out.split('\n') if l.startswith('CALL ')]
        rcs = [l for l in out.split('\n') if l.startswith('RC ')]
        rc = int(rcs[-1].split()[1]) if rcs else 99
        return calls, rc, out
    finally:
        if os.path.exists(path):
            os.unlink(path)


def seq_sha(calls):
    return hashlib.sha256('\n'.join(calls).encode()).hexdigest()


def measure_all(root=None):
    """对当前工作树（或 root 下的一份拷贝）测出全部 (rel, variant) 的调用序列。"""
    rows = []
    skipped = []
    for rel, dyn, tops, fixture in discover():
        if dyn and fixture is None:
            skipped.append(rel)
            continue
        pin = (root / rel) if root else (REPO / rel)
        if not pin.is_file():
            skipped.append(rel)
            continue
        for v in variants_of(rel, dyn, tops, fixture):
            calls, rc, out = run_one(pin, fixture, v)
            rows.append(dict(rel=rel, variant=v, n=len(calls), sha=seq_sha(calls),
                             rc=rc, calls=calls, out=out, dyn=dyn))
    return rows, skipped


def read_baseline():
    if not BASELINE.is_file():
        return None
    rows = {}
    for i, line in enumerate(BASELINE.read_text().splitlines()):
        if i == 0 or not line.strip():
            continue
        p = line.split('\t')
        rows[(p[0], p[1])] = (int(p[2]), p[3])
    return rows


def write_baseline(rows):
    BASELINE.parent.mkdir(parents=True, exist_ok=True)
    with BASELINE.open('w') as f:
        f.write('pin_file\tvariant\tcalls\tcall_seq_sha256\n')
        for r in sorted(rows, key=lambda r: (r['rel'], r['variant'])):
            f.write('%s\t%s\t%d\t%s\n' % (r['rel'], r['variant'], r['n'], r['sha']))


# ---------------------------------------------------------------------------
def cmd_check():
    base = read_baseline()
    if base is None:
        print('★基线表不存在★ %s —— 先跑一次 --update' % BASELINE)
        return 2
    rows, skipped = measure_all()
    bad = 0

    # 1. 跑不起来的一律判红（"跑不起来"不等于"没有差异"）
    for r in rows:
        if r['rc'] != 0:
            print('  FAIL  %s [%s] 在桩环境下就抛了 rc=%d' % (r['rel'], r['variant'], r['rc']))
            print('        ' + '\n        '.join(r['out'].strip().split('\n')[-3:]))
            bad += 1

    # 2. 调用序列必须与基线逐字节一致
    cur = {(r['rel'], r['variant']): (r['n'], r['sha']) for r in rows}
    for k in sorted(set(base) | set(cur)):
        b, c = base.get(k), cur.get(k)
        if b == c:
            continue
        bad += 1
        if b is None:
            print('  FAIL  %s [%s] 基线表里没有这一条' % k)
            print('        新钉点文件/新变体**必须显式登记**（"没登记就算过"等于闸有洞）。')
            print('        它没有旧基线要桥接，所以直接 `--update` 登记是安全的 ——')
            print('        ★这与下面"已有条目变了"完全不同：那种情况 --update 等于给旧 receipt 背书★')
        elif c is None:
            print('  FAIL  %s [%s] 基线表里有、现在测不到 —— 文件被删或退回无夹具？' % k)
        else:
            print('  FAIL  %s [%s] ★调用序列变了★ 基线 %d 条/%s -> 现在 %d 条/%s'
                  % (k[0], k[1], b[0], b[1][:16], c[0], c[1][:16]))
            print('        这不是守卫专属改动：既有 receipt 成了旧前提。')
            print('        要么改回去，要么在一个 commit 上重出该目标的 receipt 再 --update。')

    # 3. 覆盖面棘轮
    for rel in sorted(skipped):
        if rel not in NO_FIXTURE:
            print('  FAIL  %s 是动态钉点文件却没有夹具，也不在 NO_FIXTURE 棘轮里' % rel)
            print('        加 verif/ut/<目标>/fm_pins_fixture.tcl，或补进棘轮并写明原因。')
            bad += 1
    for rel in sorted(COVERED_DYNAMIC):
        if rel in skipped:
            print('  FAIL  %s 曾被夹具覆盖，现在退回无夹具 —— 覆盖面只许涨' % rel)
            bad += 1
    for rel in sorted(NO_FIXTURE):
        if not (REPO / rel).is_file():
            print('  FAIL  NO_FIXTURE 棘轮里有幽灵条目：%s' % rel)
            bad += 1
        elif rel not in skipped:
            print('  FAIL  %s 已经有夹具了，按棘轮规矩必须从 NO_FIXTURE 里删掉' % rel)
            bad += 1

    print('  覆盖 %d 个钉点文件 / %d 个变体；缺夹具 %d 个（已记账）'
          % (len(set(r['rel'] for r in rows)), len(rows), len(skipped)))
    if bad == 0:
        print('=== 钉点调用序列闸 PASS：全部与基线逐字节一致 ===')
    return 1 if bad else 0


def cmd_update():
    rows, skipped = measure_all()
    hard = [r for r in rows if r['rc'] != 0]
    if hard:
        for r in hard:
            print('  跑不起来：%s [%s] rc=%d' % (r['rel'], r['variant'], r['rc']))
        print('★拒绝写基线★：有文件在桩环境下就抛了，写进去的会是半张表。')
        return 1
    write_baseline(rows)
    print('写出 %s：%d 个变体' % (BASELINE, len(rows)))
    print('★提醒★：基线表变了 = 你声称"现在这版调用序列才是对的"。')
    print('  如果调用序列真的变过，先重出相关目标的 receipt，再更新这张表 ——')
    print('  否则这张表就成了给旧 receipt 背书的空洞证明。')
    return 0


def cmd_list():
    rows, skipped = measure_all()
    by = {}
    for r in rows:
        by.setdefault(r['rel'], []).append(r)
    print('%-58s %-6s %6s %s' % ('钉点文件', '类型', '变体', '调用数'))
    for rel in sorted(by):
        rs = by[rel]
        print('%-58s %-6s %6d %s' % (rel, 'DYN' if rs[0]['dyn'] else 'STATIC',
                                     len(rs), ','.join(str(r['n']) for r in rs)))
    for rel in sorted(skipped):
        print('%-58s %-6s %6s %s' % (rel, 'DYN', '-', '★无夹具（已记账）★'))
    return 0


def cmd_compare_rev(rev, tsv):
    """工作树 vs <rev>：回答"这次改动要不要重跑 receipt"。"""
    tmp = pathlib.Path(tempfile.mkdtemp(prefix='pinrev_'))
    rows_new, skipped = measure_all()
    # ★夹具表只建一次★：原来在循环里对每一行重新 discover()（重读全部 49 个钉点文件），
    # 63 行就是 63 次全量重读 —— O(n^2)，实测把这条路从秒级拖到分钟级。
    fx_by_rel = {rel: fx for rel, _dyn, _tops, fx in discover()}
    out_rows = []
    rc_all = 0
    print('%-40s %-28s %8s %8s  %s' % ('钉点文件', '变体', '旧调用', '新调用', '结论'))
    for r in rows_new:
        pr = subprocess.Popen(['git', '-C', str(REPO), 'show', '%s:%s' % (rev, r['rel'])],
                              stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        blob, _ = pr.communicate()
        if pr.returncode != 0:
            print('%-40s %-28s %8s %8s  ★%s 里没有这个文件（新增）★'
                  % (r['rel'], r['variant'], '-', r['n'], rev))
            out_rows.append((r['rel'], r['variant'], '-', r['n'], '-', r['sha'][:16],
                             'NEW', 'NEW_FILE'))
            continue
        old = tmp / r['rel'].replace('/', '__')
        old.write_bytes(blob)
        fixture = fx_by_rel.get(r['rel'])
        a, rca, _ = run_one(old, fixture, r['variant'])
        same = (a == r['calls']) and rca == 0
        print('%-40s %-28s %8d %8d  %s'
              % (r['rel'], r['variant'], len(a), r['n'],
                 '逐字节相同 ' + r['sha'][:16] if same else '★不同 -> NEEDS_RERUN★'))
        out_rows.append((r['rel'], r['variant'], len(a), r['n'],
                         seq_sha(a)[:16], r['sha'][:16],
                         'SAME' if same else 'DIFF',
                         'GUARD_ONLY' if same else 'NEEDS_RERUN'))
        if not same:
            rc_all = 1
    if tsv:
        with open(tsv, 'w') as f:
            f.write('pin_file\tvariant\told_calls\tnew_calls\told_sha256_16'
                    '\tnew_sha256_16\tcall_seq\tverdict\n')
            for row in out_rows:
                f.write('\t'.join(str(x) for x in row) + '\n')
        print('\n写出 %s' % tsv)
    print()
    print('结论：' + ('★守卫专属：调用序列逐字节相同，先前 receipt 继续有效★'
                     if rc_all == 0 else
                     '★调用集合变了：按规矩必须在一个 commit 上重出相关 receipt★'))
    return rc_all


# ---------------------------------------------------------------------------
# ★双向负测★：真守卫专属 -> 绿；真改了钉的点 -> 红。
# 只判"绿"的一侧等于没判 —— 一个恒等返回"相同"的实现也能全绿。
# ---------------------------------------------------------------------------
SYN_FIXTURE = '''
proc report_unmatched_points {args} {
    set ref {} ; set impl {}
    for {set b 0} {$b < 4} {incr b} {
        lappend ref  "r:/WORK/Demo/a_${b}_reg"
        lappend impl "i:/WORK/Demo/u_core/a_reg\\[$b\\]"
    }
    if {[lindex $args 0] eq "-reference"} { return $ref }
    return $impl
}
'''

SYN_STATIC = '''
if {$top eq "Demo"} {
  set _n 0
  set _miss 0
  foreach _pair {
    {a_0_reg a_reg[0]}
    {a_1_reg a_reg[1]}
    {a_2_reg a_reg[2]}
    {a_3_reg a_reg[3]}
  } {
    lassign $_pair _r _i
    if {[set_user_match "r:/WORK/$top/$_r" "i:/WORK/$top/u_core/$_i"]} {
      incr _n
    } else {
      incr _miss
    }
  }
  puts "SYN_PINS n=$_n miss=$_miss"
  if {$_miss != 0} { error "SYN_PIN_MISS=$_miss" }
  if {$_n != 4} { error "SYN_PIN_COUNT=$_n" }
}
'''

SYN_DYN = '''
set _ref  [report_unmatched_points -reference -status unread -list]
set _impl [report_unmatched_points -implementation -status unread -list]
set _expect 4
set _n 0
foreach r $_ref {
    if {![regexp {^r:(/WORK/[^/]+)/a_(\\d+)_reg$} $r -> scope idx]} {
        error "SYN_DYN_SHAPE=$r"
    }
    set i "i:$scope/u_core/a_reg\\[$idx\\]"
    if {[lsearch -exact $_impl $i] < 0} { error "SYN_DYN_NOT_MEASURED=$i" }
    if {![set_user_match $r $i]} { error "SYN_DYN_MISS=$r" }
    incr _n
}
if {$_n != $_expect} { error "SYN_DYN_COUNT=$_n" }
'''

# (标签, 变形函数, 期望结论)  期望 'SAME' = 守卫专属；'DIFF' = 改了钉的点
GUARD_ONLY_MUTATIONS = [
    ('改错误消息文本', lambda s: s.replace('SYN_PIN_MISS=', 'SYN_PIN_MISSED=')
                                  .replace('SYN_DYN_MISS=', 'SYN_DYN_MISSED=')),
    ('加一行 puts', lambda s: s.replace('  set _n 0', '  puts "extra diagnostic"\n  set _n 0')
                               .replace('set _expect 4', 'puts "extra diagnostic"\nset _expect 4')),
    ('返回值计数换成 catch 计数（本轮修的那个形态，反向）',
     lambda s: s.replace('if {[set_user_match "r:/WORK/$top/$_r" "i:/WORK/$top/u_core/$_i"]} {',
                         'if {![catch {set_user_match "r:/WORK/$top/$_r" "i:/WORK/$top/u_core/$_i"}]} {')
                .replace('if {![set_user_match $r $i]} { error "SYN_DYN_MISS=$r" }',
                         'if {[catch {set_user_match $r $i}]} { error "SYN_DYN_MISS=$r" }')),
    ('把期望值从字面量改成变量', lambda s: s.replace('if {$_n != 4}', 'if {$_n != $_want}')
                                             .replace('  set _n 0', '  set _want 4\n  set _n 0')),
]

PIN_SET_MUTATIONS = [
    ('改一个 ref 名字', lambda s: s.replace('{a_2_reg a_reg[2]}', '{b_2_reg a_reg[2]}')
                                   .replace('a_(\\d+)_reg$', 'a_(\\d+)_regx$')),
    ('少钉一对', lambda s: s.replace('    {a_3_reg a_reg[3]}\n', '')
                            .replace('set _expect 4', 'set _expect 3')
                            .replace('foreach r $_ref {', 'set _ref [lrange $_ref 0 2]\nforeach r $_ref {')),
    ('多钉一对（重复）', lambda s: s.replace('    {a_3_reg a_reg[3]}\n',
                                            '    {a_3_reg a_reg[3]}\n    {a_3_reg a_reg[3]}\n')
                                    .replace('set _expect 4', 'set _expect 5')
                                    .replace('foreach r $_ref {',
                                             'lappend _ref [lindex $_ref 3]\nforeach r $_ref {')),
    ('换两对的顺序', lambda s: s.replace('    {a_1_reg a_reg[1]}\n    {a_2_reg a_reg[2]}\n',
                                        '    {a_2_reg a_reg[2]}\n    {a_1_reg a_reg[1]}\n')
                                .replace('foreach r $_ref {',
                                         'set _ref [list [lindex $_ref 1] [lindex $_ref 0] '
                                         '[lindex $_ref 2] [lindex $_ref 3]]\nforeach r $_ref {')),
    ('改 impl 侧路径模板', lambda s: s.replace('i:/WORK/$top/u_core/$_i', 'i:/WORK/$top/u_core2/$_i')
                                      .replace('i:$scope/u_core/a_reg', 'i:$scope/u_core2/a_reg')),
]


def _selftest_pair(tmp, name, body, fixture, mutate):
    base = tmp / ('%s_base.tcl' % name)
    base.write_text(body)
    mut = tmp / ('%s_mut.tcl' % name)
    mut.write_text(mutate(body))
    a, rca, oa = run_one(base, fixture, 'Demo')
    b, rcb, ob = run_one(mut, fixture, 'Demo')
    return a, rca, b, rcb, ob


def cmd_selftest():
    tmp = pathlib.Path(tempfile.mkdtemp(prefix='pinself_'))
    ok = True

    def ck(label, good, detail=''):
        nonlocal ok
        if not good:
            ok = False
        print('  %s  %s%s' % ('ok  ' if good else 'FAIL', label,
                              ('  ' + detail) if detail else ''))

    print('=== 正向：未变形的样本必须跑得通且发 4 次调用 ===')
    for kind, body, fx in (('静态', SYN_STATIC, None), ('动态', SYN_DYN, SYN_FIXTURE)):
        sample = tmp / ('%s_ok.tcl' % kind)
        sample.write_text(body)
        calls, rc, out = run_one(sample, fx, 'Demo')
        ck('%s 样本自身跑得通' % kind, rc == 0 and len(calls) == 4,
           'rc=%s calls=%s' % (rc, len(calls)))

    print()
    print('=== 负测 A：★真守卫专属 -> 必须判 SAME（绿）★ ===')
    print('    （只会判红的实现在这里就露馅：它会把守卫改动也说成要重跑）')
    for kind, body, fx in (('静态', SYN_STATIC, None), ('动态', SYN_DYN, SYN_FIXTURE)):
        for label, mut in GUARD_ONLY_MUTATIONS:
            a, rca, b, rcb, ob = _selftest_pair(tmp, kind, body, fx, mut)
            same = (a == b)
            ck('%s / %s' % (kind, label), same and rca == 0 and rcb == 0,
               '' if (same and rcb == 0) else
               ('★变形后跑不起来 rc=%d★ %s' % (rcb, ob.strip().split('\n')[-1])
                if rcb else '★被误判成 DIFF★'))

    print()
    print('=== 负测 B：★真改了钉的点 -> 必须判 DIFF（红）★ ===')
    print('    （恒等返回"相同"的实现在这里露馅）')
    for kind, body, fx in (('静态', SYN_STATIC, None), ('动态', SYN_DYN, SYN_FIXTURE)):
        for label, mut in PIN_SET_MUTATIONS:
            a, rca, b, rcb, ob = _selftest_pair(tmp, kind, body, fx, mut)
            # 判红有两条通路：序列不同，或变形后当场抛（钉不成也是"不是守卫专属"）。
            caught = (a != b) or rcb != 0
            ck('%s / %s' % (kind, label), caught,
               '' if caught else '★没抓到：序列被判成相同★')

    print()
    print('=== 负测 C：闸对"跑不起来"的处置（不能读成"没有差异"）===')
    broken = tmp / 'broken.tcl'
    broken.write_text('set _n 0\nthis_command_does_not_exist\n')
    calls, rc, out = run_one(broken, None, 'Demo')
    ck('跑不起来时 rc != 0 且调用序列为空', rc != 0 and calls == [],
       'rc=%d calls=%d' % (rc, len(calls)))

    print()
    print('自测' + ('全过' if ok else '★有失败★'))
    return 0 if ok else 1


def main(argv):
    ap = argparse.ArgumentParser()
    g = ap.add_mutually_exclusive_group()
    g.add_argument('--check', action='store_true', help='对着基线表核对（默认）')
    g.add_argument('--update', action='store_true', help='重建基线表')
    g.add_argument('--list', action='store_true', help='列覆盖情况')
    g.add_argument('--selftest', action='store_true', help='双向负测')
    g.add_argument('--compare-rev', metavar='REV', help='工作树 vs 某个 git 版本')
    ap.add_argument('--tsv', help='--compare-rev 的结果写到这个 tsv')
    args = ap.parse_args(argv)

    if args.selftest:
        return cmd_selftest()
    if args.update:
        return cmd_update()
    if args.list:
        return cmd_list()
    if args.compare_rev:
        return cmd_compare_rev(args.compare_rev, args.tsv)
    return cmd_check()


if __name__ == '__main__':
    sys.exit(main(sys.argv[1:]))
