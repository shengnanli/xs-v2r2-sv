#!/usr/bin/env python3
# =============================================================================
# Writeback 簇 IT 生成器（勿手改产物，改此脚本后复跑）
# -----------------------------------------------------------------------------
# 后端写回网络簇：把两个重写写回核直连进一个 IT 顶层 Writeback_it：
#   · xs_WbDataPath_core  —— 写回数据通路 glue（accept 分流 / VfExe→Int 打拍 /
#                            各域仲裁器出口 → 物理寄存器写口格式化 / writeback 重定向）
#   · xs_WbFuBusyTable_core —— 写回 FU busy 表读出（纯组合 busy 位图重映射）
#
# 装配：
#   Writeback_it = WbDataPath_xs（→ xs_WbDataPath_core + golden 仲裁器/合并/DPIC 叶子）
#                + WbFuBusyTable_xs（→ xs_WbFuBusyTable_core）
#   两 wrapper 的端口逐字等于各自 golden 顶层（已 grep 核对），是 golden 叶子的 drop-in。
#   WbDataPath 的叶子（RealWBCollideChecker×5 / VldMergeUnit×2 / RealWBArbiter / DummyDPIC）
#   工程未重写、是写回仲裁/合并/difftest-sink 结构原语，按 IT 规则作两侧共享 golden 保留。
#   => 真正被 IT 首次连起来的「重写↔重写」是：两个写回相关重写核在同一顶层并行跑，
#      且 xs_WbDataPath_core glue 与其 golden 仲裁器叶子边界整簇对比 golden。
#
# tb：双例化 golden(WbDataPath u_g + WbFuBusyTable u_g2) vs Writeback_it u_i，喂相同随机
#     激励，逐拍比对两模块全部顶层输出。复用 WbDataPath UT tb 作骨架（驱动/比对/active
#     已写好），合入 WbFuBusyTable UT tb 的输入声明/输出影子/驱动/比对。
# =============================================================================
import re, os

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, "../../.."))
WBDP_TB = os.path.join(ROOT, "verif/ut/WbDataPath/tb.sv")
WBFU_TB = os.path.join(ROOT, "verif/ut/WbFuBusyTable/tb.sv")
WBDP_XS = os.path.join(ROOT, "verif/ut/WbDataPath/variants_xs.sv")
WBFU_XS = os.path.join(ROOT, "verif/ut/WbFuBusyTable/variants_xs.sv")

def read(p):
    with open(p) as f: return f.read()

# ---------------------------------------------------------------------------
# 解析 wrapper 模块端口（名 + 方向），用于 Writeback_it 端口表 + u_i 连接表
# ---------------------------------------------------------------------------
def parse_ports(path, modname):
    txt = read(path)
    m = re.search(r"module\s+%s\s*\((.*?)\);" % re.escape(modname), txt, re.S)
    body = m.group(1)
    ports = []  # (decl_line_text, name)
    for line in body.split("\n"):
        s = line.strip().rstrip(",")
        if not s: continue
        mm = re.match(r"(input|output)\s+(.*)", s)
        if not mm: continue
        name = re.split(r"[\s\]]", s)[-1]
        ports.append((s, name))
    return ports

wbdp_ports = parse_ports(WBDP_XS, "WbDataPath_xs")
wbfu_ports = parse_ports(WBFU_XS, "WbFuBusyTable_xs")

# WbFuBusyTable 与 WbDataPath 端口名零碰撞（已核对），直接拼接。
all_ports = wbdp_ports + wbfu_ports

