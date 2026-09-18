#!/usr/bin/env python3
"""把 rtl/uncore/TLFIFOFixer.sv 的 REGION_MAP 与 golden a_id 全枚举表逐点核对。

表在这里写第二遍是故意的：它是**独立的核对件**，不从 RTL 解析。
RTL 改了而这里没改（或反过来），核对就会失败——这正是要的。
"""
import itertools, sys

# (base, care, domain) —— region key = {address[48], address[30:12]}
ENT = [
    (0x80000, 0x80000,  1),   # address[48]=1  TLError 错误设备
    (0x31100, 0xFFFF8, 10),   # 0x31100000 +32K  APLIC M domain
    (0x31108, 0xFFFF8,  0),   # 0x31108000 +32K  (保留洞, 无域)
    (0x31110, 0xFFFF0,  0),   # 0x31110000 +64K  (保留洞, 无域)
    (0x31120, 0xFFFF8, 10),   # 0x31120000 +32K  APLIC S domain
    (0x31128, 0xFFFF8,  0),   # 0x31128000 +32K  (保留洞, 无域)
    (0x31130, 0xFFFF0,  0),   # 0x31130000 +64K  (保留洞, 无域)
    (0x38000, 0xFFFF0,  7),   # 0x38000000 +64K  TIMERRange (CLINT)
    (0x38010, 0xFFFFF,  0),   # 0x38010000 +4K   BEURange (无域)
    (0x38020, 0xFFFFF,  4),   # 0x38020000 +4K   DebugModule
    (0x38021, 0xFFFFF,  9),   # 0x38021000 +4K   MMPMA (TLPMA)
    (0x38040, 0xFFFF0,  6),   # 0x38040000 +64K  SYSCNTRange
    (0x3A000, 0xFFFFF,  2),   # 0x3a000000 +4K   PLLRange
    (0x3A800, 0xFFFFF,  5),   # 0x3a800000 +4K   IMSIC mBaseAddr
    (0x3B000, 0xFFFF8,  5),   # 0x3b000000 +32K  IMSIC sgBaseAddr
    (0x3C000, 0xFC000,  8),   # 0x3c000000 +64M  PLICRange
]
DEFAULT = 3

def main(path):
    ok = True
    for (b1, c1, _), (b2, c2, _) in itertools.combinations(ENT, 2):
        common = c1 & c2
        if (b1 & common) == (b2 & common):
            print("OVERLAP: %05x/%05x vs %05x/%05x" % (b1, c1, b2, c2)); ok = False
    print("disjoint: %s" % ("OK" if ok else "FAIL"))

    golden = bytearray(1 << 20)
    for line in open(path):
        k, v = line.split()
        golden[int(k, 16)] = int(v, 16)

    bad = 0
    for k in range(1 << 20):
        model = DEFAULT
        for b, c, d in ENT:
            if (k & c) == b:
                model = d; break
        if model != golden[k]:
            bad += 1
            if bad <= 10:
                print("MISMATCH key=%05x golden=%d model=%d" % (k, golden[k], model))
    print("mismatches: %d / %d %s" % (bad, 1 << 20, "-> table is EXACT" if bad == 0 else ""))
    return 0 if (bad == 0 and ok) else 1

if __name__ == "__main__":
    sys.exit(main(sys.argv[1] if len(sys.argv) > 1 else "aid_table.txt"))
