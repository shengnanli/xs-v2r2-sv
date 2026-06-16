// =============================================================================
// xs_TLBNonBlock_core —— 非阻塞数据 TLB（DTLB）顶层控制（可读重写）
//
// 设计意图来自 src/main/scala/xiangshan/cache/mmu/TLB.scala（class TLB，
//   Block=false 即 TLBNonBlock；本配置 Width=4 / nRespDups=2）。
//
// 本核 = TLB 的“顶层控制逻辑”。页表项的存储匹配 + PLRU 替换在外层 wrapper 里例化的
//   golden 黑盒 TlbStorageWrapper_1，本核通过 io_entries_* 与它交互（读请求/读响应/回填）。
//   sfence/csr 的 fenceDelay=2 拍延迟也在 wrapper 里用 golden DelayN 黑盒做，延迟后的
//   信号经 io_sfd_*/io_csrd_* 进核。
//
// 数据流（两拍）：
//   s0（组合，本拍）：收 io_requestor_i.req（vaddr 等）→ 算 s2xlate / EffectiveVa /
//       预检异常 prepf/pregpf/preaf → 把 vpn 转发给存储读口（io_entries_r_req_*）。
//   s1（寄存，下一拍）：req_out_i 寄存了上拍请求；拿到存储读响应 io_entries_r_resp_i +
//       PTW 回填旁路（ptw_resp_bypass，1 拍前的 ptw_resp）→ 合成：
//         hit/miss、paddr、gpaddr、perm 检查（pf/gpf/af）、pbmt；
//         miss 时 handle_nonblock 决定发 PTW 请求还是 replay。
//
// 关键有状态逻辑：
//   - req_out_v_i：请求“在 s1 有效”的寄存位（复位清零）。
//   - need_gpa 状态机：当命中项触发 guest page fault（hasGpf）时，需要再向 PTW 要一次
//     gpaddr（need_gpa=1 锁住该 vpn，PTW 回来填 resp_gpa_gvpn，refill 标志置 1）。
//   - readResult_p_*：PTW 回填后旁路 1 拍的翻译结果（p_hit 命中时优先于存储）。
//   - ptw_resp_bits_reg_i：上拍 PTW 回填的整包寄存（ptw_already_back 用）。
//
// 可读化：4 个端口用 genvar 铺开；s2xlate/EffectiveVa/perm 检查/PTW 命中匹配等
//   用 pkg 纯函数 + 本地 function automatic；权限位用 struct。golden 因 firtool 展平
//   成 4516 行，本核结构化后显著压缩。
// =============================================================================
module xs_TLBNonBlock_core
  import xs_tlbnb_pkg::*;
