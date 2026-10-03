#!/usr/bin/env python3
"""gen_lqexcbuf.py —— LqExceptionBuffer 的机械派生区生成器。

生成对象（可读核 xs_LqExceptionBuffer_core 的 §1..§4 是手写的，本脚本不碰）：
  rtl/memblock/LqExceptionBuffer.sv 的两个 GENERATED 区：
    leb-types    package 里的入口 bundle 结构体 leb_req_t 及其两个子集
                 （leb_s2_t：s2 寄存器里各口都有的字段；leb_info_t：req 寄存器要记的字段）
                 + 三个按字段名投影/拼装的函数
    leb-wrapper  golden 同名 wrapper（100 个端口 <-> 核的结构体端口）
  verif/ut/LqExceptionBuffer/fm_pins_pre.tcl   FM 匹配前逐位钉点
  verif/ut/LqExceptionBuffer/tb.sv             双例化 UT

生成前的机械核对（任何一项不符即失败）：
  (1) 口 0 的字段表 = leb_req_t；口 p 的字段表 = leb_req_t 去掉核里 HAS_ISHYPER / HAS_VANEEDEXT
      标为"没有"的字段（与手写 package 的两个掩码逐位比对），顺序不变；
  (2) golden 寄存器表：s2_req_<p>_<f> 恰是口 p 的字段；req_<f> 恰是 leb_info_t；
      其余恰是 s2_valid_REG*、req_valid、REG；
  (3) 每个 golden 寄存器恰命中一条钉点规则，映射是单射；
  (4) --check：生成结果与磁盘逐字节比较。

用法:
  scripts/gen_lqexcbuf.py            # 写文件
  scripts/gen_lqexcbuf.py --check    # 只比对，不写；有漂移 rc=1
"""
import argparse
import os
import re
import sys

GOLDEN_DIR = "/home/eda/xs-env/G1-canonical/golden-rtl"
HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.normpath(os.path.join(HERE, ".."))
TOP = "LqExceptionBuffer"
SRC = os.path.join(REPO, "rtl", "memblock", TOP + ".sv")
UT = os.path.join(REPO, "verif", "ut", TOP)
NPORT = 6
OPTIONAL = ("isHyper", "vaNeedExt")   # 只在部分口存在的字段（核里另存）


def die(msg):
    raise SystemExit("gen_lqexcbuf: " + msg)


def golden_text():
    return open(os.path.join(GOLDEN_DIR, TOP + ".sv")).read()


def port_table():
    lines = golden_text().split("\n")
    start = next(i for i, l in enumerate(lines) if l.startswith("module %s(" % TOP))
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


def golden_regs():
    t = golden_text()
    s = t.index("module %s(" % TOP)
    e = t.index("endmodule", s)
    regs = re.findall(r"^\s*reg\s+(?:\[(\d+):(\d+)\]\s+)?(\w+);", t[s:e], re.M)
    return [(n, int(a) - int(b) + 1 if a else 1) for a, b, n in regs]


def pkg_mask(name):
    m = re.search(r"localparam logic \[ENQ_PORTS-1:0\] %s\s*=\s*6'b([01]{6});" % name, open(SRC).read())
    if not m:
        die("手写 package 里找不到 %s" % name)
    bits = m.group(1)
    return [bits[NPORT - 1 - p] == "1" for p in range(NPORT)]


