#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""fm_eq_split_equiv.py —— 证明「把 per-target 数据拆出 fm_eq.tcl」这件事本身没改行为。

## 判据

用 `scripts/fm_eq_trace.tcl`（agent/harvest 造的）把 fm_eq.tcl 在 tclsh 下跑成
**发出的 FM 命令序列**，对一组代表性 (top, 环境) 比对拆分前后的序列是否逐字节相同。
拆分前那一版从 git 取（默认 `--baseline 5c21fc56:scripts/fm_eq.tcl`，即拆分所基于的
main），拆分后那一版就是工作树里的 `scripts/fm_eq.tcl` + `verif/fm_target_config/`。

代表性覆盖（每一格都真跑，不推断）：
    白名单内 / 白名单外 × vmucp=true / false，
    有 per-target appvar 的 LoadQueueReplay（true 与 false 各一），
    FM_MODE=assembly、FM_MERGE_DUP=false、FM_FAILING_LIMIT、非法 vmucp 取值，
    以及 **FM_FIELD_MAP 真给一份**（见下面"盲区"）。

## ★判别性自证★（没有这一段，上面的"相同"什么都不证明）

集成者今天用同一个 tracer 做白名单重排时，第一次跑出"四个 top 全是 1 行、哈希完全
相同"，差点当成通过 —— 查那 1 行是 `TCL_ERROR can't read "env(FM_REF_SRCS)"`，
★四个"相同"的哈希是四个相同的错误★。所以本脚本每次都先跑四条自证：

  D1 白名单内 vs 白名单外（同为拆分后、同开 vmucp）**必须不同** —— 否则判据对
     "白名单"这件事没有分辨力。
  D2 有 per-target appvar 的 top vs 没有的（同为拆分后、vmucp=false）**必须不同**
     —— 否则判据对"per-target appvar"这件事没有分辨力。
  D3 ★把 Bku.tcl 里的 fm_target_vmucp_allow 删掉★（在临时树里改，不动仓库），
     拆分后的 trace **必须变** —— 证明新加的数据文件真的是 load-bearing 的输入，
     而不是一个被 source 了但不影响任何东西的摆设。
  D4 每条 trace 都不许含 `TCL_ERROR`，且"跑到底"的用例至少 15 条记录 ——
     直接堵死"两边同样报错所以相同"这条假通过。

## 盲区（如实记，不许把"没测到"说成"测了、相同"）

  · 桩返回值是固定的：这证明的是**控制流与命令流一致**，不是"FM 会得出同样的结论"。
  · 上面 12 个用例都以 FM_SIDECAR_OUT 空跑（SIDECAR_ON=0），所以**调用序列**这件事
    没覆盖 sidecar 分支。但"拆出去那份数据还被不被绑"这个要害不靠论证：C1/C2 真开
    SIDECAR_ON 跑了一遍，实测 verif/fm_target_config/<top>.tcl 以正确 sha256 进了
    script_closure.list（没有配置的目标则不会凭空多一条）。仍未覆盖的是 emitter 的
    **其余产物**（native_facts 等）—— 本次拆分没有改 emitter 一个字节，那是论证。

  · 还有一层是本脚本够不着的：`fm_shell` 真跑（Formality license）。桩只保证
    tclsh 下的控制流一致。
  · `match_packed_payload` 在 FM_FIELD_MAP 未设置时首行就 return。原 tracer 不设它，
    于是 packed 路径完全没被覆盖。本脚本**显式设了一份两行的 field map**（用例
    packed_fieldmap），所以这条盲区在本轮是**已消除**的，不是 NOT_MODELLED。

用法:
    python3 scripts/fm_eq_split_equiv.py [--baseline <gitref>:<path>] [-v]
