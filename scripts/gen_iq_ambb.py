#!/usr/bin/env python3
"""
IssueQueueAluMulBkuBrhJmp / EntriesAluMulBkuBrhJmp 生成器(fork 自 gen_iq_acfd.py)。

可读核手写在 rtl/backend/{EntriesAluMulBkuBrhJmp,IssueQueueAluMulBkuBrhJmp}.sv,
通过 iq_ambb_pkg 的 struct/enum 表达条目阵列、转移策略、年龄选择。本脚本生成
「flat golden 端口 ↔ 可读核 struct 端口」的 wrapper 与双例化 tb。

相对 ACFD 样板的字段差异(本脚本据此调整 field map):
  * fuType 保留位 {0,1,6,7,10}(brh/jmp/alu/mul/bku);
  * payload 携带 preDecodeInfo.isRVC / pred_taken,无 flushPipe;
  * Entries 顶层 og1Resp 无 bits_resp(resp 纯由 issueTimer 决定)。
"""
import re
from pathlib import Path

XSSV = Path(__file__).resolve().parent.parent
GOLDEN = XSSV / "golden/chisel-rtl"
BK = XSSV / "rtl/backend"
UT = XSSV / "verif/ut/IssueQueueAluMulBkuBrhJmp"
GEN_HDR = "// 自动生成:scripts/gen_iq_ambb.py —— 勿手改\n"

NUM_ENTRIES, NUM_ENQ, NUM_SIMP, NUM_COMP, NUM_DEQ = 24, 2, 6, 16, 2
NUM_REGSRC, NUM_WK_IQ, NUM_WK_WB, LDPW, LDW = 2, 7, 4, 3, 2
NUM_EXU = 27
SIMP_BASE, COMP_BASE = NUM_ENQ, NUM_ENQ + NUM_SIMP


def parse_ports(modname, fname):
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


def entry_field_expr(v, suffix):
    """golden flat 字段后缀 → core entry_t 路径(AMBB 版)。"""
    if suffix == "imm":
        return f"{v}.imm"
    m = re.match(r"status_robIdx_(flag|value)", suffix)
    if m:
        return f"{v}.status.rob_{m.group(1)}"
    m = re.match(r"status_fuType_(\d+)", suffix)
    if m:
        return f"{v}.status.fu_type[{m.group(1)}]"
    m = re.match(r"status_srcStatus_(\d)_(.*)", suffix)
    if m:
        s, f = m.group(1), m.group(2)
        base = f"{v}.status.src[{s}]"
        fmap = {
            "psrc": ".psrc", "srcType": ".src_type", "srcState": ".src_state",
            "dataSources_value": ".data_src", "useRegCache": ".use_rc",
            "regCacheIdx": ".rc_idx",
        }
        if f in fmap:
            return base + fmap[f]
        ldm = re.match(r"srcLoadDependency_(\d)", f)
        if ldm:
            return f"{base}.ld_dep[{ldm.group(1)}]"
    m = re.match(r"status_(issued|issueTimer|deqPortIdx)", suffix)
    if m:
        fmap = {"issued": ".status.issued", "issueTimer": ".status.issue_timer",
                "deqPortIdx": ".status.deq_port"}
        return v + fmap[m.group(1)]
    m = re.match(r"payload_(.*)", suffix)
    if m:
        f = m.group(1)
        fmap = {
            "ftqPtr_flag": ".payload.ftq_flag", "ftqPtr_value": ".payload.ftq_value",
            "ftqOffset": ".payload.ftq_offset", "fuOpType": ".payload.fu_op_type",
            "rfWen": ".payload.rf_wen",
            "preDecodeInfo_isRVC": ".payload.pre_decode_isrvc",
            "pred_taken": ".payload.pred_taken",
            "selImm": ".payload.sel_imm", "pdest": ".payload.pdest",
        }
        if f in fmap:
            return v + fmap[f]
        ldm = re.match(r"srcLoadDependency_(\d)_(\d)", f)
        if ldm:
            return f"{v}.payload.src_load_dep[{ldm.group(1)}][{ldm.group(2)}]"
    raise ValueError("unmapped entry field: " + suffix)


def wk_iq_expr(v, fld):
    fmap = {"rfWen": ".rf_wen", "pdest": ".pdest", "is0Lat": ".is0lat", "rcDest": ".rc_dest"}
    if fld in fmap:
        return v + fmap[fld]
    ldm = re.match(r"loadDependency_(\d)", fld)
    if ldm:
        return f"{v}.ld_dep[{ldm.group(1)}]"
    if fld == "valid":
        return v + ".valid"
    raise ValueError("unmapped wk_iq field: " + fld)


