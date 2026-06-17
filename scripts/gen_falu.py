#!/usr/bin/env python3
"""FAlu 生成入口：见 scripts/gen_fpfu.py（浮点 FU 通用生成器）。
设计意图来自 src/main/scala/xiangshan/backend/fu/wrapper/FAlu.scala。"""
import gen_fpfu
gen_fpfu.build("FAlu", "xs_FAlu_core", latency=0)

if __name__ == "__main__":
    pass
