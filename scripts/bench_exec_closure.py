#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""bench_exec_closure.py —— 整芯片 benchmark（run_fcb.sh，只换 XSTile）的**执行闭包**清单与比较。

codex 0244 第 3 条：保留既有 benchmark 成果的前提是「最终提交的执行闭包仍相同」；
「此后 rtl 零改动」不能单独当证明，源选择、参数、define、存储模型都要一致。
本脚本把「一次 impl simv 构建 + 运行到底吃了哪些字节」机械化成一份 JSON 清单：

  repo 派生（随提交变）:
    selection_inputs  决定**选哪些源**的输入：rtl/ 整棵树 git tree id、verif/sim tree id、
                      选源脚本 xstile_sim_filelist.py / scripts/full_elab_filelist.py 的 sha256
    filelist          用**该提交自己的** xstile_sim_filelist.py 对该提交 rtl/ + G1 golden 实算出的
                      有序编译清单（= impl/files_impl_nosimtop.f），逐项 路径 + sha256
                      （含 97 个核内登记存储模型、核外 golden、extern_modules.sv 宏头）
    srcmap            模块 -> (来源类别, 文件)（= impl/srcmap.tsv）
    outcore_renamed   核外共用模块改名拷贝（生成物）逐个 sha256
    simtop_patched    run_fullchip.sh 里 SimTop XMR->'0 补丁（取该提交脚本里的原文执行）结果 sha256
    flow              构建/运行流程脚本 run_fcb.sh / run_fastsim.sh / run_fullchip.sh 的 sha256
                      （VCS 开关补丁、difftest 补丁、make 变量、plusarg、ram_size、NEMU so 路径都写死在里面）
                      + 从中抽出的关键参数（便于人读；判等以 sha256 为准）
    verdict_tools     commit_compare.py / bench_verdict.py（判定工具，不进 simv，单列）
  外部（不随提交变，按工作区实测）:
    external          difftest 副本（src/ config/ *.mk Makefile，已打补丁的实际文件）、
                      DPI 胶水 generated-src、build/ 下 chisel_db/constantin/perfCCT 拷贝、
                      NEMU ref so、负载 bin、G1 MANIFEST/CANONICAL_ID、vcs 可执行路径

子命令:
  compute       --repo <git 目录> --commit <rev> --out <json> [--workspace <sim 工作区>]
                用 git archive 把该提交的 rtl/ verif/sim/ scripts/full_elab_filelist.py 取到 $TMPDIR，
                **不切换任何 worktree 的分支**。
  verify-build  --manifest <json> --workspace <sim 工作区> --checkout <构建时 SV_HOME>
                核对实际构建（impl/files_impl_nosimtop.f、srcmap.tsv、outcore_renamed/、build/rtl/SimTop.sv、
                build.log 的 Parsing 记录与 vcs 命令行）就是清单所述；rtl/golden 文件当前内容 == 清单且
                mtime 早于 build.log 的 VCS 启动时刻；构建时刻 checkout 的 HEAD（reflog）== 清单提交。
  diff          <a.json> <b.json>   逐项比较两个清单。

