#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""gen_matrix.py —— IssueQueue* 家族（14 变体）「字段 / 结构差异矩阵」生成器（从 G1 golden 实测）

为什么要有这个文件：一个共享 IQ 核要被 14 个变体共用。哪些结构全家族一致（可以写进核）、
哪些逐变体不同（必须参数化或留给 wrapper），只能从 golden（firtool 展平产物）量，不能从
Chisel 默认值推。改共享核之前先跑它。

用法:
  python3 gen_matrix.py            # 写 matrix.tsv（机器读）并打印
  python3 gen_matrix.py --check    # 与已提交的 matrix.tsv 比对，不一致非零退出
"""
import argparse, collections, pathlib, re, sys

GOLDEN = pathlib.Path('/home/eda/xs-env/G1-canonical/golden-rtl')
HERE = pathlib.Path(__file__).resolve().parent
ENTRIES_TSV = HERE.parent / 'Entries_field_matrix' / 'matrix.tsv'
PORT_RE = re.compile(r'^\s*(input|output)\s+(?:\[(\d+):0\]\s+)?(\w+),?\s*$')
INST_RE = re.compile(r'^  ([A-Z]\w*) (\w+) \($', re.M)


def variants():
    return sorted(p.stem for p in GOLDEN.glob('IssueQueue*.sv'))


def ports(v, text):
    body = re.search(r'^module %s\(\n(.*?)^\);' % v, text, re.M | re.S).group(1)
    out = []
    for l in body.splitlines():
        m = PORT_RE.match(l)
        if not m:
            raise SystemExit(f'{v}: 端口行解析失败: {l!r}')
        out.append((m.group(1), int(m.group(2)) + 1 if m.group(2) else 1, m.group(3)))
    return out


def facts(v, ent):
    t = (GOLDEN / f'{v}.sv').read_text()
    P = ports(v, t)
    names = {n for _, _, n in P}
    f = collections.OrderedDict()
    e = ent['Entries' + v[len('IssueQueue'):]]
    for k in ('numEntries', 'numEnq', 'numSimp', 'numComp', 'numDeq', 'fuTypeBits'):
        f[k] = e[k]
    f['nPorts'] = len(P)
    f['nEnqPortFields'] = sum(1 for _, _, n in P if n.startswith('io_enq_0_'))
    f['nEnqSrc'] = len([n for n in names if re.fullmatch(r'io_enq_0_bits_srcType_\d+', n)])
    # 每个发射口能接受的 FuType 位（deqCanIssue_<d> 表达式里出现的 fuTypeVec_0[k]）
    acc = []
    for d in range(int(e['numDeq'])):
        m = re.search(r'wire \[\d+:0\]\s+deqCanIssue_%d =\n(.*?);' % d, t, re.S)
        bits = sorted({int(x) for x in re.findall(r'fuTypeVec_0\[(\d+)\]', m.group(1))}) if m else []
        if m and not bits:   # 另一种展平：deqCanIssue_<d> = merge & {deqCanAcceptVec_<d>_<i>...}
            m2 = re.search(r'wire\s+deqCanAcceptVec_%d_0 =\s*(.*?);' % d, t, re.S)
            bits = sorted({int(x) for x in re.findall(r'fuTypeVec_0\[(\d+)\]', m2.group(1))}) if m2 else []
        acc.append('+'.join(map(str, bits)) if bits else 'ALL?')
    f['deqAcceptFu'] = ' | '.join(acc)
    regs = re.findall(r'^\s+reg\s+(?:\[(\d+):0\]\s+)?(\w+);', t, re.M)
    rb = collections.Counter()
    for w, n in regs:
        w = int(w) + 1 if w else 1
        if n.startswith('deqDelay_'):
            rb['deqDelay_' + n.split('_')[1]] += w
        elif 'perfDebugInfo' in n:
            rb['perfTimer'] += w
        elif n.startswith('io_validCntDeqVec'):
            rb['validCntReg'] += w
        elif n.startswith('io_wakeupToIQ'):
            rb['loadWakeupReg'] += w
        else:
            rb['OTHER:' + n] += w
    f['regBits_deqDelay'] = '/'.join(str(rb['deqDelay_%d' % d]) for d in range(int(e['numDeq'])))
    f['regBits_perfTimer'] = rb['perfTimer']
    f['regBits_validCnt'] = rb['validCntReg']
    f['regBits_loadWakeup'] = rb['loadWakeupReg']
    f['regBits_other'] = ';'.join(k for k in rb if k.startswith('OTHER:')) or '-'
    f['regBits_total'] = sum(rb.values())
    f['validCntOut'] = ','.join(sorted(n.split('_')[2] for n in names if re.fullmatch(r'io_validCntDeqVec_\d+', n))) or '-'
    inst = collections.Counter(m for m, _ in INST_RE.findall(t))
    f['mwq'] = ','.join(k for k in inst if k.startswith('MultiWakeupQueue')) or '-'
    f['ageDet'] = ','.join(k for k in inst if 'AgeDetector' in k)
    bt = [n for _, n in INST_RE.findall(t) if 'BusyTable' in n]
    f['busyTables'] = ','.join(bt) or '-'
    f['wakeupToIQ'] = ('MWQ' if f['mwq'] != '-' else 'LOAD_REG' if rb['loadWakeupReg'] else
                       'none' if not any(n.startswith('io_wakeupToIQ') for n in names) else '??')
    for key, pat in (('og2Resp', r'io_og2Resp_'), ('vlIn', r'io_vlFromIntIsZero'),
                     ('memFeedback', r'io_memIO_feedbackIO'), ('loadWakeUpIn', r'io_memIO_loadWakeUp'),
                     ('vecMemPtr', r'io_memIO_lqDeqPtr'), ('finalIssueResp', r'io_finalIssueResp'),
                     ('replaceRCIdx', r'io_replaceRCIdx'), ('ldCancel', r'io_ldCancel'),
                     ('og0Cancel', r'io_og0Cancel'), ('wakeupFromIQ', r'io_wakeupFromIQ_')):
        f[key] = sum(1 for n in names if n.startswith(pat.replace('\\', '')))
    f['deqFuSame(DeqPolicy)'] = inst.get('DeqPolicy', 0)
    return f


def build():
    rows = list(csv_rows(ENTRIES_TSV))
    ent = {r['variant']: r for r in rows}
    return [(v, facts(v, ent)) for v in variants()]


def csv_rows(p):
    lines = p.read_text().splitlines()
    head = lines[0].split('\t')
    for l in lines[1:]:
        yield dict(zip(head, l.split('\t')))


def render(tab):
    keys = list(tab[0][1].keys())
    out = ['variant\t' + '\t'.join(keys)]
    for v, f in tab:
        out.append(v + '\t' + '\t'.join(str(f[k]) for k in keys))
    return '\n'.join(out) + '\n'


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--check', action='store_true')
    a = ap.parse_args()
    txt = render(build())
    dst = HERE / 'matrix.tsv'
    if a.check:
        if not dst.exists() or dst.read_text() != txt:
            print('gen_matrix --check: matrix.tsv 与 golden 实测不一致'); return 1
        print('gen_matrix --check: OK'); return 0
    dst.write_text(txt)
    print(txt)
    return 0


if __name__ == '__main__':
    sys.exit(main())
