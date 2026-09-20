#!/usr/bin/env python3
"""EntriesVfmaVialuFixVimacVppuVfaluVfcvtVipuVsetrvfwvf 的生成入口 —— 逻辑全在共享库里。

    python3 gen.py            # 生成
    python3 gen.py --check    # 只校验已提交产物没漂移（非零退出=漂移）

家族 14 个变体共用 verif/ut/Entries_common/entries_gen.py 一份代码路径：
变体之间的差异一律是"从 golden 量出来的参数"，不是在生成产物上手改
（手改会被下一次跑生成器静默删掉，本轮已踩过两次）。
"""
import pathlib, sys
sys.path.insert(0, str(pathlib.Path(__file__).resolve().parents[1] / 'Entries_common'))
from entries_gen import main                                      # noqa: E402
sys.exit(main('EntriesVfmaVialuFixVimacVppuVfaluVfcvtVipuVsetrvfwvf'))
