#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""ordered_classifier.py —— G0→G1 迁移的**有序**分类器（codex 0144 Lane F 契约）。

## 这个脚本是什么

它只回答一个问题：**这个 target 该按哪种施工方案排期。**
它 **不生成任何 RTL**、**不跑任何 EDA 工具**、**不写 golden**、**不发 PASS**。
（`--selftest-nortl` 会机械证明这一点：源码里不存在写 `.sv` 的语句。）

## 顺序本身是契约

codex 0144 给的九档，**顺序即契约**：九条判据全部独立求值（这样才能报「重叠」），
但**归档一律按序号先命中先归**，后面的档不再改判。

    rank 1  X_RETIRED         G0 这个名字在 G1 里没有了 —— 纯台账动作，不产 RTL，不计完成
    rank 2  G_NEWFORM         G1 独有（G0 无同名、且反向也定位不到 G0 前身）
    rank 2  P_SHIM            G1 模块体只有 io->io 直通 —— 从 G1 端口表直接生成
    rank 3  A_BODY_IDENTICAL  安全归一化后模块体逐字相同，且 width_chg==0 && dir_chg==0
    rank 4  A2_IFACE_ONLY     只有接口/派生接口连线变化（逐行归因，不是粗字段名过滤）
    rank 5  F_PORTWIDTH       方向不变、位宽变了 —— 可读参数化适配 + 家族回归
    rank 6  D_DEPRENUM        **只按实例名**建立子模块 G0→G1 对应，代入后模块体相同
    rank 7  C_ALPHA_RENAME    声明顺序下临时线 alpha 等价 —— 只能继承施工，**不能继承 PASS**
    rank 8  B_HANDSHAKE       G1 新增 ready/反压（必须排在 A/A2/F/D 之后）
    rank 9  E_LOGIC / F_MORPH 其余真逻辑 / 形态变化，逐目标实现与 FM

## 九条判据（全部机器可复算；每条的取值都进 TSV，不只给结论）

### rank 1 · X_RETIRED
`g1_has_same_name == False`。这是**纯粹的记账条件**：G1 里没有这个名字，
所以这个名字下没有 RTL 可交付。同时用「例化点身份」（见下）定位后继：
后继存在时，本脚本额外吐一行 `row_kind=DERIVED_SUCCESSOR` 的**新 target**，
把施工量原样搬到后继名下 —— 不让排期在改名处丢掉。

### rank 2 · G_NEWFORM / P_SHIM
- `G_NEWFORM`：`g0_has_same_name == False` 且 `resolve(G1->G0, target)` 也定位不到前身。
- `P_SHIM`：G1 模块体去掉纯 `assign io_a = io_b;` 之后为空，且无子例化、无 always。

### rank 3 · A_BODY_IDENTICAL
`body_identical_safe == True` **且** `width_chg == 0 && dir_chg == 0`。

「安全归一化」严格限定为四件事，一件都不多：
  (1) 剥 firtool 的 `` `ifdef ENABLE_INITIAL_{REG,MEM}_ `` 随机化初始化块；
  (2) `.scala:<行号>` 归零；
  (3) 自名 -> `@SELF@`；
  (4) 去行尾空白、丢空行。

**注意本脚本对 A 的读法是保守的**：「去掉纯直通 assign」**不**算安全归一化。
理由：纯直通恰恰是「接口增量」的产物，把它剥掉就等于把 A2 混进 A。
两种读法的取值都进 TSV（`body_identical_safe` / `body_identical_safe_pt`），
谁想按宽读法复算都可以，但**归档按严读法**。

width/dir 硬闸是 codex 点名的：`TLBuffer_6/_8/_9/_20/_22` 的模块体在归一化后
逐字相同，只有 `source` 位宽变了（实测 `_6` 3->4、`_8`/`_9` 2->4、`_20`/`_22` 3->5
—— 台账写的「五个都是 3->5」是错的）。没有这道闸它们会全部落 A，
产出的核位宽写回旧值，UT 照过，一路漏到 FM。

### rank 4 · A2_IFACE_ONLY —— 逐行归因，**不是**粗字段名过滤
先算两侧模块体的**标识符集合**：
    NEW = ids(G1_body) - ids(G0_body)      # 只在 G1 出现的名字
    OLD = ids(G0_body) - ids(G1_body)
再对逻辑行做 diff，得到 ADD（只在 G1）/ DEL（只在 G0）。判据：

  * ADD 行若**定义**了名字，则它定义的**每一个**名字都必须 ∈ NEW ∪ 新增端口；
  * ADD 行若不定义名字（例化连线 `.p (x),` 之类），则它引用的**每一个**标识符
    都必须 ∈ NEW（不引用任何标识符的纯结构行 —— 多出来的 `begin`/`end` ——
    一律判**不可归因**）；
  * DEL 行对称，用 OLD ∪ 删除端口；
  * 另加 `width_chg == 0 && dir_chg == 0`，且 `ports_added + ports_removed > 0`。

**为什么这样就挡住了「粗字段名过滤冒充」**：老判据 `portattr_equal` 是
「diff 行里**提到**了新增/删除端口名就从两侧一起滤掉」。于是
`assign io_out_bits_x = _T_5[7:0];` -> `assign io_out_bits_x = _T_5[15:0];`
这种**改写**，只要 `io_out_bits_x` 撞上了粗字段名，两行一起被滤，真改动凭空消失。
本判据看的是**被定义的名字在不在对侧存在**：`io_out_bits_x` 在两侧都存在，
所以那条 DEL 行不可归因，A2 直接不成立。改写永远躲不过去，因为改写的
LHS 按定义在两侧都在。（`test_ordered_classifier.py::test_neg_a2_coarse_field_spoof`
用一个人造夹具把这两种判据摆在一起跑，证明粗过滤说「相等」而本判据说「不是 A2」。）

### rank 5 · F_PORTWIDTH
`dir_chg == 0 && width_chg > 0`（codex 字面定义）。
附加**分级列**（不改归档，只给施工看）：
  `PURE_REPARAM`       —— 把两侧所有位宽记号归一后模块体相同 => 纯重参数化；
  `REPARAM_PLUS_LOGIC` —— 归一后仍有残余 diff => 除了位宽还动了逻辑，别当纯参数化做。

### rank 6 · D_DEPRENUM —— 只按实例名，**禁止 family 叉积**
子模块对应表 = `{G0子模块类型 -> G1子模块类型}`，键是**实例名**：
两侧例化点集合必须一致（`{实例名}` 相等），同一实例名上两侧放的类型配成一对。
本脚本**从不**枚举「同家族的所有编号」去配对 —— 家族叉积会造出错配候选，
代入后 diff 不归零，把一个本来干净的目标藏成「须重写」。
代入必须是**同时替换**（`simul_sub`）：逐条 `re.sub` 会链式吃掉前一条的结果
（RNXbar 一个模块里 15 处重编号，链式替换后残余 8 行假 diff）。

每一对 `C0 -> C1` 还要过一道**例化点身份**校验（复用
`check_name_collisions.resolve`，判据强度 site > site_common > site_parentnorm >
body_exact > body_childnorm）：若全局身份判据给出的对应物**不是** `C1`，
记为 contradiction，**该 target 不落 D**。判不准（留白）不算矛盾，只记 flag。

### rank 7 · C_ALPHA_RENAME —— 只能继承施工，不能继承 PASS
把所有下划线开头的 firtool 临时名按**首次出现顺序**重编成 `_@1.._@N` 再比较。
相等 => 逻辑一样、只有临时名和换行变了。
TSV 里 `inherit_construction = yes` 而 `inherit_pass = NO` —— 这是 codex 明写的。

### rank 8 · B_HANDSHAKE —— 必须排在 A/A2/F/D 之后
`ready_added > 0`。分级：
  `NEW_HANDSHAKE`      G0 端口表 0 个 ready（真·新增握手）；
  `EXTENDED_HANDSHAKE` G0 已有 ready，本次是在既有握手上再加（配方不一定照搬）。
再用 rank 4 的同一套归因引擎判是不是**纯** B：
  归因全通过 => `B`；有不可归因的行 => `B+E`（还动了真逻辑，不得按纯 B 批改）。
`BranchUnit` / `JumpUnit` 实测就是 `B+E`。
`BypassNetwork` 落不到这里：它 G0 端口表本来就有 30 个 ready，而且它在 rank 4
就被 A2 收走了 —— **含 ready 不等于 B**。

### rank 9 · E_LOGIC / F_MORPH
形态变了（端口数/位宽/例化集合任一变化）=> `F_MORPH`，否则 `E_LOGIC`。
规模分级 `S <=40 / M 41..600 / L >600`，用的是 **`resid_diff_tb`**：
抹掉 firtool 临时线编号（`_GEN_<n>` / `<x>_T_<n>`）之后的残余行数。
不这么做的话 `Ftq` 的 raw 残余是 32000 行（看着像从头重写），
抹编号后只剩 121 加 / 284 删 —— 32000 行里 99% 是 firtool 重新发号。
`resid_diff` / `resid_diff_tb` 两个数都进 TSV。
`determinacy = INDETERMINATE` 表示上面每条便宜判据都不成立且 `resid_diff_tb` > 600 行 ——
**这不是一个施工方案，是「机械上判不准」**，必须单列，不许硬塞进某一档。

## strip_randomize 的使用范围（codex 明令）

`strip_randomize()` **只允许用于本脚本的迁移分类分析**。
Formal 的 golden/ref 输入**不得**删除或重写这些字节。本脚本永不写 RTL，
`--selftest-nortl` 会扫源码证明这一点。

## 用法

    # 全量跑台账 199 个 target（+ 自动派生的后继 target），出可复算 TSV
    scripts/ordered_classifier.py --ledger <migration_plan.tsv> \
        --tsv docs/ordered_classification.tsv --manifest docs/ordered_classification.manifest.json

    # 只看几个
    scripts/ordered_classifier.py --target TLBuffer_20 --target BypassNetwork --explain

    # 与旧台账对账
    scripts/ordered_classifier.py --ledger <...> --diff-ledger

退出码：0 = 跑完；2 = 环境/用法错误（fail-closed）；3 = 有 target 判不出档（内部错误）。
"""
import argparse
import collections
import difflib
import hashlib
import json
import os
import pathlib
import re
import sys
import tempfile
import time

_HERE = pathlib.Path(__file__).resolve().parent
sys.path.insert(0, str(_HERE))
import check_name_collisions as CNC          # noqa: E402  例化点身份判据，复用不重造

G0_DEFAULT = os.environ.get('G0_GOLDEN_RTL', '/home/eda/xs-env/G0-canonical/golden-rtl')
G1_DEFAULT = os.environ.get('GOLDEN_RTL', '/home/eda/xs-env/G1-canonical/golden-rtl')

# 归档顺序 —— **这就是契约**。改这张表就是改契约，回归测试会拦。
ORDER = [
    (1, 'X_RETIRED'),
    (2, 'G_NEWFORM'),
    (2, 'P_SHIM'),
    (3, 'A_BODY_IDENTICAL'),
    (4, 'A2_IFACE_ONLY'),
    (5, 'F_PORTWIDTH'),
    (6, 'D_DEPRENUM'),
    (7, 'C_ALPHA_RENAME'),
    (8, 'B_HANDSHAKE'),
    (9, 'E_F_RESIDUAL'),
]
BUCKETS = [b for _, b in ORDER]


class ClassifyError(Exception):
    """fail-closed：看不懂就抛，绝不静默归到某一档。"""


# ===========================================================================
# 0. 文本原语
# ===========================================================================

_RAND_BLOCK = re.compile(
    r'^[ \t]*`ifdef ENABLE_INITIAL_(?:REG|MEM)_\b.*?'
    r'^[ \t]*`endif // ENABLE_INITIAL_(?:REG|MEM)_[ \t]*$\n?',
    re.S | re.M)
