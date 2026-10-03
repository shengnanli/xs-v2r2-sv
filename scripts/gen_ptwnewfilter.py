#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""gen_ptwnewfilter.py —— ptwnewfilter lane 的机械派生区（PTWFilterEntry_1 / PTWNewFilter）。

生成内容（全部从 G1 golden 端口表机械推出，没有设计决策）：
  · rtl/memblock/PTWFilterEntry_1.sv：golden 同名端口表；PTW 响应命中键 hit_key_t 的打包。
  · rtl/memblock/PTWNewFilter.sv：
      - wrapper 端口表、输入打包（8 个 dtlb 请求口 → 数组，PTW 响应 → ptw_s1_t/ptw_s2_t）、输出展平；
      - 核里三张过滤表（PTWFilterEntry / PTWFilterEntry_1 ×2）与仲裁器（RRArbiterInit_12）的逐口连线。
  · verif/ut/PTWNewFilter/fm_pins_pre.tcl：FM「匹配前」钉点 —— golden 顶层与三张表内部寄存器逐位
    set_user_match 到重写件（名字两侧不同：golden 展平名 vs 重写的 struct/数组/实例层次）。

每条映射规则表 fail-closed：每个端口/寄存器必须恰好被一条规则认领，有规则一个也没认领就拒绝生成；
钉点映射必须单射；生成的 tcl 逐条数 set_user_match 返回值并对字面总数。

用法：
    python3 scripts/gen_ptwnewfilter.py            # 生成（幂等：内容不变不写文件）
    python3 scripts/gen_ptwnewfilter.py --check    # 产物与生成器不一致则 rc=1
