#!/usr/bin/env python3
"""gen_og2forvector.py —— Og2ForVector 的机械派生区生成器。

生成对象（都是"没有微架构"的纯机械部分；可读核 xs_Og2ForVector_core 是手写的，本脚本不碰）：
  rtl/backend/Og2ForVector.sv          两个 GENERATED 区：
    og2-params    package 里的通道表：NCH / 每通道 payload 宽度 PW / 起点 PO / IS_MEM / IMM_CH
    og2-wrapper   golden 同名 wrapper：端口表逐字取 golden，按字段表把每个通道的 bits 拼成 payload、
                  再从核的 out_payload 拆回 toExu / toMemIQOg2Resp 端口
  verif/ut/Og2ForVector/fm_pins_pre.tcl  FM「匹配前」钉点（golden 扁平寄存器 <-> 核里按通道的寄存器）
  verif/ut/Og2ForVector/tb.sv            UT（双例化 golden / 重写件，全端口随机 + 逐拍比全部输出）

payload 打包约定（与核的 og2forvector_pkg 手写常量一致，生成时机械核对）：
  [8:0] = {robIdx_flag, robIdx_value}，[43:9] = fuType，[50:44] = vpu_vuopIdx，其后为其余 bits 字段
  （按 golden 输入端口顺序）。

fail-closed 核对（任何一条不满足就报错退出，不写文件）：
  (1) 每个通道 fromOg1 的 bits 字段集合 == toExu 的 bits 字段集合，且位宽逐个相等；
  (2) 每个通道都有 robIdx_flag/robIdx_value(8)/fuType(35)/vpu_vuopIdx(7)；
  (3) golden 端口每一个都被恰好一条规则消费（通道 valid/bits/ready、Og2Resp、flush、ImmInfo、clock/reset）；
  (4) golden 顶层每个寄存器恰好映射到一个重写寄存器位（双射），总位数写成字面常量进钉点文件；
  (5) 生成结果与磁盘逐字节比较（--check）。

用法:
  scripts/gen_og2forvector.py            # 写文件
  scripts/gen_og2forvector.py --check    # 只比对，不写；有漂移 rc=1（gate 用）
"""
import argparse
import os
import re
import sys

GOLDEN_DIR = "/home/eda/xs-env/G1-canonical/golden-rtl"
HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.normpath(os.path.join(HERE, ".."))
RTL = os.path.join(REPO, "rtl", "backend", "Og2ForVector.sv")
PINS = os.path.join(REPO, "verif", "ut", "Og2ForVector", "fm_pins_pre.tcl")
TB = os.path.join(REPO, "verif", "ut", "Og2ForVector", "tb.sv")
TOP = "Og2ForVector"

# 通道表：(核里通道号 k 的顺序) = Scala fromOg1VfArith ++ fromOg1VecMem 展平后的顺序
CHANNELS = [
    # (from 前缀, to 前缀, resp 前缀, golden 寄存器里的 IQ 号, 口号, 是否访存)
    ("io_fromOg1VfArith_0_0", "io_toVfArithExu_0_0", "io_toVfIQOg2Resp_0_0", 0, 0, False),
    ("io_fromOg1VfArith_0_1", "io_toVfArithExu_0_1", "io_toVfIQOg2Resp_0_1", 0, 1, False),
    ("io_fromOg1VfArith_1_0", "io_toVfArithExu_1_0", "io_toVfIQOg2Resp_1_0", 1, 0, False),
    ("io_fromOg1VfArith_1_1", "io_toVfArithExu_1_1", "io_toVfIQOg2Resp_1_1", 1, 1, False),
    ("io_fromOg1VfArith_2_0", "io_toVfArithExu_2_0", "io_toVfIQOg2Resp_2_0", 2, 0, False),
    ("io_fromOg1VecMem_0_0",  "io_toVecMemExu_0_0",  "io_toMemIQOg2Resp_0_0", 3, 0, True),
    ("io_fromOg1VecMem_1_0",  "io_toVecMemExu_1_0",  "io_toMemIQOg2Resp_1_0", 4, 0, True),
]
IMM_CH = 1          # golden 只剩 io_fromOg1ImmInfo_1 / io_toBypassNetworkImmInfo_1
HEAD_FIELDS = [("robIdx_value", 8), ("robIdx_flag", 1), ("fuType", 35), ("vpu_vuopIdx", 7)]
HEAD_W = sum(w for _, w in HEAD_FIELDS)   # 51


