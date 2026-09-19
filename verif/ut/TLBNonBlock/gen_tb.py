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
    # ★下面三档概率是按 need_gpa 的入口条件调出来的★（core §need_gpa 的 want_gpa /
    # can_get_gpa）：want_gpa 要求 ~kill & ~isPrefetch，can_get_gpa 要求
    # robIdx 正好等于 robPendingPtr（随机下 ~1/32）或 frm_mabuf。frm_mabuf 是唯一
    # 便宜的入口，所以拉到 50%；kill/isPrefetch 压低，否则 need_gpa 一路进不去
    # （实测：全 20%/15% 时 60k 拍 c_needgpa=0）。
    if re.match(r'io_requestor_\d+_req_bits_frm_mabuf$', name):
        return "%s <= ($urandom() %% 100) < 50" % name
    if re.match(r'io_requestor_\d+_req_bits_isPrefetch$', name):
        return "%s <= ($urandom() %% 100) < 10" % name
    if re.match(r'io_requestor_\d+_req_bits_(kill|no_translate|hyperinst|hlvx)$', name):
        return "%s <= ($urandom() %% 100) < 20" % name
    if re.match(r'io_requestor_\d+_req_kill$', name):
        return "%s <= ($urandom() %% 100) < 8" % name
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
    # ★把 stage-1 的权限位偏向"合法"★：gpf 要求 ~af_fault & ~has_pf（core §权限检查），
    # 而 perm.af / perm.pf / 缺 r|w|x|a|d 任一位都会先把 pf/af 报出来，把 gpf 盖住。
    # 全随机时 hasGpf 实测 200k 拍只出现 37 次、need_gpa 只进 18 次、resp_gpa_refill
    # 恒 0（覆盖桶量出来的）。这里让 s1 侧 70% 合法、G-stage 侧保持全随机，
    # 于是 pf 与 gpf 两条路都有量；af/pf 保留 15% 让 af 路不至于饿死。
    if re.match(r'io_ptw_resp_bits_s1_entry_perm_[rwxadv]$', name):
        return "%s <= (($urandom() %% 100) < 70)" % name
    if name in ("io_ptw_resp_bits_s1_pf", "io_ptw_resp_bits_s1_af"):
        return "%s <= (($urandom() %% 100) < 15)" % name
    # ★G-stage 侧反过来偏向"不合法"★：hasGpf 是 need_gpa 状态机唯一的入口，
    # 而 gpf 还要求 ~af_fault —— g_perm.af（来自 s2_gaf）一置就把 gpf 盖掉。
    # 所以 s2 的 r/w/x/a/d 只有 35% 为真（缺权限 => gpf），s2_gaf 压到 10%。
    if re.match(r'io_ptw_resp_bits_s2_entry_perm_[rwxad]$', name):
        return "%s <= (($urandom() %% 100) < 35)" % name
    if name == "io_ptw_resp_bits_s2_gaf":
        return "%s <= (($urandom() %% 100) < 10)" % name
    if name == "io_ptw_resp_bits_s2_gpf":
        return "%s <= (($urandom() %% 100) < 25)" % name
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
        # redirect 一来就 clear_gpa（core §need_gpa），15% 下 need_gpa 活不过一拍。
        return "%s <= ($urandom() %% 100) < 8" % name
    if name in ("io_redirect_bits_robIdx_value", "io_robPendingPtr_value"):
        return "%s <= 8'($urandom() %% 16)" % name
    if re.match(r'io_requestor_\d+_req_bits_debug_robIdx_value$', name):
        return "%s <= 8'($urandom() %% 16)" % name
    return "%s <= %s" % (name, rng(msb, lsb))


