#!/usr/bin/env python3
"""生成 RegCache 的双例化 UT testbench（tb.sv）——取代原 scripts/gen_zj_ut.py 的一次性 tb。

golden RegCache vs 重写 RegCache_xs（scripts/dual_tb_lib.py，端口表读 G1 golden），每拍全部输出逐位 !==。
重写侧的 6 个子模块（RegCacheDataModule{,_1} / AgeTimer{,_1} / AgeDetector{,_1}）也是重写件
（经 derive 改名 _xs）；golden 侧全是 golden。

为什么换 tb（agent/rob-regcache，2026-10-03）：原 tb 只能跑 +vcs+initreg+0 一档——两个数据存储体
mem 不复位、读地址寄存器 in_addr 是 RegEnable，random 档两侧各摇各的初值，开机就"失配"。
九档验收需要比较窗口开在这些状态都被写定之后，所以：
  arm = Int / Mem 两个存储体的 validInfo 全 1（复位后每项都被写过一次；复位期间的写入
        地址来自尚未稳定的三级流水，但 v 在复位期间被清零，arm 只认复位后的写）
      + 23 个读口各至少 ren 过一次（in_addr 写定）。
reset_period=0：只打上电复位。中途复位会把 v 清零但不清 mem，arm 的"复位后每项都写过"
  就不再成立（golden 也一样，这是被测件本身的初值语义，不是重写的问题），所以 UT 不打中途复位；
  复位行为由 FM 覆盖。
激励：wen 1/2、ren 1/2、读地址 5 位全随机（bit4 选 Mem 半区；Mem 只有 12 项，12..15 越界读第 0 项，照比）。
用法：python3 gen.py [--check]
"""
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, "..", "..", "..", "scripts"))
from dual_tb_lib import Pair, render, write_or_check  # noqa: E402

G = "rc_u_gold."
ARM = (["&{%s}" % ", ".join(G + "IntRegCache.io_validInfo_%d" % k for k in range(16)),
        "&{%s}" % ", ".join(G + "MemRegCache.io_validInfo_%d" % k for k in range(12))]
       + ["@io_readPorts_%d_ren" % i for i in range(23)])
COV = [
    ("mem_half_read", "@io_readPorts_0_ren && @io_readPorts_0_addr[4]"),
    ("int_half_read", "@io_readPorts_0_ren && !@io_readPorts_0_addr[4]"),
    ("all_int_wen", "@io_writePorts_0_wen && @io_writePorts_1_wen && @io_writePorts_2_wen && @io_writePorts_3_wen"),
    ("all_mem_wen", "@io_writePorts_4_wen && @io_writePorts_5_wen && @io_writePorts_6_wen"),
]

PAIRS = [
    # io_toWakeupQueueRCIdx_N[4] 是半区选择位：Int 口(0..3)恒 0、Mem 口(4..6)恒 1（golden 同）
    Pair("RegCache", "rc_", clocked=True, cov=COV, arm=ARM, arm_delay=1, reset_period=0, cov_min=1000,
         exempt=["io_toWakeupQueueRCIdx_%d[4]" % i for i in range(7)]),
]

HEADER = """自动生成：verif/ut/RegCache/gen.py（scripts/dual_tb_lib.py，读 G1 golden 端口表）—— 勿手改
RegCache 双例化逐拍比对：golden RegCache vs 重写 RegCache_xs（子模块两侧各自 golden / 重写件），全部输出逐位 !==。"""

if __name__ == "__main__":
    txt = render(PAIRS, HEADER)
    sys.exit(write_or_check(os.path.join(HERE, "tb.sv"), txt, "--check" in sys.argv))
