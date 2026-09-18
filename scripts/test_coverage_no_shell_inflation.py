#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""test_coverage_no_shell_inflation.py —— 空壳不得抬高 proven 覆盖率。

## 这道闸在防什么

覆盖率台账原来的判据是「rtl/ 里有同名 module 就算已重写」。LoadQueueReplay 的考古
worker 实测发现：把一个 3,149 行、只实现约两成逻辑的**骨架**放进 rtl/，覆盖率立刻
从 7.4% 跳到 11.0% —— 凭空记账 138,860 行 golden。**任何人放个空壳进去都会如此。**

判据已改成按证据记（proven = written 且有绿判决证据）。这道闸把「改好了」变成
「改住了」：机械地把一个**最小空壳**塞进 rtl/，要求

  · written 必须涨（空壳确实是个新文件，台账不该假装看不见它）
  · ★proven 必须一位不动★（它没有任何绿判决证据）

两条都查，才能区分「判据正确」与「判据把整张表冻住了」。
"""
import pathlib
import re
import subprocess
import sys
import tempfile

REPO = pathlib.Path(__file__).resolve().parent.parent
sys.path.insert(0, str(REPO / 'scripts'))


def nums():
    import importlib
    import rewrite_coverage as RC
    importlib.reload(RC)
    text, _ = RC.build()
    out = {}
    for line in text.splitlines():
        m = re.match(r'^(unique_design_\w+|golden_lines_\w+)\t(\d+)\t(\d+)\t', line)
        if m:
            out[m.group(1)] = int(m.group(2))
    return out


def main():
    # 挑一个**尚未重写**的大 golden 模块当空壳对象，才看得出抬高效果
    victim = None
    import rewrite_coverage as RC
    gold = RC.golden_modules()
    done = RC.rewritten_modules()
    for name, (_f, n) in sorted(gold.items(), key=lambda kv: -kv[1][1]):
        if name not in done and not RC.classify(name):
            victim = (name, n)
            break
    if victim is None:
        print('test_coverage_no_shell_inflation: 找不到可用的未重写模块——闸空转，判失败')
        return 1

    before = nums()
    shell = REPO / 'rtl' / ('_shell_probe_%s.sv' % victim[0])
    if shell.exists():
        print('test_coverage_no_shell_inflation: 探针文件已存在，拒绝覆盖')
        return 1
    shell.write_text('// 闸的探针文件，测完即删\nmodule %s;\nendmodule\n' % victim[0])
    try:
        after = nums()
    finally:
        shell.unlink()

    fails = []
    if after.get('golden_lines_written', 0) <= before.get('golden_lines_written', 0):
        fails.append('空壳没让 written 变化 —— 台账对新文件视而不见，探针无效')
    for k in ('golden_lines_proven', 'unique_design_proven'):
        if after.get(k) != before.get(k):
            fails.append('★空壳抬高了 %s：%s -> %s★' % (k, before.get(k), after.get(k)))

    if fails:
        print('test_coverage_no_shell_inflation: %d 条不过（空壳=%s，%d 行）：'
              % (len(fails), victim[0], victim[1]))
        for f in fails:
            print('  - ' + f)
        return 1
    print('test_coverage_no_shell_inflation: 空壳 %s 抬高 written %d→%d 行、'
          'proven 一位未动（%d 行）'
          % (victim[0], before['golden_lines_written'],
             after['golden_lines_written'], after['golden_lines_proven']))
    return 0


def test_new_round_ledger_counts():
    """新落一份 docs/fm_round_<日期>.tsv，proven 必须自动计入。

    ★这道闸堵的是反方向的错★：上面那条防"空壳抬高 proven"，这条防
    "真签核了却记不上"。2026-09-17 之前 proven_modules() 把 round 台账**写死**成
    fm_round_20260914.tsv 一份，于是新开一轮签核 proven 原地不动 ——
    written 在涨、proven 不涨，看上去像"写了一堆没证"，实际是记账口径漏了新台账。
    虚低和虚高一样是记错账：前者会让人以为还有大片没证，把力气花在已经证过的地方。
    """
    import importlib.util
    import pathlib

    def _proven():
        spec = importlib.util.spec_from_file_location("_rc", str(REPO / "scripts" / "rewrite_coverage.py"))
        m = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(m)
        return m.proven_modules()

    base = _proven()
    probe = REPO / "docs" / "fm_round_ZZPROBE.tsv"
    if probe.exists():
        print('test_new_round_ledger_counts: 探针文件已存在，拒绝覆盖: %s' % probe)
        return 1
    probe.write_text('target\tverdict\tnote\n__probe_module__\tSUCCEEDED\t负测用\n',
                     encoding='utf-8')
    try:
        got = _proven()
    finally:
        probe.unlink()
    back = _proven()

    fails = []
    if '__probe_module__' not in got:
        fails.append('★新台账没被计入 —— round 台账不是 glob 的★')
    if len(got) != len(base) + 1:
        fails.append('proven 涨了 %d 个，应正好 +1（%d -> %d）'
                     % (len(got) - len(base), len(base), len(got)))
    if len(back) != len(base):
        fails.append('撤掉探针后没回落：%d -> %d' % (len(base), len(back)))

    if fails:
        print('test_new_round_ledger_counts: %d 条不过：' % len(fails))
        for f in fails:
            print('  - ' + f)
        return 1
    print('test_new_round_ledger_counts: 新增一份 round 台账 -> proven %d -> %d，撤掉回落 ✓'
          % (len(base), len(got)))
    return 0


if __name__ == '__main__':
    sys.exit(main() or test_new_round_ledger_counts())
