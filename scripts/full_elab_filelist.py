#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""full_elab_filelist.py —— 生成「整芯片 elaborate」的源文件清单（重写件优先）。

## 这个脚本解决的问题

单目标 UT 每次只把**一个**重写文件与它的 golden 对照编进一次 elaboration。
整芯片 elaborate 是完全不同的场景：292 个重写文件 + 1757 个未重写 golden 文件
**一起**进同一个编译单元。两件事只在这个场景下才会暴露：

  1. 全局名字空间冲突（package 名、模块名）——package 名在 SystemVerilog 里是全局的，
     单文件编译永远看不见重名。
  2. 重写件与 golden 件同名——这正是重写工程的常态（wrapper 与 golden 同名是规范要求），
     必须有一条明确的取舍规则，而不是靠命令行顺序碰运气。

## 取舍规则（机械、可复算，无人工名单）

  - golden 清单以 `<golden>/filelist.f` 为准（2030 项，实测**一文件一模块、零重名、
    零缺失**，所以「文件」与「模块名」一一对应，可以按名字做取舍）。
  - 扫 `rtl/**/*.sv` 里每个文件声明的模块名；凡是与某个 golden 模块同名的，
    **该 golden 文件被剔除，用重写文件顶上**（重写件优先）。
  - 重写件里 `xs_*` 前缀的核/辅助件 golden 侧没有同名者，直接进清单。
  - 只含 package 的文件（`*_common_pkg.sv`、`alu_pkg.sv`）排在最前，其余重写文件再按
    「package 定义先于使用」做拓扑排序：SystemVerilog 要求 package 在被引用之前已经
    编译过，VCS 对文件顺序是**真敏感**的（实测：按路径字母序排时 FTBBank.sv 先于
    定义 `xs_ftb_pkg` 的 FTBEntryGen.sv，当场
      Error-[SV-LCM-PND] Package not defined ... Move package definition before the use
    外加 5 条 UTFP/IND/SE 连锁错误）。排序是机械的，不需要人工维护顺序表。
  - 厂商 SRAM 宏 `array_*_ext.v` 与 `ClockGate.sv` 不在 filelist.f 里（它们在
    `firrtl_black_box_resource_files.f`），但整芯片 elaborate 需要它们的行为模型，
    故显式补进来。difftest 的 `DiffExt*.v` / `*Helper.v` 只有 SimTop 用得上，
    XSTop 顶层不需要，默认不进（`--with-difftest` 可加）。

fail-closed：任何一条「同一个模块名被两个重写文件声明」「filelist 里的文件不存在」
「一个 golden 文件声明了 0 或 ≥2 个模块」都直接退出，不猜、不静默跳过。
（实测 extern_modules.sv 声明 0 个模块——它是 firtool 的宏定义头，作为已知例外白名单。）

用法:
  python3 scripts/full_elab_filelist.py --out build_full_elab/files.f
  python3 scripts/full_elab_filelist.py --golden-only --out build_full_elab/golden.f
  python3 scripts/full_elab_filelist.py --report      # 只打取舍统计，不写文件
