#!/usr/bin/env python3
"""TLBNonBlock 家族（TLBNonBlock / _1 / _2）薄 wrapper 生成器。

为什么要生成器：三个变体的端口表合计 604 个端口，而且**每条 requestor 通道的字段集
各不相同**（firtool 按父级 MemBlock 的实际连接逐端口消端口）。手抄 604 行端口 +
逐端口接线，抄错一位只有 FM 会告诉你，代价太大。

本脚本做的事：
  1. 从 G1 golden 的同名模块**逐字**抄端口表（名字/方向/位宽/顺序）；
  2. 由端口表推导每条 lane 的"字段存在矩阵"，得出核的参数；
  3. 生成 wrapper：例化 golden 子模块（DelayN_9 / DelayN_7 / TlbStorageWrapper_N）
     与参数化可读核 xs_TLBNonBlock_core；golden 缺的输入端口按 firtool 折叠掉的
     常量补 0，golden 缺的输出端口不接。

★两个不能从端口表推出来、必须另有依据的参数★
  · N_DUPS：TLBNonBlock_2 的 nRespDups 是 2，但它的 resp.paddr(1) 被父级消掉了，
    端口表上看不出来。依据是 Chisel（MemBlock.scala 的三条 new TLBNonBlock(...)）
    加 golden 的 `reg REG*` 计数（每 (lane,dup) 一个）：base 8 个 / _1 2 个 / _2 2 个
    ——_2 只有 lane0 的 checkfullva 端口在，lane1 的两个 REG 被折成常量消掉了，
    所以 2 = 1 lane × 2 dup，nRespDups=2。脚本会重新核对这个计数，对不上就报错。
  · DIFF_INDEX_0：difftest 的全局编号。直接从 golden 里的
    `wire [7:0] difftest_l1tlb_index = 8'hX;` 读出来，不是猜的。

生成区用 // BEGIN GENERATED(tlbnb-wrapper) 标记；文件头的手写说明在标记之外，不动。
"""
import os
import re
import sys

GOLDEN = os.environ.get("GOLDEN_RTL", "/home/eda/xs-env/G1-canonical/golden-rtl")
HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.dirname(HERE)
OUT_DIR = os.path.join(REPO, "rtl", "memblock")

PORT_RE = re.compile(
    r'^\s+(input|output)\s+(?:\[([0-9]+):([0-9]+)\]\s+)?([A-Za-z_][A-Za-z0-9_]*)\s*,?\s*$')

VARIANTS = [
    # (golden 顶层, 用的 TlbStorageWrapper, 父级里的实例名, 一句话说明)
    ("TLBNonBlock",   "TlbStorageWrapper_1", "dtlb_ld",
     "MemBlock 的 dtlb_ld：3 个 load 单元 + 1 个杂项口共 4 条通道"),
    ("TLBNonBlock_1", "TlbStorageWrapper_2", "dtlb_st",
     "MemBlock 的 dtlb_st：2 个 store 地址单元"),
    ("TLBNonBlock_2", "TlbStorageWrapper_3", "dtlb_prefetch",
     "MemBlock 的 dtlb_prefetch：2 条预取通道"),
]
# nRespDups 来自 Chisel，见文件头；下面 check_dups() 会拿 golden 的 REG 计数复核。
N_DUPS = {"TLBNonBlock": 2, "TLBNonBlock_1": 1, "TLBNonBlock_2": 2}

