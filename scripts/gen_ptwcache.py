#!/usr/bin/env python3
# =============================================================================
# gen_ptwcache.py —— 生成 PtwCache_wrapper.sv（golden 同名 module PtwCache，364 端口）
#
# 思路：wrapper 例化「可读核 xs_PtwCache_core」+ golden 黑盒存储/DFT 子模块
#   （SplittedSRAM / SplittedSRAM_1 / MbistPipePtwL1 / MbistPipePtwL0 / ClockGate）。
# golden 的 SRAM 实例端口绑定里，凡是「读出数据」接到核输入、「写数据/读写使能/setIdx/
# waymask」接到核输出、bore/clock/reset 旁带原样穿通。
#
# 本脚本机械提取 golden 的：① 端口列表；② SRAM 读出 / ClockGate Q / childBd / bd 中间
# wire 声明；③ bd_*=boreChildrenBd_* 旁带赋值；④ 五个黑盒实例（读写端口重绑到核）。
# 然后拼出核实例。
#
# 用法：python3 scripts/gen_ptwcache.py > rtl/memblock/PtwCache_wrapper.sv
# =============================================================================
import re, sys, os

GOLDEN = os.environ.get("PTWC_GOLDEN",
    "/home/eda/xs-env/xs-v2r2-sv/golden/chisel-rtl/PtwCache.sv")

with open(GOLDEN) as f:
    G = f.read()
GL = G.splitlines()

def find_module_ports():
    start = next(i for i,l in enumerate(GL) if l.startswith("module PtwCache("))
    end   = next(i for i in range(start, len(GL)) if GL[i].strip() == ");")
    return GL[start:end+1]

ports = find_module_ports()

# ---- 提取一段实例（从 "<Mod> <inst> (" 到匹配的 ");"）----
def extract_instance(modname, instname):
    pat = re.compile(r"^\s*%s\s+%s\s+\($" % (re.escape(modname), re.escape(instname)))
    start = next(i for i,l in enumerate(GL) if pat.match(l))
    depth = 0
    for i in range(start, len(GL)):
        depth += GL[i].count("(") - GL[i].count(")")
        if depth == 0 and i > start:
            return start, i
    raise RuntimeError("inst not found: %s %s" % (modname, instname))

# ---- 提取 wire 声明（按前缀名集合）----
def collect_wire_decls(prefixes):
    out = []
    for l in GL:
        s = l.strip()
        if not s.startswith("wire"):
            continue
        m = re.match(r"wire\s*(\[[^\]]*\])?\s*([A-Za-z_][A-Za-z0-9_]*)", s)
        if not m: continue
        name = m.group(2)
        if any(name == p or name.startswith(p) for p in prefixes):
            # 去掉可能的 "= ..."（这些 wire 在 wrapper 里要么由实例驱动、要么旁带赋值）
            out.append((name, l))
    return out

# SRAM 读出数据 wire（核的输入）
l1_resp = [l for (n,l) in collect_wire_decls(["_l1_io_r_resp_data_"])]
l0_resp = [l for (n,l) in collect_wire_decls(["_l0_io_r_resp_data_"])]
cg_q    = [l for l in GL if re.search(r"wire\s+_ClockGate_(1_)?Q;", l)]

# childBd / bd 中间 wire 声明（黑盒间互连）。bd_* 含 boreChildrenBd 顶层旁带的本地别名。
def raw_decls_block():
    # childBd_* wire 声明：散落在 l1 实例后。直接收集所有 childBd_ 开头 wire 声明（无 =）。
    decls = []
    for l in GL:
        s = l.strip()
        if s.startswith("wire") and re.search(r"\bchildBd_", s) and "=" not in s:
            decls.append(l)
    # bd_outdata / bd_ack（MbistPipe 输出）
    for l in GL:
        s = l.strip()
        if s.startswith("wire") and re.match(r"wire\s+(\[[^\]]*\]\s+)?bd(_1)?_(outdata|ack);", s):
            decls.append(l)
    return decls

childbd_decls = raw_decls_block()

