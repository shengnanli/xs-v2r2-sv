// =============================================================================
// xs_ICacheMainPipe —— ICache 主流水（取指数据通路的核心三级流水）
//
// 对应 Chisel: xiangshan.frontend.icache.ICacheMainPipe（ICacheMainPipe.scala）
//
// 【它在前端的位置】
//   FTQ ──req(pcMemRead)──▶ ICacheMainPipe ──resp(512b 取指数据)──▶ IFU
//   IPrefetch 早已把每次取指的「命中路 waymask / 物理 tag / iTLB 例外/属性 / meta ECC」
//   算好，存进 WayLookup FIFO；MainPipe 不再查 meta SRAM，而是：
//     · 拿 WayLookup 给的 waymask 直接去 data SRAM 取数据（省一次 meta 查找）；
//     · 自己做 PMP 检查、meta/data ECC 校验、miss 时向 MSHR(MissUnit) 发再取请求。
//
//   一次取指最多跨「两个 cacheline」（PortNumber=2：startAddr 所在 line 与 nextline）。
//   一个 cacheline=64B=512bit，按 ICacheDataBanks=8 切成 8 个 64bit bank，便于跨行拼接。
//
// 【三级流水（s0→s1→s2）】
//   s0 取指请求级：从 FTQ 收到请求 + 从 WayLookup 读出 waymask/tlb 信息，
//                  用 waymask 向 data SRAM 发读请求（partWayNum 个分路读端口）。
//   s1 SRAM 回读级：PMP 检查；锁存 data SRAM 回读数据/ECC code；做 meta ECC 校验；
//                  监听 MSHR 回填——若本拍正好填的就是要的 line，旁路用 MSHR 数据；
//                  更新替换器 touch。
//   s2 响应级：    做 data ECC 校验；miss 或 ECC 损坏 → 经 Arbiter 向 MSHR 发再取请求；
//                  持续监听 MSHR 回填修正 hit/数据/损坏标志；汇总例外；响应 IFU。
//
// 【关键设计点】
//   · waymask 来自 WayLookup（IPrefetch 算好的命中路），MainPipe 直接用它选 data SRAM 路。
//   · 跨行：port0 覆盖 startAddr 那条 line 的若干 bank，port1 覆盖 nextline 的 bank；
//     getBankSel 用 offset 把 8 个物理 bank 映射到两条 line（bankSel 16 项，低 8/高 8）。
//   · MSHR 旁路：refill 回来的 line 若正是本级要的，逐 bank 用 MSHR 数据替换 SRAM 数据，
//     并标记 data_is_from_MSHR（这些 bank 跳过 data ECC，因为是刚从 L2 取的新数据）。
//   · 例外优先级：itlb > pmp（s1 合并）> l2 corrupt（s2 合并）。meta/data ECC 损坏不报 af，
//     而是触发 metaArray flush + 向 MSHR 再取（自动恢复）。
//
// 注：本核心与 golden ICacheMainPipe 的 wayLookupRead 接口一致——即 WayLookup 模块输出的
//     {entry, gpf} 结构（entry 含两端口的 waymask/ptag/exception/pbmt/meta_codes；
//     gpf 含 gpaddr/isForVSnonLeafPTE）。
// =============================================================================
package xs_icache_mainpipe_pkg;
  // ---- 容量/位宽参数（与 KunminghuV2 ICache 一致）----
  localparam int unsigned PORT_NUM      = 2;   // PortNumber：一次取指最多跨 2 条 cacheline
  localparam int unsigned PART_WAY_NUM  = 4;   // partWayNum：data SRAM 的分路读端口数
  localparam int unsigned N_FTQ_PORT    = 5;   // partWayNum+1：FTQ pcMemRead 端口数（最后一个=主请求）
  localparam int unsigned N_WAYS        = 4;   // nWays：组相联路数
  localparam int unsigned N_BANKS       = 8;   // ICacheDataBanks：一条 line 切成 8 个 bank
  localparam int unsigned BANK_BITS     = 64;  // ICacheDataBits = blockBits/ICacheDataBanks
  localparam int unsigned BLOCK_BITS    = 512; // blockBits：一条 cacheline 比特数
  localparam int unsigned IDX_BITS      = 8;   // vSetIdx 宽（idxBits）
  localparam int unsigned VADDR_BITS    = 50;  // VAddrBits
  localparam int unsigned PADDR_BITS    = 48;  // PAddrBits
  localparam int unsigned PTAG_BITS     = 36;  // 物理 tag 宽
  localparam int unsigned GPADDR_BITS   = 56;  // PAddrBitsMax（gpaddr 用，见 Scala 注释 PR#3795）
  localparam int unsigned BLK_PADDR_BITS= 42;  // MSHR blkPaddr 宽（PAddrBits-blockOffBits=42）
  localparam int unsigned EXCP_W        = 2;   // ExceptionType.width
  localparam int unsigned PBMT_W        = 2;   // Pbmt.width
  localparam int unsigned WAY_IDX_W     = 2;   // log2(nWays)，touch.way 宽
  localparam int unsigned BLK_OFF_BITS  = 6;   // log2(blockBytes=64)
  localparam int unsigned PG_UNTAG_BITS = 12;  // pgUntagBits（页内偏移，paddr=ptag||vaddr[11:0]）
  localparam int unsigned BANK_OFF_BITS = 3;   // log2(blockBytes/ICacheDataBanks)=log2(8)

  // ---- ExceptionType 编码 ----
  localparam logic [EXCP_W-1:0] EXCP_NONE = 2'b00;
  localparam logic [EXCP_W-1:0] EXCP_AF   = 2'b11; // access fault

  // ---- Pbmt 编码（isUncache = NC(1) | IO(2)）----
  localparam logic [PBMT_W-1:0] PBMT_PMA = 2'd0;
  localparam logic [PBMT_W-1:0] PBMT_NC  = 2'd1;
  localparam logic [PBMT_W-1:0] PBMT_IO  = 2'd2;

  // ---- 由 WayLookup 读出的「单端口」命中信息 ----
  typedef struct packed {
    logic [IDX_BITS-1:0]  vSetIdx;
    logic [N_WAYS-1:0]    waymask;        // 命中路 one-hot（全 0 = SRAM miss）
    logic [PTAG_BITS-1:0] ptag;
    logic [EXCP_W-1:0]    itlb_exception;
    logic [PBMT_W-1:0]    itlb_pbmt;
    logic                 meta_codes;     // meta ECC（1bit 奇偶）
  } way_lookup_port_t;

  typedef struct packed {
    way_lookup_port_t [PORT_NUM-1:0] port;
  } way_lookup_entry_t;

  typedef struct packed {
    logic [GPADDR_BITS-1:0] gpaddr;
    logic                   isForVSnonLeafPTE;
  } way_lookup_gpf_t;

  // ---- FTQ 单个 pcMemRead 端口 ----
  typedef struct packed {
    logic [VADDR_BITS-1:0] startAddr;
    logic [VADDR_BITS-1:0] nextlineStart;
  } ftq_pc_read_t;

  // ---- data SRAM 读请求（每个 partWay 端口）----
  typedef struct packed {
    logic [PORT_NUM-1:0][IDX_BITS-1:0]  vSetIdx;       // 两条 line 的组索引
    logic [PORT_NUM-1:0][N_WAYS-1:0]    waymask;       // 两条 line 的命中路
    logic [BLK_OFF_BITS-1:0]            blkOffset;
    logic                               isDoubleLine;
  } data_sram_req_t;

  // ---- metaArray flush（ECC 损坏后清表重取）----
  typedef struct packed {
    logic [IDX_BITS-1:0] virIdx;
    logic [N_WAYS-1:0]   waymask;
  } meta_flush_t;

  // ---- 替换器 touch ----
  typedef struct packed {
    logic [IDX_BITS-1:0]   vSetIdx;
    logic [WAY_IDX_W-1:0]  way;
  } touch_t;

  // ---- L1 错误上报（BEU）----
  typedef struct packed {
    logic [PADDR_BITS-1:0] paddr;
    logic                  report_to_beu;
  } l1_error_t;

  // ---- IFU 响应（一拍给两条 line 的取指结果）----
  typedef struct packed {
    logic                                doubleline;
    logic [PORT_NUM-1:0][VADDR_BITS-1:0] vaddr;
    logic [BLOCK_BITS-1:0]               data;          // 8 bank 拼成的 512bit
    logic [PORT_NUM-1:0][PADDR_BITS-1:0] paddr;
    logic [PORT_NUM-1:0][EXCP_W-1:0]     exception;
    logic [PORT_NUM-1:0]                 pmp_mmio;
    logic [PORT_NUM-1:0][PBMT_W-1:0]     itlb_pbmt;
    logic                                backendException;
    logic [GPADDR_BITS-1:0]              gpaddr;
    logic                                isForVSnonLeafPTE;
  } ifu_resp_t;

  // ---- 性能计数信息 ----
  typedef struct packed {
    logic only_0_hit, only_0_miss;
    logic hit_0_hit_1, hit_0_miss_1, miss_0_hit_1, miss_0_miss_1;
    logic hit_0_except_1, miss_0_except_1, except_0;
    logic [PORT_NUM-1:0] bank_hit;
    logic hit;
  } perf_info_t;

  // ---- 函数 ----
  // 组索引：vaddr[13:6]
  function automatic logic [IDX_BITS-1:0] get_idx(input logic [VADDR_BITS-1:0] v);
    return v[BLK_OFF_BITS +: IDX_BITS];
  endfunction

  // 物理地址：ptag || vaddr[pgUntagBits-1:0]
  function automatic logic [PADDR_BITS-1:0] get_paddr(
      input logic [VADDR_BITS-1:0] v, input logic [PTAG_BITS-1:0] ptag);
    return {ptag, v[PG_UNTAG_BITS-1:0]};
  endfunction

  // 块地址（去块内偏移）：paddr[PAddrBits-1:blockOffBits]
  function automatic logic [BLK_PADDR_BITS-1:0] get_blk_addr(input logic [PADDR_BITS-1:0] pa);
    return pa[PADDR_BITS-1:BLK_OFF_BITS];
  endfunction

  // 由 MSHR 的 blkPaddr 取物理 tag：blkPaddr >> (pgUntagBits-blockOffBits) = blkPaddr[41:6]
  function automatic logic [PTAG_BITS-1:0] get_ptag_from_blk(input logic [BLK_PADDR_BITS-1:0] blk);
    return blk[BLK_PADDR_BITS-1 : (PG_UNTAG_BITS-BLK_OFF_BITS)];
  endfunction

  // data/meta ECC：KunminghuV2 用 1bit 全位奇偶校验
  function automatic logic encode_data_ecc(input logic [BANK_BITS-1:0] d);
    return ^d;
  endfunction
  function automatic logic encode_meta_ecc(input logic [PTAG_BITS-1:0] m);
    return ^m;
  endfunction
