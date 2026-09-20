#!/usr/bin/env python3
"""生成 CLZ 家族 9 个变体的薄文件（rtl/common/）与家族 tb。

事实来源是 gen_facts.facts()：它把 golden 的整条三元链**由家族公式重建出来逐字
比对**（9/9 一致），所以这里写下的 WIDTH / SCAN_LOW / OUT_W 都不是抄的，是算的。
薄文件一律由本脚本生成，参数名和参数值只有一个来源
（见 scripts/check_param_override.py 顶部那次"改个参数名就静默解除不变式"的事故）。
"""
import os, sys

G = os.environ.get("GOLDEN_RTL", "/home/eda/xs-env/G1-canonical/golden-rtl")
HERE = os.path.dirname(os.path.abspath(__file__))
RTL = os.path.abspath(os.path.join(HERE, "../../../rtl/common"))
sys.path.insert(0, HERE)
from gen_facts import facts     # noqa: E402

# 使用者由 grep golden 得到（`grep -lE "^  <变体> " golden-rtl/*.sv`），不是猜的。
USE = {
    "CLZ":    "IntToFP_prenorm —— 64 位整数转浮点的预规格化左移量",
    "CLZ_6":  "Estimate7 / FP_INCVT / INT2FP / VIntMisc64b —— 64 位规格化",
    "CLZ_7":  "CVT32 / CVT16 / VIntMisc64b —— 16 位规格化",
    "CLZ_9":  "CVT32 / VIntMisc64b —— 32 位规格化",
    "CLZ_11": "VIntMisc64b —— 8 位规格化（向量 vclz.v 的 8 位元素）",
    "CLZ_28": "CVT32 / CVT16 —— 10 位尾数规格化",
    "CLZ_29": "CVT32 —— 23 位单精度尾数规格化",
    "CLZ_30": "CVT32 / CVT16 —— 11 位半精度尾数规格化",
    "CLZ_31": "CVT32 —— 24 位（含隐含位）尾数规格化",
}
VARIANTS = list(USE)


def gen_variant(name):
    f = facts(name)
    w, ow, sl, none = f["width"], f["out_w"], f["scan_low"], f["none"]
    if sl == 0:
        shape = ("SCAN_LOW=0：扫到第 0 位，全零输入输出 WIDTH=%d —— 教科书意义上的 CLZ。" % w)
    else:
        shape = ("★SCAN_LOW=%d：golden **没有读** io_in[0..%d]★\n"
                 "//   全零输入输出 %d（= WIDTH-%d），**不是 %d**；也就是说「全零」与\n"
                 "//   「只有最低 %d 位里有 1」这两件事在这里输出相同。这是 Chisel\n"
                 "//   PriorityEncoder 的兜底语义（最后一个候选索引不带条件判断），\n"
                 "//   io_out 只有 %d 位、装不下 %d，端口宽度本身就是痕迹。\n"
                 "//   本工程要求 bug-for-bug 一致 —— 照抄，不\"修正\"。"
                 % (sl, sl - 1, none, sl, w, sl, ow, w))
    return """// =============================================================================
// %(name)s —— %(w)d 位前导零计数（xs_CLZ_core 家族的一个变体）
//
// 本变体的参数与规模（按 G1 golden 现读）：
//   输入 WIDTH = %(w)d 位，输出 OUT_W = %(ow)d 位，最低扫描位 SCAN_LOW = %(sl)d；
//   扫描范围内没有 1 时输出 NONE = %(none)d；golden 模块体 = 一条 %(nterm)d 项的三元链，
//   无寄存器、无子模块（纯组合）。
//   使用者：%(use)s。
//
// 家族形状：%(shape)s
//
// 结构：golden 端口 -> 设参例化 xs_CLZ_core（优先级方向与 SCAN_LOW 的语义
//   都在 xs_CLZ_core.sv 里讲）-> 直接出。本层只设参数。
//   WIDTH / SCAN_LOW / OUT_W 是三条**各自独立**从 golden 抽出来的事实
//   （前两条来自模块体真正引用到的位，第三条来自端口表），核里的
//   OUT_W == $clog2(NONE+1) 把三者对上；PORT_BITS_IN/OUT 再用 $bits(golden 端口)
//   把端口表本身对一遍。任何一处抄错，time 0 直接 $fatal。
// 自动生成：verif/ut/CLZ/gen.py（读 G1 golden）—— 勿手改
// =============================================================================

module %(name)s(
%(head)s

  localparam int unsigned WIDTH    = %(w)d;   // golden io_in 位宽
  localparam int unsigned SCAN_LOW = %(sl)d;   // 最低被扫描的位
  localparam int unsigned OUT_W    = %(ow)d;   // golden io_out 位宽

  // 端口表事实：$bits 只认端口声明，抄错位宽这些常量立刻跟着变
  localparam int unsigned PORT_BITS_IN  = $bits(io_in);
  localparam int unsigned PORT_BITS_OUT = $bits(io_out);

  xs_CLZ_core #(
    .WIDTH        (WIDTH),
    .SCAN_LOW     (SCAN_LOW),
    .OUT_W        (OUT_W),
    .PORT_BITS_IN (PORT_BITS_IN),
    .PORT_BITS_OUT(PORT_BITS_OUT)
  ) u_core (
    .d_in(io_in),
    .cnt (io_out)
  );

endmodule
""" % dict(name=name, w=w, ow=ow, sl=sl, none=none, use=USE[name], shape=shape,
           nterm=w - sl, head=f["head_text"].split(chr(10), 1)[1])