# ---------------------------------------------------------------------------
# 覆盖闸（CONVENTIONS「errors=0 单独不算数」）
#
# 只靠 errors=0 判绿有两个 fail-open：(a) 编译坏了 / tb 根本没比 —— 由 checks
# 计数堵；(b) 编译好、也比了，但激励从没走到出 bug 的那条路 —— 由下面这组桶堵。
# 桶全部取 **golden 一侧**的信号（golden 内部层次 + golden 输出），所以它量的是
# "激励把参考设计推到过哪些状态"，与重写核对不对无关；重写核错了也不会把桶刷绿。
#
# ★c_napot_sup 这个桶是有来历的★：本轮唯一那个真 bug（s1_hit 的 NAPOT tag 切片
# 少取一位）就只在 "noS2 + s1.entry.n=1 + PTW 响应正好命中这条 miss" 时才显形。
# 没有这个桶，一份把 n 恒置 0 的激励可以让三个变体全绿而 bug 还在。
COV_BUCKETS = [
    ("c_hit",       "lane0 命中（entries 或旁路）"),
    ("c_miss",      "lane0 未命中"),
    ("c_phit",      "PTW 旁路命中（p_hit 打拍后为真）"),
    ("c_ptwreq",    "向 PTW 发过请求"),
    ("c_needgpa",   "进入过 need_gpa 状态"),
    ("c_gparefill", "拿回过 gpaddr（resp_gpa_refill）"),
    ("c_gpf",       "出现过 G-stage 故障 hasGpf"),
    ("c_napot_sup", "noS2+NAPOT 的 PTW 响应把本拍 miss 压住（ptw_just_back）"),
    ("c_sfence",    "sfence 冲刷"),
    ("c_ppnnz",     "命中且译出非零 ppn"),
    ("c_s2x0",      "resp 拍 s2xlate=00 无两级翻译"),
    ("c_s2x1",      "resp 拍 s2xlate=01 只 VS-stage"),
    ("c_s2x2",      "resp 拍 s2xlate=10 只 G-stage"),
    ("c_s2x3",      "resp 拍 s2xlate=11 两级"),
]


def ptw_valid_outs(outs):
    """本变体所有 io_ptw_req_<i>_valid 输出名（base 4 条 lane，_1/_2 各 2 条）。"""
    names = [n for _, _, _, n in outs if re.match(r'io_ptw_req_\d+_valid$', n)]
    if not names:
        sys.exit("ERROR: 没找到 io_ptw_req_*_valid 输出，覆盖闸无法构造")
    return sorted(names)


def cov_decls(mod, outs):
    L = ["", "  // ---- 覆盖闸计数器（全部取 golden 侧，见 gen_tb.py 的 COV_BUCKETS 注释）----"]
    for name, why in COV_BUCKETS:
        L.append("  longint %s = 0;  // %s" % (name, why))
    L.append("")
    L.append("  task automatic sample_cov;")
    L.append("    begin")
    L.append("      if (dut_g.req_out_v_0 && !dut_g.miss_read_0)  c_hit++;")
    L.append("      if (dut_g.req_out_v_0 &&  dut_g.miss_read_0)  c_miss++;")
    L.append("      if (dut_g.readResult_p_hit_last_REG)          c_phit++;")
    L.append("      if (%s)                                       c_ptwreq++;"
             % " || ".join("%s_g" % n for n in ptw_valid_outs(outs)))
    L.append("      if (dut_g.need_gpa)                           c_needgpa++;")
    L.append("      if (dut_g.resp_gpa_refill)                    c_gparefill++;")
    L.append("      if (dut_g.hasGpf_0)                           c_gpf++;")
    L.append("      if (io_ptw_resp_valid && io_ptw_resp_bits_s1_entry_n")
    L.append("          && io_ptw_resp_bits_s2xlate == 2'h0")
    L.append("          && dut_g.req_out_v_0 && dut_g.miss_read_0")
    L.append("          && !%s_g)                                 c_napot_sup++;" % ptw_valid_outs(outs)[0])
    L.append("      if (io_sfence_valid)                          c_sfence++;")
    L.append("      if (dut_g.req_out_v_0 && !dut_g.miss_read_0")
    L.append("          && io_requestor_0_resp_bits_paddr_0_g[47:12] != 36'h0) c_ppnnz++;")
    L.append("      if (dut_g.req_out_v_0) begin")
    L.append("        case (dut_g.req_out_s2xlate_0)")
    L.append("          2'h0: c_s2x0++;  2'h1: c_s2x1++;")
    L.append("          2'h2: c_s2x2++;  default: c_s2x3++;")
    L.append("        endcase")
    L.append("      end")
    L.append("    end")
    L.append("  endtask")
    return L


def cov_report(mod, outs, has_gpa=True):
    L = ["    begin : cov_gate", "      int bad_cov = 0;"]
    L.append('      $display("--- coverage (golden 侧状态桶，全部必须 > 0) ---");')
    for name, why in COV_BUCKETS:
        L.append('      $display("  %-12s = %%0d   %s", %s);' % (name, why, name))
        L.append("      if (%s == 0) bad_cov++;" % name)
    L.append('      $display("warmup_phase2=%%0d cycles (%s)", wu);'
             % ("waited for golden resp_gpa_refill" if has_gpa
                else "skipped: this variant has no resp.gpaddr -> no resp_gpa_gvpn"))
    L.append('      $display("checks=%0d errors=%0d bad_cov=%0d", checks, errors, bad_cov);')
    L.append("      if (checks == 0) begin")
    L.append('        $display("TEST FAILED (%s): checks=0 —— tb 一次都没比，判 fail-open");' % mod)
    L.append("      end else if (errors == 0 && bad_cov == 0) begin")
    L.append('        $display("TEST PASSED (%s, %%0d cycles)", ncycles);' % mod)
    L.append("      end else if (errors != 0) begin")
    L.append('        $display("TEST FAILED (%s): errors=%%0d", errors);' % mod)
    L.append("      end else begin")
    L.append('        $display("TEST FAILED (%s): errors=0 但 %%0d 个覆盖桶为空，激励没走到", bad_cov);' % mod)
    L.append("      end")
    L.append("    end")
    L.append("    $finish;")
    return L