# ---------------------------------------------------------------------------
# 生成 Writeback_it.sv
# ---------------------------------------------------------------------------
def gen_assembly():
    lines = []
    lines.append("// ============================================================================")
    lines.append("// Writeback 簇 IT 装配（后端写回网络层）—— 由 gen_it.py 生成，勿手改")
    lines.append("// ----------------------------------------------------------------------------")
    lines.append("// 顶层端口 = golden WbDataPath 端口 + golden WbFuBusyTable 端口（逐字相同，拼接，")
    lines.append("// 零碰撞）。内部并行例化两个写回相关重写核：")
    lines.append("//   WbDataPath_xs    -> xs_WbDataPath_core   （+ golden 仲裁/合并/DPIC 叶子）")
    lines.append("//   WbFuBusyTable_xs -> xs_WbFuBusyTable_core（纯组合 busy 表）")
    lines.append("// 两 wrapper 端口逐字等于各自 golden 顶层，是 golden 叶子的 drop-in。")
    lines.append("// ============================================================================")
    lines.append("module Writeback_it(")
    decl = ["  " + d for d, _ in all_ports]
    lines.append(",\n".join(decl))
    lines.append(");")
    lines.append("")
    # WbDataPath_xs instance
    lines.append("  // ---- 写回数据通路：xs_WbDataPath_core glue + golden 仲裁器/合并/DPIC 叶子 ----")
    lines.append("  WbDataPath_xs u_wbdp (")
    conns = [".%s(%s)" % (n, n) for _, n in wbdp_ports]
    lines.append("    " + ",\n    ".join(conns))
    lines.append("  );")
    lines.append("")
    # WbFuBusyTable_xs instance
    lines.append("  // ---- 写回 FU busy 表：xs_WbFuBusyTable_core（纯组合）----")
    lines.append("  WbFuBusyTable_xs u_wbfu (")
    conns = [".%s(%s)" % (n, n) for _, n in wbfu_ports]
    lines.append("    " + ",\n    ".join(conns))
    lines.append("  );")
    lines.append("")
    lines.append("endmodule")
    return "\n".join(lines) + "\n"

with open(os.path.join(HERE, "Writeback_it.sv"), "w") as f:
    f.write(gen_assembly())
print("wrote Writeback_it.sv (%d WbDataPath ports + %d WbFuBusyTable ports)"
      % (len(wbdp_ports), len(wbfu_ports)))

# ---------------------------------------------------------------------------
# 生成合并 tb.sv：以 WbDataPath UT tb 为骨架，注入 WbFuBusyTable 部分
# ---------------------------------------------------------------------------
dp = read(WBDP_TB).split("\n")
fu = read(WBFU_TB).split("\n")

def slice_lines(lines, start_pat, end_pat, inclusive_end=True):
    """取从首个匹配 start_pat 的行到首个匹配 end_pat 的行之间（行号从 0）。"""
    si = next(i for i, l in enumerate(lines) if re.search(start_pat, l))
    ei = next(i for i, l in enumerate(lines) if i > si and re.search(end_pat, l))
    return lines[si:ei + (1 if inclusive_end else 0)]

# --- WbFuBusyTable 片段提取 ---
# 输入声明：从首个 'logic ... io_in_' 到首个 'wire ... g_io_out_' 之前
fu_in_start = next(i for i, l in enumerate(fu) if re.search(r"^\s*logic .*io_in_", l))
fu_wire_start = next(i for i, l in enumerate(fu) if re.search(r"^\s*wire .*g_io_out_", l))
fu_inputs = fu[fu_in_start:fu_wire_start]
# 输出影子 wire：从 g_io_out_ 起到 'WbFuBusyTable    u_g' 之前
fu_ug = next(i for i, l in enumerate(fu) if re.search(r"WbFuBusyTable\s+u_g ", l))
fu_wires = fu[fu_wire_start:fu_ug]
# golden u_g 实例（改名 u_g2）
fu_ug_line = fu[fu_ug].replace("u_g (", "u_g2 (")
# drive() / check() / `define CK / 任务体：从 'task automatic drive' 到 'endtask'(check)
fu_drive_start = next(i for i, l in enumerate(fu) if re.search(r"task automatic drive", l))
fu_check_end = [i for i, l in enumerate(fu) if re.search(r"endtask", l)][-1]
fu_tasks = fu[fu_drive_start:fu_check_end + 1]
# 但 drive/check 任务名会和（无）冲突——WbDataPath tb 没有同名任务，安全。
# 重命名以防万一：fu 的 drive/check → fu_drive/fu_check，CK 宏 → CKFU
fu_tasks_txt = "\n".join(fu_tasks)
fu_tasks_txt = fu_tasks_txt.replace("task automatic drive(", "task automatic fu_drive(")
fu_tasks_txt = fu_tasks_txt.replace("task automatic check(", "task automatic fu_check(")
fu_tasks_txt = fu_tasks_txt.replace("`define CK(", "`define CKFU(")
fu_tasks_txt = re.sub(r"`CK\(", "`CKFU(", fu_tasks_txt)

