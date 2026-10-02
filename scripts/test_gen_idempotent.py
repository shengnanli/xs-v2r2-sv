#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""test_gen_idempotent.py —— 每个 verif/ut/*/gen.py 重跑一遍，产物必须逐字不变。

## 为什么要这道闸

本轮已经踩过两次同一个病，形态完全一样：

  - `gen_tlbuffer_ad_family.py`：negtest 段是**手工贴在生成产物后面**的，谁跑一次
    生成器它就被静默删掉 —— 而那正是该家族唯一病因形态（位宽）的防护。
  - `gen_sram_wrappers.py`：33 个薄文件里的 6 个 `G1_*` 锚点、以及 UT Makefile 的
    negtest 段，同样是手工补在生成产物上的，重跑即全没。

两次都是**并回生成器**才修好的。修好之后给那两个挂了 `--check`，但 `verif/ut/*/gen.py`
这一层 9 个生成器里只有 1 个有 `--check`，剩下 8 个照样是敞口。

## 判据

在 HEAD 上开一个 detached worktree（不碰活动工作树），逐个跑 `gen.py`，跑完
`git status --porcelain` 必须为空。非空 = 库里那份产物与生成器**现在**会生成的不一致，
两种可能都必须当成错：

  (a) 有人手工改了生成产物 —— 下次谁跑生成器就静默丢失；
  (b) 有人改了生成器却没并回产物 —— 库里的 RTL 与生成器已经脱节。

## 已知边界（不藏着）

它验的是 **HEAD 的字节**，不是活动工作树。所以"手改产物但还没提交"这一刻它看不见，
要到下一次跑闸才报。这是刻意的取舍：证明与台账在本工程里一律钉 committed 字节
（见 scripts/run_proof.sh 的同一条理由），而且把 1.3 GiB 的 verif/ 整份拷出来跑
代价太大。它的作用是把"静默永久损坏"变成"下一轮必然变红"。

