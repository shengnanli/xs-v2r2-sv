#!/usr/bin/env python3
"""
DCache 顶层集成生成器（内层 L1 DCache 集成/互联层，非薄包装 DCacheWrapper）。

设计意图来源（人写 Chisel）：
  src/main/scala/xiangshan/cache/dcache/DCacheWrapper.scala  class DCacheImp
    把 30+ 个子模块互连成 L1 DCache（多端口 load/store/probe/atomic 路由、阵列读写
    仲裁、MSHR 分配、一致性、TileLink A/B/C/D/E）。

分层（与 LsqWrapper / DCacheWrapper 同一方法学）：
  可读核 xs_DCache_core（手写，rtl/memblock/DCache.sv）承担**真正的可读集成逻辑**：
    * setplru 替换器：256 组 × 4 路 Tree-PLRU、4 个 touch 端口（ldu0/1/2/mainPipe）
      —— 用 dcache_pkg 的 plru_* 纯函数 + genvar 表达，取代 golden 7000+ 行展平 always
    * 32 路 perf 计数 2 级打拍 —— genvar
  机械互联（本脚本从 golden 复刻，纯接线/TL-edge 拍数跟踪，无 DCache 设计决策）：
    * 32 个子模块实例的端口->网名连接          -> dcache_inst.svh
    * 所有中间/子模块输出网的 wire 声明（去掉替换器/perf 网）-> dcache_nets.svh
    * 顶层 assign 互联别名（去掉 perf-out）      -> dcache_glue_assign.svh
    * 复位/寄存 always 块（去掉替换器/perf 寄存）-> dcache_glue_ff.svh

  子模块（LoadPipe/MainPipe/MissQueue/各阵列/各 Arbiter/...）在 UT/FM 两侧均黑盒。

本脚本同时生成：黑盒 stub、golden 同名 wrapper、UT 镜像 / tb。
"""
import re
from pathlib import Path

XSSV = Path(__file__).resolve().parent.parent
GOLDEN = XSSV / "golden/chisel-rtl"
GSV = (GOLDEN / "DCache.sv").read_text()
LINES = GSV.splitlines()
RTL = XSSV / "rtl/memblock"
HDR = "// 自动生成：scripts/gen_dcache.py —— 勿手改\n"

# 被可读核手写逻辑接管、不应由机械互联复刻的网名（前缀/精确名）
REPL_NET_RE = re.compile(
    r"^(state_vec_\d+|set_touch_ways_\w+|_state_vec_\d+_T(_\d+)?|_GEN_15|_GEN_16)$")
PERF_REG_RE = re.compile(r"^io_perf_\d+_value_REG(_\d+)?$")


# ----------------------------------------------------------------------------
# 顶层端口
# ----------------------------------------------------------------------------
def top_ports():
    m = re.search(r"^module DCache\((.*?)\n\);", GSV, re.S | re.M)
    res = []
    for line in m.group(1).splitlines():
        pm = re.match(r"\s*(input|output)\s+(?:\[(\d+):0\])?\s*(\w+),?\s*$", line)
        if pm:
            res.append((pm.group(1), int(pm.group(2)) + 1 if pm.group(2) else 1, pm.group(3)))
    return res


# ----------------------------------------------------------------------------
# 实例块解析
# ----------------------------------------------------------------------------
INST_HEAD = re.compile(r"^  ([A-Za-z_][A-Za-z_0-9]*) +([a-z_][A-Za-z_0-9]*) \($")


def unwrap(v):
    v = v.strip()
    if v.startswith("(") and v.endswith(")") and v.count("(") == 1:
        return v[1:-1].strip()
    return v


def parse_instances():
    insts = []
    i = 0
    while i < len(LINES):
        m = INST_HEAD.match(LINES[i])
        if not m:
            i += 1
            continue
        mod, inst = m.group(1), m.group(2)
        i += 1
        raw = []
        while not re.match(r"^  \);$", LINES[i]):
            raw.append(LINES[i])
            i += 1
        conns, cur = [], None
        for l in raw:
            pm = re.match(r"^\s*\.(\w+)\s*(.*)$", l)
            if pm and (pm.group(2).strip() == "" or pm.group(2).strip().startswith("(")):
                if cur:
                    conns.append(cur)
                cur = [pm.group(1), pm.group(2).strip()]
            else:
                cur[1] += " " + l.strip()
        if cur:
            conns.append(cur)
        conns = [(p, re.sub(r"\s+", " ", v).strip().rstrip(",")) for p, v in conns]
        insts.append((mod, inst, conns))
        i += 1
    return insts


