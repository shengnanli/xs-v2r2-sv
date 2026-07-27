#!/usr/bin/env python3
"""
RenameTable 参数变体(fpRat=_1 / vecRat=_2 / v0Rat,vlRat=_3)的 wrapper + UT 生成脚本。

复用已签核绿基核逻辑, 提升为参数化核 rtl/backend/renametable_var_core.sv
(xs_RenameTable_var_core)。SnapshotGenerator_{5,6,7} 由 wrapper 例化为对称黑盒。

产出(每变体 N):
  rtl/backend/RenameTable_N_wrapper.sv   golden 同名 RenameTable_N(扁平端口 → 参数核 + SG 黑盒)
  verif/ut/RenameTable_N/variants_xs.sv  同一 wrapper 改名 RenameTable_N_xs
  verif/ut/RenameTable_N/tb.sv           golden vs 手写 双例化逐拍比对
  verif/ut/RenameTable_N/Makefile

参数矩阵(经 diff golden 逐项核对, 见 docs/backend/RenameTable_variants.md):
  N=1 fp   : NUM_ENTRY=34 ADDR_W=6 NUM_READ=18 NUM_DIFF_ENTRY=32 DIFF_BASE=0 HAS_NEED_FREE=0 RESET_IDENTITY=1 SG=5
  N=2 vec  : NUM_ENTRY=47 ADDR_W=6 NUM_READ=18 NUM_DIFF_ENTRY=31 DIFF_BASE=1 HAS_NEED_FREE=0 RESET_IDENTITY=1 SG=6
  N=3 v0/vl: NUM_ENTRY=1  ADDR_W=1 NUM_READ=6  NUM_DIFF_ENTRY=1  DIFF_BASE=0 HAS_NEED_FREE=0 RESET_IDENTITY=0 SG=7
             (ADDR_W 逻辑上=0, SV 夹到 1; golden 无 addr 端口, 单项恒读/写 index 0。)
"""
import re
from pathlib import Path

XSSV = Path(__file__).resolve().parent.parent
GOLDEN = XSSV / "golden/chisel-rtl"
HDR = "// 自动生成：scripts/gen_renametable_variants.py —— 勿手改\n"
NUM_DIFF = 255
COMMIT_WIDTH = 6

# 变体参数
VARIANTS = {
    1: dict(NUM_ENTRY=34, ADDR_W=6, NUM_READ=18, NUM_DIFF_ENTRY=32, DIFF_BASE=0,
            HAS_NEED_FREE=0, RESET_IDENTITY=1, SG=5),
    2: dict(NUM_ENTRY=47, ADDR_W=6, NUM_READ=18, NUM_DIFF_ENTRY=31, DIFF_BASE=1,
            HAS_NEED_FREE=0, RESET_IDENTITY=1, SG=6),
    3: dict(NUM_ENTRY=1,  ADDR_W=1, NUM_READ=6,  NUM_DIFF_ENTRY=1,  DIFF_BASE=0,
            HAS_NEED_FREE=0, RESET_IDENTITY=0, SG=7),
}


def ports(name):
    text = (GOLDEN / f"{name}.sv").read_text()
    m = re.search(rf"^module {re.escape(name)}\((.*?)\n\);", text, re.S | re.M)
    res = []
    for line in m.group(1).splitlines():
        pm = re.match(r"\s*(input|output)\s+(?:\[(\d+):0\])?\s*(\w+),?\s*$", line)
        if pm:
            res.append((pm.group(1), int(pm.group(2)) + 1 if pm.group(2) else 1, pm.group(3)))
    return res


def has_port(ps, name):
    return any(n == name for _, _, n in ps)


