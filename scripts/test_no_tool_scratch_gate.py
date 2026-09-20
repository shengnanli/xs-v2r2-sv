#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""check_no_tool_scratch.py 的双向负测。

规矩（CONVENTIONS.md「闸的负测必须是双向的」）：
  正向——该报的必须报（每一类 scratch 各造一例）
  反向——不该报的一个也不许报（正常文件、以及**长得像但不是**的名字）

反向那一半是重点：`fm_diag*` 这种前缀匹配最容易误伤 `fm_diagram/`、
`fm_diagnostics_spec.md` 之类的正经文件名，所以专门造了这些反例。
"""
import subprocess
import sys
import os

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import importlib
mod = importlib.import_module('check_no_tool_scratch')
is_scratch = mod.is_scratch

# (路径, 应当被判为 scratch?)
CASES = [
    # ---- 正向：该报的 ----
    ('FM_INFO/tags.e', True),                                   # 仓库根（历史事故 1）
    ('verif/ut/X/fm_diag/FM_INFO/tags.e', True),                # 深一层（历史事故 2）
    ('verif/ut/X/fm_diag7/fm_shell_command.log', True),         # 带数字后缀的变体
    ('verif/ut/X/fm_diag4_sidecar/a.txt', True),                # 带下划线后缀的变体
    ('verif/ut/X/fm_work/fm.log', True),
    ('FM_WORK2/x', True),
    ('verif/ut/X/neg_build/neg_compile.log', True),             # 历史事故 3
    ('verif/ut/X/neg_build/neg_simv.daidir/libfile', True),
    ('a/b/csrc/x.o', True),
    ('verif/ut/X/fm_shell_command.log.1', True),                # 带序号后缀
    ('verif/ut/X/formality.log', True),
    ('verif/ut/X/simv.daidir/x', True),                         # .daidir 目录
    ('verif/ut/X/novas.rc', True),
    ('scripts/__pycache__/m.pyc', True),
    # 备份副本（2026-09-20 实测事故 3：cf002ce8 把它连带 git add 进库）
    ('verif/ut/Sbuffer/.mutants.orig.sv', True),
    ('verif/ut/X/Foo.orig.sv', True),
    ('rtl/memblock/Sbuffer.sv.bak', True),
    ('verif/ut/X/tb.orig', True),

    # ---- 反向：不许误报 ----
    ('rtl/backend/EntriesAluCsrFenceDiv.sv', False),
    ('scripts/fm_eq.tcl', False),                               # 名字带 fm_ 但是源码
    ('scripts/fm_verdict.py', False),
    ('docs/fm_round_20260917.tsv', False),
    ('verif/ut/X/fm_pins_pre.tcl', False),                      # 生成的钉点，是输入不是产物
    ('docs/fm_diagram.md', False),                              # ★前缀像 fm_diag 但是文件不是目录
    ('verif/ut/X/fm_diagram/note.md', False),                   # ★目录名像 fm_diag 但后缀不是数字/下划线
    ('docs/fm_diagnostics_spec.md', False),
    ('verif/ut/X/Makefile', False),
    ('verif/ut/X/tb.sv', False),
    ('CONVENTIONS.md', False),
    # ★反向：名字里含 orig / bak 但不是备份副本，一个也不许误伤★
    ('rtl/common/xs_original_pkg.sv', False),
    ('docs/origin_map.tsv', False),
    ('scripts/backfill.py', False),
    ('verif/ut/X/baking_tb.sv', False),
    # ---- 反向：evidence/ 是有意提交的签核凭据，整棵豁免 ----
    ('evidence/abc123/Top/fm.log', False),
    ('evidence/abc123/Top/sidecar/native_facts.json', False),
    ('evidence/abc123/Top/black_boxes.rpt', False),
]


def main():
    bad = []
    for path, want in CASES:
        got = is_scratch(path) is not None
        if got != want:
            bad.append((path, want, got))

    if bad:
        print('test_no_tool_scratch_gate: 失败 —— %d 例判断与期望不符' % len(bad),
              file=sys.stderr)
        for path, want, got in bad:
            kind = '漏报（该拦没拦）' if want else '★误报（不该拦却拦了）'
            print('  %s  %s' % (kind, path), file=sys.stderr)
        return 1

    fwd = sum(1 for _, w in CASES if w)
    rev = len(CASES) - fwd
    print('test_no_tool_scratch_gate: OK —— 正向 %d 例全拦下，反向 %d 例全不误报'
          % (fwd, rev))

    # 再跑一次真闸，确认它在干净索引上是绿的（不然负测绿、真闸红也没用）
    rc = subprocess.call([sys.executable,
                          os.path.join(os.path.dirname(os.path.abspath(__file__)),
                                       'check_no_tool_scratch.py')])
    if rc != 0:
        print('test_no_tool_scratch_gate: 失败 —— 真闸在当前索引上是红的', file=sys.stderr)
        return 1
    return 0


if __name__ == '__main__':
    sys.exit(main())
