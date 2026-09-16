#!/usr/bin/env python3
"""rewrite_coverage.py —— 重写覆盖率台账（codex 0161 要求的三个独立指标）。

**为什么要有这张表**：
"253/253" 是 **FM 目标集**的口径，很容易被读成"重写完成了"。实测不是 ——
那 253 个目标里绝大多数是中小模块及其**单态化变体族**（SRAMTemplate 42 个变体、
NewPipelineConnectPipe 18 个、ICacheMSHR 14 个…），而主干（Rob / Backend /
CtrlBlock / Predictor / StoreQueue / 各类 Entries）基本没动。

codex 0161 的原话：

    From now on keep these three metrics separate in every report:
      1. FM target status: 253/253 for the currently configured target set.
      2. Unique readable-design coverage.
      3. Golden-line replacement coverage.
    Do not describe 253/253 as completion of the RTL rewrite.
    ...
    Maintain an explicit remaining-universe ledger by unique design and by golden
    source lines. **Variant FM receipts remain useful but must not inflate rewrite
    coverage.**

最后那句是本脚本的设计约束：**同一个设计的 N 个变体只算一个设计**，
而按行数统计时每个变体的 golden 行数**都算**（因为它们确实各占一份 golden 源码）。

## 三个口径分别是什么

- **FM 目标**：`verif/ut/*/Makefile` 的 `FM_VARIANTS` 并集。这是"跑了证明的东西"。
- **不同设计**：golden 模块名去掉尾部 `_<数字>` 后的不同基名。这是"讲清了多少种机制"。
- **golden 行数**：每个 golden 模块定义所在文件的行数。这是"替换掉了多少源码"。

## ★2026-09-16：把"已重写"的判据从「文件在不在」改成「有没有证据」★

原判据是 `rewritten_modules()` = `glob('rtl/**/*.sv')` 抓 module 名 —— 即
**"rtl/ 里有同名 module" 就算已重写**。LoadQueueReplay 的考古 worker 实测发现这是个
**假绿口子**：把一个 3,149 行、只实现约两成逻辑的**骨架**放进 rtl/，覆盖率立刻
从 7.4% 跳到 11.0%（凭空记账 138,860 行 golden），而任何人放个空壳进去都会如此。

这正是本仓其他闸一直在防的形态，结果出现在覆盖率台账自己身上。

修法**不是**加一张 WIP 声明表 —— 声明会忘、会过期，是 fail-open 的。改成按**证据**记账：

    written  模块名出现在 rtl/           （原口径，保留，但不再当头条数字）
    proven   written 且有绿判决证据      （★头条数字★）

绿判决证据 = `docs/fm_round_20260914.tsv` 里 SUCCEEDED / PASS_DEAD_REF，
或 `docs/fastlane_ledger.tsv` 里 WORKING_PASS / WORKING_PASS_DEAD_REF。
骨架没有 UT、没有 FM，于是自然记 0 —— 不需要谁记得去声明它是骨架。

实测口径切换的代价很小：105 个计入的设计族里 **98 个本来就有绿判决证据**，
无证据的 7 个只占 6,944 行（2.4%），且各有已文档化的原因（StorePipe 是
EXPLICITLY_UNPROVABLE、OpenLLC 是资源阻塞…）。它们现在落进 written 而不进 proven，
两个数并排列出，谁都看得见差在哪。

## 排除项（都有理由，且在输出里显式列出）

- 厂商存储宏 / 行为级 RAM（`array_*` / `ram_*` / `*_ext`）：两侧同源黑盒，不是重写对象。
- MBIST / DFT 扫描件：扫描链基础设施。
- `LogPerfEndpoint`：9903 端口全是 input 的纯观测 sink，19 万行全是端口表，
  计进分母会让覆盖率失真。**它被排除这件事本身要显示出来**，不能悄悄扣掉。
"""
import argparse
import collections
import pathlib
import re
import sys

REPO = pathlib.Path(__file__).resolve().parent.parent
GOLDEN = pathlib.Path('/home/eda/xs-env/G1-canonical/golden-rtl')
OUT = REPO / 'docs' / 'rewrite_coverage.tsv'

MODULE_RE = re.compile(r'^module\s+([A-Za-z_]\w*)', re.M)
VARIANT_RE = re.compile(r'_\d+$')

# 排除类：(判据, 名称, 为什么排除)
EXCLUSIONS = [
    (lambda n: re.match(r'^(array|ram|sram)_', n) or n.endswith('_ext'),
     'vendor_macro', '厂商存储宏/行为级RAM：两侧同源黑盒，不是重写对象'),
    (lambda n: 'Mbist' in n or n.startswith('BoreBd'),
     'mbist_dft', 'MBIST/DFT 扫描链基础设施'),
    (lambda n: n == 'LogPerfEndpoint',
     'observation_sink', '9903 端口全 input 的纯观测 sink，19 万行全是端口表'),
]


def classify(name):
    for pred, tag, _ in EXCLUSIONS:
        if pred(name):
            return tag
    return None


