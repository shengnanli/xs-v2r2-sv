#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""check_pkg_scope.py —— 编译单元作用域防腐闸：重名 / 共享包落点 / `$unit` import / `timescale。

本闸的四条判据是同一个病的四种形态：**写在文件里、作用域却是整个编译单元的东西，
会跨文件泄漏，且泄漏结果取决于文件顺序**。UT/FM 每次只编一个文件，永远看不见它们；
只有整芯片一起编时才发作，而那时往往不报错，只是**静默地取了错的值**。

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

## 三条判据

**A. 重名（硬错，无例外）**：同一个 package 名在 `rtl/` 下被定义两次即 FAIL。
   这不是风格问题——它在任何多文件编译单元里都是编译错误，没有合法用法。

**B. 跨文件共享包的落点**：一个 package 被**定义它的那个文件之外**的文件引用时，
   它就是跨模块共享件，按 CONVENTIONS.md 必须住在
   `rtl/<subsys>/<subsys>_common_pkg.sv`（或自己的专用包文件）里，而不是藏在某个
   兄弟模块的 .sv 里。藏着的代价有两条，都实测过：
     1. 制造**文件顺序依赖** —— VCS 要求 package 先于使用者编译，按路径字母序排
        FTBBank.sv 先于定义 `xs_ftb_pkg` 的 FTBEntryGen.sv，直接
        `Error-[SV-LCM-PND] Package not defined`，再连锁 5 条 UTFP/IND/SE。
     2. 读者打开 FTBBank.sv 找不到类型定义在哪。
   2026-09-14 的三处（`xs_ftb_pkg` / `xs_tlbsw_pkg` / `plic_pkg`）已全部搬进各自
   子系统的公共包文件，登记例外表因此**清空**：本判据现在零例外。

**C. `$unit` 作用域 import（硬错，无例外）**：写在任何 module/package/interface 之外的
   `import <pkg>::*;` 属于**编译单元作用域**。VCS 默认整个编译是单一编译单元，于是
   这种 import **跨文件泄漏**：一个文件的私有包会出现在所有其它文件的名字空间里。

   实测（VCS W-2024.09-SP1，最小样例 + 仓库真文件，两次都复现）：两个文件各在模块外
   通配 import 一个包，两个包都定义 `IDX_BITS`（probequeue_pkg=3 / writebackqueue_pkg=5）：

     * 两个模块都引用该名字时：VCS **退出码 0、0 条 Error、0 条 Warning**，
       两个模块都拿到**排在前面那个文件**的包的值。换文件顺序，两个模块的值一起翻。
     * 仓库真文件复现：今日文件序（ProbeQueue.sv 在前）下，若在 WritebackQueue 自己的
       核体里用一次 `IDX_BITS`，它拿到的是 **3**（ProbeQueue 的值），而它自己的包里
       写的是 5 —— rc=0，无任何 Error/Warning。这就是一个**静默的位宽错误**。

   ★ UT 和 FM 永远看不见这种错 ★：它们各编各的文件，只有整芯片一起编才有第二个包
   在场。所以这里必须有一道闸。

   上面那条「0 Error / 0 Warning 地取前一个包的值」是**工具行为**，不是从 LRM 推出来的，
   所以它可复跑：`bash scripts/demo_unit_scope_leak.sh`（需要 VCS，故不进 gate_all）。
   它两种写法 × 两种文件序各编一次并断言结果；哪天 VCS 行为变了，它会当场报不符。

   合法写法是把 import 放进**模块头**（作用域限定在该模块内）：

       module xs_Foo_core
         import foo_pkg::*;
       (
         ...
       );

   参考 `rtl/frontend/PreDecode.sv` / `rtl/frontend/F3Predecoder.sv`。