def die(msg):
    raise SystemExit("gen_og2forvector: " + msg)


def port_table(module):
    """golden 顶层端口表：[(dir, width, name, 原文行)]，顺序即 golden 顺序。"""
    lines = open(os.path.join(GOLDEN_DIR, module + ".sv")).read().split("\n")
    start = next(i for i, l in enumerate(lines) if l.startswith("module %s(" % module))
    end = start
    while not lines[end].startswith(");"):
        end += 1
    out = []
    pat = re.compile(r"\s*(input|output)\s+(?:\[(\d+):(\d+)\]\s*)?([A-Za-z_]\w*)\s*,?\s*$")
    for l in lines[start + 1:end]:
        m = pat.match(l)
        if not m:
            die("端口行解析失败: %r" % l)
        w = int(m.group(2)) - int(m.group(3)) + 1 if m.group(2) else 1
        out.append((m.group(1), w, m.group(4), l.rstrip(",").rstrip()))
    return out


def golden_top_regs(module):
    t = open(os.path.join(GOLDEN_DIR, module + ".sv")).read()
    body = t[t.index("module %s(" % module):]
    body = body[:body.index("\nendmodule")]
    body = re.sub(r"reg\s+(\[\d+:\d+\])\s*\n\s*", r"reg \1 ", body)
    out = []
    for a, b, n in re.findall(r"^\s*reg\s+(?:\[(\d+):(\d+)\]\s+)?(\w+);", body, re.M):
        out.append((n, int(a) - int(b) + 1 if a else 1))
    return out


def analyze():
    ports = port_table(TOP)
    pmap = {n: (d, w) for d, w, n, _ in ports}
    used = set()

    def take(name, d, w=None):
        if name not in pmap:
            die("缺端口 %s" % name)
        pd, pw = pmap[name]
        if pd != d or (w is not None and pw != w):
            die("端口 %s 方向/位宽不符：%s %d" % (name, pd, pw))
        if name in used:
            die("端口 %s 被两条规则消费" % name)
        used.add(name)
        return pw

    for n, d, w in (("clock", "input", 1), ("reset", "input", 1), ("io_flush_valid", "input", 1),
                    ("io_flush_bits_robIdx_flag", "input", 1), ("io_flush_bits_robIdx_value", "input", 8),
                    ("io_flush_bits_level", "input", 1),
                    ("io_fromOg1ImmInfo_%d_imm" % IMM_CH, "input", 32),
                    ("io_fromOg1ImmInfo_%d_immType" % IMM_CH, "input", 4),
                    ("io_toBypassNetworkImmInfo_%d_imm" % IMM_CH, "output", 32),
                    ("io_toBypassNetworkImmInfo_%d_immType" % IMM_CH, "output", 4)):
        take(n, d, w)

    chans = []
    for frm, to, rsp, gi, gj, is_mem in CHANNELS:
        take(frm + "_valid", "input", 1)
        take(to + "_valid", "output", 1)
        take(to + "_ready", "input", 1)
        take(rsp + "_valid", "output", 1)
        take(rsp + "_bits_resp", "output", 2)
        in_fields = [(n[len(frm) + 6:], w) for d, w, n, _ in ports
                     if d == "input" and n.startswith(frm + "_bits_")]
        out_fields = {n[len(to) + 6:]: w for d, w, n, _ in ports
                      if d == "output" and n.startswith(to + "_bits_")}
        if {f for f, _ in in_fields} != set(out_fields):
            die("通道 %s：fromOg1 与 toExu 的字段集合不同" % frm)
        for f, w in in_fields:
            if out_fields[f] != w:
                die("通道 %s 字段 %s 位宽不同" % (frm, f))
            take(frm + "_bits_" + f, "input", w)
            take(to + "_bits_" + f, "output", w)
        fdict = dict(in_fields)
        for f, w in HEAD_FIELDS:
            if fdict.get(f) != w:
                die("通道 %s 缺头部字段 %s(%d)" % (frm, f, w))
        layout = []                      # [(field, lsb, width)]
        pos = 0
        for f, w in HEAD_FIELDS:
            layout.append((f, pos, w)); pos += w
        for f, w in in_fields:
            if f in dict(HEAD_FIELDS):
                continue
            layout.append((f, pos, w)); pos += w
        if is_mem:
            take(rsp + "_bits_robIdx_flag", "output", 1)
            take(rsp + "_bits_robIdx_value", "output", 8)
            take(rsp + "_bits_fuType", "output", 35)
            take(rsp + "_bits_uopIdx", "output", 7)
        chans.append(dict(frm=frm, to=to, rsp=rsp, gi=gi, gj=gj, is_mem=is_mem, layout=layout, pw=pos))
    left = [n for _, _, n, _ in ports if n not in used]
    if left:
        die("有 %d 个 golden 端口没有规则消费：%s" % (len(left), left[:5]))
    po = 0
    for c in chans:
        c["po"] = po
        po += c["pw"]
    return ports, chans, po


