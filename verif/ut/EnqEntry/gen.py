#!/usr/bin/env python3
"""EnqEntry 的生成入口（薄壳）。真正的代码在共享库里，本族各变体共用一份代码路径。"""
import sys, pathlib
sys.path.insert(0, str(pathlib.Path(__file__).resolve().parents[1] / "EnqEntry_common"))
from enqentry_gen import main
sys.exit(main("EnqEntry"))
