#!/usr/bin/env python3
"""RenameTable 家族四个变体 wrapper 的生成器。

为什么生成：四个 wrapper 的端口表分别是 159 / 139 / 175 / 62 个展平端口，
纯机械（golden 逐位同名同序）。端口顺序由 port_contract_lint.py 以 order=fail
把守，手抄必错。**端口表直接从 G1-canonical 的 golden 文件里读**，
而不是照着我的理解重写一遍 —— 这样"顺序/宽度/有没有这个端口"三件事
按构造与 golden 一致。

核体（xs_RenameTable_core）在 rtl/backend/RenameTable.sv 里，手写、不生成；
本脚本只写四个 wrapper：
  · RenameTable.sv 里 BEGIN/END GENERATED(RenameTable-wrapper) 之间就地替换；
  · RenameTable_{1,2,3}.sv 整份生成。

用法: python3 gen_variants.py [--check]
"""
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.abspath(os.path.join(HERE, "..", "..", ".."))
GOLDEN = os.environ.get("GOLDEN_RTL", "/home/eda/xs-env/G1-canonical/golden-rtl")
RTL = os.path.join(REPO, "rtl", "backend")

# name -> (N_ENTRIES, ADDR_W, N_READ, INIT_IDENTITY, DIFF_N, DIFF_OFF,
#          DBG_N, DBG_OFF, HAS_NEED_FREE, HAS_DBG, snapshot 变体号, 中文说明)
VARIANTS = {
    "RenameTable": dict(
        N=32, AW=5, NR=12, ident=0, diff=(32, 0), dbg=(32, 0),
        need_free=1, has_dbg=1, snap=4,
        why="Reg_I 整数 RAT：32 个逻辑整数寄存器，每条指令 2 个源操作数 x RenameWidth 6 = 12 个读口"),
    "RenameTable_1": dict(
        N=34, AW=6, NR=18, ident=1, diff=(32, 0), dbg=(0, 0),
        need_free=0, has_dbg=0, snap=5,
        why="Reg_F 浮点 RAT：34 格、3 源操作数 x 6 = 18 个读口；"
            "golden 未导出 debug_rdata 与 need_free（fpRat 在 RenameTableWrapper 里"
            "既没有 dontTouch、need_free 也没人读，整条锥被 firtool 裁掉）"),
    "RenameTable_2": dict(
        N=47, AW=6, NR=18, ident=1, diff=(31, 1), dbg=(31, 1),
        need_free=1, has_dbg=1, snap=6,
        why="Reg_V 向量 RAT：47 格、3 源操作数 x 6 = 18 个读口；"
            "debug_rdata 与 diffRatBase 都**从第 1 格开始**导 31 格"
            "（Chisel 里是 arch_table.drop(1) / spec_table_next.drop(v0Entries)）"),
    "RenameTable_3": dict(
        N=1, AW=0, NR=6, ident=1, diff=(1, 0), dbg=(1, 0),
        need_free=1, has_dbg=1, snap=7,
        why="Reg_V0 与 Reg_Vl 共用的变体：V0LogicRegs = VlLogicRegs = 1，"
            "log2Ceil(1)=0 所以**一个 addr 端口都没有**，表只有一格；"
            "v0Rat 与 vlRat 两个实例被 firtool 判为同构、合并成同一个模块，"
            "在 RenameTableWrapper 里例化两次"),
}