def analyse():
    ports = port_table()
    full = [(n[len("io_req_0_bits_"):], w) for _, w, n, _ in ports if n.startswith("io_req_0_bits_")]
    has = {"isHyper": pkg_mask("HAS_ISHYPER"), "vaNeedExt": pkg_mask("HAS_VANEEDEXT")}
    for f in OPTIONAL:
        if f not in dict(full):
            die("口 0 没有字段 %s" % f)
        if not has[f][0]:
            die("口 0 必须有全部字段（leb_req_t 取自口 0）")
    per_port = []
    for p in range(NPORT):
        got = [(n[len("io_req_%d_bits_" % p):], w) for _, w, n, _ in ports if n.startswith("io_req_%d_bits_" % p)]
        exp = [(f, w) for f, w in full if f not in OPTIONAL or has[f][p]]
        if got != exp:
            die("口 %d 字段表与 HAS_* 掩码不符：golden=%s" % (p, [f for f, _ in got]))
        per_port.append([f for f, _ in got])
    s2 = [(f, w) for f, w in full if f not in OPTIONAL]
    info = [(f, w) for f, w in full if not f.startswith("uop_exceptionVec_")]
    # 寄存器表
    regs = golden_regs()
    want = []
    for p in range(NPORT):
        want += [("s2_req_%d_%s" % (p, f), dict(full)[f]) for f in per_port[p]]
    want += [("req_%s" % f, w) for f, w in info]
    for p in range(NPORT):
        want.append(("s2_valid_REG" if p == 0 else "s2_valid_REG_%d" % (2 * p), 1))
        for f, w in (("valid", 1), ("bits_robIdx_flag", 1), ("bits_robIdx_value", 8), ("bits_level", 1)):
            want.append(("s2_valid_REG_%d_%s" % (2 * p + 1, f), w))
    want += [("req_valid", 1), ("REG", 1)]
    if sorted(regs) != sorted(want):
        a, b = set(regs), set(want)
        die("golden 寄存器表与预期不符：多 %s 少 %s" % (sorted(a - b)[:6], sorted(b - a)[:6]))
    return ports, full, s2, info, has


def decl(w):
    return "logic" if w == 1 else "logic [%d:0]" % (w - 1)


def gen_types(full, s2, info):
    o = []
    for tname, fl, brief in (
            ("leb_req_t", full, "一个入口交来的 load（LqWriteBundle 在本模块被用到的字段；取自口 0 端口表）"),
            ("leb_s2_t", s2, "s2 寄存器里各口都有的部分（= leb_req_t 去掉 isHyper / vaNeedExt）"),
            ("leb_info_t", info, "req 寄存器要记住的部分（= leb_req_t 去掉异常位；取自 golden req_* 寄存器表）")):
        o.append("  // %s：%s，%d 字段 / %d 位" % (tname, brief, len(fl), sum(w for _, w in fl)))
        o.append("  typedef struct packed {")
        for n, w in fl:
            o.append("    %-13s %s;" % (decl(w), n))
        o.append("  } %s;" % tname)
        o.append("")
    o.append("  function automatic leb_s2_t to_s2(leb_req_t r);")
    o.append("    leb_s2_t s;")
    for n, _ in s2:
        o.append("    s.%s = r.%s;" % (n, n))
    o.append("    return s;")
    o.append("  endfunction")
    o.append("")
    o.append("  function automatic leb_req_t from_s2(leb_s2_t s, logic isHyper, logic vaNeedExt);")
    o.append("    leb_req_t r;")
    for n, _ in full:
        o.append("    r.%s = %s;" % (n, n if n in OPTIONAL else "s." + n))
    o.append("    return r;")
    o.append("  endfunction")
    o.append("")
    o.append("  function automatic leb_info_t to_info(leb_req_t r);")
    o.append("    leb_info_t i;")
    for n, _ in info:
        o.append("    i.%s = r.%s;" % (n, n))
    o.append("    return i;")
    o.append("  endfunction")
    return "\n".join(o) + "\n"


