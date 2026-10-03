#!/usr/bin/env python3
"""MissQueue UT：刷新 tb.sv 里的两个 GENERATED 区（端口/双例化、逐位比较）。

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
    #   A.param 最高位恒 0（grow 参数 2 位）；A.size 只有 0/6 —— bit0 恒 0；
    #   A.source 最大 17（CMO）—— bit5 恒 0；A.reqSource ∈ {0,2,3,4,6} —— bit4、bit3 恒 0；
    #   MainPipe 回填请求的行地址低 6 位恒 0；refill_info.store_mask 每个表项都恒为全 1、
    #   且 s2_miss_id 总能选中一个表项 ⇒ 64 位恒 1；io_perf_*_value 高 5 位恒 0；
    #   difftest bore：addr 零扩展的高 16 位、行内 32B 对齐的低 5 位、mask=FF、coreid 高 2 位、index=1 恒定。
    bore = 0
    for b in list(range(584, 600)) + list(range(536, 541)) + list(range(16, 24)) + [14, 15] + list(range(0, 8)):
        bore |= 1 << b
    ex = {"io_mem_acquire_bits_param": 0x4, "io_mem_acquire_bits_size": 0x1,
          "io_mem_acquire_bits_source": 0x20, "io_mem_acquire_bits_user_reqSource": 0x18,
          "io_main_pipe_req_bits_addr": 0x3F, "io_refill_info_bits_store_mask": (1 << 64) - 1,
          "gatewayIn_packed_41_bore": bore}
    for k in range(5):
        ex["io_perf_%d_value" % k] = 0x3E
    sys.exit(tb_main(os.path.join(HERE, "tb.sv"), "MissQueue", toggle_exempt=ex))
