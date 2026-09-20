#!/usr/bin/env python3
"""生成 PipeWithFlush 家族 8 个变体的薄文件（rtl/common/）与家族 tb。

事实来源是 gen_facts.facts()：它把 golden 的整个模块体**由家族公式重建出来逐字
比对**（8/8 一致），连 firtool 的 CSE 临时 wire、loadDependency 的级间左移、
ogFail 的下标都在比对范围内。所以这里写下的每一个参数都不是抄的，是算的。
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
    "PipeWithFlush":    "后端发射流水 —— 0 级直通（fuType/pdest/rfWen + 3 路 loadDependency）",
    "PipeWithFlush_1":  "后端发射流水 —— 2 级，**家族里唯一带 loadDependency 老化与 ldCancel 冲刷的变体**",
    "PipeWithFlush_6":  "后端发射流水 —— 1 级，无冲刷（第 1 级本来就不冲刷）",
    "PipeWithFlush_7":  "后端发射流水 —— 2 级，redirect + og0Fail 冲刷",
    "PipeWithFlush_8":  "后端发射流水 —— 0 级直通（fuType/pdest/fpWen/vecWen/v0Wen）",
    "PipeWithFlush_9":  "后端发射流水 —— 3 级，redirect + og0Fail/og1Fail 冲刷",
    "PipeWithFlush_10": "后端发射流水 —— 1 级，无冲刷",
    "PipeWithFlush_11": "后端发射流水 —— 3 级，redirect + og0Fail/og1Fail 冲刷（4 字段窄载荷）",
}
VARIANTS = list(USE)

ROBIDX = ["_robIdx_flag", "_robIdx_value"]


def layout(f):
    """把字段表分成三块，并给出核约定的拼包顺序（高位在前）。

    载荷 = { 普通字段(golden 端口顺序), robIdx_flag, robIdx_value, ld_(n-1) … ld_0 }
    robIdx 与 loadDependency 固定放低位，核就不必再要一串位置参数。
    """
    ld = f["ld_fields"]
    has_rob = all(r in [x for x, _w in f["fields"]] for r in ROBIDX) and bool(ld) or \
        all(r in [x for x, _w in f["fields"]] for r in ROBIDX)
    plain = [x for x, _w in f["fields"] if x not in ld and not (has_rob and x in ROBIDX)]
    order = plain + (ROBIDX if has_rob else []) + list(reversed(ld))
    return has_rob, plain, ld, order


def wrap(names, indent, tail=""):
    lines, cur = [], indent + "{"
    for i, n in enumerate(names):
        piece = n + ("}" + tail if i == len(names) - 1 else ",")
        if len(cur) + len(piece) + 1 > 90 and not cur.endswith("{"):
            lines.append(cur)
            cur = indent + " " + piece
        else:
            cur += ("" if cur.endswith("{") else " ") + piece
    lines.append(cur)
    return "\n".join(lines)


def gen_variant(name):
    f = facts(name)
    st, ld = f["stages"], f["ld_fields"]
    has_rob, plain, _ld, order = layout(f)
    ins = ["io_enq_bits" + x for x in order]
    outs = ["io_deq_bits" + x for x in order]

    if st == 0:
        shape = ("STAGES=0：enq 直通 deq。golden 连 clock / reset / 任何 flush 端口都没有。")
    elif st == 1:
        shape = ("STAGES=1：**没有任何 flush 端口** —— 不是被裁剪了，是第 1 级本来就不冲刷\n"
                 "//   （判据要读的条目还在组合输入上，没落进寄存器）。")
    else:
        og = " / ".join("og%dFail" % k for k in range(st - 1))
        shape = ("STAGES=%d：第 2..%d 级带冲刷，每级一根专属的 %s。\n"
                 "//   %s" % (st, st,
                              og,
                              ("另有 %d 路 ldCancel × loadDependency 冲刷，且 loadDependency\n"
                               "//   每前移一级左移一位（老化）—— 全家族只有本变体有这一路。" % len(ld))
                              if ld else "没有 loadDependency，故没有 ldCancel 那一路。"))

    # flush 端口：golden 没有的一律接常 0，并在连接行之前写明原因
    if st >= 2:
        rob = "{io_flush_redirect_bits_robIdx_flag, io_flush_redirect_bits_robIdx_value}"
        ldc = ("{%s}" % ", ".join("io_flush_ldCancel_%d_ld2Cancel" % j
                                  for j in reversed(range(len(ld))))) if ld else "1'b0"
        ldc_note = ("" if ld else
                    "    // 本变体没有 loadDependency，也就没有 ldCancel 那一路；\n"
                    "    // 核的这个输入是 1 位占位（SV 不允许零宽端口），接常 0。\n")
        ogf = "{%s}" % ", ".join("io_flush_og%dFail" % k for k in reversed(range(st - 1)))
        flush = ("    .flush_redirect_valid (io_flush_redirect_valid),\n"
                 "    .flush_redirect_level (io_flush_redirect_bits_level),\n"
                 "    .flush_redirect_robidx(%s),\n" % rob
                 + ldc_note +
                 "    .flush_ldcancel       (%s),\n" % ldc +
                 "    // 位 k-2 给第 k 级：bit0=og0Fail 管第 2 级，依次类推\n"
                 "    .flush_ogfail         (%s),\n" % ogf)
    else:
        flush = ("    // golden 没有任何 io_flush_* 端口（STAGES=%d，第 1 级不冲刷），\n"
                 "    // 核在这个参数下也不会读它们 —— 一律接常 0，不凭空补 golden 没有的输入。\n"
                 "    .flush_redirect_valid (1'b0),\n"
                 "    .flush_redirect_level (1'b0),\n"
                 "    .flush_redirect_robidx(9'b0),\n"
                 "    .flush_ldcancel       (1'b0),\n"
                 "    .flush_ogfail         (1'b0),\n" % st)

    def tie(port, have, sig, why):
        if have:
            return "    .%s(%s),\n" % (port, sig)
        return "    // golden 无 %s 端口：%s\n    .%s(1'b0),\n" % (sig, why, port)

    ctrl = (tie("clock", st > 0, "clock", "STAGES=0，没有寄存器就没有时钟域")
            + tie("reset", st > 0, "reset", "STAGES=0，没有可复位的东西"))

    lay = ("//   载荷布局（薄文件按这个顺序拼包，核按这个顺序拆）：\n"
           "//     高位 -> 低位 = %s\n" % " | ".join(
               (["普通字段 %d 个 = %d 位" % (len(plain),
                                        sum(w for x, w in f["fields"] if x in plain))]
                if plain else [])
               + (["robIdx{flag,value} 9 位"] if has_rob else [])
               + (["loadDependency %d 路 × %d 位（j=0 在最低位）" % (len(ld), f["ld_w"])]
                  if ld else [])))

    return """// =============================================================================