# requestor 通道里"核要、golden 可能没有"的输入字段 -> (核端口名, 缺席时补的常量)
REQ_IN = [
    ("req_valid",        "req_valid",       None),
    ("req_bits_vaddr",   "req_vaddr",       "50'h0"),
    ("req_bits_fullva",  "req_fullva",      "64'h0"),
    ("req_bits_checkfullva", "req_checkfullva", "1'b0"),
    ("req_bits_cmd",     "req_cmd",         "3'h0"),
    ("req_bits_hyperinst", "req_hyperinst", "1'b0"),
    ("req_bits_hlvx",    "req_hlvx",        "1'b0"),
    ("req_bits_kill",    "req_kill_bit",    "1'b0"),
    ("req_bits_isPrefetch", "req_is_prefetch", "1'b0"),
    ("req_bits_no_translate", "req_no_translate", "1'b0"),
    ("req_bits_pmp_addr", "req_pmp_addr",   "48'h0"),
    ("req_bits_frm_mabuf", "req_frm_mabuf", "1'b0"),
    ("req_bits_debug_robIdx_flag", "req_robidx_flag", "1'b0"),
    ("req_bits_debug_robIdx_value", "req_robidx_value", "8'h0"),
    ("req_bits_debug_isFirstIssue", "req_first_issue", "1'b0"),
    ("req_bits_memidx_idx", "req_memidx",   "7'h0"),
    ("req_kill",         "req_kill",        "1'b0"),
]
# requestor 通道里核算出来、golden 可能不接的输出字段 -> 核端口表达式（{i} 是 lane 号）
REQ_OUT = [
    ("resp_valid",                 "resp_valid[{i}]"),
    ("resp_bits_miss",             "resp_miss[{i}]"),
    ("resp_bits_paddr_0",          "resp_paddr[{i}][0]"),
    ("resp_bits_paddr_1",          "resp_paddr[{i}][1]"),
    ("resp_bits_gpaddr_0",         "resp_gpaddr[{i}][0]"),
    ("resp_bits_pbmt_0",           "resp_pbmt[{i}][0]"),
    ("resp_bits_fullva",           "resp_fullva[{i}]"),
    ("resp_bits_memidx_idx",       "resp_memidx[{i}]"),
    ("resp_bits_ptwBack",          "resp_ptw_back[{i}]"),
    ("resp_bits_isForVSnonLeafPTE", "resp_is_for_vs_non_leaf_pte[{i}]"),
    ("resp_bits_excp_0_pf_ld",     "resp_excp_pf_ld[{i}]"),
    ("resp_bits_excp_0_pf_st",     "resp_excp_pf_st[{i}]"),
    ("resp_bits_excp_0_gpf_ld",    "resp_excp_gpf_ld[{i}]"),
    ("resp_bits_excp_0_gpf_st",    "resp_excp_gpf_st[{i}]"),
    ("resp_bits_excp_0_af_ld",     "resp_excp_af_ld[{i}]"),
    ("resp_bits_excp_0_af_st",     "resp_excp_af_st[{i}]"),
    ("resp_bits_excp_0_isHyper",   "resp_excp_is_hyper[{i}]"),
    ("resp_bits_excp_0_vaNeedExt", "resp_excp_va_need_ext[{i}]"),
]
# csr（延迟后）struct 的字段 -> DelayN_7 的输出端口后缀
CSR_FIELDS = [
    ("satp_changed", "satp_changed"), ("vsatp_changed", "vsatp_changed"),
    ("hgatp_changed", "hgatp_changed"), ("priv_virt_changed", "priv_virt_changed"),
    ("satp_mode", "satp_mode"), ("satp_asid", "satp_asid"), ("satp_ppn", "satp_ppn"),
    ("vsatp_mode", "vsatp_mode"), ("vsatp_asid", "vsatp_asid"), ("vsatp_ppn", "vsatp_ppn"),
    ("hgatp_mode", "hgatp_mode"), ("hgatp_vmid", "hgatp_vmid"), ("hgatp_ppn", "hgatp_ppn"),
    ("priv_mxr", "priv_mxr"), ("priv_sum", "priv_sum"), ("priv_vmxr", "priv_vmxr"),
    ("priv_vsum", "priv_vsum"), ("priv_virt", "priv_virt"), ("priv_spvp", "priv_spvp"),
    ("priv_imode", "priv_imode"), ("priv_dmode", "priv_dmode"),
    ("pmm_mseccfg", "pmm_mseccfg"), ("pmm_menvcfg", "pmm_menvcfg"),
    ("pmm_henvcfg", "pmm_henvcfg"), ("pmm_hstatus", "pmm_hstatus"),
    ("pmm_senvcfg", "pmm_senvcfg"),
]
# ptw_resp_t 的字段 -> golden io_ptw_resp_bits_* 后缀（一一同名，向量字段单列）
PTW_SCALARS = [
    "s2xlate",
    "s1_entry_tag", "s1_entry_asid", "s1_entry_vmid", "s1_entry_n", "s1_entry_pbmt",
    "s1_entry_perm_d", "s1_entry_perm_a", "s1_entry_perm_g", "s1_entry_perm_u",
    "s1_entry_perm_x", "s1_entry_perm_w", "s1_entry_perm_r",
    "s1_entry_level", "s1_entry_v", "s1_entry_ppn", "s1_addr_low", "s1_pf", "s1_af",
    "s2_entry_tag", "s2_entry_vmid", "s2_entry_n", "s2_entry_pbmt", "s2_entry_ppn",
    "s2_entry_perm_d", "s2_entry_perm_a", "s2_entry_perm_g", "s2_entry_perm_u",
    "s2_entry_perm_x", "s2_entry_perm_w", "s2_entry_perm_r", "s2_entry_level",
    "s2_gpf", "s2_gaf", "getGpa",
]
PERM_FIELDS = ["pf", "af", "v", "d", "a", "u", "x", "w", "r"]
GPERM_FIELDS = ["pf", "af", "d", "a", "x", "w", "r"]