# ----------------------------------------------------------------------------
# 顶层 wire 声明（含 packed 数组）；返回有序 [(text_line, name)]
# ----------------------------------------------------------------------------
def wire_decls():
    res = []
    for ln in LINES:
        m = re.match(r"^  wire\s+(?:\[\d+:\d+\]\s+)?(\w+)(?:\s*\[\d+:\d+\])?\s*(?:=.*)?;?\s*$", ln)
        # 只取“纯声明”行：`  wire [..] name;` 或 `  wire name;`（不带 = 的赋值合一行）
        m2 = re.match(r"^  wire\s+(\[\d+:\d+\]\s+)?(\w+)(\s*\[\d+:\d+\])?;\s*$", ln)
        if m2:
            res.append((ln, m2.group(2)))
    return res


def assign_aliases():
    """顶层 `assign LHS = RHS;`（含跨行），返回 [(full_text, lhs_name)]。"""
    res = []
    for m in re.finditer(r"^(  assign (\w+)(?:\[[^\]]*\])? =.*?;)\s*$", GSV, re.S | re.M):
        res.append((m.group(1), m.group(2)))
    return res


# ----------------------------------------------------------------------------
# 生成各 include
# ----------------------------------------------------------------------------
def gen_ports_svh(ps):
    decls = [f"  {d:6s} {('['+str(w-1)+':0] ') if w>1 else ''}{n}" for d, w, n in ps]
    (RTL / "dcache_ports.svh").write_text(
        HDR + "// 可读核 xs_DCache_core 端口表（与 golden DCache 同名扁平端口）。\n"
        + ",\n".join(decls) + "\n")


def gen_nets_svh(top_names):
    """声明所有非顶层端口、非替换器/perf 的中间/子模块输出网为 wire。
       同时把 golden 里 `wire name = expr;` 形式的组合赋值（除替换器/perf）一并搬运。"""
    out = [HDR, "// 子模块输出网 + 中间组合网的 wire 声明与组合赋值（机械互联，无设计决策）。",
           "// 替换器(state_vec/set_touch_ways/_GEN_15/16)与 perf 寄存由可读核手写，不在此。\n"]
    skip_decl_reg = []
    for ln in LINES:
        # 形如  wire [..] name = expr ;  （可能跨行；这里按起始行抓再补全）
        m = re.match(r"^  wire\s+(\[\d+:\d+\]\s+)?(\w+)(\s*\[\d+:\d+\])?\s*(=|;)", ln)
        if not m:
            continue
        name = m.group(2)
        if name in top_names:
            continue
        if REPL_NET_RE.match(name):
            continue
        out.append(ln)
    return out  # 实际写入在 main()，因为需多行合并；见下


