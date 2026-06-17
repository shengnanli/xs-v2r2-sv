#!/usr/bin/env python3
"""
RenameBuffer(重命名缓冲 Rab)的 wrapper + UT 生成脚本。

设计意图来自 src/main/scala/xiangshan/backend/rob/Rab.scala (class RenameBuffer)。
可读核 rtl/backend/RenameBuffer.sv (xs_RenameBuffer_core)，把 SnapshotGenerator 当黑盒。

产出:
  rtl/backend/RenameBuffer_wrapper.sv   golden 同名 RenameBuffer(扁平端口 → 核 struct 数组)
  verif/ut/RenameBuffer/variants_xs.sv  同一 wrapper 改名 RenameBuffer_xs
  verif/ut/RenameBuffer/tb.sv           golden vs 手写 双例化逐拍比对(随机激励)

激励覆盖: rename 入队 / commit 出队 / redirect(快照 walk + 无快照 special_walk)/ walkEnd。
比对所有输出端口(canEnq/commits/status/toVecExcpMod/diffCommits)，并对内部
rename_buffer / enq_ptr / deq_ptr / walk_ptr / state / *_size 做层次探针逐拍比对。
"""
import re
from pathlib import Path

XSSV = Path(__file__).resolve().parent.parent
GOLDEN = XSSV / "golden/chisel-rtl"
MODULE = "RenameBuffer"
HDR = "// 自动生成：scripts/gen_renamebuffer.py —— 勿手改\n"

RENAME_WIDTH = 6
COMMIT_WIDTH = 6
NUM_DIFF = 255


def ports(name):
    text = (GOLDEN / f"{name}.sv").read_text()
    m = re.search(rf"^module {re.escape(name)}\((.*?)\n\);", text, re.S | re.M)
    res = []
    for line in m.group(1).splitlines():
        pm = re.match(r"\s*(input|output)\s+(?:\[(\d+):0\])?\s*(\w+),?\s*$", line)
        if pm:
            res.append((pm.group(1), int(pm.group(2)) + 1 if pm.group(2) else 1, pm.group(3)))
    return res


REQ_FIELDS = ["valid", "ldest", "pdest", "rfWen", "fpWen", "vecWen", "v0Wen", "vlWen", "isMove"]
INFO_FIELDS = ["ldest", "pdest", "rfWen", "fpWen", "vecWen", "v0Wen", "vlWen", "isMove"]


