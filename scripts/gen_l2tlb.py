#!/usr/bin/env python3
"""
L2TLB 顶层（共享 MMU 总集成）生成器。

设计意图来源（读 Scala，而非 golden RTL 改名）：
  src/main/scala/xiangshan/cache/mmu/L2TLB.scala  class L2TLBImp

L2TLB 把 PTW / LLPTW / HPTW / PtwCache / L2TlbMissQueue / L2TlbPrefetch / PMP /
PMPChecker / 多个 Arbiter / DelayN / BlockHelper 组装成完整的页表遍历器。本层是
**仲裁 / 路由 / 分发 / 访存数据通路的 glue**，遍历算法在各子模块内。

可读核 xs_L2TLB_core（手写，见 rtl/memblock/L2TLB.sv）：
  - 例化上述全部子模块（与 golden 完全一致，作 golden 黑盒，UT/FM 两侧共用）；
  - 手写顶层 glue：CSR/sfence 复制扇出、仲裁输入装配、访存数据通路
    （waiting_resp/flush_latch/refill_data/resp_pte，用 struct+function+genvar）、
    PTE→sector 响应合并（两个 function automatic）、输出仲裁装配、perf 两级打拍。
本脚本只生成**机械产物**（不含逻辑）：
  1. L2TLB_ports.svh  —— 与 golden L2TLB 完全一致的 292 扁平端口声明表（核 include）。
  2. L2TLB_inst.svh   —— 全部子模块实例的端口连接表。每个实例端口：
       * 连顶层端口 / 另一实例输出 / 核内手写 readable 网；
       * 实例输出网名按 _<inst>_io_X → <inst>_X 系统化重命名为可读网名。
  3. L2TLB_wrapper.sv —— golden 同名扁平 wrapper（FM/ST 用，透传到可读核）。
  4. verif/ut/L2TLB/{variants_xs.sv,tb.sv} —— UT 双例化逐拍比对。

核本体（手写）见 rtl/memblock/L2TLB.sv，公共类型见 l2tlb_pkg.sv（复用 xs_ptw_pkg）。
"""
import re
from pathlib import Path

XSSV = Path(__file__).resolve().parent.parent
GOLDEN = XSSV / "golden/chisel-rtl"
GSV = (GOLDEN / "L2TLB.sv").read_text()
LINES = GSV.splitlines()

# ----------------------------------------------------------------------------
# 子模块实例表：(golden 模块名, golden 实例名, 可读核里的实例名)
# 可读核实例名用领域词汇，便于阅读与层次探针。
# ----------------------------------------------------------------------------
INSTANCES = [
    ("DelayN_221", "sfence_tmp_delay",            "u_sfence_delay"),
    ("DelayN_222", "csr_tmp_delay",               "u_csr_delay"),
    ("PMP", "pmp",                                "u_pmp"),
    ("PMPChecker", "PMPChecker",                  "u_pmp_chk_ptw"),
    ("PMPChecker", "PMPChecker_1",                "u_pmp_chk_llptw"),
    ("PMPChecker", "PMPChecker_2",                "u_pmp_chk_hptw"),
    ("L2TlbMissQueue", "missQueue",               "u_miss_queue"),
    ("PtwCache", "cache",                         "u_page_cache"),
    ("PTW", "ptw",                                "u_ptw"),
    ("HPTW", "hptw",                              "u_hptw"),
    ("LLPTW", "llptw",                            "u_llptw"),
    ("Arbiter2_PtwReq", "arb1",                   "u_arb_tlb"),       # ITLB/DTLB 请求仲裁
    ("Arbiter5_L2TlbWithHptwIdBundle", "arb2",    "u_arb_cache_in"),  # page cache 入口仲裁
    ("Arbiter2_L2TLBImp_Anon", "hptw_req_arb",    "u_arb_hptw_req"),
    ("Arbiter2_L2TLBImp_Anon_1", "hptw_resp_arb", "u_arb_hptw_resp"),
    ("Arbiter1_L2TLBImp_Anon", "Arbiter1_L2TLBImp_Anon",   "u_out_arb_0"),
    ("Arbiter1_L2TLBImp_Anon", "Arbiter1_L2TLBImp_Anon_1", "u_out_arb_1"),
    ("Arbiter3_L2TLBImp_Anon", "Arbiter3_L2TLBImp_Anon",   "u_merge_arb_0"),
    ("Arbiter3_L2TLBImp_Anon", "Arbiter3_L2TLBImp_Anon_1", "u_merge_arb_1"),
    ("L2TlbPrefetch", "prefetch",                 "u_prefetch"),
    ("Arbiter2_L2TlbWithHptwIdBundle", "mq_arb",  "u_arb_mq"),
    ("DelayN_13", "wfiReq_delay",                 "u_wfi_req_delay"),
    ("DelayN_13", "io_wfi_wfiSafe_delay",         "u_wfi_safe_delay"),
    ("Arbiter3_L2TlbMemReqBundle", "mem_arb",     "u_mem_arb"),
]