def main():
    ps = top_ports()
    top_names = {n for _, _, n in ps}
    insts = parse_instances()
    print(f"DCache: {len(ps)} ports, {len(insts)} sub-instances")

    gen_ports_svh(ps)

    # --- nets: 多行合并地搬运 `wire ... = ...;` 与纯 `wire ...;`（去替换器/perf）---
    net_lines = []
    i = 0
    body_end = next(idx for idx, l in enumerate(LINES) if INST_HEAD.match(l))
    while i < body_end:
        ln = LINES[i]
        m = re.match(r"^  wire\s+(\[\d+:\d+\]\s+)?(\w+)(\s*\[\d+:\d+\])?\s*(=|;)", ln)
        if not m:
            i += 1
            continue
        name = m.group(2)
        # 收集到分号
        chunk = [ln]
        while ";" not in chunk[-1]:
            i += 1
            chunk.append(LINES[i])
        i += 1
        if name in top_names or REPL_NET_RE.match(name):
            continue
        net_lines.append("\n".join(chunk))
    (RTL / "dcache_nets.svh").write_text(
        HDR + "// 子模块输出网 + 中间组合网（机械互联；替换器/perf 网不在此，由核手写）。\n\n"
        + "\n".join(net_lines) + "\n")

    # --- reg 声明（去替换器 state_vec / perf REG）---
    reg_lines = []
    i = 0
    while i < body_end:
        ln = LINES[i]
        m = re.match(r"^  reg\s+(\[\d+:\d+\]\s+)?(\w+)(\s*\[\d+:\d+\])?;", ln)
        if m:
            name = m.group(2)
            if not (name.startswith("state_vec_") or PERF_REG_RE.match(name)):
                reg_lines.append(ln)
        i += 1
    (RTL / "dcache_regs.svh").write_text(
        HDR + "// 寄存器声明（错误聚合 / 原子响应 / release / TL-edge 拍数等机械寄存）。\n"
        "// 替换器 state_vec 与 perf REG 由可读核手写，不在此。\n\n"
        + "\n".join(reg_lines) + "\n")

    # --- always 块：搬运（剥离替换器 state_vec 更新 与 perf REG 更新）---
    gen_ff_svh()

    # --- assign 别名（去 perf-out）---
    al = []
    for txt, lhs in assign_aliases():
        if PERF_REG_RE.match(lhs) or re.match(r"^io_perf_\d+_value$", lhs):
            continue
        al.append(txt)
    (RTL / "dcache_glue_assign.svh").write_text(
        HDR + "// 顶层 assign 互联别名（机械接线；perf-out 由核手写）。\n\n"
        + "\n".join(al) + "\n")

    # --- perf 原始源映射（32 路：io_perf_i_value_REG <= _<inst>_io_perf_k_value）---
    gen_perf_src_svh()

    # --- 实例 ---
    gen_inst_svh(insts)

    # --- stub / wrapper / ut ---
    gen_stubs(insts)
    gen_wrapper_and_ut(ps)
    print("generated: ports/nets/regs/glue_ff/glue_assign/inst .svh + stubs + wrapper + UT")


def gen_ff_svh():
    """搬运顶层 always 块，但删除 state_vec_* 更新片段 与 io_perf_*_value_REG 更新片段。
       做法：逐 always 块抓取，去掉以 state_vec_ / io_perf_..._value_REG 为目标的 if/赋值。"""
    text = GSV
    blocks = re.findall(r"^  always @\(.*?\n(.*?)^  end(?: //.*)?$",
                        text, re.S | re.M)
    # 直接按行过滤更稳：在 body 区抓 always..end，逐行剔除替换器/perf 行及其所属 if
    out = [HDR, "// 复位/寄存 always 块（错误聚合 / 原子响应 / release / TL-edge 拍数等）。",
           "// 替换器 state_vec 更新 与 perf REG 更新由可读核手写，不在此。\n"]
    i = 0
    n = len(LINES)
    body_end = next(idx for idx, l in enumerate(LINES) if INST_HEAD.match(l))
    while i < body_end:
        ln = LINES[i]
        if re.match(r"^  always @\(", ln):
            blk = [ln]
            i += 1
            depth = 0
            while i < body_end:
                blk.append(LINES[i])
                if re.match(r"^  end(?: //.*)?$", LINES[i]):
                    i += 1
                    break
                i += 1
            filtered = filter_block(blk)
            if filtered:
                out.append("\n".join(filtered))
                out.append("")
        else:
            i += 1
    (RTL / "dcache_glue_ff.svh").write_text("\n".join(out) + "\n")


