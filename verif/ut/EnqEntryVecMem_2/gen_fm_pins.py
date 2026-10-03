#!/usr/bin/env python3
# 薄壳: 真正的代码在 verif/ut/EnqEntry_common/gen_fm_pins.py
import sys, pathlib
sys.path.insert(0, str(pathlib.Path(__file__).resolve().parents[1] / 'EnqEntry_common'))
from gen_fm_pins import main
sys.exit(main('EnqEntryVecMem_2'))
