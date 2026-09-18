#!/usr/bin/env python3
"""EntriesVfdivVidiv 的 FM 钉点生成入口 —— 逻辑全在 verif/ut/Entries_common/gen_fm_pins.py。"""
import pathlib, sys
sys.path.insert(0, str(pathlib.Path(__file__).resolve().parents[1] / 'Entries_common'))
from gen_fm_pins import main                                       # noqa: E402
sys.exit(main('EntriesVfdivVidiv'))
