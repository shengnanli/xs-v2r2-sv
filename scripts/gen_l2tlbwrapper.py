#!/usr/bin/env python3
"""
L2TLBWrapper：从设计意图(Scala)重写共享 MMU / L2TLB 的顶层包装层。

设计规格来源（读 Scala，而非 golden RTL 改名）：
  src/main/scala/xiangshan/cache/mmu/L2TLB.scala
    class L2TLBWrapper()(implicit p) extends LazyModule {
      val node = TLIdentityNode()                 // 向 L2 取页表项的 TileLink 透传（IdentityNode）
      val ptw  = LazyModule(new L2TLB())          // 内层真正的 L2TLB（PTW + page cache + ...）
      node := ptw.node                            // 内层 TL client 口经 IdentityNode 原样引出
      class L2TLBWrapperImp ... with HasPerfEvents {
        val io = IO(new L2TLBIO)
        io <> ptw.module.io                        // 整个 L2TLBIO 直连内层
        ptw.module.getPerfEvents                   // 收集内层 perf 计数
        generatePerfEvent()                        // -> 各 perf value 打 2 级寄存器后输出
      }
    }

  => 包装层是「端口适配 + 节点透传 + perf 计数 2 级流水」，本身不含任何 MMU/PTW 算法。
     - 绝大多数端口（auto_out_* TileLink、io_tlb_0/1 的 TLB miss 请求/页表项响应、
       io_sfence、io_wfi、io_csr、以及 SRAM DFT/bore 与 clock-gating 透传信号
       boreChildrenBd_*/sigFromSrams_*/cg_bore_cgen）**一一直连**内层 L2TLB 实例，名字相同。
     - 本配置无任何功能端口改名（不像 DCacheWrapper 的 auto_uncache_in_* 改名）。
     - 唯一时序逻辑：19 个 perf event 计数值 io_perf_<i>_value（各 6bit），
       每个经过两级流水寄存器后输出（generatePerfEvent 的标准 2 拍打拍）。

  内层 L2TLB 是巨型子模块（golden L2TLB.sv ~787KB），UT/FM 双侧均黑盒，
  本包装层只验证「互联映射 + perf 2 级流水」等价。

本脚本职责：
  1. 解析 golden L2TLBWrapper.sv 的扁平端口表与「内层 L2TLB 实例的端口→网名」映射，
     得到 (a) 顶层端口集 (b) perf 端口集（其余端口同名直连）。
  2. 生成顶层 wrapper（golden 同名 L2TLBWrapper）—— 机械透传到可读核 u_core。
  3. 生成 UT 镜像 L2TLBWrapper_xs（透传到同一可读核）。
  4. 生成内层 L2TLB 黑盒桩（UT 用）与黑盒声明（FM 用）。
  5. 生成随机激励 tb（golden vs _xs 双例化，逐拍比对所有输出）。

可读核 xs_L2TLBWrapper_core 本体见 rtl/memblock/L2TLBWrapper.sv（手写，含
struct/enum/function/genvar 表达 perf 流水与端口分组），不由本脚本生成。
"""
import re
from pathlib import Path

XSSV = Path(__file__).resolve().parent.parent
GOLDEN = XSSV / "golden/chisel-rtl"
WRAP = "L2TLBWrapper"
INNER = "L2TLB"
INNER_INST = "ptw"  # golden 里内层实例名


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
    """解析 golden 里 `L2TLB ptw ( .port (net), ... );`，返回 {inner_port: net}。"""
    m = re.search(rf"\n  {INNER} {INNER_INST} \(\n(.*?)\n  \);", text, re.S)
    res = {}
    body = m.group(1)
    flat = re.sub(r"\s+", " ", body)
    for pm in re.finditer(r"\.(\w+)\s*\(\s*(\w+)\s*\)", flat):
        res[pm.group(1)] = pm.group(2)
    return res


def emit_passthrough(modname, ps, core="xs_L2TLBWrapper_core"):
    """顶层 wrapper / UT 镜像：端口与可读核一一同名，全透传。"""
    decls = []
    for d, w, n in ps:
        ws = f"[{w-1}:0] " if w > 1 else ""
        decls.append(f"  {d:6s} {ws}{n}")
    conns = [f"    .{n}({n})" for _, _, n in ps]
    L = [f"module {modname}(", ",\n".join(decls) + "\n);",
         f"  {core} u_core (", ",\n".join(conns), "  );", "endmodule\n"]
    return "\n".join(L)


def emit_l2tlb_stub():
    """生成内层 L2TLB 黑盒桩（UT 用，golden 与 _xs 两侧共用同一桩）。

    L2TLB 巨型且依赖上百子模块，无法整树编译。本桩声明其全部端口，把 perf 计数
    io_perf_<i>_value 用「逐拍自增 + 输入扰动」驱动——保证非 X 且两侧完全一致，
    从而真实激励本包装层的 perf 2 级流水并可逐拍比对；其余输出置 0（包装层对它们
    仅透传，两侧恒等，比对自然通过）。
    """
    ps = ports(INNER)
    decls = []
    for d, w, n in ps:
        ws = f"[{w-1}:0] " if w > 1 else ""
        decls.append(f"  {d:6s} {ws}{n}")
    L = ["// 自动生成：scripts/gen_l2tlbwrapper.py —— 勿手改",
         "// 内层 L2TLB 黑盒桩：UT 两侧共用，驱动 perf 计数以激励包装层 perf 流水。",
         f"module {INNER}(", ",\n".join(decls) + "\n);"]
    L.append("  // 简易 perf 计数源：逐拍自增 + 输入扰动，保证非 X 且确定。")
    L.append("  reg [5:0] perf_ctr;")
    L.append("  always @(posedge clock) begin")
    L.append("    if (reset) perf_ctr <= 6'd0;")
    L.append("    else       perf_ctr <= perf_ctr + 6'd1;")
    L.append("  end")
    outs = [(w, n) for d, w, n in ps if d == "output"]
    perf_re = re.compile(r"io_perf_(\d+)_value$")
    # 选一个稳定存在的 1bit 输入做扰动源（tlb 请求 valid）。
    perturb = "io_tlb_0_req_0_valid"
    for w, n in outs:
        m = perf_re.match(n)
        if m:
            i = int(m.group(1))
            L.append(f"  assign {n} = perf_ctr + 6'd{i} ^ {{5'd0, {perturb}}};")
        else:
            ws = f"{w}'d0" if w > 1 else "1'b0"
            L.append(f"  assign {n} = {ws};")
    L.append("endmodule\n")
    return "\n".join(L)