_SCALA_LN = re.compile(r'\.scala:\d+')
_PURE_PASSTHROUGH = re.compile(
    r'^[ \t]*assign[ \t]+(io_\w+|auto_\w+)[ \t]*=[ \t]*\n?[ \t]*(io_\w+|auto_\w+);[ \t]*$',
    re.M)


def strip_randomize(text):
    """剥 firtool 仿真专用随机化初始化块。

    ★使用范围（codex 0144 明令）★：**只允许用于迁移分类分析**。
    Formal 的 golden / ref 输入不得删除或重写这些字节 —— 本脚本不写 RTL，
    `--selftest-nortl` 机械证明之。
    """
    return _RAND_BLOCK.sub('', text)


def strip_pure_passthrough(text):
    """去掉整条 `assign io_a = io_b;`（带运算/切片/三元的一律保留）。
    **不属于 A 档的安全归一化**，只在 A2/P_SHIM 的取值里用。"""
    return _PURE_PASSTHROUGH.sub('', text)


def norm_safe(body, selfname):
    """A 档允许的**唯一**归一化：随机化块 / scala 行号 / 自名 / 空白。"""
    s = strip_randomize(body)
    s = _SCALA_LN.sub('.scala:0', s)
    s = re.sub(r'\b%s\b' % re.escape(selfname), '@SELF@', s)
    out = [ln.rstrip() for ln in s.splitlines()]
    return '\n'.join(ln for ln in out if ln.strip())


def norm_safe_pt(body, selfname):
    """安全归一化 + 去纯直通（宽读法，仅作为 TSV 取值提供，不用于归档）。"""
    return norm_safe(strip_pure_passthrough(body), selfname)


# ---- 逻辑行切分 -----------------------------------------------------------

_INST_OPEN = re.compile(r'^\s*[A-Za-z_]\w*\s+[A-Za-z_]\w*\s*\($')
_FLUSH_BARE = {'end', 'endcase', 'endfunction', 'endtask', 'end else begin',
               '`endif', '`else', 'else begin', '`ifdef', '`ifndef'}


def logical_lines(body):
    """把模块体切成「逻辑行」。firtool 会把长表达式折行，不接起来 diff 全是噪声。

    flush 条件（两侧用同一套词法，所以即使某处切得不完美，diff 仍是可比的）：
      * 括号深度回 0 且行尾是 `;` 或 `,`；
      * 行尾是 `begin`；
      * 整行是 `end` 类关键字或预处理指令；
      * `Mod inst (` 这种例化开头单独成行；
      * `case (...)` 单独成行。
    """
    out, buf, depth = [], '', 0
    for raw in body.splitlines():
        s = raw.rstrip()
        if not s.strip():
            continue
        buf = s if not buf else buf + ' ' + s.strip()
        depth += s.count('(') - s.count(')')
        st = buf.strip()
        flush = False
        if depth <= 0 and (st.endswith(';') or st.endswith(',')):
            flush = True
        elif st.endswith('begin'):
            flush = True
        elif st in _FLUSH_BARE or st.startswith('`'):
            flush = True
        elif depth == 1 and _INST_OPEN.match(st):
            flush = True
        elif depth <= 0 and re.match(r'^(unique\s+)?case[zx]?\s*\(.*\)$', st):
            flush = True
        if flush:
            out.append(re.sub(r'\s+', ' ', st))
            buf, depth = '', 0
    if buf.strip():
        out.append(re.sub(r'\s+', ' ', buf.strip()))
    return out


# ---- 标识符 / def-use -----------------------------------------------------

_SV_KW = set("""
module endmodule input output inout wire reg logic integer genvar parameter localparam
assign always always_ff always_comb always_latch initial begin end if else case casez casex
endcase default for while repeat forever posedge negedge edge or and not xor nand nor xnor
signed unsigned automatic static function endfunction task endtask return generate endgenerate
disable fork join wait typedef struct union enum packed bit byte shortint int longint time
real string void ref const class endclass package endpackage import export virtual
unique unique0 priority inside dist iff this super null tri triand trior supply0 supply1
""".split())

_LIT = re.compile(r"\b\d[\d_]*'[sS]?[bodhBODH][0-9a-fA-FxXzZ?_]+")
_NUM = re.compile(r'\b\d[\d_]*\b')
_IDENT = re.compile(r'\b[A-Za-z_]\w*\b')


def idents(line):
    s = _LIT.sub(' ', line)
    s = _NUM.sub(' ', s)
    return set(w for w in _IDENT.findall(s) if w not in _SV_KW)


_DEF_ASSIGN = re.compile(r'^\s*assign\s+([A-Za-z_]\w*)')
_DEF_NBA = re.compile(r'^\s*([A-Za-z_]\w*)\s*(?:\[[^\]]*\])*\s*<=')
_DEF_BA = re.compile(r'^\s*([A-Za-z_]\w*)\s*(?:\[[^\]]*\])*\s*=(?!=)')
_DEF_DECL = re.compile(
    r'^\s*(?:wire|reg|logic|integer|genvar|automatic|localparam|parameter)\b'
    r'(?:\s+(?:signed|unsigned))?'
    r'(?:\s*\[[^\]]*\])*\s*'
    r'([A-Za-z_]\w*)')


