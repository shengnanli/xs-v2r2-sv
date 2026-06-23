#!/usr/bin/env python3
"""
IssueQueueFaluFmacFdiv / EntriesFaluFmacFdiv 生成器(从 gen_iq_ffmac.py 派生)。

可读核手写在 rtl/backend/{EntriesFaluFmacFdiv,IqEntryFfmacFdiv}.sv + iq_ffmacfdiv_pkg.sv,
本脚本只生成「flat golden 端口 ↔ 可读核 struct 端口」的 wrapper 与双例化 tb。

★ 与 FaluFmac 变体的差异(本变体加 Fdiv 唤醒/发射端口)★
  numDeq 1→2:dual deqSelOH / og0Resp / og1Resp / oldestSel / deqEntry。
  fuType 多 fuType_14(Fdiv);status 多 deqPortIdx(内部寄存,无顶层端口)。
  og1Resp_1_bits_resp 动态 resp(端口 1)。其余唤醒机制与 FaluFmac 完全一致。

设计意图来源:src/main/scala/xiangshan/backend/issue/{Entries,IssueQueue}.scala。
"""
import re
from pathlib import Path

XSSV = Path(__file__).resolve().parent.parent
GOLDEN = XSSV / "golden/chisel-rtl"
BK = XSSV / "rtl/backend"
UT = XSSV / "verif/ut/IssueQueueFaluFmacFdiv"
GEN_HDR = "// 自动生成:scripts/gen_iq_ffmacfdiv.py —— 勿手改\n"

# ---- 维度参数(与 iq_ffmacfdiv_pkg 一致)----
NUM_ENTRIES, NUM_ENQ, NUM_SIMP, NUM_COMP, NUM_DEQ = 18, 2, 2, 14, 2
NUM_REGSRC, NUM_WK_IQ, NUM_WK_WB = 3, 3, 6
NUM_EXU = 27
SIMP_BASE, COMP_BASE = NUM_ENQ, NUM_ENQ + NUM_SIMP


def parse_ports(modname, fname):
    """返回有序 [(dir,width,name)],去掉 clock/reset。"""
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


# ----------------------------------------------------------------------------
# entry_t 字段 ↔ golden flat 字段后缀 映射(FaluFmacFdiv:多 fuType_14)
# ----------------------------------------------------------------------------
def entry_field_expr(v, suffix):
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
            "dataSources_value": ".data_src", "exuSources_value": ".exu_src",
        }
        if f in fmap:
            return base + fmap[f]
    m = re.match(r"status_(issued|issueTimer)", suffix)
    if m:
        fmap = {"issued": ".status.issued", "issueTimer": ".status.issue_timer"}
        return v + fmap[m.group(1)]
    m = re.match(r"payload_(.*)", suffix)
    if m:
        f = m.group(1)
        fmap = {
            "fuOpType": ".payload.fu_op_type", "rfWen": ".payload.rf_wen",
            "fpWen": ".payload.fp_wen", "fpu_wflags": ".payload.fpu_wflags",
            "fpu_fmt": ".payload.fpu_fmt", "fpu_rm": ".payload.fpu_rm",
            "pdest": ".payload.pdest",
        }
        if f in fmap:
            return v + fmap[f]
    raise ValueError("unmapped entry field: " + suffix)


def wk_iq_expr(v, fld):
    fmap = {"fpWen": ".fp_wen", "pdest": ".pdest", "is0Lat": ".is0lat"}
    if fld in fmap:
        return v + fmap[fld]
    raise ValueError("unmapped wk_iq field: " + fld)


def wk_wb_expr(v, fld):
    fmap = {"valid": ".valid", "fpWen": ".fp_wen", "pdest": ".pdest"}
    return v + fmap[fld]


