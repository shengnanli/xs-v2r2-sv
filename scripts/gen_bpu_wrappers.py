#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""gen_bpu_wrappers.py —— BPU 预测器 wrapper 的机械派生区（ITTage / Tage_SC）。

生成内容（全部从 G1 golden 机械推出）：每个目标文件 rtl/frontend/<T>.sv 里
`// BEGIN GENERATED(bpu-wrapper)` / `// END GENERATED(bpu-wrapper)` 之间的 golden 同名 wrapper：
  1. golden 端口表（逐行照抄方向/位宽/名字）；
  2. 子模块例化：实例名、模块名、端口顺序照抄 golden；每根连线二选一 ——
       · golden 里接的就是顶层端口（MBIST bore / 折叠历史等）→ 原样照抄；
       · 否则必须被本目标的子模块端口规则认领（接到核的语义化网名），规则认领了但 golden 接的是
         顶层端口、或两者都不是 → 拒绝生成（fail-closed）；
  3. 顶层输出：golden 里 `assign 输出 = 某个输入;` 的纯透传照抄；其余输出必须被输出规则认领
     （接核的输出）或由子模块/核例化直接驱动；每个输出恰好一个驱动者，否则拒绝生成；
  4. 核例化（xs_<T>_core）与网声明：由本文件的模板给出（核本身在 GENERATED 区外手写）。
  另：每个输入端口在 golden 模块体里被用到 ⇔ 在生成的 wrapper 里被用到，否则拒绝生成。

用法：
    python3 scripts/gen_bpu_wrappers.py            # 生成（幂等：内容不变不写文件）
    python3 scripts/gen_bpu_wrappers.py --check    # 产物与生成器不一致则 rc=1
