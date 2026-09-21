#!/usr/bin/env python3
"""gen_param_matrix.py —— OthersEntry* 18 个变体的**核参数矩阵**（机械生成，可 --check）。

## 为什么要这一张，`OthersEntry_field_matrix/matrix.md` 不够吗

那一张量的是 **golden 端口/字段的使用情况**（24 个变体 × 端口形状）。
这一张量的是**薄 wrapper 发给共享核 `xs_iq_entry` 的实参**，以及每个实参
「是从哪儿量出来的」。两者的分界正是 2026-09-21 这次事故的现场：

  共享核的参数 API 在 `29dd150a` 变了（E1+E2：唤醒匹配从「每源一个 type 位」
  换成「按源分份的 kind × 按窗口分份的 wen 存在性」），
  `othersentry_gen.py` 与它生成的 18 个 wrapper 一个都没重生成 ——
  于是整族连 elaborate 都过不去（`Parameter 'IQ_TYPE_BIT' not defined`）。

★幂等闸（`scripts/test_gen_idempotent.py`）对这一类天然无能★：
生成器和产物是**一起**陈旧的，重跑逐字不变，闸正确地绿。
事故当天 18/18 个 `gen.py --check` 全部 rc=0。能发现它的只有 elaborate / FM。
所以这张表存在的意义不是"再加一道闸"，而是**把实参与其量法写下来**，
让下一次核的参数表变动时，有一份可以逐列对照的东西。

## 用法
    python3 verif/ut/OthersEntry_field_matrix/gen_param_matrix.py            # 重写 PARAM_MATRIX.md
    python3 verif/ut/OthersEntry_field_matrix/gen_param_matrix.py --check    # 非零退出=漂移

★为什么放在 `OthersEntry_field_matrix/` 而不是 `OthersEntry_common/`★：
`scripts/test_gen_idempotent.py` 按 `verif/ut/*/gen*.py` 发现生成器，
并把 `*_common/` 下的一律当成"库"排除（它们需要模块名参数）。
放这里且叫 `gen_*.py`，这道闸就**自动**把它的 `--check` 纳入，不用改任何共享文件；
放 `_common/` 则会被静默排除 —— 一份没人复算的表迟早腐烂。
"""
import pathlib, re, sys

HERE = pathlib.Path(__file__).resolve().parent
REPO = HERE.parents[2]
sys.path.insert(0, str(REPO / 'verif' / 'ut' / 'Entries_common'))
sys.path.insert(0, str(REPO / 'verif' / 'ut' / 'OthersEntry_common'))
from othersentry_gen import OthersVariant                      # noqa: E402

OUT = HERE / 'PARAM_MATRIX.md'


def mods():
    return sorted(p.stem for p in (REPO / 'rtl' / 'backend').glob('OthersEntry*.sv'))


def actuals(mod):
    """从**已生成的 wrapper** 里把实参逐个抠出来（不是重新推一遍）。"""
    txt = (REPO / 'rtl' / 'backend' / f'{mod}.sv').read_text()
    blk = re.search(r'xs_iq_entry #\((.*?)\n  \) u_entry', txt, re.S).group(1)
    return dict(re.findall(r'\.([A-Z_0-9]+)\(([^\n]*?)\),?\s*(?=\n|$)', blk))


