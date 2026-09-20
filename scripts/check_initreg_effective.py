#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""check_initreg_effective.py —— 证明 `+vcs+initreg` **确实改变了待测状态**（codex 0168）。

## 为什么"两轮都绿"不够

CONVENTIONS 已经写了：★两轮都绿 ≠ 复位域正确★。若被测件的可观测行为对上电初值
不敏感，两轮必然都绿，**这时它证明不了任何事**。本仓还有一个更凶的形态：
★非打包数组混合驱动会**静默关掉** `+vcs+initreg`★（TLBNonBlock 实测，VCS 0 error
0 warning）—— 该响的闸被静默变成空转，而"两轮都绿"看起来一模一样。

所以 0168 要的不是"跑了两轮"，是**把 initreg 真的改了状态这件事本身测出来**。

## ★为什么不用"两轮日志 md5 不等"★（本 lane 实测否掉的方案）

我先试了这个直觉方案，当场发现它是 **fail-open** 的：

    $ diff <(去掉命令行/时间戳 sim_1.log) <(去掉命令行/时间戳 sim_ir0_1.log)
    (无差异)

EntriesFaluFmac 的两轮日志**除了命令行那一行完全相同** —— checks、errors、
17 条覆盖计数逐个相等。也就是说：
  · 直接比 md5 会因为**命令行里带着 `+vcs+initreg+0/random`** 而永远不等 ⇒ 恒绿；
  · 去掉命令行再比，则永远相等 ⇒ 恒红。
两个方向都不是在量 initreg。**观测点选错了**：末尾汇总看的是比较窗口打开之后的
行为，而 initreg 影响的是上电瞬间的寄存器内容。

## 本脚本的做法：把观测点放到上电瞬间的寄存器上

生成一个只接 `clock`/`reset` 的探针 tb（SV 允许按名部分连接，其余端口悬空），
例化**真的 impl wrapper**，在 `reset` 还没释放、时钟还没跑之前把三类信号打出来：

| 类 | 例子 | 期望 |
|---|---|---|
| **不复位**寄存器 | `r_payload` / `r_psrc`（golden 的 entryReg_* 整批不复位） | ★两档必须不同★，且 `+0` 档必须全 0 |
| **有复位**寄存器 | `valid_reg`（golden 只有 validReg/enqDelayValidReg 带复位） | 两档相同（复位值压过初值） |

第三行是**判据自己的分辨力证明**：如果探针根本没读到设计内部（路径写错、
被优化掉），不复位那一类也会"两档相同"，那时第一行和第三行会一起变绿 ——
所以第一行要求**不同**、第三行要求**相同**，两个方向同时成立才算通过。

用法:
    python3 scripts/check_initreg_effective.py <UT目录裸名> [--keep]
    python3 scripts/check_initreg_effective.py --selftest   # 判据负测（不占 VCS 时判据逻辑）
"""
import argparse
import os
import pathlib
import re
import shutil
import subprocess
import sys
import tempfile

REPO = pathlib.Path(__file__).resolve().parents[1]

# (标签, 层次路径后缀, 期望)  —— 路径前缀由探针 tb 的实例名决定
#   'differ' = 两档必须不同（不复位寄存器）
#   'same'   = 两档必须相同（有复位寄存器）★这一行是判据的分辨力证明★
PROBES = [
    ('r_payload  (不复位)', 'u_core.g_entry[0].u_e.r_payload', 'differ'),
    ('r_psrc     (不复位)', 'u_core.g_entry[0].u_e.r_psrc',    'differ'),
    ('valid_reg  (有复位)', 'u_core.g_entry[0].u_e.valid_reg', 'same'),
]

TB = """// 自动生成的 initreg 探针 —— 只接 clock/reset，其余端口悬空（SV 按名部分连接）。
// 目的：在复位期把"不复位寄存器"的上电内容打出来，证明 +vcs+initreg 真的改了它。
module tb;
  logic clock = 1'b0;
  logic reset = 1'b1;
  {top} u (.clock(clock), .reset(reset));
  initial begin
    #1;
{dumps}
    $finish;
  end
