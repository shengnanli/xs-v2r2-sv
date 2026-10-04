#!/usr/bin/env python3
"""gen_l1prefetcher_pins.py —— L1Prefetcher（父级）FM 钉点：把两个已签核子模块的钉点搬到父级层次下。

L1Prefetcher 的 5 个子模块在父级证明里两侧白盒（ref 读 golden、impl 读重写件）。其中两个子模块
单独签核时就需要钉点来消命名鸿沟，放进父级后鸿沟原样还在，只是路径多了一层实例名：

  * StreamBitVectorArray（实例 stream_bit_vec_array）：匹配前钉点
      verif/ut/StreamBitVectorArray/fm_pins_pre.tcl   →  verif/ut/L1Prefetcher/fm_pins_pre.tcl
  * MutiLevelPrefetchFilter（实例 pf_queue_filter）：匹配后钉点（1 个死寄存器 REG / REG_0）
      verif/ut/MutiLevelPrefetchFilter/fm_pins.tcl     →  verif/ut/L1Prefetcher/fm_pins.tcl

另加一组父级才有的钉点（追加在 fm_pins_pre.tcl 末尾）——训练滤波器重排序流水/FIFO 里的死位：
  TrainFilter / TrainFilter_1 单独签核时，train_req.bits 的 pc / vaddr 每一位都是输出、都活着，
  FM 靠签名分析就配上了；进了 L1Prefetcher，下游 StrideMetaArray / StreamBitVectorArray 只读其中一部分位，
  其余位在父级变成零扇出（unread）——lane 内诊断跑实测两侧各 453 位 unmatched unread
  （stride pc 15 个寄存器 × 25 位 + stream vaddr 13 个寄存器 × 6 位）。零扇出点 FM 不做签名分析，
  golden 展平名与重写核数组名又对不上，只能钉。规则（与重写核 xs_TrainFilter_core 的文件头一一对应）：
    ld_in_reordered_res_0_1_<i>_<f>  <->  u_core/a_<g>[i]     （A 级重排序寄存器）
    ld_in_reordered_res_1_2_<i>_<f>  <->  u_core/b_<g>[i]     （B 级）
    ld_in_reordered_<i>_<f>          <->  u_core/c_<g>[i]     （C 级）
    entries_<k>_<e>                  <->  u_core/ent_<g>[k]   （FIFO 条目）
  stride（TrainFilter）：f = bits_uop_pc、e = pc、g = payload（pc 原样走流水，50 位）；
  stream（TrainFilter_1）：f = bits_vaddr、e = vaddr、g = vaddr（50 位）。
  每个寄存器 50 位**整体**逐位钉（活位本来也会配上，一并钉不改变语义，只让条数成为字面常数）；
  golden 里每个名字都必须真以 `reg [49:0] <名>;` 声明过，否则拒绝生成。

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


G = os.environ.get('GOLDEN_RTL', '/home/eda/xs-env/G1-canonical/golden-rtl')
TF = [  # (golden 模块, 父级实例, 流水字段, FIFO 字段, 核字段, FIFO 深度)
    ('TrainFilter', 'stride_train_filter', 'bits_uop_pc', 'pc', 'payload', 6),
    ('TrainFilter_1', 'stream_train_filter', 'bits_vaddr', 'vaddr', 'vaddr', 4),
]


def trainfilter_pins():
    pairs = []
    for mod, inst, f, e, g, depth in TF:
        gtxt = open(os.path.join(G, mod + '.sv')).read()
        names = []
        for stage, core in (('ld_in_reordered_res_0_1_%d_', 'a_'), ('ld_in_reordered_res_1_2_%d_', 'b_'),
                            ('ld_in_reordered_%d_', 'c_')):
            for i in range(3):
                names.append(((stage % i) + f, '%s%s_reg[%d]' % (core, g, i)))
        for k in range(depth):
            names.append(('entries_%d_%s' % (k, e), 'ent_%s_reg[%d]' % (g, k)))
        for gname, iname in names:
            if not re.search(r'\breg\s+\[49:0\]\s+%s;' % re.escape(gname), gtxt):
                raise SystemExit('gen_l1prefetcher_pins: golden %s 里没有 reg [49:0] %s' % (mod, gname))
            pairs.append(('r:/WORK/%s/%s/%s_reg' % (TOP, inst, gname),
                          'i:/WORK/%s/%s/u_core/%s' % (TOP, inst, iname)))
    L = ['', '# ---- 父级追加：训练滤波器死位钉点（规则见 scripts/gen_l1prefetcher_pins.py 文件头）----',
         'set ::L1PF_TF_EXPECT %d' % (len(pairs) * 50),
         'set ::L1PF_TF_OK 0',
         'set ::L1PF_TF_BAD 0',
         'proc l1pf_tf_pin {r i} {',
         '  for {set b 0} {$b < 50} {incr b} {',
         '    if {[set_user_match "${r}\\[$b\\]" "${i}\\[$b\\]"]} { incr ::L1PF_TF_OK } else {',
         '      incr ::L1PF_TF_BAD',
         '      if {$::L1PF_TF_BAD <= 10} { puts "L1PF_TF_PIN_FAIL: $r <-> $i bit $b" }',
         '    }',
         '  }',
         '}',
         'puts "L1PF_TF_PIN_BEGIN expect=$::L1PF_TF_EXPECT"']
    for r, i in pairs:
        L.append('l1pf_tf_pin {%s} {%s}' % (r, i))
    L += ['puts "L1PF_TF_PIN_END ok=$::L1PF_TF_OK bad=$::L1PF_TF_BAD expect=$::L1PF_TF_EXPECT"',
          'if {$::L1PF_TF_BAD != 0 || $::L1PF_TF_OK != $::L1PF_TF_EXPECT} {',
          '  error "L1PF_TF_PIN_COUNT ok=$::L1PF_TF_OK bad=$::L1PF_TF_BAD"',
          '}', '']
    return '\n'.join(L)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--check', action='store_true')
    a = ap.parse_args()
    bad = 0
    for src, child, inst, names, dst in JOBS:
        txt = build(src, child, inst, names)
        if dst.endswith('fm_pins_pre.tcl'):
            txt += trainfilter_pins()
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
