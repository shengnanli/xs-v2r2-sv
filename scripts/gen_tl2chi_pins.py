#!/usr/bin/env python3
"""gen_tl2chi_pins.py —— TL2CHICoupledL2 / L2Top 的 FM「匹配前」钉点（verif/ut/<T>/fm_pins_pre.tcl）。

两个目标都把 TL2CHICoupledL2 的整个闭包两侧白盒 elaborate。闭包里有两类 child 在单独签核时就靠钉点配对
（golden 扁平寄存器名 vs 重写数组名，FM 自己配不上）：
  * 4 个 Slice 变体（Slice / Slice_1 / _2 / _3）：verif/ut/Slice/fm_pins_pre.tcl（scripts/gen_l2_slice.py 生成，
    每变体 29381 位，内容是各 child 签核时 FM 已核实的配对，见该文件头）；
  * Prefetcher：verif/ut/Prefetcher/fm_pins_pre.tcl（scripts/gen_prefetcher_pins.py 生成，960 位）。
放进 TL2CHICoupledL2 / L2Top 之后对象不变，只是路径多一层实例名（slices_<k>/、prefetcher/，L2Top 再多 inner_l2cache/）。
本脚本**不另立规则**：逐行读这两份已签件的钉点文件，只换层次前缀，条数逐变体对账。

fail-closed：
  · 生成期：每个 Slice 变体块的条数（slice_pin 1 位 + slice_pinw w 位）必须等于该块自报的 expect；Prefetcher 的
    条数必须等于其 ::PFT_PIN_EXPECT；所有 ref / impl 路径都必须以被替换的前缀开头；全体映射单射；总数等于字面期望；
  · 运行期：逐条数 set_user_match 返回值，拒一条或总数不等于字面期望即 error。

用法：python3 scripts/gen_tl2chi_pins.py          # 生成两个目标
      python3 scripts/gen_tl2chi_pins.py --check  # 与仓库里的文件逐字节比较，不一致 rc=1
"""
import os
import re
import sys

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SLICE_PINS = os.path.join(REPO, 'verif', 'ut', 'Slice', 'fm_pins_pre.tcl')
PFT_PINS = os.path.join(REPO, 'verif', 'ut', 'Prefetcher', 'fm_pins_pre.tcl')
VARIANTS = ['Slice', 'Slice_1', 'Slice_2', 'Slice_3']      # slices_0..3 的模块名（golden TL2CHICoupledL2 同）
SLICE_EXPECT = 29381
PFT_EXPECT = 960
TARGETS = {
    # 目标: TL2CHICoupledL2 在目标里的实例路径前缀
    'TL2CHICoupledL2': '',
    'L2Top': 'inner_l2cache/',
}
EXPECT = 4 * SLICE_EXPECT + PFT_EXPECT     # 118484


def die(msg):
    raise SystemExit('gen_tl2chi_pins: ' + msg)


def slice_blocks():
    """{变体: [(ref, impl, 宽度或 None)]}，路径保留原样（r:/WORK/<变体>/... / i:/WORK/<变体>/...）"""
    t = open(SLICE_PINS).read()
    out = {}
    for v in VARIANTS:
        m = re.search(r'^if \{\$top eq "%s"\} \{\n(.*?)^\}\n' % re.escape(v), t, re.S | re.M)
        if not m:
            die('Slice 钉点文件里找不到变体 %s 的块' % v)
        body = m.group(1)
        exp = re.search(r'SLICE_PIN_BEGIN %s expect=(\d+)' % re.escape(v), body)
        if not exp:
            die('%s 块没有 expect' % v)
        items, n = [], 0
        for ln in body.splitlines():
            ln = ln.strip()
            mm = re.match(r'slice_pin \{(\S+)\} \{(\S+)\}$', ln)
            mw = re.match(r'slice_pinw \{(\S+)\} \{(\S+)\} (\d+)$', ln)
            if mm:
                items.append((mm.group(1), mm.group(2), None))
                n += 1
            elif mw:
                items.append((mw.group(1), mw.group(2), int(mw.group(3))))
                n += int(mw.group(3))
            elif ln.startswith('slice_pin'):
                die('认不出的钉点行: %r' % ln)
        if n != int(exp.group(1)) or n != SLICE_EXPECT:
            die('%s：收到 %d 位，块自报 %s，字面期望 %d' % (v, n, exp.group(1), SLICE_EXPECT))
        out[v] = items
    return out


def pft_items():
    t = open(PFT_PINS).read()
    exp = re.search(r'^set ::PFT_PIN_EXPECT (\d+)$', t, re.M)
    items = re.findall(r'^pft_pin \{(\S+)\} \{(\S+)\}$', t, re.M)
    if not exp or len(items) != int(exp.group(1)) or len(items) != PFT_EXPECT:
        die('Prefetcher 钉点 %d 条，文件自报 %s，字面期望 %d' % (len(items), exp and exp.group(1), PFT_EXPECT))
    return items


