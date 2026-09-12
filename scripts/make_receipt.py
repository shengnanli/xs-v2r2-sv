#!/usr/bin/env python3
"""make_receipt.py —— 为一次 proof 生成绑定输入的 receipt。

codex 0139 §5：任何晋升必须绑定
  G1 canonical ID + exact golden closure hash + impl commit + proof config。
本脚本在 fm-% 跑完后立即执行，把「用了哪些字节、跑在什么配置下、得了什么结论」
一次性钉死，输出 fm_work/<top>/receipt.json。

绑定内容：
  g1_canonical_id     G1-canonical/CANONICAL_ID.txt（全 golden 文件 manifest 的摘要）
  golden_closure      本次 ref 侧实际读入的每个 golden 文件的 sha256（逐文件，不是目录摘要）
  impl_closure        本次 impl 侧实际读入的每个文件的 sha256 + 仓库 commit/dirty 状态
  proof_config        FM_MODE / allowlist / vmucp / pin 文件 / allow / dead_ref 声明的 hash
  native_facts        sidecar 采集的原生事实（含 appvar readback）
  verdict             fm_verdict.py 的判定与理由
  rc                  fm_shell 退出码
fail-closed：sidecar 缺失、native 与 log 判定不一致、声明文件缺失一律非零退出。
"""
import argparse
import hashlib
import json
import os
import pathlib
import subprocess
import sys

_HERE = pathlib.Path(__file__).resolve().parent
NEW = pathlib.Path(os.environ.get('XSSV_HOME') or _HERE.parent)
G1 = pathlib.Path(os.environ.get('G1_CANONICAL') or '/home/eda/xs-env/G1-canonical')
# 证据/索引在真实仓库（worktree 内 evidence/ 不存在）
INDEX_HOME = pathlib.Path(os.environ.get('XSSV_INDEX_HOME') or NEW)


def sha(p):
    return hashlib.sha256(pathlib.Path(p).read_bytes()).hexdigest()


