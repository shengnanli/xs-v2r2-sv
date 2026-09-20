#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""test_fm_eq_trace.py —— scripts/fm_eq_trace.tcl 的负测（★闸必须能红★）。

gen_receipt_harvest.py 的关二第 (3) 项拿这套差分调用序列当判据，去说
"这份 receipt 换到 main 当前的 fm_eq.tcl 下仍然成立"。一条**永远说相同**的判据
会把每一份旧 receipt 都放行 —— 那比没有判据更糟，因为它看上去是绿的。

所以这里先证明它**会红**，再证明它在该绿的时候绿。

四个用例，前两个是负测：

  NEG-1 语义突变：把 main 的 fm_eq.tcl 里一个 appvar 的取值翻掉 -> 必须判不同
  NEG-2 ★判别性负测★：一个**在一边的白名单上、不在另一边的**的 top，开着 vmucp
        跑 -> 不在白名单那一侧会在守卫处 exit 3，另一侧一路跑完 -> 必须判不同。
        这一条是整套判据的要害：白名单差异恰恰是"看上去无关、实际致命"的那类，
        而它只在 (vmucp=true) ∧ (top 在一边不在另一边) 时致命。
        ★2026-09-20 起白名单不在 fm_eq.tcl 里了★（搬进 verif/fm_target_config/<top>.tcl，
        理由见那里的 README），所以这条负测改成**两棵树只差一份 per-target 配置**：
        判据要盯的东西没变，盯的位置跟着数据走。
  POS-1 同一对文件、同一个 top，但 vmucp=false -> 守卫分支根本不进，必须判相同
  POS-2 main 对自己 -> 必须判相同（自反）

★为什么要"搭一棵树"★：fm_eq.tcl 按 `info script` 的上两级去找 verif/fm_target_config，
所以被测的那份 fm_eq.tcl 必须真的躺在某棵 <root>/scripts/ 里。随手扔进 /tmp 根下，
它会找不到配置目录而 exit 3 —— 两边都 exit 3 就又成了"四个相同的错误"那种假通过。

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
CFG_DIR = os.path.join(REPO, 'verif', 'fm_target_config')


def stage(root, fm_eq_text, cfg_src=CFG_DIR):
    """搭一棵 <root>/scripts/fm_eq.tcl + <root>/verif/fm_target_config/ 的最小树。"""
    os.makedirs(os.path.join(root, 'scripts'), exist_ok=True)
    fp = os.path.join(root, 'scripts', 'fm_eq.tcl')
    with open(fp, 'w') as f:
        f.write(fm_eq_text)
    dst = os.path.join(root, 'verif', 'fm_target_config')
    if os.path.isdir(dst):
        shutil.rmtree(dst)
    os.makedirs(os.path.join(root, 'verif'), exist_ok=True)
    shutil.copytree(cfg_src, dst)
    return fp


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
    """某一版 fm_eq.tcl 的 vmucp 白名单。

    ★两种形态都认★：拆分前是文件里那条 `if {$top ni {...}}`（evidence/ 里的历史快照
    仍是这个样子）；拆分后白名单不在这个文件里，返回空集合，由调用方改用
    verif/fm_target_config/ 的文件名集合。
    """
    with open(path, errors='replace') as f:
        m = WL_RE.search(f.read())
    return set(m.group(1).split()) if m else set()


def config_whitelist(cfg_dir=CFG_DIR):
    return {fn[:-4] for fn in os.listdir(cfg_dir) if fn.endswith('.tcl')}


def main():
    wd = tempfile.mkdtemp(prefix='fmeqtrace-test-')
    a, b = os.path.join(wd, 'a'), os.path.join(wd, 'b')
    os.makedirs(a)
    os.makedirs(b)
    fails = []
    main_wl = config_whitelist()
    if not main_wl:
        print('FAIL setup: verif/fm_target_config/ 里一份 per-target 配置都没有')
        return 1
    with open(FM_EQ, errors='replace') as f:
        txt = f.read()

    # 两棵结构完整的树：ta 放 main 的 fm_eq.tcl，tb 放被比对的那一版。
    ta = os.path.join(wd, 'ta')
    main_staged = stage(ta, txt)

    # --- NEG-1 语义突变 ---
    old = 'set_app_var verification_verify_unread_bbox_inputs false'
    if old not in txt:
        fails.append('NEG-1 setup: 找不到要突变的 appvar 行')
    else:
        tb = os.path.join(wd, 'tb_mut')
        mut = stage(tb, txt.replace(old, old[:-5] + 'true'))
        top = sorted(main_wl)[0]
        if trace(main_staged, top, 'false', a) == trace(mut, top, 'false', b):
            fails.append('NEG-1: appvar 取值被翻掉，判据却说调用序列相同')

    # --- NEG-2 判别性：一边的白名单上有、另一边没有的 top ---
    # 拆分后白名单 = verif/fm_target_config/ 里有没有那份文件，所以"差一个白名单条目"
    # 这件事就是**两棵树只差一份配置**。这里把 main 白名单上的第一个目标从 tb 树里
    # 删掉：dtop 在 ta 上在白名单、在 tb 上不在。
    dtop = sorted(main_wl)[0]
    tb2 = os.path.join(wd, 'tb_nowl')
    dpath = stage(tb2, txt)
    os.remove(os.path.join(tb2, 'verif', 'fm_target_config', dtop + '.tcl'))
    if trace(main_staged, dtop, 'true', a) == trace(dpath, dtop, 'true', b):
        fails.append('NEG-2: %s 只在一侧的白名单上，开 vmucp 跑两版却判相同'
                     '（不在白名单那侧应在守卫处 exit 3）' % dtop)

    # --- POS-1 同一对树、vmucp 关掉 -> 守卫不进，必须相同 ---
    if trace(main_staged, dtop, 'false', a) != trace(dpath, dtop, 'false', b):
        fails.append('POS-1: vmucp=false 时守卫分支根本不进，两版却判不同')

    # --- POS-2 自反 ---
    if trace(main_staged, dtop, 'true', a) != trace(main_staged, dtop, 'true', b):
        fails.append('POS-2: main 的 fm_eq.tcl 对自己都判不同（判据不稳定）')

    # --- NEG-3 ★假通过堵死★：trace 里出现 TCL_ERROR 就不算"跑过" ---
    # 集成者实测踩过：四个 top 全是 1 行、哈希完全相同，查出来是四个相同的
    # `TCL_ERROR can't read env(FM_REF_SRCS)`。
    base = trace(main_staged, dtop, 'true', a)
    if 'TCL_ERROR' in base or len(base.splitlines()) < 15:
        fails.append('NEG-3: main 这一版自己都没跑到底（%d 行，TCL_ERROR=%s）—— '
                     '上面每一条"相同/不同"都不可信'
                     % (len(base.splitlines()), 'TCL_ERROR' in base))

    fails += pins_cases(wd)

    shutil.rmtree(wd, ignore_errors=True)
    for f in fails:
        print('FAIL %s' % f)
    if fails:
        return 1
    print('test_fm_eq_trace: 8/8 通过（fm_eq 5 + fm_pins 3；其中 4 条负测会红）')
    return 0


