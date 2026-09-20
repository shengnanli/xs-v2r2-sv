#!/usr/bin/env python3
"""生成 DelayNWithValid 家族 16 个变体的薄文件（rtl/common/）与家族 tb。

事实来源是 gen_facts.facts()：它不只数位宽，还会**把整个 golden 模块体由家族公式
重建出来逐字比对**（16/16 一致）。所以这里写下的每一个参数都不是抄的，是算的。

★薄文件里的参数一律来自 facts()，不许手写★
2026-09-20 的事故：核把参数 GOLDEN_DATA_REG_BITS 改名成 GOLDEN_REG_BITS，两个
手维护的薄文件没跟着改。VCS 对「覆盖一个不存在的参数」只给一条
`Warning-[AOUP] ... will be ignored`，于是新参数取默认值 —— 而默认值恰好是核自己
算出来的值，核里那条守恒等式变成恒真，「位宽/级数抄错就 time 0 $fatal」这道
elaborate 期不变式被静默解除武装。UT 绿、FM 绿、六道闸一条没响。
现在由 scripts/check_param_override.py 把守；而薄文件全部由本脚本生成，
参数名和参数值都只有一个来源。

## 家族的四种形状（都从 golden 端口表数出来，不是从名字猜）

  STAGES=0            退化成一根直通线：golden 连 clock / reset / io_in_valid 都没有
                      —— _4 _7
  STAGES>=1, V=0      有 clock 和 io_in_valid，但 valid 链被 firtool 消光，没有 reset
                      —— _52 _55 _103 _152 _155
  V = STAGES-1        有 reset，但没有 io_out_valid（valid 链最后一级没人读）
                      —— 本体 _1 _148 _149
  V = STAGES          有 io_out_valid，整条 valid 链都被读
                      —— _2 _3 _200 _202 _203
"""
import os, sys

G = os.environ.get("GOLDEN_RTL", "/home/eda/xs-env/G1-canonical/golden-rtl")
HERE = os.path.dirname(os.path.abspath(__file__))
RTL = os.path.abspath(os.path.join(HERE, "../../../rtl/common"))
sys.path.insert(0, HERE)
from gen_facts import facts     # noqa: E402  （含「模块体由公式重建并逐字比对」）

# 使用者与载荷含义：例化处由 grep golden 得到（`grep -lE "^  <变体> " golden-rtl/*.sv`），
# 载荷含义由 golden 的字段名读出。两者都不是猜的。
USE = {
    "DelayNWithValid":     "FTB —— 预测目标地址沿预测流水打两拍",
    "DelayNWithValid_1":   "FTB —— FTBEntry（分支槽 / 尾槽 / 预取地址 / strong_bias）打两拍",
    "DelayNWithValid_2":   "MemBlock —— 访存物理地址 + report_to_beu 打两拍，带 out_valid",
    "DelayNWithValid_3":   "MemBlock —— 48 位物理地址打两拍，带 out_valid",
    "DelayNWithValid_4":   "LqPAddrModule —— n=0 直通（Chisel 要了 0 级延迟，firtool 连线消成一根）",
    "DelayNWithValid_7":   "LqPAddrModule —— n=0 直通",
    "DelayNWithValid_52":  "LqPAddrModule_1 / LqMaskModule —— 4 位写掩码/索引打一拍",
    "DelayNWithValid_55":  "LqPAddrModule_1 —— 24 位地址高位打一拍",
    "DelayNWithValid_103": "LqMaskModule —— 16 位字节掩码打一拍",
    "DelayNWithValid_148": "LoadQueueRAW —— {flag,value} 队列指针打三拍",
    "DelayNWithValid_149": "LoadQueueRAW —— 4 位索引打三拍",
    "DelayNWithValid_152": "LqVAddrModule —— 9 位虚地址片段打一拍",
    "DelayNWithValid_155": "LqVAddrModule —— 50 位虚地址打一拍",
    "DelayNWithValid_200": "MemBlock —— {addr,source} 打两拍，带 out_valid",
    "DelayNWithValid_202": "MemBlock —— 12 位打一拍，带 out_valid（valid 链留 1 级）",
    "DelayNWithValid_203": "L2Top / MemBlock —— 64 位打一拍，带 out_valid",
}
VARIANTS = list(USE)


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