def make_wrapper(ps, modname="RenameBuffer"):
    L = [HDR,
         "// golden 同名扁平端口 → 可读核 xs_RenameBuffer_core 的机械适配层",
         f"module {modname}",
         "  import renamebuffer_pkg::*;",
         "("]
    decls = []
    for d, w, n in ps:
        ws = f"[{w-1}:0] " if w > 1 else "       "
        kw = "input " if d == "input" else "output"
        decls.append(f"  {kw} {ws}{n}")
    L.append(",\n".join(decls))
    L.append(");")

    # 中间 struct/数组信号
    L.append("  rab_req_t   req     [RENAME_WIDTH];")
    L.append("  logic [SNAPSHOT_NUM-1:0] flushv;")
    L.append("  logic       cE, cEd;")
    L.append("  logic       isCommit, isWalk;")
    L.append("  logic [COMMIT_WIDTH-1:0] cValid, wValid;")
    L.append("  rab_info_t  cInfo  [COMMIT_WIDTH];")
    L.append("  logic       sWalkEnd, sCommitEnd;")
    L.append("  logic       veValid [COMMIT_WIDTH];")
    L.append("  logic [LDEST_W-1:0] veLreg [COMMIT_WIDTH];")
    L.append("  logic [PDEST_W-1:0] vePreg [COMMIT_WIDTH];")
    L.append("  logic       dValid [NUM_DIFF];")
    L.append("  rab_info_t  dInfo  [NUM_DIFF];")
    L.append("")

    # 入队请求打包
    for i in range(RENAME_WIDTH):
        L.append(f"  assign req[{i}].valid  = io_req_{i}_valid;")
        L.append(f"  assign req[{i}].ldest  = io_req_{i}_bits_ldest;")
        L.append(f"  assign req[{i}].pdest  = io_req_{i}_bits_pdest;")
        L.append(f"  assign req[{i}].rfWen  = io_req_{i}_bits_rfWen;")
        L.append(f"  assign req[{i}].fpWen  = io_req_{i}_bits_fpWen;")
        L.append(f"  assign req[{i}].vecWen = io_req_{i}_bits_vecWen;")
        L.append(f"  assign req[{i}].v0Wen  = io_req_{i}_bits_v0Wen;")
        L.append(f"  assign req[{i}].vlWen  = io_req_{i}_bits_vlWen;")
        L.append(f"  assign req[{i}].isMove = io_req_{i}_bits_isMove;")
    L.append("  assign flushv = {io_snpt_flushVec_3, io_snpt_flushVec_2, io_snpt_flushVec_1, io_snpt_flushVec_0};")
    L.append("")

    # 输出拆解
    L.append("  assign io_canEnq = cE;")
    L.append("  assign io_canEnqForDispatch = cEd;")
    L.append("  assign io_commits_isCommit = isCommit;")
    L.append("  assign io_commits_isWalk = isWalk;")
    L.append("  assign io_status_walkEnd = sWalkEnd;")
    L.append("  assign io_status_commitEnd = sCommitEnd;")
    for i in range(COMMIT_WIDTH):
        L.append(f"  assign io_commits_commitValid_{i} = cValid[{i}];")
        L.append(f"  assign io_commits_walkValid_{i} = wValid[{i}];")
        for f in INFO_FIELDS:
            L.append(f"  assign io_commits_info_{i}_{f} = cInfo[{i}].{f};")
        L.append(f"  assign io_toVecExcpMod_logicPhyRegMap_{i}_valid = veValid[{i}];")
        L.append(f"  assign io_toVecExcpMod_logicPhyRegMap_{i}_bits_lreg = veLreg[{i}];")
        # golden preg 端口只有 7 位(取低 7)
        L.append(f"  assign io_toVecExcpMod_logicPhyRegMap_{i}_bits_preg = vePreg[{i}][6:0];")
    for i in range(NUM_DIFF):
        L.append(f"  assign io_diffCommits_commitValid_{i} = dValid[{i}];")
        for f in INFO_FIELDS:
            L.append(f"  assign io_diffCommits_info_{i}_{f} = dInfo[{i}].{f};")
    L.append("")

    L.append("  xs_RenameBuffer_core u_core (")
    L.append("    .clock(clock), .reset(reset),")
    L.append("    .io_redirect_valid(io_redirect_valid),")
    L.append("    .io_req(req),")
    L.append("    .io_fromRob_walkSize(io_fromRob_walkSize),")
    L.append("    .io_fromRob_walkEnd(io_fromRob_walkEnd),")
    L.append("    .io_fromRob_commitSize(io_fromRob_commitSize),")
    L.append("    .io_fromRob_vecLoadExcp_valid(io_fromRob_vecLoadExcp_valid),")
    L.append("    .io_snpt_snptEnq(io_snpt_snptEnq), .io_snpt_snptDeq(io_snpt_snptDeq),")
    L.append("    .io_snpt_useSnpt(io_snpt_useSnpt), .io_snpt_snptSelect(io_snpt_snptSelect),")
    L.append("    .io_snpt_flushVec(flushv),")
    L.append("    .io_canEnq(cE), .io_canEnqForDispatch(cEd),")
    L.append("    .io_commits_isCommit(isCommit), .io_commits_isWalk(isWalk),")
    L.append("    .io_commits_commitValid(cValid), .io_commits_walkValid(wValid),")
    L.append("    .io_commits_info(cInfo),")
    L.append("    .io_status_walkEnd(sWalkEnd), .io_status_commitEnd(sCommitEnd),")
    L.append("    .io_toVecExcpMod_valid(veValid), .io_toVecExcpMod_lreg(veLreg), .io_toVecExcpMod_preg(vePreg),")
    L.append("    .io_diffCommits_commitValid(dValid), .io_diffCommits_info(dInfo)")
    L.append("  );")
    L.append("endmodule")
    return "\n".join(L)


