#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""check_fm_eq_no_target_data.py —— per-target 数据不许再回到 `scripts/fm_eq.tcl`。

## 为什么要有这道闸

2026-09-20 把 per-target 数据（vmucp 白名单 65 个名字 + 各自的加入依据 +
LoadQueueReplay 的专属 appvar 块）拆进了 `verif/fm_target_config/<top>.tcl`，
理由是量出来的：6 份 child 证书里出现 4 个互不相同的 `fm_eq.tcl` 哈希、**没有一个**
等于 HEAD，而同样被绑定的 `scripts/sidecar/fm_native_emit.tcl` 6 份里有 4 份等于 HEAD
（详见 `verif/fm_target_config/README.md`）。

★但"修好"不等于"修住"★：下一条 lane 顺手把一个名字塞回 `fm_eq.tcl`，全仓证书又一起
过期，而且**没有任何现成的闸会响** —— 语法闸只看 tclsh 能不能解析，结构闸只看括号与
白名单 if 的条数。所以这里补一道专门盯"内容构成"的闸。

## 判据（四条，全部 fail-closed）

  C1  `fm_eq.tcl` 里不许按**字面名字**给 `$top` 分支：
      `$top eq/ne/in/ni ...`、`switch -- $top`、`string match ... $top`。
      拆分前的两处 per-target 数据恰好是这两种形态（`if {$top ni {…65 个…}}`
      与 `if {$top eq "LoadQueueReplay"}`），所以这一条直接盯住了复发的主路径。
  C2  不许出现**加入依据形态**的注释（`加入依据` / `进 vmucp 白名单` /
      `目标专属 appvar` / `白名单条目`）。churn 实测里，加名字的那 7 次提交
      **每次都同时搬进几十行依据**，所以只挡 C1 挡不住 churn。
  C3  ★名字预算（ratchet）★：`fm_eq.tcl` 里出现的 FM target 名字集合必须是下面
      `FROZEN_MENTIONS` 的**子集**。文件里现存的 14 个名字都在通用教训里（"SourceB
      的 set_top 失败"、"实测 EntriesFaluFmac 44 秒"…），那是**证据**不是 per-target
      数据，删掉反而丢信息；但这个集合**只许缩不许长**：想新增就得改本文件，
      于是必然过一次 review。
  C4  `verif/fm_target_config/*.tcl` 反过来也要守契约：文件名必须是真 FM target
      （名字打错 = 该目标悄悄掉出白名单）、顶层只许注释 + `fm_target_vmucp_allow` +
      `fm_target_appvar`、appvar 只许是 sidecar 注册表里的 OPTIONAL 项。

## 判据自己的负测（`--selftest`，本仓规矩：闸必须双向 + 要有元负例）

    pos          现在的树                                    -> 绿
    neg_branch   往 fm_eq.tcl 塞一条 `if {$top eq "Foo"}`    -> ★红★（C1）
    neg_prose    塞一行「XXX 加入依据(...)」注释              -> ★红★（C2）
    neg_name     塞一个新 target 名字                        -> ★红★（C3）
    neg_cfg      往某个 config 里塞一条 `set x 1`            -> ★红★（C4）
    neg_cfg_av   往某个 config 里塞一条 required appvar      -> ★红★（C4）
    undo         把上面每一条拿掉                            -> 绿（双向）
    meta_blanket 把名字全集清空（= 判据写空）                -> ★正例必须转红★

用法:
    python3 scripts/check_fm_eq_no_target_data.py
    python3 scripts/check_fm_eq_no_target_data.py --selftest
