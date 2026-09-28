#!/usr/bin/env python3
"""gen_lqraw.py —— LoadQueueRAW 簇（LqMaskModule / LqPAddrModule_1）的机械派生区生成器。

生成对象（都是"没有微架构"的纯机械部分）：
  rtl/memblock/LqMaskModule.sv      整个文件（薄 wrapper：golden 端口表 + 例化共用核
  rtl/memblock/LqPAddrModule_1.sv   xs_LqRawDataCam_core + 输出展平）

端口表逐字取自 G1 golden 同名模块（顺序/名字/位宽全同），生成时三项机械核对：
  (1) golden 端口集合 == 预期形状（wen/waddr/wdata ×3、violationMdata ×2、
      [violationCheckLine ×2]、violationMmask 2×32，外加 clock/reset），多一个少一个都报错；
  (2) 位宽与核参数一致（DATA_W / ADDR_W）；
  (3) 生成结果与磁盘逐字节比较（--check）。

用法:
  scripts/gen_lqraw.py            # 写文件
  scripts/gen_lqraw.py --check    # 只比对，不写；有漂移 rc=1（gate 用）
"""
import argparse
import os
import re
import sys

GOLDEN_DIR = "/home/eda/xs-env/G1-canonical/golden-rtl"
HERE = os.path.dirname(os.path.abspath(__file__))
RTL = os.path.normpath(os.path.join(HERE, "..", "rtl", "memblock"))

NUM_WRITE = 3
NUM_CAM = 2
NUM_ENTRIES = 32
ADDR_W = 5


def port_table(module):
    """golden 顶层端口表：[(dir, width, name, 原文行)]，顺序即 golden 顺序。"""
    path = os.path.join(GOLDEN_DIR, module + ".sv")
    lines = open(path).read().split("\n")
    start = next(i for i, l in enumerate(lines) if l.startswith("module %s(" % module))
    end = start
    while not lines[end].startswith(");"):
        end += 1
    out = []
    pat = re.compile(r"\s*(input|output)\s+(?:\[(\d+):(\d+)\]\s*)?([A-Za-z_]\w*)\s*,?\s*$")
    for l in lines[start + 1:end]:
        m = pat.match(l)
        if not m:
            raise SystemExit("gen_lqraw: 端口行解析失败: %r" % l)
        w = int(m.group(2)) - int(m.group(3)) + 1 if m.group(2) else 1
        out.append((m.group(1), w, m.group(4), l.rstrip(",").rstrip()))
    return out


def expected_ports(data_w, line_cam):
    exp = [("input", 1, "clock"), ("input", 1, "reset")]
    exp += [("input", 1, "io_wen_%d" % w) for w in range(NUM_WRITE)]
    exp += [("input", ADDR_W, "io_waddr_%d" % w) for w in range(NUM_WRITE)]
    exp += [("input", data_w, "io_wdata_%d" % w) for w in range(NUM_WRITE)]
    exp += [("input", data_w, "io_violationMdata_%d" % c) for c in range(NUM_CAM)]
    if line_cam:
        exp += [("input", 1, "io_violationCheckLine_%d" % c) for c in range(NUM_CAM)]
    exp += [("output", 1, "io_violationMmask_%d_%d" % (c, j))
            for c in range(NUM_CAM) for j in range(NUM_ENTRIES)]
    return exp


CAM_FAMILY = [
    # (模块, DATA_W, LINE_CAM, 一句话, 写数据延迟件)
    ("LqMaskModule", 16, False,
     "LoadQueueRAW 的字节掩码 CAM 阵列（32 项 × 16 位）", "DelayNWithValid_103"),
    ("LqPAddrModule_1", 24, True,
     "LoadQueueRAW 的部分物理地址 CAM 阵列（32 项 × 24 位 = paddr[27:4]）",
     "DelayNWithValid_55"),
]


