#!/usr/bin/env python3
"""
IssueQueueStdMoud(store-data IQ, StdMoud 变体)生成器。

可读核手写在 rtl/backend/IssueQueueStdMoud.sv(含顶层 wrapper), 类型/参数在
iq_stdmoud_pkg.sv。条目阵列 EntriesStdMoud 及 3 个年龄检测器直接用 golden 黑盒例化
(IQ 核负责调度逻辑: enq 分配 / canIssue / 年龄仲裁 / deq / deqDelay)。

本脚本生成:
  issuequeue_stdmoud_ports.svh    —— 顶层端口声明(去 clock/reset)
  issuequeue_stdmoud_connect.svh  —— 例化可读核, 同名端口直连(纯穿透 wrapper)
  issuequeue_stdmoud_entries.svh  —— EntriesStdMoud 黑盒例化连线。从 golden
        entries 实例机械抽取: 把 io_wakeUp*→io_wakeup* 直透; enq 折算 / deqSelOH /
        age 输出 / entries 输出网 替换成可读核里的具名信号。这是「纯结构 + 命名映射」,
        无任何 golden 调度逻辑(调度逻辑全在可读核手写)。
  verif/ut/IssueQueueStdMoud/iq_tb.sv         —— 双例化(u_g golden vs u_i 可读核)
  verif/ut/IssueQueueStdMoud/iq_variant_xs.sv —— 顶层重命名 _xs 供 tb 与 golden 共存
  verif/ut/IssueQueueStdMoud/Makefile.iq      —— UT/FM 编译脚本

设计意图来源: src/main/scala/xiangshan/backend/issue/IssueQueue.scala。
"""
import re
from pathlib import Path

XSSV = Path(__file__).resolve().parent.parent
GOLDEN = XSSV / "golden/chisel-rtl"
BK = XSSV / "rtl/backend"
UT = XSSV / "verif/ut/IssueQueueStdMoud"
GEN_HDR = "// 自动生成: scripts/gen_iq_stdmoud.py —— 勿手改\n"


def parse_ports(modname, fname):
    """返回有序 [(dir,width,name)], 去掉 clock/reset。"""
    text = (GOLDEN / fname).read_text()
    m = re.search(r"^module %s\(\n(.*?)\n\);" % modname, text, re.S | re.M)
    res = []
    for line in m.group(1).splitlines():
        pm = re.match(r"\s*(input|output)\s+(?:\[(\d+):0\])?\s*(\w+),?\s*$", line)
        if pm:
            w = int(pm.group(2)) + 1 if pm.group(2) else 1
            n = pm.group(3)
            if n in ("clock", "reset"):
                continue
            res.append((pm.group(1), w, n))
    return res


def decl(d, w, n, suffix=","):
    rng = f"[{w-1}:0] " if w > 1 else ""
    return f"  {d:<7}{rng}{n}{suffix}\n"


def emit_iq_svh():
    ports = parse_ports("IssueQueueStdMoud", "IssueQueueStdMoud.sv")
    p = [GEN_HDR.replace("\n", " (顶层端口) \n")]
    for d, w, n in ports:
        p.append(decl(d, w, n))
    p[-1] = p[-1].rstrip(",\n") + "\n"   # 最后一个端口去逗号
    (BK / "issuequeue_stdmoud_ports.svh").write_text("".join(p))

    c = [GEN_HDR.replace("\n", " (顶层连线) \n")]
    c.append("  // 顶层端口与可读核完全同名, 纯穿透例化。\n")
    c.append("  xs_IssueQueueStdMoud_core u_core (\n")
    c.append("    .clock(clock), .reset(reset),\n")
    conn = [f"    .{n}({n})" for d, w, n in ports]
    c.append(",\n".join(conn))
    c.append("\n  );\n")
    (BK / "issuequeue_stdmoud_connect.svh").write_text("".join(c))
    print("wrote issuequeue_stdmoud_{ports,connect}.svh (ports=%d)" % len(ports))


