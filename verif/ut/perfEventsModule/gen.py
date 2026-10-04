#!/usr/bin/env python3
"""生成 perfEventsModule 的双例化 UT testbench（tb.sv，scripts/dual_tb_lib.py）。

golden perfEventsModule vs perfEventsModule_xs，rdata 逐拍逐位比较。
激励：w_wen 约 1/3；三个 OPTYPE 字段各自独立地一半取合法值（0/1/2/4）、一半取 5 位随机（多为非法）
⇒ "合法写入"与"非法写入保持原值"两条路都大量出现，且同一次写里合法/非法字段混搭。

用法：python3 gen.py [--check]
"""
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, "..", "..", "..", "scripts"))
from dual_tb_lib import Pair, render, write_or_check  # noqa: E402

DECLS = """
function automatic logic [4:0] pick_op();
  case ($urandom_range(0, 7))
    0: return 5'd0;
    1: return 5'd1;
    2: return 5'd2;
    3: return 5'd4;
    default: return 5'($urandom);
  endcase
endfunction
"""

STIM = """
@w_wen = ($urandom_range(0, 2) == 0);
@w_wdata[54:50] = pick_op();
@w_wdata[49:45] = pick_op();
@w_wdata[44:40] = pick_op();
"""


def legal(hi, lo):
    f = "@w_wdata[%d:%d]" % (hi, lo)
    return "(%s == 5'd0 || %s == 5'd1 || %s == 5'd2 || %s == 5'd4)" % (f, f, f, f)


COV = [("write", "@w_wen")]
for i, (hi, lo) in enumerate(((54, 50), (49, 45), (44, 40))):
    COV.append(("op%d_legal" % (2 - i), "@w_wen && " + legal(hi, lo)))
    COV.append(("op%d_illegal" % (2 - i), "@w_wen && !" + legal(hi, lo)))
COV.append(("reset_mid", "@reset && cyc > 100"))

PAIRS = [Pair("perfEventsModule", "e_", clocked=True, stim=STIM, cov=COV, decls=DECLS,
              reset_period=2000, cov_min=50,
              # [57:55] 是保留位，恒读 0；OPTYPE 合法值只有 0/1/2/4，每个字段的高 2 位
              # （[44:43] / [49:48] / [54:53]）结构上永远为 0（WARL 拦下了所有能让它们变 1 的写）
              exempt=["rdata[%d]" % b for b in (55, 56, 57, 43, 44, 48, 49, 53, 54)])]

HEADER = """自动生成：verif/ut/perfEventsModule/gen.py（scripts/dual_tb_lib.py，读 G1 golden 端口表）—— 勿手改
perfEventsModule 双例化逐拍比对，全部输出逐位 !==。"""

if __name__ == "__main__":
    sys.exit(write_or_check(os.path.join(HERE, "tb.sv"), render(PAIRS, HEADER), "--check" in sys.argv))