def closure(files, repo=None):
    """闭包条目：路径一律记 **repo-relative**（worktree 绝对路径跑完即失效，
    无法事后 `git show <commit>:<path>` 复算）。仓库外的文件（golden）记 kind=golden
    并保留其相对 G1 的路径。"""
    out = []
    repo = pathlib.Path(repo) if repo else None
    for f in files:
        if not f:
            continue
        fp = pathlib.Path(f)
        if not fp.exists():
            sys.exit(f'ERROR: receipt 闭包文件不存在: {f}')
        rel, kind = str(fp), 'external'
        try:
            if repo:
                rel, kind = str(fp.resolve().relative_to(repo.resolve())), 'repo'
        except ValueError:
            try:
                rel, kind = str(fp.resolve().relative_to(G1.resolve())), 'golden'
            except ValueError:
                pass
        out.append({'path': rel, 'kind': kind, 'sha256': sha(fp)})
    return out


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--top', required=True)
    ap.add_argument('--workdir', required=True)
    ap.add_argument('--ref-srcs', default='')
    ap.add_argument('--impl-srcs', default='')
    ap.add_argument('--mode', required=True)
    ap.add_argument('--allowlist', default='0')
    ap.add_argument('--vmucp', default='false')
    ap.add_argument('--rc', default='0')
    ap.add_argument('--verdict', required=True)
    ap.add_argument('--expect-run-id', default=None,
                    help='本次 FM_RUN_ID；与 sidecar 记录不符即拒（防捡到上次残留 facts）')
    ap.add_argument('--parent-commit', default=None,
                    help='本次父 proof 的 commit；green_child 的 impl 闭包按该 commit 复算')
    ap.add_argument('--allow-dirty', action='store_true',
                    help='仅用于本地调试：允许 dirty 工作树（产出的 receipt 标记 provisional，'
                         '不可用于晋升）')
    a = ap.parse_args()

    wd = pathlib.Path(a.workdir)
    sc = wd / 'sidecar' / 'native_facts.json'
    if not sc.exists():
        sys.exit('ERROR: sidecar/native_facts.json 缺失 —— FM_SIDECAR_OUT 未生效，拒绝出 receipt')
    facts = json.loads(sc.read_text())

    vline = a.verdict.split('\t', 1)
    vname = vline[0]
    vq = json.loads(vline[1]) if len(vline) > 1 else {}
    if facts.get('native_verdict') and vq.get('native') and \
            facts['native_verdict'] != vq['native']:
        sys.exit(f"ERROR: native 事实({facts['native_verdict']}) 与 log 判定"
                 f"({vq['native']}) 不一致 —— 拒绝出 receipt")

    cid = (G1 / 'CANONICAL_ID.txt').read_text().strip()
    decls = {}
    for kind in ('allow', 'dead_ref'):
        p = NEW / 'verif' / kind / f'{a.top}.json'
        if p.exists():
            decls[kind] = {'path': str(p.relative_to(NEW)), 'sha256': sha(p)}

    pins = {}
    for f in ('fm_pins.tcl', 'fm_pins_pre.tcl'):
        p = wd.parent.parent / f
        if p.exists():
            pins[f] = sha(p)

    # run_id 绑定：sidecar facts 必须属于本次 run（否则可能捡到上一次残留）
    if a.expect_run_id and facts.get('run_id') != a.expect_run_id:
        sys.exit(f"ERROR: sidecar run_id({facts.get('run_id')}) != 本次 FM_RUN_ID"
                 f"({a.expect_run_id}) —— 拒绝出 receipt")

    impl_commit = subprocess.run('git rev-parse HEAD', shell=True, cwd=str(NEW),
                                 stdout=subprocess.PIPE, universal_newlines=True).stdout.strip()
    # codex 0140 P0-2: dirty 工作树**直接拒产 receipt**（不再只是记录一个 flag）。
    # 证明输入必须是 committed 字节；正规跑法是 run_proof.sh 起 detached clean worktree。
    dirty = subprocess.run('git status --porcelain', shell=True, cwd=str(NEW),
                           stdout=subprocess.PIPE, universal_newlines=True).stdout.strip()
    if dirty and not a.allow_dirty:
        sys.exit('ERROR: impl 工作树 dirty —— 拒绝出 receipt。'
                 '请用 scripts/run_proof.sh（detached clean worktree）或先提交改动。'
                 f'\n首条: {dirty.splitlines()[0][:100]}')

    # green_child 共享闭包字节一致性（codex 0140 P0-3 的 closure 部分）：
    # 父的 impl 闭包里凡是 child receipt 也读过的文件，两侧 sha256 必须逐一相同。
    # 否则说明 child 被证明时用的不是本次这份字节。
    impl_cl = closure(a.impl_srcs.split(), NEW)
    child_checks = []
    allow_p = NEW / 'verif' / 'allow' / f'{a.top}.json'
    if allow_p.exists():
        sys.path.insert(0, str(_HERE))
        import build_receipt_index as _BRI
        idx = _BRI.load(INDEX_HOME)
        adecl = json.loads(allow_p.read_text())
        children = sorted({o['child_target'] for o in adecl.get('objects', [])
                           if o.get('class') == 'green_child' and o.get('child_target')})
        mine = {pathlib.Path(e['path']).name: e['sha256'] for e in impl_cl}
        for ct in children:
            cr = idx.get(ct)
            if cr is None:
                sys.exit(f'ERROR: green_child {ct} 无 receipt —— 拒绝出 receipt')
            crj = json.loads((INDEX_HOME / cr['path']).read_text())
            shared, bad = 0, []
            for e in crj.get('impl_closure', []):
                nm = pathlib.Path(e['path']).name
                if nm in mine:
                    shared += 1
                    if mine[nm] != e['sha256']:
                        bad.append(nm)
            if bad:
                sys.exit(f'ERROR: green_child {ct} 的共享闭包字节与本次不一致: '
                         f'{bad[:3]} —— 拒绝出 receipt')
            # ★codex 0141：父把 child 黑盒掉，**更**需要组合性保证——父最终集成的
            # child 实现字节必须仍等于 child receipt 证明过的字节。对 child receipt 的
            # 每个 repo-relative impl 闭包条目，取父 commit 下同路径的字节算 sha256，
            # 必须逐一相等；文件缺失或改过一字节即 child receipt 失效（须重跑 child）。
            pcommit = a.parent_commit or impl_commit
            comp_ok, comp_bad, comp_missing = 0, [], []
            for e in crj.get('impl_closure', []):
                if e.get('kind') != 'repo':
                    continue
                r = subprocess.run(['git', 'show', f'{pcommit}:{e["path"]}'],
                                   cwd=str(NEW), stdout=subprocess.PIPE,
                                   stderr=subprocess.DEVNULL)
                if r.returncode != 0:
                    comp_missing.append(e['path'])
                    continue
                if hashlib.sha256(r.stdout).hexdigest() != e['sha256']:
                    comp_bad.append(e['path'])
                else:
                    comp_ok += 1
            if comp_missing or comp_bad:
                sys.exit(f'ERROR: green_child {ct} 的 impl 闭包在父 commit '
                         f'{pcommit[:12]} 下已变化 —— child receipt 失效，须重跑 child。'
                         f'缺失={comp_missing[:2]} 改动={comp_bad[:2]}')
            if comp_ok == 0:
                sys.exit(f'ERROR: green_child {ct} 的 receipt 无任何 repo-relative impl '
                         f'闭包条目可核对 —— 无法建立组合性保证，拒绝出 receipt')

            # 下面这条比对（父自身闭包与 child 闭包的交集）对被黑盒 child 恒空，
            # 保留仅作记录，**不再作为放行依据**。
            # 那条比对对这类 child 是空转。真正该绑的是「被黑盒的这个 golden 模块，
            # 与 child 被证明时用的 golden 模块是同一份字节」：
            # child receipt 的 golden_closure 里须含 <child>.sv，且其 sha256 与
            # G1 MANIFEST 记录一致（canonical 同源已另行校验）。
            gsha = {pathlib.Path(e['path']).name: e['sha256']
                    for e in crj.get('golden_closure', [])}
            key = f'{ct}.sv'
            man = {}
            mp = G1 / 'MANIFEST.tsv'
            if mp.exists():
                for ln in mp.read_text().splitlines():
                    c = ln.split('\t')
                    if len(c) == 3:
                        man[c[2]] = c[0]
            if key not in gsha:
                sys.exit(f'ERROR: green_child {ct} 的 receipt 未把 {key} 记入 golden 闭包 '
                         f'—— 无法证明黑盒的就是它，拒绝出 receipt')
            if key in man and man[key] != gsha[key]:
                sys.exit(f'ERROR: green_child {ct} 证明时的 {key} 字节与 G1 MANIFEST 不符 '
                         f'—— 拒绝出 receipt')
            child_checks.append({
                'child_target': ct,
                'child_impl_commit': cr['impl_commit'],
                'child_verdict': cr['verdict'],
                'child_receipt_sha256': cr['receipt_sha256'],
                # 稳定语义摘要：child 的判定 + canonical + 其 impl/golden 闭包逐文件
                # (repo-relative path, sha256) 排序后取 sha256。重跑同输入不变。
                'child_semantic_digest': hashlib.sha256(json.dumps({
                    'verdict': cr['verdict'], 'canonical': cr['canonical_id'],
                    'impl': sorted((e['path'], e['sha256'])
                                   for e in crj.get('impl_closure', [])),
                    'golden': sorted((e['path'], e['sha256'])
                                     for e in crj.get('golden_closure', [])),
                }, sort_keys=True).encode()).hexdigest(),
                'child_impl_files_verified_at_parent_commit': comp_ok,
                'parent_commit_used': pcommit,
                'child_golden_file': key,
                'child_golden_sha256': gsha[key],
                'child_golden_matches_g1_manifest': man.get(key) == gsha[key],
                'parent_impl_closure_overlap': shared,
            })

    receipt = {
        'schema': 'xs-v2-sv-receipt-v1',
        'top': a.top,
        'run_id': facts.get('run_id'),
        'g1_canonical_id': cid,
        'golden_closure': closure(a.ref_srcs.split(), NEW),
        'impl_closure': impl_cl,
        'impl_commit': impl_commit,
        'impl_worktree_dirty': bool(dirty),
        'provisional': bool(dirty),   # dirty 只在 --allow-dirty 调试路径出现
        'impl_closure_hashed_at': 'post_run',
        'proof_config': {
            'fm_mode': a.mode,
            'fm_allowlist_numeric_prefilter': a.allowlist,
            'verify_matched_unread_compare_points': a.vmucp,
            'pin_scripts': pins,
            'declarations': decls,
            'entry_appvars_readback': facts.get('entry_appvars'),
        },
        'green_child_closure_checks': child_checks,
        'fm_shell_rc': int(a.rc),
        'native_facts': facts,
        'verdict': vname,
        'verdict_detail': vq,
    }
    # 原子写：先写 tmp 再 rename（避免中断留下半截 receipt）
    out = wd / 'receipt.json'
    tmp = wd / 'receipt.json.tmp'
    tmp.write_text(json.dumps(receipt, ensure_ascii=False, indent=1))
    os.replace(str(tmp), str(out))
    print(f'receipt: {out} (verdict={vname}, canonical={cid[:20]}…, '
          f'golden={len(receipt["golden_closure"])} files, dirty={bool(dirty)})')


if __name__ == '__main__':
    main()
