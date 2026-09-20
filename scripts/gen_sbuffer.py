#!/usr/bin/env python3
"""gen_sbuffer.py —— 生成 rtl/memblock/Sbuffer.sv 里的机械派生区。

本模块手写区（package / xs_Sbuffer_core 的逻辑）不由本脚本触碰；脚本只原地替换
三个 `// BEGIN GENERATED(<tag>)` / `// END GENERATED` 区段：

  core_ports     —— xs_Sbuffer_core 的 golden 扁平端口表（从 G1 golden 逐字抽取）
  wrapper_ports  —— Sbuffer wrapper 的同一张表（末项不带逗号）
  core_inst      —— wrapper 里 xs_Sbuffer_core 的 1:1 端口透传
  fwd_flat       —— 核里 3 路 forward 输出拆回 golden 扁平端口
  datamodule_inst—— wrapper 里 SbufferData dataModule 的 2064 根引脚连线

为什么要生成：这三段合计 ~2900 行，全部是「golden 端口名 × 下标」的笛卡儿积，
手抄一定会错、也读不出信息量；真正要人读的是核里的微架构逻辑。

用法：python3 scripts/gen_sbuffer.py [--check]
  --check 只比对不写盘（gate 用），有差异返回 1。
"""
import argparse, os, re, sys

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.dirname(HERE)
GOLDEN = os.environ.get("GOLDEN_RTL", "/home/eda/xs-env/G1-canonical/golden-rtl")
TARGET = os.path.join(REPO, "rtl/memblock/Sbuffer.sv")

NLINE, NVWORD, NBYTE, ENSBUF = 16, 4, 16, 2


def golden_ports(path, top):
    """返回 [(dir, width_str, name)]，顺序与 golden 完全一致。"""
    txt = open(path).read()
    m = re.search(r"^module %s\(\n(.*?)^\);" % top, txt, re.S | re.M)
    if not m:
        sys.exit("找不到 module %s 的端口表" % top)
    out = []
    for ln in m.group(1).split("\n"):
        mm = re.match(r"\s*(input|output)\s+(?:wire\s+)?(\[[0-9]+:[0-9]+\]\s+)?([A-Za-z_]\w*)", ln)
        if mm:
            out.append((mm.group(1), (mm.group(2) or "").strip(), mm.group(3)))
    return out


def emit_golden_ports(ports, trailing_comma):
    """trailing_comma=True 时最后一项也带逗号（核端口表后面还接 dataModule 侧端口）。"""
    w = max(len(p[1]) for p in ports)
    lines = []
    for i, (d, bits, name) in enumerate(ports):
        comma = "," if (trailing_comma or i != len(ports) - 1) else ""
        lines.append("  %-6s %-*s %s%s" % (d, w, bits, name, comma))
    return lines


def emit_core_inst(ports):
    lines = ["  xs_Sbuffer_core u_core ("]
    body = []
    for d, bits, name in ports:
        body.append("    .%-40s (%s)" % (name, name))
    # 核额外的 dataModule 接口端口（packed，见核端口表）
    for name, net in [("dm_wr_valid", "dm_wr_valid"), ("dm_wr_wvec", "dm_wr_wvec"),
                      ("dm_wr_mask", "dm_wr_mask"), ("dm_wr_data", "dm_wr_data"),
                      ("dm_wr_vwoff", "dm_wr_vwoff"), ("dm_wr_wline", "dm_wr_wline"),
                      ("dm_flush_valid", "dm_flush_valid"), ("dm_flush_wvec", "dm_flush_wvec"),
                      ("dm_data_out", "dm_data_out"), ("dm_mask_out", "dm_mask_out")]:
        body.append("    .%-40s (%s)" % (name, net))
    lines.append(",\n".join(body))
    lines.append("  );")
    return lines


