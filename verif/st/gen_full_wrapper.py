#!/usr/bin/env python3
# =============================================================================
# gen_full_wrapper.py —— 由 golden 模块的完整端口表 + 重写 "子集 wrapper",
#   生成一个 **全端口 wrapper**(module M),端口与 golden 1:1(名字+方向+位宽),
#   内部把功能子集接到重写核(经子集 wrapper),golden 多出来的 perf/debug/背压口
#   做合理直通/占位驱动,使父模块例化能解析所有端口。
#
# 用法:
#   gen_full_wrapper.py <M> <golden_M.sv> <subset_wrapper.sv>  > full_wrapper.sv
#
# 机制:
#   1) 解析 golden M 的端口块 → 全端口表(name -> (dir,width_str))。
#   2) 解析子集 wrapper 的端口块 → 子集端口名集合;并提取子集 wrapper 的"内部体"
#      (端口 ) 之后到 endmodule 之前),把 `module <M> (...)` 改名为
#      `module xs_<M>_subset (...)`,作为内部子模块原样保留(它例化重写核)。
#   3) 生成 module M:
#        - 端口表 = golden 全端口(逐行原样,保证位宽/方向/名字一致)。
#        - 例化 xs_<M>_subset,把两边都有的端口按名直连;子集独有(理论上没有)忽略。
#        - golden 独有的 **输入**:声明即可,内部不接(对 subset 实例不连)。
#        - golden 独有的 **输出**:必须驱动。规则(faithful pass-through):
#            * 若该输出名把 'io_out' 换成 'io_in' 后在 golden 输入表里存在,
#              且位宽一致 → assign out = 对应 in;(perf/debug 0 延迟直通)
#            * 'io_in_ready' → assign io_in_ready = io_out_ready;(背压直通)
#            * 否则 → assign out = '0;(占位,位宽匹配)
#   注:perf/debug 不参与 difftest 架构比对(只喂性能计数/调试 DB),0 延迟直通对
#       HIT GOOD TRAP 无害;真正功能相关的 valid/ctrl/res_data 由重写核产出(经
#       子集 wrapper),io_in_ready 背压直通保证不死锁(这些 FU 写回端 io_out_ready
#       恒就绪)。
# =============================================================================
import sys, os, re

def read(p):
    with open(p) as f:
        return f.read()

# ---- 解析端口块: 返回 [(name, dir, width_str, raw_decl_line)] 保持顺序 ----
PORT_RE = re.compile(
    r'^\s*(input|output|inout)\s+(?:wire\s+|reg\s+|logic\s+)?'
    r'(\[[^\]]*\]\s*)?([A-Za-z_]\w*)\s*$')

def parse_ports(text, module):
    # 取 module <name> ( ... ); 的端口块。
    # 兼容 ANSI 头里 module 名与端口左括号之间的可选构件:
    #   - 参数块 #( ... )
    #   - 一个或多个 import pkg::*; 子句(如 Fence_wrapper 的 `import fence_pkg::*;`)
    # 这些都要在到达端口块 `(` 之前被跳过。
    m = re.search(
        r'\bmodule\s+' + re.escape(module) + r'\b\s*'
        r'(?:#\s*\([^)]*\)\s*)?'                       # 可选参数块
        r'(?:import\s+[^;]+;\s*)*'                     # 可选 import 子句(0+)
        r'\(',
        text)
    if not m:
        raise SystemExit("gen_full_wrapper: module %s not found" % module)
    start = m.end()  # 紧跟左括号后
    # 找匹配到端口块结束的 ");" —— 简单括号计数(端口块内无嵌套括号,
    # 但位宽里的 [] 不是 ())。
    depth = 1
    i = start
    while i < len(text) and depth > 0:
        c = text[i]
        if c == '(':
            depth += 1
        elif c == ')':
            depth -= 1
        i += 1
    block = text[start:i-1]
    ports = []
    for raw in block.split(','):
        line = raw.strip()
        if not line:
            continue
        # 去注释
        line = re.sub(r'//.*$', '', line, flags=re.M).strip()
        if not line:
            continue
        pm = PORT_RE.match(line)
        if not pm:
            # 容错: 可能 dir/width/name 跨多空白
            pm2 = re.match(
                r'(input|output|inout)\s+(?:wire\s+|reg\s+|logic\s+)?'
                r'(\[[^\]]*\]\s*)?([A-Za-z_]\w*)', line)
            if not pm2:
                continue
            pm = pm2
        d = pm.group(1)
        w = (pm.group(2) or '').strip()
        n = pm.group(3)
        ports.append((n, d, w))
    return ports