**D. `timescale`（硬错，无例外）**：`rtl/` 下任何文件出现 `` `timescale `` 即 FAIL。

   `timescale` 是**编译单元作用域的编译器指令**，不是模块属性：它从出现处起一直生效到
   下一条 `timescale`（或 `` `resetall ``），**跨文件向后传播**。于是「哪些模块拿到哪个
   时间精度」由**命令行上的文件顺序**决定，而不是由代码决定。

   实测（2026-09-14，本泳道）：G1 golden 的 2061 个文件里带 `timescale` 的是 **0 个**
   —— golden 整芯片全靠仿真器默认精度。而 `rtl/` 下有 2 个重写件带 `` `timescale 1ns/1ps ``
   （SubDirectory.sv:60 / SubDirectory_1.sv:61）。整芯片 impl 侧仿真把它们与 golden 件
   混编时，这两条指令会把**排在它们之后的所有 golden 模块**的精度一并改成 1ns/1ps，
   而 golden 侧同一批模块是默认精度 —— 两侧时间精度不同，且差异范围随文件顺序漂移。
   影响面实测（`sim-work/impl/files_impl_nosimtop.f`，2074 个文件）：SubDirectory.sv 排在
   第 281 位 —— 它后面还有 **1793 个文件**，整芯片 impl 侧编译时全部继承 1ns/1ps；
   而 golden 侧同一批文件拿的是 VCS 命令行给的 `-timescale=1ns/1ns`。

   ★ 而且这不只是「潜在」隐患 —— 它**已经在两侧之间造成了可观测的差异** ★：
   difftest 自己的 vsrc（永远排在 VCS 命令行最末，所以必然落在那两条指令之后）有
   **7 处 `#0.1` 亚纳秒延时**（`src/test/vsrc/common/SimJTAG.v` 6 处、
   `src/test/vsrc/vcs/DifftestEndpoint.sv:359` 的 `#0.1 -> simv_step_event` 1 处）。
   golden 侧 1ns/1ns 把 `#0.1` 舍入成 0，impl 侧 1ns/1ps 保住 100 ps。证据在两份编译日志里：

       sim-work/golden/build.log : 1 条 Warning-[DRTZ] Detect delay value roundoff to 0
       sim-work/impl/build.log   : 0 条

   （G1 golden 的 2061 个文件里亚纳秒延时是 **0 处**，所以舍入差异全部落在 difftest 件上。）
   cputest 33/33 仍然 cycle-exact SAME —— JTAG 模型没被用到，那个事件触发在同一时刻内
   定序也没翻 —— 所以没有变成失配。但「两侧不是按同一套时间语义编出来的」这件事本身
   不该靠运气兜着，而且影响面随清单顺序漂移。删掉之后两侧语义一致。

   规则很简单：重写件与 golden 对照，golden 没有的编译单元级指令，重写件也不许有。
   时间精度应当由**仿真命令行**统一给（difftest 的 vcs.mk / UT 的 ut_common.mk），
   那是唯一一个所有文件都看得见同一个值的地方。

   注：本判据只管 `rtl/`。`verif/ut/*/tb.sv` 里的 `timescale` 不在扫描范围内，也不该管
   —— testbench 是编译的**入口**文件，它给整次编译定一个精度是合法且必要的用法。

## 环境变量
  XSSV_RTL    覆盖被扫描的 rtl 根目录（负测用；默认 <repo>/rtl）

## 退出码
  0 = 干净
  1 = 有 finding