"""
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.normpath(os.path.join(HERE, ".."))
GOLDEN_DIR = os.environ.get("GOLDEN_RTL", "/home/eda/xs-env/G1-canonical/golden-rtl")
PORT_RE = re.compile(r"^\s*(input|output)\s+(?:\[(\d+):0\]\s+)?(\w+)\s*,?\s*$")
BEGIN = "// BEGIN GENERATED(bpu-wrapper) —— scripts/gen_bpu_wrappers.py 生成，勿手改\n"
END = "// END GENERATED(bpu-wrapper)\n"


def die(msg):
    raise SystemExit("gen_bpu_wrappers: " + msg)


def golden_module(top):
    t = open(os.path.join(GOLDEN_DIR, top + ".sv")).read()
    m = re.search(r"^module\s+%s\s*\((.*?)^\);(.*?)^endmodule" % re.escape(top), t, re.S | re.M)
    if not m:
        die("golden 里找不到 module %s" % top)
    ports = []
    for ln in m.group(1).splitlines():
        if not ln.strip():
            continue
        pm = PORT_RE.match(ln)
        if not pm:
            die("%s 端口行解析不了：%r" % (top, ln))
        ports.append((pm.group(1), int(pm.group(2)) + 1 if pm.group(2) else 1, pm.group(3)))
    return ports, m.group(2)


def balanced(s, i):
    """s[i] == '('：返回配对的 ')' 下标。"""
    depth = 0
    for j in range(i, len(s)):
        if s[j] == "(":
            depth += 1
        elif s[j] == ")":
            depth -= 1
            if depth == 0:
                return j
    die("括号不配对")


def golden_instances(body):
    """[(模块名, 实例名, [(端口, 表达式)])]，按 golden 顺序。"""
    out = []
    for m in re.finditer(r"^  ([A-Za-z_]\w*) (\w+) \($", body, re.M):
        mod, inst = m.group(1), m.group(2)
        if mod in ("assign", "wire", "reg", "always", "logic", "initial"):
            continue
        i = m.end() - 1
        j = balanced(body, i)
        blk = body[i + 1:j]
        conns = []
        k = 0
        while True:
            pm = re.compile(r"\.(\w+)\s*\(").search(blk, k)
            if not pm:
                break
            a = pm.end() - 1
            b = balanced(blk, a)
            conns.append((pm.group(1), " ".join(blk[a + 1:b].split())))
            k = b + 1
        out.append((mod, inst, conns))
    return out


def golden_assigns(body):
    out = []
    for m in re.finditer(r"^  assign (\w+) =(.*?);", body, re.M | re.S):
        out.append((m.group(1), " ".join(m.group(2).split())))
    return out


def rng(w):
    return "[%d:0] " % (w - 1) if w > 1 else ""


# =============================================================================
#  ITTage
# =============================================================================
def ittage_child_rule(mod, inst, port):
    m = re.fullmatch(r"tables_(\d)", inst)
    if m:
        k = int(m.group(1))
        simple = {"io_req_ready": "tbl_req_ready[%d]" % k, "io_req_valid": "tbl_req_valid",
                  "io_req_bits_pc": "tbl_req_pc", "io_resp_valid": "tbl_resp_valid[%d]" % k,
                  "io_resp_bits_ctr": "tbl_resp_ctr[%d]" % k, "io_resp_bits_u": "tbl_resp_u[%d]" % k,
                  "io_update_pc": "tbl_upd[%d].pc" % k, "io_update_ghist": "tbl_upd[%d].ghist" % k,
                  "io_update_valid": "tbl_upd[%d].valid" % k, "io_update_correct": "tbl_upd[%d].correct" % k,
                  "io_update_alloc": "tbl_upd[%d].alloc" % k, "io_update_oldCtr": "tbl_upd[%d].old_ctr" % k,
                  "io_update_uValid": "tbl_upd[%d].u_valid" % k, "io_update_u": "tbl_upd[%d].u" % k,
                  "io_update_reset_u": "tbl_upd[%d].reset_u" % k}
        if port in simple:
            return simple[port]
        pm = re.fullmatch(r"io_resp_bits_target_offset_(\w+)", port)
        if pm:
            return "tbl_resp_off[%d].%s" % (k, pm.group(1))
        pm = re.fullmatch(r"io_update_(old_target_offset|target_offset)_(\w+)", port)
        if pm:
            return "tbl_upd[%d].%s.%s" % (k, pm.group(1), pm.group(2))
        return None
    if inst == "rTable":
        pm = re.fullmatch(r"io_req_pointer_(\d)", port)
        if pm:
            return "tbl_resp_off[%s].pointer" % pm.group(1)
        pm = re.fullmatch(r"io_(resp_hit|resp_region|update_region|update_hit|update_pointer)_(\d)", port)
        if pm:
            return "rt_%s[%s]" % (pm.group(1), pm.group(2))
        pm = re.fullmatch(r"io_write_(valid|region|pointer)", port)
        if pm:
            return "rt_write_%s" % pm.group(1)
        if port in ("clock", "reset"):
            return None
        die("rTable 端口 %s 无规则" % port)
    if inst == "s2_allocLFSR_prng":
        pm = re.fullmatch(r"io_out_(\d+)", port)
        if pm:
            k = int(pm.group(1))
            return "lfsr_bits[%d]" % k if k < 5 else ""
        return None
    die("ITTage 未知实例 %s" % inst)


def ittage_output_rule(name):
    m = re.fullmatch(r"io_out_s3_full_pred_(\d)_jalr_target", name)
    if m:
        return "s3_target[%s]" % m.group(1)
    return None


ITTAGE_DECL = """
  logic [PC_W-1:0]      s0_pc    [NUM_DUP];
  logic                 s0_fire  [NUM_DUP];
  logic                 s1_fire  [NUM_DUP];
  logic                 s2_fire  [NUM_DUP];
  logic [PC_W-1:0]      s3_target[NUM_DUP];
  logic                 tbl_req_valid;
  logic [PC_W-1:0]      tbl_req_pc;
  logic                 tbl_req_ready [NUM_TABLES];
  logic                 tbl_resp_valid[NUM_TABLES];
  logic [1:0]           tbl_resp_ctr  [NUM_TABLES];
  logic                 tbl_resp_u    [NUM_TABLES];
  ittage_offset_t       tbl_resp_off  [NUM_TABLES];
  ittage_upd_t          tbl_upd       [NUM_TABLES];
  logic                 rt_resp_hit      [NUM_TABLES];
  logic [REGION_W-1:0]  rt_resp_region   [NUM_TABLES];
  logic [REGION_W-1:0]  rt_update_region [2];
  logic                 rt_update_hit    [2];
  logic [PTR_W-1:0]     rt_update_pointer[2];
  logic                 rt_write_valid;
  logic [REGION_W-1:0]  rt_write_region;
  logic [PTR_W-1:0]     rt_write_pointer;
  logic [NUM_TABLES-1:0] lfsr_bits;