def read_ports(mod):
    """golden <mod>.sv 的端口表，按出现顺序返回 [(dir, msb, lsb, name)]。"""
    path = os.path.join(GOLDEN, mod + ".sv")
    out, inside = [], False
    with open(path) as f:
        for line in f:
            if line.startswith("module %s(" % mod):
                inside = True
                continue
            if inside:
                if line.startswith(");"):
                    break
                m = PORT_RE.match(line.rstrip("\n"))
                if m:
                    d, msb, lsb, name = m.groups()
                    out.append((d, int(msb) if msb else 0, int(lsb) if lsb else 0, name))
    if not out:
        sys.exit("ERROR: 没能从 %s 解析出端口表" % path)
    return out


def body(mod):
    src = open(os.path.join(GOLDEN, mod + ".sv")).read()
    b = src[src.index("module %s(" % mod):]
    return b[:b.index("\nendmodule")]


def decl(d, msb, lsb, name):
    w = "" if (msb == 0 and lsb == 0) else "[%d:%d] " % (msb, lsb)
    return "  %-7s %-9s %s" % (d, w, name)


def lit(msb, lsb):
    return "%d'h0" % (msb - lsb + 1)


def check_dups(mod, n_dups, width, names):
    """用 golden 的 `reg REG*;` 计数复核 N_DUPS（见文件头）。
    每 (lane, dup) 一个 REG，但 checkfullva 端口被折成常量的 lane 会整组消失。"""
    regs = len(re.findall(r'\breg\s+REG(?:_\d+)?\s*;', body(mod)))
    live = sum(1 for i in range(width)
               if "io_requestor_%d_req_bits_checkfullva" % i in names)
    if regs != live * n_dups:
        sys.exit("ERROR: %s 的 REG 计数 %d 与 (%d 条活 lane x N_DUPS %d) 对不上 —— "
                 "N_DUPS 的依据失效，停下来重新量" % (mod, regs, live, n_dups))
    return regs


def diff_index0(mod):
    m = re.search(r"wire\s+\[7:0\]\s+difftest_l1tlb_index = 8'h([0-9A-Fa-f]+);", body(mod))
    if not m:
        sys.exit("ERROR: %s 里找不到 difftest_l1tlb_index 常量" % mod)
    return int(m.group(1), 16)


def difftest_en(mod):
    # pftlb 的 Chisel 里写死 difftest.valid := false.B，firtool 折成字面量 1'h0
    return 0 if re.search(r"wire\s+difftest_l1tlb_valid = 1'h0;", body(mod)) else 1


def has_reg(mod, name):
    """golden 该变体里有没有这个名字的 `reg`。gate 掉"缺输入端口造成的消寄存器"
    用的就是这一条判据 —— 直接读 golden 的寄存器清单，不靠人抄矩阵。"""
    return re.search(r'^\s+reg\s+(?:\[\d+:\d+\]\s+)?%s\s*;' % re.escape(name),
                     body(mod), re.M) is not None


def reg_mask(mod, width, fmt):
    """fmt 里 {i} 代表 lane 号；lane0 的 golden 名字通常没有下标后缀，
    所以 fmt 允许写成 'noTranslateReg{sfx}'，{sfx} = '' / '_1' / '_2' ...
    两种写法都试，只要有一个在就算这条 lane 有。"""
    bits = []
    for i in range(width):
        cands = {fmt.format(i=i, sfx=("" if i == 0 else "_%d" % i))}
        bits.append(any(has_reg(mod, c) for c in cands))
    return "%d'b%s" % (width, "".join("1" if b else "0" for b in reversed(bits)))


def mask(width, pred):
    return "%d'b%s" % (width, "".join("1" if pred(i) else "0"
                                      for i in reversed(range(width))))