def make_stim():
    """逐口随机激励：rename 入队(各 wen 随机)，fromRob commit/walk size，redirect/snpt。
    commit/walkSize 取 0..6 小范围，避免 size 长期不归零；redirect ~3%。"""
    L = ["  function automatic logic [5:0] rldest(); return 6'($urandom_range(0,31)); endfunction",
         "  function automatic logic [7:0] rpdest(); return 8'($urandom_range(0,255)); endfunction",
         "  always @(negedge clk) begin",
         "    if (rst) begin",
         "      io_redirect_valid <= 0;"]
    for i in range(RENAME_WIDTH):
        L.append(f"      io_req_{i}_valid<=0; io_req_{i}_bits_ldest<=0; io_req_{i}_bits_pdest<=0;")
        L.append(f"      io_req_{i}_bits_rfWen<=0; io_req_{i}_bits_fpWen<=0; io_req_{i}_bits_vecWen<=0;")
        L.append(f"      io_req_{i}_bits_v0Wen<=0; io_req_{i}_bits_vlWen<=0; io_req_{i}_bits_isMove<=0;")
    L.append("      io_fromRob_walkSize<=0; io_fromRob_walkEnd<=0; io_fromRob_commitSize<=0;")
    L.append("      io_fromRob_vecLoadExcp_valid<=0;")
    L.append("      io_snpt_snptEnq<=0; io_snpt_snptDeq<=0; io_snpt_useSnpt<=0; io_snpt_snptSelect<=0;")
    L.append("      {io_snpt_flushVec_3,io_snpt_flushVec_2,io_snpt_flushVec_1,io_snpt_flushVec_0}<=0;")
    L.append("    end else begin")
    L.append("      io_redirect_valid <= ($urandom_range(0,99) < 3);")
    for i in range(RENAME_WIDTH):
        L.append(f"      io_req_{i}_valid<=($urandom_range(0,99)<70); io_req_{i}_bits_ldest<=rldest(); io_req_{i}_bits_pdest<=rpdest();")
        L.append(f"      io_req_{i}_bits_rfWen<=($urandom_range(0,99)<60); io_req_{i}_bits_fpWen<=($urandom_range(0,99)<10);")
        L.append(f"      io_req_{i}_bits_vecWen<=($urandom_range(0,99)<10); io_req_{i}_bits_v0Wen<=($urandom_range(0,99)<5);")
        L.append(f"      io_req_{i}_bits_vlWen<=($urandom_range(0,99)<5); io_req_{i}_bits_isMove<=($urandom_range(0,99)<10);")
    L.append("      io_fromRob_commitSize<=8'($urandom_range(0,6));")
    L.append("      io_fromRob_walkSize<=8'($urandom_range(0,6));")
    L.append("      io_fromRob_walkEnd<=($urandom_range(0,99)<20);")
    L.append("      io_fromRob_vecLoadExcp_valid<=($urandom_range(0,99)<10);")
    L.append("      io_snpt_snptEnq<=($urandom_range(0,99)<15); io_snpt_snptDeq<=($urandom_range(0,99)<15);")
    L.append("      io_snpt_useSnpt<=$urandom_range(0,1); io_snpt_snptSelect<=$urandom_range(0,3);")
    L.append("      io_snpt_flushVec_0<=($urandom_range(0,99)<5); io_snpt_flushVec_1<=($urandom_range(0,99)<5);")
    L.append("      io_snpt_flushVec_2<=($urandom_range(0,99)<5); io_snpt_flushVec_3<=($urandom_range(0,99)<5);")
    L.append("    end")
    L.append("  end")
    return "\n".join(L)