# --- 组装合并 tb ---
out = []
# (a) header：直接用 WbDataPath tb 到第一个输入声明前（行 0..12），但要加 timescale
hdr_end = next(i for i, l in enumerate(dp) if re.search(r"^\s*logic .*io_", l))
out += dp[0:hdr_end]
# (b) WbDataPath 输入声明 + WbFuBusyTable 输入声明
dp_in_end = next(i for i, l in enumerate(dp) if re.search(r"^\s*wire .*g_io_", l))
out += dp[hdr_end:dp_in_end]
out.append("  // ---- WbFuBusyTable 输入声明 ----")
out += fu_inputs
# (c) WbDataPath 输出影子 + act 数组 + WbFuBusyTable 输出影子
#     WbDataPath 输出 wire 从 dp_in_end 到 u_g 实例前；其中含 'int unsigned act[509]'
dp_ug = next(i for i, l in enumerate(dp) if re.search(r"WbDataPath\s+u_g ", l))
out += dp[dp_in_end:dp_ug]
out.append("  // ---- WbFuBusyTable 输出影子 wire ----")
out += fu_wires
# (d) golden 实例：WbDataPath u_g + WbFuBusyTable u_g2，IT u_i = Writeback_it
out.append(dp[dp_ug])                                   # WbDataPath u_g
out.append(fu_ug_line)                                  # WbFuBusyTable u_g2
# u_i：原 WbDataPath_xs u_i 改成 Writeback_it u_i，并把 WbFuBusyTable 端口追加进连接表
dp_ui = next(i for i, l in enumerate(dp) if re.search(r"WbDataPath_xs u_i ", l))
ui_line = dp[dp_ui]
ui_line = ui_line.replace("WbDataPath_xs u_i (", "Writeback_it u_i (")
# 在结尾 ');' 前插入 WbFuBusyTable 端口连接：
#   输入端口连 tb 同名激励网；输出端口连 IT 影子网 i_<name>（与 WbDataPath u_i 输出一致）。
def fu_ui_conn(decl, name):
    is_out = decl.lstrip().startswith("output")
    rhs = ("i_" + name) if is_out else name
    return ".%s(%s)" % (name, rhs)
fu_conns = ", ".join(fu_ui_conn(d, n) for d, n in wbfu_ports)
ui_line = ui_line.rstrip()
assert ui_line.endswith(");"), ui_line[-40:]
ui_line = ui_line[:-2] + ", " + fu_conns + ");"
out.append(ui_line)
# (e) WbDataPath 驱动块（negedge）：在其 else 分支末尾追加 fu_drive() 调用
#     驱动块结构: always @(negedge clk) begin / if(rst) begin .. end else begin .. end / end
#     驱动块在 'int unsigned act' 检查块声明前结束。
dp_drv_start = next(i for i, l in enumerate(dp) if i > dp_ui and re.search(r"always @\(negedge clk\) begin", l))
dp_act = next(i for i, l in enumerate(dp) if i > dp_drv_start and re.search(r"int unsigned act", l))
drv_block = dp[dp_drv_start:dp_act]                       # 含驱动 always 整块
# 驱动块内的 bare 'end'：倒数第二个 = else 分支 end（最后一个 = 外层 always end）
end_idxs = [i for i, l in enumerate(drv_block) if re.match(r"^\s*end\s*$", l)]
ins_at = end_idxs[-2]  # else 分支 end，在它前插 fu 驱动
drv_block = drv_block[:ins_at] + [
    "      // ---- WbFuBusyTable 输入随机驱动（与 WbDataPath 同拍喂激励）----",
    "      fu_drive();",
] + drv_block[ins_at:]
out += drv_block
# (f) act 数组 + 检查块：从 'int unsigned act' 到 initial 之前；末尾 'end' 前插 fu_check()
dp_initial = next(i for i, l in enumerate(dp) if re.search(r"^\s*initial begin", l))
chk_block = dp[dp_act:dp_initial]
# chk_block 末尾是检查 always 块的 'end'。在最后 'end' 前插入 fu_check()
end_idxs = [i for i, l in enumerate(chk_block) if re.match(r"^\s*end\s*$", l)]
ins_at = end_idxs[-1]
chk_block = chk_block[:ins_at] + [
    "    // ---- WbFuBusyTable 输出比对（同拍）----",
    "    fu_check();",
] + chk_block[ins_at:]
out += chk_block
# (g) WbFuBusyTable 任务体（drive/check 重命名版）
out.append("  // ---- WbFuBusyTable drive/check 任务（合入 WbDataPath 驱动/比对块调用）----")
out.append(fu_tasks_txt)
# (h) initial / finish 块（用 WbDataPath 的，它统计 active_outputs）
out += dp[dp_initial:]

with open(os.path.join(HERE, "tb.sv"), "w") as f:
    f.write("\n".join(out) + "\n")
print("wrote tb.sv (%d lines)" % len(out))
