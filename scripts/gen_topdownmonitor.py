#!/usr/bin/env python3
"""gen_topdownmonitor.py —— TopDownMonitor 的机械派生区生成器。

生成对象（手写核 xs_TopDownMonitor_core 不碰）：
  rtl/l2/TopDownMonitor.sv            GENERATED(tdm-wrapper)：golden 同名 wrapper，端口表逐字取 golden，
                                      把 64 个 MSHR 的 valid/is_miss/set/reqTag 与 robHeadPaddr 接进核
  verif/ut/TopDownMonitor/tb.sv       UT（双例化，全输入随机 + 定向构造块地址命中）

fail-closed 核对：
  (1) golden 端口按规则分成"进核"与"只喂性能计数器（本配置不生成硬件）"两类，每个端口恰好一类；
  (2) 进核端口的位宽与核参数一致（set 9 位、reqTag 31 位、paddr 36 位，4 bank × 16 MSHR）；
  (3) 唯一输出是 io_debugTopDown_l2MissMatch；
  (4) 生成结果与磁盘逐字节比较（--check）。

用法:
  scripts/gen_topdownmonitor.py            # 写文件
  scripts/gen_topdownmonitor.py --check    # 只比对，不写；有漂移 rc=1（gate 用）
"""
import argparse
import os
import re
import sys

GOLDEN_DIR = "/home/eda/xs-env/G1-canonical/golden-rtl"
HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.normpath(os.path.join(HERE, ".."))
RTL = os.path.join(REPO, "rtl", "l2", "TopDownMonitor.sv")
TB = os.path.join(REPO, "verif", "ut", "TopDownMonitor", "tb.sv")
TOP = "TopDownMonitor"
NBANK, NMSHR = 4, 16
CORE_FIELDS = {"valid": 1, "bits_is_miss": 1, "bits_set": 9, "bits_reqTag": 31}
PERF_ONLY = re.compile(r"io_(dirResult_\d+|msAlloc_\d+_\d+|hitPfInMSHR_\d+|pfSent_\d+|pfLateInMSHR_\d+)_"
                       r"|io_msStatus_\d+_\d+_bits_(channel|is_prefetch)$")


def die(msg):
    raise SystemExit("gen_topdownmonitor: " + msg)


def port_table(module):
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


def classify(ports):
    core, perf = [], []
    seen = set()
    for d, w, n, _ in ports:
        m = re.match(r"io_msStatus_(\d+)_(\d+)_(valid|bits_is_miss|bits_set|bits_reqTag)$", n)
        if m:
            b, k, f = int(m.group(1)), int(m.group(2)), m.group(3)
            if d != "input" or w != CORE_FIELDS[f] or b >= NBANK or k >= NMSHR:
                die("端口 %s 形状不符" % n)
            core.append((n, b, k, f)); seen.add(n)
        elif n in ("io_debugTopDown_robHeadPaddr_valid", "io_debugTopDown_robHeadPaddr_bits"):
            if d != "input" or w != (1 if n.endswith("valid") else 36):
                die("端口 %s 形状不符" % n)
            seen.add(n)
        elif n == "io_debugTopDown_l2MissMatch":
            if d != "output" or w != 1:
                die("端口 %s 形状不符" % n)
            seen.add(n)
        elif PERF_ONLY.match(n):
            if d != "input":
                die("性能计数器端口 %s 不是输入" % n)
            perf.append(n); seen.add(n)
    left = [n for _, _, n, _ in ports if n not in seen]
    if left:
        die("有端口没有规则消费：%s" % left[:5])
    for b in range(NBANK):
        for k in range(NMSHR):
            for f in CORE_FIELDS:
                if ("io_msStatus_%d_%d_%s" % (b, k, f)) not in seen:
                    die("缺 MSHR 端口 io_msStatus_%d_%d_%s" % (b, k, f))
    return core, perf


def replace_region(text, tag, body):
    begin = "// BEGIN GENERATED(%s)" % tag
    end = "// END GENERATED"
    i = text.index(begin)
    j = text.index(end, i)
    line_start = text.rfind("\n", 0, i) + 1
    indent = text[line_start:i]
    return text[:i] + begin + "\n" + body + "\n" + indent + end + text[j + len(end):]