def filter_block(blk):
    """从一个 always 块里删除：以 state_vec_<n> 或 io_perf_<n>_value_REG 为左值的赋值，
       以及仅包含这些赋值的 if/begin-end 片段。保守做法：删除含这些目标 token 的整个
       顶层语句（按 `state_vec_` / `_value_REG` token 出现的整条 if(...) begin..end 或
       单行赋值）。replacer/perf 的 always 是独立的 if 段，删除安全。"""
    txt = "\n".join(blk)
    # 删除 perf REG：每个是 `io_perf_X_value_REG <= ...; io_perf_X_value_REG_1 <= ...;`
    txt = re.sub(r"^\s*io_perf_\d+_value_REG(_\d+)? <= [^;]*;\s*$", "", txt, flags=re.M)
    # 删除 state_vec 复位：`state_vec_X <= 3'h0;`
    txt = re.sub(r"^\s*state_vec_\d+ <= [^;]*;\s*$", "", txt, flags=re.M)
    # 删除 state_vec 更新 if 段（多行）：`if (set_touch_ways_..._X_valid ...) begin ... end`
    txt = strip_state_vec_ifs(txt)
    lines = [l for l in txt.splitlines() if l.strip() != ""]
    # 若块体只剩 always 头 + if(reset)begin/end 空壳，则丢弃
    meaningful = [l for l in lines if not re.match(
        r"^\s*(always @|if \(reset\)|begin|end|else if \(reset\)|else)\s*$", l)
        and "begin" not in l.strip()[:6]]
    if not any(("<=" in l or "=" in l) for l in lines):
        return []
    return lines


def strip_state_vec_ifs(txt):
    """删除形如 `if (set_touch_ways_0_<S>_valid | ...) begin <state_vec_<S> 更新> end` 的多行块。"""
    out = []
    lines = txt.splitlines()
    i = 0
    while i < len(lines):
        l = lines[i]
        if re.match(r"^\s*if \(set_touch_ways_\d+(_\d+)?_valid", l):
            # 外层 if 条件可能跨多行，begin 在后续行；先吃到第一个 begin，再按 begin/end
            # 计数吃到匹配 end。
            i += 1
            while i < len(lines) and "begin" not in lines[i - 1]:
                i += 1
            depth = 1
            while i < len(lines) and depth > 0:
                depth += lines[i].count("begin") - lines[i].count("end")
                i += 1
            continue
        out.append(l)
        i += 1
    return "\n".join(out)


def gen_perf_src_svh():
    """32 路 perf 原始源：把 golden `io_perf_i_value_REG <= SRC;` 解析为 perf_raw[i]=SRC。"""
    src = {}
    for m in re.finditer(r"io_perf_(\d+)_value_REG <= (\w+);", GSV):
        src[int(m.group(1))] = m.group(2)
    out = [HDR, "// 32 路 perf 计数原始源（子模块 perf 输出网），喂给可读核 2 级打拍。"]
    for i in range(32):
        out.append(f"  assign perf_raw[{i}] = {src[i]};")
    (RTL / "dcache_perf_src.svh").write_text("\n".join(out) + "\n")
    po = [HDR, "// 32 路 perf 打两拍后接出顶层端口。"]
    for i in range(32):
        po.append(f"  assign io_perf_{i}_value = perf_stage2[{i}];")
    (RTL / "dcache_perf_out.svh").write_text("\n".join(po) + "\n")


def gen_inst_svh(insts):
    out = [HDR, "// 32 个子模块实例（端口->网名，原样复刻 golden 互联）。"
           "直连顶层端口或 dcache_nets 声明的中间网。\n"]
    for mod, inst, conns in insts:
        out.append(f"  {mod} {inst} (")
        body = []
        for p, v in conns:
            # 替换器 way 查询：golden 用 _GEN_16(=state_vec[set]) 现场译码，
            # 改接可读核计算的 mainpipe_replace_way（见 DCache.sv 替换器节）。
            if inst == "mainPipe" and p == "io_replace_way_way":
                v = "mainpipe_replace_way"
            # golden 的未连接端口写作 (/* unused */)，SV 里应留空 .port()
            vv = unwrap(v) if v else ""
            if vv.strip() == "/* unused */":
                vv = ""
            body.append(f"    .{p}({vv})")
        out.append(",\n".join(body))
        out.append("  );")
    (RTL / "dcache_inst.svh").write_text("\n".join(out) + "\n")