HEAD = {
    "RenameTable_1": """// =============================================================================
// RenameTable_1 —— RenameTable 家族变体：浮点 RAT（Reg_F）
//
// 规模：34 格 x 8 位、地址 6 位、18 个读口（3 源操作数 x RenameWidth 6）、
//       6 个投机写口 + 6 个体系结构写口、快照件 SnapshotGenerator_5（34 x 8）。
// 复位初值是 identity（第 i 格填 i），不是全 0 —— 与整数 RAT 不同。
//
// ★本变体比别的变体少两组输出，是 firtool DCE 的结果，不是我漏写★：
//   golden RenameTable_1 的端口表里**没有** io_debug_rdata_* 与 io_need_free_*，
//   寄存器表里连 need_free 那 6 个寄存器都没有。原因在 RenameTableWrapper：
//   vecRat / v0Rat / vlRat 都带 dontTouch 把全部端口钉住，intRat 的 need_free
//   被 io.int_need_free 真的用到，而 fpRat 两样都没有。
//   所以核的这两组输出在本文件里悬空（need_free 那侧还会让核**不生成**
//   那 6 个寄存器，见 xs_RenameTable_core 的 HAS_NEED_FREE 参数）。
// 核体见 rtl/backend/RenameTable.sv，本文件仅设参数、展平端口、例化快照件。
// ★本文件由 verif/ut/RenameTable/gen_variants.py 生成，改请改生成器★
// =============================================================================""",
    "RenameTable_2": """// =============================================================================
// RenameTable_2 —— RenameTable 家族变体：向量 RAT（Reg_V）
//
// 规模：47 格 x 8 位、地址 6 位、18 个读口（3 源操作数 x RenameWidth 6）、
//       6 个投机写口 + 6 个体系结构写口、快照件 SnapshotGenerator_6（47 x 8）。
// 复位初值是 identity（第 i 格填 i）。
//
// ★本变体的两组调试输出都从第 1 格起算，只导 31 格★（不是 0..30 也不是 0..46）：
//   Chisel 里 debug_rdata 取 `arch_table.drop(1).take(vecEntries)`、
//   diffRatBase 取 `spec_table_next.drop(v0Entries).take(vecEntries)`，
//   而 v0Entries = 1、vecEntries = 31。跳过的第 0 格是 v0 那一格，
//   它由 RenameTable_3（v0Rat）单独管。
// 核体见 rtl/backend/RenameTable.sv，本文件仅设参数、展平端口、例化快照件。
// ★本文件由 verif/ut/RenameTable/gen_variants.py 生成，改请改生成器★
// =============================================================================""",
    "RenameTable_3": """// =============================================================================
// RenameTable_3 —— RenameTable 家族变体：v0 / vl 单格 RAT（Reg_V0 与 Reg_Vl 合并）
//
// 规模：**1 格** x 8 位、地址 **0 位**、6 个读口（1 源操作数 x RenameWidth 6）、
//       6 个投机写口 + 6 个体系结构写口、快照件 SnapshotGenerator_7（1 x 8）。
//
// ★"0 位地址"是本变体全部特殊性的来源★：V0LogicRegs = VlLogicRegs = 1，
//   log2Ceil(1) = 0，于是 golden 的端口表里**一个 addr 端口都没有**
//   （readPorts 只剩 hold/data，specWritePorts 与 archWritePorts 只剩 wen/data），
//   而且**一个地址寄存器都没有**（t1_raddr / t1_wSpec_addr 全被折叠掉，
//   原来的 t1_wSpec_j_wen 直接被 firtool 改名成 matchVec_j）。
//   核用 ADDR_W=0 走 g_addr_const 分支：地址恒 0、不生成任何地址寄存器。
//
// ★一个模块两个实例★：RenameTableWrapper 里的 v0Rat 与 vlRat 参数完全相同
//   （都是 1 格、1 个读口 x 6、identity 初值），firtool 判为同构后合并成本模块，
//   在 wrapper 里例化两次。它俩在 Chisel 里唯一的区别是 debug_v0 还是 debug_vl，
//   两者都等于 arch_table(0)，合并后统一叫 io_debug_v0。
// 核体见 rtl/backend/RenameTable.sv，本文件仅设参数、展平端口、例化快照件。
// ★本文件由 verif/ut/RenameTable/gen_variants.py 生成，改请改生成器★
// =============================================================================""",
}


def golden_ports(top):
    """从 golden 文件里按原序读端口表，返回 [(dir, width_str, name), ...]。"""
    src = open(os.path.join(GOLDEN, top + ".sv")).read()
    m = re.search(r'^module\s+%s\s*\((.*?)\n\);' % re.escape(top), src, re.S | re.M)
    if not m:
        raise SystemExit("无法解析 golden 端口表: " + top)
    out = []
    for line in m.group(1).split("\n"):
        line = line.strip().rstrip(",")
        if not line:
            continue
        pm = re.match(r'(input|output)\s+(\[[^\]]*\]\s+)?(\w+)$', line)
        if not pm:
            raise SystemExit("端口行无法解析(%s): %r" % (top, line))
        out.append((pm.group(1), (pm.group(2) or "").strip(), pm.group(3)))
    return out


