#!/usr/bin/env python3
"""E1 抽取原型：per-(window, source) 的 (srcTypeBit, wenKind) 对表。
先只做"抽取+自洽核对"，不改核，也不改生成器 —— 确认抽得对再动代码。"""
import re, sys, pathlib
G = pathlib.Path('/home/eda/xs-env/G1-canonical/golden-rtl')
VARIANTS = {
 'EntriesAluBrhJmpI2fVsetriwiVsetriwvfI2v':'EnqEntry_4','EntriesAluCsrFenceDiv':'EnqEntry_6',
 'EntriesAluMulBkuBrhJmp':'EnqEntry','EntriesFaluFcvtF2vFmacFdiv':'EnqEntry_8',
 'EntriesFaluFmac':'EnqEntry_12','EntriesFaluFmacFdiv':'EnqEntry_10',
 'EntriesLdu':'EnqEntry_24','EntriesStaMou':'EnqEntry_20','EntriesStdMoud':'EnqEntry_30',
 'EntriesVfdivVidiv':'EnqEntry_18','EntriesVfmaVialuFixVfalu':'EnqEntry_16',
 'EntriesVfmaVialuFixVimacVppuVfaluVfcvtVipuVsetrvfwvf':'EnqEntry_14',
 'EntriesVlduVstu':'EnqEntryVecMem_2','EntriesVlduVstuVseglduVsegstu':'EnqEntryVecMem'}

def pairs(txt, s, bus):
    """bus: 'commonIn_wakeUpFromWB' / 'enqDelayIn1_wakeUpFromWB' /
            'commonIn_wakeUpFromIQ' / 'enqDelayIn1_wakeUpFromIQ'"""
    t = re.sub(r'\s+', ' ', txt)
    return sorted(set(re.findall(
        r'srcStatus_%d_srcType\[(\d)\] & io_%s_\d+_bits_(\w+Wen)' % (s, bus), t)))

print(f'{"变体":54s} {"src":>3s}  WB当拍                       WB延迟                       IQ当拍                IQ延迟')
for top, enq in VARIANTS.items():
    txt = (G/f'{enq}.sv').read_text()
    n = len(re.findall(r'^  reg .*entryReg_status_srcStatus_\d+_psrc', txt, re.M))
    for s in range(n):
        a = pairs(txt, s, 'commonIn_wakeUpFromWB')
        b = pairs(txt, s, 'enqDelayIn1_wakeUpFromWB')
        c = pairs(txt, s, 'commonIn_wakeUpFromIQ')
        d = pairs(txt, s, 'enqDelayIn1_wakeUpFromIQ')
        f = lambda p: ','.join(f'{t}:{w[:-3]}' for t, w in p) or '-'
        flag = ''
        if a != b: flag += ' ★WB两窗口不同★'
        if c != d: flag += ' ★IQ两窗口不同★'
        print(f'{top if s==0 else "":54s} {s:>3d}  {f(a):28s} {f(b):28s} {f(c):20s} {f(d):20s}{flag}')