// %(name)s —— 带冲刷的 %(st)d 级发射流水（xs_PipeWithFlush_core 家族的一个变体）
//
// 本变体的参数与规模（按 G1 golden 现读）：
//   载荷 WIDTH = %(pay)d 位，分 %(nf)d 个字段；流水级数 STAGES = %(st)d；
//   golden 模块体 = %(rb)d 个 reg 位 = %(st)d 级 × (1 个 valid + %(pay)d 位载荷)，无子模块；
//   端口 %(np)d 个。
%(lay)s//   使用者：%(use)s。
//
// 家族形状：%(shape)s
//
// 结构：golden 同名端口表 -> 按核的约定拼成一根 %(pay)d 位扁平载荷 -> 设参例化
//   xs_PipeWithFlush_core（冲刷判据、环形 robIdx 比较、loadDependency 老化都在
//   xs_PipeWithFlush_core.sv 里讲）-> 拆包回 golden 的 io_deq_bits_* 端口。
//   本层只做拼包/拆包与 flush 端口改名。
//   PAYLOAD_W 与 GOLDEN_REG_BITS 是两条**各自独立**从 golden 抽出来的事实
//   （前者来自端口表求和，后者来自 reg 声明），核里的
//   STAGES*(1+PAYLOAD_W) == GOLDEN_REG_BITS 把两者对上；
//   PORT_BITS_IN/OUT 再用 $bits(golden 端口拼接) 把端口表本身对一遍。
//   任何一处抄错，time 0 直接 $fatal。
// 自动生成：verif/ut/PipeWithFlush/gen.py（读 G1 golden）—— 勿手改
// =============================================================================