def make_probe():
    # g_u 扁平内部 reg；i 侧 struct/数组核内信号。逐项比对关键内部状态。
    L = ["    if (!$isunknown(g_u.state)) begin"]
    # state / pointers / sizes
    L.append("      if (g_u.state !== i_u.u_core.state) begin errors++; if(errors<=80) $display(\"[%0t] state g=%h i=%h\",$time,g_u.state,i_u.u_core.state); end")
    L.append("      if (g_u.enqPtrVec_0_value !== i_u.u_core.enq_ptr.value) begin errors++; if(errors<=80) $display(\"[%0t] enqPtr g=%h i=%h\",$time,g_u.enqPtrVec_0_value,i_u.u_core.enq_ptr.value); end")
    L.append("      if (g_u.enqPtrVec_0_flag !== i_u.u_core.enq_ptr.flag) begin errors++; if(errors<=80) $display(\"[%0t] enqFlag g=%h i=%h\",$time,g_u.enqPtrVec_0_flag,i_u.u_core.enq_ptr.flag); end")
    L.append("      if (g_u.shiftAmount !== i_u.u_core.deq_ptr.value) begin errors++; if(errors<=80) $display(\"[%0t] deqPtr g=%h i=%h\",$time,g_u.shiftAmount,i_u.u_core.deq_ptr.value); end")
    L.append("      if (g_u.deqPtrVec_0_flag !== i_u.u_core.deq_ptr.flag) begin errors++; if(errors<=80) $display(\"[%0t] deqFlag g=%h i=%h\",$time,g_u.deqPtrVec_0_flag,i_u.u_core.deq_ptr.flag); end")
    L.append("      if (g_u.deqPtrOH !== i_u.u_core.deq_ptr_oh) begin errors++; if(errors<=80) $display(\"[%0t] deqOH mismatch\",$time); end")
    L.append("      if (g_u.walkPtr_value !== i_u.u_core.walk_ptr.value) begin errors++; if(errors<=80) $display(\"[%0t] walkPtr g=%h i=%h\",$time,g_u.walkPtr_value,i_u.u_core.walk_ptr.value); end")
    L.append("      if (g_u.walkPtr_flag !== i_u.u_core.walk_ptr.flag) begin errors++; if(errors<=80) $display(\"[%0t] walkFlag g=%h i=%h\",$time,g_u.walkPtr_flag,i_u.u_core.walk_ptr.flag); end")
    L.append("      if (g_u.diffPtr_value !== i_u.u_core.diff_ptr.value) begin errors++; if(errors<=80) $display(\"[%0t] diffPtr g=%h i=%h\",$time,g_u.diffPtr_value,i_u.u_core.diff_ptr.value); end")
    L.append("      if (g_u.commitSize !== i_u.u_core.commit_size) begin errors++; if(errors<=80) $display(\"[%0t] commitSize g=%h i=%h\",$time,g_u.commitSize,i_u.u_core.commit_size); end")
    L.append("      if (g_u.walkSize !== i_u.u_core.walk_size) begin errors++; if(errors<=80) $display(\"[%0t] walkSize g=%h i=%h\",$time,g_u.walkSize,i_u.u_core.walk_size); end")
    L.append("      if (g_u.specialWalkSize !== i_u.u_core.special_walk_size) begin errors++; if(errors<=80) $display(\"[%0t] specialWalkSize g=%h i=%h\",$time,g_u.specialWalkSize,i_u.u_core.special_walk_size); end")
    L.append("      if (g_u.vecLoadExcp_valid !== i_u.u_core.vec_load_excp_valid) begin errors++; if(errors<=80) $display(\"[%0t] vecExcpV g=%h i=%h\",$time,g_u.vecLoadExcp_valid,i_u.u_core.vec_load_excp_valid); end")
    # 队列条目(pdest+ldest)逐项
    for e in range(256):
        L.append(f"      if (g_u.renameBuffer_{e}_info_pdest !== i_u.u_core.rename_buffer[{e}].pdest) begin errors++; if(errors<=80) $display(\"[%0t] buf[{e}].pdest g=%h i=%h\",$time,g_u.renameBuffer_{e}_info_pdest,i_u.u_core.rename_buffer[{e}].pdest); end")
        L.append(f"      if (g_u.renameBuffer_{e}_info_ldest !== i_u.u_core.rename_buffer[{e}].ldest) begin errors++; if(errors<=80) $display(\"[%0t] buf[{e}].ldest g=%h i=%h\",$time,g_u.renameBuffer_{e}_info_ldest,i_u.u_core.rename_buffer[{e}].ldest); end")
    L.append("    end")
    return "\n".join(L)


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
    L.append(make_stim())
    L.append("  always @(negedge clk) if (!rst) begin")
    L.append("    #4; checks++;")
    for w, n in outs:
        L.append(f"    if (!$isunknown(g_{n}) && g_{n} !== i_{n}) begin errors++;")
        L.append(f"      if(errors<=80) $display(\"[%0t] {n} g=%h i=%h\", $time, g_{n}, i_{n}); end")
    L.append(make_probe())
    L.append("  end")
    L.append(EPILOG)
    L.append("endmodule")
    return "\n".join(L)


EPILOG = r"""  initial begin
    rst = 1; repeat (8) @(posedge clk); rst = 0;
    repeat (NCYCLES) @(posedge clk);
    $display("checks=%0d errors=%0d", checks, errors);
    if (errors == 0 && checks > 1000) $display("TEST PASSED"); else $display("TEST FAILED");
    $finish;
  end"""


def main():
    ps = ports(MODULE)
    (XSSV / "rtl/backend/RenameBuffer_wrapper.sv").write_text(make_wrapper(ps, "RenameBuffer"))
    ut = XSSV / f"verif/ut/{MODULE}"
    ut.mkdir(parents=True, exist_ok=True)
    (ut / "variants_xs.sv").write_text(make_wrapper(ps, "RenameBuffer_xs"))
    (ut / "tb.sv").write_text(make_tb(ps))
    print("generated wrapper + ut for", MODULE)


if __name__ == "__main__":
    main()