def gen_wrapper(ports, full, has):
    o = []
    o.append("// " + "=" * 77)
    o.append("// LqExceptionBuffer（golden 同名 wrapper）—— 端口表逐字取 golden，按口装成核的结构体数组。")
    o.append("// 某口没有的字段（HAS_* 为 0）核不读，这里按父级给的常数补上，只为不留悬空输入。")
    o.append("// 整段由 scripts/gen_lqexcbuf.py 生成，勿手改。")
    o.append("// " + "=" * 77)
    o.append("module %s" % TOP)
    o.append("  import lqexceptionbuffer_pkg::*;")
    o.append("(")
    for i, (_, _, _, raw) in enumerate(ports):
        o.append(raw + ("," if i + 1 < len(ports) else ""))
    o.append(");")
    o.append("  logic [ENQ_PORTS-1:0] req_valid;")
    o.append("  leb_req_t             req_bits [ENQ_PORTS];")
    o.append("")
    names = {n for _, _, n, _ in ports}
    for p in range(NPORT):
        o.append("  assign req_valid[%d] = io_req_%d_valid;" % (p, p))
        for f, _ in full:
            n = "io_req_%d_bits_%s" % (p, f)
            if n in names:
                o.append("  assign req_bits[%d].%s = %s;" % (p, f, n))
            else:
                const = "ISHYPER_CONST" if f == "isHyper" else "VANEEDEXT_CONST"
                o.append("  assign req_bits[%d].%s = %s;   // 本口无此字段（父级恒常数）" % (p, f, const))
    o.append("")
    o.append("  xs_LqExceptionBuffer_core u_core (")
    conns = [("clock", "clock"), ("reset", "reset")]
    conns += [(n, n) for _, _, n, _ in ports if n.startswith("io_redirect_")]
    conns += [("io_req_valid", "req_valid"), ("io_req_bits", "req_bits")]
    conns += [(n, n) for d, _, n, _ in ports if d == "output"]
    wd = max(len(n) for n, _ in conns)
    for k, (n, e) in enumerate(conns):
        o.append("    .%-*s (%s)%s" % (wd, n, e, "," if k + 1 < len(conns) else ""))
    o.append("  );")
    o.append("endmodule")
    # 端口全覆盖核对
    covered = {"clock", "reset"} | {n for n, _ in conns} | {
        "io_req_%d_valid" % p for p in range(NPORT)} | {
        "io_req_%d_bits_%s" % (p, f) for p in range(NPORT) for f, _ in full}
    if names - covered:
        die("wrapper 漏了端口: %s" % sorted(names - covered)[:5])
    return "\n".join(o) + "\n"


def gen_pins(full, s2, info, has):
    rules = []
    wfull = dict(full)
    for p in range(NPORT):
        for f, w in s2:
            rules.append(("s2_req_%d_%s" % (p, f), w, "s2_q_reg[%d]\\[%s]" % (p, f)))
        if has["isHyper"][p]:
            rules.append(("s2_req_%d_isHyper" % p, 1, "g_port[%d].g_ishyper.ishyper_q_reg" % p))
        if has["vaNeedExt"][p]:
            rules.append(("s2_req_%d_vaNeedExt" % p, 1, "g_port[%d].g_vaneedext.vaneedext_q_reg" % p))
        rules.append(("s2_valid_REG" if p == 0 else "s2_valid_REG_%d" % (2 * p), 1, "s2_valid_q_reg[%d]" % p))
        for gf, f, w in (("valid", "valid", 1), ("bits_robIdx_flag", "robIdx_flag", 1),
                         ("bits_robIdx_value", "robIdx_value", 8), ("bits_level", "level", 1)):
            rules.append(("s2_valid_REG_%d_%s" % (2 * p + 1, gf), w, "s2_redirect_q_reg[%d]\\[%s]" % (p, f)))
    for f, w in info:
        rules.append(("req_%s" % f, w, "req_q_reg\\[%s]" % f))
    rules.append(("req_valid", 1, "req_valid_q_reg"))
    rules.append(("REG", 1, "req_valid_last_q_reg"))
    greg = dict(golden_regs())
    seen_g, seen_i = set(), set()
    for g, w, i in rules:
        if greg.get(g) != w:
            die("钉点规则 %s 宽 %d 与 golden 不符" % (g, w))
        if g in seen_g or i in seen_i:
            die("钉点不是单射: %s / %s" % (g, i))
        seen_g.add(g)
        seen_i.add(i)
    if set(greg) != seen_g:
        die("golden 寄存器没有钉点规则: %s" % sorted(set(greg) - seen_g)[:5])
    expect = sum(w for _, w, _ in rules)
    o = []
    o.append("# LqExceptionBuffer FM「匹配前」钉点 —— 自动生成：scripts/gen_lqexcbuf.py（勿手改）")
    o.append("#")
    o.append("# 只消名差：golden 是按字段展平的寄存器（s2_req_<p>_<字段>、req_<字段>、s2_valid_REG_<n>…），")
    o.append("# 重写核是结构体数组 u_core/s2_q_reg[p]\\[字段][b] 等（字段名下标带一个反斜杠，数字下标不带），")
    o.append("# 只在部分口存在的 isHyper / vaNeedExt 在 generate 块里：u_core/g_port[p].g_ishyper.ishyper_q_reg。")
    o.append("# set_user_match 只声明两点对应，比较照比：不约束 ref、不改 appvar、不加黑盒、不 dont_verify。")
    o.append("# fail-closed：逐条数 set_user_match 的返回值；拒一条或总数 != %d 就 error。" % expect)
    o.append("# 进 fm.log 的输出一律 ASCII。")
    o.append("set ::LEB_PIN_EXPECT %d" % expect)
    o.append("set ::LEB_PIN_OK 0")
    o.append("set ::LEB_PIN_BAD 0")
    o.append("proc leb_pin1 {r i} {")
    o.append("  if {[set_user_match $r $i]} { incr ::LEB_PIN_OK } else {")
    o.append("    incr ::LEB_PIN_BAD")
    o.append("    if {$::LEB_PIN_BAD <= 10} { puts \"LEB_PIN_FAIL: $r <-> $i\" }")
    o.append("  }")
    o.append("}")
    o.append("proc leb_pin {g i w} {")
    o.append("  set r \"r:/WORK/LqExceptionBuffer/${g}_reg\"")
    o.append("  set m \"i:/WORK/LqExceptionBuffer/u_core/$i\"")
    o.append("  if {$w == 1} { leb_pin1 $r $m } else {")
    o.append("    for {set b 0} {$b < $w} {incr b} { leb_pin1 \"$r\\[$b\\]\" \"$m\\[$b\\]\" }")
    o.append("  }")
    o.append("}")
    o.append("puts \"LEB_PIN_BEGIN LqExceptionBuffer expect=$::LEB_PIN_EXPECT\"")
    for g, w, i in rules:
        o.append("leb_pin %s {%s} %d" % (g, i, w))
    o.append("puts \"LEB_PIN_END LqExceptionBuffer ok=$::LEB_PIN_OK bad=$::LEB_PIN_BAD\"")
    o.append("if {$::LEB_PIN_BAD != 0} { error \"LEB_PIN_MISS=$::LEB_PIN_BAD\" }")
    o.append("if {$::LEB_PIN_OK != %d} { error \"LEB_PIN_COUNT=$::LEB_PIN_OK expect=%d\" }" % (expect, expect))
    return "\n".join(o) + "\n"


