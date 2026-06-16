#!/usr/bin/env python3
"""
TLBNonBlock：生成 golden 同名 wrapper（FM/ST 用）+ _xs 镜像（UT 用）+ 随机比对 tb。

非阻塞 DTLB 顶层。wrapper 负责：
  - 把 golden 扁平端口 io_requestor_i_*/io_ptw_*/io_pmp_* 适配成可读核 xs_TLBNonBlock_core
    的 packed 数组端口（按端口 genvar 打包）；
  - 例化 golden 黑盒 DelayN_9（sfence 延迟 2 拍）/ DelayN_7（csr 延迟 2 拍）；
  - 例化 golden 黑盒 TlbStorageWrapper_1（全相联存储 + PLRU），接核的 s0 读口与回填使能；
  - 把存储读响应接回核做 s1 合成。

设计意图来自 src/main/scala/xiangshan/cache/mmu/TLB.scala（class TLBNonBlock）。
本脚本只做机械端口适配 + tb，可读核本体见 rtl/memblock/TLBNonBlock.sv。
"""
import re
from pathlib import Path

XSSV = Path(__file__).resolve().parent.parent
GOLDEN = XSSV / "golden/chisel-rtl"
W = 4


def golden_ports(name):
    text = (GOLDEN / f"{name}.sv").read_text()
    m = re.search(rf"^module {re.escape(name)}\((.*?)\n\);", text, re.S | re.M)
    res = []
    for line in m.group(1).splitlines():
        pm = re.match(r"\s*(input|output)\s+(?:\[(\d+):0\])?\s*(\w+),?\s*$", line)
        if pm:
            res.append((pm.group(1), int(pm.group(2)) + 1 if pm.group(2) else 1, pm.group(3)))
    return res


# --- 核端口（手写核的端口名/位宽，与 rtl/memblock/TLBNonBlock.sv 一致）---
# wrapper 内把 golden 扁平端口打包到这些端口。为简洁，wrapper 直接用 generate/assign 适配。

def build_wrapper(modname, core_inst):
    ps = golden_ports("TLBNonBlock")
    decls = []
    for d, w, n in ps:
        ws = f"[{w-1}:0] " if w > 1 else ""
        decls.append(f"  {d:6s} {ws}{n}")
    L = []
    L.append("// 自动生成：scripts/gen_tlbnonblock.py —— 勿手改")
    L.append(f"module {modname} import xs_tlbnb_pkg::*; (")
    L.append(",\n".join(decls))
    L.append(");")
    L.append(BODY.replace("__CORE__", core_inst))
    L.append("endmodule")
    return "\n".join(L) + "\n"