def directed_getgpa(ins):
    """把 need_gpa -> getGpa 往返走通的定向激励（覆盖桶 c_gparefill）。

    纯随机激励下 resp_gpa_refill 实测为 0（200k 拍 seed=1：need_gpa 只进过 18 次，
    而收尾还要求这期间回来的 PTW 响应 vpn/s2xlate 正好是它等的那一页）。这里在
    golden 已经处在 need_gpa 时，以 60% 概率把 PTW 响应定向成"正是它等的那一页"。

    ★激励只读 golden 一侧的状态（dut_g.need_gpa*）★——它是激励发生器的一部分，
    两个 DUT 吃到的仍然是同一组输入端口值，不构成"拿被测件当参考"。

    构造：level 取 1，n 取 0 —— 此时 ptw_get_vpn() 对四种 s2xlate 都还原成
      {tag 的高位, need_gpa_vpn 的低 9 位}，只要 tag 用 need_gpa_vpn 的对应切片，
      还原结果就恒等于 need_gpa_vpn（判据：core 的 ptw_get_vpn，lvl=1 分支）。
    """
    have = {n for _, _, _, n in ins}
    need = ["io_ptw_resp_valid", "io_ptw_resp_bits_getGpa", "io_ptw_resp_bits_s2xlate",
            "io_ptw_resp_bits_s1_entry_n", "io_ptw_resp_bits_s2_entry_n",
            "io_ptw_resp_bits_s1_entry_level", "io_ptw_resp_bits_s2_entry_level",
            "io_ptw_resp_bits_s1_entry_tag", "io_ptw_resp_bits_s2_entry_tag"]
    missing = [n for n in need if n not in have]
    if missing:
        sys.exit("ERROR: 定向 getGpa 激励缺端口 %s" % missing)
    return [
        "      // ---- 定向激励：走通 need_gpa -> getGpa 往返（见 directed_getgpa 注释）----",
        "      if (dut_g.need_gpa && ($urandom() % 100) < 60) begin",
        "        io_ptw_resp_valid               <= 1'b1;",
        "        io_ptw_resp_bits_getGpa         <= 1'b1;",
        "        io_ptw_resp_bits_s2xlate        <= dut_g.need_gpa_s2xlate;",
        "        io_ptw_resp_bits_s1_entry_n     <= 1'b0;",
        "        io_ptw_resp_bits_s2_entry_n     <= 1'b0;",
        "        io_ptw_resp_bits_s1_entry_level <= 2'h1;",
        "        io_ptw_resp_bits_s2_entry_level <= 2'h1;",
        "        io_ptw_resp_bits_s1_entry_tag   <= dut_g.need_gpa_vpn[37:3];",
        "        io_ptw_resp_bits_s2_entry_tag   <= dut_g.need_gpa_vpn;",
        "      end",
    ]


def warmup_drive(ins):
    """复位后的热身窗口：把所有 req_valid / ptw_resp_valid 强拉 1。

    ★为什么必须有（实测，不是保险起见）★
    golden 与重写核里有一批**无复位**的寄存器（RegEnable：req_out_* / resp_fullva_r /
    ptw_resp_bits_reg_* / p_* ...）。`+vcs+initreg+random` 给两侧的是**各自独立的
    随机初值**，在第一次被写之前逐拍比它们，比的是模拟器的初值、不是电路 ——
    实测 seed=7/42 的 initreg=random 那一轮能报出上万个这种"失配"。
    `+vcs+initreg+0` 那一轮两侧都是 0，看不出来，所以这条坑只有 random 那轮现形。

    无复位寄存器的初值本来就归 FM 管（FM 把它们当自由变量，两侧配对后逐点证等价），
    UT 这边的正确做法是**先把它们写一遍再开始比**，而不是把差异当 bug 报。
    热身期间不计 checks、不采覆盖桶；正式比较从热身之后开始。

    深度只有 1 拍的 RegEnable 其实 1 拍就够，取 8 拍是留余量（跨越 DelayN_7/_9 的
    两级流水 + p_hit 的一拍旁路）。
    """
    have = {n for _, _, _, n in ins}
    vs = sorted(n for n in have if re.match(r'io_requestor_\d+_req_valid$', n))
    if not vs or "io_ptw_resp_valid" not in have:
        sys.exit("ERROR: 热身窗口找不到 req_valid / ptw_resp_valid")
    L = ["      // ---- 热身窗口：所有 enable 拉满（见 gen_tb.py 的 warmup_drive）----",
         "      if (warmup) begin"]
    for n in vs:
        L.append("        %s <= 1'b1;" % n)
    L.append("        io_ptw_resp_valid <= 1'b1;")
    L.append("      end")
    return L


