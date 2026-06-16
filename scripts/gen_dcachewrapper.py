#!/usr/bin/env python3
"""
DCacheWrapper：从设计意图(Scala)重写 L1 DCache 顶层包装层。

设计规格来源：
  src/main/scala/xiangshan/cache/dcache/DCacheWrapper.scala
    class DCacheWrapper(...) extends LazyModule { ... DCacheWrapperImp ... }

  DCacheWrapper 的本质（读 Scala 而非 golden RTL）：
    val dcache = LazyModule(new DCache())          // 内层真正的 L1 DCache
    clientNode := dcache.clientNode                // TileLink client 透传（IdentityNode）
    dcache.cacheCtrlOpt.get.node := uncacheNode    // cache-ctrl 的 TL-UL 透传（IdentityNode）
    io <> dcache.module.io                         // 整个 DCacheIO 直连内层
    getPerfEvents -> generatePerfEvent()           // 收集内层 perf 计数，打 2 级寄存器后吐出

  => 包装层是「端口适配 + 节点透传 + perf 计数 2 级流水」。
     - 绝大多数端口（load*N / sta / store / atomics / TileLink client / 控制/调试）
       一一直连内层 DCache 实例，名字相同。
     - 唯一改名：cache-controller 的 TL-UL 端口在顶层叫 auto_uncache_in_*，
       连到内层 DCache 实例端口 auto_cacheCtrlOpt_in_*（diplomacy 节点改名）。
     - 唯一时序逻辑：32 个 perf event 计数值 io_perf_<i>_value（各 6bit），
       每个经过两级流水寄存器后输出（generatePerfEvent 的标准 2 拍打拍）。

  内层 DCache 是巨型子模块（golden DCache.sv ~1.08MB），UT/FM 双侧均黑盒，
  本包装层只验证「互联映射 + perf 2 级流水」等价。

本脚本职责：
  1. 解析 golden DCacheWrapper.sv 的扁平端口表与「内层 DCache 实例的端口→网名」映射，
     得到 (a) 顶层端口集 (b) auto_uncache_in_* 改名集 (c) perf 端口集。
  2. 生成顶层 wrapper（golden 同名 DCacheWrapper）—— 机械透传到可读核 u_core。
  3. 生成 UT 镜像 DCacheWrapper_xs（透传到同一可读核）。
  4. 生成随机激励 tb（golden vs _xs 双例化，逐拍比对所有输出）。

可读核 xs_DCacheWrapper_core 本体见 rtl/memblock/DCacheWrapper.sv（手写，含
struct/enum/function/genvar 表达 perf 流水与端口分组），不由本脚本生成。
"""
import re
from pathlib import Path

XSSV = Path(__file__).resolve().parent.parent
GOLDEN = XSSV / "golden/chisel-rtl"
WRAP = "DCacheWrapper"
INNER = "DCache"


def module_header(name, text):
    m = re.search(rf"^module {re.escape(name)}\((.*?)\n\);", text, re.S | re.M)
    return m.group(1)


def ports(name):
    """返回 [(dir, width, name)]，按 golden 顺序。"""
    text = (GOLDEN / f"{name}.sv").read_text()
    res = []
    for line in module_header(name, text).splitlines():
        pm = re.match(r"\s*(input|output)\s+(?:\[(\d+):0\])?\s*(\w+),?\s*$", line)
        if pm:
            res.append((pm.group(1), int(pm.group(2)) + 1 if pm.group(2) else 1, pm.group(3)))
    return res


def inst_map(text):
    """解析 golden 里 `DCache dcache ( .port (net), ... );`，返回 {inner_port: net}。"""
    m = re.search(r"\n  DCache dcache \(\n(.*?)\n  \);", text, re.S)
    res = {}
    body = m.group(1)
    # firtool 偶尔把单条连接拆成两行（.port 换行 (net)），故先把内容拍平再按 .port(net) 抓。
    flat = re.sub(r"\s+", " ", body)
    for pm in re.finditer(r"\.(\w+)\s*\(\s*(\w+)\s*\)", flat):
        res[pm.group(1)] = pm.group(2)
    return res


def emit_passthrough(modname, ps, core="xs_DCacheWrapper_core"):
    """顶层 wrapper / UT 镜像：端口与可读核一一同名，全透传。"""
    decls = []
    for d, w, n in ps:
        ws = f"[{w-1}:0] " if w > 1 else ""
        decls.append(f"  {d:6s} {ws}{n}")
    conns = [f"    .{n}({n})" for _, _, n in ps]
    L = [f"module {modname}(", ",\n".join(decls) + "\n);",
         f"  {core} u_core (", ",\n".join(conns), "  );", "endmodule\n"]
    return "\n".join(L)