# ---- 抠 golden 模块体里被 SimTop "bore"(BoringUtils 跨模块引用)直接探出的内部
#      探针 wire, 在全端口 wrapper 里原样复刻, 让顶层 XMR 能解析。
#
# 背景: firtool 给某些 FU(浮点 FAlu/FMA/FDivSqrt/FCVT)的非法操作码断言生成
#   `wire _GEN = io_in_valid & io_in_bits_ctrl_fuOpType == 9'hFF;`, 并经 BoringUtils
#   把这个 _GEN 探到 SimTop(SimTop.sv 里 `.x1_bore_NNN (...exus_N.Falu._GEN)`)。
#   重写 wrapper 没有这个 net → 顶层 XMRE "token '_GEN' ... cannot resolve"。
#   _GEN 是 **纯端口组合**(只依赖 golden 端口), 故在 wrapper 里照抄这条 wire 即可
#   忠实复刻探针值, 让 bore 解析通过(断言本身 sim-only, 不参与 difftest 架构比对)。
#
# 提取规则(保守): 在 golden 模块体(端口块之后)抓 module 作用域(depth==0,
#   不在子例化的命名块里)的顶层 `wire [..] NAME = <expr>;`, 其中 NAME 形如 `_GEN`
#   或 `_GEN_<n>`(firtool 给 bore 探针的命名), 且 <expr> 内引用到的标识符都是
#   golden 端口(纯端口组合, 复刻必可编)。返回 [(decl_text, name)]。
def scavenge_bored_wires(gtext, module, port_names):
    # 截出 module 体: 从端口块结束 ");" 到对应 endmodule。
    m = re.search(
        r'\bmodule\s+' + re.escape(module) + r'\b\s*'
        r'(?:#\s*\([^)]*\)\s*)?(?:import\s+[^;]+;\s*)*\(', gtext)
    if not m:
        return []
    i = m.end(); depth = 1
    while i < len(gtext) and depth > 0:
        c = gtext[i]
        if c == '(': depth += 1
        elif c == ')': depth -= 1
        i += 1
    # i 现在指向端口块 ");" 之后; 找 endmodule。
    body_end = gtext.find('endmodule', i)
    body = gtext[i:body_end if body_end >= 0 else len(gtext)]
    # 抓 top-level wire NAME = expr;  (NAME == _GEN or _GEN_<n>)
    wire_re = re.compile(
        r'^[ \t]*wire\b([^=;]*?)\b(_GEN(?:_\d+)?)\s*=\s*([^;]+);',
        re.M)
    ident_re = re.compile(r"\b([A-Za-z_]\w*)\b")
    found = []
    seen = set()
    for wm in wire_re.finditer(body):
        width_part, name, expr = wm.group(1), wm.group(2), wm.group(3)
        if name in seen:
            continue
        # expr 里引用到的标识符必须都是端口(或 SV 字面量关键字), 否则跳过(不安全)。
        # 先剔除 SV 基数字面量(9'hFF / 1'b0 / 32'd10 ...), 否则其十六进制尾巴
        # (hFF 等)会被当成标识符误判为 "非端口"。
        expr_nolit = re.sub(r"\b\d+'[sS]?[bBoOdDhH][0-9a-fA-F_xXzZ]+", " ", expr)
        ids = set(ident_re.findall(expr_nolit))
        bad = [x for x in ids if x not in port_names
               and not re.fullmatch(r'\d+|reset|clock', x)]
        if bad:
            sys.stderr.write(
                "[gen_full_wrapper] note: bored wire %s depends on non-port %s; "
                "skip re-emit\n" % (name, bad))
            continue
        decl = "  wire%s%s = %s;" % (width_part if width_part.strip() else ' ',
                                     name, expr.strip())
        found.append((decl, name))
        seen.add(name)
    return found


