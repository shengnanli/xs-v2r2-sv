#!/usr/bin/env python3
"""生成 MbistIntfL2 的双例化 UT testbench（tb.sv）：golden MbistIntfL2 vs 重写 MbistIntfL2_xs，
纯组合直通（无时钟），每拍全输入随机、逐位比较全部输出（scripts/dual_tb_lib.py）。

用法：python3 gen.py [--check]
"""
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, "..", "..", "..", "scripts"))
from dual_tb_lib import Pair, render, write_or_check  # noqa: E402

PAIRS = [Pair("MbistIntfL2", "mi_", clocked=False,
              cov=[("req", "@mbist_req"), ("ack", "@mbist_ack")])]
HEADER = """
tb —— MbistIntfL2：L2 MBIST 树根（MbistInterface，单子树退化为直通）双例化 UT。
本文件由 gen.py 生成（scripts/dual_tb_lib.py），勿手改。
"""

if __name__ == "__main__":
    txt = render(PAIRS, header=HEADER)
    sys.exit(write_or_check(os.path.join(HERE, "tb.sv"), txt, check="--check" in sys.argv))