"""
import argparse
import collections
import pathlib
import re
import sys

REPO = pathlib.Path(__file__).resolve().parent.parent
GOLDEN_DEFAULT = '/home/eda/xs-env/G1-canonical/golden-rtl'

MODULE_RE = re.compile(r'^\s*module\s+(\w+)', re.M)
PKG_DEF_RE = re.compile(r'^\s*package\s+(\w+)\s*;', re.M)
PKG_USE_RE = re.compile(r'\b(\w+)\s*::')
# firtool 产出的宏定义头，没有任何 module；不是错误。
NO_MODULE_OK = {'extern_modules.sv'}
# 此处曾有一张 BYTE_DUP_DROP 名单，用来把两组逐字节重复
# （rtl/common/{DataModule,SyncDataModule}.sv 与各自的 xs_ 前缀孪生）在整芯片清单里
# 机械剔除一份——因为同一个模块名在两个文件里定义，整芯片只能进一份。
# 2026-09-14 cleanup：两组已真正合并（删掉无前缀那份，FtqPcMemWrapper UT 改指
# xs_ 前缀），名单随之清空并撤掉。**不要把它加回来**：现在任何新出现的同名重复
# 都会撞下面 fail-closed 的「同一个模块名被多个重写文件声明」，这正是想要的行为；
# 靠一张剔除名单绕过去只会把重复养大。


def die(msg):
    print('full_elab_filelist: FATAL: ' + msg, file=sys.stderr)
    sys.exit(2)


def scan(path):
    return MODULE_RE.findall(path.read_text(errors='replace'))


def pkg_order(files):
    """按「package 定义先于使用」拓扑排序；同层保持原有（路径字母）序，结果稳定。

    fail-closed：有环（两个文件互相用对方的包）就直接报错——那在 SystemVerilog 里
    本来就没有合法的单编译单元文件顺序，必须先重构，不能靠排序糊过去。
    """
    defs, uses = {}, {}
    for p in files:
        t = p.read_text(errors='replace')
        d = set(PKG_DEF_RE.findall(t))
        defs[p] = d
        uses[p] = set(PKG_USE_RE.findall(t)) - d
    known = {n for d in defs.values() for n in d}
    for p in files:
        uses[p] &= known               # 只管本仓自己定义的包
    out, pending, have = [], list(files), set()
    while pending:
        ready = [p for p in pending if uses[p] <= have]
        if not ready:
            die('package 依赖成环，无法给出合法的文件顺序：\n  ' +
                '\n  '.join(f'{p}: 还缺 {sorted(uses[p] - have)}' for p in pending[:10]))
        for p in ready:
            out.append(p)
            have |= defs[p]
        pending = [p for p in pending if p not in set(ready)]
    return out


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--golden', default=GOLDEN_DEFAULT)
    ap.add_argument('--rtl', default=str(REPO / 'rtl'))
    ap.add_argument('--out')
    ap.add_argument('--golden-only', action='store_true',
                    help='只出纯 golden 清单（做对照基线用：先证明 golden 自己能过）')
    ap.add_argument('--with-difftest', action='store_true',
                    help='把 DiffExt*/-Helper 的 difftest 行为模型也放进来（SimTop 顶层才需要）')
    ap.add_argument('--report', action='store_true')
    a = ap.parse_args()

    G = pathlib.Path(a.golden)
    R = pathlib.Path(a.rtl)
    # ★ 归一化 `./` 前缀 ★：filelist.f 里绝大多数是裸文件名，但有一条写成
    # `./ClockGate.sv`。不归一化的后果是「按名字去重」认不出它，于是黑盒资源那步
    # 又补一次，VCS 报 Warning-[OPD] module 'ClockGate' previously declared。实测踩过。
    fl = [l.strip().lstrip('./') for l in (G / 'filelist.f').read_text().splitlines()
          if l.strip()]

    # --- golden 侧：文件 -> 模块名（fail-closed 校验一文件一模块） ---
    gold_file_of = {}           # module name -> golden file
    for f in fl:
        p = G / f
        if not p.exists():
            die(f'filelist.f 里的 {f} 在 {G} 下不存在')
        names = scan(p)
        if not names:
            if f in NO_MODULE_OK:
                continue
            die(f'golden {f} 声明了 0 个模块，而它不在已知例外名单里')
        if len(names) > 1:
            die(f'golden {f} 声明了 {len(names)} 个模块 {names}；'
                f'本脚本的取舍规则建立在「一文件一模块」上，请先处理这一条')
        if names[0] in gold_file_of:
            die(f'golden 模块名 {names[0]} 出现在两个文件里：'
                f'{gold_file_of[names[0]]} 与 {f}')
        gold_file_of[names[0]] = f

    # --- 重写侧 ---
    impl_files = sorted(p for p in R.rglob('*.sv'))

    owner = collections.defaultdict(list)   # module name -> [impl file]
    pkg_only, with_mod = [], []
    for p in impl_files:
        names = scan(p)
        for n in names:
            owner[n].append(str(p.relative_to(REPO)))
        (pkg_only if not names else with_mod).append(p)

    conflicts = {n: v for n, v in owner.items() if len(v) > 1}
    if conflicts:
        die('同一个模块名被多个重写文件声明（整芯片只能进一份）：\n  ' +
            '\n  '.join(f'{n}: {v}' for n, v in sorted(conflicts.items())))

    replaced = sorted(n for n in owner if n in gold_file_of)
    impl_only = sorted(n for n in owner if n not in gold_file_of)
    gold_keep = [f for f in fl
                 if f not in {gold_file_of[n] for n in replaced}]

    # --- 厂商宏 / 黑盒资源 ---
    # 注意通配符要写成 array*_ext.v：`array_ext.v`（没有编号的那一个）不匹配
    # `array_*_ext.v`。漏掉它的症状是 elaborate 末尾一条
    #   Error-[CFCILFBI] Cannot find cell 'array_ext' in liblist
    # —— 看起来像设计问题，其实是清单漏件。实测踩过一次。
    extras = sorted(str(p.name) for p in G.glob('array*_ext.v'))
    extras += ['ClockGate.sv']
    if a.with_difftest:
        extras += sorted(p.name for p in G.glob('DiffExt*.v'))
        extras += ['FlashHelper.v', 'Mem1R1WHelper.v', 'PrintCommitIDModule.v',
                   'SDCardHelper.v']
    for e in extras:
        if not (G / e).exists():
            die(f'黑盒资源 {e} 不存在于 {G}')
    # filelist.f 里已有的不再重复补（重复给同一个文件 VCS 会报
    # Warning-[OPD] module 'X' previously declared —— 纯噪音，会淹掉真问题）。
    extras = [e for e in extras if e not in set(fl)]

    print(f'golden filelist        : {len(fl)}')
    print(f'重写文件（rtl/**.sv）  : {len(impl_files)}'
          f'（其中只含 package 的 {len(pkg_only)}）')
    print(f'重写件顶掉的 golden    : {len(replaced)}')
    print(f'重写件独有模块(xs_*)   : {len(impl_only)}')
    print(f'保留的 golden 文件     : {len(gold_keep)}')
    print(f'补入的黑盒/宏资源      : {len(extras)}')

    if a.report and not a.out:
        return 0

    lines = []
    if a.golden_only:
        lines += [str(G / f) for f in fl]
    else:
        # package 先行 + 「定义先于使用」拓扑序
        lines += [str(p) for p in pkg_only]
        lines += [str(p) for p in pkg_order(with_mod)]
        lines += [str(G / f) for f in gold_keep]
    lines += [str(G / e) for e in extras]

    if a.out:
        out = pathlib.Path(a.out)
        out.parent.mkdir(parents=True, exist_ok=True)
        out.write_text('\n'.join(lines) + '\n')
        print(f'写出 {out}（{len(lines)} 项）')
    return 0


if __name__ == '__main__':
    sys.exit(main())
