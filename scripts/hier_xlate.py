#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""hier_xlate.py —— 把 golden 实例路径翻译成重写件的实例路径（消费方工具）。

给一堆按**实例路径**工作的外部流程用：波形探针、force/deposit、bind 目标、
故障注入 scope、memory campaign 的阵列路径。输入一行一条 golden 路径
（可带前缀，如 `stl_tb_top.dut.` / `SimTop.`，用 `--root-prefix` 声明），
输出每条路径在「重写件优先」的整芯片里是什么，或者为什么不再是一条路径。

判定（逐段走 golden 例化图，同时在 impl 侧跟着走）：

  OK            整条路径在 impl 侧原样存在（这条不用改）
  REMAP         存在，但路径变了 —— 给出新路径
  INLINED       这一段被吸收进可读核，**不再是一条实例路径**；
                给出宿主核路径与承载状态的信号名，由消费方自己决定怎么接
  SIGNAL_TAIL_OK      末段是信号名，且它所在的模块本轮没被重写。
                      ★"模块没被重写"不蕴含"路径没变"★：它的**上游**父模块可能被
                      重写了（每个重写件都插一层 `u_core`），此时 golden 原路径在
                      impl 树里根本不存在。所以报告层再分两种：
  SIGNAL_TAIL_OK      译出路径与输入**逐字相同** —— 这条才真的原样可用
  SIGNAL_TAIL_REMAP   模块没重写，但上游层次变了 —— 必须换用译出的新路径
  SIGNAL_IN_REWRITTEN 末段是信号名，但它所在的模块**已被重写** —— golden 的扁平
                      信号名（`_T_*`/`io_xxx_0`）在可读核里不存在，必须人工重找
  UNKNOWN_SEG   中间某一段在 golden 例化图里就查不到（输入写错）
  BEST_EFFORT   前缀能翻译，但往下进了 `xs_*` 可读核内部，golden 侧没有对应层次，
                余下的段无法机械翻译 —— **如实说不知道，不猜**

用法:
  python3 scripts/hier_xlate.py --paths mypaths.txt --root-prefix stl_tb_top.dut
  echo 'XSTop.core_with_l2.core.backend...' | python3 scripts/hier_xlate.py -