"""

ITTAGE_CORE = [
    ("clock", "clock"), ("reset", "reset"), ("reset_vector", "io_reset_vector"),
    ("s0_pc", "s0_pc"), ("s0_fire", "s0_fire"), ("s1_fire", "s1_fire"), ("s2_fire", "s2_fire"),
    ("s1_uftb_hit", "io_in_bits_resp_in_0_s1_uftbHit"),
    ("s1_uftb_has_indirect", "io_in_bits_resp_in_0_s1_uftbHasIndirect"),
    ("s1_ftb_close_req", "io_in_bits_resp_in_0_s1_ftbCloseReq"),
    ("base_target", "io_in_bits_resp_in_0_s2_full_pred_3_jalr_target"),
    ("tbl_req_valid", "tbl_req_valid"), ("tbl_req_pc", "tbl_req_pc"), ("tbl_req_ready", "tbl_req_ready"),
    ("tbl_resp_valid", "tbl_resp_valid"), ("tbl_resp_ctr", "tbl_resp_ctr"), ("tbl_resp_u", "tbl_resp_u"),
    ("tbl_resp_off", "tbl_resp_off"), ("tbl_upd", "tbl_upd"),
    ("rt_resp_hit", "rt_resp_hit"), ("rt_resp_region", "rt_resp_region"),
    ("rt_update_region", "rt_update_region"), ("rt_update_hit", "rt_update_hit"),
    ("rt_update_pointer", "rt_update_pointer"), ("rt_write_valid", "rt_write_valid"),
    ("rt_write_region", "rt_write_region"), ("rt_write_pointer", "rt_write_pointer"),
    ("lfsr_bits", "lfsr_bits"),
    ("update_valid", "io_update_valid"), ("update_pc", "io_update_bits_pc"),
    ("update_is_ret_raw", "io_update_bits_ftb_entry_isRet"),
    ("update_is_jalr_raw", "io_update_bits_ftb_entry_isJalr"),
    ("update_tail_offset", "io_update_bits_ftb_entry_tailSlot_offset"),
    ("update_tail_sharing", "io_update_bits_ftb_entry_tailSlot_sharing"),
    ("update_tail_valid", "io_update_bits_ftb_entry_tailSlot_valid"),
    ("update_strong_bias_1", "io_update_bits_ftb_entry_strong_bias_1"),
    ("update_cfi_valid", "io_update_bits_cfi_idx_valid"), ("update_cfi_idx", "io_update_bits_cfi_idx_bits"),
    ("update_jmp_taken", "io_update_bits_jmp_taken"), ("update_jmp_mispred", "io_update_bits_mispred_mask_2"),
    ("update_meta", "io_update_bits_meta"), ("update_full_target", "io_update_bits_full_target"),
    ("update_ghist", "io_update_bits_ghist"),
    ("s3_target", "s3_target"), ("last_stage_meta", "io_out_last_stage_meta"), ("s1_ready", "io_s1_ready"),
]

# =============================================================================
#  Tage_SC
# =============================================================================
TAGE_UPD = {"oldCtrs": "old_ctrs", "uMask": "u_mask", "mask": "mask", "takens": "takens",
            "alloc": "alloc", "us": "us", "reset_u": "reset_u"}
SC_UPD = {"mask": "mask", "tagePreds": "tage_preds", "takens": "takens", "oldCtrs": "old_ctrs"}


def tage_child_rule(mod, inst, port):
    m = re.fullmatch(r"tables_(\d)", inst)
    if m:
        k = int(m.group(1))
        if port == "io_req_ready":
            return "tbl_req_ready[%d]" % k
        pm = re.fullmatch(r"io_resps_(\d)_(valid|bits_ctr|bits_u|bits_unconf)", port)
        if pm:
            return "tbl_resp[%d][%s].%s" % (k, pm.group(1), pm.group(2).replace("bits_", ""))
        if port in ("io_update_pc", "io_update_ghist"):
            return "tbl_upd[%d].%s" % (k, port[len("io_update_"):])
        pm = re.fullmatch(r"io_update_(\w+)_(\d)", port)
        if pm and pm.group(1) in TAGE_UPD:
            return "tbl_upd[%d].%s[%s]" % (k, TAGE_UPD[pm.group(1)], pm.group(2))
        return None
    if inst == "bt":
        simple = {"io_req_ready": "bt_req_ready", "io_s1_resp_valid": "bt_s1_resp_valid",
                  "io_update_pc": "bt_upd.pc"}
        if port in simple:
            return simple[port]
        pm = re.fullmatch(r"io_s1_cnt_(\d)", port)
        if pm:
            return "bt_s1_cnt[%s]" % pm.group(1)
        pm = re.fullmatch(r"io_update_(mask|cnt|takens)_(\d)", port)
        if pm:
            return "bt_upd.%s[%s]" % (pm.group(1), pm.group(2))
        return None
    if inst == "mbistPl":
        return None
    m = re.fullmatch(r"allocLFSR_prng(_1)?", inst)
    if m:
        b = 1 if m.group(1) else 0
        pm = re.fullmatch(r"io_out_(\d+)", port)
        if pm:
            k = int(pm.group(1))
            return "lfsr_bits[%d][%d]" % (b, k) if k < 3 else ""
        return None
    m = re.fullmatch(r"scTables_(\d)", inst)
    if m:
        k = int(m.group(1))
        pm = re.fullmatch(r"io_resp_ctrs_(\d)_(\d)", port)
        if pm:
            return "sc_resp[%d][%s][%s]" % (k, pm.group(1), pm.group(2))
        if port in ("io_update_pc", "io_update_ghist"):
            return "sc_upd[%d].%s" % (k, port[len("io_update_"):])
        pm = re.fullmatch(r"io_update_(\w+)_(\d)", port)
        if pm and pm.group(1) in SC_UPD:
            return "sc_upd[%d].%s[%s]" % (k, SC_UPD[pm.group(1)], pm.group(2))
        return None
    die("Tage_SC 未知实例 %s" % inst)


def tage_output_rule(name):
    m = re.fullmatch(r"io_out_s([23])_full_pred_(\d)_br_taken_mask_(\d)", name)
    if m:
        return "s%s_taken[%s][%s]" % m.groups()
    m = re.fullmatch(r"io_out_last_stage_spec_info_sc_disagree_(\d)", name)
    if m:
        return "s3_sc_disagree[%s]" % m.group(1)
    m = re.fullmatch(r"io_perf_(\d)_value", name)
    if m:
        return "{4'h0, perf[%s]}" % m.group(1)
    return None


TAGE_DECL = """
  logic [PC_W-1:0]      s0_pc    [NUM_DUP];
  logic                 s0_fire  [NUM_DUP];
  logic                 s1_fire  [NUM_DUP];
  logic                 s2_fire  [NUM_DUP];
  logic                 tbl_req_ready [NUM_TABLES];
  tage_resp_t           tbl_resp      [NUM_TABLES][NUM_BR];
  tage_upd_t            tbl_upd       [NUM_TABLES];
  logic                 bt_req_ready;
  logic [1:0]           bt_s1_cnt     [NUM_BR];
  logic                 bt_s1_resp_valid;
  bt_upd_t              bt_upd;
  logic [5:0]           sc_resp       [NUM_SC][NUM_BR][2];
  sc_upd_t              sc_upd        [NUM_SC];
  logic [2:0]           lfsr_bits     [NUM_BR];
  logic [NUM_BR-1:0]    s2_taken      [NUM_DUP];
  logic [NUM_BR-1:0]    s3_taken      [NUM_DUP];
  logic [NUM_BR-1:0]    s3_sc_disagree;
  logic [1:0]           perf          [3];
