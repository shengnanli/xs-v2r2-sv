// =============================================================================
//  TLB.sv —— 前端的指令 TLB（itlb）：2 条非阻塞取指口 + 1 条阻塞口
// -----------------------------------------------------------------------------
//  位置：Frontend 里的 inner_itlb（Chisel: new TLB(itlbPortNum=3, nRespDups=1,
//        Block = Seq(false, false, true), itlbParams)）。
//    · requestor 0/1：ICache 的两条取指通道，**非阻塞** —— 本拍来、下一拍必出结果，miss 了
//      结果里 miss=1，由 ICache 自己重发；TLB 只负责向 PTW 发一次请求。
//    · requestor 2：IFU 的跨页/MMIO 取指，**阻塞** —— 有 ready/valid 握手，miss 了 TLB 自己
//      向 PTW 要，等 PTW 回来再把结果交出去，期间不收新请求。
//  页表项存在子模块 entries（TlbStorageWrapper → 48 项全相联 TLBFA）里；查不到就问 L2TLB(PTW)。
//
//  两拍的流水（与 dtlb 的 xs_TLBNonBlock_core 同一张时序图）：
//    拍 A（请求拍）：vpn 送 entries 做全相联比较；同时和"本拍正好回来的 PTW 响应"比一次
//                    （p_hit_fast，即 ptw_resp_bypass）；把请求打进 req_out_*。
//    拍 B（响应拍）：entries 命中项 / 上一拍旁路下来的 PTW 结果二选一 → 权限检查 → paddr/gpaddr；
//                    miss 了向 PTW 发请求（阻塞口还要挂起等回填）。
//
//  itlb 与 dtlb 的差别（都由 itlbParams / 端口折叠决定，golden 端口表与寄存器表可复核）：
//    · 取指专用：cmd 恒为 exec（golden 无 cmd 端口），只有 instr 方向的 pf/gpf/af；
//      模式取 imode（useDmode=false）；S 模式下 U 页一律不可执行（ifetch 使 SUM 失效）。
//    · 无 hyperinst/hlvx/fullva/checkfullva/no_translate/isPrefetch/robIdx/memidx/req_kill：
//      于是没有前置故障（prepf/pregpf/preaf）那组寄存器，need_gpa 不记 robIdx，
//      canGetGpa 恒真（isitlb），need_replay 恒 0。
//    · need_gpa 状态由 flushPipe 清（isitlb && flush_pipe(i)），而不是 redirect。
//    · 没有 tlbreplay / pmp / ptwBack 端口（父级不接，firtool 删掉了）。
//    · outsideRecvFlush=false：阻塞口在 flushPipe 时直接回一个 pf（让 IFU 自己扔掉这条）。
//
//  ★跨 lane 的 need_gpa 优先级是"下标大的 lane 覆盖下标小的"★（Chisel for 循环里的
//    last-connect），§need_gpa 按同样顺序写。
//
//  文件结构（单文件规范）：itlb_pkg（本模块私有类型）→ xs_TLB_core（可读核）→ TLB（golden 同名 wrapper）。
//  共享包 tlbnb_pkg（rtl/memblock/memblock_common_pkg.sv）：PTW 响应/CSR 结构体与 hit()/genPPN() 等纯函数，
//    与 dtlb 的 xs_TLBNonBlock_core 共用。
//  子模块（wrapper 里例化）：DelayN_9（sfence 延迟 2 拍）/ DelayN_7（CSR 延迟 2 拍）/ TlbStorageWrapper（表项），
//    三者都是本仓已签核的重写件。
//  设计源：src/main/scala/xiangshan/cache/mmu/TLB.scala（class TLB；handle_nonblock / handle_block）
// =============================================================================

// =============================================================================
//  itlb_pkg —— itlb 私有的权限位打包
// -----------------------------------------------------------------------------
//  ★不复用 tlbnb_pkg 的 tlb_perm_t / tlb_gperm_t★：itlb 只取指，不读 d（dirty）也不读 G-stage 的
//  w/r/d，golden 的旁路寄存器里就没有这几位；用 dtlb 的结构体会凭空多出 golden 没有的寄存器。
// =============================================================================
package itlb_pkg;

  localparam int W          = 3;   // 请求口数（itlbPortNum）
  localparam int BLOCK_LANE = 2;   // 唯一的阻塞口

  // VS-stage（s1）权限：TlbPermBundle 在 itlb 里留下的 8 位
  typedef struct packed {
    logic pf;   // stage-1 页故障
    logic af;   // 访问故障
    logic v;    // 表项 valid（0 且无故障 = 伪 PTE）
    logic a;    // accessed
    logic u;    // user
    logic x;
    logic w;
    logic r;
  } itlb_perm_t;

  // G-stage（s2）权限：取指只看 x 与 a
  typedef struct packed {
    logic pf;   // HptwResp.gpf
    logic af;   // HptwResp.gaf
    logic a;
    logic x;
  } itlb_gperm_t;

endpackage

// =============================================================================
//  xs_TLB_core —— 可读核
// -----------------------------------------------------------------------------
//  分节：§CSR 译码  §拍 A：请求拍  §打拍  §拍 B：响应拍（读结果/权限检查）
//        §need_gpa  §handle_nonblock（lane 0/1）  §handle_block（lane 2）
//        §entries 回填  §perf  §difftest
//  端口按 lane 打成数组，wrapper 负责把 golden 的扁平 io_* 名接过来。
//  ★复位域★：只有标了 [RST] 的寄存器带异步复位，其余一律无复位（与 golden 逐个对齐）。
// =============================================================================
module xs_TLB_core
  import tlbnb_pkg::*;
  import itlb_pkg::*;