# bd_* = boreChildrenBd_* 旁带赋值（顶层输入 → mbist 输入）+ te_cgen
def bd_assigns():
    out = []
    for l in GL:
        s = l.strip()
        if re.match(r"wire\s+(\[[^\]]*\]\s+)?bd(_1)?_\w+\s*=\s*boreChildrenBd_", s):
            out.append(l)
        if re.match(r"wire\s+te_cgen\s*=\s*cg_bore_cgen", s):
            out.append(l)
    return out

bdas = bd_assigns()

# ---- 五个黑盒实例 ----
def grab(modname, instname):
    s,e = extract_instance(modname, instname)
    return GL[s:e+1]

l1_inst   = grab("SplittedSRAM", "l1")
l0_inst   = grab("SplittedSRAM_1", "l0")
mb1_inst  = grab("MbistPipePtwL1", "mbistPlL1")
mb0_inst  = grab("MbistPipePtwL0", "mbistPlL0")
cg0_inst  = grab("ClockGate", "ClockGate")
cg1_inst  = grab("ClockGate", "ClockGate_1")

# ---- 重绑 SRAM 实例的 io_r_req / io_w_req / clock 端口到核信号 ----
def rebind_sram(lines, which):
    # which in {"l1","l0"}
    ways = 2 if which=="l1" else 4
    out = []
    for l in lines:
        m = re.match(r"^(\s*)\.([A-Za-z0-9_]+)(\s*)\((.*)\),?\s*$", l)
        if not m:
            out.append(l); continue
        ind, port, sp, _val = m.groups()
        new = None
        if port == "clock":
            new = "_ClockGate_Q" if which=="l0" else "_ClockGate_1_Q"
        elif port == "reset":
            new = "reset"
        elif port == "io_r_req_valid":
            new = "%s_r_req_valid" % which
        elif port == "io_r_req_bits_setIdx":
            new = "%s_r_req_setIdx" % which
        elif port == "io_w_req_valid":
            new = "%s_w_req_valid" % which
        elif port == "io_w_req_bits_setIdx":
            new = "%s_w_req_setIdx" % which
        elif port == "io_w_req_bits_waymask":
            new = "%s_w_req_waymask" % which
        else:
            mr = re.match(r"io_r_resp_data_(\d+)_entries_(.+)", port)
            mw = re.match(r"io_w_req_bits_data_(\d+)_entries_(.+)", port)
            if mr:
                way, fld = mr.group(1), mr.group(2)
                new = "_%s_io_r_resp_data_%s_entries_%s" % (which, way, fld)
            elif mw:
                way, fld = int(mw.group(1)), mw.group(2)
                # L1 两 way 写同一份核 struct（waymask 选 way）；L0 四 way 同理
                new = wfield(which, fld)
            else:
                # bore 旁带原样
                out.append(l); continue
        comma = "," if l.rstrip().endswith(",") else ""
        out.append("%s.%s%s(%s)%s" % (ind, port, sp, new, comma))
    return out

# 核的写 struct 字段映射（io_w_req_bits_data_<way>_entries_<fld> -> core port 表达式）
def wfield(which, fld):
    base = "%s_w_req_data" % which
    msec = re.match(r"(pbmts|ppns|vs|onlypf)_(\d+)$", fld)
    mperm= re.match(r"perms_(\d+)_([dagxuwr])$", fld)
    if fld in ("tag","asid","vmid","prefetch"):
        return "%s.%s" % (base, fld)
    if msec:
        f, idx = msec.group(1), msec.group(2)
        return "%s.%s[%s]" % (base, f, idx)
    if mperm:
        sec, bit = mperm.group(1), mperm.group(2)
        return "%s.perm_%s[%s]" % (base, bit, sec)
    return "%s.%s" % (base, fld)

l1_inst_rb = rebind_sram(l1_inst, "l1")
l0_inst_rb = rebind_sram(l0_inst, "l0")