def emit_entries_svh():
    """从 golden 抽取 EntriesStdMoud 实例连线, 做命名映射生成可读核版例化。

    映射规则(把 golden 局部网名替换成可读核里手写的具名信号):
      io_wakeUp...           -> io_wakeup...   (顶层输入直透, 仅大小写)
      s0_doEnqSelValidVec_0  -> s0_doEnq_0
      s0_doEnqSelValidVec_1  -> s0_doEnq_1
      enq srcState/dataSources 折算 -> enq_src_state()/enq_data_src() 函数调用
      deqSelValidVec_0       -> deqValid_0
      {_age_2_io_out_0,_deqSelOHVec_0_T_2,_deqSelOHVec_0_T_7} -> deqSelOH_0
      _age_io_out_0          -> age_enq_out
      |simpAgeDetectRequest_0-> (|simpReq_0)
      _age_1_io_out_0        -> age_simp_out[0]
      |_deqCanIssue_0_15to4  -> (|compReq_0)
      _age_2_io_out_0        -> age_comp_out
      fuTypeVec_k            -> e_fu_type[k]
      _age_1_io_out_1/2      -> age_simp_out[1]/[2]
      entries 输出网 _entries_io_X -> 可读核 wire(见 OUT_MAP)
    """
    text = (GOLDEN / "IssueQueueStdMoud.sv").read_text()
    m = re.search(r"  EntriesStdMoud entries \(\n(.*?)\n  \);", text, re.S)
    body = m.group(1)
    items = re.findall(r"\.(\w+)\s*\(\s*(.*?)\s*\)(?=,\n|\Z)", body, re.S)

    # entries 输出网 -> 可读核 wire
    def out_map(rhs):
        rhs = " ".join(rhs.split())
        mm = re.fullmatch(r"_entries_io_(\w+)", rhs)
        if not mm:
            return None
        s = mm.group(1)
        d = {
            "valid": "e_valid", "issued": "e_issued", "canIssue": "e_can_issue",
            "cancelDeqVec_0": "e_cancel_deq",
            "deqEntry_0_bits_status_robIdx_flag": "e_deq0_robflag",
            "deqEntry_0_bits_status_robIdx_value": "e_deq0_robval",
            "deqEntry_0_bits_status_fuType_16": "e_deq0_ft16",
            "deqEntry_0_bits_status_fuType_17": "e_deq0_ft17",
            "deqEntry_0_bits_status_srcStatus_0_psrc": "e_deq0_s0psrc",
            "deqEntry_0_bits_status_srcStatus_0_srcType": "e_deq0_s0type",
            "deqEntry_0_bits_status_srcStatus_0_regCacheIdx": "e_deq0_s0rc",
            "deqEntry_0_bits_payload_fuOpType": "e_deq0_fuop",
            "deqEntry_0_bits_payload_sqIdx_flag": "e_deq0_sqflag",
            "deqEntry_0_bits_payload_sqIdx_value": "e_deq0_sqval",
            "simpEntryEnqSelVec_0": "e_simp_enq_sel[0]",
            "simpEntryEnqSelVec_1": "e_simp_enq_sel[1]",
            "compEntryEnqSelVec_0": "e_comp_enq_sel[0]",
            "compEntryEnqSelVec_1": "e_comp_enq_sel[1]",
        }
        if s in d:
            return d[s]
        mm = re.fullmatch(r"dataSources_(\d+)_0_value", s)
        if mm:
            return f"e_data_src[{mm.group(1)}]"
        mm = re.fullmatch(r"exuSources_(\d+)_0_value", s)
        if mm:
            return f"e_exu_src[{mm.group(1)}]"
        mm = re.fullmatch(r"loadDependency_(\d+)_(\d+)", s)
        if mm:
            return f"e_load_dep[{mm.group(1)}][{mm.group(2)}]"
        mm = re.fullmatch(r"fuType_(\d+)", s)  # entries 输入 fuType vec (driven by us)
        if mm:
            return None
        return None

    def map_rhs(lhs, rhs):
        r = " ".join(rhs.split())
        # entries 输出网
        om = out_map(rhs)
        if om:
            return om
        # 顶层唤醒输入直透(仅大小写)
        if lhs.startswith("io_wakeUp"):
            return r.replace("io_wakeup", "io_wakeup")  # rhs 本就是 io_wakeup*
        # 一些常量/直透
        if re.fullmatch(r"io_\w+", r):
            return r
        if r in ("clock", "reset"):
            return r
        # enq 折算
        if r == "s0_doEnqSelValidVec_0":
            return "s0_doEnq_0"
        if r == "s0_doEnqSelValidVec_1":
            return "s0_doEnq_1"
        mm = re.fullmatch(r"io_enq_(\d)_bits_fuType\[(\d+)\]", r)
        if mm:
            return r
        # srcState 折算
        mm = re.match(r"io_enq_(\d)_bits_srcType_0\[2\] & _entries_io_enq_\d_bits_status_srcStatus_0_dataSources_value_T.*\| io_enq_(\d)_bits_srcState_0", r)
        if mm:
            i = mm.group(1)
            pz = "p0_0_zero" if i == "0" else "p1_0_zero"
            return f"enq_src_state(io_enq_{i}_bits_srcType_0, {pz}, io_enq_{i}_bits_srcState_0)"
        # dataSources 折算(三元链)
        mm = re.match(r"io_enq_(\d)_bits_srcType_0\[0\] & _entries_io_enq_\d_bits_status_srcStatus_0_dataSources_value_T", r)
        if mm and "4'h0" in r:
            i = mm.group(1)
            pz = "p0_0_zero" if i == "0" else "p1_0_zero"
            return f"enq_data_src(io_enq_{i}_bits_srcType_0, {pz})"
        # srcLoadDependency {x[0],1'h0}
        if re.fullmatch(r"\{io_enq_\d_bits_srcLoadDependency_0_\d\[0\], 1'h0\}", r):
            return r
        # deqSelOH / age
        if r == "deqSelValidVec_0":
            return "deqValid_0"
        if r == "{_age_2_io_out_0, _deqSelOHVec_0_T_2, _deqSelOHVec_0_T_7}":
            return "deqSelOH_0"
        if r == "_age_io_out_0":
            return "age_enq_out"
        if r == "|simpAgeDetectRequest_0":
            return "(|simpReq_0)"
        if r == "_age_1_io_out_0":
            return "age_simp_out[0]"
        if r == "|_deqCanIssue_0_15to4":
            return "(|compReq_0)"
        if r == "_age_2_io_out_0":
            return "age_comp_out"
        if r == "_age_1_io_out_1":
            return "age_simp_out[1]"
        if r == "_age_1_io_out_2":
            return "age_simp_out[2]"
        mm = re.fullmatch(r"fuTypeVec_(\d+)", r)
        if mm:
            return f"e_fu_type[{mm.group(1)}]"
        raise SystemExit(f"未映射 entries 连线: .{lhs}({r})")

    lines = [GEN_HDR.replace("\n", " (EntriesStdMoud 黑盒例化连线) \n")]
    lines.append("  EntriesStdMoud entries (\n")
    conns = []
    for lhs, rhs in items:
        if lhs in ("clock", "reset"):
            conns.append(f"    .{lhs}({lhs})")
            continue
        conns.append(f"    .{lhs}({map_rhs(lhs, rhs)})")
    lines.append(",\n".join(conns))
    lines.append("\n  );\n")
    (BK / "issuequeue_stdmoud_entries.svh").write_text("".join(lines))
    print("wrote issuequeue_stdmoud_entries.svh (conns=%d)" % len(items))


