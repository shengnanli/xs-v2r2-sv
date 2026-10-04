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
  ★例外（一对多，24 条）★：取指 MSHR（fetchMSHRs_0..3）的 vSetIdx[5:0] 不钉 ref 同名位，而钉到 ref 的
    blkPaddr[5:0]（impl 侧 blk_paddr_q[b] 与 vset_idx_q[b] 两个寄存器都配同一个 ref blkPaddr_reg[b]）：
      missUnit/fetchMSHRs_<n>/blkPaddr_reg[b] <-> u_core/missUnit/u_core/fetchMSHRs_<n>/u_core/vset_idx_q_reg[b]   (b < 6)
    依据（下面 shared_low_bits() 从 golden 机械复核，不读 FM 结果）：golden ICacheMainPipe 送 MSHR 的请求里
    blkPaddr = {s2_req_ptags_p, s2_req_vaddr_p[11:6]}、vSetIdx = s2_req_vaddr_p[13:6]，两字段低 6 位是同一组
    vaddr 位（页内偏移里的 set 索引位），经 Arbiter2 / ICache 顶层 / fetchDemux 原样直通进 4 格取指 MSHR，
    同一拍同一使能写入 ⇒ 每格 MSHR 的 blkPaddr[5:0] 与 vSetIdx[5:0] 恒等。merge_dup（默认开）下 FM 在 ref 侧
    把这对恒等寄存器并成一个（诊断跑 fm.log："Merging duplicated registers in block r:/WORK/ICache/missUnit/
    fetchMSHRs_<n>"，被并掉的是 vSetIdx），impl 侧没并（重写件 4 格取指 MSHR 经 u_core 多一层；即便把 14 格核
    做成 14 个独立设计也照样不并——lane icache-fm 诊断跑 2 实测，读数不变），impl 的 vset_idx_q[5:0] 于是成了
    无对家的自由状态。FM 允许一个 ref 点配多个 impl 点（set_user_match 手册：each implementation object is
    verified against the reference object），所以这里让 impl 两份副本各自都对 ref 代表点做真比较 ——
    不约束 ref、不放宽任何东西，impl 侧两个寄存器都要证明等于 golden。
