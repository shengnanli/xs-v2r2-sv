#!/usr/bin/env python3
"""证明 `+vcs+initreg` **确实改变了 OthersEntry 的待测状态**。

## 为什么「两轮都绿」不够

CONVENTIONS 已经写了：★两轮都绿 ≠ 复位域正确★。若被测件的可观测行为对上电初值
不敏感，两轮必然都绿，**这时它证明不了任何事**。本仓还有更凶的形态：
★非打包数组混合驱动会**静默关掉** `+vcs+initreg`★（0 error 0 warning），
该响的闸被静默变成空转，而「两轮都绿」看起来一模一样。

## ★「两轮日志 md5 不等」这个方案是 fail-open 的，不要用★

方法与这条结论都来自 `agent/entries-rest3` 的 `scripts/check_initreg_effective.py`
（commit 417bb13f）。那边实测：两轮日志去掉命令行后**完全相同** ——
直接比 md5 会因为命令行里带着 `+vcs+initreg+0/random` 而永远不等（恒绿），
去掉命令行再比则永远相等（恒红）。两个方向都不是在量 initreg。
**观测点选错了**：末尾汇总看的是比较窗口打开之后的行为，
而 initreg 影响的是上电瞬间的寄存器内容。

本 lane 独立复现了这一点：OthersEntry_72 seed=1 两档日志除时间戳外
checks / errors / 13 条覆盖计数逐个相等。

## 做法：把观测点放到上电瞬间的寄存器上

生成一个只接 clock/reset 的探针 tb（SV 按名部分连接，其余端口悬空），
例化**真的 impl wrapper**，在复位还没释放时打三类信号：

| 类 | 例子 | 期望 |
|---|---|---|
| 不复位寄存器 | `r_payload` / `r_psrc` | ★两档必须不同，且 +0 档全 0★ |
| 有复位寄存器 | `valid_reg` | 两档必须**相同** |

第二行是**判据自己的分辨力证明**：探针要是根本没读到设计内部（路径写错、
被优化掉），不复位那一类也会「两档相同」，两行会一起绿 ——
所以一个要求"不同"、一个要求"相同"，两个方向同时成立才算过。

★与 Entries 那份的唯一差别是层次路径★（那边 u.u_core.g_entry[0].u_e.*，
这边 u.u_entry.*）。等那份脚本进 main，应把 PROBES 变成参数、两份合一，
本文件随之删除 —— 这条已写进 lane 汇报。

用法:
    python3 check_initreg_effective.py <变体名> [--keep]
    python3 check_initreg_effective.py --selftest
"""
import argparse, os, pathlib, re, shutil, subprocess, sys, tempfile

HERE = pathlib.Path(__file__).resolve().parent
REPO = HERE.parents[2]

# (标签, u.<path>, 期望)  differ = 两档必须不同（不复位）；same = 两档必须相同（有复位）
PROBES = [
    ('r_payload  (不复位)', 'u_entry.r_payload', 'differ'),
    ('r_psrc     (不复位)', 'u_entry.r_psrc',    'differ'),
    ('valid_reg  (有复位)', 'u_entry.valid_reg', 'same'),
]

TB = """// 自动生成的 initreg 探针 —— 只接 clock/reset，其余端口悬空（SV 按名部分连接）。
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


def judge(v0, vr):
    rows, rc = [], 0
    for label, _p, want in PROBES:
        a, b = v0.get(label), vr.get(label)
        if a is None or b is None:
            rows.append((label, a, b, 'MISS', False)); rc = 1; continue
        if want == 'differ':
            ok = (a != b) and set(a.lower()) <= set('0')
            why = 'differ 且 +0 档全 0'
        else:
            ok = (a == b); why = 'same（复位值压过初值）'
        rows.append((label, a, b, why, ok))
        rc |= 0 if ok else 1
    return rc, rows


def selftest():
    L = [p[0] for p in PROBES]
    cases = [
        ('正例：不复位两档不同、有复位两档相同',
         {L[0]: '0000', L[1]: '00', L[2]: '0'},
         {L[0]: 'a3f1', L[1]: '5c', L[2]: '0'}, 0),
        ('★initreg 被静默关掉：不复位那两个也两档相同★',
         {L[0]: '0000', L[1]: '00', L[2]: '0'},
         {L[0]: '0000', L[1]: '00', L[2]: '0'}, 1),
        ('+0 档不是全 0（说明 +0 没生效）',
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
        print(f'  [{"OK" if ok else "FAIL"}] {name} -> rc={got}（期望 {want}）')
        rc |= 0 if ok else 1
    print('负测', 'PASS' if rc == 0 else 'FAIL')
    return rc


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('variant', nargs='?')
    ap.add_argument('--selftest', action='store_true')
    ap.add_argument('--keep', action='store_true')
    a = ap.parse_args()
    if a.selftest:
        return selftest()
    top = a.variant
    work = pathlib.Path(tempfile.mkdtemp(prefix=f'xsv2-oeinitreg-{top}-'))
    try:
        # UT 侧编译的是 derive 出来的 _xs 副本，这里直接用仓里的原文件（模块名即 top）
        for f in ('xs_iq_entries_core.sv', f'{top}.sv'):
            shutil.copy(str(REPO / 'rtl' / 'backend' / f), str(work / f))
        dumps = '\n'.join('    $display("PROBE %s = %%h", u.%s);' % (l, p)
                          for l, p, _ in PROBES)
        (work / 'tb_probe.sv').write_text(TB.format(top=top, dumps=dumps))
        env = dict(os.environ, VCS_ARCH_OVERRIDE='linux')
        cmd = ['vcs', '-full64', '-sverilog', '-timescale=1ns/1ps',
               '+define+SYNTHESIS', '+vcs+initreg+random', '-top', 'tb',
               'xs_iq_entries_core.sv', f'{top}.sv', 'tb_probe.sv',
               '-o', 'simv_probe']
        p = subprocess.run(cmd, cwd=str(work), stdout=subprocess.PIPE,
                           stderr=subprocess.STDOUT, universal_newlines=True, env=env)
        if p.returncode != 0:
            print(p.stdout[-3000:]); print('探针编译失败'); return 1
        outs = {}
        for tag in ('0', 'random'):
            r = subprocess.run(['./simv_probe', f'+vcs+initreg+{tag}',
                                '+ntb_random_seed=1'],
                               cwd=str(work), stdout=subprocess.PIPE,
                               stderr=subprocess.STDOUT, universal_newlines=True)
            outs[tag] = dict(re.findall(r'PROBE (\S.*?) = (\S+)', r.stdout))
        rc, rows = judge(outs['0'], outs['random'])
        print(f'[{top}] initreg 有效性探针：')
        for label, x, y, why, ok in rows:
            sx = (x[:24] + '…') if x and len(x) > 24 else x
            sy = (y[:24] + '…') if y and len(y) > 24 else y
            print(f'  [{"OK" if ok else "FAIL"}] {label}  +0={sx}  +random={sy}  ({why})')
        print('结论:', '★+vcs+initreg 确实改变了待测状态★' if rc == 0
              else '★未能证明 initreg 生效 —— 那两轮 UT 可能是空转★')
        return rc
    finally:
        if not a.keep:
            shutil.rmtree(str(work), ignore_errors=True)


if __name__ == '__main__':
    sys.exit(main())