endpackage


module xs_ICacheMainPipe
  import xs_icache_mainpipe_pkg::*;
(
  input  logic clock,
  input  logic reset,

  // ---- data SRAM 读口（partWayNum 个 valid + 共用 bits/fromIData）----
  output logic [PART_WAY_NUM-1:0]           toData_valid,
  output data_sram_req_t                    toData_bits,
  input  logic                              toData_last_ready, // 仅末端口 ready 参与 s0 推进
  input  logic [N_BANKS-1:0][BANK_BITS-1:0] fromData_datas,
  input  logic [N_BANKS-1:0]                fromData_codes,

  // ---- metaArray flush（ECC 损坏）----
  output logic [PORT_NUM-1:0]        metaFlush_valid,
  output meta_flush_t [PORT_NUM-1:0] metaFlush_bits,

  // ---- 替换器 touch ----
  output logic [PORT_NUM-1:0] touch_valid,
  output touch_t [PORT_NUM-1:0] touch_bits,

  // ---- WayLookup 读口（← IPrefetch 经 FIFO）----
  output logic              wayLookup_ready,
  input  logic              wayLookup_valid,
  input  way_lookup_entry_t wayLookup_entry,
  input  way_lookup_gpf_t   wayLookup_gpf,

  // ---- MSHR（→ MissUnit 再取请求 / ← refill 回填）----
  input  logic                      mshr_req_ready,
  output logic                      mshr_req_valid,
  output logic [BLK_PADDR_BITS-1:0] mshr_req_blkPaddr,
  output logic [IDX_BITS-1:0]       mshr_req_vSetIdx,
  input  logic                      mshr_resp_valid,
  input  logic [BLK_PADDR_BITS-1:0] mshr_resp_blkPaddr,
  input  logic [IDX_BITS-1:0]       mshr_resp_vSetIdx,
  input  logic [BLOCK_BITS-1:0]     mshr_resp_data,
  input  logic                      mshr_resp_corrupt,

  input  logic ecc_enable,

  // ---- FTQ 请求 ----
  output logic                          fetch_req_ready,
  input  logic                          fetch_req_valid,
  input  ftq_pc_read_t [N_FTQ_PORT-1:0] fetch_req_pcMemRead,
  input  logic [N_FTQ_PORT-1:0]         fetch_req_readValid,
  input  logic                          fetch_req_backendException,

  // ---- IFU 响应 ----
  output logic       fetch_resp_valid,
  output ifu_resp_t  fetch_resp_bits,
  output logic       fetch_topdownIcacheMiss,
  output logic       fetch_topdownItlbMiss,

  input  logic io_flush,

  // ---- PMP（每端口 req.addr → resp.instr/mmio）----
  output logic [PORT_NUM-1:0][PADDR_BITS-1:0] pmp_req_addr,
  input  logic [PORT_NUM-1:0]                 pmp_resp_instr,
  input  logic [PORT_NUM-1:0]                 pmp_resp_mmio,

  input  logic io_respStall,

  // ---- 错误上报 ----
  output logic [PORT_NUM-1:0]      errors_valid,
  output l1_error_t [PORT_NUM-1:0] errors_bits,

  // ---- 性能 ----
  output perf_info_t perfInfo
);

  // ===========================================================================
  // 流水控制握手线
  // ===========================================================================
  logic s1_ready, s2_ready;
  logic s0_fire, s1_fire, s2_fire;
  // s0/s1/s2_flush 三级 flush 都直接来自 io_flush（与 Scala 一致），故下文直接用 io_flush。

  // ===========================================================================
  // ICache Stage 0 —— 取指请求 + 用 waymask 向 data SRAM 发读
  // ===========================================================================
  // FTQ 主请求取 pcMemRead 的最后一个端口（index = partWayNum）；前 partWayNum 个端口
  // 用于驱动 data SRAM 各分路读口的 valid（readValid(i)）。
  ftq_pc_read_t main_req;
  assign main_req = fetch_req_pcMemRead[N_FTQ_PORT-1];

  logic [PORT_NUM-1:0][VADDR_BITS-1:0] s0_vaddr;
  assign s0_vaddr[0] = main_req.startAddr;
  assign s0_vaddr[1] = main_req.nextlineStart;

  logic [BLK_OFF_BITS-1:0] s0_offset;
  assign s0_offset = main_req.startAddr[BLK_OFF_BITS-1:0];
  // doubleline：本次取指跨行（startAddr 的 bit5=1 → 取指块尾越过 32B 半行边界进入下一 line）
  logic s0_doubleline;
  assign s0_doubleline = fetch_req_readValid[N_FTQ_PORT-1] & main_req.startAddr[5];

  // s0 从 WayLookup 拿命中信息（两端口）
  logic [PORT_NUM-1:0][N_WAYS-1:0] s0_waymask;
  logic [PORT_NUM-1:0]             s0_SRAMhit;   // 该端口 SRAM 命中（waymask 非全 0）
  for (genvar p = 0; p < PORT_NUM; p++) begin : g_s0_hit
    assign s0_waymask[p] = wayLookup_entry.port[p].waymask;
    assign s0_SRAMhit[p] = |wayLookup_entry.port[p].waymask;
  end

  // ---- data SRAM 读请求：bits 用 partWay 端口 0 的 FTQ 信息 + WayLookup 命中路 ----
  // 注：golden 中 toIData_0 的 vSetIdx/blkOffset 取自 pcMemRead_0，waymask 取自 WayLookup。
  assign toData_bits.vSetIdx[0]   = get_idx(fetch_req_pcMemRead[0].startAddr);
  assign toData_bits.vSetIdx[1]   = get_idx(fetch_req_pcMemRead[0].nextlineStart);
  assign toData_bits.waymask[0]   = s0_waymask[0];
  assign toData_bits.waymask[1]   = s0_waymask[1];
  assign toData_bits.blkOffset    = fetch_req_pcMemRead[0].startAddr[BLK_OFF_BITS-1:0];
  assign toData_bits.isDoubleLine = fetch_req_readValid[0] & fetch_req_pcMemRead[0].startAddr[5];
  assign toData_valid             = fetch_req_readValid[PART_WAY_NUM-1:0];

  // s0 推进：data SRAM 末端口 ready & WayLookup 有数据 & s1 可接
  logic s0_can_go;
  assign s0_can_go       = toData_last_ready & wayLookup_valid & s1_ready;
  assign s0_fire         = fetch_req_valid & s0_can_go & ~io_flush;
  assign fetch_req_ready = s0_can_go;
  assign wayLookup_ready = s0_fire;

  // ===========================================================================
  // ICache Stage 1 —— PMP / 锁存 SRAM 回读 / meta ECC / 监听 MSHR / touch
  // ===========================================================================
  logic s1_valid;
  // s1_valid：lastFire(s0_fire) 置位，thisFire(s1_fire) 清位，io_flush 清位
  always_ff @(posedge clock or posedge reset) begin
    if (reset) s1_valid <= 1'b0;
    else       s1_valid <= ~io_flush & (s0_fire | (~s1_fire & s1_valid));
  end

  // s0→s1 流水寄存器
  logic [PORT_NUM-1:0][VADDR_BITS-1:0] s1_vaddr;
  logic [PORT_NUM-1:0][PTAG_BITS-1:0]  s1_ptag;
  logic [GPADDR_BITS-1:0]              s1_gpaddr;
  logic                                s1_isForVSnonLeafPTE;
  logic                                s1_doubleline;
  logic [PORT_NUM-1:0]                 s1_SRAMhit;
  logic [PORT_NUM-1:0][EXCP_W-1:0]     s1_itlb_exception;
  logic                                s1_backendException;
  logic [PORT_NUM-1:0][PBMT_W-1:0]     s1_itlb_pbmt;
  logic [PORT_NUM-1:0][N_WAYS-1:0]     s1_waymask;
  logic [PORT_NUM-1:0]                 s1_meta_codes;

  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      s1_vaddr <= '0; s1_ptag <= '0; s1_gpaddr <= '0; s1_isForVSnonLeafPTE <= 1'b0;
      s1_doubleline <= 1'b0; s1_SRAMhit <= '0; s1_itlb_exception <= '0;
      s1_backendException <= 1'b0; s1_itlb_pbmt <= '0; s1_waymask <= '0; s1_meta_codes <= '0;
    end else if (s0_fire) begin
      s1_vaddr[0]          <= s0_vaddr[0];
      s1_vaddr[1]          <= s0_vaddr[1];
      s1_ptag[0]           <= wayLookup_entry.port[0].ptag;
      s1_ptag[1]           <= wayLookup_entry.port[1].ptag;
      s1_gpaddr            <= wayLookup_gpf.gpaddr;
      s1_isForVSnonLeafPTE <= wayLookup_gpf.isForVSnonLeafPTE;
      s1_doubleline        <= s0_doubleline;
      s1_SRAMhit           <= s0_SRAMhit;
      s1_itlb_exception[0] <= wayLookup_entry.port[0].itlb_exception;
      s1_itlb_exception[1] <= wayLookup_entry.port[1].itlb_exception;
      s1_backendException  <= fetch_req_backendException;
      s1_itlb_pbmt[0]      <= wayLookup_entry.port[0].itlb_pbmt;
      s1_itlb_pbmt[1]      <= wayLookup_entry.port[1].itlb_pbmt;
      s1_waymask           <= s0_waymask;
      s1_meta_codes[0]     <= wayLookup_entry.port[0].meta_codes;
      s1_meta_codes[1]     <= wayLookup_entry.port[1].meta_codes;
    end
  end

  logic [PORT_NUM-1:0][IDX_BITS-1:0]   s1_vSetIdx;
  logic [PORT_NUM-1:0][PADDR_BITS-1:0] s1_paddr;
  logic [BLK_OFF_BITS-1:0]             s1_offset;
  assign s1_offset = s1_vaddr[0][BLK_OFF_BITS-1:0];
  for (genvar p = 0; p < PORT_NUM; p++) begin : g_s1_addr
    assign s1_vSetIdx[p] = get_idx(s1_vaddr[p]);
    assign s1_paddr[p]   = get_paddr(s1_vaddr[p], s1_ptag[p]);
  end

  // ---- meta ECC 校验（每端口）----
  // 命中一路但奇偶不符 → ECC 失败；命中多路 → 必为 ECC 失败。未命中时不关心。
  logic [PORT_NUM-1:0] s1_meta_corrupt;
  for (genvar p = 0; p < PORT_NUM; p++) begin : g_meta_ecc
    logic [2:0] hit_num;
    assign hit_num = $countones(s1_waymask[p]);
    assign s1_meta_corrupt[p] = ecc_enable &
      (((encode_meta_ecc(s1_ptag[p]) != s1_meta_codes[p]) & (hit_num == 3'd1)) |
       (hit_num > 3'd1));
  end

  // ---- 替换器 touch（s0_fire 后一拍且 SRAM 命中才更新该路 LRU）----
  logic s1_touch_en;  // RegNext(s0_fire)
  always_ff @(posedge clock) s1_touch_en <= s0_fire;
  for (genvar p = 0; p < PORT_NUM; p++) begin : g_touch
    assign touch_bits[p].vSetIdx = s1_vSetIdx[p];
    // one-hot → 路号（nWays=4）
    assign touch_bits[p].way[1] = |s1_waymask[p][3:2];
    assign touch_bits[p].way[0] = s1_waymask[p][3] | s1_waymask[p][1];
  end
  assign touch_valid[0] = s1_touch_en & s1_SRAMhit[0];
  assign touch_valid[1] = s1_touch_en & s1_SRAMhit[1] & s1_doubleline;

  // ---- PMP 检查（用 s1 物理地址）----
  for (genvar p = 0; p < PORT_NUM; p++) begin : g_pmp
    assign pmp_req_addr[p] = s1_paddr[p];
  end
  logic [PORT_NUM-1:0][EXCP_W-1:0] s1_pmp_exception;
  for (genvar p = 0; p < PORT_NUM; p++) begin : g_pmp_exc
    assign s1_pmp_exception[p] = pmp_resp_instr[p] ? EXCP_AF : EXCP_NONE;
  end
  // s1 例外合并：itlb 优先，pmp 次之
  logic [PORT_NUM-1:0][EXCP_W-1:0] s1_exception;
  for (genvar p = 0; p < PORT_NUM; p++) begin : g_s1_exc_merge
    assign s1_exception[p] =
      (s1_itlb_exception[p] != EXCP_NONE) ? s1_itlb_exception[p] : s1_pmp_exception[p];
  end

  // ---- 监听 MSHR：若本拍 refill 的正是要的 line，则用 MSHR 数据 ----
  // s1 阶段的 MSHR 命中要求 !corrupt（corrupt 数据不可用）。
  logic [PORT_NUM-1:0] s1_MSHR_hit;
  assign s1_MSHR_hit[0] = s1_valid & (s1_vSetIdx[0] == mshr_resp_vSetIdx)
                        & (s1_ptag[0] == get_ptag_from_blk(mshr_resp_blkPaddr))
                        & mshr_resp_valid & ~mshr_resp_corrupt;
  assign s1_MSHR_hit[1] = s1_valid & (s1_vSetIdx[1] == mshr_resp_vSetIdx)
                        & (s1_ptag[1] == get_ptag_from_blk(mshr_resp_blkPaddr))
                        & mshr_resp_valid & ~mshr_resp_corrupt & s1_doubleline;

  // hit（含跨拍保持，ValidHoldBypass）：s1_MSHR_hit 或（s0_fire 后一拍 SRAM 命中），
  // 保持到 s1_fire / io_flush。
  logic [PORT_NUM-1:0] s1_hit;
  for (genvar p = 0; p < PORT_NUM; p++) begin : g_s1_hit
    logic hold;
    logic set;
    assign set = s1_MSHR_hit[p] | (s1_touch_en & s1_SRAMhit[p]);
    always_ff @(posedge clock or posedge reset) begin
      if (reset) hold <= 1'b0;
      else       hold <= ~(s1_fire | io_flush) & (set | hold);
    end
    assign s1_hit[p] = set | hold;
  end

  // ---- 逐 bank 的 MSHR 旁路选择 ----
  // bankIdxLow = offset>>3：startAddr 所在 line 从第几个 bank 起。
  // bank b 若 >= bankIdxLow 属 line0（port0），否则属 line1（port1）的回绕部分。
  logic [BANK_OFF_BITS-1:0] s1_bankIdxLow;
  assign s1_bankIdxLow = s1_offset[BLK_OFF_BITS-1:BANK_OFF_BITS];
  logic [N_BANKS-1:0] s1_bankMSHRHit;
  for (genvar b = 0; b < N_BANKS; b++) begin : g_s1_bankhit
    assign s1_bankMSHRHit[b] = ((b >= s1_bankIdxLow) & s1_MSHR_hit[0])
                             | ((b <  s1_bankIdxLow) & s1_MSHR_hit[1]);
  end

  // s1 数据/code/来源标志：DataHoldBypass —— s0_fire 后一拍锁存 SRAM 回读，
  // 命中 MSHR 的 bank 旁路用 MSHR 数据；保持寄存器在 s0_fire 下一拍或 MSHR 命中时更新。
  logic [N_BANKS-1:0][BANK_BITS-1:0] s1_datas;
  logic [N_BANKS-1:0]                s1_data_is_from_MSHR;
  logic [N_BANKS-1:0]                s1_codes;
  logic s1_sram_latch_en;  // RegNext(s0_fire)，data SRAM 回读有效拍
  always_ff @(posedge clock) s1_sram_latch_en <= s0_fire;

  for (genvar b = 0; b < N_BANKS; b++) begin : g_s1_data
    logic [BANK_BITS-1:0] sel_data;
    logic                 hold_en;
    logic [BANK_BITS-1:0] data_hold;
    logic                 from_mshr_hold;
    logic                 code_hold;
    assign sel_data = s1_bankMSHRHit[b] ? mshr_resp_data[b*BANK_BITS +: BANK_BITS]
                                        : fromData_datas[b];
    assign hold_en  = s1_bankMSHRHit[b] | s1_sram_latch_en;
    always_ff @(posedge clock) begin
      if (hold_en) begin
        data_hold      <= sel_data;
        from_mshr_hold <= s1_bankMSHRHit[b];
      end
    end
    assign s1_datas[b]             = hold_en ? sel_data          : data_hold;
    assign s1_data_is_from_MSHR[b] = hold_en ? s1_bankMSHRHit[b] : from_mshr_hold;

    // code 只来自 SRAM（s0_fire 下一拍锁存）
    always_ff @(posedge clock) if (s1_sram_latch_en) code_hold <= fromData_codes[b];
    assign s1_codes[b] = s1_sram_latch_en ? fromData_codes[b] : code_hold;
  end

  assign s1_ready = s2_ready | ~s1_valid;
  assign s1_fire  = s1_valid & s2_ready & ~io_flush;

  // ===========================================================================
  // ICache Stage 2 —— data ECC / miss 再取 / 监听 MSHR / 响应 IFU
  // ===========================================================================
  logic s2_valid;
  always_ff @(posedge clock or posedge reset) begin
    if (reset) s2_valid <= 1'b0;
    else       s2_valid <= ~io_flush & (s1_fire | (~s2_fire & s2_valid));
  end

  // s1→s2 流水寄存器（s1_fire 锁存）
  logic [PORT_NUM-1:0][VADDR_BITS-1:0] s2_vaddr;
  logic [PORT_NUM-1:0][PTAG_BITS-1:0]  s2_ptag;
  logic [GPADDR_BITS-1:0]              s2_gpaddr;
  logic                                s2_isForVSnonLeafPTE;
  logic                                s2_doubleline;
  logic [PORT_NUM-1:0][EXCP_W-1:0]     s2_exception;     // itlb+pmp 合并
  logic                                s2_backendException;
  logic [PORT_NUM-1:0]                 s2_pmp_mmio;
  logic [PORT_NUM-1:0][PBMT_W-1:0]     s2_itlb_pbmt;
  logic [PORT_NUM-1:0][N_WAYS-1:0]     s2_waymask;
  logic [PORT_NUM-1:0]                 s2_SRAMhit;
  logic [N_BANKS-1:0]                  s2_codes;

  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      s2_vaddr <= '0; s2_ptag <= '0; s2_gpaddr <= '0; s2_isForVSnonLeafPTE <= 1'b0;
      s2_doubleline <= 1'b0; s2_exception <= '0; s2_backendException <= 1'b0;
      s2_pmp_mmio <= '0; s2_itlb_pbmt <= '0; s2_waymask <= '0; s2_SRAMhit <= '0; s2_codes <= '0;
    end else if (s1_fire) begin
      s2_vaddr             <= s1_vaddr;
      s2_ptag              <= s1_ptag;
      s2_gpaddr            <= s1_gpaddr;
      s2_isForVSnonLeafPTE <= s1_isForVSnonLeafPTE;
      s2_doubleline        <= s1_doubleline;
      s2_exception         <= s1_exception;
      s2_backendException  <= s1_backendException;
      s2_pmp_mmio[0]       <= pmp_resp_mmio[0];
      s2_pmp_mmio[1]       <= pmp_resp_mmio[1];
      s2_itlb_pbmt         <= s1_itlb_pbmt;
      s2_waymask           <= s1_waymask;
      s2_SRAMhit           <= s1_SRAMhit;
      s2_codes             <= s1_codes;
    end
  end

  logic [PORT_NUM-1:0][IDX_BITS-1:0]   s2_vSetIdx;
  logic [PORT_NUM-1:0][PADDR_BITS-1:0] s2_paddr;
  logic [BLK_OFF_BITS-1:0]             s2_offset;
  assign s2_offset = s2_vaddr[0][BLK_OFF_BITS-1:0];
  for (genvar p = 0; p < PORT_NUM; p++) begin : g_s2_addr
    assign s2_vSetIdx[p] = get_idx(s2_vaddr[p]);
    assign s2_paddr[p]   = get_paddr(s2_vaddr[p], s2_ptag[p]);
  end

  // ---- s2 状态寄存器：data/hit/来源/损坏标志（s1_fire 装入，否则按 MSHR 回填修正）----
  logic [N_BANKS-1:0][BANK_BITS-1:0] s2_datas;
  logic [N_BANKS-1:0]                s2_data_is_from_MSHR;
  logic [PORT_NUM-1:0]               s2_hit;
  logic [PORT_NUM-1:0]               s2_meta_corrupt;
  logic [PORT_NUM-1:0]               s2_l2_corrupt;
  logic [PORT_NUM-1:0]               s2_has_send;   // 已向 MSHR 发过请求（去重）

  // s2 阶段的 bankSel：哪些 bank 属于本次取指（port0/port1 各占一段）。
  // bankIdxLow = offset>>3；bankIdxHigh = (offset+32)>>3（+32B = 半行，确保覆盖跨行尾部）。
  logic [BANK_OFF_BITS-1:0] s2_bankIdxLow;
  logic [3:0]               s2_bankIdxHigh;
  assign s2_bankIdxLow  = s2_offset[BLK_OFF_BITS-1:BANK_OFF_BITS];
  assign s2_bankIdxHigh = (7'({1'b0, s2_offset} + 7'd32)) >> BANK_OFF_BITS;
  // bankSel：16 项（2*N_BANKS），低 8 给 port0，高 8 给 port1
  logic [2*N_BANKS-1:0] s2_bankSel;
  for (genvar i = 0; i < 2*N_BANKS; i++) begin : g_s2_banksel
    assign s2_bankSel[i] = (4'(i) >= {1'b0, s2_bankIdxLow}) & (4'(i) <= s2_bankIdxHigh);
  end

  // ---- s2 监听 MSHR（不要求 !corrupt：corrupt 也要更新以放行 s2_fire）----
  logic [PORT_NUM-1:0] s2_MSHR_hit;
  assign s2_MSHR_hit[0] = s2_valid & (s2_vSetIdx[0] == mshr_resp_vSetIdx)
                        & (s2_ptag[0] == get_ptag_from_blk(mshr_resp_blkPaddr)) & mshr_resp_valid;
  assign s2_MSHR_hit[1] = s2_valid & (s2_vSetIdx[1] == mshr_resp_vSetIdx)
                        & (s2_ptag[1] == get_ptag_from_blk(mshr_resp_blkPaddr)) & mshr_resp_valid
                        & s2_doubleline;
  logic [BANK_OFF_BITS-1:0] s2_mshrBankLow;
  assign s2_mshrBankLow = s2_offset[BLK_OFF_BITS-1:BANK_OFF_BITS];
  logic [N_BANKS-1:0] s2_bankMSHRHit;
  for (genvar b = 0; b < N_BANKS; b++) begin : g_s2_bankhit
    assign s2_bankMSHRHit[b] = ((b >= s2_mshrBankLow) & s2_MSHR_hit[0])
                             | ((b <  s2_mshrBankLow) & s2_MSHR_hit[1]);
  end

  // data/from_MSHR：s1_fire 整体装入；否则命中 MSHR 的 bank 用 refill 数据并置 from_MSHR
  for (genvar b = 0; b < N_BANKS; b++) begin : g_s2_data_reg
    always_ff @(posedge clock or posedge reset) begin
      if (reset) begin
        s2_datas[b] <= '0; s2_data_is_from_MSHR[b] <= 1'b0;
      end else if (s1_fire) begin
        s2_datas[b]             <= s1_datas[b];
        s2_data_is_from_MSHR[b] <= s1_data_is_from_MSHR[b];
      end else if (s2_bankMSHRHit[b]) begin
        s2_datas[b]             <= mshr_resp_data[b*BANK_BITS +: BANK_BITS];
        s2_data_is_from_MSHR[b] <= 1'b1;  // refill 数据无需再做 data ECC
      end
    end
  end

  // hit / meta_corrupt：s1_fire 装入；否则 MSHR 命中则置 hit、清 meta_corrupt（放行 s2_fire）
  for (genvar p = 0; p < PORT_NUM; p++) begin : g_s2_hit_reg
    always_ff @(posedge clock or posedge reset) begin
      if (reset) begin
        s2_hit[p] <= 1'b0; s2_meta_corrupt[p] <= 1'b0;
      end else if (s1_fire) begin
        s2_hit[p]          <= s1_hit[p];
        s2_meta_corrupt[p] <= s1_meta_corrupt[p];
      end else if (s2_MSHR_hit[p]) begin
        s2_hit[p]          <= 1'b1;
        s2_meta_corrupt[p] <= 1'b0;
      end
    end
  end

  // l2_corrupt：s1_fire 清零；否则 MSHR 命中时取 refill 的 corrupt
  for (genvar p = 0; p < PORT_NUM; p++) begin : g_s2_l2corrupt
    always_ff @(posedge clock or posedge reset) begin
      if (reset)               s2_l2_corrupt[p] <= 1'b0;
      else if (s1_fire)        s2_l2_corrupt[p] <= 1'b0;
      else if (s2_MSHR_hit[p]) s2_l2_corrupt[p] <= mshr_resp_corrupt;
    end
  end

  // ---- data ECC 校验（每 bank 奇偶；本次取指选中的 bank 且非 MSHR 来源才算损坏）----
  logic [N_BANKS-1:0] s2_bank_corrupt;
  for (genvar b = 0; b < N_BANKS; b++) begin : g_bank_ecc
    assign s2_bank_corrupt[b] = (encode_data_ecc(s2_datas[b]) != s2_codes[b]);
  end
  logic [PORT_NUM-1:0] s2_data_corrupt;
  for (genvar p = 0; p < PORT_NUM; p++) begin : g_data_corrupt
    logic acc;
    always_comb begin
      acc = 1'b0;
      for (int b = 0; b < N_BANKS; b++)
        acc |= s2_bank_corrupt[b] & s2_bankSel[p*N_BANKS + b] & ~s2_data_is_from_MSHR[b];
    end
    assign s2_data_corrupt[p] = ecc_enable & acc & s2_SRAMhit[p];
  end

  // corrupt → 既要再取也要 flush metaArray
  logic [PORT_NUM-1:0] s2_corrupt_refetch;
  for (genvar p = 0; p < PORT_NUM; p++) begin : g_corrupt_ref
    assign s2_corrupt_refetch[p] = s2_meta_corrupt[p] | s2_data_corrupt[p];
  end

  // ---- mmio：pmp mmio 或 itlb pbmt 标记为 uncache ----
  logic [PORT_NUM-1:0] s2_mmio;
  for (genvar p = 0; p < PORT_NUM; p++) begin : g_mmio
    assign s2_mmio[p] = s2_pmp_mmio[p] | (s2_itlb_pbmt[p] == PBMT_NC) | (s2_itlb_pbmt[p] == PBMT_IO);
  end

  // ---- should_fetch：miss 或 ECC 损坏需再取；但例外/mmio/前序端口异常时不取 ----
  logic [PORT_NUM-1:0] s2_should_fetch;
  // port0：无 doubleline 限制
  assign s2_should_fetch[0] = (~s2_hit[0] | s2_corrupt_refetch[0])
                            & (s2_exception[0] == EXCP_NONE) & ~s2_mmio[0];
  // port1：要求 doubleline，且 port0/port1 都无例外、都非 mmio
  assign s2_should_fetch[1] = (~s2_hit[1] | s2_corrupt_refetch[1]) & s2_doubleline
                            & ~((|s2_exception[0]) | (|s2_exception[1]))
                            & ~s2_mmio[0] & ~s2_mmio[1];

  // ---- 向 MSHR 发再取请求（去重 + 两端口仲裁，port0 优先）----
  logic [PORT_NUM-1:0] s2_mshr_in_valid;
  logic [PORT_NUM-1:0] s2_mshr_in_ready;
  for (genvar p = 0; p < PORT_NUM; p++) begin : g_mshr_in
    assign s2_mshr_in_valid[p] = s2_valid & s2_should_fetch[p] & ~s2_has_send[p] & ~io_flush;
  end
  // Arbiter2_ICacheMissReq：in0 优先；in1 仅当 in0 无效时获让
  assign s2_mshr_in_ready[0] = mshr_req_ready;
  assign s2_mshr_in_ready[1] = ~s2_mshr_in_valid[0] & mshr_req_ready;
  assign mshr_req_valid    = s2_mshr_in_valid[0] | s2_mshr_in_valid[1];
  assign mshr_req_blkPaddr = s2_mshr_in_valid[0] ? get_blk_addr(s2_paddr[0]) : get_blk_addr(s2_paddr[1]);
  assign mshr_req_vSetIdx  = s2_mshr_in_valid[0] ? s2_vSetIdx[0]             : s2_vSetIdx[1];

  // has_send：s1_fire 清；否则该端口 fire 后置位（避免重复发请求）
  for (genvar p = 0; p < PORT_NUM; p++) begin : g_has_send
    always_ff @(posedge clock or posedge reset) begin
      if (reset)        s2_has_send[p] <= 1'b0;
      else if (s1_fire) s2_has_send[p] <= 1'b0;
      else              s2_has_send[p] <= (s2_mshr_in_ready[p] & s2_mshr_in_valid[p]) | s2_has_send[p];
    end
  end

  logic s2_fetch_finish;
  assign s2_fetch_finish = ~(s2_should_fetch[0] | s2_should_fetch[1]);

  // ---- s2 例外汇总：itlb/pmp 合并 l2 corrupt（l2 corrupt → af）----
  logic [PORT_NUM-1:0][EXCP_W-1:0] s2_exception_out;
  for (genvar p = 0; p < PORT_NUM; p++) begin : g_s2_exc_out
    assign s2_exception_out[p] =
      (s2_exception[p] != EXCP_NONE) ? s2_exception[p] : (s2_l2_corrupt[p] ? EXCP_AF : EXCP_NONE);
  end

  assign s2_ready = (s2_fetch_finish & ~io_respStall) | ~s2_valid;
  assign s2_fire  = s2_valid & s2_fetch_finish & ~io_respStall & ~io_flush;

  // ===========================================================================
  // 错误上报 / metaArray flush（ECC 损坏后清表重取）
  // ===========================================================================
  // 损坏报告打一拍（RegNext(s1_fire)），与 s2 同步
  logic s2_err_en;  // RegNext(s1_fire)
  always_ff @(posedge clock) s2_err_en <= s1_fire;

  // l2 corrupt 报告再打一拍（RegNext(s2_fire && s2_l2_corrupt)）
  logic [PORT_NUM-1:0]                 s2_l2_report;
  logic [PORT_NUM-1:0][PADDR_BITS-1:0] s2_l2_report_paddr;
  for (genvar p = 0; p < PORT_NUM; p++) begin : g_l2_report
    always_ff @(posedge clock) begin
      s2_l2_report[p]       <= s2_fire & s2_l2_corrupt[p];
      s2_l2_report_paddr[p] <= s2_paddr[p];
    end
  end

  for (genvar p = 0; p < PORT_NUM; p++) begin : g_errors
    // l2 corrupt 报告优先（其 report_to_beu=0，因为 L2 已上报过）
    assign errors_valid[p]              = s2_l2_report[p] | (s2_corrupt_refetch[p] & s2_err_en);
    assign errors_bits[p].paddr         = s2_l2_report[p] ? s2_l2_report_paddr[p] : s2_paddr[p];
    assign errors_bits[p].report_to_beu = ~s2_l2_report[p] & s2_corrupt_refetch[p] & s2_err_en;
  end

  for (genvar p = 0; p < PORT_NUM; p++) begin : g_metaflush
    assign metaFlush_valid[p]        = s2_corrupt_refetch[p] & s2_err_en;
    assign metaFlush_bits[p].virIdx  = s2_vSetIdx[p];
    // meta 损坏 → 清全部路（waymask 不可信）；data 损坏 → 只清出错那一路
    assign metaFlush_bits[p].waymask = s2_meta_corrupt[p] ? {N_WAYS{1'b1}} : s2_waymask[p];
  end

  // ===========================================================================
  // 响应 IFU
  // ===========================================================================
  assign fetch_resp_valid             = s2_fire;
  assign fetch_resp_bits.doubleline   = s2_doubleline;
  assign fetch_resp_bits.vaddr[0]     = s2_vaddr[0];
  assign fetch_resp_bits.vaddr[1]     = s2_vaddr[1];
  assign fetch_resp_bits.data         = s2_datas;   // 8 bank 拼成 512bit（bank0 在低位）
  assign fetch_resp_bits.paddr[0]     = s2_paddr[0];
  assign fetch_resp_bits.paddr[1]     = s2_paddr[1];
  // port0 始终有效；port1 仅 doubleline 时给真值，否则 none/pma
  assign fetch_resp_bits.exception[0] = s2_exception_out[0];
  assign fetch_resp_bits.exception[1] = s2_doubleline ? s2_exception_out[1] : EXCP_NONE;
  assign fetch_resp_bits.pmp_mmio[0]  = s2_pmp_mmio[0];
  assign fetch_resp_bits.pmp_mmio[1]  = s2_doubleline & s2_pmp_mmio[1];
  assign fetch_resp_bits.itlb_pbmt[0] = s2_itlb_pbmt[0];
  assign fetch_resp_bits.itlb_pbmt[1] = s2_doubleline ? s2_itlb_pbmt[1] : PBMT_PMA;
  assign fetch_resp_bits.backendException  = s2_backendException;
  assign fetch_resp_bits.gpaddr            = s2_gpaddr;
  assign fetch_resp_bits.isForVSnonLeafPTE = s2_isForVSnonLeafPTE;

  assign fetch_topdownIcacheMiss = s2_should_fetch[0] | s2_should_fetch[1];
  assign fetch_topdownItlbMiss   = fetch_req_valid & ~s0_fire;

  // ===========================================================================
  // 性能计数
  // ===========================================================================
  assign perfInfo.only_0_hit      = s2_hit[0] & ~s2_doubleline;
  assign perfInfo.only_0_miss     = ~s2_hit[0] & ~s2_doubleline;
  assign perfInfo.hit_0_hit_1     = s2_hit[0] & s2_hit[1] & s2_doubleline;
  assign perfInfo.hit_0_miss_1    = s2_hit[0] & ~s2_hit[1] & s2_doubleline;
  assign perfInfo.miss_0_hit_1    = ~s2_hit[0] & s2_hit[1] & s2_doubleline;
  assign perfInfo.miss_0_miss_1   = ~s2_hit[0] & ~s2_hit[1] & s2_doubleline;
  assign perfInfo.hit_0_except_1  = s2_hit[0] & (|s2_exception[1]) & s2_doubleline;
  assign perfInfo.miss_0_except_1 = ~s2_hit[0] & (|s2_exception[1]) & s2_doubleline;
  assign perfInfo.except_0        = |s2_exception[0];
  assign perfInfo.bank_hit[0]     = s2_hit[0];
  assign perfInfo.bank_hit[1]     = s2_hit[1] & s2_doubleline;
  assign perfInfo.hit             = s2_hit[0] & (~s2_doubleline | s2_hit[1]);

endmodule