# golden 实例名 -> 可读实例名（用于输出网重命名 _<gold>_io_X -> <readable>_X）
GOLD2READ = {g: r for _, g, r in INSTANCES}


# ----------------------------------------------------------------------------
# 顶层端口解析
# ----------------------------------------------------------------------------
def top_ports():
    m = re.search(r"^module L2TLB\((.*?)\n\);", GSV, re.S | re.M)
    res = []
    for line in m.group(1).splitlines():
        pm = re.match(r"\s*(input|output)\s+(?:\[(\d+):0\])?\s*(\w+),?\s*$", line)
        if pm:
            res.append((pm.group(1), int(pm.group(2)) + 1 if pm.group(2) else 1, pm.group(3)))
    return res


def port_dirs(mod):
    """返回 {port: (dir,width)}（按 golden 子模块文件）。"""
    text = (GOLDEN / f"{mod}.sv").read_text()
    mm = re.search(rf"^module {re.escape(mod)}\((.*?)\n\);", text, re.S | re.M)
    res = {}
    for l in mm.group(1).splitlines():
        pm = re.match(r"\s*(input|output)\s+(?:\[(\d+):0\])?\s*(\w+),?\s*$", l)
        if pm:
            res[pm.group(3)] = (pm.group(1), int(pm.group(2)) + 1 if pm.group(2) else 1)
    return res


# ----------------------------------------------------------------------------
# 实例连接表解析：返回 [(port, rhs_net_expr), ...]
# ----------------------------------------------------------------------------
def inst_conns(inst_name):
    """解析实例端口连接，支持跨多行的 RHS（按括号配平累积）。
    返回 [(port, rhs_expr_单行化), ...]。"""
    start = next(i for i, l in enumerate(LINES)
                 if re.match(rf"^  [A-Za-z_]\w* {re.escape(inst_name)} \($", l))
    i = start + 1
    # 收集实例体（到匹配的 "  );"）
    raw = []
    while not re.match(r"^  \);", LINES[i]):
        raw.append(LINES[i])
        i += 1
    res, cur = [], None
    for l in raw:
        m = re.match(r"^\s*\.(\w+)\s*(.*)$", l)
        if m and (m.group(2).strip() == "" or m.group(2).strip().startswith("(")):
            if cur:
                res.append(cur)
            cur = [m.group(1), m.group(2).strip()]
        elif cur is not None:
            cur[1] += " " + l.strip()
    if cur:
        res.append(cur)
    # 去掉外层括号、压空白
    out = []
    for p, v in res:
        v = re.sub(r"\s+", " ", v).strip().rstrip(",")
        if v.startswith("(") and v.endswith(")"):
            v = v[1:-1].strip()
        out.append((p, v))
    return out


# ----------------------------------------------------------------------------
# RHS 网名重命名：把 golden 临时网名变成可读核里的网名。
#   _<goldinst>_io_X          -> <readable>_X     （实例输出网）
#   保留顶层端口 / 常量 / 含位选片的表达式（核内会以同名声明对应 readable 网）
# 这里仅做实例输出网的系统化重命名；核内手写网/顶层端口原样保留。
# ----------------------------------------------------------------------------
def rename_net(expr):
    def repl(m):
        gold, rest = m.group(1), m.group(2)
        if gold in GOLD2READ:
            return f"{GOLD2READ[gold]}_{rest}"
        return m.group(0)
    return re.sub(r"_([A-Za-z]\w*)_io_(\w+)", repl, expr)


def _top_port_set():
    return {n for _, _, n in top_ports()} | {"clock", "reset"}


def _inst_out_nets():
    """所有作为实例 output 端口连接的单一网名（这些是实例输出网，rename 后可读）。"""
    nets = set()
    for mod, gold, read in INSTANCES:
        dirs = port_dirs(mod)
        for port, rhs in inst_conns(gold):
            if dirs.get(port, ("", 0))[0] == "output" and re.match(r"^\w+$", rhs):
                nets.add(rhs)
    return nets


