#!/usr/bin/env python3
"""fastlane_batch.py —— 快车道批量继承+验证驱动器（并行版）。

阶段1: 逐目标串行 inherit（registry 共享状态, 不并发）; 按 ut_dir 去重
       （家族共用一个 UT 目录时只跑一次, 台账记 ut_dir 代表名）。
阶段2: --jobs N 并行验证（derive → compile → UT seed1/7/42 → FM 全变体）。
       本机 32C/125G + Formality license 充裕(9999席), 小模块并行安全;
       超大模块(未来 Backend/MemBlock 级)仍须单独跑——不进本驱动器。
结果追加 docs/fastlane_ledger.tsv。
用法: fastlane_batch.py [--jobs N] <target...> | --list <file>
"""
import json
import pathlib
import re
import subprocess
import sys
import threading
from concurrent.futures import ThreadPoolExecutor

NEW = pathlib.Path('/home/eda/xs-env/xs-v2-sv')
MANIFEST = pathlib.Path('/home/eda/xs-env/xs-signoff/scripts/sidecar/manifest_305.json')
LEDGER = NEW / 'docs' / 'fastlane_ledger.tsv'
_LOCK = threading.Lock()


def sh(cmd, cwd, timeout=1800):
    p = subprocess.run(cmd, cwd=str(cwd), shell=True, stdout=subprocess.PIPE,
                       stderr=subprocess.STDOUT, universal_newlines=True, timeout=timeout)
    return p.returncode, p.stdout


def record(t, status, note=''):
    with _LOCK:
        with LEDGER.open('a') as f:
            f.write(f'{t}\t{status}\t{note}\n')
    print(f'[{status}] {t} {note}', flush=True)


def verify(t, ut):
    try:
        rc, out = sh('make derive && make compile', ut, 1800)
        if rc != 0:
            record(t, 'COMPILE_FAIL', ' | '.join(out.strip().splitlines()[-8:])[:300])
            return
        for s in (1, 7, 42):
            rc, out = sh(f'make run SEED={s}', ut, 3600)
            if rc != 0 or 'TEST PASSED' not in out:
                mm = [l for l in out.splitlines() if 'mismatch' in l][:2]
                record(t, 'UT_FAIL',
                       f'seed{s}: ' + (' | '.join(mm) if mm else 'no TEST PASSED')[:250])
                return
        rc, out = sh('make fm', ut, 7200)
        verdicts = re.findall(r'^SUCCEEDED\t', out, re.MULTILINE)
        if rc == 0 and 'FM all variants passed' in out:
            record(t, 'PASS', f'fm_verdicts={len(verdicts)}')
        else:
            bad = [l[:160] for l in out.splitlines()
                   if re.match(r'^(PARTIAL|FAILED|ERROR)\t', l)][:2]
            record(t, 'FM_FAIL', ' | '.join(bad) if bad else out.strip().splitlines()[-1][:200])
    except subprocess.TimeoutExpired as e:
        record(t, 'TIMEOUT', str(e.cmd)[:120])


def main():
    args = sys.argv[1:]
    jobs = 8
    if args and args[0] == '--jobs':
        jobs = int(args[1]); args = args[2:]
    if args and args[0] == '--list':
        targets = [l.strip() for l in pathlib.Path(args[1]).read_text().splitlines()
                   if l.strip() and not l.startswith('#')]
    else:
        targets = args
    man = {e['target']: e for e in json.load(MANIFEST.open())['entries']}

    # 阶段1: 串行 inherit + 按 ut_dir 去重
    work = []          # (代表名, ut_path)
    seen_ut = set()
    for t in targets:
        ut_dir = man[t]['ut_dir']
        if ut_dir in seen_ut:
            record(t, 'MERGED', f'与 {ut_dir} 家族同 UT 目录, 由代表目标覆盖')
            continue
        seen_ut.add(ut_dir)
        rc, out = sh(f'python3 scripts/inherit_target.py {t}', NEW, 300)
        if rc != 0:
            record(t, 'INHERIT_FAIL', out.strip().splitlines()[-1][:200])
            continue
        work.append((t, NEW / 'verif' / 'ut' / ut_dir))

    # 阶段2: 并行验证
    print(f'== inherit 完成, 并行验证 {len(work)} 个目标 (jobs={jobs}) ==', flush=True)
    with ThreadPoolExecutor(max_workers=jobs) as ex:
        for t, ut in work:
            ex.submit(verify, t, ut)


if __name__ == '__main__':
    main()
