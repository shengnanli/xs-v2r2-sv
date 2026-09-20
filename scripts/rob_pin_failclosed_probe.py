#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""rob_pin_failclosed_probe.py —— `set_user_match` 钉一个**不存在**的名字，会怎样？

## 为什么非问不可

Rob 的钉点文件（verif/ut/Rob/fm_pins.tcl，169,168 个 pin）整个 fail-closed 的
性质押在一件事上：

    if {[catch {set_user_match $r $i}] == 0} {incr _pinned}
    ...
    if {$_pinned != $_want} { puts ...; exit 3 }

**只有当 `set_user_match` 遇到不存在的名字会抛 Tcl 异常时，这段才有意义。**
如果它不抛，`_pinned` 恒等于 `_want`，那行 `exit 3` 永远不会走到 ——
"pinned N of N" 就是一句废话，而它正是本轮说好的验收步骤之一。

`gen_rob_pins.py --selftest` 证不了这件事：它在纯 tclsh 里把 `set_user_match`
**桩掉**，而桩的行为（refuse1 / refuseall 模式会 `error`）正是这里要验的那个
假设本身。★用桩去验桩的假设，是一个闭环★。

另一条 lane（Entries）在 verif/ut/EntriesFaluFmac/fm_pins_pre.tcl:13213 写下了
相反的实测结论：「set_user_match 喂一个完全不存在的路径照样返回 0，catch 抓不到」。
按本仓规矩（排除法做对一半就停下是失误），不直接采信别人的测量，也不直接采信
我们自己的假设 —— 自己跑一次最小实验。

## 实验

用 rob_array_idiom_canary 的那对小设计（ref = firtool 扁平标量，
impl = soamux 非打包数组 + 循环下标，两侧功能等价），跑一次 fm_shell，
在 match 之后依次：

  G  钉一对**真实存在**的名字        -> 预期 catch 不响
  X1 钉一个**impl 侧不存在**的名字    -> catch 响不响？
  X2 钉一个**ref 侧不存在**的名字     -> catch 响不响？
  X3 两侧都不存在                     -> catch 响不响？

每条都打印 `PROBE <tag> catch=<0|1> rc=<返回值> msg=<...>`，并在最后统计
fm.log 里行首锚定的 `^ *Error:` 行数（Entries lane 给的那条替代判据）。

结论**不由本脚本预设**：它只把四条实测打印出来并写进 verdict，
`--check` 用一份已入库的期望（docs/rob_pin_failclosed.tsv）比对，
第一次跑时用 --write 落盘。

用法
  python3 scripts/rob_pin_failclosed_probe.py --run [--dir D]
  python3 scripts/rob_pin_failclosed_probe.py --run --write   # 落盘期望
  python3 scripts/rob_pin_failclosed_probe.py --check         # 重跑并比对