def replace_region(text, tag, body):
    begin = "// BEGIN GENERATED(%s)" % tag
    end = "// END GENERATED"
    i = text.index(begin)
    j = text.index(end, i)
    line_start = text.rfind("\n", 0, i) + 1
    indent = text[line_start:i]
    return text[:i] + begin + "\n" + body + ("\n" if body else "") + indent + end + text[j + len(end):]


def gen_params(chans, total):
    o = []
    o.append("  // 通道 k 的顺序 = Scala fromOg1VfArith ++ fromOg1VecMem 展平：")
    for k, c in enumerate(chans):
        o.append("  //   %d: %-22s -> %-20s payload %4d 位%s" % (
            k, c["frm"][3:], c["to"][3:], c["pw"], "（访存）" if c["is_mem"] else ""))
    o.append("  localparam int NCH      = %d;" % len(chans))
    o.append("  localparam int PW [NCH] = '{%s};" % ", ".join(str(c["pw"]) for c in chans))
    o.append("  localparam int PO [NCH] = '{%s};" % ", ".join(str(c["po"]) for c in chans))
    o.append("  localparam int PW_TOTAL = %d;" % total)
    o.append("  localparam bit IS_MEM [NCH] = '{%s};" % ", ".join("1'b1" if c["is_mem"] else "1'b0" for c in chans))
    o.append("  localparam int IMM_CH   = %d;" % IMM_CH)
    return "\n".join(o)


