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
    """可读侧声明的模块名集合。"""
    out = set()
    for p in sorted((REPO / 'rtl').glob('**/*.sv')):
        out |= set(MODULE_RE.findall(p.read_text(errors='replace')))
    return out


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
    lines_tot = sum(n for _, n in real.values())
    lines_done = sum(n for m, (_, n) in real.items() if m in done)

    rows = []
    rows.append('# 重写覆盖率台账（codex 0161）。复算: python3 scripts/rewrite_coverage.py')
    rows.append('# ★三个口径必须分开报，不得互相冒充★：')
    rows.append('#   fm_targets      跑了证明的目标数（含同一设计的 N 个变体）')
    rows.append('#   unique_design   golden 模块名去掉尾部 _<数字> 后的不同基名数')
    rows.append('#   golden_lines    每个 golden 模块定义所在文件的行数之和')
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
    rows.append('unique_design\t%d\t%d\t%.1f'
                % (len(fam_done), len(fam), len(fam_done) * 100.0 / len(fam)))
    rows.append('golden_lines\t%d\t%d\t%.1f'
                % (lines_done, lines_tot, lines_done * 100.0 / lines_tot))
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
                                    lines_done, lines_tot)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--check', action='store_true', help='只校验台账与重算结果一致')
    a = ap.parse_args()
    text, (nt, fd, ft, ld, lt) = build()
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
    print('  不同设计         %d / %d  = %.1f%%' % (fd, ft, fd * 100.0 / ft))
    print('  golden 行数      %s / %s = %.1f%%'
          % (format(ld, ','), format(lt, ','), ld * 100.0 / lt))
    print('  已写 %s' % OUT)
    return 0


if __name__ == '__main__':
    sys.exit(main())
