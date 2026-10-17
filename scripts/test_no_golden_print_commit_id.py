#!/usr/bin/env python3
"""test_no_golden_print_commit_id.py —— impl 闭包不得读 G1/golden 的 PrintCommitIDModule.v（codex 0230 第 2 题）。

PrintCommitIDModule 是仿真专用的版本号打印件（零输出）。以前各 UT 把 golden `PrintCommitIDModule.v` 放进
RTL_GOLDEN_DEPS 两侧共读，于是它进了 impl 闭包，证书判据 validate_impl_golden_certified 判
`green_child_impl_golden_unexpected_path`（ExuBlock 实测）。0230 裁定：impl 一律读本地重写件
rtl/common/PrintCommitIDModule.sv，ref 继续读 G1 .v。本闸防止以后有人（或某个生成器）把 golden 依赖加回去。

检查两处（任一命中即 rc=1）：
  1. 每个 verif/ut/*/Makefile 里 **impl 侧**变量（RTL_SRCS / RTL_GOLDEN_DEPS / FM_IMPL_RTL，含 `fm-X: RTL_SRCS = ...`
     这种目标专属赋值，续行合并后整体看）不得出现 `PrintCommitIDModule.v`；
  2. 每份 tracked 证书 verif/proof_certificates/*.json 的 input_closure.impl 不得有 basename 为 PrintCommitIDModule.v 的条目。
--selftest：对两个人造反例（Makefile 片段 / 证书片段）必须报错、对正例必须放行。
"""
import json
import pathlib
import re
import sys

REPO = pathlib.Path(__file__).resolve().parent.parent
BAD = 'PrintCommitIDModule.v'
IMPL_VAR = re.compile(r'^(?:[\w.%-]+:\s*)?(RTL_SRCS|RTL_GOLDEN_DEPS|FM_IMPL_RTL)\s*[:+?]?=(.*)$')


def makefile_hits(text):
    """返回 impl 侧变量里出现 BAD 的 (变量名, 行号) 列表。"""
    lines = text.splitlines()
    hits, i = [], 0
    while i < len(lines):
        m = IMPL_VAR.match(lines[i])
        if not m:
            i += 1
            continue
        start, body = i, m.group(2)
        while body.rstrip().endswith('\\') and i + 1 < len(lines):
            i += 1
            body = body.rstrip()[:-1] + ' ' + lines[i]
        body = re.sub(r'#.*', '', body)
        if BAD in body:
            hits.append((m.group(1), start + 1))
        i += 1
    return hits


def cert_hits(doc):
    impl = (doc.get('input_closure') or {}).get('impl') or []
    return [e.get('path') for e in impl if (e.get('path') or '').split('/')[-1] == BAD]


def selftest():
    ok = True
    bad_mk = 'RTL_SRCS = a.sv\nRTL_GOLDEN_DEPS = $(XSSV_HOME)/rtl/common/ClockGate.sv \\\n  $(GOLDEN_RTL)/PrintCommitIDModule.v\n'
    good_mk = ('RTL_SRCS = $(RTL_DIR)/common/PrintCommitIDModule.sv\nRTL_GOLDEN_DEPS =\n'
               'FM_REF_DEPS_X = PrintCommitIDModule.v\nGOLDEN_SRCS = $(GOLDEN_RTL)/PrintCommitIDModule.v\n'
               '# RTL_GOLDEN_DEPS = PrintCommitIDModule.v（注释）\n')
    tgt_mk = 'fm-X: RTL_SRCS = $(GOLDEN_RTL)/PrintCommitIDModule.v\n'
    ok &= bool(makefile_hits(bad_mk))
    ok &= bool(makefile_hits(tgt_mk))
    ok &= not makefile_hits(good_mk)
    ok &= bool(cert_hits({'input_closure': {'impl': [{'kind': 'golden', 'path': '/x/golden-rtl/PrintCommitIDModule.v'}]}}))
    ok &= not cert_hits({'input_closure': {'impl': [{'kind': 'repo', 'path': 'rtl/common/PrintCommitIDModule.sv'}],
                                           'golden': [{'path': '/x/golden-rtl/PrintCommitIDModule.v'}]}})
    print('selftest', 'OK' if ok else 'FAIL')
    return 0 if ok else 1


def main():
    if '--selftest' in sys.argv[1:]:
        return selftest()
    bad = []
    for mk in sorted((REPO / 'verif' / 'ut').glob('*/Makefile')):
        for var, ln in makefile_hits(mk.read_text(errors='replace')):
            bad.append('%s:%d %s 含 golden %s' % (mk.relative_to(REPO), ln, var, BAD))
    for cp in sorted((REPO / 'verif' / 'proof_certificates').glob('*.json')):
        try:
            doc = json.loads(cp.read_text())
        except Exception:                                   # noqa: BLE001
            continue
        for p in cert_hits(doc):
            bad.append('%s: impl 闭包含 %s' % (cp.relative_to(REPO), p))
    for b in bad:
        print('FAIL:', b)
    print('test_no_golden_print_commit_id: %s（%d 处）' % ('FAIL' if bad else 'OK', len(bad)))
    return 1 if bad else 0


if __name__ == '__main__':
    sys.exit(main())
