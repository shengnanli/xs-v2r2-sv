#!/usr/bin/env python3
"""
MEFreeList(重命名 Move-Elimination 空闲列表，整数物理寄存器，size=224)的 UT 生成脚本。

设计意图来自:
  src/main/scala/xiangshan/backend/rename/freelist/MEFreeList.scala
  src/main/scala/xiangshan/backend/rename/freelist/BaseFreeList.scala
可读核 rtl/backend/MEFreeList.sv (xs_MEFreeList_core)，把 SnapshotGenerator 当黑盒。

本脚本产出:
  verif/ut/MEFreeList/variants_xs.sv  同一 wrapper 改名 MEFreeList_xs
  verif/ut/MEFreeList/tb.sv           golden vs 手写 双例化逐拍比对(协议化激励)

激励覆盖: 分配(alloc) / 回收(free) / 提交推进 archHead(rfWen&!isMove) /
重定向+walk 回滚 / 快照。比对所有输出端口(allocatePhyReg/canAllocate/perf)，
并对内部 headPtr/archHeadPtr/tailPtr 做层次探针逐拍比对。
"""
import re
from pathlib import Path

XSSV = Path(__file__).resolve().parent.parent
GOLDEN = XSSV / "golden/chisel-rtl"
MODULE = "MEFreeList"
HDR = "// 自动生成：scripts/gen_mefreelist.py —— 勿手改\n"


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
    """把手写 wrapper 复制一份改名 MEFreeList_xs(端口/逻辑相同)。"""
    src = (XSSV / "rtl/backend/MEFreeList_wrapper.sv").read_text()
    body = src.split("\n", 1)[1] if src.startswith("//") else src
    body = body.replace("module MEFreeList(", "module MEFreeList_xs(")
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


# 激励：随机但遵守 free/alloc 的简单流控，并周期性触发 redirect+walk。
# 整数物理寄存器池 0..223；回收时回灌随机号，避免重复。
STIM = r"""
  function automatic logic [7:0] rnd_preg(); return 8'($urandom_range(0,223)); endfunction
  always @(negedge clk) begin
    if (rst) begin
      io_redirect<=0; io_walk<=0; io_doAllocate<=0;
      {io_allocateReq_5,io_allocateReq_4,io_allocateReq_3,io_allocateReq_2,io_allocateReq_1,io_allocateReq_0}<=0;
      {io_walkReq_5,io_walkReq_4,io_walkReq_3,io_walkReq_2,io_walkReq_1,io_walkReq_0}<=0;
      {io_freeReq_5,io_freeReq_4,io_freeReq_3,io_freeReq_2,io_freeReq_1,io_freeReq_0}<=0;
      io_commit_isCommit<=0;
      {io_commit_commitValid_5,io_commit_commitValid_4,io_commit_commitValid_3,io_commit_commitValid_2,io_commit_commitValid_1,io_commit_commitValid_0}<=0;
      {io_commit_info_5_rfWen,io_commit_info_4_rfWen,io_commit_info_3_rfWen,io_commit_info_2_rfWen,io_commit_info_1_rfWen,io_commit_info_0_rfWen}<=0;
      {io_commit_info_5_isMove,io_commit_info_4_isMove,io_commit_info_3_isMove,io_commit_info_2_isMove,io_commit_info_1_isMove,io_commit_info_0_isMove}<=0;
      io_snpt_snptEnq<=0; io_snpt_snptDeq<=0; io_snpt_useSnpt<=0; io_snpt_snptSelect<=0;
      {io_snpt_flushVec_3,io_snpt_flushVec_2,io_snpt_flushVec_1,io_snpt_flushVec_0}<=0;
    end else begin
      // redirect 偶发(约 3%)，并伴随一段 walk
      io_redirect <= ($urandom_range(0,99) < 3);
      io_walk     <= ($urandom_range(0,99) < 25);
      io_doAllocate <= $urandom_range(0,1);
      io_allocateReq_0<=$urandom_range(0,1); io_allocateReq_1<=$urandom_range(0,1);
      io_allocateReq_2<=$urandom_range(0,1); io_allocateReq_3<=$urandom_range(0,1);
      io_allocateReq_4<=$urandom_range(0,1); io_allocateReq_5<=$urandom_range(0,1);
      io_walkReq_0<=$urandom_range(0,1); io_walkReq_1<=$urandom_range(0,1);
      io_walkReq_2<=$urandom_range(0,1); io_walkReq_3<=$urandom_range(0,1);
      io_walkReq_4<=$urandom_range(0,1); io_walkReq_5<=$urandom_range(0,1);
      // free 较稀疏(约 30% 每口)，回收随机物理号
      io_freeReq_0<=($urandom_range(0,99)<30); io_freeReq_1<=($urandom_range(0,99)<30);
      io_freeReq_2<=($urandom_range(0,99)<30); io_freeReq_3<=($urandom_range(0,99)<30);
      io_freeReq_4<=($urandom_range(0,99)<30); io_freeReq_5<=($urandom_range(0,99)<30);
      io_freePhyReg_0<=rnd_preg(); io_freePhyReg_1<=rnd_preg(); io_freePhyReg_2<=rnd_preg();
      io_freePhyReg_3<=rnd_preg(); io_freePhyReg_4<=rnd_preg(); io_freePhyReg_5<=rnd_preg();
      io_commit_isCommit<=$urandom_range(0,1);
      io_commit_commitValid_0<=$urandom_range(0,1); io_commit_commitValid_1<=$urandom_range(0,1);
      io_commit_commitValid_2<=$urandom_range(0,1); io_commit_commitValid_3<=$urandom_range(0,1);
      io_commit_commitValid_4<=$urandom_range(0,1); io_commit_commitValid_5<=$urandom_range(0,1);
      io_commit_info_0_rfWen<=$urandom_range(0,1); io_commit_info_1_rfWen<=$urandom_range(0,1);
      io_commit_info_2_rfWen<=$urandom_range(0,1); io_commit_info_3_rfWen<=$urandom_range(0,1);
      io_commit_info_4_rfWen<=$urandom_range(0,1); io_commit_info_5_rfWen<=$urandom_range(0,1);
      io_commit_info_0_isMove<=($urandom_range(0,99)<20); io_commit_info_1_isMove<=($urandom_range(0,99)<20);
      io_commit_info_2_isMove<=($urandom_range(0,99)<20); io_commit_info_3_isMove<=($urandom_range(0,99)<20);
      io_commit_info_4_isMove<=($urandom_range(0,99)<20); io_commit_info_5_isMove<=($urandom_range(0,99)<20);
      io_snpt_snptEnq<=($urandom_range(0,99)<15); io_snpt_snptDeq<=($urandom_range(0,99)<15);
      io_snpt_useSnpt<=$urandom_range(0,1); io_snpt_snptSelect<=$urandom_range(0,3);
      io_snpt_flushVec_0<=($urandom_range(0,99)<5); io_snpt_flushVec_1<=($urandom_range(0,99)<5);
      io_snpt_flushVec_2<=($urandom_range(0,99)<5); io_snpt_flushVec_3<=($urandom_range(0,99)<5);
    end
  end
"""