def golden_modules():
    """{module_name: (file, lines)}"""
    out = {}
    for f in sorted(list(GOLDEN.glob('*.sv')) + list(GOLDEN.glob('*.v'))):
        txt = f.read_text(errors='replace')
        n = len(txt.splitlines())
        for m in MODULE_RE.finditer(txt):
            out[m.group(1)] = (f.name, n)
    return out


def rewritten_modules():
    """可读侧**声明**的模块名集合（written 口径）。

    注意这只说明"rtl/ 里有这个 module 名"，**不说明它写完了**。一个只实现两成
    逻辑的骨架同样会出现在这里 —— 所以头条数字用的是下面 proven_modules() 的口径。
    """
    out = set()
    for p in sorted((REPO / 'rtl').glob('**/*.sv')):
        out |= set(MODULE_RE.findall(p.read_text(errors='replace')))
    return out


def proven_modules():
    """有**绿判决证据**的模块名集合（proven 口径，头条数字用它）。

    证据只认两处已提交的台账，都是机器产物、可复算：
      docs/fm_round_20260914.tsv   SUCCEEDED / PASS_DEAD_REF
      docs/fastlane_ledger.tsv     WORKING_PASS / WORKING_PASS_DEAD_REF（UT+FM 都过）

    ★为什么不接受"声明自己写完了"★：声明是 fail-open 的 —— 忘了写、写错、过期，
    都会让覆盖率虚高，而虚高的覆盖率正是本仓在防的那类假绿。证据式记账不需要
    任何人记得做什么：没跑出绿判决，就不计分。
    """
    ok = set()
    rnd = REPO / 'docs' / 'fm_round_20260914.tsv'
    if rnd.exists():
        for l in rnd.read_text(errors='replace').splitlines():
            if l.startswith('#') or l.startswith('target'):
                continue
            c = l.split('\t')
            if len(c) > 1 and c[1] in ('SUCCEEDED', 'PASS_DEAD_REF'):
                ok.add(c[0])
    led = REPO / 'docs' / 'fastlane_ledger.tsv'
    if led.exists():
        for l in led.read_text(errors='replace').splitlines():
            if l.startswith('#'):
                continue
            c = l.split('\t')
            if len(c) > 1 and c[1] in ('WORKING_PASS', 'WORKING_PASS_DEAD_REF'):
                ok.add(c[0])
    if not ok:
        raise SystemExit('proven_modules: 两张台账都读不出绿判决 —— 拒绝按 0 继续')
    return ok


def fm_targets():
    """FM 目标全集 —— ★用仓里的 make 权威引擎，不要自己写正则★。

    本轮 D70 已经证明过：正则解析 `FM_VARIANTS` 是个**缺陷模型**（它不展开
    `$(VARIANTS)` 之类的变量，实测 248 vs 权威 272，漏 24 个）。我第一版这里
    照样写了正则，解析出 250 而实际是 253 —— 同一个坑第二次。改用
    `fm_target_universe.targets_at()`（make 展开 git archive 出的临时树，
    engine='both' 时与正则交叉校验、不一致就 fail-closed 抛 EngineDisagree）。
    """
    import subprocess
    sys.path.insert(0, str(REPO / 'scripts'))
    import fm_target_universe as U
    head = subprocess.check_output(['git', 'rev-parse', 'HEAD'],
                                   cwd=str(REPO)).decode().strip()
    tmap, unresolved = U.targets_at(str(REPO), head)
    if unresolved:
        raise SystemExit('fm_target_universe 未完全展开: %s' % unresolved[:3])
    return set(tmap)


