#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""check_no_svh_in_rtl.py 的双向负测（CONVENTIONS「闸的负测必须是双向的」）。

反向那一半要防的具体误报：
  - 注释掉的 `include` 不该报
  - 字符串里出现 "`include" 字样不该报
  - rtl/ 之外的 .svh（如 verif/sim/collateral 里 difftest 自带的）不该报
"""
import os
import shutil
import subprocess
import sys
import tempfile

HERE = os.path.dirname(os.path.abspath(__file__))
GATE = os.path.join(HERE, 'check_no_svh_in_rtl.py')


def run(sb):
    # ★必须跑沙箱里的副本★：闸最后一行按 __file__ 定位仓库根并 chdir，
    # 只改 subprocess 的 cwd 是无效的（这个坑在 test_coverage_provenance_gate.py 上踩过）。
    g = os.path.join(sb, 'scripts', 'check_no_svh_in_rtl.py')
    r = subprocess.run([sys.executable, g], cwd=sb,
                       stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
    return r.returncode, r.stdout.decode('utf-8', 'replace')


def sandbox(tmp, files):
    sb = os.path.join(tmp, 'repo')
    os.makedirs(os.path.join(sb, 'scripts'))
    shutil.copy(GATE, os.path.join(sb, 'scripts', 'check_no_svh_in_rtl.py'))
    for rel, text in files.items():
        p = os.path.join(sb, rel)
        os.makedirs(os.path.dirname(p), exist_ok=True)
        with open(p, 'w', encoding='utf-8') as f:
            f.write(text)
    return sb


CLEAN = 'module M (input a, output b);\n  assign b = ~a;\nendmodule\n'

CASES = [
    # (名字, 文件表, 期望失败?, 期望消息片段)
    ('正向 rtl 下有 .svh',
     {'rtl/backend/M.sv': CLEAN, 'rtl/backend/m_body.svh': 'assign x = y;\n'},
     True, '判据 A 失败'),
    ('正向 .sv 里有 `include',
     {'rtl/backend/M.sv': '`include "m_body.svh"\n' + CLEAN},
     True, '判据 B 失败'),
    ('正向 include 前有缩进',
     {'rtl/backend/M.sv': '    `include "x.sv"\n' + CLEAN},
     True, '判据 B 失败'),
    ('反向 干净',
     {'rtl/backend/M.sv': CLEAN},
     False, None),
    ('反向 注释掉的 include 不算',
     {'rtl/backend/M.sv': '// `include "old.svh" —— 已按单文件规范收进本文件\n' + CLEAN},
     False, None),
    ('反向 字符串里提到 include 不算',
     {'rtl/backend/M.sv': CLEAN + '// 说明：本轮禁止 `include，见 CONVENTIONS\n'},
     False, None),
    ('反向 rtl 之外的 .svh 不算',
     {'rtl/backend/M.sv': CLEAN,
      'verif/sim/collateral/generated-src/DifftestMacros.svh': '`define X 1\n'},
     False, None),
    ('反向 没有 rtl 目录时跳过',
     {'verif/x.sv': CLEAN},
     False, '跳过'),
]


def main():
    bad = []
    with tempfile.TemporaryDirectory() as tmp:
        for i, (name, files, want_fail, frag) in enumerate(CASES):
            d = os.path.join(tmp, 'c%d' % i)
            os.makedirs(d)
            rc, out = run(sandbox(d, files))
            got = rc != 0
            if got != want_fail:
                bad.append((name, want_fail, got, out))
            elif frag and frag not in out:
                bad.append((name, '含 "%s"' % frag, '没有', out))
    if bad:
        print('test_no_svh_gate: 失败 —— %d 例不符' % len(bad), file=sys.stderr)
        for n, w, g, o in bad:
            print('  %s  期望=%s 实际=%s' % (n, w, g), file=sys.stderr)
            for l in o.splitlines()[:3]:
                print('      %s' % l, file=sys.stderr)
        return 1
    fwd = sum(1 for c in CASES if c[2])
    print('test_no_svh_gate: OK —— 正向 %d 例全拦下，反向 %d 例全不误报'
          % (fwd, len(CASES) - fwd))
    return 0


if __name__ == '__main__':
    sys.exit(main())
