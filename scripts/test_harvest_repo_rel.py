#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""test_harvest_repo_rel.py —— receipt 收录表 repo_rel()：证明树根前缀必须还原成仓内相对路径。

为什么有这条（2026-10-17）：TMP_PREFIX_RE 原来只认 /tmp/xsv2-proof-*/。TMPDIR 换到 /home 后
（tmp-rp/<tag>/xsv2-proof-*、tmp-bpu/xsv2-proof-* 等）以及直接在 lane worktree 里跑的证明
（wt-ssit2/...），钉点路径都原样保留成绝对路径 —— chk_pins 实际比的是 lane worktree 里那份
文件，而不是 main 的。wt-ssit2 回收后，已入库的 SSIT@684cbdbaf05c 从 COLLECTED 翻成 NEEDS_RERUN。

  正例：/tmp、/home/eda/xs-env/tmp-*/(...)/xsv2-proof-*、scratchpad 下的 xsv2-proof-*、wt-*  -> 仓内相对路径
  反例：仓外普通绝对路径（不是证明树根）保持原样；只去最近一层树根（verif 下再出现 wt- 字样不再剥）
"""
import os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import gen_receipt_harvest as g

REL = 'verif/ut/SSIT/fm_pins.tcl'
CASES = [
    ('/tmp/xsv2-proof-AbC123/' + REL, REL),
    ('/home/eda/xs-env/tmp-rp/be-SSIT/xsv2-proof-pBRxCB/' + REL, REL),
    ('/home/eda/xs-env/tmp-bpu/xsv2-proof-q1/' + REL, REL),
    ('/tmp/claude-1000/x/scratchpad/ptw3/xsv2-proof-zz/' + REL, REL),
    ('/home/eda/xs-env/wt-ssit2/' + REL, REL),
    ('/home/eda/xs-env/wt-ssit2/verif/ut/wt-x/a.tcl', 'verif/ut/wt-x/a.tcl'),
    # 反例
    ('/home/eda/xs-env/XiangShan/build/rtl/SSIT.sv', '/home/eda/xs-env/XiangShan/build/rtl/SSIT.sv'),
    ('/home/eda/other/' + REL, '/home/eda/other/' + REL),
    (REL, REL),
]

bad = 0
for src, want in CASES:
    got = g.repo_rel(src)
    ok = got == want
    bad += not ok
    print('%s %s -> %s' % ('PASS' if ok else 'FAIL', src, got))
print('%d/%d' % (len(CASES) - bad, len(CASES)))
sys.exit(1 if bad else 0)