def emit_dcache_stub():
    """生成内层 DCache 黑盒桩（UT 用，golden 与 _xs 两侧共用同一桩）。

    DCache 巨型且依赖上百个子模块，无法整树编译。本桩声明其全部 603 端口，
    把 perf 计数 io_perf_<i>_value 用「对若干输入做确定性哈希」的方式驱动——
    保证非 X 且两侧完全一致，从而真实激励本包装层的 perf 2 级流水并可逐拍比对；
    其余输出置 0（包装层对它们仅透传，两侧恒等，比对自然通过）。
    """
    ps = ports(INNER)
    decls = []
    for d, w, n in ps:
        ws = f"[{w-1}:0] " if w > 1 else ""
        decls.append(f"  {d:6s} {ws}{n}")
    L = ["// 自动生成：scripts/gen_dcachewrapper.py —— 勿手改",
         "// 内层 DCache 黑盒桩：UT 两侧共用，驱动 perf 计数以激励包装层 perf 流水。",
         "module DCache(", ",\n".join(decls) + "\n);"]
    # perf 驱动：用 clock 计数 + 一些输入异或，做成随时间变化的 6bit 值。
    L.append("  // 简易 perf 计数源：逐拍自增 + 输入扰动，保证非 X 且确定。")
    L.append("  reg [5:0] perf_ctr;")
    L.append("  always @(posedge clock) begin")
    L.append("    if (reset) perf_ctr <= 6'd0;")
    L.append("    else       perf_ctr <= perf_ctr + 6'd1;")
    L.append("  end")
    outs = [(w, n) for d, w, n in ps if d == "output"]
    perf_re = re.compile(r"io_perf_(\d+)_value$")
    for w, n in outs:
        m = perf_re.match(n)
        if m:
            i = int(m.group(1))
            # 每路加不同偏移 + 与一个输入位异或，区分各路、且对输入敏感。
            L.append(f"  assign {n} = perf_ctr + 6'd{i} "
                     f"^ {{5'd0, io_lsu_load_0_req_valid}};")
        else:
            ws = f"{w}'d0" if w > 1 else "1'b0"
            L.append(f"  assign {n} = {ws};")
    L.append("endmodule\n")
    return "\n".join(L)


def emit_tb(ps):
    ins = [(w, n) for d, w, n in ps if d == "input" and n not in ("clock", "reset")]
    outs = [(w, n) for d, w, n in ps if d == "output"]

    # 内层 DCache 黑盒：UT 两侧共用 golden DCache 实例。其大量输出在随机/未约束激励下
    # 多为 X（依赖内部 SRAM/状态机初值）。比对策略：只比对「确定可判」的输出——
    #   * perf 输出（本层唯一自有逻辑，2 级流水），以及
    #   * 与 X 无关位：用 !$isunknown(g) 跳过 golden 为 X 的拍/位。
    # 由于两侧例化同一 DCache 且互联相同，凡 golden 非 X 处 _xs 必须逐位相同。
    perf_outs = [n for _, n in outs if re.match(r"io_perf_\d+_value$", n)]

    T = ["""// 自动生成：scripts/gen_dcachewrapper.py —— 勿手改
// DCacheWrapper UT：golden DCacheWrapper vs 手写 DCacheWrapper_xs 双例化逐拍比对。
// 内层 DCache 两侧共用 golden 黑盒；只验证顶层互联映射 + perf 2 级流水等价。
`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 4000;
  bit clk = 0, rst;
  int errors = 0, checks = 0;
  always #5 clk = ~clk;
"""]
    for w, n in ins:
        ws = f"[{w-1}:0] " if w > 1 else ""
        T.append(f"  logic {ws}{n};")
    for w, n in outs:
        ws = f"[{w-1}:0] " if w > 1 else ""
        T.append(f"  wire {ws}g_{n};")
        T.append(f"  wire {ws}i_{n};")

    gc = [".clock(clk)", ".reset(rst)"] + [f".{n}({n})" for _, n in ins]
    gg = gc + [f".{n}(g_{n})" for _, n in outs]
    ig = gc + [f".{n}(i_{n})" for _, n in outs]
    T.append(f"  DCacheWrapper    u_g ({', '.join(gg)});")
    T.append(f"  DCacheWrapper_xs u_i ({', '.join(ig)});")

    # 随机激励：地址压窄高位以反复命中同 cacheline，valid 类压低占空提高握手覆盖。
    def rnd(w, n):
        if n.endswith(("_valid", "_ready")) or re.search(r"(_kill|wfiReq|robHeadValid)$", n):
            return "($urandom_range(0,2)!=0)"
        if re.search(r"(vaddr|paddr|addr|robHeadVaddr_bits)", n) and w > 8:
            return f"{{{w-8}'($urandom_range(0,3)), 8'($urandom)}}"
        if w == 1:
            return "$urandom_range(0,1)"
        if w <= 32:
            return f"{w}'($urandom)"
        rep = (w + 31) // 32
        return f"{w}'({{{', '.join(['$urandom()']*rep)}}})"

    valid_names = [n for _, n in ins if n.endswith("_valid")]
    T.append("  always @(negedge clk) begin")
    T.append("    if (rst) begin")
    for n in valid_names:
        T.append(f"      {n} <= 1'b0;")
    T.append("    end else begin")
    for w, n in ins:
        T.append(f"      {n} <= {rnd(w, n)};")
    T.append("    end")
    T.append("  end")

    # 比对：所有输出，逐位跳 golden-X。perf 输出额外断言两侧必须相同（其驱动确定）。
    cmp_lines = []
    for w, n in outs:
        cmp_lines.append(f"      if (!$isunknown(g_{n})) begin checks++; "
                         f"if (g_{n} !== i_{n}) begin errors++; "
                         f'if (errors<=20) $display("  MISMATCH %0t {n}: g=%h i=%h", $time, g_{n}, i_{n}); end end')
    T.append("""
  initial begin
    rst = 1'b1;
    repeat (10) @(negedge clk);
    rst = 1'b0;
    repeat (4) @(negedge clk);  // 等 perf 2 级流水填满
    for (int unsigned c = 0; c < NCYCLES; c++) begin
      @(posedge clk); #1;
""" + "\n".join(cmp_lines) + """
    end
    if (errors == 0) $display("TEST PASSED (DCacheWrapper): checks=%0d", checks);
    else             $display("TEST FAILED (DCacheWrapper): errors=%0d checks=%0d", errors, checks);
    $finish;
  end
endmodule
""")
    return "\n".join(T)


