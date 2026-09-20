#!/usr/bin/env python3
"""tb_<n>.sv 生成器 —— TlbStorageWrapper 家族变体的双例化逐拍比对 testbench。

本文件原来是 gen_tb_1.py（只生成变体 _1）。2026-09-20 加 _2/_3 时改成按 --top 参数化：
端口表、读端口数、内层阵列名全部从 golden 读，所以三个变体共用同一份 tb 生成逻辑，
不用把 200 行 tb 抄三遍。

★重构是保值的★：`--top TlbStorageWrapper_1` 重新生成的 tb_1.sv 与重构前
**逐字节相同**（判据见 --check-1），所以变体 _1 已签核的那套 UT 语义没有被动过。

结构与变体 0 的手写 tb.sv 一一对应：
  - 随机激励 200k 拍，逐拍比全部输出（resp 数据段只在 golden 命中时比 —— 未命中时
    golden 里是 OR 树残值，是 don't-care）；
  - directed_mbmc_sfence(): 钉 io_csr_mbmc_BME/CMODE 必须透传给内层 TLBFA_<n>，
    并且**先自证前提成立**（写入后 golden 必须命中、sfence 后 golden 必须失效），
    前提不成立就报错而不是静默算过。

用法：
  python3 gen_tb_variant.py --top TlbStorageWrapper_2     # 写 tb_2.sv
  python3 gen_tb_variant.py --all                          # 写 tb_1/tb_2/tb_3.sv
  python3 gen_tb_variant.py --check                        # 幂等闸：产物必须与生成器一致
"""
import argparse
import sys
import re, os

GOLDEN_DIR = "/home/eda/xs-env/G1-canonical/golden-rtl"
VARIANTS = ["TlbStorageWrapper_1", "TlbStorageWrapper_2", "TlbStorageWrapper_3"]

def parse_ports(path, top):
    s = open(path).read()
    m = re.search(r'module %s\((.*?)\n\);' % top, s, re.S)
    ports = []
    for line in m.group(1).split(","):
        line = line.strip()
        if not line:
            continue
        mm = re.match(r'(input|output)\s+(?:\[(\d+):(\d+)\]\s+)?(\w+)$', line)
        assert mm, repr(line)
        hi = int(mm.group(2)) if mm.group(2) else 0
        ports.append((mm.group(1), hi + 1, mm.group(4)))
    return ports

def decl(w, name, kind="logic"):
    return "  %s %s%s;" % (kind, ("[%d:0] " % (w - 1)) if w > 1 else "", name)

def rnd(w, name):
    """按端口语义给随机激励，和 tb.sv 的 drive_random 对齐。"""
    if re.search(r'_s2xlate$', name) and '_r_req_' in name:
        return "    %s = ($urandom_range(0,1)) ? 2'($urandom_range(0,3)) : 2'b0;" % name
    if re.search(r'_entry_level$', name):
        return "    %s = 2'($urandom_range(0,2));" % name
    if w == 1:
        return "    %s = $urandom_range(0,1);" % name
    if w <= 32:
        return "    %s = %d'($urandom);" % (name, w)
    words = (w + 31) // 32
    return "    %s = {%s};" % (name, ", ".join(["$urandom"] * words))