def gen_cam_wrapper(module, data_w, line_cam, brief, wdelay):
    ports = port_table(module)
    got = [(d, w, n) for d, w, n, _ in ports]
    exp = expected_ports(data_w, line_cam)
    if got != exp:
        gs, es = set(got), set(exp)
        raise SystemExit("gen_lqraw: %s golden 端口表与预期形状不符\n  多: %s\n  少: %s\n  (或顺序不同)"
                         % (module, sorted(gs - es)[:8], sorted(es - gs)[:8]))

    o = []
    o.append("// " + "=" * 77)
    o.append("// %s —— %s" % (module, brief))
    o.append("//")
    o.append("// 薄 wrapper：逻辑全部在共用核 xs_LqRawDataCam_core（同目录 xs_LqRawDataCam_core.sv）。")
    o.append("// 本变体：DATA_W=%d，LINE_CAM=%d（%s），写数据延迟件 = %s。"
             % (data_w, int(line_cam),
                "地址 CAM，带 cacheline 整行检查" if line_cam else "字节掩码交叠 CAM",
                wdelay))
    o.append("// 本层只做端口展平/改名：golden 的扁平 io_* 名 <-> 核的按口号成组的数组端口。")
    o.append("// reset 在综合视图里没有负载：golden 只在 `ifndef SYNTHESIS 的写冲突断言里用它")
    o.append("// （assert(!(wen(i) && wen(j) && waddr(i)===waddr(j)))），所有寄存器都不复位。")
    o.append("// 端口表逐字抄自 G1 golden 同名模块。自动生成：scripts/gen_lqraw.py —— 勿手改")
    o.append("// " + "=" * 77)
    o.append("")
    o.append("module %s(" % module)
    for i, (_, _, _, raw) in enumerate(ports):
        o.append(raw + ("," if i + 1 < len(ports) else ""))
    o.append(");")
    o.append("  logic [%d:0] waddr [%d];" % (ADDR_W - 1, NUM_WRITE))
    o.append("  logic [%d:0] wdata [%d];" % (data_w - 1, NUM_WRITE))
    o.append("  logic [%d:0] mdata [%d];" % (data_w - 1, NUM_CAM))
    o.append("  logic [%d:0] mmask [%d];" % (NUM_ENTRIES - 1, NUM_CAM))
    o.append("")
    for w in range(NUM_WRITE):
        o.append("  assign waddr[%d] = io_waddr_%d;" % (w, w))
    for w in range(NUM_WRITE):
        o.append("  assign wdata[%d] = io_wdata_%d;" % (w, w))
    for c in range(NUM_CAM):
        o.append("  assign mdata[%d] = io_violationMdata_%d;" % (c, c))
    o.append("")
    o.append("  xs_LqRawDataCam_core #(")
    o.append("    .NUM_ENTRIES (%d)," % NUM_ENTRIES)
    o.append("    .DATA_W      (%d)," % data_w)
    o.append("    .NUM_WRITE   (%d)," % NUM_WRITE)
    o.append("    .NUM_WBANK   (8),")
    o.append("    .NUM_CAM     (%d)," % NUM_CAM)
    o.append("    .LINE_CAM    (1'b%d)" % int(line_cam))
    o.append("  ) u_core (")
    o.append("    .clock                 (clock),")
    o.append("    .io_wen                ({%s})," % ", ".join("io_wen_%d" % w for w in reversed(range(NUM_WRITE))))
    o.append("    .io_waddr              (waddr),")
    o.append("    .io_wdata              (wdata),")
    o.append("    .io_violationMdata     (mdata),")
    if line_cam:
        o.append("    .io_violationCheckLine ({%s}),"
                 % ", ".join("io_violationCheckLine_%d" % c for c in reversed(range(NUM_CAM))))
    else:
        o.append("    .io_violationCheckLine (%d'b0),  // 掩码 CAM 不看整行标志" % NUM_CAM)
    o.append("    .io_violationMmask     (mmask)")
    o.append("  );")
    o.append("")
    for c in range(NUM_CAM):
        for j in range(NUM_ENTRIES):
            o.append("  assign io_violationMmask_%d_%d = mmask[%d][%d];" % (c, j, c, j))
    o.append("endmodule")
    return "\n".join(o) + "\n"


def targets():
    out = {}
    for module, dw, lc, brief, wd in CAM_FAMILY:
        out[os.path.join(RTL, module + ".sv")] = gen_cam_wrapper(module, dw, lc, brief, wd)
    return out


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--check", action="store_true", help="只比对不写，有漂移 rc=1")
    args = ap.parse_args()
    drift = 0
    for path, text in targets().items():
        cur = open(path).read() if os.path.exists(path) else None
        if cur == text:
            print("gen_lqraw: OK     %s" % os.path.relpath(path))
            continue
        if args.check:
            print("gen_lqraw: DRIFT  %s" % os.path.relpath(path))
            drift += 1
        else:
            with open(path, "w") as f:
                f.write(text)
            print("gen_lqraw: WROTE  %s" % os.path.relpath(path))
    return 1 if drift else 0


if __name__ == "__main__":
    sys.exit(main())
