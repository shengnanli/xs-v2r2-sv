#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""written_unproven.py —— 「rtl/ 里已经写了、但没有绿判决证据」到底是哪些。

## 为什么要专门写个工具，而不是随手 grep 一把

随手推的表**不可信**，而且不可信的方式很隐蔽。整理者手推的那张里出现了
TLBFA_1/_2/_3 与 OthersEntry_136/_150/_164 —— 全是已签核的。两个已知原因：
  (a) `evidence/` 被 .gitignore（codex D66，**设计如此不是缺陷**），
      clean 工作树里根本没有本地 receipt；
  (b) 台账的键名与 rtl 里的 module 名对不上。

这两条的共同形状，和本轮反复吃亏的那个一样：
★缺失与否定在输出里长得一模一样★。键名对不上时，如果默默归到"未证"，
就凭空多出一批假目标；默默归到"已证"，就漏掉真目标。两个方向都是 fail-open。

所以本工具的第一条规矩是：**对不上就说对不上，单独成桶，不许并到任何一边。**

## 数据源（★表头必须声明是哪一种★）

两种都允许，但必须写清楚：

  `--source tracked`（默认，**clean clone 可复现**）
      绿判决 = tracked 台账 `docs/fm_round_*.tsv` 里 verdict ∈ {SUCCEEDED, PASS_DEAD_REF}。
      那些台账由 `scripts/harvest_round_ledger.py` 从**已提交、非 dirty** 的 receipt 收割，
      本身进版本库，所以换台机器 clone 下来跑本工具结果一致。
      代价：只反映**最近一次重算**的状态，比本地 evidence 旧。

  `--source local`（**依赖本地 evidence，clean clone 不可复现**）
      绿判决 = 本地 `evidence/*/<top>/receipt.json` 里 verdict ∈ {SUCCEEDED, PASS_DEAD_REF}
      且 impl_worktree_dirty=false。

  `--source both`（推荐）
      两个都读，**并把两者的分歧单列成桶** `STALE_LEDGER` / `LEDGER_ONLY`。
      本轮实测：OthersEntry_136/_150/_164 等就落在 STALE_LEDGER —— 本地已出证、
      tracked 台账还没重算过。这正是手推那张表出错的地方。

## 「已写」怎么判

module 在 `rtl/**/*.sv` 里被定义，**且** golden 里有同名 `.sv`（即它是某个 golden
目标的实现）。rtl 里那些没有 golden 同名件的（`xs_*_core` 这类可读核、
`rtl/common/` 的共享辅助件）不是签核目标，单列 `RTL_INTERNAL` 桶报数，不算进分母。

## 桶（互斥且穷尽，每个 module 恰好落一个）

| 桶 | 含义 |
|---|---|
| `WRITTEN_PROVEN`    | rtl 写了 + 有绿判决 |
| `WRITTEN_UNPROVEN`  | rtl 写了 + 没有绿判决 ← **就是要找的那批** |
| `STALE_LEDGER`      | 本地 evidence 有绿判决，但 tracked 台账里没有（台账该重算了） |
| `LEDGER_ONLY`       | 台账说绿，但 rtl 里**没有**同名 module（键名对不上 / golden 复用 / 已删） |
| `NOT_WRITTEN`       | golden 里有、rtl 里没写 |

## 负测（★表能把已知的两个分对，才值得信★）

    python3 scripts/written_unproven.py --selftest

正例 1：`OthersEntry_164` —— 已签核且已写，必须落在 WRITTEN_PROVEN（`--source local`
        下）或 STALE_LEDGER（tracked 台账还没重算时）。**不能**落在 WRITTEN_UNPROVEN。
正例 2：一个已知**没写**的 golden 模块，必须落在 NOT_WRITTEN，不能落在别的桶。
反例  ：往 rtl 模块表里塞一个 golden 里不存在的名字 ⇒ 必须落进 RTL_INTERNAL 并报数，
        不许被当成"已写目标"。

用法:
    python3 scripts/written_unproven.py                     # 默认 tracked
    python3 scripts/written_unproven.py --source both
    python3 scripts/written_unproven.py --source both --xstile-only --top 40
    python3 scripts/written_unproven.py --selftest