def gen_wrapper(ports, core, perf):
    o = ["module %s (" % TOP]
    for idx, (_, _, _, line) in enumerate(ports):
        o.append(line + ("," if idx + 1 < len(ports) else ""))
    o.append(");")
    o.append("  // 只喂性能计数器、本配置下无硬件的输入共 %d 个（dirResult/msAlloc/hitPfInMSHR/pfSent/" % len(perf))
    o.append("  // pfLateInMSHR，及 msStatus 的 channel/is_prefetch）：不连任何逻辑。")
    o.append("  logic [%d:0][%d:0]       ms_valid, ms_is_miss;" % (NBANK - 1, NMSHR - 1))
    o.append("  logic [%d:0][%d:0][8:0]  ms_set;" % (NBANK - 1, NMSHR - 1))
    o.append("  logic [%d:0][%d:0][30:0] ms_req_tag;" % (NBANK - 1, NMSHR - 1))
    sig = {"valid": "ms_valid", "bits_is_miss": "ms_is_miss", "bits_set": "ms_set", "bits_reqTag": "ms_req_tag"}
    for n, b, k, f in sorted(core, key=lambda x: (x[1], x[2], list(CORE_FIELDS).index(x[3]))):
        o.append("  assign %s[%d][%d] = %s;" % (sig[f], b, k, n))
    o.append("  xs_TopDownMonitor_core #(.NBANK(%d), .NMSHR(%d)) u_core (" % (NBANK, NMSHR))
    o.append("    .rob_head_valid (io_debugTopDown_robHeadPaddr_valid),")
    o.append("    .rob_head_paddr (io_debugTopDown_robHeadPaddr_bits),")
    o.append("    .ms_valid       (ms_valid),")
    o.append("    .ms_is_miss     (ms_is_miss),")
    o.append("    .ms_set         (ms_set),")
    o.append("    .ms_req_tag     (ms_req_tag),")
    o.append("    .l2_miss_match  (io_debugTopDown_l2MissMatch)")
    o.append("  );")
    o.append("endmodule")
    return "\n".join(o)


