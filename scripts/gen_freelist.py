#!/usr/bin/env python3
"""
FreeList(访存队列空闲槽位表，size=16/双口)的 UT 生成脚本。

设计意图来自 src/main/scala/xiangshan/mem/lsqueue/FreeList.scala。
可读核 rtl/memblock/FreeList.sv (xs_FreeList_core)。

产出:
  verif/ut/FreeList/variants_xs.sv  把手写 wrapper 改名 FreeList_xs
  verif/ut/FreeList/tb.sv           golden vs 手写 双例化逐拍比对(随机释放位图+分配)

激励覆盖: 随机 io_free 位图、随机 doAllocate；比对 allocateSlot/validCount/empty，
并对内部 headPtr/tailPtr/freeMask/freeSlotCnt 做层次探针逐拍比对。
"""
import re
from pathlib import Path

XSSV = Path(__file__).resolve().parent.parent
GOLDEN = XSSV / "golden/chisel-rtl"
MODULE = "FreeList"
HDR = "// 自动生成：scripts/gen_freelist.py —— 勿手改\n"


def ports(name):
    text = (GOLDEN / f"{name}.sv").read_text()
    m = re.search(rf"^module {re.escape(name)}\((.*?)\n\);", text, re.S | re.M)
    res = []
    for line in m.group(1).splitlines():
        pm = re.match(r"\s*(input|output)\s+(?:\[(\d+):0\])?\s*(\w+),?\s*$", line)
        if pm:
            res.append((pm.group(1), int(pm.group(2)) + 1 if pm.group(2) else 1, pm.group(3)))
    return res


def make_variant():
    src = (XSSV / "rtl/memblock/FreeList_wrapper.sv").read_text()
    body = src.split("\n", 1)[1] if src.startswith("//") else src
    body = body.replace("module FreeList(", "module FreeList_xs(")
    return HDR + body


def make_tb(ps):
    ins = [(w, n) for d, w, n in ps if d == "input" and n not in ("clock", "reset")]
    outs = [(w, n) for d, w, n in ps if d == "output"]

    def decl(w, n, p=""):
        ws = f"[{w-1}:0] " if w > 1 else ""
        return f"  logic {ws}{p}{n};"

    L = [HDR, "`timescale 1ns/1ps", "module tb;",
         "  int unsigned NCYCLES = 200000;",
         "  bit clk = 0, rst;",
         "  int errors = 0, checks = 0;",
         "  always #5 clk = ~clk;", ""]
    for w, n in ins:
        L.append(decl(w, n))
    for w, n in outs:
        L.append(decl(w, n, "g_"))
        L.append(decl(w, n, "i_"))
    L.append("")

    def inst(mod, pre):
        c = [".clock(clk)", ".reset(rst)"]
        c += [f".{n}({n})" for _, n in ins]
        c += [f".{n}({pre}{n})" for _, n in outs]
        return f"  {mod} {pre[0]}_u (" + ", ".join(c) + ");"

    L.append(inst(MODULE, "g_"))
    L.append(inst(MODULE + "_xs", "i_"))
    L.append("")
    L.append(STIM)
    L.append("  always @(negedge clk) if (!rst) begin")
    L.append("    #4; checks++;")
    for w, n in outs:
        L.append(f"    if (!$isunknown(g_{n}) && g_{n} !== i_{n}) begin errors++;")
        L.append(f"      if(errors<=80) $display(\"[%0t] {n} g=%h i=%h\", $time, g_{n}, i_{n}); end")
    L.append(PROBE)
    L.append("  end")
    L.append(EPILOG)
    L.append("endmodule")
    return "\n".join(L)


