#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""mutants.py —— RRArbiterInit 家族 UT/覆盖闸的判别力负测（`make mutants`）。

`errors=0` 只有在「注入真 bug 时 UT 会红」的前提下才有意义。本家族 15 个变体共用
一个核，所以变异全部注入 rtl/common/RRArbiterInit.sv 的 `xs_RRArbiterInit_core`，
一次注入就同时考验 15 个变体的双例化比对。

★闸的负测是双向的（CONVENTIONS）★，本文件两个方向都做：
  · 该报警时报警：注入真 bug，要求 errors > 0；
  · 不该报警时不报警：先跑一遍未变异基线，要求 errors = 0、覆盖闸 bad_cov = 0。
    基线不绿就直接退出 —— 注入后的红证明不了是注入造成的。
另外单独考一遍**覆盖闸**本身（`--cov`）：用短到不可能跑满覆盖的拍数跑基线，
要求它**判 TEST FAILED**。一个永远绿的覆盖闸能通过"注入被抓到"这一半负测，
只有这一项能把它逼出来。

★一个故意不放进 UT 变异表的改动（列出来说明挑选口径）★
  把选择表里 `k >= N` 的补位从「填第 0 路」改成「填 0」—— chosen 由构造恒 < N，
  这些表项在任何输入组合下都选不中，**UT 与 FM 都判等价**（FM 侧的 F3 实测了这一半）。
  照抄 golden 的填法仍然是对的（零成本的忠实），但它不构成判别力缺口。
  ★顺带纠正一条容易套错的规矩★：这里**不能**说"FM 不做可达性分析所以必须照抄"。
  F3 实测 FM 判等价 —— 因为 chosen 不是自由变量。那条规矩管的是**自由寄存器**，
  本模块里就是 lastGrant：M7 / F1 这一对把它量了出来（UT errors=0，FM failing=2）。

用法:
    python3 mutants.py                  # UT 判别力（默认 20k 拍）
    python3 mutants.py --cov            # 覆盖闸自身的负测
    python3 mutants.py --fm             # FM 侧负测（含只有 FM 看得见的复位域变异）
    python3 mutants.py --compile-only   # 只查锚点与语法
