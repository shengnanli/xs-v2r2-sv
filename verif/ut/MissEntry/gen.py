#!/usr/bin/env python3
"""MissEntry UT：刷新 tb.sv 里的两个 GENERATED 区（端口/双例化、逐位比较）。

端口表读 G1 golden；生成片段见 scripts/gen_missq.py 的 tb_ports / tb_compare。
用法：python3 gen.py          生成/刷新（内容不变不写，幂等）
      python3 gen.py --check  只比较，不一致则 rc=1
"""
import os, sys
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.normpath(os.path.join(HERE, "..", "..", "..", "scripts")))
from gen_missq import tb_main  # noqa: E402

if __name__ == "__main__":
    # 结构上恒定的输出位（仍逐位比较，只豁免 toggle 覆盖）：
    #   A.opcode 只有 AcquireBlock=6 / AcquirePerm=7：[3:1] 恒为 011；
    #   A.param 最高位恒 0（grow 参数只有 2 位）；A.source 高两位恒 0（MSHR 号 4 位）；
    #   A.reqSource ∈ {2,3,4,6}：bit4、bit3 恒 0；
    #   各处的行地址（A.address / main_pipe_req.addr / forwardInfo.paddr）低 6 位恒 0；
    #   refill_to_ldq.addr = 行地址 + 半行偏移 32，低 5 位恒 0。
    sys.exit(tb_main(os.path.join(HERE, "tb.sv"), "MissEntry",
                     toggle_exempt={"io_mem_acquire_bits_opcode": 0xE,
                                    "io_mem_acquire_bits_param": 0x4,
                                    "io_mem_acquire_bits_source": 0x30,
                                    "io_mem_acquire_bits_user_reqSource": 0x18,
                                    "io_mem_acquire_bits_address": 0x3F,
                                    "io_main_pipe_req_bits_addr": 0x3F,
                                    "io_forwardInfo_paddr": 0x3F,
                                    "io_refill_to_ldq_bits_addr": 0x1F}))