用法: python3 scripts/test_gen_idempotent.py
"""
import pathlib
import shutil
import subprocess
import sys
import tempfile

REPO = pathlib.Path(__file__).resolve().parent.parent


def sh(args, cwd, env=None):
    return subprocess.run(args, cwd=str(cwd), env=env,
                          stdout=subprocess.PIPE, stderr=subprocess.STDOUT)


# ★库的第二种合法调用形态：「直接带变体名调用」（2026-10-02 gatefix）★
# IssueQueue_common/ 的 5 个生成器从来没有薄壳：它们是 `python3 <lib> <V> [--check]`
# 直接调用，产物（verif/ut/<V>/{Makefile,tb.sv,fm_pins_pre.tcl}、
# verif/fm_target_config/<V>.tcl）头上写着「自动生成：verif/ut/IssueQueue_common/<lib>」。
# 原判据只认薄壳 ⇒ 报「一个调用者都没有」并当场 return —— 闸常红，而且这 18 变体 ×
# 4 种产物**一个字节都没被验过**（真洞，不是误报：修之前 2 份 fm_target_config 确实与
# 生成器脱节）。修法是把这种调用形态**也跑起来**，不是放过它：
#   · 变体集合 = 已跟踪文件里带该库「自动生成」头、且不在库目录自身的文件所属变体；
#   · 每个变体都在 clean worktree 里跑 `<lib> <V> --check`，非零即红；
#   · 库若既无薄壳、也无带头产物、也不能空手独立运行 ⇒ 仍按「一个调用者都没有」判红。
# 不需要变体参数的库（如 gen_matrix.py：只写自己目录的 matrix.tsv）按普通生成器跑。
import re as _re0
_VARIANT_ARG = _re0.compile(r"""add_argument\(\s*['"]variant['"]|sys\.argv\[1\]""")
_CHECK_DECL0 = _re0.compile(r"""add_argument\(\s*['"]--check['"]|['"]--check['"]\s*(?:in\s+sys\.argv|==)""")


def lib_takes_variant(text):
    return bool(_VARIANT_ARG.search(text))


def variants_from_headers(lib_rel, files):
    """files: [(repo 相对路径, 文本)]。返回 (变体集合, 无法归属的路径列表)。

    头必须精确是 `自动生成：<lib_rel>`，后面不能紧跟标识符字符或 `.`
    （gen_tb.py 不许匹配 gen_tb_sched.py）。库目录自身的文件（库的 docstring/模板）不算。"""
    pat = _re0.compile('自动生成：' + _re0.escape(lib_rel) + r'(?![\w.])')
    lib_dir = lib_rel.rsplit('/', 1)[0] + '/'
    out, orphan = set(), []
    for rel, txt in files:
        if rel.startswith(lib_dir) or not pat.search(txt):
            continue
        parts = rel.split('/')
        if rel.startswith('verif/ut/') and len(parts) >= 4:
            out.add(parts[2])
        elif rel.startswith('verif/fm_target_config/') and len(parts) == 3 and rel.endswith('.tcl'):
            out.add(parts[2][:-len('.tcl')])
        else:
            orphan.append(rel)
    return out, orphan


def _header_files(lib_rel):
    r = sh(['git', 'grep', '-l', '-F', '自动生成：' + lib_rel, 'HEAD', '--', 'verif'], REPO)
    rels = [l.split(':', 1)[1] for l in r.stdout.decode('utf-8', 'replace').splitlines() if ':' in l]
    out = []
    for rel in rels:
        b = sh(['git', 'show', 'HEAD:' + rel], REPO).stdout
        out.append((rel, b.decode('utf-8', 'replace')))
    return out


def selftest():
    """正反测：variants_from_headers 的归属与精确匹配。"""
    lib = 'verif/ut/X_common/gen_tb.py'
    fails = []

    def eq(name, got, want):
        if got != want:
            fails.append('%s: got %r want %r' % (name, got, want))
    h = '# 自动生成：verif/ut/X_common/gen_tb.py —— 勿手改\n'
    eq('pos:ut 变体', variants_from_headers(lib, [('verif/ut/A/tb.sv', h)]), ({'A'}, []))
    eq('pos:fm_target_config 变体',
       variants_from_headers(lib, [('verif/fm_target_config/B.tcl', h)]), ({'B'}, []))
    eq('neg:库目录自身不算调用者', variants_from_headers(lib, [('verif/ut/X_common/m.tsv', h)]),
       (set(), []))
    eq('neg:前缀撞名 gen_tb_sched 不算 gen_tb',
       variants_from_headers(lib, [('verif/ut/S/tb.sv',
                                    '# 自动生成：verif/ut/X_common/gen_tb_sched.py\n')]), (set(), []))
    eq('neg:无头不算', variants_from_headers(lib, [('verif/ut/A/tb.sv', '// hand\n')]), (set(), []))
    eq('neg:无法归属的位置必须报出来',
       variants_from_headers(lib, [('rtl/backend/Z.sv', h)]), (set(), ['rtl/backend/Z.sv']))
    eq('pos:变体参数识别 argparse', lib_takes_variant("ap.add_argument('variant')"), True)
    eq('pos:变体参数识别 argv', lib_takes_variant("v = sys.argv[1]"), True)
    eq('neg:无变体参数', lib_takes_variant("ap.add_argument('--check', action='store_true')"), False)
    for f in fails:
        print('  FAIL ' + f)
    print('test_gen_idempotent --selftest: %d 条，失败 %d' % (9, len(fails)))
    return 1 if fails else 0


def main():
    # ★2026-09-20 扩范围：原先只 glob 'gen.py'★
    # 实测：verif/ut 下 97 个 gen*.py 里只有 53 个恰好叫 gen.py，
    # ★另外 44 个一直在这道闸之外★ —— 其中包括全部 gen_fm_pins.py，
    # 也就是整个签核依赖的钉点文件的生成器。
    # check_gen_gate_complete.py 的注释里写着「verif/ut/*/gen.py 那一层是统一重跑验的」，
    # 那句话只对**恰好叫 gen.py** 的那 53 个成立，其余按文件名静默漏掉。
    gens = sorted(REPO.glob('verif/ut/*/gen*.py'))
    if not gens:
        print('test_gen_idempotent: 一个 gen*.py 都没找到——闸空转，按失败处理')
        return 1

    # 需要必选参数、但自带 --check 的：用 --check 代替"重跑+比字节"
    # ★判定只看"支不支持 --check"，不看 argv 风格★
    # 第一版加了 'sys.argv[1]' in text 这个条件，结果 argparse 风格的
    # TlbStorageWrapper/gen_tb_variant.py 没被认出来，空手调用当场 rc=2。
    # 判据在回答另一个问题（"它是不是用 sys.argv[1] 取参数"），而我要问的是
    # "它能不能自检"——★条件多一个不是更严，是判错对象★。
    # ★verif/ut/*_common/ 下的是**库**，不是可独立运行的生成器★
    # 它们由各变体目录里的薄壳调用（薄壳供模块名），单独跑会把 `--check`
    # 当成模块名：FileNotFoundError: .../golden-rtl/--check.sv / KeyError: '--check'。
    # ★排除必须配一条正面断言，否则排除本身就是新的洞★：
    # 每个被排除的库至少要有一个薄壳调用者在本次清扫里，且那些薄壳是真跑过的。
    libs = {g for g in gens if g.parent.name.endswith('_common')}
    gens = [g for g in gens if g not in libs]
    lib_jobs = []          # (lib, 变体名)：在 clean worktree 里跑 `<lib> <V> --check`
    standalone_libs = []   # 不要变体参数的库：当普通生成器跑
    for lib in sorted(libs):
        callers = [g for g in gens
                   if lib.parent.name in g.read_text(errors='replace')
                   and g.name == lib.name]
        if callers:
            continue
        lib_rel = str(lib.relative_to(REPO))
        text = lib.read_text(errors='replace')
        if not lib_takes_variant(text):
            standalone_libs.append(lib)
            continue
        vs, orphan = variants_from_headers(lib_rel, _header_files(lib_rel))
        if orphan:
            print('test_gen_idempotent: 库 %s 的「自动生成」产物落在无法归属变体的位置：%s'
                  % (lib_rel, ', '.join(orphan[:5])))
            return 1
        if not vs:
            print('test_gen_idempotent: 库 %s 被排除但★一个调用者都没有★——'
                  '排除会变成覆盖漏洞' % lib_rel)
            return 1
        if not _CHECK_DECL0.search(text):
            print('test_gen_idempotent: 库 %s 被直接带变体调用（%d 个变体）却不支持 --check——'
                  '无法验幂等' % (lib_rel, len(vs)))
            return 1
        lib_jobs += [(lib, v) for v in sorted(vs)]
    gens = gens + standalone_libs

    # ★判定"支不支持 --check"不能只看文件里有没有这串字★（2026-09-20 实测踩过）
    # Entries_common / OthersEntry_common 的 docstring 里写着 `gen_fm_pins.py --check`，
    # 字符串在、行为不在——它们仍要模块名。「文件里有 --check」在回答另一个问题。
    # 这里只对**非库**的生成器启用 --check，且要求它是 argparse 注册或与 argv 比较的形态。
    import re as _re
    _CHECK_DECL = _re.compile(r"""add_argument\(\s*['"]--check['"]|['"]--check['"]\s*(?:in\s+sys\.argv|==)""")
    check_mode = {g for g in gens
                  if g.name != 'gen.py' and _CHECK_DECL.search(g.read_text(errors='replace'))}
    # 需要参数且**不支持** --check 的：显式登记，不许隐式跳过
    # ★只许缩不许长★：新加的生成器要么能空跑、要么挂 --check，不许往这张表里加。
    NEEDS_ARGS_NO_CHECK = {'verif/ut/Ftq/gen_tb.py'}
    gens = [g for g in gens if str(g.relative_to(REPO)) not in NEEDS_ARGS_NO_CHECK]

    wt = pathlib.Path(tempfile.mkdtemp(prefix='xsv2-genidem-'))
    shutil.rmtree(str(wt))                       # worktree add 要求目录不存在
    r = sh(['git', 'worktree', 'add', '--detach', str(wt), 'HEAD'], REPO)
    if r.returncode != 0:
        print('test_gen_idempotent: 建 worktree 失败\n' + r.stdout.decode('utf-8', 'replace'))
        return 1

    import os
    env = dict(os.environ, XSSV_HOME=str(wt), XSSV_INDEX_HOME=str(REPO))
    bad = []
    try:
        for g in gens:
            d = wt / g.relative_to(REPO).parent
            # ★有些生成器需要必选参数（sys.argv[1]），空手调用会 IndexError★
            # 那不是"不幂等"，是调用方式不对。实测扩范围后 97 个里恰好 4 个属此类：
            #   Entries_common/gen_fm_pins.py / OthersEntry_common/gen_fm_pins.py
            #   TlbStorageWrapper/gen_tb_variant.py   -> 三个都支持 --check，改用它
            #   Ftq/gen_tb.py                         -> 不支持，登记在 NEEDS_ARGS 里
            # ★把"调用方式不对"记成"不幂等"会让这道闸常红，而常红的闸等于没信号。★
            if g in check_mode:
                r = sh([sys.executable, g.name, '--check'], d, env)
                if r.returncode != 0:
                    bad.append('%s --check 非零退出 (rc=%d)：%s'
                               % (g.relative_to(REPO), r.returncode,
                                  r.stdout.decode('utf-8', 'replace').strip()[:400]))
                continue
            r = sh([sys.executable, g.name], d, env)
            if r.returncode != 0:
                bad.append('%s 跑挂了 (rc=%d)：%s'
                           % (g.relative_to(REPO), r.returncode,
                              r.stdout.decode('utf-8', 'replace').strip()[-300:]))
                continue
            st = sh(['git', 'status', '--porcelain'], wt).stdout.decode('utf-8', 'replace')
            if st.strip():
                bad.append('%s 重跑后产物变了（库里那份不是它生成的）：\n    %s'
                           % (g.relative_to(REPO),
                              '\n    '.join(st.strip().splitlines()[:8])))
                sh(['git', 'checkout', '--', '.'], wt)
                sh(['git', 'clean', '-fdq'], wt)
        for lib, v in lib_jobs:
            d = wt / lib.relative_to(REPO).parent
            r = sh([sys.executable, lib.name, v, '--check'], d, env)
            if r.returncode != 0:
                bad.append('%s %s --check 非零退出 (rc=%d)：%s'
                           % (lib.relative_to(REPO), v, r.returncode,
                              r.stdout.decode('utf-8', 'replace').strip()[:400]))
        st = sh(['git', 'status', '--porcelain'], wt).stdout.decode('utf-8', 'replace')
        if lib_jobs and st.strip():
            bad.append('库 --check 跑完工作树被改了（--check 不许写）：\n    %s'
                       % '\n    '.join(st.strip().splitlines()[:8]))
    finally:
        sh(['git', 'worktree', 'remove', '--force', str(wt)], REPO)

    if bad:
        print('test_gen_idempotent: %d/%d 个生成器(含库×变体)不幂等：'
              % (len(bad), len(gens) + len(lib_jobs)))
        for b in bad:
            print('  - ' + b)
        return 1
    # ★结论行必须如实描述这一轮到底验了什么★
    # 原文写的是 "verif/ut/*/gen.py 重跑后产物逐字不变"，但扩范围后实际是
    # gen*.py、排除了库、且其中一部分走的是 --check 而不是"重跑+比字节"。
    # 留着那句话，这道闸的输出本身就成了一条误导性断言。
    n_rerun = len(gens) - len(check_mode)
    print('test_gen_idempotent: %d 个 verif/ut/*/gen*.py 通过'
          '（%d 个重跑后产物逐字不变 / %d 个走自带 --check）；'
          '*_common 库 %d 个：%d 个经薄壳调用者覆盖、%d 个独立运行（已计入上数）、'
          '%d 个直接带变体调用（%d 个 库×变体 --check 通过）；'
          '另排除 %d 个需参数且无 --check 的'
          % (len(gens), n_rerun, len(check_mode), len(libs),
             len(libs) - len(standalone_libs) - len({l for l, _ in lib_jobs}),
             len(standalone_libs), len({l for l, _ in lib_jobs}), len(lib_jobs),
             len(NEEDS_ARGS_NO_CHECK)))
    return 0


if __name__ == '__main__':
    if sys.argv[1:] == ['--selftest']:
        sys.exit(selftest())
    sys.exit(main())
