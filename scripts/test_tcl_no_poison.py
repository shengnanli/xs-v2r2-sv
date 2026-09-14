#!/usr/bin/env python3
"""test_tcl_no_poison.py —— 禁止 FM Tcl 脚本里出现会污染判定的字符串。

**为什么要有这道闸**（2026-09-14，agent/err3 实测踩到）：

`fm_shell` 会把被 source 的 Tcl **逐行回显进 fm.log**，注释也不例外。而
`scripts/fm_verdict.py` 的若干判据是在**整份 fm.log 上做正则**：

    _ELAB147    = re.compile(r'FMR_ELAB-147')
    _DONTVERIFY = re.compile(r"set_dont_verify_points|Don't verify")

于是**在 fm_eq.tcl 的注释里把这些串完整写出来，就会让每一个目标的判定中毒**。
worker 原话：写全 `FMR_ELAB-147` 之后 MuxBundle 当场从 SUCCEEDED 翻成
`elab147=true` 的 PARTIAL —— 而 RTL 一个字没动。

这类污染极难排查：判定说"检测到 X"，你去查 RTL 和 golden 都找不到 X，因为 X
来自你自己写的一句注释。

## 更彻底的修法（未做，需 reviewer）

判据应改为读 `sidecar/native_facts.json` 的 `qualifications.*`（走 Formality API，
不过正则），而不是在日志正文上 grep。那会动 FM 判定语义、可能移动既有 verdict，
超出本闸范围。在那之前，这道闸是防线。
"""
import pathlib
import re
import sys

HERE = pathlib.Path(__file__).resolve().parent
# 与 fm_verdict.py 的判据逐字对应；改那边必须同步改这里。
POISON = [
    (re.compile(r'FMR_ELAB-147'), '_ELAB147'),
    (re.compile(r"set_dont_verify_points|Don't verify"), '_DONTVERIFY'),
]
# ★只扫**真被逐行回显**的脚本★（2026-09-14 实测定的范围）
# fm_shell 用 `-file` 载入的入口脚本会被逐行回显进 fm.log，注释也不例外 ——
# 实测：fm_eq.tcl 里的注释词「轮转仲裁」在 evidence/*/RNXbar/fm.log 里命中 1 行。
# 但 sidecar 下被 `source` 的脚本**不回显**：同一份日志里 SIDECAR_APPVAR_DIAG_ONLY
# 与 dv_nonempty_hdr 均 0 行，而 fm_native_emit.tcl 里确实有 set_dont_verify_points
# 和 "Don't verify"（那是它的解析代码，本来就该有）。
# 所以本闸只扫入口脚本。把 sidecar 也扫进来会产生假报 —— 闸里的假报比漏报更坏，
# 它会逼人把正确的解析代码改掉。
SCANNED = ['fm_eq.tcl', 'fm_eq_full.tcl']

PASS, FAIL = [], []


def scan(path):
    if not path.is_file():
        return []
    hits = []
    for i, line in enumerate(path.read_text(errors='replace').splitlines(), 1):
        for rx, who in POISON:
            if rx.search(line):
                hits.append((i, who, line.strip()[:88]))
    return hits


print('=== 扫描会被 fm_shell 回显的入口 Tcl ===')
files = [HERE / n for n in SCANNED]
seen = set()
bad = 0
for f in files:
    if f in seen or not f.is_file():
        continue
    seen.add(f)
    hits = scan(f)
    if hits:
        bad += len(hits)
        FAIL.append(f.name)
        print(f'  FAIL  {f.name}')
        for ln, who, txt in hits:
            print(f'          :{ln}  命中 {who}  {txt}')
    else:
        print(f'  ok    {f.name}')
if not FAIL:
    PASS.append('P1')

# ★对照★：种一个真污染，必须被抓 —— 否则上面的 ok 可能是空转。
probe = HERE / '_poison_probe_tmp.tcl'
try:
    probe.write_text("# 举例说明那条消息号：FMR_ELAB-147\nputs hi\n")
    hits = scan(probe)
    ok = len(hits) == 1
    (PASS if ok else FAIL).append('P2')
    print(f'  {"ok  " if ok else "FAIL"}  P2 对照：种入真污染必须被抓（命中 {len(hits)} 处）')
finally:
    if probe.exists():
        probe.unlink()

# ★对照★：裸 dont_verify 不该报（fm_verdict 的正则要的是 set_dont_verify_points
# 或 "Don't verify"）—— 否则闸比判据还严，会逼人不敢在注释里讨论这件事。
probe2 = HERE / '_poison_probe2_tmp.tcl'
try:
    probe2.write_text("# 本目标无 dont_verify、无黑盒\nputs hi\n")
    hits = scan(probe2)
    ok = len(hits) == 0
    (PASS if ok else FAIL).append('P3')
    print(f'  {"ok  " if ok else "FAIL"}  P3 对照：裸 dont_verify 不算污染（闸不得严于判据）')
finally:
    if probe2.exists():
        probe2.unlink()

print()
print(f'PASS {len(PASS)} / FAIL {len(FAIL)}')
sys.exit(1 if FAIL else 0)
