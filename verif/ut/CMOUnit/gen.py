#!/usr/bin/env python3
"""CMOUnit UT：刷新 tb.sv 里的两个 GENERATED 区（端口/双例化、逐位比较）。

端口表读 G1 golden；生成片段见 scripts/gen_missq.py 的 tb_ports / tb_compare。
用法：python3 gen.py          生成/刷新（内容不变不写，幂等）
      python3 gen.py --check  只比较，不一致则 rc=1
"""
import os, sys
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.normpath(os.path.join(HERE, "..", "..", "..", "scripts")))
from gen_missq import tb_main  # noqa: E402

if __name__ == "__main__":
    # A 通道 opcode 只可能是 CBOClean/Flush/Inval = 0xC/0xD/0xE，高两位恒为 1
    sys.exit(tb_main(os.path.join(HERE, "tb.sv"), "CMOUnit",
                     toggle_exempt={"io_req_chanA_bits_opcode": 0xC}))