def make_wrapper(N, p, modname):
    mod = f"RenameTable_{N}"
    ps = ports(mod)
    NE, AW, NR = p["NUM_ENTRY"], p["ADDR_W"], p["NUM_READ"]
    NDE, DB, SG = p["NUM_DIFF_ENTRY"], p["DIFF_BASE"], p["SG"]
    has_addr = has_port(ps, "io_readPorts_0_addr")  # 单项变体无 addr 端口
    has_hold = has_port(ps, "io_readPorts_0_hold")

    L = [HDR,
         f"// golden 同名扁平端口 → 参数化可读核 xs_RenameTable_var_core + SnapshotGenerator_{SG} 黑盒",
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

    # 核侧数组信号
    L.append(f"  logic                rp_hold [{NR}];")
    L.append(f"  logic [{AW-1}:0] rp_addr [{NR}];")
    L.append(f"  logic [7:0]          rp_data [{NR}];")
    L.append(f"  logic                sp_wen  [{COMMIT_WIDTH}];")
    L.append(f"  logic [{AW-1}:0] sp_addr [{COMMIT_WIDTH}];")
    L.append(f"  logic [7:0]          sp_data [{COMMIT_WIDTH}];")
    L.append(f"  logic                ar_wen  [{COMMIT_WIDTH}];")
    L.append(f"  logic [{AW-1}:0] ar_addr [{COMMIT_WIDTH}];")
    L.append(f"  logic [7:0]          ar_data [{COMMIT_WIDTH}];")
    L.append(f"  logic [7:0]          old_pd  [{COMMIT_WIDTH}];")
    L.append(f"  logic                nfree   [{COMMIT_WIDTH}];")
    L.append("  logic [3:0]          flushv;")
    L.append(f"  logic                df_wen  [{NUM_DIFF}];")
    L.append(f"  logic [{AW-1}:0] df_addr [{NUM_DIFF}];")
    L.append(f"  logic [7:0]          df_data [{NUM_DIFF}];")
    L.append(f"  logic [7:0]          df_rd   [{NDE}];")
    L.append(f"  logic [7:0]          spec_tbl[{NE}];")
    L.append(f"  logic [7:0]          snaps   [{4}][{NE}];")
    L.append("  logic                t1_redir;")
    L.append("  logic                t1_enq, t1_deq;")
    L.append("  logic [3:0]          t1_flushv;")
    L.append("")

    # 读口连接
    for i in range(NR):
        if has_hold:
            L.append(f"  assign rp_hold[{i}] = io_readPorts_{i}_hold;")
        else:
            L.append(f"  assign rp_hold[{i}] = 1'b0;")
        if has_addr:
            L.append(f"  assign rp_addr[{i}] = io_readPorts_{i}_addr;")
        else:
            L.append(f"  assign rp_addr[{i}] = {AW}'b0;")
        L.append(f"  assign io_readPorts_{i}_data = rp_data[{i}];")
    # 写口连接
    for i in range(COMMIT_WIDTH):
        L.append(f"  assign sp_wen[{i}]  = io_specWritePorts_{i}_wen;")
        L.append(f"  assign sp_addr[{i}] = " +
                 (f"io_specWritePorts_{i}_addr;" if has_port(ps, f"io_specWritePorts_{i}_addr") else f"{AW}'b0;"))
        L.append(f"  assign sp_data[{i}] = io_specWritePorts_{i}_data;")
        L.append(f"  assign ar_wen[{i}]  = io_archWritePorts_{i}_wen;")
        L.append(f"  assign ar_addr[{i}] = " +
                 (f"io_archWritePorts_{i}_addr;" if has_port(ps, f"io_archWritePorts_{i}_addr") else f"{AW}'b0;"))
        L.append(f"  assign ar_data[{i}] = io_archWritePorts_{i}_data;")
        L.append(f"  assign io_old_pdest_{i} = old_pd[{i}];")
        if p["HAS_NEED_FREE"]:
            L.append(f"  assign io_need_free_{i} = nfree[{i}];")
    L.append("  assign flushv = {io_snpt_flushVec_3, io_snpt_flushVec_2, io_snpt_flushVec_1, io_snpt_flushVec_0};")
    # diff 写口连接
    for i in range(NUM_DIFF):
        L.append(f"  assign df_wen[{i}]  = io_diffWritePorts_{i}_wen;")
        L.append(f"  assign df_addr[{i}] = " +
                 (f"io_diffWritePorts_{i}_addr;" if has_port(ps, f"io_diffWritePorts_{i}_addr") else f"{AW}'b0;"))
        L.append(f"  assign df_data[{i}] = io_diffWritePorts_{i}_data;")
    for e in range(NDE):
        L.append(f"  assign io_diff_rdata_{e} = df_rd[{e}];")
    L.append("")

    # 参数化核例化
    L.append("  xs_RenameTable_var_core #(")
    L.append(f"    .NUM_ENTRY({NE}), .ADDR_W({AW}), .NUM_READ({NR}),")
    L.append(f"    .NUM_DIFF_ENTRY({NDE}), .DIFF_BASE({DB}),")
    L.append(f"    .HAS_NEED_FREE(1'b{p['HAS_NEED_FREE']}), .RESET_IDENTITY(1'b{p['RESET_IDENTITY']})")
    L.append("  ) u_core (")
    L.append("    .clock(clock), .reset(reset), .io_redirect(io_redirect),")
    L.append("    .io_readPorts_hold(rp_hold), .io_readPorts_addr(rp_addr), .io_readPorts_data(rp_data),")
    L.append("    .io_specWritePorts_wen(sp_wen), .io_specWritePorts_addr(sp_addr), .io_specWritePorts_data(sp_data),")
    L.append("    .io_archWritePorts_wen(ar_wen), .io_archWritePorts_addr(ar_addr), .io_archWritePorts_data(ar_data),")
    L.append("    .io_old_pdest(old_pd), .io_need_free(nfree),")
    L.append("    .io_snpt_snptEnq(io_snpt_snptEnq), .io_snpt_snptDeq(io_snpt_snptDeq),")
    L.append("    .io_snpt_useSnpt(io_snpt_useSnpt), .io_snpt_snptSelect(io_snpt_snptSelect),")
    L.append("    .io_snpt_flushVec(flushv),")
    L.append("    .o_spec_table(spec_tbl), .i_snapshots(snaps),")
    L.append("    .o_t1_redirect(t1_redir),")
    L.append("    .o_t1_snpt_snptEnq(t1_enq), .o_t1_snpt_snptDeq(t1_deq), .o_t1_snpt_flushVec(t1_flushv),")
    L.append("    .io_diffWritePorts_wen(df_wen), .io_diffWritePorts_addr(df_addr), .io_diffWritePorts_data(df_data),")
    L.append("    .io_diff_rdata(df_rd)")
    L.append("  );")
    L.append("")

    # SnapshotGenerator 黑盒例化(与 golden 同名同连线; 逐 enqData/snapshots 展平)
    L.append(f"  SnapshotGenerator_{SG} snapshots_snapshotGen (")
    L.append("    .clock(clock), .reset(reset),")
    L.append("    .io_enq(t1_enq), .io_deq(t1_deq), .io_redirect(t1_redir),")
    for s in range(4):
        L.append(f"    .io_flushVec_{s}(t1_flushv[{s}]),")
    for e in range(NE):
        L.append(f"    .io_enqData_{e}(spec_tbl[{e}]),")
    snap_lines = []
    for s in range(4):
        for e in range(NE):
            snap_lines.append(f"    .io_snapshots_{s}_{e}(snaps[{s}][{e}])")
    L.append(",\n".join(snap_lines))
    L.append("  );")

    L.append("endmodule")
    return "\n".join(L)


def make_tb(N, p):
    mod = f"RenameTable_{N}"
    ps = ports(mod)
    AW = p["ADDR_W"]
    has_addr = has_port(ps, "io_readPorts_0_addr")
    has_hold = has_port(ps, "io_readPorts_0_hold")
    NE = p["NUM_ENTRY"]
    max_addr = NE - 1

    ins = [(w, n) for d, w, n in ps if d == "input" and n not in ("clock", "reset")]
    outs = [(w, n) for d, w, n in ps if d == "output"]

    def decl(w, n, pre=""):
        ws = f"[{w-1}:0] " if w > 1 else ""
        return f"  logic {ws}{pre}{n};"

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

    def inst(m, pre):
        c = [".clock(clk)", ".reset(rst)"]
        c += [f".{n}({n})" for _, n in ins]
        c += [f".{n}({pre}{n})" for _, n in outs]
        return f"  {m} {pre[0]}_u (" + ", ".join(c) + ");"

    L.append(inst(mod, "g_"))
    L.append(inst(mod + "_xs", "i_"))
    L.append("")

    # 随机激励
    L.append(f"  function automatic logic [{AW-1}:0] raddr(); return {AW}'($urandom_range(0,{max_addr})); endfunction")
    L.append("  function automatic logic [7:0] rpreg(); return 8'($urandom_range(0,255)); endfunction")
    L.append("  always @(negedge clk) begin")
    L.append("    if (rst) begin")
    L.append("      io_redirect <= 0;")
    for w, n in ins:
        if n == "io_redirect":
            continue
        L.append(f"      {n} <= 0;")
    L.append("    end else begin")
    L.append("      io_redirect <= ($urandom_range(0,99) < 4);")
    for _, n in ins:
        if n == "io_redirect":
            continue
        if n.endswith("_addr"):
            L.append(f"      {n} <= raddr();")
        elif n.endswith("_data"):
            L.append(f"      {n} <= rpreg();")
        elif n.endswith("_wen"):
            L.append(f"      {n} <= $urandom_range(0,1);")
        elif n.endswith("_hold"):
            L.append(f"      {n} <= ($urandom_range(0,99)<10);")
        elif "_flushVec_" in n:
            L.append(f"      {n} <= ($urandom_range(0,99)<5);")
        elif n == "io_snpt_snptEnq" or n == "io_snpt_snptDeq":
            L.append(f"      {n} <= ($urandom_range(0,99)<15);")
        elif n == "io_snpt_useSnpt":
            L.append(f"      {n} <= $urandom_range(0,1);")
        elif n == "io_snpt_snptSelect":
            L.append(f"      {n} <= $urandom_range(0,3);")
        else:
            L.append(f"      {n} <= $urandom_range(0,1);")
    L.append("    end")
    L.append("  end")

    # 输出比对 + 内部 spec/arch 表探针
    L.append("  always @(negedge clk) if (!rst) begin")
    L.append("    #4; checks++;")
    for w, n in outs:
        L.append(f"    if (!$isunknown(g_{n}) && g_{n} !== i_{n}) begin errors++;")
        L.append(f"      if(errors<=80) $display(\"[%0t] {n} g=%h i=%h\", $time, g_{n}, i_{n}); end")
    L.append("    if (!$isunknown(g_u.spec_table_0)) begin")
    for e in range(NE):
        L.append(f"      if (g_u.spec_table_{e} !== i_u.u_core.spec_table[{e}]) begin errors++;")
        L.append(f"        if(errors<=80) $display(\"[%0t] spec_table[{e}] g=%h i=%h\", $time, g_u.spec_table_{e}, i_u.u_core.spec_table[{e}]); end")
        L.append(f"      if (g_u.arch_table_{e} !== i_u.u_core.arch_table[{e}]) begin errors++;")
        L.append(f"        if(errors<=80) $display(\"[%0t] arch_table[{e}] g=%h i=%h\", $time, g_u.arch_table_{e}, i_u.u_core.arch_table[{e}]); end")
    L.append("    end")
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


def make_makefile(N, p):
    SG = p["SG"]
    mod = f"RenameTable_{N}"
    return f"""MODULE = {mod}

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

# 参数化可读核 + 类型包; 核内不例化 SG, wrapper 侧例化 SnapshotGenerator_{SG} 黑盒。
# UT 不编 {mod}_wrapper.sv(模块名与 golden 顶层冲突), 手写侧用 variants_xs.sv 里的 {mod}_xs。
RTL_SRCS = $(RTL_DIR)/backend/renametable_pkg.sv \\
           $(RTL_DIR)/backend/renametable_var_core.sv

TB_SRCS = variants_xs.sv tb.sv

# golden 顶层 {mod} + 子模块 SnapshotGenerator_{SG}(黑盒, UT 两侧共用)
GOLDEN_SRCS = $(GOLDEN_RTL)/{mod}.sv \\
              $(GOLDEN_RTL)/SnapshotGenerator_{SG}.sv

# FM: golden {mod} vs 手写同名 wrapper(→参数核)。SnapshotGenerator_{SG} 两侧同一黑盒。
WRAPPER_SRCS = $(RTL_DIR)/backend/{mod}_wrapper.sv \\
               $(GOLDEN_RTL)/SnapshotGenerator_{SG}.sv
FM_VARIANTS = {mod}
FM_REF_DEPS_{mod} = SnapshotGenerator_{SG}.sv

include ../../../scripts/ut_common.mk

# golden 含 XSError 断言; UT 关掉以免随机激励触发 $fatal
VCS += +define+SYNTHESIS
"""


def main():
    for N, p in VARIANTS.items():
        mod = f"RenameTable_{N}"
        (XSSV / f"rtl/backend/{mod}_wrapper.sv").write_text(make_wrapper(N, p, mod))
        ut = XSSV / f"verif/ut/{mod}"
        ut.mkdir(parents=True, exist_ok=True)
        (ut / "variants_xs.sv").write_text(make_wrapper(N, p, f"{mod}_xs"))
        (ut / "tb.sv").write_text(make_tb(N, p))
        (ut / "Makefile").write_text(make_makefile(N, p))
        print("generated wrapper + ut for", mod)


if __name__ == "__main__":
    main()
