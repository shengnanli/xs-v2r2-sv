#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""fm_predict.py —— FM `passing` 的**跑前登记 / 跑后对账**工具。

## 这是什么

把「跑前把预期 passing 写死并提交，跑完逐条对账，差额必须被指认」这套做法做成工具。
它在两个不相干的家族上连续零偏差：
  * OthersEntry 18/18，差全为 +0
  * ArrayMulDataModule 家族 5/5（4 个纯组合件逐位等于模型；第 5 个差 -31，
    而 receipt 里 `constant_reg` 恰好 = 31 —— 缺口被逐位解释掉）

## ★模型有前提，不说清就是误导★

    expected = Σ_(golden 闭包里每个**实例**) 寄存器位 + 顶层 output 端口位

**这个等式只在 `verification_merge_duplicated_registers = false` 时成立。**

为什么：merge 打开时 FM 会把「重复寄存器」合并成一个比较点，于是比较点数
**低于**寄存器位数，而且低多少取决于设计里有多少重复结构 —— 不是一个能从
golden 静态算出来的量。

实测（2026-09-20，本工具就是这么被逼出来的）：

| 目标 | merge_dup | 模型 | 实测 | 差 | 可指认 |
|---|---|---|---|---|---|
| `OthersEntry_72` | false | 1394 | 1394 | 0 | — |
| `ArrayMulDataModule` | false | 2692 | 2661 | 31 | `constant_reg`=31 ✔ |
| `IBuffer` | **true** | 8292 | 7902 | **390** | 只有 12（`constant_reg` 6 + `unread` 6）★378 指认不了★ |

所以 merge_dup=true 的目标，本工具给 **MODEL_NA**（模型不适用），
**不给绿也不给红** —— 谎称"差不多"才是最坏的选项。

## 差额怎么算才算"被指认"

    差额 = expected - actual
    可指认 = constant_reg + unread        （两者都直接从 receipt 读，不许手填）

`constant_reg`：FM 判成常量的寄存器不产生比较点。
`unread`：没开 vmucp 时，matched-but-not-compared 的点不计进 passing。
差额 == 可指认 -> 绿；否则红，并把**指认不了的余额**打出来。

## ★防"事后改模型迁就实测"★

`--check` 读的登记**来自 git HEAD，不是工作树**；并且要求登记所在的 commit
是 receipt 里 `impl_commit` 的**祖先**（`git merge-base --is-ancestor`）。
也就是说：预期必须在那次证明**之前**就已经进库。跑完再改登记不起作用。

## 用法

    python3 scripts/fm_predict.py model  <target> [--ut <UT目录裸名>]
    python3 scripts/fm_predict.py register <target> [...]     # 写登记，然后你去 commit
    python3 scripts/fm_predict.py check  <target> [...]       # 跑后对账
    python3 scripts/fm_predict.py recompute                   # ★改完模型必跑★全仓复算
    python3 scripts/fm_predict.py --selftest
