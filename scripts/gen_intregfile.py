#!/usr/bin/env python3
"""gen_intregfile.py —— IntRegFilePart0..3（整数物理寄存器堆 4 个 16 位切片）的机械派生区生成器。

生成对象（都是"没有微架构"的纯机械部分；可读核 rtl/backend/xs_IntRegFilePart_core.sv 手写，本脚本不碰）：
  rtl/backend/IntRegFilePart{0,1,2,3}.sv   整个文件（薄 wrapper：golden 端口表逐字 + 例化共用核）
  verif/ut/IntRegFilePart/fm_pins_pre.tcl   FM「匹配前」钉点（golden 扁平寄存器 -> 核内数组元素，逐位）
  verif/ut/IntRegFilePart/tb.sv             GENERATED(intrf-duts) 区：4 对 golden/_xs 双例化接线

生成前对 G1 golden 做机械核对，任何一条不符即失败（fail-closed，不生成任何东西）：
  (1) 四个 golden 文件逐行比较，唯一差异是 `module IntRegFilePart<N>(` 那一行
      —— 这就是"四个变体只差名字"的证据，写进 wrapper 文件头；
  (2) 端口表 == 预期形状（clock/reset、11 读口 addr/data、8 写口 wen/addr/data、
      debug_all_rdata_1..223），顺序、方向、位宽逐项相等，多一个少一个都报错；
  (3) 寄存器表 == {mem_1..mem_223 [15:0]} ∪ {io_readPorts_<r>_data_REG [7:0], r=0..10}，一个不多一个不少；
  (4) 写口是 Mux1H 按位或（每行 1 个首项 + 7 个 `| (wenOH_* ? data : 0)` 项），不是优先级 mux；
      每行命中比较的常数恰好等于行号；
  (5) 读口 = `_GEN_0[io_readPorts_<r>_data_REG]`，读视图高 32 项（224..255）是常零，第 0 项常零；
      debug_all_rdata_<i> = mem_<i>。
  (6) --check：生成结果与磁盘逐字节比较，有漂移 rc=1（gate 用）。

用法:
  scripts/gen_intregfile.py            # 写文件
  scripts/gen_intregfile.py --check    # 只比对，不写
"""
import argparse
import os
import re
import sys

GOLDEN_DIR = "/home/eda/xs-env/G1-canonical/golden-rtl"
HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.normpath(os.path.join(HERE, ".."))
RTL = os.path.join(REPO, "rtl", "backend")
UT = os.path.join(REPO, "verif", "ut", "IntRegFilePart")

VARIANTS = ["IntRegFilePart0", "IntRegFilePart1", "IntRegFilePart2", "IntRegFilePart3"]
NUM_PREGS = 224
NUM_READ = 11
NUM_WRITE = 8
DATA_W = 16
ADDR_W = 8
NUM_ROWS = 1 << ADDR_W


def die(msg):
    raise SystemExit("gen_intregfile: " + msg)


def read_golden(mod):
    with open(os.path.join(GOLDEN_DIR, mod + ".sv")) as f:
        return f.read().split("\n")


# ----------------------------------------------------------------------------- (1)
def check_variants_identical():
    base = read_golden(VARIANTS[0])
    for v in VARIANTS[1:]:
        other = read_golden(v)
        if len(other) != len(base):
            die("%s 行数 %d != %s 行数 %d" % (v, len(other), VARIANTS[0], len(base)))
        diffs = [i for i, (a, b) in enumerate(zip(base, other)) if a != b]
        if len(diffs) != 1:
            die("%s 与 %s 有 %d 行不同（预期恰好 1 行：模块名）" % (v, VARIANTS[0], len(diffs)))
        i = diffs[0]
        if base[i] != "module %s(" % VARIANTS[0] or other[i] != "module %s(" % v:
            die("%s 的唯一差异行不是模块名: %r / %r" % (v, base[i], other[i]))
    return base