def gen_wrapper(ports, chans):
    o = []
    o.append("module %s (" % TOP)
    for idx, (_, _, _, line) in enumerate(ports):
        o.append(line + ("," if idx + 1 < len(ports) else ""))
    o.append(");")
    o.append("  import og2forvector_pkg::*;")
    o.append("")
    o.append("  logic [NCH-1:0]      in_valid, exu_ready, out_valid;")
    o.append("  logic [PW_TOTAL-1:0] in_payload, out_payload;")
    o.append("  logic [NCH-1:0][1:0] resp;")
    o.append("")
    o.append("  xs_Og2ForVector_core u_core (")
    o.append("    .clock         (clock),")
    o.append("    .reset         (reset),")
    o.append("    .flush_valid   (io_flush_valid),")
    o.append("    .flush_rob_idx ({io_flush_bits_robIdx_flag, io_flush_bits_robIdx_value}),")
    o.append("    .flush_level   (io_flush_bits_level),")
    o.append("    .in_valid      (in_valid),")
    o.append("    .in_payload    (in_payload),")
    o.append("    .exu_ready     (exu_ready),")
    o.append("    .out_valid     (out_valid),")
    o.append("    .out_payload   (out_payload),")
    o.append("    .resp          (resp),")
    o.append("    .imm_in        (io_fromOg1ImmInfo_%d_imm)," % IMM_CH)
    o.append("    .imm_type_in   (io_fromOg1ImmInfo_%d_immType)," % IMM_CH)
    o.append("    .imm_out       (io_toBypassNetworkImmInfo_%d_imm)," % IMM_CH)
    o.append("    .imm_type_out  (io_toBypassNetworkImmInfo_%d_immType)" % IMM_CH)
    o.append("  );")
    for k, c in enumerate(chans):
        o.append("")
        o.append("  // ---- 通道 %d：%s -> %s ----" % (k, c["frm"][3:], c["to"][3:]))
        o.append("  assign in_valid[%d]  = %s_valid;" % (k, c["frm"]))
        o.append("  assign exu_ready[%d] = %s_ready;" % (k, c["to"]))
        o.append("  assign %s_valid = out_valid[%d];" % (c["to"], k))
        for f, lsb, w in c["layout"]:
            sl = "[%d +: %d]" % (c["po"] + lsb, w) if w > 1 else "[%d]" % (c["po"] + lsb)
            o.append("  assign in_payload%s = %s_bits_%s;" % (sl, c["frm"], f))
        for f, lsb, w in c["layout"]:
            sl = "[%d +: %d]" % (c["po"] + lsb, w) if w > 1 else "[%d]" % (c["po"] + lsb)
            o.append("  assign %s_bits_%s = out_payload%s;" % (c["to"], f, sl))
        o.append("  assign %s_valid = out_valid[%d];" % (c["rsp"], k))
        o.append("  assign %s_bits_resp = resp[%d];" % (c["rsp"], k))
        if c["is_mem"]:
            lay = {f: (lsb, w) for f, lsb, w in c["layout"]}
            for rf, pf in (("robIdx_flag", "robIdx_flag"), ("robIdx_value", "robIdx_value"),
                           ("fuType", "fuType"), ("uopIdx", "vpu_vuopIdx")):
                lsb, w = lay[pf]
                sl = "[%d +: %d]" % (c["po"] + lsb, w) if w > 1 else "[%d]" % (c["po"] + lsb)
                o.append("  assign %s_bits_%s = out_payload%s;" % (c["rsp"], rf, sl))
    o.append("endmodule")
    return "\n".join(o)


def gen_rtl(ports, chans, total):
    text = open(RTL).read()
    text = replace_region(text, "og2-params", gen_params(chans, total))
    text = replace_region(text, "og2-wrapper", gen_wrapper(ports, chans))
    return text


# ---------------------------------------------------------------------------
#  FM「匹配前」钉点
def pin_targets(chans):
    """golden 寄存器名 -> [(golden 位路径, impl 位路径)]（w==1 时无位下标）"""
    by_g = {(c["gi"], c["gj"]): (k, c) for k, c in enumerate(chans)}
    flush_suffix = {0: ""}
    flush_suffix.update({k: "_%d" % k for k in range(1, len(chans))})
    flush_of = {v: k for k, v in flush_suffix.items()}
    out = {}
    for n, w in golden_top_regs(TOP):
        m = re.match(r"s2_toExuValid_(\d)_(\d)$", n)
        if m:
            k, _ = by_g[(int(m.group(1)), int(m.group(2)))]
            out[n] = (w, "g_ch\\[%d\\].valid_q_reg" % k, None)
            continue
        m = re.match(r"s2_toExuData_(\d)_(\d)_(\w+)$", n)
        if m:
            k, c = by_g[(int(m.group(1)), int(m.group(2)))]
            lay = {f: (lsb, fw) for f, lsb, fw in c["layout"]}
            if m.group(3) not in lay or lay[m.group(3)][1] != w:
                die("寄存器 %s 在通道 %d 的字段表里找不到（或位宽不同）" % (n, k))
            out[n] = (w, "g_ch\\[%d\\].payload_q_reg" % k, lay[m.group(3)][0])
            continue
        m = re.match(r"s2_flush_next_valid_last_REG(_\d)?$", n)
        if m:
            k = flush_of[m.group(1) or ""]
            out[n] = (w, "g_ch\\[%d\\].flush_d_valid_q_reg" % k, None)
            continue
        m = re.match(r"s2_flush_next_bits_r(_\d)?_(robIdx_flag|robIdx_value|level)$", n)
        if m:
            k = flush_of[m.group(1) or ""]
            if m.group(2) == "level":
                out[n] = (w, "g_ch\\[%d\\].flush_d_level_q_reg" % k, None)
            else:
                out[n] = (w, "g_ch\\[%d\\].flush_d_rob_q_reg" % k, 8 if m.group(2) == "robIdx_flag" else 0)
            continue
        m = re.match(r"r_%d_(imm|immType)$" % IMM_CH, n)
        if m:
            out[n] = (w, "imm_q_reg" if m.group(1) == "imm" else "imm_type_q_reg", 0)
            continue
        die("golden 寄存器 %s 没有映射规则" % n)
    pairs = []
    seen = set()
    for n, (w, ipath, lsb) in out.items():
        for b in range(w):
            g = "r:/WORK/%s/%s_reg" % (TOP, n) + ("\\[%d\\]" % b if w > 1 else "")
            if lsb is None:
                if w != 1:
                    die("寄存器 %s 映射到单比特目标但宽 %d" % (n, w))
                i = "i:/WORK/%s/u_core/%s" % (TOP, ipath)
            else:
                i = "i:/WORK/%s/u_core/%s\\[%d\\]" % (TOP, ipath, lsb + b)
            if i in seen:
                die("两个 golden 寄存器位映射到同一个重写寄存器位 %s（不是双射）" % i)
            seen.add(i)
            pairs.append((g, i))
    return pairs