# ----------------------------------------------------------------------------
# Entries wrapper:flat 输入 → core struct;core 输出 → flat。
# ----------------------------------------------------------------------------
def gen_entries_wrapper(ports):
    pack, unpack = [], []
    for d, w, n in ports:
        body = n[len("io_"):]
        # ---- enq ----
        m = re.match(r"enq_(\d)_valid$", body)
        if m:
            pack.append(f"    c_enq_valid[{m.group(1)}] = {n};"); continue
        m = re.match(r"enq_(\d)_bits_(.*)", body)
        if m:
            q, suf = m.group(1), m.group(2)
            pack.append(f"    {entry_field_expr(f'c_enq_bits[{q}]', suf)} = {n};"); continue
        # ---- flush ----
        fmap = {
            "flush_valid": "c_flush_valid", "flush_bits_robIdx_flag": "c_flush_rob_flag",
            "flush_bits_robIdx_value": "c_flush_rob_value", "flush_bits_level": "c_flush_level",
        }
        if body in fmap:
            pack.append(f"    {fmap[body]} = {n};"); continue
        # ---- wakeup ----
        m = re.match(r"wakeUpFromIQ_(\d)_bits_(.*)", body)
        if m:
            pack.append(f"    {wk_iq_expr(f'c_wk_iq[{m.group(1)}]', m.group(2))} = {n};"); continue
        m = re.match(r"wakeUpFromIQDelayed_(\d)_bits_(.*)", body)
        if m:
            pack.append(f"    {wk_iq_expr(f'c_wk_iq_d[{m.group(1)}]', m.group(2))} = {n};"); continue
        m = re.match(r"wakeUpFromWB_(\d)_(valid|bits_fpWen|bits_pdest)$", body)
        if m:
            fld = m.group(2).replace("bits_", "")
            pack.append(f"    {wk_wb_expr(f'c_wk_wb[{m.group(1)}]', fld)} = {n};"); continue
        m = re.match(r"wakeUpFromWBDelayed_(\d)_(valid|bits_fpWen|bits_pdest)$", body)
        if m:
            fld = m.group(2).replace("bits_", "")
            pack.append(f"    {wk_wb_expr(f'c_wk_wb_d[{m.group(1)}]', fld)} = {n};"); continue
        # ---- cancel(仅 og0Cancel_8)----
        m = re.match(r"og0Cancel_(\d+)$", body)
        if m:
            pack.append(f"    c_og0cancel[{m.group(1)}] = {n};"); continue
        # ---- resp(numDeq=2)----
        m = re.match(r"og0Resp_(\d)_valid$", body)
        if m:
            pack.append(f"    c_og0resp_valid[{m.group(1)}] = {n};"); continue
        m = re.match(r"og1Resp_(\d)_valid$", body)
        if m:
            pack.append(f"    c_og1resp_valid[{m.group(1)}] = {n};"); continue
        if body == "og1Resp_1_bits_resp":
            pack.append(f"    c_og1resp1_resp = {n};"); continue
        # ---- deq sel(numDeq=2)----
        m = re.match(r"deqSelOH_(\d)_valid$", body)
        if m:
            pack.append(f"    c_deq_sel_oh_valid[{m.group(1)}] = {n};"); continue
        m = re.match(r"deqSelOH_(\d)_bits$", body)
        if m:
            pack.append(f"    c_deq_sel_oh_bits[{m.group(1)}] = {n};"); continue
        m = re.match(r"enqEntryOldestSel_(\d)_bits$", body)
        if m:
            pack.append(f"    c_enq_oldest_sel_bits[{m.group(1)}] = {n};"); continue
        m = re.match(r"simpEntryOldestSel_(\d)_valid$", body)
        if m:
            pack.append(f"    c_simp_oldest_sel_valid[{m.group(1)}] = {n};"); continue
        m = re.match(r"simpEntryOldestSel_(\d)_bits$", body)
        if m:
            pack.append(f"    c_simp_oldest_sel_bits[{m.group(1)}] = {n};"); continue
        m = re.match(r"compEntryOldestSel_(\d)_valid$", body)
        if m:
            pack.append(f"    c_comp_oldest_sel_valid[{m.group(1)}] = {n};"); continue
        m = re.match(r"compEntryOldestSel_(\d)_bits$", body)
        if m:
            pack.append(f"    c_comp_oldest_sel_bits[{m.group(1)}] = {n};"); continue
        m = re.match(r"simpEntryDeqSelVec_(\d)$", body)
        if m:
            pack.append(f"    c_simp_deq_sel_vec[{m.group(1)}] = {n};"); continue
        # ---- OUTPUTS ----
        if body == "valid":
            unpack.append(f"  assign {n} = c_valid;"); continue
        if body == "issued":
            unpack.append(f"  assign {n} = c_issued;"); continue
        if body == "canIssue":
            unpack.append(f"  assign {n} = c_can_issue;"); continue
        m = re.match(r"fuType_(\d+)$", body)
        if m:
            unpack.append(f"  assign {n} = c_fu_type[{m.group(1)}];"); continue
        m = re.match(r"dataSources_(\d+)_(\d)_value$", body)
        if m:
            unpack.append(f"  assign {n} = c_data_sources[{m.group(1)}][{m.group(2)}];"); continue
        m = re.match(r"exuSources_(\d+)_(\d)_value$", body)
        if m:
            unpack.append(f"  assign {n} = c_exu_sources[{m.group(1)}][{m.group(2)}];"); continue
        m = re.match(r"deqEntry_(\d)_bits_(.*)", body)
        if m:
            dport, suf = m.group(1), m.group(2)
            suf = re.sub(r"status(psrc|srcType)", r"status_srcStatus_0_\1", suf) \
                if re.match(r"status(psrc|srcType)$", suf) else suf
            unpack.append(f"  assign {n} = {entry_field_expr(f'c_deq_entry[{dport}]', suf)};"); continue
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
    .og0cancel(c_og0cancel),
    .og0resp_valid(c_og0resp_valid), .og1resp_valid(c_og1resp_valid),
    .og1resp1_resp(c_og1resp1_resp),
    .deq_sel_oh_valid(c_deq_sel_oh_valid), .deq_sel_oh_bits(c_deq_sel_oh_bits),
    .enq_oldest_sel_bits(c_enq_oldest_sel_bits),
    .simp_oldest_sel_valid(c_simp_oldest_sel_valid), .simp_oldest_sel_bits(c_simp_oldest_sel_bits),
    .comp_oldest_sel_valid(c_comp_oldest_sel_valid), .comp_oldest_sel_bits(c_comp_oldest_sel_bits),
    .simp_deq_sel_vec(c_simp_deq_sel_vec),
    .o_valid(c_valid), .o_issued(c_issued), .o_can_issue(c_can_issue),
    .o_fu_type(c_fu_type), .o_data_sources(c_data_sources), .o_exu_sources(c_exu_sources),
    .o_deq_entry(c_deq_entry),
    .o_simp_enq_sel_vec(c_simp_enq_sel_vec), .o_comp_enq_sel_vec(c_comp_enq_sel_vec)