# ----------------------------------------------------------------------------- (2)
def port_table(lines, mod):
    start = next(i for i, l in enumerate(lines) if l == "module %s(" % mod)
    end = start
    while not lines[end].startswith(");"):
        end += 1
    pat = re.compile(r"\s*(input|output)\s+(?:\[(\d+):(\d+)\]\s*)?([A-Za-z_]\w*)\s*,?\s*$")
    out = []
    for l in lines[start + 1:end]:
        m = pat.match(l)
        if not m:
            die("端口行解析失败: %r" % l)
        w = int(m.group(2)) - int(m.group(3)) + 1 if m.group(2) else 1
        out.append((m.group(1), w, m.group(4), l.rstrip(",").rstrip()))
    return out, end


def expected_ports():
    exp = [("input", 1, "clock"), ("input", 1, "reset")]
    for r in range(NUM_READ):
        exp += [("input", ADDR_W, "io_readPorts_%d_addr" % r),
                ("output", DATA_W, "io_readPorts_%d_data" % r)]
    for w in range(NUM_WRITE):
        exp += [("input", 1, "io_writePorts_%d_wen" % w),
                ("input", ADDR_W, "io_writePorts_%d_addr" % w),
                ("input", DATA_W, "io_writePorts_%d_data" % w)]
    for i in range(1, NUM_PREGS):
        exp += [("output", DATA_W, "io_debug_all_rdata_%d" % i)]
    return exp


# ----------------------------------------------------------------------------- (3)(4)(5)
def check_body(lines, body_start):
    body = "\n".join(lines[body_start:])

    regs = re.findall(r"^\s*reg\s+(?:\[(\d+):0\]\s+)?(\w+);", body, re.M)
    got = sorted((n, int(h) + 1 if h else 1) for h, n in regs)
    want = sorted([("mem_%d" % i, DATA_W) for i in range(1, NUM_PREGS)] +
                  [("io_readPorts_%d_data_REG" % r, ADDR_W) for r in range(NUM_READ)])
    if got != want:
        die("寄存器表与预期不符：多 %s / 少 %s" % (sorted(set(got) - set(want))[:5],
                                              sorted(set(want) - set(got))[:5]))

    # 命中比较：wenOH[_<k>]_<w> = io_writePorts_<w>_wen & io_writePorts_<w>_addr == 8'h<row>
    hits = re.findall(r"wire\s+(wenOH(?:_(\d+))?_(\d+))\s*=\s*io_writePorts_(\d+)_wen\s*&\s*"
                      r"io_writePorts_(\d+)_addr\s*==\s*8'h([0-9A-F]+);", body)
    if len(hits) != (NUM_PREGS - 1) * NUM_WRITE:
        die("wenOH 命中线 %d 条，预期 %d" % (len(hits), (NUM_PREGS - 1) * NUM_WRITE))
    for name, k, w, w1, w2, hexrow in hits:
        row = (int(k) + 1) if k else 1
        if not (w == w1 == w2) or int(hexrow, 16) != row:
            die("命中线 %s 的写口/行号不自洽（row=%d, const=%s）" % (name, row, hexrow))

    # Mux1H：每行写数据 = 首项 + 7 个 `| (wenOH.. ? io_writePorts_w_data : 16'h0)`
    first = re.findall(r"^\s+\(wenOH\w* \? io_writePorts_0_data : 16'h0\)$", body, re.M)
    ors = re.findall(r"^\s+\| \(wenOH\w* \? io_writePorts_([1-7])_data : 16'h0\)[;]?$", body, re.M)
    if len(first) != NUM_PREGS - 1 or len(ors) != (NUM_PREGS - 1) * (NUM_WRITE - 1):
        die("写数据不是预期的 Mux1H 按位或形状（首项 %d / 或项 %d）" % (len(first), len(ors)))
    if re.search(r"wenOH\w*\s*\?\s*io_writePorts_\d+_data\s*:\s*\(", body):
        die("发现嵌套三目（优先级 mux）形状，与按位或假设不符")

    # 读视图：_GEN 是 32 项常零，_GEN_0 = {_GEN, {mem_223..mem_1, 16'h0}}
    m = re.search(r"wire \[31:0\]\[15:0\]\s+_GEN =\s*'\{((?:\s*16'h0,?)+)\};", body)
    if not m or m.group(1).count("16'h0") != NUM_ROWS - NUM_PREGS:
        die("读视图高位补零段不是 %d 个 16'h0" % (NUM_ROWS - NUM_PREGS))
    m = re.search(r"wire \[255:0\]\[15:0\] _GEN_0 =\s*\{_GEN,\s*\{((?:\s*\{[^{}]+\},?)+)\}\};", body)
    if not m:
        die("找不到 _GEN_0 读视图")
    elems = re.findall(r"\{([^{}]+)\}", m.group(1))
    if [e.strip() for e in elems] != ["mem_%d" % i for i in range(NUM_PREGS - 1, 0, -1)] + ["16'h0"]:
        die("_GEN_0 低 224 项不是 {mem_223..mem_1, 0}")
    for r in range(NUM_READ):
        if ("assign io_readPorts_%d_data = _GEN_0[io_readPorts_%d_data_REG];" % (r, r)) not in body:
            die("读口 %d 的输出不是 _GEN_0[打拍地址]" % r)
        if ("io_readPorts_%d_data_REG <= io_readPorts_%d_addr;" % (r, r)) not in body:
            die("读口 %d 的地址寄存器不是无条件打拍" % r)
    for i in range(1, NUM_PREGS):
        if ("assign io_debug_all_rdata_%d = mem_%d;" % (i, i)) not in body:
            die("debug_all_rdata_%d != mem_%d" % (i, i))