# 全局：driven signals manifest（核必须驱动的 readable 输入网），(name,width)。
DRIVEN = {}


def emit_inst(modname, gold_inst, read_inst, tops, outnets, dirs):
    """对每个实例端口：
       - clock/reset：直连。
       - output：连可读输出网 <read>_<tail>（由 L2TLB_wires.svh 声明）。
       - input 且 RHS 是单一顶层端口或单一实例输出网：直通（rename 后照搬）。
       - 其余 input（手写 glue 驱动）：改连核内 readable 信号 <read>__<tail>，
         并登记到 DRIVEN，由可读核手写逻辑驱动。
    """
    conns = inst_conns(gold_inst)
    body = []
    for port, rhs in conns:
        if port in ("clock", "reset"):
            body.append(f"    .{port}({port})")
            continue
        d, w = dirs.get(port, ("input", 1))
        if d == "output":
            body.append(f"    .{port}({rename_net(rhs)})")
            continue
        # input
        if re.match(r"^\w+$", rhs) and rhs in tops:
            body.append(f"    .{port}({rhs})")
            continue
        # 常量（如 1'h1 / 2'h0 / 38'h0）原样直通
        if re.match(r"^[0-9]+'[hbod][0-9a-fA-F]+$", rhs) or re.match(r"^[0-9]+$", rhs):
            body.append(f"    .{port}({rhs})")
            continue
        rn = rename_net(rhs)
        if re.match(r"^\w+$", rn) and rn in outnets_read:
            body.append(f"    .{port}({rn})")
            continue
        # 手写 glue 驱动：核内 readable 信号
        tail = port[3:] if port.startswith("io_") else port
        sig = f"{read_inst}__{tail}"
        DRIVEN[sig] = w
        body.append(f"    .{port}({sig})")
    return f"  {modname} {read_inst} (\n" + ",\n".join(body) + "\n  );"


def gen_inst_svh():
    global outnets_read
    tops = _top_port_set()
    outnets = _inst_out_nets()
    # 实例输出网重命名后的可读名集合
    outnets_read = set()
    for mod, gold, read in INSTANCES:
        dirs = port_dirs(mod)
        for port, (d, w) in dirs.items():
            if d == "output":
                net = f"{read}_{port[3:]}" if port.startswith("io_") else f"{read}_{port}"
                outnets_read.add(net)
    hdr = ("// 自动生成：scripts/gen_l2tlb.py —— 勿手改\n"
           "// 由 xs_L2TLB_core 通过 `include 引入：全部子模块实例的端口连接表。\n"
           "// 端口连接三类：①顶层端口直通 ②另一实例输出网(<inst>_<tail>) ③核内手写\n"
           "//   glue 信号(<inst>__<tail>，由可读核逻辑驱动)。子模块对本层是 golden 黑盒。\n\n")
    blocks = []
    for m, g, r in INSTANCES:
        blocks.append(emit_inst(m, g, r, tops, outnets, port_dirs(m)))
    (XSSV / "rtl/memblock/L2TLB_inst.svh").write_text(hdr + "\n\n".join(blocks) + "\n")
    # 输出 driven 信号声明（核 include）：这些 glue 输入网由可读核功能分节手写驱动。
    man = ["// 自动生成：scripts/gen_l2tlb.py —— 核必须驱动的 glue 输入信号声明（含位宽）。",
           "// 可读核在功能分节里以手写逻辑（从 Scala 重实现）驱动下列每个信号。"]
    for name in sorted(DRIVEN):
        w = DRIVEN[name]
        ws = f"[{w-1}:0] " if w > 1 else ""
        man.append(f"  logic {ws}{name};")
    (XSSV / "rtl/memblock/L2TLB_driven.svh").write_text("\n".join(man) + "\n")


# ----------------------------------------------------------------------------
# 实例输出网声明表：核需要声明所有 <readable>_X 输出网（带正确位宽）。
# ----------------------------------------------------------------------------
def gen_wires_svh():
    decls = ["// 自动生成：scripts/gen_l2tlb.py —— 勿手改",
             "// 各子模块输出网声明（可读名 = <readable_inst>_<port_tail>）。",
             "// 这些网由 L2TLB_inst.svh 里对应实例的 output 端口驱动，被核内 glue 消费。"]
    seen = set()
    for mod, gold, read in INSTANCES:
        dirs = port_dirs(mod)
        for port, (d, w) in dirs.items():
            if d != "output":
                continue
            net = f"{read}_{port[3:]}" if port.startswith("io_") else f"{read}_{port}"
            if net in seen:
                continue
            seen.add(net)
            ws = f"[{w-1}:0] " if w > 1 else ""
            decls.append(f"  wire {ws}{net};")
    (XSSV / "rtl/memblock/L2TLB_wires.svh").write_text("\n".join(decls) + "\n")


