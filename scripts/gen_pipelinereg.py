#!/usr/bin/env python3
"""gen_pipelinereg.py —— PipelineRegModule 家族（LoadQueueUncache 的四个出口流水寄存器）的机械派生区生成器。

家族（本 lane 只做 LoadQueueUncache 用到的三个变体；PipelineRegModule_6 属 MemBlock，不在此列）：
  PipelineRegModule    uncache 总线请求（10 字段 / 193 位）
  PipelineRegModule_1  MMIO load 写回    （182 字段 / 1428 位）
  PipelineRegModule_2  NC load 写回      （187 字段 / 1567 位）

生成对象（都是没有微架构的纯机械部分）：
  rtl/memblock/PipelineRegModule.sv      GENERATED(pipereg-wrapper) 区（核是手写的，不碰）
  rtl/memblock/PipelineRegModule_1.sv    整个文件（薄 wrapper）
  rtl/memblock/PipelineRegModule_2.sv    整个文件（薄 wrapper）
  verif/ut/PipelineRegModule/fm_pins_pre.tcl   FM 匹配前逐位钉点（按 $top 分支）
  verif/ut/PipelineRegModule/tb.sv             三变体双例化 UT

生成前对 golden 做三项机械核对（任何一项不符即失败，不生成）：
  (1) 端口形状：clock/reset/io_in_ready/io_in_valid/io_in_bits_*/io_out_ready/io_out_valid/io_out_bits_*，
      in 与 out 的 bits 字段表逐项同名同宽同序；
  (2) 寄存器表：恰好 pipeline_reg_valid + 每字段一个 io_out_bits_r_<f>（同宽），没有别的；
  (3) 语句：valid 的复位/次态表达式与 in_ready 表达式逐字等于家族共同形状，
      每个字段恰有 `io_out_bits_r_<f> <= io_in_bits_<f>;` 与 `assign io_out_bits_<f> = io_out_bits_r_<f>;`。
  (4) --check：生成结果与磁盘逐字节比较。

用法:
  scripts/gen_pipelinereg.py            # 写文件
  scripts/gen_pipelinereg.py --check    # 只比对，不写；有漂移 rc=1
"""
import argparse
import os
import re
import sys

GOLDEN_DIR = "/home/eda/xs-env/G1-canonical/golden-rtl"
HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.normpath(os.path.join(HERE, ".."))
RTL = os.path.join(REPO, "rtl", "memblock")
UT = os.path.join(REPO, "verif", "ut", "PipelineRegModule")

VARIANTS = [
    # (模块, 一句话用途)
    ("PipelineRegModule",   "LoadQueueUncache -> Uncache 总线请求出口（io.uncache.req）"),
    ("PipelineRegModule_1", "LoadQueueUncache -> load 流水线的 MMIO 写回出口（io.mmioOut(2)）"),
    ("PipelineRegModule_2", "LoadQueueUncache -> load 流水线的 NC 写回出口（io.ncOut(0..2)，三个实例）"),
]

# 家族共同形状（逐字取自 golden，空白归一化后比较）
VALID_NEXT = ("pipeline_reg_valid <= _io_out_bits_T | ~(io_out_ready & pipeline_reg_valid) "
              "& pipeline_reg_valid;")
IN_FIRE = "wire _io_out_bits_T = io_in_ready_0 & io_in_valid;"
IN_READY = "assign io_in_ready_0 = ~pipeline_reg_valid | io_out_ready;"


def die(msg):
    raise SystemExit("gen_pipelinereg: " + msg)


def golden_text(module):
    return open(os.path.join(GOLDEN_DIR, module + ".sv")).read()


def port_table(module):
    """golden 顶层端口表：[(dir, width, name, 原文行)]，顺序即 golden 顺序。"""
    lines = golden_text(module).split("\n")
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


def module_body(module):
    t = golden_text(module)
    s = t.index("module %s(" % module)
    e = t.index("endmodule", s)
    body = t[s:e]
    # 去掉 initial 随机化块（`ifdef ENABLE_INITIAL_REG_ ... `endif），它不是综合语义
    body = re.sub(r"`ifdef ENABLE_INITIAL_REG_.*?`endif // ENABLE_INITIAL_REG_", "", body, flags=re.S)
    return body


def norm(s):
    return re.sub(r"\s+", " ", s).strip()