"""
import argparse
import os
import re
import subprocess
import sys
import tempfile

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.dirname(HERE)
LEDGER = os.path.join(REPO, 'docs', 'rob_pin_failclosed.tsv')
sys.path.insert(0, HERE)
import rob_array_idiom_canary as canary

N = 8           # 条目数：只要够 match 出多于一个 DFF 就行，越小越快
AW = 8          # 下标位宽刻意 > log2(N)，与 Rob 的 160/8 同形

TCL = r'''set_app_var verification_merge_duplicated_registers true
read_sverilog -container r -libname WORK -05 ./Canary_ref.sv
set_top r:/WORK/Canary
read_sverilog -container i -libname WORK ./Canary_soamux.sv
set_top i:/WORK/Canary
match

proc probe {tag rpath ipath} {
    set rc [catch {set_user_match $rpath $ipath} msg]
    # 一行一条，行首锚定，便于机械提取；msg 里的换行压成空格。
    regsub -all {\n} $msg { } msg
    puts "PROBE $tag catch=$rc msg=$msg"
}

# 1 位字段两侧都没有 [b] 下标（gen_rob_pins 的命名契约就是这么写的）；
# 多位字段两侧都带位号 —— GOOD_W 用 pdest[3] 把这一半也验上。
probe GOOD   r:/WORK/Canary/ent_1_valid_reg       i:/WORK/Canary/ent_valid_reg\[1\]
probe GOOD_W r:/WORK/Canary/ent_2_pdest_reg\[3\]  i:/WORK/Canary/ent_pdest_reg\[2\]\[3\]
probe X_IMPL r:/WORK/Canary/ent_3_valid_reg       i:/WORK/Canary/no_such_reg_zzz\[3\]
probe X_REF  r:/WORK/Canary/no_such_reg_zzz       i:/WORK/Canary/ent_valid_reg\[4\]
probe X_BOTH r:/WORK/Canary/no_such_reg_aaa       i:/WORK/Canary/no_such_reg_bbb
puts "PROBE_DONE"
exit 0
'''

TAGS = ['GOOD', 'GOOD_W', 'X_IMPL', 'X_REF', 'X_BOTH']


def build(d):
    with open(os.path.join(d, 'Canary_ref.sv'), 'w') as f:
        f.write(canary.gen_ref(N, AW))
    with open(os.path.join(d, 'Canary_soamux.sv'), 'w') as f:
        f.write(canary.gen_impl('soamux', N, AW))
    with open(os.path.join(d, 'probe.tcl'), 'w') as f:
        f.write(TCL)


def run(d):
    build(d)
    log = os.path.join(d, 'fm.log')
    with open(log, 'w') as f:
        rc = subprocess.call(
            ['fm_shell', '-64', '-work_path', os.path.join(d, 'fmw'),
             '-file', os.path.join(d, 'probe.tcl')],
            cwd=d, stdin=subprocess.DEVNULL, stdout=f,
            stderr=subprocess.STDOUT)
    txt = open(log, errors='replace').read()
    rows = {}
    for m in re.finditer(r'^PROBE (\w+) catch=(\d+) msg=(.*)$', txt, re.M):
        rows[m.group(1)] = (int(m.group(2)), m.group(3).strip())
    err_lines = len(re.findall(r'^ *Error:', txt, re.M))
    done = 'PROBE_DONE' in txt
    return rc, rows, err_lines, done, log


def render(rc, rows, err_lines, done):
    out = ['# rob_pin_failclosed_probe.py 生成，勿手改。'
           '重跑：python3 scripts/rob_pin_failclosed_probe.py --run --write',
           '# 问题：set_user_match 钉一个不存在的名字，catch 抓不抓得到？',
           '# 这是 verif/ut/Rob/fm_pins.tcl 整个 fail-closed 性质的地基。',
           '# fm_shell rc=%d  脚本跑完=%s  fm.log 里行首 `Error:` 行数=%d'
           % (rc, done, err_lines),
           'tag\tcatch\tmsg']
    for t in TAGS:
        c, m = rows.get(t, (-1, '(没跑到)'))
        out.append('%s\t%d\t%s' % (t, c, m[:200]))
    out.append('# 读法（列 msg 就是 set_user_match 的**返回值**，因为 catch 没抛）：')
    out.append('#   catch 全是 0  -> ★set_user_match 从不抛 Tcl 异常★，'
               '`if {[catch ...]}` 计数法是空的，')
    out.append('#                    "pinned N of N" 恒成立，exit 3 永远走不到。')
    out.append('#   返回值有分辨力 -> 钉上了返回 1，钉不上返回 0。'
               '所以正确的写法是 `if {[set_user_match $r $i]} {incr _pinned}`，')
    out.append('#                    ★不是★ `if {[catch {set_user_match $r $i}] == 0}`。')
    out.append('#   行首 Error 行数 -> 每个不存在的名字一行 FM-036；'
               '3 个坏 pin 里有 4 个坏名字，正好 4 行。')
    out.append('#                    这是第二条独立判据（不依赖返回值），'
               '两条都该用。')
    return '\n'.join(out) + '\n'


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--dir')
    ap.add_argument('--run', action='store_true')
    ap.add_argument('--write', action='store_true')
    ap.add_argument('--check', action='store_true')
    a = ap.parse_args()
    if not (a.run or a.check):
        ap.error('pick --run or --check')
    d = a.dir or tempfile.mkdtemp(prefix='rob-pin-failclosed-')
    os.makedirs(d, exist_ok=True)
    rc, rows, err_lines, done, log = run(d)
    text = render(rc, rows, err_lines, done)
    print(text, end='')
    print('# log %s' % log, file=sys.stderr)
    if not done:
        print('★fm_shell 没跑到 PROBE_DONE —— 实验无效，不要读上面的表★',
              file=sys.stderr)
        return 2
    if a.write:
        with open(LEDGER, 'w') as f:
            f.write(text)
        print('# 已写 %s' % LEDGER, file=sys.stderr)
        return 0
    if a.check:
        if not os.path.exists(LEDGER):
            print('FAIL: %s 不存在' % LEDGER, file=sys.stderr)
            return 1
        if open(LEDGER).read() != text:
            print('FAIL: 实测与 %s 不一致 —— fm_shell 行为变了，'
                  '钉点判据要重新论证' % LEDGER, file=sys.stderr)
            return 1
        print('rob_pin_failclosed_probe --check: 与入库实测一致', file=sys.stderr)
    return 0


if __name__ == '__main__':
    sys.exit(main())