"""
import os
import pathlib
import re
import sys

REPO = pathlib.Path(__file__).resolve().parents[1]
FM_EQ = REPO / 'scripts' / 'fm_eq.tcl'
CFG_DIR = REPO / 'verif' / 'fm_target_config'

sys.path.insert(0, str(REPO / 'scripts'))
import fm_target_universe as FTU                                  # noqa: E402

# ---------------------------------------------------------------------------
# C3 的冻结名单：这些名字现在就在 fm_eq.tcl 的**通用教训**里，逐条给出理由。
# ★只许缩不许长★。要加一个名字，就得在这里写清楚它凭什么不是 per-target 数据。
# ---------------------------------------------------------------------------
FROZEN_MENTIONS = {
    'EntriesFaluFmac':           'switch body 注记事故的实测受害者（44 秒 / 0 比较点）',
    'ICacheMissUnit':            'set_top 失败"教训 B"的实测实例',
    'LoadQueueReplay':           'churn 统计里那 1 次 appvar 块改动的出处（本次拆分的注记）',
    'MulUnit':                   'FM_MERGE_DUP=false 的先例之一',
    'MuxBundle':                 'set_top 失败"教训 B"的实测实例 + 消息号正则事故',
    'NCBTransactionQueue':       'matched_nc vs unmatched unread 通用判断的举例',
    'NewDispatch':               '"u_core 必然要关 merge_dup"被判别性实验证伪的出处',
    'NewPipelineConnectPipe_29': 'field map 没进字节快照那个洞的实测实例',
    'Predictor':                 'failing_point_limit 截断的实测实例 + vmucp 现形的实例',
    'RenameBuffer':              'FM_MERGE_DUP=false 的先例之一',
    'SSIT':                      '"别拿裸错误号当判据"的查出者',
    'Sbuffer':                   'switch body 注记事故的独立复现 lane',
    'SourceB':                   'set_top 失败"教训 A"的实测实例',
    'TLBFA':                     'matched_nc vs unmatched unread 通用判断的举例',
}

# sidecar 注册表（scripts/sidecar/fm_native_emit.tcl）的 OPTIONAL 集合，逐字同步。
OPTIONAL_APPVARS = {
    'verification_assume_reg_init',
    'verification_set_undriven_signals',
    'verification_propagate_const_reg_x',
    'verification_blackbox_match_mode',
}

C1_PATTERNS = [
    (re.compile(r'\$top\s+(?:eq|ne|in|ni)\b'), '$top 与字面量比较'),
    (re.compile(r'switch\s+(?:--\s+)?\$top\b'), 'switch -- $top'),
    (re.compile(r'string\s+match\s+[^\n]*\$top\b'), 'string match … $top'),
]
C2_PATTERNS = [re.compile(p) for p in
               ('加入依据', r'进\s*vmucp\s*白名单', '目标专属 appvar', '白名单条目')]


def strip_comments(text):
    """只留下**可执行**行（行首 # 的注释整行去掉）。C1 只盯可执行行。"""
    out = []
    for ln in text.split('\n'):
        if ln.lstrip().startswith('#'):
            out.append('')
        else:
            out.append(ln)
    return '\n'.join(out)


_UNIVERSE = []


def universe(blanket=False):
    """FM target 全集。blanket=True 是**元负例**：交出空集合（= 判据写空）。

    用 regex 引擎（不跑 make）：本闸只拿它当"名字是不是 target"的字典，漏一个名字
    只会让闸**弱一点**，不会误红；而 make 引擎要导出整棵树，进 gate_all 太贵。
    """
    if blanket:
        return set()
    if not _UNIVERSE:
        names, _unres = FTU.targets_at_regex(str(REPO), 'HEAD')
        _UNIVERSE.append(set(names))
    return _UNIVERSE[0]


def problems(fm_eq_text, cfg_files, names):
    """返回问题列表；空 = 干净。cfg_files: {文件名: 内容}"""
    probs = []

    # --- 判据自身的 fail-closed：全集空 / 配置目录空 都不算通过 ---
    if not names:
        probs.append('FM target 全集为空 —— 判据失效，按 fail-closed 报')
        return probs
    if not cfg_files:
        probs.append('verif/fm_target_config/ 里一份 per-target 配置都没有 —— '
                     '要么目录没了、要么解析器失效，都不算通过')
        return probs

    # --- C1 按名字分支 ---
    code = strip_comments(fm_eq_text)
    for i, ln in enumerate(code.split('\n'), start=1):
        for rx, what in C1_PATTERNS:
            if rx.search(ln):
                probs.append('C1 第 %d 行按名字给 $top 分支（%s）：%s'
                             % (i, what, ln.strip()[:70]))

    # --- C2 加入依据形态的注释 ---
    for i, ln in enumerate(fm_eq_text.split('\n'), start=1):
        for rx in C2_PATTERNS:
            if rx.search(ln):
                probs.append('C2 第 %d 行是 per-target 依据形态的注释，'
                             '该写进 verif/fm_target_config/<top>.tcl：%s'
                             % (i, ln.strip()[:60]))

    # --- C3 名字预算 ---
    hit = {n for n in names if re.search(r'(?<![A-Za-z0-9_])%s(?![A-Za-z0-9_])'
                                         % re.escape(n), fm_eq_text)}
    for n in sorted(hit - set(FROZEN_MENTIONS)):
        probs.append('C3 fm_eq.tcl 里出现了新的 FM target 名字 %s —— '
                     'per-target 的东西写进 verif/fm_target_config/%s.tcl；'
                     '若确是通用教训里的举例，把它连同理由加进本闸的 FROZEN_MENTIONS'
                     % (n, n))

    # --- C4 per-target 文件自己的契约 ---
    for fn, txt in sorted(cfg_files.items()):
        top = fn[:-4]
        if top not in names:
            probs.append('C4 %s 的文件名不是 FM target —— '
                         '名字打错的后果是该目标悄悄掉出白名单' % fn)
        for i, ln in enumerate(txt.split('\n'), start=1):
            s = ln.strip()
            if not s or s.startswith('#'):
                continue
            tok = s.split()
            if tok[0] == 'fm_target_vmucp_allow':
                if len(tok) != 1:
                    probs.append('C4 %s:%d fm_target_vmucp_allow 不带参数' % (fn, i))
            elif tok[0] == 'fm_target_appvar':
                if len(tok) != 3:
                    probs.append('C4 %s:%d fm_target_appvar 要恰两个参数' % (fn, i))
                elif tok[1] not in OPTIONAL_APPVARS:
                    probs.append('C4 %s:%d appvar %s 不在 sidecar 注册表的 OPTIONAL 集合里'
                                 '（required 由 POLICY.json 钉死，不许 per-target 覆盖）'
                                 % (fn, i, tok[1]))
            else:
                probs.append('C4 %s:%d 契约外的命令 %s —— per-target 文件不许含逻辑'
                             % (fn, i, tok[0]))
    return probs