def fields_of(module):
    """返回 [(字段名, 位宽)]，并完成 (1)(2)(3) 三项核对。"""
    ports = port_table(module)
    got = [(d, w, n) for d, w, n, _ in ports]
    fin = [(n[len("io_in_bits_"):], w) for d, w, n in got if n.startswith("io_in_bits_")]
    fout = [(n[len("io_out_bits_"):], w) for d, w, n in got if n.startswith("io_out_bits_")]
    if fin != fout:
        die("%s: io_in_bits_* 与 io_out_bits_* 字段表不一致" % module)
    exp = [("input", 1, "clock"), ("input", 1, "reset"),
           ("output", 1, "io_in_ready"), ("input", 1, "io_in_valid")]
    exp += [("input", w, "io_in_bits_" + f) for f, w in fin]
    exp += [("input", 1, "io_out_ready"), ("output", 1, "io_out_valid")]
    exp += [("output", w, "io_out_bits_" + f) for f, w in fin]
    if got != exp:
        die("%s: golden 端口表与家族形状不符（多/少/顺序不同）" % module)

    body = module_body(module)
    nb = norm(body)
    # (2) 寄存器表
    regs = re.findall(r"^\s*reg\s+(?:\[(\d+):(\d+)\]\s+)?(\w+);", body, re.M)
    regs = [(n, int(a) - int(b) + 1 if a else 1) for a, b, n in regs]
    exp_regs = [("pipeline_reg_valid", 1)] + [("io_out_bits_r_" + f, w) for f, w in fin]
    if sorted(regs) != sorted(exp_regs):
        die("%s: golden 寄存器表不是 pipeline_reg_valid + 每字段一个 io_out_bits_r_<f>" % module)
    # (3) 语句
    for frag in (VALID_NEXT, IN_FIRE, IN_READY, "if (reset) pipeline_reg_valid <= 1'h0;",
                 "always @(posedge clock or posedge reset)", "if (_io_out_bits_T) begin"):
        if norm(frag) not in nb:
            die("%s: golden 里找不到家族共同语句: %s" % (module, frag))
    if nb.count("always @(posedge clock or posedge reset)") != 1:
        die("%s: 异步复位块不止一个" % module)
    for f, _ in fin:
        if nb.count("io_out_bits_r_%s <= io_in_bits_%s;" % (f, f)) != 1:
            die("%s: 字段 %s 的锁存语句不是恰好一条" % (module, f))
        if nb.count("assign io_out_bits_%s = io_out_bits_r_%s;" % (f, f)) != 1:
            die("%s: 字段 %s 的输出 assign 不是恰好一条" % (module, f))
    return ports, fin


def layout(fields):
    """字段 -> (lsb 偏移, 位宽)。第一个字段在最高位（与 {f0, f1, ...} 拼接一致）。"""
    total = sum(w for _, w in fields)
    out, hi = [], total
    for f, w in fields:
        hi -= w
        out.append((f, hi, w))
    return total, out


def gen_wrapper(module, brief):
    ports, fields = fields_of(module)
    total, lay = layout(fields)
    o = []
    o.append("module %s(" % module)
    for i, (_, _, _, raw) in enumerate(ports):
        o.append(raw + ("," if i + 1 < len(ports) else ""))
    o.append(");")
    o.append("  // payload = %d 个字段拼成 %d 位（字段顺序同 golden 端口表，第一个在最高位）"
             % (len(fields), total))
    o.append("  localparam int W = %d;" % total)
    o.append("  logic [W-1:0] in_bits;")
    o.append("  logic [W-1:0] out_bits;")
    o.append("")
    o.append("  assign in_bits = {")
    for i, (f, _, _) in enumerate(lay):
        o.append("    io_in_bits_%s%s" % (f, "," if i + 1 < len(lay) else ""))
    o.append("  };")
    o.append("")
    o.append("  xs_PipelineRegModule_core #(.W(W)) u_core (")
    o.append("    .clock     (clock),")
    o.append("    .reset     (reset),")
    o.append("    .in_ready  (io_in_ready),")
    o.append("    .in_valid  (io_in_valid),")
    o.append("    .in_bits   (in_bits),")
    o.append("    .out_ready (io_out_ready),")
    o.append("    .out_valid (io_out_valid),")
    o.append("    .out_bits  (out_bits)")
    o.append("  );")
    o.append("")
    for f, lsb, w in lay:
        rng = "%d" % lsb if w == 1 else "%d:%d" % (lsb + w - 1, lsb)
        o.append("  assign io_out_bits_%s = out_bits[%s];" % (f, rng))
    o.append("endmodule")
    return "\n".join(o) + "\n"


def replace_region(text, tag, body):
    b = "// BEGIN GENERATED(%s)\n" % tag
    e = "// END GENERATED\n"
    i = text.index(b) + len(b)
    j = text.index(e, i)
    return text[:i] + body + text[j:]