# ----------------------------------------------------------------------------- 生成
def gen_wrapper(mod, ports):
    part = mod[-1]
    L = []
    L.append("// %s.sv —— 整数物理寄存器堆的第 %s 片（64 位数据的第 %s 个 16 位切片），薄 wrapper" % (mod, part, part))
    L.append("// =============================================================================")
    L.append("// 逻辑全部在共用核 xs_IntRegFilePart_core（同目录 xs_IntRegFilePart_core.sv），本层只做端口展平/改名：")
    L.append("//   golden 的扁平 io_readPorts_<r>_* / io_writePorts_<w>_* / io_debug_all_rdata_<i>")
    L.append("//   <-> 核的按口号成组的数组端口。")
    L.append("// 本变体参数：224 个物理寄存器（x0 恒零）、11 读口（同步读，延迟 1 拍）、8 写口（同址多写按位或）、")
    L.append("//   16 位数据、8 位地址；223 路 debug 全量读出（_1.._223，无 _0）。寄存器 3656 位，全部不复位。")
    L.append("// 与另外三片的差异：★无★。G1 golden 的 IntRegFilePart0..3 逐行相同，只差模块名那一行")
    L.append("//   （生成器逐行核对，差异多一行即失败）；片号只决定上层接哪 16 位。")
    L.append("// reset 在综合视图里没有负载（golden 只在 `ifndef SYNTHESIS 的同址写断言里用它）。")
    L.append("// 端口表逐字抄自 G1 golden 同名模块。自动生成：scripts/gen_intregfile.py —— 勿手改")
    L.append("// =============================================================================")
    L.append("")
    L.append("module %s(" % mod)
    for i, (_, _, _, text) in enumerate(ports):
        L.append(text + ("," if i + 1 < len(ports) else ""))
    L.append(");")
    L.append("")
    L.append("  logic [%d:0][%d:0] read_addr;" % (NUM_READ - 1, ADDR_W - 1))
    L.append("  logic [%d:0][%d:0] read_data;" % (NUM_READ - 1, DATA_W - 1))
    L.append("  logic [%d:0]       write_wen;" % (NUM_WRITE - 1))
    L.append("  logic [%d:0][%d:0]  write_addr;" % (NUM_WRITE - 1, ADDR_W - 1))
    L.append("  logic [%d:0][%d:0] write_data;" % (NUM_WRITE - 1, DATA_W - 1))
    L.append("  logic [%d:0][%d:0] debug_all_rdata;" % (NUM_PREGS - 1, DATA_W - 1))
    L.append("")
    L.append("  // ---- 读口 ----")
    for r in range(NUM_READ):
        L.append("  assign read_addr[%d] = io_readPorts_%d_addr;" % (r, r))
    for r in range(NUM_READ):
        L.append("  assign io_readPorts_%d_data = read_data[%d];" % (r, r))
    L.append("")
    L.append("  // ---- 写口 ----")
    for w in range(NUM_WRITE):
        L.append("  assign write_wen[%d]  = io_writePorts_%d_wen;" % (w, w))
        L.append("  assign write_addr[%d] = io_writePorts_%d_addr;" % (w, w))
        L.append("  assign write_data[%d] = io_writePorts_%d_data;" % (w, w))
    L.append("")
    L.append("  xs_IntRegFilePart_core #(")
    L.append("    .NUM_PREGS (%d)," % NUM_PREGS)
    L.append("    .NUM_READ  (%d)," % NUM_READ)
    L.append("    .NUM_WRITE (%d)," % NUM_WRITE)
    L.append("    .DATA_W    (%d)," % DATA_W)
    L.append("    .ADDR_W    (%d)" % ADDR_W)
    L.append("  ) u_core (")
    L.append("    .clock           (clock),")
    L.append("    .reset           (reset),")
    L.append("    .read_addr       (read_addr),")
    L.append("    .read_data       (read_data),")
    L.append("    .write_wen       (write_wen),")
    L.append("    .write_addr      (write_addr),")
    L.append("    .write_data      (write_data),")
    L.append("    .debug_all_rdata (debug_all_rdata)")
    L.append("  );")
    L.append("")
    L.append("  // ---- debug 全量读出（第 0 路 x0 恒零，golden 没有这个端口，不引出） ----")
    for i in range(1, NUM_PREGS):
        L.append("  assign io_debug_all_rdata_%d = debug_all_rdata[%d];" % (i, i))
    L.append("endmodule")
    L.append("")
    return "\n".join(L)