# ----------------------------------------------------------------------------
# 黑盒 stub：32 类子模块，端口方向取自各自 golden 文件（若存在）；否则从实例端口名推方向
# ----------------------------------------------------------------------------
def gen_stubs(insts):
    mods = {}
    for mod, _, _ in insts:
        mods[mod] = True
    out = [HDR, "// DCache 子模块黑盒 stub（UT/FM 两侧共用，统一黑盒边界）。\n"]
    for mod in mods:
        gf = GOLDEN / f"{mod}.sv"
        if gf.exists():
            txt = gf.read_text()
            m = re.search(rf"^module {re.escape(mod)}\((.*?)\n\);", txt, re.S | re.M)
            if m:
                out.append(f"module {mod}(")
                out.append(m.group(1))
                out.append(");")
                out.append("endmodule\n")
                continue
        # 回退：用实例连接推端口（仅声明 input，FM 黑盒模式按名对齐，方向不强求）
        out.append(f"// WARN: no golden {mod}.sv; emit empty stub")
        out.append(f"module {mod}(); endmodule\n")
    (RTL / "dcache_stub.sv").write_text("\n".join(out))


def gen_wrapper_and_ut(ps):
    def flat(modname, core):
        decls = [f"  {d:6s} {('['+str(w-1)+':0] ') if w>1 else ''}{n}" for d, w, n in ps]
        L = [f"module {modname}(", ",\n".join(decls) + "\n);",
             f"  {core} u_core (",
             ",\n".join(f"    .{n}({n})" for _, _, n in ps), "  );", "endmodule\n"]
        return "\n".join(L)

    (RTL / "DCache_wrapper.sv").write_text(HDR + flat("DCache", "xs_DCache_core"))
    ut = XSSV / "verif/ut/DCache"
    ut.mkdir(parents=True, exist_ok=True)
    (ut / "variants_xs.sv").write_text(HDR + flat("DCache_xs", "xs_DCache_core"))
    (ut / "tb.sv").write_text(gen_tb(ps))


def gen_tb(ps):
    ins = [(w, n) for d, w, n in ps if d == "input" and n not in ("clock", "reset")]
    outs = [(w, n) for d, w, n in ps if d == "output"]
    T = [HDR, "`timescale 1ns/1ps", "module tb;",
         "  int unsigned NCYCLES = 200000;",
         "  bit clk = 0; logic rst;",
         "  int errors = 0, checks = 0;",
         "  always #5 clk = ~clk;"]
    for w, n in ins:
        T.append(f"  logic {('['+str(w-1)+':0] ') if w>1 else ''}{n};")
    for w, n in outs:
        ws = ('['+str(w-1)+':0] ') if w > 1 else ''
        T.append(f"  wire {ws}g_{n};")
        T.append(f"  wire {ws}i_{n};")
    gc = [".clock(clk)", ".reset(rst)"] + [f".{n}({n})" for _, n in ins]
    T.append("  DCache    u_g (" + ", ".join(gc + [f".{n}(g_{n})" for _, n in outs]) + ");")
    T.append("  DCache_xs u_i (" + ", ".join(gc + [f".{n}(i_{n})" for _, n in outs]) + ");")

    def rnd(w, n):
        if n.endswith("_valid") or n.endswith("_ready"):
            return "$urandom_range(0,1)"
        if w == 1:
            return "$urandom_range(0,1)"
        if w <= 32:
            return f"{w}'($urandom)"
        rep = (w + 31) // 32
        return f"{w}'({{{', '.join(['$urandom()']*rep)}}})"

    reset_valids = [n for _, n in ins if n.endswith("_valid")]
    T.append("  always @(negedge clk) begin")
    T.append("    if (rst) begin")
    for n in reset_valids:
        T.append(f"      {n} <= 1'b0;")
    T.append("    end else begin")
    for w, n in ins:
        T.append(f"      {n} <= {rnd(w, n)};")
    T.append("    end")
    T.append("  end")
    T.append("  always @(negedge clk) if (!rst) begin")
    T.append("    #4; checks++;")
    for w, n in outs:
        T.append(f"    if (!$isunknown(g_{n}) && g_{n} !== i_{n}) begin errors++;")
        T.append(f"      if(errors<=80) $display(\"[%0t] {n} g=%h i=%h\", $time, g_{n}, i_{n}); end")
    T.append("  end")
    T.append("""  initial begin
    rst = 1; repeat (16) @(posedge clk); rst = 0;
    repeat (NCYCLES) @(posedge clk);
    $display("checks=%0d errors=%0d", checks, errors);
    if (errors == 0 && checks > 1000) $display("TEST PASSED"); else $display("TEST FAILED");
    $finish;
  end
endmodule
""")
    return "\n".join(T)


if __name__ == "__main__":
    main()
