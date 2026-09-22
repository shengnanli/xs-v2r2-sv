// =============================================================================
// xs_ICacheMainPipe —— ICache 取指主流水（FTQ 请求 → data SRAM/MSHR 取数 → 回 IFU）
//
// 对应 Chisel: xiangshan.frontend.icache.ICacheMainPipe（ICacheMainPipe.scala）
// golden: G1-canonical/golden-rtl/ICacheMainPipe.sv（firtool 展平，1532 行 / 189 端口）
//
// 【它在 ICache 里的位置】
//   IPrefetchPipe 已经替每个取指块查过 iTLB 和 meta，把 waymask/ptag/例外 写进
//   WayLookup。本流水从 FTQ 收到取指请求时，同拍从 WayLookup 读出这些信息，直接按
//   waymask 去 data SRAM 取 8 个 bank 的数据；miss 的行向 MissUnit 要，回填到达时
//   （不论在 s1 还是 s2）就地接住；最后把一整个 cacheline（512b）连同例外/属性回给 IFU。
//
//     FTQ req + WayLookup ─▶ s0(发 data SRAM 读) ─▶ s1(收 SRAM 数据/PMP/监听 MSHR)
//                                                 ─▶ s2(ECC 检查/向 MissUnit 要/监听 MSHR/回 IFU)
//
// 【s0】组合级。能走 = data SRAM 第 3 路 ready 且 WayLookup 有项 且 s1 空。FTQ 送来
//   5 份地址（pcMemRead 0..3 给 data SRAM 的 4 个"part way"，4 号给本流水自己）。
//   golden 的 toIData 端口是被 firtool 按 DataArray 的实际消费裁剪过的：只有第 0 路
//   带 waymask/blkOffset、只有第 3 路有 ready —— 这里照端口契约原样保留。
//
// 【s1】把 WayLookup 读出的信息锁存；收 data SRAM 的回应（RegNext(s0_fire) 那拍取线上
//   值，之后用寄存器副本 —— DataHoldBypass）；同时监听 MissUnit 回填：命中同一行就用
//   回填数据覆盖对应 bank（bankMSHRHit：第 0 口占 bank[low..7]，第 1 口占 bank[0..low-1]，
//   low = 块内偏移 >> 3）。做 meta ECC 检查（奇偶不符或多路命中）。s1_hits 用
//   ValidHoldBypass 保持到 s1 fire。
//
// 【s2】等 PMP 回应；data ECC 检查（只查从 SRAM 来的 bank，回填来的不查）；meta/data
//   出错就向 MissUnit 重取并冲掉 meta（metaArrayFlush）、报 errors；miss / 出错重取的
//   行经固定优先级仲裁向 MissUnit 发请求（has_send 防重复）；s2 期间回填到达也接住，
//   并记下 L2 报的 corrupt（回 IFU 时当 af）。s2 fire = 无需再取 且 IFU 不反压。
//
// 【照抄 golden 的几处怪癖（bug-for-bug）】
//   * s1 监听 MSHR 要求 !corrupt，s2 监听不看 corrupt（corrupt 也算 hit，让 s2 能 fire）。
//   * cntFtqFireInterval：XSPerfHistogram 的 32 位计数器，本配置下没有任何读者，
//     golden 照样保留（cone-dead）。这里同样保留一份，FM 用 vmucp 把它当比对点证。
//   * golden 里 RegNext(s0_fire) 展平成 21 份、RegNext(s1_fire) 展平成 12 份完全相同的
//     无复位寄存器；这里各只留一份（s0_fire_q / s1_fire_q）。
//   * io_errors 的 paddr 走"上一拍 s2_req_paddr"寄存器（L2 corrupt 报告晚一拍）。
//   * DiffTest refill 探针（gatewayIn_packed_0/1_bore）valid 恒 0、index 恒 3/4。
//
// 【文件结构】package xs_icachemainpipe_pkg → 核 xs_ICacheMainPipe（struct 端口）
//            → golden 同名 wrapper ICacheMainPipe（扁平端口，仅打包/拆包）
// =============================================================================
package xs_icachemainpipe_pkg;
  // ---- 规模参数（KunminghuV2 ICache）----
  localparam int unsigned PORT_NUM     = 2;    // 一次取指最多跨 2 个 cacheline
  localparam int unsigned N_WAYS       = 4;
  localparam int unsigned N_BANKS      = 8;    // ICacheDataBanks
  localparam int unsigned BANK_W       = 64;   // 512b / 8
  localparam int unsigned LINE_W       = N_BANKS * BANK_W;   // 512
  localparam int unsigned PART_WAY_NUM = 4;    // data SRAM 的 4 个读口
  localparam int unsigned N_PCMEM      = PART_WAY_NUM + 1;   // FTQ 送来 5 份地址
  localparam int unsigned VADDR_W      = 50;
  localparam int unsigned PADDR_W      = 48;
  localparam int unsigned GPADDR_W     = 56;
  localparam int unsigned BLK_OFF_BITS = 6;
  localparam int unsigned IDX_BITS     = 8;
  localparam int unsigned UNTAG_BITS   = 12;
  localparam int unsigned TAG_BITS     = PADDR_W - UNTAG_BITS;    // 36
  localparam int unsigned BLK_PADDR_W  = PADDR_W - BLK_OFF_BITS;  // 42
  localparam int unsigned BANK_IDX_W   = 3;    // log2(N_BANKS)：块内偏移 >> 3 = bank 号
  localparam int unsigned EXCP_W       = 2;
  localparam int unsigned PBMT_W       = 2;
  localparam int unsigned META_CODE_W  = 1;
  localparam int unsigned DATA_CODE_W  = 1;    // 每 bank 1 位奇偶
  localparam int unsigned HART_ID_W    = 6;
  localparam int unsigned WAY_IDX_W    = 2;    // log2(N_WAYS)

  localparam logic [EXCP_W-1:0] EXCP_NONE = 2'd0;
  localparam logic [EXCP_W-1:0] EXCP_AF   = 2'd3;
  localparam logic [PBMT_W-1:0] PBMT_NC   = 2'd1;
  localparam logic [PBMT_W-1:0] PBMT_IO   = 2'd2;

  // ---- 端口 bundle ----
  typedef struct packed {                       // FtqICacheInfo 的一份地址
    logic [VADDR_W-1:0] startAddr;
    logic [VADDR_W-1:0] nextlineStart;
  } pc_mem_read_t;

  typedef struct packed {                       // FtqToICacheRequestBundle
    pc_mem_read_t [N_PCMEM-1:0] pcMemRead;
    logic         [N_PCMEM-1:0] readValid;
    logic                       backendException;
    logic                       hasSatpFlush;
  } fetch_req_t;

  typedef struct packed {                       // WayLookupEntry 的一个口
    logic [IDX_BITS-1:0]    vSetIdx;
    logic [N_WAYS-1:0]      waymask;
    logic [TAG_BITS-1:0]    ptag;
    logic [EXCP_W-1:0]      itlb_exception;
    logic [PBMT_W-1:0]      itlb_pbmt;
    logic [META_CODE_W-1:0] meta_codes;
  } way_lookup_port_t;

  typedef struct packed {                       // WayLookupInfo
    way_lookup_port_t [PORT_NUM-1:0] entry;
    logic [GPADDR_W-1:0]             gpf_gpaddr;
    logic                            gpf_isForVSnonLeafPTE;
  } way_lookup_info_t;

  typedef struct packed {                       // ICacheDataRespBundle
    logic [N_BANKS-1:0][BANK_W-1:0]      datas;
    logic [N_BANKS-1:0][DATA_CODE_W-1:0] codes;
  } data_resp_t;

  typedef struct packed {                       // ICacheMissReq
    logic [BLK_PADDR_W-1:0] blkPaddr;
    logic [IDX_BITS-1:0]    vSetIdx;
  } miss_req_t;

  typedef struct packed {                       // ICacheMissResp
    logic [BLK_PADDR_W-1:0] blkPaddr;
    logic [IDX_BITS-1:0]    vSetIdx;
    logic [LINE_W-1:0]      data;
    logic                   corrupt;
  } miss_resp_t;

  typedef struct packed {                       // PMPRespBundle 里本流水用到的字段
    logic instr;
    logic mmio;
  } pmp_resp_t;

  typedef struct packed {                       // ICacheMetaFlushBundle
    logic [IDX_BITS-1:0] virIdx;
    logic [N_WAYS-1:0]   waymask;
  } meta_flush_t;

  typedef struct packed {                       // ReplacerTouch
    logic [IDX_BITS-1:0]  vSetIdx;
    logic [WAY_IDX_W-1:0] way;
  } touch_t;

  typedef struct packed {                       // L1CacheErrorInfo 里被保留的字段
    logic [PADDR_W-1:0] paddr;
    logic               report_to_beu;
  } error_info_t;

  typedef struct packed {                       // ICacheMainPipeBundle.resp（firtool 只留 paddr_0）
    logic                             doubleline;
    logic [PORT_NUM-1:0][VADDR_W-1:0] vaddr;
    logic [LINE_W-1:0]                data;
    logic [PADDR_W-1:0]               paddr_0;
    logic [PORT_NUM-1:0][EXCP_W-1:0]  exception;
    logic [PORT_NUM-1:0]              pmp_mmio;
    logic [PORT_NUM-1:0][PBMT_W-1:0]  itlb_pbmt;
    logic                             backendException;
    logic                             hasSatpFlush;
    logic [GPADDR_W-1:0]              gpaddr;
    logic                             isForVSnonLeafPTE;
  } fetch_resp_t;

  typedef struct packed {                       // ICachePerfInfo
    logic only_0_hit;
    logic only_0_miss;
    logic hit_0_hit_1;
    logic hit_0_miss_1;
    logic miss_0_hit_1;
    logic miss_0_miss_1;
    logic hit_0_except_1;
    logic miss_0_except_1;
    logic except_0;
    logic [PORT_NUM-1:0] bank_hit;
    logic hit;
  } perf_info_t;

  // DiffTest 的 refill 事件探针（DiffRefillEvent）。golden 扁平拼成 gatewayIn_packed_N_bore：
  //   {valid, addr, data_7..data_0, mask, coreid, index} = 1+64+512+8+8+8 = 601 位。
  typedef struct packed {
    logic                    valid;    // 本配置恒 0（Scala 里 difftest.valid := false.B）
    logic [63:0]             addr;     // 该 line 的物理起始地址
    logic [N_BANKS-1:0][63:0] data;    // = s2_datas，字 7 在最高位
    logic [7:0]              mask;     // 该口命中的 bank 位图（bankSel）
    logic [7:0]              coreid;   // = {2'h0, hartId}
    logic [7:0]              index;    // 魔数 3 / 4：MainPipe 的两个口
  } difftest_refill_t;
  localparam int unsigned DIFFTEST_REFILL_W = $bits(difftest_refill_t);  // 601

  // ---- 地址切片 ----
  function automatic logic [IDX_BITS-1:0] get_idx(input logic [VADDR_W-1:0] vaddr);
    return vaddr[BLK_OFF_BITS +: IDX_BITS];
  endfunction

  function automatic logic [BLK_OFF_BITS-1:0] get_blk_offset(input logic [VADDR_W-1:0] vaddr);
    return vaddr[BLK_OFF_BITS-1:0];
  endfunction

  function automatic logic [TAG_BITS-1:0] get_phy_tag_from_blk(input logic [BLK_PADDR_W-1:0] blk);
    return blk[BLK_PADDR_W-1 : BLK_OFF_BITS];
  endfunction

  // paddr = {ptag, vaddr 的页内偏移}
  function automatic logic [PADDR_W-1:0] get_paddr_from_ptag(input logic [VADDR_W-1:0] vaddr,
                                                             input logic [TAG_BITS-1:0] ptag);
    return {ptag, vaddr[UNTAG_BITS-1:0]};
  endfunction

  function automatic logic [BLK_PADDR_W-1:0] get_blk_addr(input logic [PADDR_W-1:0] paddr);
    return paddr[PADDR_W-1 : BLK_OFF_BITS];
  endfunction

  function automatic logic [META_CODE_W-1:0] encode_meta_ecc(input logic [TAG_BITS-1:0] ptag);
    return ^ptag;
  endfunction

  function automatic logic [DATA_CODE_W-1:0] encode_data_ecc(input logic [BANK_W-1:0] data);
    return ^data;
  endfunction

  function automatic logic [EXCP_W-1:0] excp_merge(input logic [EXCP_W-1:0] a,
                                                   input logic [EXCP_W-1:0] b);
    return (|a) ? a : b;
  endfunction

  function automatic logic pbmt_is_uncache(input logic [PBMT_W-1:0] pbmt);
    return (pbmt == PBMT_NC) | (pbmt == PBMT_IO);
  endfunction

  // OHToUInt（4 路 one-hot → 2 位路号）
  function automatic logic [WAY_IDX_W-1:0] way_oh_to_idx(input logic [N_WAYS-1:0] oh);
    return {oh[3] | oh[2], oh[3] | oh[1]};
  endfunction

  // getBankSel：一次取指从 blkOffset 起连续访问 5 个 bank（32B），跨行时后半落在第 1 口。
  //   bankIdxLow  = blkOffset >> 3；bankIdxHigh = (blkOffset + 32) >> 3 = low + 4；
  //   16 个候选 bank（第 0 口 0..7，第 1 口 8..15）里 [low, high] 那 5 个被选中。
  function automatic logic [PORT_NUM-1:0][N_BANKS-1:0] get_bank_sel(input logic [BLK_OFF_BITS-1:0] blk_offset);
    logic [BLK_OFF_BITS:0] off_low, off_high;
    logic [PORT_NUM*N_BANKS-1:0] sel;
    off_low  = {1'b0, blk_offset};
    off_high = {1'b0, blk_offset} + (BLK_OFF_BITS+1)'(32);
    for (int i = 0; i < PORT_NUM*N_BANKS; i++)
      sel[i] = ((BLK_OFF_BITS+1)'(i) >= (off_low >> BANK_IDX_W)) & ((BLK_OFF_BITS+1)'(i) <= (off_high >> BANK_IDX_W));
    return sel;
  endfunction
endpackage


// =============================================================================
// 核：xs_ICacheMainPipe
// =============================================================================
module xs_ICacheMainPipe
  import xs_icachemainpipe_pkg::*;
(
  input  logic                                   clock,
  input  logic                                   reset,          // 异步高有效
  input  logic [HART_ID_W-1:0]                   io_hartId,
  // data SRAM 读口（4 个 part way；端口按 golden 契约裁剪：只有第 0 路带 waymask/
  // blkOffset，只有第 3 路有 ready）
  output logic [PART_WAY_NUM-1:0]                io_toIData_valid,
  output logic [PART_WAY_NUM-1:0][PORT_NUM-1:0][IDX_BITS-1:0] io_toIData_vSetIdx,
  output logic [PORT_NUM-1:0][N_WAYS-1:0]        io_toIData_0_waymask,
  output logic [BLK_OFF_BITS-1:0]                io_toIData_0_blkOffset,
  input  logic                                   io_toIData_3_ready,
  input  data_resp_t                             io_fromIData,
  // meta 冲刷 / 替换算法 touch
  output logic [PORT_NUM-1:0]                    io_metaArrayFlush_valid,
  output meta_flush_t [PORT_NUM-1:0]             io_metaArrayFlush_bits,
  output logic [PORT_NUM-1:0]                    io_touch_valid,
  output touch_t [PORT_NUM-1:0]                  io_touch_bits,
  // WayLookup 读口
  output logic                                   io_wayLookupRead_ready,
  input  logic                                   io_wayLookupRead_valid,
  input  way_lookup_info_t                       io_wayLookupRead_bits,
  // MissUnit
  input  logic                                   io_mshr_req_ready,
  output logic                                   io_mshr_req_valid,
  output miss_req_t                              io_mshr_req_bits,
  input  logic                                   io_mshr_resp_valid,
  input  miss_resp_t                             io_mshr_resp_bits,
  input  logic                                   io_ecc_enable,
  // FTQ 请求 / IFU 回应
  output logic                                   io_fetch_req_ready,
  input  logic                                   io_fetch_req_valid,
  input  fetch_req_t                             io_fetch_req_bits,
  output logic                                   io_fetch_resp_valid,
  output fetch_resp_t                            io_fetch_resp_bits,
  output logic                                   io_fetch_topdownIcacheMiss,
  output logic                                   io_fetch_topdownItlbMiss,
  input  logic                                   io_flush,
  // PMP
  output logic [PORT_NUM-1:0]                    io_pmp_req_valid,
  output logic [PORT_NUM-1:0][PADDR_W-1:0]       io_pmp_req_addr,
  input  pmp_resp_t [PORT_NUM-1:0]               io_pmp_resp,
  input  logic                                   io_respStall,
  // 错误上报 / perf / DiffTest
  output logic [PORT_NUM-1:0]                    io_errors_valid,
  output error_info_t [PORT_NUM-1:0]             io_errors_bits,
  output perf_info_t                             io_perfInfo,
  output difftest_refill_t [PORT_NUM-1:0]        difftest_refill
);

  // ---------------------------------------------------------------------------
  // 级间控制线
  // ---------------------------------------------------------------------------
  logic s1_ready, s1_fire, s2_ready, s2_fire;

  // ===========================================================================
  // s0：接 FTQ 请求，发 data SRAM 读，从 WayLookup 取 waymask/ptag/例外
  // ===========================================================================
  logic s0_can_go, s0_fire;
  assign s0_can_go = io_toIData_3_ready & io_wayLookupRead_valid & s1_ready;
  assign s0_fire   = io_fetch_req_valid & s0_can_go & ~io_flush;
  assign io_fetch_req_ready     = s0_can_go;
  assign io_wayLookupRead_ready = s0_fire;

  // 4 号地址是本流水自己用的那份；0..3 号分别给 data SRAM 的 4 个读口
  pc_mem_read_t s0_req;
  assign s0_req = io_fetch_req_bits.pcMemRead[N_PCMEM-1];
  logic [PORT_NUM-1:0][VADDR_W-1:0] s0_req_vaddr;
  assign s0_req_vaddr[0] = s0_req.startAddr;
  assign s0_req_vaddr[1] = s0_req.nextlineStart;
  logic s0_doubleline;
  assign s0_doubleline = io_fetch_req_bits.readValid[N_PCMEM-1] & s0_req.startAddr[5];   // crossCacheline

  for (genvar i = 0; i < PART_WAY_NUM; i++) begin : g_todata
    assign io_toIData_valid[i]      = io_fetch_req_bits.readValid[i];
    assign io_toIData_vSetIdx[i][0] = get_idx(io_fetch_req_bits.pcMemRead[i].startAddr);
    assign io_toIData_vSetIdx[i][1] = get_idx(io_fetch_req_bits.pcMemRead[i].nextlineStart);
  end
  for (genvar p = 0; p < PORT_NUM; p++) begin : g_todata_way
    assign io_toIData_0_waymask[p] = io_wayLookupRead_bits.entry[p].waymask;
  end
  assign io_toIData_0_blkOffset = get_blk_offset(io_fetch_req_bits.pcMemRead[0].startAddr);

  // XSPerfHistogram("ftq2icache_fire") 的计数器：fire 拍清 1，否则 +1。本配置下没有读者
  //（cone-dead），照 golden 保留。
  logic [31:0] cntFtqFireInterval;
  always_ff @(posedge clock or posedge reset) begin
    if (reset)                                cntFtqFireInterval <= '0;
    else if (io_fetch_req_valid & s0_can_go)  cntFtqFireInterval <= 32'd1;
    else                                      cntFtqFireInterval <= cntFtqFireInterval + 32'd1;
  end

  // ===========================================================================
  // s1：锁存 WayLookup 信息；收 data SRAM 回应；PMP；监听 MSHR 回填；meta ECC
  // ===========================================================================
  logic                              s1_valid;
  logic [PORT_NUM-1:0][VADDR_W-1:0]  s1_req_vaddr;
  logic [PORT_NUM-1:0][TAG_BITS-1:0] s1_req_ptags;
  logic [GPADDR_W-1:0]               s1_req_gpaddr;
  logic                              s1_req_isForVSnonLeafPTE;
  logic                              s1_doubleline;
  logic [PORT_NUM-1:0]               s1_SRAMhits;        // WayLookup 说该口在 SRAM 里命中
  logic [PORT_NUM-1:0][EXCP_W-1:0]   s1_itlb_exception;
  logic                              s1_backendException;
  logic                              s1_hasSatpFlush;
  logic [PORT_NUM-1:0][PBMT_W-1:0]   s1_itlb_pbmt;
  logic [PORT_NUM-1:0][N_WAYS-1:0]   s1_waymasks;
  logic [PORT_NUM-1:0][META_CODE_W-1:0] s1_meta_codes;
  logic                              s0_fire_q;          // RegNext(s0_fire)，无复位

  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      s1_valid                 <= 1'b0;
      s1_req_vaddr             <= '0;
      s1_req_ptags             <= '0;
      s1_req_gpaddr            <= '0;
      s1_req_isForVSnonLeafPTE <= 1'b0;
      s1_doubleline            <= 1'b0;
      s1_SRAMhits              <= '0;
      s1_itlb_exception        <= '0;
      s1_backendException      <= 1'b0;
      s1_hasSatpFlush          <= 1'b0;
      s1_itlb_pbmt             <= '0;
      s1_waymasks              <= '0;
      s1_meta_codes            <= '0;
    end
    else begin
      s1_valid <= ~io_flush & (s0_fire | (~s1_fire & s1_valid));
      if (s0_fire) begin
        s1_req_vaddr             <= s0_req_vaddr;
        s1_req_gpaddr            <= io_wayLookupRead_bits.gpf_gpaddr;
        s1_req_isForVSnonLeafPTE <= io_wayLookupRead_bits.gpf_isForVSnonLeafPTE;
        s1_doubleline            <= s0_doubleline;
        s1_backendException      <= io_fetch_req_bits.backendException;
        s1_hasSatpFlush          <= io_fetch_req_bits.hasSatpFlush;
        for (int p = 0; p < PORT_NUM; p++) begin
          s1_req_ptags[p]      <= io_wayLookupRead_bits.entry[p].ptag;
          s1_SRAMhits[p]       <= |io_wayLookupRead_bits.entry[p].waymask;
          s1_itlb_exception[p] <= io_wayLookupRead_bits.entry[p].itlb_exception;
          s1_itlb_pbmt[p]      <= io_wayLookupRead_bits.entry[p].itlb_pbmt;
          s1_waymasks[p]       <= io_wayLookupRead_bits.entry[p].waymask;
          s1_meta_codes[p]     <= io_wayLookupRead_bits.entry[p].meta_codes;
        end
      end
    end
  end

  always_ff @(posedge clock) begin
    s0_fire_q <= s0_fire;
  end

  logic [PORT_NUM-1:0][IDX_BITS-1:0] s1_req_vSetIdx;
  logic [PORT_NUM-1:0][PADDR_W-1:0]  s1_req_paddr;
  for (genvar p = 0; p < PORT_NUM; p++) begin : g_s1_addr
    assign s1_req_vSetIdx[p] = get_idx(s1_req_vaddr[p]);
    assign s1_req_paddr[p]   = get_paddr_from_ptag(s1_req_vaddr[p], s1_req_ptags[p]);
  end
  logic [BANK_IDX_W-1:0] s1_bank_idx_low;   // 第 0 口从哪个 bank 开始
  assign s1_bank_idx_low = get_blk_offset(s1_req_vaddr[0]) >> BANK_IDX_W;

  // ---- meta ECC：命中一路但奇偶不符，或多路命中 ----
  logic [PORT_NUM-1:0] s1_meta_corrupt;
  for (genvar p = 0; p < PORT_NUM; p++) begin : g_s1_meta_ecc
    localparam logic PORT_ALWAYS = (p == 0);
    logic [2:0] hit_num;
    assign hit_num = 3'(s1_waymasks[p][0]) + 3'(s1_waymasks[p][1]) + 3'(s1_waymasks[p][2]) + 3'(s1_waymasks[p][3]);
    assign s1_meta_corrupt[p] = io_ecc_enable & (PORT_ALWAYS | s1_doubleline)
      & (((encode_meta_ecc(s1_req_ptags[p]) != s1_meta_codes[p]) & (hit_num == 3'd1)) | (hit_num > 3'd1));
  end

  // ---- 替换算法 touch：SRAM 命中的那一拍（s0 fire 的下一拍）报一次 ----
  assign io_touch_valid[0] = s0_fire_q & s1_SRAMhits[0];
  assign io_touch_valid[1] = s0_fire_q & s1_SRAMhits[1] & s1_doubleline;
  for (genvar p = 0; p < PORT_NUM; p++) begin : g_touch
    assign io_touch_bits[p].vSetIdx = s1_req_vSetIdx[p];
    assign io_touch_bits[p].way     = way_oh_to_idx(s1_waymasks[p]);
  end

  // ---- PMP：s1 有效期间持续查 ----
  for (genvar p = 0; p < PORT_NUM; p++) begin : g_pmp_req
    assign io_pmp_req_valid[p] = s1_valid;
    assign io_pmp_req_addr[p]  = s1_req_paddr[p];
  end

  // ---- 监听 MSHR 回填（s1 要求 !corrupt）----
  logic [PORT_NUM-1:0] s1_MSHR_hits;
  for (genvar p = 0; p < PORT_NUM; p++) begin : g_s1_mshr
    localparam logic PORT_ALWAYS = (p == 0);
    logic match;
    assign match = (s1_req_vSetIdx[p] == io_mshr_resp_bits.vSetIdx)
                 & (s1_req_ptags[p] == get_phy_tag_from_blk(io_mshr_resp_bits.blkPaddr))
                 & io_mshr_resp_valid & ~io_mshr_resp_bits.corrupt;
    assign s1_MSHR_hits[p] = s1_valid & match & (PORT_ALWAYS | s1_doubleline);
  end

  // s1_hits：ValidHoldBypass(MSHR 命中 | SRAM 命中拍, s1_fire | flush)
  logic [PORT_NUM-1:0] s1_hits;
  for (genvar p = 0; p < PORT_NUM; p++) begin : g_s1_hits
    logic set, hold_q;
    assign set = s1_MSHR_hits[p] | (s0_fire_q & s1_SRAMhits[p]);
    always_ff @(posedge clock or posedge reset) begin
      if (reset) hold_q <= 1'b0;
      else       hold_q <= ~(s1_fire | io_flush) & (set | hold_q);
    end
    assign s1_hits[p] = hold_q | set;
  end

  // ---- 每个 bank 的数据：SRAM 回应或 MSHR 回填，DataHoldBypass 保持到 s1 fire ----
  logic [N_BANKS-1:0]             s1_bankMSHRHit;
  logic [N_BANKS-1:0][BANK_W-1:0] s1_datas;
  logic [N_BANKS-1:0]             s1_data_is_from_MSHR;
  logic [N_BANKS-1:0][DATA_CODE_W-1:0] s1_codes;
  logic [N_BANKS-1:0][BANK_W-1:0] mshr_resp_banks;
  assign mshr_resp_banks = io_mshr_resp_bits.data;

  for (genvar b = 0; b < N_BANKS; b++) begin : g_s1_bank
    // 第 0 口的行占 bank[low..7]，第 1 口的行占 bank[0..low-1]
    assign s1_bankMSHRHit[b] = ((BANK_IDX_W'(b) >= s1_bank_idx_low) & s1_MSHR_hits[0])
                             | ((BANK_IDX_W'(b) <  s1_bank_idx_low) & s1_MSHR_hits[1]);

    logic [BANK_W-1:0] data_wire, data_q;         // data_q：无复位（golden s1_datas_r）
    logic              from_mshr_q;               // 无复位（golden s1_data_is_from_MSHR_r）
    logic [DATA_CODE_W-1:0] code_q;               // 无复位（golden s1_codes_r）
    logic              data_en;
    assign data_wire = s1_bankMSHRHit[b] ? mshr_resp_banks[b] : io_fromIData.datas[b];
    assign data_en   = s1_bankMSHRHit[b] | s0_fire_q;
    always_ff @(posedge clock) begin
      if (data_en) begin
        data_q      <= data_wire;
        from_mshr_q <= s1_bankMSHRHit[b];
      end
      if (s0_fire_q) code_q <= io_fromIData.codes[b];
    end
    assign s1_datas[b]            = data_en   ? data_wire            : data_q;
    assign s1_data_is_from_MSHR[b] = data_en  ? s1_bankMSHRHit[b]    : from_mshr_q;
    assign s1_codes[b]            = s0_fire_q ? io_fromIData.codes[b] : code_q;
  end

  assign s1_ready = s2_ready | ~s1_valid;
  assign s1_fire  = s1_valid & s2_ready & ~io_flush;

  // ===========================================================================
  // s2：PMP 回应 / data ECC / 向 MissUnit 要 / 监听回填 / 回 IFU
  // ===========================================================================
  logic                              s2_valid;
  logic [PORT_NUM-1:0][VADDR_W-1:0]  s2_req_vaddr;
  logic [PORT_NUM-1:0][TAG_BITS-1:0] s2_req_ptags;
  logic [GPADDR_W-1:0]               s2_req_gpaddr;
  logic                              s2_req_isForVSnonLeafPTE;
  logic                              s2_doubleline;
  logic [PORT_NUM-1:0][EXCP_W-1:0]   s2_itlb_exception;
  logic                              s2_backendException;
  logic                              s2_hasSatpFlush;
  logic [PORT_NUM-1:0][PBMT_W-1:0]   s2_itlb_pbmt;
  logic [PORT_NUM-1:0][N_WAYS-1:0]   s2_waymasks;
  logic [PORT_NUM-1:0]               s2_SRAMhits;
  logic [N_BANKS-1:0][DATA_CODE_W-1:0] s2_codes;
  logic                              s1_fire_q;          // RegNext(s1_fire)，无复位

  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      s2_valid                 <= 1'b0;
      s2_req_vaddr             <= '0;
      s2_req_ptags             <= '0;
      s2_req_gpaddr            <= '0;
      s2_req_isForVSnonLeafPTE <= 1'b0;
      s2_doubleline            <= 1'b0;
      s2_itlb_exception        <= '0;
      s2_backendException      <= 1'b0;
      s2_hasSatpFlush          <= 1'b0;
      s2_itlb_pbmt             <= '0;
      s2_waymasks              <= '0;
      s2_SRAMhits              <= '0;
      s2_codes                 <= '0;
    end
    else begin
      s2_valid <= ~io_flush & (s1_fire | (~s2_fire & s2_valid));
      if (s1_fire) begin
        s2_req_vaddr             <= s1_req_vaddr;
        s2_req_ptags             <= s1_req_ptags;
        s2_req_gpaddr            <= s1_req_gpaddr;
        s2_req_isForVSnonLeafPTE <= s1_req_isForVSnonLeafPTE;
        s2_doubleline            <= s1_doubleline;
        s2_itlb_exception        <= s1_itlb_exception;
        s2_backendException      <= s1_backendException;
        s2_hasSatpFlush          <= s1_hasSatpFlush;
        s2_itlb_pbmt             <= s1_itlb_pbmt;
        s2_waymasks              <= s1_waymasks;
        s2_SRAMhits              <= s1_SRAMhits;
        s2_codes                 <= s1_codes;
      end
    end
  end

  always_ff @(posedge clock) begin
    s1_fire_q <= s1_fire;
  end

  logic [PORT_NUM-1:0][IDX_BITS-1:0] s2_req_vSetIdx;
  logic [PORT_NUM-1:0][PADDR_W-1:0]  s2_req_paddr;
  for (genvar p = 0; p < PORT_NUM; p++) begin : g_s2_addr
    assign s2_req_vSetIdx[p] = get_idx(s2_req_vaddr[p]);
    assign s2_req_paddr[p]   = get_paddr_from_ptag(s2_req_vaddr[p], s2_req_ptags[p]);
  end
  logic [BANK_IDX_W-1:0] s2_bank_idx_low;
  assign s2_bank_idx_low = get_blk_offset(s2_req_vaddr[0]) >> BANK_IDX_W;

  // ---- PMP 回应：DataHoldBypass(_, RegNext(s1_fire)) ----
  logic [PORT_NUM-1:0][EXCP_W-1:0] s2_pmp_exception;
  logic [PORT_NUM-1:0]             s2_pmp_mmio;
  for (genvar p = 0; p < PORT_NUM; p++) begin : g_s2_pmp
    logic [EXCP_W-1:0] pmp_excp_wire, pmp_excp_q;   // pmp_excp_q/pmp_mmio_q 无复位
    logic              pmp_mmio_q;
    assign pmp_excp_wire = {EXCP_W{io_pmp_resp[p].instr}};   // ExceptionType.fromPMPResp：af
    always_ff @(posedge clock) begin
      if (s1_fire_q) begin
        pmp_excp_q <= pmp_excp_wire;
        pmp_mmio_q <= io_pmp_resp[p].mmio;
      end
    end
    assign s2_pmp_exception[p] = s1_fire_q ? pmp_excp_wire       : pmp_excp_q;
    assign s2_pmp_mmio[p]      = s1_fire_q ? io_pmp_resp[p].mmio : pmp_mmio_q;
  end

  logic [PORT_NUM-1:0][EXCP_W-1:0] s2_exception;   // iTLB > PMP
  logic [PORT_NUM-1:0]             s2_mmio;
  for (genvar p = 0; p < PORT_NUM; p++) begin : g_s2_attr
    assign s2_exception[p] = excp_merge(s2_itlb_exception[p], s2_pmp_exception[p]);
    assign s2_mmio[p]      = s2_pmp_mmio[p] | pbmt_is_uncache(s2_itlb_pbmt[p]);
  end

  // ---- 监听 MSHR 回填（s2 不看 corrupt：corrupt 也算 hit，让 s2 能 fire）----
  logic [PORT_NUM-1:0] s2_MSHR_hits;
  for (genvar p = 0; p < PORT_NUM; p++) begin : g_s2_mshr
    localparam logic PORT_ALWAYS = (p == 0);
    logic match;
    assign match = (s2_req_vSetIdx[p] == io_mshr_resp_bits.vSetIdx)
                 & (s2_req_ptags[p] == get_phy_tag_from_blk(io_mshr_resp_bits.blkPaddr))
                 & io_mshr_resp_valid;
    assign s2_MSHR_hits[p] = s2_valid & match & (PORT_ALWAYS | s2_doubleline);
  end

  logic [N_BANKS-1:0] s2_bankMSHRHit;
  for (genvar b = 0; b < N_BANKS; b++) begin : g_s2_bankhit
    assign s2_bankMSHRHit[b] = ((BANK_IDX_W'(b) >= s2_bank_idx_low) & s2_MSHR_hits[0])
                             | ((BANK_IDX_W'(b) <  s2_bank_idx_low) & s2_MSHR_hits[1]);
  end

  // ---- s2 里的数据/命中/ECC 状态：s1 fire 时整体载入，之后被回填就地更新 ----
  logic [N_BANKS-1:0][BANK_W-1:0] s2_datas;
  logic [N_BANKS-1:0]             s2_data_is_from_MSHR;
  logic [PORT_NUM-1:0]            s2_hits;
  logic [PORT_NUM-1:0]            s2_meta_corrupt;
  logic [PORT_NUM-1:0]            s2_l2_corrupt;   // 回填时 L2 报的 corrupt

  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      s2_datas             <= '0;
      s2_data_is_from_MSHR <= '0;
    end
    else if (s1_fire) begin
      s2_datas             <= s1_datas;
      s2_data_is_from_MSHR <= s1_data_is_from_MSHR;
    end
    else begin
      for (int b = 0; b < N_BANKS; b++) begin
        if (s2_bankMSHRHit[b]) begin
          s2_datas[b]             <= mshr_resp_banks[b];
          s2_data_is_from_MSHR[b] <= 1'b1;   // 重取回来的数据不再做 ECC，让 s2 能 fire
        end
      end
    end
  end

  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      s2_hits         <= '0;
      s2_meta_corrupt <= '0;
      s2_l2_corrupt   <= '0;
    end
    else if (s1_fire) begin
      s2_hits         <= s1_hits;
      s2_meta_corrupt <= s1_meta_corrupt;
      s2_l2_corrupt   <= '0;
    end
    else begin
      for (int p = 0; p < PORT_NUM; p++) begin
        if (s2_MSHR_hits[p]) begin
          s2_hits[p]         <= 1'b1;      // corrupt 也置 hit，让 s2 能 fire
          s2_meta_corrupt[p] <= 1'b0;      // 重取回来后清掉 meta 出错标记
          s2_l2_corrupt[p]   <= io_mshr_resp_bits.corrupt;
        end
      end
    end
  end

  // ---- data ECC：只查从 SRAM 来的、且本口真的访问了的 bank ----
  logic [PORT_NUM-1:0][N_BANKS-1:0] s2_bankSel;
  assign s2_bankSel = get_bank_sel(get_blk_offset(s2_req_vaddr[0]));
  logic [N_BANKS-1:0] s2_bank_corrupt;
  for (genvar b = 0; b < N_BANKS; b++) begin : g_s2_bank_ecc
    assign s2_bank_corrupt[b] = encode_data_ecc(s2_datas[b]) != s2_codes[b];
  end
  logic [PORT_NUM-1:0] s2_data_corrupt, s2_corrupt_refetch;
  for (genvar p = 0; p < PORT_NUM; p++) begin : g_s2_data_ecc
    assign s2_data_corrupt[p] = io_ecc_enable
      & (|(s2_bank_corrupt & s2_bankSel[p] & ~s2_data_is_from_MSHR))
      & s2_SRAMhits[p];
    assign s2_corrupt_refetch[p] = s2_meta_corrupt[p] | s2_data_corrupt[p];
  end

  // ---- 冲掉出错的 meta；上报错误（ECC 错当拍报，L2 corrupt 晚一拍报）----
  for (genvar p = 0; p < PORT_NUM; p++) begin : g_s2_err
    logic               l2_err_q;      // RegNext(s2_fire && s2_l2_corrupt)，无复位
    logic [PADDR_W-1:0] paddr_q;       // RegNext(s2_req_paddr)，无复位
    always_ff @(posedge clock) begin
      l2_err_q <= s2_fire & s2_l2_corrupt[p];
      paddr_q  <= s2_req_paddr[p];
    end
    assign io_metaArrayFlush_valid[p]        = s2_corrupt_refetch[p] & s1_fire_q;
    assign io_metaArrayFlush_bits[p].virIdx  = s2_req_vSetIdx[p];
    // meta 出错时 waymask 不可信，全路冲掉；data 出错只冲出错的那一路
    assign io_metaArrayFlush_bits[p].waymask = s2_meta_corrupt[p] ? {N_WAYS{1'b1}} : s2_waymasks[p];

    assign io_errors_valid[p]              = l2_err_q | (s2_corrupt_refetch[p] & s1_fire_q);
    assign io_errors_bits[p].paddr         = l2_err_q ? paddr_q : s2_req_paddr[p];
    // L2 已经报过 BEU，这里不再报
    assign io_errors_bits[p].report_to_beu = ~l2_err_q & s2_corrupt_refetch[p] & s1_fire_q;
  end

  // ---- 向 MissUnit 要：没命中或 ECC 出错要重取；有例外 / mmio 的不取 ----
  logic [PORT_NUM-1:0] s2_should_fetch;
  assign s2_should_fetch[0] = (~s2_hits[0] | s2_corrupt_refetch[0])
                            & (s2_exception[0] == EXCP_NONE) & ~s2_mmio[0];
  assign s2_should_fetch[1] = (~s2_hits[1] | s2_corrupt_refetch[1]) & s2_doubleline
                            & ~((|s2_exception[0]) | (|s2_exception[1]))
                            & ~s2_mmio[0] & ~s2_mmio[1];

  logic [PORT_NUM-1:0] s2_has_send, toMSHR_in_valid, toMSHR_in_ready;
  for (genvar p = 0; p < PORT_NUM; p++) begin : g_s2_send
    logic has_send_q;
    assign s2_has_send[p]     = has_send_q;
    assign toMSHR_in_valid[p] = s2_valid & s2_should_fetch[p] & ~has_send_q & ~io_flush;
    always_ff @(posedge clock or posedge reset) begin
      if (reset)                                        has_send_q <= 1'b0;
      else if (s1_fire)                                 has_send_q <= 1'b0;
      else if (toMSHR_in_ready[p] & toMSHR_in_valid[p]) has_send_q <= 1'b1;
    end
  end

  Arbiter2_ICacheMissReq toMSHRArbiter (
    .io_in_0_ready         (toMSHR_in_ready[0]),
    .io_in_0_valid         (toMSHR_in_valid[0]),
    .io_in_0_bits_blkPaddr (get_blk_addr(s2_req_paddr[0])),
    .io_in_0_bits_vSetIdx  (s2_req_vSetIdx[0]),
    .io_in_1_ready         (toMSHR_in_ready[1]),
    .io_in_1_valid         (toMSHR_in_valid[1]),
    .io_in_1_bits_blkPaddr (get_blk_addr(s2_req_paddr[1])),
    .io_in_1_bits_vSetIdx  (s2_req_vSetIdx[1]),
    .io_out_ready          (io_mshr_req_ready),
    .io_out_valid          (io_mshr_req_valid),
    .io_out_bits_blkPaddr  (io_mshr_req_bits.blkPaddr),
    .io_out_bits_vSetIdx   (io_mshr_req_bits.vSetIdx)
  );

  logic s2_fetch_finish;
  assign s2_fetch_finish = ~(|s2_should_fetch);
  assign s2_ready = (s2_fetch_finish & ~io_respStall) | ~s2_valid;
  assign s2_fire  = s2_valid & s2_fetch_finish & ~io_respStall & ~io_flush;

  // ---- 回 IFU ----
  logic [PORT_NUM-1:0][EXCP_W-1:0] s2_exception_out;   // 再合并 L2 corrupt（当 af）
  for (genvar p = 0; p < PORT_NUM; p++) begin : g_s2_excp_out
    assign s2_exception_out[p] = excp_merge(s2_exception[p], {EXCP_W{s2_l2_corrupt[p]}});
  end

  assign io_fetch_resp_valid                  = s2_fire;
  assign io_fetch_resp_bits.doubleline        = s2_doubleline;
  assign io_fetch_resp_bits.vaddr             = s2_req_vaddr;
  assign io_fetch_resp_bits.data              = s2_datas;
  assign io_fetch_resp_bits.paddr_0           = s2_req_paddr[0];
  assign io_fetch_resp_bits.exception[0]      = s2_exception_out[0];
  assign io_fetch_resp_bits.exception[1]      = s2_doubleline ? s2_exception_out[1] : EXCP_NONE;
  assign io_fetch_resp_bits.pmp_mmio[0]       = s2_pmp_mmio[0];
  assign io_fetch_resp_bits.pmp_mmio[1]       = s2_doubleline & s2_pmp_mmio[1];
  assign io_fetch_resp_bits.itlb_pbmt[0]      = s2_itlb_pbmt[0];
  assign io_fetch_resp_bits.itlb_pbmt[1]      = s2_doubleline ? s2_itlb_pbmt[1] : '0;   // Pbmt.pma
  assign io_fetch_resp_bits.backendException  = s2_backendException;
  assign io_fetch_resp_bits.hasSatpFlush      = s2_hasSatpFlush;
  assign io_fetch_resp_bits.gpaddr            = s2_req_gpaddr;
  assign io_fetch_resp_bits.isForVSnonLeafPTE = s2_req_isForVSnonLeafPTE;

  assign io_fetch_topdownIcacheMiss = s2_valid & ~s2_fetch_finish;
  assign io_fetch_topdownItlbMiss   = io_fetch_req_valid & ~s0_fire;   // s0_valid && !fromWayLookup.ready

  // ---- perf ----
  assign io_perfInfo.only_0_hit      =  s2_hits[0] & ~s2_doubleline;
  assign io_perfInfo.only_0_miss     = ~s2_hits[0] & ~s2_doubleline;
  assign io_perfInfo.hit_0_hit_1     =  s2_hits[0] &  s2_hits[1] & s2_doubleline;
  assign io_perfInfo.hit_0_miss_1    =  s2_hits[0] & ~s2_hits[1] & s2_doubleline;
  assign io_perfInfo.miss_0_hit_1    = ~s2_hits[0] &  s2_hits[1] & s2_doubleline;
  assign io_perfInfo.miss_0_miss_1   = ~s2_hits[0] & ~s2_hits[1] & s2_doubleline;
  assign io_perfInfo.hit_0_except_1  =  s2_hits[0] & (|s2_exception[1]) & s2_doubleline;
  assign io_perfInfo.miss_0_except_1 = ~s2_hits[0] & (|s2_exception[1]) & s2_doubleline;
  assign io_perfInfo.except_0        = |s2_exception[0];
  assign io_perfInfo.bank_hit[0]     = s2_hits[0];
  assign io_perfInfo.bank_hit[1]     = s2_hits[1] & s2_doubleline;
  assign io_perfInfo.hit             = s2_hits[0] & (~s2_doubleline | s2_hits[1]);

  // ---- DiffTest refill 探针（valid 恒 0；index 3/4 是 MainPipe 两个口的魔数）----
  for (genvar p = 0; p < PORT_NUM; p++) begin : g_difftest
    assign difftest_refill[p].valid  = 1'b0;
    assign difftest_refill[p].addr   = 64'({s2_req_ptags[p], s2_req_vaddr[p][UNTAG_BITS-1:BLK_OFF_BITS], {BLK_OFF_BITS{1'b0}}});
    assign difftest_refill[p].data   = s2_datas;
    assign difftest_refill[p].mask   = s2_bankSel[p];
    assign difftest_refill[p].coreid = 8'(io_hartId);
    assign difftest_refill[p].index  = 8'(3 + p);
  end

endmodule


// =============================================================================
// golden 同名 wrapper：ICacheMainPipe（扁平端口 ↔ xs_ICacheMainPipe 的 struct 端口）
// 只做机械的打包/拆包，供 FM 对比与 ST 替换。
// =============================================================================
module ICacheMainPipe
  import xs_icachemainpipe_pkg::*;
(
  input          clock,
  input          reset,
  input  [5:0]   io_hartId,
  output         io_dataArray_toIData_0_valid,
  output [7:0]   io_dataArray_toIData_0_bits_vSetIdx_0,
  output [7:0]   io_dataArray_toIData_0_bits_vSetIdx_1,
  output         io_dataArray_toIData_0_bits_waymask_0_0,
  output         io_dataArray_toIData_0_bits_waymask_0_1,
  output         io_dataArray_toIData_0_bits_waymask_0_2,
  output         io_dataArray_toIData_0_bits_waymask_0_3,
  output         io_dataArray_toIData_0_bits_waymask_1_0,
  output         io_dataArray_toIData_0_bits_waymask_1_1,
  output         io_dataArray_toIData_0_bits_waymask_1_2,
  output         io_dataArray_toIData_0_bits_waymask_1_3,
  output [5:0]   io_dataArray_toIData_0_bits_blkOffset,
  output         io_dataArray_toIData_1_valid,
  output [7:0]   io_dataArray_toIData_1_bits_vSetIdx_0,
  output [7:0]   io_dataArray_toIData_1_bits_vSetIdx_1,
  output         io_dataArray_toIData_2_valid,
  output [7:0]   io_dataArray_toIData_2_bits_vSetIdx_0,
  output [7:0]   io_dataArray_toIData_2_bits_vSetIdx_1,
  input          io_dataArray_toIData_3_ready,
  output         io_dataArray_toIData_3_valid,
  output [7:0]   io_dataArray_toIData_3_bits_vSetIdx_0,
  output [7:0]   io_dataArray_toIData_3_bits_vSetIdx_1,
  input  [63:0]  io_dataArray_fromIData_datas_0,
  input  [63:0]  io_dataArray_fromIData_datas_1,
  input  [63:0]  io_dataArray_fromIData_datas_2,
  input  [63:0]  io_dataArray_fromIData_datas_3,
  input  [63:0]  io_dataArray_fromIData_datas_4,
  input  [63:0]  io_dataArray_fromIData_datas_5,
  input  [63:0]  io_dataArray_fromIData_datas_6,
  input  [63:0]  io_dataArray_fromIData_datas_7,
  input          io_dataArray_fromIData_codes_0,
  input          io_dataArray_fromIData_codes_1,
  input          io_dataArray_fromIData_codes_2,
  input          io_dataArray_fromIData_codes_3,
  input          io_dataArray_fromIData_codes_4,
  input          io_dataArray_fromIData_codes_5,
  input          io_dataArray_fromIData_codes_6,
  input          io_dataArray_fromIData_codes_7,
  output         io_metaArrayFlush_0_valid,
  output [7:0]   io_metaArrayFlush_0_bits_virIdx,
  output [3:0]   io_metaArrayFlush_0_bits_waymask,
  output         io_metaArrayFlush_1_valid,
  output [7:0]   io_metaArrayFlush_1_bits_virIdx,
  output [3:0]   io_metaArrayFlush_1_bits_waymask,
  output         io_touch_0_valid,
  output [7:0]   io_touch_0_bits_vSetIdx,
  output [1:0]   io_touch_0_bits_way,
  output         io_touch_1_valid,
  output [7:0]   io_touch_1_bits_vSetIdx,
  output [1:0]   io_touch_1_bits_way,
  output         io_wayLookupRead_ready,
  input          io_wayLookupRead_valid,
  input  [7:0]   io_wayLookupRead_bits_entry_vSetIdx_0,
  input  [7:0]   io_wayLookupRead_bits_entry_vSetIdx_1,
  input  [3:0]   io_wayLookupRead_bits_entry_waymask_0,
  input  [3:0]   io_wayLookupRead_bits_entry_waymask_1,
  input  [35:0]  io_wayLookupRead_bits_entry_ptag_0,
  input  [35:0]  io_wayLookupRead_bits_entry_ptag_1,
  input  [1:0]   io_wayLookupRead_bits_entry_itlb_exception_0,
  input  [1:0]   io_wayLookupRead_bits_entry_itlb_exception_1,
  input  [1:0]   io_wayLookupRead_bits_entry_itlb_pbmt_0,
  input  [1:0]   io_wayLookupRead_bits_entry_itlb_pbmt_1,
  input          io_wayLookupRead_bits_entry_meta_codes_0,
  input          io_wayLookupRead_bits_entry_meta_codes_1,
  input  [55:0]  io_wayLookupRead_bits_gpf_gpaddr,
  input          io_wayLookupRead_bits_gpf_isForVSnonLeafPTE,
  input          io_mshr_req_ready,
  output         io_mshr_req_valid,
  output [41:0]  io_mshr_req_bits_blkPaddr,
  output [7:0]   io_mshr_req_bits_vSetIdx,
  input          io_mshr_resp_valid,
  input  [41:0]  io_mshr_resp_bits_blkPaddr,
  input  [7:0]   io_mshr_resp_bits_vSetIdx,
  input  [511:0] io_mshr_resp_bits_data,
  input          io_mshr_resp_bits_corrupt,
  input          io_ecc_enable,
  output         io_fetch_req_ready,
  input          io_fetch_req_valid,
  input  [49:0]  io_fetch_req_bits_pcMemRead_0_startAddr,
  input  [49:0]  io_fetch_req_bits_pcMemRead_0_nextlineStart,
  input  [49:0]  io_fetch_req_bits_pcMemRead_1_startAddr,
  input  [49:0]  io_fetch_req_bits_pcMemRead_1_nextlineStart,
  input  [49:0]  io_fetch_req_bits_pcMemRead_2_startAddr,
  input  [49:0]  io_fetch_req_bits_pcMemRead_2_nextlineStart,
  input  [49:0]  io_fetch_req_bits_pcMemRead_3_startAddr,
  input  [49:0]  io_fetch_req_bits_pcMemRead_3_nextlineStart,
  input  [49:0]  io_fetch_req_bits_pcMemRead_4_startAddr,
  input  [49:0]  io_fetch_req_bits_pcMemRead_4_nextlineStart,
  input          io_fetch_req_bits_readValid_0,
  input          io_fetch_req_bits_readValid_1,
  input          io_fetch_req_bits_readValid_2,
  input          io_fetch_req_bits_readValid_3,
  input          io_fetch_req_bits_readValid_4,
  input          io_fetch_req_bits_backendException,
  input          io_fetch_req_bits_hasSatpFlush,
  output         io_fetch_resp_valid,
  output         io_fetch_resp_bits_doubleline,
  output [49:0]  io_fetch_resp_bits_vaddr_0,
  output [49:0]  io_fetch_resp_bits_vaddr_1,
  output [511:0] io_fetch_resp_bits_data,
  output [47:0]  io_fetch_resp_bits_paddr_0,
  output [1:0]   io_fetch_resp_bits_exception_0,
  output [1:0]   io_fetch_resp_bits_exception_1,
  output         io_fetch_resp_bits_pmp_mmio_0,
  output         io_fetch_resp_bits_pmp_mmio_1,
  output [1:0]   io_fetch_resp_bits_itlb_pbmt_0,
  output [1:0]   io_fetch_resp_bits_itlb_pbmt_1,
  output         io_fetch_resp_bits_backendException,
  output         io_fetch_resp_bits_hasSatpFlush,
  output [55:0]  io_fetch_resp_bits_gpaddr,
  output         io_fetch_resp_bits_isForVSnonLeafPTE,
  output         io_fetch_topdownIcacheMiss,
  output         io_fetch_topdownItlbMiss,
  input          io_flush,
  output         io_pmp_0_req_valid,
  output [47:0]  io_pmp_0_req_bits_addr,
  input          io_pmp_0_resp_instr,
  input          io_pmp_0_resp_mmio,
  output         io_pmp_1_req_valid,
  output [47:0]  io_pmp_1_req_bits_addr,
  input          io_pmp_1_resp_instr,
  input          io_pmp_1_resp_mmio,
  input          io_respStall,
  output         io_errors_0_valid,
  output [47:0]  io_errors_0_bits_paddr,
  output         io_errors_0_bits_report_to_beu,
  output         io_errors_1_valid,
  output [47:0]  io_errors_1_bits_paddr,
  output         io_errors_1_bits_report_to_beu,
  output         io_perfInfo_only_0_hit,
  output         io_perfInfo_only_0_miss,
  output         io_perfInfo_hit_0_hit_1,
  output         io_perfInfo_hit_0_miss_1,
  output         io_perfInfo_miss_0_hit_1,
  output         io_perfInfo_miss_0_miss_1,
  output         io_perfInfo_hit_0_except_1,
  output         io_perfInfo_miss_0_except_1,
  output         io_perfInfo_except_0,
  output         io_perfInfo_bank_hit_0,
  output         io_perfInfo_bank_hit_1,
  output         io_perfInfo_hit,
  output [600:0] gatewayIn_packed_0_bore,
  output [600:0] gatewayIn_packed_1_bore
);
  // ---- flat → struct ----
  data_resp_t from_idata;
  assign from_idata.datas = {io_dataArray_fromIData_datas_7, io_dataArray_fromIData_datas_6,
                             io_dataArray_fromIData_datas_5, io_dataArray_fromIData_datas_4,
                             io_dataArray_fromIData_datas_3, io_dataArray_fromIData_datas_2,
                             io_dataArray_fromIData_datas_1, io_dataArray_fromIData_datas_0};
  assign from_idata.codes = {io_dataArray_fromIData_codes_7, io_dataArray_fromIData_codes_6,
                             io_dataArray_fromIData_codes_5, io_dataArray_fromIData_codes_4,
                             io_dataArray_fromIData_codes_3, io_dataArray_fromIData_codes_2,
                             io_dataArray_fromIData_codes_1, io_dataArray_fromIData_codes_0};

  way_lookup_info_t wl_bits;
  assign wl_bits.entry[0].vSetIdx        = io_wayLookupRead_bits_entry_vSetIdx_0;
  assign wl_bits.entry[0].waymask        = io_wayLookupRead_bits_entry_waymask_0;
  assign wl_bits.entry[0].ptag           = io_wayLookupRead_bits_entry_ptag_0;
  assign wl_bits.entry[0].itlb_exception = io_wayLookupRead_bits_entry_itlb_exception_0;
  assign wl_bits.entry[0].itlb_pbmt      = io_wayLookupRead_bits_entry_itlb_pbmt_0;
  assign wl_bits.entry[0].meta_codes     = io_wayLookupRead_bits_entry_meta_codes_0;
  assign wl_bits.entry[1].vSetIdx        = io_wayLookupRead_bits_entry_vSetIdx_1;
  assign wl_bits.entry[1].waymask        = io_wayLookupRead_bits_entry_waymask_1;
  assign wl_bits.entry[1].ptag           = io_wayLookupRead_bits_entry_ptag_1;
  assign wl_bits.entry[1].itlb_exception = io_wayLookupRead_bits_entry_itlb_exception_1;
  assign wl_bits.entry[1].itlb_pbmt      = io_wayLookupRead_bits_entry_itlb_pbmt_1;
  assign wl_bits.entry[1].meta_codes     = io_wayLookupRead_bits_entry_meta_codes_1;
  assign wl_bits.gpf_gpaddr              = io_wayLookupRead_bits_gpf_gpaddr;
  assign wl_bits.gpf_isForVSnonLeafPTE   = io_wayLookupRead_bits_gpf_isForVSnonLeafPTE;

  miss_resp_t mshr_resp;
  assign mshr_resp.blkPaddr = io_mshr_resp_bits_blkPaddr;
  assign mshr_resp.vSetIdx  = io_mshr_resp_bits_vSetIdx;
  assign mshr_resp.data     = io_mshr_resp_bits_data;
  assign mshr_resp.corrupt  = io_mshr_resp_bits_corrupt;

  fetch_req_t fetch_req;
  assign fetch_req.pcMemRead[0].startAddr     = io_fetch_req_bits_pcMemRead_0_startAddr;
  assign fetch_req.pcMemRead[0].nextlineStart = io_fetch_req_bits_pcMemRead_0_nextlineStart;
  assign fetch_req.pcMemRead[1].startAddr     = io_fetch_req_bits_pcMemRead_1_startAddr;
  assign fetch_req.pcMemRead[1].nextlineStart = io_fetch_req_bits_pcMemRead_1_nextlineStart;
  assign fetch_req.pcMemRead[2].startAddr     = io_fetch_req_bits_pcMemRead_2_startAddr;
  assign fetch_req.pcMemRead[2].nextlineStart = io_fetch_req_bits_pcMemRead_2_nextlineStart;
  assign fetch_req.pcMemRead[3].startAddr     = io_fetch_req_bits_pcMemRead_3_startAddr;
  assign fetch_req.pcMemRead[3].nextlineStart = io_fetch_req_bits_pcMemRead_3_nextlineStart;
  assign fetch_req.pcMemRead[4].startAddr     = io_fetch_req_bits_pcMemRead_4_startAddr;
  assign fetch_req.pcMemRead[4].nextlineStart = io_fetch_req_bits_pcMemRead_4_nextlineStart;
  assign fetch_req.readValid = {io_fetch_req_bits_readValid_4, io_fetch_req_bits_readValid_3,
                                io_fetch_req_bits_readValid_2, io_fetch_req_bits_readValid_1,
                                io_fetch_req_bits_readValid_0};
  assign fetch_req.backendException = io_fetch_req_bits_backendException;
  assign fetch_req.hasSatpFlush     = io_fetch_req_bits_hasSatpFlush;

  pmp_resp_t [PORT_NUM-1:0] pmp_resp;
  assign pmp_resp[0].instr = io_pmp_0_resp_instr;
  assign pmp_resp[0].mmio  = io_pmp_0_resp_mmio;
  assign pmp_resp[1].instr = io_pmp_1_resp_instr;
  assign pmp_resp[1].mmio  = io_pmp_1_resp_mmio;

  // ---- 核 ----
  logic [PART_WAY_NUM-1:0]                             todata_valid;
  logic [PART_WAY_NUM-1:0][PORT_NUM-1:0][IDX_BITS-1:0] todata_vset;
  logic [PORT_NUM-1:0][N_WAYS-1:0]                     todata0_waymask;
  logic [PORT_NUM-1:0]                                 meta_flush_valid;
  meta_flush_t [PORT_NUM-1:0]                          meta_flush_bits;
  logic [PORT_NUM-1:0]                                 touch_valid;
  touch_t [PORT_NUM-1:0]                               touch_bits;
  miss_req_t                                           mshr_req;
  fetch_resp_t                                         fetch_resp;
  logic [PORT_NUM-1:0]                                 pmp_req_valid;
  logic [PORT_NUM-1:0][PADDR_W-1:0]                    pmp_req_addr;
  logic [PORT_NUM-1:0]                                 errors_valid;
  error_info_t [PORT_NUM-1:0]                          errors_bits;
  perf_info_t                                          perf;
  difftest_refill_t [PORT_NUM-1:0]                     difftest_refill;

  xs_ICacheMainPipe u_core (
    .clock(clock), .reset(reset), .io_hartId(io_hartId),
    .io_toIData_valid(todata_valid), .io_toIData_vSetIdx(todata_vset),
    .io_toIData_0_waymask(todata0_waymask), .io_toIData_0_blkOffset(io_dataArray_toIData_0_bits_blkOffset),
    .io_toIData_3_ready(io_dataArray_toIData_3_ready), .io_fromIData(from_idata),
    .io_metaArrayFlush_valid(meta_flush_valid), .io_metaArrayFlush_bits(meta_flush_bits),
    .io_touch_valid(touch_valid), .io_touch_bits(touch_bits),
    .io_wayLookupRead_ready(io_wayLookupRead_ready), .io_wayLookupRead_valid(io_wayLookupRead_valid),
    .io_wayLookupRead_bits(wl_bits),
    .io_mshr_req_ready(io_mshr_req_ready), .io_mshr_req_valid(io_mshr_req_valid), .io_mshr_req_bits(mshr_req),
    .io_mshr_resp_valid(io_mshr_resp_valid), .io_mshr_resp_bits(mshr_resp),
    .io_ecc_enable(io_ecc_enable),
    .io_fetch_req_ready(io_fetch_req_ready), .io_fetch_req_valid(io_fetch_req_valid), .io_fetch_req_bits(fetch_req),
    .io_fetch_resp_valid(io_fetch_resp_valid), .io_fetch_resp_bits(fetch_resp),
    .io_fetch_topdownIcacheMiss(io_fetch_topdownIcacheMiss), .io_fetch_topdownItlbMiss(io_fetch_topdownItlbMiss),
    .io_flush(io_flush),
    .io_pmp_req_valid(pmp_req_valid), .io_pmp_req_addr(pmp_req_addr), .io_pmp_resp(pmp_resp),
    .io_respStall(io_respStall),
    .io_errors_valid(errors_valid), .io_errors_bits(errors_bits),
    .io_perfInfo(perf), .difftest_refill(difftest_refill)
  );

  // ---- struct → flat ----
  assign io_dataArray_toIData_0_valid          = todata_valid[0];
  assign io_dataArray_toIData_0_bits_vSetIdx_0 = todata_vset[0][0];
  assign io_dataArray_toIData_0_bits_vSetIdx_1 = todata_vset[0][1];
  assign io_dataArray_toIData_0_bits_waymask_0_0 = todata0_waymask[0][0];
  assign io_dataArray_toIData_0_bits_waymask_0_1 = todata0_waymask[0][1];
  assign io_dataArray_toIData_0_bits_waymask_0_2 = todata0_waymask[0][2];
  assign io_dataArray_toIData_0_bits_waymask_0_3 = todata0_waymask[0][3];
  assign io_dataArray_toIData_0_bits_waymask_1_0 = todata0_waymask[1][0];
  assign io_dataArray_toIData_0_bits_waymask_1_1 = todata0_waymask[1][1];
  assign io_dataArray_toIData_0_bits_waymask_1_2 = todata0_waymask[1][2];
  assign io_dataArray_toIData_0_bits_waymask_1_3 = todata0_waymask[1][3];
  assign io_dataArray_toIData_1_valid          = todata_valid[1];
  assign io_dataArray_toIData_1_bits_vSetIdx_0 = todata_vset[1][0];
  assign io_dataArray_toIData_1_bits_vSetIdx_1 = todata_vset[1][1];
  assign io_dataArray_toIData_2_valid          = todata_valid[2];
  assign io_dataArray_toIData_2_bits_vSetIdx_0 = todata_vset[2][0];
  assign io_dataArray_toIData_2_bits_vSetIdx_1 = todata_vset[2][1];
  assign io_dataArray_toIData_3_valid          = todata_valid[3];
  assign io_dataArray_toIData_3_bits_vSetIdx_0 = todata_vset[3][0];
  assign io_dataArray_toIData_3_bits_vSetIdx_1 = todata_vset[3][1];

  assign io_metaArrayFlush_0_valid        = meta_flush_valid[0];
  assign io_metaArrayFlush_0_bits_virIdx  = meta_flush_bits[0].virIdx;
  assign io_metaArrayFlush_0_bits_waymask = meta_flush_bits[0].waymask;
  assign io_metaArrayFlush_1_valid        = meta_flush_valid[1];
  assign io_metaArrayFlush_1_bits_virIdx  = meta_flush_bits[1].virIdx;
  assign io_metaArrayFlush_1_bits_waymask = meta_flush_bits[1].waymask;
  assign io_touch_0_valid        = touch_valid[0];
  assign io_touch_0_bits_vSetIdx = touch_bits[0].vSetIdx;
  assign io_touch_0_bits_way     = touch_bits[0].way;
  assign io_touch_1_valid        = touch_valid[1];
  assign io_touch_1_bits_vSetIdx = touch_bits[1].vSetIdx;
  assign io_touch_1_bits_way     = touch_bits[1].way;

  assign io_mshr_req_bits_blkPaddr = mshr_req.blkPaddr;
  assign io_mshr_req_bits_vSetIdx  = mshr_req.vSetIdx;

  assign io_fetch_resp_bits_doubleline        = fetch_resp.doubleline;
  assign io_fetch_resp_bits_vaddr_0           = fetch_resp.vaddr[0];
  assign io_fetch_resp_bits_vaddr_1           = fetch_resp.vaddr[1];
  assign io_fetch_resp_bits_data              = fetch_resp.data;
  assign io_fetch_resp_bits_paddr_0           = fetch_resp.paddr_0;
  assign io_fetch_resp_bits_exception_0       = fetch_resp.exception[0];
  assign io_fetch_resp_bits_exception_1       = fetch_resp.exception[1];
  assign io_fetch_resp_bits_pmp_mmio_0        = fetch_resp.pmp_mmio[0];
  assign io_fetch_resp_bits_pmp_mmio_1        = fetch_resp.pmp_mmio[1];
  assign io_fetch_resp_bits_itlb_pbmt_0       = fetch_resp.itlb_pbmt[0];
  assign io_fetch_resp_bits_itlb_pbmt_1       = fetch_resp.itlb_pbmt[1];
  assign io_fetch_resp_bits_backendException  = fetch_resp.backendException;
  assign io_fetch_resp_bits_hasSatpFlush      = fetch_resp.hasSatpFlush;
  assign io_fetch_resp_bits_gpaddr            = fetch_resp.gpaddr;
  assign io_fetch_resp_bits_isForVSnonLeafPTE = fetch_resp.isForVSnonLeafPTE;

  assign io_pmp_0_req_valid     = pmp_req_valid[0];
  assign io_pmp_0_req_bits_addr = pmp_req_addr[0];
  assign io_pmp_1_req_valid     = pmp_req_valid[1];
  assign io_pmp_1_req_bits_addr = pmp_req_addr[1];

  assign io_errors_0_valid              = errors_valid[0];
  assign io_errors_0_bits_paddr         = errors_bits[0].paddr;
  assign io_errors_0_bits_report_to_beu = errors_bits[0].report_to_beu;
  assign io_errors_1_valid              = errors_valid[1];
  assign io_errors_1_bits_paddr         = errors_bits[1].paddr;
  assign io_errors_1_bits_report_to_beu = errors_bits[1].report_to_beu;

  assign io_perfInfo_only_0_hit      = perf.only_0_hit;
  assign io_perfInfo_only_0_miss     = perf.only_0_miss;
  assign io_perfInfo_hit_0_hit_1     = perf.hit_0_hit_1;
  assign io_perfInfo_hit_0_miss_1    = perf.hit_0_miss_1;
  assign io_perfInfo_miss_0_hit_1    = perf.miss_0_hit_1;
  assign io_perfInfo_miss_0_miss_1   = perf.miss_0_miss_1;
  assign io_perfInfo_hit_0_except_1  = perf.hit_0_except_1;
  assign io_perfInfo_miss_0_except_1 = perf.miss_0_except_1;
  assign io_perfInfo_except_0        = perf.except_0;
  assign io_perfInfo_bank_hit_0      = perf.bank_hit[0];
  assign io_perfInfo_bank_hit_1      = perf.bank_hit[1];
  assign io_perfInfo_hit             = perf.hit;

  assign gatewayIn_packed_0_bore = difftest_refill[0];
  assign gatewayIn_packed_1_bore = difftest_refill[1];
endmodule
