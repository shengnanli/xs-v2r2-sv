#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""test_fm_eq_trace.py —— scripts/fm_eq_trace.tcl 的负测（★闸必须能红★）。

gen_receipt_harvest.py 的关二第 (3) 项拿这套差分调用序列当判据，去说
"这份 receipt 换到 main 当前的 fm_eq.tcl 下仍然成立"。一条**永远说相同**的判据
会把每一份旧 receipt 都放行 —— 那比没有判据更糟，因为它看上去是绿的。

所以这里先证明它**会红**，再证明它在该绿的时候绿。

四个用例，前两个是负测：

  NEG-1 语义突变：把 main 的 fm_eq.tcl 里一个 appvar 的取值翻掉 -> 必须判不同
  NEG-2 ★判别性负测★：一个**在旧白名单上、不在 main 白名单上**的 top，开着 vmucp
        跑 -> main 那版会在守卫处 exit 3，旧版一路跑完 -> 必须判不同。
        这一条是整套判据的要害：白名单差异恰恰是"看上去无关、实际致命"的那类，
        而它只在 (vmucp=true) ∧ (top 在一边不在另一边) 时致命。
  POS-1 同一对文件、同一个 top，但 vmucp=false -> 守卫分支根本不进，必须判相同
  POS-2 main 对自己 -> 必须判相同（自反）

★为什么 NEG-2 不能换成"随便挑一个不在白名单上的 top"★：那样两版都会 exit 3，
两条 trace 都是那两行，**判据当然说相同** —— 第一版负测就是这么写的，
它"通过"了，但它什么也没测到。负测本身也要挑得对。

用法: python3 scripts/test_fm_eq_trace.py
"""
# ★本机是 Python 3.6：subprocess.run 没有 capture_output（3.7 才有）。★
import os
import re
import shutil
import subprocess
import sys
import tempfile

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
TRACER = os.path.join(REPO, 'scripts', 'fm_eq_trace.tcl')
FM_EQ = os.path.join(REPO, 'scripts', 'fm_eq.tcl')
WL_RE = re.compile(r'if \{\$top ni \{([^}]*)\}\}')


def trace(fm_eq, top, vmucp, workdir):
    out = os.path.join(workdir, 'trace.txt')
    if os.path.exists(out):
        os.remove(out)
    env = dict(os.environ)
    for k in list(env):
        if k.startswith('FM_'):
            del env[k]
    env.update({'FM_TRACE_OUT': out, 'FM_TOP': top,
                'FM_REF_SRCS': 'REF.sv', 'FM_IMPL_SRCS': 'IMPL.sv',
                'FM_MODE': 'signoff-strict',
                'FM_VERIFY_MATCHED_UNREAD_COMPARE_POINTS': vmucp})
    subprocess.run(['tclsh', TRACER, fm_eq], cwd=workdir, env=env,
                   stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    with open(out, errors='replace') as f:
        return f.read()


def whitelist(path):
    with open(path, errors='replace') as f:
        m = WL_RE.search(f.read())
    return set(m.group(1).split()) if m else set()


def main():
    wd = tempfile.mkdtemp(prefix='fmeqtrace-test-')
    a, b = os.path.join(wd, 'a'), os.path.join(wd, 'b')
    os.makedirs(a)
    os.makedirs(b)
    fails = []
    main_wl = whitelist(FM_EQ)
    if not main_wl:
        print('FAIL setup: 从 %s 里解析不出 vmucp 白名单' % FM_EQ)
        return 1

    # --- NEG-1 语义突变 ---
    mut = os.path.join(wd, 'mutated_fm_eq.tcl')
    with open(FM_EQ, errors='replace') as f:
        txt = f.read()
    old = 'set_app_var verification_verify_unread_bbox_inputs false'
    if old not in txt:
        fails.append('NEG-1 setup: 找不到要突变的 appvar 行')
    else:
        with open(mut, 'w') as f:
            f.write(txt.replace(old, old[:-5] + 'true'))
        top = sorted(main_wl)[0]
        if trace(FM_EQ, top, 'false', a) == trace(mut, top, 'false', b):
            fails.append('NEG-1: appvar 取值被翻掉，判据却说调用序列相同')

    # --- NEG-2 判别性：旧白名单有、main 白名单没有的 top ---
    donor = None
    for root, _d, files in os.walk(os.path.join(REPO, 'evidence')):
        if 'sourced_000_fm_eq.tcl' not in files:
            continue
        p = os.path.join(root, 'sourced_000_fm_eq.tcl')
        extra = whitelist(p) - main_wl
        if extra:
            donor = (p, sorted(extra)[0])
            break
    if donor is None:
        # 仓内已提交的证据里没有这种历史版本时，就地造一个：往白名单里塞一个
        # main 没有的名字。判据要验的是"白名单差异致命"，造出来的差异同样有效。
        donor_path = os.path.join(wd, 'older_fm_eq.tcl')
        fake = 'ZzTestOnlyTopNotOnMainWhitelist'
        with open(donor_path, 'w') as f:
            f.write(WL_RE.sub(lambda m: 'if {$top ni {%s %s}}' % (m.group(1), fake), txt, count=1))
        donor = (donor_path, fake)
    dpath, dtop = donor
    if trace(FM_EQ, dtop, 'true', a) == trace(dpath, dtop, 'true', b):
        fails.append('NEG-2: %s 在旧白名单上、不在 main 白名单上，开 vmucp 跑'
                     '两版却判相同（main 应在守卫处 exit 3）' % dtop)

    # --- POS-1 同一对文件、vmucp 关掉 -> 守卫不进，必须相同 ---
    if trace(FM_EQ, dtop, 'false', a) != trace(dpath, dtop, 'false', b):
        fails.append('POS-1: vmucp=false 时守卫分支根本不进，两版却判不同')

    # --- POS-2 自反 ---
    if trace(FM_EQ, sorted(main_wl)[0], 'true', a) != trace(FM_EQ, sorted(main_wl)[0], 'true', b):
        fails.append('POS-2: main 的 fm_eq.tcl 对自己都判不同（判据不稳定）')

    shutil.rmtree(wd, ignore_errors=True)
    for f in fails:
        print('FAIL %s' % f)
    if fails:
        return 1
    print('test_fm_eq_trace: 4/4 通过（2 负测会红、2 正测绿）')
    return 0


if __name__ == '__main__':
    sys.exit(main())
