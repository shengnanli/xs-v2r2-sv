#!/usr/bin/env python3
"""独立复测：每条 WB lane 各带几个 wen 字段 + 每个源监听哪几条 lane。

★这是"继承来的数字必须自己重测"那条规矩的产物★：集成者转来
agent/othersentry 的 lane 分组（0-5 vecWen / 6-11 v0Wen / 12-15 vlWen），
本脚本不引用它，直接从 G1 golden 量一遍。

它回答的是 E1 的作用域问题：**lane 掩码能不能把各个源分开**。
  能分开 ⇒ 老机制(每源一张 lane 掩码 + 每 lane 一个 wen)就够
  分不开 ⇒ 区分各源的只剩「每源的匹配 kind」，必须按源分表
"""
import re, collections, sys, pathlib
G = pathlib.Path('/home/eda/xs-env/G1-canonical/golden-rtl')
MODS = [('EntriesVfdivVidiv','EnqEntry_18'), ('EntriesVfmaVialuFixVfalu','EnqEntry_16'),
        ('EntriesVfmaVialuFixVimacVppuVfaluVfcvtVipuVsetrvfwvf','EnqEntry_14'),
        ('EntriesVlduVstu','EnqEntryVecMem_2'),
        ('EntriesVlduVstuVseglduVsegstu','EnqEntryVecMem'),
        ('EntriesLdu','EnqEntry_24'), ('EntriesStaMou','EnqEntry_20'),
        ('EntriesStdMoud','EnqEntry_30'), ('EntriesAluCsrFenceDiv','EnqEntry_6'),
        ('EntriesFaluFmac','EnqEntry_12')]
for top, m in MODS:
    raw = (G/f'{m}.sv').read_text(); t = re.sub(r'\s+', ' ', raw)
    lane = collections.defaultdict(set)
    for w, f in re.findall(r'input +io_commonIn_wakeUpFromWB_(\d+)_bits_(\w+Wen)', t):
        lane[int(w)].add(f)
    if not lane:
        print(f'{top}: 无 WB wen 端口'); continue
    grp = collections.defaultdict(list)
    for w, s in lane.items(): grp[tuple(sorted(s))].append(w)
    print(f'=== {top} ({m}) ===')
    print('  lane 分组: ' + '; '.join(
        f'{min(ws)}-{max(ws)}→{"+".join(k)}' for k, ws in
        sorted(grp.items(), key=lambda kv: min(kv[1]))))
    sep = True
    seen = []
    for s in range(5):
        mm = re.search(r'assign currentStatus_srcStatus_%d_srcState =\n(.*?);\n' % s, raw, re.S)
        if not mm: continue
        lanes = sorted({int(x) for x in re.findall(
            r'io_enqDelayIn1_wakeUpFromWB_(\d+)_valid', mm.group(1))})
        pairs = sorted({(b, w) for b, w in re.findall(
            r'srcStatus_%d_srcType\[(\d)\] & io_\w+_\d+_bits_(\w+Wen)' % s,
            re.sub(r'\s+', ' ', mm.group(1)))})
        if any(set(lanes) & set(x) for x in seen): sep = False
        seen.append(lanes)
        print(f'  src{s}: lanes {min(lanes)}-{max(lanes)} ({len(lanes)} 条)  '
              f'对表 {[f"{b}:{w[:-3]}" for b, w in pairs]}')
    print('  ⇒ lane 掩码' + ('把各源分开了，老机制够用' if sep else
          ' ★分不开：各源 lane 集合重叠，区分它们的只剩每源的匹配 kind★'))