"""

ENT_CORE_SIGS = """\
  logic                 c_flush_valid, c_flush_rob_flag, c_flush_level;
  logic [7:0]           c_flush_rob_value;
  logic [1:0]           c_enq_valid;
  entry_t [1:0]         c_enq_bits;
  wk_wb_t [5:0]         c_wk_wb, c_wk_wb_d;
  wk_iq_t [2:0]         c_wk_iq, c_wk_iq_d;
  logic [26:0]          c_og0cancel;
  logic [1:0]           c_og0resp_valid, c_og1resp_valid;
  logic [1:0]           c_og1resp1_resp;
  logic [1:0]           c_deq_sel_oh_valid;
  logic [1:0][17:0]     c_deq_sel_oh_bits;
  logic [1:0][1:0]      c_enq_oldest_sel_bits;
  logic [1:0]           c_simp_oldest_sel_valid, c_comp_oldest_sel_valid;
  logic [1:0][1:0]      c_simp_oldest_sel_bits;
  logic [1:0][13:0]     c_comp_oldest_sel_bits;
  logic [1:0][1:0]      c_simp_deq_sel_vec;
  logic [17:0]          c_valid, c_issued, c_can_issue;
  logic [17:0][34:0]    c_fu_type;
  logic [17:0][2:0][3:0] c_data_sources;
  logic [17:0][2:0][1:0] c_exu_sources;
  entry_t [1:0]         c_deq_entry;
  logic [1:0][1:0]      c_simp_enq_sel_vec;
  logic [1:0][13:0]     c_comp_enq_sel_vec;