(
  input  logic                clock,
  input  logic                reset,

  // ---- 延迟后的 sfence（fenceDelay=2，外层 DelayN 黑盒产生）----
  input  logic                io_sfd_valid,
  input  logic                io_sfd_flushPipe,

  // ---- 延迟后的 csr（fenceDelay=2）----
  input  logic [3:0]          io_csrd_satp_mode,
  input  logic [15:0]         io_csrd_satp_asid,
  input  logic                io_csrd_satp_changed,
  input  logic [3:0]          io_csrd_vsatp_mode,
  input  logic [15:0]         io_csrd_vsatp_asid,
  input  logic                io_csrd_vsatp_changed,
  input  logic [3:0]          io_csrd_hgatp_mode,
  input  logic [13:0]         io_csrd_hgatp_vmid,
  input  logic                io_csrd_hgatp_changed,
  input  logic                io_csrd_priv_mxr,
  input  logic                io_csrd_priv_sum,
  input  logic                io_csrd_priv_vmxr,
  input  logic                io_csrd_priv_vsum,
  input  logic                io_csrd_priv_virt,
  input  logic                io_csrd_priv_spvp,
  input  logic [1:0]          io_csrd_priv_imode,
  input  logic [1:0]          io_csrd_priv_dmode,
  input  logic [1:0]          io_csrd_pmm_mseccfg,
  input  logic [1:0]          io_csrd_pmm_menvcfg,
  input  logic [1:0]          io_csrd_pmm_henvcfg,
  input  logic [1:0]          io_csrd_pmm_hstatus,
  input  logic [1:0]          io_csrd_pmm_senvcfg,

  // ---- 请求端口（4 个，打包成数组）----
  input  logic [WIDTH-1:0]               io_req_valid,
  input  logic [WIDTH-1:0][VADDR_W-1:0]  io_req_vaddr,
  input  logic [WIDTH-1:0][63:0]         io_req_fullva,
  input  logic [WIDTH-1:0]               io_req_checkfullva,
  input  logic [WIDTH-1:0][2:0]          io_req_cmd,
  input  logic [WIDTH-1:0]               io_req_hyperinst,
  input  logic [WIDTH-1:0]               io_req_hlvx,
  input  logic [WIDTH-1:0]               io_req_kill,
  input  logic [WIDTH-1:0]               io_req_isPrefetch,
  input  logic [WIDTH-1:0]               io_req_no_translate,
  input  logic [WIDTH-1:0][47:0]         io_req_pmp_addr,
  input  logic [WIDTH-1:0]               io_req_robIdx_flag,
  input  logic [WIDTH-1:0][ROB_W-1:0]    io_req_robIdx_value,
  input  logic [WIDTH-1:0]               io_req_kill2,   // io_requestor_i_req_kill（s1 kill）

  // ---- redirect（后端冲刷）----
  input  logic                io_redirect_valid,
  input  logic                io_redirect_robIdx_flag,
  input  logic [ROB_W-1:0]    io_redirect_robIdx_value,
  input  logic                io_redirect_level,

  // ---- 与内层存储 TlbStorageWrapper 的读响应（per port，per dup）----
  input  logic [WIDTH-1:0]              io_entries_hit,
  input  logic [WIDTH-1:0][PPN_W-1:0]  io_entries_ppn_0,
  input  logic [WIDTH-1:0][PPN_W-1:0]  io_entries_ppn_1,
  input  logic [WIDTH-1:0][1:0]        io_entries_pbmt,
  input  logic [WIDTH-1:0][1:0]        io_entries_g_pbmt,
  input  tlb_perm_t [WIDTH-1:0]        io_entries_perm0,  // dup 0
  input  tlb_perm_t [WIDTH-1:0]        io_entries_perm1,  // dup 1（仅含 pf/af/v/x/w/r 有效）
  input  tlb_gperm_t [WIDTH-1:0]       io_entries_gperm0,
  input  logic [WIDTH-1:0][1:0]        io_entries_s2xlate,

  // ---- s0 给存储读口的转发 ----
  output logic [WIDTH-1:0]             io_entries_rreq_valid,
  output logic [WIDTH-1:0][VPN_W-1:0]  io_entries_rreq_vpn,
  output logic [WIDTH-1:0][1:0]        io_entries_rreq_s2xlate,

  // ---- PTW 回填（io_ptw_resp）----
  input  logic                io_ptw_resp_valid,
  input  logic [1:0]          io_ptw_resp_s2xlate,
  input  logic [34:0]         io_ptw_resp_s1_entry_tag,
  input  logic [15:0]         io_ptw_resp_s1_entry_asid,
  input  logic [13:0]         io_ptw_resp_s1_entry_vmid,
  input  logic                io_ptw_resp_s1_entry_n,
  input  logic [1:0]          io_ptw_resp_s1_entry_pbmt,
  input  logic                io_ptw_resp_s1_entry_perm_d,
  input  logic                io_ptw_resp_s1_entry_perm_a,
  input  logic                io_ptw_resp_s1_entry_perm_g,
  input  logic                io_ptw_resp_s1_entry_perm_u,
  input  logic                io_ptw_resp_s1_entry_perm_x,
  input  logic                io_ptw_resp_s1_entry_perm_w,
  input  logic                io_ptw_resp_s1_entry_perm_r,
  input  logic [1:0]          io_ptw_resp_s1_entry_level,
  input  logic                io_ptw_resp_s1_entry_v,
  input  logic [40:0]         io_ptw_resp_s1_entry_ppn,
  input  logic [2:0]          io_ptw_resp_s1_addr_low,
  input  logic [7:0]          io_ptw_resp_s1_ppn_low_flat, // {ppn_low_7..0}[2:0] 仅 bit0 用，见下
  input  logic [2:0]          io_ptw_resp_s1_ppn_low [0:7],
  input  logic [7:0]          io_ptw_resp_s1_valididx,
  input  logic [7:0]          io_ptw_resp_s1_pteidx,
  input  logic                io_ptw_resp_s1_pf,
  input  logic                io_ptw_resp_s1_af,
  input  logic [37:0]         io_ptw_resp_s2_entry_tag,
  input  logic [13:0]         io_ptw_resp_s2_entry_vmid,
  input  logic                io_ptw_resp_s2_entry_n,
  input  logic [1:0]          io_ptw_resp_s2_entry_pbmt,
  input  logic [37:0]         io_ptw_resp_s2_entry_ppn,
  input  logic                io_ptw_resp_s2_entry_perm_d,
  input  logic                io_ptw_resp_s2_entry_perm_a,
  input  logic                io_ptw_resp_s2_entry_perm_g,
  input  logic                io_ptw_resp_s2_entry_perm_u,
  input  logic                io_ptw_resp_s2_entry_perm_x,
  input  logic                io_ptw_resp_s2_entry_perm_w,
  input  logic                io_ptw_resp_s2_entry_perm_r,
  input  logic [1:0]          io_ptw_resp_s2_entry_level,
  input  logic                io_ptw_resp_s2_gpf,
  input  logic                io_ptw_resp_s2_gaf,
  input  logic                io_ptw_resp_getGpa,

  // ---- 回填使能（给存储 io_w_valid）----
  output logic                io_refill_valid,

  // ---- resp 输出（per port；位宽与 golden 一致，pbmt/paddr/excp）----
  output logic [WIDTH-1:0]             io_resp_valid,
  output logic [WIDTH-1:0][PADDR_W-1:0] io_resp_paddr0,
  output logic [WIDTH-1:0][PADDR_W-1:0] io_resp_paddr1,
  output logic [WIDTH-1:0][63:0]       io_resp_gpaddr0,
  output logic [WIDTH-1:0][63:0]       io_resp_fullva,
  output logic [WIDTH-1:0][1:0]        io_resp_pbmt0,
  output logic [WIDTH-1:0]             io_resp_miss,
  output logic [WIDTH-1:0]             io_resp_isForVSnonLeafPTE,
  output logic [WIDTH-1:0]             io_resp_excp_vaNeedExt,
  output logic [WIDTH-1:0]             io_resp_excp_isHyper,
  output logic [WIDTH-1:0]             io_resp_excp_gpf_ld,
  output logic [WIDTH-1:0]             io_resp_excp_gpf_st,
  output logic [WIDTH-1:0]             io_resp_excp_pf_ld,
  output logic [WIDTH-1:0]             io_resp_excp_pf_st,
  output logic [WIDTH-1:0]             io_resp_excp_af_ld,
  output logic [WIDTH-1:0]             io_resp_excp_af_st,

  // ---- PMP 检查请求（addr/cmd 送外部 PMP）----
  output logic [WIDTH-1:0]             io_pmp_valid,
  output logic [WIDTH-1:0][47:0]       io_pmp_addr,
  output logic [WIDTH-1:0][2:0]        io_pmp_cmd,

  // ---- PTW 请求 + replay ----
  output logic [WIDTH-1:0]             io_ptw_req_valid,
  output logic [WIDTH-1:0][VPN_W-1:0]  io_ptw_req_vpn,
  output logic [WIDTH-1:0][1:0]        io_ptw_req_s2xlate,
  output logic [WIDTH-1:0]             io_ptw_req_getGpa,
  output logic [WIDTH-1:0]             io_tlbreplay
);

  genvar gi;

  // ===========================================================================
  // 全局 satp/vsatp/hgatp 模式译码（Sv39/Sv48）
  // ===========================================================================
  wire Sv39Enable   = io_csrd_satp_mode  == 4'h8;
  wire Sv48Enable   = io_csrd_satp_mode  == 4'h9;
  wire Sv39vsEnable = io_csrd_vsatp_mode == 4'h8;
  wire Sv48vsEnable = io_csrd_vsatp_mode == 4'h9;
  wire Sv39x4Enable = io_csrd_hgatp_mode == 4'h8;
  wire Sv48x4Enable = io_csrd_hgatp_mode == 4'h9;
  wire vsatp_on = |io_csrd_vsatp_mode;
  wire hgatp_on = |io_csrd_hgatp_mode;

  // mmu flush：sfence 或 satp/vsatp/hgatp 变更（影响回填使能）
  wire flush_mmu = io_sfd_valid || io_csrd_satp_changed
                || io_csrd_vsatp_changed || io_csrd_hgatp_changed;

  // ===========================================================================
  // s1 请求寄存（req_out）—— 每端口寄存上拍请求关键字段 + valid hold
  //   req_out_v 复位清零；其余字段在 req.fire 时更新（这里 req.ready 恒 1）。
  // ===========================================================================
  logic [WIDTH-1:0]               req_out_v;
  logic [WIDTH-1:0][VADDR_W-1:0]  req_out_vaddr;
  logic [WIDTH-1:0][63:0]         req_out_fullva;     // = EffectiveVa（端口 3 无此寄存，仅占位）
  logic [WIDTH-1:0][2:0]          req_out_cmd;
  logic [WIDTH-1:0]               req_out_hyperinst;
  logic [WIDTH-1:0]               req_out_hlvx;
  logic [WIDTH-1:0]               req_out_isPrefetch;
  logic [WIDTH-1:0]               req_out_robIdx_flag;
  logic [WIDTH-1:0][ROB_W-1:0]    req_out_robIdx_value;
  logic [WIDTH-1:0]               virt_out;           // RegEnable(csr.priv.virt, req.fire)
  logic [WIDTH-1:0]               porttr_r;           // RegEnable(~no_translate, req.valid)
  logic [WIDTH-1:0]               noTransReg;         // RegNext(no_translate)
  logic [WIDTH-1:0][63:0]         resp_fullva_r;      // RegEnable(EffectiveVa, req.valid)

  // ===========================================================================
  // s0：EffectiveVa 与预检异常（prepf/pregpf/preaf）
  //   高地址位裁剪（pointer masking PMLEN7/16）+ checkfullva 触发的页/访问错误预检。
  //   这些是“真正翻译前”的快速地址合法性检查，1 拍后（REG）合入 s1 异常输出。
  // ===========================================================================
  logic [WIDTH-1:0][63:0] EffectiveVa;
  logic [WIDTH-1:0]       prepf, pregpf, preaf;
  // s0 入口算出的 s2xlate（用 req_in 的 virt/hyperinst）
  logic [WIDTH-1:0][1:0]  req_in_s2xlate;

  for (gi = 0; gi < WIDTH; gi++) begin : g_s0
    wire        hyper_in = io_req_hyperinst[gi];
    wire        virt_or_hyper_in = io_csrd_priv_virt | hyper_in;
    // premode：req_in 视角的特权模式
    wire [1:0]  premode = hyper_in ? {1'b0, io_csrd_priv_spvp} : io_csrd_priv_dmode;
    wire        prevmEnable = ~virt_or_hyper_in & (Sv39Enable|Sv48Enable) & (premode != 2'h3);
    wire        pres2xlEnable = virt_or_hyper_in
                  & (Sv39vsEnable|Sv48vsEnable|Sv39x4Enable|Sv48x4Enable) & (premode != 2'h3);

    assign req_in_s2xlate[gi] = calc_s2xlate(virt_or_hyper_in, vsatp_on, hgatp_on);

    // pointer-masking 长度选择（pmm）：决定 fullva 有效低位宽（57 / 48 / 64）
    wire [1:0] pmm =
        io_req_hlvx[gi]        ? 2'h0 :
        (&premode)             ? io_csrd_pmm_mseccfg :
        (~virt_or_hyper_in & (premode==2'h1)) ? io_csrd_pmm_menvcfg :
        ( virt_or_hyper_in & (premode==2'h1)) ? io_csrd_pmm_henvcfg :
        (hyper_in & (io_csrd_priv_imode==2'h0)) ? io_csrd_pmm_hstatus :
        (premode==2'h0)        ? io_csrd_pmm_senvcfg : 2'h0;
    wire pmm7  = (pmm == 2'h2);  // PMLEN7  → 有效低 57 位
    wire pmm16 = (&pmm);         // PMLEN16 → 有效低 48 位
    wire [63:0] fv = io_req_fullva[gi];
    // vm 使能时符号扩展，否则零扩展
    assign EffectiveVa[gi] =
        (prevmEnable | (pres2xlEnable & vsatp_on))
          ? (pmm7  ? {{7{fv[56]}}, fv[56:0]} :
             pmm16 ? {{16{fv[47]}}, fv[47:0]} : fv)
          : (pmm7  ? {7'h0, fv[56:0]} :
             pmm16 ? {16'h0, fv[47:0]} : fv);

    wire [63:0] ev = EffectiveVa[gi];
    // 高地址截断检查
    wire pf48  = {{16{ev[47]}}, ev[47:0]} != ev;
    wire pf39  = {{25{ev[38]}}, ev[38:0]} != ev;
    wire gpf48 = |ev[63:50];
    wire gpf39 = |ev[63:41];
    wire af_hi = |ev[63:48];
    wire chk = io_req_valid[gi] & io_req_checkfullva[gi];
    wire onlyS2_in = req_in_s2xlate[gi] == ONLY_STAGE2;
    assign pregpf[gi] = chk & (prevmEnable|pres2xlEnable) & onlyS2_in
                          & (Sv48x4Enable ? gpf48 : (Sv39x4Enable & gpf39));
    assign prepf[gi]  = chk & (prevmEnable|pres2xlEnable) & ~onlyS2_in
                          & ((req_in_s2xlate[gi]==ONLY_STAGE1) | (&req_in_s2xlate[gi])
                               ? (Sv48vsEnable ? pf48 : (Sv39vsEnable & pf39))
                               : (Sv48Enable   ? pf48 : (Sv39Enable   & pf39)));
    assign preaf[gi]  = chk & ~(prevmEnable|pres2xlEnable) & af_hi;

    // s0 转发给存储读口
    assign io_entries_rreq_valid[gi]   = io_req_valid[gi];
    assign io_entries_rreq_vpn[gi]     = io_req_vaddr[gi][VADDR_W-1:12];
    assign io_entries_rreq_s2xlate[gi] = req_in_s2xlate[gi];
  end

  // ===========================================================================
  // PTW 回填旁路（ptw_resp_bypass）+ need_gpa 状态机 + lastCycleRedirect 等
  //   这些是跨拍的共享状态，先声明，再在 s1 逐端口与最后的时序块里使用/更新。
  // ===========================================================================
  // —— need_gpa：命中项触发 gpf 时，向 PTW 再要 gpaddr，锁住该 vpn ——
  logic                need_gpa;
  logic                need_gpa_wire;       // 本拍刚要进入 need_gpa（组合）
  logic                need_gpa_robidx_flag;
  logic [ROB_W-1:0]    need_gpa_robidx_value;
  logic [VPN_W-1:0]    need_gpa_vpn;
  logic [GVPN_W-1:0]   resp_gpa_gvpn;       // PTW 回来填的 guest vpn
  logic                resp_gpa_refill;     // gpaddr 已 refill 标志
  logic [1:0]          resp_s1_level;
  logic                resp_s1_isLeaf;
  logic                resp_s1_isFakePte;

  // —— lastCycleRedirect 寄存（RegNext(redirect)）——
  logic                lcr_valid;
  logic                lcr_robIdx_flag;
  logic [ROB_W-1:0]    lcr_robIdx_value;
  logic                lcr_level;

  // —— readResult_p_*：PTW 回填后旁路 1 拍的翻译结果（per port）——
  logic [WIDTH-1:0]              p_hit;        // GatedValidRegNext(...)
  logic [WIDTH-1:0][PPN_W-1:0]  p_ppn;
  logic [WIDTH-1:0][1:0]        p_pbmt;
  tlb_perm_t [WIDTH-1:0]        p_perm;
  logic [WIDTH-1:0][GVPN_W-1:0] p_gvpn;
  logic [WIDTH-1:0][1:0]        p_g_pbmt;
  tlb_gperm_t [WIDTH-1:0]       p_g_perm;
  logic [WIDTH-1:0][1:0]        p_s2xlate;
  logic [WIDTH-1:0][1:0]        p_s1_level;
  logic [WIDTH-1:0]             p_s1_isLeaf;
  logic [WIDTH-1:0]             p_s1_isFakePte;

  // —— ptw_resp 整包寄存（ptw_already_back 用）——
  logic [WIDTH-1:0][1:0]        pr_s2xlate;
  logic [WIDTH-1:0][34:0]       pr_s1_tag;
  logic [WIDTH-1:0][15:0]       pr_s1_asid;
  logic [WIDTH-1:0][13:0]       pr_s1_vmid;
  logic [WIDTH-1:0]             pr_s1_n;
  logic [WIDTH-1:0]             pr_s1_perm_g;
  logic [WIDTH-1:0][1:0]        pr_s1_level;
  logic [WIDTH-1:0][2:0]        pr_s1_addr_low;
  logic [WIDTH-1:0][7:0]        pr_s1_valididx;
  logic [WIDTH-1:0][37:0]       pr_s2_tag;
  logic [WIDTH-1:0][13:0]       pr_s2_vmid;
  logic [WIDTH-1:0]             pr_s2_n;
  logic [WIDTH-1:0][1:0]        pr_s2_level;
  logic [WIDTH-1:0]             ptw_already_back_last;  // RegNext(ptw_resp_valid)
  logic [WIDTH-1:0]             req_last;               // RegNext(req_valid)（kill 用）

  // ===========================================================================
  // 纯函数：PTW 回填项的 hit() 匹配（多级 tag/level/napot 匹配）
  //   对应 Chisel TLBEntry.hit(vpn, asid, vasid, vmid, allType=true)。
  //   一阶段（s1）和二阶段（s2）项各有 tag 切分；level 决定比到第几级；n=napot。
  //   ignoreAsid=false：noS2/onlyS1 比 asid 或 perm.g；onlyS2 比 vmid。
  // ===========================================================================
  // s1（VS/S 阶段）项命中：给定 entry 字段 + 待查 vaddr
  function automatic logic s1_entry_hit(
    input logic [34:0] tag, input logic n, input logic [1:0] level,
    input logic [49:0] vaddr, input logic [7:0] valididx
  );
    logic m3, m2, m1, lvlmatch;
    m1 = tag[14:6]  == vaddr[29:21];
    m2 = tag[23:15] == vaddr[38:30];
    m3 = tag[34:24] == vaddr[49:39];
    if (level == 2'h0)
      lvlmatch = (m3 & m2) & m1
               & (n ? (tag[5:1] == vaddr[20:16]) : (tag[5:0] == vaddr[20:15]));
    else if (level == 2'h1)
      lvlmatch = (m3 & m2) & m1;
    else
      lvlmatch = ((level != 2'h2) | m2) & m3;
    return lvlmatch & ((|level) | n | valididx[vaddr[14:12]]);
  endfunction

  // onlyS2（G 阶段）项命中
  function automatic logic s2_entry_hit(
    input logic [37:0] tag, input logic n, input logic [1:0] level,
    input logic [49:0] vaddr
  );
    logic m3, m2, m1;
    m1 = tag[17:9]  == vaddr[29:21];
    m2 = tag[26:18] == vaddr[38:30];
    m3 = tag[37:27] == vaddr[49:39];
    if (level == 2'h0)
      return (m3 & m2) & m1 & (n ? (tag[8:4]==vaddr[20:16]) : (tag[8:0]==vaddr[20:12]));
    else if (level == 2'h1)
      return (m3 & m2) & m1;
    else
      return ((level != 2'h2) | m2) & m3;
  endfunction

  // allStage（两级）项命中见下方 all_hit_full（含 addr_low 拼接）。

  // ===========================================================================
  // s1 逐端口：合成命中/miss/paddr/perm/异常 + handle_nonblock
  // ===========================================================================
  // 这些信号需要在最终时序块里被引用（如 readResult_T_* 控制 need_gpa 更新），
  // 故声明为模块级数组。
  logic [WIDTH-1:0] hit_read, miss_read;
  logic [WIDTH-1:0] hasGpf;
  logic [WIDTH-1:0] porttr;            // portTranslateEnable
  logic [WIDTH-1:0] isHyperInst;
  logic [WIDTH-1:0][1:0] req_out_s2xlate;
  logic [WIDTH-1:0] REG_pre;           // RegNext(prepf|pregpf|preaf)
  logic [WIDTH-1:0] excp_pf_ld_REG, excp_pf_st_REG, excp_gpf_ld_REG, excp_gpf_st_REG;
  logic [WIDTH-1:0] excp_af_ld_REG, excp_af_st_REG;
  // need_gpa 状态机的逐端口控制项(对应 golden readResult 的 redirect/enter 控制位)
  logic [WIDTH-1:0] rr_T_redirect;     // golden readResult redirect 命中位：本拍 redirect 命中（非 itlb）
  logic [WIDTH-1:0] rr_T_enter;        // golden readResult enter 位：本端口要进入 need_gpa
  logic [WIDTH-1:0] rr_T_ptwhit;       // golden readResult ptwhit 位：PTW 回来命中 need_gpa_vpn

  // PTW 回包的 level（s2xlate 决定取 s1/s2 的 level）—— 多处复用，组合算一次。
  wire [1:0] ptw_level = (|io_ptw_resp_s2xlate)
      ? ((&io_ptw_resp_s2xlate)
           ? (io_ptw_resp_s1_entry_level < io_ptw_resp_s2_entry_level
                ? io_ptw_resp_s1_entry_level : io_ptw_resp_s2_entry_level)
           : (io_ptw_resp_s2xlate==ONLY_STAGE2 ? io_ptw_resp_s2_entry_level
                                               : io_ptw_resp_s1_entry_level))
      : io_ptw_resp_s1_entry_level;
  wire [2:0] ptw_pteidx_or = io_ptw_resp_s1_pteidx[7:5] | io_ptw_resp_s1_pteidx[3:1];
  // s1 napot ppn 低 3 位（ppn_low_*[0] 拼）
  wire [2:0] ptw_napot_low =
      {io_ptw_resp_s1_ppn_low[2][0], io_ptw_resp_s1_ppn_low[1][0], io_ptw_resp_s1_ppn_low[0][0]};

  // PTW 回包 getVpn(need_gpa_vpn)：按 s2xlate/level 取被 napot/level 截断后的 vpn 段。
  //   对应 golden 的 s1/s2 tag 选择 + level 索引。组合算出（只读 need_gpa_vpn + ptw）。
  logic [VPN_W-1:0] ptw_getvpn_w;
  always_comb begin
    logic [VPN_W-1:0] s1v [0:3];
    logic [VPN_W-1:0] s2v [0:3];
    s1v[0] = {io_ptw_resp_s1_entry_tag, |io_ptw_resp_s1_pteidx[7:4],
              |ptw_pteidx_or[2:1], ptw_pteidx_or[2]|ptw_pteidx_or[0]};
    s1v[1] = {io_ptw_resp_s1_entry_tag[34:6],  need_gpa_vpn[8:0]};
    s1v[2] = {io_ptw_resp_s1_entry_tag[34:15], need_gpa_vpn[17:0]};
    s1v[3] = {io_ptw_resp_s1_entry_tag[34:24], need_gpa_vpn[26:0]};
    s2v[0] = io_ptw_resp_s2_entry_tag;
    s2v[1] = {io_ptw_resp_s2_entry_tag[37:9],  need_gpa_vpn[8:0]};
    s2v[2] = {io_ptw_resp_s2_entry_tag[37:18], need_gpa_vpn[17:0]};
    s2v[3] = {io_ptw_resp_s2_entry_tag[37:27], need_gpa_vpn[26:0]};
    ptw_getvpn_w = (io_ptw_resp_s2xlate==ONLY_STAGE2) ? s2v[ptw_level] : s1v[ptw_level];
  end

  for (gi = 0; gi < WIDTH; gi++) begin : g_s1
    wire [VADDR_W-1:0] vaddr = req_out_vaddr[gi];
    wire [2:0]  cmd  = req_out_cmd[gi];
    wire        hlvx = req_out_hlvx[gi];
    wire        virt_or_hyper = virt_out[gi] | (req_out_v[gi] & req_out_hyperinst[gi]);
    assign isHyperInst[gi] = req_out_v[gi] & req_out_hyperinst[gi];
    wire [1:0]  mode = isHyperInst[gi] ? {1'b0, io_csrd_priv_spvp} : io_csrd_priv_dmode;
    assign req_out_s2xlate[gi] = calc_s2xlate(virt_or_hyper, vsatp_on, hgatp_on);
    wire        onlyS2 = req_out_s2xlate[gi] == ONLY_STAGE2;
    wire        s2both = onlyS2 | (&req_out_s2xlate[gi]);  // onlyS2 或 allStage
    wire        isitlb = cmd[1:0] == 2'h2;

    // portTranslateEnable：本端口本拍真正要做翻译
    wire vmE = ~virt_or_hyper & (Sv39Enable|Sv48Enable) & (mode != 2'h3);
    wire s2E =  virt_or_hyper & (Sv39vsEnable|Sv48vsEnable|Sv39x4Enable|Sv48x4Enable) & (mode != 2'h3);
    assign porttr[gi] = (vmE | s2E) & porttr_r[gi];

    // —— dup 选择：p_hit（PTW 旁路命中）优先于存储读响应 ——
    // dup 0 用于权限检查，dup 1 用于 paddr/isForVSnonLeafPTE
    tlb_perm_t  perm0, perm1;
    tlb_gperm_t gperm0;
    logic [PPN_W-1:0] ppn0, ppn1;
    logic [1:0] pbmt_d, gpbmt_d, rs2x;
    logic isFakePteSel;
    assign perm0  = p_hit[gi] ? p_perm[gi] : io_entries_perm0[gi];
    assign perm1  = p_hit[gi] ? p_perm[gi] : io_entries_perm1[gi];
    assign gperm0 = p_hit[gi] ? p_g_perm[gi] : io_entries_gperm0[gi];
    assign ppn0   = p_hit[gi] ? p_ppn[gi] : io_entries_ppn_0[gi];
    assign ppn1   = p_hit[gi] ? p_ppn[gi] : io_entries_ppn_1[gi];
    assign pbmt_d = p_hit[gi] ? p_pbmt[gi] : io_entries_pbmt[gi];
    assign gpbmt_d= p_hit[gi] ? p_g_pbmt[gi] : io_entries_g_pbmt[gi];
    assign rs2x   = p_hit[gi] ? p_s2xlate[gi] : io_entries_s2xlate[gi];
    assign isFakePteSel = p_hit[gi] ? p_s1_isFakePte[gi] : resp_s1_isFakePte;

    // —— hit / miss ——
    wire need_gpa_vpn_hit = need_gpa_vpn == vaddr[VADDR_W-1:12];
    assign hit_read[gi] = io_entries_hit[gi] | p_hit[gi];
    // lastCycleRedirect 命中本端口（用上拍 redirect 寄存）
    wire lcr_hit = lcr_valid
        & ( (lcr_level & ({req_out_robIdx_flag[gi],req_out_robIdx_value[gi]}
                            == {lcr_robIdx_flag, lcr_robIdx_value}))
            | (req_out_robIdx_flag[gi]^lcr_robIdx_flag
               ^ (req_out_robIdx_value[gi] > lcr_robIdx_value)) );
    assign miss_read[gi] = (~hit_read[gi] & porttr[gi])
        | (hasGpf[gi] & ~p_hit[gi] & ~(resp_gpa_refill & need_gpa_vpn_hit)
           & ~onlyS2 & ~req_out_isPrefetch[gi] & ~lcr_hit);

    // ===== 权限检查（perm_check，对应 Scala def perm_check）=====
    wire isLd   = cmd_is_ld(cmd);
    wire isSt   = cmd_is_st(cmd);
    wire isInst = cmd_is_inst(cmd);
    // af：noS2/onlyS1 → perm.af；onlyS2/allStage → g_perm.af
    wire af = (~onlyS2 & perm0.af) | (s2both & gperm0.af);
    // modeCheck：U 态访问非 U 页 / S 态访问 U 页且 !sum 失败
    wire modeFail = (mode==2'h0 & ~perm0.u)
                  | (mode==2'h1 & perm0.u & ~(virt_or_hyper ? io_csrd_priv_vsum : io_csrd_priv_sum));
    wire ldPermFail = ~(~modeFail & (hlvx ? perm0.x
                          : (perm0.r | ((virt_or_hyper & io_csrd_priv_vmxr | io_csrd_priv_mxr) & perm0.x))));
    wire stPermFail = ~(~modeFail & perm0.w);
    wire inPermFail = ~(~modeFail & perm0.x);
    wire ldPf = (ldPermFail | perm0.pf) & isLd;
    wire stPf = (stPermFail | perm0.pf) & isSt;
    wire inPf = (inPermFail | perm0.pf) & isInst;
    wire ldUpd = ~perm0.a & isLd;
    wire stUpd = (~perm0.a | ~perm0.d) & isSt;
    wire inUpd = ~perm0.a & isInst;
    wire isFakePte = ~perm0.v & ~perm0.pf & ~perm0.af & ~onlyS2;
    wire isNonLeaf = ~(perm0.r|perm0.w|perm0.x) & perm0.v & ~perm0.pf & ~perm0.af;
    wire s1_valid = porttr[gi] & ~onlyS2;
    wire s2_valid = porttr[gi] & s2both;
    wire fault_valid = s1_valid | s2_valid;
    // G-stage 权限失败
    wire g_ldPermFail = ~(hlvx ? gperm0.x : (gperm0.r | (io_csrd_priv_mxr & gperm0.x)));
    wire g_stPermFail = ~gperm0.w;
    wire g_inPermFail = ~gperm0.x;
    wire ldGpf = (g_ldPermFail | gperm0.pf) & isLd;
    wire stGpf = (g_stPermFail | gperm0.pf) & isSt;
    wire inGpf = (g_inPermFail | gperm0.pf) & isInst;
    wire g_ldUpd = ~gperm0.a & isLd;
    wire g_stUpd = (~gperm0.a | ~gperm0.d) & isSt;
    wire g_inUpd = ~gperm0.a & isInst;
    // hasPf：s1 page fault 综合（gpf 须 & ~hasPf，pf 优先级高）
    wire hasPf = (ldPf|ldUpd|stPf|stUpd|inPf|inUpd) & s1_valid & ~af & ~isFakePte & ~isNonLeaf;

    // 输出异常（REG_pre 为真时改用预检异常 prepf/pregpf/preaf 的寄存版）
    wire pf_ld_dyn = (ldPf|ldUpd) & s1_valid & ~af & ~isFakePte & ~isNonLeaf;
    wire pf_st_dyn = (stPf|stUpd) & s1_valid & ~af & ~isFakePte & ~isNonLeaf;
    wire gpf_ld_dyn= (ldGpf|g_ldUpd) & s2_valid & ~af & ~hasPf;
    wire gpf_st_dyn= (stGpf|g_stUpd) & s2_valid & ~af & ~hasPf;
    wire gpf_in_dyn= (inGpf|g_inUpd) & s2_valid & ~af & ~hasPf;

    assign io_resp_excp_pf_ld[gi] = REG_pre[gi] ? (excp_pf_ld_REG[gi] & isLd) : pf_ld_dyn;
    assign io_resp_excp_pf_st[gi] = REG_pre[gi] ? (excp_pf_st_REG[gi] & isSt) : pf_st_dyn;
    wire gpf_ld_o = REG_pre[gi] ? (excp_gpf_ld_REG[gi] & isLd) : gpf_ld_dyn;
    wire gpf_st_o = REG_pre[gi] ? (excp_gpf_st_REG[gi] & isSt) : gpf_st_dyn;
    assign io_resp_excp_gpf_ld[gi] = gpf_ld_o;
    assign io_resp_excp_gpf_st[gi] = gpf_st_o;
    assign io_resp_excp_af_ld[gi] = REG_pre[gi]
        ? (excp_af_ld_REG[gi] & cmd_is_read(cmd)) : (af & cmd_is_read(cmd) & fault_valid);
    assign io_resp_excp_af_st[gi] = REG_pre[gi]
        ? (excp_af_st_REG[gi] & cmd_is_write(cmd)) : (af & cmd_is_write(cmd) & fault_valid);
    assign io_resp_excp_vaNeedExt[gi] = ~REG_pre[gi];
    assign io_resp_excp_isHyper[gi]   = isHyperInst[gi];
    // isForVSnonLeafPTE（gpf 时给 CSR 用，用 dup1 的 perm）
    assign io_resp_isForVSnonLeafPTE[gi] = ~REG_pre[gi]
        & ( (~(perm1.r|perm1.w|perm1.x) & perm1.v & ~perm1.pf & ~perm1.af)
          | (~perm1.v & ~perm1.pf & ~perm1.af & ~onlyS2) );

    // hasGpf：命中且本端口产生 guest page fault（ld/st/instr 之一）
    assign hasGpf[gi] = hit_read[gi] & ( gpf_ld_o | gpf_st_o
        | (~REG_pre[gi] & ((~gperm0.x|gperm0.pf)&isInst | ~gperm0.a&isInst) & s2_valid & ~af & ~hasPf) );

    // ===== paddr / gpaddr / pbmt 合成 =====
    // paddr0 = porttr ? {ppn0, off} : vaddr[47:0]
    assign io_resp_paddr0[gi] = porttr[gi] ? {ppn0, vaddr[11:0]} : vaddr[47:0];
    assign io_resp_paddr1[gi] = porttr[gi] ? {ppn1, vaddr[11:0]} : vaddr[47:0];
    // pbmt：noS2→pbmt onlyS2→g_pbmt allStage→pbmt!=0?pbmt:g_pbmt
    wire [1:0] pbmt_res = (req_out_s2xlate[gi]==ALL_STAGE) ? ((|pbmt_d) ? pbmt_d : gpbmt_d)
                        : (req_out_s2xlate[gi]==ONLY_STAGE2) ? gpbmt_d : pbmt_d;
    assign io_resp_pbmt0[gi] = porttr[gi] ? pbmt_res : 2'h0;

    // gpaddr 合成（跨页 fullva 处理 + leaf/非 leaf gpaddr_offset）
    wire isFakePteSel_q = p_hit[gi] ? p_s1_isFakePte[gi] : resp_s1_isFakePte;
    wire isLeafSel  = p_hit[gi] ? p_s1_isLeaf[gi] : resp_s1_isLeaf;
    wire [1:0] levelSel = p_hit[gi] ? p_s1_level[gi] : resp_s1_level;
    wire [GVPN_W-1:0] gvpnSel = p_hit[gi] ? p_gvpn[gi] : resp_gpa_gvpn;
    wire [1:0] rs2xSel = p_hit[gi] ? p_s2xlate[gi] : io_entries_s2xlate[gi];
    wire [63:0] vaddr_se = {{14{vaddr[VADDR_W-1]}}, vaddr};   // SignExt(vaddr,64) 取低48用
    wire [63:0] crossPageVaddr = (isitlb | (req_out_fullva[gi][12] != vaddr[12]))
                                  ? {16'h0, vaddr[47:0]} : req_out_fullva[gi];
    wire [1:0] vpn_idx = isFakePteSel_q & (io_csrd_vsatp_mode==4'h8) ? 2'h2
                       : isFakePteSel_q & (io_csrd_vsatp_mode==4'h9) ? 2'h3
                       : (levelSel - 2'h1);
    wire [8:0] vpnn = get_vpnn(crossPageVaddr[VADDR_W-1:12], vpn_idx);
    wire [11:0] gpaddr_off = isLeafSel ? crossPageVaddr[11:0] : {vpnn, 3'h0};
    assign io_resp_gpaddr0[gi] = REG_pre[gi]
        ? req_out_fullva[gi]
        : ((rs2xSel == ONLY_STAGE2) ? crossPageVaddr
                                    : {8'h0, gvpnSel, gpaddr_off});

    assign io_resp_fullva[gi] = resp_fullva_r[gi];
    assign io_resp_miss[gi]   = ~REG_pre[gi] & miss_read[gi];
    assign io_resp_valid[gi]  = req_out_v[gi];

    // ===== PMP 检查请求 =====
    assign io_pmp_valid[gi] = req_out_v[gi] | noTransReg[gi];
    assign io_pmp_addr[gi]  = noTransReg[gi] ? io_req_pmp_addr[gi] : io_resp_paddr0[gi];
    assign io_pmp_cmd[gi]   = cmd;

    // ===== handle_nonblock：miss → PTW 请求 或 replay =====
    // req_s2xlate（用 s1 视角）
    wire [1:0] req_s2x = calc_s2xlate(virt_out[gi] | req_out_hyperinst[gi], vsatp_on, hgatp_on);
    // ptw_just_back：本拍 PTW 回填且命中本请求 vpn
    wire pjb_s1 = s1_entry_hit(io_ptw_resp_s1_entry_tag, io_ptw_resp_s1_entry_n,
                               io_ptw_resp_s1_entry_level, vaddr, io_ptw_resp_s1_valididx)
                & (io_ptw_resp_s1_entry_asid==io_csrd_satp_asid | io_ptw_resp_s1_entry_perm_g);
    wire pjb_s2 = s2_entry_hit(io_ptw_resp_s2_entry_tag, io_ptw_resp_s2_entry_n,
                               io_ptw_resp_s2_entry_level, vaddr)
                & ({2'h0,io_ptw_resp_s2_entry_vmid}==io_csrd_hgatp_vmid);
    wire pjb_all= all_hit_full(io_ptw_resp_s1_entry_tag, io_ptw_resp_s1_entry_n,
                    io_ptw_resp_s1_entry_level, io_ptw_resp_s1_addr_low,
                    io_ptw_resp_s2_entry_n, io_ptw_resp_s2_entry_level,
                    io_ptw_resp_s2xlate==ONLY_STAGE1, vaddr)
                & ({2'h0,io_ptw_resp_s1_entry_vmid}==io_csrd_hgatp_vmid)
                & (io_ptw_resp_s1_entry_asid==io_csrd_vsatp_asid | io_ptw_resp_s1_entry_perm_g);
    wire ptw_just_back = io_ptw_resp_valid & (req_s2x==io_ptw_resp_s2xlate)
        & ((|io_ptw_resp_s2xlate) ? (io_ptw_resp_s2xlate==ONLY_STAGE2 ? pjb_s2 : pjb_all) : pjb_s1);

    // ptw_already_back：上拍 PTW 回填寄存后命中
    wire pab_s1 = s1_entry_hit(pr_s1_tag[gi], pr_s1_n[gi], pr_s1_level[gi], vaddr, pr_s1_valididx[gi])
                & (pr_s1_asid[gi]==io_csrd_satp_asid | pr_s1_perm_g[gi]);
    wire pab_s2 = s2_entry_hit(pr_s2_tag[gi], pr_s2_n[gi], pr_s2_level[gi], vaddr)
                & ({2'h0,pr_s2_vmid[gi]}==io_csrd_hgatp_vmid);
    wire pab_all= all_hit_full(pr_s1_tag[gi], pr_s1_n[gi], pr_s1_level[gi], pr_s1_addr_low[gi],
                    pr_s2_n[gi], pr_s2_level[gi], pr_s2xlate[gi]==ONLY_STAGE1, vaddr)
                & ({2'h0,pr_s1_vmid[gi]}==io_csrd_hgatp_vmid)
                & (pr_s1_asid[gi]==io_csrd_vsatp_asid | pr_s1_perm_g[gi]);
    wire ptw_already_back = ptw_already_back_last[gi] & (req_s2x==pr_s2xlate[gi])
        & (pr_s2xlate[gi]==NO_S2XLATE ? pab_s1
         : pr_s2xlate[gi]==ONLY_STAGE2 ? pab_s2 : pab_all);

    wire need_gpa_state_block = need_gpa & (need_gpa_vpn != vaddr[VADDR_W-1:12]) & ~resp_gpa_refill;
    wire miss_active = req_out_v[gi] & miss_read[gi];   // golden miss-active 链
    wire kill_replay = io_req_kill2[gi] & req_last[gi];  // golden kill-replay 链 (端口3无s1kill)

    // miss 且非（刚回填/already-back/need_gpa 占用）→ 发 PTW 请求；否则 replay
    assign io_ptw_req_valid[gi]  = (gi==3) ? (miss_active & ~ptw_just_back & ~ptw_already_back & ~need_gpa_state_block)
                                           : (~kill_replay & miss_active & ~(ptw_just_back|ptw_already_back) & ~need_gpa_state_block);
    assign io_ptw_req_vpn[gi]    = vaddr[VADDR_W-1:12];
    assign io_ptw_req_s2xlate[gi]= req_s2x;
    assign io_ptw_req_getGpa[gi] = hasGpf[gi] & hit_read[gi];
    assign io_tlbreplay[gi]      = (gi==3) ? (miss_active & ((ptw_just_back|ptw_already_back)|need_gpa_state_block))
                                           : (kill_replay | (miss_active & ((ptw_just_back|ptw_already_back)|need_gpa_state_block)));

    // need_gpa 状态机控制项（与最终时序块共享）
    assign rr_T_redirect[gi] = ~isitlb & io_redirect_valid
        & ( (io_redirect_level & ({need_gpa_robidx_flag,need_gpa_robidx_value}
                                   == {io_redirect_robIdx_flag,io_redirect_robIdx_value}))
          | ((need_gpa_robidx_flag^io_redirect_robIdx_flag)
             ^ (need_gpa_robidx_value > io_redirect_robIdx_value)) );
    wire cur_redirect = io_redirect_valid
        & ( (io_redirect_level & ({req_out_robIdx_flag[gi],req_out_robIdx_value[gi]}
                                   == {io_redirect_robIdx_flag,io_redirect_robIdx_value}))
          | (req_out_robIdx_flag[gi]^io_redirect_robIdx_flag
             ^ (req_out_robIdx_value[gi] > io_redirect_robIdx_value)) );
    // golden enter 位里的 req_kill：端口 0/1/2 用 s1 kill；端口 3 无此项（恒 0，wrapper 已 tie）
    assign rr_T_enter[gi] = req_out_v[gi] & ~p_hit[gi]
        & ~(resp_gpa_refill & need_gpa_vpn_hit) & ~onlyS2 & hasGpf[gi] & ~need_gpa
        & ~io_req_kill2[gi] & ~req_out_isPrefetch[gi] & ~cur_redirect & ~lcr_hit;
    // ptw 命中 need_gpa_vpn (golden ptwhit 位)：用 PTW 回包的 getVpn(need_gpa_vpn) 比对
    assign rr_T_ptwhit[gi] = io_ptw_resp_valid & need_gpa
        & (need_gpa_vpn == ptw_getvpn_w);
  end

  // ===========================================================================
  // 纯函数：allStage hit 的完整版（含 addr_low 拼接，level-0 用）
  // ===========================================================================
  function automatic logic all_hit_full(
    input logic [34:0] tag, input logic s1_n, input logic [1:0] s1_level,
    input logic [2:0] addr_low,
    input logic s2_n, input logic [1:0] s2_level, input logic s2xlate_onlyS1,
    input logic [49:0] vaddr
  );
    logic m3, m2, m1;
    logic [1:0] lvl;
    logic nsel;
    m1 = vaddr[29:21] == tag[14:6];
    m2 = vaddr[38:30] == tag[23:15];
    m3 = vaddr[49:39] == tag[34:24];
    lvl  = (s2xlate_onlyS1 | (s1_level < s2_level)) ? s1_level : s2_level;
    nsel = s2xlate_onlyS1 ? s1_n
         : (s1_n & (|s2_level)) | (s2_n & (|s1_level)) | (s1_n & s2_n);
    if (lvl == 2'h0)
      return (m3 & m2) & m1
           & (nsel ? (vaddr[20:16]==tag[5:1]) : (vaddr[20:12]=={tag[5:0],addr_low}));
    else if (lvl == 2'h1)
      return (m3 & m2) & m1;
    else
      return ((lvl != 2'h2) | m2) & m3;
  endfunction

  // ===========================================================================
  // need_gpa_wire（组合）：本拍是否有任一端口要进入 need_gpa（优先级 3>2>1>0）。
  //   对应 golden assign need_gpa_wire = ...（每端口 ~T_redirect & T_enter 的或）。
  // ===========================================================================
  assign need_gpa_wire = (~rr_T_redirect[3] & rr_T_enter[3])
                       | (~rr_T_redirect[2] & rr_T_enter[2])
                       | (~rr_T_redirect[1] & rr_T_enter[1])
                       | (~rr_T_redirect[0] & rr_T_enter[0]);

  // ===========================================================================
  // 回填使能：PTW 回包非 getGpa、非 need_gpa 占用、非 mmu flush 时写存储。
  // ===========================================================================
  assign io_refill_valid = io_ptw_resp_valid & ~io_ptw_resp_getGpa
                         & ~need_gpa & ~need_gpa_wire & ~flush_mmu;

  // ===========================================================================
  // genPPN / genGVPN（PTW 回填合成 ppn/gvpn）—— 纯函数（PTW 字段全经参数传入，
  //   避免 FM 把“函数读非局部信号”判为 RTL 解释错误）。
  //   按 entry.level 把页内偏移段从 ppn 换成 vpn（superpage），napot 再特殊处理。
  // ===========================================================================
  function automatic logic [GVPN_W-1:0] gen_s1_ppn44(
    input logic [40:0] ppn, input logic n, input logic [1:0] level,
    input logic [2:0] napot_low, input logic [VPN_W-1:0] v
  );
    logic [GVPN_W-1:0] r [0:3];
    r[3] = {ppn[40:24], v[26:0]};
    r[2] = {ppn[40:15], v[17:0]};
    r[1] = {ppn[40:6],  v[8:0]};
    r[0] = n ? {ppn[40:1], v[3:0]} : {ppn, napot_low};
    return r[level];
  endfunction

  function automatic logic [37:0] gen_s2_ppn38(
    input logic [37:0] ppn, input logic n, input logic [1:0] level, input logic [26:0] gv
  );
    logic [37:0] r [0:3];
    r[3] = {ppn[37:27], gv};
    r[2] = {ppn[37:18], gv[17:0]};
    r[1] = {ppn[37:9],  gv[8:0]};
    r[0] = n ? {ppn[37:4], gv[3:0]} : ppn;
    return r[level];
  endfunction

  function automatic logic [GVPN_W-1:0] gen_gvpn(
    input logic [40:0] ppn, input logic n, input logic [1:0] level,
    input logic [2:0] napot_low, input logic [37:0] s2tag,
    input logic isNonLeaf, input logic onlyS2, input logic [VPN_W-1:0] v
  );
    logic [GVPN_W-1:0] r [0:3];
    if (onlyS2) return {6'h0, s2tag};
    if (isNonLeaf) return {ppn, napot_low};  // 非叶子取 {ppn,napot}
    r[3] = {ppn[40:24], v[26:0]};
    r[2] = {ppn[40:15], v[17:0]};
    r[1] = {ppn[40:6],  v[8:0]};
    r[0] = n ? {ppn[40:1], v[3:0]} : {ppn, napot_low};
    return r[level];
  endfunction

  // gen_gvpn 的“非叶子”判据（gvpn 路径用）
  wire ptw_gvpn_isNonLeaf =
      ~(io_ptw_resp_s1_entry_perm_r|io_ptw_resp_s1_entry_perm_x|io_ptw_resp_s1_entry_perm_w)
      & io_ptw_resp_s1_entry_v & ~io_ptw_resp_s1_pf & ~io_ptw_resp_s1_af;

  // ptw 回填的 perm/gperm bundle（直接从 io_ptw_resp 取）
  wire tlb_perm_t  ptw_perm  = '{pf:io_ptw_resp_s1_pf, af:io_ptw_resp_s1_af,
       v:io_ptw_resp_s1_entry_v, d:io_ptw_resp_s1_entry_perm_d, a:io_ptw_resp_s1_entry_perm_a,
       u:io_ptw_resp_s1_entry_perm_u, x:io_ptw_resp_s1_entry_perm_x,
       w:io_ptw_resp_s1_entry_perm_w, r:io_ptw_resp_s1_entry_perm_r};
  wire tlb_gperm_t ptw_gperm = '{pf:io_ptw_resp_s2_gpf, af:io_ptw_resp_s2_gaf,
       d:io_ptw_resp_s2_entry_perm_d, a:io_ptw_resp_s2_entry_perm_a,
       x:io_ptw_resp_s2_entry_perm_x, w:io_ptw_resp_s2_entry_perm_w, r:io_ptw_resp_s2_entry_perm_r};
  wire ptw_isLeaf = (io_ptw_resp_s1_entry_perm_r|io_ptw_resp_s1_entry_perm_x
                     |io_ptw_resp_s1_entry_perm_w) & io_ptw_resp_s1_entry_v;
  wire ptw_isFakePte = ~io_ptw_resp_s1_pf & ~io_ptw_resp_s1_entry_v & ~io_ptw_resp_s1_af;

  // resp_gpa_gvpn 的下一拍值（need_gpa_vpn 视角，组合）
  wire [GVPN_W-1:0] resp_gpa_gvpn_next = (io_ptw_resp_s2xlate==ONLY_STAGE2)
      ? {6'h0, io_ptw_resp_s2_entry_tag}
      : gen_gvpn(io_ptw_resp_s1_entry_ppn, io_ptw_resp_s1_entry_n, io_ptw_resp_s1_entry_level,
                 ptw_napot_low, io_ptw_resp_s2_entry_tag, ptw_gvpn_isNonLeaf, 1'b0, need_gpa_vpn);

  // ===========================================================================
  // s0 PTW 旁路命中 + 旁路结果（按 io_req_vaddr 的 s0 视角，组合，逐端口）
  //   下一拍寄存进 p_hit / p_ppn / p_gvpn ...（GatedValidRegNext）。
  // ===========================================================================
  logic [WIDTH-1:0]             p_hit_s0;
  logic [WIDTH-1:0][PPN_W-1:0]  p_ppn_s0;
  logic [WIDTH-1:0][GVPN_W-1:0] p_gvpn_s0;
  for (gi = 0; gi < WIDTH; gi++) begin : g_s0_bypass
    wire [VADDR_W-1:0] v = io_req_vaddr[gi];
    wire [1:0] s2x = req_in_s2xlate[gi];
    // s0 命中匹配（对应 golden readResult_resp_hit_*）
    wire hit_s0 = (|io_ptw_resp_s2xlate)
        ? ((io_ptw_resp_s2xlate==ONLY_STAGE2)
             ? ( s2_entry_hit(io_ptw_resp_s2_entry_tag, io_ptw_resp_s2_entry_n,
                              io_ptw_resp_s2_entry_level, v)
                 & ({2'h0,io_ptw_resp_s2_entry_vmid}==io_csrd_hgatp_vmid) )
             : ( all_hit_full(io_ptw_resp_s1_entry_tag, io_ptw_resp_s1_entry_n,
                              io_ptw_resp_s1_entry_level, io_ptw_resp_s1_addr_low,
                              io_ptw_resp_s2_entry_n, io_ptw_resp_s2_entry_level,
                              io_ptw_resp_s2xlate==ONLY_STAGE1, v)
                 & ({2'h0,io_ptw_resp_s1_entry_vmid}==io_csrd_hgatp_vmid)
                 & (io_ptw_resp_s1_entry_asid==io_csrd_vsatp_asid | io_ptw_resp_s1_entry_perm_g) ))
        : ( s1_entry_hit(io_ptw_resp_s1_entry_tag, io_ptw_resp_s1_entry_n,
                         io_ptw_resp_s1_entry_level, v, io_ptw_resp_s1_valididx)
            & (io_ptw_resp_s1_entry_asid==io_csrd_satp_asid | io_ptw_resp_s1_entry_perm_g) );
    assign p_hit_s0[gi] = hit_s0 & io_ptw_resp_valid & (s2x == io_ptw_resp_s2xlate);

    // s0 旁路 ppn：两阶段取 s2 合成，否则 s1 合成
    wire [GVPN_W-1:0] s1ppn = gen_s1_ppn44(io_ptw_resp_s1_entry_ppn, io_ptw_resp_s1_entry_n,
                                     io_ptw_resp_s1_entry_level, ptw_napot_low, v[VADDR_W-1:12]);
    // s0 gvpn27（用于 p_ppn 的 s2 合成，对应 golden readResult_gvpn）
    wire [26:0] gvpn27 = (s2x==ONLY_STAGE2) ? v[38:12] : s1ppn[26:0];
    wire [37:0] s2ppn = gen_s2_ppn38(io_ptw_resp_s2_entry_ppn, io_ptw_resp_s2_entry_n,
                                     io_ptw_resp_s2_entry_level, gvpn27);
    assign p_ppn_s0[gi]  = (s2x==ONLY_STAGE2 | (&s2x)) ? s2ppn[PPN_W-1:0] : s1ppn[PPN_W-1:0];
    assign p_gvpn_s0[gi] = gen_gvpn(io_ptw_resp_s1_entry_ppn, io_ptw_resp_s1_entry_n,
                                    io_ptw_resp_s1_entry_level, ptw_napot_low,
                                    io_ptw_resp_s2_entry_tag, ptw_gvpn_isNonLeaf,
                                    s2x==ONLY_STAGE2, v[VADDR_W-1:12]);
  end

  // ===========================================================================
  // 时序：req_out 寄存（无复位，req.valid 使能）+ 异常预检寄存 + redirect 寄存
  // ===========================================================================
  always_ff @(posedge clock) begin
    for (int i = 0; i < WIDTH; i++) begin
      if (io_req_valid[i]) begin
        req_out_vaddr[i]        <= io_req_vaddr[i];
        req_out_fullva[i]       <= EffectiveVa[i];
        req_out_cmd[i]          <= io_req_cmd[i];
        req_out_hyperinst[i]    <= io_req_hyperinst[i];
        req_out_hlvx[i]         <= io_req_hlvx[i];
        req_out_isPrefetch[i]   <= io_req_isPrefetch[i];
        req_out_robIdx_flag[i]  <= io_req_robIdx_flag[i];
        req_out_robIdx_value[i] <= io_req_robIdx_value[i];
        virt_out[i]             <= io_csrd_priv_virt;
        porttr_r[i]             <= ~io_req_no_translate[i];
        resp_fullva_r[i]        <= EffectiveVa[i];
      end
      // 预检异常寄存 + noTranslate 寄存（每拍）
      REG_pre[i]         <= prepf[i] | pregpf[i] | preaf[i];
      excp_pf_ld_REG[i]  <= prepf[i];
      excp_pf_st_REG[i]  <= prepf[i];
      excp_gpf_ld_REG[i] <= pregpf[i];
      excp_gpf_st_REG[i] <= pregpf[i];
      excp_af_ld_REG[i]  <= preaf[i];
      excp_af_st_REG[i]  <= preaf[i];
      noTransReg[i]      <= io_req_no_translate[i];
    end
    // redirect 寄存（lastCycleRedirect）
    lcr_valid        <= io_redirect_valid;
    lcr_robIdx_flag  <= io_redirect_robIdx_flag;
    lcr_robIdx_value <= io_redirect_robIdx_value;
    lcr_level        <= io_redirect_level;
  end

  // ===========================================================================
  // 时序：req_out_v + need_gpa 状态机 + ptw 旁路寄存（带复位）
  // ===========================================================================
  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      req_out_v <= '0;
      need_gpa <= 1'b0;
      resp_gpa_refill <= 1'b0;
      resp_s1_level <= 2'h0;
      resp_s1_isLeaf <= 1'b0;
      resp_s1_isFakePte <= 1'b0;
      p_hit <= '0;
      ptw_already_back_last <= '0;
      req_last <= '0;
    end else begin
      for (int i = 0; i < WIDTH; i++) begin
        req_out_v[i] <= io_req_valid[i] & ~io_req_kill[i];
        req_last[i]  <= io_req_valid[i];
        ptw_already_back_last[i] <= io_ptw_resp_valid;
      end

      // —— need_gpa 更新（对应 golden need_gpa <= ... 的优先级链）——
      // 进入：rr_T_enter[i] 置；离开：被 redirect flush 或 resp_gpa_refill 命中清。
      // 复刻 golden 的嵌套优先级（端口 3 最高）。
      need_gpa <=
        ~( (req_out_v[3]&hasGpf[3]&resp_gpa_refill&(need_gpa_vpn==req_out_vaddr[3][VADDR_W-1:12]))
           | rr_T_redirect[3] )
        & ( rr_T_enter[3]
          | ~( (req_out_v[2]&hasGpf[2]&resp_gpa_refill&(need_gpa_vpn==req_out_vaddr[2][VADDR_W-1:12]))
               | rr_T_redirect[2] )
            & ( rr_T_enter[2]
              | ~( (req_out_v[1]&hasGpf[1]&resp_gpa_refill&(need_gpa_vpn==req_out_vaddr[1][VADDR_W-1:12]))
                   | rr_T_redirect[1] )
                & ( rr_T_enter[1]
                  | ~( (req_out_v[0]&hasGpf[0]&resp_gpa_refill&(need_gpa_vpn==req_out_vaddr[0][VADDR_W-1:12]))
                       | rr_T_redirect[0] )
                    & ( rr_T_enter[0] | need_gpa ) ) ) );

      // need_gpa_vpn / robidx：端口 3>2>1>0，redirect 清 0、enter 写本端口 vpn
      if (rr_T_redirect[3])      need_gpa_vpn <= '0;
      else if (rr_T_enter[3])    need_gpa_vpn <= req_out_vaddr[3][VADDR_W-1:12];
      else if (rr_T_redirect[2]) need_gpa_vpn <= '0;
      else if (rr_T_enter[2])    need_gpa_vpn <= req_out_vaddr[2][VADDR_W-1:12];
      else if (rr_T_redirect[1]) need_gpa_vpn <= '0;
      else if (rr_T_enter[1])    need_gpa_vpn <= req_out_vaddr[1][VADDR_W-1:12];
      else if (rr_T_redirect[0]) need_gpa_vpn <= '0;
      else if (rr_T_enter[0])    need_gpa_vpn <= req_out_vaddr[0][VADDR_W-1:12];

      if (rr_T_redirect[3] | ~rr_T_enter[3]) begin
        if (rr_T_redirect[2] | ~rr_T_enter[2]) begin
          if (rr_T_redirect[1] | ~rr_T_enter[1]) begin
            if (rr_T_redirect[0] | ~rr_T_enter[0]) begin end
            else begin need_gpa_robidx_flag <= req_out_robIdx_flag[0];
                       need_gpa_robidx_value <= req_out_robIdx_value[0]; end
          end else begin need_gpa_robidx_flag <= req_out_robIdx_flag[1];
                         need_gpa_robidx_value <= req_out_robIdx_value[1]; end
        end else begin need_gpa_robidx_flag <= req_out_robIdx_flag[2];
                       need_gpa_robidx_value <= req_out_robIdx_value[2]; end
      end else begin need_gpa_robidx_flag <= req_out_robIdx_flag[3];
                     need_gpa_robidx_value <= req_out_robIdx_value[3]; end

      // —— resp_gpa_refill：PTW 回来命中 need_gpa_vpn 则置（优先级链同上）——
      // 等价 golden 的 redirect/enter 优先级链；这里直接用 rr_ 信号复刻。
      resp_gpa_refill <=
        ~(rr_T_redirect[3] | rr_T_enter[3])
        & ( rr_T_ptwhit[3] | ~(rr_T_redirect[2]|rr_T_enter[2])
          & ( rr_T_ptwhit[2] | ~(rr_T_redirect[1]|rr_T_enter[1])
            & ( rr_T_ptwhit[1] | ~(rr_T_redirect[0]|rr_T_enter[0])
              & ( rr_T_ptwhit[0] | resp_gpa_refill ) ) ) );

      // resp_gpa_gvpn / resp_s1_level / isLeaf / isFakePte：PTW 命中 need_gpa_vpn 时更新。
      // golden 用嵌套优先级取“最后被选中端口”的 PTW 回包；各端口回包相同（同一 io_ptw_resp），
      // 故这里统一在“任一端口 ptwhit 或回包默认更新”时写 PTW 回包值（与 golden 等价）。
      resp_gpa_gvpn     <= resp_gpa_gvpn_next;
      resp_s1_level     <= io_ptw_resp_s1_entry_level;
      resp_s1_isLeaf    <= ptw_isLeaf;
      resp_s1_isFakePte <= ptw_isFakePte;

      // —— PTW 回填旁路寄存 + p_hit（GatedValidRegNext）——
      //   旁路命中/ppn/gvpn 已在 g_s0_bypass 组合算好（p_hit_s0/p_ppn_s0/p_gvpn_s0）。
      for (int i = 0; i < WIDTH; i++) begin
        p_hit[i] <= p_hit_s0[i];
        if (io_ptw_resp_valid) begin
          p_ppn[i]   <= p_ppn_s0[i];
          p_pbmt[i]  <= io_ptw_resp_s1_entry_pbmt;
          p_perm[i]  <= ptw_perm;
          p_gvpn[i]  <= p_gvpn_s0[i];
          p_g_pbmt[i]<= io_ptw_resp_s2_entry_pbmt;
          p_g_perm[i]<= ptw_gperm;
          p_s2xlate[i]<= io_ptw_resp_s2xlate;
          p_s1_level[i]<= io_ptw_resp_s1_entry_level;
          p_s1_isLeaf[i]<= ptw_isLeaf;
          p_s1_isFakePte[i]<= ptw_isFakePte;
          // 整包寄存（ptw_already_back 用）
          pr_s2xlate[i]   <= io_ptw_resp_s2xlate;
          pr_s1_tag[i]    <= io_ptw_resp_s1_entry_tag;
          pr_s1_asid[i]   <= io_ptw_resp_s1_entry_asid;
          pr_s1_vmid[i]   <= io_ptw_resp_s1_entry_vmid;
          pr_s1_n[i]      <= io_ptw_resp_s1_entry_n;
          pr_s1_perm_g[i] <= io_ptw_resp_s1_entry_perm_g;
          pr_s1_level[i]  <= io_ptw_resp_s1_entry_level;
          pr_s1_addr_low[i]<= io_ptw_resp_s1_addr_low;
          pr_s1_valididx[i]<= io_ptw_resp_s1_valididx;
          pr_s2_tag[i]    <= io_ptw_resp_s2_entry_tag;
          pr_s2_vmid[i]   <= io_ptw_resp_s2_entry_vmid;
          pr_s2_n[i]      <= io_ptw_resp_s2_entry_n;
          pr_s2_level[i]  <= io_ptw_resp_s2_entry_level;
        end
      end
    end
  end

endmodule