def shape_note(f):
    """本变体属于家族四种形状里的哪一种，以及 golden 为什么长这样。"""
    if f["stages"] == 0:
        return ("STAGES=0：退化成一根直通线。golden 连 clock / reset / io_in_valid\n"
                "//   三个端口都没有 —— 没有寄存器就没有时钟域，Chisel 那边要的是 0 级延迟。")
    if f["valid_chain"] == 0:
        return ("STAGES=%d 且 valid 链长 0：golden 有 clock 和 io_in_valid，**没有 reset**。\n"
                "//   valid 链唯一的那一级只有 io_out_valid 会读，而本变体没有这个端口，\n"
                "//   于是整条链被 firtool 消光，连带 reset 端口一起消失。" % f["stages"])
    if f["has_out_valid"]:
        return ("V = STAGES = %d：golden **有** io_out_valid，整条 valid 链都被读到，\n"
                "//   一级都没被消，所以 reset 端口在。" % f["stages"])
    return ("V = STAGES-1 = %d：golden **没有** io_out_valid，valid 链最后一级没人读、\n"
            "//   被 firtool 消掉；剩下的 %d 级还要给数据级当使能，所以留着。"
            % (f["valid_chain"], f["valid_chain"]))


def gen_variant(name):
    f = facts(name)
    ins = [p["name"] for p in f["ins"]]
    outs = [p["name"] for p in f["outs"]]
    fld = ", ".join('%s=%db' % (p["name"][len("io_in_bits_"):] or "io_in_bits", p["w"])
                    for p in f["ins"][:5])
    more = "" if len(ins) <= 5 else " …共 %d 个字段，明细见端口表" % len(ins)

    # 核的三个控制输入：golden 没有对应端口时接常 0。核在这些参数下不会读它们
    # （STAGES=0 不生成任何寄存器；VALID_CHAIN=0 不生成 valid 链），
    # 接 0 是「照抄 golden 的端口表」，不是凭空补一个 golden 没有的输入。
    def tie(port, have, sig, why):
        """golden 有这个端口就接过去；没有就接常 0，并在**连接行之前**写明原因。
        （注释不能写在 `(...)` 里 —— `//` 会把闭括号一起吃掉，VCS 当场报语法错。）"""
        if have:
            return "    .%s(%s),\n" % (port, sig)
        return "    // golden 无 %s 端口：%s\n    .%s(1'b0),\n" % (sig, why, port)

    ctrl = (tie("clock   ", f["has_clock"], "clock", "STAGES=0，没有寄存器就没有时钟域")
            + tie("reset   ", f["has_reset"], "reset", "valid 链长 0，没有可复位的东西")
            + tie("in_valid", f["stages"] > 0, "io_in_valid", "STAGES=0，没有使能可言"))
    if f["has_out_valid"]:
        ov = "    .out_valid(io_out_valid)\n"
    else:
        ov = ("    // 本变体的 golden 没有 io_out_valid 端口，核的 out_valid 悬空 ——\n"
              "    // 照抄 golden 的端口表，不凭空补一个 golden 没有的输出。\n"
              "    .out_valid()\n")

    if f["stages"] == 0:
        regline = ("//   golden 模块体 = 0 个 reg（纯连线），无子模块；\n")
    else:
        regline = ("//   golden 模块体 = %d 个 reg 位 = %d 个 valid 位（异步复位）\n"
                   "//     + %d 级 × %d 位数据（无复位），无子模块；\n"
                   % (f["reg_bits"], f["valid_chain"], f["stages"], f["payload"]))

    nout = len(outs) + (1 if f["has_out_valid"] else 0)
    return """// =============================================================================
// %(name)s —— 带 valid 使能的 %(st)d 级打拍链（xs_DelayNWithValid_core 家族的一个变体）
//
// 本变体的参数与规模（按 G1 golden 现读，不从上一轮继承）：
//   载荷 WIDTH = %(pay)d 位，分 %(nin)d 个字段；数据级数 STAGES = %(st)d；
//   valid 链保留 %(vc)d 个寄存器；
%(regline)s//   端口 %(nports)d 个 = %(portsum)s。
//   载荷字段：%(fld)s%(more)s。
//   使用者：%(use)s。
//
// 家族形状：%(shape)s
//
// 结构：golden 同名端口表 -> 打包成一根 %(pay)d 位扁平载荷 -> 设参例化
//   xs_DelayNWithValid_core（使能与复位语义、不变式都在 xs_DelayNWithValid_core.sv
//   里讲）-> 拆包回 golden 的 io_out_bits_* 端口。本层只做拼包/拆包。
//   PAYLOAD_W / GOLDEN_REG_BITS 是两条**各自独立**从 golden 抽出来的事实
//   （前者来自端口表求和，后者来自 reg 声明），核里的守恒等式
//   VALID_CHAIN + STAGES*PAYLOAD_W == GOLDEN_REG_BITS 把两者对上；
//   PORT_BITS_IN/OUT 再用 $bits(golden 端口拼接) 把端口表本身对一遍。
//   任何一处抄错，time 0 直接 $fatal。
// 自动生成：verif/ut/DelayNWithValid/gen.py（读 G1 golden）—— 勿手改
// =============================================================================

module %(name)s(
%(head)s

  localparam int unsigned STAGES          = %(st)d;   // 数据级数 n
  localparam int unsigned VALID_CHAIN     = %(vc)d;   // 保留下来的 valid 寄存器个数
  localparam int unsigned PAYLOAD_W       = %(pay)d;  // golden 端口表求和
  localparam int unsigned GOLDEN_REG_BITS = %(rb)d;   // golden reg 声明求和（含 valid 链）

  // 端口表事实：$bits 只认端口声明，抄错位宽这些常量立刻跟着变
  localparam int unsigned PORT_BITS_IN = $bits(
%(inbits)s);
  localparam int unsigned PORT_BITS_OUT = $bits(
%(outbits)s);

  logic [PAYLOAD_W-1:0] payload_in;
  logic [PAYLOAD_W-1:0] payload_out;

  assign payload_in =
%(pack)s

  xs_DelayNWithValid_core #(
    .WIDTH          (PAYLOAD_W),
    .STAGES         (STAGES),
    .VALID_CHAIN    (VALID_CHAIN),
    .GOLDEN_REG_BITS(GOLDEN_REG_BITS),
    .PORT_BITS_IN   (PORT_BITS_IN),
    .PORT_BITS_OUT  (PORT_BITS_OUT)
  ) u_core (
%(ctrl)s    .d_in    (payload_in),
    .d_out   (payload_out),
%(ov)s  );

  assign
%(unpack)s

endmodule
""" % dict(
        name=name, st=f["stages"], vc=f["valid_chain"], pay=f["payload"], rb=f["reg_bits"],
        nin=len(ins), nports=len(f["ports"]),
        portsum="%s%d 入 + %d 出" % (
            "".join(x + " + " for x in
                    (["clock"] if f["has_clock"] else []) +
                    (["reset"] if f["has_reset"] else []) +
                    (["io_in_valid"] if f["stages"] > 0 else [])),
            len(ins), nout),
        regline=regline, fld=fld, more=more, use=USE[name], shape=shape_note(f),
        head=f["head_text"].split(chr(10), 1)[1],
        inbits=wrap(ins, "    "), outbits=wrap(outs, "    "),
        pack=wrap(ins, "    ", ";"), unpack=wrap(outs, "    ", " = payload_out;"),
        ctrl=ctrl, ov=ov)