module %(name)s(
%(head)s

  localparam int unsigned STAGES          = %(st)d;   // 流水级数 N
  localparam int unsigned PAYLOAD_W       = %(pay)d;  // golden 端口表求和
  localparam int unsigned GOLDEN_REG_BITS = %(rb)d;   // golden reg 声明求和（含 valid 链）
  localparam int unsigned HAS_ROBIDX      = %(rob)d;   // 载荷里有没有 robIdx
  localparam int unsigned LD_CNT          = %(ldc)d;   // loadDependency 路数
  localparam int unsigned LD_W            = %(ldw)d;   // 每路位宽

  // 端口表事实：$bits 只认端口声明，抄错位宽这些常量立刻跟着变
  localparam int unsigned PORT_BITS_IN = $bits(
%(inbits)s);
  localparam int unsigned PORT_BITS_OUT = $bits(
%(outbits)s);

  logic [PAYLOAD_W-1:0] payload_in;
  logic [PAYLOAD_W-1:0] payload_out;

  assign payload_in =
%(pack)s

  xs_PipeWithFlush_core #(
    .WIDTH          (PAYLOAD_W),
    .STAGES         (STAGES),
    .HAS_ROBIDX     (HAS_ROBIDX),
    .LD_CNT         (LD_CNT),
    .LD_W           (LD_W),
    .GOLDEN_REG_BITS(GOLDEN_REG_BITS),
    .PORT_BITS_IN   (PORT_BITS_IN),
    .PORT_BITS_OUT  (PORT_BITS_OUT)
  ) u_core (
%(ctrl)s%(flush)s    .enq_valid(io_enq_valid),
    .enq_bits (payload_in),
    .deq_valid(io_deq_valid),
    .deq_bits (payload_out)
  );

  assign
%(unpack)s