def defs(line):
    """这条逻辑行**定义**了哪些名字。取不到就返回空集（此时走「引用全新」那条）。"""
    for rx in (_DEF_ASSIGN, _DEF_DECL, _DEF_NBA, _DEF_BA):
        m = rx.match(line)
        if m:
            return {m.group(1)}
    return set()


# ===========================================================================
# 1. 端口表
# ===========================================================================

_PORT = re.compile(
    r'^\s*(input|output|inout)\s+'
    r'(?:(?:wire|reg|logic)\s+)?'
    r'(?:(signed)\s+)?'
    r'(?:\[\s*(\d+)\s*:\s*(\d+)\s*\]\s*)?'
    r'([A-Za-z_]\w*)\s*'
    r'(?:,\s*)?$')

Port = collections.namedtuple('Port', 'dirn signed msb lsb name')


def module_span(text, name):
    try:
        i = text.index('module %s(' % name)
    except ValueError:
        raise ClassifyError('找不到 module %s(' % name)
    j = text.index('\n);', i) + 3
    k = text.index('\nendmodule', j)
    return text[i:j], text[j:k]


def parse_ports(porttable, where):
    out = []
    for ln in porttable.splitlines():
        s = ln.strip()
        if not s or s.startswith('//') or s.startswith('module ') or s == ');':
            continue
        m = _PORT.match(ln)
        if not m:
            raise ClassifyError('%s: 看不懂的端口声明 %r' % (where, ln))
        d, sg, msb, lsb, nm = m.groups()
        out.append(Port(d, bool(sg),
                        int(msb) if msb is not None else 0,
                        int(lsb) if lsb is not None else 0, nm))
    return out


def port_delta(p0, p1):
    d0 = {p.name: p for p in p0}
    d1 = {p.name: p for p in p1}
    both = sorted(set(d0) & set(d1))
    return {
        'added': sorted(set(d1) - set(d0)),
        'removed': sorted(set(d0) - set(d1)),
        'width_chg': [(n, '[%d:%d]' % (d0[n].msb, d0[n].lsb),
                       '[%d:%d]' % (d1[n].msb, d1[n].lsb))
                      for n in both
                      if (d0[n].msb, d0[n].lsb) != (d1[n].msb, d1[n].lsb)
                      or d0[n].signed != d1[n].signed],
        'dir_chg': [(n, d0[n].dirn, d1[n].dirn) for n in both
                    if d0[n].dirn != d1[n].dirn],
    }


def is_ready(name):
    return name == 'ready' or name.endswith('_ready')


# ===========================================================================
# 2. 子模块例化 / 改名（P3：只按实例名，禁止 family 叉积）
# ===========================================================================

_INSTLINE = re.compile(r'^[ \t]{2,}([A-Za-z_]\w*)\s+([A-Za-z_]\w*)\s*\(\s*$', re.M)


def instances(body):
    """模块体 -> {实例名: 子模块类型}。firtool 例化一律 `  Type inst (` 独占一行。"""
    return {m.group(2): m.group(1) for m in _INSTLINE.finditer(body)}


def child_rename_by_instname(b0, b1):
    """**只按实例名**求子模块改名表。返回 (map, problems)。

    绝不做 family 叉积：候选完全由「同一个实例名两侧各放了谁」决定。
    """
    i0, i1 = instances(b0), instances(b1)
    problems = []
    only0 = sorted(set(i0) - set(i1))
    only1 = sorted(set(i1) - set(i0))
    if only0:
        problems.append('instances only in G0: %s' % (only0[:8],))
    if only1:
        problems.append('instances only in G1: %s' % (only1[:8],))
    mapping = {}
    for inst in sorted(set(i0) & set(i1)):
        a, b = i0[inst], i1[inst]
        if a == b:
            continue
        if a in mapping and mapping[a] != b:
            problems.append('module %s maps to both %s and %s (not a renumber)'
                            % (a, mapping[a], b))
        mapping[a] = b
    return mapping, problems


def simul_sub(text, mapping):
    """**同时**整词替换。逐条 re.sub 会链式吃掉前一条结果（RNXbar 残余 8 行假 diff）。"""
    if not mapping:
        return text
    pat = re.compile(r'\b(' + '|'.join(re.escape(k) for k in
                                       sorted(mapping, key=len, reverse=True)) + r')\b')
    return pat.sub(lambda m: mapping[m.group(1)], text)


# ===========================================================================
# 3. alpha 归一（C 档）
# ===========================================================================

_TEMP = re.compile(r'\b_[A-Za-z0-9_]*\b')


def alpha_canon(text):
    """把下划线开头的 firtool 临时名按**首次出现顺序**重编成 `_@N`。"""
    order, n = {}, [0]

    def rep(m):
        w = m.group(0)
        if w not in order:
            n[0] += 1
            order[w] = '_@%d' % n[0]
        return order[w]
    return _TEMP.sub(rep, text), len(order)


_TEMPNUM = re.compile(r'\b(_[A-Za-z0-9_]*?_?(?:GEN|T))_\d+\b')


def temp_blind(text):
    """把 firtool 的 `_GEN_<n>` / `<x>_T_<n>` 编号抹成 `_@`。

    为什么需要它（而不是用 rank7 那个按声明顺序的 alpha 归一）：
    alpha 归一是**位置**归一 —— G1 只要在前面插进一个新临时线，后面整串编号平移，
    归一后反而**全不相等**。实测 Ftq：raw 逐行 diff ADD/DEL 各约 32000 行，
    按声明顺序 alpha 归一后是 32132 行（更糟），而抹掉编号后只剩 121 加 / 284 删。
    32000 行里 99% 是 firtool 给临时线重新发号，不是工作量。

    这是一个**下界**口径：抹编号会把两个真的不同的 `_GEN_5` / `_GEN_7` 也并成一个，
    所以它回答的是「这个目标的真改动**至多**多少行」，用来推翻「这是从头重写」够了，
    用来证明「这是纯接口增量」不够 —— 所以它**只作证据列与规模分级，不参与归档判据**。
    """
    return _TEMPNUM.sub(r'\1_@', text)


# ===========================================================================
# 4. 位宽记号归一（F_PORTWIDTH 分级）
# ===========================================================================

_RANGE = re.compile(r'\[\s*\d+\s*:\s*\d+\s*\]')
_SIZED = re.compile(r"\b\d[\d_]*'([sS]?[bodhBODH])")


def width_canon(text):
    s = _RANGE.sub('[@W]', text)
    s = _SIZED.sub(r"@N'\1", s)
    return s


# ===========================================================================
# 5. 逐行 diff + 归因引擎（A2 / B 共用）
# ===========================================================================

_DIFFLIB_LIMIT = 30000          # 逻辑行数上限；超了走多重集差（并在 TSV 标注）


def line_diff(l0, l1):
    """返回 (ADD 行列表, DEL 行列表, method)。"""
    if len(l0) <= _DIFFLIB_LIMIT and len(l1) <= _DIFFLIB_LIMIT:
        sm = difflib.SequenceMatcher(None, l0, l1, autojunk=False)
        add, dele = [], []
        for tag, i1, i2, j1, j2 in sm.get_opcodes():
            if tag in ('replace', 'delete'):
                dele.extend(l0[i1:i2])
            if tag in ('replace', 'insert'):
                add.extend(l1[j1:j2])
        return add, dele, 'difflib'
    c0, c1 = collections.Counter(l0), collections.Counter(l1)
    add, dele = [], []
    for k, v in (c1 - c0).items():
        add.extend([k] * v)
    for k, v in (c0 - c1).items():
        dele.extend([k] * v)
    return add, dele, 'multiset'


def attribute(add, dele, new_ids, old_ids, added_ports, removed_ports):
    """A2 / B 共用的**逐行归因**。返回 (ok, 不可归因的 ADD, 不可归因的 DEL)。

    规则（见文件头「为什么这样就挡住了粗字段名过滤冒充」）：
      * 有定义的行：**定义的每一个名字**都必须只在自己这侧存在（或是本次新增/删除的端口）；
      * 无定义的行：**引用的每一个标识符**都必须只在自己这侧存在；
      * 不引用任何标识符的纯结构行（多出来的 begin/end）：不可归因。
    """
    bad_add, bad_del = [], []
    ap, rp = set(added_ports), set(removed_ports)
    for ln in add:
        d = defs(ln)
        if d:
            if not d <= (new_ids | ap):
                bad_add.append(ln)
        else:
            u = idents(ln)
            if not u or not u <= new_ids:
                bad_add.append(ln)
    for ln in dele:
        d = defs(ln)
        if d:
            if not d <= (old_ids | rp):
                bad_del.append(ln)
        else:
            u = idents(ln)
            if not u or not u <= old_ids:
                bad_del.append(ln)
    return (not bad_add and not bad_del), bad_add, bad_del