def wrapper(top):
    v = VARIANTS[top]
    N, AW, NR = v["N"], v["AW"], v["NR"]
    NW = 6
    DIFF_N, DIFF_OFF = v["diff"]
    DBG_N, DBG_OFF = v["dbg"]
    AWS = AW if AW > 0 else 1          # 核对外的 addr 位宽（AW=0 时用 1 位常量 0）
    ports = golden_ports(top)
    names = set(p[2] for p in ports)
    L = []
    a = L.append

    a("module %s(" % top)
    w = max(len(p[1]) for p in ports)
    for k, (d, wd, n) in enumerate(ports):
        a("  %-6s %-*s %s%s" % (d, w, wd, n, "," if k + 1 < len(ports) else ""))
    a(");")
    # ---- 内部数组 ----
    a("  logic            rd_hold [%d];" % NR)
    a("  logic [%d:0]      rd_addr [%d];" % (AWS - 1, NR))
    a("  logic [7:0]      rd_data [%d];" % NR)
    a("  logic            sw_wen  [%d];" % NW)
    a("  logic [%d:0]      sw_addr [%d];" % (AWS - 1, NW))
    a("  logic [7:0]      sw_data [%d];" % NW)
    a("  logic            aw_wen  [%d];" % NW)
    a("  logic [%d:0]      aw_addr [%d];" % (AWS - 1, NW))
    a("  logic [7:0]      aw_data [%d];" % NW)
    a("  logic [7:0]      old_pdest [%d];" % NW)
    a("  logic            need_free [%d];" % NW)
    a("  logic [7:0]      diffRatBase [%d];" % max(DIFF_N, 1))
    a("  logic [7:0]      debug_rdata [%d];" % max(DBG_N, 1))
    a("  logic [7:0]      debug_arch0;")
    a("  logic [7:0]      snpt_enq_data [%d];" % N)
    a("  logic            snpt_enq, snpt_deq, snpt_redirect;")
    a("  logic [3:0]      snpt_flush;")
    a("  logic [7:0]      snpt_rdata [4][%d];" % N)
    a("")
    # ---- 输入展平 ----
    for r in range(NR):
        a("  assign rd_hold[%d] = io_readPorts_%d_hold;" % (r, r))
        if AW > 0:
            a("  assign rd_addr[%d] = io_readPorts_%d_addr;" % (r, r))
        else:
            a("  assign rd_addr[%d] = 1'b0;   // golden 无 addr 端口（表只有一格）" % r)
    for j in range(NW):
        a("  assign sw_wen[%d]  = io_specWritePorts_%d_wen;" % (j, j))
        a("  assign sw_data[%d] = io_specWritePorts_%d_data;" % (j, j))
        a("  assign sw_addr[%d] = %s;" % (
            j, ("io_specWritePorts_%d_addr" % j) if AW > 0 else "1'b0"))
        a("  assign aw_wen[%d]  = io_archWritePorts_%d_wen;" % (j, j))
        a("  assign aw_data[%d] = io_archWritePorts_%d_data;" % (j, j))
        a("  assign aw_addr[%d] = %s;" % (
            j, ("io_archWritePorts_%d_addr" % j) if AW > 0 else "1'b0"))
    a("")
    # ---- 输出展平 ----
    for r in range(NR):
        a("  assign io_readPorts_%d_data = rd_data[%d];" % (r, r))
    for j in range(NW):
        a("  assign io_old_pdest_%d = old_pdest[%d];" % (j, j))
    if "io_need_free_0" in names:
        for j in range(NW):
            a("  assign io_need_free_%d = need_free[%d];" % (j, j))
    else:
        a("  // golden 未导出 need_free（见文件头），核的该输出悬空")
    for k in range(DIFF_N):
        a("  assign io_diffRatBase_%d = diffRatBase[%d];" % (k, k))
    if DBG_N:
        for k in range(DBG_N):
            a("  assign io_debug_rdata_%d = debug_rdata[%d];" % (k, k))
    else:
        a("  // golden 未导出 debug_rdata（见文件头），核的该输出悬空")
    if "io_debug_v0" in names:
        a("  assign io_debug_v0 = debug_arch0;")
    a("")
    # ---- 核例化 ----
    a("  xs_RenameTable_core #(")
    a("    .N_ENTRIES(%d), .ADDR_W(%d), .N_READ(%d), .N_WRITE(%d)," % (N, AW, NR, NW))
    a("    .INIT_IDENTITY(1'b%d), .DIFF_N(%d), .DIFF_OFF(%d)," % (v["ident"], DIFF_N, DIFF_OFF))
    a("    .DBG_N(%d), .DBG_OFF(%d)," % (max(DBG_N, 1), DBG_OFF))
    a("    .HAS_NEED_FREE(1'b%d), .HAS_DBG(1'b%d)" % (v["need_free"], v["has_dbg"]))
    a("  ) u_core (")
    a("    .clock                  (clock),")
    a("    .reset                  (reset),")
    a("    .io_redirect            (io_redirect),")
    a("    .io_readPorts_hold      (rd_hold),")
    a("    .io_readPorts_addr      (rd_addr),")
    a("    .io_readPorts_data      (rd_data),")
    a("    .io_specWritePorts_wen  (sw_wen),")
    a("    .io_specWritePorts_addr (sw_addr),")
    a("    .io_specWritePorts_data (sw_data),")
    a("    .io_archWritePorts_wen  (aw_wen),")
    a("    .io_archWritePorts_addr (aw_addr),")
    a("    .io_archWritePorts_data (aw_data),")
    a("    .io_old_pdest           (old_pdest),")
    a("    .io_need_free           (need_free),")
    a("    .io_snpt_snptEnq        (io_snpt_snptEnq),")
    a("    .io_snpt_snptDeq        (io_snpt_snptDeq),")
    a("    .io_snpt_useSnpt        (io_snpt_useSnpt),")
    a("    .io_snpt_snptSelect     (io_snpt_snptSelect),")
    a("    .io_snpt_flushVec       ({io_snpt_flushVec_3, io_snpt_flushVec_2,")
    a("                              io_snpt_flushVec_1, io_snpt_flushVec_0}),")
    a("    .io_diffRatBase         (diffRatBase),")
    a("    .io_debug_rdata         (debug_rdata),")
    a("    .io_debug_arch0         (debug_arch0),")
    a("    .snpt_enq_data          (snpt_enq_data),")
    a("    .snpt_enq               (snpt_enq),")
    a("    .snpt_deq               (snpt_deq),")
    a("    .snpt_redirect          (snpt_redirect),")
    a("    .snpt_flush             (snpt_flush),")
    a("    .snpt_rdata             (snpt_rdata)")
    a("  );")
    a("")
    # ---- 快照件例化（实例名与 golden 一致，FM 两侧层次路径才对得上）----
    sg = "SnapshotGenerator_%d" % v["snap"]
    a("  // 实例名 snapshots_snapshotGen 与 golden 逐字一致：FM 按层次路径配对内部比对点。")
    a("  %s snapshots_snapshotGen (" % sg)
    a("    .clock       (clock),")
    a("    .reset       (reset),")
    a("    .io_enq      (snpt_enq),")
    for i in range(N):
        a("    .io_enqData_%-3d(snpt_enq_data[%d])," % (i, i))
    a("    .io_deq      (snpt_deq),")
    a("    .io_redirect (snpt_redirect),")
    for k in range(4):
        a("    .io_flushVec_%d(snpt_flush[%d])," % (k, k))
    for s in range(4):
        for i in range(N):
            last = (s == 3 and i == N - 1)
            a("    .io_snapshots_%d_%-3d(snpt_rdata[%d][%d])%s"
              % (s, i, s, i, "" if last else ","))
    a("  );")
    a("endmodule")
    return "\n".join(L) + "\n"