def build(top, pfx):
    pairs = []      # (ref 全路径, impl 全路径, 宽度或 None)
    for k, (v, items) in enumerate(sorted(slice_blocks().items(), key=lambda kv: VARIANTS.index(kv[0]))):
        for r, i, w in items:
            for p, side in ((r, 'r'), (i, 'i')):
                if not p.startswith('%s:/WORK/%s/' % (side, v)):
                    die('%s 的钉点路径 %s 不以 %s:/WORK/%s/ 开头' % (v, p, side, v))
            nr = 'r:/WORK/%s/%sslices_%d/%s' % (top, pfx, k, r[len('r:/WORK/%s/' % v):])
            ni = 'i:/WORK/%s/%sslices_%d/%s' % (top, pfx, k, i[len('i:/WORK/%s/' % v):])
            pairs.append((nr, ni, w))
    for r, i in pft_items():
        pairs.append(('r:/WORK/%s/%sprefetcher/%s' % (top, pfx, r), 'i:/WORK/%s/%sprefetcher/%s' % (top, pfx, i), None))
    if len({p[0] for p in pairs}) != len(pairs) or len({p[1] for p in pairs}) != len(pairs):
        die('%s：映射不单射' % top)
    n = sum(w or 1 for _, _, w in pairs)
    if n != EXPECT:
        die('%s：钉点 %d 位，字面期望 %d' % (top, n, EXPECT))
    o = []
    o.append('# %s FM「匹配前」钉点 —— 自动生成：scripts/gen_tl2chi_pins.py（勿手改）' % top)
    o.append('#')
    o.append('# 内容 = 4 个 Slice 变体（verif/ut/Slice/fm_pins_pre.tcl，各 %d 位）+ Prefetcher（verif/ut/Prefetcher/fm_pins_pre.tcl，'
             '%d 位）' % (SLICE_EXPECT, PFT_EXPECT))
    o.append('# 单独签核时的钉点，只换层次前缀（%sslices_<k>/、%sprefetcher/）。set_user_match 只声明两点对应，比较照比。' % (pfx, pfx))
    o.append('# fail-closed：逐条数 set_user_match 的返回值；拒一条或总数 != %d 即 error。进 fm.log 的输出一律 ASCII。' % EXPECT)
    o.append('set ::TL2_PIN_OK 0')
    o.append('set ::TL2_PIN_BAD 0')
    o.append('proc tl2_pin {r i} {')
    o.append('  if {[set_user_match $r $i]} { incr ::TL2_PIN_OK } else {')
    o.append('    incr ::TL2_PIN_BAD')
    o.append('    if {$::TL2_PIN_BAD <= 10} { puts "TL2_PIN_FAIL: $r <-> $i" }')
    o.append('  }')
    o.append('}')
    o.append('proc tl2_pinw {r i w} {')
    o.append('  for {set b 0} {$b < $w} {incr b} { tl2_pin "${r}\\[$b\\]" "${i}\\[$b\\]" }')
    o.append('}')
    o.append('puts "TL2_PIN_BEGIN %s expect=%d"' % (top, EXPECT))
    for r, i, w in pairs:
        if w is None:
            o.append('tl2_pin {%s} {%s}' % (r, i))
        else:
            o.append('tl2_pinw {%s} {%s} %d' % (r, i, w))
    o.append('puts "TL2_PIN_END %s ok=$::TL2_PIN_OK bad=$::TL2_PIN_BAD"' % top)
    o.append('if {$::TL2_PIN_BAD != 0 || $::TL2_PIN_OK != %d} {' % EXPECT)
    o.append('  error "TL2_PIN_MISMATCH ok=$::TL2_PIN_OK bad=$::TL2_PIN_BAD expect=%d"' % EXPECT)
    o.append('}')
    return '\n'.join(o) + '\n'


def main():
    check = '--check' in sys.argv[1:]
    rc = 0
    for top, pfx in TARGETS.items():
        path = os.path.join(REPO, 'verif', 'ut', top, 'fm_pins_pre.tcl')
        txt = build(top, pfx)
        if check:
            ok = os.path.exists(path) and open(path).read() == txt
            print(('OK: ' if ok else 'DRIFT: ') + path)
            rc |= 0 if ok else 1
        else:
            if not os.path.exists(path) or open(path).read() != txt:
                open(path, 'w').write(txt)
            print('wrote ' + path)
    return rc


if __name__ == '__main__':
    sys.exit(main())