# 协议合法激励：FreeList 假设上游遵守流控——只在有空闲时分配、只释放当前已分配
# 的槽位(不重复释放)。本 tb 用 outstanding[] 跟踪每个槽位是否"已分配未释放"，据此
# 约束 doAllocate(占用 < SIZE 才分配)与 io_free(只释放已占用且未在途释放的槽位)，
# 避免构造队列溢出/重复释放等非法状态(那些状态不在设计契约内)。
# 注：用 golden 的 allocateSlot 输出来记账(两侧分配结果一致，UT 会逐拍校验)。
STIM = r"""
  bit [15:0] outstanding;   // 槽位是否已分配未释放
  bit [15:0] freeing;       // 本拍正在释放的槽位(避免重复释放)
  int occ;                  // 已占用计数
  always @(negedge clk) begin
    if (rst) begin
      io_free <= 16'h0; io_doAllocate_0 <= 1'b0; io_doAllocate_1 <= 1'b0;
      outstanding <= 16'h0; occ <= 0;
    end else begin
      // --- 记账上一拍的分配/释放结果 ---
      // 上一拍 doAllocate 取走的槽位(用 golden 输出)标记为已占用
      if (io_doAllocate_0) begin outstanding[g_io_allocateSlot_0] <= 1'b1; end
      if (io_doAllocate_1) begin outstanding[g_io_allocateSlot_1] <= 1'b1; end
      // 上一拍发出的 io_free 标记为已释放
      for (int k = 0; k < 16; k++) if (io_free[k]) outstanding[k] <= 1'b0;

      // --- 生成本拍激励 ---
      // 分配流控：上游须保证不溢出。这里用 DUT 的 validCount(已占用数)留出余量，
      // 确保任何拍最多分配 2 个时占用不超过 SIZE(留 4 余量覆盖在途释放抖动)。
      io_doAllocate_0 <= (g_io_validCount < 16 - 4) && $urandom_range(0,1);
      io_doAllocate_1 <= (g_io_validCount < 16 - 4) && $urandom_range(0,1);
      // 释放：从已占用槽位里随机挑若干个释放(每个约 25%)，不碰未占用槽位
      freeing = 16'h0;
      for (int k = 0; k < 16; k++)
        if (outstanding[k] && ($urandom_range(0,99) < 25)) freeing[k] = 1'b1;
      io_free <= freeing;
    end
  end
"""

PROBE = r"""
    if (!$isunknown(g_u.headPtr_flag)) begin
      if (g_u.headPtr_flag !== i_u.u_core.headPtr.flag) begin errors++;
        if(errors<=80) $display("[%0t] headPtr.flag g=%h i=%h", $time, g_u.headPtr_flag, i_u.u_core.headPtr.flag); end
      if (g_u.headPtr_value !== i_u.u_core.headPtr.value) begin errors++;
        if(errors<=80) $display("[%0t] headPtr.value g=%h i=%h", $time, g_u.headPtr_value, i_u.u_core.headPtr.value); end
      if (g_u.tailPtr_flag !== i_u.u_core.tailPtr.flag) begin errors++;
        if(errors<=80) $display("[%0t] tailPtr.flag g=%h i=%h", $time, g_u.tailPtr_flag, i_u.u_core.tailPtr.flag); end
      if (g_u.tailPtr_value !== i_u.u_core.tailPtr.value) begin errors++;
        if(errors<=80) $display("[%0t] tailPtr.value g=%h i=%h", $time, g_u.tailPtr_value, i_u.u_core.tailPtr.value); end
      if (g_u.freeMask !== i_u.u_core.freeMask) begin errors++;
        if(errors<=80) $display("[%0t] freeMask g=%h i=%h", $time, g_u.freeMask, i_u.u_core.freeMask); end
      if (g_u.freeSlotCnt !== i_u.u_core.freeSlotCnt) begin errors++;
        if(errors<=80) $display("[%0t] freeSlotCnt g=%h i=%h", $time, g_u.freeSlotCnt, i_u.u_core.freeSlotCnt); end
    end
"""

EPILOG = r"""  initial begin
    rst = 1; repeat (8) @(posedge clk); rst = 0;
    repeat (NCYCLES) @(posedge clk);
    $display("checks=%0d errors=%0d", checks, errors);
    if (errors == 0 && checks > 1000) $display("TEST PASSED"); else $display("TEST FAILED");
    $finish;
  end"""


def main():
    ps = ports(MODULE)
    ut = XSSV / f"verif/ut/{MODULE}"
    ut.mkdir(parents=True, exist_ok=True)
    (ut / "variants_xs.sv").write_text(make_variant())
    (ut / "tb.sv").write_text(make_tb(ps))
    print("generated:", ut / "variants_xs.sv", ut / "tb.sv")


if __name__ == "__main__":
    main()
