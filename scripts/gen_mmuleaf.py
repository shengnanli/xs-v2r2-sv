#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""gen_mmuleaf.py —— mmuleaf lane 的机械派生区：FM「匹配前」钉点 fm_pins_pre.tcl + 子模块例化连线。

golden 是 firtool 展平后的寄存器名（array_3_tag、valids_7、last_REG_5 …），重写核用 generate 块 /
数组 / 语义名（array[3].tag、valids[7]、array[5].last_REG …）。名字对不上时 Formality 只能靠签名
分析去猜，表项多了就会卡在 matching。这里按规则表把 **golden 顶层每一个寄存器的每一位** 一一对应
到重写核里的寄存器位，生成 set_user_match 钉点：

  · 规则表 fail-closed：每个 golden 寄存器必须恰好命中一条规则，否则拒绝生成；
  · 映射必须是单射（两个 golden 寄存器不许落到同一个重写寄存器），否则拒绝生成；
  · 生成的 tcl 运行时逐条数 set_user_match 的返回值（它从不抛异常，0 = 没配上），
    拒一条或总数不等于字面整数（= golden 顶层寄存器总位数）就 error。

set_user_match 只声明两点对应，比较照比：不约束 ref、不改 appvar、不加黑盒。

另外，重写核里例化 golden 子模块（扁平端口 io_in_<i>_valid …）的连线没有设计决策，只是长长的逐口
连线，也在这里按 golden 子模块端口表生成，写进 rtl 文件的 `BEGIN GENERATED(<tag>)` 区：
每个端口必须恰好被一条映射规则认领，认领不了（或有规则没用上）就拒绝生成。

用法：
    python3 scripts/gen_mmuleaf.py            # 生成（幂等：内容不变不写文件）
    python3 scripts/gen_mmuleaf.py --check    # 产物与生成器不一致则 rc=1