def gen_family_file(module, brief):
    ports, fields = fields_of(module)
    total, _ = layout(fields)
    o = []
    o.append("// " + "=" * 77)
    o.append("// %s —— %s" % (module, brief))
    o.append("//")
    o.append("// PipelineRegModule 家族的薄 wrapper：逻辑全部在共用核 xs_PipelineRegModule_core")
    o.append("// （rtl/memblock/PipelineRegModule.sv，含机制说明）。本变体 payload = %d 个字段 / %d 位。"
             % (len(fields), total))
    o.append("// 本层只做端口展平：golden 的 io_in_bits_* / io_out_bits_* 与核的一根 W 位向量互转。")
    o.append("// 端口表逐字抄自 G1 golden 同名模块。自动生成：scripts/gen_pipelinereg.py —— 勿手改")
    o.append("// " + "=" * 77)
    o.append("")
    return "\n".join(o) + "\n" + gen_wrapper(module, brief)


# ---------------------------------------------------------------------------
#  FM 钉点
# ---------------------------------------------------------------------------
def gen_pins():
    o = []
    o.append("# PipelineRegModule 家族 FM「匹配前」钉点 —— 自动生成：scripts/gen_pipelinereg.py（勿手改）")
    o.append("#")
    o.append("# 只消名差：golden 是按字段展平的寄存器 io_out_bits_r_<字段>_reg[b]，重写核是一根")
    o.append("# 向量 u_core/bits_q_reg[k]（k = 字段偏移 + b，偏移按 golden 端口表字段顺序、第一个字段在最高位）。")
    o.append("# set_user_match 只声明两点对应，比较照比：不约束 ref、不改 appvar、不加黑盒、不 dont_verify。")
    o.append("# fail-closed：set_user_match 从不抛异常（没配上返回 0），所以逐条数返回值；")
    o.append("# 拒一条、或成功数不等于字面整数（= golden 寄存器位数），就 error（safe interp 里 exit 被隐藏）。")
    o.append("# 进 fm.log 的输出一律 ASCII。")
    o.append("proc prm_pin {r i} {")
    o.append("  if {[set_user_match $r $i]} { incr ::PRM_PIN_OK } else {")
    o.append("    incr ::PRM_PIN_BAD")
    o.append("    if {$::PRM_PIN_BAD <= 10} { puts \"PRM_PIN_FAIL: $r <-> $i\" }")
    o.append("  }")
    o.append("}")
    o.append("proc prm_field {top f w lsb} {")
    o.append("  if {$w == 1} {")
    o.append("    prm_pin \"r:/WORK/$top/io_out_bits_r_${f}_reg\" \"i:/WORK/$top/u_core/bits_q_reg\\[$lsb\\]\"")
    o.append("  } else {")
    o.append("    for {set b 0} {$b < $w} {incr b} {")
    o.append("      prm_pin \"r:/WORK/$top/io_out_bits_r_${f}_reg\\[$b\\]\" "
             "\"i:/WORK/$top/u_core/bits_q_reg\\[[expr {$lsb + $b}]\\]\"")
    o.append("    }")
    o.append("  }")
    o.append("}")
    for module, _ in VARIANTS:
        _, fields = fields_of(module)
        total, lay = layout(fields)
        expect = total + 1
        o.append("")
        o.append("if {$top eq \"%s\"} {" % module)
        o.append("  set ::PRM_PIN_OK 0")
        o.append("  set ::PRM_PIN_BAD 0")
        o.append("  puts \"PRM_PIN_BEGIN %s expect=%d\"" % (module, expect))
        o.append("  prm_pin \"r:/WORK/%s/pipeline_reg_valid_reg\" \"i:/WORK/%s/u_core/valid_q_reg\""
                 % (module, module))
        for f, lsb, w in lay:
            o.append("  prm_field %s %s %d %d" % (module, f, w, lsb))
        o.append("  puts \"PRM_PIN_END %s ok=$::PRM_PIN_OK bad=$::PRM_PIN_BAD\"" % module)
        o.append("  if {$::PRM_PIN_BAD != 0} { error \"PRM_PIN_MISS=$::PRM_PIN_BAD\" }")
        o.append("  if {$::PRM_PIN_OK != %d} { error \"PRM_PIN_COUNT=$::PRM_PIN_OK expect=%d\" }"
                 % (expect, expect))
        o.append("}")
    return "\n".join(o) + "\n"