def main():
    if len(sys.argv) != 4:
        sys.exit("usage: gen_full_wrapper.py <M> <golden.sv> <subset_wrapper.sv>")
    M, golden_path, subset_path = sys.argv[1], sys.argv[2], sys.argv[3]
    gtext = read(golden_path)
    stext = read(subset_path)

    gports = parse_ports(gtext, M)
    sports = parse_ports(stext, M)
    gnames = {n for (n, _, _) in gports}
    snames = {n for (n, _, _) in sports}
    gwidth = {n: w for (n, _, w) in gports}

    # subset wrapper 独有端口(golden 没有)→ 异常,工具不该发生;报错
    extra_subset = snames - gnames
    if extra_subset:
        sys.stderr.write(
            "[gen_full_wrapper] WARN subset wrapper has ports not in golden: %s\n"
            % sorted(extra_subset))

    # ---- 改名 subset wrapper: module M( -> module xs_M_subset( ----
    sub_mod = "xs_%s_subset" % M
    subset_renamed = re.sub(r'\bmodule\s+' + re.escape(M) + r'\b',
                            'module ' + sub_mod, stext, count=1)
    # 末尾 endmodule 可能带 ": M" 标签 → 去掉/改名以免重复
    subset_renamed = re.sub(r'endmodule\s*:\s*' + re.escape(M) + r'\b',
                            'endmodule', subset_renamed)

    out = []
    out.append("// " + "=" * 73)
    out.append("// FULL-PORT wrapper for module %s — generated by gen_full_wrapper.py" % M)
    out.append("// 端口与 golden 1:1; 功能子集经 %s 接重写核; golden 多余 perf/debug/" % sub_mod)
    out.append("// 背压口做直通/占位(不参与 difftest 架构比对)。")
    out.append("// " + "=" * 73)
    out.append("")
    out.append("// ---- 子集 wrapper(改名为 %s,内部例化重写核) ----" % sub_mod)
    out.append(subset_renamed.rstrip())
    out.append("")
    out.append("// ---- 全端口 wrapper(golden 同名 module %s) ----" % M)

    # 端口块: 逐行原样输出 golden 端口(对齐 golden 文本风格即可)
    decl_lines = []
    for (n, d, w) in gports:
        if w:
            decl_lines.append("  %-6s %-10s %s" % (d, w, n))
        else:
            decl_lines.append("  %-6s %-10s %s" % (d, '', n))
    out.append("module %s(" % M)
    out.append(",\n".join(decl_lines))
    out.append(");")
    out.append("")

    # 例化子集 wrapper: 只连两边都有的端口(按名直连)
    common = [n for (n, _, _) in gports if n in snames]
    out.append("  %s u_subset (" % sub_mod)
    conn = []
    for n in common:
        conn.append("    .%-44s (%s)" % (n, n))
    out.append(",\n".join(conn))
    out.append("  );")
    out.append("")

    # ---- 复刻被 SimTop bore 探出的内部探针 wire(纯端口组合), 让顶层 XMR 解析 ----
    bored = scavenge_bored_wires(gtext, M, gnames)
    if bored:
        out.append("  // ---- bored-out probe wires re-emitted for top-level XMR (BoringUtils) ----")
        for (decl, name) in bored:
            out.append(decl)
            sys.stderr.write("[gen_full_wrapper] re-emitted bored wire '%s' in module %s\n"
                             % (name, M))
        out.append("")

    # golden 独有输出 → 驱动
    golden_only = [(n, d, w) for (n, d, w) in gports if n not in snames]
    out.append("  // ---- golden 多余口驱动(直通/占位) ----")
    for (n, d, w) in golden_only:
        if d != 'output':
            # 多余输入: 声明即可, 不接(注释说明)
            out.append("  // (unused golden-only input: %s)" % n)
            continue
        # 输出: 找 io_in 对应直通
        drive = None
        if n == 'io_in_ready' and 'io_out_ready' in gnames:
            drive = 'io_out_ready'
        else:
            cand = None
            if n.startswith('io_out'):
                cand = 'io_in' + n[len('io_out'):]
            if cand and cand in gnames and gwidth.get(cand, '') == w:
                drive = cand
        if drive is not None:
            out.append("  assign %s = %s;" % (n, drive))
        else:
            # 占位 0(位宽匹配)
            out.append("  assign %s = '0;" % n)
    out.append("")
    out.append("endmodule")
    out.append("")
    sys.stdout.write("\n".join(out))

if __name__ == "__main__":
    main()