(
  input  logic clock,
  input  logic reset,

  // ---- 延迟 2 拍后的 sfence 与 CSR 现场（wrapper 里的 DelayN_9 / DelayN_7 给）----
  input  logic       sfence_valid_d,
  input  logic       sfence_flush_pipe_d,     // sfence.vma 要冲流水（svinval 不冲）
  input  tlb_csr_t   csr,
  input  logic [5:0] hart_id,

  // ---- requestor 请求 ----
  input  logic [W-1:0]              req_valid,
  input  logic [W-1:0][VADDR_W-1:0] req_vaddr,
  output logic                      req2_ready,      // 只有阻塞口有 ready
  input  logic [W-1:0]              flush_pipe,      // 前端冲刷：作废本口在途的请求

  // ---- requestor 响应 ----
  output logic                      resp2_valid,     // 只有阻塞口有 valid/ready
  input  logic                      resp2_ready,
  output logic [W-1:0][PADDR_W-1:0] resp_paddr,
  output logic [W-1:0][XLEN-1:0]    resp_gpaddr,
  output logic [W-1:0][1:0]         resp_pbmt,
  output logic [W-1:0]              resp_miss,
  output logic [W-1:0]              resp_is_for_vs_non_leaf_pte,
  output logic [W-1:0]              resp_gpf_instr,
  output logic [W-1:0]              resp_pf_instr,
  output logic [W-1:0]              resp_af_instr,

  // ---- 向 L2TLB(PTW) 要翻译 ----
  input  logic [W-1:0]              ptw_req_ready,
  output logic [W-1:0]              ptw_req_valid,
  output logic [W-1:0][VPN_W-1:0]   ptw_req_vpn,
  output logic [W-1:0][1:0]         ptw_req_s2xlate,
  output logic [W-1:0]              ptw_req_get_gpa,
  input  logic                      ptw_resp_valid,  // resp.ready 恒 1，fire == valid
  input  ptw_resp_t                 ptw_resp,

  // ---- 两个 perf 事件：access / miss（各自打两拍出去）----
  output logic [5:0]                perf_access,
  output logic [5:0]                perf_miss,

  // ---- entries（TlbStorageWrapper）查询/回填接口 ----
  output logic [W-1:0]              stor_r_req_valid,
  output logic [W-1:0][VPN_W-1:0]   stor_r_req_vpn,
  output logic [W-1:0][1:0]         stor_r_req_s2xlate,
  input  logic [W-1:0]              stor_r_hit,
  input  logic [W-1:0][PPN_W-1:0]   stor_r_ppn,
  input  logic [W-1:0][1:0]         stor_r_pbmt,
  input  logic [W-1:0][1:0]         stor_r_g_pbmt,
  input  itlb_perm_t  [W-1:0]       stor_r_perm,
  input  itlb_gperm_t [W-1:0]       stor_r_g_perm,
  input  logic [W-1:0][1:0]         stor_r_s2xlate,
  output logic                      stor_w_valid,

  // ---- difftest：DiffL1TLBEvent 的 339 位 payload，每口一份 ----
  output logic [W-1:0][338:0]       difftest_packed
);

  // ===========================================================================
  // §CSR 译码（全部用延迟后的 csr）
  // ===========================================================================
  wire sv39_en   = csr.satp_mode  == SV39;
  wire sv48_en   = csr.satp_mode  == SV48;
  wire sv39vs_en = csr.vsatp_mode == SV39;
  wire sv48vs_en = csr.vsatp_mode == SV48;
  wire sv39x4_en = csr.hgatp_mode == SV39;
  wire sv48x4_en = csr.hgatp_mode == SV48;
  wire s1_en_any = sv39_en | sv48_en;                        // 本机页表开了
  wire s2_en_any = sv39vs_en | sv48vs_en | sv39x4_en | sv48x4_en;   // 虚拟化时两级任一开了

  // 取指 TLB 用 imode（useDmode=false）；没有 hypervisor 指令，所以不会换成 spvp。
  wire [1:0] mode = csr.priv_imode;

  // s2xlate 四选一：这次翻译要走哪几级。Chisel 是 MuxCase，默认 noS2xlate。
  function automatic logic [1:0] pick_s2xlate(input logic virt,
                                              input logic [3:0] vsatp_mode,
                                              input logic [3:0] hgatp_mode);
    if (!virt)                                return NO_S2XLATE;
    else if ((|vsatp_mode) && (|hgatp_mode))  return ALL_STAGE;
    else if (vsatp_mode == 4'h0)              return ONLY_S2;
    else                                      return {1'b0, hgatp_mode == 4'h0};
  endfunction

  // 本拍回来的 PTW 响应里 hit() 要用的那几项
  hit_key_t ptw_key;
  always_comb begin
    ptw_key.s2xlate     = ptw_resp.s2xlate;
    ptw_key.s1_tag      = ptw_resp.s1.entry_tag;
    ptw_key.s1_asid     = ptw_resp.s1.entry_asid;
    ptw_key.s1_vmid     = ptw_resp.s1.entry_vmid;
    ptw_key.s1_n        = ptw_resp.s1.entry_n;
    ptw_key.s1_level    = ptw_resp.s1.entry_level;
    ptw_key.s1_perm_g   = ptw_resp.s1.entry_perm_g;
    ptw_key.s1_addr_low = ptw_resp.s1.addr_low;
    ptw_key.s1_valididx = ptw_resp.s1.valididx;
    ptw_key.s2_tag      = ptw_resp.s2.entry_tag;
    ptw_key.s2_vmid     = ptw_resp.s2.entry_vmid;
    ptw_key.s2_n        = ptw_resp.s2.entry_n;
    ptw_key.s2_level    = ptw_resp.s2.entry_level;
  end

  wire ptw_s1_is_leaf     = s1_is_leaf(ptw_resp);
  wire ptw_s1_is_fake_pte = s1_is_fake_pte(ptw_resp);
  wire ptw_s1_is_non_leaf = s1_is_non_leaf(ptw_resp);

  // PTW 响应直接转成权限位（ptwresp_to_tlbperm / hptwresp_to_tlbperm）
  itlb_perm_t  ptw_perm;
  itlb_gperm_t ptw_g_perm;
  always_comb begin
    ptw_perm.pf   = ptw_resp.s1.pf;
    ptw_perm.af   = ptw_resp.s1.af;
    ptw_perm.v    = ptw_resp.s1.entry_v;
    ptw_perm.a    = ptw_resp.s1.entry_perm_a;
    ptw_perm.u    = ptw_resp.s1.entry_perm_u;
    ptw_perm.x    = ptw_resp.s1.entry_perm_x;
    ptw_perm.w    = ptw_resp.s1.entry_perm_w;
    ptw_perm.r    = ptw_resp.s1.entry_perm_r;
    ptw_g_perm.pf = ptw_resp.s2.gpf;
    ptw_g_perm.af = ptw_resp.s2.gaf;
    ptw_g_perm.a  = ptw_resp.s2.entry_perm_a;
    ptw_g_perm.x  = ptw_resp.s2.entry_perm_x;
  end

  // ===========================================================================
  // §状态声明
  // ===========================================================================
  // --- 每口：请求现场 ---
  logic [VADDR_W-1:0]   req_out_vaddr   [W];
  logic                 virt_out        [W];
  logic                 req_out_v       [W];   // [RST] 本口有一条在途请求
  logic [VPN_W-1:0]     difftest_vpn_r  [W];
  logic                 difftest_valid_r[W];   // RegNext(req.fire)，difftest 用
  logic                 difftest_s2x_r  [W];   // RegNext(priv.virt)，difftest 用
  logic                 result_ok_last  [W];   // [RST] GatedValidRegNext(req.fire)，perf 用

  // --- 每口：PTW 响应旁路打拍（ptw_resp_bypass 里那一串 RegEnable(…, ptw.resp.fire)）---
  logic                 p_hit_last      [W];   // [RST] 上一拍旁路命中
  logic [PPN_W-1:0]     p_ppn           [W];
  logic [1:0]           p_pbmt          [W];
  itlb_perm_t           p_perm          [W];
  logic [PTE_PPN_W-1:0] p_gvpn          [W];
  logic [1:0]           p_g_pbmt        [W];
  itlb_gperm_t          p_g_perm        [W];
  logic [1:0]           p_s2xlate       [W];
  logic [1:0]           p_s1_level      [W];
  logic                 p_s1_is_leaf    [W];
  logic                 p_s1_is_fake_pte[W];

  // --- 非阻塞口：handle_nonblock 里"上一拍的 PTW 响应"（只有 lane 0/1 有）---
  hit_key_t             ptw_reg         [2];
  logic                 ptw_already_back_last [2];   // [RST]

  // --- 模块级 need_gpa 状态 ---
  logic                 need_gpa;              // [RST]
  logic [8:0]           need_gpa_count;        // [RST] 512 次上限的看门狗
  logic                 need_clear_need_gpa;   // [RST]
  logic [VPN_W-1:0]     need_gpa_vpn;
  logic [1:0]           need_gpa_s2xlate;      // [RST]
  logic [PTE_PPN_W-1:0] resp_gpa_gvpn;
  logic                 resp_gpa_refill;       // [RST]
  logic [1:0]           resp_s1_level;         // [RST]
  logic                 resp_s1_is_leaf;       // [RST]
  logic                 resp_s1_is_fake_pte;   // [RST]

  // ===========================================================================
  // §拍 A：请求拍
  // ===========================================================================
  logic [W-1:0] req_fire;       // 请求真的被收下
  logic [W-1:0] resp_fire;      // 响应真的被取走
  logic [1:0]   req_in_s2xlate [W];
  logic         p_hit_fast     [W];
  logic [PPN_W-1:0]  bypass_ppn_s1 [W];
  logic [VPN_W-1:0]  bypass_gvpn   [W];

  // 非阻塞口 req.ready = resp.ready（恒 1，golden 无端口），所以 fire 就是 valid；
  // 非阻塞口 resp.valid = req_out_v、resp.ready 恒 1，所以 resp.fire 就是 req_out_v。
  // 阻塞口的握手见 §handle_block。
  assign req_fire  = {req_valid[BLOCK_LANE] & req2_ready, req_valid[1:0]};
  assign resp_fire = {resp2_valid & resp2_ready, req_out_v[1], req_out_v[0]};

  for (genvar i = 0; i < W; i++) begin : g_req_phase
    // 取指没有 hyperinst，所以"虚拟化"只看 priv.virt
    assign req_in_s2xlate[i] = pick_s2xlate(csr.priv_virt, csr.vsatp_mode, csr.hgatp_mode);

    // PTW 响应旁路：本拍回来的 PTW 结果正好是这条请求要的页，下一拍直接用它
    assign p_hit_fast[i] = ptw_hit(ptw_key, req_vaddr[i][VADDR_W-1:OFF_W],
                                   csr.satp_asid, csr.vsatp_asid, csr.hgatp_vmid)
                           & ptw_resp_valid
                           & (req_in_s2xlate[i] == ptw_resp.s2xlate);

    // 旁路 ppn：两级翻译时最终物理页号来自 G-stage，否则来自 VS-stage
    assign bypass_ppn_s1[i] = PPN_W'(s1_gen_ppn(ptw_resp, req_vaddr[i][VADDR_W-1:OFF_W]));
    assign bypass_gvpn[i]   = (req_in_s2xlate[i] == ONLY_S2)
                              ? req_vaddr[i][VADDR_W-1:OFF_W]
                              : {{(VPN_W-PPN_W){1'b0}}, bypass_ppn_s1[i]};

    // entries 查询：请求拍发地址（★用 valid 而不是 fire★，golden 如此），响应拍取结果
    assign stor_r_req_valid[i]   = req_valid[i];
    assign stor_r_req_vpn[i]     = req_vaddr[i][VADDR_W-1:OFF_W];
    assign stor_r_req_s2xlate[i] = req_in_s2xlate[i];
  end

  // ===========================================================================
  // §打拍
  // ===========================================================================
  for (genvar i = 0; i < W; i++) begin : g_regs
    // --- 请求现场：req.fire 时存下来，响应拍再用 ---
    always_ff @(posedge clock) begin
      if (req_fire[i]) begin
        req_out_vaddr[i] <= req_vaddr[i];
        virt_out[i]      <= csr.priv_virt;
      end
      // difftest 的 vpn 用的是 RegEnable(…, req.valid)（阻塞口上与 fire 不同）
      if (req_valid[i])
        difftest_vpn_r[i] <= req_vaddr[i][VADDR_W-1:OFF_W];
      difftest_valid_r[i] <= req_fire[i];
      difftest_s2x_r[i]   <= csr.priv_virt;
    end

    // --- 带异步复位的一拍延迟 ---
    always_ff @(posedge clock or posedge reset) begin
      if (reset) begin
        req_out_v[i]      <= 1'b0;
        p_hit_last[i]     <= 1'b0;
        result_ok_last[i] <= 1'b0;
      end else begin
        // ValidHold(req.fire, resp.fire, flush_pipe)：来了置 1、被取走清 0、冲刷清 0（冲刷最优先）
        req_out_v[i]      <= ~flush_pipe[i] & (req_fire[i] | (req_out_v[i] & ~resp_fire[i]));
        p_hit_last[i]     <= p_hit_fast[i];
        result_ok_last[i] <= req_fire[i];
      end
    end

    // --- PTW 响应旁路寄存器 ---
    always_ff @(posedge clock) begin
      if (ptw_resp_valid) begin
        p_ppn[i]            <= ((req_in_s2xlate[i] == ONLY_S2) | (req_in_s2xlate[i] == ALL_STAGE))
                               ? PPN_W'(s2_gen_ppn(ptw_resp, bypass_gvpn[i]))
                               : bypass_ppn_s1[i];
        p_pbmt[i]           <= ptw_resp.s1.entry_pbmt;
        p_perm[i]           <= ptw_perm;
        p_gvpn[i]           <= (req_in_s2xlate[i] == ONLY_S2)
                               ? {{(PTE_PPN_W-GVPN_W){1'b0}}, ptw_resp.s2.entry_tag}
                               : s1_gen_gvpn(ptw_resp, req_vaddr[i][VADDR_W-1:OFF_W]);
        p_g_pbmt[i]         <= ptw_resp.s2.entry_pbmt;
        p_g_perm[i]         <= ptw_g_perm;
        p_s2xlate[i]        <= ptw_resp.s2xlate;
        p_s1_level[i]       <= ptw_resp.s1.entry_level;
        p_s1_is_leaf[i]     <= ptw_s1_is_leaf;
        p_s1_is_fake_pte[i] <= ptw_s1_is_fake_pte;
      end
    end
  end

  // 非阻塞口的"上一拍 PTW 响应"（handle_nonblock 的 ptw_already_back）
  for (genvar i = 0; i < 2; i++) begin : g_nb_regs
    always_ff @(posedge clock) if (ptw_resp_valid) ptw_reg[i] <= ptw_key;
    always_ff @(posedge clock or posedge reset) begin
      if (reset) ptw_already_back_last[i] <= 1'b0;
      else       ptw_already_back_last[i] <= ptw_resp_valid;
    end
  end

  // ===========================================================================
  // §拍 B：响应拍 —— 读结果、物理地址、权限检查
  // ===========================================================================
  logic [1:0]           req_out_s2xlate [W];
  logic                 xlate_en        [W];   // portTranslateEnable：这一拍要不要翻译
  logic                 only_s2         [W];
  logic                 all_stage       [W];
  logic                 hit_read        [W];
  logic                 miss_read       [W];
  logic                 has_gpf         [W];
  logic                 need_gpa_match  [W];
  // 从 entries / PTW 旁路二选一得到的表项内容
  logic [PPN_W-1:0]     sel_ppn         [W];
  logic [1:0]           sel_pbmt        [W];
  logic [1:0]           sel_g_pbmt      [W];
  itlb_perm_t           sel_perm        [W];
  itlb_gperm_t          sel_g_perm      [W];
  logic [1:0]           sel_s2xlate     [W];
  logic                 sel_is_fake_pte [W];
  logic                 sel_is_leaf     [W];
  logic [1:0]           sel_level       [W];
  logic [PTE_PPN_W-1:0] sel_gvpn        [W];
  // 读结果路径（TLBRead + perm_check）的输出；阻塞口还会被 §handle_block 覆盖
  logic [PADDR_W-1:0]   rd_paddr        [W];
  logic [XLEN-1:0]      rd_gpaddr       [W];
  logic [1:0]           rd_pbmt         [W];
  logic                 rd_pf_instr     [W];
  logic                 rd_gpf_instr    [W];
  logic                 rd_af_instr     [W];
  logic                 rd_vs_non_leaf  [W];

  // 取指的权限检查（perm_check 只留 instr 方向）。perm/g_perm 来自读结果或 PTW 响应，
  // s2xlate 决定查哪一级：VS-stage 报 pf，G-stage 报 gpf，访问故障 af 优先于两者。
  function automatic logic [3:0] instr_perm_check(input itlb_perm_t p, input itlb_gperm_t g,
                                                  input logic [1:0] s2x, input logic en,
                                                  input logic [1:0] md);
    logic os2, alls, af, mode_ok, fake, nonleaf, s1v, s2v, pf, gpf;
    os2     = (s2x == ONLY_S2);
    alls    = (s2x == ALL_STAGE);
    af      = (~os2 & p.af) | ((os2 | alls) & g.af);
    // U 模式只能执行 U 页；S 模式取指不能执行 U 页（ifetch 让 SUM 不起作用）
    mode_ok = ~(((md == MODE_U) & ~p.u) | ((md == MODE_S) & p.u));
    // 伪 PTE / 非叶子：PTW 停在中间级，权限位无意义，不报 pf，改报 isForVSnonLeafPTE
    fake    = ~p.v & ~p.pf & ~p.af & ~os2;
    nonleaf = ~(p.r | p.w | p.x) & p.v & ~p.pf & ~p.af;
    s1v     = en & ~os2;
    s2v     = en & (os2 | alls);
    // A 位没置也报页故障，让软件去补
    pf      = (~(mode_ok & p.x) | p.pf | ~p.a) & s1v & ~af & ~fake & ~nonleaf;
    gpf     = (~g.x | g.pf | ~g.a) & s2v & ~af & ~pf;
    return {pf, gpf, af & (s1v | s2v), nonleaf | fake};
  endfunction

  for (genvar i = 0; i < W; i++) begin : g_resp_phase
    assign req_out_s2xlate[i] = pick_s2xlate(virt_out[i], csr.vsatp_mode, csr.hgatp_mode);
    assign only_s2[i]   = req_out_s2xlate[i] == ONLY_S2;
    assign all_stage[i] = req_out_s2xlate[i] == ALL_STAGE;
    // 开了页表 + 特权级低于 M
    assign xlate_en[i]  = ((~virt_out[i] & s1_en_any) | (virt_out[i] & s2_en_any)) & (mode != MODE_M);

    // entries 命中 或 上一拍 PTW 旁路命中
    assign hit_read[i]        = stor_r_hit[i] | p_hit_last[i];
    assign sel_ppn[i]         = p_hit_last[i] ? p_ppn[i]            : stor_r_ppn[i];
    assign sel_pbmt[i]        = p_hit_last[i] ? p_pbmt[i]           : stor_r_pbmt[i];
    assign sel_g_pbmt[i]      = p_hit_last[i] ? p_g_pbmt[i]         : stor_r_g_pbmt[i];
    assign sel_perm[i]        = p_hit_last[i] ? p_perm[i]           : stor_r_perm[i];
    assign sel_g_perm[i]      = p_hit_last[i] ? p_g_perm[i]         : stor_r_g_perm[i];
    assign sel_s2xlate[i]     = p_hit_last[i] ? p_s2xlate[i]        : stor_r_s2xlate[i];
    // 下面四个：旁路没命中时用 need_gpa 拿回来的 gpaddr 素材（模块级）
    assign sel_is_fake_pte[i] = p_hit_last[i] ? p_s1_is_fake_pte[i] : resp_s1_is_fake_pte;
    assign sel_is_leaf[i]     = p_hit_last[i] ? p_s1_is_leaf[i]     : resp_s1_is_leaf;
    assign sel_level[i]       = p_hit_last[i] ? p_s1_level[i]       : resp_s1_level;
    assign sel_gvpn[i]        = p_hit_last[i] ? p_gvpn[i]           : resp_gpa_gvpn;

    assign need_gpa_match[i] = (need_gpa_vpn == req_out_vaddr[i][VADDR_W-1:OFF_W])
                             & (need_gpa_s2xlate == req_out_s2xlate[i]);

    // miss 的两种来源：(1) 要翻译却没命中；(2) 命中了但报 gpf，要专门去要 gpaddr
    assign miss_read[i] = (~hit_read[i] & xlate_en[i])
                        | (has_gpf[i] & ~p_hit_last[i]
                           & ~(resp_gpa_refill & need_gpa_match[i]) & ~only_s2[i]);

    // 物理地址：翻译时 = {ppn, 页内偏移}；不翻译时 = 虚地址低 48 位
    assign rd_paddr[i] = xlate_en[i] ? {sel_ppn[i], req_out_vaddr[i][OFF_W-1:0]}
                                     : req_out_vaddr[i][PADDR_W-1:0];

    // gpaddr：只有 G-stage 时就是虚地址本身（取指不用 fullva）；否则 = {gvpn, 偏移}，
    //   偏移在叶子页取页内偏移，在非叶子/伪 PTE 时取出错那一级的 vpnn（再补 3 位 0）。
    //   ★vpn_idx 的 Mux1H 在 firtool 里是"按位或"★（三条条件互斥）
    logic [1:0] vpn_idx;
    assign vpn_idx = {(sel_is_fake_pte[i] & sv39vs_en), 1'b0}
                   | {2{sel_is_fake_pte[i] & sv48vs_en}}
                   | (sel_is_fake_pte[i] ? 2'h0 : 2'(sel_level[i] - 2'h1));
    wire [OFF_W-1:0] gpaddr_offset =
        sel_is_leaf[i] ? req_out_vaddr[i][OFF_W-1:0]
                       : {get_vpnn(req_out_vaddr[i][VADDR_W-1:OFF_W], vpn_idx), 3'h0};
    assign rd_gpaddr[i] = (sel_s2xlate[i] == ONLY_S2)
                          ? {{(XLEN-VADDR_W){1'b0}}, req_out_vaddr[i]}
                          : {{(XLEN-PTE_PPN_W-OFF_W){1'b0}}, sel_gvpn[i], gpaddr_offset};

    // Svpbmt：两级都开时 VS-stage 的 pbmt 优先，为 0 才看 G-stage 的
    logic [1:0] pbmt_res;
    always_comb begin
      case (req_out_s2xlate[i])
        ONLY_S2:   pbmt_res = sel_g_pbmt[i];
        ALL_STAGE: pbmt_res = (|sel_pbmt[i]) ? sel_pbmt[i] : sel_g_pbmt[i];
        default:   pbmt_res = sel_pbmt[i];
      endcase
    end
    assign rd_pbmt[i] = xlate_en[i] ? pbmt_res : 2'h0;

    assign {rd_pf_instr[i], rd_gpf_instr[i], rd_af_instr[i], rd_vs_non_leaf[i]} =
        instr_perm_check(sel_perm[i], sel_g_perm[i], req_out_s2xlate[i], xlate_en[i], mode);

    // 命中了却报 G-stage 故障 —— 要专门去问 PTW 要 gpaddr（见 §need_gpa）
    assign has_gpf[i] = hit_read[i] & resp_gpf_instr[i];
  end

  // 非阻塞口：读结果就是最终响应
  for (genvar i = 0; i < 2; i++) begin : g_nb_resp
    assign resp_paddr[i]                  = rd_paddr[i];
    assign resp_gpaddr[i]                 = rd_gpaddr[i];
    assign resp_pbmt[i]                   = rd_pbmt[i];
    assign resp_miss[i]                   = miss_read[i];
    assign resp_pf_instr[i]               = rd_pf_instr[i];
    assign resp_gpf_instr[i]              = rd_gpf_instr[i];
    assign resp_af_instr[i]               = rd_af_instr[i];
    assign resp_is_for_vs_non_leaf_pte[i] = rd_vs_non_leaf[i];
  end

  // ===========================================================================
  // §need_gpa —— G-stage 故障时专门向 PTW 要 gpaddr
  //
  //   · 某口命中却报 gpf 时，整个 TLB 进入 need_gpa 状态，记下 vpn / s2xlate；
  //   · 别的口 miss 一律不发新的 PTW 请求（不然回来的响应分不清）；
  //   · PTW 带 getGpa 回来且对得上，就把 gvpn/level/isLeaf/isFakePte 存进 resp_gpa_*、置 refill；
  //   · 出故障那一口被 flushPipe 冲掉、或连续 512 次 getGpa 响应还没收尾，就放弃。
  //   跨 lane：for 循环里对同一批寄存器反复赋值，下标大的 lane 赢（last-connect）。
  // ===========================================================================
  logic [W-1:0]         clear_gpa, want_gpa, second_clear;
  logic [W-1:0]         state_clear_vec, need_clear_vec;
  logic                 need_gpa_wire;          // 本拍有口抢到了 need_gpa
  logic                 ptw_gpa_hit;            // PTW 送回来的正是我等的那一页
  logic                 need_gpa_count_full;
  logic                 nx_need_gpa, nx_resp_gpa_refill;
  logic [VPN_W-1:0]     nx_need_gpa_vpn;
  logic [1:0]           nx_need_gpa_s2xlate;
  logic [PTE_PPN_W-1:0] nx_resp_gpa_gvpn;
  logic [1:0]           nx_resp_s1_level;
  logic                 nx_resp_s1_is_leaf, nx_resp_s1_is_fake_pte;

  assign need_gpa_count_full = &need_gpa_count;
  assign ptw_gpa_hit = ptw_resp_valid & need_gpa
                     & (need_gpa_s2xlate == ptw_resp.s2xlate)
                     & (need_gpa_vpn == ptw_get_vpn(ptw_resp, need_gpa_vpn));

  for (genvar i = 0; i < W; i++) begin : g_gpa_cond
    // 取指口（isitlb）的放弃条件是 flushPipe，不看 redirect
    assign clear_gpa[i]    = flush_pipe[i] | need_clear_need_gpa | need_gpa_count_full;
    // 取指口 canGetGpa 恒真（isExec），所以只要满足条件就进入 need_gpa，从不 replay
    assign want_gpa[i]     = req_out_v[i] & ~p_hit_last[i]
                           & ~(resp_gpa_refill & need_gpa_match[i]) & ~only_s2[i]
                           & has_gpf[i] & ~need_gpa;
    assign second_clear[i] = req_out_v[i] & has_gpf[i] & resp_gpa_refill & need_gpa_match[i];
  end

  always_comb begin
    nx_need_gpa            = need_gpa;
    nx_need_gpa_vpn        = need_gpa_vpn;
    nx_need_gpa_s2xlate    = need_gpa_s2xlate;
    nx_resp_gpa_refill     = resp_gpa_refill;
    nx_resp_gpa_gvpn       = resp_gpa_gvpn;
    nx_resp_s1_level       = resp_s1_level;
    nx_resp_s1_is_leaf     = resp_s1_is_leaf;
    nx_resp_s1_is_fake_pte = resp_s1_is_fake_pte;
    need_gpa_wire          = 1'b0;
    state_clear_vec        = '0;
    need_clear_vec         = '0;
    for (int i = 0; i < W; i++) begin
      if (clear_gpa[i]) begin
        nx_need_gpa        = 1'b0;
        state_clear_vec[i] = 1'b1;
        nx_resp_gpa_refill = 1'b0;
        nx_need_gpa_vpn    = '0;
      end else if (want_gpa[i]) begin
        need_gpa_wire       = 1'b1;
        nx_need_gpa         = 1'b1;
        nx_need_gpa_vpn     = req_out_vaddr[i][VADDR_W-1:OFF_W];
        nx_need_gpa_s2xlate = req_out_s2xlate[i];
        nx_resp_gpa_refill  = 1'b0;
        // 本拍 PTW 旁路就命中了，下一拍立刻收尾
        if (p_hit_fast[i]) need_clear_vec[i] = 1'b1;
      end else if (ptw_gpa_hit) begin
        nx_resp_gpa_gvpn       = (ptw_resp.s2xlate == ONLY_S2)
                                 ? {{(PTE_PPN_W-GVPN_W){1'b0}}, ptw_resp.s2.entry_tag}
                                 : s1_gen_gvpn(ptw_resp, need_gpa_vpn);
        nx_resp_s1_level       = ptw_resp.s1.entry_level;
        nx_resp_s1_is_leaf     = ptw_s1_is_leaf;
        nx_resp_s1_is_fake_pte = ptw_s1_is_fake_pte;
        nx_resp_gpa_refill     = 1'b1;
      end
      // 独立的一条：gpaddr 已经拿到并对上了，退出 need_gpa
      if (second_clear[i]) begin
        nx_need_gpa        = 1'b0;
        state_clear_vec[i] = 1'b1;
      end
    end
  end

  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      need_gpa            <= 1'b0;
      need_gpa_count      <= 9'h0;
      need_clear_need_gpa <= 1'b0;
      need_gpa_s2xlate    <= 2'h0;
      resp_gpa_refill     <= 1'b0;
      resp_s1_level       <= 2'h0;
      resp_s1_is_leaf     <= 1'b0;
      resp_s1_is_fake_pte <= 1'b0;
    end else begin
      need_gpa            <= nx_need_gpa;
      need_clear_need_gpa <= |need_clear_vec;
      need_gpa_s2xlate    <= nx_need_gpa_s2xlate;
      resp_gpa_refill     <= nx_resp_gpa_refill;
      resp_s1_level       <= nx_resp_s1_level;
      resp_s1_is_leaf     <= nx_resp_s1_is_leaf;
      resp_s1_is_fake_pte <= nx_resp_s1_is_fake_pte;
      // 看门狗：连着 512 次 getGpa 响应还没收尾就强制退出
      if (need_gpa_wire | (|state_clear_vec) | need_gpa_count_full)
        need_gpa_count <= 9'h0;
      else if (need_gpa & ptw_resp_valid & ptw_resp.get_gpa)
        need_gpa_count <= need_gpa_count + 9'h1;
    end
  end
  always_ff @(posedge clock) begin
    need_gpa_vpn  <= nx_need_gpa_vpn;
    resp_gpa_gvpn <= nx_resp_gpa_gvpn;
  end

  // ===========================================================================
  // §handle_nonblock（lane 0/1）：miss 了就向 PTW 发请求，除非
  //   PTW 本拍/上一拍刚好送回了这一页（再查一次就命中），或别人占着 need_gpa。
  // ===========================================================================
  logic ptw_just_back    [2];
  logic ptw_already_back [2];
  for (genvar i = 0; i < 2; i++) begin : g_nonblock
    assign ptw_just_back[i]    = ptw_resp_valid
                               & (req_out_s2xlate[i] == ptw_resp.s2xlate)
                               & ptw_hit(ptw_key, req_out_vaddr[i][VADDR_W-1:OFF_W],
                                         csr.satp_asid, csr.vsatp_asid, csr.hgatp_vmid);
    assign ptw_already_back[i] = ptw_already_back_last[i]
                               & (req_out_s2xlate[i] == ptw_reg[i].s2xlate)
                               & ptw_hit(ptw_reg[i], req_out_vaddr[i][VADDR_W-1:OFF_W],
                                         csr.satp_asid, csr.vsatp_asid, csr.hgatp_vmid);
    assign ptw_req_valid[i]   = req_out_v[i] & miss_read[i]
                              & ~(ptw_just_back[i] | ptw_already_back[i])
                              & ~(need_gpa & ~need_gpa_match[i] & ~resp_gpa_refill);
    assign ptw_req_vpn[i]     = req_out_vaddr[i][VADDR_W-1:OFF_W];
    assign ptw_req_s2xlate[i] = req_out_s2xlate[i];
    assign ptw_req_get_gpa[i] = has_gpf[i] & hit_read[i];
  end

  // ===========================================================================
  // §handle_block（lane 2）：miss 了自己挂起，等 PTW 回来再交结果
  //
  //   req.ready = 口上没有在途请求，或在途那条本拍正被取走。
  //   miss_v     = "这条请求 miss 了、还没交出去"（ValidHoldBypass：置位当拍就可见）；
  //   miss_req_v = "还要向 PTW 发请求"：PTW 收下请求 / 结果被取走时清；
  //                MMU 被刷（sfence/satp 变化，但不是要冲流水的 sfence）时重新置位 —— 刷掉的
  //                可能正是在路上的那次查询，要重发。
  //   PTW 回来且正是这一页（block_ptw_hit）：本拍直接用 PTW 响应拼结果交出去，不等写进 entries。
  //   flushPipe 时（outsideRecvFlush=false）：直接回一个 pf，让 IFU 把这条扔掉。
  // ===========================================================================
  logic       new_coming_last_REG;     // [RST] 上一拍收下了一条新请求（且没被冲）
  logic       miss_v_valid;            // [RST]
  logic       miss_req_v_valid;        // [RST]
  logic [1:0] miss_req_s2xlate_reg;    // 发 PTW 请求时的 s2xlate，用来核对回来的响应
  logic       assert_resp_ready_ok;    // [RST] 断言专用：RegNext(!resp.valid || resp.ready, true)
  logic       assert_miss_has_req;     // [RST] 断言专用：RegNext(req_out_v || !(miss_v || miss_req_v), true)

  localparam int B = BLOCK_LANE;
  wire flush_mmu      = sfence_valid_d | csr.satp_changed | csr.vsatp_changed
                      | csr.hgatp_changed | csr.priv_virt_changed;
  wire mmu_flush_pipe = sfence_valid_d & sfence_flush_pipe_d;

  wire miss_wire    = new_coming_last_REG & miss_read[B];
  wire miss_v       = miss_v_valid | miss_wire;
  wire miss_req_in  = miss_wire | (miss_v & flush_mmu & ~mmu_flush_pipe);
  wire miss_req_v   = miss_req_v_valid | miss_req_in;
  wire ptw_req2_fire = ptw_req_ready[B] & miss_req_v;

  // PTW 回来正是这条挂起的请求要的页
  wire block_ptw_hit = ptw_resp_valid
                     & ptw_hit(ptw_key, req_out_vaddr[B][VADDR_W-1:OFF_W],
                               csr.satp_asid, csr.vsatp_asid, csr.hgatp_vmid)
                     & (miss_req_s2xlate_reg == ptw_resp.s2xlate)
                     & req_out_v[B] & xlate_en[B];
  // flushPipe 时的"假 pf"（golden 名 io_requestor_2_resp_bits_excp_0_pf_st）
  wire flush_pf = req_out_v[B] & flush_pipe[B] & xlate_en[B];

  assign req2_ready = ~req_out_v[B] | resp_fire[B];

  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      new_coming_last_REG  <= 1'b0;
      miss_v_valid         <= 1'b0;
      miss_req_v_valid     <= 1'b0;
      assert_resp_ready_ok <= 1'b1;
      assert_miss_has_req  <= 1'b1;
    end else begin
      new_coming_last_REG  <= req_fire[B] & ~flush_pipe[B];
      // ValidHoldBypass：置位后被"取走/冲刷"清 0（取走优先于新置位）
      miss_v_valid         <= ~(flush_pipe[B] | resp_fire[B]) & (miss_wire | miss_v_valid);
      miss_req_v_valid     <= ~(flush_pipe[B] | ptw_req2_fire | resp_fire[B])
                              & (miss_req_in | miss_req_v_valid);
      assert_resp_ready_ok <= ~resp2_valid | resp2_ready;
      assert_miss_has_req  <= req_out_v[B] | ~(miss_v | miss_req_v);
    end
  end
  always_ff @(posedge clock) begin
    if (ptw_req2_fire) miss_req_s2xlate_reg <= req_out_s2xlate[B];
  end

  // ---- PTW 直出路径：用本拍的 PTW 响应现算 paddr / gpaddr / pbmt / 权限 ----
  wire [1:0]         pr_s2x     = ptw_resp.s2xlate;
  wire [VPN_W-1:0]   b_vpn      = req_out_vaddr[B][VADDR_W-1:OFF_W];
  wire [PPN_W-1:0]   pr_s1_ppn  = PPN_W'(s1_gen_ppn(ptw_resp, b_vpn));
  wire [VPN_W-1:0]   pr_s2_gvpn = (pr_s2x == ONLY_S2) ? b_vpn : {{(VPN_W-PPN_W){1'b0}}, pr_s1_ppn};
  wire [PPN_W-1:0]   pr_s2_ppn  = PPN_W'(s2_gen_ppn(ptw_resp, pr_s2_gvpn));
  wire [PADDR_W-1:0] pr_paddr   = {((pr_s2x == ONLY_S2) | (pr_s2x == ALL_STAGE)) ? pr_s2_ppn : pr_s1_ppn,
                                   req_out_vaddr[B][OFF_W-1:0]};
  wire [1:0]         pr_vpn_idx = {(ptw_s1_is_fake_pte & sv39vs_en), 1'b0}
                                | {2{ptw_s1_is_fake_pte & sv48vs_en}}
                                | (ptw_s1_is_fake_pte ? 2'h0 : 2'(ptw_resp.s1.entry_level - 2'h1));
  wire [OFF_W-1:0]   pr_gpa_off = ptw_s1_is_leaf ? req_out_vaddr[B][OFF_W-1:0]
                                                 : {get_vpnn(b_vpn, pr_vpn_idx), 3'h0};
  wire [XLEN-1:0]    pr_gpaddr  = (pr_s2x == ONLY_S2)
                                  ? {{(XLEN-VADDR_W){1'b0}}, req_out_vaddr[B]}
                                  : {{(XLEN-PTE_PPN_W-OFF_W){1'b0}}, s1_gen_gvpn(ptw_resp, b_vpn), pr_gpa_off};
  logic [1:0] pr_pbmt;
  always_comb begin
    case (pr_s2x)
      ONLY_S2:   pr_pbmt = ptw_resp.s2.entry_pbmt;
      ALL_STAGE: pr_pbmt = (|ptw_resp.s1.entry_pbmt) ? ptw_resp.s1.entry_pbmt : ptw_resp.s2.entry_pbmt;
      default:   pr_pbmt = ptw_resp.s1.entry_pbmt;
    endcase
  end
  logic pr_pf, pr_gpf, pr_af, pr_vs_non_leaf;
  assign {pr_pf, pr_gpf, pr_af, pr_vs_non_leaf} =
      instr_perm_check(ptw_perm, ptw_g_perm, pr_s2x, xlate_en[B], mode);

  // ---- 阻塞口的最终响应 ----
  assign resp2_valid = flush_pf | block_ptw_hit | (req_out_v[B] & ~(miss_v & xlate_en[B]));
  assign resp_paddr[B]  = block_ptw_hit ? pr_paddr  : rd_paddr[B];
  assign resp_gpaddr[B] = block_ptw_hit ? pr_gpaddr : rd_gpaddr[B];
  assign resp_pbmt[B]   = (flush_pf | ~xlate_en[B]) ? 2'h0
                        : (block_ptw_hit ? pr_pbmt : rd_pbmt[B]);
  assign resp_miss[B]   = ~block_ptw_hit & miss_read[B];
  assign resp_pf_instr[B]  = flush_pf | (block_ptw_hit ? pr_pf  : rd_pf_instr[B]);
  assign resp_gpf_instr[B] = block_ptw_hit ? pr_gpf : rd_gpf_instr[B];
  assign resp_af_instr[B]  = block_ptw_hit ? pr_af  : rd_af_instr[B];
  assign resp_is_for_vs_non_leaf_pte[B] = block_ptw_hit ? pr_vs_non_leaf : rd_vs_non_leaf[B];

  assign ptw_req_valid[B]   = miss_req_v;
  assign ptw_req_vpn[B]     = b_vpn;
  assign ptw_req_s2xlate[B] = req_out_s2xlate[B];
  assign ptw_req_get_gpa[B] = has_gpf[B] & hit_read[B];

  // ===========================================================================
  // §entries 回填：PTW 响应写进全相联表
  // 三种情况不写：这次是专门要 gpaddr 的、TLB 正处在 need_gpa 状态、MMU 正在被刷。
  // ===========================================================================
  assign stor_w_valid = ptw_resp_valid & ~ptw_resp.get_gpa & ~need_gpa & ~need_gpa_wire & ~flush_mmu;

  // ===========================================================================
  // §perf：access / miss 两个计数，各自打两拍出去
  //   非阻塞口：access = 上一拍收了请求且要翻译；miss = 向 PTW 发了请求。
  //   阻塞口  ：access = 本拍收下请求；miss = 上一拍收了请求、要翻译且 miss。
  // ===========================================================================
  logic [1:0] perf_acc_r, perf_acc_r2, perf_miss_r, perf_miss_r2;
  wire [W-1:0] perf_acc_vec  = {req_fire[B],
                                xlate_en[1] & result_ok_last[1],
                                xlate_en[0] & result_ok_last[0]};
  wire [W-1:0] perf_miss_vec = {xlate_en[B] & result_ok_last[B] & miss_read[B],
                                ptw_req_ready[1] & ptw_req_valid[1],
                                ptw_req_ready[0] & ptw_req_valid[0]};
  always_ff @(posedge clock) begin
    perf_acc_r   <= 2'($countones(perf_acc_vec));
    perf_acc_r2  <= perf_acc_r;
    perf_miss_r  <= 2'($countones(perf_miss_vec));
    perf_miss_r2 <= perf_miss_r;
  end
  assign perf_access = {4'h0, perf_acc_r2};
  assign perf_miss   = {4'h0, perf_miss_r2};

  // ===========================================================================
  // §difftest：每口一个 DiffL1TLBEvent，payload 打成 339 位从 bore 端口出去
  //   上报条件 = 这一拍真的交出了一次成功的翻译（被取走、没 miss、没故障、开了翻译）。
  //   itlb 的 index 是 0..2（全局计数器：itlb 先分配）。
  // ===========================================================================
  for (genvar i = 0; i < W; i++) begin : g_difftest
    wire dt_pf    = resp_pf_instr[i] | ((i == B) ? flush_pf : 1'b0);   // 阻塞口的 pf.ld/st 来自 flush_pf
    wire dt_valid = difftest_valid_r[i] & resp_fire[i] & ~resp_miss[i]
                  & ~dt_pf & ~resp_af_instr[i] & ~resp_gpf_instr[i] & xlate_en[i];
    assign difftest_packed[i] = {
        dt_valid,
        {csr.satp_mode,  csr.satp_asid,  csr.satp_ppn},                  // satp  64
        {{(XLEN-VPN_W){1'b0}}, difftest_vpn_r[i]},                       // vpn   64
        {{(XLEN-PPN_W){1'b0}}, resp_paddr[i][PADDR_W-1:OFF_W]},          // ppn   64
        {csr.vsatp_mode, csr.vsatp_asid, csr.vsatp_ppn},                 // vsatp 64
        {csr.hgatp_mode, csr.hgatp_vmid, csr.hgatp_ppn},                 // hgatp 64
        pick_s2xlate(difftest_s2x_r[i], csr.vsatp_mode, csr.hgatp_mode), // s2xlate 2
        {2'h0, hart_id},                                                 // coreid  8
        8'(i)                                                            // index   8
    };
  end

endmodule

// =============================================================================
//  TLB —— golden 同名 wrapper：端口逐位同名同序；例化两个延迟件与表项、把扁平 io_* 接到核上
// =============================================================================
module TLB
  import tlbnb_pkg::*;
  import itlb_pkg::*;
(
  // BEGIN GENERATED(tlb_ports) —— scripts/gen_mmuleaf.py
  input          clock,
  input          reset,
  input          io_sfence_valid,
  input          io_sfence_bits_rs1,
  input          io_sfence_bits_rs2,
  input  [49:0]  io_sfence_bits_addr,
  input  [15:0]  io_sfence_bits_id,
  input          io_sfence_bits_flushPipe,
  input          io_sfence_bits_hv,
  input          io_sfence_bits_hg,
  input  [3:0]   io_csr_satp_mode,
  input  [15:0]  io_csr_satp_asid,
  input  [43:0]  io_csr_satp_ppn,
  input          io_csr_satp_changed,
  input  [3:0]   io_csr_vsatp_mode,
  input  [15:0]  io_csr_vsatp_asid,
  input  [43:0]  io_csr_vsatp_ppn,
  input          io_csr_vsatp_changed,
  input  [3:0]   io_csr_hgatp_mode,
  input  [15:0]  io_csr_hgatp_vmid,
  input  [43:0]  io_csr_hgatp_ppn,
  input          io_csr_hgatp_changed,
  input          io_csr_mbmc_BME,
  input          io_csr_mbmc_CMODE,
  input          io_csr_priv_mxr,
  input          io_csr_priv_sum,
  input          io_csr_priv_vmxr,
  input          io_csr_priv_vsum,
  input          io_csr_priv_virt,
  input          io_csr_priv_virt_changed,
  input          io_csr_priv_spvp,
  input  [1:0]   io_csr_priv_imode,
  input  [1:0]   io_csr_priv_dmode,
  input          io_csr_priv_debug,
  input  [1:0]   io_csr_pmm_mseccfg,
  input  [1:0]   io_csr_pmm_menvcfg,
  input  [1:0]   io_csr_pmm_henvcfg,
  input  [1:0]   io_csr_pmm_hstatus,
  input  [1:0]   io_csr_pmm_senvcfg,
  input  [5:0]   io_hartId,
  input          io_requestor_0_req_valid,
  input  [49:0]  io_requestor_0_req_bits_vaddr,
  output [47:0]  io_requestor_0_resp_bits_paddr_0,
  output [63:0]  io_requestor_0_resp_bits_gpaddr_0,
  output [1:0]   io_requestor_0_resp_bits_pbmt_0,
  output         io_requestor_0_resp_bits_miss,
  output         io_requestor_0_resp_bits_isForVSnonLeafPTE,
  output         io_requestor_0_resp_bits_excp_0_gpf_instr,
  output         io_requestor_0_resp_bits_excp_0_pf_instr,
  output         io_requestor_0_resp_bits_excp_0_af_instr,
  input          io_requestor_1_req_valid,
  input  [49:0]  io_requestor_1_req_bits_vaddr,
  output [47:0]  io_requestor_1_resp_bits_paddr_0,
  output [63:0]  io_requestor_1_resp_bits_gpaddr_0,
  output [1:0]   io_requestor_1_resp_bits_pbmt_0,
  output         io_requestor_1_resp_bits_miss,
  output         io_requestor_1_resp_bits_isForVSnonLeafPTE,
  output         io_requestor_1_resp_bits_excp_0_gpf_instr,
  output         io_requestor_1_resp_bits_excp_0_pf_instr,
  output         io_requestor_1_resp_bits_excp_0_af_instr,
  output         io_requestor_2_req_ready,
  input          io_requestor_2_req_valid,
  input  [49:0]  io_requestor_2_req_bits_vaddr,
  input          io_requestor_2_resp_ready,
  output         io_requestor_2_resp_valid,
  output [47:0]  io_requestor_2_resp_bits_paddr_0,
  output [63:0]  io_requestor_2_resp_bits_gpaddr_0,
  output [1:0]   io_requestor_2_resp_bits_pbmt_0,
  output         io_requestor_2_resp_bits_miss,
  output         io_requestor_2_resp_bits_isForVSnonLeafPTE,
  output         io_requestor_2_resp_bits_excp_0_gpf_instr,
  output         io_requestor_2_resp_bits_excp_0_pf_instr,
  output         io_requestor_2_resp_bits_excp_0_af_instr,
  input          io_flushPipe_0,
  input          io_flushPipe_1,
  input          io_flushPipe_2,
  input          io_ptw_req_0_ready,
  output         io_ptw_req_0_valid,
  output [37:0]  io_ptw_req_0_bits_vpn,
  output [1:0]   io_ptw_req_0_bits_s2xlate,
  output         io_ptw_req_0_bits_getGpa,
  input          io_ptw_req_1_ready,
  output         io_ptw_req_1_valid,
  output [37:0]  io_ptw_req_1_bits_vpn,
  output [1:0]   io_ptw_req_1_bits_s2xlate,
  output         io_ptw_req_1_bits_getGpa,
  input          io_ptw_req_2_ready,
  output         io_ptw_req_2_valid,
  output [37:0]  io_ptw_req_2_bits_vpn,
  output [1:0]   io_ptw_req_2_bits_s2xlate,
  output         io_ptw_req_2_bits_getGpa,
  input          io_ptw_resp_valid,
  input  [1:0]   io_ptw_resp_bits_s2xlate,
  input  [34:0]  io_ptw_resp_bits_s1_entry_tag,
  input  [15:0]  io_ptw_resp_bits_s1_entry_asid,
  input  [13:0]  io_ptw_resp_bits_s1_entry_vmid,
  input          io_ptw_resp_bits_s1_entry_n,
  input  [1:0]   io_ptw_resp_bits_s1_entry_pbmt,
  input          io_ptw_resp_bits_s1_entry_perm_d,
  input          io_ptw_resp_bits_s1_entry_perm_a,
  input          io_ptw_resp_bits_s1_entry_perm_g,
  input          io_ptw_resp_bits_s1_entry_perm_u,
  input          io_ptw_resp_bits_s1_entry_perm_x,
  input          io_ptw_resp_bits_s1_entry_perm_w,
  input          io_ptw_resp_bits_s1_entry_perm_r,
  input  [1:0]   io_ptw_resp_bits_s1_entry_level,
  input          io_ptw_resp_bits_s1_entry_v,
  input  [40:0]  io_ptw_resp_bits_s1_entry_ppn,
  input  [2:0]   io_ptw_resp_bits_s1_addr_low,
  input  [2:0]   io_ptw_resp_bits_s1_ppn_low_0,
  input  [2:0]   io_ptw_resp_bits_s1_ppn_low_1,
  input  [2:0]   io_ptw_resp_bits_s1_ppn_low_2,
  input  [2:0]   io_ptw_resp_bits_s1_ppn_low_3,
  input  [2:0]   io_ptw_resp_bits_s1_ppn_low_4,
  input  [2:0]   io_ptw_resp_bits_s1_ppn_low_5,
  input  [2:0]   io_ptw_resp_bits_s1_ppn_low_6,
  input  [2:0]   io_ptw_resp_bits_s1_ppn_low_7,
  input          io_ptw_resp_bits_s1_valididx_0,
  input          io_ptw_resp_bits_s1_valididx_1,
  input          io_ptw_resp_bits_s1_valididx_2,
  input          io_ptw_resp_bits_s1_valididx_3,
  input          io_ptw_resp_bits_s1_valididx_4,
  input          io_ptw_resp_bits_s1_valididx_5,
  input          io_ptw_resp_bits_s1_valididx_6,
  input          io_ptw_resp_bits_s1_valididx_7,
  input          io_ptw_resp_bits_s1_pteidx_0,
  input          io_ptw_resp_bits_s1_pteidx_1,
  input          io_ptw_resp_bits_s1_pteidx_2,
  input          io_ptw_resp_bits_s1_pteidx_3,
  input          io_ptw_resp_bits_s1_pteidx_4,
  input          io_ptw_resp_bits_s1_pteidx_5,
  input          io_ptw_resp_bits_s1_pteidx_6,
  input          io_ptw_resp_bits_s1_pteidx_7,
  input          io_ptw_resp_bits_s1_pf,
  input          io_ptw_resp_bits_s1_af,
  input  [37:0]  io_ptw_resp_bits_s2_entry_tag,
  input  [13:0]  io_ptw_resp_bits_s2_entry_vmid,
  input          io_ptw_resp_bits_s2_entry_n,
  input  [1:0]   io_ptw_resp_bits_s2_entry_pbmt,
  input  [37:0]  io_ptw_resp_bits_s2_entry_ppn,
  input          io_ptw_resp_bits_s2_entry_perm_d,
  input          io_ptw_resp_bits_s2_entry_perm_a,
  input          io_ptw_resp_bits_s2_entry_perm_g,
  input          io_ptw_resp_bits_s2_entry_perm_u,
  input          io_ptw_resp_bits_s2_entry_perm_x,
  input          io_ptw_resp_bits_s2_entry_perm_w,
  input          io_ptw_resp_bits_s2_entry_perm_r,
  input  [1:0]   io_ptw_resp_bits_s2_entry_level,
  input          io_ptw_resp_bits_s2_gpf,
  input          io_ptw_resp_bits_s2_gaf,
  input          io_ptw_resp_bits_getGpa,
  output [5:0]   io_perf_0_value,
  output [5:0]   io_perf_1_value,
  output [338:0] gatewayIn_packed_3_bore,
  output [338:0] gatewayIn_packed_4_bore,
  output [338:0] gatewayIn_packed_5_bore
  // END GENERATED
);

  // ---- 延迟 2 拍的 sfence / CSR ----
  tlb_csr_t   csr_d;
  logic       sfence_d_valid, sfence_d_rs1, sfence_d_rs2, sfence_d_flushPipe, sfence_d_hv, sfence_d_hg;
  logic [49:0] sfence_d_addr;
  logic [15:0] sfence_d_id;
  logic       csr_d_mbmc_BME, csr_d_mbmc_CMODE;
  logic       csr_d_priv_debug;     // 本模块不用（golden 同样悬空）

  // BEGIN GENERATED(sfence_delay) —— scripts/gen_mmuleaf.py
  DelayN_9 sfence_delay (
    .clock                 (clock),
    .io_in_valid           (io_sfence_valid),
    .io_in_bits_rs1        (io_sfence_bits_rs1),
    .io_in_bits_rs2        (io_sfence_bits_rs2),
    .io_in_bits_addr       (io_sfence_bits_addr),
    .io_in_bits_id         (io_sfence_bits_id),
    .io_in_bits_flushPipe  (io_sfence_bits_flushPipe),
    .io_in_bits_hv         (io_sfence_bits_hv),
    .io_in_bits_hg         (io_sfence_bits_hg),
    .io_out_valid          (sfence_d_valid),
    .io_out_bits_rs1       (sfence_d_rs1),
    .io_out_bits_rs2       (sfence_d_rs2),
    .io_out_bits_addr      (sfence_d_addr),
    .io_out_bits_id        (sfence_d_id),
    .io_out_bits_flushPipe (sfence_d_flushPipe),
    .io_out_bits_hv        (sfence_d_hv),
    .io_out_bits_hg        (sfence_d_hg)
  );
  // END GENERATED

  // BEGIN GENERATED(csr_delay) —— scripts/gen_mmuleaf.py
  DelayN_7 csr_delay (
    .clock                    (clock),
    .io_in_satp_mode          (io_csr_satp_mode),
    .io_in_satp_asid          (io_csr_satp_asid),
    .io_in_satp_ppn           (io_csr_satp_ppn),
    .io_in_satp_changed       (io_csr_satp_changed),
    .io_in_vsatp_mode         (io_csr_vsatp_mode),
    .io_in_vsatp_asid         (io_csr_vsatp_asid),
    .io_in_vsatp_ppn          (io_csr_vsatp_ppn),
    .io_in_vsatp_changed      (io_csr_vsatp_changed),
    .io_in_hgatp_mode         (io_csr_hgatp_mode),
    .io_in_hgatp_vmid         (io_csr_hgatp_vmid),
    .io_in_hgatp_ppn          (io_csr_hgatp_ppn),
    .io_in_hgatp_changed      (io_csr_hgatp_changed),
    .io_in_mbmc_BME           (io_csr_mbmc_BME),
    .io_in_mbmc_CMODE         (io_csr_mbmc_CMODE),
    .io_in_priv_mxr           (io_csr_priv_mxr),
    .io_in_priv_sum           (io_csr_priv_sum),
    .io_in_priv_vmxr          (io_csr_priv_vmxr),
    .io_in_priv_vsum          (io_csr_priv_vsum),
    .io_in_priv_virt          (io_csr_priv_virt),
    .io_in_priv_virt_changed  (io_csr_priv_virt_changed),
    .io_in_priv_spvp          (io_csr_priv_spvp),
    .io_in_priv_imode         (io_csr_priv_imode),
    .io_in_priv_dmode         (io_csr_priv_dmode),
    .io_in_priv_debug         (io_csr_priv_debug),
    .io_in_pmm_mseccfg        (io_csr_pmm_mseccfg),
    .io_in_pmm_menvcfg        (io_csr_pmm_menvcfg),
    .io_in_pmm_henvcfg        (io_csr_pmm_henvcfg),
    .io_in_pmm_hstatus        (io_csr_pmm_hstatus),
    .io_in_pmm_senvcfg        (io_csr_pmm_senvcfg),
    .io_out_satp_mode         (csr_d.satp_mode),
    .io_out_satp_asid         (csr_d.satp_asid),
    .io_out_satp_ppn          (csr_d.satp_ppn),
    .io_out_satp_changed      (csr_d.satp_changed),
    .io_out_vsatp_mode        (csr_d.vsatp_mode),
    .io_out_vsatp_asid        (csr_d.vsatp_asid),
    .io_out_vsatp_ppn         (csr_d.vsatp_ppn),
    .io_out_vsatp_changed     (csr_d.vsatp_changed),
    .io_out_hgatp_mode        (csr_d.hgatp_mode),
    .io_out_hgatp_vmid        (csr_d.hgatp_vmid),
    .io_out_hgatp_ppn         (csr_d.hgatp_ppn),
    .io_out_hgatp_changed     (csr_d.hgatp_changed),
    .io_out_mbmc_BME          (csr_d_mbmc_BME),
    .io_out_mbmc_CMODE        (csr_d_mbmc_CMODE),
    .io_out_priv_mxr          (csr_d.priv_mxr),
    .io_out_priv_sum          (csr_d.priv_sum),
    .io_out_priv_vmxr         (csr_d.priv_vmxr),
    .io_out_priv_vsum         (csr_d.priv_vsum),
    .io_out_priv_virt         (csr_d.priv_virt),
    .io_out_priv_virt_changed (csr_d.priv_virt_changed),
    .io_out_priv_spvp         (csr_d.priv_spvp),
    .io_out_priv_imode        (csr_d.priv_imode),
    .io_out_priv_dmode        (csr_d.priv_dmode),
    .io_out_priv_debug        (csr_d_priv_debug),
    .io_out_pmm_mseccfg       (csr_d.pmm_mseccfg),
    .io_out_pmm_menvcfg       (csr_d.pmm_menvcfg),
    .io_out_pmm_henvcfg       (csr_d.pmm_henvcfg),
    .io_out_pmm_hstatus       (csr_d.pmm_hstatus),
    .io_out_pmm_senvcfg       (csr_d.pmm_senvcfg)
  );
  // END GENERATED

  // ---- PTW 响应打包成结构体 ----
  ptw_resp_t ptw_resp;
  // BEGIN GENERATED(ptw_resp) —— scripts/gen_mmuleaf.py
  assign ptw_resp.s2xlate = io_ptw_resp_bits_s2xlate;
  assign ptw_resp.s1.entry_tag = io_ptw_resp_bits_s1_entry_tag;
  assign ptw_resp.s1.entry_asid = io_ptw_resp_bits_s1_entry_asid;
  assign ptw_resp.s1.entry_vmid = io_ptw_resp_bits_s1_entry_vmid;
  assign ptw_resp.s1.entry_n = io_ptw_resp_bits_s1_entry_n;
  assign ptw_resp.s1.entry_pbmt = io_ptw_resp_bits_s1_entry_pbmt;
  assign ptw_resp.s1.entry_perm_d = io_ptw_resp_bits_s1_entry_perm_d;
  assign ptw_resp.s1.entry_perm_a = io_ptw_resp_bits_s1_entry_perm_a;
  assign ptw_resp.s1.entry_perm_g = io_ptw_resp_bits_s1_entry_perm_g;
  assign ptw_resp.s1.entry_perm_u = io_ptw_resp_bits_s1_entry_perm_u;
  assign ptw_resp.s1.entry_perm_x = io_ptw_resp_bits_s1_entry_perm_x;
  assign ptw_resp.s1.entry_perm_w = io_ptw_resp_bits_s1_entry_perm_w;
  assign ptw_resp.s1.entry_perm_r = io_ptw_resp_bits_s1_entry_perm_r;
  assign ptw_resp.s1.entry_level = io_ptw_resp_bits_s1_entry_level;
  assign ptw_resp.s1.entry_v = io_ptw_resp_bits_s1_entry_v;
  assign ptw_resp.s1.entry_ppn = io_ptw_resp_bits_s1_entry_ppn;
  assign ptw_resp.s1.addr_low = io_ptw_resp_bits_s1_addr_low;
  assign ptw_resp.s1.ppn_low[0] = io_ptw_resp_bits_s1_ppn_low_0;
  assign ptw_resp.s1.ppn_low[1] = io_ptw_resp_bits_s1_ppn_low_1;
  assign ptw_resp.s1.ppn_low[2] = io_ptw_resp_bits_s1_ppn_low_2;
  assign ptw_resp.s1.ppn_low[3] = io_ptw_resp_bits_s1_ppn_low_3;
  assign ptw_resp.s1.ppn_low[4] = io_ptw_resp_bits_s1_ppn_low_4;
  assign ptw_resp.s1.ppn_low[5] = io_ptw_resp_bits_s1_ppn_low_5;
  assign ptw_resp.s1.ppn_low[6] = io_ptw_resp_bits_s1_ppn_low_6;
  assign ptw_resp.s1.ppn_low[7] = io_ptw_resp_bits_s1_ppn_low_7;
  assign ptw_resp.s1.valididx[0] = io_ptw_resp_bits_s1_valididx_0;
  assign ptw_resp.s1.valididx[1] = io_ptw_resp_bits_s1_valididx_1;
  assign ptw_resp.s1.valididx[2] = io_ptw_resp_bits_s1_valididx_2;
  assign ptw_resp.s1.valididx[3] = io_ptw_resp_bits_s1_valididx_3;
  assign ptw_resp.s1.valididx[4] = io_ptw_resp_bits_s1_valididx_4;
  assign ptw_resp.s1.valididx[5] = io_ptw_resp_bits_s1_valididx_5;
  assign ptw_resp.s1.valididx[6] = io_ptw_resp_bits_s1_valididx_6;
  assign ptw_resp.s1.valididx[7] = io_ptw_resp_bits_s1_valididx_7;
  assign ptw_resp.s1.pteidx[0] = io_ptw_resp_bits_s1_pteidx_0;
  assign ptw_resp.s1.pteidx[1] = io_ptw_resp_bits_s1_pteidx_1;
  assign ptw_resp.s1.pteidx[2] = io_ptw_resp_bits_s1_pteidx_2;
  assign ptw_resp.s1.pteidx[3] = io_ptw_resp_bits_s1_pteidx_3;
  assign ptw_resp.s1.pteidx[4] = io_ptw_resp_bits_s1_pteidx_4;
  assign ptw_resp.s1.pteidx[5] = io_ptw_resp_bits_s1_pteidx_5;
  assign ptw_resp.s1.pteidx[6] = io_ptw_resp_bits_s1_pteidx_6;
  assign ptw_resp.s1.pteidx[7] = io_ptw_resp_bits_s1_pteidx_7;
  assign ptw_resp.s1.pf = io_ptw_resp_bits_s1_pf;
  assign ptw_resp.s1.af = io_ptw_resp_bits_s1_af;
  assign ptw_resp.s2.entry_tag = io_ptw_resp_bits_s2_entry_tag;
  assign ptw_resp.s2.entry_vmid = io_ptw_resp_bits_s2_entry_vmid;
  assign ptw_resp.s2.entry_n = io_ptw_resp_bits_s2_entry_n;
  assign ptw_resp.s2.entry_pbmt = io_ptw_resp_bits_s2_entry_pbmt;
  assign ptw_resp.s2.entry_ppn = io_ptw_resp_bits_s2_entry_ppn;
  assign ptw_resp.s2.entry_perm_d = io_ptw_resp_bits_s2_entry_perm_d;
  assign ptw_resp.s2.entry_perm_a = io_ptw_resp_bits_s2_entry_perm_a;
  assign ptw_resp.s2.entry_perm_g = io_ptw_resp_bits_s2_entry_perm_g;
  assign ptw_resp.s2.entry_perm_u = io_ptw_resp_bits_s2_entry_perm_u;
  assign ptw_resp.s2.entry_perm_x = io_ptw_resp_bits_s2_entry_perm_x;
  assign ptw_resp.s2.entry_perm_w = io_ptw_resp_bits_s2_entry_perm_w;
  assign ptw_resp.s2.entry_perm_r = io_ptw_resp_bits_s2_entry_perm_r;
  assign ptw_resp.s2.entry_level = io_ptw_resp_bits_s2_entry_level;
  assign ptw_resp.s2.gpf = io_ptw_resp_bits_s2_gpf;
  assign ptw_resp.s2.gaf = io_ptw_resp_bits_s2_gaf;
  assign ptw_resp.get_gpa = io_ptw_resp_bits_getGpa;
  // END GENERATED

  // ---- 核 <-> 表项 ----
  logic [W-1:0]              stor_r_req_valid;
  logic [W-1:0][VPN_W-1:0]   stor_r_req_vpn;
  logic [W-1:0][1:0]         stor_r_req_s2xlate;
  logic [W-1:0]              stor_r_hit;
  logic [W-1:0][PPN_W-1:0]   stor_r_ppn;
  logic [W-1:0][1:0]         stor_r_pbmt, stor_r_g_pbmt, stor_r_s2xlate;
  itlb_perm_t  [W-1:0]       stor_r_perm;
  itlb_gperm_t [W-1:0]       stor_r_g_perm;
  logic                      stor_w_valid;

  // BEGIN GENERATED(entries) —— scripts/gen_mmuleaf.py
  TlbStorageWrapper entries (
    .clock                          (clock),
    .reset                          (reset),
    .io_sfence_valid                (sfence_d_valid),
    .io_sfence_bits_rs1             (sfence_d_rs1),
    .io_sfence_bits_rs2             (sfence_d_rs2),
    .io_sfence_bits_addr            (sfence_d_addr),
    .io_sfence_bits_id              (sfence_d_id),
    .io_sfence_bits_hv              (sfence_d_hv),
    .io_sfence_bits_hg              (sfence_d_hg),
    .io_csr_satp_asid               (csr_d.satp_asid),
    .io_csr_vsatp_asid              (csr_d.vsatp_asid),
    .io_csr_hgatp_vmid              (csr_d.hgatp_vmid),
    .io_csr_mbmc_BME                (csr_d_mbmc_BME),
    .io_csr_mbmc_CMODE              (csr_d_mbmc_CMODE),
    .io_csr_priv_virt               (csr_d.priv_virt),
    .io_r_req_0_valid               (stor_r_req_valid[0]),
    .io_r_req_0_bits_vpn            (stor_r_req_vpn[0]),
    .io_r_req_0_bits_s2xlate        (stor_r_req_s2xlate[0]),
    .io_r_req_1_valid               (stor_r_req_valid[1]),
    .io_r_req_1_bits_vpn            (stor_r_req_vpn[1]),
    .io_r_req_1_bits_s2xlate        (stor_r_req_s2xlate[1]),
    .io_r_req_2_valid               (stor_r_req_valid[2]),
    .io_r_req_2_bits_vpn            (stor_r_req_vpn[2]),
    .io_r_req_2_bits_s2xlate        (stor_r_req_s2xlate[2]),
    .io_r_resp_0_bits_hit           (stor_r_hit[0]),
    .io_r_resp_0_bits_ppn_0         (stor_r_ppn[0]),
    .io_r_resp_0_bits_pbmt_0        (stor_r_pbmt[0]),
    .io_r_resp_0_bits_g_pbmt_0      (stor_r_g_pbmt[0]),
    .io_r_resp_0_bits_perm_0_pf     (stor_r_perm[0].pf),
    .io_r_resp_0_bits_perm_0_af     (stor_r_perm[0].af),
    .io_r_resp_0_bits_perm_0_v      (stor_r_perm[0].v),
    .io_r_resp_0_bits_perm_0_a      (stor_r_perm[0].a),
    .io_r_resp_0_bits_perm_0_u      (stor_r_perm[0].u),
    .io_r_resp_0_bits_perm_0_x      (stor_r_perm[0].x),
    .io_r_resp_0_bits_perm_0_w      (stor_r_perm[0].w),
    .io_r_resp_0_bits_perm_0_r      (stor_r_perm[0].r),
    .io_r_resp_0_bits_g_perm_0_pf   (stor_r_g_perm[0].pf),
    .io_r_resp_0_bits_g_perm_0_af   (stor_r_g_perm[0].af),
    .io_r_resp_0_bits_g_perm_0_a    (stor_r_g_perm[0].a),
    .io_r_resp_0_bits_g_perm_0_x    (stor_r_g_perm[0].x),
    .io_r_resp_0_bits_s2xlate_0     (stor_r_s2xlate[0]),
    .io_r_resp_1_bits_hit           (stor_r_hit[1]),
    .io_r_resp_1_bits_ppn_0         (stor_r_ppn[1]),
    .io_r_resp_1_bits_pbmt_0        (stor_r_pbmt[1]),
    .io_r_resp_1_bits_g_pbmt_0      (stor_r_g_pbmt[1]),
    .io_r_resp_1_bits_perm_0_pf     (stor_r_perm[1].pf),
    .io_r_resp_1_bits_perm_0_af     (stor_r_perm[1].af),
    .io_r_resp_1_bits_perm_0_v      (stor_r_perm[1].v),
    .io_r_resp_1_bits_perm_0_a      (stor_r_perm[1].a),
    .io_r_resp_1_bits_perm_0_u      (stor_r_perm[1].u),
    .io_r_resp_1_bits_perm_0_x      (stor_r_perm[1].x),
    .io_r_resp_1_bits_perm_0_w      (stor_r_perm[1].w),
    .io_r_resp_1_bits_perm_0_r      (stor_r_perm[1].r),
    .io_r_resp_1_bits_g_perm_0_pf   (stor_r_g_perm[1].pf),
    .io_r_resp_1_bits_g_perm_0_af   (stor_r_g_perm[1].af),
    .io_r_resp_1_bits_g_perm_0_a    (stor_r_g_perm[1].a),
    .io_r_resp_1_bits_g_perm_0_x    (stor_r_g_perm[1].x),
    .io_r_resp_1_bits_s2xlate_0     (stor_r_s2xlate[1]),
    .io_r_resp_2_bits_hit           (stor_r_hit[2]),
    .io_r_resp_2_bits_ppn_0         (stor_r_ppn[2]),
    .io_r_resp_2_bits_pbmt_0        (stor_r_pbmt[2]),
    .io_r_resp_2_bits_g_pbmt_0      (stor_r_g_pbmt[2]),
    .io_r_resp_2_bits_perm_0_pf     (stor_r_perm[2].pf),
    .io_r_resp_2_bits_perm_0_af     (stor_r_perm[2].af),
    .io_r_resp_2_bits_perm_0_v      (stor_r_perm[2].v),
    .io_r_resp_2_bits_perm_0_a      (stor_r_perm[2].a),
    .io_r_resp_2_bits_perm_0_u      (stor_r_perm[2].u),
    .io_r_resp_2_bits_perm_0_x      (stor_r_perm[2].x),
    .io_r_resp_2_bits_perm_0_w      (stor_r_perm[2].w),
    .io_r_resp_2_bits_perm_0_r      (stor_r_perm[2].r),
    .io_r_resp_2_bits_g_perm_0_pf   (stor_r_g_perm[2].pf),
    .io_r_resp_2_bits_g_perm_0_af   (stor_r_g_perm[2].af),
    .io_r_resp_2_bits_g_perm_0_a    (stor_r_g_perm[2].a),
    .io_r_resp_2_bits_g_perm_0_x    (stor_r_g_perm[2].x),
    .io_r_resp_2_bits_s2xlate_0     (stor_r_s2xlate[2]),
    .io_w_valid                     (stor_w_valid),
    .io_w_bits_data_s2xlate         (io_ptw_resp_bits_s2xlate),
    .io_w_bits_data_s1_entry_tag    (io_ptw_resp_bits_s1_entry_tag),
    .io_w_bits_data_s1_entry_asid   (io_ptw_resp_bits_s1_entry_asid),
    .io_w_bits_data_s1_entry_vmid   (io_ptw_resp_bits_s1_entry_vmid),
    .io_w_bits_data_s1_entry_n      (io_ptw_resp_bits_s1_entry_n),
    .io_w_bits_data_s1_entry_pbmt   (io_ptw_resp_bits_s1_entry_pbmt),
    .io_w_bits_data_s1_entry_perm_d (io_ptw_resp_bits_s1_entry_perm_d),
    .io_w_bits_data_s1_entry_perm_a (io_ptw_resp_bits_s1_entry_perm_a),
    .io_w_bits_data_s1_entry_perm_g (io_ptw_resp_bits_s1_entry_perm_g),
    .io_w_bits_data_s1_entry_perm_u (io_ptw_resp_bits_s1_entry_perm_u),
    .io_w_bits_data_s1_entry_perm_x (io_ptw_resp_bits_s1_entry_perm_x),
    .io_w_bits_data_s1_entry_perm_w (io_ptw_resp_bits_s1_entry_perm_w),
    .io_w_bits_data_s1_entry_perm_r (io_ptw_resp_bits_s1_entry_perm_r),
    .io_w_bits_data_s1_entry_level  (io_ptw_resp_bits_s1_entry_level),
    .io_w_bits_data_s1_entry_v      (io_ptw_resp_bits_s1_entry_v),
    .io_w_bits_data_s1_entry_ppn    (io_ptw_resp_bits_s1_entry_ppn),
    .io_w_bits_data_s1_ppn_low_0    (io_ptw_resp_bits_s1_ppn_low_0),
    .io_w_bits_data_s1_ppn_low_1    (io_ptw_resp_bits_s1_ppn_low_1),
    .io_w_bits_data_s1_ppn_low_2    (io_ptw_resp_bits_s1_ppn_low_2),
    .io_w_bits_data_s1_ppn_low_3    (io_ptw_resp_bits_s1_ppn_low_3),
    .io_w_bits_data_s1_ppn_low_4    (io_ptw_resp_bits_s1_ppn_low_4),
    .io_w_bits_data_s1_ppn_low_5    (io_ptw_resp_bits_s1_ppn_low_5),
    .io_w_bits_data_s1_ppn_low_6    (io_ptw_resp_bits_s1_ppn_low_6),
    .io_w_bits_data_s1_ppn_low_7    (io_ptw_resp_bits_s1_ppn_low_7),
    .io_w_bits_data_s1_valididx_0   (io_ptw_resp_bits_s1_valididx_0),
    .io_w_bits_data_s1_valididx_1   (io_ptw_resp_bits_s1_valididx_1),
    .io_w_bits_data_s1_valididx_2   (io_ptw_resp_bits_s1_valididx_2),
    .io_w_bits_data_s1_valididx_3   (io_ptw_resp_bits_s1_valididx_3),
    .io_w_bits_data_s1_valididx_4   (io_ptw_resp_bits_s1_valididx_4),
    .io_w_bits_data_s1_valididx_5   (io_ptw_resp_bits_s1_valididx_5),
    .io_w_bits_data_s1_valididx_6   (io_ptw_resp_bits_s1_valididx_6),
    .io_w_bits_data_s1_valididx_7   (io_ptw_resp_bits_s1_valididx_7),
    .io_w_bits_data_s1_pteidx_0     (io_ptw_resp_bits_s1_pteidx_0),
    .io_w_bits_data_s1_pteidx_1     (io_ptw_resp_bits_s1_pteidx_1),
    .io_w_bits_data_s1_pteidx_2     (io_ptw_resp_bits_s1_pteidx_2),
    .io_w_bits_data_s1_pteidx_3     (io_ptw_resp_bits_s1_pteidx_3),
    .io_w_bits_data_s1_pteidx_4     (io_ptw_resp_bits_s1_pteidx_4),
    .io_w_bits_data_s1_pteidx_5     (io_ptw_resp_bits_s1_pteidx_5),
    .io_w_bits_data_s1_pteidx_6     (io_ptw_resp_bits_s1_pteidx_6),
    .io_w_bits_data_s1_pteidx_7     (io_ptw_resp_bits_s1_pteidx_7),
    .io_w_bits_data_s1_pf           (io_ptw_resp_bits_s1_pf),
    .io_w_bits_data_s1_af           (io_ptw_resp_bits_s1_af),
    .io_w_bits_data_s2_entry_tag    (io_ptw_resp_bits_s2_entry_tag),
    .io_w_bits_data_s2_entry_vmid   (io_ptw_resp_bits_s2_entry_vmid),
    .io_w_bits_data_s2_entry_n      (io_ptw_resp_bits_s2_entry_n),
    .io_w_bits_data_s2_entry_pbmt   (io_ptw_resp_bits_s2_entry_pbmt),
    .io_w_bits_data_s2_entry_ppn    (io_ptw_resp_bits_s2_entry_ppn),
    .io_w_bits_data_s2_entry_perm_d (io_ptw_resp_bits_s2_entry_perm_d),
    .io_w_bits_data_s2_entry_perm_a (io_ptw_resp_bits_s2_entry_perm_a),
    .io_w_bits_data_s2_entry_perm_g (io_ptw_resp_bits_s2_entry_perm_g),
    .io_w_bits_data_s2_entry_perm_u (io_ptw_resp_bits_s2_entry_perm_u),
    .io_w_bits_data_s2_entry_perm_x (io_ptw_resp_bits_s2_entry_perm_x),
    .io_w_bits_data_s2_entry_perm_w (io_ptw_resp_bits_s2_entry_perm_w),
    .io_w_bits_data_s2_entry_perm_r (io_ptw_resp_bits_s2_entry_perm_r),
    .io_w_bits_data_s2_entry_level  (io_ptw_resp_bits_s2_entry_level),
    .io_w_bits_data_s2_gpf          (io_ptw_resp_bits_s2_gpf),
    .io_w_bits_data_s2_gaf          (io_ptw_resp_bits_s2_gaf)
  );
  // END GENERATED

  // ---- 核 ----
  logic [W-1:0][PADDR_W-1:0] resp_paddr;
  logic [W-1:0][XLEN-1:0]    resp_gpaddr;
  logic [W-1:0][1:0]         resp_pbmt;
  logic [W-1:0]              resp_miss, resp_vs_non_leaf, resp_gpf, resp_pf, resp_af;
  logic [W-1:0]              ptw_req_valid, ptw_req_get_gpa;
  logic [W-1:0][VPN_W-1:0]   ptw_req_vpn;
  logic [W-1:0][1:0]         ptw_req_s2xlate;
  logic [W-1:0][338:0]       difftest_packed;

  xs_TLB_core u_core (
    .clock                       (clock),
    .reset                       (reset),
    .sfence_valid_d              (sfence_d_valid),
    .sfence_flush_pipe_d         (sfence_d_flushPipe),
    .csr                         (csr_d),
    .hart_id                     (io_hartId),
    .req_valid                   ({io_requestor_2_req_valid, io_requestor_1_req_valid, io_requestor_0_req_valid}),
    .req_vaddr                   ({io_requestor_2_req_bits_vaddr, io_requestor_1_req_bits_vaddr,
                                   io_requestor_0_req_bits_vaddr}),
    .req2_ready                  (io_requestor_2_req_ready),
    .flush_pipe                  ({io_flushPipe_2, io_flushPipe_1, io_flushPipe_0}),
    .resp2_valid                 (io_requestor_2_resp_valid),
    .resp2_ready                 (io_requestor_2_resp_ready),
    .resp_paddr                  (resp_paddr),
    .resp_gpaddr                 (resp_gpaddr),
    .resp_pbmt                   (resp_pbmt),
    .resp_miss                   (resp_miss),
    .resp_is_for_vs_non_leaf_pte (resp_vs_non_leaf),
    .resp_gpf_instr              (resp_gpf),
    .resp_pf_instr               (resp_pf),
    .resp_af_instr               (resp_af),
    .ptw_req_ready               ({io_ptw_req_2_ready, io_ptw_req_1_ready, io_ptw_req_0_ready}),
    .ptw_req_valid               (ptw_req_valid),
    .ptw_req_vpn                 (ptw_req_vpn),
    .ptw_req_s2xlate             (ptw_req_s2xlate),
    .ptw_req_get_gpa             (ptw_req_get_gpa),
    .ptw_resp_valid              (io_ptw_resp_valid),
    .ptw_resp                    (ptw_resp),
    .perf_access                 (io_perf_0_value),
    .perf_miss                   (io_perf_1_value),
    .stor_r_req_valid            (stor_r_req_valid),
    .stor_r_req_vpn              (stor_r_req_vpn),
    .stor_r_req_s2xlate          (stor_r_req_s2xlate),
    .stor_r_hit                  (stor_r_hit),
    .stor_r_ppn                  (stor_r_ppn),
    .stor_r_pbmt                 (stor_r_pbmt),
    .stor_r_g_pbmt               (stor_r_g_pbmt),
    .stor_r_perm                 (stor_r_perm),
    .stor_r_g_perm               (stor_r_g_perm),
    .stor_r_s2xlate              (stor_r_s2xlate),
    .stor_w_valid                (stor_w_valid),
    .difftest_packed             (difftest_packed)
  );

  // ---- 每口的扁平输出 ----
  // BEGIN GENERATED(resp_out) —— scripts/gen_mmuleaf.py
  assign io_requestor_0_resp_bits_paddr_0 = resp_paddr[0];
  assign io_requestor_0_resp_bits_gpaddr_0 = resp_gpaddr[0];
  assign io_requestor_0_resp_bits_pbmt_0 = resp_pbmt[0];
  assign io_requestor_0_resp_bits_miss = resp_miss[0];
  assign io_requestor_0_resp_bits_isForVSnonLeafPTE = resp_vs_non_leaf[0];
  assign io_requestor_0_resp_bits_excp_0_gpf_instr = resp_gpf[0];
  assign io_requestor_0_resp_bits_excp_0_pf_instr = resp_pf[0];
  assign io_requestor_0_resp_bits_excp_0_af_instr = resp_af[0];
  assign io_requestor_1_resp_bits_paddr_0 = resp_paddr[1];
  assign io_requestor_1_resp_bits_gpaddr_0 = resp_gpaddr[1];
  assign io_requestor_1_resp_bits_pbmt_0 = resp_pbmt[1];
  assign io_requestor_1_resp_bits_miss = resp_miss[1];
  assign io_requestor_1_resp_bits_isForVSnonLeafPTE = resp_vs_non_leaf[1];
  assign io_requestor_1_resp_bits_excp_0_gpf_instr = resp_gpf[1];
  assign io_requestor_1_resp_bits_excp_0_pf_instr = resp_pf[1];
  assign io_requestor_1_resp_bits_excp_0_af_instr = resp_af[1];
  assign io_requestor_2_resp_bits_paddr_0 = resp_paddr[2];
  assign io_requestor_2_resp_bits_gpaddr_0 = resp_gpaddr[2];
  assign io_requestor_2_resp_bits_pbmt_0 = resp_pbmt[2];
  assign io_requestor_2_resp_bits_miss = resp_miss[2];
  assign io_requestor_2_resp_bits_isForVSnonLeafPTE = resp_vs_non_leaf[2];
  assign io_requestor_2_resp_bits_excp_0_gpf_instr = resp_gpf[2];
  assign io_requestor_2_resp_bits_excp_0_pf_instr = resp_pf[2];
  assign io_requestor_2_resp_bits_excp_0_af_instr = resp_af[2];
  assign io_ptw_req_0_valid = ptw_req_valid[0];
  assign io_ptw_req_0_bits_vpn = ptw_req_vpn[0];
  assign io_ptw_req_0_bits_s2xlate = ptw_req_s2xlate[0];
  assign io_ptw_req_0_bits_getGpa = ptw_req_get_gpa[0];
  assign io_ptw_req_1_valid = ptw_req_valid[1];
  assign io_ptw_req_1_bits_vpn = ptw_req_vpn[1];
  assign io_ptw_req_1_bits_s2xlate = ptw_req_s2xlate[1];
  assign io_ptw_req_1_bits_getGpa = ptw_req_get_gpa[1];
  assign io_ptw_req_2_valid = ptw_req_valid[2];
  assign io_ptw_req_2_bits_vpn = ptw_req_vpn[2];
  assign io_ptw_req_2_bits_s2xlate = ptw_req_s2xlate[2];
  assign io_ptw_req_2_bits_getGpa = ptw_req_get_gpa[2];
  // END GENERATED

  assign gatewayIn_packed_3_bore = difftest_packed[0];
  assign gatewayIn_packed_4_bore = difftest_packed[1];
  assign gatewayIn_packed_5_bore = difftest_packed[2];

endmodule
