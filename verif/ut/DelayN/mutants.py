#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""mutants.py —— DelayN 家族 UT 的判别力负测（`make mutants`）。

跑法全部复用 `scripts/mutant_harness.py`（四个小叶子家族共用那份），本文件只声明
配置与变异表。口径（无效变异体 / 逻辑等价空变异 / infra 桶的处理）见 harness 顶部。

## 这一轮为什么必须跑它

本轮给 tb 加了 **WARMUP 热身窗口**（开 `+vcs+initreg+random` 之后，前 11 拍只驱动
不比对）。热身窗口是**判据的放宽**——凡是放宽判据，就必须先自证「它仍然看得见真
bug」，否则 `errors=0` 只是"没在看"。M1 取错级、M6 延迟被短路这两条尤其是热身窗口
的守卫：如果热身写成"跳过一切"或窗口取得过大，它们立刻会变成 MISSED。

## 为什么本族没有「只在头几拍不同」的 bug 类别（说清边界，不要读成豁免）

DelayN 是**无复位**的定长移位链：两侧寄存器的上电初值互不相干，这正是热身窗口
扣掉的那一段（等价性在那里根本没有定义）。除初值之外的任何结构差异——级数、
取哪一级、链方向、首级来源、打包顺序——都是**永久性**的，冲多少拍都不会消失。
所以热身窗口能掩盖的只有"初值不同"这一类，而那一类在本族里不构成 bug
（golden 自己也没有复位）。这不是推论豁免：下面每一条结构变异都实跑过，
要求全部 CAUGHT。

## 变异表

核层（`xs_DelayN_core.sv`，一处变异同时打中 18 个变体）：
  M1 ★取错级★      输出取倒数第二级（对 STAGES>1 的 12 个变体可观测）
  M2 ★链方向反了★  stage[s-1] <= stage[s]
  M3 ★首级来源错★  第一级收末级（自环）而不是 d_in
  M4 ★链少一级★    最后一级永远不被写
  M5 ★0 级支路接地★ 退化变体 DelayN_225 的直连线被钉成 0
  M6 ★延迟被短路★  d_out 直接取 d_in，整条链形同虚设
薄文件层（`$bits` 端口契约不变式与 negtest **都抓不到**的那一类：
位宽不变、只是接错）：
  M7 DelayN_220 打包时把 io_in_bits_rs1 与 io_in_bits_rs2 对调（都是 1 位）
不变式层（期望**编译/elaborate 就被拦下**，与 `make negtest` 互补）：
  M8 DelayN_225 的 GOLDEN_HAS_CLOCK 抄成 1（级数与"端口表有无时钟"不相容）

★双向★ 只证"该报的报"不够：一个恒报警的 tb 也能让 M1..M8 全 CAUGHT。
所以另有两条**期望不报**的逻辑等价空变异（分子分母都不计，但必须跑、必须 errors=0）：
  E1 核里 `assign d_out = ...` 改写成 `always_comb d_out = ...`（同一个组合赋值）
  E2 移位循环改成倒序写（非阻塞赋值之间无顺序依赖，电路一模一样）

FM 侧负测（`python3 mutants.py --fm`，top=DelayN_7）：证明 UT 之外那道闸也真会红。

用法: python3 mutants.py            # UT 判别力
      python3 mutants.py --cov      # 覆盖闸自身的负测（20 拍必须判 FAILED）
      python3 mutants.py --fm       # FM 侧负测
      python3 mutants.py --compile-only
