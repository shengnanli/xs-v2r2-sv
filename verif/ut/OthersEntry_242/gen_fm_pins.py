#!/usr/bin/env python3
# 薄壳: 真正的代码在 verif/ut/OthersEntry_common/gen_fm_pins.py
import sys, pathlib
sys.path.insert(0, str(pathlib.Path(__file__).resolve().parents[1] / 'OthersEntry_common'))
from gen_fm_pins import main
sys.exit(main('OthersEntry_242'))
