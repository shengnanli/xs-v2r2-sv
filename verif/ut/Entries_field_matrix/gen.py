#!/usr/bin/env python3
"""字段矩阵的生成入口。

放成 gen.py 是为了让 scripts/test_gen_idempotent.py 自动把它纳进闸里
（那道闸的做法是：在 HEAD 的 detached worktree 里逐个跑 verif/ut/*/gen.py，
跑完 git status 必须干净）。这样矩阵一旦与 golden 实测漂了，下一轮必然变红，
不用额外改共享设施。

    python3 gen.py            # 重算矩阵
    python3 gen.py --check    # 只校验没漂移
"""
import pathlib, sys
sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
import gen_matrix                                                  # noqa: E402
sys.exit(gen_matrix.main())
