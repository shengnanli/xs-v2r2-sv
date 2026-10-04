#!/usr/bin/env python3
"""gen_icache_pins.py —— ICache（父级，8 个子模块两侧白盒）FM 钉点生成器。

ICache 的子模块各自单独签核时，下面这些寄存器靠「顶层插一层 u_core」的自动配对或签名分析配上；
放进 ICache 后，impl 路径变成 u_core/<子实例>/u_core/<孙实例>/u_core/...（多层核），fm_eq 的自动配对
只认顶层那一层 u_core，签名分析在 2 万点规模下也配不全 —— lane 内诊断跑（merge_dup 默认）实测
unmatched compare 597(ref)，并因此连带 325 个 failing（全部落在 missUnit 的 MSHR / 优先级 FIFO 及其下游）。
这里按**命名规则**把它们一一钉上（只消名差，比较照比；规则来自重写核的文件头，不读任何 FM 结果）：

匹配前（fm_pins_pre.tcl）：
  missUnit/{fetchMSHRs_0..3, prefetchMSHRs_0..9}/blkPaddr_reg[b]  <-> u_core/missUnit/u_core/<同名实例>/u_core/blk_paddr_q_reg[b]   (42 位)
  missUnit/{...同上...}/vSetIdx_reg[b]                            <-> u_core/missUnit/u_core/<同名实例>/u_core/vset_idx_q_reg[b]    (8 位)
  missUnit/priorityFIFO/regFiles_<k>_reg[b]                       <-> u_core/missUnit/u_core/priorityFIFO/u_core/regfile_reg[k][b] (10 项 × 4 位)
  共 14 × 50 + 40 = 740 条。
匹配后（fm_pins.tcl）—— 两侧零扇出、名字不同的死位（unread 点 FM 不做签名分析）：
  dataArray/dataArrays_<w>_<b>/srams_0/rdata_hold_data_0_reg[65] <-> u_core/dataArray/dataArrays_<w>_<b>/srams_0/u_core/rdata_hold_reg[65]
      —— SRAMTemplateWithFixedWidth 把 65 位数据补成 66 位写 SRAM、读回截掉最高位（与该目标单独签核时同一死位）；32 条
  missUnit/refill_done_r_counter_reg <-> u_core/missUnit/u_core/grant_beat_left_q_reg
      —— 只被 `ifndef SYNTHESIS 断言读的 1 位计数器（verif/ut/ICacheMissUnit/fm_pins.tcl 同一条）；1 条
  共 33 条。配上后由 vmucp 真比较（verif/fm_target_config/ICache.tcl）。
golden 里每个被钉的寄存器都必须以对应位宽声明过，否则拒绝生成；两份产物都 fail-closed（拒一条或条数不等于
字面常数即 error）。

用法：python3 scripts/gen_icache_pins.py [--check]
"""
import argparse
import os
import re
import sys

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
G = os.environ.get('GOLDEN_RTL', '/home/eda/xs-env/G1-canonical/golden-rtl')
UT = os.path.join(REPO, 'verif', 'ut', 'ICache')
MSHRS = ['fetchMSHRs_%d' % i for i in range(4)] + ['prefetchMSHRs_%d' % i for i in range(10)]


def need_reg(mod, name, width):
    txt = open(os.path.join(G, mod + '.sv')).read()
    pat = r'\breg\s+\[%d:0\]\s+%s;' % (width - 1, re.escape(name)) if width > 1 else \
          r'\breg\s+%s;' % re.escape(name)
    if not re.search(pat, txt):
        raise SystemExit('gen_icache_pins: golden %s 里没有 %d 位寄存器 %s' % (mod, width, name))


def mshr_module(inst):
    txt = open(os.path.join(G, 'ICacheMissUnit.sv')).read()
    m = re.search(r'\n  (ICacheMSHR\w*) %s \(' % re.escape(inst), txt)
    if not m:
        raise SystemExit('gen_icache_pins: golden ICacheMissUnit 里找不到实例 %s' % inst)
    return m.group(1)


def pre_pairs():
    P = []
    for inst in MSHRS:
        mod = mshr_module(inst)
        for gname, iname, w in (('blkPaddr', 'blk_paddr_q', 42), ('vSetIdx', 'vset_idx_q', 8)):
            need_reg(mod, gname, w)
            for b in range(w):
                P.append(('r:/WORK/ICache/missUnit/%s/%s_reg[%d]' % (inst, gname, b),
                          'i:/WORK/ICache/u_core/missUnit/u_core/%s/u_core/%s_reg[%d]' % (inst, iname, b)))
    for k in range(10):
        need_reg('FIFOReg', 'regFiles_%d' % k, 4)
        for b in range(4):
            P.append(('r:/WORK/ICache/missUnit/priorityFIFO/regFiles_%d_reg[%d]' % (k, b),
                      'i:/WORK/ICache/u_core/missUnit/u_core/priorityFIFO/u_core/regfile_reg[%d][%d]' % (k, b)))
    return P


