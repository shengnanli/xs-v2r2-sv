#!/usr/bin/env python3
"""mutants.sh 的定点替换器：锚点必须在文件里**唯一**出现，否则拒绝
（防"以为改了其实没改"）。单独成文件而不是内嵌 heredoc —— 内嵌会和外层
heredoc 抢结束标记，改脚本时很容易把它悄悄改坏。"""
import os, sys
p = sys.argv[1]
old = os.environ["MUT_OLD"].replace("\\n", "\n").replace("\\&", "&")
new = os.environ["MUT_NEW"].replace("\\n", "\n").replace("\\&", "&")
t = open(p).read()
n = t.count(old)
if n != 1:
    sys.stderr.write("anchor count=%d (need exactly 1)\n" % n)
    sys.exit(2)
open(p, "w").write(t.replace(old, new, 1))
