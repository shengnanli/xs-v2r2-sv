#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""wakeup_axis.py —— 唤醒匹配机制的**判别轴**表（E1 作用域的依据）。

    python3 wakeup_axis.py            # 生成 wakeup_axis.md
    python3 wakeup_axis.py --check    # 只校验已提交的表没漂（非零退出=漂了）

## 为什么要这张表

E1（唤醒匹配从"每源一对"放宽成"按源分 kind + 多对"）的作用域，最初被按**族**切成
「MEM 族要、VEC 族不用」。实测把这条推翻了：`EntriesVlduVstu` / `…VseglduVsegstu`
是 VEC 族（`numRegSrc==5`），却和 MEM 族一样每条 lane 带多个 wen，
而且五个源全都监听全部 16 条 lane —— ★lane 掩码把它们分不开★。

★所以"族"不是判别轴。真正的轴是两条，且横穿族边界：★

    (1) 一条 WB lane 上带几个 wen 字段
    (2) 各源的 lane 掩码能不能把它们分开（分不开时，区分各源的只剩每源的 kind）

**这张表就是那条轴，逐变体算一遍。** 它是 E1 作用域的依据，也是将来复核的入口 ——
别让判据只活在某一次对话里（本仓已经吃过一次亏：结论传下去了，限定条件没传下去）。

## 四档

| 档 | 条件 | 老机制（每源一张 lane 掩码 + 每 lane 一个 wen）够不够 |
|---|---|---|
| A | 每 lane 1 个 wen，掩码能把各源分开 | ★够★ |
| B | 每 lane 1 个 wen，掩码分不开，但各源**同一种 kind** | ★够★（不分也不会串） |
| C | 每 lane 多个 wen，各源同一种 kind | 不够：要多对 |
| D | 每 lane 多个 wen，掩码分不开，且各源 **kind 不同** | 不够：要多对 **且** 按源分 kind |