def wk_wb_expr(v, fld):
    fmap = {"valid": ".valid", "rfWen": ".rf_wen", "pdest": ".pdest"}
    return v + fmap[fld]


def gen_entries_wrapper(ports):
    pack = []
    unpack = []
    for d, w, n in ports:
        body = n[len("io_"):]
        m = re.match(r"enq_(\d)_valid$", body)
        if m:
            pack.append(f"    c_enq_valid[{m.group(1)}] = {n};")
            continue
        m = re.match(r"enq_(\d)_bits_(.*)", body)
        if m:
            q, suf = m.group(1), m.group(2)
            pack.append(f"    {entry_field_expr(f'c_enq_bits[{q}]', suf)} = {n};")
            continue
        fmap = {
            "flush_valid": "c_flush_valid", "flush_bits_robIdx_flag": "c_flush_rob_flag",
            "flush_bits_robIdx_value": "c_flush_rob_value", "flush_bits_level": "c_flush_level",
        }
        if body in fmap:
            pack.append(f"    {fmap[body]} = {n};")
            continue
        m = re.match(r"wakeUpFromIQ_(\d)_bits_(.*)", body)
        if m:
            pack.append(f"    {wk_iq_expr(f'c_wk_iq[{m.group(1)}]', m.group(2))} = {n};")
            continue
        m = re.match(r"wakeUpFromIQDelayed_(\d)_bits_(.*)", body)
        if m:
            pack.append(f"    {wk_iq_expr(f'c_wk_iq_d[{m.group(1)}]', m.group(2))} = {n};")
            continue
        m = re.match(r"wakeUpFromWB_(\d)_(valid|bits_rfWen|bits_pdest)$", body)
        if m:
            fld = m.group(2).replace("bits_", "")
            pack.append(f"    {wk_wb_expr(f'c_wk_wb[{m.group(1)}]', fld)} = {n};")
            continue
        m = re.match(r"wakeUpFromWBDelayed_(\d)_(valid|bits_rfWen|bits_pdest)$", body)
        if m:
            fld = m.group(2).replace("bits_", "")
            pack.append(f"    {wk_wb_expr(f'c_wk_wb_d[{m.group(1)}]', fld)} = {n};")
            continue
        m = re.match(r"og0Cancel_(\d+)$", body)
        if m:
            pack.append(f"    c_og0cancel[{m.group(1)}] = {n};")
            continue
        m = re.match(r"og1Cancel_(\d+)$", body)
        if m:
            pack.append(f"    c_og1cancel[{m.group(1)}] = {n};")
            continue
        m = re.match(r"ldCancel_(\d)_ld2Cancel$", body)
        if m:
            pack.append(f"    c_ldcancel[{m.group(1)}].ld2_cancel = {n};")
            continue
        m = re.match(r"og0Resp_(\d)_valid$", body)
        if m:
            pack.append(f"    c_og0resp_valid[{m.group(1)}] = {n};")
            continue
        m = re.match(r"og1Resp_(\d)_valid$", body)
        if m:
            pack.append(f"    c_og1resp_valid[{m.group(1)}] = {n};")
            continue
        m = re.match(r"deqSelOH_(\d)_valid$", body)
        if m:
            pack.append(f"    c_deq_sel_oh_valid[{m.group(1)}] = {n};")
            continue
        m = re.match(r"deqSelOH_(\d)_bits$", body)
        if m:
            pack.append(f"    c_deq_sel_oh_bits[{m.group(1)}] = {n};")
            continue
        m = re.match(r"enqEntryOldestSel_(\d)_bits$", body)
        if m:
            pack.append(f"    c_enq_oldest_sel_bits[{m.group(1)}] = {n};")
            continue
        m = re.match(r"simpEntryOldestSel_(\d)_valid$", body)
        if m:
            pack.append(f"    c_simp_oldest_sel_valid[{m.group(1)}] = {n};")
            continue
        m = re.match(r"simpEntryOldestSel_(\d)_bits$", body)
        if m:
            pack.append(f"    c_simp_oldest_sel_bits[{m.group(1)}] = {n};")
            continue
        m = re.match(r"compEntryOldestSel_(\d)_valid$", body)
        if m:
            pack.append(f"    c_comp_oldest_sel_valid[{m.group(1)}] = {n};")
            continue
        m = re.match(r"compEntryOldestSel_(\d)_bits$", body)
        if m:
            pack.append(f"    c_comp_oldest_sel_bits[{m.group(1)}] = {n};")
            continue
        m = re.match(r"simpEntryDeqSelVec_(\d)$", body)
        if m:
            pack.append(f"    c_simp_deq_sel_vec[{m.group(1)}] = {n};")
            continue
        # ---- OUTPUTS ----
        if body == "valid":
            unpack.append(f"  assign {n} = c_valid;"); continue
        if body == "issued":
            unpack.append(f"  assign {n} = c_issued;"); continue
        if body == "canIssue":
            unpack.append(f"  assign {n} = c_can_issue;"); continue
        m = re.match(r"fuType_(\d+)$", body)
        if m:
            e = int(m.group(1))
            unpack.append(f"  assign {n} = c_fu_type[{e}];"); continue
        m = re.match(r"dataSources_(\d+)_(\d)_value$", body)
        if m:
            unpack.append(f"  assign {n} = c_data_sources[{m.group(1)}][{m.group(2)}];"); continue
        m = re.match(r"exuSources_(\d+)_(\d)_value$", body)
        if m:
            unpack.append(f"  assign {n} = c_exu_sources[{m.group(1)}][{m.group(2)}];"); continue
        m = re.match(r"loadDependency_(\d+)_(\d)$", body)
        if m:
            unpack.append(f"  assign {n} = c_load_dependency[{m.group(1)}][{m.group(2)}];"); continue
        m = re.match(r"deqEntry_(\d)_bits_(.*)", body)
        if m:
            unpack.append(f"  assign {n} = {entry_field_expr(f'c_deq_entry[{m.group(1)}]', m.group(2))};"); continue
        m = re.match(r"cancelDeqVec_(\d)$", body)
        if m:
            unpack.append(f"  assign {n} = c_cancel_deq[{m.group(1)}];"); continue
        m = re.match(r"simpEntryEnqSelVec_(\d)$", body)
        if m:
            unpack.append(f"  assign {n} = c_simp_enq_sel_vec[{m.group(1)}];"); continue
        m = re.match(r"compEntryEnqSelVec_(\d)$", body)
        if m:
            unpack.append(f"  assign {n} = c_comp_enq_sel_vec[{m.group(1)}];"); continue
        raise ValueError("unmapped Entries port: " + n)
    return pack, unpack