# ---- SRAM 读出 per-field wire → 核的 packed struct 数组 assign ----
def pack_resp_assigns():
    out = []
    # L1：2 way；字段：tag/asid/vmid/pbmts8/ppns8/vs8/onlypf8/prefetch（无 perm）
    for way in range(2):
        b = "l1_r_resp_data[%d]" % way
        s = "_l1_io_r_resp_data_%d_entries_" % way
        out.append("  assign %s.tag      = %stag;" % (b,s))
        out.append("  assign %s.asid     = %sasid;" % (b,s))
        out.append("  assign %s.vmid     = %svmid;" % (b,s))
        for i in range(8):
            out.append("  assign %s.pbmts[%d]  = %spbmts_%d;" % (b,i,s,i))
            out.append("  assign %s.ppns[%d]   = %sppns_%d;" % (b,i,s,i))
            out.append("  assign %s.vs[%d]     = %svs_%d;" % (b,i,s,i))
            out.append("  assign %s.onlypf[%d] = 1'b0;" % (b,i))  # L1 SRAM 无 onlypf 读出
        out.append("  assign %s.prefetch = %sprefetch;" % (b,s))
    # L0：4 way；额外 perm（perms_<sec>_<bit>）
    for way in range(4):
        b = "l0_r_resp_data[%d]" % way
        s = "_l0_io_r_resp_data_%d_entries_" % way
        out.append("  assign %s.tag      = %stag;" % (b,s))
        out.append("  assign %s.asid     = %sasid;" % (b,s))
        out.append("  assign %s.vmid     = %svmid;" % (b,s))
        for i in range(8):
            out.append("  assign %s.pbmts[%d]  = %spbmts_%d;" % (b,i,s,i))
            out.append("  assign %s.ppns[%d]   = %sppns_%d;" % (b,i,s,i))
            out.append("  assign %s.vs[%d]     = %svs_%d;" % (b,i,s,i))
            out.append("  assign %s.onlypf[%d] = %sonlypf_%d;" % (b,i,s,i))
            for bit in "daguxwr":
                out.append("  assign %s.perm_%s[%d] = %sperms_%d_%s;" % (b,bit,i,s,i,bit))
        out.append("  assign %s.prefetch = %sprefetch;" % (b,s))
    return out

# 注：L1 SRAM 无 onlypf 字段（非叶），核 l1_sram_entry_t 有 onlypf 占位，恒 0。

