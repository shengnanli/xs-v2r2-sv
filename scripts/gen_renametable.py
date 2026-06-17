#!/usr/bin/env python3
"""
RenameTable(寄存器别名表 RAT，整数 Reg_I 例化)的 wrapper + UT 生成脚本。

设计意图来自 src/main/scala/xiangshan/backend/rename/RenameTable.scala (class RenameTable, Reg_I)。
可读核 rtl/backend/RenameTable.sv (xs_RenameTable_core)，把 SnapshotGenerator_4 当黑盒。

产出:
  rtl/backend/RenameTable_wrapper.sv   golden 同名 RenameTable(扁平端口 → 核 struct 数组)
  verif/ut/RenameTable/variants_xs.sv  同一 wrapper 改名 RenameTable_xs
  verif/ut/RenameTable/tb.sv           golden vs 手写 双例化逐拍比对(随机激励)

激励覆盖: 投机写/体系结构写/同步读+旁路/redirect 整表回退/快照/diff 写。
比对所有输出端口(readPorts_data/old_pdest/need_free/diff_rdata)，并对内部
spec_table/arch_table 做层次探针逐拍比对。
"""
import re
from pathlib import Path

XSSV = Path(__file__).resolve().parent.parent
GOLDEN = XSSV / "golden/chisel-rtl"
MODULE = "RenameTable"
HDR = "// 自动生成：scripts/gen_renametable.py —— 勿手改\n"

NUM_ENTRY = 32
NUM_READ = 12
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


def make_wrapper(ps, modname="RenameTable"):
    L = [HDR,
         "// golden 同名扁平端口 → 可读核 xs_RenameTable_core 的机械适配层",
         f"module {modname}",
         "  import renametable_pkg::*;",
         "("]
    decls = []
    for d, w, n in ps:
        ws = f"[{w-1}:0] " if w > 1 else "       "
        kw = "input " if d == "input" else "output"
        decls.append(f"  {kw} {ws}{n}")
    L.append(",\n".join(decls))
    L.append(");")

    L.append("  rat_rport_t  rp_in   [NUM_READ];")
    L.append("  logic [7:0]  rp_data [NUM_READ];")
    L.append("  rat_wport_t  sp_w    [COMMIT_WIDTH];")
    L.append("  rat_wport_t  ar_w    [COMMIT_WIDTH];")
    L.append("  logic [7:0]  old_pd  [COMMIT_WIDTH];")
    L.append("  logic        nfree   [COMMIT_WIDTH];")
    L.append("  logic [3:0]  flushv;")
    L.append("  rat_wport_t  df_w    [NUM_DIFF];")
    L.append("  logic [7:0]  df_rd   [NUM_ENTRY];")
    L.append("")

    for i in range(NUM_READ):
        L.append(f"  assign rp_in[{i}].hold = io_readPorts_{i}_hold;")
        L.append(f"  assign rp_in[{i}].addr = io_readPorts_{i}_addr;")
        L.append(f"  assign io_readPorts_{i}_data = rp_data[{i}];")
    for i in range(COMMIT_WIDTH):
        L.append(f"  assign sp_w[{i}].wen = io_specWritePorts_{i}_wen;")
        L.append(f"  assign sp_w[{i}].addr = io_specWritePorts_{i}_addr;")
        L.append(f"  assign sp_w[{i}].data = io_specWritePorts_{i}_data;")
        L.append(f"  assign ar_w[{i}].wen = io_archWritePorts_{i}_wen;")
        L.append(f"  assign ar_w[{i}].addr = io_archWritePorts_{i}_addr;")
        L.append(f"  assign ar_w[{i}].data = io_archWritePorts_{i}_data;")
        L.append(f"  assign io_old_pdest_{i} = old_pd[{i}];")
        L.append(f"  assign io_need_free_{i} = nfree[{i}];")
    L.append("  assign flushv = {io_snpt_flushVec_3, io_snpt_flushVec_2, io_snpt_flushVec_1, io_snpt_flushVec_0};")
    for i in range(NUM_DIFF):
        L.append(f"  assign df_w[{i}].wen = io_diffWritePorts_{i}_wen;")
        L.append(f"  assign df_w[{i}].addr = io_diffWritePorts_{i}_addr;")
        L.append(f"  assign df_w[{i}].data = io_diffWritePorts_{i}_data;")
    for e in range(NUM_ENTRY):
        L.append(f"  assign io_diff_rdata_{e} = df_rd[{e}];")
    L.append("")

    L.append("  xs_RenameTable_core u_core (")
    L.append("    .clock(clock), .reset(reset), .io_redirect(io_redirect),")
    L.append("    .io_readPorts_in(rp_in), .io_readPorts_data(rp_data),")
    L.append("    .io_specWritePorts(sp_w), .io_archWritePorts(ar_w),")
    L.append("    .io_old_pdest(old_pd), .io_need_free(nfree),")
    L.append("    .io_snpt_snptEnq(io_snpt_snptEnq), .io_snpt_snptDeq(io_snpt_snptDeq),")
    L.append("    .io_snpt_useSnpt(io_snpt_useSnpt), .io_snpt_snptSelect(io_snpt_snptSelect),")
    L.append("    .io_snpt_flushVec(flushv),")
    L.append("    .io_diffWritePorts(df_w), .io_diff_rdata(df_rd)")
    L.append("  );")
    L.append("endmodule")
    return "\n".join(L)


