#!/usr/bin/env python3
"""gen_l1prefetcher_pins.py —— L1Prefetcher（父级）FM 钉点：把两个已签核子模块的钉点搬到父级层次下。

L1Prefetcher 的 5 个子模块在父级证明里两侧白盒（ref 读 golden、impl 读重写件）。其中两个子模块
单独签核时就需要钉点来消命名鸿沟，放进父级后鸿沟原样还在，只是路径多了一层实例名：

  * StreamBitVectorArray（实例 stream_bit_vec_array）：匹配前钉点
      verif/ut/StreamBitVectorArray/fm_pins_pre.tcl   →  verif/ut/L1Prefetcher/fm_pins_pre.tcl
  * MutiLevelPrefetchFilter（实例 pf_queue_filter）：匹配后钉点（1 个死寄存器 REG / REG_0）
      verif/ut/MutiLevelPrefetchFilter/fm_pins.tcl     →  verif/ut/L1Prefetcher/fm_pins.tcl

搬运规则（机械、逐字、fail-closed）：
  1. 只替换路径前缀 `r:/WORK/<Child>/` → `r:/WORK/L1Prefetcher/<inst>/`、`i:/WORK/<Child>/` →
     `i:/WORK/L1Prefetcher/<inst>/`（L1Prefetcher 不套 u_core，子模块实例直接挂在顶层下，两侧实例名
     与 golden 相同）；
  2. 全局 tcl 名字加 L1PF_ 前缀（::SBVA_* / proc 名 / 打印标记），免得与子模块自己的钉点文件撞名；
  3. 期望计数（字面整数）原样保留 —— 子模块的钉点条数在父级里一条不多一条不少；
  4. 源文件里每一处 `<Child>` 路径前缀都必须被替换到（替换后源 Child 名不得再以路径形式出现），
     否则拒绝生成。

用法：python3 scripts/gen_l1prefetcher_pins.py [--check]
"""
import argparse
import os
import re
import sys

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
UT = os.path.join(REPO, 'verif', 'ut')
TOP = 'L1Prefetcher'
JOBS = [
    # (源钉点文件, 子模块名, 父级实例名, tcl 名字前缀列表, 产物)
    ('StreamBitVectorArray/fm_pins_pre.tcl', 'StreamBitVectorArray', 'stream_bit_vec_array',
     ['SBVA_PIN', 'sbva_pin'], 'L1Prefetcher/fm_pins_pre.tcl'),
    ('MutiLevelPrefetchFilter/fm_pins.tcl', 'MutiLevelPrefetchFilter', 'pf_queue_filter',
     ['MLPF_PIN', '_mlpf_pin'], 'L1Prefetcher/fm_pins.tcl'),
]


def build(src, child, inst, names):
    txt = open(os.path.join(UT, src)).read()
    out = txt
    for side in ('r', 'i'):
        old = '%s:/WORK/%s/' % (side, child)
        if old not in out:
            raise SystemExit('gen_l1prefetcher_pins: %s 里没有路径前缀 %s' % (src, old))
        out = out.replace(old, '%s:/WORK/%s/%s/' % (side, TOP, inst))
    if re.search(r'[ri]:/WORK/%s/' % child, out):
        raise SystemExit('gen_l1prefetcher_pins: %s 替换后仍残留 %s 路径' % (src, child))
    for n in names:
        if n not in out:
            raise SystemExit('gen_l1prefetcher_pins: %s 里找不到 tcl 名字 %s' % (src, n))
        out = re.sub(r'\b%s' % re.escape(n), 'L1PF_' + n, out)
    head = ('# %s 父级 FM 钉点 —— 自动生成：scripts/gen_l1prefetcher_pins.py（勿手改）\n'
            '# 来源：verif/ut/%s（子模块 %s 单独签核用的钉点），机械搬到父级实例 %s/ 之下；\n'
            '# 规则与条数不变，见源文件头与生成器说明。以下为搬运后的源文件全文。\n#\n'
            % (TOP, src, child, inst))
    return head + out


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--check', action='store_true')
    a = ap.parse_args()
    bad = 0
    for src, child, inst, names, dst in JOBS:
        txt = build(src, child, inst, names)
        p = os.path.join(UT, dst)
        cur = open(p).read() if os.path.exists(p) else None
        if a.check:
            if cur != txt:
                print('DRIFT: %s' % p)
                bad += 1
        elif cur != txt:
            open(p, 'w').write(txt)
        print('%-40s <- %s (%s/)' % (dst, src, inst))
    return 1 if bad else 0


if __name__ == '__main__':
    sys.exit(main())