TB_HEAD = """// 自动生成：verif/ut/CLZ/gen.py（读 G1 golden）—— 勿手改
// CLZ 家族 %(nv)d 变体双例化逐拍比对：golden <V> vs 可读重写 <V>_xs
//   （同一个 xs_CLZ_core 设不同 WIDTH / SCAN_LOW / OUT_W）。
// 被测语义：从最高位往下找第一个 1，输出它前面有几个 0；扫描范围内没有 1 时
//   输出 NONE = WIDTH - SCAN_LOW。纯组合，无寄存器，故不需要热身窗口。
//
// ★SCAN_LOW=1 的那个变体（CLZ 本体）必须被这个 tb 真的打到★
//   它不读 io_in[0]：全零输入与"只有第 0 位是 1"输出**相同**（都是 63）。
//   激励里专门有"全零"和"单点 one-hot 到每一位"两种模式，覆盖闸再要求
//   **每一个可能的输出值都被观察到**（0..NONE 全见），这两件事才算被证到。
//
// 激励每拍按 8 种模式之一：全零 / 全一 / 随机 one-hot / **指定前导零个数**
//   （清掉最高 k 位再把第 WIDTH-1-k 位置 1，于是输出确定等于 k）/ 全随机。
//   第 4 种是覆盖闸能在 20 万拍内填满 0..64 的原因，不靠运气。
// 覆盖闸：每个变体都要 (1) 比对次数 >= COV_MIN；(2) **0..NONE 每个输出值都见过**；
//   (3) 全零输入至少 COV_MIN 次；(4) 输入每一位都见过 1 和 0。
`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 200000;
  localparam int COV_MIN = 1000;
  bit clock = 0;
  int errors = 0, checks = 0, cov_fail = 0;
  always #5 clock = ~clock;
"""


