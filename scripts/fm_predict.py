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


def ut_of(target, explicit=None):
    """找这个 target 属于哪个 UT 目录（Makefile 的 FM_VARIANTS 里含它）。"""
    if explicit:
        return explicit
    for mk in sorted((REPO / 'verif' / 'ut').glob('*/Makefile')):
        txt = re.sub(r'\\\n', ' ', mk.read_text(errors='replace'))
        m = re.search(r'^FM_VARIANTS\s*=\s*(.*)$', txt, re.M)
        if m and target in m.group(1).split():
            return mk.parent.name
    return None


def merge_dup_of(ut):
    """从 UT 的 Makefile 读 FM_MERGE_DUP；没写 = FM 默认 true。"""
    if not ut:
        return None
    mk = REPO / 'verif' / 'ut' / ut / 'Makefile'
    if not mk.exists():
        return None
    m = re.search(r'^FM_MERGE_DUP\s*=\s*(\S+)', mk.read_text(errors='replace'), re.M)
    return (m.group(1).strip() if m else 'true')


def predict_one(target, ut=None):
    ut = ut_of(target, ut)
    rows = from_ut(ut) if ut else None
    r = None
    if rows:
        r = next((x for x in rows if x['top'] == target), None)
    if r is None:
        r = compute_model(target, [])
    md = merge_dup_of(ut)
    return dict(target=target, ut=ut, regs=r['regs'], outs=r['outs'],
                expected=r['model'], merge_dup=md,
                model_applicable=(md == 'false'))


def reg_path(target):
    return REG_DIR / f'{target}.json'


def cmd_register(targets, ut=None):
    REG_DIR.mkdir(parents=True, exist_ok=True)
    for t in targets:
        p = predict_one(t, ut)
        f = reg_path(t)
        f.write_text(json.dumps(p, indent=2, ensure_ascii=False) + '\n')
        note = ('模型适用' if p['model_applicable'] else
                f'★模型不适用★（merge_dup={p["merge_dup"]}）')
        print(f'登记 {t}: expected={p["expected"]} (regs {p["regs"]} + outs {p["outs"]})'
              f'  {note}  -> {f.relative_to(REPO)}')
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
        if not reg['model_applicable']:
            verdict = f'MODEL_NA（merge_dup={reg["merge_dup"]}，模型不适用）'
            bad = True
        elif anc != 0:
            verdict = '★登记不早于该次证明 —— 可能是事后补的★'
            bad = True
        elif actual is None:
            verdict = '★receipt 里没有 passing★'; bad = True
        elif gap < 0:
            verdict = f'★实测高于模型上界 {-gap} —— 模型或闭包算漏了★'; bad = True
        elif gap == explained:
            verdict = ('逐位相等' if gap == 0 else
                       f'差额被指认（constant_reg {const} + unread {unread}）')
        else:
            verdict = f'★余额 {gap - explained} 指认不了★'; bad = True
        print(f'{t:<24}{reg["expected"]:>8}{(actual if actual is not None else 0):>8}'
              f'{gap:>7}{explained:>8}  {verdict}')
        rc_all |= 1 if bad else 0
    print()
    print('结论：' + ('全部对上' if rc_all == 0 else '★有对不上的，按 fail 处理★'))
    return rc_all


# ---------------------------------------------------------------------------
def _judge(expected, actual, const, unread, applicable, anc_ok):
    """纯判据，抽出来才好负测。返回 (是否红, 理由)。"""
    if not applicable:
        return True, 'MODEL_NA'
    if not anc_ok:
        return True, 'REGISTERED_TOO_LATE'
    gap = expected - actual
    if gap < 0:
        return True, 'ABOVE_MODEL'
    if gap == (const + unread):
        return False, 'EXACT' if gap == 0 else 'EXPLAINED'
    return True, 'UNEXPLAINED'


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
        ('★反例 模型不适用（merge_dup=true）★',
         8292, 7902, 6, 6, False, True, True),
        ('★反例 登记不早于证明（事后补登记）★',
         1394, 1394, 0, 0, True, False, True),
        ('★反例 实测高于模型上界（模型算漏了）★',
         100, 120, 0, 0, True, True, True),
    ]
    rc = 0
    print('fm_predict --selftest:')
    for name, e, a, c, u, ap, anc, want_red in cases:
        red, why = _judge(e, a, c, u, ap, anc)
        ok = (red == want_red)
        print(f'  [{"OK" if ok else "FAIL"}] {name} -> '
              f'{"红" if red else "绿"}/{why}（期望{"红" if want_red else "绿"}）')
        rc |= 0 if ok else 1
    print('负测', 'PASS' if rc == 0 else 'FAIL')
    return rc


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('cmd', nargs='?', choices=('model', 'register', 'check'))
    ap.add_argument('targets', nargs='*')
    ap.add_argument('--ut')
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
    if a.cmd == 'register':
        return cmd_register(a.targets, a.ut)
    return cmd_check(a.targets)


if __name__ == '__main__':
    sys.exit(main())