TB_TEMPLATE = r"""// ===========================================================================
// LqExceptionBuffer UT：golden LqExceptionBuffer 对重写 LqExceptionBuffer_xs，同一激励，
// 逐拍比对全部 5 个输出（io_exceptionAddr_*，共 @NOW@ 位）。
//
// ★激励★ 6 个入口各 ~30% 有效；LduCfg 的 6 个异常位各 ~12%（候选率约一半）；robIdx 从
//   16 值小池（flag x value 0..7）里抽、uopIdx 只取 0..3 —— 同龄（robIdx 相等、比 uopIdx）、
//   绕圈比较、7 个选手互相比都常态出现；地址字段全随机。redirect ~8%，robIdx 同池
//   （本拍冲掉 s2 候选 / 冲掉已记着的那条都会发生）。每 20000 拍一次 3 拍复位。
// ★比较口径★ req 的信息寄存器不复位，但每拍无条件写"锦标赛胜者"：全无效时胜者就是
//   它自己（保持），所以在它第一次记下一条有效异常之前，两侧各保持自己的上电随机值。
//   随机 initreg 档里 5 个输出只在 golden 的 req_valid 第一次为 1 之后才比；
//   +vcs+initreg+0 / +1 两个常量档从第一拍起比。req_valid 本身（复位域）不是输出，
//   它的对错经由"何时开始换记另一条"间接可见。
// ★覆盖★ COVERAGE 行各项为 0 本轮判红。
// 自动生成：scripts/gen_lqexcbuf.py —— 勿手改
// ===========================================================================
`timescale 1ns/1ps

module tb;
  import lqexceptionbuffer_pkg::*;

  int unsigned NCYCLES = 200000;
  bit   clk = 0;
  logic rst;
  int      errors = 0;
  longint  checks = 0;
  bit      cmp_all = 0;
  bit      written = 0;
  always #5 clk = ~clk;

  logic            io_redirect_valid;
  logic            io_redirect_bits_robIdx_flag;
  logic [7:0]      io_redirect_bits_robIdx_value;
  logic            io_redirect_bits_level;
  logic [5:0]      req_valid;
  leb_req_t        req_bits [6];

  localparam int NOW = @NOW@;
  wire [NOW-1:0] g_out, x_out;

@INSTS@

  longint cov_cand = 0, cov_multi = 0, cov_replace = 0, cov_keep = 0, cov_tie = 0, cov_flush = 0, cov_reset = 0;
  logic [63:0] prev_vaddr;

  task automatic quiet();
    io_redirect_valid = 0; io_redirect_bits_robIdx_flag = 0; io_redirect_bits_robIdx_value = 0;
    io_redirect_bits_level = 0; req_valid = 0;
    for (int p = 0; p < 6; p++) req_bits[p] = '0;
  endtask

  task automatic drive();
    logic [$bits(leb_req_t)+31:0] rnd;
    io_redirect_valid = ($urandom_range(0, 99) < 8);
    io_redirect_bits_robIdx_flag = $urandom_range(0, 1);
    io_redirect_bits_robIdx_value = 8'($urandom_range(0, 7));
    io_redirect_bits_level = $urandom_range(0, 1);
    for (int p = 0; p < 6; p++) begin
      for (int b = 0; b < $bits(leb_req_t); b += 32) rnd[b +: 32] = $urandom();
      req_bits[p] = rnd[$bits(leb_req_t)-1:0];
      req_valid[p] = ($urandom_range(0, 99) < 30);
      req_bits[p].uop_robIdx_flag = $urandom_range(0, 1);
      req_bits[p].uop_robIdx_value = 8'($urandom_range(0, 7));
      req_bits[p].uop_uopIdx = 7'($urandom_range(0, 3));
      req_bits[p].uop_exceptionVec_3  = ($urandom_range(0, 99) < 12);
      req_bits[p].uop_exceptionVec_4  = ($urandom_range(0, 99) < 12);
      req_bits[p].uop_exceptionVec_5  = ($urandom_range(0, 99) < 12);
      req_bits[p].uop_exceptionVec_13 = ($urandom_range(0, 99) < 12);
      req_bits[p].uop_exceptionVec_19 = ($urandom_range(0, 99) < 12);
      req_bits[p].uop_exceptionVec_21 = ($urandom_range(0, 99) < 12);
    end
  endtask

  task automatic compare(int cyc);
    if (u_g.req_valid) written = 1;
    checks++;
    if ((cmp_all || written) && g_out !== x_out) begin
      errors++;
      if (errors <= 20) $display("[%0d] MISMATCH g=%h x=%h", cyc, g_out, x_out);
    end
  endtask

  task automatic sample();   // 时钟沿之前：看即将被采下的量
    int n;
    n = 0;
    for (int p = 0; p < 6; p++) if (u_x.u_core.s2_enqueue[p]) n++;
    cov_cand += n;
    if (n >= 2) cov_multi++;
    if (u_x.u_core.cand[6].valid && n > 0) begin
      if (u_x.u_core.winner.bits == u_x.u_core.req_q) cov_keep++; else cov_replace++;
    end
    for (int p = 0; p < 6; p++)
      for (int q = p + 1; q < 6; q++)
        if (u_x.u_core.s2_enqueue[p] && u_x.u_core.s2_enqueue[q]
            && u_x.u_core.s2_req[p].uop_robIdx_flag == u_x.u_core.s2_req[q].uop_robIdx_flag
            && u_x.u_core.s2_req[p].uop_robIdx_value == u_x.u_core.s2_req[q].uop_robIdx_value)
          cov_tie++;
    if (u_x.u_core.req_valid_q && !u_x.u_core.cand[6].valid) cov_flush++;
  endtask

  initial begin
    string ir;
    void'($value$plusargs("ncycles=%d", NCYCLES));
    if ($value$plusargs("vcs+initreg+%s", ir) && (ir == "0" || ir == "1")) cmp_all = 1;
    rst = 1'b1;
    quiet();
    repeat (4) @(posedge clk);
    #1 rst = 1'b0;
    for (int cyc = 0; cyc < NCYCLES; cyc++) begin
      if (cyc % 20000 == 10000) begin
        rst = 1'b1; quiet(); cov_reset++;
        repeat (3) @(posedge clk);
        #1 rst = 1'b0;
      end
      drive();
      #1 compare(cyc);
      sample();
      @(posedge clk);
      #1;
    end
    $display("COVERAGE cand=%0d multi=%0d replace=%0d keep=%0d tie=%0d flush_held=%0d reset=%0d",
             cov_cand, cov_multi, cov_replace, cov_keep, cov_tie, cov_flush, cov_reset);
    if (cov_cand == 0 || cov_multi == 0 || cov_replace == 0 || cov_keep == 0 || cov_tie == 0
        || cov_flush == 0 || cov_reset == 0) begin
      $display("COVERAGE HOLE -> run does not count");
      errors++;
    end
    $display("checks=%0d errors=%0d", checks, errors);
    if (errors == 0) $display("TEST PASSED"); else $display("TEST FAILED");
    $finish;
  end
endmodule
"""