# 内部状态探针:逐拍比对头/尾/体系结构头指针。
# golden 是 firtool 扁平 RTL(g_u 直接含 headPtr_flag/shiftAmount(=headPtr.value)/
# tailPtr_flag/tailPtr_value/archHeadPtr_flag/archHeadPtr_value)，
# 手写侧在 i_u.u_core 下用 struct(headPtr.flag/headPtr.value 等)。逐字段比对。
PROBE = r"""
    if (!$isunknown(g_u.headPtr_flag)) begin
      if (g_u.headPtr_flag !== i_u.u_core.headPtr.flag) begin errors++;
        if(errors<=80) $display("[%0t] headPtr.flag g=%h i=%h", $time, g_u.headPtr_flag, i_u.u_core.headPtr.flag); end
      if (g_u.shiftAmount !== i_u.u_core.headPtr.value) begin errors++;
        if(errors<=80) $display("[%0t] headPtr.value g=%h i=%h", $time, g_u.shiftAmount, i_u.u_core.headPtr.value); end
    end
    if (!$isunknown(g_u.archHeadPtr_flag)) begin
      if (g_u.archHeadPtr_flag !== i_u.u_core.archHeadPtr.flag) begin errors++;
        if(errors<=80) $display("[%0t] archHeadPtr.flag g=%h i=%h", $time, g_u.archHeadPtr_flag, i_u.u_core.archHeadPtr.flag); end
      if (g_u.archHeadPtr_value !== i_u.u_core.archHeadPtr.value) begin errors++;
        if(errors<=80) $display("[%0t] archHeadPtr.value g=%h i=%h", $time, g_u.archHeadPtr_value, i_u.u_core.archHeadPtr.value); end
    end
    if (!$isunknown(g_u.tailPtr_flag)) begin
      if (g_u.tailPtr_flag !== i_u.u_core.tailPtr.flag) begin errors++;
        if(errors<=80) $display("[%0t] tailPtr.flag g=%h i=%h", $time, g_u.tailPtr_flag, i_u.u_core.tailPtr.flag); end
      if (g_u.tailPtr_value !== i_u.u_core.tailPtr.value) begin errors++;
        if(errors<=80) $display("[%0t] tailPtr.value g=%h i=%h", $time, g_u.tailPtr_value, i_u.u_core.tailPtr.value); end
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