def gen_tb(ports):
    ins = [(w, n) for d, w, n, _ in ports if d == "input"]
    o = []
    o.append("// =============================================================================")
    o.append("// tb —— TopDownMonitor UT（自动生成：scripts/gen_topdownmonitor.py，勿手改）")
    o.append("// golden TopDownMonitor 与重写件 TopDownMonitor_xs 双例化，纯组合，每拍一组新输入，比 l2MissMatch。")
    o.append("// 激励：所有输入每拍随机；另外按拍轮换四种定向形状，让命中/不命中两边都被打到：")
    o.append("//   0 全随机（几乎不命中）；1 挑一个 (bank, mshr)，把 reqTag 高 12 位清 0、令其块地址 == ROB 头块地址")
    o.append("//   （valid/is_miss/robHead.valid 随机，命中与\"差一个条件\"都会出现）；2 同 1 但 bank 号错位（地址差在低 2 位）；")
    o.append("//   3 同 1 但 reqTag 高 12 位置非 0（golden 的位宽怪癖：永远不命中）。")
    o.append("// 覆盖（写进 PASS 判据）：命中 >= 20000 拍，且 64 个 (bank, mshr) 位置各自作为命中者 >= 100 次。")
    o.append("// =============================================================================")
    o.append("`timescale 1ns/1ps")
    o.append("module tb;")
    o.append("  int unsigned NCYCLES = 200000;")
    o.append("  longint errors = 0, checks = 0;")
    for w, n in ins:
        o.append("  logic [%d:0] %s;" % (w - 1, n))
    o.append("  logic g_out, i_out;")
    for inst, out in ((TOP, "g_out"), (TOP + "_xs", "i_out")):
        o.append("  %s u_%s (" % (inst, out[0]))
        conns = [".%s(%s)" % (n, n) for _, n in ins] + [".io_debugTopDown_l2MissMatch(%s)" % out]
        for idx, cn in enumerate(conns):
            o.append("    %s%s" % (cn, "," if idx + 1 < len(conns) else ""))
        o.append("  );")
    o.append("  int hit_cnt = 0, hit_pos [%d][%d];" % (NBANK, NMSHR))
    o.append("")
    o.append("  task automatic drive();")
    for w, n in ins:
        if w <= 32:
            o.append("    %s = %d'($urandom);" % (n, w))
        else:
            o.append("    %s = {%s};" % (n, ", ".join(["$urandom"] * ((w + 31) // 32))))
    o.append("  endtask")
    o.append("")
    o.append("  // 把 (b, m) 号 MSHR 的块地址设成与 ROB 头一致（mode 2：bank 号错位；mode 3：tag 高位非 0）")
    o.append("  task automatic aim(int b, int m, int mode);")
    o.append("    logic [29:0] blk;")
    o.append("    logic [1:0]  bank;")
    o.append("    logic        force_on;")
    o.append("    blk  = io_debugTopDown_robHeadPaddr_bits[35:6];")
    o.append("    bank = (mode == 2) ? 2'(b + 1) : 2'(b);")
    o.append("    blk[1:0] = bank;")
    o.append("    io_debugTopDown_robHeadPaddr_bits[7:6] = bank;")
    o.append("    force_on = (mode == 1) && ($urandom_range(0, 1) == 1);   // 一半拍把三个使能条件都置 1")
    o.append("    if (force_on) io_debugTopDown_robHeadPaddr_valid = 1'b1;")
    o.append("    case (b * %d + m)" % NMSHR)
    for b in range(NBANK):
        for m in range(NMSHR):
            p = "io_msStatus_%d_%d_bits_" % (b, m)
            o.append("      %d: begin %sset = blk[10:2]; %sreqTag = {(mode == 3) ? 12'($urandom | 1) : 12'd0, blk[29:11]};"
                     % (b * NMSHR + m, p, p))
            o.append("          if (force_on) begin %svalid = 1'b1; %sis_miss = 1'b1; end end"
                     % (p[:-5], p))
    o.append("    endcase")
    o.append("  endtask")
    o.append("")
    o.append("  initial begin")
    o.append("    if (!$value$plusargs(\"ncycles=%d\", NCYCLES)) NCYCLES = 200000;")
    o.append("    foreach (hit_pos[b, m]) hit_pos[b][m] = 0;")
    o.append("    for (int c = 0; c < NCYCLES; c++) begin")
    o.append("      int mode, b, m;")
    o.append("      drive();")
    o.append("      mode = c %% 4; b = $urandom_range(0, %d); m = $urandom_range(0, %d);" % (NBANK - 1, NMSHR - 1))
    o.append("      if (mode != 0) aim(b, m, mode);")
    o.append("      #1;")
    o.append("      checks++;")
    o.append("      if (g_out !== i_out) begin errors++; if (errors <= 40) $display(\"[%0d] MISMATCH l2MissMatch golden=%b impl=%b mode=%0d b=%0d m=%0d\", c, g_out, i_out, mode, b, m); end")
    o.append("      if (g_out) begin hit_cnt++; if (mode == 1) hit_pos[b][m]++; end")
    o.append("      #1;")
    o.append("    end")
    o.append("    begin")
    o.append("      int bad = 0, minp = 1 << 30;")
    o.append("      foreach (hit_pos[b, m]) begin if (hit_pos[b][m] < minp) minp = hit_pos[b][m]; if (hit_pos[b][m] < 100) bad++; end")
    o.append("      if (hit_cnt < 20000) bad++;")
    o.append("      $display(\"--- coverage: hits=%0d per-(bank,mshr) hits min=%0d\", hit_cnt, minp);")
    o.append("      $display(\"checks=%0d errors=%0d bad_cov=%0d\", checks, errors, bad);")
    o.append("      if (errors == 0 && checks > 1000 && bad == 0) $display(\"TEST PASSED\");")
    o.append("      else $display(\"TEST FAILED\");")
    o.append("    end")
    o.append("    $finish;")
    o.append("  end")
    o.append("endmodule")
    return "\n".join(o) + "\n"


def targets():
    ports = port_table(TOP)
    core, perf = classify(ports)
    text = replace_region(open(RTL).read(), "tdm-wrapper", gen_wrapper(ports, core, perf))
    return {RTL: text, TB: gen_tb(ports)}


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--check", action="store_true", help="只比对不写，有漂移 rc=1")
    args = ap.parse_args()
    drift = 0
    for path, text in targets().items():
        cur = open(path).read() if os.path.exists(path) else None
        if cur == text:
            print("gen_topdownmonitor: OK     %s" % os.path.relpath(path, REPO))
            continue
        if args.check:
            print("gen_topdownmonitor: DRIFT  %s" % os.path.relpath(path, REPO))
            drift += 1
        else:
            os.makedirs(os.path.dirname(path), exist_ok=True)
            with open(path, "w") as f:
                f.write(text)
            print("gen_topdownmonitor: WROTE  %s" % os.path.relpath(path, REPO))
    return 1 if drift else 0


if __name__ == "__main__":
    sys.exit(main())