"""
import pathlib
import sys

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parents[3] / 'scripts'))
from mutant_harness import Cfg, run                       # noqa: E402

CORE = 'xs_DelayN_core.sv'
VARIANTS = ['DelayN.sv'] + ['DelayN_%d.sv' % n for n in
                            (1, 7, 8, 9, 13, 15, 17, 208, 214, 215,
                             220, 221, 225, 297, 331, 333, 334)]
FAMILY = [('common', f) for f in [CORE] + VARIANTS]

CHAIN_LOOP = ("        for (int unsigned s = 1; s < STAGES; s++)\n"
              "          stage[s] <= stage[s-1];")

MUTANTS = [
    ('CATCH', 'M1 ★取错级★ 输出取倒数第二级（热身窗口的守卫：它一旦太宽就会 MISSED）',
     "      assign d_out = stage[STAGES-1];",
     "      assign d_out = stage[STAGES > 1 ? STAGES-2 : 0];"),

    ('CATCH', 'M2 ★链方向反了★ stage[s-1] <= stage[s]',
     CHAIN_LOOP,
     "        for (int unsigned s = 1; s < STAGES; s++)\n"
     "          stage[s-1] <= stage[s];"),

    ('CATCH', 'M3 ★首级来源错★ 第一级收末级（自环）',
     "        stage[0] <= d_in;",
     "        stage[0] <= stage[STAGES-1];"),

    ('CATCH', 'M4 ★链少一级★ 最后一级永远不被写',
     CHAIN_LOOP,
     "        for (int unsigned s = 1; s < STAGES-1; s++)\n"
     "          stage[s] <= stage[s-1];"),

    ('CATCH', 'M5 ★0 级支路接地★ DelayN_225 的直连线被钉成 0',
     "      assign d_out = d_in;",
     "      assign d_out = '0;"),

    ('CATCH', 'M6 ★延迟被短路★ d_out 直接取 d_in（热身窗口的第二个守卫）',
     "      assign d_out = stage[STAGES-1];",
     "      assign d_out = d_in;"),

    ('CATCH', 'M7 _220 打包时 io_in_bits_rs1 与 io_in_bits_rs2 对调（都是 1 位，总位宽不变）',
     "  assign payload_in =\n"
     "    {io_in_valid, io_in_bits_rs1, io_in_bits_rs2, io_in_bits_addr, io_in_bits_id,",
     "  assign payload_in =\n"
     "    {io_in_valid, io_in_bits_rs2, io_in_bits_rs1, io_in_bits_addr, io_in_bits_id,",
     ('common', 'DelayN_220.sv')),

    ('COMPILE_FAIL', 'M8 _225 的 GOLDEN_HAS_CLOCK 抄成 1（级数与端口表有无时钟不相容）',
     "    .GOLDEN_HAS_CLOCK(0)",
     "    .GOLDEN_HAS_CLOCK(1)",
     ('common', 'DelayN_225.sv')),

    # ---- 双向：期望**不**报警的逻辑等价空变异 ----
    ('EQUIV', 'E1 核里 assign d_out 改写成 always_comb（同一个组合赋值）',
     "      assign d_out = stage[STAGES-1];",
     "      always_comb d_out = stage[STAGES-1];"),

    ('EQUIV', 'E2 移位循环改成倒序写（非阻塞赋值之间无顺序依赖，电路不变）',
     CHAIN_LOOP,
     "        for (int unsigned s = STAGES; s > 1; s--)\n"
     "          stage[s-1] <= stage[s-2];"),
]

# FM 侧：同样两条结构变异，要求 FM 也红（UT 与 FM 各自独立地看得见）。
FM_MUTANTS = [
    ('F1 ★取错级★ 输出取倒数第二级',
     "      assign d_out = stage[STAGES-1];",
     "      assign d_out = stage[STAGES > 1 ? STAGES-2 : 0];", True),
    ('F2 ★链方向反了★ stage[s-1] <= stage[s]',
     CHAIN_LOOP,
     "        for (int unsigned s = 1; s < STAGES; s++)\n"
     "          stage[s-1] <= stage[s];", True),
    ('F3 （等价空变异）assign 改 always_comb —— FM 必须仍然 SUCCEEDED',
     "      assign d_out = stage[STAGES-1];",
     "      always_comb d_out = stage[STAGES-1];", False),
]

CFG = Cfg(here=__file__, module='DelayN', rtl_subdir='common', mut_file=CORE,
          rtl_files=FAMILY, mutants=MUTANTS, fm_mutants=FM_MUTANTS,
          fm_top='DelayN_7', ncycles=20000)

if __name__ == '__main__':
    sys.exit(run(CFG))