def coarse_field_filter_equal(l0, l1, added_ports, removed_ports):
    """★仅供反例对照★ —— 老 `portattr_equal` 那套「粗字段名过滤」。

    「diff 行里**提到**了新增/删除端口名（或其粗前缀）就从两侧一起滤掉，再比是否相等」。
    本函数**不参与任何归档判定**，只在回归测试里跟严判据摆一起，
    证明它会把「改写」当成「接口增量」放过去。
    """
    names = set(added_ports) | set(removed_ports)
    coarse = set()
    for n in names:
        coarse.add(n)
        parts = n.split('_')
        for k in range(2, len(parts) + 1):
            coarse.add('_'.join(parts[:k]))

    def keep(ln):
        return not any(c in ln for c in coarse)
    return [x for x in l0 if keep(x)] == [x for x in l1 if keep(x)]


# ===========================================================================
# 6. 基线（例化点身份判据来自 check_name_collisions，带 pickle 缓存）
# ===========================================================================

def _fingerprint(root):
    h = hashlib.sha256()
    for p in sorted(pathlib.Path(root).glob('*.sv')):
        st = p.stat()
        h.update(('%s|%d|%d\n' % (p.name, st.st_size, st.st_mtime_ns)).encode())
    return h.hexdigest()[:16]


def load_baseline(root, cache_dir, use_cache=True):
    import pickle
    fp = _fingerprint(root)
    tag = hashlib.sha256(root.encode()).hexdigest()[:8]
    cf = pathlib.Path(cache_dir) / ('baseline_%s_%s.pkl' % (tag, fp))
    if use_cache and cf.exists():
        with open(cf, 'rb') as f:
            return pickle.load(f), str(cf)
    b = CNC.Baseline(root)
    if use_cache:
        cf.parent.mkdir(parents=True, exist_ok=True)
        with open(cf, 'wb') as f:
            pickle.dump(b, f, 4)
    return b, str(cf)


# ===========================================================================
# 7. 单个 target 的九档求值
# ===========================================================================

class Pred(object):
    __slots__ = ('ok', 'reason')

    def __init__(self, ok, reason):
        self.ok, self.reason = ok, reason

    def __repr__(self):
        return '<%s %s>' % ('OK' if self.ok else 'NO', self.reason)


class Result(dict):
    """一个 target 的完整判定。既是 TSV 的一行，也是测试的断言对象。"""

    @property
    def bucket(self):
        return self['bucket']

    @property
    def predicates(self):
        return self['_pred']


def _sha(path):
    if not os.path.exists(path):
        return ''
    return hashlib.sha256(pathlib.Path(path).read_bytes()).hexdigest()[:16]