ENT_CORE_PORTS = """\
    .clock(clock), .reset(reset),
    .flush_valid(c_flush_valid), .flush_rob_flag(c_flush_rob_flag),
    .flush_rob_value(c_flush_rob_value), .flush_level(c_flush_level),
    .enq_valid(c_enq_valid), .enq_bits(c_enq_bits),
    .wk_wb(c_wk_wb), .wk_iq(c_wk_iq), .wk_wb_d(c_wk_wb_d), .wk_iq_d(c_wk_iq_d),
    .og0cancel(c_og0cancel), .og1cancel(c_og1cancel), .ldcancel(c_ldcancel),
    .og0resp_valid(c_og0resp_valid), .og1resp_valid(c_og1resp_valid),
    .deq_ready(c_deq_ready), .deq_sel_oh_valid(c_deq_sel_oh_valid),
    .deq_sel_oh_bits(c_deq_sel_oh_bits), .enq_oldest_sel_bits(c_enq_oldest_sel_bits),
    .simp_oldest_sel_valid(c_simp_oldest_sel_valid), .simp_oldest_sel_bits(c_simp_oldest_sel_bits),
    .comp_oldest_sel_valid(c_comp_oldest_sel_valid), .comp_oldest_sel_bits(c_comp_oldest_sel_bits),
    .simp_deq_sel_vec(c_simp_deq_sel_vec),
    .o_valid(c_valid), .o_issued(c_issued), .o_can_issue(c_can_issue),
    .o_fu_type(c_fu_type), .o_data_sources(c_data_sources), .o_exu_sources(c_exu_sources),
    .o_load_dependency(c_load_dependency), .o_deq_entry(c_deq_entry), .o_cancel_deq(c_cancel_deq),
    .o_simp_enq_sel_vec(c_simp_enq_sel_vec), .o_comp_enq_sel_vec(c_comp_enq_sel_vec)
"""