def emit_datamodule_inst():
    """golden 的 SbufferData 实例引脚顺序：writeReq×2 / maskFlushReq×1 / dataOut / maskOut。"""
    L = ["  SbufferData dataModule ("]
    b = ["    .%-34s (%s)" % ("clock", "clock"), "    .%-34s (%s)" % ("reset", "reset")]
    for p in range(ENSBUF):
        b.append("    .%-34s (%s)" % ("io_writeReq_%d_valid" % p, "dm_wr_valid[%d]" % p))
        b.append("    .%-34s (%s)" % ("io_writeReq_%d_bits_wvec" % p, "dm_wr_wvec[%d]" % p))
        b.append("    .%-34s (%s)" % ("io_writeReq_%d_bits_mask" % p, "dm_wr_mask[%d]" % p))
        b.append("    .%-34s (%s)" % ("io_writeReq_%d_bits_data" % p, "dm_wr_data[%d]" % p))
        b.append("    .%-34s (%s)" % ("io_writeReq_%d_bits_vwordOffset" % p, "dm_wr_vwoff[%d]" % p))
        b.append("    .%-34s (%s)" % ("io_writeReq_%d_bits_wline" % p, "dm_wr_wline[%d]" % p))
    b.append("    .%-34s (%s)" % ("io_maskFlushReq_0_valid", "dm_flush_valid[0]"))
    b.append("    .%-34s (%s)" % ("io_maskFlushReq_0_bits_wvec", "dm_flush_wvec[0]"))
    for e in range(NLINE):
        for w in range(NVWORD):
            for by in range(NBYTE):
                b.append("    .%-34s (%s)" % ("io_dataOut_%d_%d_%d" % (e, w, by),
                                              "dm_data_out[%d][%d][%d]" % (e, w, by)))
    for e in range(NLINE):
        for w in range(NVWORD):
            for by in range(NBYTE):
                b.append("    .%-34s (%s)" % ("io_maskOut_%d_%d_%d" % (e, w, by),
                                              "dm_mask_out[%d][%d][%d]" % (e, w, by)))
    L.append(",\n".join(b))
    L.append("  );")
    return L


def emit_fwd_flat():
    """3 路 forward 的 16 位掩码 + 16 字节数据 + matchInvalid 拆回 golden 扁平端口。"""
    L = []
    for f in range(3):
        for b in range(NBYTE):
            L.append("  assign io_forward_%d_forwardMask_%-2d = fwd_o_mask[%d][%d];" % (f, b, f, b))
        for b in range(NBYTE):
            L.append("  assign io_forward_%d_forwardData_%-2d = fwd_o_data[%d][%d];" % (f, b, f, b))
        L.append("  assign io_forward_%d_matchInvalid    = fwd_mismatch[%d];" % (f, f))
    return L


def splice(txt, tag, lines):
    beg = "// BEGIN GENERATED(%s)" % tag
    end = "// END GENERATED(%s)" % tag
    m = re.search(re.escape(beg) + r".*?" + re.escape(end), txt, re.S)
    if not m:
        sys.exit("目标文件里找不到 %s 区段" % tag)
    return txt[:m.start()] + beg + "\n" + "\n".join(lines) + "\n  " + end + txt[m.end():]


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--check", action="store_true")
    a = ap.parse_args()
    ports = golden_ports(os.path.join(GOLDEN, "Sbuffer.sv"), "Sbuffer")
    txt = open(TARGET).read()
    txt = splice(txt, "core_ports", emit_golden_ports(ports, True))
    txt = splice(txt, "wrapper_ports", emit_golden_ports(ports, False))
    txt = splice(txt, "core_inst", emit_core_inst(ports))
    txt = splice(txt, "fwd_flat", emit_fwd_flat())
    txt = splice(txt, "datamodule_inst", emit_datamodule_inst())
    old = open(TARGET).read()
    if a.check:
        if old != txt:
            print("gen_sbuffer: 生成区与磁盘不一致（请重跑生成器）", file=sys.stderr)
            return 1
        print("gen_sbuffer: 生成区一致 (%d ports)" % len(ports))
        return 0
    if old != txt:
        open(TARGET, "w").write(txt)
    print("gen_sbuffer: ok, %d golden ports" % len(ports))
    return 0


if __name__ == "__main__":
    sys.exit(main())
