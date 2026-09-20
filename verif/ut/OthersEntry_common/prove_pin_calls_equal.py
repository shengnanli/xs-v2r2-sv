#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""prove_pin_calls_equal.py —— 证明改钉点文件的守卫**没有动过发射出去的钉点调用**。

## 为什么需要它

`fm_pins*.tcl` **在证明闭包里**（receipt 的 proof_config.pin_scripts 会记它的 sha256）。
按本 lane 自己提的那条规矩 ——「别把不同前提下产出的结果并列成一张表」——
只要动了它，先前那些 receipt 就成了旧前提，本该重跑。

但如果改动**可证**只碰守卫（怎么数、数不对怎么中止），而发射出去的
`set_user_match` 调用一个字没变，那"钉了哪些点"这个维度上闭包没变，
先前的 receipt 仍然有效。**这件事必须是量出来的，不是我说了算。**

## ★为什么不是"逐行 diff 含 set_user_match 的行"★

整理者给的判据是"把两版里所有 `set_user_match` 行提取出来逐字节比对"。
那条判据假定钉点文件把 N 个调用**写成 N 行字面量**。本 lane 的钉点文件不是
那个形态：它是 `foreach _pair { ...N 行数据... }` 加**一行**模板化的调用。
照字面比，那一行必然不同（`catch {set_user_match ...}` -> `[set_user_match ...]`），
但那恰恰是守卫本身，不是调用集合。

所以这里换一个**更强**的判据：把 `set_user_match` 换成一个记录参数的桩，
用 tclsh 真跑一遍两个版本，逐字节比对**实际发生的调用序列**（含顺序与重复）。
它捕获的是行为不是文本，模板化与否都适用。

## 用法

    python3 prove_pin_calls_equal.py <旧文件目录> <变体名> [...]

对每个变体，跑 old/<变体>.tcl 与仓里当前的 verif/ut/<变体>/fm_pins_pre.tcl，
比对调用序列。全部相同则退出 0。
"""
import pathlib, subprocess, sys, tempfile, hashlib

HERE = pathlib.Path(__file__).resolve().parent
REPO = HERE.parents[2]

HARNESS = '''
set top {top}
set _calls 0
proc set_user_match {{a b}} {{
    puts "CALL $a $b"
    return 1
}}
source {pinfile}
'''


def calls_of(pinfile, top):
    """用 tclsh 跑一遍钉点文件，把实际发生的 set_user_match 调用序列抓出来。"""
    with tempfile.NamedTemporaryFile('w', suffix='.tcl', delete=False) as f:
        f.write(HARNESS.format(top=top, pinfile=str(pinfile)))
        h = f.name
    try:
        r = subprocess.run(['tclsh', h], stdout=subprocess.PIPE,
                           stderr=subprocess.STDOUT, universal_newlines=True)
        if r.returncode != 0:
            return None, f'tclsh rc={r.returncode}: {r.stdout[-400:]}'
        lines = [l for l in r.stdout.split('\n') if l.startswith('CALL ')]
        return lines, None
    finally:
        (pathlib.Path(h).exists() and pathlib.Path(h).unlink())


def main(argv):
    olddir = pathlib.Path(argv[0])
    tops = argv[1:]
    rc = 0
    print(f'{"变体":<20}{"旧调用数":>10}{"新调用数":>10}  结论')
    for top in tops:
        old = olddir / f'{top}.tcl'
        new = REPO / 'verif' / 'ut' / top / 'fm_pins_pre.tcl'
        if not old.exists():
            print(f'{top:<20}{"-":>10}{"-":>10}  ★旧文件不存在，无法证明★')
            rc = 1
            continue
        a, ea = calls_of(old, top)
        b, eb = calls_of(new, top)
        if ea or eb:
            print(f'{top:<20}{"-":>10}{"-":>10}  ★跑不起来★ {ea or eb}')
            rc = 1
            continue
        ha = hashlib.sha256('\n'.join(a).encode()).hexdigest()
        hb = hashlib.sha256('\n'.join(b).encode()).hexdigest()
        same = (a == b)
        print(f'{top:<20}{len(a):>10}{len(b):>10}  '
              + ('逐字节相同 ' + ha[:16] if same else '★不同★'))
        if not same:
            rc = 1
            for i, (x, y) in enumerate(zip(a, b)):
                if x != y:
                    print(f'    首个差异 @{i}:\n      旧 {x}\n      新 {y}')
                    break
            if len(a) != len(b):
                print(f'    长度不同：旧 {len(a)} 新 {len(b)}')
    print()
    print('结论：' + ('★守卫专属改动：调用序列逐字节相同，先前 receipt 继续有效★'
                     if rc == 0 else
                     '★调用集合变了：按规矩必须在一个 commit 上重出全部 receipt★'))
    return rc


if __name__ == '__main__':
    sys.exit(main(sys.argv[1:]))