"""
import argparse, json, os, pathlib, re, sys, collections

REPO = pathlib.Path(__file__).resolve().parents[1]
GOLDEN = pathlib.Path(os.environ.get('G1_CANONICAL',
                                     '/home/eda/xs-env/G1-canonical')) / 'golden-rtl'
GREEN = {'SUCCEEDED', 'PASS_DEAD_REF'}

MODULE_RE = re.compile(r'^\s*module\s+([A-Za-z_]\w*)', re.M)
INST_RE = re.compile(r'^\s{0,4}([A-Z][A-Za-z0-9_]*)\s+([a-zA-Z_]\w*)\s*\(\s*$', re.M)


def golden_modules():
    """golden 目录里每个 <name>.sv 就是一个 golden 目标名。"""
    return {p.stem: p for p in GOLDEN.glob('*.sv')}


def rtl_modules():
    """rtl/**/*.sv 里定义的 module -> 定义它的文件（同名多处则全记，便于查重）。"""
    out = collections.defaultdict(list)
    for p in sorted((REPO / 'rtl').rglob('*.sv')):
        for m in MODULE_RE.findall(p.read_text(errors='replace')):
            out[m].append(str(p.relative_to(REPO)))
    return out


def xstile_closure(root='XSTile'):
    seen, stack = set(), [root]
    while stack:
        m = stack.pop()
        if m in seen:
            continue
        seen.add(m)
        f = GOLDEN / f'{m}.sv'
        if f.exists():
            stack.extend({x[0] for x in INST_RE.findall(f.read_text(errors='replace'))})
    return seen


def tracked_green():
    """tracked 台账里的绿判决：target -> (verdict, 来源文件)。"""
    out = {}
    for led in sorted((REPO / 'docs').glob('fm_round_*.tsv')):
        for line in led.read_text(errors='replace').splitlines():
            if line.startswith('#') or not line.strip():
                continue
            f = line.split('\t')
            if len(f) < 2 or f[0] == 'target':
                continue
            if f[1].strip() in GREEN:
                out[f[0].strip()] = (f[1].strip(), led.name)
    return out


def local_green():
    """本地 evidence 里的绿判决（clean clone 里通常为空）。"""
    out = {}
    ev = REPO / 'evidence'
    if not ev.is_dir():
        return out
    for r in ev.glob('*/*/receipt.json'):
        try:
            d = json.loads(r.read_text())
        except Exception:
            continue
        if d.get('impl_worktree_dirty'):
            continue
        if str(d.get('verdict', '')).strip() in GREEN:
            out[d.get('top', r.parent.name)] = (d['verdict'], str(r.relative_to(REPO)))
    return out


def three_axis():
    """tracked 的 docs/coverage_three_axis.tsv：module -> (rewrite_coverage, formal_coverage)。

    ★为什么非读它不可★：光看「rtl/ 里有没有同名 module」会把 **golden 复用件**
    也算成"已写"。TLBFA/_1/_2/_3 就是这样：rtl/memblock/TLBFA_1.sv 存在，但三轴表记的是
    GOLDEN_REUSE / PROVEN_IN_CONE —— 它不是重写件，而且已经在父锥里证过了。
    本工具第一版正是这么把它们塞进 WRITTEN_UNPROVEN 的，会害人去"重签"一个
    根本不该重签的目标。这与整理者手推那张表犯的是同一类错，只是换了个方向。
    """
    out = {}
    f = REPO / 'docs' / 'coverage_three_axis.tsv'
    if not f.exists():
        return out
    for line in f.read_text(errors='replace').splitlines():
        if line.startswith('#') or not line.strip():
            continue
        c = line.split('\t')
        if len(c) >= 3:
            out[c[0].strip()] = (c[1].strip(), c[2].strip())
    return out


def golden_lines(name, gmap):
    p = gmap.get(name)
    return len(p.read_text(errors='replace').splitlines()) if p else 0


def classify(gmap, rmods, trk, loc, source, axis):
    """返回 (rows, internal)。rows: name -> dict；internal: rtl 有而 golden 没有的名字。

    ★三个独立事实，绝不互相推断★
      rtl_has  : rtl/**/*.sv 里有没有同名 module（本工具现量）
      axis_rw  : 三轴表说它是 REWRITTEN / GOLDEN_REUSE / MISSING（tracked）
      green    : 有没有**直接**绿判决（tracked 台账 / 本地 receipt）
    三者两两都可能不一致，每一种不一致都单独成桶，不许并到任何一边。
    """
    internal = sorted(set(rmods) - set(gmap))
    rows = {}
    for name in sorted(gmap):
        rtl_has = name in rmods
        t, l = name in trk, name in loc
        axis_rw, axis_fc = axis.get(name, ('?', '?'))
        proven = {'tracked': t, 'local': l}.get(source, t or l)

        if not rtl_has:
            if t or l:
                bucket = 'LEDGER_ONLY'          # 台账说绿、rtl 里没有：键名对不上/已删
            elif axis_rw == 'REWRITTEN':
                bucket = 'AXIS_MISMATCH'        # 三轴说写了、rtl 里找不到
            else:
                bucket = 'NOT_WRITTEN'
        elif t:
            bucket = 'WRITTEN_PROVEN'
        elif l:
            bucket = 'STALE_LEDGER'             # 本地已证、台账未重算
        elif axis_rw == 'GOLDEN_REUSE':
            # ★不是重写件★：rtl 里那个同名文件是 golden 复用壳，不该进"待签核"名单
            bucket = ('GOLDEN_REUSE_IN_CONE' if axis_fc == 'PROVEN_IN_CONE'
                      else 'GOLDEN_REUSE_UNPROVEN')
        elif axis_fc == 'PROVEN_IN_CONE':
            bucket = 'PROVEN_IN_CONE_ONLY'      # 只在父锥里证过，没有自己的绿判决
        elif axis_rw == 'MISSING':
            bucket = 'AXIS_MISMATCH'            # rtl 里有、三轴表却说没写
        else:
            bucket = 'WRITTEN_UNPROVEN'
        rows[name] = dict(name=name, written=rtl_has, impl=';'.join(rmods.get(name, [])),
                          tracked=t, local=l, proven=proven, bucket=bucket,
                          axis_rw=axis_rw, axis_fc=axis_fc)
    return rows, internal


def selftest():
    """★判据要先证明自己分得对★：两个正例 + 一个反例。"""
    gmap, rmods = golden_modules(), rtl_modules()
    trk, loc = tracked_green(), local_green()
    rc = 0
    print('written_unproven --selftest:')

    # 正例 1：已签核且已写的目标，绝不能落在 WRITTEN_UNPROVEN
    axis = three_axis()
    rows, _ = classify(gmap, rmods, trk, loc, 'both', axis)
    for pos in ('OthersEntry_164', 'OthersEntry_72'):
        b = rows.get(pos, {}).get('bucket')
        ok = b in ('WRITTEN_PROVEN', 'STALE_LEDGER')
        print(f'  [{"OK" if ok else "FAIL"}] 正例 已签核+已写 {pos} -> {b}'
              f'（必须是 WRITTEN_PROVEN 或 STALE_LEDGER，不能是 WRITTEN_UNPROVEN）')
        rc |= 0 if ok else 1

    # 正例 2：golden 里有、rtl 里确实没写的，必须是 NOT_WRITTEN
    neg = next((n for n in sorted(gmap)
                if n not in rmods and n not in trk and n not in loc), None)
    b = rows.get(neg, {}).get('bucket')
    ok = (b == 'NOT_WRITTEN')
    print(f'  [{"OK" if ok else "FAIL"}] 正例 未写 {neg} -> {b}（必须 NOT_WRITTEN）')
    rc |= 0 if ok else 1

    # 反例：往 rtl 模块表塞一个 golden 里不存在的名字 ⇒ 必须进 RTL_INTERNAL，
    #       不许被当成"已写目标"混进任何一个 WRITTEN_* 桶
    fake = 'xs_definitely_not_a_golden_module'
    r2 = dict(rmods); r2[fake] = ['rtl/fake.sv']
    rows2, internal2 = classify(gmap, r2, trk, loc, 'both', axis)
    ok = (fake in internal2) and (fake not in rows2)
    print(f'  [{"OK" if ok else "FAIL"}] 反例 非 golden 名 {fake} -> '
          f'{"RTL_INTERNAL" if fake in internal2 else "混进了目标表"}')
    rc |= 0 if ok else 1

    # 反例 2：台账里有、rtl 里没有的键 ⇒ 必须进 LEDGER_ONLY，不许落 NOT_WRITTEN
    ghost = 'xs_ghost_ledger_key'
    t2 = dict(trk); t2[ghost] = ('SUCCEEDED', 'fake.tsv')
    g2 = dict(gmap); g2[ghost] = None          # 假装 golden 里有
    rows3, _ = classify(g2, rmods, t2, loc, 'tracked', axis)
    ok = rows3[ghost]['bucket'] == 'LEDGER_ONLY'
    print(f'  [{"OK" if ok else "FAIL"}] 反例 台账有/rtl 无 -> {rows3[ghost]["bucket"]}'
          '（必须 LEDGER_ONLY，不许默默算成 NOT_WRITTEN 以外的东西）')
    rc |= 0 if ok else 1

    # 反例 3：★golden 复用件不许混进"待签核"名单★
    #   TLBFA_1 在 rtl/ 里有同名文件，但三轴表记 GOLDEN_REUSE/PROVEN_IN_CONE。
    #   本工具第一版正是把它塞进了 WRITTEN_UNPROVEN —— 会害人去重签一个
    #   不该重签的目标。这条负测钉住它。
    for reuse in ('TLBFA_1', 'TLBFA_2', 'TLBFA_3'):
        b = rows.get(reuse, {}).get('bucket')
        ok = b is not None and b.startswith('GOLDEN_REUSE')
        print(f'  [{"OK" if ok else "FAIL"}] 反例 golden 复用件 {reuse} -> {b}'
              '（必须 GOLDEN_REUSE_*，不许进 WRITTEN_UNPROVEN）')
        rc |= 0 if ok else 1

    print('负测', 'PASS' if rc == 0 else 'FAIL')
    return rc


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--source', choices=('tracked', 'local', 'both'), default='tracked')
    ap.add_argument('--xstile-only', action='store_true')
    ap.add_argument('--top', type=int, default=0, help='只列 golden 行数最大的 N 个')
    ap.add_argument('--bucket', default='WRITTEN_UNPROVEN')
    ap.add_argument('--selftest', action='store_true')
    a = ap.parse_args()
    if a.selftest:
        return selftest()

    gmap, rmods = golden_modules(), rtl_modules()
    trk, loc = tracked_green(), local_green()
    axis = three_axis()
    rows, internal = classify(gmap, rmods, trk, loc, a.source, axis)
    tile = xstile_closure()

    src_note = {
        'tracked': 'tracked 台账 docs/fm_round_*.tsv（★clean clone 可复现★）',
        'local':   '本地 evidence/*/<top>/receipt.json（★依赖本地 evidence，clean clone 不可复现★）',
        'both':    'tracked 台账 + 本地 evidence，分歧单列 STALE_LEDGER'
                   '（★含本地 evidence，clean clone 不可复现★）',
    }[a.source]
    print(f'# 数据源：{src_note}')
    print(f'# golden 目标 {len(gmap)} 个；rtl 定义 {len(rmods)} 个 module，'
          f'其中 {len(internal)} 个没有 golden 同名件（可读核/共享辅助件，'
          f'不是签核目标，不计入分母）')
    print(f'# tracked 台账绿判决 {len(trk)} 个；本地 evidence 绿判决 {len(loc)} 个')
    print(f'# XSTile 闭包 {len(tile)} 个模块'
          + ('（本次只列闭包内）' if a.xstile_only else '（本次不过滤）'))
    cnt = collections.Counter(r['bucket'] for r in rows.values())
    order = ('WRITTEN_PROVEN', 'WRITTEN_UNPROVEN', 'STALE_LEDGER',
             'GOLDEN_REUSE_IN_CONE', 'GOLDEN_REUSE_UNPROVEN', 'PROVEN_IN_CONE_ONLY',
             'AXIS_MISMATCH', 'LEDGER_ONLY', 'NOT_WRITTEN')
    assert sum(cnt[k] for k in order) == len(rows), '分桶不穷尽/有重叠'
    print('# 分桶（互斥且穷尽，和 == golden 目标数）：')
    for k in order:
        print(f'#   {k:<24} {cnt[k]}')
    sel = [r for r in rows.values() if r['bucket'] == a.bucket]
    if a.xstile_only:
        sel = [r for r in sel if r['name'] in tile]
    for r in sel:
        r['lines'] = golden_lines(r['name'], gmap)
    sel.sort(key=lambda r: -r['lines'])
    if a.top:
        sel = sel[:a.top]
    print(f'#\n# 桶 {a.bucket}：{len(sel)} 个'
          + ('（XSTile 闭包内）' if a.xstile_only else ''))
    print('golden_lines\tin_xstile\taxis_rw/axis_fc\tmodule\timpl_file')
    for r in sel:
        print(f'{r["lines"]}\t{"Y" if r["name"] in tile else "N"}\t'
              f'{r["axis_rw"]}/{r["axis_fc"]}\t{r["name"]}\t{r["impl"] or "-"}')
    return 0


if __name__ == '__main__':
    sys.exit(main())