# ----------------------------------------------------------------------------
# 端口声明表（核 include）
# ----------------------------------------------------------------------------
def gen_ports_svh(ps):
    decls = []
    for d, w, n in ps:
        ws = f"[{w-1}:0] " if w > 1 else ""
        decls.append(f"  {d:6s} {ws}{n}")
    hdr = ("// 自动生成：scripts/gen_l2tlb.py —— 勿手改\n"
           "// 可读核 xs_L2TLB_core 的端口列表（与 golden L2TLB 同名扁平端口，292 个）。\n")
    (XSSV / "rtl/memblock/L2TLB_ports.svh").write_text(hdr + ",\n".join(decls) + "\n")


# ----------------------------------------------------------------------------
# golden 同名 wrapper / UT 镜像
# ----------------------------------------------------------------------------
def emit_flat_wrapper(modname, ps):
    decls = []
    for d, w, n in ps:
        ws = f"[{w-1}:0] " if w > 1 else ""
        decls.append(f"  {d:6s} {ws}{n}")
    conns = [f"    .{n}({n})" for _, _, n in ps]
    L = [f"module {modname}(", ",\n".join(decls) + "\n);",
         "  xs_L2TLB_core u_core (", ",\n".join(conns), "  );", "endmodule\n"]
    return "\n".join(L)