def gen_pins(chans):
    pairs = pin_targets(chans)
    total = len(pairs)
    o = []
    o.append("# Og2ForVector FM「匹配前」钉点 —— 自动生成：scripts/gen_og2forvector.py（勿手改）")
    o.append("#")
    o.append("# 只消 golden 扁平寄存器名（s2_toExuData_<iq>_<口>_<字段>）与重写核按通道打包的")
    o.append("# payload_q / flush_d_* 之间的命名鸿沟。set_user_match 只声明两点对应，比较照比：")
    o.append("# 不约束 ref、不改 appvar、不加黑盒。fail-closed：逐条数返回值，拒一条或总数不等于")
    o.append("# 字面整数（= golden 顶层寄存器位数）就 error。进 fm.log 的输出一律 ASCII。")
    o.append("set ::OG2_PIN_OK 0")
    o.append("set ::OG2_PIN_BAD 0")
    o.append("proc og2_pin {r i} {")
    o.append("  if {[set_user_match $r $i]} { incr ::OG2_PIN_OK } else {")
    o.append("    incr ::OG2_PIN_BAD")
    o.append("    if {$::OG2_PIN_BAD <= 10} { puts \"OG2_PIN_FAIL: $r <-> $i\" }")
    o.append("  }")
    o.append("}")
    o.append("puts \"OG2_PIN_BEGIN %s expect=%d\"" % (TOP, total))
    for g, i in pairs:
        o.append("og2_pin %s %s" % (g, i))
    o.append("puts \"OG2_PIN_END %s ok=$::OG2_PIN_OK bad=$::OG2_PIN_BAD\"" % TOP)
    o.append("if {$::OG2_PIN_BAD != 0} { error \"OG2_PIN_MISS=$::OG2_PIN_BAD\" }")
    o.append("if {$::OG2_PIN_OK != %d} { error \"OG2_PIN_COUNT=$::OG2_PIN_OK expect=%d\" }" % (total, total))
    return "\n".join(o) + "\n"