def gen_tb(ports, full):
    outs = [(n, w) for d, w, n, _ in ports if d == "output"]
    lay, off = [], 0
    for n, w in outs:
        lay.append((n, off, w))
        off += w
    names = {n for _, _, n, _ in ports}
    body = []
    for side, mod in (("g", TOP), ("x", TOP + "_xs")):
        conns = [("clock", "clk"), ("reset", "rst")]
        for d, w, n, _ in ports:
            if n in ("clock", "reset"):
                continue
            if d == "output":
                o = next(x for x in lay if x[0] == n)
                conns.append((n, "%s_out[%d +: %d]" % (side, o[1], o[2])))
                continue
            m = re.fullmatch(r"io_req_(\d)_valid", n)
            if m:
                conns.append((n, "req_valid[%s]" % m.group(1)))
                continue
            m = re.fullmatch(r"io_req_(\d)_bits_(\w+)", n)
            if m:
                conns.append((n, "req_bits[%s].%s" % (m.group(1), m.group(2))))
                continue
            conns.append((n, n))
        body.append("  %s u_%s (" % (mod, side))
        wd = max(len(n) for n, _ in conns)
        for k, (n, e) in enumerate(conns):
            body.append("    .%-*s (%s)%s" % (wd, n, e, "," if k + 1 < len(conns) else ""))
        body.append("  );")
    t = TB_TEMPLATE.replace("@NOW@", str(off)).replace("@INSTS@", "\n".join(body))
    return t


