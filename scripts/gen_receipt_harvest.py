#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""gen_receipt_harvest.py —— 逐份核对 lane worktree 里的绿 receipt 能不能收进版本库。

## 为什么要有它

`scripts/check_lane_receipts.py` 做的是**正面清点**：它只回答"有多少份绿 receipt
只存在于 lane worktree、台账看不见"。它**故意**不回答"哪一份能收"——因为
`git add -f evidence/<run>` 收一批很容易，而收错的代价是犯 CONVENTIONS.md 那条
硬约定：★别把不同前提下产出的结果并列成一张表★。

这些 receipt 是在**各自当时**的 `scripts/fm_eq.tcl`（含 vmucp 白名单）、钉点脚本、
公共核、golden 基线、工具版本下产出的。每一行单独看都是真的；坏的是那句没写出来
的隐含断言「这些数字可以横向比较」。本脚本把那句隐含断言变成**逐项可复算的判据**。

## 三关

关一 实现在不在 main
    receipt 的 `impl_closure` 里 `kind=repo` 的每个文件，在本仓当前 HEAD 工作树里
    是否存在。不存在 -> NEEDS_RTL_MERGE（只收 receipt 没有意义：
    `rewrite_coverage.proven = rewritten_modules() & proven_modules()`，
    rtl/ 里没有这个 module，收了也不进 proven）。