def post_pairs():
    P = []
    txt = open(os.path.join(G, 'ICacheDataArray.sv')).read()
    insts = re.findall(r'\n  (SRAMTemplateWithFixedWidth\w*) (dataArrays_\d+_\d+) \(', txt)
    if len(insts) != 32:
        raise SystemExit('gen_icache_pins: golden ICacheDataArray 里 SRAMTemplateWithFixedWidth 例化数 %d != 32' % len(insts))
    sram_of = {'SRAMTemplateWithFixedWidth': 'SRAMTemplate_4', 'SRAMTemplateWithFixedWidth_4': 'SRAMTemplate_8',
               'SRAMTemplateWithFixedWidth_12': 'SRAMTemplate_16', 'SRAMTemplateWithFixedWidth_28': 'SRAMTemplate_32'}
    for mod, inst in sorted(insts, key=lambda x: x[1]):
        need_reg(sram_of[mod], 'rdata_hold_data_0', 66)
        P.append(('r:/WORK/ICache/dataArray/%s/srams_0/rdata_hold_data_0_reg[65]' % inst,
                  'i:/WORK/ICache/u_core/dataArray/%s/srams_0/u_core/rdata_hold_reg[65]' % inst))
    need_reg('ICacheMissUnit', 'refill_done_r_counter', 1)
    P.append(('r:/WORK/ICache/missUnit/refill_done_r_counter_reg',
              'i:/WORK/ICache/u_core/missUnit/u_core/grant_beat_left_q_reg'))
    return P


def emit(pairs, tag, what):
    L = ['# ICache FM %s钉点 —— 自动生成：scripts/gen_icache_pins.py（勿手改；规则与理由见生成器文件头）' % what,
         '# 只 set_user_match 消名差：不约束 ref、不改 appvar、不加黑盒。逐条数返回值，拒一条或总数不等于字面常数即 error。',
         '# 跑在 sidecar 的 safe child interp 里：只用 set_user_match / puts / error。进 fm.log 的输出一律 ASCII。',
         'if {$top ne "ICache"} { error "ICACHE_%s_PIN_UNKNOWN_TOP=$top" }' % tag,
         'set ::ICACHE_%s_EXPECT %d' % (tag, len(pairs)),
         'set ::ICACHE_%s_OK 0' % tag,
         'set ::ICACHE_%s_BAD 0' % tag,
         'proc icache_%s_pin {r i} {' % tag.lower(),
         '  if {[set_user_match $r $i]} { incr ::ICACHE_%s_OK } else {' % tag,
         '    incr ::ICACHE_%s_BAD' % tag,
         '    if {$::ICACHE_%s_BAD <= 10} { puts "ICACHE_%s_PIN_FAIL: $r <-> $i" }' % (tag, tag),
         '  }',
         '}',
         'puts "ICACHE_%s_PIN_BEGIN expect=$::ICACHE_%s_EXPECT"' % (tag, tag)]
    for r, i in pairs:
        L.append('icache_%s_pin {%s} {%s}' % (tag.lower(), r, i))
    L += ['puts "ICACHE_%s_PIN_END ok=$::ICACHE_%s_OK bad=$::ICACHE_%s_BAD expect=$::ICACHE_%s_EXPECT"' % ((tag,) * 4),
          'if {$::ICACHE_%s_BAD != 0 || $::ICACHE_%s_OK != $::ICACHE_%s_EXPECT} {' % ((tag,) * 3),
          '  error "ICACHE_%s_PIN_COUNT ok=$::ICACHE_%s_OK bad=$::ICACHE_%s_BAD"' % ((tag,) * 3),
          '}']
    return '\n'.join(L) + '\n'


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--check', action='store_true')
    a = ap.parse_args()
    bad = 0
    for fn, txt in (('fm_pins_pre.tcl', emit(pre_pairs(), 'PRE', '「匹配前」')),
                    ('fm_pins.tcl', emit(post_pairs(), 'POST', '「匹配后」'))):
        p = os.path.join(UT, fn)
        cur = open(p).read() if os.path.exists(p) else None
        if a.check:
            if cur != txt:
                print('DRIFT: %s' % p)
                bad += 1
        elif cur != txt:
            open(p, 'w').write(txt)
        print('%s: %d 条' % (fn, txt.count('\nicache_')))
    return 1 if bad else 0


if __name__ == '__main__':
    sys.exit(main())