endmodule
""" % dict(name=name, st=st, pay=f["payload"], rb=f["reg_bits"], nf=len(f["fields"]),
           np=len(f["ports"]), use=USE[name], shape=shape, lay=lay,
           rob=1 if has_rob else 0, ldc=len(ld), ldw=f["ld_w"] if ld else 2,
           head=f["head_text"].split(chr(10), 1)[1],
           inbits=wrap(ins, "    "), outbits=wrap(outs, "    "),
           pack=wrap(ins, "    ", ";"), unpack=wrap(outs, "    ", " = payload_out;"),
           ctrl=ctrl, flush=flush)


def slices(names_widths):
    tot = sum(w for _n, w in names_widths)
    out, hi = [], tot - 1
    for n, w in names_widths:
        lo = hi - w + 1
        out.append((n, hi, lo, w))
        hi = lo - 1
    assert hi == -1
    return out


TB_HEAD = """// 自动生成：verif/ut/PipeWithFlush/gen.py（读 G1 golden）—— 勿手改
// PipeWithFlush 家族 %(nv)d 变体双例化逐拍比对：golden <V> vs 可读重写 <V>_xs
//   （同一个 xs_PipeWithFlush_core 设不同 STAGES / 载荷 / 冲刷特性）。
// 被测语义：N 级 valid + bits 流水；第 2 级起可被 redirect / ldCancel / ogFail 冲掉；
//   loadDependency 每前移一级左移一位（老化）。
// 家族四种形状都在场（缺一种这个 tb 就证不到那一档）：
//   STAGES=0 直通（无 clock/reset/flush）：%(s0)s
//   STAGES=1 无冲刷：%(s1)s
//   STAGES>=2 有冲刷：%(sf)s
//   带 loadDependency 老化 + ldCancel：%(sl)s
//
// ★热身窗口 WARMUP 不是为了绕过失配，是「无复位数据链」的定义域★
//   golden 的 bits_k_* 与重写侧 u_core.g_pipe.bits_q[] 是**不同的寄存器**：
//   +vcs+initreg+random 给它们各自独立的随机初值，链灌满之前输出的是这些初值，
//   本来就不该相等（$isunknown 拦不住 —— 随机初值不是 X）。
//   而数据级是**使能门控**的（第 k 级要等 valids[k-1] 拉高才更新），光"前几拍不比"
//   还不够。做法是**确定性灌注**：窗口内把 io_enq_valid 强制拉 1、所有 flush 输入
//   强制拉 0，连续 STAGES 拍后每级都装着 tb 驱动的数据（两侧逐级同源，归纳可证
//   相等），窗口一过立刻开始逐拍比，此后**一拍都不豁免**。
//   WARMUP = 家族最大级数 + 1 = %(warmup)d 拍。
//
// 激励：io_enq_valid 50%%；载荷逐位随机并混入全 0 / 全 1；
//   robIdx 一半落在窄区间（0..7）好让重定向比较真的命中，一半全随机；
//   redirect_valid 1/8、level 1/2、ogFail 1/16、ldCancel 1/8；
//   reset 偶尔异步脉冲一拍。
// 覆盖闸：每个变体都要 (1) 比对次数 >= COV_MIN；(2) deq_valid 的 0 / 1 各 >= COV_MIN；
//   (3) 载荷每一位都见过 1 和 0 —— **但 loadDependency 老化会把每路最低位恒填 0**，
//       所以这些位单列成第 (3b) 条：它们必须**从未**出现过 1。把"测不到 1"从
//       豁免改写成断言：老化少移一位、或者第 1 级误加了老化，这条立刻红。
//   有冲刷的变体另外要 (4) redirect_valid=1 >= COV_MIN；(5) 每根 ogFail=1 >= COV_MIN；
//   (6) **被冲掉的条目数 >= COV_MIN** —— 入队 valid 数减出队 valid 数，
//       这是"冲刷真的发生过"的见证，不是"按构造应该会冲"；
//   带 ldCancel 的变体再要 (7) 每路 ldCancel=1 >= COV_MIN。
`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 200000;
  localparam int COV_MIN = 1000;
  localparam int WARMUP  = %(warmup)d;   // 确定性灌注窗口，见文件头
  int cycle = 0;
  bit clock = 0;
  logic reset;
  int errors = 0, checks = 0, cov_fail = 0;
  always #5 clock = ~clock;
"""


def gen_tb():
    L, infos = [], []
    for i, name in enumerate(VARIANTS):
        f = facts(name)
        s = "p%d" % i
        st, ld = f["stages"], f["ld_fields"]
        has_rob, plain, _ld, order = layout(f)
        widths = dict(f["fields"])
        fw = [(x, widths[x]) for x in order]
        pw = f["payload"]
        infos.append((name, s, f, fw))
        L.append("  // ---- %s: STAGES=%d 载荷 %d 位 / %d 字段%s ----"
                 % (name, st, pw, len(fw),
                    " / ldCancel %d 路" % len(ld) if ld else ""))
        L.append("  logic %s_enq_valid;" % s)
        L.append("  logic [%d:0] %s_enq;" % (pw - 1, s))
        L.append("  wire  [%d:0] g_%s_deq, i_%s_deq;" % (pw - 1, s, s))
        L.append("  wire  g_%s_dv, i_%s_dv;" % (s, s))
        L.append("  logic [%d:0] %s_ones, %s_zeros;" % (pw - 1, s, s))
        L.append("  int   %s_checks, %s_dv1, %s_dv0, %s_enq1;" % (s, s, s, s))
        if st >= 2:
            L.append("  int   %s_red;" % s)
            L.append("  int   %s_og [%d];" % (s, st - 1))
        if ld:
            L.append("  int   %s_ldc [%d];" % (s, len(ld)))
        for tag, mod in (("g", name), ("i", name + "_xs")):
            conn = []
            if st > 0:
                conn.append("    .clock(clock)")
                conn.append("    .reset(reset)")
            if st >= 2:
                conn.append("    .io_flush_redirect_valid(fl_red_valid)")
                conn.append("    .io_flush_redirect_bits_robIdx_flag(fl_red_flag)")
                conn.append("    .io_flush_redirect_bits_robIdx_value(fl_red_value)")
                conn.append("    .io_flush_redirect_bits_level(fl_red_level)")
                for j in range(len(ld)):
                    conn.append("    .io_flush_ldCancel_%d_ld2Cancel(fl_ldc[%d])" % (j, j))
                for k in range(st - 1):
                    conn.append("    .io_flush_og%dFail(fl_og[%d])" % (k, k))
            conn.append("    .io_enq_valid(%s_enq_valid)" % s)
            for nm, hi, lo, w in slices(fw):
                conn.append("    .io_enq_bits%s(%s_enq[%d:%d])" % (nm, s, hi, lo) if w > 1
                            else "    .io_enq_bits%s(%s_enq[%d])" % (nm, s, hi))
            conn.append("    .io_deq_valid(%s_%s_dv)" % (tag, s))
            for nm, hi, lo, w in slices(fw):
                conn.append("    .io_deq_bits%s(%s_%s_deq[%d:%d])" % (nm, tag, s, hi, lo)
                            if w > 1 else
                            "    .io_deq_bits%s(%s_%s_deq[%d])" % (nm, tag, s, hi))
            L.append("  %s u_%s_%s (" % (mod, tag, s))
            L.append(",\n".join(conn))
            L.append("  );")
        L.append("")

    maxst = max(f["stages"] for _n, _s, f, _w in infos)
    maxld = max([len(f["ld_fields"]) for _n, _s, f, _w in infos] + [1])
    shared = ["  // ---- 冲刷激励（所有带冲刷的变体共用同一组，便于对照）----",
              "  logic fl_red_valid, fl_red_flag, fl_red_level;",
              "  logic [7:0] fl_red_value;",
              "  logic fl_ldc [%d];" % maxld,
              "  logic fl_og [%d];" % max(maxst - 1, 1),
              ""]
    L = shared + L

    drive, check, init, cov = [], [], [], []
    # 共用冲刷激励：热身窗口内一律 0（否则 valid 链灌不满）
    drive.append("""    // 热身窗口内不冲刷：冲刷会打断 valid 链，数据级就灌不满（见文件头）
    if (cycle < WARMUP) begin
      fl_red_valid = 1'b0; fl_red_level = 1'b0;
      fl_red_flag  = 1'b0; fl_red_value = '0;
      for (int j = 0; j < %(maxld)d; j++) fl_ldc[j] = 1'b0;
      for (int k = 0; k < %(maxog)d; k++) fl_og[k]  = 1'b0;
    end else begin
      fl_red_valid = ($urandom_range(0, 7) == 0);            // 1/8
      fl_red_level = ($urandom_range(0, 1) == 1);
      fl_red_flag  = 1'($urandom);
      // 一半落在窄区间：robIdx 比较要真的命中，靠全随机 8 位撞不上
      fl_red_value = ($urandom_range(0, 1) == 1) ? 8'($urandom_range(0, 7))
                                                 : 8'($urandom);
      for (int j = 0; j < %(maxld)d; j++) fl_ldc[j] = ($urandom_range(0, 7) == 0);
      for (int k = 0; k < %(maxog)d; k++) fl_og[k]  = ($urandom_range(0, 15) == 0);
    end""" % dict(maxld=maxld, maxog=max(maxst - 1, 1)))

    for name, s, f, fw in infos:
        st, ld = f["stages"], f["ld_fields"]
        has_rob, _plain, _l, _o = layout(f)
        pw = f["payload"]
        # robIdx 在载荷里的位置（核的约定：紧挨 loadDependency 块之上）
        rob_lsb = len(ld) * f["ld_w"]
        robdrv = ""
        if has_rob:
            robdrv = ("""
    // robIdx 一半落在窄区间，好让重定向比较真的命中
    if ($urandom_range(0, 1) == 1)
      %(s)s_enq[%(lsb)d +: 9] = {1'($urandom), 8'($urandom_range(0, 7))};"""
                      % dict(s=s, lsb=rob_lsb))
        drive.append("""    %(s)s_enq_valid = (cycle < WARMUP) ? 1'b1 : ($urandom_range(0, 1) == 1);
    case ($urandom_range(0, 7))
      0:       %(s)s_enq = '0;
      1:       %(s)s_enq = '1;
      default: for (int b = 0; b < %(pw)d; b++) %(s)s_enq[b] = 1'($urandom);
    endcase%(rob)s""" % dict(s=s, pw=pw, rob=robdrv))

        extra = ""
        if st >= 2:
            extra += ("\n      if (fl_red_valid) %s_red++;"
                      "\n      for (int k = 0; k < %d; k++) if (fl_og[k]) %s_og[k]++;"
                      % (s, st - 1, s))
        if ld:
            extra += ("\n      for (int j = 0; j < %d; j++) if (fl_ldc[j]) %s_ldc[j]++;"
                      % (len(ld), s))
        check.append("""    if (!$isunknown({g_%(s)s_dv, g_%(s)s_deq})) begin
      checks++; %(s)s_checks++;
      %(s)s_ones  |= g_%(s)s_deq;
      %(s)s_zeros |= ~g_%(s)s_deq;
      if (g_%(s)s_dv) %(s)s_dv1++; else %(s)s_dv0++;
      if (%(s)s_enq_valid) %(s)s_enq1++;%(extra)s
      if ({g_%(s)s_dv, g_%(s)s_deq} !== {i_%(s)s_dv, i_%(s)s_deq}) begin
        errors++;
        if (errors <= 20)
          $display("[%%0t] MISMATCH %(n)s g=%%b/%%0h i=%%b/%%0h",
                   $time, g_%(s)s_dv, g_%(s)s_deq, i_%(s)s_dv, i_%(s)s_deq);
      end
    end""" % dict(s=s, n=name, extra=extra))

        ini = ("    %s_enq_valid = 0; %s_enq = '0; %s_ones = '0; %s_zeros = '0;\n"
               "    %s_checks = 0; %s_dv1 = 0; %s_dv0 = 0; %s_enq1 = 0;"
               % (s, s, s, s, s, s, s, s))
        if st >= 2:
            ini += ("\n    %s_red = 0; for (int k = 0; k < %d; k++) %s_og[k] = 0;"
                    % (s, st - 1, s))
        if ld:
            ini += "\n    for (int j = 0; j < %d; j++) %s_ldc[j] = 0;" % (len(ld), s)
        init.append(ini)

        # ★结构性恒零位★：loadDependency 老化 `{v[LD_W-2:0], 1'b0}` 把每路最低位
        # 填 0，而输出取的是最后一级，所以 STAGES>=2 时这些位在输出上恒为 0。
        # 不是覆盖不到，是**必须**为 0 —— 单列成一条正向断言。
        zmask = 0
        for j in range(len(ld)):
            zmask |= 1 << (j * f["ld_w"])
        zlit = "%d'h%X" % (pw, zmask)
        c = """    $display("  %(n)s: checks=%%0d deq1=%%0d deq0=%%0d enq1=%%0d dropped=%%0d ones=%%0d/%(pw)d zeros=%%0d/%(pw)d",
             %(s)s_checks, %(s)s_dv1, %(s)s_dv0, %(s)s_enq1, %(s)s_enq1 - %(s)s_dv1,
             $countones(%(s)s_ones), $countones(%(s)s_zeros));
    cov_fail += cov_short("%(n)s checks", %(s)s_checks)
              + cov_short("%(n)s deq_valid=1", %(s)s_dv1)
              + cov_short("%(n)s deq_valid=0", %(s)s_dv0);
    // 恒零位（loadDependency 老化填进来的 0）单独处理，见下
    if (((%(s)s_ones | %(zlit)s) !== '1) || (%(s)s_zeros !== '1)) begin
      $display("COVERAGE FAIL: %(n)s 有载荷位从未在输出上观察到 1 或 0 (ones=%%0h zeros=%%0h)",
               %(s)s_ones, %(s)s_zeros); cov_fail++;
    end""" % dict(n=name, s=s, pw=pw, zlit=zlit)
        if zmask:
            c += """
    // ★正向断言，不是豁免★：loadDependency 每路最低位是老化左移填进来的 0，
    // 在输出上必须**从未**出现过 1。老化少移一位、或第 1 级误加了老化，这里立刻红。
    if ((%(s)s_ones & %(zlit)s) != '0) begin
      $display("STRUCTURAL FAIL: %(n)s loadDependency 老化位竟然出现过 1 (ones=%%0h & mask=%(zlit)s)",
               %(s)s_ones); cov_fail++;
    end else
      $display("  %(n)s: loadDependency 老化恒零位 %(zlit)s 全程未出现 1（老化左移坐实）");""" % dict(n=name, s=s, zlit=zlit)
        if st >= 2:
            c += ("""
    cov_fail += cov_short("%(n)s redirect_valid=1", %(s)s_red)
              + cov_short("%(n)s 被冲掉的条目(enq1-deq1)", %(s)s_enq1 - %(s)s_dv1);
    for (int k = 0; k < %(nog)d; k++)
      cov_fail += cov_short($sformatf("%(n)s og%%0dFail=1", k), %(s)s_og[k]);"""
                  % dict(n=name, s=s, nog=st - 1))
        if ld:
            c += ("""
    for (int j = 0; j < %(nld)d; j++)
      cov_fail += cov_short($sformatf("%(n)s ldCancel_%%0d=1", j), %(s)s_ldc[j]);"""
                  % dict(n=name, s=s, nld=len(ld)))
        cov.append(c)

    nl = "\n"
    L = [TB_HEAD % dict(
        nv=len(VARIANTS), warmup=maxst + 1,
        s0=" ".join(n for n, _s, f, _w in infos if f["stages"] == 0),
        s1=" ".join(n for n, _s, f, _w in infos if f["stages"] == 1),
        sf=" ".join(n for n, _s, f, _w in infos if f["stages"] >= 2),
        sl=" ".join(n for n, _s, f, _w in infos if f["ld_fields"]))] + L
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
    reset = 1'b1;
    fl_red_valid = 0; fl_red_level = 0; fl_red_flag = 0; fl_red_value = '0;
    for (int j = 0; j < %(maxld)d; j++) fl_ldc[j] = 0;
    for (int k = 0; k < %(maxog)d; k++) fl_og[k] = 0;
%(init)s
    repeat (4) @(negedge clock);
    reset = 1'b0;
    repeat (NCYCLES) begin
      @(negedge clock);
      // 热身窗口内两侧无复位数据寄存器各自带着独立随机初值，不可比（见文件头）
      if (cycle >= WARMUP) check_outputs();   // 输出在 posedge 变，negedge 稳定
      drive_random_inputs();
      @(posedge clock);
      cycle++;
      // 复位脉冲只清 valid 链（数据级 golden 就没有复位），热身窗口内不打
      if (cycle >= WARMUP && $urandom_range(0, 4999) == 0) begin
        reset = 1'b1;
        #1 reset = 1'b0;
      end
    end
    $display("PipeWithFlush family checks=%%0d errors=%%0d", checks, errors);
%(cov)s
    if (errors == 0 && cov_fail == 0) begin
      $display("TEST PASSED");
      $finish;
    end
    $display("TEST FAILED (errors=%%0d cov_fail=%%0d)", errors, cov_fail);
    $fatal(1);
  end
endmodule
""" % dict(drive=nl.join(drive), check=nl.join(check), init=nl.join(init),
           cov=nl.join(cov), maxld=maxld, maxog=max(maxst - 1, 1)))
    open(os.path.join(HERE, "tb.sv"), "w").write("\n".join(L))
    print("wrote tb.sv (%d variants)" % len(VARIANTS))


if __name__ == "__main__":
    for n in VARIANTS:
        open(os.path.join(RTL, n + ".sv"), "w").write(gen_variant(n))
        print("wrote", os.path.join(RTL, n + ".sv"))
    gen_tb()
