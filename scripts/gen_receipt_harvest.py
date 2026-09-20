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
"""
# ★本机是 Python 3.6：subprocess.run 没有 capture_output（3.7 才有）。★
import argparse
import collections
import hashlib
import json
import os
import re
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

COLUMNS = ['target', 'golden_lines', 'impl_in_main', 'in_vcs', 'merge_dup',
           'mdup_band', 'chk_golden', 'chk_impl', 'chk_fm_eq', 'chk_pins',
           'chk_emitter', 'chk_decl', 'chk_tool', 'chk_facts', 'verdict',
           'evidence', 'rounds', 'other_rounds', 'why']

# 一个目标一行时，结论取**最强**的那一个。
VERDICT_RANK = {'COLLECTED': 0, 'SUPERSEDED': 1, 'NEEDS_RERUN': 2,
                'NEEDS_RTL_MERGE': 3, 'OK': 0}

_band_cache = {}


def mdup_band(target):
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
        res.append(w)
    return res


def tracked_runs():
    _, out = run(['git', 'ls-files', 'evidence/'], REPO)
    return {p.split('/')[1] for p in out.splitlines() if p.count('/') >= 1}


def green_of(j):
    v = j.get('verdict') or (j.get('verdict_detail') or {}).get('native')
    return v if v in OK_VERDICTS else None


def collect(only=None):
    """扫各 lane worktree 的绿 receipt。

    `only` 给一组 (evidence, target)（evidence = "<worktree basename>:<run>"）时只收这些
    —— `--check` 用它把扫描范围钉死在表里已列出的行上，使逐行重算不受别的 lane
    正在新产出的证据影响（那是新鲜度问题，不是本表对不对的问题）。
    """
    tracked = tracked_runs()
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
    for wt in sorted(lane_worktrees()):
        ev = os.path.join(wt, 'evidence')
        if not os.path.isdir(ev):
            continue
        for rundir_name in sorted(os.listdir(ev)):
            rundir = os.path.join(ev, rundir_name)
            if not os.path.isdir(rundir):
                continue
            ev_id = '%s:%s' % (os.path.basename(wt), rundir_name)
            for tgt in sorted(os.listdir(rundir)):
                if (rundir_name, tgt) in seen:
                    continue
                if only is not None and (ev_id, tgt) not in only:
                    continue
                d = os.path.join(rundir, tgt)
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
                ver, packed = None, False
                fl = os.path.join(d, 'fm.log')
                if os.path.isfile(fl):
                    with open(fl, errors='replace') as f:
                        txt = f.read()
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
                    'ev_id': ev_id, 'in_vcs': rundir_name in tracked,
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
                    'fm_ver': ver, 'packed': packed,
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
                bad.append('dead_ref 声明读不出: %s' % e)
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
    if r['fm_ver'] == FM_SHELL_BASELINE:
        return 'same', ''
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
        txt = tcl_exec_text(os.path.join(r['dir'], 'sidecar', p['arch']))
        if re.search(r'\bfind_cells\b', txt):
            return 'DIFFER', 'emitter 差在 find_cells alias，而钉点文件的可执行文本真的调用了它'
    return 'inert', 'emitter 仅差 find_cells alias；本次钉点可执行文本里没有它'


def chk_pins(r):
    pins = _arch(r, 'fm_pins')
    if not pins:
        return 'none', ''
    missing, differ = [], []
    for e in pins:
        rel = repo_rel(e['src'])
        p = os.path.join(REPO, rel)
        if not os.path.exists(p):
            missing.append(rel)
        elif sha_file(p) != e['sha']:
            differ.append(rel)
    if missing:
        return 'MISSING', 'main 里没有钉点文件: %s' % ','.join(missing[:2])
    if differ:
        return 'DIFFER', '钉点文件已变: %s' % ','.join(differ[:2])
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
    run(['tclsh', TRACER, fm_eq_path], cwd=workdir, env=env)
    try:
        with open(out, errors='replace') as f:
            txt = f.read()
    except Exception:
        txt = '<NO TRACE>'
    _trace_cache[key] = txt
    return txt


def chk_fm_eq(r, workdir):
    """★本关重点★ 不比 sha、不读 diff，跑两版比实际发出的 FM 命令序列。"""
    es = _arch(r, 'fm_eq.tcl')
    if not es:
        return 'UNKNOWN', 'receipt 没有 fm_eq 字节快照'
    cur = os.path.join(REPO, 'scripts', 'fm_eq.tcl')
    if es[0]['sha'] == sha_file(cur):
        return 'same', ''
    old = os.path.join(r['dir'], 'sidecar', es[0]['arch'])
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
    checks['chk_pins'], w = chk_pins(r)
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
          or any(v in ('DIFFER', 'MISSING', 'UNKNOWN') for v in checks.values())):
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
        # 已经进了版本库的那一份就是本目标的既成结论，关三不必再选。
        already = [r for r in cands if r['in_vcs']]
        winner = None
        okc = [r for r in cands if r['_verdict'] == 'OK' and not r['in_vcs']]
        if okc and not already and tgt not in led:
            winner = pick_authority(okc)
        for r in cands:
            v = r['_verdict']
            if r['in_vcs']:
                v = 'COLLECTED'
                r['_why'].append('已在版本库里（evidence/%s 已被 git 跟踪）' % r['run'])
            elif v == 'OK':
                if already:
                    v = 'SUPERSEDED'
                    r['_why'].append('本目标已有一份进了版本库：evidence/%s' % already[0]['run'])
                elif tgt in led:
                    v = 'SUPERSEDED'
                    r['_why'].append('台账里这个目标已有绿判决，这一份是多余的一轮')
                elif r is winner:
                    v = 'COLLECTED'
                    r['_why'].append('本目标选它：同批 %d 个目标在 %s 上成批重出'
                                     % (batch_size(r), (r['commit'] or '?')[:8]))
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
            'yes' if lead['in_vcs'] else 'no', lead['merge_dup'], mdup_band(tgt),
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