关二 证明闭包与 main 当前是否一致（逐项，全部机械可复算）

    (1) golden   `g1_canonical_id` + `golden_closure` 每个文件的 sha256 对
                 G1-canonical/golden-rtl 当前字节。
    (2) impl     `impl_closure` 里 kind=repo 的每个文件 sha256 对本仓当前字节
                 —— 这一项同时覆盖"共享件（公共核 / 共享 package / 生成器产物）
                 有没有被别的 lane 改过"。
    (3) fm_eq    ★本关最阴险的一项★。白名单在**每个目标的闭包里**，改一次就让
                 之前所有 receipt 变成旧前提。判据**不是**比 sha、也不是读 diff
                 说"我觉得只动了守卫"——那是拿被判断的对象自己当判据
                 （见 verif/ut/OthersEntry_common/PIN_GUARD_FIX.md 驳回过的更弱判据：
                  比对模板化的那一行，而那一行恰恰就是守卫本身）。
                 判据是 `scripts/fm_eq_trace.tcl`：用 receipt **自己记录的**入口环境
                 （FM_TOP / FM_MODE / vmucp / merge_dup / interface_only，全部取自
                 `proof_config.entry_appvars_readback`，即 FM 自己的读回值）与同一组
                 桩返回值，在 tclsh 下把两版 fm_eq.tcl 各跑一遍，逐字节比对**实际
                 发出的 FM 命令序列**。相同 ⇒ 这份 receipt 换到 main 当前 fm_eq.tcl
                 下会走出同一条路径。
    (4) pins     `sidecar/sourced_*fm_pins*.tcl`（跑的时候的**字节快照**）对本仓
                 当前同路径文件。
    (5) emitter  `sidecar/sourced_001_fm_native_emit.tcl` 对本仓当前 emitter。
    (6) decl     `proof_config.declarations`（verif/allow/*.json、verif/dead_ref/*.json）
                 对本仓当前字节。
    (7) tool     fm.log 里的 fm_shell 版本对基准版本。
    (8) facts    ★不信 receipt 的 verdict 字符串，直接看 native_facts 的数★：
                 passing>0、failing/unverified/aborted/unread_notcompared 全 0、
                 unmatched 六项全 0、无 dont_verify、无 relaxed appvar。
                 verdict 是别的脚本在别的时候算出来的**一个词**，而本表的整个用途
                 就是"别把不同前提下的结论并列"——一个词不带前提，数带。
                 PASS_DEAD_REF 例外，但换的是**更紧**的一条而不是放宽：unread 点必须
                 有 verif/dead_ref/<top>.json 声明，且**逐点路径集合**与实测相等
                 （不是比个数——个数相同而点不同正是该拦的东西）。声明文件的字节由 (6) 把守。

关三 同一目标多轮 receipt，哪一份是权威
    只收一份。优先**同一个 run 目录里成批重出**的那一份（同一 commit 上的批量
    重出是唯一能横向并列的形态），同批规模相同再取新的。其余记 SUPERSEDED。

## 结论取值

    COLLECTED        三关全过，且是本目标选中的那一份 -> `git add -f evidence/<run>`
    NEEDS_RTL_MERGE  关一不过：实现还不在 main
    NEEDS_RERUN      关二有项不一致，且无法证明该差异与本次证明无关
    SUPERSEDED       同一目标已有更权威的一份（或台账里已有绿判决）

## 用法

    python3 scripts/gen_receipt_harvest.py                    # 生成 docs/receipt_harvest.tsv
    python3 scripts/gen_receipt_harvest.py --check            # 复算并比对，不一致则非零退出

★禁止手工编辑 docs/receipt_harvest.tsv★——手改完下次重跑就没了，要改改生成器。

## `--check` 的口径 —— ★把两个问题拆开★

本表的输入有一半在**仓外**：各 lane worktree 的 evidence/，而那十几条 lane 正在
活跃工作。实测本轮三次相隔几分钟的生成，受检 receipt 471 -> 514 -> 517 ——
不是生成器不幂等，是**被扫的东西在动**。第一版 `--check` 因此秒红，那是把两个
不同的问题压成了一个答案：

  A 这张表的每一行是不是机械推出来的（有没有人手改过 / 依据还成不成立）
  B 自这张表生成以来，lane 里有没有出现**新**证据

`--check` 只回答 A：它按表里列出的 (evidence, target) **逐行重算**，
列值对不上、receipt 不见了、或有人手写了一行凑不出来 —— 红。
B 单独作为一行新鲜度提示打印出来（"lane 里另有 N 份未列入"），**不影响退出码**：
别人干活不该让我的闸变红。要把 B 也判红用 `--strict-fresh`。

同批规模（关三的选择依据）按**该 run 目录在盘上的绿 receipt 数**算，
不按本次扫描范围算 —— 否则同一行在全量扫描与逐行重算下会得出两个数。

本闸**不进 gate_all.sh**：它的输入在仓外，进了就是一条"别人干活就会红"的闸。

## ★那它什么时候必须手工跑？★

不进 gate_all 的代价是**没有任何东西会提醒你跑它**，于是它会慢慢变成一张没人跑、
然后没人信、最后没人看的表 —— 本仓已经吃过一模一样的亏（round 台账被写死成一份，
新一轮签核记不上账，written 在涨 proven 不涨）。所以把触发条件写死在这里：

  1. ★收录任何 evidence 之后★（`git add -f evidence/...`）—— 收进去的那些行
     `in_vcs` 要翻成 yes，不重跑表就还在说"待收"。
  2. ★动了 `scripts/fm_eq.tcl` 之后★，尤其是动了 vmucp 白名单。白名单在**每个目标
     的证明闭包里**，加一个名字就可能让某份 receipt 从"换到 main 下会 exit 3"
     变成"能过"（或者反过来）。这是这张表存在的头号理由，改完必须重判。
  3. ★动了 `scripts/sidecar/fm_native_emit.tcl`、任何 `verif/ut/*/fm_pins*.tcl`、
     `verif/allow/*.json`、`verif/dead_ref/*.json` 之后★ —— 都在关二的逐项闭包里。
  4. ★合 main / rebase 之后★：别的 lane 合进来的 rtl/ 会同时改变关一（实现在不在
     main）与关二第 (2) 项（impl 闭包字节）。实测一次合并就能让几十份 receipt
     从 NEEDS_RTL_MERGE 翻成可收，或者从可收翻成 NEEDS_RERUN。
  5. ★准备再做一轮收录之前★ —— 先跑一次 `--check` 看新鲜度那一行有多少份未列入。

跑法：`python3 scripts/gen_receipt_harvest.py` 重生成，然后 `--check` 应为绿。
只想知道"表还对不对、不想重生成"就单跑 `--check`。
"""
# ★本机是 Python 3.6：subprocess.run 没有 capture_output（3.7 才有）。★
import argparse
import collections
import hashlib
import json
import os
import re
import shutil
import subprocess
import sys
import tempfile

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
G1 = '/home/eda/xs-env/G1-canonical'
GOLDEN_RTL = os.path.join(G1, 'golden-rtl')
OUT = os.path.join(REPO, 'docs', 'receipt_harvest.tsv')
TRACER = os.path.join(REPO, 'scripts', 'fm_eq_trace.tcl')

# 本仓当前的基准 fm_shell。所有 984 份 receipt 实测都是这一版，写死是为了
# 哪天换了版本这张表会**响**，而不是静悄悄把新旧两版的结果并列。
FM_SHELL_BASELINE = 'V-2023.12-SP3'

OK_VERDICTS = ('SUCCEEDED', 'PASS', 'PASS_DEAD_REF', 'SIGNOFF_PASS')
MODULE_RE = re.compile(r'^module\s+([A-Za-z_]\w*)', re.M)
TMP_PREFIX_RE = re.compile(r'^/tmp/xsv2-proof-[^/]+/')
PACKED_RE = re.compile(r'^PACKED_MATCH: \d+ points pinned', re.M)
# ★钉点静默落空★：与 scripts/fm_verdict.py 现行判据**同一个正则对象**（import，不抄写），
# 只认行首 `Error: Unknown name`，注释/缩进回显不算。两处口径若分叉，同一份日志会在
# fm_verdict 里降为 PARTIAL、在本表里却被收成 COLLECTED —— ITTage@68bffe7f2938 就是这样：
# 250 行 FM-036，receipt 早于该判据落地仍记 SUCCEEDED，本表 chk_facts 只看 native_facts 于是放行。
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from fm_verdict import _UNKNOWN_NAME as UNKNOWN_NAME_RE  # noqa: E402


def unknown_name_count(txt):
    """fm.log 里行首 `Error: Unknown name` 的行数；日志读不到返回 None（缺失 ≠ 0）。"""
    if txt is None:
        return None
    return len(UNKNOWN_NAME_RE.findall(txt))

COLUMNS = ['target', 'golden_lines', 'impl_in_main', 'in_vcs', 'merge_dup',
           'mdup_band', 'chk_golden', 'chk_impl', 'chk_fm_eq', 'chk_pins',
           'chk_emitter', 'chk_decl', 'chk_tool', 'chk_facts', 'verdict',
           'evidence', 'rounds', 'other_rounds', 'why']

# 一个目标一行时，结论取**最强**的那一个。
VERDICT_RANK = {'COLLECTED': 0, 'SUPERSEDED': 1, 'NEEDS_RERUN': 2,
                'NEEDS_RTL_MERGE': 3, 'OK': 0}

_band_cache = {}


def mdup_band(target, merge_dup):
    # merge_dup=false 时 merge 根本没开，模型是**精确**的，带宽这个概念不适用。
    # 第一版这一列不看 merge_dup、一律打百分比，于是 InterruptFilter（merge_dup=false，
    # 模型精确）显示成 `85.6%/wide` —— 读表的人会读成"这行模型近乎无信息"，
    # 恰好读反。带宽只有在 merge 真的开着的时候才有意义。
    if merge_dup == 'false':
        return 'exact'
    return _mdup_band_pct(target)


def _mdup_band_pct(target):
    """merge_dup=true 时，passing 模型的**不确定带宽**有多宽。

    ★这一列不参与任何判决★，本表八项判据全是 sha256 与差分调用序列，与 passing
    数无关。它在这里是给读表的人用的：merge 只合并**寄存器**导出的比较点，
    顶层 output 端口一个不少，所以 merge_dup=true 时模型的偏差上界就是 regs，
    带宽 = regs / (regs + outs)。

      NewDispatch  regs 358  / outs 51563 -> 0.7%   模型仍然很有用
      IBuffer      regs 7079 / outs 1213  -> 85%    这条带近乎无信息

    "merge_dup=true 就一律模型不适用"太钝：带窄的时候模型照样是最便宜的探针，
    只有带宽的那些才真判不了。>30% 标 wide。
    """
    if target in _band_cache:
        return _band_cache[target]
    v = 'n/a'
    try:
        sys.path.insert(0, os.path.join(REPO, 'scripts'))
        from fm_passing_model import model as _model
        r = _model(target, [])
        tot = (r['regs'] or 0) + (r['outs'] or 0)
        if tot:
            pct = 100.0 * r['regs'] / tot
            v = '%.1f%%%s' % (pct, '/wide' if pct > 30 else '')
    except Exception:
        v = 'n/a'
    _band_cache[target] = v
    return v


def read_fm_log(d):
    """读这份 receipt 的 fm.log —— ★压缩过的也要读★。

    2026-09-20 实测踩到：仓里有 416 份 receipt 的日志是 `fm.log.gz`（收录时压过），
    而第一版只 open('fm.log')。后果有两个，方向相反，都不好：

      · chk_tool 取不到版本行 -> 判 DIFFER。SyncDataModuleTemplate 三兄弟就是这么被
        误判成"工具版本不符"的 —— **假红**。
      · ★更糟的是 packed 的那一侧是假绿★：用没用 FM_FIELD_MAP 是从 fm.log 里
        认 `^PACKED_MATCH` 认出来的，日志读不到就一律当"没用过"，
        于是一份真的走了 field map 路径的 receipt 会被判成闭包完整。
        **fail-open**，正是本表存在的理由所反对的那种。

    读不到日志时返回 None，让调用方把"没有日志"与"日志里没有"区分开 ——
    缺失和否定又一次不能长成一个样。
    """
    plain = os.path.join(d, 'fm.log')
    if os.path.isfile(plain):
        with open(plain, errors='replace') as f:
            return f.read()
    gz = plain + '.gz'
    if os.path.isfile(gz):
        import gzip
        try:
            with gzip.open(gz, 'rt', errors='replace') as f:
                return f.read()
        except Exception:
            return None
    return None


def sidecar_path(r, arch, tmpdir=None):
    """sidecar 里那份字节快照的**可读路径** —— ★压缩过的也要读★。

    2026-09-21 实测踩到：`script_closure.list` 记的是运行时的原名
    （`sourced_000_fm_eq.tcl`），而 lane 收录时会把 sidecar 里的 .tcl 压成 .gz。
    于是 `chk_fm_eq` / `chk_pins` / `chk_emitter` 三处按原名 open，
    在**任何已压缩的 receipt 上**直接抛 FileNotFoundError，
    `gen_receipt_harvest.py --check` 整条崩掉（实测：
    wt-dbgfix 的 EntriesAluBrhJmpI2fVsetriwiVsetriwvfI2v）。

    ★这是 read_fm_log 那条教训的同一条，只是换了个读者★：
    同一个文件名在"跑的时候"和"收录之后"不是同一个存在形式，
    每一个读 sidecar 的地方都得自己处理，漏一个就是一处崩或一处假判。
    崩掉比假判好（fail-closed），但崩掉会让整张表算不出来，一样得修。

    读不到返回 None —— 让调用方把"没有这份快照"和"快照里没有"分开，
    缺失和否定不许长成一个样。
    """
    plain = os.path.join(r['dir'], 'sidecar', arch)
    if os.path.isfile(plain):
        return plain
    gz = plain + '.gz'
    if os.path.isfile(gz):
        import gzip
        import tempfile
        d = tmpdir or tempfile.mkdtemp(prefix='harvest_sidecar_')
        if not os.path.isdir(d):
            os.makedirs(d)
        out = os.path.join(d, os.path.basename(arch))
        try:
            with gzip.open(gz, 'rb') as fsrc, open(out, 'wb') as fdst:
                fdst.write(fsrc.read())
        except Exception:
            return None
        return out
    return None


def tcl_exec_text(path):
    """去掉 Tcl 整行注释与 `;#` 行尾注释，只留**可执行文本**。

    为什么需要它：判"这份钉点文件有没有真的调用某个动词"，不能拿整文件做子串匹配。
    实测反例：verif/ut/IBuffer/fm_pins.tcl 的注释里**专门写着** find_cells 不可用
    （"safe interp 里没有 find_cells"），整文件 grep 会把这份判成"用了 find_cells"，
    恰好判反。注释不是代码，判据得先把注释摘掉。
    """
    out = []
    try:
        with open(path, errors='replace') as f:
            for l in f:
                s = l.strip()
                if not s or s.startswith('#'):
                    continue
                out.append(re.sub(r';\s*#.*$', '', s))
    except Exception:
        return ''
    return '\n'.join(out)


# ----------------------------------------------------------------- helpers ---
def run(args, cwd=None, env=None):
    p = subprocess.run(args, cwd=cwd, env=env,
                       stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    return p.returncode, p.stdout.decode('utf-8', 'replace')


_shacache = {}


def sha_file(path):
    if path in _shacache:
        return _shacache[path]
    h = hashlib.sha256()
    try:
        with open(path, 'rb') as f:
            for b in iter(lambda: f.read(1 << 20), b''):
                h.update(b)
        v = h.hexdigest()
    except Exception:
        v = None
    _shacache[path] = v
    return v


def repo_rel(src):
    """sidecar 记的源路径是跑证明时那棵临时树里的绝对路径，去掉前缀还原成仓内相对路径。"""
    return TMP_PREFIX_RE.sub('', src)


def golden_lines():
    """{module: 行数}，口径与 scripts/rewrite_coverage.py 的 golden_modules() 一致。"""
    out = {}
    for fn in sorted(os.listdir(GOLDEN_RTL)):
        if not (fn.endswith('.sv') or fn.endswith('.v')):
            continue
        with open(os.path.join(GOLDEN_RTL, fn), errors='replace') as f:
            txt = f.read()
        n = len(txt.splitlines())
        for m in MODULE_RE.finditer(txt):
            out[m.group(1)] = n
    return out


def rtl_modules():
    """main 的 rtl/ 里声明了哪些 module（written 口径，与 rewrite_coverage 同源）。"""
    out = set()
    for root, _dirs, files in os.walk(os.path.join(REPO, 'rtl')):
        for fn in files:
            if not fn.endswith('.sv'):
                continue
            with open(os.path.join(root, fn), errors='replace') as f:
                out |= set(MODULE_RE.findall(f.read()))
    return out


def ledger_green():
    """已提交台账里已有绿判决的目标（口径抄 scripts/rewrite_coverage.py:proven_modules）。"""
    ok = set()
    docs = os.path.join(REPO, 'docs')
    for fn in sorted(os.listdir(docs)):
        if not (fn.startswith('fm_round_') and fn.endswith('.tsv')):
            continue
        with open(os.path.join(docs, fn), errors='replace') as f:
            for l in f:
                if l.startswith('#') or l.startswith('target'):
                    continue
                c = l.rstrip('\n').split('\t')
                if len(c) > 1 and c[1] in ('SUCCEEDED', 'PASS_DEAD_REF'):
                    ok.add(c[0])
    led = os.path.join(docs, 'fastlane_ledger.tsv')
    if os.path.exists(led):
        with open(led, errors='replace') as f:
            for l in f:
                if l.startswith('#'):
                    continue
                c = l.rstrip('\n').split('\t')
                if len(c) > 1 and c[1] in ('WORKING_PASS', 'WORKING_PASS_DEAD_REF'):
                    ok.add(c[0])
    if not ok:
        raise SystemExit('ledger_green: 台账里一个绿判决都读不出 —— 拒绝按 0 继续')
    return ok


# ------------------------------------------------------------- collection ---
def lane_worktrees():
    """除本仓与 main worktree 之外的 worktree。

    main worktree（xs-v2-sv）自己的 evidence/ 也有未提交的 receipt，但实测那 515 份
    **一个新目标都不带**（全部已在台账里绿），而且用的是老一版 sidecar emitter。
    本表的口径是「散落在各 lane worktree 里的证据」，故按来源排除，不混进同一张表。
    """
    _, out = run(['git', 'worktree', 'list'], REPO)
    wts = [l.split()[0] for l in out.splitlines() if l.strip()]
    main_wt = os.path.abspath(wts[0]) if wts else None
    res = []
    for w in wts:
        a = os.path.abspath(w)
        if a == os.path.abspath(REPO) or a == main_wt:
            continue
        # run_proof.sh 的临时证明 worktree（mktemp 模板 xsv2-proof-XXXXXX，跑完即 remove）不是 lane：
        # 它里面的 evidence 会写回发起 lane，收它只会让表依赖"生成那一刻哪个证明恰好在跑"（2026-10-14）。
        if os.path.basename(a).startswith('xsv2-proof-'):
            continue
        res.append(w)
    return res


def tracked_receipts():
    """版本库里**逐个 (run, target)** 已跟踪的 receipt。

    ★不能按 run 目录粒度算★（2026-09-20 实测，这是我自己造出来的一次静默低计）：
    收录是**按 target 子目录** `git add -f evidence/<run>/<target>` 做的（必须如此 ——
    同一个 run 目录里常常混着前提已变的轮次，整目录收会把它们一起带进台账）。
    于是一个 run 目录可以是**部分跟踪**的：73 个 tracked run 里就有这种。

    第一版 tracked_runs() 只收 run 名字，判 in_vcs 时写 `rundir_name in tracked` ——
    只要同 run 里**任何一个别的 target** 被收过，这个 target 就被标成"已在版本库里"。
    实测 20 行被这样误标，其中 DuplicatedTagArray / ICacheMetaArray /
    ITTageTable{,_1..4} / TageBTable 的 receipt **确实没进 git**，而表说它们
    `in_vcs=yes COLLECTED` —— 读起来是"没事可做"。

    ★但必须说准：这一次没有因此少算覆盖。★
    我第一反应是"3,529 golden 行被我自己藏了"，去查才发现错在**我只 grep 了
    docs/fm_round_20260917.tsv 一份台账**。proven 的口径是 glob `fm_round_*.tsv`
    加 fastlane —— 这 8 个在 `fm_round_20260914.tsv` 里就已经是 SUCCEEDED，
    `rewrite_coverage.proven_modules()` 认它们。所以缺陷真实、后果为零。
    （"这条洞存不存在"与"这条洞有没有实际后果"是两件事，两件都要报，
      而且**别把没发生的后果写成发生了** —— 虚高的坏消息一样会传下去。）

    判据：`git ls-files evidence/*/*/receipt.json` 逐个取 (run, target)。
    """
    _, out = run(['git', 'ls-files', 'evidence/*/*/receipt.json'], REPO)
    res = set()
    for p in out.splitlines():
        q = p.split('/')
        if len(q) >= 4:
            res.add((q[1], q[2]))
    return res


def green_of(j):
    v = j.get('verdict') or (j.get('verdict_detail') or {}).get('native')
    return v if v in OK_VERDICTS else None


def collect(only=None):
    """扫各 lane worktree 的绿 receipt。

    `only` 给一组 (evidence, target)（evidence = "<worktree basename>:<run>"）时只收这些
    —— `--check` 用它把扫描范围钉死在表里已列出的行上，使逐行重算不受别的 lane
    正在新产出的证据影响（那是新鲜度问题，不是本表对不对的问题）。
    """
    tracked = tracked_receipts()
    recs = []
    # ★按 (run, target) 去重★。两类重复都真实存在，都不该在表里各占一行：
    #   · 已进版本库的 evidence/<run> 是**被 git 跟踪的文件**，于是每一个 worktree
    #     的工作树里都有一份完整拷贝 —— 不去重的话 336 份 receipt 会被 35 个
    #     worktree 各数一遍，实测把表撑成 10450 行（第一版就是这么炸的）。
    #   · lane 之间互相 cherry-pick / 复制 evidence 时，同一个 run 目录会同时出现在
    #     两个 worktree（实测 LoadQueueReplay 的 75e1d8be8148 就在 wt-lqr3 与
    #     xsv2-genidem-zj3zjxny 各一份），那是同一份证据，不是两份。
    # 取 worktree 名字排序的第一个，保证结果与扫描顺序无关。
    seen = {}
    # ★已进版本库的 receipt 先从本仓收，provenance 记 `vcs:<run>`★（2026-10-14）
    # 原来已跟踪的 receipt 也经 lane worktree 发现，evidence 列记"名字排序第一个"的 worktree。
    # run_proof 的临时证明 worktree（tmp-*/xsv2-proof-*）排在 wt-* 之前，于是 1598 行全部记成
    # `xsv2-proof-Xws7NB:<run>`；该临时 worktree 一被回收，--check 按列出的键重算就只找回 318 行
    # ——表的内容取决于生成那一刻碰巧存在哪些临时 worktree，干净 clone 上不可复现。
    # 已跟踪的证据本来就在仓里，provenance 就是版本库本身；lane worktree 只负责发现**未跟踪**的。
    sources = [(str(REPO), 'vcs', True)] + [(wt, os.path.basename(wt), False)
                                             for wt in sorted(lane_worktrees())]
    for wt, label, tracked_only in sources:
        ev = os.path.join(wt, 'evidence')
        if not os.path.isdir(ev):
            continue
        for rundir_name in sorted(os.listdir(ev)):
            rundir = os.path.join(ev, rundir_name)
            if not os.path.isdir(rundir):
                continue
            ev_id = '%s:%s' % (label, rundir_name)
            for tgt in sorted(os.listdir(rundir)):
                if (rundir_name, tgt) in seen:
                    continue
                if tracked_only and (rundir_name, tgt) not in tracked:
                    continue
                if only is not None and (ev_id, tgt) not in only:
                    continue
                d = os.path.join(rundir, tgt)
                # ★已进版本库的，复核一律读仓内那份★（2026-09-21）
                # 发现范围仍是 lane worktree（本表的口径没变），但**读哪一份字节**
                # 是另一回事。第一版用"worktree 名字排序取第一个"保证了确定性，
                # 却没保证**可复现性**：实测 542 行里 500 行 in_vcs=yes，
                # 而它们的复核路径全部指向 wt-* —— lane worktree 是临时的，
                # 合并后就会被 git worktree remove 掉，届时这 500 张证书
                # 从干净 clone 出发一张都复核不了。
                # 确定性和可复现性是两件事，前者当时满足了，后者一直没有。
                # provenance（evidence 列的 wt-xxx:run）保持不动 —— 它记的是
                # "这份证据当初从哪来"，那仍然是真的，只是不再是读取路径。
                if (rundir_name, tgt) in tracked:
                    _repo_d = os.path.join(REPO, 'evidence', rundir_name, tgt)
                    if os.path.isfile(os.path.join(_repo_d, 'receipt.json')):
                        d = _repo_d
                rc = os.path.join(d, 'receipt.json')
                if not os.path.isfile(rc):
                    continue
                try:
                    with open(rc) as f:
                        j = json.load(f)
                except Exception:
                    continue
                v = green_of(j)
                if not v:
                    continue
                closure = []
                scl = os.path.join(d, 'sidecar', 'script_closure.list')
                if os.path.isfile(scl):
                    with open(scl, errors='replace') as f:
                        for l in f:
                            p = l.rstrip('\n').split('\t')
                            if len(p) >= 3:
                                closure.append({'src': p[0], 'arch': p[1], 'sha': p[2]})
                ver, packed, logged = None, False, False
                txt = read_fm_log(d)
                unknown_name = unknown_name_count(txt)
                if txt is not None:
                    logged = True
                    m = re.search(r'Version (\S+) for linux64', txt)
                    ver = m.group(1) if m else None
                    packed = bool(PACKED_RE.search(txt))
                pc = j.get('proof_config') or {}
                av = pc.get('entry_appvars_readback') or {}
                nf = j.get('native_facts') or {}
                vd = j.get('verdict_detail') or {}
                seen[(rundir_name, tgt)] = ev_id
                recs.append({
                    'wt': wt, 'run': rundir_name, 'target': tgt, 'dir': d,
                    'ev_id': ev_id, 'in_vcs': (rundir_name, tgt) in tracked,
                    'verdict': v, 'mtime': os.path.getmtime(rc),
                    'commit': j.get('impl_commit'),
                    'dirty': bool(j.get('impl_worktree_dirty')),
                    'provisional': bool(j.get('provisional')),
                    'g1id': j.get('g1_canonical_id'),
                    'golden_closure': j.get('golden_closure') or [],
                    'impl_closure': j.get('impl_closure') or [],
                    'declarations': pc.get('declarations') or {},
                    'fm_mode': pc.get('fm_mode') or '',
                    'vmucp': str(pc.get('verify_matched_unread_compare_points') or 'false'),
                    'merge_dup': str(av.get('verification_merge_duplicated_registers') or 'true'),
                    'interface_only': str(av.get('hdlin_interface_only') or ''),
                    'script_closure': closure,
                    'fm_ver': ver, 'packed': packed, 'logged': logged,
                    'unknown_name': unknown_name,
                    'stats': nf.get('stats') or {},
                    'unmatched': nf.get('unmatched') or {},
                    'quals': nf.get('qualifications') or {},
                    'const_reg': vd.get('constant_reg'),
                    'const_toggle': bool(vd.get('constant_reg_toggle_assumed')),
                    'objects': nf.get('objects') or {},
                })
    return recs


def chk_facts(r):
    """不信 receipt 的 verdict 字符串，直接看 native_facts 的数。

    为什么不信：verdict 是**别的脚本在别的时候**算出来的一个词，而本表的整个用途
    就是"别把不同前提下产出的结论并列"。一个词不带前提，数带。这里复核的是与
    模式无关的硬条件；assembly 模式的黑盒集合另由 chk_decl 的 verif/allow/*.json
    字节比对把守，不在这里重复判。
    """
    s, u, q = r['stats'], r['unmatched'], r['quals']
    bad = []
    if not s:
        return 'DIFFER', 'receipt 没有 native_facts.stats'
    if not s.get('passing'):
        bad.append('passing=%r' % s.get('passing'))
    for k in ('failing', 'unverified', 'aborted', 'unread_notcompared'):
        if s.get(k):
            bad.append('%s=%s' % (k, s[k]))

    # ★PASS_DEAD_REF 的 unread_ref 不是脏，是被声明过的 golden-only cone-dead 位★
    # 第一版这里一刀切"六项 unmatched 全 0"，把 Fence / Ftq / RegCache / SourceB /
    # FTBBank / TageTable_* 全判成 native_facts 不干净 —— 而这些目标**已经在版本库里、
    # 台账里也已经绿**。判据与全仓已接受的裁定冲突时，先怀疑判据：
    # PASS_DEAD_REF 的判定依据本就是"观测集合与 verif/dead_ref/<top>.json 精确相等"。
    # 所以这里不是放宽成"允许 unread"，而是换成**更紧**的一条：必须有声明文件，
    # 且声明里的 observed_points 与本次实测逐数相等。声明文件的字节由 chk_decl 把守。
    dead_ok = False
    if r['verdict'] == 'PASS_DEAD_REF':
        decl = (r['declarations'] or {}).get('dead_ref')
        obs = sorted(set((r['objects'].get('unmatched_unread_ref') or []) +
                         (r['objects'].get('unmatched_unread_impl') or [])))
        if not decl:
            bad.append('PASS_DEAD_REF 却没有 dead_ref 声明')
        else:
            want = None
            try:
                with open(os.path.join(REPO, decl['path'])) as f:
                    dj = json.load(f)
                want = sorted({e.get('ref_path') or e.get('impl_path')
                               for e in dj.get('entries') or []})
                # observed_points 是可选字段（实测 FTBBank / L2TlbPrefetch 就没有），
                # 有就一并对上，别让"缺字段"和"对不上"长成一个样。
                op = dj.get('observed_points')
                if op is not None and op != len(want):
                    bad.append('dead_ref 声明自相矛盾: observed_points=%s 但 entries=%d'
                               % (op, len(want)))
            except Exception as e:
                # ★消息里不许带绝对路径★：OSError 的 str() 含 REPO 绝对路径，而 REPO 随
                # worktree 变 —— 同一行在 wt-a 生成、在 wt-b / main 上 --check 必然 DRIFT
                # （实测 main 上这 7 行写的是 /home/eda/xs-env/wt-gatefix2/...）。判据不变，只去位置。
                bad.append('dead_ref 声明读不出: %s' % str(e).replace(REPO.rstrip('/') + '/', ''))
            if want is None:
                pass
            elif want != obs:
                # ★逐点比集合，不是比个数★：个数相同但点不同，正是这条判据该拦的东西。
                extra = [p for p in obs if p not in set(want)]
                miss = [p for p in want if p not in set(obs)]
                bad.append('dead_ref 观测集合与声明不等（实测多 %d / 声明多 %d，如 %s）'
                           % (len(extra), len(miss), (extra or miss)[:1]))
            elif not bad:
                dead_ok = True
    for k, v in sorted(u.items()):
        if not v:
            continue
        if dead_ok and k in ('unread_ref', 'unread_impl'):
            continue
        bad.append('unmatched.%s=%s' % (k, v))
    if q.get('dont_verify_objects'):
        bad.append('dont_verify=%d' % len(q['dont_verify_objects']))
    if q.get('relaxed_appvars'):
        bad.append('relaxed_appvars=%s' % q['relaxed_appvars'])
    # ★native_facts 数干净也不够★：钉点落在不存在的名字上时 FM 只写一行行首
    # `Error: Unknown name ... (FM-036)`、不抛异常，native 照样 SUCCEEDED。
    # 与 fm_verdict 同口径：>0 即不得收。日志缺失（None）不在这里判 —— chk_tool 已对
    # "没有日志"判 UNKNOWN（同样落 NEEDS_RERUN），缺失与否定不长成一个样。
    if r.get('unknown_name'):
        bad.append('fm.log 行首 Error: Unknown name=%d（钉点/命令落在不存在的对象上，静默未生效）'
                   % r['unknown_name'])
    if bad:
        return 'DIFFER', 'native_facts 不干净: %s' % ', '.join(bad[:4])
    return 'same', ''


# ------------------------------------------------------- the seven checks ---
def g1_current_id():
    """G1 基线标识：优先读 canonical 目录里落地的 id 文件，读不到则回 None。"""
    for fn in ('CANONICAL_ID', 'canonical_id.txt', 'G1_ID'):
        p = os.path.join(G1, fn)
        if os.path.exists(p):
            with open(p, errors='replace') as f:
                return f.read().strip()
    return None


def chk_golden(r, cur_id):
    """golden 侧：基线标识 + 每个 golden 文件的字节。"""
    bad = []
    for e in r['golden_closure'] + [x for x in r['impl_closure'] if x.get('kind') == 'golden']:
        p = os.path.join(G1, e['path'])
        if sha_file(p) != e['sha256']:
            bad.append(e['path'])
    if bad:
        return 'DIFFER', 'golden 字节已变: %s' % ','.join(sorted(set(bad))[:3])
    if cur_id and r['g1id'] and cur_id != r['g1id']:
        return 'DIFFER', 'g1_canonical_id 不符'
    return 'same', ''


def chk_impl(r, rtl_mods):
    """impl 侧：每个 kind=repo 文件在 main 当前字节下是否同一份。"""
    missing, differ = [], []
    for e in r['impl_closure']:
        if e.get('kind') != 'repo':
            continue
        p = os.path.join(REPO, e['path'])
        if not os.path.exists(p):
            missing.append(e['path'])
        elif sha_file(p) != e['sha256']:
            differ.append(e['path'])
    if missing:
        return 'MISSING', 'main 里没有: %s' % ','.join(sorted(missing)[:3])
    if differ:
        return 'DIFFER', 'main 里字节已变: %s' % ','.join(sorted(differ)[:3])
    return 'same', ''


def chk_decl(r):
    bad = []
    for _k, v in sorted(r['declarations'].items()):
        p = os.path.join(REPO, v['path'])
        if sha_file(p) != v['sha256']:
            bad.append(v['path'])
    if bad:
        return 'DIFFER', '声明文件已变: %s' % ','.join(bad[:2])
    return ('same' if r['declarations'] else 'none'), ''


def chk_tool(r):
    # ★没有日志 != 版本不符★：前者是"我查不了"，后者是"我查了且不对"。
    # 压缩日志由 read_fm_log 处理；连 .gz 都没有才是真的查不了，那也不能放过 ——
    # packed（用没用 field map）同样只能从日志认，没日志就等于闭包有一块看不见。
    if not r['logged']:
        return 'UNKNOWN', 'receipt 没有 fm.log(.gz)，工具版本与 field map 使用情况都查不了'
    if r['fm_ver'] == FM_SHELL_BASELINE:
        return 'same', ''
    if r['fm_ver'] is None:
        return 'UNKNOWN', 'fm.log 里没有版本行，查不到 fm_shell 版本'
    return 'DIFFER', 'fm_shell %s != 基准 %s' % (r['fm_ver'], FM_SHELL_BASELINE)


def _arch(r, needle):
    return [e for e in r['script_closure'] if needle in e['arch']]


def chk_emitter(r):
    """sidecar emitter。

    lane 侧实测只有两版：与 main 逐字节相同的那版，和只差**一行**的那版 ——
    main 在 sidecar_pin_source 的 safe interp 白名单里多 alias 了一个 `find_cells`
    （只读查询动词，不建/不拆比较点、不放宽比较、不动 appvar）。
    多暴露一个**没被用到**的只读别名不改变任何行为，判据不是"我觉得它无关"，
    而是去看这份 receipt 的钉点文件**有没有调用 find_cells**：没有调用，
    这条 alias 在本次运行里根本没被取用；有调用，老 emitter 下它会失败，
    两边不是同一件事，必须重跑。没有钉点文件时 sidecar_pin_source 压根没被调用。
    """
    es = _arch(r, 'fm_native_emit')
    if not es:
        return 'UNKNOWN', 'receipt 没有 emitter 字节快照'
    cur = sha_file(os.path.join(REPO, 'scripts', 'sidecar', 'fm_native_emit.tcl'))
    if es[0]['sha'] == cur:
        return 'same', ''
    for p in _arch(r, 'fm_pins'):
        _sp = sidecar_path(r, p['arch'])
        if _sp is None:
            return 'UNKNOWN', 'receipt 的钉点字节快照读不到: %s' % p['arch']
        txt = tcl_exec_text(_sp)
        if re.search(r'\bfind_cells\b', txt):
            return 'DIFFER', 'emitter 差在 find_cells alias，而钉点文件的可执行文本真的调用了它'
    return 'inert', 'emitter 仅差 find_cells alias；本次钉点可执行文本里没有它'


def _pins_trace(path, top, workdir):
    out = os.path.join(workdir, 'pins.txt')
    if os.path.exists(out):
        os.remove(out)
    env = dict(os.environ)
    env['FM_PINS_TRACE_OUT'] = out
    env['FM_TOP'] = top
    run(['tclsh', os.path.join(REPO, 'scripts', 'fm_pins_trace.tcl'), path],
        cwd=workdir, env=env)
    try:
        with open(out, errors='replace') as f:
            return f.read()
    except Exception:
        return '<NO TRACE>'


def chk_pins(r, workdir):
    """关二 (4)：钉点文件。

    ★字节不同 != 钉的点不同★。本仓真发生过一次"字节变了但钉的点一个没变"的改动
    （OthersEntry 家族的空守卫修复，见 verif/ut/OthersEntry_common/PIN_GUARD_FIX.md），
    当时那条 lane 用"把 set_user_match 换成记参数的桩、真跑两版比调用序列"证明了
    18/18 相同。第一版这里只比 sha256，等于把那份已经做完的论证当没看见，
    对 18 个**已经收进版本库、已计进 proven** 的目标报假红。

    所以：字节相同 -> same；字节不同 -> 用同一套差分手法跑一遍
    （scripts/fm_pins_trace.tcl），调用序列逐字节相同 -> bridged，否则 DIFFER。
    """
    pins = _arch(r, 'fm_pins')
    if not pins:
        return 'none', ''
    missing, differ, bridged = [], [], []
    for e in pins:
        rel = repo_rel(e['src'])
        cur = os.path.join(REPO, rel)
        if not os.path.exists(cur):
            missing.append(rel)
            continue
        if sha_file(cur) == e['sha']:
            continue
        old = sidecar_path(r, e['arch'], os.path.join(workdir, 'snap'))
        if old is None:
            differ.append(rel + '(快照读不到)')
            continue
        a = _pins_trace(cur, r['target'], os.path.join(workdir, 'a'))
        b = _pins_trace(old, r['target'], os.path.join(workdir, 'b'))
        if a != '<NO TRACE>' and a == b:
            bridged.append(rel)
        else:
            differ.append(rel)
    if missing:
        return 'MISSING', 'main 里没有钉点文件: %s' % ','.join(missing[:2])
    if differ:
        return 'DIFFER', '钉点文件已变且调用序列也变了: %s' % ','.join(differ[:2])
    if bridged:
        return 'bridged', ('钉点文件字节已变但**调用序列逐字节相同**'
                           '（scripts/fm_pins_trace.tcl 差分跑）: %s' % ','.join(bridged[:2]))
    return 'same', ''


# ---- 关二 (3): fm_eq 差分调用序列 -------------------------------------------
_trace_cache = {}


def _trace(fm_eq_path, r, workdir):
    key = (sha_file(fm_eq_path), r['target'], r['fm_mode'], r['vmucp'],
           r['merge_dup'], r['interface_only'])
    if key in _trace_cache:
        return _trace_cache[key]
    out = os.path.join(workdir, 'trace.txt')
    if os.path.exists(out):
        os.remove(out)
    env = dict(os.environ)
    env.update({
        'FM_TRACE_OUT': out,
        'FM_TOP': r['target'],
        'FM_REF_SRCS': 'REF.sv',
        'FM_IMPL_SRCS': 'IMPL.sv',
        'FM_MODE': r['fm_mode'],
        'FM_VERIFY_MATCHED_UNREAD_COMPARE_POINTS': r['vmucp'],
        'FM_MERGE_DUP': r['merge_dup'],
    })
    for k in ('FM_SIDECAR_OUT', 'FM_PIN_TCL', 'FM_PIN_PRE_TCL',
              'FM_FIELD_MAP', 'FM_FAILING_LIMIT', 'FM_INTERFACE_ONLY'):
        env.pop(k, None)
    if r['interface_only']:
        env['FM_INTERFACE_ONLY'] = r['interface_only']
    # ★被测的 fm_eq.tcl 必须躺在一棵 <root>/scripts/ 里★（2026-09-20）：
    # 拆分 per-target 数据之后，fm_eq.tcl 按 `info script` 的上两级去找
    # verif/fm_target_config/。receipt 里的历史快照住在 evidence/**/sidecar/ 下，
    # 直接喂给 tracer 会让**拆分后**那一版找不到配置目录而 exit 3 ——
    # 那样两版必然 DIFFER，是保守方向（不会误判成 same），但判据就废了。
    # 所以两版都搭一棵最小树再跑：差异只剩 fm_eq.tcl 本身。
    tree = os.path.join(workdir, 'tree')
    if not os.path.isdir(os.path.join(tree, 'scripts')):
        os.makedirs(os.path.join(tree, 'scripts'))
    staged = os.path.join(tree, 'scripts', 'fm_eq.tcl')
    shutil.copyfile(fm_eq_path, staged)
    link = os.path.join(tree, 'verif')
    if not os.path.exists(link):
        os.symlink(os.path.join(REPO, 'verif'), link)
    run(['tclsh', TRACER, staged], cwd=workdir, env=env)
    try:
        with open(out, errors='replace') as f:
            txt = f.read()
    except Exception:
        txt = '<NO TRACE>'
    _trace_cache[key] = txt
    return txt


def chk_fm_eq(r, workdir):
    """★本关重点★ 不比 sha、不读 diff，跑两版比实际发出的 FM 命令序列。

    ★本判据说不了话的地方，要自己说出来★（2026-09-20）：
    tracer 跑的时候 FM_FIELD_MAP 是**不设**的（见 _trace() 里 env.pop），
    于是 `match_packed_payload` 在第一行就 return，**整条 field map 路径没被走到**。
    main 在 cb2c646d 修那个洞时改的正是这条路径里的代码。也就是说，对一份
    真的用了 field map 的 receipt，这套差分跑出来的 `trace_equal`
    **不覆盖它实际走过的那一段**。

    这类 receipt 目前也会被 judge() 里的 `packed` 分支判成不可收，所以结论上
    没出错 —— 但那是**靠另一条判据兜住**。判据之间这种隐式依赖正是会烂掉的东西：
    哪天 packed 那条被放宽，这里就会开始静默放行。所以这里自己 fail-closed，
    不把"我没测到"说成"我测了，相同"。
    """
    es = _arch(r, 'fm_eq.tcl')
    if not es:
        return 'UNKNOWN', 'receipt 没有 fm_eq 字节快照'
    cur = os.path.join(REPO, 'scripts', 'fm_eq.tcl')
    if es[0]['sha'] == sha_file(cur):
        return 'same', ''
    if r['packed']:
        return 'NOT_MODELLED', ('fm_eq 差分跑不覆盖 field map 路径'
                               '（tracer 不设 FM_FIELD_MAP，match_packed_payload 首行即 return），'
                               '而本次证明真的走了那条路径')
    old = sidecar_path(r, es[0]['arch'], os.path.join(workdir, 'snap'))
    if old is None:
        return 'UNKNOWN', 'receipt 的 fm_eq 字节快照读不到: %s' % es[0]['arch']
    a = _trace(cur, r, os.path.join(workdir, 'a'))
    b = _trace(old, r, os.path.join(workdir, 'b'))
    if a == '<NO TRACE>' or b == '<NO TRACE>':
        return 'DIFFER', 'fm_eq 差分跑不出调用序列'
    if a == b:
        return 'trace_equal', ''
    # 差在哪一句，写进依据，别只说"不一样"
    la, lb = a.splitlines(), b.splitlines()
    first = next((i for i in range(max(len(la), len(lb)))
                  if (la[i] if i < len(la) else None) != (lb[i] if i < len(lb) else None)), 0)
    return 'DIFFER', 'fm_eq 调用序列第 %d 句起不同 (main=%r 旧=%r)' % (
        first + 1,
        la[first][:60] if first < len(la) else '<end>',
        lb[first][:60] if first < len(lb) else '<end>')


# ------------------------------------------------------------- the verdict ---
def judge(r, rtl_mods, cur_id, workdir):
    checks = collections.OrderedDict()
    why = []

    if r['dirty']:
        why.append('receipt 标了 impl_worktree_dirty，跑的是工作树、记的是 HEAD')
    if r['provisional']:
        why.append('receipt 标了 provisional')
    if r['packed']:
        # ★证据 schema 的一个洞，不是这份 receipt 的错★
        # match_packed_payload 用 `open` 读 $env(FM_FIELD_MAP)，而 sidecar 的字节快照
        # 是挂在 `source` 上的（sidecar_register_script / sidecar_pin_source），
        # 于是这个文件**一个字节都没进 script_closure.list，也没进 receipt**。
        # 实测 NewPipelineConnectPipe_29：fm.log 里 `PACKED_MATCH: 1023 points pinned`，
        # 1023 个 set_user_match 来自一份字节没留档的文件。
        # 那 1023 个钉点是不是还和今天的 field map 一样，**从 receipt 里看不出来**，
        # 所以这类一律判不可收；要收得先把 FM_FIELD_MAP 纳入字节快照再重出。
        why.append('用了 FM_FIELD_MAP（packed payload 钉点）：它经 open 读入而非 source，'
                   '不在 sidecar 字节快照里，闭包缺这一项无法复核')

    checks['chk_golden'], w = chk_golden(r, cur_id)
    if w:
        why.append(w)
    checks['chk_impl'], w = chk_impl(r, rtl_mods)
    if w:
        why.append(w)
    checks['chk_fm_eq'], w = chk_fm_eq(r, workdir)
    if w:
        why.append(w)
    checks['chk_pins'], w = chk_pins(r, workdir)
    if w:
        why.append(w)
    checks['chk_emitter'], w = chk_emitter(r)
    if w:
        why.append(w)
    checks['chk_decl'], w = chk_decl(r)
    if w:
        why.append(w)
    checks['chk_tool'], w = chk_tool(r)
    if w:
        why.append(w)
    checks['chk_facts'], w = chk_facts(r)
    if w:
        why.append(w)
    # 不是闸，是随行的前提标注：FM 对"被判常数的寄存器"假设其可翻转。两侧都被判
    # 常数、常数值不同、且该点无可观测扇出时，差异不会在任何比较点暴露。
    # scripts/fm_verdict.py 明确选择"把数字亮出来而不是自己发明一条闸"（见其 296-304 行），
    # 本表沿用同一裁定：不据此改判，但收进来的行必须自带这句话。
    if r['const_toggle'] and r['const_reg']:
        why.append('前提标注: constant_reg=%s 且 FM 假设常数寄存器可翻转（全仓既有裁定，不据此改判）'
                   % r['const_reg'])

    impl_in_main = 'yes' if r['target'] in rtl_mods else 'no'
    if checks['chk_impl'] == 'MISSING' or impl_in_main == 'no':
        verdict = 'NEEDS_RTL_MERGE'
        if impl_in_main == 'no' and checks['chk_impl'] != 'MISSING':
            why.append('rtl/ 里没有 module %s，收了也不进 proven 口径' % r['target'])
    elif (r['dirty'] or r['provisional'] or r['packed']
          or any(v in ('DIFFER', 'MISSING', 'UNKNOWN', 'NOT_MODELLED')
                 for v in checks.values())):
        verdict = 'NEEDS_RERUN'
    else:
        verdict = 'OK'          # 待关三定夺：COLLECTED 还是 SUPERSEDED
    return checks, impl_in_main, verdict, why


_batch_cache = {}


def batch_size(r):
    """该 run 目录在**盘上**有多少份绿 receipt。

    ★不按本次扫描范围算★：--check 逐行重算时扫描范围被钉死在表里的行上，
    若按扫描范围算，同一行在全量生成与逐行重算下会得出两个数，--check 必然假红。
    """
    key = (r['wt'], r['run'])
    if key in _batch_cache:
        return _batch_cache[key]
    rundir = os.path.join(r['wt'], 'evidence', r['run'])
    n = 0
    try:
        for tgt in os.listdir(rundir):
            rc = os.path.join(rundir, tgt, 'receipt.json')
            if not os.path.isfile(rc):
                continue
            try:
                with open(rc) as f:
                    if green_of(json.load(f)):
                        n += 1
            except Exception:
                pass
    except Exception:
        n = 0
    _batch_cache[key] = n
    return n


def pick_authority(cands):
    """关三：同一目标多份 receipt，选哪一份。

    优先**同一个 run 目录里成批重出**的那一份 —— 同一 commit 上的批量重出是唯一
    能横向并列的形态（单独补跑的那一份，与同批其它目标之间就没有共同前提）。
    同批规模相同时取新的那一份。
    """
    return sorted(cands,
                  key=lambda r: (-batch_size(r), -r['mtime'], r['wt'], r['run']))[0]


def build(only=None):
    gl = golden_lines()
    rtl_mods = rtl_modules()
    led = ledger_green()
    cur_id = g1_current_id()
    recs = collect(only)

    workdir = tempfile.mkdtemp(prefix='fmeqtrace-')
    for sub in ('a', 'b'):
        os.makedirs(os.path.join(workdir, sub), exist_ok=True)

    rows = []
    for r in recs:
        checks, impl_in_main, verdict, why = judge(r, rtl_mods, cur_id, workdir)
        r['_checks'], r['_impl_in_main'], r['_verdict'], r['_why'] = \
            checks, impl_in_main, verdict, why

    by_t = collections.defaultdict(list)
    for r in recs:
        by_t[r['target']].append(r)

    for tgt in sorted(by_t):
        cands = by_t[tgt]
        # ★"已经在版本库里"不该压过"判据真的过得了"★（2026-09-20）
        # 只把**判据也过得了**的那些算作既成结论。若库里那份已经不成立（共享件被改过、
        # 闭包缺环…），而 lane 里另有一份八项全过的轮次，该轮次是可收的 ——
        # 收它比重跑便宜得多。第一版按 in_vcs 一刀切，会把那份好的判成 SUPERSEDED、
        # 把目标判成 NEEDS_RERUN，白白让人去重跑一件已经有答案的事。
        already = [r for r in cands if r['in_vcs'] and r['_verdict'] == 'OK']
        stale_vcs = [r for r in cands if r['in_vcs'] and r['_verdict'] != 'OK']
        winner = None
        okc = [r for r in cands if r['_verdict'] == 'OK' and not r['in_vcs']]
        if okc and not already and (tgt not in led or stale_vcs):
            winner = pick_authority(okc)
        for r in cands:
            v = r['_verdict']
            if r['in_vcs']:
                # ★"已经收进来了"不等于"它现在还成立"★（2026-09-20）
                # 第一版这里无条件判 COLLECTED，于是 FauFTBWay 这种**已进版本库、
                # 台账已绿、正在计进 proven**、但闭包缺了 field map 那一环的行，
                # 在表里显示成一个干干净净的 COLLECTED —— 表对已经收进来的东西
                # 讲了个让人安心的故事。而这张表的全部意义就是不讲这种故事。
                # 现在：in_vcs 只决定"它在不在库里"，八项判据照跑；判据红就是红，
                # why 里说明它是**已收但需重出证**，而不是待收。
                if r['_verdict'] == 'OK':
                    v = 'COLLECTED'
                    r['_why'].append('已在版本库里（evidence/%s 已被 git 跟踪）' % r['run'])
                else:
                    v = r['_verdict'] if r['_verdict'] != 'NEEDS_RTL_MERGE' else 'NEEDS_RERUN'
                    r['_why'].append('★已在版本库里（evidence/%s）且已计进 proven，'
                                     '但上面的判据没过 —— 需要重出证，不是待收★' % r['run'])
            elif v == 'OK':
                if already:
                    v = 'SUPERSEDED'
                    r['_why'].append('本目标已有一份进了版本库：evidence/%s' % already[0]['run'])
                elif r is winner:
                    # ★winner 要排在 `tgt in led` 前面★：库里那份已经不成立时
                    # （stale_vcs 非空），台账虽然还记着绿，可收的恰恰是这一份。
                    # 顺序写反就会把唯一那份好的也判成"多余的一轮"。
                    v = 'COLLECTED'
                    if stale_vcs:
                        r['_why'].append('★库里那份（evidence/%s）判据没过，改收这一份★'
                                         % stale_vcs[0]['run'])
                    else:
                        r['_why'].append('本目标选它：同批 %d 个目标在 %s 上成批重出'
                                         % (batch_size(r), (r['commit'] or '?')[:8]))
                elif tgt in led:
                    v = 'SUPERSEDED'
                    r['_why'].append('台账里这个目标已有绿判决，这一份是多余的一轮')
                else:
                    v = 'SUPERSEDED'
                    r['_why'].append('同目标已选 %s/%s（同批 %d 个）'
                                     % (os.path.basename(winner['wt']), winner['run'],
                                        batch_size(winner)))
            elif tgt in led and v != 'NEEDS_RTL_MERGE':
                r['_why'].append('注：台账里这个目标已有绿判决')
            r['_v'] = v

        # ---- 一个目标一行 ----
        # 结论取**最强**的那一个：有 COLLECTED 就是 COLLECTED，不因为同一目标还有
        # 几份陈旧轮次而降级。但陈旧轮次必须在同一行里看得见（other_rounds 列），
        # 否则下一个人会以为那些证据根本不存在、跑去重做。
        lead = sorted(cands, key=lambda r: (VERDICT_RANK[r['_v']],
                                            -batch_size(r), -r['mtime'],
                                            r['wt'], r['run']))[0]
        others = [r for r in cands if r is not lead]
        others.sort(key=lambda r: (r['ev_id'],))
        rows.append([
            tgt, str(gl.get(tgt, 0)), lead['_impl_in_main'],
            'yes' if lead['in_vcs'] else 'no', lead['merge_dup'], mdup_band(tgt, lead['merge_dup']),
            lead['_checks']['chk_golden'], lead['_checks']['chk_impl'],
            lead['_checks']['chk_fm_eq'], lead['_checks']['chk_pins'],
            lead['_checks']['chk_emitter'], lead['_checks']['chk_decl'],
            lead['_checks']['chk_tool'], lead['_checks']['chk_facts'], lead['_v'],
            lead['ev_id'], str(len(cands)),
            ' '.join('%s(%s)' % (r['ev_id'], r['_v']) for r in others) or '-',
            '; '.join(lead['_why']) or '-',
        ])
    rows.sort(key=lambda x: x[0])
    return rows, led


def render(rows, led):
    out = []
    out.append('# 机械生成，勿手改：python3 scripts/gen_receipt_harvest.py')
    out.append('# 复算/比对：python3 scripts/gen_receipt_harvest.py --check')
    out.append('#   --check 按本表列出的 (evidence,target) **逐行重算**，只回答"这张表还对不对"；')
    out.append('#   "lane 里又冒出新证据没列进来"是另一个问题，单独打一行提示，不影响退出码')
    out.append('#   （被扫的 evidence/ 在仓外、十几条 lane 在活跃产出，实测几分钟就能从 471 涨到 517）。')
    out.append('#')
    out.append('# ★一个目标一行★（不是一份 receipt 一行）。同一目标的多轮 receipt 里，')
    out.append('#   verdict 取**最强**的那一个 —— 有 COLLECTED 就是 COLLECTED，不因为它')
    out.append('#   还有几份陈旧轮次而降级；但陈旧轮次在 rounds / other_rounds 两列里**看得见**，')
    out.append('#   否则下一个人会以为那些证据不存在、跑去重做。')
    out.append('#   chk_* 与 evidence 列描述的是被选中的那一份（关三的权威），why 说清为什么是它。')
    out.append('# 关一 impl_in_main  实现在不在 main（不在 -> 只收 receipt 不进 proven 口径）')
    out.append('# 关二 chk_*         证明闭包与 main 当前逐项是否一致')
    out.append('#      chk_fm_eq 的 `trace_equal` **不是**比 sha：是用 receipt 自己记的入口环境')
    out.append('#      在 tclsh 下把两版 fm_eq.tcl 各跑一遍，逐字节比对实际发出的 FM 命令序列')
    out.append('#      （scripts/fm_eq_trace.tcl，判据的输入独立于被判断的 diff 文本）。')
    out.append('# 关三 同一目标多份只收一份，其余 SUPERSEDED，why 里写清为什么是这一份。')
    out.append('#')
    out.append('# merge_dup / mdup_band 两列，说的是"passing 模型能不能当一致性探针"：')
    out.append('#   模型 passing = 闭包触发器位 + 顶层输出端口位，**只在 merge_dup=false 时成立**；')
    out.append('#   merge_dup=true 时 FM 把重复寄存器合并成一个比较点，比较点数低于寄存器位数，')
    out.append('#   低多少取决于设计里有多少重复结构 —— 不是能从 golden 静态算出来的量')
    out.append('#   （实测 IBuffer merge_dup=true：模型 8292 / 实测 7902，差 390 里只有 12 可指认）。')
    out.append('#   但"merge_dup=true 就一律模型不适用"太钝：merge 只合并**寄存器**导出的比较点，')
    out.append('#   顶层 output 端口一个不少，所以偏差上界就是 regs，mdup_band = regs/(regs+outs)。')
    out.append('#   带窄（如 NewDispatch 0.7%）模型照样好用，带宽（IBuffer 85%）才真判不了，>30% 标 wide。')
    out.append('#   merge_dup=false 的行写 `exact`：merge 没开，模型是精确的，"带宽"这个概念不适用。')
    out.append('#   ★本表一项判据都没用模型★：八项全是 sha256 逐项比对 + fm_eq 差分调用序列，')
    out.append('#   与 passing 数无关。这两列是给读表的人防误读用的，不是红灯。')
    out.append('#')
    out.append('# 结论: COLLECTED / NEEDS_RERUN / NEEDS_RTL_MERGE / SUPERSEDED')
    out.append('#')
    cnt = collections.Counter(r[14] for r in rows)
    out.append('# 本次统计: 受检 receipt %d 份 / 不同目标 %d 个 / %s'
               % (len(rows), len({r[0] for r in rows}),
                  ' '.join('%s=%d' % kv for kv in sorted(cnt.items()))))
    out.append('\t'.join(COLUMNS))
    for r in rows:
        out.append('\t'.join(r))
    return '\n'.join(out) + '\n'


def listed_rows(path):
    """表里已列出的 (evidence, target) —— --check 的扫描范围。

    ★必须把 other_rounds 也算进来★：一个目标一行之后，那一行的 rounds / other_rounds
    两列是由**该目标全部轮次**算出来的。只把主 evidence 放进扫描范围，重算时
    别的轮次不在场，other_rounds 会缩成空、--check 必然假红。
    """
    out = set()
    with open(path, errors='replace') as f:
        for l in f:
            if l.startswith('#'):
                continue
            c = l.rstrip('\n').split('\t')
            if len(c) != len(COLUMNS) or c[0] == 'target':
                continue
            out.add((c[15], c[0]))
            if c[17] != '-':
                for tok in c[17].split():
                    out.add((tok.rsplit('(', 1)[0], c[0]))
    return out


def freshness(listed):
    """lane 里还有多少份绿 receipt 没列进表 —— 只报数，不改退出码。"""
    n = 0
    for r in collect():
        if (r['ev_id'], r['target']) not in listed:
            n += 1
    return n


def main(argv):
    ap = argparse.ArgumentParser()
    ap.add_argument('--check', action='store_true',
                    help='按表里列出的行逐行重算，只判"这张表还对不对"')
    ap.add_argument('--strict-fresh', action='store_true',
                    help='连"lane 里有未列入的新证据"也判红（默认只提示）')
    ap.add_argument('--out', default=OUT)
    a = ap.parse_args(argv)

    if a.check:
        if not os.path.exists(a.out):
            print('receipt_harvest: %s 不存在' % a.out)
            return 1
        listed = listed_rows(a.out)
        if not listed:
            print('receipt_harvest: %s 里一行数据都读不出 —— 拒绝按"一致"放过' % a.out)
            return 1
        rows, led = build(only=listed)
        txt = render(rows, led)
        with open(a.out, errors='replace') as f:
            cur = f.read()
        rc = 0
        if cur != txt:
            print('receipt_harvest: ★--check 红★ 表里的行重算对不上'
                  '（有人手改过，或某一行的依据已经不成立）')
            rc = 1
        else:
            print('receipt_harvest: --check 一致（逐行重算 %d 行）' % len(rows))
        nf = freshness(listed)
        if nf:
            print('  新鲜度: lane 里另有 %d 份绿 receipt 未列入本表'
                  '（重跑生成器即可纳入；%s）'
                  % (nf, '按 --strict-fresh 判红' if a.strict_fresh else '不影响退出码'))
            if a.strict_fresh:
                rc = 1
        return rc

    rows, led = build()
    txt = render(rows, led)
    with open(a.out, 'w') as f:
        f.write(txt)
    cnt = collections.Counter(r[14] for r in rows)
    print('写出 %s' % a.out)
    print('  受检 receipt %d 份，不同目标 %d 个' % (len(rows), len({r[0] for r in rows})))
    for k in ('COLLECTED', 'NEEDS_RERUN', 'NEEDS_RTL_MERGE', 'SUPERSEDED'):
        print('  %-16s %d' % (k, cnt.get(k, 0)))
    return 0


if __name__ == '__main__':
    sys.exit(main(sys.argv[1:]))