"""

TAGE_CORE = [
    ("clock", "clock"), ("reset", "reset"), ("reset_vector", "io_reset_vector"),
    ("s0_pc", "s0_pc"), ("s0_fire", "s0_fire"), ("s1_fire", "s1_fire"), ("s2_fire", "s2_fire"),
    ("tage_enable", "io_ctrl_tage_enable"), ("sc_enable", "io_ctrl_sc_enable"),
    ("s1_uftb_taken", "{io_in_bits_resp_in_0_s1_full_pred_0_br_taken_mask_1, "
                      "io_in_bits_resp_in_0_s1_full_pred_0_br_taken_mask_0}"),
    ("tbl_req_ready", "tbl_req_ready"), ("tbl_resp", "tbl_resp"), ("tbl_upd", "tbl_upd"),
    ("bt_req_ready", "bt_req_ready"), ("bt_s1_cnt", "bt_s1_cnt"), ("bt_s1_resp_valid", "bt_s1_resp_valid"),
    ("bt_upd", "bt_upd"), ("sc_resp", "sc_resp"), ("sc_upd", "sc_upd"), ("lfsr_bits", "lfsr_bits"),
    ("update_valid", "io_update_valid"), ("update_pc", "io_update_bits_pc"),
    ("update_br0_valid", "io_update_bits_ftb_entry_brSlots_0_valid"),
    ("update_tail_sharing", "io_update_bits_ftb_entry_tailSlot_sharing"),
    ("update_tail_valid", "io_update_bits_ftb_entry_tailSlot_valid"),
    ("update_strong_bias", "{io_update_bits_ftb_entry_strong_bias_1, io_update_bits_ftb_entry_strong_bias_0}"),
    ("update_br_taken", "{io_update_bits_br_taken_mask_1, io_update_bits_br_taken_mask_0}"),
    ("update_mispred", "{io_update_bits_mispred_mask_1, io_update_bits_mispred_mask_0}"),
    ("update_meta", "io_update_bits_meta"), ("update_ghist", "io_update_bits_ghist"),
    ("s2_taken", "s2_taken"), ("s3_taken", "s3_taken"), ("s3_sc_disagree", "s3_sc_disagree"),
    ("last_stage_meta", "io_out_last_stage_meta"), ("s1_ready", "io_s1_ready"), ("perf", "perf"),
]

TAGE_ALIAS = {"bd_%s" % f: "boreChildrenBd_bore_%s" % f
              for f in ["array", "all", "req", "ack", "writeen", "be", "addr", "indata", "readen",
                        "addr_rd", "outdata"]}

TARGETS = {
    "ITTage": dict(pkgs=["ittage_pkg"], child_rule=ittage_child_rule, out_rule=ittage_output_rule,
                   decl=ITTAGE_DECL, core="xs_ITTage_core", core_conns=ITTAGE_CORE),
    "Tage_SC": dict(pkgs=["tage_sc_pkg"], child_rule=tage_child_rule, out_rule=tage_output_rule,
                    decl=TAGE_DECL, core="xs_Tage_SC_core", core_conns=TAGE_CORE,
                    keep=r"childBd(_\d+)?_\w+", alias=TAGE_ALIAS),
}


def dup_assigns():
    L = ["  // ---- 4 份 dup 的 PC 与各级 fire ----"]
    for d in range(4):
        L.append("  assign s0_pc[%d]   = io_in_bits_s0_pc_%d;" % (d, d))
    for s in range(3):
        for d in range(4):
            L.append("  assign s%d_fire[%d] = io_s%d_fire_%d;" % (s, d, s, d))
    return L


def build(top):
    spec = TARGETS[top]
    ports, body = golden_module(top)
    pnames = {n for _, _, n in ports}
    inputs = {n for d, _, n in ports if d == "input"}
    outputs = [n for d, _, n in ports if d == "output"]
    drivers = {}

    L = []
    L.append("module %s" % top)
    for p in spec["pkgs"]:
        L.append("  import %s::*;" % p)
    L.append("(")
    L.append(",\n".join("  %-6s %s%s" % (d, rng(w), n) for d, w, n in ports))
    L.append(");")
    L.append(spec["decl"].rstrip("\n"))
    L.append("")
    L.extend(dup_assigns())
    L.append("")
    L.append("  // ---- 可读核：本预测器自己的全部逻辑 ----")
    L.append("  %s u_core (" % spec["core"])
    L.append(",\n".join("    .%-21s (%s)" % c for c in spec["core_conns"]))
    L.append("  );")
    for _, e in spec["core_conns"]:
        if e in outputs:
            drivers.setdefault(e, []).append("u_core")
    L.append("")
    L.append("  // ---- 子模块（实例名 / 端口顺序同 golden）----")
    kept = set()
    inst_start = len(L)
    for mod, inst, conns in golden_instances(body):
        L.append("  %s %s (" % (mod, inst))
        cl = []
        for port, expr in conns:
            rule = spec["child_rule"](mod, inst, port)
            gold_is_port = expr in pnames
            keep_re = spec.get("keep")
            if rule is None and keep_re and re.fullmatch(keep_re, expr):
                # 子模块之间的直连网（MBIST 子链）：原名保留，按 golden 声明位宽声明
                kept.add(expr)
                cl.append((port, expr))
                continue
            alias = spec.get("alias", {}).get(expr)
            if rule is None and alias is not None:
                # golden 里给顶层端口起的别名网（wire bd_x = 顶层口）：直接接顶层口
                cl.append((port, alias))
                if alias in outputs:
                    drivers.setdefault(alias, []).append(inst)
                continue
            if port in ("clock", "reset"):
                if expr != port:
                    die("%s.%s 接的不是 %s" % (inst, port, port))
                cl.append((port, port))
                continue
            if rule is None:
                if not gold_is_port:
                    die("%s.%s：golden 接的是内部网 %r，却没有规则" % (inst, port, expr))
                cl.append((port, expr))
                if expr in outputs:
                    drivers.setdefault(expr, []).append(inst)
            else:
                if gold_is_port:
                    die("%s.%s：规则认领了，但 golden 接的是顶层端口 %s" % (inst, port, expr))
                if rule == "" and expr != "/* unused */":
                    die("%s.%s：规则说悬空，golden 却接了 %r" % (inst, port, expr))
                cl.append((port, rule))
        L.append(",\n".join("    .%-40s (%s)" % c for c in cl))
        L.append("  );")
    if kept:
        decl = []
        for nm in sorted(kept, key=lambda x: [int(t) if t.isdigit() else t for t in re.split(r"(\d+)", x)]):
            m = re.search(r"^\s*wire\s+(\[\d+:\d+\]\s+)?%s;" % re.escape(nm), body, re.M)
            if not m:
                die("子模块直连网 %s 在 golden 里找不到声明" % nm)
            decl.append("  wire %s%s;" % ((m.group(1) or "").strip() + " " if m.group(1) else "", nm))
        L[inst_start:inst_start] = ["  // MBIST 子链：子模块之间的直连网（名字同 golden）"] + decl + [""]
    L.append("")
    L.append("  // ---- 顶层输出 ----")
    for lhs, rhs in golden_assigns(body):
        if lhs not in outputs:
            continue
        rule = spec["out_rule"](lhs)
        if rule is not None:
            L.append("  assign %s = %s;" % (lhs, rule))
        elif rhs in inputs:
            L.append("  assign %s = %s;  // 透传" % (lhs, rhs))
        elif lhs in drivers:
            continue
        else:
            die("输出 %s = %r 既不是透传也没有规则" % (lhs, rhs))
        drivers.setdefault(lhs, []).append("assign")
    for o in outputs:
        if len(drivers.get(o, [])) != 1:
            die("输出 %s 的驱动者 %r 不是恰好一个" % (o, drivers.get(o)))
    L.append("")
    L.append("endmodule")
    txt = "\n".join(L) + "\n"
    # 输入使用集合：golden 体里出现 <=> 生成体里出现
    gen_body = txt[txt.index(");\n") + 3:]
    for i in sorted(inputs):
        g = re.search(r"\b%s\b" % i, body) is not None
        n = re.search(r"\b%s\b" % i, gen_body) is not None
        if g != n:
            die("输入 %s：golden 体里%s用到，生成体里%s用到" % (i, "" if g else "没", "" if n else "没"))
    return txt


def splice(text, body, path):
    if text.count(BEGIN) != 1 or text.count(END) != 1:
        die("%s 里 GENERATED 标记不是恰好一对" % path)
    a = text.index(BEGIN) + len(BEGIN)
    b = text.index(END)
    return text[:a] + body + text[b:]


def main():
    check = "--check" in sys.argv[1:]
    rc = 0
    for top in TARGETS:
        p = os.path.join(REPO, "rtl/frontend/%s.sv" % top)
        old = open(p).read()
        new = splice(old, build(top), p)
        rel = os.path.relpath(p, REPO)
        if check:
            if old != new:
                print("[gencheck] %s 与生成结果不一致" % rel)
                rc = 1
            else:
                print("[gencheck] %s OK" % rel)
        elif old != new:
            open(p, "w").write(new)
            print("wrote", rel)
        else:
            print("unchanged", rel)
    return rc


if __name__ == "__main__":
    sys.exit(main())