def build():
    rows = []
    for m in mods():
        ov = OthersVariant(m)
        v, a = ov.v, actuals(m)
        rows.append((m, ov, v, a))
    L = []
    A = L.append
    A('# OthersEntry* 18 变体 × 核参数矩阵（机械生成，勿手改）')
    A('')
    A('由 `verif/ut/OthersEntry_field_matrix/gen_param_matrix.py` 生成；`--check` 复算。')
    A('实参一列**从已生成的 wrapper 里抠出来**，不是再推一遍 ——')
    A('推一遍只能证明"生成器自洽"，抠出来才能证明"仓里那份就是它"。')
    A('')
    A('## A. 家族形状（全部来自父级 `Entries_common/entries_gen.py` 的 `Variant`，')
    A('   而 `Variant` 构造时已断言 enq/simp/comp 三个 golden 模块共用同一套路由）')
    A('')
    A('| 变体 | 父级 Entries | 角色 | 例化数 | NUM_REGSRC | NUM_WK_WB | NUM_WK_IQ '
      '| NUM_DEQ_PORTS | NUM_FU_BIT | LD_PIPES | LD_DEP_W | PL_DEQ_W | PL_TRANS_W | 端口数 |')
    A('|---|---|---|---|---|---|---|---|---|---|---|---|---|---|')
    for m, ov, v, a in rows:
        A(f'| `{m}` | `{ov.parent}` | {ov.role} | ×{ov.count} | {v.n_regsrc} | {v.n_wk} '
          f'| {v.n_wk_iq} | {v.n_deq} | {len(v.fu_bits)} | {v.ld_pipes} | {v.ld_dep_w} '
          f'| {v.pl_deq_w} | {v.pl_trans_w} | {len(ov.ports)} |')
    A('')
    A('## B. E1/E2 唤醒匹配参数（★本轮修的就是这几列★）')
    A('')
    A('`SRC_MATCH_KIND[s]`：0=MK_GP（isFp&fpWen | isXp&rfWen | isVp&vecWen）、')
    A('1=MK_V0（isV0&v0Wen，★判据是 bit3 不是 bit2★）、2=MK_VL（isVp&vlWen）。')
    A('完全由 `NUM_REGSRC` 决定：==5 则 `0,0,0,1,2`，否则全 0（`EntryBundles.scala:185/241`）。')
    A('')
    A('`*_WEN_PRESENT`：该总线**整条的并集**（位序 `{vlWen,v0Wen,vecWen,fpWen,rfWen}`），')
    A('核在 elaborate 期据此把不存在的项连同它的 srcType 位**整项剪掉** —— ★不是喂 0★。')
    A('延迟窗口（`*D_*`）OthersEntry 的 golden 根本没有那组端口，故一律空集。')
    A('')
    A('| 变体 | SRC_MATCH_KIND | WB_WEN_PRESENT | WBD | IQ_WEN_PRESENT | IQD | WB 逐路 wen 分段 |')
    A('|---|---|---|---|---|---|---|')
    for m, ov, v, a in rows:
        seg = {}
        for w, s in sorted(ov.wen_lane['wb'].items()):
            seg.setdefault(','.join(sorted(s)), []).append(w)
        segs = '; '.join(f'{k}@{min(ws)}..{max(ws)}' for k, ws in seg.items())
        A(f"| `{m}` | `{a['SRC_MATCH_KIND']}` | `{a['WB_WEN_PRESENT']}` | "
          f"`{a['WBD_WEN_PRESENT']}` | `{a.get('IQ_WEN_PRESENT','—(NUM_WK_IQ=0)')}` | "
          f"`{a.get('IQD_WEN_PRESENT','—')}` | {segs} |")
    A('')
    A('★向量 6 个变体的 `WB 逐路 wen 分段` 一列就是"整条总线一个字段"那种旧写法错在哪★：')
    A('lane 0..5 只有 vecWen、6..11 只有 v0Wen、12..15 只有 vlWen，')
    A('连线必须**逐路**取集合，剪项才用整条并集（并集 ∩ kind 给出的项集与逐路等价，')
    A('因为 `SRC_WB_MASK` 已把每个源限制在带它那个字段的那几路上）。')
    A('')
    A('## C. ★"按端口有无发参数"的逐条语义核对★')
    A('')
    A('EnqEntry 族 `6ad7839a` 的真 bug 是：`HAS_LD_DEP` 按「enq 口有没有某输入」发，')
    A('而参数在核里管的是「条目里存不存那组影子寄存器」，两者语义不一致，')
    A('结果 6 个变体把一组**活的**输出钉成常量 0。本族逐条排查如下。')
    A('')
    A('| 参数 | 生成器怎么量 | 核里的真实语义 | 交叉印证 | 结论 |')
    A('|---|---|---|---|---|')
    A('| `HAS_LD_DEP` | `io_commonIn_enq_bits_status_srcStatus_0_srcLoadDependency_0` 在不在 '
      '| `if (HAS_LD_DEP) g_ld_dep / else g_no_ld_dep`：条目里存不存那组影子寄存器 '
      '| 父级实参 `HAS_LD_DEP && (L_IS_ENQ \\|\\| L_IS_TRANS \\|\\| COMP_HAS_LD_DEP)` 求值 '
      '+ 本模块 simp 看 transEntry / comp 看 entry 出口 | **18/18 一致，本族没有那个 bug**；'
      '原因：OthersEntry 的 enq 口来自上一级的 transEntry，而 transEntry 带不带 '
      'srcLoadDependency 恰好等于「影子寄存器活不活」 |')
    A('| `HAS_LD1_CANCEL` | `io_commonIn_ldCancel_0_ld1Cancel` 在不在 '
      '| LoadShouldCancel 里 ld1 那一项在不在（留着会把 dep 的 bit0 留在锥里）'
      '| 断言 == 父级 `v.has_ld1` | 18/18 一致 |')
    A('| `LD_PIPES` | 数 `io_commonIn_ldCancel_<q>_ld2Cancel` 的条数 '
      '| 每源几条 load 流水影子 | 断言 == 父级 `v.n_ld_cancel` | 18/18 一致 |')
    A('| `NUM_DEQ_PORTS` | 父级 `v.n_deq` | deqPortIdx 寄存器存不存 '
      '| 断言 `io_commonOut_deqPortIdxRead` 在不在 == (n_deq==2) | 18/18 一致 |')
    A('| `IS_TRANS` | 角色（golden `Entries*` 里的实例名 `othersEntriesSimp_*`）'
      '| 产不产 transEntry / 有没有 trans_sel | 断言 `io_commonIn_transSel` 与 '
      '`io_commonOut_transEntry_valid` 都与角色相符 | 18/18 一致 |')
    A('| `HAS_DBG_OUT` | 恒 1 | 7 组 debug/perf 出口产不产 '
      '| 条目单独成模块时 golden 确有这 7 组端口（24/24） | — |')
    A('| `*_WEN_PRESENT` | **本模块自己的**端口表逐路量 '
      '| elaborate 期剪项 | (a) 与父级从 EnqEntry 量的那份逐路比对；'
      '(b) 模型展开的 (srcType 位, wen) 对表 == 本模块 golden 实测对表 | 18/18 零处不符 |')
    A('')
    A('| `HAS_LD_DEP` 逐变体读数 | 角色 | 自量(enq 口) | 父级 `has_ld_dep` '
      '| 父级 `comp_has_ld_dep` | 父级传给本角色的实参 | 一致 |')
    A('|---|---|---|---|---|---|---|')
    for m, ov, v, a in rows:
        pa = v.has_ld_dep if ov.is_trans else (v.has_ld_dep and v.comp_has_ld_dep)
        A(f'| `{m}` | {ov.role} | {int(ov.has_ld_dep)} | {int(v.has_ld_dep)} '
          f'| {int(v.comp_has_ld_dep)} | {int(bool(pa))} | '
          f'{"✔" if bool(pa) == ov.has_ld_dep else "★不一致★"} |')
    A('')
    return '\n'.join(L) + '\n'


def main():
    txt = build()
    if '--check' in sys.argv:
        if not OUT.exists() or OUT.read_text() != txt:
            print(f'DRIFT: {OUT}')
            return 1
        print(f'{OUT.name} 与 golden/生成物一致')
        return 0
    OUT.write_text(txt)
    print(f'wrote {OUT} ({txt.count(chr(10))} lines)')
    return 0


if __name__ == '__main__':
    sys.exit(main())