def build(TOP):
    GOLDEN = os.path.join(GOLDEN_DIR, TOP + ".sv")
    SUF = TOP.split("_")[-1]              # 变体号，用于 tb_<n>.sv / 内层 TLBFA_<n>
    CHILD = "TLBFA_" + SUF
    ports = parse_ports(GOLDEN, TOP)
    ins   = [p for p in ports if p[0] == 'input'  and p[2] not in ('clock', 'reset')]
    outs  = [p for p in ports if p[0] == 'output']
    nread = 1 + max(int(m.group(1)) for m in
                    (re.match(r'io_r_req_(\d+)_valid', p[2]) for p in ins) if m)

    L = []
    A = L.append
    A("// 自动生成：verif/ut/TlbStorageWrapper/gen_tb_variant.py —— 勿手改（改生成器后重跑）")
    A("// " + TOP + "（%d 读端口 / 48 路全相联）双例化逐拍比对:" % nread)
    A("//   golden " + TOP + "  vs  可读重写 " + TOP + "_xs。")
    A("// 含 directed_mbmc_sfence(): 钉 io_csr_mbmc_BME/CMODE 必须透传给内层 TLBFA_1。")
    A("`timescale 1ns/1ps")
    A("module tb;")
    A("  int unsigned NVEC = 200000;")
    A("  int errors = 0, checks = 0;")
    A("  logic clock = 0, reset;")
    A("  always #5 clock = ~clock;")
    for _, w, n in ins:
        A(decl(w, n))
    for _, w, n in outs:
        A(decl(w, "g_" + n, "wire"))
        A(decl(w, "i_" + n, "wire"))
    A("")

    def inst(mod, u, pfx):
        conns = [".clock(clock)", ".reset(reset)"]
        conns += [".%s(%s)" % (n, n) for _, _, n in ins]
        conns += [".%s(%s%s)" % (n, pfx, n) for _, _, n in outs]
        return "  %s %s (%s);" % (mod, u, ", ".join(conns))

    A(inst(TOP, "u_g_", "g_"))
    A(inst(TOP + "_xs", "u_i_", "i_"))
    A("")

    A("  task automatic do_check(int t);")
    A("    checks++;")
    for _, w, n in outs:
        m = re.match(r'io_r_resp_(\d+)_bits_(.*)', n)
        port, field = m.group(1), m.group(2)
        fmt = "%b" if w == 1 else "%h"
        if field == "hit":
            cond = "g_%s !== i_%s" % (n, n)
        else:
            # 未命中时 resp 的数据段是 don't-care（golden 里是 OR 树残值），只在命中时比
            cond = "g_io_r_resp_%s_bits_hit && (g_%s !== i_%s)" % (port, n, n)
        A("    if (%s) begin errors++;" % cond)
        A('      if(errors<=80) $display("vec %%0d %s g=%s i=%s",t,g_%s,i_%s); end' % (n, fmt, fmt, n, n))
    A("  endtask")
    A("")

    A("  task automatic drive_random();")
    A("    automatic int act = $urandom_range(0,9);")
    for _, w, n in ins:
        if n == 'io_w_valid':
            A("    io_w_valid = ($urandom_range(0,3) == 0);")
        elif n == 'io_sfence_valid':
            A("    io_sfence_valid = (act == 0);")
        else:
            A(rnd(w, n))
    A("  endtask")
    A("")

    # ---- directed: mbmc 透传（与 tb.sv 同一套, 只用读端口 0）----
    A(("""  // ---------------------------------------------------------------------------
  // 定向激励: sfence 的失效范围要看 mbmc.BME/CMODE（golden {CHILD}.sv）
  //   else if (io_sfence_valid & ~hg & ~hv)
  //     if (rs1 | priv_virt | io_csr_mbmc_BME & ~io_csr_mbmc_CMODE)
  //   本层只透传这两根线。透传漏了 ⇒ 内层输入悬空 ⇒ if(x) 判假 ⇒ 掉进按地址失效的
  //   `else if (rs2)` 分支。所以 sfence 地址必须**不匹配**写入的 tag，否则两侧都失效、
  //   激励白做（addr[49:39] 全 1 vs tag[34:24]=0）。
  // ---------------------------------------------------------------------------
  int directed_errors = 0;
  task automatic dir_clear();""").format(CHILD=CHILD))
    for _, w, n in ins:
        A("    %s = '0;" % n)
    A("  endtask")
    A("")
    A("  task automatic dir_write_one_entry();")
    A("    // s2xlate=0 / perm_g=1 / level=3 / valididx 全 1 ⇒ 读回命中只取决于 v_way")
    A("    io_w_valid = 1;")
    wnames = {n for _, _, n in ins}
    def setw(n, v):
        if n in wnames:
            A("    %s = %s;" % (n, v))
    setw("io_w_bits_data_s2xlate", "2'b00")
    setw("io_w_bits_data_s1_entry_perm_g", "1'b1")
    setw("io_w_bits_data_s1_entry_perm_r", "1'b1")
    setw("io_w_bits_data_s1_entry_level", "2'b11")
    setw("io_w_bits_data_s1_entry_v", "1'b1")
    for i in range(8):
        setw("io_w_bits_data_s1_valididx_%d" % i, "1'b1")
    A("    @(posedge clock); #1;")
    A("    io_w_valid = 0;")
    A("    @(posedge clock); #1;   // 等 refill_mask 落下")
    A("  endtask")
    A("")
    A("  task automatic dir_read(output logic gh, output logic ih);")
    A("    io_r_req_0_valid = 1; io_r_req_0_bits_vpn = '0; io_r_req_0_bits_s2xlate = '0;")
    A("    @(posedge clock); #1;")
    A("    gh = g_io_r_resp_0_bits_hit;")
    A("    ih = i_io_r_resp_0_bits_hit;")
    A("    io_r_req_0_valid = 0;")
    A("  endtask")
    A("")
    A("""  task automatic directed_mbmc_sfence();
    logic gh, ih;
    dir_clear();
    @(posedge clock); #1;
    dir_write_one_entry();
    dir_read(gh, ih);
    if (gh !== 1'b1) begin
      directed_errors++;
      $display("DIRECTED mbmc: 前提不成立 —— 写入后 golden 未命中 (g_hit=%%b), 激励假设错了", gh);
    end
    if (ih !== gh) begin
      directed_errors++;
      $display("DIRECTED mbmc: 写入/读回阶段就已失配 g_hit=%%b i_hit=%%b", gh, ih);
    end
    io_sfence_valid = 1; io_sfence_bits_rs1 = 0; io_sfence_bits_rs2 = 1;
    io_sfence_bits_addr = {11'h7FF, 39'h0};
    io_sfence_bits_hv = 0; io_sfence_bits_hg = 0;
    io_csr_priv_virt = 0; io_csr_mbmc_BME = 1; io_csr_mbmc_CMODE = 0;
    @(posedge clock); #1;
    io_sfence_valid = 0;
    @(posedge clock); #1;
    dir_read(gh, ih);
    if (gh !== 1'b0) begin
      directed_errors++;
      $display("DIRECTED mbmc: 前提不成立 —— BME sfence 后 golden 仍命中 (g_hit=%%b), 激励假设错了", gh);
    end
    if (ih !== gh) begin
      directed_errors++;
      $display("DIRECTED mbmc MISMATCH: sfence(BME=1,CMODE=0,rs1=0,priv_virt=0) 后 g_hit=%%b i_hit=%%b —— io_csr_mbmc_BME/CMODE 没透传给内层 %s", gh, ih);
    end
    dir_clear();
    @(posedge clock); #1;
    $display("DIRECTED mbmc_sfence errors=%%0d", directed_errors);
  endtask
""" % CHILD)
    A("  initial begin")
    A("    void'($value$plusargs(\"ncycles=%d\", NVEC));   // ut_common 统一下发 +ncycles")
    A("    reset = 1;")
    A("    dir_clear();")
    A("    repeat (3) @(posedge clock); #1; reset = 0;")
    A("    @(posedge clock);")
    A("    directed_mbmc_sfence();")
    A("    errors += directed_errors;")
    A("    for (int t = 0; t < NVEC; t++) begin")
    A("      drive_random();")
    A("      @(posedge clock); #1;")
    A("      do_check(t);")
    A("    end")
    A('    $display("checks=%0d errors=%0d (含 directed=%0d)", checks, errors, directed_errors);')
    A('    if (errors == 0 && checks > 1000) $display("TEST PASSED");')
    A('    else $display("TEST FAILED");')
    A("    $finish;")
    A("  end")
    A("endmodule")


    return "\n".join(L) + "\n"


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--top")
    ap.add_argument("--all", action="store_true")
    ap.add_argument("--check", action="store_true")
    a = ap.parse_args()
    here = os.path.dirname(os.path.abspath(__file__))
    tops = VARIANTS if (a.all or a.check) else [a.top]
    if not tops or tops == [None]:
        ap.error("要 --top <名> 或 --all 或 --check")
    rc = 0
    for TOP in tops:
        text = build(TOP)
        dst = os.path.join(here, "tb_%s.sv" % TOP.split("_")[-1])
        if a.check:
            cur = open(dst).read() if os.path.exists(dst) else None
            if cur != text:
                print("DRIFT: %s 与生成器不一致" % dst); rc = 1
            else:
                print("OK: %s" % dst)
        else:
            open(dst, "w").write(text)
            print("wrote %s" % dst)
    return rc


if __name__ == "__main__":
    sys.exit(main())
