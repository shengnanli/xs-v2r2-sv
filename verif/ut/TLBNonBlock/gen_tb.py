#!/usr/bin/env python3
"""TLBNonBlock 家族 UT testbench 生成器（三个变体各一份 tb）。

双例化：golden <Mod> 与派生的 <Mod>_xs 吃同一组激励，逐拍比所有输出。
端口表从 G1 golden 逐字读，避免手抄 604 个端口。

★激励不是纯随机★（纯随机下 entries 几乎永远 miss，权限检查那一大片锥体测不到）：
  · vaddr 从一个 8 项的 vpn 池里取，PTW 响应的 tag 也从同一个池里取
    —— 这样 refill 之后再查同一条 vpn 就会命中，命中路径才有覆盖；
  · satp/vsatp/hgatp.mode 只取 {0, 8(Sv39), 9(Sv48)}，特权级只取 {U,S,M}，
    否则 4 位 mode 随机时 99% 落在"没开页表"这一支；
  · cmd 只取 {read, write, exec, amo}；
  · ptw_resp_valid / req_valid 用偏置概率，让 refill 与查询交错。
纯随机的位（各种 perm/ppn/pbmt）照旧 $urandom —— FM 不做可达性分析，UT 这边
只要把主要控制路径走到就行。
"""
import os
import re
import sys

GOLDEN = os.environ.get("GOLDEN_RTL", "/home/eda/xs-env/G1-canonical/golden-rtl")
HERE = os.path.dirname(os.path.abspath(__file__))
PORT_RE = re.compile(
    r'^\s+(input|output)\s+(?:\[([0-9]+):([0-9]+)\]\s+)?([A-Za-z_][A-Za-z0-9_]*)\s*,?\s*$')

VARIANTS = ["TLBNonBlock", "TLBNonBlock_1", "TLBNonBlock_2"]


def read_ports(mod):
    path = os.path.join(GOLDEN, mod + ".sv")
    out, inside = [], False
    for line in open(path):
        if line.startswith("module %s(" % mod):
            inside = True
            continue
        if inside:
            if line.startswith(");"):
                break
            m = PORT_RE.match(line.rstrip("\n"))
            if m:
                d, msb, lsb, n = m.groups()
                out.append((d, int(msb) if msb else 0, int(lsb) if lsb else 0, n))
    if not out:
        sys.exit("ERROR: 解析 %s 端口表失败" % path)
    return out


def rng(msb, lsb):
    w = msb - lsb + 1
    if w <= 32:
        return "%d'($urandom())" % w
    parts = []
    rem = w
    while rem > 0:
        parts.append("$urandom()")
        rem -= 32
    return "%d'({%s})" % (w, ", ".join(parts))