"""
import argparse, json, os, pathlib, re, subprocess, sys

REPO = pathlib.Path(__file__).resolve().parents[1]
sys.path.insert(0, str(REPO / 'scripts'))
from fm_passing_model import model as compute_model, from_ut          # noqa: E402

REG_DIR = REPO / 'docs' / 'fm_predictions'
GREEN = {'SUCCEEDED', 'PASS_DEAD_REF'}


def git(*a):
    r = subprocess.run(['git', '-C', str(REPO)] + list(a),
                       stdout=subprocess.PIPE, stderr=subprocess.PIPE,
                       universal_newlines=True)
    return r.returncode, r.stdout.strip()


# ---------------------------------------------------------------------------
# ★FM_VARIANTS 由 make 自己展开★（codex 0244 B）
#
# 原先这里用 `^FM_VARIANTS = (.*)$` 正则逐词比对：`FM_VARIANTS = $(LEAVES)`、
# `FM_VARIANTS := $(VARIANTS)` 这类写法里只有字面量 `$(LEAVES)`，于是 46 个 UT 目录
# 的全部变体都被登记成 ut=null（model_applicable=false）。这**不是功能 FAIL**，
# 只是元数据枚举漏了。
#
# 修法不另造解析器：复用 `fm_target_universe._make_one` —— 在**目标自己的 UT
# 目录**里跑 `make --eval='<goal>: ; @printf ...' <goal>`，由 make 回答
# "$(strip $(FM_VARIANTS))" 是什么；ut_common.mk 的 `fm-%` 守卫也是拿这同一个
# 展开串做子串匹配，所以这就是"谁是 fm-<t> 合法目标"的权威口径。
# 与原实现一样读**工作树**（register 写的就是工作树登记）。
# ---------------------------------------------------------------------------
_VARIANT_CACHE = {}


def _ut_root(root=None):
    return pathlib.Path(root) if root else REPO / 'verif' / 'ut'


def variant_map(root=None, jobs=8):
    """{target: [ut_dir, ...]}, [错误…] —— 每个 UT 目录由 make 展开的 FM_VARIANTS 并集。

    逐目录跑不出来的记进错误表，**不吞**：调用方查不到 target 时要能区分
    "确实不在任何 FM_VARIANTS 里"与"有目录 make 没展开出来、可能就在那里"。
    """
    import concurrent.futures as cf
    import fm_target_universe as FTU                                # noqa: E402
    root = _ut_root(root)
    key = str(root)
    if key in _VARIANT_CACHE:
        return _VARIANT_CACHE[key]
    utdirs = sorted(d for d in root.glob('*') if (d / 'Makefile').is_file())
    out, errs = {}, []
    with cf.ThreadPoolExecutor(max_workers=max(1, jobs)) as ex:
        for fut in [ex.submit(FTU._make_one, d) for d in utdirs]:
            try:
                name, ts = fut.result()
            except FTU.MakeUnavailable as e:
                errs.append(str(e))
                continue
            for t in ts:
                out.setdefault(t, [])
                if name not in out[t]:
                    out[t].append(name)
    for v in out.values():
        v.sort()
    _VARIANT_CACHE[key] = (out, errs)
    return out, errs


def ut_of(target, explicit=None, root=None):
    """找这个 target 属于哪个 UT 目录（make 展开后的 FM_VARIANTS 里含它）。

    多个目录都含它时取字典序第一个（与原正则实现的 sorted 遍历同口径）。
    查不到且有目录展开失败 -> 退出（fail-closed），不把"没算出来"当"没有"。
    """
    if explicit:
        return explicit
    vm, errs = variant_map(root)
    if target in vm:
        return vm[target][0]
    if errs:
        sys.exit(f'{target}: 不在已展开的 FM_VARIANTS 里，但有 {len(errs)} 个 UT 目录 '
                 f'make 展开失败，无法断言它不是 FM target：{errs[:2]}')
    return None


def make_vars(utdir, names):
    """在 UT 目录里让 make 展开若干变量（同 `_make_one` 的打印 goal 做法，不跑配方）。"""
    import fm_target_universe as FTU                                # noqa: E402
    mark = FTU._MARK
    recipe = '; '.join('printf "%s%s=%%s\\n" "$(strip $(%s))"' % (mark, n, n)
                       for n in names)
    expr = '%s: ; @%s' % (FTU._PRINT_GOAL, recipe)
    r = subprocess.run(['make', '--no-print-directory', '--eval=' + expr,
                        FTU._PRINT_GOAL], cwd=str(utdir),
                       stdout=subprocess.PIPE, stderr=subprocess.PIPE,
                       universal_newlines=True)
    got = {}
    for ln in r.stdout.splitlines():
        if ln.startswith(mark):
            k, _, v = ln[len(mark):].partition('=')
            got[k] = v
    if r.returncode != 0 or set(got) != set(names):
        sys.exit(f'{utdir}: make 展开 {names} 失败 rc={r.returncode}: '
                 f'{(r.stderr or r.stdout).strip()[:200]}')
    return got


def merge_dup_of(ut):
    """从 UT 的 Makefile 读 FM_MERGE_DUP；没写 = FM 默认 true。"""
    if not ut:
        return None
    mk = REPO / 'verif' / 'ut' / ut / 'Makefile'
    if not mk.exists():
        return None
    m = re.search(r'^FM_MERGE_DUP\s*=\s*(\S+)', mk.read_text(errors='replace'), re.M)
    return (m.group(1).strip() if m else 'true')


def _literal_variants(ut, root=None):
    """`from_ut` 自己（正则、不展开）能看到的 FM_VARIANTS 词表。"""
    mk = _ut_root(root) / ut / 'Makefile'
    txt = re.sub(r'\\\n', ' ', mk.read_text(errors='replace'))
    m = re.search(r'^FM_VARIANTS[^\S\n]*=[^\S\n]*(.*)$', txt, re.M)
    return m.group(1).split() if m else []


def _model_via_make(target, ut, root=None):
    """`from_ut` 看不到的目标（变体来自 `$(LEAVES)` 等）：闭包变量也交给 make 展开，
    再按 `from_ut` 同样的规则（取 .sv 裸名、剔 FM_INTERFACE_ONLY）喂给模型。"""
    d = _ut_root(root) / ut
    v = make_vars(d, [f'FM_REF_DEPS_{target}', 'FM_INTERFACE_ONLY', 'FM_MERGE_DUP'])
    iface = set(v['FM_INTERFACE_ONLY'].split())
    exp = v[f'FM_REF_DEPS_{target}']
    deps = [x.split('/')[-1][:-3] for x in exp.split() if x.endswith('.sv')]
    deps = [x for x in deps if x not in iface]
    unexp = sorted(set(re.findall(r'\$\(([A-Za-z_]\w*)\)', exp)))
    return compute_model(target, deps, unexp), (v['FM_MERGE_DUP'] or 'true')


def predict_one(target, ut=None):
    ut = ut_of(target, ut)
    r, md = None, None
    if ut and target not in _literal_variants(ut):
        # ★只有 from_ut 看不到的目标才走 make 路径★：from_ut 看得到的目标
        # 一个字节都不变，已有登记无需复算。
        r, md = _model_via_make(target, ut)
    else:
        rows = from_ut(ut) if ut else None
        if rows:
            r = next((x for x in rows if x['top'] == target), None)
        md = merge_dup_of(ut)
    if r is None:
        r = compute_model(target, [])
    out = dict(target=target, ut=ut, regs=r['regs'], outs=r['outs'],
               expected=r['model'], merge_dup=md,
               model_applicable=(md == 'false'))
    # ★只有真有黑盒（或 deps 没读全）时才多这几个键★：其余目标的登记 JSON
    # 与加 BBPin 项之前逐字节相同。
    for k in ('bbin', 'bbox', 'bbox_unknown', 'deps_unexpanded'):
        if k in r:
            out[k] = r[k]
    return out


def reg_path(target):
    return REG_DIR / f'{target}.json'


def cmd_register(targets, ut=None, note=None):
    REG_DIR.mkdir(parents=True, exist_ok=True)
    for t in targets:
        p = predict_one(t, ut)
        # ★差额的解释写进登记本身，不要靠跑后补一句散文★
        # （用处见 SRAMTemplate_155/_166/_178：它们的差额来自 merge 合掉一对
        #   重复寄存器，而 `_judge` 只会给一条宽 regs 的"带内"弱结论；
        #   带内不等于说清楚了，所以把可判别的依据落在登记里。）
        if note:
            p['note'] = note
        f = reg_path(t)
        f.write_text(json.dumps(p, indent=2, ensure_ascii=False) + '\n')
        # ★这一行**不能**再叫 note★（2026-09-20 当场踩到并回滚过一轮）：
        # 原先它复用了参数名 `note`，于是第一个 target 写完之后，`note` 就变成了
        # 这句**给人看的提示语**，被原样写进后续每一个 target 的登记 JSON。
        # 实测后果：8 份登记里有 6 份的 `note` 是「★模型不适用★（merge_dup=true）」，
        # 而 _166/_178 **本该写的那条 merge 可判别依据被它顶掉了** ——
        # 登记里挂着一句正确但答非所问的话，比没有话更糟。
        # 展示用的字符串一律用独立名字，别和数据字段共用一个变量。
        disp = ('模型适用' if p['model_applicable'] else
                f'★模型不适用★（merge_dup={p["merge_dup"]}）')
        print(f'登记 {t}: expected={p["expected"]} (regs {p["regs"]} + outs {p["outs"]})'
              f'  {disp}{"  note=" + note if note else ""}  -> {f.relative_to(REPO)}')
    print('\n★下一步：git add docs/fm_predictions && git commit —— '
          'check 只认 git HEAD 里的登记，且要求它早于那次证明★')
    return 0


def load_registered(target):
    """★只认 git HEAD 里的登记★，工作树改了不算。"""
    rel = str(reg_path(target).relative_to(REPO))
    rc, out = git('show', f'HEAD:{rel}')
    if rc != 0:
        return None, f'登记文件不在 git HEAD 里（{rel}）—— 先 register 再 commit'
    return json.loads(out), None


def find_receipt(target):
    cands = sorted((REPO / 'evidence').glob(f'*/{target}/receipt.json'),
                   key=lambda p: p.stat().st_mtime)
    return cands[-1] if cands else None


def cmd_check(targets, receipts=None):
    rc_all = 0
    print(f'{"target":<24}{"预期":>8}{"实测":>8}{"差":>7}{"可指认":>8}  判决')
    for t in targets:
        reg, err = load_registered(t)
        if err:
            print(f'{t:<24}{"-":>8}{"-":>8}{"-":>7}{"-":>8}  ★{err}★')
            rc_all = 1
            continue
        rp = (pathlib.Path(receipts[t]) if receipts and t in receipts
              else find_receipt(t))
        if rp is None or not rp.exists():
            print(f'{t:<24}{reg["expected"]:>8}{"-":>8}{"-":>7}{"-":>8}  ★找不到 receipt★')
            rc_all = 1
            continue
        d = json.loads(rp.read_text())
        v = d['verdict_detail'] if isinstance(d['verdict_detail'], dict) \
            else json.loads(d['verdict_detail'])
        actual = v.get('passing')
        const = v.get('constant_reg') or 0
        unread = v.get('unread') or 0
        gap = reg['expected'] - (actual or 0)
        explained = const + unread
        # ★防事后改模型★：登记必须早于那次证明
        rel = str(reg_path(t).relative_to(REPO))
        rc, reg_commit = git('log', '-1', '--format=%H', '--', rel)
        impl_commit = d.get('impl_commit', '')
        anc = 0
        if reg_commit and impl_commit:
            anc, _ = git('merge-base', '--is-ancestor', reg_commit, impl_commit)
        verdict, bad = None, False
        if actual is None:
            verdict = '★receipt 里没有 passing★'; bad = True
        else:
            regs = reg.get('regs', 0)
            bad, why = _judge(reg['expected'], actual, const, unread,
                              reg['model_applicable'], anc == 0, regs)
            width = 100.0 * regs / reg['expected'] if reg['expected'] else 0
            verdict = {
                'EXACT': '逐位相等',
                'EXPLAINED': f'差额被指认（constant_reg {const} + unread {unread}）',
                'REGISTERED_TOO_LATE': '★登记不早于该次证明 —— 可能是事后补的★',
                'ABOVE_MODEL': f'★实测高于模型上界 {-gap} —— 模型或闭包算漏了★',
                'UNEXPLAINED': f'★余额 {gap - explained} 指认不了★',
                'UNEXPLAINED_EVEN_BOUNDED':
                    f'★连 merge 上界都兜不住：余额 {gap - explained - regs}★',
            }.get(why, why)
            if why.startswith('BOUNDED'):
                verdict = (f'落在 merge 带内 {why}（带宽 {width:.1f}%'
                           + ('，★带宽过大、这条结论近乎无信息★' if width > 30
                              else '') + '）')
        print(f'{t:<24}{reg["expected"]:>8}{(actual if actual is not None else 0):>8}'
              f'{gap:>7}{explained:>8}  {verdict}')
        if reg.get('note'):
            print(f'{"":<24}{"":>8}{"":>8}{"":>7}{"":>8}  登记时写明：{reg["note"]}')
        rc_all |= 1 if bad else 0
    print()
    print('结论：' + ('全部对上' if rc_all == 0 else '★有对不上的，按 fail 处理★'))
    return rc_all


# ---------------------------------------------------------------------------
def _judge(expected, actual, const, unread, applicable, anc_ok, regs=0):
    """纯判据，抽出来才好负测。返回 (是否红, 理由)。

    ★merge_dup=true 不是"模型不适用"，是"模型带一条上界宽 regs 的带"★
    （2026-09-20 修正，被 NewDispatch 逼出来的）：
    `merge_duplicated_registers` 只会把**寄存器**导出的比较点合并掉，
    顶层 output 端口的比较点一个都不会少。所以它能造成的偏差**上界就是 regs**：

        expected - regs - (const + unread)  <=  actual  <=  expected

    这条带有多宽完全取决于目标形状，必须报出来让人自己判：
      NewDispatch  regs 358 / outs 51563 -> 带宽占 0.7%，模型仍然很有用
      IBuffer      regs 7079 / outs 1213 -> 带宽占 85%，★这条带近乎无信息★
    第一版一律给 MODEL_NA 太钝：它把"带很窄"和"带几乎无限宽"混为一谈。
    """
    if not anc_ok:
        return True, 'REGISTERED_TOO_LATE'
    gap = expected - actual
    if gap < 0:
        return True, 'ABOVE_MODEL'
    explained = const + unread
    if applicable:
        if gap == explained:
            return False, 'EXACT' if gap == 0 else 'EXPLAINED'
        return True, 'UNEXPLAINED'
    # merge_dup=true：落在带内算过，但标明是**弱结论**并附带宽
    if gap <= explained + regs:
        return False, f'BOUNDED(<=+{regs})'
    return True, 'UNEXPLAINED_EVEN_BOUNDED'


def cmd_recompute():
    """★全仓复算★：拿**当前**模型重算每一份已登记的 expected，报出哪些变了。

    模型一旦改动就必须跑这个：登记文件是**静态快照**，模型变了它们不会自己变，
    于是"登记 vs 实测"的对账会静悄悄地拿旧上界去判新证明。
    变了的每一份都要有解释；有 receipt 的当场对账，没有的如实标"无 receipt 可对"。
    ★本命令只读不写★ —— 要不要改登记是人的决定（改了就意味着那次证明作废重跑）。
    """
    rows, rc = [], 0
    for f in sorted(REG_DIR.glob('*.json')):
        old_reg = json.loads(f.read_text())
        t = old_reg['target']
        try:
            new_reg = predict_one(t, old_reg.get('ut'))
        except SystemExit as e:
            rows.append((t, old_reg['expected'], None, f'★模型跑不出来：{e}★'))
            rc = 1
            continue
        if new_reg['expected'] == old_reg['expected']:
            continue
        rp = find_receipt(t)
        if rp is None:
            note = '★无 receipt 可对账★'
        else:
            d = json.loads(rp.read_text())
            v = d['verdict_detail'] if isinstance(d['verdict_detail'], dict) \
                else json.loads(d['verdict_detail'])
            act = v.get('passing')
            nat = d.get('native_facts', {}).get('native_verdict')
            if act is None:
                note = f'receipt 里没有 passing（native={nat}）'
            elif new_reg['expected'] == act:
                note = f'★修后逐位等于实测 {act}★'
            else:
                note = (f'实测 {act}，修后差 {new_reg["expected"] - act}'
                        f'（native={nat}）')
        rows.append((t, old_reg['expected'], new_reg['expected'], note))
    print(f'全仓复算：{len(list(REG_DIR.glob("*.json")))} 份登记，'
          f'{len(rows)} 份变了')
    for t, o, n, note in rows:
        print(f'  {t:<28}{o:>8} -> {str(n):>8}   {note}')
    if not rows:
        print('  （没有变化 —— 模型改动对已有登记逐字节无影响）')
    print()
    print('★变了的每一份都要有解释；解释不了就停下来，别改登记也别当没看见。★')
    return rc


def selftest_enum():
    """★变体枚举的双向自证★（codex 0244 B）：在临时 UT 树里造三种 Makefile。

      A  `FM_VARIANTS = $(LEAVES)`（make 变量引用，正则看不到）     -> 必须归 A
      B  `FM_VARIANTS = Baz`（字面量，不需展开）                    -> 必须归 B
      C  parse 期 `$(error)`（make 展开失败）                       -> 查不到的名字必须 fail-closed
    并核 make_vars 把 FM_REF_DEPS_<t> 也交给 make 展开（`$(DEPS)` 间接）。
    返回失败条数。
    """
    import tempfile, shutil
    fails = 0

    def ck(name, ok):
        nonlocal fails
        print(f'  [{"OK" if ok else "FAIL"}] {name}')
        fails += 0 if ok else 1

    tmp = pathlib.Path(tempfile.mkdtemp(prefix='fmpe-'))
    try:
        (tmp / 'A').mkdir(); (tmp / 'B').mkdir()
        (tmp / 'A' / 'Makefile').write_text(
            'LEAVES = Foo \\\n         Bar\nDEPS = X.sv Y.sv\n'
            'FM_VARIANTS = $(LEAVES)\nFM_REF_DEPS_Foo = $(DEPS)\n')
        (tmp / 'B' / 'Makefile').write_text('FM_VARIANTS = Baz\nFM_MERGE_DUP = false\n')
        ck('$(LEAVES) 展开：Foo -> A', ut_of('Foo', root=tmp) == 'A')
        ck('$(LEAVES) 展开（续行第二个词）：Bar -> A', ut_of('Bar', root=tmp) == 'A')
        ck('普通字面量：Baz -> B', ut_of('Baz', root=tmp) == 'B')
        ck('不在任何 FM_VARIANTS：Nope -> None', ut_of('Nope', root=tmp) is None)
        ck('from_ut 视角：A 只看得到字面 $(LEAVES)',
           _literal_variants('A', root=tmp) == ['$(LEAVES)'])
        ck('from_ut 视角：B 看得到 Baz', _literal_variants('B', root=tmp) == ['Baz'])
        v = make_vars(tmp / 'A', ['FM_REF_DEPS_Foo', 'FM_INTERFACE_ONLY', 'FM_MERGE_DUP'])
        ck('make_vars 展开 FM_REF_DEPS_Foo=$(DEPS)', v['FM_REF_DEPS_Foo'] == 'X.sv Y.sv'
           and v['FM_INTERFACE_ONLY'] == '' and v['FM_MERGE_DUP'] == '')
        ck('make_vars 读 FM_MERGE_DUP', make_vars(tmp / 'B', ['FM_MERGE_DUP'])
           == {'FM_MERGE_DUP': 'false'})
        (tmp / 'C').mkdir()
        (tmp / 'C' / 'Makefile').write_text('$(error boom)\n')
        _VARIANT_CACHE.pop(str(tmp), None)
        ck('有目录展开失败时 Foo 仍归 A', ut_of('Foo', root=tmp) == 'A')
        try:
            ut_of('Nope', root=tmp)
            ck('有目录展开失败时查不到 -> fail-closed（不返回 None）', False)
        except SystemExit:
            ck('有目录展开失败时查不到 -> fail-closed（不返回 None）', True)
    finally:
        shutil.rmtree(tmp, ignore_errors=True)
        for k in [k for k in _VARIANT_CACHE if k.startswith(str(tmp))]:
            _VARIANT_CACHE.pop(k)
    return fails


def selftest():
    """★判据必须先自证它看得见改变★：三绿三红，每一条都来自真实测出来的形态。"""
    cases = [
        # (名字, expected, actual, const, unread, applicable, anc_ok, 期望红?)
        ('正例 逐位相等（OthersEntry_72 实测 1394/1394）',
         1394, 1394, 0, 0, True, True, False),
        ('正例 差额被指认（ArrayMulDataModule 实测 2692/2661，constant_reg=31）',
         2692, 2661, 31, 0, True, True, False),
        ('正例 unread 也算指认（未开 vmucp 的一般形态）',
         100, 94, 0, 6, True, True, False),
        ('★反例 指认不了（IBuffer 实测 8292/7902，只有 const6+unread6=12）★',
         8292, 7902, 6, 6, True, True, True),
        ('★带宽过大时仍算过、但必须标成弱结论（IBuffer merge_dup=true，regs 7079）★',
         8292, 7902, 6, 6, False, True, False),
        ('★反例 merge 上界都兜不住（regs 只有 100，差额 390）★',
         8292, 7902, 6, 6, False, True, True, 100),
        ('正例 带很窄时模型仍有用（NewDispatch 形状：regs 358）',
         51921, 51600, 0, 0, False, True, False, 358),
        ('★反例 登记不早于证明（事后补登记）★',
         1394, 1394, 0, 0, True, False, True),
        ('★反例 实测高于模型上界（模型算漏了）★',
         100, 120, 0, 0, True, True, True),
    ]
    rc = 0
    print('fm_predict --selftest:')
    # --- register 的 note 不许被展示串污染（真踩过：6/8 份登记被顶掉）---------
    import inspect
    _src = inspect.getsource(cmd_register)
    _body = _src.split("f.write_text", 1)[1] if "f.write_text" in _src else ''
    _leak = ("\n        note = (" in _body)   # 循环体里重新赋值给参数名 note
    print(f'  [{"FAIL" if _leak else "OK"}] register 的展示串不得复用参数名 `note`'
          f'{"  ★又漏回去了★" if _leak else ""}')
    rc |= 1 if _leak else 0
    for case in cases:
        name, e, a, c, u, ap, anc, want_red = case[:8]
        regs = case[8] if len(case) > 8 else (7079 if not ap else 0)
        red, why = _judge(e, a, c, u, ap, anc, regs)
        ok = (red == want_red)
        print(f'  [{"OK" if ok else "FAIL"}] {name} -> '
              f'{"红" if red else "绿"}/{why}（期望{"红" if want_red else "绿"}）')
        rc |= 0 if ok else 1
    rc |= 1 if selftest_enum() else 0
    print('负测', 'PASS' if rc == 0 else 'FAIL')
    return rc


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('cmd', nargs='?',
                    choices=('model', 'register', 'check', 'recompute'))
    ap.add_argument('targets', nargs='*')
    ap.add_argument('--ut')
    ap.add_argument('--note', help='登记时把差额的解释一并写进 JSON（见 cmd_register）')
    ap.add_argument('--selftest', action='store_true')
    a = ap.parse_args()
    if a.selftest:
        return selftest()
    if not a.cmd:
        ap.error('要 model / register / check 之一，或 --selftest')
    if a.cmd == 'model':
        for t in a.targets:
            p = predict_one(t, a.ut)
            note = '模型适用' if p['model_applicable'] else \
                   f'★模型不适用（merge_dup={p["merge_dup"]}）★'
            print(f'{t}: expected={p["expected"]} '
                  f'(regs {p["regs"]} + outs {p["outs"]}) ut={p["ut"]} {note}')
        return 0
    if a.cmd == 'recompute':
        return cmd_recompute()
    if a.cmd == 'register':
        return cmd_register(a.targets, a.ut, a.note)
    return cmd_check(a.targets)


if __name__ == '__main__':
    sys.exit(main())