class Classifier(object):
    def __init__(self, g0dir=G0_DEFAULT, g1dir=G1_DEFAULT, cache_dir=None,
                 use_cache=True, baselines=None):
        self.g0dir, self.g1dir = pathlib.Path(g0dir), pathlib.Path(g1dir)
        cache_dir = cache_dir or os.path.join(tempfile.gettempdir(),
                                              'ordered_classifier_cache')
        if baselines is not None:
            self.b0, self.b1 = baselines
            self.cache_files = ('(injected)', '(injected)')
        else:
            self.b0, c0 = load_baseline(str(self.g0dir), cache_dir, use_cache)
            self.b1, c1 = load_baseline(str(self.g1dir), cache_dir, use_cache)
            self.cache_files = (c0, c1)

    # ---- 名字映射：例化点身份优先，同名只是兜底 --------------------------
    def map_name(self, target):
        """G0 target -> G1 名字。返回 (g1_name, by, note)。

        **例化点身份优先于同名**。台账两处自相矛盾就是因为把「同名」当成了身份：
          g1_universe.tsv:48/49  G0 FastArbiter_30->_30 与 G0 FastArbiter_31->_30 并存
          g1_old_to_new_map.tsv:169/171  G0 NPC_31->_33 与 G0 NPC_33->_33 并存
        例化点判据给出的是双射：_30->_29、_31->_30；_31->_33、_33->_35。
        """
        in0, in1 = target in self.b0.mods, target in self.b1.mods
        if not in0:
            return (target if in1 else ''), ('g1_only' if in1 else 'absent_both'), ''
        hit, by = CNC.resolve(self.b0, self.b1, target)
        if len(hit) == 1:
            note = ''
            if hit[0] != target and in1:
                note = ('G1 同名模块 %s 是**另一个**设计元素（同名不同物）' % target)
            return hit[0], by, note
        if in1:
            return target, 'same_name_fallback', ('身份判据留白（%s），退回同名' % (by or '无'))
        return '', (by or 'unresolved'), '身份判据留白且 G1 无同名'

    # ---- 主入口 ----------------------------------------------------------
    def classify(self, target, g1_name=None, name_by=None, row_kind='LEDGER',
                 g0_name=None):
        g0_name = g0_name or target
        if g1_name is None:
            g1_name, name_by, name_note = self.map_name(g0_name)
        else:
            name_note = ''
            name_by = name_by or 'explicit'

        r = Result()
        r['target'] = target
        r['row_kind'] = row_kind
        r['g0_name'] = g0_name if g0_name in self.b0.mods else ''
        r['g1_name'] = g1_name
        r['name_map_by'] = name_by
        r['name_map_note'] = name_note
        r['g0_exists'] = 'yes' if g0_name in self.b0.mods else 'no'
        r['g1_exists'] = 'yes' if (g1_name and g1_name in self.b1.mods) else 'no'
        r['g1_same_name_exists'] = 'yes' if g0_name in self.b1.mods else 'no'

        preds = collections.OrderedDict()
        r['_pred'] = preds

        # ---------------- rank 1: X_RETIRED -------------------------------
        retired = (g0_name in self.b0.mods) and (g0_name not in self.b1.mods)
        succ, succ_by = ('', '')
        if g0_name in self.b0.mods:
            hit, by = CNC.resolve(self.b0, self.b1, g0_name)
            if len(hit) == 1:
                succ, succ_by = hit[0], by
        r['successor_g1'] = succ
        r['successor_by'] = succ_by
        preds['X_RETIRED'] = Pred(
            retired,
            ('G0 有该名字而 G1 没有 => 该名字下无 RTL 可交付；'
             '后继=%s（判据 %s）' % (succ or '(判不准)', succ_by or '-')) if retired
            else ('不成立：g1_same_name_exists=%s g0_exists=%s'
                  % (r['g1_same_name_exists'], r['g0_exists'])))

        # ---------------- rank 2a: G_NEWFORM ------------------------------
        newform = (g0_name not in self.b0.mods) and (g1_name in self.b1.mods)
        rev, rev_by = ('', '')
        if newform:
            hit, by = CNC.resolve(self.b1, self.b0, g1_name)
            if len(hit) == 1:
                rev, rev_by = hit[0], by
                newform = False
        r['g0_predecessor'] = rev
        r['g0_predecessor_by'] = rev_by
        preds['G_NEWFORM'] = Pred(
            newform,
            'G0 无同名且反向身份判据也定位不到前身 => G1 独有' if newform
            else ('不成立：g0_exists=%s%s'
                  % (r['g0_exists'],
                     ('，反向定位到 G0 前身 %s（%s）' % (rev, rev_by)) if rev else '')))

        # 没有 G1 侧文件的，后面所有 body 判据都无从谈起
        if g1_name not in self.b1.mods:
            for b in BUCKETS:
                preds.setdefault(b, Pred(False, 'G1 侧无此模块，判据不可求值'))
            self._finish(r, preds)
            self._blank_metrics(r)
            return r

        t1 = (self.g1dir / ('%s.sv' % g1_name)).read_text(errors='replace')
        pt1, b1body = module_span(t1, g1_name)
        p1 = parse_ports(pt1, 'G1/%s' % g1_name)
        n1 = norm_safe(b1body, g1_name)
        ll1 = logical_lines(n1)
        ids1 = set()
        for ln in ll1:
            ids1 |= idents(ln)

        # ---------------- rank 2b: P_SHIM ---------------------------------
        shim_res = norm_safe_pt(b1body, g1_name).strip()
        shim_res = re.sub(r'^\s*(wire|reg|logic)\b[^;]*;\s*$', '', shim_res, flags=re.M).strip()
        is_shim = (shim_res == '' and not instances(b1body)
                   and 'always' not in b1body)
        preds['P_SHIM'] = Pred(
            is_shim, 'G1 模块体只剩纯 io->io 直通，无例化、无 always'
            if is_shim else ('不成立：去直通后仍有 %d 字符残余 / 例化 %d 个 / always=%s'
                             % (len(shim_res), len(instances(b1body)),
                                'yes' if 'always' in b1body else 'no')))

        r['n_ports_g1'] = len(p1)
        r['n_inst_g1'] = len(instances(b1body))
        r['g1_body_lines'] = len(ll1)

        if g0_name not in self.b0.mods:
            for b in BUCKETS:
                preds.setdefault(b, Pred(False, 'G0 侧无此模块，G0/G1 对比判据不可求值'))
            self._finish(r, preds)
            self._blank_metrics(r, keep_g1=True)
            return r

        t0 = (self.g0dir / ('%s.sv' % g0_name)).read_text(errors='replace')
        pt0, b0body = module_span(t0, g0_name)
        p0 = parse_ports(pt0, 'G0/%s' % g0_name)
        n0 = norm_safe(b0body, g0_name)
        ll0 = logical_lines(n0)
        ids0 = set()
        for ln in ll0:
            ids0 |= idents(ln)

        d = port_delta(p0, p1)
        r['n_ports_g0'] = len(p0)
        r['ports_added'] = len(d['added'])
        r['ports_removed'] = len(d['removed'])
        r['width_chg'] = len(d['width_chg'])
        r['dir_chg'] = len(d['dir_chg'])
        r['width_chg_sample'] = ';'.join('%s:%s->%s' % w for w in d['width_chg'][:4])
        r['dir_chg_sample'] = ';'.join('%s:%s->%s' % w for w in d['dir_chg'][:4])
        r['ports_added_sample'] = ';'.join(d['added'][:4])
        r['ports_removed_sample'] = ';'.join(d['removed'][:4])
        r['ready_g0'] = sum(1 for p in p0 if is_ready(p.name))
        r['ready_added'] = sum(1 for n in d['added'] if is_ready(n))
        r['ready_removed'] = sum(1 for n in d['removed'] if is_ready(n))
        i0m, i1m = instances(b0body), instances(b1body)
        r['n_inst_g0'] = len(i0m)
        r['inst_added'] = len(set(i1m) - set(i0m))
        r['inst_removed'] = len(set(i0m) - set(i1m))
        r['g0_body_lines'] = len(ll0)
        r['sha256_g0'] = _sha(str(self.g0dir / ('%s.sv' % g0_name)))
        r['sha256_g1'] = _sha(str(self.g1dir / ('%s.sv' % g1_name)))

        # ---------------- rank 3: A_BODY_IDENTICAL ------------------------
        body_id = (n0.replace('@SELF@', '@S@') == n1.replace('@SELF@', '@S@'))
        r['body_identical_safe'] = 'yes' if body_id else 'no'
        pt_eq = (norm_safe_pt(b0body, g0_name) == norm_safe_pt(b1body, g1_name))
        r['body_identical_safe_pt'] = 'yes' if pt_eq else 'no'
        a_ok = body_id and r['width_chg'] == 0 and r['dir_chg'] == 0
        if body_id and (r['width_chg'] or r['dir_chg']):
            a_reason = ('★禁止落 A★：模块体归一化后逐字相同，但 width_chg=%d dir_chg=%d '
                        '(%s) —— 继承会产出位宽写回旧值的核'
                        % (r['width_chg'], r['dir_chg'],
                           r['width_chg_sample'] or r['dir_chg_sample']))
        elif not body_id:
            a_reason = '不成立：安全归一化后模块体不同（body_identical_safe=no）'
        else:
            a_reason = '安全归一化后模块体逐字相同，且 width_chg==0 && dir_chg==0'
        preds['A_BODY_IDENTICAL'] = Pred(a_ok, a_reason)

        # ---------------- 逐行 diff（A2 / B / 规模分级共用）----------------
        add, dele, method = line_diff(ll0, ll1)
        r['diff_method'] = method
        r['diff_add'] = len(add)
        r['diff_del'] = len(dele)
        new_ids, old_ids = ids1 - ids0, ids0 - ids1
        r['new_ident_cnt'] = len(new_ids)
        r['old_ident_cnt'] = len(old_ids)

        ok_attr, bad_a, bad_d = attribute(add, dele, new_ids, old_ids,
                                          d['added'], d['removed'])
        r['attrib_ok'] = 'yes' if ok_attr else 'no'
        r['attrib_bad_add'] = len(bad_a)
        r['attrib_bad_del'] = len(bad_d)
        r['attrib_bad_sample'] = ' || '.join((bad_a[:2] + bad_d[:2]))[:300]

        # ---------------- rank 4: A2_IFACE_ONLY ---------------------------
        iface_changed = (r['ports_added'] + r['ports_removed']) > 0
        a2_ok = (iface_changed and r['width_chg'] == 0 and r['dir_chg'] == 0
                 and ok_attr and not body_id)
        if not iface_changed:
            a2_reason = '不成立：ports_added+ports_removed == 0，没有接口增量'
        elif r['width_chg'] or r['dir_chg']:
            a2_reason = ('不成立：width_chg=%d dir_chg=%d（A2 只允许接口/派生接口连线变化）'
                         % (r['width_chg'], r['dir_chg']))
        elif body_id:
            a2_reason = '不成立：模块体本来就逐字相同，已在 rank3 归档'
        elif not ok_attr:
            a2_reason = ('不成立：%d 条 ADD / %d 条 DEL 行**不可归因**于新增/删除端口 —— '
                         '它们定义的名字在对侧也存在（即改写，不是增量）。样例: %s'
                         % (len(bad_a), len(bad_d), r['attrib_bad_sample'][:160]))
        else:
            a2_reason = ('全部 %d ADD / %d DEL 行逐行归因通过：'
                         '定义名只在本侧存在或属新增/删除端口'
                         % (len(add), len(dele)))
        preds['A2_IFACE_ONLY'] = Pred(a2_ok, a2_reason)

        # ---------------- rank 5: F_PORTWIDTH -----------------------------
        f_ok = (r['dir_chg'] == 0 and r['width_chg'] > 0)
        wc0, wc1 = width_canon(n0), width_canon(n1)
        pure = (wc0.replace('@SELF@', '@S@') == wc1.replace('@SELF@', '@S@'))
        r['f_portwidth_grade'] = ('PURE_REPARAM' if pure else 'REPARAM_PLUS_LOGIC') if f_ok else ''
        preds['F_PORTWIDTH'] = Pred(
            f_ok, ('方向不变、%d 个端口位宽变化 (%s)；位宽记号归一后模块体%s => %s'
                   % (r['width_chg'], r['width_chg_sample'],
                      '相同' if pure else '仍有残余 diff', r['f_portwidth_grade']))
            if f_ok else ('不成立：width_chg=%d dir_chg=%d'
                          % (r['width_chg'], r['dir_chg'])))

        # ---------------- rank 6: D_DEPRENUM ------------------------------
        cmap, cprob = child_rename_by_instname(b0body, b1body)
        r['child_rename_map'] = ';'.join('%s->%s' % kv for kv in sorted(cmap.items()))
        r['child_rename_n'] = len(cmap)
        contra, unresolved = [], []
        for c0, c1 in sorted(cmap.items()):
            if c0 not in self.b0.mods:
                unresolved.append('%s(G0缺)' % c0)
                continue
            hit, by = CNC.resolve(self.b0, self.b1, c0)
            if len(hit) == 1:
                if hit[0] != c1:
                    contra.append('%s: 实例名说->%s，例化点身份说->%s(%s)' % (c0, c1, hit[0], by))
            else:
                unresolved.append('%s(身份判据留白)' % c0)
        r['d_contradictions'] = ' | '.join(contra)
        r['d_unresolved_children'] = ' | '.join(unresolved)
        subbed = simul_sub(n0, cmap)
        deprenum_eq = (subbed.replace('@SELF@', '@S@') == n1.replace('@SELF@', '@S@'))
        r['deprenum_eq'] = 'yes' if deprenum_eq else 'no'
        d_ok = (bool(cmap) and not cprob and deprenum_eq and not contra
                and r['width_chg'] == 0 and r['dir_chg'] == 0)
        if not cmap:
            d_reason = '不成立：按实例名配对没有任何子模块改名'
        elif cprob:
            d_reason = '不成立：实例名配对有问题 —— ' + '; '.join(cprob)
        elif contra:
            d_reason = '★不落 D★：实例名配对与例化点身份判据矛盾 —— ' + r['d_contradictions']
        elif not deprenum_eq:
            d_reason = '不成立：同时代入改名后模块体仍不相同'
        elif r['width_chg'] or r['dir_chg']:
            d_reason = ('不成立：width_chg=%d dir_chg=%d（已在 rank5 归档）'
                        % (r['width_chg'], r['dir_chg']))
        else:
            d_reason = ('按实例名得到 %d 处子模块改名，同时代入后模块体逐字相同；'
                        '每一对都经例化点身份判据校验无矛盾' % len(cmap))
        preds['D_DEPRENUM'] = Pred(d_ok, d_reason)

        # ---------------- rank 7: C_ALPHA_RENAME --------------------------
        a0, na0 = alpha_canon(simul_sub(n0, cmap))
        a1, na1 = alpha_canon(n1)
        alpha_eq = (a0.replace('@SELF@', '@S@') == a1.replace('@SELF@', '@S@'))
        r['alpha_eq'] = 'yes' if alpha_eq else 'no'
        r['alpha_temps_g0'] = na0
        r['alpha_temps_g1'] = na1

        # ---- 抹掉临时线编号之后的残余（**只作证据列，不改归档**）----------
        # firtool 临时名（_GEN_87 之类）在 422 个 commit 之间整串重新发号，raw 逐行
        # diff 会被它淹没：Ftq raw ADD/DEL 各约 32000 行，看上去像「从头重写」，
        # 抹掉编号后只剩 121/284 —— 那才是真改动的量级。归档仍严格按 codex 的顺序
        # （A2 在 C 之前，所以 A2 判据只吃安全归一化，不吃这层归一），
        # 但两个数都摆出来，排期的人一眼能分清「临时名 churn」和「真的重写」。
        tb0 = [temp_blind(x) for x in ll0]
        tb1 = [temp_blind(x) for x in ll1]
        tadd, tdel, tmethod = line_diff(tb0, tb1)
        tids0, tids1 = set(), set()
        for ln in tb0:
            tids0 |= idents(ln)
        for ln in tb1:
            tids1 |= idents(ln)
        tok, tbad_a, tbad_d = attribute(tadd, tdel, tids1 - tids0, tids0 - tids1,
                                        d['added'], d['removed'])
        r['resid_diff_tb'] = max(len(tadd), len(tdel))
        r['diff_method_tb'] = tmethod
        r['attrib_ok_tb'] = 'yes' if tok else 'no'
        r['tb_iface_only'] = ('yes' if (tok and not ok_attr and iface_changed
                                        and r['width_chg'] == 0 and r['dir_chg'] == 0)
                              else 'no')
        r['tb_bad_sample'] = ' || '.join((tbad_a[:2] + tbad_d[:2]))[:300]

        c_ok = alpha_eq and not body_id and r['width_chg'] == 0 and r['dir_chg'] == 0
        preds['C_ALPHA_RENAME'] = Pred(
            c_ok, ('临时线按声明顺序 alpha 等价（%d<->%d 个临时名双射）—— '
                   '★只能继承施工，不能继承 PASS★' % (na0, na1)) if c_ok
            else ('不成立：alpha_eq=%s body_identical=%s width_chg=%d dir_chg=%d'
                  % (r['alpha_eq'], r['body_identical_safe'],
                     r['width_chg'], r['dir_chg'])))

        # ---------------- rank 8: B_HANDSHAKE -----------------------------
        b_ok = r['ready_added'] > 0
        r['handshake_grade'] = ''
        if b_ok:
            r['handshake_grade'] = ('NEW_HANDSHAKE' if r['ready_g0'] == 0
                                    else 'EXTENDED_HANDSHAKE')
            r['handshake_purity'] = 'B' if ok_attr else 'B+E'
        else:
            r['handshake_purity'] = ''
        preds['B_HANDSHAKE'] = Pred(
            b_ok, ('新增 %d 个 ready 端口（G0 原有 %d 个 => %s）；归因%s => %s'
                   % (r['ready_added'], r['ready_g0'], r['handshake_grade'],
                      '全通过' if ok_attr else '有 %d 行不可归因' % (len(bad_a) + len(bad_d)),
                      r['handshake_purity'])) if b_ok
            else '不成立：ready_added==0（G0 原有 ready 端口 %d 个 —— '
                 '★含 ready 不等于 B★）' % r['ready_g0'])

        # ---------------- rank 9: E_LOGIC / F_MORPH -----------------------
        shape = (r['n_ports_g0'] != r['n_ports_g1'] or r['width_chg'] or r['dir_chg']
                 or r['inst_added'] or r['inst_removed'])
        resid = max(len(add), len(dele))
        r['resid_diff'] = resid
        r['shape_change'] = 'yes' if shape else 'no'
        # 规模分级用**抹掉临时线编号后**的残余：firtool 重新发号不是工作量。
        graded = r['resid_diff_tb']
        sub = ('F_MORPH' if shape else 'E_LOGIC') + (
            '_S' if graded <= 40 else ('_M' if graded <= 600 else '_L'))
        r['ef_subgrade'] = sub
        preds['E_F_RESIDUAL'] = Pred(
            True, '兜底档：%s，抹掉临时线编号后残余 diff %d 行'
            '（raw %d 行；差额=firtool 临时名重新发号）'
            % (sub, graded, resid))

        # ---------------- P4：同名但内容变了的子模块（施工告警，不改归档）----
        kept = {i1m[k] for k in set(i0m) & set(i1m) if i0m[k] == i1m[k]}
        p4 = []
        for c in sorted(kept):
            fa, fb = self.g0dir / ('%s.sv' % c), self.g1dir / ('%s.sv' % c)
            if not fa.exists() or not fb.exists():
                p4.append('%s(单侧缺文件)' % c)
            elif fa.read_bytes() != fb.read_bytes():
                p4.append(c)
        r['p4_children_changed'] = ';'.join(p4[:10])
        r['p4_n'] = len(p4)

        self._finish(r, preds)
        return r

    # ---- 归档 + 重叠裁决 --------------------------------------------------
    def _finish(self, r, preds):
        sat = [b for _, b in ORDER if preds.get(b) and preds[b].ok]
        r['satisfies'] = ','.join(sat) if sat else ''
        if not sat:
            raise ClassifyError('%s: 九档全不成立（兜底档也没兜住）—— 分类器有 bug'
                                % r['target'])
        bucket = sat[0]
        r['bucket'] = bucket
        r['order_rank'] = dict((b, k) for k, b in ORDER)[bucket]
        r['reason'] = preds[bucket].reason
        if len(sat) > 1:
            later = sat[1:]
            r['adjudication'] = (
                '重叠：同时满足 %s；按契约顺序归入 rank%d %s；'
                '被顺序压后的档=%s（它们的判据也成立，但顺序即契约，后面的档不再重判）'
                % (','.join(sat), r['order_rank'], bucket, ','.join(later)))
        else:
            r['adjudication'] = '无重叠：只满足 %s' % bucket
        # 判不准 / 继承语义
        r['determinacy'] = 'DETERMINATE'
        if bucket == 'E_F_RESIDUAL' and r.get('resid_diff_tb', 0) > 600:
            r['determinacy'] = 'INDETERMINATE'
        if bucket in ('X_RETIRED',):
            r['determinacy'] = 'DETERMINATE' if r.get('successor_g1') else 'INDETERMINATE'
        r['inherit_construction'] = 'yes' if bucket in (
            'A_BODY_IDENTICAL', 'A2_IFACE_ONLY', 'F_PORTWIDTH',
            'D_DEPRENUM', 'C_ALPHA_RENAME') else 'no'
        r['inherit_pass'] = 'NO'
        if bucket == 'A_BODY_IDENTICAL' and r.get('p4_n', 0) == 0:
            r['inherit_pass'] = 'CANDIDATE'
        caveats = []
        if r.get('p4_n'):
            caveats.append('P4:%d 个同名子模块在 G1 内容变了（%s）—— '
                           '只有可读实现把它们当黑盒（两侧共用 G1 定义）才允许继承'
                           % (r['p4_n'], r['p4_children_changed']))
        if r.get('name_map_note'):
            caveats.append(r['name_map_note'])
        if r.get('d_contradictions'):
            caveats.append('D 判据矛盾：' + r['d_contradictions'])
        if r.get('dir_chg'):
            caveats.append('dir_chg=%d（端口方向翻转，任何继承方案都要重新审接口）'
                           % r['dir_chg'])
        if bucket == 'C_ALPHA_RENAME':
            caveats.append('C 档只决定「继承施工」，**不得继承 PASS**（codex 0144）')
        if r.get('tb_iface_only') == 'yes':
            caveats.append('★抹掉临时线编号后逐行归因全通过★：这其实是「接口增量 + firtool '
                           '临时名重新发号」，raw 残余 %d 行 -> 抹编号后 %d 行 —— '
                           '别当从头重写排期（A2 判据按 codex 顺序只吃安全归一化，故未落 A2）'
                           % (r.get('resid_diff', 0), r.get('resid_diff_tb', 0)))
        if (r.get('bucket') == 'E_F_RESIDUAL' and r.get('resid_diff', 0) > 600
                and r.get('resid_diff_tb', 0) <= 600):
            caveats.append('★台账「从头重写」口径存疑★：raw 残余 %d 行，但抹掉 firtool '
                           '临时线编号后只剩 %d 行 —— 真改动是小手术，不是重写'
                           % (r.get('resid_diff', 0), r.get('resid_diff_tb', 0)))
        if r.get('diff_method') == 'multiset':
            caveats.append('模块体过大（%s/%s 逻辑行），diff 走多重集口径，'
                           '不含语句顺序信息' % (r.get('g0_body_lines'), r.get('g1_body_lines')))
        r['caveats'] = ' | '.join(caveats)

    @staticmethod
    def _blank_metrics(r, keep_g1=False):
        for k in ('n_ports_g0', 'ports_added', 'ports_removed', 'width_chg', 'dir_chg',
                  'ready_g0', 'ready_added', 'n_inst_g0', 'inst_added', 'inst_removed',
                  'diff_add', 'diff_del', 'resid_diff', 'child_rename_n', 'p4_n',
                  'alpha_temps_g0', 'alpha_temps_g1', 'g0_body_lines', 'resid_diff_tb',
                  'new_ident_cnt', 'old_ident_cnt', 'attrib_bad_add', 'attrib_bad_del'):
            r.setdefault(k, 0)
        if not keep_g1:
            for k in ('n_ports_g1', 'n_inst_g1', 'g1_body_lines'):
                r.setdefault(k, 0)