def gen_core_instance():
    L = []
    A = L.append
    # 总线打包 wire
    A("  // ---- CSR / sfence / req_info 总线打包 ----")
    A("  logic [2:0][15:0] csr_satp_asid_b, csr_vsatp_asid_b, csr_hgatp_vmid_b;")
    A("  logic [2:0]       csr_satp_chg_b, csr_vsatp_chg_b, csr_hgatp_chg_b, csr_priv_virt_b;")
    A("  logic [2:0][3:0]  csr_hgatp_mode_b;")
    for d in range(3):
        A("  assign csr_satp_asid_b[%d]  = io_csr_dup_%d_satp_asid;" % (d,d))
        A("  assign csr_vsatp_asid_b[%d] = io_csr_dup_%d_vsatp_asid;" % (d,d))
        A("  assign csr_hgatp_vmid_b[%d] = io_csr_dup_%d_hgatp_vmid[13:0];" % (d,d))
        A("  assign csr_satp_chg_b[%d]   = io_csr_dup_%d_satp_changed;" % (d,d))
        A("  assign csr_vsatp_chg_b[%d]  = io_csr_dup_%d_vsatp_changed;" % (d,d))
        A("  assign csr_hgatp_chg_b[%d]  = io_csr_dup_%d_hgatp_changed;" % (d,d))
        A("  assign csr_priv_virt_b[%d]  = io_csr_dup_%d_priv_virt;" % (d,d))
        A("  assign csr_hgatp_mode_b[%d] = io_csr_dup_%d_hgatp_mode;" % (d,d))
    A("  req_info_t req_info_b, refill_ri0_b, refill_ri1_b, refill_ri2_b;")
    A("  assign req_info_b.vpn = io_req_bits_req_info_vpn;")
    A("  assign req_info_b.s2xlate = io_req_bits_req_info_s2xlate;")
    A("  assign req_info_b.source  = io_req_bits_req_info_source;")
    for d in range(3):
        A("  assign refill_ri%d_b.vpn = io_refill_bits_req_info_dup_%d_vpn;" % (d,d))
        A("  assign refill_ri%d_b.s2xlate = io_refill_bits_req_info_dup_%d_s2xlate;" % (d,d))
        A("  assign refill_ri%d_b.source  = io_refill_bits_req_info_dup_%d_source;" % (d,d))
    A("  sfence_bits_t sfence0_b;")
    A("  assign sfence0_b.valid = io_sfence_dup_0_valid;")
    A("  assign sfence0_b.rs1   = io_sfence_dup_0_bits_rs1;")
    A("  assign sfence0_b.rs2   = io_sfence_dup_0_bits_rs2;")
    A("  assign sfence0_b.addr  = io_sfence_dup_0_bits_addr;")
    A("  assign sfence0_b.id    = io_sfence_dup_0_bits_id;")
    A("  assign sfence0_b.hv    = io_sfence_dup_0_bits_hv;")
    A("  assign sfence0_b.hg    = io_sfence_dup_0_bits_hg;")
    A("  ptwcache_resp_t        core_resp;")
    A("  logic [7:0][5:0]       core_perf;")
    A("  // L1/L0 SRAM 读写接口")
    A("  logic l1_r_req_valid; logic [2:0] l1_r_req_setIdx;  l1_sram_entry_t l1_r_resp_data [2];")
    A("  logic l1_w_req_valid; logic [2:0] l1_w_req_setIdx;  l1_sram_entry_t l1_w_req_data;  logic [1:0] l1_w_req_waymask;")
    A("  logic l0_r_req_valid; logic [4:0] l0_r_req_setIdx;  l0_sram_entry_t l0_r_resp_data [4];")
    A("  logic l0_w_req_valid; logic [4:0] l0_w_req_setIdx;  l0_sram_entry_t l0_w_req_data;  logic [3:0] l0_w_req_waymask;")
    A("  logic l0_clock_en, l1_clock_en;")
    A("")
    # SRAM resp packing
    L.extend(pack_resp_assigns())
    A("")
    # core instance
    A("  xs_PtwCache_core u_core (")
    A("    .clock(clock), .reset(reset),")
    A("    .csr_mPBMTE(io_csr_mPBMTE), .csr_hPBMTE(io_csr_hPBMTE),")
    A("    .csr_satp_asid(csr_satp_asid_b), .csr_satp_changed(csr_satp_chg_b),")
    A("    .csr_vsatp_asid(csr_vsatp_asid_b), .csr_vsatp_changed(csr_vsatp_chg_b),")
    A("    .csr_hgatp_mode(csr_hgatp_mode_b), .csr_hgatp_vmid(csr_hgatp_vmid_b),")
    A("    .csr_hgatp_changed(csr_hgatp_chg_b), .csr_priv_virt(csr_priv_virt_b),")
    A("    .req_ready(io_req_ready), .req_valid(io_req_valid), .req_info(req_info_b),")
    A("    .req_isFirst(io_req_bits_isFirst), .req_isHptwReq(io_req_bits_isHptwReq), .req_hptwId(io_req_bits_hptwId),")
    A("    .resp_ready(io_resp_ready), .resp_valid(io_resp_valid), .resp_bits(core_resp),")
    A("    .refill_valid(io_refill_valid), .refill_ptes(io_refill_bits_ptes),")
    A("    .refill_levelOH_sp(io_refill_bits_levelOH_sp), .refill_levelOH_l0(io_refill_bits_levelOH_l0),")
    A("    .refill_levelOH_l1(io_refill_bits_levelOH_l1), .refill_levelOH_l2(io_refill_bits_levelOH_l2),")
    A("    .refill_levelOH_l3(io_refill_bits_levelOH_l3),")
    A("    .refill_req_info_dup_0(refill_ri0_b), .refill_req_info_dup_1(refill_ri1_b), .refill_req_info_dup_2(refill_ri2_b),")
    A("    .refill_level_dup_0(io_refill_bits_level_dup_0), .refill_level_dup_2(io_refill_bits_level_dup_2),")
    A("    .refill_sel_pte_dup_0(io_refill_bits_sel_pte_dup_0), .refill_sel_pte_dup_2(io_refill_bits_sel_pte_dup_2),")
    A("    .sfence_dup_0(sfence0_b),")
    A("    .sfence_dup_1_valid(io_sfence_dup_1_valid), .sfence_dup_1_id(io_sfence_dup_1_bits_id),")
    A("    .sfence_dup_2_valid(io_sfence_dup_2_valid), .sfence_dup_2_rs1(io_sfence_dup_2_bits_rs1),")
    A("    .sfence_dup_2_rs2(io_sfence_dup_2_bits_rs2), .sfence_dup_2_id(io_sfence_dup_2_bits_id),")
    A("    .l1_r_req_valid(l1_r_req_valid), .l1_r_req_setIdx(l1_r_req_setIdx), .l1_r_resp_data(l1_r_resp_data),")
    A("    .l1_w_req_valid(l1_w_req_valid), .l1_w_req_setIdx(l1_w_req_setIdx), .l1_w_req_data(l1_w_req_data), .l1_w_req_waymask(l1_w_req_waymask),")
    A("    .l0_r_req_valid(l0_r_req_valid), .l0_r_req_setIdx(l0_r_req_setIdx), .l0_r_resp_data(l0_r_resp_data),")
    A("    .l0_w_req_valid(l0_w_req_valid), .l0_w_req_setIdx(l0_w_req_setIdx), .l0_w_req_data(l0_w_req_data), .l0_w_req_waymask(l0_w_req_waymask),")
    A("    .l0_clock_en(l0_clock_en), .l1_clock_en(l1_clock_en),")
    A("    .perf(core_perf)")
    A("  );")
    A("")
    # resp unpack
    L.extend(gen_resp_unpack())
    A("")
    for i in range(8):
        A("  assign io_perf_%d_value = core_perf[%d];" % (i,i))
    return "\n".join(L)