"""
from __future__ import print_function

import argparse
import collections
import pathlib
import re
import sys

HERE = pathlib.Path(__file__).resolve().parent
REPO = HERE.parent
sys.path.insert(0, str(HERE))
import g1_slotmap as SM                                             # noqa: E402

MAP = REPO / 'docs' / 'hier_rebind_map.tsv'
GOLDEN_DEFAULT = '/home/eda/xs-env/G1-canonical/golden-rtl'
INLINE_CLASSES = ('INLINE', 'INLINE_REG_ARRAY', 'INLINE_DESCENDANT')


def load_map(path=MAP):
    rows = {}
    cols = None
    for ln in pathlib.Path(path).read_text().splitlines():
        if ln.startswith('# owner\t'):
            cols = ln[2:].split('\t')
            continue
        if not ln.strip() or ln.startswith('#'):
            continue
        f = ln.split('\t')
        r = dict(zip(cols, f))
        rows[(r['owner'], r['golden_path'])] = r
    return rows


def translate(segs, g1, rows, top='XSTop'):
    out, gm = [], top
    owner, base, rel = None, 0, []
    for k, inst in enumerate(segs):
        if owner is None:
            if (gm, inst) in rows:                       # gm 是重写 owner
                owner, base, rel = gm, len(out), [inst]
            else:
                child = g1.slot.get((gm, inst))
                if child is None:
                    # 最后一段查不到实例 = 它多半是**信号/寄存器名**，不是实例名。
                    # 这时唯一要问的是：它所在的模块被重写了没有？重写了就必须人工
                    # 重找对应信号（golden 的 `_T_*`/扁平名在可读核里不存在）。
                    if k == len(segs) - 1:
                        v = 'SIGNAL_IN_REWRITTEN' if any(key[0] == gm for key in rows) \
                            else 'SIGNAL_TAIL_OK'
                        return (v, '.'.join(out + [inst]), gm, '')
                    return ('UNKNOWN_SEG', '.'.join(out), inst, '')
                out.append(inst)
                gm = child
                continue
        else:
            rel.append(inst)
        r = rows.get((owner, '/'.join(rel)))
        if r is None:
            if k == len(segs) - 1:
                return ('SIGNAL_IN_REWRITTEN', '.'.join(out + [inst]), owner, '')
            return ('BEST_EFFORT', '.'.join(out), inst, '')
        if r['class'] in INLINE_CLASSES:
            # ★别在这里就收工★：被内联的往往只是控制层，更深的存储叶子可能还在
            # （L2TlbMissQueue 的 io_out_q 内联了，但 io_out_q/ram_ext 仍是
            #  u_core.mem_ext）。只有走到路径最后一段仍是内联行才算 INLINED。
            if k == len(segs) - 1:
                return ('INLINED', '.'.join(out[:base] + r['impl_path'].split('.')),
                        '/'.join(rel), r['impl_signals'])
            gm = r['golden_child']
            continue
        out = out[:base] + r['impl_path'].split('.')
        gm = r['golden_child']
        if r['impl_module'] == gm:                       # 类型没换，可以重新扎根
            if any(key[0] == gm for key in rows):
                owner, base, rel = gm, len(out), []
            else:
                owner, base, rel = None, 0, []
        # 类型换了（进了 xs_*_core）：owner/rel 继续累积，靠 map 走下去
    return ('OK' if out == segs else 'REMAP', '.'.join(out), '', '')


def report_verdict(verdict, full, src):
    """把 translate() 的判定转成**报告层**判定。

    只有一件事：`SIGNAL_TAIL_OK` 说的是"末段信号所在的模块本轮没被重写"，
    这**不蕴含**"路径没变"—— 它上游的父模块可能被重写了，而每个重写件都会插
    一层 `u_core`。判据只能是译出路径与输入是否逐字相同。

    抽成纯函数是为了能被 scripts/test_hier_map_gate.py 直接负测：这条判定原先
    写在 main() 的打印分支里，没有测试覆盖，错了 242 条也没人发现。
    """
    if verdict == 'SIGNAL_TAIL_OK' and full != src:
        return 'SIGNAL_TAIL_REMAP'
    return verdict


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('paths', nargs='?', default='-')
    ap.add_argument('--paths', dest='paths_opt')
    ap.add_argument('--root-prefix', default='',
                    help='输入路径里 XSTop 之前的部分，例如 stl_tb_top.dut')
    ap.add_argument('--golden', default=GOLDEN_DEFAULT)
    ap.add_argument('--top', default='XSTop')
    ap.add_argument('--quiet-ok', action='store_true', help='只打需要改的行')
    a = ap.parse_args()

    src = a.paths_opt or a.paths
    text = sys.stdin.read() if src == '-' else pathlib.Path(src).read_text()
    g1 = SM.Baseline(a.golden, 'G1', include_v=True)
    rows = load_map()

    pre = a.root_prefix.strip('.')
    stat = collections.Counter()
    for ln in text.splitlines():
        s = ln.strip()
        if not s or s.startswith('#'):
            continue
        p = s
        if pre and p.startswith(pre + '.'):
            p = p[len(pre) + 1:]
        elif pre and p == pre:
            stat['OK'] += 1
            continue
        segs = [x for x in p.split('.') if x]
        if segs and segs[0] == a.top:      # 顶层模块名本身不是实例名
            segs = segs[1:]
        # 通配段原样保留：只翻译能确定的前缀
        if any('*' in x for x in segs):
            head = []
            for x in segs:
                if '*' in x:
                    break
                head.append(x)
            verdict, newp, where, sig = translate(head, g1, rows, a.top)
            tail = segs[len(head):]
            newp = '.'.join([newp] + tail) if newp else '.'.join(tail)
        else:
            verdict, newp, where, sig = translate(segs, g1, rows, a.top)
        full = '.'.join(x for x in [pre, a.top if s.split('.')[0] == a.top or not pre else '', newp] if x)
        # ★这条判定曾经报错★：SIGNAL_TAIL_OK 一律打印「原样可用」并把 full 丢掉
        # （full=''）。但 translate() 走到这里时 `out` 已经沿途吃过 REMAP 行——
        # 末段所在的模块没被重写，不代表**它上面**的父模块没被重写。父模块一被
        # 重写就插一层 `u_core`，golden 原路径在 impl 树里就不存在了。于是那些
        # 上游改过的路径被当成"不用改"发给消费方，拿去 force/bind 必然打空。
        # 判据只能是译出路径与输入是否逐字相同，不能是"模块有没有被重写"。
        verdict = report_verdict(verdict, full, s)
        stat[verdict] += 1
        if verdict == 'OK' and a.quiet_ok:
            continue
        extra = ''
        if verdict == 'INLINED':
            extra = '  ←「%s」已内联；宿主核=%s 信号=%s' % (where, full, sig)
            full = ''
        elif verdict in ('UNKNOWN_SEG', 'BEST_EFFORT'):
            extra = '  ← 卡在段 `%s`' % where
        elif verdict == 'SIGNAL_TAIL_OK':
            extra = '  ← 末段是信号名；所在模块 %s 本轮未重写，且路径逐字未变，原样可用' % where
            full = ''
        elif verdict == 'SIGNAL_TAIL_REMAP':
            extra = ('  ★ 末段是信号名、所在模块 %s 本轮未重写，**但上游层次已变**'
                     '（父模块被重写会插一层 u_core）—— 原路径在 impl 树里不存在，'
                     '必须改用左边给出的新路径' % where)
        elif verdict == 'SIGNAL_IN_REWRITTEN':
            extra = '  ★ 末段是信号名，而所在模块 %s 已被重写 —— golden 的扁平信号名在可读核里不存在，必须人工重找' % where
            full = ''
        print('%-12s %s%s%s' % (verdict, s, ('  ->  ' + full) if full else '', extra))
    print()
    print('合计: ' + '  '.join('%s=%d' % kv for kv in sorted(stat.items())))
    return 0


if __name__ == '__main__':
    sys.exit(main())