★B 档容易读错★：脚本报"掩码分不开"不等于"必须按源分表"——还要看各源 kind 是否不同。
两条一起才是判据。
"""
import argparse, collections, pathlib, re, sys

G = pathlib.Path('/home/eda/xs-env/G1-canonical/golden-rtl')
HERE = pathlib.Path(__file__).resolve().parent
OUT = HERE / 'wakeup_axis.md'

# 变体 -> 它的 enq 条目模块（与 matrix.md 的 enqEntryMod 列一致）
VAR = [
 ('EntriesAluBrhJmpI2fVsetriwiVsetriwvfI2v', 'EnqEntry_4'),
 ('EntriesAluCsrFenceDiv', 'EnqEntry_6'),
 ('EntriesAluMulBkuBrhJmp', 'EnqEntry'),
 ('EntriesFaluFcvtF2vFmacFdiv', 'EnqEntry_8'),
 ('EntriesFaluFmac', 'EnqEntry_12'),
 ('EntriesFaluFmacFdiv', 'EnqEntry_10'),
 ('EntriesLdu', 'EnqEntry_24'),
 ('EntriesStaMou', 'EnqEntry_20'),
 ('EntriesStdMoud', 'EnqEntry_30'),
 ('EntriesVfdivVidiv', 'EnqEntry_18'),
 ('EntriesVfmaVialuFixVfalu', 'EnqEntry_16'),
 ('EntriesVfmaVialuFixVimacVppuVfaluVfcvtVipuVsetrvfwvf', 'EnqEntry_14'),
 ('EntriesVlduVstu', 'EnqEntryVecMem_2'),
 ('EntriesVlduVstuVseglduVsegstu', 'EnqEntryVecMem'),
]
SHORT = {'rfWen': 'rf', 'fpWen': 'fp', 'vecWen': 'vec', 'v0Wen': 'v0', 'vlWen': 'vl'}


def measure(mod):
    raw = (G / f'{mod}.sv').read_text()
    flat = re.sub(r'\s+', ' ', raw)
    n_src = len(re.findall(r'^  reg .*entryReg_status_srcStatus_\d+_psrc', raw, re.M))

    lane = collections.defaultdict(set)
    for w, f in re.findall(r'input +io_commonIn_wakeUpFromWB_(\d+)_bits_(\w+Wen)', flat):
        lane[int(w)].add(f)
    per_lane = sorted({len(v) for v in lane.values()}) or [0]

    masks, kinds = [], []
    for s in range(n_src):
        m = re.search(r'assign currentStatus_srcStatus_%d_srcState =\n(.*?);\n' % s, raw, re.S)
        if not m:
            masks.append(set()); kinds.append(set()); continue
        masks.append({int(x) for x in re.findall(
            r'io_enqDelayIn1_wakeUpFromWB_(\d+)_valid', m.group(1))})
        kinds.append(frozenset(
            (int(b), SHORT[w]) for b, w in re.findall(
                r'srcStatus_%d_srcType\[(\d)\] & io_\w+_\d+_bits_(\w+Wen)' % s,
                re.sub(r'\s+', ' ', m.group(1)))))

    # ★"掩码能不能把各源分开"要问对问题★（2026-09-20 自己踩到并修正）
    #   第一版写成"任意两源的 lane 集合互不相交" —— 那会把向量族判错：
    #   它的 src0/src1/src2 共用同一张掩码(0-5)，但**三者 kind 相同**，
    #   重叠完全无害。掩码的作用是把**kind 不同**的源隔开,同 kind 的源共用掩码
    #   既正常又普遍。所以只看 kind 不同的那些源对。
    diff_pairs = [(i, j) for i in range(n_src) for j in range(i + 1, n_src)
                  if kinds[i] and kinds[j] and kinds[i] != kinds[j]]
    sep = all(not (masks[i] & masks[j]) for i, j in diff_pairs)
    multi = max(per_lane) > 1
    same_kind = len({k for k in kinds if k}) <= 1
    tier = ('D'  if (multi and not same_kind) else
            'C'  if multi else
            'B'  if same_kind else
            'A'  if sep else 'A*')
    return dict(n_src=n_src, per_lane=per_lane, lane=lane, masks=masks,
                kinds=kinds, sep=sep, multi=multi, same_kind=same_kind, tier=tier)


def lane_groups(lane):
    grp = collections.defaultdict(list)
    for w, s in lane.items():
        grp[tuple(sorted(SHORT[x] for x in s))].append(w)
    return '; '.join(f'{min(ws)}-{max(ws)}→{"+".join(k)}'
                     for k, ws in sorted(grp.items(), key=lambda kv: min(kv[1])))


NEED = {'A':  '够（各源 kind 不同，但掩码把它们隔开了）',
        'A*': '★不够：要按源分 kind（但不必多对）★',
        'B':  '够（全部源同一种 kind，没什么要隔开的）',
        'C':  '不够：要多对（全部源同一种 kind）',
        'D':  '★不够：要多对**且**按源分 kind★'}


def render():
    L = ['# 唤醒匹配机制的判别轴（E1 作用域的依据）', '',
         '由 `verif/ut/Entries_field_matrix/wakeup_axis.py` 从 G1 golden 机械生成。',
         '改共享核的唤醒匹配之前必须复跑并核对（`--check`）。', '',
         '★判别轴不是"族"，是两条：**每 lane 带几个 wen** × **lane 掩码能不能把各源分开**★',
         '—— 它横穿族边界：`EntriesVlduVstu` 是 VEC 族却落在 D 档。', '',
         '| 变体 | nSrc | 每 lane 的 wen 数 | lane 分组 | 各源 lane 掩码 | 各源 kind | 掩码分得开 | 档 | 老机制够不够 |',
         '|---|---|---|---|---|---|---|---|---|']
    rows = []
    for top, mod in VAR:
        d = measure(mod)
        mk = ' / '.join(
            (f'{min(m)}-{max(m)}' if m else '-') for m in d['masks'])
        kk = ' / '.join(
            ('+'.join(f'{b}:{w}' for b, w in sorted(k)) if k else '-') for k in d['kinds'])
        L.append(f'| `{top}` | {d["n_src"]} | {",".join(map(str,d["per_lane"]))} | '
                 f'{lane_groups(d["lane"])} | {mk} | {kk} | '
                 f'{"是" if d["sep"] else "★否★"} | **{d["tier"]}** | {NEED[d["tier"]]} |')
        rows.append((top, d['tier']))
    L += ['', '## 五档的含义', '',
          '判据两条：**每 lane 带几个 wen**（决定要不要"多对"）×',
          '**kind 不同的那些源，掩码有没有把它们隔开**（决定要不要"按源分 kind"）。', '',
          '| 档 | 每 lane wen | 各源 kind | 掩码隔开了吗 | 老机制够不够 |',
          '|---|---|---|---|---|',
          '| B | 1 | 全同 | （无关） | ★够★ |',
          '| A | 1 | 不同 | 隔开了 | ★够★ |',
          '| A\* | 1 | 不同 | **没隔开** | 不够：要按源分 kind |',
          '| C | 多 | 全同 | （无关） | 不够：要多对 |',
          '| D | 多 | 不同 | 没隔开 | ★不够：要多对**且**按源分 kind★ |',
          '',
          '★"掩码分得开"必须只问 kind 不同的那些源对★ —— 这一点我第一版写错过：',
          '向量族的 src0/1/2 共用同一张掩码(0-5)，但三者 kind 相同，重叠完全无害；',
          '按"任意两源都不许重叠"去判，会把 A 档误判成需要改造。',
          '同 kind 的源共用掩码既正常又普遍，**掩码要隔开的是 kind，不是源**。', '',
          '## 各档都有谁', '']
    by = collections.defaultdict(list)
    for top, tier in rows:
        by[tier].append(top)
    for tier in 'ABCD':
        if by[tier]:
            L.append(f'- **{tier}**（{NEED[tier]}）：' + '、'.join(f'`{x}`' for x in by[tier]))
    L += ['', '## 历史（为什么这张表要存在）', '',
          'E1 的作用域最初被按**族**切成「MEM 族要、VEC 族不用」。',
          '按族切会漏掉 D 档的 `EntriesVlduVstu` / `EntriesVlduVstuVseglduVsegstu` ——',
          '它们是 VEC 族（`numRegSrc==5`），却每条 lane 带 5 个 wen、五个源全听全部 16 条 lane，',
          '只按 `Ldu`/`StaMou`/`StdMoud`（`numRegSrc==1`、全 GP）设计的 E1 里没有 V0/VL 两种 kind，',
          '这两个变体做不了。',
          '',
          'A 档那三个向量变体（`VfdivVidiv` / `VfmaVialuFixVfalu` / `VfmaVialuFix…Vsetrvfwvf`）',
          '**确实**老机制够用 —— 但依据是「掩码能分开」，**不是**「因为它是 VEC 族」。',
          '这个区别正是本表存在的理由：★结论会传下去，限定条件不会。★', '']
    return '\n'.join(L) + '\n'


def main(argv):
    ap = argparse.ArgumentParser()
    ap.add_argument('--check', action='store_true')
    a = ap.parse_args(argv)
    new = render()
    if a.check:
        old = OUT.read_text() if OUT.exists() else ''
        if old != new:
            sys.stderr.write('wakeup_axis: ★已提交的表与 golden 实测不符★，请复跑生成\n')
            return 1
        print(f'wakeup_axis --check: 表与 golden 一致（{len(VAR)} 个变体）')
        return 0
    OUT.write_text(new)
    print(f'wrote {OUT}')
    return 0


if __name__ == '__main__':
    sys.exit(main(sys.argv[1:]))