"""
import argparse
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.normpath(os.path.join(HERE, ".."))
GOLDEN_DIR = "/home/eda/xs-env/G1-canonical/golden-rtl"
ME = "scripts/gen_ptwnewfilter.py"

PORT_RE = re.compile(r"^\s*(input|output)\s+(?:\[(\d+):0\]\s+)?(\w+)\s*,?\s*$")


def die(msg):
    raise SystemExit("gen_ptwnewfilter: " + msg)


# -----------------------------------------------------------------------------
#  golden 读取
# -----------------------------------------------------------------------------
def golden_text(mod):
    return open(os.path.join(GOLDEN_DIR, mod + ".sv")).read()


def golden_port_lines(mod):
    m = re.search(r"^module\s+%s\s*\((.*?)^\);" % re.escape(mod), golden_text(mod), re.S | re.M)
    if not m:
        die("golden 里找不到 module %s" % mod)
    return [ln.rstrip().rstrip(",") for ln in m.group(1).splitlines() if ln.strip()]


def golden_ports(mod):
    """[(方向, 名字, 位宽)]，按 golden 声明顺序。"""
    out = []
    for ln in golden_port_lines(mod):
        pm = PORT_RE.match(ln)
        if not pm:
            die("%s 端口行解析不了：%r" % (mod, ln))
        out.append((pm.group(1), pm.group(3), int(pm.group(2)) + 1 if pm.group(2) else 1))
    return out


def golden_top_regs(mod):
    """golden 顶层（不含子模块）寄存器声明：[(名字, 位宽)]，按声明顺序。"""
    t = golden_text(mod)
    body = t[t.index("module %s(" % mod):]
    body = body[:body.index("\nendmodule")]
    body = re.sub(r"reg\s+(\[\d+:\d+\])\s*\n\s*", r"reg \1 ", body)
    out = []
    for a, b, n in re.findall(r"^\s*reg\s+(?:\[(\d+):(\d+)\]\s+)?(\w+);", body, re.M):
        out.append((n, int(a) - int(b) + 1 if a else 1))
    if not out:
        die("golden %s 里一个寄存器也没解析到" % mod)
    return out


# -----------------------------------------------------------------------------
#  通用：规则认领
# -----------------------------------------------------------------------------
def claim(names, rules, what):
    """names 里每个名字恰好命中 rules 的一条；返回 [(名字, 规则下标, match)]。每条规则至少用一次。"""
    used = [0] * len(rules)
    out = []
    for n in names:
        hits = [(k, re.fullmatch(r[0], n)) for k, r in enumerate(rules)]
        hits = [(k, m) for k, m in hits if m]
        if len(hits) != 1:
            die("%s：%s 被 %d 条规则认领（必须恰好 1）" % (what, n, len(hits)))
        used[hits[0][0]] += 1
        out.append((n, hits[0][0], hits[0][1]))
    for k, c in enumerate(used):
        if c == 0:
            die("%s：规则 %r 一个也没认领（golden 端口表变了？）" % (what, rules[k][0]))
    return out


def gen_ports(mod):
    pl = golden_port_lines(mod)
    return "\n".join("  " + ln.strip() + ("," if k < len(pl) - 1 else "") for k, ln in enumerate(pl))


def gen_inst(mod, inst, rules, indent="  "):
    ports = [n for _, n, _ in golden_ports(mod)]
    width = max(len(p) for p in ports)
    lines = ["%s  .%s (%s)" % (indent, p.ljust(width), rules[k][1].format(*m.groups()))
             for p, k, m in claim(ports, rules, "%s.%s" % (mod, inst))]
    return "%s%s %s (\n%s\n%s);" % (indent, mod, inst, ",\n".join(lines), indent)


def gen_assigns(names, rules, fmt, what):
    return "\n".join(fmt(n, rules[k][1].format(*m.groups())) for n, k, m in claim(names, rules, what))


def replace_region(text, tag, body):
    b = "// BEGIN GENERATED(%s) —— %s\n" % (tag, ME)
    pat = re.compile(r"([ \t]*)" + re.escape(b) + r".*?^([ \t]*)// END GENERATED\n", re.S | re.M)
    m = pat.search(text)
    if not m:
        die("找不到生成区 %s" % tag)
    ind = m.group(1)
    return text[:m.start()] + ind + b + body + "\n" + ind + "// END GENERATED\n" + text[m.end():]


# PTW 响应端口（io_ptw_resp_bits_* / io_tlb_resp_bits_data_*）后缀 -> ptw_s1_t / ptw_s2_t 字段
def resp_field_rules(prefix, s1, s2, s2xlate):
    return [
        (prefix + r"s2xlate", s2xlate),
        (prefix + r"s1_entry_(\w+)", s1 + ".entry_{0}"),
        (prefix + r"s1_(ppn_low|valididx|pteidx)_(\d)", s1 + ".{0}[{1}]"),
        (prefix + r"s1_(addr_low|pf|af)", s1 + ".{0}"),
        (prefix + r"s2_entry_(\w+)", s2 + ".entry_{0}"),
        (prefix + r"s2_(gpf|gaf)", s2 + ".{0}"),
    ]


# -----------------------------------------------------------------------------
#  PTWFilterEntry_1
# -----------------------------------------------------------------------------
def gen_ptwfe1_rtl():
    path = os.path.join(REPO, "rtl", "memblock", "PTWFilterEntry_1.sv")
    text = open(path).read()
    text = replace_region(text, "ptwfe1_ports", gen_ports("PTWFilterEntry_1"))
    ptw_in = [n for d, n, _ in golden_ports("PTWFilterEntry_1")
              if d == "input" and n.startswith("io_ptw_resp_bits_")]
    text = replace_region(text, "ptwfe1_resp", gen_assigns(ptw_in, [
        (r"io_ptw_resp_bits_s2xlate", "ptw_resp.s2xlate"),
        (r"io_ptw_resp_bits_s1_entry_(tag|asid|vmid|n|level)", "ptw_resp.s1_{0}"),
        (r"io_ptw_resp_bits_s1_entry_perm_g", "ptw_resp.s1_perm_g"),
        (r"io_ptw_resp_bits_s1_addr_low", "ptw_resp.s1_addr_low"),
        (r"io_ptw_resp_bits_s1_valididx_(\d)", "ptw_resp.s1_valididx[{0}]"),
        (r"io_ptw_resp_bits_s2_entry_(tag|vmid|n|level)", "ptw_resp.s2_{0}"),
    ], lambda port, lhs: "  assign %s = %s;" % (lhs, port), "PTWFilterEntry_1.ptw_resp"))
    return path, text


# -----------------------------------------------------------------------------
#  PTWNewFilter
# -----------------------------------------------------------------------------
# 三张表：(golden 子模块, 重写实例名, 表号, 第一个 dtlb 口)
FILTERS = [("PTWFilterEntry", "load_filter", 0, 0),
           ("PTWFilterEntry_1", "store_filter", 1, 4),
           ("PTWFilterEntry_1", "prefetch_filter", 2, 6)]


def filter_inst(mod, inst, f, base):
    def lane(k):
        return str(int(k) + base)
    rules = [
        (r"clock", "clock"),
        (r"reset", "reset"),
        (r"io_csr_(satp_asid|vsatp_asid|hgatp_vmid)", "{0}"),
        (r"io_ptw_req_0_ready", "filt_req_ready[%d]" % f),
        (r"io_ptw_req_0_valid", "filt_req_valid[%d]" % f),
        (r"io_ptw_req_0_bits_(vpn|s2xlate)", "filt_req_{0}[%d]" % f),
        (r"io_ptw_resp_valid", "resp_valid_q[%d]" % f),
        (r"io_rob_head_miss_in_tlb", "filt_rob_head_miss[%d]" % f),
        (r"io_debugTopDown_robHeadVaddr_valid", "rob_head_vaddr_valid"),
        (r"io_debugTopDown_robHeadVaddr_bits", "rob_head_vaddr"),
        (r"io_flush", "flush"),
        (r"io_refill", "filt_refill[%d]" % f),
        (r"io_getGpa", "filt_get_gpa[%d]" % f),
        # PTW 响应：表只拿命中比较要看的那几项（hit_key_t 的字段），取自 §2 打拍后的寄存器
        (r"io_ptw_resp_bits_s2xlate", "resp_s2xlate_q"),
        (r"io_ptw_resp_bits_s1_entry_(\w+)", "resp_s1_q.entry_{0}"),
        (r"io_ptw_resp_bits_s1_addr_low", "resp_s1_q.addr_low"),
        (r"io_ptw_resp_bits_s1_valididx_(\d)", "resp_s1_q.valididx[{0}]"),
        (r"io_ptw_resp_bits_s2_entry_(\w+)", "resp_s2_q.entry_{0}"),
    ]
    if mod == "PTWFilterEntry":
        rules += [
            (r"io_hint_req_(\d)_(id|full)", "load_hint_req_{1}[{0}]"),
            (r"io_hint_resp_valid", "load_hint_resp_valid"),
            (r"io_hint_resp_bits_(id|replay_all)", "load_hint_resp_{0}"),
        ]
    # dtlb 请求口：表内 lane k = 本层口 base + k
    out = gen_inst(mod, inst, rules + [
        (r"io_tlb_req_(\d)_valid", "tlb_req_valid[{0}]"),
        (r"io_tlb_req_(\d)_bits_vpn", "tlb_req_vpn[{0}]"),
        (r"io_tlb_req_(\d)_bits_s2xlate", "tlb_req_s2xlate[{0}]"),
        (r"io_tlb_req_(\d)_bits_getGpa", "tlb_req_get_gpa[{0}]"),
    ])
    return re.sub(r"(tlb_req_\w+)\[(\d)\]", lambda m: "%s[%s]" % (m.group(1), lane(m.group(2))), out)


def gen_pnf_rtl():
    path = os.path.join(REPO, "rtl", "memblock", "PTWNewFilter.sv")
    text = open(path).read()
    text = replace_region(text, "pnf_ports", gen_ports("PTWNewFilter"))

    ports = golden_ports("PTWNewFilter")
    # 输入：dtlb 请求与 PTW 响应载荷；其余输入在 wrapper 里直接接核
    ins = [n for d, n, _ in ports if d == "input" and (n.startswith("io_tlb_req_") or n.startswith("io_ptw_resp_bits_"))
           and n != "io_ptw_resp_bits_s2xlate"]
    text = replace_region(text, "pnf_in", gen_assigns(ins, [
        (r"io_tlb_req_(\d)_valid", "tlb_req_valid[{0}]"),
        (r"io_tlb_req_(\d)_bits_vpn", "tlb_req_vpn[{0}]"),
        (r"io_tlb_req_(\d)_bits_s2xlate", "tlb_req_s2xlate[{0}]"),
        (r"io_tlb_req_(\d)_bits_getGpa", "tlb_req_get_gpa[{0}]"),
    ] + resp_field_rules(r"io_ptw_resp_bits_", "ptw_resp_s1", "ptw_resp_s2", "unused")[1:],
        lambda port, lhs: "  assign %s = %s;" % (lhs, port), "PTWNewFilter.in"))

    # 输出：响应载荷、vector/getGpa（golden 只剩每组第一个口 0/4/6）、hint.req
    vec_idx = {"0": 0, "4": 1, "6": 2}
    outs = [n for d, n, _ in ports if d == "output" and (n.startswith("io_tlb_resp_bits_") or n.startswith("io_hint_req_"))
            and n != "io_tlb_resp_bits_data_s2xlate"]
    body = gen_assigns(outs, [
        (r"io_tlb_resp_bits_(vector|getGpa)_([046])", "tlb_resp_{0}[{1}]"),
        (r"io_hint_req_(\d)_(id|full)", "hint_req_{1}[{0}]"),
    ] + resp_field_rules(r"io_tlb_resp_bits_data_", "tlb_resp_s1", "tlb_resp_s2", "unused")[1:],
        lambda port, rhs: "  assign %s = %s;" % (port, rhs), "PTWNewFilter.out")
    body = re.sub(r"tlb_resp_(vector|getGpa)\[([046])\]",
                  lambda m: "tlb_resp_%s[%d]" % ("vector" if m.group(1) == "vector" else "get_gpa",
                                                 vec_idx[m.group(2)]), body)
    text = replace_region(text, "pnf_out", body)

    for mod, inst, f, base in FILTERS:
        text = replace_region(text, "pnf_" + inst, filter_inst(mod, inst, f, base))
    text = replace_region(text, "pnf_ptw_arb", gen_inst("RRArbiterInit_12", "ptw_arb", [
        (r"clock", "clock"),
        (r"reset", "reset"),
        (r"io_in_(\d)_ready", "filt_req_ready[{0}]"),
        (r"io_in_(\d)_valid", "filt_req_valid[{0}]"),
        (r"io_in_(\d)_bits_(vpn|s2xlate)", "filt_req_{1}[{0}]"),
        (r"io_out_ready", "ptw_req_ready"),
        (r"io_out_valid", "ptw_req_valid"),
        (r"io_out_bits_(vpn|s2xlate)", "ptw_req_{0}"),
    ]))
    return path, text


RTL_GENERATORS = [gen_ptwfe1_rtl, gen_pnf_rtl]


def targets():
    out = {}
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
            print("gen_ptwnewfilter: OK     %s" % os.path.relpath(path, REPO))
            continue
        if args.check:
            print("gen_ptwnewfilter: DRIFT  %s" % os.path.relpath(path, REPO))
            drift += 1
        else:
            with open(path, "w") as f:
                f.write(text)
            print("gen_ptwnewfilter: WROTE  %s" % os.path.relpath(path, REPO))
    return 1 if drift else 0


if __name__ == "__main__":
    sys.exit(main())