ENT_CORE_SIGS = """\
  logic                 c_flush_valid, c_flush_rob_flag, c_flush_level;
  logic [7:0]           c_flush_rob_value;
  logic [1:0]           c_enq_valid;
  entry_t [1:0]         c_enq_bits;
  wk_wb_t [3:0]         c_wk_wb, c_wk_wb_d;
  wk_iq_t [6:0]         c_wk_iq, c_wk_iq_d;
  logic [26:0]          c_og0cancel, c_og1cancel;
  ld_cancel_t [2:0]     c_ldcancel;
  logic [1:0]           c_og0resp_valid, c_og1resp_valid;
  logic [1:0]           c_deq_ready, c_deq_sel_oh_valid;
  logic [1:0][23:0]     c_deq_sel_oh_bits;
  logic [1:0][1:0]      c_enq_oldest_sel_bits;
  logic [1:0]           c_simp_oldest_sel_valid, c_comp_oldest_sel_valid;
  logic [1:0][5:0]      c_simp_oldest_sel_bits;
  logic [1:0][15:0]     c_comp_oldest_sel_bits;
  logic [1:0][5:0]      c_simp_deq_sel_vec;
  logic [23:0]          c_valid, c_issued, c_can_issue;
  logic [23:0][34:0]    c_fu_type;
  logic [23:0][1:0][3:0] c_data_sources;
  logic [23:0][1:0][2:0] c_exu_sources;
  logic [23:0][2:0][1:0] c_load_dependency;
  entry_t [1:0]         c_deq_entry;
  logic [1:0]           c_cancel_deq;
  logic [1:0][5:0]      c_simp_enq_sel_vec;
  logic [1:0][15:0]     c_comp_enq_sel_vec;
"""


def emit_entries_wrapper():
    ports = parse_ports("EntriesAluMulBkuBrhJmp", "EntriesAluMulBkuBrhJmp.sv")
    pack, unpack = gen_entries_wrapper(ports)
    out = [GEN_HDR]
    out.append("// EntriesAluMulBkuBrhJmp golden 同名扁平 wrapper —— 例化可读核 xs_EntriesAluMulBkuBrhJmp_core。\n")
    out.append("module EntriesAluMulBkuBrhJmp import iq_ambb_pkg::*; (\n")
    out.append("  input  clock,\n  input  reset,\n")
    for d, w, n in ports:
        out.append(decl(d, w, n))
    out[-1] = out[-1].rstrip(",\n") + "\n"
    out.append(");\n")
    out.append(ENT_CORE_SIGS)
    out.append("  assign c_deq_ready = 2'b11; // golden 已将 deqReady 折叠为常量 1\n")
    out.append("  always_comb begin\n")
    out.append("    c_og1cancel = '0; // Entries 顶层未引 og1Cancel,置 0\n")
    out.append("    c_og0cancel = '0;\n")
    out.append("    c_enq_bits = '0;\n")
    out.append("    c_wk_iq = '0; c_wk_iq_d = '0; c_wk_wb = '0; c_wk_wb_d = '0; c_ldcancel = '0;\n")
    out.extend(p + "\n" for p in pack)
    out.append("  end\n")
    out.extend(u + "\n" for u in unpack)
    out.append("  xs_EntriesAluMulBkuBrhJmp_core u_core (\n")
    out.append(ENT_CORE_PORTS)
    out.append("  );\nendmodule\n")
    (BK / "EntriesAluMulBkuBrhJmp_wrapper.sv").write_text("".join(out))
    print("wrote EntriesAluMulBkuBrhJmp_wrapper.sv  (ports=%d pack=%d unpack=%d)"
          % (len(ports), len(pack), len(unpack)))