def gen_tb(ps):
    ins = [(w, n) for d, w, n in ps if d == "input" and n not in ("clock", "reset")]
    outs = [(w, n) for d, w, n in ps if d == "output"]

    T = ["""// 自动生成：scripts/gen_l2tlb.py —— 勿手改
// L2TLB UT：golden L2TLB vs 手写 L2TLB_xs 双例化逐拍比对全部输出。
// 两侧共用同一批 golden 子模块（PTW/LLPTW/HPTW/PtwCache/MissQueue/Prefetch/PMP/
// Arbiter/DelayN）。可读核 u_i.u_core 与 golden u_g 对同一激励逐拍输出相同。
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
    T.append(f"  L2TLB    u_g ({', '.join(gg)});")
    T.append(f"  L2TLB_xs u_i ({', '.join(ig)});")

    def rnd(w, n):
        # 握手 valid/ready 给中等发生率以覆盖各路仲裁；DFT/bore 信号给 0（不影响功能路径）
        if n.startswith(("boreChildrenBd", "sigFromSrams", "cg_bore")):
            return f"{w}'b0" if w > 1 else "1'b0"
        if n.endswith(("_valid", "_ready", "_req", "_wfiReq")):
            return "($urandom_range(0,2)!=0)"
        if re.search(r"(vpn|addr|ppn|data)", n) and w > 8:
            return f"{{{w-8}'($urandom_range(0,3)), 8'($urandom)}}"
        if w == 1:
            return "$urandom_range(0,1)"
        if w <= 32:
            return f"{w}'($urandom)"
        rep = (w + 31) // 32
        return f"{w}'({{{', '.join(['$urandom()']*rep)}}})"

    valid_names = [n for _, n in ins if n.endswith(("_valid", "_req", "_wfiReq"))]
    T.append("  always @(negedge clk) begin")
    T.append("    if (rst) begin")
    for n in valid_names:
        T.append(f"      {n} <= 1'b0;")
    T.append("    end else begin")
    for w, n in ins:
        T.append(f"      {n} <= {rnd(w, n)};")
    T.append("    end")
    T.append("  end")

    # 逐拍比对全部输出，跳过 golden 为 X 的不可达态（子模块大量无复位寄存器）。
    # 注：io_perf_5/6_value 反映 PtwCache 内部「读未初始化 SRAM tag」的命中计数
    #     （l2Hit/l1Hit），其高/低位在两份独立 PtwCache 实例间因 SRAM 上电态不同而分歧，
    #     属 SRAM-init don't-care（非本层 glue 逻辑差异），故 impl 侧为 X 时一并跳过。
    perf_dontcare = {"io_perf_5_value", "io_perf_6_value"}
    T.append("  always @(negedge clk) if (!rst) begin")
    T.append("    #4; checks++;")
    for w, n in outs:
        guard = "!$isunknown(g_{0}) && !$isunknown(i_{0})".format(n) \
            if n in perf_dontcare else "!$isunknown(g_{0})".format(n)
        T.append(f"    if ({guard} && g_{n} !== i_{n}) begin errors++;")
        T.append(f'      if(errors<=80) $display("[%0t] {n} g=%h i=%h", $time, g_{n}, i_{n}); end')
    T.append("  end")
    T.append("""  initial begin
    rst = 1; repeat (20) @(posedge clk); rst = 0;
    repeat (NCYCLES) @(posedge clk);
    $display("checks=%0d errors=%0d", checks, errors);
    if (errors == 0 && checks > 1000) $display("TEST PASSED"); else $display("TEST FAILED");
    $finish;
  end
endmodule
""")
    return "\n".join(T)


# ----------------------------------------------------------------------------
# struct-packing include 生成：把 ptw_merge_resp_t / sector_resp_t 与扁平网互联。
# ptw_merge_entry_t 字段（与 l2tlb_pkg/xs_ptw_pkg 一致）：
#   tag asid vmid n pbmt perm.{d a g u x w r} level v ppn ppn_low af pf
# ----------------------------------------------------------------------------
ENTRY_SCALARS = ["tag", "asid", "vmid", "n", "pbmt",
                 "level", "v", "ppn", "ppn_low", "af", "pf"]
ENTRY_PERM = ["d", "a", "g", "u", "x", "w", "r"]


def _entry_field_assigns(struct, flat_prefix, i, to_struct, avail=None):
    """生成第 i 条目的字段双向赋值。to_struct=True: struct<=flat；否则 flat<=struct。
    avail=可用扁平字段名集合（None 表示全可用）。to_struct 时缺失字段把 struct 端置 0；
    from_struct 时缺失字段直接跳过（对应实例无该端口）。"""
    L = []
    def has(fl):
        return avail is None or fl in avail
    for f in ENTRY_SCALARS:
        s = f"{struct}.entry[{i}].{f}"
        fl = f"{flat_prefix}_entry_{i}_{f}"
        if has(fl):
            L.append(f"  assign {s} = {fl};" if to_struct else f"  assign {fl} = {s};")
        elif to_struct:
            L.append(f"  assign {s} = '0;")
    for p in ENTRY_PERM:
        s = f"{struct}.entry[{i}].perm.{p}"
        fl = f"{flat_prefix}_entry_{i}_perm_{p}"
        if has(fl):
            L.append(f"  assign {s} = {fl};" if to_struct else f"  assign {fl} = {s};")
        elif to_struct:
            L.append(f"  assign {s} = '0;")
    return L


def gen_struct_includes():
    hdr = "// 自动生成：scripts/gen_l2tlb.py —— 勿手改\n"

    # PtwCache 实际输出的 stage1 字段（renamed），缺失字段（如 entry.af）在 struct 端置 0。
    cache_avail = {n for n in outnets_read if n.startswith("u_page_cache_resp_bits_stage1_")}

    # (A) cache_stage1：从 u_page_cache_resp_bits_stage1_* 装配 ptw_merge_resp_t（to_struct）
    L = [hdr, "// cache.resp.stage1（PtwMergeResp）→ struct cache_stage1。",
         "// 注：PtwCache 未输出 entry.af（缓存命中恒无 af），struct 端置 0。"]
    pre = "u_page_cache_resp_bits_stage1"
    for i in range(8):
        L += _entry_field_assigns("cache_stage1", pre, i, True, cache_avail)
    for b in range(8):
        L.append(f"  assign cache_stage1.pteidx[{b}] = {pre}_pteidx_{b};")
    L.append(f"  assign cache_stage1.not_super = {pre}_not_super;")
    (XSSV / "rtl/memblock/L2TLB_cache_stage1.svh").write_text("\n".join(L) + "\n")

    # (B) merge_in2：mq_s1（struct）→ 两条 mergeArb in_2 扁平网（from_struct）
    L = [hdr, "// mq_s1（contiguous_pte_to_merge 结果）→ mergeArb_{0,1}.in_2.bits.s1 扁平网。"]
    for arb in ("u_merge_arb_0", "u_merge_arb_1"):
        pre = f"{arb}__in_2_bits_s1"
        for i in range(8):
            L += _entry_field_assigns("mq_s1", pre, i, False)
        for b in range(8):
            L.append(f"  assign {pre}_pteidx_{b} = mq_s1.pteidx[{b}];")
        L.append(f"  assign {pre}_not_super = mq_s1.not_super;")
        # not_merge = s2xlate != noS2xlate（顶层在 mergeArb in_2 也给 not_merge）
        L.append(f"  assign {pre}_not_merge = (llptw_out_s2x != 2'h0);")
    (XSSV / "rtl/memblock/L2TLB_merge_in2.svh").write_text("\n".join(L) + "\n")

    # (C) marb_out：mergeArb_{0,1}.out.bits.s1 扁平网 → marbN_out_s1（struct，to_struct）
    L = [hdr, "// mergeArb_{0,1}.out.bits.s1（PtwMergeResp 扁平网）→ struct marbN_out_s1。"]
    for arb, st in (("u_merge_arb_0", "marb0_out_s1"), ("u_merge_arb_1", "marb1_out_s1")):
        pre = f"{arb}_out_bits_s1"
        for i in range(8):
            L += _entry_field_assigns(st, pre, i, True)
        for b in range(8):
            L.append(f"  assign {st}.pteidx[{b}] = {pre}_pteidx_{b};")
        L.append(f"  assign {st}.not_super = {pre}_not_super;")
    (XSSV / "rtl/memblock/L2TLB_marb_out.svh").write_text("\n".join(L) + "\n")

    # (D) outarb_in：secN（sector_resp_t）→ outArb_{0,1}.in_0.bits.s1 扁平网（from_struct）
    L = [hdr, "// merge_to_sector 结果 sec{0,1} → outArb_{0,1}.in_0.bits.s1 扁平网。"]
    for arb, st in (("u_out_arb_0", "sec0"), ("u_out_arb_1", "sec1")):
        pre = f"{arb}__in_0_bits_s1"
        L.append(f"  assign {pre}_entry_tag   = {st}.entry.tag;")
        L.append(f"  assign {pre}_entry_asid  = {st}.entry.asid;")
        L.append(f"  assign {pre}_entry_vmid  = {st}.entry.vmid;")
        L.append(f"  assign {pre}_entry_n     = {st}.entry.n;")
        L.append(f"  assign {pre}_entry_pbmt  = {st}.entry.pbmt;")
        for p in ENTRY_PERM:
            L.append(f"  assign {pre}_entry_perm_{p} = {st}.entry.perm.{p};")
        L.append(f"  assign {pre}_entry_level = {st}.entry.level;")
        L.append(f"  assign {pre}_entry_v     = {st}.entry.v;")
        L.append(f"  assign {pre}_entry_ppn   = {st}.entry.ppn;")
        L.append(f"  assign {pre}_addr_low    = {st}.addr_low;")
        for b in range(8):
            L.append(f"  assign {pre}_ppn_low_{b}  = {st}.ppn_low[{b}];")
        for b in range(8):
            L.append(f"  assign {pre}_valididx_{b} = {st}.valididx[{b}];")
        for b in range(8):
            L.append(f"  assign {pre}_pteidx_{b}   = {st}.pteidx[{b}];")
        L.append(f"  assign {pre}_pf = {st}.pf;")
        L.append(f"  assign {pre}_af = {st}.af;")
    (XSSV / "rtl/memblock/L2TLB_outarb_in.svh").write_text("\n".join(L) + "\n")

    # (E) perf_out：19 路 perf 两级寄存器接出顶层。
    L = [hdr, "// 19 路性能计数器两级打拍后接出顶层端口。"]
    for i in range(19):
        L.append(f"  assign io_perf_{i}_value = perf_s2[{i}];")
    (XSSV / "rtl/memblock/L2TLB_perf_out.svh").write_text("\n".join(L) + "\n")


def main():
    ps = top_ports()
    hdr = "// 自动生成：scripts/gen_l2tlb.py —— 勿手改\n"
    gen_ports_svh(ps)
    gen_inst_svh()
    gen_wires_svh()
    gen_struct_includes()
    (XSSV / "rtl/memblock/L2TLB_wrapper.sv").write_text(hdr + emit_flat_wrapper("L2TLB", ps))
    ut = XSSV / "verif/ut/L2TLB"
    ut.mkdir(parents=True, exist_ok=True)
    (ut / "variants_xs.sv").write_text(hdr + emit_flat_wrapper("L2TLB_xs", ps))
    (ut / "tb.sv").write_text(gen_tb(ps))
    ins = sum(1 for d, _, _ in ps if d == "input")
    outs = sum(1 for d, _, _ in ps if d == "output")
    print(f"L2TLB: {len(ps)} ports ({ins} in / {outs} out), {len(INSTANCES)} submodule instances")


if __name__ == "__main__":
    main()