"""
import pathlib
import re
import shutil
import subprocess
import sys

HERE = pathlib.Path(__file__).resolve().parent
REPO = HERE.parent.parent.parent
BUILD = HERE / 'neg_build'
RTLREL = pathlib.Path('rtl') / 'common'
MODULE = 'RRArbiterInitVariants'
MUTFILE = 'RRArbiterInit.sv'          # 核所在文件（家族 15 个变体共用）
NCYCLES = '20000'
FM_TOP = 'RRArbiterInit_12'           # FM 负测用家族最小的一个（N=3，跑得快）

RTL_FILES = [MUTFILE] + ['RRArbiterInit_%d.sv' % i for i in
                         [1, 4, 5, 6, 7, 8, 9, 11, 12, 13, 14, 15, 16, 20]]

# (期望, 说明, 锚点, 替换) —— 全部注入核。期望两种：
#   CATCH   真 bug，UT 必须报（errors > 0）
#   MISS_FM UT **结构上看不见**、由 FM 兜底的改动，UT 必须 errors == 0
#           （CONVENTIONS：EXPECTED_MISSED 读作"换了一道闸"，不是"没人管"。
#            所以它在这里是**被测量的**，而且 FM 那一侧有对应条目 F1 实证兜住了。）
MUTANTS = [
    ('CATCH', 'M1 轮转边界 off-by-one：after_last 用 >= 而不是 >（上次赢的那一路还算"优先"）',
     "      after_last[i]  = (i > int'(last_grant_q));",
     "      after_last[i]  = (i >= int'(last_grant_q));"),

    ('CATCH', 'M2 轮转失效：第二轮覆写用 in_valid 而不是 valid_after（退化成固定优先级）',
     "      if (valid_after[i]) chosen = IDX_W'(i);",
     "      if (in_valid[i]) chosen = IDX_W'(i);"),

    ('CATCH', 'M3 授权少一项：in_ready 丢掉 no_higher[N+i]（轮转段全空时不再回落到固定优先级）',
     "      in_ready[i] = ((no_higher[i] & after_last[i]) | no_higher[N+i]) & out_ready;",
     "      in_ready[i] = (no_higher[i] & after_last[i]) & out_ready;"),

    ('CATCH', 'M4 复位值改成 N-1（golden 一律复位到 0）',
     "      last_grant_q <= '0;",
     "      last_grant_q <= IDX_W'(N - 1);"),

    ('CATCH', 'M5 指针使能去掉 out_ready：只要 out_valid 就前进（out_ready=0 时也换人）',
     "    else if (out_valid & out_ready)",
     "    else if (out_valid)"),

    ('MISS_FM', 'M7 异步复位改同步复位 —— ★UT 结构上看不见（tb 的 rst 覆盖整拍，两种'
     '写法行为相同），由 FM 的 F1 兜底★',
     "  always_ff @(posedge clock or posedge reset) begin\n"
     "    if (reset)\n"
     "      last_grant_q <= '0;",
     "  always_ff @(posedge clock) begin\n"
     "    if (reset)\n"
     "      last_grant_q <= '0;"),

    ('CATCH', 'M6 前缀链错位：no_higher[k] 少看一项（把 request[k-1] 写成 request[k]）',
     "      no_higher[k] = no_higher[k-1] & ~request[k-1];",
     "      no_higher[k] = no_higher[k-1] & ~request[k];"),
]

# FM 侧负测：(说明, 锚点, 替换, 期望)  期望 True = FM 必须判不等价
FM_MUTANTS = [
    ('F1 异步复位改同步复位（★UT 结构上看不见，归 FM 管★）',
     "  always_ff @(posedge clock or posedge reset) begin\n"
     "    if (reset)\n"
     "      last_grant_q <= '0;",
     "  always_ff @(posedge clock) begin\n"
     "    if (reset)\n"
     "      last_grant_q <= '0;",
     True),

    ('F2 轮转边界 off-by-one（正对照：UT 抓得到的，FM 也必须抓到）',
     "      after_last[i]  = (i > int'(last_grant_q));",
     "      after_last[i]  = (i >= int'(last_grant_q));",
     True),

    ('F3 补位从「填第 0 路」改成「填 0」（★不可达，FM 必须**不**报警★）',
     "      sel_valid[k] = (k < N) ? in_valid[k] : in_valid[0];\n"
     "      sel_bits[k]  = (k < N) ? in_bits[k]  : in_bits[0];",
     "      sel_valid[k] = (k < N) ? in_valid[k] : 1'b0;\n"
     "      sel_bits[k]  = (k < N) ? in_bits[k]  : '0;",
     False),
]


def prepare():
    if BUILD.exists():
        shutil.rmtree(BUILD)
    (BUILD / RTLREL).mkdir(parents=True)
    (BUILD / 'verif' / 'ut' / MODULE).mkdir(parents=True)
    (BUILD / 'scripts').symlink_to(REPO / 'scripts')
    restore()
    for f in ('Makefile', 'tb.sv'):
        shutil.copy(HERE / f, BUILD / 'verif' / 'ut' / MODULE / f)


def restore():
    for f in RTL_FILES:
        shutil.copy(REPO / RTLREL / f, BUILD / RTLREL / f)


def apply_mutant(tgt, base_text, old, new):
    """返回是否真的改变了文件 —— 锚点失效或文本没变都算失败（变异必须自证改了电路）。"""
    if old not in base_text:
        return False
    t = base_text.replace(old, new, 1)
    if t == base_text:
        return False
    tgt.write_text(t)
    return True


def run_ut(ncycles=NCYCLES):
    """跑一轮 UT。★每次先删日志★，编译失败时读不到旧日志。"""
    ut = BUILD / 'verif' / 'ut' / MODULE
    log = ut / 'sim_1.log'
    if log.exists():
        log.unlink()
    r = subprocess.run(['make', 'run', 'SEED=1', 'NCYCLES=' + str(ncycles)], cwd=str(ut),
                       stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
                       universal_newlines=True)
    if not log.exists():
        return (None, r.returncode, r.stdout[-2000:])
    txt = log.read_text()
    m = re.search(r'checks=(\d+) errors=(\d+) bad_cov=(\d+)', txt)
    if not m:
        return (None, r.returncode, txt[-2000:])
    passed = 'TEST PASSED' in txt
    return ((int(m.group(1)), int(m.group(2)), int(m.group(3)), passed),
            r.returncode, '')


def run_fm():
    """在 neg_build 里跑一次 FM，返回 (native_verdict, failing 数)。"""
    ut = BUILD / 'verif' / 'ut' / MODULE
    log = ut / 'fm_work' / FM_TOP / 'fm.log'
    if log.exists():
        log.unlink()
    subprocess.run(['make', 'fm-' + FM_TOP], cwd=str(ut),
                   stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
                   universal_newlines=True)
    if not log.exists():
        return (None, None)
    txt = log.read_text(errors='replace')
    # ★判据必须钉在行首★（CONVENTIONS「别拿裸错误号当判据」的同一形状）：
    # fm_shell 把入口 Tcl 逐行回显进 fm.log，里面**同时**有
    # `puts "FM_RESULT: Verification SUCCEEDED ..."` 与 `... FAILED or INCONCLUSIVE ...`
    # 两条 —— 拿裸子串判，任何一次跑都能同时"命中"两种结论。
    # 第一版就是这么写的，会把 SUCCEEDED 读成 FAILED（即恒报警的闸）。
    m = re.search(r'^Verification (SUCCEEDED|FAILED|INCONCLUSIVE)', txt, re.M)
    verdict = m.group(1) if m else None
    mf = re.search(r'^Failing \(not equivalent\)((?:\s+\d+){8})\s*$', txt, re.M)
    failing = int(mf.group(1).split()[-1]) if mf else None
    return (verdict, failing)


def baseline():
    print('=== 基线（未变异，%s 拍）===' % NCYCLES)
    base, rc, tail = run_ut()
    if base is None or rc != 0 or base[1] != 0 or base[2] != 0 or not base[3]:
        print('基线不绿（rc=%s, %s），负测无意义：\n%s' % (rc, base, tail))
        return None
    print('    checks=%d errors=%d bad_cov=%d TEST PASSED' % base[:3])
    return base


def main():
    args = sys.argv[1:]
    prepare()
    base_text = (REPO / RTLREL / MUTFILE).read_text()
    tgt = BUILD / RTLREL / MUTFILE

    if '--compile-only' in args:
        bad = []
        for _expect, name, old, new in MUTANTS:
            restore()
            if not apply_mutant(tgt, base_text, old, new):
                print('  %-78s ★锚点失效/文本未变★' % name)
                bad.append(name)
                continue
            r = subprocess.run(['make', 'compile'],
                               cwd=str(BUILD / 'verif' / 'ut' / MODULE),
                               stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
                               universal_newlines=True)
            print('  %-78s %s' % (name, 'compiles' if r.returncode == 0
                                  else '★编译失败★'))
            if r.returncode != 0:
                bad.append(name)
        restore()
        print('=== COMPILE-ONLY: %d/%d 可编译 ===' % (len(MUTANTS) - len(bad), len(MUTANTS)))
        return 1 if bad else 0

    if '--cov' in args:
        # 覆盖闸自身的负测：拍数短到跑不满覆盖时，它**必须**判失败。
        if baseline() is None:
            return 2
        res, rc, tail = run_ut(ncycles=20)
        if res is None:
            print('!! 20 拍那轮没有产生日志（rc=%s）：\n%s' % (rc, tail))
            return 1
        print('=== 覆盖闸负测：20 拍 ===')
        print('    checks=%d errors=%d bad_cov=%d TEST %s'
              % (res[0], res[1], res[2], 'PASSED' if res[3] else 'FAILED'))
        restore()
        if res[1] == 0 and res[2] > 0 and not res[3]:
            print('=== COV-NEG PASSED：errors=0 但覆盖不全，闸照样判 FAILED ===')
            return 0
        print('=== COV-NEG FAILED：覆盖闸没有独立发挥作用 ===')
        return 1

    if '--fm' in args:
        print('=== FM 基线（未变异，top=%s）===' % FM_TOP)
        v, f = run_fm()
        print('    native=%s failing=%s' % (v, f))
        if v != 'SUCCEEDED' or f != 0:
            print('FM 基线就不干净，负测无意义')
            return 2
        bad = []
        for name, old, new, expect_fail in FM_MUTANTS:
            restore()
            if not apply_mutant(tgt, base_text, old, new):
                print('!! %-74s ★锚点失效/文本未变★' % name)
                bad.append(name)
                continue
            v, f = run_fm()
            ok = (v != 'SUCCEEDED' or (f or 0) > 0) if expect_fail else \
                 (v == 'SUCCEEDED' and f == 0)
            print('  %-74s native=%-12s failing=%-5s %s'
                  % (name, v, f, 'OK' if ok else '★不符预期★'))
            if not ok:
                bad.append(name)
        restore()
        if bad:
            print('=== FM-NEG FAILED ===')
            for x in bad:
                print('   ', x)
            return 1
        print('=== FM-NEG PASSED：%d/%d 条（含一条"不该报警也确实不报"）==='
              % (len(FM_MUTANTS), len(FM_MUTANTS)))
        return 0

    if baseline() is None:
        return 2
    bad = []
    for expect, name, old, new in MUTANTS:
        restore()
        if not apply_mutant(tgt, base_text, old, new):
            print('!! %-78s ★锚点失效/文本未变★' % name)
            bad.append(name)
            continue
        res, rc, tail = run_ut()
        if res is None:
            print('!! %-74s ★没有本轮日志（编译/运行失败 rc=%s），判 FAIL★' % (name, rc))
            bad.append(name)
            continue
        if expect == 'CATCH':
            ok = res[1] > 0
            tag = 'CAUGHT' if ok else '★MISSED★'
        else:
            ok = res[1] == 0
            tag = ('MISS_FM-ok（UT 看不见，符合预期；FM 侧 F1 兜住）' if ok
                   else '★居然报了 —— 期望是 UT 看不见，说明这条注释是错的★')
        print('  %-74s errors=%-10d %s' % (name, res[1], tag))
        if not ok:
            bad.append(name)
    restore()
    if bad:
        print('=== MUTANTS FAILED：以下条目与预期不符（或根本没生效）===')
        for x in bad:
            print('   ', x)
        return 1
    ncatch = sum(1 for e, *_ in MUTANTS if e == 'CATCH')
    print('=== MUTANTS PASSED：%d/%d 条符合预期（%d CATCH + %d MISS_FM）==='
          % (len(MUTANTS), len(MUTANTS), ncatch, len(MUTANTS) - ncatch))
    return 0


if __name__ == '__main__':
    sys.exit(main())