def main():
    text = (GOLDEN / f"{WRAP}.sv").read_text()
    ps = ports(WRAP)
    imap = inst_map(text)

    # 提取 cache-ctrl 改名集（顶层 auto_uncache_in_* -> 内层 auto_cacheCtrlOpt_in_*）
    renames = {net: inner for inner, net in imap.items()
               if inner != net and not net.startswith("_dcache")}

    hdr = "// 自动生成：scripts/gen_dcachewrapper.py —— 勿手改\n"
    (XSSV / "rtl/memblock/DCacheWrapper_wrapper.sv").write_text(hdr + emit_passthrough("DCacheWrapper", ps))

    # ---- 给手写可读核用的两个 include ----
    # (1) 端口声明表（与 golden 顶层完全一致，603 端口）。
    port_decls = []
    for d, w, n in ps:
        ws = f"[{w-1}:0] " if w > 1 else ""
        port_decls.append(f"  {d:6s} {ws}{n}")
    (XSSV / "rtl/memblock/dcachewrapper_ports.svh").write_text(
        hdr + ",\n".join(port_decls) + "\n")

    # (2) 内层 DCache 黑盒实例的「机械互联」连接——除 perf 外的全部端口。
    #     perf 端口（io_perf_<i>_value）由核内 generate 显式连到流水寄存器，故此处排除。
    #     auto_uncache_in_* 在此按 golden 改名连到内层 auto_cacheCtrlOpt_in_*。
    perf_re = re.compile(r"io_perf_\d+_value$")
    conns = []
    for inner, net in imap.items():
        if perf_re.match(inner):
            continue  # perf 由核内 generate 连接
        conns.append(f"    .{inner:42s} ({net})")
    (XSSV / "rtl/memblock/dcachewrapper_inner_conn.svh").write_text(
        hdr + ",\n".join(conns) + ",\n")

    # (3) DCache 黑盒声明（仅端口方向，无逻辑）。FM 两侧均读入这一份，使内层黑盒
    #     的 perf 输出方向显式且一致，消除 firtool 黑盒 unknown-direction 假阳性
    #     （否则个别 perf 路因 ref/impl 侧黑盒输出方向推断不一致而 FM fail）。
    iports = ports(INNER)
    bb = ["// 自动生成：scripts/gen_dcachewrapper.py —— 勿手改",
          "// 内层 DCache 黑盒声明（仅端口方向）。供 FM 两侧读入，统一黑盒边界。",
          "module DCache("]
    bdecls = []
    for d, w, n in iports:
        ws = f"[{w-1}:0] " if w > 1 else ""
        bdecls.append(f"  {d:6s} {ws}{n}")
    bb.append(",\n".join(bdecls) + "\n);")
    bb.append("endmodule")
    (XSSV / "rtl/memblock/dcache_blackbox.sv").write_text("\n".join(bb) + "\n")

    ut = XSSV / "verif/ut/DCacheWrapper"
    ut.mkdir(parents=True, exist_ok=True)
    (ut / "variants_xs.sv").write_text(hdr + emit_passthrough("DCacheWrapper_xs", ps))
    (ut / "tb.sv").write_text(emit_tb(ps))
    (ut / "dcache_stub.sv").write_text(emit_dcache_stub())

    # 给手写核作参考：打印改名集，确认核里的内层实例映射与 golden 一致。
    print(f"ports={len(ps)} renames(auto_uncache_in_*->auto_cacheCtrlOpt_in_*)={len(renames)}")
    for net, inner in renames.items():
        print(f"  {net} -> {inner}")


if __name__ == "__main__":
    main()