def build():
    gold = golden_modules()
    done = rewritten_modules()
    prov = rewritten_modules() & proven_modules()   # written 且有绿判决证据
    targets = fm_targets()

    excl = collections.Counter()
    real = {}
    for name, (f, n) in gold.items():
        tag = classify(name)
        if tag:
            excl[tag] += 1
        else:
            real[name] = (f, n)

    base = lambda n: VARIANT_RE.sub('', n)
    fam = collections.defaultdict(list)
    for name in real:
        fam[base(name)].append(name)

    fam_done = {b for b, ms in fam.items() if any(m in done for m in ms)}
    fam_prov = {b for b, ms in fam.items() if any(m in prov for m in ms)}
    lines_tot = sum(n for _, n in real.values())
    lines_done = sum(n for m, (_, n) in real.items() if m in done)
    lines_prov = sum(n for m, (_, n) in real.items() if m in prov)

    rows = []
    rows.append('# 重写覆盖率台账（codex 0161）。复算: python3 scripts/rewrite_coverage.py')
    rows.append('# ★三个口径必须分开报，不得互相冒充★：')
    rows.append('#   fm_targets      跑了证明的目标数（含同一设计的 N 个变体）')
    rows.append('#   unique_design   golden 模块名去掉尾部 _<数字> 后的不同基名数')
    rows.append('#   golden_lines    每个 golden 模块定义所在文件的行数之和')
    rows.append('#')
    rows.append('# ★written vs proven（2026-09-16 加）★')
    rows.append('#   written  模块名出现在 rtl/ —— **不说明它写完了**，骨架同样算 written')
    rows.append('#   proven   written 且有绿判决证据（fm_round 的 SUCCEEDED/PASS_DEAD_REF')
    rows.append('#            或 fastlane_ledger 的 WORKING_PASS[_DEAD_REF]）')
    rows.append('#   ★头条数字看 proven★。起因：一个 3,149 行、只实现约两成逻辑的')
    rows.append('#   LoadQueueReplay 骨架放进 rtl/，旧口径下覆盖率从 7.4% 跳到 11.0%，')
    rows.append('#   凭空记账 138,860 行 golden。判据改成按证据记，骨架自然记 0，')
    rows.append('#   不依赖任何人记得去声明"这是骨架"。')
    rows.append('# codex 0161: "Variant FM receipts remain useful but must not inflate')
    rows.append('#              rewrite coverage."')
    rows.append('#')
    rows.append('# 排除项（显式列出，不悄悄扣）：')
    for _, tag, why in EXCLUSIONS:
        rows.append('#   %-16s %4d 个   %s' % (tag, excl[tag], why))
    rows.append('#')
    rows.append('metric\tdone\ttotal\tpercent')
    # ★fm_targets 的分母是**配置集**，不是本轮实跑数★
    # 实测：配置 273，本轮实跑 253。差的 21 个大多是 worker 在自己分支验过、
    # 没进汇总表的（TLBuffer/SRAMTemplate 变体），另有 OpenLLC 资源阻塞、
    # StorePipe 是已文档化的 EXPLICITLY_UNPROVABLE。把 253 当分母会让这一栏
    # 永远是 100%，那就失去意义了。
    ran = set()
    rnd = REPO / 'docs' / 'fm_round_20260914.tsv'
    if rnd.exists():
        for l in rnd.read_text(errors='replace').splitlines():
            if l and not l.startswith('#') and not l.startswith('target'):
                ran.add(l.split('\t')[0])
    nran = len(targets & ran)
    rows.append('fm_targets_configured\t%d\t%d\t%.1f'
                % (nran, len(targets), nran * 100.0 / len(targets)))
    rows.append('unique_design_written\t%d\t%d\t%.1f'
                % (len(fam_done), len(fam), len(fam_done) * 100.0 / len(fam)))
    rows.append('unique_design_proven\t%d\t%d\t%.1f'
                % (len(fam_prov), len(fam), len(fam_prov) * 100.0 / len(fam)))
    rows.append('golden_lines_written\t%d\t%d\t%.1f'
                % (lines_done, lines_tot, lines_done * 100.0 / lines_tot))
    rows.append('golden_lines_proven\t%d\t%d\t%.1f'
                % (lines_prov, lines_tot, lines_prov * 100.0 / lines_tot))
    rows.append('#')
    rows.append('# written 里没有绿判决证据的设计族（差额都在这儿，逐个列出不藏）：')
    for b in sorted(fam_done - fam_prov):
        n = sum(real[m][1] for m in fam[b] if m in done)
        rows.append('#   %-44s %8d 行' % (b, n))
    rows.append('#')
    rows.append('# 剩余最大的 30 个（按 golden 行数）—— 下一波排期的候选')
    rows.append('remaining_design\tgolden_lines\tvariants\tscope')
    scope = {}
    uni = REPO / 'docs' / 'g1_universe.tsv'
    if uni.exists():
        for l in uni.read_text(errors='replace').splitlines():
            if l.startswith('#'):
                continue
            c = l.split('\t')
            if len(c) > 3:
                scope[c[0]] = c[3]
    rest = sorted(((sum(real[m][1] for m in ms if m not in done), b, ms)
                   for b, ms in fam.items() if b not in fam_done),
                  reverse=True)
    for n, b, ms in rest[:30]:
        rows.append('%s\t%d\t%d\t%s' % (b, n, len(ms), scope.get(b, '-')))
    return '\n'.join(rows) + '\n', (len(targets), len(fam_done), len(fam),
                                    lines_done, lines_tot, len(fam_prov), lines_prov)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--check', action='store_true', help='只校验台账与重算结果一致')
    a = ap.parse_args()
    text, (nt, fd, ft, ld, lt, fp, lp) = build()
    if a.check:
        if not OUT.exists():
            print('FAIL: %s 不存在' % OUT)
            return 1
        if OUT.read_text() != text:
            print('FAIL: %s 与重算结果不一致（DRIFT）' % OUT)
            return 1
        print('rewrite_coverage --check: 逐字节一致')
        return 0
    OUT.write_text(text)
    print('  FM 目标          %d' % nt)
    print('  不同设计 written %d / %d  = %.1f%%' % (fd, ft, fd * 100.0 / ft))
    print('  不同设计 proven  %d / %d  = %.1f%%' % (fp, ft, fp * 100.0 / ft))
    print('  golden 行 written %s / %s = %.1f%%'
          % (format(ld, ','), format(lt, ','), ld * 100.0 / lt))
    print('  ★golden 行 proven %s / %s = %.1f%%★'
          % (format(lp, ','), format(lt, ','), lp * 100.0 / lt))
    print('  已写 %s' % OUT)
    return 0


if __name__ == '__main__':
    sys.exit(main())