def gen_tb():
    L, infos = [], []
    for i, name in enumerate(VARIANTS):
        f = facts(name)
        s = "c%d" % i
        infos.append((name, s, f))
        w, ow, none = f["width"], f["out_w"], f["none"]
        L.append("  // ---- %s: WIDTH=%d OUT_W=%d SCAN_LOW=%d NONE=%d ----"
                 % (name, w, ow, f["scan_low"], none))
        L.append("  logic [%d:0] %s_in;" % (w - 1, s))
        L.append("  wire  [%d:0] g_%s_out, i_%s_out;" % (ow - 1, s, s))
        L.append("  logic [%d:0] %s_ones, %s_zeros;" % (w - 1, s, s))
        L.append("  logic [%d:0] %s_seen;   // 见过的输出值（位 v = 输出过 v）" % (none, s))
        L.append("  int   %s_checks, %s_zero_in;" % (s, s))
        for tag, mod in (("g", name), ("i", name + "_xs")):
            L.append("  %s u_%s_%s (.io_in(%s_in), .io_out(%s_%s_out));"
                     % (mod, tag, s, s, tag, s))
        L.append("")

    drive, check, init, cov = [], [], [], []
    for name, s, f in infos:
        w, none = f["width"], f["none"]
        drive.append("""    case ($urandom_range(0, 7))
      0: %(s)s_in = '0;                                  // 全零：SCAN_LOW 语义的关键用例
      1: %(s)s_in = '1;
      2: begin                                       // 随机 one-hot（含第 0 位）
           %(s)s_in = '0;
           %(s)s_in[$urandom_range(0, %(wm)d)] = 1'b1;
         end
      3, 4: begin                                    // 指定前导零个数 k，输出必等于 k
           int k;
           k = $urandom_range(0, %(w)d);
           for (int b = 0; b < %(w)d; b++) %(s)s_in[b] = 1'($urandom);
           for (int b = 0; b < k; b++) %(s)s_in[%(wm)d - b] = 1'b0;
           if (k < %(w)d) %(s)s_in[%(wm)d - k] = 1'b1; else %(s)s_in = '0;
         end
      default: for (int b = 0; b < %(w)d; b++) %(s)s_in[b] = 1'($urandom);
    endcase""" % dict(s=s, w=w, wm=w - 1))
        check.append("""    checks++; %(s)s_checks++;
    %(s)s_ones  |= %(s)s_in;
    %(s)s_zeros |= ~%(s)s_in;
    if (%(s)s_in == '0) %(s)s_zero_in++;
    %(s)s_seen[g_%(s)s_out] = 1'b1;
    if (g_%(s)s_out !== i_%(s)s_out) begin
      errors++;
      if (errors <= 20)
        $display("[%%0t] MISMATCH %(n)s in=%%0h g=%%0d i=%%0d",
                 $time, %(s)s_in, g_%(s)s_out, i_%(s)s_out);
    end""" % dict(s=s, n=name))
        init.append("    %s_in = '0; %s_ones = '0; %s_zeros = '0; %s_seen = '0;\n"
                    "    %s_checks = 0; %s_zero_in = 0;" % (s, s, s, s, s, s))
        cov.append("""    $display("  %(n)s: checks=%%0d zero_in=%%0d seen=%%0d/%(nv)d ones=%%0d/%(w)d zeros=%%0d/%(w)d",
             %(s)s_checks, %(s)s_zero_in, $countones(%(s)s_seen),
             $countones(%(s)s_ones), $countones(%(s)s_zeros));
    cov_fail += cov_short("%(n)s checks",  %(s)s_checks)
              + cov_short("%(n)s zero_in", %(s)s_zero_in);
    if (!(&%(s)s_seen)) begin
      $display("COVERAGE FAIL: %(n)s 有输出值从未被观察到（见 %%0d / %(nv)d）",
               $countones(%(s)s_seen)); cov_fail++;
    end
    if (!(&%(s)s_ones) || !(&%(s)s_zeros)) begin
      $display("COVERAGE FAIL: %(n)s 有输入位从未见过 1 或 0"); cov_fail++;
    end""" % dict(n=name, s=s, w=w, nv=none + 1))

    nl = "\n"
    L = [TB_HEAD % dict(nv=len(VARIANTS))] + L
    L.append("""
  function automatic int cov_short(string what, int n);
    if (n < COV_MIN) begin
      $display("COVERAGE FAIL: %%s 只发生 %%0d 次 (需 >= %%0d)", what, n, COV_MIN);
      return 1;
    end
    return 0;
  endfunction

  task automatic drive_random_inputs();
%(drive)s
  endtask

  task automatic check_outputs();
%(check)s
  endtask

  initial begin
    if ($value$plusargs("ncycles=%%d", NCYCLES)) begin end
%(init)s
    repeat (NCYCLES) begin
      @(negedge clock);
      drive_random_inputs();
      #1 check_outputs();     // 纯组合：驱动后延一个 delta 再比
      @(posedge clock);
    end
    $display("CLZ family checks=%%0d errors=%%0d", checks, errors);
%(cov)s
    if (errors == 0 && cov_fail == 0) begin
      $display("TEST PASSED");
      $finish;
    end
    $display("TEST FAILED (errors=%%0d cov_fail=%%0d)", errors, cov_fail);
    $fatal(1);
  end
endmodule
""" % dict(drive=nl.join(drive), check=nl.join(check),
           init=nl.join(init), cov=nl.join(cov)))
    open(os.path.join(HERE, "tb.sv"), "w").write("\n".join(L))
    print("wrote tb.sv (%d variants)" % len(VARIANTS))


if __name__ == "__main__":
    for n in VARIANTS:
        open(os.path.join(RTL, n + ".sv"), "w").write(gen_variant(n))
        print("wrote", os.path.join(RTL, n + ".sv"))
    gen_tb()