def gen_pins():
    n = (NUM_PREGS - 1) * DATA_W + NUM_READ * ADDR_W
    L = []
    L.append("# IntRegFilePart0..3 FM「匹配前」钉点 —— 自动生成：scripts/gen_intregfile.py（勿手改）")
    L.append("#")
    L.append("# 只消 golden 扁平寄存器名与重写核数组名之间的命名鸿沟：")
    L.append("#   ref  mem_<k>_reg[b]                  <-> impl u_core/mem_reg[k][b]        k=1..%d, b=0..%d" % (NUM_PREGS - 1, DATA_W - 1))
    L.append("#   ref  io_readPorts_<r>_data_REG_reg[b] <-> impl u_core/raddr_q_reg[r][b]    r=0..%d, b=0..%d" % (NUM_READ - 1, ADDR_W - 1))
    L.append("# set_user_match 只是声明两点对应，比较照比：不约束 ref、不改 appvar、不加黑盒。")
    L.append("# fail-closed：set_user_match 从不抛异常（返回 0 = 没配上），所以逐条数返回值；")
    L.append("# 拒一条或总数不等于字面整数 %d（= golden 寄存器位数）就 error（safe interp 里不用 exit）。" % n)
    L.append("# 四个变体结构逐字相同，按 $top 取路径，同一份钉点对四个 top 都成立。进 fm.log 的输出一律 ASCII。")
    L.append("set ::INTRF_PIN_EXPECT %d" % n)
    L.append("set ::INTRF_PIN_OK 0")
    L.append("set ::INTRF_PIN_BAD 0")
    L.append("proc intrf_pin {r i} {")
    L.append("  if {[set_user_match $r $i]} { incr ::INTRF_PIN_OK } else {")
    L.append("    incr ::INTRF_PIN_BAD")
    L.append("    if {$::INTRF_PIN_BAD <= 10} { puts \"INTRF_PIN_FAIL: $r <-> $i\" }")
    L.append("  }")
    L.append("}")
    L.append("puts \"INTRF_PIN_BEGIN $top expect=$::INTRF_PIN_EXPECT\"")
    L.append("for {set k 1} {$k <= %d} {incr k} {" % (NUM_PREGS - 1))
    L.append("  for {set b 0} {$b < %d} {incr b} {" % DATA_W)
    L.append("    intrf_pin \"r:/WORK/$top/mem_${k}_reg\\[$b\\]\" \"i:/WORK/$top/u_core/mem_reg\\[$k\\]\\[$b\\]\"")
    L.append("  }")
    L.append("}")
    L.append("for {set r 0} {$r < %d} {incr r} {" % NUM_READ)
    L.append("  for {set b 0} {$b < %d} {incr b} {" % ADDR_W)
    L.append("    intrf_pin \"r:/WORK/$top/io_readPorts_${r}_data_REG_reg\\[$b\\]\" \"i:/WORK/$top/u_core/raddr_q_reg\\[$r\\]\\[$b\\]\"")
    L.append("  }")
    L.append("}")
    L.append("puts \"INTRF_PIN_END $top ok=$::INTRF_PIN_OK bad=$::INTRF_PIN_BAD\"")
    L.append("if {$::INTRF_PIN_BAD != 0} { error \"INTRF_PIN_MISS=$::INTRF_PIN_BAD\" }")
    L.append("if {$::INTRF_PIN_OK != %d} { error \"INTRF_PIN_COUNT=$::INTRF_PIN_OK expect=%d\" }" % (n, n))
    L.append("")
    return "\n".join(L)


