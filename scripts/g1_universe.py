#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""g1_universe.py —— G1 主 universe 对账（**只冻结身份**）+ 工作台账归一化。

做三件事：
 1. **主 universe**：把上轮 306 目标逐个解析到 G1，得到本轮可比的主分母。
    表里只有**设计身份**：G0↔G1 映射、判据、delta 类、scope/proof obligation，
    以及由 tracked 证书派生的 proof status。
 2. **工作台账归一化**：append-only 台账压成每 target 唯一终态，按 MAIN / AUX 分栏。
    ★这一栏是**工作进度**，不是 proof 结论★（见下）。
 3. **守恒检查**：MAIN 各状态计数之和须等于主分母；AUX 之和须等于 AUX 目标数。

## 本轮修了什么（codex 0153 D66：status 与 universe 解耦）

修之前 status 列有两个来源，其中一个**在 clean clone 里不存在**：

    docs/fastlane_ledger.tsv    tracked，工作台账
    docs/receipt_index.tsv      ★untracked★（.gitignore:22），派生自同样 untracked
                                的 evidence/**/receipt.json → REVALIDATED_*

于是「重跑生成器得到冻结表」这件事取决于一份没人跟踪的文件。实测（同 commit
292fbb8、同一条命令）：

    主树（有 receipt_index）      REVALIDATED_PASS 118 / REVALIDATED_PASS_DEAD_REF 5
    clean worktree（无）          同两项 0，`--check` 直接 ★幂等 FAIL★

D66 的裁定与本文件的落地：

  * 冻结表**只冻结设计身份、G0↔G1 映射、层次角色、fingerprint、scope 与
    proof obligation** —— 不携带任何依赖 untracked 证据的状态；
  * 正式 proof status **只由 tracked `verif/proof_certificates/*.json` 派生**
    （scripts/proof_status.py，单一实现）。**没有证书 = `UNVERIFIED`**，
    这就是 clean clone 的正确答案，不是「塌陷」，更不该去复原旧绿；
  * `--receipt-index` 降级为**纯诊断**：配 `--receipt-report` 写一份单独的
    historical 报告，**不进冻结文件、不改任何 gate**；
  * `docs/receipt_index.tsv` 仍可从证据再生，但**不是输入真相**。

因此 D58 的「clean clone 重跑字节一致」现在**适用于本表**：清 clone 里没有
evidence/、没有 receipt_index，重跑得到的字节与仓库里的逐字节相同。

## 两栏状态的分工（别混）

  g1_universe.tsv       `proof_status`  ← tracked 证书。**唯一权威的证明结论。**
  ledger_normalized.tsv `work_state`    ← tracked fastlane_ledger.tsv。
                                          人写的工作进度，**不构成证明**。
                                          WORKING_PASS 只表示「当时跑过」，
                                          在 freeze 语义下等价于未证明。

## 幂等

