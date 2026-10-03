#!/usr/bin/env python3
"""生成 MbistBitmapCache 的双例化 UT testbench（tb.sv，scripts/dual_tb_lib.py）。

golden vs MbistBitmapCache_xs，全部输出逐拍比较。激励：mbist_array 3/4 时间落在本节点的
4 个 id（0x28..0x2B）上、其余随机；mbist_all 1/8；req/readen/writeen 各约一半。

用法：python3 gen.py [--check]
"""
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, "..", "..", "..", "scripts"))
from dual_tb_lib import Pair, render, write_or_check  # noqa: E402

STIM = """
if ($urandom_range(0, 3) != 0) @mbist_array = 6'h28 + 6'($urandom_range(0, 3));
@mbist_all = ($urandom_range(0, 7) == 0);
"""

COV = [("all", "@mbist_all && @mbist_req"), ("reset_mid", "@reset && cyc > 100")]
for j in range(4):
    COV.append(("sel%d" % j, "@mbist_req && !@mbist_all && @mbist_array == 6'h%X && @mbist_writeen" % (0x28 + j)))
COV.append(("miss", "@mbist_req && !@mbist_all && (@mbist_array < 6'h28 || @mbist_array > 6'h2B)"))

PAIRS = [Pair("MbistBitmapCache", "m_", clocked=True, stim=STIM, cov=COV,
              reset_period=2000, cov_min=50)]

HEADER = """自动生成：verif/ut/MbistBitmapCache/gen.py（scripts/dual_tb_lib.py，读 G1 golden 端口表）—— 勿手改
MbistBitmapCache 双例化逐拍比对，全部输出逐位 !==。"""

if __name__ == "__main__":
    sys.exit(write_or_check(os.path.join(HERE, "tb.sv"), render(PAIRS, HEADER), "--check" in sys.argv))