def make_stim():
    """逐口随机激励：写口 addr 0..31, data 0..255(addr==0 → data 0)。
    diff 写口稀疏(每口 wen 约 5%)以避免 255 口同时密集写。"""
    L = ["  function automatic logic [4:0] raddr(); return 5'($urandom_range(0,31)); endfunction",
         "  function automatic logic [7:0] rpreg(); return 8'($urandom_range(0,255)); endfunction",
         "  always @(negedge clk) begin",
         "    if (rst) begin",
         "      io_redirect <= 0;"]
    # reset all inputs
    for i in range(NUM_READ):
        L.append(f"      io_readPorts_{i}_hold <= 0; io_readPorts_{i}_addr <= 0;")
    for i in range(COMMIT_WIDTH):
        L.append(f"      io_specWritePorts_{i}_wen <= 0; io_specWritePorts_{i}_addr <= 0; io_specWritePorts_{i}_data <= 0;")
        L.append(f"      io_archWritePorts_{i}_wen <= 0; io_archWritePorts_{i}_addr <= 0; io_archWritePorts_{i}_data <= 0;")
    L.append("      io_snpt_snptEnq<=0; io_snpt_snptDeq<=0; io_snpt_useSnpt<=0; io_snpt_snptSelect<=0;")
    L.append("      {io_snpt_flushVec_3,io_snpt_flushVec_2,io_snpt_flushVec_1,io_snpt_flushVec_0}<=0;")
    for i in range(NUM_DIFF):
        L.append(f"      io_diffWritePorts_{i}_wen <= 0; io_diffWritePorts_{i}_addr <= 0; io_diffWritePorts_{i}_data <= 0;")
    L.append("    end else begin")
    L.append("      io_redirect <= ($urandom_range(0,99) < 4);")
    for i in range(NUM_READ):
        L.append(f"      io_readPorts_{i}_hold <= ($urandom_range(0,99)<10); io_readPorts_{i}_addr <= raddr();")
    for i in range(COMMIT_WIDTH):
        L.append(f"      io_specWritePorts_{i}_wen <= $urandom_range(0,1); io_specWritePorts_{i}_addr <= raddr(); io_specWritePorts_{i}_data <= rpreg();")
        L.append(f"      io_archWritePorts_{i}_wen <= $urandom_range(0,1); io_archWritePorts_{i}_addr <= raddr(); io_archWritePorts_{i}_data <= rpreg();")
    L.append("      io_snpt_snptEnq<=($urandom_range(0,99)<15); io_snpt_snptDeq<=($urandom_range(0,99)<15);")
    L.append("      io_snpt_useSnpt<=$urandom_range(0,1); io_snpt_snptSelect<=$urandom_range(0,3);")
    L.append("      io_snpt_flushVec_0<=($urandom_range(0,99)<5); io_snpt_flushVec_1<=($urandom_range(0,99)<5);")
    L.append("      io_snpt_flushVec_2<=($urandom_range(0,99)<5); io_snpt_flushVec_3<=($urandom_range(0,99)<5);")
    for i in range(NUM_DIFF):
        L.append(f"      io_diffWritePorts_{i}_wen <= ($urandom_range(0,99)<3); io_diffWritePorts_{i}_addr <= raddr(); io_diffWritePorts_{i}_data <= rpreg();")
    L.append("    end")
    L.append("  end")
    return "\n".join(L)


def make_probe():
    # g_u 扁平 spec_table_e / arch_table_e；i 侧 struct 数组。逐项比对。
    L = ["    if (!$isunknown(g_u.spec_table_0)) begin"]
    for e in range(NUM_ENTRY):
        L.append(f"      if (g_u.spec_table_{e} !== i_u.u_core.spec_table[{e}]) begin errors++;")
        L.append(f"        if(errors<=80) $display(\"[%0t] spec_table[{e}] g=%h i=%h\", $time, g_u.spec_table_{e}, i_u.u_core.spec_table[{e}]); end")
        L.append(f"      if (g_u.arch_table_{e} !== i_u.u_core.arch_table[{e}]) begin errors++;")
        L.append(f"        if(errors<=80) $display(\"[%0t] arch_table[{e}] g=%h i=%h\", $time, g_u.arch_table_{e}, i_u.u_core.arch_table[{e}]); end")
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
    (XSSV / "rtl/backend/RenameTable_wrapper.sv").write_text(make_wrapper(ps, "RenameTable"))
    ut = XSSV / f"verif/ut/{MODULE}"
    ut.mkdir(parents=True, exist_ok=True)
    (ut / "variants_xs.sv").write_text(make_wrapper(ps, "RenameTable_xs"))
    (ut / "tb.sv").write_text(make_tb(ps))
    print("generated wrapper + ut for", MODULE)


if __name__ == "__main__":
    main()