endmodule
"""


def build_tb(top):
    dumps = '\n'.join(
        '    $display("PROBE %s = %%h", u.%s);' % (label, path)
        for label, path, _ in PROBES)
    return TB.format(top=top, dumps=dumps)


def parse(out):
    return dict(re.findall(r'PROBE (\S.*?) = (\S+)', out))


def run(cmd, cwd):
    p = subprocess.run(cmd, cwd=str(cwd), stdout=subprocess.PIPE,
                       stderr=subprocess.STDOUT, universal_newlines=True)
    return p.returncode, p.stdout


def judge(v0, vr):
    """纯判据：给两档的 PROBE 表，返回 (rc, 逐行结果)。抽出来才好负测。"""
    rows, rc = [], 0
    for label, _path, want in PROBES:
        a, b = v0.get(label), vr.get(label)
        if a is None or b is None:
            rows.append((label, a, b, want, 'MISS', False))
            rc = 1
            continue
        if want == 'differ':
            ok = (a != b) and set(a.lower()) <= set('0')   # +0 档必须全 0
            why = 'differ 且 +0 档全 0'
        else:
            ok = (a == b)
            why = 'same（复位值压过初值）'
        rows.append((label, a, b, want, why, ok))
        rc |= 0 if ok else 1
    return rc, rows


def selftest():
    """★判据必须能证明自己有分辨力★：造四种输入，要求判决各不相同。"""
    L = [p[0] for p in PROBES]
    cases = [
        ('正例：不复位两档不同、有复位两档相同',
         {L[0]: '0000', L[1]: '00', L[2]: '0'},
         {L[0]: 'a3f1', L[1]: '5c', L[2]: '0'}, 0),
        ('★initreg 被静默关掉：不复位那两个也两档相同★',
         {L[0]: '0000', L[1]: '00', L[2]: '0'},
         {L[0]: '0000', L[1]: '00', L[2]: '0'}, 1),
        ('探针读到了、但 +0 档不是全 0（说明 +0 没生效）',
         {L[0]: '00f0', L[1]: '00', L[2]: '0'},
         {L[0]: 'a3f1', L[1]: '5c', L[2]: '0'}, 1),
        ('★有复位的那个也跟着变 —— 探针路径可疑/复位域写错★',
         {L[0]: '0000', L[1]: '00', L[2]: '0'},
         {L[0]: 'a3f1', L[1]: '5c', L[2]: '1'}, 1),
        ('探针整张表都没读到（路径写错/被优化掉）', {}, {}, 1),
    ]
    rc = 0
    print('check_initreg_effective --selftest:')
    for name, a, b, want in cases:
        got, _ = judge(a, b)
        ok = got == want
        rc |= 0 if ok else 1
        print(f'  rc={got} 期望 {want}  {"OK" if ok else "★FAIL★"}  {name}')
    # 元负例：把判据换成恒 0，正例之外的四行必须至少有一行不再是期望值
    g = globals()
    real = g['judge']
    g['judge'] = lambda a, b: (0, [])
    blanket_all_pass = all(judge(a, b)[0] == want for _n, a, b, want in cases)
    g['judge'] = real
    meta_ok = not blanket_all_pass
    rc |= 0 if meta_ok else 1
    print(f'  meta_blanket  {"PASS（判据换成恒 0 后不再全对）" if meta_ok else "★FAIL：判据恒绿★"}')
    print('initreg 判据负测:', 'PASS' if rc == 0 else 'FAIL')
    return rc


def main(argv=None):
    ap = argparse.ArgumentParser()
    ap.add_argument('ut_dir', nargs='?')
    ap.add_argument('--selftest', action='store_true')
    ap.add_argument('--keep', action='store_true', help='保留探针工作目录便于复核')
    a = ap.parse_args(argv)
    if a.selftest:
        return selftest()
    if not a.ut_dir:
        ap.error('要么给 UT 目录裸名，要么 --selftest')

    utdir = REPO / 'verif' / 'ut' / a.ut_dir
    mk = (utdir / 'Makefile').read_text()
    top = re.search(r'^MODULE\s*=\s*(\S+)', mk, re.M).group(1)
    srcs = [REPO / 'rtl' / 'backend' / 'xs_iq_entries_core.sv',
            REPO / 'rtl' / 'backend' / f'{top}.sv']

    work = pathlib.Path(tempfile.mkdtemp(prefix=f'xsv2-initreg-{top}-'))
    try:
        (work / 'tb_probe.sv').write_text(build_tb(top))
        env_vcs = ['vcs', '-full64', '-sverilog', '-timescale=1ns/1ps',
                   '+define+SYNTHESIS', '+vcs+initreg+random',
                   '-top', 'tb', '-o', 'simv']
        env_vcs += [str(s) for s in srcs] + ['tb_probe.sv']
        os.environ['VCS_ARCH_OVERRIDE'] = 'linux'
        rc, out = run(env_vcs, work)
        if rc != 0:
            print('探针编译失败（不是结论，是没测成，必须查）:')
            print(out[-2000:])
            return 2
        rc0, o0 = run(['./simv', '+vcs+initreg+0'], work)
        rcr, orr = run(['./simv', '+vcs+initreg+random', '+ntb_random_seed=7'], work)
        if rc0 or rcr:
            print('探针运行失败（没测成）'); print(o0[-800:], orr[-800:]); return 2
        v0, vr = parse(o0), parse(orr)
        rc, rows = judge(v0, vr)
        print(f'=== initreg 有效性: {top} ===')
        print(f'{"信号":24s} {"+0":>18s} {"+random":>18s}  期望      判决')
        for label, x, y, want, why, ok in rows:
            print(f'{label:24s} {str(x):>18s} {str(y):>18s}  {want:8s} '
                  f'{"OK" if ok else "★FAIL★"}  {why}')
        if rc == 0:
            print('⇒ +vcs+initreg 确实改变了待测状态；且有复位的那个没被带偏 '
                  '（两个方向同时成立，不是恒绿）')
        else:
            print('⇒ ★没能证明 initreg 改变了状态★ —— 两轮 UT 在复位域上等于空转，'
                  '先查非打包数组混合驱动（scripts/check_array_mixed_drive.py）')
        if a.keep:
            print(f'探针目录保留: {work}')
        return rc
    finally:
        if not a.keep:
            shutil.rmtree(str(work), ignore_errors=True)


if __name__ == '__main__':
    sys.exit(main())
