// =============================================================================
// xs_ICacheMissUnit —— ICache Miss 处理单元（MSHR 管理 + TileLink 取指 + refill 回填）
//
// 对应 Chisel: xiangshan.frontend.icache.ICacheMissUnit（ICacheMissUnit.scala）
//
// 【它在前端的位置】
//   ICache 取指流水（MainPipe）在 s2 查 meta SRAM 后若 miss，把缺失的 cacheline
//   请求交给本单元；IPrefetch 流水也会下发预取请求。本单元负责：
//     1) 用 MSHR（Miss Status Holding Register）登记在途 miss，去重；
//     2) 经 TileLink A 通道向 L2 发 Get 取整条 cacheline；
//     3) 在 TileLink D 通道收 grant（分 refillCycles=2 个 beat 拼成 512b）；
//     4) refill 完成后把数据 + tag 写回 meta/data SRAM，并把命中结果回送 MainPipe
//        （fetch_resp），同时给 WayLookup 发 update（在外层 ICache 顶层连线）。
//
//        fetch_req    ─▶ fetchDemux    ─▶ [4 个 fetch MSHR] ───┐
//                                                              ├─▶ acquireArb ─▶ mem_acquire(A)
//        prefetch_req ─▶ prefetchDemux ─▶ [10 个 prefetch MSHR]┘   (fetch 优先)
//                                            ▲ priorityFIFO 记录预取入队顺序，按序发射
//
//        mem_grant(D) ─▶ 拼 beat ─▶ respDataReg(512b) ─▶ 写 SRAM + fetch_resp
//
// 【MSHR 是什么、为什么 14 个】
//   每个 MSHR 是一条在途 miss 的状态寄存器：记 {有效, 已发射, 被冲刷, blkPaddr,
//   vSetIdx, way}。共 nFetchMshr=4 + nPrefetchMshr=10 = 14 个，source id 0..13
//   就是 TileLink A 的 source（L2 grant 回来按 source 找回是哪条 MSHR）。
//   - fetch MSHR 优先级高于 prefetch（取指比预取急）；
//   - fetch MSHR 间 lower index 优先；
//   - prefetch MSHR 按「进入 MSHR 的先后」发射（用 priorityFIFO 记录顺序）。
//
// 【去重（lookUp）】
//   新 req 进来前，先拿它的 {blkPaddr,vSetIdx} 和所有 14 个 MSHR 比对：若已有在途
//   MSHR 命中（同一条 line 正在被取），就不再新开 MSHR，直接吞掉该 req（fetchHit /
//   prefetchHit）。额外地，若预取 req 与本拍 fetch req 撞同一条 line，预取也算命中
//   （prefetchHitFetchReq）——让 fetch 去取，预取不必重复。
//
// 【flush / fencei 的差异】
//   - io_fencei（FENCE.I 清 I$）：作用于全部 14 个 MSHR。
//   - io_flush（重定向冲刷）：只作用于 10 个 prefetch MSHR；fetch MSHR 不响应 flush
//     （取指 miss 已在途，结果仍要回填，避免反复 miss）。
//   被 flush/fencei 标记后：未发射的 MSHR 立即失效；已发射的等 L2 grant 回来才失效
//     （不能丢弃已经发出去的 TileLink 事务，否则 source 泄漏 / 协议违例）。
//
// 【corrupt（数据损坏）】
//   D 通道任一 beat 置 corrupt，则整条响应标记 corrupt：照常回送 MainPipe（修时序），
//   但不写 SRAM（write_sram_valid 含 ~corrupt）。
//
// 【为什么 flush/fencei 时仍发 fetch_resp】
//   见 Scala 注释：让 io_flush → s2_miss → s2_ready → ftq ready 这条路尽快放行（时序）。
//   下游 MainPipe/WayLookup 自己的 sx_valid 已被 flush 清掉，会丢弃这次无用响应。
//   但绝不能在 flush/fencei 时写 SRAM（write_sram_valid 额外 & ~flush & ~fencei）。
//
// 本模块为自包含可读实现：MSHR 用 struct 数组 + genvar 表达 14 个；仲裁/demux/FIFO
// 用清晰组合逻辑与纯函数，不例化 golden 网表子模块。
// =============================================================================
package xs_icache_miss_pkg;
  // ---- 容量/位宽参数（KunminghuV2 ICache）----
  localparam int unsigned N_FETCH_MSHR    = 4;   // nFetchMshr
  localparam int unsigned N_PREFETCH_MSHR = 10;  // nPrefetchMshr
  localparam int unsigned N_MSHR          = N_FETCH_MSHR + N_PREFETCH_MSHR; // 14
  localparam int unsigned SRC_W           = 4;   // log2(16)，TileLink source / MSHR id 宽
  // 数组按 2 的幂开槽（16），让「4-bit source/id 变量索引」永不越界——既避免仿真 X，
  // 也消除 Formality 的 index-out-of-bound 告警；多出的槽位（14、15）恒不被写也不被读。
  localparam int unsigned N_MSHR_SLOTS    = 16;

  localparam int unsigned BLK_PADDR_W = 42;  // PAddrBits-blockOffBits = 48-6
  localparam int unsigned IDX_BITS    = 8;   // vSetIdx 宽
  localparam int unsigned WAY_BITS    = 2;   // log2(nWays=4)
  localparam int unsigned N_WAYS      = 4;   // nWays，waymask 宽
  localparam int unsigned TAG_BITS    = 36;  // 物理 tag = blkPaddr[41:6]
  localparam int unsigned PADDR_W     = 48;  // PAddrBits，mem_acquire 地址宽
  localparam int unsigned BLK_OFF     = 6;   // log2(blockBytes=64)

  localparam int unsigned REFILL_CYCLES = 2;    // 512b cacheline / 256b beat = 2 个 beat
  localparam int unsigned BEAT_BITS     = 256;  // beatBits
  localparam int unsigned BLOCK_BITS    = 512;  // blockBits
  localparam int unsigned BEAT_CNT_W    = 1;    // log2up(REFILL_CYCLES)

  // TileLink Get 编码：opcode=4（Get），size=log2(64)=6
  localparam logic [2:0] TL_GET_OPCODE  = 3'd4;
  localparam logic [3:0] TL_GET_SIZE    = 4'd6;

  // ---- 一条 miss 请求（fetch / prefetch 共用）----
  typedef struct packed {
    logic [BLK_PADDR_W-1:0] blkPaddr;  // 块物理地址（去块内偏移）
    logic [IDX_BITS-1:0]    vSetIdx;   // 虚拟组索引
  } miss_req_t;

  // ---- 一个 MSHR entry ----
  //   valid   : 该 MSHR 占用，登记着一条在途 miss
  //   issued  : 对应 TileLink Get 已成功发出（等 L2 grant）
  //   killed  : 被 flush/fencei 标记（对应 Scala 的 flush||fencei 合并语义）；
  //             killed 后该 MSHR 不再对外 lookUp 命中、不再发 resp，
  //             但若已 issued 仍需保留 valid 直到 grant 回来才回收
  typedef struct packed {
    logic                   valid;
    logic                   issued;
    logic                   killed;
    logic [BLK_PADDR_W-1:0] blkPaddr;
    logic [IDX_BITS-1:0]    vSetIdx;
    logic [WAY_BITS-1:0]    way;       // acquire 发射时锁存的 victim way
  } mshr_t;

  // 物理 tag 提取：blkPaddr 去块内偏移后即整 blkPaddr（已是块地址），取高 TAG_BITS 位
  function automatic logic [TAG_BITS-1:0] get_phy_tag(input logic [BLK_PADDR_W-1:0] blk);
    return blk[BLK_PADDR_W-1 : (BLK_PADDR_W-TAG_BITS)];  // [41:6]
  endfunction

  // victim way（2b）→ one-hot waymask（4b）
  function automatic logic [N_WAYS-1:0] way_to_mask(input logic [WAY_BITS-1:0] w);
    return (N_WAYS'(1) << w);
  endfunction
endpackage


module xs_ICacheMissUnit
  import xs_icache_miss_pkg::*;
(
  input          clock,
  input          reset,

  // ---- 控制 ----
  input          io_fencei,       // FENCE.I：清全部 MSHR
  input          io_flush,        // 重定向冲刷：仅清 prefetch MSHR
  input          io_wfi_wfiReq,   // 请求进入 WFI（暂停发射新 acquire）
  output         io_wfi_wfiSafe,  // 无在途 L2 响应，可安全进入 WFI

  // ---- fetch 通道（← MainPipe），req:Decoupled / resp:Valid ----
  output         io_fetch_req_ready,
  input          io_fetch_req_valid,
  input  [41:0]  io_fetch_req_bits_blkPaddr,
  input  [7:0]   io_fetch_req_bits_vSetIdx,
  output         io_fetch_resp_valid,
  output [41:0]  io_fetch_resp_bits_blkPaddr,
  output [7:0]   io_fetch_resp_bits_vSetIdx,
  output [3:0]   io_fetch_resp_bits_waymask,
  output [511:0] io_fetch_resp_bits_data,
  output         io_fetch_resp_bits_corrupt,

  // ---- prefetch 通道（← IPrefetch），req:Decoupled ----
  output         io_prefetch_req_ready,
  input          io_prefetch_req_valid,
  input  [41:0]  io_prefetch_req_bits_blkPaddr,
  input  [7:0]   io_prefetch_req_bits_vSetIdx,

  // ---- meta / data SRAM 写口（refill 回填），Decoupled（下游恒 ready）----
  output         io_meta_write_valid,
  output [7:0]   io_meta_write_bits_virIdx,
  output [35:0]  io_meta_write_bits_phyTag,
  output [3:0]   io_meta_write_bits_waymask,
  output         io_meta_write_bits_bankIdx,
  output         io_data_write_valid,
  output [7:0]   io_data_write_bits_virIdx,
  output [511:0] io_data_write_bits_data,
  output [3:0]   io_data_write_bits_waymask,

  // ---- victim way（→/← replacer）：发 acquire 时索要 victim，下拍由 io_victim_way 返回 ----
  output         io_victim_vSetIdx_valid,
  output [7:0]   io_victim_vSetIdx_bits,
  input  [1:0]   io_victim_way,

  // ---- TileLink A（acquire，发 Get）/ D（grant，收数据）----
  input          io_mem_acquire_ready,
  output         io_mem_acquire_valid,
  output [3:0]   io_mem_acquire_bits_source,
  output [47:0]  io_mem_acquire_bits_address,
  input          io_mem_grant_valid,
  input  [3:0]   io_mem_grant_bits_opcode,
  input  [2:0]   io_mem_grant_bits_size,
  input  [3:0]   io_mem_grant_bits_source,
  input  [255:0] io_mem_grant_bits_data,
  input          io_mem_grant_bits_corrupt
);

  // ===========================================================================
  // 输入打包成 struct
  // ===========================================================================
  miss_req_t fetch_req, prefetch_req;
  assign fetch_req.blkPaddr    = io_fetch_req_bits_blkPaddr;
  assign fetch_req.vSetIdx     = io_fetch_req_bits_vSetIdx;
  assign prefetch_req.blkPaddr = io_prefetch_req_bits_blkPaddr;
  assign prefetch_req.vSetIdx  = io_prefetch_req_bits_vSetIdx;

  // ===========================================================================
  // MSHR 状态数组（14 个）
  //   索引 0..3       = fetch MSHR（source id 0..3）
  //   索引 4..13      = prefetch MSHR（source id 4..13）
  // ===========================================================================
  mshr_t mshr [N_MSHR_SLOTS];

  // 每个 MSHR 是否「响应 flush」：fetch 不响应，prefetch 响应（见模块头）
  function automatic bit mshr_obeys_flush(input int idx);
    return idx >= int'(N_FETCH_MSHR);
  endfunction

  // ===========================================================================
  // 去重 lookUp：把 fetch_req / prefetch_req 与每个有效 MSHR 比对
  //   killed 的 MSHR 不再命中（其 line 即将作废，应允许重新发起）
  // ===========================================================================
  function automatic bit mshr_lookup_hit(input mshr_t m, input miss_req_t q);
    return m.valid && !m.killed &&
           (m.vSetIdx == q.vSetIdx) && (m.blkPaddr == q.blkPaddr);
  endfunction

  logic [N_MSHR_SLOTS-1:0] fetch_lookup_hit;     // 各 MSHR 对 fetch_req 是否命中
  logic [N_MSHR_SLOTS-1:0] prefetch_lookup_hit;  // 各 MSHR 对 prefetch_req 是否命中
  always_comb begin
    fetch_lookup_hit    = '0;
    prefetch_lookup_hit = '0;
    for (int i = 0; i < N_MSHR; i++) begin
      fetch_lookup_hit[i]    = mshr_lookup_hit(mshr[i], fetch_req);
      prefetch_lookup_hit[i] = mshr_lookup_hit(mshr[i], prefetch_req);
    end
  end

  // 预取 req 与本拍 fetch req 撞同一条 line → 也算预取命中（让 fetch 去取）
  wire prefetch_hits_fetch_req = io_fetch_req_valid &&
       (prefetch_req.blkPaddr == fetch_req.blkPaddr) &&
       (prefetch_req.vSetIdx  == fetch_req.vSetIdx);

  wire fetch_hit    = |fetch_lookup_hit;
  wire prefetch_hit = (|prefetch_lookup_hit) || prefetch_hits_fetch_req;

  // ===========================================================================
  // Demux：把一条入站 req 分配给「第一个空闲」的 MSHR（lower index 优先）
  //   - fetch_req  → fetch MSHR 区 [0..3]
  //   - prefetch_req→ prefetch MSHR 区 [4..13]
  //   一个 MSHR 能接收 req 的条件 = 该 MSHR ready（!valid 且未被 flush/fencei 挡住）
  //   demux 把 req 给「编号最小的 ready MSHR」，并对该 MSHR 置 enq。
  // ===========================================================================
  // 每个 MSHR 的 req.ready（对应 Scala io.req.ready := !valid && !flush && !fencei）
  logic [N_MSHR_SLOTS-1:0] mshr_req_ready;
  always_comb begin
    mshr_req_ready = '0;
    for (int i = 0; i < N_MSHR; i++) begin
      logic obey_flush;
      obey_flush = mshr_obeys_flush(i) && io_flush;
      mshr_req_ready[i] = !mshr[i].valid && !obey_flush && !io_fencei;
    end
  end

  // fetch 区 / prefetch 区各自的「有空位」与「选中编号」（lower index 优先）
  wire        fetch_demux_in_valid    = io_fetch_req_valid    && !fetch_hit;
  wire        prefetch_demux_in_valid = io_prefetch_req_valid && !prefetch_hit;

  // fetch 区：是否有空闲 MSHR、选中的相对编号 [0..3]
  logic                            fetch_has_free;
  logic [$clog2(N_FETCH_MSHR)-1:0] fetch_sel;        // 相对编号
  always_comb begin
    fetch_has_free = 1'b0;
    fetch_sel      = '0;
    for (int i = int'(N_FETCH_MSHR) - 1; i >= 0; i--) begin
      if (mshr_req_ready[i]) begin
        fetch_has_free = 1'b1;
        fetch_sel      = ($clog2(N_FETCH_MSHR))'(i);
      end
    end
  end

  // prefetch 区：是否有空闲 MSHR、选中的相对编号 [0..9]
  logic                               prefetch_has_free;
  logic [$clog2(N_PREFETCH_MSHR)-1:0] prefetch_sel;   // 相对编号 0..9
  always_comb begin
    prefetch_has_free = 1'b0;
    prefetch_sel      = '0;
    for (int i = int'(N_PREFETCH_MSHR) - 1; i >= 0; i--) begin
      if (mshr_req_ready[int'(N_FETCH_MSHR) + i]) begin
        prefetch_has_free = 1'b1;
        prefetch_sel      = ($clog2(N_PREFETCH_MSHR))'(i);
      end
    end
  end

  wire fetch_demux_fire    = fetch_demux_in_valid    && fetch_has_free;
  wire prefetch_demux_fire = prefetch_demux_in_valid && prefetch_has_free;

  // 对外 req.ready：有空位即可收，或命中去重（命中时直接吞掉，也算 ready）
  assign io_fetch_req_ready    = fetch_has_free    || fetch_hit;
  assign io_prefetch_req_ready = prefetch_has_free || prefetch_hit;

  // 每个 MSHR 本拍是否被 demux 选中接收新 req
  logic [N_MSHR_SLOTS-1:0] mshr_enq;
  always_comb begin
    mshr_enq = '0;
    if (fetch_demux_fire)    mshr_enq[fetch_sel] = 1'b1;
    if (prefetch_demux_fire) mshr_enq[int'(N_FETCH_MSHR) + prefetch_sel] = 1'b1;
  end

  // ===========================================================================
  // priorityFIFO：记录 prefetch MSHR 的入队顺序（深度=nPrefetchMshr，保证不会满）
  //   入队 = prefetch_demux_fire（存被选中的相对编号 prefetch_sel）
  //   出队 = 一条 prefetch acquire 成功发射
  //   prefetchArb 按队头编号选择要发射的 prefetch MSHR → 实现「先进先发」
  // ===========================================================================
  localparam int unsigned PF_PTR_W = 4;  // 编号/指针宽（depth 10，4-bit 足够）
  logic [PF_PTR_W-1:0] pf_fifo [N_MSHR_SLOTS];  // 16 槽（>=深度 10），按 2 的幂避免越界
  logic                pf_enq_flag, pf_deq_flag;
  logic [PF_PTR_W-1:0] pf_enq_ptr,  pf_deq_ptr;

  wire pf_fifo_full  = (pf_enq_ptr == pf_deq_ptr) && (pf_enq_flag ^ pf_deq_flag);
  wire pf_fifo_empty = (pf_enq_ptr == pf_deq_ptr) && (pf_enq_flag == pf_deq_flag);

  wire [PF_PTR_W-1:0] pf_deq_bits = pf_fifo[pf_deq_ptr];  // 队头：下一个该发的 prefetch 编号

  // ===========================================================================
  // 发射仲裁
  //   prefetchArb：按 priorityFIFO 队头 pf_deq_bits 选一个 prefetch MSHR 的 acquire
  //   acquireArb ：fixed-priority（fetch 0..3 优先于 prefetch 整体），lowest index 赢
  // ===========================================================================
  // 各 MSHR 的 acquire.valid（对应 Scala：valid && !issued && !flush && !fencei && !wfiReq）
  logic [N_MSHR_SLOTS-1:0] mshr_acq_valid;
  always_comb begin
    mshr_acq_valid = '0;
    for (int i = 0; i < N_MSHR; i++) begin
      logic obey_flush;
      obey_flush = mshr_obeys_flush(i) && io_flush;
      mshr_acq_valid[i] = mshr[i].valid && !mshr[i].issued &&
                          !obey_flush && !io_fencei && !io_wfi_wfiReq;
    end
  end

  // prefetchArb 输出：选中队头编号对应的那条 prefetch MSHR
  //   绝对 MSHR 槽号 = N_FETCH_MSHR + 队头编号；用 SRC_W(4-bit) 截断运算，使索引天然落在
  //   16 槽范围内（队头编号 0..9 → 槽号 4..13，永不溢出；4-bit 截断也消除 FM 越界告警）。
  wire [SRC_W-1:0]       pf_arb_out_source   = SRC_W'(N_FETCH_MSHR) + pf_deq_bits;
  wire                   pf_arb_out_valid    = mshr_acq_valid[pf_arb_out_source];
  wire [BLK_PADDR_W-1:0] pf_arb_out_blkPaddr = mshr[pf_arb_out_source].blkPaddr;
  wire [IDX_BITS-1:0]    pf_arb_out_vSetIdx  = mshr[pf_arb_out_source].vSetIdx;

  // acquireArb：5 路 fixed-priority（in0..3 = fetch MSHR 0..3，in4 = prefetchArb 输出）
  // 选第一个 valid 的输入。
  logic                   acq_out_valid;
  logic [SRC_W-1:0]       acq_out_source;
  logic [BLK_PADDR_W-1:0] acq_out_blkPaddr;  // 用于拼地址
  logic [IDX_BITS-1:0]    acq_out_vSetIdx;   // 用于向 replacer 索要 victim
  logic [$clog2(N_FETCH_MSHR+1)-1:0] acq_chosen;  // 0..4
  always_comb begin
    acq_out_valid    = 1'b0;
    acq_out_source   = '0;
    acq_out_blkPaddr = '0;
    acq_out_vSetIdx  = '0;
    acq_chosen       = '0;
    // fetch MSHR 0..3 优先
    for (int i = int'(N_FETCH_MSHR) - 1; i >= 0; i--) begin
      if (mshr_acq_valid[i]) begin
        acq_out_valid    = 1'b1;
        acq_out_source   = SRC_W'(i);
        acq_out_blkPaddr = mshr[i].blkPaddr;
        acq_out_vSetIdx  = mshr[i].vSetIdx;
        acq_chosen       = ($clog2(N_FETCH_MSHR+1))'(i);
      end
    end
    // 最低优先级：prefetchArb 的输出
    if (!acq_out_valid && pf_arb_out_valid) begin
      acq_out_valid    = 1'b1;
      acq_out_source   = pf_arb_out_source;
      acq_out_blkPaddr = pf_arb_out_blkPaddr;
      acq_out_vSetIdx  = pf_arb_out_vSetIdx;
      acq_chosen       = ($clog2(N_FETCH_MSHR+1))'(N_FETCH_MSHR);
    end
  end

  wire acq_fire = acq_out_valid && io_mem_acquire_ready;

  // 被选中发射的 MSHR 索引（用于 acquire.fire 时置 issued / 锁存 way）
  wire [SRC_W-1:0] acq_sel_idx = acq_out_source;

  // prefetchArb 输出是否被 acquireArb 接受并发射（= prefetch 区出队条件）
  // acquireArb 中 in4(prefetch) 被接受 = out.ready 且前面 4 路都不 valid
  wire pf_arb_out_fire = pf_arb_out_valid && io_mem_acquire_ready &&
                         !(|mshr_acq_valid[N_FETCH_MSHR-1:0]);

  // ---- mem_acquire 输出（TileLink A：Get）----
  assign io_mem_acquire_valid        = acq_out_valid;
  assign io_mem_acquire_bits_source  = acq_out_source;
  assign io_mem_acquire_bits_address = {acq_out_blkPaddr, BLK_OFF'(0)};  // 块对齐地址

  // ---- victim 索要：发 acquire 时给 replacer 送 vSetIdx，下拍取回 way ----
  assign io_victim_vSetIdx_valid = acq_fire;
  assign io_victim_vSetIdx_bits  = acq_out_vSetIdx;

  // ===========================================================================
  // priorityFIFO 时序
  // ===========================================================================
  wire pf_enq_fire = prefetch_demux_fire;   // 与 prefetch req 入 MSHR 同拍
  wire pf_deq_fire = pf_arb_out_fire;        // 与 prefetch acquire 发射同拍
  wire pf_fifo_flush = io_flush || io_fencei;

  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      pf_enq_flag <= 1'b0; pf_enq_ptr <= '0;
      pf_deq_flag <= 1'b0; pf_deq_ptr <= '0;
      for (int i = 0; i < N_PREFETCH_MSHR; i++) pf_fifo[i] <= '0;
    end else begin
      // 入队：写队尾，指针 +1（到深度则绕回并翻 flag）
      if (pf_enq_fire) pf_fifo[pf_enq_ptr] <= PF_PTR_W'(prefetch_sel);

      if (pf_fifo_flush) begin
        pf_enq_ptr  <= '0;
        pf_deq_ptr  <= '0;
        pf_enq_flag <= 1'b0;
        pf_deq_flag <= 1'b0;
      end else begin
        if (pf_enq_fire) begin
          if (pf_enq_ptr == PF_PTR_W'(N_PREFETCH_MSHR - 1)) begin
            pf_enq_ptr  <= '0;
            pf_enq_flag <= ~pf_enq_flag;
          end else begin
            pf_enq_ptr <= pf_enq_ptr + 1'b1;
          end
        end
        if (pf_deq_fire) begin
          if (pf_deq_ptr == PF_PTR_W'(N_PREFETCH_MSHR - 1)) begin
            pf_deq_ptr  <= '0;
            pf_deq_flag <= ~pf_deq_flag;
          end else begin
            pf_deq_ptr <= pf_deq_ptr + 1'b1;
          end
        end
      end
    end
  end

  // ===========================================================================
  // TileLink D 通道（grant）：把 refillCycles 个 beat 拼成一条 cacheline
  // ===========================================================================
  // grant 携带数据的判据：opcode[0]==1（AccessAckData 的最低位）
  wire grant_has_data = io_mem_grant_bits_opcode[0];
  wire grant_beat     = io_mem_grant_valid && grant_has_data;  // grant.ready 恒 1

  logic [BEAT_CNT_W-1:0]            read_beat_cnt;             // 当前 beat 序号（0/1）
  logic [BEAT_BITS-1:0]            resp_data [REFILL_CYCLES]; // 拼接缓存
  wire  wait_last = (read_beat_cnt == BEAT_CNT_W'(REFILL_CYCLES - 1));
  wire  last_fire = grant_beat && wait_last;                   // 收完最后一个 beat

  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      read_beat_cnt <= '0;
      for (int i = 0; i < REFILL_CYCLES; i++) resp_data[i] <= '0;
    end else if (grant_beat) begin
      resp_data[read_beat_cnt] <= io_mem_grant_bits_data;
      read_beat_cnt <= wait_last ? '0 : (read_beat_cnt + 1'b1);
    end
  end

  // 拼成 512b（beat1 在高位，beat0 在低位）
  logic [BLOCK_BITS-1:0] resp_data_flat;
  always_comb begin
    resp_data_flat = '0;
    for (int i = 0; i < REFILL_CYCLES; i++)
      resp_data_flat[i*BEAT_BITS +: BEAT_BITS] = resp_data[i];
  end

  // 收完最后 beat 的下一拍：把 source / last_fire 打一拍，用于回填与回收 MSHR
  logic            last_fire_r;
  logic [SRC_W-1:0] id_r;
  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      last_fire_r <= 1'b0;
      id_r        <= '0;
    end else begin
      last_fire_r <= last_fire;
      id_r        <= io_mem_grant_bits_source;
    end
  end

  // corrupt：任一 beat corrupt 则置位，回送 MainPipe 后（last_fire_r）清除
  logic corrupt_r;
  always_ff @(posedge clock or posedge reset) begin
    if (reset)                               corrupt_r <= 1'b0;
    else if (grant_beat && io_mem_grant_bits_corrupt) corrupt_r <= 1'b1;
    else if (last_fire_r)                    corrupt_r <= 1'b0;
  end

  // ===========================================================================
  // refill 完成 → 回收对应 MSHR、锁存其响应信息
  // ===========================================================================
  // 各 MSHR 在本拍是否被「grant 完成」回收（last_fire_r 且 source 匹配）
  logic [N_MSHR_SLOTS-1:0] mshr_invalidate;
  always_comb begin
    mshr_invalidate = '0;
    for (int i = 0; i < N_MSHR; i++)
      mshr_invalidate[i] = last_fire_r && (id_r == SRC_W'(i));
  end

  // 选 grant 对应 MSHR 的响应信息（提前一拍在 last_fire 时锁存，改善时序）
  // resp.valid 不锁存（flush/fencei 可随时清），用当拍 id_r 索引的 MSHR valid&!killed
  //
  // 注：用 always_comb 显式按 source 选中字段，而非「连续赋值整个 struct =
  //     mshr[变量下标]」——后者在 VCS 下对 unpacked 数组元素的变量索引会产生 X。
  logic [BLK_PADDR_W-1:0] grant_mshr_blkPaddr;
  logic [IDX_BITS-1:0]    grant_mshr_vSetIdx;
  logic [WAY_BITS-1:0]    grant_mshr_way;
  always_comb begin
    grant_mshr_blkPaddr = mshr[io_mem_grant_bits_source].blkPaddr;
    grant_mshr_vSetIdx  = mshr[io_mem_grant_bits_source].vSetIdx;
    grant_mshr_way      = mshr[io_mem_grant_bits_source].way;
  end

  logic [BLK_PADDR_W-1:0] resp_blkPaddr;
  logic [IDX_BITS-1:0]    resp_vSetIdx;
  logic [WAY_BITS-1:0]    resp_way;
  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      resp_blkPaddr <= '0;
      resp_vSetIdx  <= '0;
      resp_way      <= '0;
    end else if (last_fire) begin
      resp_blkPaddr <= grant_mshr_blkPaddr;
      resp_vSetIdx  <= grant_mshr_vSetIdx;
      resp_way      <= grant_mshr_way;
    end
  end

  // id_r 对应 MSHR 当拍是否仍是有效的可响应项（resp.valid，不含被 kill/未占用）
  wire resp_mshr_valid = mshr[id_r].valid && !mshr[id_r].killed;

  // ===========================================================================
  // MSHR 状态更新（每个 MSHR 独立）
  //   fetch 区 [0..3] 登记 fetch_req；prefetch 区 [4..13] 登记 prefetch_req。
  //   按区静态选取入队数据（genvar 常量分支，无变量索引、无函数读模块信号）。
  // ===========================================================================
  generate
    for (genvar gi = 0; gi < int'(N_MSHR); gi++) begin : g_mshr
      localparam bit IS_PREFETCH = (gi >= int'(N_FETCH_MSHR));
      // 本 MSHR 登记的请求来源（fetch 区 → fetch_req，prefetch 区 → prefetch_req）
      wire [BLK_PADDR_W-1:0] enq_blkPaddr = IS_PREFETCH ? prefetch_req.blkPaddr : fetch_req.blkPaddr;
      wire [IDX_BITS-1:0]    enq_vSetIdx  = IS_PREFETCH ? prefetch_req.vSetIdx  : fetch_req.vSetIdx;

      // 本 MSHR 本拍被 flush/fencei 标记（fetch 不响应 flush）
      wire kill_now = io_fencei || (IS_PREFETCH && io_flush);

      always_ff @(posedge clock or posedge reset) begin
        if (reset) begin
          mshr[gi].valid    <= 1'b0;
          mshr[gi].issued   <= 1'b0;
          mshr[gi].killed   <= 1'b0;
          mshr[gi].blkPaddr <= '0;
          mshr[gi].vSetIdx  <= '0;
          mshr[gi].way      <= '0;
        end else begin
          // ---- 接收新 req（优先级最高，会重置整条 entry）----
          if (mshr_enq[gi]) begin
            mshr[gi].valid    <= 1'b1;
            mshr[gi].issued   <= 1'b0;
            mshr[gi].killed   <= 1'b0;
            mshr[gi].blkPaddr <= enq_blkPaddr;
            mshr[gi].vSetIdx  <= enq_vSetIdx;
          end else begin
            // ---- killed：被 flush/fencei 标记；未发射的立即失效 ----
            if (kill_now) begin
              mshr[gi].killed <= 1'b1;
              if (!mshr[gi].issued) mshr[gi].valid <= 1'b0;
            end
            // ---- grant 完成回收（与 enq 互斥；同 source 不会同拍 enq+invalidate）----
            if (mshr_invalidate[gi]) mshr[gi].valid <= 1'b0;
          end

          // ---- acquire 发射：置 issued、锁存 victim way（与 enq 不会同拍冲突）----
          if (!mshr_enq[gi] && acq_fire && (acq_sel_idx == SRC_W'(gi))) begin
            mshr[gi].issued <= 1'b1;
            mshr[gi].way    <= io_victim_way;
          end
        end
      end
    end
  endgenerate

  // ===========================================================================
  // 响应 fetch + 写 SRAM
  // ===========================================================================
  wire [N_WAYS-1:0] waymask = way_to_mask(resp_way);

  // fetch_resp：refill 完成的下一拍输出（即使 flush/fencei 也发，见模块头）
  wire fetch_resp_valid = resp_mshr_valid && last_fire_r;
  // 写 SRAM：仅在 fetch_resp 有效、无 corrupt、且非 flush/fencei 时
  wire write_sram_valid = fetch_resp_valid && !corrupt_r && !io_flush && !io_fencei;

  assign io_fetch_resp_valid         = fetch_resp_valid;
  assign io_fetch_resp_bits_blkPaddr = resp_blkPaddr;
  assign io_fetch_resp_bits_vSetIdx  = resp_vSetIdx;
  assign io_fetch_resp_bits_waymask  = waymask;
  assign io_fetch_resp_bits_data     = resp_data_flat;
  assign io_fetch_resp_bits_corrupt  = corrupt_r;

  assign io_meta_write_valid        = write_sram_valid;
  assign io_meta_write_bits_virIdx  = resp_vSetIdx;
  assign io_meta_write_bits_phyTag  = get_phy_tag(resp_blkPaddr);
  assign io_meta_write_bits_waymask = waymask;
  assign io_meta_write_bits_bankIdx = resp_vSetIdx[0];

  assign io_data_write_valid        = write_sram_valid;
  assign io_data_write_bits_virIdx  = resp_vSetIdx;
  assign io_data_write_bits_data    = resp_data_flat;
  assign io_data_write_bits_waymask = waymask;

  // ===========================================================================
  // WFI safe：所有 MSHR 都没有在途 L2 响应（!(valid && issued)）
  // ===========================================================================
  logic wfi_safe;
  always_comb begin
    wfi_safe = 1'b1;
    for (int i = 0; i < N_MSHR; i++)
      if (mshr[i].valid && mshr[i].issued) wfi_safe = 1'b0;
  end
  assign io_wfi_wfiSafe = wfi_safe;

  // io_mem_grant_bits_size 在 KunminghuV2 固定（整 cacheline），本实现按 beat 计数，不使用
  wire _unused_ok = &{1'b0, io_mem_grant_bits_size};

endmodule
