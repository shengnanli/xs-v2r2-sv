#!/usr/bin/env python3
"""
EntriesVfmaVialuFixVfalu 生成器(向量 FMA/整数定点ALU/浮点ALU 多 FU、双发射 IQ,
从 gen_iq_vfdiv.py 派生)。

可读核手写在 rtl/backend/{EntriesVfmaVialuFixVfalu,IqEntryVfmaVialuFixVfalu}.sv
+ iq_vfmavialufixvfalu_pkg.sv,本脚本只生成「flat golden 端口 ↔ 可读核 struct 端口」
的 wrapper 与双例化 tb。

★ 相对 VfdivVidiv 样板的差异(全部增量)★
  维度:numEntries 10→16(2/2/12),numDeq 1→2。
  numDeq=2:deqSelOH/oldestSel/og*Resp/deqEntry 都从单口扩为 2 口;deqPortIdx 机制由核处理。
  payload 多带 fpWen/lastUop/vpu.fpu.isFoldTo1_{2,4,8}(透传字段)。
  fuType:本变体 one-hot 位 19(vialuF)/24(vfalu)/25(vfma)。

设计意图来源:src/main/scala/xiangshan/backend/issue/{Entries,IssueQueue}.scala。
"""
import re
from pathlib import Path

XSSV = Path(__file__).resolve().parent.parent
GOLDEN = XSSV / "golden/chisel-rtl"
BK = XSSV / "rtl/backend"
UT = XSSV / "verif/ut/IssueQueueVfmaVialuFixVfalu"
GEN_HDR = "// 自动生成:scripts/gen_iq_vfmavialufixvfalu.py —— 勿手改\n"

# ---- 维度参数(与 iq_vfmavialufixvfalu_pkg 一致)----
NUM_ENTRIES, NUM_ENQ, NUM_SIMP, NUM_COMP, NUM_DEQ = 16, 2, 2, 12, 2
NUM_REGSRC, NUM_WK_WB = 5, 16
SIMP_BASE, COMP_BASE = NUM_ENQ, NUM_ENQ + NUM_SIMP

MOD = "EntriesVfmaVialuFixVfalu"


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


# ----------------------------------------------------------------------------
# entry_t 字段 ↔ golden flat 字段后缀 映射
# ----------------------------------------------------------------------------
PAYLOAD_MAP = {
    "fuOpType": ".payload.fu_op_type",
    "fpWen": ".payload.fp_wen",
    "vecWen": ".payload.vec_wen", "v0Wen": ".payload.v0_wen",
    "fpu_wflags": ".payload.fpu_wflags",
    "vpu_vma": ".payload.vpu.vma", "vpu_vta": ".payload.vpu.vta",
    "vpu_vsew": ".payload.vpu.vsew", "vpu_vlmul": ".payload.vpu.vlmul",
    "vpu_vm": ".payload.vpu.vm", "vpu_vstart": ".payload.vpu.vstart",
    "vpu_fpu_isFoldTo1_2": ".payload.vpu.fpu_is_fold_to_1_2",
    "vpu_fpu_isFoldTo1_4": ".payload.vpu.fpu_is_fold_to_1_4",
    "vpu_fpu_isFoldTo1_8": ".payload.vpu.fpu_is_fold_to_1_8",
    "vpu_isExt": ".payload.vpu.is_ext", "vpu_isNarrow": ".payload.vpu.is_narrow",
    "vpu_isDstMask": ".payload.vpu.is_dst_mask", "vpu_isOpMask": ".payload.vpu.is_op_mask",
    "vpu_isDependOldVd": ".payload.vpu.is_depend_old_vd",
    "vpu_isWritePartVd": ".payload.vpu.is_write_part_vd",
    "uopIdx": ".payload.uop_idx", "lastUop": ".payload.last_uop",
    "pdest": ".payload.pdest",
}