def read_cfgs():
    if not CFG_DIR.is_dir():
        return {}
    return {p.name: p.read_text(errors='replace')
            for p in sorted(CFG_DIR.glob('*.tcl'))}


def run(fm_eq_text=None, cfg_files=None, blanket=False):
    t = FM_EQ.read_text(errors='replace') if fm_eq_text is None else fm_eq_text
    c = read_cfgs() if cfg_files is None else cfg_files
    return problems(t, c, universe(blanket=blanket))


def selftest():
    base = FM_EQ.read_text(errors='replace')
    cfgs = read_cfgs()
    one = sorted(cfgs)[0]
    rc = 0
    cases = [
        ('pos', base, cfgs, False, False),
        ('neg_branch', base.replace('\nfm_target_apply_appvars',
                                    '\nif {$top eq "Foo"} { set_app_var x y }\n'
                                    'fm_target_apply_appvars'), cfgs, False, True),
        ('neg_prose', base + '\n# Bar 加入依据(2026-09-20)：passing 1 -> 2\n',
         cfgs, False, True),
        ('neg_name', base + '\n# 顺手记一笔：AgeDetector_38 也该进白名单\n',
         cfgs, False, True),
        ('neg_cfg', base, dict(cfgs, **{one: cfgs[one] + '\nset sneaky 1\n'}), False, True),
        ('neg_cfg_av', base,
         dict(cfgs, **{one: cfgs[one] + '\nfm_target_appvar hdlin_interface_only X\n'}),
         False, True),
        ('meta_blanket', base, cfgs, True, True),
    ]
    for name, txt, c, blanket, want_red in cases:
        got = problems(txt, c, universe(blanket=blanket))
        ok = bool(got) == want_red
        rc |= 0 if ok else 1
        tail = ('报出 %d 项：%s' % (len(got), got[0][:70])) if got else '无问题'
        print('  %-13s %-4s %s' % (name, 'red' if got else 'green',
                                   ('PASS  ' if ok else '★FAIL★') + tail))
    # 双向负测的"拿掉 -> 绿"那一半：上面 pos 用的就是把注入拿掉之后的同一棵树，
    # 这里再显式跑一次，免得有人以为只测了单向。
    got = problems(base, cfgs, universe())
    ok = not got
    rc |= 0 if ok else 1
    print('  %-13s %-4s %s' % ('undo', 'green' if ok else 'red',
                               'PASS  拿掉注入即转绿' if ok else '★FAIL★ %s' % got[:1]))
    return rc


def main(argv):
    if '--selftest' in argv:
        print('check_fm_eq_no_target_data --selftest:')
        return selftest()
    probs = run()
    if not probs:
        print('check_fm_eq_no_target_data: OK —— fm_eq.tcl 里没有 per-target 数据；'
              'verif/fm_target_config/ 下 %d 份配置守约' % len(read_cfgs()))
        return 0
    print('check_fm_eq_no_target_data: ★FAIL★ —— per-target 数据又回到了共享文件里'
          '（后果：全仓 child 证书一起失效）：')
    for p in probs:
        print('  %s' % p)
    return 1


if __name__ == '__main__':
    sys.exit(main(sys.argv[1:]))
