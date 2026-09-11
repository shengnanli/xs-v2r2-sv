#!/usr/bin/env python3
"""fastlane_batch.py —— 快车道批量继承+验证驱动器（严格串行, FM 禁并发）。

对每个目标: inherit → derive → compile → UT seed 1/7/42 → FM 全变体。
任何一步失败记录状态继续下一个（收尾人工triage）; 结果追加 docs/fastlane_ledger.tsv。
用法: fastlane_batch.py <target...>  或  fastlane_batch.py --list <file>
"""
import json
import pathlib
import re
import subprocess
import sys

NEW = pathlib.Path('/home/eda/xs-env/xs-v2-sv')
MANIFEST = pathlib.Path('/home/eda/xs-env/xs-signoff/scripts/sidecar/manifest_305.json')
LEDGER = NEW / 'docs' / 'fastlane_ledger.tsv'


def sh(cmd, cwd, timeout=1800):
    p = subprocess.run(cmd, cwd=str(cwd), shell=True, stdout=subprocess.PIPE,
                       stderr=subprocess.STDOUT, universal_newlines=True, timeout=timeout)
    return p.returncode, p.stdout


def record(t, status, note=''):
    with LEDGER.open('a') as f:
        f.write(f'{t}\t{status}\t{note}\n')
    print(f'[{status}] {t} {note}', flush=True)


def main():
    args = sys.argv[1:]
    if args and args[0] == '--list':
        targets = [l.strip() for l in pathlib.Path(args[1]).read_text().splitlines()
                   if l.strip() and not l.startswith('#')]
    else:
        targets = args
    man = {e['target']: e for e in json.load(MANIFEST.open())['entries']}

    for t in targets:
        rc, out = sh(f'python3 scripts/inherit_target.py {t}', NEW, 300)
        if rc != 0:
            record(t, 'INHERIT_FAIL', out.strip().splitlines()[-1][:200])
            continue
        ut = NEW / 'verif' / 'ut' / man[t]['ut_dir']
        rc, out = sh('make derive && make compile', ut, 1800)
        if rc != 0:
            tail = ' | '.join(out.strip().splitlines()[-8:])[:300]
            record(t, 'COMPILE_FAIL', tail)
            continue
        ut_fail = ''
        for s in (1, 7, 42):
            rc, out = sh(f'make run SEED={s}', ut, 3600)
            if rc != 0 or 'TEST PASSED' not in out:
                mm = [l for l in out.splitlines() if 'mismatch' in l][:2]
                ut_fail = f'seed{s}: ' + (' | '.join(mm) if mm else 'no TEST PASSED')[:250]
                break
        if ut_fail:
            record(t, 'UT_FAIL', ut_fail)
            continue
        rc, out = sh('make fm', ut, 7200)
        verdicts = re.findall(r'^(SUCCEEDED|PARTIAL|FAILED|ERROR)\t', out, re.MULTILINE)
        if rc == 0 and 'FM all variants passed' in out:
            record(t, 'PASS', f'fm_verdicts={len(verdicts)}')
        else:
            bad = [l[:160] for l in out.splitlines()
                   if re.match(r'^(PARTIAL|FAILED|ERROR)\t', l)][:2]
            record(t, 'FM_FAIL', ' | '.join(bad) if bad else out.strip().splitlines()[-1][:200])


if __name__ == '__main__':
    main()