"""
import argparse
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.normpath(os.path.join(HERE, ".."))
GOLDEN_DIR = "/home/eda/xs-env/G1-canonical/golden-rtl"


def golden_top_regs(module):
    """golden 顶层（不含子模块）寄存器声明：[(名字, 位宽)]，按声明顺序。"""
    t = open(os.path.join(GOLDEN_DIR, module + ".sv")).read()
    body = t[t.index("module %s(" % module):]
    body = body[:body.index("\nendmodule")]
    body = re.sub(r"reg\s+(\[\d+:\d+\])\s*\n\s*", r"reg \1 ", body)  # 折行的声明
    out = []
    for a, b, n in re.findall(r"^\s*reg\s+(?:\[(\d+):(\d+)\]\s+)?(\w+);", body, re.M):
        out.append((n, int(a) - int(b) + 1 if a else 1))
    if not out:
        raise SystemExit("gen_mmuleaf: golden %s 里一个寄存器也没解析到" % module)
    return out


def esc(s):
    return s.replace("[", "\\[").replace("]", "\\]")


# -----------------------------------------------------------------------------
#  规则表：golden 寄存器名 -> (重写核里的寄存器名, 数组下标串)
#  最终 impl 路径 = u_core/<名>_reg<下标串>[<位>]（单比特无 [<位>]）
# -----------------------------------------------------------------------------
def sbva_rule(name):
    rules = [
        # 表项字段：generate 块 array[i] 里的同名字段
        (r"array_(\d+)_(tag|bit_vec|active|cnt)", lambda m: ("array[%s].%s" % (m[1], m[2]), "")),
        (r"valids_(\d+)", lambda m: ("valids", "[%s]" % m[1])),
        # RegNext(flush)：每项一份，第 0 项无后缀
        (r"last_REG(?:_(\d+))?", lambda m: ("array[%d].last_REG" % int(m[1] or 0), "")),
        # 内联的 PLRU 树 -> 共享辅助件实例
        (r"state_reg", lambda m: ("u_plru/state_reg", "")),
        # 只喂断言的三个寄存器（§7）
        (r"REG", lambda m: ("assert_s0_valid_d1", "")),
        (r"r", lambda m: ("assert_s0_hit_d1", "")),
        (r"r_1", lambda m: ("assert_plru_way_d1", "")),
        # 其余流水寄存器与 golden 同名
        (r"(s[1-5]_\w+)", lambda m: (m[1], "")),
    ]
    hits = []
    for pat, fn in rules:
        m = re.fullmatch(pat, name)
        if m:
            hits.append(fn(m))
    return hits


# -----------------------------------------------------------------------------
#  子模块例化连线
# -----------------------------------------------------------------------------
PORT_RE = re.compile(r"^\s*(input|output)\s+(?:\[(\d+):0\]\s+)?(\w+)\s*,?\s*$")


def golden_ports(mod):
    t = open(os.path.join(GOLDEN_DIR, mod + ".sv")).read()
    m = re.search(r"^module\s+%s\s*\((.*?)^\);" % re.escape(mod), t, re.S | re.M)
    if not m:
        raise SystemExit("gen_mmuleaf: golden 里找不到 module %s" % mod)
    out = []
    for ln in m.group(1).splitlines():
        if not ln.strip():
            continue
        pm = PORT_RE.match(ln)
        if not pm:
            raise SystemExit("gen_mmuleaf: %s 端口行解析不了：%r" % (mod, ln))
        out.append(pm.group(3))
    return out


def gen_inst(mod, inst, rules, indent="  "):
    """rules: [(正则, 连线表达式模板)]，模板里 {0},{1}… 是正则分组。每口恰好一条、每条至少用一次。"""
    ports = golden_ports(mod)
    used = [0] * len(rules)
    width = max(len(p) for p in ports)
    lines = []
    for p in ports:
        hits = [(k, re.fullmatch(pat, p)) for k, (pat, _) in enumerate(rules)]
        hits = [(k, m) for k, m in hits if m]
        if len(hits) != 1:
            raise SystemExit("gen_mmuleaf: %s.%s 被 %d 条规则认领（必须恰好 1）" % (mod, p, len(hits)))
        k, m = hits[0]
        used[k] += 1
        lines.append("%s  .%s (%s)" % (indent, p.ljust(width), rules[k][1].format(*m.groups())))
    for k, n in enumerate(used):
        if n == 0:
            raise SystemExit("gen_mmuleaf: %s 的规则 %r 一个端口也没认领（端口表变了？）" % (mod, rules[k][0]))
    return "%s%s %s (\n%s\n%s);" % (indent, mod, inst, ",\n".join(lines), indent)


def replace_region(text, tag, body):
    b = "// BEGIN GENERATED(%s) —— scripts/gen_mmuleaf.py\n" % tag
    pat = re.compile(r"([ \t]*)" + re.escape(b) + r".*?^([ \t]*)// END GENERATED\n", re.S | re.M)
    m = pat.search(text)
    if not m:
        raise SystemExit("gen_mmuleaf: 找不到生成区 %s" % tag)
    ind = m.group(1)
    new = ind + b + body + "\n" + ind + "// END GENERATED\n"
    return text[:m.start()] + new + text[m.end():]


def gen_prefetchfilter_rtl():
    path = os.path.join(REPO, "rtl", "memblock", "PrefetchFilter.sv")
    text = open(path).read()
    tlb = gen_inst("RRArbiterInit_5", "tlb_req_arb", [
        (r"clock", "clock"),
        (r"reset", "reset"),
        (r"io_in_(\d+)_ready", "tlb_arb_in_ready[{0}]"),
        (r"io_in_(\d+)_valid", "tlb_arb_in_valid[{0}]"),
        (r"io_in_(\d+)_bits_vaddr", "tlb_arb_in_vaddr[{0}]"),
        (r"io_out_valid", "tlb_arb_out_valid"),
        (r"io_out_bits_vaddr", "tlb_arb_out_vaddr"),
    ])
    pf = gen_inst("RRArbiterInit_6", "pf_req_arb", [
        (r"clock", "clock"),
        (r"reset", "reset"),
        (r"io_in_(\d+)_ready", "pf_arb_in_ready[{0}]"),
        (r"io_in_(\d+)_valid", "pf_arb_in_valid[{0}]"),
        (r"io_in_(\d+)_bits", "pf_arb_in_addr[{0}]"),
        (r"io_out_valid", "l2_pf_valid"),
        (r"io_out_bits", "l2_pf_addr"),
        (r"io_chosen", "pf_arb_chosen"),
    ])
    text = replace_region(text, "tlb_req_arb", tlb)
    text = replace_region(text, "pf_req_arb", pf)
    return path, text



# -----------------------------------------------------------------------------
#  TLB（itlb）wrapper 的机械派生区
# -----------------------------------------------------------------------------
def golden_port_lines(mod):
    """golden 端口声明原文行（去行尾逗号），与 golden_ports 同序。"""
    t = open(os.path.join(GOLDEN_DIR, mod + ".sv")).read()
    m = re.search(r"^module\s+%s\s*\((.*?)^\);" % re.escape(mod), t, re.S | re.M)
    return [ln.rstrip().rstrip(",") for ln in m.group(1).splitlines() if ln.strip()]


def golden_port_dirs(mod):
    out = []
    for ln in golden_port_lines(mod):
        pm = PORT_RE.match(ln)
        out.append((pm.group(1), pm.group(3)))
    return out


def gen_assigns(pairs, rules, handled, fmt, what):
    """pairs: 待认领的端口名；每个要么被 handled（别处已接）收走，要么恰好命中一条规则。"""
    used = [0] * len(rules)
    lines = []
    for p in pairs:
        if p in handled:
            continue
        hits = [(k, re.fullmatch(pat, p)) for k, (pat, _) in enumerate(rules)]
        hits = [(k, m) for k, m in hits if m]
        if len(hits) != 1:
            raise SystemExit("gen_mmuleaf: %s 端口 %s 被 %d 条规则认领（必须恰好 1）" % (what, p, len(hits)))
        k, m = hits[0]
        used[k] += 1
        lines.append(fmt(p, rules[k][1].format(*m.groups())))
    for k, n in enumerate(used):
        if n == 0:
            raise SystemExit("gen_mmuleaf: %s 的规则 %r 一个端口也没认领" % (what, rules[k][0]))
    return lines


def gen_tlb_rtl():
    path = os.path.join(REPO, "rtl", "memblock", "TLB.sv")
    text = open(path).read()
    plines = golden_port_lines("TLB")
    ports_body = "\n".join("  " + ln.strip() + ("," if k < len(plines) - 1 else "")
                           for k, ln in enumerate(plines))
    text = replace_region(text, "tlb_ports", ports_body)

    text = replace_region(text, "sfence_delay", gen_inst("DelayN_9", "sfence_delay", [
        (r"clock", "clock"),
        (r"io_in_(\w+)", "io_sfence_{0}"),
        (r"io_out_valid", "sfence_d_valid"),
        (r"io_out_bits_(\w+)", "sfence_d_{0}"),
    ]))
    text = replace_region(text, "csr_delay", gen_inst("DelayN_7", "csr_delay", [
        (r"clock", "clock"),
        (r"io_in_(\w+)", "io_csr_{0}"),
        (r"io_out_(satp|vsatp|hgatp|pmm)_(\w+)", "csr_d.{0}_{1}"),
        (r"io_out_priv_(?!debug$)(\w+)", "csr_d.priv_{0}"),
        (r"io_out_priv_debug", "csr_d_priv_debug"),
        (r"io_out_mbmc_(\w+)", "csr_d_mbmc_{0}"),
    ]))

    ptw_in = [n for d, n in golden_port_dirs("TLB") if d == "input" and n.startswith("io_ptw_resp_bits_")]
    lines = gen_assigns(ptw_in, [
        (r"io_ptw_resp_bits_s2xlate", "ptw_resp.s2xlate"),
        (r"io_ptw_resp_bits_getGpa", "ptw_resp.get_gpa"),
        (r"io_ptw_resp_bits_(s[12])_entry_(\w+)", "ptw_resp.{0}.entry_{1}"),
        (r"io_ptw_resp_bits_s1_(ppn_low|valididx|pteidx)_(\d)", "ptw_resp.s1.{0}[{1}]"),
        (r"io_ptw_resp_bits_s1_(addr_low|pf|af)", "ptw_resp.s1.{0}"),
        (r"io_ptw_resp_bits_s2_(gpf|gaf)", "ptw_resp.s2.{0}"),
    ], set(), lambda port, lhs: "  assign %s = %s;" % (lhs, port), "TLB.ptw_resp")
    text = replace_region(text, "ptw_resp", "\n".join(lines))

    text = replace_region(text, "entries", gen_inst("TlbStorageWrapper", "entries", [
        (r"clock", "clock"),
        (r"reset", "reset"),
        (r"io_sfence_valid", "sfence_d_valid"),
        (r"io_sfence_bits_(\w+)", "sfence_d_{0}"),
        (r"io_csr_(satp_asid|vsatp_asid|hgatp_vmid|priv_virt)", "csr_d.{0}"),
        (r"io_csr_mbmc_(\w+)", "csr_d_mbmc_{0}"),
        (r"io_r_req_(\d)_valid", "stor_r_req_valid[{0}]"),
        (r"io_r_req_(\d)_bits_(vpn|s2xlate)", "stor_r_req_{1}[{0}]"),
        (r"io_r_resp_(\d)_bits_hit", "stor_r_hit[{0}]"),
        (r"io_r_resp_(\d)_bits_(ppn|pbmt|g_pbmt|s2xlate)_0", "stor_r_{1}[{0}]"),
        (r"io_r_resp_(\d)_bits_perm_0_(\w+)", "stor_r_perm[{0}].{1}"),
        (r"io_r_resp_(\d)_bits_g_perm_0_(\w+)", "stor_r_g_perm[{0}].{1}"),
        (r"io_w_valid", "stor_w_valid"),
        (r"io_w_bits_data_(\w+)", "io_ptw_resp_bits_{0}"),
    ]))

    outs = [n for d, n in golden_port_dirs("TLB") if d == "output"]
    handled = {"io_requestor_2_req_ready", "io_requestor_2_resp_valid", "io_perf_0_value",
               "io_perf_1_value", "gatewayIn_packed_3_bore", "gatewayIn_packed_4_bore",
               "gatewayIn_packed_5_bore"}
    lines = gen_assigns(outs, [
        (r"io_requestor_(\d)_resp_bits_(paddr|gpaddr|pbmt)_0", "resp_{1}[{0}]"),
        (r"io_requestor_(\d)_resp_bits_miss", "resp_miss[{0}]"),
        (r"io_requestor_(\d)_resp_bits_isForVSnonLeafPTE", "resp_vs_non_leaf[{0}]"),
        (r"io_requestor_(\d)_resp_bits_excp_0_(gpf|pf|af)_instr", "resp_{1}[{0}]"),
        (r"io_ptw_req_(\d)_valid", "ptw_req_valid[{0}]"),
        (r"io_ptw_req_(\d)_bits_(vpn|s2xlate)", "ptw_req_{1}[{0}]"),
        (r"io_ptw_req_(\d)_bits_getGpa", "ptw_req_get_gpa[{0}]"),
    ], handled, lambda port, rhs: "  assign %s = %s;" % (port, rhs), "TLB.outputs")
    text = replace_region(text, "resp_out", "\n".join(lines))
    return path, text



def gen_ptwfe_rtl():
    path = os.path.join(REPO, "rtl", "memblock", "PTWFilterEntry.sv")
    text = open(path).read()
    plines = golden_port_lines("PTWFilterEntry")
    text = replace_region(text, "ptwfe_ports",
                          "\n".join("  " + ln.strip() + ("," if k < len(plines) - 1 else "")
                                    for k, ln in enumerate(plines)))
    ptw_in = [n for d, n in golden_port_dirs("PTWFilterEntry")
              if d == "input" and n.startswith("io_ptw_resp_bits_")]
    lines = gen_assigns(ptw_in, [
        (r"io_ptw_resp_bits_s2xlate", "ptw_resp.s2xlate"),
        (r"io_ptw_resp_bits_s1_entry_(tag|asid|vmid|n|level)", "ptw_resp.s1_{0}"),
        (r"io_ptw_resp_bits_s1_entry_perm_g", "ptw_resp.s1_perm_g"),
        (r"io_ptw_resp_bits_s1_addr_low", "ptw_resp.s1_addr_low"),
        (r"io_ptw_resp_bits_s1_valididx_(\d)", "ptw_resp.s1_valididx[{0}]"),
        (r"io_ptw_resp_bits_s2_entry_(tag|vmid|n|level)", "ptw_resp.s2_{0}"),
    ], set(), lambda port, lhs: "  assign %s = %s;" % (lhs, port), "PTWFilterEntry.ptw_resp")
    text = replace_region(text, "ptwfe_resp", "\n".join(lines))
    return path, text



# -----------------------------------------------------------------------------
#  TLB 的「匹配后」钉点 fm_pins.tcl：子模块内部的对称死位
# -----------------------------------------------------------------------------
#  TLB 本体 FM 时三个子模块两侧白盒（ref golden、impl 重写件），子模块内部寄存器的名字两侧不同
#  （golden DelayN 的 REG_<字段> / REG_1_<字段> vs 重写件 u_core/g_chain.stage_reg[级][位]；
#  golden TLBFA 的 reqVpn{,_1,_2} vs 重写件 u_core/g_port[i].req_vpn_q）。
#  其中在 itlb 里**没有读者**的那些位 FM 签名分析配不上（unread 点没有扇出可比），
#  诊断跑实测 95(95) unmatched unread。逐位一一钉上，再由 vmucp 实开比较。
#  哪些位：
#    · csr_delay：itlb 不用 priv.{mxr,sum,vmxr,vsum,spvp,dmode,debug} 与 pmm.* —— 两级各 18 位；
#    · sfence_delay：表项刷新只用 sfence.addr[49:12]（vpn），addr[11:0] 两级各 12 位；
#    · entries/page_itlb_storage_fa：三个查询口打拍的 vpn 只比到 [26:0]，[37:27] 各 11 位；
#    · 本体：两个断言打拍寄存器 REG_4 / REG_5（核里叫 assert_resp_ready_ok / assert_miss_has_req）。
#  DelayN 的载荷拼接顺序从**重写件源码**里 `assign payload_in = {...}` 现读，位宽从 golden 端口表读，
#  所以字段偏移不是手抄的。钉点数字面 95，少一个多一个都 error。
TLB_DEAD_CSR_FIELDS = ["priv_mxr", "priv_sum", "priv_vmxr", "priv_vsum", "priv_spvp", "priv_dmode",
                       "priv_debug", "pmm_mseccfg", "pmm_menvcfg", "pmm_henvcfg", "pmm_hstatus",
                       "pmm_senvcfg"]


def delayn_layout(mod):
    """{字段名: (lsb, 宽)}，字段名去掉 io_in_ 前缀；按重写件 payload_in 的拼接顺序（高位在前）。"""
    widths = {}
    t = open(os.path.join(GOLDEN_DIR, mod + ".sv")).read()
    m = re.search(r"^module\s+%s\s*\((.*?)^\);" % mod, t, re.S | re.M)
    for ln in m.group(1).splitlines():
        pm = PORT_RE.match(ln)
        if pm and pm.group(3).startswith("io_in_"):
            widths[pm.group(3)[len("io_in_"):]] = int(pm.group(2)) + 1 if pm.group(2) else 1
    src = open(os.path.join(REPO, "rtl", "common", mod + ".sv")).read()
    mm = re.search(r"assign payload_in =\s*\{(.*?)\};", src, re.S)
    if not mm:
        raise SystemExit("gen_mmuleaf: %s 重写件里找不到 payload_in 拼接" % mod)
    order = [x.strip()[len("io_in_"):] for x in mm.group(1).split(",")]
    if sorted(order) != sorted(widths):
        raise SystemExit("gen_mmuleaf: %s payload_in 字段集合与 golden 端口表不一致" % mod)
    lay, lsb = {}, 0
    for f in reversed(order):
        lay[f] = (lsb, widths[f])
        lsb += widths[f]
    return lay


def gen_tlb_post_pins():
    pairs = []
    csr = delayn_layout("DelayN_7")
    for stage, gpre in ((0, "REG_"), (1, "REG_1_")):
        for f in TLB_DEAD_CSR_FIELDS:
            lsb, w = csr[f]
            for b in range(w):
                r = "r:/WORK/TLB/csr_delay/%s%s_reg%s" % (gpre, f, ("[%d]" % b) if w > 1 else "")
                i = "i:/WORK/TLB/csr_delay/u_core/g_chain.stage_reg[%d][%d]" % (stage, lsb + b)
                pairs.append((r, i))
    sf = delayn_layout("DelayN_9")
    lsb, w = sf["bits_addr"]
    for stage, gpre in ((0, "REG_"), (1, "REG_1_")):
        for b in range(12):
            pairs.append(("r:/WORK/TLB/sfence_delay/%sbits_addr_reg[%d]" % (gpre, b),
                          "i:/WORK/TLB/sfence_delay/u_core/g_chain.stage_reg[%d][%d]" % (stage, lsb + b)))
    for port, gname in ((0, "reqVpn"), (1, "reqVpn_1"), (2, "reqVpn_2")):
        for b in range(27, 38):
            pairs.append(("r:/WORK/TLB/entries/page_itlb_storage_fa/%s_reg[%d]" % (gname, b),
                          "i:/WORK/TLB/entries/page_itlb_storage_fa/u_core/g_port[%d].req_vpn_q_reg[%d]" % (port, b)))
    pairs.append(("r:/WORK/TLB/REG_4_reg", "i:/WORK/TLB/u_core/assert_resp_ready_ok_reg"))
    pairs.append(("r:/WORK/TLB/REG_5_reg", "i:/WORK/TLB/u_core/assert_miss_has_req_reg"))
    if len(pairs) != 95 or len(set(r for r, _ in pairs)) != 95 or len(set(i for _, i in pairs)) != 95:
        raise SystemExit("gen_mmuleaf: TLB 匹配后钉点不是 95 对一一对应")
    o = []
    o.append("# TLB FM「匹配后」钉点 —— 自动生成：scripts/gen_mmuleaf.py（勿手改）")
    o.append("#")
    o.append("# 子模块内部 + 本体断言打拍里两侧对称的死位（itlb 不读），名字两侧不同、签名分析配不上，")
    o.append("# 逐位一一钉上（依据见生成器注释与 verif/fm_target_config/TLB.tcl）。只 set_user_match，")
    o.append("# 比较照比：不约束 ref、不改 appvar、不加黑盒。fail-closed：逐条数返回值，总数字面 95。")
    o.append("# 跑在 sidecar 的 safe child interp 里：只用 set_user_match / puts / error。进 fm.log 的输出一律 ASCII。")
    o.append("set ::TLB_PIN_OK 0")
    o.append("set ::TLB_PIN_BAD 0")
    o.append("proc tlb_pin {r i} {")
    o.append("  if {[set_user_match $r $i]} { incr ::TLB_PIN_OK } else {")
    o.append("    incr ::TLB_PIN_BAD")
    o.append("    if {$::TLB_PIN_BAD <= 10} { puts \"TLB_PIN_FAIL: $r <-> $i\" }")
    o.append("  }")
    o.append("}")
    o.append("puts \"TLB_PIN_BEGIN TLB expect=95\"")
    for r, i in pairs:
        o.append("tlb_pin %s %s" % (esc(r), esc(i)))
    o.append("puts \"TLB_PIN_END TLB ok=$::TLB_PIN_OK bad=$::TLB_PIN_BAD\"")
    o.append("if {$::TLB_PIN_BAD != 0} { error \"TLB_PIN_MISS=$::TLB_PIN_BAD\" }")
    o.append("if {$::TLB_PIN_OK != 95} { error \"TLB_PIN_COUNT=$::TLB_PIN_OK expect=95\" }")
    return os.path.join(REPO, "verif", "ut", "TLB", "fm_pins.tcl"), "\n".join(o) + "\n"



def gen_pmp_rtl():
    path = os.path.join(REPO, "rtl", "memblock", "PMP.sv")
    text = open(path).read()
    plines = golden_port_lines("PMP")
    text = replace_region(text, "pmp_ports",
                          "\n".join("  " + ln.strip() + ("," if k < len(plines) - 1 else "")
                                    for k, ln in enumerate(plines)))
    outs = [n for d, n in golden_port_dirs("PMP") if d == "output"]
    lines = gen_assigns(outs, [
        (r"io_(pmp|pma)_(\d+)_cfg_(\w+)", "{0}_cfg[{1}].{2}"),
        (r"io_(pmp|pma)_(\d+)_(addr|mask)", "{0}_{2}[{1}]"),
    ], set(), lambda port, rhs: "  assign %s = %s;" % (port, rhs), "PMP.outputs")
    text = replace_region(text, "pmp_outputs", "\n".join(lines))
    # 每项 mask 的两个写者谁排在后面：wen_reg 生成序号大的那个 when 后生成、赢
    wen = pmp_wen_targets()
    idx = {a: (0 if n == "wen_reg_last_REG" else int(n.rsplit("_", 1)[1])) for n, a in wen.items()}
    words = []
    for cb, ab in ((0x3A0, 0x3B0), (0x7C0, 0x7C8)):
        v = 0
        for i in range(32):
            if idx[ab + i] > idx[cb + 2 * (i // 8)]:
                v |= 1 << i
        words.append(v)
    prio = ("  localparam logic [NUM-1:0] ADDR_WRITE_WINS [2] = '{\n"
            "      32'h%08X,     // PMP 表\n      32'h%08X };   // PMA 表" % (words[0], words[1]))
    text = replace_region(text, "pmp_mask_prio", prio)
    return path, text


def pmp_wen_targets():
    """golden wen_reg_last_REG{,_k} -> 它所在的 CSR 地址（从 golden 的赋值语句现读）。"""
    t = open(os.path.join(GOLDEN_DIR, "PMP.sv")).read()
    flat = re.sub(r"\s+", " ", t)
    out = {}
    for name, addr in re.findall(r"(wen_reg_last_REG(?:_\d+)?) <= io_distribute_csr_w_valid "
                                 r"& io_distribute_csr_w_bits_addr == 12'h([0-9A-F]+);", flat):
        out[name] = int(addr, 16)
    if len(out) != 72:
        raise SystemExit("gen_mmuleaf: PMP 的 wen 寄存器地址只解析到 %d 个（应 72）" % len(out))
    return out


PMP_WEN = None


def pmp_rule(name):
    global PMP_WEN
    if PMP_WEN is None:
        PMP_WEN = pmp_wen_targets()
    T = {"pmp": 0, "pma": 1}
    rules = [
        (r"(pmp|pma)Mapping_cfgMerged_(\d+)", lambda m: ("cfg_merged", "[%d][%s]" % (T[m[1]], m[2]))),
        (r"(pmp|pma)Mapping_(addr|mask)_(\d+)", lambda m: (m[2], "[%d][%s]" % (T[m[1]], m[3]))),
        (r"wdata_reg", lambda m: ("wdata_reg", "")),
    ]
    hits = []
    for pat, fn in rules:
        mm = re.fullmatch(pat, name)
        if mm:
            hits.append(fn(mm))
    if re.fullmatch(r"wen_reg_last_REG(?:_\d+)?", name):
        a = PMP_WEN[name]
        for t, cb, ab in ((0, 0x3A0, 0x3B0), (1, 0x7C0, 0x7C8)):
            if cb <= a < cb + 8 and (a - cb) % 2 == 0:
                hits.append(("cfg_wen", "[%d][%d]" % (t, (a - cb) // 2)))
            if ab <= a < ab + 32:
                hits.append(("addr_wen", "[%d][%d]" % (t, a - ab)))
    return hits


def pf_rule(name):
    rules = [
        (r"entries_(\d+)_(region_tag|region_addr|region_bits|filter_bits|paddr_valid|decr_mode)",
         lambda m: ("entries[%s].%s" % (m[1], m[2]), "")),
        (r"valids_(\d+)", lambda m: ("valids", "[%s]" % m[1])),
        (r"(s[123])_tlb_fire_vec_r_r_(\d+)", lambda m: ("%s_tlb_fire_vec" % m[1], "[%s]" % m[2])),
        (r"state_reg", lambda m: ("u_plru/state_reg", "")),
        (r"(prev_\w+|s1_(?!tlb_fire_vec_r_r_)\w+|s3_tlb_resp_\w+)", lambda m: (m[1], "")),
    ]
    hits = []
    for pat, fn in rules:
        m = re.fullmatch(pat, name)
        if m:
            hits.append(fn(m))
    return hits


TARGETS = {
    # 目标名: (UT 目录, 规则函数, 打印前缀)
    "StreamBitVectorArray": ("StreamBitVectorArray", sbva_rule, "SBVA"),
    "PrefetchFilter":       ("PrefetchFilter", pf_rule, "PFF"),
    "PMP":                  ("PMP", pmp_rule, "PMP"),
}

RTL_GENERATORS = [gen_prefetchfilter_rtl, gen_tlb_rtl, gen_ptwfe_rtl, gen_pmp_rtl]


def gen_pins(top, rule, tag, design=None, ref_pre=None, impl_pre=None, note=None):
    """design/ref_pre/impl_pre：在父级里钉子模块时用（例：L2TLB 里的 pmp 实例）。"""
    design = design or top
    ref_pre = ref_pre if ref_pre is not None else "r:/WORK/%s/" % design
    impl_pre = impl_pre if impl_pre is not None else "i:/WORK/%s/u_core/" % design
    regs = golden_top_regs(top)
    total = sum(w for _, w in regs)
    seen = set()
    o = []
    o.append("# %s FM「匹配前」钉点 —— 自动生成：scripts/gen_mmuleaf.py（勿手改）" % design)
    if note:
        for ln in note:
            o.append("# " + ln)
    o.append("#")
    o.append("# 只消 golden 展平寄存器名与重写核 generate 块/数组/语义名之间的命名鸿沟（规则见生成器）。")
    o.append("# set_user_match 只是声明两点对应，比较照比：不约束 ref、不改 appvar、不加黑盒。")
    o.append("# fail-closed：set_user_match 从不抛异常（返回 0 = 没配上），所以逐条数返回值；")
    o.append("# 拒一条或总数不等于字面整数（= golden 顶层寄存器位数）就 error（safe interp 里不用 exit）。")
    o.append("# 进 fm.log 的输出一律 ASCII。")
    o.append("set ::%s_PIN_EXPECT %d" % (tag, total))
    o.append("set ::%s_PIN_OK 0" % tag)
    o.append("set ::%s_PIN_BAD 0" % tag)
    o.append("proc %s_pin {g i w} {" % tag.lower())
    o.append("  if {$w == 1} {")
    o.append("    set pairs [list \"%s${g}_reg\" \"%s${i}\"]" % (ref_pre, impl_pre))
    o.append("  } else {")
    o.append("    set pairs {}")
    o.append("    for {set b 0} {$b < $w} {incr b} {")
    o.append("      lappend pairs \"%s${g}_reg\\[$b\\]\" \"%s${i}\\[$b\\]\"" % (ref_pre, impl_pre))
    o.append("    }")
    o.append("  }")
    o.append("  foreach {r m} $pairs {")
    o.append("    if {[set_user_match $r $m]} { incr ::%s_PIN_OK } else {" % tag)
    o.append("      incr ::%s_PIN_BAD" % tag)
    o.append("      if {$::%s_PIN_BAD <= 10} { puts \"%s_PIN_FAIL: $r <-> $m\" }" % (tag, tag))
    o.append("    }")
    o.append("  }")
    o.append("}")
    o.append("puts \"%s_PIN_BEGIN %s expect=$::%s_PIN_EXPECT\"" % (tag, design, tag))
    for n, w in regs:
        hits = rule(n)
        if len(hits) != 1:
            raise SystemExit("gen_mmuleaf: %s 的钉点规则对 golden 寄存器 %s 命中 %d 条（必须恰好 1）"
                             % (top, n, len(hits)))
        base, idx = hits[0]
        key = base + idx
        if key in seen:
            raise SystemExit("gen_mmuleaf: %s 两个 golden 寄存器映射到同一个重写寄存器 %s（不是双射）" % (top, key))
        seen.add(key)
        o.append("%s_pin %s %s %d" % (tag.lower(), n, esc(base + "_reg" + idx), w))
    o.append("puts \"%s_PIN_END %s ok=$::%s_PIN_OK bad=$::%s_PIN_BAD\"" % (tag, design, tag, tag))
    o.append("if {$::%s_PIN_BAD != 0} { error \"%s_PIN_MISS=$::%s_PIN_BAD\" }" % (tag, tag, tag))
    o.append("if {$::%s_PIN_OK != %d} { error \"%s_PIN_COUNT=$::%s_PIN_OK expect=%d\" }"
             % (tag, total, tag, tag, total))
    return "\n".join(o) + "\n"


def targets():
    out = {}
    for top, (ut, rule, tag) in TARGETS.items():
        out[os.path.join(REPO, "verif", "ut", ut, "fm_pins_pre.tcl")] = gen_pins(top, rule, tag)
    path, text = gen_tlb_post_pins()
    out[path] = text
    # L2TLB 里的 pmp 实例：impl 侧改用 PMP 重写件后，两侧内部寄存器名字不同，整表逐位钉
    out[os.path.join(REPO, "verif", "ut", "L2TLB", "fm_pins_pre.tcl")] = gen_pins(
        "PMP", pmp_rule, "L2TLBPMP", design="L2TLB",
        ref_pre="r:/WORK/L2TLB/pmp/", impl_pre="i:/WORK/L2TLB/u_core/u_pmp/u_core/",
        note=["L2TLB 的 pmp 子模块：ref = golden PMP（实例名 pmp），impl = PMP 重写件（u_core/u_pmp/u_core 下）。",
              "规则与 verif/ut/PMP/fm_pins_pre.tcl 完全相同（同一个 pmp_rule），只换路径前缀。"])
    for g in RTL_GENERATORS:
        path, text = g()
        out[path] = text
    return out


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--check", action="store_true", help="只比对不写，有漂移 rc=1")
    args = ap.parse_args()
    drift = 0
    for path, text in targets().items():
        cur = open(path).read() if os.path.exists(path) else None
        if cur == text:
            print("gen_mmuleaf: OK     %s" % os.path.relpath(path, REPO))
            continue
        if args.check:
            print("gen_mmuleaf: DRIFT  %s" % os.path.relpath(path, REPO))
            drift += 1
        else:
            with open(path, "w") as f:
                f.write(text)
            print("gen_mmuleaf: WROTE  %s" % os.path.relpath(path, REPO))
    return 1 if drift else 0


if __name__ == "__main__":
    sys.exit(main())