"""
# ★本机是 Python 3.6：subprocess.run 没有 capture_output（3.7 才有）。★
import argparse
import os
import shutil
import subprocess
import sys
import tempfile

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
TRACER = os.path.join(REPO, 'scripts', 'fm_eq_trace.tcl')
DEFAULT_BASELINE = '5c21fc56:scripts/fm_eq.tcl'

# (用例名, FM_TOP, vmucp, 额外环境, 是否"跑到底")
CASES = [
    ('wl_in_true',        'Bku',                       'true',  {}, True),
    ('wl_in_false',       'Bku',                       'false', {}, True),
    ('wl_out_true',       'AgeDetector_38',            'true',  {}, False),
    ('wl_out_false',      'AgeDetector_38',            'false', {}, True),
    ('appvar_true',       'LoadQueueReplay',           'true',  {}, True),
    ('appvar_false',      'LoadQueueReplay',           'false', {}, True),
    ('wl_in_true_2',      'WBArbiter_3',               'true',  {}, True),
    ('wl_in_mergedup',    'Composer',                  'true',  {'FM_MERGE_DUP': 'false'}, True),
    ('assembly_mode',     'Bku',                       'true',
     {'FM_MODE': 'assembly', 'FM_INTERFACE_ONLY': 'SomeBlackBox'}, True),
    ('diag_failinglimit', 'TLBFA_1',                   'true',  {'FM_FAILING_LIMIT': '0'}, True),
    ('bad_vmucp_value',   'Bku',                       'yes',   {}, False),
    ('packed_fieldmap',   'NewPipelineConnectPipe_29', 'false', {'@FIELDMAP': '1'}, True),
]


def sh(args, **kw):
    p = subprocess.run(args, stdout=subprocess.PIPE, stderr=subprocess.PIPE, **kw)
    return p.returncode, p.stdout, p.stderr


def stage(wd, name, fm_eq_bytes, verif_src):
    """搭一棵最小的树：<wd>/<name>/scripts/fm_eq.tcl + <wd>/<name>/verif

    fm_eq.tcl 是按 `info script` 的**上一级的上一级**去找 verif/fm_target_config 的，
    所以被测文件必须真的躺在一棵 <root>/scripts/ 里 —— 随手扔进 /tmp 根下会让
    拆分后那一版找不到配置目录而 exit 3，那种"不同"什么也不说明。
    """
    root = os.path.join(wd, name)
    os.makedirs(os.path.join(root, 'scripts'))
    with open(os.path.join(root, 'scripts', 'fm_eq.tcl'), 'wb') as f:
        f.write(fm_eq_bytes)
    if os.path.isdir(verif_src):
        os.symlink(verif_src, os.path.join(root, 'verif'))
    # emitter 也要在树里：SIDECAR_ON 那条路径 `source [file join [file dirname
    # [info script]] sidecar fm_native_emit.tcl]`，缺了它闭包覆盖那两条直接跑不起来。
    os.symlink(os.path.join(REPO, 'scripts', 'sidecar'),
               os.path.join(root, 'scripts', 'sidecar'))
    return os.path.join(root, 'scripts', 'fm_eq.tcl')


def trace(fm_eq, top, vmucp, extra, wd, tag, fieldmap):
    out = os.path.join(wd, 'trace_%s.txt' % tag)
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
    for k, v in extra.items():
        if k == '@FIELDMAP':
            env['FM_FIELD_MAP'] = fieldmap
        else:
            env[k] = v
    run = os.path.join(wd, 'run')
    if not os.path.isdir(run):
        os.makedirs(run)
    sh(['tclsh', TRACER, fm_eq], cwd=run, env=env)
    if not os.path.exists(out):
        return '<NO TRACE FILE>'
    with open(out, errors='replace') as f:
        return f.read()


PROBE = """# 一次性探针（由 fm_eq_split_equiv.py 写出）：证明 per-target 配置文件的字节
# **真的**进了 sidecar 的 script_closure.list。手法同 fm_eq_trace.tcl，但额外把
# set_app_var / match / verify 定义成真命令 —— emitter 的 `trace add execution`
# 只能挂在真存在的命令上，光靠 unknown 挂不上。
array set ::AV {}
proc set_app_var {n v} { set ::AV($n) $v ; return $v }
proc get_app_var {n}   { if {[info exists ::AV($n)]} { return $::AV($n) } ; return "" }
proc match {args}      { return 1 }
proc verify {args}     { return 1 }
proc redirect {args} {
    if {[lindex $args 0] eq "-variable"} { upvar 1 [lindex $args 1] v ; set v "" }
    return ""
}
proc unknown {args} {
    switch -glob -- [lindex $args 0] {
        set_top { return 1 }
        default { return "" }
    }
}
file mkdir fm_work/$env(FM_TOP)
if {[catch {source [lindex $argv 0]} e]} { puts "PROBE_TCL_ERROR: $e" }
"""


def closure_entries(fm_eq, top, wd, tag):
    """在 SIDECAR_ON 下跑一遍，返回 script_closure.list 的 [(路径, sha256)]。"""
    root = os.path.join(wd, 'closure_' + tag)
    out = os.path.join(root, 'out')
    os.makedirs(out)
    probe = os.path.join(root, 'probe.tcl')
    with open(probe, 'w') as f:
        f.write(PROBE)
    env = dict(os.environ)
    for k in list(env):
        if k.startswith('FM_'):
            del env[k]
    env.update({'FM_SIDECAR_OUT': out, 'FM_TOP': top,
                'FM_REF_SRCS': 'REF.sv', 'FM_IMPL_SRCS': 'IMPL.sv',
                'FM_MODE': 'signoff-strict',
                'FM_VERIFY_MATCHED_UNREAD_COMPARE_POINTS': 'true'})
    sh(['tclsh', probe, fm_eq], cwd=root, env=env)
    lst = os.path.join(out, 'script_closure.list')
    if not os.path.exists(lst):
        return []
    rows = []
    with open(lst, errors='replace') as f:
        for ln in f:
            c = ln.rstrip('\n').split('\t')
            if len(c) == 3:
                rows.append((c[0], c[2]))
    return rows


def sha_file(p):
    import hashlib
    with open(p, 'rb') as f:
        return hashlib.sha256(f.read()).hexdigest()


def main(argv):
    ap = argparse.ArgumentParser()
    ap.add_argument('--baseline', default=DEFAULT_BASELINE,
                    help='拆分前的 fm_eq.tcl，形如 <gitref>:<path>（默认 %s）' % DEFAULT_BASELINE)
    ap.add_argument('-v', '--verbose', action='store_true')
    a = ap.parse_args(argv)

    rc, blob, err = sh(['git', 'show', a.baseline], cwd=REPO)
    if rc != 0 or not blob:
        print('FAIL setup: git show %s 取不到基线：%s' % (a.baseline, err.decode()[:200]))
        return 1
    with open(os.path.join(REPO, 'scripts', 'fm_eq.tcl'), 'rb') as f:
        post_bytes = f.read()

    wd = tempfile.mkdtemp(prefix='fmeq-splitequiv-')
    fails, lines = [], []
    try:
        verif = os.path.join(REPO, 'verif')
        base = stage(wd, 'base', blob, verif)
        post = stage(wd, 'post', post_bytes, verif)
        fieldmap = os.path.join(wd, 'fieldmap.tsv')
        with open(fieldmap, 'w') as f:
            f.write('bits_valid 0 1\nbits_data 1 32\n')

        # ---- 正题：逐用例比对 ----
        for name, top, vm, extra, full in CASES:
            tb = trace(base, top, vm, extra, wd, 'b_' + name, fieldmap)
            tp = trace(post, top, vm, extra, wd, 'p_' + name, fieldmap)
            same = (tb == tp)
            nrec = len([l for l in tp.splitlines() if l.strip()])
            lines.append('  %-18s %-28s vmucp=%-5s %s  (%d 条记录)'
                         % (name, top, vm, 'SAME' if same else '★DIFF★', nrec))
            if not same:
                fails.append('%s: 拆分前后调用序列不同' % name)
                if a.verbose:
                    import difflib
                    for d in list(difflib.unified_diff(tb.splitlines(), tp.splitlines(),
                                                       'base', 'post', lineterm=''))[:40]:
                        lines.append('      %s' % d)
            # D4：假通过堵死
            if 'TCL_ERROR' in tb or 'TCL_ERROR' in tp:
                fails.append('D4 %s: trace 里有 TCL_ERROR —— 这条"相同"是两个相同的错误'
                             % name)
            if full and nrec < 15:
                fails.append('D4 %s: 本该跑到底却只有 %d 条记录' % (name, nrec))
            if not full and nrec > 5:
                fails.append('D4 %s: 本该在守卫处停下却跑出 %d 条记录' % (name, nrec))

        # ---- 判别性自证 ----
        d1a = trace(post, 'Bku', 'true', {}, wd, 'd1a', fieldmap)
        d1b = trace(post, 'AgeDetector_38', 'true', {}, wd, 'd1b', fieldmap)
        ok1 = d1a != d1b
        lines.append('  D1 白名单内 vs 白名单外(vmucp=true)      %s' % ('不同 ✓' if ok1 else '★相同 —— 判据无分辨力★'))
        if not ok1:
            fails.append('D1: 白名单内外的 trace 相同，判据对白名单没有分辨力')

        d2a = trace(post, 'LoadQueueReplay', 'false', {}, wd, 'd2a', fieldmap)
        d2b = trace(post, 'Bku', 'false', {}, wd, 'd2b', fieldmap)
        ok2 = d2a != d2b
        lines.append('  D2 有 per-target appvar vs 没有(false)   %s' % ('不同 ✓' if ok2 else '★相同 —— 判据看不见 appvar★'))
        if not ok2:
            fails.append('D2: per-target appvar 在 trace 里看不见，判据对它没有分辨力')

        # D3：把配置文件改掉，拆分后的 trace 必须变（证明它真是 load-bearing 输入）
        mut = os.path.join(wd, 'mutcfg')
        os.makedirs(os.path.join(mut, 'scripts'))
        shutil.copy(post, os.path.join(mut, 'scripts', 'fm_eq.tcl'))
        shutil.copytree(os.path.join(REPO, 'verif', 'fm_target_config'),
                        os.path.join(mut, 'verif', 'fm_target_config'))
        bku = os.path.join(mut, 'verif', 'fm_target_config', 'Bku.tcl')
        with open(bku, errors='replace') as f:
            t = f.read()
        with open(bku, 'w') as f:
            f.write(t.replace('\nfm_target_vmucp_allow\n', '\n'))
        d3 = trace(os.path.join(mut, 'scripts', 'fm_eq.tcl'), 'Bku', 'true', {}, wd, 'd3', fieldmap)
        ok3 = d3 != d1a
        lines.append('  D3 删掉 Bku.tcl 的 allow 声明            %s' % ('trace 变了 ✓' if ok3 else '★没变 —— 数据文件是摆设★'))
        if not ok3:
            fails.append('D3: 删掉 per-target 数据后 trace 不变 —— 那份文件根本没参与')

        # ---- C 闭包覆盖：拆出去的那份数据**仍然被 sha256 绑住** ----
        # ★这是"拆分不是放宽"的要害★，所以不能只靠"sidecar 的 source trace 会接住"
        # 这个论证 —— 这里真跑一遍 SIDECAR_ON，看它到底有没有进 script_closure.list。
        cfg_rel = 'verif/fm_target_config/LoadQueueReplay.tcl'
        rows = closure_entries(post, 'LoadQueueReplay', wd, 'has')
        want = sha_file(os.path.join(REPO, cfg_rel))
        hit = [(p, s) for p, s in rows if p.endswith(cfg_rel)]
        okc1 = bool(hit) and hit[0][1] == want
        lines.append('  C1 有配置的目标：配置进 script_closure %s'
                     % ('✓ sha 逐字节相符（共 %d 条）' % len(rows) if okc1
                        else '★没进去 —— 那这份数据就是没人绑的缝★'))
        if not okc1:
            fails.append('C1: %s 没有以正确 sha256 进入 script_closure.list（rows=%r）'
                         % (cfg_rel, [p for p, _ in rows]))
        # 判别性：没有配置的目标不该凭空多出一条，否则 C1 分不清"有"和"没有"
        rows2 = closure_entries(post, 'AgeDetector_38', wd, 'none')
        okc2 = (any('fm_eq.tcl' in p for p, _ in rows2)
                and not any('fm_target_config' in p for p, _ in rows2))
        lines.append('  C2 无配置的目标：闭包里没有该条目   %s'
                     % ('✓（且 fm_eq.tcl 仍在，闭包非空）' if okc2 else '★C1 没有分辨力★'))
        if not okc2:
            fails.append('C2: 没有配置的目标闭包不对（rows=%r）' % [p for p, _ in rows2])
    finally:
        keep = os.environ.get('FM_EQ_SPLIT_KEEP')
        if keep:
            print('（临时树保留在 %s）' % wd)
        else:
            shutil.rmtree(wd, ignore_errors=True)

    print('=== fm_eq 拆分前后调用序列差分（基线 %s）===' % a.baseline)
    for l in lines:
        print(l)
    print()
    for f in fails:
        print('FAIL %s' % f)
    if fails:
        return 1
    print('fm_eq_split_equiv: %d 个用例逐字节相同 + 3 条判别性自证 + 2 条闭包覆盖'
          % len(CASES))
    return 0


if __name__ == '__main__':
    sys.exit(main(sys.argv[1:]))
