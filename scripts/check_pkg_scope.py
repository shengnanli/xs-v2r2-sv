#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""check_pkg_scope.py —— package 名全局唯一 + 跨文件共享包必须落在子系统公共包（防腐闸）。

## 为什么需要这道闸（2026-09-14，codex 0158 §3 实测）

SystemVerilog 的 **package 名是全局的**，而本工程的单目标 UT 每次只把一个重写文件
编进一次 elaboration —— 于是「两个文件定义同名 package」这种**必然的编译错误**可以
在整个工程里潜伏任意久，直到有人第一次把它们放进同一个编译单元。

实测：`rtl/` 57 个 package 里有 2 个重名（`vset_pkg` 在 VSetRiWi.sv / VSetRvfWvf.sv，
`xs_predecode_pkg` 在 F3Predecoder.sv / PreDecode.sv），两对包体逐字相同，UT/FM 全绿，
**没有任何现有闸会响**；整芯片 elaborate 第一次跑就当场：

    Error-[SV-PPD] Package previously declared
    Identifier 'vset_pkg' is already declared in file ".../VSetRiWi.sv", line 30.

已修（抽到 `rtl/<subsys>/<subsys>_common_pkg.sv`）。本闸把「修好」变成「修住」。

## 两条判据

**A. 重名（硬错，无例外）**：同一个 package 名在 `rtl/` 下被定义两次即 FAIL。
   这不是风格问题——它在任何多文件编译单元里都是编译错误，没有合法用法。

**B. 跨文件共享包的落点（带登记例外）**：一个 package 被**定义它的那个文件之外**的
   文件引用时，它就是跨模块共享件，按 CONVENTIONS.md 必须住在
   `rtl/<subsys>/<subsys>_common_pkg.sv`（或自己的专用包文件）里，而不是藏在某个
   兄弟模块的 .sv 里。藏着的代价有两条，都实测过：
     1. 制造**文件顺序依赖** —— VCS 要求 package 先于使用者编译，按路径字母序排
        FTBBank.sv 先于定义 `xs_ftb_pkg` 的 FTBEntryGen.sv，直接
        `Error-[SV-LCM-PND] Package not defined`，再连锁 5 条 UTFP/IND/SE。
     2. 读者打开 FTBBank.sv 找不到类型定义在哪。
   当前已存在 3 处（见 KNOWN_CROSS_FILE），**本轮不重构**（每处都要重跑两个目标的
   UT+FM，不属于本次任务范围），故登记为例外；**新增**一处即 FAIL。
   登记表写在本文件里而不是另开 tsv：条目只有 3 条，且每条都要一句"为什么还没修"，
   放在判据旁边比放在另一个文件里更难腐烂。

## 退出码
  0 = 干净（含仅命中登记例外）
  1 = 有 finding
"""
import collections
import pathlib
import re
import sys

REPO = pathlib.Path(__file__).resolve().parent.parent
RTL = REPO / 'rtl'

PKG_DEF = re.compile(r'^\s*package\s+(\w+)\s*;', re.M)
PKG_USE = re.compile(r'\b(\w+)\s*::')

# 登记的跨文件共享包例外：包名 -> (定义它的文件, 为什么还没搬)
KNOWN_CROSS_FILE = {
    'xs_ftb_pkg': ('rtl/frontend/FTBEntryGen.sv',
                   'FTBBank.sv 引用；搬走要重跑 FTBEntryGen + FTBBank 两个目标的 UT+FM，'
                   '不在 codex 0158 §3 的改动范围内'),
    'xs_tlbsw_pkg': ('rtl/memblock/TlbStorageWrapper.sv',
                     'TlbStorageWrapper_1.sv 引用；同一家族的变体薄文件共用父文件的包，'
                     '搬走要重跑整个 TlbStorageWrapper 家族'),
    'plic_pkg': ('rtl/uncore/PLICFanIn.sv',
                 'TLPLIC.sv 引用；搬走要重跑 PLICFanIn + TLPLIC 两个目标的 UT+FM'),
}


def main():
    defs = {}          # pkg -> [file]
    per_file_defs = {}
    texts = {}
    for p in sorted(RTL.rglob('*.sv')):
        t = p.read_text(errors='replace')
        texts[p] = t
        names = PKG_DEF.findall(t)
        per_file_defs[p] = set(names)
        for n in names:
            defs.setdefault(n, []).append(str(p.relative_to(REPO)))

    findings = []

    # --- A 重名 ---
    dup = {n: v for n, v in defs.items() if len(v) > 1}
    for n, v in sorted(dup.items()):
        findings.append(f'DUPLICATE_PACKAGE  {n}  定义于 {v} —— '
                        f'package 名是全局的，两个文件一起编译必然 Error-[SV-PPD]')

    # --- B 跨文件共享包的落点 ---
    known = set(defs)
    users = collections.defaultdict(set)
    for p, t in texts.items():
        for n in set(PKG_USE.findall(t)) & known:
            if n not in per_file_defs[p]:
                users[n].add(str(p.relative_to(REPO)))
    for n, us in sorted(users.items()):
        home = defs[n][0]
        stem = pathlib.Path(home).name
        ok_home = stem.endswith('_common_pkg.sv') or stem == f'{n}.sv'
        if ok_home:
            continue
        if n in KNOWN_CROSS_FILE and KNOWN_CROSS_FILE[n][0] == home:
            print(f'[已登记例外] {n} 定义于 {home}，被 {sorted(us)} 引用 —— '
                  f'{KNOWN_CROSS_FILE[n][1]}')
            continue
        findings.append(
            f'CROSS_FILE_PACKAGE  {n}  定义于 {home}，却被 {sorted(us)} 引用 —— '
            f'跨模块共享的包按 CONVENTIONS.md 要放 rtl/<subsys>/<subsys>_common_pkg.sv；'
            f'藏在兄弟模块文件里会制造文件顺序依赖（VCS 会报 SV-LCM-PND）')

    print(f'check_pkg_scope: rtl/ 下 {len(defs)} 个 package，'
          f'{sum(len(v) for v in defs.values())} 处定义')
    if findings:
        for f in findings:
            print('  ★ ' + f)
        return 1
    print('check_pkg_scope: 干净')
    return 0


if __name__ == '__main__':
    sys.exit(main())