def replace_region(text, tag, body):
    b = "// BEGIN GENERATED(%s)\n" % tag
    e = "// END GENERATED\n"
    i = text.index(b) + len(b)
    j = text.index(e, i)
    return text[:i] + body + text[j:]


def targets():
    ports, full, s2, info, has = analyse()
    txt = open(SRC).read()
    txt = replace_region(txt, "leb-types", gen_types(full, s2, info))
    txt = replace_region(txt, "leb-wrapper", gen_wrapper(ports, full, has))
    return {SRC: txt,
            os.path.join(UT, "fm_pins_pre.tcl"): gen_pins(full, s2, info, has),
            os.path.join(UT, "tb.sv"): gen_tb(ports, full)}


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--check", action="store_true", help="只比对不写，有漂移 rc=1")
    args = ap.parse_args()
    drift = 0
    for path, text in targets().items():
        cur = open(path).read() if os.path.exists(path) else None
        if cur == text:
            print("gen_lqexcbuf: OK     %s" % os.path.relpath(path, REPO))
            continue
        if args.check:
            print("gen_lqexcbuf: DRIFT  %s" % os.path.relpath(path, REPO))
            drift += 1
        else:
            os.makedirs(os.path.dirname(path), exist_ok=True)
            with open(path, "w") as f:
                f.write(text)
            print("gen_lqexcbuf: WROTE  %s" % os.path.relpath(path, REPO))
    return 1 if drift else 0


if __name__ == "__main__":
    sys.exit(main())