def gen_tb_region(ports):
    """tb.sv 的 GENERATED(intrf-duts) 区：每个变体一对 golden/_xs，接到按变体下标的 tb 数组上。"""
    def conn(name, side, v):
        m = re.match(r"io_readPorts_(\d+)_(addr|data)$", name)
        if m:
            r = m.group(1)
            return "raddr[%d][%s]" % (v, r) if m.group(2) == "addr" else "%s_rd[%d][%s]" % (side, v, r)
        m = re.match(r"io_writePorts_(\d+)_(wen|addr|data)$", name)
        if m:
            return "w%s[%d][%s]" % (m.group(2), v, m.group(1))
        m = re.match(r"io_debug_all_rdata_(\d+)$", name)
        if m:
            return "%s_dbg[%d][%s]" % (side, v, m.group(1))
        if name in ("clock", "reset"):
            return name
        die("tb 接线：未知端口 %s" % name)

    L = ["  // BEGIN GENERATED(intrf-duts) —— scripts/gen_intregfile.py，勿手改"]
    for v, mod in enumerate(VARIANTS):
        for side, inst_mod in (("g", mod), ("x", mod + "_xs")):
            L.append("  %s %s_%d (" % (inst_mod, "u_gold" if side == "g" else "u_impl", v))
            for i, (_, _, name, _) in enumerate(ports):
                L.append("    .%s(%s)%s" % (name, conn(name, side, v), "," if i + 1 < len(ports) else ""))
            L.append("  );")
    L.append("  // END GENERATED(intrf-duts)")
    return "\n".join(L)


def splice(text, tag, region):
    b = "  // BEGIN GENERATED(%s)" % tag
    e = "  // END GENERATED(%s)" % tag
    i, j = text.find(b), text.find(e)
    if i < 0 or j < 0 or j < i:
        die("tb.sv 里找不到 GENERATED(%s) 标记" % tag)
    j = text.index("\n", j) if "\n" in text[j:] else len(text)
    return text[:i] + region + text[j:]


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--check", action="store_true", help="只比对不写，有漂移 rc=1")
    args = ap.parse_args()

    lines = check_variants_identical()
    ports, body_start = port_table(lines, VARIANTS[0])
    if [p[:3] for p in ports] != expected_ports():
        die("golden 端口表与预期形状不符")
    check_body(lines, body_start)

    outputs = {}
    for mod in VARIANTS:
        p, _ = port_table(read_golden(mod), mod)
        outputs[os.path.join(RTL, mod + ".sv")] = gen_wrapper(mod, p)
    outputs[os.path.join(UT, "fm_pins_pre.tcl")] = gen_pins()
    tb_path = os.path.join(UT, "tb.sv")
    with open(tb_path) as f:
        outputs[tb_path] = splice(f.read(), "intrf-duts", gen_tb_region(ports))

    drift = 0
    for path, text in outputs.items():
        old = open(path).read() if os.path.exists(path) else None
        if old == text:
            continue
        if args.check:
            print("DRIFT: %s" % os.path.relpath(path, REPO))
            drift += 1
        else:
            with open(path, "w") as f:
                f.write(text)
            print("wrote %s" % os.path.relpath(path, REPO))
    if args.check:
        if drift:
            print("gen_intregfile --check: %d 个文件与生成结果不一致" % drift)
            return 1
        print("gen_intregfile --check: OK (%d files)" % len(outputs))
    return 0


if __name__ == "__main__":
    sys.exit(main())