# wrapper body：DelayN 黑盒 + 打包 + 核例化 + 存储黑盒。
# entries 的 perm/gperm struct 字段顺序须与 pkg tlb_perm_t/tlb_gperm_t 一致：
#   tlb_perm_t  = {pf,af,v,d,a,u,x,w,r}
#   tlb_gperm_t = {pf,af,d,a,x,w,r}
BODY = r"""
  // ---- DelayN 黑盒：sfence / csr 延迟 fenceDelay=2 ----
  wire        sfd_valid, sfd_rs1, sfd_rs2, sfd_hv, sfd_hg, sfd_flushPipe;
  wire [49:0] sfd_addr; wire [15:0] sfd_id;
  DelayN_9 sfence_delay (.clock(clock),
    .io_in_valid(io_sfence_valid), .io_in_bits_rs1(io_sfence_bits_rs1),
    .io_in_bits_rs2(io_sfence_bits_rs2), .io_in_bits_addr(io_sfence_bits_addr),
    .io_in_bits_id(io_sfence_bits_id), .io_in_bits_flushPipe(io_sfence_bits_flushPipe),
    .io_in_bits_hv(io_sfence_bits_hv), .io_in_bits_hg(io_sfence_bits_hg),
    .io_out_valid(sfd_valid), .io_out_bits_rs1(sfd_rs1), .io_out_bits_rs2(sfd_rs2),
    .io_out_bits_addr(sfd_addr), .io_out_bits_id(sfd_id),
    .io_out_bits_flushPipe(sfd_flushPipe), .io_out_bits_hv(sfd_hv), .io_out_bits_hg(sfd_hg));

  wire [3:0]  cd_satp_mode, cd_vsatp_mode, cd_hgatp_mode;
  wire [15:0] cd_satp_asid, cd_vsatp_asid, cd_hgatp_vmid_16;
  wire        cd_satp_changed, cd_vsatp_changed, cd_hgatp_changed;
  wire        cd_mxr, cd_sum, cd_vmxr, cd_vsum, cd_virt, cd_spvp;
  wire [1:0]  cd_imode, cd_dmode, cd_mseccfg, cd_menvcfg, cd_henvcfg, cd_hstatus, cd_senvcfg;
  DelayN_7 csr_delay (.clock(clock),
    .io_in_satp_mode(io_csr_satp_mode), .io_in_satp_asid(io_csr_satp_asid),
    .io_in_satp_changed(io_csr_satp_changed), .io_in_vsatp_mode(io_csr_vsatp_mode),
    .io_in_vsatp_asid(io_csr_vsatp_asid), .io_in_vsatp_changed(io_csr_vsatp_changed),
    .io_in_hgatp_mode(io_csr_hgatp_mode), .io_in_hgatp_vmid(io_csr_hgatp_vmid),
    .io_in_hgatp_changed(io_csr_hgatp_changed), .io_in_priv_mxr(io_csr_priv_mxr),
    .io_in_priv_sum(io_csr_priv_sum), .io_in_priv_vmxr(io_csr_priv_vmxr),
    .io_in_priv_vsum(io_csr_priv_vsum), .io_in_priv_virt(io_csr_priv_virt),
    .io_in_priv_spvp(io_csr_priv_spvp), .io_in_priv_imode(io_csr_priv_imode),
    .io_in_priv_dmode(io_csr_priv_dmode), .io_in_pmm_mseccfg(io_csr_pmm_mseccfg),
    .io_in_pmm_menvcfg(io_csr_pmm_menvcfg), .io_in_pmm_henvcfg(io_csr_pmm_henvcfg),
    .io_in_pmm_hstatus(io_csr_pmm_hstatus), .io_in_pmm_senvcfg(io_csr_pmm_senvcfg),
    .io_out_satp_mode(cd_satp_mode), .io_out_satp_asid(cd_satp_asid),
    .io_out_satp_changed(cd_satp_changed), .io_out_vsatp_mode(cd_vsatp_mode),
    .io_out_vsatp_asid(cd_vsatp_asid), .io_out_vsatp_changed(cd_vsatp_changed),
    .io_out_hgatp_mode(cd_hgatp_mode), .io_out_hgatp_vmid(cd_hgatp_vmid_16),
    .io_out_hgatp_changed(cd_hgatp_changed), .io_out_priv_mxr(cd_mxr),
    .io_out_priv_sum(cd_sum), .io_out_priv_vmxr(cd_vmxr), .io_out_priv_vsum(cd_vsum),
    .io_out_priv_virt(cd_virt), .io_out_priv_spvp(cd_spvp), .io_out_priv_imode(cd_imode),
    .io_out_priv_dmode(cd_dmode), .io_out_pmm_mseccfg(cd_mseccfg),
    .io_out_pmm_menvcfg(cd_menvcfg), .io_out_pmm_henvcfg(cd_henvcfg),
    .io_out_pmm_hstatus(cd_hstatus), .io_out_pmm_senvcfg(cd_senvcfg));
  wire [13:0] cd_hgatp_vmid = cd_hgatp_vmid_16[13:0];

  // ---- 请求端口打包（golden 扁平 → 核数组）----
  logic [3:0]        req_valid, req_checkfullva, req_hyperinst, req_hlvx, req_kill;
  logic [3:0]        req_isPrefetch, req_no_translate, req_robIdx_flag, req_kill2;
  logic [3:0][49:0]  req_vaddr;
  logic [3:0][63:0]  req_fullva;
  logic [3:0][2:0]   req_cmd;
  logic [3:0][47:0]  req_pmp_addr;
  logic [3:0][7:0]   req_robIdx_value;

  assign req_valid       = {io_requestor_3_req_valid, io_requestor_2_req_valid, io_requestor_1_req_valid, io_requestor_0_req_valid};
  assign req_vaddr       = {io_requestor_3_req_bits_vaddr, io_requestor_2_req_bits_vaddr, io_requestor_1_req_bits_vaddr, io_requestor_0_req_bits_vaddr};
  assign req_fullva      = {io_requestor_3_req_bits_fullva, io_requestor_2_req_bits_fullva, io_requestor_1_req_bits_fullva, io_requestor_0_req_bits_fullva};
  assign req_checkfullva = {io_requestor_3_req_bits_checkfullva, io_requestor_2_req_bits_checkfullva, io_requestor_1_req_bits_checkfullva, io_requestor_0_req_bits_checkfullva};
  assign req_cmd         = {io_requestor_3_req_bits_cmd, io_requestor_2_req_bits_cmd, io_requestor_1_req_bits_cmd, io_requestor_0_req_bits_cmd};
  assign req_hyperinst   = {io_requestor_3_req_bits_hyperinst, io_requestor_2_req_bits_hyperinst, io_requestor_1_req_bits_hyperinst, io_requestor_0_req_bits_hyperinst};
  assign req_hlvx        = {io_requestor_3_req_bits_hlvx, io_requestor_2_req_bits_hlvx, io_requestor_1_req_bits_hlvx, io_requestor_0_req_bits_hlvx};
  assign req_kill        = {io_requestor_3_req_bits_kill, io_requestor_2_req_bits_kill, io_requestor_1_req_bits_kill, io_requestor_0_req_bits_kill};
  assign req_isPrefetch  = {io_requestor_3_req_bits_isPrefetch, io_requestor_2_req_bits_isPrefetch, io_requestor_1_req_bits_isPrefetch, io_requestor_0_req_bits_isPrefetch};
  assign req_no_translate= {io_requestor_3_req_bits_no_translate, io_requestor_2_req_bits_no_translate, io_requestor_1_req_bits_no_translate, io_requestor_0_req_bits_no_translate};
  assign req_pmp_addr    = {io_requestor_3_req_bits_pmp_addr, io_requestor_2_req_bits_pmp_addr, io_requestor_1_req_bits_pmp_addr, io_requestor_0_req_bits_pmp_addr};
  assign req_robIdx_flag = {io_requestor_3_req_bits_debug_robIdx_flag, io_requestor_2_req_bits_debug_robIdx_flag, io_requestor_1_req_bits_debug_robIdx_flag, io_requestor_0_req_bits_debug_robIdx_flag};
  assign req_robIdx_value= {io_requestor_3_req_bits_debug_robIdx_value, io_requestor_2_req_bits_debug_robIdx_value, io_requestor_1_req_bits_debug_robIdx_value, io_requestor_0_req_bits_debug_robIdx_value};
  // 端口 3 无 s1 kill（io_requestor_3_req_kill）：tie 0
  assign req_kill2       = {1'b0, io_requestor_2_req_kill, io_requestor_1_req_kill, io_requestor_0_req_kill};

  // ---- s0 读口（核 → 存储）----
  wire [3:0]        e_rreq_valid;
  wire [3:0][37:0]  e_rreq_vpn;
  wire [3:0][1:0]   e_rreq_s2xlate;

  // ---- 存储读响应（存储 → 核），按端口打包 ----
  wire [3:0]        e_hit;
  wire [3:0][35:0]  e_ppn0, e_ppn1;
  wire [3:0][1:0]   e_pbmt, e_gpbmt, e_s2xlate;
  tlb_perm_t [3:0]  e_perm0, e_perm1;
  tlb_gperm_t [3:0] e_gperm0;

  // golden 黑盒 TlbStorageWrapper_1 的逐字段读响应 net
  wire e0_hit; wire [35:0] e0_ppn0,e0_ppn1; wire [1:0] e0_pbmt,e0_gpbmt,e0_s2x;
  wire e0_p0_pf,e0_p0_af,e0_p0_v,e0_p0_d,e0_p0_a,e0_p0_u,e0_p0_x,e0_p0_w,e0_p0_r;
  wire e0_p1_pf,e0_p1_af,e0_p1_v,e0_p1_x,e0_p1_w,e0_p1_r;
  wire e0_g_pf,e0_g_af,e0_g_d,e0_g_a,e0_g_x,e0_g_w,e0_g_r;
  wire e1_hit; wire [35:0] e1_ppn0,e1_ppn1; wire [1:0] e1_pbmt,e1_gpbmt,e1_s2x;
  wire e1_p0_pf,e1_p0_af,e1_p0_v,e1_p0_d,e1_p0_a,e1_p0_u,e1_p0_x,e1_p0_w,e1_p0_r;
  wire e1_p1_pf,e1_p1_af,e1_p1_v,e1_p1_x,e1_p1_w,e1_p1_r;
  wire e1_g_pf,e1_g_af,e1_g_d,e1_g_a,e1_g_x,e1_g_w,e1_g_r;
  wire e2_hit; wire [35:0] e2_ppn0,e2_ppn1; wire [1:0] e2_pbmt,e2_gpbmt,e2_s2x;
  wire e2_p0_pf,e2_p0_af,e2_p0_v,e2_p0_d,e2_p0_a,e2_p0_u,e2_p0_x,e2_p0_w,e2_p0_r;
  wire e2_p1_pf,e2_p1_af,e2_p1_v,e2_p1_x,e2_p1_w,e2_p1_r;
  wire e2_g_pf,e2_g_af,e2_g_d,e2_g_a,e2_g_x,e2_g_w,e2_g_r;
  wire e3_hit; wire [35:0] e3_ppn0; wire [1:0] e3_pbmt,e3_gpbmt;
  wire e3_p0_pf,e3_p0_af,e3_p0_v,e3_p0_d,e3_p0_a,e3_p0_u,e3_p0_x,e3_p0_w,e3_p0_r;
  wire e3_g_pf,e3_g_af,e3_g_d,e3_g_a,e3_g_x,e3_g_w,e3_g_r;

  // 端口 3 存储无 ppn_1/perm_1/s2xlate（firtool 裁剪），用 ppn0/0 占位
  assign e_hit    = {e3_hit, e2_hit, e1_hit, e0_hit};
  assign e_ppn0   = {e3_ppn0, e2_ppn0, e1_ppn0, e0_ppn0};
  assign e_ppn1   = {e3_ppn0, e2_ppn1, e1_ppn1, e0_ppn1};
  assign e_pbmt   = {e3_pbmt, e2_pbmt, e1_pbmt, e0_pbmt};
  assign e_gpbmt  = {e3_gpbmt, e2_gpbmt, e1_gpbmt, e0_gpbmt};
  assign e_s2xlate= {2'h0, e2_s2x, e1_s2x, e0_s2x};
  assign e_perm0[0] = '{pf:e0_p0_pf,af:e0_p0_af,v:e0_p0_v,d:e0_p0_d,a:e0_p0_a,u:e0_p0_u,x:e0_p0_x,w:e0_p0_w,r:e0_p0_r};
  assign e_perm0[1] = '{pf:e1_p0_pf,af:e1_p0_af,v:e1_p0_v,d:e1_p0_d,a:e1_p0_a,u:e1_p0_u,x:e1_p0_x,w:e1_p0_w,r:e1_p0_r};
  assign e_perm0[2] = '{pf:e2_p0_pf,af:e2_p0_af,v:e2_p0_v,d:e2_p0_d,a:e2_p0_a,u:e2_p0_u,x:e2_p0_x,w:e2_p0_w,r:e2_p0_r};
  assign e_perm0[3] = '{pf:e3_p0_pf,af:e3_p0_af,v:e3_p0_v,d:e3_p0_d,a:e3_p0_a,u:e3_p0_u,x:e3_p0_x,w:e3_p0_w,r:e3_p0_r};
  // perm dup1 仅含 pf/af/v/x/w/r（d/a/u 不用，置 0）
  assign e_perm1[0] = '{pf:e0_p1_pf,af:e0_p1_af,v:e0_p1_v,d:1'b0,a:1'b0,u:1'b0,x:e0_p1_x,w:e0_p1_w,r:e0_p1_r};
  assign e_perm1[1] = '{pf:e1_p1_pf,af:e1_p1_af,v:e1_p1_v,d:1'b0,a:1'b0,u:1'b0,x:e1_p1_x,w:e1_p1_w,r:e1_p1_r};
  assign e_perm1[2] = '{pf:e2_p1_pf,af:e2_p1_af,v:e2_p1_v,d:1'b0,a:1'b0,u:1'b0,x:e2_p1_x,w:e2_p1_w,r:e2_p1_r};
  assign e_perm1[3] = '0;  // 端口 3 无 dup1
  assign e_gperm0[0] = '{pf:e0_g_pf,af:e0_g_af,d:e0_g_d,a:e0_g_a,x:e0_g_x,w:e0_g_w,r:e0_g_r};
  assign e_gperm0[1] = '{pf:e1_g_pf,af:e1_g_af,d:e1_g_d,a:e1_g_a,x:e1_g_x,w:e1_g_w,r:e1_g_r};
  assign e_gperm0[2] = '{pf:e2_g_pf,af:e2_g_af,d:e2_g_d,a:e2_g_a,x:e2_g_x,w:e2_g_w,r:e2_g_r};
  assign e_gperm0[3] = '{pf:e3_g_pf,af:e3_g_af,d:e3_g_d,a:e3_g_a,x:e3_g_x,w:e3_g_w,r:e3_g_r};

  // ---- s1 ppn_low 数组（核要 [0:7]）----
  wire [2:0] ppn_low_arr [0:7];
  assign ppn_low_arr[0]=io_ptw_resp_bits_s1_ppn_low_0; assign ppn_low_arr[1]=io_ptw_resp_bits_s1_ppn_low_1;
  assign ppn_low_arr[2]=io_ptw_resp_bits_s1_ppn_low_2; assign ppn_low_arr[3]=io_ptw_resp_bits_s1_ppn_low_3;
  assign ppn_low_arr[4]=io_ptw_resp_bits_s1_ppn_low_4; assign ppn_low_arr[5]=io_ptw_resp_bits_s1_ppn_low_5;
  assign ppn_low_arr[6]=io_ptw_resp_bits_s1_ppn_low_6; assign ppn_low_arr[7]=io_ptw_resp_bits_s1_ppn_low_7;
  wire [7:0] valididx_v = {io_ptw_resp_bits_s1_valididx_7,io_ptw_resp_bits_s1_valididx_6,io_ptw_resp_bits_s1_valididx_5,io_ptw_resp_bits_s1_valididx_4,io_ptw_resp_bits_s1_valididx_3,io_ptw_resp_bits_s1_valididx_2,io_ptw_resp_bits_s1_valididx_1,io_ptw_resp_bits_s1_valididx_0};
  wire [7:0] pteidx_v   = {io_ptw_resp_bits_s1_pteidx_7,io_ptw_resp_bits_s1_pteidx_6,io_ptw_resp_bits_s1_pteidx_5,io_ptw_resp_bits_s1_pteidx_4,io_ptw_resp_bits_s1_pteidx_3,io_ptw_resp_bits_s1_pteidx_2,io_ptw_resp_bits_s1_pteidx_1,io_ptw_resp_bits_s1_pteidx_0};

  // ---- 核 resp 输出（数组）拆回 golden 扁平端口 ----
  wire [3:0]        o_valid, o_miss, o_isForVS, o_vaNeedExt, o_isHyper;
  wire [3:0]        o_gpf_ld, o_gpf_st, o_pf_ld, o_pf_st, o_af_ld, o_af_st;
  wire [3:0][47:0]  o_paddr0, o_paddr1;
  wire [3:0][63:0]  o_gpaddr0, o_fullva;
  wire [3:0][1:0]   o_pbmt0;
  wire [3:0]        o_pmp_valid; wire [3:0][47:0] o_pmp_addr; wire [3:0][2:0] o_pmp_cmd;
  wire [3:0]        o_ptw_valid, o_ptw_getGpa, o_replay;
  wire [3:0][37:0]  o_ptw_vpn; wire [3:0][1:0] o_ptw_s2x;
  wire              o_refill;

  __CORE__ u_core (
    .clock(clock), .reset(reset),
    .io_sfd_valid(sfd_valid), .io_sfd_flushPipe(sfd_flushPipe),
    .io_csrd_satp_mode(cd_satp_mode), .io_csrd_satp_asid(cd_satp_asid), .io_csrd_satp_changed(cd_satp_changed),
    .io_csrd_vsatp_mode(cd_vsatp_mode), .io_csrd_vsatp_asid(cd_vsatp_asid), .io_csrd_vsatp_changed(cd_vsatp_changed),
    .io_csrd_hgatp_mode(cd_hgatp_mode), .io_csrd_hgatp_vmid(cd_hgatp_vmid), .io_csrd_hgatp_changed(cd_hgatp_changed),
    .io_csrd_priv_mxr(cd_mxr), .io_csrd_priv_sum(cd_sum), .io_csrd_priv_vmxr(cd_vmxr), .io_csrd_priv_vsum(cd_vsum),
    .io_csrd_priv_virt(cd_virt), .io_csrd_priv_spvp(cd_spvp), .io_csrd_priv_imode(cd_imode), .io_csrd_priv_dmode(cd_dmode),
    .io_csrd_pmm_mseccfg(cd_mseccfg), .io_csrd_pmm_menvcfg(cd_menvcfg), .io_csrd_pmm_henvcfg(cd_henvcfg),
    .io_csrd_pmm_hstatus(cd_hstatus), .io_csrd_pmm_senvcfg(cd_senvcfg),
    .io_req_valid(req_valid), .io_req_vaddr(req_vaddr), .io_req_fullva(req_fullva),
    .io_req_checkfullva(req_checkfullva), .io_req_cmd(req_cmd), .io_req_hyperinst(req_hyperinst),
    .io_req_hlvx(req_hlvx), .io_req_kill(req_kill), .io_req_isPrefetch(req_isPrefetch),
    .io_req_no_translate(req_no_translate), .io_req_pmp_addr(req_pmp_addr),
    .io_req_robIdx_flag(req_robIdx_flag), .io_req_robIdx_value(req_robIdx_value), .io_req_kill2(req_kill2),
    .io_redirect_valid(io_redirect_valid), .io_redirect_robIdx_flag(io_redirect_bits_robIdx_flag),
    .io_redirect_robIdx_value(io_redirect_bits_robIdx_value), .io_redirect_level(io_redirect_bits_level),
    .io_entries_hit(e_hit), .io_entries_ppn_0(e_ppn0), .io_entries_ppn_1(e_ppn1),
    .io_entries_pbmt(e_pbmt), .io_entries_g_pbmt(e_gpbmt),
    .io_entries_perm0(e_perm0), .io_entries_perm1(e_perm1), .io_entries_gperm0(e_gperm0),
    .io_entries_s2xlate(e_s2xlate),
    .io_entries_rreq_valid(e_rreq_valid), .io_entries_rreq_vpn(e_rreq_vpn), .io_entries_rreq_s2xlate(e_rreq_s2xlate),
    .io_ptw_resp_valid(io_ptw_resp_valid), .io_ptw_resp_s2xlate(io_ptw_resp_bits_s2xlate),
    .io_ptw_resp_s1_entry_tag(io_ptw_resp_bits_s1_entry_tag), .io_ptw_resp_s1_entry_asid(io_ptw_resp_bits_s1_entry_asid),
    .io_ptw_resp_s1_entry_vmid(io_ptw_resp_bits_s1_entry_vmid), .io_ptw_resp_s1_entry_n(io_ptw_resp_bits_s1_entry_n),
    .io_ptw_resp_s1_entry_pbmt(io_ptw_resp_bits_s1_entry_pbmt), .io_ptw_resp_s1_entry_perm_d(io_ptw_resp_bits_s1_entry_perm_d),
    .io_ptw_resp_s1_entry_perm_a(io_ptw_resp_bits_s1_entry_perm_a), .io_ptw_resp_s1_entry_perm_g(io_ptw_resp_bits_s1_entry_perm_g),
    .io_ptw_resp_s1_entry_perm_u(io_ptw_resp_bits_s1_entry_perm_u), .io_ptw_resp_s1_entry_perm_x(io_ptw_resp_bits_s1_entry_perm_x),
    .io_ptw_resp_s1_entry_perm_w(io_ptw_resp_bits_s1_entry_perm_w), .io_ptw_resp_s1_entry_perm_r(io_ptw_resp_bits_s1_entry_perm_r),
    .io_ptw_resp_s1_entry_level(io_ptw_resp_bits_s1_entry_level), .io_ptw_resp_s1_entry_v(io_ptw_resp_bits_s1_entry_v),
    .io_ptw_resp_s1_entry_ppn(io_ptw_resp_bits_s1_entry_ppn), .io_ptw_resp_s1_addr_low(io_ptw_resp_bits_s1_addr_low),
    .io_ptw_resp_s1_ppn_low_flat(8'h0), .io_ptw_resp_s1_ppn_low(ppn_low_arr),
    .io_ptw_resp_s1_valididx(valididx_v), .io_ptw_resp_s1_pteidx(pteidx_v),
    .io_ptw_resp_s1_pf(io_ptw_resp_bits_s1_pf), .io_ptw_resp_s1_af(io_ptw_resp_bits_s1_af),
    .io_ptw_resp_s2_entry_tag(io_ptw_resp_bits_s2_entry_tag), .io_ptw_resp_s2_entry_vmid(io_ptw_resp_bits_s2_entry_vmid),
    .io_ptw_resp_s2_entry_n(io_ptw_resp_bits_s2_entry_n), .io_ptw_resp_s2_entry_pbmt(io_ptw_resp_bits_s2_entry_pbmt),
    .io_ptw_resp_s2_entry_ppn(io_ptw_resp_bits_s2_entry_ppn), .io_ptw_resp_s2_entry_perm_d(io_ptw_resp_bits_s2_entry_perm_d),
    .io_ptw_resp_s2_entry_perm_a(io_ptw_resp_bits_s2_entry_perm_a), .io_ptw_resp_s2_entry_perm_g(io_ptw_resp_bits_s2_entry_perm_g),
    .io_ptw_resp_s2_entry_perm_u(io_ptw_resp_bits_s2_entry_perm_u), .io_ptw_resp_s2_entry_perm_x(io_ptw_resp_bits_s2_entry_perm_x),
    .io_ptw_resp_s2_entry_perm_w(io_ptw_resp_bits_s2_entry_perm_w), .io_ptw_resp_s2_entry_perm_r(io_ptw_resp_bits_s2_entry_perm_r),
    .io_ptw_resp_s2_entry_level(io_ptw_resp_bits_s2_entry_level), .io_ptw_resp_s2_gpf(io_ptw_resp_bits_s2_gpf),
    .io_ptw_resp_s2_gaf(io_ptw_resp_bits_s2_gaf), .io_ptw_resp_getGpa(io_ptw_resp_bits_getGpa),
    .io_refill_valid(o_refill),
    .io_resp_valid(o_valid), .io_resp_paddr0(o_paddr0), .io_resp_paddr1(o_paddr1),
    .io_resp_gpaddr0(o_gpaddr0), .io_resp_fullva(o_fullva), .io_resp_pbmt0(o_pbmt0),
    .io_resp_miss(o_miss), .io_resp_isForVSnonLeafPTE(o_isForVS), .io_resp_excp_vaNeedExt(o_vaNeedExt),
    .io_resp_excp_isHyper(o_isHyper), .io_resp_excp_gpf_ld(o_gpf_ld), .io_resp_excp_gpf_st(o_gpf_st),
    .io_resp_excp_pf_ld(o_pf_ld), .io_resp_excp_pf_st(o_pf_st), .io_resp_excp_af_ld(o_af_ld), .io_resp_excp_af_st(o_af_st),
    .io_pmp_valid(o_pmp_valid), .io_pmp_addr(o_pmp_addr), .io_pmp_cmd(o_pmp_cmd),
    .io_ptw_req_valid(o_ptw_valid), .io_ptw_req_vpn(o_ptw_vpn), .io_ptw_req_s2xlate(o_ptw_s2x),
    .io_ptw_req_getGpa(o_ptw_getGpa), .io_tlbreplay(o_replay)
  );

  // ---- golden 黑盒 TlbStorageWrapper_1（存储 + PLRU）----
  TlbStorageWrapper_1 entries (
    .clock(clock), .reset(reset),
    .io_sfence_valid(sfd_valid), .io_sfence_bits_rs1(sfd_rs1), .io_sfence_bits_rs2(sfd_rs2),
    .io_sfence_bits_addr(sfd_addr), .io_sfence_bits_id(sfd_id), .io_sfence_bits_hv(sfd_hv), .io_sfence_bits_hg(sfd_hg),
    .io_csr_satp_asid(cd_satp_asid), .io_csr_vsatp_asid(cd_vsatp_asid),
    .io_csr_hgatp_vmid(cd_hgatp_vmid), .io_csr_priv_virt(cd_virt),
    .io_r_req_0_valid(e_rreq_valid[0]), .io_r_req_0_bits_vpn(e_rreq_vpn[0]), .io_r_req_0_bits_s2xlate(e_rreq_s2xlate[0]),
    .io_r_req_1_valid(e_rreq_valid[1]), .io_r_req_1_bits_vpn(e_rreq_vpn[1]), .io_r_req_1_bits_s2xlate(e_rreq_s2xlate[1]),
    .io_r_req_2_valid(e_rreq_valid[2]), .io_r_req_2_bits_vpn(e_rreq_vpn[2]), .io_r_req_2_bits_s2xlate(e_rreq_s2xlate[2]),
    .io_r_req_3_valid(e_rreq_valid[3]), .io_r_req_3_bits_vpn(e_rreq_vpn[3]), .io_r_req_3_bits_s2xlate(e_rreq_s2xlate[3]),
    .io_r_resp_0_bits_hit(e0_hit), .io_r_resp_0_bits_ppn_0(e0_ppn0), .io_r_resp_0_bits_ppn_1(e0_ppn1),
    .io_r_resp_0_bits_pbmt_0(e0_pbmt), .io_r_resp_0_bits_g_pbmt_0(e0_gpbmt),
    .io_r_resp_0_bits_perm_0_pf(e0_p0_pf), .io_r_resp_0_bits_perm_0_af(e0_p0_af), .io_r_resp_0_bits_perm_0_v(e0_p0_v),
    .io_r_resp_0_bits_perm_0_d(e0_p0_d), .io_r_resp_0_bits_perm_0_a(e0_p0_a), .io_r_resp_0_bits_perm_0_u(e0_p0_u),
    .io_r_resp_0_bits_perm_0_x(e0_p0_x), .io_r_resp_0_bits_perm_0_w(e0_p0_w), .io_r_resp_0_bits_perm_0_r(e0_p0_r),
    .io_r_resp_0_bits_perm_1_pf(e0_p1_pf), .io_r_resp_0_bits_perm_1_af(e0_p1_af), .io_r_resp_0_bits_perm_1_v(e0_p1_v),
    .io_r_resp_0_bits_perm_1_x(e0_p1_x), .io_r_resp_0_bits_perm_1_w(e0_p1_w), .io_r_resp_0_bits_perm_1_r(e0_p1_r),
    .io_r_resp_0_bits_g_perm_0_pf(e0_g_pf), .io_r_resp_0_bits_g_perm_0_af(e0_g_af), .io_r_resp_0_bits_g_perm_0_d(e0_g_d),
    .io_r_resp_0_bits_g_perm_0_a(e0_g_a), .io_r_resp_0_bits_g_perm_0_x(e0_g_x), .io_r_resp_0_bits_g_perm_0_w(e0_g_w),
    .io_r_resp_0_bits_g_perm_0_r(e0_g_r), .io_r_resp_0_bits_s2xlate_0(e0_s2x),
    .io_r_resp_1_bits_hit(e1_hit), .io_r_resp_1_bits_ppn_0(e1_ppn0), .io_r_resp_1_bits_ppn_1(e1_ppn1),
    .io_r_resp_1_bits_pbmt_0(e1_pbmt), .io_r_resp_1_bits_g_pbmt_0(e1_gpbmt),
    .io_r_resp_1_bits_perm_0_pf(e1_p0_pf), .io_r_resp_1_bits_perm_0_af(e1_p0_af), .io_r_resp_1_bits_perm_0_v(e1_p0_v),
    .io_r_resp_1_bits_perm_0_d(e1_p0_d), .io_r_resp_1_bits_perm_0_a(e1_p0_a), .io_r_resp_1_bits_perm_0_u(e1_p0_u),
    .io_r_resp_1_bits_perm_0_x(e1_p0_x), .io_r_resp_1_bits_perm_0_w(e1_p0_w), .io_r_resp_1_bits_perm_0_r(e1_p0_r),
    .io_r_resp_1_bits_perm_1_pf(e1_p1_pf), .io_r_resp_1_bits_perm_1_af(e1_p1_af), .io_r_resp_1_bits_perm_1_v(e1_p1_v),
    .io_r_resp_1_bits_perm_1_x(e1_p1_x), .io_r_resp_1_bits_perm_1_w(e1_p1_w), .io_r_resp_1_bits_perm_1_r(e1_p1_r),
    .io_r_resp_1_bits_g_perm_0_pf(e1_g_pf), .io_r_resp_1_bits_g_perm_0_af(e1_g_af), .io_r_resp_1_bits_g_perm_0_d(e1_g_d),
    .io_r_resp_1_bits_g_perm_0_a(e1_g_a), .io_r_resp_1_bits_g_perm_0_x(e1_g_x), .io_r_resp_1_bits_g_perm_0_w(e1_g_w),
    .io_r_resp_1_bits_g_perm_0_r(e1_g_r), .io_r_resp_1_bits_s2xlate_0(e1_s2x),
    .io_r_resp_2_bits_hit(e2_hit), .io_r_resp_2_bits_ppn_0(e2_ppn0), .io_r_resp_2_bits_ppn_1(e2_ppn1),
    .io_r_resp_2_bits_pbmt_0(e2_pbmt), .io_r_resp_2_bits_g_pbmt_0(e2_gpbmt),
    .io_r_resp_2_bits_perm_0_pf(e2_p0_pf), .io_r_resp_2_bits_perm_0_af(e2_p0_af), .io_r_resp_2_bits_perm_0_v(e2_p0_v),
    .io_r_resp_2_bits_perm_0_d(e2_p0_d), .io_r_resp_2_bits_perm_0_a(e2_p0_a), .io_r_resp_2_bits_perm_0_u(e2_p0_u),
    .io_r_resp_2_bits_perm_0_x(e2_p0_x), .io_r_resp_2_bits_perm_0_w(e2_p0_w), .io_r_resp_2_bits_perm_0_r(e2_p0_r),
    .io_r_resp_2_bits_perm_1_pf(e2_p1_pf), .io_r_resp_2_bits_perm_1_af(e2_p1_af), .io_r_resp_2_bits_perm_1_v(e2_p1_v),
    .io_r_resp_2_bits_perm_1_x(e2_p1_x), .io_r_resp_2_bits_perm_1_w(e2_p1_w), .io_r_resp_2_bits_perm_1_r(e2_p1_r),
    .io_r_resp_2_bits_g_perm_0_pf(e2_g_pf), .io_r_resp_2_bits_g_perm_0_af(e2_g_af), .io_r_resp_2_bits_g_perm_0_d(e2_g_d),
    .io_r_resp_2_bits_g_perm_0_a(e2_g_a), .io_r_resp_2_bits_g_perm_0_x(e2_g_x), .io_r_resp_2_bits_g_perm_0_w(e2_g_w),
    .io_r_resp_2_bits_g_perm_0_r(e2_g_r), .io_r_resp_2_bits_s2xlate_0(e2_s2x),
    .io_r_resp_3_bits_hit(e3_hit), .io_r_resp_3_bits_ppn_0(e3_ppn0),
    .io_r_resp_3_bits_pbmt_0(e3_pbmt), .io_r_resp_3_bits_g_pbmt_0(e3_gpbmt),
    .io_r_resp_3_bits_perm_0_pf(e3_p0_pf), .io_r_resp_3_bits_perm_0_af(e3_p0_af), .io_r_resp_3_bits_perm_0_v(e3_p0_v),
    .io_r_resp_3_bits_perm_0_d(e3_p0_d), .io_r_resp_3_bits_perm_0_a(e3_p0_a), .io_r_resp_3_bits_perm_0_u(e3_p0_u),
    .io_r_resp_3_bits_perm_0_x(e3_p0_x), .io_r_resp_3_bits_perm_0_w(e3_p0_w), .io_r_resp_3_bits_perm_0_r(e3_p0_r),
    .io_r_resp_3_bits_g_perm_0_pf(e3_g_pf), .io_r_resp_3_bits_g_perm_0_af(e3_g_af), .io_r_resp_3_bits_g_perm_0_d(e3_g_d),
    .io_r_resp_3_bits_g_perm_0_a(e3_g_a), .io_r_resp_3_bits_g_perm_0_x(e3_g_x), .io_r_resp_3_bits_g_perm_0_w(e3_g_w),
    .io_r_resp_3_bits_g_perm_0_r(e3_g_r),
    .io_w_valid(o_refill),
    .io_w_bits_data_s2xlate(io_ptw_resp_bits_s2xlate),
    .io_w_bits_data_s1_entry_tag(io_ptw_resp_bits_s1_entry_tag), .io_w_bits_data_s1_entry_asid(io_ptw_resp_bits_s1_entry_asid),
    .io_w_bits_data_s1_entry_vmid(io_ptw_resp_bits_s1_entry_vmid), .io_w_bits_data_s1_entry_n(io_ptw_resp_bits_s1_entry_n),
    .io_w_bits_data_s1_entry_pbmt(io_ptw_resp_bits_s1_entry_pbmt), .io_w_bits_data_s1_entry_perm_d(io_ptw_resp_bits_s1_entry_perm_d),
    .io_w_bits_data_s1_entry_perm_a(io_ptw_resp_bits_s1_entry_perm_a), .io_w_bits_data_s1_entry_perm_g(io_ptw_resp_bits_s1_entry_perm_g),
    .io_w_bits_data_s1_entry_perm_u(io_ptw_resp_bits_s1_entry_perm_u), .io_w_bits_data_s1_entry_perm_x(io_ptw_resp_bits_s1_entry_perm_x),
    .io_w_bits_data_s1_entry_perm_w(io_ptw_resp_bits_s1_entry_perm_w), .io_w_bits_data_s1_entry_perm_r(io_ptw_resp_bits_s1_entry_perm_r),
    .io_w_bits_data_s1_entry_level(io_ptw_resp_bits_s1_entry_level), .io_w_bits_data_s1_entry_v(io_ptw_resp_bits_s1_entry_v),
    .io_w_bits_data_s1_entry_ppn(io_ptw_resp_bits_s1_entry_ppn),
    .io_w_bits_data_s1_ppn_low_0(io_ptw_resp_bits_s1_ppn_low_0), .io_w_bits_data_s1_ppn_low_1(io_ptw_resp_bits_s1_ppn_low_1),
    .io_w_bits_data_s1_ppn_low_2(io_ptw_resp_bits_s1_ppn_low_2), .io_w_bits_data_s1_ppn_low_3(io_ptw_resp_bits_s1_ppn_low_3),
    .io_w_bits_data_s1_ppn_low_4(io_ptw_resp_bits_s1_ppn_low_4), .io_w_bits_data_s1_ppn_low_5(io_ptw_resp_bits_s1_ppn_low_5),
    .io_w_bits_data_s1_ppn_low_6(io_ptw_resp_bits_s1_ppn_low_6), .io_w_bits_data_s1_ppn_low_7(io_ptw_resp_bits_s1_ppn_low_7),
    .io_w_bits_data_s1_valididx_0(io_ptw_resp_bits_s1_valididx_0), .io_w_bits_data_s1_valididx_1(io_ptw_resp_bits_s1_valididx_1),
    .io_w_bits_data_s1_valididx_2(io_ptw_resp_bits_s1_valididx_2), .io_w_bits_data_s1_valididx_3(io_ptw_resp_bits_s1_valididx_3),
    .io_w_bits_data_s1_valididx_4(io_ptw_resp_bits_s1_valididx_4), .io_w_bits_data_s1_valididx_5(io_ptw_resp_bits_s1_valididx_5),
    .io_w_bits_data_s1_valididx_6(io_ptw_resp_bits_s1_valididx_6), .io_w_bits_data_s1_valididx_7(io_ptw_resp_bits_s1_valididx_7),
    .io_w_bits_data_s1_pteidx_0(io_ptw_resp_bits_s1_pteidx_0), .io_w_bits_data_s1_pteidx_1(io_ptw_resp_bits_s1_pteidx_1),
    .io_w_bits_data_s1_pteidx_2(io_ptw_resp_bits_s1_pteidx_2), .io_w_bits_data_s1_pteidx_3(io_ptw_resp_bits_s1_pteidx_3),
    .io_w_bits_data_s1_pteidx_4(io_ptw_resp_bits_s1_pteidx_4), .io_w_bits_data_s1_pteidx_5(io_ptw_resp_bits_s1_pteidx_5),
    .io_w_bits_data_s1_pteidx_6(io_ptw_resp_bits_s1_pteidx_6), .io_w_bits_data_s1_pteidx_7(io_ptw_resp_bits_s1_pteidx_7),
    .io_w_bits_data_s1_pf(io_ptw_resp_bits_s1_pf), .io_w_bits_data_s1_af(io_ptw_resp_bits_s1_af),
    .io_w_bits_data_s2_entry_tag(io_ptw_resp_bits_s2_entry_tag), .io_w_bits_data_s2_entry_vmid(io_ptw_resp_bits_s2_entry_vmid),
    .io_w_bits_data_s2_entry_n(io_ptw_resp_bits_s2_entry_n), .io_w_bits_data_s2_entry_pbmt(io_ptw_resp_bits_s2_entry_pbmt),
    .io_w_bits_data_s2_entry_ppn(io_ptw_resp_bits_s2_entry_ppn), .io_w_bits_data_s2_entry_perm_d(io_ptw_resp_bits_s2_entry_perm_d),
    .io_w_bits_data_s2_entry_perm_a(io_ptw_resp_bits_s2_entry_perm_a), .io_w_bits_data_s2_entry_perm_g(io_ptw_resp_bits_s2_entry_perm_g),
    .io_w_bits_data_s2_entry_perm_u(io_ptw_resp_bits_s2_entry_perm_u), .io_w_bits_data_s2_entry_perm_x(io_ptw_resp_bits_s2_entry_perm_x),
    .io_w_bits_data_s2_entry_perm_w(io_ptw_resp_bits_s2_entry_perm_w), .io_w_bits_data_s2_entry_perm_r(io_ptw_resp_bits_s2_entry_perm_r),
    .io_w_bits_data_s2_entry_level(io_ptw_resp_bits_s2_entry_level),
    .io_w_bits_data_s2_gpf(io_ptw_resp_bits_s2_gpf), .io_w_bits_data_s2_gaf(io_ptw_resp_bits_s2_gaf)
  );

  // ---- 核 resp 数组拆回 golden 扁平输出 ----
  assign io_requestor_0_resp_valid = o_valid[0];
  assign io_requestor_0_resp_bits_paddr_0 = o_paddr0[0];
  assign io_requestor_0_resp_bits_paddr_1 = o_paddr1[0];
  assign io_requestor_0_resp_bits_gpaddr_0 = o_gpaddr0[0];
  assign io_requestor_0_resp_bits_fullva = o_fullva[0];
  assign io_requestor_0_resp_bits_pbmt_0 = o_pbmt0[0];
  assign io_requestor_0_resp_bits_miss = o_miss[0];
  assign io_requestor_0_resp_bits_isForVSnonLeafPTE = o_isForVS[0];
  assign io_requestor_0_resp_bits_excp_0_vaNeedExt = o_vaNeedExt[0];
  assign io_requestor_0_resp_bits_excp_0_isHyper = o_isHyper[0];
  assign io_requestor_0_resp_bits_excp_0_gpf_ld = o_gpf_ld[0];
  assign io_requestor_0_resp_bits_excp_0_gpf_st = o_gpf_st[0];
  assign io_requestor_0_resp_bits_excp_0_pf_ld = o_pf_ld[0];
  assign io_requestor_0_resp_bits_excp_0_pf_st = o_pf_st[0];
  assign io_requestor_0_resp_bits_excp_0_af_ld = o_af_ld[0];
  assign io_requestor_0_resp_bits_excp_0_af_st = o_af_st[0];
  assign io_requestor_1_resp_valid = o_valid[1];
  assign io_requestor_1_resp_bits_paddr_0 = o_paddr0[1];
  assign io_requestor_1_resp_bits_paddr_1 = o_paddr1[1];
  assign io_requestor_1_resp_bits_gpaddr_0 = o_gpaddr0[1];
  assign io_requestor_1_resp_bits_fullva = o_fullva[1];
  assign io_requestor_1_resp_bits_pbmt_0 = o_pbmt0[1];
  assign io_requestor_1_resp_bits_miss = o_miss[1];
  assign io_requestor_1_resp_bits_isForVSnonLeafPTE = o_isForVS[1];
  assign io_requestor_1_resp_bits_excp_0_vaNeedExt = o_vaNeedExt[1];
  assign io_requestor_1_resp_bits_excp_0_isHyper = o_isHyper[1];
  assign io_requestor_1_resp_bits_excp_0_gpf_ld = o_gpf_ld[1];
  assign io_requestor_1_resp_bits_excp_0_pf_ld = o_pf_ld[1];
  assign io_requestor_1_resp_bits_excp_0_af_ld = o_af_ld[1];
  assign io_requestor_2_resp_valid = o_valid[2];
  assign io_requestor_2_resp_bits_paddr_0 = o_paddr0[2];
  assign io_requestor_2_resp_bits_paddr_1 = o_paddr1[2];
  assign io_requestor_2_resp_bits_gpaddr_0 = o_gpaddr0[2];
  assign io_requestor_2_resp_bits_fullva = o_fullva[2];
  assign io_requestor_2_resp_bits_pbmt_0 = o_pbmt0[2];
  assign io_requestor_2_resp_bits_miss = o_miss[2];
  assign io_requestor_2_resp_bits_isForVSnonLeafPTE = o_isForVS[2];
  assign io_requestor_2_resp_bits_excp_0_vaNeedExt = o_vaNeedExt[2];
  assign io_requestor_2_resp_bits_excp_0_isHyper = o_isHyper[2];
  assign io_requestor_2_resp_bits_excp_0_gpf_ld = o_gpf_ld[2];
  assign io_requestor_2_resp_bits_excp_0_pf_ld = o_pf_ld[2];
  assign io_requestor_2_resp_bits_excp_0_af_ld = o_af_ld[2];
  assign io_requestor_3_resp_valid = o_valid[3];
  assign io_requestor_3_resp_bits_paddr_0 = o_paddr0[3];
  assign io_requestor_3_resp_bits_pbmt_0 = o_pbmt0[3];
  assign io_requestor_3_resp_bits_miss = o_miss[3];
  assign io_requestor_3_resp_bits_excp_0_gpf_ld = o_gpf_ld[3];
  assign io_requestor_3_resp_bits_excp_0_pf_ld = o_pf_ld[3];
  assign io_requestor_3_resp_bits_excp_0_af_ld = o_af_ld[3];
  assign io_ptw_req_0_valid = o_ptw_valid[0]; assign io_ptw_req_0_bits_vpn = o_ptw_vpn[0];
  assign io_ptw_req_0_bits_s2xlate = o_ptw_s2x[0]; assign io_ptw_req_0_bits_getGpa = o_ptw_getGpa[0];
  assign io_ptw_req_1_valid = o_ptw_valid[1]; assign io_ptw_req_1_bits_vpn = o_ptw_vpn[1];
  assign io_ptw_req_1_bits_s2xlate = o_ptw_s2x[1]; assign io_ptw_req_1_bits_getGpa = o_ptw_getGpa[1];
  assign io_ptw_req_2_valid = o_ptw_valid[2]; assign io_ptw_req_2_bits_vpn = o_ptw_vpn[2];
  assign io_ptw_req_2_bits_s2xlate = o_ptw_s2x[2]; assign io_ptw_req_2_bits_getGpa = o_ptw_getGpa[2];
  assign io_ptw_req_3_valid = o_ptw_valid[3]; assign io_ptw_req_3_bits_vpn = o_ptw_vpn[3];
  assign io_ptw_req_3_bits_s2xlate = o_ptw_s2x[3]; assign io_ptw_req_3_bits_getGpa = o_ptw_getGpa[3];
  assign io_pmp_0_valid = o_pmp_valid[0]; assign io_pmp_0_bits_addr = o_pmp_addr[0]; assign io_pmp_0_bits_cmd = o_pmp_cmd[0];
  assign io_pmp_1_valid = o_pmp_valid[1]; assign io_pmp_1_bits_addr = o_pmp_addr[1]; assign io_pmp_1_bits_cmd = o_pmp_cmd[1];
  assign io_pmp_2_valid = o_pmp_valid[2]; assign io_pmp_2_bits_addr = o_pmp_addr[2]; assign io_pmp_2_bits_cmd = o_pmp_cmd[2];
  assign io_pmp_3_valid = o_pmp_valid[3]; assign io_pmp_3_bits_addr = o_pmp_addr[3]; assign io_pmp_3_bits_cmd = o_pmp_cmd[3];
  assign io_tlbreplay_0 = o_replay[0]; assign io_tlbreplay_1 = o_replay[1];
  assign io_tlbreplay_2 = o_replay[2]; assign io_tlbreplay_3 = o_replay[3];
"""