# ===========================================================================
# 8. TSV
# ===========================================================================

COLUMNS = [
    'target', 'row_kind', 'order_rank', 'bucket', 'determinacy',
    'g0_name', 'g1_name', 'name_map_by', 'g1_same_name_exists',
    'successor_g1', 'successor_by', 'g0_predecessor', 'g0_predecessor_by',
    'satisfies', 'adjudication', 'reason', 'caveats',
    'inherit_construction', 'inherit_pass',
    'n_ports_g0', 'n_ports_g1', 'ports_added', 'ports_removed',
    'width_chg', 'dir_chg', 'width_chg_sample', 'dir_chg_sample',
    'ports_added_sample', 'ports_removed_sample',
    'ready_g0', 'ready_added', 'handshake_grade', 'handshake_purity',
    'body_identical_safe', 'body_identical_safe_pt', 'alpha_eq',
    'alpha_temps_g0', 'alpha_temps_g1',
    'deprenum_eq', 'child_rename_n', 'child_rename_map',
    'd_contradictions', 'd_unresolved_children',
    'attrib_ok', 'attrib_bad_add', 'attrib_bad_del', 'attrib_bad_sample',
    'diff_method', 'diff_add', 'diff_del', 'resid_diff', 'shape_change',
    'resid_diff_tb', 'diff_method_tb', 'attrib_ok_tb', 'tb_iface_only', 'tb_bad_sample',
    'ef_subgrade', 'f_portwidth_grade',
    'n_inst_g0', 'n_inst_g1', 'inst_added', 'inst_removed',
    'p4_n', 'p4_children_changed',
    'g0_body_lines', 'g1_body_lines', 'new_ident_cnt', 'old_ident_cnt',
    'sha256_g0', 'sha256_g1', 'name_map_note',
]


