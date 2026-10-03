#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""gen_tb.py —— PTWNewFilter UT testbench 生成器。

双例化：golden PTWNewFilter 与派生的 PTWNewFilter_xs 吃同一组激励，逐拍比全部输出端口。
端口表从 G1 golden 逐字读；声明、端口连线宏、PTW 响应载荷随机化、逐口比较由这里机械生成，
激励策略与覆盖判据在下面的模板里手写。

用法：
    python3 gen_tb.py            # 生成 tb.sv（幂等：内容不变不写）
    python3 gen_tb.py --check    # tb.sv 与生成器不一致则 rc=1
"""
import os
import re
import sys

GOLDEN = "/home/eda/xs-env/G1-canonical/golden-rtl"
HERE = os.path.dirname(os.path.abspath(__file__))
TB = os.path.join(HERE, "tb.sv")


def ports():
    t = open(os.path.join(GOLDEN, "PTWNewFilter.sv")).read()
    m = re.search(r"^module PTWNewFilter\((.*?)^\);", t, re.S | re.M)
    out = []
    for ln in m.group(1).splitlines():
        mm = re.match(r"\s*(input|output)\s+(?:\[(\d+):0\]\s+)?(\w+)\s*,?\s*$", ln)
        if not mm:
            if ln.strip():
                sys.exit("gen_tb.py: 端口行解析不了：%r" % ln)
            continue
        d, msb, n = mm.groups()
        out.append((d, int(msb) + 1 if msb else 1, n))
    return out


def rand_expr(w):
    if w == 1:
        return "1'($urandom)"
    if w <= 32:
        return "%d'($urandom)" % w
    return "%d'({$urandom, $urandom})" % w


HEADER = r"""// =============================================================================
// PTWNewFilter UT —— golden PTWNewFilter 对重写 PTWNewFilter_xs 双例化，同激励逐拍比对全部 @NOUT@ 根输出（@NOUTBITS@ 位）。
// 本文件由 verif/ut/PTWNewFilter/gen_tb.py 生成（幂等），不要手改。
//
// 激励要点（判别力来自哪里）：
//   · 8 个 dtlb 口（load 0..3 / store 4..5 / prefetch 6..7）的 miss vpn 从 12 项小池子取，组内常常同页
//     （同拍借 id）、跨组同页（两张表各自入表、各自发出）、与表内已有项同页（去重）；池里有同一 2MB 区域
//     的几页，PTW 回超页时一次销多项、多张表同拍 refill。
//   · PTW 模型：golden 发出且被收下的请求在 1~6 拍后回一个**就是那一页**的响应（命中键对得上，其余载荷全随机），
//     偶尔凭空回应；ptw_req.ready 随机（60%），三张表常同时有待发请求 → 轮转仲裁的每个相位都会走到。
//   · flush 五个源（sfence / satp / vsatp / hgatp / virt changed）各以小概率单独脉冲，经 2 拍延迟清表。
//   · 偶发 3 拍复位脉冲（复位期间不比）。
// 比较窗口：表项载荷、PTW 响应载荷寄存器、hint 打拍寄存器都不复位，+random 档两侧初值不同。复位释放后先等：
//   三张表共 32 项每一项都入过表、PTW 响应来过、load 表 hint.resp.valid 出现过（RegEnable 的 hint.resp.bits
//   才被写过），再加 4 拍，之后逐拍全比。这段等待在 +0 档同样生效，checks 照实打印。
// 覆盖判据（在重写核的语义名上数；输出逐拍相等）：三张表各自入表 / 各自被仲裁发出 / 各自 refill / 两张以上
//   表同时待发 / 两张以上表同拍 refill / flush 时表非空 / load hint replay_all / 三张表各自 getGpa /
//   rob_head_miss —— 每一类都必须发生过，否则本轮不作数（TEST FAILED）。
// =============================================================================
`timescale 1ns/1ps

module tb;

  int unsigned NCYCLES = 200000;
  bit  clk = 0;
  int  errors = 0;
  longint checks = 0;
  always #5 clk = ~clk;

  logic reset;
"""

BODY = r"""
  // ---- 激励 ----
  localparam int POOL = 12;
  logic [37:0] pool [POOL];
  typedef struct { logic [37:0] vpn; logic [1:0] s2x; int delay; } job_t;
  job_t jobs[$];

  task automatic set_resp(input logic [37:0] vpn, input logic [1:0] s2x);
    logic [7:0] vidx;
    rand_resp_payload();
    io_ptw_resp_bits_s2xlate          = s2x;
    io_ptw_resp_bits_s1_entry_tag     = vpn[37:3];
    io_ptw_resp_bits_s1_entry_asid    = ($urandom_range(0, 9) == 0) ? 16'($urandom) : 16'h5;
    io_ptw_resp_bits_s1_entry_vmid    = ($urandom_range(0, 9) == 0) ? 14'($urandom) : 14'h3;
    io_ptw_resp_bits_s1_entry_n       = ($urandom_range(0, 9) == 0);
    io_ptw_resp_bits_s1_entry_perm_g  = ($urandom_range(0, 4) == 0);
    io_ptw_resp_bits_s1_entry_level   = ($urandom_range(0, 3) == 0) ? 2'($urandom_range(1, 3)) : 2'd0;
    io_ptw_resp_bits_s1_addr_low      = vpn[2:0];
    vidx = 8'($urandom) | (($urandom_range(0, 7) != 0) ? (8'd1 << vpn[2:0]) : 8'd0);
@VIDX@
    io_ptw_resp_bits_s2_entry_tag     = vpn;
    io_ptw_resp_bits_s2_entry_vmid    = ($urandom_range(0, 9) == 0) ? 14'($urandom) : 14'h3;
    io_ptw_resp_bits_s2_entry_n       = ($urandom_range(0, 9) == 0);
    io_ptw_resp_bits_s2_entry_level   = ($urandom_range(0, 3) == 0) ? 2'($urandom_range(1, 3)) : 2'd0;
  endtask

  function automatic logic [37:0] pick_vpn(input logic [37:0] buddy);
    return ($urandom_range(0, 3) == 0) ? buddy : pool[$urandom_range(0, POOL - 1)];
  endfunction

  task automatic drive_inputs();
    logic [7:0] v;
    logic [7:0][37:0] vpn;
    logic [7:0][1:0] s2x;
    logic [7:0] gpa;
    io_csr_satp_asid  = 16'h5;
    io_csr_vsatp_asid = 16'h5;
    io_csr_hgatp_vmid = 16'h3;
    io_sfence_valid          = ($urandom_range(0, 999) < 3);
    io_csr_satp_changed      = ($urandom_range(0, 999) < 2);
    io_csr_vsatp_changed     = ($urandom_range(0, 999) < 2);
    io_csr_hgatp_changed     = ($urandom_range(0, 999) < 2);
    io_csr_priv_virt_changed = ($urandom_range(0, 999) < 2);
    for (int i = 0; i < 8; i++) begin
      v[i]   = ($urandom_range(0, 9) < ((i < 4) ? 4 : 5));
      vpn[i] = pick_vpn((i == 0) ? pool[0] : vpn[i - 1]);
      s2x[i] = ($urandom_range(0, 3) == 0) ? 2'($urandom) : 2'd0;
      gpa[i] = ($urandom_range(0, 4) == 0);
    end
    // 跨组同页：store / prefetch 口有时抄 load 口的页
    if ($urandom_range(0, 4) == 0) begin vpn[4] = vpn[0]; s2x[4] = s2x[0]; end
    if ($urandom_range(0, 4) == 0) begin vpn[6] = vpn[1]; s2x[6] = s2x[1]; end
@REQ@
    io_ptw_req_0_ready = ($urandom_range(0, 9) < 6);
    io_debugTopDown_robHeadVaddr_valid = $urandom_range(0, 1);
    io_debugTopDown_robHeadVaddr_bits  = {pool[$urandom_range(0, POOL - 1)], 12'($urandom)};
    io_ptw_resp_valid = 1'b0;
    set_resp(pool[$urandom_range(0, POOL - 1)], 2'($urandom));
    if (jobs.size() > 0 && jobs[0].delay <= 0) begin
      job_t j = jobs.pop_front();
      set_resp(j.vpn, ($urandom_range(0, 19) == 0) ? 2'($urandom) : j.s2x);
      io_ptw_resp_valid = 1'b1;
    end else if ($urandom_range(0, 29) == 0) begin
      io_ptw_resp_valid = 1'b1;
    end
    foreach (jobs[k]) jobs[k].delay--;
  endtask

  task automatic cmp1(input string name, input logic [63:0] g, input logic [63:0] x);
    checks++;
    if (g !== x) begin
      errors++;
      if (errors <= 20) $display("[%0t] MISMATCH %s golden=%h rewrite=%h", $time, name, g, x);
    end
  endtask

  task automatic compare_outputs();
@CMP@
  endtask

  // ---- 覆盖事件 ----
  longint n_enq[3], n_issue[3], n_refill[3], n_gpa[3];
  longint n_contend, n_multi_refill, n_flush, n_replay, n_robhead;
  task automatic collect_cov();
    for (int f = 0; f < 3; f++) begin
      if (x_dut.u_core.filt_req_valid[f] & x_dut.u_core.filt_req_ready[f]) n_issue[f]++;
      if (x_dut.u_core.filt_refill[f]) n_refill[f]++;
      if (x_dut.u_core.filt_get_gpa[f]) n_gpa[f]++;
    end
    if (|x_dut.u_core.load_filter.u_core.enqvalid)     n_enq[0]++;
    if (|x_dut.u_core.store_filter.u_core.enqvalid)    n_enq[1]++;
    if (|x_dut.u_core.prefetch_filter.u_core.enqvalid) n_enq[2]++;
    if ($countones(x_dut.u_core.filt_req_valid) > 1) n_contend++;
    if ($countones(x_dut.u_core.filt_refill) > 1) n_multi_refill++;
    if (x_dut.u_core.flush && ((|x_dut.u_core.load_filter.u_core.v) || (|x_dut.u_core.store_filter.u_core.v)
                               || (|x_dut.u_core.prefetch_filter.u_core.v))) n_flush++;
    if (g_io_hint_resp_valid && g_io_hint_resp_bits_replay_all) n_replay++;
    if (g_io_rob_head_miss_in_tlb) n_robhead++;
  endtask

  initial begin
    logic [15:0] ever_ld;
    logic [7:0]  ever_st, ever_pf;
    bit seen_resp, seen_hint, cmp_on;
    int warm_cnt;
    bit cov_ok;
    if (!$value$plusargs("ncycles=%d", NCYCLES)) NCYCLES = 200000;
    for (int i = 0; i < POOL; i++) pool[i] = {6'($urandom), 32'($urandom)};
    pool[1] = {pool[0][37:9], 9'h0a7};     // 与 pool[0] 同一 2MB 区域
    pool[2] = {pool[0][37:9], 9'h1c2};
    pool[3] = {pool[0][37:3], 3'd6};       // 与 pool[0] 同一 sector
    ever_ld = '0; ever_st = '0; ever_pf = '0;
    seen_resp = 0; seen_hint = 0; cmp_on = 0; warm_cnt = 0;
    reset = 1;
    drive_inputs();
    repeat (10) @(negedge clk);
    reset = 0;
    for (longint c = 0; c < NCYCLES; c++) begin
      if (c > 1000 && $urandom_range(0, 39999) == 0) begin
        reset = 1;
        repeat (3) begin drive_inputs(); @(negedge clk); end
        reset = 0;
        jobs.delete();
      end
      drive_inputs();
      #1;
@EVER@
      if (io_ptw_resp_valid) seen_resp = 1;
      if (g_io_hint_resp_valid) seen_hint = 1;
      if ((&ever_ld) && (&ever_st) && (&ever_pf) && seen_resp && seen_hint && !cmp_on) begin
        warm_cnt++;
        if (warm_cnt > 4) cmp_on = 1;
      end
      if (cmp_on) begin compare_outputs(); collect_cov(); end
      if (g_io_ptw_req_0_valid && io_ptw_req_0_ready)
        jobs.push_back('{g_io_ptw_req_0_bits_vpn, g_io_ptw_req_0_bits_s2xlate, $urandom_range(1, 6)});
      while (jobs.size() > 16) void'(jobs.pop_front());
      @(negedge clk);
    end
    $display("=== COVERAGE (PTWNewFilter) === checks=%0d enq=%0d/%0d/%0d issue=%0d/%0d/%0d refill=%0d/%0d/%0d getGpa=%0d/%0d/%0d contend=%0d multi_refill=%0d flush_nonempty=%0d replay_all=%0d robhead=%0d",
             checks, n_enq[0], n_enq[1], n_enq[2], n_issue[0], n_issue[1], n_issue[2],
             n_refill[0], n_refill[1], n_refill[2], n_gpa[0], n_gpa[1], n_gpa[2],
             n_contend, n_multi_refill, n_flush, n_replay, n_robhead);
    cov_ok = (n_contend != 0) && (n_multi_refill != 0) && (n_flush != 0) && (n_replay != 0) && (n_robhead != 0);
    for (int f = 0; f < 3; f++)
      if (n_enq[f] == 0 || n_issue[f] == 0 || n_refill[f] == 0 || n_gpa[f] == 0) cov_ok = 0;
    if (!cov_ok) begin
      $display("COVERAGE INSUFFICIENT");
      errors++;
    end
    if (errors == 0) $display("TEST PASSED (checks=%0d errors=0)", checks);
    else             $display("TEST FAILED errors=%0d (checks=%0d)", errors, checks);
    $finish;
  end
endmodule
"""


def build():
    ps = ports()
    outs = [(w, n) for d, w, n in ps if d == "output"]
    decl, conn = [], []
    width = max(len(n) for _, _, n in ps)
    for d, w, n in ps:
        if n in ("clock", "reset"):
            continue
        vec = "" if w == 1 else "[%d:0] " % (w - 1)
        if d == "input":
            decl.append("  logic %s%s;" % (vec, n))
        else:
            decl.append("  logic %sg_%s, x_%s;" % (vec, n, n))
    for d, w, n in ps:
        if n == "clock":
            src = "clk"
        elif n == "reset" or d == "input":
            src = n
        else:
            src = "P``_" + n
        conn.append("    .%s (%s)" % (n.ljust(width), src))
    macro = "`define PNF_PORTS(P) \\\n" + ", \\\n".join(conn) + "\n"
    resp = [(w, n) for d, w, n in ps if d == "input" and n.startswith("io_ptw_resp_bits_")]
    rnd = ["  task automatic rand_resp_payload();"]
    rnd += ["    %s = %s;" % (n, rand_expr(w)) for w, n in resp]
    rnd += ["  endtask"]
    vidx = "\n".join("    io_ptw_resp_bits_s1_valididx_%d = vidx[%d];" % (k, k) for k in range(8))
    req = []
    for i in range(8):
        req.append("    io_tlb_req_%d_valid = v[%d];" % (i, i))
        req.append("    io_tlb_req_%d_bits_vpn = vpn[%d];" % (i, i))
        req.append("    io_tlb_req_%d_bits_s2xlate = s2x[%d];" % (i, i))
        req.append("    io_tlb_req_%d_bits_getGpa = gpa[%d];" % (i, i))
    cw = max(len(n) for _, n in outs)
    cmp = ["    cmp1(%s %s x_%s);" % (('"%s",' % n).ljust(cw + 3), ("g_" + n + ",").ljust(cw + 3), n)
           for _, n in outs]
    ever = ["      ever_ld |= {%s};" % ", ".join("g_dut.load_filter_load_entry.v_%d" % k for k in range(15, -1, -1)),
            "      ever_st |= {%s};" % ", ".join("g_dut.store_filter_store_entry.v_%d" % k for k in range(7, -1, -1)),
            "      ever_pf |= {%s};" % ", ".join("g_dut.prefetch_filter_prefetch_entry.v_%d" % k for k in range(7, -1, -1))]
    head = HEADER.replace("@NOUT@", str(len(outs))).replace("@NOUTBITS@", str(sum(w for w, _ in outs)))
    body = BODY.replace("@VIDX@", vidx).replace("@REQ@", "\n".join(req)).replace("@CMP@", "\n".join(cmp)) \
               .replace("@EVER@", "\n".join(ever))
    return (head + "\n".join(decl) + "\n\n" + macro + "\n"
            "  PTWNewFilter    g_dut (`PNF_PORTS(g));\n"
            "  PTWNewFilter_xs x_dut (`PNF_PORTS(x));\n\n" + "\n".join(rnd) + "\n" + body)


def main():
    text = build()
    cur = open(TB).read() if os.path.exists(TB) else None
    if "--check" in sys.argv:
        if cur != text:
            print("gen_tb.py: DRIFT tb.sv")
            return 1
        print("gen_tb.py: OK tb.sv")
        return 0
    if cur != text:
        open(TB, "w").write(text)
        print("gen_tb.py: WROTE tb.sv")
    else:
        print("gen_tb.py: OK tb.sv")
    return 0


if __name__ == "__main__":
    sys.exit(main())
