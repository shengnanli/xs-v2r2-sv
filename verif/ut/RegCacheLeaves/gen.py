#!/usr/bin/env python3
"""生成 RegCacheLeaves 的双例化 UT testbench（tb.sv）。

RegCache 的 6 个子模块（DataModule / AgeTimer / AgeDetector 各两个变体）各一对：
golden <名> vs 重写 <名>_xs（scripts/dual_tb_lib.py，端口表读 G1 golden），每拍全部输出逐位 !==。
  * DataModule：读口 ren 稀疏、地址全 4 位（_1 变体 12 项，地址 12..15 越界读第 0 项也照比）；
    写口 wen 1/3，地址按 mode 在"全随机 / 压到 0..3 制造多写口撞同项"之间切换。
    mem 不复位 ⇒ arm = 每项都被写过（tb 按 golden 写口记位图）。
  * AgeTimer：ren 稀疏（1/10，否则各项天天被读、计时器不涨），wen 1/5，validInfo 按 mode 偏置
    （全 1 / 随机 / 稀疏），让饱和停 3 与无效项回绕都出现。
  * AgeDetector：ageInfo 一半来自"随机全序"（按随机优先级生成一致矩阵，替换口能挑出唯一项），
    一半全随机（非全序，测 PriorityMux 的缺省 / 号小优先规则）。
用法：python3 gen.py [--check]
"""
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, "..", "..", "..", "scripts"))
from dual_tb_lib import Pair, render, write_or_check  # noqa: E402


def dm_pair(top, pfx, n, nr, nw):
    decls = ["logic [15:0] %swmask = '0;" % pfx, "always @(posedge clk) begin"]
    for w in range(nw):
        u = pfx + "u_gold.io_writePorts_%d_" % w     # 层次引用：decls 在端口信号声明之前
        bound = "" if n == 16 else " && %saddr < 4'd%d" % (u, n)   # 16 项时 4 位地址不会越界
        decls.append("  if (%swen%s) %swmask[%saddr] <= 1'b1;" % (u, bound, pfx, u))
    decls.append("end")
    stim = []
    for r in range(nr):
        stim.append("@io_readPorts_%d_ren = ($urandom_range(0, 3) == 0);" % r)
    for w in range(nw):
        stim.append("@io_writePorts_%d_wen = ($urandom_range(0, 2) == 0);" % w)
        stim.append("if (@mode %% 2 == 0) @io_writePorts_%d_addr = 4'($urandom_range(0, 3));" % w)
    cov = [("multi_write", "@io_writePorts_0_wen && @io_writePorts_1_wen && @io_writePorts_0_addr == @io_writePorts_1_addr"),
           ("oob_read", "@io_readPorts_0_addr >= 4'd%d" % n if n < 16 else "@io_readPorts_0_addr == 4'd15")]
    full = "(1 << %d) - 1" % n
    return Pair(top, pfx, clocked=True, stim="\n".join(stim), cov=cov, decls="\n".join(decls),
                arm=["%swmask == 16'(%s)" % (pfx, full)], mode_period=300, reset_period=50000, cov_min=50)


def at_pair(top, pfx, n, nr, nw):
    stim = []
    for r in range(nr):
        stim.append("@io_readPorts_%d_ren = ($urandom_range(0, 9) == 0);" % r)
    for w in range(nw):
        stim.append("@io_writePorts_%d_wen = ($urandom_range(0, 4) == 0);" % w)
    stim.append("case (@mode % 3)")
    stim.append("  0: {%s} = '1;" % ", ".join("@io_validInfo_%d" % k for k in range(n)))
    stim.append("  1: {%s} = %d'($urandom) & %d'($urandom);" % (", ".join("@io_validInfo_%d" % k for k in range(n)), n, n))
    stim.append("  default: ;")
    stim.append("endcase")
    g = pfx + "u_gold."
    cov = [("sat3", "%sageTimer_0 == 2'd3 && @io_validInfo_0" % g),
           ("wrap_invalid", "%sageTimer_1 == 2'd3 && !@io_validInfo_1" % g),
           ("cross_group_eq", "@io_validInfo_0 && @io_validInfo_%d && %sageTimer_0 == %sageTimer_%d" % (n - 1, g, g, n - 1))]
    return Pair(top, pfx, clocked=True, stim="\n".join(stim), cov=cov, mode_period=500,
                reset_period=40000, cov_min=50)


def ad_pair(top, pfx, n):
    decls = ["int unsigned %sprio [%d];" % (pfx, n)]
    stim = ["if (@mode % 2 == 0) begin",
            "  for (int k = 0; k < %d; k++) %sprio[k] = k;" % (n, pfx),
            "  %sprio.shuffle();" % pfx]
    for i in range(n):
        for j in range(i + 1, n):
            stim.append("  @io_ageInfo_%d_%d = (%sprio[%d] > %sprio[%d]);" % (i, j, pfx, i, pfx, j))
    stim.append("end")
    cov = [("pick_first", "@io_out_0 == 4'd0"), ("pick_last", "@io_out_0 == 4'd%d" % (n - 1))]
    return Pair(top, pfx, clocked=True, stim="\n".join(stim), cov=cov, decls="\n".join(decls),
                mode_period=200, reset_period=40000, cov_min=50)


PAIRS = [
    dm_pair("RegCacheDataModule", "rd0_", 16, 23, 4),
    dm_pair("RegCacheDataModule_1", "rd1_", 12, 23, 3),
    at_pair("RegCacheAgeTimer", "at0_", 16, 23, 4),
    at_pair("RegCacheAgeTimer_1", "at1_", 12, 23, 3),
    ad_pair("RegCacheAgeDetector", "ad0_", 16),
    ad_pair("RegCacheAgeDetector_1", "ad1_", 12),
]

HEADER = """自动生成：verif/ut/RegCacheLeaves/gen.py（scripts/dual_tb_lib.py，读 G1 golden 端口表）—— 勿手改
RegCache 六个子模块双例化逐拍比对：golden <名> vs 重写 <名>_xs，全部输出逐位 !==。"""

if __name__ == "__main__":
    txt = render(PAIRS, HEADER)
    sys.exit(write_or_check(os.path.join(HERE, "tb.sv"), txt, "--check" in sys.argv))
