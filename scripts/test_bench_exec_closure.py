#!/usr/bin/env python3
"""bench_exec_closure.py 的最小测试（合成小仓 + 合成 golden，不碰真实工作区）。

规矩（同 scripts/test_check_closure_symmetry.py）：每条断言既看退出码也看输出关键字；
每个变异都先有未变异对照（同提交两次计算 IDENTICAL、未篡改的伪构建 VERIFIED）。

覆盖：
  1. 同一提交算两次 -> IDENTICAL（确定性 + 逻辑路径与检出位置无关）
  2. 被选中的 rtl 文件改一个字节 -> DIFFERENT，指名该文件
  3. 只加一个**不被选中**的 rtl 文件 -> 编译清单不变但 selection_inputs.rtl_tree 变 -> 仍报 DIFFERENT
     （rtl 树变了要显式看见，不能静默）
  4. 流程脚本改参数（RAM_SIZE 默认值）-> flow / flow_params 报差
  5. 存储模型（golden ram_*）改一个字节 -> 报 golden:ram 文件差
  6. verify-build：按清单搭的伪构建 VERIFIED；构建后改写 checkout 里被编译的 rtl -> MISMATCH

跑法： python3 scripts/test_bench_exec_closure.py      （exit 0 = 全过）
"""
import datetime
import importlib.util
import os
import pathlib
import shutil
import subprocess
import sys
import tempfile

HERE = pathlib.Path(__file__).resolve().parent
REPO = HERE.parent
SCRIPT = HERE / 'bench_exec_closure.py'
COPY = ['verif/sim/xstile_sim_filelist.py', 'verif/sim/run_fcb.sh', 'verif/sim/run_fastsim.sh',
        'verif/sim/run_fullchip.sh', 'verif/sim/commit_compare.py', 'verif/sim/bench_verdict.py',
        'scripts/full_elab_filelist.py']
PASS, FAIL = [], []


def sh(*cmd, cwd=None, env=None, check=True):
    r = subprocess.run(list(cmd), cwd=cwd, env=env, stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
                       universal_newlines=True)
    if check and r.returncode != 0:
        raise AssertionError(f'{cmd} 失败: {r.stdout}')
    return r


def expect(name, cond, detail=''):
    (PASS if cond else FAIL).append(name)
    print(('PASS ' if cond else 'FAIL ') + name + ('' if cond else '\n    ' + detail.replace('\n', '\n    ')))


def write(p, s):
    p.parent.mkdir(parents=True, exist_ok=True)
    p.write_text(s)


def make_golden(g):
    write(g / 'extern_modules.sv', '`ifndef FOO_MACRO\n`define FOO_MACRO\n`endif\n')
    write(g / 'SimTop.sv', 'module SimTop();\n  wire a;\n  XSTile u_t ();\n  Outer u_o ();\n'
                           '  LogPerf u_p (.x(SimTop.u_t.probe_0));\nendmodule\n')
    write(g / 'XSTile.sv', 'module XSTile();\n  Core u_c ();\nendmodule\n')
    write(g / 'Core.sv', 'module Core();\nendmodule\n')
    write(g / 'Outer.sv', 'module Outer();\n  ram_4x8 u_r ();\nendmodule\n')
    write(g / 'LogPerf.sv', 'module LogPerf(input x);\nendmodule\n')
    write(g / 'ram_4x8.sv', 'module ram_4x8();\nendmodule\n')


def git_commit(repo, msg):
    sh('git', 'add', '-A', cwd=repo)
    sh('git', '-c', 'user.name=t', '-c', 'user.email=t@t', 'commit', '-q', '-m', msg, cwd=repo)
    return sh('git', 'rev-parse', 'HEAD', cwd=repo).stdout.strip()


