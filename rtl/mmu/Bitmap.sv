// Bitmap.sv —— 页位图检查器（Bitmap Checker）：对每个走表得到的物理页做一次"位图检查"——
// 从内存里的页位图（mbmc.BMA 指向，每位对应一个 4KB 页）读出该页的 check-failed 位，
// 失败的页按 access fault 处理。这是 G1 新增的机制（HasBitmapCheck）。
//
// 本文件含：xs_bitmap_pkg（状态编码/几何）+ xs_Bitmap_core（可读重写核）+ Bitmap（golden
// 同名 wrapper，75 端口透传）。共享 PTE 常量来自 rtl/mmu/mmu_common_pkg.sv。
// 对应 Chisel: xiangshan.cache.mmu.Bitmap（BitmapCheck.scala 第 104 行起）；
// 对照 golden = G1-canonical/golden-rtl/Bitmap.sv（3349 行，单变体）。
//
// 【它在 L2TLB 里的位置】
//   PTW / LLPTW / HPTW 拿到叶子 PTE 后（bitmap 使能时）把 {ppn, vpn, level, n, …} 发来；
//   本模块先查 BitmapCache（io.cache），未命中才经 PMP 检查后去内存读 64 位位图
//   （io.mem，一次带回 512 位 = 8 个 64 位字），读回后经 io.refill 写进 BitmapCache，
//   并把 cf（本页失败位）与 cfs（同一 8 页扇区的 8 位）回给请求者（io.resp），
//   level==0 且非 napot、非 bypass 的结果还广播一份 wakeup 给 PtwCache 更新 l0 的位图副本。
//
// 【条目池：8 个条目（llptwsize+2），每个条目一台 7 态状态机】
//   idle ─req.fire─▶ addr_check ─PMP 通过─▶ cache_req ─arb 出队─▶ cache_resp
//        ─cache 命中─▶ mem_out；未命中 ─▶ mem_req ─mem_arb 出队─▶ mem_waiting ─mem.resp─▶ mem_out
//   mem_out 的条目按最低编号优先（mem_ptr）回应；resp.fire 后回 idle。
//   PMP 报 access fault 的条目直接 mem_out，cf/cfs 全 1。
//
// 【去重（dup）—— 同一 64 位位图字只发一次访存】
//   dupBitmapPPN 比的是 ppn[35:5]（★golden 就是 [35:5] 而不是 [35:6]，照抄★）。
//   入队 / cache 未命中时：若已有条目在 mem_waiting 等同一个字 → 本条目也进 mem_waiting，
//   wait_id 记那个条目的 wait_id（它就是访存 id 的低 3 位）；若正好本拍 mem_arb 发出同字
//   的请求 → wait_id = mem_arb.chosen；若正好本拍访存响应带回同字 → 直接 mem_out 并取位。
//   访存 id = chosen + 8（0..7 给 LLPTW/PTW/HPTW，8..15 给本模块）；响应按 id[2:0] 对号。
//
// 【有效 ppn（getRealPPN）】按 level 把 ppn 的低位换成 vpn 的低位（大页展开成 4KB 页号）：
//   level 3/2/1 换低 27/18/9 位；level 0 且 napot 换低 4 位。KEYIDEN 在本配置下不存在。
//   位图地址 = (BMA<<6) + (eppn>>6)<<3；eppn[8:6] 选 512 位里的哪个 64 位字，
//   eppn[5:0] 选 cf 位，eppn[5:3] 选 8 位扇区 cfs。
//
// 【复位域（golden 实测）】
//   异步复位（全 0）：entries_* 全部字段（★含 data/vpn 等载荷，RegInit(0)★）、state×8、
//   wakeup_stall、io_wakeup_valid_valid（ValidHoldBypass 的保持位）。
//   不复位：enq_ptr_reg、need_addr_check、io_pmp_req_bits_addr_r（★64 位——golden 存了
//   完整 64 位和，只输出低 48 位，高 16 位无人读；照抄，不裁★）、wakeup 载荷保持寄存器 ×6。
//
// 【子模块】
//   RRArbiterInit mem_arb —— 8 入轮转仲裁（rtl/common/RRArbiterInit.sv 重写件，与 golden 同变体：
//                            8 入 / ppn 36 位 / 有 out_ready / 有 chosen）
//   Arbiter8_bitmapCacheReqBundle cache_req_arb —— 8 入固定优先级仲裁（golden 同源，两侧同一份）
//
// 【本文件导航】
//   §1 常量与全局控制   §2 寄存器   §3 条目状态解码/指针   §4 有效 ppn 与去重
//   §5 cache 响应/访存响应对号   §6 状态机（异步复位域）   §7 不复位寄存器
//   §8 仲裁器例化   §9 输出
package xs_bitmap_pkg;
  localparam int N_ENTRIES = 8;              // l2tlbParams.llptwsize + 2
  localparam int ENTRY_W   = 3;
  localparam int PPN_W     = 36;
  localparam int VPN_W     = 38;
  localparam int BMA_W     = 58;             // mbmc.BMA
  localparam int WORD_W    = 64;             // XLEN：一个位图字
  localparam int WORDS_PER_LINE = 8;         // blockBits / XLEN
  localparam int SECTOR_N  = 8;              // tlbcontiguous

  // 条目状态（Enum 顺序即编码，golden 用 3'h0..3'h6）
  typedef enum logic [2:0] {
    S_IDLE        = 3'd0,
    S_ADDR_CHECK  = 3'd1,   // 等 PMP 检查结果（入队后一拍）
    S_CACHE_REQ   = 3'd2,   // 排队向 BitmapCache 发请求
    S_CACHE_RESP  = 3'd3,   // 等 BitmapCache 响应
    S_MEM_REQ     = 3'd4,   // 排队发访存
    S_MEM_WAITING = 3'd5,   // 等访存响应（自己发的或搭别人的）
    S_MEM_OUT     = 3'd6    // 结果就绪，等回应
  } state_e;

  // 同一个 64 位位图字：golden 比 ppn[35:5]（dupBitmapPPN）
  function automatic logic dup_bitmap_ppn(input logic [PPN_W-1:0] a, input logic [PPN_W-1:0] b);
    return a[PPN_W-1:5] == b[PPN_W-1:5];
  endfunction

  // 有效 ppn（getRealPPN）：按 level 把 ppn 低位换成 vpn 低位
  function automatic logic [PPN_W-1:0] real_ppn(input logic [PPN_W-1:0] ppn, input logic [VPN_W-1:0] vpn,
                                                input logic [1:0] level, input logic n);
    return (level == 2'd3) ? {ppn[35:27], vpn[26:0]}
         : (level == 2'd2) ? {ppn[35:18], vpn[17:0]}
         : (level == 2'd1) ? {ppn[35:9],  vpn[8:0]}
         : n               ? {ppn[35:4],  vpn[3:0]}
         :                   ppn;
  endfunction

  // 512 位访存响应里取 eppn 对应的 64 位位图字（getBitmapAddr(ppn)[5:3] = ppn[8:6]）
  function automatic logic [WORD_W-1:0] bitmap_word(input logic [511:0] line, input logic [PPN_W-1:0] ppn);
    return line[ppn[8:6]*WORD_W +: WORD_W];
  endfunction

  // 位图字里本页的 cf 位 / 本 8 页扇区的 cfs
  function automatic logic word_cf(input logic [WORD_W-1:0] word, input logic [PPN_W-1:0] ppn);
    return word[ppn[5:0]];
  endfunction
  function automatic logic [SECTOR_N-1:0] word_cfs(input logic [WORD_W-1:0] word, input logic [PPN_W-1:0] ppn);
    return word[ppn[5:3]*SECTOR_N +: SECTOR_N];
  endfunction
endpackage

module xs_Bitmap_core
  import xs_bitmap_pkg::*;
(
  // BEGIN GENERATED(core_ports) —— 由 gen_mmu5.py 从 golden 端口表逐根抄出
  input  logic         clock,
  input  logic         reset,
  input  logic         io_sfence_valid,
  input  logic         io_csr_satp_changed,
  input  logic         io_csr_vsatp_changed,
  input  logic         io_csr_hgatp_changed,
  input  logic [57:0]  io_csr_mbmc_BMA,
  input  logic         io_csr_priv_virt_changed,
  input  logic         io_mem_req_ready,
  output logic         io_mem_req_valid,
  output logic [47:0]  io_mem_req_bits_addr,
  output logic [3:0]   io_mem_req_bits_id,
  input  logic         io_mem_resp_valid,
  input  logic [3:0]   io_mem_resp_bits_id,
  input  logic [511:0] io_mem_resp_bits_value,
  input  logic         io_mem_req_mask_0,
  input  logic         io_mem_req_mask_1,
  input  logic         io_mem_req_mask_2,
  input  logic         io_mem_req_mask_3,
  input  logic         io_mem_req_mask_4,
  input  logic         io_mem_req_mask_5,
  input  logic         io_mem_req_mask_6,
  input  logic         io_mem_req_mask_7,
  output logic         io_req_ready,
  input  logic         io_req_valid,
  input  logic [35:0]  io_req_bits_bmppn,
  input  logic [2:0]   io_req_bits_id,
  input  logic [37:0]  io_req_bits_vpn,
  input  logic [1:0]   io_req_bits_level,
  input  logic [3:0]   io_req_bits_way_info,
  input  logic         io_req_bits_hptw_bypassed,
  input  logic [1:0]   io_req_bits_s2xlate,
  input  logic         io_req_bits_n,
  input  logic         io_resp_ready,
  output logic         io_resp_valid,
  output logic         io_resp_bits_cf,
  output logic         io_resp_bits_cfs_0,
  output logic         io_resp_bits_cfs_1,
  output logic         io_resp_bits_cfs_2,
  output logic         io_resp_bits_cfs_3,
  output logic         io_resp_bits_cfs_4,
  output logic         io_resp_bits_cfs_5,
  output logic         io_resp_bits_cfs_6,
  output logic         io_resp_bits_cfs_7,
  output logic [2:0]   io_resp_bits_id,
  output logic [47:0]  io_pmp_req_bits_addr,
  input  logic         io_pmp_resp_ld,
  input  logic         io_pmp_resp_mmio,
  input  logic         io_wakeup_ready,
  output logic         io_wakeup_valid,
  output logic [5:0]   io_wakeup_bits_setIndex,
  output logic [37:0]  io_wakeup_bits_tag,
  output logic [3:0]   io_wakeup_bits_way_info,
  output logic [2:0]   io_wakeup_bits_pte_index,
  output logic         io_wakeup_bits_check_success,
  output logic [1:0]   io_wakeup_bits_s2xlate,
  input  logic         io_cache_req_ready,
  output logic         io_cache_req_valid,
  output logic [7:0]   io_cache_req_bits_order,
  output logic [35:0]  io_cache_req_bits_tag,
  output logic         io_cache_resp_ready,
  input  logic         io_cache_resp_valid,
  input  logic         io_cache_resp_bits_hit,
  input  logic         io_cache_resp_bits_cfs_0,
  input  logic         io_cache_resp_bits_cfs_1,
  input  logic         io_cache_resp_bits_cfs_2,
  input  logic         io_cache_resp_bits_cfs_3,
  input  logic         io_cache_resp_bits_cfs_4,
  input  logic         io_cache_resp_bits_cfs_5,
  input  logic         io_cache_resp_bits_cfs_6,
  input  logic         io_cache_resp_bits_cfs_7,
  input  logic [7:0]   io_cache_resp_bits_order,
  output logic         io_refill_valid,
  output logic [35:0]  io_refill_bits_tag,
  output logic [63:0]  io_refill_bits_data
  // END GENERATED(core_ports)
);

  // ===========================================================================
  // §1 常量与全局控制
  // ===========================================================================
  logic flush;
  assign flush = io_sfence_valid | io_csr_satp_changed | io_csr_vsatp_changed
               | io_csr_hgatp_changed | io_csr_priv_virt_changed;

  // ===========================================================================
  // §2 寄存器
  // ===========================================================================
  // ---- 异步复位域（全 0）：条目池 ----
  logic [PPN_W-1:0]    entries_ppn      [N_ENTRIES];
  logic [VPN_W-1:0]    entries_vpn      [N_ENTRIES];
  logic [1:0]          entries_s2xlate  [N_ENTRIES];
  logic [3:0]          entries_id       [N_ENTRIES];   // bMemID 4 位，高位恒 0（请求 id 只有 3 位）
  logic [ENTRY_W-1:0]  entries_wait_id  [N_ENTRIES];   // 搭哪个条目的访存（= 访存 id 低 3 位）
  logic                entries_cf       [N_ENTRIES];   // 本页检查失败
  logic                entries_hit      [N_ENTRIES];   // 结果不是自己访存来的 → 不回填 BitmapCache
  logic [SECTOR_N-1:0] entries_cfs      [N_ENTRIES];   // 同扇区 8 页的失败位
  logic [1:0]          entries_level    [N_ENTRIES];
  logic [3:0]          entries_way_info [N_ENTRIES];
  logic                entries_hptw_bypassed [N_ENTRIES];
  logic                entries_n        [N_ENTRIES];
  logic [WORD_W-1:0]   entries_data     [N_ENTRIES];   // 自己访存读回的位图字（回填用）
  state_e              state            [N_ENTRIES];
  logic                wakeup_stall;                   // wakeup 没被接走前压住 resp
  logic                io_wakeup_valid_valid;          // ValidHoldBypass(wakeup_valid_1cycle, wakeup.ready)
  // ---- 不复位域 ----
  logic [ENTRY_W-1:0]  enq_ptr_reg;                    // 上一拍入队的条目（PMP 结果对号用）
  logic                need_addr_check;                // 上一拍入队且需要 PMP 检查
  logic [63:0]         io_pmp_req_bits_addr_r;         // RegEnable(getBitmapAddr(req_real_ppn), req.fire)
  logic [5:0]          io_wakeup_bits_setIndex_r;      // DataHoldBypass 保持寄存器 ×6
  logic [VPN_W-1:0]    io_wakeup_bits_tag_r;
  logic [3:0]          io_wakeup_bits_way_info_r;
  logic [2:0]          io_wakeup_bits_pte_index_r;
  logic                io_wakeup_bits_check_success_r;
  logic [1:0]          io_wakeup_bits_s2xlate_r;

  // ===========================================================================
  // §3 条目状态解码与指针
  // ===========================================================================
  logic [N_ENTRIES-1:0] is_empty, is_cache_req, is_cache_resp, is_mem_req, is_waiting, is_having;
  logic                 full, waiting, cache_wait;
  logic [ENTRY_W-1:0]   enq_ptr;   // 最低编号的空条目（ParallelPriorityEncoder）
  logic [ENTRY_W-1:0]   mem_ptr;   // 最低编号的 mem_out 条目
  always_comb begin
    for (int i = 0; i < N_ENTRIES; i++) begin
      is_empty[i]      = (state[i] == S_IDLE);
      is_cache_req[i]  = (state[i] == S_CACHE_REQ);
      is_cache_resp[i] = (state[i] == S_CACHE_RESP);
      is_mem_req[i]    = (state[i] == S_MEM_REQ);
      is_waiting[i]    = (state[i] == S_MEM_WAITING);
      is_having[i]     = (state[i] == S_MEM_OUT);
    end
    full       = ~|is_empty;
    waiting    = |is_waiting;
    cache_wait = |is_cache_resp;
    enq_ptr = ENTRY_W'(N_ENTRIES - 1);
    mem_ptr = ENTRY_W'(N_ENTRIES - 1);
    for (int i = N_ENTRIES - 1; i >= 0; i--) begin
      if (is_empty[i])  enq_ptr = ENTRY_W'(i);
      if (is_having[i]) mem_ptr = ENTRY_W'(i);
    end
  end

  // ===========================================================================
  // §4 握手、有效 ppn 与入队去重
  // ===========================================================================
  logic              req_fire;              // io.req.fire（golden _io_pmp_req_bits_addr_T_4_probe）
  logic [PPN_W-1:0]  req_real_ppn;
  logic              mem_arb_out_valid, cache_arb_out_valid;
  logic [PPN_W-1:0]  mem_arb_out_ppn;
  logic [ENTRY_W-1:0] mem_arb_chosen, cache_arb_chosen;
  logic              mem_req_fire;          // mem_arb.io.out.fire（golden _cm_dup_req_fire_T_28；★不含 ~flush★）
  logic              mem_resp_fire;         // io.mem.resp.fire = waiting & valid（golden _cm_dup_wait_resp_T_28）
  logic              cache_req_fire;        // cache_req_arb.io.out.fire（golden _GEN_67）
  logic              cache_resp_fire;       // io.cache.resp.fire（golden _GEN_1）
  logic              io_resp_valid_0, resp_fire;
  logic              io_cache_resp_ready_0;
  logic              accessFault;           // PMP 结果

  assign req_fire        = ~full & io_req_valid;
  assign req_real_ppn    = real_ppn(io_req_bits_bmppn, io_req_bits_vpn, io_req_bits_level, io_req_bits_n);
  assign mem_req_fire    = io_mem_req_ready & mem_arb_out_valid;
  assign mem_resp_fire   = waiting & io_mem_resp_valid;
  assign cache_req_fire  = io_cache_req_ready & cache_arb_out_valid;
  assign io_cache_resp_ready_0 = ~flush & cache_wait;
  assign cache_resp_fire = io_cache_resp_ready_0 & io_cache_resp_valid;
  assign resp_fire       = io_resp_ready & io_resp_valid_0;
  assign accessFault     = io_pmp_resp_ld | io_pmp_resp_mmio;

  // 入队请求与在飞条目的去重
  logic [N_ENTRIES-1:0] dup_vec_wait;     // 哪些 mem_waiting 条目等的正是这个字
  logic                 dup_req_fire;     // 本拍 mem_arb 正发出这个字的请求
  logic                 dup_wait_resp;    // 本拍访存响应带回的正是这个字
  logic                 to_wait;
  logic [ENTRY_W-1:0]   wait_id;
  state_e               enq_state;
  always_comb begin
    for (int i = 0; i < N_ENTRIES; i++)
      dup_vec_wait[i] = dup_bitmap_ppn(req_real_ppn, entries_ppn[i]) & is_waiting[i];
    dup_req_fire  = mem_req_fire & dup_bitmap_ppn(req_real_ppn, mem_arb_out_ppn);
    dup_wait_resp = mem_resp_fire & dup_vec_wait[io_mem_resp_bits_id[ENTRY_W-1:0]];
    to_wait       = (|dup_vec_wait) | dup_req_fire;
    // ParallelMux：命中的 wait_id 按位或（同一个字的等待者 wait_id 相同）
    wait_id = '0;
    for (int i = 0; i < N_ENTRIES; i++)
      wait_id |= dup_vec_wait[i] ? entries_wait_id[i] : '0;
    if (dup_req_fire) wait_id = mem_arb_chosen;
    enq_state = dup_wait_resp ? S_MEM_OUT : to_wait ? S_MEM_WAITING : S_ADDR_CHECK;
  end

  // 入队那拍若响应正好带回同字，直接从响应里取位
  logic [WORD_W-1:0] req_word;
  assign req_word = bitmap_word(io_mem_resp_bits_value, req_real_ppn);

  // ===========================================================================
  // §5 cache 响应对号（cm_*）与访存响应对号
  // ===========================================================================
  logic [N_ENTRIES-1:0] cache_resp_for;    // 本拍 cache 响应属于条目 i（golden _GEN_2.._GEN_9）
  logic                 hit;               // 响应命中（对所有条目同一根线，照 Chisel 的 WireInit）
  logic [SECTOR_N-1:0]  cache_resp_cfs;
  logic [N_ENTRIES-1:0] cm_dup_vec_wait   [N_ENTRIES];  // [i][j]：条目 j 在等条目 i 要的字
  logic [N_ENTRIES-1:0] cm_dup_req_fire, cm_dup_wait_resp, cm_to_wait;
  logic [ENTRY_W-1:0]   cm_wait_id        [N_ENTRIES];
  logic [N_ENTRIES-1:0] mem_resp_for;      // 访存响应 id 对上条目 i 的 wait_id
  logic [WORD_W-1:0]    entry_word        [N_ENTRIES];  // 响应里条目 i 那个字
  assign cache_resp_cfs = {io_cache_resp_bits_cfs_7, io_cache_resp_bits_cfs_6, io_cache_resp_bits_cfs_5,
                           io_cache_resp_bits_cfs_4, io_cache_resp_bits_cfs_3, io_cache_resp_bits_cfs_2,
                           io_cache_resp_bits_cfs_1, io_cache_resp_bits_cfs_0};
  always_comb begin
    for (int i = 0; i < N_ENTRIES; i++) begin
      cache_resp_for[i] = is_cache_resp[i] & (io_cache_resp_bits_order == 8'(i));
      for (int j = 0; j < N_ENTRIES; j++)
        cm_dup_vec_wait[i][j] = dup_bitmap_ppn(entries_ppn[i], entries_ppn[j]) & is_waiting[j];
      cm_dup_req_fire[i]  = mem_req_fire & dup_bitmap_ppn(entries_ppn[i], mem_arb_out_ppn);
      cm_dup_wait_resp[i] = mem_resp_fire & cm_dup_vec_wait[i][io_mem_resp_bits_id[ENTRY_W-1:0]];
      cm_to_wait[i]       = (|cm_dup_vec_wait[i]) | cm_dup_req_fire[i];
      cm_wait_id[i] = '0;
      for (int j = 0; j < N_ENTRIES; j++)
        cm_wait_id[i] |= cm_dup_vec_wait[i][j] ? entries_wait_id[j] : '0;
      if (cm_dup_req_fire[i]) cm_wait_id[i] = mem_arb_chosen;
      // 访存 id = wait_id + 8（golden 写成 {1'h0,wait_id} - 4'h8，模 16 同值）
      mem_resp_for[i] = mem_resp_fire & is_waiting[i]
                      & (io_mem_resp_bits_id == {1'b1, entries_wait_id[i]});
      entry_word[i]   = bitmap_word(io_mem_resp_bits_value, entries_ppn[i]);
    end
    hit = cache_resp_fire & (|cache_resp_for) & io_cache_resp_bits_hit;
  end

  // ===========================================================================
  // §6 状态机（异步复位域）—— 按 Chisel 的 when 顺序转写，后写者赢
  // ===========================================================================
  logic wakeup_valid_1cycle, wakeup_fire;

  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      for (int i = 0; i < N_ENTRIES; i++) begin
        entries_ppn[i]      <= '0;
        entries_vpn[i]      <= '0;
        entries_s2xlate[i]  <= '0;
        entries_id[i]       <= '0;
        entries_wait_id[i]  <= '0;
        entries_cf[i]       <= 1'b0;
        entries_hit[i]      <= 1'b0;
        entries_cfs[i]      <= '0;
        entries_level[i]    <= '0;
        entries_way_info[i] <= '0;
        entries_hptw_bypassed[i] <= 1'b0;
        entries_n[i]        <= 1'b0;
        entries_data[i]     <= '0;
        state[i]            <= S_IDLE;
      end
      wakeup_stall          <= 1'b0;
      io_wakeup_valid_valid <= 1'b0;
    end else begin
      for (int i = 0; i < N_ENTRIES; i++) begin
        // (1) 入队
        if (req_fire & (enq_ptr == ENTRY_W'(i))) begin
          state[i]            <= enq_state;
          entries_ppn[i]      <= req_real_ppn;
          entries_vpn[i]      <= io_req_bits_vpn;
          entries_id[i]       <= {1'b0, io_req_bits_id};
          entries_wait_id[i]  <= to_wait ? wait_id : enq_ptr;
          entries_cf[i]       <= dup_wait_resp ? word_cf(req_word, req_real_ppn)  : 1'b0;
          entries_cfs[i]      <= dup_wait_resp ? word_cfs(req_word, req_real_ppn) : '0;
          entries_hit[i]      <= to_wait | dup_wait_resp;
          entries_level[i]    <= io_req_bits_level;
          entries_way_info[i] <= io_req_bits_way_info;
          entries_hptw_bypassed[i] <= io_req_bits_hptw_bypassed;
          entries_n[i]        <= io_req_bits_n;
          entries_s2xlate[i]  <= io_req_bits_s2xlate;
        end
        // (2) PMP 结果：失败按 cf 全 1 直接出结果，否则去查 BitmapCache
        if (need_addr_check & (enq_ptr_reg == ENTRY_W'(i))) begin
          entries_cf[i]  <= accessFault;
          entries_cfs[i] <= {SECTOR_N{accessFault}};
          state[i]       <= accessFault ? S_MEM_OUT : S_CACHE_REQ;
        end
        // (3) cache 请求出队
        if (cache_req_fire & is_cache_req[i] & (cache_arb_chosen == ENTRY_W'(i)))
          state[i] <= S_CACHE_RESP;
        // (4) cache 响应：命中直接出结果；未命中再做一次去重后去访存
        if (cache_resp_fire & cache_resp_for[i]) begin
          if (hit) begin
            entries_cf[i]  <= cache_resp_cfs[entries_ppn[i][2:0]];
            entries_hit[i] <= 1'b1;
            entries_cfs[i] <= cache_resp_cfs;
            state[i]       <= S_MEM_OUT;
          end else begin
            state[i]           <= cm_dup_wait_resp[i] ? S_MEM_OUT : cm_to_wait[i] ? S_MEM_WAITING : S_MEM_REQ;
            entries_wait_id[i] <= cm_to_wait[i] ? cm_wait_id[i] : entries_wait_id[i];
            entries_hit[i]     <= cm_to_wait[i] | cm_dup_wait_resp[i];
            if (cm_dup_wait_resp[i]) begin
              entries_cf[i]  <= word_cf(entry_word[i], entries_ppn[i]);
              entries_cfs[i] <= word_cfs(entry_word[i], entries_ppn[i]);
            end
          end
        end
        // (5) 访存请求出队：等同一个字的 mem_req 条目一起进 waiting
        if (mem_req_fire & is_mem_req[i] & dup_bitmap_ppn(entries_ppn[i], mem_arb_out_ppn)) begin
          state[i]           <= S_MEM_WAITING;
          entries_wait_id[i] <= mem_arb_chosen;
        end
        // (6) 访存响应对号
        if (mem_resp_for[i]) begin
          state[i]        <= S_MEM_OUT;
          entries_data[i] <= entry_word[i];
          entries_cf[i]   <= word_cf(entry_word[i], entries_ppn[i]);
          entries_cfs[i]  <= word_cfs(entry_word[i], entries_ppn[i]);
        end
        // (7) 回应被接走
        if (resp_fire & (mem_ptr == ENTRY_W'(i)))
          state[i] <= S_IDLE;
        // (8) flush
        if (flush)
          state[i] <= S_IDLE;
      end
      wakeup_stall          <= ~wakeup_fire & (wakeup_valid_1cycle | wakeup_stall);
      io_wakeup_valid_valid <= ~io_wakeup_ready & (wakeup_valid_1cycle | io_wakeup_valid_valid);
    end
  end

  // ===========================================================================
  // §7 不复位寄存器
  // ===========================================================================
  always_ff @(posedge clock) begin
    enq_ptr_reg     <= enq_ptr;
    need_addr_check <= (enq_state == S_ADDR_CHECK) & req_fire & ~flush;
    if (req_fire)
      io_pmp_req_bits_addr_r <= 64'({io_csr_mbmc_BMA, 6'h0} + {31'h0, req_real_ppn[35:6], 3'h0});
    if (wakeup_valid_1cycle) begin
      io_wakeup_bits_setIndex_r      <= entries_vpn[mem_ptr][8:3];
      io_wakeup_bits_tag_r           <= entries_vpn[mem_ptr];
      io_wakeup_bits_way_info_r      <= entries_way_info[mem_ptr];
      io_wakeup_bits_pte_index_r     <= entries_vpn[mem_ptr][2:0];
      io_wakeup_bits_check_success_r <= ~entries_cf[mem_ptr];
      io_wakeup_bits_s2xlate_r       <= entries_s2xlate[mem_ptr];
    end
  end

  // ===========================================================================
  // §8 仲裁器例化
  // ===========================================================================
  RRArbiterInit mem_arb (
    .clock            (clock),
    .reset            (reset),
    .io_in_0_valid    (is_mem_req[0] & ~io_mem_req_mask_0),
    .io_in_0_bits_ppn (entries_ppn[0]),
    .io_in_1_valid    (is_mem_req[1] & ~io_mem_req_mask_1),
    .io_in_1_bits_ppn (entries_ppn[1]),
    .io_in_2_valid    (is_mem_req[2] & ~io_mem_req_mask_2),
    .io_in_2_bits_ppn (entries_ppn[2]),
    .io_in_3_valid    (is_mem_req[3] & ~io_mem_req_mask_3),
    .io_in_3_bits_ppn (entries_ppn[3]),
    .io_in_4_valid    (is_mem_req[4] & ~io_mem_req_mask_4),
    .io_in_4_bits_ppn (entries_ppn[4]),
    .io_in_5_valid    (is_mem_req[5] & ~io_mem_req_mask_5),
    .io_in_5_bits_ppn (entries_ppn[5]),
    .io_in_6_valid    (is_mem_req[6] & ~io_mem_req_mask_6),
    .io_in_6_bits_ppn (entries_ppn[6]),
    .io_in_7_valid    (is_mem_req[7] & ~io_mem_req_mask_7),
    .io_in_7_bits_ppn (entries_ppn[7]),
    .io_out_ready     (io_mem_req_ready),
    .io_out_valid     (mem_arb_out_valid),
    .io_out_bits_ppn  (mem_arb_out_ppn),
    .io_chosen        (mem_arb_chosen)
  );

  Arbiter8_bitmapCacheReqBundle cache_req_arb (
    .io_in_0_valid     (is_cache_req[0]),
    .io_in_0_bits_tag  (entries_ppn[0]),
    .io_in_1_valid     (is_cache_req[1]),
    .io_in_1_bits_tag  (entries_ppn[1]),
    .io_in_2_valid     (is_cache_req[2]),
    .io_in_2_bits_tag  (entries_ppn[2]),
    .io_in_3_valid     (is_cache_req[3]),
    .io_in_3_bits_tag  (entries_ppn[3]),
    .io_in_4_valid     (is_cache_req[4]),
    .io_in_4_bits_tag  (entries_ppn[4]),
    .io_in_5_valid     (is_cache_req[5]),
    .io_in_5_bits_tag  (entries_ppn[5]),
    .io_in_6_valid     (is_cache_req[6]),
    .io_in_6_bits_tag  (entries_ppn[6]),
    .io_in_7_valid     (is_cache_req[7]),
    .io_in_7_bits_tag  (entries_ppn[7]),
    .io_out_valid      (cache_arb_out_valid),
    .io_out_bits_order (io_cache_req_bits_order),
    .io_out_bits_tag   (io_cache_req_bits_tag),
    .io_chosen         (cache_arb_chosen)
  );

  // ===========================================================================
  // §9 输出
  // ===========================================================================
  // 回应：最低编号的 mem_out 条目；wakeup 没被接走时压住
  assign io_resp_valid_0 = (|is_having) & ~wakeup_stall;
  assign io_req_ready    = ~full;
  assign io_resp_valid   = io_resp_valid_0;
  assign io_resp_bits_cf = entries_cf[mem_ptr];
  assign io_resp_bits_cfs_0 = entries_cfs[mem_ptr][0];
  assign io_resp_bits_cfs_1 = entries_cfs[mem_ptr][1];
  assign io_resp_bits_cfs_2 = entries_cfs[mem_ptr][2];
  assign io_resp_bits_cfs_3 = entries_cfs[mem_ptr][3];
  assign io_resp_bits_cfs_4 = entries_cfs[mem_ptr][4];
  assign io_resp_bits_cfs_5 = entries_cfs[mem_ptr][5];
  assign io_resp_bits_cfs_6 = entries_cfs[mem_ptr][6];
  assign io_resp_bits_cfs_7 = entries_cfs[mem_ptr][7];
  assign io_resp_bits_id    = entries_id[mem_ptr][2:0];

  // 访存：地址 = (BMA<<6) + (ppn>>6)<<3，截 48 位；id = chosen + 8
  assign io_mem_req_valid     = mem_arb_out_valid & ~flush;
  assign io_mem_req_bits_addr = 48'({io_csr_mbmc_BMA[41:0], 6'h0} + {15'h0, mem_arb_out_ppn[35:6], 3'h0});
  assign io_mem_req_bits_id   = {1'b1, mem_arb_chosen};

  assign io_pmp_req_bits_addr = io_pmp_req_bits_addr_r[47:0];

  // wakeup：level 0、非 napot、非 bypass 的结果广播给 PtwCache 的 l0 位图副本
  assign wakeup_valid_1cycle = io_resp_valid_0 & ~entries_hptw_bypassed[mem_ptr]
                             & (entries_level[mem_ptr] == 2'd0) & ~entries_n[mem_ptr];
  assign io_wakeup_valid     = io_wakeup_valid_valid | wakeup_valid_1cycle;
  assign wakeup_fire         = io_wakeup_ready & io_wakeup_valid;
  assign io_wakeup_bits_setIndex      = wakeup_valid_1cycle ? entries_vpn[mem_ptr][8:3]     : io_wakeup_bits_setIndex_r;
  assign io_wakeup_bits_tag           = wakeup_valid_1cycle ? entries_vpn[mem_ptr]          : io_wakeup_bits_tag_r;
  assign io_wakeup_bits_way_info      = wakeup_valid_1cycle ? entries_way_info[mem_ptr]     : io_wakeup_bits_way_info_r;
  assign io_wakeup_bits_pte_index     = wakeup_valid_1cycle ? entries_vpn[mem_ptr][2:0]     : io_wakeup_bits_pte_index_r;
  assign io_wakeup_bits_check_success = wakeup_valid_1cycle ? ~entries_cf[mem_ptr]          : io_wakeup_bits_check_success_r;
  assign io_wakeup_bits_s2xlate       = wakeup_valid_1cycle ? entries_s2xlate[mem_ptr]      : io_wakeup_bits_s2xlate_r;

  assign io_cache_req_valid  = cache_arb_out_valid & ~flush;
  assign io_cache_resp_ready = io_cache_resp_ready_0;

  // 自己访存来的结果才回填 BitmapCache
  assign io_refill_valid     = io_resp_valid_0 & ~entries_hit[mem_ptr];
  assign io_refill_bits_tag  = entries_ppn[mem_ptr];
  assign io_refill_bits_data = entries_data[mem_ptr];

endmodule

// BEGIN GENERATED(wrapper) —— 由 gen_mmu5.py 生成：Bitmap 的 golden 同名 wrapper，
// 端口与 G1 golden 逐位同名，纯透传到 xs_Bitmap_core（无任何逻辑）。
module Bitmap(
  input  logic         clock,
  input  logic         reset,
  input  logic         io_sfence_valid,
  input  logic         io_csr_satp_changed,
  input  logic         io_csr_vsatp_changed,
  input  logic         io_csr_hgatp_changed,
  input  logic [57:0]  io_csr_mbmc_BMA,
  input  logic         io_csr_priv_virt_changed,
  input  logic         io_mem_req_ready,
  output logic         io_mem_req_valid,
  output logic [47:0]  io_mem_req_bits_addr,
  output logic [3:0]   io_mem_req_bits_id,
  input  logic         io_mem_resp_valid,
  input  logic [3:0]   io_mem_resp_bits_id,
  input  logic [511:0] io_mem_resp_bits_value,
  input  logic         io_mem_req_mask_0,
  input  logic         io_mem_req_mask_1,
  input  logic         io_mem_req_mask_2,
  input  logic         io_mem_req_mask_3,
  input  logic         io_mem_req_mask_4,
  input  logic         io_mem_req_mask_5,
  input  logic         io_mem_req_mask_6,
  input  logic         io_mem_req_mask_7,
  output logic         io_req_ready,
  input  logic         io_req_valid,
  input  logic [35:0]  io_req_bits_bmppn,
  input  logic [2:0]   io_req_bits_id,
  input  logic [37:0]  io_req_bits_vpn,
  input  logic [1:0]   io_req_bits_level,
  input  logic [3:0]   io_req_bits_way_info,
  input  logic         io_req_bits_hptw_bypassed,
  input  logic [1:0]   io_req_bits_s2xlate,
  input  logic         io_req_bits_n,
  input  logic         io_resp_ready,
  output logic         io_resp_valid,
  output logic         io_resp_bits_cf,
  output logic         io_resp_bits_cfs_0,
  output logic         io_resp_bits_cfs_1,
  output logic         io_resp_bits_cfs_2,
  output logic         io_resp_bits_cfs_3,
  output logic         io_resp_bits_cfs_4,
  output logic         io_resp_bits_cfs_5,
  output logic         io_resp_bits_cfs_6,
  output logic         io_resp_bits_cfs_7,
  output logic [2:0]   io_resp_bits_id,
  output logic [47:0]  io_pmp_req_bits_addr,
  input  logic         io_pmp_resp_ld,
  input  logic         io_pmp_resp_mmio,
  input  logic         io_wakeup_ready,
  output logic         io_wakeup_valid,
  output logic [5:0]   io_wakeup_bits_setIndex,
  output logic [37:0]  io_wakeup_bits_tag,
  output logic [3:0]   io_wakeup_bits_way_info,
  output logic [2:0]   io_wakeup_bits_pte_index,
  output logic         io_wakeup_bits_check_success,
  output logic [1:0]   io_wakeup_bits_s2xlate,
  input  logic         io_cache_req_ready,
  output logic         io_cache_req_valid,
  output logic [7:0]   io_cache_req_bits_order,
  output logic [35:0]  io_cache_req_bits_tag,
  output logic         io_cache_resp_ready,
  input  logic         io_cache_resp_valid,
  input  logic         io_cache_resp_bits_hit,
  input  logic         io_cache_resp_bits_cfs_0,
  input  logic         io_cache_resp_bits_cfs_1,
  input  logic         io_cache_resp_bits_cfs_2,
  input  logic         io_cache_resp_bits_cfs_3,
  input  logic         io_cache_resp_bits_cfs_4,
  input  logic         io_cache_resp_bits_cfs_5,
  input  logic         io_cache_resp_bits_cfs_6,
  input  logic         io_cache_resp_bits_cfs_7,
  input  logic [7:0]   io_cache_resp_bits_order,
  output logic         io_refill_valid,
  output logic [35:0]  io_refill_bits_tag,
  output logic [63:0]  io_refill_bits_data
);
  xs_Bitmap_core u_core (
    .clock                        (clock),
    .reset                        (reset),
    .io_sfence_valid              (io_sfence_valid),
    .io_csr_satp_changed          (io_csr_satp_changed),
    .io_csr_vsatp_changed         (io_csr_vsatp_changed),
    .io_csr_hgatp_changed         (io_csr_hgatp_changed),
    .io_csr_mbmc_BMA              (io_csr_mbmc_BMA),
    .io_csr_priv_virt_changed     (io_csr_priv_virt_changed),
    .io_mem_req_ready             (io_mem_req_ready),
    .io_mem_req_valid             (io_mem_req_valid),
    .io_mem_req_bits_addr         (io_mem_req_bits_addr),
    .io_mem_req_bits_id           (io_mem_req_bits_id),
    .io_mem_resp_valid            (io_mem_resp_valid),
    .io_mem_resp_bits_id          (io_mem_resp_bits_id),
    .io_mem_resp_bits_value       (io_mem_resp_bits_value),
    .io_mem_req_mask_0            (io_mem_req_mask_0),
    .io_mem_req_mask_1            (io_mem_req_mask_1),
    .io_mem_req_mask_2            (io_mem_req_mask_2),
    .io_mem_req_mask_3            (io_mem_req_mask_3),
    .io_mem_req_mask_4            (io_mem_req_mask_4),
    .io_mem_req_mask_5            (io_mem_req_mask_5),
    .io_mem_req_mask_6            (io_mem_req_mask_6),
    .io_mem_req_mask_7            (io_mem_req_mask_7),
    .io_req_ready                 (io_req_ready),
    .io_req_valid                 (io_req_valid),
    .io_req_bits_bmppn            (io_req_bits_bmppn),
    .io_req_bits_id               (io_req_bits_id),
    .io_req_bits_vpn              (io_req_bits_vpn),
    .io_req_bits_level            (io_req_bits_level),
    .io_req_bits_way_info         (io_req_bits_way_info),
    .io_req_bits_hptw_bypassed    (io_req_bits_hptw_bypassed),
    .io_req_bits_s2xlate          (io_req_bits_s2xlate),
    .io_req_bits_n                (io_req_bits_n),
    .io_resp_ready                (io_resp_ready),
    .io_resp_valid                (io_resp_valid),
    .io_resp_bits_cf              (io_resp_bits_cf),
    .io_resp_bits_cfs_0           (io_resp_bits_cfs_0),
    .io_resp_bits_cfs_1           (io_resp_bits_cfs_1),
    .io_resp_bits_cfs_2           (io_resp_bits_cfs_2),
    .io_resp_bits_cfs_3           (io_resp_bits_cfs_3),
    .io_resp_bits_cfs_4           (io_resp_bits_cfs_4),
    .io_resp_bits_cfs_5           (io_resp_bits_cfs_5),
    .io_resp_bits_cfs_6           (io_resp_bits_cfs_6),
    .io_resp_bits_cfs_7           (io_resp_bits_cfs_7),
    .io_resp_bits_id              (io_resp_bits_id),
    .io_pmp_req_bits_addr         (io_pmp_req_bits_addr),
    .io_pmp_resp_ld               (io_pmp_resp_ld),
    .io_pmp_resp_mmio             (io_pmp_resp_mmio),
    .io_wakeup_ready              (io_wakeup_ready),
    .io_wakeup_valid              (io_wakeup_valid),
    .io_wakeup_bits_setIndex      (io_wakeup_bits_setIndex),
    .io_wakeup_bits_tag           (io_wakeup_bits_tag),
    .io_wakeup_bits_way_info      (io_wakeup_bits_way_info),
    .io_wakeup_bits_pte_index     (io_wakeup_bits_pte_index),
    .io_wakeup_bits_check_success (io_wakeup_bits_check_success),
    .io_wakeup_bits_s2xlate       (io_wakeup_bits_s2xlate),
    .io_cache_req_ready           (io_cache_req_ready),
    .io_cache_req_valid           (io_cache_req_valid),
    .io_cache_req_bits_order      (io_cache_req_bits_order),
    .io_cache_req_bits_tag        (io_cache_req_bits_tag),
    .io_cache_resp_ready          (io_cache_resp_ready),
    .io_cache_resp_valid          (io_cache_resp_valid),
    .io_cache_resp_bits_hit       (io_cache_resp_bits_hit),
    .io_cache_resp_bits_cfs_0     (io_cache_resp_bits_cfs_0),
    .io_cache_resp_bits_cfs_1     (io_cache_resp_bits_cfs_1),
    .io_cache_resp_bits_cfs_2     (io_cache_resp_bits_cfs_2),
    .io_cache_resp_bits_cfs_3     (io_cache_resp_bits_cfs_3),
    .io_cache_resp_bits_cfs_4     (io_cache_resp_bits_cfs_4),
    .io_cache_resp_bits_cfs_5     (io_cache_resp_bits_cfs_5),
    .io_cache_resp_bits_cfs_6     (io_cache_resp_bits_cfs_6),
    .io_cache_resp_bits_cfs_7     (io_cache_resp_bits_cfs_7),
    .io_cache_resp_bits_order     (io_cache_resp_bits_order),
    .io_refill_valid              (io_refill_valid),
    .io_refill_bits_tag           (io_refill_bits_tag),
    .io_refill_bits_data          (io_refill_bits_data)
  );
endmodule
// END GENERATED(wrapper)
