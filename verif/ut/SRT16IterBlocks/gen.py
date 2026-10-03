#!/usr/bin/env python3
"""gen.py —— 生成 SRT16IterBlocks UT 的 tb.sv（块级双例化区按 golden 端口表机械展开）。

tb 由两部分组成：
  (A) 块级：SelBlock_v4 / SpecBlock_v4 / IterBlock_v4{,_4,_6} 各自 golden vs _xs 双例化，
      每拍随机灌全部输入（商位独热口 80% 独热、20% 任意；整拍全 0 / 全 1 各少量），
      逐拍比全部输出。端口多（IterBlock 125 个），故按 golden 端口表生成。
  (B) 系统级：golden SRT16Divint{,_4,_6} vs 「同一 golden 父级、IterBlock 子树换成重写件」
      各一对，跑真实除法，逐拍对拍 + 独立 oracle（div_lane.sv，手写）。
本脚本只生成 tb.sv；div_lane.sv 与 Makefile 手写。

用法: python3 gen.py [--check]   （幂等：内容不变不碰文件；--check 有漂移 rc=1）
"""
import argparse
import os
import pathlib
import re
import sys

HERE = pathlib.Path(__file__).resolve().parent
GOLDEN_DIR = os.environ.get("GOLDEN_RTL", "/home/eda/xs-env/G1-canonical/golden-rtl")
PORT_RE = re.compile(r"^\s*(input|output)\s+(?:\[(\d+):0\])?\s*(\w+)\s*,?\s*$")

BLOCKS = ["SelBlock_v4", "SpecBlock_v4", "IterBlock_v4", "IterBlock_v4_4", "IterBlock_v4_6"]
QPORTS = {"io_q_j", "io_q_j_1"}            # 独热商位输入
QOUTS = {"SelBlock_v4": "io_q_j_1", "SpecBlock_v4": "io_q_j_2"}   # 覆盖统计的商位输出
LANES = [("SRT16Divint", 16, 1), ("SRT16Divint_4", 32, 2), ("SRT16Divint_6", 64, 3)]


def ports(module):
    text = open(os.path.join(GOLDEN_DIR, module + ".sv")).read()
    m = re.search(r"^module %s\((.*?)^\);" % re.escape(module), text, re.S | re.M)
    out = []
    for line in m.group(1).splitlines():
        if line.strip():
            pm = PORT_RE.match(line)
            assert pm, line
            out.append((pm.group(1), int(pm.group(2)) + 1 if pm.group(2) else 1, pm.group(3)))
    return out


def block_section(mod):
    ps = ports(mod)
    ins = [p for p in ps if p[0] == "input"]
    outs = [p for p in ps if p[0] == "output"]
    s = []
    s.append("  // ---------------- %s（%d 入 / %d 出）----------------" % (mod, len(ins), len(outs)))
    for _, w, n in ins:
        s.append("  logic [%d:0] %s__%s;" % (w - 1, mod, n))
    for _, w, n in outs:
        s.append("  wire  [%d:0] %s__g__%s, %s__i__%s;" % (w - 1, mod, n, mod, n))
    for side, name in (("g", mod), ("i", mod + "_xs")):
        s.append("  %s u_%s_%s (" % (name, side, mod))
        conns = ["    .%s(%s__%s)" % (n, mod, n) for _, _, n in ins]
        conns += ["    .%s(%s__%s__%s)" % (n, mod, side, n) for _, _, n in outs]
        s.append(",\n".join(conns))
        s.append("  );")
    s.append("  task automatic drive_%s(input int mode);" % mod)
    for _, w, n in ins:
        if n in QPORTS:
            s.append("    %s__%s = pick_q(mode);" % (mod, n))
        else:
            s.append("    %s__%s = %d'(rnd_bits(mode));" % (mod, n, w))
    s.append("  endtask")
    s.append("  task automatic check_%s();" % mod)
    for _, w, n in outs:
        s.append("    checks++;")
        s.append("    if (%s__g__%s !== %s__i__%s) begin errors++; if (errors <= 10) "
                 "$display(\"MISMATCH %s.%s g=%%h i=%%h\", %s__g__%s, %s__i__%s); end"
                 % (mod, n, mod, n, mod, n, mod, n, mod, n))
    if mod in QOUTS:
        q = QOUTS[mod]
        s.append("    qhist_%s[q_class(%s__g__%s)]++;" % (mod, mod, q))
    s.append("  endtask")
    return "\n".join(s)