# ---------------------------------------------------------------------------
#  UT tb
# ---------------------------------------------------------------------------
def gen_tb():
    o = []
    o.append("// " + "=" * 77)
    o.append("// PipelineRegModule 家族 UT：三个变体各一对 DUT（golden <M> 对重写 <M>_xs），")
    o.append("// 同一时钟/复位、各自独立的随机激励，逐拍比对全部输出。")
    o.append("//")
    o.append("// 激励：in_valid ~60%、out_ready ~55%、payload 每拍全随机 —— 满/空/同拍进出/满且")
    o.append("// 下游不收（反压）四种局面都常态出现（见 COVERAGE，任何一项为 0 本轮不作数）。")
    o.append("// 复位域：运行中每 ~5000 拍打一次异步复位脉冲：valid 必须归 0，payload 必须保持。")
    o.append("// payload 寄存器不复位：+vcs+initreg+random 下两侧初值不同，所以某变体的 out_bits")
    o.append("// 只在它第一次 in 成交之后才比（此后两侧必然同值）；valid/ready 从复位撤销起就比。")
    o.append("// 自动生成：scripts/gen_pipelinereg.py —— 勿手改")
    o.append("// " + "=" * 77)
    o.append("`timescale 1ns/1ps")
    o.append("")
    o.append("module tb;")
    o.append("  int unsigned NCYCLES = 200000;")
    o.append("  bit   clk = 0;")
    o.append("  logic rst;")
    o.append("  int      errors = 0;")
    o.append("  longint  checks = 0;")
    o.append("  longint  cov_reset_pulses = 0;")
    o.append("  always #5 clk = ~clk;")
    o.append("")
    for vi, (module, _) in enumerate(VARIANTS):
        _, fields = fields_of(module)
        total, lay = layout(fields)
        p = "v%d" % vi
        o.append("  // ---- %s（W=%d）----" % (module, total))
        o.append("  logic [%d:0] %s_in_bits;" % (total - 1, p))
        o.append("  logic %s_in_valid, %s_out_ready;" % (p, p))
        o.append("  wire  %s_g_in_ready, %s_x_in_ready, %s_g_out_valid, %s_x_out_valid;" % (p, p, p, p))
        o.append("  wire  [%d:0] %s_g_out_bits, %s_x_out_bits;" % (total - 1, p, p))
        o.append("  bit   %s_written = 0;   // golden 侧至少成交过一次 in" % p)
        o.append("  longint %s_cov_in_fire = 0, %s_cov_out_fire = 0, %s_cov_both = 0, %s_cov_blocked = 0;"
                 % (p, p, p, p))
        for side, name in (("g", module), ("x", module + "_xs")):
            o.append("  %s u_%s_%s (" % (name, side, p))
            o.append("    .clock        (clk),")
            o.append("    .reset        (rst),")
            o.append("    .io_in_ready  (%s_%s_in_ready)," % (p, side))
            o.append("    .io_in_valid  (%s_in_valid)," % p)
            for f, lsb, w in lay:
                o.append("    .io_in_bits_%s (%s_in_bits[%d +: %d])," % (f, p, lsb, w))
            o.append("    .io_out_ready (%s_out_ready)," % p)
            o.append("    .io_out_valid (%s_%s_out_valid)," % (p, side))
            for i, (f, lsb, w) in enumerate(lay):
                o.append("    .io_out_bits_%s (%s_%s_out_bits[%d +: %d])%s"
                         % (f, p, side, lsb, w, "," if i + 1 < len(lay) else ""))
            o.append("  );")
        o.append("")
    o.append("  task automatic drive();")
    for vi, (module, _) in enumerate(VARIANTS):
        _, fields = fields_of(module)
        total, _ = layout(fields)
        p = "v%d" % vi
        o.append("    %s_in_valid  = ($urandom_range(0, 99) < 60);" % p)
        o.append("    %s_out_ready = ($urandom_range(0, 99) < 55);" % p)
        pad = (total + 31) // 32 * 32
        o.append("    begin")
        o.append("      logic [%d:0] rnd;" % (pad - 1))
        o.append("      for (int k = 0; k < %d; k += 32) rnd[k +: 32] = $urandom();" % pad)
        o.append("      %s_in_bits = rnd[%d:0];" % (p, total - 1))
        o.append("    end")
    o.append("  endtask")
    o.append("")
    o.append("  task automatic compare(int cyc);")
    for vi, (module, _) in enumerate(VARIANTS):
        p = "v%d" % vi
        o.append("    checks++;")
        o.append("    if (%s_g_in_ready !== %s_x_in_ready || %s_g_out_valid !== %s_x_out_valid) begin"
                 % (p, p, p, p))
        o.append("      errors++;")
        o.append("      if (errors <= 20) $display(\"[%%0d] MISMATCH %s ctrl: g ready=%%b valid=%%b  x ready=%%b valid=%%b\","
                 " cyc, %s_g_in_ready, %s_g_out_valid, %s_x_in_ready, %s_x_out_valid);" % (module, p, p, p, p))
        o.append("    end")
        o.append("    if (%s_written && %s_g_out_bits !== %s_x_out_bits) begin" % (p, p, p))
        o.append("      errors++;")
        o.append("      if (errors <= 20) $display(\"[%%0d] MISMATCH %s out_bits: diff=%%h\", cyc, %s_g_out_bits ^ %s_x_out_bits);"
                 % (module, p, p))
        o.append("    end")
    o.append("  endtask")
    o.append("")
    o.append("  task automatic count();")
    for vi, (module, _) in enumerate(VARIANTS):
        p = "v%d" % vi
        o.append("    if (%s_in_valid & %s_g_in_ready) begin %s_cov_in_fire++; %s_written = 1; end"
                 % (p, p, p, p))
        o.append("    if (%s_out_ready & %s_g_out_valid) %s_cov_out_fire++;" % (p, p, p))
        o.append("    if (%s_in_valid & %s_g_in_ready & %s_out_ready & %s_g_out_valid) %s_cov_both++;"
                 % (p, p, p, p, p))
        o.append("    if (%s_in_valid & ~%s_g_in_ready) %s_cov_blocked++;" % (p, p, p))
    o.append("  endtask")
    o.append("")
    o.append("  initial begin")
    o.append("    void'($value$plusargs(\"ncycles=%d\", NCYCLES));")
    o.append("    rst = 1'b1;")
    o.append("    drive();")
    o.append("    repeat (5) @(posedge clk);")
    o.append("    #1 rst = 1'b0;")
    o.append("    for (int cyc = 0; cyc < NCYCLES; cyc++) begin")
    o.append("      // 中途异步复位脉冲：落在两个时钟沿之间，valid 归 0、payload 保持")
    o.append("      if (cyc % 5000 == 2500) begin")
    o.append("        #1 rst = 1'b1; #1 rst = 1'b0; cov_reset_pulses++;")
    o.append("      end")
    o.append("      #1 compare(cyc);")
    o.append("      @(posedge clk);")
    o.append("      count();")
    o.append("      #1 drive();")
    o.append("    end")
    o.append("    $display(\"COVERAGE reset_pulses=%0d\", cov_reset_pulses);")
    covs = []
    for vi, (module, _) in enumerate(VARIANTS):
        p = "v%d" % vi
        o.append("    $display(\"COVERAGE %s in_fire=%%0d out_fire=%%0d both=%%0d blocked=%%0d\","
                 " %s_cov_in_fire, %s_cov_out_fire, %s_cov_both, %s_cov_blocked);" % (module, p, p, p, p))
        covs += ["%s_cov_%s == 0" % (p, c) for c in ("in_fire", "out_fire", "both", "blocked")]
    o.append("    if (%s || cov_reset_pulses == 0) begin" % " || ".join(covs))
    o.append("      $display(\"COVERAGE HOLE -> run does not count\");")
    o.append("      errors++;")
    o.append("    end")
    o.append("    $display(\"checks=%0d errors=%0d\", checks, errors);")
    o.append("    if (errors == 0) $display(\"TEST PASSED\"); else $display(\"TEST FAILED\");")
    o.append("    $finish;")
    o.append("  end")
    o.append("endmodule")
    return "\n".join(o) + "\n"