def drive(name, msb, lsb):
    """给某个输入端口挑激励。返回一行赋值（不含分号）。"""
    w = msb - lsb + 1
    # --- 请求通道 ---
    m = re.match(r'io_requestor_(\d+)_req_valid$', name)
    if m:
        return "%s <= ($urandom() %% 100) < 70" % name
    m = re.match(r'io_requestor_(\d+)_req_bits_vaddr$', name)
    if m:
        return "%s <= {vpn_pool[$urandom() %% POOL_N], 12'($urandom())}" % name
    m = re.match(r'io_requestor_(\d+)_req_bits_fullva$', name)
    if m:
        i = m.group(1)
        return ("%s <= {14'($urandom()), vpn_pool[$urandom() %% POOL_N], 12'($urandom())}"
                % name)
    if re.match(r'io_requestor_\d+_req_bits_cmd$', name):
        return "%s <= cmd_pool[$urandom() %% 4]" % name
    if re.match(r'io_requestor_\d+_req_bits_checkfullva$', name):
        return "%s <= ($urandom() %% 100) < 40" % name
    if re.match(r'io_requestor_\d+_req_bits_(kill|no_translate|hyperinst|hlvx|'
                r'isPrefetch|frm_mabuf)$', name):
        return "%s <= ($urandom() %% 100) < 20" % name
    if re.match(r'io_requestor_\d+_req_kill$', name):
        return "%s <= ($urandom() %% 100) < 15" % name
    # --- PTW 响应 ---
    if name == "io_ptw_resp_valid":
        return "%s <= ($urandom() %% 100) < 35" % name
    if name == "io_ptw_resp_bits_s2xlate":
        return "%s <= 2'($urandom())" % name
    if name == "io_ptw_resp_bits_s1_entry_tag":
        return "%s <= vpn_pool[$urandom() %% POOL_N][37:3]" % name
    if name == "io_ptw_resp_bits_s2_entry_tag":
        return "%s <= vpn_pool[$urandom() %% POOL_N]" % name
    if name in ("io_ptw_resp_bits_s1_entry_level", "io_ptw_resp_bits_s2_entry_level"):
        return "%s <= 2'($urandom())" % name
    if name in ("io_ptw_resp_bits_s1_entry_asid",):
        return "%s <= asid_pool[$urandom() %% 4]" % name
    if name in ("io_ptw_resp_bits_s1_entry_vmid", "io_ptw_resp_bits_s2_entry_vmid"):
        return "%s <= 14'(vmid_pool[$urandom() %% 4])" % name
    # --- CSR ---
    if name in ("io_csr_satp_mode", "io_csr_vsatp_mode", "io_csr_hgatp_mode"):
        return "%s <= mode_pool[$urandom() %% 3]" % name
    if name in ("io_csr_satp_asid", "io_csr_vsatp_asid"):
        return "%s <= asid_pool[$urandom() %% 4]" % name
    if name == "io_csr_hgatp_vmid":
        return "%s <= vmid_pool[$urandom() %% 4]" % name
    if name in ("io_csr_priv_imode", "io_csr_priv_dmode"):
        return "%s <= priv_pool[$urandom() %% 3]" % name
    if name.startswith("io_csr_pmm_"):
        return "%s <= 2'($urandom())" % name
    if name == "io_csr_priv_virt":
        return "%s <= ($urandom() %% 100) < 40" % name
    # --- sfence / redirect：偶发 ---
    if name == "io_sfence_valid":
        return "%s <= ($urandom() %% 100) < 8" % name
    if name == "io_redirect_valid":
        return "%s <= ($urandom() %% 100) < 15" % name
    if name in ("io_redirect_bits_robIdx_value", "io_robPendingPtr_value"):
        return "%s <= 8'($urandom() %% 16)" % name
    if re.match(r'io_requestor_\d+_req_bits_debug_robIdx_value$', name):
        return "%s <= 8'($urandom() %% 16)" % name
    return "%s <= %s" % (name, rng(msb, lsb))


