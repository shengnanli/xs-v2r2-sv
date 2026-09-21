#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""prev_round_shell_audit.py —— 上一轮（xs-v2r2-sv）重写件「真重写 vs golden 套壳」全量审计。

## 这个脚本解决什么问题

本轮要决定哪些模块可以从上一轮移植、哪些必须白手起家。上一轮用过
`.svh` include 把 golden 原文藏进被包含文件蒙混验收（CONVENTIONS.md
「单文件规范」里「禁止 `.svh` include」那条就是这么来的），而**没人系统查过有多少**。

已有的 `scripts/prev_round_verbatim_scan.py` 是最接近的先例，但它有一处
**与本次问题正好对不上的盲点**：它只 `rglob('*.sv')`（manifest 里
`n_files: 909`），**202 个 `.svh`、204,373 行一行没扫**。而套壳藏东西的地方
恰恰就在 `.svh` 里。本脚本把 `.svh` 一并纳入，并把「文件」聚合成「模块」。

## 判据来源（不自创，全部沿用本轮已有口径）

- A 类禁用命名 `FORBIDDEN`、`codelines()`（去注释/去端口表/去结构行）、
  逐字重合行的五分类 `classify_line()` —— **逐字抄自
  `scripts/prev_round_verbatim_scan.py`**（它自己又抄自
  `scripts/readability_audit.py` G 类）。同一套判据，一个字没改。
- 本脚本**新增**一个更宽的 firtool 中间名口径 `FIRTOOL_TEMP`：
  `readability_audit.py` 的 `FORBIDDEN=\b_(GEN|T)(_\d+)?\b` 要求下划线前是
  **非单词字符**，于是 firtool 极常见的 `_deqPtr_T_1`、`_io_out_T_3`
  这种「前缀 + _T_n」**一个都不算**。两个口径都出，都进 TSV，互为交叉验证。

## 聚合方式（文件 -> 实现单元 -> golden 模块）

1. include 图：`\`include "x"` 全仓都是**裸文件名**、无路径、无 basename 冲突
   （已实测），故按 basename 解析。
2. 根文件 = 没有被任何别的文件 include 的 `.sv`；实现单元 = 根 + 其传递闭包。
3. 实现单元声明的 module 名里，凡在 golden 目录有同名 `<Name>.sv` 的即
   「本单元覆盖的 golden 模块」。
4. 同一个 golden 模块被多个根覆盖时（上一轮两文件布局：`Rob.sv` 核 +
   `Rob_wrapper.sv` 壳），把这些根并成**一个连通分量**一起报。
   分量 = 二部图（实现单元 ↔ golden 模块）的连通分量。
5. 被多个分量共享的文件（公共 pkg/svh）会在每个分量里各计一次行数，
   `shared_files` 列把它们点出来，便于复算时扣除。

## 用法

    python3 scripts/prev_round_shell_audit.py \
        --impl-root /home/eda/xs-env/xs-v2r2-sv/rtl \
        --golden /home/eda/xs-env/G0-canonical/golden-rtl \
        --golden-new /home/eda/xs-env/G1-canonical/golden-rtl \
        --ledger docs/coverage_three_axis.tsv \
        --out-files docs/prev_round_shell_audit_files.tsv \
        --out-modules docs/prev_round_shell_audit_modules.tsv \
        --manifest docs/prev_round_shell_audit.manifest.json

对照组（量「干净」基线密度）另跑一次，把 --impl-root/--golden 指向本轮：

    python3 scripts/prev_round_shell_audit.py \
        --impl-root rtl --golden /home/eda/xs-env/G1-canonical/golden-rtl \
        --out-files /dev/null --out-modules /dev/null --manifest /dev/null \
        --baseline-only