def gen(mod):
    ports = read_ports(mod)
    ins = [p for p in ports if p[0] == "input" and p[3] not in ("clock", "reset")]
    outs = [p for p in ports if p[0] == "output"]
    # 本变体有没有 resp.gpaddr(0) 端口 —— 决定阶段二热身有没有对象（见 warmup 注释）
    has_gpa = any(re.match(r'io_requestor_\d+_resp_bits_gpaddr_0$', p[3]) for p in outs)
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
    L.append("  longint errors = 0, checks = 0;")
    L.append("  // 复位后的热身窗口，见 gen_tb.py 的 warmup_drive() 与 warmup_seq()")
    L.append("  localparam int WARMUP_CYCLES = 8;      // 阶段一：所有 enable 拉满")
    L.append("  localparam int WARMUP_MAX    = 20000;  // 阶段二：等自保持寄存器被写，超时判失败")
    L.append("  reg warmup = 1'b1;")
    L.append("  reg seen_refill = 1'b%d;" % (0 if has_gpa else 1))
    L.append("  integer wu = 0;")
    if has_gpa:
        L.append("  // golden 的 resp_gpa_refill 为 1 的那一拍，正是 resp_gpa_gvpn 被写的拍")
        L.append("  always @(posedge clock) if (!reset && dut_g.resp_gpa_refill) seen_refill <= 1'b1;")
    else:
        L.append("  // 本变体没有 resp.gpaddr 端口 -> golden 里根本没有 resp_gpa_gvpn 这个")
        L.append("  // 自保持寄存器（判据：golden %s 的 reg 清单里没有它），阶段二无对象，直接跳过。" % mod)
    L.append("  integer ncycles = 200000;")
    L.append("  integer i;")
    L.extend(cov_decls(mod, outs))
    L.append("")
    L.append("  task automatic drive_inputs;")
    L.append("    begin")
    for d, msb, lsb, n in ins:
        L.append("      %s;" % drive(n, msb, lsb))
    L.extend(directed_getgpa(ins))
    L.extend(warmup_drive(ins))
    L.append("    end")
    L.append("  endtask")
    L.append("")
    L.append("  task automatic check_outputs;")
    L.append("    begin")
    for d, msb, lsb, n in outs:
        L.append("      checks = checks + 1;")
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
    L.append("    // ---- 热身：把所有 enable 拉满，让两侧每个无复位寄存器都被写过一次 ----")
    L.append("    for (i = 0; i < WARMUP_CYCLES; i = i + 1) begin")
    L.append("      @(posedge clock);")
    L.append("      drive_inputs();")
    L.append("    end")
    L.append("    warmup = 1'b0;")
    L.append("    // ---- 阶段二：等**自保持**的无复位寄存器被写过一次 ----")
    L.append("    // resp_gpa_gvpn / need_gpa_vpn / need_gpa_robidx_* 的次态默认是它们自己，")
    L.append("    // 拉 enable 没用，只有一次真的 getGpa 往返才会写它们。两侧的随机初值不同，")
    L.append("    // 写之前比 gpaddr 就是在比模拟器初值（实测 seed=7 那轮 832 个失配全是这个）。")
    L.append("    while (!seen_refill && wu < WARMUP_MAX) begin")
    L.append("      @(posedge clock);")
    L.append("      drive_inputs();")
    L.append("      wu = wu + 1;")
    L.append("    end")
    L.append("    if (!seen_refill) begin")
    L.append("      $display(\"TEST FAILED (%s): 热身 %%0d 拍内 golden 的 resp_gpa_refill "
             "没出现过 —— 自保持寄存器没被写，后面的比较没有意义\", wu);" % mod)
    L.append("      $finish;")
    L.append("    end")
    L.append("    @(posedge clock);")
    L.append("    drive_inputs();")
    L.append("    for (i = 0; i < ncycles; i = i + 1) begin")
    L.append("      @(posedge clock);")
    L.append("      drive_inputs();")
    L.append("      #1 check_outputs();")
    L.append("      sample_cov();")
    L.append("    end")
    L.extend(cov_report(mod, outs, has_gpa))
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