def gen(mod, stor_mod, inst_name, blurb):
    ports = read_ports(mod)
    names = {p[3] for p in ports}
    wmap = {p[3]: (p[1], p[2]) for p in ports}
    width = sum(1 for i in range(16) if "io_requestor_%d_req_valid" % i in names)
    nd = N_DUPS[mod]
    nreg = check_dups(mod, nd, width, names)
    idx0 = diff_index0(mod)
    dten = difftest_en(mod)
    bores = sorted(int(re.match(r"gatewayIn_packed_(\d+)_bore", n).group(1))
                   for n in names if n.startswith("gatewayIn_packed_"))
    assert len(bores) == width, (mod, bores, width)
    stor_names = {p[3] for p in read_ports(stor_mod)}

    has = lambda i, f: ("io_requestor_%d_%s" % (i, f)) in names
    L = []
    L.append("// BEGIN GENERATED(tlbnb-wrapper) —— scripts/gen_tlbnb_family.py 生成，勿手改")
    L.append("module %s import tlbnb_pkg::*; (" % mod)
    L.append(",\n".join(decl(*p) for p in ports))
    L.append(");")
    L.append("")
    L.append("  // ---- 本变体参数（推导依据见 scripts/gen_tlbnb_family.py 的文件头）----")
    L.append("  localparam int W = %d;            // requestor 通道数" % width)
    L.append("  localparam int ND = %d;           // nRespDups（golden REG 计数复核过：%d 个）"
             % (nd, nreg))
    L.append("")

    # ---------------- DelayN：sfence / csr 各延迟 fenceDelay=2 拍 ----------------
    L.append("  // ---- sfence / CSR 各延迟 2 拍（fenceDelay）：刷 TLB 要等流水线里的旧访存走完 ----")
    for n, w in [("valid", 0), ("bits_rs1", 0), ("bits_rs2", 0), ("bits_addr", 50),
                 ("bits_id", 16), ("bits_hv", 0), ("bits_hg", 0)]:
        L.append("  wire %s sfd_%s;" % ("" if w == 0 else "[%d:0]" % (w - 1), n))
    for f, _ in CSR_FIELDS:
        msb, lsb = wmap.get("io_csr_" + f, (0, 0))
        L.append("  wire %s csrd_%s;" % ("" if msb == lsb == 0 else "[%d:%d]" % (msb, lsb), f))
    L.append("  wire csrd_mbmc_BME, csrd_mbmc_CMODE;")
    L.append("")
    L.append("  DelayN_9 sfence_delay (")
    L.append("    .clock                 (clock),")
    for n in ["valid", "bits_rs1", "bits_rs2", "bits_addr", "bits_id",
              "bits_flushPipe", "bits_hv", "bits_hg"]:
        L.append("    .io_in_%-16s (io_sfence_%s)," % (n, n))
    for n in ["valid", "bits_rs1", "bits_rs2", "bits_addr", "bits_id"]:
        L.append("    .io_out_%-15s (sfd_%s)," % (n, n))
    L.append("    .io_out_bits_flushPipe (/* golden 也不接：非阻塞 TLB 不看 flushPipe */),")
    L.append("    .io_out_bits_hv        (sfd_bits_hv),")
    L.append("    .io_out_bits_hg        (sfd_bits_hg)")
    L.append("  );")
    L.append("  DelayN_7 csr_delay (")
    L.append("    .clock (clock),")
    allcsr = [f for f, _ in CSR_FIELDS] + ["mbmc_BME", "mbmc_CMODE", "priv_debug"]
    for f in allcsr:
        L.append("    .io_in_%-20s (io_csr_%s)," % (f, f))
    for f in allcsr:
        tgt = "/* golden 也不接 */" if f == "priv_debug" else "csrd_%s" % f
        L.append("    .io_out_%-19s (%s)%s" % (f, tgt, "," if f != allcsr[-1] else ""))
    L.append("  );")
    L.append("")

    # ---------------- 打包给核的两个 struct ----------------
    L.append("  // ---- 打包成核的两个 struct 端口 ----")
    L.append("  tlb_csr_t  csr_d;")
    L.append("  ptw_resp_t ptw_resp_w;")
    L.append("  always_comb begin")
    for f, out in CSR_FIELDS:
        L.append("    csr_d.%-18s = csrd_%s;" % (f, out))
    L.append("  end")
    L.append("  always_comb begin")
    for f in PTW_SCALARS:
        tgt = "get_gpa" if f == "getGpa" else f.replace("s1_", "s1.").replace("s2_", "s2.", 1)
        L.append("    ptw_resp_w.%-22s = io_ptw_resp_bits_%s;" % (tgt, f))
    for k in range(8):
        L.append("    ptw_resp_w.s1.ppn_low[%d]  = io_ptw_resp_bits_s1_ppn_low_%d;" % (k, k))
    for k in range(8):
        L.append("    ptw_resp_w.s1.valididx[%d] = io_ptw_resp_bits_s1_valididx_%d;" % (k, k))
    for k in range(8):
        L.append("    ptw_resp_w.s1.pteidx[%d]   = io_ptw_resp_bits_s1_pteidx_%d;" % (k, k))
    L.append("  end")
    L.append("")

    # ---------------- 核 <-> entries 的线 ----------------
    L.append("  // ---- 核与 entries（%s）之间的查询/回填线 ----" % stor_mod)
    L.append("  wire [W-1:0]              stor_r_req_valid;")
    L.append("  wire [W-1:0][VPN_W-1:0]   stor_r_req_vpn;")
    L.append("  wire [W-1:0][1:0]         stor_r_req_s2xlate;")
    L.append("  wire                      stor_w_valid;")
    L.append("  wire [W-1:0]              ent_hit;")
    L.append("  logic [W-1:0][ND-1:0][PPN_W-1:0] ent_ppn;")
    L.append("  logic [W-1:0][ND-1:0][1:0]       ent_pbmt;")
    L.append("  logic [W-1:0][ND-1:0][1:0]       ent_g_pbmt;")
    L.append("  logic [W-1:0][ND-1:0][1:0]       ent_s2xlate;")
    L.append("  tlb_perm_t  [W-1:0][ND-1:0]      ent_perm;")
    L.append("  tlb_gperm_t [W-1:0][ND-1:0]      ent_g_perm;")
    for i in range(width):
        L.append("  wire ent_hit_%d;" % i)
        for d in range(nd):
            for nm, w in [("ppn_%d" % d, 36)]:
                if "io_r_resp_%d_bits_%s" % (i, nm) in stor_names:
                    L.append("  wire [%d:0] ent_%d_%s;" % (w - 1, i, nm))
            for f in PERM_FIELDS:
                if "io_r_resp_%d_bits_perm_%d_%s" % (i, d, f) in stor_names:
                    L.append("  wire ent_%d_perm_%d_%s;" % (i, d, f))
            for f in GPERM_FIELDS:
                if "io_r_resp_%d_bits_g_perm_%d_%s" % (i, d, f) in stor_names:
                    L.append("  wire ent_%d_g_perm_%d_%s;" % (i, d, f))
            for nm in ["pbmt_%d" % d, "g_pbmt_%d" % d, "s2xlate_%d" % d]:
                if "io_r_resp_%d_bits_%s" % (i, nm) in stor_names:
                    L.append("  wire [1:0] ent_%d_%s;" % (i, nm))
    L.append("")
    for i in range(width):
        L.append("  assign ent_hit[%d] = ent_hit_%d;" % (i, i))
    L.append("")
    L.append("  // entries 在本变体里没给的字段（firtool 消掉了）一律补 0：")
    L.append("  // 它们只喂到核里同样没人读的那部分组合逻辑上（dup>0 的 pbmt / g_perm 等）。")
    L.append("  always_comb begin")
    L.append("    ent_ppn = '0; ent_pbmt = '0; ent_g_pbmt = '0;")
    L.append("    ent_s2xlate = '0; ent_perm = '0; ent_g_perm = '0;")
    for i in range(width):
        for d in range(nd):
            if "io_r_resp_%d_bits_ppn_%d" % (i, d) in stor_names:
                L.append("    ent_ppn[%d][%d] = ent_%d_ppn_%d;" % (i, d, i, d))
            for nm, tgt in [("pbmt_%d" % d, "ent_pbmt"), ("g_pbmt_%d" % d, "ent_g_pbmt"),
                            ("s2xlate_%d" % d, "ent_s2xlate")]:
                if "io_r_resp_%d_bits_%s" % (i, nm) in stor_names:
                    L.append("    %s[%d][%d] = ent_%d_%s;" % (tgt, i, d, i, nm))
            for f in PERM_FIELDS:
                if "io_r_resp_%d_bits_perm_%d_%s" % (i, d, f) in stor_names:
                    L.append("    ent_perm[%d][%d].%s = ent_%d_perm_%d_%s;" % (i, d, f, i, d, f))
            for f in GPERM_FIELDS:
                if "io_r_resp_%d_bits_g_perm_%d_%s" % (i, d, f) in stor_names:
                    L.append("    ent_g_perm[%d][%d].%s = ent_%d_g_perm_%d_%s;"
                             % (i, d, f, i, d, f))
    L.append("  end")
    L.append("")

    # ---------------- 核实例 ----------------
    L.append("  // ---- 可读核 ----")
    L.append("  logic [W-1:0]                     core_resp_valid, core_resp_miss;")
    L.append("  logic [W-1:0][PADDR_W-1:0]        core_pmp_addr;")
    L.append("  logic [W-1:0][ND-1:0][PADDR_W-1:0] core_paddr;")
    L.append("  logic [W-1:0][ND-1:0][XLEN-1:0]   core_gpaddr;")
    L.append("  logic [W-1:0][ND-1:0][1:0]        core_pbmt;")
    L.append("  logic [W-1:0][XLEN-1:0]           core_fullva;")
    L.append("  logic [W-1:0][MEMIDX_W-1:0]       core_memidx;")
    L.append("  logic [W-1:0] core_ptw_back, core_vsnl, core_pf_ld, core_pf_st;")
    L.append("  logic [W-1:0] core_gpf_ld, core_gpf_st, core_af_ld, core_af_st;")
    L.append("  logic [W-1:0] core_is_hyper, core_va_need_ext, core_tlbreplay;")
    L.append("  logic [W-1:0] core_ptw_req_valid, core_ptw_req_get_gpa, core_pmp_valid;")
    L.append("  logic [W-1:0][VPN_W-1:0] core_ptw_req_vpn;")
    L.append("  logic [W-1:0][1:0]       core_ptw_req_s2xlate, core_pmp_mode;")
    L.append("  logic [W-1:0][2:0]       core_pmp_cmd;")
    L.append("  logic [5:0] core_perf_access, core_perf_miss;")
    L.append("  logic [W-1:0][338:0] core_difftest;")
    L.append("")
    L.append("  xs_TLBNonBlock_core #(")
    L.append("    .W (W), .N_DUPS (ND),")
    L.append("    .HAS_GPADDR      (%s),  // resp.gpaddr(0) 端口在的 lane"
             % mask(width, lambda i: has(i, "resp_bits_gpaddr_0")))
    L.append("    .HAS_RESP_FULLVA (%s),  // resp.fullva 端口在的 lane"
             % mask(width, lambda i: has(i, "resp_bits_fullva")))
    L.append("    .HAS_MEMIDX      (%s),  // resp.memidx 端口在的 lane"
             % mask(width, lambda i: has(i, "resp_bits_memidx_idx")))
    L.append("    .HAS_ST_EXCP     (%s),  // excp(0).{pf,af}.st 端口在的 lane"
             % mask(width, lambda i: has(i, "resp_bits_excp_0_pf_st")))
    L.append("    .HAS_REQ_KILL    (%s),  // requestor.req_kill 端口在的 lane"
             % mask(width, lambda i: has(i, "req_kill")))
    # ---- 缺**输入**端口造成的逐 lane 消寄存器（判据 = golden 的 reg 清单）----
    L.append("    .HAS_FIRST_ISSUE (%s),  // golden 有 debug_isFirstIssue 端口的 lane"
             % mask(width, lambda i: has(i, "req_bits_debug_isFirstIssue")))
    L.append("    .HAS_ROBIDX      (%s),  // golden 有 reg req_out_<i>_debug_robIdx_flag"
             % reg_mask(mod, width, "req_out_{i}_debug_robIdx_flag"))
    L.append("    .HAS_FRM_MABUF   (%s),  // golden 有 reg req_out_<i>_frm_mabuf"
             % reg_mask(mod, width, "req_out_{i}_frm_mabuf"))
    L.append("    .HAS_HYPERINST   (%s),  // golden 有 reg req_out_<i>_hyperinst"
             % reg_mask(mod, width, "req_out_{i}_hyperinst"))
    L.append("    .HAS_HLVX        (%s),  // golden 有 reg req_out_<i>_hlvx"
             % reg_mask(mod, width, "req_out_{i}_hlvx"))
    L.append("    .HAS_NO_TRANSLATE(%s),  // golden 有 reg useReqS1Paddr_<i>"
             % reg_mask(mod, width, "useReqS1Paddr_{i}"))
    L.append("    .HAS_IS_PREFETCH (%s),  // golden 有 reg req_out_<i>_isPrefetch"
             % reg_mask(mod, width, "req_out_{i}_isPrefetch"))
    L.append("    .HAS_PRE_EXCP    (%s),  // golden 有 reg ..._excp_0_pf_ld_REG"
             % reg_mask(mod, width,
                        "io_requestor_{i}_resp_bits_excp_0_pf_ld_REG"))
    L.append("    .HAS_TLBREPLAY   (1'b%d)," % (1 if "io_tlbreplay_0" in names else 0))
    L.append("    .HAS_PERF        (1'b%d)," % (1 if "io_perf_0_value" in names else 0))
    L.append("    .DIFFTEST_EN     (1'b%d)," % dten)
    L.append("    .DIFF_INDEX_0    (%d)" % idx0)
    L.append("  ) u_core (")
    L.append("    .clock (clock), .reset (reset),")
    L.append("    .sfence_valid_d (sfd_valid), .csr (csr_d), .hart_id (io_hartId),")
    L.append("    .redirect_valid (io_redirect_valid),")
    L.append("    .redirect_robidx_flag (io_redirect_bits_robIdx_flag),")
    L.append("    .redirect_robidx_value (io_redirect_bits_robIdx_value),")
    L.append("    .redirect_level (io_redirect_bits_level),")
    L.append("    .rob_pending_flag (io_robPendingPtr_flag),")
    L.append("    .rob_pending_value (io_robPendingPtr_value),")
    for g, core, const in REQ_IN:
        elems = []
        for i in reversed(range(width)):
            elems.append("io_requestor_%d_%s" % (i, g) if has(i, g) else const)
        L.append("    .%-12s ({%s})," % (core, ", ".join(elems)))
    L.append("    .resp_valid (core_resp_valid), .resp_miss (core_resp_miss),")
    L.append("    .resp_paddr (core_paddr), .resp_gpaddr (core_gpaddr),")
    L.append("    .resp_pbmt (core_pbmt), .resp_fullva (core_fullva),")
    L.append("    .resp_memidx (core_memidx), .resp_ptw_back (core_ptw_back),")
    L.append("    .resp_is_for_vs_non_leaf_pte (core_vsnl),")
    L.append("    .resp_excp_pf_ld (core_pf_ld), .resp_excp_pf_st (core_pf_st),")
    L.append("    .resp_excp_gpf_ld (core_gpf_ld), .resp_excp_gpf_st (core_gpf_st),")
    L.append("    .resp_excp_af_ld (core_af_ld), .resp_excp_af_st (core_af_st),")
    L.append("    .resp_excp_is_hyper (core_is_hyper),")
    L.append("    .resp_excp_va_need_ext (core_va_need_ext),")
    L.append("    .ptw_req_valid (core_ptw_req_valid), .ptw_req_vpn (core_ptw_req_vpn),")
    L.append("    .ptw_req_s2xlate (core_ptw_req_s2xlate),")
    L.append("    .ptw_req_get_gpa (core_ptw_req_get_gpa),")
    L.append("    .ptw_resp_valid (io_ptw_resp_valid), .ptw_resp (ptw_resp_w),")
    L.append("    .pmp_valid (core_pmp_valid), .pmp_addr (core_pmp_addr),")
    L.append("    .pmp_cmd (core_pmp_cmd), .pmp_mode (core_pmp_mode),")
    L.append("    .tlbreplay (core_tlbreplay),")
    L.append("    .perf_access (core_perf_access), .perf_miss (core_perf_miss),")
    L.append("    .stor_r_req_valid (stor_r_req_valid), .stor_r_req_vpn (stor_r_req_vpn),")
    L.append("    .stor_r_req_s2xlate (stor_r_req_s2xlate), .stor_r_hit (ent_hit),")
    L.append("    .stor_r_ppn (ent_ppn), .stor_r_pbmt (ent_pbmt),")
    L.append("    .stor_r_g_pbmt (ent_g_pbmt), .stor_r_perm (ent_perm),")
    L.append("    .stor_r_g_perm (ent_g_perm), .stor_r_s2xlate (ent_s2xlate),")
    L.append("    .stor_w_valid (stor_w_valid), .difftest_packed (core_difftest)")
    L.append("  );")
    L.append("")

    # ---------------- entries 实例 ----------------
    L.append("  // ---- 全相联页表项存储（本层不碰内容，只把查询/回填接过去）----")
    L.append("  %s entries (" % stor_mod)
    L.append("    .clock (clock), .reset (reset),")
    for n in ["valid", "bits_rs1", "bits_rs2", "bits_addr", "bits_id", "bits_hv", "bits_hg"]:
        L.append("    .io_sfence_%-12s (sfd_%s)," % (n, n))
    for f in ["satp_asid", "vsatp_asid", "hgatp_vmid", "mbmc_BME", "mbmc_CMODE", "priv_virt"]:
        L.append("    .io_csr_%-15s (csrd_%s)," % (f, f))
    for i in range(width):
        L.append("    .io_r_req_%d_valid        (stor_r_req_valid[%d])," % (i, i))
        L.append("    .io_r_req_%d_bits_vpn     (stor_r_req_vpn[%d])," % (i, i))
        L.append("    .io_r_req_%d_bits_s2xlate (stor_r_req_s2xlate[%d])," % (i, i))
    for i in range(width):
        L.append("    .io_r_resp_%d_bits_hit    (ent_hit_%d)," % (i, i))
        for d in range(nd):
            for nm in ["ppn_%d" % d, "pbmt_%d" % d, "g_pbmt_%d" % d]:
                if "io_r_resp_%d_bits_%s" % (i, nm) in stor_names:
                    L.append("    .io_r_resp_%d_bits_%-13s (ent_%d_%s)," % (i, nm, i, nm))
            for f in PERM_FIELDS:
                nm = "perm_%d_%s" % (d, f)
                if "io_r_resp_%d_bits_%s" % (i, nm) in stor_names:
                    L.append("    .io_r_resp_%d_bits_%-13s (ent_%d_%s)," % (i, nm, i, nm))
            for f in GPERM_FIELDS:
                nm = "g_perm_%d_%s" % (d, f)
                if "io_r_resp_%d_bits_%s" % (i, nm) in stor_names:
                    L.append("    .io_r_resp_%d_bits_%-13s (ent_%d_%s)," % (i, nm, i, nm))
            nm = "s2xlate_%d" % d
            if "io_r_resp_%d_bits_%s" % (i, nm) in stor_names:
                L.append("    .io_r_resp_%d_bits_%-13s (ent_%d_%s)," % (i, nm, i, nm))
    L.append("    .io_w_valid (stor_w_valid),")
    wports = [p for p in read_ports(stor_mod) if p[3].startswith("io_w_bits_data_")]
    for k, (_, _, _, n) in enumerate(wports):
        suffix = n[len("io_w_bits_data_"):]
        L.append("    .%-34s (io_ptw_resp_bits_%s)%s"
                 % (n, suffix, "," if k != len(wports) - 1 else ""))
    L.append("  );")
    L.append("")

    # ---------------- 输出 ----------------
    L.append("  // ---- 核 -> golden 扁平输出端口 ----")
    L.append("  // 核算出来但本变体没有端口的字段就不接（firtool 在 golden 里也消掉了）。")
    core_of = {
        "resp_valid": "core_resp_valid[{i}]", "resp_bits_miss": "core_resp_miss[{i}]",
        "resp_bits_paddr_0": "core_paddr[{i}][0]", "resp_bits_paddr_1": "core_paddr[{i}][1]",
        "resp_bits_gpaddr_0": "core_gpaddr[{i}][0]", "resp_bits_pbmt_0": "core_pbmt[{i}][0]",
        "resp_bits_fullva": "core_fullva[{i}]", "resp_bits_memidx_idx": "core_memidx[{i}]",
        "resp_bits_ptwBack": "core_ptw_back[{i}]",
        "resp_bits_isForVSnonLeafPTE": "core_vsnl[{i}]",
        "resp_bits_excp_0_pf_ld": "core_pf_ld[{i}]",
        "resp_bits_excp_0_pf_st": "core_pf_st[{i}]",
        "resp_bits_excp_0_gpf_ld": "core_gpf_ld[{i}]",
        "resp_bits_excp_0_gpf_st": "core_gpf_st[{i}]",
        "resp_bits_excp_0_af_ld": "core_af_ld[{i}]",
        "resp_bits_excp_0_af_st": "core_af_st[{i}]",
        "resp_bits_excp_0_isHyper": "core_is_hyper[{i}]",
        "resp_bits_excp_0_vaNeedExt": "core_va_need_ext[{i}]",
    }
    for i in range(width):
        for g, _ in REQ_OUT:
            if has(i, g):
                L.append("  assign io_requestor_%d_%s = %s;"
                         % (i, g, core_of[g].format(i=i)))
        for g, expr in [("io_ptw_req_%d_valid", "core_ptw_req_valid[%d]"),
                        ("io_ptw_req_%d_bits_vpn", "core_ptw_req_vpn[%d]"),
                        ("io_ptw_req_%d_bits_s2xlate", "core_ptw_req_s2xlate[%d]"),
                        ("io_ptw_req_%d_bits_getGpa", "core_ptw_req_get_gpa[%d]"),
                        ("io_pmp_%d_valid", "core_pmp_valid[%d]"),
                        ("io_pmp_%d_bits_addr", "core_pmp_addr[%d]"),
                        ("io_pmp_%d_bits_cmd", "core_pmp_cmd[%d]"),
                        ("io_pmpMode_%d", "core_pmp_mode[%d]"),
                        ("io_tlbreplay_%d", "core_tlbreplay[%d]")]:
            if (g % i) in names:
                L.append("  assign %s = %s;" % (g % i, expr % i))
        L.append("  assign gatewayIn_packed_%d_bore = core_difftest[%d];" % (bores[i], i))
    if "io_perf_0_value" in names:
        L.append("  assign io_perf_0_value = core_perf_access;")
        L.append("  assign io_perf_1_value = core_perf_miss;")
    L.append("")
    L.append("endmodule")
    L.append("// END GENERATED(tlbnb-wrapper)")

    head = [
        "// %s —— %s（TLBNonBlock 家族薄 wrapper）" % (mod, blurb),
        "//",
        "// 本变体 = MemBlock 里的 %s。逻辑全部在参数化可读核" % inst_name,
        "// xs_TLBNonBlock_core（同目录 xs_TLBNonBlock_core.sv）里；本文件只做三件事：",
        "//   1) 逐位抄 golden 的端口表；",
        "//   2) 例化 golden 子模块 DelayN_9 / DelayN_7 / %s；" % stor_mod,
        "//   3) 把扁平的 io_* 名接到核的按 lane 成组的向量端口上，缺席端口补常量/不接。",
        "//",
        "// 规模：golden %s.sv %d 行 / %d 端口（%d 输入、%d 输出），%d 个寄存器。"
        % (mod, len(open(os.path.join(GOLDEN, mod + '.sv')).readlines()), len(ports),
           sum(1 for p in ports if p[0] == 'input'),
           sum(1 for p in ports if p[0] == 'output'),
           len(re.findall(r'\breg\s+(?:\[\d+:\d+\]\s+)?[A-Za-z_][A-Za-z0-9_]*\s*;',
                          re.sub(r'`ifdef ENABLE_INITIAL_REG_.*?`endif // ENABLE_INITIAL_REG_',
                                 '', body(mod), flags=re.S)))),
        "// 参数：W=%d  nRespDups=%d  difftest %s（index 从 %d 起）"
        % (width, nd, "开" if dten else "关（pftlb 不参与 difftest）", idx0),
        "//",
        "// 端口表与接线由 scripts/gen_tlbnb_family.py 生成（GENERATED 标记之间），勿手改。",
        "",
    ]
    return "\n".join(head) + "\n".join(L) + "\n"


if __name__ == "__main__":
    for mod, stor, inst, blurb in VARIANTS:
        txt = gen(mod, stor, inst, blurb)
        path = os.path.join(OUT_DIR, mod + ".sv")
        old = open(path).read() if os.path.exists(path) else None
        if old != txt:
            open(path, "w").write(txt)
        print("%-16s -> %s (%d 行)" % (mod, path, txt.count("\n")))