def entry_field_expr(v, suffix):
    m = re.match(r"status_robIdx_(flag|value)", suffix)
    if m:
        return f"{v}.status.rob_{m.group(1)}"
    m = re.match(r"status_fuType_(\d+)", suffix)
    if m:
        mp = {"19": "vialuf", "24": "vfalu", "25": "vfma"}
        return f"{v}.status.fu_type_" + mp[m.group(1)]
    m = re.match(r"status_srcStatus_(\d)_(.*)", suffix)
    if m:
        s, f = m.group(1), m.group(2)
        base = f"{v}.status.src[{s}]"
        fmap = {
            "psrc": ".psrc", "srcType": ".src_type", "srcState": ".src_state",
            "dataSources_value": ".data_src",
        }
        if f in fmap:
            return base + fmap[f]
    m = re.match(r"status_(issued|issueTimer|deqPortIdx)", suffix)
    if m:
        return v + {"issued": ".status.issued", "issueTimer": ".status.issue_timer",
                    "deqPortIdx": ".status.deq_port_idx"}[m.group(1)]
    m = re.match(r"payload_(.*)", suffix)
    if m and m.group(1) in PAYLOAD_MAP:
        return v + PAYLOAD_MAP[m.group(1)]
    raise ValueError("unmapped entry field: " + suffix)


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
        # ---- vl_info ----
        vmap = {
            "vlFromIntIsZero": "c_vl.int_is_zero", "vlFromIntIsVlmax": "c_vl.int_is_vlmax",
            "vlFromVfIsZero": "c_vl.vf_is_zero", "vlFromVfIsVlmax": "c_vl.vf_is_vlmax",
        }
        if body in vmap:
            pack.append(f"    {vmap[body]} = {n};"); continue
        # ---- WB 唤醒(分组写使能)----
        m = re.match(r"wakeUpFromWB_(\d+)_(valid|bits_vecWen|bits_v0Wen|bits_vlWen|bits_pdest)$", body)
        if m:
            idx, fld = int(m.group(1)), m.group(2)
            if fld == "valid":
                pack.append(f"    c_wk_wb[{idx}].valid = {n};")
            elif fld == "bits_pdest":
                pack.append(f"    c_wk_wb[{idx}].pdest = {n};")
            else:
                pack.append(f"    c_wk_wb[{idx}].wen = {n};")
            continue
        m = re.match(r"wakeUpFromWBDelayed_(\d+)_(valid|bits_vecWen|bits_v0Wen|bits_vlWen|bits_pdest)$", body)
        if m:
            idx, fld = int(m.group(1)), m.group(2)
            if fld == "valid":
                pack.append(f"    c_wk_wb_d[{idx}].valid = {n};")
            elif fld == "bits_pdest":
                pack.append(f"    c_wk_wb_d[{idx}].pdest = {n};")
            else:
                pack.append(f"    c_wk_wb_d[{idx}].wen = {n};")
            continue
        # ---- resp(每 deq 端口)----
        m = re.match(r"og0Resp_(\d)_valid$", body)
        if m:
            pack.append(f"    c_og_resp[{m.group(1)}].og0_valid = {n};"); continue
        m = re.match(r"og1Resp_(\d)_valid$", body)
        if m:
            pack.append(f"    c_og_resp[{m.group(1)}].og1_valid = {n};"); continue
        m = re.match(r"og2Resp_(\d)_valid$", body)
        if m:
            pack.append(f"    c_og_resp[{m.group(1)}].og2_valid = {n};"); continue
        m = re.match(r"og2Resp_(\d)_bits_resp$", body)
        if m:
            pack.append(f"    c_og_resp[{m.group(1)}].og2_resp = {n};"); continue
        # ---- deq sel(每端口 one-hot)----
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
        m = re.match(r"deqEntry_(\d)_bits_(.*)", body)
        if m:
            p, suf = m.group(1), m.group(2)
            unpack.append(f"  assign {n} = {entry_field_expr(f'c_deq_entry[{p}]', suf)};"); continue
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
    .wk_wb(c_wk_wb), .wk_wb_d(c_wk_wb_d),
    .vl_info(c_vl),
    .og_resp(c_og_resp),
    .deq_sel_oh_valid(c_deq_sel_oh_valid), .deq_sel_oh_bits(c_deq_sel_oh_bits),
    .enq_oldest_sel_bits(c_enq_oldest_sel_bits),
    .simp_oldest_sel_valid(c_simp_oldest_sel_valid), .simp_oldest_sel_bits(c_simp_oldest_sel_bits),
    .comp_oldest_sel_valid(c_comp_oldest_sel_valid), .comp_oldest_sel_bits(c_comp_oldest_sel_bits),
    .simp_deq_sel_vec(c_simp_deq_sel_vec),
    .o_valid(c_valid), .o_issued(c_issued), .o_can_issue(c_can_issue),
    .o_fu_type(c_fu_type), .o_data_sources(c_data_sources),
    .o_deq_entry(c_deq_entry),
    .o_simp_enq_sel_vec(c_simp_enq_sel_vec), .o_comp_enq_sel_vec(c_comp_enq_sel_vec)