def emit_blackbox():
    """L2TLB 黑盒声明（仅端口方向，无逻辑）。FM 两侧均读入这一份，统一黑盒边界。"""
    iports = ports(INNER)
    bb = ["// 自动生成：scripts/gen_l2tlbwrapper.py —— 勿手改",
          "// 内层 L2TLB 黑盒声明（仅端口方向）。供 FM 两侧读入，统一黑盒边界。",
          f"module {INNER}("]
    bdecls = []
    for d, w, n in iports:
        ws = f"[{w-1}:0] " if w > 1 else ""
        bdecls.append(f"  {d:6s} {ws}{n}")
    bb.append(",\n".join(bdecls) + "\n);")
    bb.append("endmodule")
    return "\n".join(bb) + "\n"


def emit_tb(ps):
    ins = [(w, n) for d, w, n in ps if d == "input" and n not in ("clock", "reset")]
    outs = [(w, n) for d, w, n in ps if d == "output"]

    T = ["""// 自动生成：scripts/gen_l2tlbwrapper.py —— 勿手改
// L2TLBWrapper UT：golden L2TLBWrapper vs 手写 L2TLBWrapper_xs 双例化逐拍比对。
// 内层 L2TLB 两侧共用 golden 黑盒桩；只验证顶层互联映射 + perf 2 级流水等价。
`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 200000;
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
    T.append(f"  L2TLBWrapper    u_g ({', '.join(gg)});")
    T.append(f"  L2TLBWrapper_xs u_i ({', '.join(ig)});")

    def rnd(w, n):
        if n.endswith(("_valid", "_ready")) or re.search(r"(wfiReq|_req$|_all$)", n):
            return "($urandom_range(0,2)!=0)"
        if re.search(r"(vpn|addr|ppn)", n) and w > 8:
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
    if (errors == 0) $display("TEST PASSED (L2TLBWrapper): checks=%0d", checks);
    else             $display("TEST FAILED (L2TLBWrapper): errors=%0d checks=%0d", errors, checks);
    $finish;
  end
endmodule
""")
    return "\n".join(T)


def main():
    text = (GOLDEN / f"{WRAP}.sv").read_text()
    ps = ports(WRAP)
    imap = inst_map(text)

    hdr = "// 自动生成：scripts/gen_l2tlbwrapper.py —— 勿手改\n"
    (XSSV / "rtl/memblock/L2TLBWrapper_wrapper.sv").write_text(hdr + emit_passthrough("L2TLBWrapper", ps))

    # ---- 给手写可读核用的两个 include ----
    # (1) 端口声明表（与 golden 顶层完全一致，292 端口）。
    port_decls = []
    for d, w, n in ps:
        ws = f"[{w-1}:0] " if w > 1 else ""
        port_decls.append(f"  {d:6s} {ws}{n}")
    (XSSV / "rtl/memblock/l2tlbwrapper_ports.svh").write_text(
        hdr + ",\n".join(port_decls) + "\n")

    # (2) 内层 L2TLB 黑盒实例的「机械互联」连接——除 perf 外的全部端口。
    #     perf 端口（io_perf_<i>_value）由核内 generate 显式连到流水寄存器，故此处排除。
    #     本配置无任何功能端口改名（inner_port == net）。
    perf_re = re.compile(r"io_perf_\d+_value$")
    renames = {}
    conns = []
    for inner, net in imap.items():
        if perf_re.match(inner):
            continue  # perf 由核内 generate 连接
        if inner != net:
            renames[net] = inner
        conns.append(f"    .{inner:34s} ({net})")
    (XSSV / "rtl/memblock/l2tlbwrapper_inner_conn.svh").write_text(
        hdr + ",\n".join(conns) + ",\n")

    # (3) L2TLB 黑盒声明（仅端口方向）。FM 两侧均读入。
    (XSSV / "rtl/memblock/l2tlb_blackbox.sv").write_text(emit_blackbox())

    ut = XSSV / "verif/ut/L2TLBWrapper"
    ut.mkdir(parents=True, exist_ok=True)
    (ut / "variants_xs.sv").write_text(hdr + emit_passthrough("L2TLBWrapper_xs", ps))
    (ut / "tb.sv").write_text(emit_tb(ps))
    (ut / "l2tlb_stub.sv").write_text(emit_l2tlb_stub())

    nperf = sum(1 for _, _, n in ps if perf_re.match(n))
    print(f"ports={len(ps)} perf_events={nperf} functional_renames={len(renames)}")
    for net, inner in renames.items():
        print(f"  {net} -> {inner}")


if __name__ == "__main__":
    main()