def gen_resp_unpack():
    o = []
    R = "core_resp"
    o.append("  // ---- core_resp 解包到 io_resp_bits_* ----")
    o.append("  assign io_resp_bits_req_info_vpn     = %s.req_info.vpn;" % R)
    o.append("  assign io_resp_bits_req_info_s2xlate = %s.req_info.s2xlate;" % R)
    o.append("  assign io_resp_bits_req_info_source  = %s.req_info.source;" % R)
    o.append("  assign io_resp_bits_isFirst   = %s.isFirst;" % R)
    o.append("  assign io_resp_bits_hit       = %s.hit;" % R)
    o.append("  assign io_resp_bits_prefetch  = %s.prefetch;" % R)
    o.append("  assign io_resp_bits_bypassed  = %s.bypassed;" % R)
    o.append("  assign io_resp_bits_toFsm_l3Hit = %s.toFsm_l3Hit;" % R)
    o.append("  assign io_resp_bits_toFsm_l2Hit = %s.toFsm_l2Hit;" % R)
    o.append("  assign io_resp_bits_toFsm_l1Hit = %s.toFsm_l1Hit;" % R)
    o.append("  assign io_resp_bits_toFsm_ppn   = %s.toFsm_ppn;" % R)
    o.append("  assign io_resp_bits_toFsm_stage1Hit = %s.toFsm_stage1Hit;" % R)
    for s in range(8):
        e = "%s.stage1_entry[%d]" % (R, s)
        p = "io_resp_bits_stage1_entry_%d" % s
        o.append("  assign %s_tag    = %s.tag;" % (p,e))
        o.append("  assign %s_asid   = %s.asid;" % (p,e))
        o.append("  assign %s_vmid   = %s.vmid;" % (p,e))
        o.append("  assign %s_n      = %s.n;" % (p,e))
        o.append("  assign %s_pbmt   = %s.pbmt;" % (p,e))
        for bit in "daguxwr":
            o.append("  assign %s_perm_%s = %s.perm.%s;" % (p,bit,e,bit))
        o.append("  assign %s_level  = %s.level;" % (p,e))
        o.append("  assign %s_v      = %s.v;" % (p,e))
        o.append("  assign %s_ppn    = %s.ppn;" % (p,e))
        o.append("  assign %s_ppn_low = %s.ppn_low;" % (p,e))
        o.append("  assign %s_pf     = %s.pf;" % (p,e))
    for i in range(8):
        o.append("  assign io_resp_bits_stage1_pteidx_%d = %s.stage1_pteidx[%d];" % (i,R,i))
    o.append("  assign io_resp_bits_stage1_not_super = %s.stage1_not_super;" % R)
    o.append("  assign io_resp_bits_isHptwReq = %s.isHptwReq;" % R)
    o.append("  assign io_resp_bits_toHptw_l3Hit = %s.toHptw_l3Hit;" % R)
    o.append("  assign io_resp_bits_toHptw_l2Hit = %s.toHptw_l2Hit;" % R)
    o.append("  assign io_resp_bits_toHptw_l1Hit = %s.toHptw_l1Hit;" % R)
    o.append("  assign io_resp_bits_toHptw_ppn   = %s.toHptw_ppn;" % R)
    o.append("  assign io_resp_bits_toHptw_id    = %s.toHptw_id;" % R)
    e = "%s.toHptw_entry" % R
    o.append("  assign io_resp_bits_toHptw_resp_entry_tag  = %s.tag;" % e)
    o.append("  assign io_resp_bits_toHptw_resp_entry_vmid = %s.vmid;" % e)
    o.append("  assign io_resp_bits_toHptw_resp_entry_n    = %s.n;" % e)
    o.append("  assign io_resp_bits_toHptw_resp_entry_pbmt = %s.pbmt;" % e)
    o.append("  assign io_resp_bits_toHptw_resp_entry_ppn  = %s.ppn;" % e)
    for bit in "daguxwr":
        o.append("  assign io_resp_bits_toHptw_resp_entry_perm_%s = %s.perm.%s;" % (bit,e,bit))
    o.append("  assign io_resp_bits_toHptw_resp_entry_level = %s.level;" % e)
    o.append("  assign io_resp_bits_toHptw_resp_gpf = %s.toHptw_gpf;" % R)
    o.append("  assign io_resp_bits_toHptw_bypassed = %s.toHptw_bypassed;" % R)
    return o