HEADER = """// =============================================================================
// tb —— SRT radix-16 整数除法迭代块 UT（SelBlock_v4 / SpecBlock_v4 / IterBlock_v4{,_4,_6}）
//
// (A) 块级双例化：五个块各自 golden vs 重写（_xs），每拍随机灌全部输入、逐拍比全部
//     输出。商位独热口（io_q_j / io_q_j_1）80% 取独热、20% 取任意 5 位（golden 的
//     Mux1H 是按位或，多热也要一致）；每拍另有 1/16 概率全 0、1/16 全 1。
// (B) 系统级：golden SRT16Divint{,_4,_6} 与「同一 golden 父级、但 IterBlock 子树换成
//     重写件」的副本（ut_gen/subst_*.sv）各一对，由 div_lane 跑真实除法：逐拍对拍
//     + 独立 oracle（商/余数逐位对照 RISC-V 语义：除零、负数、最小值/-1、各 SEW）。
//     这一层让重写件处在真实的商位/余数分布下，补块级随机激励覆盖不到的「合法轨迹」。
// 判据：两部分 errors 合计 0 才打印 TEST PASSED。
// 本文件由 verif/ut/SRT16IterBlocks/gen.py 生成，勿手改。
// =============================================================================
`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 200000;
  bit clk = 0; always #5 clk = ~clk;
  longint errors = 0, checks = 0;

  function automatic logic [127:0] rnd_bits(input int mode);
    if (mode == 1) return '0;
    if (mode == 2) return '1;
    return {$urandom, $urandom, $urandom, $urandom};
  endfunction
  function automatic logic [4:0] pick_q(input int mode);
    if (mode == 1) return '0;
    if (mode == 2) return '1;
    if ($urandom_range(0, 9) < 8) return 5'd1 << $urandom_range(0, 4);
    return 5'($urandom);
  endfunction
  // 商位输出分类：0..4 = 独热第 i 位，5 = 全 0，6 = 多热
  function automatic int q_class(input logic [4:0] q);
    if (q == 0) return 5;
    if ($onehot(q)) for (int i = 0; i < 5; i++) if (q[i]) return i;
    return 6;
  endfunction
  longint qhist_SelBlock_v4 [7] = '{default: 0};
  longint qhist_SpecBlock_v4 [7] = '{default: 0};
"""

LANE_TMPL = """
  // ---------------- 系统级车道：{mod}（{w} 位）----------------
  logic        L{w}_rst, L{w}_sign, L{w}_flush, L{w}_in_valid, L{w}_out_ready;
  logic [{wm}:0] L{w}_dividend, L{w}_divisor;
  logic [1:0]  L{w}_sew;
  wire         L{w}_g_valid, L{w}_i_valid;
  wire  [{wm}:0] L{w}_g_q, L{w}_g_rem, L{w}_i_q, L{w}_i_rem;
  div_lane #(.WIDTH({w}), .MAXSEW({maxsew}), .NAME("{mod}")) u_lane{w} (
    .clk(clk), .rst(L{w}_rst), .sign(L{w}_sign), .dividend(L{w}_dividend), .divisor(L{w}_divisor),
    .flush(L{w}_flush), .sew(L{w}_sew), .in_valid(L{w}_in_valid), .out_ready(L{w}_out_ready),
    .g_valid(L{w}_g_valid), .g_q(L{w}_g_q), .g_rem(L{w}_g_rem),
    .i_valid(L{w}_i_valid), .i_q(L{w}_i_q), .i_rem(L{w}_i_rem));
  {mod} u_g_{mod} (
    .clock(clk), .reset(L{w}_rst), .io_sign(L{w}_sign), .io_dividend(L{w}_dividend),
    .io_divisor(L{w}_divisor), .io_flush(L{w}_flush), .io_sew(L{w}_sew),
    .io_div_in_valid(L{w}_in_valid), .io_div_out_ready(L{w}_out_ready),
    .io_div_out_valid(L{w}_g_valid), .io_div_out_q(L{w}_g_q), .io_div_out_rem(L{w}_g_rem));
  {mod}_subst u_i_{mod} (
    .clock(clk), .reset(L{w}_rst), .io_sign(L{w}_sign), .io_dividend(L{w}_dividend),
    .io_divisor(L{w}_divisor), .io_flush(L{w}_flush), .io_sew(L{w}_sew),
    .io_div_in_valid(L{w}_in_valid), .io_div_out_ready(L{w}_out_ready),
    .io_div_out_valid(L{w}_i_valid), .io_div_out_q(L{w}_i_q), .io_div_out_rem(L{w}_i_rem));
"""