# ---------------------------------------------------------------------------
#  UT tb
def gen_tb(ports, chans):
    ins = [(w, n) for d, w, n, _ in ports if d == "input" and n not in ("clock", "reset")]
    outs = [(w, n) for d, w, n, _ in ports if d == "output"]
    o = []
    o.append("// =============================================================================")
    o.append("// tb —— Og2ForVector UT（自动生成：scripts/gen_og2forvector.py，勿手改）")
    o.append("// golden Og2ForVector 与重写件 Og2ForVector_xs 双例化，同激励逐拍比全部 %d 个输出端口。" % len(outs))
    o.append("//")
    o.append("// 激励：除 clock/reset 外每个输入每拍随机；但为了让冲刷判定真的被打到：")
    o.append("//   · 各通道 OG1 valid 约 70%；io_flush_valid 约 30%，level 随机；")
    o.append("//   · robIdx：flush 与各通道 uop 的 robIdx 都从一个 4 值的小池子里取 value（+随机 flag），")
    o.append("//     让 \"正是那条\"（flushItself）与 isAfter 两种冲刷、以及 flag 翻转都大量出现；")
    o.append("//   · EXU ready 约 70%（og2Resp 的 block 分支）。")
    o.append("// 不复位寄存器：开头 4 拍复位，再跑 2 拍（s2 寄存器全被重写过）后开始比较。")
    o.append("// 覆盖（写进 PASS 判据）：每个通道 {进 OG2, 被本拍 redirect 冲掉, 被上拍 redirect 冲掉,")
    o.append("//   flushItself 命中, OG2 有效且 EXU 不 ready(block)} 各 >= 1000 次。")
    o.append("// =============================================================================")
    o.append("`timescale 1ns/1ps")
    o.append("module tb;")
    o.append("  int unsigned NCYCLES = 200000;")
    o.append("  longint errors = 0, checks = 0;")
    o.append("  logic clock = 0, reset = 1;")
    for w, n in ins:
        o.append("  logic [%d:0] %s;" % (w - 1, n))
    for w, n in outs:
        o.append("  logic [%d:0] g_%s, i_%s;" % (w - 1, n, n))
    for inst, pre in (("%s" % TOP, "g_"), ("%s_xs" % TOP, "i_")):
        o.append("  %s u_%s (" % (inst, pre[0]))
        conns = [".clock(clock)", ".reset(reset)"] + [".%s(%s)" % (n, n) for _, n in ins] + \
                [".%s(%s%s)" % (n, pre, n) for _, n in outs]
        for idx, cn in enumerate(conns):
            o.append("    %s%s" % (cn, "," if idx + 1 < len(conns) else ""))
        o.append("  );")
    nch = len(chans)
    o.append("  localparam int NCH = %d;" % nch)
    o.append("  int cov_enter [NCH], cov_kill_now [NCH], cov_kill_prev [NCH], cov_itself [NCH], cov_block [NCH];")
    o.append("  logic [7:0] pool [4];")
    o.append("  logic       fv_q; logic [8:0] frob_q; logic flvl_q;")
    o.append("")
    o.append("  function automatic logic nf(logic v, logic [8:0] r, logic l, logic [8:0] x);")
    o.append("    return v & ((l & (x == r)) | ((x[8] ^ r[8]) ^ (x[7:0] > r[7:0])));")
    o.append("  endfunction")
    o.append("")
    o.append("  task automatic drive();")
    for w, n in ins:
        if w <= 32:
            o.append("    %s = %d'($urandom);" % (n, w))
        else:
            o.append("    %s = {%s};" % (n, ", ".join(["$urandom"] * ((w + 31) // 32))) + "  // 截低 %d 位" % w)
    o.append("    io_flush_valid = ($urandom_range(0, 9) < 3);")
    o.append("    io_flush_bits_robIdx_value = pool[$urandom_range(0, 3)];")
    for c in chans:
        o.append("    %s_valid = ($urandom_range(0, 9) < 7);" % c["frm"])
        o.append("    %s_bits_robIdx_value = pool[$urandom_range(0, 3)];" % c["frm"])
        o.append("    %s_ready = ($urandom_range(0, 9) < 7);" % c["to"])
    o.append("  endtask")
    o.append("")
    o.append("  initial begin")
    o.append("    if (!$value$plusargs(\"ncycles=%d\", NCYCLES)) NCYCLES = 200000;")
    o.append("    foreach (cov_enter[k]) begin cov_enter[k] = 0; cov_kill_now[k] = 0; cov_kill_prev[k] = 0; cov_itself[k] = 0; cov_block[k] = 0; end")
    o.append("    foreach (pool[p]) pool[p] = $urandom;")
    o.append("    fv_q = 0; frob_q = 0; flvl_q = 0;")
    o.append("    drive();")
    o.append("    repeat (4) begin #5 clock = 1; #5 clock = 0; end")
    o.append("    reset = 0;")
    o.append("    for (int c = 0; c < NCYCLES; c++) begin")
    o.append("      if (c % 1024 == 0) foreach (pool[p]) pool[p] = $urandom;")
    o.append("      drive();")
    o.append("      #1;")
    o.append("      // 覆盖统计（用 tb 自己的参考模型判冲刷，不读 DUT 内部）")
    o.append("      begin")
    o.append("        logic [8:0] fr; logic [8:0] x;")
    o.append("        fr = {io_flush_bits_robIdx_flag, io_flush_bits_robIdx_value};")
    for k, c in enumerate(chans):
        f = c["frm"]
        o.append("        x = {%s_bits_robIdx_flag, %s_bits_robIdx_value};" % (f, f))
        o.append("        if (%s_valid) begin" % f)
        o.append("          if (nf(io_flush_valid, fr, io_flush_bits_level, x)) cov_kill_now[%d]++;" % k)
        o.append("          else if (nf(fv_q, frob_q, flvl_q, x)) cov_kill_prev[%d]++;" % k)
        o.append("          else cov_enter[%d]++;" % k)
        o.append("          if (io_flush_valid & io_flush_bits_level & (x == fr)) cov_itself[%d]++;" % k)
        o.append("        end")
        o.append("        if (g_%s_valid & ~%s_ready) cov_block[%d]++;" % (c["to"], c["to"], k))
    o.append("      end")
    o.append("      if (io_flush_valid) begin frob_q = {io_flush_bits_robIdx_flag, io_flush_bits_robIdx_value}; flvl_q = io_flush_bits_level; end")
    o.append("      fv_q = io_flush_valid;")
    o.append("      #4 clock = 1;")
    o.append("      #4;")
    o.append("      if (c >= 2) begin")
    for w, n in outs:
        o.append("        checks++; if (g_%s !== i_%s) begin errors++; if (errors <= 40) $display(\"[%%0d] MISMATCH %s golden=%%h impl=%%h\", c, g_%s, i_%s); end" % (n, n, n, n, n))
    o.append("      end")
    o.append("      #1 clock = 0;")
    o.append("    end")
    o.append("    begin")
    o.append("      int bad = 0;")
    o.append("      for (int k = 0; k < NCH; k++) begin")
    o.append("        $display(\"--- coverage ch%0d: enter=%0d kill_now=%0d kill_prev=%0d flushItself=%0d block=%0d\",")
    o.append("                 k, cov_enter[k], cov_kill_now[k], cov_kill_prev[k], cov_itself[k], cov_block[k]);")
    o.append("        if (cov_enter[k] < 1000 || cov_kill_now[k] < 1000 || cov_kill_prev[k] < 1000 ||")
    o.append("            cov_itself[k] < 1000 || cov_block[k] < 1000) bad++;")
    o.append("      end")
    o.append("      $display(\"checks=%0d errors=%0d bad_cov=%0d\", checks, errors, bad);")
    o.append("      if (errors == 0 && checks > 1000 && bad == 0) $display(\"TEST PASSED\");")
    o.append("      else $display(\"TEST FAILED\");")
    o.append("    end")
    o.append("    $finish;")
    o.append("  end")
    o.append("endmodule")
    return "\n".join(o) + "\n"


def targets():
    ports, chans, total = analyze()
    return {RTL: gen_rtl(ports, chans, total), PINS: gen_pins(chans), TB: gen_tb(ports, chans)}


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--check", action="store_true", help="只比对不写，有漂移 rc=1")
    args = ap.parse_args()
    drift = 0
    for path, text in targets().items():
        cur = open(path).read() if os.path.exists(path) else None
        if cur == text:
            print("gen_og2forvector: OK     %s" % os.path.relpath(path, REPO))
            continue
        if args.check:
            print("gen_og2forvector: DRIFT  %s" % os.path.relpath(path, REPO))
            drift += 1
        else:
            os.makedirs(os.path.dirname(path), exist_ok=True)
            with open(path, "w") as f:
                f.write(text)
            print("gen_og2forvector: WROTE  %s" % os.path.relpath(path, REPO))
    return 1 if drift else 0


if __name__ == "__main__":
    sys.exit(main())
