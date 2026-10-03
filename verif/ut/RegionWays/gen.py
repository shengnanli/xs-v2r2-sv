#!/usr/bin/env python3
"""生成 RegionWays 的双例化 UT testbench（tb.sv）。

golden RegionWays vs 重写 RegionWays_xs（scripts/dual_tb_lib.py，端口表读 G1 golden），逐拍比全部输出。
激励要点：write_region / update_region 从 24 项小池子取（比表容量 16 大一些：表会被填满、PLRU 替换会发生，
  已有项又常被再次写中）；write_valid 按阶段 1/8 ~ 7/8；update_region 有 1/4 概率直接取本拍的
  write_region（旁路路径）；读指针全随机。复位每 ~2000 拍一次（表从空开始重新填）。
覆盖（golden 内部语义信号）：写命中 / 写未满取空项 / 写满走 PLRU 替换 / 更新口旁路 / 更新口表内命中。

用法：python3 gen.py [--check]
"""
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, "..", "..", "..", "scripts"))
from dual_tb_lib import Pair, render, write_or_check  # noqa: E402

DECLS = """
logic [29:0] r_pool [24];
initial for (int k = 0; k < 24; k++) r_pool[k] = 30'($urandom);
"""
STIM = """
@io_write_valid = ($urandom_range(0, 7) < (r_mode % 7) + 1);
@io_write_region = r_pool[$urandom_range(0, 23)];
@io_update_region_0 = ($urandom_range(0, 3) == 0) ? @io_write_region : r_pool[$urandom_range(0, 23)];
@io_update_region_1 = ($urandom_range(0, 3) == 0) ? @io_write_region : r_pool[$urandom_range(0, 23)];
"""
g = "r_u_gold"
pair = Pair("RegionWays", "r_", clocked=True, reset_period=2000, stim=STIM, decls=DECLS,
            mode_period=1000,
            cov=[("write_hit", "@io_write_valid && %s.w_hit" % g),
                 ("write_fill_free", "@io_write_valid && !%s.w_hit && !%s.valid" % (g, g)),
                 ("write_plru_replace", "@io_write_valid && !%s.w_hit && %s.valid" % (g, g)),
                 ("update_bypass", "%s.u_bypass || %s.u_bypass_1" % (g, g)),
                 ("update_table_hit", "(@io_update_hit_0 && !%s.u_bypass) || (@io_update_hit_1 && !%s.u_bypass_1)" % (g, g))])
txt = render([pair], header=__doc__.split("用法")[0].strip())
sys.exit(write_or_check(os.path.join(HERE, "tb.sv"), txt, check="--check" in sys.argv))