def gen(mod):
    ports = read_ports(mod)
    ins = [p for p in ports if p[0] == "input" and p[3] not in ("clock", "reset")]
    outs = [p for p in ports if p[0] == "output"]
    L = []
    L.append("// 由 verif/ut/TLBNonBlock/gen_tb.py 生成，勿手改。golden %s 与重写 %s_xs"
             % (mod, mod))
    L.append("// 同激励双例化，逐拍比全部 %d 个输出。" % len(outs))
    L.append("`timescale 1ns/1ps")
    L.append("module tb;")
    L.append("  localparam int POOL_N = 8;")
    L.append("  reg clock = 1'b0;")
    L.append("  reg reset = 1'b1;")
    L.append("  always #5 clock = ~clock;")
    L.append("")
    L.append("  // 激励池：让 refill 与查询打在同一批 vpn 上，命中路径才有覆盖")
    L.append("  reg [37:0] vpn_pool  [POOL_N];")
    L.append("  reg [2:0]  cmd_pool  [4];")
    L.append("  reg [3:0]  mode_pool [3];")
    L.append("  reg [15:0] asid_pool [4];")
    L.append("  reg [15:0] vmid_pool [4];")
    L.append("  reg [1:0]  priv_pool [3];")
    L.append("")
    for d, msb, lsb, n in ins:
        w = "" if msb == lsb == 0 else "[%d:%d] " % (msb, lsb)
        L.append("  reg %s%s;" % (w, n))
    L.append("")
    for d, msb, lsb, n in outs:
        w = "" if msb == lsb == 0 else "[%d:%d] " % (msb, lsb)
        L.append("  wire %s%s_g, %s_x;" % (w, n, n))
    L.append("")
    for suffix, inst in [("_g", mod), ("_x", mod + "_xs")]:
        L.append("  %s dut%s (" % (inst, suffix))
        conn = ["    .clock (clock), .reset (reset)"]
        for d, msb, lsb, n in ins:
            conn.append("    .%s (%s)" % (n, n))
        for d, msb, lsb, n in outs:
            conn.append("    .%s (%s%s)" % (n, n, suffix))
        L.append(",\n".join(conn))
        L.append("  );")
    L.append("")
    L.append("  integer errors = 0;")
    L.append("  integer ncycles = 200000;")
    L.append("  integer i;")
    L.append("")
    L.append("  task automatic drive_inputs;")
    L.append("    begin")
    for d, msb, lsb, n in ins:
        L.append("      %s;" % drive(n, msb, lsb))
    L.append("    end")
    L.append("  endtask")
    L.append("")
    L.append("  task automatic check_outputs;")
    L.append("    begin")
    for d, msb, lsb, n in outs:
        L.append("      if (%s_g !== %s_x) begin" % (n, n))
        L.append("        errors = errors + 1;")
        L.append("        if (errors < 20) $display(\"MISMATCH @%%0t %s g=%%h x=%%h\","
                 " $time, %s_g, %s_x);" % (n, n, n))
        L.append("      end")
    L.append("    end")
    L.append("  endtask")
    L.append("")
    L.append("  initial begin")
    L.append("    if (!$value$plusargs(\"ncycles=%d\", ncycles)) ncycles = 200000;")
    L.append("    for (i = 0; i < POOL_N; i = i + 1) vpn_pool[i] = {$urandom(), $urandom()};")
    L.append("    cmd_pool[0] = 3'h0; cmd_pool[1] = 3'h1; cmd_pool[2] = 3'h2; cmd_pool[3] = 3'h5;")
    L.append("    mode_pool[0] = 4'h0; mode_pool[1] = 4'h8; mode_pool[2] = 4'h9;")
    L.append("    for (i = 0; i < 4; i = i + 1) asid_pool[i] = 16'($urandom());")
    L.append("    for (i = 0; i < 4; i = i + 1) vmid_pool[i] = 16'($urandom() % 8);")
    L.append("    priv_pool[0] = 2'h0; priv_pool[1] = 2'h1; priv_pool[2] = 2'h3;")
    L.append("    drive_inputs();")
    L.append("    reset = 1'b1;")
    L.append("    repeat (5) @(posedge clock);")
    L.append("    reset = 1'b0;")
    L.append("    for (i = 0; i < ncycles; i = i + 1) begin")
    L.append("      @(posedge clock);")
    L.append("      drive_inputs();")
    L.append("      #1 check_outputs();")
    L.append("    end")
    L.append("    if (errors == 0) $display(\"TEST PASSED (%s, %%0d cycles)\", ncycles);" % mod)
    L.append("    else $display(\"TEST FAILED (%s): errors=%%0d\", errors);" % mod)
    L.append("    $finish;")
    L.append("  end")
    L.append("endmodule")
    return "\n".join(L) + "\n"


if __name__ == "__main__":
    for k, mod in enumerate(VARIANTS):
        name = "tb.sv" if k == 0 else "tb_%d.sv" % k
        path = os.path.join(HERE, name)
        txt = gen(mod)
        if not os.path.exists(path) or open(path).read() != txt:
            open(path, "w").write(txt)
        print("%-16s -> %s" % (mod, path))