def build_tb(ps):
    ins  = [(w, n) for d, w, n in ps if d == "input" and n not in ("clock", "reset")]
    outs = [(w, n) for d, w, n in ps if d == "output"]
    T = ["// 自动生成：scripts/gen_tlbnonblock.py —— 勿手改",
         "`timescale 1ns/1ps", "module tb;",
         "  int unsigned NCYCLES = 200000;",
         "  bit clk=0, rst; int errors=0, checks=0;",
         "  always #5 clk = ~clk;"]
    for w, n in ins:
        T.append(f"  logic {('['+str(w-1)+':0] ') if w>1 else ''}{n};")
    for w, n in outs:
        ws = ('['+str(w-1)+':0] ') if w > 1 else ''
        T.append(f"  wire {ws}g_{n};")
        T.append(f"  wire {ws}i_{n};")
    gc = [".clock(clk)", ".reset(rst)"] + [f".{n}({n})" for _, n in ins]
    gg = gc + [f".{n}(g_{n})" for _, n in outs]
    ig = gc + [f".{n}(i_{n})" for _, n in outs]
    T.append(f"  TLBNonBlock    u_g ({', '.join(gg)});")
    T.append(f"  TLBNonBlock_xs u_i ({', '.join(ig)});")

    # 随机激励：valid 类调慢些覆盖空闲；地址压窄高位以提高跨端口/PTW 命中。
    valid_rate = {
        "io_ptw_resp_valid": "($urandom_range(0,3)==0)",
        "io_redirect_valid": "($urandom_range(0,15)==0)",
        "io_sfence_valid":   "($urandom_range(0,63)==0)",
        "io_csr_satp_changed":"($urandom_range(0,63)==0)",
        "io_csr_vsatp_changed":"($urandom_range(0,63)==0)",
        "io_csr_hgatp_changed":"($urandom_range(0,63)==0)",
    }
    for i in range(4):
        valid_rate[f"io_requestor_{i}_req_valid"] = "($urandom_range(0,1))"
        valid_rate[f"io_requestor_{i}_req_bits_kill"] = "($urandom_range(0,7)==0)"
        valid_rate[f"io_requestor_{i}_req_kill"] = "($urandom_range(0,7)==0)"

    def rnd(w, n):
        if n in valid_rate:
            return valid_rate[n]
        # csr 模式：取 0/8/9 覆盖 Sv39/Sv48/关
        if n.endswith("satp_mode") or n.endswith("hgatp_mode"):
            return "(4'($urandom_range(0,2))*4'h8 + (($urandom_range(0,2)==2)?4'h1:4'h0))"
        if "vaddr" in n or "fullva" in n:
            return f"{{{w-12}'($urandom_range(0,7)), 12'($urandom)}}"
        if w == 1:
            return "$urandom_range(0,1)"
        if w <= 32:
            return f"{w}'($urandom)"
        rep = (w + 31) // 32
        return f"{w}'({{{', '.join(['$urandom()']*rep)}}})"

    in_names = {n for _, n in ins}
    reset_valids = [n for n in valid_rate if n in in_names]
    T.append("  always @(negedge clk) begin")
    T.append("    if (rst) begin")
    for n in reset_valids:
        T.append(f"      {n} <= 1'b0;")
    T.append("    end else begin")
    for w, n in ins:
        T.append(f"      {n} <= {rnd(w, n)};")
    # satp/vsatp 模式简化为 {0,8,9}
    for m in ("io_csr_satp_mode","io_csr_vsatp_mode","io_csr_hgatp_mode"):
        if m in in_names:
            T.append(f"      begin int s; s=$urandom_range(0,2); {m} <= (s==0)?4'h0:(s==1)?4'h8:4'h9; end")
    T.append("    end")
    T.append("  end")

    T.append("  always @(negedge clk) if (!rst) begin")
    T.append("    #4; checks++;")
    for w, n in outs:
        T.append(f"    if (!$isunknown(g_{n}) && g_{n} !== i_{n}) begin errors++;")
        T.append(f"      if(errors<=80) $display(\"[%0t] {n} g=%h i=%h\", $time, g_{n}, i_{n}); end")
    T.append("  end")
    # 内部寄存器探针：证 FM 20 failing（excp_*_REG / REG / need_gpa_vpn）是假阳性
    T.append("""
  int pe_need_gpa_vpn=0, pe_REG=0, pe_pfld=0, pe_afld=0, pe_pfst=0;
  always @(negedge clk) if (!rst) begin #4;
    if (!$isunknown(u_g.need_gpa_vpn) && u_g.need_gpa_vpn !== u_i.u_core.need_gpa_vpn) pe_need_gpa_vpn++;
    if (!$isunknown(u_g.REG) && u_g.REG !== u_i.u_core.REG_pre[0]) pe_REG++;
    if (!$isunknown(u_g.io_requestor_0_resp_bits_excp_0_pf_ld_REG)
        && u_g.io_requestor_0_resp_bits_excp_0_pf_ld_REG !== u_i.u_core.excp_pf_ld_REG[0]) pe_pfld++;
    if (!$isunknown(u_g.io_requestor_0_resp_bits_excp_0_af_ld_REG)
        && u_g.io_requestor_0_resp_bits_excp_0_af_ld_REG !== u_i.u_core.excp_af_ld_REG[0]) pe_afld++;
    if (!$isunknown(u_g.io_requestor_0_resp_bits_excp_0_pf_st_REG)
        && u_g.io_requestor_0_resp_bits_excp_0_pf_st_REG !== u_i.u_core.excp_pf_st_REG[0]) pe_pfst++;
  end""")
    T.append("""  initial begin
    rst = 1; repeat (8) @(posedge clk); rst = 0;
    repeat (NCYCLES) @(posedge clk);
    $display("checks=%0d errors=%0d", checks, errors);
    $display("PROBE need_gpa_vpn=%0d REG=%0d pf_ld=%0d af_ld=%0d pf_st=%0d",
             pe_need_gpa_vpn, pe_REG, pe_pfld, pe_afld, pe_pfst);
    if (errors == 0 && checks > 1000) $display("TEST PASSED"); else $display("TEST FAILED");
    $finish;
  end
endmodule
""")
    return "\n".join(T)


def main():
    ps = golden_ports("TLBNonBlock")
    (XSSV / "rtl/memblock/TLBNonBlock_wrapper.sv").write_text(build_wrapper("TLBNonBlock", "xs_TLBNonBlock_core"))
    ut = XSSV / "verif/ut/TLBNonBlock"
    ut.mkdir(parents=True, exist_ok=True)
    (ut / "variants_xs.sv").write_text(build_wrapper("TLBNonBlock_xs", "xs_TLBNonBlock_core"))
    (ut / "tb.sv").write_text(build_tb(ps))
    print(f"TLBNonBlock: {len(ps)} golden ports")


if __name__ == "__main__":
    main()
