// ============================================================================
// xs_L2TLB_core —— L2TLB 顶层（香山 V2R2 共享 MMU 总集成 / 页表遍历器）
// ----------------------------------------------------------------------------
// 设计意图来源：src/main/scala/xiangshan/cache/mmu/L2TLB.scala（class L2TLBImp）
//
// L2TLB 把 PTW / LLPTW / HPTW / PtwCache / L2TlbMissQueue / L2TlbPrefetch / PMP /
// 多个 Arbiter / DelayN / BlockHelper 组装成完整的页表遍历器：接收 ITLB/DTLB 的 miss
// 请求，经 page cache 命中→直接返回，未命中→PTW(非叶级)/LLPTW(叶级)/HPTW(G-stage)
// 遍历→向 L2 访存读 PTE→回填 page cache 并把结果合并成 sector PtwResp 返回 TLB。
//
// 本层只承担**仲裁 / 路由 / 分发 / 访存数据通路的 glue**，遍历/缓存/仲裁算法都封装在
// 子模块里（对本层是 golden 黑盒，UT/FM 两侧共用同一份 golden 定义）。本文件按功能
// 分节手写这些 glue（子模块实例与机械直通连接见 L2TLB_inst.svh）：
//   1) CSR / sfence 复制扇出（DelayN 1 拍 + RegNext 1 拍 → 多份同值副本，降扇出）
//   2) ITLB/DTLB 请求计数与节流（tlbCounter）
//   3) page cache 入口仲裁(arb2)输入装配 + miss queue 仲裁(mq_arb)
//   4) PTW / LLPTW / HPTW 请求分发（按 cache resp 的 hit/l1Hit/isHptwReq/bypassed）
//   5) page cache resp.ready 多路选择 + cache.req / cache.refill 装配
//   6) 访存数据通路：mem_arb→TileLink A；D 通道 refill_data 拼装；waiting_resp /
//      flush_latch 在途跟踪；resp_pte 各 id 暂存（struct + function + genvar）
//   7) HPTW 响应分发（cache hit / hptw → ptw / llptw）
//   8) 输出合并：mergeArb 三路输入（cache / ptw / llptw）+ outArb → ITLB/DTLB resp
//      （contiguous_pte_to_merge / merge_to_sector 两个 function automatic）
//   9) PMP checker 请求装配；prefetch 触发；wfi
//
// 验证：UT 与 golden L2TLB 双例化逐拍比对全部 147 个输出；FM 以子模块为两侧共享 golden
//       黑盒，对本层 glue 做签名等价。
// ============================================================================
module xs_L2TLB_core
  import xs_ptw_pkg::*;
  import l2tlb_pkg::*;