core_inst = gen_core_instance()

# ---- 组装输出 ----
# 模块名：默认 PtwCache（FM 用，golden 同名）；UT 用 PtwCache_xs（避免与 golden 重名）。
MODNAME = sys.argv[1] if len(sys.argv) > 1 else "PtwCache"

W = []
W.append("// 自动生成：scripts/gen_ptwcache.py —— golden 同名 PtwCache，例化可读核 xs_PtwCache_core")
W.append("//   + golden 黑盒 SplittedSRAM/SplittedSRAM_1/MbistPipePtwL1/L0/ClockGate。")
W.append("// 控制逻辑全在 xs_PtwCache_core（rtl/memblock/PtwCache.sv + ptwcache_*.svh）。")
W.append("module %s import xs_ptwcache_pkg::*; (" % MODNAME)
W += ports[1:]   # 去掉首行 "module PtwCache("（已替换为带 import）
W.append("")
W.append("  // ---- 黑盒间互连 / SRAM 读出 / ClockGate 中间 wire ----")
W += ["  " + l.strip() for l in cg_q]
W += ["  " + l.strip() for l in l1_resp]
W += ["  " + l.strip() for l in l0_resp]
W += ["  " + l.strip() for l in childbd_decls]
W.append("")
W.append("  // ---- DFT 旁带本地别名（顶层输入 → mbist 输入）----")
W += ["  " + l.strip() for l in bdas]
W.append("")
W.append("  // ---- DFT 旁带输出（mbist 输出 → 顶层输出）----")
W.append("  assign boreChildrenBd_bore_ack = bd_ack;")
W.append("  assign boreChildrenBd_bore_outdata = bd_outdata;")
W.append("  assign boreChildrenBd_bore_1_ack = bd_1_ack;")
W.append("  assign boreChildrenBd_bore_1_outdata = bd_1_outdata;")
W.append("")

# core 实例
W.append(core_inst)
W.append("")

# 黑盒实例
W.append("  // ===== golden 黑盒存储/DFT 子模块（UT/FM 两侧共用同一份 golden）=====")
W += l1_inst_rb
W += mb1_inst
W += l0_inst_rb
W += mb0_inst
W += cg0_inst
W += cg1_inst
W.append("")
W.append("endmodule")

sys.stdout.write("\n".join(W) + "\n")
