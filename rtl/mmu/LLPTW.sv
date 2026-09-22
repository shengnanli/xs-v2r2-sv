// LLPTW.sv —— 末级页表走表器（Last Level Page Table Walker）：6 个条目并发处理
// "只差最后一级（level 0）"的页表访问，把 PTW 送来的 l1 级 ppn 变成一条访存请求，
// 回填 PtwCache，并在两阶段翻译下串行地向 HPTW 借力。
//
// 本文件含：xs_llptw_pkg（私有类型）+ xs_LLPTW_core（可读重写核）+ LLPTW（golden 同名 wrapper，163 端口）。
// 共享 PTE 判定函数来自 rtl/mmu/mmu_common_pkg.sv 的 xs_mmu_common_pkg。
// 对应 Chisel: xiangshan.cache.mmu.LLPTW（PageTableWalker.scala 第 711 行起）；
// 对照 golden = G1-canonical/golden-rtl/LLPTW.sv（5293 行，单变体；其中约 4900 行是 6 个条目 × 43 个
// 字段的展平 + 5 个仲裁器的输入装配）。
//
// 【它在 L2TLB 里的位置】
//   PTW 走到 level 1（找到指向最后一级页表的 PDE）就把请求丢给本模块（io.in），自己去接
//   下一个请求；本模块给每个请求分配一个条目，读 8 个相邻 PTE（一个 64B 块 = tlbcontiguous
//   扇区），结果经 io.out 回 L2TLB 合并成 sector 响应，同时 io.mem.refill 告诉 L2TLB
//   这个块该回填 PtwCache 的哪个 vpn。两阶段翻译（allStage）时最后一级 PTE 的地址是客户机
//   物理地址，要先经 HPTW 翻译（hptw_req/resp），读回的叶子 PTE 再翻一次
//   （last_hptw_req/resp）。bitmap 检查打开时叶子还要过一遍 Bitmap（bitmap_check/resp）。
//
// 【条目状态机（Chisel Enum(12)，编码照抄）】
//   0 idle → 3 addr_check（下一拍查 PMP）→ 4 mem_req（等 mem_arb 选中）→ 5 mem_waiting（等访存回来）
//     → 6 mem_out（等 io.out 接走）
//   allStage：idle → 1 hptw_req → 2 hptw_resp → 3 addr_check → … → 5 mem_waiting
//             → 7 last_hptw_req → 8 last_hptw_resp → 6 mem_out
//   bitmap：  5 mem_waiting → 10 bitmap_check → 11 bitmap_resp → 6 mem_out
//   9 cache：入队时发现同 vpn 的条目数据刚回来/正在做 bitmap/正在做最后一级翻译，
//            本条目不再访存，改成回 PtwCache 重查（io.cache）。
//
// 【入队去重（§5）】同 vpn[37:3]（同一扇区）且同 s2xlate 的请求：
//   · 已有条目在 mem_waiting（或本拍正被 mem_arb 发出）→ 本条目也进 mem_waiting，wait_id 指向它；
//   · 本拍访存响应正好是那个扇区（dup_wait_resp）→ 直接拿数据进 mem_out / bitmap_check / last_hptw_req；
//   · 已有条目在 mem_out / bitmap / last_hptw → 进 cache 状态。
//   预取（source==2）如果不需要真正访存就直接丢弃（enq_state=idle）。
//
// 【访存响应广播（§8）】io.mem.resp 带 id（发请求的条目号），所有 mem_waiting 且 wait_id==id
//   的条目同时拿到数据，各自用自己的 vpn[2:0] 挑出 8 条 PTE 里的那一条判 pf/gpf。
//
// 【★golden 的 Vec 越界语义（§4）★】entries(id) / state(id) 里 id 是 3 位而条目只有 6 个，
//   firtool 把下标 6/7 展成读**条目 0**。io_mem_resp_bits_id / io_hptw_resp_bits_id /
//   wait_id / mem_refill_id / hptw_resp_ptr_reg 都走这条规则，照抄。
//
// 【复位域（golden 实测）】
//   异步复位：6 条目全部字段（RegInit 0）、state×6、REG（断言用 RegNext，见 §9 末）、
//   mem_resp_hit×6、need_addr_check_last_REG。
//   不复位：enq_ptr_reg、hptw_resp_ptr_reg、hptw_need_addr_check_REG、hpaddr、addr、
//   way_info_*_r、mem_refill_id、perf 两级打拍。
//
// 【子模块】mem_arb / hyper_arb1 / hyper_arb2 = RRArbiterInit_1（rtl/common 重写件，两侧白盒对称）；
//   bitmap_arb = RRArbiterInit_4（同上）；hptw_req_arb = Arbiter2_LLPTW_Anon（golden 独有，两侧同源）。
//   ★RRArbiterInit_1 的 golden 没有 io_in_*_ready 输出★，仲裁器的 in.ready 在本层不可见。
//
// 【本文件导航】（行号由 gen_mmu5.py 生成段决定，分节标题用 "§n " 可搜）
//   §1 全局控制 · §2 寄存器 · §3 状态谓词与指针 · §4 按 id 读条目 · §5 入队判定
//   §6 仲裁器 · §7 事件匹配向量 · §8 访存响应逐条目判定 · §9 条目/状态更新
//   §10 不复位域 · §11 输出装配
package xs_llptw_pkg;
  localparam int N_ENTRY   = 6;    // llptwsize
  localparam int ID_W      = 3;    // log2Up(6)
  // SECTOR_N（8 条 PTE 一个块）沿用 xs_mmu_common_pkg 的定义，不在此重复

  // 条目状态（Chisel Enum(12) 的编码，照抄）
  localparam logic [3:0] S_IDLE           = 4'd0;
  localparam logic [3:0] S_HPTW_REQ       = 4'd1;
  localparam logic [3:0] S_HPTW_RESP      = 4'd2;
  localparam logic [3:0] S_ADDR_CHECK     = 4'd3;
  localparam logic [3:0] S_MEM_REQ        = 4'd4;
  localparam logic [3:0] S_MEM_WAITING    = 4'd5;
  localparam logic [3:0] S_MEM_OUT        = 4'd6;
  localparam logic [3:0] S_LAST_HPTW_REQ  = 4'd7;
  localparam logic [3:0] S_LAST_HPTW_RESP = 4'd8;
  localparam logic [3:0] S_CACHE          = 4'd9;
  localparam logic [3:0] S_BITMAP_CHECK   = 4'd10;
  localparam logic [3:0] S_BITMAP_RESP    = 4'd11;

  localparam logic [1:0] SRC_PREFETCH = 2'd2;   // from_pre(source)

  typedef struct packed {
    logic [37:0] vpn;
    logic [1:0]  s2xlate;
    logic [1:0]  source;
  } req_info_t;

  // HptwResp（PtwEntry(tagLen=gvpnLen, hasPerm, hasLevel, hasNapot) + gpf/gaf），
  // 只含 golden 真存的字段（没有 asid/prefetch/v）。
  typedef struct packed {
    logic [37:0] tag;
    logic [13:0] vmid;
    logic        n;
    logic [1:0]  pbmt;
    logic [37:0] ppn;
    logic        perm_d, perm_a, perm_g, perm_u, perm_x, perm_w, perm_r;
    logic [1:0]  level;
  } hptw_entry_t;

  typedef struct packed {
    hptw_entry_t entry;
    logic        gpf;
    logic        gaf;
  } hptw_resp_t;

  // LLPTWEntry：一个条目的全部字段（与 golden 的 43 个寄存器逐一对应）
  typedef struct packed {
    req_info_t   req_info;
    logic [43:0] ppn;               // ptePPNLen = 44：页表页 ppn（含高 8 位）；last_hptw 时改存叶子 ppn
    logic [2:0]  wait_id;           // 我在等哪个条目发出的访存/HPTW/bitmap 响应
    logic        af;                // PMP access fault
    hptw_resp_t  hptw_resp;         // 两阶段翻译时 HPTW 给的 G 阶段结果
    logic        first_s2xlate_fault;
    logic        cf;                // bitmap 检查失败
    logic        from_l0;           // jmp 请求：PTE 来自 PtwCache l0（否则来自访存）
    logic [3:0]  way_info;          // jmp 请求带来的 l0 命中路
    logic        jmp_bitmap_check;
    logic        n;                 // 叶子 PTE 的 napot 位
    logic [xs_mmu_common_pkg::SECTOR_N-1:0][63:0] ptes;  // jmp 请求带来的 8 条 PTE（原样带回 io.out）
    logic [xs_mmu_common_pkg::SECTOR_N-1:0]       cfs;   // 8 个 cf 位（入队时来自请求，bitmap 响应后覆盖）
  } llptw_entry_t;

  // HptwResp.genPPNS2(vpn)：按 G 阶段命中的级别，把 GPA 的低位拼进主机 ppn
  function automatic logic [37:0] gen_ppn_s2(input hptw_entry_t e, input logic [37:0] vpn);
    return (e.level == 2'd3) ? {e.ppn[37:27], vpn[26:0]}
         : (e.level == 2'd2) ? {e.ppn[37:18], vpn[17:0]}
         : (e.level == 2'd1) ? {e.ppn[37:9],  vpn[8:0]}
         : (e.n ? {e.ppn[37:4], vpn[3:0]} : e.ppn);
  endfunction
endpackage

module xs_LLPTW_core
  import xs_mmu_common_pkg::*;
  import xs_llptw_pkg::*;
(
  // BEGIN GENERATED(core_ports) —— 由 gen_mmu5.py 从 golden 端口表逐根抄出
  input  logic         clock,
  input  logic         reset,
  input  logic         io_sfence_valid,
  input  logic         io_csr_satp_changed,
  input  logic         io_csr_vsatp_changed,
  input  logic [3:0]   io_csr_hgatp_mode,
  input  logic         io_csr_hgatp_changed,
  input  logic         io_csr_mbmc_BME,
  input  logic         io_csr_mbmc_CMODE,
  input  logic         io_csr_priv_virt_changed,
  input  logic         io_csr_mPBMTE,
  input  logic         io_csr_hPBMTE,
  output logic         io_in_ready,
  input  logic         io_in_valid,
  input  logic [37:0]  io_in_bits_req_info_vpn,
  input  logic [1:0]   io_in_bits_req_info_s2xlate,
  input  logic [1:0]   io_in_bits_req_info_source,
  input  logic [43:0]  io_in_bits_ppn,
  input  logic         io_in_bits_bitmapCheck_jmp_bitmap_check,
  input  logic [63:0]  io_in_bits_bitmapCheck_ptes_0,
  input  logic [63:0]  io_in_bits_bitmapCheck_ptes_1,
  input  logic [63:0]  io_in_bits_bitmapCheck_ptes_2,
  input  logic [63:0]  io_in_bits_bitmapCheck_ptes_3,
  input  logic [63:0]  io_in_bits_bitmapCheck_ptes_4,
  input  logic [63:0]  io_in_bits_bitmapCheck_ptes_5,
  input  logic [63:0]  io_in_bits_bitmapCheck_ptes_6,
  input  logic [63:0]  io_in_bits_bitmapCheck_ptes_7,
  input  logic         io_in_bits_bitmapCheck_cfs_0,
  input  logic         io_in_bits_bitmapCheck_cfs_1,
  input  logic         io_in_bits_bitmapCheck_cfs_2,
  input  logic         io_in_bits_bitmapCheck_cfs_3,
  input  logic         io_in_bits_bitmapCheck_cfs_4,
  input  logic         io_in_bits_bitmapCheck_cfs_5,
  input  logic         io_in_bits_bitmapCheck_cfs_6,
  input  logic         io_in_bits_bitmapCheck_cfs_7,
  input  logic [3:0]   io_in_bits_bitmapCheck_hitway,
  input  logic         io_out_ready,
  output logic         io_out_valid,
  output logic [37:0]  io_out_bits_req_info_vpn,
  output logic [1:0]   io_out_bits_req_info_s2xlate,
  output logic [1:0]   io_out_bits_req_info_source,
  output logic [3:0]   io_out_bits_id,
  output logic [37:0]  io_out_bits_h_resp_entry_tag,
  output logic [13:0]  io_out_bits_h_resp_entry_vmid,
  output logic         io_out_bits_h_resp_entry_n,
  output logic [1:0]   io_out_bits_h_resp_entry_pbmt,
  output logic [37:0]  io_out_bits_h_resp_entry_ppn,
  output logic         io_out_bits_h_resp_entry_perm_d,
  output logic         io_out_bits_h_resp_entry_perm_a,
  output logic         io_out_bits_h_resp_entry_perm_g,
  output logic         io_out_bits_h_resp_entry_perm_u,
  output logic         io_out_bits_h_resp_entry_perm_x,
  output logic         io_out_bits_h_resp_entry_perm_w,
  output logic         io_out_bits_h_resp_entry_perm_r,
  output logic [1:0]   io_out_bits_h_resp_entry_level,
  output logic         io_out_bits_h_resp_gpf,
  output logic         io_out_bits_h_resp_gaf,
  output logic         io_out_bits_first_s2xlate_fault,
  output logic         io_out_bits_af,
  output logic         io_out_bits_bitmapCheck_jmp_bitmap_check,
  output logic [63:0]  io_out_bits_bitmapCheck_ptes_0,
  output logic [63:0]  io_out_bits_bitmapCheck_ptes_1,
  output logic [63:0]  io_out_bits_bitmapCheck_ptes_2,
  output logic [63:0]  io_out_bits_bitmapCheck_ptes_3,
  output logic [63:0]  io_out_bits_bitmapCheck_ptes_4,
  output logic [63:0]  io_out_bits_bitmapCheck_ptes_5,
  output logic [63:0]  io_out_bits_bitmapCheck_ptes_6,
  output logic [63:0]  io_out_bits_bitmapCheck_ptes_7,
  output logic         io_out_bits_bitmapCheck_cfs_0,
  output logic         io_out_bits_bitmapCheck_cfs_1,
  output logic         io_out_bits_bitmapCheck_cfs_2,
  output logic         io_out_bits_bitmapCheck_cfs_3,
  output logic         io_out_bits_bitmapCheck_cfs_4,
  output logic         io_out_bits_bitmapCheck_cfs_5,
  output logic         io_out_bits_bitmapCheck_cfs_6,
  output logic         io_out_bits_bitmapCheck_cfs_7,
  input  logic         io_mem_req_ready,
  output logic         io_mem_req_valid,
  output logic [47:0]  io_mem_req_bits_addr,
  output logic [3:0]   io_mem_req_bits_id,
  input  logic         io_mem_resp_valid,
  input  logic [2:0]   io_mem_resp_bits_id,
  input  logic [511:0] io_mem_resp_bits_value,
  output logic [2:0]   io_mem_enq_ptr,
  output logic         io_mem_buffer_it_0,
  output logic         io_mem_buffer_it_1,
  output logic         io_mem_buffer_it_2,
  output logic         io_mem_buffer_it_3,
  output logic         io_mem_buffer_it_4,
  output logic         io_mem_buffer_it_5,
  output logic [37:0]  io_mem_refill_vpn,
  output logic [1:0]   io_mem_refill_s2xlate,
  output logic [1:0]   io_mem_refill_source,
  input  logic         io_mem_req_mask_0,
  input  logic         io_mem_req_mask_1,
  input  logic         io_mem_req_mask_2,
  input  logic         io_mem_req_mask_3,
  input  logic         io_mem_req_mask_4,
  input  logic         io_mem_req_mask_5,
  input  logic         io_mem_flush_latch_0,
  input  logic         io_mem_flush_latch_1,
  input  logic         io_mem_flush_latch_2,
  input  logic         io_mem_flush_latch_3,
  input  logic         io_mem_flush_latch_4,
  input  logic         io_mem_flush_latch_5,
  input  logic         io_cache_ready,
  output logic         io_cache_valid,
  output logic [37:0]  io_cache_bits_vpn,
  output logic [1:0]   io_cache_bits_s2xlate,
  output logic [1:0]   io_cache_bits_source,
  output logic [47:0]  io_pmp_0_req_bits_addr,
  input  logic         io_pmp_0_resp_ld,
  input  logic         io_pmp_0_resp_mmio,
  output logic [47:0]  io_pmp_1_req_bits_addr,
  input  logic         io_pmp_1_resp_ld,
  input  logic         io_pmp_1_resp_mmio,
  input  logic         io_hptw_req_ready,
  output logic         io_hptw_req_valid,
  output logic [1:0]   io_hptw_req_bits_source,
  output logic [2:0]   io_hptw_req_bits_id,
  output logic [43:0]  io_hptw_req_bits_gvpn,
  input  logic         io_hptw_resp_valid,
  input  logic [2:0]   io_hptw_resp_bits_id,
  input  logic [37:0]  io_hptw_resp_bits_h_resp_entry_tag,
  input  logic [13:0]  io_hptw_resp_bits_h_resp_entry_vmid,
  input  logic         io_hptw_resp_bits_h_resp_entry_n,
  input  logic [1:0]   io_hptw_resp_bits_h_resp_entry_pbmt,
  input  logic [37:0]  io_hptw_resp_bits_h_resp_entry_ppn,
  input  logic         io_hptw_resp_bits_h_resp_entry_perm_d,
  input  logic         io_hptw_resp_bits_h_resp_entry_perm_a,
  input  logic         io_hptw_resp_bits_h_resp_entry_perm_g,
  input  logic         io_hptw_resp_bits_h_resp_entry_perm_u,
  input  logic         io_hptw_resp_bits_h_resp_entry_perm_x,
  input  logic         io_hptw_resp_bits_h_resp_entry_perm_w,
  input  logic         io_hptw_resp_bits_h_resp_entry_perm_r,
  input  logic [1:0]   io_hptw_resp_bits_h_resp_entry_level,
  input  logic         io_hptw_resp_bits_h_resp_gpf,
  input  logic         io_hptw_resp_bits_h_resp_gaf,
  input  logic         io_bitmap_req_ready,
  output logic         io_bitmap_req_valid,
  output logic [35:0]  io_bitmap_req_bits_bmppn,
  output logic [2:0]   io_bitmap_req_bits_id,
  output logic [37:0]  io_bitmap_req_bits_vpn,
  output logic [3:0]   io_bitmap_req_bits_way_info,
  output logic [1:0]   io_bitmap_req_bits_s2xlate,
  output logic         io_bitmap_req_bits_n,
  output logic         io_bitmap_resp_ready,
  input  logic         io_bitmap_resp_valid,
  input  logic         io_bitmap_resp_bits_cf,
  input  logic         io_bitmap_resp_bits_cfs_0,
  input  logic         io_bitmap_resp_bits_cfs_1,
  input  logic         io_bitmap_resp_bits_cfs_2,
  input  logic         io_bitmap_resp_bits_cfs_3,
  input  logic         io_bitmap_resp_bits_cfs_4,
  input  logic         io_bitmap_resp_bits_cfs_5,
  input  logic         io_bitmap_resp_bits_cfs_6,
  input  logic         io_bitmap_resp_bits_cfs_7,
  input  logic [2:0]   io_bitmap_resp_bits_id,
  input  logic [3:0]   io_l0_way_info,
  output logic [5:0]   io_perf_0_value,
  output logic [5:0]   io_perf_1_value,
  output logic [5:0]   io_perf_2_value,
  output logic [5:0]   io_perf_3_value
  // END GENERATED(core_ports)
);

  // ===========================================================================
  // §1 全局控制
  // ===========================================================================
  logic flush;
  logic bitmap_enable;
  logic in_fire, out_fire, cache_fire;
  assign flush = io_sfence_valid | io_csr_satp_changed | io_csr_vsatp_changed
               | io_csr_hgatp_changed | io_csr_priv_virt_changed;
  assign bitmap_enable = io_csr_mbmc_BME & ~io_csr_mbmc_CMODE;

  // ===========================================================================
  // §2 寄存器
  // ===========================================================================
  // ---- 异步复位域 ----
  llptw_entry_t entries [N_ENTRY];
  logic [3:0]   state   [N_ENTRY];
  logic         REG;                            // RegNext(dup_req_fire & |dup_vec_wait)：golden 只给 XSError 用
  logic [N_ENTRY-1:0] mem_resp_hit;             // 本条目上一拍刚拿到访存数据（喂 io.mem.buffer_it 与 way_info 旁路）
  logic         need_addr_check_last_REG;       // GatedValidRegNext：上一拍入队的条目进了 addr_check
  // ---- 不复位域 ----
  logic [2:0]   enq_ptr_reg;
  logic [2:0]   hptw_resp_ptr_reg;
  logic         hptw_need_addr_check_REG;
  logic [49:0]  hpaddr;                         // HPTW 翻译后的主机物理地址（送 PMP(1)）
  logic [47:0]  addr;                           // 入队时算好的最后一级 PTE 物理地址（送 PMP(0)）
  logic [3:0]   way_info_r [N_ENTRY];           // DataHoldBypass(io.l0_way_info, mem_resp_hit) 的保持寄存器
  logic [2:0]   mem_refill_id;
  logic         io_perf_0_value_REG, io_perf_0_value_REG_1;
  logic         io_perf_1_value_REG, io_perf_1_value_REG_1;
  logic         io_perf_2_value_REG, io_perf_2_value_REG_1;
  logic [2:0]   io_perf_3_value_REG, io_perf_3_value_REG_1;

  // ---- 后文才赋值、前文就要用的组合信号（SV 要求先声明）----
  logic [2:0] wait_id;                          // 入队时要跟随的条目号（§5）
  logic [N_ENTRY-1:0] mem_arb_in_valid, hyper_arb1_in_valid, hyper_arb2_in_valid;
  logic mem_arb_out_valid, hyper_arb1_out_valid, hyper_arb2_out_valid, bitmap_arb_out_valid;
  logic mem_arb_fire, hyper_arb1_fire, hyper_arb2_fire, bitmap_arb_fire;
  logic [2:0] mem_arb_chosen, hyper_arb1_chosen, hyper_arb2_chosen, bitmap_arb_chosen;
  logic [1:0] hyper_arb1_source, hyper_arb2_source;
  logic [43:0] hyper_arb1_ppn, hyper_arb2_ppn;
  logic [35:0] bitmap_arb_bmppn;
  logic hptw_req_arb_in0_ready, hptw_req_arb_in1_ready, hptw_req_arb_out_valid;
  typedef struct packed { req_info_t req_info; logic [43:0] ppn; hptw_entry_t hptw; } mem_arb_out_t;
  mem_arb_out_t mem_arb_out;                    // mem_arb 选出的那条（golden 只用到这些字段）
  hptw_resp_t   wait_by_chosen_hptw_resp;       // entries(mem_arb.chosen).hptw_resp（§9 后定义）

  // ===========================================================================
  // §3 状态谓词与指针
  // ===========================================================================
  logic [N_ENTRY-1:0] is_empty, is_mems, is_waiting, is_having, is_cache;
  logic [N_ENTRY-1:0] is_hptw_req, is_hptw_resp, is_last_hptw_req, is_last_hptw_resp;
  logic [N_ENTRY-1:0] is_bitmap_req, is_bitmap_resp;
  always_comb begin
    for (int i = 0; i < N_ENTRY; i++) begin
      is_empty[i]          = (state[i] == S_IDLE);
      is_mems[i]           = (state[i] == S_MEM_REQ);
      is_waiting[i]        = (state[i] == S_MEM_WAITING);
      is_having[i]         = (state[i] == S_MEM_OUT);
      is_cache[i]          = (state[i] == S_CACHE);
      is_hptw_req[i]       = (state[i] == S_HPTW_REQ);
      is_hptw_resp[i]      = (state[i] == S_HPTW_RESP);
      is_last_hptw_req[i]  = (state[i] == S_LAST_HPTW_REQ);
      is_last_hptw_resp[i] = (state[i] == S_LAST_HPTW_RESP);
      is_bitmap_req[i]     = (state[i] == S_BITMAP_CHECK);
      is_bitmap_resp[i]    = (state[i] == S_BITMAP_RESP);
    end
  end

  logic full, has_hptw_resp, has_last_hptw_resp, has_bitmap_resp;
  assign full               = ~(|is_empty);
  assign has_hptw_resp      = |is_hptw_resp;
  assign has_last_hptw_resp = |is_last_hptw_resp;
  assign has_bitmap_resp    = |is_bitmap_resp;

  // ParallelPriorityEncoder：最低下标优先；全不命中时给 5（golden 实测的默认值）
  function automatic logic [2:0] priority_encode6(input logic [N_ENTRY-1:0] v);
    logic [2:0] idx;
    idx = 3'd5;
    for (int i = N_ENTRY - 1; i >= 0; i--) if (v[i]) idx = 3'(i);
    return idx;
  endfunction

  // ParallelMux(is_cache, idx)：按位或的选择（多个同时命中时是 OR，不是优先）
  logic [2:0] enq_ptr, mem_ptr, cache_ptr;
  assign enq_ptr = priority_encode6(is_empty);
  assign mem_ptr = priority_encode6(is_having);
  always_comb begin
    cache_ptr = '0;
    for (int i = 0; i < N_ENTRY; i++) cache_ptr |= is_cache[i] ? 3'(i) : 3'd0;
  end

  // ===========================================================================
  // §4 按 3 位 id 读条目 —— golden 的 Vec 越界语义：6/7 读条目 0
  // ===========================================================================
  llptw_entry_t mem_resp_entry;     // entries(io.mem.resp.bits.id)
  llptw_entry_t hptw_resp_entry;    // entries(io.hptw.resp.bits.id)
  llptw_entry_t refill_entry;       // entries(mem_refill_id)
  llptw_entry_t out_entry;          // entries(mem_ptr)
  llptw_entry_t wait_entry;         // entries(wait_id)（入队时抄 hptw_resp 用）
  llptw_entry_t enq_entry;          // entries(enq_ptr)
  logic [3:0]   hptw_ptr_state;     // state(hptw_resp_ptr_reg)
  logic         mem_resp_flush_latch, mem_resp_dup_wait;
  always_comb begin
    mem_resp_entry  = entries[0];
    hptw_resp_entry = entries[0];
    refill_entry    = entries[0];
    out_entry       = entries[0];
    wait_entry      = entries[0];
    enq_entry       = entries[0];
    hptw_ptr_state  = state[0];
    for (int i = 1; i < N_ENTRY; i++) begin
      if (io_mem_resp_bits_id  == 3'(i)) mem_resp_entry  = entries[i];
      if (io_hptw_resp_bits_id == 3'(i)) hptw_resp_entry = entries[i];
      if (mem_refill_id        == 3'(i)) refill_entry    = entries[i];
      if (mem_ptr              == 3'(i)) out_entry       = entries[i];
      if (wait_id              == 3'(i)) wait_entry      = entries[i];
      if (enq_ptr              == 3'(i)) enq_entry       = entries[i];
      if (hptw_resp_ptr_reg    == 3'(i)) hptw_ptr_state  = state[i];
    end
  end

  // ===========================================================================
  // §5 入队判定：去重 / 合并 / 直接拿到刚回来的数据
  // ===========================================================================
  logic [N_ENTRY-1:0] dup_vec, dup_vec_wait;
  logic dup_req_fire, dup_wait_resp, to_wait, to_cache, to_hptw_req;
  always_comb begin
    for (int i = 0; i < N_ENTRY; i++) begin
      dup_vec[i]      = (io_in_bits_req_info_vpn[37:3] == entries[i].req_info.vpn[37:3])
                      & (io_in_bits_req_info_s2xlate == entries[i].req_info.s2xlate);
      dup_vec_wait[i] = dup_vec[i] & is_waiting[i];
    end
  end
  // 与本拍 mem_arb 正在发出的那条请求撞同一扇区
  assign dup_req_fire = mem_arb_fire
                      & (io_in_bits_req_info_vpn[37:3] == mem_arb_out.req_info.vpn[37:3])
                      & (io_in_bits_req_info_s2xlate == mem_arb_out.req_info.s2xlate);
  // 本拍访存响应正好是我要的扇区（响应 id 对应的条目在 dup_vec_wait 里，且没被 flush_latch 作废）
  always_comb begin
    mem_resp_dup_wait    = dup_vec_wait[0];
    mem_resp_flush_latch = io_mem_flush_latch_0;
    case (io_mem_resp_bits_id)
      3'd1: begin mem_resp_dup_wait = dup_vec_wait[1]; mem_resp_flush_latch = io_mem_flush_latch_1; end
      3'd2: begin mem_resp_dup_wait = dup_vec_wait[2]; mem_resp_flush_latch = io_mem_flush_latch_2; end
      3'd3: begin mem_resp_dup_wait = dup_vec_wait[3]; mem_resp_flush_latch = io_mem_flush_latch_3; end
      3'd4: begin mem_resp_dup_wait = dup_vec_wait[4]; mem_resp_flush_latch = io_mem_flush_latch_4; end
      3'd5: begin mem_resp_dup_wait = dup_vec_wait[5]; mem_resp_flush_latch = io_mem_flush_latch_5; end
      default: ;
    endcase
  end
  assign dup_wait_resp = io_mem_resp_valid & mem_resp_dup_wait & ~mem_resp_flush_latch;
  assign to_wait       = (|dup_vec_wait) | dup_req_fire;
  always_comb begin
    wait_id = '0;
    for (int i = 0; i < N_ENTRY; i++) wait_id |= dup_vec_wait[i] ? entries[i].wait_id : 3'd0;
    if (dup_req_fire) wait_id = mem_arb_chosen;
  end
  always_comb begin
    to_cache = 1'b0;
    for (int i = 0; i < N_ENTRY; i++)
      to_cache |= dup_vec[i] & (is_bitmap_req[i] | is_bitmap_resp[i] | is_having[i]
                                | is_last_hptw_req[i] | is_last_hptw_resp[i]);
  end
  assign to_hptw_req = (io_in_bits_req_info_s2xlate == ALL_STAGE);

  // 刚回来的那个块里、新请求要的那条 PTE（index = vpn[2:0]：MakeAddr 的 [5:3] 就是 vpn 低 3 位）
  pte_t  in_resp_pte;
  logic [43:0] last_hptw_req_ppn;      // napot 叶子把 vpn 低 4 位拼进 ppn
  logic  last_hptw_vsStagePf, last_hptw_gStagePf;
  logic  mem_resp_s1Pbmte, mem_resp_Pf, mem_resp_gStagePf, noStage2;
  logic  to_mem_out, to_bitmap_req, to_last_hptw_req, last_hptw_excp;
  assign in_resp_pte = pte_t'(io_mem_resp_bits_value[io_in_bits_req_info_vpn[2:0]*64 +: 64]);
  assign last_hptw_req_ppn = {in_resp_pte.ppn_high,
                              in_resp_pte.n ? {in_resp_pte.ppn[35:4], io_in_bits_req_info_vpn[3:0]}
                                            : in_resp_pte.ppn};
  // allStage 视角：VS 阶段 pf（按 hPBMTE）、G 阶段 gpf（vs pf 时不查）
  assign last_hptw_vsStagePf = pte_is_pf(in_resp_pte, 2'd0, io_csr_hPBMTE) | ~pte_is_leaf(in_resp_pte);
  assign last_hptw_gStagePf  = pte_is_stage1_gpf(in_resp_pte, io_csr_hgatp_mode) & ~last_hptw_vsStagePf;
  // 响应条目自身模式视角：pbmte 按它的 s2xlate 选
  assign mem_resp_s1Pbmte  = (mem_resp_entry.req_info.s2xlate != NO_S2XLATE) ? io_csr_hPBMTE : io_csr_mPBMTE;
  assign mem_resp_Pf       = pte_is_pf(in_resp_pte, 2'd0, mem_resp_s1Pbmte) | ~pte_is_leaf(in_resp_pte);
  assign mem_resp_gStagePf = (mem_resp_entry.req_info.s2xlate == ALL_STAGE)
                           & pte_is_stage1_gpf(in_resp_pte, io_csr_hgatp_mode) & ~mem_resp_Pf;
  // 不需要第二阶段翻译：noS2xlate / onlyStage1，或 allStage 但已经出故障
  assign noStage2 = (mem_resp_entry.req_info.s2xlate == NO_S2XLATE)
                  | (mem_resp_entry.req_info.s2xlate == ONLY_STAGE1)
                  | ((mem_resp_entry.req_info.s2xlate == ALL_STAGE) & (last_hptw_vsStagePf | last_hptw_gStagePf));
  assign to_mem_out       = dup_wait_resp & noStage2 & (~bitmap_enable | mem_resp_Pf | mem_resp_gStagePf);
  assign to_bitmap_req    = dup_wait_resp & noStage2 & bitmap_enable & ~(mem_resp_Pf | mem_resp_gStagePf);
  assign to_last_hptw_req = dup_wait_resp & (mem_resp_entry.req_info.s2xlate == ALL_STAGE)
                          & ~(last_hptw_vsStagePf | last_hptw_gStagePf);
  assign last_hptw_excp   = dup_wait_resp & (mem_resp_entry.req_info.s2xlate == ALL_STAGE)
                          & (last_hptw_vsStagePf | last_hptw_gStagePf);

  // 入队状态：MuxCase 优先级照抄；预取不需要真访存就丢掉
  logic [3:0] enq_state_normal, enq_state;
  assign enq_state_normal = to_mem_out       ? S_MEM_OUT
                          : to_bitmap_req    ? S_BITMAP_CHECK
                          : to_last_hptw_req ? S_LAST_HPTW_REQ
                          : to_wait          ? S_MEM_WAITING
                          : to_cache         ? S_CACHE
                          : to_hptw_req      ? S_HPTW_REQ
                          :                    S_ADDR_CHECK;
  assign enq_state = ((io_in_bits_req_info_source == SRC_PREFETCH) & (enq_state_normal != S_ADDR_CHECK))
                   ? S_IDLE : enq_state_normal;

  assign in_fire    = ~full & io_in_valid;
  logic enq_normal, enq_jmp;                       // 两种入队
  assign enq_normal = in_fire & ~io_in_bits_bitmapCheck_jmp_bitmap_check;
  assign enq_jmp    = in_fire &  io_in_bits_bitmapCheck_jmp_bitmap_check;

  // jmp 请求：8 条 PTE 里按 vpn[2:0] 挑出命中的那条
  pte_t jmp_pte;
  logic [SECTOR_N-1:0][63:0] in_ptes;
  logic [SECTOR_N-1:0]       in_cfs;
  assign in_ptes = {io_in_bits_bitmapCheck_ptes_7, io_in_bits_bitmapCheck_ptes_6,
                    io_in_bits_bitmapCheck_ptes_5, io_in_bits_bitmapCheck_ptes_4,
                    io_in_bits_bitmapCheck_ptes_3, io_in_bits_bitmapCheck_ptes_2,
                    io_in_bits_bitmapCheck_ptes_1, io_in_bits_bitmapCheck_ptes_0};
  assign in_cfs  = {io_in_bits_bitmapCheck_cfs_7, io_in_bits_bitmapCheck_cfs_6,
                    io_in_bits_bitmapCheck_cfs_5, io_in_bits_bitmapCheck_cfs_4,
                    io_in_bits_bitmapCheck_cfs_3, io_in_bits_bitmapCheck_cfs_2,
                    io_in_bits_bitmapCheck_cfs_1, io_in_bits_bitmapCheck_cfs_0};
  assign jmp_pte = pte_t'(in_ptes[io_in_bits_req_info_vpn[2:0]]);

  // ===========================================================================
  // §6 仲裁器
  // ===========================================================================
  // mem_arb：mem_req 状态且没被 L2TLB 的 req_mask 压住的条目竞争访存口
  logic [N_ENTRY-1:0] req_mask;
  assign req_mask = {io_mem_req_mask_5, io_mem_req_mask_4, io_mem_req_mask_3,
                     io_mem_req_mask_2, io_mem_req_mask_1, io_mem_req_mask_0};
  // HPTW 请求串行化：有条目在等 HPTW 响应时不发新请求
  assign mem_arb_in_valid    = is_mems & ~req_mask;
  assign hyper_arb1_in_valid = is_hptw_req      & {N_ENTRY{~has_hptw_resp & ~has_last_hptw_resp}};
  assign hyper_arb2_in_valid = is_last_hptw_req & {N_ENTRY{~has_hptw_resp & ~has_last_hptw_resp}};
  assign mem_arb_fire    = io_mem_req_ready & mem_arb_out_valid;      // out.ready 直接是 io.mem.req.ready（不看 flush）
  assign hyper_arb1_fire = hptw_req_arb_in0_ready & hyper_arb1_out_valid;
  assign hyper_arb2_fire = hptw_req_arb_in1_ready & hyper_arb2_out_valid;
  assign bitmap_arb_fire = io_bitmap_req_ready & bitmap_arb_out_valid;

  // bitmap_arb 每路的 way_info：jmp 来的用请求带的路，否则用 mem 响应后一拍旁路/保持的 l0_way_info
  logic [3:0] way_info [N_ENTRY];
  logic [3:0] bitmap_in_way_info [N_ENTRY];
  always_comb begin
    for (int i = 0; i < N_ENTRY; i++) begin
      way_info[i]           = mem_resp_hit[i] ? io_l0_way_info : way_info_r[i];
      bitmap_in_way_info[i] = entries[i].from_l0 ? entries[i].way_info : way_info[i];
    end
  end

  RRArbiterInit_1 mem_arb (
    .clock(clock), .reset(reset),
    .io_in_0_valid(mem_arb_in_valid[0]),
    .io_in_0_bits_req_info_vpn(entries[0].req_info.vpn), .io_in_0_bits_req_info_s2xlate(entries[0].req_info.s2xlate),
    .io_in_0_bits_req_info_source(entries[0].req_info.source), .io_in_0_bits_ppn(entries[0].ppn),
    .io_in_0_bits_hptw_resp_entry_n(entries[0].hptw_resp.entry.n), .io_in_0_bits_hptw_resp_entry_ppn(entries[0].hptw_resp.entry.ppn),
    .io_in_0_bits_hptw_resp_entry_level(entries[0].hptw_resp.entry.level),
    .io_in_1_valid(mem_arb_in_valid[1]),
    .io_in_1_bits_req_info_vpn(entries[1].req_info.vpn), .io_in_1_bits_req_info_s2xlate(entries[1].req_info.s2xlate),
    .io_in_1_bits_req_info_source(entries[1].req_info.source), .io_in_1_bits_ppn(entries[1].ppn),
    .io_in_1_bits_hptw_resp_entry_n(entries[1].hptw_resp.entry.n), .io_in_1_bits_hptw_resp_entry_ppn(entries[1].hptw_resp.entry.ppn),
    .io_in_1_bits_hptw_resp_entry_level(entries[1].hptw_resp.entry.level),
    .io_in_2_valid(mem_arb_in_valid[2]),
    .io_in_2_bits_req_info_vpn(entries[2].req_info.vpn), .io_in_2_bits_req_info_s2xlate(entries[2].req_info.s2xlate),
    .io_in_2_bits_req_info_source(entries[2].req_info.source), .io_in_2_bits_ppn(entries[2].ppn),
    .io_in_2_bits_hptw_resp_entry_n(entries[2].hptw_resp.entry.n), .io_in_2_bits_hptw_resp_entry_ppn(entries[2].hptw_resp.entry.ppn),
    .io_in_2_bits_hptw_resp_entry_level(entries[2].hptw_resp.entry.level),
    .io_in_3_valid(mem_arb_in_valid[3]),
    .io_in_3_bits_req_info_vpn(entries[3].req_info.vpn), .io_in_3_bits_req_info_s2xlate(entries[3].req_info.s2xlate),
    .io_in_3_bits_req_info_source(entries[3].req_info.source), .io_in_3_bits_ppn(entries[3].ppn),
    .io_in_3_bits_hptw_resp_entry_n(entries[3].hptw_resp.entry.n), .io_in_3_bits_hptw_resp_entry_ppn(entries[3].hptw_resp.entry.ppn),
    .io_in_3_bits_hptw_resp_entry_level(entries[3].hptw_resp.entry.level),
    .io_in_4_valid(mem_arb_in_valid[4]),
    .io_in_4_bits_req_info_vpn(entries[4].req_info.vpn), .io_in_4_bits_req_info_s2xlate(entries[4].req_info.s2xlate),
    .io_in_4_bits_req_info_source(entries[4].req_info.source), .io_in_4_bits_ppn(entries[4].ppn),
    .io_in_4_bits_hptw_resp_entry_n(entries[4].hptw_resp.entry.n), .io_in_4_bits_hptw_resp_entry_ppn(entries[4].hptw_resp.entry.ppn),
    .io_in_4_bits_hptw_resp_entry_level(entries[4].hptw_resp.entry.level),
    .io_in_5_valid(mem_arb_in_valid[5]),
    .io_in_5_bits_req_info_vpn(entries[5].req_info.vpn), .io_in_5_bits_req_info_s2xlate(entries[5].req_info.s2xlate),
    .io_in_5_bits_req_info_source(entries[5].req_info.source), .io_in_5_bits_ppn(entries[5].ppn),
    .io_in_5_bits_hptw_resp_entry_n(entries[5].hptw_resp.entry.n), .io_in_5_bits_hptw_resp_entry_ppn(entries[5].hptw_resp.entry.ppn),
    .io_in_5_bits_hptw_resp_entry_level(entries[5].hptw_resp.entry.level),
    .io_out_ready(io_mem_req_ready),
    .io_out_valid(mem_arb_out_valid),
    .io_out_bits_req_info_vpn(mem_arb_out.req_info.vpn), .io_out_bits_req_info_s2xlate(mem_arb_out.req_info.s2xlate),
    .io_out_bits_req_info_source(mem_arb_out.req_info.source), .io_out_bits_ppn(mem_arb_out.ppn),
    .io_out_bits_hptw_resp_entry_n(mem_arb_out.hptw.n), .io_out_bits_hptw_resp_entry_ppn(mem_arb_out.hptw.ppn),
    .io_out_bits_hptw_resp_entry_level(mem_arb_out.hptw.level),
    .io_chosen(mem_arb_chosen)
  );
  // 第一次 HPTW 翻译（页表页地址）与最后一次（叶子 ppn）各一个轮转仲裁器，再由 hptw_req_arb 二选一
  RRArbiterInit_1 hyper_arb1 (
    .clock(clock), .reset(reset),
    .io_in_0_valid(hyper_arb1_in_valid[0]),
    .io_in_0_bits_req_info_vpn(entries[0].req_info.vpn), .io_in_0_bits_req_info_s2xlate(entries[0].req_info.s2xlate),
    .io_in_0_bits_req_info_source(entries[0].req_info.source), .io_in_0_bits_ppn(entries[0].ppn),
    .io_in_0_bits_hptw_resp_entry_n(entries[0].hptw_resp.entry.n), .io_in_0_bits_hptw_resp_entry_ppn(entries[0].hptw_resp.entry.ppn),
    .io_in_0_bits_hptw_resp_entry_level(entries[0].hptw_resp.entry.level),
    .io_in_1_valid(hyper_arb1_in_valid[1]),
    .io_in_1_bits_req_info_vpn(entries[1].req_info.vpn), .io_in_1_bits_req_info_s2xlate(entries[1].req_info.s2xlate),
    .io_in_1_bits_req_info_source(entries[1].req_info.source), .io_in_1_bits_ppn(entries[1].ppn),
    .io_in_1_bits_hptw_resp_entry_n(entries[1].hptw_resp.entry.n), .io_in_1_bits_hptw_resp_entry_ppn(entries[1].hptw_resp.entry.ppn),
    .io_in_1_bits_hptw_resp_entry_level(entries[1].hptw_resp.entry.level),
    .io_in_2_valid(hyper_arb1_in_valid[2]),
    .io_in_2_bits_req_info_vpn(entries[2].req_info.vpn), .io_in_2_bits_req_info_s2xlate(entries[2].req_info.s2xlate),
    .io_in_2_bits_req_info_source(entries[2].req_info.source), .io_in_2_bits_ppn(entries[2].ppn),
    .io_in_2_bits_hptw_resp_entry_n(entries[2].hptw_resp.entry.n), .io_in_2_bits_hptw_resp_entry_ppn(entries[2].hptw_resp.entry.ppn),
    .io_in_2_bits_hptw_resp_entry_level(entries[2].hptw_resp.entry.level),
    .io_in_3_valid(hyper_arb1_in_valid[3]),
    .io_in_3_bits_req_info_vpn(entries[3].req_info.vpn), .io_in_3_bits_req_info_s2xlate(entries[3].req_info.s2xlate),
    .io_in_3_bits_req_info_source(entries[3].req_info.source), .io_in_3_bits_ppn(entries[3].ppn),
    .io_in_3_bits_hptw_resp_entry_n(entries[3].hptw_resp.entry.n), .io_in_3_bits_hptw_resp_entry_ppn(entries[3].hptw_resp.entry.ppn),
    .io_in_3_bits_hptw_resp_entry_level(entries[3].hptw_resp.entry.level),
    .io_in_4_valid(hyper_arb1_in_valid[4]),
    .io_in_4_bits_req_info_vpn(entries[4].req_info.vpn), .io_in_4_bits_req_info_s2xlate(entries[4].req_info.s2xlate),
    .io_in_4_bits_req_info_source(entries[4].req_info.source), .io_in_4_bits_ppn(entries[4].ppn),
    .io_in_4_bits_hptw_resp_entry_n(entries[4].hptw_resp.entry.n), .io_in_4_bits_hptw_resp_entry_ppn(entries[4].hptw_resp.entry.ppn),
    .io_in_4_bits_hptw_resp_entry_level(entries[4].hptw_resp.entry.level),
    .io_in_5_valid(hyper_arb1_in_valid[5]),
    .io_in_5_bits_req_info_vpn(entries[5].req_info.vpn), .io_in_5_bits_req_info_s2xlate(entries[5].req_info.s2xlate),
    .io_in_5_bits_req_info_source(entries[5].req_info.source), .io_in_5_bits_ppn(entries[5].ppn),
    .io_in_5_bits_hptw_resp_entry_n(entries[5].hptw_resp.entry.n), .io_in_5_bits_hptw_resp_entry_ppn(entries[5].hptw_resp.entry.ppn),
    .io_in_5_bits_hptw_resp_entry_level(entries[5].hptw_resp.entry.level),
    .io_out_ready(hptw_req_arb_in0_ready),
    .io_out_valid(hyper_arb1_out_valid),
    .io_out_bits_req_info_vpn(), .io_out_bits_req_info_s2xlate(),
    .io_out_bits_req_info_source(hyper_arb1_source), .io_out_bits_ppn(hyper_arb1_ppn),
    .io_out_bits_hptw_resp_entry_n(), .io_out_bits_hptw_resp_entry_ppn(), .io_out_bits_hptw_resp_entry_level(),
    .io_chosen(hyper_arb1_chosen)
  );
  RRArbiterInit_1 hyper_arb2 (
    .clock(clock), .reset(reset),
    .io_in_0_valid(hyper_arb2_in_valid[0]),
    .io_in_0_bits_req_info_vpn(entries[0].req_info.vpn), .io_in_0_bits_req_info_s2xlate(entries[0].req_info.s2xlate),
    .io_in_0_bits_req_info_source(entries[0].req_info.source), .io_in_0_bits_ppn(entries[0].ppn),
    .io_in_0_bits_hptw_resp_entry_n(entries[0].hptw_resp.entry.n), .io_in_0_bits_hptw_resp_entry_ppn(entries[0].hptw_resp.entry.ppn),
    .io_in_0_bits_hptw_resp_entry_level(entries[0].hptw_resp.entry.level),
    .io_in_1_valid(hyper_arb2_in_valid[1]),
    .io_in_1_bits_req_info_vpn(entries[1].req_info.vpn), .io_in_1_bits_req_info_s2xlate(entries[1].req_info.s2xlate),
    .io_in_1_bits_req_info_source(entries[1].req_info.source), .io_in_1_bits_ppn(entries[1].ppn),
    .io_in_1_bits_hptw_resp_entry_n(entries[1].hptw_resp.entry.n), .io_in_1_bits_hptw_resp_entry_ppn(entries[1].hptw_resp.entry.ppn),
    .io_in_1_bits_hptw_resp_entry_level(entries[1].hptw_resp.entry.level),
    .io_in_2_valid(hyper_arb2_in_valid[2]),
    .io_in_2_bits_req_info_vpn(entries[2].req_info.vpn), .io_in_2_bits_req_info_s2xlate(entries[2].req_info.s2xlate),
    .io_in_2_bits_req_info_source(entries[2].req_info.source), .io_in_2_bits_ppn(entries[2].ppn),
    .io_in_2_bits_hptw_resp_entry_n(entries[2].hptw_resp.entry.n), .io_in_2_bits_hptw_resp_entry_ppn(entries[2].hptw_resp.entry.ppn),
    .io_in_2_bits_hptw_resp_entry_level(entries[2].hptw_resp.entry.level),
    .io_in_3_valid(hyper_arb2_in_valid[3]),
    .io_in_3_bits_req_info_vpn(entries[3].req_info.vpn), .io_in_3_bits_req_info_s2xlate(entries[3].req_info.s2xlate),
    .io_in_3_bits_req_info_source(entries[3].req_info.source), .io_in_3_bits_ppn(entries[3].ppn),
    .io_in_3_bits_hptw_resp_entry_n(entries[3].hptw_resp.entry.n), .io_in_3_bits_hptw_resp_entry_ppn(entries[3].hptw_resp.entry.ppn),
    .io_in_3_bits_hptw_resp_entry_level(entries[3].hptw_resp.entry.level),
    .io_in_4_valid(hyper_arb2_in_valid[4]),
    .io_in_4_bits_req_info_vpn(entries[4].req_info.vpn), .io_in_4_bits_req_info_s2xlate(entries[4].req_info.s2xlate),
    .io_in_4_bits_req_info_source(entries[4].req_info.source), .io_in_4_bits_ppn(entries[4].ppn),
    .io_in_4_bits_hptw_resp_entry_n(entries[4].hptw_resp.entry.n), .io_in_4_bits_hptw_resp_entry_ppn(entries[4].hptw_resp.entry.ppn),
    .io_in_4_bits_hptw_resp_entry_level(entries[4].hptw_resp.entry.level),
    .io_in_5_valid(hyper_arb2_in_valid[5]),
    .io_in_5_bits_req_info_vpn(entries[5].req_info.vpn), .io_in_5_bits_req_info_s2xlate(entries[5].req_info.s2xlate),
    .io_in_5_bits_req_info_source(entries[5].req_info.source), .io_in_5_bits_ppn(entries[5].ppn),
    .io_in_5_bits_hptw_resp_entry_n(entries[5].hptw_resp.entry.n), .io_in_5_bits_hptw_resp_entry_ppn(entries[5].hptw_resp.entry.ppn),
    .io_in_5_bits_hptw_resp_entry_level(entries[5].hptw_resp.entry.level),
    .io_out_ready(hptw_req_arb_in1_ready),
    .io_out_valid(hyper_arb2_out_valid),
    .io_out_bits_req_info_vpn(), .io_out_bits_req_info_s2xlate(),
    .io_out_bits_req_info_source(hyper_arb2_source), .io_out_bits_ppn(hyper_arb2_ppn),
    .io_out_bits_hptw_resp_entry_n(), .io_out_bits_hptw_resp_entry_ppn(), .io_out_bits_hptw_resp_entry_level(),
    .io_chosen(hyper_arb2_chosen)
  );
  RRArbiterInit_4 bitmap_arb (
    .clock(clock), .reset(reset),
    .io_in_0_valid(is_bitmap_req[0]), .io_in_0_bits_bmppn(entries[0].ppn[35:0]), .io_in_0_bits_vpn(entries[0].req_info.vpn),
    .io_in_0_bits_way_info(bitmap_in_way_info[0]), .io_in_0_bits_s2xlate(entries[0].req_info.s2xlate), .io_in_0_bits_n(entries[0].n),
    .io_in_1_valid(is_bitmap_req[1]), .io_in_1_bits_bmppn(entries[1].ppn[35:0]), .io_in_1_bits_vpn(entries[1].req_info.vpn),
    .io_in_1_bits_way_info(bitmap_in_way_info[1]), .io_in_1_bits_s2xlate(entries[1].req_info.s2xlate), .io_in_1_bits_n(entries[1].n),
    .io_in_2_valid(is_bitmap_req[2]), .io_in_2_bits_bmppn(entries[2].ppn[35:0]), .io_in_2_bits_vpn(entries[2].req_info.vpn),
    .io_in_2_bits_way_info(bitmap_in_way_info[2]), .io_in_2_bits_s2xlate(entries[2].req_info.s2xlate), .io_in_2_bits_n(entries[2].n),
    .io_in_3_valid(is_bitmap_req[3]), .io_in_3_bits_bmppn(entries[3].ppn[35:0]), .io_in_3_bits_vpn(entries[3].req_info.vpn),
    .io_in_3_bits_way_info(bitmap_in_way_info[3]), .io_in_3_bits_s2xlate(entries[3].req_info.s2xlate), .io_in_3_bits_n(entries[3].n),
    .io_in_4_valid(is_bitmap_req[4]), .io_in_4_bits_bmppn(entries[4].ppn[35:0]), .io_in_4_bits_vpn(entries[4].req_info.vpn),
    .io_in_4_bits_way_info(bitmap_in_way_info[4]), .io_in_4_bits_s2xlate(entries[4].req_info.s2xlate), .io_in_4_bits_n(entries[4].n),
    .io_in_5_valid(is_bitmap_req[5]), .io_in_5_bits_bmppn(entries[5].ppn[35:0]), .io_in_5_bits_vpn(entries[5].req_info.vpn),
    .io_in_5_bits_way_info(bitmap_in_way_info[5]), .io_in_5_bits_s2xlate(entries[5].req_info.s2xlate), .io_in_5_bits_n(entries[5].n),
    .io_out_ready(io_bitmap_req_ready),
    .io_out_valid(bitmap_arb_out_valid),
    .io_out_bits_bmppn(bitmap_arb_bmppn),
    .io_out_bits_vpn(io_bitmap_req_bits_vpn),
    .io_out_bits_way_info(io_bitmap_req_bits_way_info),
    .io_out_bits_s2xlate(io_bitmap_req_bits_s2xlate),
    .io_out_bits_n(io_bitmap_req_bits_n),
    .io_chosen(bitmap_arb_chosen)
  );
  Arbiter2_LLPTW_Anon hptw_req_arb (
    .io_in_0_ready(hptw_req_arb_in0_ready),
    .io_in_0_valid(hyper_arb1_out_valid),
    .io_in_0_bits_source(hyper_arb1_source),
    .io_in_0_bits_id(hyper_arb1_chosen),
    .io_in_0_bits_ppn(hyper_arb1_ppn),
    .io_in_1_ready(hptw_req_arb_in1_ready),
    .io_in_1_valid(hyper_arb2_out_valid),
    .io_in_1_bits_source(hyper_arb2_source),
    .io_in_1_bits_id(hyper_arb2_chosen),
    .io_in_1_bits_ppn(hyper_arb2_ppn),
    .io_out_ready(io_hptw_req_ready),
    .io_out_valid(hptw_req_arb_out_valid),
    .io_out_bits_source(io_hptw_req_bits_source),
    .io_out_bits_id(io_hptw_req_bits_id),
    .io_out_bits_ppn(io_hptw_req_bits_gvpn)
  );

  // ===========================================================================
  // §7 事件匹配向量：本拍的每件事命中了哪个条目
  // ===========================================================================
  logic [N_ENTRY-1:0] enq_normal_hit, enq_jmp_hit;      // 入队写到本条目
  logic [N_ENTRY-1:0] hyper1_hit, hyper2_hit;           // hyper_arb 选中了本条目
  logic [N_ENTRY-1:0] pmp0_hit, pmp1_hit;               // PMP 结果回到本条目
  logic [N_ENTRY-1:0] mem_arb_dup_hit;                  // mem_arb 发出的请求覆盖了本条目（同扇区合并）
  logic [N_ENTRY-1:0] mem_resp_take;                    // 访存响应命中本条目
  logic [N_ENTRY-1:0] bitmap_arb_hit, bitmap_resp_take; // bitmap 请求发出 / 响应命中
  logic [N_ENTRY-1:0] hptw_resp_hit, last_hptw_resp_hit;// HPTW 响应命中（第一次 / 最后一次）
  logic need_addr_check, hptw_need_addr_check;
  logic accessFault0, accessFault1, hptw_fault, check_g_perm_fail;
  logic bitmap_resp_fire;
  assign need_addr_check      = need_addr_check_last_REG;
  assign hptw_need_addr_check = hptw_need_addr_check_REG & (hptw_ptr_state == S_ADDR_CHECK);
  assign accessFault0 = io_pmp_0_resp_ld | io_pmp_0_resp_mmio;
  assign accessFault1 = io_pmp_1_resp_ld | io_pmp_1_resp_mmio;
  assign bitmap_resp_fire = has_bitmap_resp & io_bitmap_resp_valid;
  // G 阶段权限检查：没 gaf 却不可读也算故障
  assign check_g_perm_fail = ~io_hptw_resp_bits_h_resp_gaf & ~io_hptw_resp_bits_h_resp_entry_perm_r;
  assign hptw_fault = check_g_perm_fail | io_hptw_resp_bits_h_resp_gaf | io_hptw_resp_bits_h_resp_gpf;

  always_comb begin
    for (int i = 0; i < N_ENTRY; i++) begin
      enq_normal_hit[i]  = enq_normal & (enq_ptr == 3'(i));
      enq_jmp_hit[i]     = enq_jmp    & (enq_ptr == 3'(i));
      hyper1_hit[i]      = hyper_arb1_fire & is_hptw_req[i] & (entries[i].ppn == hyper_arb1_ppn)
                         & (entries[i].req_info.s2xlate == ALL_STAGE) & (hyper_arb1_chosen == 3'(i));
      hyper2_hit[i]      = hyper_arb2_fire & is_last_hptw_req[i] & (entries[i].ppn == hyper_arb2_ppn)
                         & (entries[i].req_info.s2xlate == ALL_STAGE) & (hyper_arb2_chosen == 3'(i));
      pmp0_hit[i]        = need_addr_check      & (enq_ptr_reg       == 3'(i));
      pmp1_hit[i]        = hptw_need_addr_check & (hptw_resp_ptr_reg == 3'(i));
      mem_arb_dup_hit[i] = mem_arb_fire
                         & (state[i] != S_IDLE) & (state[i] != S_MEM_OUT)
                         & (state[i] != S_LAST_HPTW_REQ) & (state[i] != S_LAST_HPTW_RESP)
                         & (state[i] != S_BITMAP_CHECK) & (state[i] != S_BITMAP_RESP)
                         & (entries[i].req_info.s2xlate == mem_arb_out.req_info.s2xlate)
                         & (entries[i].req_info.vpn[37:3] == mem_arb_out.req_info.vpn[37:3]);
      mem_resp_take[i]   = io_mem_resp_valid & is_waiting[i] & (io_mem_resp_bits_id == entries[i].wait_id);
      bitmap_arb_hit[i]  = bitmap_arb_fire & is_bitmap_req[i] & (bitmap_arb_bmppn == entries[i].ppn[35:0]);
      bitmap_resp_take[i]= bitmap_resp_fire & is_bitmap_resp[i] & (io_bitmap_resp_bits_id == entries[i].wait_id);
      hptw_resp_hit[i]   = io_hptw_resp_valid & is_hptw_resp[i] & (io_hptw_resp_bits_id == entries[i].wait_id)
                         & ({6'h0, io_hptw_resp_bits_h_resp_entry_tag} == entries[i].ppn);
      last_hptw_resp_hit[i] = io_hptw_resp_valid & is_last_hptw_resp[i] & (io_hptw_resp_bits_id == entries[i].wait_id)
                         & ({6'h0, io_hptw_resp_bits_h_resp_entry_tag} == entries[i].ppn);
    end
  end

  // HPTW 响应无故障时：还有没有同扇区的条目在 mem_waiting？有就跟着等（wait_id 抄它的）
  logic [N_ENTRY-1:0] need_to_waiting_vec;
  logic [2:0]         waiting_index;
  always_comb begin
    waiting_index = '0;
    for (int i = 0; i < N_ENTRY; i++) begin
      need_to_waiting_vec[i] = is_waiting[i]
                             & (entries[i].req_info.vpn[37:3] == hptw_resp_entry.req_info.vpn[37:3])
                             & (entries[i].req_info.s2xlate == hptw_resp_entry.req_info.s2xlate);
      waiting_index |= need_to_waiting_vec[i] ? entries[i].wait_id : 3'd0;
    end
  end

  // 入队时抄来的 hptw_resp：跟着 last_hptw 的条目 / 跟着 mem_waiting 的条目 / 自己原来的
  hptw_resp_t enq_hptw_resp;
  assign enq_hptw_resp = to_last_hptw_req ? mem_resp_entry.hptw_resp
                       : to_wait          ? wait_entry.hptw_resp
                       :                    enq_entry.hptw_resp;

  // HPTW 响应打包成 struct
  hptw_resp_t in_h_resp;
  assign in_h_resp = '{entry: '{tag: io_hptw_resp_bits_h_resp_entry_tag, vmid: io_hptw_resp_bits_h_resp_entry_vmid,
                                n: io_hptw_resp_bits_h_resp_entry_n, pbmt: io_hptw_resp_bits_h_resp_entry_pbmt,
                                ppn: io_hptw_resp_bits_h_resp_entry_ppn,
                                perm_d: io_hptw_resp_bits_h_resp_entry_perm_d, perm_a: io_hptw_resp_bits_h_resp_entry_perm_a,
                                perm_g: io_hptw_resp_bits_h_resp_entry_perm_g, perm_u: io_hptw_resp_bits_h_resp_entry_perm_u,
                                perm_x: io_hptw_resp_bits_h_resp_entry_perm_x, perm_w: io_hptw_resp_bits_h_resp_entry_perm_w,
                                perm_r: io_hptw_resp_bits_h_resp_entry_perm_r, level: io_hptw_resp_bits_h_resp_entry_level},
                       gpf: io_hptw_resp_bits_h_resp_gpf, gaf: io_hptw_resp_bits_h_resp_gaf};
  logic [SECTOR_N-1:0] in_bitmap_cfs;
  assign in_bitmap_cfs = {io_bitmap_resp_bits_cfs_7, io_bitmap_resp_bits_cfs_6, io_bitmap_resp_bits_cfs_5,
                          io_bitmap_resp_bits_cfs_4, io_bitmap_resp_bits_cfs_3, io_bitmap_resp_bits_cfs_2,
                          io_bitmap_resp_bits_cfs_1, io_bitmap_resp_bits_cfs_0};

  // ===========================================================================
  // §8 访存响应逐条目判定：各自用自己的 vpn[2:0] 挑 PTE
  // ===========================================================================
  pte_t        resp_pte     [N_ENTRY];
  logic        vsStagePf    [N_ENTRY];
  logic        gStagePf     [N_ENTRY];
  logic [3:0]  mem_resp_next_state [N_ENTRY];
  logic [43:0] resp_leaf_ppn [N_ENTRY];
  always_comb begin
    for (int i = 0; i < N_ENTRY; i++) begin
      resp_pte[i]  = pte_t'(io_mem_resp_bits_value[entries[i].req_info.vpn[2:0]*64 +: 64]);
      vsStagePf[i] = pte_is_pf(resp_pte[i], 2'd0,
                               (entries[i].req_info.s2xlate != NO_S2XLATE) ? io_csr_hPBMTE : io_csr_mPBMTE)
                   | ~pte_is_leaf(resp_pte[i]);
      gStagePf[i]  = pte_is_stage1_gpf(resp_pte[i], io_csr_hgatp_mode) & ~vsStagePf[i];
      mem_resp_next_state[i] =
          ((entries[i].req_info.s2xlate == ALL_STAGE) & ~(vsStagePf[i] | gStagePf[i])) ? S_LAST_HPTW_REQ
        : (bitmap_enable & ~(vsStagePf[i] | ((entries[i].req_info.s2xlate == ALL_STAGE) & gStagePf[i]))) ? S_BITMAP_CHECK
        : S_MEM_OUT;
      resp_leaf_ppn[i] = {resp_pte[i].ppn_high,
                          resp_pte[i].n ? {resp_pte[i].ppn[35:4], entries[i].req_info.vpn[3:0]} : resp_pte[i].ppn};
    end
  end

  // ===========================================================================
  // §9 条目与状态更新（异步复位域）—— 按 Chisel when 顺序转写，后写者赢
  // ===========================================================================
  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      for (int i = 0; i < N_ENTRY; i++) begin
        entries[i] <= '0;
        state[i]   <= S_IDLE;
      end
      REG                      <= 1'b0;
      mem_resp_hit             <= '0;
      need_addr_check_last_REG <= 1'b0;
    end else begin
      for (int i = 0; i < N_ENTRY; i++) begin
        // (1) 普通入队
        if (enq_normal_hit[i]) begin
          state[i]                     <= enq_state;
          entries[i].req_info          <= '{vpn: io_in_bits_req_info_vpn, s2xlate: io_in_bits_req_info_s2xlate,
                                            source: io_in_bits_req_info_source};
          entries[i].ppn               <= (to_bitmap_req | to_last_hptw_req | last_hptw_excp) ? last_hptw_req_ppn : io_in_bits_ppn;
          entries[i].wait_id           <= to_wait ? wait_id : enq_ptr;
          entries[i].af                <= 1'b0;
          entries[i].cf                <= 1'b0;
          entries[i].from_l0           <= 1'b0;
          entries[i].way_info          <= 4'h0;
          entries[i].jmp_bitmap_check  <= 1'b0;
          entries[i].ptes              <= '0;
          entries[i].cfs               <= in_cfs;
          entries[i].n                 <= in_resp_pte.n;
          entries[i].hptw_resp         <= enq_hptw_resp;
          entries[i].hptw_resp.gpf     <= last_hptw_excp & last_hptw_gStagePf;
          entries[i].first_s2xlate_fault <= 1'b0;
          mem_resp_hit[i]              <= to_bitmap_req | to_mem_out | to_last_hptw_req;
        end
        // (2) bitmap 跳转入队：PTE 已经在手，只差 bitmap 检查
        if (enq_jmp_hit[i]) begin
          state[i]                     <= S_BITMAP_CHECK;
          entries[i].req_info          <= '{vpn: io_in_bits_req_info_vpn, s2xlate: io_in_bits_req_info_s2xlate,
                                            source: io_in_bits_req_info_source};
          entries[i].ppn               <= {8'h0, jmp_pte.ppn};
          entries[i].wait_id           <= enq_ptr;
          entries[i].af                <= 1'b0;
          entries[i].cf                <= 1'b0;
          entries[i].from_l0           <= 1'b1;
          entries[i].way_info          <= io_in_bits_bitmapCheck_hitway;
          entries[i].jmp_bitmap_check  <= io_in_bits_bitmapCheck_jmp_bitmap_check;
          entries[i].n                 <= jmp_pte.n;
          entries[i].ptes              <= in_ptes;
          entries[i].cfs               <= in_cfs;
          entries[i].first_s2xlate_fault <= 1'b0;
          mem_resp_hit[i]              <= 1'b0;
        end
        // (3) 第一次 HPTW 请求被仲裁出去
        if (hyper1_hit[i]) begin
          state[i]           <= S_HPTW_RESP;
          entries[i].wait_id <= hyper_arb1_chosen;
        end
        // (4) PMP(0)：入队后一拍的地址检查结果
        if (pmp0_hit[i]) begin
          entries[i].af <= accessFault0;
          state[i]      <= accessFault0 ? S_MEM_OUT : S_MEM_REQ;
        end
        // (5) PMP(1)：HPTW 翻译后的地址检查结果
        if (pmp1_hit[i]) begin
          entries[i].af <= accessFault1;
          state[i]      <= accessFault1 ? S_MEM_OUT : S_MEM_REQ;
        end
        // (6) mem_arb 发出请求：同扇区的其它条目一起进 mem_waiting
        if (mem_arb_dup_hit[i]) begin
          state[i]             <= S_MEM_WAITING;
          entries[i].hptw_resp <= wait_by_chosen_hptw_resp;
          entries[i].wait_id   <= mem_arb_chosen;
        end
        // (7) 访存响应到达
        if (mem_resp_take[i]) begin
          state[i]                 <= mem_resp_next_state[i];
          mem_resp_hit[i]          <= 1'b1;
          entries[i].ppn           <= resp_leaf_ppn[i];
          entries[i].hptw_resp.gpf <= (entries[i].req_info.s2xlate == ALL_STAGE) & gStagePf[i];
          entries[i].n             <= resp_pte[i].n;
        end
        // (8) 最后一次 HPTW 请求被仲裁出去
        if (hyper2_hit[i]) begin
          state[i]           <= S_LAST_HPTW_RESP;
          entries[i].wait_id <= hyper_arb2_chosen;
        end
        // (9) bitmap 请求发出
        if (bitmap_arb_hit[i]) begin
          state[i]           <= S_BITMAP_RESP;
          entries[i].wait_id <= bitmap_arb_chosen;
        end
        // (10) bitmap 响应
        if (bitmap_resp_take[i]) begin
          entries[i].cfs <= in_bitmap_cfs;
          entries[i].cf  <= io_bitmap_resp_bits_cf;
          state[i]       <= S_MEM_OUT;
        end
        // (11) HPTW 响应
        if (hptw_resp_hit[i]) begin
          if (hptw_fault) begin
            state[i]                       <= S_MEM_OUT;
            entries[i].hptw_resp           <= in_h_resp;
            entries[i].hptw_resp.gpf       <= io_hptw_resp_bits_h_resp_gpf | check_g_perm_fail;
            entries[i].first_s2xlate_fault <= hptw_fault;
          end else begin
            state[i]             <= (|need_to_waiting_vec) ? S_MEM_WAITING : S_ADDR_CHECK;
            entries[i].hptw_resp <= in_h_resp;
            entries[i].wait_id   <= (|need_to_waiting_vec) ? waiting_index : entries[i].wait_id;
          end
        end
        if (last_hptw_resp_hit[i]) begin
          state[i]             <= S_MEM_OUT;
          entries[i].hptw_resp <= in_h_resp;
        end
        // (12) 出队 / (13) 回 PtwCache 重查 / (14) flush
        if (out_fire   & (mem_ptr   == 3'(i))) state[i] <= S_IDLE;
        if (cache_fire & (cache_ptr == 3'(i))) state[i] <= S_IDLE;
        if (mem_resp_hit[i]) mem_resp_hit[i] <= 1'b0;   // 只保持一拍
        if (flush) state[i] <= S_IDLE;
      end
      // golden 只在 XSError（`ifndef SYNTHESIS）里读它；照存，不省
      REG                      <= dup_req_fire & (|dup_vec_wait);
      need_addr_check_last_REG <= (enq_state == S_ADDR_CHECK) & in_fire & ~flush
                                & ~io_in_bits_bitmapCheck_jmp_bitmap_check;
    end
  end

  always_comb begin
    wait_by_chosen_hptw_resp = entries[0].hptw_resp;
    for (int i = 1; i < N_ENTRY; i++)
      if (mem_arb_chosen == 3'(i)) wait_by_chosen_hptw_resp = entries[i].hptw_resp;
  end

  // ===========================================================================
  // §10 不复位域：addr / hpaddr / way_info / refill id / perf
  // ===========================================================================
  // HPTW 响应对应条目的 GPA = MakeGPAddr(entries(id).ppn, vpn[8:0])，再用 genPPNS2 翻成主机地址
  logic [49:0] hptw_gpaddr;
  assign hptw_gpaddr = 50'({hptw_resp_entry.ppn, 12'h0} + {hptw_resp_entry.req_info.vpn[8:0], 3'h0});
  always_ff @(posedge clock) begin
    enq_ptr_reg              <= enq_ptr;
    hptw_resp_ptr_reg        <= io_hptw_resp_bits_id;
    hptw_need_addr_check_REG <= has_hptw_resp & io_hptw_resp_valid & ~flush;
    if (io_hptw_resp_valid)
      hpaddr <= {gen_ppn_s2(in_h_resp.entry, hptw_gpaddr[49:12]), hptw_gpaddr[11:0]};
    if (in_fire)
      addr <= {io_in_bits_ppn[35:0], io_in_bits_req_info_vpn[8:0], 3'h0};
    for (int i = 0; i < N_ENTRY; i++)
      if (mem_resp_hit[i]) way_info_r[i] <= io_l0_way_info;
    mem_refill_id <= io_mem_resp_bits_id;
    // perf：入队数 / 阻塞数 / 访存数 / 在等访存的条目数，各打两拍
    io_perf_0_value_REG   <= in_fire;
    io_perf_0_value_REG_1 <= io_perf_0_value_REG;
    io_perf_1_value_REG   <= io_in_valid & full;
    io_perf_1_value_REG_1 <= io_perf_1_value_REG;
    io_perf_2_value_REG   <= io_mem_req_ready & io_mem_req_valid;
    io_perf_2_value_REG_1 <= io_perf_2_value_REG;
    io_perf_3_value_REG   <= 3'($countones(is_waiting));
    io_perf_3_value_REG_1 <= io_perf_3_value_REG;
  end

  // ===========================================================================
  // §11 输出装配
  // ===========================================================================
  assign io_in_ready   = ~full;
  assign io_out_valid  = |is_having;
  assign out_fire      = io_out_ready & io_out_valid;
  assign io_out_bits_req_info_vpn     = out_entry.req_info.vpn;
  assign io_out_bits_req_info_s2xlate = out_entry.req_info.s2xlate;
  assign io_out_bits_req_info_source  = out_entry.req_info.source;
  assign io_out_bits_id               = {1'b0, mem_ptr};
  assign io_out_bits_h_resp_entry_tag    = out_entry.hptw_resp.entry.tag;
  assign io_out_bits_h_resp_entry_vmid   = out_entry.hptw_resp.entry.vmid;
  assign io_out_bits_h_resp_entry_n      = out_entry.hptw_resp.entry.n;
  assign io_out_bits_h_resp_entry_pbmt   = out_entry.hptw_resp.entry.pbmt;
  assign io_out_bits_h_resp_entry_ppn    = out_entry.hptw_resp.entry.ppn;
  assign io_out_bits_h_resp_entry_perm_d = out_entry.hptw_resp.entry.perm_d;
  assign io_out_bits_h_resp_entry_perm_a = out_entry.hptw_resp.entry.perm_a;
  assign io_out_bits_h_resp_entry_perm_g = out_entry.hptw_resp.entry.perm_g;
  assign io_out_bits_h_resp_entry_perm_u = out_entry.hptw_resp.entry.perm_u;
  assign io_out_bits_h_resp_entry_perm_x = out_entry.hptw_resp.entry.perm_x;
  assign io_out_bits_h_resp_entry_perm_w = out_entry.hptw_resp.entry.perm_w;
  assign io_out_bits_h_resp_entry_perm_r = out_entry.hptw_resp.entry.perm_r;
  assign io_out_bits_h_resp_entry_level  = out_entry.hptw_resp.entry.level;
  assign io_out_bits_h_resp_gpf          = out_entry.hptw_resp.gpf;
  assign io_out_bits_h_resp_gaf          = out_entry.hptw_resp.gaf;
  assign io_out_bits_first_s2xlate_fault = out_entry.first_s2xlate_fault;
  // bitmap 使能时，bitmap 检查失败也按 access fault 上报
  assign io_out_bits_af = (bitmap_enable & out_entry.cf) | out_entry.af;
  assign io_out_bits_bitmapCheck_jmp_bitmap_check = out_entry.jmp_bitmap_check;
  assign io_out_bits_bitmapCheck_ptes_0 = out_entry.ptes[0];
  assign io_out_bits_bitmapCheck_ptes_1 = out_entry.ptes[1];
  assign io_out_bits_bitmapCheck_ptes_2 = out_entry.ptes[2];
  assign io_out_bits_bitmapCheck_ptes_3 = out_entry.ptes[3];
  assign io_out_bits_bitmapCheck_ptes_4 = out_entry.ptes[4];
  assign io_out_bits_bitmapCheck_ptes_5 = out_entry.ptes[5];
  assign io_out_bits_bitmapCheck_ptes_6 = out_entry.ptes[6];
  assign io_out_bits_bitmapCheck_ptes_7 = out_entry.ptes[7];
  assign io_out_bits_bitmapCheck_cfs_0  = out_entry.cfs[0];
  assign io_out_bits_bitmapCheck_cfs_1  = out_entry.cfs[1];
  assign io_out_bits_bitmapCheck_cfs_2  = out_entry.cfs[2];
  assign io_out_bits_bitmapCheck_cfs_3  = out_entry.cfs[3];
  assign io_out_bits_bitmapCheck_cfs_4  = out_entry.cfs[4];
  assign io_out_bits_bitmapCheck_cfs_5  = out_entry.cfs[5];
  assign io_out_bits_bitmapCheck_cfs_6  = out_entry.cfs[6];
  assign io_out_bits_bitmapCheck_cfs_7  = out_entry.cfs[7];

  // 访存地址：allStage 时页表页 ppn 先经 hptw_resp 的 genPPNS2 翻成主机 ppn
  logic [37:0] mem_hppn;
  assign mem_hppn = gen_ppn_s2(mem_arb_out.hptw, mem_arb_out.ppn[35:0]);
  assign io_mem_req_valid     = mem_arb_out_valid & ~flush;
  assign io_mem_req_bits_addr = {(mem_arb_out.req_info.s2xlate == ALL_STAGE) ? mem_hppn[35:0] : mem_arb_out.ppn[35:0],
                                 mem_arb_out.req_info.vpn[8:0], 3'h0};
  assign io_mem_req_bits_id   = {1'b0, mem_arb_chosen};
  assign io_mem_enq_ptr       = enq_ptr;
  assign io_mem_buffer_it_0   = mem_resp_hit[0];
  assign io_mem_buffer_it_1   = mem_resp_hit[1];
  assign io_mem_buffer_it_2   = mem_resp_hit[2];
  assign io_mem_buffer_it_3   = mem_resp_hit[3];
  assign io_mem_buffer_it_4   = mem_resp_hit[4];
  assign io_mem_buffer_it_5   = mem_resp_hit[5];
  assign io_mem_refill_vpn     = refill_entry.req_info.vpn;
  assign io_mem_refill_s2xlate = refill_entry.req_info.s2xlate;
  assign io_mem_refill_source  = refill_entry.req_info.source;

  // 回 PtwCache 重查：ParallelMux（按位或）
  req_info_t cache_bits;
  always_comb begin
    cache_bits = '0;
    for (int i = 0; i < N_ENTRY; i++) cache_bits |= is_cache[i] ? entries[i].req_info : '0;
  end
  assign io_cache_valid        = |is_cache;
  assign cache_fire            = io_cache_ready & io_cache_valid;
  assign io_cache_bits_vpn     = cache_bits.vpn;
  assign io_cache_bits_s2xlate = cache_bits.s2xlate;
  assign io_cache_bits_source  = cache_bits.source;

  assign io_pmp_0_req_bits_addr = addr;
  assign io_pmp_1_req_bits_addr = hpaddr[47:0];

  assign io_hptw_req_valid = io_hptw_req_ready & hptw_req_arb_out_valid & ~flush;

  assign io_bitmap_req_valid      = bitmap_arb_out_valid & ~flush;
  assign io_bitmap_req_bits_bmppn = bitmap_arb_bmppn;
  assign io_bitmap_req_bits_id    = bitmap_arb_chosen;
  assign io_bitmap_resp_ready     = has_bitmap_resp;

  assign io_perf_0_value = {5'h0, io_perf_0_value_REG_1};
  assign io_perf_1_value = {5'h0, io_perf_1_value_REG_1};
  assign io_perf_2_value = {5'h0, io_perf_2_value_REG_1};
  assign io_perf_3_value = {3'h0, io_perf_3_value_REG_1};

endmodule

// BEGIN GENERATED(wrapper) —— 由 gen_mmu5.py 生成：LLPTW 的 golden 同名 wrapper，
// 端口与 G1 golden 逐位同名，纯透传到 xs_LLPTW_core（无任何逻辑）。
module LLPTW(
  input  logic         clock,
  input  logic         reset,
  input  logic         io_sfence_valid,
  input  logic         io_csr_satp_changed,
  input  logic         io_csr_vsatp_changed,
  input  logic [3:0]   io_csr_hgatp_mode,
  input  logic         io_csr_hgatp_changed,
  input  logic         io_csr_mbmc_BME,
  input  logic         io_csr_mbmc_CMODE,
  input  logic         io_csr_priv_virt_changed,
  input  logic         io_csr_mPBMTE,
  input  logic         io_csr_hPBMTE,
  output logic         io_in_ready,
  input  logic         io_in_valid,
  input  logic [37:0]  io_in_bits_req_info_vpn,
  input  logic [1:0]   io_in_bits_req_info_s2xlate,
  input  logic [1:0]   io_in_bits_req_info_source,
  input  logic [43:0]  io_in_bits_ppn,
  input  logic         io_in_bits_bitmapCheck_jmp_bitmap_check,
  input  logic [63:0]  io_in_bits_bitmapCheck_ptes_0,
  input  logic [63:0]  io_in_bits_bitmapCheck_ptes_1,
  input  logic [63:0]  io_in_bits_bitmapCheck_ptes_2,
  input  logic [63:0]  io_in_bits_bitmapCheck_ptes_3,
  input  logic [63:0]  io_in_bits_bitmapCheck_ptes_4,
  input  logic [63:0]  io_in_bits_bitmapCheck_ptes_5,
  input  logic [63:0]  io_in_bits_bitmapCheck_ptes_6,
  input  logic [63:0]  io_in_bits_bitmapCheck_ptes_7,
  input  logic         io_in_bits_bitmapCheck_cfs_0,
  input  logic         io_in_bits_bitmapCheck_cfs_1,
  input  logic         io_in_bits_bitmapCheck_cfs_2,
  input  logic         io_in_bits_bitmapCheck_cfs_3,
  input  logic         io_in_bits_bitmapCheck_cfs_4,
  input  logic         io_in_bits_bitmapCheck_cfs_5,
  input  logic         io_in_bits_bitmapCheck_cfs_6,
  input  logic         io_in_bits_bitmapCheck_cfs_7,
  input  logic [3:0]   io_in_bits_bitmapCheck_hitway,
  input  logic         io_out_ready,
  output logic         io_out_valid,
  output logic [37:0]  io_out_bits_req_info_vpn,
  output logic [1:0]   io_out_bits_req_info_s2xlate,
  output logic [1:0]   io_out_bits_req_info_source,
  output logic [3:0]   io_out_bits_id,
  output logic [37:0]  io_out_bits_h_resp_entry_tag,
  output logic [13:0]  io_out_bits_h_resp_entry_vmid,
  output logic         io_out_bits_h_resp_entry_n,
  output logic [1:0]   io_out_bits_h_resp_entry_pbmt,
  output logic [37:0]  io_out_bits_h_resp_entry_ppn,
  output logic         io_out_bits_h_resp_entry_perm_d,
  output logic         io_out_bits_h_resp_entry_perm_a,
  output logic         io_out_bits_h_resp_entry_perm_g,
  output logic         io_out_bits_h_resp_entry_perm_u,
  output logic         io_out_bits_h_resp_entry_perm_x,
  output logic         io_out_bits_h_resp_entry_perm_w,
  output logic         io_out_bits_h_resp_entry_perm_r,
  output logic [1:0]   io_out_bits_h_resp_entry_level,
  output logic         io_out_bits_h_resp_gpf,
  output logic         io_out_bits_h_resp_gaf,
  output logic         io_out_bits_first_s2xlate_fault,
  output logic         io_out_bits_af,
  output logic         io_out_bits_bitmapCheck_jmp_bitmap_check,
  output logic [63:0]  io_out_bits_bitmapCheck_ptes_0,
  output logic [63:0]  io_out_bits_bitmapCheck_ptes_1,
  output logic [63:0]  io_out_bits_bitmapCheck_ptes_2,
  output logic [63:0]  io_out_bits_bitmapCheck_ptes_3,
  output logic [63:0]  io_out_bits_bitmapCheck_ptes_4,
  output logic [63:0]  io_out_bits_bitmapCheck_ptes_5,
  output logic [63:0]  io_out_bits_bitmapCheck_ptes_6,
  output logic [63:0]  io_out_bits_bitmapCheck_ptes_7,
  output logic         io_out_bits_bitmapCheck_cfs_0,
  output logic         io_out_bits_bitmapCheck_cfs_1,
  output logic         io_out_bits_bitmapCheck_cfs_2,
  output logic         io_out_bits_bitmapCheck_cfs_3,
  output logic         io_out_bits_bitmapCheck_cfs_4,
  output logic         io_out_bits_bitmapCheck_cfs_5,
  output logic         io_out_bits_bitmapCheck_cfs_6,
  output logic         io_out_bits_bitmapCheck_cfs_7,
  input  logic         io_mem_req_ready,
  output logic         io_mem_req_valid,
  output logic [47:0]  io_mem_req_bits_addr,
  output logic [3:0]   io_mem_req_bits_id,
  input  logic         io_mem_resp_valid,
  input  logic [2:0]   io_mem_resp_bits_id,
  input  logic [511:0] io_mem_resp_bits_value,
  output logic [2:0]   io_mem_enq_ptr,
  output logic         io_mem_buffer_it_0,
  output logic         io_mem_buffer_it_1,
  output logic         io_mem_buffer_it_2,
  output logic         io_mem_buffer_it_3,
  output logic         io_mem_buffer_it_4,
  output logic         io_mem_buffer_it_5,
  output logic [37:0]  io_mem_refill_vpn,
  output logic [1:0]   io_mem_refill_s2xlate,
  output logic [1:0]   io_mem_refill_source,
  input  logic         io_mem_req_mask_0,
  input  logic         io_mem_req_mask_1,
  input  logic         io_mem_req_mask_2,
  input  logic         io_mem_req_mask_3,
  input  logic         io_mem_req_mask_4,
  input  logic         io_mem_req_mask_5,
  input  logic         io_mem_flush_latch_0,
  input  logic         io_mem_flush_latch_1,
  input  logic         io_mem_flush_latch_2,
  input  logic         io_mem_flush_latch_3,
  input  logic         io_mem_flush_latch_4,
  input  logic         io_mem_flush_latch_5,
  input  logic         io_cache_ready,
  output logic         io_cache_valid,
  output logic [37:0]  io_cache_bits_vpn,
  output logic [1:0]   io_cache_bits_s2xlate,
  output logic [1:0]   io_cache_bits_source,
  output logic [47:0]  io_pmp_0_req_bits_addr,
  input  logic         io_pmp_0_resp_ld,
  input  logic         io_pmp_0_resp_mmio,
  output logic [47:0]  io_pmp_1_req_bits_addr,
  input  logic         io_pmp_1_resp_ld,
  input  logic         io_pmp_1_resp_mmio,
  input  logic         io_hptw_req_ready,
  output logic         io_hptw_req_valid,
  output logic [1:0]   io_hptw_req_bits_source,
  output logic [2:0]   io_hptw_req_bits_id,
  output logic [43:0]  io_hptw_req_bits_gvpn,
  input  logic         io_hptw_resp_valid,
  input  logic [2:0]   io_hptw_resp_bits_id,
  input  logic [37:0]  io_hptw_resp_bits_h_resp_entry_tag,
  input  logic [13:0]  io_hptw_resp_bits_h_resp_entry_vmid,
  input  logic         io_hptw_resp_bits_h_resp_entry_n,
  input  logic [1:0]   io_hptw_resp_bits_h_resp_entry_pbmt,
  input  logic [37:0]  io_hptw_resp_bits_h_resp_entry_ppn,
  input  logic         io_hptw_resp_bits_h_resp_entry_perm_d,
  input  logic         io_hptw_resp_bits_h_resp_entry_perm_a,
  input  logic         io_hptw_resp_bits_h_resp_entry_perm_g,
  input  logic         io_hptw_resp_bits_h_resp_entry_perm_u,
  input  logic         io_hptw_resp_bits_h_resp_entry_perm_x,
  input  logic         io_hptw_resp_bits_h_resp_entry_perm_w,
  input  logic         io_hptw_resp_bits_h_resp_entry_perm_r,
  input  logic [1:0]   io_hptw_resp_bits_h_resp_entry_level,
  input  logic         io_hptw_resp_bits_h_resp_gpf,
  input  logic         io_hptw_resp_bits_h_resp_gaf,
  input  logic         io_bitmap_req_ready,
  output logic         io_bitmap_req_valid,
  output logic [35:0]  io_bitmap_req_bits_bmppn,
  output logic [2:0]   io_bitmap_req_bits_id,
  output logic [37:0]  io_bitmap_req_bits_vpn,
  output logic [3:0]   io_bitmap_req_bits_way_info,
  output logic [1:0]   io_bitmap_req_bits_s2xlate,
  output logic         io_bitmap_req_bits_n,
  output logic         io_bitmap_resp_ready,
  input  logic         io_bitmap_resp_valid,
  input  logic         io_bitmap_resp_bits_cf,
  input  logic         io_bitmap_resp_bits_cfs_0,
  input  logic         io_bitmap_resp_bits_cfs_1,
  input  logic         io_bitmap_resp_bits_cfs_2,
  input  logic         io_bitmap_resp_bits_cfs_3,
  input  logic         io_bitmap_resp_bits_cfs_4,
  input  logic         io_bitmap_resp_bits_cfs_5,
  input  logic         io_bitmap_resp_bits_cfs_6,
  input  logic         io_bitmap_resp_bits_cfs_7,
  input  logic [2:0]   io_bitmap_resp_bits_id,
  input  logic [3:0]   io_l0_way_info,
  output logic [5:0]   io_perf_0_value,
  output logic [5:0]   io_perf_1_value,
  output logic [5:0]   io_perf_2_value,
  output logic [5:0]   io_perf_3_value
);
  xs_LLPTW_core u_core (
    .clock                                    (clock),
    .reset                                    (reset),
    .io_sfence_valid                          (io_sfence_valid),
    .io_csr_satp_changed                      (io_csr_satp_changed),
    .io_csr_vsatp_changed                     (io_csr_vsatp_changed),
    .io_csr_hgatp_mode                        (io_csr_hgatp_mode),
    .io_csr_hgatp_changed                     (io_csr_hgatp_changed),
    .io_csr_mbmc_BME                          (io_csr_mbmc_BME),
    .io_csr_mbmc_CMODE                        (io_csr_mbmc_CMODE),
    .io_csr_priv_virt_changed                 (io_csr_priv_virt_changed),
    .io_csr_mPBMTE                            (io_csr_mPBMTE),
    .io_csr_hPBMTE                            (io_csr_hPBMTE),
    .io_in_ready                              (io_in_ready),
    .io_in_valid                              (io_in_valid),
    .io_in_bits_req_info_vpn                  (io_in_bits_req_info_vpn),
    .io_in_bits_req_info_s2xlate              (io_in_bits_req_info_s2xlate),
    .io_in_bits_req_info_source               (io_in_bits_req_info_source),
    .io_in_bits_ppn                           (io_in_bits_ppn),
    .io_in_bits_bitmapCheck_jmp_bitmap_check  (io_in_bits_bitmapCheck_jmp_bitmap_check),
    .io_in_bits_bitmapCheck_ptes_0            (io_in_bits_bitmapCheck_ptes_0),
    .io_in_bits_bitmapCheck_ptes_1            (io_in_bits_bitmapCheck_ptes_1),
    .io_in_bits_bitmapCheck_ptes_2            (io_in_bits_bitmapCheck_ptes_2),
    .io_in_bits_bitmapCheck_ptes_3            (io_in_bits_bitmapCheck_ptes_3),
    .io_in_bits_bitmapCheck_ptes_4            (io_in_bits_bitmapCheck_ptes_4),
    .io_in_bits_bitmapCheck_ptes_5            (io_in_bits_bitmapCheck_ptes_5),
    .io_in_bits_bitmapCheck_ptes_6            (io_in_bits_bitmapCheck_ptes_6),
    .io_in_bits_bitmapCheck_ptes_7            (io_in_bits_bitmapCheck_ptes_7),
    .io_in_bits_bitmapCheck_cfs_0             (io_in_bits_bitmapCheck_cfs_0),
    .io_in_bits_bitmapCheck_cfs_1             (io_in_bits_bitmapCheck_cfs_1),
    .io_in_bits_bitmapCheck_cfs_2             (io_in_bits_bitmapCheck_cfs_2),
    .io_in_bits_bitmapCheck_cfs_3             (io_in_bits_bitmapCheck_cfs_3),
    .io_in_bits_bitmapCheck_cfs_4             (io_in_bits_bitmapCheck_cfs_4),
    .io_in_bits_bitmapCheck_cfs_5             (io_in_bits_bitmapCheck_cfs_5),
    .io_in_bits_bitmapCheck_cfs_6             (io_in_bits_bitmapCheck_cfs_6),
    .io_in_bits_bitmapCheck_cfs_7             (io_in_bits_bitmapCheck_cfs_7),
    .io_in_bits_bitmapCheck_hitway            (io_in_bits_bitmapCheck_hitway),
    .io_out_ready                             (io_out_ready),
    .io_out_valid                             (io_out_valid),
    .io_out_bits_req_info_vpn                 (io_out_bits_req_info_vpn),
    .io_out_bits_req_info_s2xlate             (io_out_bits_req_info_s2xlate),
    .io_out_bits_req_info_source              (io_out_bits_req_info_source),
    .io_out_bits_id                           (io_out_bits_id),
    .io_out_bits_h_resp_entry_tag             (io_out_bits_h_resp_entry_tag),
    .io_out_bits_h_resp_entry_vmid            (io_out_bits_h_resp_entry_vmid),
    .io_out_bits_h_resp_entry_n               (io_out_bits_h_resp_entry_n),
    .io_out_bits_h_resp_entry_pbmt            (io_out_bits_h_resp_entry_pbmt),
    .io_out_bits_h_resp_entry_ppn             (io_out_bits_h_resp_entry_ppn),
    .io_out_bits_h_resp_entry_perm_d          (io_out_bits_h_resp_entry_perm_d),
    .io_out_bits_h_resp_entry_perm_a          (io_out_bits_h_resp_entry_perm_a),
    .io_out_bits_h_resp_entry_perm_g          (io_out_bits_h_resp_entry_perm_g),
    .io_out_bits_h_resp_entry_perm_u          (io_out_bits_h_resp_entry_perm_u),
    .io_out_bits_h_resp_entry_perm_x          (io_out_bits_h_resp_entry_perm_x),
    .io_out_bits_h_resp_entry_perm_w          (io_out_bits_h_resp_entry_perm_w),
    .io_out_bits_h_resp_entry_perm_r          (io_out_bits_h_resp_entry_perm_r),
    .io_out_bits_h_resp_entry_level           (io_out_bits_h_resp_entry_level),
    .io_out_bits_h_resp_gpf                   (io_out_bits_h_resp_gpf),
    .io_out_bits_h_resp_gaf                   (io_out_bits_h_resp_gaf),
    .io_out_bits_first_s2xlate_fault          (io_out_bits_first_s2xlate_fault),
    .io_out_bits_af                           (io_out_bits_af),
    .io_out_bits_bitmapCheck_jmp_bitmap_check (io_out_bits_bitmapCheck_jmp_bitmap_check),
    .io_out_bits_bitmapCheck_ptes_0           (io_out_bits_bitmapCheck_ptes_0),
    .io_out_bits_bitmapCheck_ptes_1           (io_out_bits_bitmapCheck_ptes_1),
    .io_out_bits_bitmapCheck_ptes_2           (io_out_bits_bitmapCheck_ptes_2),
    .io_out_bits_bitmapCheck_ptes_3           (io_out_bits_bitmapCheck_ptes_3),
    .io_out_bits_bitmapCheck_ptes_4           (io_out_bits_bitmapCheck_ptes_4),
    .io_out_bits_bitmapCheck_ptes_5           (io_out_bits_bitmapCheck_ptes_5),
    .io_out_bits_bitmapCheck_ptes_6           (io_out_bits_bitmapCheck_ptes_6),
    .io_out_bits_bitmapCheck_ptes_7           (io_out_bits_bitmapCheck_ptes_7),
    .io_out_bits_bitmapCheck_cfs_0            (io_out_bits_bitmapCheck_cfs_0),
    .io_out_bits_bitmapCheck_cfs_1            (io_out_bits_bitmapCheck_cfs_1),
    .io_out_bits_bitmapCheck_cfs_2            (io_out_bits_bitmapCheck_cfs_2),
    .io_out_bits_bitmapCheck_cfs_3            (io_out_bits_bitmapCheck_cfs_3),
    .io_out_bits_bitmapCheck_cfs_4            (io_out_bits_bitmapCheck_cfs_4),
    .io_out_bits_bitmapCheck_cfs_5            (io_out_bits_bitmapCheck_cfs_5),
    .io_out_bits_bitmapCheck_cfs_6            (io_out_bits_bitmapCheck_cfs_6),
    .io_out_bits_bitmapCheck_cfs_7            (io_out_bits_bitmapCheck_cfs_7),
    .io_mem_req_ready                         (io_mem_req_ready),
    .io_mem_req_valid                         (io_mem_req_valid),
    .io_mem_req_bits_addr                     (io_mem_req_bits_addr),
    .io_mem_req_bits_id                       (io_mem_req_bits_id),
    .io_mem_resp_valid                        (io_mem_resp_valid),
    .io_mem_resp_bits_id                      (io_mem_resp_bits_id),
    .io_mem_resp_bits_value                   (io_mem_resp_bits_value),
    .io_mem_enq_ptr                           (io_mem_enq_ptr),
    .io_mem_buffer_it_0                       (io_mem_buffer_it_0),
    .io_mem_buffer_it_1                       (io_mem_buffer_it_1),
    .io_mem_buffer_it_2                       (io_mem_buffer_it_2),
    .io_mem_buffer_it_3                       (io_mem_buffer_it_3),
    .io_mem_buffer_it_4                       (io_mem_buffer_it_4),
    .io_mem_buffer_it_5                       (io_mem_buffer_it_5),
    .io_mem_refill_vpn                        (io_mem_refill_vpn),
    .io_mem_refill_s2xlate                    (io_mem_refill_s2xlate),
    .io_mem_refill_source                     (io_mem_refill_source),
    .io_mem_req_mask_0                        (io_mem_req_mask_0),
    .io_mem_req_mask_1                        (io_mem_req_mask_1),
    .io_mem_req_mask_2                        (io_mem_req_mask_2),
    .io_mem_req_mask_3                        (io_mem_req_mask_3),
    .io_mem_req_mask_4                        (io_mem_req_mask_4),
    .io_mem_req_mask_5                        (io_mem_req_mask_5),
    .io_mem_flush_latch_0                     (io_mem_flush_latch_0),
    .io_mem_flush_latch_1                     (io_mem_flush_latch_1),
    .io_mem_flush_latch_2                     (io_mem_flush_latch_2),
    .io_mem_flush_latch_3                     (io_mem_flush_latch_3),
    .io_mem_flush_latch_4                     (io_mem_flush_latch_4),
    .io_mem_flush_latch_5                     (io_mem_flush_latch_5),
    .io_cache_ready                           (io_cache_ready),
    .io_cache_valid                           (io_cache_valid),
    .io_cache_bits_vpn                        (io_cache_bits_vpn),
    .io_cache_bits_s2xlate                    (io_cache_bits_s2xlate),
    .io_cache_bits_source                     (io_cache_bits_source),
    .io_pmp_0_req_bits_addr                   (io_pmp_0_req_bits_addr),
    .io_pmp_0_resp_ld                         (io_pmp_0_resp_ld),
    .io_pmp_0_resp_mmio                       (io_pmp_0_resp_mmio),
    .io_pmp_1_req_bits_addr                   (io_pmp_1_req_bits_addr),
    .io_pmp_1_resp_ld                         (io_pmp_1_resp_ld),
    .io_pmp_1_resp_mmio                       (io_pmp_1_resp_mmio),
    .io_hptw_req_ready                        (io_hptw_req_ready),
    .io_hptw_req_valid                        (io_hptw_req_valid),
    .io_hptw_req_bits_source                  (io_hptw_req_bits_source),
    .io_hptw_req_bits_id                      (io_hptw_req_bits_id),
    .io_hptw_req_bits_gvpn                    (io_hptw_req_bits_gvpn),
    .io_hptw_resp_valid                       (io_hptw_resp_valid),
    .io_hptw_resp_bits_id                     (io_hptw_resp_bits_id),
    .io_hptw_resp_bits_h_resp_entry_tag       (io_hptw_resp_bits_h_resp_entry_tag),
    .io_hptw_resp_bits_h_resp_entry_vmid      (io_hptw_resp_bits_h_resp_entry_vmid),
    .io_hptw_resp_bits_h_resp_entry_n         (io_hptw_resp_bits_h_resp_entry_n),
    .io_hptw_resp_bits_h_resp_entry_pbmt      (io_hptw_resp_bits_h_resp_entry_pbmt),
    .io_hptw_resp_bits_h_resp_entry_ppn       (io_hptw_resp_bits_h_resp_entry_ppn),
    .io_hptw_resp_bits_h_resp_entry_perm_d    (io_hptw_resp_bits_h_resp_entry_perm_d),
    .io_hptw_resp_bits_h_resp_entry_perm_a    (io_hptw_resp_bits_h_resp_entry_perm_a),
    .io_hptw_resp_bits_h_resp_entry_perm_g    (io_hptw_resp_bits_h_resp_entry_perm_g),
    .io_hptw_resp_bits_h_resp_entry_perm_u    (io_hptw_resp_bits_h_resp_entry_perm_u),
    .io_hptw_resp_bits_h_resp_entry_perm_x    (io_hptw_resp_bits_h_resp_entry_perm_x),
    .io_hptw_resp_bits_h_resp_entry_perm_w    (io_hptw_resp_bits_h_resp_entry_perm_w),
    .io_hptw_resp_bits_h_resp_entry_perm_r    (io_hptw_resp_bits_h_resp_entry_perm_r),
    .io_hptw_resp_bits_h_resp_entry_level     (io_hptw_resp_bits_h_resp_entry_level),
    .io_hptw_resp_bits_h_resp_gpf             (io_hptw_resp_bits_h_resp_gpf),
    .io_hptw_resp_bits_h_resp_gaf             (io_hptw_resp_bits_h_resp_gaf),
    .io_bitmap_req_ready                      (io_bitmap_req_ready),
    .io_bitmap_req_valid                      (io_bitmap_req_valid),
    .io_bitmap_req_bits_bmppn                 (io_bitmap_req_bits_bmppn),
    .io_bitmap_req_bits_id                    (io_bitmap_req_bits_id),
    .io_bitmap_req_bits_vpn                   (io_bitmap_req_bits_vpn),
    .io_bitmap_req_bits_way_info              (io_bitmap_req_bits_way_info),
    .io_bitmap_req_bits_s2xlate               (io_bitmap_req_bits_s2xlate),
    .io_bitmap_req_bits_n                     (io_bitmap_req_bits_n),
    .io_bitmap_resp_ready                     (io_bitmap_resp_ready),
    .io_bitmap_resp_valid                     (io_bitmap_resp_valid),
    .io_bitmap_resp_bits_cf                   (io_bitmap_resp_bits_cf),
    .io_bitmap_resp_bits_cfs_0                (io_bitmap_resp_bits_cfs_0),
    .io_bitmap_resp_bits_cfs_1                (io_bitmap_resp_bits_cfs_1),
    .io_bitmap_resp_bits_cfs_2                (io_bitmap_resp_bits_cfs_2),
    .io_bitmap_resp_bits_cfs_3                (io_bitmap_resp_bits_cfs_3),
    .io_bitmap_resp_bits_cfs_4                (io_bitmap_resp_bits_cfs_4),
    .io_bitmap_resp_bits_cfs_5                (io_bitmap_resp_bits_cfs_5),
    .io_bitmap_resp_bits_cfs_6                (io_bitmap_resp_bits_cfs_6),
    .io_bitmap_resp_bits_cfs_7                (io_bitmap_resp_bits_cfs_7),
    .io_bitmap_resp_bits_id                   (io_bitmap_resp_bits_id),
    .io_l0_way_info                           (io_l0_way_info),
    .io_perf_0_value                          (io_perf_0_value),
    .io_perf_1_value                          (io_perf_1_value),
    .io_perf_2_value                          (io_perf_2_value),
    .io_perf_3_value                          (io_perf_3_value)
  );
endmodule
// END GENERATED(wrapper)
