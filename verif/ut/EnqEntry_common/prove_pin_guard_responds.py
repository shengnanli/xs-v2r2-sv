#!/usr/bin/env python3
"""prove_pin_guard_responds.py —— 证明 EnqEntry* 钉点文件的 fail-closed 守卫**会响**。

## 为什么需要这个脚本

本族 9 个 fm_pins_pre.tcl 原先的计数写法是

    if {[catch {set_user_match $r $i} _msg]} { incr _miss } else { incr _n }

而 `set_user_match` **从不抛 Tcl 异常**（名字存在返回 1，不存在返回 0 并往 fm.log
写 `Error: Unknown name: ... (FM-036)`）。于是 `_miss` 恒为 0、`_n` 恒等于目标数，
文件尾那两道 `if {...} {error ...}` **一道都走不到** —— 两道都是空的。
第二道尤其危险：它建立在第一道的中间量 `_n` 上，把第一道的空洞原样继承了过来。
（CONVENTIONS「新判据建立在旧判据的中间量上时，会把旧判据的空洞一并继承」）

改成返回值计数之后，「守卫会响」这件事必须是**跑出来的**，不是推出来的。
本脚本用 tclsh 真跑钉点文件，`set_user_match` 换成可控桩，逐个 case 对照：

  accept_all  桩恒返回 1  -> 不许 error，且 _n 必须等于文件里写死的期望数
  refuse_one  第 k 条返回 0 -> 必须 error，且错在 EE_PIN_REFUSED
  refuse_all  桩恒返回 0  -> 必须 error
  throw_never 桩恒返回 1 但另有一条名字不存在时的旧行为（catch 恒 0）已不再被依赖

并且★元判据★：把守卫拆掉（模拟旧的 catch 写法）之后 refuse_one 必须**不再**报错 ——
否则 "refuse_one 报错" 可能来自别的地方，与守卫无关。

用法:
    python3 prove_pin_guard_responds.py            # 9 个变体全跑
    python3 prove_pin_guard_responds.py <变体> ...
"""
import pathlib, re, subprocess, sys, tempfile

HERE = pathlib.Path(__file__).resolve().parent
REPO = HERE.parents[2]
MODS = ['EnqEntry', 'EnqEntry_4', 'EnqEntry_6', 'EnqEntry_8', 'EnqEntry_10',
        'EnqEntry_12', 'EnqEntry_14', 'EnqEntry_16', 'EnqEntry_18']

# 桩：按 mode 决定第 n 次调用的返回值。`top` 由外层设成变体名。
HARNESS = '''
set ::calls 0
proc set_user_match {r i} {
  incr ::calls
  switch $::MODE {
    accept_all { return 1 }
    refuse_all { return 0 }
    refuse_one { return [expr {$::calls == $::K ? 0 : 1}] }
  }
}
set top "%(mod)s"
set ::MODE "%(mode)s"
set ::K %(k)d
if {[catch {source "%(pins)s"} _e]} { puts "TCL_ERROR: $_e" ; exit 7 }
puts "TCL_OK calls=$::calls n=$_n miss=$_miss"
'''


def run(mod, pins_path, mode, k=1):
    with tempfile.NamedTemporaryFile('w', suffix='.tcl', delete=False) as f:
        f.write(HARNESS % dict(mod=mod, mode=mode, k=k, pins=pins_path))
        h = f.name
    p = subprocess.run(['tclsh', h], stdout=subprocess.PIPE,
                       stderr=subprocess.PIPE, universal_newlines=True)
    pathlib.Path(h).unlink()
    return p.returncode, (p.stdout + p.stderr).strip()


def expected_count(txt):
    m = re.search(r'if \{\$_n != (\d+)\}', txt)
    return int(m.group(1))


def strip_guards(txt):
    """模拟旧写法：把两道 fail-closed 判据删掉，用于元判据对照。"""
    return re.sub(r'^\s*if \{\$_(miss|n) != .*\n', '', txt, flags=re.M)


def main(argv):
    mods = [a for a in argv if not a.startswith('-')] or MODS
    bad = 0
    for mod in mods:
        pins = REPO / 'verif' / 'ut' / mod / 'fm_pins_pre.tcl'
        txt = pins.read_text()
        want = expected_count(txt)

        rc, out = run(mod, str(pins), 'accept_all')
        ok_a = rc == 0 and f'n={want} ' in out + ' '
        rc1, out1 = run(mod, str(pins), 'refuse_one', k=max(1, want // 2))
        ok_b = rc1 == 7 and 'EE_PIN_REFUSED' in out1
        rc2, out2 = run(mod, str(pins), 'refuse_all')
        ok_c = rc2 == 7 and 'EE_PIN_REFUSED' in out2

        # 元判据：拆掉守卫后 refuse_one 必须不再报错（证明报错确实来自守卫）
        with tempfile.NamedTemporaryFile('w', suffix='.tcl', delete=False) as f:
            f.write(strip_guards(txt))
            nog = f.name
        rc3, out3 = run(mod, nog, 'refuse_one', k=max(1, want // 2))
        pathlib.Path(nog).unlink()
        ok_d = rc3 == 0

        ok = ok_a and ok_b and ok_c and ok_d
        bad += 0 if ok else 1
        mk = lambda b: '+' if b else '-'
        print('%-4s %-14s expect=%-5d accept_all%s refuse_one%s refuse_all%s meta%s'
              % ('ok' if ok else 'FAIL', mod, want,
                 mk(ok_a), mk(ok_b), mk(ok_c), mk(ok_d)))
        if not ok:
            for lbl, o in (('accept_all', out), ('refuse_one', out1),
                           ('refuse_all', out2), ('meta', out3)):
                print(f'        {lbl}: {o[:160]}')
    print(f'\n{len(mods) - bad} / {len(mods)} 的 fail-closed 守卫**实测会响**')
    return 1 if bad else 0


if __name__ == '__main__':
    sys.exit(main(sys.argv[1:]))