PINS_TRACER = os.path.join(REPO, 'scripts', 'fm_pins_trace.tcl')


def pins_trace(pins, top, wd):
    out = os.path.join(wd, 'pins.txt')
    if os.path.exists(out):
        os.remove(out)
    env = dict(os.environ)
    env['FM_PINS_TRACE_OUT'] = out
    env['FM_TOP'] = top
    subprocess.run(['tclsh', PINS_TRACER, pins], cwd=wd, env=env,
                   stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    with open(out, errors='replace') as f:
        return f.read()


def pins_cases(wd):
    """scripts/fm_pins_trace.tcl 的负测。

    这套差分是用来把"钉点文件字节变了"从红改判成 bridged 的 —— 也就是说它有
    **放行**的权力。一条永远说相同的判据会把所有钉点改动放行，那比只比 sha256
    更糟（sha256 至少是保守的）。所以先证明它会红。
    """
    fails = []
    # 找一份真实的、够长的钉点文件当样本
    sample = None
    for root, _d, files in os.walk(os.path.join(REPO, 'verif', 'ut')):
        for fn in files:
            if fn.startswith('fm_pins') and fn.endswith('.tcl'):
                p = os.path.join(root, fn)
                if os.path.getsize(p) > 2000:
                    sample = p
                    break
        if sample:
            break
    if sample is None:
        fails.append('PINS setup: 仓里找不到够大的 fm_pins*.tcl 样本')
        return fails
    top = os.path.basename(os.path.dirname(sample))

    base = pins_trace(sample, top, wd)
    if not base.strip():
        fails.append('PINS setup: 样本 %s 跑不出任何调用（判据无分辨力）' % sample)
        return fails

    # POS：同一份文件对自己必须相同
    if pins_trace(sample, top, wd) != base:
        fails.append('PINS-POS: 同一份钉点文件两次跑出不同序列（判据不稳定）')

    with open(sample, errors='replace') as f:
        txt = f.read()

    # NEG-1 ★多钉一个点★ -> 必须判不同
    added = os.path.join(wd, 'pins_added.tcl')
    with open(added, 'w') as f:
        f.write(txt + '\nset_user_match r:/WORK/ZZ/extra_reg i:/WORK/ZZ/extra_q_reg\n')
    if pins_trace(added, top, wd) == base:
        fails.append('PINS NEG-1: 多钉了一个点，判据却说调用序列相同')

    # NEG-2 ★少钉一个点★ -> 必须判不同（少钉是最典型的静默退化）
    #
    # 钉点文件是 foreach 扫数据表生成调用的，参数来自表里的行、不是写死在调用处，
    # 所以"改一行调用"这种文本变异对真文件不适用（第一版就是这么写的，
    # 在 verif/ut/*/fm_pins_pre.tcl 上直接 setup 失败）。
    # ★改成由 trace 反推★：从实际发生的调用里取一个参数，去文件里找承载它的那一行删掉。
    # 判据的输入（真实调用参数）因此独立于我对文件长什么样的猜测。
    arg = None
    for line in base.splitlines():
        p = line.split('\t')
        if p[0] == 'set_user_match' and len(p) > 1 and p[1].strip():
            cand = p[1].split()[0].strip('{}"')
            cand = re.sub(r'^[ri]:/WORK/[^/]+/', '', cand)      # 去掉运行期拼的前缀
            if len(cand) >= 6:
                arg = cand
                break
    if arg is None:
        fails.append('PINS NEG-2 setup: 从 trace 里取不到可定位的钉点参数')
    else:
        lines = txt.splitlines(True)
        stem = re.split(r'[\[\]]', arg)[0]                      # 去掉 [3] 之类的下标
        idx = next((i for i, l in enumerate(lines)
                    if stem in l and not l.strip().startswith('#')), None)
        if idx is None:
            fails.append('PINS NEG-2 setup: 文件里找不到承载 %r 的行' % stem)
        else:
            dropped = os.path.join(wd, 'pins_dropped.tcl')
            with open(dropped, 'w') as f:
                f.write(''.join(lines[:idx] + lines[idx + 1:]))
            if pins_trace(dropped, top, wd) == base:
                fails.append('PINS NEG-2: 删掉承载钉点的那一行，判据却说调用序列相同')
    return fails


if __name__ == '__main__':
    sys.exit(main())
