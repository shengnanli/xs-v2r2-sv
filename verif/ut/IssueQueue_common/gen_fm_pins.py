#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""gen_fm_pins.py —— IssueQueue<V> 的 FM「匹配前」钉点：复用已签核 Entries<V> 的钉点表，加实例前缀

为什么需要：IQ 父级 FM 把条目阵列两侧白盒（ref = golden Entries<V> 及其 EnqEntry/OthersEntry
子树，impl = 本仓重写 Entries<V>，u_core 里是扁平的数组寄存器）。两侧寄存器命名体系完全不同
（golden 逐条目逐字段平铺，重写按字段数组存），不钉的话 matching 要靠签名硬扛 ~2.5 万个点。
单签 Entries<V> 时已经有一张逐位、一一对应、fail-closed 的钉点表
（verif/ut/Entries<V>/fm_pins_pre.tcl，由 Entries_common/gen_fm_pins.py 从字段偏移表机械生成）。
这里**原样复用它的配对列表**，只把两侧路径各加上条目阵列在 IQ 里的实例名：
    r:/WORK/$top/<inst>/<golden 寄存器>   <->   i:/WORK/$top/<inst>/u_core/<重写寄存器>
钉点只消名差，不约束 ref、不 dont_verify、不黑盒。计数守卫照搬（用 set_user_match 返回值数，
失败一条或总数不等于字面期望值都 error）。

用法: python3 gen_fm_pins.py <IssueQueueV> [--check]
"""
import argparse
import pathlib
import re
import sys

HERE = pathlib.Path(__file__).resolve().parent
UT = HERE.parent


def gen(v):
    ev = 'Entries' + v[len('IssueQueue'):]
    src = (UT / ev / 'fm_pins_pre.tcl').read_text()
    m = re.search(r'foreach _pair \{\n(.*?)\n  \} \{', src, re.S)
    if not m:
        raise SystemExit(f'{ev}: 找不到钉点列表')
    pairs = [l for l in m.group(1).splitlines() if l.strip()]
    for l in pairs:
        if not re.fullmatch(r'    \{\S+ \S+\}', l):
            raise SystemExit(f'{ev}: 钉点行格式异常 {l!r}')
    exp = int(re.search(r'expect=(\d+)"', src).group(1))
    if exp != len(pairs):
        raise SystemExit(f'{ev}: 期望数 {exp} != 列表行数 {len(pairs)}')
    # golden IQ 里条目阵列的实例名
    gsrc = pathlib.Path(f'/home/eda/xs-env/G1-canonical/golden-rtl/{v}.sv').read_text()
    inst = re.findall(r'^  %s (\w+) \($' % ev, gsrc, re.M)
    if len(inst) != 1:
        raise SystemExit(f'{v}: {ev} 实例数 != 1')
    inst = inst[0]
    out = f'''# {v} FM 匹配前钉点 —— 复用已签核 {ev} 的钉点表，两侧路径加实例前缀 "{inst}/"
# ============================================================================
# ★自动生成：verif/ut/IssueQueue_common/gen_fm_pins.py —— 勿手改★
# 配对来源：verif/ut/{ev}/fm_pins_pre.tcl（逐字复制其配对列表，{exp} 对）。
# 计数守卫：用 set_user_match 的**返回值**数（它从不抛异常），失败一条或总数 != {exp} 都 error
# （用 error 不用 exit：sidecar 模式下本文件在 safe interp 里执行，exit 被隐藏）。
# ============================================================================

if {{$top eq "{v}"}} {{
  set _n 0
  set _miss 0
  puts "IQE_PIN_BEGIN {v} expect={exp}"
  foreach _pair {{
{chr(10).join(pairs)}
  }} {{
    lassign $_pair _r _i
    if {{[set_user_match "r:/WORK/$top/{inst}/$_r" "i:/WORK/$top/{inst}/u_core/$_i"]}} {{
      incr _n
    }} else {{
      incr _miss
      if {{$_miss <= 10}} {{ puts "IQE_PIN_FAIL: $_r <-> $_i" }}
    }}
  }}
  puts "IQE_PIN_END {v} n=$_n miss=$_miss expect={exp}"
  if {{$_miss != 0}} {{ error "IQE_PIN_MISS={v} miss=$_miss" }}
  if {{$_n != {exp}}} {{ error "IQE_PIN_COUNT={v} n=$_n expect={exp}" }}
}}
'''
    return out


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('variant')
    ap.add_argument('--check', action='store_true')
    a = ap.parse_args()
    dst = UT / a.variant / 'fm_pins_pre.tcl'
    txt = gen(a.variant)
    if a.check:
        ok = dst.exists() and dst.read_text() == txt
        print(f'gen_fm_pins --check: {a.variant} ' + ('OK' if ok else '不一致'))
        return 0 if ok else 1
    dst.write_text(txt)
    print(f'gen_fm_pins: 写 {dst}')
    return 0


if __name__ == '__main__':
    sys.exit(main())