def emit_entries_tb():
    ports = parse_ports("EntriesAluMulBkuBrhJmp", "EntriesAluMulBkuBrhJmp.sv")
    ins  = [(w, n) for d, w, n in ports if d == "input"]
    outs = [(w, n) for d, w, n in ports if d == "output"]
    L = []
    L.append("// 自动生成:scripts/gen_iq_ambb.py(entries tb)—— 勿手改\n")
    L.append("`timescale 1ns/1ps\nmodule tb;\n")
    L.append("  int unsigned NCYCLES = 200000;\n")
    L.append("  bit clk=0, rst; int errors=0, checks=0;\n")
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
    L.append(inst("EntriesAluMulBkuBrhJmp", "g"))
    L.append(inst("EntriesAluMulBkuBrhJmp_xs", "i"))
    L.append("  task drive_rand();\n")
    for w, n in ins:
        L.append(f"    {n} = $urandom;\n")
    L.append("    // 适度降低各 valid 密度,覆盖 enq/唤醒/发射/转移/冲刷\n")
    for w, n in ins:
        if n.endswith("_valid") and ("Resp" not in n):
            L.append(f"    {n} = ($urandom % 4 == 0);\n")
    L.append("    io_flush_valid = ($urandom % 16 == 0);\n")
    L.append("  endtask\n")
    L.append("  task check();\n")
    for w, n in outs:
        L.append(f"    if (!$isunknown(g_{n}) && g_{n} !== i_{n}) begin errors++;\n")
        L.append(f"      if(errors<=120) $display(\"[%0t] {n} g=%h i=%h\", $time, g_{n}, i_{n}); end\n")
    L.append("    checks++;\n  endtask\n")
    L.append("""  initial begin
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
    (UT / "entries_tb.sv").write_text("".join(L))
    print("wrote entries_tb.sv (ins=%d outs=%d)" % (len(ins), len(outs)))


def emit_entries_xs_variant():
    txt = (BK / "EntriesAluMulBkuBrhJmp_wrapper.sv").read_text()
    txt = txt.replace("module EntriesAluMulBkuBrhJmp ", "module EntriesAluMulBkuBrhJmp_xs ")
    (UT / "entries_variant_xs.sv").write_text(txt)
    print("wrote entries_variant_xs.sv")


def emit_iq_svh():
    ports = parse_ports("IssueQueueAluMulBkuBrhJmp", "IssueQueueAluMulBkuBrhJmp.sv")
    p = [GEN_HDR.replace("\n", " (顶层端口) \n")]
    for d, w, n in ports:
        p.append(decl(d, w, n))
    p[-1] = p[-1].rstrip(",\n") + "\n"
    (BK / "issuequeue_ambb_ports.svh").write_text("".join(p))

    c = [GEN_HDR.replace("\n", " (顶层连线) \n")]
    c.append("  // 顶层端口与可读核完全同名, 纯穿透例化。\n")
    c.append("  xs_IssueQueueAluMulBkuBrhJmp_core u_core (\n")
    c.append("    .clock(clock), .reset(reset),\n")
    conn = [f"    .{n}({n})" for d, w, n in ports]
    c.append(",\n".join(conn))
    c.append("\n  );\n")
    (BK / "issuequeue_ambb_connect.svh").write_text("".join(c))
    print("wrote issuequeue_ambb_{ports,connect}.svh (ports=%d)" % len(ports))


def emit_iq_tb():
    ports = parse_ports("IssueQueueAluMulBkuBrhJmp", "IssueQueueAluMulBkuBrhJmp.sv")
    ins  = [(w, n) for d, w, n in ports if d == "input"]
    outs = [(w, n) for d, w, n in ports if d == "output"]
    L = []
    L.append("// 自动生成: scripts/gen_iq_ambb.py(iq tb)—— 勿手改\n")
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
    L.append(inst("IssueQueueAluMulBkuBrhJmp", "g"))
    L.append(inst("IssueQueueAluMulBkuBrhJmp_xs", "i"))

    L.append("  task drive_rand();\n")
    for w, n in ins:
        L.append(f"    {n} = $urandom;\n")
    L.append("    // 适度降低各 valid/handshake 密度, 覆盖 enq/发射/背压/唤醒/重定向\n")
    for w, n in ins:
        if n.endswith("_valid") and ("Resp" not in n):
            L.append(f"    {n} = ($urandom % 4 == 0);\n")
    L.append("    io_deqDelay_0_ready = ($urandom % 8 != 0);\n")
    L.append("    io_deqDelay_1_ready = ($urandom % 8 != 0);\n")
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
    L.append("module IssueQueueAluMulBkuBrhJmp_xs (\n")
    L.append("  input  clock,\n  input  reset,\n")
    L.append('`include "issuequeue_ambb_ports.svh"\n')
    L.append(");\n")
    L.append('`include "issuequeue_ambb_connect.svh"\n')
    L.append("endmodule\n")
    (UT / "iq_variant_xs.sv").write_text("".join(L))
    print("wrote iq_variant_xs.sv")


if __name__ == "__main__":
    import sys
    if "--entries" in sys.argv:
        emit_entries_wrapper()
        emit_entries_tb()
        emit_entries_xs_variant()
    else:
        emit_entries_wrapper()
    emit_iq_svh()
    emit_iq_tb()
    emit_iq_xs_variant()