def emit_iq_tb():
    ports = parse_ports("IssueQueueStdMoud", "IssueQueueStdMoud.sv")
    ins = [(w, n) for d, w, n in ports if d == "input"]
    outs = [(w, n) for d, w, n in ports if d == "output"]
    L = []
    L.append("// 自动生成: scripts/gen_iq_stdmoud.py(iq tb)—— 勿手改\n")
    L.append("`timescale 1ns/1ps\nmodule tb;\n")
    L.append("  int unsigned NCYCLES = 200000;\n")
    L.append("  bit clk=0, rst; int errors=0, checks=0;\n")
    L.append("  bit no_flush;\n")
    L.append("  always #5 clk = ~clk;\n")
    for w, n in ins:
        rng = f"[{w-1}:0] " if w > 1 else ""
        L.append(f"  logic {rng}{n};\n")
    for w, n in outs:
        rng = f"[{w-1}:0] " if w > 1 else ""
        L.append(f"  wire {rng}g_{n};\n  wire {rng}i_{n};\n")

    def inst(mod, pfx):
        s = [f"  {mod} u_{pfx} (\n    .clock(clk), .reset(rst),\n"]
        conn = []
        for w, n in ins:
            conn.append(f"    .{n}({n})")
        for w, n in outs:
            conn.append(f"    .{n}({pfx}_{n})")
        s.append(",\n".join(conn))
        s.append("\n  );\n")
        return "".join(s)
    L.append(inst("IssueQueueStdMoud", "g"))
    L.append(inst("IssueQueueStdMoud_xs", "i"))

    L.append("  task drive_rand();\n")
    for w, n in ins:
        L.append(f"    {n} = $urandom;\n")
    L.append("    // 降低各 valid/handshake 密度, 覆盖 enq/发射/背压/唤醒/重定向\n")
    for w, n in ins:
        if n.endswith("_valid") and ("Resp" not in n):
            L.append(f"    {n} = ($urandom % 4 == 0);\n")
    L.append("    io_deqDelay_0_ready = ($urandom % 8 != 0);\n")
    L.append("    if (no_flush) io_flush_valid = 1'b0;\n")
    L.append("    else io_flush_valid = ($urandom % 16 == 0);\n")
    L.append("  endtask\n")

    L.append("  task check();\n")
    for w, n in outs:
        L.append(f"    if (!$isunknown(g_{n}) && g_{n} !== i_{n}) begin errors++;\n")
        L.append(f"      if(errors<=120) $display(\"[%0t] {n} g=%h i=%h\", $time, g_{n}, i_{n}); end\n")
    L.append("    checks++;\n  endtask\n")
    L.append("""  initial begin
    no_flush = $test$plusargs("NO_FLUSH");
    rst = 1; drive_rand();
    repeat (16) @(posedge clk); rst = 0;
    repeat (NCYCLES) begin
      @(negedge clk); drive_rand();
      @(posedge clk); #1 check();
    end
    $display("checks=%0d errors=%0d", checks, errors);
    if (errors==0 && checks>1000) $display("TEST PASSED"); else $display("TEST FAILED");
    $finish;
  end
endmodule
""")
    UT.mkdir(parents=True, exist_ok=True)
    (UT / "iq_tb.sv").write_text("".join(L))
    print("wrote iq_tb.sv (ins=%d outs=%d)" % (len(ins), len(outs)))