def slices(ports):
    tot = sum(p["w"] for p in ports)
    out, hi = [], tot - 1
    for p in ports:
        lo = hi - p["w"] + 1
        out.append((p["name"], hi, lo, p["w"]))
        hi = lo - 1
    assert hi == -1
    return out


TB_HEAD = """// 自动生成：verif/ut/DelayNWithValid/gen.py（读 G1 golden）—— 勿手改
// DelayNWithValid 家族 %(nv)d 变体双例化逐拍比对：golden <V> vs 可读重写 <V>_xs
//   （同一个 xs_DelayNWithValid_core 设不同 WIDTH / STAGES / VALID_CHAIN）。
// 被测语义：valid 打一拍 + n 级"只在使能时更新"的数据寄存器；输入无效时输出保持。
// 家族四种形状都在场（缺一种这个 tb 就证不到那一档）：
//   STAGES=0 直通（无 clock/reset/in_valid）：%(s0)s
//   valid 链长 0（无 reset）：%(v0)s
//   有 out_valid（整条 valid 链被读）：%(ov)s
//   其余为 V=STAGES-1。
// 只有 valid 寄存器带异步复位，数据寄存器无复位，故用 $isunknown(golden 输出)
//   跳过尚未灌满的拍。
// ★热身窗口 WARMUP 不是为了绕过失配，是「无复位数据链」的定义域★
//   golden 的 data/res_bits 与重写侧 u_core.g_chain.data_q[] 是**不同的寄存器**：
//   +vcs+initreg+random 给它们各自独立的随机初值，链灌满之前输出的是这些初值，
//   本来就不该相等（$isunknown 拦不住 —— 随机初值不是 X）。
//   而本家族的数据级是**使能门控**的（第 k 级要等 in_valid 延迟 k 拍才更新），
//   所以光"前几拍不比"还不够 —— 那几拍里使能可能压根没拉高过，链还是空的。
//   做法是**确定性灌注**：热身窗口内把所有变体的 io_in_valid 强制拉 1，
//   连续 STAGES 拍之后每一级都装着 tb 驱动的数据（两侧逐级同源，归纳可证相等），
//   窗口一过立刻开始逐拍比，此后**一拍都不豁免**。
//   WARMUP = 家族最大级数 + 1 = %(warmup)d 拍（20 万拍里扣 %(warmup)d 拍，覆盖闸不受影响）。
// 激励：io_in_valid 按 50%% 随机（既有连续有效也有长时间无效，才测得到"保持"），
//   载荷逐位随机并混入全 0 / 全 1；reset 偶尔异步脉冲一拍。
// 覆盖闸：每个变体都要 (1) 有效比对 >= COV_MIN；(2) in_valid=1 与 in_valid=0
//   各 >= COV_MIN；(3) 输出**保持不变**（相邻拍相等）与**发生变化**各 >= COV_MIN
//   —— 只测流动不测保持的 tb 会在这里被判 FAIL；(4) 每个载荷位都见过 1 和 0；
//   (5) 有 out_valid 的变体，out_valid 的 0 / 1 各 >= COV_MIN。
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
        s = "dv%d" % i
        pw = f["payload"]
        infos.append((name, s, f))
        L.append("  // ---- %s: 载荷 %d 位 / %d 字段 / STAGES=%d / V=%d%s ----"
                 % (name, pw, len(f["ins"]), f["stages"], f["valid_chain"],
                    " / 有 out_valid" if f["has_out_valid"] else ""))
        L.append("  logic %s_in_valid;" % s)
        L.append("  logic [%d:0] %s_in;" % (pw - 1, s))
        L.append("  wire  [%d:0] g_%s_out, i_%s_out;" % (pw - 1, s, s))
        if f["has_out_valid"]:
            L.append("  wire  g_%s_ov, i_%s_ov;" % (s, s))
            L.append("  int   %s_ov1, %s_ov0;" % (s, s))
        L.append("  logic [%d:0] %s_ones, %s_zeros, %s_prev;" % (pw - 1, s, s, s))
        L.append("  int   %s_checks, %s_vld, %s_idle, %s_hold, %s_move;" % (s, s, s, s, s))
        for tag, mod in (("g", name), ("i", name + "_xs")):
            conn = []
            if f["has_clock"]:
                conn.append("    .clock(clock)")
            if f["has_reset"]:
                conn.append("    .reset(reset)")
            if f["stages"] > 0:
                conn.append("    .io_in_valid(%s_in_valid)" % s)
            for nm, hi, lo, w in slices(f["ins"]):
                conn.append("    .%s(%s_in[%d:%d])" % (nm, s, hi, lo) if w > 1
                            else "    .%s(%s_in[%d])" % (nm, s, hi))
            for nm, hi, lo, w in slices(f["outs"]):
                conn.append("    .%s(%s_%s_out[%d:%d])" % (nm, tag, s, hi, lo) if w > 1
                            else "    .%s(%s_%s_out[%d])" % (nm, tag, s, hi))
            if f["has_out_valid"]:
                conn.append("    .io_out_valid(%s_%s_ov)" % (tag, s))
            L.append("  %s u_%s_%s (" % (mod, tag, s))
            L.append(",\n".join(conn))
            L.append("  );")
        L.append("")

    drive, check, init, cov = [], [], [], []
    for name, s, f in infos:
        pw = f["payload"]
        drive.append("""    %(s)s_in_valid = (cycle < WARMUP) ? 1'b1 : ($urandom_range(0, 1) == 1);
    case ($urandom_range(0, 7))
      0:       %(s)s_in = '0;
      1:       %(s)s_in = '1;
      default: for (int b = 0; b < %(pw)d; b++) %(s)s_in[b] = 1'($urandom);
    endcase""" % dict(s=s, pw=pw))
        ovchk = ""
        if f["has_out_valid"]:
            ovchk = """
      if (g_%(s)s_ov) %(s)s_ov1++; else %(s)s_ov0++;
      if (g_%(s)s_ov !== i_%(s)s_ov) begin
        errors++;
        if (errors <= 20)
          $display("[%%0t] MISMATCH %(n)s io_out_valid g=%%b i=%%b",
                   $time, g_%(s)s_ov, i_%(s)s_ov);
      end""" % dict(s=s, n=name)
        check.append("""    if (!$isunknown(g_%(s)s_out)) begin
      checks++; %(s)s_checks++;
      %(s)s_ones  |= g_%(s)s_out;
      %(s)s_zeros |= ~g_%(s)s_out;
      if (%(s)s_in_valid) %(s)s_vld++; else %(s)s_idle++;
      if (!$isunknown(%(s)s_prev)) begin
        if (%(s)s_prev === g_%(s)s_out) %(s)s_hold++; else %(s)s_move++;
      end
      %(s)s_prev = g_%(s)s_out;
      if (g_%(s)s_out !== i_%(s)s_out) begin
        errors++;
        if (errors <= 20)
          $display("[%%0t] MISMATCH %(n)s g=%%0h i=%%0h", $time, g_%(s)s_out, i_%(s)s_out);
      end%(ov)s
    end""" % dict(s=s, n=name, ov=ovchk))
        extra = (" %s_ov1 = 0; %s_ov0 = 0;" % (s, s)) if f["has_out_valid"] else ""
        init.append("    %s_in_valid = 0; %s_in = '0; %s_ones = '0; %s_zeros = '0;"
                    " %s_prev = 'x;\n"
                    "    %s_checks = 0; %s_vld = 0; %s_idle = 0; %s_hold = 0; %s_move = 0;%s"
                    % (s, s, s, s, s, s, s, s, s, s, extra))
        ovcov = ("""
    cov_fail += cov_short("%(n)s out_valid=1", %(s)s_ov1)
              + cov_short("%(n)s out_valid=0", %(s)s_ov0);""" % dict(n=name, s=s)
                 ) if f["has_out_valid"] else ""
        cov.append("""    $display("  %(n)s: checks=%%0d valid=%%0d idle=%%0d hold=%%0d move=%%0d ones=%%0d/%(pw)d zeros=%%0d/%(pw)d",
             %(s)s_checks, %(s)s_vld, %(s)s_idle, %(s)s_hold, %(s)s_move,
             $countones(%(s)s_ones), $countones(%(s)s_zeros));
    cov_fail += cov_short("%(n)s checks", %(s)s_checks)
              + cov_short("%(n)s valid",  %(s)s_vld)
              + cov_short("%(n)s idle",   %(s)s_idle)
              + cov_short("%(n)s hold",   %(s)s_hold)
              + cov_short("%(n)s move",   %(s)s_move);%(ovcov)s
    if (!(&%(s)s_ones) || !(&%(s)s_zeros)) begin
      $display("COVERAGE FAIL: %(n)s 有载荷位从未在输出上观察到 1 或 0"); cov_fail++;
    end""" % dict(n=name, s=s, pw=pw, ovcov=ovcov))

    nl = "\n"
    head = TB_HEAD % dict(
        nv=len(VARIANTS),
        warmup=max(f["stages"] for _n, _s, f in infos) + 1,
        s0=" ".join(n for n, _s, f in infos if f["stages"] == 0),
        v0=" ".join(n for n, _s, f in infos if f["stages"] > 0 and f["valid_chain"] == 0),
        ov=" ".join(n for n, _s, f in infos if f["has_out_valid"]))
    L = [head] + L
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
%(init)s
    repeat (4) @(negedge clock);
    reset = 1'b0;
    repeat (NCYCLES) begin
      @(negedge clock);
      // 热身窗口：两侧无复位数据寄存器各自带着独立随机初值，此时不可比；
      // 窗口内 drive 把 io_in_valid 强制拉 1 做确定性灌注（见文件头）。
      if (cycle >= WARMUP) check_outputs();   // 输出在 posedge 变，negedge 稳定
      drive_random_inputs();
      @(posedge clock);
      cycle++;
      // 复位脉冲只清 valid 链（数据级 golden 就没有复位），热身窗口内不打，
      // 免得把灌注拖慢。
      if (cycle >= WARMUP && $urandom_range(0, 4999) == 0) begin   // 异步复位脉冲
        reset = 1'b1;
        #1 reset = 1'b0;
      end
    end
    $display("DelayNWithValid family checks=%%0d errors=%%0d", checks, errors);
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