匹配后（fm_pins.tcl）—— 两侧零扇出、名字不同的死位（unread 点 FM 不做签名分析）：
  dataArray/dataArrays_<w>_<b>/srams_0/rdata_hold_data_0_reg[65] <-> u_core/dataArray/dataArrays_<w>_<b>/srams_0/u_core/rdata_hold_reg[65]
      —— SRAMTemplateWithFixedWidth 把 65 位数据补成 66 位写 SRAM、读回截掉最高位（与该目标单独签核时同一死位）；32 条
  missUnit/refill_done_r_counter_reg <-> u_core/missUnit/u_core/grant_beat_left_q_reg
      —— 只被 `ifndef SYNTHESIS 断言读的 1 位计数器（verif/ut/ICacheMissUnit/fm_pins.tcl 同一条）；1 条
  ctrlUnitOpt/out_back_q/ram_reg[53+k] <-> u_core/ctrlUnitOpt/out_back_q/slot_reg\[data][48+k]   (k=0..15)
      —— Queue1_RegMapperInput_5 的 data[63:48]：ICacheCtrlUnit 只读 data[47:0]，这 16 位入队不出队
         （与 verif/ut/ICacheCtrlUnit/fm_pins.tcl 同一组死位，golden 打包在 ram 的绝对位 53..68）；16 条
  dataArray/{res,res_1,res_2,res_3}/beReg_reg <-> u_core/dataArray/<同名>/u_core/beReg_reg[0]
      —— MbistPipeIcacheDataWay0..3 的 1 位 MBIST 写使能锁存（父级不读；重写核 xs_mbist_pipe_core 声明成
         [BE_W-1:0]，FM 展平名多一个 [0]）；4 条
  共 53 条（lane icache-fm 诊断跑 2：钉完前 33 条后，FM 报两侧各 20 个 unmatched unread，正是后两组）。
  配上后由 vmucp 真比较（verif/fm_target_config/ICache.tcl）。
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


def shared_low_bits():
    """golden 取指 MSHR 请求里 blkPaddr 与 vSetIdx 共用的低位数（机械复核整条直通路径，任何一处不符即拒绝生成）。"""
    mp = open(os.path.join(G, 'ICacheMainPipe.sv')).read()
    n = None
    for p in (0, 1):
        mb = re.search(r'\.io_in_%d_bits_blkPaddr\s*\(\{s2_req_ptags_%d, s2_req_vaddr_%d\[(\d+):(\d+)\]\}\)' % (p, p, p), mp)
        mv = re.search(r'\.io_in_%d_bits_vSetIdx\s*\(s2_req_vaddr_%d\[(\d+):(\d+)\]\)' % (p, p), mp)
        if not (mb and mv) or mb.group(2) != mv.group(2):
            raise SystemExit('gen_icache_pins: golden ICacheMainPipe toMSHRArbiter 口 %d 的 blkPaddr/vSetIdx 低位不再同源' % p)
        k = int(mb.group(1)) - int(mb.group(2)) + 1
        if n is not None and k != n:
            raise SystemExit('gen_icache_pins: 两个口共用低位数不一致 %d/%d' % (n, k))
        n = k
    top = open(os.path.join(G, 'ICache.sv')).read()
    for f in ('blkPaddr', 'vSetIdx'):
        if not re.search(r'\.io_fetch_req_bits_%s\s*\(_mainPipe_io_mshr_req_bits_%s\)' % (f, f), top):
            raise SystemExit('gen_icache_pins: golden ICache 里 missUnit.fetch_req.%s 不再直连 mainPipe.mshr_req' % f)
    mu = open(os.path.join(G, 'ICacheMissUnit.sv')).read()
    dm = open(os.path.join(G, 'DeMultiplexer.sv')).read()
    if not re.search(r'\n  DeMultiplexer fetchDemux \(', mu) or \
       not re.search(r'\.io_in_bits_blkPaddr\s*\(io_fetch_req_bits_blkPaddr\)', mu) or \
       not re.search(r'\.io_in_bits_vSetIdx\s*\(io_fetch_req_bits_vSetIdx\)', mu):
        raise SystemExit('gen_icache_pins: golden ICacheMissUnit fetchDemux 输入不再是 io_fetch_req')
    for i in range(4):
        for f in ('blkPaddr', 'vSetIdx'):
            if not re.search(r'assign io_out_%d_bits_%s = io_in_bits_%s;' % (i, f, f), dm):
                raise SystemExit('gen_icache_pins: golden DeMultiplexer 出口 %d 的 %s 不再直通' % (i, f))
            if not re.search(r'\.io_req_bits_%s\s*\(_fetchDemux_io_out_%d_bits_%s\)' % (f, i, f), mu):
                raise SystemExit('gen_icache_pins: golden fetchMSHRs_%d.io_req.%s 不接 fetchDemux 出口 %d' % (i, f, i))
    return n


def pre_pairs():
    P = []
    nshared = shared_low_bits()
    for inst in MSHRS:
        mod = mshr_module(inst)
        for gname, iname, w in (('blkPaddr', 'blk_paddr_q', 42), ('vSetIdx', 'vset_idx_q', 8)):
            need_reg(mod, gname, w)
            for b in range(w):
                rname = gname
                if inst.startswith('fetchMSHRs_') and gname == 'vSetIdx' and b < nshared:
                    rname = 'blkPaddr'   # 一对多：见文件头「例外」
                P.append(('r:/WORK/ICache/missUnit/%s/%s_reg[%d]' % (inst, rname, b),
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
    need_reg('Queue1_RegMapperInput_5', 'ram', 84)
    q = open(os.path.join(G, 'Queue1_RegMapperInput_5.sv')).read()
    if 'assign io_deq_bits_data = ram[68:5];' not in q:
        raise SystemExit('gen_icache_pins: golden Queue1_RegMapperInput_5 的 data 段不再是 ram[68:5]')
    if not re.search(r'\n  Queue1_RegMapperInput_5 out_back_q \(', open(os.path.join(G, 'ICacheCtrlUnit.sv')).read()):
        raise SystemExit('gen_icache_pins: golden ICacheCtrlUnit 里找不到 out_back_q')
    for k in range(16):
        P.append(('r:/WORK/ICache/ctrlUnitOpt/out_back_q/ram_reg[%d]' % (53 + k),
                  'i:/WORK/ICache/u_core/ctrlUnitOpt/out_back_q/slot_reg\\[data][%d]' % (48 + k)))
    da = open(os.path.join(G, 'ICacheDataArray.sv')).read()
    for w, inst in enumerate(('res', 'res_1', 'res_2', 'res_3')):
        mod = 'MbistPipeIcacheDataWay%d' % w
        if not re.search(r'\n  %s %s \(' % (mod, inst), da):
            raise SystemExit('gen_icache_pins: golden ICacheDataArray 里找不到 %s %s' % (mod, inst))
        need_reg(mod, 'beReg', 1)
        P.append(('r:/WORK/ICache/dataArray/%s/beReg_reg' % inst,
                  'i:/WORK/ICache/u_core/dataArray/%s/u_core/beReg_reg[0]' % inst))
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
