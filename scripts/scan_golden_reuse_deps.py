#!/usr/bin/env python3
"""scan_golden_reuse_deps.py —— 筛出「已有重写件、却仍两侧同喂 golden」的子依赖。

## 这条判据是从哪来的

codex 0168 对 Sbuffer 的裁定，原话：

> `SbufferData` 已有重写件，impl 侧却仍使用 golden 源码，此配置不能签作
> "重写 Sbuffer 整体已证"。先将 impl 侧 `SbufferData` 接到重写件并跑真实 FM。

机制在 `scripts/ut_common.mk:167`：

    FM_IMPL_SRCS = $(abspath $(RTL_SRCS) $(RTL_GOLDEN_DEPS))

`RTL_GOLDEN_DEPS` 同时进 impl 侧和（经 `GOLDEN_SRCS` / `FM_REF_DEPS_<top>`）ref 侧。
一个子模块放在这里 = 两侧读**同一份字节**，FM 对这一块必判等价。
当这个子模块**本来就没有重写件**时，这是诚实的（UNCHANGED_GOLDEN_DEP，
本 target 对它零信息量，照实记就是）；当它**已经有重写件**时，就是白送 ——
本该被证的那一块被换成了 golden 自己。

## 本脚本做什么

对每个 `verif/ut/*/Makefile`：用 `make --eval` 让 make 自己展开
`RTL_GOLDEN_DEPS` 与 `RTL_SRCS`（不手抄），然后报出满足**两个条件**的条目：

  1. 该 golden 文件的模块名在 `rtl/` 下**已有同名重写件**（非 `xs_` 前缀的 module）；
  2. 该文件名**不在** `RTL_SRCS` 里（在的话说明已经改指过了）。

## ★这是报告，不是闸★

不接进 `scripts/gate_all.sh`，也不非零退出（除非用法错）。理由：

  · 命中项分布在 24 个 UT 目录、由不同 lane 拥有，直接变成硬闸会当场把别人的
    构建判红，而其中一部分需要的不是"改指"而是"换变量"
    （见 `verif/ut/StdFreeList/Makefile` 的注释：子模块若被 UT 的 **golden 那侧**
    也例化，改路径会让双例化对比当场失效，必须换变量）；
  · 判据本身只是**筛**：命中 ≠ 一定错。有重写件但**故意**不接的情形需要逐条给理由
    （并按 0168 的要求写成 UNCHANGED_GOLDEN_DEP / 子依赖未闭合），
    这件事只能由该 target 的 owner 做，脚本替不了。

所以它的定位是：把"哪些地方可能在白送"从**要人记得去查**变成**一条命令列出来**。

用法:
  python3 scripts/scan_golden_reuse_deps.py            # 全仓
  python3 scripts/scan_golden_reuse_deps.py --only Sbuffer TageTable
退出码: 0 正常（无论命中多少）；2 用法/环境错。
"""
import argparse
import pathlib
import re
import subprocess
import sys

REPO = pathlib.Path(__file__).resolve().parent.parent
MODULE_DECL = re.compile(r'^\s*module\s+([A-Za-z_]\w*)', re.M)


def rewritten_modules():
    """rtl/ 下声明的、不以 xs_ 开头的 module 名 -> 所在文件（第一次出现者）。

    只取非 `xs_` 前缀：单文件规范下那才是与 golden 同名的 wrapper，
    也就是"这个 golden 模块已经有重写件"的判据。
    """
    out = {}
    for f in sorted((REPO / 'rtl').rglob('*.sv')):
        for m in MODULE_DECL.finditer(f.read_text(errors='replace')):
            n = m.group(1)
            if not n.startswith('xs_'):
                out.setdefault(n, f)
    return out


def expand(utdir):
    """让 make 自己展开两个变量 —— 手抄 Makefile 是这类扫描最常见的错法。"""
    try:
        raw = subprocess.check_output(
            ['make', '-s', '-f', 'Makefile',
             '--eval=__scan: ;@echo GD=$(RTL_GOLDEN_DEPS)\n\t@echo RS=$(RTL_SRCS)',
             '__scan'],
            cwd=str(utdir), stderr=subprocess.STDOUT).decode('utf-8', 'replace')
    except Exception as e:  # noqa: BLE001 —— 任何展开失败都要可见，不能当成"没问题"
        return None, None, str(e).splitlines()[0][:120]
    gd = rs = []
    for line in raw.splitlines():
        if line.startswith('GD='):
            gd = line[3:].split()
        elif line.startswith('RS='):
            rs = line[3:].split()
    return gd, rs, None


def main(argv=None):
    ap = argparse.ArgumentParser()
    ap.add_argument('--only', nargs='*', default=None, help='只看这些 UT 目录裸名')
    a = ap.parse_args(argv)

    rew = rewritten_modules()
    dirs = sorted(p.parent for p in (REPO / 'verif' / 'ut').glob('*/Makefile'))
    if a.only:
        want = set(a.only)
        dirs = [d for d in dirs if d.name in want]
        missing = want - {d.name for d in dirs}
        if missing:
            print(f'ERROR: 没有这些 UT 目录: {sorted(missing)}', file=sys.stderr)
            return 2

    hits, errs = [], []
    for d in dirs:
        gd, rs, err = expand(d)
        if err is not None:
            errs.append((d.name, err))
            continue
        rs_base = {pathlib.Path(x).name for x in rs}
        for g in gd:
            base = pathlib.Path(g).name
            mod = base[:-3] if base.endswith('.sv') else base
            if mod in rew and base not in rs_base:
                hits.append((d.name, mod, str(rew[mod].relative_to(REPO))))

    print(f'{"UT目录":<26} {"两侧同喂的 golden 子模块":<30} 已存在的重写件')
    for r in sorted(hits):
        print(f'{r[0]:<26} {r[1]:<30} {r[2]}')
    uts = len({h[0] for h in hits})
    print(f'--- 命中 {len(hits)} 条，分布在 {uts} 个 UT 目录（共扫 {len(dirs)} 个）---')
    if errs:
        print(f'--- make 展开失败 {len(errs)} 个（**未判定，不等于没问题**）---')
        for n, e in errs:
            print(f'    {n}: {e}')
    print('命中 ≠ 一定错：需由该 target 的 owner 逐条判——改指重写件，'
          '或按 codex 0168 明确记成 UNCHANGED_GOLDEN_DEP / 子依赖未闭合。')
    return 0


if __name__ == '__main__':
    sys.exit(main())