def _cell(v):
    s = '' if v is None else str(v)
    return s.replace('\t', ' ').replace('\n', ' ')


def rows_to_tsv(rows):
    out = ['\t'.join(COLUMNS)]
    for r in rows:
        out.append('\t'.join(_cell(r.get(c, '')) for c in COLUMNS))
    return '\n'.join(out) + '\n'


# ===========================================================================
# 9. 自检：本脚本不写 RTL
# ===========================================================================

def selftest_nortl(path=None):
    """机械证明：源码里不存在任何「写 .sv」的路径。

    codex 0144：`strip_randomize` 只允许用于迁移分类分析；
    Formal 的 golden/ref 输入不得删除或重写这些字节。本脚本永不产出 RTL。
    """
    src = pathlib.Path(path or __file__).read_text()
    bad = []
    for m in re.finditer(r"(write_text|write_bytes|shutil\.copy\w*|os\.replace)\s*\(", src):
        bad.append('写文件调用: ' + src[max(0, m.start() - 60):m.end() + 20].replace('\n', ' '))
    for m in re.finditer(r"open\s*\(([^)]*)\)", src):
        arg = m.group(1)
        if "'w" in arg or '"w' in arg or "'a" in arg:
            ctx = src[max(0, m.start() - 120):m.end()]
            if '.sv' in ctx:
                bad.append('可能写 .sv: ' + ctx.replace('\n', ' ')[-120:])
    if re.search(r"""['"]\.sv['"]\s*\)?\s*$""", '', re.M):
        pass
    for m in re.finditer(r"\.sv['\"]", src):
        seg = src[max(0, m.start() - 200):m.start()]
        if re.search(r'(write_text|write_bytes|open\s*\([^)]*[\'"][wa])', seg):
            bad.append('写 .sv 上下文: ' + seg[-100:].replace('\n', ' '))
    return bad


# ===========================================================================
# 10. CLI
# ===========================================================================

def read_ledger(path):
    """读 migration_plan.tsv：返回 [(target, ledger_mode, ledger_g1_name)]。"""
    rows = []
    with open(path, encoding='utf-8', errors='replace') as f:
        hdr = f.readline().rstrip('\n').split('\t')
        ix = dict((h, i) for i, h in enumerate(hdr))
        for ln in f:
            c = ln.rstrip('\n').split('\t')
            if not c or not c[0].strip() or c[0].startswith('#'):
                continue
            rows.append((c[0],
                         c[ix['mode']] if 'mode' in ix and len(c) > ix['mode'] else '',
                         c[ix['g1_name']] if 'g1_name' in ix and len(c) > ix['g1_name'] else ''))
    return rows