FOOTER = """
  // ---------------- 主循环：下降沿灌块级激励，上升沿比块级输出 ----------------
  initial begin
    int mode;
    if ($value$plusargs("ncycles=%d", NCYCLES)) ;
    for (int unsigned c = 0; c < NCYCLES; c++) begin
      @(negedge clk);
      mode = ($urandom_range(0, 15) == 0) ? 1 : (($urandom_range(0, 15) == 0) ? 2 : 0);
{drives}
      @(posedge clk);
      #1;
{checks}
    end
    @(negedge clk);
    $display("blocks: checks=%0d", checks);
    $display("cover SelBlock_v4 q_j_1 (golden): +2=%0d +1=%0d 0=%0d -1=%0d -2=%0d none=%0d multi=%0d",
             qhist_SelBlock_v4[0], qhist_SelBlock_v4[1], qhist_SelBlock_v4[2], qhist_SelBlock_v4[3],
             qhist_SelBlock_v4[4], qhist_SelBlock_v4[5], qhist_SelBlock_v4[6]);
    $display("cover SpecBlock_v4 q_j_2 (golden): +2=%0d +1=%0d 0=%0d -1=%0d -2=%0d none=%0d multi=%0d",
             qhist_SpecBlock_v4[0], qhist_SpecBlock_v4[1], qhist_SpecBlock_v4[2], qhist_SpecBlock_v4[3],
             qhist_SpecBlock_v4[4], qhist_SpecBlock_v4[5], qhist_SpecBlock_v4[6]);
{reports}
    errors += {lane_errs};
    $display("SRT16IterBlocks: block_checks=%0d lane_checks=%0d errors=%0d", checks, {lane_checks}, errors);
    if (errors == 0 && {lane_done_ok}) $display("TEST PASSED");
    else $display("TEST FAILED");
    $finish;
  end
endmodule
"""


def render():
    parts = [HEADER]
    for m in BLOCKS:
        parts.append(block_section(m) + "\n")
    for mod, w, maxsew in LANES:
        parts.append(LANE_TMPL.format(mod=mod, w=w, wm=w - 1, maxsew=maxsew))
    drives = "\n".join("      drive_%s(mode);" % m for m in BLOCKS)
    checks = "\n".join("      check_%s();" % m for m in BLOCKS)
    reports = "\n".join("    u_lane%d.report();" % w for _, w, _ in LANES)
    lane_errs = " + ".join("u_lane%d.errors" % w for _, w, _ in LANES)
    lane_checks = " + ".join("u_lane%d.oracle_checks" % w for _, w, _ in LANES)
    # 每条车道至少完成 1000 次除法，否则判失败（防"车道卡死、零检查也算过"）
    lane_done_ok = " && ".join("u_lane%d.ops_done >= 1000" % w for _, w, _ in LANES)
    parts.append(FOOTER.format(drives=drives, checks=checks, reports=reports,
                               lane_errs=lane_errs, lane_checks=lane_checks,
                               lane_done_ok=lane_done_ok))
    return "".join(parts)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--check", action="store_true")
    args = ap.parse_args()
    path = HERE / "tb.sv"
    text = render()
    cur = path.read_text() if path.exists() else None
    if cur == text:
        print("gen.py: OK     tb.sv")
        return 0
    if args.check:
        print("gen.py: DRIFT  tb.sv")
        return 1
    path.write_text(text)
    print("gen.py: WROTE  tb.sv")
    return 0


if __name__ == "__main__":
    sys.exit(main())