def emit_iq_xs_variant():
    L = [GEN_HDR.replace("\n", " (顶层 _xs 变体) \n")]
    L.append("module IssueQueueStdMoud_xs (\n")
    L.append("  input  clock,\n  input  reset,\n")
    L.append('`include "issuequeue_stdmoud_ports.svh"\n')
    L.append(");\n")
    L.append('`include "issuequeue_stdmoud_connect.svh"\n')
    L.append("endmodule\n")
    (UT / "iq_variant_xs.sv").write_text("".join(L))
    print("wrote iq_variant_xs.sv")


def emit_makefile():
    L = []
    L.append("MODULE = IssueQueueStdMoud\n\n")
    L.append("RTL_DIR = ../../../rtl\n")
    L.append("GOLDEN_RTL = ../../../golden/chisel-rtl\n\n")
    L.append("# 手写可读核(含顶层 wrapper)+ 类型包。svh 由 wrapper / 核 include。\n")
    L.append("RTL_SRCS = $(RTL_DIR)/backend/iq_stdmoud_pkg.sv \\\n")
    L.append("           $(RTL_DIR)/backend/IssueQueueStdMoud.sv\n\n")
    L.append("# golden 黑盒(IQ 的子模块 + 它们各自的依赖)。两侧 u_g/u_i 共享。\n")
    L.append("BB_DEPS = EntriesStdMoud.sv EnqEntry_30.sv OthersEntry_242.sv OthersEntry_244.sv \\\n")
    L.append("          EnqPolicy_14.sv UIntCompressor_27_000011100000000000001010101.sv \\\n")
    L.append("          NewAgeDetector_6.sv AgeDetector_12.sv AgeDetector_21.sv\n\n")
    L.append("TB_SRCS = iq_variant_xs.sv iq_tb.sv\n")
    L.append("GOLDEN_SRCS = $(GOLDEN_RTL)/IssueQueueStdMoud.sv \\\n")
    L.append("              $(addprefix $(GOLDEN_RTL)/,$(BB_DEPS))\n\n")
    L.append("WRAPPER_SRCS = $(addprefix $(GOLDEN_RTL)/,$(BB_DEPS))\n")
    L.append("FM_VARIANTS = IssueQueueStdMoud\n")
    L.append("FM_REF_DEPS_IssueQueueStdMoud = $(BB_DEPS)\n\n")
    L.append("include ../../../scripts/ut_common.mk\n\n")
    L.append("VCS += +define+SYNTHESIS\n")
    L.append("VCS += +incdir+$(RTL_DIR)/backend\n")
    L.append("# golden 状态寄存器无 reset, 上电为 X; 用 initreg 让两侧都从 0 上电消除假阳性。\n")
    L.append("VCS      += +vcs+initreg+random\n")
    L.append("SIM_ARGS += +vcs+initreg+0\n")
    (UT / "Makefile.iq").write_text("".join(L))
    print("wrote Makefile.iq")


if __name__ == "__main__":
    emit_iq_svh()
    emit_entries_svh()
    emit_iq_tb()
    emit_iq_xs_variant()
    emit_makefile()