def build_files():
    out = {}
    # 基础变体：就地替换 RenameTable.sv 的 GENERATED 段
    base = open(os.path.join(RTL, "RenameTable.sv"), encoding="utf-8").read()
    beg = "// BEGIN GENERATED(RenameTable-wrapper)\n"
    end = "// END GENERATED\n"
    i, j = base.index(beg), base.index(end)
    body = ("// golden 同名 wrapper —— 整数 RAT（Reg_I）：32 格 / 5 位地址 / 12 读口 /\n"
            "// 全 0 初值 / 快照件 SnapshotGenerator_4。端口表与 golden 逐位同名同序。\n"
            + wrapper("RenameTable"))
    out[os.path.join(RTL, "RenameTable.sv")] = base[:i + len(beg)] + body + base[j:]
    for top in ("RenameTable_1", "RenameTable_2", "RenameTable_3"):
        out[os.path.join(RTL, top + ".sv")] = HEAD[top] + "\n" + wrapper(top)
    return out


if __name__ == "__main__":
    files = build_files()
    if "--check" in sys.argv:
        bad = 0
        for path, txt in files.items():
            cur = open(path, encoding="utf-8").read() if os.path.exists(path) else ""
            if cur != txt:
                print("ERROR: %s 与生成器结果不一致" % path)
                bad = 1
        sys.exit(bad)
    for path, txt in files.items():
        open(path, "w", encoding="utf-8").write(txt)
        print("wrote", path)