幂等：同输入 -> 同 TSV（行序固定、浮点定长），manifest 里带产物 sha256。
退出码 0 = 扫完（有命中是数据不是错误）；2 = 环境错误。
"""
import argparse
import collections
import hashlib
import json
import os
import pathlib
import re
import sys

# ---- 以下五段与 scripts/prev_round_verbatim_scan.py 逐字相同（判据必须同一套）----
FORBIDDEN = re.compile(r'\b_(GEN|T)(_\d+)?\b')
MOD_RE = re.compile(r'^(package|module)\s+(\w+)', re.MULTILINE)
_PORTLINE = re.compile(r'^\s*(input|output|inout)\b')
_STRUCTURAL = re.compile(
    r'^(\.\w+'
    r'|\)\s*\w*\s*;?$'
    r'|(wire|logic|reg|localparam|parameter|genvar|typedef|import|package|endpackage)\b'
    r'|[A-Za-z_]\w*(\s*#\s*\(.*)?\s+\w+\s*\($'
    r'|(begin|end|endmodule|endcase|endgenerate|endfunction|else)\b'
    r'|module\s+\w+'
    r'|\{|\}|,$)')

_CONCAT_ELEM = re.compile(r'^[A-Za-z_]\w*(\s*\[[^\]]*\])?\s*,?$')
_CONST_TIEOFF = re.compile(
    r"^assign\s+[A-Za-z_]\w*(\s*\[[^\]]*\])?\s*=\s*"
    r"(\d[\d_]*'[sS]?[bodhBODH][0-9a-fA-FxXzZ_]+|\d+|1'h0|1'h1)\s*;$")
_PASSTHRU = re.compile(r'^assign\s+[A-Za-z_]\w*\s*=\s*[A-Za-z_]\w*\s*;$')
_INST_CONN_VAL = re.compile(r'^\(\s*[A-Za-z_]\w*(\s*\[[^\]]*\])?\s*\)\s*,?$')


def strip_comments(text):
    text = re.sub(r'/\*.*?\*/', '', text, flags=re.S)
    return re.sub(r'//[^\n]*', '', text)


def codelines(text, drop_ports=True):
    out = []
    for ln in strip_comments(text).splitlines():
        s = ln.rstrip()
        if not s.strip():
            continue
        if drop_ports and (_PORTLINE.match(s) or _STRUCTURAL.match(s.strip())):
            continue
        out.append(s.strip())
    return out


def classify_line(l):
    if _CONCAT_ELEM.match(l):
        return 'concat_elem'
    if _CONST_TIEOFF.match(l):
        return 'const_tieoff'
    if _PASSTHRU.match(l):
        return 'passthrough'
    if _INST_CONN_VAL.match(l):
        return 'inst_conn_val'
    return 'substantive'
# ---- 判据引用结束 ---------------------------------------------------------

# ---- 模块体：区分「真实现」与「黑盒 stub」---------------------------------
# ★第三处 fail-open★：上一轮有 16 个 `*stub*.sv`，里面把几十上百个 golden 模块名
# 各声明一次空体（输出全钉 0）。若把这些声明当成「本单元实现了该 golden 模块」，
# 二部图会把整个 backend 连成**一个 414 模块 / 216 文件 / 201,934 行的巨型分量**
# （实测），聚合结论全废。判别不靠文件名白名单（手工清单一定会漏），靠模块体：
#   真实现 = 体内有例化，或有「不是纯常量钉死」的代码行；
#   stub   = 体内只有 `assign io_x = <常量>;`。
_MOD_SPLIT = re.compile(r'^module\s+(\w+)', re.MULTILINE)
# 例化头：`  Foo bar (`。★必须排除 `module Foo(`★（首版没排，于是每个 stub 的
# module 声明行自己就被当成「有例化」，31 个 stub 全判成真实现，巨型分量没消掉）。
# ★第四处修补★：首版只认 `  Foo bar (`，漏掉带参数的 `  Foo #(.X(1)) bar (`
# 与断行的 `  Foo #(`。实测这一漏会把 xs_TageTable_core / xs_FauFTB_core /
# xs_iq_entry_acfd 等一大批**确实被例化**的核误报成「孤儿核」（grep 复核推翻）。
_INST_HDR = re.compile(
    r'^\s+(?!module\b|function\b|task\b|endmodule\b)[A-Za-z_]\w*\s*'
    r'(?:#\s*\((?:[^()]|\([^()]*\))*\)\s*\w*\s*\('
    r'|#\s*\(\s*$'
    r'|\s+\w+\s*\()\s*$')
# ★左括号必须存在★：第一版把它写成 `\(?`（可选），于是端口表最后一行
# `  output io_error_0`（无逗号）也被当成例化头 —— Rob_wrapper.sv 这个
# 3313 行的**空模块**因此被判成「有例化」，`vacuous=no`，整档判错。
# 负测见 --selftest。
_PORT_CONN = re.compile(r'^\s*\.\w+\s*\(')
# 钉死常量：**本脚本自用**，比抄来的 `_CONST_TIEOFF` 宽——要认 `'0` / `'1` 这种
# 无位宽字面量（stub 生成器用的就是 `assign io_x = '0;`）。抄来的那条一个字不动，
# 它只服务于 verbatim 列的口径一致性。
_TIEOFF_ANY = re.compile(
    r"^assign\s+[A-Za-z_]\w*(\s*\[[^\]]*\])?\s*=\s*"
    r"('[sS]?[bodhBODH01xXzZ][0-9a-fA-FxXzZ_]*|\d[\d_]*'[sS]?[bodhBODH][0-9a-fA-FxXzZ_]+|\d+)\s*;$")


def module_bodies(text):
    """返回 [(模块名, 体文本)]；体 = `module X` 到下一个 `endmodule`。"""
    code = strip_comments(text)
    lines = code.splitlines()
    starts = [(i, m.group(1)) for i, l in enumerate(lines)
              for m in [_MOD_SPLIT.match(l)] if m]
    out = []
    for i, name in starts:
        j = i
        while j < len(lines) and not lines[j].strip().startswith('endmodule'):
            j += 1
        out.append((name, '\n'.join(lines[i:j])))
    return out


def is_implementation(body):
    for ln in body.splitlines():
        if _INST_HDR.match(ln) or _PORT_CONN.match(ln):
            return True
    for l in codelines(body):
        if not _TIEOFF_ANY.match(l):
            return True
    return False


# 本脚本新增的宽口径：允许中间名带前缀（firtool 的 `_deqPtr_T_1` 形态）。
FIRTOOL_TEMP = re.compile(r'[A-Za-z0-9_]*_(?:GEN|T)(?:_\d+)?\b')
INCLUDE_RE = re.compile(r'^\s*`include\s+"([^"]+)"', re.MULTILINE)
# ★包文件是 import 进来的，不是 include 进来的★：上一轮 `NewDispatch.sv` 写
# `import newdispatch_pkg::*;`，而 `newdispatch_pkg.sv`（123 行）是独立文件。
# 只看 `\`include` 会把它漏掉 —— 实测 NewDispatch 少记 123 行、
# LoadQueueReplay 少记 214 行（2334 vs 真实 2548）。故 import 也当作一条依赖边。
IMPORT_RE = re.compile(r'^\s*import\s+(\w+)\s*::', re.MULTILINE)


def sha256_file(p):
    h = hashlib.sha256()
    with open(p, 'rb') as f:
        for chunk in iter(lambda: f.read(1 << 16), b''):
            h.update(chunk)
    return h.hexdigest()


# --------------------------------------------------------------------------
# 1. 逐文件度量
# --------------------------------------------------------------------------
def measure_files(impl_root):
    """每个 .sv/.svh 的原始度量。"""
    files = {}
    for p in sorted(pathlib.Path(impl_root).rglob('*')):
        if p.suffix not in ('.sv', '.svh') or not p.is_file():
            continue
        text = p.read_text(errors='replace')
        code = strip_comments(text)
        nl = len(text.splitlines())
        files[p] = {
            'path': p,
            'rel': str(p.relative_to(impl_root)),
            'ext': p.suffix,
            'lines': nl,
            'code_lines': len(codelines(text)),
            'gate_a_hits': len(FORBIDDEN.findall(code)),
            'firtool_hits': len(FIRTOOL_TEMP.findall(code)),
            'modules': [m.group(2) for m in MOD_RE.finditer(code)
                        if m.group(1) == 'module'],
            'impl_modules': [n for n, b in module_bodies(text) if is_implementation(b)],
            'packages': [m.group(2) for m in MOD_RE.finditer(code)
                         if m.group(1) == 'package'],
            'includes': (INCLUDE_RE.findall(text)
                         + ['%s.sv' % x for x in set(IMPORT_RE.findall(text))]),
            'unit_scope_import': bool(re.search(r'(?m)^import\s+\w+\s*::', text)),
            'text': text,
        }
    return files


# --------------------------------------------------------------------------
# 2. include 图 -> 实现单元
# --------------------------------------------------------------------------
def build_units(files):
    by_name = {}
    for p in files:
        by_name.setdefault(p.name, []).append(p)
    dupes = {n: v for n, v in by_name.items() if len(v) > 1}
    if dupes:
        raise SystemExit('basename 冲突，include 无法按裸名解析: %s' % sorted(dupes))

    included_by = collections.defaultdict(set)
    for p, d in files.items():
        for inc in d['includes']:
            tgt = by_name.get(os.path.basename(inc))
            if tgt:
                included_by[tgt[0]].add(p)

    def closure(root):
        seen, stack = set(), [root]
        while stack:
            cur = stack.pop()
            if cur in seen:
                continue
            seen.add(cur)
            for inc in files[cur]['includes']:
                t = by_name.get(os.path.basename(inc))
                if t:
                    stack.append(t[0])
        return seen

    roots = [p for p in files if not included_by[p]]
    units = {r: closure(r) for r in sorted(roots)}
    return units, included_by


# --------------------------------------------------------------------------
# 3. 实现单元 <-> golden 模块 二部图连通分量
# --------------------------------------------------------------------------
_XS_CORE = re.compile(r'^xs_(.+?)_core(_\w+)?$')
_SHELL_SUFFIX = re.compile(r'_(wrapper|core|pkg|inst|decls|body)$')


def golden_names(name, golden_dir):
    """一个 impl 侧的模块名/文件名对应哪个 golden 模块名。

    ★这是第二处 fail-open 的修补★：上一轮的可读核叫 `xs_CtrlBlock_core`，
    文件叫 `CtrlBlock.sv`，**没有任何模块叫 `CtrlBlock`**（golden 同名壳在
    `CtrlBlock_wrapper.sv` 里，或干脆没有）。只按「声明的模块名 ∈ golden」找，
    202 个 .svh 里有 184 个（192,173 行）映不到任何 golden —— 等于没查。
    故补两条回退：`xs_X_core` -> `X`；文件名去 `_wrapper/_core/_pkg/...` 后缀。
    """
    cands = [name]
    m = _XS_CORE.match(name)
    if m:
        cands.append(m.group(1))
    cands.append(_SHELL_SUFFIX.sub('', name))
    out = []
    for c in cands:
        if c and (golden_dir / ('%s.sv' % c)).exists() and c not in out:
            out.append(c)
    return out


def components(units, files, golden_dir):
    def gmods(unit_files, root):
        out = []
        for f in sorted(unit_files):
            for m in files[f]['impl_modules']:
                for g in golden_names(m, golden_dir):
                    if g not in out:
                        out.append(g)
        if not out:
            for g in golden_names(root.stem, golden_dir):
                if g not in out:
                    out.append(g)
        return out

    unit_mods = {r: gmods(fs, r) for r, fs in units.items()}
    mod_units = collections.defaultdict(set)
    for r, ms in unit_mods.items():
        for m in ms:
            mod_units[m].add(r)

    seen_r, comps = set(), []
    for r in sorted(units):
        if r in seen_r:
            continue
        cr, cm, stack = set(), set(), [('u', r)]
        while stack:
            kind, x = stack.pop()
            if kind == 'u':
                if x in cr:
                    continue
                cr.add(x)
                for m in unit_mods[x]:
                    stack.append(('m', m))
            else:
                if x in cm:
                    continue
                cm.add(x)
                for u in mod_units[x]:
                    stack.append(('u', u))
        seen_r |= cr
        comps.append((sorted(cr), sorted(cm)))
    return comps, unit_mods


# --------------------------------------------------------------------------
# 4. golden 逐字重合
# --------------------------------------------------------------------------
_GCACHE = {}

# golden（firtool 扁平输出）里例化恒为独占一行的 `  Foo bar (`，无 `#(` 参数化
# （XSTile.sv 实测 0 处 `#(`）。据此从某个根模块做实例图可达闭包。
_GOLD_INST = re.compile(r'^\s+([A-Za-z_]\w*)\s+([A-Za-z_]\w*)\s*\($', re.MULTILINE)


def golden_closure(golden_dir, root):
    golden_dir = pathlib.Path(golden_dir)
    seen, stack = set(), [root]
    while stack:
        m = stack.pop()
        if m in seen:
            continue
        seen.add(m)
        f = golden_dir / ('%s.sv' % m)
        if not f.exists():
            continue
        for mm in _GOLD_INST.finditer(strip_comments(f.read_text(errors='replace'))):
            stack.append(mm.group(1))
    return seen


def gold_lines(f):
    if f not in _GCACHE:
        _GCACHE[f] = set(codelines(pathlib.Path(f).read_text(errors='replace')))
    return _GCACHE[f]


# --------------------------------------------------------------------------
# 分档。★阈值全部有出处，没有一个是拍脑袋定的★（复算见 docs/prev_round_shell_audit.md）
#
# 对照组 = **本轮 rtl/ 全部 420 个文件 / 154,412 行 / 393 个 golden 模块**，
# 其中含用户点名的已签核干净件：DelayReg 家族 ×11、StdFreeList、
# UncacheEntry ×16、RASStack、WrBypass。对照组实测：
#   - `_GEN_/_T_` 命中（窄口径 gate_A 与宽口径 firtool）**恒为 0**，
#     420 个文件逐个都是 0，max=0.00 —— 所以「firtool 密度 > 0」本身就已越线，
#     不需要再造一个非零阈值。
#   - 实质逐字率 rate_subst 加权 545/31,302 = 1.74%；
#     按模块、限 code_lines>=30：p50=0.000 p90=0.048 p95=0.121 p99=0.290
#     **max=0.3009（UncacheEntry，658 可比行里 198 行与 golden 逐字相同）**。
#     ★这一条推翻了「逐字率高就是抄」的直觉★：写得干净、结构贴 golden 的件，
#     逐字率也能到 0.30。所以干净上界取 **0.31（对照组实测 max 0.3009 之上一点，
#     使对照组 393 个模块无一落到 T0 之外）**。
#   - 0.45 **不是本脚本发明的**：是 coordinator 给
#     `scripts/prev_round_verbatim_scan.py` 定的那条（manifest threshold=0.45），
#     原样沿用以便与那份台账对账。
#   - code_lines < 30 不判逐字率：对照组里 LevelGateway(2 行/0.40)、
#     SinkA(7 行/0.33) 这种小件，逐字相同是**写法唯一**造成的，不是抄。
#     这类另开一档如实说「样本太小，判不了」，比硬判一个方向诚实。
#   - firtool 密度 >= 10/100 行单列为「基本是 golden 原文」：上一轮 24 个
#     firtool 非零模块里，密度分布在 36.7 / 23.9 / 20.6 之后**直接掉到 4.8**，
#     这个空档就是分界；且这三个（VLMergeBufferImp / Predictor / MMIOBridgeEntry）
#     已逐段人工核过，确认是 golden 原文（见 md 的抽样节）。
# --------------------------------------------------------------------------
CLEAN_RATE_MAX = 0.31      # 对照组实测 max = 0.3009（UncacheEntry），取 0.31 使对照组全落 T0
VERBATIM_RATE = 0.45       # 沿用 prev_round_verbatim_scan.py 的既有阈值
JUDGE_MIN_CODELINES = 30   # 低于此不判逐字率
HEAVY_FIRTOOL_PER100 = 10.0

TIER_CLEAN = 'T0_CLEAN_REWRITE'
TIER_SUSPECT = 'T1_PARTIAL_SHELL'
TIER_VERBATIM = 'T2_MOSTLY_GOLDEN_TEXT'
TIER_VACUOUS = 'T3_VACUOUS_SHELL'
TIER_SMALL = 'T4_TOO_SMALL_TO_JUDGE'
TIER_CORE_ONLY = 'T5_CORE_ONLY_NO_WRAPPER'
TIER_NA = 'TX_NO_GOLDEN_TARGET'


def classify_tier(n_gold, vacuous, firtool, rate_subst, gate_a, lines, g0,
                  code_lines=10 ** 9, core_only=False):
    if not n_gold:
        return TIER_NA, '本单元不覆盖任何 golden 模块（辅助件/共享核）'
    if vacuous and len(vacuous) == n_gold:
        if core_only:
            return TIER_CORE_ONLY, ('只有 xs_*_core（核里有真逻辑），'
                                    '没有 golden 同名模块 —— 差一层壳，不是空壳')
        return TIER_VACUOUS, ('golden 同名模块是空体：无 assign / 无 always / '
                              '无例化，只有端口表')
    fpc = 100.0 * firtool / max(lines, 1)
    judged = code_lines >= JUDGE_MIN_CODELINES
    why = []
    if fpc >= HEAVY_FIRTOOL_PER100:
        why.append('firtool 中间名密度 %.1f/100 行（对照组恒为 0）' % fpc)
    if judged and rate_subst > VERBATIM_RATE:
        why.append('实质逐字率 %.2f > %.2f' % (rate_subst, VERBATIM_RATE))
    if why:
        return TIER_VERBATIM, '；'.join(why)
    why = []
    if firtool > 0:
        why.append('firtool 中间名 %d 处 / %.2f 每百行（对照组恒为 0）' % (firtool, fpc))
    if judged and rate_subst > CLEAN_RATE_MAX:
        why.append('实质逐字率 %.2f > 对照组实测上界 %.2f'
                   % (rate_subst, CLEAN_RATE_MAX))
    if vacuous:
        why.append('%d 个 golden 同名模块是空体' % len(vacuous))
    if why:
        return TIER_SUSPECT, '；'.join(why)
    if not judged:
        return TIER_SMALL, ('可比代码行仅 %d（<%d），逐字率 %.2f 不足以判定；'
                            'firtool 密度为 0'
                            % (code_lines, JUDGE_MIN_CODELINES, rate_subst))
    return TIER_CLEAN, ('firtool 中间名 0；实质逐字率 %.2f ≤ 对照组实测上界 %.2f'
                        % (rate_subst, CLEAN_RATE_MAX))


# --------------------------------------------------------------------------
# 自测：判据的**双向**负测（会认的要认、不会认的一个都不许认）。
# CONVENTIONS.md「闸的负测必须是双向的：会报警 **和** 不会误报，缺一不可」。
# `--selftest` 非零退出即判据坏了。这一节是被自己的 bug 逼出来的：
# `_INST_HDR` 的左括号一度写成可选，端口表末行 `  output io_error_0` 被当成
# 例化头，于是 Rob_wrapper.sv 这个 3313 行空模块判成「有例化」，整档判错。
# --------------------------------------------------------------------------
_SELFTEST_INST_YES = [
    '  Rob rob (',
    '  xs_TageTable_core #(.HIST_LEN(8)) u_core (',
    '  xs_FauFTB_core #(',
    '      xs_iq_entry_acfd #(.IS_ENQ(IS_ENQ_E), .IS_COMP(IS_COMP_E)) u_ety (',
]
_SELFTEST_INST_NO = [
    'module BypassNetwork(',
    '  input  clock,',
    '  output io_error_0',
    '  output [5:0]  io_perf_9_value,',
    "  assign io_x = '0;",
    '  endmodule',
    '  wire [15:0] foo;',
]
_SELFTEST_TIEOFF_YES = ["assign io_x = '0;", "assign io_y = 1'h0;",
                        'assign io_z = 0;', "assign io_w[3:0] = 4'hf;"]
_SELFTEST_TIEOFF_NO = ['assign io_x = io_y;', 'assign io_x = a & b;',
                       "assign io_x = {a, 1'h0};"]


def selftest():
    bad = []
    for s in _SELFTEST_INST_YES:
        if not _INST_HDR.match(s):
            bad.append('例化头漏认: %r' % s)
    for s in _SELFTEST_INST_NO:
        if _INST_HDR.match(s):
            bad.append('例化头误认: %r' % s)
    for s in _SELFTEST_TIEOFF_YES:
        if not _TIEOFF_ANY.match(s):
            bad.append('钉零漏认: %r' % s)
    for s in _SELFTEST_TIEOFF_NO:
        if _TIEOFF_ANY.match(s):
            bad.append('钉零误认: %r' % s)
    empty = 'module Rob(\n  input clock,\n  output io_error_0\n);\nendmodule'
    shell = ('module Rob(\n  input clock\n);\n  xs_Rob_core u (\n'
             '    .clock (clock)\n  );\nendmodule')
    if is_implementation(module_bodies(empty)[0][1]):
        bad.append('空端口表模块被判成真实现')
    if not is_implementation(module_bodies(shell)[0][1]):
        bad.append('例化了核的壳被判成 stub')
    # 分档：三个边界各一例（干净上界 / coordinator 阈值 / 小样本不判）
    if classify_tier(1, [], 0, 0.3009, 0, 1000, 1000, 100)[0] != TIER_CLEAN:
        bad.append('rate=0.3009（对照组实测 max）应判 T0')
    if classify_tier(1, [], 0, 0.32, 0, 1000, 1000, 100)[0] != TIER_SUSPECT:
        bad.append('rate=0.32 应判 T1')
    if classify_tier(1, [], 0, 0.46, 0, 1000, 1000, 100)[0] != TIER_VERBATIM:
        bad.append('rate=0.46 应判 T2')
    if classify_tier(1, [], 1, 0.0, 0, 1000, 1000, 100)[0] != TIER_SUSPECT:
        bad.append('firtool=1（对照组恒 0）应判 T1')
    if classify_tier(1, ['X'], 0, 0.0, 0, 1000, 1000, 100)[0] != TIER_VACUOUS:
        bad.append('空壳应判 T3')
    if classify_tier(1, ['X'], 0, 0.0, 0, 1000, 1000, 100,
                     core_only=True)[0] != TIER_CORE_ONLY:
        bad.append('只有核没有 golden 同名壳应判 T5，不是 T3')
    if classify_tier(1, [], 0, 0.9, 0, 100, 100, 5)[0] != TIER_SMALL:
        bad.append('可比行 5 应判 T4（样本太小不判）')
    for b in bad:
        print('SELFTEST FAIL: ' + b, file=sys.stderr)
    n = (len(_SELFTEST_INST_YES) + len(_SELFTEST_INST_NO)
         + len(_SELFTEST_TIEOFF_YES) + len(_SELFTEST_TIEOFF_NO) + 9)
    print('selftest: %d checks, %d failures' % (n, len(bad)))
    return 1 if bad else 0


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--selftest', action='store_true', help='只跑判据双向负测')
    ap.add_argument('--impl-root', required=False)
    ap.add_argument('--golden', required=False, help='对照 golden（上一轮=G0）')
    ap.add_argument('--golden-new', default='', help='本轮 golden（G1），用于算 G0/G1 差')
    ap.add_argument('--ledger', default='', help='docs/coverage_three_axis.tsv')
    ap.add_argument('--universe', default='', help='docs/g1_configured_universe.tsv（在册判定）')
    ap.add_argument('--incore-root', default='', help='核内闭包的根模块名（用户口径=XSTile），在 --golden-new 上算实例图可达')
    ap.add_argument('--out-files', required=False)
    ap.add_argument('--out-modules', required=False)
    ap.add_argument('--manifest', required=False)
    args = ap.parse_args()
    if args.selftest:
        return selftest()
    for req in ('impl_root', 'golden', 'out_files', 'out_modules', 'manifest'):
        if not getattr(args, req):
            print('缺参数 --%s' % req.replace('_', '-'), file=sys.stderr)
            return 2

    impl_root = pathlib.Path(args.impl_root).resolve()
    golden = pathlib.Path(args.golden).resolve()
    if not impl_root.is_dir() or not golden.is_dir():
        print('环境错误：impl-root 或 golden 不是目录', file=sys.stderr)
        return 2

    files = measure_files(impl_root)
    units, included_by = build_units(files)
    comps, unit_mods = components(units, files, golden)

    # 每个 golden 同名模块在本仓的声明形态：有没有一处是真实现（非 stub 文件里）。
    # Rob 就是靠这条抓出来的：`Rob_wrapper.sv` 3313 行里 3292 行是端口表，
    # 0 个 assign / 0 个 always / 0 个例化（核的例化被注释掉了）——
    # 「重写了 Rob」在文件层面成立，在电路层面是个**空模块**。
    decl_real = collections.defaultdict(bool)
    decl_named = collections.defaultdict(bool)   # 有没有一个**与 golden 同名**的模块
    decl_files = collections.defaultdict(list)
    for f, d in files.items():
        stubfile = 'stub' in f.name.lower() or 'blackbox' in f.name.lower()
        for n, b in module_bodies(d['text']):
            if (golden / ('%s.sv' % n)).exists():
                decl_files[n].append(d['rel'])
                decl_named[n] = True
                if is_implementation(b) and not stubfile:
                    decl_real[n] = True

    # 孤儿核：`xs_*` 核在整个 rtl/ 的去注释正文里，除自己的 module 声明行外
    # 再无任何一处提到 -> 它没有被任何东西例化，等于没接进电路。
    ref = collections.Counter()
    for f, d in files.items():
        code = strip_comments(d['text'])
        for ln in code.splitlines():
            s = ln.strip()
            if s.startswith('module ') or s.startswith('package '):
                continue
            for w in re.findall(r'\bxs_\w+\b', s):
                ref[w] += 1
    orphan_core = {n for f, d in files.items() for n in d['modules']
                   if n.startswith('xs_') and ref[n] == 0}

    # 每个文件属于几个分量（共享文件识别）
    file_comp_count = collections.Counter()
    for cr, cm in comps:
        fs = set()
        for r in cr:
            fs |= units[r]
        for f in fs:
            file_comp_count[f] += 1

    # 每个文件该跟哪些 golden 文件比：自己声明的 golden 模块，**外加**把它
    # include 进来的那些分量所覆盖的 golden 模块。
    # ★这一步是修一处 fail-open★：`.svh` 自己不声明任何 module，若只按
    # 「本文件声明的模块」找 golden，202 个 `.svh` 会全部比出 0 条重合 ——
    # 而 `.svh` 正是本次要查的地方。首版就是这么错的（svh subst 全 0），
    # 靠分量级口径对不上才发现。
    file_gmods = collections.defaultdict(set)
    for cr, cm in comps:
        fs = set()
        for r in cr:
            fs |= units[r]
        for f in fs:
            file_gmods[f] |= set(cm)
    for f, d in files.items():
        for m in d['impl_modules']:
            file_gmods[f] |= set(golden_names(m, golden))

    # ---- 文件级 TSV ----
    fcols = ['rel', 'ext', 'lines', 'code_lines', 'gate_a_hits', 'firtool_hits',
             'gate_a_per100', 'firtool_per100', 'included_by_n', 'is_root',
             'modules_declared', 'golden_modules', 'verbatim_code', 'verbatim_subst',
             'rate_subst', 'in_n_components', 'stub_modules_n', 'unit_scope_import']
    frows = []
    for p in sorted(files, key=lambda x: str(x)):
        d = files[p]
        impl = codelines(d['text'])
        gmods = sorted(file_gmods[p])
        stub_mods = [m for m in d['modules'] if m not in d['impl_modules']]
        gset = set()
        for m in gmods:
            gset |= gold_lines(golden / ('%s.sv' % m))
        hits = [l for l in impl if l in gset] if gset else []
        subst = sum(1 for l in hits if classify_line(l) == 'substantive')
        frows.append({
            'rel': d['rel'], 'ext': d['ext'], 'lines': d['lines'],
            'code_lines': d['code_lines'], 'gate_a_hits': d['gate_a_hits'],
            'firtool_hits': d['firtool_hits'],
            'gate_a_per100': '%.2f' % (100.0 * d['gate_a_hits'] / max(d['lines'], 1)),
            'firtool_per100': '%.2f' % (100.0 * d['firtool_hits'] / max(d['lines'], 1)),
            'included_by_n': len(included_by[p]),
            'is_root': 'yes' if p in units else 'no',
            'modules_declared': ';'.join(d['modules'][:8]) or '-',
            'golden_modules': ';'.join(gmods[:8]) or '-',
            'verbatim_code': len(hits),
            'verbatim_subst': subst,
            'rate_subst': '%.4f' % (subst / len(impl)) if impl else '',
            'in_n_components': file_comp_count[p],
            'stub_modules_n': len(stub_mods),
            'unit_scope_import': 'yes' if d['unit_scope_import'] else 'no',
        })

    # ---- 台账 / universe ----
    ledger = {}
    if args.ledger and os.path.exists(args.ledger):
        for ln in open(args.ledger):
            if ln.startswith('#'):
                continue
            c = ln.rstrip('\n').split('\t')
            if len(c) >= 3:
                ledger[c[0]] = (c[1], c[2])
    universe = set()
    if args.universe and os.path.exists(args.universe):
        # 表头本身是 `# module\tin_universe\tsource`（注释行），故按列位解析。
        for ln in open(args.universe):
            if ln.startswith('#'):
                continue
            c = ln.rstrip('\n').split('\t')
            if len(c) >= 2 and c[1] == 'yes':
                universe.add(c[0])

    gnew = pathlib.Path(args.golden_new).resolve() if args.golden_new else None
    incore = golden_closure(gnew or golden, args.incore_root) if args.incore_root else set()

    def gline(d, m):
        f = d / ('%s.sv' % m)
        if not f.exists():
            return -1
        return len(f.read_text(errors='replace').splitlines())

    # ---- golden 模块级 TSV ----
    # ★为什么不按「二部图连通分量」出表★：分量会通过共享文件把不相干的东西并起来
    # （实测 AtomicsUnit 分量吞进 63 个 golden 模块 / 89 个文件 / 102,792 行，
    # CSRPermitModule 分量吞进 211 个），聚合出的密度和逐字率对任何一个模块都不成立。
    # 决策要的是「模块 X 能不能移植」，所以一行 = 一个 golden 模块，
    # 它的实现件 = 声明了 X（或 xs_X_core）的那些**实现单元**（根 .sv + 其 include 闭包），
    # **不做跨模块传递合并**。一个单元同时实现多个 golden 模块时（newcsr 批量文件），
    # 该单元的行数会在每个模块行里各记一次，`unit_covers_n_modules` 把这件事标出来。
    mod_units_map = collections.defaultdict(set)
    for r, ms in unit_mods.items():
        for m in ms:
            mod_units_map[m].add(r)

    mcols = ['golden_module', 'tier', 'tier_why', 'scope', 'impl_files', 'n_files', 'n_svh',
             'impl_lines', 'svh_lines', 'svh_line_frac', 'code_lines',
             'gate_a_hits', 'gate_a_per100', 'firtool_hits', 'firtool_per100',
             'verbatim_code', 'verbatim_subst', 'rate_subst',
             'g0_lines', 'g1_lines', 'g0_eq_g1', 'compress_ratio',
             'vacuous', 'golden_also_vacuous', 'orphan_cores', 'unit_covers_n_modules',
             'unit_scope_import',
             'ledger_rewrite', 'ledger_formal', 'in_universe', 'in_core']
    mrows = []
    for m in sorted(mod_units_map):
        us = sorted(mod_units_map[m])
        fs = sorted(set().union(*[units[u] for u in us]))
        ncov = max(len(unit_mods[u]) for u in us)
        # ★口径★：一个文件里塞了 N 个 golden 模块时（NewPipelineConnectPipe.sv
        # 一个文件 20 个变体、TLBuffer 家族 30 个），若按「整个单元」记行数，
        # 每个变体都记一遍整文件 = 20,028 行，对 g0 的 200 行算出压缩比 100 倍，
        # 纯属胡说。故 N>1 时**只量该模块自己的 module 体**（含 xs_X_core 体），
        # scope 列标明用的是哪一种。
        scope = 'unit' if ncov == 1 else 'own_body'
        if scope == 'unit':
            texts = [files[f]['text'] for f in fs]
        else:
            texts = []
            for f in fs:
                for n, b in module_bodies(files[f]['text']):
                    if m in golden_names(n, golden):
                        texts.append(b)
        blob = '\n'.join(texts)
        lines = sum(len(x.splitlines()) for x in texts)
        svh = [f for f in fs if files[f]['ext'] == '.svh'] if scope == 'unit' else []
        svhl = sum(files[f]['lines'] for f in svh)
        cl = len(codelines(blob))
        ga = len(FORBIDDEN.findall(strip_comments(blob)))
        ft = len(FIRTOOL_TEMP.findall(strip_comments(blob)))
        gset = gold_lines(golden / ('%s.sv' % m))
        impl = codelines(blob)
        hits = [l for l in impl if l in gset]
        subst = sum(1 for l in hits if classify_line(l) == 'substantive')
        g0 = max(gline(golden, m), 0)
        g1 = max(gline(gnew, m), 0) if gnew else -1
        eq = ''
        if gnew:
            a, b = golden / ('%s.sv' % m), gnew / ('%s.sv' % m)
            eq = 'yes' if (a.exists() and b.exists()
                           and sha256_file(a) == sha256_file(b)) else 'no'
        # 三种「没有可用的 golden 同名模块」要分开，否则会把两件性质完全不同的事
        # 混成一档：
        #   (a) 有同名模块但**体是空的**（Rob：3313 行里 3292 行端口表，
        #       核的例化被注释掉了）—— 这是真空壳；
        #   (b) **根本没有同名模块**，只有 `xs_X_core`（Queue1_UInt32 / OffsetScoreTable
        #       / RecentRequestTable / DelayQueue 等 l2 叶子）—— 核里逻辑是真的，
        #       缺的是那层 golden 同名壳，性质是「差一层壳」不是「空壳」。
        #       首版把 (b) 也判成空壳，人工看 Queue1_UInt32 时当场推翻。
        vac = [] if decl_real[m] else [m]
        core_only = (not decl_named[m]) and not decl_real[m]
        # ★T3 的关键区分★：golden 自己也可能是空体（配置下被 firtool DCE 掉的死码）。
        # 本轮 StorePipe 就是这样（golden 93 行、体内无逻辑），此时重写件是空壳是
        # **对的**，不是漏做。对照组里这一条被当成真阳性验证了分类器。
        gvac = False
        if (golden / ('%s.sv' % m)).exists():
            gb = module_bodies((golden / ('%s.sv' % m)).read_text(errors='replace'))
            gvac = not any(is_implementation(b) for _, b in gb)
        orph = sorted({n for f in fs for n in files[f]['modules']
                       if n in orphan_core})
        rsub = (subst / len(impl)) if impl else 0.0
        tier, why = classify_tier(1, vac, ft, rsub, ga, lines, g0, cl,
                                  core_only=core_only)
        if tier == TIER_VACUOUS and gvac:
            why += '；★但 golden 同名模块自己也是空体（配置下被 DCE 的死码），空壳是对的★'
        mrows.append({
            'golden_module': m, 'tier': tier, 'tier_why': why, 'scope': scope,
            'impl_files': ';'.join(files[f]['rel'] for f in fs[:14]),
            'n_files': len(fs), 'n_svh': len(svh),
            'impl_lines': lines, 'svh_lines': svhl,
            'svh_line_frac': '%.3f' % (svhl / lines) if lines else '',
            'code_lines': cl, 'gate_a_hits': ga,
            'gate_a_per100': '%.2f' % (100.0 * ga / max(lines, 1)),
            'firtool_hits': ft,
            'firtool_per100': '%.2f' % (100.0 * ft / max(lines, 1)),
            'verbatim_code': len(hits), 'verbatim_subst': subst,
            'rate_subst': '%.4f' % rsub,
            'g0_lines': g0, 'g1_lines': g1, 'g0_eq_g1': eq,
            'compress_ratio': '%.3f' % (lines / g0) if g0 else '',
            'vacuous': 'yes' if vac else 'no',
            'golden_also_vacuous': 'yes' if gvac else 'no',
            'orphan_cores': ';'.join(orph) or '-',
            'unit_covers_n_modules': ncov,
            'unit_scope_import': ('yes' if any(files[f]['unit_scope_import']
                                               for f in fs) else 'no'),
            'ledger_rewrite': ledger.get(m, ('NOT_IN_LEDGER', '-'))[0],
            'ledger_formal': ledger.get(m, ('-', 'NOT_IN_LEDGER'))[1],
            'in_universe': ('yes' if m in universe else 'no') if universe else '',
            'in_core': ('yes' if m in incore else 'no') if incore else '',
        })
    mrows.sort(key=lambda r: (-r['impl_lines'], r['golden_module']))

    def write_tsv(path, cols, rows):
        if path == '/dev/null':
            return
        pathlib.Path(path).parent.mkdir(parents=True, exist_ok=True)
        with open(path, 'w') as f:
            f.write('\t'.join(cols) + '\n')
            for r in rows:
                f.write('\t'.join(str(r[c]) for c in cols) + '\n')

    write_tsv(args.out_files, fcols, frows)
    write_tsv(args.out_modules, mcols, mrows)

    man = {
        'impl_root': str(impl_root),
        'golden': str(golden),
        'golden_new': str(gnew) if gnew else '',
        'n_files_scanned': len(files),
        'n_sv': sum(1 for d in files.values() if d['ext'] == '.sv'),
        'n_svh': sum(1 for d in files.values() if d['ext'] == '.svh'),
        'total_lines': sum(d['lines'] for d in files.values()),
        'n_units': len(units),
        'n_components': len(comps),
        'incore_root': args.incore_root,
        'n_incore_modules': len(incore),
        'criteria_from': 'scripts/prev_round_verbatim_scan.py (itself from readability_audit.py G)',
        'script_sha256': sha256_file(__file__),
        'rerun': ' '.join(['python3', 'scripts/prev_round_shell_audit.py'] + sys.argv[1:]),
    }
    for k, p in (('out_files_sha256', args.out_files),
                 ('out_modules_sha256', args.out_modules)):
        man[k] = sha256_file(p) if p != '/dev/null' and os.path.exists(p) else ''
    if args.manifest != '/dev/null':
        pathlib.Path(args.manifest).parent.mkdir(parents=True, exist_ok=True)
        with open(args.manifest, 'w') as f:
            json.dump(man, f, indent=2, ensure_ascii=False)
            f.write('\n')
    print(json.dumps(man, indent=2, ensure_ascii=False))
    return 0


if __name__ == '__main__':
    sys.exit(main())
