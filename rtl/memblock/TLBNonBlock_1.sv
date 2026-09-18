// TLBNonBlock_1 —— MemBlock 的 dtlb_st：2 个 store 地址单元（TLBNonBlock 家族薄 wrapper）
//
// 本变体 = MemBlock 里的 dtlb_st。逻辑全部在参数化可读核
// xs_TLBNonBlock_core（同目录 xs_TLBNonBlock_core.sv）里；本文件只做三件事：
//   1) 逐位抄 golden 的端口表；
//   2) 例化 golden 子模块 DelayN_9 / DelayN_7 / TlbStorageWrapper_2；
//   3) 把扁平的 io_* 名接到核的按 lane 成组的向量端口上，缺席端口补常量/不接。
//
// 规模：golden TLBNonBlock_1.sv 2746 行 / 182 端口（128 输入、54 输出），165 个寄存器。
// 参数：W=2  nRespDups=1  difftest 开（index 从 7 起）
//
// 端口表与接线由 scripts/gen_tlbnb_family.py 生成（GENERATED 标记之间），勿手改。
// BEGIN GENERATED(tlbnb-wrapper) —— scripts/gen_tlbnb_family.py 生成，勿手改
module TLBNonBlock_1 import tlbnb_pkg::*; (
  input             clock,
  input             reset,
  input             io_sfence_valid,
  input             io_sfence_bits_rs1,
  input             io_sfence_bits_rs2,
  input   [49:0]    io_sfence_bits_addr,
  input   [15:0]    io_sfence_bits_id,
  input             io_sfence_bits_flushPipe,
  input             io_sfence_bits_hv,
  input             io_sfence_bits_hg,
  input   [3:0]     io_csr_satp_mode,
  input   [15:0]    io_csr_satp_asid,
  input   [43:0]    io_csr_satp_ppn,
  input             io_csr_satp_changed,
  input   [3:0]     io_csr_vsatp_mode,
  input   [15:0]    io_csr_vsatp_asid,
  input   [43:0]    io_csr_vsatp_ppn,
  input             io_csr_vsatp_changed,
  input   [3:0]     io_csr_hgatp_mode,
  input   [15:0]    io_csr_hgatp_vmid,
  input   [43:0]    io_csr_hgatp_ppn,
  input             io_csr_hgatp_changed,
  input             io_csr_mbmc_BME,
  input             io_csr_mbmc_CMODE,
  input             io_csr_priv_mxr,
  input             io_csr_priv_sum,
  input             io_csr_priv_vmxr,
  input             io_csr_priv_vsum,
  input             io_csr_priv_virt,
  input             io_csr_priv_virt_changed,
  input             io_csr_priv_spvp,
  input   [1:0]     io_csr_priv_imode,
  input   [1:0]     io_csr_priv_dmode,
  input             io_csr_priv_debug,
  input   [1:0]     io_csr_pmm_mseccfg,
  input   [1:0]     io_csr_pmm_menvcfg,
  input   [1:0]     io_csr_pmm_henvcfg,
  input   [1:0]     io_csr_pmm_hstatus,
  input   [1:0]     io_csr_pmm_senvcfg,
  input   [5:0]     io_hartId,
  input             io_requestor_0_req_valid,
  input   [49:0]    io_requestor_0_req_bits_vaddr,
  input   [63:0]    io_requestor_0_req_bits_fullva,
  input             io_requestor_0_req_bits_checkfullva,
  input   [2:0]     io_requestor_0_req_bits_cmd,
  input             io_requestor_0_req_bits_hyperinst,
  input   [6:0]     io_requestor_0_req_bits_memidx_idx,
  input             io_requestor_0_req_bits_frm_mabuf,
  input             io_requestor_0_req_bits_debug_robIdx_flag,
  input   [7:0]     io_requestor_0_req_bits_debug_robIdx_value,
  input             io_requestor_0_req_bits_debug_isFirstIssue,
  output            io_requestor_0_resp_valid,
  output  [47:0]    io_requestor_0_resp_bits_paddr_0,
  output  [63:0]    io_requestor_0_resp_bits_gpaddr_0,
  output  [63:0]    io_requestor_0_resp_bits_fullva,
  output  [1:0]     io_requestor_0_resp_bits_pbmt_0,
  output            io_requestor_0_resp_bits_miss,
  output            io_requestor_0_resp_bits_isForVSnonLeafPTE,
  output            io_requestor_0_resp_bits_excp_0_vaNeedExt,
  output            io_requestor_0_resp_bits_excp_0_isHyper,
  output            io_requestor_0_resp_bits_excp_0_gpf_ld,
  output            io_requestor_0_resp_bits_excp_0_gpf_st,
  output            io_requestor_0_resp_bits_excp_0_pf_ld,
  output            io_requestor_0_resp_bits_excp_0_pf_st,
  output            io_requestor_0_resp_bits_excp_0_af_ld,
  output            io_requestor_0_resp_bits_excp_0_af_st,
  output            io_requestor_0_resp_bits_ptwBack,
  output  [6:0]     io_requestor_0_resp_bits_memidx_idx,
  input             io_requestor_1_req_valid,
  input   [49:0]    io_requestor_1_req_bits_vaddr,
  input   [63:0]    io_requestor_1_req_bits_fullva,
  input             io_requestor_1_req_bits_checkfullva,
  input   [2:0]     io_requestor_1_req_bits_cmd,
  input             io_requestor_1_req_bits_hyperinst,
  input   [6:0]     io_requestor_1_req_bits_memidx_idx,
  input             io_requestor_1_req_bits_frm_mabuf,
  input             io_requestor_1_req_bits_debug_robIdx_flag,
  input   [7:0]     io_requestor_1_req_bits_debug_robIdx_value,
  input             io_requestor_1_req_bits_debug_isFirstIssue,
  output            io_requestor_1_resp_valid,
  output  [47:0]    io_requestor_1_resp_bits_paddr_0,
  output  [63:0]    io_requestor_1_resp_bits_gpaddr_0,
  output  [63:0]    io_requestor_1_resp_bits_fullva,
  output  [1:0]     io_requestor_1_resp_bits_pbmt_0,
  output            io_requestor_1_resp_bits_miss,
  output            io_requestor_1_resp_bits_isForVSnonLeafPTE,
  output            io_requestor_1_resp_bits_excp_0_vaNeedExt,
  output            io_requestor_1_resp_bits_excp_0_isHyper,
  output            io_requestor_1_resp_bits_excp_0_gpf_ld,
  output            io_requestor_1_resp_bits_excp_0_gpf_st,
  output            io_requestor_1_resp_bits_excp_0_pf_ld,
  output            io_requestor_1_resp_bits_excp_0_pf_st,
  output            io_requestor_1_resp_bits_excp_0_af_ld,
  output            io_requestor_1_resp_bits_excp_0_af_st,
  output            io_requestor_1_resp_bits_ptwBack,
  output  [6:0]     io_requestor_1_resp_bits_memidx_idx,
  input             io_redirect_valid,
  input             io_redirect_bits_robIdx_flag,
  input   [7:0]     io_redirect_bits_robIdx_value,
  input             io_redirect_bits_level,
  output            io_ptw_req_0_valid,
  output  [37:0]    io_ptw_req_0_bits_vpn,
  output  [1:0]     io_ptw_req_0_bits_s2xlate,
  output            io_ptw_req_0_bits_getGpa,
  output            io_ptw_req_1_valid,
  output  [37:0]    io_ptw_req_1_bits_vpn,
  output  [1:0]     io_ptw_req_1_bits_s2xlate,
  output            io_ptw_req_1_bits_getGpa,
  input             io_ptw_resp_valid,
  input   [1:0]     io_ptw_resp_bits_s2xlate,
  input   [34:0]    io_ptw_resp_bits_s1_entry_tag,
  input   [15:0]    io_ptw_resp_bits_s1_entry_asid,
  input   [13:0]    io_ptw_resp_bits_s1_entry_vmid,
  input             io_ptw_resp_bits_s1_entry_n,
  input   [1:0]     io_ptw_resp_bits_s1_entry_pbmt,
  input             io_ptw_resp_bits_s1_entry_perm_d,
  input             io_ptw_resp_bits_s1_entry_perm_a,
  input             io_ptw_resp_bits_s1_entry_perm_g,
  input             io_ptw_resp_bits_s1_entry_perm_u,
  input             io_ptw_resp_bits_s1_entry_perm_x,
  input             io_ptw_resp_bits_s1_entry_perm_w,
  input             io_ptw_resp_bits_s1_entry_perm_r,
  input   [1:0]     io_ptw_resp_bits_s1_entry_level,
  input             io_ptw_resp_bits_s1_entry_v,
  input   [40:0]    io_ptw_resp_bits_s1_entry_ppn,
  input   [2:0]     io_ptw_resp_bits_s1_addr_low,
  input   [2:0]     io_ptw_resp_bits_s1_ppn_low_0,
  input   [2:0]     io_ptw_resp_bits_s1_ppn_low_1,
  input   [2:0]     io_ptw_resp_bits_s1_ppn_low_2,
  input   [2:0]     io_ptw_resp_bits_s1_ppn_low_3,
  input   [2:0]     io_ptw_resp_bits_s1_ppn_low_4,
  input   [2:0]     io_ptw_resp_bits_s1_ppn_low_5,
  input   [2:0]     io_ptw_resp_bits_s1_ppn_low_6,
  input   [2:0]     io_ptw_resp_bits_s1_ppn_low_7,
  input             io_ptw_resp_bits_s1_valididx_0,
  input             io_ptw_resp_bits_s1_valididx_1,
  input             io_ptw_resp_bits_s1_valididx_2,
  input             io_ptw_resp_bits_s1_valididx_3,
  input             io_ptw_resp_bits_s1_valididx_4,
  input             io_ptw_resp_bits_s1_valididx_5,
  input             io_ptw_resp_bits_s1_valididx_6,
  input             io_ptw_resp_bits_s1_valididx_7,
  input             io_ptw_resp_bits_s1_pteidx_0,
  input             io_ptw_resp_bits_s1_pteidx_1,
  input             io_ptw_resp_bits_s1_pteidx_2,
  input             io_ptw_resp_bits_s1_pteidx_3,
  input             io_ptw_resp_bits_s1_pteidx_4,
  input             io_ptw_resp_bits_s1_pteidx_5,
  input             io_ptw_resp_bits_s1_pteidx_6,
  input             io_ptw_resp_bits_s1_pteidx_7,
  input             io_ptw_resp_bits_s1_pf,
  input             io_ptw_resp_bits_s1_af,
  input   [37:0]    io_ptw_resp_bits_s2_entry_tag,
  input   [13:0]    io_ptw_resp_bits_s2_entry_vmid,
  input             io_ptw_resp_bits_s2_entry_n,
  input   [1:0]     io_ptw_resp_bits_s2_entry_pbmt,
  input   [37:0]    io_ptw_resp_bits_s2_entry_ppn,
  input             io_ptw_resp_bits_s2_entry_perm_d,
  input             io_ptw_resp_bits_s2_entry_perm_a,
  input             io_ptw_resp_bits_s2_entry_perm_g,
  input             io_ptw_resp_bits_s2_entry_perm_u,
  input             io_ptw_resp_bits_s2_entry_perm_x,
  input             io_ptw_resp_bits_s2_entry_perm_w,
  input             io_ptw_resp_bits_s2_entry_perm_r,
  input   [1:0]     io_ptw_resp_bits_s2_entry_level,
  input             io_ptw_resp_bits_s2_gpf,
  input             io_ptw_resp_bits_s2_gaf,
  input             io_ptw_resp_bits_getGpa,
  output            io_pmp_0_valid,
  output  [47:0]    io_pmp_0_bits_addr,
  output  [2:0]     io_pmp_0_bits_cmd,
  output            io_pmp_1_valid,
  output  [47:0]    io_pmp_1_bits_addr,
  output  [2:0]     io_pmp_1_bits_cmd,
  output  [1:0]     io_pmpMode_0,
  output  [1:0]     io_pmpMode_1,
  input             io_robPendingPtr_flag,
  input   [7:0]     io_robPendingPtr_value,
  output  [5:0]     io_perf_0_value,
  output  [5:0]     io_perf_1_value,
  output  [338:0]   gatewayIn_packed_57_bore,
  output  [338:0]   gatewayIn_packed_58_bore
);

  // ---- 本变体参数（推导依据见 scripts/gen_tlbnb_family.py 的文件头）----
  localparam int W = 2;            // requestor 通道数
  localparam int ND = 1;           // nRespDups（golden REG 计数复核过：2 个）

  // ---- sfence / CSR 各延迟 2 拍（fenceDelay）：刷 TLB 要等流水线里的旧访存走完 ----
  wire  sfd_valid;
  wire  sfd_bits_rs1;
  wire  sfd_bits_rs2;
  wire [49:0] sfd_bits_addr;
  wire [15:0] sfd_bits_id;
  wire  sfd_bits_hv;
  wire  sfd_bits_hg;
  wire  csrd_satp_changed;
  wire  csrd_vsatp_changed;
  wire  csrd_hgatp_changed;
  wire  csrd_priv_virt_changed;
  wire [3:0] csrd_satp_mode;
  wire [15:0] csrd_satp_asid;
  wire [43:0] csrd_satp_ppn;
  wire [3:0] csrd_vsatp_mode;
  wire [15:0] csrd_vsatp_asid;
  wire [43:0] csrd_vsatp_ppn;
  wire [3:0] csrd_hgatp_mode;
  wire [15:0] csrd_hgatp_vmid;
  wire [43:0] csrd_hgatp_ppn;
  wire  csrd_priv_mxr;
  wire  csrd_priv_sum;
  wire  csrd_priv_vmxr;
  wire  csrd_priv_vsum;
  wire  csrd_priv_virt;
  wire  csrd_priv_spvp;
  wire [1:0] csrd_priv_imode;
  wire [1:0] csrd_priv_dmode;
  wire [1:0] csrd_pmm_mseccfg;
  wire [1:0] csrd_pmm_menvcfg;
  wire [1:0] csrd_pmm_henvcfg;
  wire [1:0] csrd_pmm_hstatus;
  wire [1:0] csrd_pmm_senvcfg;
  wire csrd_mbmc_BME, csrd_mbmc_CMODE;

  DelayN_9 sfence_delay (
    .clock                 (clock),
    .io_in_valid            (io_sfence_valid),
    .io_in_bits_rs1         (io_sfence_bits_rs1),
    .io_in_bits_rs2         (io_sfence_bits_rs2),
    .io_in_bits_addr        (io_sfence_bits_addr),
    .io_in_bits_id          (io_sfence_bits_id),
    .io_in_bits_flushPipe   (io_sfence_bits_flushPipe),
    .io_in_bits_hv          (io_sfence_bits_hv),
    .io_in_bits_hg          (io_sfence_bits_hg),
    .io_out_valid           (sfd_valid),
    .io_out_bits_rs1        (sfd_bits_rs1),
    .io_out_bits_rs2        (sfd_bits_rs2),
    .io_out_bits_addr       (sfd_bits_addr),
    .io_out_bits_id         (sfd_bits_id),
    .io_out_bits_flushPipe (/* golden 也不接：非阻塞 TLB 不看 flushPipe */),
    .io_out_bits_hv        (sfd_bits_hv),
    .io_out_bits_hg        (sfd_bits_hg)
  );
  DelayN_7 csr_delay (
    .clock (clock),
    .io_in_satp_changed         (io_csr_satp_changed),
    .io_in_vsatp_changed        (io_csr_vsatp_changed),
    .io_in_hgatp_changed        (io_csr_hgatp_changed),
    .io_in_priv_virt_changed    (io_csr_priv_virt_changed),
    .io_in_satp_mode            (io_csr_satp_mode),
    .io_in_satp_asid            (io_csr_satp_asid),
    .io_in_satp_ppn             (io_csr_satp_ppn),
    .io_in_vsatp_mode           (io_csr_vsatp_mode),
    .io_in_vsatp_asid           (io_csr_vsatp_asid),
    .io_in_vsatp_ppn            (io_csr_vsatp_ppn),
    .io_in_hgatp_mode           (io_csr_hgatp_mode),
    .io_in_hgatp_vmid           (io_csr_hgatp_vmid),
    .io_in_hgatp_ppn            (io_csr_hgatp_ppn),
    .io_in_priv_mxr             (io_csr_priv_mxr),
    .io_in_priv_sum             (io_csr_priv_sum),
    .io_in_priv_vmxr            (io_csr_priv_vmxr),
    .io_in_priv_vsum            (io_csr_priv_vsum),
    .io_in_priv_virt            (io_csr_priv_virt),
    .io_in_priv_spvp            (io_csr_priv_spvp),
    .io_in_priv_imode           (io_csr_priv_imode),
    .io_in_priv_dmode           (io_csr_priv_dmode),
    .io_in_pmm_mseccfg          (io_csr_pmm_mseccfg),
    .io_in_pmm_menvcfg          (io_csr_pmm_menvcfg),
    .io_in_pmm_henvcfg          (io_csr_pmm_henvcfg),
    .io_in_pmm_hstatus          (io_csr_pmm_hstatus),
    .io_in_pmm_senvcfg          (io_csr_pmm_senvcfg),
    .io_in_mbmc_BME             (io_csr_mbmc_BME),
    .io_in_mbmc_CMODE           (io_csr_mbmc_CMODE),
    .io_in_priv_debug           (io_csr_priv_debug),
    .io_out_satp_changed        (csrd_satp_changed),
    .io_out_vsatp_changed       (csrd_vsatp_changed),
    .io_out_hgatp_changed       (csrd_hgatp_changed),
    .io_out_priv_virt_changed   (csrd_priv_virt_changed),
    .io_out_satp_mode           (csrd_satp_mode),
    .io_out_satp_asid           (csrd_satp_asid),
    .io_out_satp_ppn            (csrd_satp_ppn),
    .io_out_vsatp_mode          (csrd_vsatp_mode),
    .io_out_vsatp_asid          (csrd_vsatp_asid),
    .io_out_vsatp_ppn           (csrd_vsatp_ppn),
    .io_out_hgatp_mode          (csrd_hgatp_mode),
    .io_out_hgatp_vmid          (csrd_hgatp_vmid),
    .io_out_hgatp_ppn           (csrd_hgatp_ppn),
    .io_out_priv_mxr            (csrd_priv_mxr),
    .io_out_priv_sum            (csrd_priv_sum),
    .io_out_priv_vmxr           (csrd_priv_vmxr),
    .io_out_priv_vsum           (csrd_priv_vsum),
    .io_out_priv_virt           (csrd_priv_virt),
    .io_out_priv_spvp           (csrd_priv_spvp),
    .io_out_priv_imode          (csrd_priv_imode),
    .io_out_priv_dmode          (csrd_priv_dmode),
    .io_out_pmm_mseccfg         (csrd_pmm_mseccfg),
    .io_out_pmm_menvcfg         (csrd_pmm_menvcfg),
    .io_out_pmm_henvcfg         (csrd_pmm_henvcfg),
    .io_out_pmm_hstatus         (csrd_pmm_hstatus),
    .io_out_pmm_senvcfg         (csrd_pmm_senvcfg),
    .io_out_mbmc_BME            (csrd_mbmc_BME),
    .io_out_mbmc_CMODE          (csrd_mbmc_CMODE),
    .io_out_priv_debug          (/* golden 也不接 */)
  );

  // ---- 打包成核的两个 struct 端口 ----
  tlb_csr_t  csr_d;
  ptw_resp_t ptw_resp_w;
  always_comb begin
    csr_d.satp_changed       = csrd_satp_changed;
    csr_d.vsatp_changed      = csrd_vsatp_changed;
    csr_d.hgatp_changed      = csrd_hgatp_changed;
    csr_d.priv_virt_changed  = csrd_priv_virt_changed;
    csr_d.satp_mode          = csrd_satp_mode;
    csr_d.satp_asid          = csrd_satp_asid;
    csr_d.satp_ppn           = csrd_satp_ppn;
    csr_d.vsatp_mode         = csrd_vsatp_mode;
    csr_d.vsatp_asid         = csrd_vsatp_asid;
    csr_d.vsatp_ppn          = csrd_vsatp_ppn;
    csr_d.hgatp_mode         = csrd_hgatp_mode;
    csr_d.hgatp_vmid         = csrd_hgatp_vmid;
    csr_d.hgatp_ppn          = csrd_hgatp_ppn;
    csr_d.priv_mxr           = csrd_priv_mxr;
    csr_d.priv_sum           = csrd_priv_sum;
    csr_d.priv_vmxr          = csrd_priv_vmxr;
    csr_d.priv_vsum          = csrd_priv_vsum;
    csr_d.priv_virt          = csrd_priv_virt;
    csr_d.priv_spvp          = csrd_priv_spvp;
    csr_d.priv_imode         = csrd_priv_imode;
    csr_d.priv_dmode         = csrd_priv_dmode;
    csr_d.pmm_mseccfg        = csrd_pmm_mseccfg;
    csr_d.pmm_menvcfg        = csrd_pmm_menvcfg;
    csr_d.pmm_henvcfg        = csrd_pmm_henvcfg;
    csr_d.pmm_hstatus        = csrd_pmm_hstatus;
    csr_d.pmm_senvcfg        = csrd_pmm_senvcfg;
  end
  always_comb begin
    ptw_resp_w.s2xlate                = io_ptw_resp_bits_s2xlate;
    ptw_resp_w.s1.entry_tag           = io_ptw_resp_bits_s1_entry_tag;
    ptw_resp_w.s1.entry_asid          = io_ptw_resp_bits_s1_entry_asid;
    ptw_resp_w.s1.entry_vmid          = io_ptw_resp_bits_s1_entry_vmid;
    ptw_resp_w.s1.entry_n             = io_ptw_resp_bits_s1_entry_n;
    ptw_resp_w.s1.entry_pbmt          = io_ptw_resp_bits_s1_entry_pbmt;
    ptw_resp_w.s1.entry_perm_d        = io_ptw_resp_bits_s1_entry_perm_d;
    ptw_resp_w.s1.entry_perm_a        = io_ptw_resp_bits_s1_entry_perm_a;
    ptw_resp_w.s1.entry_perm_g        = io_ptw_resp_bits_s1_entry_perm_g;
    ptw_resp_w.s1.entry_perm_u        = io_ptw_resp_bits_s1_entry_perm_u;
    ptw_resp_w.s1.entry_perm_x        = io_ptw_resp_bits_s1_entry_perm_x;
    ptw_resp_w.s1.entry_perm_w        = io_ptw_resp_bits_s1_entry_perm_w;
    ptw_resp_w.s1.entry_perm_r        = io_ptw_resp_bits_s1_entry_perm_r;
    ptw_resp_w.s1.entry_level         = io_ptw_resp_bits_s1_entry_level;
    ptw_resp_w.s1.entry_v             = io_ptw_resp_bits_s1_entry_v;
    ptw_resp_w.s1.entry_ppn           = io_ptw_resp_bits_s1_entry_ppn;
    ptw_resp_w.s1.addr_low            = io_ptw_resp_bits_s1_addr_low;
    ptw_resp_w.s1.pf                  = io_ptw_resp_bits_s1_pf;
    ptw_resp_w.s1.af                  = io_ptw_resp_bits_s1_af;
    ptw_resp_w.s2.entry_tag           = io_ptw_resp_bits_s2_entry_tag;
    ptw_resp_w.s2.entry_vmid          = io_ptw_resp_bits_s2_entry_vmid;
    ptw_resp_w.s2.entry_n             = io_ptw_resp_bits_s2_entry_n;
    ptw_resp_w.s2.entry_pbmt          = io_ptw_resp_bits_s2_entry_pbmt;
    ptw_resp_w.s2.entry_ppn           = io_ptw_resp_bits_s2_entry_ppn;
    ptw_resp_w.s2.entry_perm_d        = io_ptw_resp_bits_s2_entry_perm_d;
    ptw_resp_w.s2.entry_perm_a        = io_ptw_resp_bits_s2_entry_perm_a;
    ptw_resp_w.s2.entry_perm_g        = io_ptw_resp_bits_s2_entry_perm_g;
    ptw_resp_w.s2.entry_perm_u        = io_ptw_resp_bits_s2_entry_perm_u;
    ptw_resp_w.s2.entry_perm_x        = io_ptw_resp_bits_s2_entry_perm_x;
    ptw_resp_w.s2.entry_perm_w        = io_ptw_resp_bits_s2_entry_perm_w;
    ptw_resp_w.s2.entry_perm_r        = io_ptw_resp_bits_s2_entry_perm_r;
    ptw_resp_w.s2.entry_level         = io_ptw_resp_bits_s2_entry_level;
    ptw_resp_w.s2.gpf                 = io_ptw_resp_bits_s2_gpf;
    ptw_resp_w.s2.gaf                 = io_ptw_resp_bits_s2_gaf;
    ptw_resp_w.get_gpa                = io_ptw_resp_bits_getGpa;
    ptw_resp_w.s1.ppn_low[0]  = io_ptw_resp_bits_s1_ppn_low_0;
    ptw_resp_w.s1.ppn_low[1]  = io_ptw_resp_bits_s1_ppn_low_1;
    ptw_resp_w.s1.ppn_low[2]  = io_ptw_resp_bits_s1_ppn_low_2;
    ptw_resp_w.s1.ppn_low[3]  = io_ptw_resp_bits_s1_ppn_low_3;
    ptw_resp_w.s1.ppn_low[4]  = io_ptw_resp_bits_s1_ppn_low_4;
    ptw_resp_w.s1.ppn_low[5]  = io_ptw_resp_bits_s1_ppn_low_5;
    ptw_resp_w.s1.ppn_low[6]  = io_ptw_resp_bits_s1_ppn_low_6;
    ptw_resp_w.s1.ppn_low[7]  = io_ptw_resp_bits_s1_ppn_low_7;
    ptw_resp_w.s1.valididx[0] = io_ptw_resp_bits_s1_valididx_0;
    ptw_resp_w.s1.valididx[1] = io_ptw_resp_bits_s1_valididx_1;
    ptw_resp_w.s1.valididx[2] = io_ptw_resp_bits_s1_valididx_2;
    ptw_resp_w.s1.valididx[3] = io_ptw_resp_bits_s1_valididx_3;
    ptw_resp_w.s1.valididx[4] = io_ptw_resp_bits_s1_valididx_4;
    ptw_resp_w.s1.valididx[5] = io_ptw_resp_bits_s1_valididx_5;
    ptw_resp_w.s1.valididx[6] = io_ptw_resp_bits_s1_valididx_6;
    ptw_resp_w.s1.valididx[7] = io_ptw_resp_bits_s1_valididx_7;
    ptw_resp_w.s1.pteidx[0]   = io_ptw_resp_bits_s1_pteidx_0;
    ptw_resp_w.s1.pteidx[1]   = io_ptw_resp_bits_s1_pteidx_1;
    ptw_resp_w.s1.pteidx[2]   = io_ptw_resp_bits_s1_pteidx_2;
    ptw_resp_w.s1.pteidx[3]   = io_ptw_resp_bits_s1_pteidx_3;
    ptw_resp_w.s1.pteidx[4]   = io_ptw_resp_bits_s1_pteidx_4;
    ptw_resp_w.s1.pteidx[5]   = io_ptw_resp_bits_s1_pteidx_5;
    ptw_resp_w.s1.pteidx[6]   = io_ptw_resp_bits_s1_pteidx_6;
    ptw_resp_w.s1.pteidx[7]   = io_ptw_resp_bits_s1_pteidx_7;
  end

  // ---- 核与 entries（TlbStorageWrapper_2）之间的查询/回填线 ----
  wire [W-1:0]              stor_r_req_valid;
  wire [W-1:0][VPN_W-1:0]   stor_r_req_vpn;
  wire [W-1:0][1:0]         stor_r_req_s2xlate;
  wire                      stor_w_valid;
  wire [W-1:0]              ent_hit;
  logic [W-1:0][ND-1:0][PPN_W-1:0] ent_ppn;
  logic [W-1:0][ND-1:0][1:0]       ent_pbmt;
  logic [W-1:0][ND-1:0][1:0]       ent_g_pbmt;
  logic [W-1:0][ND-1:0][1:0]       ent_s2xlate;
  tlb_perm_t  [W-1:0][ND-1:0]      ent_perm;
  tlb_gperm_t [W-1:0][ND-1:0]      ent_g_perm;
  wire ent_hit_0;
  wire [35:0] ent_0_ppn_0;
  wire ent_0_perm_0_pf;
  wire ent_0_perm_0_af;
  wire ent_0_perm_0_v;
  wire ent_0_perm_0_d;
  wire ent_0_perm_0_a;
  wire ent_0_perm_0_u;
  wire ent_0_perm_0_x;
  wire ent_0_perm_0_w;
  wire ent_0_perm_0_r;
  wire ent_0_g_perm_0_pf;
  wire ent_0_g_perm_0_af;
  wire ent_0_g_perm_0_d;
  wire ent_0_g_perm_0_a;
  wire ent_0_g_perm_0_x;
  wire ent_0_g_perm_0_w;
  wire ent_0_g_perm_0_r;
  wire [1:0] ent_0_pbmt_0;
  wire [1:0] ent_0_g_pbmt_0;
  wire [1:0] ent_0_s2xlate_0;
  wire ent_hit_1;
  wire [35:0] ent_1_ppn_0;
  wire ent_1_perm_0_pf;
  wire ent_1_perm_0_af;
  wire ent_1_perm_0_v;
  wire ent_1_perm_0_d;
  wire ent_1_perm_0_a;
  wire ent_1_perm_0_u;
  wire ent_1_perm_0_x;
  wire ent_1_perm_0_w;
  wire ent_1_perm_0_r;
  wire ent_1_g_perm_0_pf;
  wire ent_1_g_perm_0_af;
  wire ent_1_g_perm_0_d;
  wire ent_1_g_perm_0_a;
  wire ent_1_g_perm_0_x;
  wire ent_1_g_perm_0_w;
  wire ent_1_g_perm_0_r;
  wire [1:0] ent_1_pbmt_0;
  wire [1:0] ent_1_g_pbmt_0;
  wire [1:0] ent_1_s2xlate_0;

  assign ent_hit[0] = ent_hit_0;
  assign ent_hit[1] = ent_hit_1;

  // entries 在本变体里没给的字段（firtool 消掉了）一律补 0：
  // 它们只喂到核里同样没人读的那部分组合逻辑上（dup>0 的 pbmt / g_perm 等）。
  always_comb begin
    ent_ppn = '0; ent_pbmt = '0; ent_g_pbmt = '0;
    ent_s2xlate = '0; ent_perm = '0; ent_g_perm = '0;
    ent_ppn[0][0] = ent_0_ppn_0;
    ent_pbmt[0][0] = ent_0_pbmt_0;
    ent_g_pbmt[0][0] = ent_0_g_pbmt_0;
    ent_s2xlate[0][0] = ent_0_s2xlate_0;
    ent_perm[0][0].pf = ent_0_perm_0_pf;
    ent_perm[0][0].af = ent_0_perm_0_af;
    ent_perm[0][0].v = ent_0_perm_0_v;
    ent_perm[0][0].d = ent_0_perm_0_d;
    ent_perm[0][0].a = ent_0_perm_0_a;
    ent_perm[0][0].u = ent_0_perm_0_u;
    ent_perm[0][0].x = ent_0_perm_0_x;
    ent_perm[0][0].w = ent_0_perm_0_w;
    ent_perm[0][0].r = ent_0_perm_0_r;
    ent_g_perm[0][0].pf = ent_0_g_perm_0_pf;
    ent_g_perm[0][0].af = ent_0_g_perm_0_af;
    ent_g_perm[0][0].d = ent_0_g_perm_0_d;
    ent_g_perm[0][0].a = ent_0_g_perm_0_a;
    ent_g_perm[0][0].x = ent_0_g_perm_0_x;
    ent_g_perm[0][0].w = ent_0_g_perm_0_w;
    ent_g_perm[0][0].r = ent_0_g_perm_0_r;
    ent_ppn[1][0] = ent_1_ppn_0;
    ent_pbmt[1][0] = ent_1_pbmt_0;
    ent_g_pbmt[1][0] = ent_1_g_pbmt_0;
    ent_s2xlate[1][0] = ent_1_s2xlate_0;
    ent_perm[1][0].pf = ent_1_perm_0_pf;
    ent_perm[1][0].af = ent_1_perm_0_af;
    ent_perm[1][0].v = ent_1_perm_0_v;
    ent_perm[1][0].d = ent_1_perm_0_d;
    ent_perm[1][0].a = ent_1_perm_0_a;
    ent_perm[1][0].u = ent_1_perm_0_u;
    ent_perm[1][0].x = ent_1_perm_0_x;
    ent_perm[1][0].w = ent_1_perm_0_w;
    ent_perm[1][0].r = ent_1_perm_0_r;
    ent_g_perm[1][0].pf = ent_1_g_perm_0_pf;
    ent_g_perm[1][0].af = ent_1_g_perm_0_af;
    ent_g_perm[1][0].d = ent_1_g_perm_0_d;
    ent_g_perm[1][0].a = ent_1_g_perm_0_a;
    ent_g_perm[1][0].x = ent_1_g_perm_0_x;
    ent_g_perm[1][0].w = ent_1_g_perm_0_w;
    ent_g_perm[1][0].r = ent_1_g_perm_0_r;
  end

  // ---- 可读核 ----
  logic [W-1:0]                     core_resp_valid, core_resp_miss;
  logic [W-1:0][PADDR_W-1:0]        core_pmp_addr;
  logic [W-1:0][ND-1:0][PADDR_W-1:0] core_paddr;
  logic [W-1:0][ND-1:0][XLEN-1:0]   core_gpaddr;
  logic [W-1:0][ND-1:0][1:0]        core_pbmt;
  logic [W-1:0][XLEN-1:0]           core_fullva;
  logic [W-1:0][MEMIDX_W-1:0]       core_memidx;
  logic [W-1:0] core_ptw_back, core_vsnl, core_pf_ld, core_pf_st;
  logic [W-1:0] core_gpf_ld, core_gpf_st, core_af_ld, core_af_st;
  logic [W-1:0] core_is_hyper, core_va_need_ext, core_tlbreplay;
  logic [W-1:0] core_ptw_req_valid, core_ptw_req_get_gpa, core_pmp_valid;
  logic [W-1:0][VPN_W-1:0] core_ptw_req_vpn;
  logic [W-1:0][1:0]       core_ptw_req_s2xlate, core_pmp_mode;
  logic [W-1:0][2:0]       core_pmp_cmd;
  logic [5:0] core_perf_access, core_perf_miss;
  logic [W-1:0][338:0] core_difftest;

  xs_TLBNonBlock_core #(
    .W (W), .N_DUPS (ND),
    .HAS_GPADDR      (2'b11),  // resp.gpaddr(0) 端口在的 lane
    .HAS_RESP_FULLVA (2'b11),  // resp.fullva 端口在的 lane
    .HAS_MEMIDX      (2'b11),  // resp.memidx 端口在的 lane
    .HAS_ST_EXCP     (2'b11),  // excp(0).{pf,af}.st 端口在的 lane
    .HAS_REQ_KILL    (2'b00),  // requestor.req_kill 端口在的 lane
    .HAS_TLBREPLAY   (1'b0),
    .HAS_PERF        (1'b1),
    .DIFFTEST_EN     (1'b1),
    .DIFF_INDEX_0    (7)
  ) u_core (
    .clock (clock), .reset (reset),
    .sfence_valid_d (sfd_valid), .csr (csr_d), .hart_id (io_hartId),
    .redirect_valid (io_redirect_valid),
    .redirect_robidx_flag (io_redirect_bits_robIdx_flag),
    .redirect_robidx_value (io_redirect_bits_robIdx_value),
    .redirect_level (io_redirect_bits_level),
    .rob_pending_flag (io_robPendingPtr_flag),
    .rob_pending_value (io_robPendingPtr_value),
    .req_valid    ({io_requestor_1_req_valid, io_requestor_0_req_valid}),
    .req_vaddr    ({io_requestor_1_req_bits_vaddr, io_requestor_0_req_bits_vaddr}),
    .req_fullva   ({io_requestor_1_req_bits_fullva, io_requestor_0_req_bits_fullva}),
    .req_checkfullva ({io_requestor_1_req_bits_checkfullva, io_requestor_0_req_bits_checkfullva}),
    .req_cmd      ({io_requestor_1_req_bits_cmd, io_requestor_0_req_bits_cmd}),
    .req_hyperinst ({io_requestor_1_req_bits_hyperinst, io_requestor_0_req_bits_hyperinst}),
    .req_hlvx     ({1'b0, 1'b0}),
    .req_kill_bit ({1'b0, 1'b0}),
    .req_is_prefetch ({1'b0, 1'b0}),
    .req_no_translate ({1'b0, 1'b0}),
    .req_pmp_addr ({48'h0, 48'h0}),
    .req_frm_mabuf ({io_requestor_1_req_bits_frm_mabuf, io_requestor_0_req_bits_frm_mabuf}),
    .req_robidx_flag ({io_requestor_1_req_bits_debug_robIdx_flag, io_requestor_0_req_bits_debug_robIdx_flag}),
    .req_robidx_value ({io_requestor_1_req_bits_debug_robIdx_value, io_requestor_0_req_bits_debug_robIdx_value}),
    .req_first_issue ({io_requestor_1_req_bits_debug_isFirstIssue, io_requestor_0_req_bits_debug_isFirstIssue}),
    .req_memidx   ({io_requestor_1_req_bits_memidx_idx, io_requestor_0_req_bits_memidx_idx}),
    .req_kill     ({1'b0, 1'b0}),
    .resp_valid (core_resp_valid), .resp_miss (core_resp_miss),
    .resp_paddr (core_paddr), .resp_gpaddr (core_gpaddr),
    .resp_pbmt (core_pbmt), .resp_fullva (core_fullva),
    .resp_memidx (core_memidx), .resp_ptw_back (core_ptw_back),
    .resp_is_for_vs_non_leaf_pte (core_vsnl),
    .resp_excp_pf_ld (core_pf_ld), .resp_excp_pf_st (core_pf_st),
    .resp_excp_gpf_ld (core_gpf_ld), .resp_excp_gpf_st (core_gpf_st),
    .resp_excp_af_ld (core_af_ld), .resp_excp_af_st (core_af_st),
    .resp_excp_is_hyper (core_is_hyper),
    .resp_excp_va_need_ext (core_va_need_ext),
    .ptw_req_valid (core_ptw_req_valid), .ptw_req_vpn (core_ptw_req_vpn),
    .ptw_req_s2xlate (core_ptw_req_s2xlate),
    .ptw_req_get_gpa (core_ptw_req_get_gpa),
    .ptw_resp_valid (io_ptw_resp_valid), .ptw_resp (ptw_resp_w),
    .pmp_valid (core_pmp_valid), .pmp_addr (core_pmp_addr),
    .pmp_cmd (core_pmp_cmd), .pmp_mode (core_pmp_mode),
    .tlbreplay (core_tlbreplay),
    .perf_access (core_perf_access), .perf_miss (core_perf_miss),
    .stor_r_req_valid (stor_r_req_valid), .stor_r_req_vpn (stor_r_req_vpn),
    .stor_r_req_s2xlate (stor_r_req_s2xlate), .stor_r_hit (ent_hit),
    .stor_r_ppn (ent_ppn), .stor_r_pbmt (ent_pbmt),
    .stor_r_g_pbmt (ent_g_pbmt), .stor_r_perm (ent_perm),
    .stor_r_g_perm (ent_g_perm), .stor_r_s2xlate (ent_s2xlate),
    .stor_w_valid (stor_w_valid), .difftest_packed (core_difftest)
  );

  // ---- 全相联页表项存储（本层不碰内容，只把查询/回填接过去）----
  TlbStorageWrapper_2 entries (
    .clock (clock), .reset (reset),
    .io_sfence_valid        (sfd_valid),
    .io_sfence_bits_rs1     (sfd_bits_rs1),
    .io_sfence_bits_rs2     (sfd_bits_rs2),
    .io_sfence_bits_addr    (sfd_bits_addr),
    .io_sfence_bits_id      (sfd_bits_id),
    .io_sfence_bits_hv      (sfd_bits_hv),
    .io_sfence_bits_hg      (sfd_bits_hg),
    .io_csr_satp_asid       (csrd_satp_asid),
    .io_csr_vsatp_asid      (csrd_vsatp_asid),
    .io_csr_hgatp_vmid      (csrd_hgatp_vmid),
    .io_csr_mbmc_BME        (csrd_mbmc_BME),
    .io_csr_mbmc_CMODE      (csrd_mbmc_CMODE),
    .io_csr_priv_virt       (csrd_priv_virt),
    .io_r_req_0_valid        (stor_r_req_valid[0]),
    .io_r_req_0_bits_vpn     (stor_r_req_vpn[0]),
    .io_r_req_0_bits_s2xlate (stor_r_req_s2xlate[0]),
    .io_r_req_1_valid        (stor_r_req_valid[1]),
    .io_r_req_1_bits_vpn     (stor_r_req_vpn[1]),
    .io_r_req_1_bits_s2xlate (stor_r_req_s2xlate[1]),
    .io_r_resp_0_bits_hit    (ent_hit_0),
    .io_r_resp_0_bits_ppn_0         (ent_0_ppn_0),
    .io_r_resp_0_bits_pbmt_0        (ent_0_pbmt_0),
    .io_r_resp_0_bits_g_pbmt_0      (ent_0_g_pbmt_0),
    .io_r_resp_0_bits_perm_0_pf     (ent_0_perm_0_pf),
    .io_r_resp_0_bits_perm_0_af     (ent_0_perm_0_af),
    .io_r_resp_0_bits_perm_0_v      (ent_0_perm_0_v),
    .io_r_resp_0_bits_perm_0_d      (ent_0_perm_0_d),
    .io_r_resp_0_bits_perm_0_a      (ent_0_perm_0_a),
    .io_r_resp_0_bits_perm_0_u      (ent_0_perm_0_u),
    .io_r_resp_0_bits_perm_0_x      (ent_0_perm_0_x),
    .io_r_resp_0_bits_perm_0_w      (ent_0_perm_0_w),
    .io_r_resp_0_bits_perm_0_r      (ent_0_perm_0_r),
    .io_r_resp_0_bits_g_perm_0_pf   (ent_0_g_perm_0_pf),
    .io_r_resp_0_bits_g_perm_0_af   (ent_0_g_perm_0_af),
    .io_r_resp_0_bits_g_perm_0_d    (ent_0_g_perm_0_d),
    .io_r_resp_0_bits_g_perm_0_a    (ent_0_g_perm_0_a),
    .io_r_resp_0_bits_g_perm_0_x    (ent_0_g_perm_0_x),
    .io_r_resp_0_bits_g_perm_0_w    (ent_0_g_perm_0_w),
    .io_r_resp_0_bits_g_perm_0_r    (ent_0_g_perm_0_r),
    .io_r_resp_0_bits_s2xlate_0     (ent_0_s2xlate_0),
    .io_r_resp_1_bits_hit    (ent_hit_1),
    .io_r_resp_1_bits_ppn_0         (ent_1_ppn_0),
    .io_r_resp_1_bits_pbmt_0        (ent_1_pbmt_0),
    .io_r_resp_1_bits_g_pbmt_0      (ent_1_g_pbmt_0),
    .io_r_resp_1_bits_perm_0_pf     (ent_1_perm_0_pf),
    .io_r_resp_1_bits_perm_0_af     (ent_1_perm_0_af),
    .io_r_resp_1_bits_perm_0_v      (ent_1_perm_0_v),
    .io_r_resp_1_bits_perm_0_d      (ent_1_perm_0_d),
    .io_r_resp_1_bits_perm_0_a      (ent_1_perm_0_a),
    .io_r_resp_1_bits_perm_0_u      (ent_1_perm_0_u),
    .io_r_resp_1_bits_perm_0_x      (ent_1_perm_0_x),
    .io_r_resp_1_bits_perm_0_w      (ent_1_perm_0_w),
    .io_r_resp_1_bits_perm_0_r      (ent_1_perm_0_r),
    .io_r_resp_1_bits_g_perm_0_pf   (ent_1_g_perm_0_pf),
    .io_r_resp_1_bits_g_perm_0_af   (ent_1_g_perm_0_af),
    .io_r_resp_1_bits_g_perm_0_d    (ent_1_g_perm_0_d),
    .io_r_resp_1_bits_g_perm_0_a    (ent_1_g_perm_0_a),
    .io_r_resp_1_bits_g_perm_0_x    (ent_1_g_perm_0_x),
    .io_r_resp_1_bits_g_perm_0_w    (ent_1_g_perm_0_w),
    .io_r_resp_1_bits_g_perm_0_r    (ent_1_g_perm_0_r),
    .io_r_resp_1_bits_s2xlate_0     (ent_1_s2xlate_0),
    .io_w_valid (stor_w_valid),
    .io_w_bits_data_s2xlate             (io_ptw_resp_bits_s2xlate),
    .io_w_bits_data_s1_entry_tag        (io_ptw_resp_bits_s1_entry_tag),
    .io_w_bits_data_s1_entry_asid       (io_ptw_resp_bits_s1_entry_asid),
    .io_w_bits_data_s1_entry_vmid       (io_ptw_resp_bits_s1_entry_vmid),
    .io_w_bits_data_s1_entry_n          (io_ptw_resp_bits_s1_entry_n),
    .io_w_bits_data_s1_entry_pbmt       (io_ptw_resp_bits_s1_entry_pbmt),
    .io_w_bits_data_s1_entry_perm_d     (io_ptw_resp_bits_s1_entry_perm_d),
    .io_w_bits_data_s1_entry_perm_a     (io_ptw_resp_bits_s1_entry_perm_a),
    .io_w_bits_data_s1_entry_perm_g     (io_ptw_resp_bits_s1_entry_perm_g),
    .io_w_bits_data_s1_entry_perm_u     (io_ptw_resp_bits_s1_entry_perm_u),
    .io_w_bits_data_s1_entry_perm_x     (io_ptw_resp_bits_s1_entry_perm_x),
    .io_w_bits_data_s1_entry_perm_w     (io_ptw_resp_bits_s1_entry_perm_w),
    .io_w_bits_data_s1_entry_perm_r     (io_ptw_resp_bits_s1_entry_perm_r),
    .io_w_bits_data_s1_entry_level      (io_ptw_resp_bits_s1_entry_level),
    .io_w_bits_data_s1_entry_v          (io_ptw_resp_bits_s1_entry_v),
    .io_w_bits_data_s1_entry_ppn        (io_ptw_resp_bits_s1_entry_ppn),
    .io_w_bits_data_s1_ppn_low_0        (io_ptw_resp_bits_s1_ppn_low_0),
    .io_w_bits_data_s1_ppn_low_1        (io_ptw_resp_bits_s1_ppn_low_1),
    .io_w_bits_data_s1_ppn_low_2        (io_ptw_resp_bits_s1_ppn_low_2),
    .io_w_bits_data_s1_ppn_low_3        (io_ptw_resp_bits_s1_ppn_low_3),
    .io_w_bits_data_s1_ppn_low_4        (io_ptw_resp_bits_s1_ppn_low_4),
    .io_w_bits_data_s1_ppn_low_5        (io_ptw_resp_bits_s1_ppn_low_5),
    .io_w_bits_data_s1_ppn_low_6        (io_ptw_resp_bits_s1_ppn_low_6),
    .io_w_bits_data_s1_ppn_low_7        (io_ptw_resp_bits_s1_ppn_low_7),
    .io_w_bits_data_s1_valididx_0       (io_ptw_resp_bits_s1_valididx_0),
    .io_w_bits_data_s1_valididx_1       (io_ptw_resp_bits_s1_valididx_1),
    .io_w_bits_data_s1_valididx_2       (io_ptw_resp_bits_s1_valididx_2),
    .io_w_bits_data_s1_valididx_3       (io_ptw_resp_bits_s1_valididx_3),
    .io_w_bits_data_s1_valididx_4       (io_ptw_resp_bits_s1_valididx_4),
    .io_w_bits_data_s1_valididx_5       (io_ptw_resp_bits_s1_valididx_5),
    .io_w_bits_data_s1_valididx_6       (io_ptw_resp_bits_s1_valididx_6),
    .io_w_bits_data_s1_valididx_7       (io_ptw_resp_bits_s1_valididx_7),
    .io_w_bits_data_s1_pteidx_0         (io_ptw_resp_bits_s1_pteidx_0),
    .io_w_bits_data_s1_pteidx_1         (io_ptw_resp_bits_s1_pteidx_1),
    .io_w_bits_data_s1_pteidx_2         (io_ptw_resp_bits_s1_pteidx_2),
    .io_w_bits_data_s1_pteidx_3         (io_ptw_resp_bits_s1_pteidx_3),
    .io_w_bits_data_s1_pteidx_4         (io_ptw_resp_bits_s1_pteidx_4),
    .io_w_bits_data_s1_pteidx_5         (io_ptw_resp_bits_s1_pteidx_5),
    .io_w_bits_data_s1_pteidx_6         (io_ptw_resp_bits_s1_pteidx_6),
    .io_w_bits_data_s1_pteidx_7         (io_ptw_resp_bits_s1_pteidx_7),
    .io_w_bits_data_s1_pf               (io_ptw_resp_bits_s1_pf),
    .io_w_bits_data_s1_af               (io_ptw_resp_bits_s1_af),
    .io_w_bits_data_s2_entry_tag        (io_ptw_resp_bits_s2_entry_tag),
    .io_w_bits_data_s2_entry_vmid       (io_ptw_resp_bits_s2_entry_vmid),
    .io_w_bits_data_s2_entry_n          (io_ptw_resp_bits_s2_entry_n),
    .io_w_bits_data_s2_entry_pbmt       (io_ptw_resp_bits_s2_entry_pbmt),
    .io_w_bits_data_s2_entry_ppn        (io_ptw_resp_bits_s2_entry_ppn),
    .io_w_bits_data_s2_entry_perm_d     (io_ptw_resp_bits_s2_entry_perm_d),
    .io_w_bits_data_s2_entry_perm_a     (io_ptw_resp_bits_s2_entry_perm_a),
    .io_w_bits_data_s2_entry_perm_g     (io_ptw_resp_bits_s2_entry_perm_g),
    .io_w_bits_data_s2_entry_perm_u     (io_ptw_resp_bits_s2_entry_perm_u),
    .io_w_bits_data_s2_entry_perm_x     (io_ptw_resp_bits_s2_entry_perm_x),
    .io_w_bits_data_s2_entry_perm_w     (io_ptw_resp_bits_s2_entry_perm_w),
    .io_w_bits_data_s2_entry_perm_r     (io_ptw_resp_bits_s2_entry_perm_r),
    .io_w_bits_data_s2_entry_level      (io_ptw_resp_bits_s2_entry_level),
    .io_w_bits_data_s2_gpf              (io_ptw_resp_bits_s2_gpf),
    .io_w_bits_data_s2_gaf              (io_ptw_resp_bits_s2_gaf)
  );

  // ---- 核 -> golden 扁平输出端口 ----
  // 核算出来但本变体没有端口的字段就不接（firtool 在 golden 里也消掉了）。
  assign io_requestor_0_resp_valid = core_resp_valid[0];
  assign io_requestor_0_resp_bits_miss = core_resp_miss[0];
  assign io_requestor_0_resp_bits_paddr_0 = core_paddr[0][0];
  assign io_requestor_0_resp_bits_gpaddr_0 = core_gpaddr[0][0];
  assign io_requestor_0_resp_bits_pbmt_0 = core_pbmt[0][0];
  assign io_requestor_0_resp_bits_fullva = core_fullva[0];
  assign io_requestor_0_resp_bits_memidx_idx = core_memidx[0];
  assign io_requestor_0_resp_bits_ptwBack = core_ptw_back[0];
  assign io_requestor_0_resp_bits_isForVSnonLeafPTE = core_vsnl[0];
  assign io_requestor_0_resp_bits_excp_0_pf_ld = core_pf_ld[0];
  assign io_requestor_0_resp_bits_excp_0_pf_st = core_pf_st[0];
  assign io_requestor_0_resp_bits_excp_0_gpf_ld = core_gpf_ld[0];
  assign io_requestor_0_resp_bits_excp_0_gpf_st = core_gpf_st[0];
  assign io_requestor_0_resp_bits_excp_0_af_ld = core_af_ld[0];
  assign io_requestor_0_resp_bits_excp_0_af_st = core_af_st[0];
  assign io_requestor_0_resp_bits_excp_0_isHyper = core_is_hyper[0];
  assign io_requestor_0_resp_bits_excp_0_vaNeedExt = core_va_need_ext[0];
  assign io_ptw_req_0_valid = core_ptw_req_valid[0];
  assign io_ptw_req_0_bits_vpn = core_ptw_req_vpn[0];
  assign io_ptw_req_0_bits_s2xlate = core_ptw_req_s2xlate[0];
  assign io_ptw_req_0_bits_getGpa = core_ptw_req_get_gpa[0];
  assign io_pmp_0_valid = core_pmp_valid[0];
  assign io_pmp_0_bits_addr = core_pmp_addr[0];
  assign io_pmp_0_bits_cmd = core_pmp_cmd[0];
  assign io_pmpMode_0 = core_pmp_mode[0];
  assign gatewayIn_packed_57_bore = core_difftest[0];
  assign io_requestor_1_resp_valid = core_resp_valid[1];
  assign io_requestor_1_resp_bits_miss = core_resp_miss[1];
  assign io_requestor_1_resp_bits_paddr_0 = core_paddr[1][0];
  assign io_requestor_1_resp_bits_gpaddr_0 = core_gpaddr[1][0];
  assign io_requestor_1_resp_bits_pbmt_0 = core_pbmt[1][0];
  assign io_requestor_1_resp_bits_fullva = core_fullva[1];
  assign io_requestor_1_resp_bits_memidx_idx = core_memidx[1];
  assign io_requestor_1_resp_bits_ptwBack = core_ptw_back[1];
  assign io_requestor_1_resp_bits_isForVSnonLeafPTE = core_vsnl[1];
  assign io_requestor_1_resp_bits_excp_0_pf_ld = core_pf_ld[1];
  assign io_requestor_1_resp_bits_excp_0_pf_st = core_pf_st[1];
  assign io_requestor_1_resp_bits_excp_0_gpf_ld = core_gpf_ld[1];
  assign io_requestor_1_resp_bits_excp_0_gpf_st = core_gpf_st[1];
  assign io_requestor_1_resp_bits_excp_0_af_ld = core_af_ld[1];
  assign io_requestor_1_resp_bits_excp_0_af_st = core_af_st[1];
  assign io_requestor_1_resp_bits_excp_0_isHyper = core_is_hyper[1];
  assign io_requestor_1_resp_bits_excp_0_vaNeedExt = core_va_need_ext[1];
  assign io_ptw_req_1_valid = core_ptw_req_valid[1];
  assign io_ptw_req_1_bits_vpn = core_ptw_req_vpn[1];
  assign io_ptw_req_1_bits_s2xlate = core_ptw_req_s2xlate[1];
  assign io_ptw_req_1_bits_getGpa = core_ptw_req_get_gpa[1];
  assign io_pmp_1_valid = core_pmp_valid[1];
  assign io_pmp_1_bits_addr = core_pmp_addr[1];
  assign io_pmp_1_bits_cmd = core_pmp_cmd[1];
  assign io_pmpMode_1 = core_pmp_mode[1];
  assign gatewayIn_packed_58_bore = core_difftest[1];
  assign io_perf_0_value = core_perf_access;
  assign io_perf_1_value = core_perf_miss;

endmodule
// END GENERATED(tlbnb-wrapper)