"""

ENT_CORE_SIGS = """\
  logic                  c_flush_valid, c_flush_rob_flag, c_flush_level;
  logic [7:0]            c_flush_rob_value;
  logic [1:0]            c_enq_valid;
  entry_t [1:0]          c_enq_bits;
  wk_wb_t [15:0]         c_wk_wb, c_wk_wb_d;
  vl_info_t              c_vl;
  og_resp_t [1:0]        c_og_resp;
  logic [1:0]            c_deq_sel_oh_valid;
  logic [1:0][15:0]      c_deq_sel_oh_bits;
  logic [1:0][1:0]       c_enq_oldest_sel_bits;
  logic [1:0]            c_simp_oldest_sel_valid, c_comp_oldest_sel_valid;
  logic [1:0][1:0]       c_simp_oldest_sel_bits;
  logic [1:0][11:0]      c_comp_oldest_sel_bits;
  logic [1:0][1:0]       c_simp_deq_sel_vec;
  logic [15:0]           c_valid, c_issued, c_can_issue;
  logic [15:0][34:0]     c_fu_type;
  logic [15:0][4:0][3:0] c_data_sources;
  entry_t [1:0]          c_deq_entry;
  logic [1:0][1:0]       c_simp_enq_sel_vec;
  logic [1:0][11:0]      c_comp_enq_sel_vec;
"""


def emit_entries_wrapper():
    ports = parse_ports(MOD, MOD + ".sv")
    pack, unpack = gen_entries_wrapper(ports)
    out = [GEN_HDR]
    out.append(f"// {MOD} golden 同名扁平 wrapper —— 例化可读核 xs_{MOD}_core。\n")
    out.append(f"module {MOD} import iq_vfmavialufixvfalu_pkg::*; (\n")
    out.append("  input  clock,\n  input  reset,\n")
    for d, w, n in ports:
        out.append(decl(d, w, n))
    out[-1] = out[-1].rstrip(",\n") + "\n"
    out.append(");\n")
    out.append(ENT_CORE_SIGS)
    out.append("  always_comb begin\n")
    # golden 把 enq.bits 中本变体不消费的字段裁成常量,故未引出为端口 → 先清零再赋。
    out.append("    c_enq_bits = '0;\n")
    out.append("    c_wk_wb = '0; c_wk_wb_d = '0;\n")
    out.extend(p + "\n" for p in pack)
    out.append("  end\n")
    out.extend(u + "\n" for u in unpack)
    out.append(f"  xs_{MOD}_core u_core (\n")
    out.append(ENT_CORE_PORTS)
    out.append("  );\nendmodule\n")
    (BK / (MOD + "_wrapper.sv")).write_text("".join(out))
    print("wrote %s_wrapper.sv  (ports=%d pack=%d unpack=%d)"
          % (MOD, len(ports), len(pack), len(unpack)))


def emit_entries_tb():
    ports = parse_ports(MOD, MOD + ".sv")
    ins  = [(w, n) for d, w, n in ports if d == "input"]
    outs = [(w, n) for d, w, n in ports if d == "output"]
    L = []
    L.append("// 自动生成:scripts/gen_iq_vfmavialufixvfalu.py(entries tb)—— 勿手改\n")
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
    L.append(inst(MOD, "g"))
    L.append(inst(MOD + "_xs", "i"))

    L.append("  // srcType 入队偏置:src0/1/2/4 置 isVec(bit2),src3 置 isV0(bit3),否则唤醒永不命中。\n")
    L.append("  task drive_rand();\n")
    for w, n in ins:
        L.append(f"    {n} = $urandom;\n")
    for w, n in ins:
        if n.endswith("_valid") and ("Resp" not in n):
            L.append(f"    {n} = ($urandom % 4 == 0);\n")
    for q in range(NUM_ENQ):
        for s in range(NUM_REGSRC):
            nm = f"io_enq_{q}_bits_status_srcStatus_{s}_srcType"
            bit = 3 if s == 3 else 2
            val = "4'h8" if bit == 3 else "4'h4"
            if any(n == nm for _, n in ins):
                L.append(f"    {nm} = ($urandom % 2) ? {val} : {nm};\n")
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
    txt = (BK / (MOD + "_wrapper.sv")).read_text()
    txt = txt.replace(f"module {MOD} ", f"module {MOD}_xs ")
    (UT / "entries_variant_xs.sv").write_text(txt)
    print("wrote entries_variant_xs.sv")


if __name__ == "__main__":
    emit_entries_wrapper()
    emit_entries_tb()
    emit_entries_xs_variant()
