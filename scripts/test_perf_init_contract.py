#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""test_perf_init_contract.py —— perf 初值设定闸（codex 0207 P1，Z0）的负测（秒级）。

perf_compare.py 在比数之前先比"两侧是怎么跑的"：两份 assert.log 各要恰好一条
[PERFCFG]（verif/sim/perf_cfg_stamp.sv 在仿真里现场打印），且每侧都是 Z0
（编译期无 RANDOMIZE_*、编译期开 initreg、运行期 +vcs+initreg+0、探针 reg/阵列实测为 0），
两侧 workload/seed/max_cycles 逐字一致。任一不满足 → 退出码 3，不做比较。

这里用真实分档台账里的 3 个已绑定计数器造一对最小日志：
  P0 两侧 Z0 且一致                                   → rc 0（证明闸不是一直红）
  N1..N14 每次只坏一项（缺行/各字段不合 Z0/两侧不一致/重复行/缺字段） → rc 3
  N15 设定全对但数值差 1（B_CONTROL）                 → rc 1（主比较无容差）
"""
from __future__ import print_function

import pathlib
import shutil
import subprocess
import sys
import tempfile

HERE = pathlib.Path(__file__).resolve().parent
REPO = HERE.parent
sys.path.insert(0, str(HERE))
import perf_compare as PC                                           # noqa: E402

fails = []


def check(name, cond, detail=''):
    if not cond:
        fails.append('%s: %s' % (name, detail))
    print('  %-60s %s' % (name, 'ok' if cond else '★FAIL ' + detail))


# 选 3 个已分档、已绑定（不在 gap 台账里）的 B_CONTROL 计数器
tier = PC.load_tier()
gap = PC.load_gap()
keys = [k for k, r in sorted(tier.items()) if r['tier'] == 'B_CONTROL' and k not in gap][:3]
assert len(keys) == 3, '分档台账里找不到 3 个已绑定 B_CONTROL 计数器'

GOOD = dict(randomize_defines='none', initreg_plusarg='0',
            initreg_probe_reg='0000000000000000', initreg_probe_mem='00000000',
            workload='/x/ready-to-run/coremark-2-iteration.bin', seed='default',
            max_cycles='20000')


def cfg_line(d, drop=()):
    return '[PERFCFG] ' + ' '.join('%s=%s' % (k, d[k]) for k in PC.CFG_KEYS if k not in drop)


def log_text(cfg, bump=0, extra_cfg=0, drop=()):
    out = ['some banner']
    if cfg is not None:
        out += [cfg_line(cfg, drop)] * (1 + extra_cfg)
    for n, (sc, nm) in enumerate(keys):
        out.append('[PERF ][time=               19999] %s: %s,  %d' % (sc, nm, 100 + n + (bump if n == 0 else 0)))
    return '\n'.join(out) + '\n'


def run(gtxt, itxt):
    d = pathlib.Path(tempfile.mkdtemp())
    (d / 'g.log').write_text(gtxt)
    (d / 'i.log').write_text(itxt)
    p = subprocess.run([sys.executable, str(HERE / 'perf_compare.py'),
                        str(d / 'g.log'), str(d / 'i.log'), '--all'],
                       stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
    shutil.rmtree(str(d))
    return p.returncode, p.stdout.decode(errors='replace')


def mod(**kw):
    d = dict(GOOD)
    d.update(kw)
    return d


rc, out = run(log_text(GOOD), log_text(GOOD))
check('P0 两侧 Z0 且一致 → 比较照做、rc 0', rc == 0 and '初值设定闸: 两侧 Z0' in out,
      'rc=%d\n%s' % (rc, out[-500:]))

cases = [
    ('N1 golden 缺 [PERFCFG]', log_text(None), log_text(GOOD), '缺 [PERFCFG]'),
    ('N2 impl 缺 [PERFCFG]', log_text(GOOD), log_text(None), '缺 [PERFCFG]'),
    ('N3 golden 编译期定义了 RANDOMIZE_*', log_text(mod(randomize_defines='REG_INIT,MEM_INIT,')),
     log_text(GOOD), 'RANDOMIZE_'),
    ('N4 impl 编译期只剩 RANDOMIZE_GARBAGE_ASSIGN 也不行', log_text(GOOD),
     log_text(mod(randomize_defines='GARBAGE_ASSIGN,')), 'RANDOMIZE_'),
    ('N5 两侧都没给 +vcs+initreg+0（random）',
     log_text(mod(initreg_plusarg='random', initreg_probe_reg='45c29f8be8b2dad1',
                  initreg_probe_mem='22568d44')),
     log_text(mod(initreg_plusarg='random', initreg_probe_reg='0bad0bad0bad0bad',
                  initreg_probe_mem='12345678')), '+vcs+initreg+random'),
    ('N6 impl +vcs+initreg+1', log_text(GOOD),
     log_text(mod(initreg_plusarg='1', initreg_probe_reg='ffffffffffffffff',
                  initreg_probe_mem='ffffffff')), '+vcs+initreg+1'),
    ('N7 golden 编译期没开 initreg（探针为 x）', log_text(mod(initreg_probe_reg='xxxxxxxxxxxxxxxx',
                                                    initreg_probe_mem='xxxxxxxx')),
     log_text(GOOD), '没开 +vcs+initreg+random'),
    ('N8 plusarg 写着 0 但探针不是 0（自述与实测不符）', log_text(GOOD),
     log_text(mod(initreg_probe_mem='00000001')), '不是 0'),
    ('N9 两侧 workload 不一致', log_text(GOOD),
     log_text(mod(workload='/x/ready-to-run/dhrystone.bin')), 'workload 不一致'),
    ('N10 两侧 seed 不一致', log_text(GOOD), log_text(mod(seed='987654321')), 'seed 不一致'),
    ('N11 两侧 max_cycles 不一致', log_text(mod(max_cycles='30000')), log_text(GOOD),
     'max_cycles 不一致'),
    ('N12 一侧 [PERFCFG] 重复两条', log_text(GOOD, extra_cfg=1), log_text(GOOD), '应恰好 1 条'),
    ('N13 一侧缺字段 workload', log_text(GOOD), log_text(GOOD, drop=('workload',)), '缺字段 workload'),
    ('N14 一侧没给 +workload', log_text(mod(workload='absent')),
     log_text(mod(workload='absent')), '没有 +workload'),
]
for name, g, i, want in cases:
    rc, out = run(g, i)
    check(name + ' → rc 3', rc == 3 and want in out and '不做比较' in out,
          'rc=%d, 想看到 %r\n%s' % (rc, want, out[-400:]))

rc, out = run(log_text(GOOD), log_text(GOOD, bump=1))
check('N15 设定全对、B_CONTROL 差 1 → rc 1（无容差）', rc == 1 and 'BLOCKING 1' in out,
      'rc=%d\n%s' % (rc, out[-400:]))

print()
if fails:
    print('★test_perf_init_contract: %d 条未过★' % len(fails))
    for f in fails:
        print('   ' + f)
    sys.exit(1)
print('test_perf_init_contract: 全部通过（P0 绿；N1-N14 设定闸各红在 rc 3；N15 无容差红在 rc 1）')