def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__.split('\n')[0],
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument('--g0-dir', default=G0_DEFAULT)
    ap.add_argument('--g1-dir', default=G1_DEFAULT)
    ap.add_argument('--ledger', help='migration_plan.tsv')
    ap.add_argument('--target', action='append', default=[])
    ap.add_argument('--tsv', help='结果 TSV 输出路径')
    ap.add_argument('--manifest', help='可复算 manifest（含 sha256 与重跑命令）')
    ap.add_argument('--diff-ledger', action='store_true', help='与台账 mode 列对账')
    ap.add_argument('--diff-out', help='对账报告输出路径')
    ap.add_argument('--explain', action='store_true', help='逐 target 打九档判据取值')
    ap.add_argument('--no-derive-successors', action='store_true')
    ap.add_argument('--cache-dir')
    ap.add_argument('--no-cache', action='store_true')
    ap.add_argument('--selftest-nortl', action='store_true')
    a = ap.parse_args(argv)

    if a.selftest_nortl:
        bad = selftest_nortl()
        if bad:
            print('SELFTEST FAIL: 本脚本出现了写 RTL 的路径:')
            for b in bad:
                print('  ' + b)
            return 2
        print('SELFTEST OK: ordered_classifier.py 不写任何 .sv；'
              'strip_randomize 只用于分类分析')
        return 0

    if not a.ledger and not a.target:
        ap.error('至少给 --ledger 或 --target')
    for dd in (a.g0_dir, a.g1_dir):
        if not os.path.isdir(dd):
            print('ERROR: golden 目录不存在: %s' % dd, file=sys.stderr)
            return 2

    t0 = time.time()
    cl = Classifier(a.g0_dir, a.g1_dir, a.cache_dir, not a.no_cache)
    ledger = read_ledger(a.ledger) if a.ledger else []
    lmode = dict((t, m) for t, m, _ in ledger)
    lg1 = dict((t, g) for t, _, g in ledger)
    targets = [t for t, _, _ in ledger] + [t for t in a.target if t not in lmode]

    rows, errs = [], []
    seen = set()
    for t in targets:
        if t in seen:
            continue
        seen.add(t)
        try:
            r = cl.classify(t)
        except ClassifyError as e:
            errs.append('%s: %s' % (t, e))
            continue
        r['ledger_mode'] = lmode.get(t, '')
        r['ledger_g1_name'] = lg1.get(t, '')
        rows.append(r)

    # 派生后继 target：X_RETIRED 的施工量不能在改名处丢掉
    if not a.no_derive_successors:
        extra = []
        for r in rows:
            if r['bucket'] == 'X_RETIRED' and r['successor_g1'] and \
                    r['successor_g1'] not in seen:
                seen.add(r['successor_g1'])
                try:
                    e = cl.classify(r['successor_g1'], g1_name=r['successor_g1'],
                                    name_by='successor_of:%s' % r['target'],
                                    row_kind='DERIVED_SUCCESSOR',
                                    g0_name=r['g0_name'])
                    e['ledger_mode'] = ''
                    e['ledger_g1_name'] = ''
                    extra.append(e)
                except ClassifyError as ex:
                    errs.append('%s(derived): %s' % (r['successor_g1'], ex))
        rows.extend(extra)

    rows.sort(key=lambda r: (r['order_rank'], r['bucket'], r['target']))

    if a.explain:
        for r in rows:
            print('=' * 78)
            print('%s  [%s]  -> rank%d %s  (%s)'
                  % (r['target'], r['row_kind'], r['order_rank'], r['bucket'],
                     r['determinacy']))
            print('  G0=%s  G1=%s  (名字判据 %s)' % (r['g0_name'] or '-',
                                                     r['g1_name'] or '-',
                                                     r['name_map_by']))
            for b in BUCKETS:
                p = r['_pred'].get(b)
                if p is None:
                    continue
                print('   %-4s %-18s %s  %s' % (
                    'rank%d' % dict((x, k) for k, x in ORDER)[b], b,
                    'HIT ' if p.ok else 'miss', p.reason))
            print('  裁决: %s' % r['adjudication'])
            if r['caveats']:
                print('  告警: %s' % r['caveats'])

    tsv = rows_to_tsv(rows)
    tsv_sha = hashlib.sha256(tsv.encode()).hexdigest()
    if a.tsv:
        pathlib.Path(a.tsv).parent.mkdir(parents=True, exist_ok=True)
        with open(a.tsv, 'w', encoding='utf-8') as f:
            f.write(tsv)
        print('wrote %s  (%d rows, sha256=%s)' % (a.tsv, len(rows), tsv_sha))
    else:
        sys.stdout.write(tsv)

    dist = collections.Counter(r['bucket'] for r in rows)
    print('# 分布: ' + '  '.join('%s=%d' % (b, dist[b]) for _, b in ORDER if dist[b]),
          file=sys.stderr)
    if errs:
        print('# 判不出档 (%d): %s' % (len(errs), '; '.join(errs[:5])), file=sys.stderr)

    if a.diff_ledger and ledger:
        rep = diff_ledger_report(rows, lmode, lg1)
        if a.diff_out:
            with open(a.diff_out, 'w', encoding='utf-8') as f:
                f.write(rep)
            print('wrote %s' % a.diff_out)
        else:
            print(rep)

    if a.manifest:
        man = {
            'generated_by': 'scripts/ordered_classifier.py',
            'script_sha256': hashlib.sha256(
                pathlib.Path(__file__).read_bytes()).hexdigest(),
            'dep_sha256': {
                'scripts/check_name_collisions.py': hashlib.sha256(
                    (_HERE / 'check_name_collisions.py').read_bytes()).hexdigest(),
            },
            'g0_dir': a.g0_dir, 'g0_fingerprint': _fingerprint(a.g0_dir),
            'g1_dir': a.g1_dir, 'g1_fingerprint': _fingerprint(a.g1_dir),
            'ledger': a.ledger,
            'ledger_sha256': (hashlib.sha256(
                pathlib.Path(a.ledger).read_bytes()).hexdigest() if a.ledger else ''),
            'n_rows': len(rows),
            'tsv': a.tsv, 'tsv_sha256': tsv_sha,
            'distribution': dict(dist),
            'elapsed_s': round(time.time() - t0, 1),
            'order_contract': ['rank%d:%s' % (k, b) for k, b in ORDER],
            'rerun': ('python3 scripts/ordered_classifier.py --ledger %s --tsv %s '
                      '--manifest %s --diff-ledger --diff-out %s'
                      % (a.ledger, a.tsv, a.manifest, a.diff_out or '<diff.md>')),
            'note': ('分类分析专用。strip_randomize 只用于本分析；'
                     'Formal 的 golden/ref 输入不得删除或重写这些字节。'
                     '本脚本不生成 RTL（--selftest-nortl 机械证明）。'),
        }
        with open(a.manifest, 'w', encoding='utf-8') as f:
            json.dump(man, f, indent=2, ensure_ascii=False)
        print('wrote %s' % a.manifest)

    return 3 if errs else 0


def diff_ledger_report(rows, lmode, lg1):
    """与旧台账 mode 列对账。"""
    L = []
    L.append('# 有序分类器 vs 旧台账（migration_plan.tsv）对账\n')
    L.append('旧台账的 mode 与本分类器的 bucket 不是同一套词表；'
             '下表按「施工方案是否改变」列出差异。\n')
    same_family = {
        'X_RETIRED': {'X_RETIRED'},
        'G_NEWFORM': {'G_NEWFORM'},
        'P_SHIM': {'P_SHIM'},
        'A_BODY_IDENTICAL': {'I_IDENTICAL', 'A_IFACE'},
        'A2_IFACE_ONLY': {'A2_IFACE_DEEP', 'A_IFACE'},
        'F_PORTWIDTH': {'F_PORTWIDTH'},
        'D_DEPRENUM': {'D_DEPRENUM'},
        'C_ALPHA_RENAME': {'C_RENUMBER', 'C2_TEMPNAME_CHURN'},
        'B_HANDSHAKE': {'B_HANDSHAKE', 'B2_HANDSHAKE_PARTIAL'},
        'E_F_RESIDUAL': {'E_LOGIC_S', 'E_LOGIC_M', 'F_MORPH_S', 'F_MORPH_M',
                         'U_INDETERMINATE'},
    }
    changed, kept = [], []
    for r in rows:
        if r['row_kind'] != 'LEDGER':
            continue
        old = lmode.get(r['target'], '')
        (kept if old in same_family.get(r['bucket'], set()) else changed).append(
            (r['target'], old, r['bucket'], r))
    L.append('- 台账行 %d，其中施工方案**改变** %d，未变 %d\n'
             % (len(kept) + len(changed), len(changed), len(kept)))
    L.append('\n## 分类改变的 target\n')
    L.append('| target | 旧台账 mode | 新 bucket | 依据 |')
    L.append('|---|---|---|---|')
    for t, old, new, r in sorted(changed, key=lambda x: (x[2], x[0])):
        L.append('| `%s` | %s | **%s** | %s |'
                 % (t, old or '(空)', new, r['reason'].replace('|', '/')[:220]))
    L.append('\n## g1_name 映射与台账不一致的 target（例化点身份 vs 同名假设）\n')
    L.append('| target | 台账 g1_name | 身份判据 g1_name | 判据 |')
    L.append('|---|---|---|---|')
    n = 0
    for r in rows:
        if r['row_kind'] != 'LEDGER':
            continue
        old = (lg1.get(r['target']) or '').strip()
        new = r['g1_name']
        if old and old != '-' and new and old != new:
            L.append('| `%s` | %s | **%s** | %s |' % (r['target'], old, new,
                                                      r['name_map_by']))
            n += 1
    if n == 0:
        L.append('| (无) | | | |')
    return '\n'.join(L) + '\n'


if __name__ == '__main__':
    sys.exit(main())
