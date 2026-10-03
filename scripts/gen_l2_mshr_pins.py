#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""gen_l2_mshr_pins.py —— 生成 MSHRCtl lane 的 FM「匹配前」钉点 fm_pins_pre.tcl。

只消名差：golden 扁平寄存器名（probes_0_waitG / mshrs_3/req_tag）与重写件数组/generate
层次名（u_core/probes_waitG[0] / u_core/mshrs[3].entry/u_core/req_tag）之间的差。
set_user_match 只声明两点对应，比较照比：不约束 ref、不改 appvar、不加黑盒。

fail-closed：
  · 生成期：golden 寄存器必须每个都命中恰好一条映射规则，映射单射，否则报错退出；
  · 运行期：set_user_match 从不抛异常（返回 0 = 没配上），逐条数返回值；
    拒一条或总数不等于字面整数（= 钉点位数）就 error（safe interp 里不用 exit）。
进 fm.log 的输出一律 ASCII。

用法:
  python3 scripts/gen_l2_mshr_pins.py          # 幂等写入
  python3 scripts/gen_l2_mshr_pins.py --check  # 只比对不写，有漂移 rc=1（gate 用）
"""
import argparse
import os
import pathlib
import re
import sys

REPO = pathlib.Path(__file__).resolve().parent.parent
GOLDEN = pathlib.Path(os.environ.get('G1_GOLDEN',
                                    '/home/eda/xs-env/G1-canonical/golden-rtl'))


def golden_regs(mod):
    """golden 模块顶层声明的寄存器：[(名字, 位宽)]，按声明顺序。"""
    out = []
    for m in re.finditer(r'^\s*reg\s+(?:\[(\d+):0\]\s+)?(\w+);', (GOLDEN / (mod + '.sv')).read_text(), re.M):
        out.append((m.group(2), int(m.group(1)) + 1 if m.group(1) else 1))
    return out


# ---------------------------------------------------------------------------
# SourceB：probes_<k>_<field> -> u_core/probes_<field>_reg[k]
# ---------------------------------------------------------------------------
SOURCEB_FIELD = {'valid': 'valid', 'rdy': 'rdy', 'waitG': 'waitG', 'task_tag': 'tag',
                 'task_set': 'set', 'task_opcode': 'opcode', 'task_param': 'param',
                 'task_alias': 'alias'}


def sourceb_pins(ref_prefix='', impl_prefix='u_core/'):
    pins = []
    for name, w in golden_regs('SourceB'):
        m = re.fullmatch(r'probes_(\d+)_(\w+)', name)
        if not m or m.group(2) not in SOURCEB_FIELD:
            raise SystemExit('SourceB 寄存器 %s 没有映射规则' % name)
        k, f = m.group(1), SOURCEB_FIELD[m.group(2)]
        pins.append((ref_prefix + name, '%sprobes_%s_reg\\[%s\\]' % (impl_prefix, f, k), w))
    return pins


def render(tag, top, pins, note):
    total = sum(w for _, _, w in pins)
    impls = [i for _, i, _ in pins]
    if len(set(impls)) != len(impls) or len(set(r for r, _, _ in pins)) != len(pins):
        raise SystemExit('%s: 映射不是单射' % top)
    P = tag.upper()
    L = ['# %s FM「匹配前」钉点 —— 自动生成：scripts/gen_l2_mshr_pins.py（勿手改）' % top,
         '#']
    L += ['# ' + x for x in note]
    L += ['# set_user_match 只是声明两点对应，比较照比：不约束 ref、不改 appvar、不加黑盒。',
          '# fail-closed：逐条数 set_user_match 的返回值；拒一条或总数不等于字面整数就 error。',
          'set ::%s_PIN_EXPECT %d' % (P, total),
          'set ::%s_PIN_OK 0' % P,
          'set ::%s_PIN_BAD 0' % P,
          'proc %s_pin {g i w} {' % tag,
          '  if {$w == 1} {',
          '    set pairs [list "r:/WORK/%s/${g}_reg" "i:/WORK/%s/${i}"]' % (top, top),
          '  } else {',
          '    set pairs {}',
          '    for {set b 0} {$b < $w} {incr b} {',
          '      lappend pairs "r:/WORK/%s/${g}_reg\\[$b\\]" "i:/WORK/%s/${i}\\[$b\\]"' % (top, top),
          '    }',
          '  }',
          '  foreach {r m} $pairs {',
          '    if {[set_user_match $r $m]} { incr ::%s_PIN_OK } else {' % P,
          '      incr ::%s_PIN_BAD' % P,
          '      if {$::%s_PIN_BAD <= 10} { puts "%s_PIN_FAIL: $r <-> $m" }' % (P, P),
          '    }',
          '  }',
          '}',
          'puts "%s_PIN_BEGIN %s expect=$::%s_PIN_EXPECT"' % (P, top, P)]
    for r, i, w in pins:
        L.append('%s_pin %s %s %d' % (tag, r, i, w))
    L += ['puts "%s_PIN_END %s ok=$::%s_PIN_OK bad=$::%s_PIN_BAD"' % (P, top, P, P),
          'if {$::%s_PIN_BAD != 0} { error "%s_PIN_MISS=$::%s_PIN_BAD" }' % (P, P, P),
          'if {$::%s_PIN_OK != %d} { error "%s_PIN_COUNT=$::%s_PIN_OK expect=%d" }' % (P, total, P, P, total)]
    return '\n'.join(L) + '\n'


def outputs():
    out = {}
    out[REPO / 'verif/ut/SourceB/fm_pins_pre.tcl'] = render(
        'sourceb', 'SourceB', sourceb_pins(),
        ['golden 的 4 个 probe 表项是扁平寄存器 probes_<k>_<字段>，重写核存成按字段的数组',
         'probes_<字段>[k]。活位靠签名也能配上，但 waitG[6:4]（恒写 0、没有读者）两侧都是',
         '死位，签名配不上 —— 所以全部表项寄存器逐位钉死（4 x 56 = 224 位），不依赖签名。',
         'issueArb（FastArbiter_5）内部同名，FM 自动配对，不钉。'])
    out[REPO / 'verif/ut/MSHRCtl/fm_pins_pre.tcl'] = render(
        'mshrctl', 'MSHRCtl', sourceb_pins('sourceB/', 'u_core/sourceB/u_core/'),
        ['只钉 sourceB 实例里的 probe 表项（理由同 verif/ut/SourceB/fm_pins_pre.tcl：waitG[6:4]',
         '两侧都是死位，签名配不上）。16 个 MSHR、4 个仲裁器、本层 timers/perf 寄存器 FM 按名',
         '自动配上（commit 159b9c25 试跑：除这 12 位外 unmatched 0(0)），不钉。'])
    return out


def main():
    ap = argparse.ArgumentParser(description=__doc__.split('\n')[0])
    ap.add_argument('--check', action='store_true', help='只比对不写，有漂移 rc=1')
    args = ap.parse_args()
    drift = []
    for p, t in outputs().items():
        cur = p.read_text() if p.exists() else None
        if cur != t:
            drift.append(str(p.relative_to(REPO)))
            if not args.check:
                p.write_text(t)
    if args.check:
        print('gen_l2_mshr_pins: DRIFT %s' % drift if drift else 'gen_l2_mshr_pins: OK')
        return 1 if drift else 0
    print('gen_l2_mshr_pins: 更新 %s' % drift if drift else 'gen_l2_mshr_pins: 已是最新')
    return 0


if __name__ == '__main__':
    sys.exit(main())