`--check` 重新生成一遍并与仓库里的文件逐字节比对，不一致即非零退出。
"""
from __future__ import print_function

import argparse
import json
import os
import pathlib
import sys
from collections import Counter

HERE = pathlib.Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))
import g1_slotmap as SM                                            # noqa: E402
import g1_configured_universe as CU                                # noqa: E402
import proof_status as PS                                          # noqa: E402

G0_DEFAULT = SM.G0_DEFAULT
G1_DEFAULT = SM.G1_DEFAULT
MANIFEST_DEFAULT = '/home/eda/xs-env/xs-signoff/scripts/sidecar/manifest_305.json'
CANONICAL_DEFAULT = '/home/eda/xs-env/G1-canonical/CANONICAL_ID.txt'

#: proof obligation —— 纯粹由**身份 + scope** 机械推导，与做没做、过没过无关。
OBL_REQUIRED = 'REQUIRED'        # 映射到 configured universe 里的 G1 模块
OBL_OUT_OF_SCOPE = 'OUT_OF_SCOPE'  # 映射到 G1 里、但落在排除类（厂商宏/行为级存储…）
OBL_NONE = 'NONE'                # G1 里没有对应模块（gone_in_g1）

UNI_HDR = [
    '# G1 主 universe 对账（scripts/g1_universe.py 生成；禁止手工编辑 ——',
    '#   手工改完下次重跑就没了，要改改生成器。`--check` 是这条的机器闸）。',
    '# 主分母 = 上轮 306 目标按**槽位判据**解析到 G1。',
    '# ★本表只冻结身份★（codex 0153 D66）：G0↔G1 映射、判据、delta 类、scope/',
    '#   proof obligation，以及由 **tracked 证书** 派生的 proof_status。',
    '#   不读 docs/receipt_index.tsv、不读 evidence/ —— 两者都 untracked，',
    '#   clean clone 里不存在，拿它们当输入会让冻结表的字节不可复现。',
    '# resolve 列 = 做决定的判据还有谁独立佐证：',
    '#   same_name   槽位判据的答案就是同名模块',
    '#   slot_map    槽位判据把它改判到了别的名字（仅有槽位判据支持）',
    '#   manual_map  槽位判据的答案与 docs/g1_manual_map.tsv 的人工结论一致',
    '#   renumbered  槽位判据的答案与「模块体字节全等」的纯重编号一致',
    '#   gone_in_g1  四条判据都不给答案（须人工定位，不得自动改判）',
    '# obligation 列（由身份+scope 机械推导，与做没做无关）:',
    '#   REQUIRED      映射到 G1 configured universe 内的模块，须有证明',
    '#   OUT_OF_SCOPE  映射到 G1，但落在排除类（厂商宏/行为级存储/difftest 基础设施）',
    '#   NONE          G1 里没有对应模块',
    '# proof_status 列（唯一权威的证明结论，来源 verif/proof_certificates/*.json）:',
    '#   VERIFIED / CERT_REJECTED / CERT_INVALID / UNVERIFIED',
    '#   ★只有 VERIFIED 算证明过★；无 tracked 证书 = UNVERIFIED（clean clone 的正确答案）。',
    '# ★proof_status 只按 g1_name 取★：老名下的证书是对**另一个模块**的结论。',
    '# old_target\tg1_name\tresolve\tdelta_class\tobligation\tproof_status\tnote',
]

NORM_HDR = [
    '# 工作台账归一化（scripts/g1_universe.py 生成；每 target 唯一终态；',
    '#   bucket=MAIN 属主 universe / AUX 为本轮多覆盖的 G1 变体）',
    '# ★work_state 是**工作进度**，不是 proof 结论★（codex 0153 D66）。',
    '#   来源只有 tracked 的 docs/fastlane_ledger.tsv。WORKING_PASS 之类只表示',
    '#   「当时有人跑过」，在 freeze 语义下等价于**未证明**；权威结论看',
    '#   docs/g1_universe.tsv 的 proof_status 列（由 tracked 证书派生）。',
    '# target\tbucket\twork_state\tnote',
]

RCP_HDR = [
    '# ★诊断/历史报告，不是输入真相，不进任何 gate★（codex 0153 D66）。',
    '# 由 --receipt-index 指定的 docs/receipt_index.tsv 派生；该文件与它依赖的',
    '# evidence/ 都在 .gitignore 里，clean clone 中不存在 —— 所以本报告**不可复现**，',
    '# 只用来回看「上一轮那些 receipt 当时记在谁头上」。',
    '# 冻结表的 proof_status 一律以 verif/proof_certificates/*.json 为准。',
    '# g1_name\thistorical_verdict\treceipt_path\tcommit\tin_main_universe',
]


def read_kv(path, key=0, val=2, sep='\t'):
    out = {}
    for ln in pathlib.Path(path).read_text().splitlines():
        if ln.startswith('#') or not ln.strip():
            continue
        f = ln.split(sep)
        if len(f) > max(key, val):
            out[f[key]] = f[val]
    return out


def load_worklog(repo):
    """target -> (work_state, note)，**只读 tracked 的 docs/fastlane_ledger.tsv**。

    append-only 文本台账，同 target 取最后一行。

    ★这里刻意不再读 docs/receipt_index.tsv★（D66）。它 untracked、依赖同样
    untracked 的 evidence/，读它会让冻结表的字节在 clean clone 里复现不出来。
    """
    status = {}
    lp = pathlib.Path(repo) / 'docs' / 'fastlane_ledger.tsv'
    for ln in lp.read_text().splitlines():
        if ln.startswith('#') or not ln.strip():
            continue
        f = ln.split('\t')
        status[f[0]] = (f[1], f[2] if len(f) > 2 else '')
    return status


def load_receipt_history(receipt_index, canonical_id):
    """**诊断专用**：把老 receipt_index 读成 [(target, verdict, path, commit)]。

    返回值只进 `--receipt-report` 的独立报告，绝不参与冻结表或任何判定。
    """
    rows = []
    ri = pathlib.Path(receipt_index)
    if not ri.exists():
        return rows, False
    for ln in ri.read_text().splitlines():
        if ln.startswith('#') or not ln.strip():
            continue
        c = ln.split('\t')
        if len(c) < 7:
            continue
        tgt, verdict, cid, commit, prov, _sha, path = c[:7]
        if prov != 'false' or cid != canonical_id:
            continue
        if verdict not in ('SUCCEEDED', 'PASS_DEAD_REF'):
            continue
        rows.append((tgt, verdict, path, commit))
    return rows, True


def obligation_of(g1n, universe):
    if not g1n:
        return OBL_NONE
    return OBL_REQUIRED if g1n in universe else OBL_OUT_OF_SCOPE


def configured_universe(g1, root):
    """G1 configured universe 的模块名集合。

    与 scripts/g1_configured_universe.py **同一份实现**（import 过来的
    `reachable` / `excluded`），两个生成器对 scope 的口径不可能再漂。
    """
    reach = CU.reachable(g1, root)
    return set(n for n in g1.ports if n in reach and not CU.excluded(n))


def build(args):
    repo = pathlib.Path(args.repo)
    g0 = SM.Baseline(args.g0, 'G0', include_v=not args.no_include_v)
    g1 = SM.Baseline(args.g1, 'G1', include_v=not args.no_include_v)
    res = SM.Resolver(g0, g1, args.g0, args.g1, SM.load_manual_map(repo))

    old_targets = [e['target'] for e in json.load(open(args.manifest))['entries']]
    delta = read_kv(repo / 'docs' / 'g0g1_delta.tsv', 0, 2)
    work = load_worklog(repo)
    universe = configured_universe(g1, args.root)
    # ★proof status 只认 tracked 证书★（D66）。没有证书 = UNVERIFIED。
    pmap = PS.status_map(repo)

    rows, g1_of, dropped = [], {}, []
    for t in old_targets:
        g1n, label, crit = res.resolve(t)
        g1_of[t] = g1n
        # ★只按 g1_name 取★——老名下的证书是对**另一个模块**的结论。
        pst, pnote = PS.status_of(pmap, g1n) if g1n else (PS.UNVERIFIED, 'no G1 module')
        if g1n != t and t in pmap:
            dropped.append((t, g1n or '-', pmap[t][0]))
        bits = []
        if g1n and g1n != t:
            bits.append('槽位判据(%s)改判: 原名 %s；依据见 docs/g1_slot_map_evidence.tsv'
                        % (crit, t))
        bits.append(pnote)
        rows.append((t, g1n or '-', label, delta.get(t, '?'),
                     obligation_of(g1n, universe), pst, '；'.join(bits)))

    # ★MAIN = 被 old306 映射**覆盖到的 G1 模块**，不是 old306 的名字集合★
    # 改判之后，老名往往指向 G1 里的另一个模块（NewPipelineConnectPipe_27 的
    # 老名在 G1 里仍然存在，但它已经不是任何 old target 的映射目标了）。
    # 把老名算进 MAIN 会让这些模块以"主 universe 成员"的身份混进分母 ——
    # check_universe_freeze C2 的 MAIN/AUX 判据正是按映射目标算的，两边必须一致。
    main_names = set(v for v in g1_of.values() if v)
    aux = sorted(set(work) - main_names)

    uni_txt = '\n'.join(UNI_HDR + ['\t'.join(r) for r in rows]) + '\n'
    norm_txt = '\n'.join(
        NORM_HDR + ['%s\t%s\t%s\t%s' % (t, 'AUX' if t in aux else 'MAIN',
                                        work[t][0], work[t][1][:120])
                    for t in sorted(work)]) + '\n'
    return dict(rows=rows, aux=aux, work=work, dropped=dropped,
                main_names=main_names, pmap=pmap, universe=universe,
                files={repo / 'docs' / 'g1_universe.tsv': uni_txt,
                       repo / 'docs' / 'ledger_normalized.tsv': norm_txt})


def emit(files, check):
    """写文件；`check` 模式下只比对，不写。返回不一致的文件列表。"""
    bad = []
    for p, txt in sorted(files.items()):
        if check:
            cur = p.read_text() if p.exists() else None
            if cur != txt:
                bad.append(p)
        else:
            p.write_text(txt)
    return bad


def main(argv=None):
    ap = argparse.ArgumentParser(
        description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument('--repo', default=str(os.environ.get('XSSV_HOME') or HERE.parent),
                    help='仓库根（默认 $XSSV_HOME 或本脚本所在仓库）。'
                         '★禁止硬编码主树★：多个 worktree 并行时写错树会互相覆盖。')
    ap.add_argument('--g0', default=G0_DEFAULT)
    ap.add_argument('--g1', default=G1_DEFAULT)
    ap.add_argument('--manifest', default=MANIFEST_DEFAULT)
    ap.add_argument('--canonical-id', default=CANONICAL_DEFAULT)
    ap.add_argument('--root', default='XSTop',
                    help='configured universe 的根（D59 固定 XSTop）；'
                         'obligation 列按它判 scope')
    ap.add_argument('--receipt-index', default=None,
                    help='★仅供 --receipt-report 的历史/诊断报告使用★（D66）。'
                         '不影响冻结表的任何一个字节，也不进任何 gate。'
                         '默认 <repo>/docs/receipt_index.tsv')
    ap.add_argument('--receipt-report', default=None, metavar='FILE',
                    help='把老 receipt_index 写成一份**独立的**历史报告到 FILE。'
                         '不给这个参数就不写任何报告。')
    ap.add_argument('--no-include-v', action='store_true')
    ap.add_argument('--check', action='store_true',
                    help='不写文件，只校验仓库里的 TSV 与重新生成的结果逐字节一致'
                         '（D58 幂等闸）；不一致退出码 1')
    ap.add_argument('--report-dropped', action='store_true',
                    help='列出「老名下有证书、但因改判而未被继承」的 target')
    args = ap.parse_args(argv)
    if args.receipt_index is None:
        args.receipt_index = str(pathlib.Path(args.repo) / 'docs' / 'receipt_index.tsv')

    try:
        b = build(args)
    except (SM.InputError, PS.PolicyError, IOError, OSError) as e:
        sys.stderr.write('INPUT/PARSE ERROR (fail-closed): %s\n' % e)
        return 2

    rows, aux, work = b['rows'], b['aux'], b['work']
    print('tracked 证书 %d 份 → proof_status 非 UNVERIFIED 的 target %d 个'
          % (len(b['pmap']), len(b['pmap'])))

    cnt = Counter(r[2] for r in rows)
    obl_cnt = Counter(r[4] for r in rows)
    main_cnt = Counter(r[5] for r in rows)
    aux_cnt = Counter(work[t][0] for t in aux)
    gone = [r[0] for r in rows if r[2] == 'gone_in_g1']
    print('主 universe（老 %d 解析到 G1）: %d 个  %s'
          % (len(rows), len(rows),
             ' / '.join('%s %d' % kv for kv in sorted(cnt.items()))))
    print('proof obligation:', dict(obl_cnt.most_common()))
    print('MAIN proof_status:', dict(main_cnt.most_common()))
    print('AUX（本轮多覆盖的 G1 变体）work_state:', len(aux), dict(aux_cnt.most_common()))
    mp = sum(v for k, v in main_cnt.items() if k in PS.PROVEN)
    print('★证明过（proof_status=VERIFIED）: MAIN %d/%d = %.1f%%★'
          % (mp, len(rows), 100.0 * mp / len(rows)))
    if not b['pmap']:
        print('  （仓库里没有 tracked 证书 —— 全部 UNVERIFIED 是**正确**结果，'
              '不是塌陷；见 verif/proof_certificates/POLICY.json）')
    if gone:
        print('G1 已消失（需人工定位去向，不得自动改判）:', ' '.join(gone))
    if b['dropped']:
        print('★改判后未继承老名证书的 target: %d 个（老名下的结论是对**另一个模块**的）'
              % len(b['dropped']))
        if args.report_dropped:
            for t, g, s in b['dropped']:
                print('    %s → %s  老名证书状态 %s 已丢弃' % (t, g, s))
        else:
            print('    （--report-dropped 逐条列出）')

    ok = (sum(main_cnt.values()) == len(rows)
          and sum(aux_cnt.values()) == len(aux)
          and sum(obl_cnt.values()) == len(rows))
    # 守恒的口径必须与 MAIN/AUX 的口径一致：MAIN = 映射目标集合。
    overlap = set(aux) & b['main_names']
    if overlap:
        print('★守恒失败：同时落入两栏:', ' '.join(sorted(overlap)[:5]))
        ok = False
    print('守恒检查:', 'PASS' if ok else 'FAIL')

    # ---- 历史/诊断报告：单独文件，**不属于冻结集**，也不影响上面的任何结论 ----
    if args.receipt_report:
        cid = pathlib.Path(args.canonical_id).read_text().strip()
        hist, have = load_receipt_history(args.receipt_index, cid)
        g1names = set(r[1] for r in rows if r[1] != '-')
        lines = list(RCP_HDR) + [
            '%s\t%s\t%s\t%s\t%s' % (t, v, p, c[:12], 'yes' if t in g1names else 'no')
            for t, v, p, c in sorted(hist)]
        pathlib.Path(args.receipt_report).write_text('\n'.join(lines) + '\n')
        print('历史报告（★诊断用，不进冻结集、不进 gate★）: %s  %d 行  '
              '（receipt_index %s）'
              % (args.receipt_report, len(hist),
                 '存在' if have else '不存在 —— clean clone 的正常情况'))

    bad = emit(b['files'], args.check)
    if args.check:
        if bad:
            print('★幂等 FAIL★ 重新生成的结果与仓库里的文件不一致:')
            for p in bad:
                print('    -', p)
            return 1
        print('幂等 PASS: %d 个文件与重新生成的结果逐字节一致' % len(b['files']))
    return 0 if ok else 1


if __name__ == '__main__':
    sys.exit(main())