(
  `include "L2TLB_ports.svh"
);

  // 子模块输出网声明（由 L2TLB_inst.svh 里的实例驱动）。
  `include "L2TLB_wires.svh"
  // glue 输入网声明（由本核功能分节手写驱动；名 <inst>__<port_tail>）。
  `include "L2TLB_driven.svh"

  // ==========================================================================
  // 1. CSR / sfence 复制扇出
  // --------------------------------------------------------------------------
  // io.csr.tlb / io.sfence 先经 DelayN(1) 得到 csr_tmp / sfence_tmp（= u_csr_delay /
  // u_sfence_delay 的输出），再各 RegNext 一拍得到多份同值副本 csr_dup[0..7] /
  // sfence_dup[0..8]。复制只为降低长扇出，所有副本逻辑值相同。各子模块按固定下标取用：
  //   prefetch/flush=0, llptw=1, cache=2(+3,4), missQueue csr=5/sfence=6, ptw=6/7,
  //   hptw csr=7/sfence=8。csr_dup(0) 还用于 flush 判定。
  // ==========================================================================
  l2tlb_csr_t    csr_tmp;
  l2tlb_sfence_t sfence_tmp;
  assign csr_tmp = '{
    satp_mode: u_csr_delay_out_satp_mode,   satp_asid: u_csr_delay_out_satp_asid,
    satp_ppn:  u_csr_delay_out_satp_ppn,    satp_changed: u_csr_delay_out_satp_changed,
    vsatp_mode: u_csr_delay_out_vsatp_mode, vsatp_asid: u_csr_delay_out_vsatp_asid,
    vsatp_ppn: u_csr_delay_out_vsatp_ppn,   vsatp_changed: u_csr_delay_out_vsatp_changed,
    hgatp_mode: u_csr_delay_out_hgatp_mode, hgatp_vmid: u_csr_delay_out_hgatp_vmid,
    hgatp_ppn: u_csr_delay_out_hgatp_ppn,   hgatp_changed: u_csr_delay_out_hgatp_changed,
    priv_mxr: u_csr_delay_out_priv_mxr,     priv_virt: u_csr_delay_out_priv_virt,
    mPBMTE: u_csr_delay_out_mPBMTE,         hPBMTE: u_csr_delay_out_hPBMTE };
  assign sfence_tmp = '{
    valid: u_sfence_delay_out_valid, rs1: u_sfence_delay_out_bits_rs1,
    rs2: u_sfence_delay_out_bits_rs2, addr: u_sfence_delay_out_bits_addr,
    id: u_sfence_delay_out_bits_id, hv: u_sfence_delay_out_bits_hv,
    hg: u_sfence_delay_out_bits_hg };

  l2tlb_csr_t    csr_dup    [8];
  l2tlb_sfence_t sfence_dup [9];
  for (genvar i = 0; i < 8; i++) begin : g_csr_dup
    always_ff @(posedge clock) csr_dup[i] <= csr_tmp;
  end
  for (genvar i = 0; i < 9; i++) begin : g_sfence_dup
    always_ff @(posedge clock) sfence_dup[i] <= sfence_tmp;
  end

  // flush：sfence 有效 或 satp/vsatp/hgatp 任一变化（用 csr_dup(0)）。
  wire flush = sfence_dup[0].valid | csr_dup[0].satp_changed
             | csr_dup[0].vsatp_changed | csr_dup[0].hgatp_changed;

  // -- 把各子模块的 csr/sfence 输入接到对应副本 --
  // prefetch ← csr/sfence 0
  assign u_prefetch__csr_satp_changed  = csr_dup[0].satp_changed;
  assign u_prefetch__csr_vsatp_changed = csr_dup[0].vsatp_changed;
  assign u_prefetch__csr_vsatp_mode    = csr_dup[0].vsatp_mode;
  assign u_prefetch__csr_hgatp_changed = csr_dup[0].hgatp_changed;
  assign u_prefetch__csr_hgatp_mode    = csr_dup[0].hgatp_mode;
  assign u_prefetch__csr_priv_virt     = csr_dup[0].priv_virt;
  assign u_prefetch__sfence_valid      = sfence_dup[0].valid;
  // llptw ← csr/sfence 1
  assign u_llptw__csr_satp_changed  = csr_dup[1].satp_changed;
  assign u_llptw__csr_vsatp_changed = csr_dup[1].vsatp_changed;
  assign u_llptw__csr_hgatp_changed = csr_dup[1].hgatp_changed;
  assign u_llptw__csr_hgatp_mode    = csr_dup[1].hgatp_mode;
  assign u_llptw__csr_priv_mxr      = csr_dup[1].priv_mxr;
  assign u_llptw__csr_mPBMTE        = csr_dup[1].mPBMTE;
  assign u_llptw__csr_hPBMTE        = csr_dup[1].hPBMTE;
  assign u_llptw__sfence_valid      = sfence_dup[1].valid;
  // cache 自带 csr_dup[0..2] = csr_dup(2,3,4)；sfence_dup[0..2] = sfence_dup(2,3,4)
  for (genvar k = 0; k < 3; k++) begin : g_cache_csr
    // 仅连 cache 真正用到的字段（其余在 inst.svh 直连顶层/置 0）。
    if (k == 0) begin : k0
      assign u_page_cache__csr_dup_0_satp_asid    = csr_dup[2].satp_asid;
      assign u_page_cache__csr_dup_0_satp_changed = csr_dup[2].satp_changed;
      assign u_page_cache__csr_dup_0_vsatp_asid   = csr_dup[2].vsatp_asid;
      assign u_page_cache__csr_dup_0_vsatp_changed= csr_dup[2].vsatp_changed;
      assign u_page_cache__csr_dup_0_hgatp_vmid   = csr_dup[2].hgatp_vmid;
      assign u_page_cache__csr_dup_0_hgatp_mode   = csr_dup[2].hgatp_mode;
      assign u_page_cache__csr_dup_0_hgatp_changed= csr_dup[2].hgatp_changed;
      assign u_page_cache__csr_dup_0_priv_virt    = csr_dup[2].priv_virt;
    end else if (k == 1) begin : k1
      assign u_page_cache__csr_dup_1_satp_asid    = csr_dup[3].satp_asid;
      assign u_page_cache__csr_dup_1_satp_changed = csr_dup[3].satp_changed;
      assign u_page_cache__csr_dup_1_vsatp_asid   = csr_dup[3].vsatp_asid;
      assign u_page_cache__csr_dup_1_vsatp_changed= csr_dup[3].vsatp_changed;
      assign u_page_cache__csr_dup_1_hgatp_vmid   = csr_dup[3].hgatp_vmid;
      assign u_page_cache__csr_dup_1_hgatp_mode   = csr_dup[3].hgatp_mode;
      assign u_page_cache__csr_dup_1_hgatp_changed= csr_dup[3].hgatp_changed;
      assign u_page_cache__csr_dup_1_priv_virt    = csr_dup[3].priv_virt;
    end else begin : k2
      assign u_page_cache__csr_dup_2_satp_asid    = csr_dup[4].satp_asid;
      assign u_page_cache__csr_dup_2_satp_changed = csr_dup[4].satp_changed;
      assign u_page_cache__csr_dup_2_vsatp_asid   = csr_dup[4].vsatp_asid;
      assign u_page_cache__csr_dup_2_vsatp_changed= csr_dup[4].vsatp_changed;
      assign u_page_cache__csr_dup_2_hgatp_vmid   = csr_dup[4].hgatp_vmid;
      assign u_page_cache__csr_dup_2_hgatp_mode   = csr_dup[4].hgatp_mode;
      assign u_page_cache__csr_dup_2_hgatp_changed= csr_dup[4].hgatp_changed;
      assign u_page_cache__csr_dup_2_priv_virt    = csr_dup[4].priv_virt;
    end
  end
  assign u_page_cache__csr_mPBMTE = csr_dup[2].mPBMTE;
  assign u_page_cache__csr_hPBMTE = csr_dup[2].hPBMTE;
  assign u_page_cache__sfence_dup_0_valid    = sfence_dup[2].valid;
  assign u_page_cache__sfence_dup_0_bits_rs1 = sfence_dup[2].rs1;
  assign u_page_cache__sfence_dup_0_bits_rs2 = sfence_dup[2].rs2;
  assign u_page_cache__sfence_dup_0_bits_addr= sfence_dup[2].addr;
  assign u_page_cache__sfence_dup_0_bits_id  = sfence_dup[2].id;
  assign u_page_cache__sfence_dup_0_bits_hv  = sfence_dup[2].hv;
  assign u_page_cache__sfence_dup_0_bits_hg  = sfence_dup[2].hg;
  assign u_page_cache__sfence_dup_1_valid    = sfence_dup[3].valid;
  assign u_page_cache__sfence_dup_1_bits_id  = sfence_dup[3].id;
  assign u_page_cache__sfence_dup_2_valid    = sfence_dup[4].valid;
  assign u_page_cache__sfence_dup_2_bits_id  = sfence_dup[4].id;
  assign u_page_cache__sfence_dup_2_bits_rs1 = sfence_dup[4].rs1;
  assign u_page_cache__sfence_dup_2_bits_rs2 = sfence_dup[4].rs2;
  // missQueue ← csr 5 / sfence 6
  assign u_miss_queue__csr_satp_changed  = csr_dup[5].satp_changed;
  assign u_miss_queue__csr_vsatp_changed = csr_dup[5].vsatp_changed;
  assign u_miss_queue__csr_hgatp_changed = csr_dup[5].hgatp_changed;
  assign u_miss_queue__sfence_valid      = sfence_dup[6].valid;
  // ptw ← csr 6 / sfence 7
  assign u_ptw__csr_satp_mode    = csr_dup[6].satp_mode;
  assign u_ptw__csr_satp_asid    = csr_dup[6].satp_asid;
  assign u_ptw__csr_satp_ppn     = csr_dup[6].satp_ppn;
  assign u_ptw__csr_satp_changed = csr_dup[6].satp_changed;
  assign u_ptw__csr_vsatp_mode   = csr_dup[6].vsatp_mode;
  assign u_ptw__csr_vsatp_asid   = csr_dup[6].vsatp_asid;
  assign u_ptw__csr_vsatp_ppn    = csr_dup[6].vsatp_ppn;
  assign u_ptw__csr_vsatp_changed= csr_dup[6].vsatp_changed;
  assign u_ptw__csr_hgatp_mode   = csr_dup[6].hgatp_mode;
  assign u_ptw__csr_hgatp_vmid   = csr_dup[6].hgatp_vmid;
  assign u_ptw__csr_hgatp_changed= csr_dup[6].hgatp_changed;
  assign u_ptw__csr_priv_mxr     = csr_dup[6].priv_mxr;
  assign u_ptw__csr_mPBMTE       = csr_dup[6].mPBMTE;
  assign u_ptw__csr_hPBMTE       = csr_dup[6].hPBMTE;
  assign u_ptw__sfence_valid     = sfence_dup[7].valid;
  // hptw ← csr 7 / sfence 8
  assign u_hptw__csr_satp_changed = csr_dup[7].satp_changed;
  assign u_hptw__csr_vsatp_changed= csr_dup[7].vsatp_changed;
  assign u_hptw__csr_hgatp_mode   = csr_dup[7].hgatp_mode;
  assign u_hptw__csr_hgatp_vmid   = csr_dup[7].hgatp_vmid;
  assign u_hptw__csr_hgatp_ppn    = csr_dup[7].hgatp_ppn;
  assign u_hptw__csr_hgatp_changed= csr_dup[7].hgatp_changed;
  assign u_hptw__csr_mPBMTE       = csr_dup[7].mPBMTE;
  // hptw.sfence.valid ← sfence_dup[8]（golden sfence_dup_8_valid）。原实现漏此驱动 →
  // HPTW.sfence.valid 输入悬空、X 传染。
  assign u_hptw__sfence_valid     = sfence_dup[8].valid;

  // ==========================================================================
  // 2. ITLB/DTLB 请求计数与节流（tlbCounter）
  // --------------------------------------------------------------------------
  // 每拍：进入(各 tlb.req fire)计数 - 离开(各 tlb.resp fire)计数。flush 清零。
  // arb1.out 仅在 tlbCounter < MissQueueSize(=MEM_REQ_WIDTH*... 这里 40) 时放行，
  // 防止 miss queue 溢出。golden 阈值为 40（6'h28）。
  // ==========================================================================
  localparam int MISS_QUEUE_SIZE = 40;
  logic [5:0] tlb_counter;
  wire tlb0_req_fire = u_arb_tlb_in_0_ready & io_tlb_0_req_0_valid;
  wire tlb1_req_fire = u_arb_tlb_in_1_ready & io_tlb_1_req_0_valid;
  wire tlb0_resp_fire = io_tlb_0_resp_valid & io_tlb_0_resp_ready;
  // tlb_1 的 resp 通道在 golden 里 outArb_1.out.ready 恒 1（无 io_tlb_1_resp_ready 端口）。
  wire tlb1_resp_fire = io_tlb_1_resp_valid;
  wire [1:0] n_req  = {1'b0, tlb0_req_fire}  + {1'b0, tlb1_req_fire};
  wire [1:0] n_resp = {1'b0, tlb0_resp_fire} + {1'b0, tlb1_resp_fire};
  always_ff @(posedge clock or posedge reset) begin
    if (reset)      tlb_counter <= '0;
    else if (flush) tlb_counter <= '0;
    else            tlb_counter <= tlb_counter + {4'b0, n_req} - {4'b0, n_resp};
  end
  // arb1(=u_arb_tlb).out.ready = arb2.in(TLB).ready && tlbCounter < MissQueueSize
  assign u_arb_tlb__out_ready = u_arb_cache_in_in_3_ready & (tlb_counter < MISS_QUEUE_SIZE);

  // ==========================================================================
  // 8 前置：抓取常用的 cache resp 字段（命中/各级 hit/请求类型）。
  // ==========================================================================
  wire        cr_valid     = u_page_cache_resp_valid;
  wire        cr_hit       = u_page_cache_resp_bits_hit;
  wire        cr_isHptwReq = u_page_cache_resp_bits_isHptwReq;
  wire        cr_isFirst   = u_page_cache_resp_bits_isFirst;
  wire        cr_bypassed  = u_page_cache_resp_bits_bypassed;
  wire        cr_l1Hit     = u_page_cache_resp_bits_toFsm_l1Hit;
  wire        cr_stage1Hit = u_page_cache_resp_bits_toFsm_stage1Hit;
  wire [1:0]  cr_source    = u_page_cache_resp_bits_req_info_source;
  wire        cr_prefetch  = u_page_cache_resp_bits_prefetch;
  // from_pre(source==2)：golden 用 _mq_arb_io_in_0_valid_T_2 = (source==2'h2) 作「预取来源」
  // 判据（同时门控 mq_arb.in_0.valid 与 prefetch.in.valid）。source 为 2bit，可取值 2(=10b)，
  // 不能恒 0；否则 cache.resp.source==2 时 impl 仍放行 mq_arb/prefetch，与 golden 分叉
  // （missQueue.in / prefetch.in BBPin 失配）。
  wire        from_pre     = (cr_source == 2'h2);
  // toLLPTW（bitmap 关闭）恒 0。
  wire        toFsm_toLLPTW = 1'b0;

  // ==========================================================================
  // 3. page cache 入口仲裁(arb2)输入装配 + miss queue 仲裁(mq_arb)
  // --------------------------------------------------------------------------
  // arb2 五路输入：HPTW(0)/PTW(1)/MissQueue(2)/TLB(3)/Prefetch(4)。本核驱动：
  //   in(PTW).valid = ptw.llptw.valid（PTW 把叶级请求交给 LLPTW，经 cache 再分发）；
  //   in(TLB).valid = arb1.out.fire（arb1 选中的 ITLB/DTLB 请求），source=arb1.chosen；
  //   in(HPTW).valid = hptw_req_arb.out.valid；
  //   in(MissQueue) 经 block_decoupled：missQueue.out 受 isLLptw?~llptw.in.ready:~ptw.req.ready 阻塞。
  // mq_arb 两路：cache miss 需进 missQueue（0）/ llptw.cache（1）。
  // ==========================================================================
  // arb2.in(TLB)：source = {1'h0, arb1.chosen}
  assign u_arb_cache_in__in_3_valid = tlb0_req_fire | tlb1_req_fire; // arb1.out.fire
  assign u_arb_cache_in__in_3_bits_req_info_source = {1'b0, u_arb_tlb_chosen};

  // block_decoupled(missQueue.out → arb2.in(MQ)/in_2)：
  //   golden io_in_2_valid = _missQueue_io_out_valid & ~_GEN_2
  //          _GEN_2 = isLLptw ? ~llptw.in.ready : ~ptw.req.ready  (= mq_block)
  //   missQueue.out.ready = arb2.in_2.ready && ~mq_block。
  // 原实现误把 in_2.valid 接成 hptw_req_arb.out.valid（HPTW 已是 in_0），与 golden
  // 分叉（cache/missQueue 输入锥、io_tlb resp 全线失配）。in_2 是 MissQueue 路。
  wire mq_block = u_miss_queue_out_bits_isLLptw ? ~u_llptw_in_ready : ~u_ptw_req_ready;
  assign u_arb_cache_in__in_2_valid = u_miss_queue_out_valid & ~mq_block;
  assign u_miss_queue__out_ready = u_arb_cache_in_in_2_ready & ~mq_block;

  // arb2.out.ready = cache.req.ready
  // cache.req.valid = arb2.out.fire；cache.req.isFirst = (arb2.chosen != MQ && !isHptwReq)
  assign u_page_cache__req_valid = u_arb_cache_in_out_valid & u_page_cache_req_ready;
  assign u_page_cache__req_bits_isFirst =
      (u_arb_cache_in_chosen != IN_ARB_MQ[2:0]) & ~u_arb_cache_in_out_bits_isHptwReq;

  // mq_arb.in(0)：cache miss、非预取来源、非 hptwReq、且 (bypassed 或需进 PTW/LLPTW 但忙)
  wire mq0_cond_ptw  = ((~cr_l1Hit & ~toFsm_toLLPTW) | cr_stage1Hit)
                       & ~cr_isHptwReq & (cr_isFirst | ~u_ptw_req_ready);
  wire mq0_cond_llptw= (cr_l1Hit | toFsm_toLLPTW) & ~u_llptw_in_ready;
  assign u_arb_mq__in_0_valid = cr_valid & ~cr_hit & ~from_pre & ~cr_isHptwReq
                              & (cr_bypassed | mq0_cond_ptw | mq0_cond_llptw);
  // mq_arb.in(0).bits.isLLptw = cache.resp.toFsm.l1Hit | toLLPTW；isHptwReq=0
  // （这些 bits 在 inst.svh 直接连 cache.resp/常量；valid 这里给）。

  // hptw_req_arb.in(0)=PTW.hptw.req, in(1)=LLPTW.hptw.req；gvpn 装配（直通自子模块输出）
  assign u_arb_hptw_req__in_0_bits_gvpn = u_ptw_hptw_req_bits_gvpn;
  assign u_arb_hptw_req__in_1_bits_gvpn = u_llptw_hptw_req_bits_gvpn;

  // ==========================================================================
  // 4. PTW / LLPTW / HPTW 请求分发
  // --------------------------------------------------------------------------
  // 按 cache.resp 的命中情况把 miss 请求送往三个遍历器（Scala L2TLB.scala:278/317/340）：
  //   LLPTW.in.valid : miss & (toLLPTW|l1Hit) & !bypassed & !isHptwReq；ppn=toFsm.ppn
  //   PTW.req.valid  : miss & !l1Hit & !bypassed & !isFirst & !isHptwReq & !toLLPTW
  //   HPTW.req.valid : miss & isHptwReq
  // ==========================================================================
  assign u_llptw__in_valid = cr_valid & ~cr_hit
                           & (toFsm_toLLPTW | cr_l1Hit) & ~cr_bypassed & ~cr_isHptwReq;
  assign u_llptw__in_bits_ppn = {6'h0, u_page_cache_resp_bits_toFsm_ppn};

  assign u_ptw__req_valid = cr_valid & ~cr_hit & ~cr_l1Hit & ~cr_bypassed
                          & ~cr_isFirst & ~cr_isHptwReq & ~toFsm_toLLPTW;
  assign u_ptw__req_bits_ppn = {6'h0, u_page_cache_resp_bits_toFsm_ppn};

  assign u_hptw__req_valid = cr_valid & ~cr_hit & cr_isHptwReq;

  // ==========================================================================
  // 5. page cache resp.ready 多路选择
  // --------------------------------------------------------------------------
  // MuxCase（Scala L2TLB.scala:308）：按 hit/isHptwReq/toLLPTW/bypassed 决定 cache 何时
  // 能被消费。outReady(source,port) = mergeArb(source).in(port).ready。
  // ==========================================================================
  wire out_ready_cache_s = (cr_source == 2'h1) ? u_merge_arb_1_in_0_ready
                         : ((|cr_source) | u_merge_arb_0_in_0_ready);
  // hptw_resp_arb.in(CACHE).ready 在 golden 恒 1（out.ready=true、固定优先级仲裁）。
  assign u_page_cache__resp_ready =
      (~cr_hit & cr_isHptwReq) ? u_hptw_req_ready :
      (cr_hit & cr_isHptwReq)  ? 1'b1 :
      cr_hit                   ? out_ready_cache_s :
      ((toFsm_toLLPTW | cr_l1Hit) & ~cr_bypassed & u_llptw_in_ready) ? u_llptw_in_ready :
      (~(cr_bypassed | cr_isFirst) & u_ptw_req_ready) | u_arb_mq_in_0_ready;

  // ==========================================================================
  // 6. 访存数据通路（mem）
  // --------------------------------------------------------------------------
  // mem_arb 三路（PTW(0)/LLPTW(1)/HPTW(2)）仲裁后发往 TileLink A（读 64B PTE 块）。
  // D 通道：firstlastHelper 跟踪 beat，把 2 个 256bit beat 拼成 512bit refill_data；
  // waiting_resp[id] 跟踪在途、flush_latch[id] 记录 sfence 期间到的 resp 需丢弃。
  // resp_pte[id] 暂存每个 id 的 64bit PTE（PTW/HPTW 用），LLPTW 直接用 buffer_it 旁路。
  // ==========================================================================
  // mem_arb.out.ready = a.ready && !flush && !wfiReq
  wire wfi_req = u_wfi_req_delay_out;
  assign u_mem_arb__out_ready = auto_out_a_ready & ~flush & ~wfi_req;

  // -- TileLink A：发读请求 --
  wire mem_a_fire = u_mem_arb_out_valid & ~flush & ~wfi_req;
  assign auto_out_a_valid        = mem_a_fire;
  // 登记类寄存器(waiting_resp/req_addr_low/hptw_bypassed)用「握手」而非 valid：
  // golden _GEN_4 = auto_out_a_ready & ~flush & ~wfi & mem_arb_out_valid（即 fire&ready）。
  // 缺 a_ready 时 a_valid 拉高但对端未 ready 的拍会误登记，与 golden 分叉。
  wire mem_a_hs = mem_a_fire & auto_out_a_ready;
  assign auto_out_a_bits_source  = u_mem_arb_out_bits_id;
  assign auto_out_a_bits_address = {u_mem_arb_out_bits_addr[47:6], 6'h0}; // 64B 对齐

  // -- 在途跟踪 waiting_resp / flush_latch / req_addr_low / hptw_bypassed --
  logic [MEM_REQ_WIDTH-1:0] waiting_resp;
  logic [MEM_REQ_WIDTH-1:0] flush_latch;
  logic [2:0]               req_addr_low [MEM_REQ_WIDTH];
  logic                     hptw_bypassed;

  // -- D 通道 beat 跟踪（firstlastHelper：本配置每次 2 beat）--
  wire        d_valid   = auto_out_d_valid;
  wire [12:0] beats_dec = 13'h3F << auto_out_d_bits_size;
  wire        beats1    = auto_out_d_bits_opcode[0] & ~beats_dec[5]; // 多 beat（Grant 类）
  logic       beat_cnt;        // 0=首 beat,1=末 beat
  wire        cnt_m1    = beat_cnt - 1'b1;
  wire        mem_resp_done = (beat_cnt | ~beats1) & d_valid;   // 末 beat 到达
  wire        beat_idx  = beats1 & ~cnt_m1;                     // 当前 beat 写入下标(1=高半)
  // beat_cnt 更新对齐 golden refill_helper_counter：每个 d_valid 拍，若计数非 0 则减 1
  // （推进到末 beat），否则装载 beats1（多 beat 时下一拍进入末 beat）。原“随 beats1 累加”
  // 写法在多 beat 传输的末 beat（该拍 beats1 可能为 0）不减计数，导致 beat_cnt 与 golden
  // 计数错位，mem_resp_done/refill_valid 多发一拍，把 cache.io_req_ready 拉 0 与 golden 分叉。
  always_ff @(posedge clock or posedge reset) begin
    if (reset)        beat_cnt <= 1'b0;
    else if (d_valid) beat_cnt <= beat_cnt ? (beat_cnt - 1'b1) : beats1;
  end

  wire [MEM_ID_W-1:0] d_src = auto_out_d_bits_source;
  wire mem_resp_from_llptw = (d_src[2:1] != 2'h3);             // id 0..5
  wire mem_resp_from_ptw   = (d_src == PTW_MEM_ID[2:0]);       // id 6
  wire mem_resp_from_hptw  = (&d_src);                         // id 7

  // refill_data：2 个 256bit beat。当前拍把 d_bits_data 写入 beat_idx 选中半。
  logic [L1_BUS_DATA_W-1:0] refill_data [BEATS];
  for (genvar b = 0; b < BEATS; b++) begin : g_refill_data
    always_ff @(posedge clock or posedge reset)
      if (reset)                          refill_data[b] <= '0;
      else if (d_valid && (beat_idx == b[0])) refill_data[b] <= auto_out_d_bits_data;
  end
  // refill_data_tmp：当拍旁路（比寄存器早一拍），用于 ptw/hptw 取 PTE。
  logic [BLOCK_BITS-1:0] refill_data_tmp;
  always_comb begin
    for (int b = 0; b < BEATS; b++)
      refill_data_tmp[b*L1_BUS_DATA_W +: L1_BUS_DATA_W] =
        (beat_idx == b[0]) ? auto_out_d_bits_data : refill_data[b];
  end
  wire [BLOCK_BITS-1:0] refill_data_flat = {refill_data[1], refill_data[0]};

  // resp_pte：PTW(id6)/HPTW(id7) 各暂存一个 64bit PTE。复位清 0（与 golden RegEnable 0.U 一致）。
  logic [63:0] resp_pte_ptw, resp_pte_hptw;
  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      resp_pte_ptw  <= '0;
      resp_pte_hptw <= '0;
    end else begin
      if (mem_resp_done & mem_resp_from_ptw)
        resp_pte_ptw  <= get_part(refill_data_tmp, req_addr_low[PTW_MEM_ID]);
      if (mem_resp_done & mem_resp_from_hptw)
        resp_pte_hptw <= get_part(refill_data_tmp, req_addr_low[HPTW_MEM_ID]);
    end
  end

  // resp_pte_sector：LLPTW 各 id 暂存 512bit 块（buffer_it 时旁路当拍 refill_data）。
  // 复位清 0（与 golden RegEnable 0.U 一致），否则未写时为 X 会污染 s1 合并路径。
  // 阵列扩到 8 项：golden 的出口读表实打实含 id6(PTW)/id7(HPTW) 两项（在
  //  ptw/hptw resp 时用**当拍旁路**的 refill_data_tmp 写入），3 位下标读不折叠。
  logic [BLOCK_BITS-1:0] resp_pte_sector [MEM_REQ_WIDTH];
  wire [LLPTW_SIZE-1:0] llptw_buffer_it = {u_llptw_mem_buffer_it_5, u_llptw_mem_buffer_it_4,
      u_llptw_mem_buffer_it_3, u_llptw_mem_buffer_it_2, u_llptw_mem_buffer_it_1,
      u_llptw_mem_buffer_it_0};
  for (genvar i = 0; i < LLPTW_SIZE; i++) begin : g_resp_sector
    always_ff @(posedge clock or posedge reset)
      if (reset)                  resp_pte_sector[i] <= '0;
      else if (llptw_buffer_it[i]) resp_pte_sector[i] <= refill_data_flat;
  end
  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      resp_pte_sector[PTW_MEM_ID]  <= '0;
      resp_pte_sector[HPTW_MEM_ID] <= '0;
    end else begin
      if (mem_resp_done & mem_resp_from_ptw)  resp_pte_sector[PTW_MEM_ID]  <= refill_data_tmp;
      if (mem_resp_done & mem_resp_from_hptw) resp_pte_sector[HPTW_MEM_ID] <= refill_data_tmp;
    end
  end
  // LLPTW 出口选中的块：id 0..5 在 buffer_it 时取当拍 refill_data，否则取暂存；
  // id 6/7 直接取暂存（golden 读表同构；id 越界位选会产生 X，须显式建表）。
  logic [BLOCK_BITS-1:0] sector_rd_tbl [MEM_REQ_WIDTH];
  always_comb begin
    for (int i = 0; i < LLPTW_SIZE; i++)
      sector_rd_tbl[i] = llptw_buffer_it[i] ? refill_data_flat : resp_pte_sector[i];
    sector_rd_tbl[PTW_MEM_ID]  = resp_pte_sector[PTW_MEM_ID];
    sector_rd_tbl[HPTW_MEM_ID] = resp_pte_sector[HPTW_MEM_ID];
  end
  wire [BLOCK_BITS-1:0] llptw_out_blk = sector_rd_tbl[u_llptw_out_bits_id];

  // -- mem_arb fire 时登记 req_addr_low / waiting_resp / hptw_bypassed --
  // llptw enq 时也登记 req_addr_low（来自 vpn）。
  always_ff @(posedge clock or posedge reset) begin
    // 复位清 0：对齐 golden（hptw_bypassed <= 1'h0）。缺失复位会让 hptw_bypassed 上电为
    // X，当首个 HPTW resp（d_src==7）在任何 HPTW req 登记之前到达时，
    // refill_valid = … & ~(mem_resp_from_hptw & hptw_bypassed) 变 X，
    // 经 cache.refill→stageReq_ready→io_req_ready / perf 把 X 传到顶层输出（约 645 拍首现）。
    if (reset) begin
      hptw_bypassed <= 1'b0;
    end else begin
      if (mem_a_hs)
        hptw_bypassed <= (u_mem_arb_out_bits_id == HPTW_MEM_ID[2:0]) & u_mem_arb_out_bits_hptw_bypassed;
    end
  end
  // req_addr_low：golden 为无复位寄存器（clock-only 块），不能挂在 reset 门控分支下
  // （否则复位期间的登记被吞掉，与 golden 分叉——SQ/LQR/Ftq 同型复位域问题）。
  always_ff @(posedge clock) begin
    if (u_llptw_in_ready & u_llptw__in_valid)
      req_addr_low[u_llptw_mem_enq_ptr] <= addr_low_from_vpn(u_page_cache_resp_bits_req_info_vpn);
    if (mem_a_hs)
      req_addr_low[u_mem_arb_out_bits_id] <= addr_low_from_paddr(u_mem_arb_out_bits_addr);
  end
  for (genvar i = 0; i < MEM_REQ_WIDTH; i++) begin : g_waiting
    // golden 语义: next = ~clear & (set | old)（清位优先, 与置位同拍时清位赢）。
    //   waiting_resp_i <= ~_GEN_406_i & (_GEN_5_i        | waiting_resp_i)
    //   flush_latch_i  <= ~_GEN_406_i & (flush&waiting_i | flush_latch_i)
    // 其中 set = mem_arb fire & id==i, clear = mem_resp_done & d_src==i。
    // 原 if-else 给「置位」优先 → 与 golden 分叉（waiting_resp/flush_latch 各 8 failing）。
    wire wr_set   = mem_a_hs      && (u_mem_arb_out_bits_id == i[MEM_ID_W-1:0]);
    wire wr_clear = mem_resp_done && (d_src               == i[MEM_ID_W-1:0]);
    always_ff @(posedge clock or posedge reset) begin
      if (reset) begin
        waiting_resp[i] <= 1'b0;
        flush_latch[i]  <= 1'b0;
      end else begin
        waiting_resp[i] <= ~wr_clear & (wr_set                    | waiting_resp[i]);
        flush_latch[i]  <= ~wr_clear & ((flush & waiting_resp[i]) | flush_latch[i]);
      end
    end
  end

  // -- mem resp 分发到 llptw / ptw / hptw --
  assign u_llptw__mem_resp_valid     = mem_resp_done & mem_resp_from_llptw;
  // golden 对 llptw.mem.resp.id 用 holdUnless(d_valid) 寄存（llptw_io_mem_resp_bits_id_r）；
  // 镜像该保持寄存器（resp_valid 时 d_valid 恒 1，行为等价），FM 可配平。
  logic [MEM_ID_W-1:0] llptw_resp_id_r;
  logic [BLOCK_BITS-1:0] llptw_resp_value_r;   // 同为 holdUnless(d_valid)、无复位
  always_ff @(posedge clock) if (d_valid) begin
    llptw_resp_id_r    <= auto_out_d_bits_source;
    llptw_resp_value_r <= refill_data_tmp;
  end
  assign u_llptw__mem_resp_bits_id   = d_valid ? d_src : llptw_resp_id_r;
  assign u_llptw__mem_resp_bits_value= d_valid ? refill_data_tmp : llptw_resp_value_r;
  assign u_ptw__mem_resp_valid       = mem_resp_done & mem_resp_from_ptw;
  assign u_ptw__mem_resp_bits        = resp_pte_ptw;
  assign u_ptw__mem_mask             = waiting_resp[PTW_MEM_ID];
  assign u_hptw__mem_resp_valid      = mem_resp_done & mem_resp_from_hptw;
  assign u_hptw__mem_resp_bits       = resp_pte_hptw;
  assign u_hptw__mem_mask            = waiting_resp[HPTW_MEM_ID];
  // llptw mem mask / flush_latch（低 6 路）
  logic [LLPTW_SIZE-1:0] llptw_mem_req_mask, llptw_mem_flush_latch;
  for (genvar i = 0; i < LLPTW_SIZE; i++) begin : g_llptw_mem
    assign llptw_mem_req_mask[i]    = waiting_resp[i];
    assign llptw_mem_flush_latch[i] = flush_latch[i];
  end
  assign u_llptw__mem_req_mask_0 = llptw_mem_req_mask[0];
  assign u_llptw__mem_req_mask_1 = llptw_mem_req_mask[1];
  assign u_llptw__mem_req_mask_2 = llptw_mem_req_mask[2];
  assign u_llptw__mem_req_mask_3 = llptw_mem_req_mask[3];
  assign u_llptw__mem_req_mask_4 = llptw_mem_req_mask[4];
  assign u_llptw__mem_req_mask_5 = llptw_mem_req_mask[5];
  assign u_llptw__mem_flush_latch_0 = llptw_mem_flush_latch[0];
  assign u_llptw__mem_flush_latch_1 = llptw_mem_flush_latch[1];
  assign u_llptw__mem_flush_latch_2 = llptw_mem_flush_latch[2];
  assign u_llptw__mem_flush_latch_3 = llptw_mem_flush_latch[3];
  assign u_llptw__mem_flush_latch_4 = llptw_mem_flush_latch[4];
  assign u_llptw__mem_flush_latch_5 = llptw_mem_flush_latch[5];

  // wfi：DelayN(wfiReq && !any waiting,1)。
  // io_wfi_wfiSafe 由 u_wfi_safe_delay 实例的 .io_out 直接驱动（inst.svh），此处不能再
  // assign（否则 io_wfi_wfiSafe 多驱动、u_wfi_safe_delay_out 悬空）。
  assign u_wfi_safe_delay__in = wfi_req & ~(|waiting_resp);
  assign auto_out_d_ready     = 1'b1;

  // ==========================================================================
  // 6b. cache.refill 装配
  // --------------------------------------------------------------------------
  // refill 在 mem resp 完成、非 flush、非 flush_latch、非(hptw 且 bypassed) 时有效，
  // 打一拍后给 cache.refill.valid。bits 在 refill_valid 时锁存（req_info/level/ptes/sel_pte）。
  // refill_level：llptw→0；ptw→RegEnable(ptw.refill.level)；hptw→RegEnable(hptw.refill.level)。
  // ==========================================================================
  // golden refill_level_r/refill_level_r_1 有复位到 0（reg 在 reset 分支置 2'h0）；
  // 照搬 bug-for-bug，否则 impl 无复位的 next-state 锥与 golden 不等价（FM failing）。
  logic [1:0] ptw_refill_level_r, hptw_refill_level_r;
  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      ptw_refill_level_r  <= 2'h0;
      hptw_refill_level_r <= 2'h0;
    end else begin
      if (u_ptw_mem_req_valid & u_mem_arb_in_0_ready)  ptw_refill_level_r  <= u_ptw_refill_level;
      if (u_hptw_mem_req_valid & u_mem_arb_in_2_ready) hptw_refill_level_r <= u_hptw_refill_level;
    end
  end
  wire [1:0] refill_level = mem_resp_from_llptw ? 2'h0
                          : mem_resp_from_ptw   ? ptw_refill_level_r : hptw_refill_level_r;
  wire refill_valid = mem_resp_done & ~flush & ~flush_latch[d_src]
                    & ~(mem_resp_from_hptw & hptw_bypassed);
  logic refill_valid_d;
  // 复位清 0：对齐 golden cache_io_refill_valid_last_REG（复位 1'h0）。缺失复位会让
  // refill_valid_d 上电为 X，经 cache.io_refill_valid→stageReq_ready→io_req_ready 把
  // X 传到 tlb_*_req_0_ready / perf 计数，造成与 golden 的残留分叉。
  always_ff @(posedge clock or posedge reset) begin
    if (reset) refill_valid_d <= 1'b0;
    else       refill_valid_d <= refill_valid;
  end
  assign u_page_cache__refill_valid     = refill_valid_d;
  assign u_page_cache__refill_bits_ptes = refill_data_flat;
  // req_info：llptw.mem.refill / ptw.refill.req_info / hptw.refill.req_info 三选一，refill_valid 锁存
  ptw_req_info_t refill_req_info_sel;
  always_comb begin
    if (mem_resp_from_llptw)
      refill_req_info_sel = '{vpn: u_llptw_mem_refill_vpn, s2xlate: u_llptw_mem_refill_s2xlate,
                              source: u_llptw_mem_refill_source};
    else if (mem_resp_from_ptw)
      refill_req_info_sel = '{vpn: u_ptw_refill_req_info_vpn, s2xlate: u_ptw_refill_req_info_s2xlate,
                              source: u_ptw_refill_req_info_source};
    else
      refill_req_info_sel = '{vpn: u_hptw_refill_req_info_vpn, s2xlate: 2'h2 /*onlyStage2*/,
                              source: u_hptw_refill_req_info_source};
  end
  // golden 为 cache.refill 各 dup 端口各保留一份锁存副本（req_info×3 / level×2 /
  // sel_pte×2，同值同使能）。1:1 镜像以便 FM 配平；行为与单份完全一致。
  ptw_req_info_t refill_req_info_r [3];
  logic [1:0]    refill_level_r   [2];
  logic [63:0]   refill_sel_pte_r [2];
  always_ff @(posedge clock) if (refill_valid) begin
    for (int j = 0; j < 3; j++) refill_req_info_r[j] <= refill_req_info_sel;
    for (int j = 0; j < 2; j++) begin
      refill_level_r[j]   <= refill_level;
      refill_sel_pte_r[j] <= get_part(refill_data_tmp, req_addr_low[d_src]); // sel_data
    end
  end
  assign u_page_cache__refill_bits_req_info_dup_0_vpn     = refill_req_info_r[0].vpn;
  assign u_page_cache__refill_bits_req_info_dup_0_s2xlate = refill_req_info_r[0].s2xlate;
  assign u_page_cache__refill_bits_req_info_dup_0_source  = refill_req_info_r[0].source;
  assign u_page_cache__refill_bits_req_info_dup_1_vpn     = refill_req_info_r[1].vpn;
  assign u_page_cache__refill_bits_req_info_dup_1_s2xlate = refill_req_info_r[1].s2xlate;
  assign u_page_cache__refill_bits_req_info_dup_1_source  = refill_req_info_r[1].source;
  assign u_page_cache__refill_bits_req_info_dup_2_vpn     = refill_req_info_r[2].vpn;
  assign u_page_cache__refill_bits_req_info_dup_2_s2xlate = refill_req_info_r[2].s2xlate;
  assign u_page_cache__refill_bits_req_info_dup_2_source  = refill_req_info_r[2].source;
  assign u_page_cache__refill_bits_level_dup_0 = refill_level_r[0];
  assign u_page_cache__refill_bits_level_dup_2 = refill_level_r[1];
  assign u_page_cache__refill_bits_sel_pte_dup_0 = refill_sel_pte_r[0];
  assign u_page_cache__refill_bits_sel_pte_dup_2 = refill_sel_pte_r[1];
  // levelOH(level, refill_valid)：one-hot 打一拍。level 0..3 + sp（superpage 用 level==1?）
  // Chisel levelOH：sp = (level==3) 等价；这里按 golden 的 5 路独热（l0..l3 + sp）。
  // golden 每拍无条件赋 (cond & refill_valid)（非 refill 拍归 0，非「保持」），且有复位到 0。
  // 原用 `if (refill_valid)` 作写使能会在非 refill 拍保持旧值，与 golden 分叉（FM failing）。
  logic lvOH_sp_r, lvOH_l0_r, lvOH_l1_r, lvOH_l2_r, lvOH_l3_r;
  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      lvOH_l0_r <= 1'b0; lvOH_l1_r <= 1'b0; lvOH_l2_r <= 1'b0;
      lvOH_l3_r <= 1'b0; lvOH_sp_r <= 1'b0;
    end else begin
      lvOH_l0_r <= (refill_level == 2'h0) & refill_valid;
      lvOH_l1_r <= (refill_level == 2'h1) & refill_valid;
      lvOH_l2_r <= (refill_level == 2'h2) & refill_valid;
      lvOH_l3_r <= (refill_level == 2'h3) & refill_valid;
      lvOH_sp_r <= (refill_level != 2'h0) & refill_valid;
    end
  end
  assign u_page_cache__refill_bits_levelOH_l0 = lvOH_l0_r;
  assign u_page_cache__refill_bits_levelOH_l1 = lvOH_l1_r;
  assign u_page_cache__refill_bits_levelOH_l2 = lvOH_l2_r;
  assign u_page_cache__refill_bits_levelOH_l3 = lvOH_l3_r;
  assign u_page_cache__refill_bits_levelOH_sp = lvOH_sp_r;

  // ==========================================================================
  // 7. HPTW 响应分发（hptw_resp_arb：cache hit 的 hptw 响应(0) / hptw.resp(1)）
  // --------------------------------------------------------------------------
  // 仲裁后按 id 分发：id==FsmReqID → PTW.hptw.resp；否则 → LLPTW.hptw.resp。
  // ==========================================================================
  assign u_arb_hptw_resp__in_0_valid = cr_valid & cr_hit & cr_isHptwReq;
  wire hresp_to_ptw = (u_arb_hptw_resp_out_bits_id == FSM_REQ_ID[2:0]);
  assign u_ptw__hptw_resp_valid   = u_arb_hptw_resp_out_valid &  hresp_to_ptw;
  assign u_llptw__hptw_resp_valid = u_arb_hptw_resp_out_valid & ~hresp_to_ptw;

  // ==========================================================================
  // 8. 输出合并：mergeArb 三路 + outArb → ITLB/DTLB resp
  // --------------------------------------------------------------------------
  // 每条 PtwWidth 各一组 mergeArb(3)+outArb(1)：
  //   in(CACHE).valid = cache hit & source==i & !isHptwReq；s1=cache.stage1, s2=cache.toHptw.resp
  //   in(FSM).valid   = ptw.resp.valid & source==i；s1=ptw.resp.resp, s2=ptw.resp.h_resp
  //   in(MQ).valid    = llptw.out.valid & source==i；
  //       s1 = first_s2xlate_fault ? llptw_stage1 : contiguous_pte_to_merge(llptw_out_blk,...)
  //       s2 = llptw.out.h_resp
  // outArb.in(0).s1 = merge_to_sector(mergeArb.out.s1)。outArb.out → io.tlb(i).resp。
  // cache(in0)/ptw(in1) 的 bits 在 inst.svh 直通子模块输出；本核驱动 valid 与 in2 bits。
  // ==========================================================================
  // -- llptw_stage1：llptw.in.fire 时按 enq_ptr 锁存 cache.resp.stage1（merge resp）--
  //    用于 first_s2xlate_fault 时回放 stage1。本配置仅记录顶层需要的字段。
  //   golden 的 s1.entry.*.af 恒被门控为 0（_GEN_281 = ~first_s2xlate_fault & ...），stage1
  //   回放路径根本不取 af，故 golden 的 llptw_stage1 里没有 af 寄存器。为逐位对齐，本核
  //   把 llptw_stage1 的存储类型换成【不含 af 的 merge resp】(ptw_merge_resp_noaf_t)，读出时
  //   用 mrg_from_noaf() 拼回完整类型并把 entry.af 钉 0——af 不成为触发器（无 impl-only 寄存器）。
  ptw_merge_resp_noaf_t llptw_stage1_q [LLPTW_SIZE];
  // cache.resp.stage1 打包为 ptw_merge_resp_t
  ptw_merge_resp_t cache_stage1;
  `include "L2TLB_cache_stage1.svh"  // 装配 cache_stage1（从 u_page_cache_resp_bits_stage1_*）
  // 完整读出视图（entry.af 恒 0，与 golden 门控一致）。
  ptw_merge_resp_t llptw_stage1 [LLPTW_SIZE];
  for (genvar i = 0; i < LLPTW_SIZE; i++) begin : g_stage1_rd
    assign llptw_stage1[i] = mrg_from_noaf(llptw_stage1_q[i]);
  end
  for (genvar i = 0; i < LLPTW_SIZE; i++) begin : g_llptw_stage1
    // golden 无复位（always @(posedge clock) 纯 enable 锁存）；照搬 bug-for-bug。
    always_ff @(posedge clock)
      if ((u_llptw_in_ready & u_llptw__in_valid) && (u_llptw_mem_enq_ptr == i[2:0]))
        llptw_stage1_q[i] <= mrg_to_noaf(cache_stage1);
  end

  // -- mergeArb 各路 valid（per tlb i）--
  wire [1:0] llptw_out_src = u_llptw_out_bits_req_info_source;
  // in(MQ).valid = llptw.out.valid & source==i
  assign u_merge_arb_0__in_2_valid = u_llptw_out_valid & (llptw_out_src == 2'h0);
  assign u_merge_arb_1__in_2_valid = u_llptw_out_valid & (llptw_out_src == 2'h1);
  // in(FSM).valid = ptw.resp.valid & source==i（in_1）
  assign u_merge_arb_0__in_1_valid = u_ptw_resp_valid & (u_ptw_resp_bits_source == 2'h0);
  assign u_merge_arb_1__in_1_valid = u_ptw_resp_valid & (u_ptw_resp_bits_source == 2'h1);
  // in(CACHE).valid = cache hit & source==i & !isHptwReq（in_0）
  assign u_merge_arb_0__in_0_valid = cr_valid & cr_hit & (cr_source == 2'h0) & ~cr_isHptwReq;
  assign u_merge_arb_1__in_0_valid = cr_valid & cr_hit & (cr_source == 2'h1) & ~cr_isHptwReq;

  // ptw.resp.ready：golden 按 resp.source 选对应 mergeArb 的 in_1.ready；
  //   source==1 → mergeArb_1.in_1.ready；否则 (|source) | mergeArb_0.in_1.ready。
  // （in_1 是 FSM/PTW 路。原实现漏驱动此输入 → PTW 内部 resp 握手悬空、X 传染顶层。）
  assign u_ptw__resp_ready = (u_ptw_resp_bits_source == 2'h1)
                           ? u_merge_arb_1_in_1_ready
                           : ((|u_ptw_resp_bits_source) | u_merge_arb_0_in_1_ready);

  // -- in(MQ).bits.s1 = contiguous_pte_to_merge(...) 或 llptw_stage1（first_s2xlate_fault）--
  ptw_merge_resp_t mq_s1;
  wire [1:0] llptw_out_s2x = u_llptw_out_bits_req_info_s2xlate;
  // llptw id 是 3bit(0..7) 但 llptw_stage1 只有 LLPTW_SIZE(=6) 项。golden 的选择数组
  // _GEN_21[id]（8 项 concat）把 id>=6 回绕到 stage1[0]（id 6,7 两项均取 llptw_stage1_0），
  // 0..5 直取 [id]。用「显式 8 路 mux」而非 llptw_stage1[id]：后者让 FM 对 6 项数组按 3bit
  // 下标建 mux，无法证明 6/7 不可达 → fm_mux 对 6/7 推 X 传染 valididx（假分叉）。8 路显式
  // 映射(6,7→[0])两侧全定义、与 golden _GEN_21 回绕完全一致。
  ptw_merge_resp_t llptw_stage1_sel_s;
  always_comb begin
    unique case (u_llptw_out_bits_id)
      3'd0:    llptw_stage1_sel_s = llptw_stage1[0];
      3'd1:    llptw_stage1_sel_s = llptw_stage1[1];
      3'd2:    llptw_stage1_sel_s = llptw_stage1[2];
      3'd3:    llptw_stage1_sel_s = llptw_stage1[3];
      3'd4:    llptw_stage1_sel_s = llptw_stage1[4];
      3'd5:    llptw_stage1_sel_s = llptw_stage1[5];
      default: llptw_stage1_sel_s = llptw_stage1[0]; // id 6,7 回绕到 stage1[0]（对齐 golden）
    endcase
  end
  always_comb begin
    if (u_llptw_out_bits_first_s2xlate_fault)
      mq_s1 = llptw_stage1_sel_s;
    else
      mq_s1 = contiguous_pte_to_merge(
        llptw_out_blk, u_llptw_out_bits_req_info_vpn, u_llptw_out_bits_af, llptw_out_s2x,
        csr_dup[0].mPBMTE, csr_dup[0].hPBMTE,
        csr_dup[0].satp_asid, csr_dup[0].vsatp_asid, csr_dup[0].hgatp_vmid);
  end
  // 注：llptw_stage1 的 entry.af 由 mrg_from_noaf 恒钉 0（存储侧不含 af），与 golden 的
  //   _GEN_281 门控（stage1 回放 af 恒 0）一致，故 mq_s1 在 fault 路径的 af 自然为 0。
  // 把 mq_s1 拆给两条 mergeArb 的 in_2 s1 字段（per-entry）。
  `include "L2TLB_merge_in2.svh"

  // -- outArb.in(0).s1 = merge_to_sector(mergeArb.out.s1)（per tlb i）--
  //    mergeArb.out.s1 是 ptw_merge_resp_t；not_merge 取 mergeArb 输出的 s1.not_merge
  //    字段（= ~in0.valid & ~in1.valid & in2.not_merge，即仅 llptw 路胜出且 s2xlate!=0 时
  //    才不合并；cache/ptw 路胜出恒合并）。原用 (out.s2xlate!=0) 作 not_merge 与 golden 分叉
  //    （cache/ptw 路 s2xlate!=0 时误判 not_merge=1 → valididx 全线失配）。
  ptw_merge_resp_t marb0_out_s1, marb1_out_s1;
  `include "L2TLB_marb_out.svh"   // 从 u_merge_arb_N_out_bits_s1_* 装配 marbN_out_s1
  sector_resp_t sec0, sec1;
  assign sec0 = merge_to_sector(marb0_out_s1, u_merge_arb_0_out_bits_s1_not_merge);
  assign sec1 = merge_to_sector(marb1_out_s1, u_merge_arb_1_out_bits_s1_not_merge);
  `include "L2TLB_outarb_in.svh"  // 把 sec0/sec1 拆给 outArb 的 in_0 s1 字段

  // outArb.out.ready：outArb_0 直连 io_tlb_0_resp_ready；outArb_1 在 golden 里恒 1（inst.svh）。
  // llptw.out.ready = source==1 ? mergeArb_1.in_2.ready : (|source) | mergeArb_0.in_2.ready。
  // else 分支的 (|source) 项不能省：source∈{2,3} 时 golden 恒 ready=1（与 ptw.resp.ready 同型）。
  assign u_llptw__out_ready = (llptw_out_src == 2'h1) ? u_merge_arb_1_in_2_ready
                                                      : ((|llptw_out_src) | u_merge_arb_0_in_2_ready);

  // io.tlb resp valid（outArb.out.valid 直接驱动；inst.svh 已连 io_tlb_*_resp_valid）

  // ==========================================================================
  // 9. PMP checker 请求装配 + prefetch 触发
  // --------------------------------------------------------------------------
  // 3 个 PMPChecker：ptw(0)/llptw(1)/hptw(2)。check_env.mode=ModeS(=1)，cmd=read(=0)。
  // prefetch.in.valid = cache.resp.fire & !from_pre & (!hit||prefetched) & isFirst。
  // ==========================================================================
  assign u_pmp_chk_ptw__check_env_mode   = 2'h1; // ModeS
  assign u_pmp_chk_llptw__check_env_mode = 2'h1;
  assign u_pmp_chk_hptw__check_env_mode  = 2'h1;
  assign u_pmp_chk_ptw__req_bits_cmd     = 3'h0; // read
  assign u_pmp_chk_llptw__req_bits_cmd   = 3'h0;
  assign u_pmp_chk_hptw__req_bits_cmd    = 3'h0;

  wire cache_resp_fire = cr_valid & u_page_cache__resp_ready;
  assign u_prefetch__in_valid = cache_resp_fire & ~from_pre & (~cr_hit | cr_prefetch) & cr_isFirst;

  // ==========================================================================
  // 10. 顶层输出直驱（req.ready / resp.valid / resp.s1.af）
  // --------------------------------------------------------------------------
  // arb1.in(i).ready → io.tlb(i).req.ready；outArb(i).out → io.tlb(i).resp。
  // resp 的其余 bits 在 inst.svh 由 outArb 输出端口直连顶层；这里补 valid/req_ready/af。
  // ==========================================================================
  assign io_tlb_0_req_0_ready  = u_arb_tlb_in_0_ready;
  assign io_tlb_1_req_0_ready  = u_arb_tlb_in_1_ready;
  assign io_tlb_0_resp_valid   = u_out_arb_0_out_valid;
  assign io_tlb_1_resp_valid   = u_out_arb_1_out_valid;
  assign io_tlb_0_resp_bits_s1_af = u_out_arb_0_out_bits_s1_af;
  assign io_tlb_1_resp_bits_s1_af = u_out_arb_1_out_bits_s1_af;

  // ==========================================================================
  // 11. 性能事件（perf）两级打拍
  // --------------------------------------------------------------------------
  // 19 路性能计数：0..3←LLPTW，4..11←PtwCache，12..18←PTW。各打两拍对齐输出，
  // 降低长扇出对时序影响（与 Scala HasPerfEvents 的两级寄存器一致）。
  // ==========================================================================
  logic [5:0] perf_src [PERF_NUM];
  assign perf_src[0]  = u_llptw_perf_0_value;
  assign perf_src[1]  = u_llptw_perf_1_value;
  assign perf_src[2]  = u_llptw_perf_2_value;
  assign perf_src[3]  = u_llptw_perf_3_value;
  assign perf_src[4]  = u_page_cache_perf_0_value;
  assign perf_src[5]  = u_page_cache_perf_1_value;
  assign perf_src[6]  = u_page_cache_perf_2_value;
  assign perf_src[7]  = u_page_cache_perf_3_value;
  assign perf_src[8]  = u_page_cache_perf_4_value;
  assign perf_src[9]  = u_page_cache_perf_5_value;
  assign perf_src[10] = u_page_cache_perf_6_value;
  assign perf_src[11] = u_page_cache_perf_7_value;
  assign perf_src[12] = u_ptw_perf_0_value;
  assign perf_src[13] = u_ptw_perf_1_value;
  assign perf_src[14] = u_ptw_perf_2_value;
  assign perf_src[15] = u_ptw_perf_3_value;
  assign perf_src[16] = u_ptw_perf_4_value;
  assign perf_src[17] = u_ptw_perf_5_value;
  assign perf_src[18] = u_ptw_perf_6_value;
  logic [5:0] perf_s1 [PERF_NUM], perf_s2 [PERF_NUM];
  for (genvar i = 0; i < PERF_NUM; i++) begin : g_perf
    always_ff @(posedge clock) begin
      perf_s1[i] <= perf_src[i];
      perf_s2[i] <= perf_s1[i];
    end
  end
  `include "L2TLB_perf_out.svh"  // assign io_perf_<i>_value = perf_s2[i];

  // ==========================================================================
  // 子模块实例（与 golden 完全一致；黑盒）。
  // ==========================================================================
  `include "L2TLB_inst.svh"

endmodule