退出码: 0 = 相同 / 核对通过；1 = 有差异 / 核对失败；2 = 用法或环境错误。
"""
import argparse
import datetime
import hashlib
import json
import os
import pathlib
import re
import shutil
import subprocess
import sys

GOLDEN_DEFAULT = '/home/eda/xs-env/G1-canonical/golden-rtl'
WORKLOADS_DEFAULT = ['/home/eda/xs-env/sim-fcb/workloads/flash_recursion_test.bin',
                     '/home/eda/xs-env/sim-fcb/workloads/coremark-2-iteration.bin',
                     '/home/eda/xs-env/sim-fcb/workloads/dhrystone.bin']
CPUTEST_GLOB_DIR = '/home/eda/xs-env/nexus-am/tests/cputest/build'
NEMU_SO_DEFAULT = '/home/eda/xs-env/XiangShan/ready-to-run/riscv64-nemu-interpreter-so'
XS_BUILD_COPIES = ['chisel_db.cpp', 'chisel_db.h', 'constantin.cpp', 'constantin.hpp', 'constantin.txt',
                   'perfCCT.cpp', 'perfCCT.h']
SELECTOR_FILES = ['verif/sim/xstile_sim_filelist.py', 'scripts/full_elab_filelist.py']
FLOW_FILES = ['verif/sim/run_fcb.sh', 'verif/sim/run_fastsim.sh', 'verif/sim/run_fullchip.sh']
VERDICT_FILES = ['verif/sim/commit_compare.py', 'verif/sim/bench_verdict.py']
ARCHIVE_PATHS = ['rtl', 'verif/sim', 'scripts/full_elab_filelist.py']
SCHEMA = 'bench-exec-closure-v1'


def die(msg, code=2):
    print('bench_exec_closure: ERROR: ' + msg, file=sys.stderr)
    sys.exit(code)


def sha_bytes(b):
    return hashlib.sha256(b).hexdigest()


def sha_file(p):
    h = hashlib.sha256()
    with open(p, 'rb') as f:
        for chunk in iter(lambda: f.read(1 << 20), b''):
            h.update(chunk)
    return h.hexdigest()


def git(repo, *args, binary=False):
    r = subprocess.run(['git', '-C', str(repo)] + list(args), stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    if r.returncode != 0:
        die(f'git {" ".join(args)} 失败: {r.stderr.decode(errors="replace").strip()}')
    return r.stdout if binary else r.stdout.decode().strip()


def tmp_root():
    t = os.environ.get('TMPDIR')
    if not t:
        die('须设 TMPDIR（本 lane 约定 /home/eda/xs-env/tmp-bcl）')
    p = pathlib.Path(t)
    p.mkdir(parents=True, exist_ok=True)
    return p


class PathMap:
    """绝对路径 <-> 逻辑路径（repo:/golden:/outcore:/ws:）。逻辑路径与机器上的检出位置无关，两次计算才可比。"""

    def __init__(self, pairs):
        # 长前缀优先，防 /a/b 抢走 /a/b/c 的匹配
        self.pairs = sorted(((str(pathlib.Path(a)).rstrip('/') + '/', tag) for a, tag in pairs),
                            key=lambda x: -len(x[0]))

    def logical(self, p):
        s = str(p)
        for pre, tag in self.pairs:
            if s.startswith(pre):
                return tag + ':' + s[len(pre):]
        return 'abs:' + s


def extract_simtop_patch(run_fullchip_text):
    """取 run_fullchip.sh 里 SimTop 补丁的 python heredoc 原文（<<'PYEOF' ... PYEOF）。"""
    m = re.search(r"<<'PYEOF'\n(.*?)\nPYEOF\n", run_fullchip_text, re.S)
    if not m:
        die("run_fullchip.sh 里找不到 SimTop 补丁 heredoc（<<'PYEOF'），流程已变，须人工复核")
    return m.group(1)


def flow_params(texts):
    """从流程脚本里抽关键参数（人读用；判等以 flow 的 sha256 为准）。"""
    out = {}
    fc, fs, fcb = (texts.get('verif/sim/run_fullchip.sh', ''), texts.get('verif/sim/run_fastsim.sh', ''),
                   texts.get('verif/sim/run_fcb.sh', ''))
    m = re.search(r'make -C "\$DIFFTEST" simv \\\n(.*?)\n\s*2>&1', fc, re.S)
    out['make_simv'] = re.sub(r'\s+', ' ', m.group(1).replace('\\', ' ')).strip() if m else None
    for k, src in (('RAM_SIZE', fs), ('REF_SO', fs), ('VCS_JOBS', fs), ('GOLDEN_RTL', fc), ('SIMF', fcb)):
        m = re.search(r'^\s*(?:export\s+)?' + k + r'="\$\{' + k + r':-([^}]*)\}"', src, re.M)
        out[k] = m.group(1) if m else None
    m = re.search(r"sed -i -e 's/ -debug_access\+all//' -e \"s/-j200/-j\$VCS_JOBS/\"", fs)
    out['vcs_mk_patch'] = 'drop -debug_access+all; -j200 -> -j$VCS_JOBS' if m else None
    out['run_plusargs'] = re.findall(r'"\+(workload|diff|ram_size)=', fs)
    out['commit_trace_patch'] = 'FCB_COMMIT_TRACE' in fcb
    out['xstile_only'] = bool(re.search(r'^export XSTILE_ONLY=1$', fcb, re.M))
    return out


def hash_tree(root, rel_filter=None, skip_re=None):
    root = pathlib.Path(root)
    out = {}
    if not root.exists():
        return out
    for p in sorted(root.rglob('*')):
        if not p.is_file() or p.is_symlink() and not p.exists():
            continue
        rel = str(p.relative_to(root))
        if rel_filter and not rel_filter(rel):
            continue
        if skip_re and re.search(skip_re, rel):
            continue
        out[rel] = sha_file(p)
    return out


def difftest_filter(rel):
    top = rel.split('/')[0]
    return top in ('src', 'config') or rel in ('Makefile',) or (('/' not in rel) and rel.endswith('.mk'))


def external_inputs(workspace, golden, workloads):
    """不随提交变的外部输入：按工作区实测。"""
    ws = pathlib.Path(workspace)
    ext = {}
    # 已打补丁的 difftest 实际文件；*.orig 是补丁前备份、*.patch.txt 是补丁记录（含路径/时间戳头），都不进 simv
    ext['difftest'] = hash_tree(ws / 'difftest', difftest_filter, r'\.orig$')
    ext['generated_src'] = hash_tree(ws / 'impl/build/generated-src')
    ext['xs_build_copies'] = {f: sha_file(ws / 'impl/build' / f) for f in XS_BUILD_COPIES
                              if (ws / 'impl/build' / f).exists()}
    regen = ws / 'regen/build/generated-src'
    ext['regen_generated_src'] = hash_tree(regen)
    ext['nemu_so'] = {NEMU_SO_DEFAULT: sha_file(NEMU_SO_DEFAULT)} if os.path.exists(NEMU_SO_DEFAULT) else {}
    wl = {}
    for w in workloads:
        if os.path.exists(w):
            wl[w] = sha_file(w)
    if os.path.isdir(CPUTEST_GLOB_DIR):
        for p in sorted(pathlib.Path(CPUTEST_GLOB_DIR).glob('*-riscv64-xs.bin')):
            wl[str(p)] = sha_file(p)
    ext['workloads'] = wl
    g = pathlib.Path(golden)
    for f in ('MANIFEST.tsv', 'CANONICAL_ID.txt'):
        q = g.parent / f
        ext['golden_' + f] = sha_file(q) if q.exists() else None
    vcs = shutil.which('vcs')
    ext['vcs_bin'] = os.path.realpath(vcs) if vcs else None
    return ext


def compute(a):
    repo = pathlib.Path(a.repo)
    commit = git(repo, 'rev-parse', '--verify', a.commit + '^{commit}')
    golden = pathlib.Path(a.golden).resolve()
    work = tmp_root() / f'bcl-{commit[:12]}'
    if work.exists():
        shutil.rmtree(work)
    src, outdir = work / 'src', work / 'out'
    src.mkdir(parents=True)
    outdir.mkdir()
    blob = git(repo, 'archive', '--format=tar', commit, *ARCHIVE_PATHS, binary=True)
    r = subprocess.run(['tar', '-x', '-C', str(src)], input=blob, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    if r.returncode != 0:
        die('tar 解包失败: ' + r.stderr.decode(errors='replace'))

    # 1) 选源：用该提交自己的生成器原样跑
    files_f, tsv, ren = outdir / 'files_impl_nosimtop.f', outdir / 'srcmap.tsv', outdir / 'outcore_renamed'
    r = subprocess.run([sys.executable, str(src / 'verif/sim/xstile_sim_filelist.py'), '--golden', str(golden),
                        '--out', str(files_f), '--tsv', str(tsv), '--rename-dir', str(ren)],
                       stdout=subprocess.PIPE, stderr=subprocess.PIPE, universal_newlines=True)
    if r.returncode != 0:
        die('xstile_sim_filelist.py 失败:\n' + r.stdout + r.stderr)
    gen_out = r.stdout
    pm = PathMap([(src, 'repo'), (golden, 'golden'), (ren, 'outcore')])
    filelist = []
    for line in files_f.read_text().splitlines():
        if line.strip():
            filelist.append([pm.logical(line), sha_file(line)])
    srcmap = []
    for line in tsv.read_text().splitlines():
        if line.startswith('#') or not line.strip():
            continue
        m, cls, p = line.split('\t')
        srcmap.append([m, cls, pm.logical(p)])
    outcore = {p.name: sha_file(p) for p in sorted(ren.iterdir())}

    # 2) SimTop 补丁：执行该提交 run_fullchip.sh 里的补丁原文
    texts = {f: (src / f).read_text() for f in FLOW_FILES}
    patch_py = outdir / 'simtop_patch.py'
    patch_py.write_text(extract_simtop_patch(texts['verif/sim/run_fullchip.sh']))
    simtop = outdir / 'SimTop.sv'
    r = subprocess.run([sys.executable, str(patch_py), str(golden / 'SimTop.sv'), str(simtop)],
                       stdout=subprocess.PIPE, stderr=subprocess.PIPE, universal_newlines=True)
    if r.returncode != 0:
        die('SimTop 补丁执行失败: ' + r.stderr)

    man = {
        'schema': SCHEMA,
        'commit': commit,
        'golden_dir': str(golden),
        'computed_at': datetime.datetime.now().isoformat(timespec='seconds'),
        'selection_inputs': {
            'rtl_tree': git(repo, 'rev-parse', f'{commit}:rtl'),
            'verif_sim_tree': git(repo, 'rev-parse', f'{commit}:verif/sim'),
            **{f: sha_file(src / f) for f in SELECTOR_FILES},
        },
        'filelist': filelist,
        'srcmap': srcmap,
        'outcore_renamed': outcore,
        'simtop_patched': {'sha256': sha_file(simtop), 'golden_SimTop_sha256': sha_file(golden / 'SimTop.sv'),
                           'log': r.stdout.strip()},
        'flow': {f: sha_file(src / f) for f in FLOW_FILES},
        'flow_params': flow_params(texts),
        'verdict_tools': {f: sha_file(src / f) for f in VERDICT_FILES if (src / f).exists()},
    }
    man['generator_log'] = gen_out.replace(str(outdir), '<out>').strip()
    if a.determinism:
        r2 = subprocess.run([sys.executable, str(src / 'verif/sim/xstile_sim_filelist.py'), '--golden',
                             str(golden), '--out', str(outdir / 'again.f'), '--tsv', str(outdir / 'again.tsv'),
                             '--rename-dir', str(ren)], stdout=subprocess.PIPE, stderr=subprocess.PIPE,
                            universal_newlines=True)
        if r2.returncode != 0 or (outdir / 'again.f').read_text() != files_f.read_text() or \
                (outdir / 'again.tsv').read_text() != tsv.read_text() or \
                {p.name: sha_file(p) for p in sorted(ren.iterdir())} != outcore:
            die('生成器两次运行结果不同（非确定性），闭包无意义')
        man['generator_deterministic'] = True
    counts = {}
    for _, cls, _ in srcmap:
        counts[cls] = counts.get(cls, 0) + 1
    man['summary'] = {'filelist_entries': len(filelist),
                      'repo_files': sum(1 for p, _ in filelist if p.startswith('repo:')),
                      'golden_files': sum(1 for p, _ in filelist if p.startswith('golden:')),
                      'outcore_files': sum(1 for p, _ in filelist if p.startswith('outcore:')),
                      'srcmap_classes': counts,
                      'filelist_digest': sha_bytes('\n'.join(f'{p} {h}' for p, h in filelist).encode())}
    if a.workspace:
        man['external'] = external_inputs(a.workspace, golden, a.workload or WORKLOADS_DEFAULT)
        man['external_workspace'] = str(pathlib.Path(a.workspace).resolve())
    pathlib.Path(a.out).write_text(json.dumps(man, indent=1, ensure_ascii=False) + '\n')
    s = man['summary']
    print(f'commit {commit}: 清单 {s["filelist_entries"]} 项（repo {s["repo_files"]} / golden {s["golden_files"]}'
          f' / outcore {s["outcore_files"]}），filelist_digest {s["filelist_digest"][:16]}… -> {a.out}')
    if not a.keep:
        shutil.rmtree(work)
    return 0


# ----------------------------------------------------------------------------------------------
# diff
# ----------------------------------------------------------------------------------------------
def diff_manifests(A, B):
    """返回差异条目列表 [(section, key, a, b)]；空 = 执行闭包相同。commit/computed_at 不算。"""
    out = []

    def cmp_map(sec, a, b):
        for k in sorted(set(a) | set(b)):
            if a.get(k) != b.get(k):
                out.append((sec, k, a.get(k), b.get(k)))

    cmp_map('selection_inputs', A['selection_inputs'], B['selection_inputs'])
    la, lb = [p for p, _ in A['filelist']], [p for p, _ in B['filelist']]
    if la != lb:
        sa, sb = set(la), set(lb)
        for p in sorted(sa - sb):
            out.append(('filelist', p, 'present', 'absent'))
        for p in sorted(sb - sa):
            out.append(('filelist', p, 'absent', 'present'))
        if sa == sb:
            out.append(('filelist', '<order>', 'order differs', ''))
    cmp_map('filelist_sha256', dict(A['filelist']), dict(B['filelist']))
    cmp_map('srcmap', {m: (c, p) for m, c, p in A['srcmap']}, {m: (c, p) for m, c, p in B['srcmap']})
    cmp_map('outcore_renamed', A['outcore_renamed'], B['outcore_renamed'])
    cmp_map('simtop_patched', {k: v for k, v in A['simtop_patched'].items() if k != 'log'},
            {k: v for k, v in B['simtop_patched'].items() if k != 'log'})
    cmp_map('flow', A['flow'], B['flow'])
    cmp_map('flow_params', A['flow_params'], B['flow_params'])
    cmp_map('verdict_tools', A.get('verdict_tools', {}), B.get('verdict_tools', {}))
    if A.get('golden_dir') != B.get('golden_dir'):
        out.append(('golden_dir', '', A.get('golden_dir'), B.get('golden_dir')))
    ea, eb = A.get('external'), B.get('external')
    if ea is not None and eb is not None:
        for sec in sorted(set(ea) | set(eb)):
            va, vb = ea.get(sec), eb.get(sec)
            if isinstance(va, dict) and isinstance(vb, dict):
                cmp_map('external.' + sec, va, vb)
            elif va != vb:
                out.append(('external', sec, va, vb))
    elif (ea is None) != (eb is None):
        out.append(('external', '<presence>', ea is not None, eb is not None))
    return out


def cmd_diff(a):
    A, B = (json.loads(pathlib.Path(p).read_text()) for p in (a.a, a.b))
    for M, p in ((A, a.a), (B, a.b)):
        if M.get('schema') != SCHEMA:
            die(f'{p} 不是 {SCHEMA} 清单')
    d = diff_manifests(A, B)
    print(f'A = {A["commit"]}  ({a.a})\nB = {B["commit"]}  ({a.b})')
    if not d:
        print(f'IDENTICAL：执行闭包逐字节相同（{len(A["filelist"])} 个编译输入 + SimTop 补丁 + 流程脚本'
              f'{" + 外部输入" if "external" in A and "external" in B else ""}）')
        return 0
    print(f'DIFFERENT：{len(d)} 处差异')
    for sec, k, va, vb in d:
        print(f'  [{sec}] {k}: {va} -> {vb}')
    return 1


# ----------------------------------------------------------------------------------------------
# verify-build
# ----------------------------------------------------------------------------------------------
VCS_TIME_RE = re.compile(r'Version (\S+) -- (\w{3} \w{3} +\d+ \d\d:\d\d:\d\d \d{4})')


def parse_build_log(text):
    m = VCS_TIME_RE.search(text)
    if not m:
        die('build.log 里找不到 VCS 版本/启动时刻行')
    start = datetime.datetime.strptime(re.sub(' +', ' ', m.group(2)), '%a %b %d %H:%M:%S %Y')
    design = re.findall(r"Parsing design file '([^']+)'", text)
    included = re.findall(r"Parsing included file '([^']+)'", text)
    library = re.findall(r"Parsing library file '([^']+)'", text)
    cmd = next((l for l in text.splitlines() if l.startswith('vcs ')), None)
    return {'vcs_version': m.group(1), 'start': start, 'design': design, 'included': included,
            'library': library, 'cmd': cmd}


def vcs_switches(cmd):
    """vcs 命令行里与功能/编译语义相关的开关（去掉源文件与 -CFLAGS 串里的路径不同）。"""
    if not cmd:
        return []
    toks = re.findall(r'"[^"]*"|\S+', cmd)
    keep = []
    for t in toks:
        if t.startswith('+define+') or t.startswith('+vcs+') or t in (
                '-full64', '+v2k', '-sverilog', '-timescale=1ns/1ns', '+lint=TFIPC-L', '-debug_access+all',
                '-kdb', '-xprop', '+libext+.v', '+libext+.sv') or t.startswith('-timescale') or \
                t.startswith('-j') or t.startswith('-top') or t == 'tb_top':
            keep.append(t)
    return keep


def reflog_head_at(checkout, when):
    """构建开始时刻 checkout 的 HEAD（取 reflog 中时刻 <= when 的最后一条）。"""
    r = subprocess.run(['git', '-C', str(checkout), 'reflog', '--date=unix', '--format=%H %gd'],
                       stdout=subprocess.PIPE, stderr=subprocess.PIPE, universal_newlines=True)
    best = None
    ts_when = when.timestamp()
    for line in r.stdout.splitlines():
        m = re.match(r'(\w+) \S+@\{(\d+)\}', line)
        if m and int(m.group(2)) <= ts_when and (best is None or int(m.group(2)) > best[1]):
            best = (m.group(1), int(m.group(2)))
    return best


def verify_build(a):
    M = json.loads(pathlib.Path(a.manifest).read_text())
    ws = pathlib.Path(a.workspace).resolve()
    impl = ws / 'impl'
    checkout = pathlib.Path(a.checkout).resolve()
    golden = pathlib.Path(M['golden_dir'])
    pm = PathMap([(checkout, 'repo'), (golden, 'golden'), (impl / 'outcore_renamed', 'outcore')])
    fails, notes = [], []

    def check(ok, msg):
        (notes if ok else fails).append(('OK   ' if ok else 'FAIL ') + msg)

    # 1) 实际编译清单 == 清单（有序、逐路径）
    actual = [l for l in (impl / 'files_impl_nosimtop.f').read_text().splitlines() if l.strip()]
    act_logical = [pm.logical(p) for p in actual]
    exp_logical = [p for p, _ in M['filelist']]
    check(act_logical == exp_logical,
          f'impl/files_impl_nosimtop.f {len(actual)} 项与清单 {len(exp_logical)} 项逐行（含顺序）一致')
    if act_logical != exp_logical:
        sa, sb = set(act_logical), set(exp_logical)
        for p in sorted(sa - sb)[:20]:
            fails.append(f'      仅实际构建有: {p}')
        for p in sorted(sb - sa)[:20]:
            fails.append(f'      仅清单有: {p}')
    # 2) srcmap
    act_map = []
    for line in (impl / 'srcmap.tsv').read_text().splitlines():
        if line.startswith('#') or not line.strip():
            continue
        m, c, p = line.split('\t')
        act_map.append([m, c, pm.logical(p)])
    check(act_map == M['srcmap'], f'impl/srcmap.tsv {len(act_map)} 行与清单一致（模块->来源类别->文件）')
    # 3) outcore 拷贝、SimTop 补丁
    act_out = {p.name: sha_file(p) for p in sorted((impl / 'outcore_renamed').iterdir())}
    check(act_out == M['outcore_renamed'], f'impl/outcore_renamed/ {len(act_out)} 个文件 sha256 与清单一致')
    st = impl / 'build/rtl/SimTop.sv'
    check(sha_file(st) == M['simtop_patched']['sha256'], 'impl/build/rtl/SimTop.sv sha256 == 清单补丁结果')
    lib_dir = sorted(p.name for p in (impl / 'build/rtl').iterdir())
    check(lib_dir == ['SimTop.sv'], f'-y 库兜底目录 impl/build/rtl 只有 SimTop.sv（实际 {lib_dir[:5]}）')
    # 4) build.log：VCS 实际读入了哪些文件
    bl = parse_build_log((impl / 'build.log').read_text(errors='replace'))
    start = bl['start']
    notes.append(f'INFO VCS {bl["vcs_version"]}，启动 {start}')
    design = set(bl['design'])
    dt_vsrc = {p for p in design if p.startswith(str(ws / 'difftest') + '/')}
    expect = set(actual) | {str(st)}
    check(design - dt_vsrc == expect,
          f'build.log 读入 design file {len(design)} 个 = 清单 {len(actual)} + SimTop 1 + difftest vsrc {len(dt_vsrc)}')
    if design - dt_vsrc != expect:
        for p in sorted((design - dt_vsrc) ^ expect)[:20]:
            fails.append(f'      对称差: {p}')
    check(not bl['library'], f'build.log 从 -y 库目录读入 {len(bl["library"])} 个文件')
    inc = sorted(set(bl['included']))
    check(all(p.startswith(str(impl / 'build/generated-src') + '/') for p in inc),
          f'build.log included file 只来自 impl/build/generated-src：{inc}')
    # 5) 构建所读 rtl/golden 文件 == 清单内容，且构建开始后未被改写（mtime 早于 VCS 启动）
    exp_sha = dict(M['filelist'])
    late, badsha = [], []
    for p in actual:
        lp = pm.logical(p)
        if not os.path.exists(p):
            badsha.append(lp + ' (不存在)')
            continue
        if sha_file(p) != exp_sha.get(lp):
            badsha.append(lp)
        if datetime.datetime.fromtimestamp(os.path.getmtime(p)) >= start:
            late.append(lp)
    check(not badsha, f'构建清单文件当前内容 == 清单 sha256（{len(actual) - len(badsha)}/{len(actual)}）'
          + (f' 不符: {badsha[:10]}' if badsha else ''))
    check(not late, f'构建清单文件 mtime 全部早于 VCS 启动（晚于者 {len(late)}: {late[:10]}）')
    # 6) 构建开始时刻 checkout HEAD == 清单提交
    head = reflog_head_at(checkout, start)
    check(head is not None and head[0] == M['commit'],
          f'构建时刻 {checkout} 的 HEAD（reflog）= {head[0] if head else None}，清单提交 {M["commit"]}')
    # 7) vcs 命令行：开关与默认 difftest 流一致；与 golden 侧构建（若给了）开关相同
    sw = vcs_switches(bl['cmd'])
    notes.append('INFO vcs 开关: ' + ' '.join(sw))
    check('-debug_access+all' not in sw and '+define+DIFFTEST' in sw and '+vcs+initreg+random' in sw,
          'vcs 开关含 +define+DIFFTEST / +vcs+initreg+random，无 -debug_access+all（快 simv）')
    check(f'-f {impl}/files_impl_nosimtop.f' in (bl['cmd'] or ''), 'vcs 命令行 -f 指向 impl/files_impl_nosimtop.f')
    if a.golden_build_log:
        g = parse_build_log(pathlib.Path(a.golden_build_log).read_text(errors='replace'))
        gsw = vcs_switches(g['cmd'])
        check(gsw == sw, f'golden 侧构建 vcs 开关与 impl 侧逐个相同（golden: {a.golden_build_log}）')
        check(g['vcs_version'] == bl['vcs_version'], f'golden/impl VCS 版本相同 {g["vcs_version"]}')
    # 8) 外部输入：实测 == 清单 external（若清单带了），且 mtime 早于构建
    if 'external' in M:
        ext = external_inputs(ws, golden, a.workload or WORKLOADS_DEFAULT)
        for sec in ('difftest', 'generated_src', 'xs_build_copies'):
            check(ext[sec] == M['external'][sec], f'外部输入 {sec}（{len(ext[sec])} 个文件）== 清单')
        late_ext = []
        for root, flt in ((ws / 'difftest', difftest_filter), (impl / 'build/generated-src', None)):
            for p in root.rglob('*'):
                rel = str(p.relative_to(root))
                if p.is_file() and not rel.endswith('.orig') and (flt is None or flt(rel)) \
                        and datetime.datetime.fromtimestamp(p.stat().st_mtime) >= start:
                    late_ext.append(str(p))
        check(not late_ext, f'difftest/generated-src 文件 mtime 早于 VCS 启动（晚于者 {len(late_ext)}）')
        check(ext['generated_src'] == ext['regen_generated_src'],
              'impl/build/generated-src 与 regen/build/generated-src（check_dpic 门禁源）逐文件相同')
    # 9) golden 用到的文件 sha256 == G1 MANIFEST.tsv
    mf = golden.parent / 'MANIFEST.tsv'
    if mf.exists():
        gm = {}
        for line in mf.read_text().splitlines():
            parts = line.split('\t')
            if len(parts) >= 3:
                gm[parts[2]] = parts[0]
        used = [(p[len('golden:'):], h) for p, h in M['filelist'] if p.startswith('golden:')]
        used.append(('SimTop.sv', M['simtop_patched']['golden_SimTop_sha256']))
        bad = [n for n, h in used if gm.get(n) != h]
        check(not bad, f'清单所用 golden 文件 {len(used)} 个 sha256 == G1 MANIFEST.tsv（不符 {bad[:10]}）')
    for n in notes + fails:
        print(n)
    print(('VERIFIED' if not fails else 'MISMATCH') + f'：实际构建 {ws} 对清单 {M["commit"][:12]} '
          f'（{len(fails)} 项失败）')
    return 0 if not fails else 1


def main():
    ap = argparse.ArgumentParser(description=__doc__.split('\n')[0])
    sub = ap.add_subparsers(dest='cmd')
    c = sub.add_parser('compute')
    c.add_argument('--repo', required=True)
    c.add_argument('--commit', required=True)
    c.add_argument('--out', required=True)
    c.add_argument('--golden', default=GOLDEN_DEFAULT)
    c.add_argument('--workspace', help='sim 工作区（含 difftest/、impl/build/、regen/）；给了才记外部输入')
    c.add_argument('--workload', action='append', help='负载 bin（可多次；默认 smoke/coremark/dhrystone + cputest）')
    c.add_argument('--determinism', action='store_true', help='生成器再跑一次，确认清单可复算（多 ~80s）')
    c.add_argument('--keep', action='store_true', help='保留 $TMPDIR/bcl-<sha> 解包目录')
    v = sub.add_parser('verify-build')
    v.add_argument('--manifest', required=True)
    v.add_argument('--workspace', required=True)
    v.add_argument('--checkout', required=True, help='构建时 run_fcb.sh 所在仓（SV_HOME）')
    v.add_argument('--golden-build-log', help='golden 侧 build.log，比对 vcs 开关')
    v.add_argument('--workload', action='append')
    d = sub.add_parser('diff')
    d.add_argument('a')
    d.add_argument('b')
    a = ap.parse_args()
    if not a.cmd:
        ap.print_help()
        return 2
    return {'compute': compute, 'verify-build': verify_build, 'diff': cmd_diff}[a.cmd](a)


if __name__ == '__main__':
    sys.exit(main())