def main():
    tmp = pathlib.Path(tempfile.mkdtemp(prefix='test_bcl_', dir=os.environ.get('TMPDIR')))
    env = dict(os.environ, TMPDIR=str(tmp / 'tmpdir'))
    try:
        g = tmp / 'golden-rtl'
        make_golden(g)
        repo = tmp / 'repo'
        for f in COPY:
            q = repo / f
            q.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy(REPO / f, q)
        write(repo / 'rtl/xstile/XSTile.sv', 'module XSTile();\n  Core u_c ();\n  ram_4x8 u_m ();\nendmodule\n')
        write(repo / 'rtl/core/Core.sv', '// v1\nmodule Core();\nendmodule\n')
        sh('git', 'init', '-q', str(repo))
        c1 = git_commit(repo, 'c1')

        def compute(commit, out, golden=g, keep=False):
            args = [sys.executable, str(SCRIPT), 'compute', '--repo', str(repo), '--commit', commit,
                    '--golden', str(golden), '--out', str(tmp / out)] + (['--keep'] if keep else [])
            return sh(*args, env=env)

        def diff(a, b):
            return sh(sys.executable, str(SCRIPT), 'diff', str(tmp / a), str(tmp / b), env=env, check=False)

        compute(c1, 'm1.json')
        compute(c1, 'm1b.json')
        r = diff('m1.json', 'm1b.json')
        expect('同提交两次 -> IDENTICAL', r.returncode == 0 and 'IDENTICAL' in r.stdout, r.stdout)

        # 2) 被选中的 rtl 文件改一个字节
        write(repo / 'rtl/core/Core.sv', '// v2\nmodule Core();\nendmodule\n')
        c2 = git_commit(repo, 'c2')
        compute(c2, 'm2.json')
        r = diff('m1.json', 'm2.json')
        expect('选中 rtl 改字节 -> DIFFERENT 且指名文件',
               r.returncode == 1 and '[filelist_sha256] repo:rtl/core/Core.sv' in r.stdout, r.stdout)

        # 3) 只加不被选中的 rtl 文件
        sh('git', 'checkout', '-q', c1, cwd=repo)
        write(repo / 'rtl/extra/Unused.sv', 'module Unused();\nendmodule\n')
        c3 = git_commit(repo, 'c3')
        compute(c3, 'm3.json')
        r = diff('m1.json', 'm3.json')
        expect('未选中 rtl 新增 -> 清单不变但 rtl_tree 报差',
               r.returncode == 1 and '[selection_inputs] rtl_tree' in r.stdout and '[filelist' not in r.stdout,
               r.stdout)

        # 4) 流程脚本参数
        sh('git', 'checkout', '-q', c1, cwd=repo)
        fs = repo / 'verif/sim/run_fastsim.sh'
        t = fs.read_text()
        assert 'RAM_SIZE="${RAM_SIZE:-8589934592}"' in t, 'run_fastsim.sh 的 RAM_SIZE 行变了，测试须更新'
        fs.write_text(t.replace('RAM_SIZE="${RAM_SIZE:-8589934592}"', 'RAM_SIZE="${RAM_SIZE:-4294967296}"'))
        c4 = git_commit(repo, 'c4')
        compute(c4, 'm4.json')
        r = diff('m1.json', 'm4.json')
        expect('流程脚本 RAM_SIZE 变 -> flow + flow_params 报差',
               r.returncode == 1 and '[flow] verif/sim/run_fastsim.sh' in r.stdout
               and '[flow_params] RAM_SIZE: 8589934592 -> 4294967296' in r.stdout, r.stdout)

        # 5) 存储模型改字节（同提交，换一份 golden）
        g2 = tmp / 'g2' / 'golden-rtl'
        shutil.copytree(str(g), str(g2))
        (g2 / 'ram_4x8.sv').write_text('module ram_4x8();\n  // changed\nendmodule\n')
        compute(c1, 'm5.json', golden=g2)
        r = diff('m1.json', 'm5.json')
        expect('存储模型改字节 -> golden:ram_4x8.sv 报差',
               r.returncode == 1 and '[filelist_sha256] golden:ram_4x8.sv' in r.stdout, r.stdout)

        # 6) verify-build：按 c1 在 checkout 上搭伪构建
        sh('git', 'checkout', '-q', c1, cwd=repo)
        ws = tmp / 'ws'
        impl = ws / 'impl'
        (impl / 'build/rtl').mkdir(parents=True)
        sh(sys.executable, str(repo / 'verif/sim/xstile_sim_filelist.py'), '--golden', str(g), '--out',
           str(impl / 'files_impl_nosimtop.f'), '--tsv', str(impl / 'srcmap.tsv'), '--rename-dir',
           str(impl / 'outcore_renamed'))
        spec = importlib.util.spec_from_file_location('bec', str(SCRIPT))
        bec = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(bec)
        pp = tmp / 'patch.py'
        pp.write_text(bec.extract_simtop_patch((repo / 'verif/sim/run_fullchip.sh').read_text()))
        sh(sys.executable, str(pp), str(g / 'SimTop.sv'), str(impl / 'build/rtl/SimTop.sv'))
        files = [l for l in (impl / 'files_impl_nosimtop.f').read_text().splitlines() if l]
        start = datetime.datetime.now() + datetime.timedelta(seconds=120)
        log = ['                         Chronologic VCS (TM)',
               '       Version T-2099.01_Full64 -- ' + start.strftime('%a %b %d %H:%M:%S %Y'),
               f'vcs +define+DIFFTEST -full64 +v2k -top tb_top -sverilog +define+VCS +vcs+initreg+random '
               f'-f {impl}/files_impl_nosimtop.f {impl}/build/rtl/SimTop.sv']
        log += [f"Parsing design file '{p}'" for p in files + [str(impl / 'build/rtl/SimTop.sv')]]
        (impl / 'build.log').write_text('\n'.join(log) + '\n')
        vb = [sys.executable, str(SCRIPT), 'verify-build', '--manifest', str(tmp / 'm1.json'), '--workspace',
              str(ws), '--checkout', str(repo)]
        r = sh(*vb, env=env, check=False)
        expect('伪构建（未篡改）-> VERIFIED', r.returncode == 0 and 'VERIFIED' in r.stdout, r.stdout)
        (repo / 'rtl/core/Core.sv').write_text('// tampered\nmodule Core();\nendmodule\n')
        r = sh(*vb, env=env, check=False)
        expect('构建后 checkout 的 rtl 被改 -> MISMATCH',
               r.returncode == 1 and 'MISMATCH' in r.stdout and 'repo:rtl/core/Core.sv' in r.stdout, r.stdout)
    finally:
        shutil.rmtree(str(tmp), ignore_errors=True)
    print(f'{len(PASS)} PASS / {len(FAIL)} FAIL')
    return 0 if not FAIL else 1


if __name__ == '__main__':
    sys.exit(main())