"""
import collections
import os
import pathlib
import re
import sys

REPO = pathlib.Path(__file__).resolve().parent.parent
RTL = pathlib.Path(os.environ['XSSV_RTL']) if os.environ.get('XSSV_RTL') else REPO / 'rtl'

PKG_DEF = re.compile(r'^\s*package\s+(\w+)\s*;', re.M)
PKG_USE = re.compile(r'\b(\w+)\s*::')
SCOPE_OPEN = re.compile(r'^(module|package|interface|program|class|primitive|checker)\b')
SCOPE_CLOSE = re.compile(r'^end(module|package|interface|program|class|primitive|checker)\b')
IMPORT_LINE = re.compile(r'^import\s+([\w$]+)\s*::')
TIMESCALE = re.compile(r'^\s*`timescale\b(.*)$')

# 跨文件共享包的登记例外：包名 -> (定义它的文件, 为什么还没搬)。
# 2026-09-14 起为空——三处历史例外都已搬进子系统公共包文件。新增一处即 FAIL；
# 真要再登记，必须在这里写清"为什么还没修"，让理由和判据待在同一个地方。
KNOWN_CROSS_FILE = {}


def strip_comments(text):
    """去注释，但保留行数（findings 要报真实行号）。"""
    text = re.sub(r'/\*.*?\*/', lambda m: '\n' * m.group(0).count('\n'), text, flags=re.S)
    return re.sub(r'//[^\n]*', '', text)


def unit_scope_imports(text):
    """返回 [(行号, 包名)]：位于任何 module/package/interface 之外的 import。

    判定按词法嵌套深度做，与缩进无关 —— 模块外的 import 不管缩成什么样都是 `$unit`
    作用域，只看它在不在一对 module/endmodule（或 package/interface/…）里面。
    """
    hits, depth = [], 0
    for i, ln in enumerate(strip_comments(text).splitlines(), 1):
        s = ln.strip()
        if SCOPE_CLOSE.match(s):
            depth = max(0, depth - 1)
            continue
        if SCOPE_OPEN.match(s):
            depth += 1
            continue          # `module M import pkg::*; (` 是合法的模块头 import
        m = IMPORT_LINE.match(s)
        if m and depth == 0:
            hits.append((i, m.group(1)))
    return hits


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
            defs.setdefault(n, []).append(str(p.relative_to(REPO)) if REPO in p.parents or str(p).startswith(str(REPO)) else str(p))

    def rel(p):
        try:
            return str(p.relative_to(REPO))
        except ValueError:
            return str(p)

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
        # ★先去注释★：注释里写一句 `mainpipe_pkg::grow_starter`（讲「这张表与那边同一张」）
        # 不产生任何编译依赖，VCS 不会因此报 SV-LCM-PND。2026-10-02 实测 MissEntry.sv:234
        # 就是这种形态被判成 CROSS_FILE_PACKAGE —— 误报。判据 C/D 早就先 strip_comments，B 漏了。
        # 去注释保留行数与代码，真实的 `pkg::` 引用（含同行带尾注释的）照抓，见负测。
        for n in set(PKG_USE.findall(strip_comments(t))) & known:
            if n not in per_file_defs[p]:
                users[n].add(rel(p))
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

    # --- C $unit 作用域 import ---
    n_unit = 0
    for p in sorted(texts):
        for line, pkg in unit_scope_imports(texts[p]):
            n_unit += 1
            findings.append(
                f'UNIT_SCOPE_IMPORT  {rel(p)}:{line}  `import {pkg}::…;` 写在所有 module 之外 —— '
                f'这是**编译单元($unit)作用域**，会跨文件泄漏到整个编译里。实测 VCS 在两个包'
                f'导出同名量时 0 Error / 0 Warning 地取排在前面那个包的值（静默位宽错误），'
                f'UT/FM 各编各的文件永远看不见。改成模块头 import：'
                f'`module <M>\\n  import {pkg}::*;\\n(...)`，见 rtl/frontend/PreDecode.sv')

    # --- D `timescale（编译单元作用域指令，跨文件按顺序传播） ---
    # 单独扫一次：judge A-C 只读 *.sv，而 `timescale 藏在被 `include 的 *.svh 里
    # 同样致命（它在预处理展开后就是编译单元里的一条指令）。
    n_ts = 0
    for p in sorted(list(RTL.rglob('*.sv')) + list(RTL.rglob('*.svh'))):
        body = texts.get(p)
        if body is None:
            body = p.read_text(errors='replace')
        for i, ln in enumerate(strip_comments(body).splitlines(), 1):
            m = TIMESCALE.match(ln)
            if not m:
                continue
            n_ts += 1
            findings.append(
                f'TIMESCALE_DIRECTIVE  {rel(p)}:{i}  `timescale{m.group(1).rstrip()} —— '
                f'这是**编译单元作用域**的指令，从这里起一直生效到下一条 `timescale，'
                f'跨文件向后传播，于是「哪些模块用哪个时间精度」由命令行文件顺序决定。'
                f'G1 golden 2061 个文件里带 `timescale 的是 0 个；重写件带了，整芯片混编时'
                f'会把排在其后的 golden 模块精度一并改掉，两侧精度不同且范围随顺序漂移。'
                f'删掉它，精度统一由仿真命令行给（tb.sv 作为编译入口文件不受本判据管）')

    print(f'check_pkg_scope: {RTL} 下 {len(defs)} 个 package，'
          f'{sum(len(v) for v in defs.values())} 处定义，'
          f'{n_unit} 处 $unit 作用域 import，{n_ts} 处 `timescale')
    if findings:
        for f in findings:
            print('  ★ ' + f)
        return 1
    print('check_pkg_scope: 干净')
    return 0


if __name__ == '__main__':
    sys.exit(main())