"""


def emit_entries_wrapper():
    ports = parse_ports("EntriesFaluFmacFdiv", "EntriesFaluFmacFdiv.sv")
    pack, unpack = gen_entries_wrapper(ports)
    out = [GEN_HDR]
    out.append("// EntriesFaluFmacFdiv golden 同名扁平 wrapper —— 例化可读核 xs_EntriesFaluFmacFdiv_core。\n")
    out.append("module EntriesFaluFmacFdiv import iq_ffmacfdiv_pkg::*; (\n")
    out.append("  input  clock,\n  input  reset,\n")
    for d, w, n in ports:
        out.append(decl(d, w, n))
    out[-1] = out[-1].rstrip(",\n") + "\n"
    out.append(");\n")
    out.append(ENT_CORE_SIGS)
    out.append("  always_comb begin\n")
    out.append("    c_og0cancel = '0; // 仅 og0Cancel[8] 被引用,其余位置 0\n")
    # golden 把 enq.bits 中本变体不消费的字段裁成常量 0,故未引出为端口。
    out.append("    c_enq_bits = '0;\n")
    out.append("    c_wk_iq = '0; c_wk_iq_d = '0; c_wk_wb = '0; c_wk_wb_d = '0;\n")
    out.extend(p + "\n" for p in pack)
    out.append("  end\n")
    out.extend(u + "\n" for u in unpack)
    out.append("  xs_EntriesFaluFmacFdiv_core u_core (\n")
    out.append(ENT_CORE_PORTS)
    out.append("  );\nendmodule\n")
    (BK / "EntriesFaluFmacFdiv_wrapper.sv").write_text("".join(out))
    print("wrote EntriesFaluFmacFdiv_wrapper.sv  (ports=%d pack=%d unpack=%d)"
          % (len(ports), len(pack), len(unpack)))


def emit_entries_tb():
    ports = parse_ports("EntriesFaluFmacFdiv", "EntriesFaluFmacFdiv.sv")
    ins  = [(w, n) for d, w, n in ports if d == "input"]
    outs = [(w, n) for d, w, n in ports if d == "output"]
    L = []
    L.append("// 自动生成:scripts/gen_iq_ffmacfdiv.py(entries tb)—— 勿手改\n")
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
    L.append(inst("EntriesFaluFmacFdiv", "g"))
    L.append(inst("EntriesFaluFmacFdiv_xs", "i"))

    L.append("  // srcType 入队偏置为 isFp(bit1=1),否则唤醒永不命中,覆盖率为 0。\n")
    L.append("  task drive_rand();\n")
    for w, n in ins:
        L.append(f"    {n} = $urandom;\n")
    for w, n in ins:
        if n.endswith("_valid") and ("Resp" not in n):
            L.append(f"    {n} = ($urandom % 4 == 0);\n")
    for q in range(NUM_ENQ):
        for s in range(NUM_REGSRC):
            nm = f"io_enq_{q}_bits_status_srcStatus_{s}_srcType"
            if any(n == nm for _, n in ins):
                L.append(f"    {nm} = ($urandom % 2) ? 4'h2 : {nm};\n")
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
    (UT / "entries_tb.sv").write_text("".join(L))
    print("wrote entries_tb.sv (ins=%d outs=%d)" % (len(ins), len(outs)))


def emit_entries_xs_variant():
    txt = (BK / "EntriesFaluFmacFdiv_wrapper.sv").read_text()
    txt = txt.replace("module EntriesFaluFmacFdiv ", "module EntriesFaluFmacFdiv_xs ")
    (UT / "entries_variant_xs.sv").write_text(txt)
    print("wrote entries_variant_xs.sv")


if __name__ == "__main__":
    emit_entries_wrapper()
    emit_entries_tb()
    emit_entries_xs_variant()