def targets():
    out = {}
    base = os.path.join(RTL, "PipelineRegModule.sv")
    cur = open(base).read()
    out[base] = replace_region(cur, "pipereg-wrapper", gen_wrapper(*VARIANTS[0]))
    for module, brief in VARIANTS[1:]:
        out[os.path.join(RTL, module + ".sv")] = gen_family_file(module, brief)
    out[os.path.join(UT, "fm_pins_pre.tcl")] = gen_pins()
    out[os.path.join(UT, "tb.sv")] = gen_tb()
    return out


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--check", action="store_true", help="只比对不写，有漂移 rc=1")
    args = ap.parse_args()
    drift = 0
    for path, text in targets().items():
        cur = open(path).read() if os.path.exists(path) else None
        if cur == text:
            print("gen_pipelinereg: OK     %s" % os.path.relpath(path, REPO))
            continue
        if args.check:
            print("gen_pipelinereg: DRIFT  %s" % os.path.relpath(path, REPO))
            drift += 1
        else:
            os.makedirs(os.path.dirname(path), exist_ok=True)
            with open(path, "w") as f:
                f.write(text)
            print("gen_pipelinereg: WROTE  %s" % os.path.relpath(path, REPO))
    return 1 if drift else 0


if __name__ == "__main__":
    sys.exit(main())
